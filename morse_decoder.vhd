----------------------------------------------------------------------------------
-- Company:     Engs 31, 21S
-- Engineer:    Lukas Hoffman
-- 
-- Create Date: 07/30/2016 05:53:43 AM
-- Design Name: Morse Decoder
-- Module Name: morse_decoder - Behavioral
-- Project Name: ASCII to Morse Converter
-- Target Devices: 
-- Tool Versions: 
-- Description: A decoder for binary encoded morse signals.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 1.1 - Final Revisions Done, Commented and Working
-- 
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity morse_decoder is
  Port (
    bin:         in std_logic_vector (7 downto 0); --Our binary encoded morse string
    clk:         in std_logic;     --10 Mhz clock
    start_stop:       in std_logic;--Monopulse input to start or stop reading out
    next_char:   out std_logic := '0';    --Output to signal the queue to send the next signal
    morse_sig:       out std_logic --The output of our signal
    );
end morse_decoder;

architecture Behavioral of morse_decoder is
signal bin_pos, dit_counter: integer := 0;  --Our position in the binary string, and our timer for the generation logic
signal tc_control:  integer := 0;           --The adjustable terminal count for the bin position
signal decrement:   STD_LOGIC := '0';       --The signal to decrement bin_pos
signal enable:      STD_LOGIC := '0';       --Track whether the decoder is enabled
signal addflag:     STD_LOGIC := '0';       --Signal to adjust bin_pos on reset
signal count_space:  STD_LOGIC := '0';      --Flag for whether we are coutning a space
signal dit_length_counter:  integer := 0;   --Timer for controlling our generation speed
signal dit_tc:              STD_LOGIC := '0'; --Terminal count signal for the dit length counter
constant dit_rate:          integer := 1000000; --10 Hz dit rate
signal send_read:           STD_LOGIC := '0'; --Signal to send the output next_char signal
begin

dit_clock_adapter: process(clk, dit_tc, dit_length_counter)
--A simple counter for adapting our generation speed.
begin
    if rising_edge(clk) then --Synchronous clock update
        if dit_tc = '1' then dit_length_counter <= 0;
        else dit_length_counter <= dit_length_counter + 1;
        end if;
    end if;
    
    --Asynchronous TC
    if dit_length_counter = dit_rate -1 then
        dit_tc <= '1';
    else dit_tc <= '0';
    end if;
end process;

signal_logic: process(enable, decrement, count_space, bin)
--Combinational logic for the output of morse_sig
begin
    if enable = '1' AND count_space = '0' --If we are enabled and not counting a space
        AND bin /= "11000000" AND bin /= "00000000" then --And the letter is not a space or invalid
            morse_sig <= not(decrement); --Decrement only happens between the dits and dahs, so the signal is the opposite of decrement

    else morse_sig <= '0';
    end if;
end process;

next_char_sig:  process(dit_tc, send_read)
--Combinational logic to properly send the signal for the next character to the queue
begin
    if dit_tc = '1' AND send_read = '1' then next_char <= '1'; --We want to send out the read signal only on a TC
    else next_char <= '0';
    end if;
end process;

generate_morse: process(clk, dit_tc, bin, bin_pos, start_stop, decrement, count_space)
--Our logic to generate the morse signal, and control for spaces and varying lengths
begin
    if rising_edge(clk) then
    if dit_tc = '1' then 
        if enable = '1' then
            dit_counter <= dit_counter + 1;  
            
            if start_stop = '1' then enable <= '0';  --Disable if we are already enabled and start_stop goes high
                      
            elsif count_space = '1' and dit_counter = 2 then --If we are in a space between characters and reach the end, 
                                                             --go back to counting characters
                dit_counter <= 1; --Reset to 1 to avoid extra dot length in timing.
                count_space <= '0';
                decrement <= '0';
            
            elsif bin = "11000000" and count_space = '0' then --Special case for space. Reset after one tick, 
                                                            --as it will have a char space (3 length) on both sides
                decrement <= '1';
                count_space <= '1';
                send_read <= '1'; --Space is special, so we always send read.
                dit_counter <= 0;
                
            elsif dit_counter = 3 AND bin(bin_pos) = '1' AND count_space = '0' then --Reset after three highs if 'dah'
                dit_counter <= 0;
                decrement <= '1';
                send_read <= '0';
            
                if bin_pos = 0 then --If we've reached the end of the character
                    count_space <= '1'; --Move into counting the space
                    send_read <= '1'; --Read in the next character
                else 
                    count_space <= '0';
                    send_read <= '0';
                end if;
            
            elsif dit_counter = 1 AND bin(bin_pos) = '0' AND count_space = '0' then --Reset after one high if 'dit'
                dit_counter <= 0;
                decrement <= '1';
                send_read <= '0';
            
                if bin_pos = 0 then --If we've reached the end of the character
                    count_space <= '1'; --Move into counting the space
                    send_read <= '1';   --Read in the next character
                else 
                    count_space <= '0';
                    send_read <= '0';
                end if;

            else --Otherwise we do not decrement, meaning morse_sig will be high
                send_read <= '0';
                decrement <= '0';
            end if;

        elsif start_stop = '1' then --If enable is false and start_stop goes high, enable the device
            enable <= '1';
            dit_counter <= 0;

            decrement <= '1'; --This will signal to get the next character.
        end if;
    end if;
    end if;
end process;

bin_count:  process(clk, bin, bin_pos, decrement, tc_control, addflag, dit_tc)
--All the logic to find the start position and move through the binary string.
begin

     CASE bin(7) is --Cases for our char length
            when '1' =>
                if bin(6) = '1' then
                    if bin(5 downto 0) = "000000" then tc_control <= 0; --"11000000" is a space
                    else tc_control <= 5; --"11" and a string is punctuation, always 6 length
                    end if;
                else tc_control <= 4; --"10" is a number, always 5 length
                end if;
            when others =>
                tc_control <= to_integer(unsigned(bin(6 downto 4))-1); --Otherwise it's a letter, which will have its length encoded
    end CASE;


    if rising_edge(clk) then
    if dit_tc = '1' then
        if enable = '0' then bin_pos <= 0; --Prepare to move to the next char if enable is 0

        elsif decrement = '1' AND bin_pos > 0 then bin_pos <= bin_pos -1; --Decrement through
        
        elsif decrement = '1' AND bin_pos <= 0 AND enable = '1' then --Signal for next char
            bin_pos <= tc_control; --Reset
            addflag <= '1'; --Flag to ensure it resets to the correct number
        end if;
        
        if addflag = '1' then --TC_control takes an extra tick to update, so we use addflag to ensure correct reset
            bin_pos <= tc_control;
            addflag <= '0';
        end if;    
    end if;
    end if;
end process;

end Behavioral;