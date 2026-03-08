--=============================================================================
-- @file vga_controller.vhdl
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
-- vga_controller
--
-- @brief This file specifies a VGA controller circuit
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR VGA_CONTROLLER
--=============================================================================
entity vga_controller is
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
    
     VSEdgexSO : out std_logic;


    -- Data/color output
    RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0);
    GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
  );
end vga_controller;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of vga_controller is

  -- Counters
  signal CNTxDN, CNTxDP : unsigned(30-1 downto 0);
  signal CountCLRxS     : std_logic;
  signal CountENxS      : std_logic;
  signal CntHorxDP, CntHorxDN : unsigned(12-1 downto 0);
  signal CntVerxDP, CntVerxDN : unsigned(12-1 downto 0);
  signal VSxDN,VSxDP,HSxDP,HSxDN: std_logic;
  signal RedxDN, RedxDP, GreenxDN, GreenxDP, BluexDP, BluexDN: std_logic_vector(COLOR_BW - 1 downto 0);
--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

  -- TODO: Implement your own code here
  
    -- Counter for Horizontal ---
    contH: process(CLKxCI, RSTxRI) is
    begin
        if RSTxRI = '1' then
            CntHorxDP <= (OTHERS => '0');
        elsif CLKxCI'event and CLKxCI = '1' then
            CntHorxDP <= CntHorxDN;
        end if;
    end process;
    
    
    -- Counter for Vertical --
    contV: process(CLKxCI, RSTxRI) is
    begin
        if RSTxRI = '1' then
            CntVerxDP <= (OTHERS => '0');
        elsif CLKxCI'event and CLKxCI = '1' then
            CntVerxDP <= CntVerxDN;
        end if;
    end process;
    
    
    
    -- Registers for horizontal and vertical control signals
    
    process(CLKxCI, RSTxRI) is
    begin
        if RSTxRI = '1' then
            HSxDP <= '0';
        elsif CLKxCI'event and CLKxCI = '1' then
            HSxDP <= HSxDN;
        end if;
    end process;
    
    process(CLKxCI, RSTxRI) is
    begin
        if RSTxRI = '1' then
            VSxDP <= '0';
        elsif CLKxCI'event and CLKxCI = '1' then
            VSxDP <= VSxDN;
        end if;
    end process;
    
    --Registers for color control signals
    
    process(CLKxCI, RSTxRI) is
    begin
        if RSTxRI = '1' then
            RedxDP <= "0000";
            GreenxDP <= "0000";
            BluexDP <= "0000";
            
        elsif CLKxCI'event and CLKxCI = '1' then
            RedxDP <= RedxDN;
            GreenxDP <= GreenxDN;
            BluexDP <= BluexDN;
        end if;
    end process;
    
    -- Transition logic (combinational logic inside a dedicated process
    
     process (all) is
     begin
     
         CntHorxDN <= CntHorxDP;
        CntVerxDN <= CntVerxDP;
        HSxDN <= HSxDP;
        VSxDN <= VSxDP;
        RedxDN <= RedxDP;
        GreenxDN <= GreenxDP;
        BluexDN <= BluexDP;
        VSEdgexSO <= '0';
        
        --Setting of the color signals for each display region
        if ((CntVerxDP <= VS_DISPLAY) and (CntHorxDP <= HS_DISPLAY)) then    
            RedxDN <= RedxSI;
            GreenxDN <= GreenxSI;
            BluexDN <= BluexSI;
        else 
            RedxDN <= "0000";
            GreenxDN <= "0000";
            BluexDN <= "0000";
        end if;
        
        --Setting of the H/S control signals for each display region
        --Horizontal control signal
        if ((CntHorxDP <= HS_DISPLAY+HS_FRONT_PORCH-2))
             or ((CntHorxDP >= HS_DISPLAY+HS_FRONT_PORCH+HS_PULSE-1)and(CntHorxDP <= HS_DISPLAY+HS_FRONT_PORCH+HS_PULSE+HS_BACK_PORCH-1))
             then
            HSxDN <= '1';
        else 
            HSxDN<='0';
        end if;
        
        --Vertical control signal
        if ((CntVerxDP <= VS_DISPLAY+VS_FRONT_PORCH-2))
             or ((CntVerxDP >= VS_DISPLAY+VS_FRONT_PORCH+VS_PULSE-1)and (CntVerxDP <= VS_DISPLAY+VS_FRONT_PORCH+VS_PULSE+VS_BACK_PORCH-1))
             then
            VSxDN <= '1';
        else 
            VSxDN<= '0';
        end if;
        
        --Incrementation of the H/S counters
        if (CntHorxDP = HS_DISPLAY+HS_FRONT_PORCH+HS_PULSE+HS_BACK_PORCH-1) then
            CntHorxDN<=(others=>'0');
         else 
            CntHorxDN <= CntHorxDP + 1;
         end if;
            
         if ((CntVerxDP = VS_DISPLAY+VS_FRONT_PORCH+VS_PULSE+VS_BACK_PORCH-1)
            and (CntHorxDP = HS_DISPLAY+HS_FRONT_PORCH+HS_PULSE+HS_BACK_PORCH-1))
            then
            CntVerxDN<=(others=>'0');
            VSEdgexSO <= '1';
         elsif (CntHorxDP = HS_DISPLAY+HS_FRONT_PORCH+HS_PULSE+HS_BACK_PORCH-1) then
            CntVerxDN<=CntVerxDP+1;
            VSEdgexSO <= '0';
         else
            CntVerxDN<=CntVerxDP; 
            VSEdgexSO <= '0';
         end if;
             
    end process;

   
    -- Outputs --
    
    
    HSxSO <= HSxDP;
    VSxSO <= VSxDP;
    
    RedxSO <= RedxDP;
    GreenxSO <= GreenxDP;
    BluexSO <= BluexDP;
    
    XCoordxDO <= CntHorxDP;
    YCoordxDO <= CntVerxDP;


end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
