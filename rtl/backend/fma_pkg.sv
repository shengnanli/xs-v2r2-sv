// =============================================================================
//  fma_pkg —— 浮点乘加功能单元 FMA 的类型 / 常量 / 纯函数
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/backend/fu/wrapper/FMA.scala
//                （class FMA extends FpPipedFuncUnit, latency=3）
//
//  FMA 是浮点乘加 FU：fmadd / fmsub / fnmadd / fnmsub / fmul 等（三源 a*b±c）。
//  真正的乘加阵列在黑盒 FloatFMA（内部 3 拍流水）里；本 wrapper 层只做：
//    1) rm 选择、fp_fmt 透传（同 FAlu）；
//    2) 三源各自的规范 NaN 检测——其中 c 源的检测要额外乘上「非纯乘 vfmul」条件
//       （纯乘 fmul 不读 c，故不对 c 做 box 检测）；
//    3) op_code = fuOpType[3:0] 透传；
//    4) 3 拍定长流水的 valid/perf 打拍 + 输出控制透传。
// =============================================================================
package fma_pkg;

  localparam int XLEN = 64;

  // 浮点格式（同 FAlu，VSew 编码）
  typedef enum logic [1:0] {
    FMT_E8  = 2'b00,
    FMT_E16 = 2'b01,   // f16
    FMT_E32 = 2'b10,   // f32
    FMT_E64 = 2'b11    // f64
  } fp_fmt_e;

  // vfmul（纯乘）的 4bit opcode 编码：VfmaType.vfmul = 4'b0000。
  //  c 源是否参与（是否需要对 c 做 NaN-box 检测）由「opcode 非 0」判定。
  localparam logic [3:0] FMA_VFMUL = 4'b0000;

  // rm：指令 rm==7(动态) → CSR frm；否则指令 rm（同 FAlu）。
  function automatic logic [2:0] selRoundMode(input logic [2:0] inst_rm,
                                              input logic [2:0] csr_frm);
    selRoundMode = (inst_rm != 3'b111) ? inst_rm : csr_frm;
  endfunction

  // NaN-boxing 校验：窄浮点高位非全 1 → 规范 NaN（同 FAlu）。
  function automatic logic isFpCanonicalNAN(input fp_fmt_e fmt,
                                            input logic [XLEN-1:0] src);
    logic e32_bad, e16_bad;
    e32_bad = (fmt == FMT_E32) && (src[63:32] != 32'hFFFFFFFF);
    e16_bad = (fmt == FMT_E16) && (src[63:16] != 48'hFFFFFFFFFFFF);
    isFpCanonicalNAN = e32_bad | e16_bad;
  endfunction

  // c 源是否为纯乘（vfmul）——纯乘不读 c，对应 opcode[3:0]==0。
  function automatic logic isVfmul(input logic [3:0] opcode);
    isVfmul = (opcode == FMA_VFMUL);
  endfunction

endpackage
