library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity spi_op is generic(
    g_clk_freq : integer := 100000000;
    g_spi_clk  : integer := 1000000 
);
    port(
        i_clk  : in std_logic; 
        i_load : in std_logic;
        i_dc   : in std_logic;
        i_bytes: in std_logic_vector(3 downto 0);
        i_data : in std_logic_vector(7 downto 0);
        o_csn  : out std_logic;
        o_dc   : out std_logic;
        o_busy : out std_logic;
        o_mosi : out std_logic;
        o_sclk : out std_logic;
        o_done : out std_logic
);
end entity;

architecture rtl of spi_op is 

    function vector_size(clk_freq, spi_clk : real) return integer is
        variable div                             : real;
        variable res                             : real;
        begin
        div := (clk_freq/spi_clk);
        res := CEIL(LOG(div)/LOG(2.0));
        return integer(res - 1.0);
    end;

    type fsm is (idle, load, complete);

    constant c_fe_det : std_logic_vector(1 downto 0):= "10";

    signal s_baud_counter       : unsigned(vector_size(real(g_clk_freq), real(g_spi_clk)) downto 0) := (others => '0'); 
    signal s_baud_enb           : std_logic:='0';
    signal s_data_reg           : std_logic_vector(7 downto 0):=(others =>'0');
    signal s_current_state      : fsm :=idle;
    signal s_load               : std_logic:='0';
    signal s_payload            : std_logic_vector(7 downto 0):=(others =>'0');
    signal s_dc                 : std_logic:='0';
    signal s_sck                : std_logic:='0';
    signal s_sck_fe             : std_logic:='0'; 
    signal s_tmr                : std_logic_vector(7 downto 0) := (others =>'0');
    signal s_fe_det             : std_logic_vector(1 downto 0);
    signal s_busy               : std_logic :='0';
    signal s_csn                : std_logic :='1';
    signal s_bytes              : unsigned(3 downto 0):=(others=>'0');
    signal s_byte_cnt           : unsigned(3 downto 0):=(others=>'0');
    signal s_done               : std_logic;

begin 

o_done <= s_done;

csn_cnrtl: process(i_clk)
begin
    if rising_edge(i_clk) then
        if i_load = '1' then 
            s_bytes     <= unsigned(i_bytes);
            s_csn       <= '0';
            
        elsif s_bytes = s_byte_cnt then
            s_csn <= '1';
            s_byte_cnt  <= (others =>'0');
        elsif s_done = '1' then 
            s_byte_cnt <= s_byte_cnt + 1;
        end if;        
    end if;
end process;

fsm_cntrl: process(i_clk)
begin
    if rising_edge(i_clk) then 
        s_load <= '0';
        s_done <= '0';
        case s_current_state is 
            when idle => 
                if i_load = '1' then 
                    s_dc      <= i_dc;
                   
                    s_busy <= '1'; 
                    s_load <= '1';
                    s_current_state <= load;
                end if;
            when load => 
                s_current_state <= complete;
            when complete =>
                if s_tmr = (s_tmr'range =>'0') then 
                    s_current_state <= idle;
                    s_busy <= '0';
                    s_done <= '1';
                end if;
        end case;
    end if;
end process;

sck_gen : process(i_clk)
begin
    if rising_edge(i_clk) then 
        if s_load = '1' then 
            s_sck <= '0';
            s_baud_counter <= (others=>'0');
        elsif s_baud_counter = ((g_clk_freq/g_spi_clk)/2)-1 then --toggle at 50:50 duty cycle 
            s_sck <= not(s_sck);
            s_baud_counter <= (others=>'0');
        else
            s_baud_counter <= s_baud_counter + 1;
        end if;
    end if;        
end process;

edge_det : process(i_clk)
begin
    if rising_edge(i_clk) then 
        s_fe_det <= s_fe_det(s_fe_det'high-1 downto s_fe_det'low) & s_sck;
    end if;
end process;


op_uart : process (i_clk)
begin
  if rising_edge(i_clk) then
    if i_load = '1' then
        s_data_reg  <= i_data  ;
        s_tmr <= (others => '1');
    elsif s_fe_det = c_fe_det then 
        s_data_reg  <= s_data_reg(s_data_reg'high-1 downto s_data_reg'low) & '0';
        s_tmr <= s_tmr(s_tmr'high - 1 downto s_tmr'low) & '0';
    end if;
  end if;
end process;

o_busy <= s_busy or i_load; 
o_mosi <= s_data_reg(s_data_reg'high);
o_sclk <= s_sck when s_busy = '1' else '0';
o_dc <= s_dc;
o_csn <= s_csn;


end architecture;