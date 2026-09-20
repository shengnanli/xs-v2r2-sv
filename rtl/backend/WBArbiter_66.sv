// ============================================================================
// WBArbiter_66.sv —— WBArbiter 家族薄 wrapper：N=1，payload addr[4:0]
// 例化者：V0RFReadArbiter.sv / VlRFReadArbiter.sv
// ★golden 实测：N=1 时 finalValid_0 恒等于 io_in_0_valid（~hasFull 与
//   ~(v&isFull) 两项里必有一项为真），因此 in_ready 恒 1、计数器恒 0 ——
//   本变体那 3 个反饥饿寄存器是**死逻辑**。golden 有它们，这里照样有。
//
// 本文件只做参数设定与端口对位，核体见 rtl/backend/WBArbiter.sv，全家族共一份。
// 由 scripts/gen_fubusy_wbarb.py 生成，勿手改；差异维度矩阵见
// verif/ut/WBArbiterVariants/README.md。
// golden 对照：G1-canonical/golden-rtl/WBArbiter_66.sv
// ============================================================================
module WBArbiter_66(
  input        clock,
  input        reset,
  output       io_in_0_ready,
  input        io_in_0_valid,
  input  [4:0] io_in_0_bits_addr,
  output       io_out_valid,
  output [4:0] io_out_bits_addr
);
  localparam int N  = 1;
  localparam int PW = 5;

  logic [N-1:0] in_ready;
  xs_WBArbiter_core #(.N(N), .PW(PW)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  ({io_in_0_valid}),
    .in_bits   ({io_in_0_bits_addr}),
    .in_ready  (in_ready),
    .out_valid (io_out_valid),
    .out_bits  (io_out_bits_addr)
  );
  assign io_in_0_ready = in_ready[0];
endmodule
