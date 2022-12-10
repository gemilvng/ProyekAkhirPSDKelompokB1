library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Decoder is
port (
        clk : in std_logic;
        bcd : in std_logic_vector(3 downto 0);  --BCD input
        segment7 : out std_logic_vector(6 downto 0)  -- 7 bit decoded output.
    );
end Decoder;
--'a' corresponds to MSB of segment7 and g corresponds to LSB of segment7.
architecture behave of Decoder is

begin
process (clk,bcd)
BEGIN
    if (rising_edge(clk)) then  
        -- 0 mati 
        -- 1 hidup
        case  bcd is
            when "0000"=> segment7 <= "1111110";  -- '0'
            when "0001"=> segment7 <= "0110000";  -- '1'
            when "0010"=> segment7 <= "1101101";  -- '2'
            when "0011"=> segment7 <= "1111001";  -- '3'
            when "0100"=> segment7 <= "0110011";  -- '4'
            when "0101"=> segment7 <= "1011011";  -- '5'
            when "0110"=> segment7 <= "1011111";  -- '6'
            when "0111"=> segment7 <= "1110000";  -- '7'
            when "1000"=> segment7 <= "1111111";  -- '8'
            when "1001"=> segment7 <= "1111011";  -- '9'
            --nothing is displayed when a number more than 9 is given as input.
            when others=> segment7 <="0000000";
        end case;
    end if;

end process;

end behave;