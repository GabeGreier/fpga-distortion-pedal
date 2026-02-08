module audio_in(
    input  BCLK,               // bit clock from codec
    input  LRCLK,              // left/right clock
    input  ADCDAT,             // serial ADC data
    output reg signed [15:0] left,
    output reg signed [15:0] right
);

    reg [15:0] shift_reg = 0;
    reg [4:0]  bit_index = 0;
    reg        lrclk_prev = 0; // Fixed: Track previous LRCLK state for reliable edge detection

    // Shift incoming serial data on rising edge of BCLK
    always @(posedge BCLK) begin
        shift_reg <= {shift_reg[14:0], ADCDAT};
        bit_index <= bit_index + 1;
    end

    // Fixed: Detect LRCLK edges by comparing previous and current state
    // LRCLK rising edge = left channel, falling edge = right channel
    always @(posedge BCLK) begin
        lrclk_prev <= LRCLK;
        
        // Detect LRCLK rising edge (left channel)
        if (!lrclk_prev && LRCLK) begin
            left <= shift_reg;
            bit_index <= 0;
        end
        // Detect LRCLK falling edge (right channel)
        else if (lrclk_prev && !LRCLK) begin
            right <= shift_reg;
            bit_index <= 0;
        end
    end

endmodule
