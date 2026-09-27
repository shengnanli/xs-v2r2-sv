// CtrlBlock.sv —— 后端控制块：译码/重命名/派遣/ROB 的装配层，外加把它们粘起来的那一层真时序 glue。
//
// 在哪一层：Backend 里的"控制平面"顶层。前端送来的指令流（cfVec）从这里进译码，
// 经 6 条 decode→rename 流水缓冲、rename→dispatch 成组缓冲进入 NewDispatch，
// 最后入队 Rob；各执行单元的 27 路写回（fromWB）在这里打一拍再送 Rob；
// 所有重定向（Rob flush / 执行单元跳转失败 / load 违例）在这里排序、打拍、广播。
//
// 核心机制（读本文件按这个顺序）：
//   1. **重定向流水** s0→s1→s3→s4→s5：Rob 的 flushOut 打一拍成 s1；与 RedirectGenerator
//      的 stage2Redirect 二选一成 s1_s3（Rob flush 优先）；再打两拍成 s2_s4（发给 IssueBlock/
//      DataPath/ExuBlock 的 flush）与 s3_s5。发往前端 FTQ 的 flush 比 Rob flush 晚 6 拍
//      （DelayN(4)+两个 RegNext），期间 CSR 已算出 trapTarget。
//   2. **写回打拍与压缩**：27 路 ExuOutput 逐路 RegEnable 一拍；valid 用"没被更老的重定向
//      冲掉"过滤；同一 robIdx 在同一拍写回的路数（PopCount）也打一拍给 Rob 做 uopNum 递减。
//      ★golden 每路只保留 Rob 真消费的字段（firtool DCE 逐路窄化），本文件用 WB_LANE 描述表
//      + generate-if 逐路复现同一套寄存器集合，一位不多一位不少★。
//   3. **译码缓冲（decode buffer）**：decode 不能全收时把没收下的指令暂存 6 项寄存器，
//      按"第一个未接收位置"整体前移；下一拍优先喂缓冲里的指令。
//   4. **快照（snapshot）**：rename 出口标了 snapshot 的 uop 让 SnapshotGenerator 记一份
//      RobPtr 组；重定向时算 useSnpt / snptSelect / flushVec 通知 Rob/RAT/Rename 回滚。
//   5. **融合译码（fusion）**：FusionDecoder 判定相邻两条可融合时改写 rename 入口的
//      fuType/fuOpType/lsrc/selImm/commitType，并让 decode 清掉第二条。
//   6. **pcMem 读口分配**：15 个读口按 NamedIndexes 固定编号：
//      0 redirect(load违例) / 1 memPred / 2 robFlush / 3..5 bju pc / 6..8 bju target(ptr+1)
//      / 9..11 load / 12..14 trace。
//
// 结构（单文件规范）：
//   ctrlblock_pkg     —— 本模块私有类型：与 Chisel Bundle 同构的 packed struct（只含 golden
//                        真保留的字段）、27 路写回 lane 的字段保留描述表 WB_LANE。
//   xs_CtrlBlock_core —— 可读核：全部 glue 时序与组合逻辑，端口是 struct/数组。
//   CtrlBlock         —— golden 同名 wrapper：8288 个扁平端口 + 22 个 child 实例 + u_core，
//                        由 scripts/gen_ctrlblock.py 从 golden 端口表/例化表机械生成
//                        （`// BEGIN GENERATED(...)` .. `// END GENERATED`），手写区不碰。
//
// 子模块处置（FM 边界，见 verif/allow/CtrlBlock.json）：
//   · Rob：两侧白盒（ref 用 golden Rob.sv，impl 用 rtl/backend/Rob.sv 重写件）——CtrlBlock 是
//     Rob 那 448 位 debug_otherPdest 悬空输出的第一个可观测边界（golden 把它们接成 unused）。
//   · 已签核绿的 child（pcMem/snpt/DelayN×3/PipelineConnectPipe×6/PipeGroupConnect）：两侧对称
//     黑盒，allow 记 green_child（证书等 freeze 铸）。
//   · 仍由别的 lane 重写中的 child（DecodeStage/FusionDecoder/Rename/RenameTableWrapper/
//     RedirectGenerator/Trace/MemCtrl/GPAMem/NewDispatch）：两侧同源 golden elaborate
//     （UNCHANGED_GOLDEN_DEP，对本目标零信息量，如实记）。
//   · 三个 firtool 行为级存储叶子（dt_pcTransType_160x2 / diff_rat_state_bank_320x776 /
//     stateBankTags_320x3，深度非 2 的幂，inline 必触发 FMR_ELAB-147）：两侧对称接口黑盒。
//
// golden 怪癖清单（bug-for-bug 照抄，每条在代码处再注一次）：
//   Q1 s1_s3 二选一时，Rob flush 没有的字段（cfiUpdate.* 等）取 0，不是取 redirectGen 的值。
//   Q2 decode buffer 的向量下标 i+acceptNum 越界（6、7）时 firtool 展开成"取第 0 项"，不是 0。
//   Q3 snptSelect 是 MuxCase(enqPtr-1, enqPtr-2, enqPtr+1(=enqPtr-3), enqPtr)，2 位指针回绕。
//   Q4 融合改写的 fuType 是常量 35'h80（ALU），fuOpType 来自 FusionDecoder。
//   Q5 enqRob.req 的 debugInfo.*Time / lqIdx / sqIdx 装的是常量 0（NewDispatch 没这些出口），
//      lane1..5 的 snapshot 与全部 lane 的 replayInst 也是"valid 拍装 0"的 hold-clear 寄存器。
//   Q6 GTimer() 每次调用各生一个 64 位自由计数器：25 路写回各自一个 writebackTime 计数器。
//   Q7 toVecExcpMod.ratOldPest 的 pdest 寄存器是 8 位，输出只取 [6:0]（第 7 位是两侧对称死位）。
//   Q8 toFtq.ftqIdxAhead 只剩第 0 路（exu 重定向），loadReplay/异常两路及 ftqIdxSelOH.valid
//      在 golden 里被 DCE 掉，没有端口。
//   Q9 io_perf 编号跳过 42（65 个 perf 口 0..65 缺 42），wrapper 按 golden 端口名逐个接。
//   Q10 trigger 编码：TriggerAction.None = 4'hF，DebugMode = 4'h1。
//
// 对照：/home/eda/xs-env/XiangShan/src/main/scala/xiangshan/backend/CtrlBlock.scala（设计意图）
//       /home/eda/xs-env/G1-canonical/golden-rtl/CtrlBlock.sv（唯一判据）
//
// ============================================================================
// 私有类型包
// ============================================================================
package ctrlblock_pkg;

  // ---- 基本参数（KunminghuV2Config） ----
  localparam int DECODE_W   = 6;    // DecodeWidth = RenameWidth
  localparam int COMMIT_W   = 8;    // CommitWidth
  localparam int RAB_W      = 6;    // RabCommitWidth
  localparam int WB_N       = 27;   // 写回口数（params.genWrite2CtrlBundles）
  localparam int WB_NUM_W   = 5;    // Rob.io.writebackNums 位宽 = log2Up(27+1)
  localparam int EXU_REDIR_N = 4;   // 带 redirect 的写回口（lane 1/3/5/7 = BJU×3 + CSR）
  localparam int NEED_EXC_N = 13;   // needExceptionGen 的写回口数（lane 7,13..24）
  localparam int SNPT_N     = 4;    // RenameSnapshotNum
  localparam int PCMEM_RD_N = 15;   // pcMem 读口数（NamedIndexes 总和）
  localparam int BRH_N      = 3;    // BrhCnt（bju pc / bju target 各 3 个读口）
  localparam int LDU_N      = 3;    // LduCnt（load 读口）
  localparam int TRACE_GRP  = 3;    // TraceGroupNum
  localparam int MDP_N      = 2;    // memCtrl.mdpFoldPcVec 的路数（golden 只保留 2 路）
  localparam int PERF_N     = 65;   // io_perf 口数（编号 0..65 缺 42，见 Q9）
  localparam int VADDR_W    = 50;
  localparam int XLEN       = 64;
  localparam int EXC_N      = 24;   // ExceptionVec 位数
  localparam int PREG_W     = 8;    // PhyRegIdxWidth
  localparam int TRIGGER_NONE  = 4'hF;   // TriggerAction.None
  localparam int TRIGGER_DMODE = 4'h1;   // TriggerAction.DebugMode

  // pcMem 读口编号（NamedIndexes，顺序 = Chisel 里 Seq 的顺序）
  localparam int PCRD_REDIRECT = 0;
  localparam int PCRD_MEMPRED  = 1;
  localparam int PCRD_ROBFLUSH = 2;
  localparam int PCRD_BJU_PC   = 3;   // 3..5
  localparam int PCRD_BJU_TGT  = 6;   // 6..8
  localparam int PCRD_LOAD     = 9;   // 9..11
  localparam int PCRD_TRACE    = 12;  // 12..14

  // ---- 循环队列指针 ----
  typedef struct packed { logic flag; logic [7:0] value; } robptr_t;
  typedef struct packed { logic flag; logic [5:0] value; } ftqptr_t;
  typedef struct packed { logic flag; logic [4:0] value; } rasptr_t;   // TOSW/TOSR/NOS
  typedef struct packed { logic flag; logic [7:0] value; } histptr_t;  // CGHPtr
  typedef struct packed { logic flag; logic [6:0] value; } lqptr_t;
  typedef struct packed { logic flag; logic [5:0] value; } sqptr_t;
  typedef struct packed { logic flag; logic [1:0] value; } snptptr_t;

  // isAfter(a, b)：a 比 b 年轻（环形序比较，flag 不同时值大的反而老）
  function automatic logic rob_is_after(robptr_t a, robptr_t b);
    return a.flag ^ b.flag ^ (a.value > b.value);
  endfunction
  // needFlush：被重定向 r 冲掉 = r 有效且（r 自冲（level=flush）且同一 robIdx，或 a 比 r 年轻）
  function automatic logic rob_need_flush(robptr_t a, logic r_valid, robptr_t r_idx, logic r_level);
    return r_valid & ((r_level & (a == r_idx)) | rob_is_after(a, r_idx));
  endfunction

  // ---- 预译码信息 ----
  typedef struct packed {
    logic       valid;
    logic       isRVC;
    logic [1:0] brType;
    logic       isCall;
    logic       isRet;
  } predecode_t;

  // ---- 全局历史折叠（AllFoldedHistories，18 段各自宽度不同，照 golden） ----
  typedef struct packed {
    logic [10:0] hist_17;
    logic [10:0] hist_16;
    logic [6:0]  hist_15;
    logic [7:0]  hist_14;
    logic [8:0]  hist_13;
    logic [3:0]  hist_12;
    logic [7:0]  hist_11;
    logic [8:0]  hist_10;
    logic [6:0]  hist_9;
    logic [7:0]  hist_8;
    logic [6:0]  hist_7;
    logic [8:0]  hist_6;
    logic [6:0]  hist_5;
    logic [7:0]  hist_4;
    logic [7:0]  hist_3;
    logic [7:0]  hist_2;
    logic [10:0] hist_1;
    logic [7:0]  hist_0;
  } folded_hist_t;

  // ---- CfiUpdateInfo（分支更新信息；两个变体：带/不带 pd） ----
  // 带 pd 的完整版：s2_s4/s3_s5 级、Rob flush 二选一后的 s1_s3、发往前端/IssueBlock 的 flush。
  typedef struct packed {
    logic [VADDR_W-1:0] pc;
    predecode_t         pd;
    logic [3:0]         ssp;
    logic [2:0]         sctr;
    rasptr_t            TOSW;
    rasptr_t            TOSR;
    rasptr_t            NOS;
    logic [VADDR_W-1:0] topAddr;
    folded_hist_t       folded_hist;
    logic [5:0][3:0]    afhob;          // AllAheadFoldedHistoryOldestBits：6 组 × 4 位
    logic [2:0]         lastBrNumOH;
    logic [3:0]         ghr;
    histptr_t           histPtr;
    logic [1:0][9:0]    specCnt;
    logic               br_hit;
    logic               jr_hit;
    logic               sc_hit;
    logic               predTaken;
    logic [VADDR_W-1:0] target;
    logic               taken;
    logic               isMisPred;
    logic [1:0]         shift;
    logic               addIntoHist;
    logic               backendIGPF;
    logic               backendIPF;
    logic               backendIAF;
  } cfi_update_t;

  // 执行单元写回携带的 redirect.cfiUpdate（golden 在"最老 exu 重定向"寄存器里没保留 pd）
  typedef struct packed {
    logic [VADDR_W-1:0] pc;
    logic [3:0]         ssp;
    logic [2:0]         sctr;
    rasptr_t            TOSW;
    rasptr_t            TOSR;
    rasptr_t            NOS;
    logic [VADDR_W-1:0] topAddr;
    folded_hist_t       folded_hist;
    logic [5:0][3:0]    afhob;
    logic [2:0]         lastBrNumOH;
    logic [3:0]         ghr;
    histptr_t           histPtr;
    logic [1:0][9:0]    specCnt;
    logic               br_hit;
    logic               jr_hit;
    logic               sc_hit;
    logic               predTaken;
    logic [VADDR_W-1:0] target;
    logic               taken;
    logic               isMisPred;
    logic [1:0]         shift;
    logic               addIntoHist;
    logic               backendIGPF;
    logic               backendIPF;
    logic               backendIAF;
  } exu_cfi_update_t;

  // ---- Redirect（完整版：s1_s3 / s2_s4 / RedirectGenerator.stage2Redirect） ----
  typedef struct packed {
    logic               isRVC;
    robptr_t            robIdx;
    ftqptr_t            ftqIdx;
    logic [3:0]         ftqOffset;
    logic               level;          // RedirectLevel：1 = flush（含自身），0 = flushAfter
    logic               interrupt;
    cfi_update_t        cfiUpdate;
    logic [XLEN-1:0]    fullTarget;
    logic               satpFlush;
    logic               isVlsException;
    ftqptr_t            stFtqIdx;
    logic [3:0]         stFtqOffset;
    logic [XLEN-1:0]    debug_runahead_checkpoint_id;
    logic               debugIsCtrl;
    logic               debugIsMemVio;
  } redirect_t;

  // 执行单元写回里的 redirect（不带 pd，带 debugIsMemVio 只在 CSR 口有——按 lane 由 wrapper 补 0）
  typedef struct packed {
    logic               isRVC;
    robptr_t            robIdx;
    ftqptr_t            ftqIdx;
    logic [3:0]         ftqOffset;
    logic               level;
    logic               interrupt;
    exu_cfi_update_t    cfiUpdate;
    logic [XLEN-1:0]    fullTarget;
    logic               satpFlush;
    logic               isVlsException;
    ftqptr_t            stFtqIdx;
    logic [3:0]         stFtqOffset;
    logic [XLEN-1:0]    debug_runahead_checkpoint_id;
    logic               debugIsCtrl;
  } exu_redirect_t;

  // Rob.flushOut 里真保留的字段（Rob 只驱动这几个）
  typedef struct packed {
    logic               isRVC;
    robptr_t            robIdx;
    ftqptr_t            ftqIdx;
    logic [3:0]         ftqOffset;
    logic               level;
    logic               satpFlush;
    logic               isVlsException;
  } rob_flush_t;

  // load 违例重定向（fromMem.violation）里真保留的字段
  typedef struct packed {
    logic               isRVC;
    robptr_t            robIdx;
    ftqptr_t            ftqIdx;
    logic [3:0]         ftqOffset;
    logic               level;
    ftqptr_t            stFtqIdx;
    logic [3:0]         stFtqOffset;
    logic [XLEN-1:0]    debug_runahead_checkpoint_id;
  } mem_violation_t;

  // 只带排序所需字段的"轻量重定向"（findOldestRedirect / needFlush 只看这三样）
  typedef struct packed {
    logic    valid;
    robptr_t robIdx;
    logic    level;
  } redirect_lite_t;

  // 两个重定向里挑更老的那个：都无效取 a；只一个有效取有效的；都有效取 robIdx 更老的
  // （golden：sel_a = a.v & ~b.v | ~(~a.v & b.v | a.v & b.v & isAfter(a, b))）
  function automatic redirect_lite_t oldest_redirect(redirect_lite_t a, redirect_lite_t b);
    logic sel_a;
    sel_a = (a.valid & ~b.valid)
          | ~((~a.valid & b.valid) | (a.valid & b.valid & rob_is_after(a.robIdx, b.robIdx)));
    return sel_a ? a : b;
  endfunction

  // ---- 向量控制字段（VPU 状态 + 向量访存信息） ----
  typedef struct packed {
    logic       isFpToVecInst;
    logic       isFP32Instr;
    logic       isFP64Instr;
    logic       isReduction;
    logic       isFoldTo1_2;
    logic       isFoldTo1_4;
    logic       isFoldTo1_8;
  } vpu_fpu_t;

  typedef struct packed {
    logic       vill;
    logic       vma;
    logic       vta;
    logic [1:0] vsew;
    logic [2:0] vlmul;
    logic       specVill;
    logic       specVma;
    logic       specVta;
    logic [1:0] specVsew;
    logic [2:0] specVlmul;
    logic       vm;
    logic [7:0] vstart;
    logic [2:0] frm;
    vpu_fpu_t   fpu;
    logic [1:0] vxrm;
    logic [6:0] vuopIdx;
    logic       lastUop;
    logic [127:0] vmask;
    logic [7:0] vl;
    logic [2:0] nf;
    logic [1:0] veew;
    logic       isReverse;
    logic       isExt;
    logic       isNarrow;
    logic       isDstMask;
    logic       isOpMask;
    logic       isMove;
    logic       isDependOldVd;
    logic       isWritePartVd;
    logic       isVleff;
  } vpu_ctrl_t;

  typedef struct packed {
    vpu_ctrl_t  vpu;
    logic [7:0] oldVdPsrc;
    logic [2:0] vdIdx;
    logic [2:0] vdIdxInField;
    logic       isIndexed;
    logic       isMasked;
    logic       isStrided;
    logic       isWhole;
    logic       isVecLoad;
    logic       isVlm;
  } vls_info_t;

  // ---- 调试时间戳（PerfDebugInfo）与序号 ----
  typedef struct packed {
    logic            eliminatedMove;
    logic [XLEN-1:0] renameTime;
    logic [XLEN-1:0] dispatchTime;
    logic [XLEN-1:0] enqRsTime;
    logic [XLEN-1:0] selectTime;
    logic [XLEN-1:0] issueTime;
    logic [XLEN-1:0] writebackTime;
    logic [XLEN-1:0] runahead_checkpoint_id;
    logic [XLEN-1:0] tlbFirstReqTime;
    logic [XLEN-1:0] tlbRespTime;
  } debug_info_t;

  typedef struct packed {
    logic [55:0] seqNum;
    logic [7:0]  uopIdx;
  } seq_num_t;

  // ---- ExuOutput：27 路写回口的并集（每路真有哪些字段由 WB_LANE 描述表决定） ----
  typedef struct packed {
    logic [5:0][127:0]  data;           // data_0..data_5（整数口只用 [63:0]）
    logic [PREG_W-1:0]  pdest;
    robptr_t            robIdx;
    logic               intWen;
    logic               fpWen;
    logic               vecWen;
    logic               v0Wen;
    logic               vlWen;
    logic               redirect_valid;
    exu_redirect_t      redirect;
    logic               redirect_debugIsMemVio;   // 只有 CSR 口（lane 7）有这一位
    logic [EXC_N-1:0]   exceptionVec;
    logic               flushPipe;
    logic               satpFlushPipe;
    logic               replay;
    lqptr_t             lqIdx;
    sqptr_t             sqIdx;
    logic [3:0]         trigger;
    predecode_t         predecodeInfo;
    logic [4:0]         fflags;
    logic               wflags;
    logic               vxsat;
    vls_info_t          vls;
    logic               debug_isMMIO;
    logic               debug_isNCIO;
    logic               debug_isPerfCnt;
    logic [47:0]        debug_paddr;
    logic [VADDR_W-1:0] debug_vaddr;
    debug_info_t        debugInfo;
    seq_num_t           debug_seqNum;
  } exu_output_t;

  typedef struct packed {
    logic        valid;
    exu_output_t bits;
  } wb_lane_t;

  // 每路写回口的字段保留描述（golden 逐路 DCE 的结果，由 gen_ctrlblock.py 从 golden 寄存器表核出）
  typedef struct packed {
    logic [7:0]  data_w;          // data_0 寄存器位宽（64 或 128）；0 = 无 data
    logic [3:0]  data_n;          // 保留的 data 段数（data_0..data_{n-1}）
    logic        has_base;        // robIdx.value + debugInfo enqRs/select/issue 时间戳 + writebackTime 计数器 + data_0
    logic        has_robidx_flag; // robIdx.flag
    logic        has_pdest;
    logic        has_intwen, has_fpwen, has_vecwen, has_vlwen, has_vxsat;
    logic        has_fflags;      // fflags + wflags
    logic        has_redir_lite;  // redirect_valid + cfiUpdate.taken + cfiUpdate.isMisPred
    logic        has_redir_full;  // redirect 其余字段（只有 CSR 口）
    logic [EXC_N-1:0] exc_mask;   // exceptionVec 里保留的位
    logic        has_flushpipe;
    logic        has_satpflushpipe;
    logic        has_replay;
    logic        has_lqidx, has_sqidx;
    logic        has_trigger;
    logic        has_predecode;
    logic        has_perfcnt;     // debug_isPerfCnt
    logic        has_dbgmem;      // debug_isMMIO/isNCIO/paddr/vaddr
    logic        has_dbglong;     // debugInfo.eliminatedMove/renameTime/dispatchTime/tlb*Time/runahead + debug_seqNum
    logic        has_vls;
    logic        need_exc_gen;    // 该口进 writebackNeedFlush（exceptionVec|flushPipe|replay|trigger==DebugMode）
    logic        has_valid;       // Rob 消费 writeback.valid（delayedNotFlushedWriteBack.valid）
    logic        has_csr;         // 是 CSR 口（backendIAF/IPF/IGPF 只从这一口取）
    logic [WB_N-1:0] same_group;  // writebackNums：与本口可同 robIdx 压缩计数的口集合
    logic [3:0]  nums_w;          // writebackNums 寄存器位宽 = log2Ceil(popcount(same_group)+1)
  } wb_lane_shape_t;

  // BEGIN GENERATED(wb_lane_table)
  // END GENERATED

  // ---- StaticInst / CtrlFlow：前端送来、译码缓冲保存的指令 ----
  typedef struct packed {
    logic [31:0]        instr;
    logic [VADDR_W-1:0] pc;
    logic [9:0]         foldpc;
    logic [EXC_N-1:0]   exceptionVec;
    logic               isFetchMalAddr;   // ← 前端 cfVec.backendException
    logic [3:0]         trigger;
    predecode_t         preDecodeInfo;    // ← 前端 cfVec.pd
    logic               pred_taken;
    logic               crossPageIPFFix;
    ftqptr_t            ftqPtr;
    logic [3:0]         ftqOffset;
    logic               isLastInFtqEntry;
    seq_num_t           debug_seqNum;
    logic               satpFlushFirstFetchFault;
  } static_inst_t;

  // 译码缓冲只保留 golden 真保留的异常位：bit 3 / bit 22 在 DecodeStage 入口没有端口，
  // 前端 cfVec 只带 1/2/12/20 四位（其余位装 0）。
  localparam logic [EXC_N-1:0] DECODE_EXC_KEEP  = 24'hBFFFF7;
  localparam logic [EXC_N-1:0] FRONTEND_EXC_BITS = 24'h101006;

  typedef struct packed {
    logic         valid;
    static_inst_t bits;
  } static_inst_valid_t;

  // ---- DynInst：Rob 入队请求里真保留的字段（NewDispatch → 打一拍 → Rob.enq.req） ----
  typedef struct packed {
    logic       vill;
    logic       vma;
    logic       vta;
    logic [1:0] vsew;
    logic [2:0] vlmul;
    logic       specVill;
    logic       specVma;
    logic       specVta;
    logic [1:0] specVsew;
    logic [2:0] specVlmul;
  } enq_vpu_t;

  typedef struct packed {
    logic [3:0] itype;
    logic [3:0] iretire;
    logic       ilastsize;
  } trace_pipe_t;

  typedef struct packed {
    logic [31:0]        instr;
    logic [VADDR_W-1:0] pc;
    logic [EXC_N-1:0]   exceptionVec;     // golden 只保留 0/1/2/3/12/20/22（ENQ_EXC_KEEP）
    logic               isFetchMalAddr;
    logic               hasException;
    logic [3:0]         trigger;
    logic               preDecodeInfo_isRVC;
    logic               crossPageIPFFix;
    ftqptr_t            ftqPtr;
    logic [3:0]         ftqOffset;
    logic               satpFlushFirstFetchFault;
    logic [5:0]         ldest;
    logic [34:0]        fuType;
    logic [8:0]         fuOpType;
    logic               rfWen;
    logic               fpWen;
    logic               vecWen;
    logic               v0Wen;
    logic               vlWen;
    logic               isXSTrap;
    logic               waitForward;
    logic               blockBackward;
    logic               flushPipe;
    enq_vpu_t           vpu;
    logic               vlsInstr;
    logic               wfflags;
    logic               isMove;
    logic               isVset;
    logic               firstUop;
    logic               lastUop;
    logic [6:0]         numWB;
    logic [2:0]         commitType;
    logic [PREG_W-1:0]  pdest;
    robptr_t            robIdx;
    logic [2:0]         instrSize;
    logic               dirtyFs;
    logic               dirtyVs;
    trace_pipe_t        traceBlockInPipe;
    logic               eliminatedMove;
    logic               snapshot;
    logic [XLEN-1:0]    debugInfo_renameTime;
    logic [XLEN-1:0]    debugInfo_dispatchTime;   // Q5：NewDispatch 没有这些出口，装的是常量 0
    logic [XLEN-1:0]    debugInfo_enqRsTime;
    logic [XLEN-1:0]    debugInfo_selectTime;
    logic [XLEN-1:0]    debugInfo_issueTime;
    logic [XLEN-1:0]    debugInfo_writebackTime;
    logic [6:0]         lqIdx_value;
    logic [5:0]         sqIdx_value;
    logic               singleStep;
    logic               replayInst;
    logic [34:0]        debug_fuType;
    logic               debug_sim_trig;
  } dyn_inst_t;

  localparam logic [EXC_N-1:0] ENQ_EXC_KEEP = 24'h50100F;

  typedef struct packed {
    logic      valid;
    dyn_inst_t bits;
  } enq_req_t;

  // ---- Rob 提交信息里前端 FTQ 要的那几个字段 ----
  typedef struct packed {
    logic [2:0] commitType;
    ftqptr_t    ftqIdx;
    logic [3:0] ftqOffset;
  } commit_to_ftq_t;

  // ---- 快照条目（SnapshotGenerator 的 CFIRobIdx：6 个 RobPtr + 6 个 isCFI） ----
  typedef struct packed {
    robptr_t [DECODE_W-1:0] robIdx;
    logic    [DECODE_W-1:0] isCFI;
  } snapshot_t;

  // ---- 地址翻译模式（AddrTransType） ----
  typedef struct packed {
    logic bare;
    logic sv39;
    logic sv39x4;
    logic sv48;
    logic sv48x4;
  } addr_trans_type_t;

  // ============================================================================
  // 可读核端口束：顶层 IO 里核真消费/真驱动的那部分（与 CtrlBlockIO 同构）
  // ============================================================================
  typedef struct packed {
    logic         valid;
    static_inst_t bits;   // 前端 cfVec 已经用 static_inst_t 的形状装好（wrapper 完成字段改名）
  } ctrl_flow_t;

  typedef struct packed {
    logic               pc_mem_wen;
    logic [5:0]         pc_mem_waddr;
    logic [VADDR_W-1:0] pc_mem_wdata_startAddr;
    logic               newest_entry_en;
    logic [VADDR_W-1:0] newest_entry_target;
    logic [5:0]         newest_entry_ptr_value;
  } from_ftq_t;

  typedef struct packed {
    logic [XLEN-1:0] pc;
    logic            raiseIPF;
    logic            raiseIAF;
    logic            raiseIGPF;
  } trap_target_t;

  typedef struct packed {
    logic fusion_enable;
    logic wfi_enable;
    logic singlestep;
  } csr_ctrl_t;

  typedef struct packed {
    logic [2:0] lastPriv;
    logic [2:0] currentPriv;
  } trace_csr_t;

  typedef struct packed {
    ctrl_flow_t [DECODE_W-1:0]  cfVec;
    from_ftq_t                  fromFtq;
    csr_ctrl_t                  csrCtrl;
    trace_csr_t                 traceCSR;
    addr_trans_type_t           instrAddrTransType;
    logic                       violation_valid;      // fromMem.violation
    mem_violation_t             violation_bits;
    logic [DECODE_W-1:0][5:0]   fromDataPathFtqPtr;   // toDataPath.pcToDataPathIO.fromDataPathFtqPtr(i).value
    trap_target_t               trapTarget;           // robio.csr.trapTarget
    logic [7:0]                 vstart;               // toDecode.vstart
    wb_lane_t [WB_N-1:0]        wb;                   // fromWB.wbData
  } cb_in_t;

  typedef struct packed {
    logic            valid;
    commit_to_ftq_t  bits;
  } rob_commit_valid_t;

  typedef struct packed {
    ftqptr_t            ftqIdx;
    logic [3:0]         ftqOffset;
    logic               level;
    logic [VADDR_W-1:0] cfiUpdate_pc;
    logic [VADDR_W-1:0] cfiUpdate_target;
    logic               cfiUpdate_taken;
    logic               cfiUpdate_isMisPred;
    logic               cfiUpdate_backendIGPF;
    logic               cfiUpdate_backendIPF;
    logic               cfiUpdate_backendIAF;
    logic               satpFlush;
    logic               debugIsCtrl;
    logic               debugIsMemVio;
  } ftq_redirect_t;

  typedef struct packed {
    rob_commit_valid_t [COMMIT_W-1:0] rob_commits;
    logic                             redirect_valid;
    ftq_redirect_t                    redirect_bits;
    logic                             ftqIdxAhead0_valid;
    logic [5:0]                       ftqIdxAhead0_value;
    logic [2:0]                       ftqIdxSelOH;
  } to_ftq_t;

  typedef struct packed {
    logic               valid;
    logic [PREG_W-2:0]  bits;   // 7 位输出（Q7）
  } old_pdest_t;

  typedef struct packed {
    to_ftq_t                        toFtq;
    logic [DECODE_W-1:0]            cfVec_ready;
    logic                           canAccept;
    logic                           redirect_valid;     // io_redirect = s1_s3
    robptr_t                        redirect_robIdx;
    logic                           redirect_level;
    logic                           redirect_isVlsException;
    logic                           flush_valid;        // s2_s4 → toIssueBlock/toDataPath/toExuBlock.flush
    redirect_t                      flush_bits;
    logic [BRH_N-1:0][VADDR_W-1:0]  toDataPathTargetPC;
    logic [VADDR_W-1:0]             exception_pc;       // robio.exception.bits.pc = s1_robFlushPc
    logic [6:0]                     retiredInstr;       // robio.csr.perfinfo.retiredInstr（打一拍）
    old_pdest_t [RAB_W-1:0]         v0OldVdPdest;
    old_pdest_t [RAB_W-1:0]         vecOldVdPdest;
    logic [2:0]                     trace_priv;
    logic [PERF_N-1:0][5:0]         perf;
    logic                           error0;
  } cb_out_t;

  // ---- child 出口（核真消费的那部分） ----
  typedef struct packed {
    logic                          flushOut_valid;
    rob_flush_t                    flushOut_bits;
    logic                          commits_isCommit;
    logic [COMMIT_W-1:0]           commits_commitValid;
    robptr_t [COMMIT_W-1:0]        commits_robIdx;
    commit_to_ftq_t [COMMIT_W-1:0] commits_info;
    logic                          rabCommits_isCommit;
    logic                          rabCommits_isWalk;
    logic [RAB_W-1:0]              rabCommits_commitValid;
    logic [RAB_W-1:0]              rabCommits_v0Wen;
    logic [RAB_W-1:0]              rabCommits_vecWen;
    logic                          enq_canAccept;
    logic                          enq_canAcceptForDispatch;
    logic                          enq_isEmpty;
    logic                          exception_valid;
    logic [6:0]                    retiredInstr;
    logic                          error0;
  } rob_out_t;

  typedef struct packed {
    logic                          redirect_valid;         // s1_s3（Rob.io.redirect）
    robptr_t                       redirect_robIdx;
    logic                          redirect_level;
    logic                          redirect_isMisPred;
    enq_req_t [DECODE_W-1:0]       enq_req;
    logic                          snpt_useSnpt;
    logic [1:0]                    snpt_snptSelect;
    logic                          snpt_snptDeq;
    logic [SNPT_N-1:0]             snpt_flushVec;
    logic                          vstartIsZero;
    logic                          wfi_enable;
    wb_lane_t [WB_N-1:0]           writeback;              // delayedNotFlushedWriteBack
    logic [WB_N-1:0]               exuWriteback_valid;     // delayedWriteBack.valid（bits 同上）
    logic [WB_N-1:0][WB_NUM_W-1:0] writebackNums;
    logic [WB_N-1:0]               writebackNeedFlush;     // 按 lane 编号；wrapper 只接 need_exc_gen 的口
  } rob_in_t;

  typedef struct packed {
    logic              stage2_valid;
    redirect_t         stage2_bits;
    logic [1:0]        stage2oldestOH;
  } redirectgen_out_t;

  typedef struct packed {
    logic              oldestExuRedirect_valid;
    exu_redirect_t     oldestExuRedirect_bits;
    logic              oldestExuRedirectIsCSR;
    addr_trans_type_t  instrAddrTransType;
    predecode_t        oldestExuOutPredecode;
    logic              loadReplay_valid;
    mem_violation_t    loadReplay_bits;
    logic [VADDR_W-1:0] loadReplay_pc;          // loadReplay.bits.cfiUpdate.pc = .target
    logic [VADDR_W-1:0] memPredPcRead_data;
    logic              robFlush_valid;
    rob_flush_t        robFlush_bits;
  } redirectgen_in_t;

  typedef struct packed {
    enq_req_t [DECODE_W-1:0] enqRob_req;
  } dispatch_out_t;

  typedef struct packed {
    logic [DECODE_W-1:0] renameIn_valid;
    logic                enqRob_canAccept;
    logic                enqRob_isEmpty;
    logic                singleStep;
    logic [34:0]         renameIn0_fuType;     // Q4：融合改写只作用于 lane 0
    logic [8:0]          renameIn0_fuOpType;
  } dispatch_in_t;

  typedef struct packed {
    logic [DECODE_W-1:0]            in_ready;
    logic [DECODE_W-1:0]            out_valid;
    logic [DECODE_W-1:0][EXC_N-1:0] out_exceptionVec;
    logic [DECODE_W-1:0][3:0]       out_trigger;
  } decode_out_t;

  typedef struct packed {
    static_inst_valid_t [DECODE_W-1:0] in;
    logic                              redirect;
    logic [DECODE_W-2:0]               fusion;
    logic                              backendCanAccept;
    csr_ctrl_t                         csrCtrl;    // RegNext(io.csrCtrl)
  } decode_in_t;

  // decode→rename 流水缓冲（PipelineConnectPipe）出口里核要看的字段
  typedef struct packed {
    logic        out_valid;
    logic        in_ready;
    logic [5:0]  ftqPtr_value;
    logic [3:0]  ftqOffset;
    logic        isMove;
    logic [34:0] fuType;
    logic [8:0]  fuOpType;
    logic [3:0]  srcType_1;
    logic [5:0]  lsrc_1;
    logic [3:0]  selImm;
    logic [2:0]  commitType;
    logic [9:0]  foldpc;
  } pipe_out_t;

  typedef struct packed {
    logic        valid;
    logic        fuType_valid;
    logic        fuOpType_valid;
    logic [8:0]  fuOpType_bits;
    logic        src2Type_valid;
    logic        lsrc2_valid;
    logic [5:0]  lsrc2_bits;
    logic        selImm_valid;
    logic [3:0]  selImm_bits;
  } fusion_out_lane_t;

  typedef struct packed {
    fusion_out_lane_t [DECODE_W-2:0] out;
    logic [DECODE_W-1:1]             clear;
  } fusion_out_t;

  typedef struct packed {
    logic                disableFusion;
    logic [DECODE_W-1:0] in_valid;
  } fusion_in_t;

  typedef struct packed {
    logic [DECODE_W-1:0]          out_valid;
    logic [DECODE_W-1:0]          out_snapshot;
  } rename_out_t;

  // rename 入口被融合改写的字段（lane 0..4 改写，lane 5 只有 valid）
  typedef struct packed {
    logic        valid;
    logic [34:0] fuType;
    logic [8:0]  fuOpType;
    logic [3:0]  srcType_1;
    logic [5:0]  lsrc_1;
    logic [3:0]  selImm;
    logic [2:0]  commitType;
  } rename_in_lane_t;

  typedef struct packed {
    logic                          redirect_valid;   // s1_s3
    robptr_t                       redirect_robIdx;
    logic                          redirect_level;
    logic                          redirect_debugIsCtrl;
    logic                          redirect_debugIsMemVio;
    rename_in_lane_t [DECODE_W-1:0] in;
    logic                          snpt_useSnpt;
    logic [1:0]                    snpt_snptSelect;
    logic                          snpt_snptDeq;
    logic [SNPT_N-1:0]             snpt_flushVec;
    logic                          snptLastEnq_valid;
    robptr_t                       snptLastEnq_bits;
    logic                          snptIsFull;
    logic                          singleStep;
  } rename_in_t;

  typedef struct packed {
    logic [RAB_W-1:0][PREG_W-1:0] v0_old_pdest;
    logic [RAB_W-1:0][PREG_W-1:0] vec_old_pdest;
  } rat_out_t;

  typedef struct packed {
    logic                redirect;         // s1_s3.valid
    logic [DECODE_W-1:0] renameUpdates_valid;
    logic                snpt_snptEnq;
    logic                snpt_snptDeq;
    logic                snpt_useSnpt;
    logic [1:0]          snpt_snptSelect;
    logic [SNPT_N-1:0]   snpt_flushVec;    // ★RAT 收的是没打拍的 flushVec★
  } rat_in_t;

  typedef struct packed {
    logic [SNPT_N-1:0]        valids;
    snapshot_t [SNPT_N-1:0]   snapshots;
    snptptr_t                 enqPtr;
    snptptr_t                 deqPtr;
  } snpt_out_t;

  typedef struct packed {
    logic              enq;
    logic              deq;
    logic              redirect;
    logic [SNPT_N-1:0] flushVec;   // 打过一拍的 flushVecNext
  } snpt_in_t;

  typedef struct packed {
    logic [PCMEM_RD_N-1:0][VADDR_W-1:0] rdata_startAddr;
  } pcmem_out_t;

  typedef struct packed {
    logic [PCMEM_RD_N-1:0]      ren;
    logic [PCMEM_RD_N-1:0][5:0] raddr;
    logic                       wen;
    logic [5:0]                 waddr;
    logic [VADDR_W-1:0]         wdata_startAddr;
  } pcmem_in_t;

  typedef struct packed {
    logic [MDP_N-1:0]      mdpFoldPcVecVld;
    logic [MDP_N-1:0][9:0] mdpFlodPcVec;
  } memctrl_in_t;

  typedef struct packed {
    logic [DECODE_W-1:0] in_ready;   // renamePipeDispatch.io_in_N_ready
  } pgc_out_t;

  typedef struct packed {
    logic in0_snapshot;               // renamePipeDispatch.io_in_0_bits_snapshot
  } pgc_in_t;

  typedef struct packed {
    logic s5_flushFromRobValidAhead;  // DelayN_15(s1_robFlushRedirect.valid, 4)
    logic s5_csrIsTrap;               // DelayN_15(rob.io.exception.valid, 4)
  } delay_out_t;

endpackage
