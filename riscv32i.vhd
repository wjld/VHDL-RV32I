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
    signal pc : std_logic_vector(31 downto 0) := x"00000000";
    signal plus4PC, brJmpPC, pcS : std_logic_vector(31 downto 0);
    signal instrS : std_logic_vector(31 downto 0);
    signal ifidS : std_logic_vector(41 downto 0);

    signal aluSrcS, cntrlBrS, memRdS, memWrS : std_logic;
    signal regWrS, mem2RegS, auipcS, luiS, jalS, jalrS, beqS : std_logic;
    signal hazardFlushS, ifidFlushS, idexFlushS, exmemFlushS : std_logic;
    signal aluOpS : std_logic_vector(3 downto 0);
    signal immS, beqPC, reg1S, reg2S : std_logic_vector(31 downto 0);
    signal idexS : std_logic_vector(134 downto 0);

    signal branchJalPC, jalrPC, pcAddrS : std_logic_vector(31 downto 0);
    signal fwdRs1S, fwdRs2S : std_logic_vector(31 downto 0);
    signal aluA, aluB, aluOutS : std_logic_vector(31 downto 0);
    signal forwardAS, forwardBS : std_logic_vector(1 downto 0);
    signal exmemS : std_logic_vector(106 downto 0);

    signal dataMemOutS, dataAddrS, dataDataS : std_logic_vector(31 downto 0);
    signal memwbS : std_logic_vector(70 downto 0);

    signal wbS : std_logic_vector(31 downto 0);
begin
    ----------------------- instruction fetch
    muxBeqOthers: entity work.mux2(arch) port map(
        a0 => beqPC, a1 => exmemS(104 downto 73),
        sel => (not hazardFlushS) and brJmpS,
        b => brJmpPC
    );
    muxPC: entity work.mux2(arch) port map(
        a0 => plus4PC, a1 => brJmpPC,
        sel => hazardFlushS or brJmpS,
        b => pcS
    );
    ifidFlushS <= hazardFlushS or brJmpS;
    idexFlushS <= brJmpS;
    exmemFlushS <= brJmpS;
    process(clk) is begin
        if(clk'event and clk = '1') then
            if(stallS = '1' and ((memIWr or memDWr) = '0')) then
                pc <= pcS;
            end if;
        end if;
    end process;
    pcPlus4Adder: entity work.adder(arch) port map(
        a => pc, b => x"00000004", c => plus4PC
    );
    instrMem: entity work.memory(arch) port map(
        clk => clk, wren => memIWr, rden => '1', inAddr => memIAddr,
        outAddr => pc(11 downto 2), inData => memIData, outData => instrS
    );
    IFID: entity work.pipelineReg(arch) port map(
        clk => clk, wren => stallS, rst => ifidFlushS,
        regIn => pc(11 downto 2) & instrS, regOut => ifidS
    );
    ----------------------- instruction decode
    controlUnit: entity work.control(arch) port map(
        opcode => ifidS(6 downto 2), funct3 => ifidS(14 downto 12),
        funct7 => ifidS(30), aluOp => aluOpS, aluSrc => aluSrcS,
        branch => cntrlBrS, memRd => memRdS, memWr => memWrS,
        regWr => regWrS, mem2Reg => mem2RegS, auipc => auipcS,
        lui => luiS, jal => jalS, jalr => jalRS
    );
    beqS <= '1' when reg1S = reg2S else '0';
    hazardDetectionUnit: entity work.hazardDetection port map(
        rdMem => idexS(67), beq => beqS,
        rd => memwbS(4 downto 0), rs1 => ifidS(19 downto 15),
        rs2 => ifidS(24 downto 20),
        funct3Opcode => ifidS(14 downto 12) & ifidS(6 downto 0),
        stall => stallS, flush => hazardFlushS
    );
    immGen: entity work.genImm32(arch) port map(
        instr => ifidS(31 downto 0), imm32 => immS
    );
    beqAdder: entity work.adder(arch) port map(
        a => x"00000" & ifidS(41 downto 32) & "00",
        b => immS, c => beqPC
    );
    regFile: entity work.xregs(arch) port map(
        clk => clk, wren => memwbS(69), rs1 => ifidS(19 downto 15),
        rs2 => ifidS(24 downto 20), rd => memwbS(4 downto 0),
        data => wbS, ro1 => reg1S, ro2 => reg2S
    );
    IDEX: entity work.pipelineReg(arch) generic map(93) port map(
        clk => clk, wren => '1', rst => idexFlushS,
        regIn => cntrlBrS & jalrS & jalS & luiS & auipcS & mem2RegS & regWrS 
               & memWrS & memRdS & aluOpS & aluSrcS & ifidS(41 downto 32)
               & reg1S & reg2S & immS & ifidS(19 downto 15)
               & ifidS(24 downto 20) & ifidS(11 downto 7),
        regOut => idexS
    );
    ----------------------- instruction execute
    branchJalAdder: entity work.adder(arch) port map(
        a => x"00000" & idexS(120 downto 111) & "00",
        b => idexS(46 downto 15), c => branchJalPC
    );
    forwardingUnit: entity work.forwarding(arch) port map(
        exMemRegWr => exmemS(71), memWbRegWr => memwbS(69),
        rs1 => idexS(14 downto 10), rs2 => idexS(9 downto 5),
        exMemRd => exmemS(4 downto 0), memWbRd => memwbS(4 downto 0),
        forwardA => forwardAS, forwardB => forwardBS
    );
    rs1Mux: entity work.mux3(arch) port map(
        a0 => idexS(110 downto 79), a1 => wbS, a2 => exmemS(68 downto 37),
        sel => forwardAS, b => fwdRs1S
    );
    rs2Mux: entity work.mux3(arch) port map(
        a0 => idexS(78 downto 47), a1 => wbS, a2 => exmemS(68 downto 37),
        sel => forwardBS, b => fwdRs2S
    );
    alu1Mux: entity work.mux3(arch) port map(
        a0 => fwdRs1S, a1 => x"00000" & idexS(120 downto 111) & "00",
        a2 => x"00000000", sel => (or idexS(133 downto 131)) & idexS(130),
        b => aluA
    );
    jalrAdder: entity work.adder(arch) port map(
        a => fwdRs1S, b => idexS(46 downto 15), c => jalrPC
    );
    pcAddrMux: entity work.mux2(arch) port map(
        a0 => branchJalPC, a1 => jalrPC(31 downto 1) & '0',
        sel => idexS(133), b => pcAddrS
    );
    alu2Mux: entity work.mux3(arch) port map(
        a0 => fwdRs2S, a1 => idexS(46 downto 15),
        a2 => x"00000" & ifidS(41 downto 32) & "00",
        sel => (idexS(133) or idexS(132))
             & (idexS(121) and (not (idexS(133) or idexS(132)))), b => aluB
    );
    alu: entity work.alu(arch) port map(
        opcode => idexS(125 downto 122), A => aluA, B => aluB, Z => aluOutS
    );
    EXMEM: entity work.pipelineReg(arch) generic map(65) port map(
        clk => clk, wren => '1', rst => exmemFlushS,
        regIn => idexS(134) & (or idexS(133 downto 132)) & pcAddrS
               & idexS(129 downto 126) & aluOutS & aluB & idexS(4 downto 0),
        regOut => exmemS
    );
    ----------------------- memory access
    brJmpS <= '1' when ((exmemS(106) and exmemS(37)) or exmemS(105)) = '1' else
              '0';
    dataMemAddrMux: entity work.mux2(arch) port map(
        a0 => exmemS(68 downto 37), a1 => x"00000" & memDAddr & "00",
        sel => memDWr, b => dataAddrS
    );
    dataMemDataMux: entity work.mux2(arch) port map(
        a0 => exmemS(36 downto 5), a1 => memDData,
        sel => memDWr, b => dataDataS
    );
    dataMemory: entity work.memory(arch) port map(
        clk => clk, wren => exmemS(70) or memDWr, rden => exmemS(69),
        inAddr => dataAddrS(11 downto 2), outAddr => exmemS(48 downto 39),
        inData => dataDataS, outData => dataMemOutS
    );
    MEMWB: entity work.pipelineReg(arch) generic map(29) port map(
        clk => clk, wren => '1', rst => '0',
        regIn => exmemS(72 downto 71) & dataMemOutS & exmemS(68 downto 37)
               & exmemS(4 downto 0),
        regOut => memwbS
    );
    ----------------------- writeback
    writebackMux: entity work.mux2(arch) port map(
        a0 => memwbS(36 downto 5), a1 => memwbS(68 downto 37),
        sel => memwbS(70), b => wbS
    );
end;