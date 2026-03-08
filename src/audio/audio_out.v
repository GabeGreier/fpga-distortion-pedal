module audio_out(
    input                BCLK,        // bit clock
    input                LRCLK,       // left/right word-select clock
    input  signed [15:0] left,        // left sample
    input  signed [15:0] right,       // right sample
    output reg           DACDAT       // serial output to codec
);

    reg [15:0] shift_reg  = 16'd0;
    reg [4:0]  bit_count  = 5'd0;
    reg        lrclk_prev = 1'b0;

    // I2S transmit for 16-bit samples in (typical) 32-bit slots.
    // Drive first 16 bits from sample MSB->LSB, then zero-pad remaining slot bits.
    // Update on BCLK falling edge so codec can sample on rising edge.
    always @(negedge BCLK) begin
        lrclk_prev <= LRCLK;

        // Word boundary: LRCLK toggled, load sample for new channel.
        if (LRCLK != lrclk_prev) begin
            bit_count <= 5'd0;

            // Keep existing channel polarity used elsewhere in this project:
            // LRCLK=1 => left, LRCLK=0 => right.
            if (LRCLK)
                shift_reg <= left;
            else
                shift_reg <= right;

            // I2S timing: WS toggles one bit before MSB.
            // Keep output low in this boundary bit period.
            DACDAT <= 1'b0;
        end else if (bit_count < 5'd16) begin
            DACDAT    <= shift_reg[15];
            shift_reg <= {shift_reg[14:0], 1'b0};
            bit_count <= bit_count + 5'd1;
        end else begin
            DACDAT <= 1'b0;
        end
    end

endmodule
