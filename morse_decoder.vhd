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
-- Revision 0.02 - Working prototype
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
  	bin:	in std_logic_vector (7 downto 0);
  	clk:	in std_logic;
  	ready:	in std_logic;
  	new_char:	in std_logic;
  	morse_bit:	out std_logic;
  	next_char:	out std_logic
  	);
end morse_decoder;

architecture Behavioral of morse_decoder is
	signal curr: INTEGER := 0;
	signal bin_copy:   STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
begin


send_bit:	process(ready, curr, clk, bin)
	begin
		if rising_edge(clk) then
		  if new_char = '1' then
		        bin_copy <= bin;
				if bin(7) = '1' then curr <= 5;
				else curr <= to_integer(unsigned(bin(6 downto 5))) +1;
				end if;
		  elsif ready = '1' then
				if curr > -1 then morse_bit <= bin_copy(curr);
				curr <= curr - 1;
				end if;
		  end if;
		end if;
		if curr = -1 then next_char <= '1';
		else next_char <= '0';
		end if;
	end process;
end Behavioral;