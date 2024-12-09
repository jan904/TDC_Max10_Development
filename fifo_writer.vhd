-- write data from 4 channels into fifo

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY fifo_writer IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        ch_valid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        ch_data : IN STD_LOGIC_VECTOR(39 DOWNTO 0);
        fifo_full : IN STD_LOGIC;
        fifo_wr : OUT STD_LOGIC;
        written_channels : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        fifo_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END ENTITY fifo_writer;

ARCHITECTURE rtl OF fifo_writer IS

    TYPE state_type IS (IDLE, WRITE_COARSE, RST);
    SIGNAL state, next_state : state_type;

    SIGNAL channel_next, channel_reg : INTEGER range 0 to 3;
    SIGNAL data_next, data_reg : STD_LOGIC_VECTOR(39 DOWNTO 0);
    SIGNAL fifo_data_reg, fifo_data_next : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL wr_next, wr_reg : STD_LOGIC;

    SIGNAL written_channels_next, written_channels_reg : STD_LOGIC_VECTOR(3 DOWNTO 0);

    SIGNAL count, count_next : INTEGER range 0 to 4;

BEGIN

    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            state <= IDLE;
            channel_reg <= 0;
            data_reg <= (OTHERS => '0');
            wr_reg <= '0';
            fifo_data_reg <= (OTHERS => '0');
            written_channels_reg <= (OTHERS => '0');
            count <= 0;
        ELSIF rising_edge(clk) THEN
            state <= next_state;
            channel_reg <= channel_next;
            data_reg <= data_next;
            wr_reg <= wr_next;
            fifo_data_reg <= fifo_data_next;
            written_channels_reg <= written_channels_next;
            count <= count_next;
        END IF;
    END PROCESS;

    PROCESS(state, ch_valid, ch_data, fifo_full, channel_reg, data_reg, wr_reg, fifo_data_reg, written_channels_reg, count)
    BEGIN

        next_state <= state;
        channel_next <= channel_reg;
        data_next <= data_reg;
        wr_next <= wr_reg;
        fifo_data_next <= fifo_data_reg;
        written_channels_next <= written_channels_reg;
        count_next <= count;

        CASE state IS
            WHEN IDLE =>
                wr_next <= '0';
                written_channels_next <= "0000";
                IF fifo_full = '0' THEN
                    IF ch_valid(0) = '1' THEN
                        next_state <= WRITE_COARSE;
                        data_next <= ch_data;
                    ELSE
                        channel_next <= 0;
                    END IF;
                ELSE
                    next_state <= IDLE;
                END IF;

            WHEN WRITE_COARSE =>
                IF fifo_full = '0' THEN
                    IF count = 0 THEN
                        fifo_data_next <= data_reg(7 DOWNTO 0);
                        wr_next <= '1';
                        count_next <= count + 1;
                        next_state <= WRITE_COARSE;
                    ELSIF count = 1 THEN
                        fifo_data_next <= data_reg(15 DOWNTO 8);
                        wr_next <= '1';
                        count_next <= count + 1;
                        next_state <= WRITE_COARSE;
                    ELSIF count = 2 THEN
                        fifo_data_next <= data_reg(23 DOWNTO 16);
                        wr_next <= '1';
                        count_next <= count + 1;
                        next_state <= WRITE_COARSE;
                    ELSIF count = 3 THEN
                        fifo_data_next <= data_reg(31 DOWNTO 24);
                        wr_next <= '1';
                        count_next <= count + 1;
                        next_state <= WRITE_COARSE;
                    ELSIF count = 4 THEN
                        fifo_data_next <= data_reg(39 DOWNTO 32);
                        wr_next <= '1';
                        count_next <= 0;
                        channel_next <= 0;
                        written_channels_next(0) <= '1';
                        next_state <= RST;
                    END IF;
                ELSE
                    wr_next <= '0';
                    next_state <= WRITE_COARSE;
                END IF;

            WHEN RST =>
                IF count = 4 THEN
                    next_state <= IDLE;
                    count_next <= 0;
                ELSE
                    count_next <= count + 1; 
                    next_state <= RST;
                END IF;
                wr_next <= '0';

            WHEN OTHERS =>
                next_state <= IDLE;

        END CASE;

    END PROCESS;

    fifo_wr <= wr_reg;
    fifo_data <= fifo_data_reg;
    written_channels <= written_channels_reg;

END ARCHITECTURE rtl;