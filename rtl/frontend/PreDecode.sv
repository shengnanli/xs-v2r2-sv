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
// xs_PreDecode_core —— 取指包预解码（纯组合）
//
// 对应 Chisel: xiangshan.frontend.PreDecode（KunminghuV2Config：PredictWidth=16,
// XLEN=64, HasCExtension=true）
//
// 对一个取指包（PredictWidth+1=17 个 16-bit 半字）逐字节地址做预解码：
//   - 取每个半字位置的 32-bit 指令 inst[i] = {data[i+1], data[i]}
//   - 判 RVC（inst[1:0]!=2'b11）、分支类型（br/jal/jalr/notCFI）、isCall/isRet
//   - 算 jal/branch 的符号扩展跳转偏移
//   - 用两段式 RVC/RVI 边界检测得到每个位置是否为「有效指令起点」(valid) 及
//     half-valid（用于跨包 last-half 匹配）
//
// 两段式边界：前半 [0,8) 直接链式推导；后半 [8,16) 同时算两种假设——half（假设 8
// 是有效起点）与 halfPlus1（假设 8 是上一条 RVI 的后半、9 才是起点），最后按前半
// 是否在 7 处干净结束(validEnd[7]) 选择。如此在中点打断长依赖链，改善时序。
// =============================================================================
import xs_predecode_pkg::*;


module xs_PreDecode_core #(
  parameter int unsigned PW   = 16,   // PredictWidth
  parameter int unsigned XLEN = 64
)(
  // 取指数据：PW+1 个半字
  input  logic [PW:0][15:0]        io_data,
  // 逐位置输出
  output logic [PW-1:0]            pd_valid,
  output logic [PW-1:0]            pd_isRVC,
  output logic [PW-1:0][1:0]       pd_brType,
  output logic [PW-1:0]            pd_isCall,
  output logic [PW-1:0]            pd_isRet,
  output logic [PW-1:0]            hasHalfValid,
  output logic [PW-1:0][31:0]      instr,
  output logic [PW-1:0][XLEN-1:0]  jumpOffset
);
  localparam int unsigned HALF = PW / 2;

  // 分支类型译码/isCall/isRet/isLink 来自 xs_predecode_pkg（与 F3Predecoder 共享）

  // jal 偏移：RVC(C.J) / RVI(JAL) 立即数，符号扩展到 XLEN（显式符号位复制）
  function automatic logic [XLEN-1:0] jal_offset(input logic [31:0] inst, input logic rvc);
    logic [11:0] rvc_off;  // C.J: 12 bit
    logic [20:0] rvi_off;  // JAL: 21 bit
    logic [20:0] sel;
    rvc_off = {inst[12], inst[8], inst[10:9], inst[6], inst[7], inst[2], inst[11], inst[5:3], 1'b0};
    rvi_off = {inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
    sel = rvc ? {{9{rvc_off[11]}}, rvc_off} : rvi_off;
    return {{(XLEN-21){sel[20]}}, sel};
  endfunction

  // branch 偏移
  function automatic logic [XLEN-1:0] br_offset(input logic [31:0] inst, input logic rvc);
    logic [8:0]  rvc_off;  // C.B: 9 bit
    logic [12:0] rvi_off;  // B: 13 bit
    logic [12:0] sel;
    rvc_off = {inst[12], inst[6:5], inst[2], inst[11:10], inst[4:3], 1'b0};
    rvi_off = {inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    sel = rvc ? {{4{rvc_off[8]}}, rvc_off} : rvi_off;
    return {{(XLEN-13){sel[12]}}, sel};
  endfunction

  // ---- 逐位置：指令、RVC、类型、call/ret、偏移 ----
  logic [PW-1:0]      isRVCv;

  for (genvar i = 0; i < PW; i++) begin : g_dec
    wire [31:0] inst = {io_data[i+1], io_data[i]};
    wire        rvc  = xs_is_rvc(inst);
    wire [1:0]  bt   = xs_br_type(inst);

    assign isRVCv[i]   = rvc;
    assign instr[i]    = inst;
    assign jumpOffset[i] = (bt == BR_BRANCH) ? br_offset(inst, rvc) : jal_offset(inst, rvc);

    assign pd_isRVC[i]  = rvc;
    assign pd_brType[i] = bt;
    assign pd_isCall[i] = xs_is_call(inst);
    assign pd_isRet[i]  = xs_is_ret(inst);
  end

  // ---- 两段式有效起点/结束边界检测 ----
  // 各链用运行标量推进（避免 always_comb 内读写同一数组），分块计算，块间互不读写。
  logic [PW-1:0] vStart, vEnd, hStart, hEnd;
  logic [HALF-1:0] vS_lo, vE_lo, hS_lo, hE_lo;       // 前半 [0,HALF)
  logic [PW-1:0] vS_half, vE_half, hS_half, hE_half; // 后半假设 half
  logic [PW-1:0] vS_hp1,  vE_hp1,  hS_hp1,  hE_hp1;  // 后半假设 halfPlus1

  // 前半链式 [0,HALF)
  always_comb begin
    logic vpe, hpe, vs, hs;
    vpe = 1'b1; hpe = 1'b0;  // i==0: v 起点恒 1；h 起点 0
    for (int i = 0; i < HALF; i++) begin
      vs = (i == 0) ? 1'b1 : vpe;
      vS_lo[i] = vs;  vE_lo[i] = (vs & isRVCv[i]) | ~vs;  vpe = vE_lo[i];
      hs = (i == 0) ? 1'b0 : hpe;
      hS_lo[i] = hs;  hE_lo[i] = (hs & isRVCv[i]) | ~hs;  hpe = hE_lo[i];
    end
  end

  // 后半假设 half：HALF 是有效起点
  always_comb begin
    logic vpe, hpe, vs, hs;
    vS_half = '0; vE_half = '0; hS_half = '0; hE_half = '0;
    vpe = 1'b0; hpe = 1'b0;
    for (int i = HALF; i < PW; i++) begin
      vs = (i == HALF) ? 1'b1 : vpe;
      vS_half[i] = vs; vE_half[i] = (vs & isRVCv[i]) | ~vs; vpe = vE_half[i];
      hs = (i == HALF) ? 1'b1 : hpe;
      hS_half[i] = hs; hE_half[i] = (hs & isRVCv[i]) | ~hs; hpe = hE_half[i];
    end
  end

  // 后半假设 halfPlus1：HALF 是上条 RVI 后半，HALF+1 才是起点
  always_comb begin
    logic vpe, hpe, vs, hs;
    vS_hp1 = '0; vE_hp1 = '0; hS_hp1 = '0; hE_hp1 = '0;
    vS_hp1[HALF] = 1'b0; vE_hp1[HALF] = 1'b1;
    hS_hp1[HALF] = 1'b0; hE_hp1[HALF] = 1'b1;
    vpe = 1'b1; hpe = 1'b1;  // i==HALF+1 起点恒 1
    for (int i = HALF + 1; i < PW; i++) begin
      vs = (i == HALF + 1) ? 1'b1 : vpe;
      vS_hp1[i] = vs; vE_hp1[i] = (vs & isRVCv[i]) | ~vs; vpe = vE_hp1[i];
      hs = (i == HALF + 1) ? 1'b1 : hpe;
      hS_hp1[i] = hs; hE_hp1[i] = (hs & isRVCv[i]) | ~hs; hpe = hE_hp1[i];
    end
  end

  // 合并：前半直接用；后半按 validEnd[HALF-1]/h_validEnd[HALF-1] 选假设
  always_comb begin
    for (int i = 0; i < HALF; i++) begin
      vStart[i] = vS_lo[i]; vEnd[i] = vE_lo[i];
      hStart[i] = hS_lo[i]; hEnd[i] = hE_lo[i];
    end
    for (int i = HALF; i < PW; i++) begin
      vStart[i] = vE_lo[HALF-1] ? vS_half[i] : vS_hp1[i];
      vEnd[i]   = vE_lo[HALF-1] ? vE_half[i] : vE_hp1[i];
      hStart[i] = hE_lo[HALF-1] ? hS_half[i] : hS_hp1[i];
      hEnd[i]   = hE_lo[HALF-1] ? hE_half[i] : hE_hp1[i];
    end
  end

  assign pd_valid     = vStart;
  assign hasHalfValid = hStart;

endmodule

// 自动生成：xs-v2r2-sv/scripts/gen_predecode.py —— 该脚本未移植到本轮(它按上一轮规范产出独立 _wrapper.sv)，本文件手工维护

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module PreDecode(
  input  clock,
  input  reset,
  input  io_in_valid,
  input  [15:0] io_in_bits_data_0,
  input  [15:0] io_in_bits_data_1,
  input  [15:0] io_in_bits_data_2,
  input  [15:0] io_in_bits_data_3,
  input  [15:0] io_in_bits_data_4,
  input  [15:0] io_in_bits_data_5,
  input  [15:0] io_in_bits_data_6,
  input  [15:0] io_in_bits_data_7,
  input  [15:0] io_in_bits_data_8,
  input  [15:0] io_in_bits_data_9,
  input  [15:0] io_in_bits_data_10,
  input  [15:0] io_in_bits_data_11,
  input  [15:0] io_in_bits_data_12,
  input  [15:0] io_in_bits_data_13,
  input  [15:0] io_in_bits_data_14,
  input  [15:0] io_in_bits_data_15,
  input  [15:0] io_in_bits_data_16,
  output io_out_pd_0_isRVC,
  output [1:0] io_out_pd_0_brType,
  output io_out_pd_0_isCall,
  output io_out_pd_0_isRet,
  output io_out_pd_1_valid,
  output io_out_pd_1_isRVC,
  output [1:0] io_out_pd_1_brType,
  output io_out_pd_1_isCall,
  output io_out_pd_1_isRet,
  output io_out_pd_2_valid,
  output io_out_pd_2_isRVC,
  output [1:0] io_out_pd_2_brType,
  output io_out_pd_2_isCall,
  output io_out_pd_2_isRet,
  output io_out_pd_3_valid,
  output io_out_pd_3_isRVC,
  output [1:0] io_out_pd_3_brType,
  output io_out_pd_3_isCall,
  output io_out_pd_3_isRet,
  output io_out_pd_4_valid,
  output io_out_pd_4_isRVC,
  output [1:0] io_out_pd_4_brType,
  output io_out_pd_4_isCall,
  output io_out_pd_4_isRet,
  output io_out_pd_5_valid,
  output io_out_pd_5_isRVC,
  output [1:0] io_out_pd_5_brType,
  output io_out_pd_5_isCall,
  output io_out_pd_5_isRet,
  output io_out_pd_6_valid,
  output io_out_pd_6_isRVC,
  output [1:0] io_out_pd_6_brType,
  output io_out_pd_6_isCall,
  output io_out_pd_6_isRet,
  output io_out_pd_7_valid,
  output io_out_pd_7_isRVC,
  output [1:0] io_out_pd_7_brType,
  output io_out_pd_7_isCall,
  output io_out_pd_7_isRet,
  output io_out_pd_8_valid,
  output io_out_pd_8_isRVC,
  output [1:0] io_out_pd_8_brType,
  output io_out_pd_8_isCall,
  output io_out_pd_8_isRet,
  output io_out_pd_9_valid,
  output io_out_pd_9_isRVC,
  output [1:0] io_out_pd_9_brType,
  output io_out_pd_9_isCall,
  output io_out_pd_9_isRet,
  output io_out_pd_10_valid,
  output io_out_pd_10_isRVC,
  output [1:0] io_out_pd_10_brType,
  output io_out_pd_10_isCall,
  output io_out_pd_10_isRet,
  output io_out_pd_11_valid,
  output io_out_pd_11_isRVC,
  output [1:0] io_out_pd_11_brType,
  output io_out_pd_11_isCall,
  output io_out_pd_11_isRet,
  output io_out_pd_12_valid,
  output io_out_pd_12_isRVC,
  output [1:0] io_out_pd_12_brType,
  output io_out_pd_12_isCall,
  output io_out_pd_12_isRet,
  output io_out_pd_13_valid,
  output io_out_pd_13_isRVC,
  output [1:0] io_out_pd_13_brType,
  output io_out_pd_13_isCall,
  output io_out_pd_13_isRet,
  output io_out_pd_14_valid,
  output io_out_pd_14_isRVC,
  output [1:0] io_out_pd_14_brType,
  output io_out_pd_14_isCall,
  output io_out_pd_14_isRet,
  output io_out_pd_15_valid,
  output io_out_pd_15_isRVC,
  output [1:0] io_out_pd_15_brType,
  output io_out_pd_15_isCall,
  output io_out_pd_15_isRet,
  output io_out_hasHalfValid_2,
  output io_out_hasHalfValid_3,
  output io_out_hasHalfValid_4,
  output io_out_hasHalfValid_5,
  output io_out_hasHalfValid_6,
  output io_out_hasHalfValid_7,
  output io_out_hasHalfValid_8,
  output io_out_hasHalfValid_9,
  output io_out_hasHalfValid_10,
  output io_out_hasHalfValid_11,
  output io_out_hasHalfValid_12,
  output io_out_hasHalfValid_13,
  output io_out_hasHalfValid_14,
  output io_out_hasHalfValid_15,
  output [31:0] io_out_instr_0,
  output [31:0] io_out_instr_1,
  output [31:0] io_out_instr_2,
  output [31:0] io_out_instr_3,
  output [31:0] io_out_instr_4,
  output [31:0] io_out_instr_5,
  output [31:0] io_out_instr_6,
  output [31:0] io_out_instr_7,
  output [31:0] io_out_instr_8,
  output [31:0] io_out_instr_9,
  output [31:0] io_out_instr_10,
  output [31:0] io_out_instr_11,
  output [31:0] io_out_instr_12,
  output [31:0] io_out_instr_13,
  output [31:0] io_out_instr_14,
  output [31:0] io_out_instr_15,
  output [63:0] io_out_jumpOffset_0,
  output [63:0] io_out_jumpOffset_1,
  output [63:0] io_out_jumpOffset_2,
  output [63:0] io_out_jumpOffset_3,
  output [63:0] io_out_jumpOffset_4,
  output [63:0] io_out_jumpOffset_5,
  output [63:0] io_out_jumpOffset_6,
  output [63:0] io_out_jumpOffset_7,
  output [63:0] io_out_jumpOffset_8,
  output [63:0] io_out_jumpOffset_9,
  output [63:0] io_out_jumpOffset_10,
  output [63:0] io_out_jumpOffset_11,
  output [63:0] io_out_jumpOffset_12,
  output [63:0] io_out_jumpOffset_13,
  output [63:0] io_out_jumpOffset_14,
  output [63:0] io_out_jumpOffset_15
);
  wire [16:0][15:0] data_arr;
  assign data_arr[0] = io_in_bits_data_0;
  assign data_arr[1] = io_in_bits_data_1;
  assign data_arr[2] = io_in_bits_data_2;
  assign data_arr[3] = io_in_bits_data_3;
  assign data_arr[4] = io_in_bits_data_4;
  assign data_arr[5] = io_in_bits_data_5;
  assign data_arr[6] = io_in_bits_data_6;
  assign data_arr[7] = io_in_bits_data_7;
  assign data_arr[8] = io_in_bits_data_8;
  assign data_arr[9] = io_in_bits_data_9;
  assign data_arr[10] = io_in_bits_data_10;
  assign data_arr[11] = io_in_bits_data_11;
  assign data_arr[12] = io_in_bits_data_12;
  assign data_arr[13] = io_in_bits_data_13;
  assign data_arr[14] = io_in_bits_data_14;
  assign data_arr[15] = io_in_bits_data_15;
  assign data_arr[16] = io_in_bits_data_16;
  wire [15:0]       c_valid, c_isRVC, c_isCall, c_isRet, c_hasHalfValid;
  wire [15:0][1:0]  c_brType;
  wire [15:0][31:0] c_instr;
  wire [15:0][63:0] c_jumpOffset;
  xs_PreDecode_core #(.PW(16), .XLEN(64)) u_core (
    .io_data(data_arr),
    .pd_valid(c_valid), .pd_isRVC(c_isRVC), .pd_brType(c_brType),
    .pd_isCall(c_isCall), .pd_isRet(c_isRet), .hasHalfValid(c_hasHalfValid),
    .instr(c_instr), .jumpOffset(c_jumpOffset)
  );
  assign io_out_pd_0_isRVC = c_isRVC[0];
  assign io_out_pd_0_brType = c_brType[0];
  assign io_out_pd_0_isCall = c_isCall[0];
  assign io_out_pd_0_isRet = c_isRet[0];
  assign io_out_pd_1_valid = c_valid[1];
  assign io_out_pd_1_isRVC = c_isRVC[1];
  assign io_out_pd_1_brType = c_brType[1];
  assign io_out_pd_1_isCall = c_isCall[1];
  assign io_out_pd_1_isRet = c_isRet[1];
  assign io_out_pd_2_valid = c_valid[2];
  assign io_out_pd_2_isRVC = c_isRVC[2];
  assign io_out_pd_2_brType = c_brType[2];
  assign io_out_pd_2_isCall = c_isCall[2];
  assign io_out_pd_2_isRet = c_isRet[2];
  assign io_out_pd_3_valid = c_valid[3];
  assign io_out_pd_3_isRVC = c_isRVC[3];
  assign io_out_pd_3_brType = c_brType[3];
  assign io_out_pd_3_isCall = c_isCall[3];
  assign io_out_pd_3_isRet = c_isRet[3];
  assign io_out_pd_4_valid = c_valid[4];
  assign io_out_pd_4_isRVC = c_isRVC[4];
  assign io_out_pd_4_brType = c_brType[4];
  assign io_out_pd_4_isCall = c_isCall[4];
  assign io_out_pd_4_isRet = c_isRet[4];
  assign io_out_pd_5_valid = c_valid[5];
  assign io_out_pd_5_isRVC = c_isRVC[5];
  assign io_out_pd_5_brType = c_brType[5];
  assign io_out_pd_5_isCall = c_isCall[5];
  assign io_out_pd_5_isRet = c_isRet[5];
  assign io_out_pd_6_valid = c_valid[6];
  assign io_out_pd_6_isRVC = c_isRVC[6];
  assign io_out_pd_6_brType = c_brType[6];
  assign io_out_pd_6_isCall = c_isCall[6];
  assign io_out_pd_6_isRet = c_isRet[6];
  assign io_out_pd_7_valid = c_valid[7];
  assign io_out_pd_7_isRVC = c_isRVC[7];
  assign io_out_pd_7_brType = c_brType[7];
  assign io_out_pd_7_isCall = c_isCall[7];
  assign io_out_pd_7_isRet = c_isRet[7];
  assign io_out_pd_8_valid = c_valid[8];
  assign io_out_pd_8_isRVC = c_isRVC[8];
  assign io_out_pd_8_brType = c_brType[8];
  assign io_out_pd_8_isCall = c_isCall[8];
  assign io_out_pd_8_isRet = c_isRet[8];
  assign io_out_pd_9_valid = c_valid[9];
  assign io_out_pd_9_isRVC = c_isRVC[9];
  assign io_out_pd_9_brType = c_brType[9];
  assign io_out_pd_9_isCall = c_isCall[9];
  assign io_out_pd_9_isRet = c_isRet[9];
  assign io_out_pd_10_valid = c_valid[10];
  assign io_out_pd_10_isRVC = c_isRVC[10];
  assign io_out_pd_10_brType = c_brType[10];
  assign io_out_pd_10_isCall = c_isCall[10];
  assign io_out_pd_10_isRet = c_isRet[10];
  assign io_out_pd_11_valid = c_valid[11];
  assign io_out_pd_11_isRVC = c_isRVC[11];
  assign io_out_pd_11_brType = c_brType[11];
  assign io_out_pd_11_isCall = c_isCall[11];
  assign io_out_pd_11_isRet = c_isRet[11];
  assign io_out_pd_12_valid = c_valid[12];
  assign io_out_pd_12_isRVC = c_isRVC[12];
  assign io_out_pd_12_brType = c_brType[12];
  assign io_out_pd_12_isCall = c_isCall[12];
  assign io_out_pd_12_isRet = c_isRet[12];
  assign io_out_pd_13_valid = c_valid[13];
  assign io_out_pd_13_isRVC = c_isRVC[13];
  assign io_out_pd_13_brType = c_brType[13];
  assign io_out_pd_13_isCall = c_isCall[13];
  assign io_out_pd_13_isRet = c_isRet[13];
  assign io_out_pd_14_valid = c_valid[14];
  assign io_out_pd_14_isRVC = c_isRVC[14];
  assign io_out_pd_14_brType = c_brType[14];
  assign io_out_pd_14_isCall = c_isCall[14];
  assign io_out_pd_14_isRet = c_isRet[14];
  assign io_out_pd_15_valid = c_valid[15];
  assign io_out_pd_15_isRVC = c_isRVC[15];
  assign io_out_pd_15_brType = c_brType[15];
  assign io_out_pd_15_isCall = c_isCall[15];
  assign io_out_pd_15_isRet = c_isRet[15];
  assign io_out_hasHalfValid_2 = c_hasHalfValid[2];
  assign io_out_hasHalfValid_3 = c_hasHalfValid[3];
  assign io_out_hasHalfValid_4 = c_hasHalfValid[4];
  assign io_out_hasHalfValid_5 = c_hasHalfValid[5];
  assign io_out_hasHalfValid_6 = c_hasHalfValid[6];
  assign io_out_hasHalfValid_7 = c_hasHalfValid[7];
  assign io_out_hasHalfValid_8 = c_hasHalfValid[8];
  assign io_out_hasHalfValid_9 = c_hasHalfValid[9];
  assign io_out_hasHalfValid_10 = c_hasHalfValid[10];
  assign io_out_hasHalfValid_11 = c_hasHalfValid[11];
  assign io_out_hasHalfValid_12 = c_hasHalfValid[12];
  assign io_out_hasHalfValid_13 = c_hasHalfValid[13];
  assign io_out_hasHalfValid_14 = c_hasHalfValid[14];
  assign io_out_hasHalfValid_15 = c_hasHalfValid[15];
  assign io_out_instr_0 = c_instr[0];
  assign io_out_instr_1 = c_instr[1];
  assign io_out_instr_2 = c_instr[2];
  assign io_out_instr_3 = c_instr[3];
  assign io_out_instr_4 = c_instr[4];
  assign io_out_instr_5 = c_instr[5];
  assign io_out_instr_6 = c_instr[6];
  assign io_out_instr_7 = c_instr[7];
  assign io_out_instr_8 = c_instr[8];
  assign io_out_instr_9 = c_instr[9];
  assign io_out_instr_10 = c_instr[10];
  assign io_out_instr_11 = c_instr[11];
  assign io_out_instr_12 = c_instr[12];
  assign io_out_instr_13 = c_instr[13];
  assign io_out_instr_14 = c_instr[14];
  assign io_out_instr_15 = c_instr[15];
  assign io_out_jumpOffset_0 = c_jumpOffset[0];
  assign io_out_jumpOffset_1 = c_jumpOffset[1];
  assign io_out_jumpOffset_2 = c_jumpOffset[2];
  assign io_out_jumpOffset_3 = c_jumpOffset[3];
  assign io_out_jumpOffset_4 = c_jumpOffset[4];
  assign io_out_jumpOffset_5 = c_jumpOffset[5];
  assign io_out_jumpOffset_6 = c_jumpOffset[6];
  assign io_out_jumpOffset_7 = c_jumpOffset[7];
  assign io_out_jumpOffset_8 = c_jumpOffset[8];
  assign io_out_jumpOffset_9 = c_jumpOffset[9];
  assign io_out_jumpOffset_10 = c_jumpOffset[10];
  assign io_out_jumpOffset_11 = c_jumpOffset[11];
  assign io_out_jumpOffset_12 = c_jumpOffset[12];
  assign io_out_jumpOffset_13 = c_jumpOffset[13];
  assign io_out_jumpOffset_14 = c_jumpOffset[14];
  assign io_out_jumpOffset_15 = c_jumpOffset[15];
endmodule
