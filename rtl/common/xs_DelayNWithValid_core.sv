// =============================================================================
// xs_DelayNWithValid_core —— 带 valid 使能的 N 级打拍链（DelayNWithValid 家族的核）
//
// 对应 Chisel: utility.DelayNWithValid(in, valid, n)。与 xs_DelayN_core 的区别：
// 数据级不是无条件移位，而是**只在本级的使能拉高时才更新**——相当于 n 级"带保持
// 的锁存"，中间没人写就一直保住上一次的值。香山用它把 FTB 预测项、TLB/PTW 请求、
// 各种 bits+valid 的小包沿流水多打几拍，同时避免无效拍把上一次的有效值冲掉。
//
// 两条链：
//   valid 链  v[0] <= in_valid，v[k] <= v[k-1]；**异步高有效复位到 0**。
//             它既是数据级的使能，也是（若 golden 有 io_out_valid 端口时）输出的
//             有效标志。
//   数据链    data[0] 在 in_valid 时收 d_in，data[k] 在 v[k-1] 时收 data[k-1]；
//             **无复位**，上电为 X，要等各自的使能拉过一次才有定值。
// 于是一次有效输入要走 STAGES 拍才出现在 d_out 上。
//
// ★VALID_CHAIN 为什么是独立参数而不是 STAGES-1★
// firtool 只保留被读到的寄存器。valid 链的最后一级只有在 golden **有 io_out_valid
// 端口**时才有人读；没有这个端口时它被整个消掉，于是同样是 n 级的两个变体，
// 一个有 STAGES 个 valid 寄存器、一个只有 STAGES-1 个。n=1 且无 out_valid 时
// （DelayNWithValid_52/_55/_103/_152/_155）valid 链全部消光，连 reset 端口都没有。
// 这是 golden 的真实形态，**不是不对称需要补齐**——照抄。
//   VALID_CHAIN = 0        当 STAGES == 0
//   VALID_CHAIN = STAGES   当 golden 有 io_out_valid
//   VALID_CHAIN = STAGES-1 当没有
// 这条公式对家族 16 个变体逐个成立，并且整段模块体都能由它重建出来
// （verif/ut/DelayNWithValid/gen_facts.py 的 rebuild()，16/16 逐字一致）。
//
// elaborate 期不变式（见下面 initial）：
//   VALID_CHAIN + STAGES * WIDTH == GOLDEN_REG_BITS —— 右边是从 golden 数出来的
//   reg 位数总和。级数、载荷位宽、valid 链长任何一个抄错，等式立刻不成立。
//   PORT_BITS_IN / PORT_BITS_OUT 由薄文件用 $bits(golden 端口拼接) 传进来，
//   必须都等于 WIDTH：任何一个端口位宽抄错，拼接总位数就变，time 0 直接 $fatal。
// =============================================================================
module xs_DelayNWithValid_core #(
  parameter int unsigned WIDTH           = 1,   // 载荷位宽（打平后的总位数）
  parameter int unsigned STAGES          = 2,   // 数据级数 n
  parameter int unsigned VALID_CHAIN     = 1,   // 保留下来的 valid 寄存器个数
  parameter int unsigned GOLDEN_REG_BITS = VALID_CHAIN + STAGES * WIDTH,
  parameter int unsigned PORT_BITS_IN    = WIDTH,   // = $bits({golden io_in_bits_*})
  parameter int unsigned PORT_BITS_OUT   = WIDTH    // = $bits({golden io_out_bits_*})
)(
  input  logic             clock,     // STAGES==0 时不被使用（golden 也没有这个口）
  input  logic             reset,     // 异步高有效，只作用于 valid 链（照搬 golden）
  input  logic             in_valid,
  input  logic [WIDTH-1:0] d_in,
  output logic [WIDTH-1:0] d_out,
  output logic             out_valid  // 仅 VALID_CHAIN == STAGES 时有意义
);

  initial begin
    if (WIDTH == 0)
      $fatal(1, "xs_DelayNWithValid_core: WIDTH=0 不合法");
    if (VALID_CHAIN > STAGES)
      $fatal(1, "xs_DelayNWithValid_core: VALID_CHAIN=%0d > STAGES=%0d —— valid 链不可能比数据链长",
             VALID_CHAIN, STAGES);
    if (STAGES > 0 && VALID_CHAIN < STAGES - 1)
      $fatal(1, "xs_DelayNWithValid_core: VALID_CHAIN=%0d 少于 STAGES-1=%0d —— 数据级的使能就没来源了",
             VALID_CHAIN, STAGES - 1);
    if (VALID_CHAIN + STAGES * WIDTH != GOLDEN_REG_BITS)
      $fatal(1, "xs_DelayNWithValid_core: valid %0d + %0d 级 × %0d 位 = %0d != golden reg 位数 %0d（参数抄错）",
             VALID_CHAIN, STAGES, WIDTH, VALID_CHAIN + STAGES * WIDTH, GOLDEN_REG_BITS);
    if (PORT_BITS_IN != WIDTH)
      $fatal(1, "xs_DelayNWithValid_core: golden io_in_bits_* 共 %0d 位 != WIDTH=%0d（端口位宽抄错）",
             PORT_BITS_IN, WIDTH);
    if (PORT_BITS_OUT != WIDTH)
      $fatal(1, "xs_DelayNWithValid_core: golden io_out_bits_* 共 %0d 位 != WIDTH=%0d（端口位宽抄错）",
             PORT_BITS_OUT, WIDTH);
  end

  generate
    if (STAGES == 0) begin : g_bypass
      // n=0 的退化情形（DelayNWithValid_4 / _7）：一根线直通，没有寄存器、没有时钟，
      // golden 连 io_in_valid 端口都没有。
      assign d_out     = d_in;
      assign out_valid = in_valid;
    end else begin : g_chain
      // valid 链。长度 0 时（n=1 且无 out_valid）这里一个寄存器都不生成，
      // 数据级第 0 级的使能直接用 in_valid，正好不需要任何 valid 寄存器。
      logic [VALID_CHAIN:0] valid_q;   // valid_q[0] 是 in_valid 本身，[1..] 才是寄存器

      assign valid_q[0] = in_valid;

      if (VALID_CHAIN > 0) begin : g_valid
        logic [VALID_CHAIN-1:0] valid_reg;
        always_ff @(posedge clock or posedge reset) begin
          if (reset)
            valid_reg <= '0;
          else begin
            valid_reg[0] <= in_valid;
            for (int unsigned v = 1; v < VALID_CHAIN; v++)
              valid_reg[v] <= valid_reg[v-1];
          end
        end
        assign valid_q[VALID_CHAIN:1] = valid_reg;
      end

      // 数据链。第 s 级的使能 = valid_q[s]，即「s 拍以前的 in_valid」：
      // s=0 用 in_valid 本身，s>=1 用 valid 链的第 s 个。无复位。
      logic [WIDTH-1:0] data_q [STAGES];

      always_ff @(posedge clock) begin
        if (valid_q[0]) data_q[0] <= d_in;
        for (int unsigned s = 1; s < STAGES; s++)
          if (valid_q[s]) data_q[s] <= data_q[s-1];
      end

      assign d_out     = data_q[STAGES-1];
      assign out_valid = valid_q[VALID_CHAIN];
    end
  endgenerate

endmodule
