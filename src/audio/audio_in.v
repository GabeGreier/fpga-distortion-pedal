module audio_in(
    input  BCLK,               // bit clock from codec
    input  LRCLK,              // left/right clock
    input  ADCDAT,             // serial ADC data
    output reg signed [15:0] left,
    output reg signed [15:0] right
);

    reg [15:0] shift_reg = 0;
    reg [4:0]  bit_index = 0;
    reg        current_channel = 0; // 0 = left, 1 = right

    // Shift incoming serial data on rising edge of BCLK
    always @(posedge BCLK) begin
        shift_reg <= {shift_reg[14:0], ADCDAT};
        bit_index <= bit_index + 1;
    end

    // LRCLK toggles at start of each channel
    always @(posedge LRCLK) begin
        // LRCLK = 0 → left channel, LRCLK = 1 → right channel
        current_channel <= LRCLK;
        bit_index <= 0;

        if (LRCLK == 0)
            left <= shift_reg;      // capture left
        else
            right <= shift_reg;     // capture right
    end

endmodule
