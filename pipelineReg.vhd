library IEEE;
use IEEE.std_logic_1164.all;

entity pipelineReg is generic(
    addSize: integer := 0); port(
    clk, wren, rst : in std_logic;
    regIn: in std_logic_vector(addSize + 41 downto 0);
    regOut : out std_logic_vector(addSize + 41 downto 0));
end;

architecture arch of pipelineReg is
begin
    process(clk) is
    begin
        if(clk'event and clk = '1') then
            if(wren = '1' and rst = '0') then
                regOut <= regIn;
            elsif(rst = '1') then
                regOut <= (others => '0');
            end if;
        end if;
    end process;
end;