// This module was written with ai in reference the HD44780 LCD controller datasheet.
// It initializes the LCD and displays the current distortion mode selected via the 'mode' input.
// Works in junction with the mode_select module to show the selected mode on the LCD screen.

module lcd_hd44780 (
    input  wire       clk,        // 50 MHz
    input  wire       reset_n,    // active-low
    input  wire [1:0] mode,

    output reg  [7:0] LCD_DATA,
    output reg        LCD_EN,
    output reg        LCD_RS,
    output reg        LCD_RW,
    output reg        LCD_ON,
    output reg        LCD_BLON
);

    // LCD timing (50 MHz clock)
    localparam integer WAIT_15MS   = 750_000;   // 15ms @ 50MHz
    localparam integer WAIT_40US   = 2_000;     // 40us
    localparam integer WAIT_2MS    = 100_000;   // 2ms
    localparam integer E_PULSE     = 50;        // 1us-ish pulse (50 cycles @ 50MHz)

    // Main states
    localparam [3:0]
        ST_RESET_WAIT   = 4'd0,
        ST_FUNC_SET     = 4'd1,
        ST_DISP_OFF     = 4'd2,
        ST_CLEAR        = 4'd3,
        ST_ENTRY        = 4'd4,
        ST_DISP_ON      = 4'd5,
        ST_ADDR_LINE1   = 4'd6,
        ST_WRITE_LINE1  = 4'd7,
        ST_ADDR_LINE2   = 4'd8,
        ST_WRITE_LINE2  = 4'd9,
        ST_IDLE         = 4'd10,
        ST_SEND_SETUP   = 4'd11,
        ST_SEND_EHIGH   = 4'd12,
        ST_SEND_WAIT    = 4'd13;

    reg [3:0]  state, return_state;
    reg [31:0] cnt;
    reg [31:0] post_wait;
    reg        send_is_data;
    reg [7:0]  send_byte;

    reg [5:0]  char_idx;          // 0..31
    reg [1:0]  last_mode;

    // ------------------------------------------------------------
    // Build characters for LCD (pure Verilog function style)
    // ------------------------------------------------------------
    function [7:0] char_at;
        input [5:0] idx;
        input [1:0] m;
        begin
            // Line 1: "FPGA DISTORTION "
            if (idx < 16) begin
                case (idx)
                    0:  char_at = "F";
                    1:  char_at = "P";
                    2:  char_at = "G";
                    3:  char_at = "A";
                    4:  char_at = " ";
                    5:  char_at = "D";
                    6:  char_at = "I";
                    7:  char_at = "S";
                    8:  char_at = "T";
                    9:  char_at = "O";
                    10: char_at = "R";
                    11: char_at = "T";
                    12: char_at = "I";
                    13: char_at = "O";
                    14: char_at = "N";
                    15: char_at = " ";
                    default: char_at = " ";
                endcase
            end else begin
                // Line 2: "MODE: ______     "
                // idx 16..31 -> position 0..15
                case (idx - 16)
                    0: char_at = "M";
                    1: char_at = "O";
                    2: char_at = "D";
                    3: char_at = "E";
                    4: char_at = ":";
                    5: char_at = " ";
                    6: begin
                        case (m)
                            2'b00: char_at = "C"; // CLEAN
                            2'b01: char_at = "L"; // LIGHT
                            2'b10: char_at = "N"; // NORMAL
                            2'b11: char_at = "H"; // HEAVY
                        endcase
                    end
                    7: begin
                        case (m)
                            2'b00: char_at = "L";
                            2'b01: char_at = "I";
                            2'b10: char_at = "O";
                            2'b11: char_at = "E";
                        endcase
                    end
                    8: begin
                        case (m)
                            2'b00: char_at = "E";
                            2'b01: char_at = "G";
                            2'b10: char_at = "R";
                            2'b11: char_at = "A";
                        endcase
                    end
                    9: begin
                        case (m)
                            2'b00: char_at = "A";
                            2'b01: char_at = "H";
                            2'b10: char_at = "M";
                            2'b11: char_at = "V";
                        endcase
                    end
                    10: begin
                        case (m)
                            2'b00: char_at = "N";
                            2'b01: char_at = "T";
                            2'b10: char_at = "A";
                            2'b11: char_at = "Y";
                        endcase
                    end
                    11: begin
                        case (m)
                            2'b00: char_at = " ";
                            2'b01: char_at = " ";
                            2'b10: char_at = "L";
                            2'b11: char_at = " ";
                        endcase
                    end
                    12: char_at = " ";
                    13: char_at = " ";
                    14: char_at = " ";
                    15: char_at = " ";
                    default: char_at = " ";
                endcase
            end
        end
    endfunction

    // Default outputs / constants
    always @* begin
        LCD_ON   = 1'b1;   // keep LCD powered
        LCD_BLON = 1'b0;   // not used (no backlight on many DE2-115 LCDs)
    end

    always @(posedge clk) begin
        if (!reset_n) begin
            state        <= ST_RESET_WAIT;
            return_state <= ST_RESET_WAIT;
            cnt          <= 32'd0;

            LCD_EN       <= 1'b0;
            LCD_RS       <= 1'b0;
            LCD_RW       <= 1'b0;
            LCD_DATA     <= 8'h00;

            char_idx     <= 6'd0;
            last_mode    <= 2'b00;

            // Also clear these to avoid X-propagation
            post_wait    <= 32'd0;
            send_is_data <= 1'b0;
            send_byte    <= 8'h00;

        end else begin
            case (state)
                ST_RESET_WAIT: begin
                    if (cnt >= WAIT_15MS) begin
                        cnt   <= 32'd0;
                        state <= ST_FUNC_SET;
                    end else begin
                        cnt <= cnt + 32'd1;
                    end
                end

                // --- init command sequence ---
                ST_FUNC_SET: begin
                    send_is_data <= 1'b0; send_byte <= 8'h38; post_wait <= WAIT_40US;
                    return_state <= ST_DISP_OFF; state <= ST_SEND_SETUP;
                end
                ST_DISP_OFF: begin
                    send_is_data <= 1'b0; send_byte <= 8'h08; post_wait <= WAIT_40US;
                    return_state <= ST_CLEAR; state <= ST_SEND_SETUP;
                end
                ST_CLEAR: begin
                    send_is_data <= 1'b0; send_byte <= 8'h01; post_wait <= WAIT_2MS;
                    return_state <= ST_ENTRY; state <= ST_SEND_SETUP;
                end
                ST_ENTRY: begin
                    send_is_data <= 1'b0; send_byte <= 8'h06; post_wait <= WAIT_40US;
                    return_state <= ST_DISP_ON; state <= ST_SEND_SETUP;
                end
                ST_DISP_ON: begin
                    send_is_data <= 1'b0; send_byte <= 8'h0C; post_wait <= WAIT_40US;
                    return_state <= ST_ADDR_LINE1; state <= ST_SEND_SETUP;
                end

                // --- write line 1 ---
                ST_ADDR_LINE1: begin
                    char_idx     <= 6'd0;
                    send_is_data <= 1'b0; send_byte <= 8'h80; post_wait <= WAIT_40US; // DDRAM line 1
                    return_state <= ST_WRITE_LINE1; state <= ST_SEND_SETUP;
                end
                ST_WRITE_LINE1: begin
                    send_is_data <= 1'b1; send_byte <= char_at(char_idx, mode); post_wait <= WAIT_40US;
                    if (char_idx == 6'd15) begin
                        return_state <= ST_ADDR_LINE2;
                        state <= ST_SEND_SETUP;
                    end else begin
                        char_idx <= char_idx + 6'd1;
                        return_state <= ST_WRITE_LINE1;
                        state <= ST_SEND_SETUP;
                    end
                end

                // --- write line 2 ---
                ST_ADDR_LINE2: begin
                    char_idx     <= 6'd16;
                    send_is_data <= 1'b0; send_byte <= 8'hC0; post_wait <= WAIT_40US; // DDRAM line 2
                    return_state <= ST_WRITE_LINE2; state <= ST_SEND_SETUP;
                end
                ST_WRITE_LINE2: begin
                    send_is_data <= 1'b1; send_byte <= char_at(char_idx, mode); post_wait <= WAIT_40US;
                    if (char_idx == 6'd31) begin
                        last_mode    <= mode;
                        return_state <= ST_IDLE;
                        state <= ST_SEND_SETUP;
                    end else begin
                        char_idx <= char_idx + 6'd1;
                        return_state <= ST_WRITE_LINE2;
                        state <= ST_SEND_SETUP;
                    end
                end

                // refresh line 2 only when mode changes
                ST_IDLE: begin
                    if (mode != last_mode) begin
                        state <= ST_ADDR_LINE2;
                    end
                end

                // --- byte sender ---
                ST_SEND_SETUP: begin
                    LCD_RS   <= send_is_data;
                    LCD_RW   <= 1'b0;        // write only
                    LCD_DATA <= send_byte;
                    LCD_EN   <= 1'b0;
                    cnt      <= 32'd0;
                    state    <= ST_SEND_EHIGH;
                end

                ST_SEND_EHIGH: begin
                    if (cnt >= E_PULSE) begin
                        LCD_EN <= 1'b0;
                        cnt    <= 32'd0;
                        state  <= ST_SEND_WAIT;
                    end else begin
                        LCD_EN <= 1'b1;
                        cnt    <= cnt + 32'd1;
                    end
                end

                ST_SEND_WAIT: begin
                    if (cnt >= post_wait) begin
                        cnt   <= 32'd0;
                        state <= return_state;
                    end else begin
                        cnt <= cnt + 32'd1;
                    end
                end

                default: state <= ST_RESET_WAIT;
            endcase
        end
    end

endmodule
