library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std_unsigned.all;

entity memory is port(
    clk, wren, rden : in std_logic;
    inAddr, outAddr : in std_logic_vector(9 downto 0);
    inData : in std_logic_vector(31 downto 0);
    outData : out std_logic_vector(31 downto 0));
end;

architecture arch of memory is
    type addresses is array(1023 downto 0) of std_logic_vector(31 downto 0);
    signal mem : addresses;
begin
    outData <= mem(to_integer(outAddr)) when rden = '1' else x"XXXXXXXX";
    process(clk) is
    begin
        if(clk'event and clk = '1') then
            if(wren = '1') then
                mem(to_integer(inAddr)) <= inData;
            end if;
        end if;
    end process;
end;