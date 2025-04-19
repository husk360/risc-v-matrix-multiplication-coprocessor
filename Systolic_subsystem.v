`include "defines.v"
`timescale 1ns/1ps

module Systolic_subsystem(
    input clk,
    input rst_n,
    input [`PE_ROW * `PE_COL * `DWIDTH - 1:0] din_data,
    input [1:0] PEmode,
    input out_valid,
   
    output  reg [`PE_ROW * `PE_COL * `DWIDTH - 1:0] result,
    output  reg load_is_finish,             //Complete loading weight 
    output reg  final_is_finish             //Complete the calculation
   
);

    parameter INIT = 2'b00;
    parameter WLOD = 2'b01;
	parameter DLOD = 2'b11;
    parameter SELW = 1'b1;
    parameter SELD = 1'b0;
    
    

	reg [1:0] mode, next_mode;
	reg load_is_work, next_load_is_work;    //Calculate the vaild signal
	reg sel_input, next_sel_input;
    reg [`PE_ROW-1:0] is_finish;
    reg l1;
    wire [`DWIDTH-1:0] final_sum[`PE_COL-1:0];

    // Define the initial values of partial_sum and prod
    wire [`DWIDTH-1:0] partial_sum[`PE_ROW:0][`PE_COL-1:0];
    wire [`DWIDTH-1:0] prod[`PE_ROW:0][`PE_COL-1:0];
    
    // Initialize partial_sum and prod for the first line
    genvar p;
    generate
        for (p = 0; p < `PE_COL; p = p + 1) begin: init_first_row
            assign partial_sum[0][p] = {`DWIDTH{1'b0}}; // The initial value is 0
            assign prod[0][p] = {`DWIDTH{1'b0}}; // The initial value is 0
        end
    endgenerate
    
    wire PEvalid_wire[`PE_ROW+1:0][`PE_COL-1:0]; // The valid signal of each PE
    reg PEvalid_firstrow[`PE_COL-1:0];
    reg PEweight_valid;
    reg [`DWIDTH-1:0] X_value_firstrow[`PE_COL-1:0];
    wire [`DWIDTH-1:0] X_value_wire[`PE_ROW:0][`PE_COL-1:0];
    reg [`DWIDTH-1:0] din_weight[`PE_ROW-1:0][`PE_COL-1:0];

    // Counter, used to control data input
    reg [31:0] index;     //8-bit index (used to control which row to input)
    
    
    reg can_use;
    wire can_use_wire[`PE_ROW:0][`PE_COL-1:0];




    integer v;
    integer l=0;
   
	

  // State machine
always @(*) begin
   
    
    
    case (mode)
        INIT: begin
          
           
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
            // The default output in the WLOD state
            next_load_is_work = 1'b0;
            
       
            if (out_valid) begin
                next_sel_input = SELW;           
                next_mode = INIT;
                
			end else begin
				next_mode = INIT;
                next_sel_input = SELD;  // Update sel_input when returning INIT
			end
        end
        
        DLOD: begin
            // DThe default output in the DLOD state
            next_sel_input = SELD;
            
          
           
                next_mode = INIT;
                next_load_is_work = 1'b1;  // Return INIT and set load_is_work to 1 when out_valid is 1
        end
        
        default: begin
            // By default, restore to the INIT state
            next_mode = INIT;
            next_load_is_work = 1'b0;
            next_sel_input = SELD;
        end
    endcase
end

// PE register update
always @(posedge clk ) begin
    if (~rst_n) begin
        // Initialize all status registers when resetting
        mode <= INIT;
        load_is_work <= 1'b0;
        sel_input <= SELD;
        is_finish <= 0;
        load_is_finish<=0;
         // Initialize all PEvalid to 0
            for (v = 0; v <= `PE_COL-1; v = v + 1) begin
                PEvalid_firstrow[v] <= 1'b0;
            end
            is_finish <= 0;
         
    end else begin
        // Update all status registers at the rising edge of the clock
        mode <= next_mode;
       

        load_is_work <= next_load_is_work;
      
        sel_input <= next_sel_input;
        load_is_finish<=0;
        if(next_sel_input==1)begin
            load_is_finish<=1;
        end
    end



           
            // Update the first line PEvalid based on load_is_work
            for (v = 0; v <= `PE_COL-1; v = v + 1) begin
                PEvalid_firstrow[v] <= load_is_work;
            end
            


            is_finish[index-1] <= l1;
    
          
               // Used to detect whether the data of each row has been calculated
        if (is_finish[index-1]) begin
    
                final_is_finish<=0;
                // When all the calculations are completed
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




    // Assign values to din_weight or X_value based on sel_input
    integer i1, j1, k1,i2;
    always @(*) begin

        
        // Selectively update the corresponding value based on sel_input
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




reg [31:0] store_index=1;


//Counter logic
    always @(posedge clk ) begin
        can_use<=0;
        if (!rst_n) begin
         
            index <= 1;   // Index reset
        end else if (load_is_work && is_finish[index-1]) begin
          
           
                index <= (index == `PE_ROW) ? index : (index + 1); // Fix the overflow problem
                can_use <=1;
            
        end  

        if(store_index==`PE_COL) begin
                           
                            final_is_finish<=1;
                        
        end else if(can_use_wire[`PE_ROW][0]) begin

                  store_index=store_index+1;   
        
            
                end 

            if(load_is_work) begin
                 for (i2=0;i2<`PE_COL; i2=i2+1) begin
         result[(`PE_ROW-store_index+1)*`PE_COL*`DWIDTH-1 -i2*`DWIDTH-:`DWIDTH]<=final_sum[i2];
         
                 end
            end else begin
                store_index=1;
            end
    end






    // PEvalid initialization logic


always@(*) begin
    
 for (l=0; l<`PE_COL; l=l+1) begin
                if(l==0) begin
                    l1= PEvalid_wire[`PE_ROW+1][l]&& PEvalid_wire[`PE_ROW+1][l+1];
                end else if (l>1) begin
                l1= l1&&PEvalid_wire[`PE_ROW+1][l];
                end

            end

end




   
    // Valid signal for controlling the PE weight
    always@(*) begin
        if (sel_input) begin
             PEweight_valid=1;
        end else if (next_sel_input==0) begin
             PEweight_valid=0;
        end else begin
             PEweight_valid=0;
        end
    end

  


// Instantiate the systolic array
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
                    .can_use    (can_use),
                    .output_can_use (can_use_wire[0][j]),
                    .valid_out  (PEvalid_wire[1][j])
                );
            end


        endgenerate


    //Instantiate the PE module
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
                    .can_use    (can_use_wire[i-1][j]),
                    .output_can_use (can_use_wire[i][j]),
                    .valid_out  (PEvalid_wire[i+1][j])
                );
            end
        end
    endgenerate

    // Instantiate the output accumulator
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
                .can_use    (can_use_wire[`PE_ROW-1][k]),
                .output_can_use (can_use_wire[`PE_ROW][k]),
                .valid_out  (PEvalid_wire[`PE_ROW+1][k])
            );
        end
    endgenerate




endmodule