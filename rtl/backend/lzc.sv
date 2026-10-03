// =============================================================================
// lzc —— 53 位前导零计数（fpsqrt_r16{,_vector_r16} 的规格化移位量）
//
// 本变体的参数与规模（按 G1 golden 现读）：输入 53 位，cnt_o 6 位，
//   纯组合、无寄存器、无子模块。
// 语义（Chisel PriorityEncoder 兜底语义，bug-for-bug 照抄）：
//   cnt_o = in_i 的前导零个数（最高置位在第 p 位则 cnt = 52-p）；
//   第 0 位不在显式扫描链里，而是优先级链的无条件末档 —— 仅第 0 位置位时
//   cnt_o = 52，与常规全宽 CLZ 结果相同；
//   ★全零输入★：empty_o = 1 且 cnt_o = 0（golden 链首即 empty|in[52] ? 0
//   —— 是 0，不是 53）。这是与 CLZ.sv 同族的兜底陷阱，照抄不"修正"。
// golden 里的共享中间线只是 firtool 对扫描链的布尔化简，已逐位核对扫描链
//   恰好覆盖第 52..1 位、每一位各一次，无丢位无错位。
// 结构：golden 端口 -> xs_lzc_core（优先级扫描核）-> 直接出。
// 自动生成：scripts/gen_srt_divsqrt_leaves10.py —— 勿手改
// =============================================================================

module xs_lzc_core (
  input  logic [52:0] data_i,
  output logic [5:0] count_o,
  output logic          empty_o
);
  assign empty_o = (data_i == '0);

  // 优先级扫描：最高的置位决定计数；第 0 位是无条件末档（count = 52，
  // 与全宽 CLZ 一致）；全零由 empty 先行截为 0（见文件头）。
  always_comb begin
    count_o = '0;
    if (data_i != '0) begin
      count_o = 6'd52;
      for (int i = 1; i < 53; i++)
        if (data_i[i]) count_o = 6'(52 - i);
    end
  end
endmodule

module lzc (
  input  logic [52:0] in_i,
  output logic [5:0] cnt_o,
  output logic          empty_o
);
  xs_lzc_core u_core (
    .data_i  (in_i),
    .count_o (cnt_o),
    .empty_o (empty_o)
  );
endmodule
