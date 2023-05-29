`timescale 1ns/10ps
module baud_gen #(
    parameter WIDTH = 16
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             enable,
    input  wire             rate_sel,
    input  wire [WIDTH-1:0] dvsr,
    output wire             bclk
);
    wire  [WIDTH-1:0] nx;
    reg  [WIDTH-1:0] pr;
    wire [WIDTH-1:0] dvsr_tmp;

    always @(posedge clk, negedge rst_n) begin
       if (!rst_n) begin
           pr <= 0;
       end
       else begin
         if (enable) begin
             pr <= nx;
          end
          else begin
             pr <= 0;
          end
       end        
    end

    assign dvsr_tmp = (rate_sel)? 0 : dvsr;
    // Next-state Logic
    assign nx = (pr >= dvsr_tmp - 1)? 0 : pr + 1;
    // Output Logic
    assign bclk = (pr == 1);
endmodule
