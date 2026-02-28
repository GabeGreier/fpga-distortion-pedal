module audio_in(
    input  BCLK,               // bit clock from codec
    input  LRCLK,              // left/right clock
    input  ADCDAT,             // serial ADC data
    output reg signed [15:0] left,
    output reg signed [15:0] right
);

    reg [15:0] shift_reg = 16'd0;
    reg [4:0]  bit_index = 5'd0;
    reg        lrclk_prev = 1'b0;

    // Single process avoids multiple procedural drivers on bit_index.
    // Shift serial ADC data and capture full words at LRCLK boundaries.
    always @(posedge BCLK) begin
        lrclk_prev <= LRCLK;
        shift_reg  <= {shift_reg[14:0], ADCDAT};

        // Detect LRCLK rising edge (left channel)
        if (!lrclk_prev && LRCLK) begin
            left <= shift_reg;
            bit_index <= 5'd0;
        end
        // Detect LRCLK falling edge (right channel)
        else if (lrclk_prev && !LRCLK) begin
            right <= shift_reg;
            bit_index <= 5'd0;
        end
        else begin
            bit_index <= bit_index + 5'd1;
        end
    end

endmodule
