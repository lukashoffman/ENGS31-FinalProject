----------------------------------------------------------------------------------
-- Company:     Engs 31, 20X
-- Engineer:    Lukas Hoffman
-- 
-- Create Date: 
-- Design Name: morse_decoder_tb
-- Module Name: morse_decoder_tb - Behavioral
-- Project Name: Final Project
-- Target Devices: 
-- Tool Versions: 
-- Description: A testbench for a decoder of binary encoded morse signals.
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity morse_decoder_tb is
end morse_decoder_tb;

architecture Behavioral of morse_decoder_tb is

signal next_char, morse_sig, start:  STD_LOGIC := '0';
signal clk:   STD_LOGIC := '1';
signal bin: STD_LOGIC_VECTOR (7 downto 0) := "00100001";
type QUEUETEST is array (0 to 5) of STD_LOGIC_VECTOR (7 downto 0);
signal qt:  QUEUETEST := ("00100001", "11000000", "11010101", "00010001", "00100010", "00000000");
signal qt_p: integer := 0;
signal clk_period:  time := 10 ns;

signal counter: integer := 0;
component morse_decoder is
  Port (
    bin:         in std_logic_vector (7 downto 0);
    clk:         in std_logic;
    start_stop:       in std_logic;
    next_char:   out std_logic;
    morse_sig:       out std_logic
    );
end component;

begin

uut: morse_decoder port map(
    bin => bin,
    clk => clk,
    start_stop => start,
    next_char => next_char,
    morse_sig => morse_sig
);
clk_process: process
begin
    clk <= '1';
    wait for clk_period/2;
    clk <= '0';
    wait for clk_period/2;
end process;

queue_proc: process(clk, next_char)
begin   
   if falling_edge(clk) then
        if next_char = '1' AND qt_p < 4 then qt_p <= qt_p + 1;
        bin <= qt(qt_p+1);
        end if;      
   end if;
end process;

stim_proc:  process
begin
    wait for 3*clk_period;
    start <= '1';
    wait for 1*clk_period;
    start <= '0';
    wait;
end process;
end Behavioral;
