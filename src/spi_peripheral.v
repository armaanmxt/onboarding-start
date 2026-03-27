module spi_peripheral (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       sclk,
    input  wire       copi,
    input  wire       ncs,
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        en_reg_out_7_0  <= 8'h00;
        en_reg_out_15_8 <= 8'h00;
        en_reg_pwm_7_0  <= 8'h00;
        en_reg_pwm_15_8 <= 8'h00;
        pwm_duty_cycle  <= 8'h00;
    end
end


// Synchronizers
reg sclk_sync1, sclk_sync2;
reg copi_sync1, copi_sync2;
reg ncs_sync1, ncs_sync2;

always @(posedge clk) begin
    sclk_sync1 <= sclk;
    sclk_sync2 <= sclk_sync1;

    copi_sync1 <= copi;
    copi_sync2 <= copi_sync1;

    ncs_sync1 <= ncs;
    ncs_sync2 <= ncs_sync1;
end

// Edge detection
reg sclk_prev;
reg ncs_prev;

always @(posedge clk) begin
    sclk_prev <= sclk_sync2;
    ncs_prev  <= ncs_sync2;
end

wire sclk_rising = (sclk_sync2 == 1'b1) && (sclk_prev == 1'b0);
wire ncs_rising  = (ncs_sync2  == 1'b1) && (ncs_prev  == 1'b0);
wire ncs_falling = (ncs_sync2  == 1'b0) && (ncs_prev  == 1'b1);

// Shift register + bit counter
reg [15:0] shift_reg;
reg [4:0] bit_count;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= 16'b0;
        bit_count <= 5'b0;
    end else begin

        // Start of transaction
        if (ncs_falling) begin
            bit_count <= 0;
            shift_reg <= 16'b0;
        end

        // During transaction: capture bits on SCLK rising edge
        else if (ncs_sync2 == 1'b0 && sclk_rising) begin
            shift_reg <= {shift_reg[14:0], copi_sync2}; // shift left
            bit_count <= bit_count + 1;
        end
    end
end


// Decode and update registers
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // already handled above, no need to repeat
    end else begin

        if (ncs_rising && bit_count == 16) begin

            // Extract fields
            // [15] = R/W
            // [14:8] = address
            // [7:0] = data

            if (shift_reg[15] == 1'b1) begin  // WRITE only

                case (shift_reg[14:8])

                    7'h00: en_reg_out_7_0  <= shift_reg[7:0];
                    7'h01: en_reg_out_15_8 <= shift_reg[7:0];
                    7'h02: en_reg_pwm_7_0  <= shift_reg[7:0];
                    7'h03: en_reg_pwm_15_8 <= shift_reg[7:0];
                    7'h04: pwm_duty_cycle  <= shift_reg[7:0];

                    default: begin
                        // ignore invalid address
                    end

                endcase
            end
        end
    end
end

endmodule