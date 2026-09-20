// ============================================================================
// WBArbiter_3.sv —— WBArbiter 家族薄 wrapper：N=1，无 payload
// 例化者：FpRFWBCollideChecker.sv / IntRFWBCollideChecker.sv / V0RFWBCollideChecker.sv / VfRFWBCollideChecker.sv / VlRFWBCollideChecker.sv
// ★golden 实测：N=1 时 finalValid_0 恒等于 io_in_0_valid（~hasFull 与
//   ~(v&isFull) 两项里必有一项为真），因此 in_ready 恒 1、计数器恒 0 ——
//   本变体那 3 个反饥饿寄存器是**死逻辑**。golden 有它们，这里照样有。
//
// 本文件只做参数设定与端口对位，核体见 rtl/backend/WBArbiter.sv，全家族共一份。
// 由 scripts/gen_fubusy_wbarb.py 生成，勿手改；差异维度矩阵见
// verif/ut/WBArbiterVariants/README.md。
// golden 对照：G1-canonical/golden-rtl/WBArbiter_3.sv
// ============================================================================
module WBArbiter_3(
  input  clock,
  input  reset,
  output io_in_0_ready,
  input  io_in_0_valid,
  output io_out_valid
);
  localparam int N  = 1;
  localparam int PW = 1;   // 无 payload：传 1 位并悬空 out_bits

  logic [N-1:0] in_ready;
  xs_WBArbiter_core #(.N(N), .PW(PW)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  ({io_in_0_valid}),
    .in_bits   ('0),            // golden 本变体无 bits 端口
    .in_ready  (in_ready),
    .out_valid (io_out_valid),
    .out_bits  ()
  );
  assign io_in_0_ready = in_ready[0];
endmodule
