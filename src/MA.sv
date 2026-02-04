module MA #( parameter SIZE = 1024 )
  ( input  wire         clk
  , input  addr_t       address
  , input  data_t       write_data
  , input  wire   [3:0] write_enable
  , output data_t       read_data
  );

  reg [31:0] M[0:SIZE -1];

  localparam int WORDS = SIZE;
  localparam int IDX_W = (WORDS <= 1) ? 1 : $clog2(WORDS);
  wire [IDX_W-1:0] word_idx = address[IDX_W+1:2]; // word address bits (byte addr -> word idx)


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
    read_data <= M[word_idx]; // 2 LSBs used for byte addressing

    if (write_enable[0]) M[word_idx][7:0]   <= write_data[7:0];
    if (write_enable[1]) M[word_idx][15:8]  <= write_data[15:8];
    if (write_enable[2]) M[word_idx][23:16] <= write_data[23:16];
    if (write_enable[3]) M[word_idx][31:24] <= write_data[31:24];
  end

endmodule
