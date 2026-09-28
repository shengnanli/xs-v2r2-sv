// =============================================================================
// LqExceptionBuffer —— LoadQueue 的"最老异常 load"记录器
//
// 位置：MemBlock / LSU 的 LoadQueue 侧（LoadQueue 的一个 child）。发生异常的 load
//       （地址不对齐、访问错、页错、断点、硬件错、客户页错）不会立刻把异常地址交出去；
//       ROB 真正处理异常时才来问"那条 load 的虚地址 / 客户物理地址是多少"。本模块就是
//       那个答案：它一直记着**目前为止最老的一条**异常 load 的地址信息，由
//       io_exceptionAddr_* 直接输出。
//
// 数据流（Chisel: xiangshan/mem/lsqueue/LoadExceptionBuffer.scala）：
//   6 个入口：3 条标量 load 流水线 + 2 条向量 load 流水线 + 1 个 MMIO 总线非数据错口。
//   s1  入口直接打一拍（s2_req = RegEnable(req, valid)，s2 valid = RegNext(valid)）；
//   s2  入口有效、没被上一拍或本拍的 redirect 冲掉、且带 LduCfg 关心的异常位 => 候选；
//       6 个候选加上"当前记着的那条"（若它本拍没被 redirect 冲掉）共 7 个，按
//       selectOldest 的锦标赛树两两比年龄：robIdx 更老者赢，同一条指令（robIdx 相等）
//       uopIdx 更小者赢。胜者**每拍无条件**写回 req（胜者就是 req 自己时等于保持）。
//
// 锦标赛树的形状照抄 Scala 的递归切分（7 = 3 + 4，3 = 1 + 2，4 = 2 + 2）：
//       pick( pick(c0, pick(c1, c2)),  pick(pick(c3, c4), pick(c5, c6=req)) )
//   两两比较 pick(a, b)：都有效 -> 年龄决定；只有 a 有效 -> a；否则（只有 b 或都无效）-> b。
//   ★都无效时取 b 的 payload★：req 每拍都写，这条规则保证"全无效"时最终取到 c6 = req，
//   即保持。树形或这条规则改一点，"无效候选的 payload"就会漏进 req —— 照抄，不化简。
//
// 几处"照抄 golden、不许抹平"的地方：
//   · 父级给某些入口的某些字段恒定常数，firtool 把常数推了进来，golden 在这些口上**连
//     端口带寄存器都没有**：向量 load 口 3、4 的 isHyper 恒 0；MMIO 口 5 的 vaNeedExt
//     恒 1。这里也不为它们建寄存器（建了就是 golden 没有的状态，FM 必失配），读的时候
//     直接用常数（见 §1 的 generate）。
//   · RegNext(io.redirect) 在 s2 判定里**每个入口各一份**（golden s2_valid_REG_1/3/../11）。
//   · golden 有一个只供 perf 计数用的 RegNext(req_valid)（名为 REG，没有读者）。照抄为
//     req_valid_last_q：两侧对称死位，按 vmucp standing rule 处置（verif/fm_target_config）。
// =============================================================================
package lqexceptionbuffer_pkg;

  localparam int ENQ_PORTS = 6;   // LoadPipelineWidth 3 + VecLoadPipelineWidth 2 + 1（MMIO 非数据错）

  // 各入口是否真的有这个字段（没有的口父级给常数，golden 里无端口无寄存器）
  localparam logic [ENQ_PORTS-1:0] HAS_ISHYPER   = 6'b100111;   // 口 3、4（向量 load）恒 0
  localparam logic [ENQ_PORTS-1:0] HAS_VANEEDEXT = 6'b011111;   // 口 5（MMIO）恒 1
  localparam logic ISHYPER_CONST   = 1'b0;
  localparam logic VANEEDEXT_CONST = 1'b1;

  // io.redirect 的一份拷贝（golden 只留下 needFlush 要用的这四个字段）
  typedef struct packed {
    logic       valid;
    logic       robIdx_flag;
    logic [7:0] robIdx_value;
    logic       level;         // 1 = flushItself（精确 redirect，连自己一起冲）
  } redirect_t;

  // ---- 入口 bundle 与其子集：字段表逐字取自 golden 端口表 ----
  // BEGIN GENERATED(leb-types)
  // leb_req_t：一个入口交来的 load（LqWriteBundle 在本模块被用到的字段；取自口 0 端口表），14 字段 / 153 位
  typedef struct packed {
    logic         uop_exceptionVec_3;
    logic         uop_exceptionVec_4;
    logic         uop_exceptionVec_5;
    logic         uop_exceptionVec_13;
    logic         uop_exceptionVec_19;
    logic         uop_exceptionVec_21;
    logic [6:0]   uop_uopIdx;
    logic         uop_robIdx_flag;
    logic [7:0]   uop_robIdx_value;
    logic [63:0]  fullva;
    logic         vaNeedExt;
    logic [63:0]  gpaddr;
    logic         isHyper;
    logic         isForVSnonLeafPTE;
  } leb_req_t;

  // leb_s2_t：s2 寄存器里各口都有的部分（= leb_req_t 去掉 isHyper / vaNeedExt），12 字段 / 151 位
  typedef struct packed {
    logic         uop_exceptionVec_3;
    logic         uop_exceptionVec_4;
    logic         uop_exceptionVec_5;
    logic         uop_exceptionVec_13;
    logic         uop_exceptionVec_19;
    logic         uop_exceptionVec_21;
    logic [6:0]   uop_uopIdx;
    logic         uop_robIdx_flag;
    logic [7:0]   uop_robIdx_value;
    logic [63:0]  fullva;
    logic [63:0]  gpaddr;
    logic         isForVSnonLeafPTE;
  } leb_s2_t;

  // leb_info_t：req 寄存器要记住的部分（= leb_req_t 去掉异常位；取自 golden req_* 寄存器表），8 字段 / 147 位
  typedef struct packed {
    logic [6:0]   uop_uopIdx;
    logic         uop_robIdx_flag;
    logic [7:0]   uop_robIdx_value;
    logic [63:0]  fullva;
    logic         vaNeedExt;
    logic [63:0]  gpaddr;
    logic         isHyper;
    logic         isForVSnonLeafPTE;
  } leb_info_t;

  function automatic leb_s2_t to_s2(leb_req_t r);
    leb_s2_t s;
    s.uop_exceptionVec_3 = r.uop_exceptionVec_3;
    s.uop_exceptionVec_4 = r.uop_exceptionVec_4;
    s.uop_exceptionVec_5 = r.uop_exceptionVec_5;
    s.uop_exceptionVec_13 = r.uop_exceptionVec_13;
    s.uop_exceptionVec_19 = r.uop_exceptionVec_19;
    s.uop_exceptionVec_21 = r.uop_exceptionVec_21;
    s.uop_uopIdx = r.uop_uopIdx;
    s.uop_robIdx_flag = r.uop_robIdx_flag;
    s.uop_robIdx_value = r.uop_robIdx_value;
    s.fullva = r.fullva;
    s.gpaddr = r.gpaddr;
    s.isForVSnonLeafPTE = r.isForVSnonLeafPTE;
    return s;
  endfunction

  function automatic leb_req_t from_s2(leb_s2_t s, logic isHyper, logic vaNeedExt);
    leb_req_t r;
    r.uop_exceptionVec_3 = s.uop_exceptionVec_3;
    r.uop_exceptionVec_4 = s.uop_exceptionVec_4;
    r.uop_exceptionVec_5 = s.uop_exceptionVec_5;
    r.uop_exceptionVec_13 = s.uop_exceptionVec_13;
    r.uop_exceptionVec_19 = s.uop_exceptionVec_19;
    r.uop_exceptionVec_21 = s.uop_exceptionVec_21;
    r.uop_uopIdx = s.uop_uopIdx;
    r.uop_robIdx_flag = s.uop_robIdx_flag;
    r.uop_robIdx_value = s.uop_robIdx_value;
    r.fullva = s.fullva;
    r.vaNeedExt = vaNeedExt;
    r.gpaddr = s.gpaddr;
    r.isHyper = isHyper;
    r.isForVSnonLeafPTE = s.isForVSnonLeafPTE;
    return r;
  endfunction

  function automatic leb_info_t to_info(leb_req_t r);
    leb_info_t i;
    i.uop_uopIdx = r.uop_uopIdx;
    i.uop_robIdx_flag = r.uop_robIdx_flag;
    i.uop_robIdx_value = r.uop_robIdx_value;
    i.fullva = r.fullva;
    i.vaNeedExt = r.vaNeedExt;
    i.gpaddr = r.gpaddr;
    i.isHyper = r.isHyper;
    i.isForVSnonLeafPTE = r.isForVSnonLeafPTE;
    return i;
  endfunction
// END GENERATED

  // RobPtr 比较：a 在 b 之后（更年轻）。★写成 flag ^ flag ^ (value > value)，与 golden 同形★
  function automatic logic rob_is_after(logic af, logic [7:0] av, logic bf, logic [7:0] bv);
    return af ^ bf ^ (av > bv);
  endfunction

  // robIdx.needFlush(redirect)
  function automatic logic need_flush(logic rf, logic [7:0] rv, redirect_t r);
    return r.valid & ((r.level & ({rf, rv} == {r.robIdx_flag, r.robIdx_value}))
                      | rob_is_after(rf, rv, r.robIdx_flag, r.robIdx_value));
  endfunction

  // 锦标赛里的一个选手：有效位 + 要记住的信息
  typedef struct packed {
    logic      valid;
    leb_info_t bits;
  } cand_t;

  // selectOldest 的两两比较（Scala 的 length == 2 分支）
  function automatic cand_t pick_oldest(cand_t a, cand_t b);
    logic b_older;
    b_older = rob_is_after(a.bits.uop_robIdx_flag, a.bits.uop_robIdx_value,
                           b.bits.uop_robIdx_flag, b.bits.uop_robIdx_value)
            | (({a.bits.uop_robIdx_flag, a.bits.uop_robIdx_value}
                == {b.bits.uop_robIdx_flag, b.bits.uop_robIdx_value})
               & (a.bits.uop_uopIdx > b.bits.uop_uopIdx));
    if (a.valid & b.valid)
      return b_older ? b : a;
    else
      return (a.valid & ~b.valid) ? a : b;
  endfunction

endpackage

module xs_LqExceptionBuffer_core
  import lqexceptionbuffer_pkg::*;
(
  input  logic                 clock,
  input  logic                 reset,
  input  logic                 io_redirect_valid,
  input  logic                 io_redirect_bits_robIdx_flag,
  input  logic [7:0]           io_redirect_bits_robIdx_value,
  input  logic                 io_redirect_bits_level,
  input  logic [ENQ_PORTS-1:0] io_req_valid,
  input  leb_req_t             io_req_bits [ENQ_PORTS],   // 没有的字段（见 HAS_*）核不读
  output logic [63:0]          io_exceptionAddr_vaddr,
  output logic                 io_exceptionAddr_vaNeedExt,
  output logic                 io_exceptionAddr_isHyper,
  output logic [63:0]          io_exceptionAddr_gpaddr,
  output logic                 io_exceptionAddr_isForVSnonLeafPTE
);

  redirect_t redirect_now;
  assign redirect_now = '{valid:        io_redirect_valid,
                          robIdx_flag:  io_redirect_bits_robIdx_flag,
                          robIdx_value: io_redirect_bits_robIdx_value,
                          level:        io_redirect_bits_level};

  // ---------------------------------------------------------------------------
  // §1 s2 寄存器：各入口打一拍（不复位）
  //
  // 所有口都有的字段存在 s2_q（leb_s2_t）；isHyper / vaNeedExt 只在真有这个字段的口
  // 建寄存器，其余口直接用常数。s2_req 是按口重新拼好的完整请求（组合）。
  // ---------------------------------------------------------------------------
  logic [ENQ_PORTS-1:0] s2_valid_q;                  // RegNext(io.req(p).valid)
  redirect_t            s2_redirect_q [ENQ_PORTS];   // RegNext(io.redirect)，每口一份
  leb_s2_t              s2_q          [ENQ_PORTS];   // RegEnable(io.req(p).bits, valid)
  wire  [ENQ_PORTS-1:0] s2_ishyper;
  wire  [ENQ_PORTS-1:0] s2_vaneedext;
  leb_req_t             s2_req        [ENQ_PORTS];

  always_ff @(posedge clock) begin
    for (int p = 0; p < ENQ_PORTS; p++) begin
      s2_valid_q[p]    <= io_req_valid[p];
      s2_redirect_q[p] <= redirect_now;
      if (io_req_valid[p])
        s2_q[p] <= to_s2(io_req_bits[p]);
    end
  end

  for (genvar p = 0; p < ENQ_PORTS; p++) begin : g_port
    if (HAS_ISHYPER[p]) begin : g_ishyper
      logic ishyper_q;
      always_ff @(posedge clock)
        if (io_req_valid[p])
          ishyper_q <= io_req_bits[p].isHyper;
      assign s2_ishyper[p] = ishyper_q;
    end
    else begin : g_ishyper_const
      assign s2_ishyper[p] = ISHYPER_CONST;
    end
    if (HAS_VANEEDEXT[p]) begin : g_vaneedext
      logic vaneedext_q;
      always_ff @(posedge clock)
        if (io_req_valid[p])
          vaneedext_q <= io_req_bits[p].vaNeedExt;
      assign s2_vaneedext[p] = vaneedext_q;
    end
    else begin : g_vaneedext_const
      assign s2_vaneedext[p] = VANEEDEXT_CONST;
    end
  end

  always_comb begin
    for (int p = 0; p < ENQ_PORTS; p++)
      s2_req[p] = from_s2(s2_q[p], s2_ishyper[p], s2_vaneedext[p]);
  end

  // ---------------------------------------------------------------------------
  // §2 s2 候选：有效、没被上一拍/本拍的 redirect 冲掉、且带 LduCfg 的异常位
  //   （ExceptionNO.selectByFu(exceptionVec, LduCfg)：断点 3 / 地址不对齐 4 / 访问错 5 /
  //    页错 13 / 硬件错 19 / 客户页错 21）
  // ---------------------------------------------------------------------------
  logic [ENQ_PORTS-1:0] s2_enqueue;

  always_comb begin
    for (int p = 0; p < ENQ_PORTS; p++)
      s2_enqueue[p] = s2_valid_q[p]
                    & ~need_flush(s2_req[p].uop_robIdx_flag, s2_req[p].uop_robIdx_value, s2_redirect_q[p])
                    & ~need_flush(s2_req[p].uop_robIdx_flag, s2_req[p].uop_robIdx_value, redirect_now)
                    & (|{s2_req[p].uop_exceptionVec_21, s2_req[p].uop_exceptionVec_19,
                         s2_req[p].uop_exceptionVec_13, s2_req[p].uop_exceptionVec_5,
                         s2_req[p].uop_exceptionVec_4,  s2_req[p].uop_exceptionVec_3});
  end

  // ---------------------------------------------------------------------------
  // §3 锦标赛：6 个候选 + 当前记着的那条（c6），选出最老的（树形见文件头）
  // ---------------------------------------------------------------------------
  logic      req_valid_q;        // 记着一条有效的异常 load（异步复位）
  leb_info_t req_q;              // 它的信息（不复位，每拍无条件写）
  logic      req_valid_last_q;   // RegNext(req_valid)：golden 只供 perf，没有读者（照抄）

  cand_t cand [ENQ_PORTS + 1];
  cand_t left_right, left, right_left, right_right, right, winner;

  always_comb begin
    for (int p = 0; p < ENQ_PORTS; p++) begin
      cand[p].valid = s2_enqueue[p];
      cand[p].bits  = to_info(s2_req[p]);
    end
    cand[ENQ_PORTS].valid = req_valid_q
                          & ~need_flush(req_q.uop_robIdx_flag, req_q.uop_robIdx_value, redirect_now);
    cand[ENQ_PORTS].bits  = req_q;

    left_right  = pick_oldest(cand[1], cand[2]);
    left        = pick_oldest(cand[0], left_right);
    right_left  = pick_oldest(cand[3], cand[4]);
    right_right = pick_oldest(cand[5], cand[6]);
    right       = pick_oldest(right_left, right_right);
    winner      = pick_oldest(left, right);
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      req_valid_q <= 1'b0;
    else
      req_valid_q <= winner.valid;
  end

  always_ff @(posedge clock) begin
    req_q            <= winner.bits;
    req_valid_last_q <= req_valid_q;
  end

  // ---------------------------------------------------------------------------
  // §4 输出：ROB 处理异常时来取的地址信息
  // ---------------------------------------------------------------------------
  assign io_exceptionAddr_vaddr             = req_q.fullva;
  assign io_exceptionAddr_vaNeedExt         = req_q.vaNeedExt;
  assign io_exceptionAddr_isHyper           = req_q.isHyper;
  assign io_exceptionAddr_gpaddr            = req_q.gpaddr;
  assign io_exceptionAddr_isForVSnonLeafPTE = req_q.isForVSnonLeafPTE;

endmodule

// BEGIN GENERATED(leb-wrapper)
// =============================================================================
// LqExceptionBuffer（golden 同名 wrapper）—— 端口表逐字取 golden，按口装成核的结构体数组。
// 某口没有的字段（HAS_* 为 0）核不读，这里按父级给的常数补上，只为不留悬空输入。
// 整段由 scripts/gen_lqexcbuf.py 生成，勿手改。
// =============================================================================
module LqExceptionBuffer
  import lqexceptionbuffer_pkg::*;
(
  input         clock,
  input         reset,
  input         io_redirect_valid,
  input         io_redirect_bits_robIdx_flag,
  input  [7:0]  io_redirect_bits_robIdx_value,
  input         io_redirect_bits_level,
  input         io_req_0_valid,
  input         io_req_0_bits_uop_exceptionVec_3,
  input         io_req_0_bits_uop_exceptionVec_4,
  input         io_req_0_bits_uop_exceptionVec_5,
  input         io_req_0_bits_uop_exceptionVec_13,
  input         io_req_0_bits_uop_exceptionVec_19,
  input         io_req_0_bits_uop_exceptionVec_21,
  input  [6:0]  io_req_0_bits_uop_uopIdx,
  input         io_req_0_bits_uop_robIdx_flag,
  input  [7:0]  io_req_0_bits_uop_robIdx_value,
  input  [63:0] io_req_0_bits_fullva,
  input         io_req_0_bits_vaNeedExt,
  input  [63:0] io_req_0_bits_gpaddr,
  input         io_req_0_bits_isHyper,
  input         io_req_0_bits_isForVSnonLeafPTE,
  input         io_req_1_valid,
  input         io_req_1_bits_uop_exceptionVec_3,
  input         io_req_1_bits_uop_exceptionVec_4,
  input         io_req_1_bits_uop_exceptionVec_5,
  input         io_req_1_bits_uop_exceptionVec_13,
  input         io_req_1_bits_uop_exceptionVec_19,
  input         io_req_1_bits_uop_exceptionVec_21,
  input  [6:0]  io_req_1_bits_uop_uopIdx,
  input         io_req_1_bits_uop_robIdx_flag,
  input  [7:0]  io_req_1_bits_uop_robIdx_value,
  input  [63:0] io_req_1_bits_fullva,
  input         io_req_1_bits_vaNeedExt,
  input  [63:0] io_req_1_bits_gpaddr,
  input         io_req_1_bits_isHyper,
  input         io_req_1_bits_isForVSnonLeafPTE,
  input         io_req_2_valid,
  input         io_req_2_bits_uop_exceptionVec_3,
  input         io_req_2_bits_uop_exceptionVec_4,
  input         io_req_2_bits_uop_exceptionVec_5,
  input         io_req_2_bits_uop_exceptionVec_13,
  input         io_req_2_bits_uop_exceptionVec_19,
  input         io_req_2_bits_uop_exceptionVec_21,
  input  [6:0]  io_req_2_bits_uop_uopIdx,
  input         io_req_2_bits_uop_robIdx_flag,
  input  [7:0]  io_req_2_bits_uop_robIdx_value,
  input  [63:0] io_req_2_bits_fullva,
  input         io_req_2_bits_vaNeedExt,
  input  [63:0] io_req_2_bits_gpaddr,
  input         io_req_2_bits_isHyper,
  input         io_req_2_bits_isForVSnonLeafPTE,
  input         io_req_3_valid,
  input         io_req_3_bits_uop_exceptionVec_3,
  input         io_req_3_bits_uop_exceptionVec_4,
  input         io_req_3_bits_uop_exceptionVec_5,
  input         io_req_3_bits_uop_exceptionVec_13,
  input         io_req_3_bits_uop_exceptionVec_19,
  input         io_req_3_bits_uop_exceptionVec_21,
  input  [6:0]  io_req_3_bits_uop_uopIdx,
  input         io_req_3_bits_uop_robIdx_flag,
  input  [7:0]  io_req_3_bits_uop_robIdx_value,
  input  [63:0] io_req_3_bits_fullva,
  input         io_req_3_bits_vaNeedExt,
  input  [63:0] io_req_3_bits_gpaddr,
  input         io_req_3_bits_isForVSnonLeafPTE,
  input         io_req_4_valid,
  input         io_req_4_bits_uop_exceptionVec_3,
  input         io_req_4_bits_uop_exceptionVec_4,
  input         io_req_4_bits_uop_exceptionVec_5,
  input         io_req_4_bits_uop_exceptionVec_13,
  input         io_req_4_bits_uop_exceptionVec_19,
  input         io_req_4_bits_uop_exceptionVec_21,
  input  [6:0]  io_req_4_bits_uop_uopIdx,
  input         io_req_4_bits_uop_robIdx_flag,
  input  [7:0]  io_req_4_bits_uop_robIdx_value,
  input  [63:0] io_req_4_bits_fullva,
  input         io_req_4_bits_vaNeedExt,
  input  [63:0] io_req_4_bits_gpaddr,
  input         io_req_4_bits_isForVSnonLeafPTE,
  input         io_req_5_valid,
  input         io_req_5_bits_uop_exceptionVec_3,
  input         io_req_5_bits_uop_exceptionVec_4,
  input         io_req_5_bits_uop_exceptionVec_5,
  input         io_req_5_bits_uop_exceptionVec_13,
  input         io_req_5_bits_uop_exceptionVec_19,
  input         io_req_5_bits_uop_exceptionVec_21,
  input  [6:0]  io_req_5_bits_uop_uopIdx,
  input         io_req_5_bits_uop_robIdx_flag,
  input  [7:0]  io_req_5_bits_uop_robIdx_value,
  input  [63:0] io_req_5_bits_fullva,
  input  [63:0] io_req_5_bits_gpaddr,
  input         io_req_5_bits_isHyper,
  input         io_req_5_bits_isForVSnonLeafPTE,
  output [63:0] io_exceptionAddr_vaddr,
  output        io_exceptionAddr_vaNeedExt,
  output        io_exceptionAddr_isHyper,
  output [63:0] io_exceptionAddr_gpaddr,
  output        io_exceptionAddr_isForVSnonLeafPTE
);
  logic [ENQ_PORTS-1:0] req_valid;
  leb_req_t             req_bits [ENQ_PORTS];

  assign req_valid[0] = io_req_0_valid;
  assign req_bits[0].uop_exceptionVec_3 = io_req_0_bits_uop_exceptionVec_3;
  assign req_bits[0].uop_exceptionVec_4 = io_req_0_bits_uop_exceptionVec_4;
  assign req_bits[0].uop_exceptionVec_5 = io_req_0_bits_uop_exceptionVec_5;
  assign req_bits[0].uop_exceptionVec_13 = io_req_0_bits_uop_exceptionVec_13;
  assign req_bits[0].uop_exceptionVec_19 = io_req_0_bits_uop_exceptionVec_19;
  assign req_bits[0].uop_exceptionVec_21 = io_req_0_bits_uop_exceptionVec_21;
  assign req_bits[0].uop_uopIdx = io_req_0_bits_uop_uopIdx;
  assign req_bits[0].uop_robIdx_flag = io_req_0_bits_uop_robIdx_flag;
  assign req_bits[0].uop_robIdx_value = io_req_0_bits_uop_robIdx_value;
  assign req_bits[0].fullva = io_req_0_bits_fullva;
  assign req_bits[0].vaNeedExt = io_req_0_bits_vaNeedExt;
  assign req_bits[0].gpaddr = io_req_0_bits_gpaddr;
  assign req_bits[0].isHyper = io_req_0_bits_isHyper;
  assign req_bits[0].isForVSnonLeafPTE = io_req_0_bits_isForVSnonLeafPTE;
  assign req_valid[1] = io_req_1_valid;
  assign req_bits[1].uop_exceptionVec_3 = io_req_1_bits_uop_exceptionVec_3;
  assign req_bits[1].uop_exceptionVec_4 = io_req_1_bits_uop_exceptionVec_4;
  assign req_bits[1].uop_exceptionVec_5 = io_req_1_bits_uop_exceptionVec_5;
  assign req_bits[1].uop_exceptionVec_13 = io_req_1_bits_uop_exceptionVec_13;
  assign req_bits[1].uop_exceptionVec_19 = io_req_1_bits_uop_exceptionVec_19;
  assign req_bits[1].uop_exceptionVec_21 = io_req_1_bits_uop_exceptionVec_21;
  assign req_bits[1].uop_uopIdx = io_req_1_bits_uop_uopIdx;
  assign req_bits[1].uop_robIdx_flag = io_req_1_bits_uop_robIdx_flag;
  assign req_bits[1].uop_robIdx_value = io_req_1_bits_uop_robIdx_value;
  assign req_bits[1].fullva = io_req_1_bits_fullva;
  assign req_bits[1].vaNeedExt = io_req_1_bits_vaNeedExt;
  assign req_bits[1].gpaddr = io_req_1_bits_gpaddr;
  assign req_bits[1].isHyper = io_req_1_bits_isHyper;
  assign req_bits[1].isForVSnonLeafPTE = io_req_1_bits_isForVSnonLeafPTE;
  assign req_valid[2] = io_req_2_valid;
  assign req_bits[2].uop_exceptionVec_3 = io_req_2_bits_uop_exceptionVec_3;
  assign req_bits[2].uop_exceptionVec_4 = io_req_2_bits_uop_exceptionVec_4;
  assign req_bits[2].uop_exceptionVec_5 = io_req_2_bits_uop_exceptionVec_5;
  assign req_bits[2].uop_exceptionVec_13 = io_req_2_bits_uop_exceptionVec_13;
  assign req_bits[2].uop_exceptionVec_19 = io_req_2_bits_uop_exceptionVec_19;
  assign req_bits[2].uop_exceptionVec_21 = io_req_2_bits_uop_exceptionVec_21;
  assign req_bits[2].uop_uopIdx = io_req_2_bits_uop_uopIdx;
  assign req_bits[2].uop_robIdx_flag = io_req_2_bits_uop_robIdx_flag;
  assign req_bits[2].uop_robIdx_value = io_req_2_bits_uop_robIdx_value;
  assign req_bits[2].fullva = io_req_2_bits_fullva;
  assign req_bits[2].vaNeedExt = io_req_2_bits_vaNeedExt;
  assign req_bits[2].gpaddr = io_req_2_bits_gpaddr;
  assign req_bits[2].isHyper = io_req_2_bits_isHyper;
  assign req_bits[2].isForVSnonLeafPTE = io_req_2_bits_isForVSnonLeafPTE;
  assign req_valid[3] = io_req_3_valid;
  assign req_bits[3].uop_exceptionVec_3 = io_req_3_bits_uop_exceptionVec_3;
  assign req_bits[3].uop_exceptionVec_4 = io_req_3_bits_uop_exceptionVec_4;
  assign req_bits[3].uop_exceptionVec_5 = io_req_3_bits_uop_exceptionVec_5;
  assign req_bits[3].uop_exceptionVec_13 = io_req_3_bits_uop_exceptionVec_13;
  assign req_bits[3].uop_exceptionVec_19 = io_req_3_bits_uop_exceptionVec_19;
  assign req_bits[3].uop_exceptionVec_21 = io_req_3_bits_uop_exceptionVec_21;
  assign req_bits[3].uop_uopIdx = io_req_3_bits_uop_uopIdx;
  assign req_bits[3].uop_robIdx_flag = io_req_3_bits_uop_robIdx_flag;
  assign req_bits[3].uop_robIdx_value = io_req_3_bits_uop_robIdx_value;
  assign req_bits[3].fullva = io_req_3_bits_fullva;
  assign req_bits[3].vaNeedExt = io_req_3_bits_vaNeedExt;
  assign req_bits[3].gpaddr = io_req_3_bits_gpaddr;
  assign req_bits[3].isHyper = ISHYPER_CONST;   // 本口无此字段（父级恒常数）
  assign req_bits[3].isForVSnonLeafPTE = io_req_3_bits_isForVSnonLeafPTE;
  assign req_valid[4] = io_req_4_valid;
  assign req_bits[4].uop_exceptionVec_3 = io_req_4_bits_uop_exceptionVec_3;
  assign req_bits[4].uop_exceptionVec_4 = io_req_4_bits_uop_exceptionVec_4;
  assign req_bits[4].uop_exceptionVec_5 = io_req_4_bits_uop_exceptionVec_5;
  assign req_bits[4].uop_exceptionVec_13 = io_req_4_bits_uop_exceptionVec_13;
  assign req_bits[4].uop_exceptionVec_19 = io_req_4_bits_uop_exceptionVec_19;
  assign req_bits[4].uop_exceptionVec_21 = io_req_4_bits_uop_exceptionVec_21;
  assign req_bits[4].uop_uopIdx = io_req_4_bits_uop_uopIdx;
  assign req_bits[4].uop_robIdx_flag = io_req_4_bits_uop_robIdx_flag;
  assign req_bits[4].uop_robIdx_value = io_req_4_bits_uop_robIdx_value;
  assign req_bits[4].fullva = io_req_4_bits_fullva;
  assign req_bits[4].vaNeedExt = io_req_4_bits_vaNeedExt;
  assign req_bits[4].gpaddr = io_req_4_bits_gpaddr;
  assign req_bits[4].isHyper = ISHYPER_CONST;   // 本口无此字段（父级恒常数）
  assign req_bits[4].isForVSnonLeafPTE = io_req_4_bits_isForVSnonLeafPTE;
  assign req_valid[5] = io_req_5_valid;
  assign req_bits[5].uop_exceptionVec_3 = io_req_5_bits_uop_exceptionVec_3;
  assign req_bits[5].uop_exceptionVec_4 = io_req_5_bits_uop_exceptionVec_4;
  assign req_bits[5].uop_exceptionVec_5 = io_req_5_bits_uop_exceptionVec_5;
  assign req_bits[5].uop_exceptionVec_13 = io_req_5_bits_uop_exceptionVec_13;
  assign req_bits[5].uop_exceptionVec_19 = io_req_5_bits_uop_exceptionVec_19;
  assign req_bits[5].uop_exceptionVec_21 = io_req_5_bits_uop_exceptionVec_21;
  assign req_bits[5].uop_uopIdx = io_req_5_bits_uop_uopIdx;
  assign req_bits[5].uop_robIdx_flag = io_req_5_bits_uop_robIdx_flag;
  assign req_bits[5].uop_robIdx_value = io_req_5_bits_uop_robIdx_value;
  assign req_bits[5].fullva = io_req_5_bits_fullva;
  assign req_bits[5].vaNeedExt = VANEEDEXT_CONST;   // 本口无此字段（父级恒常数）
  assign req_bits[5].gpaddr = io_req_5_bits_gpaddr;
  assign req_bits[5].isHyper = io_req_5_bits_isHyper;
  assign req_bits[5].isForVSnonLeafPTE = io_req_5_bits_isForVSnonLeafPTE;

  xs_LqExceptionBuffer_core u_core (
    .clock                              (clock),
    .reset                              (reset),
    .io_redirect_valid                  (io_redirect_valid),
    .io_redirect_bits_robIdx_flag       (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value      (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level             (io_redirect_bits_level),
    .io_req_valid                       (req_valid),
    .io_req_bits                        (req_bits),
    .io_exceptionAddr_vaddr             (io_exceptionAddr_vaddr),
    .io_exceptionAddr_vaNeedExt         (io_exceptionAddr_vaNeedExt),
    .io_exceptionAddr_isHyper           (io_exceptionAddr_isHyper),
    .io_exceptionAddr_gpaddr            (io_exceptionAddr_gpaddr),
    .io_exceptionAddr_isForVSnonLeafPTE (io_exceptionAddr_isForVSnonLeafPTE)
  );
endmodule
// END GENERATED
