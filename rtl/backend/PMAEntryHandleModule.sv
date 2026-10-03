// PMAEntryHandleModule.sv — cross-entry PMA rules of NewCSR (32 entries).
// PMA (physical memory attributes) reuses the PMP entry format; cfg bits 6:5
// carry C (cacheable) and ATOMIC instead of being reserved.  This module
// supplies the legalised pmacfg write value and holds the pmaaddr registers
// with the same lock / grain rules as PMP.  CSR addresses (custom M-mode
// range): pmacfg0/2/4/6 = 0x7C0.., pmaaddr0..31 = 0x7C8...
// Unlike PMP the address registers do not reset to 0: they reset to the
// platform memory map (Scala PMAInit: PMAConfigs padded with empty entries
// and reversed, so the real regions occupy the highest-numbered entries).
// The table in the generated wrapper is read from golden.
// The logic is the shared xs_PmEntryHandle_core in
// rtl/backend/xs_PmEntryHandle_core.sv; this file is only the golden-named
// wrapper.

// BEGIN GENERATED(csr-irq-handle)
module PMAEntryHandleModule (
  input         clock,
  input         reset,
  input         io_in_wen,
  input         io_in_ren,
  input  [11:0] io_in_addr,
  input  [63:0] io_in_wdata,
  input         io_in_pmaCfg_0_R,
  input         io_in_pmaCfg_0_W,
  input         io_in_pmaCfg_0_X,
  input  [1:0]  io_in_pmaCfg_0_A,
  input         io_in_pmaCfg_0_L,
  input         io_in_pmaCfg_0_ATOMIC,
  input         io_in_pmaCfg_0_C,
  input         io_in_pmaCfg_1_R,
  input         io_in_pmaCfg_1_W,
  input         io_in_pmaCfg_1_X,
  input  [1:0]  io_in_pmaCfg_1_A,
  input         io_in_pmaCfg_1_L,
  input         io_in_pmaCfg_1_ATOMIC,
  input         io_in_pmaCfg_1_C,
  input         io_in_pmaCfg_2_R,
  input         io_in_pmaCfg_2_W,
  input         io_in_pmaCfg_2_X,
  input  [1:0]  io_in_pmaCfg_2_A,
  input         io_in_pmaCfg_2_L,
  input         io_in_pmaCfg_2_ATOMIC,
  input         io_in_pmaCfg_2_C,
  input         io_in_pmaCfg_3_R,
  input         io_in_pmaCfg_3_W,
  input         io_in_pmaCfg_3_X,
  input  [1:0]  io_in_pmaCfg_3_A,
  input         io_in_pmaCfg_3_L,
  input         io_in_pmaCfg_3_ATOMIC,
  input         io_in_pmaCfg_3_C,
  input         io_in_pmaCfg_4_R,
  input         io_in_pmaCfg_4_W,
  input         io_in_pmaCfg_4_X,
  input  [1:0]  io_in_pmaCfg_4_A,
  input         io_in_pmaCfg_4_L,
  input         io_in_pmaCfg_4_ATOMIC,
  input         io_in_pmaCfg_4_C,
  input         io_in_pmaCfg_5_R,
  input         io_in_pmaCfg_5_W,
  input         io_in_pmaCfg_5_X,
  input  [1:0]  io_in_pmaCfg_5_A,
  input         io_in_pmaCfg_5_L,
  input         io_in_pmaCfg_5_ATOMIC,
  input         io_in_pmaCfg_5_C,
  input         io_in_pmaCfg_6_R,
  input         io_in_pmaCfg_6_W,
  input         io_in_pmaCfg_6_X,
  input  [1:0]  io_in_pmaCfg_6_A,
  input         io_in_pmaCfg_6_L,
  input         io_in_pmaCfg_6_ATOMIC,
  input         io_in_pmaCfg_6_C,
  input         io_in_pmaCfg_7_R,
  input         io_in_pmaCfg_7_W,
  input         io_in_pmaCfg_7_X,
  input  [1:0]  io_in_pmaCfg_7_A,
  input         io_in_pmaCfg_7_L,
  input         io_in_pmaCfg_7_ATOMIC,
  input         io_in_pmaCfg_7_C,
  input         io_in_pmaCfg_8_R,
  input         io_in_pmaCfg_8_W,
  input         io_in_pmaCfg_8_X,
  input  [1:0]  io_in_pmaCfg_8_A,
  input         io_in_pmaCfg_8_L,
  input         io_in_pmaCfg_8_ATOMIC,
  input         io_in_pmaCfg_8_C,
  input         io_in_pmaCfg_9_R,
  input         io_in_pmaCfg_9_W,
  input         io_in_pmaCfg_9_X,
  input  [1:0]  io_in_pmaCfg_9_A,
  input         io_in_pmaCfg_9_L,
  input         io_in_pmaCfg_9_ATOMIC,
  input         io_in_pmaCfg_9_C,
  input         io_in_pmaCfg_10_R,
  input         io_in_pmaCfg_10_W,
  input         io_in_pmaCfg_10_X,
  input  [1:0]  io_in_pmaCfg_10_A,
  input         io_in_pmaCfg_10_L,
  input         io_in_pmaCfg_10_ATOMIC,
  input         io_in_pmaCfg_10_C,
  input         io_in_pmaCfg_11_R,
  input         io_in_pmaCfg_11_W,
  input         io_in_pmaCfg_11_X,
  input  [1:0]  io_in_pmaCfg_11_A,
  input         io_in_pmaCfg_11_L,
  input         io_in_pmaCfg_11_ATOMIC,
  input         io_in_pmaCfg_11_C,
  input         io_in_pmaCfg_12_R,
  input         io_in_pmaCfg_12_W,
  input         io_in_pmaCfg_12_X,
  input  [1:0]  io_in_pmaCfg_12_A,
  input         io_in_pmaCfg_12_L,
  input         io_in_pmaCfg_12_ATOMIC,
  input         io_in_pmaCfg_12_C,
  input         io_in_pmaCfg_13_R,
  input         io_in_pmaCfg_13_W,
  input         io_in_pmaCfg_13_X,
  input  [1:0]  io_in_pmaCfg_13_A,
  input         io_in_pmaCfg_13_L,
  input         io_in_pmaCfg_13_ATOMIC,
  input         io_in_pmaCfg_13_C,
  input         io_in_pmaCfg_14_R,
  input         io_in_pmaCfg_14_W,
  input         io_in_pmaCfg_14_X,
  input  [1:0]  io_in_pmaCfg_14_A,
  input         io_in_pmaCfg_14_L,
  input         io_in_pmaCfg_14_ATOMIC,
  input         io_in_pmaCfg_14_C,
  input         io_in_pmaCfg_15_R,
  input         io_in_pmaCfg_15_W,
  input         io_in_pmaCfg_15_X,
  input  [1:0]  io_in_pmaCfg_15_A,
  input         io_in_pmaCfg_15_L,
  input         io_in_pmaCfg_15_ATOMIC,
  input         io_in_pmaCfg_15_C,
  input         io_in_pmaCfg_16_R,
  input         io_in_pmaCfg_16_W,
  input         io_in_pmaCfg_16_X,
  input  [1:0]  io_in_pmaCfg_16_A,
  input         io_in_pmaCfg_16_L,
  input         io_in_pmaCfg_16_ATOMIC,
  input         io_in_pmaCfg_16_C,
  input         io_in_pmaCfg_17_R,
  input         io_in_pmaCfg_17_W,
  input         io_in_pmaCfg_17_X,
  input  [1:0]  io_in_pmaCfg_17_A,
  input         io_in_pmaCfg_17_L,
  input         io_in_pmaCfg_17_ATOMIC,
  input         io_in_pmaCfg_17_C,
  input         io_in_pmaCfg_18_R,
  input         io_in_pmaCfg_18_W,
  input         io_in_pmaCfg_18_X,
  input  [1:0]  io_in_pmaCfg_18_A,
  input         io_in_pmaCfg_18_L,
  input         io_in_pmaCfg_18_ATOMIC,
  input         io_in_pmaCfg_18_C,
  input         io_in_pmaCfg_19_R,
  input         io_in_pmaCfg_19_W,
  input         io_in_pmaCfg_19_X,
  input  [1:0]  io_in_pmaCfg_19_A,
  input         io_in_pmaCfg_19_L,
  input         io_in_pmaCfg_19_ATOMIC,
  input         io_in_pmaCfg_19_C,
  input         io_in_pmaCfg_20_R,
  input         io_in_pmaCfg_20_W,
  input         io_in_pmaCfg_20_X,
  input  [1:0]  io_in_pmaCfg_20_A,
  input         io_in_pmaCfg_20_L,
  input         io_in_pmaCfg_20_ATOMIC,
  input         io_in_pmaCfg_20_C,
  input         io_in_pmaCfg_21_R,
  input         io_in_pmaCfg_21_W,
  input         io_in_pmaCfg_21_X,
  input  [1:0]  io_in_pmaCfg_21_A,
  input         io_in_pmaCfg_21_L,
  input         io_in_pmaCfg_21_ATOMIC,
  input         io_in_pmaCfg_21_C,
  input         io_in_pmaCfg_22_R,
  input         io_in_pmaCfg_22_W,
  input         io_in_pmaCfg_22_X,
  input  [1:0]  io_in_pmaCfg_22_A,
  input         io_in_pmaCfg_22_L,
  input         io_in_pmaCfg_22_ATOMIC,
  input         io_in_pmaCfg_22_C,
  input         io_in_pmaCfg_23_R,
  input         io_in_pmaCfg_23_W,
  input         io_in_pmaCfg_23_X,
  input  [1:0]  io_in_pmaCfg_23_A,
  input         io_in_pmaCfg_23_L,
  input         io_in_pmaCfg_23_ATOMIC,
  input         io_in_pmaCfg_23_C,
  input         io_in_pmaCfg_24_R,
  input         io_in_pmaCfg_24_W,
  input         io_in_pmaCfg_24_X,
  input  [1:0]  io_in_pmaCfg_24_A,
  input         io_in_pmaCfg_24_L,
  input         io_in_pmaCfg_24_ATOMIC,
  input         io_in_pmaCfg_24_C,
  input         io_in_pmaCfg_25_R,
  input         io_in_pmaCfg_25_W,
  input         io_in_pmaCfg_25_X,
  input  [1:0]  io_in_pmaCfg_25_A,
  input         io_in_pmaCfg_25_L,
  input         io_in_pmaCfg_25_ATOMIC,
  input         io_in_pmaCfg_25_C,
  input         io_in_pmaCfg_26_R,
  input         io_in_pmaCfg_26_W,
  input         io_in_pmaCfg_26_X,
  input  [1:0]  io_in_pmaCfg_26_A,
  input         io_in_pmaCfg_26_L,
  input         io_in_pmaCfg_26_ATOMIC,
  input         io_in_pmaCfg_26_C,
  input         io_in_pmaCfg_27_R,
  input         io_in_pmaCfg_27_W,
  input         io_in_pmaCfg_27_X,
  input  [1:0]  io_in_pmaCfg_27_A,
  input         io_in_pmaCfg_27_L,
  input         io_in_pmaCfg_27_ATOMIC,
  input         io_in_pmaCfg_27_C,
  input         io_in_pmaCfg_28_R,
  input         io_in_pmaCfg_28_W,
  input         io_in_pmaCfg_28_X,
  input  [1:0]  io_in_pmaCfg_28_A,
  input         io_in_pmaCfg_28_L,
  input         io_in_pmaCfg_28_ATOMIC,
  input         io_in_pmaCfg_28_C,
  input         io_in_pmaCfg_29_R,
  input         io_in_pmaCfg_29_W,
  input         io_in_pmaCfg_29_X,
  input  [1:0]  io_in_pmaCfg_29_A,
  input         io_in_pmaCfg_29_L,
  input         io_in_pmaCfg_29_ATOMIC,
  input         io_in_pmaCfg_29_C,
  input         io_in_pmaCfg_30_R,
  input         io_in_pmaCfg_30_W,
  input         io_in_pmaCfg_30_X,
  input  [1:0]  io_in_pmaCfg_30_A,
  input         io_in_pmaCfg_30_L,
  input         io_in_pmaCfg_30_ATOMIC,
  input         io_in_pmaCfg_30_C,
  input         io_in_pmaCfg_31_R,
  input         io_in_pmaCfg_31_W,
  input         io_in_pmaCfg_31_X,
  input  [1:0]  io_in_pmaCfg_31_A,
  input         io_in_pmaCfg_31_L,
  input         io_in_pmaCfg_31_ATOMIC,
  input         io_in_pmaCfg_31_C,
  output [63:0] io_out_pmaCfgWdata,
  output [63:0] io_out_pmaAddrRData_0,
  output [63:0] io_out_pmaAddrRData_1,
  output [63:0] io_out_pmaAddrRData_2,
  output [63:0] io_out_pmaAddrRData_3,
  output [63:0] io_out_pmaAddrRData_4,
  output [63:0] io_out_pmaAddrRData_5,
  output [63:0] io_out_pmaAddrRData_6,
  output [63:0] io_out_pmaAddrRData_7,
  output [63:0] io_out_pmaAddrRData_8,
  output [63:0] io_out_pmaAddrRData_9,
  output [63:0] io_out_pmaAddrRData_10,
  output [63:0] io_out_pmaAddrRData_11,
  output [63:0] io_out_pmaAddrRData_12,
  output [63:0] io_out_pmaAddrRData_13,
  output [63:0] io_out_pmaAddrRData_14,
  output [63:0] io_out_pmaAddrRData_15,
  output [63:0] io_out_pmaAddrRData_16,
  output [63:0] io_out_pmaAddrRData_17,
  output [63:0] io_out_pmaAddrRData_18,
  output [63:0] io_out_pmaAddrRData_19,
  output [63:0] io_out_pmaAddrRData_20,
  output [63:0] io_out_pmaAddrRData_21,
  output [63:0] io_out_pmaAddrRData_22,
  output [63:0] io_out_pmaAddrRData_23,
  output [63:0] io_out_pmaAddrRData_24,
  output [63:0] io_out_pmaAddrRData_25,
  output [63:0] io_out_pmaAddrRData_26,
  output [63:0] io_out_pmaAddrRData_27,
  output [63:0] io_out_pmaAddrRData_28,
  output [63:0] io_out_pmaAddrRData_29,
  output [63:0] io_out_pmaAddrRData_30,
  output [63:0] io_out_pmaAddrRData_31
);
  // Current cfg byte of every entry: {L, bit6, bit5, A[1:0], X, W, R}.
  logic [31:0][7:0] old_cfg;
  assign old_cfg[0] = {io_in_pmaCfg_0_L, io_in_pmaCfg_0_C, io_in_pmaCfg_0_ATOMIC, io_in_pmaCfg_0_A, io_in_pmaCfg_0_X, io_in_pmaCfg_0_W, io_in_pmaCfg_0_R};
  assign old_cfg[1] = {io_in_pmaCfg_1_L, io_in_pmaCfg_1_C, io_in_pmaCfg_1_ATOMIC, io_in_pmaCfg_1_A, io_in_pmaCfg_1_X, io_in_pmaCfg_1_W, io_in_pmaCfg_1_R};
  assign old_cfg[2] = {io_in_pmaCfg_2_L, io_in_pmaCfg_2_C, io_in_pmaCfg_2_ATOMIC, io_in_pmaCfg_2_A, io_in_pmaCfg_2_X, io_in_pmaCfg_2_W, io_in_pmaCfg_2_R};
  assign old_cfg[3] = {io_in_pmaCfg_3_L, io_in_pmaCfg_3_C, io_in_pmaCfg_3_ATOMIC, io_in_pmaCfg_3_A, io_in_pmaCfg_3_X, io_in_pmaCfg_3_W, io_in_pmaCfg_3_R};
  assign old_cfg[4] = {io_in_pmaCfg_4_L, io_in_pmaCfg_4_C, io_in_pmaCfg_4_ATOMIC, io_in_pmaCfg_4_A, io_in_pmaCfg_4_X, io_in_pmaCfg_4_W, io_in_pmaCfg_4_R};
  assign old_cfg[5] = {io_in_pmaCfg_5_L, io_in_pmaCfg_5_C, io_in_pmaCfg_5_ATOMIC, io_in_pmaCfg_5_A, io_in_pmaCfg_5_X, io_in_pmaCfg_5_W, io_in_pmaCfg_5_R};
  assign old_cfg[6] = {io_in_pmaCfg_6_L, io_in_pmaCfg_6_C, io_in_pmaCfg_6_ATOMIC, io_in_pmaCfg_6_A, io_in_pmaCfg_6_X, io_in_pmaCfg_6_W, io_in_pmaCfg_6_R};
  assign old_cfg[7] = {io_in_pmaCfg_7_L, io_in_pmaCfg_7_C, io_in_pmaCfg_7_ATOMIC, io_in_pmaCfg_7_A, io_in_pmaCfg_7_X, io_in_pmaCfg_7_W, io_in_pmaCfg_7_R};
  assign old_cfg[8] = {io_in_pmaCfg_8_L, io_in_pmaCfg_8_C, io_in_pmaCfg_8_ATOMIC, io_in_pmaCfg_8_A, io_in_pmaCfg_8_X, io_in_pmaCfg_8_W, io_in_pmaCfg_8_R};
  assign old_cfg[9] = {io_in_pmaCfg_9_L, io_in_pmaCfg_9_C, io_in_pmaCfg_9_ATOMIC, io_in_pmaCfg_9_A, io_in_pmaCfg_9_X, io_in_pmaCfg_9_W, io_in_pmaCfg_9_R};
  assign old_cfg[10] = {io_in_pmaCfg_10_L, io_in_pmaCfg_10_C, io_in_pmaCfg_10_ATOMIC, io_in_pmaCfg_10_A, io_in_pmaCfg_10_X, io_in_pmaCfg_10_W, io_in_pmaCfg_10_R};
  assign old_cfg[11] = {io_in_pmaCfg_11_L, io_in_pmaCfg_11_C, io_in_pmaCfg_11_ATOMIC, io_in_pmaCfg_11_A, io_in_pmaCfg_11_X, io_in_pmaCfg_11_W, io_in_pmaCfg_11_R};
  assign old_cfg[12] = {io_in_pmaCfg_12_L, io_in_pmaCfg_12_C, io_in_pmaCfg_12_ATOMIC, io_in_pmaCfg_12_A, io_in_pmaCfg_12_X, io_in_pmaCfg_12_W, io_in_pmaCfg_12_R};
  assign old_cfg[13] = {io_in_pmaCfg_13_L, io_in_pmaCfg_13_C, io_in_pmaCfg_13_ATOMIC, io_in_pmaCfg_13_A, io_in_pmaCfg_13_X, io_in_pmaCfg_13_W, io_in_pmaCfg_13_R};
  assign old_cfg[14] = {io_in_pmaCfg_14_L, io_in_pmaCfg_14_C, io_in_pmaCfg_14_ATOMIC, io_in_pmaCfg_14_A, io_in_pmaCfg_14_X, io_in_pmaCfg_14_W, io_in_pmaCfg_14_R};
  assign old_cfg[15] = {io_in_pmaCfg_15_L, io_in_pmaCfg_15_C, io_in_pmaCfg_15_ATOMIC, io_in_pmaCfg_15_A, io_in_pmaCfg_15_X, io_in_pmaCfg_15_W, io_in_pmaCfg_15_R};
  assign old_cfg[16] = {io_in_pmaCfg_16_L, io_in_pmaCfg_16_C, io_in_pmaCfg_16_ATOMIC, io_in_pmaCfg_16_A, io_in_pmaCfg_16_X, io_in_pmaCfg_16_W, io_in_pmaCfg_16_R};
  assign old_cfg[17] = {io_in_pmaCfg_17_L, io_in_pmaCfg_17_C, io_in_pmaCfg_17_ATOMIC, io_in_pmaCfg_17_A, io_in_pmaCfg_17_X, io_in_pmaCfg_17_W, io_in_pmaCfg_17_R};
  assign old_cfg[18] = {io_in_pmaCfg_18_L, io_in_pmaCfg_18_C, io_in_pmaCfg_18_ATOMIC, io_in_pmaCfg_18_A, io_in_pmaCfg_18_X, io_in_pmaCfg_18_W, io_in_pmaCfg_18_R};
  assign old_cfg[19] = {io_in_pmaCfg_19_L, io_in_pmaCfg_19_C, io_in_pmaCfg_19_ATOMIC, io_in_pmaCfg_19_A, io_in_pmaCfg_19_X, io_in_pmaCfg_19_W, io_in_pmaCfg_19_R};
  assign old_cfg[20] = {io_in_pmaCfg_20_L, io_in_pmaCfg_20_C, io_in_pmaCfg_20_ATOMIC, io_in_pmaCfg_20_A, io_in_pmaCfg_20_X, io_in_pmaCfg_20_W, io_in_pmaCfg_20_R};
  assign old_cfg[21] = {io_in_pmaCfg_21_L, io_in_pmaCfg_21_C, io_in_pmaCfg_21_ATOMIC, io_in_pmaCfg_21_A, io_in_pmaCfg_21_X, io_in_pmaCfg_21_W, io_in_pmaCfg_21_R};
  assign old_cfg[22] = {io_in_pmaCfg_22_L, io_in_pmaCfg_22_C, io_in_pmaCfg_22_ATOMIC, io_in_pmaCfg_22_A, io_in_pmaCfg_22_X, io_in_pmaCfg_22_W, io_in_pmaCfg_22_R};
  assign old_cfg[23] = {io_in_pmaCfg_23_L, io_in_pmaCfg_23_C, io_in_pmaCfg_23_ATOMIC, io_in_pmaCfg_23_A, io_in_pmaCfg_23_X, io_in_pmaCfg_23_W, io_in_pmaCfg_23_R};
  assign old_cfg[24] = {io_in_pmaCfg_24_L, io_in_pmaCfg_24_C, io_in_pmaCfg_24_ATOMIC, io_in_pmaCfg_24_A, io_in_pmaCfg_24_X, io_in_pmaCfg_24_W, io_in_pmaCfg_24_R};
  assign old_cfg[25] = {io_in_pmaCfg_25_L, io_in_pmaCfg_25_C, io_in_pmaCfg_25_ATOMIC, io_in_pmaCfg_25_A, io_in_pmaCfg_25_X, io_in_pmaCfg_25_W, io_in_pmaCfg_25_R};
  assign old_cfg[26] = {io_in_pmaCfg_26_L, io_in_pmaCfg_26_C, io_in_pmaCfg_26_ATOMIC, io_in_pmaCfg_26_A, io_in_pmaCfg_26_X, io_in_pmaCfg_26_W, io_in_pmaCfg_26_R};
  assign old_cfg[27] = {io_in_pmaCfg_27_L, io_in_pmaCfg_27_C, io_in_pmaCfg_27_ATOMIC, io_in_pmaCfg_27_A, io_in_pmaCfg_27_X, io_in_pmaCfg_27_W, io_in_pmaCfg_27_R};
  assign old_cfg[28] = {io_in_pmaCfg_28_L, io_in_pmaCfg_28_C, io_in_pmaCfg_28_ATOMIC, io_in_pmaCfg_28_A, io_in_pmaCfg_28_X, io_in_pmaCfg_28_W, io_in_pmaCfg_28_R};
  assign old_cfg[29] = {io_in_pmaCfg_29_L, io_in_pmaCfg_29_C, io_in_pmaCfg_29_ATOMIC, io_in_pmaCfg_29_A, io_in_pmaCfg_29_X, io_in_pmaCfg_29_W, io_in_pmaCfg_29_R};
  assign old_cfg[30] = {io_in_pmaCfg_30_L, io_in_pmaCfg_30_C, io_in_pmaCfg_30_ATOMIC, io_in_pmaCfg_30_A, io_in_pmaCfg_30_X, io_in_pmaCfg_30_W, io_in_pmaCfg_30_R};
  assign old_cfg[31] = {io_in_pmaCfg_31_L, io_in_pmaCfg_31_C, io_in_pmaCfg_31_ATOMIC, io_in_pmaCfg_31_A, io_in_pmaCfg_31_X, io_in_pmaCfg_31_W, io_in_pmaCfg_31_R};
  logic [31:0][63:0] addr_rdata;

  // Address reset values, one per entry (entry 31 first).
  localparam logic [31:0][45:0] ADDR_RESET = {
    46'h1FFF_FFFF_FFFF,  // 31
    46'h0200_0000_0000,  // 30
    46'h0000_2000_0000,  // 29
    46'h0000_0E80_0000,  // 28
    46'h0000_0E40_0800,  // 27
    46'h0000_0E40_0000,  // 26
    46'h0000_0E00_8800,  // 25
    46'h0000_0E00_8400,  // 24
    46'h0000_0E00_8000,  // 23
    46'h0000_0C01_4000,  // 22
    46'h0000_0C00_4000,  // 21
    46'h0000_0800_0000,  // 20
    46'h0000_0400_0000,  // 19
    46'h0000_0000_0000,  // 18
    46'h0000_0000_0000,  // 17
    46'h0000_0000_0000,  // 16
    46'h0000_0000_0000,  // 15
    46'h0000_0000_0000,  // 14
    46'h0000_0000_0000,  // 13
    46'h0000_0000_0000,  // 12
    46'h0000_0000_0000,  // 11
    46'h0000_0000_0000,  // 10
    46'h0000_0000_0000,  // 9
    46'h0000_0000_0000,  // 8
    46'h0000_0000_0000,  // 7
    46'h0000_0000_0000,  // 6
    46'h0000_0000_0000,  // 5
    46'h0000_0000_0000,  // 4
    46'h0000_0000_0000,  // 3
    46'h0000_0000_0000,  // 2
    46'h0000_0000_0000,  // 1
    46'h0000_0000_0000   // 0
  };

  xs_PmEntryHandle_core #(
    .CFG_CSR_BASE (12'h7C0),
    .ADDR_CSR_BASE(12'h7C8),
    .ADDR_RESET   (ADDR_RESET)
  ) u_core (
    .clk       (clock),
    .rst       (reset),
    .wen       (io_in_wen),
    .ren       (io_in_ren),
    .csr_addr  (io_in_addr),
    .wdata     (io_in_wdata),
    .old_cfg   (old_cfg),
    .cfg_wdata (io_out_pmaCfgWdata),
    .addr_rdata(addr_rdata)
  );

  assign io_out_pmaAddrRData_0 = addr_rdata[0];
  assign io_out_pmaAddrRData_1 = addr_rdata[1];
  assign io_out_pmaAddrRData_2 = addr_rdata[2];
  assign io_out_pmaAddrRData_3 = addr_rdata[3];
  assign io_out_pmaAddrRData_4 = addr_rdata[4];
  assign io_out_pmaAddrRData_5 = addr_rdata[5];
  assign io_out_pmaAddrRData_6 = addr_rdata[6];
  assign io_out_pmaAddrRData_7 = addr_rdata[7];
  assign io_out_pmaAddrRData_8 = addr_rdata[8];
  assign io_out_pmaAddrRData_9 = addr_rdata[9];
  assign io_out_pmaAddrRData_10 = addr_rdata[10];
  assign io_out_pmaAddrRData_11 = addr_rdata[11];
  assign io_out_pmaAddrRData_12 = addr_rdata[12];
  assign io_out_pmaAddrRData_13 = addr_rdata[13];
  assign io_out_pmaAddrRData_14 = addr_rdata[14];
  assign io_out_pmaAddrRData_15 = addr_rdata[15];
  assign io_out_pmaAddrRData_16 = addr_rdata[16];
  assign io_out_pmaAddrRData_17 = addr_rdata[17];
  assign io_out_pmaAddrRData_18 = addr_rdata[18];
  assign io_out_pmaAddrRData_19 = addr_rdata[19];
  assign io_out_pmaAddrRData_20 = addr_rdata[20];
  assign io_out_pmaAddrRData_21 = addr_rdata[21];
  assign io_out_pmaAddrRData_22 = addr_rdata[22];
  assign io_out_pmaAddrRData_23 = addr_rdata[23];
  assign io_out_pmaAddrRData_24 = addr_rdata[24];
  assign io_out_pmaAddrRData_25 = addr_rdata[25];
  assign io_out_pmaAddrRData_26 = addr_rdata[26];
  assign io_out_pmaAddrRData_27 = addr_rdata[27];
  assign io_out_pmaAddrRData_28 = addr_rdata[28];
  assign io_out_pmaAddrRData_29 = addr_rdata[29];
  assign io_out_pmaAddrRData_30 = addr_rdata[30];
  assign io_out_pmaAddrRData_31 = addr_rdata[31];
endmodule
// END GENERATED
