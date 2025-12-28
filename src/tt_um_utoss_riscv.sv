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
  assign uo_out  = memory__address[7:0];  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire         _unused = &{ena, 1'b0};

  addr_t       memory__address;
  data_t       memory__write_data;
  logic  [3:0] memory__write_enable;
  data_t       memory__read_data;

  MA #( .SIZE ( 16 ) )
    memory
      ( .clk          ( clk                  )
      , .address      ( memory__address      )
      , .write_data   ( memory__write_data   )
      , .write_enable ( memory__write_enable )
      , .read_data    ( memory__read_data    )
      );

  utoss_riscv core
    ( .clk                 ( clk                  )
    , .reset               ( ~rst_n               )
    , .memory__address     ( memory__address      )
    , .memory__write_data  ( memory__write_data   )
    , .memory__write_enable( memory__write_enable )
    , .memory__read_data   ( memory__read_data    )
    );

endmodule
