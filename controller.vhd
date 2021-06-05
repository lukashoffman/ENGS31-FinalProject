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
           reset:       out STD_LOGIC
           );
end Controller;

architecture Behavioral of Controller is
type STATE_TYPE is (RECEIVE, FULL, TRANSITION, GEN);
signal cstate, nstate:  STATE_TYPE := RECEIVE;
signal transition_counter:  integer := 0;
constant trans_count_tc: integer := 1000000;
begin

state_update: process(clk)
begin
    if rising_edge(clk) then
        cstate <= nstate;        
    end if;
end process;

counter_proc: process(clk, cstate, transition_counter)
begin
    if rising_edge(clk) then
        if cstate = TRANSITION then transition_counter <= transition_counter + 1;
        else transition_counter <= 0;
        end if;
    end if;
end process;

state_logic: process(cstate, submit, full_sig, empty_sig, transition_counter)
begin
    nstate <= cstate;
    reset <= '0';
    CASE cstate is
        when RECEIVE =>
            if submit = '1' AND empty_sig = '0' then nstate <= TRANSITION;
            elsif full_sig = '1' then nstate <= FULL;
            else nstate <= RECEIVE;
            end if;
            
            write_enable <= '1';
            read_enable <= '0';
            start_stop <= '0';
            
        when FULL =>
            if submit = '1' AND empty_sig = '0' then nstate <= TRANSITION;
            else nstate <= FULL;
            end if;
            
            write_enable <= '0';
            read_enable <= '0';
            start_stop <= '0';
        when GEN =>
            if empty_sig = '1' then nstate <= TRANSITION;
            else nstate <= GEN;
            end if;
            
            write_enable <= '0';
            read_enable <= '1';
            start_stop <= '0';
        when TRANSITION =>
            if empty_sig = '1' AND transition_counter = trans_count_tc then 
                nstate <= RECEIVE;
                reset <= '1';
            elsif transition_counter = trans_count_tc then nstate <= GEN;
            else nstate <= TRANSITION;
            end if;
            
            read_enable <= '1';
            write_enable <= '0';
            start_stop <= '1';
        when OTHERS =>
            nstate <= RECEIVE;
            
            reset <= '1';
            write_enable <= '0';
            read_enable <= '0';
            start_stop <= '0';
    end CASE;
end process;

end Behavioral;
