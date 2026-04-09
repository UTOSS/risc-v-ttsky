`default_nettype none

module RAM32 (
`ifdef USE_POWER_PINS
    input  wire        VPWR,
    input  wire        VGND,
`endif
    input  wire        CLK,
    input  wire [3:0]  WE0,
    input  wire        EN0,
    input  wire [4:0]  A0,
    input  wire [31:0] Di0,
    output reg  [31:0] Do0
);

    reg [31:0] mem [0:31];

    always @(posedge CLK) begin
        if (EN0) begin
            Do0 <= mem[A0];
            if (WE0[0]) mem[A0][7:0]   <= Di0[7:0];
            if (WE0[1]) mem[A0][15:8]  <= Di0[15:8];
            if (WE0[2]) mem[A0][23:16] <= Di0[23:16];
            if (WE0[3]) mem[A0][31:24] <= Di0[31:24];
        end
        else begin
            Do0 <= 32'b0;
        end
    end

endmodule