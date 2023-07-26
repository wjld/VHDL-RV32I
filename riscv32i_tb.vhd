library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std_unsigned.all;
use std.textio.all;

entity riscv32i_tb is end;

architecture tb of riscv32i_tb is
    signal wClk, rClk, miwT, mdwT, ecdT, ecmT, wpcT : std_logic := '1';
    signal miaT, wMdaT, rMdaT, mdaT : std_logic_vector(11 downto 0);
    signal midT, mddT, r1dT, r2dT, mdT : std_logic_vector(31 downto 0);
    signal pcT, codeEnd : std_logic_vector(31 downto 0);
begin
    mdaT <= wMdaT when (miwT or mdwT) = '1' else rMdaT;
    core: entity work.riscv32i(arch) port map(
        clk => wClk and rClk, memIWr => miwT, memDWr => mdwT, memIAddr => miaT,
        memDAddr => mdaT, memIData => midT, memDData => mddT, ecallD => ecdT,
        ecallM => ecmT, reg1Data => r1dT, reg2Data => r2dT, memData => mdT,
        currentPC => pcT, codeWrap => wpcT
    );

    writeMemories:
    process is
        file code : text open read_mode is "./bintxt/codequadint.txt";
        file data : text open read_mode is "./bintxt/dataquadint.txt";
        variable codeline, dataline : line;
        variable address : std_logic_vector(11 downto 0) := x"000";
        variable codevec, datavec : std_logic_vector(31 downto 0);
    begin
        while not endfile(code) loop
            wClk <= not wClk;
            readline(code,codeline);
            read(codeline,codevec);
            midT <= codevec;
            miaT <= address;
            wait for 1 ps;
            wClk <= not wClk;
            wait for 1 ps;
            codeEnd <= x"00000" & address;
            address := address + 4;
        end loop;
        address := x"000";
        while not endfile(data) loop
            wClk <= not wClk;
            readline(data,dataline);
            read(dataline,datavec);
            mddT <= datavec;
            wMdaT <= address;
            wait for 1 ps;
            wClk <= not wClk;
            wait for 1 ps;
            address := address + 4;
        end loop;
        miwT <= '0'; mdwT <= '0';
        file_close(code);
        file_close(data);
        wait;
    end process;

    run:
    process is
        variable finished : boolean := false;
        file output : text open write_mode is "./output/output.txt";
        variable outputline : line;
        variable endM : string(1 to 31) := "-- program is finished running ";
        variable errM : string(1 to 10) := "Error in: ";
        variable ecallTime : time;
        variable ecallService : std_logic_vector(3 downto 0);
        variable char : std_logic_vector(7 downto 0);
        variable ecallParam : std_logic_vector(31 downto 0);
    begin
        wait for 9500 ps;
        while pcT < codeEnd + 20 loop
            rClk <= not rClk;
            ecallTime := 0 ps;
            if wpcT = '1' then
                exit;
            end if;
            if rClk = '1' and ecmT = '1' then
                if ecallService = "1010" then
                    finished := true;
                    exit;
                elsif ecallService = "0100" then
                    loop
                        rMdaT <= ecallParam(11 downto 0);
                        wait for 1 ps; ecallTime := ecallTime + 1 ps;
                        char := mdT(7 downto 0);
                        if char /= x"00" then
                            write(outputline,character'val(to_integer(char)));
                        else
                            exit;
                        end if;
                        ecallParam := ecallParam + 1;
                    end loop;
                elsif ecallService = "0001" then
                    write(outputline, to_integer(ecallParam));
                    wait for 1 ps; ecallTime := ecallTime + 1 ps;
                end if;
            end if;
            if rClk = '0' and ecdT = '1' then
                ecallService := r1dT(3 downto 0);
                ecallParam := r2dT;
                wait for 1 ps; ecallTime := ecallTime + 1 ps;
            end if;
            ecallTime := 500 ps - ecallTime when ecallTime < 500 ps else 1 ps;
            wait for ecallTime;
        end loop;
        writeline(output,outputline);
        if finished then
            write(outputline,endM & "(0) --");
        elsif wpcT /= '1' then
            write(outputline,endM & "(dropped off bottom) --");
        else
            write(outputline,errM & "instruction load access error");
        end if;
        writeline(output,outputline);
        file_close(output);
        wait;
    end process;
end;