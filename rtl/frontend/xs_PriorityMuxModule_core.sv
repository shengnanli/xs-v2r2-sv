// =============================================================================
// xs_PriorityMuxModule_core —— 带兜底源的优先级选择器（PriorityMuxModule 家族的核）
//
// 位置：香山分支预测器 Predictor 的"多级覆盖"骨架。预测流水的 s1/s2/s3 三级、
//       以及后端 redirect，都可能对同一份预测状态（目标 PC、全局历史 GH/FGH/AFHOB、
//       分支序号 BrNumOH、GHPtr 等）提出改写；哪一级有效就用哪一级，谁都没有
//       就保持"停顿值"（stallXxx，即上一拍的自留值）。golden 里 Predictor 对每一
//       类状态各单态化出一个 PriorityMuxModule_<n>，形状完全一样，只差载荷字段。
//
// 语义：res = 优先级最高的那一路有效源，全都无效则取兜底源 dflt。
//       sel 与 src 的**高位 = 优先级高**——薄文件按 golden 的书写顺序
//       {最高优先, …, 最低优先} 从左到右拼接，MSB-first 拼接天然给出这个顺序。
//       本核纯组合、无状态、无时钟。
//
// 为什么整个家族只需要这一个核：golden 里每个输出字段都是同一条右结合三元链
//       out_f = selA ? srcA_f : selB ? srcB_f : … : dflt_f，各字段共用同一组 sel。
//       于是"若干路 × 若干字段"可以压成"若干路 × 一根扁平载荷"。
//
// elaborate 期不变式（见下面 initial）：五条等式把参数钉死在 golden 的端口事实上，
//       任何一个字段位宽 / 路数 / 字段数抄错，time 0 就 $fatal，不必指望随机激励。
// =============================================================================
module xs_PriorityMuxModule_core #(
  parameter int unsigned WIDTH      = 1,   // 载荷位宽（全部字段打平后的总位数）
  parameter int unsigned NUM_WAYS   = 4,   // 带 sel 的候选路数（不含兜底源）
  parameter int unsigned NUM_FIELDS = 1,   // 载荷字段数（仅用于端口数等式自检）
  // ---- 下面四个由薄文件从 golden 端口表算出来，只用于自检 ----
  parameter int unsigned GOLDEN_PORTS   = NUM_WAYS + (NUM_WAYS + 2) * NUM_FIELDS,
  parameter int unsigned PORT_BITS_SRC  = WIDTH * NUM_WAYS,  // = $bits({各路全部源端口})
  parameter int unsigned PORT_BITS_DFLT = WIDTH,             // = $bits({兜底源端口})
  parameter int unsigned PORT_BITS_OUT  = WIDTH              // = $bits({全部输出端口})
)(
  input  logic [NUM_WAYS-1:0]         sel,   // sel[NUM_WAYS-1] 优先级最高
  input  logic [NUM_WAYS*WIDTH-1:0]   src,   // 与 sel 同序：高位段配高位 sel
  input  logic [WIDTH-1:0]            dflt,  // 全不选中时的兜底源
  output logic [WIDTH-1:0]            res
);

  initial begin
    if (NUM_WAYS == 0 || WIDTH == 0)
      $fatal(1, "xs_PriorityMuxModule_core: NUM_WAYS=%0d WIDTH=%0d 不合法", NUM_WAYS, WIDTH);
    if (PORT_BITS_SRC != WIDTH * NUM_WAYS)
      $fatal(1, "xs_PriorityMuxModule_core: golden 各路源端口共 %0d 位 != WIDTH(%0d)*NUM_WAYS(%0d)=%0d（位宽或路数抄错）",
             PORT_BITS_SRC, WIDTH, NUM_WAYS, WIDTH * NUM_WAYS);
    if (PORT_BITS_DFLT != WIDTH)
      $fatal(1, "xs_PriorityMuxModule_core: golden 兜底源端口共 %0d 位 != WIDTH=%0d（位宽抄错）",
             PORT_BITS_DFLT, WIDTH);
    if (PORT_BITS_OUT != WIDTH)
      $fatal(1, "xs_PriorityMuxModule_core: golden 输出端口共 %0d 位 != WIDTH=%0d（位宽抄错）",
             PORT_BITS_OUT, WIDTH);
    // golden 端口数恒等式：NUM_WAYS 个 sel + (NUM_WAYS 路 + 兜底 + 输出) × 字段数
    if (GOLDEN_PORTS != NUM_WAYS + (NUM_WAYS + 2) * NUM_FIELDS)
      $fatal(1, "xs_PriorityMuxModule_core: golden 端口数 %0d != %0d + (%0d+2)*%0d（路数或字段数抄错）",
             GOLDEN_PORTS, NUM_WAYS, NUM_WAYS, NUM_FIELDS);
  end

  // 优先级链：从最低位（优先级最低）扫到最高位，后写覆盖先写，
  // 于是最高位那一路（golden 三元链最外层的 sel）胜出；都不成立就留兜底源。
  always_comb begin
    res = dflt;
    for (int unsigned w = 0; w < NUM_WAYS; w++)
      if (sel[w])
        res = src[w * WIDTH +: WIDTH];
  end

endmodule
