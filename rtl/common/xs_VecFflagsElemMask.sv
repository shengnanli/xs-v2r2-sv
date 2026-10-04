// =============================================================================
// xs_VecFflagsElemMask —— 向量浮点 FU：本 uop 里哪些元素的 fflags 要计入（8 位元素使能）
//
// 在哪一层：向量浮点 FU 外壳（VFDivSqrt / VFMA / VFAlu）的写回级共享辅助件（Scala 写在公共基类
//   VecFuncUnit 的 fflags 合并里，被 firtool 内联进每个外壳；这里一处实现、讲透）。
// 背景：外壳里两个 64 位运算核各报 4 组 5 位 fflags（f16 时 4 个元素各一组；f32 时用组 0/1；f64 只用组 0），
//   拼成 8 组。RVV 要求只有「活跃」元素（vl 以内、掩码为 1）的异常标志才累计进 fflags。
// 机制（逐项照 Scala / golden，含截断宽度）：
//   1. vlMax       = 16 >> eew                    —— 一个 128 位寄存器装几个 eew 元素（5 位）；
//   2. vlMaxThisUop = vlmul 为分数档（vlmul_frac）时再按 vlmul_fix 收窄：vlMax >> (vlmul_fix[2] ? -vlmul_fix[1:0] : vlmul_fix[1:0])；
//   3. 本 uop 剩余 vl：vlSetThisUop = vl > uop_idx*vlMaxThisUop ? vl - uop_idx*vlMaxThisUop : 0（乘积截 8 位）；
//   4. vl 窗口：vlMaskRShift = 8'hFF >> (8 - min(vlSetThisUop, vlMaxThisUop)[3:0])（4 位截断）——低若干位为 1；
//   5. 掩码窗口：mask >> (uop_idx * vlMax)（注意这里用 vlMax 而不是 vlMaxThisUop，乘积截 8 位）取低 8 位；
//   6. 两个窗口都按 eew 摊到 8 组上：e16 → 8 组一一对应；e32 → 元素 0/1 放组 0/1、元素 2/3 放组 4/5；
//      e64 → 元素 0 放组 0、元素 1 放组 4；e8 → 全 0；elem_en = 两者之与。
// 纯组合、无状态、无子模块。
// =============================================================================
module xs_VecFflagsElemMask (
  input  logic [1:0]   eew,          // 结果元素宽度（加宽指令已 +1）：1=e16 2=e32 3=e64
  input  logic         vlmul_frac,   // vtype.vlmul[2]（分数 LMUL）
  input  logic [2:0]   vlmul_fix,    // 用来收窄 vlMax 的 vlmul（加宽指令已 +1）
  input  logic [2:0]   uop_idx,      // vuopIdx[2:0]
  input  logic [7:0]   vl,
  input  logic [127:0] mask,         // 已按 vm 选好的掩码（vm=1 时全 1）
  output logic [7:0]   elem_en       // 第 k 组 fflags 是否计入
);
  logic [4:0] vl_max, vl_max_this_uop;
  logic [1:0] frac_shift;
  assign vl_max          = 5'h10 >> eew;
  assign frac_shift      = vlmul_fix[2] ? 2'(~vlmul_fix[1:0] + 2'd1) : vlmul_fix[1:0];
  assign vl_max_this_uop = vlmul_frac ? (vl_max >> frac_shift) : vl_max;

  logic [7:0] uop_base, vl_set_this_uop, vl_window;
  logic [3:0] vl_cnt;
  assign uop_base        = 8'(uop_idx * vl_max_this_uop);
  assign vl_set_this_uop = (vl > uop_base) ? 8'(vl - uop_base) : 8'h0;
  assign vl_cnt          = (vl_set_this_uop < {3'h0, vl_max_this_uop}) ? vl_set_this_uop[3:0] : vl_max_this_uop[3:0];
  assign vl_window       = 8'hFF >> 4'(4'd8 - vl_cnt);

  logic [127:0] mask_shifted;
  assign mask_shifted = mask >> 8'(uop_idx * vl_max);

  // 把「第 k 个 eew 元素」摊到 8 组 fflags 上
  function automatic logic [7:0] spread(input logic [7:0] x, input logic [1:0] w);
    case (w)
      2'd1:    return x;
      2'd2:    return {2'b00, x[3:2], 2'b00, x[1:0]};
      2'd3:    return {3'b000, x[1], 3'b000, x[0]};
      default: return 8'h00;
    endcase
  endfunction

  assign elem_en = spread(mask_shifted[7:0], eew) & spread(vl_window, eew);
endmodule
