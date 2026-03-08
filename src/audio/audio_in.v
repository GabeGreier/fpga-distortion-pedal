module audio_in(
    input  BCLK,               // bit clock from codec
    input  LRCLK,              // left/right word-select clock
    input  ADCDAT,             // serial ADC data
    output reg signed [15:0] left,
    output reg signed [15:0] right
);

    reg [15:0] shift_reg = 16'd0;
    reg [4:0]  bit_count = 5'd0;
    reg        lrclk_prev = 1'b0;

    // I2S receive for 16-bit samples in (typical) 32-bit slots.
    // Capture only first 16 bits of each LRCLK half-frame; ignore padding bits.
    always @(posedge BCLK) begin
        lrclk_prev <= LRCLK;

        // Word boundary: LRCLK toggled, start bit counter for new channel word.
        if (LRCLK != lrclk_prev) begin
            bit_count <= 5'd0;
        end else if (bit_count < 5'd16) begin
            shift_reg <= {shift_reg[14:0], ADCDAT};

            if (bit_count == 5'd15) begin
                // Keep existing channel polarity used elsewhere in this project:
                // LRCLK=1 => left, LRCLK=0 => right.
                if (LRCLK)
                    left  <= {shift_reg[14:0], ADCDAT};
                else
                    right <= {shift_reg[14:0], ADCDAT};
            end

            bit_count <= bit_count + 5'd1;
        end
    end

endmodule
