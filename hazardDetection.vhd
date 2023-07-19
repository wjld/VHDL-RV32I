library IEEE;
use IEEE.std_logic_1164.all;

entity hazardDetection is port(
    rdMem, beq : in std_logic;
    rd, rs1, rs2 : in std_logic_vector(4 downto 0);
    funct3Opcode : in std_logic_vector(9 downto 0);
    stall, flush : out std_logic
);
end;

architecture arch of hazardDetection is
begin
    stall <= '1' when rdMem = '1' and (rd = rs1 or rd = rs2) else '0';
    flush <= beq when funct3Opcode = "0001100011" else '0';
end;