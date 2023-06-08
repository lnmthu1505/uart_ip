`timescale 1ns/10ps


module regs_bank #(
   parameter APB_ADDR_WIDTH = 8,
   parameter APB_DATA_WIDTH = 8
   )
   (
   output wire [APB_DATA_WIDTH-1:0] MDR,
   output wire [APB_DATA_WIDTH-1:0] DLL,
   output wire [APB_DATA_WIDTH-1:0] DLH,
   output wire [APB_DATA_WIDTH-1:0] LCR,
   output wire [APB_DATA_WIDTH-1:0] IER,
   output wire [APB_DATA_WIDTH-1:0] TBR,
   input  wire [APB_DATA_WIDTH-1:0] FSR,
   input  wire [APB_DATA_WIDTH-1:0] RBR,

   //APB interface
   input  PCLK,
   input  PRESETN,
   input  wire [APB_ADDR_WIDTH-1:0] PADDR,
   input  wire [APB_DATA_WIDTH-1:0] PWDATA,
   input  wire PSEL, 
   input  wire PENABLE, 
   input  wire PWRITE,
   output wire [APB_DATA_WIDTH-1:0] PRDATA,
   output wire PREADY,
   output wire PSLVERR
   );

   reg [APB_ADDR_WIDTH-1:0] aw_addr;
   reg [APB_ADDR_WIDTH-1:0] ar_addr;
   reg [APB_DATA_WIDTH-1:0] apb_rdata;
   reg apb_ready;
   reg apb_slverr;
  
   reg fifo_valid;
   
   // local parameter for addressing 8 bit of APB_DATA_WIDTH
   // ADDR_LSB is used for addresssing 8 bit registers/memories
   // ADDR_LSB = 0 (n downto 0)
   localparam integer ADDR_LSB = 4;
   localparam integer OPT_MEM_ADDR_BITS = 3;
   
   //number of slave registers
   reg [APB_DATA_WIDTH-1:0] slv_reg_0;
   reg [APB_DATA_WIDTH-1:0] slv_reg_1;
   reg [APB_DATA_WIDTH-1:0] slv_reg_2;
   reg [APB_DATA_WIDTH-1:0] slv_reg_3;
   reg [APB_DATA_WIDTH-1:0] slv_reg_4;
   reg [APB_DATA_WIDTH-1:0] slv_reg_5;
   reg [APB_DATA_WIDTH-1:0] slv_reg_6;
   reg [APB_DATA_WIDTH-1:0] slv_reg_7;
   reg [APB_DATA_WIDTH-1:0] slv_reg_8;
   reg [APB_DATA_WIDTH-1:0] slv_reg_9;
   reg [APB_DATA_WIDTH-1:0] slv_reg_10;
   reg [APB_DATA_WIDTH-1:0] slv_reg_11;
   reg [APB_DATA_WIDTH-1:0] slv_reg_12;
   reg [APB_DATA_WIDTH-1:0] slv_reg_13;
   reg [APB_DATA_WIDTH-1:0] slv_reg_14;
   reg [APB_DATA_WIDTH-1:0] slv_reg_15;

   wire slv_reg_rden;
   wire slv_reg_wren;
   reg [APB_DATA_WIDTH-1:0] reg_data_out;
   reg [APB_DATA_WIDTH-1:0] reg_pwdata;
   //reg [APB_DATA_WIDTH-1:0] rdata_tmp;
   reg [APB_DATA_WIDTH-1:0] reg_fsr, reg_rbr;

   wire read_domain;
   wire write_domain;

   localparam rx_empty_status = 3;
   localparam rx_full_status  = 2;
   localparam tx_empty_status = 1;
   localparam tx_full_status  = 0;

   assign PREADY  = apb_ready;
   assign PSLVERR = apb_slverr;
   assign PRDATA  = apb_rdata;

   assign slv_reg_wren = PSEL && PENABLE && PWRITE;
   assign slv_reg_rden = PSEL && PENABLE && ~PWRITE;

   assign write_domain = (PADDR[7:4] == 4'h00) || (PADDR[7:4] == 4'h01) ||
                         (PADDR[7:4] == 4'h01) || (PADDR[7:4] == 4'h03) ||
                         (PADDR[7:4] == 4'h04) || (PADDR[7:4] == 4'h06) ;

   assign read_domain  = (PADDR[7:4] == 4'h05) || (PADDR[7:4] == 4'h07) ;

   /*
      Address iss only valid to be considered when PSEL, PENABLE is high
      PWRITE = 1 means that aw_addr receives address from PADDR
      Otherwise, ar_addr receives address from PADDR.
   */
   always @(posedge PCLK, negedge PRESETN) begin
      if(!PRESETN) begin
         aw_addr <= APB_ADDR_WIDTH'('hFF);
         ar_addr <= APB_ADDR_WIDTH'('hFF);
      end
      else begin
         if(PSEL && PENABLE) begin
            if(PWRITE) begin
               aw_addr <= PADDR;
            end
            else begin
               ar_addr <= PADDR;
            end
         end
      end
   end
   
   always @(posedge PCLK, negedge PRESETN) begin
      if(!PRESETN) begin
         reg_pwdata <= APB_ADDR_WIDTH'('hFF);
      end
      else begin
         reg_pwdata <= PWDATA;
      end
   end

   always @(posedge PCLK, negedge PRESETN) begin
      if(!PRESETN) begin
         apb_ready <= 0;
      end
      else begin 
         if(PSEL && ~PENABLE && PWRITE) begin 
            apb_ready <= 0;
         end
         else begin
            if(PSEL && ~PENABLE && ~PWRITE) begin
               apb_ready <= 0;
            end
            else begin
               if(PENABLE && PSEL) begin
                  apb_ready <= 1;
               end
            end
         end   
      end
   end

   /*
      Storing address off each output register.
      When receiving write enable, output has valid data from APB Bus.
      Providing signals and operations for UART logic blocks.
   */
   always @(posedge PCLK, negedge PRESETN) begin
      if(!PRESETN) begin
         fifo_valid      <= 0;
         slv_reg_0       <= 0;
         slv_reg_1       <= 0;
         slv_reg_2       <= 0;
         slv_reg_3       <= 0;
         slv_reg_4[5:0]  <= 6'b000011;
         slv_reg_5       <= 0;
         slv_reg_6[3:0]  <= 4'b1010;
         slv_reg_7       <= 0;
         slv_reg_8       <= 0;
         slv_reg_9       <= 0;
         slv_reg_10      <= 0;
         slv_reg_11      <= 0;
         slv_reg_12      <= 0;
         slv_reg_13      <= 0;
         slv_reg_14      <= 0;
         slv_reg_15      <= 0;
      end
      else begin
         if(slv_reg_wren) begin
            fifo_valid <= 0;
            case(aw_addr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
               4'h0: slv_reg_0  <= reg_pwdata;
               4'h1: slv_reg_1  <= reg_pwdata;
               4'h2: slv_reg_2  <= reg_pwdata;
               4'h3: slv_reg_3  <= reg_pwdata;
               4'h4: slv_reg_4  <= reg_pwdata;
               4'h5: slv_reg_5  <= reg_pwdata;
               4'h6: begin
                  slv_reg_6  <= reg_pwdata;
                  fifo_valid <= 1     ;
               end
               4'h7: slv_reg_7  <= reg_pwdata;
               4'h8: slv_reg_8  <= reg_pwdata;
               4'h9: slv_reg_9  <= reg_pwdata;
               4'hA: slv_reg_10 <= reg_pwdata;
               4'hB: slv_reg_11 <= reg_pwdata;
               4'hC: slv_reg_12 <= reg_pwdata;
               4'hD: slv_reg_13 <= reg_pwdata;
               4'hE: slv_reg_14 <= reg_pwdata;
               4'hF: slv_reg_15 <= reg_pwdata;
            endcase
         end
      end
   end

   /*
      FSR and RBR are outputs generated from UART blocks.
      APB Slave requests to read data from FSR or RBR with corresponding
      address to APB Bus.
   */
   always @(posedge PCLK) begin
      case(ar_addr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
         4'h0: reg_data_out <= slv_reg_0;
         4'h1: reg_data_out <= slv_reg_1;
         4'h2: reg_data_out <= slv_reg_2;
         4'h3: reg_data_out <= slv_reg_3;
         4'h4: reg_data_out <= slv_reg_4;
         4'h5: reg_data_out <= reg_fsr;
         4'h6: reg_data_out <= slv_reg_6;
         4'h7: reg_data_out <= reg_rbr;
         4'h8: reg_data_out <= slv_reg_8;
         4'h9: reg_data_out <= slv_reg_9;
         4'hA: reg_data_out <= slv_reg_10;
         4'hB: reg_data_out <= slv_reg_11;
         4'hC: reg_data_out <= slv_reg_12;
         4'hD: reg_data_out <= slv_reg_13;
         4'hE: reg_data_out <= slv_reg_14;
         4'hF: reg_data_out <= slv_reg_15;
      endcase
   end

   always @(posedge PCLK, negedge PRESETN) begin
      if(!PRESETN) begin
         reg_fsr <= 0;
         reg_rbr <= 0;
      end
      else begin
         reg_fsr <= FSR;
         reg_rbr <= RBR;
      end
   end
   always @(posedge PCLK, negedge PRESETN) begin
      if(!PRESETN) begin
         apb_rdata <= APB_DATA_WIDTH'('b0);
        //rdata_tmp <= APB_DATA_WIDTH'('b0);
      end
      else begin
         if(slv_reg_rden) begin
            apb_rdata <= reg_data_out;
         end
      end
   end

   /*
      Check cases of slave error signal.
      PSLVERR signal is only valid to be considered when
      PSEL, PENABLE and PREADY is high.
      Otherwise, remaining the provious status.
   */
   always @(*) begin
      if(PSEL == 1 && PENABLE == 1 && apb_ready == 1) begin
         if(PWRITE && PADDR[7:4] == 4'h6 && FSR[0] == 1) begin
            apb_slverr = 1;
         end
         else begin
            if(~PWRITE && ar_addr[7:4] == 4'h7 && FSR[rx_empty_status]) begin
               apb_slverr = 1;
            end
            else begin
               if(PADDR[7] == 1) begin
                  apb_slverr = 1;
               end
               else begin
                  if(~PWRITE && write_domain) begin
                     apb_slverr = 1;
                  end         
                  else begin
                     if(PWRITE && read_domain) begin
                        apb_slverr = 1;
                     end
                     else begin
                        apb_slverr = 0;
                     end
                  end
               end
            end
         end
      end
      else begin
         apb_slverr = apb_slverr;
      end
   end
   

   //user logic assignments
   assign MDR = slv_reg_0;
   assign DLL = slv_reg_1;
   assign DLH = slv_reg_2;
   assign LCR = slv_reg_3;
   assign IER = slv_reg_4;
   assign TBR = slv_reg_6;
endmodule
