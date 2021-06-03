--=============================================================
--Library Declarations
--=============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL; -- needed for arithmetic
use ieee.math_real.all; -- needed for automatic register sizing
library UNISIM; -- needed for the BUFG component
use UNISIM.Vcomponents.ALL;

--=============================================================
--Shell Entitity Declarations
--=============================================================
entity morse_shell is
port (  
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    --Timing
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Clk : in  STD_LOGIC; -- 100 MHz board clock
   
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    --7 Segment Display
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    seg : out std_logic_vector(0 to 6);
    dp    : out std_logic;
    an : out std_logic_vector(3 downto 0);  
     
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    --SCI receiver
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    clk10_p : out std_logic; -- 10 MHz clock  
    RsRx_p : out std_logic; -- serial data stream
    rx_shift_p : out std_logic; -- Rx register shift          
    rx_done_tick_p : OUT  std_logic; -- data ready
   
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    --Decoder
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    next_char : out std_logic;
    morse_sig : out std_logic );
   
end morse_shell;

-- This is the eventual version with transmitter included
--entity lab5top is
--    Port ( Clk : in  STD_LOGIC;
--           RsRx  : in  STD_LOGIC;
-- RsTx  : in  STD_LOGIC );
--end lab5top;

--=============================================================
--Architecture + Component Declarations
--=============================================================
architecture Behavioral of morse_shell is
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Controller
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component morse_controller is
port(clk :in std_logic
);
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Datapath
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component morse_datapath is
port(clk :in std_logic
);
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--7 Segment Display
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component mux7seg is
    Port ( clk : in  STD_LOGIC;
            y0, y1, y2, y3 : in  STD_LOGIC_VECTOR (3 downto 0);
            dp_set : in std_logic_vector(3 downto 0);
            seg : out  STD_LOGIC_VECTOR (0 to 6);
          dp : out std_logic;
            an : out  STD_LOGIC_VECTOR (3 downto 0) );
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--7 Segment Display
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
COMPONENT blk_mem_gen_0
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END COMPONENT;

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

--=============================================================
--Local Signal Declaration
--=============================================================
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Timing Signals:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
constant CLOCK_DIVIDER_VALUE: integer := 5;
signal clkdiv: integer := 0; -- the clock divider counter
signal clk_en: std_logic := '0'; -- terminal count
signal clk10: std_logic; -- 10 MHz clock signal

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Intermediate Signals:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
signal RsRx : std_logic := '0';
signal rx_data : std_logic_vector(7 downto 0);
signal rx_done_tick : std_logic;

signal start_stop : std_logic;

signal to_mux7seg_y3 : std_logic_vector(3 downto 0) := (others => '0');
signal to_mux7seg_y2 : std_logic_vector(3 downto 0) := (others => '0');
signal to_mux7seg_y1 : std_logic_vector(3 downto 0) := (others => '0');
signal to_mux7seg_y0 : std_logic_vector(3 downto 0) := (others => '0');
signal measured_voltage : std_logic_vector(15 downto 0) := (others => '0');
       
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
                O => clk10 );

-- Divide the 100 MHz clock down to 20 MHz, then toggling the
-- clk_en signal at 20 MHz gives a 10 MHz clock with 50% duty cycle
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
------------------------------

--=============================================================
--Port Maps:
--=============================================================
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Outputs
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Map testing signals to toplevel ports
clk10_p <= clk_en;
rx_done_tick_p <= rx_done_tick;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--SCI receiver
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Receiver: SerialRx PORT MAP(
Clk => clk10, -- receiver is clocked with 10 MHz clock
RsRx => RsRx,
rx_data => rx_data,
rx_done_tick => rx_done_tick  );

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--SCI receiver
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Decoder: morse_decoder PORT MAP(
        clk => clk10,
        bin => rx_data,
        start_stop => start_stop,
        next_char => next_char,
        morse_sig => morse_sig);

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Mux to 7-Seg
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Input Multiplexer
--display_mux: process(mode, measured_voltage, ian, in_data)
--begin
--    if mode = '1' then
--        to_mux7seg_y3 <= measured_voltage(15 downto 12);
--        to_mux7seg_y2 <= measured_voltage(11 downto 8);
--        to_mux7seg_y1 <= measured_voltage(7 downto 4);
--        to_mux7seg_y0 <= measured_voltage(3 downto 0);
--        an <= ian;
--    else
--        to_mux7seg_y3 <= "0000";
--        to_mux7seg_y2 <= in_data(11 downto 8);
--        to_mux7seg_y1 <= in_data(7 downto 4);
--        to_mux7seg_y0 <= in_data(3 downto 0);
--        an <= ian OR "1000";
--    end if;
--end process;

--7-Segment Display Port Map
--display: mux7seg port map(
--    clk => clk, -- runs on the 1 MHz clock
--    y3 => to_mux7seg_y3,        
--    y2 => to_mux7seg_y2, -- A/D converter output  
--    y1 => to_mux7seg_y1,
--    y0 => to_mux7seg_y0,
--    dp_set => "0000",           -- decimal points off
--    seg => seg,
--    dp => dp,
--    an => ian );
--    );

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Block Memory
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    
--blockMem : blk_mem_gen_0
-- PORT MAP (
--    clk => clk,
--    ena => take_sample,
--    addra => in_data,
--    douta => measured_voltage);
end Behavioral;