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
    signal brJmpS, stallS : std_logic;
    signal pc, plus4PC, brJmpPC, pcS : std_logic_vector(31 downto 0);
    signal instrS, ifidS, ifidFlushS: std_logic_vector(31 downto 0);
begin
    ----------------------- instruction fetch
    muxPC: entity work.mux2(arch) port map(
        a0 => plus4PC, a1 => brJmpPC, sel => brJmpS, b => pcS
    );
    process(clk) is begin
        if(clk'event and clk = '1') then
            if(stallS = '1') then
                pc <= pcS;
            end if;
        end if;
    end process;
    pcPlus4Adder: entity work.adder(arch) port map(
        a => pc, b => x"00000004", c => plus4PC
    );
    instrMem: entity work.memory(arch) port map(
        clk => clk, wren => memIWr, rden => '1', inAddr => memIAddr,
        outAddr => pc(9 downto 0), inData => memIData, outData => instrS
    );
    IFID: entity work.pipelineReg(arch) port map(
        clk => clk, wren => stallS, rst => ifidFlushS,
        regIn => pc & instrS, regOut => ifidS
    );
end;