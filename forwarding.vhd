library IEEE;
use IEEE.std_logic_1164.all;

entity forwarding is port(
    idExRegWr, exMemRegWr, memWbRegWr : in std_logic;
    rs1Addr, rs2Addr, idExRdAddr : in std_logic_vector(4 downto 0);
    exMemRdAddr, memWbRdAddr : in std_logic_vector(4 downto 0);
    rs1, rs2, idExRd, exMemRd, memWbRd : in std_logic_vector(31 downto 0);
    fwdRs1, fwdRs2 : out std_logic_vector(31 downto 0)
);
end;

architecture arch of forwarding is
begin
    fwdRs1 <= idExRd when idExRegWr = '1' and idExRdAddr /= "00000"
                      and idExRdAddr = rs1Addr else
             exMemRd when exMemRegWr = '1' and exMemRdAddr /= "00000"
                      and exMemRdAddr = rs1Addr else
             memWbRd when memWbRegWr = '1' and memWbRdAddr /= "00000"
                      and memWbRdAddr = rs1Addr else
                 rs1;
    fwdRs2 <= idExRd when idExRegWr = '1' and idExRdAddr /= "00000"
                      and idExRdAddr = rs2Addr else
             exMemRd when exMemRegWr = '1' and exMemRdAddr /= "00000"
                      and exMemRdAddr = rs2Addr else
             memWbRd when memWbRegWr = '1' and memWbRdAddr /= "00000"
                      and memWbRdAddr = rs2Addr else
                 rs2;
end;