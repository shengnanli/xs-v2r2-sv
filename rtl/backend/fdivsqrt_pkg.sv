// =============================================================================
//  fdivsqrt_pkg —— 浮点除/开方功能单元 FDivSqrt 的类型 / 常量 / 纯函数
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/backend/fu/wrapper/FDivSqrt.scala
//                （class FDivSqrt extends FpNonPipedFuncUnit）
//                + src/main/scala/xiangshan/backend/rob/RobPtr.scala (needFlush)
//                + utility.DataHoldBypass（outCtrl 锁存）
//
//  FDivSqrt 是浮点除法 / 开方 FU：fdiv（is_sqrt=0）/ fsqrt（is_sqrt=1）。这是一个
//  **非定长流水（迭代）单元**：FloatDivider 内部多拍迭代，故带 in.ready/out.ready 握手与
//  flush 端口（可被重定向冲刷）。本 wrapper 层只做：
//    1) rm 选择、fp_fmt 透传、两源 NaN 检测（同 FAlu）；
//    2) 握手：start_valid=io.in.valid，start_ready→io.in.ready；finish_valid→io.out.valid，
//       finish_ready=io.out.ready & io.out.valid；
//    3) 用 DataHoldBypass 在 io.in.fire 时锁存输出侧控制(robIdx/pdest/.../fmt/perf)，
//       供迭代结束时写回（输出控制 = 锁存值）；
//    4) flush：用「正在处理的 robIdx」(io.in.fire 时取输入、否则取锁存) 与 flush 比较 needFlush；
//    5) 结果按输出 fmt 做 NaN-box（窄结果高位补全 1）。
// =============================================================================
package fdivsqrt_pkg;

  localparam int XLEN = 64;
  localparam int ROB_IDX_W = 8;     // RobPtr value 位宽

  typedef enum logic [1:0] {
    FMT_E8  = 2'b00,
    FMT_E16 = 2'b01,   // f16
    FMT_E32 = 2'b10,   // f32
    FMT_E64 = 2'b11    // f64
  } fp_fmt_e;

  function automatic logic [2:0] selRoundMode(input logic [2:0] inst_rm,
                                              input logic [2:0] csr_frm);
    selRoundMode = (inst_rm != 3'b111) ? inst_rm : csr_frm;
  endfunction

  function automatic logic isFpCanonicalNAN(input fp_fmt_e fmt,
                                            input logic [XLEN-1:0] src);
    logic e32_bad, e16_bad;
    e32_bad = (fmt == FMT_E32) && (src[63:32] != 32'hFFFFFFFF);
    e16_bad = (fmt == FMT_E16) && (src[63:16] != 48'hFFFFFFFFFFFF);
    isFpCanonicalNAN = e32_bad | e16_bad;
  endfunction

  // ---------------------------------------------------------------------------
  //  RobPtr.needFlush：判断「本条 robIdx」是否被重定向冲刷
  // ---------------------------------------------------------------------------
  //  RobPtr = {flag, value}，flag 是回绕标志位。重定向携带 robIdx 与 level：
  //    · level==1（异常级冲刷）：robIdx 相等也要冲（含自身）；
  //    · 否则只冲「严格更年轻(older-than 之后)」的：用 (flag^fflag) ^ (value>fvalue)
  //      表达环形比较的「晚于 flush.robIdx」。
  //  与 golden 逐位等价：flush_valid & ( level&同号同值 | (flag^fflag ^ (value>fvalue)) )
  function automatic logic robNeedFlush(
      input logic              flush_valid,
      input logic              flush_level,
      input logic              flush_flag,
      input logic [ROB_IDX_W-1:0] flush_value,
      input logic              this_flag,
      input logic [ROB_IDX_W-1:0] this_value);
    logic same_rob, younger;
    same_rob = ({this_flag, this_value} == {flush_flag, flush_value});
    younger  = this_flag ^ flush_flag ^ (this_value > flush_value);
    robNeedFlush = flush_valid & ((flush_level & same_rob) | younger);
  endfunction

  // ---------------------------------------------------------------------------
  //  结果按输出格式做 NaN-box（窄结果高位补全 1）
  // ---------------------------------------------------------------------------
  //  迭代器给出 64bit 结果 res；按输出 fmt 取低 16/32/64 位并把高位补 1（NaN-boxing）。
  //  用 one-hot OR-mux 复刻 Chisel Mux1H：非法 fmt → 0（与 golden 等价）。
  function automatic logic [XLEN-1:0] boxResult(input fp_fmt_e fmt,
                                                input logic [XLEN-1:0] res);
    case (fmt)
      FMT_E16 : boxResult = {48'hFFFFFFFFFFFF, res[15:0]};
      FMT_E32 : boxResult = {32'hFFFFFFFF,     res[31:0]};
      FMT_E64 : boxResult = res;
      default : boxResult = '0;        // e8 等非法格式：Mux1H 无命中 → 0
    endcase
  endfunction

endpackage
