// =====================================================================
// StoreUnit.sv —— store 地址流水（sta）：s0 选源算地址 → s1 TLB → s2 PMP/MMIO 判定 → s3/sx 写回
// ---------------------------------------------------------------------
// 位置：MemBlock 里 2 条完全相同的 store 地址流水。store 的"数据"走另一条路（std 直接写 SQ），
//   本模块只处理"地址"：把虚地址翻译成物理地址、查权限、把结果写进 store queue，并向 ROB 写回。
//   上游：发射队列（stin 标量 store / cbo）、向量拆分流水（vecstin）、store 非对齐缓冲（misalign_stin：
//         跨 16B 边界的 store 被拆成两次访问后重新进来）。
//   下游：DTLB、store queue（lsq / lsq_replenish / st_mask_out）、load 流水（stld_nuke_query 查
//         st-ld 违例）、发射队列反馈（feedback_slow / issue）、写回（stout 标量 / vecstout 向量）、
//         非对齐缓冲入队（misalign_enq）。
// 每一级做什么（详见各节开头）：
//   s0 三路来源选一路（非对齐缓冲 > 向量 > 标量），算虚地址与字节掩码，判对齐，发 DTLB 请求；
//   s1 拿 TLB 结果：物理地址 / 页异常 / Svpbmt 属性；跑调试触发器（MemTrigger_3）；
//      地址写 store queue；向 load 流水发违例查询；跨 16B 的非对齐 store 送非对齐缓冲；
//   s2 拿 PMP 结果：访问异常、MMIO/NC 判定；把异常与 MMIO 属性补写进 store queue；
//      向发射队列回 TLB miss 反馈（feedback_slow）；非对齐缓冲的子访问结果回给缓冲（misalign_stout）；
//   s3 + sx 写回：再延一拍（RAWTotalDelayCycles=1，等 load 侧违例检查），标量走 stout、向量走 vecstout。
// 本配置（KunminghuV2Config）下被 firtool 跨层折掉的东西（golden 端口表里没有，核里也不写）：
//   · store 硬件预取一路（prefetch_req / prefetch_train / s1,s2_prefetch_spec）整条不存在；
//   · DCache 的写意图查询只剩 dcache_req_valid 一根线（其余端口上层不接）；
//   · stout / vecstout 的 ready 恒 1 ⇒ 整条流水的 ready 链恒通（核里保留 ready 链的写法，常量记为
//     STOUT_READY）；vec_isFirstIssue 恒 1；debug_ls、性能计数器全部消掉。
// 文件结构：storeunit_pkg → xs_StoreUnit_core（手写可读核）→ golden 同名 wrapper（生成）。
//   GENERATED 段由 scripts/gen_storeunit.py 从 golden 端口表/寄存器表生成：
//   types（接口 struct）、core_ports（核端口表）、trigger（MemTrigger_3 例化）、
//   pipe_regs（整包打拍寄存器：字段集合照 golden 现数）、wrapper（扁平端口 ↔ struct 拆装）。
// =====================================================================
// 本文件导航（按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位；行号由生成器维护）：
// BEGIN GENERATED(nav) —— scripts/gen_storeunit.py 生成，勿手改
//   L43    storeunit_pkg：常量、译码与掩码小函数、接口 struct（生成）
//   L346   xs_StoreUnit_core —— 可读核
//   L449   s0：三路来源选一路，算虚地址 / 掩码 / 对齐，发 DTLB 请求
//   L624   s1：TLB 应答、调试触发器、写 SQ、违例查询、非对齐入缓冲
//   L853   s2：PMP 应答、异常与 MMIO 判定、补写 SQ、反馈
//   L1042  s3 + sx：写回
//   L1144  整包打拍寄存器（生成）
//   L1793  golden 同名 wrapper（生成）
// END GENERATED(nav)
// =====================================================================

package storeunit_pkg;

  // ---------------- 位宽 ----------------
  localparam int VADDR_W = 50;    // VAddrBits
  localparam int XLEN    = 64;
  localparam int VLEN_B  = 16;    // VLEN/8：一次访问最多 16 字节

  // ---------------- 异常号（ExceptionNO）与 sta 能报的异常集合（StaCfg / VstuCfg 相同）----------------
  localparam int EXC_BREAKPOINT        = 3;
  localparam int EXC_ST_ADDR_MISALIGN  = 6;
  localparam int EXC_ST_ACCESS_FAULT   = 7;
  localparam int EXC_ST_PAGE_FAULT     = 15;
  localparam int EXC_HARDWARE_ERROR    = 19;
  localparam int EXC_ST_GUEST_PF       = 23;
  localparam logic [23:0] STA_EXC_MASK = 24'h8880C8;   // 位 3/6/7/15/19/23

  // ---------------- Svpbmt 页属性 ----------------
  localparam logic [1:0] PBMT_PMA = 2'd0;   // 不覆盖：由 PMA/PMP 决定是否 MMIO
  localparam logic [1:0] PBMT_NC  = 2'd1;   // 不可缓存、幂等（主存式）
  localparam logic [1:0] PBMT_IO  = 2'd2;   // 不可缓存、非幂等（MMIO）

  // ---------------- TlbCmd / 触发器动作 / st-ld 违例匹配粒度 ----------------
  localparam logic [2:0] TLB_CMD_READ  = 3'd0;
  localparam logic [2:0] TLB_CMD_WRITE = 3'd1;
  localparam logic [3:0] TRIG_ACT_BREAKPOINT = 4'h0;   // 报断点异常
  localparam logic [3:0] TRIG_ACT_DEBUG_MODE = 4'h1;   // 进 debug mode
  localparam logic [1:0] NUKE_MATCH_NORMAL    = 2'd0;  // 按 8B 比
  localparam logic [1:0] NUKE_MATCH_QUADWORD  = 2'd1;  // 按 16B 比（128 位访问）
  localparam logic [1:0] NUKE_MATCH_CACHELINE = 2'd2;  // 按 64B 缓存行比（cbo）

  // ---------------- LSUOpType 译码（xiangshan/package.scala）----------------
  // cbo.clean/flush/inval = 4'b11xx（高 3 位为 0）；cbo.zero = 4'b0111
  function automatic logic is_cbo(input logic [8:0] op);          // 不含 cbo.zero
    return (op[3:2] == 2'b11) & (op[6:4] == 3'b000);
  endfunction
  function automatic logic is_cbo_all(input logic [8:0] op);      // 含 cbo.zero
    return is_cbo(op) | (op[3:0] == 4'b0111);
  endfunction
  function automatic logic is_hsv(input logic [8:0] op);          // hsv.b/h/w/d：虚拟化 store
    return op[4] & ~op[5] & (op[8:7] == 2'b00);
  endfunction

  // 环形指针"是否该被这次 redirect 冲掉"（RobPtr.needFlush）：
  //   redirect 有效，且（level=1 表示连 redirect 指令自己也冲，此时相等也算）或本指令比它年轻。
  //   年轻判定 isAfter：flag 不同则 value 小者年轻，flag 相同则 value 大者年轻 → 三项异或。
  function automatic logic rob_need_flush(
      input logic       flag,
      input logic [7:0] value,
      input logic       rd_valid,
      input logic       rd_level,
      input logic       rd_flag,
      input logic [7:0] rd_value);
    return rd_valid & (rd_level & ({flag, value} == {rd_flag, rd_value})
                       | (flag ^ rd_flag ^ (value > rd_value)));
  endfunction

  // 访问宽度（alignType：0=1B 1=2B 2=4B 3=8B）对应的"从地址 0 起"的字节掩码
  function automatic logic [VLEN_B-1:0] base_mask(input logic [1:0] align_type);
    case (align_type)
      2'd0:    return 16'h0001;
      2'd1:    return 16'h0003;
      2'd2:    return 16'h000F;
      default: return 16'h00FF;
    endcase
  endfunction

  // 标量 store 在 16B 窗口内的字节掩码（genVWmask128）：按 size 取基掩码再左移 addr[3:0]。
  // size 编码取 fuOpType[2:0]：0..3 = 1/2/4/8B，4 与 7 = 16B，5/6 无定义 → 0。移出 16 位的部分丢弃。
  function automatic logic [VLEN_B-1:0] store_mask128(input logic [3:0] addr_low, input logic [2:0] size);
    logic [VLEN_B-1:0] base;
    case (size)
      3'd0:    base = 16'h0001;
      3'd1:    base = 16'h0003;
      3'd2:    base = 16'h000F;
      3'd3:    base = 16'h00FF;
      3'd4:    base = 16'hFFFF;
      3'd7:    base = 16'hFFFF;
      default: base = 16'h0000;
    endcase
    return base << addr_low;
  endfunction

  // 掩码里最低的置位字节号（genVFirstUnmask）；全 0 时得 0
  function automatic logic [3:0] first_set_byte(input logic [VLEN_B-1:0] mask);
    logic [3:0] idx;
    idx = 4'd0;
    for (int i = VLEN_B - 1; i >= 0; i--)
      if (mask[i]) idx = 4'(i);
    return idx;
  endfunction

  // BEGIN GENERATED(types) —— scripts/gen_storeunit.py 生成，勿手改
  // 微操作信息（DynInst 在本模块各接口 / 各级留下的字段并集）
  typedef struct packed {
    logic          ftqPtr_flag;
    logic [5:0]    ftqPtr_value;
    logic [3:0]    ftqOffset;
    logic [34:0]   fuType;
    logic [8:0]    fuOpType;
    logic          rfWen;
    logic [31:0]   imm;
    logic [7:0]    pdest;
    logic          robIdx_flag;
    logic [7:0]    robIdx_value;
    logic          debugInfo_eliminatedMove;
    logic [63:0]   debugInfo_renameTime;
    logic [63:0]   debugInfo_dispatchTime;
    logic [63:0]   debugInfo_enqRsTime;
    logic [63:0]   debugInfo_selectTime;
    logic [63:0]   debugInfo_issueTime;
    logic [63:0]   debugInfo_writebackTime;
    logic [63:0]   debugInfo_runahead_checkpoint_id;
    logic [63:0]   debugInfo_tlbFirstReqTime;
    logic [63:0]   debugInfo_tlbRespTime;
    logic [55:0]   debug_seqNum_seqNum;
    logic [7:0]    debug_seqNum_uopIdx;
    logic          lqIdx_flag;
    logic [6:0]    lqIdx_value;
    logic          sqIdx_flag;
    logic [5:0]    sqIdx_value;
    logic [23:0]   exceptionVec;
    logic [3:0]    trigger;
    logic [7:0]    vpu_vstart;
    logic [2:0]    vpu_nf;
    logic [1:0]    vpu_veew;
    logic [6:0]    uopIdx;
  } uop_t;

  // redirect（冲刷）
  typedef struct packed {
    logic          robIdx_flag;
    logic [7:0]    robIdx_value;
    logic          level;
  } redirect_t;

  // 发射队列来的标量 store（MemExuInput）
  typedef struct packed {
    uop_t          uop;
    logic [63:0]   src_0;
    logic          isFirstIssue;
  } stin_t;

  // 向量拆分流水来的元素访问（VecPipeBundle）
  typedef struct packed {
    uop_t          uop;
    logic [63:0]   vaddr;
    logic [49:0]   basevaddr;
    logic [15:0]   mask;
    logic [2:0]    alignedType;
    logic          vecActive;
    logic          vecIsFirstActiveElement;
    logic [3:0]    mBIndex;
    logic [7:0]    elemIdx;
    logic [4:0]    splitIndex;
  } vec_in_t;

  // 流水各级传递的访问包（LsPipelineBundle 并集；SQ / 非对齐缓冲接口也用它）
  typedef struct packed {
    uop_t          uop;
    logic [49:0]   vaddr;
    logic [15:0]   mask;
    logic          isvec;
    logic          is128bit;
    logic          isFinalSplit;
    logic          vaNeedExt;
    logic [47:0]   paddr;
    logic [63:0]   gpaddr;
    logic          nc;
    logic          mmio;
    logic          memBackTypeMM;
    logic          isForVSnonLeafPTE;
    logic          vecActive;
    logic          need_rep;
    logic [63:0]   fullva;
    logic          wlineflag;
    logic          miss;
    logic          isHyper;
    logic          isFrmMisAlignBuf;
    logic          isMisalign;
    logic          misalignWith16Byte;
    logic          updateAddrValid;
    logic          af;
    logic          hasException;
    logic [7:0]    elemIdx;
    logic [2:0]    alignedType;
    logic [3:0]    mbIndex;
    logic [4:0]    splitIndex;
    logic [49:0]   vecBaseVaddr;
    logic          isFirstIssue;
    logic [49:0]   vecVaddrOffset;
  } flow_t;

  // DTLB 请求
  typedef struct packed {
    logic [49:0]   vaddr;
    logic [63:0]   fullva;
    logic          checkfullva;
    logic [2:0]    cmd;
    logic          hyperinst;
    logic [6:0]    memidx_idx;
    logic          frm_mabuf;
    logic          debug_robIdx_flag;
    logic [7:0]    debug_robIdx_value;
    logic          debug_isFirstIssue;
  } tlb_req_t;

  // DTLB 应答
  typedef struct packed {
    logic [47:0]   paddr_0;
    logic [63:0]   gpaddr_0;
    logic [63:0]   fullva;
    logic [1:0]    pbmt_0;
    logic          miss;
    logic          isForVSnonLeafPTE;
    logic          excp_0_vaNeedExt;
    logic          excp_0_isHyper;
    logic          excp_0_gpf_ld;
    logic          excp_0_gpf_st;
    logic          excp_0_pf_ld;
    logic          excp_0_pf_st;
    logic          excp_0_af_ld;
    logic          excp_0_af_st;
    logic          ptwBack;
    logic [6:0]    memidx_idx;
  } tlb_resp_t;

  // PMP / PMA 检查结果
  typedef struct packed {
    logic          ld;
    logic          st;
    logic          mmio;
  } pmp_t;

  // 给发射队列的反馈（RSFeedback）
  typedef struct packed {
    logic          robIdx_flag;
    logic [7:0]    robIdx_value;
    logic          hit;
    logic          flushState;
    logic          sqIdx_flag;
    logic [5:0]    sqIdx_value;
    logic          lqIdx_flag;
    logic [6:0]    lqIdx_value;
  } feedback_t;

  // st-ld 违例查询（StoreNukeQueryBundle）
  typedef struct packed {
    logic          robIdx_flag;
    logic [7:0]    robIdx_value;
    logic [47:0]   paddr;
    logic [15:0]   mask;
    logic [1:0]    matchType;
  } nuke_query_t;

  // 标量写回（MemExuOutput）
  typedef struct packed {
    uop_t          uop;
    logic          debug_isMMIO;
    logic          debug_isNCIO;
    logic [47:0]   debug_paddr;
    logic [49:0]   debug_vaddr;
  } mem_out_t;

  // 写回延迟级的包（VecMemExuOutput：标量写回 + 向量元素信息）
  typedef struct packed {
    mem_out_t      out;
    logic          vecFeedback;
    logic          hasException;
    logic [7:0]    elemIdx;
    logic [3:0]    mbIndex;
    logic [15:0]   mask;
    logic [63:0]   vaddr;
    logic          vaNeedExt;
    logic [63:0]   gpaddr;
    logic          isForVSnonLeafPTE;
    logic [4:0]    splitIndx;
  } sx_t;

  // 向量 store 写回（VecPipelineFeedbackIO）
  typedef struct packed {
    logic [3:0]    mBIndex;
    logic          hit;
    logic [3:0]    trigger;
    logic [23:0]   exceptionVec;
    logic          hasException;
    logic [63:0]   vaddr;
    logic          vaNeedExt;
    logic [63:0]   gpaddr;
    logic          isForVSnonLeafPTE;
    logic [7:0]    vstart;
    logic [7:0]    elemIdx;
    logic [15:0]   mask;
    logic [4:0]    splitIndex;
  } vec_feedback_t;

  // 提前告诉 SQ 的字节掩码（StoreMaskBundle）
  typedef struct packed {
    logic [5:0]    sqIdx_value;
    logic [15:0]   mask;
  } st_mask_t;
  // END GENERATED(types)

endpackage

// =====================================================================
// xs_StoreUnit_core —— 可读核
// =====================================================================
module xs_StoreUnit_core
  import storeunit_pkg::*;
(
  // BEGIN GENERATED(core_ports) —— scripts/gen_storeunit.py 生成，勿手改
  input  logic          clock,
  input  logic          reset,
  input  logic          redirect_valid,
  input  redirect_t     redirect,
  input  logic          csrCtrl_hd_misalign_st_enable,
  output logic          stin_ready,
  input  logic          stin_valid,
  input  stin_t         stin,
  output logic          issue_valid,
  output stin_t         issue,
  output logic          misalign_stin_ready,
  input  logic          misalign_stin_valid,
  input  flow_t         misalign_stin,
  output logic          misalign_stout_valid,
  output flow_t         misalign_stout,
  output logic          tlb_req_valid,
  output tlb_req_t      tlb_req,
  input  logic          tlb_resp_valid,
  input  tlb_resp_t     tlb_resp,
  output logic          dcache_req_valid,
  input  pmp_t          pmp,
  output logic          lsq_valid,
  output flow_t         lsq,
  output flow_t         lsq_replenish,
  output logic          feedback_slow_valid,
  output feedback_t     feedback_slow,
  output logic          stld_nuke_query_valid,
  output nuke_query_t   stld_nuke_query,
  output logic          stout_valid,
  output mem_out_t      stout,
  output logic          vecstout_valid,
  output vec_feedback_t vecstout,
  output logic          st_mask_out_valid,
  output st_mask_t      st_mask_out,
  output logic          vecstin_ready,
  input  logic          vecstin_valid,
  input  vec_in_t       vecstin,
  input  logic          misalign_enq_req_ready,
  output logic          misalign_enq_req_valid,
  output flow_t         misalign_enq_req,
  output logic          misalign_enq_revoke,
  input  logic [1:0]    fromCsrTrigger_tdataVec_0_matchType,
  input  logic          fromCsrTrigger_tdataVec_0_select,
  input  logic          fromCsrTrigger_tdataVec_0_timing,
  input  logic [3:0]    fromCsrTrigger_tdataVec_0_action,
  input  logic          fromCsrTrigger_tdataVec_0_chain,
  input  logic          fromCsrTrigger_tdataVec_0_store,
  input  logic [63:0]   fromCsrTrigger_tdataVec_0_tdata2,
  input  logic [1:0]    fromCsrTrigger_tdataVec_1_matchType,
  input  logic          fromCsrTrigger_tdataVec_1_select,
  input  logic          fromCsrTrigger_tdataVec_1_timing,
  input  logic [3:0]    fromCsrTrigger_tdataVec_1_action,
  input  logic          fromCsrTrigger_tdataVec_1_chain,
  input  logic          fromCsrTrigger_tdataVec_1_store,
  input  logic [63:0]   fromCsrTrigger_tdataVec_1_tdata2,
  input  logic [1:0]    fromCsrTrigger_tdataVec_2_matchType,
  input  logic          fromCsrTrigger_tdataVec_2_select,
  input  logic          fromCsrTrigger_tdataVec_2_timing,
  input  logic [3:0]    fromCsrTrigger_tdataVec_2_action,
  input  logic          fromCsrTrigger_tdataVec_2_chain,
  input  logic          fromCsrTrigger_tdataVec_2_store,
  input  logic [63:0]   fromCsrTrigger_tdataVec_2_tdata2,
  input  logic [1:0]    fromCsrTrigger_tdataVec_3_matchType,
  input  logic          fromCsrTrigger_tdataVec_3_select,
  input  logic          fromCsrTrigger_tdataVec_3_timing,
  input  logic [3:0]    fromCsrTrigger_tdataVec_3_action,
  input  logic          fromCsrTrigger_tdataVec_3_chain,
  input  logic          fromCsrTrigger_tdataVec_3_store,
  input  logic [63:0]   fromCsrTrigger_tdataVec_3_tdata2,
  input  logic          fromCsrTrigger_tEnableVec_0,
  input  logic          fromCsrTrigger_tEnableVec_1,
  input  logic          fromCsrTrigger_tEnableVec_2,
  input  logic          fromCsrTrigger_tEnableVec_3,
  input  logic          fromCsrTrigger_debugMode,
  input  logic          fromCsrTrigger_triggerCanRaiseBpExp,
  input  logic          sqCommitPtr_flag,
  input  logic [5:0]    sqCommitPtr_value,
  input  logic [6:0]    sqCommitUopIdx,
  input  logic          sqCommitRobIdx_flag,
  input  logic [7:0]    sqCommitRobIdx_value
  // END GENERATED(core_ports)
);

  // 写回口恒 ready（上层把 stout/vecstout.ready 接常 1，golden 里端口已被折掉）
  localparam logic STOUT_READY = 1'b1;

  // 各级之间传递的"访问包"（LsPipelineBundle）。sN_in = 第 N 级入口寄存器的读回（见文件尾
  // GENERATED(pipe_regs)：golden 每级只留下后面真用得到的字段，没留的字段读回为 0），
  // sN_out = 第 N 级加工后交给下一级的包。
  flow_t s0_out;
  flow_t s1_in, s1_out;
  flow_t s2_in, s2_out;
  flow_t s3_in;

  logic s1_ready, s2_ready, s3_ready;

  // ===================================================================
  // s0：三路来源选一路，算虚地址 / 掩码 / 对齐，发 DTLB 请求
  // -------------------------------------------------------------------
  // 输入：stin（标量 store，地址 = src0 + imm12）、vecstin（向量元素，地址已由拆分流水算好）、
  //       misalign_stin（非对齐缓冲拆出的子访问，地址/掩码都是现成的）、redirect、s1_ready。
  // 选源：非对齐缓冲 > 向量 > 标量，固定优先级；没被选中的一路 ready=0，下一拍再来。
  // 对齐：地址不按访问宽度对齐 → isMisalign。再细分两种：
  //   · 没跨 16B 边界（misalignWith16Byte）：当成一次 128 位访问做完，掩码就是真实字节；
  //   · 跨了 16B 边界（cross16Bytes）：s1 送去非对齐缓冲拆成两次；这里只给 SQ 一个"基掩码"
  //     （从字节 0 起的 size 个 1），SQ 自己按地址低位移位拆分。
  //   跨 16B 的 store 必须等它成为 SQ 里最老的那条才能进非对齐缓冲（缓冲只有一项），
  //   否则标 misalignNeedReplay，让发射队列稍后重发。
  // cbo.*（缓存块操作）当作对齐访问，掩码全 1；cbo.clean/flush/inval 查 TLB 用读权限。
  // ===================================================================
  logic    s0_valid;
  logic    s0_use_flow_ma, s0_use_flow_vec, s0_use_flow_rs, s0_use_non_prf_flow;
  stin_t   s0_stin;        // 没选中标量一路时整包清 0（下面各 Mux 的"其它"分支因此自然为 0）
  vec_in_t s0_vecstin;     // 同上，向量一路
  uop_t    s0_uop;

  assign s0_valid            = stin_valid | vecstin_valid | misalign_stin_valid;
  assign s0_use_flow_ma      = misalign_stin_valid;
  assign s0_use_flow_vec     = vecstin_valid & ~misalign_stin_valid;
  assign s0_use_flow_rs      = stin_valid & ~vecstin_valid & ~misalign_stin_valid;
  assign s0_use_non_prf_flow = s0_use_flow_rs | s0_use_flow_vec | s0_use_flow_ma;   // 本配置无预取一路
  assign s0_stin             = s0_use_flow_rs  ? stin    : '0;
  assign s0_vecstin          = s0_use_flow_vec ? vecstin : '0;
  assign s0_uop              = s0_use_flow_ma ? misalign_stin.uop
                             : s0_use_flow_rs ? s0_stin.uop
                             :                  s0_vecstin.uop;

  // 首次发射标记（只给调试计时用）：非对齐缓冲重入不算；向量一路上层恒给 1
  logic s0_isFirstIssue;
  assign s0_isFirstIssue = ~s0_use_flow_ma & (s0_use_flow_rs & stin.isFirstIssue | s0_use_flow_vec);

  logic s0_kill, s0_fire;
  assign s0_kill = rob_need_flush(s0_uop.robIdx_flag, s0_uop.robIdx_value, redirect_valid,
                                  redirect.level, redirect.robIdx_flag, redirect.robIdx_value);
  assign s0_fire = s0_valid & ~s0_kill & s1_ready;

  // ---- 虚地址 ----
  logic [VADDR_W-1:0] s0_saddr;      // 标量：基址 + 符号扩展的 12 位立即数（按 VAddrBits 截断）
  logic [VADDR_W-1:0] s0_vaddr;
  logic [XLEN-1:0]    s0_fullva;     // 64 位完整虚地址：给 TLB 检查高位是否合法
  assign s0_saddr  = s0_stin.src_0[VADDR_W-1:0] + {{(VADDR_W-12){s0_stin.uop.imm[11]}}, s0_stin.uop.imm[11:0]};
  assign s0_vaddr  = s0_use_flow_ma  ? misalign_stin.vaddr
                   : s0_use_flow_rs  ? s0_saddr
                   : s0_use_flow_vec ? s0_vecstin.vaddr[VADDR_W-1:0]
                   :                   '0;
  assign s0_fullva = s0_use_flow_rs  ? s0_stin.src_0 + {{(XLEN-12){s0_stin.uop.imm[11]}}, s0_stin.uop.imm[11:0]}
                   : s0_use_flow_vec ? s0_vecstin.vaddr
                   :                   XLEN'(s0_vaddr);

  // ---- cbo 识别 ----
  logic s0_isCbo, s0_isCbo_noZero, s0_wlineflag;
  assign s0_isCbo        = s0_use_flow_rs & is_cbo_all(s0_stin.uop.fuOpType);
  assign s0_isCbo_noZero = s0_use_flow_rs & is_cbo(s0_stin.uop.fuOpType);
  assign s0_wlineflag    = s0_use_flow_rs & is_cbo_all(s0_uop.fuOpType);   // 整行写（给 SQ / sbuffer）

  // ---- 对齐检查 ----
  logic [1:0] s0_alignType;          // 访问宽度：向量取元素宽度，标量取 fuOpType 低 2 位
  logic       s0_addr_aligned;
  logic       s0_vecActive;          // 向量元素是否活跃（被 mask 掉的元素不产生异常）；非向量恒 1
  logic       s0_isMisalign;
  logic [4:0] s0_addr_Up_low;        // 访问最后一个字节地址的低 5 位
  logic       s0_rs_cross16Bytes;    // 访问跨 16B 边界
  logic       s0_misalignWith16Byte; // 非对齐但没跨 16B
  logic       s0_misalignNeedReplay; // 跨 16B 但还不能进非对齐缓冲
  logic       s0_is128bit;

  assign s0_alignType = s0_use_flow_vec ? s0_vecstin.alignedType[1:0] : s0_uop.fuOpType[1:0];
  assign s0_vecActive = ~s0_use_flow_vec | s0_vecstin.vecActive;

  always_comb begin
    case (s0_alignType)
      2'b00:   s0_addr_aligned = 1'b1;
      2'b01:   s0_addr_aligned = (s0_vaddr[0]   == 1'b0);
      2'b10:   s0_addr_aligned = (s0_vaddr[1:0] == 2'b0);
      default: s0_addr_aligned = (s0_vaddr[2:0] == 3'b0);
    endcase
    s0_addr_aligned = s0_addr_aligned | s0_isCbo;

    case (s0_alignType)
      2'b00:   s0_addr_Up_low = 5'd0;
      2'b01:   s0_addr_Up_low = 5'd1;
      2'b10:   s0_addr_Up_low = 5'd3;
      default: s0_addr_Up_low = 5'd7;
    endcase
    s0_addr_Up_low = s0_addr_Up_low + s0_vaddr[4:0];
  end

  // 向量拆分流水若已判出元素地址非对齐（exceptionVec[6]）也算
  assign s0_isMisalign = s0_use_non_prf_flow
                       & (~s0_addr_aligned | s0_vecstin.uop.exceptionVec[EXC_ST_ADDR_MISALIGN] & s0_vecActive);
  assign s0_rs_cross16Bytes    = s0_addr_Up_low[4] != s0_vaddr[4];
  assign s0_misalignWith16Byte = ~s0_rs_cross16Bytes & ~s0_addr_aligned;
  // 能进非对齐缓冲的条件：本条就是 SQ 待提交的那条（sqIdx 相等，或 robIdx + uopIdx 相等）；
  // 向量 store 还要求是第一个活跃元素
  assign s0_misalignNeedReplay = s0_rs_cross16Bytes
      & (~({s0_uop.sqIdx_flag, s0_uop.sqIdx_value} == {sqCommitPtr_flag, sqCommitPtr_value}
           | {s0_uop.robIdx_flag, s0_uop.robIdx_value} == {sqCommitRobIdx_flag, sqCommitRobIdx_value}
             & s0_uop.uopIdx == sqCommitUopIdx)
         | ~s0_vecstin.vecIsFirstActiveElement & s0_use_flow_vec);
  assign s0_is128bit = s0_use_flow_ma ? misalign_stin.is128bit
                                      : s0_vecstin.alignedType[2] | s0_misalignWith16Byte;

  // ---- 字节掩码 ----
  logic [VLEN_B-1:0] s0_mask;
  assign s0_mask = s0_use_flow_ma  ? misalign_stin.mask
                 : s0_use_flow_rs  ? (s0_isCbo ? '1 : store_mask128(s0_saddr[3:0], s0_uop.fuOpType[2:0]))
                 : s0_use_flow_vec ? s0_vecstin.mask
                 :                   '1;

  // ---- 调试计时器（GTimer：自由计数，只用来给 debugInfo 打时间戳）----
  logic [63:0] s0_out_uop_debugInfo_tlbFirstReqTime_c;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) s0_out_uop_debugInfo_tlbFirstReqTime_c <= 64'h0;
    else       s0_out_uop_debugInfo_tlbFirstReqTime_c <= s0_out_uop_debugInfo_tlbFirstReqTime_c + 64'h1;
  end

  // ---- 交给 s1 的包 ----
  always_comb begin
    s0_out                    = '0;
    s0_out.uop                = s0_uop;
    if (s0_valid & s0_isFirstIssue)
      s0_out.uop.debugInfo_tlbFirstReqTime = s0_out_uop_debugInfo_tlbFirstReqTime_c;
    s0_out.vaddr              = s0_vaddr;
    s0_out.fullva             = s0_fullva;
    // 跨 16B 的非对齐访问：给 SQ 基掩码，由 SQ 按地址低位移位拆分
    s0_out.mask               = (s0_rs_cross16Bytes & ~s0_addr_aligned) ? base_mask(s0_alignType) : s0_mask;
    s0_out.isFirstIssue       = s0_isFirstIssue;
    s0_out.wlineflag          = s0_wlineflag;
    s0_out.isvec              = s0_use_flow_vec;
    s0_out.is128bit           = s0_is128bit;
    s0_out.vecActive          = s0_vecActive;
    s0_out.elemIdx            = s0_vecstin.elemIdx;
    s0_out.alignedType        = s0_vecstin.alignedType;
    s0_out.mbIndex            = s0_vecstin.mBIndex;
    s0_out.vecBaseVaddr       = s0_vecstin.basevaddr;
    s0_out.splitIndex         = s0_vecstin.splitIndex;
    s0_out.misalignWith16Byte = s0_misalignWith16Byte;
    s0_out.isMisalign         = s0_isMisalign;
    s0_out.isFrmMisAlignBuf   = s0_use_flow_ma;
    s0_out.isFinalSplit       = misalign_stin_valid & misalign_stin.isFinalSplit;
  end

  // ---- DTLB 请求（每拍都发，s1 取结果）----
  always_comb begin
    tlb_req                    = '0;
    tlb_req.vaddr              = s0_vaddr;
    tlb_req.fullva             = s0_fullva;
    tlb_req.checkfullva        = s0_use_flow_rs | s0_use_flow_vec;   // 非对齐缓冲的子访问已查过
    tlb_req.cmd                = s0_isCbo_noZero ? TLB_CMD_READ : TLB_CMD_WRITE;
    tlb_req.hyperinst          = is_hsv(s0_uop.fuOpType);
    tlb_req.memidx_idx         = 7'(s0_use_non_prf_flow ? s0_uop.sqIdx_value : 6'h0);
    tlb_req.frm_mabuf          = s0_use_flow_ma;
    tlb_req.debug_robIdx_flag  = s0_use_non_prf_flow & s0_uop.robIdx_flag;
    tlb_req.debug_robIdx_value = s0_use_non_prf_flow ? s0_uop.robIdx_value : 8'h0;
    tlb_req.debug_isFirstIssue = s0_isFirstIssue;
  end
  assign tlb_req_valid    = s0_valid;
  assign dcache_req_valid = s0_fire;     // DCache 写意图查询（只读 tag/meta，预热缺失）

  // ---- store 掩码提前一拍告诉 SQ ----
  assign st_mask_out_valid = s0_use_flow_rs | s0_use_flow_vec;
  always_comb begin
    st_mask_out             = '0;
    st_mask_out.mask        = s0_out.mask;
    st_mask_out.sqIdx_value = s0_out.uop.sqIdx_value;
  end

  assign stin_ready          = s1_ready & s0_use_flow_rs;
  assign vecstin_ready       = s1_ready & s0_use_flow_vec;
  assign misalign_stin_ready = s1_ready & s0_use_flow_ma;

  // ===================================================================
  // s1：TLB 应答 → 物理地址与页异常；调试触发器；写 SQ；st-ld 违例查询；非对齐入缓冲
  // -------------------------------------------------------------------
  // 输入：s1_in（s0 的包）、tlb_resp、触发器配置（fromCsrTrigger）、redirect、misalign_enq_req_ready。
  // TLB miss：标量 store 直接在本级杀掉（s1_kill），靠 feedback_slow 让发射队列重发；
  //   向量 store 与非对齐缓冲的子访问不杀，带着 miss 标记走到 s2/s3 由各自的缓冲处理。
  // 写 SQ（lsq）：不管 miss 与否都写一次（miss 位告诉 SQ 地址还无效）。updateAddrValid 表示
  //   "这次写完地址就算就绪"：跨 16B 的非对齐 store 要等最后一个拆分（isFinalSplit）才就绪；有异常则立即就绪。
  // 非对齐入缓冲：跨 16B 的非对齐 store（且 CSR 开了硬件非对齐支持）在本级向缓冲请求入队；
  //   s0 判定还不能进的（s1_misalignNeedReplay）不请求，s2 让发射队列重发。
  // ===================================================================
  logic s1_valid;
  logic s1_kill, s1_fire;
  logic s1_vecActive;             // s0_out.vecActive 的独立副本（复位值 1）
  logic s1_isCbo;
  logic s1_isvec;                 // s0_out.isvec 的独立副本（带复位）
  logic s1_misalignNeedReplay;
  logic s1_frm_mab_vec;           // 来自非对齐缓冲、且原指令是向量 store（只用来给 SQ 打 isvec 标记）
  logic s1_frm_mabuf;
  assign s1_frm_mabuf = s1_in.isFrmMisAlignBuf;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_valid              <= 1'b0;
      s1_vecActive          <= 1'b1;
      s1_isvec              <= 1'b0;
      s1_misalignNeedReplay <= 1'b0;
      s1_frm_mab_vec        <= 1'b0;
    end else begin
      if      (s0_fire) s1_valid <= 1'b1;
      else if (s1_fire) s1_valid <= 1'b0;
      else if (s1_kill) s1_valid <= 1'b0;
      if (s0_fire) begin
        s1_vecActive          <= s0_out.vecActive;
        s1_isvec              <= s0_out.isvec;
        s1_misalignNeedReplay <= s0_misalignNeedReplay;
        s1_frm_mab_vec        <= s0_use_flow_ma & misalign_stin.isvec;
      end
    end
  end
  always_ff @(posedge clock) begin
    if (s0_fire) s1_isCbo <= s0_isCbo;
  end

  // ---- TLB 应答 ----
  logic              s1_tlb_miss, s1_tlb_hit;
  logic [1:0]        s1_pbmt;
  logic [XLEN-1:0]   s1_fullva;
  logic              s1_redirect_flush;
  assign s1_tlb_miss = tlb_resp.miss  & tlb_resp_valid & s1_valid;
  assign s1_tlb_hit  = ~tlb_resp.miss & tlb_resp_valid & s1_valid;
  assign s1_pbmt     = s1_tlb_hit ? tlb_resp.pbmt_0 : PBMT_PMA;
  // 非对齐缓冲的子访问没让 TLB 查 fullva，用自己的虚地址
  assign s1_fullva   = s1_frm_mabuf ? XLEN'(s1_in.vaddr) : tlb_resp.fullva;

  assign s1_redirect_flush = rob_need_flush(s1_in.uop.robIdx_flag, s1_in.uop.robIdx_value, redirect_valid,
                                            redirect.level, redirect.robIdx_flag, redirect.robIdx_value);
  assign s1_kill  = s1_redirect_flush | (s1_tlb_miss & ~s1_isvec & ~s1_frm_mabuf);
  assign s1_fire  = s1_valid & ~s1_kill & s2_ready;
  assign s1_ready = ~s1_valid | s1_kill | s2_ready;

  // ---- 调试触发器（MemTrigger_3：纯组合，按 s1 的完整虚地址匹配）----
  logic [3:0]         s1_trigger_action;
  logic [VADDR_W-1:0] s1_trigger_vaddr;
  logic               s1_trigger_debug_mode, s1_trigger_breakpoint;
  // BEGIN GENERATED(trigger) —— scripts/gen_storeunit.py 生成，勿手改
  MemTrigger_3 storeTrigger (
    .tdataVec_io_fromCsrTrigger_tdataVec_0_matchType      (fromCsrTrigger_tdataVec_0_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_select         (fromCsrTrigger_tdataVec_0_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_timing         (fromCsrTrigger_tdataVec_0_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_action         (fromCsrTrigger_tdataVec_0_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_chain          (fromCsrTrigger_tdataVec_0_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_store          (fromCsrTrigger_tdataVec_0_store),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_tdata2         (fromCsrTrigger_tdataVec_0_tdata2),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_matchType      (fromCsrTrigger_tdataVec_1_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_select         (fromCsrTrigger_tdataVec_1_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_timing         (fromCsrTrigger_tdataVec_1_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_action         (fromCsrTrigger_tdataVec_1_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_chain          (fromCsrTrigger_tdataVec_1_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_store          (fromCsrTrigger_tdataVec_1_store),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_tdata2         (fromCsrTrigger_tdataVec_1_tdata2),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_matchType      (fromCsrTrigger_tdataVec_2_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_select         (fromCsrTrigger_tdataVec_2_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_timing         (fromCsrTrigger_tdataVec_2_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_action         (fromCsrTrigger_tdataVec_2_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_chain          (fromCsrTrigger_tdataVec_2_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_store          (fromCsrTrigger_tdataVec_2_store),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_tdata2         (fromCsrTrigger_tdataVec_2_tdata2),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_matchType      (fromCsrTrigger_tdataVec_3_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_select         (fromCsrTrigger_tdataVec_3_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_timing         (fromCsrTrigger_tdataVec_3_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_action         (fromCsrTrigger_tdataVec_3_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_chain          (fromCsrTrigger_tdataVec_3_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_store          (fromCsrTrigger_tdataVec_3_store),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_tdata2         (fromCsrTrigger_tdataVec_3_tdata2),
    .tdataVec_io_fromCsrTrigger_tEnableVec_0              (fromCsrTrigger_tEnableVec_0),
    .tdataVec_io_fromCsrTrigger_tEnableVec_1              (fromCsrTrigger_tEnableVec_1),
    .tdataVec_io_fromCsrTrigger_tEnableVec_2              (fromCsrTrigger_tEnableVec_2),
    .tdataVec_io_fromCsrTrigger_tEnableVec_3              (fromCsrTrigger_tEnableVec_3),
    .tdataVec_io_fromCsrTrigger_debugMode                 (fromCsrTrigger_debugMode),
    .tdataVec_io_fromCsrTrigger_triggerCanRaiseBpExp      (fromCsrTrigger_triggerCanRaiseBpExp),
    .tdataVec_io_fromLoadStore_vaddr                      (s1_fullva[VADDR_W-1:0]),
    .tdataVec_io_fromLoadStore_isVectorUnitStride         (s1_in.isvec & s1_in.is128bit),
    .tdataVec_io_fromLoadStore_mask                       (s1_in.mask),
    .tdataVec_io_toLoadStore_triggerAction                (s1_trigger_action),
    .tdataVec_io_toLoadStore_triggerVaddr                 (s1_trigger_vaddr),
    .tdataVec_io_isCbo                                    (s1_isCbo)
  );
  // END GENERATED(trigger)
  assign s1_trigger_debug_mode = (s1_trigger_action == TRIG_ACT_DEBUG_MODE);
  assign s1_trigger_breakpoint = (s1_trigger_action == TRIG_ACT_BREAKPOINT);

  // ---- 调试计时器（另一个 GTimer 副本）----
  logic [63:0] s1_out_uop_debugInfo_tlbRespTime_c;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) s1_out_uop_debugInfo_tlbRespTime_c <= 64'h0;
    else       s1_out_uop_debugInfo_tlbRespTime_c <= s1_out_uop_debugInfo_tlbRespTime_c + 64'h1;
  end

  // ---- 交给 s2 的包 ----
  always_comb begin
    s1_out                   = s1_in;
    s1_out.paddr             = tlb_resp.paddr_0;
    s1_out.gpaddr            = tlb_resp.gpaddr_0;
    s1_out.fullva            = s1_fullva;
    s1_out.vaNeedExt         = tlb_resp.excp_0_vaNeedExt;
    s1_out.isHyper           = tlb_resp.excp_0_isHyper;
    s1_out.nc                = (s1_pbmt == PBMT_NC);
    s1_out.mmio              = (s1_pbmt == PBMT_IO);
    s1_out.isForVSnonLeafPTE = tlb_resp.isForVSnonLeafPTE;
    // 页异常（cbo.clean 等用读权限查，所以 ld/st 两种都收）；被 mask 掉的向量元素不报
    s1_out.uop.exceptionVec[EXC_ST_PAGE_FAULT]    = (tlb_resp.excp_0_pf_st  | tlb_resp.excp_0_pf_ld)  & s1_vecActive;
    s1_out.uop.exceptionVec[EXC_ST_ACCESS_FAULT]  = (tlb_resp.excp_0_af_st  | tlb_resp.excp_0_af_ld)  & s1_vecActive;
    s1_out.uop.exceptionVec[EXC_ST_GUEST_PF]      = (tlb_resp.excp_0_gpf_st | tlb_resp.excp_0_gpf_ld) & s1_vecActive;
    s1_out.uop.trigger                            = s1_trigger_action;
    s1_out.uop.exceptionVec[EXC_BREAKPOINT]       = s1_trigger_breakpoint;
    // 非对齐访问落在 Svpbmt=IO 的页上：报非对齐异常（MMIO 不支持拆分）
    s1_out.uop.exceptionVec[EXC_ST_ADDR_MISALIGN] = s1_out.mmio & s1_in.isMisalign;
    // 向量异常要回报"出错元素相对基址的偏移"（s2 换算成 vstart）：
    // 触发器命中时用触发地址，否则用本次访问第一个有效字节的地址
    s1_out.vecVaddrOffset = (s1_trigger_debug_mode | s1_trigger_breakpoint)
                          ? s1_trigger_vaddr - s1_in.vecBaseVaddr
                          : s1_in.vaddr + VADDR_W'(first_set_byte(s1_in.mask)) - s1_in.vecBaseVaddr;
    if (tlb_resp_valid & ~s1_tlb_miss & (tlb_resp.memidx_idx == 7'(s1_in.uop.sqIdx_value)))
      s1_out.uop.debugInfo_tlbRespTime = s1_out_uop_debugInfo_tlbRespTime_c;
  end

  logic s1_exception;    // 本级已知的 sta 类异常（任一）
  assign s1_exception = |(s1_out.uop.exceptionVec & STA_EXC_MASK);

  // ---- 写 store queue ----
  assign lsq_valid = s1_valid;
  always_comb begin
    lsq                 = s1_out;
    lsq.miss            = s1_tlb_miss;
    lsq.isvec           = s1_out.isvec | s1_frm_mab_vec;
    lsq.updateAddrValid = (~s1_in.isMisalign | s1_in.misalignWith16Byte) & (~s1_frm_mabuf | s1_in.isFinalSplit)
                        | s1_exception;
    lsq.isMisalign      = s1_out.isMisalign & ~s1_misalignNeedReplay;
  end

  // ---- st-ld 违例查询：让 load 流水 / RAW 队列查有没有比本 store 年轻、地址重叠且已执行的 load ----
  assign stld_nuke_query_valid = s1_valid & ~s1_tlb_miss;
  always_comb begin
    stld_nuke_query              = '0;
    stld_nuke_query.robIdx_flag  = s1_in.uop.robIdx_flag;
    stld_nuke_query.robIdx_value = s1_in.uop.robIdx_value;
    stld_nuke_query.paddr        = tlb_resp.paddr_0;
    stld_nuke_query.mask         = s1_in.mask;
    stld_nuke_query.matchType    = s1_isCbo        ? NUKE_MATCH_CACHELINE
                                 : s1_in.is128bit  ? NUKE_MATCH_QUADWORD
                                 :                   NUKE_MATCH_NORMAL;
  end

  // ---- 通知发射队列"这条 sta 已成功发出"（只对标量首发；bits 是 s0 选中的标量包打一拍）----
  logic       io_issue_bits_r_uop_robIdx_flag;
  logic [7:0] io_issue_bits_r_uop_robIdx_value;
  always_ff @(posedge clock) begin
    if (s0_valid) begin
      io_issue_bits_r_uop_robIdx_flag  <= s0_stin.uop.robIdx_flag;
      io_issue_bits_r_uop_robIdx_value <= s0_stin.uop.robIdx_value;
    end
  end
  assign issue_valid = s1_valid & ~s1_tlb_miss & ~s1_isvec & ~s1_frm_mabuf;
  always_comb begin
    issue                  = '0;
    issue.uop.robIdx_flag  = io_issue_bits_r_uop_robIdx_flag;
    issue.uop.robIdx_value = io_issue_bits_r_uop_robIdx_value;
  end

  // ---- TLB 命中与否的反馈（本级生成，s2 送出）----
  feedback_t s1_feedback;
  logic      s1_feedback_valid;
  assign s1_feedback_valid = s1_valid;
  always_comb begin
    s1_feedback              = '0;
    s1_feedback.hit          = ~s1_tlb_miss;
    s1_feedback.flushState   = tlb_resp.ptwBack;
    s1_feedback.robIdx_flag  = s1_out.uop.robIdx_flag;
    s1_feedback.robIdx_value = s1_out.uop.robIdx_value;
    s1_feedback.sqIdx_flag   = s1_out.uop.sqIdx_flag;
    s1_feedback.sqIdx_value  = s1_out.uop.sqIdx_value;
    s1_feedback.lqIdx_flag   = s1_out.uop.lqIdx_flag;
    s1_feedback.lqIdx_value  = s1_out.uop.lqIdx_value;
  end

  // ---- 非对齐 store 入缓冲 ----
  // CSR 开关各打一拍（golden 是两个独立的 GatedValidRegNext，照写两份）
  logic s1_mis_align_last_REG, s1_toMisalignBufferValid_last_REG;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_mis_align_last_REG             <= 1'b0;
      s1_toMisalignBufferValid_last_REG <= 1'b0;
    end else begin
      s1_mis_align_last_REG             <= csrCtrl_hd_misalign_st_enable;
      s1_toMisalignBufferValid_last_REG <= csrCtrl_hd_misalign_st_enable;
    end
  end

  logic s1_mis_align;               // 本条是"要交给非对齐缓冲处理"的 store（s2/s3 据此不写回）
  logic s1_toMisalignBufferValid;   // 本级想向缓冲入队
  assign s1_mis_align = s1_valid & ~s1_tlb_miss & ~s1_isCbo & ~s1_out.nc & ~s1_out.mmio
                      & s1_mis_align_last_REG & s1_in.isMisalign & ~s1_in.misalignWith16Byte
                      & ~s1_trigger_breakpoint & ~s1_trigger_debug_mode;
  assign s1_toMisalignBufferValid = s1_valid & ~s1_frm_mabuf & ~s1_isCbo & s1_in.isMisalign
                                  & ~s1_in.misalignWith16Byte & s1_toMisalignBufferValid_last_REG;
  assign misalign_enq_req_valid = s1_toMisalignBufferValid & ~s1_misalignNeedReplay;
  assign misalign_enq_req       = s1_in;

  // ===================================================================
  // s2：PMP 应答 → 访问异常与 MMIO/NC 判定；补写 SQ；回发射队列反馈；非对齐子访问回缓冲
  // -------------------------------------------------------------------
  // 输入：s2_in（s1 的包）、pmp（按 s1 的物理地址查出的权限 / 是否 MMIO 区）、redirect。
  // PMP/PMA 的结果只有在地址翻译没出异常时才可信（否则物理地址本身是垃圾），
  //   所以"实际落在不可缓存空间"的几个判定都先排除 s2_un_access_exception。
  // MMIO store（且无异常）在本级结束（s2_kill）：它不走写回，等 ROB 提交到它时由 SQ 发起 uncache 写。
  // 访问异常（storeAccessFault）的来源：TLB 的 af、PMP 不可写、cbo.clean 等要读权限而 PMP 不可读、
  //   向量 store 落在不可缓存空间、非对齐 store 落在 MMIO、cbo 落在 MMIO。
  // 非对齐异常：非对齐的标量 store 落在 Svpbmt=NC 的页上（且没有更高优先级的异常）。
  // ===================================================================
  logic       s2_valid;
  logic       s2_kill, s2_fire;
  logic       s2_vecActive;                  // 复位值 1
  logic       s2_frm_mab_vec;                // 复位值 1（golden 如此）
  logic [1:0] s2_pbmt;
  logic       s2_trigger_debug_mode;
  logic       s2_tlb_hit;
  logic       s2_isCbo;                      // 含 cbo.zero
  logic       s2_mis_align_r;
  logic       s2_misalignNeedReplay;         // 非对齐缓冲没收下（满了，或 s0 就判定不能进）→ 要重发
  logic       s2_misalign_stout_bits_need_rep_r;
  // s1 的 TLB 命中位各打一拍：golden 是三个同源的 RegNext，照写三份
  logic       s2_exception_REG, s2_un_misalign_exception_REG, s2_mmio_REG;
  logic       io_misalign_enq_revoke_REG;    // s1 TLB miss 打一拍
  logic       s2_frm_mabuf;
  assign s2_frm_mabuf = s2_in.isFrmMisAlignBuf;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s2_valid              <= 1'b0;
      s2_vecActive          <= 1'b1;
      s2_frm_mab_vec        <= 1'b1;
      s2_trigger_debug_mode <= 1'b0;
      s2_misalignNeedReplay <= 1'b0;
    end else begin
      if      (s1_fire) s2_valid <= 1'b1;
      else if (s2_fire) s2_valid <= 1'b0;
      else if (s2_kill) s2_valid <= 1'b0;
      if (s1_fire) begin
        s2_vecActive          <= s1_out.vecActive;
        s2_frm_mab_vec        <= s1_frm_mab_vec;
        s2_trigger_debug_mode <= s1_trigger_debug_mode;
        s2_misalignNeedReplay <= s1_toMisalignBufferValid & (~misalign_enq_req_ready | s1_misalignNeedReplay);
      end
    end
  end
  always_ff @(posedge clock) begin
    if (s1_fire) begin
      s2_pbmt                           <= s1_pbmt;
      s2_tlb_hit                        <= s1_tlb_hit;
      s2_isCbo                          <= s1_isCbo;
      s2_mis_align_r                    <= s1_mis_align;
      s2_misalign_stout_bits_need_rep_r <= s1_tlb_miss;
    end
    s2_exception_REG             <= s1_feedback.hit;
    s2_un_misalign_exception_REG <= s1_feedback.hit;
    s2_mmio_REG                  <= s1_feedback.hit;
    io_misalign_enq_revoke_REG   <= s1_tlb_miss;
  end

  // ---- 不可缓存空间判定 ----
  logic s2_isCbo_noZero;
  logic s2_un_access_exception;      // 翻译阶段已有访问类异常 → PMP 结果不可信
  logic s2_pma_mmio;                 // 页表没指定属性（PMA），PMP 说是 MMIO 且可写
  logic s2_actually_uncache;         // 真落在不可缓存空间（MMIO 或 NC）
  logic s2_actually_mmio;            // 靠 PMA 判定的 MMIO
  logic s2_actually_all_mmio;        // MMIO（PMA 判定或 Svpbmt=IO）
  logic s2_actually_pbmt_nc;         // Svpbmt=NC
  logic s2_mmio;
  assign s2_isCbo_noZero        = is_cbo(s2_in.uop.fuOpType);
  assign s2_un_access_exception = s2_vecActive & (s2_in.uop.exceptionVec[EXC_ST_ACCESS_FAULT]
                                                | s2_in.uop.exceptionVec[EXC_ST_PAGE_FAULT]
                                                | s2_in.uop.exceptionVec[EXC_ST_GUEST_PF]);
  assign s2_pma_mmio          = (s2_pbmt == PBMT_PMA) & ~pmp.st & pmp.mmio;
  assign s2_actually_uncache  = s2_tlb_hit & ~s2_un_access_exception & (s2_pma_mmio | s2_in.nc | s2_in.mmio);
  assign s2_actually_mmio     = s2_tlb_hit & ~s2_un_access_exception & s2_pma_mmio;
  assign s2_actually_all_mmio = s2_tlb_hit & ~s2_un_access_exception & (s2_pma_mmio | s2_in.mmio);
  assign s2_actually_pbmt_nc  = s2_tlb_hit & ~s2_un_access_exception & s2_in.nc;
  assign s2_mmio = (s2_in.mmio | (s2_pbmt == PBMT_PMA) & pmp.mmio) & s2_mmio_REG;

  // ---- 本级更新的异常位 ----
  logic        s2_access_fault;               // 新的 storeAccessFault
  logic        s2_un_misalign_exception;      // 有除"非对齐"以外的异常（或进 debug mode）
  logic        s2_addr_misaligned;            // 新的 storeAddrMisaligned
  logic [23:0] s2_exceptionVec;               // s2_out.uop.exceptionVec
  logic        s2_exception;                  // 本条 store 最终带异常（或触发进 debug mode）

  assign s2_access_fault = (s2_in.uop.exceptionVec[EXC_ST_ACCESS_FAULT]
                           | pmp.st
                           | pmp.ld & s2_isCbo_noZero            // cbo.clean 等要读权限，但报 store 异常
                           | s2_in.isvec & s2_actually_uncache
                           | s2_actually_all_mmio & (s2_in.isMisalign | s2_in.isFrmMisAlignBuf)
                           | s2_actually_mmio & s2_isCbo) & s2_vecActive;
  always_comb begin
    logic [23:0] vec_without_misalign;
    vec_without_misalign                       = s2_in.uop.exceptionVec;
    vec_without_misalign[EXC_ST_ACCESS_FAULT]  = s2_access_fault;
    vec_without_misalign[EXC_ST_ADDR_MISALIGN] = 1'b0;
    s2_un_misalign_exception = s2_un_misalign_exception_REG
                             & (s2_trigger_debug_mode | (|(vec_without_misalign & STA_EXC_MASK)));
    s2_addr_misaligned = s2_actually_pbmt_nc & ~s2_in.isvec & (s2_in.isMisalign | s2_in.isFrmMisAlignBuf)
                       & ~s2_un_misalign_exception;

    s2_exceptionVec                       = s2_in.uop.exceptionVec;
    s2_exceptionVec[EXC_ST_ACCESS_FAULT]  = s2_access_fault;
    s2_exceptionVec[EXC_ST_ADDR_MISALIGN] = s2_addr_misaligned;
  end
  assign s2_exception = s2_exception_REG & (s2_trigger_debug_mode | (|(s2_exceptionVec & STA_EXC_MASK)))
                      & s2_vecActive;

  logic s2_redirect_flush;
  assign s2_redirect_flush = rob_need_flush(s2_in.uop.robIdx_flag, s2_in.uop.robIdx_value, redirect_valid,
                                            redirect.level, redirect.robIdx_flag, redirect.robIdx_value);
  assign s2_kill  = (s2_mmio & ~s2_exception) & ~s2_in.isvec & ~s2_frm_mabuf | s2_redirect_flush;
  assign s2_fire  = s2_valid & ~s2_kill & s3_ready;
  assign s2_ready = ~s2_valid | s2_kill | s3_ready;

  // ---- 交给 s3 的包 ----
  always_comb begin
    s2_out                 = s2_in;
    s2_out.uop.exceptionVec = s2_exceptionVec;
    s2_out.af              = s2_access_fault;
    s2_out.mmio            = s2_mmio & ~s2_exception;
    s2_out.memBackTypeMM   = ~pmp.mmio;
    // 向量异常的 vstart = 出错字节相对基址的偏移 / 元素字节数
    s2_out.uop.vpu_vstart  = 8'(s2_in.vecVaddrOffset >> s2_in.uop.vpu_veew);
  end

  // ---- 非对齐缓冲：撤销入队 / 重发 ----
  logic s2_mis_align;
  logic s2_misalignBufferNack;
  logic s2_misalign_cango;      // 非对齐 store 是否也要从本流水写回（只有带异常或要重发的才写回）
  assign s2_mis_align           = s2_valid & s2_mis_align_r;
  assign misalign_enq_revoke    = s2_exception | io_misalign_enq_revoke_REG;   // 有异常或上拍 TLB miss：缓冲里那项作废
  assign s2_misalignBufferNack  = ~misalign_enq_revoke & s2_misalignNeedReplay;
  assign s2_misalign_cango      = ~s2_mis_align
                                | s2_in.isvec  & (s2_misalignNeedReplay | s2_exception)
                                | ~s2_in.isvec & ~s2_misalignNeedReplay & s2_exception;

  // ---- 回发射队列的反馈（s1 生成的反馈打一拍；只对标量、非缓冲子访问）----
  logic      feedback_slow_valid_next;
  logic      io_feedback_slow_valid_last_REG;
  logic      io_feedback_slow_bits_hit_r;
  feedback_t feedback_slow_r;       // 见 GENERATED(pipe_regs)：golden 没给 hit 留在这一组里（单独一个寄存器）
  assign feedback_slow_valid_next = s1_feedback_valid & ~s1_redirect_flush & ~s1_out.isvec & ~s1_frm_mabuf;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) io_feedback_slow_valid_last_REG <= 1'b0;
    else       io_feedback_slow_valid_last_REG <= feedback_slow_valid_next;
  end
  always_ff @(posedge clock) begin
    if (feedback_slow_valid_next) io_feedback_slow_bits_hit_r <= s1_feedback.hit;
  end
  assign feedback_slow_valid = io_feedback_slow_valid_last_REG;
  always_comb begin
    feedback_slow     = feedback_slow_r;
    // 非对齐缓冲没收下 → 当作没命中，让发射队列重发
    feedback_slow.hit = io_feedback_slow_bits_hit_r & ~s2_misalignNeedReplay;
  end

  // ---- 向量 store 的"成功"反馈（随写回送给向量合并缓冲）----
  logic s2_vecFeedback_REG;
  logic s2_vecFeedback;
  always_ff @(posedge clock) begin
    s2_vecFeedback_REG <= ~s1_redirect_flush & s1_feedback.hit & s1_feedback_valid;
  end
  assign s2_vecFeedback = s2_vecFeedback_REG & ~s2_misalignBufferNack & s2_in.isvec & ~s2_frm_mabuf;

  // ---- 非对齐缓冲的子访问：结果回给缓冲 ----
  assign misalign_stout_valid = s2_valid & s3_ready & s2_frm_mabuf;
  always_comb begin
    misalign_stout          = s2_out;
    misalign_stout.need_rep = s2_misalign_stout_bits_need_rep_r;    // 子访问 TLB miss：缓冲稍后重发
  end

  // ---- 补写 store queue：异常、MMIO 属性 ----
  always_comb begin
    lsq_replenish                 = s2_out;
    lsq_replenish.af              = s2_out.af & s2_valid & ~s2_kill;
    lsq_replenish.mmio            = (s2_mmio | s2_isCbo_noZero) & ~s2_exception;   // cbo 借用 SQ 的 mmio 等待逻辑
    lsq_replenish.updateAddrValid = ~s2_mis_align & (~s2_frm_mabuf | s2_out.isFinalSplit)
                                  | ~s2_in.isvec & s2_exception & ~s2_misalignNeedReplay
                                  | s2_in.isvec & s2_exception;
    lsq_replenish.isvec           = s2_out.isvec | s2_frm_mab_vec;
    lsq_replenish.hasException    = ((|(s2_out.uop.exceptionVec & STA_EXC_MASK))
                                     | (s2_out.uop.trigger == TRIG_ACT_DEBUG_MODE)
                                     | s2_out.af) & s2_valid & ~s2_kill;
  end

  // ===================================================================
  // s3 + sx：写回
  // -------------------------------------------------------------------
  // s3_valid：MMIO / cbo（无异常时）不从这里写回（由 SQ 在提交时处理）；交给非对齐缓冲的 store、
  //   缓冲的子访问也不写回（由缓冲写回）。
  // sx：写回再延 RAWTotalDelayCycles=1 拍（sx_in_1），等 load 侧的 st-ld 违例检查结果先到 ROB。
  //   sx_in_0 = s3 的结果；sx_in_1 = 打一拍后的结果（寄存器组 sx_in_1_r，见 GENERATED(pipe_regs)）。
  // 标量 store 走 stout，向量 store 走 vecstout（带给向量合并缓冲的元素信息）。
  // ===================================================================
  logic s3_valid;
  logic s3_kill, s3_fire;
  logic s3_vecFeedback, s3_exception;

  assign s3_kill = rob_need_flush(s3_in.uop.robIdx_flag, s3_in.uop.robIdx_value, redirect_valid,
                                  redirect.level, redirect.robIdx_flag, redirect.robIdx_value);
  assign s3_fire = s3_valid & ~s3_kill & s3_ready;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s3_valid <= 1'b0;
    end else begin
      if      (s2_fire) s3_valid <= (~s2_mmio & ~s2_isCbo | s2_exception) & s2_misalign_cango & ~s2_frm_mabuf;
      else if (s3_fire) s3_valid <= 1'b0;
      else if (s3_kill) s3_valid <= 1'b0;
    end
  end
  always_ff @(posedge clock) begin
    if (s2_fire) begin
      s3_vecFeedback <= s2_vecFeedback;
      s3_exception   <= s2_exception;
    end
  end

  sx_t  sx_in_0, sx_in_1;
  logic sx_valid_1_r;          // sx_valid(1)
  logic sx_in_vec_1_r;         // sx_in_vec(1)：这条写回是向量 store
  logic sx_ready_0, sx_ready_1;
  logic sx_cur_kill, sx_cur_fire, sx_prev_fire;

  always_comb begin
    sx_in_0                     = '0;
    sx_in_0.out.uop          = s3_in.uop;
    sx_in_0.out.debug_isMMIO = s3_in.mmio;
    sx_in_0.out.debug_isNCIO = s3_in.nc & ~s3_in.memBackTypeMM;
    sx_in_0.out.debug_paddr  = s3_in.paddr;
    sx_in_0.out.debug_vaddr  = s3_in.vaddr;
    sx_in_0.vecFeedback         = s3_vecFeedback;
    sx_in_0.hasException        = s3_exception;
    sx_in_0.elemIdx             = s3_in.elemIdx;
    sx_in_0.mbIndex             = s3_in.mbIndex;
    sx_in_0.mask                = s3_in.mask;
    sx_in_0.vaddr               = s3_in.fullva;
    sx_in_0.vaNeedExt           = s3_in.vaNeedExt;
    sx_in_0.gpaddr              = s3_in.gpaddr;
    sx_in_0.isForVSnonLeafPTE   = s3_in.isForVSnonLeafPTE;
    sx_in_0.splitIndx           = s3_in.splitIndex;
  end

  assign sx_cur_kill  = rob_need_flush(sx_in_1.out.uop.robIdx_flag, sx_in_1.out.uop.robIdx_value,
                                       redirect_valid, redirect.level, redirect.robIdx_flag, redirect.robIdx_value);
  assign sx_ready_1   = ~sx_valid_1_r | sx_cur_kill | STOUT_READY;
  assign sx_ready_0   = ~s3_valid | s3_kill | sx_ready_1;
  assign s3_ready     = sx_ready_0;
  assign sx_cur_fire  = sx_valid_1_r & ~sx_cur_kill & STOUT_READY;
  assign sx_prev_fire = s3_valid & ~s3_kill & sx_ready_1;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      sx_valid_1_r <= 1'b0;
    else if (sx_prev_fire | sx_cur_fire | sx_cur_kill)
      sx_valid_1_r <= sx_prev_fire;
  end
  always_ff @(posedge clock) begin
    if (sx_prev_fire) sx_in_vec_1_r <= s3_in.isvec;
  end

  // ---- 标量写回 ----
  assign stout_valid = sx_valid_1_r & ~sx_in_vec_1_r;
  always_comb begin
    stout                  = sx_in_1.out;
    stout.uop.exceptionVec = sx_in_1.out.uop.exceptionVec & STA_EXC_MASK;
  end

  // ---- 向量写回（给 VSMergeBuffer）----
  assign vecstout_valid = sx_valid_1_r & sx_in_vec_1_r;
  always_comb begin
    vecstout                   = '0;
    vecstout.mBIndex           = sx_in_1.mbIndex;
    vecstout.hit               = sx_in_1.vecFeedback;
    vecstout.trigger           = sx_in_1.out.uop.trigger;
    vecstout.exceptionVec      = sx_in_1.out.uop.exceptionVec & STA_EXC_MASK;
    vecstout.hasException      = sx_in_1.hasException;
    vecstout.elemIdx           = sx_in_1.elemIdx;
    vecstout.mask              = sx_in_1.mask;
    vecstout.vaddr             = sx_in_1.vaddr;
    vecstout.vaNeedExt         = sx_in_1.vaNeedExt;
    vecstout.gpaddr            = sx_in_1.gpaddr;
    vecstout.isForVSnonLeafPTE = sx_in_1.isForVSnonLeafPTE;
    vecstout.vstart            = sx_in_1.out.uop.vpu_vstart;
    vecstout.splitIndex        = sx_in_1.splitIndx;
  end

  // ===================================================================
  // 整包打拍寄存器（生成）：字段集合 = golden 的寄存器表；装载源 / 使能见每组开头
  // ===================================================================
  // BEGIN GENERATED(pipe_regs) —— scripts/gen_storeunit.py 生成，勿手改
  // ---- s1_in <= s0_out（s0_fire 时整包打拍，无复位）：golden 留下的 65 个字段 ----
  logic          s1_in_uop_exceptionVec_0;
  logic          s1_in_uop_exceptionVec_1;
  logic          s1_in_uop_exceptionVec_2;
  logic          s1_in_uop_exceptionVec_4;
  logic          s1_in_uop_exceptionVec_5;
  logic          s1_in_uop_exceptionVec_8;
  logic          s1_in_uop_exceptionVec_9;
  logic          s1_in_uop_exceptionVec_10;
  logic          s1_in_uop_exceptionVec_11;
  logic          s1_in_uop_exceptionVec_12;
  logic          s1_in_uop_exceptionVec_13;
  logic          s1_in_uop_exceptionVec_14;
  logic          s1_in_uop_exceptionVec_16;
  logic          s1_in_uop_exceptionVec_17;
  logic          s1_in_uop_exceptionVec_18;
  logic          s1_in_uop_exceptionVec_19;
  logic          s1_in_uop_exceptionVec_20;
  logic          s1_in_uop_exceptionVec_21;
  logic          s1_in_uop_exceptionVec_22;
  logic [3:0]    s1_in_uop_trigger;
  logic          s1_in_uop_ftqPtr_flag;
  logic [5:0]    s1_in_uop_ftqPtr_value;
  logic [3:0]    s1_in_uop_ftqOffset;
  logic [34:0]   s1_in_uop_fuType;
  logic [8:0]    s1_in_uop_fuOpType;
  logic          s1_in_uop_rfWen;
  logic [7:0]    s1_in_uop_vpu_vstart;
  logic [2:0]    s1_in_uop_vpu_nf;
  logic [1:0]    s1_in_uop_vpu_veew;
  logic [6:0]    s1_in_uop_uopIdx;
  logic [7:0]    s1_in_uop_pdest;
  logic          s1_in_uop_robIdx_flag;
  logic [7:0]    s1_in_uop_robIdx_value;
  logic          s1_in_uop_debugInfo_eliminatedMove;
  logic [63:0]   s1_in_uop_debugInfo_renameTime;
  logic [63:0]   s1_in_uop_debugInfo_dispatchTime;
  logic [63:0]   s1_in_uop_debugInfo_enqRsTime;
  logic [63:0]   s1_in_uop_debugInfo_selectTime;
  logic [63:0]   s1_in_uop_debugInfo_issueTime;
  logic [63:0]   s1_in_uop_debugInfo_writebackTime;
  logic [63:0]   s1_in_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   s1_in_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   s1_in_uop_debugInfo_tlbRespTime;
  logic [55:0]   s1_in_uop_debug_seqNum_seqNum;
  logic [7:0]    s1_in_uop_debug_seqNum_uopIdx;
  logic          s1_in_uop_lqIdx_flag;
  logic [6:0]    s1_in_uop_lqIdx_value;
  logic          s1_in_uop_sqIdx_flag;
  logic [5:0]    s1_in_uop_sqIdx_value;
  logic [49:0]   s1_in_vaddr;
  logic [15:0]   s1_in_mask;
  logic          s1_in_wlineflag;
  logic          s1_in_isvec;
  logic          s1_in_is128bit;
  logic [7:0]    s1_in_elemIdx;
  logic [2:0]    s1_in_alignedType;
  logic [3:0]    s1_in_mbIndex;
  logic [49:0]   s1_in_vecBaseVaddr;
  logic [4:0]    s1_in_splitIndex;
  logic          s1_in_vecActive;
  logic          s1_in_isFirstIssue;
  logic          s1_in_isFrmMisAlignBuf;
  logic          s1_in_isMisalign;
  logic          s1_in_isFinalSplit;
  logic          s1_in_misalignWith16Byte;
  always_ff @(posedge clock) begin
    if (s0_fire) begin
      s1_in_uop_exceptionVec_0 <= s0_out.uop.exceptionVec[0];
      s1_in_uop_exceptionVec_1 <= s0_out.uop.exceptionVec[1];
      s1_in_uop_exceptionVec_2 <= s0_out.uop.exceptionVec[2];
      s1_in_uop_exceptionVec_4 <= s0_out.uop.exceptionVec[4];
      s1_in_uop_exceptionVec_5 <= s0_out.uop.exceptionVec[5];
      s1_in_uop_exceptionVec_8 <= s0_out.uop.exceptionVec[8];
      s1_in_uop_exceptionVec_9 <= s0_out.uop.exceptionVec[9];
      s1_in_uop_exceptionVec_10 <= s0_out.uop.exceptionVec[10];
      s1_in_uop_exceptionVec_11 <= s0_out.uop.exceptionVec[11];
      s1_in_uop_exceptionVec_12 <= s0_out.uop.exceptionVec[12];
      s1_in_uop_exceptionVec_13 <= s0_out.uop.exceptionVec[13];
      s1_in_uop_exceptionVec_14 <= s0_out.uop.exceptionVec[14];
      s1_in_uop_exceptionVec_16 <= s0_out.uop.exceptionVec[16];
      s1_in_uop_exceptionVec_17 <= s0_out.uop.exceptionVec[17];
      s1_in_uop_exceptionVec_18 <= s0_out.uop.exceptionVec[18];
      s1_in_uop_exceptionVec_19 <= s0_out.uop.exceptionVec[19];
      s1_in_uop_exceptionVec_20 <= s0_out.uop.exceptionVec[20];
      s1_in_uop_exceptionVec_21 <= s0_out.uop.exceptionVec[21];
      s1_in_uop_exceptionVec_22 <= s0_out.uop.exceptionVec[22];
      s1_in_uop_trigger <= s0_out.uop.trigger;
      s1_in_uop_ftqPtr_flag <= s0_out.uop.ftqPtr_flag;
      s1_in_uop_ftqPtr_value <= s0_out.uop.ftqPtr_value;
      s1_in_uop_ftqOffset <= s0_out.uop.ftqOffset;
      s1_in_uop_fuType <= s0_out.uop.fuType;
      s1_in_uop_fuOpType <= s0_out.uop.fuOpType;
      s1_in_uop_rfWen <= s0_out.uop.rfWen;
      s1_in_uop_vpu_vstart <= s0_out.uop.vpu_vstart;
      s1_in_uop_vpu_nf <= s0_out.uop.vpu_nf;
      s1_in_uop_vpu_veew <= s0_out.uop.vpu_veew;
      s1_in_uop_uopIdx <= s0_out.uop.uopIdx;
      s1_in_uop_pdest <= s0_out.uop.pdest;
      s1_in_uop_robIdx_flag <= s0_out.uop.robIdx_flag;
      s1_in_uop_robIdx_value <= s0_out.uop.robIdx_value;
      s1_in_uop_debugInfo_eliminatedMove <= s0_out.uop.debugInfo_eliminatedMove;
      s1_in_uop_debugInfo_renameTime <= s0_out.uop.debugInfo_renameTime;
      s1_in_uop_debugInfo_dispatchTime <= s0_out.uop.debugInfo_dispatchTime;
      s1_in_uop_debugInfo_enqRsTime <= s0_out.uop.debugInfo_enqRsTime;
      s1_in_uop_debugInfo_selectTime <= s0_out.uop.debugInfo_selectTime;
      s1_in_uop_debugInfo_issueTime <= s0_out.uop.debugInfo_issueTime;
      s1_in_uop_debugInfo_writebackTime <= s0_out.uop.debugInfo_writebackTime;
      s1_in_uop_debugInfo_runahead_checkpoint_id <= s0_out.uop.debugInfo_runahead_checkpoint_id;
      s1_in_uop_debugInfo_tlbFirstReqTime <= s0_out.uop.debugInfo_tlbFirstReqTime;
      s1_in_uop_debugInfo_tlbRespTime <= s0_out.uop.debugInfo_tlbRespTime;
      s1_in_uop_debug_seqNum_seqNum <= s0_out.uop.debug_seqNum_seqNum;
      s1_in_uop_debug_seqNum_uopIdx <= s0_out.uop.debug_seqNum_uopIdx;
      s1_in_uop_lqIdx_flag <= s0_out.uop.lqIdx_flag;
      s1_in_uop_lqIdx_value <= s0_out.uop.lqIdx_value;
      s1_in_uop_sqIdx_flag <= s0_out.uop.sqIdx_flag;
      s1_in_uop_sqIdx_value <= s0_out.uop.sqIdx_value;
      s1_in_vaddr <= s0_out.vaddr;
      s1_in_mask <= s0_out.mask;
      s1_in_wlineflag <= s0_out.wlineflag;
      s1_in_isvec <= s0_out.isvec;
      s1_in_is128bit <= s0_out.is128bit;
      s1_in_elemIdx <= s0_out.elemIdx;
      s1_in_alignedType <= s0_out.alignedType;
      s1_in_mbIndex <= s0_out.mbIndex;
      s1_in_vecBaseVaddr <= s0_out.vecBaseVaddr;
      s1_in_splitIndex <= s0_out.splitIndex;
      s1_in_vecActive <= s0_out.vecActive;
      s1_in_isFirstIssue <= s0_out.isFirstIssue;
      s1_in_isFrmMisAlignBuf <= s0_out.isFrmMisAlignBuf;
      s1_in_isMisalign <= s0_out.isMisalign;
      s1_in_isFinalSplit <= s0_out.isFinalSplit;
      s1_in_misalignWith16Byte <= s0_out.misalignWith16Byte;
    end
  end
  always_comb begin
    s1_in = '0;
    s1_in.uop.exceptionVec[0] = s1_in_uop_exceptionVec_0;
    s1_in.uop.exceptionVec[1] = s1_in_uop_exceptionVec_1;
    s1_in.uop.exceptionVec[2] = s1_in_uop_exceptionVec_2;
    s1_in.uop.exceptionVec[4] = s1_in_uop_exceptionVec_4;
    s1_in.uop.exceptionVec[5] = s1_in_uop_exceptionVec_5;
    s1_in.uop.exceptionVec[8] = s1_in_uop_exceptionVec_8;
    s1_in.uop.exceptionVec[9] = s1_in_uop_exceptionVec_9;
    s1_in.uop.exceptionVec[10] = s1_in_uop_exceptionVec_10;
    s1_in.uop.exceptionVec[11] = s1_in_uop_exceptionVec_11;
    s1_in.uop.exceptionVec[12] = s1_in_uop_exceptionVec_12;
    s1_in.uop.exceptionVec[13] = s1_in_uop_exceptionVec_13;
    s1_in.uop.exceptionVec[14] = s1_in_uop_exceptionVec_14;
    s1_in.uop.exceptionVec[16] = s1_in_uop_exceptionVec_16;
    s1_in.uop.exceptionVec[17] = s1_in_uop_exceptionVec_17;
    s1_in.uop.exceptionVec[18] = s1_in_uop_exceptionVec_18;
    s1_in.uop.exceptionVec[19] = s1_in_uop_exceptionVec_19;
    s1_in.uop.exceptionVec[20] = s1_in_uop_exceptionVec_20;
    s1_in.uop.exceptionVec[21] = s1_in_uop_exceptionVec_21;
    s1_in.uop.exceptionVec[22] = s1_in_uop_exceptionVec_22;
    s1_in.uop.trigger = s1_in_uop_trigger;
    s1_in.uop.ftqPtr_flag = s1_in_uop_ftqPtr_flag;
    s1_in.uop.ftqPtr_value = s1_in_uop_ftqPtr_value;
    s1_in.uop.ftqOffset = s1_in_uop_ftqOffset;
    s1_in.uop.fuType = s1_in_uop_fuType;
    s1_in.uop.fuOpType = s1_in_uop_fuOpType;
    s1_in.uop.rfWen = s1_in_uop_rfWen;
    s1_in.uop.vpu_vstart = s1_in_uop_vpu_vstart;
    s1_in.uop.vpu_nf = s1_in_uop_vpu_nf;
    s1_in.uop.vpu_veew = s1_in_uop_vpu_veew;
    s1_in.uop.uopIdx = s1_in_uop_uopIdx;
    s1_in.uop.pdest = s1_in_uop_pdest;
    s1_in.uop.robIdx_flag = s1_in_uop_robIdx_flag;
    s1_in.uop.robIdx_value = s1_in_uop_robIdx_value;
    s1_in.uop.debugInfo_eliminatedMove = s1_in_uop_debugInfo_eliminatedMove;
    s1_in.uop.debugInfo_renameTime = s1_in_uop_debugInfo_renameTime;
    s1_in.uop.debugInfo_dispatchTime = s1_in_uop_debugInfo_dispatchTime;
    s1_in.uop.debugInfo_enqRsTime = s1_in_uop_debugInfo_enqRsTime;
    s1_in.uop.debugInfo_selectTime = s1_in_uop_debugInfo_selectTime;
    s1_in.uop.debugInfo_issueTime = s1_in_uop_debugInfo_issueTime;
    s1_in.uop.debugInfo_writebackTime = s1_in_uop_debugInfo_writebackTime;
    s1_in.uop.debugInfo_runahead_checkpoint_id = s1_in_uop_debugInfo_runahead_checkpoint_id;
    s1_in.uop.debugInfo_tlbFirstReqTime = s1_in_uop_debugInfo_tlbFirstReqTime;
    s1_in.uop.debugInfo_tlbRespTime = s1_in_uop_debugInfo_tlbRespTime;
    s1_in.uop.debug_seqNum_seqNum = s1_in_uop_debug_seqNum_seqNum;
    s1_in.uop.debug_seqNum_uopIdx = s1_in_uop_debug_seqNum_uopIdx;
    s1_in.uop.lqIdx_flag = s1_in_uop_lqIdx_flag;
    s1_in.uop.lqIdx_value = s1_in_uop_lqIdx_value;
    s1_in.uop.sqIdx_flag = s1_in_uop_sqIdx_flag;
    s1_in.uop.sqIdx_value = s1_in_uop_sqIdx_value;
    s1_in.vaddr = s1_in_vaddr;
    s1_in.mask = s1_in_mask;
    s1_in.wlineflag = s1_in_wlineflag;
    s1_in.isvec = s1_in_isvec;
    s1_in.is128bit = s1_in_is128bit;
    s1_in.elemIdx = s1_in_elemIdx;
    s1_in.alignedType = s1_in_alignedType;
    s1_in.mbIndex = s1_in_mbIndex;
    s1_in.vecBaseVaddr = s1_in_vecBaseVaddr;
    s1_in.splitIndex = s1_in_splitIndex;
    s1_in.vecActive = s1_in_vecActive;
    s1_in.isFirstIssue = s1_in_isFirstIssue;
    s1_in.isFrmMisAlignBuf = s1_in_isFrmMisAlignBuf;
    s1_in.isMisalign = s1_in_isMisalign;
    s1_in.isFinalSplit = s1_in_isFinalSplit;
    s1_in.misalignWith16Byte = s1_in_misalignWith16Byte;
  end

  // ---- s2_in <= s1_out（s1_fire 时整包打拍，无复位）：golden 留下的 46 个字段 ----
  logic          s2_in_uop_exceptionVec_3;
  logic          s2_in_uop_exceptionVec_7;
  logic          s2_in_uop_exceptionVec_15;
  logic          s2_in_uop_exceptionVec_19;
  logic          s2_in_uop_exceptionVec_23;
  logic [3:0]    s2_in_uop_trigger;
  logic [8:0]    s2_in_uop_fuOpType;
  logic          s2_in_uop_rfWen;
  logic [1:0]    s2_in_uop_vpu_veew;
  logic [6:0]    s2_in_uop_uopIdx;
  logic [7:0]    s2_in_uop_pdest;
  logic          s2_in_uop_robIdx_flag;
  logic [7:0]    s2_in_uop_robIdx_value;
  logic          s2_in_uop_debugInfo_eliminatedMove;
  logic [63:0]   s2_in_uop_debugInfo_renameTime;
  logic [63:0]   s2_in_uop_debugInfo_dispatchTime;
  logic [63:0]   s2_in_uop_debugInfo_enqRsTime;
  logic [63:0]   s2_in_uop_debugInfo_selectTime;
  logic [63:0]   s2_in_uop_debugInfo_issueTime;
  logic [63:0]   s2_in_uop_debugInfo_writebackTime;
  logic [63:0]   s2_in_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   s2_in_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   s2_in_uop_debugInfo_tlbRespTime;
  logic [55:0]   s2_in_uop_debug_seqNum_seqNum;
  logic [7:0]    s2_in_uop_debug_seqNum_uopIdx;
  logic          s2_in_uop_sqIdx_flag;
  logic [5:0]    s2_in_uop_sqIdx_value;
  logic [49:0]   s2_in_vaddr;
  logic [63:0]   s2_in_fullva;
  logic          s2_in_vaNeedExt;
  logic [47:0]   s2_in_paddr;
  logic [63:0]   s2_in_gpaddr;
  logic [15:0]   s2_in_mask;
  logic          s2_in_nc;
  logic          s2_in_mmio;
  logic          s2_in_isHyper;
  logic          s2_in_isForVSnonLeafPTE;
  logic          s2_in_isvec;
  logic [7:0]    s2_in_elemIdx;
  logic [3:0]    s2_in_mbIndex;
  logic [49:0]   s2_in_vecVaddrOffset;
  logic [4:0]    s2_in_splitIndex;
  logic          s2_in_vecActive;
  logic          s2_in_isFrmMisAlignBuf;
  logic          s2_in_isMisalign;
  logic          s2_in_isFinalSplit;
  always_ff @(posedge clock) begin
    if (s1_fire) begin
      s2_in_uop_exceptionVec_3 <= s1_out.uop.exceptionVec[3];
      s2_in_uop_exceptionVec_7 <= s1_out.uop.exceptionVec[7];
      s2_in_uop_exceptionVec_15 <= s1_out.uop.exceptionVec[15];
      s2_in_uop_exceptionVec_19 <= s1_out.uop.exceptionVec[19];
      s2_in_uop_exceptionVec_23 <= s1_out.uop.exceptionVec[23];
      s2_in_uop_trigger <= s1_out.uop.trigger;
      s2_in_uop_fuOpType <= s1_out.uop.fuOpType;
      s2_in_uop_rfWen <= s1_out.uop.rfWen;
      s2_in_uop_vpu_veew <= s1_out.uop.vpu_veew;
      s2_in_uop_uopIdx <= s1_out.uop.uopIdx;
      s2_in_uop_pdest <= s1_out.uop.pdest;
      s2_in_uop_robIdx_flag <= s1_out.uop.robIdx_flag;
      s2_in_uop_robIdx_value <= s1_out.uop.robIdx_value;
      s2_in_uop_debugInfo_eliminatedMove <= s1_out.uop.debugInfo_eliminatedMove;
      s2_in_uop_debugInfo_renameTime <= s1_out.uop.debugInfo_renameTime;
      s2_in_uop_debugInfo_dispatchTime <= s1_out.uop.debugInfo_dispatchTime;
      s2_in_uop_debugInfo_enqRsTime <= s1_out.uop.debugInfo_enqRsTime;
      s2_in_uop_debugInfo_selectTime <= s1_out.uop.debugInfo_selectTime;
      s2_in_uop_debugInfo_issueTime <= s1_out.uop.debugInfo_issueTime;
      s2_in_uop_debugInfo_writebackTime <= s1_out.uop.debugInfo_writebackTime;
      s2_in_uop_debugInfo_runahead_checkpoint_id <= s1_out.uop.debugInfo_runahead_checkpoint_id;
      s2_in_uop_debugInfo_tlbFirstReqTime <= s1_out.uop.debugInfo_tlbFirstReqTime;
      s2_in_uop_debugInfo_tlbRespTime <= s1_out.uop.debugInfo_tlbRespTime;
      s2_in_uop_debug_seqNum_seqNum <= s1_out.uop.debug_seqNum_seqNum;
      s2_in_uop_debug_seqNum_uopIdx <= s1_out.uop.debug_seqNum_uopIdx;
      s2_in_uop_sqIdx_flag <= s1_out.uop.sqIdx_flag;
      s2_in_uop_sqIdx_value <= s1_out.uop.sqIdx_value;
      s2_in_vaddr <= s1_out.vaddr;
      s2_in_fullva <= s1_out.fullva;
      s2_in_vaNeedExt <= s1_out.vaNeedExt;
      s2_in_paddr <= s1_out.paddr;
      s2_in_gpaddr <= s1_out.gpaddr;
      s2_in_mask <= s1_out.mask;
      s2_in_nc <= s1_out.nc;
      s2_in_mmio <= s1_out.mmio;
      s2_in_isHyper <= s1_out.isHyper;
      s2_in_isForVSnonLeafPTE <= s1_out.isForVSnonLeafPTE;
      s2_in_isvec <= s1_out.isvec;
      s2_in_elemIdx <= s1_out.elemIdx;
      s2_in_mbIndex <= s1_out.mbIndex;
      s2_in_vecVaddrOffset <= s1_out.vecVaddrOffset;
      s2_in_splitIndex <= s1_out.splitIndex;
      s2_in_vecActive <= s1_out.vecActive;
      s2_in_isFrmMisAlignBuf <= s1_out.isFrmMisAlignBuf;
      s2_in_isMisalign <= s1_out.isMisalign;
      s2_in_isFinalSplit <= s1_out.isFinalSplit;
    end
  end
  always_comb begin
    s2_in = '0;
    s2_in.uop.exceptionVec[3] = s2_in_uop_exceptionVec_3;
    s2_in.uop.exceptionVec[7] = s2_in_uop_exceptionVec_7;
    s2_in.uop.exceptionVec[15] = s2_in_uop_exceptionVec_15;
    s2_in.uop.exceptionVec[19] = s2_in_uop_exceptionVec_19;
    s2_in.uop.exceptionVec[23] = s2_in_uop_exceptionVec_23;
    s2_in.uop.trigger = s2_in_uop_trigger;
    s2_in.uop.fuOpType = s2_in_uop_fuOpType;
    s2_in.uop.rfWen = s2_in_uop_rfWen;
    s2_in.uop.vpu_veew = s2_in_uop_vpu_veew;
    s2_in.uop.uopIdx = s2_in_uop_uopIdx;
    s2_in.uop.pdest = s2_in_uop_pdest;
    s2_in.uop.robIdx_flag = s2_in_uop_robIdx_flag;
    s2_in.uop.robIdx_value = s2_in_uop_robIdx_value;
    s2_in.uop.debugInfo_eliminatedMove = s2_in_uop_debugInfo_eliminatedMove;
    s2_in.uop.debugInfo_renameTime = s2_in_uop_debugInfo_renameTime;
    s2_in.uop.debugInfo_dispatchTime = s2_in_uop_debugInfo_dispatchTime;
    s2_in.uop.debugInfo_enqRsTime = s2_in_uop_debugInfo_enqRsTime;
    s2_in.uop.debugInfo_selectTime = s2_in_uop_debugInfo_selectTime;
    s2_in.uop.debugInfo_issueTime = s2_in_uop_debugInfo_issueTime;
    s2_in.uop.debugInfo_writebackTime = s2_in_uop_debugInfo_writebackTime;
    s2_in.uop.debugInfo_runahead_checkpoint_id = s2_in_uop_debugInfo_runahead_checkpoint_id;
    s2_in.uop.debugInfo_tlbFirstReqTime = s2_in_uop_debugInfo_tlbFirstReqTime;
    s2_in.uop.debugInfo_tlbRespTime = s2_in_uop_debugInfo_tlbRespTime;
    s2_in.uop.debug_seqNum_seqNum = s2_in_uop_debug_seqNum_seqNum;
    s2_in.uop.debug_seqNum_uopIdx = s2_in_uop_debug_seqNum_uopIdx;
    s2_in.uop.sqIdx_flag = s2_in_uop_sqIdx_flag;
    s2_in.uop.sqIdx_value = s2_in_uop_sqIdx_value;
    s2_in.vaddr = s2_in_vaddr;
    s2_in.fullva = s2_in_fullva;
    s2_in.vaNeedExt = s2_in_vaNeedExt;
    s2_in.paddr = s2_in_paddr;
    s2_in.gpaddr = s2_in_gpaddr;
    s2_in.mask = s2_in_mask;
    s2_in.nc = s2_in_nc;
    s2_in.mmio = s2_in_mmio;
    s2_in.isHyper = s2_in_isHyper;
    s2_in.isForVSnonLeafPTE = s2_in_isForVSnonLeafPTE;
    s2_in.isvec = s2_in_isvec;
    s2_in.elemIdx = s2_in_elemIdx;
    s2_in.mbIndex = s2_in_mbIndex;
    s2_in.vecVaddrOffset = s2_in_vecVaddrOffset;
    s2_in.splitIndex = s2_in_splitIndex;
    s2_in.vecActive = s2_in_vecActive;
    s2_in.isFrmMisAlignBuf = s2_in_isFrmMisAlignBuf;
    s2_in.isMisalign = s2_in_isMisalign;
    s2_in.isFinalSplit = s2_in_isFinalSplit;
  end

  // ---- s3_in <= s2_out（s2_fire 时整包打拍，无复位）：golden 留下的 41 个字段 ----
  logic          s3_in_uop_exceptionVec_3;
  logic          s3_in_uop_exceptionVec_6;
  logic          s3_in_uop_exceptionVec_7;
  logic          s3_in_uop_exceptionVec_15;
  logic          s3_in_uop_exceptionVec_19;
  logic          s3_in_uop_exceptionVec_23;
  logic [3:0]    s3_in_uop_trigger;
  logic          s3_in_uop_rfWen;
  logic [7:0]    s3_in_uop_vpu_vstart;
  logic [7:0]    s3_in_uop_pdest;
  logic          s3_in_uop_robIdx_flag;
  logic [7:0]    s3_in_uop_robIdx_value;
  logic          s3_in_uop_debugInfo_eliminatedMove;
  logic [63:0]   s3_in_uop_debugInfo_renameTime;
  logic [63:0]   s3_in_uop_debugInfo_dispatchTime;
  logic [63:0]   s3_in_uop_debugInfo_enqRsTime;
  logic [63:0]   s3_in_uop_debugInfo_selectTime;
  logic [63:0]   s3_in_uop_debugInfo_issueTime;
  logic [63:0]   s3_in_uop_debugInfo_writebackTime;
  logic [63:0]   s3_in_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   s3_in_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   s3_in_uop_debugInfo_tlbRespTime;
  logic [55:0]   s3_in_uop_debug_seqNum_seqNum;
  logic [7:0]    s3_in_uop_debug_seqNum_uopIdx;
  logic          s3_in_uop_sqIdx_flag;
  logic [5:0]    s3_in_uop_sqIdx_value;
  logic [49:0]   s3_in_vaddr;
  logic [63:0]   s3_in_fullva;
  logic          s3_in_vaNeedExt;
  logic [47:0]   s3_in_paddr;
  logic [63:0]   s3_in_gpaddr;
  logic [15:0]   s3_in_mask;
  logic          s3_in_nc;
  logic          s3_in_mmio;
  logic          s3_in_memBackTypeMM;
  logic          s3_in_isForVSnonLeafPTE;
  logic          s3_in_isvec;
  logic [7:0]    s3_in_elemIdx;
  logic [3:0]    s3_in_mbIndex;
  logic [4:0]    s3_in_splitIndex;
  logic          s3_in_vecActive;
  always_ff @(posedge clock) begin
    if (s2_fire) begin
      s3_in_uop_exceptionVec_3 <= s2_out.uop.exceptionVec[3];
      s3_in_uop_exceptionVec_6 <= s2_out.uop.exceptionVec[6];
      s3_in_uop_exceptionVec_7 <= s2_out.uop.exceptionVec[7];
      s3_in_uop_exceptionVec_15 <= s2_out.uop.exceptionVec[15];
      s3_in_uop_exceptionVec_19 <= s2_out.uop.exceptionVec[19];
      s3_in_uop_exceptionVec_23 <= s2_out.uop.exceptionVec[23];
      s3_in_uop_trigger <= s2_out.uop.trigger;
      s3_in_uop_rfWen <= s2_out.uop.rfWen;
      s3_in_uop_vpu_vstart <= s2_out.uop.vpu_vstart;
      s3_in_uop_pdest <= s2_out.uop.pdest;
      s3_in_uop_robIdx_flag <= s2_out.uop.robIdx_flag;
      s3_in_uop_robIdx_value <= s2_out.uop.robIdx_value;
      s3_in_uop_debugInfo_eliminatedMove <= s2_out.uop.debugInfo_eliminatedMove;
      s3_in_uop_debugInfo_renameTime <= s2_out.uop.debugInfo_renameTime;
      s3_in_uop_debugInfo_dispatchTime <= s2_out.uop.debugInfo_dispatchTime;
      s3_in_uop_debugInfo_enqRsTime <= s2_out.uop.debugInfo_enqRsTime;
      s3_in_uop_debugInfo_selectTime <= s2_out.uop.debugInfo_selectTime;
      s3_in_uop_debugInfo_issueTime <= s2_out.uop.debugInfo_issueTime;
      s3_in_uop_debugInfo_writebackTime <= s2_out.uop.debugInfo_writebackTime;
      s3_in_uop_debugInfo_runahead_checkpoint_id <= s2_out.uop.debugInfo_runahead_checkpoint_id;
      s3_in_uop_debugInfo_tlbFirstReqTime <= s2_out.uop.debugInfo_tlbFirstReqTime;
      s3_in_uop_debugInfo_tlbRespTime <= s2_out.uop.debugInfo_tlbRespTime;
      s3_in_uop_debug_seqNum_seqNum <= s2_out.uop.debug_seqNum_seqNum;
      s3_in_uop_debug_seqNum_uopIdx <= s2_out.uop.debug_seqNum_uopIdx;
      s3_in_uop_sqIdx_flag <= s2_out.uop.sqIdx_flag;
      s3_in_uop_sqIdx_value <= s2_out.uop.sqIdx_value;
      s3_in_vaddr <= s2_out.vaddr;
      s3_in_fullva <= s2_out.fullva;
      s3_in_vaNeedExt <= s2_out.vaNeedExt;
      s3_in_paddr <= s2_out.paddr;
      s3_in_gpaddr <= s2_out.gpaddr;
      s3_in_mask <= s2_out.mask;
      s3_in_nc <= s2_out.nc;
      s3_in_mmio <= s2_out.mmio;
      s3_in_memBackTypeMM <= s2_out.memBackTypeMM;
      s3_in_isForVSnonLeafPTE <= s2_out.isForVSnonLeafPTE;
      s3_in_isvec <= s2_out.isvec;
      s3_in_elemIdx <= s2_out.elemIdx;
      s3_in_mbIndex <= s2_out.mbIndex;
      s3_in_splitIndex <= s2_out.splitIndex;
      s3_in_vecActive <= s2_out.vecActive;
    end
  end
  always_comb begin
    s3_in = '0;
    s3_in.uop.exceptionVec[3] = s3_in_uop_exceptionVec_3;
    s3_in.uop.exceptionVec[6] = s3_in_uop_exceptionVec_6;
    s3_in.uop.exceptionVec[7] = s3_in_uop_exceptionVec_7;
    s3_in.uop.exceptionVec[15] = s3_in_uop_exceptionVec_15;
    s3_in.uop.exceptionVec[19] = s3_in_uop_exceptionVec_19;
    s3_in.uop.exceptionVec[23] = s3_in_uop_exceptionVec_23;
    s3_in.uop.trigger = s3_in_uop_trigger;
    s3_in.uop.rfWen = s3_in_uop_rfWen;
    s3_in.uop.vpu_vstart = s3_in_uop_vpu_vstart;
    s3_in.uop.pdest = s3_in_uop_pdest;
    s3_in.uop.robIdx_flag = s3_in_uop_robIdx_flag;
    s3_in.uop.robIdx_value = s3_in_uop_robIdx_value;
    s3_in.uop.debugInfo_eliminatedMove = s3_in_uop_debugInfo_eliminatedMove;
    s3_in.uop.debugInfo_renameTime = s3_in_uop_debugInfo_renameTime;
    s3_in.uop.debugInfo_dispatchTime = s3_in_uop_debugInfo_dispatchTime;
    s3_in.uop.debugInfo_enqRsTime = s3_in_uop_debugInfo_enqRsTime;
    s3_in.uop.debugInfo_selectTime = s3_in_uop_debugInfo_selectTime;
    s3_in.uop.debugInfo_issueTime = s3_in_uop_debugInfo_issueTime;
    s3_in.uop.debugInfo_writebackTime = s3_in_uop_debugInfo_writebackTime;
    s3_in.uop.debugInfo_runahead_checkpoint_id = s3_in_uop_debugInfo_runahead_checkpoint_id;
    s3_in.uop.debugInfo_tlbFirstReqTime = s3_in_uop_debugInfo_tlbFirstReqTime;
    s3_in.uop.debugInfo_tlbRespTime = s3_in_uop_debugInfo_tlbRespTime;
    s3_in.uop.debug_seqNum_seqNum = s3_in_uop_debug_seqNum_seqNum;
    s3_in.uop.debug_seqNum_uopIdx = s3_in_uop_debug_seqNum_uopIdx;
    s3_in.uop.sqIdx_flag = s3_in_uop_sqIdx_flag;
    s3_in.uop.sqIdx_value = s3_in_uop_sqIdx_value;
    s3_in.vaddr = s3_in_vaddr;
    s3_in.fullva = s3_in_fullva;
    s3_in.vaNeedExt = s3_in_vaNeedExt;
    s3_in.paddr = s3_in_paddr;
    s3_in.gpaddr = s3_in_gpaddr;
    s3_in.mask = s3_in_mask;
    s3_in.nc = s3_in_nc;
    s3_in.mmio = s3_in_mmio;
    s3_in.memBackTypeMM = s3_in_memBackTypeMM;
    s3_in.isForVSnonLeafPTE = s3_in_isForVSnonLeafPTE;
    s3_in.isvec = s3_in_isvec;
    s3_in.elemIdx = s3_in_elemIdx;
    s3_in.mbIndex = s3_in_mbIndex;
    s3_in.splitIndex = s3_in_splitIndex;
    s3_in.vecActive = s3_in_vecActive;
  end

  // ---- sx_in_1 <= sx_in_0（写回延迟级，s3 发出时打拍，无复位）：golden 留下的 40 个字段 ----
  logic          sx_in_1_r_output_uop_exceptionVec_3;
  logic          sx_in_1_r_output_uop_exceptionVec_6;
  logic          sx_in_1_r_output_uop_exceptionVec_7;
  logic          sx_in_1_r_output_uop_exceptionVec_15;
  logic          sx_in_1_r_output_uop_exceptionVec_19;
  logic          sx_in_1_r_output_uop_exceptionVec_23;
  logic [3:0]    sx_in_1_r_output_uop_trigger;
  logic          sx_in_1_r_output_uop_rfWen;
  logic [7:0]    sx_in_1_r_output_uop_vpu_vstart;
  logic [7:0]    sx_in_1_r_output_uop_pdest;
  logic          sx_in_1_r_output_uop_robIdx_flag;
  logic [7:0]    sx_in_1_r_output_uop_robIdx_value;
  logic          sx_in_1_r_output_uop_debugInfo_eliminatedMove;
  logic [63:0]   sx_in_1_r_output_uop_debugInfo_renameTime;
  logic [63:0]   sx_in_1_r_output_uop_debugInfo_dispatchTime;
  logic [63:0]   sx_in_1_r_output_uop_debugInfo_enqRsTime;
  logic [63:0]   sx_in_1_r_output_uop_debugInfo_selectTime;
  logic [63:0]   sx_in_1_r_output_uop_debugInfo_issueTime;
  logic [63:0]   sx_in_1_r_output_uop_debugInfo_writebackTime;
  logic [63:0]   sx_in_1_r_output_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   sx_in_1_r_output_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   sx_in_1_r_output_uop_debugInfo_tlbRespTime;
  logic [55:0]   sx_in_1_r_output_uop_debug_seqNum_seqNum;
  logic [7:0]    sx_in_1_r_output_uop_debug_seqNum_uopIdx;
  logic          sx_in_1_r_output_uop_sqIdx_flag;
  logic [5:0]    sx_in_1_r_output_uop_sqIdx_value;
  logic          sx_in_1_r_output_debug_isMMIO;
  logic          sx_in_1_r_output_debug_isNCIO;
  logic [47:0]   sx_in_1_r_output_debug_paddr;
  logic [49:0]   sx_in_1_r_output_debug_vaddr;
  logic          sx_in_1_r_vecFeedback;
  logic          sx_in_1_r_hasException;
  logic [7:0]    sx_in_1_r_elemIdx;
  logic [3:0]    sx_in_1_r_mbIndex;
  logic [15:0]   sx_in_1_r_mask;
  logic [63:0]   sx_in_1_r_vaddr;
  logic          sx_in_1_r_vaNeedExt;
  logic [63:0]   sx_in_1_r_gpaddr;
  logic          sx_in_1_r_isForVSnonLeafPTE;
  logic [4:0]    sx_in_1_r_splitIndx;
  always_ff @(posedge clock) begin
    if (sx_prev_fire) begin
      sx_in_1_r_output_uop_exceptionVec_3 <= sx_in_0.out.uop.exceptionVec[3];
      sx_in_1_r_output_uop_exceptionVec_6 <= sx_in_0.out.uop.exceptionVec[6];
      sx_in_1_r_output_uop_exceptionVec_7 <= sx_in_0.out.uop.exceptionVec[7];
      sx_in_1_r_output_uop_exceptionVec_15 <= sx_in_0.out.uop.exceptionVec[15];
      sx_in_1_r_output_uop_exceptionVec_19 <= sx_in_0.out.uop.exceptionVec[19];
      sx_in_1_r_output_uop_exceptionVec_23 <= sx_in_0.out.uop.exceptionVec[23];
      sx_in_1_r_output_uop_trigger <= sx_in_0.out.uop.trigger;
      sx_in_1_r_output_uop_rfWen <= sx_in_0.out.uop.rfWen;
      sx_in_1_r_output_uop_vpu_vstart <= sx_in_0.out.uop.vpu_vstart;
      sx_in_1_r_output_uop_pdest <= sx_in_0.out.uop.pdest;
      sx_in_1_r_output_uop_robIdx_flag <= sx_in_0.out.uop.robIdx_flag;
      sx_in_1_r_output_uop_robIdx_value <= sx_in_0.out.uop.robIdx_value;
      sx_in_1_r_output_uop_debugInfo_eliminatedMove <= sx_in_0.out.uop.debugInfo_eliminatedMove;
      sx_in_1_r_output_uop_debugInfo_renameTime <= sx_in_0.out.uop.debugInfo_renameTime;
      sx_in_1_r_output_uop_debugInfo_dispatchTime <= sx_in_0.out.uop.debugInfo_dispatchTime;
      sx_in_1_r_output_uop_debugInfo_enqRsTime <= sx_in_0.out.uop.debugInfo_enqRsTime;
      sx_in_1_r_output_uop_debugInfo_selectTime <= sx_in_0.out.uop.debugInfo_selectTime;
      sx_in_1_r_output_uop_debugInfo_issueTime <= sx_in_0.out.uop.debugInfo_issueTime;
      sx_in_1_r_output_uop_debugInfo_writebackTime <= sx_in_0.out.uop.debugInfo_writebackTime;
      sx_in_1_r_output_uop_debugInfo_runahead_checkpoint_id <= sx_in_0.out.uop.debugInfo_runahead_checkpoint_id;
      sx_in_1_r_output_uop_debugInfo_tlbFirstReqTime <= sx_in_0.out.uop.debugInfo_tlbFirstReqTime;
      sx_in_1_r_output_uop_debugInfo_tlbRespTime <= sx_in_0.out.uop.debugInfo_tlbRespTime;
      sx_in_1_r_output_uop_debug_seqNum_seqNum <= sx_in_0.out.uop.debug_seqNum_seqNum;
      sx_in_1_r_output_uop_debug_seqNum_uopIdx <= sx_in_0.out.uop.debug_seqNum_uopIdx;
      sx_in_1_r_output_uop_sqIdx_flag <= sx_in_0.out.uop.sqIdx_flag;
      sx_in_1_r_output_uop_sqIdx_value <= sx_in_0.out.uop.sqIdx_value;
      sx_in_1_r_output_debug_isMMIO <= sx_in_0.out.debug_isMMIO;
      sx_in_1_r_output_debug_isNCIO <= sx_in_0.out.debug_isNCIO;
      sx_in_1_r_output_debug_paddr <= sx_in_0.out.debug_paddr;
      sx_in_1_r_output_debug_vaddr <= sx_in_0.out.debug_vaddr;
      sx_in_1_r_vecFeedback <= sx_in_0.vecFeedback;
      sx_in_1_r_hasException <= sx_in_0.hasException;
      sx_in_1_r_elemIdx <= sx_in_0.elemIdx;
      sx_in_1_r_mbIndex <= sx_in_0.mbIndex;
      sx_in_1_r_mask <= sx_in_0.mask;
      sx_in_1_r_vaddr <= sx_in_0.vaddr;
      sx_in_1_r_vaNeedExt <= sx_in_0.vaNeedExt;
      sx_in_1_r_gpaddr <= sx_in_0.gpaddr;
      sx_in_1_r_isForVSnonLeafPTE <= sx_in_0.isForVSnonLeafPTE;
      sx_in_1_r_splitIndx <= sx_in_0.splitIndx;
    end
  end
  always_comb begin
    sx_in_1 = '0;
    sx_in_1.out.uop.exceptionVec[3] = sx_in_1_r_output_uop_exceptionVec_3;
    sx_in_1.out.uop.exceptionVec[6] = sx_in_1_r_output_uop_exceptionVec_6;
    sx_in_1.out.uop.exceptionVec[7] = sx_in_1_r_output_uop_exceptionVec_7;
    sx_in_1.out.uop.exceptionVec[15] = sx_in_1_r_output_uop_exceptionVec_15;
    sx_in_1.out.uop.exceptionVec[19] = sx_in_1_r_output_uop_exceptionVec_19;
    sx_in_1.out.uop.exceptionVec[23] = sx_in_1_r_output_uop_exceptionVec_23;
    sx_in_1.out.uop.trigger = sx_in_1_r_output_uop_trigger;
    sx_in_1.out.uop.rfWen = sx_in_1_r_output_uop_rfWen;
    sx_in_1.out.uop.vpu_vstart = sx_in_1_r_output_uop_vpu_vstart;
    sx_in_1.out.uop.pdest = sx_in_1_r_output_uop_pdest;
    sx_in_1.out.uop.robIdx_flag = sx_in_1_r_output_uop_robIdx_flag;
    sx_in_1.out.uop.robIdx_value = sx_in_1_r_output_uop_robIdx_value;
    sx_in_1.out.uop.debugInfo_eliminatedMove = sx_in_1_r_output_uop_debugInfo_eliminatedMove;
    sx_in_1.out.uop.debugInfo_renameTime = sx_in_1_r_output_uop_debugInfo_renameTime;
    sx_in_1.out.uop.debugInfo_dispatchTime = sx_in_1_r_output_uop_debugInfo_dispatchTime;
    sx_in_1.out.uop.debugInfo_enqRsTime = sx_in_1_r_output_uop_debugInfo_enqRsTime;
    sx_in_1.out.uop.debugInfo_selectTime = sx_in_1_r_output_uop_debugInfo_selectTime;
    sx_in_1.out.uop.debugInfo_issueTime = sx_in_1_r_output_uop_debugInfo_issueTime;
    sx_in_1.out.uop.debugInfo_writebackTime = sx_in_1_r_output_uop_debugInfo_writebackTime;
    sx_in_1.out.uop.debugInfo_runahead_checkpoint_id = sx_in_1_r_output_uop_debugInfo_runahead_checkpoint_id;
    sx_in_1.out.uop.debugInfo_tlbFirstReqTime = sx_in_1_r_output_uop_debugInfo_tlbFirstReqTime;
    sx_in_1.out.uop.debugInfo_tlbRespTime = sx_in_1_r_output_uop_debugInfo_tlbRespTime;
    sx_in_1.out.uop.debug_seqNum_seqNum = sx_in_1_r_output_uop_debug_seqNum_seqNum;
    sx_in_1.out.uop.debug_seqNum_uopIdx = sx_in_1_r_output_uop_debug_seqNum_uopIdx;
    sx_in_1.out.uop.sqIdx_flag = sx_in_1_r_output_uop_sqIdx_flag;
    sx_in_1.out.uop.sqIdx_value = sx_in_1_r_output_uop_sqIdx_value;
    sx_in_1.out.debug_isMMIO = sx_in_1_r_output_debug_isMMIO;
    sx_in_1.out.debug_isNCIO = sx_in_1_r_output_debug_isNCIO;
    sx_in_1.out.debug_paddr = sx_in_1_r_output_debug_paddr;
    sx_in_1.out.debug_vaddr = sx_in_1_r_output_debug_vaddr;
    sx_in_1.vecFeedback = sx_in_1_r_vecFeedback;
    sx_in_1.hasException = sx_in_1_r_hasException;
    sx_in_1.elemIdx = sx_in_1_r_elemIdx;
    sx_in_1.mbIndex = sx_in_1_r_mbIndex;
    sx_in_1.mask = sx_in_1_r_mask;
    sx_in_1.vaddr = sx_in_1_r_vaddr;
    sx_in_1.vaNeedExt = sx_in_1_r_vaNeedExt;
    sx_in_1.gpaddr = sx_in_1_r_gpaddr;
    sx_in_1.isForVSnonLeafPTE = sx_in_1_r_isForVSnonLeafPTE;
    sx_in_1.splitIndx = sx_in_1_r_splitIndx;
  end

  // ---- feedback_slow_r <= s1_feedback（s1 反馈有效时打拍，无复位）：golden 留下的 7 个字段 ----
  logic          io_feedback_slow_bits_r_robIdx_flag;
  logic [7:0]    io_feedback_slow_bits_r_robIdx_value;
  logic          io_feedback_slow_bits_r_flushState;
  logic          io_feedback_slow_bits_r_sqIdx_flag;
  logic [5:0]    io_feedback_slow_bits_r_sqIdx_value;
  logic          io_feedback_slow_bits_r_lqIdx_flag;
  logic [6:0]    io_feedback_slow_bits_r_lqIdx_value;
  always_ff @(posedge clock) begin
    if (feedback_slow_valid_next) begin
      io_feedback_slow_bits_r_robIdx_flag <= s1_feedback.robIdx_flag;
      io_feedback_slow_bits_r_robIdx_value <= s1_feedback.robIdx_value;
      io_feedback_slow_bits_r_flushState <= s1_feedback.flushState;
      io_feedback_slow_bits_r_sqIdx_flag <= s1_feedback.sqIdx_flag;
      io_feedback_slow_bits_r_sqIdx_value <= s1_feedback.sqIdx_value;
      io_feedback_slow_bits_r_lqIdx_flag <= s1_feedback.lqIdx_flag;
      io_feedback_slow_bits_r_lqIdx_value <= s1_feedback.lqIdx_value;
    end
  end
  always_comb begin
    feedback_slow_r = '0;
    feedback_slow_r.robIdx_flag = io_feedback_slow_bits_r_robIdx_flag;
    feedback_slow_r.robIdx_value = io_feedback_slow_bits_r_robIdx_value;
    feedback_slow_r.flushState = io_feedback_slow_bits_r_flushState;
    feedback_slow_r.sqIdx_flag = io_feedback_slow_bits_r_sqIdx_flag;
    feedback_slow_r.sqIdx_value = io_feedback_slow_bits_r_sqIdx_value;
    feedback_slow_r.lqIdx_flag = io_feedback_slow_bits_r_lqIdx_flag;
    feedback_slow_r.lqIdx_value = io_feedback_slow_bits_r_lqIdx_value;
  end
  // END GENERATED(pipe_regs)

endmodule

// =====================================================================
// golden 同名 wrapper（生成）：扁平端口 ↔ 核的 struct 口；golden 没有的字段在输入侧补 0
// =====================================================================
// BEGIN GENERATED(wrapper) —— scripts/gen_storeunit.py 生成，勿手改
module StoreUnit
  import storeunit_pkg::*;
(
  input         clock,
  input         reset,
  input         io_redirect_valid,
  input         io_redirect_bits_robIdx_flag,
  input  [7:0]  io_redirect_bits_robIdx_value,
  input         io_redirect_bits_level,
  input         io_csrCtrl_hd_misalign_st_enable,
  output        io_stin_ready,
  input         io_stin_valid,
  input         io_stin_bits_uop_ftqPtr_flag,
  input  [5:0]  io_stin_bits_uop_ftqPtr_value,
  input  [3:0]  io_stin_bits_uop_ftqOffset,
  input  [34:0] io_stin_bits_uop_fuType,
  input  [8:0]  io_stin_bits_uop_fuOpType,
  input         io_stin_bits_uop_rfWen,
  input  [31:0] io_stin_bits_uop_imm,
  input  [7:0]  io_stin_bits_uop_pdest,
  input         io_stin_bits_uop_robIdx_flag,
  input  [7:0]  io_stin_bits_uop_robIdx_value,
  input         io_stin_bits_uop_debugInfo_eliminatedMove,
  input  [63:0] io_stin_bits_uop_debugInfo_renameTime,
  input  [63:0] io_stin_bits_uop_debugInfo_dispatchTime,
  input  [63:0] io_stin_bits_uop_debugInfo_enqRsTime,
  input  [63:0] io_stin_bits_uop_debugInfo_selectTime,
  input  [63:0] io_stin_bits_uop_debugInfo_issueTime,
  input  [63:0] io_stin_bits_uop_debugInfo_writebackTime,
  input  [63:0] io_stin_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0] io_stin_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0] io_stin_bits_uop_debugInfo_tlbRespTime,
  input  [55:0] io_stin_bits_uop_debug_seqNum_seqNum,
  input  [7:0]  io_stin_bits_uop_debug_seqNum_uopIdx,
  input         io_stin_bits_uop_lqIdx_flag,
  input  [6:0]  io_stin_bits_uop_lqIdx_value,
  input         io_stin_bits_uop_sqIdx_flag,
  input  [5:0]  io_stin_bits_uop_sqIdx_value,
  input  [63:0] io_stin_bits_src_0,
  input         io_stin_bits_isFirstIssue,
  output        io_issue_valid,
  output        io_issue_bits_uop_robIdx_flag,
  output [7:0]  io_issue_bits_uop_robIdx_value,
  output        io_misalign_stin_ready,
  input         io_misalign_stin_valid,
  input         io_misalign_stin_bits_uop_exceptionVec_0,
  input         io_misalign_stin_bits_uop_exceptionVec_1,
  input         io_misalign_stin_bits_uop_exceptionVec_2,
  input         io_misalign_stin_bits_uop_exceptionVec_4,
  input         io_misalign_stin_bits_uop_exceptionVec_5,
  input         io_misalign_stin_bits_uop_exceptionVec_8,
  input         io_misalign_stin_bits_uop_exceptionVec_9,
  input         io_misalign_stin_bits_uop_exceptionVec_10,
  input         io_misalign_stin_bits_uop_exceptionVec_11,
  input         io_misalign_stin_bits_uop_exceptionVec_12,
  input         io_misalign_stin_bits_uop_exceptionVec_13,
  input         io_misalign_stin_bits_uop_exceptionVec_14,
  input         io_misalign_stin_bits_uop_exceptionVec_16,
  input         io_misalign_stin_bits_uop_exceptionVec_17,
  input         io_misalign_stin_bits_uop_exceptionVec_18,
  input         io_misalign_stin_bits_uop_exceptionVec_19,
  input         io_misalign_stin_bits_uop_exceptionVec_20,
  input         io_misalign_stin_bits_uop_exceptionVec_21,
  input         io_misalign_stin_bits_uop_exceptionVec_22,
  input  [3:0]  io_misalign_stin_bits_uop_trigger,
  input         io_misalign_stin_bits_uop_ftqPtr_flag,
  input  [5:0]  io_misalign_stin_bits_uop_ftqPtr_value,
  input  [3:0]  io_misalign_stin_bits_uop_ftqOffset,
  input  [34:0] io_misalign_stin_bits_uop_fuType,
  input  [8:0]  io_misalign_stin_bits_uop_fuOpType,
  input         io_misalign_stin_bits_uop_rfWen,
  input  [7:0]  io_misalign_stin_bits_uop_vpu_vstart,
  input  [2:0]  io_misalign_stin_bits_uop_vpu_nf,
  input  [1:0]  io_misalign_stin_bits_uop_vpu_veew,
  input  [6:0]  io_misalign_stin_bits_uop_uopIdx,
  input  [7:0]  io_misalign_stin_bits_uop_pdest,
  input         io_misalign_stin_bits_uop_robIdx_flag,
  input  [7:0]  io_misalign_stin_bits_uop_robIdx_value,
  input         io_misalign_stin_bits_uop_debugInfo_eliminatedMove,
  input  [63:0] io_misalign_stin_bits_uop_debugInfo_renameTime,
  input  [63:0] io_misalign_stin_bits_uop_debugInfo_dispatchTime,
  input  [63:0] io_misalign_stin_bits_uop_debugInfo_enqRsTime,
  input  [63:0] io_misalign_stin_bits_uop_debugInfo_selectTime,
  input  [63:0] io_misalign_stin_bits_uop_debugInfo_issueTime,
  input  [63:0] io_misalign_stin_bits_uop_debugInfo_writebackTime,
  input  [63:0] io_misalign_stin_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0] io_misalign_stin_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0] io_misalign_stin_bits_uop_debugInfo_tlbRespTime,
  input  [55:0] io_misalign_stin_bits_uop_debug_seqNum_seqNum,
  input  [7:0]  io_misalign_stin_bits_uop_debug_seqNum_uopIdx,
  input         io_misalign_stin_bits_uop_lqIdx_flag,
  input  [6:0]  io_misalign_stin_bits_uop_lqIdx_value,
  input         io_misalign_stin_bits_uop_sqIdx_flag,
  input  [5:0]  io_misalign_stin_bits_uop_sqIdx_value,
  input  [49:0] io_misalign_stin_bits_vaddr,
  input  [15:0] io_misalign_stin_bits_mask,
  input         io_misalign_stin_bits_isvec,
  input         io_misalign_stin_bits_is128bit,
  input         io_misalign_stin_bits_isFinalSplit,
  output        io_misalign_stout_valid,
  output        io_misalign_stout_bits_uop_exceptionVec_3,
  output        io_misalign_stout_bits_uop_exceptionVec_6,
  output        io_misalign_stout_bits_uop_exceptionVec_7,
  output        io_misalign_stout_bits_uop_exceptionVec_15,
  output        io_misalign_stout_bits_uop_exceptionVec_19,
  output        io_misalign_stout_bits_uop_exceptionVec_23,
  output [3:0]  io_misalign_stout_bits_uop_trigger,
  output        io_misalign_stout_bits_uop_robIdx_flag,
  output [7:0]  io_misalign_stout_bits_uop_robIdx_value,
  output [49:0] io_misalign_stout_bits_vaddr,
  output        io_misalign_stout_bits_vaNeedExt,
  output [47:0] io_misalign_stout_bits_paddr,
  output [63:0] io_misalign_stout_bits_gpaddr,
  output        io_misalign_stout_bits_nc,
  output        io_misalign_stout_bits_mmio,
  output        io_misalign_stout_bits_memBackTypeMM,
  output        io_misalign_stout_bits_isForVSnonLeafPTE,
  output        io_misalign_stout_bits_vecActive,
  output        io_misalign_stout_bits_need_rep,
  output        io_tlb_req_valid,
  output [49:0] io_tlb_req_bits_vaddr,
  output [63:0] io_tlb_req_bits_fullva,
  output        io_tlb_req_bits_checkfullva,
  output [2:0]  io_tlb_req_bits_cmd,
  output        io_tlb_req_bits_hyperinst,
  output [6:0]  io_tlb_req_bits_memidx_idx,
  output        io_tlb_req_bits_frm_mabuf,
  output        io_tlb_req_bits_debug_robIdx_flag,
  output [7:0]  io_tlb_req_bits_debug_robIdx_value,
  output        io_tlb_req_bits_debug_isFirstIssue,
  input         io_tlb_resp_valid,
  input  [47:0] io_tlb_resp_bits_paddr_0,
  input  [63:0] io_tlb_resp_bits_gpaddr_0,
  input  [63:0] io_tlb_resp_bits_fullva,
  input  [1:0]  io_tlb_resp_bits_pbmt_0,
  input         io_tlb_resp_bits_miss,
  input         io_tlb_resp_bits_isForVSnonLeafPTE,
  input         io_tlb_resp_bits_excp_0_vaNeedExt,
  input         io_tlb_resp_bits_excp_0_isHyper,
  input         io_tlb_resp_bits_excp_0_gpf_ld,
  input         io_tlb_resp_bits_excp_0_gpf_st,
  input         io_tlb_resp_bits_excp_0_pf_ld,
  input         io_tlb_resp_bits_excp_0_pf_st,
  input         io_tlb_resp_bits_excp_0_af_ld,
  input         io_tlb_resp_bits_excp_0_af_st,
  input         io_tlb_resp_bits_ptwBack,
  input  [6:0]  io_tlb_resp_bits_memidx_idx,
  output        io_dcache_req_valid,
  input         io_pmp_ld,
  input         io_pmp_st,
  input         io_pmp_mmio,
  output        io_lsq_valid,
  output        io_lsq_bits_uop_exceptionVec_0,
  output        io_lsq_bits_uop_exceptionVec_1,
  output        io_lsq_bits_uop_exceptionVec_2,
  output        io_lsq_bits_uop_exceptionVec_3,
  output        io_lsq_bits_uop_exceptionVec_4,
  output        io_lsq_bits_uop_exceptionVec_5,
  output        io_lsq_bits_uop_exceptionVec_6,
  output        io_lsq_bits_uop_exceptionVec_7,
  output        io_lsq_bits_uop_exceptionVec_8,
  output        io_lsq_bits_uop_exceptionVec_9,
  output        io_lsq_bits_uop_exceptionVec_10,
  output        io_lsq_bits_uop_exceptionVec_11,
  output        io_lsq_bits_uop_exceptionVec_12,
  output        io_lsq_bits_uop_exceptionVec_13,
  output        io_lsq_bits_uop_exceptionVec_14,
  output        io_lsq_bits_uop_exceptionVec_15,
  output        io_lsq_bits_uop_exceptionVec_16,
  output        io_lsq_bits_uop_exceptionVec_17,
  output        io_lsq_bits_uop_exceptionVec_18,
  output        io_lsq_bits_uop_exceptionVec_19,
  output        io_lsq_bits_uop_exceptionVec_20,
  output        io_lsq_bits_uop_exceptionVec_21,
  output        io_lsq_bits_uop_exceptionVec_22,
  output        io_lsq_bits_uop_exceptionVec_23,
  output [3:0]  io_lsq_bits_uop_trigger,
  output        io_lsq_bits_uop_ftqPtr_flag,
  output [5:0]  io_lsq_bits_uop_ftqPtr_value,
  output [3:0]  io_lsq_bits_uop_ftqOffset,
  output [34:0] io_lsq_bits_uop_fuType,
  output [8:0]  io_lsq_bits_uop_fuOpType,
  output        io_lsq_bits_uop_rfWen,
  output [2:0]  io_lsq_bits_uop_vpu_nf,
  output [1:0]  io_lsq_bits_uop_vpu_veew,
  output [6:0]  io_lsq_bits_uop_uopIdx,
  output [7:0]  io_lsq_bits_uop_pdest,
  output        io_lsq_bits_uop_robIdx_flag,
  output [7:0]  io_lsq_bits_uop_robIdx_value,
  output        io_lsq_bits_uop_debugInfo_eliminatedMove,
  output [63:0] io_lsq_bits_uop_debugInfo_renameTime,
  output [63:0] io_lsq_bits_uop_debugInfo_dispatchTime,
  output [63:0] io_lsq_bits_uop_debugInfo_enqRsTime,
  output [63:0] io_lsq_bits_uop_debugInfo_selectTime,
  output [63:0] io_lsq_bits_uop_debugInfo_issueTime,
  output [63:0] io_lsq_bits_uop_debugInfo_writebackTime,
  output [63:0] io_lsq_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0] io_lsq_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0] io_lsq_bits_uop_debugInfo_tlbRespTime,
  output [55:0] io_lsq_bits_uop_debug_seqNum_seqNum,
  output [7:0]  io_lsq_bits_uop_debug_seqNum_uopIdx,
  output        io_lsq_bits_uop_sqIdx_flag,
  output [5:0]  io_lsq_bits_uop_sqIdx_value,
  output [49:0] io_lsq_bits_vaddr,
  output [63:0] io_lsq_bits_fullva,
  output        io_lsq_bits_vaNeedExt,
  output [47:0] io_lsq_bits_paddr,
  output [63:0] io_lsq_bits_gpaddr,
  output [15:0] io_lsq_bits_mask,
  output        io_lsq_bits_wlineflag,
  output        io_lsq_bits_miss,
  output        io_lsq_bits_nc,
  output        io_lsq_bits_isHyper,
  output        io_lsq_bits_isForVSnonLeafPTE,
  output        io_lsq_bits_isvec,
  output        io_lsq_bits_isFrmMisAlignBuf,
  output        io_lsq_bits_isMisalign,
  output        io_lsq_bits_misalignWith16Byte,
  output        io_lsq_bits_updateAddrValid,
  output        io_lsq_replenish_uop_exceptionVec_3,
  output        io_lsq_replenish_uop_exceptionVec_6,
  output        io_lsq_replenish_uop_exceptionVec_15,
  output        io_lsq_replenish_uop_exceptionVec_19,
  output        io_lsq_replenish_uop_exceptionVec_23,
  output [6:0]  io_lsq_replenish_uop_uopIdx,
  output        io_lsq_replenish_uop_robIdx_flag,
  output [7:0]  io_lsq_replenish_uop_robIdx_value,
  output [63:0] io_lsq_replenish_fullva,
  output        io_lsq_replenish_vaNeedExt,
  output [63:0] io_lsq_replenish_gpaddr,
  output        io_lsq_replenish_af,
  output        io_lsq_replenish_mmio,
  output        io_lsq_replenish_memBackTypeMM,
  output        io_lsq_replenish_hasException,
  output        io_lsq_replenish_isHyper,
  output        io_lsq_replenish_isForVSnonLeafPTE,
  output        io_lsq_replenish_isvec,
  output        io_lsq_replenish_updateAddrValid,
  output        io_feedback_slow_valid,
  output        io_feedback_slow_bits_robIdx_flag,
  output [7:0]  io_feedback_slow_bits_robIdx_value,
  output        io_feedback_slow_bits_hit,
  output        io_feedback_slow_bits_flushState,
  output        io_feedback_slow_bits_sqIdx_flag,
  output [5:0]  io_feedback_slow_bits_sqIdx_value,
  output        io_feedback_slow_bits_lqIdx_flag,
  output [6:0]  io_feedback_slow_bits_lqIdx_value,
  output        io_stld_nuke_query_valid,
  output        io_stld_nuke_query_bits_robIdx_flag,
  output [7:0]  io_stld_nuke_query_bits_robIdx_value,
  output [47:0] io_stld_nuke_query_bits_paddr,
  output [15:0] io_stld_nuke_query_bits_mask,
  output [1:0]  io_stld_nuke_query_bits_matchType,
  output        io_stout_valid,
  output        io_stout_bits_uop_exceptionVec_3,
  output        io_stout_bits_uop_exceptionVec_6,
  output        io_stout_bits_uop_exceptionVec_7,
  output        io_stout_bits_uop_exceptionVec_15,
  output        io_stout_bits_uop_exceptionVec_19,
  output        io_stout_bits_uop_exceptionVec_23,
  output [3:0]  io_stout_bits_uop_trigger,
  output        io_stout_bits_uop_rfWen,
  output [7:0]  io_stout_bits_uop_pdest,
  output        io_stout_bits_uop_robIdx_flag,
  output [7:0]  io_stout_bits_uop_robIdx_value,
  output        io_stout_bits_uop_debugInfo_eliminatedMove,
  output [63:0] io_stout_bits_uop_debugInfo_renameTime,
  output [63:0] io_stout_bits_uop_debugInfo_dispatchTime,
  output [63:0] io_stout_bits_uop_debugInfo_enqRsTime,
  output [63:0] io_stout_bits_uop_debugInfo_selectTime,
  output [63:0] io_stout_bits_uop_debugInfo_issueTime,
  output [63:0] io_stout_bits_uop_debugInfo_writebackTime,
  output [63:0] io_stout_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0] io_stout_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0] io_stout_bits_uop_debugInfo_tlbRespTime,
  output [55:0] io_stout_bits_uop_debug_seqNum_seqNum,
  output [7:0]  io_stout_bits_uop_debug_seqNum_uopIdx,
  output        io_stout_bits_uop_sqIdx_flag,
  output [5:0]  io_stout_bits_uop_sqIdx_value,
  output        io_stout_bits_debug_isMMIO,
  output        io_stout_bits_debug_isNCIO,
  output [47:0] io_stout_bits_debug_paddr,
  output [49:0] io_stout_bits_debug_vaddr,
  output        io_vecstout_valid,
  output [3:0]  io_vecstout_bits_mBIndex,
  output        io_vecstout_bits_hit,
  output [3:0]  io_vecstout_bits_trigger,
  output        io_vecstout_bits_exceptionVec_3,
  output        io_vecstout_bits_exceptionVec_6,
  output        io_vecstout_bits_exceptionVec_7,
  output        io_vecstout_bits_exceptionVec_15,
  output        io_vecstout_bits_exceptionVec_19,
  output        io_vecstout_bits_exceptionVec_23,
  output        io_vecstout_bits_hasException,
  output [63:0] io_vecstout_bits_vaddr,
  output        io_vecstout_bits_vaNeedExt,
  output [63:0] io_vecstout_bits_gpaddr,
  output        io_vecstout_bits_isForVSnonLeafPTE,
  output [7:0]  io_vecstout_bits_vstart,
  output [7:0]  io_vecstout_bits_elemIdx,
  output [15:0] io_vecstout_bits_mask,
  output [4:0]  io_vecstout_bits_splitIndex,
  output        io_st_mask_out_valid,
  output [5:0]  io_st_mask_out_bits_sqIdx_value,
  output [15:0] io_st_mask_out_bits_mask,
  output        io_vecstin_ready,
  input         io_vecstin_valid,
  input  [63:0] io_vecstin_bits_vaddr,
  input  [49:0] io_vecstin_bits_basevaddr,
  input  [15:0] io_vecstin_bits_mask,
  input  [2:0]  io_vecstin_bits_alignedType,
  input         io_vecstin_bits_vecActive,
  input         io_vecstin_bits_vecIsFirstActiveElement,
  input         io_vecstin_bits_uop_exceptionVec_4,
  input         io_vecstin_bits_uop_exceptionVec_5,
  input         io_vecstin_bits_uop_exceptionVec_6,
  input         io_vecstin_bits_uop_exceptionVec_13,
  input         io_vecstin_bits_uop_exceptionVec_19,
  input         io_vecstin_bits_uop_exceptionVec_21,
  input  [3:0]  io_vecstin_bits_uop_trigger,
  input         io_vecstin_bits_uop_ftqPtr_flag,
  input  [5:0]  io_vecstin_bits_uop_ftqPtr_value,
  input  [3:0]  io_vecstin_bits_uop_ftqOffset,
  input  [34:0] io_vecstin_bits_uop_fuType,
  input  [8:0]  io_vecstin_bits_uop_fuOpType,
  input         io_vecstin_bits_uop_rfWen,
  input  [7:0]  io_vecstin_bits_uop_vpu_vstart,
  input  [2:0]  io_vecstin_bits_uop_vpu_nf,
  input  [1:0]  io_vecstin_bits_uop_vpu_veew,
  input  [6:0]  io_vecstin_bits_uop_uopIdx,
  input  [7:0]  io_vecstin_bits_uop_pdest,
  input         io_vecstin_bits_uop_robIdx_flag,
  input  [7:0]  io_vecstin_bits_uop_robIdx_value,
  input         io_vecstin_bits_uop_debugInfo_eliminatedMove,
  input  [63:0] io_vecstin_bits_uop_debugInfo_renameTime,
  input  [63:0] io_vecstin_bits_uop_debugInfo_dispatchTime,
  input  [63:0] io_vecstin_bits_uop_debugInfo_enqRsTime,
  input  [63:0] io_vecstin_bits_uop_debugInfo_selectTime,
  input  [63:0] io_vecstin_bits_uop_debugInfo_issueTime,
  input  [63:0] io_vecstin_bits_uop_debugInfo_writebackTime,
  input  [63:0] io_vecstin_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0] io_vecstin_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0] io_vecstin_bits_uop_debugInfo_tlbRespTime,
  input  [55:0] io_vecstin_bits_uop_debug_seqNum_seqNum,
  input  [7:0]  io_vecstin_bits_uop_debug_seqNum_uopIdx,
  input         io_vecstin_bits_uop_lqIdx_flag,
  input  [6:0]  io_vecstin_bits_uop_lqIdx_value,
  input         io_vecstin_bits_uop_sqIdx_flag,
  input  [5:0]  io_vecstin_bits_uop_sqIdx_value,
  input  [3:0]  io_vecstin_bits_mBIndex,
  input  [7:0]  io_vecstin_bits_elemIdx,
  input  [4:0]  io_vecstin_bits_splitIndex,
  input         io_misalign_enq_req_ready,
  output        io_misalign_enq_req_valid,
  output        io_misalign_enq_req_bits_uop_exceptionVec_0,
  output        io_misalign_enq_req_bits_uop_exceptionVec_1,
  output        io_misalign_enq_req_bits_uop_exceptionVec_2,
  output        io_misalign_enq_req_bits_uop_exceptionVec_4,
  output        io_misalign_enq_req_bits_uop_exceptionVec_5,
  output        io_misalign_enq_req_bits_uop_exceptionVec_8,
  output        io_misalign_enq_req_bits_uop_exceptionVec_9,
  output        io_misalign_enq_req_bits_uop_exceptionVec_10,
  output        io_misalign_enq_req_bits_uop_exceptionVec_11,
  output        io_misalign_enq_req_bits_uop_exceptionVec_12,
  output        io_misalign_enq_req_bits_uop_exceptionVec_13,
  output        io_misalign_enq_req_bits_uop_exceptionVec_14,
  output        io_misalign_enq_req_bits_uop_exceptionVec_16,
  output        io_misalign_enq_req_bits_uop_exceptionVec_17,
  output        io_misalign_enq_req_bits_uop_exceptionVec_18,
  output        io_misalign_enq_req_bits_uop_exceptionVec_19,
  output        io_misalign_enq_req_bits_uop_exceptionVec_20,
  output        io_misalign_enq_req_bits_uop_exceptionVec_21,
  output        io_misalign_enq_req_bits_uop_exceptionVec_22,
  output [3:0]  io_misalign_enq_req_bits_uop_trigger,
  output        io_misalign_enq_req_bits_uop_ftqPtr_flag,
  output [5:0]  io_misalign_enq_req_bits_uop_ftqPtr_value,
  output [3:0]  io_misalign_enq_req_bits_uop_ftqOffset,
  output [34:0] io_misalign_enq_req_bits_uop_fuType,
  output [8:0]  io_misalign_enq_req_bits_uop_fuOpType,
  output        io_misalign_enq_req_bits_uop_rfWen,
  output [7:0]  io_misalign_enq_req_bits_uop_vpu_vstart,
  output [2:0]  io_misalign_enq_req_bits_uop_vpu_nf,
  output [1:0]  io_misalign_enq_req_bits_uop_vpu_veew,
  output [6:0]  io_misalign_enq_req_bits_uop_uopIdx,
  output [7:0]  io_misalign_enq_req_bits_uop_pdest,
  output        io_misalign_enq_req_bits_uop_robIdx_flag,
  output [7:0]  io_misalign_enq_req_bits_uop_robIdx_value,
  output        io_misalign_enq_req_bits_uop_debugInfo_eliminatedMove,
  output [63:0] io_misalign_enq_req_bits_uop_debugInfo_renameTime,
  output [63:0] io_misalign_enq_req_bits_uop_debugInfo_dispatchTime,
  output [63:0] io_misalign_enq_req_bits_uop_debugInfo_enqRsTime,
  output [63:0] io_misalign_enq_req_bits_uop_debugInfo_selectTime,
  output [63:0] io_misalign_enq_req_bits_uop_debugInfo_issueTime,
  output [63:0] io_misalign_enq_req_bits_uop_debugInfo_writebackTime,
  output [63:0] io_misalign_enq_req_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0] io_misalign_enq_req_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0] io_misalign_enq_req_bits_uop_debugInfo_tlbRespTime,
  output [55:0] io_misalign_enq_req_bits_uop_debug_seqNum_seqNum,
  output [7:0]  io_misalign_enq_req_bits_uop_debug_seqNum_uopIdx,
  output        io_misalign_enq_req_bits_uop_lqIdx_flag,
  output [6:0]  io_misalign_enq_req_bits_uop_lqIdx_value,
  output        io_misalign_enq_req_bits_uop_sqIdx_flag,
  output [5:0]  io_misalign_enq_req_bits_uop_sqIdx_value,
  output [49:0] io_misalign_enq_req_bits_vaddr,
  output [15:0] io_misalign_enq_req_bits_mask,
  output        io_misalign_enq_req_bits_isvec,
  output [7:0]  io_misalign_enq_req_bits_elemIdx,
  output [2:0]  io_misalign_enq_req_bits_alignedType,
  output [3:0]  io_misalign_enq_req_bits_mbIndex,
  output [4:0]  io_misalign_enq_req_bits_splitIndex,
  output        io_misalign_enq_revoke,
  input  [1:0]  io_fromCsrTrigger_tdataVec_0_matchType,
  input         io_fromCsrTrigger_tdataVec_0_select,
  input         io_fromCsrTrigger_tdataVec_0_timing,
  input  [3:0]  io_fromCsrTrigger_tdataVec_0_action,
  input         io_fromCsrTrigger_tdataVec_0_chain,
  input         io_fromCsrTrigger_tdataVec_0_store,
  input  [63:0] io_fromCsrTrigger_tdataVec_0_tdata2,
  input  [1:0]  io_fromCsrTrigger_tdataVec_1_matchType,
  input         io_fromCsrTrigger_tdataVec_1_select,
  input         io_fromCsrTrigger_tdataVec_1_timing,
  input  [3:0]  io_fromCsrTrigger_tdataVec_1_action,
  input         io_fromCsrTrigger_tdataVec_1_chain,
  input         io_fromCsrTrigger_tdataVec_1_store,
  input  [63:0] io_fromCsrTrigger_tdataVec_1_tdata2,
  input  [1:0]  io_fromCsrTrigger_tdataVec_2_matchType,
  input         io_fromCsrTrigger_tdataVec_2_select,
  input         io_fromCsrTrigger_tdataVec_2_timing,
  input  [3:0]  io_fromCsrTrigger_tdataVec_2_action,
  input         io_fromCsrTrigger_tdataVec_2_chain,
  input         io_fromCsrTrigger_tdataVec_2_store,
  input  [63:0] io_fromCsrTrigger_tdataVec_2_tdata2,
  input  [1:0]  io_fromCsrTrigger_tdataVec_3_matchType,
  input         io_fromCsrTrigger_tdataVec_3_select,
  input         io_fromCsrTrigger_tdataVec_3_timing,
  input  [3:0]  io_fromCsrTrigger_tdataVec_3_action,
  input         io_fromCsrTrigger_tdataVec_3_chain,
  input         io_fromCsrTrigger_tdataVec_3_store,
  input  [63:0] io_fromCsrTrigger_tdataVec_3_tdata2,
  input         io_fromCsrTrigger_tEnableVec_0,
  input         io_fromCsrTrigger_tEnableVec_1,
  input         io_fromCsrTrigger_tEnableVec_2,
  input         io_fromCsrTrigger_tEnableVec_3,
  input         io_fromCsrTrigger_debugMode,
  input         io_fromCsrTrigger_triggerCanRaiseBpExp,
  input         io_sqCommitPtr_flag,
  input  [5:0]  io_sqCommitPtr_value,
  input  [6:0]  io_sqCommitUopIdx,
  input         io_sqCommitRobIdx_flag,
  input  [7:0]  io_sqCommitRobIdx_value
);

  redirect_t     redirect;
  always_comb begin
    redirect = '0;
    redirect.robIdx_flag = io_redirect_bits_robIdx_flag;
    redirect.robIdx_value = io_redirect_bits_robIdx_value;
    redirect.level = io_redirect_bits_level;
  end

  stin_t         stin;
  always_comb begin
    stin = '0;
    stin.uop.ftqPtr_flag = io_stin_bits_uop_ftqPtr_flag;
    stin.uop.ftqPtr_value = io_stin_bits_uop_ftqPtr_value;
    stin.uop.ftqOffset = io_stin_bits_uop_ftqOffset;
    stin.uop.fuType = io_stin_bits_uop_fuType;
    stin.uop.fuOpType = io_stin_bits_uop_fuOpType;
    stin.uop.rfWen = io_stin_bits_uop_rfWen;
    stin.uop.imm = io_stin_bits_uop_imm;
    stin.uop.pdest = io_stin_bits_uop_pdest;
    stin.uop.robIdx_flag = io_stin_bits_uop_robIdx_flag;
    stin.uop.robIdx_value = io_stin_bits_uop_robIdx_value;
    stin.uop.debugInfo_eliminatedMove = io_stin_bits_uop_debugInfo_eliminatedMove;
    stin.uop.debugInfo_renameTime = io_stin_bits_uop_debugInfo_renameTime;
    stin.uop.debugInfo_dispatchTime = io_stin_bits_uop_debugInfo_dispatchTime;
    stin.uop.debugInfo_enqRsTime = io_stin_bits_uop_debugInfo_enqRsTime;
    stin.uop.debugInfo_selectTime = io_stin_bits_uop_debugInfo_selectTime;
    stin.uop.debugInfo_issueTime = io_stin_bits_uop_debugInfo_issueTime;
    stin.uop.debugInfo_writebackTime = io_stin_bits_uop_debugInfo_writebackTime;
    stin.uop.debugInfo_runahead_checkpoint_id = io_stin_bits_uop_debugInfo_runahead_checkpoint_id;
    stin.uop.debugInfo_tlbFirstReqTime = io_stin_bits_uop_debugInfo_tlbFirstReqTime;
    stin.uop.debugInfo_tlbRespTime = io_stin_bits_uop_debugInfo_tlbRespTime;
    stin.uop.debug_seqNum_seqNum = io_stin_bits_uop_debug_seqNum_seqNum;
    stin.uop.debug_seqNum_uopIdx = io_stin_bits_uop_debug_seqNum_uopIdx;
    stin.uop.lqIdx_flag = io_stin_bits_uop_lqIdx_flag;
    stin.uop.lqIdx_value = io_stin_bits_uop_lqIdx_value;
    stin.uop.sqIdx_flag = io_stin_bits_uop_sqIdx_flag;
    stin.uop.sqIdx_value = io_stin_bits_uop_sqIdx_value;
    stin.src_0 = io_stin_bits_src_0;
    stin.isFirstIssue = io_stin_bits_isFirstIssue;
  end

  stin_t         issue;
  assign io_issue_bits_uop_robIdx_flag = issue.uop.robIdx_flag;
  assign io_issue_bits_uop_robIdx_value = issue.uop.robIdx_value;

  flow_t         misalign_stin;
  always_comb begin
    misalign_stin = '0;
    misalign_stin.uop.exceptionVec[0] = io_misalign_stin_bits_uop_exceptionVec_0;
    misalign_stin.uop.exceptionVec[1] = io_misalign_stin_bits_uop_exceptionVec_1;
    misalign_stin.uop.exceptionVec[2] = io_misalign_stin_bits_uop_exceptionVec_2;
    misalign_stin.uop.exceptionVec[4] = io_misalign_stin_bits_uop_exceptionVec_4;
    misalign_stin.uop.exceptionVec[5] = io_misalign_stin_bits_uop_exceptionVec_5;
    misalign_stin.uop.exceptionVec[8] = io_misalign_stin_bits_uop_exceptionVec_8;
    misalign_stin.uop.exceptionVec[9] = io_misalign_stin_bits_uop_exceptionVec_9;
    misalign_stin.uop.exceptionVec[10] = io_misalign_stin_bits_uop_exceptionVec_10;
    misalign_stin.uop.exceptionVec[11] = io_misalign_stin_bits_uop_exceptionVec_11;
    misalign_stin.uop.exceptionVec[12] = io_misalign_stin_bits_uop_exceptionVec_12;
    misalign_stin.uop.exceptionVec[13] = io_misalign_stin_bits_uop_exceptionVec_13;
    misalign_stin.uop.exceptionVec[14] = io_misalign_stin_bits_uop_exceptionVec_14;
    misalign_stin.uop.exceptionVec[16] = io_misalign_stin_bits_uop_exceptionVec_16;
    misalign_stin.uop.exceptionVec[17] = io_misalign_stin_bits_uop_exceptionVec_17;
    misalign_stin.uop.exceptionVec[18] = io_misalign_stin_bits_uop_exceptionVec_18;
    misalign_stin.uop.exceptionVec[19] = io_misalign_stin_bits_uop_exceptionVec_19;
    misalign_stin.uop.exceptionVec[20] = io_misalign_stin_bits_uop_exceptionVec_20;
    misalign_stin.uop.exceptionVec[21] = io_misalign_stin_bits_uop_exceptionVec_21;
    misalign_stin.uop.exceptionVec[22] = io_misalign_stin_bits_uop_exceptionVec_22;
    misalign_stin.uop.trigger = io_misalign_stin_bits_uop_trigger;
    misalign_stin.uop.ftqPtr_flag = io_misalign_stin_bits_uop_ftqPtr_flag;
    misalign_stin.uop.ftqPtr_value = io_misalign_stin_bits_uop_ftqPtr_value;
    misalign_stin.uop.ftqOffset = io_misalign_stin_bits_uop_ftqOffset;
    misalign_stin.uop.fuType = io_misalign_stin_bits_uop_fuType;
    misalign_stin.uop.fuOpType = io_misalign_stin_bits_uop_fuOpType;
    misalign_stin.uop.rfWen = io_misalign_stin_bits_uop_rfWen;
    misalign_stin.uop.vpu_vstart = io_misalign_stin_bits_uop_vpu_vstart;
    misalign_stin.uop.vpu_nf = io_misalign_stin_bits_uop_vpu_nf;
    misalign_stin.uop.vpu_veew = io_misalign_stin_bits_uop_vpu_veew;
    misalign_stin.uop.uopIdx = io_misalign_stin_bits_uop_uopIdx;
    misalign_stin.uop.pdest = io_misalign_stin_bits_uop_pdest;
    misalign_stin.uop.robIdx_flag = io_misalign_stin_bits_uop_robIdx_flag;
    misalign_stin.uop.robIdx_value = io_misalign_stin_bits_uop_robIdx_value;
    misalign_stin.uop.debugInfo_eliminatedMove = io_misalign_stin_bits_uop_debugInfo_eliminatedMove;
    misalign_stin.uop.debugInfo_renameTime = io_misalign_stin_bits_uop_debugInfo_renameTime;
    misalign_stin.uop.debugInfo_dispatchTime = io_misalign_stin_bits_uop_debugInfo_dispatchTime;
    misalign_stin.uop.debugInfo_enqRsTime = io_misalign_stin_bits_uop_debugInfo_enqRsTime;
    misalign_stin.uop.debugInfo_selectTime = io_misalign_stin_bits_uop_debugInfo_selectTime;
    misalign_stin.uop.debugInfo_issueTime = io_misalign_stin_bits_uop_debugInfo_issueTime;
    misalign_stin.uop.debugInfo_writebackTime = io_misalign_stin_bits_uop_debugInfo_writebackTime;
    misalign_stin.uop.debugInfo_runahead_checkpoint_id = io_misalign_stin_bits_uop_debugInfo_runahead_checkpoint_id;
    misalign_stin.uop.debugInfo_tlbFirstReqTime = io_misalign_stin_bits_uop_debugInfo_tlbFirstReqTime;
    misalign_stin.uop.debugInfo_tlbRespTime = io_misalign_stin_bits_uop_debugInfo_tlbRespTime;
    misalign_stin.uop.debug_seqNum_seqNum = io_misalign_stin_bits_uop_debug_seqNum_seqNum;
    misalign_stin.uop.debug_seqNum_uopIdx = io_misalign_stin_bits_uop_debug_seqNum_uopIdx;
    misalign_stin.uop.lqIdx_flag = io_misalign_stin_bits_uop_lqIdx_flag;
    misalign_stin.uop.lqIdx_value = io_misalign_stin_bits_uop_lqIdx_value;
    misalign_stin.uop.sqIdx_flag = io_misalign_stin_bits_uop_sqIdx_flag;
    misalign_stin.uop.sqIdx_value = io_misalign_stin_bits_uop_sqIdx_value;
    misalign_stin.vaddr = io_misalign_stin_bits_vaddr;
    misalign_stin.mask = io_misalign_stin_bits_mask;
    misalign_stin.isvec = io_misalign_stin_bits_isvec;
    misalign_stin.is128bit = io_misalign_stin_bits_is128bit;
    misalign_stin.isFinalSplit = io_misalign_stin_bits_isFinalSplit;
  end

  flow_t         misalign_stout;
  assign io_misalign_stout_bits_uop_exceptionVec_3 = misalign_stout.uop.exceptionVec[3];
  assign io_misalign_stout_bits_uop_exceptionVec_6 = misalign_stout.uop.exceptionVec[6];
  assign io_misalign_stout_bits_uop_exceptionVec_7 = misalign_stout.uop.exceptionVec[7];
  assign io_misalign_stout_bits_uop_exceptionVec_15 = misalign_stout.uop.exceptionVec[15];
  assign io_misalign_stout_bits_uop_exceptionVec_19 = misalign_stout.uop.exceptionVec[19];
  assign io_misalign_stout_bits_uop_exceptionVec_23 = misalign_stout.uop.exceptionVec[23];
  assign io_misalign_stout_bits_uop_trigger = misalign_stout.uop.trigger;
  assign io_misalign_stout_bits_uop_robIdx_flag = misalign_stout.uop.robIdx_flag;
  assign io_misalign_stout_bits_uop_robIdx_value = misalign_stout.uop.robIdx_value;
  assign io_misalign_stout_bits_vaddr = misalign_stout.vaddr;
  assign io_misalign_stout_bits_vaNeedExt = misalign_stout.vaNeedExt;
  assign io_misalign_stout_bits_paddr = misalign_stout.paddr;
  assign io_misalign_stout_bits_gpaddr = misalign_stout.gpaddr;
  assign io_misalign_stout_bits_nc = misalign_stout.nc;
  assign io_misalign_stout_bits_mmio = misalign_stout.mmio;
  assign io_misalign_stout_bits_memBackTypeMM = misalign_stout.memBackTypeMM;
  assign io_misalign_stout_bits_isForVSnonLeafPTE = misalign_stout.isForVSnonLeafPTE;
  assign io_misalign_stout_bits_vecActive = misalign_stout.vecActive;
  assign io_misalign_stout_bits_need_rep = misalign_stout.need_rep;

  tlb_req_t      tlb_req;
  assign io_tlb_req_bits_vaddr = tlb_req.vaddr;
  assign io_tlb_req_bits_fullva = tlb_req.fullva;
  assign io_tlb_req_bits_checkfullva = tlb_req.checkfullva;
  assign io_tlb_req_bits_cmd = tlb_req.cmd;
  assign io_tlb_req_bits_hyperinst = tlb_req.hyperinst;
  assign io_tlb_req_bits_memidx_idx = tlb_req.memidx_idx;
  assign io_tlb_req_bits_frm_mabuf = tlb_req.frm_mabuf;
  assign io_tlb_req_bits_debug_robIdx_flag = tlb_req.debug_robIdx_flag;
  assign io_tlb_req_bits_debug_robIdx_value = tlb_req.debug_robIdx_value;
  assign io_tlb_req_bits_debug_isFirstIssue = tlb_req.debug_isFirstIssue;

  tlb_resp_t     tlb_resp;
  always_comb begin
    tlb_resp = '0;
    tlb_resp.paddr_0 = io_tlb_resp_bits_paddr_0;
    tlb_resp.gpaddr_0 = io_tlb_resp_bits_gpaddr_0;
    tlb_resp.fullva = io_tlb_resp_bits_fullva;
    tlb_resp.pbmt_0 = io_tlb_resp_bits_pbmt_0;
    tlb_resp.miss = io_tlb_resp_bits_miss;
    tlb_resp.isForVSnonLeafPTE = io_tlb_resp_bits_isForVSnonLeafPTE;
    tlb_resp.excp_0_vaNeedExt = io_tlb_resp_bits_excp_0_vaNeedExt;
    tlb_resp.excp_0_isHyper = io_tlb_resp_bits_excp_0_isHyper;
    tlb_resp.excp_0_gpf_ld = io_tlb_resp_bits_excp_0_gpf_ld;
    tlb_resp.excp_0_gpf_st = io_tlb_resp_bits_excp_0_gpf_st;
    tlb_resp.excp_0_pf_ld = io_tlb_resp_bits_excp_0_pf_ld;
    tlb_resp.excp_0_pf_st = io_tlb_resp_bits_excp_0_pf_st;
    tlb_resp.excp_0_af_ld = io_tlb_resp_bits_excp_0_af_ld;
    tlb_resp.excp_0_af_st = io_tlb_resp_bits_excp_0_af_st;
    tlb_resp.ptwBack = io_tlb_resp_bits_ptwBack;
    tlb_resp.memidx_idx = io_tlb_resp_bits_memidx_idx;
  end

  pmp_t          pmp;
  always_comb begin
    pmp = '0;
    pmp.ld = io_pmp_ld;
    pmp.st = io_pmp_st;
    pmp.mmio = io_pmp_mmio;
  end

  flow_t         lsq;
  assign io_lsq_bits_uop_exceptionVec_0 = lsq.uop.exceptionVec[0];
  assign io_lsq_bits_uop_exceptionVec_1 = lsq.uop.exceptionVec[1];
  assign io_lsq_bits_uop_exceptionVec_2 = lsq.uop.exceptionVec[2];
  assign io_lsq_bits_uop_exceptionVec_3 = lsq.uop.exceptionVec[3];
  assign io_lsq_bits_uop_exceptionVec_4 = lsq.uop.exceptionVec[4];
  assign io_lsq_bits_uop_exceptionVec_5 = lsq.uop.exceptionVec[5];
  assign io_lsq_bits_uop_exceptionVec_6 = lsq.uop.exceptionVec[6];
  assign io_lsq_bits_uop_exceptionVec_7 = lsq.uop.exceptionVec[7];
  assign io_lsq_bits_uop_exceptionVec_8 = lsq.uop.exceptionVec[8];
  assign io_lsq_bits_uop_exceptionVec_9 = lsq.uop.exceptionVec[9];
  assign io_lsq_bits_uop_exceptionVec_10 = lsq.uop.exceptionVec[10];
  assign io_lsq_bits_uop_exceptionVec_11 = lsq.uop.exceptionVec[11];
  assign io_lsq_bits_uop_exceptionVec_12 = lsq.uop.exceptionVec[12];
  assign io_lsq_bits_uop_exceptionVec_13 = lsq.uop.exceptionVec[13];
  assign io_lsq_bits_uop_exceptionVec_14 = lsq.uop.exceptionVec[14];
  assign io_lsq_bits_uop_exceptionVec_15 = lsq.uop.exceptionVec[15];
  assign io_lsq_bits_uop_exceptionVec_16 = lsq.uop.exceptionVec[16];
  assign io_lsq_bits_uop_exceptionVec_17 = lsq.uop.exceptionVec[17];
  assign io_lsq_bits_uop_exceptionVec_18 = lsq.uop.exceptionVec[18];
  assign io_lsq_bits_uop_exceptionVec_19 = lsq.uop.exceptionVec[19];
  assign io_lsq_bits_uop_exceptionVec_20 = lsq.uop.exceptionVec[20];
  assign io_lsq_bits_uop_exceptionVec_21 = lsq.uop.exceptionVec[21];
  assign io_lsq_bits_uop_exceptionVec_22 = lsq.uop.exceptionVec[22];
  assign io_lsq_bits_uop_exceptionVec_23 = lsq.uop.exceptionVec[23];
  assign io_lsq_bits_uop_trigger = lsq.uop.trigger;
  assign io_lsq_bits_uop_ftqPtr_flag = lsq.uop.ftqPtr_flag;
  assign io_lsq_bits_uop_ftqPtr_value = lsq.uop.ftqPtr_value;
  assign io_lsq_bits_uop_ftqOffset = lsq.uop.ftqOffset;
  assign io_lsq_bits_uop_fuType = lsq.uop.fuType;
  assign io_lsq_bits_uop_fuOpType = lsq.uop.fuOpType;
  assign io_lsq_bits_uop_rfWen = lsq.uop.rfWen;
  assign io_lsq_bits_uop_vpu_nf = lsq.uop.vpu_nf;
  assign io_lsq_bits_uop_vpu_veew = lsq.uop.vpu_veew;
  assign io_lsq_bits_uop_uopIdx = lsq.uop.uopIdx;
  assign io_lsq_bits_uop_pdest = lsq.uop.pdest;
  assign io_lsq_bits_uop_robIdx_flag = lsq.uop.robIdx_flag;
  assign io_lsq_bits_uop_robIdx_value = lsq.uop.robIdx_value;
  assign io_lsq_bits_uop_debugInfo_eliminatedMove = lsq.uop.debugInfo_eliminatedMove;
  assign io_lsq_bits_uop_debugInfo_renameTime = lsq.uop.debugInfo_renameTime;
  assign io_lsq_bits_uop_debugInfo_dispatchTime = lsq.uop.debugInfo_dispatchTime;
  assign io_lsq_bits_uop_debugInfo_enqRsTime = lsq.uop.debugInfo_enqRsTime;
  assign io_lsq_bits_uop_debugInfo_selectTime = lsq.uop.debugInfo_selectTime;
  assign io_lsq_bits_uop_debugInfo_issueTime = lsq.uop.debugInfo_issueTime;
  assign io_lsq_bits_uop_debugInfo_writebackTime = lsq.uop.debugInfo_writebackTime;
  assign io_lsq_bits_uop_debugInfo_runahead_checkpoint_id = lsq.uop.debugInfo_runahead_checkpoint_id;
  assign io_lsq_bits_uop_debugInfo_tlbFirstReqTime = lsq.uop.debugInfo_tlbFirstReqTime;
  assign io_lsq_bits_uop_debugInfo_tlbRespTime = lsq.uop.debugInfo_tlbRespTime;
  assign io_lsq_bits_uop_debug_seqNum_seqNum = lsq.uop.debug_seqNum_seqNum;
  assign io_lsq_bits_uop_debug_seqNum_uopIdx = lsq.uop.debug_seqNum_uopIdx;
  assign io_lsq_bits_uop_sqIdx_flag = lsq.uop.sqIdx_flag;
  assign io_lsq_bits_uop_sqIdx_value = lsq.uop.sqIdx_value;
  assign io_lsq_bits_vaddr = lsq.vaddr;
  assign io_lsq_bits_fullva = lsq.fullva;
  assign io_lsq_bits_vaNeedExt = lsq.vaNeedExt;
  assign io_lsq_bits_paddr = lsq.paddr;
  assign io_lsq_bits_gpaddr = lsq.gpaddr;
  assign io_lsq_bits_mask = lsq.mask;
  assign io_lsq_bits_wlineflag = lsq.wlineflag;
  assign io_lsq_bits_miss = lsq.miss;
  assign io_lsq_bits_nc = lsq.nc;
  assign io_lsq_bits_isHyper = lsq.isHyper;
  assign io_lsq_bits_isForVSnonLeafPTE = lsq.isForVSnonLeafPTE;
  assign io_lsq_bits_isvec = lsq.isvec;
  assign io_lsq_bits_isFrmMisAlignBuf = lsq.isFrmMisAlignBuf;
  assign io_lsq_bits_isMisalign = lsq.isMisalign;
  assign io_lsq_bits_misalignWith16Byte = lsq.misalignWith16Byte;
  assign io_lsq_bits_updateAddrValid = lsq.updateAddrValid;

  flow_t         lsq_replenish;
  assign io_lsq_replenish_uop_exceptionVec_3 = lsq_replenish.uop.exceptionVec[3];
  assign io_lsq_replenish_uop_exceptionVec_6 = lsq_replenish.uop.exceptionVec[6];
  assign io_lsq_replenish_uop_exceptionVec_15 = lsq_replenish.uop.exceptionVec[15];
  assign io_lsq_replenish_uop_exceptionVec_19 = lsq_replenish.uop.exceptionVec[19];
  assign io_lsq_replenish_uop_exceptionVec_23 = lsq_replenish.uop.exceptionVec[23];
  assign io_lsq_replenish_uop_uopIdx = lsq_replenish.uop.uopIdx;
  assign io_lsq_replenish_uop_robIdx_flag = lsq_replenish.uop.robIdx_flag;
  assign io_lsq_replenish_uop_robIdx_value = lsq_replenish.uop.robIdx_value;
  assign io_lsq_replenish_fullva = lsq_replenish.fullva;
  assign io_lsq_replenish_vaNeedExt = lsq_replenish.vaNeedExt;
  assign io_lsq_replenish_gpaddr = lsq_replenish.gpaddr;
  assign io_lsq_replenish_af = lsq_replenish.af;
  assign io_lsq_replenish_mmio = lsq_replenish.mmio;
  assign io_lsq_replenish_memBackTypeMM = lsq_replenish.memBackTypeMM;
  assign io_lsq_replenish_hasException = lsq_replenish.hasException;
  assign io_lsq_replenish_isHyper = lsq_replenish.isHyper;
  assign io_lsq_replenish_isForVSnonLeafPTE = lsq_replenish.isForVSnonLeafPTE;
  assign io_lsq_replenish_isvec = lsq_replenish.isvec;
  assign io_lsq_replenish_updateAddrValid = lsq_replenish.updateAddrValid;

  feedback_t     feedback_slow;
  assign io_feedback_slow_bits_robIdx_flag = feedback_slow.robIdx_flag;
  assign io_feedback_slow_bits_robIdx_value = feedback_slow.robIdx_value;
  assign io_feedback_slow_bits_hit = feedback_slow.hit;
  assign io_feedback_slow_bits_flushState = feedback_slow.flushState;
  assign io_feedback_slow_bits_sqIdx_flag = feedback_slow.sqIdx_flag;
  assign io_feedback_slow_bits_sqIdx_value = feedback_slow.sqIdx_value;
  assign io_feedback_slow_bits_lqIdx_flag = feedback_slow.lqIdx_flag;
  assign io_feedback_slow_bits_lqIdx_value = feedback_slow.lqIdx_value;

  nuke_query_t   stld_nuke_query;
  assign io_stld_nuke_query_bits_robIdx_flag = stld_nuke_query.robIdx_flag;
  assign io_stld_nuke_query_bits_robIdx_value = stld_nuke_query.robIdx_value;
  assign io_stld_nuke_query_bits_paddr = stld_nuke_query.paddr;
  assign io_stld_nuke_query_bits_mask = stld_nuke_query.mask;
  assign io_stld_nuke_query_bits_matchType = stld_nuke_query.matchType;

  mem_out_t      stout;
  assign io_stout_bits_uop_exceptionVec_3 = stout.uop.exceptionVec[3];
  assign io_stout_bits_uop_exceptionVec_6 = stout.uop.exceptionVec[6];
  assign io_stout_bits_uop_exceptionVec_7 = stout.uop.exceptionVec[7];
  assign io_stout_bits_uop_exceptionVec_15 = stout.uop.exceptionVec[15];
  assign io_stout_bits_uop_exceptionVec_19 = stout.uop.exceptionVec[19];
  assign io_stout_bits_uop_exceptionVec_23 = stout.uop.exceptionVec[23];
  assign io_stout_bits_uop_trigger = stout.uop.trigger;
  assign io_stout_bits_uop_rfWen = stout.uop.rfWen;
  assign io_stout_bits_uop_pdest = stout.uop.pdest;
  assign io_stout_bits_uop_robIdx_flag = stout.uop.robIdx_flag;
  assign io_stout_bits_uop_robIdx_value = stout.uop.robIdx_value;
  assign io_stout_bits_uop_debugInfo_eliminatedMove = stout.uop.debugInfo_eliminatedMove;
  assign io_stout_bits_uop_debugInfo_renameTime = stout.uop.debugInfo_renameTime;
  assign io_stout_bits_uop_debugInfo_dispatchTime = stout.uop.debugInfo_dispatchTime;
  assign io_stout_bits_uop_debugInfo_enqRsTime = stout.uop.debugInfo_enqRsTime;
  assign io_stout_bits_uop_debugInfo_selectTime = stout.uop.debugInfo_selectTime;
  assign io_stout_bits_uop_debugInfo_issueTime = stout.uop.debugInfo_issueTime;
  assign io_stout_bits_uop_debugInfo_writebackTime = stout.uop.debugInfo_writebackTime;
  assign io_stout_bits_uop_debugInfo_runahead_checkpoint_id = stout.uop.debugInfo_runahead_checkpoint_id;
  assign io_stout_bits_uop_debugInfo_tlbFirstReqTime = stout.uop.debugInfo_tlbFirstReqTime;
  assign io_stout_bits_uop_debugInfo_tlbRespTime = stout.uop.debugInfo_tlbRespTime;
  assign io_stout_bits_uop_debug_seqNum_seqNum = stout.uop.debug_seqNum_seqNum;
  assign io_stout_bits_uop_debug_seqNum_uopIdx = stout.uop.debug_seqNum_uopIdx;
  assign io_stout_bits_uop_sqIdx_flag = stout.uop.sqIdx_flag;
  assign io_stout_bits_uop_sqIdx_value = stout.uop.sqIdx_value;
  assign io_stout_bits_debug_isMMIO = stout.debug_isMMIO;
  assign io_stout_bits_debug_isNCIO = stout.debug_isNCIO;
  assign io_stout_bits_debug_paddr = stout.debug_paddr;
  assign io_stout_bits_debug_vaddr = stout.debug_vaddr;

  vec_feedback_t vecstout;
  assign io_vecstout_bits_mBIndex = vecstout.mBIndex;
  assign io_vecstout_bits_hit = vecstout.hit;
  assign io_vecstout_bits_trigger = vecstout.trigger;
  assign io_vecstout_bits_exceptionVec_3 = vecstout.exceptionVec[3];
  assign io_vecstout_bits_exceptionVec_6 = vecstout.exceptionVec[6];
  assign io_vecstout_bits_exceptionVec_7 = vecstout.exceptionVec[7];
  assign io_vecstout_bits_exceptionVec_15 = vecstout.exceptionVec[15];
  assign io_vecstout_bits_exceptionVec_19 = vecstout.exceptionVec[19];
  assign io_vecstout_bits_exceptionVec_23 = vecstout.exceptionVec[23];
  assign io_vecstout_bits_hasException = vecstout.hasException;
  assign io_vecstout_bits_vaddr = vecstout.vaddr;
  assign io_vecstout_bits_vaNeedExt = vecstout.vaNeedExt;
  assign io_vecstout_bits_gpaddr = vecstout.gpaddr;
  assign io_vecstout_bits_isForVSnonLeafPTE = vecstout.isForVSnonLeafPTE;
  assign io_vecstout_bits_vstart = vecstout.vstart;
  assign io_vecstout_bits_elemIdx = vecstout.elemIdx;
  assign io_vecstout_bits_mask = vecstout.mask;
  assign io_vecstout_bits_splitIndex = vecstout.splitIndex;

  st_mask_t      st_mask_out;
  assign io_st_mask_out_bits_sqIdx_value = st_mask_out.sqIdx_value;
  assign io_st_mask_out_bits_mask = st_mask_out.mask;

  vec_in_t       vecstin;
  always_comb begin
    vecstin = '0;
    vecstin.vaddr = io_vecstin_bits_vaddr;
    vecstin.basevaddr = io_vecstin_bits_basevaddr;
    vecstin.mask = io_vecstin_bits_mask;
    vecstin.alignedType = io_vecstin_bits_alignedType;
    vecstin.vecActive = io_vecstin_bits_vecActive;
    vecstin.vecIsFirstActiveElement = io_vecstin_bits_vecIsFirstActiveElement;
    vecstin.uop.exceptionVec[4] = io_vecstin_bits_uop_exceptionVec_4;
    vecstin.uop.exceptionVec[5] = io_vecstin_bits_uop_exceptionVec_5;
    vecstin.uop.exceptionVec[6] = io_vecstin_bits_uop_exceptionVec_6;
    vecstin.uop.exceptionVec[13] = io_vecstin_bits_uop_exceptionVec_13;
    vecstin.uop.exceptionVec[19] = io_vecstin_bits_uop_exceptionVec_19;
    vecstin.uop.exceptionVec[21] = io_vecstin_bits_uop_exceptionVec_21;
    vecstin.uop.trigger = io_vecstin_bits_uop_trigger;
    vecstin.uop.ftqPtr_flag = io_vecstin_bits_uop_ftqPtr_flag;
    vecstin.uop.ftqPtr_value = io_vecstin_bits_uop_ftqPtr_value;
    vecstin.uop.ftqOffset = io_vecstin_bits_uop_ftqOffset;
    vecstin.uop.fuType = io_vecstin_bits_uop_fuType;
    vecstin.uop.fuOpType = io_vecstin_bits_uop_fuOpType;
    vecstin.uop.rfWen = io_vecstin_bits_uop_rfWen;
    vecstin.uop.vpu_vstart = io_vecstin_bits_uop_vpu_vstart;
    vecstin.uop.vpu_nf = io_vecstin_bits_uop_vpu_nf;
    vecstin.uop.vpu_veew = io_vecstin_bits_uop_vpu_veew;
    vecstin.uop.uopIdx = io_vecstin_bits_uop_uopIdx;
    vecstin.uop.pdest = io_vecstin_bits_uop_pdest;
    vecstin.uop.robIdx_flag = io_vecstin_bits_uop_robIdx_flag;
    vecstin.uop.robIdx_value = io_vecstin_bits_uop_robIdx_value;
    vecstin.uop.debugInfo_eliminatedMove = io_vecstin_bits_uop_debugInfo_eliminatedMove;
    vecstin.uop.debugInfo_renameTime = io_vecstin_bits_uop_debugInfo_renameTime;
    vecstin.uop.debugInfo_dispatchTime = io_vecstin_bits_uop_debugInfo_dispatchTime;
    vecstin.uop.debugInfo_enqRsTime = io_vecstin_bits_uop_debugInfo_enqRsTime;
    vecstin.uop.debugInfo_selectTime = io_vecstin_bits_uop_debugInfo_selectTime;
    vecstin.uop.debugInfo_issueTime = io_vecstin_bits_uop_debugInfo_issueTime;
    vecstin.uop.debugInfo_writebackTime = io_vecstin_bits_uop_debugInfo_writebackTime;
    vecstin.uop.debugInfo_runahead_checkpoint_id = io_vecstin_bits_uop_debugInfo_runahead_checkpoint_id;
    vecstin.uop.debugInfo_tlbFirstReqTime = io_vecstin_bits_uop_debugInfo_tlbFirstReqTime;
    vecstin.uop.debugInfo_tlbRespTime = io_vecstin_bits_uop_debugInfo_tlbRespTime;
    vecstin.uop.debug_seqNum_seqNum = io_vecstin_bits_uop_debug_seqNum_seqNum;
    vecstin.uop.debug_seqNum_uopIdx = io_vecstin_bits_uop_debug_seqNum_uopIdx;
    vecstin.uop.lqIdx_flag = io_vecstin_bits_uop_lqIdx_flag;
    vecstin.uop.lqIdx_value = io_vecstin_bits_uop_lqIdx_value;
    vecstin.uop.sqIdx_flag = io_vecstin_bits_uop_sqIdx_flag;
    vecstin.uop.sqIdx_value = io_vecstin_bits_uop_sqIdx_value;
    vecstin.mBIndex = io_vecstin_bits_mBIndex;
    vecstin.elemIdx = io_vecstin_bits_elemIdx;
    vecstin.splitIndex = io_vecstin_bits_splitIndex;
  end

  flow_t         misalign_enq_req;
  assign io_misalign_enq_req_bits_uop_exceptionVec_0 = misalign_enq_req.uop.exceptionVec[0];
  assign io_misalign_enq_req_bits_uop_exceptionVec_1 = misalign_enq_req.uop.exceptionVec[1];
  assign io_misalign_enq_req_bits_uop_exceptionVec_2 = misalign_enq_req.uop.exceptionVec[2];
  assign io_misalign_enq_req_bits_uop_exceptionVec_4 = misalign_enq_req.uop.exceptionVec[4];
  assign io_misalign_enq_req_bits_uop_exceptionVec_5 = misalign_enq_req.uop.exceptionVec[5];
  assign io_misalign_enq_req_bits_uop_exceptionVec_8 = misalign_enq_req.uop.exceptionVec[8];
  assign io_misalign_enq_req_bits_uop_exceptionVec_9 = misalign_enq_req.uop.exceptionVec[9];
  assign io_misalign_enq_req_bits_uop_exceptionVec_10 = misalign_enq_req.uop.exceptionVec[10];
  assign io_misalign_enq_req_bits_uop_exceptionVec_11 = misalign_enq_req.uop.exceptionVec[11];
  assign io_misalign_enq_req_bits_uop_exceptionVec_12 = misalign_enq_req.uop.exceptionVec[12];
  assign io_misalign_enq_req_bits_uop_exceptionVec_13 = misalign_enq_req.uop.exceptionVec[13];
  assign io_misalign_enq_req_bits_uop_exceptionVec_14 = misalign_enq_req.uop.exceptionVec[14];
  assign io_misalign_enq_req_bits_uop_exceptionVec_16 = misalign_enq_req.uop.exceptionVec[16];
  assign io_misalign_enq_req_bits_uop_exceptionVec_17 = misalign_enq_req.uop.exceptionVec[17];
  assign io_misalign_enq_req_bits_uop_exceptionVec_18 = misalign_enq_req.uop.exceptionVec[18];
  assign io_misalign_enq_req_bits_uop_exceptionVec_19 = misalign_enq_req.uop.exceptionVec[19];
  assign io_misalign_enq_req_bits_uop_exceptionVec_20 = misalign_enq_req.uop.exceptionVec[20];
  assign io_misalign_enq_req_bits_uop_exceptionVec_21 = misalign_enq_req.uop.exceptionVec[21];
  assign io_misalign_enq_req_bits_uop_exceptionVec_22 = misalign_enq_req.uop.exceptionVec[22];
  assign io_misalign_enq_req_bits_uop_trigger = misalign_enq_req.uop.trigger;
  assign io_misalign_enq_req_bits_uop_ftqPtr_flag = misalign_enq_req.uop.ftqPtr_flag;
  assign io_misalign_enq_req_bits_uop_ftqPtr_value = misalign_enq_req.uop.ftqPtr_value;
  assign io_misalign_enq_req_bits_uop_ftqOffset = misalign_enq_req.uop.ftqOffset;
  assign io_misalign_enq_req_bits_uop_fuType = misalign_enq_req.uop.fuType;
  assign io_misalign_enq_req_bits_uop_fuOpType = misalign_enq_req.uop.fuOpType;
  assign io_misalign_enq_req_bits_uop_rfWen = misalign_enq_req.uop.rfWen;
  assign io_misalign_enq_req_bits_uop_vpu_vstart = misalign_enq_req.uop.vpu_vstart;
  assign io_misalign_enq_req_bits_uop_vpu_nf = misalign_enq_req.uop.vpu_nf;
  assign io_misalign_enq_req_bits_uop_vpu_veew = misalign_enq_req.uop.vpu_veew;
  assign io_misalign_enq_req_bits_uop_uopIdx = misalign_enq_req.uop.uopIdx;
  assign io_misalign_enq_req_bits_uop_pdest = misalign_enq_req.uop.pdest;
  assign io_misalign_enq_req_bits_uop_robIdx_flag = misalign_enq_req.uop.robIdx_flag;
  assign io_misalign_enq_req_bits_uop_robIdx_value = misalign_enq_req.uop.robIdx_value;
  assign io_misalign_enq_req_bits_uop_debugInfo_eliminatedMove = misalign_enq_req.uop.debugInfo_eliminatedMove;
  assign io_misalign_enq_req_bits_uop_debugInfo_renameTime = misalign_enq_req.uop.debugInfo_renameTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_dispatchTime = misalign_enq_req.uop.debugInfo_dispatchTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_enqRsTime = misalign_enq_req.uop.debugInfo_enqRsTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_selectTime = misalign_enq_req.uop.debugInfo_selectTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_issueTime = misalign_enq_req.uop.debugInfo_issueTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_writebackTime = misalign_enq_req.uop.debugInfo_writebackTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_runahead_checkpoint_id = misalign_enq_req.uop.debugInfo_runahead_checkpoint_id;
  assign io_misalign_enq_req_bits_uop_debugInfo_tlbFirstReqTime = misalign_enq_req.uop.debugInfo_tlbFirstReqTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_tlbRespTime = misalign_enq_req.uop.debugInfo_tlbRespTime;
  assign io_misalign_enq_req_bits_uop_debug_seqNum_seqNum = misalign_enq_req.uop.debug_seqNum_seqNum;
  assign io_misalign_enq_req_bits_uop_debug_seqNum_uopIdx = misalign_enq_req.uop.debug_seqNum_uopIdx;
  assign io_misalign_enq_req_bits_uop_lqIdx_flag = misalign_enq_req.uop.lqIdx_flag;
  assign io_misalign_enq_req_bits_uop_lqIdx_value = misalign_enq_req.uop.lqIdx_value;
  assign io_misalign_enq_req_bits_uop_sqIdx_flag = misalign_enq_req.uop.sqIdx_flag;
  assign io_misalign_enq_req_bits_uop_sqIdx_value = misalign_enq_req.uop.sqIdx_value;
  assign io_misalign_enq_req_bits_vaddr = misalign_enq_req.vaddr;
  assign io_misalign_enq_req_bits_mask = misalign_enq_req.mask;
  assign io_misalign_enq_req_bits_isvec = misalign_enq_req.isvec;
  assign io_misalign_enq_req_bits_elemIdx = misalign_enq_req.elemIdx;
  assign io_misalign_enq_req_bits_alignedType = misalign_enq_req.alignedType;
  assign io_misalign_enq_req_bits_mbIndex = misalign_enq_req.mbIndex;
  assign io_misalign_enq_req_bits_splitIndex = misalign_enq_req.splitIndex;

  xs_StoreUnit_core u_core (
    .clock                                        (clock),
    .reset                                        (reset),
    .redirect_valid                               (io_redirect_valid),
    .redirect                                     (redirect),
    .csrCtrl_hd_misalign_st_enable                (io_csrCtrl_hd_misalign_st_enable),
    .stin_ready                                   (io_stin_ready),
    .stin_valid                                   (io_stin_valid),
    .stin                                         (stin),
    .issue_valid                                  (io_issue_valid),
    .issue                                        (issue),
    .misalign_stin_ready                          (io_misalign_stin_ready),
    .misalign_stin_valid                          (io_misalign_stin_valid),
    .misalign_stin                                (misalign_stin),
    .misalign_stout_valid                         (io_misalign_stout_valid),
    .misalign_stout                               (misalign_stout),
    .tlb_req_valid                                (io_tlb_req_valid),
    .tlb_req                                      (tlb_req),
    .tlb_resp_valid                               (io_tlb_resp_valid),
    .tlb_resp                                     (tlb_resp),
    .dcache_req_valid                             (io_dcache_req_valid),
    .pmp                                          (pmp),
    .lsq_valid                                    (io_lsq_valid),
    .lsq                                          (lsq),
    .lsq_replenish                                (lsq_replenish),
    .feedback_slow_valid                          (io_feedback_slow_valid),
    .feedback_slow                                (feedback_slow),
    .stld_nuke_query_valid                        (io_stld_nuke_query_valid),
    .stld_nuke_query                              (stld_nuke_query),
    .stout_valid                                  (io_stout_valid),
    .stout                                        (stout),
    .vecstout_valid                               (io_vecstout_valid),
    .vecstout                                     (vecstout),
    .st_mask_out_valid                            (io_st_mask_out_valid),
    .st_mask_out                                  (st_mask_out),
    .vecstin_ready                                (io_vecstin_ready),
    .vecstin_valid                                (io_vecstin_valid),
    .vecstin                                      (vecstin),
    .misalign_enq_req_ready                       (io_misalign_enq_req_ready),
    .misalign_enq_req_valid                       (io_misalign_enq_req_valid),
    .misalign_enq_req                             (misalign_enq_req),
    .misalign_enq_revoke                          (io_misalign_enq_revoke),
    .fromCsrTrigger_tdataVec_0_matchType          (io_fromCsrTrigger_tdataVec_0_matchType),
    .fromCsrTrigger_tdataVec_0_select             (io_fromCsrTrigger_tdataVec_0_select),
    .fromCsrTrigger_tdataVec_0_timing             (io_fromCsrTrigger_tdataVec_0_timing),
    .fromCsrTrigger_tdataVec_0_action             (io_fromCsrTrigger_tdataVec_0_action),
    .fromCsrTrigger_tdataVec_0_chain              (io_fromCsrTrigger_tdataVec_0_chain),
    .fromCsrTrigger_tdataVec_0_store              (io_fromCsrTrigger_tdataVec_0_store),
    .fromCsrTrigger_tdataVec_0_tdata2             (io_fromCsrTrigger_tdataVec_0_tdata2),
    .fromCsrTrigger_tdataVec_1_matchType          (io_fromCsrTrigger_tdataVec_1_matchType),
    .fromCsrTrigger_tdataVec_1_select             (io_fromCsrTrigger_tdataVec_1_select),
    .fromCsrTrigger_tdataVec_1_timing             (io_fromCsrTrigger_tdataVec_1_timing),
    .fromCsrTrigger_tdataVec_1_action             (io_fromCsrTrigger_tdataVec_1_action),
    .fromCsrTrigger_tdataVec_1_chain              (io_fromCsrTrigger_tdataVec_1_chain),
    .fromCsrTrigger_tdataVec_1_store              (io_fromCsrTrigger_tdataVec_1_store),
    .fromCsrTrigger_tdataVec_1_tdata2             (io_fromCsrTrigger_tdataVec_1_tdata2),
    .fromCsrTrigger_tdataVec_2_matchType          (io_fromCsrTrigger_tdataVec_2_matchType),
    .fromCsrTrigger_tdataVec_2_select             (io_fromCsrTrigger_tdataVec_2_select),
    .fromCsrTrigger_tdataVec_2_timing             (io_fromCsrTrigger_tdataVec_2_timing),
    .fromCsrTrigger_tdataVec_2_action             (io_fromCsrTrigger_tdataVec_2_action),
    .fromCsrTrigger_tdataVec_2_chain              (io_fromCsrTrigger_tdataVec_2_chain),
    .fromCsrTrigger_tdataVec_2_store              (io_fromCsrTrigger_tdataVec_2_store),
    .fromCsrTrigger_tdataVec_2_tdata2             (io_fromCsrTrigger_tdataVec_2_tdata2),
    .fromCsrTrigger_tdataVec_3_matchType          (io_fromCsrTrigger_tdataVec_3_matchType),
    .fromCsrTrigger_tdataVec_3_select             (io_fromCsrTrigger_tdataVec_3_select),
    .fromCsrTrigger_tdataVec_3_timing             (io_fromCsrTrigger_tdataVec_3_timing),
    .fromCsrTrigger_tdataVec_3_action             (io_fromCsrTrigger_tdataVec_3_action),
    .fromCsrTrigger_tdataVec_3_chain              (io_fromCsrTrigger_tdataVec_3_chain),
    .fromCsrTrigger_tdataVec_3_store              (io_fromCsrTrigger_tdataVec_3_store),
    .fromCsrTrigger_tdataVec_3_tdata2             (io_fromCsrTrigger_tdataVec_3_tdata2),
    .fromCsrTrigger_tEnableVec_0                  (io_fromCsrTrigger_tEnableVec_0),
    .fromCsrTrigger_tEnableVec_1                  (io_fromCsrTrigger_tEnableVec_1),
    .fromCsrTrigger_tEnableVec_2                  (io_fromCsrTrigger_tEnableVec_2),
    .fromCsrTrigger_tEnableVec_3                  (io_fromCsrTrigger_tEnableVec_3),
    .fromCsrTrigger_debugMode                     (io_fromCsrTrigger_debugMode),
    .fromCsrTrigger_triggerCanRaiseBpExp          (io_fromCsrTrigger_triggerCanRaiseBpExp),
    .sqCommitPtr_flag                             (io_sqCommitPtr_flag),
    .sqCommitPtr_value                            (io_sqCommitPtr_value),
    .sqCommitUopIdx                               (io_sqCommitUopIdx),
    .sqCommitRobIdx_flag                          (io_sqCommitRobIdx_flag),
    .sqCommitRobIdx_value                         (io_sqCommitRobIdx_value)
  );

endmodule
// END GENERATED(wrapper)
