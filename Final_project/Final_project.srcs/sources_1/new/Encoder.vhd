library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.MATH_REAL.ALL;

entity Encoder is
  generic (
      N_BIT : integer := 15
   );
    
  port (
      CLK          : in  std_logic;
      RST          : in  std_logic;
      A            : in  std_logic;
      B	           : in  std_logic;
      POSITION     : out std_logic_vector(N_BIT downto 0);
      ENC_ERROR    : out std_logic
  );
end entity Encoder;

architecture Behavioral of Encoder is   
    -- Define the states
    type State is (errState, S01, S00, S10, S11);
    signal current_state : State;

    -- Define the position counter
    signal position_counter : integer range -(2**N_BIT) to (2**N_BIT)-1; -- -2^15 to +2^15 - 1
    signal AB: std_logic_vector(1 downto 0);
    
begin
    
	 AB <= A & B;
	 POSITION <= std_logic_vector(to_signed(position_counter, N_BIT+1));
	 
    -- Synchronous process for state transition
    process(CLK, RST, AB)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
			 -- Ensures that everytime RST is on then ENC_ERROR & POSITION should be 0
               ENC_ERROR <= '0'; 
               
               -- Reset Mode 
               case(AB) is
		          when "01" =>
                      current_state <= S01;
		          when "00" =>
                      current_state <= S00;
		          when "10" =>
                      current_state <= S10;
		          when "11" =>
                      current_state <= S11;
                  when others =>
                      current_state <= errState;
                      position_counter <= 0;
                      ENC_ERROR <= '0';
		          end case;
		          
		       else
		       -- Normal Mode Operation
                ENC_ERROR <= '0';
		        case (current_state) is
		          when S01 =>
                    if AB = "00" then
                       current_state <= S00;
                       position_counter <= position_counter + 1;
                    end if;
						 
	                if AB = "11" then
                       current_state <= S11;
                       position_counter <= position_counter - 1;
                    end if;
						 
                    if AB = "10" then 
                       current_state <= errState;
                    end if;
						 
		          when S00 =>
                    if AB = "10" then
                       current_state <= S10;
                       position_counter <= position_counter + 1;
                    end if;
						 
	                if AB = "01" then
                       current_state <= S01;
                       position_counter <= position_counter - 1;
                    end if;
						 
                    if AB = "11" then
                       current_state <= errState;
                    end if;
						 
                  when S10 =>
                    if AB = "11" then
                       current_state <= S11;
                       position_counter <= position_counter + 1;
                    end if;
						 
                    if AB = "00" then
                       current_state <= S00;
                       position_counter <= position_counter - 1;
                    end if;
						 
                    if AB = "01" then
                       current_state <= errState;
                    end if;
					
                  when S11 =>
                    if AB = "01" then
                       current_state <= S01;
                       position_counter <= position_counter + 1;
                    end if;
                                 
                    if AB = "10" then
                       current_state <= S10;
                       position_counter <= position_counter - 1;
                    end if;
                                 
                    if AB = "00" then
                       current_state <= errState;  
                    end if;
         
		          when errState =>
		             current_state <= errState;
			         position_counter <= 0;
			         ENC_ERROR <= '1';
			      end case;
		     end if;
	    end if;
	    
    end process;
    
end architecture Behavioral;
