`timescale 1ns/10ps
module rptr_empty #(
   parameter ASIZE = 4
)
(  input  wire             rd_en  ,
   input  wire             rd_clk   , 
   input  wire             rrst_n , 
   input  wire [ASIZE:0]   s_wptr , 
   output reg              rempty ,
   output      [ASIZE-1:0] raddr  ,
   output reg  [ASIZE :0]  rptr
);
   reg  [ASIZE:0] bin;
   wire [ASIZE:0] gnext, bnext;
   wire empty_val ; 
   
   always @(posedge rd_clk or negedge rrst_n) begin
      if (!rrst_n) begin 
         {bin, rptr} <= 0;
      end else begin 
         {bin, rptr} <= {bnext, gnext};
      end 
   end 

   assign raddr = bin[ASIZE-1:0];
   assign bnext = bin + (rd_en & ~rempty);
   assign gnext = (bnext>>1) ^ bnext;


   assign empty_val = (gnext == s_wptr);
   always @(posedge rd_clk or negedge rrst_n) begin 
      if (!rrst_n) begin 
         rempty <= 1'b1;
      end else begin  
         rempty <= empty_val;
      end 
   end 
endmodule
