// =============================================================================
// VsetModule —— 向量配置计算核：由 (avl, vtype, func) 算出 vl / vtype / vlmax（纯组合）
//
// 设计源：src/main/scala/xiangshan/backend/fu/Vsetu.scala（class VsetModule）。
// 被 VTypeGen（译码级，只用 vtype 一半）以及 VSetRiWi / VSetRvfWvf（执行单元）用到；
// 那三个重写件把同一组计算以 backend_common_pkg.sv 里 vset_pkg 的纯函数内联，
// 本文件是 golden 独立模块 VsetModule 的重写，同样复用这组函数（同一份实现）。
//
// 计算（VLEN=128、ELEN=64）：
//   log2Vsew = vsew[1:0] + 3；VLMAX = 1 << (7 + vlmul - log2Vsew)（3 位回绕移位量）；
//   非法 = vlmul==100 | vsew[2] | log2Vsew > (vlmul[2] ? vlmul-2 : 6) | reserved≠0 | vtype.illegal；
//   非法 ⇒ vtype 清零、vill=1、vl=0；
//   vl = (非 vsetivli 且 setVlmax 位) 或 avl > VLMAX ? VLMAX : avl；
//   io_out_vlmax = max(VLMAX, VLEN/SEW)（分数 LMUL 时 VLMAX 可能小于一个寄存器的元素数）。
// 怪癖（照 golden）：vlmax 输出不看 illegal；vl / vlmax 都截成 8 位。
// =============================================================================
module xs_VsetModule_core
  import vset_pkg::*;
(
  input  logic [63:0]  avl,
  input  vtype_in_t    vtype_in,
  input  logic [8:0]   func,
  output vtype_out_t   vtype_out,
  output logic [7:0]   vl,
  output logic [7:0]   vlmax_out
);

  logic [2:0]         log2_sew;
  logic [VLMAX_W-1:0] vlmax;
  logic [VLMAX_W-1:0] vlen_div_sew;
  logic               illegal;

  assign log2_sew     = calc_log2_sew(vtype_in.vsew);
  assign vlmax        = calc_vlmax(vtype_in.vlmul, log2_sew);
  assign vlen_div_sew = calc_vlen_div_sew(log2_sew);
  assign illegal      = calc_illegal(vtype_in.vlmul, vtype_in.vsew, log2_sew,
                                     vtype_in.reserved, vtype_in.illegal);

  // 非法：vill=1，其余字段清零；合法：透传（vsew 收窄成 2 位）
  assign vtype_out.illegal = illegal;
  assign vtype_out.vma     = ~illegal & vtype_in.vma;
  assign vtype_out.vta     = ~illegal & vtype_in.vta;
  assign vtype_out.vsew    = illegal ? 2'd0 : vtype_in.vsew[1:0];
  assign vtype_out.vlmul   = illegal ? 3'd0 : vtype_in.vlmul;

  assign vl        = calc_vl(illegal, func, avl, vlmax);
  assign vlmax_out = (vlmax >= vlen_div_sew) ? vlmax[7:0] : vlen_div_sew[7:0];

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden VsetModule.sv 逐位一致
// ---------------------------------------------------------------------------
module VsetModule
  import vset_pkg::*;
(
  input  [63:0] io_in_avl,
  input         io_in_vtype_illegal,
  input  [54:0] io_in_vtype_reserved,
  input         io_in_vtype_vma,
  input         io_in_vtype_vta,
  input  [2:0]  io_in_vtype_vsew,
  input  [2:0]  io_in_vtype_vlmul,
  input  [8:0]  io_in_func,
  output        io_out_vconfig_vtype_illegal,
  output        io_out_vconfig_vtype_vma,
  output        io_out_vconfig_vtype_vta,
  output [1:0]  io_out_vconfig_vtype_vsew,
  output [2:0]  io_out_vconfig_vtype_vlmul,
  output [7:0]  io_out_vconfig_vl,
  output [7:0]  io_out_vlmax
);

  vtype_in_t  vtype_in;
  vtype_out_t vtype_out;

  assign vtype_in.illegal  = io_in_vtype_illegal;
  assign vtype_in.reserved = io_in_vtype_reserved;
  assign vtype_in.vma      = io_in_vtype_vma;
  assign vtype_in.vta      = io_in_vtype_vta;
  assign vtype_in.vsew     = io_in_vtype_vsew;
  assign vtype_in.vlmul    = io_in_vtype_vlmul;

  xs_VsetModule_core u_core (
    .avl       (io_in_avl),
    .vtype_in  (vtype_in),
    .func      (io_in_func),
    .vtype_out (vtype_out),
    .vl        (io_out_vconfig_vl),
    .vlmax_out (io_out_vlmax)
  );

  assign io_out_vconfig_vtype_illegal = vtype_out.illegal;
  assign io_out_vconfig_vtype_vma     = vtype_out.vma;
  assign io_out_vconfig_vtype_vta     = vtype_out.vta;
  assign io_out_vconfig_vtype_vsew    = vtype_out.vsew;
  assign io_out_vconfig_vtype_vlmul   = vtype_out.vlmul;

endmodule
