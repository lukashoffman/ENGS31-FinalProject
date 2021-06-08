--=============================================================
--Library Declarations
--=============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;			-- needed for arithmetic
use ieee.math_real.all;				-- needed for automatic register sizing
library UNISIM;						-- needed for the BUFG component
use UNISIM.Vcomponents.ALL;

--=============================================================
--Shell Entitity Declarations
--=============================================================
entity morse_shell is
port (  
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    --Timing
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    clk : in  STD_LOGIC;					-- 100 MHz board clock
	          
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    --7 Segment Display
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    seg	: out std_logic_vector(0 to 6);
    dp    : out std_logic;
    an 	: out std_logic_vector(3 downto 0);  
     
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    --SCI receiver
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    RsRx : in std_logic;				-- serial data stream     
    rx_done_tick_p : out  std_logic;	-- data ready
    
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    --Decoder
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    morse_sig : out std_logic ;
    led:        out std_logic ;
    submit:     in std_logic);
end morse_shell;

--=============================================================
--Architecture + Component Declarations
--=============================================================
architecture Behavioral of morse_shell is
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Controller
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component Controller is
	port(submit	       :in std_logic;
	     full_sig      :in std_logic;
	     empty_sig     :in std_logic;
	     clk           :in std_logic;
	     write_enable  :out std_logic;
	     read_enable   :out std_logic;
	     start_stop    :out std_logic;
	     reset         :out std_logic
	     );
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Queue
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component Queue is
	port(clk			:in std_logic;
	     Write          :in std_logic;
	     read           :in std_logic;
	     reset          :in std_logic;
	     Data_in        :in std_logic_vector(7 downto 0);
	     Data_out       :out std_logic_vector(7 downto 0);
	     full           :out std_logic;
	     empty          :out std_logic
		 );
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--7 Segment Display
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component mux7seg is
    Port ( 	clk : in  STD_LOGIC; 
           	y0, y1, y2, y3 : in  STD_LOGIC_VECTOR (3 downto 0);	
           	dp_set : in std_logic_vector(3 downto 0);					
           	seg : out  STD_LOGIC_VECTOR (0 to 6);	
          	dp : out std_logic;
           	an : out  STD_LOGIC_VECTOR (3 downto 0) );			
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--SCI Serial receiver
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
COMPONENT SerialRx
	PORT(
		Clk : IN std_logic;
		RsRx : IN std_logic;   
		rx_data :  out std_logic_vector(7 downto 0);
		rx_done_tick : out std_logic  );
	END COMPONENT;
	
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Morse decoder
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
COMPONENT morse_decoder
    PORT(
        clk : in std_logic;
        bin : in std_logic_vector(7 downto 0);
        start_stop : in std_logic;
        next_char : out std_logic;
        morse_sig : out std_logic );
    END COMPONENT;
    
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Block Memory
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

COMPONENT blk_mem_gen_0
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;
--=============================================================
--Local Signal Declaration
--=============================================================
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Timing Signals:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
signal CLOCK_DIVIDER_VALUE: integer := 5;
signal clkdiv: integer := 0;			-- the clock divider counter
signal clk_en: std_logic := '0';		-- terminal count
signal sclk: std_logic := '0';              -- 1 mHz clock signal
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Intermediate Signals:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
signal rx_data : std_logic_vector(7 downto 0);
signal rx_done_tick : std_logic;

signal Data_out : std_logic_vector(7 downto 0);
signal full,empty : std_logic;
signal reset:       std_logic;
signal next_char : std_logic;
signal write_enable, read_enable, start_stop : std_logic;

signal to_mux7seg_y3 : std_logic_vector(3 downto 0) := (others => '0');
signal to_mux7seg_y2 : std_logic_vector(3 downto 0) := (others => '0');
signal to_mux7seg_y1 : std_logic_vector(3 downto 0) := (others => '0');
signal to_mux7seg_y0 : std_logic_vector(3 downto 0) := (others => '0');

signal read_sig, write_sig: STD_LOGIC;
signal write_ff1, write_ff2, write_ff3: STD_LOGIC;
signal queue_data:        STD_LOGIC_VECTOR (7 downto 0);
signal out_sig:         STD_LOGIC;
-------------------------
	
begin
--=============================================================
--Timing:
--=============================================================		
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--10 MHz Serial Clock (clk) Generation
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- Clock buffer for 10 MHz clock
-- The BUFG component puts the slow clock onto the FPGA clocking network
Slow_clock_buffer: BUFG
      port map (I => clk_en,
                O => sclk );

-- Divide the 100 MHz clock down to 10 Mhz
Clock_divider: process(clk)
begin
    if rising_edge(clk) then
        if clkdiv = CLOCK_DIVIDER_VALUE-1 then 
            clk_en <= NOT(clk_en);      
            clkdiv <= 0;
        else
            clkdiv <= clkdiv + 1;
        end if;
    end if;
end process Clock_divider;

--=============================================================
--Port Maps:
--=============================================================
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Outputs
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Map testing signals to toplevel ports
rx_done_tick_p <= rx_done_tick;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Controller
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
MorseController: Controller PORT MAP(
         submit => submit,
	     full_sig => full,
	     empty_sig => empty,
	     clk  => sclk,
	     write_enable => write_enable,
	     read_enable  => read_enable,
	     start_stop  => start_stop,
	     reset => reset
	     );
	     
read_write_enable: process(clk, read_enable, write_enable, next_char, rx_done_tick, write_ff3)
begin
    if rising_edge(clk) then
        --Flip flops ensure correct delay timing for the write_enable
        write_ff1 <= rx_done_tick;
        write_ff2 <= write_ff1;
        write_ff3 <= write_ff2;
    end if;
    
    if read_enable = '1' then 
        read_sig <= next_char; --Allow passthrough from the next_char signal from the decoder
    else read_sig <= '0';
    end if;
    
    if write_enable = '1' then
        write_sig <= write_ff3; --Allow delayed passthrough from the rx_done_tick of the SCI receiver
    else write_sig <= '0';
    end if;
end process;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Queue
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
MorseQueue: Queue PORT MAP(
         clk => sclk,
	     Write => Write_sig,
	     read => read_sig,
	     reset => reset,
	     Data_in => queue_data,
	     Data_out => Data_out,
	     full => full,
	     empty => empty
	     );
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--SCI receiver
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Receiver: SerialRx PORT MAP(
		Clk => sclk,				-- receiver is clocked with 10 MHz clock
		RsRx => RsRx,
		rx_data => rx_data,
		rx_done_tick => rx_done_tick  );

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Decoder
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Decoder: morse_decoder PORT MAP(
        clk => sclk,
        bin => data_out,
        start_stop => start_stop,
        next_char => next_char,
        morse_sig => out_sig);

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Mux to 7-Seg
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Input Multiplexer
display_mux: process(rx_data)
begin
        --Display the received char's hex value on the 7 seg
        to_mux7seg_y3 <= "0000"; --x"00"
        to_mux7seg_y2 <= "0000"; --x"10
        to_mux7seg_y1 <= rx_data(7 downto 4);
        to_mux7seg_y0 <= rx_data(3 downto 0);
end process;

--7-Segment Display Port Map

display: mux7seg port map( 
    clk => sclk,				-- runs on the 1 MHz clock
    y3 => to_mux7seg_y3, 		        
    y2 => to_mux7seg_y2, -- A/D converter output  	
    y1 => to_mux7seg_y1, 		
    y0 => to_mux7seg_y0,		
    dp_set => "0000",           -- decimal points off
    seg => seg,
    dp => dp,
    an => an);
    
    --Map both the LED and audio to the same signal
    led <= out_sig;
    morse_sig <= out_sig;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Block Memory
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    
BlockMem : blk_mem_gen_0
 PORT MAP (
    clka => sclk,
    ena => '1',
    addra => rx_data,
    douta => queue_data);
		
end Behavioral;
