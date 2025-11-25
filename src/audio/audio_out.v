module audio_out(
    input               BCLK,        // bit clock
    input               LRCLK,       // left/right indicator
    input  signed [15:0] left,       // left sample
    input  signed [15:0] right,      // right sample
    output reg          DACDAT       // serial output to codec
);

    reg [15:0] shift_reg = 0;
    reg [4:0]  bit_index = 0;

    // Load left or right channel sample at start of LRCLK period
    always @(posedge LRCLK) begin
        bit_index <= 0;
        if (LRCLK == 0) 
            shift_reg <= left;
        else 
            shift_reg <= right;
    end

    // Shift out MSB first on falling edge of BCLK
    always @(negedge BCLK) begin
        DACDAT <= shift_reg[15];
        shift_reg <= {shift_reg[14:0], 1'b0};
        bit_index <= bit_index + 1;
    end

endmodule
