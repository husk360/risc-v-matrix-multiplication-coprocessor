`timescale 1ns/1ps

`include "./defines.v"



module End_adder (
    input clk,                  // 时钟信号
    input rst_n,                // 复位信号
    input [`DWIDTH-1:0] sum_in,        // 来自上一轮的累加和
    input [`DWIDTH-1:0] prod_in,        //来自上一轮的乘法结果
    input valid_in,             // 输入有效信号
    input can_use,
    output reg output_can_use,
    output reg [`DWIDTH-1:0] sum_out,  // 最终的结果
    output reg valid_out        // 输出有效信号
);
   reg in_vaild_add;

   

    // 加法操作
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            sum_out <= `DWIDTH'd0;
            in_vaild_add<=0;
        end else if (valid_in) begin
            // 进行累加
            sum_out <= prod_in + sum_in;
            in_vaild_add<=1;
        end else begin
            in_vaild_add<=0;
        end
    end



    // 输出有效信号
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n || valid_in==0) begin
            valid_out <= 1'b0;
         
        end else if (in_vaild_add) begin
            valid_out <= 1'b1;  // 输出有效信号
            output_can_use<=can_use;
        end else begin
            valid_out <= 1'b0;
         
        end
    end

endmodule
