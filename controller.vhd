----------------------------------------------------------------------------------
-- Company: Engs 31/ COSC 56
-- Engineer: Lukas Hoffman
-- 
-- Create Date: 06/02/2021 11:40:47 PM
-- Design Name: Morse Decoder Controller
-- Module Name: Controller - Behavioral
-- Project Name: Morse Decoder
-- Target Devices: Basys3
-- Tool Versions: 
-- Description: A finite state machine based controller for a morse code converter
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 1.1 Working version with comments
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
    Port ( submit : in STD_LOGIC;       --User input to submit the entered morse
           full_sig : in STD_LOGIC;     --Memory full signal from the queue
           empty_sig : in STD_LOGIC;    --Empty signal from the queue
           clk : in STD_LOGIC;          --10 Mhz clock
           write_enable : out STD_LOGIC;
           read_enable : out STD_LOGIC;
           start_stop : out STD_LOGIC;  --Start/stop signal for the decoder
           reset:       out STD_LOGIC   --Queue reset signal
           );
end Controller;

architecture Behavioral of Controller is
type STATE_TYPE is (RECEIVE, FULL, TRANSITION, GEN);
signal cstate, nstate:  STATE_TYPE := RECEIVE;
signal transition_counter:  integer := 0; --We want to maintain the transition state for a full timer cycle of the decoder
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
    --Count up in transition, otherwise set the counter to 0
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
            --Allow the Receiver to write to the queue, and do not allow reads from the decoder
            if submit = '1' AND empty_sig = '0' then nstate <= TRANSITION; --Move to output if not empty on submission
            elsif full_sig = '1' then nstate <= FULL; --Go to full to disallow inputs
            else nstate <= RECEIVE;
            end if;
            
            write_enable <= '1';
            read_enable <= '0';
            start_stop <= '0';
            
        when FULL =>
            --Do not allow write inputs, only submit inputs
            if submit = '1' AND empty_sig = '0' then nstate <= TRANSITION;
            else nstate <= FULL;
            end if;
            
            write_enable <= '0';
            read_enable <= '0';
            start_stop <= '0';
        when GEN =>
            --Allow the decoder to read from the queue until it is empty
            if empty_sig = '1' then nstate <= TRANSITION;
            else nstate <= GEN;
            end if;
            
            write_enable <= '0';
            read_enable <= '1';
            start_stop <= '0';
        when TRANSITION =>
            --Stay in this state for one cycle of the decoder to ensure it enables, and again coming back to ensure it disables
            if empty_sig = '1' AND transition_counter = trans_count_tc then 
                nstate <= RECEIVE;
                reset <= '1'; --Reset the queue before we start receiving again
            elsif transition_counter = trans_count_tc then nstate <= GEN;
            else nstate <= TRANSITION;
            end if;
            
            read_enable <= '1';
            write_enable <= '0';
            start_stop <= '1';
        when OTHERS =>
            --In case of a fault and an undefined state, reset everything.
            nstate <= RECEIVE;
            
            reset <= '1';
            write_enable <= '0';
            read_enable <= '0';
            start_stop <= '0';
    end CASE;
end process;

end Behavioral;
