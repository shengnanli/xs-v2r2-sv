// =============================================================================
//  divunit_pkg —— 整数除法功能单元 DivUnit 的类型 / 常量 / 纯函数
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/backend/fu/wrapper/DivUnit.scala
//                + src/main/scala/xiangshan/package.scala (object DIVOpType)
//                + RobPtr.needFlush (src/.../backend/rob/RobBundles.scala)
//
//  DivUnit 是一个多周期、可迭代（非定长流水）的整数除法 FU 包装层。它例化 golden
//  黑盒迭代除法阵列 SRT16DividerDataModule（基-16 SRT 除法），自身只做：
//    1) 由 fuOpType 译出 {isW,isHi,sign}（字操作 / 取余 / 有无符号）；
//    2) 对两源做“字操作时的 32→64 符号或零扩展”（符号处理）；
//    3) 在 in.fire 时锁存 robIdx 与 ctrl，供迭代期间的冲刷判定与输出控制透传；
//    4) 计算 kill_w（请求拍冲刷）/ kill_r（迭代中冲刷）并送给阵列。
//
//  本包把 golden 里散落的位选择与 RobPtr.needFlush 展平表达，收敛成 enum + 纯函数。
// =============================================================================
package divunit_pkg;

  localparam int XLEN = 64;        // 目的数据位宽（RV64 → 64）

  // ---------------------------------------------------------------------------
  //  除法子操作（DIVOpType 的低 5bit 编码，便于阅读者对照指令）
  // ---------------------------------------------------------------------------
  //  fuOpType 编码：| type(2) | isWord(1)=bit2 | isSign(1)=bit1 | opcode(1)=bit0 |
  //  高 2bit type 恒为 10（除法类）。与 Mul 不同，除法不按子操作做多路选择，而是把
  //  这 5bit 直接拆成 isW/sign/isHi 三个正交控制位（见下 decodeDivCtrl）；本枚举仅
  //  作为“编码字典”帮助阅读，不参与数据通路选择。
  typedef enum logic [4:0] {
    DIV_DIV   = 5'b10000,  // 有符号除法，商
    DIV_REM   = 5'b10001,  // 有符号除法，余数
    DIV_DIVU  = 5'b10010,  // 无符号除法，商
    DIV_REMU  = 5'b10011,  // 无符号除法，余数
    DIV_DIVW  = 5'b10100,  // 有符号字除法，商（32bit）
    DIV_REMW  = 5'b10101,  // 有符号字除法，余数
    DIV_DIVUW = 5'b10110,  // 无符号字除法，商
    DIV_REMUW = 5'b10111   // 无符号字除法，余数
  } div_op_e;

  // ---------------------------------------------------------------------------
  //  除法控制信号（MulDivCtrl 的精简：DivUnit 只用 isW / isHi / sign）
  // ---------------------------------------------------------------------------
  //  从 fuOpType 的 3 个位直接译出三正交控制：
  //    isW   = func[2]    字操作（divw/divuw/remw/remuw）：源/结果按 32bit 处理
  //    sign  = !func[1]   有符号（div/rem/divw/remw）；无符号则用零扩展
  //    isHi  = func[0]    取余（rem/remu/...）→ 取除法器的余数输出
  typedef struct packed {
    logic isW;
    logic isHi;
    logic sign;
  } div_ctrl_t;

  function automatic div_ctrl_t decodeDivCtrl(input logic [8:0] func);
    div_ctrl_t c;
    c.isW   = func[2];        // DIVOpType.isW
    c.isHi  = func[0];        // DIVOpType.isH
    c.sign  = ~func[1];       // DIVOpType.isSign = !op(1)
    return c;
  endfunction

  // ---------------------------------------------------------------------------
  //  源操作数字操作扩展（符号处理）
  // ---------------------------------------------------------------------------
  //  非字操作：原样 64bit 送入除法器。
  //  字操作  ：只取低 32bit，按 sign 决定符号/零扩展回 64bit
  //            （有符号 divw/remw 用符号扩展，无符号 divuw/remuw 用零扩展）。
  //  golden 把高 32bit 写成 {32{ sign & x[31] }}：sign=0 时恒零（零扩展），
  //  sign=1 时复制原符号位（符号扩展），与下式等价。
  function automatic logic [XLEN-1:0] cvtDivSrc(input logic        isW,
                                                input logic        sign,
                                                input logic [XLEN-1:0] x);
    if (isW) cvtDivSrc = {{(XLEN-32){sign & x[31]}}, x[31:0]};
    else     cvtDivSrc = x;
  endfunction

  // ---------------------------------------------------------------------------
  //  RobPtr 冲刷判定（RobPtr.needFlush 的展平实现）
  // ---------------------------------------------------------------------------
  //  needFlush = flush.valid &&
  //              ( (flush.level && this == flush.robIdx)            // flushItself
  //                || isAfter(this, flush.robIdx) )                 // 比冲刷点更年轻
  //  其中 RobPtr 是循环队列指针 {flag, value}，
  //    isAfter(a,b) = a.flag ^ b.flag ^ (a.value > b.value)
  //  注：调用处会再与“是否正在迭代”等条件相与（见 DivUnit.sv 的 kill_w/kill_r）。
  function automatic logic robNeedFlush(
      input logic       flush_valid,
      input logic       flush_level,
      input logic       flush_flag,
      input logic [7:0] flush_value,
      input logic       this_flag,
      input logic [7:0] this_value);
    logic flush_itself;
    logic is_after;
    flush_itself = flush_level & (this_flag == flush_flag) & (this_value == flush_value);
    is_after     = this_flag ^ flush_flag ^ (this_value > flush_value);
    return flush_valid & (flush_itself | is_after);
  endfunction

endpackage
