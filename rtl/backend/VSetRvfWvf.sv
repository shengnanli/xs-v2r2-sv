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
