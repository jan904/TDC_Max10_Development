LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY conc_output IS
    GENERIC (
        coarse_bits : INTEGER := 8
    );
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        we : IN STD_LOGIC;
        fine_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        coarse_in : IN STD_LOGIC_VECTOR(coarse_bits-1 DOWNTO 0);
        we_out : OUT STD_LOGIC; 
        data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END ENTITY conc_output;

ARCHITECTURE rtl OF conc_output IS

    TYPE stype IS (IDLE, WRITE_FINE, WRITE_COARSE);
    SIGNAL state, next_state : stype;

    SIGNAL fine_reg : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL coarse_reg : STD_LOGIC_VECTOR(coarse_bits-1 DOWNTO 0);
    SIGNAL we_reg, we_next : STD_LOGIC;
    SIGNAL data_out_reg : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL count, count_next : INTEGER range 0 to (coarse_bits/8 - 1);

BEGIN

    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst = '1' THEN
                state <= IDLE;
                we_reg <= '0';
                count <= 0;
            ELSE
                state <= next_state;
                we_reg <= we_next;
                count <= count_next;
            END IF;
        END IF;
    END PROCESS;

    PROCESS (state, fine_reg, coarse_reg, we_reg, fine_in, coarse_in, count, we)
    BEGIN

        next_state <= state;
        we_next <= we_reg;
        count_next <= count;

        CASE state IS
            WHEN IDLE =>
                fine_reg <= fine_in;
                coarse_reg <= coarse_in;
                we_next <= '0';
                IF we = '1' THEN
                    next_state <= WRITE_FINE;
                ELSE
                    next_state <= IDLE;
                END IF;
            
            WHEN WRITE_FINE =>
                we_next <= '1';
                data_out_reg <= fine_reg;
                next_state <= WRITE_COARSE;

            WHEN WRITE_COARSE =>
                we_next <= '1';
                IF count = (coarse_bits/8 - 1) THEN
                    count_next <= 0;
                    next_state <= IDLE;
                ELSE
                    count_next <= count + 1;
                    data_out_reg <= coarse_reg(count*8+7 downto count*8);
                    next_state <= WRITE_COARSE;
                END IF;

        END CASE;
    END PROCESS;

    we_out <= we_reg;
    data_out <= data_out_reg;

END ARCHITECTURE rtl;
                
                
                