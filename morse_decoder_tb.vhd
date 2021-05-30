----------------------------------------------------------------------------------
-- Company:     Engs 31 / COSC 56
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
-- Revision 0.02 - Working testbench
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

signal new_char, morse_bit, next_char:  STD_LOGIC := '0';
signal ready, clk:   STD_LOGIC := '1';
signal bin: STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal clk_period:  time := 10 ns;

signal counter: integer := 0;
component morse_decoder is
  Port (
    bin:    in std_logic_vector (7 downto 0);
    clk:    in std_logic;
    ready:  in std_logic;
    new_char:   in std_logic;
    morse_bit:  out std_logic;
    next_char:  out std_logic
    );
end component;

begin

uut: morse_decoder port map(
    bin => bin,
    clk => clk,
    ready => ready,
    new_char => new_char,
    morse_bit => morse_bit,
    next_char => next_char
);
clk_process: process
begin
    clk <= '1';
    wait for clk_period/2;
    clk <= '0';
    wait for clk_period/2;
end process;

stim_process: process
begin
    bin <= "00100001";
    wait for 8 * clk_period;
    bin <= "01000110"; 
    wait;
end process;

ready_process: process(clk, morse_bit, counter)
begin
    if rising_edge(clk) then
        counter <= counter + 1;
        if counter = 3 and morse_bit = '1' then
            counter <= 0;
            ready <= '1';
        elsif counter = 1 and morse_bit = '0' then
            counter <= 0;
            ready <= '1';
        else ready <= '0';
        end if;
    end if;
    new_char <= next_char;
end process;
end Behavioral;