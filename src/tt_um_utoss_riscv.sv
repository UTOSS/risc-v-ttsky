/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

`include "utoss-risc-v/src/types.svh"

module tt_um_utoss_riscv (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  // assign uo_out  = memory__address[7:0];  // Example: ou_out is the sum of ui_in and uio_in
  assign uo_out[3:0] = 4'b0000;
  assign uo_out[7:5] = 3'b000;
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire         _unused = &{ena, 1'b0};

  wire [7:0] uart_rx_data;
  wire       uart_rx_valid;
  wire       uart_rx_ready;

  wire [7:0] uart_tx_data;
  wire       uart_tx_valid;
  wire       uart_tx_ready;

  wire       tx_busy, rx_busy, rx_overrun, rx_frame;

  addr_t core_addr;
  data_t core_write_data;
  logic [3:0] core_write_enable;

  logic [31:0] dbg_regs [0:31];
  addr_t       dbg_pc;

  uart  #(
        .DATA_WIDTH(8)
      , .CLK_HZ(50000000)
      , .BAUD(115200)
  )
  u_uart (
        .clk                ( clk           )
      , .rst                ( rst_n         )
      , .i_data_s           ( uart_tx_data  )
      , .i_valid_s          ( uart_tx_valid )
      , .o_ready_s          ( uart_tx_ready )
      , .o_data_m           ( uart_rx_data  )
      , .o_valid_m          ( uart_rx_valid )
      , .i_ready_m          ( uart_rx_ready )
      , .i_rxd              ( ui_in[3]      )
      , .o_txd              ( uo_out[4]     )
      , .o_tx_busy          ( tx_busy       )
      , .o_rx_busy          ( rx_busy       )
      , .o_rx_overrun_error ( rx_overrun    )
      , .o_rx_frame_error   ( rx_frame      )
  );

  logic [31:0]  dbg_addr, dbg_write_data;
  logic [3:0]   dbg_write_enable;
  wire  [31:0]  read_data;

  logic hold_core;

  uart_bus_master u_master (
        .clk                 ( clk              )
      , .rst                 ( rst_n            )
      , .rx_data             ( uart_rx_data     )
      , .rx_valid            ( uart_rx_valid    )
      , .rx_ready            ( uart_rx_ready    )
      , .tx_data             ( uart_tx_data     )
      , .tx_valid            ( uart_tx_valid    )
      , .tx_ready            ( uart_tx_ready    )
      , .bus_addr            ( dbg_addr         )
      , .bus_write_data      ( dbg_write_data   )
      , .bus_write_enable    ( dbg_write_enable )
      , .bus_read_data       ( read_data        )
      , .dbg_regs            ( dbg_regs         )
      , .dbg_pc              ( dbg_pc           )
      , .hold_core           ( hold_core        )
  );

  wire core_reset = rst_n | hold_core;

  addr_t bus_addr;
  data_t bus_write_data;
  logic [3:0] bus_write_enable;

  assign bus_addr  = hold_core ? dbg_addr  : core_addr;
  assign bus_write_data = hold_core ? dbg_write_data : core_write_data;
  assign bus_write_enable = hold_core ? dbg_write_enable : core_write_enable;

  MA #( .SIZE ( 16 ) )
    memory
      ( .clk          ( clk                  )
      , .address      ( bus_addr             )
      , .write_data   ( bus_write_data       )
      , .write_enable ( bus_write_enable     )
      , .read_data    ( read_data            )
      );

  utoss_riscv core
    ( .clk                 ( clk                  )
    , .reset               ( ~core_reset          )
    , .memory__address     ( core_addr            )
    , .memory__write_data  ( core_write_data      )
    , .memory__write_enable( core_write_enable    )
    , .memory__read_data   ( read_data            )
    , .dbg_regs            ( dbg_regs             )
    , .dbg_pc              ( dbg_pc               )
    );

endmodule
