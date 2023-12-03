
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
  signal o_clk : std_logic;
  signal o_data : std_logic_vector(7 downto 0);
  signal o_web : std_logic_vector(0 downto 0);


  type mem_array is array (0 to 8191) of std_logic_vector(7 downto 0);
  signal ram : mem_array:=(x"00", x"01", x"03", others => x"ff");

begin

  eink_top_inst : entity work.eink_top
  port map (
    i_clk => i_clk,
    i_config => i_config,
    o_done => o_done,
    o_addr => o_addr,
    o_rd_en => o_rd_en,
    i_data => i_data,
    o_clk  => o_clk,
    o_data => o_data,
    o_web => o_web,
    i_busy =>'0',
    o_csn => o_csn,
    o_dc => o_dc,
    o_mosi => o_mosi,
    o_sclk => o_sclk
  );

i_clk <= not i_clk after clk_period/2;


process(o_clk)
begin
  if rising_edge(o_clk) then
    if o_rd_en = '1' then 
      i_data <= ram(to_integer(unsigned(o_addr)));
    end if;

  end if;

end process;

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