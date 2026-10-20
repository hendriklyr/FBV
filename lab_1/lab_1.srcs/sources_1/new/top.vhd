----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/20/2026 09:09:57 PM
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

library work;
use work.fbv_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
    Port ( i_dig_gain : in STD_LOGIC_VECTOR (7 downto 0);
           i_dig_offset : in STD_LOGIC_VECTOR (7 downto 0);
           i_video : in STD_LOGIC_VECTOR (7 downto 0);
           i_clk : in STD_LOGIC;
           i_fval : in STD_LOGIC;
           i_lval : in STD_LOGIC;
           o_video : out STD_LOGIC_VECTOR(7 downto 0);
           o_fval : out STD_LOGIC;
           o_lval : out STD_LOGIC);
end top;

architecture Behavioral of top is

signal w_dig_gain, w_dig_offset, w_i_video : std_logic_vector( 7 downto 0);
signal w_clk, w_fval, w_lval : std_logic;
signal ff_add : std_logic_vector;-- TODO: set length of ff_add and ff_mul
signal ff_mul : std_logic_vector;
signal sr_delay: std_logic_vector(1 downto 0);

begin
    P_SYNC: process(i_clk) 
    begin  
        if rising_edge(i_clk) then 
            w_dig_gain <= i_dig_gain;
            w_dig_offset <= i_dig_offset;
            w_i_video <= i_video;
            w_clk <=  i_clk;
            w_fval <= i_fval;
            w_lval <= i_lval;
            
        end if;
    end process;
    P_LOGIC: process(i_clk) 
    begin
        if rising_edge(w_clk) then
            dig_offset(w_i_video, w_dig_offset,ff_add);
            ff_mul <= dig_gain(ff_add, w_dig_gain,0,0); --TODO change genentic decimals and res_width, is it generic??
        end if;
    end process;
    
    P_OUT: process(w_clk)
    begin
        if rising_edge(w_clk) then --TODO implement o_fval and i_fval
            o_video <= ff_mul;
            sr_delay <= sr(sr_delay'left downto (sr_delay'right-1)) & w_lval;
            o_lval <= sr_delay(sr_delay'left);
        end if;
    end process;
    


end Behavioral;
