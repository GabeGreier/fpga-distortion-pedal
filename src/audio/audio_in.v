module audio_in(
    input  BCLK,               // bit clock from codec
    input  LRCLK,              // left/right clock
    input  ADCDAT,             // serial ADC data
    output reg signed [15:0] left,
    output reg signed [15:0] right
);

    reg [15:0] shift_reg = 16'd0;
    reg [4:0]  bit_index = 5'd0;

    // Synchronize LRCLK into BCLK domain before edge detection.
    reg lrclk_meta = 1'b0;
    reg lrclk_sync = 1'b0;
    reg lrclk_prev = 1'b0;

    // Shift serial ADC data and capture full words at synchronized LRCLK edges.
    always @(posedge BCLK) begin
        lrclk_meta <= LRCLK;
        lrclk_sync <= lrclk_meta;
        lrclk_prev <= lrclk_sync;
        shift_reg  <= {shift_reg[14:0], ADCDAT};

        // Detect synchronized LRCLK rising edge (left channel)
        if (!lrclk_prev && lrclk_sync) begin
            left <= shift_reg;
            bit_index <= 5'd0;
        end
        // Detect synchronized LRCLK falling edge (right channel)
        else if (lrclk_prev && !lrclk_sync) begin
            right <= shift_reg;
            bit_index <= 5'd0;
        end
        else begin
            bit_index <= bit_index + 5'd1;
        end
    end

endmodule
