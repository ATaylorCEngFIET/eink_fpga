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
        o_addr      : out std_logic_vector(12 downto 0);
        o_rd_en     : out std_logic; 
        i_data      : in  std_logic_vector(7 downto 0);

        -- spi output interface 
        i_done      : in std_logic;
        o_load      : out std_logic;
        o_dc        : out std_logic;
        o_bytes     : out std_logic_vector(12 downto 0);
        o_data      : out std_logic_vector(7 downto 0)
    );      
end entity;

architecture rtl of eink_cntl is 
    constant c_total_commands   : integer := 38;
    constant c_pre_commands     : integer := 27;
    constant c_wave_bytes       : integer := 159;
    constant c_data_bytes       : integer := 5000;
    constant c_waveform_max     : integer := 153;

    type t_memory   is array (0 to c_total_commands-1)      of std_logic_vector(7 downto 0); -- stores control commands
    type t_data_cmd is array (0 to c_total_commands-1)      of std_logic;
    type t_wave     is array (0 to c_wave_bytes-1)          of std_logic_vector(7 downto 0); -- stores waveforms

    type fsm        is (idle, pre_cmd, wait_cmd_end, program_array_cmd, program_array_cmd_done, data_byte, data_byte_end, post_cmd, post_cmd_end,
                        program_wave_cmd, program_wave_cmd_done, wave_byte, wave_byte_end );
    
    -- control commands to be issued to the eink display each line is one command sequence
    signal s_cntrl : t_memory := (  x"12",
                                    x"01", x"C7", x"00", x"00",
                                    x"11", x"01",
                                    x"44", x"00", x"18",
                                    x"45", x"c7", x"00", x"00", x"00",
                                    x"3c", x"01",
                                    x"18", x"80",
                                    x"22", x"b1",
                                    x"20",
                                    x"4e", x"00",
                                    x"4f", x"c7",x"00",
                                    --post commands 
                                    x"3f", x"02",
                                    x"03", x"17",
                                    x"04", x"41", x"b0", x"32",
                                    x"22", x"c7",
                                    x"20"); 
    signal s_dc : t_data_cmd := (   '0',
                                    '0','1','0','0',
                                    '0','1',
                                    '0','1','1',
                                    '0','1','1','1','1',
                                    '0','1',
                                    '0','1',
                                    '0','1',
                                    '0',
                                    '0','1',
                                    '0','1','1',
                                    -- post commands 
                                    '0', '1',
                                    '0', '1',
                                    '0','1','1','1',
                                    '0','1',
                                    '0' );

    --waveform full refresh
    signal s_waveform : t_wave := (											
    x"80",	x"48",	x"40",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",
    x"40",	x"48",	x"80",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",
    x"80",	x"48",	x"40",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",
    x"40",	x"48",	x"80",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",
    x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",
    x"0A",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",					
    x"08",	x"01",	x"00",	x"08",	x"01",	x"00",	x"02",					
    x"0A",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",					
    x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",					
    x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",					
    x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",					
    x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",					
    x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",					
    x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",					
    x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",					
    x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",					
    x"00",	x"00",	x"00",	x"00",	x"00",	x"00",	x"00",					
    x"22",	x"22",	x"22",	x"22",	x"22",	x"22",	x"00",	x"00",	x"00",			
    x"22",	x"17",	x"41",	x"00",	x"32",	x"20");

    signal s_current_state : fsm := idle;
    signal s_command_lnght : integer := 0;
    signal s_data_byte     : integer := 0; 
    signal s_byte_pos      : integer := 0;
    signal s_wave_byte     : integer := 0;

    signal s_address       : unsigned(12 downto 0);
    signal s_rd_en         : std_logic;

begin 

o_addr <= std_logic_vector(to_unsigned(s_data_byte,13));
o_rd_en <= s_rd_en;

process(i_clk)
begin
    if rising_edge(i_clk) then 
        o_load  <= '0';
        o_done  <= '0';
        s_rd_en <= '1';
        case s_current_state is 
            when idle =>
                if i_config = '1' then
                    s_current_state <= pre_cmd;
                    s_command_lnght <= 0;
                end if;

            when pre_cmd =>
                if s_command_lnght = (c_pre_commands) then 
                    s_current_state <= program_wave_cmd;
                    s_wave_byte <= 0;
                else
                    if i_busy = '0' then 
                        o_load <= '1';
                        o_dc   <= s_dc(s_command_lnght);
                        o_bytes <= std_logic_vector(to_unsigned(1,13));
                        o_data  <= s_cntrl(s_command_lnght);
                        s_current_state <= wait_cmd_end;
                    end if;
                end if;
            when wait_cmd_end =>
                if i_done = '1' then 
                    s_command_lnght <= s_command_lnght + 1;
                    s_current_state <= pre_cmd;
                end if;

            when program_wave_cmd =>
                if i_busy = '0' then 
                    o_load <= '1';
                    o_dc   <= '0';
                    o_bytes <= std_logic_vector(to_unsigned(1,13));
                    o_data  <= x"32";
                    s_current_state <= program_wave_cmd_done; 
                end if;
            when program_wave_cmd_done =>
                if i_done = '1' then 
                    s_current_state <= wave_byte;
                end if;

            when wave_byte =>
                if s_wave_byte = (c_wave_bytes - 1) then 
                    s_current_state <= program_array_cmd;
                    s_data_byte <= 0;
                else
                    if i_busy = '0' then
                        o_load <= '1';
                        o_dc   <= '1';
                        o_bytes <= std_logic_vector(to_unsigned(1,13));
                        o_data  <= s_waveform(s_wave_byte) ;
                        s_current_state <= wave_byte_end; 
                    end if;
                end if;
            when wave_byte_end =>
                if i_done = '1' then 
                    s_current_state <= wave_byte;
                    s_wave_byte <= s_wave_byte + 1;
                end if;



            when program_array_cmd =>
                if i_busy = '0' then 
                    o_load <= '1';
                    o_dc   <= '0';
                    o_bytes <= std_logic_vector(to_unsigned(1,13));
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
                else
                    if i_busy = '0' then
                        o_load <= '1';
                        o_dc   <= '1';
                        s_data_byte <= s_data_byte + 1;
                        o_bytes <= std_logic_vector(to_unsigned(1,13));
                        o_data  <= i_data;--x"f0";
                        s_current_state <= data_byte_end; 
                    end if;
                end if;

            when data_byte_end =>
                if i_done = '1' then 
                    s_current_state <= data_byte;
                    --s_data_byte <= s_data_byte + 1;
                end if;

            when post_cmd =>
                if s_command_lnght = (c_total_commands) then 
                    o_done <= '1';
                    s_current_state <= idle;
                else
                    if i_busy = '0' then
                        o_load <= '1';
                        o_dc   <= s_dc(s_command_lnght);
                        o_bytes <= std_logic_vector(to_unsigned(1,13));
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