library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity eink_top is 
    port(
        i_clk       : in std_logic;
        -- control interface 
        i_config    : in std_logic;
        o_done      : out std_logic;

        -- bram interface 
        o_addr      : out std_logic_vector(14 downto 0);
        o_rd_en     : out std_logic; 
        o_clk       : out std_logic;
        o_data      : out std_logic_vector(7 downto 0);
        o_web       : out std_logic_vector(0 downto 0);
        i_data      : in  std_logic_vector(7 downto 0);

        -- spi output interface 
        i_busy : in std_logic;
        o_csn  : out std_logic;
        o_dc   : out std_logic;
        o_mosi : out std_logic;
        o_sclk : out std_logic  
    );      
end entity;

architecture rtl of eink_top is

    constant g_clk_freq : integer := 100000000;
    constant g_spi_clk : integer := 100000;

    signal s_load : std_logic;
    signal s_dc : std_logic;
    signal s_data : std_logic_vector(7 downto 0);

    signal s_busy : std_logic;
    signal s_done : std_logic;
    signal s_bytes: std_logic_vector(12 downto 0);

begin

    o_web <= (others =>'0');
    o_data<= (others =>'0');
    o_clk <= i_clk;

spi_op_inst : entity work.spi_op
    generic map (
      g_clk_freq => g_clk_freq,
      g_spi_clk => g_spi_clk
    )
    port map (
      i_clk     => i_clk,
      i_load    => s_load,
      i_dc      => s_dc,
      i_data    => s_data,
      i_bytes   => s_bytes,
      o_csn     => o_csn,
      o_dc      => o_dc,
      o_busy    => s_busy,
      o_mosi    => o_mosi,
      o_sclk    => o_sclk,
      o_done    => s_done
    );
        

eink_cntrl_inst : entity work.eink_cntl port map(
    i_clk       => i_clk,
    i_config    => i_config,
    o_done      => o_done,
    i_busy      => i_busy,
    o_addr      => o_addr, 
    o_rd_en     => o_rd_en,
    i_data      => i_data,
    i_done      => s_done,
    o_load      => s_load,
    o_dc        => s_dc,
    o_bytes     => s_bytes,
    o_data      => s_data 
    );

end architecture; 