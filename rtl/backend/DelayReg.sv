// =============================================================================
// xs_delay_reg_core —— 香山 V2R2 通用「延迟 N 拍」移位链核 (可读重写)
// -----------------------------------------------------------------------------
// 设计源:utility/Hold.scala 的 class DelayN —— 把 payload 经 N 个背靠背 RegNext
//   打 N 拍。golden DelayReg 是其 N=3、payload=DiffInstrCommit 的实例。
//
// 行为:每个时钟上升沿,payload 无条件向后一级流动(无握手、无使能);异步复位
//   把所有级清 0(对齐 golden 的 posedge reset 异步复位到 0)。输出 = 第 N 级。
//   => 纯延迟线:out(t) = in(t-N),复位后前 N 拍输出 0。
//
// 参数化:WIDTH 为 payload 总位宽(struct 打平),N 为延迟拍数。核内对 payload 不
//   做任何字段级处理,只整体打拍 —— 这正是 DelayN 的「对任意 bundle 延迟」语义。
//   用 genvar 生成 N 级,而非手工复制 REG/REG_1/REG_2。
// =============================================================================
module xs_delay_reg_core #(
  parameter int WIDTH = 1,   // payload 总位宽
  parameter int N     = 3    // 延迟拍数
) (
  input  logic             clock,
  input  logic             reset,   // 异步、高有效;复位时各级清 0
  input  logic [WIDTH-1:0] in,
  output logic [WIDTH-1:0] out
);

  // N 级流水寄存器:stage[0] = 输入打 1 拍,...,stage[N-1] = 输入打 N 拍。
  // N=0 时退化为直通(generate 处理)。
  generate
    if (N == 0) begin : g_passthrough
      // 无延迟:直接连通(DelayN(0) 即 io.out := io.in)。
      assign out = in;
    end else begin : g_pipe
      logic [WIDTH-1:0] stage [N];

      genvar s;
      for (s = 0; s < N; s++) begin : g_stage
        // 每级的输入:第 0 级取模块输入,其余取前一级。
        // 用 always_ff + 异步复位,逐级前移,与 golden 的 RegNext(init=0) 等价。
        always_ff @(posedge clock or posedge reset) begin
          if (reset)
            stage[s] <= '0;
          else
            stage[s] <= (s == 0) ? in : stage[s-1];
        end
      end

      // 输出 = 最后一级。
      assign out = stage[N-1];
    end
  endgenerate

endmodule : xs_delay_reg_core
