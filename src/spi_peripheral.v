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


endmodule