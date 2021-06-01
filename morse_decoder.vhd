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
  	bin:	     in std_logic_vector (7 downto 0);
  	clk:	     in std_logic;
  	start_stop:       in std_logic;
  	next_char:   out std_logic;
  	morse_sig:       out std_logic
  	);
end morse_decoder;

architecture Behavioral of morse_decoder is
signal bin_pos, dit_counter: integer := 0;
signal tc_control:  integer := 0;
signal decrement:   STD_LOGIC := '0';
signal enable:      STD_LOGIC := '0';
signal test:        STD_LOGIC;
signal addflag:     STD_LOGIC := '0';
begin

test <= bin(bin_pos);
process(enable, decrement)
begin
    if enable = '1' then morse_sig <= not(decrement);
    else morse_sig <= '0';
    end if;
end process;

generate_morse: process(clk, bin, bin_pos, start_stop, decrement)
begin
    if rising_edge(clk) then
        if enable = '1' then
            dit_counter <= dit_counter + 1;  
            if start_stop = '1' then enable <= '0'; 
            elsif dit_counter = 3 AND bin(bin_pos) = '1' then
                dit_counter <= 0;
                decrement <= '1';
            
                if bin_pos = 0 then next_char <= '1';
                else next_char <= '0';
                end if;
            
            elsif dit_counter = 1 AND bin(bin_pos) = '0' then
                dit_counter <= 0;
               -- morse_sig <= '0';
                decrement <= '1';
            
                if bin_pos = 0 then next_char <= '1';
                else next_char <= '0';
                end if;
            else 
                --morse_sig <= '1';
                next_char <= '0';
                decrement <= '0';
            end if;
        elsif start_stop = '1' then
            enable <= '1';
            dit_counter <= 0;
            --morse_sig <= '0';
            decrement <= '1'; 
        end if;
    end if;
end process;

bin_count:  process(clk, bin, bin_pos, decrement, tc_control, addflag)
begin
     CASE bin(7) is 
            when '1' =>
                tc_control <= 4;
            when others =>
                tc_control <= to_integer(unsigned(bin(6 downto 4))-1);
    end CASE;
    if rising_edge(clk) then
        if decrement = '1' AND bin_pos > 0 then bin_pos <= bin_pos -1;
        elsif decrement = '1' AND bin_pos = 0 then
            bin_pos <= tc_control;
            addflag <= '1';
        end if;
        if addflag = '1' then
            bin_pos <= tc_control;
            addflag <= '0';
        end if;    
    end if;
end process;

end Behavioral;