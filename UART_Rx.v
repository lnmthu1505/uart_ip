`timescale 1ns/10ps

module UART_Rx (input wire        BCLK,
                input wire        rst_n,
                input wire        EPS,
                input wire        PEN,
                input wire        STB,
                input wire  [1:0] WLS,
                input wire        OSM_SEL,
                input wire        UART_RXD,
                output reg        DATA_VALID,
                output reg  [7:0] DATA_RX);

//configuration varibale
reg       eps;
reg       pen;
reg [1:0] stb;
reg [2:0] wls;
reg [3:0] osm_sel;
reg [2:0] half_osm_sel;
reg       reg_uart_rxd;
reg       reg_data_valid;

//state declarartion
parameter [4:0] IDLE   = 5'b00001;
parameter [4:0] START  = 5'b00010;
parameter [4:0] DATA   = 5'b00100;
parameter [4:0] STOP   = 5'b01000;
parameter [4:0] PARITY = 5'b10000;

//present variable
reg [3:0] cnt;
reg [2:0] width_data;
reg [1:0] width_stop;
reg       parity_check;
reg [7:0] reg_out;
reg [4:0] present_state;

//next varibale
reg [3:0] next_cnt;
reg [2:0] next_width_data;
reg [1:0] next_width_stop;
reg       next_parity_check;
reg [7:0] next_reg_out;
reg       parity;
reg [4:0] next_state;

//FF at INPUT
always@(posedge BCLK or negedge rst_n) begin
   if (!rst_n) begin
      reg_uart_rxd <= 1'b1;
   end else begin
      reg_uart_rxd <= UART_RXD;
   end
end
//FF at Output
always@(posedge BCLK or negedge rst_n) begin
   if (!rst_n) begin
      DATA_RX <= 8'h00;
   end else begin
      DATA_RX <= reg_out;
   end
end

always@(posedge BCLK or negedge rst_n) begin
   if (!rst_n) begin
      DATA_VALID <= 1'b0;
   end else begin
      DATA_VALID <= reg_data_valid;
   end 
end

//configuration controller
always@(posedge BCLK or negedge rst_n) begin
   if(!rst_n) begin
      osm_sel <= 4'd000;
      half_osm_sel <= 3'd00;
   end else begin
      if (OSM_SEL) begin
         osm_sel      <= 4'd12;
         half_osm_sel <= 3'd5;
      end else begin
         osm_sel      <= 4'd15;
         half_osm_sel <= 3'd7; 
      end
   end
end

always@(posedge BCLK or negedge rst_n) begin
   if (!rst_n) begin
      eps <= 0;
   end else begin
      if (EPS) begin
         eps <= 1; //even check
      end else begin
         eps <= 0; //odd check
      end
   end
end

always@(posedge BCLK or negedge rst_n) begin
   if (!rst_n) begin
      pen <= 0;
   end else begin
      if (PEN) begin
         pen <= 1; //parity mode
      end else begin
         pen <= 0; //no parity
      end
   end
end

always@(posedge BCLK or negedge rst_n) begin
   if (!rst_n) begin
      stb <= 2'b00;
   end else begin
      if (STB) begin
        stb <= 2'b01; //2 stop bit
      end else begin
        stb <= 2'b00; //1 stop bit
      end
   end
end

always@(posedge BCLK or negedge rst_n) begin
   if (!rst_n) begin
      wls <= 3'b000;
   end else begin
      case (WLS)
         2'b00: begin
                   wls <= 3'b100; // 5 bit data
                end
         2'b01: begin
                   wls <= 3'b101; // 6 bit data
                end
         2'b10: begin
                   wls <= 3'b110; // 7 bit data
                end
         2'b11: begin
                   wls <= 3'b111; // 8 bit data
                end
      endcase
   end
end

//FSM Controller
//presen state
always@(posedge BCLK or negedge rst_n) begin
   if (!rst_n) begin
      present_state <= IDLE;
      cnt           <= 4'b0000;
      width_data    <= 3'b000;
      width_stop    <= 2'b00;
      parity_check  <= 1'b0;
      reg_out       <= 8'h00;
   end else begin
      present_state <= next_state;
      cnt           <= next_cnt;
      width_data    <= next_width_data;
      width_stop    <= next_width_stop;
      parity_check  <= next_parity_check;
      reg_out       <= next_reg_out;
   end
end

//next state
always@(*) begin
   case (present_state)
      IDLE: begin
               next_width_stop   = 2'b00;
               next_parity_check = 1'b0;
               next_width_data   = 3'b000;
               parity            = 1'b0;
               if (reg_uart_rxd == 1) begin
                  next_state     = IDLE;
                  reg_data_valid = 1'b0;
                  next_reg_out   = 8'h00;
                  next_cnt       = cnt;
               end else begin
                  next_state     = START;
                  reg_data_valid = 1'b0;
                  next_reg_out   = 8'h00;
                  next_cnt       = 4'b0000;
               end
            end
     START: begin
               next_width_data     = 3'b000;
               next_width_stop     = 2'b00;
               next_reg_out        = 8'h00;
               next_parity_check   = 1'b0;
               parity              = 1'b0;
               reg_data_valid      = 1'b0;
               if (cnt == half_osm_sel) begin
                  next_cnt         = 4'b0000;
                  next_state       = DATA;
               end else begin
                  next_cnt = cnt + 1;  
                  if (reg_uart_rxd == 0) begin //reg_uart_rxd still zero ?
                     next_state    = START;
                  end else begin
                     next_state    = IDLE;
                  end
               end
            end
      DATA: begin
               parity                = 1'b0;
               reg_data_valid        = 1'b0;
               next_width_stop       = 2'b00;
               if (cnt == osm_sel) begin
                  next_cnt           = 4'b0000;
                  next_reg_out       = {reg_uart_rxd, reg_out[7:1]};//, reg_uart_rxd};
                  next_parity_check  = parity_check ^ reg_uart_rxd;
                  if (width_data == wls) begin
                     next_width_data = 3'b000;
                     if (pen == 1) begin
                        next_state   = PARITY;
                     end else begin
                        next_state   = STOP;
                     end
                  end else begin
                     next_width_data = width_data + 1;
                     next_state      = DATA;
                  end
               end else begin
                  next_cnt           = cnt + 1;
                  next_state         = DATA;
                  next_parity_check  = parity_check;
                  next_width_data    = width_data;
                  next_reg_out       = reg_out;
               end
            end
    PARITY: begin
               reg_data_valid        = 1'b0;
               next_reg_out          = reg_out;
               next_width_stop       = 2'b00;
               next_width_data       = 3'b000;
               if (cnt == osm_sel) begin
                  next_cnt           = 4'b0000;
                  parity             = reg_uart_rxd;
                  case({eps, parity, parity_check})
                     3'b000: begin
                                next_state = IDLE;
                                next_parity_check = 0;
                             end
                     3'b001: begin
                                next_state = STOP;
                                next_parity_check = 0;
                             end
                     3'b010: begin
                                next_state = STOP;
                                next_parity_check = 0;

                             end
                     3'b011: begin
                                next_state = IDLE;
                                next_parity_check = 0;
                             end
                     3'b100: begin
                                next_state = STOP;
                                next_parity_check = 0;
                             end
                     3'b101: begin
                                next_state = IDLE;
                                next_parity_check = 0;
                             end
                     3'b110: begin
                                next_state = IDLE;
                                next_parity_check = 0;
                             end
                     3'b111: begin
                                next_state = STOP;
                                next_parity_check = 0;
                             end
                  endcase
               end else begin
                  next_state         = PARITY;
                  next_cnt           = cnt + 1;
                  next_parity_check  = parity_check;
                  parity             = parity;
               end
            end
      STOP: begin
               next_reg_out          = reg_out;
               parity                = 1'b0;
               next_width_data       = 3'b000;
               next_parity_check     = parity_check;
               if (cnt == osm_sel) begin
                  if (reg_uart_rxd == 1) begin
                     if (width_stop == stb) begin
                        reg_data_valid           = 1'b1;
                        next_state      = IDLE;
                        next_width_stop = 2'b00;
                        next_cnt        = 4'b0000;
                     end else begin
                        reg_data_valid  = 1'b0;
                        next_width_stop = width_stop + 1;
                        next_state      = STOP;
                        next_cnt        = 4'b0000;
                     end
                  end else begin
                     reg_data_valid     = 1'b0;
                     next_state         = IDLE;
                     next_width_stop    = 2'b00;
                     next_cnt           = 4'b0000;
                  end
               end else begin
                  next_cnt           = cnt + 1;
                  reg_data_valid     = 1'b0;
                  next_width_stop    = width_stop;
                  next_state         = STOP;
               end
            end
   default: begin
                  next_state        = IDLE;
                  next_cnt          = 4'b1111;
                  next_width_data   = 3'b111;
                  next_width_stop   = 2'b11;
                  next_parity_check = 1'b1;
                  next_reg_out      = 8'hFF;
                  reg_data_valid    = 1'b0;
                  parity            = 1'b0;
            end
   endcase
end

//assign DATA_RX = reg_out;

endmodule
