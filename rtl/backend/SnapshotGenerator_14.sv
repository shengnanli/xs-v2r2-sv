// =============================================================================
// SnapshotGenerator_14 —— SnapshotGenerator 家族变体（Vec(6) of {flag, value[7:0]} 与 Vec(6) of Bool 两段拼接；★本变体的 golden 还留着 enqPtr/deqPtr/valids 输出★）
// 本文件只做参数化与端口展平；核体见 rtl/backend/SnapshotGenerator.sv
//   （xs_SnapshotGenerator_core，含家族 11 个变体的实测差异表与机制说明）。
// golden 对照：G1-canonical/golden-rtl/SnapshotGenerator_14.sv（107 端口，实测控制逻辑与
//   base 变体逐字节相同，只有 payload 位宽与 ptr/valids 输出不同）。
// payload 实测 60 位 = 18 个字段：_robIdx_0_flag, _robIdx_0_value[7:0], _robIdx_1_flag, _robIdx_1_value[7:0], _robIdx_2_flag, _robIdx_2_value[7:0] ...
// ★本文件由 verif/ut/SnapshotGenerator/gen_variants.py 生成，改请改生成器★
// =============================================================================
module SnapshotGenerator_14(
  input           clock,
  input           reset,
  input           io_enq,
  input           io_enqData_robIdx_0_flag,
  input  [7:0]    io_enqData_robIdx_0_value,
  input           io_enqData_robIdx_1_flag,
  input  [7:0]    io_enqData_robIdx_1_value,
  input           io_enqData_robIdx_2_flag,
  input  [7:0]    io_enqData_robIdx_2_value,
  input           io_enqData_robIdx_3_flag,
  input  [7:0]    io_enqData_robIdx_3_value,
  input           io_enqData_robIdx_4_flag,
  input  [7:0]    io_enqData_robIdx_4_value,
  input           io_enqData_robIdx_5_flag,
  input  [7:0]    io_enqData_robIdx_5_value,
  input           io_enqData_isCFI_0,
  input           io_enqData_isCFI_1,
  input           io_enqData_isCFI_2,
  input           io_enqData_isCFI_3,
  input           io_enqData_isCFI_4,
  input           io_enqData_isCFI_5,
  input           io_deq,
  input           io_redirect,
  input           io_flushVec_0,
  input           io_flushVec_1,
  input           io_flushVec_2,
  input           io_flushVec_3,
  output          io_snapshots_0_robIdx_0_flag,
  output [7:0]    io_snapshots_0_robIdx_0_value,
  output          io_snapshots_0_robIdx_1_flag,
  output [7:0]    io_snapshots_0_robIdx_1_value,
  output          io_snapshots_0_robIdx_2_flag,
  output [7:0]    io_snapshots_0_robIdx_2_value,
  output          io_snapshots_0_robIdx_3_flag,
  output [7:0]    io_snapshots_0_robIdx_3_value,
  output          io_snapshots_0_robIdx_4_flag,
  output [7:0]    io_snapshots_0_robIdx_4_value,
  output          io_snapshots_0_robIdx_5_flag,
  output [7:0]    io_snapshots_0_robIdx_5_value,
  output          io_snapshots_0_isCFI_0,
  output          io_snapshots_0_isCFI_1,
  output          io_snapshots_0_isCFI_2,
  output          io_snapshots_0_isCFI_3,
  output          io_snapshots_0_isCFI_4,
  output          io_snapshots_0_isCFI_5,
  output          io_snapshots_1_robIdx_0_flag,
  output [7:0]    io_snapshots_1_robIdx_0_value,
  output          io_snapshots_1_robIdx_1_flag,
  output [7:0]    io_snapshots_1_robIdx_1_value,
  output          io_snapshots_1_robIdx_2_flag,
  output [7:0]    io_snapshots_1_robIdx_2_value,
  output          io_snapshots_1_robIdx_3_flag,
  output [7:0]    io_snapshots_1_robIdx_3_value,
  output          io_snapshots_1_robIdx_4_flag,
  output [7:0]    io_snapshots_1_robIdx_4_value,
  output          io_snapshots_1_robIdx_5_flag,
  output [7:0]    io_snapshots_1_robIdx_5_value,
  output          io_snapshots_1_isCFI_0,
  output          io_snapshots_1_isCFI_1,
  output          io_snapshots_1_isCFI_2,
  output          io_snapshots_1_isCFI_3,
  output          io_snapshots_1_isCFI_4,
  output          io_snapshots_1_isCFI_5,
  output          io_snapshots_2_robIdx_0_flag,
  output [7:0]    io_snapshots_2_robIdx_0_value,
  output          io_snapshots_2_robIdx_1_flag,
  output [7:0]    io_snapshots_2_robIdx_1_value,
  output          io_snapshots_2_robIdx_2_flag,
  output [7:0]    io_snapshots_2_robIdx_2_value,
  output          io_snapshots_2_robIdx_3_flag,
  output [7:0]    io_snapshots_2_robIdx_3_value,
  output          io_snapshots_2_robIdx_4_flag,
  output [7:0]    io_snapshots_2_robIdx_4_value,
  output          io_snapshots_2_robIdx_5_flag,
  output [7:0]    io_snapshots_2_robIdx_5_value,
  output          io_snapshots_2_isCFI_0,
  output          io_snapshots_2_isCFI_1,
  output          io_snapshots_2_isCFI_2,
  output          io_snapshots_2_isCFI_3,
  output          io_snapshots_2_isCFI_4,
  output          io_snapshots_2_isCFI_5,
  output          io_snapshots_3_robIdx_0_flag,
  output [7:0]    io_snapshots_3_robIdx_0_value,
  output          io_snapshots_3_robIdx_1_flag,
  output [7:0]    io_snapshots_3_robIdx_1_value,
  output          io_snapshots_3_robIdx_2_flag,
  output [7:0]    io_snapshots_3_robIdx_2_value,
  output          io_snapshots_3_robIdx_3_flag,
  output [7:0]    io_snapshots_3_robIdx_3_value,
  output          io_snapshots_3_robIdx_4_flag,
  output [7:0]    io_snapshots_3_robIdx_4_value,
  output          io_snapshots_3_robIdx_5_flag,
  output [7:0]    io_snapshots_3_robIdx_5_value,
  output          io_snapshots_3_isCFI_0,
  output          io_snapshots_3_isCFI_1,
  output          io_snapshots_3_isCFI_2,
  output          io_snapshots_3_isCFI_3,
  output          io_snapshots_3_isCFI_4,
  output          io_snapshots_3_isCFI_5,
  output          io_enqPtr_flag,
  output [1:0]    io_enqPtr_value,
  output          io_deqPtr_flag,
  output [1:0]    io_deqPtr_value,
  output          io_valids_0,
  output          io_valids_1,
  output          io_valids_2,
  output          io_valids_3
);

  localparam int DW = 60;   // payload 位宽（实测自 golden 端口表）

  logic [DW-1:0] core_enq_data;
  logic [DW-1:0] core_snapshots [4];

  // 打包：golden 端口声明顺序，先声明的在高位。
  assign core_enq_data = {
    io_enqData_robIdx_0_flag,
    io_enqData_robIdx_0_value,
    io_enqData_robIdx_1_flag,
    io_enqData_robIdx_1_value,
    io_enqData_robIdx_2_flag,
    io_enqData_robIdx_2_value,
    io_enqData_robIdx_3_flag,
    io_enqData_robIdx_3_value,
    io_enqData_robIdx_4_flag,
    io_enqData_robIdx_4_value,
    io_enqData_robIdx_5_flag,
    io_enqData_robIdx_5_value,
    io_enqData_isCFI_0,
    io_enqData_isCFI_1,
    io_enqData_isCFI_2,
    io_enqData_isCFI_3,
    io_enqData_isCFI_4,
    io_enqData_isCFI_5
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
    // ★只有本变体的 golden 留着这三组端口★（别的变体被 firtool 消掉了）
    .enq_ptr   ({io_enqPtr_flag, io_enqPtr_value}),
    .deq_ptr   ({io_deqPtr_flag, io_deqPtr_value}),
    .valids    ({io_valids_3, io_valids_2, io_valids_1, io_valids_0})
  );

  // 拆包：与上面的打包次序互逆。
  assign io_snapshots_0_robIdx_0_flag = core_snapshots[0][59];
  assign io_snapshots_0_robIdx_0_value = core_snapshots[0][58:51];
  assign io_snapshots_0_robIdx_1_flag = core_snapshots[0][50];
  assign io_snapshots_0_robIdx_1_value = core_snapshots[0][49:42];
  assign io_snapshots_0_robIdx_2_flag = core_snapshots[0][41];
  assign io_snapshots_0_robIdx_2_value = core_snapshots[0][40:33];
  assign io_snapshots_0_robIdx_3_flag = core_snapshots[0][32];
  assign io_snapshots_0_robIdx_3_value = core_snapshots[0][31:24];
  assign io_snapshots_0_robIdx_4_flag = core_snapshots[0][23];
  assign io_snapshots_0_robIdx_4_value = core_snapshots[0][22:15];
  assign io_snapshots_0_robIdx_5_flag = core_snapshots[0][14];
  assign io_snapshots_0_robIdx_5_value = core_snapshots[0][13:6];
  assign io_snapshots_0_isCFI_0 = core_snapshots[0][5];
  assign io_snapshots_0_isCFI_1 = core_snapshots[0][4];
  assign io_snapshots_0_isCFI_2 = core_snapshots[0][3];
  assign io_snapshots_0_isCFI_3 = core_snapshots[0][2];
  assign io_snapshots_0_isCFI_4 = core_snapshots[0][1];
  assign io_snapshots_0_isCFI_5 = core_snapshots[0][0];
  assign io_snapshots_1_robIdx_0_flag = core_snapshots[1][59];
  assign io_snapshots_1_robIdx_0_value = core_snapshots[1][58:51];
  assign io_snapshots_1_robIdx_1_flag = core_snapshots[1][50];
  assign io_snapshots_1_robIdx_1_value = core_snapshots[1][49:42];
  assign io_snapshots_1_robIdx_2_flag = core_snapshots[1][41];
  assign io_snapshots_1_robIdx_2_value = core_snapshots[1][40:33];
  assign io_snapshots_1_robIdx_3_flag = core_snapshots[1][32];
  assign io_snapshots_1_robIdx_3_value = core_snapshots[1][31:24];
  assign io_snapshots_1_robIdx_4_flag = core_snapshots[1][23];
  assign io_snapshots_1_robIdx_4_value = core_snapshots[1][22:15];
  assign io_snapshots_1_robIdx_5_flag = core_snapshots[1][14];
  assign io_snapshots_1_robIdx_5_value = core_snapshots[1][13:6];
  assign io_snapshots_1_isCFI_0 = core_snapshots[1][5];
  assign io_snapshots_1_isCFI_1 = core_snapshots[1][4];
  assign io_snapshots_1_isCFI_2 = core_snapshots[1][3];
  assign io_snapshots_1_isCFI_3 = core_snapshots[1][2];
  assign io_snapshots_1_isCFI_4 = core_snapshots[1][1];
  assign io_snapshots_1_isCFI_5 = core_snapshots[1][0];
  assign io_snapshots_2_robIdx_0_flag = core_snapshots[2][59];
  assign io_snapshots_2_robIdx_0_value = core_snapshots[2][58:51];
  assign io_snapshots_2_robIdx_1_flag = core_snapshots[2][50];
  assign io_snapshots_2_robIdx_1_value = core_snapshots[2][49:42];
  assign io_snapshots_2_robIdx_2_flag = core_snapshots[2][41];
  assign io_snapshots_2_robIdx_2_value = core_snapshots[2][40:33];
  assign io_snapshots_2_robIdx_3_flag = core_snapshots[2][32];
  assign io_snapshots_2_robIdx_3_value = core_snapshots[2][31:24];
  assign io_snapshots_2_robIdx_4_flag = core_snapshots[2][23];
  assign io_snapshots_2_robIdx_4_value = core_snapshots[2][22:15];
  assign io_snapshots_2_robIdx_5_flag = core_snapshots[2][14];
  assign io_snapshots_2_robIdx_5_value = core_snapshots[2][13:6];
  assign io_snapshots_2_isCFI_0 = core_snapshots[2][5];
  assign io_snapshots_2_isCFI_1 = core_snapshots[2][4];
  assign io_snapshots_2_isCFI_2 = core_snapshots[2][3];
  assign io_snapshots_2_isCFI_3 = core_snapshots[2][2];
  assign io_snapshots_2_isCFI_4 = core_snapshots[2][1];
  assign io_snapshots_2_isCFI_5 = core_snapshots[2][0];
  assign io_snapshots_3_robIdx_0_flag = core_snapshots[3][59];
  assign io_snapshots_3_robIdx_0_value = core_snapshots[3][58:51];
  assign io_snapshots_3_robIdx_1_flag = core_snapshots[3][50];
  assign io_snapshots_3_robIdx_1_value = core_snapshots[3][49:42];
  assign io_snapshots_3_robIdx_2_flag = core_snapshots[3][41];
  assign io_snapshots_3_robIdx_2_value = core_snapshots[3][40:33];
  assign io_snapshots_3_robIdx_3_flag = core_snapshots[3][32];
  assign io_snapshots_3_robIdx_3_value = core_snapshots[3][31:24];
  assign io_snapshots_3_robIdx_4_flag = core_snapshots[3][23];
  assign io_snapshots_3_robIdx_4_value = core_snapshots[3][22:15];
  assign io_snapshots_3_robIdx_5_flag = core_snapshots[3][14];
  assign io_snapshots_3_robIdx_5_value = core_snapshots[3][13:6];
  assign io_snapshots_3_isCFI_0 = core_snapshots[3][5];
  assign io_snapshots_3_isCFI_1 = core_snapshots[3][4];
  assign io_snapshots_3_isCFI_2 = core_snapshots[3][3];
  assign io_snapshots_3_isCFI_3 = core_snapshots[3][2];
  assign io_snapshots_3_isCFI_4 = core_snapshots[3][1];
  assign io_snapshots_3_isCFI_5 = core_snapshots[3][0];

endmodule
