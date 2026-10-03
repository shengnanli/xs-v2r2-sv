// =============================================================================
// FastArbiter.sv —— FastArbiter 家族薄 wrapper：L2 4 个 slice 的预取训练请求（PrefetchTrain）汇入 Prefetcher 的仲裁
//
// 本变体规模：N=4 路，载荷打平 W=99 位（6 个字段，无常量字段）。
//   例化者：TL2CHICoupledL2.sv（实例 prefetch_train_arb）。
//
// 本文件只做"字段打包 → 核 → 拆包"的端口对位；仲裁逻辑（轮转 + 挂起记忆）
// 在 rtl/common/xs_FastArbiter_core.sv，全家族共一份。
// 本文件由 scripts/gen_fastarbiter_l2c.py 生成，勿手改。
// golden 对照：G1-canonical/golden-rtl/FastArbiter.sv
// =============================================================================
package fastarbiter_pkg;
  // 载荷字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  typedef struct packed {
    logic [32:0] tag;
    logic [8:0]  set;
    logic        needT;
    logic [6:0]  source;
    logic [43:0] vaddr;
    logic [4:0]  reqsource;
  } payload_t;
endpackage

module FastArbiter import fastarbiter_pkg::*; (
  input         clock,
  input         reset,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [32:0] io_in_0_bits_tag,
  input  [8:0]  io_in_0_bits_set,
  input         io_in_0_bits_needT,
  input  [6:0]  io_in_0_bits_source,
  input  [43:0] io_in_0_bits_vaddr,
  input  [4:0]  io_in_0_bits_reqsource,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [32:0] io_in_1_bits_tag,
  input  [8:0]  io_in_1_bits_set,
  input         io_in_1_bits_needT,
  input  [6:0]  io_in_1_bits_source,
  input  [43:0] io_in_1_bits_vaddr,
  input  [4:0]  io_in_1_bits_reqsource,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [32:0] io_in_2_bits_tag,
  input  [8:0]  io_in_2_bits_set,
  input         io_in_2_bits_needT,
  input  [6:0]  io_in_2_bits_source,
  input  [43:0] io_in_2_bits_vaddr,
  input  [4:0]  io_in_2_bits_reqsource,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [32:0] io_in_3_bits_tag,
  input  [8:0]  io_in_3_bits_set,
  input         io_in_3_bits_needT,
  input  [6:0]  io_in_3_bits_source,
  input  [43:0] io_in_3_bits_vaddr,
  input  [4:0]  io_in_3_bits_reqsource,
  input         io_out_ready,
  output        io_out_valid,
  output [32:0] io_out_bits_tag,
  output [8:0]  io_out_bits_set,
  output        io_out_bits_needT,
  output [6:0]  io_out_bits_source,
  output [43:0] io_out_bits_vaddr,
  output [4:0]  io_out_bits_reqsource
);
  localparam int N = 4;
  localparam int W = $bits(payload_t);

  // ---- 打包：第 i 路的全部字段按字段表拼成一个 payload_t
  payload_t [N-1:0] in_payload;
  assign in_payload[0] = '{
    tag: io_in_0_bits_tag,
    set: io_in_0_bits_set,
    needT: io_in_0_bits_needT,
    source: io_in_0_bits_source,
    vaddr: io_in_0_bits_vaddr,
    reqsource: io_in_0_bits_reqsource
  };
  assign in_payload[1] = '{
    tag: io_in_1_bits_tag,
    set: io_in_1_bits_set,
    needT: io_in_1_bits_needT,
    source: io_in_1_bits_source,
    vaddr: io_in_1_bits_vaddr,
    reqsource: io_in_1_bits_reqsource
  };
  assign in_payload[2] = '{
    tag: io_in_2_bits_tag,
    set: io_in_2_bits_set,
    needT: io_in_2_bits_needT,
    source: io_in_2_bits_source,
    vaddr: io_in_2_bits_vaddr,
    reqsource: io_in_2_bits_reqsource
  };
  assign in_payload[3] = '{
    tag: io_in_3_bits_tag,
    set: io_in_3_bits_set,
    needT: io_in_3_bits_needT,
    source: io_in_3_bits_source,
    vaddr: io_in_3_bits_vaddr,
    reqsource: io_in_3_bits_reqsource
  };

  // ---- 核例化：仲裁逻辑全在 xs_FastArbiter_core
  payload_t out_payload;
  xs_FastArbiter_core #(.N(N), .W(W)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  ({io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid}),
    .in_bits   (in_payload),
    .in_ready  ({io_in_3_ready, io_in_2_ready, io_in_1_ready, io_in_0_ready}),
    .out_ready (io_out_ready),
    .out_valid (io_out_valid),
    .out_bits  (out_payload)
  );

  // ---- 拆包：与打包共用同一张字段表
  assign io_out_bits_tag = out_payload.tag;
  assign io_out_bits_set = out_payload.set;
  assign io_out_bits_needT = out_payload.needT;
  assign io_out_bits_source = out_payload.source;
  assign io_out_bits_vaddr = out_payload.vaddr;
  assign io_out_bits_reqsource = out_payload.reqsource;
endmodule
