----------------------------------------------------------------------------------
-- Company: CS56/ ENGS31 Digital Electronics
-- Engineer: Aadhya Kocha and Lukas Hoffman
-- 
-- Create Date: 05/30/2021 01:02:44 AM
-- Design Name: Morse code generator
-- Module Name: SerialRX - Behavioral
-- Project Name: SCI receiver- Final Project
-- Target Devices: Basys 3
-- Tool Versions: Vivado 2018.3
-- Description: Receivers a UART signal as on RsRx port
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
use IEEE.NUMERIC_STD.ALL;

entity SerialRx is
    Port ( clk : in STD_LOGIC;                  -- 10MHz clock
    RsRx : in STD_LOGIC;                        -- received bit stream
    rx_data : out STD_LOGIC_VECTOR (7 downto 0); -- data byte
    rx_done_tick : out STD_LOGIC );             -- data ready tick
end SerialRx;

architecture Behavioral of SerialRX is

constant BAUD_PERIOD : integer := 1042; --(10 MHz / 9600)

signal temp_RsRx, sync_RsRx : std_logic := '1';
signal i_rx_data : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal shift_reg : std_logic_vector(9 downto 0) := (others => '0');
signal pload_reg : std_logic_vector(7 downto 0) := (others => '0');
signal CLEAR : std_logic := '0';
signal SHIFT : std_logic := '0';
signal count2 : unsigned(10 downto 0) := (others => '0');    --edge counter fpr T/2
signal count : unsigned(10 downto 0) := (others => '0');     --edge counter for T
signal shift_count : unsigned(3 downto 0) := (others => '0');     --bit counter for shift reg

type state_type is (s_idle, s_wait_tby2, s_wait_t, s_shift, s_ready);
signal current_state : state_type := s_idle;    --start at idle state
signal next_state    : state_type;
signal tc, count_en : std_logic := '0';         -- baud counter for no. of full clk cycles (T)
signal tc2, count2_en : std_logic := '0';       -- baud counter for no. of half clk cycles (T/2)
signal shift_tc, shift_count_en : std_logic := '0';     -- bit counter for bits in shift reg
signal shift_en, load_en : std_logic := '0';

begin

synchronise: process(RsRx, clk)
    begin
        if rising_edge(clk) then
            temp_RsRx <= RsRx;
            sync_RsRx <= temp_RsRx;
        end if;
end process synchronise;
    
stateUpdate: process(clk)
    begin
 		if rising_edge(clk) then
        	current_state <= next_state;
        end if;
    end process stateUpdate;

nextStateLogic: process(current_state, count_en, count2_en, shift_count_en, shift_en, load_en, shift_tc, tc, tc2, sync_RsRx)
    begin
    --defaults
    next_state <= current_state;
    shift_en <= '0';
    load_en <= '0';
    count_en <= '0';
    count2_en <= '0';
    shift_count_en <= '0';
    rx_done_tick <= '0';
    
		case (current_state) is
		
        	when s_idle =>  if sync_RsRx = '0' then        -- RsRx data sent
        	                    next_state <= s_wait_tby2;
                            end if;
                          
            when s_wait_tby2 =>   count2_en <= '1';        -- start counting clock edges N/2
                                  if tc2 = '1' then        -- when N/2 reached
                                    next_state <= s_shift; -- move to shift register as start bit
                                  end if;
                                                  
            when s_wait_t =>   count_en <= '1';            -- start counting clock edges N
                                if shift_tc = '1' then     -- shift register full
                                    next_state <= s_ready; -- if rull move to load register
                                elsif tc = '1' then        -- when N reached
                                    next_state <= s_shift;  -- shift bit into shift register
                                else
                                    next_state <= s_wait_t; -- wait for clock edge
                                end if;
                         
            when s_shift =>	    shift_count_en <= '1';      -- start counting bits in shift register
                                shift_en <= '1';            -- enable shifting to datapath
                                if shift_tc = '1' then      -- shift register full
                                    next_state <= s_ready;  -- move to load register
                                else
                                    next_state <= s_wait_t;
                                end if;
                                
            when s_ready =>     load_en <= '1';             -- enable loading to datapath
                                rx_done_tick <= '1';        -- rx_done_tick output to next components
                                next_state <= s_idle;       -- go wait for more user input
                            
           	when others =>  next_state <= s_idle;
            
        end case;
        
    end process nextStateLogic;

-- count N/2 clock edges        
tc2Counter: process(count2_en, clk, tc2)
    begin
        if rising_edge(clk) then
            if count2_en = '1' then
                count2 <= count2 + 1;
            elsif tc2 = '1' then
                count2 <= (others => '0');
            end if;
        end if;
			
	end process tc2Counter;

-- count N clock edges  
tcCounter: process(count_en, clk, tc)
    begin
        if rising_edge(clk) then
            if count_en = '1' then
                count <= count + 1;
            elsif tc = '1' then
                count <= (others => '0');
            end if;
        end if;
			
	end process tcCounter;
	
-- count number of bits in shift register
shiftCounter: process(shift_count_en, clk, shift_tc)
    begin
        if rising_edge(clk) then
            if shift_count_en = '1' then
                shift_count <= shift_count + 1;
            elsif shift_tc = '1' then
                shift_count <= (others => '0');
            end if;
        end if;
			
	end process shiftCounter;

-- enable shift_tc	
shiftTcLimit: process(shift_count)
	begin
	    if shift_count >= 10 then
           shift_tc <= '1';
        else
           shift_tc <= '0';
        end if;
    
end process shiftTcLimit;

-- enable tc2
tcLimit: process(count)
	begin
	    if count >= BAUD_PERIOD then
           tc <= '1';
        else
           tc <= '0';
        end if;
    
end process tcLimit;

-- enable tc2
tc2Limit: process(count2)
	begin
	    if count2 >= BAUD_PERIOD/2 then
           tc2 <= '1';
        else
           tc2 <= '0';
        end if;
    
end process tc2Limit;

datapath: process(clk, shift_en, load_en, CLEAR)
    begin
        if rising_edge(clk) then
        
            if CLEAR = '0' then
                    if shift_en = '1' then
                        shift_reg <= sync_RsRx & shift_reg(9 downto 1); --shifted to make bit sizes compatible
                    end if;
            else
                shift_reg <= (others => '0');
            end if;
            
            if load_en = '1' then
                pload_reg <= shift_reg(8 downto 1);
            end if;
            
        end if;
    
end process datapath;

rx_data <= pload_reg;

end Behavioral;
