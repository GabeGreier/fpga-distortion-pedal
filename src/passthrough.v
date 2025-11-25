module passthrough(
    input CLOCK_50,   // main FPGA clock, must be 50 MHz

    // I2S Audio Signals
    input  AUD_ADCLRCK, // ADC LR clock
    input  AUD_ADCDAT,  // ADC digital data
    input  AUD_BCLK,    // bit clock

    output AUD_DACLRCK, // DAC LR clock
    output AUD_DACDAT,  // DAC digital data
    output AUD_XCK,     // master clock to codec

    // I2C Control Signals
    output I2C_SCLK,    // codec config clock
    inout  I2C_SDAT     // codec config data (bidirectional)
);

    // internal audio sample wires
    wire signed [15:0] adc_left;
    wire signed [15:0] adc_right;
    wire signed [15:0] dac_left;
    wire signed [15:0] dac_right;

    // clean passthrough: ADC -> DAC
    assign dac_left  = adc_left;
    assign dac_right = adc_right;

    // instantiate audio interface
    audio_interface audio_inst (
        .CLOCK_50(CLOCK_50),

        .AUD_ADCLRCK(AUD_ADCLRCK),
        .AUD_ADCDAT(AUD_ADCDAT),
        .AUD_BCLK(AUD_BCLK),
        .AUD_DACLRCK(AUD_DACLRCK),
        .AUD_DACDAT(AUD_DACDAT),
        .AUD_XCK(AUD_XCK),

        .I2C_SCLK(I2C_SCLK),
        .I2C_SDAT(I2C_SDAT),

        .adc_left(adc_left),
        .adc_right(adc_right),
        .dac_left(dac_left),
        .dac_right(dac_right)
    );

endmodule
