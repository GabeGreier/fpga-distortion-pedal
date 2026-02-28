// ================================================
// FPGA Distortion Pedal Top Module
// Board: Terrasic DE2-115
//
// Purpose:
// - Pull in stereo audio samples from the WM8731 codec
// - Select a mode using SW[1:0] (00 clean, 01 light, 10 normnal, 11 heavy)
// - Apply distortion effect using a piecewise non linear, to both left/right samples
// - Display project name + current mode on the LCD
//
// ================================================

module distortion (
    input wire signed [15:0] in_sample,
    input wire [1:0] mode,
    output reg signed [15:0] out_sample
);

    // Fixed: abs32 function input should be 32-bit signed, not 16-bit
    function signed [31:0] abs32;
        input signed [31:0] x;
        begin
            if (x < 0)
                abs32 = -x;
            else
                abs32 = x;
        end
    endfunction

    // Helper function: saturate signed 32 bit to signed 16 bit
    function signed [15:0] sat16;
        input signed [31:0] x;
        begin
            if (x > 32'sd32767)
                sat16 = 16'sd32767;
            else if (x < -32'sd32768)
                sat16 = -16'sd32768;
            else
                sat16 = x[15:0];
        end
    endfunction

    // Internal reg for intermediate values
    reg signed [31:0] x_pre;     // pre-gain sample (wide)
    reg signed [31:0] y_shape;   // after piecewise shaping (wide)

    reg [31:0]        a;         // abs(x_pre)
    reg signed [31:0] sgn;       // +1 or -1 as 32-bit signed
    reg signed [31:0] thr;       // threshold T (positive)
    reg signed [31:0] two_thr;   // 2T

    // Region math temps
    reg [31:0] delta;

    always @(*) begin

        x_pre = 32'sd0;
        y_shape = 32'sd0;
        a = 32'd0;
        sgn       = 32'sd1;
        thr       = 32'sd20000;
        two_thr   = 32'sd40000;
        delta     = 32'd0;
        

        // Pre gain
        case (mode)
            2'b00: begin
                x_pre = {{16{in_sample[15]}}, in_sample}; // sign-extend to 32-bit
                thr   = 32'sd32767; // no clipping
            end
            2'b01: begin
                // Fixed: Use << (not <<<) for logical shift, sign-extend result
                // 2x gain light clipping
                x_pre = {{15{in_sample[15]}}, in_sample, 1'b0}; // *2
                thr   = 32'sd20000;
            end
            2'b10: begin
                // Fixed: Use << (not <<<) for logical shift, sign-extend result
                // 4x gain more clipping
                x_pre = {{14{in_sample[15]}}, in_sample, 2'b00}; // *4
                thr   = 32'sd16000;
            end
            2'b11: begin
                // Fixed: Use << (not <<<) for logical shift, sign-extend result
                // 8x gain aggressive clipping
                x_pre = {{13{in_sample[15]}}, in_sample, 3'b000}; // *8
                thr   = 32'sd12000;
            end
        endcase

    // Prep sign and magnitude
    if (x_pre < 0) sgn = -32'sd1;
    else sgn = 32'sd1;
    a = abs32(x_pre);
    two_thr = thr << 1; // Fixed: Use << (not <<<) for shift operation. 2 * T

    // Piecewise soft clipping
    // Region 1: |x| <= T
    // Region 2: T < |x| <= 2T
    // Region 3: |x| > 2T

    if (mode == 2'b00) begin
        // clean, bypass
        y_shape = x_pre;
    end
    else if (a <= thr[31:0]) begin
        // Region 1 linear
        y_shape = x_pre;
    end
    else if (a <= two_thr[31:0]) begin
        // Region 2 moderate compression
        delta   = a - thr[31:0];
        y_shape = sgn * (thr + (delta >> 1)); // Fixed: Use >> (not >>>) for right shift. /2
    end
    else begin
        // Region 3 strong compression
        delta   = a - two_thr[31:0];
        y_shape = sgn * ((thr + (thr >> 1)) + (delta >> 2)); // Fixed: Use >> (not >>>) for right shift. 1.5T + (delta/4)
    end

    // Saturate to 16 bits
    out_sample = sat16(y_shape);
    end
endmodule