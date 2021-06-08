----------------------------------------------------------------------------------
-- Company: ENGS 31 / COSC 56
-- Engineer: Aadhya Kocha & Lukas Hoffman
-- 
-- Create Date: 06/04/2021 07:54:12 PM
-- Design Name: Morse Shell Testbench
-- Module Name: morse_tb - Behavioral
-- Project Name: Morse Code Generator
-- Target Devices: 
-- Tool Versions: 
-- Description: Testbench for a Morse Code Generator
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 1.0 - Final Version
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.all;
 
ENTITY morse_tb IS
END morse_tb;
 
ARCHITECTURE behavior OF morse_tb IS 
 
COMPONENT morse_shell
	PORT(
		clk : IN std_logic;
		submit: IN std_logic;
		RsRx : IN std_logic;
		morse_sig :  out std_logic);
	END COMPONENT;
  
   --Inputs
   signal clk : std_logic := '0';
   signal morse_clk: std_logic := '0';
   signal RsRx : std_logic := '1';
   signal submit: std_logic := '0';
 	--Outputs
   signal morse_sig : std_logic;

   -- Clock period definitions
   constant clk_period : time := 100ns;		-- 10 MHz clock
   constant morse_clk_period: time := 10 ns;
	
	-- Data definitions
	constant bit_time : time := 104us;		-- 9600 baud
	--constant bit_time : time := 8.68us;		-- 115,200 baud
	signal TxData : std_logic_vector(7 downto 0) := "01000101";

	
BEGIN 
	-- Instantiate the Unit Under Test (UUT)
   uut: morse_shell PORT MAP (
          submit => submit,
          clk => clk,
          RsRx => RsRx,
          morse_sig => morse_sig
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
   
   morse_clk_process :process
   begin
		morse_clk <= '1';
		wait for morse_clk_period/2;
		morse_clk <= '0';
		wait for morse_clk_period/2;
   end process;
 
   -- Stimulus process
   stim_proc: process
   begin
        TxData <= "01000101";		
		wait for 100 us;
		wait for 10.25*clk_period;		
		
		RsRx <= '0';		-- Start bit
		wait for bit_time;
		
		for bitcount in 0 to 7 loop
			RsRx <= TxData(bitcount);
			wait for bit_time;
		end loop;
		
		RsRx <= '1';		-- Stop bit
		
		TxData <= "01000010";
		wait for 200 us;
		
		RsRx <= '0';		-- Start bit
		wait for bit_time;
		
		for bitcount in 0 to 7 loop
			RsRx <= TxData(bitcount);
			wait for bit_time;
		end loop;
		
		RsRx <= '1';		-- Stop bit
		wait for 200 us;
		submit <= '1';
		wait for 300 ns;
		submit <= '0';
		
		
		wait for 5000 us;
   end process;
END;

