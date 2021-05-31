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
-- Revision 0.03 - Added output generator
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
  	new_char:    in std_logic;
  	next_char:   out std_logic;
  	morse_sig:       out std_logic
  	);
end morse_decoder;

architecture Behavioral of morse_decoder is
	signal curr: INTEGER := -1;
	signal bin_copy:    STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
	signal ready:	    std_logic := '1';
	signal morse_bit:	std_logic;
    signal counter:     integer := 0;
    signal enable:      STD_LOGIC := '0';
begin

send_bit:	process(ready, curr, clk, bin, new_char)
	begin
		if rising_edge(clk) then
		  if new_char = '1' then
		        bin_copy <= bin;
				if bin(7) = '1' then curr <= 4;
				else curr <= to_integer(unsigned(bin(6 downto 4))-1);
				end if;
		  elsif ready = '1'then
				if curr > -1 then 
				morse_bit <= bin_copy(curr);
				curr <= curr - 1;
				end if;
		  end if;
		end if;
		
		if curr <= -1  OR bin_copy(7 downto 4) = "0000" then next_char <= '1';
		else next_char <= '0';
		end if;
	end process;
	
generate_proc: process(clk, morse_bit, counter)
begin
    if rising_edge(clk) then
    if enable = '1' then
        counter <= counter + 1;
        if counter = 3 and morse_bit = '1' then
            counter <= 0;
            ready <= '1';
        elsif counter = 1 and morse_bit = '0' then
            counter <= 0;
            ready <= '1';
        else 
            ready <= '0';
        end if;
    else ready <= '1';
    end if;
    end if;
    
    morse_sig <= not(ready);
end process;

enable_proc:    process(new_char, enable)
begin
    if curr > -1 and enable = '0' then enable <= '1';
    elsif curr < -1 then enable <= '0';
    end if;
end process;

end Behavioral;