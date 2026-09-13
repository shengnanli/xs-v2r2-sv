// =============================================================================
// xs_DelayNWithValid_core —— 带 valid 使能的两级打拍链（DelayNWithValid 家族的核）
//
// 对应 Chisel: utility.DelayNWithValid(in, valid, n=2)。与 xs_DelayN_core 的区别：
// 数据级不是无条件移位，而是**只在 valid 时才更新**——相当于两级"带保持的锁存"，
// 中间没人写就一直保住上一次的值。香山 FTB 用它把预测项（FTBEntry / 目标地址）
// 沿预测流水多打两拍，同时避免无效拍把上一次的有效值冲掉。
//
// 三个寄存器（名字沿用 golden）：
//   valid_q    io_in_valid 打一拍，**异步高有效复位到 0**（唯一带复位的寄存器）；
//   data_q     第一级数据，io_in_valid 时更新，无复位；
//   res_q      第二级数据，valid_q（= 上一拍的 in_valid）时更新，无复位，就是输出。
// 于是一次有效输入要走两拍才出现在 io_out_bits 上；输入无效时输出保持不变。
// 没有输出 valid 端口 —— 上层自己知道什么时候该看。
//
// 为什么整个家族只需要这一个核：golden 里的变体只差**载荷位宽**，
// 时序结构逐字相同。这里把载荷压成一根扁平向量，位宽进参数。
//
// elaborate 期不变式（见下面 initial）：
//   WIDTH * 2 == GOLDEN_DATA_REG_BITS —— 后者是从 golden 数出来的两级数据寄存器
//   位数总和（不含 1 位 valid_q）；PORT_BITS_IN/OUT 由薄文件用 $bits(golden 端口
//   拼接) 传进来，必须都等于 WIDTH。任何端口位宽抄错 time 0 就 $fatal。
// =============================================================================
module xs_DelayNWithValid_core #(
  parameter int unsigned WIDTH               = 1,          // 载荷位宽
  parameter int unsigned GOLDEN_DATA_REG_BITS = 2 * WIDTH,  // golden 两级数据 reg 位数总和
  parameter int unsigned PORT_BITS_IN        = WIDTH,      // = $bits({golden io_in_bits_*})
  parameter int unsigned PORT_BITS_OUT       = WIDTH       // = $bits({golden io_out_bits_*})
)(
  input  logic             clock,
  input  logic             reset,   // 异步高有效，只作用于 valid_q（照搬 golden）
  input  logic             in_valid,
  input  logic [WIDTH-1:0] d_in,
  output logic [WIDTH-1:0] d_out
);

  localparam int unsigned STAGES = 2;   // golden 家族里 n 恒为 2

  initial begin
    if (WIDTH == 0)
      $fatal(1, "xs_DelayNWithValid_core: WIDTH=0 不合法");
    if (STAGES * WIDTH != GOLDEN_DATA_REG_BITS)
      $fatal(1, "xs_DelayNWithValid_core: %0d 级 × WIDTH=%0d = %0d != golden 数据 reg 位数 %0d（位宽抄错）",
             STAGES, WIDTH, STAGES * WIDTH, GOLDEN_DATA_REG_BITS);
    if (PORT_BITS_IN != WIDTH)
      $fatal(1, "xs_DelayNWithValid_core: golden io_in_bits_* 共 %0d 位 != WIDTH=%0d（端口位宽抄错）",
             PORT_BITS_IN, WIDTH);
    if (PORT_BITS_OUT != WIDTH)
      $fatal(1, "xs_DelayNWithValid_core: golden io_out_bits_* 共 %0d 位 != WIDTH=%0d（端口位宽抄错）",
             PORT_BITS_OUT, WIDTH);
  end

  logic             valid_q;
  logic [WIDTH-1:0] data_q;
  logic [WIDTH-1:0] res_q;

  // 只有这一个寄存器带复位（异步高有效）；两级数据寄存器无复位，上电为 X，
  // 要等各自的使能拉过一次才有定值 —— 与 golden 逐字一致。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) valid_q <= 1'b0;
    else       valid_q <= in_valid;
  end

  always_ff @(posedge clock) begin
    if (in_valid) data_q <= d_in;     // 第一级：本拍有效就收
    if (valid_q)  res_q  <= data_q;   // 第二级：上一拍有效就把第一级搬过来
  end

  assign d_out = res_q;

endmodule
