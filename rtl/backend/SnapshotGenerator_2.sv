// =============================================================================
// SnapshotGenerator_2 —— SnapshotGenerator 家族变体（VType：{illegal, vma, vta, vsew[1:0], vlmul[2:0]}）
// 本文件只做参数化与端口展平；核体见 rtl/backend/SnapshotGenerator.sv
//   （xs_SnapshotGenerator_core，含家族 11 个变体的实测差异表与机制说明）。
// golden 对照：G1-canonical/golden-rtl/SnapshotGenerator_2.sv（34 端口，实测控制逻辑与
//   base 变体逐字节相同，只有 payload 位宽不同）。
// payload 实测 8 位 = 5 个字段：_illegal, _vma, _vta, _vsew[1:0], _vlmul[2:0]
// ★本文件由 verif/ut/SnapshotGenerator/gen_variants.py 生成，改请改生成器★
// =============================================================================
module SnapshotGenerator_2(
  input           clock,
  input           reset,
  input           io_enq,
  input           io_enqData_illegal,
  input           io_enqData_vma,
  input           io_enqData_vta,
  input  [1:0]    io_enqData_vsew,
  input  [2:0]    io_enqData_vlmul,
  input           io_deq,
  input           io_redirect,
  input           io_flushVec_0,
  input           io_flushVec_1,
  input           io_flushVec_2,
  input           io_flushVec_3,
  output          io_snapshots_0_illegal,
  output          io_snapshots_0_vma,
  output          io_snapshots_0_vta,
  output [1:0]    io_snapshots_0_vsew,
  output [2:0]    io_snapshots_0_vlmul,
  output          io_snapshots_1_illegal,
  output          io_snapshots_1_vma,
  output          io_snapshots_1_vta,
  output [1:0]    io_snapshots_1_vsew,
  output [2:0]    io_snapshots_1_vlmul,
  output          io_snapshots_2_illegal,
  output          io_snapshots_2_vma,
  output          io_snapshots_2_vta,
  output [1:0]    io_snapshots_2_vsew,
  output [2:0]    io_snapshots_2_vlmul,
  output          io_snapshots_3_illegal,
  output          io_snapshots_3_vma,
  output          io_snapshots_3_vta,
  output [1:0]    io_snapshots_3_vsew,
  output [2:0]    io_snapshots_3_vlmul
);

  localparam int DW = 8;   // payload 位宽（实测自 golden 端口表）

  logic [DW-1:0] core_enq_data;
  logic [DW-1:0] core_snapshots [4];

  // 打包：golden 端口声明顺序，先声明的在高位。
  assign core_enq_data = {
    io_enqData_illegal,
    io_enqData_vma,
    io_enqData_vta,
    io_enqData_vsew,
    io_enqData_vlmul
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
  assign io_snapshots_0_illegal = core_snapshots[0][7];
  assign io_snapshots_0_vma = core_snapshots[0][6];
  assign io_snapshots_0_vta = core_snapshots[0][5];
  assign io_snapshots_0_vsew = core_snapshots[0][4:3];
  assign io_snapshots_0_vlmul = core_snapshots[0][2:0];
  assign io_snapshots_1_illegal = core_snapshots[1][7];
  assign io_snapshots_1_vma = core_snapshots[1][6];
  assign io_snapshots_1_vta = core_snapshots[1][5];
  assign io_snapshots_1_vsew = core_snapshots[1][4:3];
  assign io_snapshots_1_vlmul = core_snapshots[1][2:0];
  assign io_snapshots_2_illegal = core_snapshots[2][7];
  assign io_snapshots_2_vma = core_snapshots[2][6];
  assign io_snapshots_2_vta = core_snapshots[2][5];
  assign io_snapshots_2_vsew = core_snapshots[2][4:3];
  assign io_snapshots_2_vlmul = core_snapshots[2][2:0];
  assign io_snapshots_3_illegal = core_snapshots[3][7];
  assign io_snapshots_3_vma = core_snapshots[3][6];
  assign io_snapshots_3_vta = core_snapshots[3][5];
  assign io_snapshots_3_vsew = core_snapshots[3][4:3];
  assign io_snapshots_3_vlmul = core_snapshots[3][2:0];

endmodule
