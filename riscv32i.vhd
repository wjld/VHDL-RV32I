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
    function to_logic(bool : boolean) return std_logic is begin
        if bool then return '1';
        else return '0'; end if;
    end function;

    signal brJmpS, stallS : std_logic;
    signal pc, plus4PC, brJmpPC, pcS : std_logic_vector(31 downto 0);
    signal instrS, ifidS : std_logic_vector(31 downto 0);

    signal aluSrcS, cntrlBrS, memRdS, memWrS : std_logic;
    signal regWrS, mem2RegS, auipcS, luiS : std_logic;
    signal hazardFlushS, ifidFlushS, idexFlushS, exmemFlushS : std_logic;
    signal aluOpS : std_logic_vector(3 downto 0);
    signal immS, beqJalPC, reg1S, reg2S : std_logic_vector(31 downto 0);
    signal idexS : std_logic_vector(129 downto 0);

    signal alu1, alu2, aluA, aluB, aluOutS : std_logic_vector(31 downto 0);
    signal forwardAS, forwardBS : std_logic_vector(1 downto 0);
    signal aluZeroS : std_logic;

    signal exmemS : std_logic_vector(72 downto 0);

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
    hazardDetectionUnit: entity work.hazardDetection port map(
        rdMem => idexS(67), beq => to_logic(reg1S = reg2S),
        rd => memwbS(4 downto 0), rs1 => ifidS(19 downto 15),
        rs2 => ifidS(24 downto 20),
        funct3Opcode => ifidS(14 downto 12) & ifidS(6 downto 0),
        stall => stallS, flush => hazardFlushS
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
        rs2 => ifidS(24 downto 20), rd => memwbS(4 downto 0),
        data => wbS, ro1 => reg1S, ro2 => reg2S
    );
    IDEX: entity work.pipelineReg(arch) generic map(88) port map(
        clk => clk, wren => stallS, rst => idexFlushS,
        regIn => luiS & auipcS & mem2RegS & regWrS & memWrS & memRdS
               & cntrlBrS & aluOpS & aluSrcS & ifidS(42 downto 32) & reg1S
               & reg2S & immS & ifidS(19 downto 15) & ifidS(24 downto 20)
               & ifidS(11 downto 7),
        regOut => idexS
    );
    ----------------------- instruction execute
    rs1Mux: entity work.mux3(arch) port map(
        a0 => idexS(110 downto 79),
        a1 => x"00000" & "00" & idexS(120 downto 111),
        a2 => x"00000000", sel => idexS(129 downto 128), b => alu1
    );
    rs2Mux: entity work.mux2(arch) port map(
        a0 => idexS(78 downto 47), a1 => idexS(46 downto 15),
        sel => idexS(121), b => alu2
    );
    forwardingUnit: entity work.forwarding(arch) port map(
        exMemRegWr => exmemS(71), memWbRegWr => memwbS(69),
        rs1 => idexS(14 downto 10), rs2 => idexS(9 downto 5),
        exMemRd => exmemS(4 downto 0), memWbRd => memwbS(4 downto 0),
        forwardA => forwardAS, forwardB => forwardBS
    );
    alu1Mux: entity work.mux3(arch) port map(
        a0 => alu1, a1 => wbS, a2 => exmemS(68 downto 37),
        sel => forwardAS, b => aluA
    );
    alu2Mux: entity work.mux3(arch) port map(
        a0 => alu2, a1 => wbS, a2 => exmemS(68 downto 37),
        sel => forwardBS, b => aluB
    );
    alu: entity work.alu(arch) port map(
        opcode => idexS(125 downto 122), A => aluA, B => aluB,
        Z => aluOutS, zero => aluZeroS
    );
    EXMEM: entity work.pipelineReg(arch) generic map(31) port map(
        clk => clk, wren => '1', rst => exmemFlushS,
        regIn => idexS(127 downto 121) & aluOutS & aluB & idexS(4 downto 0),
        regOut => exmemS
    );
end;