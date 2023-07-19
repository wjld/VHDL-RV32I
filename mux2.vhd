library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std_unsigned.all;

entity mux2 is port(
    a0, a1 : in std_logic_vector(31 downto 0);
    sel : in std_logic;
    b : out std_logic_vector(31 downto 0)
);
end;

architecture arch of mux2 is
begin
    b <= a0 when sel = '0' else
         a1 when sel = '1' else
         x"XXXXXXXX";
end;