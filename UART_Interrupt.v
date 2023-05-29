`timescale 1ns/10ps


module UART_Interrupt (input wire        en_rx_fifo_empty,
                       input wire        en_rx_fifo_full,
                       input wire        en_tx_fifo_empty,
                       input wire        en_tx_fifo_full,
                       input wire        rx_fifo_empty,
                       input wire        rx_fifo_full,
                       input wire        tx_fifo_empty,
                       input wire        tx_fifo_full,
                       output wire [3:0] IRQs);

assign IRQs[0] = en_rx_fifo_empty & rx_fifo_empty;
assign IRQs[1] = en_rx_fifo_full & rx_fifo_full;
assign IRQs[2] = en_tx_fifo_empty & tx_fifo_empty;
assign IRQs[3] = en_tx_fifo_full & tx_fifo_full;

endmodule
