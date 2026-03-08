// ================================================
// FPGA Distortion block
// - Mode 00: clean passthrough (linear, with headroom trim)
// - Mode 01: light soft clip
// - Mode 10: normal clip
// - Mode 11: heavy clip
// ================================================

module distortion (
    input  wire signed [15:0] in_sample,
    input  wire [1:0]         mode,
    output reg  signed [15:0] out_sample
);

    function signed [31:0] abs32;
        input signed [31:0] x;
        begin
            if (x < 0)
                abs32 = -x;
            else
                abs32 = x;
        end
    endfunction

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

    // Keep digital headroom so line-level sources do not clip immediately.
    localparam integer INPUT_TRIM_SHIFT = 1; // 1 => /2

    reg signed [31:0] x_raw;
    reg signed [31:0] x;
    reg signed [31:0] x_gain;
    reg signed [31:0] y;
    reg signed [31:0] thr;
    reg signed [31:0] sgn;
    reg [31:0]        a;
    reg [31:0]        d;
    reg [31:0]        gate_thr;

    always @(*) begin
        x_raw    = {{16{in_sample[15]}}, in_sample};
        x        = x_raw >>> INPUT_TRIM_SHIFT;
        x_gain   = 32'sd0;
        y        = 32'sd0;
        thr      = 32'sd32767;
        sgn      = 32'sd1;
        a        = 32'd0;
        d        = 32'd0;
        gate_thr = 32'd0;

        // CLEAN: linear path only (no gate/no nonlinearity), just headroom trim.
        if (mode == 2'b00) begin
            out_sample = sat16(x);
        end else begin
            // Gate only on distorted modes to suppress idle hiss.
            case (mode)
                2'b01: gate_thr = 32'd256;
                2'b10: gate_thr = 32'd448;
                default: gate_thr = 32'd640;
            endcase

            if (abs32(x) < gate_thr) begin
                out_sample = 16'sd0;
            end else begin
                case (mode)
                    // LIGHT
                    2'b01: begin
                        x_gain = x <<< 1;
                        thr    = 32'sd22000;
                    end

                    // NORMAL
                    2'b10: begin
                        x_gain = x <<< 2;
                        thr    = 32'sd16000;
                    end

                    // HEAVY
                    default: begin
                        x_gain = x <<< 3;
                        thr    = 32'sd11000;
                    end
                endcase

                if (x_gain < 0)
                    sgn = -32'sd1;
                else
                    sgn = 32'sd1;

                a = abs32(x_gain);

                if (a <= thr[31:0]) begin
                    y = x_gain;
                end else if (a <= (thr <<< 1)) begin
                    d = a - thr[31:0];
                    y = sgn * (thr + (d >>> 2));
                end else begin
                    y = sgn * (thr + (thr >>> 2));
                end

                out_sample = sat16(y);
            end
        end
    end

endmodule
