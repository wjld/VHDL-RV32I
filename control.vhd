library IEEE;
use IEEE.std_logic_1164.all;

entity control is port(
    opcode : in std_logic_vector(6 downto 0);
    funct3 : in std_logic_vector(2 downto 0);
    funct7 : in std_logic;
    aluOp : out std_logic_vector(3 downto 0);
    aluSrc, branch, memRd, memWr, regWr, mem2Reg, auipc, lui : out std_logic;
    jal, jalr, ecall, readStoreB, readStoreH, unsigned : out std_logic
);
end;

architecture arch of control is
begin
    unsigned <= '0' when (funct3 & opcode) /= "1000000011"
                     and (funct3 & opcode) /= "1010000011"
                     and (funct3 & opcode) /= "0001110011" else '1';
    with (funct3 & opcode) select
        readStoreB <= '1' when "0000000011",
                      '1' when "1000000011",
                      '1' when "0000100011",
                      '1' when "0001110011",
                      '0' when others;
    with (funct3 & opcode) select
        readStoreH <= '1' when "0010000011",
                      '1' when "1010000011",
                      '1' when "0010100011",
                      '0' when others;
    ecall <= '0' when opcode /= "1110011" else '1';
    jalr <= '0' when opcode /= "1100111" else '1';
    jal <= '0' when opcode /= "1101111" else '1';
    lui <= '0' when opcode /= "0110111" else '1';
    auipc <= '0' when opcode /= "0010111" else '1';
    branch <= '0' when (opcode /= "1100011") or (funct3 = "000") else '1';
    memRd <= '0' when opcode /= "0000011" and opcode /= "1110011" else '1';
    memWr <= '0' when opcode /= "0100011" else '1';
    regWr <= '0' when opcode /= "0110111" and opcode /= "0010111"
                  and opcode /= "1101111" and opcode /= "1100111"
                  and opcode /= "0000011" and opcode /= "0010011"
                  and opcode /= "0110011" else '1';
    mem2Reg <= '0' when opcode /= "0000011" else '1';
    aluSrc <= '0' when opcode = "1100011" or opcode = "0110011" else '1';
    process(opcode, funct3, funct7) is begin
        case opcode is
            when "1100011" => --branches
                case funct3 is
                    when "000" => --beq
                        aluOp <= "1101";
                    when "001" => --bne
                        aluOp <= "1110";
                    when "100" => --blt
                        aluOp <= "1001";
                    when "101" => --bge
                        aluOp <= "1011";
                    when "110" => --bltu
                        aluOp <= "1010";
                    when "111" => --bgeu
                        aluOp <= "1100";
                    when others =>
                        aluOp <= "0000";
                end case;
            when "0010011" | "0110011" => --integer computational
                case funct3 is
                    when "000" =>
                        if opcode = "0010011" or funct7 = '0' then --add
                            aluOp <= "0000";
                        else --sub
                            aluOp <= "0001";
                        end if;
                    when "001" => --sll
                        aluOp <= "0101";
                    when "010" => --slt
                        aluOp <= "1001";
                    when "011" => --sltu
                        aluOp <= "1010";
                    when "100" => --xor
                        aluOp <= "0100";
                    when "101" =>
                        if funct7 = '0' then --srl
                            aluOp <= "0111";
                        else --sra
                            aluOp <= "1000";
                        end if;
                    when "110" => --or
                        aluOp <= "0011";
                    when "111" => --and
                        aluOp <= "0010";
                    when others =>
                        aluOp <= "0000";
                end case;
            when others => --load, store, lui or auipc
                aluOp <= "0000";
        end case;
    end process;
end;