LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Top_Level IS
    GENERIC (
        MAX_VALUE  : INTEGER := 25000; -- Max value for PWM
        N_BIT      : INTEGER := 7     -- Bit width for encoder and PWM
    );
    PORT (
        CLK          : IN  std_logic;
        RESET        : IN  std_logic;
        CONTROL_BUS  : IN  std_logic_vector(31 DOWNTO 0); -- KP, KI, KD, and SETPOINT combined
        ENCODER_A    : IN  std_logic;
        ENCODER_B    : IN  std_logic;
        PWM_OUT      : OUT std_logic;
        PWM_ERROR    : OUT std_logic;
        ENC_ERROR    : OUT std_logic
    );
END Top_Level;

ARCHITECTURE Behavioral OF Top_Level IS
    -- Signals for internal connections
    SIGNAL POSITION     : std_logic_vector(7 DOWNTO 0); -- Encoder position
    SIGNAL PID_OUTPUT   : signed(15 DOWNTO 0);             -- PID output
    SIGNAL KP, KI, KD   : signed(7 DOWNTO 0);             -- PID gains
    SIGNAL SETPOINT     : signed(7 DOWNTO 0);             -- Desired value for PID
    SIGNAL ERROR        : signed(7 DOWNTO 0):= (others=>'0');
BEGIN

    -- Split the CONTROL_BUS into KP, KI, KD, and SETPOINT
    KP       <= signed(CONTROL_BUS(7 DOWNTO 0));
    KI       <= signed(CONTROL_BUS(15 DOWNTO 8));
    KD       <= signed(CONTROL_BUS(23 DOWNTO 16));
    SETPOINT <= signed(CONTROL_BUS(31 DOWNTO 24));
    
    -- Encoder Instance
    Encoder_inst : ENTITY work.Encoder
        GENERIC MAP (
            N_BIT => N_BIT
        )
        PORT MAP (
            CLK       => CLK,
            RST       => RESET,
            A         => ENCODER_A,
            B         => ENCODER_B,
            POSITION  => POSITION,
            ENC_ERROR => ENC_ERROR
        );
    ERROR <= SETPOINT-signed(POSITION);
    -- PID Controller Instance
    PID_inst : ENTITY work.PID
        PORT MAP (
            CLK         => CLK,
            RESET       => RESET,
            ERROR       => ERROR,
            KP          => KP,
            KI          => KI,
            KD          => KD,
            OUTPUT      => PID_OUTPUT
        );

    -- PWM Generator Instance
    PWM_inst : ENTITY work.PWM
        GENERIC MAP (
            MAX_VALUE => MAX_VALUE,
            N_BIT     => 15
        )
        PORT MAP (
            RST       => RESET,
            CLK       => CLK,
            POWER     => std_logic_vector(PID_OUTPUT),
            PWM_OUT   => PWM_OUT,
            PWM_DIR   => OPEN, -- Not used in this design
            PWM_ERROR => PWM_ERROR
        );

END Behavioral;
