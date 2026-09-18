// =============================================================================
// SnapshotGenerator_7 —— SnapshotGenerator 家族变体（长度为 1 的向量，元素是 8 位无符号数）
// 本文件只做参数化与端口展平；核体见 rtl/backend/SnapshotGenerator.sv
//   （xs_SnapshotGenerator_core，含家族 11 个变体的实测差异表与机制说明）。
// golden 对照：G1-canonical/golden-rtl/SnapshotGenerator_7.sv（14 端口，实测控制逻辑与
//   base 变体逐字节相同，只有 payload 位宽不同）。
// payload 实测 8 位 = 1 个字段：_0[7:0]
// ★本文件由 verif/ut/SnapshotGenerator/gen_variants.py 生成，改请改生成器★
// =============================================================================
module SnapshotGenerator_7(
  input           clock,
  input           reset,
  input           io_enq,
  input  [7:0]    io_enqData_0,
  input           io_deq,
  input           io_redirect,
  input           io_flushVec_0,
  input           io_flushVec_1,
  input           io_flushVec_2,
  input           io_flushVec_3,
  output [7:0]    io_snapshots_0_0,
  output [7:0]    io_snapshots_1_0,
  output [7:0]    io_snapshots_2_0,
  output [7:0]    io_snapshots_3_0
);

  localparam int DW = 8;   // payload 位宽（实测自 golden 端口表）

  logic [DW-1:0] core_enq_data;
  logic [DW-1:0] core_snapshots [4];

  // 打包：golden 端口声明顺序，先声明的在高位。
  assign core_enq_data = {
    io_enqData_0
  };

  xs_SnapshotGenerator_core #(.DATA_W(DW)) u_core (
    .clock     (clock),
    .reset     (reset),
    .enq       (io_enq),
    .enq_data  (core_enq_data),
    .deq       (io_deq),
    .redirect  (io_redirect),
    .flush_vec ({io_flushVec_3, io_flushVec_2, io_flushVec_1, io_flushVec_0}),
    .snapshots (core_snapshots),
    .enq_ptr   (),   // 本变体 golden 端口表里没有，悬空
    .deq_ptr   (),
    .valids    ()
  );

  // 拆包：与上面的打包次序互逆。
  assign io_snapshots_0_0 = core_snapshots[0][7:0];
  assign io_snapshots_1_0 = core_snapshots[1][7:0];
  assign io_snapshots_2_0 = core_snapshots[2][7:0];
  assign io_snapshots_3_0 = core_snapshots[3][7:0];

endmodule
