// =============================================================================
// SnapshotGenerator_6 —— SnapshotGenerator 家族变体（47 个 8 位元素的向量）
// 本文件只做参数化与端口展平；核体见 rtl/backend/SnapshotGenerator.sv
//   （xs_SnapshotGenerator_core，含家族 11 个变体的实测差异表与机制说明）。
// golden 对照：G1-canonical/golden-rtl/SnapshotGenerator_6.sv（244 端口，实测控制逻辑与
//   base 变体逐字节相同，只有 payload 位宽不同）。
// payload 实测 376 位 = 47 个字段：_0[7:0], _1[7:0], _2[7:0], _3[7:0], _4[7:0], _5[7:0] ...
// ★本文件由 verif/ut/SnapshotGenerator/gen_variants.py 生成，改请改生成器★
// =============================================================================
module SnapshotGenerator_6(
  input           clock,
  input           reset,
  input           io_enq,
  input  [7:0]    io_enqData_0,
  input  [7:0]    io_enqData_1,
  input  [7:0]    io_enqData_2,
  input  [7:0]    io_enqData_3,
  input  [7:0]    io_enqData_4,
  input  [7:0]    io_enqData_5,
  input  [7:0]    io_enqData_6,
  input  [7:0]    io_enqData_7,
  input  [7:0]    io_enqData_8,
  input  [7:0]    io_enqData_9,
  input  [7:0]    io_enqData_10,
  input  [7:0]    io_enqData_11,
  input  [7:0]    io_enqData_12,
  input  [7:0]    io_enqData_13,
  input  [7:0]    io_enqData_14,
  input  [7:0]    io_enqData_15,
  input  [7:0]    io_enqData_16,
  input  [7:0]    io_enqData_17,
  input  [7:0]    io_enqData_18,
  input  [7:0]    io_enqData_19,
  input  [7:0]    io_enqData_20,
  input  [7:0]    io_enqData_21,
  input  [7:0]    io_enqData_22,
  input  [7:0]    io_enqData_23,
  input  [7:0]    io_enqData_24,
  input  [7:0]    io_enqData_25,
  input  [7:0]    io_enqData_26,
  input  [7:0]    io_enqData_27,
  input  [7:0]    io_enqData_28,
  input  [7:0]    io_enqData_29,
  input  [7:0]    io_enqData_30,
  input  [7:0]    io_enqData_31,
  input  [7:0]    io_enqData_32,
  input  [7:0]    io_enqData_33,
  input  [7:0]    io_enqData_34,
  input  [7:0]    io_enqData_35,
  input  [7:0]    io_enqData_36,
  input  [7:0]    io_enqData_37,
  input  [7:0]    io_enqData_38,
  input  [7:0]    io_enqData_39,
  input  [7:0]    io_enqData_40,
  input  [7:0]    io_enqData_41,
  input  [7:0]    io_enqData_42,
  input  [7:0]    io_enqData_43,
  input  [7:0]    io_enqData_44,
  input  [7:0]    io_enqData_45,
  input  [7:0]    io_enqData_46,
  input           io_deq,
  input           io_redirect,
  input           io_flushVec_0,
  input           io_flushVec_1,
  input           io_flushVec_2,
  input           io_flushVec_3,
  output [7:0]    io_snapshots_0_0,
  output [7:0]    io_snapshots_0_1,
  output [7:0]    io_snapshots_0_2,
  output [7:0]    io_snapshots_0_3,
  output [7:0]    io_snapshots_0_4,
  output [7:0]    io_snapshots_0_5,
  output [7:0]    io_snapshots_0_6,
  output [7:0]    io_snapshots_0_7,
  output [7:0]    io_snapshots_0_8,
  output [7:0]    io_snapshots_0_9,
  output [7:0]    io_snapshots_0_10,
  output [7:0]    io_snapshots_0_11,
  output [7:0]    io_snapshots_0_12,
  output [7:0]    io_snapshots_0_13,
  output [7:0]    io_snapshots_0_14,
  output [7:0]    io_snapshots_0_15,
  output [7:0]    io_snapshots_0_16,
  output [7:0]    io_snapshots_0_17,
  output [7:0]    io_snapshots_0_18,
  output [7:0]    io_snapshots_0_19,
  output [7:0]    io_snapshots_0_20,
  output [7:0]    io_snapshots_0_21,
  output [7:0]    io_snapshots_0_22,
  output [7:0]    io_snapshots_0_23,
  output [7:0]    io_snapshots_0_24,
  output [7:0]    io_snapshots_0_25,
  output [7:0]    io_snapshots_0_26,
  output [7:0]    io_snapshots_0_27,
  output [7:0]    io_snapshots_0_28,
  output [7:0]    io_snapshots_0_29,
  output [7:0]    io_snapshots_0_30,
  output [7:0]    io_snapshots_0_31,
  output [7:0]    io_snapshots_0_32,
  output [7:0]    io_snapshots_0_33,
  output [7:0]    io_snapshots_0_34,
  output [7:0]    io_snapshots_0_35,
  output [7:0]    io_snapshots_0_36,
  output [7:0]    io_snapshots_0_37,
  output [7:0]    io_snapshots_0_38,
  output [7:0]    io_snapshots_0_39,
  output [7:0]    io_snapshots_0_40,
  output [7:0]    io_snapshots_0_41,
  output [7:0]    io_snapshots_0_42,
  output [7:0]    io_snapshots_0_43,
  output [7:0]    io_snapshots_0_44,
  output [7:0]    io_snapshots_0_45,
  output [7:0]    io_snapshots_0_46,
  output [7:0]    io_snapshots_1_0,
  output [7:0]    io_snapshots_1_1,
  output [7:0]    io_snapshots_1_2,
  output [7:0]    io_snapshots_1_3,
  output [7:0]    io_snapshots_1_4,
  output [7:0]    io_snapshots_1_5,
  output [7:0]    io_snapshots_1_6,
  output [7:0]    io_snapshots_1_7,
  output [7:0]    io_snapshots_1_8,
  output [7:0]    io_snapshots_1_9,
  output [7:0]    io_snapshots_1_10,
  output [7:0]    io_snapshots_1_11,
  output [7:0]    io_snapshots_1_12,
  output [7:0]    io_snapshots_1_13,
  output [7:0]    io_snapshots_1_14,
  output [7:0]    io_snapshots_1_15,
  output [7:0]    io_snapshots_1_16,
  output [7:0]    io_snapshots_1_17,
  output [7:0]    io_snapshots_1_18,
  output [7:0]    io_snapshots_1_19,
  output [7:0]    io_snapshots_1_20,
  output [7:0]    io_snapshots_1_21,
  output [7:0]    io_snapshots_1_22,
  output [7:0]    io_snapshots_1_23,
  output [7:0]    io_snapshots_1_24,
  output [7:0]    io_snapshots_1_25,
  output [7:0]    io_snapshots_1_26,
  output [7:0]    io_snapshots_1_27,
  output [7:0]    io_snapshots_1_28,
  output [7:0]    io_snapshots_1_29,
  output [7:0]    io_snapshots_1_30,
  output [7:0]    io_snapshots_1_31,
  output [7:0]    io_snapshots_1_32,
  output [7:0]    io_snapshots_1_33,
  output [7:0]    io_snapshots_1_34,
  output [7:0]    io_snapshots_1_35,
  output [7:0]    io_snapshots_1_36,
  output [7:0]    io_snapshots_1_37,
  output [7:0]    io_snapshots_1_38,
  output [7:0]    io_snapshots_1_39,
  output [7:0]    io_snapshots_1_40,
  output [7:0]    io_snapshots_1_41,
  output [7:0]    io_snapshots_1_42,
  output [7:0]    io_snapshots_1_43,
  output [7:0]    io_snapshots_1_44,
  output [7:0]    io_snapshots_1_45,
  output [7:0]    io_snapshots_1_46,
  output [7:0]    io_snapshots_2_0,
  output [7:0]    io_snapshots_2_1,
  output [7:0]    io_snapshots_2_2,
  output [7:0]    io_snapshots_2_3,
  output [7:0]    io_snapshots_2_4,
  output [7:0]    io_snapshots_2_5,
  output [7:0]    io_snapshots_2_6,
  output [7:0]    io_snapshots_2_7,
  output [7:0]    io_snapshots_2_8,
  output [7:0]    io_snapshots_2_9,
  output [7:0]    io_snapshots_2_10,
  output [7:0]    io_snapshots_2_11,
  output [7:0]    io_snapshots_2_12,
  output [7:0]    io_snapshots_2_13,
  output [7:0]    io_snapshots_2_14,
  output [7:0]    io_snapshots_2_15,
  output [7:0]    io_snapshots_2_16,
  output [7:0]    io_snapshots_2_17,
  output [7:0]    io_snapshots_2_18,
  output [7:0]    io_snapshots_2_19,
  output [7:0]    io_snapshots_2_20,
  output [7:0]    io_snapshots_2_21,
  output [7:0]    io_snapshots_2_22,
  output [7:0]    io_snapshots_2_23,
  output [7:0]    io_snapshots_2_24,
  output [7:0]    io_snapshots_2_25,
  output [7:0]    io_snapshots_2_26,
  output [7:0]    io_snapshots_2_27,
  output [7:0]    io_snapshots_2_28,
  output [7:0]    io_snapshots_2_29,
  output [7:0]    io_snapshots_2_30,
  output [7:0]    io_snapshots_2_31,
  output [7:0]    io_snapshots_2_32,
  output [7:0]    io_snapshots_2_33,
  output [7:0]    io_snapshots_2_34,
  output [7:0]    io_snapshots_2_35,
  output [7:0]    io_snapshots_2_36,
  output [7:0]    io_snapshots_2_37,
  output [7:0]    io_snapshots_2_38,
  output [7:0]    io_snapshots_2_39,
  output [7:0]    io_snapshots_2_40,
  output [7:0]    io_snapshots_2_41,
  output [7:0]    io_snapshots_2_42,
  output [7:0]    io_snapshots_2_43,
  output [7:0]    io_snapshots_2_44,
  output [7:0]    io_snapshots_2_45,
  output [7:0]    io_snapshots_2_46,
  output [7:0]    io_snapshots_3_0,
  output [7:0]    io_snapshots_3_1,
  output [7:0]    io_snapshots_3_2,
  output [7:0]    io_snapshots_3_3,
  output [7:0]    io_snapshots_3_4,
  output [7:0]    io_snapshots_3_5,
  output [7:0]    io_snapshots_3_6,
  output [7:0]    io_snapshots_3_7,
  output [7:0]    io_snapshots_3_8,
  output [7:0]    io_snapshots_3_9,
  output [7:0]    io_snapshots_3_10,
  output [7:0]    io_snapshots_3_11,
  output [7:0]    io_snapshots_3_12,
  output [7:0]    io_snapshots_3_13,
  output [7:0]    io_snapshots_3_14,
  output [7:0]    io_snapshots_3_15,
  output [7:0]    io_snapshots_3_16,
  output [7:0]    io_snapshots_3_17,
  output [7:0]    io_snapshots_3_18,
  output [7:0]    io_snapshots_3_19,
  output [7:0]    io_snapshots_3_20,
  output [7:0]    io_snapshots_3_21,
  output [7:0]    io_snapshots_3_22,
  output [7:0]    io_snapshots_3_23,
  output [7:0]    io_snapshots_3_24,
  output [7:0]    io_snapshots_3_25,
  output [7:0]    io_snapshots_3_26,
  output [7:0]    io_snapshots_3_27,
  output [7:0]    io_snapshots_3_28,
  output [7:0]    io_snapshots_3_29,
  output [7:0]    io_snapshots_3_30,
  output [7:0]    io_snapshots_3_31,
  output [7:0]    io_snapshots_3_32,
  output [7:0]    io_snapshots_3_33,
  output [7:0]    io_snapshots_3_34,
  output [7:0]    io_snapshots_3_35,
  output [7:0]    io_snapshots_3_36,
  output [7:0]    io_snapshots_3_37,
  output [7:0]    io_snapshots_3_38,
  output [7:0]    io_snapshots_3_39,
  output [7:0]    io_snapshots_3_40,
  output [7:0]    io_snapshots_3_41,
  output [7:0]    io_snapshots_3_42,
  output [7:0]    io_snapshots_3_43,
  output [7:0]    io_snapshots_3_44,
  output [7:0]    io_snapshots_3_45,
  output [7:0]    io_snapshots_3_46
);

  localparam int DW = 376;   // payload 位宽（实测自 golden 端口表）

  logic [DW-1:0] core_enq_data;
  logic [DW-1:0] core_snapshots [4];

  // 打包：golden 端口声明顺序，先声明的在高位。
  assign core_enq_data = {
    io_enqData_0,
    io_enqData_1,
    io_enqData_2,
    io_enqData_3,
    io_enqData_4,
    io_enqData_5,
    io_enqData_6,
    io_enqData_7,
    io_enqData_8,
    io_enqData_9,
    io_enqData_10,
    io_enqData_11,
    io_enqData_12,
    io_enqData_13,
    io_enqData_14,
    io_enqData_15,
    io_enqData_16,
    io_enqData_17,
    io_enqData_18,
    io_enqData_19,
    io_enqData_20,
    io_enqData_21,
    io_enqData_22,
    io_enqData_23,
    io_enqData_24,
    io_enqData_25,
    io_enqData_26,
    io_enqData_27,
    io_enqData_28,
    io_enqData_29,
    io_enqData_30,
    io_enqData_31,
    io_enqData_32,
    io_enqData_33,
    io_enqData_34,
    io_enqData_35,
    io_enqData_36,
    io_enqData_37,
    io_enqData_38,
    io_enqData_39,
    io_enqData_40,
    io_enqData_41,
    io_enqData_42,
    io_enqData_43,
    io_enqData_44,
    io_enqData_45,
    io_enqData_46
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
  assign io_snapshots_0_0 = core_snapshots[0][375:368];
  assign io_snapshots_0_1 = core_snapshots[0][367:360];
  assign io_snapshots_0_2 = core_snapshots[0][359:352];
  assign io_snapshots_0_3 = core_snapshots[0][351:344];
  assign io_snapshots_0_4 = core_snapshots[0][343:336];
  assign io_snapshots_0_5 = core_snapshots[0][335:328];
  assign io_snapshots_0_6 = core_snapshots[0][327:320];
  assign io_snapshots_0_7 = core_snapshots[0][319:312];
  assign io_snapshots_0_8 = core_snapshots[0][311:304];
  assign io_snapshots_0_9 = core_snapshots[0][303:296];
  assign io_snapshots_0_10 = core_snapshots[0][295:288];
  assign io_snapshots_0_11 = core_snapshots[0][287:280];
  assign io_snapshots_0_12 = core_snapshots[0][279:272];
  assign io_snapshots_0_13 = core_snapshots[0][271:264];
  assign io_snapshots_0_14 = core_snapshots[0][263:256];
  assign io_snapshots_0_15 = core_snapshots[0][255:248];
  assign io_snapshots_0_16 = core_snapshots[0][247:240];
  assign io_snapshots_0_17 = core_snapshots[0][239:232];
  assign io_snapshots_0_18 = core_snapshots[0][231:224];
  assign io_snapshots_0_19 = core_snapshots[0][223:216];
  assign io_snapshots_0_20 = core_snapshots[0][215:208];
  assign io_snapshots_0_21 = core_snapshots[0][207:200];
  assign io_snapshots_0_22 = core_snapshots[0][199:192];
  assign io_snapshots_0_23 = core_snapshots[0][191:184];
  assign io_snapshots_0_24 = core_snapshots[0][183:176];
  assign io_snapshots_0_25 = core_snapshots[0][175:168];
  assign io_snapshots_0_26 = core_snapshots[0][167:160];
  assign io_snapshots_0_27 = core_snapshots[0][159:152];
  assign io_snapshots_0_28 = core_snapshots[0][151:144];
  assign io_snapshots_0_29 = core_snapshots[0][143:136];
  assign io_snapshots_0_30 = core_snapshots[0][135:128];
  assign io_snapshots_0_31 = core_snapshots[0][127:120];
  assign io_snapshots_0_32 = core_snapshots[0][119:112];
  assign io_snapshots_0_33 = core_snapshots[0][111:104];
  assign io_snapshots_0_34 = core_snapshots[0][103:96];
  assign io_snapshots_0_35 = core_snapshots[0][95:88];
  assign io_snapshots_0_36 = core_snapshots[0][87:80];
  assign io_snapshots_0_37 = core_snapshots[0][79:72];
  assign io_snapshots_0_38 = core_snapshots[0][71:64];
  assign io_snapshots_0_39 = core_snapshots[0][63:56];
  assign io_snapshots_0_40 = core_snapshots[0][55:48];
  assign io_snapshots_0_41 = core_snapshots[0][47:40];
  assign io_snapshots_0_42 = core_snapshots[0][39:32];
  assign io_snapshots_0_43 = core_snapshots[0][31:24];
  assign io_snapshots_0_44 = core_snapshots[0][23:16];
  assign io_snapshots_0_45 = core_snapshots[0][15:8];
  assign io_snapshots_0_46 = core_snapshots[0][7:0];
  assign io_snapshots_1_0 = core_snapshots[1][375:368];
  assign io_snapshots_1_1 = core_snapshots[1][367:360];
  assign io_snapshots_1_2 = core_snapshots[1][359:352];
  assign io_snapshots_1_3 = core_snapshots[1][351:344];
  assign io_snapshots_1_4 = core_snapshots[1][343:336];
  assign io_snapshots_1_5 = core_snapshots[1][335:328];
  assign io_snapshots_1_6 = core_snapshots[1][327:320];
  assign io_snapshots_1_7 = core_snapshots[1][319:312];
  assign io_snapshots_1_8 = core_snapshots[1][311:304];
  assign io_snapshots_1_9 = core_snapshots[1][303:296];
  assign io_snapshots_1_10 = core_snapshots[1][295:288];
  assign io_snapshots_1_11 = core_snapshots[1][287:280];
  assign io_snapshots_1_12 = core_snapshots[1][279:272];
  assign io_snapshots_1_13 = core_snapshots[1][271:264];
  assign io_snapshots_1_14 = core_snapshots[1][263:256];
  assign io_snapshots_1_15 = core_snapshots[1][255:248];
  assign io_snapshots_1_16 = core_snapshots[1][247:240];
  assign io_snapshots_1_17 = core_snapshots[1][239:232];
  assign io_snapshots_1_18 = core_snapshots[1][231:224];
  assign io_snapshots_1_19 = core_snapshots[1][223:216];
  assign io_snapshots_1_20 = core_snapshots[1][215:208];
  assign io_snapshots_1_21 = core_snapshots[1][207:200];
  assign io_snapshots_1_22 = core_snapshots[1][199:192];
  assign io_snapshots_1_23 = core_snapshots[1][191:184];
  assign io_snapshots_1_24 = core_snapshots[1][183:176];
  assign io_snapshots_1_25 = core_snapshots[1][175:168];
  assign io_snapshots_1_26 = core_snapshots[1][167:160];
  assign io_snapshots_1_27 = core_snapshots[1][159:152];
  assign io_snapshots_1_28 = core_snapshots[1][151:144];
  assign io_snapshots_1_29 = core_snapshots[1][143:136];
  assign io_snapshots_1_30 = core_snapshots[1][135:128];
  assign io_snapshots_1_31 = core_snapshots[1][127:120];
  assign io_snapshots_1_32 = core_snapshots[1][119:112];
  assign io_snapshots_1_33 = core_snapshots[1][111:104];
  assign io_snapshots_1_34 = core_snapshots[1][103:96];
  assign io_snapshots_1_35 = core_snapshots[1][95:88];
  assign io_snapshots_1_36 = core_snapshots[1][87:80];
  assign io_snapshots_1_37 = core_snapshots[1][79:72];
  assign io_snapshots_1_38 = core_snapshots[1][71:64];
  assign io_snapshots_1_39 = core_snapshots[1][63:56];
  assign io_snapshots_1_40 = core_snapshots[1][55:48];
  assign io_snapshots_1_41 = core_snapshots[1][47:40];
  assign io_snapshots_1_42 = core_snapshots[1][39:32];
  assign io_snapshots_1_43 = core_snapshots[1][31:24];
  assign io_snapshots_1_44 = core_snapshots[1][23:16];
  assign io_snapshots_1_45 = core_snapshots[1][15:8];
  assign io_snapshots_1_46 = core_snapshots[1][7:0];
  assign io_snapshots_2_0 = core_snapshots[2][375:368];
  assign io_snapshots_2_1 = core_snapshots[2][367:360];
  assign io_snapshots_2_2 = core_snapshots[2][359:352];
  assign io_snapshots_2_3 = core_snapshots[2][351:344];
  assign io_snapshots_2_4 = core_snapshots[2][343:336];
  assign io_snapshots_2_5 = core_snapshots[2][335:328];
  assign io_snapshots_2_6 = core_snapshots[2][327:320];
  assign io_snapshots_2_7 = core_snapshots[2][319:312];
  assign io_snapshots_2_8 = core_snapshots[2][311:304];
  assign io_snapshots_2_9 = core_snapshots[2][303:296];
  assign io_snapshots_2_10 = core_snapshots[2][295:288];
  assign io_snapshots_2_11 = core_snapshots[2][287:280];
  assign io_snapshots_2_12 = core_snapshots[2][279:272];
  assign io_snapshots_2_13 = core_snapshots[2][271:264];
  assign io_snapshots_2_14 = core_snapshots[2][263:256];
  assign io_snapshots_2_15 = core_snapshots[2][255:248];
  assign io_snapshots_2_16 = core_snapshots[2][247:240];
  assign io_snapshots_2_17 = core_snapshots[2][239:232];
  assign io_snapshots_2_18 = core_snapshots[2][231:224];
  assign io_snapshots_2_19 = core_snapshots[2][223:216];
  assign io_snapshots_2_20 = core_snapshots[2][215:208];
  assign io_snapshots_2_21 = core_snapshots[2][207:200];
  assign io_snapshots_2_22 = core_snapshots[2][199:192];
  assign io_snapshots_2_23 = core_snapshots[2][191:184];
  assign io_snapshots_2_24 = core_snapshots[2][183:176];
  assign io_snapshots_2_25 = core_snapshots[2][175:168];
  assign io_snapshots_2_26 = core_snapshots[2][167:160];
  assign io_snapshots_2_27 = core_snapshots[2][159:152];
  assign io_snapshots_2_28 = core_snapshots[2][151:144];
  assign io_snapshots_2_29 = core_snapshots[2][143:136];
  assign io_snapshots_2_30 = core_snapshots[2][135:128];
  assign io_snapshots_2_31 = core_snapshots[2][127:120];
  assign io_snapshots_2_32 = core_snapshots[2][119:112];
  assign io_snapshots_2_33 = core_snapshots[2][111:104];
  assign io_snapshots_2_34 = core_snapshots[2][103:96];
  assign io_snapshots_2_35 = core_snapshots[2][95:88];
  assign io_snapshots_2_36 = core_snapshots[2][87:80];
  assign io_snapshots_2_37 = core_snapshots[2][79:72];
  assign io_snapshots_2_38 = core_snapshots[2][71:64];
  assign io_snapshots_2_39 = core_snapshots[2][63:56];
  assign io_snapshots_2_40 = core_snapshots[2][55:48];
  assign io_snapshots_2_41 = core_snapshots[2][47:40];
  assign io_snapshots_2_42 = core_snapshots[2][39:32];
  assign io_snapshots_2_43 = core_snapshots[2][31:24];
  assign io_snapshots_2_44 = core_snapshots[2][23:16];
  assign io_snapshots_2_45 = core_snapshots[2][15:8];
  assign io_snapshots_2_46 = core_snapshots[2][7:0];
  assign io_snapshots_3_0 = core_snapshots[3][375:368];
  assign io_snapshots_3_1 = core_snapshots[3][367:360];
  assign io_snapshots_3_2 = core_snapshots[3][359:352];
  assign io_snapshots_3_3 = core_snapshots[3][351:344];
  assign io_snapshots_3_4 = core_snapshots[3][343:336];
  assign io_snapshots_3_5 = core_snapshots[3][335:328];
  assign io_snapshots_3_6 = core_snapshots[3][327:320];
  assign io_snapshots_3_7 = core_snapshots[3][319:312];
  assign io_snapshots_3_8 = core_snapshots[3][311:304];
  assign io_snapshots_3_9 = core_snapshots[3][303:296];
  assign io_snapshots_3_10 = core_snapshots[3][295:288];
  assign io_snapshots_3_11 = core_snapshots[3][287:280];
  assign io_snapshots_3_12 = core_snapshots[3][279:272];
  assign io_snapshots_3_13 = core_snapshots[3][271:264];
  assign io_snapshots_3_14 = core_snapshots[3][263:256];
  assign io_snapshots_3_15 = core_snapshots[3][255:248];
  assign io_snapshots_3_16 = core_snapshots[3][247:240];
  assign io_snapshots_3_17 = core_snapshots[3][239:232];
  assign io_snapshots_3_18 = core_snapshots[3][231:224];
  assign io_snapshots_3_19 = core_snapshots[3][223:216];
  assign io_snapshots_3_20 = core_snapshots[3][215:208];
  assign io_snapshots_3_21 = core_snapshots[3][207:200];
  assign io_snapshots_3_22 = core_snapshots[3][199:192];
  assign io_snapshots_3_23 = core_snapshots[3][191:184];
  assign io_snapshots_3_24 = core_snapshots[3][183:176];
  assign io_snapshots_3_25 = core_snapshots[3][175:168];
  assign io_snapshots_3_26 = core_snapshots[3][167:160];
  assign io_snapshots_3_27 = core_snapshots[3][159:152];
  assign io_snapshots_3_28 = core_snapshots[3][151:144];
  assign io_snapshots_3_29 = core_snapshots[3][143:136];
  assign io_snapshots_3_30 = core_snapshots[3][135:128];
  assign io_snapshots_3_31 = core_snapshots[3][127:120];
  assign io_snapshots_3_32 = core_snapshots[3][119:112];
  assign io_snapshots_3_33 = core_snapshots[3][111:104];
  assign io_snapshots_3_34 = core_snapshots[3][103:96];
  assign io_snapshots_3_35 = core_snapshots[3][95:88];
  assign io_snapshots_3_36 = core_snapshots[3][87:80];
  assign io_snapshots_3_37 = core_snapshots[3][79:72];
  assign io_snapshots_3_38 = core_snapshots[3][71:64];
  assign io_snapshots_3_39 = core_snapshots[3][63:56];
  assign io_snapshots_3_40 = core_snapshots[3][55:48];
  assign io_snapshots_3_41 = core_snapshots[3][47:40];
  assign io_snapshots_3_42 = core_snapshots[3][39:32];
  assign io_snapshots_3_43 = core_snapshots[3][31:24];
  assign io_snapshots_3_44 = core_snapshots[3][23:16];
  assign io_snapshots_3_45 = core_snapshots[3][15:8];
  assign io_snapshots_3_46 = core_snapshots[3][7:0];

endmodule
