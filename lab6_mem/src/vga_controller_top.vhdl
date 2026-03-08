--=============================================================================
-- @file vga_controller_top.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Packages
library work;
use work.dsd_prj_pkg.all;

--=============================================================================
--
-- vga_controller_top
--
-- @brief This file specifies the toplevel of a VGA controller
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR VGA_CONTROLLER_TOP
--=============================================================================
entity vga_controller_top is
  port (
    CLK125xCI : in std_logic;
    RSTxRI    : in std_logic;

    -- Timing outputs
    HSxSO : out std_logic;
    VSxSO : out std_logic;

    -- Data/color output
    RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0);
    GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
  );
end vga_controller_top;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of vga_controller_top is

--=============================================================================
-- SIGNAL (COMBINATIONAL) DECLARATIONS
--=============================================================================;

  -- clk_wiz_0
  signal CLK75xC : std_logic;

  -- blk_mem_gen_0
  signal WrAddrAxD : std_logic_vector(MEM_ADDR_BW - 1 downto 0);
  signal RdAddrBxD : std_logic_vector(MEM_ADDR_BW - 1 downto 0);
  signal ENAxS     : std_logic;
  signal WEAxS     : std_logic_vector(0 downto 0);
  signal ENBxS     : std_logic;
  signal DINAxD    : std_logic_vector(MEM_DATA_BW - 1 downto 0);
  signal DOUTBxD   : std_logic_vector(MEM_DATA_BW - 1 downto 0);

  -- vga_controller
  signal RedxSI   : std_logic_vector(COLOR_BW - 1 downto 0);
  signal GreenxSI : std_logic_vector(COLOR_BW - 1 downto 0);
  signal BluexSI  : std_logic_vector(COLOR_BW - 1 downto 0);

  signal XCoordxD : unsigned(COORD_BW - 1 downto 0);
  signal YCoordxD : unsigned(COORD_BW - 1 downto 0);
  
  signal XCoord_ds : unsigned(7 downto 0);  -- 256 max -> 8 bits
  signal YCoord_ds : unsigned(7 downto 0);  -- 192 max -> 8 bits
  signal MemAddr   : unsigned(MEM_ADDR_BW - 1 downto 0);

--=============================================================================
-- COMPONENT DECLARATIONS
--=============================================================================
  component clk_wiz_0 is
    port (
      clk_out1 : out std_logic;
      reset    : in  std_logic;
      locked   : out std_logic;
      clk_in1  : in  std_logic
    );
  end component clk_wiz_0;

  component blk_mem_gen_0
    port (
      clka  : in std_logic;
      ena   : in std_logic;
      wea   : in std_logic_vector(0 downto 0);
      addra : in std_logic_vector(15 downto 0);
      dina  : in std_logic_vector(11 downto 0);

      clkb  : in std_logic;
      enb   : in std_logic;
      addrb : in std_logic_vector(15 downto 0);
      doutb : out std_logic_vector(11 downto 0)
    );
  end component;

  component vga_controller is
    port (
      CLKxCI : in std_logic;
      RSTxRI : in std_logic;

      -- Data/color input
      RedxSI   : in std_logic_vector(COLOR_BW - 1 downto 0);
      GreenxSI : in std_logic_vector(COLOR_BW - 1 downto 0);
      BluexSI  : in std_logic_vector(COLOR_BW - 1 downto 0);

      -- Coordinate output
      XCoordxDO : out unsigned(COORD_BW - 1 downto 0);
      YCoordxDO : out unsigned(COORD_BW - 1 downto 0);

      -- Timing output
      HSxSO : out std_logic;
      VSxSO : out std_logic;

      -- Data/color output
      RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0);
      GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
      BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
    );
  end component vga_controller;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

--=============================================================================
-- COMPONENT INSTANTIATIONS
--=============================================================================
  i_clk_wiz_0 : clk_wiz_0
    port map (
      clk_out1 => CLK75xC,
      reset    => RSTxRI,
      locked   => open,
      clk_in1  => CLK125xCI
    );

  i_blk_mem_gen_0 : blk_mem_gen_0
    port map (
      clka  => CLK75xC,
      ena   => ENAxS,
      wea   => WEAxS,
      addra => WrAddrAxD,
      dina  => DINAxD,

      clkb  => CLK75xC,
      enb   => ENBxS,
      addrb => RdAddrBxD,
      doutb => DOUTBxD
    );

  i_vga_controller: vga_controller
    port map (
      CLKxCI => CLK75xC,
      RSTxRI => RSTxRI,

      RedxSI   => RedxSI,
      GreenxSI => GreenxSI,
      BluexSI  => BluexSI,

      HSxSO => HSxSO,
      VSxSO => VSxSO,

      XCoordxDO => XCoordxD,
      YCoordxDO => YCoordxD,

      RedxSO   => RedxSO,
      GreenxSO => GreenxSO,
      BluexSO  => BluexSO
    );

--=============================================================================
-- SIGNAL MAPPING
--=============================================================================

  ENAxS     <= '0';
  ENBxS     <= '1';
  WEAxS     <= "0";
  WrAddrAxD <= (others => '0');
  DINAxD    <= (others => '0');
    -- Divide coordinates by 4 (skip 3 out of 4 pixels)
  XCoord_ds <= XCoordxD(9 downto 2);  -- 1024 = 2^10 ? drop 2 LSBs ? /4
  YCoord_ds <= YCoordxD(9 downto 2);  -- 768 fits in 10 bits; drop 2 bits ? /4

  -- Linear addressing: addr = y * 256 + x
  MemAddr <= resize(
              resize(YCoord_ds, MEM_ADDR_BW) * 256 +
              resize(XCoord_ds, MEM_ADDR_BW),
              MEM_ADDR_BW
           );

   RdAddrBxD <= std_logic_vector(MemAddr);
 -- TODO: Map the X and Y coordinates to the address of the memory

  RedxSI   <= DOUTBxD(3 * COLOR_BW - 1 downto 2 * COLOR_BW);
  GreenxSI <= DOUTBxD(2 * COLOR_BW - 1 downto 1 * COLOR_BW);
  BluexSI  <= DOUTBxD(1 * COLOR_BW - 1 downto 0 * COLOR_BW);

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
