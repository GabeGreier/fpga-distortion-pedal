module audio_out(
    input                BCLK,        // bit clock
    input                LRCLK,       // left/right indicator
    input  signed [15:0] left,        // left sample
    input  signed [15:0] right,       // right sample
    output reg           DACDAT       // serial output to codec
);

    reg [15:0] shift_reg = 16'd0;
    reg [4:0]  bit_index = 5'd0;

    // Synchronize LRCLK into BCLK domain before edge detection.
    reg lrclk_meta = 1'b0;
    reg lrclk_sync = 1'b0;
    reg lrclk_prev = 1'b0;

    // Update data on BCLK falling edge so DAC sees stable value on rising edge.
    always @(negedge BCLK) begin
        lrclk_meta <= LRCLK;
        lrclk_sync <= lrclk_meta;
        lrclk_prev <= lrclk_sync;

        // Detect synchronized LRCLK rising edge (left channel)
        if (!lrclk_prev && lrclk_sync) begin
            shift_reg <= left;
            bit_index <= 5'd0;
            DACDAT    <= left[15];
        end
        // Detect synchronized LRCLK falling edge (right channel)
        else if (lrclk_prev && !lrclk_sync) begin
            shift_reg <= right;
            bit_index <= 5'd0;
            DACDAT    <= right[15];
        end
        // Shift out MSB first between channel boundaries.
        else begin
            DACDAT    <= shift_reg[15];
            shift_reg <= {shift_reg[14:0], 1'b0};
            bit_index <= bit_index + 5'd1;
        end
    end

endmodule
