module passthrough(
    input  CLOCK_50,   // main FPGA clock, must be 50 MHz

    // I2S Audio Signals
    input          AUD_ADCLRCK, // ADC LR clock
    input          AUD_ADCDAT,  // ADC digital data
    input          AUD_BCLK,    // bit clock

    output         AUD_DACLRCK, // DAC LR clock
    output         AUD_DACDAT,  // DAC digital data
    output         AUD_XCK,     // master clock to codec

    // I2C Control Signals
    output         I2C_SCLK,    // codec config clock
    inout          I2C_SDAT     // codec config data (bidirectional)
);
