// =============================================================================
// CLZ_11 —— 8 位前导零计数（xs_CLZ_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读）：
//   输入 WIDTH = 8 位，输出 OUT_W = 4 位，最低扫描位 SCAN_LOW = 0；
//   扫描范围内没有 1 时输出 NONE = 8；golden 模块体 = 一条 8 项的三元链，
//   无寄存器、无子模块（纯组合）。
//   使用者：VIntMisc64b —— 8 位规格化（向量 vclz.v 的 8 位元素）。
//
// 家族形状：SCAN_LOW=0：扫到第 0 位，全零输入输出 WIDTH=8 —— 教科书意义上的 CLZ。
//
// 结构：golden 端口 -> 设参例化 xs_CLZ_core（优先级方向与 SCAN_LOW 的语义
//   都在 xs_CLZ_core.sv 里讲）-> 直接出。本层只设参数。
//   WIDTH / SCAN_LOW / OUT_W 是三条**各自独立**从 golden 抽出来的事实
//   （前两条来自模块体真正引用到的位，第三条来自端口表），核里的
//   OUT_W == $clog2(NONE+1) 把三者对上；PORT_BITS_IN/OUT 再用 $bits(golden 端口)
//   把端口表本身对一遍。任何一处抄错，time 0 直接 $fatal。
// 自动生成：verif/ut/CLZ/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module CLZ_11(
  input  [7:0] io_in,
  output [3:0] io_out
);

  localparam int unsigned WIDTH    = 8;   // golden io_in 位宽
  localparam int unsigned SCAN_LOW = 0;   // 最低被扫描的位
  localparam int unsigned OUT_W    = 4;   // golden io_out 位宽

  // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
  localparam int unsigned PORT_BITS_IN  = $bits(io_in);
  localparam int unsigned PORT_BITS_OUT = $bits(io_out);

  xs_CLZ_core #(
    .WIDTH        (WIDTH),
    .SCAN_LOW     (SCAN_LOW),
    .OUT_W        (OUT_W),
    .PORT_BITS_IN (PORT_BITS_IN),
    .PORT_BITS_OUT(PORT_BITS_OUT)
  ) u_core (
    .d_in(io_in),
    .cnt (io_out)
  );

endmodule
