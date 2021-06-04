-- Taken from professor's solutions. Modified to work on falling edge.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY Queue IS
PORT ( 	clk		:	in	STD_LOGIC;
		Write	: 	in 	STD_LOGIC;
		read	: 	in 	STD_LOGIC;
        Data_in	:	in	STD_LOGIC_VECTOR(7 downto 0);
		Data_out:	out	STD_LOGIC_VECTOR(7 downto 0);
		full    :   out STD_LOGIC;
		empty   :   out STD_LOGIC
		);		
end Queue;


architecture behavior of Queue is

type regfile is array(0 to 63) of STD_LOGIC_VECTOR(7 downto 0);
signal Queue_reg : regfile;

signal W_ADDR : integer := 0;
signal R_ADDR : integer := 0;
signal size   : integer := 0;
BEGIN

process(clk)
begin
	if rising_edge(clk) then
    	if (Write = '1' AND size < 64) then
        	Queue_reg(W_ADDR) <= Data_in;
            if W_ADDR = 63 then
            	W_ADDR <= 0;
      		else
            	W_ADDR <= W_ADDR + 1;
            end if;
        end if;
        
        if (read = '1' AND size > 0) then
        	Queue_reg(R_ADDR) <= (others => '0');
        	if R_ADDR = 63 then
            	R_ADDR <= 0;
      		else
            	R_ADDR <= R_ADDR + 1;
            end if;
        end if;
    end if;
end process;

process(size)
begin
    if size = 63 then 
        full <= '1';
        empty <= '0';
    elsif size = 0 then 
        empty <= '1';
        full <= '0';
    else
        empty <= '0';
        full <= '0';
    end if;
end process;

Data_out <= Queue_reg(R_ADDR);

end behavior;
        
        
