// ExeUnit_study.sv —— 香山昆明湖 V2 整数执行口 ExeUnit（可读重写 / 学习材料）
//
// 这是什么：后端"执行级"的一个**执行口**（issue port）。上游发射队列每拍最多送一条
//   uop 进来，本模块把它分发给口内三个功能单元之一，等结果出来后仲裁成唯一一路写回。
//   本口（整数 0 号口）= Alu(0 拍) + MulUnit(2 拍) + Bku(2 拍)。
//   ExeUnit 自己**不做任何运算**，它全部的工作是 FU 周围的 glue：分发、打拍对齐、
//   flush、时钟门控、输出仲裁。想看运算，去 Alu.sv / MulUnit.sv / Bku.sv。
//
//   flush ─┐
//          ▼                        ┌──────────── Alu (0 拍, 组合) ─────────┐
//   io_in ─┴─▶ Dispatcher ──valid──▶├──────────── MulUnit (2 拍) ──────────┤─▶ §4
//          │   (35b 独热比较)        └──────────── Bku (2 拍) ──────────────┘  或归约
//          │                          ▲          ▲                              │
//          ├─▶ §1 ctrl_pipe ──────────┘(第2级控制位)                            ▼
//          ├─▶ §1 alive_pipe ─────────┘(逐级存活位, flush 在这里杀)          io_out
//          └─▶ §2 占用影子链 ─▶ ClockGate ─▶ Mul/Bku 的 clock
//
// 五个非看不可的点（README.md 里每一点都配了 Verdi 信号组）：
//  1) 分发靠 fuType 的 **35 位独热整字比较**，见 Dispatcher_study.sv。
//  2) **两个 valid 各管各的**，最容易看混：
//       alive_pipe(golden inPipe_2_*)  = "这条 uop 还活着吗" —— 由 ExeUnit 维护，flush 只动它；
//       valid_thisfu(在 FU 内部)       = "这一级槽位里有东西吗" —— 由 FU 自己维护，不认识 flush。
//     FU 的 io_out_valid = 二者相与。杀掉一条在飞指令，靠的是把前者掐 0。
//  3) 三种握手形态：Alu = 纯组合(in_ready 直接等于 out_ready)；Mul/Bku = 定长 2 级流水
//     (自己的 rdy 链 + 外面喂进来的 alive 链)。**本执行口没有变长迭代的 Div**，
//     Div 在另外的执行口（ExeUnit_1 那一族），这里看不到。
//  4) **flush 判定窗口只有 2 拍**：只有 alive_pipe[0]、alive_pipe[1] 两个判定点，
//     没有第三个。晚于 2 拍到的 flush 掐不掉它，结果照样写回，由下游 ROB 按 robIdx 丢弃。
//  5) **ctrl_pipe**：robIdx/pdest/rfWen 这些控制位不进 FU 的流水，而是在 ExeUnit 里
//     单独打拍，等 FU 出结果那拍再交给它（golden 端口名 ctrlPipe_0 / ctrlPipe_2）。
//     省掉在每个 FU 里各复制一份控制流水的面积。
//
// ── golden 对照表（左边是 G1 golden ExeUnit.sv 里的名字，右边是本文件的名字）──
//   inPipe_2_1 / inPipe_2_2            → alive_pipe[0] / alive_pipe[1]  (别名 alive_s1/s2)
//   inPipe_1_1_* / inPipe_1_2_*        → ctrl_pipe[0]  / ctrl_pipe[1]   (别名 ctrl_s1/s2)
//   （flush 判定是内联的，无名）        → kill_s0 / kill_s1
//   fuVldVec_1   / fuVldVec_2          → g_gate[0].occ_s1 / g_gate[0].occ_s2   (Mul)
//   fuVldVec_1_1 / fuVldVec_2_1        → g_gate[1].occ_s1 / g_gate[1].occ_s2   (Bku)
//   fuRdyVec_1   / fuRdyVec_1_1        → g_gate[0].rdy_s1 / g_gate[1].rdy_s1
//   fuVld_en_1   / fuVld_en_2          → g_gate[*].busy
//   fuVld_en_reg_1 / fuVld_en_reg_2    → g_gate[*].busy_q
//   clk_en_1_probe / clk_en_2_probe    → clk_en_gated[0] / clk_en_gated[1]
//   _in1ToN_io_out_N_valid             → disp_valid[N]
//   _Alu_io_out_valid / _Mul_ / _Bku_  → fu_valid[0] / [1] / [2]
//   io_out_bits_data_1_0               → sel_data
//
// ★ 本文件是 **verif/study 下的学习材料，不是 rtl/ 里的交付重写**：
//   - 它没进过本工程的 FM 等价签核，只过了本目录 tb 的逐拍双例化比对（见 README）。
//   - 顶层 wrapper 直接叫 ExeUnit_xs 而不是 golden 同名的 ExeUnit，因为学习台要把
//     golden 和它同时编进一次 elaboration。rtl/ 里的正式重写走 CONVENTIONS 的
//     "golden 同名 wrapper + derive_ut_impl.py 派生"路线；这里省掉派生，
//     让你在 Verdi 里读到的就是我手写的原文，没有被脚本改过名的注释。
//   - 端口与 G1 golden ExeUnit 逐位同名、同宽、同方向（50 个端口）。
// ============================================================================

package exeunit_study_pkg;

  localparam int XLEN    = 64;
  localparam int NUM_FU  = 3;   // 本执行口的功能单元数：0=Alu 1=Mul 2=Bku
  localparam int LAT_MAX = 2;   // 口内最长固定延迟（Mul/Bku 都是 2 拍）→ 打拍链深度
  localparam int N_GATED = 2;   // 需要时钟门控的 FU 数（Alu 无时序，不门控）

  // ROB 索引：环形队列指针。value 是槽位号，flag 是"绕了奇数圈"标志。
  // 比新旧不能直接比 value —— 必须连 flag 一起比（见 rob_younger）。
  typedef struct packed {
    logic       flag;
    logic [7:0] value;
  } robidx_t;

  // 随 uop 走、但不进 FU 运算流水的控制位（就是 golden 的 ctrlPipe 那一束）。
  typedef struct packed {
    robidx_t    robIdx;   // 谁：ROB 里的位置，写回和 flush 都按它认人
    logic [7:0] pdest;    // 写哪：物理目的寄存器号
    logic       rfWen;    // 写不写：整数寄存器堆写使能
  } uop_ctrl_t;

  // 性能计数/调试观测线：一路跟着 uop 走，不参与任何功能判断。
  typedef struct packed {
    logic        eliminatedMove;
    logic [63:0] renameTime;
    logic [63:0] dispatchTime;
    logic [63:0] enqRsTime;
    logic [63:0] selectTime;
    logic [63:0] issueTime;
    logic [63:0] writebackTime;
    logic [63:0] runahead_checkpoint_id;
    logic [63:0] tlbFirstReqTime;
    logic [63:0] tlbRespTime;
  } perf_t;

  typedef struct packed {
    logic [55:0] seqNum;
    logic [7:0]  uopIdx;
  } seqnum_t;

  // --------------------------------------------------------------------------
  // ROB 索引的环形新旧比较：a 是否比 b **更年轻**（更晚进 ROB）？
  //   ROB 是环形队列，指针每绕一圈 flag 翻转一次。于是：
  //     flag 相同 → 同一圈内，value 大的更年轻；
  //     flag 不同 → 差了一圈，value 大的反而更老。
  //   两种情况合起来正好是一个异或：flag_a ^ flag_b ^ (value_a > value_b)。
  //   golden 里就是这一串（注意 Verilog 里 > 的优先级高于 ^，所以断句是
  //   `flag ^ flag ^ (value > value)`，不是 `((flag^flag)^value) > value`）。
  // --------------------------------------------------------------------------
  function automatic logic rob_younger(robidx_t a, robidx_t b);
    rob_younger = a.flag ^ b.flag ^ (a.value > b.value);
  endfunction

  // --------------------------------------------------------------------------
  // 这条在飞 uop 要不要被本次 flush（重定向）杀掉？
  //   level=0（后端重定向/分支预测失败）：只杀**比 flush 点更年轻**的，
  //                                       flush 点那条自己要活着走完（它是罪魁，但它有效）。
  //   level=1（flushItself，例如异常/fence）：连 flush 点**自己**一起杀。
  //   对应 Chisel: robIdx.needFlush(redirect)。
  // --------------------------------------------------------------------------
  function automatic logic need_flush(robidx_t rob,
                                      logic    fl_valid,
                                      logic    fl_level,
                                      robidx_t fl_rob);
    need_flush = fl_valid & ((fl_level & (rob == fl_rob)) | rob_younger(rob, fl_rob));
  endfunction

endpackage : exeunit_study_pkg


// ============================================================================
// xs_ExeUnit_study_core —— 可读核
// ============================================================================
module xs_ExeUnit_study_core
  import exeunit_study_pkg::*;
(
  input  logic            clock,
  input  logic            reset,

  // ---- 重定向（flush）广播：全后端共用一根，不带握手 ----
  input  logic            flush_valid,
  input  robidx_t         flush_robIdx,
  input  logic            flush_level,

  // ---- 上游发射口 io.in（Decoupled）----
  output logic            in_ready,
  input  logic            in_valid,
  input  logic [34:0]     in_fuType,
  input  logic [8:0]      in_fuOpType,
  input  logic [XLEN-1:0] in_src0,
  input  logic [XLEN-1:0] in_src1,
  input  uop_ctrl_t       in_ctrl,
  input  perf_t           in_perf,
  input  seqnum_t         in_seqNum,

  // ---- 下游写回口 io.out（Decoupled）----
  input  logic            out_ready,
  output logic            out_valid,
  output logic [XLEN-1:0] out_data,
  output uop_ctrl_t       out_ctrl,
  output perf_t           out_perf,
  output seqnum_t         out_seqNum,

  // ---- DFT：两个 ClockGate 的 test enable（拉高 = 门常开）----
  input  logic            cg_te_mul,
  input  logic            cg_te_bku
);

  // ==========================================================================
  // §0 分发：把 io_in 路由到三个 FU 之一
  // --------------------------------------------------------------------------
  // 真正的比较逻辑在 Dispatcher_study.sv。这里只接线。
  // 注意 in_ready 的方向：由分发器把三个 FU 的 ready **与**起来往上游报。
  //
  // perf / seqNum 这两束纯观测线，分发器对它们不做任何事（golden 里是逐字段
  // 直连再三路广播）。为了不让 36 行机械连线淹掉这个文件，这里让它们**绕过**
  // 分发器，从 io_in 直接接到各 FU —— 与 golden 逐拍等价（都是同一根组合线），
  // 只是网表上少绕一层。Dispatcher_xs 那三组 perf 输出你在波形里照样看得到，
  // 只是没人接。这是本文件与 golden **唯一的结构性差异**，行为上无差别。
  // ==========================================================================
  logic [NUM_FU-1:0] disp_valid;    // golden: _in1ToN_io_out_{0,1,2}_valid
  logic [NUM_FU-1:0] disp_ready;    // golden: _Alu_io_in_ready / _Mul_ / _Bku_
  logic [8:0]        disp_fuOpType [NUM_FU];

  Dispatcher_xs u_disp (
    .clock                  (clock),
    .reset                  (reset),
    .io_in_ready            (in_ready),
    .io_in_valid            (in_valid),
    .io_in_bits_fuType      (in_fuType),
    .io_in_bits_fuOpType    (in_fuOpType),
    .io_in_bits_perfDebugInfo_eliminatedMove         (in_perf.eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime             (in_perf.renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime           (in_perf.dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime              (in_perf.enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime             (in_perf.selectTime),
    .io_in_bits_perfDebugInfo_issueTime              (in_perf.issueTime),
    .io_in_bits_perfDebugInfo_writebackTime          (in_perf.writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id (in_perf.runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime        (in_perf.tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime            (in_perf.tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum                  (in_seqNum.seqNum),
    .io_in_bits_debug_seqNum_uopIdx                  (in_seqNum.uopIdx),
    .io_out_0_ready         (disp_ready[0]),
    .io_out_0_valid         (disp_valid[0]),
    .io_out_0_bits_fuOpType (disp_fuOpType[0]),
    .io_out_1_ready         (disp_ready[1]),
    .io_out_1_valid         (disp_valid[1]),
    .io_out_1_bits_fuOpType (disp_fuOpType[1]),
    .io_out_2_ready         (disp_ready[2]),
    .io_out_2_valid         (disp_valid[2]),
    .io_out_2_bits_fuOpType (disp_fuOpType[2])
    // 其余 perf/seqNum 输出端口按上面注释说明留空（模块内部照常有值）
  );

  // ==========================================================================
  // §1 inPipe —— 控制位链 + 存活位链（★教学点 2/4/5 都在这一节）
  // --------------------------------------------------------------------------
  // 两条平行的移位链，深度都是 LAT_MAX=2（口内最长 FU 延迟）：
  //
  //   ctrl_pipe  ：控制位（robIdx/pdest/rfWen）**纯移位**，不带任何清除。
  //                它只是把"这条 uop 是谁"延后 2 拍，好在 Mul/Bku 出结果那拍
  //                把 robIdx/pdest 贴回结果上（golden 端口 ctrlPipe_2）。
  //                Alu 是 0 拍，直接吃当拍的 io_in（golden 端口 ctrlPipe_0）。
  //                ★ 没有复位 —— golden 也没有（always @(posedge clock) 光杆）。
  //                  复位后头两拍它是 X/垃圾，但那两拍 alive_pipe 是 0，没人看它。
  //
  //   alive_pipe ：存活位。每拍前进一格，**并且每一格都重新问一次"被 flush 了吗"**。
  //                这就是"杀在飞指令"的全部机制：把这条链掐成 0。
  //                ★ 有异步复位（golden 同款 posedge reset）。
  //
  // ★★ 教学点 4：判定点只有两个 —— alive_pipe[0] 和 alive_pipe[1]。没有第三个。
  //    时间轴（T = io_in_valid 的那一拍）：
  //      T    : flush 到 → kill_s0 命中 → alive_pipe[0] 写 0        ✔ 杀掉
  //      T+1  : flush 到 → kill_s1 命中 → alive_pipe[1] 写 0        ✔ 杀掉
  //      T+2  : flush 到 → 没有判定点了，Mul 这拍已经 out_valid      ✘ 杀不掉，照常写回
  //    T+2 那次不是漏洞：写回带着 robIdx，ROB 收到后自己会按 robIdx 丢弃。
  //    执行级只负责"能省则省"，正确性兜底在 ROB —— 分层过滤。
  //
  // ★★ 教学点 2：这条 alive_pipe 讲的是**存活性**（这条 uop 还该不该算数）。
  //    另一条 valid 讲的是**占用性**（这一级槽里有没有东西），它在 FU 内部
  //    （xs_MulUnit_core.valid_thisfu_1/_2，golden MulUnit.validVecThisFu_1/_2），
  //    每拍无条件移位，压根不认识 flush。FU 的 out_valid = 两者相与。
  //    在 Verdi 里把 alive_pipe[1] 和 u_mul/u_core/valid_thisfu_2 拖到一起看，
  //    flush 场景下前者被掐 0、后者照常走完，一目了然。
  // ==========================================================================
  uop_ctrl_t ctrl_pipe  [LAT_MAX];   // golden: inPipe_1_1_* / inPipe_1_2_*
  logic      alive_pipe [LAT_MAX];   // golden: inPipe_2_1   / inPipe_2_2

  // 每一级的 flush 判定：拿**该级自己那条 uop 的 robIdx** 去和 flush 点比。
  // 第 0 级用的是当拍进来的 io_in（还没进 ctrl_pipe），第 k 级用 ctrl_pipe[k-1]。
  logic kill_s0;   // 判定"当拍正在进来的这条"
  logic kill_s1;   // 判定"已经在第 1 级的这条"
  assign kill_s0 = need_flush(in_ctrl.robIdx,        flush_valid, flush_level, flush_robIdx);
  assign kill_s1 = need_flush(ctrl_pipe[0].robIdx,   flush_valid, flush_level, flush_robIdx);

  // 控制位链：纯移位，无复位（与 golden 一致）。
  always_ff @(posedge clock) begin
    ctrl_pipe[0] <= in_ctrl;
    for (int k = 1; k < LAT_MAX; k++)
      ctrl_pipe[k] <= ctrl_pipe[k-1];
  end

  // 存活位链：移位 + 逐级 flush-kill，异步复位清 0（与 golden 一致）。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int k = 0; k < LAT_MAX; k++) alive_pipe[k] <= 1'b0;
    end else begin
      alive_pipe[0] <= in_valid       & ~kill_s0;
      alive_pipe[1] <= alive_pipe[0]  & ~kill_s1;
    end
  end
  // 备注：golden 写的是 `inPipe_2_1 <= io_in_valid & ~(io_in_valid & flush & 命中)`，
  //       里面那个多余的 `io_in_valid &` 是 firtool 展开 Mux 留下的，恒等于上式。

  // Verdi 用的标量别名（同一根线，方便直接按名字拖）。
  wire       alive_s1 = alive_pipe[0];
  wire       alive_s2 = alive_pipe[1];
  uop_ctrl_t ctrl_s1; assign ctrl_s1 = ctrl_pipe[0];
  uop_ctrl_t ctrl_s2; assign ctrl_s2 = ctrl_pipe[1];

  // ==========================================================================
  // §2 时钟门控的"占用影子链"（golden fuVldVec_*）
  // --------------------------------------------------------------------------
  // 为什么 ExeUnit 里要再复制一份和 FU 内部一模一样的占用链？
  //   因为 FU 的时钟是**被门控的**。FU 内部那条 valid_thisfu 跑在门控后的时钟上，
  //   一旦门关了它就冻住，没法拿它来判断"还要不要继续给时钟"——鸡生蛋。
  //   所以在**未门控**的 clock 上再养一条一模一样的影子链，专门算门控使能。
  //   这是时钟门控的经典写法：**决定要不要给时钟的那点逻辑，自己不能被门控**。
  //
  //   clk_en = (入口有 uop | 影子链任一级有货) | 上一拍的这个值
  //   末尾那个"| 上一拍"是**多留一拍**：最后一级出结果那拍还要靠时钟把
  //   结果寄存器打出去，不能提前关门。
  //
  // ready 门控：G1 相对 G0 新增的部分。rdy_s1 = "第2级空着，或者下游这拍收走"。
  //   本执行口在真实芯片里 out_ready 恒 1（整数写回口不反压），此时 rdy 恒 1，
  //   下面这堆 if/else 退化成"无条件移位"。留着是为了 bug-for-bug 对齐 golden。
  // ==========================================================================
  localparam int GATED_FU [N_GATED] = '{1, 2};   // 0 号=Mul(FU1)  1 号=Bku(FU2)

  logic [N_GATED-1:0] clk_en_gated;   // golden: clk_en_1_probe / clk_en_2_probe
  logic [N_GATED-1:0] fu_clk;         // 门控后的时钟，喂给 Mul / Bku

  for (genvar g = 0; g < N_GATED; g++) begin : g_gate
    logic occ_s1;   // golden: fuVldVec_1   / fuVldVec_1_1
    logic occ_s2;   // golden: fuVldVec_2   / fuVldVec_2_1
    logic busy_q;   // golden: fuVld_en_reg_1 / fuVld_en_reg_2

    wire  rdy_s1 = ~occ_s2 | out_ready;                          // golden: fuRdyVec_1 / _1_1
    wire  enq    = disp_valid[GATED_FU[g]];                      // 这拍分发给本 FU 了吗
    wire  busy   = enq | occ_s1 | occ_s2;                        // golden: fuVld_en_1 / _2
    wire  clk_en = busy | busy_q;                                // 多留一拍，见上文

    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        occ_s1 <= 1'b0;
        occ_s2 <= 1'b0;
        busy_q <= 1'b0;
      end else begin
        // 第 1 级：本级空着、或本级这拍走得掉，就收下新的；否则维持（走不掉才留住）。
        if ((~occ_s1 | rdy_s1) & enq) occ_s1 <= enq;
        else                          occ_s1 <= ~rdy_s1 & occ_s1;
        // 第 2 级：第 1 级这拍走掉了就接过来；否则下游没收走才留住。
        if (rdy_s1 & occ_s1)          occ_s2 <= occ_s1;
        else                          occ_s2 <= ~out_ready & occ_s2;
        busy_q <= busy;
      end
    end

    assign clk_en_gated[g] = clk_en;
  end

  // ClockGate 是库单元（低电平采样的锁存器 + 与门），两侧共用 golden 那一份，
  // 不重写：这不是"设计"，是工艺库给的东西。
  ClockGate u_cg_mul (.TE(cg_te_mul), .E(clk_en_gated[0]), .CK(clock), .Q(fu_clk[0]));
  ClockGate u_cg_bku (.TE(cg_te_bku), .E(clk_en_gated[1]), .CK(clock), .Q(fu_clk[1]));

  // ==========================================================================
  // §3 三个 FU
  // --------------------------------------------------------------------------
  // ★ 教学点 3：三种握手形态，看这三个例化的端口就能读出来
  //   Alu   ：没有 clock/reset —— 它是**纯组合**。in_ready 直接 = out_ready，
  //           out_valid 直接 = in_valid，当拍进当拍出。控制位吃当拍的 in_ctrl。
  //   Mul/Bku：有 clock(门控后)/reset，定长 2 拍。
  //           - validPipe_0/1/2 是**外面喂进去的存活链**（就是 §1 的 alive）；
  //           - 自己内部还有一条 valid_thisfu 占用链和 rdy 链（在 FU 文件里）；
  //           - 控制位吃 ctrl_pipe[1]（延后 2 拍的那份）。
  //   本口没有变长迭代的 FU；Div（DivUnit，商余迭代，拍数随操作数变）在别的执行口。
  //
  // 例化的是 *_xs 后缀的模块：那是 rtl/backend/{Alu,MulUnit,Bku}.sv 这三份
  // **可读重写**由 scripts/derive_ut_impl.py 机械改名得到的副本（改名只为躲开
  // golden 同名模块，逻辑一字未动）。所以这一侧从上到下都是可读代码：
  //   ExeUnit_xs → Alu_xs/MulUnit_xs/Bku_xs → xs_*_core
  // 唯二仍是 golden 的叶子：ClockGate（库单元）、以及 Bku/MulUnit 内部的
  // 运算阵列（ArrayMulDataModule / CountModule 等，另有 owner，两侧共用同一份）。
  // ==========================================================================
  logic            fu_valid [NUM_FU];
  uop_ctrl_t       fu_ctrl  [NUM_FU];
  logic [XLEN-1:0] fu_data  [NUM_FU];
  perf_t           fu_perf  [NUM_FU];
  seqnum_t         fu_seq   [NUM_FU];

  // ---- FU0：Alu，0 拍，纯组合 ----
  Alu_xs u_alu (
    .io_in_ready                        (disp_ready[0]),
    .io_in_valid                        (disp_valid[0]),
    .io_in_bits_ctrl_fuOpType           (disp_fuOpType[0]),
    .io_in_bits_ctrlPipe_0_robIdx_flag  (in_ctrl.robIdx.flag),   // 0 拍 → 吃当拍
    .io_in_bits_ctrlPipe_0_robIdx_value (in_ctrl.robIdx.value),
    .io_in_bits_ctrlPipe_0_pdest        (in_ctrl.pdest),
    .io_in_bits_ctrlPipe_0_rfWen        (in_ctrl.rfWen),
    .io_in_bits_data_src_1              (in_src1),
    .io_in_bits_data_src_0              (in_src0),
    .io_in_bits_perfDebugInfo_eliminatedMove         (in_perf.eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime             (in_perf.renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime           (in_perf.dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime              (in_perf.enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime             (in_perf.selectTime),
    .io_in_bits_perfDebugInfo_issueTime              (in_perf.issueTime),
    .io_in_bits_perfDebugInfo_writebackTime          (in_perf.writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id (in_perf.runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime        (in_perf.tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime            (in_perf.tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum                  (in_seqNum.seqNum),
    .io_in_bits_debug_seqNum_uopIdx                  (in_seqNum.uopIdx),
    .io_out_ready                       (out_ready),
    .io_out_valid                       (fu_valid[0]),
    .io_out_bits_ctrl_robIdx_flag       (fu_ctrl[0].robIdx.flag),
    .io_out_bits_ctrl_robIdx_value      (fu_ctrl[0].robIdx.value),
    .io_out_bits_ctrl_pdest             (fu_ctrl[0].pdest),
    .io_out_bits_ctrl_rfWen             (fu_ctrl[0].rfWen),
    .io_out_bits_res_data               (fu_data[0]),
    .io_out_bits_perfDebugInfo_eliminatedMove         (fu_perf[0].eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (fu_perf[0].renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (fu_perf[0].dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (fu_perf[0].enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (fu_perf[0].selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (fu_perf[0].issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (fu_perf[0].writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (fu_perf[0].runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (fu_perf[0].tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (fu_perf[0].tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (fu_seq[0].seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (fu_seq[0].uopIdx)
  );

  // ---- FU1：MulUnit，2 拍定长流水，时钟被门控 ----
  MulUnit_xs u_mul (
    .clock                              (fu_clk[0]),
    .reset                              (reset),
    .io_in_ready                        (disp_ready[1]),
    .io_in_valid                        (disp_valid[1]),
    .io_in_bits_ctrl_fuOpType           (disp_fuOpType[1]),
    .io_in_bits_ctrlPipe_2_robIdx_flag  (ctrl_pipe[1].robIdx.flag),  // 2 拍 → 吃延后两拍那份
    .io_in_bits_ctrlPipe_2_robIdx_value (ctrl_pipe[1].robIdx.value),
    .io_in_bits_ctrlPipe_2_pdest        (ctrl_pipe[1].pdest),
    .io_in_bits_ctrlPipe_2_rfWen        (ctrl_pipe[1].rfWen),
    .io_in_bits_validPipe_0             (in_valid),         // 存活链第 0 级 = 当拍
    .io_in_bits_validPipe_1             (alive_pipe[0]),
    .io_in_bits_validPipe_2             (alive_pipe[1]),
    .io_in_bits_data_src_1              (in_src1),
    .io_in_bits_data_src_0              (in_src0),
    .io_in_bits_perfDebugInfo_eliminatedMove         (in_perf.eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime             (in_perf.renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime           (in_perf.dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime              (in_perf.enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime             (in_perf.selectTime),
    .io_in_bits_perfDebugInfo_issueTime              (in_perf.issueTime),
    .io_in_bits_perfDebugInfo_writebackTime          (in_perf.writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id (in_perf.runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime        (in_perf.tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime            (in_perf.tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum                  (in_seqNum.seqNum),
    .io_in_bits_debug_seqNum_uopIdx                  (in_seqNum.uopIdx),
    .io_out_ready                       (out_ready),
    .io_out_valid                       (fu_valid[1]),
    .io_out_bits_ctrl_robIdx_flag       (fu_ctrl[1].robIdx.flag),
    .io_out_bits_ctrl_robIdx_value      (fu_ctrl[1].robIdx.value),
    .io_out_bits_ctrl_pdest             (fu_ctrl[1].pdest),
    .io_out_bits_ctrl_rfWen             (fu_ctrl[1].rfWen),
    .io_out_bits_res_data               (fu_data[1]),
    .io_out_bits_perfDebugInfo_eliminatedMove         (fu_perf[1].eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (fu_perf[1].renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (fu_perf[1].dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (fu_perf[1].enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (fu_perf[1].selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (fu_perf[1].issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (fu_perf[1].writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (fu_perf[1].runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (fu_perf[1].tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (fu_perf[1].tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (fu_seq[1].seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (fu_seq[1].uopIdx)
  );

  // ---- FU2：Bku（位操作/加密扩展 Zb*/Zk*），2 拍定长流水，时钟被门控 ----
  Bku_xs u_bku (
    .clock                              (fu_clk[1]),
    .reset                              (reset),
    .io_in_ready                        (disp_ready[2]),
    .io_in_valid                        (disp_valid[2]),
    .io_in_bits_ctrl_fuOpType           (disp_fuOpType[2]),
    .io_in_bits_ctrlPipe_2_robIdx_flag  (ctrl_pipe[1].robIdx.flag),
    .io_in_bits_ctrlPipe_2_robIdx_value (ctrl_pipe[1].robIdx.value),
    .io_in_bits_ctrlPipe_2_pdest        (ctrl_pipe[1].pdest),
    .io_in_bits_ctrlPipe_2_rfWen        (ctrl_pipe[1].rfWen),
    .io_in_bits_validPipe_0             (in_valid),
    .io_in_bits_validPipe_1             (alive_pipe[0]),
    .io_in_bits_validPipe_2             (alive_pipe[1]),
    .io_in_bits_data_src_1              (in_src1),
    .io_in_bits_data_src_0              (in_src0),
    .io_in_bits_perfDebugInfo_eliminatedMove         (in_perf.eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime             (in_perf.renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime           (in_perf.dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime              (in_perf.enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime             (in_perf.selectTime),
    .io_in_bits_perfDebugInfo_issueTime              (in_perf.issueTime),
    .io_in_bits_perfDebugInfo_writebackTime          (in_perf.writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id (in_perf.runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime        (in_perf.tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime            (in_perf.tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum                  (in_seqNum.seqNum),
    .io_in_bits_debug_seqNum_uopIdx                  (in_seqNum.uopIdx),
    .io_out_ready                       (out_ready),
    .io_out_valid                       (fu_valid[2]),
    .io_out_bits_ctrl_robIdx_flag       (fu_ctrl[2].robIdx.flag),
    .io_out_bits_ctrl_robIdx_value      (fu_ctrl[2].robIdx.value),
    .io_out_bits_ctrl_pdest             (fu_ctrl[2].pdest),
    .io_out_bits_ctrl_rfWen             (fu_ctrl[2].rfWen),
    .io_out_bits_res_data               (fu_data[2]),
    .io_out_bits_perfDebugInfo_eliminatedMove         (fu_perf[2].eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (fu_perf[2].renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (fu_perf[2].dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (fu_perf[2].enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (fu_perf[2].selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (fu_perf[2].issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (fu_perf[2].writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (fu_perf[2].runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (fu_perf[2].tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (fu_perf[2].tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (fu_seq[2].seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (fu_seq[2].uopIdx)
  );

  // ==========================================================================
  // §4 输出仲裁：one-hot 或归约（Chisel 的 Mux1H）
  // --------------------------------------------------------------------------
  // 前提：同一拍**至多一个** FU 的 out_valid 为 1。这不是靠仲裁保证的，而是靠
  //   "延迟互不相同 + 每拍只发一条" 从构造上排开的（Alu 0 拍、Mul/Bku 都 2 拍，
  //   而 Mul 和 Bku 不可能同拍被分发——fuType 是独热）。golden 在这里放了一条
  //   `assert(popcount(valid) <= 1)`（`ifndef SYNTHESIS 里），下面照抄。
  // 于是仲裁就是"选中的取值、没选中的取 0，全部按位或起来"——没有优先级，
  //   综合成一层与-或，比 case/priority mux 短。
  // ==========================================================================
  uop_ctrl_t sel_ctrl;
  logic [XLEN-1:0] sel_data;   // golden: io_out_bits_data_1_0
  perf_t     sel_perf;
  seqnum_t   sel_seq;

  always_comb begin
    sel_ctrl = '0;
    sel_data = '0;
    sel_perf = '0;
    sel_seq  = '0;
    for (int i = 0; i < NUM_FU; i++) begin
      sel_ctrl |= fu_valid[i] ? fu_ctrl[i] : '0;
      sel_data |= fu_valid[i] ? fu_data[i] : '0;
      sel_perf |= fu_valid[i] ? fu_perf[i] : '0;
      sel_seq  |= fu_valid[i] ? fu_seq[i]  : '0;
    end
  end

  assign out_valid  = fu_valid[0] | fu_valid[1] | fu_valid[2];
  assign out_ctrl   = sel_ctrl;
  assign out_data   = sel_data;
  assign out_perf   = sel_perf;
  assign out_seqNum = sel_seq;

`ifndef SYNTHESIS
  always @(posedge clock) begin
    if (!reset && (fu_valid[0] + fu_valid[1] + fu_valid[2]) > 1)
      $error("[ExeUnit] 同一拍多个 FU 写回：Alu=%b Mul=%b Bku=%b（one-hot 前提被打破）",
             fu_valid[0], fu_valid[1], fu_valid[2]);
  end
`endif

endmodule : xs_ExeUnit_study_core


// ============================================================================
// ExeUnit_xs —— 与 G1 golden `ExeUnit` 端口逐位同名同宽的外壳（50 个端口）
// ----------------------------------------------------------------------------
// 只做打包/拆包，没有任何逻辑。两处值得一提：
//   · io_out_bits_data_0 和 data_1 在 golden 里接的是**同一根线**（Chisel 的
//     writeback bundle 有两个 data 槽，整数口只用第 0 个，第 1 个被同值兜底）。
//   · io_out_bits_intWen 就是仲裁后的 rfWen（整数口的写使能，名字换了个说法）。
// ============================================================================
module ExeUnit_xs(
  input         clock,
  input         reset,
  input         io_flush_valid,
  input         io_flush_bits_robIdx_flag,
  input  [7:0]  io_flush_bits_robIdx_value,
  input         io_flush_bits_level,
  output        io_in_ready,
  input         io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0]  io_in_bits_fuOpType,
  input  [63:0] io_in_bits_src_0,
  input  [63:0] io_in_bits_src_1,
  input         io_in_bits_robIdx_flag,
  input  [7:0]  io_in_bits_robIdx_value,
  input  [7:0]  io_in_bits_pdest,
  input         io_in_bits_rfWen,
  input         io_in_bits_perfDebugInfo_eliminatedMove,
  input  [63:0] io_in_bits_perfDebugInfo_renameTime,
  input  [63:0] io_in_bits_perfDebugInfo_dispatchTime,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  input  [63:0] io_in_bits_perfDebugInfo_writebackTime,
  input  [63:0] io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0] io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0] io_in_bits_perfDebugInfo_tlbRespTime,
  input  [55:0] io_in_bits_debug_seqNum_seqNum,
  input  [7:0]  io_in_bits_debug_seqNum_uopIdx,
  input         io_out_ready,
  output        io_out_valid,
  output [63:0] io_out_bits_data_0,
  output [63:0] io_out_bits_data_1,
  output [7:0]  io_out_bits_pdest,
  output        io_out_bits_robIdx_flag,
  output [7:0]  io_out_bits_robIdx_value,
  output        io_out_bits_intWen,
  output        io_out_bits_debugInfo_eliminatedMove,
  output [63:0] io_out_bits_debugInfo_renameTime,
  output [63:0] io_out_bits_debugInfo_dispatchTime,
  output [63:0] io_out_bits_debugInfo_enqRsTime,
  output [63:0] io_out_bits_debugInfo_selectTime,
  output [63:0] io_out_bits_debugInfo_issueTime,
  output [63:0] io_out_bits_debugInfo_writebackTime,
  output [63:0] io_out_bits_debugInfo_runahead_checkpoint_id,
  output [63:0] io_out_bits_debugInfo_tlbFirstReqTime,
  output [63:0] io_out_bits_debugInfo_tlbRespTime,
  output [55:0] io_out_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_bits_debug_seqNum_uopIdx,
  input         cg_bore_cgen,
  input         cg_bore_1_cgen
);

  import exeunit_study_pkg::*;

  uop_ctrl_t in_ctrl_w,  out_ctrl_w;
  perf_t     in_perf_w,  out_perf_w;
  seqnum_t   in_seq_w,   out_seq_w;
  robidx_t   flush_rob_w;
  logic [XLEN-1:0] out_data_w;

  assign in_ctrl_w = '{robIdx: '{flag:  io_in_bits_robIdx_flag,
                                 value: io_in_bits_robIdx_value},
                       pdest:  io_in_bits_pdest,
                       rfWen:  io_in_bits_rfWen};

  assign flush_rob_w = '{flag:  io_flush_bits_robIdx_flag,
                         value: io_flush_bits_robIdx_value};

  assign in_perf_w = '{eliminatedMove:         io_in_bits_perfDebugInfo_eliminatedMove,
                       renameTime:             io_in_bits_perfDebugInfo_renameTime,
                       dispatchTime:           io_in_bits_perfDebugInfo_dispatchTime,
                       enqRsTime:              io_in_bits_perfDebugInfo_enqRsTime,
                       selectTime:             io_in_bits_perfDebugInfo_selectTime,
                       issueTime:              io_in_bits_perfDebugInfo_issueTime,
                       writebackTime:          io_in_bits_perfDebugInfo_writebackTime,
                       runahead_checkpoint_id: io_in_bits_perfDebugInfo_runahead_checkpoint_id,
                       tlbFirstReqTime:        io_in_bits_perfDebugInfo_tlbFirstReqTime,
                       tlbRespTime:            io_in_bits_perfDebugInfo_tlbRespTime};

  assign in_seq_w = '{seqNum: io_in_bits_debug_seqNum_seqNum,
                      uopIdx: io_in_bits_debug_seqNum_uopIdx};

  xs_ExeUnit_study_core u_core (
    .clock        (clock),
    .reset        (reset),
    .flush_valid  (io_flush_valid),
    .flush_robIdx (flush_rob_w),
    .flush_level  (io_flush_bits_level),
    .in_ready     (io_in_ready),
    .in_valid     (io_in_valid),
    .in_fuType    (io_in_bits_fuType),
    .in_fuOpType  (io_in_bits_fuOpType),
    .in_src0      (io_in_bits_src_0),
    .in_src1      (io_in_bits_src_1),
    .in_ctrl      (in_ctrl_w),
    .in_perf      (in_perf_w),
    .in_seqNum    (in_seq_w),
    .out_ready    (io_out_ready),
    .out_valid    (io_out_valid),
    .out_data     (out_data_w),
    .out_ctrl     (out_ctrl_w),
    .out_perf     (out_perf_w),
    .out_seqNum   (out_seq_w),
    .cg_te_mul    (cg_bore_cgen),
    .cg_te_bku    (cg_bore_1_cgen)
  );

  assign io_out_bits_data_0       = out_data_w;
  assign io_out_bits_data_1       = out_data_w;   // 与 data_0 同源，见文件头说明
  assign io_out_bits_pdest        = out_ctrl_w.pdest;
  assign io_out_bits_robIdx_flag  = out_ctrl_w.robIdx.flag;
  assign io_out_bits_robIdx_value = out_ctrl_w.robIdx.value;
  assign io_out_bits_intWen       = out_ctrl_w.rfWen;

  assign io_out_bits_debugInfo_eliminatedMove         = out_perf_w.eliminatedMove;
  assign io_out_bits_debugInfo_renameTime             = out_perf_w.renameTime;
  assign io_out_bits_debugInfo_dispatchTime           = out_perf_w.dispatchTime;
  assign io_out_bits_debugInfo_enqRsTime              = out_perf_w.enqRsTime;
  assign io_out_bits_debugInfo_selectTime             = out_perf_w.selectTime;
  assign io_out_bits_debugInfo_issueTime              = out_perf_w.issueTime;
  assign io_out_bits_debugInfo_writebackTime          = out_perf_w.writebackTime;
  assign io_out_bits_debugInfo_runahead_checkpoint_id = out_perf_w.runahead_checkpoint_id;
  assign io_out_bits_debugInfo_tlbFirstReqTime        = out_perf_w.tlbFirstReqTime;
  assign io_out_bits_debugInfo_tlbRespTime            = out_perf_w.tlbRespTime;
  assign io_out_bits_debug_seqNum_seqNum              = out_seq_w.seqNum;
  assign io_out_bits_debug_seqNum_uopIdx              = out_seq_w.uopIdx;

endmodule
