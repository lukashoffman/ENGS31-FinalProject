-- Taken from professor's solutions
--Modifications: tracking of size, and full and empty signals
--               reset button
--               default to zeroes rather than undefined
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY Queue IS
PORT (  clk     :   in  STD_LOGIC;
        Write   :   in  STD_LOGIC;
        read    :   in  STD_LOGIC;
        Data_in :   in  STD_LOGIC_VECTOR(7 downto 0);
        Data_out:   out STD_LOGIC_VECTOR(7 downto 0);
        full    :   out STD_LOGIC;
        empty   :   out STD_LOGIC;
        reset   :   in  STD_LOGIC
        );      
end Queue;


architecture behavior of Queue is

type regfile is array(0 to 7) of STD_LOGIC_VECTOR(7 downto 0);
signal Queue_reg : regfile := (others=>(others=>'0'));

signal W_ADDR : integer := 0;
signal R_ADDR : integer := 0;
signal size   : integer := 0;
BEGIN

process(clk)
begin
    if rising_edge(clk) then
        if (reset = '1') then
            --Reset everything
           R_ADDR <= 0;
           W_ADDR <= 0;
           size <= 0;
           queue_reg <= (others=>(others=>'0'));

        elsif (Write = '1' AND size < 9 AND Data_in /= "00000000") then --Do not allow all zeroes to be written as an input
            Queue_reg(W_ADDR) <= Data_in;
            size <= size +1;
            if W_ADDR = 7 then
                W_ADDR <= 0;
            else
                W_ADDR <= W_ADDR + 1;
            end if;
        elsif (read = '1' AND size > 0) then --Do not allow read from an empty queue
            Queue_reg(R_ADDR) <= (others => '0');
            size <= size -1;
            if R_ADDR = 7 then
                R_ADDR <= 0;
            else
                R_ADDR <= R_ADDR + 1;
            end if;
        end if;
    end if;
end process;

process(size)
--Output control signals for the FSM
begin
    if size = 8 then 
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
        
        