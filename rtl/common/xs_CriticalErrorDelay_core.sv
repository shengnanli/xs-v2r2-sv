// =============================================================================
// xs_CriticalErrorDelay_core —— 致命错误上报的两拍打拍（utility.HasCriticalErrors）
// -----------------------------------------------------------------------------
// 设计源：utility/src/main/scala/utility/CriticalErrorUtils.scala（trait HasCriticalErrors）。
//   每个混入 HasCriticalErrors 的模块把自己收集到的 criticalErrors 逐条接到 io_error(i)：
//       io_error(i) := RegNext(RegNext(error_i))
//   即**每经过一层**就再打两拍（切长走线，致命错误晚几拍上报无所谓）。不复位。
//   noRegNext 参数（直连不打拍）在本配置里没有调用点用到。
// 在哪里用：ExeUnit_7（CSR 外壳，error 来自 CSR）与 ExuBlock（error 来自 ExeUnit_7）——
//   两层各一份，所以 CSR 的错误到 ExuBlock 口上一共晚 4 拍（CSR 自己内部另有打拍）。
// 参数：N = 本层错误条数（golden 里 io_error_0 .. io_error_{N-1}）。
// 复位：无（与 golden 同：两级寄存器都不复位，上电值要等两拍才被冲掉）。
// =============================================================================
module xs_CriticalErrorDelay_core #(
  parameter int unsigned N = 1          // 错误条数
) (
  input  logic         clock,
  input  logic [N-1:0] err_in,          // 下层送上来的 error（本拍值）
  output logic [N-1:0] err_out          // 打两拍后送本层 io_error
);

  logic [N-1:0] stage1_q;               // RegNext(error)
  logic [N-1:0] stage2_q;               // RegNext(RegNext(error))

  always_ff @(posedge clock) begin
    stage1_q <= err_in;
    stage2_q <= stage1_q;
  end

  assign err_out = stage2_q;

endmodule
