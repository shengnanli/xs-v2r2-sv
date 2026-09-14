// VSetRiWi —— 由 scripts/port_increment_migrate.py 迁移自上轮可读核
//
// 迁移依据（脚本已校验）：G0 与 G1 的 golden 去掉端口表后**逐字相同**，
// 即 G1 的改动只是接口增量（perfDebugInfo / debug.seqNum / ready 等透传字段），
// 运算逻辑未动。故核体沿用，wrapper 按 G1 端口重做，直通 assign 由 golden
// 文本机械提取（不手打）。
//
// vset 写 vtype/vl，本变体为 rs1-immediate(RiWi) 形态。
//
// 共享类型/计算函数在 rtl/backend/backend_common_pkg.sv 的 vset_pkg 里
// （与 VSetRvfWvf 共用一份；两边各存一份会让 package 名在整芯片编译时撞车）。


// =============================================================================
// VSetRiWi —— 可读核 xs_VSetRiWi_core(向量配置单元:读两整型寄存器、写整型 rd)
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/fu/wrapper/VSet.scala (class VSetRiWi)
//         + class VSetBase(操作数/vtype 选源) + class VsetModule(vl 计算)。
//
// 角色:处理 vset 指令中「把新 vl 写到整型寄存器 rd」的那个 uop(uvsetrd_*)。
//   覆盖 uvsetrd_ii / uvsetrd_xi / uvsetrd_xx / uvsetrd_vlmax_{i,x} 等变体。
//   输出 res.data = 计算出的 vl(零扩展到 64 位)。本核 **不写 vtype 寄存器**
//   (那是 VSetRiWvf/VSetRvfWvf 的职责),故只产出 vl。
//
// 数据流(纯组合,单周期):
//   ┌── src0/src1 + fuOpType
//   │      │
//   │  ① 选 AVL    : vsetivli 用立即数(src1[14:10]),否则用整型 rs1=src0。
//   │  ② 选 vtype  : vsetvl 用 rs2 的 VtypeStruct(src1),否则用立即数解码的 vtype。
//   │      │
//   │  ③ VsetModule 计算: VLMAX、合法性、vl=min(AVL,VLMAX)。
//   └──> res.data = {56'b0, vl}
//
// VSetBase 的握手/控制位(valid/robIdx/pdest/rfWen/perfDebugInfo)由 wrapper 直通。
// =============================================================================
module xs_VSetRiWi_core
  import vset_pkg::*;
(
  input  logic [8:0]  func,    // fuOpType(vset 变体编码)
  input  logic [63:0] src0,    // 整型 rs1(普通 AVL)
  input  logic [63:0] src1,    // 整型 rs2 / 立即数载体(vtype、立即 AVL)
  output logic [63:0] res_data // 写回整型 rd 的 vl(零扩展)
);

  // ---------------------------------------------------------------------------
  // ① AVL 选源
  //   - vsetivli(func[7:6]==00):AVL 来自指令 uimm5,封装在 src1[14:10]。
  //   - 其余(vsetvli/vsetvl):AVL = 整型 rs1 = src0(rs1==x0 的 vlmax 特例由
  //     calc_vl 里的 setVlmax 位处理,这里仍取 src0)。
  //   判据 (|func[7:6]) == !isVsetivli,与 golden 一致。
  // ---------------------------------------------------------------------------
  logic [63:0] avl;
  assign avl = (|func[7:6]) ? src0 : {59'h0, src1[14:10]};

  // ---------------------------------------------------------------------------
  // ② vtype 选源 —— 三条路径解码成统一的 vtype_in_t
  //   - vsetvl(func[6]=1):vtype = rs2 的 VtypeStruct(src1),含 vill(src1[63])
  //     与 55 位 reserved(src1[62:8])。
  //   - vsetvli(func[7]=1):vtype = 11 位立即数 InstVType,reserved 仅 3 位(src1[10:8])。
  //   - vsetivli(func[7:6]=00):vtype = 10 位立即数 InstVType,reserved 仅 2 位(src1[9:8])。
  //   三路的 vma/vta/vsew/vlmul 位置相同(src1[7]/[6]/[5:3]/[2:0]),差异只在
  //   illegal 与 reserved 的来源与宽度。
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
  // ③ VsetModule 计算:VLMAX / 合法性 / vl
  // ---------------------------------------------------------------------------
  logic [2:0]          log2_sew;
  logic [VLMAX_W-1:0]  vlmax;
  logic                illegal;
  logic [VL_WIDTH-1:0] vl;

  assign log2_sew = calc_log2_sew(vtype.vsew);
  assign vlmax    = calc_vlmax(vtype.vlmul, log2_sew);
  assign illegal  = calc_illegal(vtype.vlmul, vtype.vsew, log2_sew,
                                 vtype.reserved, vtype.illegal);
  assign vl       = calc_vl(illegal, func, avl, vlmax);

  // 写回 rd:vl 零扩展到 64 位(VSetRiWi 只产出 vl)。
  assign res_data = {56'h0, vl};

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden VSetRiWi.sv 完全一致
// ---------------------------------------------------------------------------
module VSetRiWi(
  output        io_in_ready,
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,
  input         io_in_bits_ctrl_robIdx_flag,
  input  [7:0]  io_in_bits_ctrl_robIdx_value,
  input  [7:0]  io_in_bits_ctrl_pdest,
  input         io_in_bits_ctrl_rfWen,
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
  output        io_out_bits_ctrl_rfWen,
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
  output [7:0]  io_out_bits_debug_seqNum_uopIdx
);

  // vset 计算核：func/src -> {vtype, vl} 打包结果
  xs_VSetRiWi_core u_core (
    .func     (io_in_bits_ctrl_fuOpType),
    .src0     (io_in_bits_data_src_0),
    .src1     (io_in_bits_data_src_1),
    .res_data (io_out_bits_res_data)
  );

  // 握手直通（无内部阻塞）
  assign io_in_ready                                      = io_out_ready;

  // 控制/调试旁路直通（Chisel PipedFuncUnit 的 out := in）
  assign io_out_valid                                     = io_in_valid;
  assign io_out_bits_ctrl_robIdx_flag                     = io_in_bits_ctrl_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value                    = io_in_bits_ctrl_robIdx_value;
  assign io_out_bits_ctrl_pdest                           = io_in_bits_ctrl_pdest;
  assign io_out_bits_ctrl_rfWen                           = io_in_bits_ctrl_rfWen;
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
