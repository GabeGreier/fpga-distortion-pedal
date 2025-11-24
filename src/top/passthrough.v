module passthrough(
    input  CLOCK_50,   // main FPGA clock, must be 50 MHz

    // Audio codec interface pins
    input  AUD_BCLK,   // bit clock from WM8731
    input  AUD_LRCLK,  // left/right sample clock
    input  AUD_ADCDAT, // audio data from codec (ADC)

    output AUD_DACDAT, // audio data to codec (DAC)
    output AUD_XCK     // master clock to codec
);
