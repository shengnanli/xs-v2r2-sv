// VSetRvfWvf —— 由 scripts/port_increment_migrate.py 迁移自上轮可读核
//
// 迁移依据（脚本已校验）：G0 与 G1 的 golden 去掉端口表后**逐字相同**，
// 即 G1 的改动只是接口增量（perfDebugInfo / debug.seqNum / ready 等透传字段），
// 运算逻辑未动。故核体沿用，wrapper 按 G1 端口重做，直通 assign 由 golden
// 文本机械提取（不手打）。
//
// vset 写 vtype/vl，本变体为 rs1 取 vtype 寄存器(RvfWvf)形态。
//
// 共享类型/计算函数在 rtl/backend/backend_common_pkg.sv 的 vset_pkg 里
// （与 VSetRiWi 共用一份；两边各存一份会让 package 名在整芯片编译时撞车）。


// =============================================================================
// VSetRvfWvf —— 可读核 xs_VSetRvfWvf_core(向量配置:读旧 vconfig+vtmp,写 vconfig)
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/fu/wrapper/VSet.scala (class VSetRvfWvf)
//         + class VSetBase + class VsetModule。
//
// 角色:处理两类「保持 vl、只改 vtype」及读 vl 的 uop:
//   - uvsetvcfg_vv  (0111_0010):vsetvl 的 rs1==x0&rd==x0 分裂出的第二 uop,
//                                AVL = 旧 vconfig.vl(保持 vl),vtype 来自 rs2 的 VtypeStruct。
//   - uvsetvcfg_keep_v(1010_0010):vsetvli 的同类情形,vtype 来自立即数。
//   - csrrvl(0001_0110):读向量、写整型——直接把旧 vl 透传到 rd,不做配置计算。
//
//   与 VSetRiWi 的关键区别:
//     · AVL 不来自 rs1,而是 src4 = 旧 VConfig.vl(8 位,保持上一次的 vl);
//     · 除写 vl 外还 **写回 vtype 寄存器**(vtype_out),并产出 vlIsZero/vlIsVlmax
//       两个标志(供后续 rename/dispatch 快速判断 vl 边界);
//     · res.data 在 csrrvl 时直接回送旧 vl。
//
// 数据流(纯组合):
//   src4(oldVL) ─► AVL ─┐
//   src1(128b)  ─► vtype ┴─► VsetModule(vlmax/illegal/vl) ─► vtype_out, vl
//                                                       │
//   csrrvl ? oldVL : vl ───────────────────────────────┴─► res_data
// =============================================================================

module xs_VSetRvfWvf_core
  import vset_pkg::*;
(
  input  logic         valid,        // 本拍是否有效(决定 vtype_valid/标志)
  input  logic [8:0]   func,         // fuOpType
  input  logic [7:0]   src4,         // 旧 VConfig.vl(AVL = 保持的 vl)
  input  logic [127:0] src1,         // rs2 VtypeStruct / 立即数载体
  output logic [63:0]  res_data,     // 写回 rd 的 vl(csrrvl 时为旧 vl)
  output logic         vtype_valid,  // vtype 寄存器写使能(仅 vsetvl 路径)
  output vtype_out_t   vtype_out,    // 写回的 vtype(SEW/LMUL/ta/ma/vill)
  output logic         vl_is_zero,   // 新 vl == 0
  output logic         vl_is_vlmax   // 新 vl == VLMAX
);

  // ---------------------------------------------------------------------------
  // ① AVL = 旧 vl(保持语义):src4 零扩展到 64 位。
  // ---------------------------------------------------------------------------
  logic [63:0] old_vl;
  logic [63:0] avl;
  assign old_vl = {56'h0, src4};
  assign avl    = old_vl;

  // ---------------------------------------------------------------------------
  // ② vtype 选源(与 VSetRiWi 同构;此处 src1 为 128 位,仍只用低位)
  //   - vsetvl(func[6]):VtypeStruct(src1[63],src1[62:8],...)。
  //   - 立即数(keep_v):无 vill,reserved 按 vsetvli/vsetivli 取位段零扩展。
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
      VSET_IVLI: begin  // 立即数 vtype,reserved 仅 2 位
        vtype.illegal  = 1'b0;
        vtype.reserved = {53'h0, src1[9:8]};
      end
      VSET_VLI: begin   // 立即数 vtype,reserved 3 位
        vtype.illegal  = 1'b0;
        vtype.reserved = {52'h0, src1[10:8]};
      end
      default: begin    // VSET_VL / VSET_VL2:寄存器 VtypeStruct(含 vill)
        vtype.illegal  = src1[63];
        vtype.reserved = src1[62:8];
      end
    endcase
  end

  // ---------------------------------------------------------------------------
  // ③ VsetModule 计算:VLMAX / 合法性 / vl / 写回 vtype
  // ---------------------------------------------------------------------------
  logic [2:0]          log2_sew;
  logic [VLMAX_W-1:0]  vlmax_raw;     // 1<<log2Vlmax(可能小于 VLEN/SEW)
  logic [VLMAX_W-1:0]  vlen_div_sew;  // VLEN/SEW 下界
  logic [VLMAX_W-1:0]  vlmax_out;     // 对外 vlmax = max(vlmax_raw, VLEN/SEW)
  logic                illegal;
  logic [VL_WIDTH-1:0] vl;

  assign log2_sew     = calc_log2_sew(vtype.vsew);
  assign vlmax_raw    = calc_vlmax(vtype.vlmul, log2_sew);
  assign vlen_div_sew = calc_vlen_div_sew(log2_sew);
  // 对外 vlmax 取下界保护(避免 LMUL 分数时 vlmax_raw 截位为 0)。
  assign vlmax_out    = (vlmax_raw >= vlen_div_sew) ? vlmax_raw : vlen_div_sew;
  assign illegal      = calc_illegal(vtype.vlmul, vtype.vsew, log2_sew,
                                     vtype.reserved, vtype.illegal);
  assign vl           = calc_vl(illegal, func, avl, vlmax_raw);

  // 写回 vtype:非法时整体清零并置 vill;vsew 收窄为 2 位。
  always_comb begin
    vtype_out.illegal = illegal;
    vtype_out.vma     = illegal ? 1'b0  : vtype.vma;
    vtype_out.vta     = illegal ? 1'b0  : vtype.vta;
    vtype_out.vsew    = illegal ? 2'b0  : vtype.vsew[1:0];
    vtype_out.vlmul   = illegal ? 3'b0  : vtype.vlmul;
  end

  // ---------------------------------------------------------------------------
  // ④ 输出:res.data / vtype 写使能 / vl 边界标志
  //   - csrrvl 只读 vl:res.data = 旧 vl(不取新算的 vl)。
  //   - vtype_valid:仅 vsetvl 路径(func[6])且本拍有效时写 vtype 寄存器。
  //   - vl_is_zero/vlmax:有效、且非 csrrvl(读 vl 不算配置)时,比较新 vl。
  // ---------------------------------------------------------------------------
  logic is_read_vl;
  assign is_read_vl = (func == FUOP_CSRRVL);

  assign res_data    = {56'h0, is_read_vl ? src4 : vl};
  assign vtype_valid = func[6] & valid;
  assign vl_is_zero  = valid & ~is_read_vl & (vl == '0);
  assign vl_is_vlmax = valid & ~is_read_vl & (vl == vlmax_out[VL_WIDTH-1:0]);

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden VSetRvfWvf.sv 完全一致
// ---------------------------------------------------------------------------
module VSetRvfWvf(
  output         io_in_ready,
  input          io_in_valid,
  input  [8:0]   io_in_bits_ctrl_fuOpType,
  input          io_in_bits_ctrl_robIdx_flag,
  input  [7:0]   io_in_bits_ctrl_robIdx_value,
  input  [7:0]   io_in_bits_ctrl_pdest,
  input          io_in_bits_ctrl_rfWen,
  input          io_in_bits_ctrl_vlWen,
  input  [7:0]   io_in_bits_data_src_4,
  input  [127:0] io_in_bits_data_src_1,
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
  output         io_out_bits_ctrl_rfWen,
  output         io_out_bits_ctrl_vlWen,
  output [63:0]  io_out_bits_res_data,
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
  output [7:0]   io_out_bits_debug_seqNum_uopIdx,
  output         io_vtype_valid,
  output         io_vtype_bits_illegal,
  output         io_vtype_bits_vma,
  output         io_vtype_bits_vta,
  output [1:0]   io_vtype_bits_vsew,
  output [2:0]   io_vtype_bits_vlmul,
  output         io_vlIsZero,
  output         io_vlIsVlmax
);

  import vset_pkg::vtype_out_t;
  vtype_out_t vtype_out;

  // vset 计算核（rs1=vtype 寄存器形态 RvfWvf）
  xs_VSetRvfWvf_core u_core (
    .valid       (io_in_valid),
    .func        (io_in_bits_ctrl_fuOpType),
    .src4        (io_in_bits_data_src_4),
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
  assign io_out_bits_ctrl_rfWen                           = io_in_bits_ctrl_rfWen;
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
