// PMPEntryHandleModule.sv — cross-entry PMP rules of NewCSR (32 entries).
// The pmpcfg / pmpaddr CSR leaves each hold one entry; this module supplies
// what needs several entries at once: the legalised pmpcfg write value
// (lock, W&R, no NA4 at 4 KiB grain) and the pmpaddr registers themselves
// with their lock rule (own L, or next entry locked in TOR mode) and the
// grain-masked CSR read.  CSR addresses: pmpcfg0/2/4/6 = 0x3A0.., pmpaddr0..31
// = 0x3B0...  All addresses reset to 0.  Bits 6:5 of a cfg byte are reserved
// in PMP: golden has no ports for the old value (it is 0).
// The logic is the shared xs_PmEntryHandle_core in
// rtl/backend/xs_PmEntryHandle_core.sv; this file is only the golden-named
// wrapper, which packs the per-entry cfg ports into bytes.

// BEGIN GENERATED(csr-irq-handle)
module PMPEntryHandleModule (
  input         clock,
  input         reset,
  input         io_in_wen,
  input         io_in_ren,
  input  [11:0] io_in_addr,
  input  [63:0] io_in_wdata,
  input         io_in_pmpCfg_0_R,
  input         io_in_pmpCfg_0_W,
  input         io_in_pmpCfg_0_X,
  input  [1:0]  io_in_pmpCfg_0_A,
  input         io_in_pmpCfg_0_L,
  input         io_in_pmpCfg_1_R,
  input         io_in_pmpCfg_1_W,
  input         io_in_pmpCfg_1_X,
  input  [1:0]  io_in_pmpCfg_1_A,
  input         io_in_pmpCfg_1_L,
  input         io_in_pmpCfg_2_R,
  input         io_in_pmpCfg_2_W,
  input         io_in_pmpCfg_2_X,
  input  [1:0]  io_in_pmpCfg_2_A,
  input         io_in_pmpCfg_2_L,
  input         io_in_pmpCfg_3_R,
  input         io_in_pmpCfg_3_W,
  input         io_in_pmpCfg_3_X,
  input  [1:0]  io_in_pmpCfg_3_A,
  input         io_in_pmpCfg_3_L,
  input         io_in_pmpCfg_4_R,
  input         io_in_pmpCfg_4_W,
  input         io_in_pmpCfg_4_X,
  input  [1:0]  io_in_pmpCfg_4_A,
  input         io_in_pmpCfg_4_L,
  input         io_in_pmpCfg_5_R,
  input         io_in_pmpCfg_5_W,
  input         io_in_pmpCfg_5_X,
  input  [1:0]  io_in_pmpCfg_5_A,
  input         io_in_pmpCfg_5_L,
  input         io_in_pmpCfg_6_R,
  input         io_in_pmpCfg_6_W,
  input         io_in_pmpCfg_6_X,
  input  [1:0]  io_in_pmpCfg_6_A,
  input         io_in_pmpCfg_6_L,
  input         io_in_pmpCfg_7_R,
  input         io_in_pmpCfg_7_W,
  input         io_in_pmpCfg_7_X,
  input  [1:0]  io_in_pmpCfg_7_A,
  input         io_in_pmpCfg_7_L,
  input         io_in_pmpCfg_8_R,
  input         io_in_pmpCfg_8_W,
  input         io_in_pmpCfg_8_X,
  input  [1:0]  io_in_pmpCfg_8_A,
  input         io_in_pmpCfg_8_L,
  input         io_in_pmpCfg_9_R,
  input         io_in_pmpCfg_9_W,
  input         io_in_pmpCfg_9_X,
  input  [1:0]  io_in_pmpCfg_9_A,
  input         io_in_pmpCfg_9_L,
  input         io_in_pmpCfg_10_R,
  input         io_in_pmpCfg_10_W,
  input         io_in_pmpCfg_10_X,
  input  [1:0]  io_in_pmpCfg_10_A,
  input         io_in_pmpCfg_10_L,
  input         io_in_pmpCfg_11_R,
  input         io_in_pmpCfg_11_W,
  input         io_in_pmpCfg_11_X,
  input  [1:0]  io_in_pmpCfg_11_A,
  input         io_in_pmpCfg_11_L,
  input         io_in_pmpCfg_12_R,
  input         io_in_pmpCfg_12_W,
  input         io_in_pmpCfg_12_X,
  input  [1:0]  io_in_pmpCfg_12_A,
  input         io_in_pmpCfg_12_L,
  input         io_in_pmpCfg_13_R,
  input         io_in_pmpCfg_13_W,
  input         io_in_pmpCfg_13_X,
  input  [1:0]  io_in_pmpCfg_13_A,
  input         io_in_pmpCfg_13_L,
  input         io_in_pmpCfg_14_R,
  input         io_in_pmpCfg_14_W,
  input         io_in_pmpCfg_14_X,
  input  [1:0]  io_in_pmpCfg_14_A,
  input         io_in_pmpCfg_14_L,
  input         io_in_pmpCfg_15_R,
  input         io_in_pmpCfg_15_W,
  input         io_in_pmpCfg_15_X,
  input  [1:0]  io_in_pmpCfg_15_A,
  input         io_in_pmpCfg_15_L,
  input         io_in_pmpCfg_16_R,
  input         io_in_pmpCfg_16_W,
  input         io_in_pmpCfg_16_X,
  input  [1:0]  io_in_pmpCfg_16_A,
  input         io_in_pmpCfg_16_L,
  input         io_in_pmpCfg_17_R,
  input         io_in_pmpCfg_17_W,
  input         io_in_pmpCfg_17_X,
  input  [1:0]  io_in_pmpCfg_17_A,
  input         io_in_pmpCfg_17_L,
  input         io_in_pmpCfg_18_R,
  input         io_in_pmpCfg_18_W,
  input         io_in_pmpCfg_18_X,
  input  [1:0]  io_in_pmpCfg_18_A,
  input         io_in_pmpCfg_18_L,
  input         io_in_pmpCfg_19_R,
  input         io_in_pmpCfg_19_W,
  input         io_in_pmpCfg_19_X,
  input  [1:0]  io_in_pmpCfg_19_A,
  input         io_in_pmpCfg_19_L,
  input         io_in_pmpCfg_20_R,
  input         io_in_pmpCfg_20_W,
  input         io_in_pmpCfg_20_X,
  input  [1:0]  io_in_pmpCfg_20_A,
  input         io_in_pmpCfg_20_L,
  input         io_in_pmpCfg_21_R,
  input         io_in_pmpCfg_21_W,
  input         io_in_pmpCfg_21_X,
  input  [1:0]  io_in_pmpCfg_21_A,
  input         io_in_pmpCfg_21_L,
  input         io_in_pmpCfg_22_R,
  input         io_in_pmpCfg_22_W,
  input         io_in_pmpCfg_22_X,
  input  [1:0]  io_in_pmpCfg_22_A,
  input         io_in_pmpCfg_22_L,
  input         io_in_pmpCfg_23_R,
  input         io_in_pmpCfg_23_W,
  input         io_in_pmpCfg_23_X,
  input  [1:0]  io_in_pmpCfg_23_A,
  input         io_in_pmpCfg_23_L,
  input         io_in_pmpCfg_24_R,
  input         io_in_pmpCfg_24_W,
  input         io_in_pmpCfg_24_X,
  input  [1:0]  io_in_pmpCfg_24_A,
  input         io_in_pmpCfg_24_L,
  input         io_in_pmpCfg_25_R,
  input         io_in_pmpCfg_25_W,
  input         io_in_pmpCfg_25_X,
  input  [1:0]  io_in_pmpCfg_25_A,
  input         io_in_pmpCfg_25_L,
  input         io_in_pmpCfg_26_R,
  input         io_in_pmpCfg_26_W,
  input         io_in_pmpCfg_26_X,
  input  [1:0]  io_in_pmpCfg_26_A,
  input         io_in_pmpCfg_26_L,
  input         io_in_pmpCfg_27_R,
  input         io_in_pmpCfg_27_W,
  input         io_in_pmpCfg_27_X,
  input  [1:0]  io_in_pmpCfg_27_A,
  input         io_in_pmpCfg_27_L,
  input         io_in_pmpCfg_28_R,
  input         io_in_pmpCfg_28_W,
  input         io_in_pmpCfg_28_X,
  input  [1:0]  io_in_pmpCfg_28_A,
  input         io_in_pmpCfg_28_L,
  input         io_in_pmpCfg_29_R,
  input         io_in_pmpCfg_29_W,
  input         io_in_pmpCfg_29_X,
  input  [1:0]  io_in_pmpCfg_29_A,
  input         io_in_pmpCfg_29_L,
  input         io_in_pmpCfg_30_R,
  input         io_in_pmpCfg_30_W,
  input         io_in_pmpCfg_30_X,
  input  [1:0]  io_in_pmpCfg_30_A,
  input         io_in_pmpCfg_30_L,
  input         io_in_pmpCfg_31_R,
  input         io_in_pmpCfg_31_W,
  input         io_in_pmpCfg_31_X,
  input  [1:0]  io_in_pmpCfg_31_A,
  input         io_in_pmpCfg_31_L,
  output [63:0] io_out_pmpCfgWData,
  output [63:0] io_out_pmpAddrRData_0,
  output [63:0] io_out_pmpAddrRData_1,
  output [63:0] io_out_pmpAddrRData_2,
  output [63:0] io_out_pmpAddrRData_3,
  output [63:0] io_out_pmpAddrRData_4,
  output [63:0] io_out_pmpAddrRData_5,
  output [63:0] io_out_pmpAddrRData_6,
  output [63:0] io_out_pmpAddrRData_7,
  output [63:0] io_out_pmpAddrRData_8,
  output [63:0] io_out_pmpAddrRData_9,
  output [63:0] io_out_pmpAddrRData_10,
  output [63:0] io_out_pmpAddrRData_11,
  output [63:0] io_out_pmpAddrRData_12,
  output [63:0] io_out_pmpAddrRData_13,
  output [63:0] io_out_pmpAddrRData_14,
  output [63:0] io_out_pmpAddrRData_15,
  output [63:0] io_out_pmpAddrRData_16,
  output [63:0] io_out_pmpAddrRData_17,
  output [63:0] io_out_pmpAddrRData_18,
  output [63:0] io_out_pmpAddrRData_19,
  output [63:0] io_out_pmpAddrRData_20,
  output [63:0] io_out_pmpAddrRData_21,
  output [63:0] io_out_pmpAddrRData_22,
  output [63:0] io_out_pmpAddrRData_23,
  output [63:0] io_out_pmpAddrRData_24,
  output [63:0] io_out_pmpAddrRData_25,
  output [63:0] io_out_pmpAddrRData_26,
  output [63:0] io_out_pmpAddrRData_27,
  output [63:0] io_out_pmpAddrRData_28,
  output [63:0] io_out_pmpAddrRData_29,
  output [63:0] io_out_pmpAddrRData_30,
  output [63:0] io_out_pmpAddrRData_31
);
  // Current cfg byte of every entry: {L, bit6, bit5, A[1:0], X, W, R}.
  logic [31:0][7:0] old_cfg;
  assign old_cfg[0] = {io_in_pmpCfg_0_L, 1'b0, 1'b0, io_in_pmpCfg_0_A, io_in_pmpCfg_0_X, io_in_pmpCfg_0_W, io_in_pmpCfg_0_R};
  assign old_cfg[1] = {io_in_pmpCfg_1_L, 1'b0, 1'b0, io_in_pmpCfg_1_A, io_in_pmpCfg_1_X, io_in_pmpCfg_1_W, io_in_pmpCfg_1_R};
  assign old_cfg[2] = {io_in_pmpCfg_2_L, 1'b0, 1'b0, io_in_pmpCfg_2_A, io_in_pmpCfg_2_X, io_in_pmpCfg_2_W, io_in_pmpCfg_2_R};
  assign old_cfg[3] = {io_in_pmpCfg_3_L, 1'b0, 1'b0, io_in_pmpCfg_3_A, io_in_pmpCfg_3_X, io_in_pmpCfg_3_W, io_in_pmpCfg_3_R};
  assign old_cfg[4] = {io_in_pmpCfg_4_L, 1'b0, 1'b0, io_in_pmpCfg_4_A, io_in_pmpCfg_4_X, io_in_pmpCfg_4_W, io_in_pmpCfg_4_R};
  assign old_cfg[5] = {io_in_pmpCfg_5_L, 1'b0, 1'b0, io_in_pmpCfg_5_A, io_in_pmpCfg_5_X, io_in_pmpCfg_5_W, io_in_pmpCfg_5_R};
  assign old_cfg[6] = {io_in_pmpCfg_6_L, 1'b0, 1'b0, io_in_pmpCfg_6_A, io_in_pmpCfg_6_X, io_in_pmpCfg_6_W, io_in_pmpCfg_6_R};
  assign old_cfg[7] = {io_in_pmpCfg_7_L, 1'b0, 1'b0, io_in_pmpCfg_7_A, io_in_pmpCfg_7_X, io_in_pmpCfg_7_W, io_in_pmpCfg_7_R};
  assign old_cfg[8] = {io_in_pmpCfg_8_L, 1'b0, 1'b0, io_in_pmpCfg_8_A, io_in_pmpCfg_8_X, io_in_pmpCfg_8_W, io_in_pmpCfg_8_R};
  assign old_cfg[9] = {io_in_pmpCfg_9_L, 1'b0, 1'b0, io_in_pmpCfg_9_A, io_in_pmpCfg_9_X, io_in_pmpCfg_9_W, io_in_pmpCfg_9_R};
  assign old_cfg[10] = {io_in_pmpCfg_10_L, 1'b0, 1'b0, io_in_pmpCfg_10_A, io_in_pmpCfg_10_X, io_in_pmpCfg_10_W, io_in_pmpCfg_10_R};
  assign old_cfg[11] = {io_in_pmpCfg_11_L, 1'b0, 1'b0, io_in_pmpCfg_11_A, io_in_pmpCfg_11_X, io_in_pmpCfg_11_W, io_in_pmpCfg_11_R};
  assign old_cfg[12] = {io_in_pmpCfg_12_L, 1'b0, 1'b0, io_in_pmpCfg_12_A, io_in_pmpCfg_12_X, io_in_pmpCfg_12_W, io_in_pmpCfg_12_R};
  assign old_cfg[13] = {io_in_pmpCfg_13_L, 1'b0, 1'b0, io_in_pmpCfg_13_A, io_in_pmpCfg_13_X, io_in_pmpCfg_13_W, io_in_pmpCfg_13_R};
  assign old_cfg[14] = {io_in_pmpCfg_14_L, 1'b0, 1'b0, io_in_pmpCfg_14_A, io_in_pmpCfg_14_X, io_in_pmpCfg_14_W, io_in_pmpCfg_14_R};
  assign old_cfg[15] = {io_in_pmpCfg_15_L, 1'b0, 1'b0, io_in_pmpCfg_15_A, io_in_pmpCfg_15_X, io_in_pmpCfg_15_W, io_in_pmpCfg_15_R};
  assign old_cfg[16] = {io_in_pmpCfg_16_L, 1'b0, 1'b0, io_in_pmpCfg_16_A, io_in_pmpCfg_16_X, io_in_pmpCfg_16_W, io_in_pmpCfg_16_R};
  assign old_cfg[17] = {io_in_pmpCfg_17_L, 1'b0, 1'b0, io_in_pmpCfg_17_A, io_in_pmpCfg_17_X, io_in_pmpCfg_17_W, io_in_pmpCfg_17_R};
  assign old_cfg[18] = {io_in_pmpCfg_18_L, 1'b0, 1'b0, io_in_pmpCfg_18_A, io_in_pmpCfg_18_X, io_in_pmpCfg_18_W, io_in_pmpCfg_18_R};
  assign old_cfg[19] = {io_in_pmpCfg_19_L, 1'b0, 1'b0, io_in_pmpCfg_19_A, io_in_pmpCfg_19_X, io_in_pmpCfg_19_W, io_in_pmpCfg_19_R};
  assign old_cfg[20] = {io_in_pmpCfg_20_L, 1'b0, 1'b0, io_in_pmpCfg_20_A, io_in_pmpCfg_20_X, io_in_pmpCfg_20_W, io_in_pmpCfg_20_R};
  assign old_cfg[21] = {io_in_pmpCfg_21_L, 1'b0, 1'b0, io_in_pmpCfg_21_A, io_in_pmpCfg_21_X, io_in_pmpCfg_21_W, io_in_pmpCfg_21_R};
  assign old_cfg[22] = {io_in_pmpCfg_22_L, 1'b0, 1'b0, io_in_pmpCfg_22_A, io_in_pmpCfg_22_X, io_in_pmpCfg_22_W, io_in_pmpCfg_22_R};
  assign old_cfg[23] = {io_in_pmpCfg_23_L, 1'b0, 1'b0, io_in_pmpCfg_23_A, io_in_pmpCfg_23_X, io_in_pmpCfg_23_W, io_in_pmpCfg_23_R};
  assign old_cfg[24] = {io_in_pmpCfg_24_L, 1'b0, 1'b0, io_in_pmpCfg_24_A, io_in_pmpCfg_24_X, io_in_pmpCfg_24_W, io_in_pmpCfg_24_R};
  assign old_cfg[25] = {io_in_pmpCfg_25_L, 1'b0, 1'b0, io_in_pmpCfg_25_A, io_in_pmpCfg_25_X, io_in_pmpCfg_25_W, io_in_pmpCfg_25_R};
  assign old_cfg[26] = {io_in_pmpCfg_26_L, 1'b0, 1'b0, io_in_pmpCfg_26_A, io_in_pmpCfg_26_X, io_in_pmpCfg_26_W, io_in_pmpCfg_26_R};
  assign old_cfg[27] = {io_in_pmpCfg_27_L, 1'b0, 1'b0, io_in_pmpCfg_27_A, io_in_pmpCfg_27_X, io_in_pmpCfg_27_W, io_in_pmpCfg_27_R};
  assign old_cfg[28] = {io_in_pmpCfg_28_L, 1'b0, 1'b0, io_in_pmpCfg_28_A, io_in_pmpCfg_28_X, io_in_pmpCfg_28_W, io_in_pmpCfg_28_R};
  assign old_cfg[29] = {io_in_pmpCfg_29_L, 1'b0, 1'b0, io_in_pmpCfg_29_A, io_in_pmpCfg_29_X, io_in_pmpCfg_29_W, io_in_pmpCfg_29_R};
  assign old_cfg[30] = {io_in_pmpCfg_30_L, 1'b0, 1'b0, io_in_pmpCfg_30_A, io_in_pmpCfg_30_X, io_in_pmpCfg_30_W, io_in_pmpCfg_30_R};
  assign old_cfg[31] = {io_in_pmpCfg_31_L, 1'b0, 1'b0, io_in_pmpCfg_31_A, io_in_pmpCfg_31_X, io_in_pmpCfg_31_W, io_in_pmpCfg_31_R};
  logic [31:0][63:0] addr_rdata;

  // Address reset values, one per entry (entry 31 first).
  localparam logic [31:0][45:0] ADDR_RESET = {
    46'h0000_0000_0000,  // 31
    46'h0000_0000_0000,  // 30
    46'h0000_0000_0000,  // 29
    46'h0000_0000_0000,  // 28
    46'h0000_0000_0000,  // 27
    46'h0000_0000_0000,  // 26
    46'h0000_0000_0000,  // 25
    46'h0000_0000_0000,  // 24
    46'h0000_0000_0000,  // 23
    46'h0000_0000_0000,  // 22
    46'h0000_0000_0000,  // 21
    46'h0000_0000_0000,  // 20
    46'h0000_0000_0000,  // 19
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
    .CFG_CSR_BASE (12'h3A0),
    .ADDR_CSR_BASE(12'h3B0),
    .ADDR_RESET   (ADDR_RESET)
  ) u_core (
    .clk       (clock),
    .rst       (reset),
    .wen       (io_in_wen),
    .ren       (io_in_ren),
    .csr_addr  (io_in_addr),
    .wdata     (io_in_wdata),
    .old_cfg   (old_cfg),
    .cfg_wdata (io_out_pmpCfgWData),
    .addr_rdata(addr_rdata)
  );

  assign io_out_pmpAddrRData_0 = addr_rdata[0];
  assign io_out_pmpAddrRData_1 = addr_rdata[1];
  assign io_out_pmpAddrRData_2 = addr_rdata[2];
  assign io_out_pmpAddrRData_3 = addr_rdata[3];
  assign io_out_pmpAddrRData_4 = addr_rdata[4];
  assign io_out_pmpAddrRData_5 = addr_rdata[5];
  assign io_out_pmpAddrRData_6 = addr_rdata[6];
  assign io_out_pmpAddrRData_7 = addr_rdata[7];
  assign io_out_pmpAddrRData_8 = addr_rdata[8];
  assign io_out_pmpAddrRData_9 = addr_rdata[9];
  assign io_out_pmpAddrRData_10 = addr_rdata[10];
  assign io_out_pmpAddrRData_11 = addr_rdata[11];
  assign io_out_pmpAddrRData_12 = addr_rdata[12];
  assign io_out_pmpAddrRData_13 = addr_rdata[13];
  assign io_out_pmpAddrRData_14 = addr_rdata[14];
  assign io_out_pmpAddrRData_15 = addr_rdata[15];
  assign io_out_pmpAddrRData_16 = addr_rdata[16];
  assign io_out_pmpAddrRData_17 = addr_rdata[17];
  assign io_out_pmpAddrRData_18 = addr_rdata[18];
  assign io_out_pmpAddrRData_19 = addr_rdata[19];
  assign io_out_pmpAddrRData_20 = addr_rdata[20];
  assign io_out_pmpAddrRData_21 = addr_rdata[21];
  assign io_out_pmpAddrRData_22 = addr_rdata[22];
  assign io_out_pmpAddrRData_23 = addr_rdata[23];
  assign io_out_pmpAddrRData_24 = addr_rdata[24];
  assign io_out_pmpAddrRData_25 = addr_rdata[25];
  assign io_out_pmpAddrRData_26 = addr_rdata[26];
  assign io_out_pmpAddrRData_27 = addr_rdata[27];
  assign io_out_pmpAddrRData_28 = addr_rdata[28];
  assign io_out_pmpAddrRData_29 = addr_rdata[29];
  assign io_out_pmpAddrRData_30 = addr_rdata[30];
  assign io_out_pmpAddrRData_31 = addr_rdata[31];
endmodule
// END GENERATED
