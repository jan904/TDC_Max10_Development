-- Thermometer to binary encoder
--
-- Inputs:
--   thermometer: Thermometer code to be encoded
--   clk : Clock signal
--
-- Outputs:
--   count_bin: Binary encoded thermometer code   

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY encoder IS
    GENERIC (
        n_bits_bin : POSITIVE;
        n_bits_therm : POSITIVE
    );
    PORT (
        clk : IN STD_LOGIC;
        thermometer : IN STD_LOGIC_VECTOR((n_bits_therm - 1) DOWNTO 0);
        count_bin : OUT STD_LOGIC_VECTOR((n_bits_bin - 1) DOWNTO 0)
    );
END ENTITY encoder;


ARCHITECTURE rtl OF encoder IS
BEGIN

    PROCESS (clk)
        -- Variable to store the count
       VARIABLE count : unsigned(n_bits_bin - 1 DOWNTO 0); --:= (OTHERS => '0');
    BEGIN
        -- Simply loop over the thermometer code and count the number of '1's
        IF rising_edge(clk) THEN
            -- Reset the count after each clock cycle
            count := (OTHERS => '0');
            FOR i IN 0 TO n_bits_therm - 1 LOOP
                IF thermometer(i) = '1' THEN
                    count := count + 1;
                END IF;
            END LOOP;
            -- Assign the count to the output
            count_bin <= STD_LOGIC_VECTOR(count);
        END IF;
    END PROCESS;

END ARCHITECTURE rtl;


