// NewCSR CSR-field primitive: tvec (trap-vector base-address CSR).
//
// Faithful, readable, parameterized reimplementation of the golden tvec family
// (MtvecModule, StvecModule, VStvecModule — all three golden modules are
// byte-identical). A tvec CSR splits into {addr[63:2], mode[1:0]}:
//
//   * mode is WARL: only the Direct (2'h0) and Vectored (2'h1) encodings are
//     accepted; reserved modes (2/3) leave reg_mode unchanged (the golden write
//     enable is `w_wen & (mode==1 | mode==0)`).
//   * addr[61:0] is a plain register written on any w_wen.
//   * both async-reset to 0.
//   * rdata = {reg_addr, reg_mode}.

module xs_tvec (
    input         clock,
    input         reset,
    input         w_wen,
    input  [63:0] w_wdata,
    output [63:0] rdata,
    output [1:0]  regOut_mode,
    output [61:0] regOut_addr
);

  reg [1:0]  reg_mode;
  reg [61:0] reg_addr;

  // WARL: accept only mode ∈ {Direct(0), Vectored(1)}.
  wire mode_legal = (w_wdata[1:0] == 2'h1) | (w_wdata[1:0] == 2'h0);

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_mode <= 2'h0;
      reg_addr <= 62'h0;
    end
    else begin
      if (w_wen & mode_legal)
        reg_mode <= w_wdata[1:0];
      if (w_wen)
        reg_addr <= w_wdata[63:2];
    end
  end

  assign rdata       = {reg_addr, reg_mode};
  assign regOut_mode = reg_mode;
  assign regOut_addr = reg_addr;

endmodule
