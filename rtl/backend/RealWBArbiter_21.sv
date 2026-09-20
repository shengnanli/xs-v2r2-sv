// ============================================================================
// RealWBArbiter_21.sv —— RealWBArbiter 家族薄 wrapper：N=1，payload {v0Wen:1, pdest:5, data:128}（共 134 位）
// 例化者：RealWBCollideChecker_3.sv
// ★golden 不对称：N=1 的变体**连 io_in_0_ready 端口都没有**（恒 1 被
//   firtool 折掉），而 N>=2 的变体保留了恒 1 的 io_in_0_ready。照抄。
//
// 本文件只做参数设定与端口对位，核体见 rtl/common/xs_PriorityArbSelect.sv，全家族共一份。
// 由 scripts/gen_fubusy_wbarb.py 生成，勿手改；差异维度矩阵见
// verif/ut/RealWBArbiterVariants/README.md。
// golden 对照：G1-canonical/golden-rtl/RealWBArbiter_21.sv
// ============================================================================
package realwbarbiter_21_pkg;
  // payload 字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  typedef struct packed {
    logic          v0Wen;
    logic [4:0]    pdest;
    logic [127:0]  data;
  } payload_t;
endpackage

module RealWBArbiter_21 import realwbarbiter_21_pkg::*; (
  input          io_in_0_valid,
  input          io_in_0_bits_v0Wen,
  input  [4:0]   io_in_0_bits_pdest,
  input  [127:0] io_in_0_bits_data,
  output         io_out_valid,
  output         io_out_bits_v0Wen,
  output [4:0]   io_out_bits_pdest,
  output [127:0] io_out_bits_data
);
  localparam int N  = 1;
  localparam int PW = $bits(payload_t);

  payload_t [N-1:0] in_payload;
  assign in_payload[0] = {io_in_0_bits_v0Wen, io_in_0_bits_pdest, io_in_0_bits_data};

  payload_t     out_payload;
  logic [N-1:0] in_ready;
  logic [N-1:0] in_valid;
  assign in_valid = {io_in_0_valid};

  xs_PriorityArbSelect #(.N(N), .PW(PW)) u_sel (
    .in_valid  (in_valid),
    .eff_valid (in_valid),    // 本族没有反饥饿级，原始 valid 直接参与竞争
    .in_bits   (in_payload),
    .in_ready  (in_ready),
    .out_valid (io_out_valid),
    .out_bits  (out_payload)
  );

  // golden 本变体没有 io_in_0_ready 端口（恒 1 被折掉）：in_ready 悬空不接。
  assign io_out_bits_v0Wen    = out_payload.v0Wen;
  assign io_out_bits_pdest    = out_payload.pdest;
  assign io_out_bits_data     = out_payload.data;
endmodule
