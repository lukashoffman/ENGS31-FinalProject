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
           full : in STD_LOGIC;
           empty : in STD_LOGIC;
           clk : in STD_LOGIC;
           write_enable : out STD_LOGIC;
           read_enable : out STD_LOGIC;
           start_stop : out STD_LOGIC;
           speed_select : out STD_LOGIC);
end Controller;

architecture Behavioral of Controller is

begin


end Behavioral;
