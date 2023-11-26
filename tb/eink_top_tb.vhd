
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity eink_top_tb is
end;

architecture bench of eink_top_tb is
  -- Clock period
  constant clk_period : time := 10 ns;
  -- Generics
  -- Ports
  signal i_clk : std_logic:='0';
  signal i_config : std_logic;
  signal o_addr : std_logic_vector(12 downto 0);
  signal o_rd_en : std_logic;
  signal i_data : std_logic_vector(7 downto 0);
  signal o_csn : std_logic;
  signal o_dc : std_logic;
  signal o_done : std_logic;
  signal o_mosi : std_logic;
  signal o_sclk : std_logic;
begin

  eink_top_inst : entity work.eink_top
  port map (
    i_clk => i_clk,
    i_config => i_config,
    o_done => o_done,
    o_addr => o_addr,
    o_rd_en => o_rd_en,
    i_data => i_data,
    o_csn => o_csn,
    o_dc => o_dc,
    o_mosi => o_mosi,
    o_sclk => o_sclk
  );

i_clk <= not i_clk after clk_period/2;


process 

begin
    i_config <= '0';
    wait for 100 ns;
    wait until rising_edge(i_clk);
    i_config <= '1';
    wait until rising_edge(i_clk);
    i_config <= '0';
    wait until rising_edge(o_done);
    report "simulation complete" severity failure;


end process;

end;