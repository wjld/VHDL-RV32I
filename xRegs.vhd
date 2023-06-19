library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std_unsigned.all;

entity xregs is port(
    clk, wren : in std_logic;
    rs1, rs2, rd : in std_logic_vector(4 downto 0);
    data : in std_logic_vector(31 downto 0);
    ro1, ro2 : out std_logic_vector(31 downto 0));
end;

architecture arch of xregs is
    type rfile is array(31 downto 0) of std_logic_vector(31 downto 0);
    signal r : rfile;
begin
    ro1 <= x"00000000" when rs1 = "00000" else r(to_integer(rs1));
    ro2 <= x"00000000" when rs2 = "00000" else r(to_integer(rs2));
    process(clk) is
    begin
        if(clk'event and clk = '1') then
            if(wren = '1') then
                r(to_integer(rd)) <= data;
            end if;
        end if;
    end process;
end;