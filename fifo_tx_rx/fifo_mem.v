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
   output wire [WIDTH-1:0] data_out   //  Data 8-bit Output
); //cadence black_box  

   parameter DEPTH = 1 << ASIZE; 
   reg [WIDTH-1 : 0] mem [0:DEPTH-1];
   reg [WIDTH-1:0] tmp_data_out;
   //reg tmp_wrt_en;
   assign data_out = rd_en ? tmp_data_out : mem[rd_addr];//data_out;

   always @(posedge rd_clk or negedge rst_n) begin
      if (!rst_n) begin
         tmp_data_out <= 8'h00; 
      end else begin
         //if (rd_en) begin
            tmp_data_out <= mem[rd_addr];
         //end else begin
         //   data_out <= data_out;
         //end
      end
   end 
   /*always@(posedge wrt_clk or negedge rst_n) begin
      if (!rst_n) begin
         tmp_wrt_en <= 1'b0;
      end else begin
         tmp_wrt_en <= wrt_en;
      end
   end*/
   always @(posedge wrt_clk or negedge rst_n) begin
      if (!rst_n) begin
            mem[wr_addr] <= 8'h00; 
      end else begin
         if (wrt_en) begin
            mem[wr_addr] <= data_in;   
         end else begin
            mem[wr_addr] <= mem[wr_addr];
         end
      end
   end

endmodule
