// =============================================================================
// CommitStuckCounter —— ROB「提交卡死」看门狗计数器（Rob 的子模块）
//
// 设计源：src/main/scala/xiangshan/backend/rob/CommitStuckCounter.scala，
//         例化处 Rob.scala（commitStuckCounter，width = log2Up(maxCommitStuck) = 21）。
//
// 机制：Rob 每拍给出 io_stuck（本拍没有任何指令提交、且队头不是 MMIO、且不在 WFI）。
//   连续卡住的拍数累加到 21 位计数器 count；只要有一拍不卡就清零。
//   count 全 1（连续卡住 2^21-1 拍）时 io_overflow 拉高，Rob 把它作为 criticalError
//   （"rob_commit_stuck"）报出去。
//
// golden 常量折叠（G1 KunminghuV2 配置下 firtool 已裁掉，本文件照此）：
//   * forceEnable = EnableDifftest||FullBasicDiff = true ⇒ runtimeEnable 端口被消掉，
//     计数条件只剩 io_stuck；
//   * overflowEnabled 在 Rob 侧恒为 true（wfiResume=true）⇒ 端口被消掉，
//     overflow = &count；
//   * io_count 无读者 ⇒ 端口被消掉。
// 复位：count 异步复位为 0（RegInit）。
// =============================================================================
module xs_CommitStuckCounter_core #(
  parameter int WIDTH = 21
) (
  input  logic clock,
  input  logic reset,
  input  logic stuck,
  output logic overflow
);

  logic [WIDTH-1:0] count;

  // 连续卡住就 +1（自然回绕），任何一拍不卡就清零。
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      count <= '0;
    else if (stuck)
      count <= count + 1'b1;
    else
      count <= '0;
  end

  // 计满（全 1）即溢出。
  assign overflow = &count;

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden CommitStuckCounter.sv 逐位一致
// ---------------------------------------------------------------------------
module CommitStuckCounter (
  input  clock,
  input  reset,
  input  io_stuck,
  output io_overflow
);

  xs_CommitStuckCounter_core #(
    .WIDTH (21)
  ) u_core (
    .clock    (clock),
    .reset    (reset),
    .stuck    (io_stuck),
    .overflow (io_overflow)
  );

endmodule
