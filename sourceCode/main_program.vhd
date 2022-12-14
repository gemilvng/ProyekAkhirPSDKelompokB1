library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity main_program is
    port (
    clock   : in std_logic;
    tombol  : in std_logic_vector (1 downto 0); -- 00 untuk reset
    mode    : out std_logic_vector (1 downto 0) -- 00 untuk tidak menyebrang (default)
                                                -- 01 untuk orang dewasa, 
                                                -- 10 untuk lansia dan carrier, 
                                                -- 11 untuk tunanetra
    );
end main_program; 

architecture behave of main_program is
    --Component Low Lever Decoder BCD to 7-Segment
    component Decoder is
        port (
            clk : in std_logic;
            bcd : in std_logic_vector(3 downto 0);  --BCD input
            segment7 : out std_logic_vector(6 downto 0)  -- 7 bit decoded output.
        );
    end component;

    constant waktu_transisi : integer := 5; --limit waktu transisi sesaat ada yang menekan tombol = 4 detik
    constant waktu_menyebrang_dewasa : integer := 20; --limit waktu saat menyebrang = 20 detik
    constant waktu_menyebrang_lainnya : integer := 60; --limit waktu saat menyebrang = 20 detik

    signal trigger_5 : std_logic := '0'; --trigger untuk memulai counter 5 detik
    signal trigger_20 : std_logic := '0'; --trigger untuk memulai counter 20 detik
    signal trigger_60 : std_logic := '0'; -- trigger untuk memulai counter 60
    signal buzzer : std_logic := '0'; -- trigger untuk menyalakan buzzer
    signal trigger_STM : std_logic := '0';

    type state is (   --Define State kondisi jalan raya
        state_default, 
        menyebrang_dewasa, 
        menyebrang_lansia, 
        menyebrang_tunanetra, 
        transisi
        ); 
    signal PS, NS: state;

    type lampu is (merah, kuning, hijau);                   --Define warna yang akan menyala pada lampu
    signal lampu_jalanRaya, lampu_penyebrang : lampu;

    signal clock_count : integer := 0;                      --counter berdasarkan clock cycle
    signal STM_counter1 : integer := 0;                   
    signal inputPuluhan : std_logic_vector (3 downto 0);    --Input decoder untuk 7-segment puluhan
    signal inputSatuan : std_logic_vector (3 downto 0);     --Input decoder untuk 7 segement satuan
    signal outputPuluhan : std_logic_vector (6 downto 0);   --Output decoder untuk 7-segment puluhan
    signal outputSatuan : std_logic_vector (6 downto 0);    --Output decoder untuk 7-segemnt satuan

    

begin
    --define 2 decoder untuk 7-segment puluhan dan satuan
    decode_puluhan : Decoder port map (clock, inputPuluhan, outputPuluhan);
    decode_satuan : Decoder port map (clock, inputSatuan, outputSatuan);

    --Synchronous process (Merepresentasikan Flip FLop (terdapat Memory))
    sync_proc : process (clock, NS) --Variable control ada clock, dan Next State (NS)
    begin
        if rising_edge(clock) then 
            PS <= NS;              
        end if;
    end process sync_proc;

    --Combinatioral process 
    comb_proc : process (STM_counter1,clock_count,tombol, PS) --Variable control ada clock-couter , tombol penyebrang (input 1 saat ada yang menekan tombol), Present State (PS)
    begin
        trigger_20 <= '0';
        trigger_5 <= '0';

        case PS is
            when state_default =>                --Kondisi saat tidak ada pejalan kaki yang ingin menyebrang
                mode <= "00";
                lampu_jalanRaya <= hijau;           
                lampu_penyebrang <= merah;
                trigger_STM <= '1';        
                if (tombol = "00") then              --Jika tidak ada pejalan kaki yang menekan tombol
                    NS <= state_default;
                else        --Saat ada pejalan kaki yang menekan tombol ingin menyebrang jalan
                    NS <= transisi;         --Next State tetap ke kondisi state_default
                end if;

            when transisi =>                          --Kondisi sesaat setelah ada pejalan kaki yang menekan tombol
                lampu_jalanRaya <= kuning;          
                lampu_penyebrang <= kuning;         
                trigger_5 <= '1';                                       --Trigger counter 5 detik aktif
                if((clock_count = waktu_transisi) and (tombol = "01")) then NS <= menyebrang_dewasa;
                elsif((clock_count = waktu_transisi) and (tombol = "10")) then NS <= menyebrang_lansia;
                elsif((clock_count = waktu_transisi) and (tombol = "11")) then NS <= menyebrang_tunanetra;
                elsif((clock_count = waktu_transisi) and (tombol = "00")) then NS <= state_default;   --Setelah counter bernilai sama dengan waktu transisi yaitu 5 maka NS menjadi kondisi menyebrang
                end if;

            when menyebrang_dewasa =>                  --Kondisi saat pejalan kaki boleh menyebrang dan kendaraan wajib berhenti
                mode <= "01";
                lampu_jalanRaya <= merah;
                lampu_penyebrang <= hijau;
                trigger_20 <= '1';                                                  --Trigger counter 20 detik aktif
                if ((clock_count = waktu_menyebrang_dewasa) or (tombol = "00")) then 
                    NS <= transisi;                                         
                end if;
            
            when menyebrang_lansia =>                  --Kondisi saat pejalan kaki boleh menyebrang dan kendaraan wajib berhenti
                mode <= "10";
                lampu_jalanRaya <= merah;
                lampu_penyebrang <= hijau;
                trigger_60 <= '1';                                                  --Trigger counter 60 detik aktif
                if ((clock_count = waktu_menyebrang_lainnya) or (tombol = "00")) then 
                    NS <= transisi;                                         
                end if;
            
                when menyebrang_tunanetra =>                  --Kondisi saat pejalan kaki boleh menyebrang dan kendaraan wajib berhenti
                mode <= "11";
                lampu_jalanRaya <= merah;
                lampu_penyebrang <= hijau;
                buzzer <= '1';
                trigger_60 <= '1';                                                  --Trigger counter 60 detik aktif
                if ((clock_count = waktu_menyebrang_lainnya) or (tombol = "00")) then 
                    NS <= transisi;                                         
                end if;
            
            end case;
            end process comb_proc;

        --Prosess counter waktu
        timer : process (trigger_STM, trigger_20, trigger_5, clock)
        begin
            if trigger_5 = '1' then
                STM_counter1 <= 1;                                                 --Jika trigger counter 5 detik menyala, maka counter akan menghitung 5 kali clock cycle
                if rising_edge(clock) then                                          --Saat clock kondisi naik            
					clock_count <= clock_count + 1;                                 --Counter akan bertamabh 1
					if (clock_count = waktu_transisi) then                            --Saat counter bernilai sama dengan waktu transisi atau 5 detik
                        clock_count <= 0;                                           -- clock_count akan direset
					end if;
				end if;

            elsif trigger_20 = '1' then                                             --Jika trigger counter 20 detik menyala, maka counter akan menghitung 20 kali clock cycle
                if rising_edge(clock) then                                          -- saat clock kondisi naik
					clock_count <= clock_count + 1;                                 -- counter akan bertambah 1
					if (clock_count = waktu_menyebrang_dewasa) then                        --Saat counter bernilai sama dengan waktu menyebrang atau 20
                        clock_count <= 0;                                           --Counter akan direset
					end if;
				end if;
            
            elsif trigger_60 = '1' then                                             --Jika trigger counter 60 detik menyala, maka counter akan menghitung 60 kali clock cycle
                if rising_edge(clock) then                                          -- saat clock kondisi naik
					clock_count <= clock_count + 1;                                 -- counter akan bertambah 1
					if (clock_count = waktu_menyebrang_lainnya) then                        --Saat counter bernilai sama dengan waktu menyebrang atau 60
                        clock_count <= 0;                                           --Counter akan direset
					end if;
				end if;
            
            elsif trigger_STM = '1' then
                if rising_edge(clock) then
                    STM_counter1 <= STM_counter1 + 1;
                end if;
            end if;               
            end process timer;

        --proses input control untuk decoder puluhan dan satuan berdasarkan counter clock cycle        
        decControl : process (clock_count, trigger_5, trigger_20, trigger_60)
        begin
            --Saat kondisi transisi atau sesaat setelah pejalan kaki menekan tombol
            --7 segment akan menampilkan hitung mundur 5 detik
            --Karena counter merupakan count up maka input decoder dibuat terbalik dengan counter
            if(trigger_5 = '1') then
                inputPuluhan <= "1111"; 
                case clock_count is
                    when 1 => inputSatuan <= "0101"; --5
                    when 2 => inputSatuan <= "0100"; --4
                    when 3 => inputSatuan <= "0011"; --3
                    when 4 => inputSatuan <= "0010"; --2
                    when 5 => inputSatuan <= "0001"; --1
                    when others => inputSatuan <= "1111"; --Mati
                end case;

            --Saat kondisi pejalan kaki menyebrang dan kendaraan wajib berhenti
            --7 segment akan menampilkan hitung mundur 20 detik
            --Karena counter merupakan count up, maka input decoder dibuat terbalik dengan counter
            elsif(trigger_20 = '1') then
                case clock_count is
                    when 1 =>                   
                        inputPuluhan <= "0010"; --20
                        inputSatuan <= "0000";
                    when 2 =>                   
                        inputPuluhan <= "0001"; --19
                        inputSatuan <= "1001";
                    when 3 => 
                        inputPuluhan <= "0001"; --18              
                        inputSatuan <= "1000";
                    when 4 =>  
                        inputPuluhan <= "0001"; --17           
                        inputSatuan <= "0111";
                    when 5 =>        
                        inputPuluhan <= "0001"; --16
                        inputSatuan <= "0110";
                    when 6 => 
                        inputPuluhan <= "0001"; --15
                        inputSatuan <= "0101";
                    when 7 =>   
                        inputPuluhan <= "0001"; --14
                        inputSatuan <= "0100";
                    when 8 =>
                        inputPuluhan <= "0001"; --13
                        inputSatuan <= "0011";
                    when 9 =>
                        inputPuluhan <= "0001"; --12
                        inputSatuan <= "0010";
                    when 10 =>
                        inputPuluhan <= "0001"; --11
                        inputSatuan <= "0001";
                    when 11 =>                   
                        inputPuluhan <= "0001"; --10
                        inputSatuan <= "0000";
                    when 12 =>                   
                        inputPuluhan <= "0000"; --9
                        inputSatuan <= "1001";
                    when 13 =>    
                        inputPuluhan <= "0000"; --8          
                        inputSatuan <= "1000";
                    when 14 => 
                        inputPuluhan <= "0000"; --7       
                        inputSatuan <= "0111";
                    when 15 => 
                        inputPuluhan <= "0000"; --6   
                        inputSatuan <= "0110";
                    when 16 => 
                        inputPuluhan <= "0000"; --5
                        inputSatuan <= "0101";
                    when 17 => 
                        inputPuluhan <= "0000"; --4
                        inputSatuan <= "0100";
                    when 18 =>
                        inputPuluhan <= "0000"; --3
                        inputSatuan <= "0011";
                    when 19 => 
                        inputPuluhan <= "0000"; --2
                        inputSatuan <= "0010";
                    when 20 =>
                        inputPuluhan <= "0000"; --1
                        inputSatuan <= "0001";
                    when others => 
                        inputPuluhan <= "1111"; --Mati
                        inputSatuan <= "1111"; --Mati
                end case;
            elsif(trigger_60 = '1') then
                case clock_count is
                    when 1 =>                   
                        inputPuluhan <= "0111"; --60
                        inputSatuan <= "0000";
                    when 2 =>                   
                        inputPuluhan <= "0101"; --59
                        inputSatuan <= "1001";
                    when 3 => 
                        inputPuluhan <= "0101"; --58              
                        inputSatuan <= "1000";
                    when 4 =>  
                        inputPuluhan <= "0101"; --57           
                        inputSatuan <= "0111";
                    when 5 =>        
                        inputPuluhan <= "0101"; --56
                        inputSatuan <= "0110";
                    when 6 => 
                        inputPuluhan <= "0101"; --55
                        inputSatuan <= "0101";
                    when 7 =>   
                        inputPuluhan <= "0101"; --54
                        inputSatuan <= "0100";
                    when 8 =>
                        inputPuluhan <= "0101"; --53
                        inputSatuan <= "0011";
                    when 9 =>
                        inputPuluhan <= "0101"; --52
                        inputSatuan <= "0010";
                    when 10 =>
                        inputPuluhan <= "0101"; --51
                        inputSatuan <= "0001";
                    when 11 =>                   
                        inputPuluhan <= "0101"; --50
                        inputSatuan <= "0000";
                    when 12 =>                   
                        inputPuluhan <= "0100"; --49
                        inputSatuan <= "1001";
                    when 13 =>    
                        inputPuluhan <= "0100"; --48          
                        inputSatuan <= "1000";
                    when 14 => 
                        inputPuluhan <= "0100"; --47       
                        inputSatuan <= "0111";
                    when 15 => 
                        inputPuluhan <= "0100"; --46   
                        inputSatuan <= "0110";
                    when 16 => 
                        inputPuluhan <= "0100"; --45
                        inputSatuan <= "0101";
                    when 17 => 
                        inputPuluhan <= "0100"; --44
                        inputSatuan <= "0100";
                    when 18 =>
                        inputPuluhan <= "0100"; --43
                        inputSatuan <= "0011";
                    when 19 => 
                        inputPuluhan <= "0100"; --42
                        inputSatuan <= "0010";
                    when 20 =>
                        inputPuluhan <= "0100"; --41
                        inputSatuan <= "0001";
                    when 21 =>                   
                        inputPuluhan <= "0100"; --40
                        inputSatuan <= "0000";
                    when 22 =>                   
                        inputPuluhan <= "0011"; --39
                        inputSatuan <= "1001";
                    when 23 => 
                        inputPuluhan <= "0011"; --38              
                        inputSatuan <= "1000";
                    when 24 =>  
                        inputPuluhan <= "0011"; --37           
                        inputSatuan <= "0111";
                    when 25 =>        
                        inputPuluhan <= "0011"; --36
                        inputSatuan <= "0110";
                    when 26 => 
                        inputPuluhan <= "0011"; --35
                        inputSatuan <= "0101";
                    when 27 =>   
                        inputPuluhan <= "0011"; --34
                        inputSatuan <= "0100";
                    when 28 =>
                        inputPuluhan <= "0011"; --33
                        inputSatuan <= "0011";
                    when 29 =>
                        inputPuluhan <= "0011"; --32
                        inputSatuan <= "0010";
                    when 30 =>
                        inputPuluhan <= "0011"; --31
                        inputSatuan <= "0001";
                    when 31 =>                   
                        inputPuluhan <= "0011"; --30
                        inputSatuan <= "0000";
                    when 32 =>                   
                        inputPuluhan <= "0010"; --29
                        inputSatuan <= "1001";
                    when 33 => 
                        inputPuluhan <= "0010"; --28              
                        inputSatuan <= "1000";
                    when 34 =>  
                        inputPuluhan <= "0010"; --27           
                        inputSatuan <= "0111";
                    when 35 =>        
                        inputPuluhan <= "0010"; --26
                        inputSatuan <= "0110";
                    when 36 => 
                        inputPuluhan <= "0010"; --25
                        inputSatuan <= "0101";
                    when 37 =>   
                        inputPuluhan <= "0010"; --24
                        inputSatuan <= "0100";
                    when 38 =>
                        inputPuluhan <= "0010"; --23
                        inputSatuan <= "0011";
                    when 39 =>
                        inputPuluhan <= "0010"; --22
                        inputSatuan <= "0010";
                    when 40 =>
                        inputPuluhan <= "0010"; --21
                        inputSatuan <= "0001";
                    when 41 =>                   
                        inputPuluhan <= "0010"; --20
                        inputSatuan <= "0000";
                    when 42 =>                   
                        inputPuluhan <= "0001"; --19
                        inputSatuan <= "1001";
                    when 43 => 
                        inputPuluhan <= "0001"; --18              
                        inputSatuan <= "1000";
                    when 44 =>  
                        inputPuluhan <= "0001"; --17           
                        inputSatuan <= "0111";
                    when 45 =>        
                        inputPuluhan <= "0001"; --16
                        inputSatuan <= "0110";
                    when 46 => 
                        inputPuluhan <= "0001"; --15
                        inputSatuan <= "0101";
                    when 47 =>   
                        inputPuluhan <= "0001"; --14
                        inputSatuan <= "0100";
                    when 48 =>
                        inputPuluhan <= "0001"; --13
                        inputSatuan <= "0011";
                    when 49 =>
                        inputPuluhan <= "0001"; --12
                        inputSatuan <= "0010";
                    when 50 =>
                        inputPuluhan <= "0001"; --11
                        inputSatuan <= "0001";
                    when 51 =>                   
                        inputPuluhan <= "0010"; --10
                        inputSatuan <= "0000";
                    when 52 =>                   
                        inputPuluhan <= "0000"; --9
                        inputSatuan <= "1001";
                    when 53 => 
                        inputPuluhan <= "0000"; --8              
                        inputSatuan <= "1000";
                    when 54 =>  
                        inputPuluhan <= "0000"; --7           
                        inputSatuan <= "0111";
                    when 55 =>        
                        inputPuluhan <= "0000"; --6
                        inputSatuan <= "0110";
                    when 56 => 
                        inputPuluhan <= "0000"; --5
                        inputSatuan <= "0101";
                    when 57 =>   
                        inputPuluhan <= "0000"; --4
                        inputSatuan <= "0100";
                    when 58 =>
                        inputPuluhan <= "0000"; --3
                        inputSatuan <= "0011";
                    when 59 =>
                        inputPuluhan <= "0000"; --2
                        inputSatuan <= "0010";
                    when 60 =>
                        inputPuluhan <= "0000"; --1
                        inputSatuan <= "0001";
                    when others => 
                        inputPuluhan <= "1111"; --Mati
                        inputSatuan <= "1111"; --Mati
                end case;
            end if;
        end process ;


end architecture ;