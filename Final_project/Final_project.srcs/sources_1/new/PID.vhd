LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY PID IS

GENERIC(
    MAX_OUTPUT: INTEGER := 25000
);
	PORT (
		CLK          : IN std_logic;
		RESET        : IN std_logic;
		ERROR  : IN signed(7 DOWNTO 0); -- System feedback
		KP           : IN signed(7 DOWNTO 0); -- Proportional gain
		KI           : IN signed(7 DOWNTO 0); -- Integral gain
		KD           : IN signed(7 DOWNTO 0); -- Derivative gain
		OUTPUT       : OUT signed(15 DOWNTO 0)  -- Output signal
	);
END PID;

ARCHITECTURE Behavioral OF PID IS
	SIGNAL PREV_ERROR   : signed(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL PROPORTIONAL : signed(15 DOWNTO 0) := (OTHERS => '0');
	SIGNAL INTEGRAL     : signed(15 DOWNTO 0) := (OTHERS => '0');
	SIGNAL DERIVATIVE   : signed(15 DOWNTO 0) := (OTHERS => '0');
	SIGNAL OUTPUT_TEMP  : signed(15 DOWNTO 0) := (OTHERS => '0');
	SIGNAL DT           : signed(7 DOWNTO 0) := to_signed(2, 8); -- Fixed time step
	SIGNAL KD_DT :signed(7 DOWNTO 0) := KD/DT;
BEGIN

	PROPORTIONAL_PROCESS : PROCESS (CLK, RESET)
	BEGIN
		IF RESET = '1' THEN
			PROPORTIONAL <= (OTHERS => '0');
		ELSIF rising_edge(CLK) THEN
			PROPORTIONAL <= ERROR * KP;
		END IF;
	END PROCESS;

	INTEGRAL_PROCESS : PROCESS (CLK, RESET)
	BEGIN
		IF RESET = '1' THEN
			INTEGRAL <= (OTHERS => '0');
		ELSIF rising_edge(CLK) THEN
			INTEGRAL <= resize(INTEGRAL + resize(ERROR * KI * DT, INTEGRAL'LENGTH), INTEGRAL'LENGTH);
		END IF;
	END PROCESS;

	DERIVATIVE_PROCESS : PROCESS (CLK, RESET)
	BEGIN
		IF RESET = '1' THEN
			DERIVATIVE <= (OTHERS => '0');
			PREV_ERROR <= (OTHERS => '0');
		ELSIF rising_edge(CLK) THEN
			IF DT /= 0 THEN
				DERIVATIVE <= KD_DT * (ERROR - PREV_ERROR);
			ELSE
				DERIVATIVE <= (OTHERS => '0');
				PREV_ERROR <= ERROR;
			END IF;
		END IF;
	END PROCESS;

	OUTPUT_PROCESS : PROCESS (CLK, RESET)
	BEGIN
		IF RESET = '1' THEN
			OUTPUT <= (OTHERS => '0');
		ELSIF rising_edge(CLK) THEN
			OUTPUT_TEMP <= PROPORTIONAL+DERIVATIVE+INTEGRAL;
			IF OUTPUT_TEMP > to_signed(MAX_OUTPUT, 16) THEN
				OUTPUT <= to_signed(MAX_OUTPUT, 16); -- Max limit
			ELSIF OUTPUT_TEMP < to_signed(-MAX_OUTPUT, 16) THEN
				OUTPUT <= to_signed(-MAX_OUTPUT, 16); -- Min limit
			ELSE
				OUTPUT <= OUTPUT_TEMP; 
			END IF;
		END IF;
	END PROCESS;

END Behavioral;
