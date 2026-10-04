// VSstatusModule.sv — virtual-supervisor status state and trap/return updates.
// 设计意图：src/main/scala/xiangshan/backend/fu/NewCSR/VirtualSupervisorLevel.scala（vsstatus，父 NewCSR）。
// FS/VS dirty transitions, SDT visibility, trap entry, sret, and CSR writes are retained.
// Reset and field priority follow the G1 status CSR semantics exactly.
// Explicit state names below separate CSR writes from trap/return priority and dirty-state updates.
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
  input         robCommit_vstart_valid,
  input  [6:0]  robCommit_vstart_bits,
  input         writeFCSR,
  input         writeVCSR,
  input         isVirtMode,
  input         menvcfg_DTE,
  input         henvcfg_DTE
);

  logic       sdt_effective;
  logic       sie_q;
  logic       spie_q;
  logic       spp_q;
  logic [1:0] vs_q;
  logic [1:0] fs_q;
  logic       sum_q;
  logic       mxr_q;
  logic       sdt_q;
  wire        fs_dirty_set = (robCommit_fsDirty | writeFCSR) & isVirtMode;
  wire        vs_dirty_set =
    (robCommit_vsDirty | writeVCSR | robCommit_vstart_valid & (|robCommit_vstart_bits))
    & isVirtMode;
  `ifndef SYNTHESIS
    always @(posedge clock) begin
      if (fs_dirty_set & ~reset & fs_q == 2'h0) begin
        if (`ASSERT_VERBOSE_COND_)
          $fwrite(32'h80000002, "Assertion failed: The vsstatus.FS should not be Off when set dirty, please check decode\n    at VirtualSupervisorLevel.scala:32 assert(reg.FS =/= ContextStatus.Off, \"The vsstatus.FS should not be Off when set dirty, please check decode\")\n");
        if (`STOP_COND_)
          xs_assert_v2(`__FILE__, `__LINE__);
      end
      if (vs_dirty_set & ~reset & vs_q == 2'h0) begin
        if (`ASSERT_VERBOSE_COND_)
          $fwrite(32'h80000002, "Assertion failed: The vsstatus.VS should not be Off when set dirty, please check decode\n    at VirtualSupervisorLevel.scala:37 assert(reg.VS =/= ContextStatus.Off, \"The vsstatus.VS should not be Off when set dirty, please check decode\")\n");
        if (`STOP_COND_)
          xs_assert_v2(`__FILE__, `__LINE__);
      end
    end // always @(posedge)
  `endif // not def SYNTHESIS
  assign sdt_effective = menvcfg_DTE & henvcfg_DTE & sdt_q;
  wire        s_level_write = w_wen | retFromS_vsstatus_valid | trapToVS_vsstatus_valid;
  // Next-state equations make the trap/return/write priority explicit.
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      sie_q <= 1'b0;
      spie_q <= 1'b0;
      spp_q <= 1'b0;
      vs_q <= 2'b0;
      fs_q <= 2'b0;
      sum_q <= 1'b0;
      mxr_q <= 1'b0;
      sdt_q <= 1'b0;
    end else begin
      sie_q <= ~(menvcfg_DTE & henvcfg_DTE & w_wdata[24] & w_wen) &
        (s_level_write ?
          ((retFromS_vsstatus_valid & retFromS_vsstatus_bits_SIE) |
           (trapToVS_vsstatus_valid & trapToVS_vsstatus_bits_SIE) |
           (w_wen & w_wdata[1])) : sie_q);
      if (s_level_write) begin
        spie_q <= (retFromS_vsstatus_valid & retFromS_vsstatus_bits_SPIE) |
          (trapToVS_vsstatus_valid & trapToVS_vsstatus_bits_SPIE) |
          (w_wen & w_wdata[5]);
        spp_q <= (retFromS_vsstatus_valid & retFromS_vsstatus_bits_SPP) |
          (trapToVS_vsstatus_valid & trapToVS_vsstatus_bits_SPP) |
          (w_wen & w_wdata[8]);
      end
      if (vs_dirty_set)
        vs_q <= 2'h3;
      else if (w_wen)
        vs_q <= w_wdata[10:9];
      if (fs_dirty_set)
        fs_q <= 2'h3;
      else if (w_wen)
        fs_q <= w_wdata[14:13];
      if (w_wen) begin
        sum_q <= w_wdata[18];
        mxr_q <= w_wdata[19];
      end
      if (w_wen | retFromSSDT_vsstatus_valid | retFromM_vsstatus_valid |
          retFromMN_vsstatus_valid | retFromD_vsstatus_valid |
          trapToVS_vsstatus_valid)
        sdt_q <= (retFromM_vsstatus_valid & retFromM_vsstatus_bits_SDT) |
          (retFromMN_vsstatus_valid & retFromMN_vsstatus_bits_SDT) |
          (retFromD_vsstatus_valid & retFromD_vsstatus_bits_SDT) |
          (trapToVS_vsstatus_valid & trapToVS_vsstatus_bits_SDT) |
          (w_wen & w_wdata[24]);
    end
  end // always @(posedge, posedge)
  
  assign rdata = {
    (fs_q == 2'h3) | (vs_q == 2'h3),
    38'h100,
    menvcfg_DTE & henvcfg_DTE & sdt_q,
    4'b0,
    mxr_q,
    sum_q,
    3'b0,
    fs_q,
    2'b0,
    vs_q,
    spp_q,
    2'b0,
    spie_q,
    3'b0,
    sie_q,
    1'b0};
  assign regOut_SIE = sie_q;
  assign regOut_SPIE = spie_q;
  assign regOut_SPP = spp_q;
  assign regOut_VS = vs_q;
  assign regOut_FS = fs_q;
  assign regOut_SUM = sum_q;
  assign regOut_MXR = mxr_q;
  assign regOut_SDT = menvcfg_DTE & henvcfg_DTE & sdt_q;
endmodule
