----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/03/2026 03:51:33 PM
-- Design Name: 
-- Module Name: top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is

    Port (
        dclk_n      : in    std_logic;
        dclk_p      : in    std_logic;
        i_DATA_n    : in    std_logic;
        i_DATA_p    : in    std_logic;
        resync      : in    std_logic;
        rst         : in    std_logic;
        sysclk      : in    std_logic;
        o_data      : out   std_logic_vector(7 downto 0);
        o_done      : out   std_logic;
        o_err       : out   std_logic;
        o_locked    : out   std_logic
    );
end top;

architecture Behavioral of top is

begin


end Behavioral;
