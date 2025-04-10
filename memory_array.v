`include "defines.v"//nLint `include compiler directive should not be used. (Language Construct,HDL Translation)
`timescale 1ns/1ps
module memory_array (
    // system
    input clk,
    input rst_n,


    // outside port
    input [`AWIDTH - 1:0] outside_addr,
    input outside_wreq,
    input [`DWIDTH  - 1:0] outside_din,
    output [`DWIDTH  - 1:0] outside_dout,
    output reg outside_dout_finish,

    // inside port
    input inside_data_rweq,
    input [`AWIDTH - 1:0] inside_write_addr,    //结果的储存地址
    input [`DWIDTH  - 1:0] inside_din,
    input inside_dout_read_vaild,
    //input inside_data_busy,
    output [`DWIDTH  - 1:0] inside_dout,
    output sram_load_isfinsh,
    output reg inside_dout_read_finish    //读取完数据
);
    
reg memory_status_reg;



always @(posedge clk ) begin
    if (~rst_n) begin
        memory_status_reg <= `MEMORY_STATUE_ZERO;    //用于切换两个ram的作用，一个储存输入，一个储存结果
    end
end

wire read_finish;

wire [`AWIDTH - 1:0]zero_addr = (memory_status_reg)?inside_write_addr:outside_addr;
wire zero_wreq = (memory_status_reg)?inside_data_rweq:outside_wreq;
wire [`DWIDTH  - 1:0]zero_din = (memory_status_reg)?inside_din:outside_din;
wire [`DWIDTH - 1:0]zero_dout;
wire zero_read_vaild;
wire zero_read_finish;

wire [`AWIDTH - 1:0]one_addr = (memory_status_reg)?outside_addr:inside_write_addr;
wire one_wreq = (memory_status_reg)?outside_wreq:inside_data_rweq;
wire [`DWIDTH - 1:0]one_din = (memory_status_reg)?outside_din:inside_din;
wire [`DWIDTH - 1:0]one_dout;
wire one_read_vaild;
wire one_read_finsih;

wire sram_load_isfinsh_zero;
wire sram_load_isfinsh_one;

assign inside_dout = (memory_status_reg)?zero_dout:one_dout;
assign outside_dout = (memory_status_reg)?one_dout:zero_dout;
assign sram_load_isfinsh =(memory_status_reg)?sram_load_isfinsh_one:sram_load_isfinsh_zero;
//assign inside_dout_read_vaild = (memory_status_reg)? zero_read_vaild : one_read_vaild;
assign zero_read_vaild=(memory_status_reg)?inside_dout_read_vaild:0;
assign one_read_vaild=(memory_status_reg)? 0: inside_dout_read_vaild;
assign read_finish= (memory_status_reg)? zero_read_finish : one_read_finish;

sram_model #(
    .ADDR_WIDTH(`AWIDTH),
    .DATA_WIDTH(`DWIDTH )   //还是整排传的
) u_sram_model_zero (
    .clk(clk),
    .addr(zero_addr),
    .wreq(zero_wreq),
    .din(zero_din),
    .sram_load_isfinsh(sram_load_isfinsh_zero),
    .dout(zero_dout),
    .read_vaild(zero_read_vaild),
    .read_finish(zero_read_finish)
);

sram_model #(
    .ADDR_WIDTH(`AWIDTH),
    .DATA_WIDTH(`DWIDTH )
) u_sram_model_one (
    .clk(clk),
    .addr(one_addr),
    .wreq(one_wreq),
    .din(one_din),
    .sram_load_isfinsh(sram_load_isfinsh_one),
    .dout(one_dout),
    .read_vaild(one_read_vaild),
    .read_finish(one_read_finish)
);

always @ (posedge clk ) begin
    if (~rst_n) begin
        outside_dout_finish<=0;
        inside_dout_read_finish<=0;
    end else begin
        outside_dout_finish<=outside_wreq;
        inside_dout_read_finish<= read_finish;
       
    end
end

endmodule