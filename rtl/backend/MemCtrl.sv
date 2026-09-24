// =============================================================================
// MemCtrl.sv —— 访存相关性预测器（MDP）的装配层：SSIT + WaitTable
// -----------------------------------------------------------------------------
// 设计源: XiangShan src/main/scala/xiangshan/backend/ctrlblock/MemCtrl.scala
// golden 对照: G1-canonical/golden-rtl/MemCtrl.sv（163 行）
// 层次位置: SimTop…backend.inner.ctrlBlock.memCtrl
//
// ★ 它是什么 ★
// CtrlBlock 里承载 load/store 相关性预测的两张表：
//   ssit      —— store set 表（rtl/backend/SSIT.sv，已签核），decode 位置按折叠 PC 读
//   waittable —— load 等待表（rtl/backend/WaitTable.sv）
// 本层只做三件事：把 RedirectGenerator 来的 memPredUpdate 和 csrCtrl.lvpred_timeout
// 各打一拍再喂给两张表（每张表各自一份寄存器副本，降扇出），把 decode 的读请求
// 直连 ssit。
//
// ★ golden 事实（KunminghuV2Config，firtool -O=release）★
//   - Chisel 里还有 LFST（load-store 前瞻表）以及 waitTable2Rename / ssit2Rename
//     两组输出；golden 里 **LFST 整块不存在、输出端口一个都没有**（消费者没读，
//     DCE 连带把 ssit/waittable 的 rdata 链路也裁掉了）。golden 端口 = 11 个全 input。
//   - 打拍寄存器全部无复位（RegNext 无 init）。
//   - waittable 只收 update.valid/waddr（wdata 恒 1 被折叠），decode 读地址不再连它。
// =============================================================================

module xs_MemCtrl_core #(
  parameter int unsigned PC_W      = 10,   // MemPredPCWidth
  parameter int unsigned TIMEOUT_W = 5,
  parameter int unsigned DEC_W     = 2     // DecodeWidth 里真正连到 ssit 读口的数目
)(
  input  logic                 clock,
  input  logic                 reset,
  input  logic [TIMEOUT_W-1:0] csr_lvpred_timeout,
  // 来自 RedirectGenerator 的相关性更新
  input  logic                 memPredUpdate_valid,
  input  logic [PC_W-1:0]      memPredUpdate_waddr,
  input  logic [PC_W-1:0]      memPredUpdate_ldpc,
  input  logic [PC_W-1:0]      memPredUpdate_stpc,
  // decode 侧折叠 PC 读口
  input  logic [DEC_W-1:0]            mdpFoldPcVecVld,
  input  logic [DEC_W-1:0][PC_W-1:0]  mdpFlodPcVec
);

  // 各表一份打拍副本（无复位）。字段名沿用 golden 的展平名，便于对照。
  logic                 ssit_update_q_valid, waittable_update_q_valid;
  logic [PC_W-1:0]      ssit_update_q_ldpc,  ssit_update_q_stpc;
  logic [PC_W-1:0]      waittable_update_q_waddr;
  logic [TIMEOUT_W-1:0] ssit_timeout_q, waittable_timeout_q;

  always_ff @(posedge clock) begin
    ssit_update_q_valid      <= memPredUpdate_valid;
    ssit_update_q_ldpc       <= memPredUpdate_ldpc;
    ssit_update_q_stpc       <= memPredUpdate_stpc;
    waittable_update_q_valid <= memPredUpdate_valid;
    waittable_update_q_waddr <= memPredUpdate_waddr;
    ssit_timeout_q           <= csr_lvpred_timeout;
    waittable_timeout_q      <= csr_lvpred_timeout;
  end

  SSIT ssit (
    .clock                     (clock),
    .reset                     (reset),
    .io_ren_0                  (mdpFoldPcVecVld[0]),
    .io_ren_1                  (mdpFoldPcVecVld[1]),
    .io_raddr_0                (mdpFlodPcVec[0]),
    .io_raddr_1                (mdpFlodPcVec[1]),
    .io_update_valid           (ssit_update_q_valid),
    .io_update_ldpc            (ssit_update_q_ldpc),
    .io_update_stpc            (ssit_update_q_stpc),
    .io_csrCtrl_lvpred_timeout (ssit_timeout_q)
  );

  WaitTable waittable (
    .clock                     (clock),
    .reset                     (reset),
    .io_update_valid           (waittable_update_q_valid),
    .io_update_waddr           (waittable_update_q_waddr),
    .io_csrCtrl_lvpred_timeout (waittable_timeout_q)
  );

endmodule : xs_MemCtrl_core

module MemCtrl(
  input       clock,
  input       reset,
  input [4:0] io_csrCtrl_lvpred_timeout,
  input       io_memPredUpdate_valid,
  input [9:0] io_memPredUpdate_waddr,
  input [9:0] io_memPredUpdate_ldpc,
  input [9:0] io_memPredUpdate_stpc,
  input       io_mdpFoldPcVecVld_0,
  input       io_mdpFoldPcVecVld_1,
  input [9:0] io_mdpFlodPcVec_0,
  input [9:0] io_mdpFlodPcVec_1
);
  xs_MemCtrl_core u_core (
    .clock               (clock),
    .reset               (reset),
    .csr_lvpred_timeout  (io_csrCtrl_lvpred_timeout),
    .memPredUpdate_valid (io_memPredUpdate_valid),
    .memPredUpdate_waddr (io_memPredUpdate_waddr),
    .memPredUpdate_ldpc  (io_memPredUpdate_ldpc),
    .memPredUpdate_stpc  (io_memPredUpdate_stpc),
    .mdpFoldPcVecVld     ({io_mdpFoldPcVecVld_1, io_mdpFoldPcVecVld_0}),
    .mdpFlodPcVec        ({io_mdpFlodPcVec_1, io_mdpFlodPcVec_0})
  );
endmodule
