`timescale 1ns/10ps
module syn_r2w #(
   parameter ASIZE = 4
) 
( 
   input wire [ASIZE:0] rptr   , 
   input wire           wclk   , 
   input wire           wrst_n , 
   output reg [ASIZE:0] s_rptr
); 
   reg [ASIZE:0] tmp_rptr;
   always @(posedge wclk or negedge wrst_n) begin 
      if (!wrst_n) begin 
         {s_rptr,tmp_rptr} <= 0;
      end else begin 
         {s_rptr,tmp_rptr} <= {tmp_rptr,rptr};
      end 
   end 

endmodule
