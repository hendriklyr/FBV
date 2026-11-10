------------------------------------------------------------------------
-- FBV Laborversuch 2: Synchronisation und Deserialisierung (Testbench)
-- (C) 2013, Kurt Ackermann
-- Hochschule Mannheim
--
-- Simulationszeit: ~ 35 us (Resync wird 4x angestossen)
------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY top_TB IS
END top_TB;
 
ARCHITECTURE behavior OF top_TB IS 
 
    COMPONENT top
    PORT(
         sysclk   : IN  std_logic;
         rst      : IN  std_logic;
         resync   : IN  std_logic;
         dclk_p   : IN  std_logic;
         dclk_n   : IN  std_logic;
         i_DATA_p : IN  std_logic;
         i_DATA_n : IN  std_logic;
		 o_locked : OUT STD_LOGIC;
         o_data   : OUT STD_LOGIC_VECTOR(7 downto 0);
		 o_done   : OUT STD_LOGIC;
		 o_err    : OUT STD_LOGIC);			
    END COMPONENT;
    
	-- Clock period definitions
	constant sysclk_period : time := 15 ns;	    --  66,67 MHz
	constant dclk_period   : time := 3.2 ns;	-- 312,50 MHz
	 
	signal sysclk   : std_logic := '0';
	signal rst      : std_logic := '1';
	signal resync   : std_logic := '0';
	signal dclk_p   : std_logic := '0';
	signal dclk_n   : std_logic := '0';
	signal i_DATA_p : std_logic := '0';
	signal i_DATA_n : std_logic := '1';
	signal o_data   : std_logic_vector(7 downto 0);
	signal o_done, o_err, o_locked  : std_logic;
	signal nxt_data : std_logic := '0';

	-- repeating trainings-pattern
	signal data_sr : std_logic_vector(7 downto 0) := x"C5";
	
	signal data_tm1, data_tp1, data_t, data_tmp : std_logic;
	signal noise, noise_smpl : std_logic := '0';
	signal noise_en : std_logic := '1';
	signal pat_chg  : std_logic := '0';
	
	constant t1  : time := 10 ps;
	constant t2  : time := 3900 ps;
	signal t_res : time := t1;
	
BEGIN
    
	uut: top PORT MAP (
		sysclk   => sysclk,
		rst      => rst,
		resync   => resync,
		dclk_p   => dclk_p,
		dclk_n   => dclk_n,
		i_DATA_p => i_DATA_p,
		i_DATA_n => i_DATA_n,
		o_locked => o_locked,
		o_data   => o_data,
		o_done   => o_done,
		o_err    => o_err);

   sysclk_process :process
   begin
		sysclk <= not sysclk;
		wait for sysclk_period/2;
   end process;
   dclk_process :process
   begin
		dclk_p <= not dclk_p;
		wait for dclk_period/2;
   end process;
	dclk_n <= not dclk_p;

	-- generate "random" data to simulate noise at signal transitions
	process
	begin
		noise <= not noise;
		wait for 57 ps;
	end process;

	rst <= '1', '0' after 100 ns;
	
	process
	begin
		wait until o_locked='1';
		resync <= '0'; wait for 1 us;
		resync <= '1'; wait for 30 ns;
		resync <= '0'; 
		wait until (o_err or o_done)='1';
		
		wait for 1 us;
		nxt_data <= '1';
		wait for 1 us;
		resync <= '1'; wait for 30 ns;
		resync <= '0';
		wait until (o_err or o_done)='1';
		
		wait for 1 us;
		noise_en <= '0';
		wait for 1 us;
		resync <= '1'; wait for 30 ns;
		resync <= '0';		
		wait until (o_err or o_done)='1';
		
		wait for 1 us;
		pat_chg <= '1';
		wait for 1 ns;
		pat_chg <= '0';
		resync  <= '1'; wait for 30 ns;
		resync  <= '0';		
		wait;
	end process;
	
	process(dclk_p, pat_chg)
	begin
		if (pat_chg = '1') then
			data_sr <= x"D5";
	    elsif (dclk_p'event) then
			data_sr    <= data_sr(data_sr'left-1 downto 0) & data_sr(data_sr'left);
			noise_smpl <= noise;
		end if;
	end process;
	
	-- delay data to detect signal transitions
	data_tm1 <= data_sr(data_sr'left);
	data_t   <= transport data_tm1 after dclk_period/16;
	data_tp1 <= transport data_t   after dclk_period/16;
	
	-- insert random value at transitions
	data_tmp <= data_t when (data_tm1=data_tp1 or noise_en='0') else noise_smpl;
	-- additionally delay data-channel to be suitable for IDELAY simulation
	i_DATA_p <= transport data_tmp after t_res;
	i_DATA_n <= not i_DATA_p;
	
	-- change data offset for second resync
	t_res <= t1 when nxt_data='0' else t2;
	
END;