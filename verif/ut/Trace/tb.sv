// 自动生成: Trace UT: golden vs 可读核 _xs 逐拍逐输出比对(共享 golden TraceBuffer)。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic reset;
  logic io_in_fromEncoder_enable;
  logic io_in_fromEncoder_stall;
  logic io_in_fromRob_blocks_0_valid;
  logic [5:0] io_in_fromRob_blocks_0_bits_ftqIdx_value;
  logic [3:0] io_in_fromRob_blocks_0_bits_ftqOffset;
  logic [3:0] io_in_fromRob_blocks_0_bits_tracePipe_itype;
  logic [3:0] io_in_fromRob_blocks_0_bits_tracePipe_iretire;
  logic io_in_fromRob_blocks_0_bits_tracePipe_ilastsize;
  logic io_in_fromRob_blocks_1_valid;
  logic [5:0] io_in_fromRob_blocks_1_bits_ftqIdx_value;
  logic [3:0] io_in_fromRob_blocks_1_bits_ftqOffset;
  logic [3:0] io_in_fromRob_blocks_1_bits_tracePipe_itype;
  logic [3:0] io_in_fromRob_blocks_1_bits_tracePipe_iretire;
  logic io_in_fromRob_blocks_1_bits_tracePipe_ilastsize;
  logic io_in_fromRob_blocks_2_valid;
  logic [5:0] io_in_fromRob_blocks_2_bits_ftqIdx_value;
  logic [3:0] io_in_fromRob_blocks_2_bits_ftqOffset;
  logic [3:0] io_in_fromRob_blocks_2_bits_tracePipe_itype;
  logic [3:0] io_in_fromRob_blocks_2_bits_tracePipe_iretire;
  logic io_in_fromRob_blocks_2_bits_tracePipe_ilastsize;
  logic io_in_fromRob_blocks_3_valid;
  logic [5:0] io_in_fromRob_blocks_3_bits_ftqIdx_value;
  logic [3:0] io_in_fromRob_blocks_3_bits_ftqOffset;
  logic [3:0] io_in_fromRob_blocks_3_bits_tracePipe_itype;
  logic [3:0] io_in_fromRob_blocks_3_bits_tracePipe_iretire;
  logic io_in_fromRob_blocks_3_bits_tracePipe_ilastsize;
  logic io_in_fromRob_blocks_4_valid;
  logic [5:0] io_in_fromRob_blocks_4_bits_ftqIdx_value;
  logic [3:0] io_in_fromRob_blocks_4_bits_ftqOffset;
  logic [3:0] io_in_fromRob_blocks_4_bits_tracePipe_itype;
  logic [3:0] io_in_fromRob_blocks_4_bits_tracePipe_iretire;
  logic io_in_fromRob_blocks_4_bits_tracePipe_ilastsize;
  logic io_in_fromRob_blocks_5_valid;
  logic [5:0] io_in_fromRob_blocks_5_bits_ftqIdx_value;
  logic [3:0] io_in_fromRob_blocks_5_bits_ftqOffset;
  logic [3:0] io_in_fromRob_blocks_5_bits_tracePipe_itype;
  logic [3:0] io_in_fromRob_blocks_5_bits_tracePipe_iretire;
  logic io_in_fromRob_blocks_5_bits_tracePipe_ilastsize;
  logic io_in_fromRob_blocks_6_valid;
  logic [5:0] io_in_fromRob_blocks_6_bits_ftqIdx_value;
  logic [3:0] io_in_fromRob_blocks_6_bits_ftqOffset;
  logic [3:0] io_in_fromRob_blocks_6_bits_tracePipe_itype;
  logic [3:0] io_in_fromRob_blocks_6_bits_tracePipe_iretire;
  logic io_in_fromRob_blocks_6_bits_tracePipe_ilastsize;
  logic io_in_fromRob_blocks_7_valid;
  logic [5:0] io_in_fromRob_blocks_7_bits_ftqIdx_value;
  logic [3:0] io_in_fromRob_blocks_7_bits_ftqOffset;
  logic [3:0] io_in_fromRob_blocks_7_bits_tracePipe_itype;
  logic [3:0] io_in_fromRob_blocks_7_bits_tracePipe_iretire;
  logic io_in_fromRob_blocks_7_bits_tracePipe_ilastsize;
  logic g_io_out_toPcMem_blocks_0_valid;
  logic [5:0] g_io_out_toPcMem_blocks_0_bits_ftqIdx_value;
  logic g_io_out_toPcMem_blocks_1_valid;
  logic [5:0] g_io_out_toPcMem_blocks_1_bits_ftqIdx_value;
  logic g_io_out_toPcMem_blocks_2_valid;
  logic [5:0] g_io_out_toPcMem_blocks_2_bits_ftqIdx_value;
  logic g_io_out_toEncoder_blocks_0_valid;
  logic [3:0] g_io_out_toEncoder_blocks_0_bits_ftqOffset;
  logic [3:0] g_io_out_toEncoder_blocks_0_bits_tracePipe_itype;
  logic [6:0] g_io_out_toEncoder_blocks_0_bits_tracePipe_iretire;
  logic g_io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize;
  logic g_io_out_toEncoder_blocks_1_valid;
  logic [3:0] g_io_out_toEncoder_blocks_1_bits_ftqOffset;
  logic [3:0] g_io_out_toEncoder_blocks_1_bits_tracePipe_itype;
  logic [6:0] g_io_out_toEncoder_blocks_1_bits_tracePipe_iretire;
  logic g_io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize;
  logic g_io_out_toEncoder_blocks_2_valid;
  logic [3:0] g_io_out_toEncoder_blocks_2_bits_ftqOffset;
  logic [3:0] g_io_out_toEncoder_blocks_2_bits_tracePipe_itype;
  logic [6:0] g_io_out_toEncoder_blocks_2_bits_tracePipe_iretire;
  logic g_io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize;
  logic g_io_out_blockRobCommit;
  logic i_io_out_toPcMem_blocks_0_valid;
  logic [5:0] i_io_out_toPcMem_blocks_0_bits_ftqIdx_value;
  logic i_io_out_toPcMem_blocks_1_valid;
  logic [5:0] i_io_out_toPcMem_blocks_1_bits_ftqIdx_value;
  logic i_io_out_toPcMem_blocks_2_valid;
  logic [5:0] i_io_out_toPcMem_blocks_2_bits_ftqIdx_value;
  logic i_io_out_toEncoder_blocks_0_valid;
  logic [3:0] i_io_out_toEncoder_blocks_0_bits_ftqOffset;
  logic [3:0] i_io_out_toEncoder_blocks_0_bits_tracePipe_itype;
  logic [6:0] i_io_out_toEncoder_blocks_0_bits_tracePipe_iretire;
  logic i_io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize;
  logic i_io_out_toEncoder_blocks_1_valid;
  logic [3:0] i_io_out_toEncoder_blocks_1_bits_ftqOffset;
  logic [3:0] i_io_out_toEncoder_blocks_1_bits_tracePipe_itype;
  logic [6:0] i_io_out_toEncoder_blocks_1_bits_tracePipe_iretire;
  logic i_io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize;
  logic i_io_out_toEncoder_blocks_2_valid;
  logic [3:0] i_io_out_toEncoder_blocks_2_bits_ftqOffset;
  logic [3:0] i_io_out_toEncoder_blocks_2_bits_tracePipe_itype;
  logic [6:0] i_io_out_toEncoder_blocks_2_bits_tracePipe_iretire;
  logic i_io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize;
  logic i_io_out_blockRobCommit;

  Trace u_g (
    .clock(clk),
    .reset(reset),
    .io_in_fromEncoder_enable(io_in_fromEncoder_enable),
    .io_in_fromEncoder_stall(io_in_fromEncoder_stall),
    .io_in_fromRob_blocks_0_valid(io_in_fromRob_blocks_0_valid),
    .io_in_fromRob_blocks_0_bits_ftqIdx_value(io_in_fromRob_blocks_0_bits_ftqIdx_value),
    .io_in_fromRob_blocks_0_bits_ftqOffset(io_in_fromRob_blocks_0_bits_ftqOffset),
    .io_in_fromRob_blocks_0_bits_tracePipe_itype(io_in_fromRob_blocks_0_bits_tracePipe_itype),
    .io_in_fromRob_blocks_0_bits_tracePipe_iretire(io_in_fromRob_blocks_0_bits_tracePipe_iretire),
    .io_in_fromRob_blocks_0_bits_tracePipe_ilastsize(io_in_fromRob_blocks_0_bits_tracePipe_ilastsize),
    .io_in_fromRob_blocks_1_valid(io_in_fromRob_blocks_1_valid),
    .io_in_fromRob_blocks_1_bits_ftqIdx_value(io_in_fromRob_blocks_1_bits_ftqIdx_value),
    .io_in_fromRob_blocks_1_bits_ftqOffset(io_in_fromRob_blocks_1_bits_ftqOffset),
    .io_in_fromRob_blocks_1_bits_tracePipe_itype(io_in_fromRob_blocks_1_bits_tracePipe_itype),
    .io_in_fromRob_blocks_1_bits_tracePipe_iretire(io_in_fromRob_blocks_1_bits_tracePipe_iretire),
    .io_in_fromRob_blocks_1_bits_tracePipe_ilastsize(io_in_fromRob_blocks_1_bits_tracePipe_ilastsize),
    .io_in_fromRob_blocks_2_valid(io_in_fromRob_blocks_2_valid),
    .io_in_fromRob_blocks_2_bits_ftqIdx_value(io_in_fromRob_blocks_2_bits_ftqIdx_value),
    .io_in_fromRob_blocks_2_bits_ftqOffset(io_in_fromRob_blocks_2_bits_ftqOffset),
    .io_in_fromRob_blocks_2_bits_tracePipe_itype(io_in_fromRob_blocks_2_bits_tracePipe_itype),
    .io_in_fromRob_blocks_2_bits_tracePipe_iretire(io_in_fromRob_blocks_2_bits_tracePipe_iretire),
    .io_in_fromRob_blocks_2_bits_tracePipe_ilastsize(io_in_fromRob_blocks_2_bits_tracePipe_ilastsize),
    .io_in_fromRob_blocks_3_valid(io_in_fromRob_blocks_3_valid),
    .io_in_fromRob_blocks_3_bits_ftqIdx_value(io_in_fromRob_blocks_3_bits_ftqIdx_value),
    .io_in_fromRob_blocks_3_bits_ftqOffset(io_in_fromRob_blocks_3_bits_ftqOffset),
    .io_in_fromRob_blocks_3_bits_tracePipe_itype(io_in_fromRob_blocks_3_bits_tracePipe_itype),
    .io_in_fromRob_blocks_3_bits_tracePipe_iretire(io_in_fromRob_blocks_3_bits_tracePipe_iretire),
    .io_in_fromRob_blocks_3_bits_tracePipe_ilastsize(io_in_fromRob_blocks_3_bits_tracePipe_ilastsize),
    .io_in_fromRob_blocks_4_valid(io_in_fromRob_blocks_4_valid),
    .io_in_fromRob_blocks_4_bits_ftqIdx_value(io_in_fromRob_blocks_4_bits_ftqIdx_value),
    .io_in_fromRob_blocks_4_bits_ftqOffset(io_in_fromRob_blocks_4_bits_ftqOffset),
    .io_in_fromRob_blocks_4_bits_tracePipe_itype(io_in_fromRob_blocks_4_bits_tracePipe_itype),
    .io_in_fromRob_blocks_4_bits_tracePipe_iretire(io_in_fromRob_blocks_4_bits_tracePipe_iretire),
    .io_in_fromRob_blocks_4_bits_tracePipe_ilastsize(io_in_fromRob_blocks_4_bits_tracePipe_ilastsize),
    .io_in_fromRob_blocks_5_valid(io_in_fromRob_blocks_5_valid),
    .io_in_fromRob_blocks_5_bits_ftqIdx_value(io_in_fromRob_blocks_5_bits_ftqIdx_value),
    .io_in_fromRob_blocks_5_bits_ftqOffset(io_in_fromRob_blocks_5_bits_ftqOffset),
    .io_in_fromRob_blocks_5_bits_tracePipe_itype(io_in_fromRob_blocks_5_bits_tracePipe_itype),
    .io_in_fromRob_blocks_5_bits_tracePipe_iretire(io_in_fromRob_blocks_5_bits_tracePipe_iretire),
    .io_in_fromRob_blocks_5_bits_tracePipe_ilastsize(io_in_fromRob_blocks_5_bits_tracePipe_ilastsize),
    .io_in_fromRob_blocks_6_valid(io_in_fromRob_blocks_6_valid),
    .io_in_fromRob_blocks_6_bits_ftqIdx_value(io_in_fromRob_blocks_6_bits_ftqIdx_value),
    .io_in_fromRob_blocks_6_bits_ftqOffset(io_in_fromRob_blocks_6_bits_ftqOffset),
    .io_in_fromRob_blocks_6_bits_tracePipe_itype(io_in_fromRob_blocks_6_bits_tracePipe_itype),
    .io_in_fromRob_blocks_6_bits_tracePipe_iretire(io_in_fromRob_blocks_6_bits_tracePipe_iretire),
    .io_in_fromRob_blocks_6_bits_tracePipe_ilastsize(io_in_fromRob_blocks_6_bits_tracePipe_ilastsize),
    .io_in_fromRob_blocks_7_valid(io_in_fromRob_blocks_7_valid),
    .io_in_fromRob_blocks_7_bits_ftqIdx_value(io_in_fromRob_blocks_7_bits_ftqIdx_value),
    .io_in_fromRob_blocks_7_bits_ftqOffset(io_in_fromRob_blocks_7_bits_ftqOffset),
    .io_in_fromRob_blocks_7_bits_tracePipe_itype(io_in_fromRob_blocks_7_bits_tracePipe_itype),
    .io_in_fromRob_blocks_7_bits_tracePipe_iretire(io_in_fromRob_blocks_7_bits_tracePipe_iretire),
    .io_in_fromRob_blocks_7_bits_tracePipe_ilastsize(io_in_fromRob_blocks_7_bits_tracePipe_ilastsize),
    .io_out_toPcMem_blocks_0_valid(g_io_out_toPcMem_blocks_0_valid),
    .io_out_toPcMem_blocks_0_bits_ftqIdx_value(g_io_out_toPcMem_blocks_0_bits_ftqIdx_value),
    .io_out_toPcMem_blocks_1_valid(g_io_out_toPcMem_blocks_1_valid),
    .io_out_toPcMem_blocks_1_bits_ftqIdx_value(g_io_out_toPcMem_blocks_1_bits_ftqIdx_value),
    .io_out_toPcMem_blocks_2_valid(g_io_out_toPcMem_blocks_2_valid),
    .io_out_toPcMem_blocks_2_bits_ftqIdx_value(g_io_out_toPcMem_blocks_2_bits_ftqIdx_value),
    .io_out_toEncoder_blocks_0_valid(g_io_out_toEncoder_blocks_0_valid),
    .io_out_toEncoder_blocks_0_bits_ftqOffset(g_io_out_toEncoder_blocks_0_bits_ftqOffset),
    .io_out_toEncoder_blocks_0_bits_tracePipe_itype(g_io_out_toEncoder_blocks_0_bits_tracePipe_itype),
    .io_out_toEncoder_blocks_0_bits_tracePipe_iretire(g_io_out_toEncoder_blocks_0_bits_tracePipe_iretire),
    .io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize(g_io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize),
    .io_out_toEncoder_blocks_1_valid(g_io_out_toEncoder_blocks_1_valid),
    .io_out_toEncoder_blocks_1_bits_ftqOffset(g_io_out_toEncoder_blocks_1_bits_ftqOffset),
    .io_out_toEncoder_blocks_1_bits_tracePipe_itype(g_io_out_toEncoder_blocks_1_bits_tracePipe_itype),
    .io_out_toEncoder_blocks_1_bits_tracePipe_iretire(g_io_out_toEncoder_blocks_1_bits_tracePipe_iretire),
    .io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize(g_io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize),
    .io_out_toEncoder_blocks_2_valid(g_io_out_toEncoder_blocks_2_valid),
    .io_out_toEncoder_blocks_2_bits_ftqOffset(g_io_out_toEncoder_blocks_2_bits_ftqOffset),
    .io_out_toEncoder_blocks_2_bits_tracePipe_itype(g_io_out_toEncoder_blocks_2_bits_tracePipe_itype),
    .io_out_toEncoder_blocks_2_bits_tracePipe_iretire(g_io_out_toEncoder_blocks_2_bits_tracePipe_iretire),
    .io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize(g_io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize),
    .io_out_blockRobCommit(g_io_out_blockRobCommit)
  );
  Trace_xs u_i (
    .clock(clk),
    .reset(reset),
    .io_in_fromEncoder_enable(io_in_fromEncoder_enable),
    .io_in_fromEncoder_stall(io_in_fromEncoder_stall),
    .io_in_fromRob_blocks_0_valid(io_in_fromRob_blocks_0_valid),
    .io_in_fromRob_blocks_0_bits_ftqIdx_value(io_in_fromRob_blocks_0_bits_ftqIdx_value),
    .io_in_fromRob_blocks_0_bits_ftqOffset(io_in_fromRob_blocks_0_bits_ftqOffset),
    .io_in_fromRob_blocks_0_bits_tracePipe_itype(io_in_fromRob_blocks_0_bits_tracePipe_itype),
    .io_in_fromRob_blocks_0_bits_tracePipe_iretire(io_in_fromRob_blocks_0_bits_tracePipe_iretire),
    .io_in_fromRob_blocks_0_bits_tracePipe_ilastsize(io_in_fromRob_blocks_0_bits_tracePipe_ilastsize),
    .io_in_fromRob_blocks_1_valid(io_in_fromRob_blocks_1_valid),
    .io_in_fromRob_blocks_1_bits_ftqIdx_value(io_in_fromRob_blocks_1_bits_ftqIdx_value),
    .io_in_fromRob_blocks_1_bits_ftqOffset(io_in_fromRob_blocks_1_bits_ftqOffset),
    .io_in_fromRob_blocks_1_bits_tracePipe_itype(io_in_fromRob_blocks_1_bits_tracePipe_itype),
    .io_in_fromRob_blocks_1_bits_tracePipe_iretire(io_in_fromRob_blocks_1_bits_tracePipe_iretire),
    .io_in_fromRob_blocks_1_bits_tracePipe_ilastsize(io_in_fromRob_blocks_1_bits_tracePipe_ilastsize),
    .io_in_fromRob_blocks_2_valid(io_in_fromRob_blocks_2_valid),
    .io_in_fromRob_blocks_2_bits_ftqIdx_value(io_in_fromRob_blocks_2_bits_ftqIdx_value),
    .io_in_fromRob_blocks_2_bits_ftqOffset(io_in_fromRob_blocks_2_bits_ftqOffset),
    .io_in_fromRob_blocks_2_bits_tracePipe_itype(io_in_fromRob_blocks_2_bits_tracePipe_itype),
    .io_in_fromRob_blocks_2_bits_tracePipe_iretire(io_in_fromRob_blocks_2_bits_tracePipe_iretire),
    .io_in_fromRob_blocks_2_bits_tracePipe_ilastsize(io_in_fromRob_blocks_2_bits_tracePipe_ilastsize),
    .io_in_fromRob_blocks_3_valid(io_in_fromRob_blocks_3_valid),
    .io_in_fromRob_blocks_3_bits_ftqIdx_value(io_in_fromRob_blocks_3_bits_ftqIdx_value),
    .io_in_fromRob_blocks_3_bits_ftqOffset(io_in_fromRob_blocks_3_bits_ftqOffset),
    .io_in_fromRob_blocks_3_bits_tracePipe_itype(io_in_fromRob_blocks_3_bits_tracePipe_itype),
    .io_in_fromRob_blocks_3_bits_tracePipe_iretire(io_in_fromRob_blocks_3_bits_tracePipe_iretire),
    .io_in_fromRob_blocks_3_bits_tracePipe_ilastsize(io_in_fromRob_blocks_3_bits_tracePipe_ilastsize),
    .io_in_fromRob_blocks_4_valid(io_in_fromRob_blocks_4_valid),
    .io_in_fromRob_blocks_4_bits_ftqIdx_value(io_in_fromRob_blocks_4_bits_ftqIdx_value),
    .io_in_fromRob_blocks_4_bits_ftqOffset(io_in_fromRob_blocks_4_bits_ftqOffset),
    .io_in_fromRob_blocks_4_bits_tracePipe_itype(io_in_fromRob_blocks_4_bits_tracePipe_itype),
    .io_in_fromRob_blocks_4_bits_tracePipe_iretire(io_in_fromRob_blocks_4_bits_tracePipe_iretire),
    .io_in_fromRob_blocks_4_bits_tracePipe_ilastsize(io_in_fromRob_blocks_4_bits_tracePipe_ilastsize),
    .io_in_fromRob_blocks_5_valid(io_in_fromRob_blocks_5_valid),
    .io_in_fromRob_blocks_5_bits_ftqIdx_value(io_in_fromRob_blocks_5_bits_ftqIdx_value),
    .io_in_fromRob_blocks_5_bits_ftqOffset(io_in_fromRob_blocks_5_bits_ftqOffset),
    .io_in_fromRob_blocks_5_bits_tracePipe_itype(io_in_fromRob_blocks_5_bits_tracePipe_itype),
    .io_in_fromRob_blocks_5_bits_tracePipe_iretire(io_in_fromRob_blocks_5_bits_tracePipe_iretire),
    .io_in_fromRob_blocks_5_bits_tracePipe_ilastsize(io_in_fromRob_blocks_5_bits_tracePipe_ilastsize),
    .io_in_fromRob_blocks_6_valid(io_in_fromRob_blocks_6_valid),
    .io_in_fromRob_blocks_6_bits_ftqIdx_value(io_in_fromRob_blocks_6_bits_ftqIdx_value),
    .io_in_fromRob_blocks_6_bits_ftqOffset(io_in_fromRob_blocks_6_bits_ftqOffset),
    .io_in_fromRob_blocks_6_bits_tracePipe_itype(io_in_fromRob_blocks_6_bits_tracePipe_itype),
    .io_in_fromRob_blocks_6_bits_tracePipe_iretire(io_in_fromRob_blocks_6_bits_tracePipe_iretire),
    .io_in_fromRob_blocks_6_bits_tracePipe_ilastsize(io_in_fromRob_blocks_6_bits_tracePipe_ilastsize),
    .io_in_fromRob_blocks_7_valid(io_in_fromRob_blocks_7_valid),
    .io_in_fromRob_blocks_7_bits_ftqIdx_value(io_in_fromRob_blocks_7_bits_ftqIdx_value),
    .io_in_fromRob_blocks_7_bits_ftqOffset(io_in_fromRob_blocks_7_bits_ftqOffset),
    .io_in_fromRob_blocks_7_bits_tracePipe_itype(io_in_fromRob_blocks_7_bits_tracePipe_itype),
    .io_in_fromRob_blocks_7_bits_tracePipe_iretire(io_in_fromRob_blocks_7_bits_tracePipe_iretire),
    .io_in_fromRob_blocks_7_bits_tracePipe_ilastsize(io_in_fromRob_blocks_7_bits_tracePipe_ilastsize),
    .io_out_toPcMem_blocks_0_valid(i_io_out_toPcMem_blocks_0_valid),
    .io_out_toPcMem_blocks_0_bits_ftqIdx_value(i_io_out_toPcMem_blocks_0_bits_ftqIdx_value),
    .io_out_toPcMem_blocks_1_valid(i_io_out_toPcMem_blocks_1_valid),
    .io_out_toPcMem_blocks_1_bits_ftqIdx_value(i_io_out_toPcMem_blocks_1_bits_ftqIdx_value),
    .io_out_toPcMem_blocks_2_valid(i_io_out_toPcMem_blocks_2_valid),
    .io_out_toPcMem_blocks_2_bits_ftqIdx_value(i_io_out_toPcMem_blocks_2_bits_ftqIdx_value),
    .io_out_toEncoder_blocks_0_valid(i_io_out_toEncoder_blocks_0_valid),
    .io_out_toEncoder_blocks_0_bits_ftqOffset(i_io_out_toEncoder_blocks_0_bits_ftqOffset),
    .io_out_toEncoder_blocks_0_bits_tracePipe_itype(i_io_out_toEncoder_blocks_0_bits_tracePipe_itype),
    .io_out_toEncoder_blocks_0_bits_tracePipe_iretire(i_io_out_toEncoder_blocks_0_bits_tracePipe_iretire),
    .io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize(i_io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize),
    .io_out_toEncoder_blocks_1_valid(i_io_out_toEncoder_blocks_1_valid),
    .io_out_toEncoder_blocks_1_bits_ftqOffset(i_io_out_toEncoder_blocks_1_bits_ftqOffset),
    .io_out_toEncoder_blocks_1_bits_tracePipe_itype(i_io_out_toEncoder_blocks_1_bits_tracePipe_itype),
    .io_out_toEncoder_blocks_1_bits_tracePipe_iretire(i_io_out_toEncoder_blocks_1_bits_tracePipe_iretire),
    .io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize(i_io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize),
    .io_out_toEncoder_blocks_2_valid(i_io_out_toEncoder_blocks_2_valid),
    .io_out_toEncoder_blocks_2_bits_ftqOffset(i_io_out_toEncoder_blocks_2_bits_ftqOffset),
    .io_out_toEncoder_blocks_2_bits_tracePipe_itype(i_io_out_toEncoder_blocks_2_bits_tracePipe_itype),
    .io_out_toEncoder_blocks_2_bits_tracePipe_iretire(i_io_out_toEncoder_blocks_2_bits_tracePipe_iretire),
    .io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize(i_io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize),
    .io_out_blockRobCommit(i_io_out_blockRobCommit)
  );

  task automatic drive_inputs();
    reset = ($urandom_range(0,99) < 3);
    io_in_fromEncoder_enable = $urandom;
    io_in_fromEncoder_stall = $urandom;
    io_in_fromRob_blocks_0_valid = $urandom;
    io_in_fromRob_blocks_0_bits_ftqIdx_value = $urandom;
    io_in_fromRob_blocks_0_bits_ftqOffset = $urandom;
    io_in_fromRob_blocks_0_bits_tracePipe_itype = $urandom;
    io_in_fromRob_blocks_0_bits_tracePipe_iretire = $urandom;
    io_in_fromRob_blocks_0_bits_tracePipe_ilastsize = $urandom;
    io_in_fromRob_blocks_1_valid = $urandom;
    io_in_fromRob_blocks_1_bits_ftqIdx_value = $urandom;
    io_in_fromRob_blocks_1_bits_ftqOffset = $urandom;
    io_in_fromRob_blocks_1_bits_tracePipe_itype = $urandom;
    io_in_fromRob_blocks_1_bits_tracePipe_iretire = $urandom;
    io_in_fromRob_blocks_1_bits_tracePipe_ilastsize = $urandom;
    io_in_fromRob_blocks_2_valid = $urandom;
    io_in_fromRob_blocks_2_bits_ftqIdx_value = $urandom;
    io_in_fromRob_blocks_2_bits_ftqOffset = $urandom;
    io_in_fromRob_blocks_2_bits_tracePipe_itype = $urandom;
    io_in_fromRob_blocks_2_bits_tracePipe_iretire = $urandom;
    io_in_fromRob_blocks_2_bits_tracePipe_ilastsize = $urandom;
    io_in_fromRob_blocks_3_valid = $urandom;
    io_in_fromRob_blocks_3_bits_ftqIdx_value = $urandom;
    io_in_fromRob_blocks_3_bits_ftqOffset = $urandom;
    io_in_fromRob_blocks_3_bits_tracePipe_itype = $urandom;
    io_in_fromRob_blocks_3_bits_tracePipe_iretire = $urandom;
    io_in_fromRob_blocks_3_bits_tracePipe_ilastsize = $urandom;
    io_in_fromRob_blocks_4_valid = $urandom;
    io_in_fromRob_blocks_4_bits_ftqIdx_value = $urandom;
    io_in_fromRob_blocks_4_bits_ftqOffset = $urandom;
    io_in_fromRob_blocks_4_bits_tracePipe_itype = $urandom;
    io_in_fromRob_blocks_4_bits_tracePipe_iretire = $urandom;
    io_in_fromRob_blocks_4_bits_tracePipe_ilastsize = $urandom;
    io_in_fromRob_blocks_5_valid = $urandom;
    io_in_fromRob_blocks_5_bits_ftqIdx_value = $urandom;
    io_in_fromRob_blocks_5_bits_ftqOffset = $urandom;
    io_in_fromRob_blocks_5_bits_tracePipe_itype = $urandom;
    io_in_fromRob_blocks_5_bits_tracePipe_iretire = $urandom;
    io_in_fromRob_blocks_5_bits_tracePipe_ilastsize = $urandom;
    io_in_fromRob_blocks_6_valid = $urandom;
    io_in_fromRob_blocks_6_bits_ftqIdx_value = $urandom;
    io_in_fromRob_blocks_6_bits_ftqOffset = $urandom;
    io_in_fromRob_blocks_6_bits_tracePipe_itype = $urandom;
    io_in_fromRob_blocks_6_bits_tracePipe_iretire = $urandom;
    io_in_fromRob_blocks_6_bits_tracePipe_ilastsize = $urandom;
    io_in_fromRob_blocks_7_valid = $urandom;
    io_in_fromRob_blocks_7_bits_ftqIdx_value = $urandom;
    io_in_fromRob_blocks_7_bits_ftqOffset = $urandom;
    io_in_fromRob_blocks_7_bits_tracePipe_itype = $urandom;
    io_in_fromRob_blocks_7_bits_tracePipe_iretire = $urandom;
    io_in_fromRob_blocks_7_bits_tracePipe_ilastsize = $urandom;
  endtask
  task automatic check_outputs();
    if (!$isunknown(g_io_out_toPcMem_blocks_0_valid) && (g_io_out_toPcMem_blocks_0_valid) !== (i_io_out_toPcMem_blocks_0_valid)) begin errors++; if (errors<=60) $display("[%0t] io_out_toPcMem_blocks_0_valid g=%h i=%h",$time,g_io_out_toPcMem_blocks_0_valid,i_io_out_toPcMem_blocks_0_valid); end checks++;
    if (!$isunknown(g_io_out_toPcMem_blocks_0_bits_ftqIdx_value) && (g_io_out_toPcMem_blocks_0_bits_ftqIdx_value) !== (i_io_out_toPcMem_blocks_0_bits_ftqIdx_value)) begin errors++; if (errors<=60) $display("[%0t] io_out_toPcMem_blocks_0_bits_ftqIdx_value g=%h i=%h",$time,g_io_out_toPcMem_blocks_0_bits_ftqIdx_value,i_io_out_toPcMem_blocks_0_bits_ftqIdx_value); end checks++;
    if (!$isunknown(g_io_out_toPcMem_blocks_1_valid) && (g_io_out_toPcMem_blocks_1_valid) !== (i_io_out_toPcMem_blocks_1_valid)) begin errors++; if (errors<=60) $display("[%0t] io_out_toPcMem_blocks_1_valid g=%h i=%h",$time,g_io_out_toPcMem_blocks_1_valid,i_io_out_toPcMem_blocks_1_valid); end checks++;
    if (!$isunknown(g_io_out_toPcMem_blocks_1_bits_ftqIdx_value) && (g_io_out_toPcMem_blocks_1_bits_ftqIdx_value) !== (i_io_out_toPcMem_blocks_1_bits_ftqIdx_value)) begin errors++; if (errors<=60) $display("[%0t] io_out_toPcMem_blocks_1_bits_ftqIdx_value g=%h i=%h",$time,g_io_out_toPcMem_blocks_1_bits_ftqIdx_value,i_io_out_toPcMem_blocks_1_bits_ftqIdx_value); end checks++;
    if (!$isunknown(g_io_out_toPcMem_blocks_2_valid) && (g_io_out_toPcMem_blocks_2_valid) !== (i_io_out_toPcMem_blocks_2_valid)) begin errors++; if (errors<=60) $display("[%0t] io_out_toPcMem_blocks_2_valid g=%h i=%h",$time,g_io_out_toPcMem_blocks_2_valid,i_io_out_toPcMem_blocks_2_valid); end checks++;
    if (!$isunknown(g_io_out_toPcMem_blocks_2_bits_ftqIdx_value) && (g_io_out_toPcMem_blocks_2_bits_ftqIdx_value) !== (i_io_out_toPcMem_blocks_2_bits_ftqIdx_value)) begin errors++; if (errors<=60) $display("[%0t] io_out_toPcMem_blocks_2_bits_ftqIdx_value g=%h i=%h",$time,g_io_out_toPcMem_blocks_2_bits_ftqIdx_value,i_io_out_toPcMem_blocks_2_bits_ftqIdx_value); end checks++;
    if (!$isunknown(g_io_out_toEncoder_blocks_0_valid) && (g_io_out_toEncoder_blocks_0_valid) !== (i_io_out_toEncoder_blocks_0_valid)) begin errors++; if (errors<=60) $display("[%0t] io_out_toEncoder_blocks_0_valid g=%h i=%h",$time,g_io_out_toEncoder_blocks_0_valid,i_io_out_toEncoder_blocks_0_valid); end checks++;
    if (!$isunknown(g_io_out_toEncoder_blocks_0_bits_ftqOffset) && (g_io_out_toEncoder_blocks_0_bits_ftqOffset) !== (i_io_out_toEncoder_blocks_0_bits_ftqOffset)) begin errors++; if (errors<=60) $display("[%0t] io_out_toEncoder_blocks_0_bits_ftqOffset g=%h i=%h",$time,g_io_out_toEncoder_blocks_0_bits_ftqOffset,i_io_out_toEncoder_blocks_0_bits_ftqOffset); end checks++;
    if (!$isunknown(g_io_out_toEncoder_blocks_0_bits_tracePipe_itype) && (g_io_out_toEncoder_blocks_0_bits_tracePipe_itype) !== (i_io_out_toEncoder_blocks_0_bits_tracePipe_itype)) begin errors++; if (errors<=60) $display("[%0t] io_out_toEncoder_blocks_0_bits_tracePipe_itype g=%h i=%h",$time,g_io_out_toEncoder_blocks_0_bits_tracePipe_itype,i_io_out_toEncoder_blocks_0_bits_tracePipe_itype); end checks++;
    if (!$isunknown(g_io_out_toEncoder_blocks_0_bits_tracePipe_iretire) && (g_io_out_toEncoder_blocks_0_bits_tracePipe_iretire) !== (i_io_out_toEncoder_blocks_0_bits_tracePipe_iretire)) begin errors++; if (errors<=60) $display("[%0t] io_out_toEncoder_blocks_0_bits_tracePipe_iretire g=%h i=%h",$time,g_io_out_toEncoder_blocks_0_bits_tracePipe_iretire,i_io_out_toEncoder_blocks_0_bits_tracePipe_iretire); end checks++;
    if (!$isunknown(g_io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize) && (g_io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize) !== (i_io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize)) begin errors++; if (errors<=60) $display("[%0t] io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize g=%h i=%h",$time,g_io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize,i_io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize); end checks++;
    if (!$isunknown(g_io_out_toEncoder_blocks_1_valid) && (g_io_out_toEncoder_blocks_1_valid) !== (i_io_out_toEncoder_blocks_1_valid)) begin errors++; if (errors<=60) $display("[%0t] io_out_toEncoder_blocks_1_valid g=%h i=%h",$time,g_io_out_toEncoder_blocks_1_valid,i_io_out_toEncoder_blocks_1_valid); end checks++;
    if (!$isunknown(g_io_out_toEncoder_blocks_1_bits_ftqOffset) && (g_io_out_toEncoder_blocks_1_bits_ftqOffset) !== (i_io_out_toEncoder_blocks_1_bits_ftqOffset)) begin errors++; if (errors<=60) $display("[%0t] io_out_toEncoder_blocks_1_bits_ftqOffset g=%h i=%h",$time,g_io_out_toEncoder_blocks_1_bits_ftqOffset,i_io_out_toEncoder_blocks_1_bits_ftqOffset); end checks++;
    if (!$isunknown(g_io_out_toEncoder_blocks_1_bits_tracePipe_itype) && (g_io_out_toEncoder_blocks_1_bits_tracePipe_itype) !== (i_io_out_toEncoder_blocks_1_bits_tracePipe_itype)) begin errors++; if (errors<=60) $display("[%0t] io_out_toEncoder_blocks_1_bits_tracePipe_itype g=%h i=%h",$time,g_io_out_toEncoder_blocks_1_bits_tracePipe_itype,i_io_out_toEncoder_blocks_1_bits_tracePipe_itype); end checks++;
    if (!$isunknown(g_io_out_toEncoder_blocks_1_bits_tracePipe_iretire) && (g_io_out_toEncoder_blocks_1_bits_tracePipe_iretire) !== (i_io_out_toEncoder_blocks_1_bits_tracePipe_iretire)) begin errors++; if (errors<=60) $display("[%0t] io_out_toEncoder_blocks_1_bits_tracePipe_iretire g=%h i=%h",$time,g_io_out_toEncoder_blocks_1_bits_tracePipe_iretire,i_io_out_toEncoder_blocks_1_bits_tracePipe_iretire); end checks++;
    if (!$isunknown(g_io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize) && (g_io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize) !== (i_io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize)) begin errors++; if (errors<=60) $display("[%0t] io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize g=%h i=%h",$time,g_io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize,i_io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize); end checks++;
    if (!$isunknown(g_io_out_toEncoder_blocks_2_valid) && (g_io_out_toEncoder_blocks_2_valid) !== (i_io_out_toEncoder_blocks_2_valid)) begin errors++; if (errors<=60) $display("[%0t] io_out_toEncoder_blocks_2_valid g=%h i=%h",$time,g_io_out_toEncoder_blocks_2_valid,i_io_out_toEncoder_blocks_2_valid); end checks++;
    if (!$isunknown(g_io_out_toEncoder_blocks_2_bits_ftqOffset) && (g_io_out_toEncoder_blocks_2_bits_ftqOffset) !== (i_io_out_toEncoder_blocks_2_bits_ftqOffset)) begin errors++; if (errors<=60) $display("[%0t] io_out_toEncoder_blocks_2_bits_ftqOffset g=%h i=%h",$time,g_io_out_toEncoder_blocks_2_bits_ftqOffset,i_io_out_toEncoder_blocks_2_bits_ftqOffset); end checks++;
    if (!$isunknown(g_io_out_toEncoder_blocks_2_bits_tracePipe_itype) && (g_io_out_toEncoder_blocks_2_bits_tracePipe_itype) !== (i_io_out_toEncoder_blocks_2_bits_tracePipe_itype)) begin errors++; if (errors<=60) $display("[%0t] io_out_toEncoder_blocks_2_bits_tracePipe_itype g=%h i=%h",$time,g_io_out_toEncoder_blocks_2_bits_tracePipe_itype,i_io_out_toEncoder_blocks_2_bits_tracePipe_itype); end checks++;
    if (!$isunknown(g_io_out_toEncoder_blocks_2_bits_tracePipe_iretire) && (g_io_out_toEncoder_blocks_2_bits_tracePipe_iretire) !== (i_io_out_toEncoder_blocks_2_bits_tracePipe_iretire)) begin errors++; if (errors<=60) $display("[%0t] io_out_toEncoder_blocks_2_bits_tracePipe_iretire g=%h i=%h",$time,g_io_out_toEncoder_blocks_2_bits_tracePipe_iretire,i_io_out_toEncoder_blocks_2_bits_tracePipe_iretire); end checks++;
    if (!$isunknown(g_io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize) && (g_io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize) !== (i_io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize)) begin errors++; if (errors<=60) $display("[%0t] io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize g=%h i=%h",$time,g_io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize,i_io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize); end checks++;
    if (!$isunknown(g_io_out_blockRobCommit) && (g_io_out_blockRobCommit) !== (i_io_out_blockRobCommit)) begin errors++; if (errors<=60) $display("[%0t] io_out_blockRobCommit g=%h i=%h",$time,g_io_out_blockRobCommit,i_io_out_blockRobCommit); end checks++;
  endtask

  initial begin
    drive_inputs(); reset = 1;
    repeat (5) @(negedge clk);
    repeat (NCYCLES) begin
      drive_inputs();
      @(posedge clk);
      #1 check_outputs();
      @(negedge clk);
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
