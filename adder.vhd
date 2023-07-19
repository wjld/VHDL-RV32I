library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std_unsigned.all;

entity adder is port(
    a, b : in std_logic_vector(31 downto 0);
    c : out std_logic_vector(31 downto 0)
);
end;

architecture arch of adder is
begin
    c <= a + b;
end;