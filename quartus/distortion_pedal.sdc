create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]

# External audio clocks from WM8731 are asynchronous to CLOCK_50.
# Constrain them explicitly and cut cross-domain timing between unrelated domains.
create_clock -name AUD_BCLK    -period 325.521 [get_ports {AUD_BCLK}]
create_clock -name AUD_ADCLRCK -period 20833.333 [get_ports {AUD_ADCLRCK}]

set_clock_groups -asynchronous \
    -group {CLOCK_50} \
    -group {AUD_BCLK AUD_ADCLRCK}

derive_pll_clocks
derive_clock_uncertainty
