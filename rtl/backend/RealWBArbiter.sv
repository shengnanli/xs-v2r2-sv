// =============================================================================
// RealWBArbiter.sv —— 写回数据通路的固定优先级仲裁器（本族无状态）
//
// 在哪一层：后端写回（writeback）数据通路，由 RealWBCollideChecker* 例化。
//   上游是若干条写回通道（{xxWen, pdest, data}），本模块把它们合成一路送给
//   寄存器堆写口。**与 WBArbiter 是两个模块，不是同一个的变体**：
//     · 本族没有 clock/reset，一个寄存器都没有（纯组合）；
//     · WBArbiter 带 2N+1 个寄存器的反饥饿计数级；
//     · payload 形状不同（本族 {xxWen, pdest, data}，WBArbiter 是单个 addr 或没有）；
//     · 父模块也是两套（RealWBCollideChecker* vs *RFWBCollideChecker/*RFReadArbiter）。
//   两族**共有的**那半边是优先级法则本身，已抽成 rtl/common/xs_PriorityArbSelect.sv，
//   实测依据（逐字等价的化简）写在该文件头。本族的核体就是那条法则，没有别的东西，
//   所以这里不再套一层空的 xs_RealWBArbiter_core，wrapper 直接例化共享件。
//
// 核心机制：编号最小的 valid 那一路赢；in_ready[i] = 赢 | ~valid[i]（不请求恒就绪）；
//   out_bits 取赢家的 payload，一路都没有时落到最后一路（照抄 golden 的条件链末档）。
//
// ★golden 的不对称照抄★：N=1 的四个变体（_3/_15/_21/_26）**连 io_in_0_ready 端口
//   都没有**（恒 1 被 firtool 折掉），而 N>=2 的变体保留了恒 1 的 io_in_0_ready。
//   薄 wrapper 各自照抄，不许"补齐"。
//
// 家族差异（9 个变体只差 2 个维度）：仲裁宽度 N（1/2/3/4）与 payload 字段表
//   （rfWen/fpWen/vecWen/v0Wen/vlWen × pdest 5..8 位 × data 8/64/128 位）。
//   逐变体矩阵见 verif/ut/RealWBArbiterVariants/README.md；8 个薄 wrapper 由
//   scripts/gen_fubusy_wbarb.py 生成。
//
// 设计源：XiangShan src/main/scala/xiangshan/backend/datapath/WbArbiter.scala
// golden 对照：G1-canonical/golden-rtl/RealWBArbiter.sv
// =============================================================================
package realwbarbiter_pkg;
  // payload 字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  typedef struct packed {
    logic        rfWen;
    logic [7:0]  pdest;
    logic [63:0] data;
  } payload_t;
endpackage

module RealWBArbiter import realwbarbiter_pkg::*; (
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
  output        io_out_valid,
  output        io_out_bits_rfWen,
  output [7:0]  io_out_bits_pdest,
  output [63:0] io_out_bits_data
);
  localparam int N  = 3;
  localparam int PW = $bits(payload_t);

  payload_t [N-1:0] in_payload;
  assign in_payload[0] = {io_in_0_bits_rfWen, io_in_0_bits_pdest, io_in_0_bits_data};
  assign in_payload[1] = {io_in_1_bits_rfWen, io_in_1_bits_pdest, io_in_1_bits_data};
  assign in_payload[2] = {io_in_2_bits_rfWen, io_in_2_bits_pdest, io_in_2_bits_data};

  payload_t     out_payload;
  logic [N-1:0] in_ready;
  logic [N-1:0] in_valid;
  assign in_valid = {io_in_2_valid, io_in_1_valid, io_in_0_valid};

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
  assign io_out_bits_rfWen = out_payload.rfWen;
  assign io_out_bits_pdest = out_payload.pdest;
  assign io_out_bits_data  = out_payload.data;
endmodule
