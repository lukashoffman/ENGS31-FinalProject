----------------------------------------------------------------------------------
-- Company:     Engs 31, 20X
-- Engineer:    Lukas Hoffman
-- 
-- Create Date: 07/30/2016 05:53:43 AM
-- Design Name: 
-- Module Name: morse_decoder - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: A decoder for binary encoded morse signals.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- August 2020:  Added an accumulator overflow test (EWH)
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

entity morse_decoder is
  Port (
    bin:         in std_logic_vector (7 downto 0); --Our binary encoded morse string
    clk:         in std_logic;     --Divided clock
    start_stop:       in std_logic;--Monopulse input to start or stop reading out
    next_char:   out std_logic := '0';    --Output to signal the queue to send the next signal
    morse_sig:       out std_logic --The output of our signal
    );
end morse_decoder;

architecture Behavioral of morse_decoder is
signal bin_pos, dit_counter: integer := 0;
signal tc_control:  integer := 0;
signal decrement:   STD_LOGIC := '0';
signal enable:      STD_LOGIC := '0';
signal test:        STD_LOGIC;
signal addflag:     STD_LOGIC := '0';
signal count_space:  STD_LOGIC := '0';
signal dit_length_counter:  integer := 0;
signal dit_tc:              STD_LOGIC := '0';
signal dit_rate:            integer := 1000;
signal send_read:           STD_LOGIC := '0';
begin

test <= bin(bin_pos);

dit_clock_adapter: process(clk, dit_tc, dit_length_counter, dit_rate)
begin
    if rising_edge(clk) then
        if dit_tc = '1' then dit_length_counter <= 0;
        else dit_length_counter <= dit_length_counter + 1;
        end if;
    end if;
    
    if dit_length_counter = dit_rate -1 then 
        dit_tc <= '1';
    else dit_tc <= '0';
    end if;
end process;

signal_logic: process(enable, decrement, count_space, bin)
begin
    if enable = '1' AND count_space = '0' AND bin /= "11000000" then morse_sig <= not(decrement); --When not moving between bits or in a space, we are in a dit or dah
    else morse_sig <= '0'; --When moving between bits or in a space
    end if;
end process;

next_char_sig:  process(dit_tc, send_read)
begin
    if dit_tc = '1' AND send_read = '1' then next_char <= '1';
    else next_char <= '0';
    end if;
end process;

generate_morse: process(clk, dit_tc, bin, bin_pos, start_stop, decrement, count_space)
begin
    if rising_edge(clk) then
    if dit_tc = '1' then
        if enable = '1' then
            dit_counter <= dit_counter + 1;  
            
            if start_stop = '1' then enable <= '0';  --Disable if triggered
                      
            elsif count_space = '1' and dit_counter = 2 then
                dit_counter <= 1;
                count_space <= '0';
                decrement <= '0';
            
            elsif bin = "11000000" and count_space = '0' then --Special case for space. Reset after one tick. 
                decrement <= '1';
                count_space <= '1';
                send_read <= '1';
                dit_counter <= 0;
                
            elsif dit_counter = 3 AND bin(bin_pos) = '1' AND count_space = '0' then --Reset after three highs if 'dah'
                dit_counter <= 0;
                decrement <= '1';
                send_read <= '0';
            
                if bin_pos = 0 then 
                    count_space <= '1';
                    send_read <= '1';
                else 
                    count_space <= '0';
                    send_read <= '0';
                end if;
            
            elsif dit_counter = 1 AND bin(bin_pos) = '0' AND count_space = '0' then --Reset after one high if 'dit'
                dit_counter <= 0;
                decrement <= '1';
                send_read <= '0';
            
                if bin_pos = 0 then 
                    count_space <= '1';
                    send_read <= '1';
                else 
                    count_space <= '0';
                    send_read <= '0';
                end if;
            else --Otherwise just count high
                send_read <= '0';
                decrement <= '0';
            end if;
        elsif start_stop = '1' then
            enable <= '1';
            dit_counter <= 0;

            decrement <= '1'; 
        end if;
    end if;
    end if;
end process;

bin_count:  process(clk, bin, bin_pos, decrement, tc_control, addflag, dit_tc)
begin
     CASE bin(7) is 
            when '1' =>
                if bin(6) = '1' then
                    if bin(5 downto 0) = "000000" then tc_control <= 0;
                    else tc_control <= 5;
                    end if;
                else tc_control <= 4;
                end if;
            when others =>
                tc_control <= to_integer(unsigned(bin(6 downto 4))-1);
    end CASE;
    if rising_edge(clk) then
    if dit_tc = '1' then
        if enable = '0' then bin_pos <= 0;
        elsif decrement = '1' AND bin_pos > 0 then bin_pos <= bin_pos -1;
        
        elsif decrement = '1' AND bin_pos = 0 AND enable = '1' then
            bin_pos <= tc_control;
            addflag <= '1';
        end if;
        
        if addflag = '1' then
            bin_pos <= tc_control;
            addflag <= '0';
        end if;    
    end if;
    end if;
end process;

end Behavioral;