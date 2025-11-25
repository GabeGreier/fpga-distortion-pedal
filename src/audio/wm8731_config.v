module wm8731_config(
    input  clock,        // 50 MHz
    input  reset,

    output reg I2C_SCLK,
    inout      I2C_SDAT
);

    // ========== I2C constants ==========
    localparam DEVICE_ADDR = 7'h1A;  // WM8731 I2C address (0x1A)

    // WM8731 register configuration table:
    reg [15:0] rom [0:9];

    initial begin
        // Register : Value pairs
        rom[0] = 16'h0C_00; // Power Down: all on
        rom[1] = 16'h0E_02; // Digital audio interface: I2S, 16-bit, slave
        rom[2] = 16'h10_00; // Sampling control normal
        rom[3] = 16'h08_00; // Analog audio path control
        rom[4] = 16'h0A_00; // Digital audio path control
        rom[5] = 16'h06_1F; // Left line in volume
        rom[6] = 16'h07_1F; // Right line in volume
        rom[7] = 16'h02_79; // DAC left volume
        rom[8] = 16'h03_79; // DAC right volume
        rom[9] = 16'h12_01; // Activate codec
    end

    reg [3:0] index = 0;
    reg [7:0] bit_cnt = 0;
    reg [31:0] shift = 0;
    reg busy = 0;

    // Simple state machine: continuously write config table
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            I2C_SCLK <= 1;
            index <= 0;
            busy <= 0;
        end else begin

            if (!busy) begin
                // Build full I2C frame:
                // [DEVICE_ADDR | write bit] + register/value
                shift <= {DEVICE_ADDR, 1'b0, rom[index]};
                bit_cnt <= 31;
                busy <= 1;
            end else begin
                // Shift out MSB on SCLK falling edge
                I2C_SCLK <= ~I2C_SCLK;

                if (I2C_SCLK == 0) begin
                    if (bit_cnt == 0) begin
                        busy <= 0;
                        index <= index + 1;
                        if (index == 9)
                            index <= 0;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                        shift <= {shift[30:0], 1'b0};
                    end
                end
            end
        end
    end

    assign I2C_SDAT = shift[31];

endmodule
