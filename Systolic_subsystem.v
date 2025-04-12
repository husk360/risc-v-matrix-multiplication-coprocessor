`include "defines.v"
`timescale 1ns/1ps

module Systolic_subsystem(
    input clk,
    input rst_n,
    input [`PE_ROW * `PE_COL * `DWIDTH - 1:0] din_data,
    input [1:0] PEmode,
    input out_valid,
   
    output  reg [`PE_ROW * `PE_COL * `DWIDTH - 1:0] result,
    output  reg load_is_finish,             //加载权重完成
    output reg  final_is_finish             //计算完成
   
);

    parameter INIT = 2'b00;
    parameter WLOD = 2'b01;
	parameter DLOD = 2'b11;
    parameter SELW = 1'b1;
    parameter SELD = 1'b0;
    
    

	reg [1:0] mode, next_mode;
	reg load_is_work, next_load_is_work;    //计算vaild信号
	reg sel_input, next_sel_input;
    reg [`PE_ROW-1:0] is_finish;
    reg l1;
    wire [`DWIDTH-1:0] final_sum[`PE_COL-1:0];

    // 定义 partial_sum 和 prod 的初始值
    wire [`DWIDTH-1:0] partial_sum[`PE_ROW:0][`PE_COL-1:0];
    wire [`DWIDTH-1:0] prod[`PE_ROW:0][`PE_COL-1:0];
    
    // 为第一行初始化 partial_sum 和 prod
    genvar p;
    generate
        for (p = 0; p < `PE_COL; p = p + 1) begin: init_first_row
            assign partial_sum[0][p] = {`DWIDTH{1'b0}}; // 初始值为 0
            assign prod[0][p] = {`DWIDTH{1'b0}}; // 初始值为 0
        end
    endgenerate
    
    wire PEvalid_wire[`PE_ROW+1:0][`PE_COL-1:0]; // 每个PE的数据输入有效信号
    reg PEvalid_firstrow[`PE_COL-1:0];
    reg PEweight_valid;
    //reg [`DWIDTH-1:0] X_value[`PE_ROW:0][`PE_COL-1:0]; // 中间传递的不变的X值
    reg [`DWIDTH-1:0] X_value_firstrow[`PE_COL-1:0];
    wire [`DWIDTH-1:0] X_value_wire[`PE_ROW:0][`PE_COL-1:0];
    reg [`DWIDTH-1:0] din_weight[`PE_ROW-1:0][`PE_COL-1:0];

    // 计数器，用于控制数据输入
    reg [31:0] index;     // 8-bit 索引 (用于控制哪排传入阵列)
    //reg counter;         // 1-bit 计数器，用于实现2周期更新
    
   
  
    integer v;
    integer l=0;
   
	

  // 状态机组合逻辑 - 计算下一个状态和输出
always @(*) begin
    // 默认保持当前状态和输出不变
    
    
    case (mode)
        INIT: begin
            // INIT状态下的默认输出
            //next_load_is_work = 1'b0;
            //next_sel_input = SELD;
            
            // 状态转换逻辑
            if (PEmode == 2'b01) begin
                next_mode = WLOD;
               
            end else if (PEmode == 2'b11 && out_valid) begin
                next_mode = DLOD;
               
            end  else begin
				next_mode=INIT;
				next_sel_input=SELD;
                next_load_is_work=0;
                
               
			end
        end
        
        WLOD: begin
            // WLOD状态下的默认输出
            next_load_is_work = 1'b0;
            
            // 状态转换逻辑
            if (out_valid) begin
                next_sel_input = SELW;           
                next_mode = INIT;
                
			end else begin
				next_mode = INIT;
                next_sel_input = SELD;  // 返回INIT时更新sel_input
			end
        end
        
        DLOD: begin
            // DLOD状态下的默认输出
            next_sel_input = SELD;
            
            // 状态转换逻辑
           
                next_mode = INIT;
                next_load_is_work = 1'b1;  // 返回INIT且out_valid为1时设置load_is_work为1
        end
        
        default: begin
            // 默认情况，恢复到INIT状态
            next_mode = INIT;
            next_load_is_work = 1'b0;
            next_sel_input = SELD;
        end
    endcase
end

// 状态机时序逻辑 - 寄存器更新
always @(posedge clk ) begin
    if (~rst_n) begin
        // 复位时初始化所有状态寄存器
        mode <= INIT;
        load_is_work <= 1'b0;
        sel_input <= SELD;
        is_finish <= 0;
        load_is_finish<=0;
         // 初始化所有 PEvalid 为 0
            for (v = 0; v <= `PE_COL-1; v = v + 1) begin
                PEvalid_firstrow[v] <= 1'b0;
            end
            is_finish <= 0;
         
    end else begin
        // 在时钟上升沿更新所有状态寄存器
        mode <= next_mode;
       

        load_is_work <= next_load_is_work;
      
        sel_input <= next_sel_input;
        load_is_finish<=0;
        if(next_sel_input==1)begin
            load_is_finish<=1;
        end
    end



           
            // 根据 load_is_work 更新第一行 PEvalid
            for (v = 0; v <= `PE_COL-1; v = v + 1) begin
                PEvalid_firstrow[v] <= load_is_work;
            end
            


            is_finish[index-1] <= l1;
    
          
                //储存结果的模块
        if (is_finish[index-1]) begin
        

              // 检查输出有效信号来更新 is_finsh
          
                //当所有的计算都完成时
                final_is_finish<=0;
            if(&is_finish) begin
              
                index<=1;
                is_finish<=`PE_ROW'b0;
                l=0;
            end


            if (PEmode==2'b00 || out_valid==0) begin
             
                final_is_finish<=0;
                index<=1;
                is_finish<=0;
            end


           
              
        end
end




    // 根据 sel_input 为 din_weight 或 X_value 赋值
    integer i1, j1, k1,i2;
    always @(*) begin

        
        // 根据 sel_input 选择性地更新对应的值
        if (sel_input) begin
            for (i1 = 0; i1 < `PE_ROW; i1 = i1 + 1) begin
                for (j1 = 0; j1 < `PE_COL; j1 = j1 + 1) begin
                    din_weight[i1][j1] = din_data[`PE_COL*`PE_ROW*`DWIDTH - (i1 * `PE_COL* `DWIDTH + j1*`DWIDTH) - 1 -: `DWIDTH];
                end
            end

  

        end else begin
            for (k1 = 0; k1 < `PE_COL; k1 = k1 + 1) begin
                if (index <= `PE_ROW)
                    X_value_firstrow[k1] = din_data[`PE_COL*(`PE_ROW-index+1)*`DWIDTH - k1*`DWIDTH - 1 -: `DWIDTH];
            end
        end






    end



reg [`DWIDTH-1:0] final_sum_q=0;
reg [31:0] store_index=0;


// 计数器逻辑
    always @(posedge clk ) begin
        if (!rst_n) begin
            //counter <= 1'b0;  // 计数器复位
            index <= 1;   // 索引复位
        end else if (load_is_work && is_finish[index-1]) begin
           // counter <= counter + 1'b1; // 计数器递增
           
                index <= (index == `PE_ROW) ? index : (index + 1); // 修正溢出的问题 
           
            
        end 



                if(final_sum[0]!=final_sum_q) begin

                  store_index=store_index+1;   
         for (i2=0;i2<`PE_COL; i2=i2+1) begin
         result[(`PE_ROW-store_index+1)*`PE_COL*`DWIDTH-1 -i2*`DWIDTH-:`DWIDTH]<=final_sum[i2];
         final_sum_q<=final_sum[0];
        
            end
            
                end else if(store_index==`PE_COL) begin
                    store_index=0;
                    final_is_finish<=1;
                    final_sum_q<=0;
                end
    end






    // PEvalid 初始化逻辑


always@(*) begin
    
 for (l=0; l<`PE_COL; l=l+1) begin
                if(l==0) begin
                    l1= PEvalid_wire[`PE_ROW+1][l]&& PEvalid_wire[`PE_ROW+1][l+1];
                end else if (l>1) begin
                l1= l1&&PEvalid_wire[`PE_ROW+1][l];
                end

            end

end




   
    //控制PE权重的有效信号
    always@(*) begin
        if (sel_input) begin
             PEweight_valid=1;
        end else if (next_sel_input==0) begin
             PEweight_valid=0;
        end else begin
             PEweight_valid=0;
        end
    end

  


// 实例化脉动阵列
    genvar i, j;

    generate
         for (j = 0; j < `PE_COL; j = j + 1) begin: proc_j
                GreatPE u_GreatPE (
                    .clk        (clk),
                    .rst_n      (rst_n),
                    .Xin        (X_value_firstrow[j]),
                    .weight     (din_weight[(j)%`PE_ROW][j]),
                    .sum_in     (partial_sum[0][j]),
                    .prod_in    (prod[0][j]),
                    .valid_in_data   (PEvalid_firstrow[j]),
                    .valid_in_weight (PEweight_valid),
                    .prod_out   (prod[1][j]),
                    .sum_out    (partial_sum[1][j]),
                    .Xout       (X_value_wire[1][(j+`PE_COL-1)%`PE_COL]),
                    .valid_out  (PEvalid_wire[1][j])
                );
            end


        endgenerate



    generate
        for (i = 1; i < `PE_ROW; i = i + 1) begin: proc_i
            for (j = 0; j < `PE_COL; j = j + 1) begin: proc_j
                GreatPE u_GreatPE (
                    .clk        (clk),
                    .rst_n      (rst_n),
                    .Xin        (X_value_wire[i][j]),
                    .weight     (din_weight[(i+j)%`PE_ROW][j]),
                    .sum_in     (partial_sum[i][j]),
                    .prod_in    (prod[i][j]),
                    .valid_in_data   (PEvalid_wire[i][j]),
                    .valid_in_weight (PEweight_valid),
                    .prod_out   (prod[i+1][j]),
                    .sum_out    (partial_sum[i+1][j]),
                    .Xout       (X_value_wire[i+1][(j+`PE_COL-1)%`PE_COL]),
                    .valid_out  (PEvalid_wire[i+1][j])
                );
            end
        end
    endgenerate

    // 实例化输出累加器
    genvar k;
    generate
        for (k = 0; k < `PE_COL; k = k + 1) begin: proc_k
            End_adder u_End_adder (
                .clk        (clk),
                .rst_n      (rst_n),
                .sum_in     (partial_sum[`PE_ROW][k]),
                .prod_in    (prod[`PE_ROW][k]),
                .valid_in   (PEvalid_wire[`PE_ROW][k]),
                .sum_out    (final_sum[k]),
                .valid_out  (PEvalid_wire[`PE_ROW+1][k])
            );
        end
    endgenerate




endmodule