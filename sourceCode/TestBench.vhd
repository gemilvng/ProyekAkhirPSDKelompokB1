library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TestBench is
end TestBench;

architecture rtl of TestBench is
    component main_program is
        port
        (
            clock : in std_logic;
            tombol : in std_logic_vector (1 downto 0);
            mode : out std_logic_vector (1 downto 0)
        );
    end component;
    signal clock : std_logic;
    constant clock_period : time := 0.1 ns;
    signal counter_clock : integer := 0;
    signal tombol : std_logic_vector := "00";
    

begin
    test : main_program port map (clock, tombol, mode);
    
    uut : process
        begin
            clock <= '0';
            wait for clock_period;
            clock <= '1';
            counter_clock <= counter_clock + 1;
            wait for clock_period;

            if(counter_clock = ) then -- case untuk mode penyebrang 1
                if

            if(counter_clock = ) then -- case untuk mode penyebrang 2 (lansia dan carrier)
                if

            if(counter_clock = ) then -- case untuk mode penyebrang 3 (tunanetra)
                if

    

end architecture;