----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/02/2021 11:40:47 PM
-- Design Name: 
-- Module Name: Controller - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Controller is
    Port ( submit : in STD_LOGIC;
           full_sig : in STD_LOGIC;
           empty_sig : in STD_LOGIC;
           clk : in STD_LOGIC;
           write_enable : out STD_LOGIC;
           read_enable : out STD_LOGIC;
           start_stop : out STD_LOGIC;
           speed_select : out STD_LOGIC);
end Controller;

architecture Behavioral of Controller is
type STATE_TYPE is (RECEIVE, FULL, GEN);
signal cstate, nstate:  STATE_TYPE := RECEIVE;

begin

state_update: process(clk)
begin
    if rising_edge(clk) then
        cstate <= nstate;
    end if;
end process;

state_logic: process(cstate, nstate, submit, full_sig, empty_sig)
begin
    nstate <= cstate;
    CASE cstate is
        when RECEIVE =>
            if submit = '1' then nstate <= GEN;
            elsif full_sig = '1' then nstate <= FULL;
            else nstate <= RECEIVE;
            end if;
            
            write_enable <= '1';
            read_enable <= '0';
            start_stop <= '0';
            speed_select <= '0';
            
        when FULL =>
            if submit = '1' then nstate <= GEN;
            else nstate <= FULL;
            end if;
            
            write_enable <= '0';
            read_enable <= '0';
            start_stop <= '0';
            speed_select <= '0';
        when GEN =>
            if empty_sig = '1' then nstate <= RECEIVE;
            else nstate <= GEN;
            end if;
            
            write_enable <= '0';
            read_enable <= '1';
            start_stop <= '1';
            speed_select <= '1';
        when OTHERS =>
            nstate <= RECEIVE;
            
            write_enable <= '0';
            read_enable <= '0';
            start_stop <= '0';
            speed_select <= '0';
    end CASE;
end process;

end Behavioral;
