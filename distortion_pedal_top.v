module distortion_pedal_top(
    input  wire        CLOCK_50,
    input  wire [1:0]  SW,

    // I2S Audio Signals
    input  wire        AUD_ADCLRCK,
    input  wire        AUD_ADCDAT,
    input  wire        AUD_BCLK,

    output wire        AUD_DACLRCK,
    output wire        AUD_DACDAT,
    output wire        AUD_XCK,

    // I2C Control Signals
    output wire        I2C_SCLK,
    inout  wire        I2C_SDAT,

    // LCD
    output wire [7:0]  LCD_DATA,
    output wire        LCD_EN,
    output wire        LCD_RS,
    output wire        LCD_RW,
    output wire        LCD_ON,
    output wire        LCD_BLON
);

    // Power-on reset so LCD + codec init starts clean
    reg [19:0] por_cnt = 20'd0;
    reg        reset_n = 1'b0;

    always @(posedge CLOCK_50) begin
        if (!reset_n) begin
            por_cnt <= por_cnt + 1'b1;
            if (por_cnt == 20'hFFFFF)
                reset_n <= 1'b1;
        end
    end

    // Audio sample buses
    wire signed [15:0] adc_left, adc_right;
    wire signed [15:0] dac_left, dac_right;

    // Use raw switches for UI mode so LCD always reflects physical switch state.
    wire [1:0] mode_sys = SW;

    // Synchronize mode into codec LRCLK domain for audio DSP use.
    reg [1:0] mode_lr_ff1, mode_lr_ff2;
    always @(posedge AUD_ADCLRCK) begin
        mode_lr_ff1 <= mode_sys;
        mode_lr_ff2 <= mode_lr_ff1;
    end

    // Extra sync stage for LCD path.
    reg [1:0] mode_ff1, mode_ff2;
    always @(posedge CLOCK_50) begin
        mode_ff1 <= mode_sys;
        mode_ff2 <= mode_ff1;
    end

    // Distortion DSP (stereo)
    distortion u_dist_L (
        .in_sample(adc_left),
        .mode(mode_lr_ff2),
        .out_sample(dac_left)
    );

    distortion u_dist_R (
        .in_sample(adc_right),
        .mode(mode_lr_ff2),
        .out_sample(dac_right)
    );

    // LCD UI
    lcd_hd44780 u_lcd (
        .clk(CLOCK_50),
        .reset_n(reset_n),
        .mode(mode_ff2),
        .LCD_DATA(LCD_DATA),
        .LCD_EN(LCD_EN),
        .LCD_RS(LCD_RS),
        .LCD_RW(LCD_RW),
        .LCD_ON(LCD_ON),
        .LCD_BLON(LCD_BLON)
    );

    // Audio interface (codec config + I2S in/out)
    audio_interface audio_inst (
        .CLOCK_50(CLOCK_50),
        .reset(!reset_n),

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
