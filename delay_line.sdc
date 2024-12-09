create_clock -name CLK_25_MAX10 -period 40 [get_ports {clk25}]
derive_pll_clocks

derive_clock_uncertainty

set_false_path -from [get_ports {signal_in}]
set_false_path -from * -to [get_ports {signal_out*}]