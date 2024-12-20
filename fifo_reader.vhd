LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY fifo_reader IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        fifo_empty : IN STD_LOGIC;
        fifo_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        fifo_rd : OUT STD_LOGIC;
        data_valid : OUT STD_LOGIC;
        data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END ENTITY fifo_reader;

ARCHITECTURE rtl OF fifo_reader IS

    TYPE state_type IS (IDLE, READ_DATA);
    SIGNAL state, next_state : state_type;

    SIGNAL rd_next, rd_reg : STD_LOGIC;
    SIGNAL data_out_next, data_out_reg : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL data_valid_next, data_valid_reg : STD_LOGIC;

BEGIN

    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            state <= IDLE;
            rd_reg <= '0';
            data_valid_reg <= '0';
            data_out_reg <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            state <= next_state;
            rd_reg <= rd_next;
            data_valid_reg <= data_valid_next;
            data_out_reg <= data_out_next;
        END IF;
    END PROCESS;

    PROCESS(state, fifo_empty, fifo_data, rd_reg, data_out_reg, data_valid_reg)
    BEGIN

        next_state <= state;
        rd_next <= rd_reg;
        data_valid_next <= data_valid_reg;
        data_out_next <= data_out_reg;

        CASE state IS
            WHEN IDLE =>
                data_valid_next <= '0';
                IF fifo_empty = '0' THEN  
                    rd_next <= '1';
                    next_state <= READ_DATA;
                ELSE
                    next_state <= IDLE;
                END IF;

            WHEN READ_DATA =>
                rd_next <= '0';
                data_valid_next <= '1';
                data_out_next <= fifo_data;
                next_state <= IDLE;

            WHEN OTHERS =>
                rd_next <= '0';
                next_state <= IDLE;
        END CASE;

    END PROCESS;

    fifo_rd <= rd_reg;
    data_out <= data_out_reg;
    data_valid <= data_valid_reg;

END ARCHITECTURE rtl;
        
            