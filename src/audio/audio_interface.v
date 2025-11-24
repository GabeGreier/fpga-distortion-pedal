module audio_interface(
    input CLOCK_50,

    // I2S interface
    input AUD_ADCLRCK,
    input AUD_ADCDAT,
    input AUD_BCLK,
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
