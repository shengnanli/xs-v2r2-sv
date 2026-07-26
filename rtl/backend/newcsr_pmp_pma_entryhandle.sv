// NewCSR PMP/PMA entry-handle modules — readable transcriptions.
//
// PMPEntryHandleModule / PMAEntryHandleModule perform the cross-entry WARL
// legalization of a PMP/PMA config or address write: they decode the target CSR
// address, apply the lock (L / locked-neighbour) and NAPOT/TOR grain rules, and
// produce the legalized packed cfg/addr write buses that feed the per-entry
// Pmp*cfg/Pmpaddr* (resp. Pma*) registers. Combinational (PMP) / 16 addr regs
// (PMA). The readable rewrite drops the sim randomize-init block and renames the
// CIRCT address-decode wires: wenCfg0/wenCfg2 (write to pmp/pmacfg0/2) and
// addrEntry0..15 (write-address matches the N-th entry). FM-verified strict
// golden-vs-impl SUCCEEDED, no black box, no dont_verify.


module PMPEntryHandleModule(
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
  input  [45:0] io_in_pmpAddr_0_ADDRESS,
  input  [45:0] io_in_pmpAddr_1_ADDRESS,
  input  [45:0] io_in_pmpAddr_2_ADDRESS,
  input  [45:0] io_in_pmpAddr_3_ADDRESS,
  input  [45:0] io_in_pmpAddr_4_ADDRESS,
  input  [45:0] io_in_pmpAddr_5_ADDRESS,
  input  [45:0] io_in_pmpAddr_6_ADDRESS,
  input  [45:0] io_in_pmpAddr_7_ADDRESS,
  input  [45:0] io_in_pmpAddr_8_ADDRESS,
  input  [45:0] io_in_pmpAddr_9_ADDRESS,
  input  [45:0] io_in_pmpAddr_10_ADDRESS,
  input  [45:0] io_in_pmpAddr_11_ADDRESS,
  input  [45:0] io_in_pmpAddr_12_ADDRESS,
  input  [45:0] io_in_pmpAddr_13_ADDRESS,
  input  [45:0] io_in_pmpAddr_14_ADDRESS,
  input  [45:0] io_in_pmpAddr_15_ADDRESS,
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
  output [63:0] io_out_pmpAddrWData_0,
  output [63:0] io_out_pmpAddrWData_1,
  output [63:0] io_out_pmpAddrWData_2,
  output [63:0] io_out_pmpAddrWData_3,
  output [63:0] io_out_pmpAddrWData_4,
  output [63:0] io_out_pmpAddrWData_5,
  output [63:0] io_out_pmpAddrWData_6,
  output [63:0] io_out_pmpAddrWData_7,
  output [63:0] io_out_pmpAddrWData_8,
  output [63:0] io_out_pmpAddrWData_9,
  output [63:0] io_out_pmpAddrWData_10,
  output [63:0] io_out_pmpAddrWData_11,
  output [63:0] io_out_pmpAddrWData_12,
  output [63:0] io_out_pmpAddrWData_13,
  output [63:0] io_out_pmpAddrWData_14,
  output [63:0] io_out_pmpAddrWData_15
);

  wire wenCfg0 = io_in_wen & io_in_addr == 12'h3A0;
  wire wenCfg2 = io_in_wen & io_in_addr == 12'h3A2;
  wire addrEntry0 = io_in_addr == 12'h3B0;
  wire addrEntry1 = io_in_addr == 12'h3B1;
  wire addrEntry2 = io_in_addr == 12'h3B2;
  wire addrEntry3 = io_in_addr == 12'h3B3;
  wire addrEntry4 = io_in_addr == 12'h3B4;
  wire addrEntry5 = io_in_addr == 12'h3B5;
  wire addrEntry6 = io_in_addr == 12'h3B6;
  wire addrEntry7 = io_in_addr == 12'h3B7;
  wire addrEntry8 = io_in_addr == 12'h3B8;
  wire addrEntry9 = io_in_addr == 12'h3B9;
  wire addrEntry10 = io_in_addr == 12'h3BA;
  wire addrEntry11 = io_in_addr == 12'h3BB;
  wire addrEntry12 = io_in_addr == 12'h3BC;
  wire addrEntry13 = io_in_addr == 12'h3BD;
  wire addrEntry14 = io_in_addr == 12'h3BE;
  wire addrEntry15 = io_in_addr == 12'h3BF;
  assign io_out_pmpCfgWData =
    {wenCfg2
       ? (io_in_pmpCfg_15_L ? io_in_pmpCfg_15_L : io_in_wdata[63])
       : wenCfg0 & (io_in_pmpCfg_7_L ? io_in_pmpCfg_7_L : io_in_wdata[63]),
     wenCfg2
       ? ~io_in_pmpCfg_15_L & io_in_wdata[62]
       : wenCfg0 & ~io_in_pmpCfg_7_L & io_in_wdata[62],
     wenCfg2
       ? ~io_in_pmpCfg_15_L & io_in_wdata[61]
       : wenCfg0 & ~io_in_pmpCfg_7_L & io_in_wdata[61],
     wenCfg2
       ? (io_in_pmpCfg_15_L
            ? io_in_pmpCfg_15_A
            : {io_in_wdata[60], |(io_in_wdata[60:59])})
       : wenCfg0
           ? (io_in_pmpCfg_7_L
                ? io_in_pmpCfg_7_A
                : {io_in_wdata[60], |(io_in_wdata[60:59])})
           : 2'h0,
     wenCfg2
       ? (io_in_pmpCfg_15_L ? io_in_pmpCfg_15_X : io_in_wdata[58])
       : wenCfg0 & (io_in_pmpCfg_7_L ? io_in_pmpCfg_7_X : io_in_wdata[58]),
     wenCfg2
       ? (io_in_pmpCfg_15_L ? io_in_pmpCfg_15_W : io_in_wdata[57] & io_in_wdata[56])
       : wenCfg0 & (io_in_pmpCfg_7_L ? io_in_pmpCfg_7_W : io_in_wdata[57] & io_in_wdata[56]),
     wenCfg2
       ? (io_in_pmpCfg_15_L ? io_in_pmpCfg_15_R : io_in_wdata[56])
       : wenCfg0 & (io_in_pmpCfg_7_L ? io_in_pmpCfg_7_R : io_in_wdata[56]),
     wenCfg2
       ? (io_in_pmpCfg_14_L ? io_in_pmpCfg_14_L : io_in_wdata[55])
       : wenCfg0 & (io_in_pmpCfg_6_L ? io_in_pmpCfg_6_L : io_in_wdata[55]),
     wenCfg2
       ? ~io_in_pmpCfg_14_L & io_in_wdata[54]
       : wenCfg0 & ~io_in_pmpCfg_6_L & io_in_wdata[54],
     wenCfg2
       ? ~io_in_pmpCfg_14_L & io_in_wdata[53]
       : wenCfg0 & ~io_in_pmpCfg_6_L & io_in_wdata[53],
     wenCfg2
       ? (io_in_pmpCfg_14_L
            ? io_in_pmpCfg_14_A
            : {io_in_wdata[52], |(io_in_wdata[52:51])})
       : wenCfg0
           ? (io_in_pmpCfg_6_L
                ? io_in_pmpCfg_6_A
                : {io_in_wdata[52], |(io_in_wdata[52:51])})
           : 2'h0,
     wenCfg2
       ? (io_in_pmpCfg_14_L ? io_in_pmpCfg_14_X : io_in_wdata[50])
       : wenCfg0 & (io_in_pmpCfg_6_L ? io_in_pmpCfg_6_X : io_in_wdata[50]),
     wenCfg2
       ? (io_in_pmpCfg_14_L ? io_in_pmpCfg_14_W : io_in_wdata[49] & io_in_wdata[48])
       : wenCfg0 & (io_in_pmpCfg_6_L ? io_in_pmpCfg_6_W : io_in_wdata[49] & io_in_wdata[48]),
     wenCfg2
       ? (io_in_pmpCfg_14_L ? io_in_pmpCfg_14_R : io_in_wdata[48])
       : wenCfg0 & (io_in_pmpCfg_6_L ? io_in_pmpCfg_6_R : io_in_wdata[48]),
     wenCfg2
       ? (io_in_pmpCfg_13_L ? io_in_pmpCfg_13_L : io_in_wdata[47])
       : wenCfg0 & (io_in_pmpCfg_5_L ? io_in_pmpCfg_5_L : io_in_wdata[47]),
     wenCfg2
       ? ~io_in_pmpCfg_13_L & io_in_wdata[46]
       : wenCfg0 & ~io_in_pmpCfg_5_L & io_in_wdata[46],
     wenCfg2
       ? ~io_in_pmpCfg_13_L & io_in_wdata[45]
       : wenCfg0 & ~io_in_pmpCfg_5_L & io_in_wdata[45],
     wenCfg2
       ? (io_in_pmpCfg_13_L
            ? io_in_pmpCfg_13_A
            : {io_in_wdata[44], |(io_in_wdata[44:43])})
       : wenCfg0
           ? (io_in_pmpCfg_5_L
                ? io_in_pmpCfg_5_A
                : {io_in_wdata[44], |(io_in_wdata[44:43])})
           : 2'h0,
     wenCfg2
       ? (io_in_pmpCfg_13_L ? io_in_pmpCfg_13_X : io_in_wdata[42])
       : wenCfg0 & (io_in_pmpCfg_5_L ? io_in_pmpCfg_5_X : io_in_wdata[42]),
     wenCfg2
       ? (io_in_pmpCfg_13_L ? io_in_pmpCfg_13_W : io_in_wdata[41] & io_in_wdata[40])
       : wenCfg0 & (io_in_pmpCfg_5_L ? io_in_pmpCfg_5_W : io_in_wdata[41] & io_in_wdata[40]),
     wenCfg2
       ? (io_in_pmpCfg_13_L ? io_in_pmpCfg_13_R : io_in_wdata[40])
       : wenCfg0 & (io_in_pmpCfg_5_L ? io_in_pmpCfg_5_R : io_in_wdata[40]),
     wenCfg2
       ? (io_in_pmpCfg_12_L ? io_in_pmpCfg_12_L : io_in_wdata[39])
       : wenCfg0 & (io_in_pmpCfg_4_L ? io_in_pmpCfg_4_L : io_in_wdata[39]),
     wenCfg2
       ? ~io_in_pmpCfg_12_L & io_in_wdata[38]
       : wenCfg0 & ~io_in_pmpCfg_4_L & io_in_wdata[38],
     wenCfg2
       ? ~io_in_pmpCfg_12_L & io_in_wdata[37]
       : wenCfg0 & ~io_in_pmpCfg_4_L & io_in_wdata[37],
     wenCfg2
       ? (io_in_pmpCfg_12_L
            ? io_in_pmpCfg_12_A
            : {io_in_wdata[36], |(io_in_wdata[36:35])})
       : wenCfg0
           ? (io_in_pmpCfg_4_L
                ? io_in_pmpCfg_4_A
                : {io_in_wdata[36], |(io_in_wdata[36:35])})
           : 2'h0,
     wenCfg2
       ? (io_in_pmpCfg_12_L ? io_in_pmpCfg_12_X : io_in_wdata[34])
       : wenCfg0 & (io_in_pmpCfg_4_L ? io_in_pmpCfg_4_X : io_in_wdata[34]),
     wenCfg2
       ? (io_in_pmpCfg_12_L ? io_in_pmpCfg_12_W : io_in_wdata[33] & io_in_wdata[32])
       : wenCfg0 & (io_in_pmpCfg_4_L ? io_in_pmpCfg_4_W : io_in_wdata[33] & io_in_wdata[32]),
     wenCfg2
       ? (io_in_pmpCfg_12_L ? io_in_pmpCfg_12_R : io_in_wdata[32])
       : wenCfg0 & (io_in_pmpCfg_4_L ? io_in_pmpCfg_4_R : io_in_wdata[32]),
     wenCfg2
       ? (io_in_pmpCfg_11_L ? io_in_pmpCfg_11_L : io_in_wdata[31])
       : wenCfg0 & (io_in_pmpCfg_3_L ? io_in_pmpCfg_3_L : io_in_wdata[31]),
     wenCfg2
       ? ~io_in_pmpCfg_11_L & io_in_wdata[30]
       : wenCfg0 & ~io_in_pmpCfg_3_L & io_in_wdata[30],
     wenCfg2
       ? ~io_in_pmpCfg_11_L & io_in_wdata[29]
       : wenCfg0 & ~io_in_pmpCfg_3_L & io_in_wdata[29],
     wenCfg2
       ? (io_in_pmpCfg_11_L
            ? io_in_pmpCfg_11_A
            : {io_in_wdata[28], |(io_in_wdata[28:27])})
       : wenCfg0
           ? (io_in_pmpCfg_3_L
                ? io_in_pmpCfg_3_A
                : {io_in_wdata[28], |(io_in_wdata[28:27])})
           : 2'h0,
     wenCfg2
       ? (io_in_pmpCfg_11_L ? io_in_pmpCfg_11_X : io_in_wdata[26])
       : wenCfg0 & (io_in_pmpCfg_3_L ? io_in_pmpCfg_3_X : io_in_wdata[26]),
     wenCfg2
       ? (io_in_pmpCfg_11_L ? io_in_pmpCfg_11_W : io_in_wdata[25] & io_in_wdata[24])
       : wenCfg0 & (io_in_pmpCfg_3_L ? io_in_pmpCfg_3_W : io_in_wdata[25] & io_in_wdata[24]),
     wenCfg2
       ? (io_in_pmpCfg_11_L ? io_in_pmpCfg_11_R : io_in_wdata[24])
       : wenCfg0 & (io_in_pmpCfg_3_L ? io_in_pmpCfg_3_R : io_in_wdata[24]),
     wenCfg2
       ? (io_in_pmpCfg_10_L ? io_in_pmpCfg_10_L : io_in_wdata[23])
       : wenCfg0 & (io_in_pmpCfg_2_L ? io_in_pmpCfg_2_L : io_in_wdata[23]),
     wenCfg2
       ? ~io_in_pmpCfg_10_L & io_in_wdata[22]
       : wenCfg0 & ~io_in_pmpCfg_2_L & io_in_wdata[22],
     wenCfg2
       ? ~io_in_pmpCfg_10_L & io_in_wdata[21]
       : wenCfg0 & ~io_in_pmpCfg_2_L & io_in_wdata[21],
     wenCfg2
       ? (io_in_pmpCfg_10_L
            ? io_in_pmpCfg_10_A
            : {io_in_wdata[20], |(io_in_wdata[20:19])})
       : wenCfg0
           ? (io_in_pmpCfg_2_L
                ? io_in_pmpCfg_2_A
                : {io_in_wdata[20], |(io_in_wdata[20:19])})
           : 2'h0,
     wenCfg2
       ? (io_in_pmpCfg_10_L ? io_in_pmpCfg_10_X : io_in_wdata[18])
       : wenCfg0 & (io_in_pmpCfg_2_L ? io_in_pmpCfg_2_X : io_in_wdata[18]),
     wenCfg2
       ? (io_in_pmpCfg_10_L ? io_in_pmpCfg_10_W : io_in_wdata[17] & io_in_wdata[16])
       : wenCfg0 & (io_in_pmpCfg_2_L ? io_in_pmpCfg_2_W : io_in_wdata[17] & io_in_wdata[16]),
     wenCfg2
       ? (io_in_pmpCfg_10_L ? io_in_pmpCfg_10_R : io_in_wdata[16])
       : wenCfg0 & (io_in_pmpCfg_2_L ? io_in_pmpCfg_2_R : io_in_wdata[16]),
     wenCfg2
       ? (io_in_pmpCfg_9_L ? io_in_pmpCfg_9_L : io_in_wdata[15])
       : wenCfg0 & (io_in_pmpCfg_1_L ? io_in_pmpCfg_1_L : io_in_wdata[15]),
     wenCfg2
       ? ~io_in_pmpCfg_9_L & io_in_wdata[14]
       : wenCfg0 & ~io_in_pmpCfg_1_L & io_in_wdata[14],
     wenCfg2
       ? ~io_in_pmpCfg_9_L & io_in_wdata[13]
       : wenCfg0 & ~io_in_pmpCfg_1_L & io_in_wdata[13],
     wenCfg2
       ? (io_in_pmpCfg_9_L ? io_in_pmpCfg_9_A : {io_in_wdata[12], |(io_in_wdata[12:11])})
       : wenCfg0
           ? (io_in_pmpCfg_1_L
                ? io_in_pmpCfg_1_A
                : {io_in_wdata[12], |(io_in_wdata[12:11])})
           : 2'h0,
     wenCfg2
       ? (io_in_pmpCfg_9_L ? io_in_pmpCfg_9_X : io_in_wdata[10])
       : wenCfg0 & (io_in_pmpCfg_1_L ? io_in_pmpCfg_1_X : io_in_wdata[10]),
     wenCfg2
       ? (io_in_pmpCfg_9_L ? io_in_pmpCfg_9_W : io_in_wdata[9] & io_in_wdata[8])
       : wenCfg0 & (io_in_pmpCfg_1_L ? io_in_pmpCfg_1_W : io_in_wdata[9] & io_in_wdata[8]),
     wenCfg2
       ? (io_in_pmpCfg_9_L ? io_in_pmpCfg_9_R : io_in_wdata[8])
       : wenCfg0 & (io_in_pmpCfg_1_L ? io_in_pmpCfg_1_R : io_in_wdata[8]),
     wenCfg2
       ? (io_in_pmpCfg_8_L ? io_in_pmpCfg_8_L : io_in_wdata[7])
       : wenCfg0 & (io_in_pmpCfg_0_L ? io_in_pmpCfg_0_L : io_in_wdata[7]),
     wenCfg2
       ? ~io_in_pmpCfg_8_L & io_in_wdata[6]
       : wenCfg0 & ~io_in_pmpCfg_0_L & io_in_wdata[6],
     wenCfg2
       ? ~io_in_pmpCfg_8_L & io_in_wdata[5]
       : wenCfg0 & ~io_in_pmpCfg_0_L & io_in_wdata[5],
     wenCfg2
       ? (io_in_pmpCfg_8_L ? io_in_pmpCfg_8_A : {io_in_wdata[4], |(io_in_wdata[4:3])})
       : wenCfg0
           ? (io_in_pmpCfg_0_L ? io_in_pmpCfg_0_A : {io_in_wdata[4], |(io_in_wdata[4:3])})
           : 2'h0,
     wenCfg2
       ? (io_in_pmpCfg_8_L ? io_in_pmpCfg_8_X : io_in_wdata[2])
       : wenCfg0 & (io_in_pmpCfg_0_L ? io_in_pmpCfg_0_X : io_in_wdata[2]),
     wenCfg2
       ? (io_in_pmpCfg_8_L ? io_in_pmpCfg_8_W : io_in_wdata[1] & io_in_wdata[0])
       : wenCfg0 & (io_in_pmpCfg_0_L ? io_in_pmpCfg_0_W : io_in_wdata[1] & io_in_wdata[0]),
     wenCfg2
       ? (io_in_pmpCfg_8_L ? io_in_pmpCfg_8_R : io_in_wdata[0])
       : wenCfg0 & (io_in_pmpCfg_0_L ? io_in_pmpCfg_0_R : io_in_wdata[0])};
  assign io_out_pmpAddrRData_0 =
    {18'h0,
     io_in_ren & addrEntry0
       ? (io_in_pmpCfg_0_A[1]
            ? {io_in_pmpAddr_0_ADDRESS[45:9], 9'h1FF}
            : {io_in_pmpAddr_0_ADDRESS[45:10], 10'h0})
       : io_in_pmpAddr_0_ADDRESS};
  assign io_out_pmpAddrRData_1 =
    {18'h0,
     io_in_ren & addrEntry1
       ? (io_in_pmpCfg_1_A[1]
            ? {io_in_pmpAddr_1_ADDRESS[45:9], 9'h1FF}
            : {io_in_pmpAddr_1_ADDRESS[45:10], 10'h0})
       : io_in_pmpAddr_1_ADDRESS};
  assign io_out_pmpAddrRData_2 =
    {18'h0,
     io_in_ren & addrEntry2
       ? (io_in_pmpCfg_2_A[1]
            ? {io_in_pmpAddr_2_ADDRESS[45:9], 9'h1FF}
            : {io_in_pmpAddr_2_ADDRESS[45:10], 10'h0})
       : io_in_pmpAddr_2_ADDRESS};
  assign io_out_pmpAddrRData_3 =
    {18'h0,
     io_in_ren & addrEntry3
       ? (io_in_pmpCfg_3_A[1]
            ? {io_in_pmpAddr_3_ADDRESS[45:9], 9'h1FF}
            : {io_in_pmpAddr_3_ADDRESS[45:10], 10'h0})
       : io_in_pmpAddr_3_ADDRESS};
  assign io_out_pmpAddrRData_4 =
    {18'h0,
     io_in_ren & addrEntry4
       ? (io_in_pmpCfg_4_A[1]
            ? {io_in_pmpAddr_4_ADDRESS[45:9], 9'h1FF}
            : {io_in_pmpAddr_4_ADDRESS[45:10], 10'h0})
       : io_in_pmpAddr_4_ADDRESS};
  assign io_out_pmpAddrRData_5 =
    {18'h0,
     io_in_ren & addrEntry5
       ? (io_in_pmpCfg_5_A[1]
            ? {io_in_pmpAddr_5_ADDRESS[45:9], 9'h1FF}
            : {io_in_pmpAddr_5_ADDRESS[45:10], 10'h0})
       : io_in_pmpAddr_5_ADDRESS};
  assign io_out_pmpAddrRData_6 =
    {18'h0,
     io_in_ren & addrEntry6
       ? (io_in_pmpCfg_6_A[1]
            ? {io_in_pmpAddr_6_ADDRESS[45:9], 9'h1FF}
            : {io_in_pmpAddr_6_ADDRESS[45:10], 10'h0})
       : io_in_pmpAddr_6_ADDRESS};
  assign io_out_pmpAddrRData_7 =
    {18'h0,
     io_in_ren & addrEntry7
       ? (io_in_pmpCfg_7_A[1]
            ? {io_in_pmpAddr_7_ADDRESS[45:9], 9'h1FF}
            : {io_in_pmpAddr_7_ADDRESS[45:10], 10'h0})
       : io_in_pmpAddr_7_ADDRESS};
  assign io_out_pmpAddrRData_8 =
    {18'h0,
     io_in_ren & addrEntry8
       ? (io_in_pmpCfg_8_A[1]
            ? {io_in_pmpAddr_8_ADDRESS[45:9], 9'h1FF}
            : {io_in_pmpAddr_8_ADDRESS[45:10], 10'h0})
       : io_in_pmpAddr_8_ADDRESS};
  assign io_out_pmpAddrRData_9 =
    {18'h0,
     io_in_ren & addrEntry9
       ? (io_in_pmpCfg_9_A[1]
            ? {io_in_pmpAddr_9_ADDRESS[45:9], 9'h1FF}
            : {io_in_pmpAddr_9_ADDRESS[45:10], 10'h0})
       : io_in_pmpAddr_9_ADDRESS};
  assign io_out_pmpAddrRData_10 =
    {18'h0,
     io_in_ren & addrEntry10
       ? (io_in_pmpCfg_10_A[1]
            ? {io_in_pmpAddr_10_ADDRESS[45:9], 9'h1FF}
            : {io_in_pmpAddr_10_ADDRESS[45:10], 10'h0})
       : io_in_pmpAddr_10_ADDRESS};
  assign io_out_pmpAddrRData_11 =
    {18'h0,
     io_in_ren & addrEntry11
       ? (io_in_pmpCfg_11_A[1]
            ? {io_in_pmpAddr_11_ADDRESS[45:9], 9'h1FF}
            : {io_in_pmpAddr_11_ADDRESS[45:10], 10'h0})
       : io_in_pmpAddr_11_ADDRESS};
  assign io_out_pmpAddrRData_12 =
    {18'h0,
     io_in_ren & addrEntry12
       ? (io_in_pmpCfg_12_A[1]
            ? {io_in_pmpAddr_12_ADDRESS[45:9], 9'h1FF}
            : {io_in_pmpAddr_12_ADDRESS[45:10], 10'h0})
       : io_in_pmpAddr_12_ADDRESS};
  assign io_out_pmpAddrRData_13 =
    {18'h0,
     io_in_ren & addrEntry13
       ? (io_in_pmpCfg_13_A[1]
            ? {io_in_pmpAddr_13_ADDRESS[45:9], 9'h1FF}
            : {io_in_pmpAddr_13_ADDRESS[45:10], 10'h0})
       : io_in_pmpAddr_13_ADDRESS};
  assign io_out_pmpAddrRData_14 =
    {18'h0,
     io_in_ren & addrEntry14
       ? (io_in_pmpCfg_14_A[1]
            ? {io_in_pmpAddr_14_ADDRESS[45:9], 9'h1FF}
            : {io_in_pmpAddr_14_ADDRESS[45:10], 10'h0})
       : io_in_pmpAddr_14_ADDRESS};
  assign io_out_pmpAddrRData_15 =
    {18'h0,
     io_in_ren & addrEntry15
       ? (io_in_pmpCfg_15_A[1]
            ? {io_in_pmpAddr_15_ADDRESS[45:9], 9'h1FF}
            : {io_in_pmpAddr_15_ADDRESS[45:10], 10'h0})
       : io_in_pmpAddr_15_ADDRESS};
  assign io_out_pmpAddrWData_0 =
    ~(io_in_wen & addrEntry0) | io_in_pmpCfg_0_L | io_in_pmpCfg_1_L & io_in_pmpCfg_1_A == 2'h1
      ? {18'h0, io_in_pmpAddr_0_ADDRESS}
      : io_in_wdata;
  assign io_out_pmpAddrWData_1 =
    ~(io_in_wen & addrEntry1) | io_in_pmpCfg_1_L | io_in_pmpCfg_2_L & io_in_pmpCfg_2_A == 2'h1
      ? {18'h0, io_in_pmpAddr_1_ADDRESS}
      : io_in_wdata;
  assign io_out_pmpAddrWData_2 =
    ~(io_in_wen & addrEntry2) | io_in_pmpCfg_2_L | io_in_pmpCfg_3_L & io_in_pmpCfg_3_A == 2'h1
      ? {18'h0, io_in_pmpAddr_2_ADDRESS}
      : io_in_wdata;
  assign io_out_pmpAddrWData_3 =
    ~(io_in_wen & addrEntry3) | io_in_pmpCfg_3_L | io_in_pmpCfg_4_L & io_in_pmpCfg_4_A == 2'h1
      ? {18'h0, io_in_pmpAddr_3_ADDRESS}
      : io_in_wdata;
  assign io_out_pmpAddrWData_4 =
    ~(io_in_wen & addrEntry4) | io_in_pmpCfg_4_L | io_in_pmpCfg_5_L & io_in_pmpCfg_5_A == 2'h1
      ? {18'h0, io_in_pmpAddr_4_ADDRESS}
      : io_in_wdata;
  assign io_out_pmpAddrWData_5 =
    ~(io_in_wen & addrEntry5) | io_in_pmpCfg_5_L | io_in_pmpCfg_6_L & io_in_pmpCfg_6_A == 2'h1
      ? {18'h0, io_in_pmpAddr_5_ADDRESS}
      : io_in_wdata;
  assign io_out_pmpAddrWData_6 =
    ~(io_in_wen & addrEntry6) | io_in_pmpCfg_6_L | io_in_pmpCfg_7_L & io_in_pmpCfg_7_A == 2'h1
      ? {18'h0, io_in_pmpAddr_6_ADDRESS}
      : io_in_wdata;
  assign io_out_pmpAddrWData_7 =
    ~(io_in_wen & addrEntry7) | io_in_pmpCfg_7_L | io_in_pmpCfg_8_L & io_in_pmpCfg_8_A == 2'h1
      ? {18'h0, io_in_pmpAddr_7_ADDRESS}
      : io_in_wdata;
  assign io_out_pmpAddrWData_8 =
    ~(io_in_wen & addrEntry8) | io_in_pmpCfg_8_L | io_in_pmpCfg_9_L & io_in_pmpCfg_9_A == 2'h1
      ? {18'h0, io_in_pmpAddr_8_ADDRESS}
      : io_in_wdata;
  assign io_out_pmpAddrWData_9 =
    ~(io_in_wen & addrEntry9) | io_in_pmpCfg_9_L | io_in_pmpCfg_10_L
    & io_in_pmpCfg_10_A == 2'h1
      ? {18'h0, io_in_pmpAddr_9_ADDRESS}
      : io_in_wdata;
  assign io_out_pmpAddrWData_10 =
    ~(io_in_wen & addrEntry10) | io_in_pmpCfg_10_L | io_in_pmpCfg_11_L
    & io_in_pmpCfg_11_A == 2'h1
      ? {18'h0, io_in_pmpAddr_10_ADDRESS}
      : io_in_wdata;
  assign io_out_pmpAddrWData_11 =
    ~(io_in_wen & addrEntry11) | io_in_pmpCfg_11_L | io_in_pmpCfg_12_L
    & io_in_pmpCfg_12_A == 2'h1
      ? {18'h0, io_in_pmpAddr_11_ADDRESS}
      : io_in_wdata;
  assign io_out_pmpAddrWData_12 =
    ~(io_in_wen & addrEntry12) | io_in_pmpCfg_12_L | io_in_pmpCfg_13_L
    & io_in_pmpCfg_13_A == 2'h1
      ? {18'h0, io_in_pmpAddr_12_ADDRESS}
      : io_in_wdata;
  assign io_out_pmpAddrWData_13 =
    ~(io_in_wen & addrEntry13) | io_in_pmpCfg_13_L | io_in_pmpCfg_14_L
    & io_in_pmpCfg_14_A == 2'h1
      ? {18'h0, io_in_pmpAddr_13_ADDRESS}
      : io_in_wdata;
  assign io_out_pmpAddrWData_14 =
    ~(io_in_wen & addrEntry14) | io_in_pmpCfg_14_L | io_in_pmpCfg_15_L
    & io_in_pmpCfg_15_A == 2'h1
      ? {18'h0, io_in_pmpAddr_14_ADDRESS}
      : io_in_wdata;
  assign io_out_pmpAddrWData_15 =
    ~(io_in_wen & addrEntry15) | io_in_pmpCfg_15_L
      ? {18'h0, io_in_pmpAddr_15_ADDRESS}
      : io_in_wdata;
endmodule


module PMAEntryHandleModule(
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
  output [63:0] io_out_pmaAddrRData_15
);

  reg  [45:0] pmaAddr_0;
  reg  [45:0] pmaAddr_1;
  reg  [45:0] pmaAddr_2;
  reg  [45:0] pmaAddr_3;
  reg  [45:0] pmaAddr_4;
  reg  [45:0] pmaAddr_5;
  reg  [45:0] pmaAddr_6;
  reg  [45:0] pmaAddr_7;
  reg  [45:0] pmaAddr_8;
  reg  [45:0] pmaAddr_9;
  reg  [45:0] pmaAddr_10;
  reg  [45:0] pmaAddr_11;
  reg  [45:0] pmaAddr_12;
  reg  [45:0] pmaAddr_13;
  reg  [45:0] pmaAddr_14;
  reg  [45:0] pmaAddr_15;
  wire        wenCfg0 = io_in_wen & io_in_addr == 12'h7C0;
  wire        wenCfg2 = io_in_wen & io_in_addr == 12'h7C2;
  wire        addrEntry0 = io_in_addr == 12'h7C8;
  wire        addrEntry1 = io_in_addr == 12'h7C9;
  wire        addrEntry2 = io_in_addr == 12'h7CA;
  wire        addrEntry3 = io_in_addr == 12'h7CB;
  wire        addrEntry4 = io_in_addr == 12'h7CC;
  wire        addrEntry5 = io_in_addr == 12'h7CD;
  wire        addrEntry6 = io_in_addr == 12'h7CE;
  wire        addrEntry7 = io_in_addr == 12'h7CF;
  wire        addrEntry8 = io_in_addr == 12'h7D0;
  wire        addrEntry9 = io_in_addr == 12'h7D1;
  wire        addrEntry10 = io_in_addr == 12'h7D2;
  wire        addrEntry11 = io_in_addr == 12'h7D3;
  wire        addrEntry12 = io_in_addr == 12'h7D4;
  wire        addrEntry13 = io_in_addr == 12'h7D5;
  wire        addrEntry14 = io_in_addr == 12'h7D6;
  wire        addrEntry15 = io_in_addr == 12'h7D7;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      pmaAddr_0 <= 46'h0;
      pmaAddr_1 <= 46'h0;
      pmaAddr_2 <= 46'h0;
      pmaAddr_3 <= 46'h4000000;
      pmaAddr_4 <= 46'h8000000;
      pmaAddr_5 <= 46'hC004000;
      pmaAddr_6 <= 46'hC014000;
      pmaAddr_7 <= 46'hE008000;
      pmaAddr_8 <= 46'hE008400;
      pmaAddr_9 <= 46'hE008800;
      pmaAddr_10 <= 46'hE400000;
      pmaAddr_11 <= 46'hE400800;
      pmaAddr_12 <= 46'hE800000;
      pmaAddr_13 <= 46'h20000000;
      pmaAddr_14 <= 46'h20000000000;
      pmaAddr_15 <= 46'h1FFFFFFFFFFF;
    end
    else begin
      if (~(io_in_wen & addrEntry0) | io_in_pmaCfg_0_L | io_in_pmaCfg_1_L
          & io_in_pmaCfg_1_A == 2'h1) begin
      end
      else
        pmaAddr_0 <= io_in_wdata[45:0];
      if (~(io_in_wen & addrEntry1) | io_in_pmaCfg_1_L | io_in_pmaCfg_2_L
          & io_in_pmaCfg_2_A == 2'h1) begin
      end
      else
        pmaAddr_1 <= io_in_wdata[45:0];
      if (~(io_in_wen & addrEntry2) | io_in_pmaCfg_2_L | io_in_pmaCfg_3_L
          & io_in_pmaCfg_3_A == 2'h1) begin
      end
      else
        pmaAddr_2 <= io_in_wdata[45:0];
      if (~(io_in_wen & addrEntry3) | io_in_pmaCfg_3_L | io_in_pmaCfg_4_L
          & io_in_pmaCfg_4_A == 2'h1) begin
      end
      else
        pmaAddr_3 <= io_in_wdata[45:0];
      if (~(io_in_wen & addrEntry4) | io_in_pmaCfg_4_L | io_in_pmaCfg_5_L
          & io_in_pmaCfg_5_A == 2'h1) begin
      end
      else
        pmaAddr_4 <= io_in_wdata[45:0];
      if (~(io_in_wen & addrEntry5) | io_in_pmaCfg_5_L | io_in_pmaCfg_6_L
          & io_in_pmaCfg_6_A == 2'h1) begin
      end
      else
        pmaAddr_5 <= io_in_wdata[45:0];
      if (~(io_in_wen & addrEntry6) | io_in_pmaCfg_6_L | io_in_pmaCfg_7_L
          & io_in_pmaCfg_7_A == 2'h1) begin
      end
      else
        pmaAddr_6 <= io_in_wdata[45:0];
      if (~(io_in_wen & addrEntry7) | io_in_pmaCfg_7_L | io_in_pmaCfg_8_L
          & io_in_pmaCfg_8_A == 2'h1) begin
      end
      else
        pmaAddr_7 <= io_in_wdata[45:0];
      if (~(io_in_wen & addrEntry8) | io_in_pmaCfg_8_L | io_in_pmaCfg_9_L
          & io_in_pmaCfg_9_A == 2'h1) begin
      end
      else
        pmaAddr_8 <= io_in_wdata[45:0];
      if (~(io_in_wen & addrEntry9) | io_in_pmaCfg_9_L | io_in_pmaCfg_10_L
          & io_in_pmaCfg_10_A == 2'h1) begin
      end
      else
        pmaAddr_9 <= io_in_wdata[45:0];
      if (~(io_in_wen & addrEntry10) | io_in_pmaCfg_10_L | io_in_pmaCfg_11_L
          & io_in_pmaCfg_11_A == 2'h1) begin
      end
      else
        pmaAddr_10 <= io_in_wdata[45:0];
      if (~(io_in_wen & addrEntry11) | io_in_pmaCfg_11_L | io_in_pmaCfg_12_L
          & io_in_pmaCfg_12_A == 2'h1) begin
      end
      else
        pmaAddr_11 <= io_in_wdata[45:0];
      if (~(io_in_wen & addrEntry12) | io_in_pmaCfg_12_L | io_in_pmaCfg_13_L
          & io_in_pmaCfg_13_A == 2'h1) begin
      end
      else
        pmaAddr_12 <= io_in_wdata[45:0];
      if (~(io_in_wen & addrEntry13) | io_in_pmaCfg_13_L | io_in_pmaCfg_14_L
          & io_in_pmaCfg_14_A == 2'h1) begin
      end
      else
        pmaAddr_13 <= io_in_wdata[45:0];
      if (~(io_in_wen & addrEntry14) | io_in_pmaCfg_14_L | io_in_pmaCfg_15_L
          & io_in_pmaCfg_15_A == 2'h1) begin
      end
      else
        pmaAddr_14 <= io_in_wdata[45:0];
      if (~(io_in_wen & addrEntry15) | io_in_pmaCfg_15_L) begin
      end
      else
        pmaAddr_15 <= io_in_wdata[45:0];
    end
  end
  assign io_out_pmaCfgWdata =
    {wenCfg2
       ? (io_in_pmaCfg_15_L ? io_in_pmaCfg_15_L : io_in_wdata[63])
       : wenCfg0 & (io_in_pmaCfg_7_L ? io_in_pmaCfg_7_L : io_in_wdata[63]),
     wenCfg2
       ? (io_in_pmaCfg_15_L ? io_in_pmaCfg_15_C : io_in_wdata[62])
       : wenCfg0 & (io_in_pmaCfg_7_L ? io_in_pmaCfg_7_C : io_in_wdata[62]),
     wenCfg2
       ? (io_in_pmaCfg_15_L ? io_in_pmaCfg_15_ATOMIC : io_in_wdata[61])
       : wenCfg0 & (io_in_pmaCfg_7_L ? io_in_pmaCfg_7_ATOMIC : io_in_wdata[61]),
     wenCfg2
       ? (io_in_pmaCfg_15_L
            ? io_in_pmaCfg_15_A
            : {io_in_wdata[60], |(io_in_wdata[60:59])})
       : wenCfg0
           ? (io_in_pmaCfg_7_L
                ? io_in_pmaCfg_7_A
                : {io_in_wdata[60], |(io_in_wdata[60:59])})
           : 2'h0,
     wenCfg2
       ? (io_in_pmaCfg_15_L ? io_in_pmaCfg_15_X : io_in_wdata[58])
       : wenCfg0 & (io_in_pmaCfg_7_L ? io_in_pmaCfg_7_X : io_in_wdata[58]),
     wenCfg2
       ? (io_in_pmaCfg_15_L ? io_in_pmaCfg_15_W : io_in_wdata[57] & io_in_wdata[56])
       : wenCfg0 & (io_in_pmaCfg_7_L ? io_in_pmaCfg_7_W : io_in_wdata[57] & io_in_wdata[56]),
     wenCfg2
       ? (io_in_pmaCfg_15_L ? io_in_pmaCfg_15_R : io_in_wdata[56])
       : wenCfg0 & (io_in_pmaCfg_7_L ? io_in_pmaCfg_7_R : io_in_wdata[56]),
     wenCfg2
       ? (io_in_pmaCfg_14_L ? io_in_pmaCfg_14_L : io_in_wdata[55])
       : wenCfg0 & (io_in_pmaCfg_6_L ? io_in_pmaCfg_6_L : io_in_wdata[55]),
     wenCfg2
       ? (io_in_pmaCfg_14_L ? io_in_pmaCfg_14_C : io_in_wdata[54])
       : wenCfg0 & (io_in_pmaCfg_6_L ? io_in_pmaCfg_6_C : io_in_wdata[54]),
     wenCfg2
       ? (io_in_pmaCfg_14_L ? io_in_pmaCfg_14_ATOMIC : io_in_wdata[53])
       : wenCfg0 & (io_in_pmaCfg_6_L ? io_in_pmaCfg_6_ATOMIC : io_in_wdata[53]),
     wenCfg2
       ? (io_in_pmaCfg_14_L
            ? io_in_pmaCfg_14_A
            : {io_in_wdata[52], |(io_in_wdata[52:51])})
       : wenCfg0
           ? (io_in_pmaCfg_6_L
                ? io_in_pmaCfg_6_A
                : {io_in_wdata[52], |(io_in_wdata[52:51])})
           : 2'h0,
     wenCfg2
       ? (io_in_pmaCfg_14_L ? io_in_pmaCfg_14_X : io_in_wdata[50])
       : wenCfg0 & (io_in_pmaCfg_6_L ? io_in_pmaCfg_6_X : io_in_wdata[50]),
     wenCfg2
       ? (io_in_pmaCfg_14_L ? io_in_pmaCfg_14_W : io_in_wdata[49] & io_in_wdata[48])
       : wenCfg0 & (io_in_pmaCfg_6_L ? io_in_pmaCfg_6_W : io_in_wdata[49] & io_in_wdata[48]),
     wenCfg2
       ? (io_in_pmaCfg_14_L ? io_in_pmaCfg_14_R : io_in_wdata[48])
       : wenCfg0 & (io_in_pmaCfg_6_L ? io_in_pmaCfg_6_R : io_in_wdata[48]),
     wenCfg2
       ? (io_in_pmaCfg_13_L ? io_in_pmaCfg_13_L : io_in_wdata[47])
       : wenCfg0 & (io_in_pmaCfg_5_L ? io_in_pmaCfg_5_L : io_in_wdata[47]),
     wenCfg2
       ? (io_in_pmaCfg_13_L ? io_in_pmaCfg_13_C : io_in_wdata[46])
       : wenCfg0 & (io_in_pmaCfg_5_L ? io_in_pmaCfg_5_C : io_in_wdata[46]),
     wenCfg2
       ? (io_in_pmaCfg_13_L ? io_in_pmaCfg_13_ATOMIC : io_in_wdata[45])
       : wenCfg0 & (io_in_pmaCfg_5_L ? io_in_pmaCfg_5_ATOMIC : io_in_wdata[45]),
     wenCfg2
       ? (io_in_pmaCfg_13_L
            ? io_in_pmaCfg_13_A
            : {io_in_wdata[44], |(io_in_wdata[44:43])})
       : wenCfg0
           ? (io_in_pmaCfg_5_L
                ? io_in_pmaCfg_5_A
                : {io_in_wdata[44], |(io_in_wdata[44:43])})
           : 2'h0,
     wenCfg2
       ? (io_in_pmaCfg_13_L ? io_in_pmaCfg_13_X : io_in_wdata[42])
       : wenCfg0 & (io_in_pmaCfg_5_L ? io_in_pmaCfg_5_X : io_in_wdata[42]),
     wenCfg2
       ? (io_in_pmaCfg_13_L ? io_in_pmaCfg_13_W : io_in_wdata[41] & io_in_wdata[40])
       : wenCfg0 & (io_in_pmaCfg_5_L ? io_in_pmaCfg_5_W : io_in_wdata[41] & io_in_wdata[40]),
     wenCfg2
       ? (io_in_pmaCfg_13_L ? io_in_pmaCfg_13_R : io_in_wdata[40])
       : wenCfg0 & (io_in_pmaCfg_5_L ? io_in_pmaCfg_5_R : io_in_wdata[40]),
     wenCfg2
       ? (io_in_pmaCfg_12_L ? io_in_pmaCfg_12_L : io_in_wdata[39])
       : wenCfg0 & (io_in_pmaCfg_4_L ? io_in_pmaCfg_4_L : io_in_wdata[39]),
     wenCfg2
       ? (io_in_pmaCfg_12_L ? io_in_pmaCfg_12_C : io_in_wdata[38])
       : wenCfg0 & (io_in_pmaCfg_4_L ? io_in_pmaCfg_4_C : io_in_wdata[38]),
     wenCfg2
       ? (io_in_pmaCfg_12_L ? io_in_pmaCfg_12_ATOMIC : io_in_wdata[37])
       : wenCfg0 & (io_in_pmaCfg_4_L ? io_in_pmaCfg_4_ATOMIC : io_in_wdata[37]),
     wenCfg2
       ? (io_in_pmaCfg_12_L
            ? io_in_pmaCfg_12_A
            : {io_in_wdata[36], |(io_in_wdata[36:35])})
       : wenCfg0
           ? (io_in_pmaCfg_4_L
                ? io_in_pmaCfg_4_A
                : {io_in_wdata[36], |(io_in_wdata[36:35])})
           : 2'h0,
     wenCfg2
       ? (io_in_pmaCfg_12_L ? io_in_pmaCfg_12_X : io_in_wdata[34])
       : wenCfg0 & (io_in_pmaCfg_4_L ? io_in_pmaCfg_4_X : io_in_wdata[34]),
     wenCfg2
       ? (io_in_pmaCfg_12_L ? io_in_pmaCfg_12_W : io_in_wdata[33] & io_in_wdata[32])
       : wenCfg0 & (io_in_pmaCfg_4_L ? io_in_pmaCfg_4_W : io_in_wdata[33] & io_in_wdata[32]),
     wenCfg2
       ? (io_in_pmaCfg_12_L ? io_in_pmaCfg_12_R : io_in_wdata[32])
       : wenCfg0 & (io_in_pmaCfg_4_L ? io_in_pmaCfg_4_R : io_in_wdata[32]),
     wenCfg2
       ? (io_in_pmaCfg_11_L ? io_in_pmaCfg_11_L : io_in_wdata[31])
       : wenCfg0 & (io_in_pmaCfg_3_L ? io_in_pmaCfg_3_L : io_in_wdata[31]),
     wenCfg2
       ? (io_in_pmaCfg_11_L ? io_in_pmaCfg_11_C : io_in_wdata[30])
       : wenCfg0 & (io_in_pmaCfg_3_L ? io_in_pmaCfg_3_C : io_in_wdata[30]),
     wenCfg2
       ? (io_in_pmaCfg_11_L ? io_in_pmaCfg_11_ATOMIC : io_in_wdata[29])
       : wenCfg0 & (io_in_pmaCfg_3_L ? io_in_pmaCfg_3_ATOMIC : io_in_wdata[29]),
     wenCfg2
       ? (io_in_pmaCfg_11_L
            ? io_in_pmaCfg_11_A
            : {io_in_wdata[28], |(io_in_wdata[28:27])})
       : wenCfg0
           ? (io_in_pmaCfg_3_L
                ? io_in_pmaCfg_3_A
                : {io_in_wdata[28], |(io_in_wdata[28:27])})
           : 2'h0,
     wenCfg2
       ? (io_in_pmaCfg_11_L ? io_in_pmaCfg_11_X : io_in_wdata[26])
       : wenCfg0 & (io_in_pmaCfg_3_L ? io_in_pmaCfg_3_X : io_in_wdata[26]),
     wenCfg2
       ? (io_in_pmaCfg_11_L ? io_in_pmaCfg_11_W : io_in_wdata[25] & io_in_wdata[24])
       : wenCfg0 & (io_in_pmaCfg_3_L ? io_in_pmaCfg_3_W : io_in_wdata[25] & io_in_wdata[24]),
     wenCfg2
       ? (io_in_pmaCfg_11_L ? io_in_pmaCfg_11_R : io_in_wdata[24])
       : wenCfg0 & (io_in_pmaCfg_3_L ? io_in_pmaCfg_3_R : io_in_wdata[24]),
     wenCfg2
       ? (io_in_pmaCfg_10_L ? io_in_pmaCfg_10_L : io_in_wdata[23])
       : wenCfg0 & (io_in_pmaCfg_2_L ? io_in_pmaCfg_2_L : io_in_wdata[23]),
     wenCfg2
       ? (io_in_pmaCfg_10_L ? io_in_pmaCfg_10_C : io_in_wdata[22])
       : wenCfg0 & (io_in_pmaCfg_2_L ? io_in_pmaCfg_2_C : io_in_wdata[22]),
     wenCfg2
       ? (io_in_pmaCfg_10_L ? io_in_pmaCfg_10_ATOMIC : io_in_wdata[21])
       : wenCfg0 & (io_in_pmaCfg_2_L ? io_in_pmaCfg_2_ATOMIC : io_in_wdata[21]),
     wenCfg2
       ? (io_in_pmaCfg_10_L
            ? io_in_pmaCfg_10_A
            : {io_in_wdata[20], |(io_in_wdata[20:19])})
       : wenCfg0
           ? (io_in_pmaCfg_2_L
                ? io_in_pmaCfg_2_A
                : {io_in_wdata[20], |(io_in_wdata[20:19])})
           : 2'h0,
     wenCfg2
       ? (io_in_pmaCfg_10_L ? io_in_pmaCfg_10_X : io_in_wdata[18])
       : wenCfg0 & (io_in_pmaCfg_2_L ? io_in_pmaCfg_2_X : io_in_wdata[18]),
     wenCfg2
       ? (io_in_pmaCfg_10_L ? io_in_pmaCfg_10_W : io_in_wdata[17] & io_in_wdata[16])
       : wenCfg0 & (io_in_pmaCfg_2_L ? io_in_pmaCfg_2_W : io_in_wdata[17] & io_in_wdata[16]),
     wenCfg2
       ? (io_in_pmaCfg_10_L ? io_in_pmaCfg_10_R : io_in_wdata[16])
       : wenCfg0 & (io_in_pmaCfg_2_L ? io_in_pmaCfg_2_R : io_in_wdata[16]),
     wenCfg2
       ? (io_in_pmaCfg_9_L ? io_in_pmaCfg_9_L : io_in_wdata[15])
       : wenCfg0 & (io_in_pmaCfg_1_L ? io_in_pmaCfg_1_L : io_in_wdata[15]),
     wenCfg2
       ? (io_in_pmaCfg_9_L ? io_in_pmaCfg_9_C : io_in_wdata[14])
       : wenCfg0 & (io_in_pmaCfg_1_L ? io_in_pmaCfg_1_C : io_in_wdata[14]),
     wenCfg2
       ? (io_in_pmaCfg_9_L ? io_in_pmaCfg_9_ATOMIC : io_in_wdata[13])
       : wenCfg0 & (io_in_pmaCfg_1_L ? io_in_pmaCfg_1_ATOMIC : io_in_wdata[13]),
     wenCfg2
       ? (io_in_pmaCfg_9_L ? io_in_pmaCfg_9_A : {io_in_wdata[12], |(io_in_wdata[12:11])})
       : wenCfg0
           ? (io_in_pmaCfg_1_L
                ? io_in_pmaCfg_1_A
                : {io_in_wdata[12], |(io_in_wdata[12:11])})
           : 2'h0,
     wenCfg2
       ? (io_in_pmaCfg_9_L ? io_in_pmaCfg_9_X : io_in_wdata[10])
       : wenCfg0 & (io_in_pmaCfg_1_L ? io_in_pmaCfg_1_X : io_in_wdata[10]),
     wenCfg2
       ? (io_in_pmaCfg_9_L ? io_in_pmaCfg_9_W : io_in_wdata[9] & io_in_wdata[8])
       : wenCfg0 & (io_in_pmaCfg_1_L ? io_in_pmaCfg_1_W : io_in_wdata[9] & io_in_wdata[8]),
     wenCfg2
       ? (io_in_pmaCfg_9_L ? io_in_pmaCfg_9_R : io_in_wdata[8])
       : wenCfg0 & (io_in_pmaCfg_1_L ? io_in_pmaCfg_1_R : io_in_wdata[8]),
     wenCfg2
       ? (io_in_pmaCfg_8_L ? io_in_pmaCfg_8_L : io_in_wdata[7])
       : wenCfg0 & (io_in_pmaCfg_0_L ? io_in_pmaCfg_0_L : io_in_wdata[7]),
     wenCfg2
       ? (io_in_pmaCfg_8_L ? io_in_pmaCfg_8_C : io_in_wdata[6])
       : wenCfg0 & (io_in_pmaCfg_0_L ? io_in_pmaCfg_0_C : io_in_wdata[6]),
     wenCfg2
       ? (io_in_pmaCfg_8_L ? io_in_pmaCfg_8_ATOMIC : io_in_wdata[5])
       : wenCfg0 & (io_in_pmaCfg_0_L ? io_in_pmaCfg_0_ATOMIC : io_in_wdata[5]),
     wenCfg2
       ? (io_in_pmaCfg_8_L ? io_in_pmaCfg_8_A : {io_in_wdata[4], |(io_in_wdata[4:3])})
       : wenCfg0
           ? (io_in_pmaCfg_0_L ? io_in_pmaCfg_0_A : {io_in_wdata[4], |(io_in_wdata[4:3])})
           : 2'h0,
     wenCfg2
       ? (io_in_pmaCfg_8_L ? io_in_pmaCfg_8_X : io_in_wdata[2])
       : wenCfg0 & (io_in_pmaCfg_0_L ? io_in_pmaCfg_0_X : io_in_wdata[2]),
     wenCfg2
       ? (io_in_pmaCfg_8_L ? io_in_pmaCfg_8_W : io_in_wdata[1] & io_in_wdata[0])
       : wenCfg0 & (io_in_pmaCfg_0_L ? io_in_pmaCfg_0_W : io_in_wdata[1] & io_in_wdata[0]),
     wenCfg2
       ? (io_in_pmaCfg_8_L ? io_in_pmaCfg_8_R : io_in_wdata[0])
       : wenCfg0 & (io_in_pmaCfg_0_L ? io_in_pmaCfg_0_R : io_in_wdata[0])};
  assign io_out_pmaAddrRData_0 =
    {18'h0,
     io_in_ren & addrEntry0
       ? (io_in_pmaCfg_0_A[1] ? {pmaAddr_0[45:9], 9'h1FF} : {pmaAddr_0[45:10], 10'h0})
       : pmaAddr_0};
  assign io_out_pmaAddrRData_1 =
    {18'h0,
     io_in_ren & addrEntry1
       ? (io_in_pmaCfg_1_A[1] ? {pmaAddr_1[45:9], 9'h1FF} : {pmaAddr_1[45:10], 10'h0})
       : pmaAddr_1};
  assign io_out_pmaAddrRData_2 =
    {18'h0,
     io_in_ren & addrEntry2
       ? (io_in_pmaCfg_2_A[1] ? {pmaAddr_2[45:9], 9'h1FF} : {pmaAddr_2[45:10], 10'h0})
       : pmaAddr_2};
  assign io_out_pmaAddrRData_3 =
    {18'h0,
     io_in_ren & addrEntry3
       ? (io_in_pmaCfg_3_A[1] ? {pmaAddr_3[45:9], 9'h1FF} : {pmaAddr_3[45:10], 10'h0})
       : pmaAddr_3};
  assign io_out_pmaAddrRData_4 =
    {18'h0,
     io_in_ren & addrEntry4
       ? (io_in_pmaCfg_4_A[1] ? {pmaAddr_4[45:9], 9'h1FF} : {pmaAddr_4[45:10], 10'h0})
       : pmaAddr_4};
  assign io_out_pmaAddrRData_5 =
    {18'h0,
     io_in_ren & addrEntry5
       ? (io_in_pmaCfg_5_A[1] ? {pmaAddr_5[45:9], 9'h1FF} : {pmaAddr_5[45:10], 10'h0})
       : pmaAddr_5};
  assign io_out_pmaAddrRData_6 =
    {18'h0,
     io_in_ren & addrEntry6
       ? (io_in_pmaCfg_6_A[1] ? {pmaAddr_6[45:9], 9'h1FF} : {pmaAddr_6[45:10], 10'h0})
       : pmaAddr_6};
  assign io_out_pmaAddrRData_7 =
    {18'h0,
     io_in_ren & addrEntry7
       ? (io_in_pmaCfg_7_A[1] ? {pmaAddr_7[45:9], 9'h1FF} : {pmaAddr_7[45:10], 10'h0})
       : pmaAddr_7};
  assign io_out_pmaAddrRData_8 =
    {18'h0,
     io_in_ren & addrEntry8
       ? (io_in_pmaCfg_8_A[1] ? {pmaAddr_8[45:9], 9'h1FF} : {pmaAddr_8[45:10], 10'h0})
       : pmaAddr_8};
  assign io_out_pmaAddrRData_9 =
    {18'h0,
     io_in_ren & addrEntry9
       ? (io_in_pmaCfg_9_A[1] ? {pmaAddr_9[45:9], 9'h1FF} : {pmaAddr_9[45:10], 10'h0})
       : pmaAddr_9};
  assign io_out_pmaAddrRData_10 =
    {18'h0,
     io_in_ren & addrEntry10
       ? (io_in_pmaCfg_10_A[1] ? {pmaAddr_10[45:9], 9'h1FF} : {pmaAddr_10[45:10], 10'h0})
       : pmaAddr_10};
  assign io_out_pmaAddrRData_11 =
    {18'h0,
     io_in_ren & addrEntry11
       ? (io_in_pmaCfg_11_A[1] ? {pmaAddr_11[45:9], 9'h1FF} : {pmaAddr_11[45:10], 10'h0})
       : pmaAddr_11};
  assign io_out_pmaAddrRData_12 =
    {18'h0,
     io_in_ren & addrEntry12
       ? (io_in_pmaCfg_12_A[1] ? {pmaAddr_12[45:9], 9'h1FF} : {pmaAddr_12[45:10], 10'h0})
       : pmaAddr_12};
  assign io_out_pmaAddrRData_13 =
    {18'h0,
     io_in_ren & addrEntry13
       ? (io_in_pmaCfg_13_A[1] ? {pmaAddr_13[45:9], 9'h1FF} : {pmaAddr_13[45:10], 10'h0})
       : pmaAddr_13};
  assign io_out_pmaAddrRData_14 =
    {18'h0,
     io_in_ren & addrEntry14
       ? (io_in_pmaCfg_14_A[1] ? {pmaAddr_14[45:9], 9'h1FF} : {pmaAddr_14[45:10], 10'h0})
       : pmaAddr_14};
  assign io_out_pmaAddrRData_15 =
    {18'h0,
     io_in_ren & addrEntry15
       ? (io_in_pmaCfg_15_A[1] ? {pmaAddr_15[45:9], 9'h1FF} : {pmaAddr_15[45:10], 10'h0})
       : pmaAddr_15};
endmodule
