// =============================================================================
// xs_predecode_pkg —— 预解码共享译码函数
//
// 对应 Chisel: xiangshan.frontend.HasPdConst 的 brInfo / isLink / isRVC 等。
// 供 PreDecode、F3Predecoder 等复用，保证分支译码语义单一来源。
// =============================================================================
package xs_predecode_pkg;

  // BrType 编码（与 Chisel object BrType 一致）
  localparam logic [1:0] BR_NOTCFI = 2'b00, BR_BRANCH = 2'b01,
                         BR_JAL = 2'b10, BR_JALR = 2'b11;

  function automatic logic xs_is_rvc(input logic [31:0] inst);
    return (inst[1:0] != 2'b11);
  endfunction

  function automatic logic xs_is_link(input logic [4:0] r);
    return (r == 5'd1) || (r == 5'd5);
  endfunction

  // 分支类型译码（优先级：C.EBREAK→notCFI 高于 C.JALR；其余互斥）
  function automatic logic [1:0] xs_br_type(input logic [31:0] inst);
    logic c_ebreak, c_j, c_jalr, c_branch, i_jal, i_jalr, i_branch;
    c_ebreak = (inst[15:13] == 3'b100) && (inst[11:2] == 10'b0) && (inst[1:0] == 2'b10);
    c_j      = (inst[15:13] == 3'b101) && (inst[1:0] == 2'b01);
    c_jalr   = (inst[15:13] == 3'b100) && (inst[6:2] == 5'b0) && (inst[1:0] == 2'b10);
    c_branch = (inst[15:14] == 2'b11) && (inst[1:0] == 2'b01);
    i_jal    = (inst[6:0] == 7'b1101111);
    i_jalr   = (inst[14:12] == 3'b000) && (inst[6:0] == 7'b1100111);
    i_branch = (inst[6:0] == 7'b1100011);
    if (c_ebreak)                   return BR_NOTCFI;
    else if (c_j || i_jal)          return BR_JAL;
    else if (c_jalr || i_jalr)      return BR_JALR;
    else if (c_branch || i_branch)  return BR_BRANCH;
    else                            return BR_NOTCFI;
  endfunction

  // rd/rs 抽取（RVC 时按 C 编码）
  function automatic logic [4:0] xs_rd(input logic [31:0] inst);
    return xs_is_rvc(inst) ? {4'b0, inst[12]} : inst[11:7];
  endfunction

  function automatic logic [4:0] xs_rs(input logic [31:0] inst);
    logic [1:0] bt = xs_br_type(inst);
    return xs_is_rvc(inst) ? (bt == BR_JAL ? 5'b0 : inst[11:7]) : inst[19:15];
  endfunction

  function automatic logic xs_is_call(input logic [31:0] inst);
    logic [1:0] bt = xs_br_type(inst);
    return ((bt == BR_JAL && !xs_is_rvc(inst)) || bt == BR_JALR) && xs_is_link(xs_rd(inst));
  endfunction

  function automatic logic xs_is_ret(input logic [31:0] inst);
    logic [1:0] bt = xs_br_type(inst);
    return (bt == BR_JALR) && xs_is_link(xs_rs(inst)) && !xs_is_call(inst);
  endfunction

endpackage

// =============================================================================
// xs_F3Predecoder_core —— F3 阶段分支预译码（纯组合）
//
// 对应 Chisel: xiangshan.frontend.F3Predecoder
// 在 IFU 的 F3 级对 PredictWidth 条已对齐的 32-bit 指令做分支信息译码，只输出
// brType/isCall/isRet（valid/isRVC 在该模块为 DontCare，不引出）。译码逻辑与
// PreDecode 完全相同，复用 xs_predecode_pkg。
// =============================================================================
import xs_predecode_pkg::*;


module xs_F3Predecoder_core #(
  parameter int unsigned PW = 16
)(
  input  logic [PW-1:0][31:0] io_instr,
  output logic [PW-1:0][1:0]  pd_brType,
  output logic [PW-1:0]       pd_isCall,
  output logic [PW-1:0]       pd_isRet
);
  for (genvar i = 0; i < PW; i++) begin : g_dec
    assign pd_brType[i] = xs_br_type(io_instr[i]);
    assign pd_isCall[i] = xs_is_call(io_instr[i]);
    assign pd_isRet[i]  = xs_is_ret(io_instr[i]);
  end
endmodule

// 自动生成：xs-v2r2-sv/scripts/gen_f3predecoder.py —— 该脚本未移植到本轮(它按上一轮规范产出独立 _wrapper.sv)，本文件手工维护

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module F3Predecoder(
  input  [31:0] io_in_instr_0,
  input  [31:0] io_in_instr_1,
  input  [31:0] io_in_instr_2,
  input  [31:0] io_in_instr_3,
  input  [31:0] io_in_instr_4,
  input  [31:0] io_in_instr_5,
  input  [31:0] io_in_instr_6,
  input  [31:0] io_in_instr_7,
  input  [31:0] io_in_instr_8,
  input  [31:0] io_in_instr_9,
  input  [31:0] io_in_instr_10,
  input  [31:0] io_in_instr_11,
  input  [31:0] io_in_instr_12,
  input  [31:0] io_in_instr_13,
  input  [31:0] io_in_instr_14,
  input  [31:0] io_in_instr_15,
  output [1:0] io_out_pd_0_brType,
  output io_out_pd_0_isCall,
  output io_out_pd_0_isRet,
  output [1:0] io_out_pd_1_brType,
  output io_out_pd_1_isCall,
  output io_out_pd_1_isRet,
  output [1:0] io_out_pd_2_brType,
  output io_out_pd_2_isCall,
  output io_out_pd_2_isRet,
  output [1:0] io_out_pd_3_brType,
  output io_out_pd_3_isCall,
  output io_out_pd_3_isRet,
  output [1:0] io_out_pd_4_brType,
  output io_out_pd_4_isCall,
  output io_out_pd_4_isRet,
  output [1:0] io_out_pd_5_brType,
  output io_out_pd_5_isCall,
  output io_out_pd_5_isRet,
  output [1:0] io_out_pd_6_brType,
  output io_out_pd_6_isCall,
  output io_out_pd_6_isRet,
  output [1:0] io_out_pd_7_brType,
  output io_out_pd_7_isCall,
  output io_out_pd_7_isRet,
  output [1:0] io_out_pd_8_brType,
  output io_out_pd_8_isCall,
  output io_out_pd_8_isRet,
  output [1:0] io_out_pd_9_brType,
  output io_out_pd_9_isCall,
  output io_out_pd_9_isRet,
  output [1:0] io_out_pd_10_brType,
  output io_out_pd_10_isCall,
  output io_out_pd_10_isRet,
  output [1:0] io_out_pd_11_brType,
  output io_out_pd_11_isCall,
  output io_out_pd_11_isRet,
  output [1:0] io_out_pd_12_brType,
  output io_out_pd_12_isCall,
  output io_out_pd_12_isRet,
  output [1:0] io_out_pd_13_brType,
  output io_out_pd_13_isCall,
  output io_out_pd_13_isRet,
  output [1:0] io_out_pd_14_brType,
  output io_out_pd_14_isCall,
  output io_out_pd_14_isRet,
  output [1:0] io_out_pd_15_brType,
  output io_out_pd_15_isCall,
  output io_out_pd_15_isRet
);
  wire [15:0][31:0] instr_arr;
  assign instr_arr[0] = io_in_instr_0;
  assign instr_arr[1] = io_in_instr_1;
  assign instr_arr[2] = io_in_instr_2;
  assign instr_arr[3] = io_in_instr_3;
  assign instr_arr[4] = io_in_instr_4;
  assign instr_arr[5] = io_in_instr_5;
  assign instr_arr[6] = io_in_instr_6;
  assign instr_arr[7] = io_in_instr_7;
  assign instr_arr[8] = io_in_instr_8;
  assign instr_arr[9] = io_in_instr_9;
  assign instr_arr[10] = io_in_instr_10;
  assign instr_arr[11] = io_in_instr_11;
  assign instr_arr[12] = io_in_instr_12;
  assign instr_arr[13] = io_in_instr_13;
  assign instr_arr[14] = io_in_instr_14;
  assign instr_arr[15] = io_in_instr_15;
  wire [15:0][1:0] c_brType;
  wire [15:0]      c_isCall, c_isRet;
  xs_F3Predecoder_core #(.PW(16)) u_core (
    .io_instr(instr_arr), .pd_brType(c_brType),
    .pd_isCall(c_isCall), .pd_isRet(c_isRet)
  );
  assign io_out_pd_0_brType = c_brType[0];
  assign io_out_pd_0_isCall = c_isCall[0];
  assign io_out_pd_0_isRet = c_isRet[0];
  assign io_out_pd_1_brType = c_brType[1];
  assign io_out_pd_1_isCall = c_isCall[1];
  assign io_out_pd_1_isRet = c_isRet[1];
  assign io_out_pd_2_brType = c_brType[2];
  assign io_out_pd_2_isCall = c_isCall[2];
  assign io_out_pd_2_isRet = c_isRet[2];
  assign io_out_pd_3_brType = c_brType[3];
  assign io_out_pd_3_isCall = c_isCall[3];
  assign io_out_pd_3_isRet = c_isRet[3];
  assign io_out_pd_4_brType = c_brType[4];
  assign io_out_pd_4_isCall = c_isCall[4];
  assign io_out_pd_4_isRet = c_isRet[4];
  assign io_out_pd_5_brType = c_brType[5];
  assign io_out_pd_5_isCall = c_isCall[5];
  assign io_out_pd_5_isRet = c_isRet[5];
  assign io_out_pd_6_brType = c_brType[6];
  assign io_out_pd_6_isCall = c_isCall[6];
  assign io_out_pd_6_isRet = c_isRet[6];
  assign io_out_pd_7_brType = c_brType[7];
  assign io_out_pd_7_isCall = c_isCall[7];
  assign io_out_pd_7_isRet = c_isRet[7];
  assign io_out_pd_8_brType = c_brType[8];
  assign io_out_pd_8_isCall = c_isCall[8];
  assign io_out_pd_8_isRet = c_isRet[8];
  assign io_out_pd_9_brType = c_brType[9];
  assign io_out_pd_9_isCall = c_isCall[9];
  assign io_out_pd_9_isRet = c_isRet[9];
  assign io_out_pd_10_brType = c_brType[10];
  assign io_out_pd_10_isCall = c_isCall[10];
  assign io_out_pd_10_isRet = c_isRet[10];
  assign io_out_pd_11_brType = c_brType[11];
  assign io_out_pd_11_isCall = c_isCall[11];
  assign io_out_pd_11_isRet = c_isRet[11];
  assign io_out_pd_12_brType = c_brType[12];
  assign io_out_pd_12_isCall = c_isCall[12];
  assign io_out_pd_12_isRet = c_isRet[12];
  assign io_out_pd_13_brType = c_brType[13];
  assign io_out_pd_13_isCall = c_isCall[13];
  assign io_out_pd_13_isRet = c_isRet[13];
  assign io_out_pd_14_brType = c_brType[14];
  assign io_out_pd_14_isCall = c_isCall[14];
  assign io_out_pd_14_isRet = c_isRet[14];
  assign io_out_pd_15_brType = c_brType[15];
  assign io_out_pd_15_isCall = c_isCall[15];
  assign io_out_pd_15_isRet = c_isRet[15];
endmodule
