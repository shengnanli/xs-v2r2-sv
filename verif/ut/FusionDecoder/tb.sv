// =============================================================================
// FusionDecoder UT —— golden FusionDecoder 对重写 FusionDecoder_xs 双例化，同激励逐拍比对
// 全部 84 根输出线（5 对 × 9 个替换字段 + 5 × 3 个 info + 5 个 clear）。
// 本文件由 gen.py 生成，不要手改（改 gen.py 再重跑）。
//
// ★判别力在「模式 × 寄存器关系 × 相邻对位置」★
//   28 种模式每种都要在 5 个对位置上各命中；每种模式还要打到 rd 关系的各种分支：
//   同 rd / rd->rs1(b) / rd->rs2(b) / rs1(b)==rs2(b)（R 型不融合）/ rd=0（HINT 不融合）/
//   近似模式（移位量差 1、opcode 差一位）。覆盖统计从 golden 内部 fusionVec 寄存器取。
// ★无复位寄存器★ fusionVec/notHint/enabled/... 都无复位；+vcs+initreg+random 下两例化初值
//   不同，所以暖机 WARMUP 拍里全 valid、全 ready 让 5 对都 fire 一次把它们写定，之后开比。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int WARMUP = 32;
  localparam int N_IN = 6, N_PAIR = 5;
  bit clk = 0; logic rst; int errors = 0; longint checks = 0;
  always #5 clk = ~clk;

  logic        io_disableFusion;
  logic        io_in_0_valid;
  logic [31:0] io_in_0_bits;
  logic        io_in_1_valid;
  logic [31:0] io_in_1_bits;
  logic        io_in_2_valid;
  logic [31:0] io_in_2_bits;
  logic        io_in_3_valid;
  logic [31:0] io_in_3_bits;
  logic        io_in_4_valid;
  logic [31:0] io_in_4_bits;
  logic        io_in_5_valid;
  logic [31:0] io_in_5_bits;
  logic        io_inReady_0;
  logic [8:0]  io_dec_0_fuOpType;
  logic        io_inReady_1;
  logic [8:0]  io_dec_1_fuOpType;
  logic        io_inReady_2;
  logic [8:0]  io_dec_2_fuOpType;
  logic        io_inReady_3;
  logic [8:0]  io_dec_3_fuOpType;
  logic        io_inReady_4;
  logic [8:0]  io_dec_4_fuOpType;
  logic [0:0] g_out_0_valid;
  logic [0:0] g_out_0_bits_fuType_valid;
  logic [0:0] g_out_0_bits_fuOpType_valid;
  logic [8:0] g_out_0_bits_fuOpType_bits;
  logic [0:0] g_out_0_bits_lsrc2_valid;
  logic [5:0] g_out_0_bits_lsrc2_bits;
  logic [0:0] g_out_0_bits_src2Type_valid;
  logic [0:0] g_out_0_bits_selImm_valid;
  logic [3:0] g_out_0_bits_selImm_bits;
  logic g_info_0_rs2FromRs1;
  logic g_info_0_rs2FromRs2;
  logic g_info_0_rs2FromZero;
  logic [0:0] g_out_1_valid;
  logic [0:0] g_out_1_bits_fuType_valid;
  logic [0:0] g_out_1_bits_fuOpType_valid;
  logic [8:0] g_out_1_bits_fuOpType_bits;
  logic [0:0] g_out_1_bits_lsrc2_valid;
  logic [5:0] g_out_1_bits_lsrc2_bits;
  logic [0:0] g_out_1_bits_src2Type_valid;
  logic [0:0] g_out_1_bits_selImm_valid;
  logic [3:0] g_out_1_bits_selImm_bits;
  logic g_info_1_rs2FromRs1;
  logic g_info_1_rs2FromRs2;
  logic g_info_1_rs2FromZero;
  logic [0:0] g_out_2_valid;
  logic [0:0] g_out_2_bits_fuType_valid;
  logic [0:0] g_out_2_bits_fuOpType_valid;
  logic [8:0] g_out_2_bits_fuOpType_bits;
  logic [0:0] g_out_2_bits_lsrc2_valid;
  logic [5:0] g_out_2_bits_lsrc2_bits;
  logic [0:0] g_out_2_bits_src2Type_valid;
  logic [0:0] g_out_2_bits_selImm_valid;
  logic [3:0] g_out_2_bits_selImm_bits;
  logic g_info_2_rs2FromRs1;
  logic g_info_2_rs2FromRs2;
  logic g_info_2_rs2FromZero;
  logic [0:0] g_out_3_valid;
  logic [0:0] g_out_3_bits_fuType_valid;
  logic [0:0] g_out_3_bits_fuOpType_valid;
  logic [8:0] g_out_3_bits_fuOpType_bits;
  logic [0:0] g_out_3_bits_lsrc2_valid;
  logic [5:0] g_out_3_bits_lsrc2_bits;
  logic [0:0] g_out_3_bits_src2Type_valid;
  logic [0:0] g_out_3_bits_selImm_valid;
  logic [3:0] g_out_3_bits_selImm_bits;
  logic g_info_3_rs2FromRs1;
  logic g_info_3_rs2FromRs2;
  logic g_info_3_rs2FromZero;
  logic [0:0] g_out_4_valid;
  logic [0:0] g_out_4_bits_fuType_valid;
  logic [0:0] g_out_4_bits_fuOpType_valid;
  logic [8:0] g_out_4_bits_fuOpType_bits;
  logic [0:0] g_out_4_bits_lsrc2_valid;
  logic [5:0] g_out_4_bits_lsrc2_bits;
  logic [0:0] g_out_4_bits_src2Type_valid;
  logic [0:0] g_out_4_bits_selImm_valid;
  logic [3:0] g_out_4_bits_selImm_bits;
  logic g_info_4_rs2FromRs1;
  logic g_info_4_rs2FromRs2;
  logic g_info_4_rs2FromZero;
  logic g_clear_1;
  logic g_clear_2;
  logic g_clear_3;
  logic g_clear_4;
  logic g_clear_5;
  logic [0:0] x_out_0_valid;
  logic [0:0] x_out_0_bits_fuType_valid;
  logic [0:0] x_out_0_bits_fuOpType_valid;
  logic [8:0] x_out_0_bits_fuOpType_bits;
  logic [0:0] x_out_0_bits_lsrc2_valid;
  logic [5:0] x_out_0_bits_lsrc2_bits;
  logic [0:0] x_out_0_bits_src2Type_valid;
  logic [0:0] x_out_0_bits_selImm_valid;
  logic [3:0] x_out_0_bits_selImm_bits;
  logic x_info_0_rs2FromRs1;
  logic x_info_0_rs2FromRs2;
  logic x_info_0_rs2FromZero;
  logic [0:0] x_out_1_valid;
  logic [0:0] x_out_1_bits_fuType_valid;
  logic [0:0] x_out_1_bits_fuOpType_valid;
  logic [8:0] x_out_1_bits_fuOpType_bits;
  logic [0:0] x_out_1_bits_lsrc2_valid;
  logic [5:0] x_out_1_bits_lsrc2_bits;
  logic [0:0] x_out_1_bits_src2Type_valid;
  logic [0:0] x_out_1_bits_selImm_valid;
  logic [3:0] x_out_1_bits_selImm_bits;
  logic x_info_1_rs2FromRs1;
  logic x_info_1_rs2FromRs2;
  logic x_info_1_rs2FromZero;
  logic [0:0] x_out_2_valid;
  logic [0:0] x_out_2_bits_fuType_valid;
  logic [0:0] x_out_2_bits_fuOpType_valid;
  logic [8:0] x_out_2_bits_fuOpType_bits;
  logic [0:0] x_out_2_bits_lsrc2_valid;
  logic [5:0] x_out_2_bits_lsrc2_bits;
  logic [0:0] x_out_2_bits_src2Type_valid;
  logic [0:0] x_out_2_bits_selImm_valid;
  logic [3:0] x_out_2_bits_selImm_bits;
  logic x_info_2_rs2FromRs1;
  logic x_info_2_rs2FromRs2;
  logic x_info_2_rs2FromZero;
  logic [0:0] x_out_3_valid;
  logic [0:0] x_out_3_bits_fuType_valid;
  logic [0:0] x_out_3_bits_fuOpType_valid;
  logic [8:0] x_out_3_bits_fuOpType_bits;
  logic [0:0] x_out_3_bits_lsrc2_valid;
  logic [5:0] x_out_3_bits_lsrc2_bits;
  logic [0:0] x_out_3_bits_src2Type_valid;
  logic [0:0] x_out_3_bits_selImm_valid;
  logic [3:0] x_out_3_bits_selImm_bits;
  logic x_info_3_rs2FromRs1;
  logic x_info_3_rs2FromRs2;
  logic x_info_3_rs2FromZero;
  logic [0:0] x_out_4_valid;
  logic [0:0] x_out_4_bits_fuType_valid;
  logic [0:0] x_out_4_bits_fuOpType_valid;
  logic [8:0] x_out_4_bits_fuOpType_bits;
  logic [0:0] x_out_4_bits_lsrc2_valid;
  logic [5:0] x_out_4_bits_lsrc2_bits;
  logic [0:0] x_out_4_bits_src2Type_valid;
  logic [0:0] x_out_4_bits_selImm_valid;
  logic [3:0] x_out_4_bits_selImm_bits;
  logic x_info_4_rs2FromRs1;
  logic x_info_4_rs2FromRs2;
  logic x_info_4_rs2FromZero;
  logic x_clear_1;
  logic x_clear_2;
  logic x_clear_3;
  logic x_clear_4;
  logic x_clear_5;

  FusionDecoder u_gold (
    .clock(clk), .reset(rst), .io_disableFusion(io_disableFusion),
    .io_in_0_valid(io_in_0_valid), .io_in_0_bits(io_in_0_bits),
    .io_in_1_valid(io_in_1_valid), .io_in_1_bits(io_in_1_bits),
    .io_in_2_valid(io_in_2_valid), .io_in_2_bits(io_in_2_bits),
    .io_in_3_valid(io_in_3_valid), .io_in_3_bits(io_in_3_bits),
    .io_in_4_valid(io_in_4_valid), .io_in_4_bits(io_in_4_bits),
    .io_in_5_valid(io_in_5_valid), .io_in_5_bits(io_in_5_bits),
    .io_inReady_0(io_inReady_0), .io_dec_0_fuOpType(io_dec_0_fuOpType),
    .io_inReady_1(io_inReady_1), .io_dec_1_fuOpType(io_dec_1_fuOpType),
    .io_inReady_2(io_inReady_2), .io_dec_2_fuOpType(io_dec_2_fuOpType),
    .io_inReady_3(io_inReady_3), .io_dec_3_fuOpType(io_dec_3_fuOpType),
    .io_inReady_4(io_inReady_4), .io_dec_4_fuOpType(io_dec_4_fuOpType),
    .io_out_0_valid(g_out_0_valid), .io_out_0_bits_fuType_valid(g_out_0_bits_fuType_valid), .io_out_0_bits_fuOpType_valid(g_out_0_bits_fuOpType_valid), .io_out_0_bits_fuOpType_bits(g_out_0_bits_fuOpType_bits), .io_out_0_bits_lsrc2_valid(g_out_0_bits_lsrc2_valid), .io_out_0_bits_lsrc2_bits(g_out_0_bits_lsrc2_bits), .io_out_0_bits_src2Type_valid(g_out_0_bits_src2Type_valid), .io_out_0_bits_selImm_valid(g_out_0_bits_selImm_valid), .io_out_0_bits_selImm_bits(g_out_0_bits_selImm_bits),
    .io_out_1_valid(g_out_1_valid), .io_out_1_bits_fuType_valid(g_out_1_bits_fuType_valid), .io_out_1_bits_fuOpType_valid(g_out_1_bits_fuOpType_valid), .io_out_1_bits_fuOpType_bits(g_out_1_bits_fuOpType_bits), .io_out_1_bits_lsrc2_valid(g_out_1_bits_lsrc2_valid), .io_out_1_bits_lsrc2_bits(g_out_1_bits_lsrc2_bits), .io_out_1_bits_src2Type_valid(g_out_1_bits_src2Type_valid), .io_out_1_bits_selImm_valid(g_out_1_bits_selImm_valid), .io_out_1_bits_selImm_bits(g_out_1_bits_selImm_bits),
    .io_out_2_valid(g_out_2_valid), .io_out_2_bits_fuType_valid(g_out_2_bits_fuType_valid), .io_out_2_bits_fuOpType_valid(g_out_2_bits_fuOpType_valid), .io_out_2_bits_fuOpType_bits(g_out_2_bits_fuOpType_bits), .io_out_2_bits_lsrc2_valid(g_out_2_bits_lsrc2_valid), .io_out_2_bits_lsrc2_bits(g_out_2_bits_lsrc2_bits), .io_out_2_bits_src2Type_valid(g_out_2_bits_src2Type_valid), .io_out_2_bits_selImm_valid(g_out_2_bits_selImm_valid), .io_out_2_bits_selImm_bits(g_out_2_bits_selImm_bits),
    .io_out_3_valid(g_out_3_valid), .io_out_3_bits_fuType_valid(g_out_3_bits_fuType_valid), .io_out_3_bits_fuOpType_valid(g_out_3_bits_fuOpType_valid), .io_out_3_bits_fuOpType_bits(g_out_3_bits_fuOpType_bits), .io_out_3_bits_lsrc2_valid(g_out_3_bits_lsrc2_valid), .io_out_3_bits_lsrc2_bits(g_out_3_bits_lsrc2_bits), .io_out_3_bits_src2Type_valid(g_out_3_bits_src2Type_valid), .io_out_3_bits_selImm_valid(g_out_3_bits_selImm_valid), .io_out_3_bits_selImm_bits(g_out_3_bits_selImm_bits),
    .io_out_4_valid(g_out_4_valid), .io_out_4_bits_fuType_valid(g_out_4_bits_fuType_valid), .io_out_4_bits_fuOpType_valid(g_out_4_bits_fuOpType_valid), .io_out_4_bits_fuOpType_bits(g_out_4_bits_fuOpType_bits), .io_out_4_bits_lsrc2_valid(g_out_4_bits_lsrc2_valid), .io_out_4_bits_lsrc2_bits(g_out_4_bits_lsrc2_bits), .io_out_4_bits_src2Type_valid(g_out_4_bits_src2Type_valid), .io_out_4_bits_selImm_valid(g_out_4_bits_selImm_valid), .io_out_4_bits_selImm_bits(g_out_4_bits_selImm_bits),
    .io_info_0_rs2FromRs1(g_info_0_rs2FromRs1), .io_info_0_rs2FromRs2(g_info_0_rs2FromRs2), .io_info_0_rs2FromZero(g_info_0_rs2FromZero),
    .io_info_1_rs2FromRs1(g_info_1_rs2FromRs1), .io_info_1_rs2FromRs2(g_info_1_rs2FromRs2), .io_info_1_rs2FromZero(g_info_1_rs2FromZero),
    .io_info_2_rs2FromRs1(g_info_2_rs2FromRs1), .io_info_2_rs2FromRs2(g_info_2_rs2FromRs2), .io_info_2_rs2FromZero(g_info_2_rs2FromZero),
    .io_info_3_rs2FromRs1(g_info_3_rs2FromRs1), .io_info_3_rs2FromRs2(g_info_3_rs2FromRs2), .io_info_3_rs2FromZero(g_info_3_rs2FromZero),
    .io_info_4_rs2FromRs1(g_info_4_rs2FromRs1), .io_info_4_rs2FromRs2(g_info_4_rs2FromRs2), .io_info_4_rs2FromZero(g_info_4_rs2FromZero),
    .io_clear_1(g_clear_1), .io_clear_2(g_clear_2), .io_clear_3(g_clear_3), .io_clear_4(g_clear_4), .io_clear_5(g_clear_5)
  );

  FusionDecoder_xs u_xs (
    .clock(clk), .reset(rst), .io_disableFusion(io_disableFusion),
    .io_in_0_valid(io_in_0_valid), .io_in_0_bits(io_in_0_bits),
    .io_in_1_valid(io_in_1_valid), .io_in_1_bits(io_in_1_bits),
    .io_in_2_valid(io_in_2_valid), .io_in_2_bits(io_in_2_bits),
    .io_in_3_valid(io_in_3_valid), .io_in_3_bits(io_in_3_bits),
    .io_in_4_valid(io_in_4_valid), .io_in_4_bits(io_in_4_bits),
    .io_in_5_valid(io_in_5_valid), .io_in_5_bits(io_in_5_bits),
    .io_inReady_0(io_inReady_0), .io_dec_0_fuOpType(io_dec_0_fuOpType),
    .io_inReady_1(io_inReady_1), .io_dec_1_fuOpType(io_dec_1_fuOpType),
    .io_inReady_2(io_inReady_2), .io_dec_2_fuOpType(io_dec_2_fuOpType),
    .io_inReady_3(io_inReady_3), .io_dec_3_fuOpType(io_dec_3_fuOpType),
    .io_inReady_4(io_inReady_4), .io_dec_4_fuOpType(io_dec_4_fuOpType),
    .io_out_0_valid(x_out_0_valid), .io_out_0_bits_fuType_valid(x_out_0_bits_fuType_valid), .io_out_0_bits_fuOpType_valid(x_out_0_bits_fuOpType_valid), .io_out_0_bits_fuOpType_bits(x_out_0_bits_fuOpType_bits), .io_out_0_bits_lsrc2_valid(x_out_0_bits_lsrc2_valid), .io_out_0_bits_lsrc2_bits(x_out_0_bits_lsrc2_bits), .io_out_0_bits_src2Type_valid(x_out_0_bits_src2Type_valid), .io_out_0_bits_selImm_valid(x_out_0_bits_selImm_valid), .io_out_0_bits_selImm_bits(x_out_0_bits_selImm_bits),
    .io_out_1_valid(x_out_1_valid), .io_out_1_bits_fuType_valid(x_out_1_bits_fuType_valid), .io_out_1_bits_fuOpType_valid(x_out_1_bits_fuOpType_valid), .io_out_1_bits_fuOpType_bits(x_out_1_bits_fuOpType_bits), .io_out_1_bits_lsrc2_valid(x_out_1_bits_lsrc2_valid), .io_out_1_bits_lsrc2_bits(x_out_1_bits_lsrc2_bits), .io_out_1_bits_src2Type_valid(x_out_1_bits_src2Type_valid), .io_out_1_bits_selImm_valid(x_out_1_bits_selImm_valid), .io_out_1_bits_selImm_bits(x_out_1_bits_selImm_bits),
    .io_out_2_valid(x_out_2_valid), .io_out_2_bits_fuType_valid(x_out_2_bits_fuType_valid), .io_out_2_bits_fuOpType_valid(x_out_2_bits_fuOpType_valid), .io_out_2_bits_fuOpType_bits(x_out_2_bits_fuOpType_bits), .io_out_2_bits_lsrc2_valid(x_out_2_bits_lsrc2_valid), .io_out_2_bits_lsrc2_bits(x_out_2_bits_lsrc2_bits), .io_out_2_bits_src2Type_valid(x_out_2_bits_src2Type_valid), .io_out_2_bits_selImm_valid(x_out_2_bits_selImm_valid), .io_out_2_bits_selImm_bits(x_out_2_bits_selImm_bits),
    .io_out_3_valid(x_out_3_valid), .io_out_3_bits_fuType_valid(x_out_3_bits_fuType_valid), .io_out_3_bits_fuOpType_valid(x_out_3_bits_fuOpType_valid), .io_out_3_bits_fuOpType_bits(x_out_3_bits_fuOpType_bits), .io_out_3_bits_lsrc2_valid(x_out_3_bits_lsrc2_valid), .io_out_3_bits_lsrc2_bits(x_out_3_bits_lsrc2_bits), .io_out_3_bits_src2Type_valid(x_out_3_bits_src2Type_valid), .io_out_3_bits_selImm_valid(x_out_3_bits_selImm_valid), .io_out_3_bits_selImm_bits(x_out_3_bits_selImm_bits),
    .io_out_4_valid(x_out_4_valid), .io_out_4_bits_fuType_valid(x_out_4_bits_fuType_valid), .io_out_4_bits_fuOpType_valid(x_out_4_bits_fuOpType_valid), .io_out_4_bits_fuOpType_bits(x_out_4_bits_fuOpType_bits), .io_out_4_bits_lsrc2_valid(x_out_4_bits_lsrc2_valid), .io_out_4_bits_lsrc2_bits(x_out_4_bits_lsrc2_bits), .io_out_4_bits_src2Type_valid(x_out_4_bits_src2Type_valid), .io_out_4_bits_selImm_valid(x_out_4_bits_selImm_valid), .io_out_4_bits_selImm_bits(x_out_4_bits_selImm_bits),
    .io_info_0_rs2FromRs1(x_info_0_rs2FromRs1), .io_info_0_rs2FromRs2(x_info_0_rs2FromRs2), .io_info_0_rs2FromZero(x_info_0_rs2FromZero),
    .io_info_1_rs2FromRs1(x_info_1_rs2FromRs1), .io_info_1_rs2FromRs2(x_info_1_rs2FromRs2), .io_info_1_rs2FromZero(x_info_1_rs2FromZero),
    .io_info_2_rs2FromRs1(x_info_2_rs2FromRs1), .io_info_2_rs2FromRs2(x_info_2_rs2FromRs2), .io_info_2_rs2FromZero(x_info_2_rs2FromZero),
    .io_info_3_rs2FromRs1(x_info_3_rs2FromRs1), .io_info_3_rs2FromRs2(x_info_3_rs2FromRs2), .io_info_3_rs2FromZero(x_info_3_rs2FromZero),
    .io_info_4_rs2FromRs1(x_info_4_rs2FromRs1), .io_info_4_rs2FromRs2(x_info_4_rs2FromRs2), .io_info_4_rs2FromZero(x_info_4_rs2FromZero),
    .io_clear_1(x_clear_1), .io_clear_2(x_clear_2), .io_clear_3(x_clear_3), .io_clear_4(x_clear_4), .io_clear_5(x_clear_5)
  );

  // ---- 指令构造（RV64I/M/Zba/Zbb 编码）----
  function automatic logic [31:0] mk_i(input logic [11:0] imm, input logic [4:0] rs1, input logic [2:0] f3, input logic [4:0] rd, input logic [6:0] op);
    return {imm, rs1, f3, rd, op};
  endfunction
  function automatic logic [31:0] mk_r(input logic [6:0] f7, input logic [4:0] rs2, input logic [4:0] rs1, input logic [2:0] f3, input logic [4:0] rd, input logic [6:0] op);
    return {f7, rs2, rs1, f3, rd, op};
  endfunction
  // 第一条：kind 按 CASES 表；rd 给定，rs1 随机
  function automatic logic [31:0] mk_first(input int kind, input int imm, input logic [4:0] rd);
    logic [4:0] rs1 = 5'($urandom);
    logic [2:0] pick = 3'($urandom_range(0, 6));
    case (kind)
      0: return mk_i({6'b000000, 6'(imm)}, rs1, 3'b001, rd, 7'h13);           // slli
      1: return mk_i({6'b000000, 6'(imm)}, rs1, 3'b101, rd, 7'h13);           // srli
      2: return mk_i({7'b0000000, 5'(imm)}, rs1, 3'b001, rd, 7'h1B);          // slliw
      3: return mk_i(12'(imm), rs1, 3'b111, rd, 7'h13);                       // andi
      4: return $urandom_range(0,1) ? mk_i(12'($urandom), rs1, 3'b000, rd, 7'h1B)   // addiw
                                    : mk_r(7'b0, 5'($urandom), rs1, 3'b000, rd, 7'h3B); // addw
      5: case (pick)                                                          // logic 7 选 1
           0: return mk_i(12'($urandom), rs1, 3'b111, rd, 7'h13);            // andi
           1: return mk_r(7'b0, 5'($urandom), rs1, 3'b111, rd, 7'h33);       // and
           2: return mk_i(12'($urandom), rs1, 3'b110, rd, 7'h13);            // ori
           3: return mk_r(7'b0, 5'($urandom), rs1, 3'b110, rd, 7'h33);       // or
           4: return mk_i(12'($urandom), rs1, 3'b100, rd, 7'h13);            // xori
           5: return mk_r(7'b0, 5'($urandom), rs1, 3'b100, rd, 7'h33);       // xor
           default: return mk_i(12'h287, rs1, 3'b101, rd, 7'h13);            // orc.b
         endcase
      default: return {20'($urandom), rd, 7'h37};                            // lui
    endcase
  endfunction
  // 第二条：kind 按 CASES 表；rd/rs1/rs2 给定
  function automatic logic [31:0] mk_second(input int kind, input int imm, input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2);
    case (kind)
      0: return mk_i({6'b000000, 6'(imm)}, rs1, 3'b101, rd, 7'h13);           // srli
      1: return mk_i({7'b0000000, 5'(imm)}, rs1, 3'b101, rd, 7'h1B);          // srliw
      2: return mk_i({7'b0100000, 5'(imm)}, rs1, 3'b101, rd, 7'h1B);          // sraiw
      3: return mk_r(7'b0, rs2, rs1, 3'b000, rd, 7'h33);                      // add
      4: return mk_r(7'b0, rs2, rs1, 3'b000, rd, 7'h3B);                      // addw
      5: return mk_r(7'b0, rs2, rs1, 3'b110, rd, 7'h33);                      // or
      6: return mk_r(7'b0000001, rs2, rs1, 3'b000, rd, 7'h3B);                // mulw
      7: return mk_i(12'(imm), rs1, 3'b111, rd, 7'h13);                       // andi
      8: return mk_i(12'h080, rs1, 3'b100, rd, 7'h3B);                        // zext.h
      9: return mk_i(12'h605, rs1, 3'b001, rd, 7'h13);                        // sext.h
      10: return mk_i(12'($urandom), rs1, 3'b000, rd, 7'h13);                 // addi
      default: return mk_i(12'($urandom), rs1, 3'b000, rd, 7'h1B);            // addiw
    endcase
  endfunction
  // CASES 表：第一条 kind/imm，第二条 kind/imm
  localparam int NCASE = 28;
  int k1[NCASE], im1[NCASE], k2[NCASE], im2[NCASE];
  string cname[NCASE];
  initial begin
    k1[0] = 0; im1[0] = 32; k2[0] = 0; im2[0] = 32; cname[0] = "ADDUW";
    k1[1] = 0; im1[1] = 48; k2[1] = 0; im2[1] = 48; cname[1] = "ZEXTH";
    k1[2] = 2; im1[2] = 16; k2[2] = 1; im2[2] = 16; cname[2] = "ZEXTH1";
    k1[3] = 2; im1[3] = 16; k2[3] = 2; im2[3] = 16; cname[3] = "SEXTH";
    k1[4] = 0; im1[4] = 1; k2[4] = 3; im2[4] = 0; cname[4] = "SH1ADD";
    k1[5] = 0; im1[5] = 2; k2[5] = 3; im2[5] = 0; cname[5] = "SH2ADD";
    k1[6] = 0; im1[6] = 3; k2[6] = 3; im2[6] = 0; cname[6] = "SH3ADD";
    k1[7] = 0; im1[7] = 32; k2[7] = 0; im2[7] = 31; cname[7] = "SZEWL1";
    k1[8] = 0; im1[8] = 32; k2[8] = 0; im2[8] = 30; cname[8] = "SZEWL2";
    k1[9] = 0; im1[9] = 32; k2[9] = 0; im2[9] = 29; cname[9] = "SZEWL3";
    k1[10] = 1; im1[10] = 8; k2[10] = 7; im2[10] = 255; cname[10] = "BYTE2";
    k1[11] = 0; im1[11] = 4; k2[11] = 3; im2[11] = 0; cname[11] = "SH4ADD";
    k1[12] = 1; im1[12] = 29; k2[12] = 3; im2[12] = 0; cname[12] = "SR29ADD";
    k1[13] = 1; im1[13] = 30; k2[13] = 3; im2[13] = 0; cname[13] = "SR30ADD";
    k1[14] = 1; im1[14] = 31; k2[14] = 3; im2[14] = 0; cname[14] = "SR31ADD";
    k1[15] = 1; im1[15] = 32; k2[15] = 3; im2[15] = 0; cname[15] = "SR32ADD";
    k1[16] = 3; im1[16] = 1; k2[16] = 3; im2[16] = 0; cname[16] = "ODDADD";
    k1[17] = 3; im1[17] = 1; k2[17] = 4; im2[17] = 0; cname[17] = "ODDADDW";
    k1[18] = 3; im1[18] = 3840; k2[18] = 5; im2[18] = 0; cname[18] = "ORH48";
    k1[19] = 3; im1[19] = 127; k2[19] = 6; im2[19] = 0; cname[19] = "MULW7";
    k1[20] = 4; im1[20] = 0; k2[20] = 7; im2[20] = 255; cname[20] = "ADDWBYTE";
    k1[21] = 4; im1[21] = 0; k2[21] = 7; im2[21] = 1; cname[21] = "ADDWBIT";
    k1[22] = 4; im1[22] = 0; k2[22] = 8; im2[22] = 0; cname[22] = "ADDWZEXTH";
    k1[23] = 4; im1[23] = 0; k2[23] = 9; im2[23] = 0; cname[23] = "ADDWSEXTH";
    k1[24] = 5; im1[24] = 0; k2[24] = 7; im2[24] = 1; cname[24] = "LOGICLSB";
    k1[25] = 5; im1[25] = 0; k2[25] = 8; im2[25] = 0; cname[25] = "LOGICZEXTH";
    k1[26] = 6; im1[26] = 0; k2[26] = 10; im2[26] = 0; cname[26] = "LUI32";
    k1[27] = 6; im1[27] = 0; k2[27] = 11; im2[27] = 0; cname[27] = "LUI32W";
  end

  // 构造一对：mode 决定 rd 关系；返回两条指令
  task automatic mk_pair(input int c, output logic [31:0] a, output logic [31:0] b);
    logic [4:0] rd, rs1, rs2; int rel;
    rd  = ($urandom_range(0, 9) == 0) ? 5'h0 : 5'($urandom);   // 10% rd=0（HINT）
    rel = $urandom_range(0, 9);
    // 0-3: rd->rs1(b)  4-6: rd->rs2(b)  7: rs1==rs2==rd  8: 两个都不是 rd  9: 第二条 rd 不同
    case (rel)
      0,1,2,3: begin rs1 = rd; rs2 = 5'($urandom); if (rs2 == rd) rs2 = rd + 5'd1; end
      4,5,6:   begin rs2 = rd; rs1 = 5'($urandom); if (rs1 == rd) rs1 = rd + 5'd1; end
      7:       begin rs1 = rd; rs2 = rd; end
      default: begin rs1 = 5'($urandom); rs2 = 5'($urandom); end
    endcase
    a = mk_first(k1[c], im1[c], rd);
    b = mk_second(k2[c], im2[c], (rel == 9) ? rd ^ 5'h1 : rd, rs1, rs2);
    // 近似模式：15% 把某一位翻掉（移位量/funct/opcode），验证「差一点就不融合」
    if ($urandom_range(0, 99) < 15) begin
      if ($urandom_range(0, 1)) a[$urandom_range(12, 31)] ^= 1'b1; else b[$urandom_range(12, 31)] ^= 1'b1;
    end
  endtask

  logic [31:0] instr [N_IN];
  longint cov_case[5][NCASE]; longint cov_out_valid[5]; longint cov_clear_chain = 0; longint cov_disabled_fire = 0;
  longint cov_rel_rs1 = 0, cov_rel_rs2 = 0, cov_rel_zero = 0;

  task automatic drive_inputs(input bit warm);
    int c, pos; logic [31:0] a, b;
    for (int i = 0; i < N_IN; i++) instr[i] = $urandom;
    // 每拍最多放两对定向模式（相邻/重叠时正好测 clear 链）
    repeat ($urandom_range(0, 2)) begin
      c = $urandom_range(0, NCASE - 1); pos = $urandom_range(0, N_PAIR - 1);
      mk_pair(c, a, b); instr[pos] = a; instr[pos + 1] = b;
    end
    io_in_0_bits  = instr[0];
    io_in_0_valid = warm ? 1'b1 : ($urandom_range(0, 9) < 8);
    io_in_1_bits  = instr[1];
    io_in_1_valid = warm ? 1'b1 : ($urandom_range(0, 9) < 8);
    io_in_2_bits  = instr[2];
    io_in_2_valid = warm ? 1'b1 : ($urandom_range(0, 9) < 8);
    io_in_3_bits  = instr[3];
    io_in_3_valid = warm ? 1'b1 : ($urandom_range(0, 9) < 8);
    io_in_4_bits  = instr[4];
    io_in_4_valid = warm ? 1'b1 : ($urandom_range(0, 9) < 8);
    io_in_5_bits  = instr[5];
    io_in_5_valid = warm ? 1'b1 : ($urandom_range(0, 9) < 8);
    io_inReady_0    = warm ? 1'b1 : ($urandom_range(0, 9) < 7);
    io_dec_0_fuOpType = 9'($urandom);
    io_inReady_1    = warm ? 1'b1 : ($urandom_range(0, 9) < 7);
    io_dec_1_fuOpType = 9'($urandom);
    io_inReady_2    = warm ? 1'b1 : ($urandom_range(0, 9) < 7);
    io_dec_2_fuOpType = 9'($urandom);
    io_inReady_3    = warm ? 1'b1 : ($urandom_range(0, 9) < 7);
    io_dec_3_fuOpType = 9'($urandom);
    io_inReady_4    = warm ? 1'b1 : ($urandom_range(0, 9) < 7);
    io_dec_4_fuOpType = 9'($urandom);
    io_disableFusion = warm ? 1'b0 : ($urandom_range(0, 19) == 0);
  endtask

  task automatic compare_outputs();
    checks++;
    if (g_out_0_valid !== x_out_0_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_0_valid g=%h x=%h", $time, g_out_0_valid, x_out_0_valid); end
    if (g_out_0_bits_fuType_valid !== x_out_0_bits_fuType_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_0_bits_fuType_valid g=%h x=%h", $time, g_out_0_bits_fuType_valid, x_out_0_bits_fuType_valid); end
    if (g_out_0_bits_fuOpType_valid !== x_out_0_bits_fuOpType_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_0_bits_fuOpType_valid g=%h x=%h", $time, g_out_0_bits_fuOpType_valid, x_out_0_bits_fuOpType_valid); end
    if (g_out_0_bits_fuOpType_bits !== x_out_0_bits_fuOpType_bits) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_0_bits_fuOpType_bits g=%h x=%h", $time, g_out_0_bits_fuOpType_bits, x_out_0_bits_fuOpType_bits); end
    if (g_out_0_bits_lsrc2_valid !== x_out_0_bits_lsrc2_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_0_bits_lsrc2_valid g=%h x=%h", $time, g_out_0_bits_lsrc2_valid, x_out_0_bits_lsrc2_valid); end
    if (g_out_0_bits_lsrc2_bits !== x_out_0_bits_lsrc2_bits) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_0_bits_lsrc2_bits g=%h x=%h", $time, g_out_0_bits_lsrc2_bits, x_out_0_bits_lsrc2_bits); end
    if (g_out_0_bits_src2Type_valid !== x_out_0_bits_src2Type_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_0_bits_src2Type_valid g=%h x=%h", $time, g_out_0_bits_src2Type_valid, x_out_0_bits_src2Type_valid); end
    if (g_out_0_bits_selImm_valid !== x_out_0_bits_selImm_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_0_bits_selImm_valid g=%h x=%h", $time, g_out_0_bits_selImm_valid, x_out_0_bits_selImm_valid); end
    if (g_out_0_bits_selImm_bits !== x_out_0_bits_selImm_bits) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_0_bits_selImm_bits g=%h x=%h", $time, g_out_0_bits_selImm_bits, x_out_0_bits_selImm_bits); end
    if (g_info_0_rs2FromRs1 !== x_info_0_rs2FromRs1) begin errors++; if (errors < 20) $display("MISMATCH @%0t info_0_rs2FromRs1 g=%b x=%b", $time, g_info_0_rs2FromRs1, x_info_0_rs2FromRs1); end
    if (g_info_0_rs2FromRs2 !== x_info_0_rs2FromRs2) begin errors++; if (errors < 20) $display("MISMATCH @%0t info_0_rs2FromRs2 g=%b x=%b", $time, g_info_0_rs2FromRs2, x_info_0_rs2FromRs2); end
    if (g_info_0_rs2FromZero !== x_info_0_rs2FromZero) begin errors++; if (errors < 20) $display("MISMATCH @%0t info_0_rs2FromZero g=%b x=%b", $time, g_info_0_rs2FromZero, x_info_0_rs2FromZero); end
    if (g_out_1_valid !== x_out_1_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_1_valid g=%h x=%h", $time, g_out_1_valid, x_out_1_valid); end
    if (g_out_1_bits_fuType_valid !== x_out_1_bits_fuType_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_1_bits_fuType_valid g=%h x=%h", $time, g_out_1_bits_fuType_valid, x_out_1_bits_fuType_valid); end
    if (g_out_1_bits_fuOpType_valid !== x_out_1_bits_fuOpType_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_1_bits_fuOpType_valid g=%h x=%h", $time, g_out_1_bits_fuOpType_valid, x_out_1_bits_fuOpType_valid); end
    if (g_out_1_bits_fuOpType_bits !== x_out_1_bits_fuOpType_bits) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_1_bits_fuOpType_bits g=%h x=%h", $time, g_out_1_bits_fuOpType_bits, x_out_1_bits_fuOpType_bits); end
    if (g_out_1_bits_lsrc2_valid !== x_out_1_bits_lsrc2_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_1_bits_lsrc2_valid g=%h x=%h", $time, g_out_1_bits_lsrc2_valid, x_out_1_bits_lsrc2_valid); end
    if (g_out_1_bits_lsrc2_bits !== x_out_1_bits_lsrc2_bits) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_1_bits_lsrc2_bits g=%h x=%h", $time, g_out_1_bits_lsrc2_bits, x_out_1_bits_lsrc2_bits); end
    if (g_out_1_bits_src2Type_valid !== x_out_1_bits_src2Type_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_1_bits_src2Type_valid g=%h x=%h", $time, g_out_1_bits_src2Type_valid, x_out_1_bits_src2Type_valid); end
    if (g_out_1_bits_selImm_valid !== x_out_1_bits_selImm_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_1_bits_selImm_valid g=%h x=%h", $time, g_out_1_bits_selImm_valid, x_out_1_bits_selImm_valid); end
    if (g_out_1_bits_selImm_bits !== x_out_1_bits_selImm_bits) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_1_bits_selImm_bits g=%h x=%h", $time, g_out_1_bits_selImm_bits, x_out_1_bits_selImm_bits); end
    if (g_info_1_rs2FromRs1 !== x_info_1_rs2FromRs1) begin errors++; if (errors < 20) $display("MISMATCH @%0t info_1_rs2FromRs1 g=%b x=%b", $time, g_info_1_rs2FromRs1, x_info_1_rs2FromRs1); end
    if (g_info_1_rs2FromRs2 !== x_info_1_rs2FromRs2) begin errors++; if (errors < 20) $display("MISMATCH @%0t info_1_rs2FromRs2 g=%b x=%b", $time, g_info_1_rs2FromRs2, x_info_1_rs2FromRs2); end
    if (g_info_1_rs2FromZero !== x_info_1_rs2FromZero) begin errors++; if (errors < 20) $display("MISMATCH @%0t info_1_rs2FromZero g=%b x=%b", $time, g_info_1_rs2FromZero, x_info_1_rs2FromZero); end
    if (g_out_2_valid !== x_out_2_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_2_valid g=%h x=%h", $time, g_out_2_valid, x_out_2_valid); end
    if (g_out_2_bits_fuType_valid !== x_out_2_bits_fuType_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_2_bits_fuType_valid g=%h x=%h", $time, g_out_2_bits_fuType_valid, x_out_2_bits_fuType_valid); end
    if (g_out_2_bits_fuOpType_valid !== x_out_2_bits_fuOpType_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_2_bits_fuOpType_valid g=%h x=%h", $time, g_out_2_bits_fuOpType_valid, x_out_2_bits_fuOpType_valid); end
    if (g_out_2_bits_fuOpType_bits !== x_out_2_bits_fuOpType_bits) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_2_bits_fuOpType_bits g=%h x=%h", $time, g_out_2_bits_fuOpType_bits, x_out_2_bits_fuOpType_bits); end
    if (g_out_2_bits_lsrc2_valid !== x_out_2_bits_lsrc2_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_2_bits_lsrc2_valid g=%h x=%h", $time, g_out_2_bits_lsrc2_valid, x_out_2_bits_lsrc2_valid); end
    if (g_out_2_bits_lsrc2_bits !== x_out_2_bits_lsrc2_bits) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_2_bits_lsrc2_bits g=%h x=%h", $time, g_out_2_bits_lsrc2_bits, x_out_2_bits_lsrc2_bits); end
    if (g_out_2_bits_src2Type_valid !== x_out_2_bits_src2Type_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_2_bits_src2Type_valid g=%h x=%h", $time, g_out_2_bits_src2Type_valid, x_out_2_bits_src2Type_valid); end
    if (g_out_2_bits_selImm_valid !== x_out_2_bits_selImm_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_2_bits_selImm_valid g=%h x=%h", $time, g_out_2_bits_selImm_valid, x_out_2_bits_selImm_valid); end
    if (g_out_2_bits_selImm_bits !== x_out_2_bits_selImm_bits) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_2_bits_selImm_bits g=%h x=%h", $time, g_out_2_bits_selImm_bits, x_out_2_bits_selImm_bits); end
    if (g_info_2_rs2FromRs1 !== x_info_2_rs2FromRs1) begin errors++; if (errors < 20) $display("MISMATCH @%0t info_2_rs2FromRs1 g=%b x=%b", $time, g_info_2_rs2FromRs1, x_info_2_rs2FromRs1); end
    if (g_info_2_rs2FromRs2 !== x_info_2_rs2FromRs2) begin errors++; if (errors < 20) $display("MISMATCH @%0t info_2_rs2FromRs2 g=%b x=%b", $time, g_info_2_rs2FromRs2, x_info_2_rs2FromRs2); end
    if (g_info_2_rs2FromZero !== x_info_2_rs2FromZero) begin errors++; if (errors < 20) $display("MISMATCH @%0t info_2_rs2FromZero g=%b x=%b", $time, g_info_2_rs2FromZero, x_info_2_rs2FromZero); end
    if (g_out_3_valid !== x_out_3_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_3_valid g=%h x=%h", $time, g_out_3_valid, x_out_3_valid); end
    if (g_out_3_bits_fuType_valid !== x_out_3_bits_fuType_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_3_bits_fuType_valid g=%h x=%h", $time, g_out_3_bits_fuType_valid, x_out_3_bits_fuType_valid); end
    if (g_out_3_bits_fuOpType_valid !== x_out_3_bits_fuOpType_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_3_bits_fuOpType_valid g=%h x=%h", $time, g_out_3_bits_fuOpType_valid, x_out_3_bits_fuOpType_valid); end
    if (g_out_3_bits_fuOpType_bits !== x_out_3_bits_fuOpType_bits) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_3_bits_fuOpType_bits g=%h x=%h", $time, g_out_3_bits_fuOpType_bits, x_out_3_bits_fuOpType_bits); end
    if (g_out_3_bits_lsrc2_valid !== x_out_3_bits_lsrc2_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_3_bits_lsrc2_valid g=%h x=%h", $time, g_out_3_bits_lsrc2_valid, x_out_3_bits_lsrc2_valid); end
    if (g_out_3_bits_lsrc2_bits !== x_out_3_bits_lsrc2_bits) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_3_bits_lsrc2_bits g=%h x=%h", $time, g_out_3_bits_lsrc2_bits, x_out_3_bits_lsrc2_bits); end
    if (g_out_3_bits_src2Type_valid !== x_out_3_bits_src2Type_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_3_bits_src2Type_valid g=%h x=%h", $time, g_out_3_bits_src2Type_valid, x_out_3_bits_src2Type_valid); end
    if (g_out_3_bits_selImm_valid !== x_out_3_bits_selImm_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_3_bits_selImm_valid g=%h x=%h", $time, g_out_3_bits_selImm_valid, x_out_3_bits_selImm_valid); end
    if (g_out_3_bits_selImm_bits !== x_out_3_bits_selImm_bits) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_3_bits_selImm_bits g=%h x=%h", $time, g_out_3_bits_selImm_bits, x_out_3_bits_selImm_bits); end
    if (g_info_3_rs2FromRs1 !== x_info_3_rs2FromRs1) begin errors++; if (errors < 20) $display("MISMATCH @%0t info_3_rs2FromRs1 g=%b x=%b", $time, g_info_3_rs2FromRs1, x_info_3_rs2FromRs1); end
    if (g_info_3_rs2FromRs2 !== x_info_3_rs2FromRs2) begin errors++; if (errors < 20) $display("MISMATCH @%0t info_3_rs2FromRs2 g=%b x=%b", $time, g_info_3_rs2FromRs2, x_info_3_rs2FromRs2); end
    if (g_info_3_rs2FromZero !== x_info_3_rs2FromZero) begin errors++; if (errors < 20) $display("MISMATCH @%0t info_3_rs2FromZero g=%b x=%b", $time, g_info_3_rs2FromZero, x_info_3_rs2FromZero); end
    if (g_out_4_valid !== x_out_4_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_4_valid g=%h x=%h", $time, g_out_4_valid, x_out_4_valid); end
    if (g_out_4_bits_fuType_valid !== x_out_4_bits_fuType_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_4_bits_fuType_valid g=%h x=%h", $time, g_out_4_bits_fuType_valid, x_out_4_bits_fuType_valid); end
    if (g_out_4_bits_fuOpType_valid !== x_out_4_bits_fuOpType_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_4_bits_fuOpType_valid g=%h x=%h", $time, g_out_4_bits_fuOpType_valid, x_out_4_bits_fuOpType_valid); end
    if (g_out_4_bits_fuOpType_bits !== x_out_4_bits_fuOpType_bits) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_4_bits_fuOpType_bits g=%h x=%h", $time, g_out_4_bits_fuOpType_bits, x_out_4_bits_fuOpType_bits); end
    if (g_out_4_bits_lsrc2_valid !== x_out_4_bits_lsrc2_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_4_bits_lsrc2_valid g=%h x=%h", $time, g_out_4_bits_lsrc2_valid, x_out_4_bits_lsrc2_valid); end
    if (g_out_4_bits_lsrc2_bits !== x_out_4_bits_lsrc2_bits) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_4_bits_lsrc2_bits g=%h x=%h", $time, g_out_4_bits_lsrc2_bits, x_out_4_bits_lsrc2_bits); end
    if (g_out_4_bits_src2Type_valid !== x_out_4_bits_src2Type_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_4_bits_src2Type_valid g=%h x=%h", $time, g_out_4_bits_src2Type_valid, x_out_4_bits_src2Type_valid); end
    if (g_out_4_bits_selImm_valid !== x_out_4_bits_selImm_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_4_bits_selImm_valid g=%h x=%h", $time, g_out_4_bits_selImm_valid, x_out_4_bits_selImm_valid); end
    if (g_out_4_bits_selImm_bits !== x_out_4_bits_selImm_bits) begin errors++; if (errors < 20) $display("MISMATCH @%0t out_4_bits_selImm_bits g=%h x=%h", $time, g_out_4_bits_selImm_bits, x_out_4_bits_selImm_bits); end
    if (g_info_4_rs2FromRs1 !== x_info_4_rs2FromRs1) begin errors++; if (errors < 20) $display("MISMATCH @%0t info_4_rs2FromRs1 g=%b x=%b", $time, g_info_4_rs2FromRs1, x_info_4_rs2FromRs1); end
    if (g_info_4_rs2FromRs2 !== x_info_4_rs2FromRs2) begin errors++; if (errors < 20) $display("MISMATCH @%0t info_4_rs2FromRs2 g=%b x=%b", $time, g_info_4_rs2FromRs2, x_info_4_rs2FromRs2); end
    if (g_info_4_rs2FromZero !== x_info_4_rs2FromZero) begin errors++; if (errors < 20) $display("MISMATCH @%0t info_4_rs2FromZero g=%b x=%b", $time, g_info_4_rs2FromZero, x_info_4_rs2FromZero); end
    if (g_clear_1 !== x_clear_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t clear_1 g=%b x=%b", $time, g_clear_1, x_clear_1); end
    if (g_clear_2 !== x_clear_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t clear_2 g=%b x=%b", $time, g_clear_2, x_clear_2); end
    if (g_clear_3 !== x_clear_3) begin errors++; if (errors < 20) $display("MISMATCH @%0t clear_3 g=%b x=%b", $time, g_clear_3, x_clear_3); end
    if (g_clear_4 !== x_clear_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t clear_4 g=%b x=%b", $time, g_clear_4, x_clear_4); end
    if (g_clear_5 !== x_clear_5) begin errors++; if (errors < 20) $display("MISMATCH @%0t clear_5 g=%b x=%b", $time, g_clear_5, x_clear_5); end
  endtask

  // 覆盖：从 golden 内部展平寄存器取（独立于被测件）
  task automatic collect_cov();
    if (u_gold.fusionVec_0 === 1'b1) cov_case[0][0]++;
    if (u_gold.fusionVec_1 === 1'b1) cov_case[0][1]++;
    if (u_gold.fusionVec_2 === 1'b1) cov_case[0][2]++;
    if (u_gold.fusionVec_3 === 1'b1) cov_case[0][3]++;
    if (u_gold.fusionVec_4 === 1'b1) cov_case[0][4]++;
    if (u_gold.fusionVec_5 === 1'b1) cov_case[0][5]++;
    if (u_gold.fusionVec_6 === 1'b1) cov_case[0][6]++;
    if (u_gold.fusionVec_7 === 1'b1) cov_case[0][7]++;
    if (u_gold.fusionVec_8 === 1'b1) cov_case[0][8]++;
    if (u_gold.fusionVec_9 === 1'b1) cov_case[0][9]++;
    if (u_gold.fusionVec_10 === 1'b1) cov_case[0][10]++;
    if (u_gold.fusionVec_11 === 1'b1) cov_case[0][11]++;
    if (u_gold.fusionVec_12 === 1'b1) cov_case[0][12]++;
    if (u_gold.fusionVec_13 === 1'b1) cov_case[0][13]++;
    if (u_gold.fusionVec_14 === 1'b1) cov_case[0][14]++;
    if (u_gold.fusionVec_15 === 1'b1) cov_case[0][15]++;
    if (u_gold.fusionVec_16 === 1'b1) cov_case[0][16]++;
    if (u_gold.fusionVec_17 === 1'b1) cov_case[0][17]++;
    if (u_gold.fusionVec_18 === 1'b1) cov_case[0][18]++;
    if (u_gold.fusionVec_19 === 1'b1) cov_case[0][19]++;
    if (u_gold.fusionVec_20 === 1'b1) cov_case[0][20]++;
    if (u_gold.fusionVec_21 === 1'b1) cov_case[0][21]++;
    if (u_gold.fusionVec_22 === 1'b1) cov_case[0][22]++;
    if (u_gold.fusionVec_23 === 1'b1) cov_case[0][23]++;
    if (u_gold.fusionVec_24 === 1'b1) cov_case[0][24]++;
    if (u_gold.fusionVec_25 === 1'b1) cov_case[0][25]++;
    if (u_gold.fusionVec_26 === 1'b1) cov_case[0][26]++;
    if (u_gold.fusionVec_27 === 1'b1) cov_case[0][27]++;
    if (g_out_0_valid === 1'b1) cov_out_valid[0]++;
    if (g_info_0_rs2FromRs1 === 1'b1) cov_rel_rs1++;
    if (g_info_0_rs2FromRs2 === 1'b1) cov_rel_rs2++;
    if (g_info_0_rs2FromZero === 1'b1) cov_rel_zero++;
    if (u_gold.fusionVec_1_0 === 1'b1) cov_case[1][0]++;
    if (u_gold.fusionVec_1_1 === 1'b1) cov_case[1][1]++;
    if (u_gold.fusionVec_1_2 === 1'b1) cov_case[1][2]++;
    if (u_gold.fusionVec_1_3 === 1'b1) cov_case[1][3]++;
    if (u_gold.fusionVec_1_4 === 1'b1) cov_case[1][4]++;
    if (u_gold.fusionVec_1_5 === 1'b1) cov_case[1][5]++;
    if (u_gold.fusionVec_1_6 === 1'b1) cov_case[1][6]++;
    if (u_gold.fusionVec_1_7 === 1'b1) cov_case[1][7]++;
    if (u_gold.fusionVec_1_8 === 1'b1) cov_case[1][8]++;
    if (u_gold.fusionVec_1_9 === 1'b1) cov_case[1][9]++;
    if (u_gold.fusionVec_1_10 === 1'b1) cov_case[1][10]++;
    if (u_gold.fusionVec_1_11 === 1'b1) cov_case[1][11]++;
    if (u_gold.fusionVec_1_12 === 1'b1) cov_case[1][12]++;
    if (u_gold.fusionVec_1_13 === 1'b1) cov_case[1][13]++;
    if (u_gold.fusionVec_1_14 === 1'b1) cov_case[1][14]++;
    if (u_gold.fusionVec_1_15 === 1'b1) cov_case[1][15]++;
    if (u_gold.fusionVec_1_16 === 1'b1) cov_case[1][16]++;
    if (u_gold.fusionVec_1_17 === 1'b1) cov_case[1][17]++;
    if (u_gold.fusionVec_1_18 === 1'b1) cov_case[1][18]++;
    if (u_gold.fusionVec_1_19 === 1'b1) cov_case[1][19]++;
    if (u_gold.fusionVec_1_20 === 1'b1) cov_case[1][20]++;
    if (u_gold.fusionVec_1_21 === 1'b1) cov_case[1][21]++;
    if (u_gold.fusionVec_1_22 === 1'b1) cov_case[1][22]++;
    if (u_gold.fusionVec_1_23 === 1'b1) cov_case[1][23]++;
    if (u_gold.fusionVec_1_24 === 1'b1) cov_case[1][24]++;
    if (u_gold.fusionVec_1_25 === 1'b1) cov_case[1][25]++;
    if (u_gold.fusionVec_1_26 === 1'b1) cov_case[1][26]++;
    if (u_gold.fusionVec_1_27 === 1'b1) cov_case[1][27]++;
    if (g_out_1_valid === 1'b1) cov_out_valid[1]++;
    if (g_info_1_rs2FromRs1 === 1'b1) cov_rel_rs1++;
    if (g_info_1_rs2FromRs2 === 1'b1) cov_rel_rs2++;
    if (g_info_1_rs2FromZero === 1'b1) cov_rel_zero++;
    if (u_gold.fusionVec_2_0 === 1'b1) cov_case[2][0]++;
    if (u_gold.fusionVec_2_1 === 1'b1) cov_case[2][1]++;
    if (u_gold.fusionVec_2_2 === 1'b1) cov_case[2][2]++;
    if (u_gold.fusionVec_2_3 === 1'b1) cov_case[2][3]++;
    if (u_gold.fusionVec_2_4 === 1'b1) cov_case[2][4]++;
    if (u_gold.fusionVec_2_5 === 1'b1) cov_case[2][5]++;
    if (u_gold.fusionVec_2_6 === 1'b1) cov_case[2][6]++;
    if (u_gold.fusionVec_2_7 === 1'b1) cov_case[2][7]++;
    if (u_gold.fusionVec_2_8 === 1'b1) cov_case[2][8]++;
    if (u_gold.fusionVec_2_9 === 1'b1) cov_case[2][9]++;
    if (u_gold.fusionVec_2_10 === 1'b1) cov_case[2][10]++;
    if (u_gold.fusionVec_2_11 === 1'b1) cov_case[2][11]++;
    if (u_gold.fusionVec_2_12 === 1'b1) cov_case[2][12]++;
    if (u_gold.fusionVec_2_13 === 1'b1) cov_case[2][13]++;
    if (u_gold.fusionVec_2_14 === 1'b1) cov_case[2][14]++;
    if (u_gold.fusionVec_2_15 === 1'b1) cov_case[2][15]++;
    if (u_gold.fusionVec_2_16 === 1'b1) cov_case[2][16]++;
    if (u_gold.fusionVec_2_17 === 1'b1) cov_case[2][17]++;
    if (u_gold.fusionVec_2_18 === 1'b1) cov_case[2][18]++;
    if (u_gold.fusionVec_2_19 === 1'b1) cov_case[2][19]++;
    if (u_gold.fusionVec_2_20 === 1'b1) cov_case[2][20]++;
    if (u_gold.fusionVec_2_21 === 1'b1) cov_case[2][21]++;
    if (u_gold.fusionVec_2_22 === 1'b1) cov_case[2][22]++;
    if (u_gold.fusionVec_2_23 === 1'b1) cov_case[2][23]++;
    if (u_gold.fusionVec_2_24 === 1'b1) cov_case[2][24]++;
    if (u_gold.fusionVec_2_25 === 1'b1) cov_case[2][25]++;
    if (u_gold.fusionVec_2_26 === 1'b1) cov_case[2][26]++;
    if (u_gold.fusionVec_2_27 === 1'b1) cov_case[2][27]++;
    if (g_out_2_valid === 1'b1) cov_out_valid[2]++;
    if (g_info_2_rs2FromRs1 === 1'b1) cov_rel_rs1++;
    if (g_info_2_rs2FromRs2 === 1'b1) cov_rel_rs2++;
    if (g_info_2_rs2FromZero === 1'b1) cov_rel_zero++;
    if (u_gold.fusionVec_3_0 === 1'b1) cov_case[3][0]++;
    if (u_gold.fusionVec_3_1 === 1'b1) cov_case[3][1]++;
    if (u_gold.fusionVec_3_2 === 1'b1) cov_case[3][2]++;
    if (u_gold.fusionVec_3_3 === 1'b1) cov_case[3][3]++;
    if (u_gold.fusionVec_3_4 === 1'b1) cov_case[3][4]++;
    if (u_gold.fusionVec_3_5 === 1'b1) cov_case[3][5]++;
    if (u_gold.fusionVec_3_6 === 1'b1) cov_case[3][6]++;
    if (u_gold.fusionVec_3_7 === 1'b1) cov_case[3][7]++;
    if (u_gold.fusionVec_3_8 === 1'b1) cov_case[3][8]++;
    if (u_gold.fusionVec_3_9 === 1'b1) cov_case[3][9]++;
    if (u_gold.fusionVec_3_10 === 1'b1) cov_case[3][10]++;
    if (u_gold.fusionVec_3_11 === 1'b1) cov_case[3][11]++;
    if (u_gold.fusionVec_3_12 === 1'b1) cov_case[3][12]++;
    if (u_gold.fusionVec_3_13 === 1'b1) cov_case[3][13]++;
    if (u_gold.fusionVec_3_14 === 1'b1) cov_case[3][14]++;
    if (u_gold.fusionVec_3_15 === 1'b1) cov_case[3][15]++;
    if (u_gold.fusionVec_3_16 === 1'b1) cov_case[3][16]++;
    if (u_gold.fusionVec_3_17 === 1'b1) cov_case[3][17]++;
    if (u_gold.fusionVec_3_18 === 1'b1) cov_case[3][18]++;
    if (u_gold.fusionVec_3_19 === 1'b1) cov_case[3][19]++;
    if (u_gold.fusionVec_3_20 === 1'b1) cov_case[3][20]++;
    if (u_gold.fusionVec_3_21 === 1'b1) cov_case[3][21]++;
    if (u_gold.fusionVec_3_22 === 1'b1) cov_case[3][22]++;
    if (u_gold.fusionVec_3_23 === 1'b1) cov_case[3][23]++;
    if (u_gold.fusionVec_3_24 === 1'b1) cov_case[3][24]++;
    if (u_gold.fusionVec_3_25 === 1'b1) cov_case[3][25]++;
    if (u_gold.fusionVec_3_26 === 1'b1) cov_case[3][26]++;
    if (u_gold.fusionVec_3_27 === 1'b1) cov_case[3][27]++;
    if (g_out_3_valid === 1'b1) cov_out_valid[3]++;
    if (g_info_3_rs2FromRs1 === 1'b1) cov_rel_rs1++;
    if (g_info_3_rs2FromRs2 === 1'b1) cov_rel_rs2++;
    if (g_info_3_rs2FromZero === 1'b1) cov_rel_zero++;
    if (u_gold.fusionVec_4_0 === 1'b1) cov_case[4][0]++;
    if (u_gold.fusionVec_4_1 === 1'b1) cov_case[4][1]++;
    if (u_gold.fusionVec_4_2 === 1'b1) cov_case[4][2]++;
    if (u_gold.fusionVec_4_3 === 1'b1) cov_case[4][3]++;
    if (u_gold.fusionVec_4_4 === 1'b1) cov_case[4][4]++;
    if (u_gold.fusionVec_4_5 === 1'b1) cov_case[4][5]++;
    if (u_gold.fusionVec_4_6 === 1'b1) cov_case[4][6]++;
    if (u_gold.fusionVec_4_7 === 1'b1) cov_case[4][7]++;
    if (u_gold.fusionVec_4_8 === 1'b1) cov_case[4][8]++;
    if (u_gold.fusionVec_4_9 === 1'b1) cov_case[4][9]++;
    if (u_gold.fusionVec_4_10 === 1'b1) cov_case[4][10]++;
    if (u_gold.fusionVec_4_11 === 1'b1) cov_case[4][11]++;
    if (u_gold.fusionVec_4_12 === 1'b1) cov_case[4][12]++;
    if (u_gold.fusionVec_4_13 === 1'b1) cov_case[4][13]++;
    if (u_gold.fusionVec_4_14 === 1'b1) cov_case[4][14]++;
    if (u_gold.fusionVec_4_15 === 1'b1) cov_case[4][15]++;
    if (u_gold.fusionVec_4_16 === 1'b1) cov_case[4][16]++;
    if (u_gold.fusionVec_4_17 === 1'b1) cov_case[4][17]++;
    if (u_gold.fusionVec_4_18 === 1'b1) cov_case[4][18]++;
    if (u_gold.fusionVec_4_19 === 1'b1) cov_case[4][19]++;
    if (u_gold.fusionVec_4_20 === 1'b1) cov_case[4][20]++;
    if (u_gold.fusionVec_4_21 === 1'b1) cov_case[4][21]++;
    if (u_gold.fusionVec_4_22 === 1'b1) cov_case[4][22]++;
    if (u_gold.fusionVec_4_23 === 1'b1) cov_case[4][23]++;
    if (u_gold.fusionVec_4_24 === 1'b1) cov_case[4][24]++;
    if (u_gold.fusionVec_4_25 === 1'b1) cov_case[4][25]++;
    if (u_gold.fusionVec_4_26 === 1'b1) cov_case[4][26]++;
    if (u_gold.fusionVec_4_27 === 1'b1) cov_case[4][27]++;
    if (g_out_4_valid === 1'b1) cov_out_valid[4]++;
    if (g_info_4_rs2FromRs1 === 1'b1) cov_rel_rs1++;
    if (g_info_4_rs2FromRs2 === 1'b1) cov_rel_rs2++;
    if (g_info_4_rs2FromZero === 1'b1) cov_rel_zero++;
    // clear 链真正生效：上一对 clear 拉高、本对本来也匹配（golden 的 conflict_fusion 事件）
    if (g_clear_1 === 1'b1 && u_gold.instrPairValid_1 === 1'b1 && ((u_gold.fusionVec_1_0 | u_gold.fusionVec_1_1 | u_gold.fusionVec_1_2 | u_gold.fusionVec_1_3 | u_gold.fusionVec_1_4 | u_gold.fusionVec_1_5 | u_gold.fusionVec_1_6 | u_gold.fusionVec_1_7 | u_gold.fusionVec_1_8 | u_gold.fusionVec_1_9 | u_gold.fusionVec_1_10 | u_gold.fusionVec_1_11 | u_gold.fusionVec_1_12 | u_gold.fusionVec_1_13 | u_gold.fusionVec_1_14 | u_gold.fusionVec_1_15 | u_gold.fusionVec_1_16 | u_gold.fusionVec_1_17 | u_gold.fusionVec_1_18 | u_gold.fusionVec_1_19 | u_gold.fusionVec_1_20 | u_gold.fusionVec_1_21 | u_gold.fusionVec_1_22 | u_gold.fusionVec_1_23 | u_gold.fusionVec_1_24 | u_gold.fusionVec_1_25 | u_gold.fusionVec_1_26 | u_gold.fusionVec_1_27) === 1'b1)) cov_clear_chain++;
    if (g_clear_2 === 1'b1 && u_gold.instrPairValid_2 === 1'b1 && ((u_gold.fusionVec_2_0 | u_gold.fusionVec_2_1 | u_gold.fusionVec_2_2 | u_gold.fusionVec_2_3 | u_gold.fusionVec_2_4 | u_gold.fusionVec_2_5 | u_gold.fusionVec_2_6 | u_gold.fusionVec_2_7 | u_gold.fusionVec_2_8 | u_gold.fusionVec_2_9 | u_gold.fusionVec_2_10 | u_gold.fusionVec_2_11 | u_gold.fusionVec_2_12 | u_gold.fusionVec_2_13 | u_gold.fusionVec_2_14 | u_gold.fusionVec_2_15 | u_gold.fusionVec_2_16 | u_gold.fusionVec_2_17 | u_gold.fusionVec_2_18 | u_gold.fusionVec_2_19 | u_gold.fusionVec_2_20 | u_gold.fusionVec_2_21 | u_gold.fusionVec_2_22 | u_gold.fusionVec_2_23 | u_gold.fusionVec_2_24 | u_gold.fusionVec_2_25 | u_gold.fusionVec_2_26 | u_gold.fusionVec_2_27) === 1'b1)) cov_clear_chain++;
    if (g_clear_3 === 1'b1 && u_gold.instrPairValid_3 === 1'b1 && ((u_gold.fusionVec_3_0 | u_gold.fusionVec_3_1 | u_gold.fusionVec_3_2 | u_gold.fusionVec_3_3 | u_gold.fusionVec_3_4 | u_gold.fusionVec_3_5 | u_gold.fusionVec_3_6 | u_gold.fusionVec_3_7 | u_gold.fusionVec_3_8 | u_gold.fusionVec_3_9 | u_gold.fusionVec_3_10 | u_gold.fusionVec_3_11 | u_gold.fusionVec_3_12 | u_gold.fusionVec_3_13 | u_gold.fusionVec_3_14 | u_gold.fusionVec_3_15 | u_gold.fusionVec_3_16 | u_gold.fusionVec_3_17 | u_gold.fusionVec_3_18 | u_gold.fusionVec_3_19 | u_gold.fusionVec_3_20 | u_gold.fusionVec_3_21 | u_gold.fusionVec_3_22 | u_gold.fusionVec_3_23 | u_gold.fusionVec_3_24 | u_gold.fusionVec_3_25 | u_gold.fusionVec_3_26 | u_gold.fusionVec_3_27) === 1'b1)) cov_clear_chain++;
    if (g_clear_4 === 1'b1 && u_gold.instrPairValid_4 === 1'b1 && ((u_gold.fusionVec_4_0 | u_gold.fusionVec_4_1 | u_gold.fusionVec_4_2 | u_gold.fusionVec_4_3 | u_gold.fusionVec_4_4 | u_gold.fusionVec_4_5 | u_gold.fusionVec_4_6 | u_gold.fusionVec_4_7 | u_gold.fusionVec_4_8 | u_gold.fusionVec_4_9 | u_gold.fusionVec_4_10 | u_gold.fusionVec_4_11 | u_gold.fusionVec_4_12 | u_gold.fusionVec_4_13 | u_gold.fusionVec_4_14 | u_gold.fusionVec_4_15 | u_gold.fusionVec_4_16 | u_gold.fusionVec_4_17 | u_gold.fusionVec_4_18 | u_gold.fusionVec_4_19 | u_gold.fusionVec_4_20 | u_gold.fusionVec_4_21 | u_gold.fusionVec_4_22 | u_gold.fusionVec_4_23 | u_gold.fusionVec_4_24 | u_gold.fusionVec_4_25 | u_gold.fusionVec_4_26 | u_gold.fusionVec_4_27) === 1'b1)) cov_clear_chain++;
    if (io_disableFusion === 1'b1 && (io_in_0_valid & io_inReady_0)) cov_disabled_fire++;
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int i = 0; i < N_PAIR; i++) begin cov_out_valid[i] = 0; for (int k = 0; k < NCASE; k++) cov_case[i][k] = 0; end
    rst = 1'b1; drive_inputs(1'b1);
    repeat (4) @(negedge clk);
    rst = 1'b0;
    for (longint c = 0; c < NCYCLES; c++) begin
      // 运行中多次异步复位（每 ~8000 拍 2 拍），复位期间照常打激励并比对
      rst = ((c % 8192) < 2) && (c > WARMUP);
      drive_inputs(c < WARMUP);
      #1;
      if (c >= WARMUP) begin compare_outputs(); collect_cov(); end
      @(negedge clk);
    end
    $display("=== COVERAGE (FusionDecoder) ===");
    $display("  checks=%0d  rs2FromRs1=%0d rs2FromRs2=%0d rs2FromZero=%0d clear_chain=%0d disabled_fire=%0d", checks, cov_rel_rs1, cov_rel_rs2, cov_rel_zero, cov_clear_chain, cov_disabled_fire);
    begin
      int zero = 0; longint minhit = -1;
      for (int i = 0; i < N_PAIR; i++) begin
        $display("  pair %0d: out_valid=%0d", i, cov_out_valid[i]);
        for (int k = 0; k < NCASE; k++) begin
          if (cov_case[i][k] == 0) begin zero++; $display("  ZERO-HIT pair %0d case %s", i, cname[k]); end
          if (minhit < 0 || cov_case[i][k] < minhit) minhit = cov_case[i][k];
        end
      end
      $display("  5x28 (pair,case) 未命中 %0d 个，最少命中 %0d", zero, minhit);
      if (zero != 0) begin $display("COVERAGE INSUFFICIENT"); errors++; end
      if (cov_rel_rs1 == 0 || cov_rel_rs2 == 0 || cov_rel_zero == 0 || cov_clear_chain == 0 || cov_disabled_fire == 0) begin
        $display("COVERAGE INSUFFICIENT: rs1/rs2/zero/clear链/disableFusion 有一项没打到"); errors++;
      end
    end
    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
