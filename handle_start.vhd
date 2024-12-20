-- Handle start after starting the fpga
--
-- This module is used to send a signal for one clock cycle after the FPGA has
-- been started. This signal is used to initialize several modules.
-- Implemented using a state machine with two states: reset_state and
-- running_state. 
--
-- Inputs:
--   clk: clock signal
--
-- Outputs:
--   starting: signal that is high for one clock cycle after the FPGA has been started
 
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY handle_start IS
    PORT (
        clk : IN STD_LOGIC;
        pll_locked : IN STD_LOGIC;
        reset_outside : IN STD_LOGIC;
        restart_outside : IN STD_LOGIC;
        starting : OUT STD_LOGIC;
        sending : OUT STD_LOGIC
    );
END ENTITY handle_start;


ARCHITECTURE fsm_arch OF handle_start IS

    -- Define the states of the state machine
    TYPE state_type IS (reset_state, starting_state, running_state, waiting_state);
    SIGNAL current_state, next_state : state_type;

    -- Output signal updated by the state machine
    SIGNAL starting_reg, starting_next : STD_LOGIC;
    SIGNAL sending_reg, sending_next : STD_LOGIC;

BEGIN

    -- fsm core
    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            current_state <= next_state;
            starting_reg <= starting_next;
            sending_reg <= sending_next;
        END IF;
    END PROCESS;

    -- fsm logic
    PROCESS (next_state, starting_reg, current_state, pll_locked, sending_reg, reset_outside, restart_outside)
    BEGIN
        -- Go to reset_state after starting. Stay in reset_state for one cycle
        -- and send starting signal. Then go to running_state and stay there sending no signal.

        starting_next <= starting_reg;
        sending_next <= sending_reg;

        CASE current_state IS
            WHEN reset_state =>
                IF pll_locked = '1' THEN
                    starting_next <= '1';
                    next_state <= starting_state;
                ELSE
                    starting_next <= '0';
                    next_state <= reset_state;
                END IF;

            WHEN starting_state =>
                starting_next <= '0';
                sending_next <= '1';
                next_state <= running_state;

            WHEN running_state =>
                sending_next <= '0';
                IF reset_outside = '1' THEN
                    next_state <= waiting_state;
                ELSE
                    next_state <= running_state;
                END IF; 

            WHEN waiting_state =>
                IF restart_outside = '1' THEN
                    next_state <= reset_state;
                    starting_next <= '1';
                    sending_next <= '0';
                ELSE
                    next_state <= waiting_state;
                    starting_next <= '1';
                    sending_next <= '1';
                END IF;

            WHEN OTHERS =>
                next_state <= reset_state;

        END CASE;
    END PROCESS;

    starting <= starting_reg;
    sending <= sending_reg or starting_reg;

END ARCHITECTURE fsm_arch;