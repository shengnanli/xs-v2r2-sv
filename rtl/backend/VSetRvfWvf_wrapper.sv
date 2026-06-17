// =============================================================================
// VSetRvfWvf (wrapper) —— golden 同名顶层,端口与 golden/chisel-rtl/VSetRvfWvf.sv 一致。
// -----------------------------------------------------------------------------
// 作用:把可读核 xs_VSetRvfWvf_core 适配成 golden 扁平端口。除 vl 写回外,本单元
//       还写 vtype 寄存器(io_vtype_*)并产出 vlIsZero/vlIsVlmax 标志。控制位
//       (含 vlWen)按 VSetBase 的 out := in 直通。
// =============================================================================
module VSetRvfWvf (
  input          io_in_valid,
  input  [8:0]   io_in_bits_ctrl_fuOpType,
  input          io_in_bits_ctrl_robIdx_flag,
  input  [7:0]   io_in_bits_ctrl_robIdx_value,
  input  [7:0]   io_in_bits_ctrl_pdest,
  input          io_in_bits_ctrl_rfWen,
  input          io_in_bits_ctrl_vlWen,
  input  [7:0]   io_in_bits_data_src_4,
  input  [127:0] io_in_bits_data_src_1,
  input  [63:0]  io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_in_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_in_bits_perfDebugInfo_issueTime,
  output         io_out_valid,
  output         io_out_bits_ctrl_robIdx_flag,
  output [7:0]   io_out_bits_ctrl_robIdx_value,
  output [7:0]   io_out_bits_ctrl_pdest,
  output         io_out_bits_ctrl_rfWen,
  output         io_out_bits_ctrl_vlWen,
  output [63:0]  io_out_bits_res_data,
  output [63:0]  io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_out_bits_perfDebugInfo_selectTime,
  output [63:0]  io_out_bits_perfDebugInfo_issueTime,
  output         io_vtype_valid,
  output         io_vtype_bits_illegal,
  output         io_vtype_bits_vma,
  output         io_vtype_bits_vta,
  output [1:0]   io_vtype_bits_vsew,
  output [2:0]   io_vtype_bits_vlmul,
  output         io_vlIsZero,
  output         io_vlIsVlmax
);

  import vset_pkg::vtype_out_t;
  vtype_out_t vtype_out;

  xs_VSetRvfWvf_core u_core (
    .valid       (io_in_valid),
    .func        (io_in_bits_ctrl_fuOpType),
    .src4        (io_in_bits_data_src_4),
    .src1        (io_in_bits_data_src_1),
    .res_data    (io_out_bits_res_data),
    .vtype_valid (io_vtype_valid),
    .vtype_out   (vtype_out),
    .vl_is_zero  (io_vlIsZero),
    .vl_is_vlmax (io_vlIsVlmax)
  );

  // vtype 结构拆成 golden 扁平字段。
  assign io_vtype_bits_illegal = vtype_out.illegal;
  assign io_vtype_bits_vma     = vtype_out.vma;
  assign io_vtype_bits_vta     = vtype_out.vta;
  assign io_vtype_bits_vsew    = vtype_out.vsew;
  assign io_vtype_bits_vlmul   = vtype_out.vlmul;

  // 控制/调试旁路直通(VSetBase: out := in)。
  assign io_out_valid                         = io_in_valid;
  assign io_out_bits_ctrl_robIdx_flag         = io_in_bits_ctrl_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value        = io_in_bits_ctrl_robIdx_value;
  assign io_out_bits_ctrl_pdest               = io_in_bits_ctrl_pdest;
  assign io_out_bits_ctrl_rfWen               = io_in_bits_ctrl_rfWen;
  assign io_out_bits_ctrl_vlWen               = io_in_bits_ctrl_vlWen;
  assign io_out_bits_perfDebugInfo_enqRsTime  = io_in_bits_perfDebugInfo_enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime = io_in_bits_perfDebugInfo_selectTime;
  assign io_out_bits_perfDebugInfo_issueTime  = io_in_bits_perfDebugInfo_issueTime;

endmodule
