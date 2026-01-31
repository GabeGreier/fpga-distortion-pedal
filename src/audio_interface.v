module audio_interface(
    input CLOCK_50,  // main FPGA clock, must be 50 MHz

    // I2S interface
    input  AUD_ADCLRCK,
    input  AUD_ADCDAT,
    input  AUD_BCLK,
    output AUD_DACLRCK,
    output AUD_DACDAT,
    output AUD_XCK,

    // I2C interface
    output I2C_SCLK,
    inout  I2C_SDAT,

    // Clean sample buses to passthrough
    output signed [15:0] adc_left,
    output signed [15:0] adc_right,
    input  signed [15:0] dac_left,
    input  signed [15:0] dac_right
);

    // PLL: generate AUD_XCK from 50 MHz
    pll_audio pll_inst (
        .inclk0(CLOCK_50),
        .c0(AUD_XCK)
    );

    // Configure WM8731 at startup
    wm8731_config codec_config (
        .clock(CLOCK_50),
        .reset(1'b0),

        .I2C_SCLK(I2C_SCLK),
        .I2C_SDAT(I2C_SDAT)
    );

    // I2S receiver: ADC -> 16-bit samples
    audio_in adc_interface (
        .BCLK(AUD_BCLK),
        .LRCLK(AUD_ADCLRCK),
        .ADCDAT(AUD_ADCDAT),
        .left(adc_left),
        .right(adc_right)
    );

    // I2S transmitter: 16-bit samples -> DAC
    audio_out dac_interface (
        .BCLK(AUD_BCLK),
        .LRCLK(AUD_DACLRCK),
        .left(dac_left),
        .right(dac_right),
        .DACDAT(AUD_DACDAT)
    );

    // For now: pass ADC LR clock directly to DAC LR clock
    assign AUD_DACLRCK = AUD_ADCLRCK;

endmodule
