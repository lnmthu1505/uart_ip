`timescale 1ns/10ps
module uart_tx (
   input wire       bclk,
   input wire       rst_n,
   input wire [7:0] tx_din,
   input wire       tx_start,
   input wire       rate_sel,
   input wire       pen,
   input wire       eps,
   input wire       stb,
   input wire [1:0] wls,
   output reg       tx_done,
   output reg       tx
);
   
   // Internal signals
   reg  [7:0]  tx_din_s1;
   reg  [7:0]  tx_reg;
   reg  [7:0]  tx_next;
   reg         tx_start_s1;
   reg         rate_sel_s1;
   reg         pen_s1;
   reg         eps_s1;
   reg         stb_s1;
   reg  [1:0]  wls_s1;
   reg  [2:0]  current_state;
   reg  [2:0]  next_state;
   reg  [3:0]  count;
   reg  [2:0]  bit_num;
   wire        hold_done;
   wire        bit_done;
   wire        data_frame_done;
   wire        stop_done;
   reg         tx_tmp;
   wire        tx_done_tmp;
   wire        clr_counter;
   wire [3:0]  DBIT;
   wire [3:0]  SBIT;
   wire [3:0]  HBIT;
   wire [2:0]  NBIT;

   // State encode
   parameter [2:0] IDLE   = 3'd0;
   parameter [2:0] HOLD   = 3'd1;
   parameter [2:0] SHIFT  = 3'd2;
   parameter [2:0] PARITY = 3'd3;
   parameter [2:0] STOP_1 = 3'd4;
   parameter [2:0] STOP_2 = 3'd5;

   // Front ff
   always @(posedge bclk, negedge rst_n) begin
      if(!rst_n) begin
         tx_din_s1   <= 0;
         tx_start_s1 <= 0; 
         rate_sel_s1 <= 0; 
         pen_s1      <= 0; 
         eps_s1      <= 0; 
         stb_s1      <= 0; 
         wls_s1      <= 0; 
      end
      else begin
         tx_din_s1   <= tx_din;
         tx_start_s1 <= tx_start;
         rate_sel_s1 <= rate_sel;
         pen_s1      <= pen;
         eps_s1      <= eps;
         stb_s1      <= stb;
         wls_s1      <= wls;
      end
   end

   // State memory
   always @(posedge bclk, negedge rst_n) begin
      if (!rst_n) begin
         current_state <= IDLE;
      end
      else begin
         current_state <= next_state;
      end
   end

   // Next-state logic
   always @(*) begin
      case (current_state)
         IDLE: begin
            if (tx_start_s1) begin
               next_state = HOLD;
            end
            else begin
               next_state = current_state;
            end
         end
         HOLD: begin
            if (hold_done) begin
               next_state = SHIFT;
            end
            else begin
               next_state = current_state;
            end
         end
         SHIFT: begin
            case ({data_frame_done,pen_s1})
               2'b11: begin
                  next_state = PARITY;
               end
               2'b10: begin
                  next_state = STOP_1;
               end
               default: next_state = current_state;
            endcase
         end
         PARITY: begin
            if (bit_done) begin
               next_state = STOP_1;
            end
            else begin
               next_state = current_state;
            end
         end
         STOP_1: begin
            case ({stop_done,stb_s1})
               2'b11: begin
                  next_state = STOP_2;
               end
               2'b10: begin
                  next_state = IDLE;
               end
               default: next_state = current_state;
            endcase
         end
         STOP_2: begin
            if (stop_done) begin
               next_state = IDLE;
            end
            else begin
               next_state = current_state;
            end
         end
         default: next_state = current_state;
      endcase
   end

   // Output logic
   always @(*) begin
      case (current_state)
         IDLE: begin
            tx_tmp = 1'b1;
         end
         HOLD: begin
            tx_tmp = 1'b0;
         end
         SHIFT: begin
            tx_tmp = tx_reg[0];
         end
         PARITY: begin
            tx_tmp = ~(^(tx_din_s1) ^ eps_s1);
         end
         STOP_1: begin
            tx_tmp = 1'b1;
         end
         STOP_2: begin
            tx_tmp = 1'b1;
         end
         default: tx_tmp = 1'b1;
      endcase
   end

   // Sampling rate define
   assign {DBIT,SBIT,HBIT} = (!rate_sel_s1)? {4'd15,4'd15,4'd15} : {4'd12,4'd12,4'd12};

   // Shifting register
   always @(posedge bclk, negedge rst_n) begin
      if (!rst_n) begin
         tx_reg <= 8'b0;
      end
      else begin
         tx_reg <= tx_next;
      end
   end

   always @(*) begin
      case (current_state)
         HOLD: begin
            if (tx_start_s1) begin
               tx_next = tx_din_s1;
            end
            else begin
               tx_next = tx_reg;
            end
         end
         SHIFT: begin
            if (bit_done) begin
               tx_next = {1'b0,tx_reg[7:1]};
            end
            else begin
               tx_next = tx_reg;
            end
         end
         default: tx_next = tx_reg;
      endcase
   end

   // Sampling rate define
   assign {DBIT,SBIT,HBIT} = (!rate_sel_s1)? {4'd15,4'd15,4'd15} : {4'd12,4'd12,4'd12};
   
   // Counter
   always @(posedge bclk, negedge rst_n) begin
      if (!rst_n) begin
         count <= 4'd0;
      end
      else begin
         if (clr_counter || current_state == IDLE) begin
            count <= 4'd0;
         end
         else begin
            count <= count + 4'd1;
         end
      end
   end
   assign bit_done    = (current_state == SHIFT  || current_state == PARITY) & (count == DBIT);
   assign stop_done   = (current_state == STOP_1 || current_state == STOP_2) & (count == SBIT);
   assign hold_done   = (current_state == HOLD)  &  (count == HBIT);
   assign clr_counter = bit_done | stop_done | hold_done;
   
   // WLS encode
   assign NBIT = (wls_s1 == 2'b00)? 3'd4 : (wls_s1 == 2'b01)? 3'd5 : 
                          (wls_s1 == 2'b10)? 3'd6 : (wls_s1 == 2'b11)? 3'd7 : 3'd7;
   
   // Data Bit counter
   always @(posedge bclk, negedge rst_n) begin
      if (!rst_n) begin
         bit_num <= 0;
      end
      else begin
         if (data_frame_done) begin
            bit_num <= 0;
         end
         else begin
            if (bit_done && current_state != PARITY) begin
               bit_num <= bit_num + 3'd1;
            end
         end
      end
   end
   assign data_frame_done = (bit_num == NBIT) & bit_done;

   // Done flag define
   assign tx_done_tmp = ((!stb_s1 & (current_state == STOP_1)) | (stb_s1 & (current_state == STOP_2))) & (count == SBIT);

   // Back ff
   always @(posedge bclk, negedge rst_n) begin
      if (!rst_n) begin
         tx      <= 1'b1;
         tx_done <= 1'b0;
      end
      else begin
         tx      <= tx_tmp;
         tx_done <= tx_done_tmp;
      end
   end

   //always @(*) begin
   //   tx_done = tx_done_tmp;
   //end
endmodule
