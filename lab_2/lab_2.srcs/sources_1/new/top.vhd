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
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

-- IDELAYCTRL  : In order to incorporate this function into the design,
--    VHDL     : the following instance declaration needs to be placed
--  instance   : in the body of the design code.  The instance name
-- declaration : (IDELAYCTRL_inst) and/or the port declarations after the
--    code     : "=>" declaration maybe changed to properly reference and
--             : connect this function to the design.  All inputs and outputs
--             : must be connected.

--   Library   : In addition to adding the instance declaration, a use
-- declaration : statement for the UNISIM.vcomponents library needs to be
--     for     : added before the entity declaration.  This library
--   Xilinx    : contains the component declarations for all Xilinx
-- primitives  : primitives and points to the models that will be used
--             : for simulation.


				
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

--  Put the following attribute before the 'begin' statement
--  Specifies group name for associated IDELAYs/ODELAYs and IDELAYCTRL

attribute IODELAY_GROUP : STRING;
attribute IODELAY_GROUP of <label_name>: label is "<iodelay_group_name>";
signal idelayctrl_ready,idelayctrl_rst , pll_locked : std_logic;
signal sysclk_bufg, clk200_bufg : std_logic;

signal data_int : std_logic; 
signal data_delayed : std_logic;  
signal idelay_rdy : std_logic;

--Signale fuer IDELAY2 
signal idelay_ld : std_logic := '0'; 
signal idelay_ce : std_logic := '0'; 
signal idelay_inc : std_logic := '0'; 
signal idelay_cntin : std_logic_vector(4 downto 0) := (others => '0'); 
signal idelay_cntout : std_logic_vector(4 downto 0);

signal bitslip_sig : std_logic := '0';


type MAIN_STATE_TYPE is (IDLE ,START_STABLE_CHECK, WAIT_STABLE_CHECK, START_WORD_ALLIGN, WAIT_WORD_ALLIGN);

signal MAIN_STATE, MAIN_NEXT_STATE : MAIN_STATE_TYPE;

type STABLE_STATE_TYPE is (IDLE );
signal STABLE_STATE, STABLE_NEXT_STATE : STABLE_STATE_TYPE;

type WORD_STATE_TYPE is ( IDLE);
signal WORD_STATE, WORD_NEXT_STATE : WORD_STATE_TYPE;
begin

    
    -- Aufgabe 1 PLL
    U_clk_wiz : clk_wiz_0
    port map (
        clk_in1 => sysclk, -- 66.67 MHz Eingang
        clk_out1 => clk200_bufg, -- 200 MHz Ausgang 
        clk_out2 => sysclk_bufg,
        locked => pll_locked, -- Locked-Signal 
        reset => rst 
    );
        
    --bufg_inst : BUFG
    --port map (
      --  I => sysclk,   -- clk
      --  O => sysclk_bufg   -- bufferd global clk
   -- );

   -- Aufgabe 2
   IDELAYCTRL_inst : IDELAYCTRL
   port map (
      RDY => idelayctrl_ready,       -- 1-bit output: Ready output
      REFCLK => clk200_bufg, -- 1-bit input: Reference clock input
      RST => idelayctrl_rst        -- 1-bit input: Active high reset input
   );
   
   idelayctrl_rst <= rst or pll_locked; 
   
   
   IDELAYE2_inst : IDELAYE2
   generic map (
      CINVCTRL_SEL => "FALSE",          -- Enable dynamic clock inversion (FALSE, TRUE)
      DELAY_SRC => "IDATAIN",           -- Delay input (IDATAIN, DATAIN)
      HIGH_PERFORMANCE_MODE => "FALSE", -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
      IDELAY_TYPE => "FIXED",           -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
      IDELAY_VALUE => 0,                -- Input delay tap setting (0-31)
      PIPE_SEL => "FALSE",              -- Select pipelined mode, FALSE, TRUE
      REFCLK_FREQUENCY => 200.0,        -- IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
      SIGNAL_PATTERN => "DATA"          -- DATA, CLOCK input signal
   )
   port map (
      CNTVALUEOUT => idelay_cntout,         -- 5-bit output: Counter value output
      DATAOUT => data_delayed,              -- 1-bit output: Delayed data output
      C => sysclk_bufg,                     -- 1-bit input: Clock input
      CE => idelay_ce,                      -- 1-bit input: Active high enable increment/decrement input
      CINVCTRL => '0',                      -- 1-bit input: Dynamic clock inversion input
      CNTVALUEIN => idelay_cntin,           -- 5-bit input: Counter value input
      DATAIN => '0',                        -- 1-bit input: Internal delay data input
      IDATAIN => data_int,                  -- 1-bit input: Data input from the I/O
      INC => idelay_inc,                    -- 1-bit input: Increment / Decrement tap delay input
      LD => idelay_ld,                      -- 1-bit input: Load IDELAY_VALUE input
      LDPIPEEN => '0',                      -- 1-bit input: Enable PIPELINE register to load data input
      REGRST => '0                          -- 1-bit input: Active-high reset tap-delay input
   );
   -- ###muss idelay signale noch sync gemacht werden?###
   
   -- Aufgabe 3
   
   -- ISERDESE2: Input SERial/DESerializer with Bitslip
   --            Artix-7
   -- Xilinx HDL Language Template, version 2025.2

   ISERDESE2_inst : ISERDESE2
   generic map (
      DATA_RATE => "DDR",           -- DDR, SDR
      DATA_WIDTH => 8,              -- Parallel data width (2-8,10,14)
      DYN_CLKDIV_INV_EN => "FALSE", -- Enable DYNCLKDIVINVSEL inversion (FALSE, TRUE)
      DYN_CLK_INV_EN => "FALSE",    -- Enable DYNCLKINVSEL inversion (FALSE, TRUE)
      -- INIT_Q1 - INIT_Q4: Initial value on the Q outputs (0/1)
      INIT_Q1 => '0',
      INIT_Q2 => '0',
      INIT_Q3 => '0',
      INIT_Q4 => '0',
      INTERFACE_TYPE => "NETWORKING",   -- MEMORY, MEMORY_DDR3, MEMORY_QDR, NETWORKING, OVERSAMPLE
      IOBDELAY => "IFD",           -- NONE, BOTH, IBUF, IFD
      NUM_CE => 2,                  -- Number of clock enables (1,2)
      OFB_USED => "FALSE",          -- Select OFB path (FALSE, TRUE)
      SERDES_MODE => "MASTER",      -- MASTER, SLAVE
      -- SRVAL_Q1 - SRVAL_Q4: Q output values when RST is used (0/1)
      SRVAL_Q1 => '0',
      SRVAL_Q2 => '0',
      SRVAL_Q3 => '0',
      SRVAL_Q4 => '0'
   )
   port map (
    --  O => O,                       -- 1-bit output: Combinatorial output
      -- Q1 - Q8: 1-bit (each) output: Registered data outputs
      Q1 => o_data(7),
      Q2 => o_data(6),
      Q3 => o_data(5),
      Q4 => o_data(4),
      Q5 => o_data(3),
      Q6 => o_data(2),
      Q7 => o_data(1),
      Q8 => o_data(0),
      -- SHIFTOUT1, SHIFTOUT2: 1-bit (each) output: Data width expansion output ports
      --SHIFTOUT1 => SHIFTOUT1,
      --=SHIFTOUT2 => SHIFTOUT2,
      BITSLIP => bitslip_sig,           -- 1-bit input: The BITSLIP pin performs a Bitslip operation synchronous to
                                    -- CLKDIV when asserted (active High). Subsequently, the data seen on the
                                    -- Q1 to Q8 output ports will shift, as in a barrel-shifter operation, one
                                    -- position every time Bitslip is invoked (DDR operation is different from
                                    -- SDR).

      -- CE1, CE2: 1-bit (each) input: Data register clock enable inputs
      CE1 => '1',
      CE2 => '1',
      --CLKDIVP => CLKDIVP,           -- 1-bit input: TBD -- Clocks: 1-bit (each) input: ISERDESE2 clock input ports
      CLK => dclk_p,                   -- 1-bit input: High-speed clock -- ###muss dclk noch mit ibugio syncroniesiert wertden??### TODO: aufgabe 1)ii 
      CLKB => dclk_n,                 -- 1-bit input: High-speed secondary clock
      CLKDIV => CLKDIV,     --muss noch gemacht werden        -- 1-bit input: Divided clock
      --OCLK => OCLK,                 -- 1-bit input: High speed output clock used when INTERFACE_TYPE="MEMORY" 
      -- Dynamic Clock Inversions: 1-bit (each) input: Dynamic clock inversion pins to switch clock polarity
   --   DYNCLKDIVSEL => DYNCLKDIVSEL, -- 1-bit input: Dynamic CLKDIV inversion
   --   DYNCLKSEL => DYNCLKSEL,       -- 1-bit input: Dynamic CLK/CLKB inversion
      -- Input Data: 1-bit (each) input: ISERDESE2 data input ports
      D => '0',                       -- 1-bit input: Data input
      DDLY => data_delayed,                 -- 1-bit input: Serial data from IDELAYE2
    --  OFB => OFB,                   -- 1-bit input: Data feedback from OSERDESE2
     -- OCLKB => OCLKB,               -- 1-bit input: High speed negative edge output clock
      RST => rst,                   -- 1-bit input: Active high asynchronous reset
      -- SHIFTIN1, SHIFTIN2: 1-bit (each) input: Data width expansion input ports
     -- SHIFTIN1 => SHIFTIN1,
     -- SHIFTIN2 => SHIFTIN2
   );

   --Aufgabe 4
 
   P_FSM_MAIN : process(sysclk_bufg) 
   begin
        if rising_edge(sysclk_bufg) then 
            MAIN_STATE <= MAIN_NEXT_STATE;
        end if;
   end process;
   
   P_FSM_MAIN_CASE : process(MAIN_STATE, resync)
   begin 
   end process;   
   P_FSM_STABLE_CHECK: process
   begin
   end process;
   
   P_FSM_WORD_ALLIGN : process
   begin 
   
   end process;
				

   




end Behavioral;
