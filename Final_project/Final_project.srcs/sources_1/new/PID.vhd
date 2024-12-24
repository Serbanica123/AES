LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY PID IS
	PORT (
		CLK          : IN std_logic;
		RESET        : IN std_logic;
		SETPOINT     : IN signed(15 DOWNTO 0); -- Desired value
		MEASUREMENT  : IN signed(15 DOWNTO 0); -- System feedback
		KP           : IN signed(15 DOWNTO 0); -- Proportional gain
		KI           : IN signed(15 DOWNTO 0); -- Integral gain
		KD           : IN signed(15 DOWNTO 0); -- Derivative gain
		OUTPUT       : OUT signed(15 DOWNTO 0)  -- Output signal
	);
END PID;

ARCHITECTURE Behavioral OF PID IS
	SIGNAL ERROR        : signed(15 DOWNTO 0) := (OTHERS => '0');
	SIGNAL PREV_ERROR   : signed(15 DOWNTO 0) := (OTHERS => '0');
	SIGNAL PROPORTIONAL : signed(31 DOWNTO 0) := (OTHERS => '0');
	SIGNAL INTEGRAL     : signed(31 DOWNTO 0) := (OTHERS => '0');
	SIGNAL DERIVATIVE   : signed(31 DOWNTO 0) := (OTHERS => '0');
	SIGNAL OUTPUT_TEMP  : signed(31 DOWNTO 0) := (OTHERS => '0');
	SIGNAL DT           : signed(15 DOWNTO 0) := to_signed(1, 16); -- Fixed time step
BEGIN
	ERROR_PROCESS : PROCESS (CLK, RESET)
	BEGIN
		IF RESET = '1' THEN
			ERROR <= (OTHERS => '0');
			PREV_ERROR <= (OTHERS => '0');
		ELSIF rising_edge(CLK) THEN
			PREV_ERROR <= ERROR;
			ERROR <= SETPOINT - MEASUREMENT;
		END IF;
	END PROCESS;

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
			INTEGRAL <= INTEGRAL + ERROR * KI * DT;
		END IF;
	END PROCESS;

	DERIVATIVE_PROCESS : PROCESS (CLK, RESET)
	BEGIN
		IF RESET = '1' THEN
			DERIVATIVE <= (OTHERS => '0');
		ELSIF rising_edge(CLK) THEN
			IF DT /= 0 THEN
				DERIVATIVE <= KD * (ERROR - PREV_ERROR) / DT;
			ELSE
				DERIVATIVE <= (OTHERS => '0');
			END IF;
		END IF;
	END PROCESS;

	OUTPUT_PROCESS : PROCESS (CLK, RESET)
	BEGIN
		IF RESET = '1' THEN
			OUTPUT <= (OTHERS => '0');
		ELSIF rising_edge(CLK) THEN
			OUTPUT_TEMP <= PROPORTIONAL + INTEGRAL + DERIVATIVE;
			IF OUTPUT_TEMP > to_signed(32767, 32) THEN
				OUTPUT <= to_signed(32767, 16); -- Max limit
			ELSIF OUTPUT_TEMP < to_signed(-32768, 32) THEN
				OUTPUT <= to_signed(-32768, 16); -- Min limit
			ELSE
				OUTPUT <= resize(OUTPUT_TEMP, 16); -- Cast to 16 bits
			END IF;
		END IF;
	END PROCESS;

END Behavioral;
