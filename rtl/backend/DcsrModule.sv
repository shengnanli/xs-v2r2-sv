// =============================================================================
// DcsrModule.sv —— 调试模式 CSR dcsr（32 位），NewCSR 的 debug 级叶
// 记录调试态控制位与「进调试现场」：trapToD_dcsr_*（进入调试，锁存 cause/v/prv）、
// retFromD_dcsr_*（dret 返回，回写 v/prv）、w_*（CSR 软件写口）、nmip（NMI 挂起）。
// 机制：11 个纯软件写位只走 w 口；cause 只在进调试时更新（同拍软件写按位或入）；
//   v 是 trap/dret/软件写三源按位或；prv 是 WARL 字段，软件写保留值 2 不构成写使能
//   （但 trap/dret 同拍时该写数据仍按位或入——golden 的不对称，照抄）。
//   NMIP 只读，直通 nmip 输入不落寄存器；DEBUGVER=4/EXTCAUSE=0 是读出侧的硬连常量。
// 复位域：14 位寄存器全部异步高有效复位，prv 复位到 M 态（2'h3）、其余清 0。
// wrapper（端口表与 u_core 连线）由 scripts/gen_csrctl_leaves5.py 生成，见文末 GENERATED 区。
// =============================================================================

// -----------------------------------------------------------------------------
// xs_DcsrModule_core —— dcsr 寄存器堆本体
// -----------------------------------------------------------------------------
module xs_DcsrModule_core (
  input  logic        clock,
  input  logic        reset,            // 异步、高有效
  input  logic        csr_wen,          // dcsr 软件写口（字段位见 rdata 拼接注释）
  input  logic [63:0] csr_wdata,
  input  logic        trap_valid,       // 进入调试模式：锁存 cause/v/prv
  input  logic [2:0]  trap_cause,
  input  logic        trap_v,
  input  logic [1:0]  trap_prv,
  input  logic        dret_valid,       // dret 返回：回写 v/prv
  input  logic        dret_v,
  input  logic [1:0]  dret_prv,
  input  logic        nmip,             // NMI 挂起（只读直通，不落寄存器）
  output logic [31:0] rdata,
  output logic        f_cetrig,
  output logic        f_ebreakvs,
  output logic        f_ebreakvu,
  output logic        f_ebreakm,
  output logic        f_ebreaks,
  output logic        f_ebreaku,
  output logic        f_stepie,
  output logic        f_stopcount,
  output logic        f_stoptime,
  output logic [2:0]  f_cause,
  output logic        f_v,
  output logic        f_mprven,
  output logic        f_nmip,
  output logic        f_step,
  output logic [1:0]  f_prv
);
  logic       cetrig_q;     // [19] 关键错误调试入口的触发器重入控制
  logic       ebreakvs_q;   // [17] VS 态 ebreak 进调试
  logic       ebreakvu_q;   // [16] VU 态 ebreak 进调试
  logic       ebreakm_q;    // [15] M 态 ebreak 进调试
  logic       ebreaks_q;    // [13] HS 态 ebreak 进调试
  logic       ebreaku_q;    // [12] HU 态 ebreak 进调试
  logic       stepie_q;     // [11] 单步期间保持中断使能
  logic       stopcount_q;  // [10] 调试态停计数器
  logic       stoptime_q;   // [9]  调试态停 time
  logic [2:0] cause_q;      // [8:6] 最近一次进调试的原因
  logic       v_q;          // [5]  进调试前的虚拟化态
  logic       mprven_q;     // [4]  调试态放行 mstatus.MPRV
  logic       step_q;       // [2]  单步使能
  logic [1:0] prv_q;        // [1:0] 进调试前的特权级（复位 = M 态）

  // PRV 是 WARL 字段：合法特权级编码只有 {U=0, S=1, M=3}，写保留值 2 不构成软件写使能。
  // golden 原文是「==0 | ==1 | 两位全 1」三项或，对全部 4 个取值逐点等价于「不等于 2」。
  logic prv_wlegal;
  assign prv_wlegal = (csr_wdata[1:0] != 2'h2);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      cetrig_q    <= 1'b0;
      ebreakvs_q  <= 1'b0;
      ebreakvu_q  <= 1'b0;
      ebreakm_q   <= 1'b0;
      ebreaks_q   <= 1'b0;
      ebreaku_q   <= 1'b0;
      stepie_q    <= 1'b0;
      stopcount_q <= 1'b0;
      stoptime_q  <= 1'b0;
      cause_q     <= 3'h0;
      v_q         <= 1'b0;
      mprven_q    <= 1'b0;
      step_q      <= 1'b0;
      prv_q       <= 2'h3;   // 复位在 M 态
    end
    else begin
      // 纯软件写字段：仅 CSR 写口一路来源
      if (csr_wen) begin
        cetrig_q    <= csr_wdata[19];
        ebreakvs_q  <= csr_wdata[17];
        ebreakvu_q  <= csr_wdata[16];
        ebreakm_q   <= csr_wdata[15];
        ebreaks_q   <= csr_wdata[13];
        ebreaku_q   <= csr_wdata[12];
        stepie_q    <= csr_wdata[11];
        stopcount_q <= csr_wdata[10];
        stoptime_q  <= csr_wdata[9];
        mprven_q    <= csr_wdata[4];
        step_q      <= csr_wdata[2];
      end
      // cause：只在进入调试时更新；同拍的软件写按位或进来
      if (trap_valid)
        cause_q <= trap_cause | (csr_wen ? csr_wdata[8:6] : 3'h0);
      // v：trap / dret / 软件写三源按位或（golden 原文即 AND-OR 形状，非优先级 mux）
      if (trap_valid | dret_valid | csr_wen)
        v_q <= (trap_valid & trap_v) | (dret_valid & dret_v) | (csr_wen & csr_wdata[5]);
      // prv：WARL 合法性只挡在使能侧——trap/dret 与软件写同拍时，即使软件写的是
      // 保留值 2，wdata[1:0] 仍按位或进次态（golden 的不对称，照抄，不许抹平）。
      if (trap_valid | dret_valid | (csr_wen & prv_wlegal))
        prv_q <= (trap_valid ? trap_prv : 2'h0)
               | (dret_valid  ? dret_prv : 2'h0)
               | (csr_wen     ? csr_wdata[1:0] : 2'h0);
    end
  end

  // 整字读：高 12 位 12'h400 = DEBUGVER[31:28]=4（调试规范 v1.0）+ EXTCAUSE[26:24]=0；
  // [18]/[14] 保留为 0；NMIP[3] 只读，直通 nmip 输入。
  assign rdata = {12'h400,
                  cetrig_q,                // 19
                  1'b0,                    // 18 保留
                  ebreakvs_q,              // 17
                  ebreakvu_q,              // 16
                  ebreakm_q,               // 15
                  1'b0,                    // 14 保留
                  ebreaks_q,               // 13
                  ebreaku_q,               // 12
                  stepie_q,                // 11
                  stopcount_q,             // 10
                  stoptime_q,              // 9
                  cause_q,                 // 8:6
                  v_q,                     // 5
                  mprven_q,                // 4
                  nmip,                    // 3
                  step_q,                  // 2
                  prv_q};                  // 1:0

  assign f_cetrig    = cetrig_q;
  assign f_ebreakvs  = ebreakvs_q;
  assign f_ebreakvu  = ebreakvu_q;
  assign f_ebreakm   = ebreakm_q;
  assign f_ebreaks   = ebreaks_q;
  assign f_ebreaku   = ebreaku_q;
  assign f_stepie    = stepie_q;
  assign f_stopcount = stopcount_q;
  assign f_stoptime  = stoptime_q;
  assign f_cause     = cause_q;
  assign f_v         = v_q;
  assign f_mprven    = mprven_q;
  assign f_nmip      = nmip;    // 只读直通
  assign f_step      = step_q;
  assign f_prv       = prv_q;
endmodule

// BEGIN GENERATED(csrctl5) —— 由 scripts/gen_csrctl_leaves5.py 从 golden 端口表产出，勿手改
module DcsrModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [31:0] rdata,
  output        regOut_CETRIG,
  output        regOut_EBREAKVS,
  output        regOut_EBREAKVU,
  output        regOut_EBREAKM,
  output        regOut_EBREAKS,
  output        regOut_EBREAKU,
  output        regOut_STEPIE,
  output        regOut_STOPCOUNT,
  output        regOut_STOPTIME,
  output [2:0]  regOut_CAUSE,
  output        regOut_V,
  output        regOut_MPRVEN,
  output        regOut_NMIP,
  output        regOut_STEP,
  output [1:0]  regOut_PRV,
  input         trapToD_dcsr_valid,
  input  [2:0]  trapToD_dcsr_bits_CAUSE,
  input         trapToD_dcsr_bits_V,
  input  [1:0]  trapToD_dcsr_bits_PRV,
  input         retFromD_dcsr_valid,
  input         retFromD_dcsr_bits_V,
  input  [1:0]  retFromD_dcsr_bits_PRV,
  input         nmip
);

  xs_DcsrModule_core u_core (
    .clock       (clock),
    .reset       (reset),
    .csr_wen     (w_wen),
    .csr_wdata   (w_wdata),
    .trap_valid  (trapToD_dcsr_valid),
    .trap_cause  (trapToD_dcsr_bits_CAUSE),
    .trap_v      (trapToD_dcsr_bits_V),
    .trap_prv    (trapToD_dcsr_bits_PRV),
    .dret_valid  (retFromD_dcsr_valid),
    .dret_v      (retFromD_dcsr_bits_V),
    .dret_prv    (retFromD_dcsr_bits_PRV),
    .nmip        (nmip),
    .rdata       (rdata),
    .f_cetrig    (regOut_CETRIG),
    .f_ebreakvs  (regOut_EBREAKVS),
    .f_ebreakvu  (regOut_EBREAKVU),
    .f_ebreakm   (regOut_EBREAKM),
    .f_ebreaks   (regOut_EBREAKS),
    .f_ebreaku   (regOut_EBREAKU),
    .f_stepie    (regOut_STEPIE),
    .f_stopcount (regOut_STOPCOUNT),
    .f_stoptime  (regOut_STOPTIME),
    .f_cause     (regOut_CAUSE),
    .f_v         (regOut_V),
    .f_mprven    (regOut_MPRVEN),
    .f_nmip      (regOut_NMIP),
    .f_step      (regOut_STEP),
    .f_prv       (regOut_PRV)
  );
endmodule
// END GENERATED
