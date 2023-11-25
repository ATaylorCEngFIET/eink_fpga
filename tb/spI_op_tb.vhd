
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_op_tb is
end;

architecture bench of spi_op_tb is
  -- Clock period
  constant clk_period : time := 10 ns;
  -- Generics
  constant g_clk_freq : integer := 100000000;
  constant g_spi_clk : integer := 1000000;
  -- Ports
  signal i_clk : std_logic:='0';
  signal i_load : std_logic;
  signal i_dc : std_logic;
  signal i_data : std_logic_vector(7 downto 0);
  signal o_csn : std_logic;
  signal o_dc : std_logic;
  signal o_busy : std_logic;
  signal o_mosi : std_logic;
  signal o_sclk : std_logic;
  signal o_done : std_logic;
  signal i_bytes: std_logic_vector(3 downto 0);
begin

  spi_op_inst : entity work.spi_op
  generic map (
    g_clk_freq => g_clk_freq,
    g_spi_clk => g_spi_clk
  )
  port map (
    i_clk => i_clk,
    i_load => i_load,
    i_dc => i_dc,
    i_data => i_data,
    i_bytes => i_bytes,
    o_csn => o_csn,
    o_dc => o_dc,
    o_busy => o_busy,
    o_mosi => o_mosi,
    o_sclk => o_sclk,
    o_done => o_done
  );

 i_clk <= not i_clk after clk_period/2;

process 
begin 

    i_load <= '0';
    i_dc <= '1';
    i_data <= x"00";

    wait for 100 ns;
    wait until rising_edge(i_clk);
    i_load <= '1';
    i_bytes <= "0001";
    i_dc <= '0';
    i_data <= x"aa";
    wait until rising_edge(i_clk);
    i_load <= '0';
    wait until o_done = '1'; 
    
    wait for 100 ns;
    wait until rising_edge(i_clk);
    i_load <= '1';
    i_bytes <= "0101";
    i_dc <= '1';
    i_data <= x"01";
    wait until rising_edge(i_clk);
    i_load <= '0';
    wait until o_done = '1'; 

    wait for 100 ns;
    wait until rising_edge(i_clk);
    i_load <= '1';
    i_bytes <= "0101";
    i_dc <= '0';
    i_data <= x"02";
    wait until rising_edge(i_clk);
    i_load <= '0';
    wait until o_done = '1'; 

    wait for 100 ns;
    wait until rising_edge(i_clk);
    i_load <= '1';
    i_bytes <= "0101";
    i_dc <= '1';
    i_data <= x"03";
    wait until rising_edge(i_clk);
    i_load <= '0';
    wait until o_done = '1'; 

    wait for 100 ns;
    wait until rising_edge(i_clk);
    i_load <= '1';
    i_bytes <= "0101";
    i_dc <= '0';
    i_data <= x"04";
    wait until rising_edge(i_clk);
    i_load <= '0';
    wait until o_done = '1'; 

    wait for 100 ns;
    wait until rising_edge(i_clk);
    i_load <= '1';
    i_bytes <= "0101";
    i_dc <= '1';
    i_data <= x"05";
    wait until rising_edge(i_clk);
    i_load <= '0';
    wait until o_done = '1'; 

    wait for 100 ns;
    report "simulation complete" severity failure;
 end process;

end;