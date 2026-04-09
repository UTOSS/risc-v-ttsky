module MA #( parameter SIZE = 1024 )
  ( 
`ifdef USE_POWER_PINS
    input             VPWR,
    input             VGND,
`endif
    input  wire         clk
  , input  addr_t       address
  , input  data_t       write_data
  , input  wire   [3:0] write_enable
  , output data_t       read_data
  );
`ifdef __pnr__

    wire [4:0] ram_addr;
    assign ram_addr = {1'b0, address[5:2]};

    RAM32 ram_macro (
`ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
`endif
        .CLK(clk),
        .EN0(1'b1),
        .A0(ram_addr),
        .WE0(write_enable),
        .Di0(write_data),
        .Do0(read_data)
    );

`else
  reg [31:0] M[0:SIZE -1];

`ifndef UTOSS_RISCV_HARDENING
  initial begin
    string mem_file;

    if ($value$plusargs("MEM=%s", mem_file)) begin
      $display("loading memory from <%s>", mem_file);
      $readmemh(mem_file, M);
      $display("memory loaded");
    end
  end
`endif

  always @(posedge clk) begin
    read_data <= M[address[31:2]]; // 2 LSBs used for byte addressing

    if (write_enable[0]) M[address[31:2]][7:0]   <= write_data[7:0];
    if (write_enable[1]) M[address[31:2]][15:8]  <= write_data[15:8];
    if (write_enable[2]) M[address[31:2]][23:16] <= write_data[23:16];
    if (write_enable[3]) M[address[31:2]][31:24] <= write_data[31:24];
  end
  
`endif

endmodule
