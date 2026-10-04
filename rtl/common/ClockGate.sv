// ClockGate.sv —— 锁存器型时钟门控单元（ICG，integrated clock gating）的行为模型
//
// ★这是工艺无关、可综合的 ICG 行为模型★：仿真、lint 与通用综合直接用它；
// ASIC 流程可在约束或 tech mapping 阶段把它换成工艺库的 ICG 标准单元
// （典型名如 CKLNQD* / ICGx* / TLATNTSCA*）。库单元与本模型端口语义一一对应：
//   CK = 被门控的时钟，E = 功能使能，TE = 测试使能（DFT 扫描时强制开门），Q = 门控后时钟。
//
// 来源：utility/ClockGate.scala —— 一个 BlackBox + 内联 SV，香山各处
// （MbistClockGateCell 的 SRAM 读时钟、L2 数据阵列 bank 时钟等）都经它门控时钟。
//
// 机制（经典"低电平透明锁存器 + 与门"结构）：
//   * CK=0（低相）：锁存器透明，enableLatched 跟随 TE | E —— 使能在这半周期内建立；
//   * CK=1（高相）：锁存器关闭，保持低相最后的值 —— 高相期间 E/TE 再怎么翻转都不会传到 Q；
//   * Q = CK & enableLatched：只有在"上一个低相末尾使能为 1"时，本个高相脉冲才完整放过去。
// 为什么必须是锁存器而不是直接 CK & E：E 由 CK 上升沿驱动的触发器产生，若直接相与，
// E 在高相中途变化会切出毛刺/半脉冲；锁存器把 E 的采样点钉在上升沿之前。
//
// 边界与怪癖（bug-for-bug 对齐 golden，不做任何"改进"）：
//   * 无复位、无初值：上电后第一个低相到来之前 enableLatched 是未知态，与库 ICG 一致；
//   * 锁存器内用阻塞赋值，与 golden / Scala 内联源的事件语义保持一致；
//   * 端口名、方向、位宽与 golden ClockGate 完全相同（全部 1 位）。

module ClockGate (
  input  logic TE,
  input  logic E,
  input  logic CK,
  output logic Q
);

  logic enableLatched;   // 低相锁存的门控使能

  // 低相透明锁存：CK=0 时跟随 TE | E，CK=1 时保持
  always_latch begin
    if (!CK) enableLatched = TE | E;
  end

  // 只在锁存使能为 1 时放过 CK 的高相
  assign Q = CK & enableLatched;

endmodule
