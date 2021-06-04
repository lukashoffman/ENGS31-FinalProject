----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/04/2021 07:54:12 PM
-- Design Name: 
-- Module Name: morse_tb - Behavioral
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

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.all;
 
ENTITY morse_tb IS
END morse_tb;
 
ARCHITECTURE behavior OF morse_tb IS 
 
COMPONENT SerialRx
	PORT(
		clk : IN std_logic;
		RsRx : IN std_logic;
		morse_sig :  out std_logic_vector(7 downto 0));
	END COMPONENT;
  
   --Inputs
   signal clk : std_logic := '0';
   signal RsRx : std_logic := '1';

 	--Outputs
   signal morse_sig : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant clk_period : time := 100ns;		-- 10 MHz clock
	
	-- Data definitions
	constant bit_time : time := 104us;		-- 9600 baud
	--constant bit_time : time := 8.68us;		-- 115,200 baud
	constant TxData : std_logic_vector(7 downto 0) := "01101001";

	
BEGIN 
	-- Instantiate the Unit Under Test (UUT)
   uut: SerialRx PORT MAP (
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
 
   -- Stimulus process
   stim_proc: process
   begin		
		wait for 100 us;
		wait for 10.25*clk_period;		
		
		RsRx <= '0';		-- Start bit
		wait for bit_time;
		
		for bitcount in 0 to 7 loop
			RsRx <= TxData(bitcount);
			wait for bit_time;
		end loop;
		
		RsRx <= '1';		-- Stop bit
		wait for 200 us;
		
		RsRx <= '0';		-- Start bit
		wait for bit_time;
		
		for bitcount in 0 to 7 loop
			RsRx <= not( TxData(bitcount) );
			wait for bit_time;
		end loop;
		
		RsRx <= '1';		-- Stop bit
		
		wait;
   end process;
END;

