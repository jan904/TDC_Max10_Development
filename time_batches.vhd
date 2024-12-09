LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY time_batches IS
    GENERIC (
        coarse_bits : INTEGER := 31
    );
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        wrt_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        written : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        coarse_in : IN STD_LOGIC_VECTOR(coarse_bits - 1 DOWNTO 0);
        coarse_out : OUT STD_LOGIC_VECTOR(coarse_bits - 1 DOWNTO 0)
    );
END ENTITY time_batches;

ARCHITECTURE rtl OF time_batches IS

    SIGNAL coarse_reg : STD_LOGIC_VECTOR(coarse_bits - 1 DOWNTO 0);
    SIGNAL coarse_next : STD_LOGIC_VECTOR(coarse_bits - 1 DOWNTO 0);

    TYPE stype IS (IDLE, WRT, RST);
    SIGNAL state, next_state : stype;

BEGIN

    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            state <= IDLE;
            coarse_reg <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            state <= next_state;
            coarse_reg <= coarse_next;
        END IF;
    END PROCESS;

    PROCESS(state, wrt_in, written, coarse_in)
    BEGIN

        next_state <= state;
        coarse_next <= coarse_reg;

        CASE state IS
            WHEN IDLE =>
                IF wrt_in(0) = '1' THEN
                    next_state <= WRT;
                    coarse_next <= coarse_in;
                ELSE
                    next_state <= IDLE;
                END IF;

            WHEN WRT =>
                coarse_next <= coarse_in;
                next_state <= RST;

            WHEN RST =>
                IF written(0) = '1' THEN
                    coarse_next <= (OTHERS => '0');
                    next_state <= IDLE;
                ELSE
                    next_state <= RST;
                END IF;
            
            WHEN OTHERS =>
                next_state <= IDLE;

        END CASE;

    END PROCESS;

    coarse_out <= coarse_reg;

END ARCHITECTURE rtl;