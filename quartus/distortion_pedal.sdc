create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]

# External audio clocks from WM8731.
create_clock -name AUD_BCLK    -period 325.521 [get_ports {AUD_BCLK}]
create_clock -name AUD_ADCLRCK -period 20833.333 [get_ports {AUD_ADCLRCK}]

# Treat all unrelated clock domains as asynchronous for timing closure.
set_clock_groups -asynchronous     -group {CLOCK_50}     -group {AUD_BCLK}     -group {AUD_ADCLRCK}

# LRCLK and BCLK are both sourced by WM8731 and treated as related clocks.
# No explicit false-path to removed synchronization registers.

derive_pll_clocks
derive_clock_uncertainty
