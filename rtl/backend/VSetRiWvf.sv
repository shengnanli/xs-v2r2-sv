// =============================================================================
// VSetRiWvf —— 向量配置单元「读整型、写 vl 寄存器」形态（vset 的 vconfig 写回 uop）
// -----------------------------------------------------------------------------
// 设计源：src/main/scala/xiangshan/backend/fu/wrapper/VSet.scala（class VSetRiWvf，
//   继承 VSetBase；vl 计算在 VsetModule）。
// 在哪一层：ExeUnit_5（整数 IQ 的 alu/brh/jmp/i2f/vset 混合执行单元）里的一个 FU，
//   延迟 0（组合），与 VSetRiWi 并列：VSetRiWi 把新 vl 写进整型 rd，本 FU 把
//   {vtype, vl} 写进 vl 寄存器堆（writeVlRf），并对外给出 vtype 写口与两个 vl 边界标志。
// 机制（纯组合）：
//   ① AVL：vsetivli 取立即数 uimm5（src1[14:10]），其余取整型 rs1 = src0；
//   ② vtype：vsetvl 取 rs2 的 VtypeStruct（src1，含 vill），vsetvli/vsetivli 取立即数；
//   ③ VsetModule：VLMAX / 合法性 / vl = min(AVL, VLMAX)（非法则 0、setVlmax 则 VLMAX）；
//   ④ 输出：res.data = vl（零扩展）；vtype.valid = valid & isVsetvl；
//      vlIsZero / vlIsVlmax 只看 valid 与新 vl（本形态没有 csrrvl 读 vl，那在 VSetRvfWvf）。
// 与已签同族的关系：AVL / vtype 选源与 VSetRiWi 逐字同构，vtype 写回与 vl 标志与
//   VSetRvfWvf 同构；三者共用 backend_common_pkg.sv 里 vset_pkg 的计算函数（不改那份包）。
// 子模块：golden 例化 VsetModule；本核把它的组合逻辑写成 vset_pkg 的纯函数，不例化
//   （与 VSetRiWi / VSetRvfWvf 的做法一致）。无时钟、无复位、无寄存器。
// 握手：PipedFuncUnit 的直通 —— in.ready = out.ready，out.valid = in.valid，
//   ctrl / perfDebugInfo / debug.seqNum 原样转发。
// golden 对照：G1-canonical/golden-rtl/VSetRiWvf.sv
// =============================================================================

module xs_VSetRiWvf_core
  import vset_pkg::*;
(
  input  logic        valid,        // 本拍是否有效（只用于 vtype 写口与两个标志）
  input  logic [8:0]  func,         // fuOpType（vset 变体编码）
  input  logic [63:0] src0,         // 整型 rs1（普通 AVL）
  input  logic [63:0] src1,         // 整型 rs2 / 立即数载体（vtype、立即 AVL）
  output logic [63:0] res_data,     // 写回 vl 寄存器堆的 vl（零扩展）
  output logic        vtype_valid,  // vtype 寄存器写使能（仅 vsetvl 路径）
  output vtype_out_t  vtype_out,    // 写回的 vtype
  output logic        vl_is_zero,   // 新 vl == 0
  output logic        vl_is_vlmax   // 新 vl == VLMAX
);

  // ---------------------------------------------------------------------------
  // ① AVL 选源：vsetivli（func[7:6]==00）取立即数 uimm5，否则取整型 rs1。
  // ---------------------------------------------------------------------------
  logic [63:0] avl;
  assign avl = (|func[7:6]) ? src0 : {59'h0, src1[14:10]};

  // ---------------------------------------------------------------------------
  // ② vtype 选源：三种变体的 vma/vta/vsew/vlmul 位置相同（src1[7]/[6]/[5:3]/[2:0]），
  //    差别只在 vill 与 reserved 从哪来、有多宽。
  // ---------------------------------------------------------------------------
  vset_kind_e kind;
  vtype_in_t  vtype;
  assign kind = classify(func);
  always_comb begin
    vtype.vma   = src1[7];
    vtype.vta   = src1[6];
    vtype.vsew  = src1[5:3];
    vtype.vlmul = src1[2:0];
    unique case (kind)
      VSET_IVLI: begin  // 立即数 vtype，reserved 仅 2 位
        vtype.illegal  = 1'b0;
        vtype.reserved = {53'h0, src1[9:8]};
      end
      VSET_VLI: begin   // 立即数 vtype，reserved 3 位
        vtype.illegal  = 1'b0;
        vtype.reserved = {52'h0, src1[10:8]};
      end
      default: begin    // VSET_VL / VSET_VL2：寄存器 VtypeStruct（含 vill）
        vtype.illegal  = src1[63];
        vtype.reserved = src1[62:8];
      end
    endcase
  end

  // ---------------------------------------------------------------------------
  // ③ VsetModule：VLMAX / 合法性 / vl / 写回 vtype
  // ---------------------------------------------------------------------------
  logic [2:0]          log2_sew;
  logic [VLMAX_W-1:0]  vlmax_raw;     // 1 << log2Vlmax（vl 计算用这一份）
  logic [VLMAX_W-1:0]  vlen_div_sew;  // VLEN/SEW（分数 LMUL 时的下界）
  logic [VLMAX_W-1:0]  vlmax_out;     // VsetModule 对外的 vlmax = max(vlmax_raw, VLEN/SEW)
  logic                illegal;
  logic [VL_WIDTH-1:0] vl;

  assign log2_sew     = calc_log2_sew(vtype.vsew);
  assign vlmax_raw    = calc_vlmax(vtype.vlmul, log2_sew);
  assign vlen_div_sew = calc_vlen_div_sew(log2_sew);
  assign vlmax_out    = (vlmax_raw >= vlen_div_sew) ? vlmax_raw : vlen_div_sew;
  assign illegal      = calc_illegal(vtype.vlmul, vtype.vsew, log2_sew,
                                     vtype.reserved, vtype.illegal);
  assign vl           = calc_vl(illegal, func, avl, vlmax_raw);

  // 写回 vtype：非法时字段全清零、只留 vill；vsew 收窄为 2 位。
  always_comb begin
    vtype_out.illegal = illegal;
    vtype_out.vma     = illegal ? 1'b0 : vtype.vma;
    vtype_out.vta     = illegal ? 1'b0 : vtype.vta;
    vtype_out.vsew    = illegal ? 2'b0 : vtype.vsew[1:0];
    vtype_out.vlmul   = illegal ? 3'b0 : vtype.vlmul;
  end

  // ---------------------------------------------------------------------------
  // ④ 输出
  // ---------------------------------------------------------------------------
  assign res_data    = {56'h0, vl};
  assign vtype_valid = valid & func[6];                                  // 只有 vsetvl 改 vtype
  assign vl_is_zero  = valid & (vl == '0);
  assign vl_is_vlmax = valid & (vl == vlmax_out[VL_WIDTH-1:0]);

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden VSetRiWvf.sv 完全一致
// ---------------------------------------------------------------------------
module VSetRiWvf(
  output        io_in_ready,
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,
  input         io_in_bits_ctrl_robIdx_flag,
  input  [7:0]  io_in_bits_ctrl_robIdx_value,
  input  [7:0]  io_in_bits_ctrl_pdest,
  input         io_in_bits_ctrl_vlWen,
  input  [63:0] io_in_bits_data_src_1,
  input  [63:0] io_in_bits_data_src_0,
  input         io_in_bits_perfDebugInfo_eliminatedMove,
  input  [63:0] io_in_bits_perfDebugInfo_renameTime,
  input  [63:0] io_in_bits_perfDebugInfo_dispatchTime,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  input  [63:0] io_in_bits_perfDebugInfo_writebackTime,
  input  [63:0] io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0] io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0] io_in_bits_perfDebugInfo_tlbRespTime,
  input  [55:0] io_in_bits_debug_seqNum_seqNum,
  input  [7:0]  io_in_bits_debug_seqNum_uopIdx,
  input         io_out_ready,
  output        io_out_valid,
  output        io_out_bits_ctrl_robIdx_flag,
  output [7:0]  io_out_bits_ctrl_robIdx_value,
  output [7:0]  io_out_bits_ctrl_pdest,
  output        io_out_bits_ctrl_vlWen,
  output [63:0] io_out_bits_res_data,
  output        io_out_bits_perfDebugInfo_eliminatedMove,
  output [63:0] io_out_bits_perfDebugInfo_renameTime,
  output [63:0] io_out_bits_perfDebugInfo_dispatchTime,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  output [63:0] io_out_bits_perfDebugInfo_writebackTime,
  output [63:0] io_out_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0] io_out_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0] io_out_bits_perfDebugInfo_tlbRespTime,
  output [55:0] io_out_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_bits_debug_seqNum_uopIdx,
  output        io_vtype_valid,
  output        io_vtype_bits_illegal,
  output        io_vtype_bits_vma,
  output        io_vtype_bits_vta,
  output [1:0]  io_vtype_bits_vsew,
  output [2:0]  io_vtype_bits_vlmul,
  output        io_vlIsZero,
  output        io_vlIsVlmax
);

  import vset_pkg::vtype_out_t;
  vtype_out_t vtype_out;

  // vset 计算核（rs1/rs2 整型源、写 vl 寄存器形态 RiWvf）
  xs_VSetRiWvf_core u_core (
    .valid       (io_in_valid),
    .func        (io_in_bits_ctrl_fuOpType),
    .src0        (io_in_bits_data_src_0),
    .src1        (io_in_bits_data_src_1),
    .res_data    (io_out_bits_res_data),
    .vtype_valid (io_vtype_valid),
    .vtype_out   (vtype_out),
    .vl_is_zero  (io_vlIsZero),
    .vl_is_vlmax (io_vlIsVlmax)
  );

  // vtype 结构拆成 golden 的扁平字段
  assign io_vtype_bits_illegal = vtype_out.illegal;
  assign io_vtype_bits_vma     = vtype_out.vma;
  assign io_vtype_bits_vta     = vtype_out.vta;
  assign io_vtype_bits_vsew    = vtype_out.vsew;
  assign io_vtype_bits_vlmul   = vtype_out.vlmul;

  // 握手直通（无内部阻塞）
  assign io_in_ready                                      = io_out_ready;

  // 控制/调试旁路直通（Chisel PipedFuncUnit 的 out := in）
  assign io_out_valid                                     = io_in_valid;
  assign io_out_bits_ctrl_robIdx_flag                     = io_in_bits_ctrl_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value                    = io_in_bits_ctrl_robIdx_value;
  assign io_out_bits_ctrl_pdest                           = io_in_bits_ctrl_pdest;
  assign io_out_bits_ctrl_vlWen                           = io_in_bits_ctrl_vlWen;
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
