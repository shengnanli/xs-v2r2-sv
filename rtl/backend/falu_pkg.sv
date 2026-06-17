// =============================================================================
//  falu_pkg —— 浮点加法/比较功能单元 FAlu 的类型 / 常量 / 纯函数
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/backend/fu/wrapper/FALU.scala
//                （class FAlu extends FpPipedFuncUnit, latency=1）
//                + src/main/scala/xiangshan/backend/fu/fpu/FpPipedFuncUnit.scala
//                  (trait FpFuncUnitAlias：rm / fp_fmt 的来源)
//
//  FAlu 是后端浮点执行簇里的「浮点加法 / 减法 / 比较 / 符号注入 / 分类 / 选最值」FU。
//  真正的浮点加法器在黑盒 FloatAdder（内部分 F64 / F32-F16 两条流水）里；本 wrapper 层只做：
//    1) 圆整模式选择 rm：指令携带的 rm（inst.rm）若为 7(动态)则改用 CSR 的 frm；
//    2) 浮点格式 fp_fmt 透传（e16/e32/e64，box 检查用）；
//    3) 规范 NaN 检测 fp_aIsFpCanonicalNAN / fp_bIsFpCanonicalNAN：
//       对窄于 64bit 的浮点数，高位若不是全 1（未正确 NaN-box），则视作规范 NaN；
//    4) op_code = fuOpType[4:0] 透传给加法器；
//    5) 1 拍定长流水的 valid / perf 打拍 + 输出控制透传（HasPipelineReg 模型）。
//
//  本包把 golden 里散落的 fmt 比较、box 检测、rm 选择收敛成有意义的 enum + 纯函数。
// =============================================================================
package falu_pkg;

  localparam int XLEN = 64;

  // ---------------------------------------------------------------------------
  //  浮点格式 fp_fmt / sew（VSew 编码，2bit）
  // ---------------------------------------------------------------------------
  //  香山用向量元素宽度 VSew 复用为标量浮点格式：
  //    e8=00 / e16=01(半精度 f16) / e32=10(单精度 f32) / e64=11(双精度 f64)
  typedef enum logic [1:0] {
    FMT_E8  = 2'b00,
    FMT_E16 = 2'b01,   // f16
    FMT_E32 = 2'b10,   // f32
    FMT_E64 = 2'b11    // f64
  } fp_fmt_e;

  // ---------------------------------------------------------------------------
  //  圆整模式选择（FpFuncUnitAlias.rm）
  // ---------------------------------------------------------------------------
  //  指令字段 instRm==3'b111 表示「动态圆整」，此时改用 CSR fcsr.frm；否则用指令自带 rm。
  function automatic logic [2:0] selRoundMode(input logic [2:0] inst_rm,
                                              input logic [2:0] csr_frm);
    selRoundMode = (inst_rm != 3'b111) ? inst_rm : csr_frm;
  endfunction

  // ---------------------------------------------------------------------------
  //  规范 NaN（canonical NaN）检测 —— NaN-boxing 校验
  // ---------------------------------------------------------------------------
  //  RV 把窄浮点数装进 64bit 寄存器时要求高位全 1（NaN-boxing）。若实际高位不是全 1，
  //  说明这不是一个合法 box 过的窄浮点，按规范 NaN 处理：
  //    · f32(e32)：检查 src[63:32] 是否 != 全 1；
  //    · f16(e16)：检查 src[63:16] 是否 != 全 1；
  //    · f64(e64)：占满 64bit，无需检测（返回 0）。
  function automatic logic isFpCanonicalNAN(input fp_fmt_e fmt,
                                            input logic [XLEN-1:0] src);
    logic e32_bad, e16_bad;
    e32_bad = (fmt == FMT_E32) && (src[63:32] != 32'hFFFFFFFF);
    e16_bad = (fmt == FMT_E16) && (src[63:16] != 48'hFFFFFFFFFFFF);
    isFpCanonicalNAN = e32_bad | e16_bad;
  endfunction

endpackage
