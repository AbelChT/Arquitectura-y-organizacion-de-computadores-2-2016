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

	mtx_busA : out  STD_LOGIC_VECTOR (1 downto 0);
	mtx_busB : out  STD_LOGIC_VECTOR (1 downto 0);
	signal_STOP : out  STD_LOGIC
  );
end HDM;

architecture Behavioral of HDM is

begin

A <= 	"11" when (
		op /= "000000" AND s = t2 AND (op2 = "000010" OR op2 = "001010")
		) else
	"10" when (
		op /= "000000" AND ((op2 = "000001" AND s = d2) OR ((op2 = "001010" OR op2 = "001011") AND s = s2))
		) else
	"01" when (
		(op /= "000000" AND ((op1 = "000001" AND s = d1) OR ((op1 = "001010" OR op2 = "001011") AND s = s1))) OR
			((op = "000001" OR op = "000100" OR op = "000011" OR op = "001011") AND op1 = "001010" AND s = s1)
		) else
	"00";

B <= 	"11" when (
		(op = "000001" OR op = "000100" OR op = "000011" OR op = "001011") AND (op2 = "000010" OR op2 = "001010") AND t = t2
		) else
	"10" when (
		(op = "000001" OR op = "000100" OR op = "000011" OR op = "001011") AND ((op2 = "000001" AND t = d2) OR ((op2 = "001010" OR op2 = "000011") AND t = s2))
		) else
	"01" when (
		(op = "000001" OR op = "000100" OR op = "000011" OR op = "001011") AND ((op1 = "000001" AND t = d1) OR ((op1 = "001010" OR op1 = "001011") AND t = s1))
		) else
	"00";

STOP <=	'1' when (
		((op = "000001" OR op = "000100" OR op = "000011" OR op = "001011") AND t = t1 AND (op1 = "000010" OR op1 = "001010")) OR
			(op /= "000000" AND s = t1 AND (op1 = "000010" OR op1 = "001010"))
		) else
	'0';
end Behavioral;
