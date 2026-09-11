// =============================================================================
// immextractor_pkg —— 香山 V2R2(昆明湖) 立即数抽取/扩展 的类型与编码定义
// -----------------------------------------------------------------------------
// 设计源:
//   - src/main/scala/xiangshan/backend/issue/ImmExtractor.scala (ImmExtractor)
//   - src/main/scala/xiangshan/backend/decode/DecodeUnit.scala  (object ImmUnion 及各 Imm_* case class)
//   - src/main/scala/xiangshan/package.scala                    (object SelImm 的 4 位编码)
//
// 背景(为什么需要 ImmExtractor):
//   RISC-V 各指令格式(I/S/B/U/J/...)把立即数拆散打包在指令的不同位段里,
//   且位宽各异(5~32 位)。译码阶段(DecodeUnit)并不把立即数立刻扩成 32/64 位,
//   而是先用 minBitsFromInstr() 把散落的立即数位**紧凑拼接**成一个最小宽度的
//   "压缩立即数"(minBits)随 uop 流入发射队列(IQ)。这样 IQ 里每条 uop 只存
//   ImmUnion.maxLen(=20)位立即数,省面积。
//
//   到了发射后、进执行单元前,才由 ImmExtractor 按该 uop 的 selImm 类型,把压缩
//   立即数 do_toImm32() 还原成 32 位真值并符号/零扩展到数据通路位宽(64 或向量 128)。
//   故本模块的输入 imm **不是原始指令**,而是译码已打包好的 minBits。
//
// 关键点 —— 本模块只做 do_toImm32 + 扩展,不做 minBitsFromInstr:
//   minBitsFromInstr(从指令抽位)在译码阶段已完成;ImmExtractor 只负责
//   "压缩立即数 -> 32 位 -> 扩展到 dataBits"。两步分离是香山省 IQ 面积的设计。
// =============================================================================
package immextractor_pkg;

  // SelImm 4 位编码(见 object SelImm)。各执行单元的 IQ 只会出现其指令集子集,
  // 故 ImmExtractor 被参数化:只对"该 IQ 用到的类型"生成 mux 分支,其余返回 0。
  typedef enum logic [3:0] {
    IMM_SB       = 4'h1,  // B 型分支:SignExt(Cat(minBits[11:0], 1'b0))
    IMM_U        = 4'h2,  // U 型(lui/auipc 高 20 位):Cat(minBits[19:0], 12'b0) 后按 bit31 符号扩展
    IMM_UJ       = 4'h3,  // J 型跳转:SignExt(Cat(minBits[19:0], 1'b0))
    IMM_I        = 4'h4,  // I 型:SignExt(minBits[11:0])
    IMM_Z        = 4'h5,  // CSR/Zicsr 类:22 位原样(rd|rs1|csr),零扩展
    IMM_B6       = 4'h8,  // 6 位无符号(部分位移/向量):ZeroExt(minBits[5:0])
    IMM_OPIVIS   = 4'h9,  // 向量 OPIVI 有符号 5 位:SignExt(minBits[4:0])
    IMM_OPIVIU   = 4'hA,  // 向量 OPIVI 无符号 5 位:ZeroExt(minBits[4:0])
    IMM_LUI32    = 4'hB,  // 32 位立即数:minBits[31:0] 按 bit31 符号扩展
    IMM_VSETVLI  = 4'hC,  // vsetvli 的 11 位 vtypei:SignExt(minBits[10:0])
    IMM_VSETIVLI = 4'hD,  // vsetivli 的 15 位(uimm5|vtype8|...):SignExt(minBits[14:0])
    IMM_S        = 4'hE,  // S 型存储:SignExt(minBits[11:0])
    IMM_VRORVI   = 4'hF   // 向量 ror 立即:ZeroExt(Cat(...)) 6 位
  } sel_imm_e;

  // 各类型在"使能掩码"里的 bit 位 = 其 4 位编码。给变体包装层用一个 16 位
  // 掩码声明"本 IQ 支持哪些立即数类型",未使能的类型输出 0(与 golden MuxLookup
  // 的 default 0.U 对齐)。
  function automatic logic type_enabled(logic [15:0] mask, sel_imm_e t);
    return mask[t];
  endfunction

endpackage : immextractor_pkg

// =============================================================================
// xs_imm_extractor_core —— 香山 V2R2 立即数抽取/符号扩展核 (可读重写)
// -----------------------------------------------------------------------------
// 设计源:ImmExtractor.scala 的 MuxLookup + DecodeUnit.scala 各 Imm_*.do_toImm32。
//
// 角色:纯组合叶子。输入 = 译码已打包的"压缩立即数"minBits(32 位载体,实际有效
//   位数随类型不同)+ 4 位 selImm 类型;输出 = 还原并扩展到数据通路位宽的立即数。
//
// 两段式语义(见 pkg 注释):
//   1) do_toImm32(minBits):按 RISC-V 指令格式把压缩立即数还原成 32 位真值
//      (该补的低 0 位、该符号/零扩展到 32 位,各类型规则不同)。
//   2) SignExt 到 IntData(=64 位):整数数据通路位宽。向量 IQ 的 dataBits=128 时,
//      golden 把 64 位结果零扩展到高 64 位(见 ImmExtractor_12/_37)。
//
// 参数化设计意图:
//   不同执行单元的 IQ 只会出现其指令子集对应的立即数类型(如整数 IQ 只有 I/U/...,
//   向量 IQ 只有 OPIVI/VSET/...)。Scala 用 immTypeSet 过滤 MuxLookup 分支,未用到
//   的类型不生成、查表落 default 0。这里用 TYPE_EN 掩码表达同一意图:核内对全部
//   13 种类型都能解码,但只有 TYPE_EN 使能的类型才输出其值,其余落 0。
//   => 一份可读核覆盖 golden 的所有 ImmExtractor 变体(不同 immTypeSet/dataBits)。
// =============================================================================

module xs_imm_extractor_core
  import immextractor_pkg::*;
#(
  parameter int          DATA_BITS = 64,        // 数据通路位宽:整数 64,向量 128
  parameter logic [15:0] TYPE_EN   = 16'hFFFF   // 本 IQ 使能的 selImm 类型掩码(bit=编码值)
) (
  input  logic [31:0]          io_in_imm,       // 压缩立即数 minBits(译码打包,非原始指令)
  input  logic [3:0]           io_in_immType,   // selImm 4 位类型码
  output logic [DATA_BITS-1:0] io_out_imm
);

  localparam int INT_BITS = 64;  // IntData().dataWidth:整数数据通路位宽

  // ---------------------------------------------------------------------------
  // do_toImm32 + 扩展到 64 位:对每种类型给出"还原 32 位真值并 SignExt 到 64 位"
  // 的结果。注意各类型 do_toImm32 内部的扩展规则:
  //   - SignExt(x, 32):x 不足 32 位时按其最高位符号扩展到 32,再整体扩到 64;
  //     等价于直接对 x 的最高位符号扩展到 64 位。
  //   - ZeroExt(x, 32):零扩展,等价于直接零扩展到 64 位。
  //   - U 型:do_toImm32 = {minBits[19:0],12'b0} 恰好 32 位,符号位是 bit31=minBits[19]。
  //   - Z 型:do_toImm32 = minBits(22 位)原样,零扩展到 64。
  //   - LUI32:do_toImm32 = minBits[31:0],符号位 bit31=minBits[31]。
  // 返回 64 位,顶层再据 DATA_BITS 决定是否零扩展到 128。
  // ---------------------------------------------------------------------------
  function automatic logic [INT_BITS-1:0] decode_imm
      (sel_imm_e t, logic [31:0] m);
    unique case (t)
      IMM_I:        return {{(INT_BITS-12){m[11]}}, m[11:0]};                 // SignExt(m[11:0])
      IMM_S:        return {{(INT_BITS-12){m[11]}}, m[11:0]};                 // SignExt(m[11:0])
      IMM_SB:       return {{(INT_BITS-13){m[11]}}, m[11:0], 1'b0};           // SignExt({m[11:0],0})
      IMM_U:        return {{(INT_BITS-32){m[19]}}, m[19:0], 12'b0};          // {m[19:0],12'0}, 符号=bit19
      IMM_UJ:       return {{(INT_BITS-21){m[19]}}, m[19:0], 1'b0};           // SignExt({m[19:0],0})
      IMM_Z:        return {{(INT_BITS-22){1'b0}},  m[21:0]};                 // ZeroExt(m[21:0])
      IMM_B6:       return {{(INT_BITS-6){1'b0}},   m[5:0]};                  // ZeroExt(m[5:0])
      IMM_OPIVIS:   return {{(INT_BITS-5){m[4]}},   m[4:0]};                  // SignExt(m[4:0])
      IMM_OPIVIU:   return {{(INT_BITS-5){1'b0}},   m[4:0]};                  // ZeroExt(m[4:0])
      IMM_LUI32:    return {{(INT_BITS-32){m[31]}}, m[31:0]};                 // SignExt(m[31:0])
      IMM_VSETVLI:  return {{(INT_BITS-11){m[10]}}, m[10:0]};                 // SignExt(m[10:0])
      IMM_VSETIVLI: return {{(INT_BITS-15){m[14]}}, m[14:0]};                 // SignExt(m[14:0])
      IMM_VRORVI:   return {{(INT_BITS-6){1'b0}},   m[5:0]};                  // ZeroExt(m[5:0])
      default:      return '0;
    endcase
  endfunction

  // 64 位还原值;仅当该类型被本 IQ 使能时才输出,否则 0(对齐 MuxLookup default)。
  logic [INT_BITS-1:0] imm64;
  sel_imm_e            sel_type;
  always_comb begin
    sel_type = sel_imm_e'(io_in_immType);
    imm64    = type_enabled(TYPE_EN, sel_type) ? decode_imm(sel_type, io_in_imm) : '0;
  end

  // 扩展到数据通路位宽:64 位直接输出;>64(向量 128)时高位零扩展。
  generate
    if (DATA_BITS == INT_BITS) begin : g_int
      assign io_out_imm = imm64;
    end else begin : g_wide
      assign io_out_imm = {{(DATA_BITS-INT_BITS){1'b0}}, imm64};
    end
  endgenerate

endmodule : xs_imm_extractor_core

// =============================================================================
// ImmExtractor (wrapper) —— golden 同名顶层,端口与 golden/chisel-rtl/ImmExtractor.sv 一致。
// -----------------------------------------------------------------------------
// 该 golden 变体对应整数 IQ 的最小立即数集合:immTypeSet = {IMM_I, IMM_U, IMM_LUI32},
// dataBits = 64。见 golden 模块体只含 0xB(LUI32)/0x4(I)/0x2(U) 三个分支、其余 0。
//
// 用 TYPE_EN 掩码把可读核裁剪到这三种类型:bit2(U) | bit4(I) | bit11(LUI32) = 0x0814。
// 本层是机械的端口适配 + 参数固化,供 Formality 等价比对与系统级替换。
// =============================================================================
// =============================================================================
// ImmExtractor_12 (wrapper) —— golden 同名顶层(向量 IQ 全类型集, dataBits=128)。
// 端口与 golden/chisel-rtl/ImmExtractor_12.sv 一致。
// 使能类型(见 golden 模块体):SB(1) U(2) UJ(3) I(4) OPIVIS(9) OPIVIU(A)
//   VSETVLI(C) VSETIVLI(D) VRORVI(F) => 掩码 0xB61E。
// =============================================================================

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module ImmExtractor (
  input  logic [31:0] io_in_imm,
  input  logic [3:0]  io_in_immType,
  output logic [63:0] io_out_imm
);

  xs_imm_extractor_core #(
    .DATA_BITS(64),
    .TYPE_EN  (16'h0814)   // IMM_U(2) | IMM_I(4) | IMM_LUI32(11)
  ) u_core (
    .io_in_imm    (io_in_imm),
    .io_in_immType(io_in_immType),
    .io_out_imm   (io_out_imm)
  );

endmodule
