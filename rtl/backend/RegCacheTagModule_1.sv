// =============================================================================
// RegCacheTagModule_1 —— RegCacheTagModule 的 Mem 半区单态化变体
//   规模：12 条目 / 3 写口 / 12 读口 / tag 8 位 / loadDependency 3 组 × 2 位；
//         读写地址仍是 4 位（RegCacheIdx 低 4 位按 Int 半区的 16 条目定宽）。
// 核体见 rtl/backend/RegCacheTagModule.sv（xs_RegCacheTagModule_core），
// 本文件只设参数与端口展平。
//
// ★与 Int 变体唯一的结构差异：写口对角线★
//   Mem 半区的三个写口就是三个 load/store 流水自己，写口 w 写进条目里的
//   "对第 w 个 load 的依赖"恒为「刚发射」(2'h1)，于是 firtool 把
//   io_writePorts_w_loadDependency_w 这个输入端口整个删掉了 —— golden 里写成
//   `loadDependency_e_w <= {1'h0, wenOH_e_w} | ...`。这条规则由核的
//   **SELF_DEP_DIAG=1** 供给（RegCacheTagTable 的 Mem 实例也置同一个参数，
//   规则只有一份），所以下面接线里对角线上的三处 2'h0 是占位符，核会覆盖它。
// =============================================================================

// BEGIN GENERATED(wrapper)
module RegCacheTagModule_1(
  input        clock,
  input        reset,
  input        io_readPorts_0_ren,
  input  [7:0] io_readPorts_0_tag,
  output       io_readPorts_0_valid,
  output [3:0] io_readPorts_0_addr,
  input        io_readPorts_1_ren,
  input  [7:0] io_readPorts_1_tag,
  output       io_readPorts_1_valid,
  output [3:0] io_readPorts_1_addr,
  input        io_readPorts_2_ren,
  input  [7:0] io_readPorts_2_tag,
  output       io_readPorts_2_valid,
  output [3:0] io_readPorts_2_addr,
  input        io_readPorts_3_ren,
  input  [7:0] io_readPorts_3_tag,
  output       io_readPorts_3_valid,
  output [3:0] io_readPorts_3_addr,
  input        io_readPorts_4_ren,
  input  [7:0] io_readPorts_4_tag,
  output       io_readPorts_4_valid,
  output [3:0] io_readPorts_4_addr,
  input        io_readPorts_5_ren,
  input  [7:0] io_readPorts_5_tag,
  output       io_readPorts_5_valid,
  output [3:0] io_readPorts_5_addr,
  input        io_readPorts_6_ren,
  input  [7:0] io_readPorts_6_tag,
  output       io_readPorts_6_valid,
  output [3:0] io_readPorts_6_addr,
  input        io_readPorts_7_ren,
  input  [7:0] io_readPorts_7_tag,
  output       io_readPorts_7_valid,
  output [3:0] io_readPorts_7_addr,
  input        io_readPorts_8_ren,
  input  [7:0] io_readPorts_8_tag,
  output       io_readPorts_8_valid,
  output [3:0] io_readPorts_8_addr,
  input        io_readPorts_9_ren,
  input  [7:0] io_readPorts_9_tag,
  output       io_readPorts_9_valid,
  output [3:0] io_readPorts_9_addr,
  input        io_readPorts_10_ren,
  input  [7:0] io_readPorts_10_tag,
  output       io_readPorts_10_valid,
  output [3:0] io_readPorts_10_addr,
  input        io_readPorts_11_ren,
  input  [7:0] io_readPorts_11_tag,
  output       io_readPorts_11_valid,
  output [3:0] io_readPorts_11_addr,
  input        io_writePorts_0_wen,
  input  [3:0] io_writePorts_0_addr,
  input  [7:0] io_writePorts_0_tag,
  input  [1:0] io_writePorts_0_loadDependency_1,
  input  [1:0] io_writePorts_0_loadDependency_2,
  input        io_writePorts_1_wen,
  input  [3:0] io_writePorts_1_addr,
  input  [7:0] io_writePorts_1_tag,
  input  [1:0] io_writePorts_1_loadDependency_0,
  input  [1:0] io_writePorts_1_loadDependency_2,
  input        io_writePorts_2_wen,
  input  [3:0] io_writePorts_2_addr,
  input  [7:0] io_writePorts_2_tag,
  input  [1:0] io_writePorts_2_loadDependency_0,
  input  [1:0] io_writePorts_2_loadDependency_1,
  input        io_cancelVec_0,
  input        io_cancelVec_1,
  input        io_cancelVec_2,
  input        io_cancelVec_3,
  input        io_cancelVec_4,
  input        io_cancelVec_5,
  input        io_cancelVec_6,
  input        io_cancelVec_7,
  input        io_cancelVec_8,
  input        io_cancelVec_9,
  input        io_cancelVec_10,
  input        io_cancelVec_11,
  output       io_validVec_0,
  output       io_validVec_1,
  output       io_validVec_2,
  output       io_validVec_3,
  output       io_validVec_4,
  output       io_validVec_5,
  output       io_validVec_6,
  output       io_validVec_7,
  output       io_validVec_8,
  output       io_validVec_9,
  output       io_validVec_10,
  output       io_validVec_11,
  output [7:0] io_tagVec_0,
  output [7:0] io_tagVec_1,
  output [7:0] io_tagVec_2,
  output [7:0] io_tagVec_3,
  output [7:0] io_tagVec_4,
  output [7:0] io_tagVec_5,
  output [7:0] io_tagVec_6,
  output [7:0] io_tagVec_7,
  output [7:0] io_tagVec_8,
  output [7:0] io_tagVec_9,
  output [7:0] io_tagVec_10,
  output [7:0] io_tagVec_11,
  output [1:0] io_loadDependencyVec_0_0,
  output [1:0] io_loadDependencyVec_0_1,
  output [1:0] io_loadDependencyVec_0_2,
  output [1:0] io_loadDependencyVec_1_0,
  output [1:0] io_loadDependencyVec_1_1,
  output [1:0] io_loadDependencyVec_1_2,
  output [1:0] io_loadDependencyVec_2_0,
  output [1:0] io_loadDependencyVec_2_1,
  output [1:0] io_loadDependencyVec_2_2,
  output [1:0] io_loadDependencyVec_3_0,
  output [1:0] io_loadDependencyVec_3_1,
  output [1:0] io_loadDependencyVec_3_2,
  output [1:0] io_loadDependencyVec_4_0,
  output [1:0] io_loadDependencyVec_4_1,
  output [1:0] io_loadDependencyVec_4_2,
  output [1:0] io_loadDependencyVec_5_0,
  output [1:0] io_loadDependencyVec_5_1,
  output [1:0] io_loadDependencyVec_5_2,
  output [1:0] io_loadDependencyVec_6_0,
  output [1:0] io_loadDependencyVec_6_1,
  output [1:0] io_loadDependencyVec_6_2,
  output [1:0] io_loadDependencyVec_7_0,
  output [1:0] io_loadDependencyVec_7_1,
  output [1:0] io_loadDependencyVec_7_2,
  output [1:0] io_loadDependencyVec_8_0,
  output [1:0] io_loadDependencyVec_8_1,
  output [1:0] io_loadDependencyVec_8_2,
  output [1:0] io_loadDependencyVec_9_0,
  output [1:0] io_loadDependencyVec_9_1,
  output [1:0] io_loadDependencyVec_9_2,
  output [1:0] io_loadDependencyVec_10_0,
  output [1:0] io_loadDependencyVec_10_1,
  output [1:0] io_loadDependencyVec_10_2,
  output [1:0] io_loadDependencyVec_11_0,
  output [1:0] io_loadDependencyVec_11_1,
  output [1:0] io_loadDependencyVec_11_2
);

  xs_RegCacheTagModule_core #(
    .NUM_ENTRIES(12), .NUM_WRITE(3), .NUM_READ(12),
    .SELF_DEP_DIAG(1'b1)
  ) u_core (
    .clock                 (clock),
    .reset                 (reset),
    .io_read_ren ({
      io_readPorts_11_ren, io_readPorts_10_ren, io_readPorts_9_ren, io_readPorts_8_ren,
      io_readPorts_7_ren, io_readPorts_6_ren, io_readPorts_5_ren, io_readPorts_4_ren,
      io_readPorts_3_ren, io_readPorts_2_ren, io_readPorts_1_ren, io_readPorts_0_ren
    }),
    .io_read_tag ({
      io_readPorts_11_tag, io_readPorts_10_tag, io_readPorts_9_tag, io_readPorts_8_tag,
      io_readPorts_7_tag, io_readPorts_6_tag, io_readPorts_5_tag, io_readPorts_4_tag,
      io_readPorts_3_tag, io_readPorts_2_tag, io_readPorts_1_tag, io_readPorts_0_tag
    }),
    .io_read_valid ({
      io_readPorts_11_valid, io_readPorts_10_valid, io_readPorts_9_valid, io_readPorts_8_valid,
      io_readPorts_7_valid, io_readPorts_6_valid, io_readPorts_5_valid, io_readPorts_4_valid,
      io_readPorts_3_valid, io_readPorts_2_valid, io_readPorts_1_valid, io_readPorts_0_valid
    }),
    .io_read_addr ({
      io_readPorts_11_addr, io_readPorts_10_addr, io_readPorts_9_addr, io_readPorts_8_addr,
      io_readPorts_7_addr, io_readPorts_6_addr, io_readPorts_5_addr, io_readPorts_4_addr,
      io_readPorts_3_addr, io_readPorts_2_addr, io_readPorts_1_addr, io_readPorts_0_addr
    }),
    .io_write_wen          ({io_writePorts_2_wen, io_writePorts_1_wen, io_writePorts_0_wen}),
    .io_write_addr         ({io_writePorts_2_addr, io_writePorts_1_addr, io_writePorts_0_addr}),
    .io_write_tag          ({io_writePorts_2_tag, io_writePorts_1_tag, io_writePorts_0_tag}),
    .io_write_loadDependency ({
      {2'h0, io_writePorts_2_loadDependency_1, io_writePorts_2_loadDependency_0},
      {io_writePorts_1_loadDependency_2, 2'h0, io_writePorts_1_loadDependency_0},
      {io_writePorts_0_loadDependency_2, io_writePorts_0_loadDependency_1, 2'h0}
    }),
    .io_cancelVec ({
      io_cancelVec_11, io_cancelVec_10, io_cancelVec_9, io_cancelVec_8, io_cancelVec_7,
      io_cancelVec_6, io_cancelVec_5, io_cancelVec_4, io_cancelVec_3, io_cancelVec_2,
      io_cancelVec_1, io_cancelVec_0
    }),
    .io_validVec ({
      io_validVec_11, io_validVec_10, io_validVec_9, io_validVec_8, io_validVec_7, io_validVec_6,
      io_validVec_5, io_validVec_4, io_validVec_3, io_validVec_2, io_validVec_1, io_validVec_0
    }),
    .io_tagVec ({
      io_tagVec_11, io_tagVec_10, io_tagVec_9, io_tagVec_8, io_tagVec_7, io_tagVec_6,
      io_tagVec_5, io_tagVec_4, io_tagVec_3, io_tagVec_2, io_tagVec_1, io_tagVec_0
    }),
    .io_loadDependencyVec ({
      {io_loadDependencyVec_11_2, io_loadDependencyVec_11_1, io_loadDependencyVec_11_0},
      {io_loadDependencyVec_10_2, io_loadDependencyVec_10_1, io_loadDependencyVec_10_0},
      {io_loadDependencyVec_9_2, io_loadDependencyVec_9_1, io_loadDependencyVec_9_0},
      {io_loadDependencyVec_8_2, io_loadDependencyVec_8_1, io_loadDependencyVec_8_0},
      {io_loadDependencyVec_7_2, io_loadDependencyVec_7_1, io_loadDependencyVec_7_0},
      {io_loadDependencyVec_6_2, io_loadDependencyVec_6_1, io_loadDependencyVec_6_0},
      {io_loadDependencyVec_5_2, io_loadDependencyVec_5_1, io_loadDependencyVec_5_0},
      {io_loadDependencyVec_4_2, io_loadDependencyVec_4_1, io_loadDependencyVec_4_0},
      {io_loadDependencyVec_3_2, io_loadDependencyVec_3_1, io_loadDependencyVec_3_0},
      {io_loadDependencyVec_2_2, io_loadDependencyVec_2_1, io_loadDependencyVec_2_0},
      {io_loadDependencyVec_1_2, io_loadDependencyVec_1_1, io_loadDependencyVec_1_0},
      {io_loadDependencyVec_0_2, io_loadDependencyVec_0_1, io_loadDependencyVec_0_0}
    })
  );

endmodule
// END GENERATED
