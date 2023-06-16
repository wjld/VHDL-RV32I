library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alu is port(
    opcode : in std_logic_vector(3 downto 0);
    A, B : in std_logic_vector(31 downto 0);
    Z : out std_logic_vector(31 downto 0);
    zero : out std_logic
);
end;

architecture arch of alu is
    function to_word(bool : boolean)
        return std_logic_vector is
    begin
        if bool then
            return x"00000001";
        else
            return x"00000000";
        end if;
    end function;
    signal shamt : integer;
begin
    shamt <= to_integer(unsigned(B(4 downto 0)));
    zero <= nor Z;
    with opcode select Z <= 
        std_logic_vector(signed(A) + signed(B)) when "0000",
        std_logic_vector(signed(A) - signed(B)) when "0001",
        A and B                                 when "0010",
        A or  B                                 when "0011",
        A xor B                                 when "0100",
        std_logic_vector(unsigned(A) sll shamt) when "0101",
        std_logic_vector(signed(A) sla shamt)   when "0110",
        std_logic_vector(unsigned(A) srl shamt) when "0111",
        std_logic_vector(signed(A) sra shamt )  when "1000",
        to_word(signed(A) < signed(B))          when "1001",
        to_word(unsigned(A) < unsigned(B))      when "1010",
        to_word(signed(A) >= signed(B))         when "1011",
        to_word(unsigned(A) >= unsigned(B))     when "1100",
        to_word(A = B)                          when "1101",
        to_word(A /= B)                         when "1110",
        (others => 'U')                         when others;
end;