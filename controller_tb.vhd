----------------------------------------------------------------------------------
-- Company: ENGS 31 / COSC 56
-- Engineer: Aadhya Kocha and Lukas Hoffman
-- 
-- Create Date: 06/03/2021 07:24:23 PM
-- Design Name: Controller Testbench
-- Module Name: Controller_tb - Behavioral
-- Project Name: Morse Code Generator
-- Target Devices: 
-- Tool Versions: 
-- Description: A Testbench for the Morse Code Generator FSM
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 1.0 Working simple testbench
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

entity Controller_tb is
--  Port ( );
end Controller_tb;

architecture Behavioral of Controller_tb is
component Controller is
    Port ( submit : in STD_LOGIC;
           full_sig : in STD_LOGIC;
           empty_sig : in STD_LOGIC;
           clk : in STD_LOGIC;
           write_enable : out STD_LOGIC;
           read_enable : out STD_LOGIC;
           start_stop : out STD_LOGIC);
end component;

signal submit, full_sig, empty_sig, 
       clk, write_enable, read_enable, 
       start_stop:  STD_LOGIC := '0';
signal clk_period: time := 10 ns;
begin

uut: Controller port map(
    submit => submit,
    full_sig => full_sig,
    empty_sig => empty_sig,
    clk => clk,
    write_enable => write_enable,
    read_enable => read_enable,
    start_stop => start_stop
);

clk_process: process
begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
end process;



stim_proc: process
begin
    wait for 10*clk_period;
    submit <= '1';
    wait for 1*clk_period;
    submit <= '0';
    wait for 5*clk_period;
    empty_sig <= '1';
    wait for 3* clk_period; 
    empty_sig <= '0';
    wait for 4*clk_period;
    full_sig <= '1';
    wait for 1*clk_period;
    full_sig <= '0';
    wait for 8*clk_period;
    submit<= '1';
    wait for 1*clk_period;
    submit<= '0';
    wait;
end process;
end Behavioral;
