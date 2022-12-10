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
    signal clock_counter : integer := 0;
    signal tombol : std_logic_vector := '00';
    
    -- 00 untuk tidak menyebrang (default)
    -- 01 untuk orang dewasa, 
    -- 10 untuk lansia dan carrier, 
    -- 11 untuk tunanetra

begin
    test : main_program port map (clock, tombol, mode);
    
    uut : process
        begin
            clock <= '0';
            wait for clock_period;
            clock <= '1';
            clock_counter <= clock_counter + 1;
            wait for clock_period;

            -- membiarkan mode idle selama 15 detik
            if(clock_counter = 15) then
                tombol <= '00'
            assert mode = '00'
                report "Tidak dapat melakukan reset karena dalam mode idle"
                severity note;
            
            elsif(clock_counter = 20) then
                tombol <= '10' -- mencoba mode 2
            
            elsif(clock_counter = 35) then
                tombol <= '11' -- melakukan interupsi dengan mencoba mode 11
            assert mode = '10'
                report "Tidak dapat melakukan mode tunanetra, silahkan reset terlebih dahulu"
                severity warning;
            
            elsif(clock_counter = 42) then
                tombol <= '01'
            
            elsif(clock_counter = 40) then
                tombol <= '00' -- melakukan reset sebelum selesai

            elsif(clock_counter = 45) then
                tombol <= '11' -- mode tunanetra
            
            elsif(clock_counter = 85) then
                tombol <= '00' -- melakukan reset sebelum selesai
            
            elsif(clock_counter = '90') then
                tombol <= '01'
            
            elsif(clock_counter = 120) then
                tombol <= '11'
            
            elsif(counter_clock = 190) then
                wait;
            end if;
        end process;

end architecture;
