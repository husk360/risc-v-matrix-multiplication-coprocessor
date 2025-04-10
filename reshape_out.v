`include "defines.v"
`timescale 1ns/1ps
module reshape_out (
    input wire clk, 
    input wire rst_n,
    input wire[`PE_COL*`PE_ROW*`DWIDTH-1:0]result,
    input finish_systolic,
  
    
    output reg inside_data_rweq,
    output reg[`AWIDTH-1:0]load_addr,
    //output reg busy,
    output reg inside_dout_finish,
    output reg [`DWIDTH-1:0]dout
  
    

);



 // 参数定义
    parameter SEGMENTS = `PE_COL*`PE_ROW;     // 数据段数量 
    
    // 内部寄存器
    reg [`PE_COL*`PE_ROW*`DWIDTH-1:0] result_ram;       // 存储当前输入数据
    reg [`AWIDTH-1:0] counter;          // 计数器，用于跟踪当前输出的段
    //reg busy;                   // 模块状态标志
    
    // 状态定义
    localparam STANDBY = 1'b0;
    localparam WORKING = 1'b1;
    reg state;
    
  
    
    always @(posedge clk ) begin
        if (!rst_n) begin
            // 复位逻辑
            result_ram <= `PE_COL*`PE_ROW*`DWIDTH'b0;
            counter <= `AWIDTH'b0;
            dout <= `DWIDTH'b0;
            load_addr <= `AWIDTH'b0;
            inside_data_rweq <= 1'b0;
            //busy <= 1'b0;
            state <= STANDBY;
        end else begin
            case (state)
                STANDBY: begin
                    inside_data_rweq <= 1'b0;
                    inside_dout_finish<=1'b0;
                    counter <= `AWIDTH'b0;       // 重置计数器
                    // 检测输入数据是否变化
                    if (finish_systolic) begin
                        result_ram <= result;   // 存储新的输入数据
                        state <= WORKING;      // 切换到工作状态
                        //busy <= 1'b1;
                    end
                end
                
                WORKING: begin
                    if ((counter < SEGMENTS)) begin
                        // 计算当前段的索引并输出
                        dout <= result_ram[`PE_COL*`PE_ROW*`DWIDTH-1-`DWIDTH*counter-:`DWIDTH];  // 选择16位段
                        load_addr <= counter;                      // 输出当前地址
                        inside_data_rweq <= 1'b1;                        // 标记输出有效
                        counter <= counter + 1'b1;                // 更新计数器
                    end else begin
                        // 所有段处理完毕
                        inside_data_rweq <= 1'b0;     // 清除有效标志
                        inside_dout_finish<=1'b1;
                        state <= STANDBY;      // 返回待机状态
                        //busy <= 1'b0;
                    end
                end
            endcase
        end
    end


endmodule