`timescale 1ns/10ps
module syn_w2r #(
   parameter ASIZE = 4
) 
( 
   input  wire [ASIZE:0] wptr   ,
   input  wire           rclk   , 
   input  wire           rrst_n , 
   output reg [ASIZE:0]  s_wptr
); 
   reg [ASIZE:0] tmp_wptr;
   always @(posedge rclk or negedge rrst_n) begin
      if (!rrst_n) begin 
         {s_wptr,tmp_wptr} <= 0;
      end else begin 
         {s_wptr,tmp_wptr} <= {tmp_wptr,wptr};
      end 
   end 

endmodule
