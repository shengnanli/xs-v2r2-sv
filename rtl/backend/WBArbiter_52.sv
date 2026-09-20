// ============================================================================
// WBArbiter_52.sv —— WBArbiter 家族薄 wrapper：N=2，payload addr[6:0]
// 例化者：VfRFReadArbiter.sv
//
// 本文件只做参数设定与端口对位，核体见 rtl/backend/WBArbiter.sv，全家族共一份。
// 由 scripts/gen_fubusy_wbarb.py 生成，勿手改；差异维度矩阵见
// verif/ut/WBArbiterVariants/README.md。
// golden 对照：G1-canonical/golden-rtl/WBArbiter_52.sv
// ============================================================================
module WBArbiter_52(
  input        clock,
  input        reset,
  output       io_in_0_ready,
  input        io_in_0_valid,
  input  [6:0] io_in_0_bits_addr,
  output       io_in_1_ready,
  input        io_in_1_valid,
  input  [6:0] io_in_1_bits_addr,
  output       io_out_valid,
  output [6:0] io_out_bits_addr
);
  localparam int N  = 2;
  localparam int PW = 7;

  logic [N-1:0] in_ready;
  xs_WBArbiter_core #(.N(N), .PW(PW)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  ({io_in_1_valid, io_in_0_valid}),
    .in_bits   ({io_in_1_bits_addr, io_in_0_bits_addr}),
    .in_ready  (in_ready),
    .out_valid (io_out_valid),
    .out_bits  (io_out_bits_addr)
  );
  assign io_in_0_ready = in_ready[0];
  assign io_in_1_ready = in_ready[1];
endmodule
