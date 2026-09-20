// =============================================================================
// RenameTable_2 —— RenameTable 家族变体：向量 RAT（Reg_V）
//
// 规模：47 格 x 8 位、地址 6 位、18 个读口（3 源操作数 x RenameWidth 6）、
//       6 个投机写口 + 6 个体系结构写口、快照件 SnapshotGenerator_6（47 x 8）。
// 复位初值是 identity（第 i 格填 i）。
//
// ★本变体的两组调试输出都从第 1 格起算，只导 31 格★（不是 0..30 也不是 0..46）：
//   Chisel 里 debug_rdata 取 `arch_table.drop(1).take(vecEntries)`、
//   diffRatBase 取 `spec_table_next.drop(v0Entries).take(vecEntries)`，
//   而 v0Entries = 1、vecEntries = 31。跳过的第 0 格是 v0 那一格，
//   它由 RenameTable_3（v0Rat）单独管。
// 核体见 rtl/backend/RenameTable.sv，本文件仅设参数、展平端口、例化快照件。
// ★本文件由 verif/ut/RenameTable/gen_variants.py 生成，改请改生成器★
// =============================================================================
module RenameTable_2(
  input        clock,
  input        reset,
  input        io_redirect,
  input        io_readPorts_0_hold,
  input  [5:0] io_readPorts_0_addr,
  output [7:0] io_readPorts_0_data,
  input        io_readPorts_1_hold,
  input  [5:0] io_readPorts_1_addr,
  output [7:0] io_readPorts_1_data,
  input        io_readPorts_2_hold,
  input  [5:0] io_readPorts_2_addr,
  output [7:0] io_readPorts_2_data,
  input        io_readPorts_3_hold,
  input  [5:0] io_readPorts_3_addr,
  output [7:0] io_readPorts_3_data,
  input        io_readPorts_4_hold,
  input  [5:0] io_readPorts_4_addr,
  output [7:0] io_readPorts_4_data,
  input        io_readPorts_5_hold,
  input  [5:0] io_readPorts_5_addr,
  output [7:0] io_readPorts_5_data,
  input        io_readPorts_6_hold,
  input  [5:0] io_readPorts_6_addr,
  output [7:0] io_readPorts_6_data,
  input        io_readPorts_7_hold,
  input  [5:0] io_readPorts_7_addr,
  output [7:0] io_readPorts_7_data,
  input        io_readPorts_8_hold,
  input  [5:0] io_readPorts_8_addr,
  output [7:0] io_readPorts_8_data,
  input        io_readPorts_9_hold,
  input  [5:0] io_readPorts_9_addr,
  output [7:0] io_readPorts_9_data,
  input        io_readPorts_10_hold,
  input  [5:0] io_readPorts_10_addr,
  output [7:0] io_readPorts_10_data,
  input        io_readPorts_11_hold,
  input  [5:0] io_readPorts_11_addr,
  output [7:0] io_readPorts_11_data,
  input        io_readPorts_12_hold,
  input  [5:0] io_readPorts_12_addr,
  output [7:0] io_readPorts_12_data,
  input        io_readPorts_13_hold,
  input  [5:0] io_readPorts_13_addr,
  output [7:0] io_readPorts_13_data,
  input        io_readPorts_14_hold,
  input  [5:0] io_readPorts_14_addr,
  output [7:0] io_readPorts_14_data,
  input        io_readPorts_15_hold,
  input  [5:0] io_readPorts_15_addr,
  output [7:0] io_readPorts_15_data,
  input        io_readPorts_16_hold,
  input  [5:0] io_readPorts_16_addr,
  output [7:0] io_readPorts_16_data,
  input        io_readPorts_17_hold,
  input  [5:0] io_readPorts_17_addr,
  output [7:0] io_readPorts_17_data,
  input        io_specWritePorts_0_wen,
  input  [5:0] io_specWritePorts_0_addr,
  input  [7:0] io_specWritePorts_0_data,
  input        io_specWritePorts_1_wen,
  input  [5:0] io_specWritePorts_1_addr,
  input  [7:0] io_specWritePorts_1_data,
  input        io_specWritePorts_2_wen,
  input  [5:0] io_specWritePorts_2_addr,
  input  [7:0] io_specWritePorts_2_data,
  input        io_specWritePorts_3_wen,
  input  [5:0] io_specWritePorts_3_addr,
  input  [7:0] io_specWritePorts_3_data,
  input        io_specWritePorts_4_wen,
  input  [5:0] io_specWritePorts_4_addr,
  input  [7:0] io_specWritePorts_4_data,
  input        io_specWritePorts_5_wen,
  input  [5:0] io_specWritePorts_5_addr,
  input  [7:0] io_specWritePorts_5_data,
  input        io_archWritePorts_0_wen,
  input  [5:0] io_archWritePorts_0_addr,
  input  [7:0] io_archWritePorts_0_data,
  input        io_archWritePorts_1_wen,
  input  [5:0] io_archWritePorts_1_addr,
  input  [7:0] io_archWritePorts_1_data,
  input        io_archWritePorts_2_wen,
  input  [5:0] io_archWritePorts_2_addr,
  input  [7:0] io_archWritePorts_2_data,
  input        io_archWritePorts_3_wen,
  input  [5:0] io_archWritePorts_3_addr,
  input  [7:0] io_archWritePorts_3_data,
  input        io_archWritePorts_4_wen,
  input  [5:0] io_archWritePorts_4_addr,
  input  [7:0] io_archWritePorts_4_data,
  input        io_archWritePorts_5_wen,
  input  [5:0] io_archWritePorts_5_addr,
  input  [7:0] io_archWritePorts_5_data,
  output [7:0] io_old_pdest_0,
  output [7:0] io_old_pdest_1,
  output [7:0] io_old_pdest_2,
  output [7:0] io_old_pdest_3,
  output [7:0] io_old_pdest_4,
  output [7:0] io_old_pdest_5,
  output       io_need_free_0,
  output       io_need_free_1,
  output       io_need_free_2,
  output       io_need_free_3,
  output       io_need_free_4,
  output       io_need_free_5,
  input        io_snpt_snptEnq,
  input        io_snpt_snptDeq,
  input        io_snpt_useSnpt,
  input  [1:0] io_snpt_snptSelect,
  input        io_snpt_flushVec_0,
  input        io_snpt_flushVec_1,
  input        io_snpt_flushVec_2,
  input        io_snpt_flushVec_3,
  output [7:0] io_diffRatBase_0,
  output [7:0] io_diffRatBase_1,
  output [7:0] io_diffRatBase_2,
  output [7:0] io_diffRatBase_3,
  output [7:0] io_diffRatBase_4,
  output [7:0] io_diffRatBase_5,
  output [7:0] io_diffRatBase_6,
  output [7:0] io_diffRatBase_7,
  output [7:0] io_diffRatBase_8,
  output [7:0] io_diffRatBase_9,
  output [7:0] io_diffRatBase_10,
  output [7:0] io_diffRatBase_11,
  output [7:0] io_diffRatBase_12,
  output [7:0] io_diffRatBase_13,
  output [7:0] io_diffRatBase_14,
  output [7:0] io_diffRatBase_15,
  output [7:0] io_diffRatBase_16,
  output [7:0] io_diffRatBase_17,
  output [7:0] io_diffRatBase_18,
  output [7:0] io_diffRatBase_19,
  output [7:0] io_diffRatBase_20,
  output [7:0] io_diffRatBase_21,
  output [7:0] io_diffRatBase_22,
  output [7:0] io_diffRatBase_23,
  output [7:0] io_diffRatBase_24,
  output [7:0] io_diffRatBase_25,
  output [7:0] io_diffRatBase_26,
  output [7:0] io_diffRatBase_27,
  output [7:0] io_diffRatBase_28,
  output [7:0] io_diffRatBase_29,
  output [7:0] io_diffRatBase_30,
  output [7:0] io_debug_rdata_0,
  output [7:0] io_debug_rdata_1,
  output [7:0] io_debug_rdata_2,
  output [7:0] io_debug_rdata_3,
  output [7:0] io_debug_rdata_4,
  output [7:0] io_debug_rdata_5,
  output [7:0] io_debug_rdata_6,
  output [7:0] io_debug_rdata_7,
  output [7:0] io_debug_rdata_8,
  output [7:0] io_debug_rdata_9,
  output [7:0] io_debug_rdata_10,
  output [7:0] io_debug_rdata_11,
  output [7:0] io_debug_rdata_12,
  output [7:0] io_debug_rdata_13,
  output [7:0] io_debug_rdata_14,
  output [7:0] io_debug_rdata_15,
  output [7:0] io_debug_rdata_16,
  output [7:0] io_debug_rdata_17,
  output [7:0] io_debug_rdata_18,
  output [7:0] io_debug_rdata_19,
  output [7:0] io_debug_rdata_20,
  output [7:0] io_debug_rdata_21,
  output [7:0] io_debug_rdata_22,
  output [7:0] io_debug_rdata_23,
  output [7:0] io_debug_rdata_24,
  output [7:0] io_debug_rdata_25,
  output [7:0] io_debug_rdata_26,
  output [7:0] io_debug_rdata_27,
  output [7:0] io_debug_rdata_28,
  output [7:0] io_debug_rdata_29,
  output [7:0] io_debug_rdata_30
);
  logic            rd_hold [18];
  logic [5:0]      rd_addr [18];
  logic [7:0]      rd_data [18];
  logic            sw_wen  [6];
  logic [5:0]      sw_addr [6];
  logic [7:0]      sw_data [6];
  logic            aw_wen  [6];
  logic [5:0]      aw_addr [6];
  logic [7:0]      aw_data [6];
  logic [7:0]      old_pdest [6];
  logic            need_free [6];
  logic [7:0]      diffRatBase [31];
  logic [7:0]      debug_rdata [31];
  logic [7:0]      debug_arch0;
  logic [7:0]      snpt_enq_data [47];
  logic            snpt_enq, snpt_deq, snpt_redirect;
  logic [3:0]      snpt_flush;
  logic [7:0]      snpt_rdata [4][47];

  assign rd_hold[0] = io_readPorts_0_hold;
  assign rd_addr[0] = io_readPorts_0_addr;
  assign rd_hold[1] = io_readPorts_1_hold;
  assign rd_addr[1] = io_readPorts_1_addr;
  assign rd_hold[2] = io_readPorts_2_hold;
  assign rd_addr[2] = io_readPorts_2_addr;
  assign rd_hold[3] = io_readPorts_3_hold;
  assign rd_addr[3] = io_readPorts_3_addr;
  assign rd_hold[4] = io_readPorts_4_hold;
  assign rd_addr[4] = io_readPorts_4_addr;
  assign rd_hold[5] = io_readPorts_5_hold;
  assign rd_addr[5] = io_readPorts_5_addr;
  assign rd_hold[6] = io_readPorts_6_hold;
  assign rd_addr[6] = io_readPorts_6_addr;
  assign rd_hold[7] = io_readPorts_7_hold;
  assign rd_addr[7] = io_readPorts_7_addr;
  assign rd_hold[8] = io_readPorts_8_hold;
  assign rd_addr[8] = io_readPorts_8_addr;
  assign rd_hold[9] = io_readPorts_9_hold;
  assign rd_addr[9] = io_readPorts_9_addr;
  assign rd_hold[10] = io_readPorts_10_hold;
  assign rd_addr[10] = io_readPorts_10_addr;
  assign rd_hold[11] = io_readPorts_11_hold;
  assign rd_addr[11] = io_readPorts_11_addr;
  assign rd_hold[12] = io_readPorts_12_hold;
  assign rd_addr[12] = io_readPorts_12_addr;
  assign rd_hold[13] = io_readPorts_13_hold;
  assign rd_addr[13] = io_readPorts_13_addr;
  assign rd_hold[14] = io_readPorts_14_hold;
  assign rd_addr[14] = io_readPorts_14_addr;
  assign rd_hold[15] = io_readPorts_15_hold;
  assign rd_addr[15] = io_readPorts_15_addr;
  assign rd_hold[16] = io_readPorts_16_hold;
  assign rd_addr[16] = io_readPorts_16_addr;
  assign rd_hold[17] = io_readPorts_17_hold;
  assign rd_addr[17] = io_readPorts_17_addr;
  assign sw_wen[0]  = io_specWritePorts_0_wen;
  assign sw_data[0] = io_specWritePorts_0_data;
  assign sw_addr[0] = io_specWritePorts_0_addr;
  assign aw_wen[0]  = io_archWritePorts_0_wen;
  assign aw_data[0] = io_archWritePorts_0_data;
  assign aw_addr[0] = io_archWritePorts_0_addr;
  assign sw_wen[1]  = io_specWritePorts_1_wen;
  assign sw_data[1] = io_specWritePorts_1_data;
  assign sw_addr[1] = io_specWritePorts_1_addr;
  assign aw_wen[1]  = io_archWritePorts_1_wen;
  assign aw_data[1] = io_archWritePorts_1_data;
  assign aw_addr[1] = io_archWritePorts_1_addr;
  assign sw_wen[2]  = io_specWritePorts_2_wen;
  assign sw_data[2] = io_specWritePorts_2_data;
  assign sw_addr[2] = io_specWritePorts_2_addr;
  assign aw_wen[2]  = io_archWritePorts_2_wen;
  assign aw_data[2] = io_archWritePorts_2_data;
  assign aw_addr[2] = io_archWritePorts_2_addr;
  assign sw_wen[3]  = io_specWritePorts_3_wen;
  assign sw_data[3] = io_specWritePorts_3_data;
  assign sw_addr[3] = io_specWritePorts_3_addr;
  assign aw_wen[3]  = io_archWritePorts_3_wen;
  assign aw_data[3] = io_archWritePorts_3_data;
  assign aw_addr[3] = io_archWritePorts_3_addr;
  assign sw_wen[4]  = io_specWritePorts_4_wen;
  assign sw_data[4] = io_specWritePorts_4_data;
  assign sw_addr[4] = io_specWritePorts_4_addr;
  assign aw_wen[4]  = io_archWritePorts_4_wen;
  assign aw_data[4] = io_archWritePorts_4_data;
  assign aw_addr[4] = io_archWritePorts_4_addr;
  assign sw_wen[5]  = io_specWritePorts_5_wen;
  assign sw_data[5] = io_specWritePorts_5_data;
  assign sw_addr[5] = io_specWritePorts_5_addr;
  assign aw_wen[5]  = io_archWritePorts_5_wen;
  assign aw_data[5] = io_archWritePorts_5_data;
  assign aw_addr[5] = io_archWritePorts_5_addr;

  assign io_readPorts_0_data = rd_data[0];
  assign io_readPorts_1_data = rd_data[1];
  assign io_readPorts_2_data = rd_data[2];
  assign io_readPorts_3_data = rd_data[3];
  assign io_readPorts_4_data = rd_data[4];
  assign io_readPorts_5_data = rd_data[5];
  assign io_readPorts_6_data = rd_data[6];
  assign io_readPorts_7_data = rd_data[7];
  assign io_readPorts_8_data = rd_data[8];
  assign io_readPorts_9_data = rd_data[9];
  assign io_readPorts_10_data = rd_data[10];
  assign io_readPorts_11_data = rd_data[11];
  assign io_readPorts_12_data = rd_data[12];
  assign io_readPorts_13_data = rd_data[13];
  assign io_readPorts_14_data = rd_data[14];
  assign io_readPorts_15_data = rd_data[15];
  assign io_readPorts_16_data = rd_data[16];
  assign io_readPorts_17_data = rd_data[17];
  assign io_old_pdest_0 = old_pdest[0];
  assign io_old_pdest_1 = old_pdest[1];
  assign io_old_pdest_2 = old_pdest[2];
  assign io_old_pdest_3 = old_pdest[3];
  assign io_old_pdest_4 = old_pdest[4];
  assign io_old_pdest_5 = old_pdest[5];
  assign io_need_free_0 = need_free[0];
  assign io_need_free_1 = need_free[1];
  assign io_need_free_2 = need_free[2];
  assign io_need_free_3 = need_free[3];
  assign io_need_free_4 = need_free[4];
  assign io_need_free_5 = need_free[5];
  assign io_diffRatBase_0 = diffRatBase[0];
  assign io_diffRatBase_1 = diffRatBase[1];
  assign io_diffRatBase_2 = diffRatBase[2];
  assign io_diffRatBase_3 = diffRatBase[3];
  assign io_diffRatBase_4 = diffRatBase[4];
  assign io_diffRatBase_5 = diffRatBase[5];
  assign io_diffRatBase_6 = diffRatBase[6];
  assign io_diffRatBase_7 = diffRatBase[7];
  assign io_diffRatBase_8 = diffRatBase[8];
  assign io_diffRatBase_9 = diffRatBase[9];
  assign io_diffRatBase_10 = diffRatBase[10];
  assign io_diffRatBase_11 = diffRatBase[11];
  assign io_diffRatBase_12 = diffRatBase[12];
  assign io_diffRatBase_13 = diffRatBase[13];
  assign io_diffRatBase_14 = diffRatBase[14];
  assign io_diffRatBase_15 = diffRatBase[15];
  assign io_diffRatBase_16 = diffRatBase[16];
  assign io_diffRatBase_17 = diffRatBase[17];
  assign io_diffRatBase_18 = diffRatBase[18];
  assign io_diffRatBase_19 = diffRatBase[19];
  assign io_diffRatBase_20 = diffRatBase[20];
  assign io_diffRatBase_21 = diffRatBase[21];
  assign io_diffRatBase_22 = diffRatBase[22];
  assign io_diffRatBase_23 = diffRatBase[23];
  assign io_diffRatBase_24 = diffRatBase[24];
  assign io_diffRatBase_25 = diffRatBase[25];
  assign io_diffRatBase_26 = diffRatBase[26];
  assign io_diffRatBase_27 = diffRatBase[27];
  assign io_diffRatBase_28 = diffRatBase[28];
  assign io_diffRatBase_29 = diffRatBase[29];
  assign io_diffRatBase_30 = diffRatBase[30];
  assign io_debug_rdata_0 = debug_rdata[0];
  assign io_debug_rdata_1 = debug_rdata[1];
  assign io_debug_rdata_2 = debug_rdata[2];
  assign io_debug_rdata_3 = debug_rdata[3];
  assign io_debug_rdata_4 = debug_rdata[4];
  assign io_debug_rdata_5 = debug_rdata[5];
  assign io_debug_rdata_6 = debug_rdata[6];
  assign io_debug_rdata_7 = debug_rdata[7];
  assign io_debug_rdata_8 = debug_rdata[8];
  assign io_debug_rdata_9 = debug_rdata[9];
  assign io_debug_rdata_10 = debug_rdata[10];
  assign io_debug_rdata_11 = debug_rdata[11];
  assign io_debug_rdata_12 = debug_rdata[12];
  assign io_debug_rdata_13 = debug_rdata[13];
  assign io_debug_rdata_14 = debug_rdata[14];
  assign io_debug_rdata_15 = debug_rdata[15];
  assign io_debug_rdata_16 = debug_rdata[16];
  assign io_debug_rdata_17 = debug_rdata[17];
  assign io_debug_rdata_18 = debug_rdata[18];
  assign io_debug_rdata_19 = debug_rdata[19];
  assign io_debug_rdata_20 = debug_rdata[20];
  assign io_debug_rdata_21 = debug_rdata[21];
  assign io_debug_rdata_22 = debug_rdata[22];
  assign io_debug_rdata_23 = debug_rdata[23];
  assign io_debug_rdata_24 = debug_rdata[24];
  assign io_debug_rdata_25 = debug_rdata[25];
  assign io_debug_rdata_26 = debug_rdata[26];
  assign io_debug_rdata_27 = debug_rdata[27];
  assign io_debug_rdata_28 = debug_rdata[28];
  assign io_debug_rdata_29 = debug_rdata[29];
  assign io_debug_rdata_30 = debug_rdata[30];

  xs_RenameTable_core #(
    .N_ENTRIES(47), .ADDR_W(6), .N_READ(18), .N_WRITE(6),
    .INIT_IDENTITY(1'b1), .DIFF_N(31), .DIFF_OFF(1),
    .DBG_N(31), .DBG_OFF(1),
    .HAS_NEED_FREE(1'b1), .HAS_DBG(1'b1)
  ) u_core (
    .clock                  (clock),
    .reset                  (reset),
    .io_redirect            (io_redirect),
    .io_readPorts_hold      (rd_hold),
    .io_readPorts_addr      (rd_addr),
    .io_readPorts_data      (rd_data),
    .io_specWritePorts_wen  (sw_wen),
    .io_specWritePorts_addr (sw_addr),
    .io_specWritePorts_data (sw_data),
    .io_archWritePorts_wen  (aw_wen),
    .io_archWritePorts_addr (aw_addr),
    .io_archWritePorts_data (aw_data),
    .io_old_pdest           (old_pdest),
    .io_need_free           (need_free),
    .io_snpt_snptEnq        (io_snpt_snptEnq),
    .io_snpt_snptDeq        (io_snpt_snptDeq),
    .io_snpt_useSnpt        (io_snpt_useSnpt),
    .io_snpt_snptSelect     (io_snpt_snptSelect),
    .io_snpt_flushVec       ({io_snpt_flushVec_3, io_snpt_flushVec_2,
                              io_snpt_flushVec_1, io_snpt_flushVec_0}),
    .io_diffRatBase         (diffRatBase),
    .io_debug_rdata         (debug_rdata),
    .io_debug_arch0         (debug_arch0),
    .snpt_enq_data          (snpt_enq_data),
    .snpt_enq               (snpt_enq),
    .snpt_deq               (snpt_deq),
    .snpt_redirect          (snpt_redirect),
    .snpt_flush             (snpt_flush),
    .snpt_rdata             (snpt_rdata)
  );

  // 实例名 snapshots_snapshotGen 与 golden 逐字一致：FM 按层次路径配对内部比对点。
  SnapshotGenerator_6 snapshots_snapshotGen (
    .clock       (clock),
    .reset       (reset),
    .io_enq      (snpt_enq),
    .io_enqData_0  (snpt_enq_data[0]),
    .io_enqData_1  (snpt_enq_data[1]),
    .io_enqData_2  (snpt_enq_data[2]),
    .io_enqData_3  (snpt_enq_data[3]),
    .io_enqData_4  (snpt_enq_data[4]),
    .io_enqData_5  (snpt_enq_data[5]),
    .io_enqData_6  (snpt_enq_data[6]),
    .io_enqData_7  (snpt_enq_data[7]),
    .io_enqData_8  (snpt_enq_data[8]),
    .io_enqData_9  (snpt_enq_data[9]),
    .io_enqData_10 (snpt_enq_data[10]),
    .io_enqData_11 (snpt_enq_data[11]),
    .io_enqData_12 (snpt_enq_data[12]),
    .io_enqData_13 (snpt_enq_data[13]),
    .io_enqData_14 (snpt_enq_data[14]),
    .io_enqData_15 (snpt_enq_data[15]),
    .io_enqData_16 (snpt_enq_data[16]),
    .io_enqData_17 (snpt_enq_data[17]),
    .io_enqData_18 (snpt_enq_data[18]),
    .io_enqData_19 (snpt_enq_data[19]),
    .io_enqData_20 (snpt_enq_data[20]),
    .io_enqData_21 (snpt_enq_data[21]),
    .io_enqData_22 (snpt_enq_data[22]),
    .io_enqData_23 (snpt_enq_data[23]),
    .io_enqData_24 (snpt_enq_data[24]),
    .io_enqData_25 (snpt_enq_data[25]),
    .io_enqData_26 (snpt_enq_data[26]),
    .io_enqData_27 (snpt_enq_data[27]),
    .io_enqData_28 (snpt_enq_data[28]),
    .io_enqData_29 (snpt_enq_data[29]),
    .io_enqData_30 (snpt_enq_data[30]),
    .io_enqData_31 (snpt_enq_data[31]),
    .io_enqData_32 (snpt_enq_data[32]),
    .io_enqData_33 (snpt_enq_data[33]),
    .io_enqData_34 (snpt_enq_data[34]),
    .io_enqData_35 (snpt_enq_data[35]),
    .io_enqData_36 (snpt_enq_data[36]),
    .io_enqData_37 (snpt_enq_data[37]),
    .io_enqData_38 (snpt_enq_data[38]),
    .io_enqData_39 (snpt_enq_data[39]),
    .io_enqData_40 (snpt_enq_data[40]),
    .io_enqData_41 (snpt_enq_data[41]),
    .io_enqData_42 (snpt_enq_data[42]),
    .io_enqData_43 (snpt_enq_data[43]),
    .io_enqData_44 (snpt_enq_data[44]),
    .io_enqData_45 (snpt_enq_data[45]),
    .io_enqData_46 (snpt_enq_data[46]),
    .io_deq      (snpt_deq),
    .io_redirect (snpt_redirect),
    .io_flushVec_0(snpt_flush[0]),
    .io_flushVec_1(snpt_flush[1]),
    .io_flushVec_2(snpt_flush[2]),
    .io_flushVec_3(snpt_flush[3]),
    .io_snapshots_0_0  (snpt_rdata[0][0]),
    .io_snapshots_0_1  (snpt_rdata[0][1]),
    .io_snapshots_0_2  (snpt_rdata[0][2]),
    .io_snapshots_0_3  (snpt_rdata[0][3]),
    .io_snapshots_0_4  (snpt_rdata[0][4]),
    .io_snapshots_0_5  (snpt_rdata[0][5]),
    .io_snapshots_0_6  (snpt_rdata[0][6]),
    .io_snapshots_0_7  (snpt_rdata[0][7]),
    .io_snapshots_0_8  (snpt_rdata[0][8]),
    .io_snapshots_0_9  (snpt_rdata[0][9]),
    .io_snapshots_0_10 (snpt_rdata[0][10]),
    .io_snapshots_0_11 (snpt_rdata[0][11]),
    .io_snapshots_0_12 (snpt_rdata[0][12]),
    .io_snapshots_0_13 (snpt_rdata[0][13]),
    .io_snapshots_0_14 (snpt_rdata[0][14]),
    .io_snapshots_0_15 (snpt_rdata[0][15]),
    .io_snapshots_0_16 (snpt_rdata[0][16]),
    .io_snapshots_0_17 (snpt_rdata[0][17]),
    .io_snapshots_0_18 (snpt_rdata[0][18]),
    .io_snapshots_0_19 (snpt_rdata[0][19]),
    .io_snapshots_0_20 (snpt_rdata[0][20]),
    .io_snapshots_0_21 (snpt_rdata[0][21]),
    .io_snapshots_0_22 (snpt_rdata[0][22]),
    .io_snapshots_0_23 (snpt_rdata[0][23]),
    .io_snapshots_0_24 (snpt_rdata[0][24]),
    .io_snapshots_0_25 (snpt_rdata[0][25]),
    .io_snapshots_0_26 (snpt_rdata[0][26]),
    .io_snapshots_0_27 (snpt_rdata[0][27]),
    .io_snapshots_0_28 (snpt_rdata[0][28]),
    .io_snapshots_0_29 (snpt_rdata[0][29]),
    .io_snapshots_0_30 (snpt_rdata[0][30]),
    .io_snapshots_0_31 (snpt_rdata[0][31]),
    .io_snapshots_0_32 (snpt_rdata[0][32]),
    .io_snapshots_0_33 (snpt_rdata[0][33]),
    .io_snapshots_0_34 (snpt_rdata[0][34]),
    .io_snapshots_0_35 (snpt_rdata[0][35]),
    .io_snapshots_0_36 (snpt_rdata[0][36]),
    .io_snapshots_0_37 (snpt_rdata[0][37]),
    .io_snapshots_0_38 (snpt_rdata[0][38]),
    .io_snapshots_0_39 (snpt_rdata[0][39]),
    .io_snapshots_0_40 (snpt_rdata[0][40]),
    .io_snapshots_0_41 (snpt_rdata[0][41]),
    .io_snapshots_0_42 (snpt_rdata[0][42]),
    .io_snapshots_0_43 (snpt_rdata[0][43]),
    .io_snapshots_0_44 (snpt_rdata[0][44]),
    .io_snapshots_0_45 (snpt_rdata[0][45]),
    .io_snapshots_0_46 (snpt_rdata[0][46]),
    .io_snapshots_1_0  (snpt_rdata[1][0]),
    .io_snapshots_1_1  (snpt_rdata[1][1]),
    .io_snapshots_1_2  (snpt_rdata[1][2]),
    .io_snapshots_1_3  (snpt_rdata[1][3]),
    .io_snapshots_1_4  (snpt_rdata[1][4]),
    .io_snapshots_1_5  (snpt_rdata[1][5]),
    .io_snapshots_1_6  (snpt_rdata[1][6]),
    .io_snapshots_1_7  (snpt_rdata[1][7]),
    .io_snapshots_1_8  (snpt_rdata[1][8]),
    .io_snapshots_1_9  (snpt_rdata[1][9]),
    .io_snapshots_1_10 (snpt_rdata[1][10]),
    .io_snapshots_1_11 (snpt_rdata[1][11]),
    .io_snapshots_1_12 (snpt_rdata[1][12]),
    .io_snapshots_1_13 (snpt_rdata[1][13]),
    .io_snapshots_1_14 (snpt_rdata[1][14]),
    .io_snapshots_1_15 (snpt_rdata[1][15]),
    .io_snapshots_1_16 (snpt_rdata[1][16]),
    .io_snapshots_1_17 (snpt_rdata[1][17]),
    .io_snapshots_1_18 (snpt_rdata[1][18]),
    .io_snapshots_1_19 (snpt_rdata[1][19]),
    .io_snapshots_1_20 (snpt_rdata[1][20]),
    .io_snapshots_1_21 (snpt_rdata[1][21]),
    .io_snapshots_1_22 (snpt_rdata[1][22]),
    .io_snapshots_1_23 (snpt_rdata[1][23]),
    .io_snapshots_1_24 (snpt_rdata[1][24]),
    .io_snapshots_1_25 (snpt_rdata[1][25]),
    .io_snapshots_1_26 (snpt_rdata[1][26]),
    .io_snapshots_1_27 (snpt_rdata[1][27]),
    .io_snapshots_1_28 (snpt_rdata[1][28]),
    .io_snapshots_1_29 (snpt_rdata[1][29]),
    .io_snapshots_1_30 (snpt_rdata[1][30]),
    .io_snapshots_1_31 (snpt_rdata[1][31]),
    .io_snapshots_1_32 (snpt_rdata[1][32]),
    .io_snapshots_1_33 (snpt_rdata[1][33]),
    .io_snapshots_1_34 (snpt_rdata[1][34]),
    .io_snapshots_1_35 (snpt_rdata[1][35]),
    .io_snapshots_1_36 (snpt_rdata[1][36]),
    .io_snapshots_1_37 (snpt_rdata[1][37]),
    .io_snapshots_1_38 (snpt_rdata[1][38]),
    .io_snapshots_1_39 (snpt_rdata[1][39]),
    .io_snapshots_1_40 (snpt_rdata[1][40]),
    .io_snapshots_1_41 (snpt_rdata[1][41]),
    .io_snapshots_1_42 (snpt_rdata[1][42]),
    .io_snapshots_1_43 (snpt_rdata[1][43]),
    .io_snapshots_1_44 (snpt_rdata[1][44]),
    .io_snapshots_1_45 (snpt_rdata[1][45]),
    .io_snapshots_1_46 (snpt_rdata[1][46]),
    .io_snapshots_2_0  (snpt_rdata[2][0]),
    .io_snapshots_2_1  (snpt_rdata[2][1]),
    .io_snapshots_2_2  (snpt_rdata[2][2]),
    .io_snapshots_2_3  (snpt_rdata[2][3]),
    .io_snapshots_2_4  (snpt_rdata[2][4]),
    .io_snapshots_2_5  (snpt_rdata[2][5]),
    .io_snapshots_2_6  (snpt_rdata[2][6]),
    .io_snapshots_2_7  (snpt_rdata[2][7]),
    .io_snapshots_2_8  (snpt_rdata[2][8]),
    .io_snapshots_2_9  (snpt_rdata[2][9]),
    .io_snapshots_2_10 (snpt_rdata[2][10]),
    .io_snapshots_2_11 (snpt_rdata[2][11]),
    .io_snapshots_2_12 (snpt_rdata[2][12]),
    .io_snapshots_2_13 (snpt_rdata[2][13]),
    .io_snapshots_2_14 (snpt_rdata[2][14]),
    .io_snapshots_2_15 (snpt_rdata[2][15]),
    .io_snapshots_2_16 (snpt_rdata[2][16]),
    .io_snapshots_2_17 (snpt_rdata[2][17]),
    .io_snapshots_2_18 (snpt_rdata[2][18]),
    .io_snapshots_2_19 (snpt_rdata[2][19]),
    .io_snapshots_2_20 (snpt_rdata[2][20]),
    .io_snapshots_2_21 (snpt_rdata[2][21]),
    .io_snapshots_2_22 (snpt_rdata[2][22]),
    .io_snapshots_2_23 (snpt_rdata[2][23]),
    .io_snapshots_2_24 (snpt_rdata[2][24]),
    .io_snapshots_2_25 (snpt_rdata[2][25]),
    .io_snapshots_2_26 (snpt_rdata[2][26]),
    .io_snapshots_2_27 (snpt_rdata[2][27]),
    .io_snapshots_2_28 (snpt_rdata[2][28]),
    .io_snapshots_2_29 (snpt_rdata[2][29]),
    .io_snapshots_2_30 (snpt_rdata[2][30]),
    .io_snapshots_2_31 (snpt_rdata[2][31]),
    .io_snapshots_2_32 (snpt_rdata[2][32]),
    .io_snapshots_2_33 (snpt_rdata[2][33]),
    .io_snapshots_2_34 (snpt_rdata[2][34]),
    .io_snapshots_2_35 (snpt_rdata[2][35]),
    .io_snapshots_2_36 (snpt_rdata[2][36]),
    .io_snapshots_2_37 (snpt_rdata[2][37]),
    .io_snapshots_2_38 (snpt_rdata[2][38]),
    .io_snapshots_2_39 (snpt_rdata[2][39]),
    .io_snapshots_2_40 (snpt_rdata[2][40]),
    .io_snapshots_2_41 (snpt_rdata[2][41]),
    .io_snapshots_2_42 (snpt_rdata[2][42]),
    .io_snapshots_2_43 (snpt_rdata[2][43]),
    .io_snapshots_2_44 (snpt_rdata[2][44]),
    .io_snapshots_2_45 (snpt_rdata[2][45]),
    .io_snapshots_2_46 (snpt_rdata[2][46]),
    .io_snapshots_3_0  (snpt_rdata[3][0]),
    .io_snapshots_3_1  (snpt_rdata[3][1]),
    .io_snapshots_3_2  (snpt_rdata[3][2]),
    .io_snapshots_3_3  (snpt_rdata[3][3]),
    .io_snapshots_3_4  (snpt_rdata[3][4]),
    .io_snapshots_3_5  (snpt_rdata[3][5]),
    .io_snapshots_3_6  (snpt_rdata[3][6]),
    .io_snapshots_3_7  (snpt_rdata[3][7]),
    .io_snapshots_3_8  (snpt_rdata[3][8]),
    .io_snapshots_3_9  (snpt_rdata[3][9]),
    .io_snapshots_3_10 (snpt_rdata[3][10]),
    .io_snapshots_3_11 (snpt_rdata[3][11]),
    .io_snapshots_3_12 (snpt_rdata[3][12]),
    .io_snapshots_3_13 (snpt_rdata[3][13]),
    .io_snapshots_3_14 (snpt_rdata[3][14]),
    .io_snapshots_3_15 (snpt_rdata[3][15]),
    .io_snapshots_3_16 (snpt_rdata[3][16]),
    .io_snapshots_3_17 (snpt_rdata[3][17]),
    .io_snapshots_3_18 (snpt_rdata[3][18]),
    .io_snapshots_3_19 (snpt_rdata[3][19]),
    .io_snapshots_3_20 (snpt_rdata[3][20]),
    .io_snapshots_3_21 (snpt_rdata[3][21]),
    .io_snapshots_3_22 (snpt_rdata[3][22]),
    .io_snapshots_3_23 (snpt_rdata[3][23]),
    .io_snapshots_3_24 (snpt_rdata[3][24]),
    .io_snapshots_3_25 (snpt_rdata[3][25]),
    .io_snapshots_3_26 (snpt_rdata[3][26]),
    .io_snapshots_3_27 (snpt_rdata[3][27]),
    .io_snapshots_3_28 (snpt_rdata[3][28]),
    .io_snapshots_3_29 (snpt_rdata[3][29]),
    .io_snapshots_3_30 (snpt_rdata[3][30]),
    .io_snapshots_3_31 (snpt_rdata[3][31]),
    .io_snapshots_3_32 (snpt_rdata[3][32]),
    .io_snapshots_3_33 (snpt_rdata[3][33]),
    .io_snapshots_3_34 (snpt_rdata[3][34]),
    .io_snapshots_3_35 (snpt_rdata[3][35]),
    .io_snapshots_3_36 (snpt_rdata[3][36]),
    .io_snapshots_3_37 (snpt_rdata[3][37]),
    .io_snapshots_3_38 (snpt_rdata[3][38]),
    .io_snapshots_3_39 (snpt_rdata[3][39]),
    .io_snapshots_3_40 (snpt_rdata[3][40]),
    .io_snapshots_3_41 (snpt_rdata[3][41]),
    .io_snapshots_3_42 (snpt_rdata[3][42]),
    .io_snapshots_3_43 (snpt_rdata[3][43]),
    .io_snapshots_3_44 (snpt_rdata[3][44]),
    .io_snapshots_3_45 (snpt_rdata[3][45]),
    .io_snapshots_3_46 (snpt_rdata[3][46])
  );
endmodule
