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
