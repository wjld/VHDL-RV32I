library IEEE;
use IEEE.std_logic_1164.all;

entity extendSign is port(
    byte, half, unsigned : std_logic;
    wordIn : in std_logic_vector(31 downto 0);
    wordOut : out std_logic_vector(31 downto 0)
);
end;

architecture arch of extendSign is
begin
    with (byte & half & unsigned) select wordOut <=
           (7 downto 0 => wordIn(7 downto 0), others => wordIn(7)) when "100",
                                    x"000000" & wordIn(7 downto 0) when "101",
        (15 downto 0 => wordIn(15 downto 0), others => wordIn(15)) when "010",
                                     x"0000" & wordIn(15 downto 0) when "011",
                                                            wordIn when others;
end architecture;