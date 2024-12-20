LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY top IS
    GENERIC (
        carry4_count : INTEGER := 72;
        n_output_bits : INTEGER := 9;
        coarse_bits : INTEGER := 31
    );
    PORT (
        clk25 : IN STD_LOGIC;
        signal_in : IN STD_LOGIC;
        reset_outside : IN STD_LOGIC;
        restart_outside : IN STD_LOGIC;
        signal_out : OUT STD_LOGIC_VECTOR(n_output_bits - 1 DOWNTO 0);
        serial_out : OUT STD_LOGIC;
        wrt_out : OUT STD_LOGIC
    );
END ENTITY top;

ARCHITECTURE rtl of top IS

    SIGNAL clk : STD_LOGIC;
    SIGNAL pll_locked : STD_LOGIC;

    SIGNAL reset_after_start : STD_LOGIC;
    SIGNAL sending_after_start : STD_LOGIC;

    SIGNAL coarse_count : STD_LOGIC_VECTOR(coarse_bits - 1 DOWNTO 0);
    SIGNAL coarse_set : STD_LOGIC_VECTOR(coarse_bits - 1 DOWNTO 0);

    SIGNAL signal_out_1 : STD_LOGIC_VECTOR(n_output_bits - 1 DOWNTO 0);
    SIGNAL channels_wr_en : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL channels_written : STD_LOGIC_VECTOR(3 DOWNTO 0);

    SIGNAL fifo_wr : STD_LOGIC;
    SIGNAL fifo_rd : STD_LOGIC;
    SIGNAL fifo_full : STD_LOGIC;
    SIGNAL fifo_empty : STD_LOGIC;
    SIGNAL w_fifo_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL r_fifo_data : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL uart_data_valid : STD_LOGIC;
    SIGNAL data_to_uart : STD_LOGIC_VECTOR(7 DOWNTO 0);

    COMPONENT pll IS
        PORT (
            inclk0 : IN STD_LOGIC;
            c0 : OUT STD_LOGIC;
            locked : OUT STD_LOGIC
        );
    END COMPONENT pll;

    COMPONENT channel IS
        GENERIC (
            carry4_count : INTEGER := 72;
            n_output_bits : INTEGER := 9
        );
        PORT (
            clk : IN STD_LOGIC;
            signal_in : IN STD_LOGIC;
            start_reset : IN STD_LOGIC;
            channel_written : IN STD_LOGIC;
            signal_out : OUT STD_LOGIC_VECTOR(n_output_bits - 1 DOWNTO 0);
            wr_en_out : OUT STD_LOGIC
        );
    END COMPONENT channel;

    COMPONENT handle_start IS
        PORT (
            clk : IN STD_LOGIC;
            pll_locked : IN STD_LOGIC;
            reset_outside : IN STD_LOGIC;
            restart_outside : IN STD_LOGIC;
            starting : OUT STD_LOGIC;
            sending : OUT STD_LOGIC
        );
    END COMPONENT handle_start;

    COMPONENT coarse_counter IS
        GENERIC (
            coarse_bits : INTEGER := 8
        );
        PORT (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            count : OUT STD_LOGIC_VECTOR(coarse_bits - 1 DOWNTO 0)
        );
    END COMPONENT coarse_counter;

    COMPONENT time_batches IS
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
    END COMPONENT time_batches;

    COMPONENT fifo_writer IS
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
    END COMPONENT fifo_writer;

    COMPONENT fifo IS
        GENERIC (
            abits : INTEGER := 4;
            dbits : INTEGER := 8
        );
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            rd : IN STD_LOGIC;
            wr : IN STD_LOGIC;
            w_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            r_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            full : OUT STD_LOGIC;
            empty : OUT STD_LOGIC
        );
    END COMPONENT fifo;

    COMPONENT dual_fifo IS
        PORT (
            aclr : IN STD_LOGIC;
            data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            rdclk : IN STD_LOGIC;
            rdreq : IN STD_LOGIC;
            wrclk : IN STD_LOGIC;
            wrreq : IN STD_LOGIC;
            q : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            rdempty : OUT STD_LOGIC;
            wrfull : OUT STD_LOGIC
        );
    END COMPONENT dual_fifo;

    COMPONENT fifo_reader IS
        PORT (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            fifo_empty : IN STD_LOGIC;
            fifo_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            fifo_rd : OUT STD_LOGIC;
            data_valid : OUT STD_LOGIC;
            data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT fifo_reader;

    COMPONENT uart IS
        GENERIC (
            mhz : INTEGER := 12
        );
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            we : IN STD_LOGIC;
            din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            tx : OUT STD_LOGIC
        );
    END COMPONENT uart;



BEGIN

    pll_inst : pll
    PORT MAP (
        inclk0 => clk25,
        c0 => clk,
        locked => pll_locked
    );

    handle_start_inst : handle_start
    PORT MAP (
        clk => clk,
        pll_locked => pll_locked,
        reset_outside => not reset_outside,
        restart_outside => not restart_outside,
        starting => reset_after_start,
        sending => sending_after_start
    );

    coarse_counter_inst : coarse_counter
    GENERIC MAP (
        coarse_bits => coarse_bits
    )
    PORT MAP (
        clk => clk,
        reset => reset_after_start,
        count => coarse_count
    );

    channel_inst_1 : channel
    GENERIC MAP (
        carry4_count => carry4_count,
        n_output_bits => n_output_bits
    )
    PORT MAP (
        clk => clk,
        signal_in => signal_in,
        start_reset => reset_after_start,
        channel_written => channels_written(0),
        signal_out => signal_out_1,
        wr_en_out => channels_wr_en(0)
    );

    signal_out <= signal_out_1;

    fifo_writer_inst : fifo_writer
    PORT MAP (
        clk => clk,
        reset => reset_after_start,
        ch_valid => channels_wr_en,
        ch_data => coarse_count & signal_out_1,
        fifo_full => fifo_full,
        fifo_wr => fifo_wr,
        written_channels => channels_written,
        fifo_data => w_fifo_data
    );

    wrt_out <= channels_wr_en(0);

    fifo_inst_1 : fifo
    PORT MAP (
        clk => clk,
        rst => reset_after_start,
        rd => fifo_rd,
        wr => fifo_wr,
        w_data => w_fifo_data,
        r_data => r_fifo_data,
        full => fifo_full,
        empty => fifo_empty
    ); 

    fifo_reader_inst : fifo_reader
    PORT MAP (
        clk => clk,
        reset => sending_after_start,
        fifo_empty => fifo_empty,
        fifo_data => r_fifo_data,
        fifo_rd => fifo_rd,
        data_valid => uart_data_valid,
        data_out => data_to_uart
    );

    uart_inst : uart
    GENERIC MAP (
        mhz => 12
    )
    PORT MAP (
        clk => clk,
        rst => sending_after_start,
        we => uart_data_valid,
        din => data_to_uart,
        tx => serial_out
    );

END rtl;