library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std_unsigned.all;

entity memory is port(
    clk, wren, rden, byte, half : in std_logic;
    inAddr, outAddr : in std_logic_vector(11 downto 0);
    inData : in std_logic_vector(31 downto 0);
    outData : out std_logic_vector(31 downto 0));
end;

architecture arch of memory is
    type addresses is array(4095 downto 0) of std_logic_vector(7 downto 0);
    signal mem : addresses;
begin
    input:
    process(clk) is begin
        if(clk'event and clk = '1') then
            if(wren = '1') then
                mem(to_integer(inAddr)) <= inData(7 downto 0);
                if byte = '0' then
                    mem(to_integer(inAddr) + 1) <= inData(15 downto 8);
                    if half = '0' then
                        mem(to_integer(inAddr) + 2) <= inData(23 downto 16);
                        mem(to_integer(inAddr) + 3) <= inData(31 downto 24);
                    end if;
                end if;
            end if;
        end if;
    end process;
    output:
    process(clk, rden, byte, half, outAddr) is begin
        if(rden = '1') then
            outData(7 downto 0) <= mem(to_integer(outAddr));
            if byte = '0' then
                outData(15 downto 8) <= mem(to_integer(outAddr) + 1);
                if half = '0' then
                    outData(23 downto 16) <= mem(to_integer(outAddr) + 2);
                    outData(31 downto 24) <= mem(to_integer(outAddr) + 3);
                else
                    outData(31 downto 16) <= x"0000";
                end if;
            else
                outData(31 downto 8) <= x"000000";
            end if;
        else
            outData <= x"XXXXXXXX";
        end if;
    end process;
end;