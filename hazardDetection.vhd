library IEEE;
use IEEE.std_logic_1164.all;

entity hazardDetection is port(
    rdMemIdEx, rdMemExMem, beq : in std_logic;
    rdIdEx, rdExMem, rs1, rs2 : in std_logic_vector(4 downto 0);
    funct3Opcode : in std_logic_vector(9 downto 0);
    stallEx, stallMem, flush : out std_logic
);
end;

architecture arch of hazardDetection is
begin
    stallEx <= '0' when rdMemIdEx = '1' and rdIdEx /= "00000" 
                    and (rdIdEx = rs1 or rdIdEx = rs2) else '1';
    stallMem <= '0' when rdMemExMem = '1' and rdExMem /= "00000" 
                    and (rdExMem = rs1 or rdExMem = rs2) else '1';
    flush <= beq when funct3Opcode = "0001100011" else '0';
end;