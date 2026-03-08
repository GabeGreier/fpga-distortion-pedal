// ================================================
// FPGA Distortion block
// - Mode 00: clean passthrough with light noise gate
// - Mode 01: light soft clip
// - Mode 10: normal clip
// - Mode 11: heavy clip
// ================================================

module distortion (
    input  wire signed [15:0] in_sample,
    input  wire [1:0]         mode,
    output reg  signed [15:0] out_sample
);

    // |x| helper
    function signed [31:0] abs32;
        input signed [31:0] x;
        begin
            if (x < 0)
                abs32 = -x;
            else
                abs32 = x;
        end
    endfunction

    // Saturate 32-bit signed to 16-bit signed
    function signed [15:0] sat16;
        input signed [31:0] x;
        begin
            if (x > 32'sd32767)
                sat16 = 16'sd32767;
            else if (x < -32'sd32768)
                sat16 = 16'sh8000;
            else
                sat16 = x[15:0];
        end
    endfunction

    // Processing temps
    reg signed [31:0] x;          // widened input
    reg signed [31:0] x_gain;     // pre-gain sample
    reg signed [31:0] y;          // shaped sample
    reg signed [31:0] thr;        // clip threshold
    reg signed [31:0] sgn;
    reg [31:0]        a;
    reg [31:0]        d;

    localparam signed [31:0] NOISE_GATE = 32'sd96;

    always @(*) begin
        x      = {{16{in_sample[15]}}, in_sample};
        x_gain = 32'sd0;
        y      = 32'sd0;
        thr    = 32'sd32767;
        sgn    = 32'sd1;
        a      = 32'd0;
        d      = 32'd0;

        // Small noise gate to suppress idle hiss/static floor.
        if (abs32(x) < NOISE_GATE) begin
            out_sample = 16'sd0;
        end else begin

            case (mode)
                // CLEAN
                2'b00: begin
                    x_gain = x;
                    thr    = 32'sd32767;
                end

                // LIGHT: ~2x pre-gain, gentle soft clip
                2'b01: begin
                    x_gain = x <<< 1;
                    thr    = 32'sd18000;
                end

                // NORMAL: ~4x pre-gain, medium clip
                2'b10: begin
                    x_gain = x <<< 2;
                    thr    = 32'sd12000;
                end

                // HEAVY: ~8x pre-gain, aggressive clip
                default: begin
                    x_gain = x <<< 3;
                    thr    = 32'sd7000;
                end
            endcase

            if (x_gain < 0)
                sgn = -32'sd1;
            else
                sgn = 32'sd1;

            a = abs32(x_gain);

            if (mode == 2'b00) begin
                y = x_gain;
            end else if (a <= thr[31:0]) begin
                // Region 1: linear
                y = x_gain;
            end else if (a <= (thr <<< 1)) begin
                // Region 2: soft compression
                d = a - thr[31:0];
                y = sgn * (thr + (d >>> 2));
            end else begin
                // Region 3: near hard-limit
                y = sgn * (thr + (thr >>> 2));
            end

            out_sample = sat16(y);
        end
    end

endmodule
