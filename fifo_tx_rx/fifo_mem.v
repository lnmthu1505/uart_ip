`timescale 1ns/10ps
module fifo_mem #(  
   parameter WIDTH  = 8,
   parameter ASIZE  = 4
) (
   input  wire             wrt_clk      , // Clock 
   input  wire             rd_clk       , // Clock 
   input  wire             rst_n     , // neg reset 
   input  wire             rd_en     , // full
   input  wire             wrt_en    , // write_enable 
   input  wire [ASIZE-1:0] rd_addr   , // Read address
   input  wire [ASIZE-1:0] wr_addr   , // write address 
   input  wire [WIDTH-1:0] data_in   , // Data 8-bit Input
   output reg  [WIDTH-1:0] data_out   //  Data 8-bit Output
); //cadence black_box  

   parameter DEPTH = 1 << ASIZE; 
   reg [WIDTH-1 : 0] mem [0:DEPTH-1]; 
   
   always @(posedge rd_clk or negedge rst_n) begin
      if (!rst_n) begin
            data_out <= 16'h0; 
      end else begin
         if (rd_en) begin
            data_out <= mem[rd_addr];   
         end
      end
   end 
   
   always @(posedge wrt_clk or negedge rst_n) begin
      if (!rst_n) begin
            mem[wr_addr] <= 16'h0; 
      end else begin
         if (wrt_en) begin
            mem[wr_addr] <= data_in;   
         end
      end
   end

endmodule

