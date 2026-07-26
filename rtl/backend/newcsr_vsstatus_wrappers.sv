// NewCSR bespoke module: VSstatusModule (virtual-supervisor status CSR).
//
// Faithful, readable reimplementation of the golden VSstatusModule. vsstatus is
// the VS-mode view of sstatus (8 architected fields). Writes come from a direct
// CSR write (w_wen), a VS trap entry (trapToVS), or an sret from VS
// (retFromS_vsstatus); SDT additionally tracks ret from M/MN/D. FS/VS become
// Dirty only when the FP/vector state changes *while virtualized* (isVirtMode).
// The SDT field is only visible when BOTH menvcfg.DTE and henvcfg.DTE enable the
// double-trap feature. All CIRCT intermediate wires are renamed for clarity.
//
// A non-synthesizable assertion warns if FS/VS are set Dirty while Off; UT/FM
// define SYNTHESIS so it is excluded.

module VSstatusModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SIE,
  output        regOut_SPIE,
  output        regOut_SPP,
  output [1:0]  regOut_VS,
  output [1:0]  regOut_FS,
  output        regOut_SUM,
  output        regOut_MXR,
  output        regOut_SDT,
  input         retFromS_vsstatus_valid,
  input         retFromS_vsstatus_bits_SIE,
  input         retFromS_vsstatus_bits_SPIE,
  input         retFromS_vsstatus_bits_SPP,
  input         retFromSSDT_vsstatus_valid,
  input         retFromM_vsstatus_valid,
  input         retFromM_vsstatus_bits_SDT,
  input         retFromMN_vsstatus_valid,
  input         retFromMN_vsstatus_bits_SDT,
  input         retFromD_vsstatus_valid,
  input         retFromD_vsstatus_bits_SDT,
  input         trapToVS_vsstatus_valid,
  input         trapToVS_vsstatus_bits_SIE,
  input         trapToVS_vsstatus_bits_SPIE,
  input         trapToVS_vsstatus_bits_SPP,
  input         trapToVS_vsstatus_bits_SDT,
  input         robCommit_fsDirty,
  input         robCommit_vsDirty,
  input         writeFCSR,
  input         writeVCSR,
  input         isVirtMode,
  input         menvcfg_DTE,
  input         henvcfg_DTE
);
  reg        reg_SIE, reg_SPIE, reg_SPP;
  reg  [1:0] reg_VS, reg_FS;
  reg        reg_SUM, reg_MXR, reg_SDT;

  // FS/VS become Dirty only on a state change that happens while virtualized.
  wire fsDirtySet = (robCommit_fsDirty | writeFCSR) & isVirtMode;
  wire vsDirtySet = (robCommit_vsDirty | writeVCSR) & isVirtMode;

`ifndef SYNTHESIS
  always @(posedge clock) begin
    if (fsDirtySet & ~reset & reg_FS == 2'h0) begin
      if (`ASSERT_VERBOSE_COND_)
        $fwrite(32'h80000002, "Assertion failed: The vsstatus.FS should not be Off when set dirty, please check decode\n    at VirtualSupervisorLevel.scala:32 assert(reg.FS =/= ContextStatus.Off, \"The vsstatus.FS should not be Off when set dirty, please check decode\")\n");
      if (`STOP_COND_)
        xs_assert_v2(`__FILE__, `__LINE__);
    end
    if (vsDirtySet & ~reset & reg_VS == 2'h0) begin
      if (`ASSERT_VERBOSE_COND_)
        $fwrite(32'h80000002, "Assertion failed: The vsstatus.VS should not be Off when set dirty, please check decode\n    at VirtualSupervisorLevel.scala:37 assert(reg.VS =/= ContextStatus.Off, \"The vsstatus.VS should not be Off when set dirty, please check decode\")\n");
      if (`STOP_COND_)
        xs_assert_v2(`__FILE__, `__LINE__);
    end
  end
`endif

  // SDT visible only when the double-trap feature is enabled at both M and HS.
  wire sdt_eff = menvcfg_DTE & henvcfg_DTE & reg_SDT;
  // SIE/SPIE/SPP write select: direct write, VS trap entry, or sret-from-VS.
  wire sLevelWrite = w_wen | retFromS_vsstatus_valid | trapToVS_vsstatus_valid;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_SIE <= 1'h0; reg_SPIE <= 1'h0; reg_SPP <= 1'h0; reg_VS <= 2'h0;
      reg_FS <= 2'h0; reg_SUM <= 1'h0; reg_MXR <= 1'h0; reg_SDT <= 1'h0;
    end
    else begin
      // SIE forced 0 when SDT is being set via a DTE-enabled write of w_wdata[24].
      reg_SIE <=
        ~(menvcfg_DTE & henvcfg_DTE & w_wdata[24] & w_wen)
        & (sLevelWrite
             ? retFromS_vsstatus_valid & retFromS_vsstatus_bits_SIE
               | trapToVS_vsstatus_valid & trapToVS_vsstatus_bits_SIE | w_wen & w_wdata[1]
             : reg_SIE);
      if (sLevelWrite) begin
        reg_SPIE <=
          retFromS_vsstatus_valid & retFromS_vsstatus_bits_SPIE | trapToVS_vsstatus_valid
          & trapToVS_vsstatus_bits_SPIE | w_wen & w_wdata[5];
        reg_SPP <=
          retFromS_vsstatus_valid & retFromS_vsstatus_bits_SPP | trapToVS_vsstatus_valid
          & trapToVS_vsstatus_bits_SPP | w_wen & w_wdata[8];
      end
      if (vsDirtySet)
        reg_VS <= 2'h3;
      else if (w_wen)
        reg_VS <= w_wdata[10:9];
      if (fsDirtySet)
        reg_FS <= 2'h3;
      else if (w_wen)
        reg_FS <= w_wdata[14:13];
      if (w_wen) begin
        reg_SUM <= w_wdata[18];
        reg_MXR <= w_wdata[19];
      end
      if (w_wen | retFromSSDT_vsstatus_valid | retFromM_vsstatus_valid
          | retFromMN_vsstatus_valid | retFromD_vsstatus_valid | trapToVS_vsstatus_valid)
        reg_SDT <=
          retFromM_vsstatus_valid & retFromM_vsstatus_bits_SDT | retFromMN_vsstatus_valid
          & retFromMN_vsstatus_bits_SDT | retFromD_vsstatus_valid
          & retFromD_vsstatus_bits_SDT | trapToVS_vsstatus_valid
          & trapToVS_vsstatus_bits_SDT | w_wen & w_wdata[24];
    end
  end

  assign rdata =
    {(&reg_FS) | (&reg_VS), 38'h100, sdt_eff, 4'h0, reg_MXR, reg_SUM, 3'h0, reg_FS,
     2'h0, reg_VS, reg_SPP, 2'h0, reg_SPIE, 3'h0, reg_SIE, 1'h0};

  assign regOut_SIE  = reg_SIE;
  assign regOut_SPIE = reg_SPIE;
  assign regOut_SPP  = reg_SPP;
  assign regOut_VS   = reg_VS;
  assign regOut_FS   = reg_FS;
  assign regOut_SUM  = reg_SUM;
  assign regOut_MXR  = reg_MXR;
  assign regOut_SDT  = sdt_eff;

endmodule
