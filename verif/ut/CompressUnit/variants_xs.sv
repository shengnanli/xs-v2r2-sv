// CompressUnit_xs —— UT 用可读核包装(golden 同端口,改名避免与 golden 冲突)。
// 由 scripts/gen_compressunit.py --xs 生成。仅端口适配,无算法逻辑。
import compressunit_pkg::*;

module CompressUnit_xs (
  input         io_in_0_valid,
  input         io_in_0_bits_exceptionVec_0,
  input         io_in_0_bits_exceptionVec_1,
  input         io_in_0_bits_exceptionVec_2,
  input         io_in_0_bits_exceptionVec_3,
  input         io_in_0_bits_exceptionVec_4,
  input         io_in_0_bits_exceptionVec_5,
  input         io_in_0_bits_exceptionVec_6,
  input         io_in_0_bits_exceptionVec_7,
  input         io_in_0_bits_exceptionVec_8,
  input         io_in_0_bits_exceptionVec_9,
  input         io_in_0_bits_exceptionVec_10,
  input         io_in_0_bits_exceptionVec_11,
  input         io_in_0_bits_exceptionVec_12,
  input         io_in_0_bits_exceptionVec_13,
  input         io_in_0_bits_exceptionVec_14,
  input         io_in_0_bits_exceptionVec_15,
  input         io_in_0_bits_exceptionVec_16,
  input         io_in_0_bits_exceptionVec_17,
  input         io_in_0_bits_exceptionVec_18,
  input         io_in_0_bits_exceptionVec_19,
  input         io_in_0_bits_exceptionVec_20,
  input         io_in_0_bits_exceptionVec_21,
  input         io_in_0_bits_exceptionVec_22,
  input         io_in_0_bits_exceptionVec_23,
  input  [3:0]  io_in_0_bits_trigger,
  input         io_in_0_bits_canRobCompress,
  input         io_in_0_bits_lastUop,
  input  [2:0]  io_in_0_bits_commitType,
  input         io_in_1_valid,
  input         io_in_1_bits_exceptionVec_0,
  input         io_in_1_bits_exceptionVec_1,
  input         io_in_1_bits_exceptionVec_2,
  input         io_in_1_bits_exceptionVec_3,
  input         io_in_1_bits_exceptionVec_4,
  input         io_in_1_bits_exceptionVec_5,
  input         io_in_1_bits_exceptionVec_6,
  input         io_in_1_bits_exceptionVec_7,
  input         io_in_1_bits_exceptionVec_8,
  input         io_in_1_bits_exceptionVec_9,
  input         io_in_1_bits_exceptionVec_10,
  input         io_in_1_bits_exceptionVec_11,
  input         io_in_1_bits_exceptionVec_12,
  input         io_in_1_bits_exceptionVec_13,
  input         io_in_1_bits_exceptionVec_14,
  input         io_in_1_bits_exceptionVec_15,
  input         io_in_1_bits_exceptionVec_16,
  input         io_in_1_bits_exceptionVec_17,
  input         io_in_1_bits_exceptionVec_18,
  input         io_in_1_bits_exceptionVec_19,
  input         io_in_1_bits_exceptionVec_20,
  input         io_in_1_bits_exceptionVec_21,
  input         io_in_1_bits_exceptionVec_22,
  input         io_in_1_bits_exceptionVec_23,
  input  [3:0]  io_in_1_bits_trigger,
  input         io_in_1_bits_canRobCompress,
  input         io_in_1_bits_lastUop,
  input  [2:0]  io_in_1_bits_commitType,
  input         io_in_2_valid,
  input         io_in_2_bits_exceptionVec_0,
  input         io_in_2_bits_exceptionVec_1,
  input         io_in_2_bits_exceptionVec_2,
  input         io_in_2_bits_exceptionVec_3,
  input         io_in_2_bits_exceptionVec_4,
  input         io_in_2_bits_exceptionVec_5,
  input         io_in_2_bits_exceptionVec_6,
  input         io_in_2_bits_exceptionVec_7,
  input         io_in_2_bits_exceptionVec_8,
  input         io_in_2_bits_exceptionVec_9,
  input         io_in_2_bits_exceptionVec_10,
  input         io_in_2_bits_exceptionVec_11,
  input         io_in_2_bits_exceptionVec_12,
  input         io_in_2_bits_exceptionVec_13,
  input         io_in_2_bits_exceptionVec_14,
  input         io_in_2_bits_exceptionVec_15,
  input         io_in_2_bits_exceptionVec_16,
  input         io_in_2_bits_exceptionVec_17,
  input         io_in_2_bits_exceptionVec_18,
  input         io_in_2_bits_exceptionVec_19,
  input         io_in_2_bits_exceptionVec_20,
  input         io_in_2_bits_exceptionVec_21,
  input         io_in_2_bits_exceptionVec_22,
  input         io_in_2_bits_exceptionVec_23,
  input  [3:0]  io_in_2_bits_trigger,
  input         io_in_2_bits_canRobCompress,
  input         io_in_2_bits_lastUop,
  input  [2:0]  io_in_2_bits_commitType,
  input         io_in_3_valid,
  input         io_in_3_bits_exceptionVec_0,
  input         io_in_3_bits_exceptionVec_1,
  input         io_in_3_bits_exceptionVec_2,
  input         io_in_3_bits_exceptionVec_3,
  input         io_in_3_bits_exceptionVec_4,
  input         io_in_3_bits_exceptionVec_5,
  input         io_in_3_bits_exceptionVec_6,
  input         io_in_3_bits_exceptionVec_7,
  input         io_in_3_bits_exceptionVec_8,
  input         io_in_3_bits_exceptionVec_9,
  input         io_in_3_bits_exceptionVec_10,
  input         io_in_3_bits_exceptionVec_11,
  input         io_in_3_bits_exceptionVec_12,
  input         io_in_3_bits_exceptionVec_13,
  input         io_in_3_bits_exceptionVec_14,
  input         io_in_3_bits_exceptionVec_15,
  input         io_in_3_bits_exceptionVec_16,
  input         io_in_3_bits_exceptionVec_17,
  input         io_in_3_bits_exceptionVec_18,
  input         io_in_3_bits_exceptionVec_19,
  input         io_in_3_bits_exceptionVec_20,
  input         io_in_3_bits_exceptionVec_21,
  input         io_in_3_bits_exceptionVec_22,
  input         io_in_3_bits_exceptionVec_23,
  input  [3:0]  io_in_3_bits_trigger,
  input         io_in_3_bits_canRobCompress,
  input         io_in_3_bits_lastUop,
  input  [2:0]  io_in_3_bits_commitType,
  input         io_in_4_valid,
  input         io_in_4_bits_exceptionVec_0,
  input         io_in_4_bits_exceptionVec_1,
  input         io_in_4_bits_exceptionVec_2,
  input         io_in_4_bits_exceptionVec_3,
  input         io_in_4_bits_exceptionVec_4,
  input         io_in_4_bits_exceptionVec_5,
  input         io_in_4_bits_exceptionVec_6,
  input         io_in_4_bits_exceptionVec_7,
  input         io_in_4_bits_exceptionVec_8,
  input         io_in_4_bits_exceptionVec_9,
  input         io_in_4_bits_exceptionVec_10,
  input         io_in_4_bits_exceptionVec_11,
  input         io_in_4_bits_exceptionVec_12,
  input         io_in_4_bits_exceptionVec_13,
  input         io_in_4_bits_exceptionVec_14,
  input         io_in_4_bits_exceptionVec_15,
  input         io_in_4_bits_exceptionVec_16,
  input         io_in_4_bits_exceptionVec_17,
  input         io_in_4_bits_exceptionVec_18,
  input         io_in_4_bits_exceptionVec_19,
  input         io_in_4_bits_exceptionVec_20,
  input         io_in_4_bits_exceptionVec_21,
  input         io_in_4_bits_exceptionVec_22,
  input         io_in_4_bits_exceptionVec_23,
  input  [3:0]  io_in_4_bits_trigger,
  input         io_in_4_bits_canRobCompress,
  input         io_in_4_bits_lastUop,
  input  [2:0]  io_in_4_bits_commitType,
  input         io_in_5_valid,
  input         io_in_5_bits_exceptionVec_0,
  input         io_in_5_bits_exceptionVec_1,
  input         io_in_5_bits_exceptionVec_2,
  input         io_in_5_bits_exceptionVec_3,
  input         io_in_5_bits_exceptionVec_4,
  input         io_in_5_bits_exceptionVec_5,
  input         io_in_5_bits_exceptionVec_6,
  input         io_in_5_bits_exceptionVec_7,
  input         io_in_5_bits_exceptionVec_8,
  input         io_in_5_bits_exceptionVec_9,
  input         io_in_5_bits_exceptionVec_10,
  input         io_in_5_bits_exceptionVec_11,
  input         io_in_5_bits_exceptionVec_12,
  input         io_in_5_bits_exceptionVec_13,
  input         io_in_5_bits_exceptionVec_14,
  input         io_in_5_bits_exceptionVec_15,
  input         io_in_5_bits_exceptionVec_16,
  input         io_in_5_bits_exceptionVec_17,
  input         io_in_5_bits_exceptionVec_18,
  input         io_in_5_bits_exceptionVec_19,
  input         io_in_5_bits_exceptionVec_20,
  input         io_in_5_bits_exceptionVec_21,
  input         io_in_5_bits_exceptionVec_22,
  input         io_in_5_bits_exceptionVec_23,
  input  [3:0]  io_in_5_bits_trigger,
  input         io_in_5_bits_canRobCompress,
  input         io_in_5_bits_lastUop,
  input  [2:0]  io_in_5_bits_commitType,
  output        io_out_needRobFlags_0,
  output        io_out_needRobFlags_1,
  output        io_out_needRobFlags_2,
  output        io_out_needRobFlags_3,
  output        io_out_needRobFlags_4,
  output        io_out_needRobFlags_5,
  output [2:0]  io_out_instrSizes_0,
  output [2:0]  io_out_instrSizes_1,
  output [2:0]  io_out_instrSizes_2,
  output [2:0]  io_out_instrSizes_3,
  output [2:0]  io_out_instrSizes_4,
  output [2:0]  io_out_instrSizes_5,
  output [5:0]  io_out_masks_0,
  output [5:0]  io_out_masks_1,
  output [5:0]  io_out_masks_2,
  output [5:0]  io_out_masks_3,
  output [5:0]  io_out_masks_4,
  output [5:0]  io_out_masks_5,
  output        io_out_canCompressVec_0,
  output        io_out_canCompressVec_1,
  output        io_out_canCompressVec_2,
  output        io_out_canCompressVec_3,
  output        io_out_canCompressVec_4,
  output        io_out_canCompressVec_5
);

  compress_in_t [RENAME_WIDTH-1:0] in_w;
  logic [RENAME_WIDTH-1:0]             ccv, nrf;
  logic [RENAME_WIDTH-1:0][SIZE_W-1:0] sizes;
  logic [RENAME_WIDTH-1:0][MASK_W-1:0] masks_w;

  assign in_w[0] = '{
    valid:          io_in_0_valid,
    exceptionVec:   {io_in_0_bits_exceptionVec_23, io_in_0_bits_exceptionVec_22, io_in_0_bits_exceptionVec_21, io_in_0_bits_exceptionVec_20, io_in_0_bits_exceptionVec_19, io_in_0_bits_exceptionVec_18, io_in_0_bits_exceptionVec_17, io_in_0_bits_exceptionVec_16, io_in_0_bits_exceptionVec_15, io_in_0_bits_exceptionVec_14, io_in_0_bits_exceptionVec_13, io_in_0_bits_exceptionVec_12, io_in_0_bits_exceptionVec_11, io_in_0_bits_exceptionVec_10, io_in_0_bits_exceptionVec_9, io_in_0_bits_exceptionVec_8, io_in_0_bits_exceptionVec_7, io_in_0_bits_exceptionVec_6, io_in_0_bits_exceptionVec_5, io_in_0_bits_exceptionVec_4, io_in_0_bits_exceptionVec_3, io_in_0_bits_exceptionVec_2, io_in_0_bits_exceptionVec_1, io_in_0_bits_exceptionVec_0},
    trigger:        io_in_0_bits_trigger,
    canRobCompress: io_in_0_bits_canRobCompress,
    lastUop:        io_in_0_bits_lastUop,
    commitType:     io_in_0_bits_commitType
  };
  assign in_w[1] = '{
    valid:          io_in_1_valid,
    exceptionVec:   {io_in_1_bits_exceptionVec_23, io_in_1_bits_exceptionVec_22, io_in_1_bits_exceptionVec_21, io_in_1_bits_exceptionVec_20, io_in_1_bits_exceptionVec_19, io_in_1_bits_exceptionVec_18, io_in_1_bits_exceptionVec_17, io_in_1_bits_exceptionVec_16, io_in_1_bits_exceptionVec_15, io_in_1_bits_exceptionVec_14, io_in_1_bits_exceptionVec_13, io_in_1_bits_exceptionVec_12, io_in_1_bits_exceptionVec_11, io_in_1_bits_exceptionVec_10, io_in_1_bits_exceptionVec_9, io_in_1_bits_exceptionVec_8, io_in_1_bits_exceptionVec_7, io_in_1_bits_exceptionVec_6, io_in_1_bits_exceptionVec_5, io_in_1_bits_exceptionVec_4, io_in_1_bits_exceptionVec_3, io_in_1_bits_exceptionVec_2, io_in_1_bits_exceptionVec_1, io_in_1_bits_exceptionVec_0},
    trigger:        io_in_1_bits_trigger,
    canRobCompress: io_in_1_bits_canRobCompress,
    lastUop:        io_in_1_bits_lastUop,
    commitType:     io_in_1_bits_commitType
  };
  assign in_w[2] = '{
    valid:          io_in_2_valid,
    exceptionVec:   {io_in_2_bits_exceptionVec_23, io_in_2_bits_exceptionVec_22, io_in_2_bits_exceptionVec_21, io_in_2_bits_exceptionVec_20, io_in_2_bits_exceptionVec_19, io_in_2_bits_exceptionVec_18, io_in_2_bits_exceptionVec_17, io_in_2_bits_exceptionVec_16, io_in_2_bits_exceptionVec_15, io_in_2_bits_exceptionVec_14, io_in_2_bits_exceptionVec_13, io_in_2_bits_exceptionVec_12, io_in_2_bits_exceptionVec_11, io_in_2_bits_exceptionVec_10, io_in_2_bits_exceptionVec_9, io_in_2_bits_exceptionVec_8, io_in_2_bits_exceptionVec_7, io_in_2_bits_exceptionVec_6, io_in_2_bits_exceptionVec_5, io_in_2_bits_exceptionVec_4, io_in_2_bits_exceptionVec_3, io_in_2_bits_exceptionVec_2, io_in_2_bits_exceptionVec_1, io_in_2_bits_exceptionVec_0},
    trigger:        io_in_2_bits_trigger,
    canRobCompress: io_in_2_bits_canRobCompress,
    lastUop:        io_in_2_bits_lastUop,
    commitType:     io_in_2_bits_commitType
  };
  assign in_w[3] = '{
    valid:          io_in_3_valid,
    exceptionVec:   {io_in_3_bits_exceptionVec_23, io_in_3_bits_exceptionVec_22, io_in_3_bits_exceptionVec_21, io_in_3_bits_exceptionVec_20, io_in_3_bits_exceptionVec_19, io_in_3_bits_exceptionVec_18, io_in_3_bits_exceptionVec_17, io_in_3_bits_exceptionVec_16, io_in_3_bits_exceptionVec_15, io_in_3_bits_exceptionVec_14, io_in_3_bits_exceptionVec_13, io_in_3_bits_exceptionVec_12, io_in_3_bits_exceptionVec_11, io_in_3_bits_exceptionVec_10, io_in_3_bits_exceptionVec_9, io_in_3_bits_exceptionVec_8, io_in_3_bits_exceptionVec_7, io_in_3_bits_exceptionVec_6, io_in_3_bits_exceptionVec_5, io_in_3_bits_exceptionVec_4, io_in_3_bits_exceptionVec_3, io_in_3_bits_exceptionVec_2, io_in_3_bits_exceptionVec_1, io_in_3_bits_exceptionVec_0},
    trigger:        io_in_3_bits_trigger,
    canRobCompress: io_in_3_bits_canRobCompress,
    lastUop:        io_in_3_bits_lastUop,
    commitType:     io_in_3_bits_commitType
  };
  assign in_w[4] = '{
    valid:          io_in_4_valid,
    exceptionVec:   {io_in_4_bits_exceptionVec_23, io_in_4_bits_exceptionVec_22, io_in_4_bits_exceptionVec_21, io_in_4_bits_exceptionVec_20, io_in_4_bits_exceptionVec_19, io_in_4_bits_exceptionVec_18, io_in_4_bits_exceptionVec_17, io_in_4_bits_exceptionVec_16, io_in_4_bits_exceptionVec_15, io_in_4_bits_exceptionVec_14, io_in_4_bits_exceptionVec_13, io_in_4_bits_exceptionVec_12, io_in_4_bits_exceptionVec_11, io_in_4_bits_exceptionVec_10, io_in_4_bits_exceptionVec_9, io_in_4_bits_exceptionVec_8, io_in_4_bits_exceptionVec_7, io_in_4_bits_exceptionVec_6, io_in_4_bits_exceptionVec_5, io_in_4_bits_exceptionVec_4, io_in_4_bits_exceptionVec_3, io_in_4_bits_exceptionVec_2, io_in_4_bits_exceptionVec_1, io_in_4_bits_exceptionVec_0},
    trigger:        io_in_4_bits_trigger,
    canRobCompress: io_in_4_bits_canRobCompress,
    lastUop:        io_in_4_bits_lastUop,
    commitType:     io_in_4_bits_commitType
  };
  assign in_w[5] = '{
    valid:          io_in_5_valid,
    exceptionVec:   {io_in_5_bits_exceptionVec_23, io_in_5_bits_exceptionVec_22, io_in_5_bits_exceptionVec_21, io_in_5_bits_exceptionVec_20, io_in_5_bits_exceptionVec_19, io_in_5_bits_exceptionVec_18, io_in_5_bits_exceptionVec_17, io_in_5_bits_exceptionVec_16, io_in_5_bits_exceptionVec_15, io_in_5_bits_exceptionVec_14, io_in_5_bits_exceptionVec_13, io_in_5_bits_exceptionVec_12, io_in_5_bits_exceptionVec_11, io_in_5_bits_exceptionVec_10, io_in_5_bits_exceptionVec_9, io_in_5_bits_exceptionVec_8, io_in_5_bits_exceptionVec_7, io_in_5_bits_exceptionVec_6, io_in_5_bits_exceptionVec_5, io_in_5_bits_exceptionVec_4, io_in_5_bits_exceptionVec_3, io_in_5_bits_exceptionVec_2, io_in_5_bits_exceptionVec_1, io_in_5_bits_exceptionVec_0},
    trigger:        io_in_5_bits_trigger,
    canRobCompress: io_in_5_bits_canRobCompress,
    lastUop:        io_in_5_bits_lastUop,
    commitType:     io_in_5_bits_commitType
  };

  xs_CompressUnit_core u_core (
    .in               (in_w),
    .can_compress_vec (ccv),
    .need_rob_flags   (nrf),
    .instr_sizes      (sizes),
    .masks            (masks_w)
  );

  assign io_out_needRobFlags_0    = nrf[0];
  assign io_out_needRobFlags_1    = nrf[1];
  assign io_out_needRobFlags_2    = nrf[2];
  assign io_out_needRobFlags_3    = nrf[3];
  assign io_out_needRobFlags_4    = nrf[4];
  assign io_out_needRobFlags_5    = nrf[5];
  assign io_out_instrSizes_0      = sizes[0];
  assign io_out_instrSizes_1      = sizes[1];
  assign io_out_instrSizes_2      = sizes[2];
  assign io_out_instrSizes_3      = sizes[3];
  assign io_out_instrSizes_4      = sizes[4];
  assign io_out_instrSizes_5      = sizes[5];
  assign io_out_masks_0           = masks_w[0];
  assign io_out_masks_1           = masks_w[1];
  assign io_out_masks_2           = masks_w[2];
  assign io_out_masks_3           = masks_w[3];
  assign io_out_masks_4           = masks_w[4];
  assign io_out_masks_5           = masks_w[5];
  assign io_out_canCompressVec_0  = ccv[0];
  assign io_out_canCompressVec_1  = ccv[1];
  assign io_out_canCompressVec_2  = ccv[2];
  assign io_out_canCompressVec_3  = ccv[3];
  assign io_out_canCompressVec_4  = ccv[4];
  assign io_out_canCompressVec_5  = ccv[5];

endmodule
