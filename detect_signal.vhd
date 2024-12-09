LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY detect_signal IS
    GENERIC (
        stages : INTEGER := 124;
        n_output_bits : INTEGER := 8
    );
    PORT (
        clock : IN STD_LOGIC;
        start : IN STD_LOGIC;
        signal_in : IN STD_LOGIC;
        d_in : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
        written : IN STD_LOGIC;
        signal_running : OUT STD_LOGIC;
        reset : OUT STD_LOGIC;
        wrt : OUT STD_LOGIC
    );
END ENTITY detect_signal;


ARCHITECTURE fsm OF detect_signal IS

    -- Define the states of the FSM
    TYPE stype IS (IDLE, DETECT_START, WRITE_FIFO, RST);
    SIGNAL state, next_state : stype;

    -- Signals used to store the values of the signals
    SIGNAL reset_reg, reset_next : STD_LOGIC;
    SIGNAL signal_running_reg, signal_running_next : STD_LOGIC;
    SIGNAL wrt_reg, wrt_next : STD_LOGIC;
    SIGNAL count, count_reg, count_next : INTEGER range 0 to 4;

BEGIN
    -- FSM core
    PROCESS(clock)
    BEGIN
        IF rising_edge(clock) THEN
            -- Reset at start 
            IF start = '1' THEN
                state <= IDLE;
                signal_running_reg <= '0';
                reset_reg <= '0';
                wrt_reg <= '0';
                count <= 0;

            -- Update signals
            ELSE
                signal_running_reg <= signal_running_next;
                reset_reg <= reset_next;
                wrt_reg <= wrt_next;
                state <= next_state;
                count <= count_next;
            END IF;
        END IF;
    END PROCESS;

    -- FSM logic
    PROCESS (state, signal_running_reg, wrt_reg, reset_reg, signal_in, count, d_in, written)  
    BEGIN

        -- Default values
        next_state <= state;
        wrt_next <= wrt_reg;
        reset_next <= reset_reg;
        signal_running_next <= signal_running_reg;
        count_next <= count;

        CASE state IS
            WHEN IDLE =>
                IF signal_in = '1' THEN
                    next_state <= DETECT_START;
                ELSE
                    next_state <= IDLE;
                END IF;
                
            WHEN DETECT_START =>
                signal_running_next <= '1';
                next_state <= WRITE_FIFO;

            WHEN WRITE_FIFO =>
                IF count = 0 THEN
                    count_next <= count + 1;
                    next_state <= WRITE_FIFO;
                ELSIF count = 1 THEN
                    wrt_next <= '1';
                    count_next <= count + 1;
                    next_state <= WRITE_FIFO;
                ELSIF count = 2 THEN
                    IF written = '1' THEN
                        next_state <= RST;
                    ELSE
                        count_next <= count;
                        next_state <= WRITE_FIFO;
                    END IF;
                ELSE
                    next_state <= RST;
                END IF;

            WHEN RST =>
                IF signal_in = '0' or reset_reg = '1' THEN
                    IF reset_reg = '1' THEN
                        next_state <= IDLE;
                        signal_running_next <= '0';
                        reset_next <= '0';
                        count_next <= 0;
                    ELSIF reset_reg = '0' THEN
                        next_state <= RST;
                        reset_next <= '1';
                    END IF;
                ELSE 
                    next_state <= RST;
                END IF;
                wrt_next <= '0';

            WHEN OTHERS =>
                next_state <= IDLE;
        END CASE;
    END PROCESS;

    signal_running <= signal_running_reg;
    reset <= reset_reg;
    wrt <= wrt_reg;

END ARCHITECTURE fsm;


