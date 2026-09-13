// =============================================================================
// PriorityMuxModule_4 —— 带兜底源的优先级选择器（xs_PriorityMuxModule_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   候选路数 NUM_WAYS = 4（各带一个 sel）+ 1 路兜底源（无 sel）；
//   载荷字段 NUM_FIELDS = 17，打平后 WIDTH = 140 位；
//   端口 106 个 = 4 个 sel + (4 路 + 兜底 + 输出) × 17 个字段；
//   golden 模块体 = 17 条纯组合三元链，无寄存器 / 无时钟 / 无子模块。
//   优先级（高 -> 低）：s2_FGH_sel > s1_FGH_sel > s3_FGH_sel > redirect_FGHT_sel，全不成立则取 stallFGH_src*。
//   载荷字段：hist_17_folded_hist=11b, hist_16_folded_hist=11b, hist_15_folded_hist=7b, hist_14_folded_hist=8b …共 17 个字段，明细见端口表。
//   用途：Predictor 的 折叠全局历史 FGH（17 条 folded_hist，共 140 位）。
//
// 结构：golden 同名端口表 -> 把每一路的全部字段按输出顺序 MSB 优先拼成一根
//   140 位载荷 -> 设参例化 xs_PriorityMuxModule_core（核体见
//   xs_PriorityMuxModule_core.sv，优先级语义与不变式都在那里讲）-> 拆包回输出端口。
//   PORT_BITS_* 与 GOLDEN_PORTS 用 $bits(端口拼接) / 端口数算出来传给核：
//   任何字段位宽、路数、字段数抄错，time 0 直接 $fatal。
// 自动生成：verif/ut/PriorityMuxModule/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module PriorityMuxModule_4(
  input         s2_FGH_sel,
  input  [10:0] s2_FGH_src_hist_17_folded_hist,
  input  [10:0] s2_FGH_src_hist_16_folded_hist,
  input  [6:0]  s2_FGH_src_hist_15_folded_hist,
  input  [7:0]  s2_FGH_src_hist_14_folded_hist,
  input  [8:0]  s2_FGH_src_hist_13_folded_hist,
  input  [3:0]  s2_FGH_src_hist_12_folded_hist,
  input  [7:0]  s2_FGH_src_hist_11_folded_hist,
  input  [8:0]  s2_FGH_src_hist_10_folded_hist,
  input  [6:0]  s2_FGH_src_hist_9_folded_hist,
  input  [7:0]  s2_FGH_src_hist_8_folded_hist,
  input  [6:0]  s2_FGH_src_hist_7_folded_hist,
  input  [8:0]  s2_FGH_src_hist_6_folded_hist,
  input  [6:0]  s2_FGH_src_hist_5_folded_hist,
  input  [7:0]  s2_FGH_src_hist_4_folded_hist,
  input  [7:0]  s2_FGH_src_hist_3_folded_hist,
  input  [7:0]  s2_FGH_src_hist_2_folded_hist,
  input  [10:0] s2_FGH_src_hist_1_folded_hist,
  input         s1_FGH_sel,
  input  [10:0] s1_FGH_src_hist_17_folded_hist,
  input  [10:0] s1_FGH_src_hist_16_folded_hist,
  input  [6:0]  s1_FGH_src_hist_15_folded_hist,
  input  [7:0]  s1_FGH_src_hist_14_folded_hist,
  input  [8:0]  s1_FGH_src_hist_13_folded_hist,
  input  [3:0]  s1_FGH_src_hist_12_folded_hist,
  input  [7:0]  s1_FGH_src_hist_11_folded_hist,
  input  [8:0]  s1_FGH_src_hist_10_folded_hist,
  input  [6:0]  s1_FGH_src_hist_9_folded_hist,
  input  [7:0]  s1_FGH_src_hist_8_folded_hist,
  input  [6:0]  s1_FGH_src_hist_7_folded_hist,
  input  [8:0]  s1_FGH_src_hist_6_folded_hist,
  input  [6:0]  s1_FGH_src_hist_5_folded_hist,
  input  [7:0]  s1_FGH_src_hist_4_folded_hist,
  input  [7:0]  s1_FGH_src_hist_3_folded_hist,
  input  [7:0]  s1_FGH_src_hist_2_folded_hist,
  input  [10:0] s1_FGH_src_hist_1_folded_hist,
  input         s3_FGH_sel,
  input  [10:0] s3_FGH_src_hist_17_folded_hist,
  input  [10:0] s3_FGH_src_hist_16_folded_hist,
  input  [6:0]  s3_FGH_src_hist_15_folded_hist,
  input  [7:0]  s3_FGH_src_hist_14_folded_hist,
  input  [8:0]  s3_FGH_src_hist_13_folded_hist,
  input  [3:0]  s3_FGH_src_hist_12_folded_hist,
  input  [7:0]  s3_FGH_src_hist_11_folded_hist,
  input  [8:0]  s3_FGH_src_hist_10_folded_hist,
  input  [6:0]  s3_FGH_src_hist_9_folded_hist,
  input  [7:0]  s3_FGH_src_hist_8_folded_hist,
  input  [6:0]  s3_FGH_src_hist_7_folded_hist,
  input  [8:0]  s3_FGH_src_hist_6_folded_hist,
  input  [6:0]  s3_FGH_src_hist_5_folded_hist,
  input  [7:0]  s3_FGH_src_hist_4_folded_hist,
  input  [7:0]  s3_FGH_src_hist_3_folded_hist,
  input  [7:0]  s3_FGH_src_hist_2_folded_hist,
  input  [10:0] s3_FGH_src_hist_1_folded_hist,
  input         redirect_FGHT_sel,
  input  [10:0] redirect_FGHT_src_hist_17_folded_hist,
  input  [10:0] redirect_FGHT_src_hist_16_folded_hist,
  input  [6:0]  redirect_FGHT_src_hist_15_folded_hist,
  input  [7:0]  redirect_FGHT_src_hist_14_folded_hist,
  input  [8:0]  redirect_FGHT_src_hist_13_folded_hist,
  input  [3:0]  redirect_FGHT_src_hist_12_folded_hist,
  input  [7:0]  redirect_FGHT_src_hist_11_folded_hist,
  input  [8:0]  redirect_FGHT_src_hist_10_folded_hist,
  input  [6:0]  redirect_FGHT_src_hist_9_folded_hist,
  input  [7:0]  redirect_FGHT_src_hist_8_folded_hist,
  input  [6:0]  redirect_FGHT_src_hist_7_folded_hist,
  input  [8:0]  redirect_FGHT_src_hist_6_folded_hist,
  input  [6:0]  redirect_FGHT_src_hist_5_folded_hist,
  input  [7:0]  redirect_FGHT_src_hist_4_folded_hist,
  input  [7:0]  redirect_FGHT_src_hist_3_folded_hist,
  input  [7:0]  redirect_FGHT_src_hist_2_folded_hist,
  input  [10:0] redirect_FGHT_src_hist_1_folded_hist,
  input  [10:0] stallFGH_src_hist_17_folded_hist,
  input  [10:0] stallFGH_src_hist_16_folded_hist,
  input  [6:0]  stallFGH_src_hist_15_folded_hist,
  input  [7:0]  stallFGH_src_hist_14_folded_hist,
  input  [8:0]  stallFGH_src_hist_13_folded_hist,
  input  [3:0]  stallFGH_src_hist_12_folded_hist,
  input  [7:0]  stallFGH_src_hist_11_folded_hist,
  input  [8:0]  stallFGH_src_hist_10_folded_hist,
  input  [6:0]  stallFGH_src_hist_9_folded_hist,
  input  [7:0]  stallFGH_src_hist_8_folded_hist,
  input  [6:0]  stallFGH_src_hist_7_folded_hist,
  input  [8:0]  stallFGH_src_hist_6_folded_hist,
  input  [6:0]  stallFGH_src_hist_5_folded_hist,
  input  [7:0]  stallFGH_src_hist_4_folded_hist,
  input  [7:0]  stallFGH_src_hist_3_folded_hist,
  input  [7:0]  stallFGH_src_hist_2_folded_hist,
  input  [10:0] stallFGH_src_hist_1_folded_hist,
  output [10:0] out_res_hist_17_folded_hist,
  output [10:0] out_res_hist_16_folded_hist,
  output [6:0]  out_res_hist_15_folded_hist,
  output [7:0]  out_res_hist_14_folded_hist,
  output [8:0]  out_res_hist_13_folded_hist,
  output [3:0]  out_res_hist_12_folded_hist,
  output [7:0]  out_res_hist_11_folded_hist,
  output [8:0]  out_res_hist_10_folded_hist,
  output [6:0]  out_res_hist_9_folded_hist,
  output [7:0]  out_res_hist_8_folded_hist,
  output [6:0]  out_res_hist_7_folded_hist,
  output [8:0]  out_res_hist_6_folded_hist,
  output [6:0]  out_res_hist_5_folded_hist,
  output [7:0]  out_res_hist_4_folded_hist,
  output [7:0]  out_res_hist_3_folded_hist,
  output [7:0]  out_res_hist_2_folded_hist,
  output [10:0] out_res_hist_1_folded_hist
);

  localparam int unsigned NUM_WAYS      = 4;
  localparam int unsigned NUM_FIELDS    = 17;
  localparam int unsigned GOLDEN_PORTS  = 106;   // golden 端口总数
  localparam int unsigned PAYLOAD_W     = 140;

  // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
  localparam int unsigned PORT_BITS_SRC = $bits(
    {s2_FGH_src_hist_17_folded_hist, s2_FGH_src_hist_16_folded_hist,
     s2_FGH_src_hist_15_folded_hist, s2_FGH_src_hist_14_folded_hist,
     s2_FGH_src_hist_13_folded_hist, s2_FGH_src_hist_12_folded_hist,
     s2_FGH_src_hist_11_folded_hist, s2_FGH_src_hist_10_folded_hist,
     s2_FGH_src_hist_9_folded_hist, s2_FGH_src_hist_8_folded_hist,
     s2_FGH_src_hist_7_folded_hist, s2_FGH_src_hist_6_folded_hist,
     s2_FGH_src_hist_5_folded_hist, s2_FGH_src_hist_4_folded_hist,
     s2_FGH_src_hist_3_folded_hist, s2_FGH_src_hist_2_folded_hist,
     s2_FGH_src_hist_1_folded_hist, s1_FGH_src_hist_17_folded_hist,
     s1_FGH_src_hist_16_folded_hist, s1_FGH_src_hist_15_folded_hist,
     s1_FGH_src_hist_14_folded_hist, s1_FGH_src_hist_13_folded_hist,
     s1_FGH_src_hist_12_folded_hist, s1_FGH_src_hist_11_folded_hist,
     s1_FGH_src_hist_10_folded_hist, s1_FGH_src_hist_9_folded_hist,
     s1_FGH_src_hist_8_folded_hist, s1_FGH_src_hist_7_folded_hist,
     s1_FGH_src_hist_6_folded_hist, s1_FGH_src_hist_5_folded_hist,
     s1_FGH_src_hist_4_folded_hist, s1_FGH_src_hist_3_folded_hist,
     s1_FGH_src_hist_2_folded_hist, s1_FGH_src_hist_1_folded_hist,
     s3_FGH_src_hist_17_folded_hist, s3_FGH_src_hist_16_folded_hist,
     s3_FGH_src_hist_15_folded_hist, s3_FGH_src_hist_14_folded_hist,
     s3_FGH_src_hist_13_folded_hist, s3_FGH_src_hist_12_folded_hist,
     s3_FGH_src_hist_11_folded_hist, s3_FGH_src_hist_10_folded_hist,
     s3_FGH_src_hist_9_folded_hist, s3_FGH_src_hist_8_folded_hist,
     s3_FGH_src_hist_7_folded_hist, s3_FGH_src_hist_6_folded_hist,
     s3_FGH_src_hist_5_folded_hist, s3_FGH_src_hist_4_folded_hist,
     s3_FGH_src_hist_3_folded_hist, s3_FGH_src_hist_2_folded_hist,
     s3_FGH_src_hist_1_folded_hist, redirect_FGHT_src_hist_17_folded_hist,
     redirect_FGHT_src_hist_16_folded_hist, redirect_FGHT_src_hist_15_folded_hist,
     redirect_FGHT_src_hist_14_folded_hist, redirect_FGHT_src_hist_13_folded_hist,
     redirect_FGHT_src_hist_12_folded_hist, redirect_FGHT_src_hist_11_folded_hist,
     redirect_FGHT_src_hist_10_folded_hist, redirect_FGHT_src_hist_9_folded_hist,
     redirect_FGHT_src_hist_8_folded_hist, redirect_FGHT_src_hist_7_folded_hist,
     redirect_FGHT_src_hist_6_folded_hist, redirect_FGHT_src_hist_5_folded_hist,
     redirect_FGHT_src_hist_4_folded_hist, redirect_FGHT_src_hist_3_folded_hist,
     redirect_FGHT_src_hist_2_folded_hist, redirect_FGHT_src_hist_1_folded_hist});
  localparam int unsigned PORT_BITS_DFLT = $bits(
    {stallFGH_src_hist_17_folded_hist, stallFGH_src_hist_16_folded_hist,
     stallFGH_src_hist_15_folded_hist, stallFGH_src_hist_14_folded_hist,
     stallFGH_src_hist_13_folded_hist, stallFGH_src_hist_12_folded_hist,
     stallFGH_src_hist_11_folded_hist, stallFGH_src_hist_10_folded_hist,
     stallFGH_src_hist_9_folded_hist, stallFGH_src_hist_8_folded_hist,
     stallFGH_src_hist_7_folded_hist, stallFGH_src_hist_6_folded_hist,
     stallFGH_src_hist_5_folded_hist, stallFGH_src_hist_4_folded_hist,
     stallFGH_src_hist_3_folded_hist, stallFGH_src_hist_2_folded_hist,
     stallFGH_src_hist_1_folded_hist});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {out_res_hist_17_folded_hist, out_res_hist_16_folded_hist, out_res_hist_15_folded_hist,
     out_res_hist_14_folded_hist, out_res_hist_13_folded_hist, out_res_hist_12_folded_hist,
     out_res_hist_11_folded_hist, out_res_hist_10_folded_hist, out_res_hist_9_folded_hist,
     out_res_hist_8_folded_hist, out_res_hist_7_folded_hist, out_res_hist_6_folded_hist,
     out_res_hist_5_folded_hist, out_res_hist_4_folded_hist, out_res_hist_3_folded_hist,
     out_res_hist_2_folded_hist, out_res_hist_1_folded_hist});

  logic [PAYLOAD_W-1:0] res;

  xs_PriorityMuxModule_core #(
    .WIDTH         (PAYLOAD_W),
    .NUM_WAYS      (NUM_WAYS),
    .NUM_FIELDS    (NUM_FIELDS),
    .GOLDEN_PORTS  (GOLDEN_PORTS),
    .PORT_BITS_SRC (PORT_BITS_SRC),
    .PORT_BITS_DFLT(PORT_BITS_DFLT),
    .PORT_BITS_OUT (PORT_BITS_OUT)
  ) u_core (
    // sel / src 都按"优先级从高到低"MSB 优先拼接
    .sel(
      {s2_FGH_sel, s1_FGH_sel, s3_FGH_sel, redirect_FGHT_sel}),
    .src(
      {s2_FGH_src_hist_17_folded_hist, s2_FGH_src_hist_16_folded_hist,
       s2_FGH_src_hist_15_folded_hist, s2_FGH_src_hist_14_folded_hist,
       s2_FGH_src_hist_13_folded_hist, s2_FGH_src_hist_12_folded_hist,
       s2_FGH_src_hist_11_folded_hist, s2_FGH_src_hist_10_folded_hist,
       s2_FGH_src_hist_9_folded_hist, s2_FGH_src_hist_8_folded_hist,
       s2_FGH_src_hist_7_folded_hist, s2_FGH_src_hist_6_folded_hist,
       s2_FGH_src_hist_5_folded_hist, s2_FGH_src_hist_4_folded_hist,
       s2_FGH_src_hist_3_folded_hist, s2_FGH_src_hist_2_folded_hist,
       s2_FGH_src_hist_1_folded_hist, s1_FGH_src_hist_17_folded_hist,
       s1_FGH_src_hist_16_folded_hist, s1_FGH_src_hist_15_folded_hist,
       s1_FGH_src_hist_14_folded_hist, s1_FGH_src_hist_13_folded_hist,
       s1_FGH_src_hist_12_folded_hist, s1_FGH_src_hist_11_folded_hist,
       s1_FGH_src_hist_10_folded_hist, s1_FGH_src_hist_9_folded_hist,
       s1_FGH_src_hist_8_folded_hist, s1_FGH_src_hist_7_folded_hist,
       s1_FGH_src_hist_6_folded_hist, s1_FGH_src_hist_5_folded_hist,
       s1_FGH_src_hist_4_folded_hist, s1_FGH_src_hist_3_folded_hist,
       s1_FGH_src_hist_2_folded_hist, s1_FGH_src_hist_1_folded_hist,
       s3_FGH_src_hist_17_folded_hist, s3_FGH_src_hist_16_folded_hist,
       s3_FGH_src_hist_15_folded_hist, s3_FGH_src_hist_14_folded_hist,
       s3_FGH_src_hist_13_folded_hist, s3_FGH_src_hist_12_folded_hist,
       s3_FGH_src_hist_11_folded_hist, s3_FGH_src_hist_10_folded_hist,
       s3_FGH_src_hist_9_folded_hist, s3_FGH_src_hist_8_folded_hist,
       s3_FGH_src_hist_7_folded_hist, s3_FGH_src_hist_6_folded_hist,
       s3_FGH_src_hist_5_folded_hist, s3_FGH_src_hist_4_folded_hist,
       s3_FGH_src_hist_3_folded_hist, s3_FGH_src_hist_2_folded_hist,
       s3_FGH_src_hist_1_folded_hist, redirect_FGHT_src_hist_17_folded_hist,
       redirect_FGHT_src_hist_16_folded_hist, redirect_FGHT_src_hist_15_folded_hist,
       redirect_FGHT_src_hist_14_folded_hist, redirect_FGHT_src_hist_13_folded_hist,
       redirect_FGHT_src_hist_12_folded_hist, redirect_FGHT_src_hist_11_folded_hist,
       redirect_FGHT_src_hist_10_folded_hist, redirect_FGHT_src_hist_9_folded_hist,
       redirect_FGHT_src_hist_8_folded_hist, redirect_FGHT_src_hist_7_folded_hist,
       redirect_FGHT_src_hist_6_folded_hist, redirect_FGHT_src_hist_5_folded_hist,
       redirect_FGHT_src_hist_4_folded_hist, redirect_FGHT_src_hist_3_folded_hist,
       redirect_FGHT_src_hist_2_folded_hist, redirect_FGHT_src_hist_1_folded_hist}),
    .dflt(
      {stallFGH_src_hist_17_folded_hist, stallFGH_src_hist_16_folded_hist,
       stallFGH_src_hist_15_folded_hist, stallFGH_src_hist_14_folded_hist,
       stallFGH_src_hist_13_folded_hist, stallFGH_src_hist_12_folded_hist,
       stallFGH_src_hist_11_folded_hist, stallFGH_src_hist_10_folded_hist,
       stallFGH_src_hist_9_folded_hist, stallFGH_src_hist_8_folded_hist,
       stallFGH_src_hist_7_folded_hist, stallFGH_src_hist_6_folded_hist,
       stallFGH_src_hist_5_folded_hist, stallFGH_src_hist_4_folded_hist,
       stallFGH_src_hist_3_folded_hist, stallFGH_src_hist_2_folded_hist,
       stallFGH_src_hist_1_folded_hist}),
    .res(res)
  );

  assign
    {out_res_hist_17_folded_hist, out_res_hist_16_folded_hist, out_res_hist_15_folded_hist,
     out_res_hist_14_folded_hist, out_res_hist_13_folded_hist, out_res_hist_12_folded_hist,
     out_res_hist_11_folded_hist, out_res_hist_10_folded_hist, out_res_hist_9_folded_hist,
     out_res_hist_8_folded_hist, out_res_hist_7_folded_hist, out_res_hist_6_folded_hist,
     out_res_hist_5_folded_hist, out_res_hist_4_folded_hist, out_res_hist_3_folded_hist,
     out_res_hist_2_folded_hist, out_res_hist_1_folded_hist} = res;

endmodule
