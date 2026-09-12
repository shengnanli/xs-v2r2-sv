// Dispatcher_study.sv —— ExeUnit 入口的 1→N 分发器（可读重写 / 学习材料）
//
// 位置：整数执行口 ExeUnit 的最前面一级。上游发射队列(IssueQueue)把一条 uop
//       送进 ExeUnit 的 io_in，这个模块负责决定"这条 uop 该进哪个功能单元(FU)"。
// 机制：uop 的 fuType 是 **35 位独热码**（一位一种功能单元，见 FuType.scala）。
//       分发器把它和本 ExeUnit 内每个 FU 认领的那一位做**相等比较**，命中即把
//       io_in.valid 拉到那一路。本执行口 = {Alu(bit6), Mul(bit7), Bku(bit10)}。
//       反压方向相反：io_in.ready = 三路 ready 的**与**（保守，见 §2 注释）。
//       数据(fuOpType / perf / seqNum)不做选择，三路同时广播，靠 valid 挑。
//
//   in_fuType[34:0] ──┬─ ==1<<6  ─▶ hit_alu ─& in_valid ─▶ out_valid[0] ─▶ Alu
//                     ├─ ==1<<7  ─▶ hit_mul ─& in_valid ─▶ out_valid[1] ─▶ Mul
//                     └─ ==1<<10 ─▶ hit_bku ─& in_valid ─▶ out_valid[2] ─▶ Bku
//   in_ready  ◀── & {out_ready[0], out_ready[1], out_ready[2]}
//
// ★ 本文件是 **verif/study 下的学习材料**，不是 rtl/ 里的交付重写：
//   - 顶层 wrapper 直接叫 Dispatcher_xs（不叫 golden 同名的 Dispatcher），
//     因为学习台 tb 要把 golden Dispatcher 和它**同时**编进一次 elaboration，
//     同名会撞。rtl/ 里的正式重写按 CONVENTIONS 用 golden 同名 wrapper +
//     scripts/derive_ut_impl.py 派生 _xs 副本，这里省掉派生这一步，
//     让你在 Verdi 里看到的源码就是我手写的这一份，一个字都没被脚本改过。
//   - 端口与 G1 golden Dispatcher 逐位同名同宽（跑过 tb 的逐拍比对器）。
// ============================================================================

package dispatcher_study_pkg;

  localparam int NUM_FU   = 3;   // 本执行口内的功能单元个数
  localparam int FUTYPE_W = 35;  // FuType 独热码宽度（全芯片统一，不随执行口变）

  // 本执行口三个 FU 各自认领的 fuType 独热位编号。
  // 数字来自 src/main/scala/xiangshan/backend/fu/FuType.scala 里 OHEnumeration
  // 的声明顺序：jmp=0, brh=1, i2f=2, i2v=3, f2v=4, csr=5, alu=6, mul=7,
  //            div=8, fence=9, bku=10, ...
  localparam int FU_BIT [NUM_FU] = '{6, 7, 10};   // 0:Alu  1:Mul  2:Bku

endpackage : dispatcher_study_pkg


// ----------------------------------------------------------------------------
// xs_Dispatcher_study_core —— 可读核
// ----------------------------------------------------------------------------
// clock/reset 在 golden 里只喂断言（`ifndef SYNTHESIS 的 $fwrite），功能上用不到；
// 这里保留同样的端口和同样的两条断言，位置对齐，方便你对着 golden 读。
module xs_Dispatcher_study_core
  import dispatcher_study_pkg::*;
(
  input  logic                clock,
  input  logic                reset,

  // ---- 上游（发射口）----
  output logic                in_ready,
  input  logic                in_valid,
  input  logic [FUTYPE_W-1:0] in_fuType,

  // ---- 下游（三个 FU）----
  input  logic [NUM_FU-1:0]   out_ready,
  output logic [NUM_FU-1:0]   out_valid
);

  // ==========================================================================
  // §1 路由：35 位独热码的相等比较
  // --------------------------------------------------------------------------
  // 为什么是 `==` 而不是 `in_fuType[FU_BIT[i]]`（取一位）？
  //   因为 fuType 在这一层被约定为**严格独热**（一条 uop 只属于一种 FU）。
  //   用整字相等比较，等价于"这一位是 1 且其余全 0"，多设一位就谁也不命中，
  //   会被 §3 的第二条断言抓住。golden 也是整字比较（acceptVec_N）。
  //   代价是 35 位比较器 ×3；收益是错误编码不会被静默地分发到某个 FU。
  // ==========================================================================
  logic [NUM_FU-1:0] accept;      // golden: acceptVec_0 / _1 / _2

  for (genvar i = 0; i < NUM_FU; i++) begin : g_accept
    assign accept[i] = (in_fuType == (FUTYPE_W'(1) << FU_BIT[i]));
  end

  // 给三根线起人话名字，方便直接拖进 Verdi（与 accept[i] 是同一根线）。
  wire hit_alu = accept[0];       // golden: acceptVec_0  (fuType == 35'h40)
  wire hit_mul = accept[1];       // golden: acceptVec_1  (fuType == 35'h80)
  wire hit_bku = accept[2];       // golden: acceptVec_2  (fuType == 35'h400)

  assign out_valid = accept & {NUM_FU{in_valid}};

  // ==========================================================================
  // §2 反压：in_ready = 三路 ready 的**与**
  // --------------------------------------------------------------------------
  // 注意这里**不是** Mux1H（"只看被命中那一路的 ready"），而是保守的与归约：
  //   只要任何一个 FU 满了，整个执行口就不收新指令 —— 哪怕这条 uop 要去的是
  //   空着的那个 FU。这是香山有意选的简化（省掉 ready 上的 fuType 选择逻辑，
  //   缩短发射侧关键路径），代价是执行口内部会有一点假阻塞。
  //   本执行口里 Alu.in_ready = out_ready（组合直通），Mul/Bku.in_ready =
  //   各自的 rdyVec 链；整数写回口的 out_ready 在 ExuBlock 里硬接 1，
  //   所以真实芯片里这三个 ready 恒 1，这条与归约恒 1，假阻塞不会发生。
  // ==========================================================================
  assign in_ready = &out_ready;

  // ==========================================================================
  // §3 断言：与 golden 同样的两条（golden 在 `ifndef SYNTHESIS 里）
  //   a) 至多命中一路   b) valid 时至少命中一路
  // 本学习台默认带 +define+SYNTHESIS 编译（和 golden 一致地关掉），
  // 想看断言就去掉那个 define 重编。
  // ==========================================================================
`ifndef SYNTHESIS
  always @(posedge clock) begin
    if (!reset) begin
      if ($countones(accept) > 1)
        $error("[Dispatcher] fuType=%b 同时命中多个 FU（应为独热）", in_fuType);
      if (in_valid && accept == '0)
        $error("[Dispatcher] fuType=%b 谁也不认领（这条 uop 进错执行口了）", in_fuType);
    end
  end
`endif

endmodule : xs_Dispatcher_study_core


// ----------------------------------------------------------------------------
// Dispatcher_xs —— 与 G1 golden `Dispatcher` 端口逐位同名同宽的外壳
// ----------------------------------------------------------------------------
// 做两件事：(1) 把扁平端口收拢成可读核的向量端口；
//           (2) perf / seqNum 的**纯扇出**（golden 也是逐字段直连，三路同值，
//               完全不参与路由；放在 wrapper 里，核里就不用被 12 根观测线淹没）。
module Dispatcher_xs(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0]  io_in_bits_fuOpType,
  input         io_in_bits_perfDebugInfo_eliminatedMove,
  input  [63:0] io_in_bits_perfDebugInfo_renameTime,
  input  [63:0] io_in_bits_perfDebugInfo_dispatchTime,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  input  [63:0] io_in_bits_perfDebugInfo_writebackTime,
  input  [63:0] io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0] io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0] io_in_bits_perfDebugInfo_tlbRespTime,
  input  [55:0] io_in_bits_debug_seqNum_seqNum,
  input  [7:0]  io_in_bits_debug_seqNum_uopIdx,
  input         io_out_0_ready,
  output        io_out_0_valid,
  output [8:0]  io_out_0_bits_fuOpType,
  output        io_out_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0] io_out_0_bits_perfDebugInfo_renameTime,
  output [63:0] io_out_0_bits_perfDebugInfo_dispatchTime,
  output [63:0] io_out_0_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_0_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_0_bits_perfDebugInfo_issueTime,
  output [63:0] io_out_0_bits_perfDebugInfo_writebackTime,
  output [63:0] io_out_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0] io_out_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0] io_out_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0] io_out_0_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_0_bits_debug_seqNum_uopIdx,
  input         io_out_1_ready,
  output        io_out_1_valid,
  output [8:0]  io_out_1_bits_fuOpType,
  output        io_out_1_bits_perfDebugInfo_eliminatedMove,
  output [63:0] io_out_1_bits_perfDebugInfo_renameTime,
  output [63:0] io_out_1_bits_perfDebugInfo_dispatchTime,
  output [63:0] io_out_1_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_1_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_1_bits_perfDebugInfo_issueTime,
  output [63:0] io_out_1_bits_perfDebugInfo_writebackTime,
  output [63:0] io_out_1_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0] io_out_1_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0] io_out_1_bits_perfDebugInfo_tlbRespTime,
  output [55:0] io_out_1_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_1_bits_debug_seqNum_uopIdx,
  input         io_out_2_ready,
  output        io_out_2_valid,
  output [8:0]  io_out_2_bits_fuOpType,
  output        io_out_2_bits_perfDebugInfo_eliminatedMove,
  output [63:0] io_out_2_bits_perfDebugInfo_renameTime,
  output [63:0] io_out_2_bits_perfDebugInfo_dispatchTime,
  output [63:0] io_out_2_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_2_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_2_bits_perfDebugInfo_issueTime,
  output [63:0] io_out_2_bits_perfDebugInfo_writebackTime,
  output [63:0] io_out_2_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0] io_out_2_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0] io_out_2_bits_perfDebugInfo_tlbRespTime,
  output [55:0] io_out_2_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_2_bits_debug_seqNum_uopIdx
);

  logic [2:0] fu_valid;

  xs_Dispatcher_study_core u_core (
    .clock     (clock),
    .reset     (reset),
    .in_ready  (io_in_ready),
    .in_valid  (io_in_valid),
    .in_fuType (io_in_bits_fuType),
    .out_ready ({io_out_2_ready, io_out_1_ready, io_out_0_ready}),
    .out_valid (fu_valid)
  );

  assign io_out_0_valid = fu_valid[0];
  assign io_out_1_valid = fu_valid[1];
  assign io_out_2_valid = fu_valid[2];

  // ---- 广播段：fuOpType / perf / seqNum 三路同值直通，不参与路由 ----
  assign io_out_0_bits_fuOpType = io_in_bits_fuOpType;
  assign io_out_1_bits_fuOpType = io_in_bits_fuOpType;
  assign io_out_2_bits_fuOpType = io_in_bits_fuOpType;

  assign io_out_0_bits_perfDebugInfo_eliminatedMove          = io_in_bits_perfDebugInfo_eliminatedMove;
  assign io_out_0_bits_perfDebugInfo_renameTime              = io_in_bits_perfDebugInfo_renameTime;
  assign io_out_0_bits_perfDebugInfo_dispatchTime            = io_in_bits_perfDebugInfo_dispatchTime;
  assign io_out_0_bits_perfDebugInfo_enqRsTime               = io_in_bits_perfDebugInfo_enqRsTime;
  assign io_out_0_bits_perfDebugInfo_selectTime              = io_in_bits_perfDebugInfo_selectTime;
  assign io_out_0_bits_perfDebugInfo_issueTime               = io_in_bits_perfDebugInfo_issueTime;
  assign io_out_0_bits_perfDebugInfo_writebackTime           = io_in_bits_perfDebugInfo_writebackTime;
  assign io_out_0_bits_perfDebugInfo_runahead_checkpoint_id  = io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_out_0_bits_perfDebugInfo_tlbFirstReqTime         = io_in_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_out_0_bits_perfDebugInfo_tlbRespTime             = io_in_bits_perfDebugInfo_tlbRespTime;
  assign io_out_0_bits_debug_seqNum_seqNum                   = io_in_bits_debug_seqNum_seqNum;
  assign io_out_0_bits_debug_seqNum_uopIdx                   = io_in_bits_debug_seqNum_uopIdx;

  assign io_out_1_bits_perfDebugInfo_eliminatedMove          = io_in_bits_perfDebugInfo_eliminatedMove;
  assign io_out_1_bits_perfDebugInfo_renameTime              = io_in_bits_perfDebugInfo_renameTime;
  assign io_out_1_bits_perfDebugInfo_dispatchTime            = io_in_bits_perfDebugInfo_dispatchTime;
  assign io_out_1_bits_perfDebugInfo_enqRsTime               = io_in_bits_perfDebugInfo_enqRsTime;
  assign io_out_1_bits_perfDebugInfo_selectTime              = io_in_bits_perfDebugInfo_selectTime;
  assign io_out_1_bits_perfDebugInfo_issueTime               = io_in_bits_perfDebugInfo_issueTime;
  assign io_out_1_bits_perfDebugInfo_writebackTime           = io_in_bits_perfDebugInfo_writebackTime;
  assign io_out_1_bits_perfDebugInfo_runahead_checkpoint_id  = io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_out_1_bits_perfDebugInfo_tlbFirstReqTime         = io_in_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_out_1_bits_perfDebugInfo_tlbRespTime             = io_in_bits_perfDebugInfo_tlbRespTime;
  assign io_out_1_bits_debug_seqNum_seqNum                   = io_in_bits_debug_seqNum_seqNum;
  assign io_out_1_bits_debug_seqNum_uopIdx                   = io_in_bits_debug_seqNum_uopIdx;

  assign io_out_2_bits_perfDebugInfo_eliminatedMove          = io_in_bits_perfDebugInfo_eliminatedMove;
  assign io_out_2_bits_perfDebugInfo_renameTime              = io_in_bits_perfDebugInfo_renameTime;
  assign io_out_2_bits_perfDebugInfo_dispatchTime            = io_in_bits_perfDebugInfo_dispatchTime;
  assign io_out_2_bits_perfDebugInfo_enqRsTime               = io_in_bits_perfDebugInfo_enqRsTime;
  assign io_out_2_bits_perfDebugInfo_selectTime              = io_in_bits_perfDebugInfo_selectTime;
  assign io_out_2_bits_perfDebugInfo_issueTime               = io_in_bits_perfDebugInfo_issueTime;
  assign io_out_2_bits_perfDebugInfo_writebackTime           = io_in_bits_perfDebugInfo_writebackTime;
  assign io_out_2_bits_perfDebugInfo_runahead_checkpoint_id  = io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_out_2_bits_perfDebugInfo_tlbFirstReqTime         = io_in_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_out_2_bits_perfDebugInfo_tlbRespTime             = io_in_bits_perfDebugInfo_tlbRespTime;
  assign io_out_2_bits_debug_seqNum_seqNum                   = io_in_bits_debug_seqNum_seqNum;
  assign io_out_2_bits_debug_seqNum_uopIdx                   = io_in_bits_debug_seqNum_uopIdx;

endmodule
