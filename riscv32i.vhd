library IEEE;
use IEEE.std_logic_1164.all;

entity riscv32i is port(
    clk, memIWr, memDWr : in std_logic;
    memIAddr, memDAddr : in std_logic_vector(9 downto 0);
    memIData, memDData : in std_logic_vector(31 downto 0);
    regAddr : in std_logic_vector(4 downto 0);
    regData : out std_logic_vector(31 downto 0)
);
end;

architecture arch of riscv32i is
begin
end;