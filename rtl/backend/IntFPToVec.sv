// =============================================================================
// IntFPToVec —— 标量整数 / 浮点 / 立即数 → 向量寄存器（及 fli / fmv 到浮点寄存器）的搬运 FU
// -----------------------------------------------------------------------------
// 设计源：src/main/scala/xiangshan/backend/fu/fpu/IntFPToVec.scala（PipedFuncUnit，延迟 0）。
// 在哪一层：两处例化 —— ExeUnit_5 的 i2v（整数侧：vmv.v.x / vmv.s.x / 立即数 vmv.v.i）与
//   ExeUnit_8 的 f2v（浮点侧：vfmv.v.f / vfmv.s.f，以及 Zfa 的 fli.h/s/d 与 fmv.*.x）。
// 机制（纯组合，一拍内出结果）：
//   ① 取标量：fli.{h,s,d}（opType[7]=1）查 FliH/S/D 三张常数表，并按目的格式 NaN-box；
//      否则 opType[3]（isImm）选 src1（立即数），再否则选 src0（整数 / 浮点寄存器值）。
//   ② 出结果（vsew = opType[1:0]）：
//      · needDup（opType[4]）：把标量的低 SEW 位复制满 128 位（vmv.v.* 的一次写满）；
//        若是浮点源（opType[2]）而标量不是合法 NaN-box（高位不全 1），该元素换成
//        对应宽度的规范 NaN（e8 的 0x78 / e16 的 0x7E00 / e32 的 0x7FC00000；e64 不检查）；
//      · 不复制且是 fmv（浮点源）：低 SEW 位 + 高位补全 1（NaN-box），放在低 64 位；
//      · 其余：标量原样放在低 64 位。
// 握手：PipedFuncUnit 的直通 —— in.ready = out.ready，out.valid = validPipe(0) & in.valid，
//   ctrl / perfDebugInfo / debug.seqNum 原样转发。无时钟、无复位、无寄存器。
// 子模块：FliHTable / FliSTable / FliDTable（已签核重写件，两侧白盒）。
// golden 对照：G1-canonical/golden-rtl/IntFPToVec.sv
// =============================================================================

module xs_IntFPToVec_core (
  input  logic [8:0]   op,          // fuOpType
  input  logic [63:0]  src0,        // 整数 / 浮点寄存器标量
  input  logic [63:0]  src1,        // 立即数载体
  output logic [127:0] res_data
);

  // ---------------------------------------------------------------------------
  // ① 标量来源
  // ---------------------------------------------------------------------------
  // fli 三种格式：opType[7]=1，[6:5] 选 h(10) / s(00) / d(01)；低 5 位是 fli 立即数编码
  logic is_fli_h, is_fli_s, is_fli_d, is_fli;
  assign is_fli_h = op[7] &  op[6] & ~op[5];
  assign is_fli_s = op[7] & ~op[6] & ~op[5];
  assign is_fli_d = op[7] & ~op[6] &  op[5];
  assign is_fli   = is_fli_h | is_fli_s | is_fli_d;

  logic [15:0] fli_h, fli_s_hi, fli_d_hi;   // 三张常数表的输出（s/d 只存高 16 位，余位为 0）
  FliHTable FliHTable (.src(op[4:0]), .out(fli_h));
  FliSTable FliSTable (.src(op[4:0]), .out(fli_s_hi));
  FliDTable FliDTable (.src(op[4:0]), .out(fli_d_hi));

  // fli 结果按目的格式 NaN-box 进 64 位（三者互斥，golden 写成与或 Mux1H）
  logic [63:0] fli_data;
  always_comb begin
    fli_data = '0;
    if (is_fli_h) fli_data = {48'hFFFF_FFFF_FFFF, fli_h};
    if (is_fli_s) fli_data = {32'hFFFF_FFFF, fli_s_hi, 16'h0};
    if (is_fli_d) fli_data = {fli_d_hi, 48'h0};
  end

  // 非 fli 时 opType[4:2] 的三个功能位（IF2VectorType）：[4] needDup  [3] isImm  [2] isFp
  logic need_dup, is_imm, is_fp, is_fmv;
  assign need_dup = ~is_fli & op[4];
  assign is_imm   = ~is_fli & op[3];
  assign is_fp    = ~is_fli & op[2];
  assign is_fmv   = ~is_fli & op[2] & ~op[4];   // 浮点源且不复制 = 标量 fmv

  logic [63:0] scalar;
  assign scalar = is_fli ? fli_data : (is_imm ? src1 : src0);

  // ---------------------------------------------------------------------------
  // ② 结果
  // ---------------------------------------------------------------------------
  logic [1:0] vsew;
  assign vsew = op[1:0];

  // 浮点源的元素若不是合法 NaN-box（高位不全 1）就换成该宽度的规范 NaN
  logic [7:0]  elem8;
  logic [15:0] elem16;
  logic [31:0] elem32;
  assign elem8  = (is_fp && scalar[63:8]  != 56'hFF_FFFF_FFFF_FFFF) ? 8'h78        : scalar[7:0];
  assign elem16 = (is_fp && scalar[63:16] != 48'hFFFF_FFFF_FFFF)    ? 16'h7E00     : scalar[15:0];
  assign elem32 = (is_fp && scalar[63:32] != 32'hFFFF_FFFF)         ? 32'h7FC00000 : scalar[31:0];

  logic [127:0] dup_data;   // 复制满 128 位
  logic [63:0]  fmv_data;   // 低 SEW 位 + 高位 NaN-box
  always_comb begin
    unique case (vsew)
      2'd0: begin dup_data = {16{elem8}};  fmv_data = {56'hFF_FFFF_FFFF_FFFF, scalar[7:0]};  end
      2'd1: begin dup_data = {8{elem16}};  fmv_data = {48'hFFFF_FFFF_FFFF,    scalar[15:0]}; end
      2'd2: begin dup_data = {4{elem32}};  fmv_data = {32'hFFFF_FFFF,         scalar[31:0]}; end
      default: begin dup_data = {2{scalar}}; fmv_data = scalar; end
    endcase
  end

  assign res_data = need_dup ? dup_data
                  : {64'h0, (is_fmv ? fmv_data : scalar)};

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden IntFPToVec.sv 完全一致
// ---------------------------------------------------------------------------
module IntFPToVec(
  output         io_in_ready,
  input          io_in_valid,
  input  [8:0]   io_in_bits_ctrl_fuOpType,
  input          io_in_bits_ctrl_robIdx_flag,
  input  [7:0]   io_in_bits_ctrl_robIdx_value,
  input  [7:0]   io_in_bits_ctrl_pdest,
  input          io_in_bits_ctrl_fpWen,
  input          io_in_bits_ctrl_vecWen,
  input          io_in_bits_ctrl_v0Wen,
  input          io_in_bits_validPipe_0,
  input  [63:0]  io_in_bits_data_src_1,
  input  [63:0]  io_in_bits_data_src_0,
  input          io_in_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_in_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_in_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_in_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_in_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_in_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_in_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_in_bits_debug_seqNum_seqNum,
  input  [7:0]   io_in_bits_debug_seqNum_uopIdx,
  input          io_out_ready,
  output         io_out_valid,
  output         io_out_bits_ctrl_robIdx_flag,
  output [7:0]   io_out_bits_ctrl_robIdx_value,
  output [7:0]   io_out_bits_ctrl_pdest,
  output         io_out_bits_ctrl_fpWen,
  output         io_out_bits_ctrl_vecWen,
  output         io_out_bits_ctrl_v0Wen,
  output [127:0] io_out_bits_res_data,
  output         io_out_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_out_bits_perfDebugInfo_renameTime,
  output [63:0]  io_out_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_out_bits_perfDebugInfo_selectTime,
  output [63:0]  io_out_bits_perfDebugInfo_issueTime,
  output [63:0]  io_out_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_out_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_out_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_out_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_out_bits_debug_seqNum_seqNum,
  output [7:0]   io_out_bits_debug_seqNum_uopIdx
);

  xs_IntFPToVec_core u_core (
    .op       (io_in_bits_ctrl_fuOpType),
    .src0     (io_in_bits_data_src_0),
    .src1     (io_in_bits_data_src_1),
    .res_data (io_out_bits_res_data)
  );

  // 握手直通（延迟 0）；写回有效还要与发射级的 validPipe(0) 相与
  assign io_in_ready  = io_out_ready;
  assign io_out_valid = io_in_bits_validPipe_0 & io_in_valid;

  // 控制/调试旁路直通（PipedFuncUnit 的 connect0LatencyCtrlSingal）
  assign io_out_bits_ctrl_robIdx_flag                     = io_in_bits_ctrl_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value                    = io_in_bits_ctrl_robIdx_value;
  assign io_out_bits_ctrl_pdest                           = io_in_bits_ctrl_pdest;
  assign io_out_bits_ctrl_fpWen                           = io_in_bits_ctrl_fpWen;
  assign io_out_bits_ctrl_vecWen                          = io_in_bits_ctrl_vecWen;
  assign io_out_bits_ctrl_v0Wen                           = io_in_bits_ctrl_v0Wen;
  assign io_out_bits_perfDebugInfo_eliminatedMove         = io_in_bits_perfDebugInfo_eliminatedMove;
  assign io_out_bits_perfDebugInfo_renameTime             = io_in_bits_perfDebugInfo_renameTime;
  assign io_out_bits_perfDebugInfo_dispatchTime           = io_in_bits_perfDebugInfo_dispatchTime;
  assign io_out_bits_perfDebugInfo_enqRsTime              = io_in_bits_perfDebugInfo_enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime             = io_in_bits_perfDebugInfo_selectTime;
  assign io_out_bits_perfDebugInfo_issueTime              = io_in_bits_perfDebugInfo_issueTime;
  assign io_out_bits_perfDebugInfo_writebackTime          = io_in_bits_perfDebugInfo_writebackTime;
  assign io_out_bits_perfDebugInfo_runahead_checkpoint_id = io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_out_bits_perfDebugInfo_tlbFirstReqTime        = io_in_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_out_bits_perfDebugInfo_tlbRespTime            = io_in_bits_perfDebugInfo_tlbRespTime;
  assign io_out_bits_debug_seqNum_seqNum                  = io_in_bits_debug_seqNum_seqNum;
  assign io_out_bits_debug_seqNum_uopIdx                  = io_in_bits_debug_seqNum_uopIdx;

endmodule
