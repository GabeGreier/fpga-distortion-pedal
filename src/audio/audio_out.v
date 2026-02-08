module audio_out(
    input               BCLK,        // bit clock
    input               LRCLK,       // left/right indicator
    input  signed [15:0] left,       // left sample
    input  signed [15:0] right,      // right sample
    output reg          DACDAT       // serial output to codec
);

    reg [15:0] shift_reg = 0;
    reg [4:0]  bit_index = 0;
    reg        lrclk_prev = 0; // Fixed: Track previous LRCLK state for reliable edge detection

    // Fixed: Detect LRCLK edges by comparing previous and current state
    // LRCLK rising edge = load left, falling edge = load right
    always @(posedge BCLK) begin
        lrclk_prev <= LRCLK;
        
        // Detect LRCLK rising edge (left channel)
        if (!lrclk_prev && LRCLK) begin
            bit_index <= 0;
            shift_reg <= left;
        end
        // Detect LRCLK falling edge (right channel)
        else if (lrclk_prev && !LRCLK) begin
            bit_index <= 0;
            shift_reg <= right;
        end
    end

    // Shift out MSB first on falling edge of BCLK
    always @(negedge BCLK) begin
        DACDAT <= shift_reg[15];
        shift_reg <= {shift_reg[14:0], 1'b0};
        bit_index <= bit_index + 1;
    end

endmodule
