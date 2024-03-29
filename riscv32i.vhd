library IEEE;
use IEEE.std_logic_1164.all;

entity riscv32i is port(
    clk, memIWr, memDWr : in std_logic;
    memIAddr, memDAddr : in std_logic_vector(11 downto 0);
    memIData, memDData : in std_logic_vector(31 downto 0);
    ecallD, ecallM, codeWrap : out std_logic;
    reg1Data, reg2Data, memData, currentPC : out std_logic_vector(31 downto 0)
);
end;

architecture arch of riscv32i is
    signal branchS, stallExS, stallMemS : std_logic;
    signal pc : std_logic_vector(31 downto 0) := x"00000000";
    signal plus4PC, brJmpPC, pcS : std_logic_vector(31 downto 0);
    signal instrS : std_logic_vector(31 downto 0);
    signal ifidS : std_logic_vector(42 downto 0);

    signal beqS, hazardFlushS, ifidFlushS, idexFlushS, exmemFlushS : std_logic;
    signal ctrlS : std_logic_vector(17 downto 0);
    signal beqJalPC, jalrPC, pcAddrS : std_logic_vector(31 downto 0);
    signal immS, reg1S, reg2S, rs1AddrS : std_logic_vector(31 downto 0);
    signal rs2AddrS, fwdRs1S, fwdRs2S : std_logic_vector(31 downto 0);
    signal idexS : std_logic_vector(139 downto 0);

    signal branchPC, jumpRaS : std_logic_vector(31 downto 0);
    signal aluA, aluB, aluOutS : std_logic_vector(31 downto 0);
    signal exmemS : std_logic_vector(77 downto 0);

    signal dataMemOutS, dataAddrS, dataDataS : std_logic_vector(31 downto 0);
    signal signedWordS : std_logic_vector(31 downto 0);
    signal memwbS : std_logic_vector(70 downto 0);

    signal wbS : std_logic_vector(31 downto 0);
begin
    currentPC <= pc;
    ----------------------- instruction fetch
    muxBrJmpOthers: entity work.mux2(arch) port map(
        a0 => branchPC, a1 => pcAddrS,
        sel => not branchS and (hazardFlushS or ctrlS(11) or ctrlS(12)),
        b => brJmpPC
    );
    muxPC: entity work.mux2(arch) port map(
        a0 => plus4PC, a1 => brJmpPC,
        sel => hazardFlushS or ctrlS(11) or ctrlS(12) or branchS,
        b => pcS
    );
    ifidFlushS <= (hazardFlushS or ctrlS(11) or ctrlS(12) or branchS)
                  and stallMemS;
    idexFlushS <= branchS or (not stallExS);
    exmemFlushS <= not stallMemS;
    process(clk) is begin
        if(clk'event and clk = '1') then
            if((((stallExS or ifidFlushS) and stallMemS) = '1')
               and ((memIWr or memDWr) = '0')) then
                pc <= pcS;
            end if;
            codeWrap <= exmemS(77);
        end if;
    end process;
    pcPlus4Adder: entity work.adder(arch) port map(
        a => pc, b => x"00000004", c => plus4PC
    );
    instrMem: entity work.memory(arch) port map(
        clk => clk, wren => memIWr, rden => not (memIWr or memDWr),
        byte => '0', half => '0', inAddr => memIAddr,
        outAddr => pc(11 downto 0), inData => memIData, outData => instrS
    );
    IFID: entity work.pipelineReg(arch) generic map(1) port map(
        clk => clk, wren => stallExS and stallMemS, rst => ifidFlushS,
        regIn => pcS(12) & pc(11 downto 2) & instrS, regOut => ifidS
    );
    ----------------------- instruction decode
    controlUnit: entity work.control(arch) port map(
        opcode => ifidS(6 downto 0), funct3 => ifidS(14 downto 12),
        funct7 => ifidS(30), aluOp => ctrlS(4 downto 1), aluSrc => ctrlS(0),
        branch => ctrlS(13), memRd => ctrlS(5), memWr => ctrlS(6),
        regWr => ctrlS(7), mem2Reg => ctrlS(8), auipc => ctrlS(9),
        lui => ctrlS(10), jal => ctrlS(11), jalr => ctrlS(12),
        ecall => ctrlS(14), readStoreB => ctrlS(15), readStoreH => ctrlS(16),
        unsigned => ctrlS(17)
    );
    ecallD <= ctrlS(14);
    beqS <= '1' when fwdRs1S = fwdRs2S else '0';
    hazardDetectionUnit: entity work.hazardDetection port map(
        rdMemIdEx => idexS(126), rdMemExMem => exmemS(69), beq => beqS,
        rdIdEx => idexS(4 downto 0), rdExMem => exmemS(4 downto 0),
        rs1 => rs1AddrS(4 downto 0), rs2 => rs2AddrS(4 downto 0),
        funct3Opcode => ifidS(14 downto 12) & ifidS(6 downto 0),
        stallEx => stallExS, stallMem => stallMemS, flush => hazardFlushS
    );
    immGen: entity work.genImm32(arch) port map(
        instr => ifidS(31 downto 0), imm32 => immS
    );
    beqJalAdder: entity work.adder(arch) port map(
        a => x"00000" & ifidS(41 downto 32) & "00",
        b => immS, c => beqJalPC
    );
    reg1AddrMux: entity work.mux2(arch) port map(
        a0 => x"000000" & "000" & ifidS(19 downto 15), a1 => x"00000011",
        sel => ctrlS(14), b => rs1AddrS
    );
    reg2AddrMux: entity work.mux2(arch) port map(
        a0 => x"000000" & "000" & ifidS(24 downto 20), a1 => x"0000000A",
        sel => ctrlS(14), b => rs2AddrS
    );
    regFile: entity work.xregs(arch) port map(
        clk => clk, wren => memwbS(69), rs1 => rs1AddrS(4 downto 0),
        rs2 => rs2AddrS(4 downto 0), rd => memwbS(4 downto 0),
        data => wbS, ro1 => reg1S, ro2 => reg2S
    );
    forwardingUnit: entity work.forwarding(arch) port map(
        idExRegWr => idexS(128), exMemRegWr => exmemS(71),
        memWbRegWr => memwbS(69), rs1Addr => rs1AddrS(4 downto 0),
        rs2Addr => rs2AddrS(4 downto 0), idExRdAddr => idexS(4 downto 0),
        exMemRdAddr => exmemS(4 downto 0), memWbRdAddr => memwbS(4 downto 0),
        rs1 => reg1S, rs2 => reg2S, idExRd => aluOutS,
        exMemRd => exmemS(68 downto 37), memWbRd => wbS, fwdRs1 => fwdRs1S,
        fwdRs2 => fwdRs2S
    );
    jalrAdder: entity work.adder(arch) port map(
        a => fwdRs1S, b => immS, c => jalrPC
    );
    pcAddrMux: entity work.mux2(arch) port map(
        a0 => beqJalPC, a1 => jalrPC(31 downto 1) & '0',
        sel => ctrlS(12), b => pcAddrS
    );
    reg1Data <= fwdRs1S;
    reg2Data <= fwdRs2S;
    IDEX: entity work.pipelineReg(arch) generic map(98) port map(
        clk => clk, wren => stallMemS, rst => idexFlushS,
        regIn => ifidS(42) & ctrlS & ifidS(41 downto 32) & fwdRs1S & fwdRs2S
               & immS & ifidS(19 downto 15) & ifidS(24 downto 20)
               & ifidS(11 downto 7),
        regOut => idexS
    );
    ----------------------- instruction execute
    branchAdder: entity work.adder(arch) port map(
        a => x"00000" & idexS(120 downto 111) & "00", b => idexS(46 downto 15),
        c => branchPC
    );
    jumpRaAdder: entity work.adder(arch) port map(
        a => x"00000" & idexS(120 downto 111) & "00", b => x"00000004",
        c => jumpRaS
    );
    alu1Mux: entity work.mux3(arch) port map(
        a0 => idexS(110 downto 79),
        a1 => x"00000" & idexS(120 downto 111) & "00", a2 => x"00000000",
        sel => (or idexS(133 downto 131)) & idexS(130), b => aluA
    );
    alu2Mux: entity work.mux3(arch) port map(
        a0 => idexS(78 downto 47), a1 => idexS(46 downto 15), a2 => jumpRaS,
        sel => (idexS(133) or idexS(132))
             & (idexS(121) and (not (idexS(133) or idexS(132)))), b => aluB
    );
    alu: entity work.alu(arch) port map(
        opcode => idexS(125 downto 122), A => aluA, B => aluB, Z => aluOutS
    );
    branchS <= '1' when (idexS(134) and aluOutS(0)) = '1' else '0';
    EXMEM: entity work.pipelineReg(arch) generic map(36) port map(
        clk => clk, wren => '1', rst => exmemFlushS,
        regIn => idexS(139 downto 135) & idexS(129 downto 126)
               & aluOutS & idexS(78 downto 47) & idexS(4 downto 0),
        regOut => exmemS
    );
    ----------------------- memory access
    dataMemAddrMux: entity work.mux2(arch) port map(
        a0 => exmemS(68 downto 37), a1 => x"00000" & memDAddr,
        sel => memDWr or exmemS(73), b => dataAddrS
    );
    dataMemDataMux: entity work.mux2(arch) port map(
        a0 => exmemS(36 downto 5), a1 => memDData,
        sel => memDWr, b => dataDataS
    );
    dataMemory: entity work.memory(arch) port map(
        clk => clk, wren => exmemS(70) or memDWr, rden => exmemS(69),
        byte => exmemS(74), half => exmemS(75),
        inAddr => dataAddrS(11 downto 0), outAddr => dataAddrS(11 downto 0),
        inData => dataDataS, outData => dataMemOutS
    );
    wordSign: entity work.extendSign(arch) port map(
        byte => exmemS(74), half => exmemS(75), unsigned => exmemS(76),
        wordIn => dataMemOutS, wordOut => signedWordS
    );
    ecallM <= exmemS(73);
    memData <= signedWordS;
    MEMWB: entity work.pipelineReg(arch) generic map(29) port map(
        clk => clk, wren => '1', rst => '0',
        regIn => exmemS(72 downto 71) & signedWordS & exmemS(68 downto 37)
               & exmemS(4 downto 0),
        regOut => memwbS
    );
    ----------------------- writeback
    writebackMux: entity work.mux2(arch) port map(
        a0 => memwbS(36 downto 5), a1 => memwbS(68 downto 37),
        sel => memwbS(70), b => wbS
    );
end;