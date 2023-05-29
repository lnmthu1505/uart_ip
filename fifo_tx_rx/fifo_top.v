`timescale 1ns/10ps
module fifo_top #(
   parameter WIDTH  = 8,
   parameter ASIZE  = 4
) (
   input  wire             wrt_clk  , // write  Clock
   input  wire             rd_clk   , // read clock 
   input  wire             rst_n    , // neg reset 
   input  wire             wrt_en   , // write_enable
   input  wire             rd_en    , // read enable 
   input  wire [WIDTH-1:0] data_in  , // Data 8-bit Input
   output                  empty    , // Empty signal
   output                  full     , // Full signal 
   output      [WIDTH-1:0] data_out   // Data 8-bit Output
);
   wire [ASIZE-1:0] rd_addr, wr_addr; 
   wire [ASIZE  :0] wptr, rptr, s_wptr, s_rptr;   
   assign renb_mem = rd_en & !empty; 
   assign wenb_mem = wrt_en & !full; 

   fifo_mem #(WIDTH,ASIZE) u_fifo_mem (
                           .wrt_clk  (wrt_clk    ),
                           .rd_clk   (rd_clk     ),  
                           .rst_n    (rst_n      ),
                           .rd_en    (renb_mem   ),  
                           .wrt_en   (wenb_mem   ), 
                           .rd_addr  (rd_addr    ),
                           .wr_addr  (wr_addr    ),
                           .data_in  (data_in    ),
                           .data_out (data_out   )
   ); 

   syn_w2r #(ASIZE)        u_syn_w2r (           
                           .wptr     (wptr       ),     
                           .rclk     (rd_clk     ), 
                           .rrst_n   (rst_n      ),  
                           .s_wptr   (s_wptr     )  
   ); 
   syn_r2w #(ASIZE)        u_syn_r2w (           
                           .rptr     (rptr       ),     
                           .wclk     (wrt_clk    ), 
                           .wrst_n   (rst_n      ),  
                           .s_rptr   (s_rptr     )  
   ); 
 
   rptr_empty #(ASIZE)     u_rptr_empty (           
                           .rd_en  (rd_en      ),
                           .rd_clk (rd_clk     ),
                           .rrst_n (rst_n      ),
                           .s_wptr (s_wptr     ),
                           .rempty (empty      ),
                           .raddr  (rd_addr    ),
                           .rptr   (rptr       )
   );
 
   wptr_full #(ASIZE)     u_wptr_full (
                           .wrt_en (wrt_en   ),
                           .wrt_clk(wrt_clk  ),
                           .wrst_n (rst_n    ),
                           .s_rptr (s_rptr   ),
                           .wfull  (full     ),
                           .waddr  (wr_addr  ),
                           .wptr   (wptr     )
   ); 
endmodule

