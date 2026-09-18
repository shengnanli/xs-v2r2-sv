// =============================================================================
// VecExceptionGen.sv —— 向量指令「非法指令」判据生成器（纯组合，无寄存器）
// -----------------------------------------------------------------------------
// 设计源:XiangShan src/main/scala/xiangshan/backend/decode/VecExceptionGen.scala
// golden 对照:G1-canonical/golden-rtl/VecExceptionGen.sv（340 行,0 子模块,0 寄存器）
//
// ★ 它是什么 ★
// 复杂指令译码单元 DecodeUnitComp 里挂的一个纯查表/比较块。上一级已经把指令译出
// fuType/srcType/vecWen,本块拿**锁存下来的**指令字 + 当前 vtype + vstart,回答一个
// 问题:这条向量指令在这组 vtype 下是不是非法指令(EX_II)。它的唯一输出
// io_illegalInst 会被或进 csBundle 的 exceptionVec(EX_II)。
//
// ★ 七条判据(RISC-V V 规范的七类约束,彼此独立取或)★
//   1 instIllegal      掩码逻辑指令要求 vm=1(不许带掩码)
//   2 villIllegal      vtype.vill 置位时,除 vset*/整寄存器访存外一律非法
//   3 eewIllegal       元素宽度越界:浮点 SEW=8、扩展指令 SEW 太小、加宽/收窄 SEW=64
//   4 emulIllegal      寄存器组倍数越界:访存 EMUL 超 [1/8,8]、段访存寄存器数超限等
//   5 regNumIllegal    EMUL>1 时寄存器号必须按 EMUL 对齐
//   6 regOverlapIllegal  vd 与 v0/vs1/vs2 的重叠约束
//   7 vstartIllegal    向量**算术**类不允许 vstart≠0(香山实现约束,非 RISC-V 规范)
//
// ★ 结构说明 ★
// §1 指令类归属  —— 由 gen.py 从 Chisel + rocket-chip BitPat 机械生成(见区段头)
// §2 公共派生量  —— SEW/LMUL/寄存器号/段访存规模
// §3~§7 上面七条判据,逐条对着 golden 的同名 wire 写
//
// ★ golden 与 Chisel 字面不一致处(一律以 golden 为准,逐条注在使用点)★
//   (a) Chisel 的 `isVset` 没有任何读者,firtool 整条消掉 —— 这里也不写。
//   (b) `LMUL + 1.U`(Chisel `+`,3 位截断)与 `LMUL +& 1.U`(4 位)在本文件里**都
//       出现**,且落在相邻两行:vs2Emul 的 sel==4'h4 分支是 3 位截断(LMUL=7 → 0),
//       vs1Emul 的 vrgather16 分支是 4 位。两处都照 golden 写。
//       ★诚实记录:这两处的差别在**输出上不可观测**★ —— 负测实测抓不到,而且
//       能证明抓不到,见 §5 的两段论证。**Formality 已正面证实**:把这两种写法
//       各自当 impl 与 golden 跑 signoff-strict,都是 Verification SUCCEEDED
//       (1 passing / 0 failing / 0 unmatched)。也就是说照字面统一成一种**不会**
//       让 FM 失配。之所以仍然逐位照抄,是本工程的规矩:「凡 golden 里看起来
//       冗余的结构,先照抄,别合并」—— 上游 Chisel 一改,不可观测随时变成可观测。
//   (c) `SEW - 3.U` 被 firtool 折成 `SEW + 1`(2 位模运算),同值;这里按 Chisel 原式
//       写 `sew - 2'd3`,位宽 2 位 —— 两者逐位相同。
// =============================================================================

package vecexceptiongen_pkg;

  // BitPat 匹配:care 是「关心哪些位」的掩码,value 是这些位应有的值。
  // 纯函数,全部依赖走参数 —— 不读任何模块级信号(FM 不接受函数体里的闭包)。
  function automatic logic bitpat_match(input logic [31:0] inst,
                                        input logic [31:0] care,
                                        input logic [31:0] value);
    bitpat_match = ((inst & care) == value);
  endfunction

  // LmultoRegNum:EMUL 编码 → 该操作数占几个向量寄存器。
  // 编码是「偏置 4」的有符号量:0..3 = 分数 EMUL(1/8,1/4,1/2 …都只占 1 个寄存器),
  // 4..7 = EMUL 1/2/4/8。所以只有最高位(bit2)置起时才按 bit[1:0] 做 2 的幂。
  function automatic logic [3:0] lmul_to_regnum(input logic [3:0] emul);
    lmul_to_regnum = 4'd1 << (emul[2] ? emul[1:0] : 2'd0);
  endfunction

  // EMUL = 2/4/8 时,起始寄存器号必须 2/4/8 对齐。reg_lo3 给寄存器号的低 3 位。
  function automatic logic reg_num_not_align(input logic [3:0] emul,
                                             input logic [2:0] reg_lo3);
    reg_num_not_align = (emul == 4'd5 && reg_lo3[0])
                     || (emul == 4'd6 && |reg_lo3[1:0])
                     || (emul == 4'd7 && |reg_lo3[2:0]);
  endfunction

  // NFtoLmul:段访存的 field 数(nf 域)→ EMUL 编码。nf=0/1/3/7 即 1/2/4/8 个 field,
  // 分别对应 EMUL 1/2/4/8 = 编码 4/5/6/7。其余 nf 取 0(Chisel LookupTree 无默认项,
  // 展开成或树,不命中即全 0)。
  // ★这个「其余取 0」是死分支★:本模块只在两处调用它 —— vmv<N>r.v 与整寄存器
  // 访存,而这两类指令的 BitPat 把那个域(分别是 inst[19:15] 与 inst[31:29])钉成
  // care 位,取值只能是 0/1/3/7。所以默认值写 0 还是写别的都不可观测;照 golden
  // 写 0,并在 mutants.py 里登记为「预期抓不到」。
  function automatic logic [2:0] nf_to_lmul(input logic [2:0] nf);
    nf_to_lmul = (nf == 3'd0) ? 3'd4 :
                 (nf == 3'd1) ? 3'd5 :
                 (nf == 3'd3) ? 3'd6 :
                 (nf == 3'd7) ? 3'd7 : 3'd0;
  endfunction

endpackage : vecexceptiongen_pkg


// =============================================================================
// xs_VecExceptionGen_core —— 可读核
// =============================================================================
module xs_VecExceptionGen_core
  import vecexceptiongen_pkg::*;
(
  input  logic [31:0] inst,          // 锁存下来的 32 位指令字
  input  logic [3:0]  src_type_vs1,  // srcType(0);只有 bit2(=isVp「是向量源」)被读
  input  logic [3:0]  src_type_vs2,  // srcType(1)
  input  logic [3:0]  src_type_vd,   // srcType(2)
  input  logic [34:0] fu_type,       // one-hot 功能单元类型
  input  logic        vec_wen,       // 本指令写向量寄存器堆
  input  logic        vtype_illegal, // vtype.vill
  input  logic [1:0]  vsew,          // vtype.vsew
  input  logic [2:0]  vlmul,         // vtype.vlmul(偏置编码:bit2 取反后才是量值)
  input  logic [7:0]  vstart,        // vstart CSR
  output logic        illegal_inst
);

  // ---------------------------------------------------------------------------
  // §1 指令类归属
  // ---------------------------------------------------------------------------
  // BEGIN GENERATED(instclass)
  // 下面这一片由 verif/ut/VecExceptionGen/gen.py 从 Chisel 源与 rocket-chip
  // 的 BitPat 定义机械生成（助记符与原始编码见行尾注释），不要手改。
  // 每一项都是「关心位相等」判断：(inst & care) == value。

  // 单位步长/跨步向量访存（含 fault-only-first）
  // Chisel: lsStrideInst  （20 条指令）
  wire is_ls_stride =
      bitpat_match(inst, 32'h1DF0707F, 32'h00000007)   // VLE8_V           ???000?00000?????000?????0000111
    | bitpat_match(inst, 32'h1DF0707F, 32'h00005007)   // VLE16_V          ???000?00000?????101?????0000111
    | bitpat_match(inst, 32'h1DF0707F, 32'h00006007)   // VLE32_V          ???000?00000?????110?????0000111
    | bitpat_match(inst, 32'h1DF0707F, 32'h00007007)   // VLE64_V          ???000?00000?????111?????0000111
    | bitpat_match(inst, 32'h1DF0707F, 32'h00000027)   // VSE8_V           ???000?00000?????000?????0100111
    | bitpat_match(inst, 32'h1DF0707F, 32'h00005027)   // VSE16_V          ???000?00000?????101?????0100111
    | bitpat_match(inst, 32'h1DF0707F, 32'h00006027)   // VSE32_V          ???000?00000?????110?????0100111
    | bitpat_match(inst, 32'h1DF0707F, 32'h00007027)   // VSE64_V          ???000?00000?????111?????0100111
    | bitpat_match(inst, 32'h1C00707F, 32'h08000007)   // VLSE8_V          ???010???????????000?????0000111
    | bitpat_match(inst, 32'h1C00707F, 32'h08005007)   // VLSE16_V         ???010???????????101?????0000111
    | bitpat_match(inst, 32'h1C00707F, 32'h08006007)   // VLSE32_V         ???010???????????110?????0000111
    | bitpat_match(inst, 32'h1C00707F, 32'h08007007)   // VLSE64_V         ???010???????????111?????0000111
    | bitpat_match(inst, 32'h1C00707F, 32'h08000027)   // VSSE8_V          ???010???????????000?????0100111
    | bitpat_match(inst, 32'h1C00707F, 32'h08005027)   // VSSE16_V         ???010???????????101?????0100111
    | bitpat_match(inst, 32'h1C00707F, 32'h08006027)   // VSSE32_V         ???010???????????110?????0100111
    | bitpat_match(inst, 32'h1C00707F, 32'h08007027)   // VSSE64_V         ???010???????????111?????0100111
    | bitpat_match(inst, 32'h1DF0707F, 32'h01000007)   // VLE8FF_V         ???000?10000?????000?????0000111
    | bitpat_match(inst, 32'h1DF0707F, 32'h01005007)   // VLE16FF_V        ???000?10000?????101?????0000111
    | bitpat_match(inst, 32'h1DF0707F, 32'h01006007)   // VLE32FF_V        ???000?10000?????110?????0000111
    | bitpat_match(inst, 32'h1DF0707F, 32'h01007007);  // VLE64FF_V        ???000?10000?????111?????0000111

  // 掩码寄存器访存 vlm/vsm（EEW 恒 8、EMUL 恒 1）
  // Chisel: lsMaskInst  （2 条指令）
  wire is_ls_mask =
      bitpat_match(inst, 32'hFFF0707F, 32'h02B00007)   // VLM_V            000000101011?????000?????0000111
    | bitpat_match(inst, 32'hFFF0707F, 32'h02B00027);  // VSM_V            000000101011?????000?????0100111

  // 索引访存（unordered/ordered，vs2 给下标）
  // Chisel: lsIndexInst  （16 条指令）
  wire is_ls_index =
      bitpat_match(inst, 32'h1C00707F, 32'h04000007)   // VLUXEI8_V        ???001???????????000?????0000111
    | bitpat_match(inst, 32'h1C00707F, 32'h04005007)   // VLUXEI16_V       ???001???????????101?????0000111
    | bitpat_match(inst, 32'h1C00707F, 32'h04006007)   // VLUXEI32_V       ???001???????????110?????0000111
    | bitpat_match(inst, 32'h1C00707F, 32'h04007007)   // VLUXEI64_V       ???001???????????111?????0000111
    | bitpat_match(inst, 32'h1C00707F, 32'h0C000007)   // VLOXEI8_V        ???011???????????000?????0000111
    | bitpat_match(inst, 32'h1C00707F, 32'h0C005007)   // VLOXEI16_V       ???011???????????101?????0000111
    | bitpat_match(inst, 32'h1C00707F, 32'h0C006007)   // VLOXEI32_V       ???011???????????110?????0000111
    | bitpat_match(inst, 32'h1C00707F, 32'h0C007007)   // VLOXEI64_V       ???011???????????111?????0000111
    | bitpat_match(inst, 32'h1C00707F, 32'h04000027)   // VSUXEI8_V        ???001???????????000?????0100111
    | bitpat_match(inst, 32'h1C00707F, 32'h04005027)   // VSUXEI16_V       ???001???????????101?????0100111
    | bitpat_match(inst, 32'h1C00707F, 32'h04006027)   // VSUXEI32_V       ???001???????????110?????0100111
    | bitpat_match(inst, 32'h1C00707F, 32'h04007027)   // VSUXEI64_V       ???001???????????111?????0100111
    | bitpat_match(inst, 32'h1C00707F, 32'h0C000027)   // VSOXEI8_V        ???011???????????000?????0100111
    | bitpat_match(inst, 32'h1C00707F, 32'h0C005027)   // VSOXEI16_V       ???011???????????101?????0100111
    | bitpat_match(inst, 32'h1C00707F, 32'h0C006027)   // VSOXEI32_V       ???011???????????110?????0100111
    | bitpat_match(inst, 32'h1C00707F, 32'h0C007027);  // VSOXEI64_V       ???011???????????111?????0100111

  // 整寄存器访存 vl<N>re<E>/vs<N>r（不看 vtype）
  // Chisel: lsWholeInst  （20 条指令）
  wire is_ls_whole =
      bitpat_match(inst, 32'hFFF0707F, 32'h02800007)   // VL1RE8_V         000000101000?????000?????0000111
    | bitpat_match(inst, 32'hFFF0707F, 32'h02805007)   // VL1RE16_V        000000101000?????101?????0000111
    | bitpat_match(inst, 32'hFFF0707F, 32'h02806007)   // VL1RE32_V        000000101000?????110?????0000111
    | bitpat_match(inst, 32'hFFF0707F, 32'h02807007)   // VL1RE64_V        000000101000?????111?????0000111
    | bitpat_match(inst, 32'hFFF0707F, 32'h22800007)   // VL2RE8_V         001000101000?????000?????0000111
    | bitpat_match(inst, 32'hFFF0707F, 32'h22805007)   // VL2RE16_V        001000101000?????101?????0000111
    | bitpat_match(inst, 32'hFFF0707F, 32'h22806007)   // VL2RE32_V        001000101000?????110?????0000111
    | bitpat_match(inst, 32'hFFF0707F, 32'h22807007)   // VL2RE64_V        001000101000?????111?????0000111
    | bitpat_match(inst, 32'hFFF0707F, 32'h62800007)   // VL4RE8_V         011000101000?????000?????0000111
    | bitpat_match(inst, 32'hFFF0707F, 32'h62805007)   // VL4RE16_V        011000101000?????101?????0000111
    | bitpat_match(inst, 32'hFFF0707F, 32'h62806007)   // VL4RE32_V        011000101000?????110?????0000111
    | bitpat_match(inst, 32'hFFF0707F, 32'h62807007)   // VL4RE64_V        011000101000?????111?????0000111
    | bitpat_match(inst, 32'hFFF0707F, 32'hE2800007)   // VL8RE8_V         111000101000?????000?????0000111
    | bitpat_match(inst, 32'hFFF0707F, 32'hE2805007)   // VL8RE16_V        111000101000?????101?????0000111
    | bitpat_match(inst, 32'hFFF0707F, 32'hE2806007)   // VL8RE32_V        111000101000?????110?????0000111
    | bitpat_match(inst, 32'hFFF0707F, 32'hE2807007)   // VL8RE64_V        111000101000?????111?????0000111
    | bitpat_match(inst, 32'hFFF0707F, 32'h02800027)   // VS1R_V           000000101000?????000?????0100111
    | bitpat_match(inst, 32'hFFF0707F, 32'h22800027)   // VS2R_V           001000101000?????000?????0100111
    | bitpat_match(inst, 32'hFFF0707F, 32'h62800027)   // VS4R_V           011000101000?????000?????0100111
    | bitpat_match(inst, 32'hFFF0707F, 32'hE2800027);  // VS8R_V           111000101000?????000?????0100111

  // vd 加宽（结果 EEW = 2×SEW）
  // Chisel: vdWideningInst  （57 条指令）
  wire is_vd_widening =
      bitpat_match(inst, 32'hFC00707F, 32'hC4002057)   // VWADD_VV         110001???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hC4006057)   // VWADD_VX         110001???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD4002057)   // VWADD_WV         110101???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD4006057)   // VWADD_WX         110101???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hC0002057)   // VWADDU_VV        110000???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hC0006057)   // VWADDU_VX        110000???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD0002057)   // VWADDU_WV        110100???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD0006057)   // VWADDU_WX        110100???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hF4002057)   // VWMACC_VV        111101???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hF4006057)   // VWMACC_VX        111101???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hFC002057)   // VWMACCSU_VV      111111???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hFC006057)   // VWMACCSU_VX      111111???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hF0002057)   // VWMACCU_VV       111100???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hF0006057)   // VWMACCU_VX       111100???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hF8006057)   // VWMACCUS_VX      111110???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hEC002057)   // VWMUL_VV         111011???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hEC006057)   // VWMUL_VX         111011???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hE8002057)   // VWMULSU_VV       111010???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hE8006057)   // VWMULSU_VX       111010???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hE0002057)   // VWMULU_VV        111000???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hE0006057)   // VWMULU_VX        111000???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hCC002057)   // VWSUB_VV         110011???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hCC006057)   // VWSUB_VX         110011???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hDC002057)   // VWSUB_WV         110111???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hDC006057)   // VWSUB_WX         110111???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hC8002057)   // VWSUBU_VV        110010???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hC8006057)   // VWSUBU_VX        110010???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD8002057)   // VWSUBU_WV        110110???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD8006057)   // VWSUBU_WX        110110???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hC0005057)   // VFWADD_VF        110000???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hC0001057)   // VFWADD_VV        110000???????????001?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD0005057)   // VFWADD_WF        110100???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD0001057)   // VFWADD_WV        110100???????????001?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hC8005057)   // VFWSUB_VF        110010???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hC8001057)   // VFWSUB_VV        110010???????????001?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD8005057)   // VFWSUB_WF        110110???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD8001057)   // VFWSUB_WV        110110???????????001?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hE0005057)   // VFWMUL_VF        111000???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hE0001057)   // VFWMUL_VV        111000???????????001?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hF0005057)   // VFWMACC_VF       111100???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hF0001057)   // VFWMACC_VV       111100???????????001?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hF8005057)   // VFWMSAC_VF       111110???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hF8001057)   // VFWMSAC_VV       111110???????????001?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hF4005057)   // VFWNMACC_VF      111101???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hF4001057)   // VFWNMACC_VV      111101???????????001?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hFC005057)   // VFWNMSAC_VF      111111???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hFC001057)   // VFWNMSAC_VV      111111???????????001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48061057)   // VFWCVT_F_F_V     010010??????01100001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48059057)   // VFWCVT_F_X_V     010010??????01011001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48051057)   // VFWCVT_F_XU_V    010010??????01010001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48079057)   // VFWCVT_RTZ_X_F_V 010010??????01111001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48071057)   // VFWCVT_RTZ_XU_F_V 010010??????01110001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48049057)   // VFWCVT_X_F_V     010010??????01001001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48041057)   // VFWCVT_XU_F_V    010010??????01000001?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD4000057)   // VWSLL_VV         110101???????????000?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD4004057)   // VWSLL_VX         110101???????????100?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD4003057);  // VWSLL_VI         110101???????????011?????1010111

  // vs2 已是宽操作数（.wv/.wx 形态）
  // Chisel: vs2WideningInst  （12 条指令）
  wire is_vs2_widening =
      bitpat_match(inst, 32'hFC00707F, 32'hD4002057)   // VWADD_WV         110101???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD4006057)   // VWADD_WX         110101???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD0002057)   // VWADDU_WV        110100???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD0006057)   // VWADDU_WX        110100???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hDC002057)   // VWSUB_WV         110111???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hDC006057)   // VWSUB_WX         110111???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD8002057)   // VWSUBU_WV        110110???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD8006057)   // VWSUBU_WX        110110???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD0005057)   // VFWADD_WF        110100???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD0001057)   // VFWADD_WV        110100???????????001?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD8005057)   // VFWSUB_WF        110110???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hD8001057);  // VFWSUB_WV        110110???????????001?????1010111

  // 收窄（vs2 EEW = 2×SEW，vd = SEW）
  // Chisel: narrowingInst  （20 条指令）
  wire is_narrowing =
      bitpat_match(inst, 32'hFC00707F, 32'hBC003057)   // VNCLIP_WI        101111???????????011?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hBC000057)   // VNCLIP_WV        101111???????????000?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hBC004057)   // VNCLIP_WX        101111???????????100?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hB8003057)   // VNCLIPU_WI       101110???????????011?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hB8000057)   // VNCLIPU_WV       101110???????????000?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hB8004057)   // VNCLIPU_WX       101110???????????100?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hB4003057)   // VNSRA_WI         101101???????????011?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hB4000057)   // VNSRA_WV         101101???????????000?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hB4004057)   // VNSRA_WX         101101???????????100?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hB0003057)   // VNSRL_WI         101100???????????011?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hB0000057)   // VNSRL_WV         101100???????????000?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hB0004057)   // VNSRL_WX         101100???????????100?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h480A1057)   // VFNCVT_F_F_W     010010??????10100001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48099057)   // VFNCVT_F_X_W     010010??????10011001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48091057)   // VFNCVT_F_XU_W    010010??????10010001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h480A9057)   // VFNCVT_ROD_F_F_W 010010??????10101001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h480B9057)   // VFNCVT_RTZ_X_F_W 010010??????10111001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h480B1057)   // VFNCVT_RTZ_XU_F_W 010010??????10110001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48089057)   // VFNCVT_X_F_W     010010??????10001001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48081057);  // VFNCVT_XU_F_W    010010??????10000001?????1010111

  // 整数扩展 vsext/vzext（vf2/vf4/vf8）
  // Chisel: intExtInst  （6 条指令）
  wire is_int_ext =
      bitpat_match(inst, 32'hFC0FF07F, 32'h4803A057)   // VSEXT_VF2        010010??????00111010?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h4802A057)   // VSEXT_VF4        010010??????00101010?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h4801A057)   // VSEXT_VF8        010010??????00011010?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48032057)   // VZEXT_VF2        010010??????00110010?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48022057)   // VZEXT_VF4        010010??????00100010?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48012057);  // VZEXT_VF8        010010??????00010010?????1010111

  // 进位/借位产生 vmadc/vmsbc（vd 是掩码）
  // Chisel: acsbInst  （10 条指令）
  wire is_acsb =
      bitpat_match(inst, 32'hFE00707F, 32'h46003057)   // VMADC_VI         0100011??????????011?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h44003057)   // VMADC_VIM        0100010??????????011?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h46000057)   // VMADC_VV         0100011??????????000?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h44000057)   // VMADC_VVM        0100010??????????000?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h46004057)   // VMADC_VX         0100011??????????100?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h44004057)   // VMADC_VXM        0100010??????????100?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h4E000057)   // VMSBC_VV         0100111??????????000?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h4C000057)   // VMSBC_VVM        0100110??????????000?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h4E004057)   // VMSBC_VX         0100111??????????100?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h4C004057);  // VMSBC_VXM        0100110??????????100?????1010111

  // 比较类（vd 是掩码）
  // Chisel: cmpInst  （30 条指令）
  wire is_cmp =
      bitpat_match(inst, 32'hFC00707F, 32'h60003057)   // VMSEQ_VI         011000???????????011?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h60000057)   // VMSEQ_VV         011000???????????000?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h60004057)   // VMSEQ_VX         011000???????????100?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h7C003057)   // VMSGT_VI         011111???????????011?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h7C004057)   // VMSGT_VX         011111???????????100?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h78003057)   // VMSGTU_VI        011110???????????011?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h78004057)   // VMSGTU_VX        011110???????????100?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h74003057)   // VMSLE_VI         011101???????????011?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h74000057)   // VMSLE_VV         011101???????????000?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h74004057)   // VMSLE_VX         011101???????????100?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h70003057)   // VMSLEU_VI        011100???????????011?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h70000057)   // VMSLEU_VV        011100???????????000?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h70004057)   // VMSLEU_VX        011100???????????100?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h6C000057)   // VMSLT_VV         011011???????????000?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h6C004057)   // VMSLT_VX         011011???????????100?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h68000057)   // VMSLTU_VV        011010???????????000?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h68004057)   // VMSLTU_VX        011010???????????100?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h64003057)   // VMSNE_VI         011001???????????011?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h64000057)   // VMSNE_VV         011001???????????000?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h64004057)   // VMSNE_VX         011001???????????100?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h60005057)   // VMFEQ_VF         011000???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h60001057)   // VMFEQ_VV         011000???????????001?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h70005057)   // VMFNE_VF         011100???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h70001057)   // VMFNE_VV         011100???????????001?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h7C005057)   // VMFGE_VF         011111???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h74005057)   // VMFGT_VF         011101???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h64005057)   // VMFLE_VF         011001???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h64001057)   // VMFLE_VV         011001???????????001?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h6C005057)   // VMFLT_VF         011011???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h6C001057);  // VMFLT_VV         011011???????????001?????1010111

  // 归约（vs1/vd 只用第 0 个元素）
  // Chisel: redInst  （12 条指令）
  wire is_red =
      bitpat_match(inst, 32'hFC00707F, 32'h04002057)   // VREDAND_VS       000001???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h1C002057)   // VREDMAX_VS       000111???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h18002057)   // VREDMAXU_VS      000110???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h14002057)   // VREDMIN_VS       000101???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h10002057)   // VREDMINU_VS      000100???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h08002057)   // VREDOR_VS        000010???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h00002057)   // VREDSUM_VS       000000???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h0C002057)   // VREDXOR_VS       000011???????????010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h1C001057)   // VFREDMAX_VS      000111???????????001?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h14001057)   // VFREDMIN_VS      000101???????????001?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h0C001057)   // VFREDOSUM_VS     000011???????????001?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h04001057);  // VFREDUSUM_VS     000001???????????001?????1010111

  // 加宽归约
  // Chisel: redWideningInst  （4 条指令）
  wire is_red_widening =
      bitpat_match(inst, 32'hFC00707F, 32'hC4000057)   // VWREDSUM_VS      110001???????????000?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hC0000057)   // VWREDSUMU_VS     110000???????????000?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hCC001057)   // VFWREDOSUM_VS    110011???????????001?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'hC4001057);  // VFWREDUSUM_VS    110001???????????001?????1010111

  // 掩码逻辑 vmand/vmor/…（vm 必须为 1）
  // Chisel: maskLogicalInst  （8 条指令）
  wire is_mask_logical =
      bitpat_match(inst, 32'hFE00707F, 32'h66002057)   // VMAND_MM         0110011??????????010?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h76002057)   // VMNAND_MM        0111011??????????010?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h62002057)   // VMANDN_MM        0110001??????????010?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h6E002057)   // VMXOR_MM         0110111??????????010?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h6A002057)   // VMOR_MM          0110101??????????010?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h7A002057)   // VMNOR_MM         0111101??????????010?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h72002057)   // VMORN_MM         0111001??????????010?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h7E002057);  // VMXNOR_MM        0111111??????????010?????1010111

  // 掩码算术（含掩码逻辑；vs1/vs2 按掩码看待）
  // Chisel: maskArithmeticInst  （5 条指令 + maskLogicalInst）
  wire is_mask_arith =
      bitpat_match(inst, 32'hFC0FF07F, 32'h40082057)   // VCPOP_M          010000??????10000010?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h4008A057)   // VFIRST_M         010000??????10001010?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h5000A057)   // VMSBF_M          010100??????00001010?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h5001A057)   // VMSIF_M          010100??????00011010?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h50012057)   // VMSOF_M          010100??????00010010?????1010111
    | is_mask_logical;                                 // （整类并入：maskLogicalInst）

  // viota/vid（vs2 按掩码看待）
  // Chisel: maskIndexInst  （2 条指令）
  wire is_mask_index =
      bitpat_match(inst, 32'hFC0FF07F, 32'h50082057)   // VIOTA_M          010100??????10000010?????1010111
    | bitpat_match(inst, 32'hFDFFF07F, 32'h5008A057);  // VID_V            010100?0000010001010?????1010111

  // 标量<->向量单元素搬运 vmv.x.s 等
  // Chisel: vmvSingleInst  （4 条指令）
  wire is_vmv_single =
      bitpat_match(inst, 32'hFE0FF07F, 32'h42002057)   // VMV_X_S          0100001?????00000010?????1010111
    | bitpat_match(inst, 32'hFFF0707F, 32'h42006057)   // VMV_S_X          010000100000?????110?????1010111
    | bitpat_match(inst, 32'hFE0FF07F, 32'h42001057)   // VFMV_F_S         0100001?????00000001?????1010111
    | bitpat_match(inst, 32'hFFF0707F, 32'h42005057);  // VFMV_S_F         010000100000?????101?????1010111

  // 整寄存器搬运 vmv<N>r.v
  // Chisel: vmvWholeInst  （4 条指令）
  wire is_vmv_whole =
      bitpat_match(inst, 32'hFE0FF07F, 32'h9E003057)   // VMV1R_V          1001111?????00000011?????1010111
    | bitpat_match(inst, 32'hFE0FF07F, 32'h9E00B057)   // VMV2R_V          1001111?????00001011?????1010111
    | bitpat_match(inst, 32'hFE0FF07F, 32'h9E01B057)   // VMV4R_V          1001111?????00011011?????1010111
    | bitpat_match(inst, 32'hFE0FF07F, 32'h9E03B057);  // VMV8R_V          1001111?????00111011?????1010111

  // vrgatherei16.vv（下标 EEW 固定 16）
  // Chisel: vrgather16  （1 条指令）
  wire is_vrgather16 =
      bitpat_match(inst, 32'hFC00707F, 32'h38000057);  // VRGATHEREI16_VV  001110???????????000?????1010111

  // vcompress.vm（vs1 按掩码看待）
  // Chisel: vcompress  （1 条指令）
  wire is_vcompress =
      bitpat_match(inst, 32'hFE00707F, 32'h5E002057);  // VCOMPRESS_VM     0101111??????????010?????1010111

  // vsext/vzext .vf2
  // Chisel: intExt2  （2 条指令）
  wire is_int_ext2 =
      bitpat_match(inst, 32'hFC0FF07F, 32'h4803A057)   // VSEXT_VF2        010010??????00111010?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48032057);  // VZEXT_VF2        010010??????00110010?????1010111

  // vsext/vzext .vf4
  // Chisel: intExt4  （2 条指令）
  wire is_int_ext4 =
      bitpat_match(inst, 32'hFC0FF07F, 32'h4802A057)   // VSEXT_VF4        010010??????00101010?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48022057);  // VZEXT_VF4        010010??????00100010?????1010111

  // vsext/vzext .vf8
  // Chisel: intExt8  （2 条指令）
  wire is_int_ext8 =
      bitpat_match(inst, 32'hFC0FF07F, 32'h4801A057)   // VSEXT_VF8        010010??????00011010?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48012057);  // VZEXT_VF8        010010??????00010010?????1010111

  // 不依赖 vtype 的指令（vset* 与整寄存器访存）
  // Chisel: notDependVtypeInst  （3 条指令 + lsWholeInst）
  wire is_not_depend_vtype =
      bitpat_match(inst, 32'h8000707F, 32'h00007057)   // VSETVLI          0????????????????111?????1010111
    | bitpat_match(inst, 32'hC000707F, 32'hC0007057)   // VSETIVLI         11???????????????111?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h80007057)   // VSETVL           1000000??????????111?????1010111
    | is_ls_whole;                                     // （整类并入：lsWholeInst）

  // 浮点整数互转的加宽/收窄（SEW=8 时仍合法）
  // Chisel: doubleFpInst  （6 条指令）
  wire is_double_fp =
      bitpat_match(inst, 32'hFC0FF07F, 32'h48059057)   // VFWCVT_F_X_V     010010??????01011001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48051057)   // VFWCVT_F_XU_V    010010??????01010001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h480B9057)   // VFNCVT_RTZ_X_F_W 010010??????10111001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h480B1057)   // VFNCVT_RTZ_XU_F_W 010010??????10110001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48089057)   // VFNCVT_X_F_W     010010??????10001001?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h48081057);  // VFNCVT_XU_F_W    010010??????10000001?????1010111

  // vmsbf/vmsif/vmsof —— 唯三不许与 v0 重叠的掩码结果
  // Chisel: mask_set_inst  （3 条指令）
  wire is_mask_set =
      bitpat_match(inst, 32'hFC0FF07F, 32'h5000A057)   // VMSBF_M          010100??????00001010?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h5001A057)   // VMSIF_M          010100??????00011010?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h50012057);  // VMSOF_M          010100??????00010010?????1010111

  // 源/目的绝不许重叠的指令清单
  // Chisel: no_overlap_list  （13 条指令）
  wire is_no_overlap_list =
      bitpat_match(inst, 32'hFC0FF07F, 32'h5000A057)   // VMSBF_M          010100??????00001010?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h5001A057)   // VMSIF_M          010100??????00011010?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h50012057)   // VMSOF_M          010100??????00010010?????1010111
    | bitpat_match(inst, 32'hFC0FF07F, 32'h50082057)   // VIOTA_M          010100??????10000010?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h38004057)   // VSLIDEUP_VX      001110???????????100?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h38003057)   // VSLIDEUP_VI      001110???????????011?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h38006057)   // VSLIDE1UP_VX     001110???????????110?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h38005057)   // VFSLIDE1UP_VF    001110???????????101?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h30000057)   // VRGATHER_VV      001100???????????000?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h38000057)   // VRGATHEREI16_VV  001110???????????000?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h30004057)   // VRGATHER_VX      001100???????????100?????1010111
    | bitpat_match(inst, 32'hFC00707F, 32'h30003057)   // VRGATHER_VI      001100???????????011?????1010111
    | bitpat_match(inst, 32'hFE00707F, 32'h5E002057);  // VCOMPRESS_VM     0101111??????????010?????1010111
  // END GENERATED

  // ---------------------------------------------------------------------------
  // §2 公共派生量
  // ---------------------------------------------------------------------------
  // 指令字里被本模块读到的域(XSInstBitFields)。全部列在一处,省得读者回头数位。
  wire [4:0] fld_vd    = inst[11:7];    // VD    目的向量寄存器号
  wire [4:0] fld_vs1   = inst[19:15];   // VS1   (也是 OPIVI 的 5 位立即数域)
  wire [4:0] fld_vs2   = inst[24:20];   // VS2
  wire       fld_vm    = inst[25];      // VM    0 = 带掩码执行
  wire [2:0] fld_nf    = inst[31:29];   // NF    段访存的 field 数减一
  wire [1:0] fld_width = inst[13:12];   // WIDTH(1,0) 访存 EEW 编码

  // SEW 直接就是 vtype.vsew。LMUL 的编码要把最高位取反才是「偏置 4 的量值」:
  // vlmul = 3'b000..011 → LMUL 1,2,4,8(编码 4..7);3'b101..111 → 1/8,1/4,1/2(编码 1..3)。
  wire [2:0] lmul = {~vlmul[2], vlmul[1:0]};

  // 下面这几个零扩展量对应 golden 的 _GEN_6/_GEN_7/_GEN_8 —— Chisel 的 `+&`
  // (位宽加一的加法)在 SV 里必须靠显式零扩展 + 足够宽的目标位宽来表达。
  wire [3:0] lmul_z4 = {1'b0, lmul};
  wire [2:0] sew_z3  = {1'b0, vsew};
  wire [3:0] sew_z4  = {2'b0, vsew};
  wire [2:0] sew_p1  = sew_z3 + 3'd1;      // SEW +& 1,3 位

  // 向量功能单元判别。FuType 是 one-hot:18..27 是向量算术类(vialuF/vimac/vfalu…),
  // 31..34 是向量访存类(vldu/vstu/vsegldu/vsegstu)。
  wire is_varith     = |fu_type[27:18];
  wire is_varith_mem = is_varith | (|fu_type[34:31]);

  // ---------------------------------------------------------------------------
  // §3 判据 1/2/3 —— 指令自身非法、vill、元素宽度(EEW)非法
  // ---------------------------------------------------------------------------
  // 1) 掩码逻辑指令(vmand/vmor/…)规定 vm 必须为 1。
  wire inst_illegal = is_mask_logical & ~fld_vm;

  // 2) vtype.vill 置位 ⇒ 除 vset*/整寄存器访存外的向量指令一律非法。
  wire vill_illegal = vtype_illegal & is_varith_mem & ~is_not_depend_vtype;

  // 3a) 浮点向量算术(funct3 = ?01 且 opcode = OP-V)在 SEW=8 下没有对应浮点格式,
  //     例外是整数<->浮点的加宽/收窄转换(doubleFpInst),它们的浮点侧是 2×SEW。
  wire is_fp_arith   = (inst[13:12] == 2'b01) & (inst[6:0] == 7'h57);
  wire fp_eew_ill    = is_fp_arith & (vsew == 2'd0) & ~is_double_fp;
  // 3b) vsext/vzext.vf2/vf4/vf8 把 SEW/2、SEW/4、SEW/8 的源扩成 SEW,源宽必须 ≥8。
  wire int_ext_eew_ill = (is_int_ext2 & (vsew == 2'd0))
                       | (is_int_ext4 & (vsew <= 2'd1))
                       | (is_int_ext8 & (vsew <= 2'd2));
  // 3c) 加宽/收窄/加宽归约的宽侧是 2×SEW,SEW=64 就超出 ELEN。
  wire wn_eew_ill    = (is_vd_widening | is_narrowing | is_red_widening) & (vsew == 2'd3);
  wire eew_illegal   = fp_eew_ill | int_ext_eew_ill | wn_eew_ill;

  // ---------------------------------------------------------------------------
  // §4 判据 4 —— 寄存器组倍数(EMUL)非法
  // ---------------------------------------------------------------------------
  // 4a) 访存的 EMUL = LMUL × EEW/SEW,合法范围 [1/8, 8],即编码 [SEW+1, SEW+7]。
  //     (这里 LMUL/EEW/SEW 都是「以 2 为底的对数 + 偏置」,所以乘除变成加减。)
  wire [3:0] ls_emul     = lmul_z4 + {2'b0, fld_width};       // LMUL +& WIDTH(1,0)
  wire       ls_emul_ill = (is_ls_stride | is_ls_index)
                         & ((ls_emul < {1'b0, sew_p1}) | (ls_emul > (sew_z4 + 4'd7)));

  // 4b) vsext/vzext:源 EMUL = LMUL/2、/4、/8,源 EMUL 不能掉到 1/8 以下。
  wire int_ext_emul_ill = (is_int_ext2 & (lmul == 3'd1))
                        | (is_int_ext4 & (lmul <= 3'd2))
                        | (is_int_ext8 & (lmul <= 3'd3));
  // 4c) 加宽/收窄的宽侧 EMUL = 2×LMUL,LMUL=8 就超了。
  wire wn_emul_ill      = (is_vd_widening | is_narrowing) & (lmul == 3'd7);
  // 4d) vrgatherei16:下标 EEW 固定 16,其 EMUL = LMUL×16/SEW 必须落在 [1/8,8]。
  wire gather16_emul_ill = is_vrgather16
                         & ((lmul < sew_z3) | (lmul_z4 > (sew_z4 + 4'd6)));

  // 4e) 段访存:nf+1 个 field,每个 field 占 2^emul 个寄存器。
  //     总寄存器数不得超过 8,且 vd + 总数不得跨过 v31。
  //     ★seg_emul 在 golden 里是 3 位★:Chisel 算出来是 4 位(`+&`),但只有 bit2 和
  //     bit[1:0] 被读,firtool 把第 4 位消掉了。这里照 golden 写 3 位 —— 写成 4 位
  //     值相同(高位无人读),但会在 FM 里多出一个不可比的内部点。
  wire [3:0] nfields    = {1'b0, fld_nf} + 4'd1;
  wire [2:0] seg_emul   = is_ls_index ? lmul : ((lmul + {1'b0, fld_width}) - sew_z3);
  wire [1:0] seg_pow    = seg_emul[2] ? seg_emul[1:0] : 2'd0;
  wire [6:0] seg_regnum = {3'b0, nfields} << seg_pow;
  wire [7:0] seg_regmax = {3'b0, fld_vd} + {1'b0, seg_regnum};
  wire       ls_seg_ill = (is_ls_stride | is_ls_index) & (|fld_nf)
                        & ((seg_regnum > 7'd8) | (seg_regmax > 8'd32));

  wire emul_illegal = ls_emul_ill | int_ext_emul_ill | wn_emul_ill
                    | gather16_emul_ill | ls_seg_ill;

  // ---------------------------------------------------------------------------
  // §5 判据 5 —— 寄存器号对齐
  // ---------------------------------------------------------------------------
  // 每个操作数先算出它自己的 EEW 与 EMUL,再看寄存器号是否按 EMUL 对齐。
  // 「按掩码看待」(EEW=1,EMUL=1)与「只用单个元素」(归约/vmv.x.s)的操作数固定
  // 占 1 个寄存器 → EMUL 编码 4,永远对齐。

  wire [3:0] lmul_p1 = lmul_z4 + 4'd1;   // LMUL +& 1(4 位),对应 golden 的 _vdEmul_T

  // --- vs1 ---
  wire       vs1_is_mask   = is_mask_arith | is_vcompress;
  wire       vs1_is_single = is_red | is_red_widening;
  wire [1:0] vs1_eew       = is_vrgather16 ? 2'd1 : vsew;   // gather 的下标 EEW=16
  wire [3:0] vs1_emul      = (vs1_is_mask | vs1_is_single) ? 4'd4
                           : is_vrgather16 ? (lmul_p1 - sew_z4)   // ★4 位,不截断★
                           : lmul_z4;
  wire       vs1_not_align = src_type_vs1[2] & reg_num_not_align(vs1_emul, fld_vs1[2:0]);

  // --- vs2 ---
  wire vs2_is_mask        = is_mask_arith | is_mask_index;
  wire vs2_is_single      = is_vmv_single;
  wire vs2_wide_or_narrow = is_vs2_widening | is_narrowing;

  // vs2 的 EEW 选择(one-hot 优先级链,与 golden 同序):索引访存看 WIDTH、
  // 宽源/收窄/加宽归约是 SEW+1、vf2/vf4/vf8 是 SEW-1/-2/-3。
  wire [4:0] vs2_eew_sel = {is_ls_index,
                            vs2_wide_or_narrow | is_red_widening,
                            is_int_ext2, is_int_ext4, is_int_ext8};
  wire [1:0] vs2_eew = (vs2_eew_sel == 5'h10) ? fld_width      :
                       (vs2_eew_sel == 5'h08) ? (vsew + 2'd1)  :
                       (vs2_eew_sel == 5'h04) ? (vsew - 2'd1)  :
                       (vs2_eew_sel == 5'h02) ? (vsew - 2'd2)  :
                       (vs2_eew_sel == 5'h01) ? (vsew - 2'd3)  : vsew;

  wire [3:0] vs2_emul_sel = {vs2_is_mask | vs2_is_single,
                             vs2_wide_or_narrow,
                             is_vmv_whole,
                             is_int_ext | is_ls_index};
  // ★位宽:sel==4'h4 这支是 Chisel 的 `LMUL + 1.U`(普通 `+`,结果 3 位),LMUL=7 时
  // 回绕成 0;而上面 vs1_emul 的 gather 支是 `+&`(4 位),LMUL=7 得 8。两种加法在同
  // 一份 Chisel 里相邻出现,照 golden 逐位抄。
  // ★但这两处的差别在输出上不可观测,别把它当成「这里很关键」★:
  //   - sel==4'h4 ⟺ vs2 宽源或收窄,而这两类指令**都在** vd 加宽/收窄清单里
  //     (vs2WideningInst ⊂ vdWideningInst),于是 LMUL=7 时 §4 的 wn_emul_ill
  //     已经把 emul_illegal 拉高,输出恒 1,vs2_emul 取 0 还是 8 都改不了结论。
  //   - vs1_emul 的 gather 支只有在 lmul_p1 < sew(即 LMUL < SEW)时才会借位到
  //     第 4 位,而那正是 §4 gather16_emul_ill 的 `lmul < sew` 条件,输出同样恒 1。
  // 负测 mutants.py 把这两条列为「预期抓不到」并要求**确实**抓不到 ——
  // 哪天抓到了,说明上面的论证被推翻,必须重新审。
  wire [3:0] vs2_emul = (vs2_emul_sel == 4'h8) ? 4'd4                          :
                        (vs2_emul_sel == 4'h4) ? {1'b0, lmul_p1[2:0]}          :
                        (vs2_emul_sel == 4'h2) ? {1'b0, nf_to_lmul(fld_vs1[2:0])} :
                        (vs2_emul_sel == 4'h1) ? ((lmul_z4 + {2'b0, vs2_eew}) - sew_z4) :
                                                 lmul_z4;
  wire vs2_not_align = src_type_vs2[2] & reg_num_not_align(vs2_emul, fld_vs2[2:0]);

  // --- vd ---
  wire       vd_is_mask   = is_ls_mask | is_acsb | is_cmp | is_mask_arith;
  wire       vd_is_single = is_red | is_red_widening | is_vmv_single;
  wire [1:0] vd_eew       = is_ls_stride ? fld_width
                          : (is_vd_widening | is_red_widening) ? (vsew + 2'd1) : vsew;
  wire [4:0] vd_emul_sel  = {vd_is_mask | vd_is_single,
                             is_vd_widening,
                             is_vmv_whole,
                             is_ls_whole,
                             is_ls_stride};
  wire [3:0] vd_emul = (vd_emul_sel == 5'h10) ? 4'd4                             :
                       (vd_emul_sel == 5'h08) ? {1'b0, lmul_p1[2:0]}             :
                       (vd_emul_sel == 5'h04) ? {1'b0, nf_to_lmul(fld_vs1[2:0])} :
                       (vd_emul_sel == 5'h02) ? {1'b0, nf_to_lmul(fld_nf)}       :
                       (vd_emul_sel == 5'h01) ? ((lmul_z4 + {2'b0, vd_eew}) - sew_z4) :
                                                lmul_z4;
  wire vd_not_align = (src_type_vd[2] | vec_wen) & reg_num_not_align(vd_emul, fld_vd[2:0]);

  wire reg_num_illegal = is_varith_mem & (vs1_not_align | vs2_not_align | vd_not_align);

  // ---------------------------------------------------------------------------
  // §6 判据 6 —— 寄存器重叠
  // ---------------------------------------------------------------------------
  // 6a) v0 重叠:带掩码执行(vm=0)时 vd 不能是 v0 —— 除非 vd 本身只占 1 个寄存器
  //     (掩码结果或单元素结果),那样写 v0 是允许的;但 vmsbf/vmsif/vmsof 三条
  //     即使结果是掩码也明令禁止与源掩码重叠,所以照样非法。
  wire v0_allow_overlap = (vd_is_mask | vd_is_single) & ~is_mask_set;
  wire v0_overlap = is_varith_mem & vec_wen & ~fld_vm & (fld_vd == 5'd0) & ~v0_allow_overlap;

  // 6b) vs1/vs2 与 vd 的寄存器区间重叠。先算各自占用的 [lo, hi] 区间。
  //     vd 的上界对访存走段访存算法(segRegMax-1),对算术走 vd + 2^EMUL - 1。
  wire [5:0] vs1_reg_lo = {1'b0, fld_vs1};
  wire [5:0] vs1_reg_hi = vs1_reg_lo + {2'b0, lmul_to_regnum(vs1_emul)} - 6'd1;
  wire [5:0] vs2_reg_lo = {1'b0, fld_vs2};
  wire [5:0] vs2_reg_hi = vs2_reg_lo + {2'b0, lmul_to_regnum(vs2_emul)} - 6'd1;
  wire [5:0] vd_reg_lo6 = {1'b0, fld_vd};
  // ★5 位截断★:Chisel 这里是普通 `+`(max(5,4)=5 位),vd=31、EMUL=8 会回绕。
  wire [4:0] vd_reg_hi_arith = fld_vd + {1'b0, lmul_to_regnum(vd_emul)} - 5'd1;
  wire [7:0] vd_reg_hi = (is_ls_stride | is_ls_index) ? (seg_regmax - 8'd1)
                                                     : {3'b0, vd_reg_hi_arith};

  // 「绝不许重叠」清单:段索引访存,以及 vmsbf/vmsif/vmsof/viota/vslideup/
  // vslide1up/vrgather/vcompress —— 这些指令的源在写 vd 之后还要继续读。
  wire not_allow_overlap = (is_ls_index & (|fld_nf)) | is_no_overlap_list;

  // 重叠但**允许**的三种情形(V 规范 5.2):EEW 相同、vd 窄于源且左对齐、
  // vd 宽于源且右对齐(后者还要求源 EMUL≥1);另外 vd 只用单元素时永远允许。
  wire vs1_vd_not_overlap = (vs1_reg_hi < vd_reg_lo6) | (vd_reg_hi < {2'b0, vs1_reg_lo});
  wire vs1_c1 = (vs1_is_mask & vd_is_mask)
              | (~vs1_is_mask & ~vd_is_mask & (vs1_eew == vd_eew));
  wire vs1_c2 = ((vd_is_mask & ~vs1_is_mask)
                 | (~vs1_is_mask & ~vd_is_mask & (vs1_eew > vd_eew)))
              & (fld_vd == fld_vs1) & (vd_reg_hi <= {2'b0, vs1_reg_hi});
  wire vs1_c3 = ((~vd_is_mask & vs1_is_mask)
                 | (~vs1_is_mask & ~vd_is_mask & (vs1_eew < vd_eew)))
              & (vs1_emul >= 4'd4) & (vd_reg_hi == {2'b0, vs1_reg_hi})
              & (fld_vd <= fld_vs1);
  wire vs1_allow_overlap = (vs1_c1 | vs1_c2 | vs1_c3 | vd_is_single) & ~not_allow_overlap;
  wire vs1_vd_overlap = (src_type_vs1[2] & vec_wen) & ~vs1_vd_not_overlap
                      & ~vs1_allow_overlap;

  wire vs2_vd_not_overlap = (vs2_reg_hi < vd_reg_lo6) | (vd_reg_hi < {2'b0, vs2_reg_lo});
  wire vs2_c1 = (vs2_is_mask & vd_is_mask)
              | (~vs2_is_mask & ~vd_is_mask & (vs2_eew == vd_eew));
  wire vs2_c2 = ((vd_is_mask & ~vs2_is_mask)
                 | (~vs2_is_mask & ~vd_is_mask & (vs2_eew > vd_eew)))
              & (fld_vd == fld_vs2) & (vd_reg_hi <= {2'b0, vs2_reg_hi});
  wire vs2_c3 = ((~vd_is_mask & vs2_is_mask)
                 | (~vs2_is_mask & ~vd_is_mask & (vs2_eew < vd_eew)))
              & (vs2_emul >= 4'd4) & (vd_reg_hi == {2'b0, vs2_reg_hi})
              & (fld_vd <= fld_vs2);
  wire vs2_allow_overlap = (vs2_c1 | vs2_c2 | vs2_c3 | vd_is_single) & ~not_allow_overlap;
  wire vs2_vd_overlap = (src_type_vs2[2] & vec_wen) & ~vs2_vd_not_overlap
                      & ~vs2_allow_overlap;

  wire reg_overlap_illegal = v0_overlap | vs1_vd_overlap | vs2_vd_overlap;

  // ---------------------------------------------------------------------------
  // §7 判据 7 与总输出
  // ---------------------------------------------------------------------------
  // 向量**算术**类不接受 vstart≠0(香山后端不支持从中间元素恢复算术指令);
  // 访存类可以,所以这里用 is_varith 而不是 is_varith_mem。
  wire vstart_illegal = is_varith & (|vstart);

  assign illegal_inst = inst_illegal | vill_illegal | eew_illegal | emul_illegal
                      | reg_num_illegal | reg_overlap_illegal | vstart_illegal;

endmodule : xs_VecExceptionGen_core


// =============================================================================
// VecExceptionGen —— golden 同名 wrapper（端口与 G1 golden 逐位同名同序）
// =============================================================================
module VecExceptionGen(
  input  [31:0] io_inst,
  input  [3:0]  io_decodedInst_srcType_0,
  input  [3:0]  io_decodedInst_srcType_1,
  input  [3:0]  io_decodedInst_srcType_2,
  input  [34:0] io_decodedInst_fuType,
  input         io_decodedInst_vecWen,
  input         io_vtype_illegal,
  input  [1:0]  io_vtype_vsew,
  input  [2:0]  io_vtype_vlmul,
  input  [7:0]  io_vstart,
  output        io_illegalInst
);

  xs_VecExceptionGen_core u_core (
    .inst          (io_inst),
    .src_type_vs1  (io_decodedInst_srcType_0),
    .src_type_vs2  (io_decodedInst_srcType_1),
    .src_type_vd   (io_decodedInst_srcType_2),
    .fu_type       (io_decodedInst_fuType),
    .vec_wen       (io_decodedInst_vecWen),
    .vtype_illegal (io_vtype_illegal),
    .vsew          (io_vtype_vsew),
    .vlmul         (io_vtype_vlmul),
    .vstart        (io_vstart),
    .illegal_inst  (io_illegalInst)
  );

endmodule : VecExceptionGen
