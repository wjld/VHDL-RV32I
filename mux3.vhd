library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std_unsigned.all;

entity mux3 is port(
    a0, a1, a2 : in std_logic_vector(31 downto 0);
    sel : in std_logic_vector(1 downto 0);
    b : out std_logic_vector(31 downto 0)
);
end;

architecture arch of mux3 is
begin
    b <= a0 when sel = "00" else
         a1 when sel = "01" else
         a2 when sel = "10" else
         x"XXXXXXXX";
end;