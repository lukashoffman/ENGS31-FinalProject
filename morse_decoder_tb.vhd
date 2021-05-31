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
-- Revision 0.03 - Updated testbench for new functional block.
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

signal new_char, morse_bit, next_char, morse_sig:  STD_LOGIC := '0';
signal clk:   STD_LOGIC := '1';
signal bin: STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal clk_period:  time := 10 ns;

signal counter: integer := 0;
component morse_decoder is
  Port (
    bin:         in std_logic_vector (7 downto 0);
    clk:         in std_logic;
    new_char:    in std_logic;
    next_char:   out std_logic;
    morse_sig:       out std_logic
    );
end component;

begin
update_char:    process(clk, next_char)
begin
if rising_edge(clk) then
    new_char <= next_char;
end if;
end process;
uut: morse_decoder port map(
    bin => bin,
    clk => clk,
    new_char => new_char,
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

stim_process: process
begin
    bin <= "00100010";
    wait for 8 * clk_period;
    bin <= "01000111"; 
    wait for 8*clk_period;
    bin <= "10011110";
    wait;
end process;

end Behavioral;
