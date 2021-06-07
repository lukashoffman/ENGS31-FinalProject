-- Code your testbench here
library IEEE;
use IEEE.std_logic_1164.all;

entity Queue_tb is
end Queue_tb;

architecture testbench of Queue_tb is

component Queue IS
PORT ( 	clk		:	in	STD_LOGIC; --10 MHz clock
		Write	: 	in 	STD_LOGIC;
		read	: 	in 	STD_LOGIC;
        Data_in	:	in	STD_LOGIC_VECTOR(7 downto 0);
		Data_out:	out	STD_LOGIC_VECTOR(7 downto 0);
		full:   out STD_Logic;
		empty:  out STD_LOGIC);
end component;



signal 	clk		:	STD_LOGIC; --10 MHz clock
signal 	Write	: 	STD_LOGIC 	:= '0';
signal 	Read	: 	STD_LOGIC	:= '0';
signal 	Data_in	:	STD_LOGIC_Vector(7 downto 0) := "00000000";
signal 	Data_out:	STD_LOGIC_Vector(7 downto 0) := "00000000";
signal full_sig, empty_sig: STD_LOGIC;

begin

uut : Queue PORT MAP(
		clk  => CLK,
		Read => Read,
        Write => Write,
        Data_in => Data_in,
		Data_out => Data_out,
		full => full_sig,
		empty => empty_sig);
    
    
clk_proc : process
BEGIN

  CLK <= '0';
  wait for 5ns;   

  CLK <= '1';
  wait for 5ns;

END PROCESS clk_proc;

stim_proc : process
begin
	
    wait for 20 ns;
    
    Data_in <= "11110000";
    Write <= '1';
    
    wait for 10 ns;
    Data_in <= "00001111";
    Write <= '1';
    
    wait for 10 ns;
    Data_in <= "00100000";
    write <= '0';
    
    wait for 40 ns;
  
    read <= '1';
	
    wait;
end process stim_proc;
end testbench;