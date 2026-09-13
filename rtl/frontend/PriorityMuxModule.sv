// =============================================================================
// PriorityMuxModule —— 带兜底源的优先级选择器（xs_PriorityMuxModule_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   候选路数 NUM_WAYS = 4（各带一个 sel）+ 1 路兜底源（无 sel）；
//   载荷字段 NUM_FIELDS = 1，打平后 WIDTH = 50 位；
//   端口 10 个 = 4 个 sel + (4 路 + 兜底 + 输出) × 1 个字段；
//   golden 模块体 = 1 条纯组合三元链，无寄存器 / 无时钟 / 无子模块。
//   优先级（高 -> 低）：s2_target_sel > s1_target_sel > s3_target_sel > redirect_target_sel，全不成立则取 stallPC_src*。
//   载荷字段：out_res=50b。
//   用途：Predictor 的 预测目标 PC（target，50 位虚地址）。
//
// 结构：golden 同名端口表 -> 把每一路的全部字段按输出顺序 MSB 优先拼成一根
//   50 位载荷 -> 设参例化 xs_PriorityMuxModule_core（核体见
//   xs_PriorityMuxModule_core.sv，优先级语义与不变式都在那里讲）-> 拆包回输出端口。
//   PORT_BITS_* 与 GOLDEN_PORTS 用 $bits(端口拼接) / 端口数算出来传给核：
//   任何字段位宽、路数、字段数抄错，time 0 直接 $fatal。
// 自动生成：verif/ut/PriorityMuxModule/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module PriorityMuxModule(
  input         s2_target_sel,
  input  [49:0] s2_target_src,
  input         s1_target_sel,
  input  [49:0] s1_target_src,
  input         s3_target_sel,
  input  [49:0] s3_target_src,
  input         redirect_target_sel,
  input  [49:0] redirect_target_src,
  input  [49:0] stallPC_src,
  output [49:0] out_res
);

  localparam int unsigned NUM_WAYS      = 4;
  localparam int unsigned NUM_FIELDS    = 1;
  localparam int unsigned GOLDEN_PORTS  = 10;   // golden 端口总数
  localparam int unsigned PAYLOAD_W     = 50;

  // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
  localparam int unsigned PORT_BITS_SRC = $bits(
    {s2_target_src, s1_target_src, s3_target_src, redirect_target_src});
  localparam int unsigned PORT_BITS_DFLT = $bits(
    {stallPC_src});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {out_res});

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
      {s2_target_sel, s1_target_sel, s3_target_sel, redirect_target_sel}),
    .src(
      {s2_target_src, s1_target_src, s3_target_src, redirect_target_src}),
    .dflt(
      {stallPC_src}),
    .res(res)
  );

  assign
    {out_res} = res;

endmodule
