library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity genImm32 is port(
    instr : in std_logic_vector(31 downto 0);
    imm32 : out std_logic_vector(31 downto 0));
end;

architecture arch of genImm32 is
    signal ins, R, I, S, B, U, J : signed(31 downto 0);
    signal opcode : std_logic_vector(7 downto 0);
begin
    ins <= signed(instr);
operations:
    opcode <= '0' & instr(6 downto 0);
    R <= (others => '0');
    I <= resize(ins(31 downto 20),32);
    S <= resize(ins(31 downto 25) & ins(11 downto 7),32);
    B <= resize(ins(31)&ins(7)&ins(30 downto 25)&ins(11 downto 8)&'0',32);
    U <= ins(31 downto 12) & x"000";
    J <= resize(ins(31)&ins(19 downto 12)&ins(20)&ins(30 downto 21)&'0',32);
output:
    with opcode select
        imm32 <= std_logic_vector(I) when x"03",
                 std_logic_vector(I) when x"13",
                 std_logic_vector(I) when x"67",
                 std_logic_vector(S) when x"23",
                 std_logic_vector(B) when x"63",
                 std_logic_vector(U) when x"37",
                 std_logic_vector(J) when x"6F",
                 std_logic_vector(R) when others;
end;