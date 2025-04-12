`timescale 1ns/1ps

`include "./defines.v"



module GreatPE (
    input clk,                  // 时钟信号
    input rst_n,                // 复位信号
    input [`DWIDTH-1:0] Xin,             // 输入X
    input [`DWIDTH-1:0] weight,        // 当前时刻的权重
    input [`DWIDTH-1:0] sum_in,        // 来自上一轮的累加和
    input [`DWIDTH-1:0] prod_in,        //来自上一轮的乘法结果
    input valid_in_data,             // 输入有效信号
    input valid_in_weight,
    input can_use,
    output reg output_can_use,
    output reg [`DWIDTH-1:0] prod_out, // 当前乘法结果
    output reg [`DWIDTH-1:0] sum_out,  // 当前累加和
    output reg [`DWIDTH-1:0] Xout,     // X的输出，原封不动
    output reg valid_out        // 输出有效信号
);
    reg [`DWIDTH-1:0] weight_mem;  // 权重存储的RAM（1个权重值）
    //reg [22:0] partial_sum;        // 层次小的部分累加和

reg in_vaild_mul;
reg in_vaild_add;


    // 权重存储（可以通过写入初始化或外部更新）
    always @(posedge clk ) begin
        if (~rst_n) begin
            // 复位时初始化权重
            weight_mem <= `DWIDTH'd0;
            in_vaild_mul<=0;
            in_vaild_add<=0;
            // 继续初始化其他权重...
        end else if (valid_in_weight)begin
         
            weight_mem<= weight;
            // 更新其他权重...
        end else begin
            weight_mem<=weight_mem;
        end
    end

    // 乘法操作
    always @(posedge clk ) begin
        if (~rst_n) begin
            prod_out <= `DWIDTH'd0;
        end else if (valid_in_data) begin
            prod_out <= Xin * weight_mem;  // 对应每个X与权重的乘积
            in_vaild_mul<=1;
        end else begin
            in_vaild_mul<=0;
        end
    end

    // 部分累加和加法操作
    always @(posedge clk ) begin
        if (~rst_n) begin
            //prod_in <= 22'd0;
            sum_out <= `DWIDTH'd0;
        end else if (valid_in_data) begin
            // 进行累加
            sum_out <= prod_in + sum_in;
            in_vaild_add<=1;
        end else begin
            in_vaild_add<=0;
        end
    end

    // X的输出（原封不动）
    always @(posedge clk ) begin
        if (~rst_n) begin
            Xout <= `DWIDTH'd0;
        end else if (valid_in_data) begin
            Xout <= Xin;  // X保持不变
            output_can_use<=can_use;
        end
    end

    // 输出有效信号
    always @(posedge clk ) begin
        if (~rst_n) begin
            valid_out <= 1'b0;
        end else if (valid_in_data&in_vaild_add&in_vaild_mul) begin
            valid_out <= 1'b1;  // 输出有效信号

        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule
