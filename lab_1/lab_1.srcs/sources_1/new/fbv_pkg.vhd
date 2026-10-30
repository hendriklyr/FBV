----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/26/2026 11:06:49 AM
-- Design Name: 
-- Module Name: fbv_pkg - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

package fbv_pkg is
--  Port ( );
    procedure DIG_OFFSET(signal iData : in std_logic_vector;
                         signal Offset : in std_logic_vector;
                         signal Result : out std_logic_vector);
    function DIG_GAIN( iData, Factor : std_logic_vector; Decimals, res_width: positive) return std_logic_vector;
end fbv_pkg;

package body fbv_pkg is

    -- Offset hinzufügen(kann negativ sein)
    procedure DIG_OFFSET(signal iData : in std_logic_vector;
                         signal Offset : in std_logic_vector;
                         signal Result : out std_logic_vector) is  
    variable sum: signed(iData'length +1 downto 0);  
    begin
        sum := signed("00" & iData) + signed(Offset);
        if (sum(sum'left) = '1') then
            Result <= (others => '0');
        elsif (Result'length = iData'length and sum(sum'left -1) = '1') then
            Result <= (others => '1');
        else
            Result <= std_logic_vector(sum(sum'left-2 downto 0));
        end if;
    end procedure;
    
    
    -- Gain berechnen
    function DIG_GAIN( iData, Factor : std_logic_vector; Decimals, res_width: positive) return std_logic_vector is
        variable product: unsigned(iData'length+Factor'length-1 downto 0);
        variable no_dec: unsigned(iData'length+Factor'length-1 downto 0);
        variable res_val: std_logic_vector(res_width-1 downto 0);
    begin
        product := unsigned(iData) * unsigned(Factor);
        no_dec := shift_right(product, Decimals);
        
        if (no_dec(no_dec'left downto res_width) /= 0) then
            res_val := (others => '1');
        else
            res_val := std_logic_vector(no_dec(res_width-1 downto 0));
        end if; 
        
        return res_val;
    end function;


end fbv_pkg;