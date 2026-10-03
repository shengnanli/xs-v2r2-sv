// HidelegModule.sv — hypervisor interrupt-delegation CSR.
// This readable core preserves the G1 golden reset, WARL, and write-priority behavior.
// Parent: NewCSR; ports are generated from the G1 golden module to keep the contract exact.
module xs_HidelegModule_core (
  input logic clock, input logic reset, input logic w_wen, input logic [63:0] w_wdata,
  output logic [63:0] rdata, output logic regOut_SSI, output logic regOut_VSSI, output logic regOut_MSI,
  output logic regOut_STI, output logic regOut_VSTI, output logic regOut_MTI, output logic regOut_SEI,
  output logic regOut_VSEI, output logic regOut_MEI, output logic regOut_SGEI, output logic regOut_LCOFI,
  input logic mideleg_SSI, input logic mideleg_STI, input logic mideleg_SEI, input logic mideleg_LCOFI
);
  logic vssi_q,vsti_q,vsei_q,lcofi_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin vssi_q<=0; vsti_q<=0; vsei_q<=0; lcofi_q<=0; end
    else if (w_wen) begin vssi_q<=w_wdata[2]; vsti_q<=w_wdata[6]; vsei_q<=w_wdata[10]; lcofi_q<=w_wdata[13]; end
  end
  wire lcofi_out=lcofi_q&mideleg_LCOFI;
  assign rdata={50'h0,lcofi_out,2'h0,vsei_q,3'h0,vsti_q,3'h0,vssi_q,2'h0};
  assign regOut_SSI=0; assign regOut_VSSI=vssi_q; assign regOut_MSI=0; assign regOut_STI=0; assign regOut_VSTI=vsti_q;
  assign regOut_MTI=0; assign regOut_SEI=0; assign regOut_VSEI=vsei_q; assign regOut_MEI=0; assign regOut_SGEI=0; assign regOut_LCOFI=lcofi_out;
endmodule

// BEGIN GENERATED(csr_dh)
module HidelegModule(
  input logic clock,
  input logic reset,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic regOut_SSI,
  output logic regOut_VSSI,
  output logic regOut_MSI,
  output logic regOut_STI,
  output logic regOut_VSTI,
  output logic regOut_MTI,
  output logic regOut_SEI,
  output logic regOut_VSEI,
  output logic regOut_MEI,
  output logic regOut_SGEI,
  output logic regOut_LCOFI,
  input logic mideleg_SSI,
  input logic mideleg_STI,
  input logic mideleg_SEI,
  input logic mideleg_LCOFI
);

  xs_HidelegModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_SSI(regOut_SSI),
    .regOut_VSSI(regOut_VSSI),
    .regOut_MSI(regOut_MSI),
    .regOut_STI(regOut_STI),
    .regOut_VSTI(regOut_VSTI),
    .regOut_MTI(regOut_MTI),
    .regOut_SEI(regOut_SEI),
    .regOut_VSEI(regOut_VSEI),
    .regOut_MEI(regOut_MEI),
    .regOut_SGEI(regOut_SGEI),
    .regOut_LCOFI(regOut_LCOFI),
    .mideleg_SSI(mideleg_SSI),
    .mideleg_STI(mideleg_STI),
    .mideleg_SEI(mideleg_SEI),
    .mideleg_LCOFI(mideleg_LCOFI)
  );
endmodule
// END GENERATED
