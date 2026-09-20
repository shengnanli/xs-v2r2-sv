// =============================================================================
// xs_PriorityArbSelect.sv —— 「编号小者先赢」的固定优先级仲裁法则（共享辅助件）
//
// 在哪一层：它不对应任何一个 golden 模块，而是 golden 里 WBArbiter 与 RealWBArbiter
//   两族**共有的那半边**。Chisel 把这段法则内联进了每一个使用者，firtool 于是在
//   22 个模块里各展平了一份；本仓按 CONVENTIONS「共享辅助件」把它抽成一处讲透。
//
// 两族的关系是**实测**出来的，不是名字像（golden 实测见下）：
//   · RealWBArbiter 的 in_ready / out_valid / out_bits 三条式子，逐字等于
//     WBArbiter 在 isFull≡0、hasFull≡0 时的化简结果。例如 N=3 时
//       golden WBArbiter    : io_in_2_ready = ~(fv0|fv1) & fv2 | ~v2
//       golden RealWBArbiter: io_in_2_ready = ~(v0|v1) | ~v2
//     把 fv 代回 v 两者恒等（A&v | ~v == A | ~v）。
//   · 但两族**不是同一个模块**：WBArbiter 带时钟与 2N+1 个寄存器的反饥饿级，
//     RealWBArbiter 连 clock/reset 端口都没有；payload 形状也完全不同
//     （addr 单字段 vs {xxWen, pdest, data}）；连父模块都是两套
//     （*RFWBCollideChecker / *RFReadArbiter vs RealWBCollideChecker）。
//   所以是「共享法则 + 各自的核」，不是「合成一个核」。
//
// 核心机制（三条，与 Chisel 的 Arbiter 逐句对应）：
//   1. win[i] = 「编号比 i 小的都没请求」& eff_valid[i]     —— 优先级链
//   2. in_ready[i] = win[i] | ~in_valid[i]                  —— 不请求的那一路恒就绪
//   3. out_bits = 编号最小的 eff_valid 那一路；一路都没有时落到 in_bits[N-1]
//      （golden 的条件表达式链最后一档就是无条件的 in_bits[N-1]，照抄）
//
// eff_valid 与 in_valid 分开传：WBArbiter 的 eff_valid 是经过反饥饿级筛选的
//   finalValid，而 in_ready 的「不请求即就绪」那一项看的仍是原始 valid。
//   RealWBArbiter 两者接同一根线。
// =============================================================================
module xs_PriorityArbSelect #(
  parameter int N  = 2,   // 仲裁宽度
  parameter int PW = 1    // payload 打平位宽（golden 无 payload 的变体传 1 并悬空 out_bits）
) (
  input  logic [N-1:0]         in_valid,   // 原始请求
  input  logic [N-1:0]         eff_valid,  // 真正参与竞争的请求（见文件头）
  input  logic [N-1:0][PW-1:0] in_bits,
  output logic [N-1:0]         in_ready,
  output logic                 out_valid,
  output logic [PW-1:0]        out_bits
);
  // ---- 1. 优先级链：从 0 号往上扫，第一个 eff_valid 的那一路赢 -----------------
  logic [N-1:0] win;
  always_comb begin
    logic none_higher;          // 「编号比当前更小的都没请求」
    none_higher = 1'b1;
    for (int i = 0; i < N; i++) begin
      win[i]      = none_higher & eff_valid[i];
      none_higher = none_higher & ~eff_valid[i];
    end
  end

  // ---- 2. 授权 --------------------------------------------------------------
  assign in_ready  = win | ~in_valid;
  assign out_valid = |eff_valid;

  // ---- 3. payload 选择 ------------------------------------------------------
  // 倒着扫、命中就覆写，最后留下的是编号最小的那一路；全不命中时保留初值 in_bits[N-1]。
  always_comb begin
    out_bits = in_bits[N-1];
    for (int i = N - 1; i >= 0; i--)
      if (eff_valid[i]) out_bits = in_bits[i];
  end
endmodule
