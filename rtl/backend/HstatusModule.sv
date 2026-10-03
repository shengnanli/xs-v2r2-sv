// HstatusModule.sv — hypervisor status CSR.
// This readable core preserves the G1 golden reset, WARL, and write-priority behavior.
// Parent: NewCSR; ports are generated from the G1 golden module to keep the contract exact.
module xs_HstatusModule_core (
  input logic clock, input logic reset, input logic w_wen, input logic [63:0] w_wdata, output logic [63:0] rdata,
  output logic regOut_GVA, output logic regOut_SPV, output logic regOut_SPVP, output logic regOut_HU, output logic [5:0] regOut_VGEIN,
  output logic regOut_VTVM, output logic regOut_VTW, output logic regOut_VTSR, output logic [1:0] regOut_HUPMM,
  input logic retFromS_hstatus_valid, input logic retFromS_hstatus_bits_SPV, input logic trapToHS_hstatus_valid,
  input logic trapToHS_hstatus_bits_GVA, input logic trapToHS_hstatus_bits_SPV, input logic trapToHS_hstatus_bits_SPVP
);
  logic gva_q,spv_q,spvp_q,hu_q,vtvm_q,vtw_q,vtsr_q; logic [5:0] vgein_q; logic [1:0] hupmm_q;
  wire hupmm_legal=(w_wdata[49:48]==2'h0)||(w_wdata[49:48]==2'h2)||(&w_wdata[49:48]);
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin gva_q<=0;spv_q<=0;spvp_q<=0;hu_q<=0;vgein_q<=0;vtvm_q<=0;vtw_q<=0;vtsr_q<=0;hupmm_q<=0; end
    else begin
      if (w_wen || trapToHS_hstatus_valid) begin gva_q<=(trapToHS_hstatus_valid&trapToHS_hstatus_bits_GVA)|(w_wen&w_wdata[6]); spvp_q<=(trapToHS_hstatus_valid&trapToHS_hstatus_bits_SPVP)|(w_wen&w_wdata[8]); end
      if (w_wen || retFromS_hstatus_valid || trapToHS_hstatus_valid) spv_q<=(retFromS_hstatus_valid&retFromS_hstatus_bits_SPV)|(trapToHS_hstatus_valid&trapToHS_hstatus_bits_SPV)|(w_wen&w_wdata[7]);
      if (w_wen) begin hu_q<=w_wdata[9];vgein_q<=w_wdata[17:12];vtvm_q<=w_wdata[20];vtw_q<=w_wdata[21];vtsr_q<=w_wdata[22]; end
      if (w_wen && hupmm_legal) hupmm_q<=w_wdata[49:48];
    end
  end
  assign rdata={14'h0,hupmm_q,25'h400,vtsr_q,vtw_q,vtvm_q,2'h0,vgein_q,2'h0,hu_q,spvp_q,spv_q,gva_q,6'h0};
  assign regOut_GVA=gva_q; assign regOut_SPV=spv_q; assign regOut_SPVP=spvp_q; assign regOut_HU=hu_q; assign regOut_VGEIN=vgein_q; assign regOut_VTVM=vtvm_q; assign regOut_VTW=vtw_q; assign regOut_VTSR=vtsr_q; assign regOut_HUPMM=hupmm_q;
endmodule

// BEGIN GENERATED(csr_dh)
module HstatusModule(
  input logic clock,
  input logic reset,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic regOut_GVA,
  output logic regOut_SPV,
  output logic regOut_SPVP,
  output logic regOut_HU,
  output logic [5:0] regOut_VGEIN,
  output logic regOut_VTVM,
  output logic regOut_VTW,
  output logic regOut_VTSR,
  output logic [1:0] regOut_HUPMM,
  input logic retFromS_hstatus_valid,
  input logic retFromS_hstatus_bits_SPV,
  input logic trapToHS_hstatus_valid,
  input logic trapToHS_hstatus_bits_GVA,
  input logic trapToHS_hstatus_bits_SPV,
  input logic trapToHS_hstatus_bits_SPVP
);

  xs_HstatusModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_GVA(regOut_GVA),
    .regOut_SPV(regOut_SPV),
    .regOut_SPVP(regOut_SPVP),
    .regOut_HU(regOut_HU),
    .regOut_VGEIN(regOut_VGEIN),
    .regOut_VTVM(regOut_VTVM),
    .regOut_VTW(regOut_VTW),
    .regOut_VTSR(regOut_VTSR),
    .regOut_HUPMM(regOut_HUPMM),
    .retFromS_hstatus_valid(retFromS_hstatus_valid),
    .retFromS_hstatus_bits_SPV(retFromS_hstatus_bits_SPV),
    .trapToHS_hstatus_valid(trapToHS_hstatus_valid),
    .trapToHS_hstatus_bits_GVA(trapToHS_hstatus_bits_GVA),
    .trapToHS_hstatus_bits_SPV(trapToHS_hstatus_bits_SPV),
    .trapToHS_hstatus_bits_SPVP(trapToHS_hstatus_bits_SPVP)
  );
endmodule
// END GENERATED
