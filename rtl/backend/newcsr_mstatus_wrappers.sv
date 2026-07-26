// NewCSR bespoke module: MStatusModule (machine status CSR + sstatus alias).
//
// Faithful, readable reimplementation of the golden MStatusModule — the most
// intricate CSR in the file. mstatus holds 18 architected fields, each of which
// can be updated from several sources with a fixed priority (OR-of-guarded-muxes
// exactly as golden generates). The distinct write sources are:
//   w_wen                  : direct CSR write (mstatus)
//   wAliasSstatus_wen      : CSR write via the sstatus alias (subset of fields)
//   trapToM_* / trapToHS_* : hardware trap entry latches (M / HS view)
//   retFromM/S/D/MN_*      : xret restore of the *PIE->*IE, *PP, MPRV, ...
//   robCommit_fs/vsDirty   : FS/VS become Dirty (0b11) on FP/vector state change
// The CIRCT intermediate select wires are renamed for clarity (see below).
//
// SDT interaction: an sstatus write of SIE is suppressed when SDT is set unless
// menvcfg.DTE gates it (golden ~(...) & (...) form, transcribed exactly).
//
// A non-synthesizable assertion block warns if FS/VS are set Dirty while Off;
// UT/FM define SYNTHESIS so it is excluded from both.

module MStatusModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SIE,
  output        regOut_MIE,
  output        regOut_SPIE,
  output        regOut_MPIE,
  output        regOut_SPP,
  output [1:0]  regOut_VS,
  output [1:0]  regOut_MPP,
  output [1:0]  regOut_FS,
  output        regOut_MPRV,
  output        regOut_SUM,
  output        regOut_MXR,
  output        regOut_TVM,
  output        regOut_TW,
  output        regOut_TSR,
  output        regOut_SDT,
  output        regOut_GVA,
  output        regOut_MPV,
  output        regOut_MDT,
  input         trapToM_mstatus_valid,
  input         trapToM_mstatus_bits_MIE,
  input         trapToM_mstatus_bits_MPIE,
  input  [1:0]  trapToM_mstatus_bits_MPP,
  input         trapToM_mstatus_bits_GVA,
  input         trapToM_mstatus_bits_MPV,
  input         trapToM_mstatus_bits_MDT,
  input         trapToHS_mstatus_valid,
  input         trapToHS_mstatus_bits_SIE,
  input         trapToHS_mstatus_bits_SPIE,
  input         trapToHS_mstatus_bits_SPP,
  input         trapToHS_mstatus_bits_SDT,
  input         retFromD_mstatus_valid,
  input         retFromD_mstatus_bits_MPRV,
  input         retFromD_mstatus_bits_SDT,
  input         retFromD_mstatus_bits_MDT,
  input         retFromM_mstatus_valid,
  input         retFromM_mstatus_bits_MIE,
  input         retFromM_mstatus_bits_MPIE,
  input  [1:0]  retFromM_mstatus_bits_MPP,
  input         retFromM_mstatus_bits_MPRV,
  input         retFromM_mstatus_bits_SDT,
  input         retFromM_mstatus_bits_MPV,
  input         retFromM_mstatus_bits_MDT,
  input         retFromMN_mstatus_valid,
  input         retFromMN_mstatus_bits_MPRV,
  input         retFromMN_mstatus_bits_SDT,
  input         retFromMN_mstatus_bits_MDT,
  input         retFromS_mstatus_valid,
  input         retFromS_mstatus_bits_SIE,
  input         retFromS_mstatus_bits_SPIE,
  input         retFromS_mstatus_bits_SPP,
  input         retFromS_mstatus_bits_MPRV,
  input         retFromS_mstatus_bits_SDT,
  input         retFromS_mstatus_bits_MDT,
  input         robCommit_fsDirty,
  input         robCommit_vsDirty,
  input         writeFCSR,
  input         writeVCSR,
  input         menvcfg_DTE,
  output        sstatus_SIE,
  output        sstatus_SPIE,
  output        sstatus_SPP,
  output [1:0]  sstatus_VS,
  output [1:0]  sstatus_FS,
  output        sstatus_SUM,
  output        sstatus_MXR,
  output        sstatus_SDT,
  output        sstatus_SD,
  output [63:0] sstatusRdata,
  input         wAliasSstatus_wen,
  input  [63:0] wAliasSstatus_wdata
);
  reg        reg_SIE, reg_MIE, reg_SPIE, reg_MPIE, reg_SPP;
  reg  [1:0] reg_VS, reg_MPP, reg_FS;
  reg        reg_MPRV, reg_SUM, reg_MXR, reg_TVM, reg_TW, reg_TSR;
  reg        reg_SDT, reg_GVA, reg_MPV, reg_MDT;

  // FS/VS become Dirty (0b11) when the FP/vector unit reports state change or the
  // corresponding CSR (fcsr/vcsr) is written.
  wire fsDirtySet = robCommit_fsDirty | writeFCSR;
  wire vsDirtySet = robCommit_vsDirty | writeVCSR;

`ifndef SYNTHESIS
  always @(posedge clock) begin
    if (fsDirtySet & ~reset & reg_FS == 2'h0) begin
      if (`ASSERT_VERBOSE_COND_)
        $fwrite(32'h80000002, "Assertion failed: The [m|s]status.FS should not be Off when set dirty, please check decode\n    at MachineLevel.scala:538 assert(reg.FS =/= ContextStatus.Off, \"The [m|s]status.FS should not be Off when set dirty, please check decode\")\n");
      if (`STOP_COND_)
        xs_assert_v2(`__FILE__, `__LINE__);
    end
    if (vsDirtySet & ~reset & reg_VS == 2'h0) begin
      if (`ASSERT_VERBOSE_COND_)
        $fwrite(32'h80000002, "Assertion failed: The [m|s]status.VS should not be Off when set dirty, please check decode\n    at MachineLevel.scala:543 assert(reg.VS =/= ContextStatus.Off, \"The [m|s]status.VS should not be Off when set dirty, please check decode\")\n");
      if (`STOP_COND_)
        xs_assert_v2(`__FILE__, `__LINE__);
    end
  end
`endif

  // Summary "state dirty" bit: FS==Dirty OR VS==Dirty.
  wire sd = (&reg_FS) | (&reg_VS);
  // sstatus.SDT is only visible when menvcfg.DTE enables the feature.
  wire sstatus_SDT_eff = reg_SDT & menvcfg_DTE;

  // Per-field write-enable selects (grouped by which sources may touch a field).
  wire mLevelTrapOrRet = trapToM_mstatus_valid | retFromM_mstatus_valid;
  wire mLevelWrite     = w_wen | mLevelTrapOrRet;
  wire sAliasWrite     = w_wen | wAliasSstatus_wen;
  wire sLevelWrite =
    w_wen | trapToHS_mstatus_valid | retFromS_mstatus_valid | wAliasSstatus_wen;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_SIE <= 1'h0; reg_MIE <= 1'h0; reg_SPIE <= 1'h0; reg_MPIE <= 1'h0;
      reg_SPP <= 1'h0; reg_VS <= 2'h0; reg_MPP <= 2'h0; reg_FS <= 2'h0;
      reg_MPRV <= 1'h0; reg_SUM <= 1'h0; reg_MXR <= 1'h0; reg_TVM <= 1'h0;
      reg_TW <= 1'h0; reg_TSR <= 1'h0; reg_SDT <= 1'h0; reg_GVA <= 1'h0;
      reg_MPV <= 1'h0; reg_MDT <= 1'h0;
    end
    else begin
      // SIE: sstatus-writable; forced 0 when SDT is being set (unless DTE-gated).
      reg_SIE <=
        ~(w_wen
            ? w_wdata[24]
            : wAliasSstatus_wen & (menvcfg_DTE ? wAliasSstatus_wdata[24] : reg_SDT))
        & (sLevelWrite
             ? trapToHS_mstatus_valid & trapToHS_mstatus_bits_SIE | retFromS_mstatus_valid
               & retFromS_mstatus_bits_SIE | wAliasSstatus_wen & wAliasSstatus_wdata[1]
               | w_wen & w_wdata[1]
             : reg_SIE);
      // MIE: forced 0 when MDT is being set via w_wdata[42].
      reg_MIE <=
        ~(w_wdata[42] & w_wen)
        & (mLevelWrite
             ? trapToM_mstatus_valid & trapToM_mstatus_bits_MIE | retFromM_mstatus_valid
               & retFromM_mstatus_bits_MIE | w_wen & w_wdata[3]
             : reg_MIE);
      if (sLevelWrite) begin
        reg_SPIE <=
          trapToHS_mstatus_valid & trapToHS_mstatus_bits_SPIE | retFromS_mstatus_valid
          & retFromS_mstatus_bits_SPIE | wAliasSstatus_wen & wAliasSstatus_wdata[5]
          | w_wen & w_wdata[5];
        reg_SPP <=
          trapToHS_mstatus_valid & trapToHS_mstatus_bits_SPP | retFromS_mstatus_valid
          & retFromS_mstatus_bits_SPP | wAliasSstatus_wen & wAliasSstatus_wdata[8] | w_wen
          & w_wdata[8];
      end
      if (mLevelWrite) begin
        reg_MPIE <=
          trapToM_mstatus_valid & trapToM_mstatus_bits_MPIE | retFromM_mstatus_valid
          & retFromM_mstatus_bits_MPIE | w_wen & w_wdata[7];
        reg_MPV <=
          trapToM_mstatus_valid & trapToM_mstatus_bits_MPV | retFromM_mstatus_valid
          & retFromM_mstatus_bits_MPV | w_wen & w_wdata[39];
      end
      // VS/FS: forced to Dirty on dirty-set, else written by mstatus/sstatus.
      if (vsDirtySet)
        reg_VS <= 2'h3;
      else if (sAliasWrite)
        reg_VS <=
          (wAliasSstatus_wen ? wAliasSstatus_wdata[10:9] : 2'h0)
          | (w_wen ? w_wdata[10:9] : 2'h0);
      // MPP is WARL (only 0/1/3 legal); trap/ret also load it.
      if (w_wen & (|{&(w_wdata[12:11]), w_wdata[12:11] == 2'h1, w_wdata[12:11] == 2'h0})
          | mLevelTrapOrRet)
        reg_MPP <=
          (trapToM_mstatus_valid ? trapToM_mstatus_bits_MPP : 2'h0)
          | (retFromM_mstatus_valid ? retFromM_mstatus_bits_MPP : 2'h0)
          | (w_wen ? w_wdata[12:11] : 2'h0);
      if (fsDirtySet)
        reg_FS <= 2'h3;
      else if (sAliasWrite)
        reg_FS <=
          (wAliasSstatus_wen ? wAliasSstatus_wdata[14:13] : 2'h0)
          | (w_wen ? w_wdata[14:13] : 2'h0);
      if (w_wen | retFromD_mstatus_valid | retFromM_mstatus_valid
          | retFromMN_mstatus_valid | retFromS_mstatus_valid)
        reg_MPRV <=
          retFromD_mstatus_valid & retFromD_mstatus_bits_MPRV | retFromM_mstatus_valid
          & retFromM_mstatus_bits_MPRV | retFromMN_mstatus_valid
          & retFromMN_mstatus_bits_MPRV | retFromS_mstatus_valid
          & retFromS_mstatus_bits_MPRV | w_wen & w_wdata[17];
      if (sAliasWrite) begin
        reg_SUM <= wAliasSstatus_wen & wAliasSstatus_wdata[18] | w_wen & w_wdata[18];
        reg_MXR <= wAliasSstatus_wen & wAliasSstatus_wdata[19] | w_wen & w_wdata[19];
      end
      if (w_wen) begin
        reg_TVM <= w_wdata[20];
        reg_TW  <= w_wdata[21];
        reg_TSR <= w_wdata[22];
      end
      // SDT: written by any privilege trap/ret/alias except a DTE-disabled sstatus
      // write (the empty then-branch preserves the register in that corner).
      if (~menvcfg_DTE & wAliasSstatus_wen
          | ~(w_wen | trapToHS_mstatus_valid | retFromD_mstatus_valid
              | retFromM_mstatus_valid | retFromMN_mstatus_valid | retFromS_mstatus_valid
              | wAliasSstatus_wen)) begin
      end
      else
        reg_SDT <=
          trapToHS_mstatus_valid & trapToHS_mstatus_bits_SDT | retFromD_mstatus_valid
          & retFromD_mstatus_bits_SDT | retFromM_mstatus_valid & retFromM_mstatus_bits_SDT
          | retFromMN_mstatus_valid & retFromMN_mstatus_bits_SDT | retFromS_mstatus_valid
          & retFromS_mstatus_bits_SDT | wAliasSstatus_wen & wAliasSstatus_wdata[24]
          | w_wen & w_wdata[24];
      if (w_wen | trapToM_mstatus_valid)
        reg_GVA <= trapToM_mstatus_valid & trapToM_mstatus_bits_GVA | w_wen & w_wdata[38];
      if (w_wen | trapToM_mstatus_valid | retFromD_mstatus_valid | retFromM_mstatus_valid
          | retFromMN_mstatus_valid | retFromS_mstatus_valid)
        reg_MDT <=
          trapToM_mstatus_valid & trapToM_mstatus_bits_MDT | retFromD_mstatus_valid
          & retFromD_mstatus_bits_MDT | retFromM_mstatus_valid & retFromM_mstatus_bits_MDT
          | retFromMN_mstatus_valid & retFromMN_mstatus_bits_MDT | retFromS_mstatus_valid
          & retFromS_mstatus_bits_MDT | w_wen & w_wdata[42];
    end
  end

  assign rdata =
    {sd, 20'h0, reg_MDT, 2'h0, reg_MPV, reg_GVA, 13'h500, reg_SDT, 1'h0, reg_TSR,
     reg_TW, reg_TVM, reg_MXR, reg_SUM, reg_MPRV, 2'h0, reg_FS, reg_MPP, reg_VS,
     reg_SPP, reg_MPIE, 1'h0, reg_SPIE, 1'h0, reg_MIE, 1'h0, reg_SIE, 1'h0};

  assign regOut_SIE  = reg_SIE;
  assign regOut_MIE  = reg_MIE;
  assign regOut_SPIE = reg_SPIE;
  assign regOut_MPIE = reg_MPIE;
  assign regOut_SPP  = reg_SPP;
  assign regOut_VS   = reg_VS;
  assign regOut_MPP  = reg_MPP;
  assign regOut_FS   = reg_FS;
  assign regOut_MPRV = reg_MPRV;
  assign regOut_SUM  = reg_SUM;
  assign regOut_MXR  = reg_MXR;
  assign regOut_TVM  = reg_TVM;
  assign regOut_TW   = reg_TW;
  assign regOut_TSR  = reg_TSR;
  assign regOut_SDT  = reg_SDT;
  assign regOut_GVA  = reg_GVA;
  assign regOut_MPV  = reg_MPV;
  assign regOut_MDT  = reg_MDT;

  assign sstatus_SIE  = reg_SIE;
  assign sstatus_SPIE = reg_SPIE;
  assign sstatus_SPP  = reg_SPP;
  assign sstatus_VS   = reg_VS;
  assign sstatus_FS   = reg_FS;
  assign sstatus_SUM  = reg_SUM;
  assign sstatus_MXR  = reg_MXR;
  assign sstatus_SDT  = sstatus_SDT_eff;
  assign sstatus_SD   = sd;

  assign sstatusRdata =
    {sd, 38'h100, sstatus_SDT_eff, 4'h0, reg_MXR, reg_SUM, 3'h0, reg_FS, 2'h0,
     reg_VS, reg_SPP, 2'h0, reg_SPIE, 3'h0, reg_SIE, 1'h0};

endmodule
