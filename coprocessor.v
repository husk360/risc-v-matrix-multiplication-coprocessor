`include "defines.v"
`timescale 1ns/1ps
module coprocessor (
    input clk, resetn,

	input             pcpi_valid,
	input      [31:0] pcpi_insn,
	input      [31:0] pcpi_rs1,
	input      [31:0] pcpi_rs2,
	output reg           pcpi_wr,
	output reg    [31:0] pcpi_rd,
	output reg           pcpi_wait,
	output reg           pcpi_ready
);

reg instr_load, instr_weight, instr_compute, instr_read;
wire instr_any_mul = |{instr_load, instr_weight, instr_compute, instr_read};
reg pcpi_wait_q;


wire [`DWIDTH-1:0]load_data;
wire memory_output_finish;
reg [1:0]work_mode;

always @(posedge clk or negedge resetn) begin
		instr_load <= 0;
		instr_weight <= 0;
		instr_compute <= 0;
        instr_read<=0;
		
        //用于解读指令，来控制协处理器执行什么操作
		if (resetn && pcpi_valid && pcpi_insn[6:0] == 7'b1011011 && pcpi_insn[31:25] == 7'b0000001) begin
			case (pcpi_insn[14:12])
				3'b001: instr_load <= 1;
				3'b010: instr_weight <= 1;
				3'b100: instr_compute <= 1;
                3'b101: instr_read <=1;     //用于读取数据

                default : begin
                    instr_load <= 0;
				    instr_weight <= 0;
				    instr_compute <= 0;
                    instr_read <=0;     //用于读取数据

                end
			endcase
		end

		
		
	end


always@(*) begin
    if(instr_any_mul)begin
        pcpi_wait = 1;
    end else if (pcpi_ready)begin
        pcpi_wait = 0;
    end
end


always@(*) begin
    if (instr_load && !instr_weight && !instr_compute) begin
        work_mode=2'b01;  //把外面的数据加载到ram中
    end else if(instr_weight && !instr_load && !instr_compute) begin
        work_mode=2'b10;    //从ram中读取数据，加载权重
    end else if(instr_compute && !instr_load && !instr_weight) begin
        work_mode=2'b11;    //从ram中读取数据，开始计算
    end else begin
        work_mode=2'b00;
    end
end


wire [`AWIDTH-1:0] reshape_in_addr;
wire outside_wreq=(work_mode==2'b01)?1:0;
wire [`AWIDTH-1:0] out_data_addr=(work_mode==2'b01)? pcpi_rs1[`AWIDTH-1:0] : reshape_in_addr;
wire [`PE_ROW*`PE_COL*`DWIDTH-1:0] data_systolic;
wire out_valid;
wire [1:0]PEmode;
wire [`PE_ROW * `PE_COL * `DWIDTH - 1:0] result_systolic;
wire is_finish_systolic;
wire reshape_out_isfinish;
wire inside_data_rweq;
wire [`AWIDTH-1:0] inside_write_addr_reshape_out;
wire [`AWIDTH-1:0] inside_write_addr=(instr_read)? pcpi_rs1[`AWIDTH-1:0] : inside_write_addr_reshape_out;
wire [`DWIDTH-1:0 ]inside_din;
wire [`DWIDTH-1:0]inside_dout;
wire inside_dout_finish;  //用于计算完成后的finish信号
wire load_is_finish;
wire sram_load_isfinsh;
//wire busy;

assign pcpi_rd = {16'b0, inside_dout};
assign pcpi_wr=inside_dout_finish;      //用于阅读计算完的数据时至高


// pcpi_ready(完成指令后置高的)
always@(posedge clk)begin
    pcpi_ready<=0;
    if(sram_load_isfinsh || load_is_finish || reshape_out_isfinish)  begin
        pcpi_ready<=1;
    end
end

memory_array u_memory_array(
    .clk(clk),
    .rst_n(resetn),


    
    .outside_addr(out_data_addr),
    .outside_wreq(outside_wreq),
    .outside_din(pcpi_rs2[`DWIDTH-1:0]),
    .outside_dout(load_data),
    .outside_dout_finish(memory_output_finish), //每储存好一个数据这个就为高（感觉好像没什么用）

   
    .inside_data_rweq(inside_data_rweq),
    .inside_write_addr(inside_write_addr),    //结果的储存地址
    .inside_din(inside_din),

    .inside_dout(inside_dout),
    .sram_load_isfinsh(sram_load_isfinsh),
    .inside_dout_finish(inside_dout_finish)     //所有计算结果以及完成
    //.inside_data_busy(busy)make


);

reshape_in u_reshape_in(
    .clk(clk), 
    .rst_n(resetn),
    .din(load_data),
    .work_mode(work_mode),

    .load_addr(reshape_in_addr),
    .dout(data_systolic),
    .out_valid(out_valid),
    .PEmode(PEmode)  


);

reshape_out u_reshape_out(

    .clk(clk), 
    .rst_n(resetn),
    .result(result_systolic),
    .finish_systolic(is_finish_systolic),
    
    .inside_data_rweq(inside_data_rweq),
    .load_addr(inside_write_addr_reshape_out),
    //.busy(busy),
    .inside_dout_finish(reshape_out_isfinish),          //output
    .dout(inside_din)




);



Systolic_subsystem u_Systolic_subsystem(
    .clk(clk),
    .rst_n(resetn),
    .din_data(data_systolic),
    .PEmode(PEmode),
    .out_valid(out_valid),
    
    .result(result_systolic),
    .load_is_finish(load_is_finish),
    .final_is_finish(is_finish_systolic)




);

endmodule