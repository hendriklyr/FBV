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
attribute IODELAY_GROUP of IDELAYE2_inst, IDELAYCTRL_inst: label is "coolers_lable";

signal idelayctrl_ready,idelayctrl_rst , pll_locked : std_logic;
signal sysclk_bufg, clk200_bufg : std_logic;

signal dclk_int, not_dclk_int : std_logic;
signal dclk_bufio : std_logic;
signal dclk_pixel : std_logic;

signal data_int : std_logic; 
signal data_delayed : std_logic;  
signal idelay_rdy : std_logic;

--Signale fuer IDELAY2 
signal idelay_ld : std_logic := '0'; 
signal idelay_ce : std_logic := '0'; -- enable increment/decrement
signal idelay_inc : std_logic := '0';  -- 0 is decrement 1 is inc
signal idelay_cntin : std_logic_vector(4 downto 0) := (others => '0'); 
signal idelay_cntout : std_logic_vector(4 downto 0);

signal bitslip_sig : std_logic := '0';

-- SIGNALE fuer FSM MAIN
signal is_first_stable, is_first_not_stable : STD_LOGIC := '1';
signal sc_stable , sc_done, t_sc_stable , t_sc_done :std_logic := '0';
signal align_done, align_err, t_align_done, t_align_err : std_logic := '0';
signal tab_counter, current_tab_length,left_tab_length, current_start_tab, left_start_tab, current_end_tab, left_end_tab : unsigned( 4 downto 0) := "00000";
signal mid_calc : unsigned(tab_counter'length downto 0); -- 1 bit laenger fuer addition
signal mid : unsigned (tab_counter'left downto 0);

-- SIGNALE fuer FSM STABLE CHECK

signal start_sc, t_start_sc : std_logic := '0';
signal prev_data, w_data : std_logic_vector(7 downto 0);
signal sc_counter : unsigned( 2 downto 0);

-- SIGNALE fuer FSM WORD ALIGN
signal start_align, t_start_align: std_logic := '0';
signal test_data : std_logic_vector(7 downto 0) := x"C5";
signal wait_cnt: unsigned(1 downto 0);
signal bitslip_cnt: unsigned(2 downto 0);

type MAIN_STATE_TYPE is (IDLE ,START_STABLE_CHECK, WAIT_STABLE_CHECK, FIRST_STABLE, FIRST_NOT_STABLE, REACHED_32, MID_FINDER, CALC_MID, STABLE_OR_NOT,GET_MID_TAP,START_WORD_ALIGN, WAIT_WORD_ALIGN, INCREMENT);

signal MAIN_STATE: MAIN_STATE_TYPE;

type STABLE_STATE_TYPE is (IDLE, COMPARE_STATE );
signal STABLE_STATE : STABLE_STATE_TYPE;

type WORD_STATE_TYPE is ( IDLE, COMPARE_STATE, WAIT_STATE);
signal WORD_STATE : WORD_STATE_TYPE;

component clk_wiz_0 is
    port (
        clk_in1   : in std_logic;
        clk_out1 : out std_logic;
        clk_out2 : out std_logic;
        locked : out std_logic;
        reset : in std_logic
        
    );
end component;
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
    
    --Aufgabe 1ii

   IBUFDS_CLK : IBUFDS
   generic map (
      DIFF_TERM => FALSE, -- Differential Termination 
      IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD => "DEFAULT")
   port map (
      O => dclk_int,  -- Buffer output
      I => dclk_p,  -- Diff_p buffer input (connect directly to top-level port)
      IB => dclk_n -- Diff_n buffer input (connect directly to top-level port)
   );
    
    IBUFDS_DATA : IBUFDS
   generic map (
      DIFF_TERM => FALSE, -- Differential Termination 
      IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD => "DEFAULT")
   port map (
      O => data_int,  -- Buffer output
      I => i_DATA_p,  -- Diff_p buffer input (connect directly to top-level port)
      IB => i_DATA_n -- Diff_n buffer input (connect directly to top-level port)
   );
    
   BUFIO_inst : BUFIO
   port map (
      O => dclk_bufio, -- 1-bit output: Clock output (connect to I/O clock loads).
      I => dclk_int  -- 1-bit input: Clock input (connect to an IBUF or BUFMR).
   );
   not_dclk_int <= (not dclk_int);
   
   BUFR_inst : BUFR
   generic map (
      BUFR_DIVIDE => "4",   -- Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
      SIM_DEVICE => "7SERIES"  -- Must be set to "7SERIES" 
   )
   port map (
      O => dclk_pixel,     -- 1-bit output: Clock output port
      CE => '1',   -- 1-bit input: Active high, clock enable (Divided modes only)
      CLR => '0', -- 1-bit input: Active high, asynchronous clear (Divided modes only)
      I => dclk_int     -- 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
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
      IDELAY_TYPE => "VAR_LOAD",           -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
      IDELAY_VALUE => 0,                -- Input delay tap setting (0-31)
      PIPE_SEL => "FALSE",              -- Select pipelined mode, FALSE, TRUE
      REFCLK_FREQUENCY => 200.0,        -- IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
      SIGNAL_PATTERN => "DATA"          -- DATA, CLOCK input signal
   )
   port map (
      CNTVALUEOUT => idelay_cntout,         -- 5-bit output: Counter value output
      DATAOUT => data_delayed,              -- 1-bit output: Delayed data output
      C => sysclk_bufg,                     -- 1-bit input: Clock input
      CE => idelay_ce,                      -- 1-bit input: Active high enable increment/decrement input --vllt auch dauerhaft auf 
      CINVCTRL => '0',                      -- 1-bit input: Dynamic clock inversion input
      CNTVALUEIN => idelay_cntin,           -- 5-bit input: Counter value input
      DATAIN => '0',                        -- 1-bit input: Internal delay data input
      IDATAIN => data_int,                  -- 1-bit input: Data input from the I/O
      INC => idelay_inc,                    -- 1-bit input: Increment / Decrement tap delay input
      LD => idelay_ld,                      -- 1-bit input: Load IDELAY_VALUE input
      LDPIPEEN => '0',                      -- 1-bit input: Enable PIPELINE register to load data input
      REGRST => '0'                          -- 1-bit input: Active-high reset tap-delay input
   );
   -- ###muss idelay signale noch sync gemacht werden?###
    P_SYNC_IDELAY2_SIGNALS : process(sysclk_bufg)
    begin
        if rising_edge(sysclk_bufg) then 
            
        end if;
    end process;
    
   
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
      O => open,                       -- 1-bit output: Combinatorial output
      -- Q1 - Q8: 1-bit (each) output: Registered data outputs
      Q1 => w_data(0),
      Q2 => w_data(1),
      Q3 => w_data(2),
      Q4 => w_data(3),
      Q5 => w_data(4),
      Q6 => w_data(5),
      Q7 => w_data(6),
      Q8 => w_data(7),
      -- SHIFTOUT1, SHIFTOUT2: 1-bit (each) output: Data width expansion output ports
      SHIFTOUT1 => open,
      SHIFTOUT2 => open,
      BITSLIP => bitslip_sig,           -- 1-bit input: The BITSLIP pin performs a Bitslip operation synchronous to
                                    -- CLKDIV when asserted (active High). Subsequently, the data seen on the
                                    -- Q1 to Q8 output ports will shift, as in a barrel-shifter operation, one
                                    -- position every time Bitslip is invoked (DDR operation is different from
                                    -- SDR).

      -- CE1, CE2: 1-bit (each) input: Data register clock enable inputs
      CE1 => '1',
      CE2 => '1',
      CLKDIVP => '0',           -- 1-bit input: TBD -- Clocks: 1-bit (each) input: ISERDESE2 clock input ports
      CLK => dclk_int,                   -- 1-bit input: High-speed clock -- ###muss dclk noch mit ibugio syncroniesiert wertden??### TODO: aufgabe 1)ii 
      CLKB => not_dclk_int,                 -- 1-bit input: High-speed secondary clock
      CLKDIV => dclk_pixel,--muss noch gemacht werden        -- 1-bit input: Divided clock
      OCLK => '0',                 -- 1-bit input: High speed output clock used when INTERFACE_TYPE="MEMORY" 
      -- Dynamic Clock Inversions: 1-bit (each) input: Dynamic clock inversion pins to switch clock polarity
      DYNCLKDIVSEL => '0', -- 1-bit input: Dynamic CLKDIV inversion
      DYNCLKSEL => '0',       -- 1-bit input: Dynamic CLK/CLKB inversion
      -- Input Data: 1-bit (each) input: ISERDESE2 data input ports
      D => '0',                       -- 1-bit input: Data input
      DDLY => data_delayed,                 -- 1-bit input: Serial data from IDELAYE2
      OFB => '0',                   -- 1-bit input: Data feedback from OSERDESE2
      OCLKB => '0',               -- 1-bit input: High speed negative edge output clock
      RST => rst,                   -- 1-bit input: Active high asynchronous reset
      -- SHIFTIN1, SHIFTIN2: 1-bit (each) input: Data width expansion input ports
      SHIFTIN1 => '0',
      SHIFTIN2 => '0'
   );

   --Aufgabe 4
 
    P_SYNC: process(sysclk_bufg) 
    begin 
    end process;

   
   
   P_FSM_MAIN : process(sysclk_bufg)
   begin 
        if rising_edge(sysclk_bufg) then 
            idelay_ld <= '0';
            idelay_ce <= '0';
            start_sc <= '0';
            start_align <= '0';
            if rst = '1' then
                o_done <= '0';
                o_err <= '0';
                o_locked <= '1';
                MAIN_STATE <= IDLE;
            end if;
            case MAIN_STATE is 
                when IDLE => 
                    if (resync = '1') then 
                        o_done <= '0';
                        o_err <= '0';
                        idelay_ld <='1';
                        tab_counter <= TO_UNSIGNED(0,5);
                        current_tab_length <= to_unsigned(0,5);
                        current_start_tab <= to_unsigned(0,5);
                        current_end_tab <= to_unsigned(0,5);
                        idelay_cntin <= "00000";
                        left_tab_length <= to_unsigned(0,5);  
                        MAIN_STATE <= START_STABLE_CHECK;
                    end if;
                    
                when START_STABLE_CHECK => 
                    start_sc <=  '1'; 
                    MAIN_STATE <= WAIT_STABLE_CHECK;
                   
                    
                when WAIT_STABLE_CHECK => 
                    if t_sc_done = '1' then 
                        MAIN_STATE <= STABLE_OR_NOT;
                    end if;
                     
                when STABLE_OR_NOT => 
                    if (t_sc_stable = '1') then 
                        MAIN_STATE <= FIRST_STABLE;
                    else
                        MAIN_STATE <= FIRST_NOT_STABLE;
                    end if;
                    
                when FIRST_STABLE =>
                    if(is_first_stable = '1') then 
                        current_start_tab <= tab_counter;
                        current_tab_length <= to_unsigned(0,5);
                        current_end_tab <= tab_counter;
                        is_first_stable <= '0';
                        is_first_not_stable <= '1';
                    else
                        current_tab_length <= current_tab_length +1 ;
                        current_end_tab <= tab_counter;
                    end if;
                    MAIN_STATE <= INCREMENT;
                    
                when FIRST_NOT_STABLE => 
                    if is_first_not_stable = '1' then 
                        if left_tab_length = "00000" then
                            left_start_tab <= current_start_tab;
                            left_tab_length <= current_tab_length;
                            left_end_tab <= current_end_tab;
                            current_start_tab <= to_unsigned(0,5);
                            current_tab_length <= to_unsigned(0,5);
                            current_end_tab <= to_unsigned(0,5);
                            is_first_stable <= '1';
                            is_first_not_stable <= '0';  
                        end if;                   
                    end if;
                    MAIN_STATE <= INCREMENT;
                    
                when INCREMENT =>
                    tab_counter <= tab_counter + 1; 
                    idelay_inc <= '1'; -- kann auch weggelassen werden? sollte ja immer 1 sein 
                    idelay_ce <= '1'; -- wird nach einem Takt wieder zurueck gesetzt
                    MAIN_STATE <= REACHED_32;
                    
                when REACHED_32 => 
                    if (tab_counter = 31) then 
                        MAIN_STATE <= MID_FINDER;
                    else
                        MAIN_STATE <= START_STABLE_CHECK;
                    end if;
                    
                when MID_FINDER => 
                    if left_tab_length = 0 then 
                        mid_calc <= ('0' & current_start_tab) + current_end_tab;
                        --mid <= mid_calc(mid_calc'left downto 1); -- (start+ende)/2
                    else
                        if left_tab_length > current_tab_length then 
                            mid_calc <= ('0' & left_start_tab) + left_end_tab;
                            --mid <= mid_calc(mid_calc'left downto 1);
                        else
                            mid_calc <= ('0' & current_start_tab) + current_end_tab;
                            --mid <= mid_calc(mid_calc'left downto 1); -- (start+ende)/2
                        end if;
                    MAIN_STATE <= CALC_MID;    
                    end if;
                    
                when CALC_MID => 
                    mid <= mid_calc(mid_calc'left downto 1);
                    MAIN_STATE <= GET_MID_TAP;
                    
                when GET_MID_TAP =>
                    idelay_cntin <= std_logic_vector(mid);
                    idelay_ld <= '1';
                    MAIN_STATE <= START_WORD_ALIGN;    

                when START_WORD_ALIGN =>
                    start_align <= '1';
                    MAIN_STATE <= WAIT_WORD_ALIGN;
                    
                when WAIT_WORD_ALIGN =>
                    if t_align_done = '1' then
                        if t_align_err = '1' then
                            o_err <= '1';
                        else
                            o_done <= '1'; 
                        end if;
                        
                        MAIN_STATE <= IDLE; 
                    end if;
                    
            end case;
        end if;
   end process;   
   
   P_FSM_STABLE_CHECK: process(dclk_pixel) -- sysclk_bufg weil idelay auch danit getaktet ist
   begin
        if rising_edge(dclk_pixel) then
            prev_data <= w_data;
            if rst = '1' then
                sc_done <= '0';
                sc_counter <= TO_UNSIGNED(0,3);
                STABLE_STATE <= IDLE;
            end if;
            case STABLE_STATE is
                when IDLE => if (t_start_sc = '1') then
                        STABLE_STATE <= COMPARE_STATE;
                    end if;
                    
                when COMPARE_STATE => 
                    
                        if ( prev_data = w_data) then 
                            sc_counter <= sc_counter +1 ;
                            
                            if sc_counter = 5 then 
                                sc_stable <='1';
                                sc_counter <= to_unsigned(0,3);
                                sc_done <= '1';
                                
                                STABLE_STATE <= IDLE;
                                   
                            end if;
                        else
                            sc_counter <= to_unsigned(0,3);
                            sc_stable <='0';
                            sc_done <= '1'; -- meta stabilit't beachten
                            STABLE_STATE <= IDLE;
                                               
                        end if; 
            end case;
        end if;
   end process;
   
   
   P_FSM_WORD_ALLIGN : process(dclk_pixel)
   begin
        if rising_edge(dclk_pixel) then 
            bitslip_sig <= '0';
            
            if rst = '1' then
                align_done <= '0';
                wait_cnt <= TO_UNSIGNED(0,2);
                bitslip_cnt <= TO_UNSIGNED(0,3);
                WORD_STATE <= IDLE;
            end if;
            
            case WORD_STATE is
                when IDLE => if (t_start_align = '1') then
                        align_done <= '0';
                        align_err <= '0';
                        wait_cnt <= TO_UNSIGNED(0,2);
                        bitslip_cnt <= TO_UNSIGNED(0,3);
                        WORD_STATE <= COMPARE_STATE;
                    end if;
                when COMPARE_STATE => 
                    if (w_data = test_data) then
                        align_done <= '1';
                        WORD_STATE <= IDLE;
                    else
                        if (bitslip_cnt = 7) then
                            align_err <= '1';
                            align_done <= '1';  
                            WORD_STATE <= IDLE;                   
                        else
                            bitslip_cnt <= bitslip_cnt + 1;
                            bitslip_sig <= '1';
                            WORD_STATE <= WAIT_STATE;
                        end if;
                        
                    end if;
                when WAIT_STATE => 
                    if wait_cnt = 2 then
                        wait_cnt <= TO_UNSIGNED(0,2);
                        WORD_STATE <= COMPARE_STATE;
                    else              
                        wait_cnt <= wait_cnt + 1; 
                    end if;
            end case;
        end if; 
   
   end process;
   
   SYNC: process(sysclk_bufg)
   begin 
        if rising_edge(sysclk_bufg) then 
        t_start_sc <= start_sc;
        t_sc_done <= sc_done;
        t_sc_stable <= sc_stable;
        t_start_align <= start_align;
        t_align_done <= align_done;
        t_align_err <= align_err;
        
        end if;
   end process;

end Behavioral;
