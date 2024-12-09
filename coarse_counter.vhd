LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY coarse_counter IS
    GENERIC (
        coarse_bits : INTEGER := 8
    );
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        count : OUT STD_LOGIC_VECTOR(coarse_bits - 1 DOWNTO 0)
    );
END ENTITY coarse_counter;

ARCHITECTURE rtl OF coarse_counter IS

    SIGNAL counter : UNSIGNED(coarse_bits - 1 DOWNTO 0);

BEGIN

    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            counter <= (OTHERS => '0');
        ELSIF clk'EVENT AND clk = '1' THEN
            IF counter = 2 ** coarse_bits - 1 THEN
                counter <= (OTHERS => '0');
            ELSE
                counter <= counter + 1;
            END IF;
        END IF;
    END PROCESS;

    count <= STD_LOGIC_VECTOR(counter);

END ARCHITECTURE rtl;