library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity eink_cntl is 
    port(
        i_clk       : in std_logic;
        -- control interface 
        i_config    : in std_logic;
        o_done      : out std_logic;
        i_busy      : in std_logic;
        -- bram interface 
        --o_addr      : out std_logic_vector(12 downto 0);
        --o_rd_en     : out std_logic; 
        --i_data      : in  std_logic_vector(7 downto 0);

        -- spi output interface 
        i_done      : in std_logic;
        o_load      : out std_logic;
        o_dc        : out std_logic;
        o_bytes     : out std_logic_vector(3 downto 0);
        o_data      : out std_logic_vector(7 downto 0)
    );      
end entity;

architecture rtl of eink_cntl is 

    constant c_pre_commands : integer := 22;
    constant c_post_commands: integer := 29;
    constant c_post_command : integer := 1;
    constant c_data_bytes   : integer := 5000;

    type t_memory   is array (0 to 28)      of std_logic_vector(7 downto 0); -- stores control commands
    type t_length   is array (0 to 28)      of std_logic_vector(3 downto 0); -- stores number of command sequences
    type t_data_cmd is array (0 to 28)      of std_logic;
    type fsm        is (idle, pre_cmd, wait_cmd_end, program_array_cmd, program_array_cmd_done, data_byte, data_byte_end, post_cmd, post_cmd_end );
    
    -- control commands to be issued to the eink display each line is one command sequence
    signal s_cntrl : t_memory := (  x"01", x"C7", x"00", x"00",
                                    x"11", x"01",
                                    x"44", x"00", x"18",
                                    x"45", x"c7", x"00", x"00", x"00",
                                    x"22", x"b1",
                                    x"20",
                                    x"4e", x"00",
                                    x"4F", x"c7", x"00",
                                    x"4e", x"00",
                                    x"4f", x"c7", x"00",
                                    x"22", x"c7"); 
    signal s_dc : t_data_cmd := (   '0','1','0','0',
                                    '0','1',
                                    '0','1','1',
                                    '0','1','1','1','1',
                                    '0','1',
                                    '0',
                                    '0','1',
                                    '0','1','1',
                                    '0','1',
                                    '0','1','1',
                                    '0','1' );
    -- command control bytes sent per sequence, duplicated for each sequence but makes addressing easier  
    signal s_cntrl_lngth : t_length :=( x"4", x"4", x"4", x"4",
                                        x"2", x"2",
                                        x"3", x"3", x"3",
                                        x"5", x"5", x"5", x"5", x"5",
                                        x"2", x"2",
                                        x"1",
                                        x"2", x"2",
                                        x"3", x"3", x"3",
                                        x"2", x"2",
                                        x"3", x"3", x"3",
                                        x"2", x"2");

    signal s_current_state : fsm := idle;
    signal s_command_lnght : integer := 0;
    signal s_data_byte     : integer := 0; 
    signal s_byte_pos      : integer := 0;

begin 

process(i_clk)
begin
    if rising_edge(i_clk) then 
        o_load <= '0';
        o_done <= '0';
        case s_current_state is 
            when idle =>
                if i_config = '1' then
                    s_current_state <= pre_cmd;
                    s_command_lnght <= 0;
                end if;

            when pre_cmd =>
                if s_command_lnght = (c_pre_commands - 1) then 
                    s_current_state <= program_array_cmd;
                    s_data_byte <= 0;
                else
                    if i_busy = '0' then 
                        o_load <= '1';
                        o_dc   <= s_dc(s_command_lnght);
                        o_bytes <= s_cntrl_lngth(s_command_lnght);
                        o_data  <= s_cntrl(s_command_lnght);
                        s_current_state <= wait_cmd_end;
                    end if;
                end if;
            when wait_cmd_end =>
                if i_done = '1' then 
                    s_command_lnght <= s_command_lnght + 1;
                    s_current_state <= pre_cmd;
                end if;

            when program_array_cmd =>
                if i_busy = '0' then 
                    o_load <= '1';
                    o_dc   <= '0';
                    o_bytes <= x"1";
                    o_data  <= x"24";
                    s_current_state <= program_array_cmd_done; 
                end if;
            when program_array_cmd_done =>
                if i_done = '1' then 
                    s_current_state <= data_byte;
                end if;

            when data_byte =>
                if s_data_byte = (c_data_bytes - 1) then 
                    s_current_state <= post_cmd;
                    s_command_lnght <= 27;
                else
                    if i_busy = '0' then
                        o_load <= '1';
                        o_dc   <= '1';
                        o_bytes <= x"1";
                        o_data  <= x"f0";
                        s_current_state <= data_byte_end; 
                    end if;
                end if;
            when data_byte_end =>
                if i_done = '1' then 
                    s_current_state <= data_byte;
                    s_data_byte <= s_data_byte + 1;
                end if;

            when post_cmd =>
                if s_command_lnght = (c_post_commands) then 
                    o_done <= '1';
                    s_current_state <= idle;
                else
                    if i_busy = '0' then
                        o_load <= '1';
                        o_dc   <= s_dc(s_command_lnght);
                        o_bytes <= s_cntrl_lngth(s_command_lnght);
                        o_data  <= s_cntrl(s_command_lnght);
                        s_current_state <= post_cmd_end;
                    end if;
                end if;
            when post_cmd_end =>
                if i_done = '1' then 
                    s_command_lnght <= s_command_lnght + 1;
                    s_current_state <= post_cmd;
                end if;

            when others => null;
        end case; 
        

    end if;



end process;



end architecture; 