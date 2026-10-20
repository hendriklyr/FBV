----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/20/2026 09:20:33 PM
-- Design Name: 
-- Module Name: fbv_pkg - 
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

package fbv_pkg is
    procedure dig_offset(
        signal i_data          : in  std_logic_vector;
        signal i_offset        : in std_logic_vector;
        signal o_result        : out std_logic_vector
    );
    function dig_gain(
        i_data, factor      :std_logic_vector;
        decimals, res_width :integer     --integer ?? generic?? better with logic_vector??
    )return std_logic_vector;
end fbv_pkg;

package body fbv_pkg is
    procedure dig_offset(
        signal i_data          : in  std_logic_vector;
        signal i_offset        : in std_logic_vector;
        signal o_result        : out std_logic_vector
    ) is
    signal add, add_temp : unsigned (i_data'length downto 0);-- 1 bit more then i_data
    signal data_signed : std_logic_vector(i_data'length downto 0); -- 1 bit more then i_data
    signal sub : signed (i_data'length -1 downto 0);
    begin
    --plan: offset is signed -> convert to signed first? or just check the msb first?
    --      then: data to unsigend check if extra 0 is needed
    if i_offset(i_offset'left) = '0' then 
        add <= UNSIGNED(i_data) + UNSIGNED(i_offset);
        add_temp <= add; -- to get the same delay as with negativ offset
        o_result <= std_logic_vector(add_temp);
    else
        data_signed <= '0' & i_data;
        sub <= SIGNED(data_signed) - SIGNED(i_offset);
        o_result <= std_logic_vector(sub(sub'left -1 downto 0));
        
    end if;
    
    end procedure dig_offset;
    
    function dig_gain(
        i_data, factor      :std_logic_vector;
        decimals, res_width :integer     --integer ?? generic?? better with logic_vector??
    )return std_logic_vector is
    begin
    
    end function dig_gain;
    
end package body fbv_pkg;