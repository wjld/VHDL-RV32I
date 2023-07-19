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
    signal instrS, ifidS : std_logic_vector(31 downto 0);

    signal aluSrcS, cntrlBrS, memrdS, memWrS : std_logic;
    signal regWrS, mem2RegS, auipcS, luiS : std_logic;
    signal ifidFlushS, idexFlushS : std_logic;
    signal aluOpS : std_logic_vector(3 downto 0);
    signal immS, beqJalPC, reg1S, reg2S : std_logic_vector(31 downto 0);
    signal idexS : std_logic_vector(120 downto 0);

    signal wbS : std_logic_vector(31 downto 0);
    signal memwbS : std_logic_vector(70 downto 0);
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
    ----------------------- instruction decode
    controlUnit: entity work.control(arch) port map(
        opcode => ifidS(6 downto 2), funct3 => ifidS(14 downto 12),
        funct7 => ifidS(30), aluOp => aluOpS, aluSrc => aluSrcS,
        branch => cntrlBrS, memRd => memRdS, memWr => memWrS,
        regWr => regWrS, mem2Reg => mem2RegS, auipc => auipcS, lui => luiS
    );
    immGen: entity work.genImm32(arch) port map(
        instr => ifidS(31 downto 0), imm32 => immS
    );
    beqJalAdder: entity work.adder(arch) port map(
        a => x"00000" & "00" & ifidS(42 downto 32),
        b => immS, c => beqJalPC
    );
    regFile: entity work.xregs(arch) port map(
        clk => clk, wren => memwbS(69), rs1 => ifidS(19 downto 15),
        rs2 => ifidS(24 downto 20), rd => ifidS(11 downto 7),
        data => wbS, ro1 => reg1S, ro2 => reg2S
    );
    IDEX: entity work.pipelineReg(arch) generic map(79) port map(
        clk => clk, wren => stallS, rst => idexFlushS,
        regIn => ifidS(42 downto 32) & reg1S & reg2S & immS
               & ifidS(19 downto 15) & ifidS(24 downto 20)
               & ifidS(11 downto 7),
        regOut => idexS
    );
end;