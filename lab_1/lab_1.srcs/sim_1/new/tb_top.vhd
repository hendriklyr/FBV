----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/21/2026 02:23:37 PM
-- Design Name: 
-- Module Name: tb_top - Behavioral
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
use IEEE.numeric_std.all;

use STD.textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_top is
--  Port ( );
end tb_top;

architecture Behavioral of tb_top is


component top 
    Port(  i_dig_gain : in STD_LOGIC_VECTOR (7 downto 0);
           i_dig_offset : in STD_LOGIC_VECTOR (7 downto 0);
           i_video : in STD_LOGIC_VECTOR (7 downto 0);
           i_clk : in STD_LOGIC;
           i_fval : in STD_LOGIC;
           i_lval : in STD_LOGIC;
           o_video : out STD_LOGIC_VECTOR(7 downto 0);
           o_fval : out STD_LOGIC;
           o_lval : out STD_LOGIC);
end component;
           
           
        
--type TEXT is file of STRING;
--type LINE is access STRING;

signal tb_clk :std_logic := '1';
signal tb_i_video: std_logic_vector(7 downto 0);
--signal pic_data : std_logic_vector(;
signal tb_dig_gain : STD_LOGIC_VECTOR (7 downto 0);
signal tb_dig_offset :  STD_LOGIC_VECTOR (7 downto 0);

signal tb_i_fval :  STD_LOGIC;
signal tb_i_lval : STD_LOGIC;
signal tb_i_fval_intern :  STD_LOGIC;
signal tb_i_lval_intern : STD_LOGIC;
signal tb_o_video :STD_LOGIC_VECTOR(7 downto 0);
signal tb_o_fval : STD_LOGIC;
signal tb_o_lval : STD_LOGIC;
shared variable value : integer;
shared variable height : integer;
shared variable width: integer;
shared variable bit_width : integer;

begin
    uut: top port map(
       i_dig_gain => tb_dig_gain ,
       i_dig_offset => tb_dig_offset,
       i_video => tb_i_video,
       i_clk  => tb_clk ,
       i_fval  => tb_i_fval,
       i_lval => tb_i_lval,
       o_video => tb_o_video,
       o_fval => tb_o_fval,
       o_lval => tb_o_lval
    );
    

P_CLK : process
begin
    tb_clk <= not tb_clk;
    wait for 5 ns;
end process;

tb_dig_gain <= "00000110";
tb_dig_offset <= "00010100";

SYNC : process(tb_clk)
begin

    --tb_i_video <= tb_i_video;
    
    tb_i_fval  <= tb_i_fval_intern;
    tb_i_lval <= tb_i_lval_intern;
end process;

P_INPUT_FILE : process
    file input_file : TEXT open read_mode is "C:\Users\lagah\Documents\Studium\Semester_6\lena_sw.txt" ; -- maybe another ..\ needed
    
    variable inline : LINE;

    
    variable is_first_line : boolean := true;
begin
 
    while not (endfile(input_file)) loop
        tb_i_fval_intern <= '1';
        readline(input_file, inline);
        if is_first_line then 
            read(inline, width);
            report ("Picture DATA: "& integer'image(width));
            read(inline, height );
            report ("Picture DATA: "& integer'image(height));
            read(inline, bit_width);
            report ("Picture DATA: "& integer'image(bit_width));
            is_first_line := false;
        else 
            for x in 1 to width loop
                
                wait until rising_edge(tb_clk);
                tb_i_lval_intern <= '1';
                read(inline, value);
                
                tb_i_video <= std_logic_vector(TO_UNSIGNED(value,8)); 
                             
            end loop;
            tb_i_lval_intern <= '0';
            wait for 200 ns;
        end if;
    end loop;
    tb_i_fval_intern <= '0';
    
        
    --    while (endfile(input_file)) loop
    --        readline(input_file, inline);
    --        read(inline, value);
    --        tb_i_video <= std_logic_vector(value);
    --    end loop;
    
    
end process;
P_OUTPUT_FILE: process
file output_file : TEXT open write_mode is "C:\Users\lagah\Documents\Studium\Semester_6\lena_sw_new.txt" ;
    --variable inline : LINE;
    --variable value : integer;
    variable buf: LINE;
    variable is_first_line : boolean := true;
    variable tb_o_lval_ff: std_logic;
begin 

    wait until tb_o_fval = '1';
    
    write(buf, width);
    write(buf, string'(" "));
    write(buf, height);
    write(buf, string'(" "));
    write(buf, bit_width);
    writeline(output_file, buf);
    
    while tb_o_fval = '1' loop
        wait until rising_edge(tb_clk);
        
        if tb_o_lval = '1' then
            report("o_lval = 1");
            write(buf, TO_INTEGER(unsigned(tb_o_video)));
            write(buf, string'(" "));
        elsif tb_o_lval_ff = '1' and tb_o_lval = '0' then
            report("o_lval = 0");
            writeline(output_file, buf);
        end if;
        
        tb_o_lval_ff := tb_o_lval;
          
    end loop;
    wait;  
end process;
end Behavioral;
