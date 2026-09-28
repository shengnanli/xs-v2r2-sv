// VLMergeBufferImp.sv — 向量 load 合并缓冲（VMergeBuffer 家族的参数化核 + VLoad 变体 wrapper）
//
// 在访存流水里的位置（Chisel: xiangshan/mem/vector/VMergeBuffer.scala）：
//
//   VSplit ──fromSplit.req──> 【MergeBuffer】 <──fromPipeline── LoadUnit / StoreUnit (每个 flow 的结果)
//     ^    <─fromSplit.resp── (条目号 mBIndex)        │
//     └──── toSplit.threshold (快满了)                ├─uopWriteback─> 后端写回（经一级 NewPipelineConnect）
//                                                     ├─toLsq────────> LSQ（这条 uop 提交/冲刷）
//                                                     └─feedback─────> 发射队列（命中/需要重放）
//
// 一条向量访存 uop 被 VSplit 拆成 flowNum 个 flow（元素访问）分发给标量流水。本缓冲给每条 uop
// 分一个条目（槽位号由 FreeList 分配），等它的全部 flow 都回来：
//   1. 入队（EnqConnect）：记下 uop、mask、flowNum（还差几个 flow）、vl/vlmax 等。
//   2. 流水写回：每回来一个 flow，flowNum 减一（同拍多口写同一条目时由编号最小的口一次减掉
//      全部）；带异常的 flow 按"元素号最小者优先"记下异常向量、vstart、出错地址；
//      load 版本还要把 flow 带回的数据按元素号拼进条目的 128 位 data。
//   3. 完成与出队：flowNum 归零即置 uopFinish；出队口从 uopFinish 里挑条目（口 0 挑编号最小的，
//      口 1 挑编号最大的），经一级 NewPipelineConnect 写回后端，同时通知 LSQ、反馈发射队列并
//      把槽位还给 FreeList。若有 flow 没命中（需要发射队列重放），则只反馈"重放"、不释放条目。
//   redirect（分支误预测/异常冲刷）把 robIdx 在重定向点之后的条目直接作废并释放。
//
// 本文件 = package vmergebuffer_pkg + 参数化核 xs_VMergeBuffer_core + golden 同名 wrapper
// VLMergeBufferImp（load：16 条目 / 2 入队口 / 3 流水写回口 / 2 出队口，数据合并逻辑在场）。
// store 变体 VSMergeBufferImp（16 条目 / 1 / 1 / 1，无数据）只是一个薄 wrapper，见同目录
// VSMergeBufferImp.sv。子模块全部白盒例化本仓已签核的重写件：FreeList / FreeList_1（槽位表）、
// NewPipelineConnectPipe_29（写回口的单拍流水缓冲）。
//
// 机械派生区（struct 成员表、uop 透传字段的存储、流水缓冲的端口连线、两个 wrapper）由
// scripts/gen_vmergebuf.py 从 G1 golden 端口表生成，`// BEGIN GENERATED(<tag>)` 标记，勿手改。
//
// ── 与 golden 对齐的要点（逐条对着 golden 核过，UT/FM 都会拦）──────────────────────────
//   · 端口里没有的输入字段不是"没有"，是上游恒送常量、被 firtool 跨模块常量传播删掉了端口：
//     load 流水的 hit 恒 1（所以 load 版永远不会要求发射队列重放）、sourceType 恒 0；
//     store 流水的 sourceType 恒 1；两者 flushState 恒 0；uop 的 flushPipe/replayInst/psrc_2/
//     trigger 在入队请求里恒 0。wrapper 在这些位置补常量，核按 Chisel 原意照常处理。
//   · 条目字段集合按 golden 的 reg 声明逐字对齐，两个变体不同（见 §2）：例如 store 版没有
//     data/vdIdx/vl/originVl/fof/flushState，却留着一个只写不读的 isPartReplay（debug）。
//   · load 版的异常/计数写回用的是**打了一拍**的流水结果，store 版用当拍的（Chisel 的
//     `if(isVStore) x else RegNext(x)`）。于是 load 版里同一个 valid/mBIndex 被打成三份
//     互相独立的寄存器（pipeValidReg / latchWbValid / pipewbValidReg 等），golden 一份不少，
//     这里也一份不少（见 §5、§8）。
//   · 出队选择是 SelectOne("circ")：口 0 取编号最小的 uopFinish，口 1 取编号最大的，
//     口 1 只在至少两个条目完成时才有效；没有条目完成时条目号取 0。
//   · 本单元只有 16 条目，条目号 4 位恰好覆盖，可以直接用信号下标访问条目数组；
//     但宽度 < 4 位的"口号"一律用 for + 比较选择（避免 Formality 的越界下标告警）。
// 本文件导航（共 2445 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L271   xs_VMergeBuffer_core —— 合并缓冲的可读核
//   L299   §1 小工具：异常向量的"按功能单元挑选"
//   L301   条目里只存本单元会产生的那 6 个异常位
//   L387   §2 条目状态
//   L389   控制位
//   L424   §3 入队：向 FreeList 要槽位
//   L484   §4 redirect：robIdx 在重定向点之后的已分配条目作废
//   L496   §5 同拍多口写同一条目：合并矩阵
//   L498   mergePortMatrix[i][j]：口 j 与口 i 写同一条目且 j 在 i 之后
//   L612   §6 异常写回：同一条目的多个异常 flow 里挑元素号最小的
//   L614   口 i 负责它所写条目
//   L694   §7 计数写回
//   L727   §8 load 版数据合并：flow 数据先在当拍拼好、打一拍后写回条目
//   L729   两条路径，由 alignedType[2] 选：
//   L846   §9 完成与出队选择
//   L889   §10 出队输出：写回
//   L1196  §11 条目寄存器更新
//   L1198  控制位：入队置位 -> redirect 作废 -> 没命中置 needRSReplay -> 完成置 uopFinish ->
//   L1560  VLMergeBufferImp —— golden 同名 wrapper
//   L1562  BEGIN GENERATED(wrapper_VLMergeBufferImp)
//

package vmergebuffer_pkg;

  // ---- KunminghuV2Config 下的规模常量（由 golden 端口/寄存器宽度核实）----
  localparam int MB_SIZE  = 16;   // VlMergeBufferSize == VsMergeBufferSize
  localparam int MB_IDX_W = 4;    // log2(MB_SIZE)：mBIndex 宽度
  localparam int VLEN     = 128;
  localparam int VLENB    = 16;   // VLEN/8：每字节一位的 mask 宽度
  localparam int FLOW_W   = 5;    // flowIdxBits：flowNum / replayFlowNum 宽度
  localparam int ELEM_W   = 8;    // elemIdxBits：elemIdx / vstart / vl / vlmax 宽度
  localparam int ROB_W    = 8;    // robIdx.value 宽度

  // ---- ExceptionVec（24 位）与两类功能单元会产生的异常号（FuConfig.exceptionOut）----
  localparam int EXC_BREAKPOINT = 3;
  //   load : breakPoint(3) loadAddrMisaligned(4) loadAccessFault(5) loadPageFault(13)
  //          hardwareError(19) loadGuestPageFault(21)
  localparam logic [23:0] VLDU_EXC_SEL = 24'h28_2038;
  //   store: breakPoint(3) storeAddrMisaligned(6) storeAccessFault(7) storePageFault(15)
  //          hardwareError(19) storeGuestPageFault(23)
  localparam logic [23:0] VSTU_EXC_SEL = 24'h88_80C8;

  // ---- TriggerAction ----
  localparam logic [3:0] TRIGGER_BREAKPOINT_EXP = 4'd0;  // 触发断点异常
  localparam logic [3:0] TRIGGER_DEBUG_MODE     = 4'd1;  // 进入 debug mode（isDmode）

  // ---- 端口 struct：成员名 = golden 扁平端口名去掉 `io_<口>_<i>_bits_` 前缀 ----
  //  exceptionVec_<n> 收成 24 位向量 exceptionVec[n]；toLsq 的 feedback_<n> 收成 feedback[n]。
  //  各 struct 是两个变体端口的并集；某变体没有的成员由 wrapper 补常量（见文件头）。
  // BEGIN GENERATED(structs)
  // DynInst 在本单元进出的字段（入队请求 uop 与写回 uop 的并集）
  typedef struct packed {
    logic [23:0]         exceptionVec;
    logic [3:0]          trigger;
    logic [8:0]          fuOpType;
    logic                vecWen;
    logic                v0Wen;
    logic                vlWen;
    logic                flushPipe;
    logic                vpu_vill;
    logic                vpu_vma;
    logic                vpu_vta;
    logic [1:0]          vpu_vsew;
    logic [2:0]          vpu_vlmul;
    logic                vpu_specVill;
    logic                vpu_specVma;
    logic                vpu_specVta;
    logic [1:0]          vpu_specVsew;
    logic [2:0]          vpu_specVlmul;
    logic                vpu_vm;
    logic [7:0]          vpu_vstart;
    logic [2:0]          vpu_frm;
    logic                vpu_fpu_isFpToVecInst;
    logic                vpu_fpu_isFP32Instr;
    logic                vpu_fpu_isFP64Instr;
    logic                vpu_fpu_isReduction;
    logic                vpu_fpu_isFoldTo1_2;
    logic                vpu_fpu_isFoldTo1_4;
    logic                vpu_fpu_isFoldTo1_8;
    logic [1:0]          vpu_vxrm;
    logic [6:0]          vpu_vuopIdx;
    logic                vpu_lastUop;
    logic [127:0]        vpu_vmask;
    logic [7:0]          vpu_vl;
    logic [2:0]          vpu_nf;
    logic [1:0]          vpu_veew;
    logic                vpu_isReverse;
    logic                vpu_isExt;
    logic                vpu_isNarrow;
    logic                vpu_isDstMask;
    logic                vpu_isOpMask;
    logic                vpu_isMove;
    logic                vpu_isDependOldVd;
    logic                vpu_isWritePartVd;
    logic                vpu_isVleff;
    logic [7:0]          psrc_2;
    logic [7:0]          pdest;
    logic                robIdx_flag;
    logic [7:0]          robIdx_value;
    logic                debugInfo_eliminatedMove;
    logic [63:0]         debugInfo_renameTime;
    logic [63:0]         debugInfo_dispatchTime;
    logic [63:0]         debugInfo_enqRsTime;
    logic [63:0]         debugInfo_selectTime;
    logic [63:0]         debugInfo_issueTime;
    logic [63:0]         debugInfo_writebackTime;
    logic [63:0]         debugInfo_runahead_checkpoint_id;
    logic [63:0]         debugInfo_tlbFirstReqTime;
    logic [63:0]         debugInfo_tlbRespTime;
    logic [55:0]         debug_seqNum_seqNum;
    logic [7:0]          debug_seqNum_uopIdx;
    logic                replayInst;
    logic [6:0]          uopIdx;
    logic                lqIdx_flag;
    logic [6:0]          lqIdx_value;
    logic                sqIdx_flag;
    logic [5:0]          sqIdx_value;
  } mb_uop_t;

  // redirect：重定向点 robIdx 与 level
  typedef struct packed {
    logic                valid;
    logic                robIdx_flag;
    logic [7:0]          robIdx_value;
    logic                level;
  } mb_redirect_t;

  // fromSplit.req：VSplit 发来的一条 uop（MergeBufferReq）
  typedef struct packed {
    logic                valid;
    logic [15:0]         mask;
    logic [49:0]         vaddr;
    logic [4:0]          flowNum;
    logic [127:0]        data;
    logic [2:0]          vdIdx;
    logic                fof;
    logic [7:0]          vlmax;
    mb_uop_t             uop;
  } mb_enq_req_t;

  // fromPipeline：一个 flow 的写回（VecPipelineFeedbackIO）；sourceType/flushState 无端口，恒由 wrapper 补常量
  typedef struct packed {
    logic                valid;
    logic [3:0]          mBIndex;
    logic [3:0]          trigger;
    logic [23:0]         exceptionVec;
    logic                hasException;
    logic [63:0]         vaddr;
    logic                vaNeedExt;
    logic [63:0]         gpaddr;
    logic                isForVSnonLeafPTE;
    logic [7:0]          vstart;
    logic [15:0]         vecTriggerMask;
    logic [7:0]          elemIdx;
    logic [15:0]         mask;
    logic [2:0]          alignedType;
    logic [3:0]          reg_offset;
    logic [7:0]          elemIdxInsideVd;
    logic [127:0]        vecdata;
    logic                hit;
    logic [4:0]          splitIndex;
    logic [2:0]          sourceType;
    logic                flushState;
  } mb_pipe_t;

  // uopWriteback：写回后端的 MemExuOutput
  typedef struct packed {
    logic                valid;
    logic [127:0]        data;
    logic [2:0]          vdIdx;
    logic [2:0]          vdIdxInField;
    mb_uop_t             uop;
  } mb_wb_t;

  // toLsq：FeedbackToLsqIO
  typedef struct packed {
    logic                valid;
    logic                robidx_flag;
    logic [7:0]          robidx_value;
    logic [6:0]          uopidx;
    logic [63:0]         vaddr;
    logic                vaNeedExt;
    logic [63:0]         gpaddr;
    logic                isForVSnonLeafPTE;
    logic [1:0]          feedback;
    logic [7:0]          vl;
    logic [23:0]         exceptionVec;
  } mb_lsq_t;

  // feedback：给发射队列的 RSFeedback
  typedef struct packed {
    logic                valid;
    logic                robIdx_flag;
    logic [7:0]          robIdx_value;
    logic                hit;
    logic                flushState;
    logic [3:0]          sourceType;
    logic                sqIdx_flag;
    logic [5:0]          sqIdx_value;
    logic                lqIdx_flag;
    logic [6:0]          lqIdx_value;
    logic                isVecPartReplay;
    logic [15:0]         vecReplayMask;
    logic [3:0]          vecReplayMbIdx;
  } mb_fb_t;
  // END GENERATED

  // DynInst.fuOpType 的 LSUOpType.isAllUS：unit-stride / whole-register / masked 三类
  function automatic logic is_all_us(input logic [8:0] fuOpType);
    return fuOpType[6:5] == 2'b00 && (fuOpType[8] ^ fuOpType[7]);
  endfunction

  // RobPtr.needFlush(redirect)：重定向有效，且 robIdx 在重定向点之后
  // （level=1 表示"连重定向点这条自己也冲"）。isAfter 用 {flag,value} 环形比较。
  function automatic logic need_flush(input logic flag, input logic [ROB_W-1:0] value,
                                      input mb_redirect_t r);
    logic is_after;
    is_after = flag ^ r.robIdx_flag ^ (value > r.robIdx_value);
    return r.valid && ((r.level && flag == r.robIdx_flag && value == r.robIdx_value) || is_after);
  endfunction

endpackage

// =============================================================================
// xs_VMergeBuffer_core —— 合并缓冲的可读核（load/store 两变体共用）
// =============================================================================
module xs_VMergeBuffer_core
  import vmergebuffer_pkg::*;
#(
  parameter bit          IS_VSTORE = 1'b0,          // 0 = VLMergeBufferImp，1 = VSMergeBufferImp
  parameter int          ENQ_W     = 2,             // 入队口数（VecLoad/StorePipelineWidth 对应的 split 口）
  parameter int          PIPE_W    = 3,             // 流水写回口数（只支持 1 或 3，见 §6）
  parameter int          DEQ_W     = 2,             // 出队口数（只支持 1 或 2，见 §9）
  parameter int          THRESHOLD = 6,             // toSplit.threshold：空闲条目 <= 该值即报"快满"
  parameter logic [23:0] EXC_SEL   = VLDU_EXC_SEL   // 本功能单元的 exceptionOut
) (
  input  logic                clock,
  input  logic                reset,
  input  mb_redirect_t        io_redirect,
  input  mb_enq_req_t         io_fromSplit_req          [ENQ_W],
  output logic                io_fromSplit_req_ready    [ENQ_W],
  output logic                io_fromSplit_resp_valid   [ENQ_W],
  output logic [MB_IDX_W-1:0] io_fromSplit_resp_mBIndex [ENQ_W],
  input  mb_pipe_t            io_fromPipeline           [PIPE_W],
  input  logic                io_uopWriteback_ready     [DEQ_W],
  output mb_wb_t              io_uopWriteback           [DEQ_W],
  output logic                io_toSplit_threshold,
  output mb_lsq_t             io_toLsq                  [DEQ_W],
  output mb_fb_t              io_feedback               [DEQ_W]
);

  // ---------------------------------------------------------------------------
  // §1 小工具：异常向量的"按功能单元挑选"（ExceptionNO.selectByFu）
  // ---------------------------------------------------------------------------
  // 条目里只存本单元会产生的那 6 个异常位（golden 也只有这 6 个寄存器），
  // 压缩向量第 k 位 = EXC_SEL 里从低到高第 k 个被选中的异常号。
  localparam int EXC_W = 6;
  localparam int CNT_W = $clog2(PIPE_W + 1);   // 同拍最多 PIPE_W 个 flow 写同一条目
  typedef logic [EXC_W-1:0] exc_t;

  function automatic exc_t exc_select(input logic [23:0] v);
    exc_t r;
    int   k;
    r = '0;
    k = 0;
    for (int b = 0; b < 24; b++) begin
      if (EXC_SEL[b]) begin
        r[k] = v[b];
        k++;
      end
    end
    return r;
  endfunction

  function automatic logic [23:0] exc_expand(input exc_t c);
    logic [23:0] r;
    int          k;
    r = '0;
    k = 0;
    for (int b = 0; b < 24; b++) begin
      if (EXC_SEL[b]) begin
        r[b] = c[k];
        k++;
      end
    end
    return r;
  endfunction

  // selectByFuAndUnSelect(vec, fuCfg, Seq(breakPoint))：同上但不看 breakPoint
  function automatic exc_t exc_select_no_bp(input logic [23:0] v);
    return exc_select(v & ~(24'b1 << EXC_BREAKPOINT));
  endfunction

  // genVFirstUnmask：mask 里最低的 1 在第几位（全 0 时为 0）
  function automatic logic [3:0] first_unmask(input logic [VLENB-1:0] m);
    logic [3:0] r;
    r = '0;
    for (int b = VLENB - 1; b >= 0; b--) begin
      if (m[b]) r = 4'(b);
    end
    return r;
  endfunction

  // selectOldest 的二选一：两个都有异常取 elemIdx 小的（相等取右边），只有一个有异常取它，
  // 都没有取右边。返回 1 = 取左边。
  function automatic logic pick_left(input logic vl, input logic [ELEM_W-1:0] el,
                                     input logic vr, input logic [ELEM_W-1:0] er);
    return (vl && vr) ? (el < er) : (vl && !vr);
  endfunction

  // mergeDataWithElemIdx：把同拍写同一条目的各口 flow 数据按"元素在 vd 里的序号"拼进 old。
  // alignedType 决定元素宽度（字节/半字/字/双字）；新数据都取自各口 vecdata 的最低元素；
  // 多口写同一元素时口号大的胜（ParallelPosteriorityMux）。
  function automatic logic [VLEN-1:0] merge_by_elem(
    input logic [VLEN-1:0]                old,
    input logic [1:0]                     aligned,
    input logic [PIPE_W-1:0]              valids,
    input logic [PIPE_W-1:0][VLEN-1:0]    newd,
    input logic [PIPE_W-1:0][ELEM_W-1:0]  eidx
  );
    logic [VLEN-1:0] r;
    r = old;
    unique case (aligned)
      2'b00: for (int b = 0; b < 16; b++)
               for (int j = 0; j < PIPE_W; j++)
                 if (valids[j] && eidx[j][3:0] == 4'(b)) r[8*b +: 8] = newd[j][7:0];
      2'b01: for (int h = 0; h < 8; h++)
               for (int j = 0; j < PIPE_W; j++)
                 if (valids[j] && eidx[j][2:0] == 3'(h)) r[16*h +: 16] = newd[j][15:0];
      2'b10: for (int w = 0; w < 4; w++)
               for (int j = 0; j < PIPE_W; j++)
                 if (valids[j] && eidx[j][1:0] == 2'(w)) r[32*w +: 32] = newd[j][31:0];
      2'b11: for (int d = 0; d < 2; d++)
               for (int j = 0; j < PIPE_W; j++)
                 if (valids[j] && eidx[j][0] == 1'(d)) r[64*d +: 64] = newd[j][63:0];
    endcase
    return r;
  endfunction

  // ---------------------------------------------------------------------------
  // §2 条目状态（每个字段一个数组，下标 = 条目号 = mBIndex；字段集合逐字对齐 golden）
  // ---------------------------------------------------------------------------
  // 控制位（异步复位）
  logic                allocated             [MB_SIZE];  // 条目已分配给某条 uop
  logic                uopFinish             [MB_SIZE];  // 全部 flow 已回来，等待出队
  logic                needRSReplay          [MB_SIZE];  // 有 flow 没命中，出队时要求发射队列重放
  // 两个变体都有的数据字段（不复位）
  logic [VLENB-1:0]    entries_mask          [MB_SIZE];  // 这条 uop 的字节 mask
  logic [FLOW_W-1:0]   entries_flowNum       [MB_SIZE];  // 还差几个 flow 没回来
  exc_t                entries_exceptionVec  [MB_SIZE];  // 最老的异常 flow 的异常向量（压缩）
  logic [3:0]          entries_uop_trigger   [MB_SIZE];  // 最老的异常 flow 的 trigger 动作
  logic [2:0]          entries_sourceType    [MB_SIZE];  // 各 flow 的 sourceType 按位或
  logic [ELEM_W-1:0]   entries_elemIdx       [MB_SIZE];  // 最老的异常 flow 的元素号（初值全 1）
  logic [ELEM_W-1:0]   entries_vstart        [MB_SIZE];  // 异常时的 vstart
  logic [ELEM_W-1:0]   entries_vlmax         [MB_SIZE];
  logic [63:0]         entries_vaddr         [MB_SIZE];  // 异常地址（入队时是 uop 的基址）
  logic [63:0]         entries_gpaddr        [MB_SIZE];
  logic                entries_vaNeedExt     [MB_SIZE];
  logic                entries_isForVSnonLeafPTE [MB_SIZE];
  logic [FLOW_W-1:0]   entries_replayFlowNum  [MB_SIZE];  // 需重放的 flow 数（只有 store 版会累加）
  logic [VLENB-1:0]    entries_replayFlowMask [MB_SIZE];  // 需重放的 flow 位图（同上）
  // 只有 load 版有的字段
  logic [VLEN-1:0]     entries_data          [MB_SIZE];  // 拼好的 128 位目的寄存器数据
  logic [2:0]          entries_vdIdx         [MB_SIZE];
  logic                entries_fof           [MB_SIZE];  // fault-only-first
  logic [ELEM_W-1:0]   entries_vl            [MB_SIZE];  // fof 截断后的 vl（报给 LSQ）
  logic [ELEM_W-1:0]   entries_originVl      [MB_SIZE];  // 入队时的 vl（写回给后端）
  logic                entries_flushState    [MB_SIZE];
  // 只有 store 版有的字段
  logic                entries_isPartReplay  [MB_SIZE];  // debug 用，只写不读（golden 靠 dontTouch 保留）
  logic [VLEN-1:0]     entries_uop_vpu_vmask [MB_SIZE];
  logic [ELEM_W-1:0]   entries_uop_vpu_vl    [MB_SIZE];

  // 入队时照抄、出队时原样送出的 uop 字段（每字段一个数组）与它们拼回 struct 的只读视图
  mb_uop_t             entries_uop           [MB_SIZE];

  // ---------------------------------------------------------------------------
  // §3 入队：向 FreeList 要槽位（第 i 个入队口拿"前面有几个口也在入队"那个槽）
  // ---------------------------------------------------------------------------
  logic [MB_IDX_W-1:0] allocateSlot [ENQ_W];
  logic [MB_IDX_W:0]   validCount;          // FreeList 里"已被占用"的槽位数
  logic [MB_IDX_W:0]   freeCount;           // 空闲槽位数
  logic [MB_SIZE-1:0]  freeMaskVec;         // 本拍释放回 FreeList 的条目
  logic                needEnqueue [ENQ_W]; // 请求有效且没被本拍 redirect 冲掉
  logic                enq_fire    [ENQ_W]; // 真正写入条目
  logic [MB_IDX_W-1:0] enq_idx     [ENQ_W];

  assign freeCount            = (MB_IDX_W + 1)'(MB_SIZE) - validCount;
  assign io_toSplit_threshold = freeCount <= (MB_IDX_W + 1)'(THRESHOLD);

  always_comb begin
    int offset;
    offset = 0;
    for (int p = 0; p < ENQ_W; p++) begin
      needEnqueue[p] = io_fromSplit_req[p].valid
                       && !need_flush(io_fromSplit_req[p].uop.robIdx_flag,
                                      io_fromSplit_req[p].uop.robIdx_value, io_redirect);
      // ready 只看空闲数（"for better timing"），不看本拍其它口是否入队
      io_fromSplit_req_ready[p]  = freeCount >= (MB_IDX_W + 1)'(p + 1);
      io_fromSplit_resp_valid[p] = freeCount >= (MB_IDX_W + 1)'(p + 1);
      enq_idx[p] = allocateSlot[0];
      for (int k = 1; k < ENQ_W; k++) begin
        if (offset == k) enq_idx[p] = allocateSlot[k];
      end
      io_fromSplit_resp_mBIndex[p] = enq_idx[p];
      enq_fire[p] = needEnqueue[p] && io_fromSplit_req_ready[p];
      offset += int'(needEnqueue[p]);
    end
  end

  generate
    if (!IS_VSTORE) begin : g_freelist_vl
      FreeList freeCount_freeList (
        .clock             (clock),
        .reset             (reset),
        .io_allocateSlot_0 (allocateSlot[0]),
        .io_allocateSlot_1 (allocateSlot[1]),
        .io_doAllocate_0   (enq_fire[0]),
        .io_doAllocate_1   (enq_fire[1]),
        .io_free           (freeMaskVec),
        .io_validCount     (validCount),
        .io_empty          ()
      );
    end else begin : g_freelist_vs
      FreeList_1 freeCount_freeList (
        .clock             (clock),
        .reset             (reset),
        .io_allocateSlot_0 (allocateSlot[0]),
        .io_doAllocate_0   (enq_fire[0]),
        .io_free           (freeMaskVec),
        .io_validCount     (validCount),
        .io_empty          ()
      );
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // §4 redirect：robIdx 在重定向点之后的已分配条目作废
  // ---------------------------------------------------------------------------
  logic needCancel [MB_SIZE];

  always_comb begin
    for (int e = 0; e < MB_SIZE; e++) begin
      needCancel[e] = need_flush(entries_uop[e].robIdx_flag, entries_uop[e].robIdx_value,
                                 io_redirect) && allocated[e];
    end
  end

  // ---------------------------------------------------------------------------
  // §5 同拍多口写同一条目：合并矩阵（当拍）与 load 版的一拍锁存
  // ---------------------------------------------------------------------------
  // mergePortMatrix[i][j]：口 j 与口 i 写同一条目且 j 在 i 之后（含 j==i 自己）。
  //   口 i 的计数写回一次扣掉整行的 flow 数；mergedByPrevPortVec[i] = 前面已有口写这个条目，
  //   口 i 自己就不再写（避免同一条目被写两次）。
  logic mergePortMatrix        [PIPE_W][PIPE_W];
  logic mergePortMatrixMiss    [PIPE_W][PIPE_W];  // 同上且口 j 没命中（store 版累计重放）
  logic mergePortMatrixHasExcp [PIPE_W][PIPE_W];  // 同上且口 j 带异常或 debug trigger
  logic mergedByPrevPortVec    [PIPE_W];

  always_comb begin
    for (int i = 0; i < PIPE_W; i++) begin
      mergedByPrevPortVec[i] = 1'b0;
      for (int j = 0; j < PIPE_W; j++) begin
        logic same;
        same = (j == i)
               || (j > i && io_fromPipeline[j].mBIndex == io_fromPipeline[i].mBIndex
                   && io_fromPipeline[j].valid);
        mergePortMatrix[i][j]        = same;
        mergePortMatrixMiss[i][j]    = !io_fromPipeline[j].hit && same;
        mergePortMatrixHasExcp[i][j] = same && (io_fromPipeline[j].hasException
                                                || io_fromPipeline[j].trigger == TRIGGER_DEBUG_MODE);
        if (j < i && io_fromPipeline[j].mBIndex == io_fromPipeline[i].mBIndex
            && io_fromPipeline[j].valid) begin
          mergedByPrevPortVec[i] = 1'b1;
        end
      end
    end
  end

  // "写回视图"：§6 异常写回、§7 计数写回看到的流水结果。
  //   store 版 = 当拍的 io.fromPipeline；load 版 = 打一拍后的（数据合并要多一拍，控制跟着等）。
  logic                wbv_valid          [PIPE_W];  // pipeValidReg
  logic [MB_IDX_W-1:0] wbv_mBIndex        [PIPE_W];
  logic [3:0]          wbv_trigger        [PIPE_W];
  exc_t                wbv_exceptionVec   [PIPE_W];
  logic [63:0]         wbv_vaddr          [PIPE_W];
  logic                wbv_vaNeedExt      [PIPE_W];
  logic [63:0]         wbv_gpaddr         [PIPE_W];
  logic                wbv_isForVSnonLeafPTE [PIPE_W];
  logic [ELEM_W-1:0]   wbv_vstart         [PIPE_W];
  logic [ELEM_W-1:0]   wbv_elemIdx        [PIPE_W];
  logic [VLENB-1:0]    wbv_mask           [PIPE_W];
  logic                wbv_hasExcp        [PIPE_W][PIPE_W];  // mergePortMatrixHasExcpWrap
  logic                wbv_mergedByPrev   [PIPE_W];          // mergedByPrevPortVecWrap
  // 计数写回自己又锁了一份 valid / 条目号 / 本行 flow 数 / mergedByPrev（golden 里是独立寄存器）
  logic                cnt_valid          [PIPE_W];          // latchWbValid
  logic [MB_IDX_W-1:0] cnt_idx            [PIPE_W];          // latchWbIndex
  logic [CNT_W-1:0]    cnt_flowNum        [PIPE_W];          // latchFlowNum
  logic                cnt_mergedByPrev   [PIPE_W];          // latchMergeByPre

  // 当拍的"本行有几个 flow"（PopCount(mergePortMatrix(i))）
  logic [CNT_W-1:0]    flowNumOffset      [PIPE_W];

  always_comb begin
    for (int i = 0; i < PIPE_W; i++) begin
      flowNumOffset[i] = '0;
      for (int j = 0; j < PIPE_W; j++) begin
        flowNumOffset[i] = flowNumOffset[i] + CNT_W'(mergePortMatrix[i][j]);
      end
    end
  end

  generate
    if (IS_VSTORE) begin : g_wbview_direct
      always_comb begin
        for (int i = 0; i < PIPE_W; i++) begin
          wbv_valid[i]             = io_fromPipeline[i].valid;
          wbv_mBIndex[i]           = io_fromPipeline[i].mBIndex;
          wbv_trigger[i]           = io_fromPipeline[i].trigger;
          wbv_exceptionVec[i]      = exc_select(io_fromPipeline[i].exceptionVec);
          wbv_vaddr[i]             = io_fromPipeline[i].vaddr;
          wbv_vaNeedExt[i]         = io_fromPipeline[i].vaNeedExt;
          wbv_gpaddr[i]            = io_fromPipeline[i].gpaddr;
          wbv_isForVSnonLeafPTE[i] = io_fromPipeline[i].isForVSnonLeafPTE;
          wbv_vstart[i]            = io_fromPipeline[i].vstart;
          wbv_elemIdx[i]           = io_fromPipeline[i].elemIdx;
          wbv_mask[i]              = io_fromPipeline[i].mask;
          wbv_mergedByPrev[i]      = mergedByPrevPortVec[i];
          cnt_valid[i]             = io_fromPipeline[i].valid;
          cnt_idx[i]               = io_fromPipeline[i].mBIndex;
          cnt_flowNum[i]           = flowNumOffset[i];
          cnt_mergedByPrev[i]      = mergedByPrevPortVec[i];
          for (int j = 0; j < PIPE_W; j++) wbv_hasExcp[i][j] = mergePortMatrixHasExcp[i][j];
        end
      end
    end else begin : g_wbview_latched
      // RegNext（无使能）：mergePortMatrixHasExcpWrap / mergedByPrevPortVecWrap / pipeValidReg / latchWbValid
      // RegEnable(_, valid)：pipeBitsReg_* / latchWbIndex / latchFlowNum / latchMergeByPre
      always_ff @(posedge clock) begin
        for (int i = 0; i < PIPE_W; i++) begin
          for (int j = 0; j < PIPE_W; j++) wbv_hasExcp[i][j] <= mergePortMatrixHasExcp[i][j];
          wbv_mergedByPrev[i] <= mergedByPrevPortVec[i];
          wbv_valid[i]        <= io_fromPipeline[i].valid;
          cnt_valid[i]        <= io_fromPipeline[i].valid;
          if (io_fromPipeline[i].valid) begin
            wbv_mBIndex[i]           <= io_fromPipeline[i].mBIndex;
            wbv_trigger[i]           <= io_fromPipeline[i].trigger;
            wbv_exceptionVec[i]      <= exc_select(io_fromPipeline[i].exceptionVec);
            wbv_vaddr[i]             <= io_fromPipeline[i].vaddr;
            wbv_vaNeedExt[i]         <= io_fromPipeline[i].vaNeedExt;
            wbv_gpaddr[i]            <= io_fromPipeline[i].gpaddr;
            wbv_isForVSnonLeafPTE[i] <= io_fromPipeline[i].isForVSnonLeafPTE;
            wbv_vstart[i]            <= io_fromPipeline[i].vstart;
            wbv_elemIdx[i]           <= io_fromPipeline[i].elemIdx;
            wbv_mask[i]              <= io_fromPipeline[i].mask;
            cnt_idx[i]               <= io_fromPipeline[i].mBIndex;
            cnt_flowNum[i]           <= flowNumOffset[i];
            cnt_mergedByPrev[i]      <= mergedByPrevPortVec[i];
          end
        end
      end
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // §6 异常写回：同一条目的多个异常 flow 里挑元素号最小的（selectOldest），记进条目
  // ---------------------------------------------------------------------------
  // 口 i 负责它所写条目（同行里它是第一个口）：在本行带异常的口里挑最老的那个 sel。
  // 写入条件：本行有异常，且条目里还没有异常、或已有异常但本次更老（elemIdx 不大于）。
  // fof（fault-only-first）且 vstart != 0：不报异常，只把 vl 截到 vstart。
  logic                exc_upd      [PIPE_W];
  logic                exc_fof_ok   [PIPE_W];  // !fof || vstart == 0：照常记异常
  logic [MB_IDX_W-1:0] exc_idx      [PIPE_W];
  logic [ELEM_W-1:0]   exc_elemIdx  [PIPE_W];
  logic [ELEM_W-1:0]   exc_vstart   [PIPE_W];
  exc_t                exc_vec      [PIPE_W];
  logic [3:0]          exc_trigger  [PIPE_W];
  logic [63:0]         exc_vaddr    [PIPE_W];
  logic [63:0]         exc_gpaddr   [PIPE_W];
  logic                exc_vaNeedExt [PIPE_W];
  logic                exc_isForVSnonLeafPTE [PIPE_W];
  logic [ELEM_W-1:0]   exc_vl       [PIPE_W];  // fof 截断后的 vl
  logic [1:0]          exc_sel      [PIPE_W];  // selectOldest 选中的写回口

  // selectOldest 的二分树：n=1 直接取口 0；n=3 = pick(口0, pick(口1, 口2))
  generate
    if (PIPE_W == 1) begin : g_sel_oldest_1
      assign exc_sel[0] = 2'd0;
    end else if (PIPE_W == 3) begin : g_sel_oldest_3
      always_comb begin
        for (int i = 0; i < PIPE_W; i++) begin
          logic              right_left, right_v;
          logic [ELEM_W-1:0] right_e;
          right_left = pick_left(wbv_hasExcp[i][1], wbv_elemIdx[1], wbv_hasExcp[i][2], wbv_elemIdx[2]);
          right_v    = right_left ? wbv_hasExcp[i][1] : wbv_hasExcp[i][2];
          right_e    = right_left ? wbv_elemIdx[1]    : wbv_elemIdx[2];
          exc_sel[i] = pick_left(wbv_hasExcp[i][0], wbv_elemIdx[0], right_v, right_e) ? 2'd0
                     : (right_left ? 2'd1 : 2'd2);
        end
      end
    end else begin : g_sel_oldest_unsupported
      $error("xs_VMergeBuffer_core: PIPE_W 只支持 1 或 3");
    end
  endgenerate

  always_comb begin
    for (int i = 0; i < PIPE_W; i++) begin
      logic [MB_IDX_W-1:0] idx;
      logic                entryIsUS, entryExcp, portHasExcp;
      logic [3:0]          addrOffset;
      idx       = wbv_mBIndex[i];
      entryIsUS = is_all_us(entries_uop[idx].fuOpType);
      entryExcp = ((|entries_exceptionVec[idx]) || entries_uop_trigger[idx] == TRIGGER_DEBUG_MODE)
                  && (|entries_mask[idx]);
      portHasExcp = 1'b0;
      for (int j = 0; j < PIPE_W; j++) portHasExcp = portHasExcp | wbv_hasExcp[i][j];

      exc_idx[i] = idx;
      addrOffset = '0;
      exc_elemIdx[i] = '0;  exc_vec[i] = '0;  exc_trigger[i] = '0;  exc_vaNeedExt[i] = 1'b0;
      exc_isForVSnonLeafPTE[i] = 1'b0;  exc_vaddr[i] = '0;  exc_gpaddr[i] = '0;  exc_vstart[i] = '0;
      for (int j = 0; j < PIPE_W; j++) begin
        if (exc_sel[i] == 2'(j)) begin
          // unit-stride 首个非对齐 uop：出错地址要加上 mask 里第一个有效字节的偏移
          addrOffset = entryIsUS ? first_unmask(wbv_mask[j]) : 4'd0;
          exc_elemIdx[i]           = wbv_elemIdx[j];
          exc_vec[i]               = wbv_exceptionVec[j];
          exc_trigger[i]           = wbv_trigger[j];
          exc_vaNeedExt[i]         = wbv_vaNeedExt[j];
          exc_isForVSnonLeafPTE[i] = wbv_isForVSnonLeafPTE[j];
          exc_vaddr[i]             = wbv_vaddr[j] + 64'(addrOffset);
          exc_gpaddr[i]            = wbv_gpaddr[j] + 64'(addrOffset);
          // vstart：unit-stride 用流水给的；其它用"元素号在本字段内的序号"
          exc_vstart[i]            = entryIsUS ? wbv_vstart[j]
                                               : wbv_elemIdx[j] & (entries_vlmax[idx] - 8'd1);
        end
      end

      exc_upd[i] = ((entries_elemIdx[idx] >= exc_elemIdx[i] && entryExcp && portHasExcp)
                    || (!entryExcp && portHasExcp))
                   && wbv_valid[i] && !wbv_mergedByPrev[i];
      exc_fof_ok[i] = !entries_fof[idx] || exc_vstart[i] == '0;
      exc_vl[i]     = (entries_vl[idx] < exc_vstart[i]) ? entries_vl[idx] : exc_vstart[i];
    end
  end

  // ---------------------------------------------------------------------------
  // §7 计数写回（flowNum 扣减、store 版重放累计）与当拍的 sourceType / 重放标记
  // ---------------------------------------------------------------------------
  logic                cnt_upd          [PIPE_W];
  logic [FLOW_W-1:0]   cnt_flowNum_new  [PIPE_W];
  logic                replay_upd       [PIPE_W];  // store：本行有没命中的 flow
  logic [FLOW_W-1:0]   replay_num_new   [PIPE_W];
  logic [VLENB-1:0]    replay_mask_new  [PIPE_W];
  logic [2:0]          src_type_new     [PIPE_W];  // 当拍：条目 sourceType | 本 flow 的
  logic                rs_set           [PIPE_W];  // 当拍：本 flow 没命中 -> needRSReplay

  always_comb begin
    for (int i = 0; i < PIPE_W; i++) begin
      logic [CNT_W-1:0] missCount;
      cnt_upd[i]         = cnt_valid[i] && !cnt_mergedByPrev[i];
      cnt_flowNum_new[i] = entries_flowNum[cnt_idx[i]] - FLOW_W'(cnt_flowNum[i]);

      missCount          = '0;
      replay_mask_new[i] = entries_replayFlowMask[cnt_idx[i]];
      for (int j = 0; j < PIPE_W; j++) begin
        missCount = missCount + CNT_W'(mergePortMatrixMiss[i][j]);
        if (mergePortMatrixMiss[i][j]) begin
          replay_mask_new[i][io_fromPipeline[j].splitIndex[3:0]] = 1'b1;
        end
      end
      replay_upd[i]     = IS_VSTORE && !io_fromPipeline[i].hit;
      replay_num_new[i] = entries_replayFlowNum[cnt_idx[i]] + FLOW_W'(missCount);

      src_type_new[i] = entries_sourceType[io_fromPipeline[i].mBIndex] | io_fromPipeline[i].sourceType;
      rs_set[i]       = io_fromPipeline[i].valid && !io_fromPipeline[i].hit;
    end
  end

  // ---------------------------------------------------------------------------
  // §8 load 版数据合并：flow 数据先在当拍拼好、打一拍后写回条目
  // ---------------------------------------------------------------------------
  // 两条路径，由 alignedType[2] 选：
  //   · 非 unit-stride：mergeDataWithElemIdx，按元素号把本行各口的元素拼进"旧数据"。
  //     旧数据优先取上一拍刚拼好、还没写进条目的 mergeDataReg（同条目连续两拍写回的旁路）。
  //   · unit-stride：一个 flow 带回一整块 128 位，可能跨两个目的寄存器。当拍先把本口与本行
  //     另一口的数据拼成 256 位（mergeDataByIndex），下一拍按 reg_offset 取出 128 位，按字节
  //     mask 写进条目。
  logic                data_upd [PIPE_W];
  logic [MB_IDX_W-1:0] data_idx [PIPE_W];
  logic [VLEN-1:0]     data_new [PIPE_W];

  generate
    if (!IS_VSTORE) begin : g_data_merge
      logic [PIPE_W-1:0][VLEN-1:0]   pipe_vecdata;
      logic [PIPE_W-1:0][ELEM_W-1:0] pipe_elemIdxInVd;
      logic [VLENB-1:0]              maskWithexceptionMask [PIPE_W];
      logic [VLEN-1:0]               mergedData            [PIPE_W];
      logic [2*VLEN-1:0]             brodenMergeData       [PIPE_W];
      logic [2*VLENB-1:0]            brodenMergeMask       [PIPE_W];
      // 打一拍（RegNext / RegEnable(_, valid)）
      logic                          pipewbValidReg        [PIPE_W];
      logic [MB_IDX_W-1:0]           wbIndexReg            [PIPE_W];
      logic [VLEN-1:0]               mergeDataReg          [PIPE_W];
      logic [2*VLEN-1:0]             brodenMergeDataReg    [PIPE_W];
      logic [2*VLENB-1:0]            brodenMergeMaskReg    [PIPE_W];
      logic                          mergedByPrevPortReg   [PIPE_W];
      logic [3:0]                    regOffsetReg          [PIPE_W];
      logic                          isusMerge             [PIPE_W];

      always_comb begin
        for (int j = 0; j < PIPE_W; j++) begin
          pipe_vecdata[j]     = io_fromPipeline[j].vecdata;
          pipe_elemIdxInVd[j] = io_fromPipeline[j].elemIdxInsideVd;
          // 有断点/debug trigger：按 trigger 给的 mask 屏蔽；否则有（非断点）异常就整条不写
          maskWithexceptionMask[j] =
            ((io_fromPipeline[j].trigger == TRIGGER_BREAKPOINT_EXP
              || io_fromPipeline[j].trigger == TRIGGER_DEBUG_MODE)
               ? ~io_fromPipeline[j].vecTriggerMask
               : {VLENB{~|exc_select_no_bp(io_fromPipeline[j].exceptionVec)}})
            & io_fromPipeline[j].mask;
        end
      end

      always_comb begin
        for (int i = 0; i < PIPE_W; i++) begin
          logic [VLEN-1:0]     oldData;
          logic [PIPE_W-1:0]   valids;
          logic [VLEN-1:0]     partner_data;
          logic [VLENB-1:0]    partner_mask;
          // 旧数据：上一拍各口刚拼好的数据优先（口号小的优先），否则取条目里的
          oldData = entries_data[io_fromPipeline[i].mBIndex];
          for (int j = PIPE_W - 1; j >= 0; j--) begin
            if (pipewbValidReg[j] && wbIndexReg[j] == io_fromPipeline[i].mBIndex) oldData = mergeDataReg[j];
          end
          for (int j = 0; j < PIPE_W; j++) valids[j] = mergePortMatrix[i][j];
          mergedData[i] = merge_by_elem(oldData, io_fromPipeline[i].alignedType[1:0], valids,
                                        pipe_vecdata, pipe_elemIdxInVd);
          // mergeDataByIndex：本行口号最大的另一个口做搭档（没有搭档则补 0）
          partner_data = '0;
          partner_mask = '0;
          for (int k = i + 1; k < PIPE_W; k++) begin
            if (mergePortMatrix[i][k]) begin
              partner_data = io_fromPipeline[k].vecdata;
              partner_mask = maskWithexceptionMask[k];
            end
          end
          if (io_fromPipeline[i].elemIdxInsideVd == '0) begin
            brodenMergeData[i] = {partner_data, io_fromPipeline[i].vecdata};
            brodenMergeMask[i] = {partner_mask, maskWithexceptionMask[i]};
          end else begin
            brodenMergeData[i] = {io_fromPipeline[i].vecdata, partner_data};
            brodenMergeMask[i] = {maskWithexceptionMask[i], partner_mask};
          end
        end
      end

      always_ff @(posedge clock) begin
        for (int i = 0; i < PIPE_W; i++) begin
          pipewbValidReg[i] <= io_fromPipeline[i].valid;
          if (io_fromPipeline[i].valid) begin
            wbIndexReg[i]          <= io_fromPipeline[i].mBIndex;
            mergeDataReg[i]        <= mergedData[i];
            brodenMergeDataReg[i]  <= brodenMergeData[i];
            brodenMergeMaskReg[i]  <= brodenMergeMask[i];
            mergedByPrevPortReg[i] <= mergedByPrevPortVec[i];
            regOffsetReg[i]        <= io_fromPipeline[i].reg_offset;
            isusMerge[i]           <= io_fromPipeline[i].alignedType[2];
          end
        end
      end

      always_comb begin
        for (int i = 0; i < PIPE_W; i++) begin
          logic [VLEN-1:0]  usSelData, cur, usMergeData;
          logic [VLENB-1:0] usSelMask;
          usSelData = brodenMergeDataReg[i][8*regOffsetReg[i] +: VLEN];
          usSelMask = brodenMergeMaskReg[i][regOffsetReg[i] +: VLENB];
          cur       = entries_data[wbIndexReg[i]];
          for (int b = 0; b < VLENB; b++) begin
            usMergeData[8*b +: 8] = usSelMask[b] ? usSelData[8*b +: 8] : cur[8*b +: 8];
          end
          data_upd[i] = pipewbValidReg[i] && !mergedByPrevPortReg[i];
          data_idx[i] = wbIndexReg[i];
          data_new[i] = isusMerge[i] ? usMergeData : mergeDataReg[i];
        end
      end
    end else begin : g_no_data_merge
      always_comb begin
        for (int i = 0; i < PIPE_W; i++) begin
          data_upd[i] = 1'b0;
          data_idx[i] = '0;
          data_new[i] = '0;
        end
      end
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // §9 完成与出队选择（SelectOne "circ"）
  // ---------------------------------------------------------------------------
  logic                deq_selValid [DEQ_W];
  logic [MB_IDX_W-1:0] deq_idx      [DEQ_W];
  logic                deq_fire     [DEQ_W];  // selFire：选中且写回流水缓冲能收
  logic                deq_partial  [DEQ_W];  // selDoPartialReplay：只反馈重放，不释放
  logic                deq_canDeq   [DEQ_W];  // 真正写回 / 通知 LSQ
  logic                pipe_in_ready [DEQ_W];
  logic                pipe_in_valid [DEQ_W];
  mb_wb_t              deq_bits     [DEQ_W];  // DeqConnect

  always_comb begin
    int                  finishCount;
    logic [MB_IDX_W-1:0] first, last;
    finishCount = 0;
    first       = '0;
    last        = '0;
    for (int e = 0; e < MB_SIZE; e++) begin
      finishCount += int'(uopFinish[e]);
      if (uopFinish[e]) last = MB_IDX_W'(e);
    end
    for (int e = MB_SIZE - 1; e >= 0; e--) begin
      if (uopFinish[e]) first = MB_IDX_W'(e);
    end
    for (int d = 0; d < DEQ_W; d++) begin
      deq_selValid[d] = finishCount > d;
      deq_idx[d]      = (d % 2 == 0) ? first : last;
      deq_fire[d]     = deq_selValid[d] && pipe_in_ready[d];
      deq_partial[d]  = needRSReplay[deq_idx[d]]
                        && (IS_VSTORE || !is_all_us(entries_uop[deq_idx[d]].fuOpType));
      deq_canDeq[d]   = deq_fire[d] && !needRSReplay[deq_idx[d]];
    end
  end

  // 释放回 FreeList：redirect 作废的，加上出队（非部分重放）的
  always_comb begin
    for (int e = 0; e < MB_SIZE; e++) freeMaskVec[e] = needCancel[e];
    for (int d = 0; d < DEQ_W; d++) begin
      if (deq_fire[d] && !deq_partial[d]) freeMaskVec[deq_idx[d]] = allocated[deq_idx[d]];
    end
  end

  // ---------------------------------------------------------------------------
  // §10 出队输出：写回（DeqConnect -> NewPipelineConnect）、LSQ、发射队列反馈
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int d = 0; d < DEQ_W; d++) begin
      logic [MB_IDX_W-1:0] idx;
      idx = deq_idx[d];
      pipe_in_valid[d] = deq_canDeq[d] && allocated[idx]
                         && !need_flush(entries_uop[idx].robIdx_flag, entries_uop[idx].robIdx_value,
                                        io_redirect);
      // DeqConnect：uop 原样，异常/触发/vstart 用条目里记下的
      deq_bits[d]                  = '0;
      deq_bits[d].uop              = entries_uop[idx];
      deq_bits[d].uop.exceptionVec = exc_expand(entries_exceptionVec[idx]);
      deq_bits[d].uop.trigger      = entries_uop_trigger[idx];
      deq_bits[d].uop.vpu_vstart   = entries_vstart[idx];
      if (IS_VSTORE) begin
        // store 没有数据：data / vdIdx 为 DontCare（golden 接 0）；vmask / vl 用 uop 自带的
        deq_bits[d].uop.vpu_vmask = entries_uop_vpu_vmask[idx];
        deq_bits[d].uop.vpu_vl    = entries_uop_vpu_vl[idx];
      end else begin
        deq_bits[d].uop.vpu_vmask = VLEN'(entries_mask[idx]);
        deq_bits[d].uop.vpu_vl    = entries_originVl[idx];
        deq_bits[d].data          = entries_data[idx];
        deq_bits[d].vdIdx         = entries_vdIdx[idx];
        deq_bits[d].vdIdxInField  = entries_vdIdx[idx];
      end

      // ToLsqConnect：有异常则让 LSQ 冲刷（FLUSH），否则提交这条 uop（COMMIT）
      io_toLsq[d]                   = '0;
      io_toLsq[d].valid             = deq_canDeq[d] && allocated[idx];
      io_toLsq[d].robidx_flag       = entries_uop[idx].robIdx_flag;
      io_toLsq[d].robidx_value      = entries_uop[idx].robIdx_value;
      io_toLsq[d].uopidx            = entries_uop[idx].uopIdx;
      io_toLsq[d].vaddr             = entries_vaddr[idx];
      io_toLsq[d].vaNeedExt         = entries_vaNeedExt[idx];
      io_toLsq[d].gpaddr            = entries_gpaddr[idx];
      io_toLsq[d].isForVSnonLeafPTE = entries_isForVSnonLeafPTE[idx];
      io_toLsq[d].feedback[0]       = |entries_exceptionVec[idx];   // VecFeedbacks.FLUSH
      io_toLsq[d].feedback[1]       = ~|entries_exceptionVec[idx];  // VecFeedbacks.COMMIT
      io_toLsq[d].vl                = entries_vl[idx];
      io_toLsq[d].exceptionVec      = exc_expand(entries_exceptionVec[idx]);
    end
  end

  // 写回流水缓冲（每个出队口一级 NewPipelineConnect）：
  //   入口有效且被收下时按"入口 uop"判冲刷，否则按"缓冲里那条"判冲刷。
  logic pipe_out_valid [DEQ_W];

  generate
    for (genvar d = 0; d < DEQ_W; d++) begin : g_deq_pipe
      logic isFlush;
      assign isFlush = (pipe_in_ready[d] && pipe_in_valid[d])
                       ? need_flush(deq_bits[d].uop.robIdx_flag, deq_bits[d].uop.robIdx_value, io_redirect)
                       : need_flush(io_uopWriteback[d].uop.robIdx_flag,
                                    io_uopWriteback[d].uop.robIdx_value, io_redirect);
      assign io_uopWriteback[d].valid = pipe_out_valid[d];
      // BEGIN GENERATED(deq_pipe)
      NewPipelineConnectPipe_29 VMergebufferPipelineConnect (
        .clock                                            (clock),
        .reset                                            (reset),
        .io_in_ready                                      (pipe_in_ready[d]),
        .io_in_valid                                      (pipe_in_valid[d]),
        .io_in_bits_uop_exceptionVec_3                    (deq_bits[d].uop.exceptionVec[3]),
        .io_in_bits_uop_exceptionVec_4                    (deq_bits[d].uop.exceptionVec[4]),
        .io_in_bits_uop_exceptionVec_5                    (deq_bits[d].uop.exceptionVec[5]),
        .io_in_bits_uop_exceptionVec_6                    (deq_bits[d].uop.exceptionVec[6]),
        .io_in_bits_uop_exceptionVec_7                    (deq_bits[d].uop.exceptionVec[7]),
        .io_in_bits_uop_exceptionVec_13                   (deq_bits[d].uop.exceptionVec[13]),
        .io_in_bits_uop_exceptionVec_15                   (deq_bits[d].uop.exceptionVec[15]),
        .io_in_bits_uop_exceptionVec_19                   (deq_bits[d].uop.exceptionVec[19]),
        .io_in_bits_uop_exceptionVec_21                   (deq_bits[d].uop.exceptionVec[21]),
        .io_in_bits_uop_exceptionVec_23                   (deq_bits[d].uop.exceptionVec[23]),
        .io_in_bits_uop_trigger                           (deq_bits[d].uop.trigger),
        .io_in_bits_uop_fuOpType                          (deq_bits[d].uop.fuOpType),
        .io_in_bits_uop_vecWen                            (deq_bits[d].uop.vecWen),
        .io_in_bits_uop_v0Wen                             (deq_bits[d].uop.v0Wen),
        .io_in_bits_uop_vlWen                             (deq_bits[d].uop.vlWen),
        .io_in_bits_uop_flushPipe                         (deq_bits[d].uop.flushPipe),
        .io_in_bits_uop_vpu_vill                          (deq_bits[d].uop.vpu_vill),
        .io_in_bits_uop_vpu_vma                           (deq_bits[d].uop.vpu_vma),
        .io_in_bits_uop_vpu_vta                           (deq_bits[d].uop.vpu_vta),
        .io_in_bits_uop_vpu_vsew                          (deq_bits[d].uop.vpu_vsew),
        .io_in_bits_uop_vpu_vlmul                         (deq_bits[d].uop.vpu_vlmul),
        .io_in_bits_uop_vpu_specVill                      (deq_bits[d].uop.vpu_specVill),
        .io_in_bits_uop_vpu_specVma                       (deq_bits[d].uop.vpu_specVma),
        .io_in_bits_uop_vpu_specVta                       (deq_bits[d].uop.vpu_specVta),
        .io_in_bits_uop_vpu_specVsew                      (deq_bits[d].uop.vpu_specVsew),
        .io_in_bits_uop_vpu_specVlmul                     (deq_bits[d].uop.vpu_specVlmul),
        .io_in_bits_uop_vpu_vm                            (deq_bits[d].uop.vpu_vm),
        .io_in_bits_uop_vpu_vstart                        (deq_bits[d].uop.vpu_vstart),
        .io_in_bits_uop_vpu_frm                           (deq_bits[d].uop.vpu_frm),
        .io_in_bits_uop_vpu_fpu_isFpToVecInst             (deq_bits[d].uop.vpu_fpu_isFpToVecInst),
        .io_in_bits_uop_vpu_fpu_isFP32Instr               (deq_bits[d].uop.vpu_fpu_isFP32Instr),
        .io_in_bits_uop_vpu_fpu_isFP64Instr               (deq_bits[d].uop.vpu_fpu_isFP64Instr),
        .io_in_bits_uop_vpu_fpu_isReduction               (deq_bits[d].uop.vpu_fpu_isReduction),
        .io_in_bits_uop_vpu_fpu_isFoldTo1_2               (deq_bits[d].uop.vpu_fpu_isFoldTo1_2),
        .io_in_bits_uop_vpu_fpu_isFoldTo1_4               (deq_bits[d].uop.vpu_fpu_isFoldTo1_4),
        .io_in_bits_uop_vpu_fpu_isFoldTo1_8               (deq_bits[d].uop.vpu_fpu_isFoldTo1_8),
        .io_in_bits_uop_vpu_vxrm                          (deq_bits[d].uop.vpu_vxrm),
        .io_in_bits_uop_vpu_vuopIdx                       (deq_bits[d].uop.vpu_vuopIdx),
        .io_in_bits_uop_vpu_lastUop                       (deq_bits[d].uop.vpu_lastUop),
        .io_in_bits_uop_vpu_vmask                         (deq_bits[d].uop.vpu_vmask),
        .io_in_bits_uop_vpu_vl                            (deq_bits[d].uop.vpu_vl),
        .io_in_bits_uop_vpu_nf                            (deq_bits[d].uop.vpu_nf),
        .io_in_bits_uop_vpu_veew                          (deq_bits[d].uop.vpu_veew),
        .io_in_bits_uop_vpu_isReverse                     (deq_bits[d].uop.vpu_isReverse),
        .io_in_bits_uop_vpu_isExt                         (deq_bits[d].uop.vpu_isExt),
        .io_in_bits_uop_vpu_isNarrow                      (deq_bits[d].uop.vpu_isNarrow),
        .io_in_bits_uop_vpu_isDstMask                     (deq_bits[d].uop.vpu_isDstMask),
        .io_in_bits_uop_vpu_isOpMask                      (deq_bits[d].uop.vpu_isOpMask),
        .io_in_bits_uop_vpu_isMove                        (deq_bits[d].uop.vpu_isMove),
        .io_in_bits_uop_vpu_isDependOldVd                 (deq_bits[d].uop.vpu_isDependOldVd),
        .io_in_bits_uop_vpu_isWritePartVd                 (deq_bits[d].uop.vpu_isWritePartVd),
        .io_in_bits_uop_vpu_isVleff                       (deq_bits[d].uop.vpu_isVleff),
        .io_in_bits_uop_psrc_2                            (deq_bits[d].uop.psrc_2),
        .io_in_bits_uop_pdest                             (deq_bits[d].uop.pdest),
        .io_in_bits_uop_robIdx_flag                       (deq_bits[d].uop.robIdx_flag),
        .io_in_bits_uop_robIdx_value                      (deq_bits[d].uop.robIdx_value),
        .io_in_bits_uop_debugInfo_eliminatedMove          (deq_bits[d].uop.debugInfo_eliminatedMove),
        .io_in_bits_uop_debugInfo_renameTime              (deq_bits[d].uop.debugInfo_renameTime),
        .io_in_bits_uop_debugInfo_dispatchTime            (deq_bits[d].uop.debugInfo_dispatchTime),
        .io_in_bits_uop_debugInfo_enqRsTime               (deq_bits[d].uop.debugInfo_enqRsTime),
        .io_in_bits_uop_debugInfo_selectTime              (deq_bits[d].uop.debugInfo_selectTime),
        .io_in_bits_uop_debugInfo_issueTime               (deq_bits[d].uop.debugInfo_issueTime),
        .io_in_bits_uop_debugInfo_writebackTime           (deq_bits[d].uop.debugInfo_writebackTime),
        .io_in_bits_uop_debugInfo_runahead_checkpoint_id  (deq_bits[d].uop.debugInfo_runahead_checkpoint_id),
        .io_in_bits_uop_debugInfo_tlbFirstReqTime         (deq_bits[d].uop.debugInfo_tlbFirstReqTime),
        .io_in_bits_uop_debugInfo_tlbRespTime             (deq_bits[d].uop.debugInfo_tlbRespTime),
        .io_in_bits_uop_debug_seqNum_seqNum               (deq_bits[d].uop.debug_seqNum_seqNum),
        .io_in_bits_uop_debug_seqNum_uopIdx               (deq_bits[d].uop.debug_seqNum_uopIdx),
        .io_in_bits_uop_replayInst                        (deq_bits[d].uop.replayInst),
        .io_in_bits_data                                  (deq_bits[d].data),
        .io_in_bits_vdIdx                                 (deq_bits[d].vdIdx),
        .io_in_bits_vdIdxInField                          (deq_bits[d].vdIdxInField),
        .io_out_ready                                     (io_uopWriteback_ready[d]),
        .io_out_valid                                     (pipe_out_valid[d]),
        .io_out_bits_uop_exceptionVec_3                   (io_uopWriteback[d].uop.exceptionVec[3]),
        .io_out_bits_uop_exceptionVec_4                   (io_uopWriteback[d].uop.exceptionVec[4]),
        .io_out_bits_uop_exceptionVec_5                   (io_uopWriteback[d].uop.exceptionVec[5]),
        .io_out_bits_uop_exceptionVec_6                   (io_uopWriteback[d].uop.exceptionVec[6]),
        .io_out_bits_uop_exceptionVec_7                   (io_uopWriteback[d].uop.exceptionVec[7]),
        .io_out_bits_uop_exceptionVec_13                  (io_uopWriteback[d].uop.exceptionVec[13]),
        .io_out_bits_uop_exceptionVec_15                  (io_uopWriteback[d].uop.exceptionVec[15]),
        .io_out_bits_uop_exceptionVec_19                  (io_uopWriteback[d].uop.exceptionVec[19]),
        .io_out_bits_uop_exceptionVec_21                  (io_uopWriteback[d].uop.exceptionVec[21]),
        .io_out_bits_uop_exceptionVec_23                  (io_uopWriteback[d].uop.exceptionVec[23]),
        .io_out_bits_uop_trigger                          (io_uopWriteback[d].uop.trigger),
        .io_out_bits_uop_fuOpType                         (io_uopWriteback[d].uop.fuOpType),
        .io_out_bits_uop_vecWen                           (io_uopWriteback[d].uop.vecWen),
        .io_out_bits_uop_v0Wen                            (io_uopWriteback[d].uop.v0Wen),
        .io_out_bits_uop_vlWen                            (io_uopWriteback[d].uop.vlWen),
        .io_out_bits_uop_flushPipe                        (io_uopWriteback[d].uop.flushPipe),
        .io_out_bits_uop_vpu_vill                         (io_uopWriteback[d].uop.vpu_vill),
        .io_out_bits_uop_vpu_vma                          (io_uopWriteback[d].uop.vpu_vma),
        .io_out_bits_uop_vpu_vta                          (io_uopWriteback[d].uop.vpu_vta),
        .io_out_bits_uop_vpu_vsew                         (io_uopWriteback[d].uop.vpu_vsew),
        .io_out_bits_uop_vpu_vlmul                        (io_uopWriteback[d].uop.vpu_vlmul),
        .io_out_bits_uop_vpu_specVill                     (io_uopWriteback[d].uop.vpu_specVill),
        .io_out_bits_uop_vpu_specVma                      (io_uopWriteback[d].uop.vpu_specVma),
        .io_out_bits_uop_vpu_specVta                      (io_uopWriteback[d].uop.vpu_specVta),
        .io_out_bits_uop_vpu_specVsew                     (io_uopWriteback[d].uop.vpu_specVsew),
        .io_out_bits_uop_vpu_specVlmul                    (io_uopWriteback[d].uop.vpu_specVlmul),
        .io_out_bits_uop_vpu_vm                           (io_uopWriteback[d].uop.vpu_vm),
        .io_out_bits_uop_vpu_vstart                       (io_uopWriteback[d].uop.vpu_vstart),
        .io_out_bits_uop_vpu_frm                          (io_uopWriteback[d].uop.vpu_frm),
        .io_out_bits_uop_vpu_fpu_isFpToVecInst            (io_uopWriteback[d].uop.vpu_fpu_isFpToVecInst),
        .io_out_bits_uop_vpu_fpu_isFP32Instr              (io_uopWriteback[d].uop.vpu_fpu_isFP32Instr),
        .io_out_bits_uop_vpu_fpu_isFP64Instr              (io_uopWriteback[d].uop.vpu_fpu_isFP64Instr),
        .io_out_bits_uop_vpu_fpu_isReduction              (io_uopWriteback[d].uop.vpu_fpu_isReduction),
        .io_out_bits_uop_vpu_fpu_isFoldTo1_2              (io_uopWriteback[d].uop.vpu_fpu_isFoldTo1_2),
        .io_out_bits_uop_vpu_fpu_isFoldTo1_4              (io_uopWriteback[d].uop.vpu_fpu_isFoldTo1_4),
        .io_out_bits_uop_vpu_fpu_isFoldTo1_8              (io_uopWriteback[d].uop.vpu_fpu_isFoldTo1_8),
        .io_out_bits_uop_vpu_vxrm                         (io_uopWriteback[d].uop.vpu_vxrm),
        .io_out_bits_uop_vpu_vuopIdx                      (io_uopWriteback[d].uop.vpu_vuopIdx),
        .io_out_bits_uop_vpu_lastUop                      (io_uopWriteback[d].uop.vpu_lastUop),
        .io_out_bits_uop_vpu_vmask                        (io_uopWriteback[d].uop.vpu_vmask),
        .io_out_bits_uop_vpu_vl                           (io_uopWriteback[d].uop.vpu_vl),
        .io_out_bits_uop_vpu_nf                           (io_uopWriteback[d].uop.vpu_nf),
        .io_out_bits_uop_vpu_veew                         (io_uopWriteback[d].uop.vpu_veew),
        .io_out_bits_uop_vpu_isReverse                    (io_uopWriteback[d].uop.vpu_isReverse),
        .io_out_bits_uop_vpu_isExt                        (io_uopWriteback[d].uop.vpu_isExt),
        .io_out_bits_uop_vpu_isNarrow                     (io_uopWriteback[d].uop.vpu_isNarrow),
        .io_out_bits_uop_vpu_isDstMask                    (io_uopWriteback[d].uop.vpu_isDstMask),
        .io_out_bits_uop_vpu_isOpMask                     (io_uopWriteback[d].uop.vpu_isOpMask),
        .io_out_bits_uop_vpu_isMove                       (io_uopWriteback[d].uop.vpu_isMove),
        .io_out_bits_uop_vpu_isDependOldVd                (io_uopWriteback[d].uop.vpu_isDependOldVd),
        .io_out_bits_uop_vpu_isWritePartVd                (io_uopWriteback[d].uop.vpu_isWritePartVd),
        .io_out_bits_uop_vpu_isVleff                      (io_uopWriteback[d].uop.vpu_isVleff),
        .io_out_bits_uop_psrc_2                           (io_uopWriteback[d].uop.psrc_2),
        .io_out_bits_uop_pdest                            (io_uopWriteback[d].uop.pdest),
        .io_out_bits_uop_robIdx_flag                      (io_uopWriteback[d].uop.robIdx_flag),
        .io_out_bits_uop_robIdx_value                     (io_uopWriteback[d].uop.robIdx_value),
        .io_out_bits_uop_debugInfo_eliminatedMove         (io_uopWriteback[d].uop.debugInfo_eliminatedMove),
        .io_out_bits_uop_debugInfo_renameTime             (io_uopWriteback[d].uop.debugInfo_renameTime),
        .io_out_bits_uop_debugInfo_dispatchTime           (io_uopWriteback[d].uop.debugInfo_dispatchTime),
        .io_out_bits_uop_debugInfo_enqRsTime              (io_uopWriteback[d].uop.debugInfo_enqRsTime),
        .io_out_bits_uop_debugInfo_selectTime             (io_uopWriteback[d].uop.debugInfo_selectTime),
        .io_out_bits_uop_debugInfo_issueTime              (io_uopWriteback[d].uop.debugInfo_issueTime),
        .io_out_bits_uop_debugInfo_writebackTime          (io_uopWriteback[d].uop.debugInfo_writebackTime),
        .io_out_bits_uop_debugInfo_runahead_checkpoint_id (io_uopWriteback[d].uop.debugInfo_runahead_checkpoint_id),
        .io_out_bits_uop_debugInfo_tlbFirstReqTime        (io_uopWriteback[d].uop.debugInfo_tlbFirstReqTime),
        .io_out_bits_uop_debugInfo_tlbRespTime            (io_uopWriteback[d].uop.debugInfo_tlbRespTime),
        .io_out_bits_uop_debug_seqNum_seqNum              (io_uopWriteback[d].uop.debug_seqNum_seqNum),
        .io_out_bits_uop_debug_seqNum_uopIdx              (io_uopWriteback[d].uop.debug_seqNum_uopIdx),
        .io_out_bits_uop_replayInst                       (io_uopWriteback[d].uop.replayInst),
        .io_out_bits_data                                 (io_uopWriteback[d].data),
        .io_out_bits_vdIdx                                (io_uopWriteback[d].vdIdx),
        .io_out_bits_vdIdxInField                         (io_uopWriteback[d].vdIdxInField),
        .io_rightOutFire                                  (io_uopWriteback_ready[d] && pipe_out_valid[d]),
        .io_isFlush                                       (isFlush)
      );
      // 流水缓冲不携带的写回字段：接常量（wrapper 也不读它们）
      assign io_uopWriteback[d].uop.exceptionVec[0] = 1'b0;
      assign io_uopWriteback[d].uop.exceptionVec[1] = 1'b0;
      assign io_uopWriteback[d].uop.exceptionVec[2] = 1'b0;
      assign io_uopWriteback[d].uop.exceptionVec[8] = 1'b0;
      assign io_uopWriteback[d].uop.exceptionVec[9] = 1'b0;
      assign io_uopWriteback[d].uop.exceptionVec[10] = 1'b0;
      assign io_uopWriteback[d].uop.exceptionVec[11] = 1'b0;
      assign io_uopWriteback[d].uop.exceptionVec[12] = 1'b0;
      assign io_uopWriteback[d].uop.exceptionVec[14] = 1'b0;
      assign io_uopWriteback[d].uop.exceptionVec[16] = 1'b0;
      assign io_uopWriteback[d].uop.exceptionVec[17] = 1'b0;
      assign io_uopWriteback[d].uop.exceptionVec[18] = 1'b0;
      assign io_uopWriteback[d].uop.exceptionVec[20] = 1'b0;
      assign io_uopWriteback[d].uop.exceptionVec[22] = 1'b0;
      assign io_uopWriteback[d].uop.uopIdx = '0;
      assign io_uopWriteback[d].uop.lqIdx_flag = '0;
      assign io_uopWriteback[d].uop.lqIdx_value = '0;
      assign io_uopWriteback[d].uop.sqIdx_flag = '0;
      assign io_uopWriteback[d].uop.sqIdx_value = '0;
      // END GENERATED
    end
  endgenerate

  // 发射队列反馈：出队选中（不论写回还是部分重放）即反馈，打一拍送出
  logic                fb_valid_REG             [DEQ_W];
  logic                fb_r_robIdx_flag         [DEQ_W];
  logic [ROB_W-1:0]    fb_r_robIdx_value        [DEQ_W];
  logic                fb_r_hit                 [DEQ_W];
  logic [3:0]          fb_r_sourceType          [DEQ_W];
  logic                fb_r_sqIdx_flag          [DEQ_W];
  logic [5:0]          fb_r_sqIdx_value         [DEQ_W];
  logic                fb_r_lqIdx_flag          [DEQ_W];
  logic [6:0]          fb_r_lqIdx_value         [DEQ_W];
  logic                fb_r_isVecPartReplay     [DEQ_W];
  logic [VLENB-1:0]    fb_r_vecReplayMask       [DEQ_W];
  logic [MB_IDX_W-1:0] fb_r_vecReplayMbIdx      [DEQ_W];
  logic                fb_r_flushState          [DEQ_W];  // 只有 load 版有

  logic                feedbackValid            [DEQ_W];

  always_comb begin
    for (int d = 0; d < DEQ_W; d++) feedbackValid[d] = deq_fire[d] && allocated[deq_idx[d]];
  end

  always_ff @(posedge clock) begin
    for (int d = 0; d < DEQ_W; d++) begin
      fb_valid_REG[d] <= feedbackValid[d];
      if (feedbackValid[d]) begin
        fb_r_robIdx_flag[d]     <= entries_uop[deq_idx[d]].robIdx_flag;
        fb_r_robIdx_value[d]    <= entries_uop[deq_idx[d]].robIdx_value;
        fb_r_hit[d]             <= !needRSReplay[deq_idx[d]];
        fb_r_sourceType[d]      <= {1'b0, entries_sourceType[deq_idx[d]]};
        fb_r_sqIdx_flag[d]      <= entries_uop[deq_idx[d]].sqIdx_flag;
        fb_r_sqIdx_value[d]     <= entries_uop[deq_idx[d]].sqIdx_value;
        fb_r_lqIdx_flag[d]      <= entries_uop[deq_idx[d]].lqIdx_flag;
        fb_r_lqIdx_value[d]     <= entries_uop[deq_idx[d]].lqIdx_value;
        fb_r_isVecPartReplay[d] <= deq_partial[d];
        fb_r_vecReplayMask[d]   <= entries_replayFlowMask[deq_idx[d]];
        fb_r_vecReplayMbIdx[d]  <= deq_idx[d];
      end
    end
  end

  generate
    if (!IS_VSTORE) begin : g_fb_flushstate
      always_ff @(posedge clock) begin
        for (int d = 0; d < DEQ_W; d++) begin
          if (feedbackValid[d]) fb_r_flushState[d] <= entries_flushState[deq_idx[d]];
        end
      end
    end else begin : g_no_fb_flushstate
      always_comb for (int d = 0; d < DEQ_W; d++) fb_r_flushState[d] = 1'b0;
    end
  endgenerate

  always_comb begin
    for (int d = 0; d < DEQ_W; d++) begin
      io_feedback[d]                 = '0;
      io_feedback[d].valid           = fb_valid_REG[d];
      io_feedback[d].robIdx_flag     = fb_r_robIdx_flag[d];
      io_feedback[d].robIdx_value    = fb_r_robIdx_value[d];
      io_feedback[d].hit             = fb_r_hit[d];
      io_feedback[d].flushState      = fb_r_flushState[d];
      io_feedback[d].sourceType      = fb_r_sourceType[d];
      io_feedback[d].sqIdx_flag      = fb_r_sqIdx_flag[d];
      io_feedback[d].sqIdx_value     = fb_r_sqIdx_value[d];
      io_feedback[d].lqIdx_flag      = fb_r_lqIdx_flag[d];
      io_feedback[d].lqIdx_value     = fb_r_lqIdx_value[d];
      io_feedback[d].isVecPartReplay = fb_r_isVecPartReplay[d];
      io_feedback[d].vecReplayMask   = fb_r_vecReplayMask[d];
      io_feedback[d].vecReplayMbIdx  = fb_r_vecReplayMbIdx[d];
    end
  end

  // ---------------------------------------------------------------------------
  // §11 条目寄存器更新（按 Chisel 源码里各处赋值的先后顺序写，后写的覆盖先写的）
  // ---------------------------------------------------------------------------
  // 控制位：入队置位 -> redirect 作废 -> 没命中置 needRSReplay -> 完成置 uopFinish -> 出队清除
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int e = 0; e < MB_SIZE; e++) begin
        allocated[e]    <= 1'b0;
        uopFinish[e]    <= 1'b0;
        needRSReplay[e] <= 1'b0;
      end
    end else begin
      for (int e = 0; e < MB_SIZE; e++) begin
        for (int p = 0; p < ENQ_W; p++) begin
          if (enq_fire[p] && enq_idx[p] == MB_IDX_W'(e)) begin
            allocated[e]    <= 1'b1;
            uopFinish[e]    <= 1'b0;
            needRSReplay[e] <= 1'b0;
          end
        end
        if (needCancel[e]) begin
          allocated[e]    <= 1'b0;
          uopFinish[e]    <= 1'b0;
          needRSReplay[e] <= 1'b0;
        end
        for (int i = 0; i < PIPE_W; i++) begin
          if (rs_set[i] && io_fromPipeline[i].mBIndex == MB_IDX_W'(e)) needRSReplay[e] <= 1'b1;
        end
        if (allocated[e] && entries_flowNum[e] == '0 && !needCancel[e]) uopFinish[e] <= 1'b1;
        for (int d = 0; d < DEQ_W; d++) begin
          if (deq_fire[d] && deq_idx[d] == MB_IDX_W'(e)) begin
            needRSReplay[e] <= 1'b0;
            uopFinish[e]    <= 1'b0;
            if (!deq_partial[d]) allocated[e] <= 1'b0;
          end
        end
      end
    end
  end

  // 两个变体都有的数据字段
  always_ff @(posedge clock) begin
    for (int e = 0; e < MB_SIZE; e++) begin
      // (1) 入队 EnqConnect
      for (int p = 0; p < ENQ_W; p++) begin
        if (enq_fire[p] && enq_idx[p] == MB_IDX_W'(e)) begin
          entries_mask[e]           <= io_fromSplit_req[p].mask;
          entries_flowNum[e]        <= io_fromSplit_req[p].flowNum;
          entries_exceptionVec[e]   <= '0;
          entries_uop_trigger[e]    <= io_fromSplit_req[p].uop.trigger;
          entries_sourceType[e]     <= '0;
          entries_elemIdx[e]        <= '1;
          entries_vlmax[e]          <= io_fromSplit_req[p].vlmax;
          entries_vaddr[e]          <= 64'(io_fromSplit_req[p].vaddr);
          entries_vstart[e]         <= '0;
          entries_replayFlowNum[e]  <= '0;
          entries_replayFlowMask[e] <= '0;
        end
      end
      // (2) 异常写回
      for (int i = 0; i < PIPE_W; i++) begin
        if (exc_upd[i] && exc_idx[i] == MB_IDX_W'(e)) begin
          entries_elemIdx[e] <= exc_elemIdx[i];
          if (exc_fof_ok[i]) begin
            entries_vstart[e]            <= exc_vstart[i];
            entries_exceptionVec[e]      <= exc_vec[i];
            entries_uop_trigger[e]       <= exc_trigger[i];
            entries_vaddr[e]             <= exc_vaddr[i];
            entries_vaNeedExt[e]         <= exc_vaNeedExt[i];
            entries_gpaddr[e]            <= exc_gpaddr[i];
            entries_isForVSnonLeafPTE[e] <= exc_isForVSnonLeafPTE[i];
          end
        end
      end
      // (3) 计数写回
      for (int i = 0; i < PIPE_W; i++) begin
        if (cnt_upd[i] && cnt_idx[i] == MB_IDX_W'(e)) begin
          entries_flowNum[e] <= cnt_flowNum_new[i];
          if (replay_upd[i]) begin
            entries_replayFlowNum[e]  <= replay_num_new[i];
            entries_replayFlowMask[e] <= replay_mask_new[i];
          end
        end
      end
      // (4) 当拍 sourceType
      for (int i = 0; i < PIPE_W; i++) begin
        if (io_fromPipeline[i].valid && io_fromPipeline[i].mBIndex == MB_IDX_W'(e)) begin
          entries_sourceType[e] <= src_type_new[i];
        end
      end
      // (5) 出队：清重放记录；部分重放则把 flowNum 设成要重放的 flow 数
      for (int d = 0; d < DEQ_W; d++) begin
        if (deq_fire[d] && deq_idx[d] == MB_IDX_W'(e)) begin
          entries_replayFlowNum[e]  <= '0;
          entries_replayFlowMask[e] <= '0;
          if (deq_partial[d]) entries_flowNum[e] <= entries_replayFlowNum[e];
        end
      end
    end
  end

  generate
    if (!IS_VSTORE) begin : g_vl_fields
      always_ff @(posedge clock) begin
        for (int e = 0; e < MB_SIZE; e++) begin
          for (int p = 0; p < ENQ_W; p++) begin
            if (enq_fire[p] && enq_idx[p] == MB_IDX_W'(e)) begin
              entries_data[e]       <= io_fromSplit_req[p].data;
              entries_vdIdx[e]      <= io_fromSplit_req[p].vdIdx;
              entries_fof[e]        <= io_fromSplit_req[p].fof;
              entries_vl[e]         <= io_fromSplit_req[p].uop.vpu_vl;
              entries_originVl[e]   <= io_fromSplit_req[p].uop.vpu_vl;
              entries_flushState[e] <= 1'b0;
            end
          end
          for (int i = 0; i < PIPE_W; i++) begin
            if (exc_upd[i] && exc_idx[i] == MB_IDX_W'(e) && !exc_fof_ok[i]) entries_vl[e] <= exc_vl[i];
          end
          for (int i = 0; i < PIPE_W; i++) begin
            if (io_fromPipeline[i].valid && io_fromPipeline[i].mBIndex == MB_IDX_W'(e)) begin
              entries_flushState[e] <= io_fromPipeline[i].flushState;
            end
          end
          for (int i = 0; i < PIPE_W; i++) begin
            if (data_upd[i] && data_idx[i] == MB_IDX_W'(e)) entries_data[e] <= data_new[i];
          end
        end
      end
      always_comb begin
        for (int e = 0; e < MB_SIZE; e++) begin
          entries_isPartReplay[e]  = 1'b0;
          entries_uop_vpu_vmask[e] = '0;
          entries_uop_vpu_vl[e]    = '0;
        end
      end
    end else begin : g_vs_fields
      always_ff @(posedge clock) begin
        for (int e = 0; e < MB_SIZE; e++) begin
          for (int p = 0; p < ENQ_W; p++) begin
            if (enq_fire[p] && enq_idx[p] == MB_IDX_W'(e)) begin
              entries_isPartReplay[e]  <= 1'b0;
              entries_uop_vpu_vmask[e] <= io_fromSplit_req[p].uop.vpu_vmask;
              entries_uop_vpu_vl[e]    <= io_fromSplit_req[p].uop.vpu_vl;
            end
          end
          for (int i = 0; i < PIPE_W; i++) begin
            if (rs_set[i] && io_fromPipeline[i].mBIndex == MB_IDX_W'(e)) entries_isPartReplay[e] <= 1'b1;
          end
        end
      end
      always_comb begin
        for (int e = 0; e < MB_SIZE; e++) begin
          entries_data[e]       = '0;
          entries_vdIdx[e]      = '0;
          entries_fof[e]        = 1'b0;
          entries_vl[e]         = '0;
          entries_originVl[e]   = '0;
          entries_flushState[e] = 1'b0;
        end
      end
    end
  endgenerate

  // 入队照抄、出队原样送出的 uop 字段（每字段一个数组 + 拼回 struct 的只读视图）
  // BEGIN GENERATED(uop_store)
  logic [8:0]    entries_uop_fuOpType                           [MB_SIZE];
  logic          entries_uop_vecWen                             [MB_SIZE];
  logic          entries_uop_v0Wen                              [MB_SIZE];
  logic          entries_uop_vlWen                              [MB_SIZE];
  logic          entries_uop_flushPipe                          [MB_SIZE];
  logic          entries_uop_vpu_vill                           [MB_SIZE];
  logic          entries_uop_vpu_vma                            [MB_SIZE];
  logic          entries_uop_vpu_vta                            [MB_SIZE];
  logic [1:0]    entries_uop_vpu_vsew                           [MB_SIZE];
  logic [2:0]    entries_uop_vpu_vlmul                          [MB_SIZE];
  logic          entries_uop_vpu_specVill                       [MB_SIZE];
  logic          entries_uop_vpu_specVma                        [MB_SIZE];
  logic          entries_uop_vpu_specVta                        [MB_SIZE];
  logic [1:0]    entries_uop_vpu_specVsew                       [MB_SIZE];
  logic [2:0]    entries_uop_vpu_specVlmul                      [MB_SIZE];
  logic          entries_uop_vpu_vm                             [MB_SIZE];
  logic [2:0]    entries_uop_vpu_frm                            [MB_SIZE];
  logic          entries_uop_vpu_fpu_isFpToVecInst              [MB_SIZE];
  logic          entries_uop_vpu_fpu_isFP32Instr                [MB_SIZE];
  logic          entries_uop_vpu_fpu_isFP64Instr                [MB_SIZE];
  logic          entries_uop_vpu_fpu_isReduction                [MB_SIZE];
  logic          entries_uop_vpu_fpu_isFoldTo1_2                [MB_SIZE];
  logic          entries_uop_vpu_fpu_isFoldTo1_4                [MB_SIZE];
  logic          entries_uop_vpu_fpu_isFoldTo1_8                [MB_SIZE];
  logic [1:0]    entries_uop_vpu_vxrm                           [MB_SIZE];
  logic [6:0]    entries_uop_vpu_vuopIdx                        [MB_SIZE];
  logic          entries_uop_vpu_lastUop                        [MB_SIZE];
  logic [2:0]    entries_uop_vpu_nf                             [MB_SIZE];
  logic [1:0]    entries_uop_vpu_veew                           [MB_SIZE];
  logic          entries_uop_vpu_isReverse                      [MB_SIZE];
  logic          entries_uop_vpu_isExt                          [MB_SIZE];
  logic          entries_uop_vpu_isNarrow                       [MB_SIZE];
  logic          entries_uop_vpu_isDstMask                      [MB_SIZE];
  logic          entries_uop_vpu_isOpMask                       [MB_SIZE];
  logic          entries_uop_vpu_isMove                         [MB_SIZE];
  logic          entries_uop_vpu_isDependOldVd                  [MB_SIZE];
  logic          entries_uop_vpu_isWritePartVd                  [MB_SIZE];
  logic          entries_uop_vpu_isVleff                        [MB_SIZE];
  logic [7:0]    entries_uop_psrc_2                             [MB_SIZE];
  logic [7:0]    entries_uop_pdest                              [MB_SIZE];
  logic          entries_uop_robIdx_flag                        [MB_SIZE];
  logic [7:0]    entries_uop_robIdx_value                       [MB_SIZE];
  logic          entries_uop_debugInfo_eliminatedMove           [MB_SIZE];
  logic [63:0]   entries_uop_debugInfo_renameTime               [MB_SIZE];
  logic [63:0]   entries_uop_debugInfo_dispatchTime             [MB_SIZE];
  logic [63:0]   entries_uop_debugInfo_enqRsTime                [MB_SIZE];
  logic [63:0]   entries_uop_debugInfo_selectTime               [MB_SIZE];
  logic [63:0]   entries_uop_debugInfo_issueTime                [MB_SIZE];
  logic [63:0]   entries_uop_debugInfo_writebackTime            [MB_SIZE];
  logic [63:0]   entries_uop_debugInfo_runahead_checkpoint_id   [MB_SIZE];
  logic [63:0]   entries_uop_debugInfo_tlbFirstReqTime          [MB_SIZE];
  logic [63:0]   entries_uop_debugInfo_tlbRespTime              [MB_SIZE];
  logic [55:0]   entries_uop_debug_seqNum_seqNum                [MB_SIZE];
  logic [7:0]    entries_uop_debug_seqNum_uopIdx                [MB_SIZE];
  logic          entries_uop_replayInst                         [MB_SIZE];
  logic [6:0]    entries_uop_uopIdx                             [MB_SIZE];
  logic          entries_uop_lqIdx_flag                         [MB_SIZE];
  logic [6:0]    entries_uop_lqIdx_value                        [MB_SIZE];
  logic          entries_uop_sqIdx_flag                         [MB_SIZE];
  logic [5:0]    entries_uop_sqIdx_value                        [MB_SIZE];

  always_ff @(posedge clock) begin
    for (int e = 0; e < MB_SIZE; e++) begin
      for (int p = 0; p < ENQ_W; p++) begin
        if (enq_fire[p] && enq_idx[p] == MB_IDX_W'(e)) begin
          entries_uop_fuOpType[e]                            <= io_fromSplit_req[p].uop.fuOpType;
          entries_uop_vecWen[e]                              <= io_fromSplit_req[p].uop.vecWen;
          entries_uop_v0Wen[e]                               <= io_fromSplit_req[p].uop.v0Wen;
          entries_uop_vlWen[e]                               <= io_fromSplit_req[p].uop.vlWen;
          entries_uop_flushPipe[e]                           <= io_fromSplit_req[p].uop.flushPipe;
          entries_uop_vpu_vill[e]                            <= io_fromSplit_req[p].uop.vpu_vill;
          entries_uop_vpu_vma[e]                             <= io_fromSplit_req[p].uop.vpu_vma;
          entries_uop_vpu_vta[e]                             <= io_fromSplit_req[p].uop.vpu_vta;
          entries_uop_vpu_vsew[e]                            <= io_fromSplit_req[p].uop.vpu_vsew;
          entries_uop_vpu_vlmul[e]                           <= io_fromSplit_req[p].uop.vpu_vlmul;
          entries_uop_vpu_specVill[e]                        <= io_fromSplit_req[p].uop.vpu_specVill;
          entries_uop_vpu_specVma[e]                         <= io_fromSplit_req[p].uop.vpu_specVma;
          entries_uop_vpu_specVta[e]                         <= io_fromSplit_req[p].uop.vpu_specVta;
          entries_uop_vpu_specVsew[e]                        <= io_fromSplit_req[p].uop.vpu_specVsew;
          entries_uop_vpu_specVlmul[e]                       <= io_fromSplit_req[p].uop.vpu_specVlmul;
          entries_uop_vpu_vm[e]                              <= io_fromSplit_req[p].uop.vpu_vm;
          entries_uop_vpu_frm[e]                             <= io_fromSplit_req[p].uop.vpu_frm;
          entries_uop_vpu_fpu_isFpToVecInst[e]               <= io_fromSplit_req[p].uop.vpu_fpu_isFpToVecInst;
          entries_uop_vpu_fpu_isFP32Instr[e]                 <= io_fromSplit_req[p].uop.vpu_fpu_isFP32Instr;
          entries_uop_vpu_fpu_isFP64Instr[e]                 <= io_fromSplit_req[p].uop.vpu_fpu_isFP64Instr;
          entries_uop_vpu_fpu_isReduction[e]                 <= io_fromSplit_req[p].uop.vpu_fpu_isReduction;
          entries_uop_vpu_fpu_isFoldTo1_2[e]                 <= io_fromSplit_req[p].uop.vpu_fpu_isFoldTo1_2;
          entries_uop_vpu_fpu_isFoldTo1_4[e]                 <= io_fromSplit_req[p].uop.vpu_fpu_isFoldTo1_4;
          entries_uop_vpu_fpu_isFoldTo1_8[e]                 <= io_fromSplit_req[p].uop.vpu_fpu_isFoldTo1_8;
          entries_uop_vpu_vxrm[e]                            <= io_fromSplit_req[p].uop.vpu_vxrm;
          entries_uop_vpu_vuopIdx[e]                         <= io_fromSplit_req[p].uop.vpu_vuopIdx;
          entries_uop_vpu_lastUop[e]                         <= io_fromSplit_req[p].uop.vpu_lastUop;
          entries_uop_vpu_nf[e]                              <= io_fromSplit_req[p].uop.vpu_nf;
          entries_uop_vpu_veew[e]                            <= io_fromSplit_req[p].uop.vpu_veew;
          entries_uop_vpu_isReverse[e]                       <= io_fromSplit_req[p].uop.vpu_isReverse;
          entries_uop_vpu_isExt[e]                           <= io_fromSplit_req[p].uop.vpu_isExt;
          entries_uop_vpu_isNarrow[e]                        <= io_fromSplit_req[p].uop.vpu_isNarrow;
          entries_uop_vpu_isDstMask[e]                       <= io_fromSplit_req[p].uop.vpu_isDstMask;
          entries_uop_vpu_isOpMask[e]                        <= io_fromSplit_req[p].uop.vpu_isOpMask;
          entries_uop_vpu_isMove[e]                          <= io_fromSplit_req[p].uop.vpu_isMove;
          entries_uop_vpu_isDependOldVd[e]                   <= io_fromSplit_req[p].uop.vpu_isDependOldVd;
          entries_uop_vpu_isWritePartVd[e]                   <= io_fromSplit_req[p].uop.vpu_isWritePartVd;
          entries_uop_vpu_isVleff[e]                         <= io_fromSplit_req[p].uop.vpu_isVleff;
          entries_uop_psrc_2[e]                              <= io_fromSplit_req[p].uop.psrc_2;
          entries_uop_pdest[e]                               <= io_fromSplit_req[p].uop.pdest;
          entries_uop_robIdx_flag[e]                         <= io_fromSplit_req[p].uop.robIdx_flag;
          entries_uop_robIdx_value[e]                        <= io_fromSplit_req[p].uop.robIdx_value;
          entries_uop_debugInfo_eliminatedMove[e]            <= io_fromSplit_req[p].uop.debugInfo_eliminatedMove;
          entries_uop_debugInfo_renameTime[e]                <= io_fromSplit_req[p].uop.debugInfo_renameTime;
          entries_uop_debugInfo_dispatchTime[e]              <= io_fromSplit_req[p].uop.debugInfo_dispatchTime;
          entries_uop_debugInfo_enqRsTime[e]                 <= io_fromSplit_req[p].uop.debugInfo_enqRsTime;
          entries_uop_debugInfo_selectTime[e]                <= io_fromSplit_req[p].uop.debugInfo_selectTime;
          entries_uop_debugInfo_issueTime[e]                 <= io_fromSplit_req[p].uop.debugInfo_issueTime;
          entries_uop_debugInfo_writebackTime[e]             <= io_fromSplit_req[p].uop.debugInfo_writebackTime;
          entries_uop_debugInfo_runahead_checkpoint_id[e]    <= io_fromSplit_req[p].uop.debugInfo_runahead_checkpoint_id;
          entries_uop_debugInfo_tlbFirstReqTime[e]           <= io_fromSplit_req[p].uop.debugInfo_tlbFirstReqTime;
          entries_uop_debugInfo_tlbRespTime[e]               <= io_fromSplit_req[p].uop.debugInfo_tlbRespTime;
          entries_uop_debug_seqNum_seqNum[e]                 <= io_fromSplit_req[p].uop.debug_seqNum_seqNum;
          entries_uop_debug_seqNum_uopIdx[e]                 <= io_fromSplit_req[p].uop.debug_seqNum_uopIdx;
          entries_uop_replayInst[e]                          <= io_fromSplit_req[p].uop.replayInst;
          entries_uop_uopIdx[e]                              <= io_fromSplit_req[p].uop.uopIdx;
          entries_uop_lqIdx_flag[e]                          <= io_fromSplit_req[p].uop.lqIdx_flag;
          entries_uop_lqIdx_value[e]                         <= io_fromSplit_req[p].uop.lqIdx_value;
          entries_uop_sqIdx_flag[e]                          <= io_fromSplit_req[p].uop.sqIdx_flag;
          entries_uop_sqIdx_value[e]                         <= io_fromSplit_req[p].uop.sqIdx_value;
        end
      end
    end
  end

  always_comb begin
    for (int e = 0; e < MB_SIZE; e++) begin
      entries_uop[e] = '0;
      entries_uop[e].fuOpType                           = entries_uop_fuOpType[e];
      entries_uop[e].vecWen                             = entries_uop_vecWen[e];
      entries_uop[e].v0Wen                              = entries_uop_v0Wen[e];
      entries_uop[e].vlWen                              = entries_uop_vlWen[e];
      entries_uop[e].flushPipe                          = entries_uop_flushPipe[e];
      entries_uop[e].vpu_vill                           = entries_uop_vpu_vill[e];
      entries_uop[e].vpu_vma                            = entries_uop_vpu_vma[e];
      entries_uop[e].vpu_vta                            = entries_uop_vpu_vta[e];
      entries_uop[e].vpu_vsew                           = entries_uop_vpu_vsew[e];
      entries_uop[e].vpu_vlmul                          = entries_uop_vpu_vlmul[e];
      entries_uop[e].vpu_specVill                       = entries_uop_vpu_specVill[e];
      entries_uop[e].vpu_specVma                        = entries_uop_vpu_specVma[e];
      entries_uop[e].vpu_specVta                        = entries_uop_vpu_specVta[e];
      entries_uop[e].vpu_specVsew                       = entries_uop_vpu_specVsew[e];
      entries_uop[e].vpu_specVlmul                      = entries_uop_vpu_specVlmul[e];
      entries_uop[e].vpu_vm                             = entries_uop_vpu_vm[e];
      entries_uop[e].vpu_frm                            = entries_uop_vpu_frm[e];
      entries_uop[e].vpu_fpu_isFpToVecInst              = entries_uop_vpu_fpu_isFpToVecInst[e];
      entries_uop[e].vpu_fpu_isFP32Instr                = entries_uop_vpu_fpu_isFP32Instr[e];
      entries_uop[e].vpu_fpu_isFP64Instr                = entries_uop_vpu_fpu_isFP64Instr[e];
      entries_uop[e].vpu_fpu_isReduction                = entries_uop_vpu_fpu_isReduction[e];
      entries_uop[e].vpu_fpu_isFoldTo1_2                = entries_uop_vpu_fpu_isFoldTo1_2[e];
      entries_uop[e].vpu_fpu_isFoldTo1_4                = entries_uop_vpu_fpu_isFoldTo1_4[e];
      entries_uop[e].vpu_fpu_isFoldTo1_8                = entries_uop_vpu_fpu_isFoldTo1_8[e];
      entries_uop[e].vpu_vxrm                           = entries_uop_vpu_vxrm[e];
      entries_uop[e].vpu_vuopIdx                        = entries_uop_vpu_vuopIdx[e];
      entries_uop[e].vpu_lastUop                        = entries_uop_vpu_lastUop[e];
      entries_uop[e].vpu_nf                             = entries_uop_vpu_nf[e];
      entries_uop[e].vpu_veew                           = entries_uop_vpu_veew[e];
      entries_uop[e].vpu_isReverse                      = entries_uop_vpu_isReverse[e];
      entries_uop[e].vpu_isExt                          = entries_uop_vpu_isExt[e];
      entries_uop[e].vpu_isNarrow                       = entries_uop_vpu_isNarrow[e];
      entries_uop[e].vpu_isDstMask                      = entries_uop_vpu_isDstMask[e];
      entries_uop[e].vpu_isOpMask                       = entries_uop_vpu_isOpMask[e];
      entries_uop[e].vpu_isMove                         = entries_uop_vpu_isMove[e];
      entries_uop[e].vpu_isDependOldVd                  = entries_uop_vpu_isDependOldVd[e];
      entries_uop[e].vpu_isWritePartVd                  = entries_uop_vpu_isWritePartVd[e];
      entries_uop[e].vpu_isVleff                        = entries_uop_vpu_isVleff[e];
      entries_uop[e].psrc_2                             = entries_uop_psrc_2[e];
      entries_uop[e].pdest                              = entries_uop_pdest[e];
      entries_uop[e].robIdx_flag                        = entries_uop_robIdx_flag[e];
      entries_uop[e].robIdx_value                       = entries_uop_robIdx_value[e];
      entries_uop[e].debugInfo_eliminatedMove           = entries_uop_debugInfo_eliminatedMove[e];
      entries_uop[e].debugInfo_renameTime               = entries_uop_debugInfo_renameTime[e];
      entries_uop[e].debugInfo_dispatchTime             = entries_uop_debugInfo_dispatchTime[e];
      entries_uop[e].debugInfo_enqRsTime                = entries_uop_debugInfo_enqRsTime[e];
      entries_uop[e].debugInfo_selectTime               = entries_uop_debugInfo_selectTime[e];
      entries_uop[e].debugInfo_issueTime                = entries_uop_debugInfo_issueTime[e];
      entries_uop[e].debugInfo_writebackTime            = entries_uop_debugInfo_writebackTime[e];
      entries_uop[e].debugInfo_runahead_checkpoint_id   = entries_uop_debugInfo_runahead_checkpoint_id[e];
      entries_uop[e].debugInfo_tlbFirstReqTime          = entries_uop_debugInfo_tlbFirstReqTime[e];
      entries_uop[e].debugInfo_tlbRespTime              = entries_uop_debugInfo_tlbRespTime[e];
      entries_uop[e].debug_seqNum_seqNum                = entries_uop_debug_seqNum_seqNum[e];
      entries_uop[e].debug_seqNum_uopIdx                = entries_uop_debug_seqNum_uopIdx[e];
      entries_uop[e].replayInst                         = entries_uop_replayInst[e];
      entries_uop[e].uopIdx                             = entries_uop_uopIdx[e];
      entries_uop[e].lqIdx_flag                         = entries_uop_lqIdx_flag[e];
      entries_uop[e].lqIdx_value                        = entries_uop_lqIdx_value[e];
      entries_uop[e].sqIdx_flag                         = entries_uop_sqIdx_flag[e];
      entries_uop[e].sqIdx_value                        = entries_uop_sqIdx_value[e];
    end
  end
  // END GENERATED

endmodule

// =============================================================================
// VLMergeBufferImp —— golden 同名 wrapper（load 变体：16 条目 / 2 入队 / 3 写回 / 2 出队）
// =============================================================================
// BEGIN GENERATED(wrapper_VLMergeBufferImp)
module VLMergeBufferImp
  import vmergebuffer_pkg::*;
(
  input  logic               clock,
  input  logic               reset,
  input  logic               io_redirect_valid,
  input  logic               io_redirect_bits_robIdx_flag,
  input  logic [7:0]         io_redirect_bits_robIdx_value,
  input  logic               io_redirect_bits_level,
  input  logic               io_fromPipeline_0_valid,
  input  logic [3:0]         io_fromPipeline_0_bits_mBIndex,
  input  logic [3:0]         io_fromPipeline_0_bits_trigger,
  input  logic               io_fromPipeline_0_bits_exceptionVec_3,
  input  logic               io_fromPipeline_0_bits_exceptionVec_4,
  input  logic               io_fromPipeline_0_bits_exceptionVec_5,
  input  logic               io_fromPipeline_0_bits_exceptionVec_13,
  input  logic               io_fromPipeline_0_bits_exceptionVec_19,
  input  logic               io_fromPipeline_0_bits_exceptionVec_21,
  input  logic               io_fromPipeline_0_bits_hasException,
  input  logic [63:0]        io_fromPipeline_0_bits_vaddr,
  input  logic               io_fromPipeline_0_bits_vaNeedExt,
  input  logic [63:0]        io_fromPipeline_0_bits_gpaddr,
  input  logic               io_fromPipeline_0_bits_isForVSnonLeafPTE,
  input  logic [7:0]         io_fromPipeline_0_bits_vstart,
  input  logic [15:0]        io_fromPipeline_0_bits_vecTriggerMask,
  input  logic [7:0]         io_fromPipeline_0_bits_elemIdx,
  input  logic [15:0]        io_fromPipeline_0_bits_mask,
  input  logic [2:0]         io_fromPipeline_0_bits_alignedType,
  input  logic [3:0]         io_fromPipeline_0_bits_reg_offset,
  input  logic [7:0]         io_fromPipeline_0_bits_elemIdxInsideVd,
  input  logic [127:0]       io_fromPipeline_0_bits_vecdata,
  input  logic               io_fromPipeline_1_valid,
  input  logic [3:0]         io_fromPipeline_1_bits_mBIndex,
  input  logic [3:0]         io_fromPipeline_1_bits_trigger,
  input  logic               io_fromPipeline_1_bits_exceptionVec_3,
  input  logic               io_fromPipeline_1_bits_exceptionVec_4,
  input  logic               io_fromPipeline_1_bits_exceptionVec_5,
  input  logic               io_fromPipeline_1_bits_exceptionVec_13,
  input  logic               io_fromPipeline_1_bits_exceptionVec_19,
  input  logic               io_fromPipeline_1_bits_exceptionVec_21,
  input  logic               io_fromPipeline_1_bits_hasException,
  input  logic [63:0]        io_fromPipeline_1_bits_vaddr,
  input  logic               io_fromPipeline_1_bits_vaNeedExt,
  input  logic [63:0]        io_fromPipeline_1_bits_gpaddr,
  input  logic               io_fromPipeline_1_bits_isForVSnonLeafPTE,
  input  logic [7:0]         io_fromPipeline_1_bits_vstart,
  input  logic [15:0]        io_fromPipeline_1_bits_vecTriggerMask,
  input  logic [7:0]         io_fromPipeline_1_bits_elemIdx,
  input  logic [15:0]        io_fromPipeline_1_bits_mask,
  input  logic [2:0]         io_fromPipeline_1_bits_alignedType,
  input  logic [3:0]         io_fromPipeline_1_bits_reg_offset,
  input  logic [7:0]         io_fromPipeline_1_bits_elemIdxInsideVd,
  input  logic [127:0]       io_fromPipeline_1_bits_vecdata,
  input  logic               io_fromPipeline_2_valid,
  input  logic [3:0]         io_fromPipeline_2_bits_mBIndex,
  input  logic [3:0]         io_fromPipeline_2_bits_trigger,
  input  logic               io_fromPipeline_2_bits_exceptionVec_3,
  input  logic               io_fromPipeline_2_bits_exceptionVec_4,
  input  logic               io_fromPipeline_2_bits_exceptionVec_5,
  input  logic               io_fromPipeline_2_bits_exceptionVec_13,
  input  logic               io_fromPipeline_2_bits_exceptionVec_19,
  input  logic               io_fromPipeline_2_bits_exceptionVec_21,
  input  logic               io_fromPipeline_2_bits_hasException,
  input  logic [63:0]        io_fromPipeline_2_bits_vaddr,
  input  logic               io_fromPipeline_2_bits_vaNeedExt,
  input  logic [63:0]        io_fromPipeline_2_bits_gpaddr,
  input  logic               io_fromPipeline_2_bits_isForVSnonLeafPTE,
  input  logic [7:0]         io_fromPipeline_2_bits_vstart,
  input  logic [15:0]        io_fromPipeline_2_bits_vecTriggerMask,
  input  logic [7:0]         io_fromPipeline_2_bits_elemIdx,
  input  logic [15:0]        io_fromPipeline_2_bits_mask,
  input  logic [2:0]         io_fromPipeline_2_bits_alignedType,
  input  logic [3:0]         io_fromPipeline_2_bits_reg_offset,
  input  logic [7:0]         io_fromPipeline_2_bits_elemIdxInsideVd,
  input  logic [127:0]       io_fromPipeline_2_bits_vecdata,
  output logic               io_fromSplit_0_req_ready,
  input  logic               io_fromSplit_0_req_valid,
  input  logic [15:0]        io_fromSplit_0_req_bits_mask,
  input  logic [49:0]        io_fromSplit_0_req_bits_vaddr,
  input  logic [4:0]         io_fromSplit_0_req_bits_flowNum,
  input  logic [8:0]         io_fromSplit_0_req_bits_uop_fuOpType,
  input  logic               io_fromSplit_0_req_bits_uop_vecWen,
  input  logic               io_fromSplit_0_req_bits_uop_v0Wen,
  input  logic               io_fromSplit_0_req_bits_uop_vlWen,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_vill,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_vma,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_vta,
  input  logic [1:0]         io_fromSplit_0_req_bits_uop_vpu_vsew,
  input  logic [2:0]         io_fromSplit_0_req_bits_uop_vpu_vlmul,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_specVill,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_specVma,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_specVta,
  input  logic [1:0]         io_fromSplit_0_req_bits_uop_vpu_specVsew,
  input  logic [2:0]         io_fromSplit_0_req_bits_uop_vpu_specVlmul,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_vm,
  input  logic [2:0]         io_fromSplit_0_req_bits_uop_vpu_frm,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8,
  input  logic [1:0]         io_fromSplit_0_req_bits_uop_vpu_vxrm,
  input  logic [6:0]         io_fromSplit_0_req_bits_uop_vpu_vuopIdx,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_lastUop,
  input  logic [7:0]         io_fromSplit_0_req_bits_uop_vpu_vl,
  input  logic [2:0]         io_fromSplit_0_req_bits_uop_vpu_nf,
  input  logic [1:0]         io_fromSplit_0_req_bits_uop_vpu_veew,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isReverse,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isExt,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isNarrow,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isDstMask,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isOpMask,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isMove,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isDependOldVd,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isWritePartVd,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isVleff,
  input  logic [6:0]         io_fromSplit_0_req_bits_uop_uopIdx,
  input  logic [7:0]         io_fromSplit_0_req_bits_uop_pdest,
  input  logic               io_fromSplit_0_req_bits_uop_robIdx_flag,
  input  logic [7:0]         io_fromSplit_0_req_bits_uop_robIdx_value,
  input  logic               io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_renameTime,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_selectTime,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_issueTime,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_writebackTime,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime,
  input  logic [55:0]        io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum,
  input  logic [7:0]         io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx,
  input  logic               io_fromSplit_0_req_bits_uop_lqIdx_flag,
  input  logic [6:0]         io_fromSplit_0_req_bits_uop_lqIdx_value,
  input  logic               io_fromSplit_0_req_bits_uop_sqIdx_flag,
  input  logic [5:0]         io_fromSplit_0_req_bits_uop_sqIdx_value,
  input  logic [127:0]       io_fromSplit_0_req_bits_data,
  input  logic [2:0]         io_fromSplit_0_req_bits_vdIdx,
  input  logic               io_fromSplit_0_req_bits_fof,
  input  logic [7:0]         io_fromSplit_0_req_bits_vlmax,
  output logic               io_fromSplit_0_resp_valid,
  output logic [3:0]         io_fromSplit_0_resp_bits_mBIndex,
  output logic               io_fromSplit_1_req_ready,
  input  logic               io_fromSplit_1_req_valid,
  input  logic [15:0]        io_fromSplit_1_req_bits_mask,
  input  logic [49:0]        io_fromSplit_1_req_bits_vaddr,
  input  logic [4:0]         io_fromSplit_1_req_bits_flowNum,
  input  logic [8:0]         io_fromSplit_1_req_bits_uop_fuOpType,
  input  logic               io_fromSplit_1_req_bits_uop_vecWen,
  input  logic               io_fromSplit_1_req_bits_uop_v0Wen,
  input  logic               io_fromSplit_1_req_bits_uop_vlWen,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_vill,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_vma,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_vta,
  input  logic [1:0]         io_fromSplit_1_req_bits_uop_vpu_vsew,
  input  logic [2:0]         io_fromSplit_1_req_bits_uop_vpu_vlmul,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_specVill,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_specVma,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_specVta,
  input  logic [1:0]         io_fromSplit_1_req_bits_uop_vpu_specVsew,
  input  logic [2:0]         io_fromSplit_1_req_bits_uop_vpu_specVlmul,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_vm,
  input  logic [2:0]         io_fromSplit_1_req_bits_uop_vpu_frm,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_fpu_isFpToVecInst,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_fpu_isFP32Instr,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_fpu_isFP64Instr,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_fpu_isReduction,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_2,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_4,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_8,
  input  logic [1:0]         io_fromSplit_1_req_bits_uop_vpu_vxrm,
  input  logic [6:0]         io_fromSplit_1_req_bits_uop_vpu_vuopIdx,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_lastUop,
  input  logic [7:0]         io_fromSplit_1_req_bits_uop_vpu_vl,
  input  logic [2:0]         io_fromSplit_1_req_bits_uop_vpu_nf,
  input  logic [1:0]         io_fromSplit_1_req_bits_uop_vpu_veew,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_isReverse,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_isExt,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_isNarrow,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_isDstMask,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_isOpMask,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_isMove,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_isDependOldVd,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_isWritePartVd,
  input  logic               io_fromSplit_1_req_bits_uop_vpu_isVleff,
  input  logic [6:0]         io_fromSplit_1_req_bits_uop_uopIdx,
  input  logic [7:0]         io_fromSplit_1_req_bits_uop_pdest,
  input  logic               io_fromSplit_1_req_bits_uop_robIdx_flag,
  input  logic [7:0]         io_fromSplit_1_req_bits_uop_robIdx_value,
  input  logic               io_fromSplit_1_req_bits_uop_debugInfo_eliminatedMove,
  input  logic [63:0]        io_fromSplit_1_req_bits_uop_debugInfo_renameTime,
  input  logic [63:0]        io_fromSplit_1_req_bits_uop_debugInfo_dispatchTime,
  input  logic [63:0]        io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime,
  input  logic [63:0]        io_fromSplit_1_req_bits_uop_debugInfo_selectTime,
  input  logic [63:0]        io_fromSplit_1_req_bits_uop_debugInfo_issueTime,
  input  logic [63:0]        io_fromSplit_1_req_bits_uop_debugInfo_writebackTime,
  input  logic [63:0]        io_fromSplit_1_req_bits_uop_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]        io_fromSplit_1_req_bits_uop_debugInfo_tlbFirstReqTime,
  input  logic [63:0]        io_fromSplit_1_req_bits_uop_debugInfo_tlbRespTime,
  input  logic [55:0]        io_fromSplit_1_req_bits_uop_debug_seqNum_seqNum,
  input  logic [7:0]         io_fromSplit_1_req_bits_uop_debug_seqNum_uopIdx,
  input  logic               io_fromSplit_1_req_bits_uop_lqIdx_flag,
  input  logic [6:0]         io_fromSplit_1_req_bits_uop_lqIdx_value,
  input  logic               io_fromSplit_1_req_bits_uop_sqIdx_flag,
  input  logic [5:0]         io_fromSplit_1_req_bits_uop_sqIdx_value,
  input  logic [127:0]       io_fromSplit_1_req_bits_data,
  input  logic [2:0]         io_fromSplit_1_req_bits_vdIdx,
  input  logic               io_fromSplit_1_req_bits_fof,
  input  logic [7:0]         io_fromSplit_1_req_bits_vlmax,
  output logic               io_fromSplit_1_resp_valid,
  output logic [3:0]         io_fromSplit_1_resp_bits_mBIndex,
  input  logic               io_uopWriteback_0_ready,
  output logic               io_uopWriteback_0_valid,
  output logic               io_uopWriteback_0_bits_uop_exceptionVec_3,
  output logic               io_uopWriteback_0_bits_uop_exceptionVec_4,
  output logic               io_uopWriteback_0_bits_uop_exceptionVec_5,
  output logic               io_uopWriteback_0_bits_uop_exceptionVec_13,
  output logic               io_uopWriteback_0_bits_uop_exceptionVec_19,
  output logic               io_uopWriteback_0_bits_uop_exceptionVec_21,
  output logic [3:0]         io_uopWriteback_0_bits_uop_trigger,
  output logic [8:0]         io_uopWriteback_0_bits_uop_fuOpType,
  output logic               io_uopWriteback_0_bits_uop_vecWen,
  output logic               io_uopWriteback_0_bits_uop_v0Wen,
  output logic               io_uopWriteback_0_bits_uop_vlWen,
  output logic               io_uopWriteback_0_bits_uop_flushPipe,
  output logic               io_uopWriteback_0_bits_uop_vpu_vill,
  output logic               io_uopWriteback_0_bits_uop_vpu_vma,
  output logic               io_uopWriteback_0_bits_uop_vpu_vta,
  output logic [1:0]         io_uopWriteback_0_bits_uop_vpu_vsew,
  output logic [2:0]         io_uopWriteback_0_bits_uop_vpu_vlmul,
  output logic               io_uopWriteback_0_bits_uop_vpu_specVill,
  output logic               io_uopWriteback_0_bits_uop_vpu_specVma,
  output logic               io_uopWriteback_0_bits_uop_vpu_specVta,
  output logic [1:0]         io_uopWriteback_0_bits_uop_vpu_specVsew,
  output logic [2:0]         io_uopWriteback_0_bits_uop_vpu_specVlmul,
  output logic               io_uopWriteback_0_bits_uop_vpu_vm,
  output logic [7:0]         io_uopWriteback_0_bits_uop_vpu_vstart,
  output logic [2:0]         io_uopWriteback_0_bits_uop_vpu_frm,
  output logic               io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst,
  output logic               io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr,
  output logic               io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr,
  output logic               io_uopWriteback_0_bits_uop_vpu_fpu_isReduction,
  output logic               io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2,
  output logic               io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4,
  output logic               io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8,
  output logic [1:0]         io_uopWriteback_0_bits_uop_vpu_vxrm,
  output logic [6:0]         io_uopWriteback_0_bits_uop_vpu_vuopIdx,
  output logic               io_uopWriteback_0_bits_uop_vpu_lastUop,
  output logic [127:0]       io_uopWriteback_0_bits_uop_vpu_vmask,
  output logic [7:0]         io_uopWriteback_0_bits_uop_vpu_vl,
  output logic [2:0]         io_uopWriteback_0_bits_uop_vpu_nf,
  output logic [1:0]         io_uopWriteback_0_bits_uop_vpu_veew,
  output logic               io_uopWriteback_0_bits_uop_vpu_isReverse,
  output logic               io_uopWriteback_0_bits_uop_vpu_isExt,
  output logic               io_uopWriteback_0_bits_uop_vpu_isNarrow,
  output logic               io_uopWriteback_0_bits_uop_vpu_isDstMask,
  output logic               io_uopWriteback_0_bits_uop_vpu_isOpMask,
  output logic               io_uopWriteback_0_bits_uop_vpu_isMove,
  output logic               io_uopWriteback_0_bits_uop_vpu_isDependOldVd,
  output logic               io_uopWriteback_0_bits_uop_vpu_isWritePartVd,
  output logic               io_uopWriteback_0_bits_uop_vpu_isVleff,
  output logic [7:0]         io_uopWriteback_0_bits_uop_psrc_2,
  output logic [7:0]         io_uopWriteback_0_bits_uop_pdest,
  output logic               io_uopWriteback_0_bits_uop_robIdx_flag,
  output logic [7:0]         io_uopWriteback_0_bits_uop_robIdx_value,
  output logic               io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_renameTime,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_dispatchTime,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_enqRsTime,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_selectTime,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_issueTime,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_writebackTime,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime,
  output logic [55:0]        io_uopWriteback_0_bits_uop_debug_seqNum_seqNum,
  output logic [7:0]         io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx,
  output logic               io_uopWriteback_0_bits_uop_replayInst,
  output logic [127:0]       io_uopWriteback_0_bits_data,
  output logic [2:0]         io_uopWriteback_0_bits_vdIdx,
  output logic [2:0]         io_uopWriteback_0_bits_vdIdxInField,
  input  logic               io_uopWriteback_1_ready,
  output logic               io_uopWriteback_1_valid,
  output logic               io_uopWriteback_1_bits_uop_exceptionVec_3,
  output logic               io_uopWriteback_1_bits_uop_exceptionVec_4,
  output logic               io_uopWriteback_1_bits_uop_exceptionVec_5,
  output logic               io_uopWriteback_1_bits_uop_exceptionVec_13,
  output logic               io_uopWriteback_1_bits_uop_exceptionVec_19,
  output logic               io_uopWriteback_1_bits_uop_exceptionVec_21,
  output logic [3:0]         io_uopWriteback_1_bits_uop_trigger,
  output logic [8:0]         io_uopWriteback_1_bits_uop_fuOpType,
  output logic               io_uopWriteback_1_bits_uop_vecWen,
  output logic               io_uopWriteback_1_bits_uop_v0Wen,
  output logic               io_uopWriteback_1_bits_uop_vlWen,
  output logic               io_uopWriteback_1_bits_uop_flushPipe,
  output logic               io_uopWriteback_1_bits_uop_vpu_vill,
  output logic               io_uopWriteback_1_bits_uop_vpu_vma,
  output logic               io_uopWriteback_1_bits_uop_vpu_vta,
  output logic [1:0]         io_uopWriteback_1_bits_uop_vpu_vsew,
  output logic [2:0]         io_uopWriteback_1_bits_uop_vpu_vlmul,
  output logic               io_uopWriteback_1_bits_uop_vpu_specVill,
  output logic               io_uopWriteback_1_bits_uop_vpu_specVma,
  output logic               io_uopWriteback_1_bits_uop_vpu_specVta,
  output logic [1:0]         io_uopWriteback_1_bits_uop_vpu_specVsew,
  output logic [2:0]         io_uopWriteback_1_bits_uop_vpu_specVlmul,
  output logic               io_uopWriteback_1_bits_uop_vpu_vm,
  output logic [7:0]         io_uopWriteback_1_bits_uop_vpu_vstart,
  output logic [2:0]         io_uopWriteback_1_bits_uop_vpu_frm,
  output logic               io_uopWriteback_1_bits_uop_vpu_fpu_isFpToVecInst,
  output logic               io_uopWriteback_1_bits_uop_vpu_fpu_isFP32Instr,
  output logic               io_uopWriteback_1_bits_uop_vpu_fpu_isFP64Instr,
  output logic               io_uopWriteback_1_bits_uop_vpu_fpu_isReduction,
  output logic               io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_2,
  output logic               io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_4,
  output logic               io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_8,
  output logic [1:0]         io_uopWriteback_1_bits_uop_vpu_vxrm,
  output logic [6:0]         io_uopWriteback_1_bits_uop_vpu_vuopIdx,
  output logic               io_uopWriteback_1_bits_uop_vpu_lastUop,
  output logic [127:0]       io_uopWriteback_1_bits_uop_vpu_vmask,
  output logic [7:0]         io_uopWriteback_1_bits_uop_vpu_vl,
  output logic [2:0]         io_uopWriteback_1_bits_uop_vpu_nf,
  output logic [1:0]         io_uopWriteback_1_bits_uop_vpu_veew,
  output logic               io_uopWriteback_1_bits_uop_vpu_isReverse,
  output logic               io_uopWriteback_1_bits_uop_vpu_isExt,
  output logic               io_uopWriteback_1_bits_uop_vpu_isNarrow,
  output logic               io_uopWriteback_1_bits_uop_vpu_isDstMask,
  output logic               io_uopWriteback_1_bits_uop_vpu_isOpMask,
  output logic               io_uopWriteback_1_bits_uop_vpu_isMove,
  output logic               io_uopWriteback_1_bits_uop_vpu_isDependOldVd,
  output logic               io_uopWriteback_1_bits_uop_vpu_isWritePartVd,
  output logic               io_uopWriteback_1_bits_uop_vpu_isVleff,
  output logic [7:0]         io_uopWriteback_1_bits_uop_psrc_2,
  output logic [7:0]         io_uopWriteback_1_bits_uop_pdest,
  output logic               io_uopWriteback_1_bits_uop_robIdx_flag,
  output logic [7:0]         io_uopWriteback_1_bits_uop_robIdx_value,
  output logic               io_uopWriteback_1_bits_uop_debugInfo_eliminatedMove,
  output logic [63:0]        io_uopWriteback_1_bits_uop_debugInfo_renameTime,
  output logic [63:0]        io_uopWriteback_1_bits_uop_debugInfo_dispatchTime,
  output logic [63:0]        io_uopWriteback_1_bits_uop_debugInfo_enqRsTime,
  output logic [63:0]        io_uopWriteback_1_bits_uop_debugInfo_selectTime,
  output logic [63:0]        io_uopWriteback_1_bits_uop_debugInfo_issueTime,
  output logic [63:0]        io_uopWriteback_1_bits_uop_debugInfo_writebackTime,
  output logic [63:0]        io_uopWriteback_1_bits_uop_debugInfo_runahead_checkpoint_id,
  output logic [63:0]        io_uopWriteback_1_bits_uop_debugInfo_tlbFirstReqTime,
  output logic [63:0]        io_uopWriteback_1_bits_uop_debugInfo_tlbRespTime,
  output logic [55:0]        io_uopWriteback_1_bits_uop_debug_seqNum_seqNum,
  output logic [7:0]         io_uopWriteback_1_bits_uop_debug_seqNum_uopIdx,
  output logic               io_uopWriteback_1_bits_uop_replayInst,
  output logic [127:0]       io_uopWriteback_1_bits_data,
  output logic [2:0]         io_uopWriteback_1_bits_vdIdx,
  output logic [2:0]         io_uopWriteback_1_bits_vdIdxInField,
  output logic               io_toSplit_threshold,
  output logic               io_toLsq_0_valid,
  output logic               io_toLsq_0_bits_robidx_flag,
  output logic [7:0]         io_toLsq_0_bits_robidx_value,
  output logic [6:0]         io_toLsq_0_bits_uopidx,
  output logic [63:0]        io_toLsq_0_bits_vaddr,
  output logic               io_toLsq_0_bits_vaNeedExt,
  output logic [63:0]        io_toLsq_0_bits_gpaddr,
  output logic               io_toLsq_0_bits_isForVSnonLeafPTE,
  output logic               io_toLsq_0_bits_feedback_0,
  output logic               io_toLsq_0_bits_feedback_1,
  output logic [7:0]         io_toLsq_0_bits_vl,
  output logic               io_toLsq_0_bits_exceptionVec_3,
  output logic               io_toLsq_0_bits_exceptionVec_4,
  output logic               io_toLsq_0_bits_exceptionVec_5,
  output logic               io_toLsq_0_bits_exceptionVec_13,
  output logic               io_toLsq_0_bits_exceptionVec_19,
  output logic               io_toLsq_0_bits_exceptionVec_21,
  output logic               io_toLsq_1_valid,
  output logic               io_toLsq_1_bits_robidx_flag,
  output logic [7:0]         io_toLsq_1_bits_robidx_value,
  output logic [6:0]         io_toLsq_1_bits_uopidx,
  output logic [63:0]        io_toLsq_1_bits_vaddr,
  output logic               io_toLsq_1_bits_vaNeedExt,
  output logic [63:0]        io_toLsq_1_bits_gpaddr,
  output logic               io_toLsq_1_bits_isForVSnonLeafPTE,
  output logic               io_toLsq_1_bits_feedback_0,
  output logic               io_toLsq_1_bits_feedback_1,
  output logic [7:0]         io_toLsq_1_bits_vl,
  output logic               io_toLsq_1_bits_exceptionVec_3,
  output logic               io_toLsq_1_bits_exceptionVec_4,
  output logic               io_toLsq_1_bits_exceptionVec_5,
  output logic               io_toLsq_1_bits_exceptionVec_13,
  output logic               io_toLsq_1_bits_exceptionVec_19,
  output logic               io_toLsq_1_bits_exceptionVec_21,
  output logic               io_feedback_0_valid,
  output logic               io_feedback_0_bits_robIdx_flag,
  output logic [7:0]         io_feedback_0_bits_robIdx_value,
  output logic               io_feedback_0_bits_hit,
  output logic               io_feedback_0_bits_flushState,
  output logic [3:0]         io_feedback_0_bits_sourceType,
  output logic               io_feedback_0_bits_sqIdx_flag,
  output logic [5:0]         io_feedback_0_bits_sqIdx_value,
  output logic               io_feedback_0_bits_lqIdx_flag,
  output logic [6:0]         io_feedback_0_bits_lqIdx_value,
  output logic               io_feedback_0_bits_isVecPartReplay,
  output logic [15:0]        io_feedback_0_bits_vecReplayMask,
  output logic [3:0]         io_feedback_0_bits_vecReplayMbIdx,
  output logic               io_feedback_1_valid,
  output logic               io_feedback_1_bits_robIdx_flag,
  output logic [7:0]         io_feedback_1_bits_robIdx_value,
  output logic               io_feedback_1_bits_hit,
  output logic               io_feedback_1_bits_flushState,
  output logic [3:0]         io_feedback_1_bits_sourceType,
  output logic               io_feedback_1_bits_sqIdx_flag,
  output logic [5:0]         io_feedback_1_bits_sqIdx_value,
  output logic               io_feedback_1_bits_lqIdx_flag,
  output logic [6:0]         io_feedback_1_bits_lqIdx_value,
  output logic               io_feedback_1_bits_isVecPartReplay,
  output logic [15:0]        io_feedback_1_bits_vecReplayMask,
  output logic [3:0]         io_feedback_1_bits_vecReplayMbIdx
);

  mb_redirect_t        redirect;
  mb_enq_req_t         enq_req          [2];
  logic                enq_ready        [2];
  logic                enq_resp_valid   [2];
  logic [3:0]          enq_resp_mBIndex [2];
  mb_pipe_t            pipe             [3];
  logic                wb_ready         [2];
  mb_wb_t              wb               [2];
  logic                threshold;
  mb_lsq_t             lsq              [2];
  mb_fb_t              fb               [2];

  // 输入：先整体清零（端口被 firtool 删掉、上游恒送 0 的字段就停在 0），再逐个接端口
  always_comb begin
    redirect = '0;
    enq_req[0] = '0;
    enq_req[1] = '0;
    pipe[0] = '0;
    pipe[1] = '0;
    pipe[2] = '0;
    redirect.valid                                  = io_redirect_valid;
    redirect.robIdx_flag                            = io_redirect_bits_robIdx_flag;
    redirect.robIdx_value                           = io_redirect_bits_robIdx_value;
    redirect.level                                  = io_redirect_bits_level;
    pipe[0].valid                                   = io_fromPipeline_0_valid;
    pipe[0].mBIndex                                 = io_fromPipeline_0_bits_mBIndex;
    pipe[0].trigger                                 = io_fromPipeline_0_bits_trigger;
    pipe[0].exceptionVec[3]                         = io_fromPipeline_0_bits_exceptionVec_3;
    pipe[0].exceptionVec[4]                         = io_fromPipeline_0_bits_exceptionVec_4;
    pipe[0].exceptionVec[5]                         = io_fromPipeline_0_bits_exceptionVec_5;
    pipe[0].exceptionVec[13]                        = io_fromPipeline_0_bits_exceptionVec_13;
    pipe[0].exceptionVec[19]                        = io_fromPipeline_0_bits_exceptionVec_19;
    pipe[0].exceptionVec[21]                        = io_fromPipeline_0_bits_exceptionVec_21;
    pipe[0].hasException                            = io_fromPipeline_0_bits_hasException;
    pipe[0].vaddr                                   = io_fromPipeline_0_bits_vaddr;
    pipe[0].vaNeedExt                               = io_fromPipeline_0_bits_vaNeedExt;
    pipe[0].gpaddr                                  = io_fromPipeline_0_bits_gpaddr;
    pipe[0].isForVSnonLeafPTE                       = io_fromPipeline_0_bits_isForVSnonLeafPTE;
    pipe[0].vstart                                  = io_fromPipeline_0_bits_vstart;
    pipe[0].vecTriggerMask                          = io_fromPipeline_0_bits_vecTriggerMask;
    pipe[0].elemIdx                                 = io_fromPipeline_0_bits_elemIdx;
    pipe[0].mask                                    = io_fromPipeline_0_bits_mask;
    pipe[0].alignedType                             = io_fromPipeline_0_bits_alignedType;
    pipe[0].reg_offset                              = io_fromPipeline_0_bits_reg_offset;
    pipe[0].elemIdxInsideVd                         = io_fromPipeline_0_bits_elemIdxInsideVd;
    pipe[0].vecdata                                 = io_fromPipeline_0_bits_vecdata;
    pipe[1].valid                                   = io_fromPipeline_1_valid;
    pipe[1].mBIndex                                 = io_fromPipeline_1_bits_mBIndex;
    pipe[1].trigger                                 = io_fromPipeline_1_bits_trigger;
    pipe[1].exceptionVec[3]                         = io_fromPipeline_1_bits_exceptionVec_3;
    pipe[1].exceptionVec[4]                         = io_fromPipeline_1_bits_exceptionVec_4;
    pipe[1].exceptionVec[5]                         = io_fromPipeline_1_bits_exceptionVec_5;
    pipe[1].exceptionVec[13]                        = io_fromPipeline_1_bits_exceptionVec_13;
    pipe[1].exceptionVec[19]                        = io_fromPipeline_1_bits_exceptionVec_19;
    pipe[1].exceptionVec[21]                        = io_fromPipeline_1_bits_exceptionVec_21;
    pipe[1].hasException                            = io_fromPipeline_1_bits_hasException;
    pipe[1].vaddr                                   = io_fromPipeline_1_bits_vaddr;
    pipe[1].vaNeedExt                               = io_fromPipeline_1_bits_vaNeedExt;
    pipe[1].gpaddr                                  = io_fromPipeline_1_bits_gpaddr;
    pipe[1].isForVSnonLeafPTE                       = io_fromPipeline_1_bits_isForVSnonLeafPTE;
    pipe[1].vstart                                  = io_fromPipeline_1_bits_vstart;
    pipe[1].vecTriggerMask                          = io_fromPipeline_1_bits_vecTriggerMask;
    pipe[1].elemIdx                                 = io_fromPipeline_1_bits_elemIdx;
    pipe[1].mask                                    = io_fromPipeline_1_bits_mask;
    pipe[1].alignedType                             = io_fromPipeline_1_bits_alignedType;
    pipe[1].reg_offset                              = io_fromPipeline_1_bits_reg_offset;
    pipe[1].elemIdxInsideVd                         = io_fromPipeline_1_bits_elemIdxInsideVd;
    pipe[1].vecdata                                 = io_fromPipeline_1_bits_vecdata;
    pipe[2].valid                                   = io_fromPipeline_2_valid;
    pipe[2].mBIndex                                 = io_fromPipeline_2_bits_mBIndex;
    pipe[2].trigger                                 = io_fromPipeline_2_bits_trigger;
    pipe[2].exceptionVec[3]                         = io_fromPipeline_2_bits_exceptionVec_3;
    pipe[2].exceptionVec[4]                         = io_fromPipeline_2_bits_exceptionVec_4;
    pipe[2].exceptionVec[5]                         = io_fromPipeline_2_bits_exceptionVec_5;
    pipe[2].exceptionVec[13]                        = io_fromPipeline_2_bits_exceptionVec_13;
    pipe[2].exceptionVec[19]                        = io_fromPipeline_2_bits_exceptionVec_19;
    pipe[2].exceptionVec[21]                        = io_fromPipeline_2_bits_exceptionVec_21;
    pipe[2].hasException                            = io_fromPipeline_2_bits_hasException;
    pipe[2].vaddr                                   = io_fromPipeline_2_bits_vaddr;
    pipe[2].vaNeedExt                               = io_fromPipeline_2_bits_vaNeedExt;
    pipe[2].gpaddr                                  = io_fromPipeline_2_bits_gpaddr;
    pipe[2].isForVSnonLeafPTE                       = io_fromPipeline_2_bits_isForVSnonLeafPTE;
    pipe[2].vstart                                  = io_fromPipeline_2_bits_vstart;
    pipe[2].vecTriggerMask                          = io_fromPipeline_2_bits_vecTriggerMask;
    pipe[2].elemIdx                                 = io_fromPipeline_2_bits_elemIdx;
    pipe[2].mask                                    = io_fromPipeline_2_bits_mask;
    pipe[2].alignedType                             = io_fromPipeline_2_bits_alignedType;
    pipe[2].reg_offset                              = io_fromPipeline_2_bits_reg_offset;
    pipe[2].elemIdxInsideVd                         = io_fromPipeline_2_bits_elemIdxInsideVd;
    pipe[2].vecdata                                 = io_fromPipeline_2_bits_vecdata;
    enq_req[0].valid                                = io_fromSplit_0_req_valid;
    enq_req[0].mask                                 = io_fromSplit_0_req_bits_mask;
    enq_req[0].vaddr                                = io_fromSplit_0_req_bits_vaddr;
    enq_req[0].flowNum                              = io_fromSplit_0_req_bits_flowNum;
    enq_req[0].uop.fuOpType                         = io_fromSplit_0_req_bits_uop_fuOpType;
    enq_req[0].uop.vecWen                           = io_fromSplit_0_req_bits_uop_vecWen;
    enq_req[0].uop.v0Wen                            = io_fromSplit_0_req_bits_uop_v0Wen;
    enq_req[0].uop.vlWen                            = io_fromSplit_0_req_bits_uop_vlWen;
    enq_req[0].uop.vpu_vill                         = io_fromSplit_0_req_bits_uop_vpu_vill;
    enq_req[0].uop.vpu_vma                          = io_fromSplit_0_req_bits_uop_vpu_vma;
    enq_req[0].uop.vpu_vta                          = io_fromSplit_0_req_bits_uop_vpu_vta;
    enq_req[0].uop.vpu_vsew                         = io_fromSplit_0_req_bits_uop_vpu_vsew;
    enq_req[0].uop.vpu_vlmul                        = io_fromSplit_0_req_bits_uop_vpu_vlmul;
    enq_req[0].uop.vpu_specVill                     = io_fromSplit_0_req_bits_uop_vpu_specVill;
    enq_req[0].uop.vpu_specVma                      = io_fromSplit_0_req_bits_uop_vpu_specVma;
    enq_req[0].uop.vpu_specVta                      = io_fromSplit_0_req_bits_uop_vpu_specVta;
    enq_req[0].uop.vpu_specVsew                     = io_fromSplit_0_req_bits_uop_vpu_specVsew;
    enq_req[0].uop.vpu_specVlmul                    = io_fromSplit_0_req_bits_uop_vpu_specVlmul;
    enq_req[0].uop.vpu_vm                           = io_fromSplit_0_req_bits_uop_vpu_vm;
    enq_req[0].uop.vpu_frm                          = io_fromSplit_0_req_bits_uop_vpu_frm;
    enq_req[0].uop.vpu_fpu_isFpToVecInst            = io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst;
    enq_req[0].uop.vpu_fpu_isFP32Instr              = io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr;
    enq_req[0].uop.vpu_fpu_isFP64Instr              = io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr;
    enq_req[0].uop.vpu_fpu_isReduction              = io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction;
    enq_req[0].uop.vpu_fpu_isFoldTo1_2              = io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2;
    enq_req[0].uop.vpu_fpu_isFoldTo1_4              = io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4;
    enq_req[0].uop.vpu_fpu_isFoldTo1_8              = io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8;
    enq_req[0].uop.vpu_vxrm                         = io_fromSplit_0_req_bits_uop_vpu_vxrm;
    enq_req[0].uop.vpu_vuopIdx                      = io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
    enq_req[0].uop.vpu_lastUop                      = io_fromSplit_0_req_bits_uop_vpu_lastUop;
    enq_req[0].uop.vpu_vl                           = io_fromSplit_0_req_bits_uop_vpu_vl;
    enq_req[0].uop.vpu_nf                           = io_fromSplit_0_req_bits_uop_vpu_nf;
    enq_req[0].uop.vpu_veew                         = io_fromSplit_0_req_bits_uop_vpu_veew;
    enq_req[0].uop.vpu_isReverse                    = io_fromSplit_0_req_bits_uop_vpu_isReverse;
    enq_req[0].uop.vpu_isExt                        = io_fromSplit_0_req_bits_uop_vpu_isExt;
    enq_req[0].uop.vpu_isNarrow                     = io_fromSplit_0_req_bits_uop_vpu_isNarrow;
    enq_req[0].uop.vpu_isDstMask                    = io_fromSplit_0_req_bits_uop_vpu_isDstMask;
    enq_req[0].uop.vpu_isOpMask                     = io_fromSplit_0_req_bits_uop_vpu_isOpMask;
    enq_req[0].uop.vpu_isMove                       = io_fromSplit_0_req_bits_uop_vpu_isMove;
    enq_req[0].uop.vpu_isDependOldVd                = io_fromSplit_0_req_bits_uop_vpu_isDependOldVd;
    enq_req[0].uop.vpu_isWritePartVd                = io_fromSplit_0_req_bits_uop_vpu_isWritePartVd;
    enq_req[0].uop.vpu_isVleff                      = io_fromSplit_0_req_bits_uop_vpu_isVleff;
    enq_req[0].uop.uopIdx                           = io_fromSplit_0_req_bits_uop_uopIdx;
    enq_req[0].uop.pdest                            = io_fromSplit_0_req_bits_uop_pdest;
    enq_req[0].uop.robIdx_flag                      = io_fromSplit_0_req_bits_uop_robIdx_flag;
    enq_req[0].uop.robIdx_value                     = io_fromSplit_0_req_bits_uop_robIdx_value;
    enq_req[0].uop.debugInfo_eliminatedMove         = io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove;
    enq_req[0].uop.debugInfo_renameTime             = io_fromSplit_0_req_bits_uop_debugInfo_renameTime;
    enq_req[0].uop.debugInfo_dispatchTime           = io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime;
    enq_req[0].uop.debugInfo_enqRsTime              = io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
    enq_req[0].uop.debugInfo_selectTime             = io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
    enq_req[0].uop.debugInfo_issueTime              = io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
    enq_req[0].uop.debugInfo_writebackTime          = io_fromSplit_0_req_bits_uop_debugInfo_writebackTime;
    enq_req[0].uop.debugInfo_runahead_checkpoint_id = io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id;
    enq_req[0].uop.debugInfo_tlbFirstReqTime        = io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime;
    enq_req[0].uop.debugInfo_tlbRespTime            = io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime;
    enq_req[0].uop.debug_seqNum_seqNum              = io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum;
    enq_req[0].uop.debug_seqNum_uopIdx              = io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx;
    enq_req[0].uop.lqIdx_flag                       = io_fromSplit_0_req_bits_uop_lqIdx_flag;
    enq_req[0].uop.lqIdx_value                      = io_fromSplit_0_req_bits_uop_lqIdx_value;
    enq_req[0].uop.sqIdx_flag                       = io_fromSplit_0_req_bits_uop_sqIdx_flag;
    enq_req[0].uop.sqIdx_value                      = io_fromSplit_0_req_bits_uop_sqIdx_value;
    enq_req[0].data                                 = io_fromSplit_0_req_bits_data;
    enq_req[0].vdIdx                                = io_fromSplit_0_req_bits_vdIdx;
    enq_req[0].fof                                  = io_fromSplit_0_req_bits_fof;
    enq_req[0].vlmax                                = io_fromSplit_0_req_bits_vlmax;
    enq_req[1].valid                                = io_fromSplit_1_req_valid;
    enq_req[1].mask                                 = io_fromSplit_1_req_bits_mask;
    enq_req[1].vaddr                                = io_fromSplit_1_req_bits_vaddr;
    enq_req[1].flowNum                              = io_fromSplit_1_req_bits_flowNum;
    enq_req[1].uop.fuOpType                         = io_fromSplit_1_req_bits_uop_fuOpType;
    enq_req[1].uop.vecWen                           = io_fromSplit_1_req_bits_uop_vecWen;
    enq_req[1].uop.v0Wen                            = io_fromSplit_1_req_bits_uop_v0Wen;
    enq_req[1].uop.vlWen                            = io_fromSplit_1_req_bits_uop_vlWen;
    enq_req[1].uop.vpu_vill                         = io_fromSplit_1_req_bits_uop_vpu_vill;
    enq_req[1].uop.vpu_vma                          = io_fromSplit_1_req_bits_uop_vpu_vma;
    enq_req[1].uop.vpu_vta                          = io_fromSplit_1_req_bits_uop_vpu_vta;
    enq_req[1].uop.vpu_vsew                         = io_fromSplit_1_req_bits_uop_vpu_vsew;
    enq_req[1].uop.vpu_vlmul                        = io_fromSplit_1_req_bits_uop_vpu_vlmul;
    enq_req[1].uop.vpu_specVill                     = io_fromSplit_1_req_bits_uop_vpu_specVill;
    enq_req[1].uop.vpu_specVma                      = io_fromSplit_1_req_bits_uop_vpu_specVma;
    enq_req[1].uop.vpu_specVta                      = io_fromSplit_1_req_bits_uop_vpu_specVta;
    enq_req[1].uop.vpu_specVsew                     = io_fromSplit_1_req_bits_uop_vpu_specVsew;
    enq_req[1].uop.vpu_specVlmul                    = io_fromSplit_1_req_bits_uop_vpu_specVlmul;
    enq_req[1].uop.vpu_vm                           = io_fromSplit_1_req_bits_uop_vpu_vm;
    enq_req[1].uop.vpu_frm                          = io_fromSplit_1_req_bits_uop_vpu_frm;
    enq_req[1].uop.vpu_fpu_isFpToVecInst            = io_fromSplit_1_req_bits_uop_vpu_fpu_isFpToVecInst;
    enq_req[1].uop.vpu_fpu_isFP32Instr              = io_fromSplit_1_req_bits_uop_vpu_fpu_isFP32Instr;
    enq_req[1].uop.vpu_fpu_isFP64Instr              = io_fromSplit_1_req_bits_uop_vpu_fpu_isFP64Instr;
    enq_req[1].uop.vpu_fpu_isReduction              = io_fromSplit_1_req_bits_uop_vpu_fpu_isReduction;
    enq_req[1].uop.vpu_fpu_isFoldTo1_2              = io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_2;
    enq_req[1].uop.vpu_fpu_isFoldTo1_4              = io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_4;
    enq_req[1].uop.vpu_fpu_isFoldTo1_8              = io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_8;
    enq_req[1].uop.vpu_vxrm                         = io_fromSplit_1_req_bits_uop_vpu_vxrm;
    enq_req[1].uop.vpu_vuopIdx                      = io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
    enq_req[1].uop.vpu_lastUop                      = io_fromSplit_1_req_bits_uop_vpu_lastUop;
    enq_req[1].uop.vpu_vl                           = io_fromSplit_1_req_bits_uop_vpu_vl;
    enq_req[1].uop.vpu_nf                           = io_fromSplit_1_req_bits_uop_vpu_nf;
    enq_req[1].uop.vpu_veew                         = io_fromSplit_1_req_bits_uop_vpu_veew;
    enq_req[1].uop.vpu_isReverse                    = io_fromSplit_1_req_bits_uop_vpu_isReverse;
    enq_req[1].uop.vpu_isExt                        = io_fromSplit_1_req_bits_uop_vpu_isExt;
    enq_req[1].uop.vpu_isNarrow                     = io_fromSplit_1_req_bits_uop_vpu_isNarrow;
    enq_req[1].uop.vpu_isDstMask                    = io_fromSplit_1_req_bits_uop_vpu_isDstMask;
    enq_req[1].uop.vpu_isOpMask                     = io_fromSplit_1_req_bits_uop_vpu_isOpMask;
    enq_req[1].uop.vpu_isMove                       = io_fromSplit_1_req_bits_uop_vpu_isMove;
    enq_req[1].uop.vpu_isDependOldVd                = io_fromSplit_1_req_bits_uop_vpu_isDependOldVd;
    enq_req[1].uop.vpu_isWritePartVd                = io_fromSplit_1_req_bits_uop_vpu_isWritePartVd;
    enq_req[1].uop.vpu_isVleff                      = io_fromSplit_1_req_bits_uop_vpu_isVleff;
    enq_req[1].uop.uopIdx                           = io_fromSplit_1_req_bits_uop_uopIdx;
    enq_req[1].uop.pdest                            = io_fromSplit_1_req_bits_uop_pdest;
    enq_req[1].uop.robIdx_flag                      = io_fromSplit_1_req_bits_uop_robIdx_flag;
    enq_req[1].uop.robIdx_value                     = io_fromSplit_1_req_bits_uop_robIdx_value;
    enq_req[1].uop.debugInfo_eliminatedMove         = io_fromSplit_1_req_bits_uop_debugInfo_eliminatedMove;
    enq_req[1].uop.debugInfo_renameTime             = io_fromSplit_1_req_bits_uop_debugInfo_renameTime;
    enq_req[1].uop.debugInfo_dispatchTime           = io_fromSplit_1_req_bits_uop_debugInfo_dispatchTime;
    enq_req[1].uop.debugInfo_enqRsTime              = io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
    enq_req[1].uop.debugInfo_selectTime             = io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
    enq_req[1].uop.debugInfo_issueTime              = io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
    enq_req[1].uop.debugInfo_writebackTime          = io_fromSplit_1_req_bits_uop_debugInfo_writebackTime;
    enq_req[1].uop.debugInfo_runahead_checkpoint_id = io_fromSplit_1_req_bits_uop_debugInfo_runahead_checkpoint_id;
    enq_req[1].uop.debugInfo_tlbFirstReqTime        = io_fromSplit_1_req_bits_uop_debugInfo_tlbFirstReqTime;
    enq_req[1].uop.debugInfo_tlbRespTime            = io_fromSplit_1_req_bits_uop_debugInfo_tlbRespTime;
    enq_req[1].uop.debug_seqNum_seqNum              = io_fromSplit_1_req_bits_uop_debug_seqNum_seqNum;
    enq_req[1].uop.debug_seqNum_uopIdx              = io_fromSplit_1_req_bits_uop_debug_seqNum_uopIdx;
    enq_req[1].uop.lqIdx_flag                       = io_fromSplit_1_req_bits_uop_lqIdx_flag;
    enq_req[1].uop.lqIdx_value                      = io_fromSplit_1_req_bits_uop_lqIdx_value;
    enq_req[1].uop.sqIdx_flag                       = io_fromSplit_1_req_bits_uop_sqIdx_flag;
    enq_req[1].uop.sqIdx_value                      = io_fromSplit_1_req_bits_uop_sqIdx_value;
    enq_req[1].data                                 = io_fromSplit_1_req_bits_data;
    enq_req[1].vdIdx                                = io_fromSplit_1_req_bits_vdIdx;
    enq_req[1].fof                                  = io_fromSplit_1_req_bits_fof;
    enq_req[1].vlmax                                = io_fromSplit_1_req_bits_vlmax;
    wb_ready[0]                                     = io_uopWriteback_0_ready;
    wb_ready[1]                                     = io_uopWriteback_1_ready;
    pipe[0].hit = 1'b1;  // 无端口：上游恒送 1'b1
    pipe[1].hit = 1'b1;  // 无端口：上游恒送 1'b1
    pipe[2].hit = 1'b1;  // 无端口：上游恒送 1'b1
    pipe[0].sourceType = 3'h0;  // 无端口：上游恒送 3'h0
    pipe[1].sourceType = 3'h0;  // 无端口：上游恒送 3'h0
    pipe[2].sourceType = 3'h0;  // 无端口：上游恒送 3'h0
    pipe[0].flushState = 1'b0;  // 无端口：上游恒送 1'b0
    pipe[1].flushState = 1'b0;  // 无端口：上游恒送 1'b0
    pipe[2].flushState = 1'b0;  // 无端口：上游恒送 1'b0
  end

  xs_VMergeBuffer_core #(
    .IS_VSTORE (1'b0),
    .ENQ_W     (2),
    .PIPE_W    (3),
    .DEQ_W     (2),
    .THRESHOLD (6),
    .EXC_SEL   (VLDU_EXC_SEL)
  ) u_core (
    .clock                     (clock),
    .reset                     (reset),
    .io_redirect               (redirect),
    .io_fromSplit_req          (enq_req),
    .io_fromSplit_req_ready    (enq_ready),
    .io_fromSplit_resp_valid   (enq_resp_valid),
    .io_fromSplit_resp_mBIndex (enq_resp_mBIndex),
    .io_fromPipeline           (pipe),
    .io_uopWriteback_ready     (wb_ready),
    .io_uopWriteback           (wb),
    .io_toSplit_threshold      (threshold),
    .io_toLsq                  (lsq),
    .io_feedback               (fb)
  );

  // 输出
  assign io_fromSplit_0_req_ready                                    = enq_ready[0];
  assign io_fromSplit_0_resp_valid                                   = enq_resp_valid[0];
  assign io_fromSplit_0_resp_bits_mBIndex                            = enq_resp_mBIndex[0];
  assign io_fromSplit_1_req_ready                                    = enq_ready[1];
  assign io_fromSplit_1_resp_valid                                   = enq_resp_valid[1];
  assign io_fromSplit_1_resp_bits_mBIndex                            = enq_resp_mBIndex[1];
  assign io_uopWriteback_0_valid                                     = wb[0].valid;
  assign io_uopWriteback_0_bits_uop_exceptionVec_3                   = wb[0].uop.exceptionVec[3];
  assign io_uopWriteback_0_bits_uop_exceptionVec_4                   = wb[0].uop.exceptionVec[4];
  assign io_uopWriteback_0_bits_uop_exceptionVec_5                   = wb[0].uop.exceptionVec[5];
  assign io_uopWriteback_0_bits_uop_exceptionVec_13                  = wb[0].uop.exceptionVec[13];
  assign io_uopWriteback_0_bits_uop_exceptionVec_19                  = wb[0].uop.exceptionVec[19];
  assign io_uopWriteback_0_bits_uop_exceptionVec_21                  = wb[0].uop.exceptionVec[21];
  assign io_uopWriteback_0_bits_uop_trigger                          = wb[0].uop.trigger;
  assign io_uopWriteback_0_bits_uop_fuOpType                         = wb[0].uop.fuOpType;
  assign io_uopWriteback_0_bits_uop_vecWen                           = wb[0].uop.vecWen;
  assign io_uopWriteback_0_bits_uop_v0Wen                            = wb[0].uop.v0Wen;
  assign io_uopWriteback_0_bits_uop_vlWen                            = wb[0].uop.vlWen;
  assign io_uopWriteback_0_bits_uop_flushPipe                        = wb[0].uop.flushPipe;
  assign io_uopWriteback_0_bits_uop_vpu_vill                         = wb[0].uop.vpu_vill;
  assign io_uopWriteback_0_bits_uop_vpu_vma                          = wb[0].uop.vpu_vma;
  assign io_uopWriteback_0_bits_uop_vpu_vta                          = wb[0].uop.vpu_vta;
  assign io_uopWriteback_0_bits_uop_vpu_vsew                         = wb[0].uop.vpu_vsew;
  assign io_uopWriteback_0_bits_uop_vpu_vlmul                        = wb[0].uop.vpu_vlmul;
  assign io_uopWriteback_0_bits_uop_vpu_specVill                     = wb[0].uop.vpu_specVill;
  assign io_uopWriteback_0_bits_uop_vpu_specVma                      = wb[0].uop.vpu_specVma;
  assign io_uopWriteback_0_bits_uop_vpu_specVta                      = wb[0].uop.vpu_specVta;
  assign io_uopWriteback_0_bits_uop_vpu_specVsew                     = wb[0].uop.vpu_specVsew;
  assign io_uopWriteback_0_bits_uop_vpu_specVlmul                    = wb[0].uop.vpu_specVlmul;
  assign io_uopWriteback_0_bits_uop_vpu_vm                           = wb[0].uop.vpu_vm;
  assign io_uopWriteback_0_bits_uop_vpu_vstart                       = wb[0].uop.vpu_vstart;
  assign io_uopWriteback_0_bits_uop_vpu_frm                          = wb[0].uop.vpu_frm;
  assign io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst            = wb[0].uop.vpu_fpu_isFpToVecInst;
  assign io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr              = wb[0].uop.vpu_fpu_isFP32Instr;
  assign io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr              = wb[0].uop.vpu_fpu_isFP64Instr;
  assign io_uopWriteback_0_bits_uop_vpu_fpu_isReduction              = wb[0].uop.vpu_fpu_isReduction;
  assign io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2              = wb[0].uop.vpu_fpu_isFoldTo1_2;
  assign io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4              = wb[0].uop.vpu_fpu_isFoldTo1_4;
  assign io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8              = wb[0].uop.vpu_fpu_isFoldTo1_8;
  assign io_uopWriteback_0_bits_uop_vpu_vxrm                         = wb[0].uop.vpu_vxrm;
  assign io_uopWriteback_0_bits_uop_vpu_vuopIdx                      = wb[0].uop.vpu_vuopIdx;
  assign io_uopWriteback_0_bits_uop_vpu_lastUop                      = wb[0].uop.vpu_lastUop;
  assign io_uopWriteback_0_bits_uop_vpu_vmask                        = wb[0].uop.vpu_vmask;
  assign io_uopWriteback_0_bits_uop_vpu_vl                           = wb[0].uop.vpu_vl;
  assign io_uopWriteback_0_bits_uop_vpu_nf                           = wb[0].uop.vpu_nf;
  assign io_uopWriteback_0_bits_uop_vpu_veew                         = wb[0].uop.vpu_veew;
  assign io_uopWriteback_0_bits_uop_vpu_isReverse                    = wb[0].uop.vpu_isReverse;
  assign io_uopWriteback_0_bits_uop_vpu_isExt                        = wb[0].uop.vpu_isExt;
  assign io_uopWriteback_0_bits_uop_vpu_isNarrow                     = wb[0].uop.vpu_isNarrow;
  assign io_uopWriteback_0_bits_uop_vpu_isDstMask                    = wb[0].uop.vpu_isDstMask;
  assign io_uopWriteback_0_bits_uop_vpu_isOpMask                     = wb[0].uop.vpu_isOpMask;
  assign io_uopWriteback_0_bits_uop_vpu_isMove                       = wb[0].uop.vpu_isMove;
  assign io_uopWriteback_0_bits_uop_vpu_isDependOldVd                = wb[0].uop.vpu_isDependOldVd;
  assign io_uopWriteback_0_bits_uop_vpu_isWritePartVd                = wb[0].uop.vpu_isWritePartVd;
  assign io_uopWriteback_0_bits_uop_vpu_isVleff                      = wb[0].uop.vpu_isVleff;
  assign io_uopWriteback_0_bits_uop_psrc_2                           = wb[0].uop.psrc_2;
  assign io_uopWriteback_0_bits_uop_pdest                            = wb[0].uop.pdest;
  assign io_uopWriteback_0_bits_uop_robIdx_flag                      = wb[0].uop.robIdx_flag;
  assign io_uopWriteback_0_bits_uop_robIdx_value                     = wb[0].uop.robIdx_value;
  assign io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove         = wb[0].uop.debugInfo_eliminatedMove;
  assign io_uopWriteback_0_bits_uop_debugInfo_renameTime             = wb[0].uop.debugInfo_renameTime;
  assign io_uopWriteback_0_bits_uop_debugInfo_dispatchTime           = wb[0].uop.debugInfo_dispatchTime;
  assign io_uopWriteback_0_bits_uop_debugInfo_enqRsTime              = wb[0].uop.debugInfo_enqRsTime;
  assign io_uopWriteback_0_bits_uop_debugInfo_selectTime             = wb[0].uop.debugInfo_selectTime;
  assign io_uopWriteback_0_bits_uop_debugInfo_issueTime              = wb[0].uop.debugInfo_issueTime;
  assign io_uopWriteback_0_bits_uop_debugInfo_writebackTime          = wb[0].uop.debugInfo_writebackTime;
  assign io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id = wb[0].uop.debugInfo_runahead_checkpoint_id;
  assign io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime        = wb[0].uop.debugInfo_tlbFirstReqTime;
  assign io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime            = wb[0].uop.debugInfo_tlbRespTime;
  assign io_uopWriteback_0_bits_uop_debug_seqNum_seqNum              = wb[0].uop.debug_seqNum_seqNum;
  assign io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx              = wb[0].uop.debug_seqNum_uopIdx;
  assign io_uopWriteback_0_bits_uop_replayInst                       = wb[0].uop.replayInst;
  assign io_uopWriteback_0_bits_data                                 = wb[0].data;
  assign io_uopWriteback_0_bits_vdIdx                                = wb[0].vdIdx;
  assign io_uopWriteback_0_bits_vdIdxInField                         = wb[0].vdIdxInField;
  assign io_uopWriteback_1_valid                                     = wb[1].valid;
  assign io_uopWriteback_1_bits_uop_exceptionVec_3                   = wb[1].uop.exceptionVec[3];
  assign io_uopWriteback_1_bits_uop_exceptionVec_4                   = wb[1].uop.exceptionVec[4];
  assign io_uopWriteback_1_bits_uop_exceptionVec_5                   = wb[1].uop.exceptionVec[5];
  assign io_uopWriteback_1_bits_uop_exceptionVec_13                  = wb[1].uop.exceptionVec[13];
  assign io_uopWriteback_1_bits_uop_exceptionVec_19                  = wb[1].uop.exceptionVec[19];
  assign io_uopWriteback_1_bits_uop_exceptionVec_21                  = wb[1].uop.exceptionVec[21];
  assign io_uopWriteback_1_bits_uop_trigger                          = wb[1].uop.trigger;
  assign io_uopWriteback_1_bits_uop_fuOpType                         = wb[1].uop.fuOpType;
  assign io_uopWriteback_1_bits_uop_vecWen                           = wb[1].uop.vecWen;
  assign io_uopWriteback_1_bits_uop_v0Wen                            = wb[1].uop.v0Wen;
  assign io_uopWriteback_1_bits_uop_vlWen                            = wb[1].uop.vlWen;
  assign io_uopWriteback_1_bits_uop_flushPipe                        = wb[1].uop.flushPipe;
  assign io_uopWriteback_1_bits_uop_vpu_vill                         = wb[1].uop.vpu_vill;
  assign io_uopWriteback_1_bits_uop_vpu_vma                          = wb[1].uop.vpu_vma;
  assign io_uopWriteback_1_bits_uop_vpu_vta                          = wb[1].uop.vpu_vta;
  assign io_uopWriteback_1_bits_uop_vpu_vsew                         = wb[1].uop.vpu_vsew;
  assign io_uopWriteback_1_bits_uop_vpu_vlmul                        = wb[1].uop.vpu_vlmul;
  assign io_uopWriteback_1_bits_uop_vpu_specVill                     = wb[1].uop.vpu_specVill;
  assign io_uopWriteback_1_bits_uop_vpu_specVma                      = wb[1].uop.vpu_specVma;
  assign io_uopWriteback_1_bits_uop_vpu_specVta                      = wb[1].uop.vpu_specVta;
  assign io_uopWriteback_1_bits_uop_vpu_specVsew                     = wb[1].uop.vpu_specVsew;
  assign io_uopWriteback_1_bits_uop_vpu_specVlmul                    = wb[1].uop.vpu_specVlmul;
  assign io_uopWriteback_1_bits_uop_vpu_vm                           = wb[1].uop.vpu_vm;
  assign io_uopWriteback_1_bits_uop_vpu_vstart                       = wb[1].uop.vpu_vstart;
  assign io_uopWriteback_1_bits_uop_vpu_frm                          = wb[1].uop.vpu_frm;
  assign io_uopWriteback_1_bits_uop_vpu_fpu_isFpToVecInst            = wb[1].uop.vpu_fpu_isFpToVecInst;
  assign io_uopWriteback_1_bits_uop_vpu_fpu_isFP32Instr              = wb[1].uop.vpu_fpu_isFP32Instr;
  assign io_uopWriteback_1_bits_uop_vpu_fpu_isFP64Instr              = wb[1].uop.vpu_fpu_isFP64Instr;
  assign io_uopWriteback_1_bits_uop_vpu_fpu_isReduction              = wb[1].uop.vpu_fpu_isReduction;
  assign io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_2              = wb[1].uop.vpu_fpu_isFoldTo1_2;
  assign io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_4              = wb[1].uop.vpu_fpu_isFoldTo1_4;
  assign io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_8              = wb[1].uop.vpu_fpu_isFoldTo1_8;
  assign io_uopWriteback_1_bits_uop_vpu_vxrm                         = wb[1].uop.vpu_vxrm;
  assign io_uopWriteback_1_bits_uop_vpu_vuopIdx                      = wb[1].uop.vpu_vuopIdx;
  assign io_uopWriteback_1_bits_uop_vpu_lastUop                      = wb[1].uop.vpu_lastUop;
  assign io_uopWriteback_1_bits_uop_vpu_vmask                        = wb[1].uop.vpu_vmask;
  assign io_uopWriteback_1_bits_uop_vpu_vl                           = wb[1].uop.vpu_vl;
  assign io_uopWriteback_1_bits_uop_vpu_nf                           = wb[1].uop.vpu_nf;
  assign io_uopWriteback_1_bits_uop_vpu_veew                         = wb[1].uop.vpu_veew;
  assign io_uopWriteback_1_bits_uop_vpu_isReverse                    = wb[1].uop.vpu_isReverse;
  assign io_uopWriteback_1_bits_uop_vpu_isExt                        = wb[1].uop.vpu_isExt;
  assign io_uopWriteback_1_bits_uop_vpu_isNarrow                     = wb[1].uop.vpu_isNarrow;
  assign io_uopWriteback_1_bits_uop_vpu_isDstMask                    = wb[1].uop.vpu_isDstMask;
  assign io_uopWriteback_1_bits_uop_vpu_isOpMask                     = wb[1].uop.vpu_isOpMask;
  assign io_uopWriteback_1_bits_uop_vpu_isMove                       = wb[1].uop.vpu_isMove;
  assign io_uopWriteback_1_bits_uop_vpu_isDependOldVd                = wb[1].uop.vpu_isDependOldVd;
  assign io_uopWriteback_1_bits_uop_vpu_isWritePartVd                = wb[1].uop.vpu_isWritePartVd;
  assign io_uopWriteback_1_bits_uop_vpu_isVleff                      = wb[1].uop.vpu_isVleff;
  assign io_uopWriteback_1_bits_uop_psrc_2                           = wb[1].uop.psrc_2;
  assign io_uopWriteback_1_bits_uop_pdest                            = wb[1].uop.pdest;
  assign io_uopWriteback_1_bits_uop_robIdx_flag                      = wb[1].uop.robIdx_flag;
  assign io_uopWriteback_1_bits_uop_robIdx_value                     = wb[1].uop.robIdx_value;
  assign io_uopWriteback_1_bits_uop_debugInfo_eliminatedMove         = wb[1].uop.debugInfo_eliminatedMove;
  assign io_uopWriteback_1_bits_uop_debugInfo_renameTime             = wb[1].uop.debugInfo_renameTime;
  assign io_uopWriteback_1_bits_uop_debugInfo_dispatchTime           = wb[1].uop.debugInfo_dispatchTime;
  assign io_uopWriteback_1_bits_uop_debugInfo_enqRsTime              = wb[1].uop.debugInfo_enqRsTime;
  assign io_uopWriteback_1_bits_uop_debugInfo_selectTime             = wb[1].uop.debugInfo_selectTime;
  assign io_uopWriteback_1_bits_uop_debugInfo_issueTime              = wb[1].uop.debugInfo_issueTime;
  assign io_uopWriteback_1_bits_uop_debugInfo_writebackTime          = wb[1].uop.debugInfo_writebackTime;
  assign io_uopWriteback_1_bits_uop_debugInfo_runahead_checkpoint_id = wb[1].uop.debugInfo_runahead_checkpoint_id;
  assign io_uopWriteback_1_bits_uop_debugInfo_tlbFirstReqTime        = wb[1].uop.debugInfo_tlbFirstReqTime;
  assign io_uopWriteback_1_bits_uop_debugInfo_tlbRespTime            = wb[1].uop.debugInfo_tlbRespTime;
  assign io_uopWriteback_1_bits_uop_debug_seqNum_seqNum              = wb[1].uop.debug_seqNum_seqNum;
  assign io_uopWriteback_1_bits_uop_debug_seqNum_uopIdx              = wb[1].uop.debug_seqNum_uopIdx;
  assign io_uopWriteback_1_bits_uop_replayInst                       = wb[1].uop.replayInst;
  assign io_uopWriteback_1_bits_data                                 = wb[1].data;
  assign io_uopWriteback_1_bits_vdIdx                                = wb[1].vdIdx;
  assign io_uopWriteback_1_bits_vdIdxInField                         = wb[1].vdIdxInField;
  assign io_toSplit_threshold                                        = threshold;
  assign io_toLsq_0_valid                                            = lsq[0].valid;
  assign io_toLsq_0_bits_robidx_flag                                 = lsq[0].robidx_flag;
  assign io_toLsq_0_bits_robidx_value                                = lsq[0].robidx_value;
  assign io_toLsq_0_bits_uopidx                                      = lsq[0].uopidx;
  assign io_toLsq_0_bits_vaddr                                       = lsq[0].vaddr;
  assign io_toLsq_0_bits_vaNeedExt                                   = lsq[0].vaNeedExt;
  assign io_toLsq_0_bits_gpaddr                                      = lsq[0].gpaddr;
  assign io_toLsq_0_bits_isForVSnonLeafPTE                           = lsq[0].isForVSnonLeafPTE;
  assign io_toLsq_0_bits_feedback_0                                  = lsq[0].feedback[0];
  assign io_toLsq_0_bits_feedback_1                                  = lsq[0].feedback[1];
  assign io_toLsq_0_bits_vl                                          = lsq[0].vl;
  assign io_toLsq_0_bits_exceptionVec_3                              = lsq[0].exceptionVec[3];
  assign io_toLsq_0_bits_exceptionVec_4                              = lsq[0].exceptionVec[4];
  assign io_toLsq_0_bits_exceptionVec_5                              = lsq[0].exceptionVec[5];
  assign io_toLsq_0_bits_exceptionVec_13                             = lsq[0].exceptionVec[13];
  assign io_toLsq_0_bits_exceptionVec_19                             = lsq[0].exceptionVec[19];
  assign io_toLsq_0_bits_exceptionVec_21                             = lsq[0].exceptionVec[21];
  assign io_toLsq_1_valid                                            = lsq[1].valid;
  assign io_toLsq_1_bits_robidx_flag                                 = lsq[1].robidx_flag;
  assign io_toLsq_1_bits_robidx_value                                = lsq[1].robidx_value;
  assign io_toLsq_1_bits_uopidx                                      = lsq[1].uopidx;
  assign io_toLsq_1_bits_vaddr                                       = lsq[1].vaddr;
  assign io_toLsq_1_bits_vaNeedExt                                   = lsq[1].vaNeedExt;
  assign io_toLsq_1_bits_gpaddr                                      = lsq[1].gpaddr;
  assign io_toLsq_1_bits_isForVSnonLeafPTE                           = lsq[1].isForVSnonLeafPTE;
  assign io_toLsq_1_bits_feedback_0                                  = lsq[1].feedback[0];
  assign io_toLsq_1_bits_feedback_1                                  = lsq[1].feedback[1];
  assign io_toLsq_1_bits_vl                                          = lsq[1].vl;
  assign io_toLsq_1_bits_exceptionVec_3                              = lsq[1].exceptionVec[3];
  assign io_toLsq_1_bits_exceptionVec_4                              = lsq[1].exceptionVec[4];
  assign io_toLsq_1_bits_exceptionVec_5                              = lsq[1].exceptionVec[5];
  assign io_toLsq_1_bits_exceptionVec_13                             = lsq[1].exceptionVec[13];
  assign io_toLsq_1_bits_exceptionVec_19                             = lsq[1].exceptionVec[19];
  assign io_toLsq_1_bits_exceptionVec_21                             = lsq[1].exceptionVec[21];
  assign io_feedback_0_valid                                         = fb[0].valid;
  assign io_feedback_0_bits_robIdx_flag                              = fb[0].robIdx_flag;
  assign io_feedback_0_bits_robIdx_value                             = fb[0].robIdx_value;
  assign io_feedback_0_bits_hit                                      = fb[0].hit;
  assign io_feedback_0_bits_flushState                               = fb[0].flushState;
  assign io_feedback_0_bits_sourceType                               = fb[0].sourceType;
  assign io_feedback_0_bits_sqIdx_flag                               = fb[0].sqIdx_flag;
  assign io_feedback_0_bits_sqIdx_value                              = fb[0].sqIdx_value;
  assign io_feedback_0_bits_lqIdx_flag                               = fb[0].lqIdx_flag;
  assign io_feedback_0_bits_lqIdx_value                              = fb[0].lqIdx_value;
  assign io_feedback_0_bits_isVecPartReplay                          = fb[0].isVecPartReplay;
  assign io_feedback_0_bits_vecReplayMask                            = fb[0].vecReplayMask;
  assign io_feedback_0_bits_vecReplayMbIdx                           = fb[0].vecReplayMbIdx;
  assign io_feedback_1_valid                                         = fb[1].valid;
  assign io_feedback_1_bits_robIdx_flag                              = fb[1].robIdx_flag;
  assign io_feedback_1_bits_robIdx_value                             = fb[1].robIdx_value;
  assign io_feedback_1_bits_hit                                      = fb[1].hit;
  assign io_feedback_1_bits_flushState                               = fb[1].flushState;
  assign io_feedback_1_bits_sourceType                               = fb[1].sourceType;
  assign io_feedback_1_bits_sqIdx_flag                               = fb[1].sqIdx_flag;
  assign io_feedback_1_bits_sqIdx_value                              = fb[1].sqIdx_value;
  assign io_feedback_1_bits_lqIdx_flag                               = fb[1].lqIdx_flag;
  assign io_feedback_1_bits_lqIdx_value                              = fb[1].lqIdx_value;
  assign io_feedback_1_bits_isVecPartReplay                          = fb[1].isVecPartReplay;
  assign io_feedback_1_bits_vecReplayMask                            = fb[1].vecReplayMask;
  assign io_feedback_1_bits_vecReplayMbIdx                           = fb[1].vecReplayMbIdx;

endmodule
// END GENERATED
