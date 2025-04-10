`timescale 1ns/1ps
`include "defines.v"
module sram_model #(
    parameter ADDR_WIDTH = `AWIDTH,
    parameter DATA_WIDTH = `DWIDTH
) (
    input clk,

    input [ADDR_WIDTH - 1:0] addr,
    input wreq,
    input [DATA_WIDTH - 1:0] din,
    input read_vaild,
    output reg read_finish,
    output reg sram_load_isfinsh,
    output reg [DATA_WIDTH - 1:0] dout
);

reg [DATA_WIDTH - 1:0] mem [`PE_COL*`PE_ROW-1:0];

genvar i;
generate
    for (i = 0; i < `PE_COL*`PE_ROW; i = i + 1) begin:proc_i
        always @ (posedge clk) begin
            sram_load_isfinsh<=0;
            if (wreq && i == addr) begin
                mem[i] <= din;
                sram_load_isfinsh<=1;
            end
        end
    end
endgenerate
    
always @ (posedge clk) begin
    read_finish<=0;
    dout <= mem[addr];//nLint (More than 1) bit index or range "[addr]" should be a constant for signal "mem[addr]". (Synthesis)
    if(read_vaild) begin
        read_finish<=1;
    end else begin
        read_finish<=0;
    end
end

endmodule