// =============================================================================
// FastArbiter_1.sv —— FastArbiter 家族薄 wrapper：L2 4 个 slice 的预取响应（PrefetchResp，只剩 pfSource 字段）汇入 Prefetcher 的仲裁
//
// 本变体规模：N=4 路，载荷打平 W=5 位（1 个字段，无常量字段）。
//   例化者：TL2CHICoupledL2.sv（实例 prefetch_resp_arb）。
//
// 本文件只做"字段打包 → 核 → 拆包"的端口对位；仲裁逻辑（轮转 + 挂起记忆）
// 在 rtl/common/xs_FastArbiter_core.sv，全家族共一份。
// 本文件由 scripts/gen_fastarbiter_l2c.py 生成，勿手改。
// golden 对照：G1-canonical/golden-rtl/FastArbiter_1.sv
// =============================================================================
package fastarbiter_1_pkg;
  // 载荷字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  typedef struct packed {
    logic [4:0] pfSource;
  } payload_t;
endpackage

module FastArbiter_1 import fastarbiter_1_pkg::*; (
  input        clock,
  input        reset,
  output       io_in_0_ready,
  input        io_in_0_valid,
  input  [4:0] io_in_0_bits_pfSource,
  output       io_in_1_ready,
  input        io_in_1_valid,
  input  [4:0] io_in_1_bits_pfSource,
  output       io_in_2_ready,
  input        io_in_2_valid,
  input  [4:0] io_in_2_bits_pfSource,
  output       io_in_3_ready,
  input        io_in_3_valid,
  input  [4:0] io_in_3_bits_pfSource,
  input        io_out_ready,
  output       io_out_valid,
  output [4:0] io_out_bits_pfSource
);
  localparam int N = 4;
  localparam int W = $bits(payload_t);

  // ---- 打包：第 i 路的全部字段按字段表拼成一个 payload_t
  payload_t [N-1:0] in_payload;
  assign in_payload[0] = '{
    pfSource: io_in_0_bits_pfSource
  };
  assign in_payload[1] = '{
    pfSource: io_in_1_bits_pfSource
  };
  assign in_payload[2] = '{
    pfSource: io_in_2_bits_pfSource
  };
  assign in_payload[3] = '{
    pfSource: io_in_3_bits_pfSource
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
  assign io_out_bits_pfSource = out_payload.pfSource;
endmodule
