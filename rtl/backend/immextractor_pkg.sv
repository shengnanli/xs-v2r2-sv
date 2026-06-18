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
