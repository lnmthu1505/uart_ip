`timescale 1ns/10ps
module wptr_full #(
   parameter ASIZE = 4
)
(  input  wire             wrt_en ,
   input  wire             wrt_clk   , 
   input  wire             wrst_n , 
   input  wire [ASIZE:0]   s_rptr , 
   output reg              wfull  ,
   output      [ASIZE-1:0] waddr  ,
   output reg  [ASIZE :0]  wptr
);
   reg  [ASIZE:0] bin;
   wire [ASIZE:0] gnext, bnext;
   wire full_val ; 
   
   always @(posedge wrt_clk or negedge wrst_n) begin 
      if (!wrst_n) begin 
         {bin, wptr} <= 0;
      end else begin 
         {bin, wptr} <= {bnext, gnext};
      end 
   end 

   assign waddr = bin[ASIZE-1:0];
   assign bnext = bin + (wrt_en & ~wfull);
   assign gnext = (bnext>>1) ^ bnext;
  
   assign full_val = (gnext == {~s_rptr[ASIZE:ASIZE-1],s_rptr[ASIZE-2:0]} );
   always @(posedge wrt_clk or negedge wrst_n) begin 
      if (!wrst_n) begin 
         wfull <= 1'b0;
      end else begin  
         wfull <= full_val;
      end 
   end 
endmodule
