// SatpModule.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_SatpModule_core(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic [3:0]  regOut_MODE,
  output logic [15:0] regOut_ASID,
  output logic [43:0] regOut_PPN
);
logic [3:0]  reg_MODE;
  logic [15:0] reg_ASID;
  logic [43:0] reg_PPN;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_MODE <= 4'h0;
      reg_ASID <= 16'h0;
      reg_PPN <= 44'h0;
    end
    else if (w_wen
             & (w_wdata[63:60] == 4'h0 | w_wdata[63:60] == 4'h8
                | w_wdata[63:60] == 4'h9)) begin
      reg_MODE <= w_wdata[63:60];
      reg_ASID <= w_wdata[59:44];
      reg_PPN <= {8'h0, w_wdata[35:0]};
    end
  end // always @(posedge, posedge)
always_comb begin
    rdata = {reg_MODE, reg_ASID, reg_PPN};
  end
  always_comb begin
    regOut_MODE = reg_MODE;
  end
  always_comb begin
    regOut_ASID = reg_ASID;
  end
  always_comb begin
    regOut_PPN = reg_PPN;
  end
endmodule

module SatpModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [3:0]  regOut_MODE,
  output [15:0] regOut_ASID,
  output [43:0] regOut_PPN
);
  xs_SatpModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_MODE(regOut_MODE),
    .regOut_ASID(regOut_ASID),
    .regOut_PPN(regOut_PPN)
  );
endmodule
