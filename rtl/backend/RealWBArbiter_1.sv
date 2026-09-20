// ============================================================================
// RealWBArbiter_1.sv —— RealWBArbiter 家族薄 wrapper：N=4，payload {rfWen:1, pdest:8, data:64}（共 73 位）
// 例化者：RealWBCollideChecker.sv
//
// 本文件只做参数设定与端口对位，核体见 rtl/common/xs_PriorityArbSelect.sv，全家族共一份。
// 由 scripts/gen_fubusy_wbarb.py 生成，勿手改；差异维度矩阵见
// verif/ut/RealWBArbiterVariants/README.md。
// golden 对照：G1-canonical/golden-rtl/RealWBArbiter_1.sv
// ============================================================================
package realwbarbiter_1_pkg;
  // payload 字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  typedef struct packed {
    logic          rfWen;
    logic [7:0]    pdest;
    logic [63:0]   data;
  } payload_t;
endpackage

module RealWBArbiter_1 import realwbarbiter_1_pkg::*; (
  output        io_in_0_ready,
  input         io_in_0_valid,
  input         io_in_0_bits_rfWen,
  input  [7:0]  io_in_0_bits_pdest,
  input  [63:0] io_in_0_bits_data,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input         io_in_1_bits_rfWen,
  input  [7:0]  io_in_1_bits_pdest,
  input  [63:0] io_in_1_bits_data,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input         io_in_2_bits_rfWen,
  input  [7:0]  io_in_2_bits_pdest,
  input  [63:0] io_in_2_bits_data,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input         io_in_3_bits_rfWen,
  input  [7:0]  io_in_3_bits_pdest,
  input  [63:0] io_in_3_bits_data,
  output        io_out_valid,
  output        io_out_bits_rfWen,
  output [7:0]  io_out_bits_pdest,
  output [63:0] io_out_bits_data
);
  localparam int N  = 4;
  localparam int PW = $bits(payload_t);

  payload_t [N-1:0] in_payload;
  assign in_payload[0] = {io_in_0_bits_rfWen, io_in_0_bits_pdest, io_in_0_bits_data};
  assign in_payload[1] = {io_in_1_bits_rfWen, io_in_1_bits_pdest, io_in_1_bits_data};
  assign in_payload[2] = {io_in_2_bits_rfWen, io_in_2_bits_pdest, io_in_2_bits_data};
  assign in_payload[3] = {io_in_3_bits_rfWen, io_in_3_bits_pdest, io_in_3_bits_data};

  payload_t     out_payload;
  logic [N-1:0] in_ready;
  logic [N-1:0] in_valid;
  assign in_valid = {io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};

  xs_PriorityArbSelect #(.N(N), .PW(PW)) u_sel (
    .in_valid  (in_valid),
    .eff_valid (in_valid),    // 本族没有反饥饿级，原始 valid 直接参与竞争
    .in_bits   (in_payload),
    .in_ready  (in_ready),
    .out_valid (io_out_valid),
    .out_bits  (out_payload)
  );

  assign io_in_0_ready     = in_ready[0];
  assign io_in_1_ready     = in_ready[1];
  assign io_in_2_ready     = in_ready[2];
  assign io_in_3_ready     = in_ready[3];
  assign io_out_bits_rfWen    = out_payload.rfWen;
  assign io_out_bits_pdest    = out_payload.pdest;
  assign io_out_bits_data     = out_payload.data;
endmodule
