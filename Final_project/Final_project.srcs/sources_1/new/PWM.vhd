library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.MATH_REAL.ALL;

entity PWM is
    generic (
        MAX_VALUE  : integer := 25000; --Specs: 100us and 200us so the range clock cycles can vary from 12500 to 25000 period
        N_BIT      : integer := 15 --N-Bits required to describe the max value in power
    );
    Port ( 
        RST          : in std_logic;
        CLK          : in std_logic;
        POWER        : in std_logic_vector(N_BIT downto 0); --The counter ranges from 12500 to 25000, so you need max 15 bits bcs 2^15 = 32768;
        PWM_OUT      : out std_logic;
        PWM_DIR      : out std_logic;
        PWM_ERROR    : out std_logic
    );
end PWM;

architecture Behavioral of PWM is
    signal Counter : unsigned(N_BIT-1 downto 0);
begin

    RisingEdge : process(CLK, RST)
    begin
        if rising_edge(CLK) then
           if RST = '1' then
                -- Reset the counter
                Counter <= (others => '0'); 
           else    
               -- Reset the counter to zero if the counter reaches its max value
               if to_integer(unsigned(Counter)) >= MAX_VALUE then
                  -- Reset the counter
                   Counter <= (others => '0'); 
               else
                   -- Increment the counter by 1 if RST is off and counter is not at max value
                    Counter <= Counter + 1;
               end if;   
           end if;
        end if;
    end process;
    
    --PWM output is active ('1') when RST if off and the counter is less than the absolute value of POWER
    --PWM_OUT   <= '1' when (RST = '0' and to_integer(unsigned(Counter)) < to_integer(abs(signed(POWER)))) else '0'; 
    PWM_OUT <= '0' when RST = '1' else
    '1' when to_integer(unsigned(Counter)) < abs(signed(POWER)) else
    '0';
    
    -- When RST is active, PWM_DIR is set to high-impedance ('Z')
    -- When POWER is negative, PWM_DIR is '1'
    PWM_DIR   <= POWER(N_BIT) when RST = '0' else 'Z'; 
   
    -- When it is outside range, the power error activates
    PWM_ERROR <= '1' when (to_integer(abs(signed(POWER))) > MAX_VALUE) and RST = '0' else '0'; 

end Behavioral;
