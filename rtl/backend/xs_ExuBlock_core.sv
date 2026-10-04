// =============================================================================
// xs_ExuBlock_core —— 执行块（ExuBlock）的本层逻辑：每个浮点 / 向量执行单元一份 frm 打拍
// -----------------------------------------------------------------------------
// 设计源：src/main/scala/xiangshan/backend/exu/ExuBlock.scala（class ExuBlockImp）。
// 在哪一层：Backend → 某个调度块（int / fp / vf）对应的 ExuBlock → 若干 ExeUnit（每个 ExeUnit 一个发射口）。
//   ExuBlock 本身几乎只是装配：
//     发射口 io_in_<i>_<j>  ──►  ExeUnit（按 issue block i、exu j 一一对应）──►  写回口 io_out_<i>_<j>
//   ExeUnit 的例化与逐端口连线在各变体的 wrapper（ExuBlock_<k>.sv，由 scripts/gen_exublock.py 从 golden
//   机械生成）里；本核只放这一层**真正的时序逻辑** —— 只有一样：
//
//   §1 frm 打拍：CSR 的浮点舍入模式 io_frm 对每个需要它的 ExeUnit 各打一拍再送进去
//      （Scala `exuio := RegNext(io.frm.get)`，每个 ExeUnit 一份独立寄存器，值恒相同 ——
//      firtool 不合并，这里也逐份保留，FM 按份配对）。不复位。
//
// 本层**没有**的东西（读 Scala 时会看到，但在本配置下不落到这一层的 RTL 里）：
//   * 发射口握手 / 写回仲裁：ready、valid、bits 全部直连 ExeUnit（out.ready 由上层给或恒 1）；
//   * 唤醒、og0/og1 取消：在 IssueQueue / DataPath 里做，ExuBlock 只是把 ExeUnit 的写回原样送出；
//   * 性能计数（每个 ExeUnit 的 in.fire 计数、alu/brh fire 分布）：综合口径下被删，golden 只剩无读者的
//     `_GEN*` 线（fire = ready & valid），这里不复制。
// =============================================================================

module xs_ExuBlock_core #(
  parameter int unsigned N_FRM = 1    // 需要 frm 的 ExeUnit 个数（每个一份打拍寄存器）
) (
  input  logic       clock,
  input  logic [2:0] frm,                  // CSR 的浮点舍入模式
  output logic [2:0] exu_frm [N_FRM]       // 送第 k 个 ExeUnit 的打拍后 frm
);

  // ===========================================================================
  // §1 frm 打拍（每个 ExeUnit 一份，不复位）
  // ===========================================================================
  always_ff @(posedge clock) begin
    for (int k = 0; k < N_FRM; k++) exu_frm[k] <= frm;
  end

endmodule
