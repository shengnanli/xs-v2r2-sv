// =============================================================================
//  LoadQueueReplay —— load 重放调度器（可读重写核 xs_LoadQueueReplay_core）
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/mem/lsqueue/LoadQueueReplay.scala
//  类型/常量/纯函数集中在 loadqueuereplay_pkg（见 loadqueuereplay_pkg.sv 文件头）。
//
//  ── 这个模块在访存子系统的位置 ───────────────────────────────────────────
//  LoadUnit 是流水化的：一条 load 走 s0(发射)→s1(TLB/读 SQ forward)→s2(dcache 命中
//  判定/forward 合并)→s3。若在某级因 tlb miss / dcache miss / forward 未就绪 /
//  bank 冲突 / RAR/RAW 队列满 / st-ld 违例 等原因无法完成，s3 会把它「踢」到本队列
//  （io.enq），等待 block 条件解除后再选回 LoadUnit 重跑（io.replay）。
//
//  ── 核心数据结构 ─────────────────────────────────────────────────────────
//  72 个 entry（非环形，用 freelist 分配空闲槽）。每 entry 保存：
//    allocated  : 是否占用
//    scheduled  : 已选中正在重放流水里（避免重复选）
//    blocking   : block 条件仍未解除（不可重放）
//    strict     : C_MA 严格序（loadWaitStrict）
//    cause[11]  : 11 种 replay cause 位向量（可同时多个）
//    uop/vec    : 重放时回填 LoadUnit 的元数据
//    blockSqIdx : C_MA/C_FF 等待的 store 的 sqIdx
//    missMSHRId : C_DM 等待的 mshr id
//    tlbHintId  : C_TM 等待的 tlb filter id
//    vaddr      : 虚地址（存外部黑盒 LqVAddrModule，省寄存器）
//
//  ── 三级选择流水（关键，s2_oldestSel 是著名假阳性家族来源）──────────────────
//    s0：在 72 entry 中按「cause 优先级（hint > 高优先 C_DM/C_FF > 低优先）+ 年龄
//        （程序序最老 oldest）」选出每路（3 路）一个 one-hot 候选，读其 vaddr。
//        年龄选择有两条腿：① 程序序 oldest（按 ldWbPtr+0..3 匹配，issOldest）；
//        ② 入队序 oldest（AgeDetector 维护的入队先后矩阵，ageOldest）。issOldest
//        优先于 ageOldest。
//    s1：把 s0 的 one-hot 转 7 位下标打一拍寄存；置 scheduled；读 vaddr 子模块。
//    s2：再打一拍；组装 replay_req 发回 LoadUnit。被 redirect 刷则取消。
//        replay 还有「冷却」：连续重放同口超阈值会强制冷却，避免饿死其他口。
//
//  ── 分节 ────────────────────────────────────────────────────────────────
//    §0  端口/参数 + entry 状态寄存器 + 子模块例化（黑盒）
//    §1  入队判定（needEnqueue/canFree/newEnqueue + freelist 分配下标）
//    §2  blocking 解除条件（11 种 cause 各自的唤醒逻辑）
//    §3  s0 选择：hint/高/低优先 mask + 年龄选择（AgeDetector + 程序序）
//    §4  s1/s2 流水 + replay_req 组装
//    §5  寄存器统一更新（入队写入 / scheduled / blocking / 取消释放）
//    §6  redirect/vec 取消 + freelist free
//    §7  topdown + perf
//
//  ⚠ 端口集合/命名与 golden LoadQueueReplay 完全一致（扁平 io_*，由 wrapper 适配）。
//    本配置 golden 已裁剪 difftest/部分 backend 字段。可读性体现在「内部」用
//    struct 数组 + genvar + enum + function 表达微架构。
// =============================================================================
module xs_LoadQueueReplay_core
  import loadqueuereplay_pkg::*;
(
`include "loadqueuereplay_ports.svh"
);

  // ===========================================================================
  //  §0  每 entry 的控制状态（散列 Vec(72,Bool) → 聚合为 struct 数组）
  // ===========================================================================
  typedef struct packed {
    logic allocated;    // 已分配
    logic scheduled;    // 已被选入重放流水（避免重复选）
    logic blocking;     // block 条件未解除（不可重放）
    logic strict;       // C_MA 严格序
  } entry_ctrl_t;

  // entry 阵列按 LQ_SLOTS=128 声明（仅 0..71 有效，其余为 padding，永不分配且复位清 0）。
  //  这样所有「7 位下标读阵列」静态在界，对 Formality 友好（消除 FMR_ELAB-147）。
  entry_ctrl_t              ent [LQ_SLOTS];
  logic [N_CAUSES-1:0]      cause [LQ_SLOTS];           // 11 位 cause 向量
  lqr_uop_t                 uop   [LQ_SLOTS];
  lqr_vec_t                 vecReplay [LQ_SLOTS];
  sq_ptr_t                  blockSqIdx [LQ_SLOTS];
  logic [MSHR_ID_W-1:0]     missMSHRId [LQ_SLOTS];
  logic [TLB_ID_W-1:0]      tlbHintId  [LQ_SLOTS];
  logic                     dataInLastBeat [LQ_SLOTS];
  logic [VADDR_BITS-1:0]    debug_vaddr [LQ_SLOTS];

  // ---- 越界折叠读视图（FM 配平）：golden 对 Vec(72) 以 7 位下标做纯值读取时，
  //      firtool 生成 128 项读表、高 56 项(72..127)复制条目 0（越界回绕 vec[0]）。
  //      运行期下标的纯值读一律走 *R 视图；padding 条目因此只写不读，两侧同被剪除
  //      （否则 padding 条目为无驱动网，FM 视作自由变量，读锥全部误判失配）。
  lqr_uop_t                 uopR       [LQ_SLOTS];
  lqr_vec_t                 vecReplayR [LQ_SLOTS];
  logic [N_CAUSES-1:0]      causeR     [LQ_SLOTS];
  logic [MSHR_ID_W-1:0]     missMSHRIdR[LQ_SLOTS];
  always_comb
    for (int k = 0; k < LQ_SLOTS; k++) begin
      uopR[k]        = (k >= LQ_REPLAY_SIZE) ? uop[0]        : uop[k];
      vecReplayR[k]  = (k >= LQ_REPLAY_SIZE) ? vecReplay[0]  : vecReplay[k];
      causeR[k]      = (k >= LQ_REPLAY_SIZE) ? cause[0]      : cause[k];
      missMSHRIdR[k] = (k >= LQ_REPLAY_SIZE) ? missMSHRId[0] : missMSHRId[k];
    end

  // 派生位向量（组合）：把 struct 字段摊成 72 位总线，便于做 mask 运算
  logic [LQ_REPLAY_SIZE-1:0] allocated_v, scheduled_v, blocking_v;
  genvar gi;
  generate
    for (gi = 0; gi < LQ_REPLAY_SIZE; gi++) begin : g_statvec
      assign allocated_v[gi] = ent[gi].allocated;
      assign scheduled_v[gi] = ent[gi].scheduled;
      assign blocking_v[gi]  = ent[gi].blocking;
    end
  endgenerate

  // 出队释放掩码（被 redirect/vec 取消 或 重放后 done 的 entry 置 1，喂回 freelist）
  logic [LQ_REPLAY_SIZE-1:0] freeMaskVec;

  // 子模块互联网（详见 §0b/§3/§4 使用处）
  logic [REM_SIZE-1:0] age_enq [LD_PIPE_W][LD_PIPE_W]; // [rport][enq port]
  logic [REM_SIZE-1:0] age_deq [LD_PIPE_W];            // free mask（rem 视角）
  logic [REM_SIZE-1:0] age_ready [LD_PIPE_W];          // priority replay sel
  logic [REM_SIZE-1:0] age_out [LD_PIPE_W];

  logic [SCHED_IDX_W-1:0] freeAllocSlot [LD_PIPE_W];
  logic [LD_PIPE_W-1:0]   freeCanAllocate;
  logic                   freeEmpty;
  logic [LD_PIPE_W-1:0]   freeDoAllocate;

  logic [LD_PIPE_W-1:0]            va_ren;
  logic [LD_PIPE_W-1:0][LQ_IDX_W-1:0] va_raddr;
  logic [LD_PIPE_W-1:0][VADDR_BITS-1:0] va_rdata;
  logic [LD_PIPE_W-1:0]            va_wen;
  logic [LD_PIPE_W-1:0][LQ_IDX_W-1:0] va_waddr;
  logic [LD_PIPE_W-1:0][VADDR_BITS-1:0] va_wdata;

`include "loadqueuereplay_subinst.svh"

  // ===========================================================================
  //  §1  入队判定
  //      needEnqueue : 有效 & 未被 redirect 刷 & 确需重放 & 无异常
  //      canFree     : 本来是 isLoadReplay 回流，但不再需要重放（或有异常）→ 释放
  //      newEnqueue  : needEnqueue 且不是 isLoadReplay（首次进队，要分配新槽）
  // ===========================================================================
  logic [LD_PIPE_W-1:0] canEnqueue, cancelEnq, needReplay, hasExceptions;
  logic [LD_PIPE_W-1:0] loadReplay, needEnqueue, newEnqueue, canFreeVec;

  // selectByFu(exceptionVec, LduCfg)：load 关心的异常位子集（不是全 24 位！）。
  //  LduCfg 选出的异常位 = {3,4,5,13,19,21}（含 misalign/access/page fault 等 load
  //  相关项）；只对这些位 orR 判定 hasExceptions。tlbMiss 时不算异常（要去重放）。
  //  ⚠ 误用全 24 位 orR 会让其他位（非 load 异常）误触发，错误地阻止入队。
  function automatic logic ldu_has_exc(input logic [23:0] ev);
    return ev[3] | ev[4] | ev[5] | ev[13] | ev[19] | ev[21];
  endfunction
  generate
    for (gi = 0; gi < LD_PIPE_W; gi++) begin : g_enqjudge
      assign canEnqueue[gi]    = enq_valid[gi];
      assign cancelEnq[gi]     = rob_need_flush(enq_uop[gi].robIdx.flag, enq_uop[gi].robIdx.value,
                                   redirect_valid, redirect_robIdx.flag, redirect_robIdx.value, redirect_level);
      assign needReplay[gi]    = |enq_cause[gi];
      assign hasExceptions[gi] = ldu_has_exc(enq_uop[gi].exceptionVec) & ~enq_tlbMiss[gi];
      assign loadReplay[gi]    = enq_isLoadReplay[gi];
      assign needEnqueue[gi]   = canEnqueue[gi] & ~cancelEnq[gi] & needReplay[gi] & ~hasExceptions[gi];
      assign newEnqueue[gi]    = needEnqueue[gi] & ~enq_isLoadReplay[gi];
      assign canFreeVec[gi]    = canEnqueue[gi] & loadReplay[gi] & (~needReplay[gi] | hasExceptions[gi]);
    end
  endgenerate

  // freelist 分配下标：isLoadReplay 复用原 schedIndex，否则取 freelist 第 offset 个空槽
  //  offset = 前面几路 newEnqueue 的个数（PopCount(newEnqueue.take(w))）
  logic [SCHED_IDX_W-1:0] enqIndex [LD_PIPE_W];
  logic [LQ_REPLAY_SIZE-1:0] enqIndexOH [LD_PIPE_W];
  // freelist 第 offset 个空槽：offset∈{0,1,2}，用显式 3 选 1（不用动态下标，避免
  //  Formality 因 offset 类型上界 3 > 数组深度而报 out-of-bound elab 误报）。
  function automatic logic [SCHED_IDX_W-1:0] pick_slot(
      input logic [SCHED_IDX_W-1:0] s0, input logic [SCHED_IDX_W-1:0] s1,
      input logic [SCHED_IDX_W-1:0] s2, input logic [1:0] off);
    unique case (off)
      2'd0:    pick_slot = s0;
      2'd1:    pick_slot = s1;
      default: pick_slot = s2;   // off==2（off 至多为 LD_PIPE_W-1=2）
    endcase
  endfunction
  always_comb begin
    for (int w = 0; w < LD_PIPE_W; w++) begin
      logic [1:0] offset;
      offset = '0;
      for (int k = 0; k < LD_PIPE_W; k++) if (k < w) offset += newEnqueue[k];
      enqIndex[w]   = enq_isLoadReplay[w] ? enq_schedIndex[w]
                    : pick_slot(freeAllocSlot[0], freeAllocSlot[1], freeAllocSlot[2], offset);
      enqIndexOH[w] = idx_to_oh(enqIndex[w]);
      freeDoAllocate[w] = needEnqueue[w] & ~enq_isLoadReplay[w];
    end
  end

  assign lqFull = freeEmpty;

  // ===========================================================================
  //  §2  blocking 解除条件（每 entry 按其当前 cause 决定何时可重放）
  //      把组合中间量与寄存器更新分开：这里算「本拍是否解除该 cause 的 block」，
  //      §5 的统一 always_ff 据此把 blocking 清 0。
  // ===========================================================================
`include "loadqueuereplay_block.svh"

  // ===========================================================================
  //  §3  s0 选择：构造 hint/高优先/低优先 mask，喂 AgeDetector + 程序序选择
  // ===========================================================================
`include "loadqueuereplay_s0sel.svh"

  // ===========================================================================
  //  §4  s1/s2 流水 + replay_req 组装
  // ===========================================================================
`include "loadqueuereplay_pipe.svh"

  // ===========================================================================
  //  §5  entry 寄存器统一更新（入队写入 + scheduled + blocking 清除 + 取消释放）
  // ===========================================================================
`include "loadqueuereplay_regupd.svh"

  // ===========================================================================
  //  §6/§7  topdown + perf
  // ===========================================================================
`include "loadqueuereplay_perf.svh"

endmodule
