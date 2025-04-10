`include "defines.v"
`timescale 1ns/1ps
module reshape_in (
    input clk, 
    input rst_n,
    input [`DWIDTH-1:0]din,
    input [1:0] work_mode,
   

    output reg[`AWIDTH-1:0]load_addr,
    output reg [`PE_COL*`PE_ROW*`DWIDTH-1:0]dout,
    output reg out_valid,
    output  reg [1:0]PEmode

);

integer i3;




always@(posedge clk) begin
    
   

    if(work_mode==2'b01) begin
        PEmode<=2'b00;
    end else if(work_mode==2'b10) begin
        PEmode<=2'b01;
    end else if(work_mode==2'b11) begin
        PEmode<=2'b11;
    end else begin
        PEmode<=2'b00;
    end
    
end
  
  integer counter=0;



localparam NORMAL = 2'b00;
localparam COUNTER_PLUS = 2'b01;
localparam WAIT = 2'b11;
reg [1:0] state,next_state;
integer is_a=0;


// 状态机时序逻辑 - 寄存器更新
always @(posedge clk ) begin
    if (~rst_n) begin
        // 复位时初始化所有状态寄存器
        state <= NORMAL;

    end else begin
        // 在时钟上升沿更新所有状态寄存器
        state <= next_state;
       
    end
end





always @(posedge clk) begin
        if (!rst_n) begin
            // 复位逻辑
            out_valid<=0;
            state <= NORMAL;
        end else begin
            case (state)
                NORMAL: begin
                    if(work_mode==2'b10 || work_mode== 2'b11) begin
                     if(counter<(`PE_COL*`PE_ROW)) begin
                 
                        dout[`PE_COL*`PE_ROW*`DWIDTH-1-counter*`DWIDTH-:`DWIDTH]<=din;
                        next_state<=COUNTER_PLUS;
                        is_a=1;
                       
                     end 
                    end 
                    
                    if ( counter==(`PE_COL*`PE_ROW))begin
                             out_valid<=1;
                             load_addr<=0;
                             next_state<=WAIT;
                    end else begin
                         out_valid<=0;
                    end
                end
                
                COUNTER_PLUS: begin
                    if(is_a) begin
                  
                   counter=counter+1;
                    load_addr<= counter;
                   next_state<=NORMAL;
                   is_a=0;
                    end
                end

                WAIT: begin
                    counter=0;
                    next_state<=NORMAL;
                end
            endcase
        end
    end


endmodule