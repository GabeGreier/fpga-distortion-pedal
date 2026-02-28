module mode_select (
    input  wire clk,
    input  wire [1:0] sw,
    output reg [1:0] mode
);
    reg [1:0] sw_ff1, sw_ff2;

    always @(posedge clk) begin
        sw_ff1 <= sw;
        sw_ff2 <= sw_ff1;
        mode   <= sw_ff2;
    end
endmodule
