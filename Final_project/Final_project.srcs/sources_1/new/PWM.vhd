library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PWM is
    Generic (
        N : integer := 8 -- Length of the POWER signal
    );
    Port (
        CLK : in STD_LOGIC;
        RST : in STD_LOGIC;
        POWER : in STD_LOGIC_VECTOR(N-1 downto 0);
        PWM_OUT : out STD_LOGIC;
        PWM_ERROR : out STD_LOGIC;
        PWM_DIR : out STD_LOGIC
    );
end PWM;

architecture Behavioral of PWM is
    signal counter : integer := 0;
    constant MAX_VALUE : integer := 2**(N-1) - 1; -- Calculate MAX_VALUE based on N
    constant MAX_POWER : integer := 25000; -- Calculate MAX_VALUE based on N
    signal power_int : integer;
begin

    process(CLK, RST) begin
        -- Reset Case
        if RST = '0' then
            counter <= 0;
            PWM_OUT <= '0';
            PWM_ERROR <= '0';
            PWM_DIR <= 'Z';
            
        elsif rising_edge(CLK) then
            -- Convert POWER to integer every clock cycle
            power_int <= to_integer(abs(signed(POWER)));
            
             -- POWER does not exceed MAX_VALUE --> Continue going
            if ( ( (power_int <=  MAX_POWER) AND (power_int >= -MAX_POWER) ) OR (RST = '1') ) then
                PWM_ERROR <= '0';

                -- Every Clock cycle increase counter until it's at MAX_VALUE, in which case it resets
                if counter >= MAX_VALUE then
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
                
                -- If the counter is lower than POWER go HIGH, otherwise go LOW
                if counter <= power_int then
                    PWM_OUT <= '1';
                else 
                    PWM_OUT <= '0';
                end if;
                
                -- The MSB of POWER determines the direction.
                PWM_DIR <= POWER(N-1);
            
            --Power exceeds MAX_VALUE --> Give error
            else 
                PWM_ERROR <= '1';
                PWM_OUT <= '0';
                PWM_DIR <= 'Z';
            end if;
            
        end if;
    end process;
end Behavioral;
