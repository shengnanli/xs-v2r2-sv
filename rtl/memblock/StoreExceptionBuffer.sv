// =============================================================================
// StoreExceptionBuffer.sv —— StoreQueue 的「最老异常 store」保持器
// -----------------------------------------------------------------------------
// 设计源:XiangShan src/main/scala/xiangshan/mem/lsqueue/StoreQueue.scala
//        class StoreExceptionBuffer
// golden 对照:G1 golden-rtl/StoreExceptionBuffer.sv(1170 行 / 106 端口 / 66 寄存器)
//
// 【它是干什么的】
// store 流水线上任何一级发现异常(缺页、访问错、地址不对齐、断点、SoC 硬件错……)
// 都把出错的 uop 丢进这里。本模块只留**一条**:程序序最老的那条。因为异常要按
// 程序序精确报告,更年轻的异常必然会被这条老的冲掉,留着没用。
// 最后由 io_exceptionAddr_* 把这条的地址信息交给 CSR 填 *tval。
//
//   ★ 没有出队口,也没有清除口 ★
//   保持/替换/清空全部由同一棵"选最老"树决定:每拍把 7 个新来的候选和
//   **当前保持的这条**放在一起比一次,最老的那个成为下一拍的保持值。
//   一个都没有 → valid 自然变 0,这就是"清空";保持值最老 → 选中自己,这就是"保持"。
//
// 【两级入队流水】
//   S1(组合):看输入 valid、按 redirect 冲刷、并且异常向量非零 —— 三者都成立才算候选
//   S2(寄存):把 S1 选中的负载打一拍存下(RegEnable),再按 redirect 冲刷一次
//   然后进选择树。
//
// 【★ 复位域:1 个异步复位 + 65 个完全不复位 ★】
//   异步复位:只有 req_valid 一个。
//   不复位  :req 的 8 个负载字段、s2_valid_REG[7]、以及 50 个 s2 负载寄存器。
//   把那 65 个写成复位是真 bug:elaborate / lint 都不报,只有 FM 抓得到。
//   (Chisel 侧:req_valid 是 RegInit(false.B),req / s2_req 是裸 Reg / RegEnable。)
//
// 【★★ 七个入队口有三种不同形状,照"对称"写就错 ★★】
// 这是本模块最容易写错的地方。父模块 StoreQueue 给各口接的东西不一样,firtool
// 把没接的字段常数折叠掉了,于是 golden 的端口表是不对称的:
//
//   口 0..3(sta s1 / sta s2 重入):15 个信号,**全字段**
//   口 4..5(向量 store)          :14 个信号,★没有 isHyper★ → 模块内恒 0
//   口 6  (SoC 非数据错 / mmio)  : 7 个信号,★只有 exceptionVec 的第 7、19 位★
//                                   且 vaNeedExt 恒 **1**、gpaddr 恒 **0**、
//                                   isHyper 恒 0、isForVSnonLeafPTE 恒 0
//
//   ——对应的**寄存器**也是不对称的(golden 50 个 s2 负载寄存器):
//       uopIdx/robIdx_flag/robIdx_value/fullva  7 个口都有   → 4 × 7 = 28
//       vaNeedExt/gpaddr/isForVSnonLeafPTE      只有口 0..5  → 3 × 6 = 18
//       isHyper                                 只有口 0..3  → 1 × 4 =  4
//   ★给口 4/5 补 isHyper 寄存器、或给口 6 补一整套,就是 6~11 个没人写的死寄存器
//     → FM 判 unread → PARTIAL。★ 所以下面的寄存器数组是**按口数精确开的**,
//     常数字段在进选择树时才补上(§2.4),不占寄存器。
//
//   ★ 注意口 6 的 vaNeedExt 是常数 **1** 而不是 0 ★(父模块接的是 true.B)。
//     其余三个常数字段才是 0。极易写反。
//
// 【★ 与 Chisel 冲突:本仓 XiangShan-v2r2 那份 Scala 不是 G1 的生成源 ★】
//   /home/eda/xs-env/XiangShan-v2r2 里的 StoreExceptionBuffer 是**旧版**:
//     selectOldest(s2_enqueue, s2_req)        —— 只对 7 个新候选建树
//     再用一个单独的 when(req_valid){ req := Mux(...) } 和保持值比
//   而 golden 里 `_reqSel_right_right_oldest_T = s2_valid_6 & reqValid` ——
//   保持值 req 是**树的第 8 片叶子**,在树内部就和 s2_6 比掉了。
//   这与 /home/eda/xs-env/XiangShan 那份新版一致:
//     reqSel = selectOldest(s2_enqueue :+ reqValid, s2_req :+ req)
//   ★以 golden 为准:8 片叶子的树。★ 两者在"同 robIdx 同 uopIdx 平局"等边角上
//   的结论不同,不是可以互换的写法。
//
// 【更新优先级】谁赢:
//   1. 冲刷最高 —— redirect 不参与仲裁,它在**进树之前**就把每片叶子的 valid
//      清掉了(S1 输入、S2 寄存值、保持值三处各清一次)。所以"同拍既来新的又被
//      冲刷"不需要额外仲裁。
//   2. 树内两两比:都有效 → 取**更老**(robIdx 小;robIdx 相同则 uopIdx 小)。
//      ★完全平局(robIdx 与 uopIdx 都相等)→ 取**下标小**的那一片★。
//      只有一个有效 → 取它。都无效 → 取下标大的那片(valid=0,负载无意义)。
//   3. 叶子顺序 = [s2_0 … s2_6, 保持值]。★保持值排在最后★,所以新候选与保持值
//      完全平局时,**新候选赢**。
// =============================================================================

// -----------------------------------------------------------------------------
// §1 尺寸与负载类型
// -----------------------------------------------------------------------------
package store_exception_buffer_pkg;

  // enqPortNum = StorePipelineWidth*2 + VecStorePipelineWidth + 1 = 2*2 + 2 + 1
  localparam int NUM_ENQ = 7;

  // 携带 vaNeedExt / gpaddr / isForVSnonLeafPTE 的入队口数(口 0..5)。
  localparam int N_VA_PORTS = 6;
  // 携带 isHyper 的入队口数(口 0..3)。
  localparam int N_HY_PORTS = 4;

  // 选择树的叶子 = 7 个新候选 + 1 个保持值。
  localparam int NUM_LEAVES = NUM_ENQ + 1;

  localparam int ROB_VAL_W = 8;   // RobPtr.value 位宽
  localparam int UOPIDX_W  = 7;
  localparam int VA_W      = 64;

  // 本模块关心的 6 个 store 异常(ExceptionNO.selectByFu(..., StaCfg) 的结果):
  //   3 breakPoint / 6 storeAddrMisaligned / 7 storeAccessFault
  //   15 storePageFault / 19 hardwareError / 23 storeGuestPageFault
  // 口 6 只可能出 7 与 19 两种,其余 4 位在 wrapper 里恒接 0(见 §3)——
  // 恒 0 进 OR 是纯组合常数折叠,不产生任何寄存器。
  localparam int NUM_EXC = 6;

  // 循环队列指针(RobPtr):flag 是环绕位。
  typedef struct packed {
    logic                 flag;
    logic [ROB_VAL_W-1:0] value;
  } robptr_t;

  // 一条候选的全部负载。golden 把它摊平成独立寄存器;这里打包只改可读性,
  // 不改寄存器集合 —— 真正的寄存器在 §2.3 按口数精确开。
  typedef struct packed {
    logic [UOPIDX_W-1:0] uopIdx;
    robptr_t             robIdx;
    logic [VA_W-1:0]     fullva;
    logic                vaNeedExt;
    logic [VA_W-1:0]     gpaddr;
    logic                isHyper;
    logic                isForVSnonLeafPTE;
  } req_t;

  // 树里流动的 (valid, bits) 对。
  typedef struct packed {
    logic  valid;
    req_t  bits;
  } vreq_t;

  // a 是否**晚于** b(循环指针比较,CircularQueuePtr 的 `>`)。
  // 环绕位不同时比较结果要翻转,于是三项异或。
  function automatic logic is_after(input robptr_t a, input robptr_t b);
    is_after = a.flag ^ b.flag ^ (a.value > b.value);
  endfunction

  // 两两取更老者。★平局取 a(下标小的那片)★。
  function automatic vreq_t pick_older(input vreq_t a, input vreq_t b);
    logic a_younger;
    // a 比 b 年轻:robIdx 更晚,或 robIdx 相同而 uopIdx 更大(同一条指令的后续 uop)
    a_younger = is_after(a.bits.robIdx, b.bits.robIdx)
                | ((a.bits.robIdx == b.bits.robIdx) & (a.bits.uopIdx > b.bits.uopIdx));
    if (a.valid & b.valid)      pick_older = a_younger ? b : a;
    else if (a.valid & ~b.valid) pick_older = a;
    else                         pick_older = b;   // b 可能也无效,那就整体无效
  endfunction

endpackage

// -----------------------------------------------------------------------------
// §2 xs_StoreExceptionBuffer_core —— 可读核
// -----------------------------------------------------------------------------
module xs_StoreExceptionBuffer_core
  import store_exception_buffer_pkg::*;
(
  input  logic                  clock,
  input  logic                  reset,

  // 冲刷
  input  logic                  redirect_valid,
  input  robptr_t               redirect_robIdx,
  input  logic                  redirect_level,   // level[0] = flushItself

  // 入队(7 口;★三种形状,数组按实际携带该字段的口数开★ —— 见文件头)
  input  logic                  in_valid   [NUM_ENQ],
  input  logic [NUM_EXC-1:0]    in_excVec  [NUM_ENQ],
  input  logic [UOPIDX_W-1:0]   in_uopIdx  [NUM_ENQ],
  input  robptr_t               in_robIdx  [NUM_ENQ],
  input  logic [VA_W-1:0]       in_fullva  [NUM_ENQ],
  input  logic                  in_vaNeedExt         [N_VA_PORTS],
  input  logic [VA_W-1:0]       in_gpaddr            [N_VA_PORTS],
  input  logic                  in_isForVSnonLeafPTE [N_VA_PORTS],
  input  logic                  in_isHyper           [N_HY_PORTS],

  // 输出:当前保持的那条异常 store 的地址信息
  output logic [VA_W-1:0]       exceptionAddr_vaddr,
  output logic                  exceptionAddr_vaNeedExt,
  output logic                  exceptionAddr_isHyper,
  output logic [VA_W-1:0]       exceptionAddr_gpaddr,
  output logic                  exceptionAddr_isForVSnonLeafPTE
);

  // ---------------------------------------------------------------------------
  // §2.1 冲刷判定(RobBundles.scala needFlush)
  // ---------------------------------------------------------------------------
  // 一条 uop 要被冲刷 = 重定向有效,且 (它就是触发重定向那条且该重定向"连自己一起冲"
  // || 它比触发点更年轻)。
  //
  // ★ redirect 的三个字段必须当**入参**传进来,不许在函数体里直接读模块信号 ★
  //   读非局部变量的函数会被 Formality 判 FMR_VLOG-091(可能仿真/综合不一致)并
  //   拒绝 link(FM-262 → set_top 失败 FM-156)。实测踩过一次:第一版写成读
  //   redirect_valid / redirect_level / redirect_robIdx,FM 直接起不来。
  //   正确的修法是把函数写成纯函数,不是去抑制那条消息。
  function automatic logic need_flush(input robptr_t p,
                                      input logic    rd_valid,
                                      input logic    rd_level,
                                      input robptr_t rd_robIdx);
    need_flush = rd_valid & ((rd_level & (p == rd_robIdx)) | is_after(p, rd_robIdx));
  endfunction

  // ---------------------------------------------------------------------------
  // §2.2 S1:组合筛选
  // ---------------------------------------------------------------------------
  // 三个条件同时成立才是候选:输入有效、没被冲刷、异常向量非零。
  // (异常向量为零说明这一拍这条口根本没异常,不该占位。)
  logic s1_valid [NUM_ENQ];
  always_comb
    for (int p = 0; p < NUM_ENQ; p++)
      s1_valid[p] = in_valid[p] & ~need_flush(in_robIdx[p], redirect_valid, redirect_level, redirect_robIdx) & (|in_excVec[p]);

  // ---------------------------------------------------------------------------
  // §2.3 S2:打一拍(★全部不复位;数组按口数精确开★)
  // ---------------------------------------------------------------------------
  logic                s2_valid_r  [NUM_ENQ];     // RegNext(s1_valid)
  logic [UOPIDX_W-1:0] s2_uopIdx   [NUM_ENQ];
  robptr_t             s2_robIdx   [NUM_ENQ];
  logic [VA_W-1:0]     s2_fullva   [NUM_ENQ];
  logic                s2_vaNeedExt         [N_VA_PORTS];
  logic [VA_W-1:0]     s2_gpaddr            [N_VA_PORTS];
  logic                s2_isForVSnonLeafPTE [N_VA_PORTS];
  logic                s2_isHyper           [N_HY_PORTS];

  always_ff @(posedge clock) begin
    for (int p = 0; p < NUM_ENQ; p++) begin
      s2_valid_r[p] <= s1_valid[p];
      if (s1_valid[p]) begin
        s2_uopIdx[p] <= in_uopIdx[p];
        s2_robIdx[p] <= in_robIdx[p];
        s2_fullva[p] <= in_fullva[p];
      end
    end
    for (int p = 0; p < N_VA_PORTS; p++)
      if (s1_valid[p]) begin
        s2_vaNeedExt[p]         <= in_vaNeedExt[p];
        s2_gpaddr[p]            <= in_gpaddr[p];
        s2_isForVSnonLeafPTE[p] <= in_isForVSnonLeafPTE[p];
      end
    for (int p = 0; p < N_HY_PORTS; p++)
      if (s1_valid[p]) s2_isHyper[p] <= in_isHyper[p];
  end

  // ---------------------------------------------------------------------------
  // §2.4 保持值 + 组装 8 片叶子
  // ---------------------------------------------------------------------------
  logic  req_valid;       // ★本模块唯一的异步复位寄存器★
  req_t  req;             // ★不复位★

  vreq_t leaf [NUM_LEAVES];

  always_comb begin
    for (int p = 0; p < NUM_ENQ; p++) begin
      // S2 的寄存值再按当前 redirect 冲一次:它可能是上一拍存下、这一拍才被冲掉的。
      leaf[p].valid            = s2_valid_r[p] & ~need_flush(s2_robIdx[p], redirect_valid, redirect_level, redirect_robIdx);
      leaf[p].bits.uopIdx      = s2_uopIdx[p];
      leaf[p].bits.robIdx      = s2_robIdx[p];
      leaf[p].bits.fullva      = s2_fullva[p];

      // ★ 常数字段在这里补,不占寄存器 ★(见文件头)。
      if (p < N_VA_PORTS) begin
        leaf[p].bits.vaNeedExt         = s2_vaNeedExt[p];
        leaf[p].bits.gpaddr            = s2_gpaddr[p];
        leaf[p].bits.isForVSnonLeafPTE = s2_isForVSnonLeafPTE[p];
      end else begin
        // 口 6(SoC 非数据错):父模块把 vaNeedExt 接了 true.B,其余是 DontCare→0。
        leaf[p].bits.vaNeedExt         = 1'b1;    // ★是 1,不是 0★
        leaf[p].bits.gpaddr            = '0;
        leaf[p].bits.isForVSnonLeafPTE = 1'b0;
      end

      // 口 4/5(向量 store)与口 6 都没有 isHyper,父模块 DontCare → 折叠成 0。
      leaf[p].bits.isHyper = (p < N_HY_PORTS) ? s2_isHyper[p] : 1'b0;
    end

    // ★第 8 片叶子 = 当前保持值★,同样先按 redirect 冲一次。
    // 它排在最后,所以与新候选完全平局时新候选赢(见文件头【更新优先级】)。
    leaf[NUM_ENQ].valid = req_valid & ~need_flush(req.robIdx, redirect_valid, redirect_level, redirect_robIdx);
    leaf[NUM_ENQ].bits  = req;
  end

  // ---------------------------------------------------------------------------
  // §2.5 选最老:8 片叶子的平衡二叉树
  // ---------------------------------------------------------------------------
  // 树形来自 Chisel selectOldest 的 take(n/2) / takeRight(n-n/2) 递归:
  //     ((0,1),(2,3)) 与 ((4,5),(6,保持值)) 先各自归约,再合并。
  // 必须照这个形状写:pick_older 的平局规则取"下标小者",不同的结合方式会在
  // 多路平局时选出不同的叶子。
  vreq_t sel_l0, sel_l1, sel_left;
  vreq_t sel_r0, sel_r1, sel_right;
  vreq_t sel;

  always_comb begin
    sel_l0    = pick_older(leaf[0], leaf[1]);
    sel_l1    = pick_older(leaf[2], leaf[3]);
    sel_left  = pick_older(sel_l0,  sel_l1);
    sel_r0    = pick_older(leaf[4], leaf[5]);
    sel_r1    = pick_older(leaf[6], leaf[7]);
    sel_right = pick_older(sel_r0,  sel_r1);
    sel       = pick_older(sel_left, sel_right);
  end

  // ---------------------------------------------------------------------------
  // §2.6 时序
  // ---------------------------------------------------------------------------
  // 无条件写回树的结果 —— "保持"和"清空"都已经包含在树里了(见文件头)。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) req_valid <= 1'b0;
    else       req_valid <= sel.valid;
  end

  always_ff @(posedge clock) req <= sel.bits;   // ★不复位★

  // ---------------------------------------------------------------------------
  // §2.7 输出(纯寄存器抽头)
  // ---------------------------------------------------------------------------
  // 注意 golden **没有** vstart / vl / isStore 输出端口:Chisel 里有,但父模块
  // 不消费,被 firtool 连同背后的寄存器一起 DCE 了。补上就是多出没人读的寄存器。
  assign exceptionAddr_vaddr             = req.fullva;
  assign exceptionAddr_vaNeedExt         = req.vaNeedExt;
  assign exceptionAddr_isHyper           = req.isHyper;
  assign exceptionAddr_gpaddr            = req.gpaddr;
  assign exceptionAddr_isForVSnonLeafPTE = req.isForVSnonLeafPTE;

endmodule

// -----------------------------------------------------------------------------
// §3 StoreExceptionBuffer —— golden 同名薄 wrapper
// -----------------------------------------------------------------------------
// 端口名/顺序/位宽逐位对齐 G1 golden。★三种入队口形状在这里体现★:
//   口 4/5 没有 isHyper 端口;口 6 只有 7 个信号。
// 缺失的**异常位**在这里补 0(纯组合常数折叠进 OR,不产生寄存器);
// 缺失的**负载字段**根本不传给核,由核内部补常数(§2.4),这样才不会多出死寄存器。

module StoreExceptionBuffer(
  input         clock,
  input         reset,
  input         io_redirect_valid,
  input         io_redirect_bits_robIdx_flag,
  input  [7:0]  io_redirect_bits_robIdx_value,
  input         io_redirect_bits_level,
  input         io_storeAddrIn_0_valid,
  input         io_storeAddrIn_0_bits_uop_exceptionVec_3,
  input         io_storeAddrIn_0_bits_uop_exceptionVec_6,
  input         io_storeAddrIn_0_bits_uop_exceptionVec_7,
  input         io_storeAddrIn_0_bits_uop_exceptionVec_15,
  input         io_storeAddrIn_0_bits_uop_exceptionVec_19,
  input         io_storeAddrIn_0_bits_uop_exceptionVec_23,
  input  [6:0]  io_storeAddrIn_0_bits_uop_uopIdx,
  input         io_storeAddrIn_0_bits_uop_robIdx_flag,
  input  [7:0]  io_storeAddrIn_0_bits_uop_robIdx_value,
  input  [63:0] io_storeAddrIn_0_bits_fullva,
  input         io_storeAddrIn_0_bits_vaNeedExt,
  input  [63:0] io_storeAddrIn_0_bits_gpaddr,
  input         io_storeAddrIn_0_bits_isHyper,
  input         io_storeAddrIn_0_bits_isForVSnonLeafPTE,
  input         io_storeAddrIn_1_valid,
  input         io_storeAddrIn_1_bits_uop_exceptionVec_3,
  input         io_storeAddrIn_1_bits_uop_exceptionVec_6,
  input         io_storeAddrIn_1_bits_uop_exceptionVec_7,
  input         io_storeAddrIn_1_bits_uop_exceptionVec_15,
  input         io_storeAddrIn_1_bits_uop_exceptionVec_19,
  input         io_storeAddrIn_1_bits_uop_exceptionVec_23,
  input  [6:0]  io_storeAddrIn_1_bits_uop_uopIdx,
  input         io_storeAddrIn_1_bits_uop_robIdx_flag,
  input  [7:0]  io_storeAddrIn_1_bits_uop_robIdx_value,
  input  [63:0] io_storeAddrIn_1_bits_fullva,
  input         io_storeAddrIn_1_bits_vaNeedExt,
  input  [63:0] io_storeAddrIn_1_bits_gpaddr,
  input         io_storeAddrIn_1_bits_isHyper,
  input         io_storeAddrIn_1_bits_isForVSnonLeafPTE,
  input         io_storeAddrIn_2_valid,
  input         io_storeAddrIn_2_bits_uop_exceptionVec_3,
  input         io_storeAddrIn_2_bits_uop_exceptionVec_6,
  input         io_storeAddrIn_2_bits_uop_exceptionVec_7,
  input         io_storeAddrIn_2_bits_uop_exceptionVec_15,
  input         io_storeAddrIn_2_bits_uop_exceptionVec_19,
  input         io_storeAddrIn_2_bits_uop_exceptionVec_23,
  input  [6:0]  io_storeAddrIn_2_bits_uop_uopIdx,
  input         io_storeAddrIn_2_bits_uop_robIdx_flag,
  input  [7:0]  io_storeAddrIn_2_bits_uop_robIdx_value,
  input  [63:0] io_storeAddrIn_2_bits_fullva,
  input         io_storeAddrIn_2_bits_vaNeedExt,
  input  [63:0] io_storeAddrIn_2_bits_gpaddr,
  input         io_storeAddrIn_2_bits_isHyper,
  input         io_storeAddrIn_2_bits_isForVSnonLeafPTE,
  input         io_storeAddrIn_3_valid,
  input         io_storeAddrIn_3_bits_uop_exceptionVec_3,
  input         io_storeAddrIn_3_bits_uop_exceptionVec_6,
  input         io_storeAddrIn_3_bits_uop_exceptionVec_7,
  input         io_storeAddrIn_3_bits_uop_exceptionVec_15,
  input         io_storeAddrIn_3_bits_uop_exceptionVec_19,
  input         io_storeAddrIn_3_bits_uop_exceptionVec_23,
  input  [6:0]  io_storeAddrIn_3_bits_uop_uopIdx,
  input         io_storeAddrIn_3_bits_uop_robIdx_flag,
  input  [7:0]  io_storeAddrIn_3_bits_uop_robIdx_value,
  input  [63:0] io_storeAddrIn_3_bits_fullva,
  input         io_storeAddrIn_3_bits_vaNeedExt,
  input  [63:0] io_storeAddrIn_3_bits_gpaddr,
  input         io_storeAddrIn_3_bits_isHyper,
  input         io_storeAddrIn_3_bits_isForVSnonLeafPTE,
  input         io_storeAddrIn_4_valid,
  input         io_storeAddrIn_4_bits_uop_exceptionVec_3,
  input         io_storeAddrIn_4_bits_uop_exceptionVec_6,
  input         io_storeAddrIn_4_bits_uop_exceptionVec_7,
  input         io_storeAddrIn_4_bits_uop_exceptionVec_15,
  input         io_storeAddrIn_4_bits_uop_exceptionVec_19,
  input         io_storeAddrIn_4_bits_uop_exceptionVec_23,
  input  [6:0]  io_storeAddrIn_4_bits_uop_uopIdx,
  input         io_storeAddrIn_4_bits_uop_robIdx_flag,
  input  [7:0]  io_storeAddrIn_4_bits_uop_robIdx_value,
  input  [63:0] io_storeAddrIn_4_bits_fullva,
  input         io_storeAddrIn_4_bits_vaNeedExt,
  input  [63:0] io_storeAddrIn_4_bits_gpaddr,
  input         io_storeAddrIn_4_bits_isForVSnonLeafPTE,
  input         io_storeAddrIn_5_valid,
  input         io_storeAddrIn_5_bits_uop_exceptionVec_3,
  input         io_storeAddrIn_5_bits_uop_exceptionVec_6,
  input         io_storeAddrIn_5_bits_uop_exceptionVec_7,
  input         io_storeAddrIn_5_bits_uop_exceptionVec_15,
  input         io_storeAddrIn_5_bits_uop_exceptionVec_19,
  input         io_storeAddrIn_5_bits_uop_exceptionVec_23,
  input  [6:0]  io_storeAddrIn_5_bits_uop_uopIdx,
  input         io_storeAddrIn_5_bits_uop_robIdx_flag,
  input  [7:0]  io_storeAddrIn_5_bits_uop_robIdx_value,
  input  [63:0] io_storeAddrIn_5_bits_fullva,
  input         io_storeAddrIn_5_bits_vaNeedExt,
  input  [63:0] io_storeAddrIn_5_bits_gpaddr,
  input         io_storeAddrIn_5_bits_isForVSnonLeafPTE,
  input         io_storeAddrIn_6_valid,
  input         io_storeAddrIn_6_bits_uop_exceptionVec_7,
  input         io_storeAddrIn_6_bits_uop_exceptionVec_19,
  input  [6:0]  io_storeAddrIn_6_bits_uop_uopIdx,
  input         io_storeAddrIn_6_bits_uop_robIdx_flag,
  input  [7:0]  io_storeAddrIn_6_bits_uop_robIdx_value,
  input  [63:0] io_storeAddrIn_6_bits_fullva,
  output [63:0] io_exceptionAddr_vaddr,
  output        io_exceptionAddr_vaNeedExt,
  output        io_exceptionAddr_isHyper,
  output [63:0] io_exceptionAddr_gpaddr,
  output        io_exceptionAddr_isForVSnonLeafPTE
);

  import store_exception_buffer_pkg::*;

  logic        in_valid   [NUM_ENQ];
  logic [5:0]  in_excVec  [NUM_ENQ];
  logic [6:0]  in_uopIdx  [NUM_ENQ];
  robptr_t     in_robIdx  [NUM_ENQ];
  logic [63:0] in_fullva  [NUM_ENQ];
  logic        in_vaNeedExt         [N_VA_PORTS];
  logic [63:0] in_gpaddr            [N_VA_PORTS];
  logic        in_isForVSnonLeafPTE [N_VA_PORTS];
  logic        in_isHyper           [N_HY_PORTS];

  always_comb begin
    in_valid[0]  = io_storeAddrIn_0_valid;
    in_excVec[0] = {io_storeAddrIn_0_bits_uop_exceptionVec_23, io_storeAddrIn_0_bits_uop_exceptionVec_19, io_storeAddrIn_0_bits_uop_exceptionVec_15, io_storeAddrIn_0_bits_uop_exceptionVec_7, io_storeAddrIn_0_bits_uop_exceptionVec_6, io_storeAddrIn_0_bits_uop_exceptionVec_3};
    in_uopIdx[0] = io_storeAddrIn_0_bits_uop_uopIdx;
    in_robIdx[0] = '{flag: io_storeAddrIn_0_bits_uop_robIdx_flag,
                      value: io_storeAddrIn_0_bits_uop_robIdx_value};
    in_fullva[0] = io_storeAddrIn_0_bits_fullva;
    in_vaNeedExt[0]         = io_storeAddrIn_0_bits_vaNeedExt;
    in_gpaddr[0]            = io_storeAddrIn_0_bits_gpaddr;
    in_isForVSnonLeafPTE[0] = io_storeAddrIn_0_bits_isForVSnonLeafPTE;
    in_isHyper[0]           = io_storeAddrIn_0_bits_isHyper;

    in_valid[1]  = io_storeAddrIn_1_valid;
    in_excVec[1] = {io_storeAddrIn_1_bits_uop_exceptionVec_23, io_storeAddrIn_1_bits_uop_exceptionVec_19, io_storeAddrIn_1_bits_uop_exceptionVec_15, io_storeAddrIn_1_bits_uop_exceptionVec_7, io_storeAddrIn_1_bits_uop_exceptionVec_6, io_storeAddrIn_1_bits_uop_exceptionVec_3};
    in_uopIdx[1] = io_storeAddrIn_1_bits_uop_uopIdx;
    in_robIdx[1] = '{flag: io_storeAddrIn_1_bits_uop_robIdx_flag,
                      value: io_storeAddrIn_1_bits_uop_robIdx_value};
    in_fullva[1] = io_storeAddrIn_1_bits_fullva;
    in_vaNeedExt[1]         = io_storeAddrIn_1_bits_vaNeedExt;
    in_gpaddr[1]            = io_storeAddrIn_1_bits_gpaddr;
    in_isForVSnonLeafPTE[1] = io_storeAddrIn_1_bits_isForVSnonLeafPTE;
    in_isHyper[1]           = io_storeAddrIn_1_bits_isHyper;

    in_valid[2]  = io_storeAddrIn_2_valid;
    in_excVec[2] = {io_storeAddrIn_2_bits_uop_exceptionVec_23, io_storeAddrIn_2_bits_uop_exceptionVec_19, io_storeAddrIn_2_bits_uop_exceptionVec_15, io_storeAddrIn_2_bits_uop_exceptionVec_7, io_storeAddrIn_2_bits_uop_exceptionVec_6, io_storeAddrIn_2_bits_uop_exceptionVec_3};
    in_uopIdx[2] = io_storeAddrIn_2_bits_uop_uopIdx;
    in_robIdx[2] = '{flag: io_storeAddrIn_2_bits_uop_robIdx_flag,
                      value: io_storeAddrIn_2_bits_uop_robIdx_value};
    in_fullva[2] = io_storeAddrIn_2_bits_fullva;
    in_vaNeedExt[2]         = io_storeAddrIn_2_bits_vaNeedExt;
    in_gpaddr[2]            = io_storeAddrIn_2_bits_gpaddr;
    in_isForVSnonLeafPTE[2] = io_storeAddrIn_2_bits_isForVSnonLeafPTE;
    in_isHyper[2]           = io_storeAddrIn_2_bits_isHyper;

    in_valid[3]  = io_storeAddrIn_3_valid;
    in_excVec[3] = {io_storeAddrIn_3_bits_uop_exceptionVec_23, io_storeAddrIn_3_bits_uop_exceptionVec_19, io_storeAddrIn_3_bits_uop_exceptionVec_15, io_storeAddrIn_3_bits_uop_exceptionVec_7, io_storeAddrIn_3_bits_uop_exceptionVec_6, io_storeAddrIn_3_bits_uop_exceptionVec_3};
    in_uopIdx[3] = io_storeAddrIn_3_bits_uop_uopIdx;
    in_robIdx[3] = '{flag: io_storeAddrIn_3_bits_uop_robIdx_flag,
                      value: io_storeAddrIn_3_bits_uop_robIdx_value};
    in_fullva[3] = io_storeAddrIn_3_bits_fullva;
    in_vaNeedExt[3]         = io_storeAddrIn_3_bits_vaNeedExt;
    in_gpaddr[3]            = io_storeAddrIn_3_bits_gpaddr;
    in_isForVSnonLeafPTE[3] = io_storeAddrIn_3_bits_isForVSnonLeafPTE;
    in_isHyper[3]           = io_storeAddrIn_3_bits_isHyper;

    in_valid[4]  = io_storeAddrIn_4_valid;
    in_excVec[4] = {io_storeAddrIn_4_bits_uop_exceptionVec_23, io_storeAddrIn_4_bits_uop_exceptionVec_19, io_storeAddrIn_4_bits_uop_exceptionVec_15, io_storeAddrIn_4_bits_uop_exceptionVec_7, io_storeAddrIn_4_bits_uop_exceptionVec_6, io_storeAddrIn_4_bits_uop_exceptionVec_3};
    in_uopIdx[4] = io_storeAddrIn_4_bits_uop_uopIdx;
    in_robIdx[4] = '{flag: io_storeAddrIn_4_bits_uop_robIdx_flag,
                      value: io_storeAddrIn_4_bits_uop_robIdx_value};
    in_fullva[4] = io_storeAddrIn_4_bits_fullva;
    in_vaNeedExt[4]         = io_storeAddrIn_4_bits_vaNeedExt;
    in_gpaddr[4]            = io_storeAddrIn_4_bits_gpaddr;
    in_isForVSnonLeafPTE[4] = io_storeAddrIn_4_bits_isForVSnonLeafPTE;

    in_valid[5]  = io_storeAddrIn_5_valid;
    in_excVec[5] = {io_storeAddrIn_5_bits_uop_exceptionVec_23, io_storeAddrIn_5_bits_uop_exceptionVec_19, io_storeAddrIn_5_bits_uop_exceptionVec_15, io_storeAddrIn_5_bits_uop_exceptionVec_7, io_storeAddrIn_5_bits_uop_exceptionVec_6, io_storeAddrIn_5_bits_uop_exceptionVec_3};
    in_uopIdx[5] = io_storeAddrIn_5_bits_uop_uopIdx;
    in_robIdx[5] = '{flag: io_storeAddrIn_5_bits_uop_robIdx_flag,
                      value: io_storeAddrIn_5_bits_uop_robIdx_value};
    in_fullva[5] = io_storeAddrIn_5_bits_fullva;
    in_vaNeedExt[5]         = io_storeAddrIn_5_bits_vaNeedExt;
    in_gpaddr[5]            = io_storeAddrIn_5_bits_gpaddr;
    in_isForVSnonLeafPTE[5] = io_storeAddrIn_5_bits_isForVSnonLeafPTE;

    in_valid[6]  = io_storeAddrIn_6_valid;
    // ★口 6 只有第 7、19 位★,其余 4 位恒 0(纯常数折叠,不产生寄存器)
    in_excVec[6] = {1'b0, io_storeAddrIn_6_bits_uop_exceptionVec_19, 1'b0, io_storeAddrIn_6_bits_uop_exceptionVec_7, 1'b0, 1'b0};
    in_uopIdx[6] = io_storeAddrIn_6_bits_uop_uopIdx;
    in_robIdx[6] = '{flag: io_storeAddrIn_6_bits_uop_robIdx_flag,
                      value: io_storeAddrIn_6_bits_uop_robIdx_value};
    in_fullva[6] = io_storeAddrIn_6_bits_fullva;

  end

  xs_StoreExceptionBuffer_core u_core (
    .clock                (clock),
    .reset                (reset),
    .redirect_valid       (io_redirect_valid),
    .redirect_robIdx      ('{flag:  io_redirect_bits_robIdx_flag,
                             value: io_redirect_bits_robIdx_value}),
    .redirect_level       (io_redirect_bits_level),
    .in_valid             (in_valid),
    .in_excVec            (in_excVec),
    .in_uopIdx            (in_uopIdx),
    .in_robIdx            (in_robIdx),
    .in_fullva            (in_fullva),
    .in_vaNeedExt         (in_vaNeedExt),
    .in_gpaddr            (in_gpaddr),
    .in_isForVSnonLeafPTE (in_isForVSnonLeafPTE),
    .in_isHyper           (in_isHyper),
    .exceptionAddr_vaddr             (io_exceptionAddr_vaddr),
    .exceptionAddr_vaNeedExt         (io_exceptionAddr_vaNeedExt),
    .exceptionAddr_isHyper           (io_exceptionAddr_isHyper),
    .exceptionAddr_gpaddr            (io_exceptionAddr_gpaddr),
    .exceptionAddr_isForVSnonLeafPTE (io_exceptionAddr_isForVSnonLeafPTE)
  );

endmodule
