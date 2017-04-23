------------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    13:10:55 03/31/2014
-- Design Name:
-- Module Name:    Hazard detector module - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
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
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity HDM is
  Port (
	op_code_ID : in  STD_LOGIC_VECTOR (5 downto 0);
	op_code_EX : in  STD_LOGIC_VECTOR (5 downto 0);
	op_code_MEM : in  STD_LOGIC_VECTOR (5 downto 0);

  Reg_Rs_ID : in  STD_LOGIC_VECTOR (4 downto 0);
	Reg_Rt_ID : in  STD_LOGIC_VECTOR (4 downto 0);

	Reg_Rs_EX : in  STD_LOGIC_VECTOR (4 downto 0);
	Reg_Rt_EX : in  STD_LOGIC_VECTOR (4 downto 0);
	Reg_Rd_EX : in  STD_LOGIC_VECTOR (4 downto 0);

  Reg_Rs_MEM : in  STD_LOGIC_VECTOR (4 downto 0);
	Reg_Rt_MEM : in  STD_LOGIC_VECTOR (4 downto 0);
	Reg_Rd_MEM : in  STD_LOGIC_VECTOR (4 downto 0);

	mux_busA : out  STD_LOGIC_VECTOR (1 downto 0);
	mux_busB : out  STD_LOGIC_VECTOR (1 downto 0);
	signal_STOP : out  STD_LOGIC
  );
end HDM;

architecture Behavioral of HDM is

begin

mux_busA <= "01" when (
		(op_code_ID /= "000000" AND ((op_code_EX = "000001" AND Reg_Rs_ID = Reg_Rd_EX) OR
		((op_code_EX = "001010" OR op_code_EX = "001011") AND Reg_Rs_ID = Reg_Rs_EX)))
		) else
	"10" when (
		(op_code_ID /= "000000" AND ((op_code_MEM = "000001" AND Reg_Rs_ID = Reg_Rd_MEM) OR
		((op_code_MEM = "001010" OR op_code_MEM = "001011") AND Reg_Rs_ID = Reg_Rs_MEM)))
		) else
	"11" when (
		(op_code_ID /= "000000" AND (op_code_MEM = "000010" OR op_code_MEM = "001010") AND Reg_Rs_ID = Reg_Rt_MEM)
		) else
	"00";

mux_busB <= 	"01" when (
		((op_code_ID = "000001" OR op_code_ID = "000100" OR op_code_ID = "000011" OR op_code_ID = "001011") AND ((op_code_EX = "000001" AND Reg_Rt_ID = Reg_Rd_EX) OR
		((op_code_EX = "001010" OR op_code_EX = "001011") AND Reg_Rt_ID = Reg_Rs_EX)))
		) else
	"10" when (
		((op_code_ID = "000001" OR op_code_ID = "000100" OR op_code_ID = "000011" OR op_code_ID = "001011") AND((op_code_MEM = "000001" AND Reg_Rt_ID = Reg_Rd_MEM) OR ((op_code_MEM = "001010" OR op_code_MEM = "001011") AND Reg_Rt_ID = Reg_Rs_MEM)))
		) else
	"11" when (
		((op_code_ID = "000001" OR op_code_ID = "000100" OR op_code_ID = "000011" OR op_code_ID = "001011") AND (op_code_MEM = "000010" OR op_code_MEM = "001010") AND Reg_Rt_ID = Reg_Rt_MEM)
		) else
	"00";

signal_STOP <=	'1' when (
		((op_code_ID = "000001" OR op_code_ID = "000100" OR op_code_ID = "000011" OR op_code_ID = "001011") AND (op_code_EX = "001010" OR op_code_EX = "000010") AND Reg_Rt_ID = Reg_Rt_EX) OR
		(op_code_ID /= "000000" AND (op_code_EX = "000010" OR op_code_EX = "001010") AND Reg_Rs_ID = Reg_Rt_EX)
		) else
	'0';
end Behavioral;
