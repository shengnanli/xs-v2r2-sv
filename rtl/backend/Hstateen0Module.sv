// Hstateen0Module.sv — VS state-enable level 0.
// This readable core preserves the G1 golden reset, WARL, and write-priority behavior.
// Parent: NewCSR; ports are generated from the G1 golden module to keep the contract exact.
module xs_Hstateen0Module_core (
  input logic clock, input logic reset, input logic w_wen, input logic [63:0] w_wdata,
  output logic [63:0] rdata, output logic regOut_JVT, output logic regOut_FCSR, output logic regOut_C,
  output logic regOut_SE0, output logic regOut_ENVCFG, output logic regOut_CSRIND, output logic regOut_AIA,
  output logic regOut_IMSIC, output logic regOut_CONTEXT, input logic fromMstateen0_SE0, input logic fromMstateen0_ENVCFG,
  input logic fromMstateen0_CSRIND, input logic fromMstateen0_AIA, input logic fromMstateen0_IMSIC,
  input logic fromMstateen0_CONTEXT, input logic fromMstateen0_C
);
  logic c_q,se0_q,envcfg_q,csrind_q,aia_q,imsic_q,context_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin c_q<=0;se0_q<=0;envcfg_q<=0;csrind_q<=0;aia_q<=0;imsic_q<=0;context_q<=0; end
    else if (w_wen) begin c_q<=w_wdata[0];se0_q<=w_wdata[63];envcfg_q<=w_wdata[62];csrind_q<=w_wdata[60];aia_q<=w_wdata[59];imsic_q<=w_wdata[58];context_q<=w_wdata[57]; end
  end
  wire c_out=c_q&fromMstateen0_C, se0_out=se0_q&fromMstateen0_SE0, envcfg_out=envcfg_q&fromMstateen0_ENVCFG;
  wire csrind_out=csrind_q&fromMstateen0_CSRIND, aia_out=aia_q&fromMstateen0_AIA, imsic_out=imsic_q&fromMstateen0_IMSIC, context_out=context_q&fromMstateen0_CONTEXT;
  assign rdata={se0_out,envcfg_out,1'b0,csrind_out,aia_out,imsic_out,context_out,56'h0,c_out};
  assign regOut_JVT=0; assign regOut_FCSR=0; assign regOut_C=c_out; assign regOut_SE0=se0_out; assign regOut_ENVCFG=envcfg_out;
  assign regOut_CSRIND=csrind_out; assign regOut_AIA=aia_out; assign regOut_IMSIC=imsic_out; assign regOut_CONTEXT=context_out;
endmodule

// BEGIN GENERATED(csr_dh)
module Hstateen0Module(
  input logic clock,
  input logic reset,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic regOut_JVT,
  output logic regOut_FCSR,
  output logic regOut_C,
  output logic regOut_SE0,
  output logic regOut_ENVCFG,
  output logic regOut_CSRIND,
  output logic regOut_AIA,
  output logic regOut_IMSIC,
  output logic regOut_CONTEXT,
  input logic fromMstateen0_SE0,
  input logic fromMstateen0_ENVCFG,
  input logic fromMstateen0_CSRIND,
  input logic fromMstateen0_AIA,
  input logic fromMstateen0_IMSIC,
  input logic fromMstateen0_CONTEXT,
  input logic fromMstateen0_C
);

  xs_Hstateen0Module_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_JVT(regOut_JVT),
    .regOut_FCSR(regOut_FCSR),
    .regOut_C(regOut_C),
    .regOut_SE0(regOut_SE0),
    .regOut_ENVCFG(regOut_ENVCFG),
    .regOut_CSRIND(regOut_CSRIND),
    .regOut_AIA(regOut_AIA),
    .regOut_IMSIC(regOut_IMSIC),
    .regOut_CONTEXT(regOut_CONTEXT),
    .fromMstateen0_SE0(fromMstateen0_SE0),
    .fromMstateen0_ENVCFG(fromMstateen0_ENVCFG),
    .fromMstateen0_CSRIND(fromMstateen0_CSRIND),
    .fromMstateen0_AIA(fromMstateen0_AIA),
    .fromMstateen0_IMSIC(fromMstateen0_IMSIC),
    .fromMstateen0_CONTEXT(fromMstateen0_CONTEXT),
    .fromMstateen0_C(fromMstateen0_C)
  );
endmodule
// END GENERATED
