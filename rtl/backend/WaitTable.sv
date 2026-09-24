// =============================================================================
// WaitTable.sv —— 21264 式 load 等待表（访存相关性预测器的第二张表）
// -----------------------------------------------------------------------------
// 设计源: XiangShan src/main/scala/xiangshan/mem/mdp/WaitTable.scala
// golden 对照: G1-canonical/golden-rtl/WaitTable.sv（9,481 行，单变体）
// 层次位置: SimTop…backend.inner.ctrlBlock.memCtrl.waittable
//
// ★ 它是什么 ★
// 1024 项 × 2 位饱和移位计数器，按 load 的折叠 PC（MemPredPCWidth=10 位）索引。
// 一条 load 因访存违例被回放时（RedirectGenerator 发出 memPredUpdate），把它的表项
// 左移一位并填 1：0→01→11。计数器高位为 1 表示「这条 load 该等前面的 store」。
// 表每隔一段时间整体清零（周期由 csrCtrl.lvpred_timeout 选：resetCounter 自增，
// 取其 [19:10] 右移 timeout 后的最低位为 1 即触发），让过时的预测衰减掉。
//
// ★ golden 事实（KunminghuV2Config，firtool -O=release）★
//   - **本模块没有任何输出端口**：Chisel 的 io.rdata（loadWaitBit 送 rename）在
//     golden 里被整条裁掉（消费者没读），golden 端口 = 5 个全 input。于是本模块的
//     可观测状态只有 1024 项表 + resetCounter + timeout 寄存器，UT 走层次探针比对。
//   - 清零与更新同拍时**清零赢**（golden 是 `else if (timeout) 清零 else 更新`）。
//   - REG(=RegNext(lvpred_timeout)) 无复位；data/resetCounter 异步复位为 0。
//   - 上游 MemCtrl 已经把 memPredUpdate 与 csrCtrl 各打了一拍，这里 timeout 再打一拍。
// =============================================================================

module xs_WaitTable_core #(
  parameter int unsigned N_ENTRIES = 1024,   // WaitTableSize
  parameter int unsigned PC_W      = 10,     // MemPredPCWidth
  parameter int unsigned CNT_W     = 20,     // ResetTimeMax2Pow
  parameter int unsigned MIN2POW   = 10,     // ResetTimeMin2Pow
  parameter int unsigned TIMEOUT_W = 5       // lvpred_timeout 位宽
)(
  input  logic                 clock,
  input  logic                 reset,
  input  logic                 update_valid,
  input  logic [PC_W-1:0]      update_waddr,
  input  logic [TIMEOUT_W-1:0] lvpred_timeout
);

  // 表体：每项 2 位移位计数器（golden: data_0 … data_1023）
  logic [N_ENTRIES-1:0][1:0] data;
  // 衰减周期计数器
  logic [CNT_W-1:0]          resetCounter;
  // lvpred_timeout 再打一拍（golden 名 REG，无复位）
  logic [TIMEOUT_W-1:0]      timeout_q;

  always_ff @(posedge clock)
    timeout_q <= lvpred_timeout;

  // 超时判定：resetCounter[19:10] 右移 timeout 后的最低位。timeout >= 10 时移空、恒 0。
  logic [CNT_W-MIN2POW-1:0] timeout_window;
  assign timeout_window = resetCounter[CNT_W-1:MIN2POW] >> timeout_q;
  wire  timeout_fire   = timeout_window[0];

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      data         <= '0;
      resetCounter <= '0;
    end else if (timeout_fire) begin
      // 整表衰减：清零并重新计时（同拍的更新被丢弃，照 golden）
      data         <= '0;
      resetCounter <= '0;
    end else begin
      if (update_valid)
        data[update_waddr] <= {data[update_waddr][0], 1'b1};
      resetCounter <= resetCounter + 1'b1;
    end
  end

endmodule : xs_WaitTable_core

module WaitTable(
  input       clock,
  input       reset,
  input       io_update_valid,
  input [9:0] io_update_waddr,
  input [4:0] io_csrCtrl_lvpred_timeout
);
  xs_WaitTable_core u_core (
    .clock          (clock),
    .reset          (reset),
    .update_valid   (io_update_valid),
    .update_waddr   (io_update_waddr),
    .lvpred_timeout (io_csrCtrl_lvpred_timeout)
  );
endmodule
