// =============================================================================
// fpdecoder_pkg —— 香山 V2R2(昆明湖) 浮点指令译码器 FPDecoder 的类型/常量定义
// -----------------------------------------------------------------------------
// 对应 Scala 源:xiangshan.backend.decode.FPDecoder。
//
// FPDecoder 是后端译码阶段的一个**纯组合叶子**:输入 32 位指令编码,输出浮点
// 控制信号 FPUCtrlSignals 的若干字段,供浮点执行单元(FAlu/FMA/FCVT/FDiv…)
// 与浮点->向量适配通道使用。它只关心 RV F/D/Zfh(以及标量 cvt/move)这一族
// OP-FP(opcode 1010011)与 FMADD 系列(opcode 1000x11)指令。
//
// 设计意图(来自 Scala):
//   - 用一张 (指令 BitPat -> 9 位控制位) 的真值表(single/double/half 三段)做译码,
//     交给 rocket-chip 的 DecodeLogic 最小化。9 个控制位含义(顺序见 Scala 注释):
//       isAddSub tagIn tagOut fromInt wflags fpWen div sqrt fcvt
//   - 但 **真正输出到端口的只有两位来自这张表**:typeTagOut(=表第2位)与
//     wflags(=表第4位)。其余控制位在该模块未驱动任何输出端口(它们在更大的
//     译码流程别处使用),故 golden 顶层只剩 5 个输出。
//   - 另外三个输出**直接由指令字段/指令类别算出**,不走真值表:
//       typ = inst[21:20]          (FCVT 的整数宽度/符号类型选择)
//       rm  = inst[14:12]          (静态 rounding mode 字段)
//       fmt = 浮点宽度(VSew 编码): FP32->e32, FP16->e16, 其余(含 FP64)->e64
//
// 本包给出:
//   - 输出 FPUCtrlSignals 的 packed struct(把 golden 的 5 个扁平端口聚合);
//   - typeTag / VSew 的有意义枚举;
//   - RISC-V 指令编码所需的字段切片常量(opcode/funct7/funct3/rs2 等)。
// =============================================================================
package fpdecoder_pkg;

  // ---------------------------------------------------------------------------
  // 浮点类型标记 typeTag(FPU.S/D/H 的低 2 位编码)。
  // Scala: FPU.S=0, FPU.D=1(代码里 i 也映射到 D=1), FPU.H=2。
  // typeTagOut 表示"结果"的浮点类型(对 FPToInt 类指令则是整数侧 i=D=1)。
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
    TAG_S = 2'd0, // 单精度 float32
    TAG_D = 2'd1, // 双精度 float64(也用于"整数侧" i 的占位)
    TAG_H = 2'd2  // 半精度 float16
  } fp_tag_e;

  // ---------------------------------------------------------------------------
  // fmt 输出沿用向量 VSew(2bit)编码,表达该浮点指令的元素宽度。
  // 注意这里只用到 e16/e32/e64 三档(e8 在浮点无意义)。
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
    SEW_E8  = 2'b00,
    SEW_E16 = 2'b01, // FP16
    SEW_E32 = 2'b10, // FP32
    SEW_E64 = 2'b11  // FP64(默认)
  } vsew_e;

  // ---------------------------------------------------------------------------
  // 输出聚合:FPUCtrlSignals 在本模块实际驱动的 5 个字段。
  // (Scala 的 FPUCtrlSignals 更宽,但 FPDecoder 只赋这几个 + 默认 0,
  //   firtool 把未驱动/未使用的端口裁掉了,故 golden 顶层就是这 5 个。)
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [1:0] typeTagOut; // 结果浮点类型标记(真值表第 2 位)
    logic       wflags;     // 是否会写 fflags 浮点异常标志(真值表第 4 位)
    logic [1:0] typ;        // = inst[21:20]
    logic [1:0] fmt;        // 浮点宽度(VSew 编码)
    logic [2:0] rm;         // = inst[14:12] 静态舍入模式
  } fp_ctrl_t;

endpackage
