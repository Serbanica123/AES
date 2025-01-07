--Add Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Define Entity
entity ENCODER is

    generic (
        N : integer := 16 -- Length of the POSITION signal
    );

    port (
        CLK         : in  std_logic;
        RST         : in  std_logic;
        A           : in  std_logic;
        B           : in  std_logic;
        ENC_ERROR   : out std_logic;
        POSITION    : out std_logic_vector(N-1 downto 0)
    );
end ENCODER;

--Define Architecture
architecture behavioral of ENCODER is
  
  --Define StateMachine
  type state_type is (s00, s01, s10, s11, errState);
  
  --Define Signals
  signal state : state_type;
  signal AB : std_logic_vector(1 downto 0);
  signal position_internal : integer;
 
begin
  
  --Bundle A&B to AB
  AB <= A & B;
  
  --Assign internal position to output
  POSITION <= std_logic_vector(to_signed(position_internal, N));
  
  --Process Encoder (Based on StateMachine)
  process(CLK, RST) is  
  begin
    if RST = '0' then
        --Set Correct state
        case AB is
            when "00" => 
                state <= s00;
            when "01" =>
                state <= s01;
            when "10" =>
                state <= s10;
            when "11" =>
                state <= s11;
            when others => 
                state <= errState;
        end case;
        --Reset Position to 0
        position_internal <= 0;
        ENC_ERROR <= '0';
        
        
    elsif rising_edge(CLK) then 
        case state is
            when s00 => --Increment or lower the position
                if (AB = "01")  then 
                    position_internal <= position_internal + 1; 
                    state <= s01;
                elsif (AB = "10") then
                    position_internal <= position_internal - 1; 
                    state <= s10;
                elsif (AB = "11") then
                    state <= errState;
                end if;
                
            when s01 =>--Increment or lower the position
                if (AB = "11")  then 
                    position_internal <= position_internal + 1; 
                    state <= s11;
                elsif (AB = "00") then
                    position_internal <= position_internal - 1;
                    state <= s00;
                elsif (AB = "10") then
                    state <= errState;
                end if;
                
            when s10 =>--Increment or lower the position
                if (AB = "00")  then 
                    position_internal <= position_internal + 1; 
                    state <= s00;
                elsif (AB = "11") then
                    position_internal <= position_internal - 1; 
                    state <= s11;
                elsif (AB = "01") then
                    state <= errState;
                end if;
                
            when s11 =>--Increment or lower the position
                if (AB = "10")  then 
                    position_internal <= position_internal + 1; 
                    state <= s10;
                elsif (AB = "01") then
                    position_internal <= position_internal - 1; 
                    state <= s01;
                elsif (AB = "00") then
                    state <= errState;
                end if;
                
            when errState =>
                ENC_ERROR <= '1';
            when others => 
                ENC_ERROR <= '1';
                
        end case;
    end if;
  end process;
  
end behavioral;
