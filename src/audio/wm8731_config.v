// ============================================================
// wm8731_config.v  (REAL I2C config writer)
// Writes WM8731 registers over I2C at ~100 kHz from 50 MHz clock.
// ============================================================

module wm8731_config(
    input  wire clock,        // 50 MHz
    input  wire reset,        // active-high reset (can tie to 1'b0)

    output reg  I2C_SCLK,
    inout       I2C_SDAT
);

    // 7-bit WM8731 I2C address
    localparam [6:0] DEVICE_ADDR = 7'h1A;  // 0x1A
    localparam [7:0] ADDR_W      = {DEVICE_ADDR, 1'b0}; // write => 0x34

    // I2C clock divider for ~100 kHz SCL
    // 50 MHz / (2*DIV) = 100 kHz  -> DIV = 250
    localparam integer DIV = 250;

    reg [15:0] div_cnt;
    wire tick = (div_cnt == (DIV-1));

    // Open-drain SDA control
    reg sda_drive_low;               // 1 => drive 0, 0 => release (Z)
    assign I2C_SDAT = sda_drive_low ? 1'b0 : 1'bz;
    wire sda_in = I2C_SDAT;

    // ------------------------------------------------------------
    // WM8731 register table: each entry is 16 bits:
    //   [15:9] = register address (7 bits)
    //   [8:0]  = register data    (9 bits)
    //
    // I2C sends two data bytes after address:
    //   byte1 = {reg[6:0], data[8]}
    //   byte2 = data[7:0]
    // ------------------------------------------------------------
    localparam integer NREG = 11;
    reg [15:0] rom [0:NREG-1];

    initial begin
        // Reset register
        rom[0]  = {7'h0F, 9'h000};   // RESET

        // Power down control: all ON (0)
        rom[1]  = {7'h06, 9'h000};

        // Line input volumes (adjust later by ear)
        rom[2]  = {7'h00, 9'h017};   // Left Line In  (0x17)
        rom[3]  = {7'h01, 9'h017};   // Right Line In (0x17)

        // Headphone/line out volume
        rom[4]  = {7'h02, 9'h079};   // Left HP Out
        rom[5]  = {7'h03, 9'h079};   // Right HP Out

        // Analog audio path:
        // 0x12 is a common safe setting: DAC select + mic mute
        rom[6]  = {7'h04, 9'h012};

        // Digital audio path control: no deemph, no soft-mute
        rom[7]  = {7'h05, 9'h000};

        // Digital audio interface format:
        // I2S, 16-bit, codec in slave mode (BCLK/LRCLK from FPGA)
        rom[8]  = {7'h07, 9'h002};

        // Sampling control: normal mode (MCLK used)
        rom[9]  = {7'h08, 9'h000};

        // Activate interface
        rom[10] = {7'h09, 9'h001};
    end

    // ------------------------------------------------------------
    // I2C FSM
    // We drive SCL high/low and update SDA only while SCL is low.
    // Data is sampled by the slave while SCL is high.
    // ------------------------------------------------------------
    localparam [3:0]
        ST_IDLE      = 4'd0,
        ST_START_A   = 4'd1,
        ST_START_B   = 4'd2,
        ST_LOAD_BYTE = 4'd3,
        ST_BIT_LOW   = 4'd4,
        ST_BIT_HIGH  = 4'd5,
        ST_ACK_LOW   = 4'd6,
        ST_ACK_HIGH  = 4'd7,
        ST_STOP_A    = 4'd8,
        ST_STOP_B    = 4'd9,
        ST_NEXT      = 4'd10,
        ST_DONE      = 4'd11;

    reg [3:0] state;

    reg [3:0] reg_idx;
    reg [1:0] byte_idx;      // 0=addr, 1=byte1, 2=byte2
    reg [7:0] tx_byte;
    reg [2:0] bit_idx;       // 7..0

    reg ack_bit;             // sampled ACK (0 expected)

    // startup delay so codec powers up before first I2C transaction
    reg [19:0] startup_cnt;
    wire startup_done = (startup_cnt == 20'd1_000_000); // ~20ms at 50MHz

    // divider
    always @(posedge clock or posedge reset) begin
        if (reset) div_cnt <= 16'd0;
        else if (tick)     div_cnt <= 16'd0;
        else               div_cnt <= div_cnt + 16'd1;
    end

    // main FSM updates on tick
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // bus idle
            I2C_SCLK       <= 1'b1;
            sda_drive_low  <= 1'b0;

            state          <= ST_IDLE;
            reg_idx        <= 4'd0;
            byte_idx       <= 2'd0;
            bit_idx        <= 3'd7;
            tx_byte        <= 8'h00;
            ack_bit        <= 1'b1;

            startup_cnt    <= 20'd0;
        end else begin
            // startup wait (runs regardless of tick)
            if (!startup_done)
                startup_cnt <= startup_cnt + 20'd1;

            if (tick) begin
                case (state)

                    ST_IDLE: begin
                        // keep bus idle high
                        I2C_SCLK      <= 1'b1;
                        sda_drive_low <= 1'b0;

                        if (startup_done) begin
                            reg_idx  <= 4'd0;
                            byte_idx <= 2'd0;
                            state    <= ST_START_A;
                        end
                    end

                    // START condition: while SCL high, SDA goes high->low
                    ST_START_A: begin
                        I2C_SCLK      <= 1'b1;
                        sda_drive_low <= 1'b0;   // released high
                        state         <= ST_START_B;
                    end

                    ST_START_B: begin
                        I2C_SCLK      <= 1'b1;
                        sda_drive_low <= 1'b1;   // pull SDA low = START
                        byte_idx      <= 2'd0;
                        state         <= ST_LOAD_BYTE;
                    end

                    // Load next byte to transmit (addr, byte1, byte2)
                    ST_LOAD_BYTE: begin
                        I2C_SCLK <= 1'b0; // ensure SCL low before changing SDA

                        if (byte_idx == 2'd0) begin
                            tx_byte <= ADDR_W;
                        end else if (byte_idx == 2'd1) begin
                            // byte1 = {reg[6:0], data[8]}
                            tx_byte <= {rom[reg_idx][15:9], rom[reg_idx][8]};
                        end else begin
                            // byte2 = data[7:0]
                            tx_byte <= rom[reg_idx][7:0];
                        end

                        bit_idx <= 3'd7;
                        state   <= ST_BIT_LOW;
                    end

                    // With SCL low, drive SDA to current bit
                    ST_BIT_LOW: begin
                        I2C_SCLK <= 1'b0;

                        // drive 0 => pull low, drive 1 => release high
                        if (tx_byte[bit_idx] == 1'b0)
                            sda_drive_low <= 1'b1;
                        else
                            sda_drive_low <= 1'b0;

                        state <= ST_BIT_HIGH;
                    end

                    // Raise SCL high (slave samples data). Then move to next bit.
                    ST_BIT_HIGH: begin
                        I2C_SCLK <= 1'b1;

                        if (bit_idx == 0)
                            state <= ST_ACK_LOW;
                        else begin
                            bit_idx <= bit_idx - 3'd1;
                            state   <= ST_BIT_LOW;
                        end
                    end

                    // ACK bit: release SDA while SCL low
                    ST_ACK_LOW: begin
                        I2C_SCLK      <= 1'b0;
                        sda_drive_low <= 1'b0; // release SDA for slave ACK
                        state         <= ST_ACK_HIGH;
                    end

                    // Raise SCL high and sample ACK
                    ST_ACK_HIGH: begin
                        I2C_SCLK <= 1'b1;
                        ack_bit  <= sda_in; // ACK should be 0

                        // move to next byte or stop
                        if (byte_idx == 2'd2) begin
                            state <= ST_STOP_A;
                        end else begin
                            byte_idx <= byte_idx + 2'd1;
                            state    <= ST_LOAD_BYTE;
                        end
                    end

                    // STOP: ensure SCL low, SDA low
                    ST_STOP_A: begin
                        I2C_SCLK      <= 1'b0;
                        sda_drive_low <= 1'b1; // hold SDA low
                        state         <= ST_STOP_B;
                    end

                    // STOP condition: SCL high, then SDA low->high (release)
                    ST_STOP_B: begin
                        I2C_SCLK      <= 1'b1;
                        sda_drive_low <= 1'b0; // release SDA high = STOP
                        state         <= ST_NEXT;
                    end

                    // Next register
                    ST_NEXT: begin
                        if (reg_idx == (NREG-1)) begin
                            state <= ST_DONE;
                        end else begin
                            reg_idx  <= reg_idx + 4'd1;
                            byte_idx <= 2'd0;
                            state    <= ST_START_A;
                        end
                    end

                    // Finished: hold bus idle
                    ST_DONE: begin
                        I2C_SCLK      <= 1'b1;
                        sda_drive_low <= 1'b0;
                        state         <= ST_DONE;
                    end

                    default: state <= ST_IDLE;
                endcase
            end
        end
    end

endmodule
