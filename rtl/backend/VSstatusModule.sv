// VSstatusModule.sv — virtual-supervisor status state and trap/return updates.
// FS/VS dirty transitions, SDT visibility, trap entry, sret, and CSR writes are retained.
// Reset and field priority follow the G1 status CSR semantics exactly.
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
  logic       reg_SIE;
  logic       reg_SPIE;
  logic       reg_SPP;
  logic [1:0] reg_VS;
  logic [1:0] reg_FS;
  logic       reg_SUM;
  logic       reg_MXR;
  logic       reg_SDT;
  logic       fs_dirty_set = (robCommit_fsDirty | writeFCSR) & isVirtMode;
  logic       vs_dirty_set =
    (robCommit_vsDirty | writeVCSR | robCommit_vstart_valid & (|robCommit_vstart_bits))
    & isVirtMode;
  `ifndef SYNTHESIS
    always @(posedge clock) begin
      if (fs_dirty_set & ~reset & reg_FS == 2'h0) begin
        if (`ASSERT_VERBOSE_COND_)
          $fwrite(32'h80000002, "Assertion failed: The vsstatus.FS should not be Off when set dirty, please check decode\n    at VirtualSupervisorLevel.scala:32 assert(reg.FS =/= ContextStatus.Off, \"The vsstatus.FS should not be Off when set dirty, please check decode\")\n");
        if (`STOP_COND_)
          xs_assert_v2(`__FILE__, `__LINE__);
      end
      if (vs_dirty_set & ~reset & reg_VS == 2'h0) begin
        if (`ASSERT_VERBOSE_COND_)
          $fwrite(32'h80000002, "Assertion failed: The vsstatus.VS should not be Off when set dirty, please check decode\n    at VirtualSupervisorLevel.scala:37 assert(reg.VS =/= ContextStatus.Off, \"The vsstatus.VS should not be Off when set dirty, please check decode\")\n");
        if (`STOP_COND_)
          xs_assert_v2(`__FILE__, `__LINE__);
      end
    end // always @(posedge)
  `endif // not def SYNTHESIS
  assign sdt_effective = menvcfg_DTE & henvcfg_DTE & reg_SDT;
  logic       s_level_write = w_wen | retFromS_vsstatus_valid | trapToVS_vsstatus_valid;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_SIE <= 1'h0;
      reg_SPIE <= 1'h0;
      reg_SPP <= 1'h0;
      reg_VS <= 2'h0;
      reg_FS <= 2'h0;
      reg_SUM <= 1'h0;
      reg_MXR <= 1'h0;
      reg_SDT <= 1'h0;
    end
    else begin
      reg_SIE <=
        ~(menvcfg_DTE & henvcfg_DTE & w_wdata[24] & w_wen)
        & (s_level_write
             ? retFromS_vsstatus_valid & retFromS_vsstatus_bits_SIE
               | trapToVS_vsstatus_valid & trapToVS_vsstatus_bits_SIE | w_wen & w_wdata[1]
             : reg_SIE);
      if (s_level_write) begin
        reg_SPIE <=
          retFromS_vsstatus_valid & retFromS_vsstatus_bits_SPIE | trapToVS_vsstatus_valid
          & trapToVS_vsstatus_bits_SPIE | w_wen & w_wdata[5];
        reg_SPP <=
          retFromS_vsstatus_valid & retFromS_vsstatus_bits_SPP | trapToVS_vsstatus_valid
          & trapToVS_vsstatus_bits_SPP | w_wen & w_wdata[8];
      end
      if (vs_dirty_set)
        reg_VS <= 2'h3;
      else if (w_wen)
        reg_VS <= w_wdata[10:9];
      if (fs_dirty_set)
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
  end // always @(posedge, posedge)
  
  assign rdata =
    {(&reg_FS) | (&reg_VS),
     38'h100,
     sdt_effective,
     4'h0,
     reg_MXR,
     reg_SUM,
     3'h0,
     reg_FS,
     2'h0,
     reg_VS,
     reg_SPP,
     2'h0,
     reg_SPIE,
     3'h0,
     reg_SIE,
     1'h0};
  assign regOut_SIE = reg_SIE;
  assign regOut_SPIE = reg_SPIE;
  assign regOut_SPP = reg_SPP;
  assign regOut_VS = reg_VS;
  assign regOut_FS = reg_FS;
  assign regOut_SUM = reg_SUM;
  assign regOut_MXR = reg_MXR;
  assign regOut_SDT = sdt_effective;
endmodule
