// ============================================================================
// xs_LsqWrapper_core —— Load/Store 队列包装器（香山 V2R2 LSU 队列层顶层）
// ----------------------------------------------------------------------------
// 设计意图来源：src/main/scala/xiangshan/mem/lsqueue/LSQWrapper.scala
//
// 在乱序访存子系统里，本模块把两个大队列拼装成统一的“访存队列层”：
//   * LoadQueue  —— 维护在飞 load：地址/数据/异常/replay 信息、load-load(RAR)
//                   与 store-load(RAW/nuke) 违例检测、向 ROB 报异常、replay 调度、
//                   非缓存 load、向上游回写 ldout / forward 数据等。
//   * StoreQueue —— 维护在飞 store：地址 + 数据入队、提交后向 SBuffer/DCache 写、
//                   给 load 做 forward、非缓存/MMIO store、CMO 等。
//
// LsqWrapper 自身只承担**包装级控制**，逻辑量很小（绝大部分端口是两队列与顶层
// 之间的直通线，见 LsqWrapper_inst.svh）。本文件按功能分 5 节手写这些控制逻辑：
//   1) 入队拆分 + canAccept 联立
//   2) StoreQueue → LoadQueue 的“地址/数据就绪”内部互联
//   3) 非缓存（uncache/MMIO）仲裁状态机
//   4) 异常地址（exceptionAddr）延迟选择
//   5) 性能事件（perf）两级打拍
//
// 验证：UT 与 golden LsqWrapper 双例化逐拍比对；FM 以 LoadQueue/StoreQueue 为两侧
//       共享黑盒、对包装级逻辑做签名等价。
// ============================================================================
module xs_LsqWrapper_core
  import lsq_pkg::*;
(
  `include "LsqWrapper_ports.svh"
);

  // ==========================================================================
  // 0. 内部互联网声明（被 LsqWrapper_inst.svh 里的两个子模块实例连接）
  // ==========================================================================

  // -- 入队拆分（每路：needAlloc 的某一 bit + 与 req.valid 相与后的 fire）--
  logic [LSQ_ENQ_WIDTH-1:0] lq_enq_need, lq_enq_fire;  // → LoadQueue
  logic [LSQ_ENQ_WIDTH-1:0] sq_enq_need, sq_enq_fire;  // → StoreQueue

  // -- 两队列的 canAccept（互为对方的入队前提）--
  logic lq_can_accept, sq_can_accept;

  // -- StoreQueue → LoadQueue 的地址/数据就绪互联（纯内部）--
  logic                  sq2lq_stAddrReadySqPtr_flag;
  logic [5:0]            sq2lq_stAddrReadySqPtr_value;
  logic [SQ_SIZE-1:0]    sq2lq_stAddrReadyVec;
  logic                  sq2lq_stDataReadySqPtr_flag;
  logic [5:0]            sq2lq_stDataReadySqPtr_value;
  logic [SQ_SIZE-1:0]    sq2lq_stDataReadyVec;
  logic                  sq2lq_stIssuePtr_flag;
  logic [5:0]            sq2lq_stIssuePtr_value;
  logic                  sq2lq_sqEmpty;

  // -- 两队列各自的 uncache 请求输出 + 由仲裁 FSM 驱动的握手输入 --
  logic         lq_unc_req_valid, sq_unc_req_valid;
  rob_idx_t     lq_unc_req_rob,  sq_unc_req_rob;
  logic [4:0]   lq_unc_req_bits_cmd;                 // load 带 cmd；store 固定为 1
  logic [47:0]  lq_unc_req_bits_addr,  sq_unc_req_bits_addr;
  logic [49:0]  lq_unc_req_bits_vaddr, sq_unc_req_bits_vaddr;
  logic [63:0]  lq_unc_req_bits_data,  sq_unc_req_bits_data;
  logic [7:0]   lq_unc_req_bits_mask,  sq_unc_req_bits_mask;
  logic [6:0]   lq_unc_req_bits_id,    sq_unc_req_bits_id;
  logic         lq_unc_req_bits_nc,    sq_unc_req_bits_nc;
  logic         lq_unc_req_bits_memBackTypeMM, sq_unc_req_bits_memBackTypeMM;
  logic         lq_unc_req_ready, sq_unc_req_ready;
  logic         lq_unc_resp_valid, sq_unc_resp_valid;
  logic         lq_unc_idResp_valid, sq_unc_idResp_valid;
  // robIdx 子字段（inst 连接表按 flat 名连接，这里给出别名网）
  logic         lq_unc_req_bits_robIdx_flag,  sq_unc_req_bits_robIdx_flag;
  logic [7:0]   lq_unc_req_bits_robIdx_value, sq_unc_req_bits_robIdx_value;
  assign lq_unc_req_rob = '{flag: lq_unc_req_bits_robIdx_flag, value: lq_unc_req_bits_robIdx_value};
  assign sq_unc_req_rob = '{flag: sq_unc_req_bits_robIdx_flag, value: sq_unc_req_bits_robIdx_value};

  // -- 两队列各自的异常地址输出 --
  logic [63:0]  lq_exc_vaddr,  sq_exc_vaddr;
  logic         lq_exc_vaNeedExt, sq_exc_vaNeedExt;
  logic         lq_exc_isHyper,   sq_exc_isHyper;
  logic [63:0]  lq_exc_gpaddr,    sq_exc_gpaddr;
  logic         lq_exc_isForVSnonLeafPTE, sq_exc_isForVSnonLeafPTE;

  // -- 两队列的性能计数器输出（LQ 28 个，SQ 8 个）--
  logic [PERF_W-1:0] lq_perf [PERF_LQ_NUM];
  logic [PERF_W-1:0] sq_perf [PERF_SQ_NUM];

  // ==========================================================================
  // 1. 入队拆分 + canAccept 联立
  // --------------------------------------------------------------------------
  // dispatch 一拍最多送 LSQ_ENQ_WIDTH 条访存 uop。每条 uop 的 needAlloc 是 2 bit：
  //   bit0 = 需要 LoadQueue 表项，bit1 = 需要 StoreQueue 表项。
  // 拆分后各自与 req.valid 相与，得到真正写入对应队列的 fire。
  // 整体只有当两个队列都能收时才对外宣称 canAccept（io_lqCanAccept/io_sqCanAccept
  // 各自单独反映，便于上游分别观察）。
  // 注：本配置下 needAlloc 只有 0..4 这 5 路真正接入队列（第 6 路 req_5 仅参与 valid
  //     掩码，与 golden 展开一致），故用 for 统一铺开。
  // ==========================================================================
  logic [LSQ_ENQ_WIDTH-1:0] enq_req_valid;
  assign enq_req_valid = {io_enq_req_5_valid, io_enq_req_4_valid, io_enq_req_3_valid,
                          io_enq_req_2_valid, io_enq_req_1_valid, io_enq_req_0_valid};
  logic [1:0] enq_need_alloc [LSQ_ENQ_WIDTH];
  assign enq_need_alloc = '{io_enq_needAlloc_0, io_enq_needAlloc_1, io_enq_needAlloc_2,
                            io_enq_needAlloc_3, io_enq_needAlloc_4, io_enq_needAlloc_5};

  for (genvar i = 0; i < LSQ_ENQ_WIDTH; i++) begin : g_enq_split
    assign lq_enq_need[i] = enq_need_alloc[i][0];   // bit0 → LoadQueue
    assign sq_enq_need[i] = enq_need_alloc[i][1];   // bit1 → StoreQueue
    assign lq_enq_fire[i] = enq_need_alloc[i][0] & enq_req_valid[i];
    assign sq_enq_fire[i] = enq_need_alloc[i][1] & enq_req_valid[i];
  end

  assign io_lqCanAccept = lq_can_accept;
  assign io_sqCanAccept = sq_can_accept;

  // ==========================================================================
  // 2. StoreQueue → LoadQueue 内部互联 + sqEmpty 出口
  // --------------------------------------------------------------------------
  // LoadQueue 做 RAW（store→load）违例检测与 forward 时，需要知道 StoreQueue 中
  // 各表项的“地址就绪/数据就绪”状态以及发射/就绪指针。这些信号纯属两队列之间
  // 的内部联络，不出顶层；唯一外露的是 sqEmpty（也喂给 LoadQueue）。
  // ==========================================================================
  assign io_sqEmpty = sq2lq_sqEmpty;

  // ==========================================================================
  // 3. 非缓存（uncache / MMIO）仲裁状态机
  // --------------------------------------------------------------------------
  // 下游 uncache 通道一次只能在飞一笔事务。Load 与 Store 队列都可能发起 uncache
  // 请求，故用 3 态 FSM（IDLE/LOAD/STORE）择一放行：
  //   * IDLE 时按年龄（robIdx）择老者放行——pick_load() 给出 selectLq；
  //     放行后据 outstanding & nc 决定是否仍留 IDLE（nc outstanding 不占槽），
  //     否则进入 LOAD 或 STORE 等待 resp。
  //   * resp 返回（is2lq 区分回送给 Load 还是 Store）后回到 IDLE。
  // req 仅在 IDLE 拍放行（_GEN = (state==IDLE)）；resp/idResp 按 is2lq 分发。
  // ==========================================================================
  uncache_arb_e unc_state;
  wire          unc_idle    = (unc_state == UNC_IDLE);
  wire          select_load = pick_load(lq_unc_req_valid, sq_unc_req_valid,
                                         lq_unc_req_rob,   sq_unc_req_rob);

  // resp/idResp 按 is2lq 分发到对应队列
  wire resp_to_lq   =  io_uncache_resp_bits_is2lq   & io_uncache_resp_valid;
  wire resp_to_sq   = ~io_uncache_resp_bits_is2lq   & io_uncache_resp_valid;
  wire idResp_to_lq =  io_uncache_idResp_bits_is2lq & io_uncache_idResp_valid;
  wire idResp_to_sq = ~io_uncache_idResp_bits_is2lq & io_uncache_idResp_valid;

  assign lq_unc_resp_valid   = resp_to_lq;
  assign sq_unc_resp_valid   = resp_to_sq;
  assign lq_unc_idResp_valid = idResp_to_lq;
  assign sq_unc_idResp_valid = idResp_to_sq;

  // 只有 IDLE 拍、且被选中的队列，其 req 才得到下游 ready
  assign lq_unc_req_ready = unc_idle &  select_load & io_uncache_req_ready;
  assign sq_unc_req_ready = unc_idle & ~select_load & io_uncache_req_ready;

  // 顶层 uncache.req：IDLE 拍放行被选中队列的请求
  wire top_unc_req_fire = io_uncache_req_valid & io_uncache_req_ready;
  assign io_uncache_req_valid =
      unc_idle & (select_load ? lq_unc_req_valid : sq_unc_req_valid);
  assign io_uncache_req_bits_nc =
      select_load ? lq_unc_req_bits_nc : sq_unc_req_bits_nc;
  assign io_uncache_req_bits_robIdx_flag =
      select_load ? lq_unc_req_bits_robIdx_flag : sq_unc_req_bits_robIdx_flag;
  assign io_uncache_req_bits_robIdx_value =
      select_load ? lq_unc_req_bits_robIdx_value : sq_unc_req_bits_robIdx_value;
  assign io_uncache_req_bits_cmd =
      select_load ? lq_unc_req_bits_cmd : 5'h1;   // store uncache cmd 固定为 1
  assign io_uncache_req_bits_addr =
      select_load ? lq_unc_req_bits_addr : sq_unc_req_bits_addr;
  assign io_uncache_req_bits_vaddr =
      select_load ? lq_unc_req_bits_vaddr : sq_unc_req_bits_vaddr;
  assign io_uncache_req_bits_data =
      select_load ? lq_unc_req_bits_data : sq_unc_req_bits_data;
  assign io_uncache_req_bits_mask =
      select_load ? lq_unc_req_bits_mask : sq_unc_req_bits_mask;
  assign io_uncache_req_bits_id =
      select_load ? lq_unc_req_bits_id : sq_unc_req_bits_id;
  assign io_uncache_req_bits_memBackTypeMM =
      select_load ? lq_unc_req_bits_memBackTypeMM : sq_unc_req_bits_memBackTypeMM;

  always_ff @(posedge clock) begin
    if (reset) begin
      unc_state <= UNC_IDLE;
    end else if (unc_idle) begin
      if (top_unc_req_fire)
        // nc + outstanding 不占用在途槽位，仍留 IDLE；否则按选择进入 LOAD/STORE
        unc_state <= (io_uncacheOutstanding & io_uncache_req_bits_nc) ? UNC_IDLE
                   : select_load ? UNC_LOAD : UNC_STORE;
    end else if ((unc_state == UNC_LOAD || unc_state == UNC_STORE)
                 && io_uncache_resp_valid) begin
      unc_state <= UNC_IDLE;
    end
  end

  // ==========================================================================
  // 4. 异常地址（exceptionAddr）延迟选择
  // --------------------------------------------------------------------------
  // ROB 提交触发异常对 lq/sq 的 deqPtr 更新是延迟两拍的（commit→find→trigger→
  // ptr 更新）。异常地址在 trigger 之后一拍才被使用，故这里把“该异常是否来自
  // store”打一拍（isStore_d），用它在 StoreQueue / LoadQueue 给出的异常地址信息
  // 之间选择。7 个字段共享同一选择子（与 Scala 一致）。
  // ==========================================================================
  logic exc_is_store_d;
  always_ff @(posedge clock) exc_is_store_d <= io_exceptionAddr_isStore;

  assign io_exceptionAddr_vaddr   = exc_is_store_d ? sq_exc_vaddr   : lq_exc_vaddr;
  assign io_exceptionAddr_vaNeedExt = exc_is_store_d ? sq_exc_vaNeedExt : lq_exc_vaNeedExt;
  assign io_exceptionAddr_isHyper = exc_is_store_d ? sq_exc_isHyper : lq_exc_isHyper;
  assign io_exceptionAddr_gpaddr  = exc_is_store_d ? sq_exc_gpaddr  : lq_exc_gpaddr;
  assign io_exceptionAddr_isForVSnonLeafPTE =
      exc_is_store_d ? sq_exc_isForVSnonLeafPTE : lq_exc_isForVSnonLeafPTE;

  // ==========================================================================
  // 5. 性能事件（perf）两级打拍
  // --------------------------------------------------------------------------
  // 36 个性能计数器（LoadQueue 提供前 28，StoreQueue 提供后 8）各打两拍对齐后
  // 输出，避免长扇出影响时序。用 genvar 把 36 路统一铺开。
  // ==========================================================================
  logic [PERF_W-1:0] perf_src   [PERF_NUM];
  logic [PERF_W-1:0] perf_stage1[PERF_NUM];
  logic [PERF_W-1:0] perf_stage2[PERF_NUM];

  for (genvar i = 0; i < PERF_NUM; i++) begin : g_perf
    // 前 PERF_LQ_NUM 路取 LoadQueue，其余取 StoreQueue。两支的下标都钳到合法范围，
    // 避免 elaborator 对未选中分支求出越界下标（仅影响 X 优化，不影响功能）。
    localparam int LQI = (i < PERF_LQ_NUM)        ? i                 : 0;
    localparam int SQI = (i >= PERF_LQ_NUM)       ? i - PERF_LQ_NUM   : 0;
    assign perf_src[i] = (i < PERF_LQ_NUM) ? lq_perf[LQI] : sq_perf[SQI];
    always_ff @(posedge clock) begin
      perf_stage1[i] <= perf_src[i];
      perf_stage2[i] <= perf_stage1[i];
    end
  end

  `include "LsqWrapper_perf_out.svh"  // assign io_perf_<i>_value = perf_stage2[i];

  // ==========================================================================
  // 6. 两个大队列子模块实例（与 golden 完全一致）
  // --------------------------------------------------------------------------
  // 直通端口连顶层同名口，被本文件接管的端口连上面的 readable 网。
  // ==========================================================================
  `include "LsqWrapper_inst.svh"

endmodule
