// =====================================================================
// StoreMisalignBuffer.sv —— 跨 16 字节边界的非对齐 store：拆成两个对齐子访问交给 sta 流水查地址，
//                           跨 4KB 页时还要和 StoreQueue 配合出队（单条目缓冲）
// ---------------------------------------------------------------------
// 位置：MemBlock 里，2 条 StoreUnit（sta）共用 1 个；兄弟模块 LoadMisalignBuffer.sv 是 load 侧的同构件，
//   先读那一份更容易（本模块没有"拼数据"那一步：store 的数据由 StoreQueue 按拆分结果自己搬）。
// 与 StoreUnit / StoreQueue 的往返：
//   enq            ← StoreUnit s1 查出的"跨 16B 非对齐"store（两口挑最老的，隔一拍还可能被 revoke 撤回）；
//   splitStoreReq  → StoreUnit 的对齐子访问，照常走 TLB / PMP，只算地址；
//   splitStoreResp ← 子访问的地址结果（异常 / uncache / 要不要 replay）；
//   sqControl      ↔ StoreQueue：跨 4KB 页的 store 两半物理页不同，要等它到 ROB 头（rob.pendingst）才拆，
//                    写回后停在 s_block，等 StoreQueue 用第二页的 paddr 把数据写完（doDeq）再释放。
// 状态机（bufferState）：
//   s_idle → s_split → s_req（发 curPtr 指向的子访问）→ s_resp（等结果；两片都回来后**多等一拍**
//     让 RAW 违例检查对齐，再去 s_wb）→ s_wb（标量写 ROB / 向量写 vecWriteBack）
//     → 不跨页：s_idle；跨页：s_block（等 StoreQueue 的 doDeq）→ s_idle
//   子访问报异常或落在 uncache 空间：立刻 s_wb 带异常写回（uncache 一律报 storeAddrMisaligned 交软件）。
//   redirect 冲掉本条目、或入队下一拍被 revoke：回 s_idle。
// 本配置（KunminghuV2Config）下 firtool 删掉了：io.rob 的 mmio 口、overwriteExpBuf、needFlushPipe、
//   unWriteStores、拆分结果宽度 low/highResultWidth、splitStoreData（store 数据不经过这里），
//   以及 splitStoreResp 里除第二片 paddr 以外的全部字段；vecWriteBack.ready 在上层恒 1（fire == valid）。
// 文件结构：storemisalignbuffer_pkg → xs_StoreMisalignBuffer_core（手写可读核）→ golden 同名 wrapper（生成）。
//   GENERATED 段由 scripts/gen_smisalign.py 从 golden 端口表/寄存器表生成（--check 查漂移）。
// =====================================================================
// 本文件导航（按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位；行号由生成器维护）：
// BEGIN GENERATED(nav) —— scripts/gen_smisalign.py 生成，勿手改
//   L42    storemisalignbuffer_pkg：常量、状态编码、接口 struct、拆分方案表与小工具函数
//   L305   xs_StoreMisalignBuffer_core —— 可读核：全部状态
//   L393   §1 入队（两口选最老 / revoke / 跨页顶替）
//   L460   §2 状态机
//   L550   §3 拆分成两个对齐子访问
//   L573   §4 发请求
//   L586   §5 收响应：异常 / uncache / replay
//   L692   §6 写回与 StoreQueue 控制
//   L740   §7 整包寄存器（生成）
//   L1375  golden 同名 wrapper（生成）
// END GENERATED(nav)
// =====================================================================

package storemisalignbuffer_pkg;

  // ---------------- 常量 ----------------
  localparam int NUM_ENQ    = 2;        // StorePipelineWidth：两条 sta 流水
  localparam int NUM_VEC_WB = 2;        // VecStorePipelineWidth：向量写回两个口，按入队口号选

  // 访问宽度编码（fuOpType[1:0] / alignedType[1:0]）
  localparam logic [1:0] SZ_B = 2'b00;
  localparam logic [1:0] SZ_H = 2'b01;
  localparam logic [1:0] SZ_W = 2'b10;
  localparam logic [1:0] SZ_D = 2'b11;

  // 异常号（ExceptionNO）：StaCfg / VstuCfg 只产生这 6 个
  localparam int EXC_BREAKPOINT     = 3;
  localparam int EXC_ST_MISALIGN    = 6;    // storeAddrMisaligned
  localparam int EXC_ST_ACCESS      = 7;
  localparam int EXC_ST_PAGE        = 15;
  localparam int EXC_HW_ERROR       = 19;
  localparam int EXC_ST_GUEST_PAGE  = 23;
  localparam logic [23:0] STA_EXC_MASK = (24'h1 << EXC_BREAKPOINT) | (24'h1 << EXC_ST_MISALIGN)
                                       | (24'h1 << EXC_ST_ACCESS)  | (24'h1 << EXC_ST_PAGE)
                                       | (24'h1 << EXC_HW_ERROR)   | (24'h1 << EXC_ST_GUEST_PAGE);

  localparam logic [3:0] TRIG_ACT_DEBUG_MODE = 4'h1;   // TriggerAction.DebugMode

  // ---------------- 状态机 ----------------
  typedef enum logic [2:0] {
    S_IDLE  = 3'd0,   // 空闲 / 跨页时等本条到 ROB 头
    S_SPLIT = 3'd1,   // 拆成低 / 高两个对齐子访问
    S_REQ   = 3'd2,   // 发 curPtr 指向的子访问
    S_RESP  = 3'd3,   // 等子访问结果；两片齐了再等一拍
    S_WB    = 3'd4,   // 写回
    S_BLOCK = 3'd5    // 跨页：等 StoreQueue 出队（doDeq）
  } state_e;

  // BEGIN GENERATED(types) —— scripts/gen_smisalign.py 生成，勿手改
  // DynInst（后端微操作）在本模块出现过的全部字段；各接口只用其中一部分，其余在 wrapper 里补 0 / 丢弃
  typedef struct packed {
    logic [23:0]     exceptionVec;
    logic [3:0]      trigger;
    logic            ftqPtr_flag;
    logic [5:0]      ftqPtr_value;
    logic [3:0]      ftqOffset;
    logic [34:0]     fuType;
    logic [8:0]      fuOpType;
    logic            rfWen;
    logic [7:0]      vpu_vstart;
    logic [2:0]      vpu_nf;
    logic [1:0]      vpu_veew;
    logic [6:0]      uopIdx;
    logic [7:0]      pdest;
    logic            robIdx_flag;
    logic [7:0]      robIdx_value;
    logic            debugInfo_eliminatedMove;
    logic [63:0]     debugInfo_renameTime;
    logic [63:0]     debugInfo_dispatchTime;
    logic [63:0]     debugInfo_enqRsTime;
    logic [63:0]     debugInfo_selectTime;
    logic [63:0]     debugInfo_issueTime;
    logic [63:0]     debugInfo_writebackTime;
    logic [63:0]     debugInfo_runahead_checkpoint_id;
    logic [63:0]     debugInfo_tlbFirstReqTime;
    logic [63:0]     debugInfo_tlbRespTime;
    logic [55:0]     debug_seqNum_seqNum;
    logic [7:0]      debug_seqNum_uopIdx;
    logic            lqIdx_flag;
    logic [6:0]      lqIdx_value;
    logic            sqIdx_flag;
    logic [5:0]      sqIdx_value;
  } uop_t;

  // Redirect（后端重定向）：本模块只用 robIdx 与 level
  typedef struct packed {
    logic            robIdx_flag;
    logic [7:0]      robIdx_value;
    logic            level;
  } redirect_t;

  // MisalignBufferEnqIO.req：StoreUnit 送进来的非对齐 store（LsPipelineBundle 的子集）
  typedef struct packed {
    uop_t            uop;
    logic [49:0]     vaddr;
    logic [15:0]     mask;
    logic            isvec;
    logic [7:0]      elemIdx;
    logic [2:0]      alignedType;
    logic [3:0]      mbIndex;
    logic [4:0]      splitIndex;
  } enq_req_t;

  // RobLsqIO 里本模块用到的：ROB 头是否是一条等执行的 store（pendingst）及其 robIdx
  typedef struct packed {
    logic            pendingst;
    logic            pendingPtr_flag;
    logic [7:0]      pendingPtr_value;
  } rob_t;

  // LsPipelineBundle：发回 StoreUnit 的对齐子访问（两个子访问寄存器 splitStoreReqs 也是这个类型）
  typedef struct packed {
    uop_t            uop;
    logic [49:0]     vaddr;
    logic [15:0]     mask;
    logic            isvec;
    logic            is128bit;
    logic            isFinalSplit;
  } split_req_t;

  // SqWriteBundle：子访问的地址结果
  typedef struct packed {
    uop_t            uop;
    logic [49:0]     vaddr;
    logic            vaNeedExt;
    logic [47:0]     paddr;
    logic [63:0]     gpaddr;
    logic            nc;
    logic            mmio;
    logic            memBackTypeMM;
    logic            isForVSnonLeafPTE;
    logic            vecActive;
    logic            need_rep;
  } split_resp_t;

  // MemExuOutput：标量写回（写 ROB）
  typedef struct packed {
    uop_t            uop;
    logic            debug_isMMIO;
    logic            debug_isNCIO;
    logic [47:0]     debug_paddr;
    logic [49:0]     debug_vaddr;
  } wb_t;

  // VecPipelineFeedbackIO：向量元素写回（按入队口号选口）
  typedef struct packed {
    logic [3:0]      mBIndex;
    logic [23:0]     exceptionVec;
    logic            hasException;
    logic [63:0]     vaddr;
    logic            vaNeedExt;
    logic [63:0]     gpaddr;
    logic            isForVSnonLeafPTE;
    logic [7:0]      vstart;
    logic [7:0]      elemIdx;
    logic [15:0]     mask;
    logic [4:0]      splitIndex;
  } vec_wb_t;

  // StoreQueue → 本缓冲：出队许可 doDeq、当前出队指针、它正在处理的 uop
  typedef struct packed {
    logic            sqPtr_flag;
    logic [5:0]      sqPtr_value;
    logic            doDeq;
    uop_t            uop;
  } sq_to_mab_t;

  // 本缓冲 → StoreQueue：跨页条目的出队配合
  typedef struct packed {
    logic            crossPageWithHit;
    logic            crossPageCanDeq;
    logic [47:0]     paddr;
    logic            withSamePtr;
  } sq_to_sq_t;

  // 条目本体 req（StoreMisalignBufferEntry = LsPipelineBundle + portIndex）：字段 = golden 留下的 req_* 寄存器
  typedef struct packed {
    uop_t            uop;
    logic [49:0]     vaddr;
    logic            vaNeedExt;
    logic [47:0]     paddr;
    logic [63:0]     gpaddr;
    logic [15:0]     mask;
    logic            isForVSnonLeafPTE;
    logic            isvec;
    logic [7:0]      elemIdx;
    logic [2:0]      alignedType;
    logic [3:0]      mbIndex;
    logic [4:0]      splitIndex;
    logic            portIndex;
  } entry_t;
  // END GENERATED(types)

  // ---------------- 拆分方案 ----------------
  // 一个宽度为 size、起点为 vaddr 的非对齐 store，拆成两个"自然对齐"的子访问：
  //   低半：宽度 lo_size，起点 vaddr - lo_back；高半：宽度 hi_size，起点 vaddr + hi_fwd
  //   （hi_fwd = 原访问落在低半里的字节数）。与 load 侧不同：sd 的 101/110/111 三种偏移，
  //   低半取的是整 8 字节（起点往回退 5/6/7），不是 load 那样的 lw/lh/lb。
  // valid=0 的组合（sb，或本来就对齐的 sw、sd）跨 16B 时不可达（golden 只有断言）：
  //   两个子访问地址 / 掩码为 0、fuOpType 保持原值 —— 照 Chisel 的 switch 缺省行为原样保留。
  typedef struct packed {
    logic       valid;
    logic [1:0] lo_size;
    logic [2:0] lo_back;
    logic [1:0] hi_size;
    logic [2:0] hi_fwd;
  } split_plan_t;

  function automatic split_plan_t split_plan(logic [1:0] size, logic [2:0] off);
    split_plan_t p;
    p = '0;
    unique case (size)
      SZ_H: p = '{1'b1, SZ_B, 3'd0, SZ_B, 3'd1};
      SZ_W:
        unique case (off[1:0])
          2'b01:   p = '{1'b1, SZ_W, 3'd1, SZ_B, 3'd3};
          2'b10:   p = '{1'b1, SZ_H, 3'd0, SZ_H, 3'd2};
          2'b11:   p = '{1'b1, SZ_B, 3'd0, SZ_W, 3'd1};
          default: p = '0;
        endcase
      SZ_D:
        unique case (off)
          3'b001:  p = '{1'b1, SZ_D, 3'd1, SZ_B, 3'd7};
          3'b010:  p = '{1'b1, SZ_D, 3'd2, SZ_H, 3'd6};
          3'b011:  p = '{1'b1, SZ_D, 3'd3, SZ_W, 3'd5};
          3'b100:  p = '{1'b1, SZ_W, 3'd0, SZ_W, 3'd4};
          3'b101:  p = '{1'b1, SZ_D, 3'd5, SZ_D, 3'd3};
          3'b110:  p = '{1'b1, SZ_D, 3'd6, SZ_D, 3'd2};
          3'b111:  p = '{1'b1, SZ_D, 3'd7, SZ_D, 3'd1};
          default: p = '0;
        endcase
      default: p = '0;   // SZ_B：单字节不会非对齐
    endcase
    return p;
  endfunction

  // 访问宽度 → 字节掩码（未移位）
  function automatic logic [7:0] size_mask(logic [1:0] size);
    unique case (size)
      SZ_B:    return 8'h01;
      SZ_H:    return 8'h03;
      SZ_W:    return 8'h0F;
      default: return 8'hFF;
    endcase
  endfunction

  // 访问宽度 → 最后一个字节相对起点的偏移（size 字节数 - 1）
  function automatic logic [2:0] size_last_byte(logic [1:0] size);
    unique case (size)
      SZ_B:    return 3'd0;
      SZ_H:    return 3'd1;
      SZ_W:    return 3'd3;
      default: return 3'd7;
    endcase
  endfunction

  // 环形 robIdx 指针的新旧比较（HasCircularQueuePtrHelper）
  function automatic logic rob_is_after(logic [8:0] a, logic [8:0] b);        // a 比 b 年轻
    return a[8] ^ b[8] ^ (a[7:0] > b[7:0]);
  endfunction
  function automatic logic rob_is_not_before(logic [8:0] a, logic [8:0] b);   // a 不比 b 老
    return a[8] ^ b[8] ^ (a[7:0] >= b[7:0]);
  endfunction

  // RobPtr.needFlush(redirect)
  function automatic logic rob_need_flush(logic redir_valid, logic redir_level,
                                          logic [8:0] redir_rob, logic [8:0] rob);
    return redir_valid & (redir_level & (rob == redir_rob) | rob_is_after(rob, redir_rob));
  endfunction

  // Hypervisor store 标志（LSUOpType.isHsv）
  function automatic logic is_hsv(logic [8:0] op);
    return op[4] & ~op[5] & (op[8:7] == 2'b00);
  endfunction

endpackage

// =====================================================================
// xs_StoreMisalignBuffer_core —— 可读核
// =====================================================================
module xs_StoreMisalignBuffer_core
  import storemisalignbuffer_pkg::*;
(
  input  logic                          clock,
  input  logic                          reset,
  input  logic                          redirect_valid,
  input  redirect_t                     redirect,
  input  logic [NUM_ENQ-1:0]            enq_valid,
  input  enq_req_t [NUM_ENQ-1:0]        enq_bits,
  input  logic [NUM_ENQ-1:0]            enq_revoke,       // 入队下一拍 StoreUnit 撤回
  output logic [NUM_ENQ-1:0]            enq_ready,
  input  rob_t                          rob,              // ROB 头是不是一条等着执行的 store
  input  logic                          split_req_ready,
  output logic                          split_req_valid,
  output split_req_t                    split_req,
  input  logic                          split_resp_valid,
  input  split_resp_t                   split_resp,
  input  logic                          wb_ready,
  output logic                          wb_valid,
  output wb_t                           wb,
  output logic [NUM_VEC_WB-1:0]         vec_wb_valid,
  output vec_wb_t [NUM_VEC_WB-1:0]      vec_wb,
  input  logic                          store_out_valid,      // StoreUnit 本拍自己要写回：让路
  input  logic                          store_vec_out_valid,  // 同上，向量写回口
  input  sq_to_mab_t                    sq_in,                // StoreQueue → 本缓冲
  output sq_to_sq_t                     sq_out,               // 本缓冲 → StoreQueue
  output logic                          to_vec_split_empty    // 缓冲空（告诉向量拆分单元）
);

  // ===================================================================
  // 本模块的全部状态（寄存器名与 golden 逐个相同，便于对照）
  // ===================================================================
  // 条目本体：入队那一拍锁存的 store（LsPipelineBundle 子集 + 入队口号 portIndex）
  entry_t      req, req_nxt;
  // 两个对齐子访问，s_split 时算好存下，s_req 按 curPtr 发出
  split_req_t  split_reqs [2];
  split_req_t  split_new  [2];
  logic        split_now;

  logic        req_valid;
  state_e      bufferState;
  logic        s2_canEnq;               // 上一拍真的入队了（revoke 只在入队的下一拍有效）
  logic        s2_reqSelPort_next_r;    // 上一拍选中的入队口号（GatedRegNext，复位 0）
  logic        isCrossPage;             // 本条跨 4KB 页（在 s_idle 离开时确定）
  logic [1:0]  unSentStores;            // 还没成功回来的子访问（按下标置位）
  logic        curPtr;                  // 当前在处理第几个子访问
  logic        globalException;         // 某个子访问报了异常
  logic        globalUncache;           // 某个子访问落在 MMIO / NC 空间
  logic        globalMMIO;              // 以下三个只进 debug
  logic        globalNC;
  logic        globalMemBackTypeMM;
  logic [47:0] splitStoreResp_1_paddr;  // 第二片（高地址页）的物理地址：跨页时 StoreQueue 用它写第二页
  // 累计异常：只有 StaCfg 的 6 位（3/6/7/15/19/23）是寄存器
  logic        exceptionVec_3, exceptionVec_6, exceptionVec_7;
  logic        exceptionVec_15, exceptionVec_19, exceptionVec_23;
  logic        REG;                     // RegNextN(needDelay, 1)：两片都回来后多等的那一拍
  logic        REG_1;                   // RegNext(!req_valid)：只给 perf 计数 "alloc" 用，本配置无出口

  // 整包寄存器 req / split_reqs 的逐字段声明与读写在核末尾 §7（生成）

  logic [23:0] exc_q, exc_d;
  always_comb begin
    exc_q = '0;
    exc_q[EXC_BREAKPOINT]    = exceptionVec_3;
    exc_q[EXC_ST_MISALIGN]   = exceptionVec_6;
    exc_q[EXC_ST_ACCESS]     = exceptionVec_7;
    exc_q[EXC_ST_PAGE]       = exceptionVec_15;
    exc_q[EXC_HW_ERROR]      = exceptionVec_19;
    exc_q[EXC_ST_GUEST_PAGE] = exceptionVec_23;
  end

  logic [8:0] req_rob;
  assign req_rob = {req.uop.robIdx_flag, req.uop.robIdx_value};

  // 跨 16B / 跨 4KB 页（req 的最后一个字节与第一个字节是否落在不同块 / 页）
  logic [1:0]  aligned_size;
  logic [4:0]  high_addr;
  logic [12:0] high_page_addr;
  logic        cross16, cross4k;
  assign aligned_size   = req.isvec ? req.alignedType[1:0] : req.uop.fuOpType[1:0];
  assign high_addr      = 5'(size_last_byte(aligned_size)) + req.vaddr[4:0];
  assign high_page_addr = 13'(size_last_byte(aligned_size)) + req.vaddr[12:0];
  assign cross16        = req_valid & (high_addr[4] != req.vaddr[4]);
  assign cross4k        = req_valid & (high_page_addr[12] != req.vaddr[12]);

  // ===================================================================
  // §1 入队：两口挑最老的一条；空闲时收，或跨页条目还没开拆时被更老的 store 顶替
  // ===================================================================
  // selectOldest 选"包"（bits/valid）与选"口号"（index）在 Chisel 里写法不同：前者 isAfter || isNotBefore && uopIdx>，
  //   后者 isAfter || robIdx相等 && uopIdx>。在 isAfter 为假时 isNotBefore 就等价于"相等"，所以两者逻辑相同；
  //   这里照 Chisel 分开写，便于对照。
  logic        both_valid, pick1_bits, pick1_port, sel_valid, sel_port;
  enq_req_t    sel;
  logic [8:0]  rob0, rob1, sel_rob;
  always_comb begin
    rob0 = {enq_bits[0].uop.robIdx_flag, enq_bits[0].uop.robIdx_value};
    rob1 = {enq_bits[1].uop.robIdx_flag, enq_bits[1].uop.robIdx_value};
    both_valid = enq_valid[0] & enq_valid[1];
    pick1_bits = both_valid ? rob_is_after(rob0, rob1)
                              | rob_is_not_before(rob0, rob1) & (enq_bits[0].uop.uopIdx > enq_bits[1].uop.uopIdx)
                            : ~(enq_valid[0] & ~enq_valid[1]);
    pick1_port = both_valid ? rob_is_after(rob0, rob1)
                              | (rob0 == rob1) & (enq_bits[0].uop.uopIdx > enq_bits[1].uop.uopIdx)
                            : ~(enq_valid[0] & ~enq_valid[1]);
    sel       = pick1_bits ? enq_bits[1] : enq_bits[0];
    sel_valid = pick1_bits ? enq_valid[1] : enq_valid[0];
    sel_port  = pick1_port;
    sel_rob   = {sel.uop.robIdx_flag, sel.uop.robIdx_value};
  end

  logic sel_redirected;       // 选中者被本拍 redirect 冲掉
  logic sel_older_than_req;   // 跨页条目在 s_idle 等 ROB 头时，来了一条更老的：顶替它
  logic cross_replace;        // 顶替成立
  logic can_enq;              // 本拍写入条目（新入队或顶替）
  logic req_we;               // req 写使能
  assign sel_redirected = rob_need_flush(redirect_valid, redirect.level,
                                         {redirect.robIdx_flag, redirect.robIdx_value}, sel_rob);
  assign sel_older_than_req = sel_valid
                            & (rob_is_after(req_rob, sel_rob)
                               | rob_is_not_before(req_rob, sel_rob) & (req.uop.uopIdx > sel.uop.uopIdx))
                            & (bufferState == S_IDLE);
  assign cross_replace = cross4k & ~sel_redirected & sel_older_than_req;
  assign can_enq       = cross_replace | ~req_valid & ~sel_redirected & sel_valid;
  // Chisel 的写法是 when(canEnq){req := sel}，随后 when(跨页 && !redirect){ 顶替 ? req := sel : req := req }，
  // 后一句覆盖前一句 —— 所以跨页期间只有"顶替"能写 req
  assign req_we = (cross4k & ~sel_redirected) ? sel_older_than_req : can_enq;

  always_comb
    for (int i = 0; i < NUM_ENQ; i++)
      enq_ready[i] = (sel_port == 1'(i)) & (~req_valid | cross4k & cross_replace);

  // 入队的下一拍：StoreUnit 可能 revoke（撤回）刚入的那条
  logic s2_needRevoke;
  assign s2_needRevoke = s2_canEnq & enq_revoke[s2_reqSelPort_next_r];

  always_ff @(posedge clock) begin
    s2_canEnq <= can_enq;
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset) s2_reqSelPort_next_r <= 1'b0;
    else       s2_reqSelPort_next_r <= sel_port;
  end

  // ROB 头就是本条 store（跨页的 store 要等到这时才开拆）
  logic rob_match;
  assign rob_match = req_valid & rob.pendingst & ({rob.pendingPtr_flag, rob.pendingPtr_value} == req_rob);

  logic flush, kill;
  assign flush = req_valid & rob_need_flush(redirect_valid, redirect.level,
                                            {redirect.robIdx_flag, redirect.robIdx_value}, req_rob);
  assign kill  = flush | s2_needRevoke;

  // ===================================================================
  // §2 状态机
  // ===================================================================
  logic resp_has_exc, resp_uncache, resp_abort, resp_more;
  // store 的异常 / uncache 判定都要求"不需要 replay"（与 load 侧不同）
  assign resp_has_exc = split_resp.vecActive & ~split_resp.need_rep
                        & (|(split_resp.uop.exceptionVec & STA_EXC_MASK))
                      | split_resp.uop.trigger == TRIG_ACT_DEBUG_MODE;
  assign resp_uncache = (split_resp.mmio | split_resp.nc) & ~split_resp.need_rep;
  assign resp_abort   = resp_has_exc | resp_uncache;
  assign resp_more    = split_resp.need_rep | (|(unSentStores & ~(2'b01 << curPtr)));   // 要重发 / 另一片没发

  logic resp_match;   // 响应属于本条目（数据 / 指针 / 异常的更新要核对 robIdx；状态转移不核对）
  assign resp_match = split_resp_valid & (bufferState == S_RESP)
                    & (req_rob == {split_resp.uop.robIdx_flag, split_resp.uop.robIdx_value});

  // needDelay：两片都成功回来。★怪癖★ Chisel 里这根 WireInit 声明在 is(s_resp) 分支里，
  // 分支外没有驱动（invalid），firtool 就把 "bufferState === s_resp" 这个条件优化掉了 ——
  // golden 的 REG 在任何状态下都按响应口打拍。照抄。
  logic need_delay;
  assign need_delay = split_resp_valid & ~resp_abort & ~resp_more;

  logic split_req_fire, wb_any, wb_release, block_release;
  assign split_req_fire = split_req_ready & split_req_valid;
  // 写回握手：向量两个口任一（ready 恒 1），或标量口 fire
  assign wb_any         = req.isvec & (|vec_wb_valid) | wb_ready & wb_valid;
  assign wb_release     = (bufferState == S_WB) & wb_any & (~isCrossPage | globalUncache | globalException);
  assign block_release  = (bufferState == S_BLOCK) & sq_in.doDeq;

  state_e bufferState_nxt;
  logic   req_valid_nxt, isCrossPage_nxt;
  always_comb begin
    bufferState_nxt = bufferState;
    isCrossPage_nxt = isCrossPage;
    unique case (bufferState)
      S_IDLE:
        if (cross4k & ~s2_needRevoke) begin
          if (rob_match) begin                       // 跨页：等到 ROB 头才拆
            bufferState_nxt = S_SPLIT;
            isCrossPage_nxt = 1'b1;
          end
        end else if (req_valid & ~s2_needRevoke) begin
          bufferState_nxt = S_SPLIT;
          isCrossPage_nxt = 1'b0;
        end
      S_SPLIT: bufferState_nxt = S_REQ;
      S_REQ:   if (split_req_fire) bufferState_nxt = S_RESP;
      S_RESP: begin
        if (split_resp_valid) begin
          if (resp_abort)     bufferState_nxt = S_WB;
          else if (resp_more) bufferState_nxt = S_REQ;
          // 否则：两片齐了，留在 s_resp 等一拍
        end
        if (REG) bufferState_nxt = S_WB;             // 等的那一拍到了
      end
      S_WB:
        if (wb_release)  bufferState_nxt = S_IDLE;
        else if (wb_any) bufferState_nxt = S_BLOCK;  // 跨页且正常写回：等 StoreQueue
      S_BLOCK: if (block_release) bufferState_nxt = S_IDLE;
      default: ;                                     // 6/7 不可达，保持
    endcase
    if (wb_release | block_release) isCrossPage_nxt = 1'b0;
    if (kill) begin
      bufferState_nxt = S_IDLE;
      isCrossPage_nxt = 1'b0;
    end

    req_valid_nxt = req_valid;
    if (can_enq)                      req_valid_nxt = 1'b1;
    if (wb_release | block_release)   req_valid_nxt = 1'b0;
    if (kill)                         req_valid_nxt = 1'b0;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      req_valid   <= 1'b0;
      bufferState <= S_IDLE;
      isCrossPage <= 1'b0;
    end else begin
      req_valid   <= req_valid_nxt;
      bufferState <= bufferState_nxt;
      isCrossPage <= isCrossPage_nxt;
    end
  end

  always_ff @(posedge clock) begin
    REG   <= need_delay;
    REG_1 <= ~req_valid;
  end

  // ===================================================================
  // §3 拆分：s_split 这一拍把 req 拆成低 / 高两个对齐子访问
  // ===================================================================
  split_plan_t plan;
  assign plan      = split_plan(aligned_size, req.vaddr[2:0]);
  assign split_now = (bufferState == S_SPLIT) & cross16;

  always_comb begin
    for (int k = 0; k < 2; k++) begin
      split_new[k]     = '0;
      split_new[k].uop = req.uop;
      split_new[k].uop.exceptionVec[EXC_ST_MISALIGN] = 1'b0;
    end
    if (plan.valid) begin
      split_new[0].uop.fuOpType = 9'(plan.lo_size);
      split_new[0].vaddr        = req.vaddr - 50'(plan.lo_back);
      split_new[1].uop.fuOpType = 9'(plan.hi_size);
      split_new[1].vaddr        = req.vaddr + 50'(plan.hi_fwd);
    end
    split_new[0].mask = plan.valid ? 16'(16'(size_mask(plan.lo_size)) << split_new[0].vaddr[3:0]) : 16'h0;
    split_new[1].mask = plan.valid ? 16'(16'(size_mask(plan.hi_size)) << split_new[1].vaddr[3:0]) : 16'h0;
  end

  // ===================================================================
  // §4 发请求
  // ===================================================================
  always_comb begin
    split_req_valid        = req_valid & (bufferState == S_REQ);
    split_req              = split_reqs[curPtr];
    split_req.isvec        = req.isvec;
    split_req.isFinalSplit = curPtr;
    // 向量：fuOpType 原样用 req 的；标量：宽度换成子访问的，恢复 hsv 标志（{hsv, 00, size}）
    split_req.uop.fuOpType = req.isvec ? req.uop.fuOpType
                           : {4'b0000, is_hsv(req.uop.fuOpType), 2'b00, split_reqs[curPtr].uop.fuOpType[1:0]};
  end

  // ===================================================================
  // §5 收响应：推进 curPtr / unSentStores、累计异常；异常 / uncache 时改写 req 的地址、记全局标志
  // ===================================================================
  logic [1:0] unSentStores_nxt;
  logic       curPtr_nxt;
  always_comb begin
    unSentStores_nxt = unSentStores;
    curPtr_nxt       = curPtr;
    exc_d            = exc_q;        // 注意：store 侧拆分时不清异常累计（与 load 侧不同），照抄
    if (wb_release | block_release) begin
      unSentStores_nxt = 2'b00;
      curPtr_nxt       = 1'b0;
    end
    if (split_now) begin
      unSentStores_nxt = 2'b11;
      curPtr_nxt       = 1'b0;
    end
    if (resp_match) begin
      if (resp_uncache) begin
        unSentStores_nxt = 2'b00;
        exc_d            = '0;
        exc_d[EXC_ST_MISALIGN] = 1'b1;     // uncache：改报 storeAddrMisaligned 交软件
      end else if (resp_has_exc) begin
        unSentStores_nxt = 2'b00;
        exc_d            = exc_q | (split_resp.uop.exceptionVec & STA_EXC_MASK);
      end else if (!split_resp.need_rep) begin
        unSentStores_nxt = unSentStores & ~(2'b01 << curPtr);
        curPtr_nxt       = curPtr + 1'b1;
        exc_d            = '0;
      end
    end
    if (kill) begin
      unSentStores_nxt = 2'b00;
      curPtr_nxt       = 1'b0;
    end
  end

  logic gExc_nxt, gUnc_nxt, gMMIO_nxt, gNC_nxt, gMM_nxt;
  always_comb begin
    {gExc_nxt, gUnc_nxt, gMMIO_nxt, gNC_nxt, gMM_nxt} =
      {globalException, globalUncache, globalMMIO, globalNC, globalMemBackTypeMM};
    if ((bufferState == S_RESP) & split_resp_valid & resp_abort)
      {gExc_nxt, gUnc_nxt, gMMIO_nxt, gNC_nxt, gMM_nxt} =
        {resp_has_exc, resp_uncache, split_resp.mmio, split_resp.nc, split_resp.memBackTypeMM};
    if (wb_release | block_release | kill)
      {gExc_nxt, gUnc_nxt, gMMIO_nxt, gNC_nxt, gMM_nxt} = '0;
  end

  // req 的次态：入队 / 顶替整包写入（入队口没有的字段写 0）；robIdx 对上的异常 / uncache 响应改写地址
  always_comb begin
    req_nxt = req;
    if (req_we) begin
      req_nxt                = '0;
      req_nxt.uop            = sel.uop;
      req_nxt.vaddr          = sel.vaddr;
      req_nxt.mask           = sel.mask;
      req_nxt.isvec          = sel.isvec;
      req_nxt.elemIdx        = sel.elemIdx;
      req_nxt.alignedType    = sel.alignedType;
      req_nxt.mbIndex        = sel.mbIndex;
      req_nxt.splitIndex     = sel.splitIndex;
      req_nxt.portIndex      = sel_port;
    end
    if (resp_match & resp_abort) begin
      req_nxt.vaddr             = split_resp.vaddr;
      req_nxt.vaNeedExt         = split_resp.vaNeedExt;
      req_nxt.paddr             = split_resp.paddr;
      req_nxt.gpaddr            = split_resp.gpaddr;
      req_nxt.isForVSnonLeafPTE = split_resp.isForVSnonLeafPTE;
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      unSentStores           <= 2'b00;
      curPtr                 <= 1'b0;
      globalException        <= 1'b0;
      globalUncache          <= 1'b0;
      globalMMIO             <= 1'b0;
      globalNC               <= 1'b0;
      globalMemBackTypeMM    <= 1'b0;
      exceptionVec_3         <= 1'b0;
      exceptionVec_6         <= 1'b0;
      exceptionVec_7         <= 1'b0;
      exceptionVec_15        <= 1'b0;
      exceptionVec_19        <= 1'b0;
      exceptionVec_23        <= 1'b0;
      splitStoreResp_1_paddr <= 48'h0;
    end else begin
      unSentStores           <= unSentStores_nxt;
      curPtr                 <= curPtr_nxt;
      globalException        <= gExc_nxt;
      globalUncache          <= gUnc_nxt;
      globalMMIO             <= gMMIO_nxt;
      globalNC               <= gNC_nxt;
      globalMemBackTypeMM    <= gMM_nxt;
      exceptionVec_3         <= exc_d[EXC_BREAKPOINT];
      exceptionVec_6         <= exc_d[EXC_ST_MISALIGN];
      exceptionVec_7         <= exc_d[EXC_ST_ACCESS];
      exceptionVec_15        <= exc_d[EXC_ST_PAGE];
      exceptionVec_19        <= exc_d[EXC_HW_ERROR];
      exceptionVec_23        <= exc_d[EXC_ST_GUEST_PAGE];
      if (resp_match & curPtr) splitStoreResp_1_paddr <= split_resp.paddr;
    end
  end

  // ===================================================================
  // §6 写回与 StoreQueue 控制
  // ===================================================================
  logic abort_wb;
  assign abort_wb = globalUncache | globalException;

  always_comb begin
    wb_valid = req_valid & (bufferState == S_WB) & ~store_out_valid & ~req.isvec;
    wb                   = '0;
    wb.uop               = req.uop;
    wb.uop.exceptionVec  = abort_wb ? (exc_q & STA_EXC_MASK) : 24'h0;
    // （Chisel 还把 flushPipe / replayInst 置 0、rfWen 照原值；前两者本配置没有端口）
    wb.debug_isMMIO      = globalMMIO;
    wb.debug_isNCIO      = globalNC & ~globalMemBackTypeMM;
    wb.debug_paddr       = req.paddr;
    wb.debug_vaddr       = req.vaddr;

    // 向量写回：只走入队时那个口（portIndex）
    for (int i = 0; i < NUM_VEC_WB; i++) begin
      vec_wb_valid[i] = req_valid & (bufferState == S_WB) & req.isvec & ~store_vec_out_valid
                      & (req.portIndex == 1'(i));
      vec_wb[i]                   = '0;
      vec_wb[i].mBIndex           = req.mbIndex;
      vec_wb[i].exceptionVec      = exc_q & STA_EXC_MASK;   // VstuCfg 与 StaCfg 同 6 位
      vec_wb[i].hasException      = globalException;
      vec_wb[i].vaddr             = 64'(req.vaddr);
      vec_wb[i].vaNeedExt         = req.vaNeedExt;
      vec_wb[i].gpaddr            = req.gpaddr;
      vec_wb[i].isForVSnonLeafPTE = req.isForVSnonLeafPTE;
      vec_wb[i].vstart            = req.uop.vpu_vstart;
      vec_wb[i].elemIdx           = req.elemIdx;
      vec_wb[i].mask              = req.mask;
      vec_wb[i].splitIndex        = req.splitIndex;
    end

    // StoreQueue：跨页条目命中它的出队指针 / 可以出队 / 第二页地址（8 字节对齐）/ 向量同一 uop
    sq_out = '0;
    sq_out.crossPageWithHit = ({sq_in.sqPtr_flag, sq_in.sqPtr_value}
                               == {req.uop.sqIdx_flag, req.uop.sqIdx_value}) & isCrossPage & req_valid;
    sq_out.crossPageCanDeq  = bufferState == S_BLOCK;
    sq_out.paddr            = {splitStoreResp_1_paddr[47:3], 3'b000};
    sq_out.withSamePtr      = ({sq_in.uop.robIdx_flag, sq_in.uop.robIdx_value} == req_rob)
                            & (sq_in.uop.uopIdx == req.uop.uopIdx) & req.isvec & rob_match
                            & isCrossPage & (bufferState == S_BLOCK);

    to_vec_split_empty = ~req_valid;
  end

  // ===================================================================
  // §7 整包寄存器（生成）：req / splitStoreReqs_0/1 按 golden 留下的字段逐个存
  // ===================================================================
  // 字段集合 = golden 的 reg 声明（firtool 删掉了读不到 / 恒 0 的字段）；
  // 核里其余逻辑只通过 struct 视图 req / split_reqs 读、通过 req_nxt / split_new 写。
  // BEGIN GENERATED(regs) —— scripts/gen_smisalign.py 生成，勿手改
  // ---- req：入队 / 顶替时整包锁存，子访问异常时改写地址字段（无复位；次态 req_nxt 见 §5）：golden 留下的 61 个字段 ----
  logic           req_uop_exceptionVec_0;
  logic           req_uop_exceptionVec_1;
  logic           req_uop_exceptionVec_2;
  logic           req_uop_exceptionVec_4;
  logic           req_uop_exceptionVec_5;
  logic           req_uop_exceptionVec_8;
  logic           req_uop_exceptionVec_9;
  logic           req_uop_exceptionVec_10;
  logic           req_uop_exceptionVec_11;
  logic           req_uop_exceptionVec_12;
  logic           req_uop_exceptionVec_13;
  logic           req_uop_exceptionVec_14;
  logic           req_uop_exceptionVec_16;
  logic           req_uop_exceptionVec_17;
  logic           req_uop_exceptionVec_18;
  logic           req_uop_exceptionVec_19;
  logic           req_uop_exceptionVec_20;
  logic           req_uop_exceptionVec_21;
  logic           req_uop_exceptionVec_22;
  logic [3:0]     req_uop_trigger;
  logic           req_uop_ftqPtr_flag;
  logic [5:0]     req_uop_ftqPtr_value;
  logic [3:0]     req_uop_ftqOffset;
  logic [34:0]    req_uop_fuType;
  logic [8:0]     req_uop_fuOpType;
  logic           req_uop_rfWen;
  logic [7:0]     req_uop_vpu_vstart;
  logic [2:0]     req_uop_vpu_nf;
  logic [1:0]     req_uop_vpu_veew;
  logic [6:0]     req_uop_uopIdx;
  logic [7:0]     req_uop_pdest;
  logic           req_uop_robIdx_flag;
  logic [7:0]     req_uop_robIdx_value;
  logic           req_uop_debugInfo_eliminatedMove;
  logic [63:0]    req_uop_debugInfo_renameTime;
  logic [63:0]    req_uop_debugInfo_dispatchTime;
  logic [63:0]    req_uop_debugInfo_enqRsTime;
  logic [63:0]    req_uop_debugInfo_selectTime;
  logic [63:0]    req_uop_debugInfo_issueTime;
  logic [63:0]    req_uop_debugInfo_writebackTime;
  logic [63:0]    req_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]    req_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]    req_uop_debugInfo_tlbRespTime;
  logic [55:0]    req_uop_debug_seqNum_seqNum;
  logic [7:0]     req_uop_debug_seqNum_uopIdx;
  logic           req_uop_lqIdx_flag;
  logic [6:0]     req_uop_lqIdx_value;
  logic           req_uop_sqIdx_flag;
  logic [5:0]     req_uop_sqIdx_value;
  logic [49:0]    req_vaddr;
  logic           req_vaNeedExt;
  logic [47:0]    req_paddr;
  logic [63:0]    req_gpaddr;
  logic [15:0]    req_mask;
  logic           req_isForVSnonLeafPTE;
  logic           req_isvec;
  logic [7:0]     req_elemIdx;
  logic [2:0]     req_alignedType;
  logic [3:0]     req_mbIndex;
  logic [4:0]     req_splitIndex;
  logic           req_portIndex;
  always_ff @(posedge clock) begin
    req_uop_exceptionVec_0 <= req_nxt.uop.exceptionVec[0];
    req_uop_exceptionVec_1 <= req_nxt.uop.exceptionVec[1];
    req_uop_exceptionVec_2 <= req_nxt.uop.exceptionVec[2];
    req_uop_exceptionVec_4 <= req_nxt.uop.exceptionVec[4];
    req_uop_exceptionVec_5 <= req_nxt.uop.exceptionVec[5];
    req_uop_exceptionVec_8 <= req_nxt.uop.exceptionVec[8];
    req_uop_exceptionVec_9 <= req_nxt.uop.exceptionVec[9];
    req_uop_exceptionVec_10 <= req_nxt.uop.exceptionVec[10];
    req_uop_exceptionVec_11 <= req_nxt.uop.exceptionVec[11];
    req_uop_exceptionVec_12 <= req_nxt.uop.exceptionVec[12];
    req_uop_exceptionVec_13 <= req_nxt.uop.exceptionVec[13];
    req_uop_exceptionVec_14 <= req_nxt.uop.exceptionVec[14];
    req_uop_exceptionVec_16 <= req_nxt.uop.exceptionVec[16];
    req_uop_exceptionVec_17 <= req_nxt.uop.exceptionVec[17];
    req_uop_exceptionVec_18 <= req_nxt.uop.exceptionVec[18];
    req_uop_exceptionVec_19 <= req_nxt.uop.exceptionVec[19];
    req_uop_exceptionVec_20 <= req_nxt.uop.exceptionVec[20];
    req_uop_exceptionVec_21 <= req_nxt.uop.exceptionVec[21];
    req_uop_exceptionVec_22 <= req_nxt.uop.exceptionVec[22];
    req_uop_trigger <= req_nxt.uop.trigger;
    req_uop_ftqPtr_flag <= req_nxt.uop.ftqPtr_flag;
    req_uop_ftqPtr_value <= req_nxt.uop.ftqPtr_value;
    req_uop_ftqOffset <= req_nxt.uop.ftqOffset;
    req_uop_fuType <= req_nxt.uop.fuType;
    req_uop_fuOpType <= req_nxt.uop.fuOpType;
    req_uop_rfWen <= req_nxt.uop.rfWen;
    req_uop_vpu_vstart <= req_nxt.uop.vpu_vstart;
    req_uop_vpu_nf <= req_nxt.uop.vpu_nf;
    req_uop_vpu_veew <= req_nxt.uop.vpu_veew;
    req_uop_uopIdx <= req_nxt.uop.uopIdx;
    req_uop_pdest <= req_nxt.uop.pdest;
    req_uop_robIdx_flag <= req_nxt.uop.robIdx_flag;
    req_uop_robIdx_value <= req_nxt.uop.robIdx_value;
    req_uop_debugInfo_eliminatedMove <= req_nxt.uop.debugInfo_eliminatedMove;
    req_uop_debugInfo_renameTime <= req_nxt.uop.debugInfo_renameTime;
    req_uop_debugInfo_dispatchTime <= req_nxt.uop.debugInfo_dispatchTime;
    req_uop_debugInfo_enqRsTime <= req_nxt.uop.debugInfo_enqRsTime;
    req_uop_debugInfo_selectTime <= req_nxt.uop.debugInfo_selectTime;
    req_uop_debugInfo_issueTime <= req_nxt.uop.debugInfo_issueTime;
    req_uop_debugInfo_writebackTime <= req_nxt.uop.debugInfo_writebackTime;
    req_uop_debugInfo_runahead_checkpoint_id <= req_nxt.uop.debugInfo_runahead_checkpoint_id;
    req_uop_debugInfo_tlbFirstReqTime <= req_nxt.uop.debugInfo_tlbFirstReqTime;
    req_uop_debugInfo_tlbRespTime <= req_nxt.uop.debugInfo_tlbRespTime;
    req_uop_debug_seqNum_seqNum <= req_nxt.uop.debug_seqNum_seqNum;
    req_uop_debug_seqNum_uopIdx <= req_nxt.uop.debug_seqNum_uopIdx;
    req_uop_lqIdx_flag <= req_nxt.uop.lqIdx_flag;
    req_uop_lqIdx_value <= req_nxt.uop.lqIdx_value;
    req_uop_sqIdx_flag <= req_nxt.uop.sqIdx_flag;
    req_uop_sqIdx_value <= req_nxt.uop.sqIdx_value;
    req_vaddr <= req_nxt.vaddr;
    req_vaNeedExt <= req_nxt.vaNeedExt;
    req_paddr <= req_nxt.paddr;
    req_gpaddr <= req_nxt.gpaddr;
    req_mask <= req_nxt.mask;
    req_isForVSnonLeafPTE <= req_nxt.isForVSnonLeafPTE;
    req_isvec <= req_nxt.isvec;
    req_elemIdx <= req_nxt.elemIdx;
    req_alignedType <= req_nxt.alignedType;
    req_mbIndex <= req_nxt.mbIndex;
    req_splitIndex <= req_nxt.splitIndex;
    req_portIndex <= req_nxt.portIndex;
  end
  always_comb begin
    req = '0;   // golden 没留的字段恒 0
    req.uop.exceptionVec[0] = req_uop_exceptionVec_0;
    req.uop.exceptionVec[1] = req_uop_exceptionVec_1;
    req.uop.exceptionVec[2] = req_uop_exceptionVec_2;
    req.uop.exceptionVec[4] = req_uop_exceptionVec_4;
    req.uop.exceptionVec[5] = req_uop_exceptionVec_5;
    req.uop.exceptionVec[8] = req_uop_exceptionVec_8;
    req.uop.exceptionVec[9] = req_uop_exceptionVec_9;
    req.uop.exceptionVec[10] = req_uop_exceptionVec_10;
    req.uop.exceptionVec[11] = req_uop_exceptionVec_11;
    req.uop.exceptionVec[12] = req_uop_exceptionVec_12;
    req.uop.exceptionVec[13] = req_uop_exceptionVec_13;
    req.uop.exceptionVec[14] = req_uop_exceptionVec_14;
    req.uop.exceptionVec[16] = req_uop_exceptionVec_16;
    req.uop.exceptionVec[17] = req_uop_exceptionVec_17;
    req.uop.exceptionVec[18] = req_uop_exceptionVec_18;
    req.uop.exceptionVec[19] = req_uop_exceptionVec_19;
    req.uop.exceptionVec[20] = req_uop_exceptionVec_20;
    req.uop.exceptionVec[21] = req_uop_exceptionVec_21;
    req.uop.exceptionVec[22] = req_uop_exceptionVec_22;
    req.uop.trigger = req_uop_trigger;
    req.uop.ftqPtr_flag = req_uop_ftqPtr_flag;
    req.uop.ftqPtr_value = req_uop_ftqPtr_value;
    req.uop.ftqOffset = req_uop_ftqOffset;
    req.uop.fuType = req_uop_fuType;
    req.uop.fuOpType = req_uop_fuOpType;
    req.uop.rfWen = req_uop_rfWen;
    req.uop.vpu_vstart = req_uop_vpu_vstart;
    req.uop.vpu_nf = req_uop_vpu_nf;
    req.uop.vpu_veew = req_uop_vpu_veew;
    req.uop.uopIdx = req_uop_uopIdx;
    req.uop.pdest = req_uop_pdest;
    req.uop.robIdx_flag = req_uop_robIdx_flag;
    req.uop.robIdx_value = req_uop_robIdx_value;
    req.uop.debugInfo_eliminatedMove = req_uop_debugInfo_eliminatedMove;
    req.uop.debugInfo_renameTime = req_uop_debugInfo_renameTime;
    req.uop.debugInfo_dispatchTime = req_uop_debugInfo_dispatchTime;
    req.uop.debugInfo_enqRsTime = req_uop_debugInfo_enqRsTime;
    req.uop.debugInfo_selectTime = req_uop_debugInfo_selectTime;
    req.uop.debugInfo_issueTime = req_uop_debugInfo_issueTime;
    req.uop.debugInfo_writebackTime = req_uop_debugInfo_writebackTime;
    req.uop.debugInfo_runahead_checkpoint_id = req_uop_debugInfo_runahead_checkpoint_id;
    req.uop.debugInfo_tlbFirstReqTime = req_uop_debugInfo_tlbFirstReqTime;
    req.uop.debugInfo_tlbRespTime = req_uop_debugInfo_tlbRespTime;
    req.uop.debug_seqNum_seqNum = req_uop_debug_seqNum_seqNum;
    req.uop.debug_seqNum_uopIdx = req_uop_debug_seqNum_uopIdx;
    req.uop.lqIdx_flag = req_uop_lqIdx_flag;
    req.uop.lqIdx_value = req_uop_lqIdx_value;
    req.uop.sqIdx_flag = req_uop_sqIdx_flag;
    req.uop.sqIdx_value = req_uop_sqIdx_value;
    req.vaddr = req_vaddr;
    req.vaNeedExt = req_vaNeedExt;
    req.paddr = req_paddr;
    req.gpaddr = req_gpaddr;
    req.mask = req_mask;
    req.isForVSnonLeafPTE = req_isForVSnonLeafPTE;
    req.isvec = req_isvec;
    req.elemIdx = req_elemIdx;
    req.alignedType = req_alignedType;
    req.mbIndex = req_mbIndex;
    req.splitIndex = req_splitIndex;
    req.portIndex = req_portIndex;
  end

  // ---- splitStoreReqs(0)：低地址那一半子访问（异步复位为 0；s_split 且跨 16B 时写入，见 §3）：golden 留下的 52 个字段 ----
  logic           splitStoreReqs_0_uop_exceptionVec_0;
  logic           splitStoreReqs_0_uop_exceptionVec_1;
  logic           splitStoreReqs_0_uop_exceptionVec_2;
  logic           splitStoreReqs_0_uop_exceptionVec_4;
  logic           splitStoreReqs_0_uop_exceptionVec_5;
  logic           splitStoreReqs_0_uop_exceptionVec_8;
  logic           splitStoreReqs_0_uop_exceptionVec_9;
  logic           splitStoreReqs_0_uop_exceptionVec_10;
  logic           splitStoreReqs_0_uop_exceptionVec_11;
  logic           splitStoreReqs_0_uop_exceptionVec_12;
  logic           splitStoreReqs_0_uop_exceptionVec_13;
  logic           splitStoreReqs_0_uop_exceptionVec_14;
  logic           splitStoreReqs_0_uop_exceptionVec_16;
  logic           splitStoreReqs_0_uop_exceptionVec_17;
  logic           splitStoreReqs_0_uop_exceptionVec_18;
  logic           splitStoreReqs_0_uop_exceptionVec_19;
  logic           splitStoreReqs_0_uop_exceptionVec_20;
  logic           splitStoreReqs_0_uop_exceptionVec_21;
  logic           splitStoreReqs_0_uop_exceptionVec_22;
  logic [3:0]     splitStoreReqs_0_uop_trigger;
  logic           splitStoreReqs_0_uop_ftqPtr_flag;
  logic [5:0]     splitStoreReqs_0_uop_ftqPtr_value;
  logic [3:0]     splitStoreReqs_0_uop_ftqOffset;
  logic [34:0]    splitStoreReqs_0_uop_fuType;
  logic [8:0]     splitStoreReqs_0_uop_fuOpType;
  logic           splitStoreReqs_0_uop_rfWen;
  logic [7:0]     splitStoreReqs_0_uop_vpu_vstart;
  logic [2:0]     splitStoreReqs_0_uop_vpu_nf;
  logic [1:0]     splitStoreReqs_0_uop_vpu_veew;
  logic [6:0]     splitStoreReqs_0_uop_uopIdx;
  logic [7:0]     splitStoreReqs_0_uop_pdest;
  logic           splitStoreReqs_0_uop_robIdx_flag;
  logic [7:0]     splitStoreReqs_0_uop_robIdx_value;
  logic           splitStoreReqs_0_uop_debugInfo_eliminatedMove;
  logic [63:0]    splitStoreReqs_0_uop_debugInfo_renameTime;
  logic [63:0]    splitStoreReqs_0_uop_debugInfo_dispatchTime;
  logic [63:0]    splitStoreReqs_0_uop_debugInfo_enqRsTime;
  logic [63:0]    splitStoreReqs_0_uop_debugInfo_selectTime;
  logic [63:0]    splitStoreReqs_0_uop_debugInfo_issueTime;
  logic [63:0]    splitStoreReqs_0_uop_debugInfo_writebackTime;
  logic [63:0]    splitStoreReqs_0_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]    splitStoreReqs_0_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]    splitStoreReqs_0_uop_debugInfo_tlbRespTime;
  logic [55:0]    splitStoreReqs_0_uop_debug_seqNum_seqNum;
  logic [7:0]     splitStoreReqs_0_uop_debug_seqNum_uopIdx;
  logic           splitStoreReqs_0_uop_lqIdx_flag;
  logic [6:0]     splitStoreReqs_0_uop_lqIdx_value;
  logic           splitStoreReqs_0_uop_sqIdx_flag;
  logic [5:0]     splitStoreReqs_0_uop_sqIdx_value;
  logic [49:0]    splitStoreReqs_0_vaddr;
  logic [15:0]    splitStoreReqs_0_mask;
  logic           splitStoreReqs_0_is128bit;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      splitStoreReqs_0_uop_exceptionVec_0 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_1 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_2 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_4 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_5 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_8 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_9 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_10 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_11 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_12 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_13 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_14 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_16 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_17 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_18 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_19 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_20 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_21 <= 1'b0;
      splitStoreReqs_0_uop_exceptionVec_22 <= 1'b0;
      splitStoreReqs_0_uop_trigger <= '0;
      splitStoreReqs_0_uop_ftqPtr_flag <= 1'b0;
      splitStoreReqs_0_uop_ftqPtr_value <= '0;
      splitStoreReqs_0_uop_ftqOffset <= '0;
      splitStoreReqs_0_uop_fuType <= '0;
      splitStoreReqs_0_uop_fuOpType <= '0;
      splitStoreReqs_0_uop_rfWen <= 1'b0;
      splitStoreReqs_0_uop_vpu_vstart <= '0;
      splitStoreReqs_0_uop_vpu_nf <= '0;
      splitStoreReqs_0_uop_vpu_veew <= '0;
      splitStoreReqs_0_uop_uopIdx <= '0;
      splitStoreReqs_0_uop_pdest <= '0;
      splitStoreReqs_0_uop_robIdx_flag <= 1'b0;
      splitStoreReqs_0_uop_robIdx_value <= '0;
      splitStoreReqs_0_uop_debugInfo_eliminatedMove <= 1'b0;
      splitStoreReqs_0_uop_debugInfo_renameTime <= '0;
      splitStoreReqs_0_uop_debugInfo_dispatchTime <= '0;
      splitStoreReqs_0_uop_debugInfo_enqRsTime <= '0;
      splitStoreReqs_0_uop_debugInfo_selectTime <= '0;
      splitStoreReqs_0_uop_debugInfo_issueTime <= '0;
      splitStoreReqs_0_uop_debugInfo_writebackTime <= '0;
      splitStoreReqs_0_uop_debugInfo_runahead_checkpoint_id <= '0;
      splitStoreReqs_0_uop_debugInfo_tlbFirstReqTime <= '0;
      splitStoreReqs_0_uop_debugInfo_tlbRespTime <= '0;
      splitStoreReqs_0_uop_debug_seqNum_seqNum <= '0;
      splitStoreReqs_0_uop_debug_seqNum_uopIdx <= '0;
      splitStoreReqs_0_uop_lqIdx_flag <= 1'b0;
      splitStoreReqs_0_uop_lqIdx_value <= '0;
      splitStoreReqs_0_uop_sqIdx_flag <= 1'b0;
      splitStoreReqs_0_uop_sqIdx_value <= '0;
      splitStoreReqs_0_vaddr <= '0;
      splitStoreReqs_0_mask <= '0;
      splitStoreReqs_0_is128bit <= 1'b0;
    end else if (split_now) begin
      splitStoreReqs_0_uop_exceptionVec_0 <= split_new[0].uop.exceptionVec[0];
      splitStoreReqs_0_uop_exceptionVec_1 <= split_new[0].uop.exceptionVec[1];
      splitStoreReqs_0_uop_exceptionVec_2 <= split_new[0].uop.exceptionVec[2];
      splitStoreReqs_0_uop_exceptionVec_4 <= split_new[0].uop.exceptionVec[4];
      splitStoreReqs_0_uop_exceptionVec_5 <= split_new[0].uop.exceptionVec[5];
      splitStoreReqs_0_uop_exceptionVec_8 <= split_new[0].uop.exceptionVec[8];
      splitStoreReqs_0_uop_exceptionVec_9 <= split_new[0].uop.exceptionVec[9];
      splitStoreReqs_0_uop_exceptionVec_10 <= split_new[0].uop.exceptionVec[10];
      splitStoreReqs_0_uop_exceptionVec_11 <= split_new[0].uop.exceptionVec[11];
      splitStoreReqs_0_uop_exceptionVec_12 <= split_new[0].uop.exceptionVec[12];
      splitStoreReqs_0_uop_exceptionVec_13 <= split_new[0].uop.exceptionVec[13];
      splitStoreReqs_0_uop_exceptionVec_14 <= split_new[0].uop.exceptionVec[14];
      splitStoreReqs_0_uop_exceptionVec_16 <= split_new[0].uop.exceptionVec[16];
      splitStoreReqs_0_uop_exceptionVec_17 <= split_new[0].uop.exceptionVec[17];
      splitStoreReqs_0_uop_exceptionVec_18 <= split_new[0].uop.exceptionVec[18];
      splitStoreReqs_0_uop_exceptionVec_19 <= split_new[0].uop.exceptionVec[19];
      splitStoreReqs_0_uop_exceptionVec_20 <= split_new[0].uop.exceptionVec[20];
      splitStoreReqs_0_uop_exceptionVec_21 <= split_new[0].uop.exceptionVec[21];
      splitStoreReqs_0_uop_exceptionVec_22 <= split_new[0].uop.exceptionVec[22];
      splitStoreReqs_0_uop_trigger <= split_new[0].uop.trigger;
      splitStoreReqs_0_uop_ftqPtr_flag <= split_new[0].uop.ftqPtr_flag;
      splitStoreReqs_0_uop_ftqPtr_value <= split_new[0].uop.ftqPtr_value;
      splitStoreReqs_0_uop_ftqOffset <= split_new[0].uop.ftqOffset;
      splitStoreReqs_0_uop_fuType <= split_new[0].uop.fuType;
      splitStoreReqs_0_uop_fuOpType <= split_new[0].uop.fuOpType;
      splitStoreReqs_0_uop_rfWen <= split_new[0].uop.rfWen;
      splitStoreReqs_0_uop_vpu_vstart <= split_new[0].uop.vpu_vstart;
      splitStoreReqs_0_uop_vpu_nf <= split_new[0].uop.vpu_nf;
      splitStoreReqs_0_uop_vpu_veew <= split_new[0].uop.vpu_veew;
      splitStoreReqs_0_uop_uopIdx <= split_new[0].uop.uopIdx;
      splitStoreReqs_0_uop_pdest <= split_new[0].uop.pdest;
      splitStoreReqs_0_uop_robIdx_flag <= split_new[0].uop.robIdx_flag;
      splitStoreReqs_0_uop_robIdx_value <= split_new[0].uop.robIdx_value;
      splitStoreReqs_0_uop_debugInfo_eliminatedMove <= split_new[0].uop.debugInfo_eliminatedMove;
      splitStoreReqs_0_uop_debugInfo_renameTime <= split_new[0].uop.debugInfo_renameTime;
      splitStoreReqs_0_uop_debugInfo_dispatchTime <= split_new[0].uop.debugInfo_dispatchTime;
      splitStoreReqs_0_uop_debugInfo_enqRsTime <= split_new[0].uop.debugInfo_enqRsTime;
      splitStoreReqs_0_uop_debugInfo_selectTime <= split_new[0].uop.debugInfo_selectTime;
      splitStoreReqs_0_uop_debugInfo_issueTime <= split_new[0].uop.debugInfo_issueTime;
      splitStoreReqs_0_uop_debugInfo_writebackTime <= split_new[0].uop.debugInfo_writebackTime;
      splitStoreReqs_0_uop_debugInfo_runahead_checkpoint_id <= split_new[0].uop.debugInfo_runahead_checkpoint_id;
      splitStoreReqs_0_uop_debugInfo_tlbFirstReqTime <= split_new[0].uop.debugInfo_tlbFirstReqTime;
      splitStoreReqs_0_uop_debugInfo_tlbRespTime <= split_new[0].uop.debugInfo_tlbRespTime;
      splitStoreReqs_0_uop_debug_seqNum_seqNum <= split_new[0].uop.debug_seqNum_seqNum;
      splitStoreReqs_0_uop_debug_seqNum_uopIdx <= split_new[0].uop.debug_seqNum_uopIdx;
      splitStoreReqs_0_uop_lqIdx_flag <= split_new[0].uop.lqIdx_flag;
      splitStoreReqs_0_uop_lqIdx_value <= split_new[0].uop.lqIdx_value;
      splitStoreReqs_0_uop_sqIdx_flag <= split_new[0].uop.sqIdx_flag;
      splitStoreReqs_0_uop_sqIdx_value <= split_new[0].uop.sqIdx_value;
      splitStoreReqs_0_vaddr <= split_new[0].vaddr;
      splitStoreReqs_0_mask <= split_new[0].mask;
      splitStoreReqs_0_is128bit <= split_new[0].is128bit;
    end
  end
  always_comb begin
    split_reqs[0] = '0;   // golden 没留的字段恒 0
    split_reqs[0].uop.exceptionVec[0] = splitStoreReqs_0_uop_exceptionVec_0;
    split_reqs[0].uop.exceptionVec[1] = splitStoreReqs_0_uop_exceptionVec_1;
    split_reqs[0].uop.exceptionVec[2] = splitStoreReqs_0_uop_exceptionVec_2;
    split_reqs[0].uop.exceptionVec[4] = splitStoreReqs_0_uop_exceptionVec_4;
    split_reqs[0].uop.exceptionVec[5] = splitStoreReqs_0_uop_exceptionVec_5;
    split_reqs[0].uop.exceptionVec[8] = splitStoreReqs_0_uop_exceptionVec_8;
    split_reqs[0].uop.exceptionVec[9] = splitStoreReqs_0_uop_exceptionVec_9;
    split_reqs[0].uop.exceptionVec[10] = splitStoreReqs_0_uop_exceptionVec_10;
    split_reqs[0].uop.exceptionVec[11] = splitStoreReqs_0_uop_exceptionVec_11;
    split_reqs[0].uop.exceptionVec[12] = splitStoreReqs_0_uop_exceptionVec_12;
    split_reqs[0].uop.exceptionVec[13] = splitStoreReqs_0_uop_exceptionVec_13;
    split_reqs[0].uop.exceptionVec[14] = splitStoreReqs_0_uop_exceptionVec_14;
    split_reqs[0].uop.exceptionVec[16] = splitStoreReqs_0_uop_exceptionVec_16;
    split_reqs[0].uop.exceptionVec[17] = splitStoreReqs_0_uop_exceptionVec_17;
    split_reqs[0].uop.exceptionVec[18] = splitStoreReqs_0_uop_exceptionVec_18;
    split_reqs[0].uop.exceptionVec[19] = splitStoreReqs_0_uop_exceptionVec_19;
    split_reqs[0].uop.exceptionVec[20] = splitStoreReqs_0_uop_exceptionVec_20;
    split_reqs[0].uop.exceptionVec[21] = splitStoreReqs_0_uop_exceptionVec_21;
    split_reqs[0].uop.exceptionVec[22] = splitStoreReqs_0_uop_exceptionVec_22;
    split_reqs[0].uop.trigger = splitStoreReqs_0_uop_trigger;
    split_reqs[0].uop.ftqPtr_flag = splitStoreReqs_0_uop_ftqPtr_flag;
    split_reqs[0].uop.ftqPtr_value = splitStoreReqs_0_uop_ftqPtr_value;
    split_reqs[0].uop.ftqOffset = splitStoreReqs_0_uop_ftqOffset;
    split_reqs[0].uop.fuType = splitStoreReqs_0_uop_fuType;
    split_reqs[0].uop.fuOpType = splitStoreReqs_0_uop_fuOpType;
    split_reqs[0].uop.rfWen = splitStoreReqs_0_uop_rfWen;
    split_reqs[0].uop.vpu_vstart = splitStoreReqs_0_uop_vpu_vstart;
    split_reqs[0].uop.vpu_nf = splitStoreReqs_0_uop_vpu_nf;
    split_reqs[0].uop.vpu_veew = splitStoreReqs_0_uop_vpu_veew;
    split_reqs[0].uop.uopIdx = splitStoreReqs_0_uop_uopIdx;
    split_reqs[0].uop.pdest = splitStoreReqs_0_uop_pdest;
    split_reqs[0].uop.robIdx_flag = splitStoreReqs_0_uop_robIdx_flag;
    split_reqs[0].uop.robIdx_value = splitStoreReqs_0_uop_robIdx_value;
    split_reqs[0].uop.debugInfo_eliminatedMove = splitStoreReqs_0_uop_debugInfo_eliminatedMove;
    split_reqs[0].uop.debugInfo_renameTime = splitStoreReqs_0_uop_debugInfo_renameTime;
    split_reqs[0].uop.debugInfo_dispatchTime = splitStoreReqs_0_uop_debugInfo_dispatchTime;
    split_reqs[0].uop.debugInfo_enqRsTime = splitStoreReqs_0_uop_debugInfo_enqRsTime;
    split_reqs[0].uop.debugInfo_selectTime = splitStoreReqs_0_uop_debugInfo_selectTime;
    split_reqs[0].uop.debugInfo_issueTime = splitStoreReqs_0_uop_debugInfo_issueTime;
    split_reqs[0].uop.debugInfo_writebackTime = splitStoreReqs_0_uop_debugInfo_writebackTime;
    split_reqs[0].uop.debugInfo_runahead_checkpoint_id = splitStoreReqs_0_uop_debugInfo_runahead_checkpoint_id;
    split_reqs[0].uop.debugInfo_tlbFirstReqTime = splitStoreReqs_0_uop_debugInfo_tlbFirstReqTime;
    split_reqs[0].uop.debugInfo_tlbRespTime = splitStoreReqs_0_uop_debugInfo_tlbRespTime;
    split_reqs[0].uop.debug_seqNum_seqNum = splitStoreReqs_0_uop_debug_seqNum_seqNum;
    split_reqs[0].uop.debug_seqNum_uopIdx = splitStoreReqs_0_uop_debug_seqNum_uopIdx;
    split_reqs[0].uop.lqIdx_flag = splitStoreReqs_0_uop_lqIdx_flag;
    split_reqs[0].uop.lqIdx_value = splitStoreReqs_0_uop_lqIdx_value;
    split_reqs[0].uop.sqIdx_flag = splitStoreReqs_0_uop_sqIdx_flag;
    split_reqs[0].uop.sqIdx_value = splitStoreReqs_0_uop_sqIdx_value;
    split_reqs[0].vaddr = splitStoreReqs_0_vaddr;
    split_reqs[0].mask = splitStoreReqs_0_mask;
    split_reqs[0].is128bit = splitStoreReqs_0_is128bit;
  end

  // ---- splitStoreReqs(1)：高地址那一半子访问（同上）：golden 留下的 52 个字段 ----
  logic           splitStoreReqs_1_uop_exceptionVec_0;
  logic           splitStoreReqs_1_uop_exceptionVec_1;
  logic           splitStoreReqs_1_uop_exceptionVec_2;
  logic           splitStoreReqs_1_uop_exceptionVec_4;
  logic           splitStoreReqs_1_uop_exceptionVec_5;
  logic           splitStoreReqs_1_uop_exceptionVec_8;
  logic           splitStoreReqs_1_uop_exceptionVec_9;
  logic           splitStoreReqs_1_uop_exceptionVec_10;
  logic           splitStoreReqs_1_uop_exceptionVec_11;
  logic           splitStoreReqs_1_uop_exceptionVec_12;
  logic           splitStoreReqs_1_uop_exceptionVec_13;
  logic           splitStoreReqs_1_uop_exceptionVec_14;
  logic           splitStoreReqs_1_uop_exceptionVec_16;
  logic           splitStoreReqs_1_uop_exceptionVec_17;
  logic           splitStoreReqs_1_uop_exceptionVec_18;
  logic           splitStoreReqs_1_uop_exceptionVec_19;
  logic           splitStoreReqs_1_uop_exceptionVec_20;
  logic           splitStoreReqs_1_uop_exceptionVec_21;
  logic           splitStoreReqs_1_uop_exceptionVec_22;
  logic [3:0]     splitStoreReqs_1_uop_trigger;
  logic           splitStoreReqs_1_uop_ftqPtr_flag;
  logic [5:0]     splitStoreReqs_1_uop_ftqPtr_value;
  logic [3:0]     splitStoreReqs_1_uop_ftqOffset;
  logic [34:0]    splitStoreReqs_1_uop_fuType;
  logic [8:0]     splitStoreReqs_1_uop_fuOpType;
  logic           splitStoreReqs_1_uop_rfWen;
  logic [7:0]     splitStoreReqs_1_uop_vpu_vstart;
  logic [2:0]     splitStoreReqs_1_uop_vpu_nf;
  logic [1:0]     splitStoreReqs_1_uop_vpu_veew;
  logic [6:0]     splitStoreReqs_1_uop_uopIdx;
  logic [7:0]     splitStoreReqs_1_uop_pdest;
  logic           splitStoreReqs_1_uop_robIdx_flag;
  logic [7:0]     splitStoreReqs_1_uop_robIdx_value;
  logic           splitStoreReqs_1_uop_debugInfo_eliminatedMove;
  logic [63:0]    splitStoreReqs_1_uop_debugInfo_renameTime;
  logic [63:0]    splitStoreReqs_1_uop_debugInfo_dispatchTime;
  logic [63:0]    splitStoreReqs_1_uop_debugInfo_enqRsTime;
  logic [63:0]    splitStoreReqs_1_uop_debugInfo_selectTime;
  logic [63:0]    splitStoreReqs_1_uop_debugInfo_issueTime;
  logic [63:0]    splitStoreReqs_1_uop_debugInfo_writebackTime;
  logic [63:0]    splitStoreReqs_1_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]    splitStoreReqs_1_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]    splitStoreReqs_1_uop_debugInfo_tlbRespTime;
  logic [55:0]    splitStoreReqs_1_uop_debug_seqNum_seqNum;
  logic [7:0]     splitStoreReqs_1_uop_debug_seqNum_uopIdx;
  logic           splitStoreReqs_1_uop_lqIdx_flag;
  logic [6:0]     splitStoreReqs_1_uop_lqIdx_value;
  logic           splitStoreReqs_1_uop_sqIdx_flag;
  logic [5:0]     splitStoreReqs_1_uop_sqIdx_value;
  logic [49:0]    splitStoreReqs_1_vaddr;
  logic [15:0]    splitStoreReqs_1_mask;
  logic           splitStoreReqs_1_is128bit;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      splitStoreReqs_1_uop_exceptionVec_0 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_1 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_2 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_4 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_5 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_8 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_9 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_10 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_11 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_12 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_13 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_14 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_16 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_17 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_18 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_19 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_20 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_21 <= 1'b0;
      splitStoreReqs_1_uop_exceptionVec_22 <= 1'b0;
      splitStoreReqs_1_uop_trigger <= '0;
      splitStoreReqs_1_uop_ftqPtr_flag <= 1'b0;
      splitStoreReqs_1_uop_ftqPtr_value <= '0;
      splitStoreReqs_1_uop_ftqOffset <= '0;
      splitStoreReqs_1_uop_fuType <= '0;
      splitStoreReqs_1_uop_fuOpType <= '0;
      splitStoreReqs_1_uop_rfWen <= 1'b0;
      splitStoreReqs_1_uop_vpu_vstart <= '0;
      splitStoreReqs_1_uop_vpu_nf <= '0;
      splitStoreReqs_1_uop_vpu_veew <= '0;
      splitStoreReqs_1_uop_uopIdx <= '0;
      splitStoreReqs_1_uop_pdest <= '0;
      splitStoreReqs_1_uop_robIdx_flag <= 1'b0;
      splitStoreReqs_1_uop_robIdx_value <= '0;
      splitStoreReqs_1_uop_debugInfo_eliminatedMove <= 1'b0;
      splitStoreReqs_1_uop_debugInfo_renameTime <= '0;
      splitStoreReqs_1_uop_debugInfo_dispatchTime <= '0;
      splitStoreReqs_1_uop_debugInfo_enqRsTime <= '0;
      splitStoreReqs_1_uop_debugInfo_selectTime <= '0;
      splitStoreReqs_1_uop_debugInfo_issueTime <= '0;
      splitStoreReqs_1_uop_debugInfo_writebackTime <= '0;
      splitStoreReqs_1_uop_debugInfo_runahead_checkpoint_id <= '0;
      splitStoreReqs_1_uop_debugInfo_tlbFirstReqTime <= '0;
      splitStoreReqs_1_uop_debugInfo_tlbRespTime <= '0;
      splitStoreReqs_1_uop_debug_seqNum_seqNum <= '0;
      splitStoreReqs_1_uop_debug_seqNum_uopIdx <= '0;
      splitStoreReqs_1_uop_lqIdx_flag <= 1'b0;
      splitStoreReqs_1_uop_lqIdx_value <= '0;
      splitStoreReqs_1_uop_sqIdx_flag <= 1'b0;
      splitStoreReqs_1_uop_sqIdx_value <= '0;
      splitStoreReqs_1_vaddr <= '0;
      splitStoreReqs_1_mask <= '0;
      splitStoreReqs_1_is128bit <= 1'b0;
    end else if (split_now) begin
      splitStoreReqs_1_uop_exceptionVec_0 <= split_new[1].uop.exceptionVec[0];
      splitStoreReqs_1_uop_exceptionVec_1 <= split_new[1].uop.exceptionVec[1];
      splitStoreReqs_1_uop_exceptionVec_2 <= split_new[1].uop.exceptionVec[2];
      splitStoreReqs_1_uop_exceptionVec_4 <= split_new[1].uop.exceptionVec[4];
      splitStoreReqs_1_uop_exceptionVec_5 <= split_new[1].uop.exceptionVec[5];
      splitStoreReqs_1_uop_exceptionVec_8 <= split_new[1].uop.exceptionVec[8];
      splitStoreReqs_1_uop_exceptionVec_9 <= split_new[1].uop.exceptionVec[9];
      splitStoreReqs_1_uop_exceptionVec_10 <= split_new[1].uop.exceptionVec[10];
      splitStoreReqs_1_uop_exceptionVec_11 <= split_new[1].uop.exceptionVec[11];
      splitStoreReqs_1_uop_exceptionVec_12 <= split_new[1].uop.exceptionVec[12];
      splitStoreReqs_1_uop_exceptionVec_13 <= split_new[1].uop.exceptionVec[13];
      splitStoreReqs_1_uop_exceptionVec_14 <= split_new[1].uop.exceptionVec[14];
      splitStoreReqs_1_uop_exceptionVec_16 <= split_new[1].uop.exceptionVec[16];
      splitStoreReqs_1_uop_exceptionVec_17 <= split_new[1].uop.exceptionVec[17];
      splitStoreReqs_1_uop_exceptionVec_18 <= split_new[1].uop.exceptionVec[18];
      splitStoreReqs_1_uop_exceptionVec_19 <= split_new[1].uop.exceptionVec[19];
      splitStoreReqs_1_uop_exceptionVec_20 <= split_new[1].uop.exceptionVec[20];
      splitStoreReqs_1_uop_exceptionVec_21 <= split_new[1].uop.exceptionVec[21];
      splitStoreReqs_1_uop_exceptionVec_22 <= split_new[1].uop.exceptionVec[22];
      splitStoreReqs_1_uop_trigger <= split_new[1].uop.trigger;
      splitStoreReqs_1_uop_ftqPtr_flag <= split_new[1].uop.ftqPtr_flag;
      splitStoreReqs_1_uop_ftqPtr_value <= split_new[1].uop.ftqPtr_value;
      splitStoreReqs_1_uop_ftqOffset <= split_new[1].uop.ftqOffset;
      splitStoreReqs_1_uop_fuType <= split_new[1].uop.fuType;
      splitStoreReqs_1_uop_fuOpType <= split_new[1].uop.fuOpType;
      splitStoreReqs_1_uop_rfWen <= split_new[1].uop.rfWen;
      splitStoreReqs_1_uop_vpu_vstart <= split_new[1].uop.vpu_vstart;
      splitStoreReqs_1_uop_vpu_nf <= split_new[1].uop.vpu_nf;
      splitStoreReqs_1_uop_vpu_veew <= split_new[1].uop.vpu_veew;
      splitStoreReqs_1_uop_uopIdx <= split_new[1].uop.uopIdx;
      splitStoreReqs_1_uop_pdest <= split_new[1].uop.pdest;
      splitStoreReqs_1_uop_robIdx_flag <= split_new[1].uop.robIdx_flag;
      splitStoreReqs_1_uop_robIdx_value <= split_new[1].uop.robIdx_value;
      splitStoreReqs_1_uop_debugInfo_eliminatedMove <= split_new[1].uop.debugInfo_eliminatedMove;
      splitStoreReqs_1_uop_debugInfo_renameTime <= split_new[1].uop.debugInfo_renameTime;
      splitStoreReqs_1_uop_debugInfo_dispatchTime <= split_new[1].uop.debugInfo_dispatchTime;
      splitStoreReqs_1_uop_debugInfo_enqRsTime <= split_new[1].uop.debugInfo_enqRsTime;
      splitStoreReqs_1_uop_debugInfo_selectTime <= split_new[1].uop.debugInfo_selectTime;
      splitStoreReqs_1_uop_debugInfo_issueTime <= split_new[1].uop.debugInfo_issueTime;
      splitStoreReqs_1_uop_debugInfo_writebackTime <= split_new[1].uop.debugInfo_writebackTime;
      splitStoreReqs_1_uop_debugInfo_runahead_checkpoint_id <= split_new[1].uop.debugInfo_runahead_checkpoint_id;
      splitStoreReqs_1_uop_debugInfo_tlbFirstReqTime <= split_new[1].uop.debugInfo_tlbFirstReqTime;
      splitStoreReqs_1_uop_debugInfo_tlbRespTime <= split_new[1].uop.debugInfo_tlbRespTime;
      splitStoreReqs_1_uop_debug_seqNum_seqNum <= split_new[1].uop.debug_seqNum_seqNum;
      splitStoreReqs_1_uop_debug_seqNum_uopIdx <= split_new[1].uop.debug_seqNum_uopIdx;
      splitStoreReqs_1_uop_lqIdx_flag <= split_new[1].uop.lqIdx_flag;
      splitStoreReqs_1_uop_lqIdx_value <= split_new[1].uop.lqIdx_value;
      splitStoreReqs_1_uop_sqIdx_flag <= split_new[1].uop.sqIdx_flag;
      splitStoreReqs_1_uop_sqIdx_value <= split_new[1].uop.sqIdx_value;
      splitStoreReqs_1_vaddr <= split_new[1].vaddr;
      splitStoreReqs_1_mask <= split_new[1].mask;
      splitStoreReqs_1_is128bit <= split_new[1].is128bit;
    end
  end
  always_comb begin
    split_reqs[1] = '0;   // golden 没留的字段恒 0
    split_reqs[1].uop.exceptionVec[0] = splitStoreReqs_1_uop_exceptionVec_0;
    split_reqs[1].uop.exceptionVec[1] = splitStoreReqs_1_uop_exceptionVec_1;
    split_reqs[1].uop.exceptionVec[2] = splitStoreReqs_1_uop_exceptionVec_2;
    split_reqs[1].uop.exceptionVec[4] = splitStoreReqs_1_uop_exceptionVec_4;
    split_reqs[1].uop.exceptionVec[5] = splitStoreReqs_1_uop_exceptionVec_5;
    split_reqs[1].uop.exceptionVec[8] = splitStoreReqs_1_uop_exceptionVec_8;
    split_reqs[1].uop.exceptionVec[9] = splitStoreReqs_1_uop_exceptionVec_9;
    split_reqs[1].uop.exceptionVec[10] = splitStoreReqs_1_uop_exceptionVec_10;
    split_reqs[1].uop.exceptionVec[11] = splitStoreReqs_1_uop_exceptionVec_11;
    split_reqs[1].uop.exceptionVec[12] = splitStoreReqs_1_uop_exceptionVec_12;
    split_reqs[1].uop.exceptionVec[13] = splitStoreReqs_1_uop_exceptionVec_13;
    split_reqs[1].uop.exceptionVec[14] = splitStoreReqs_1_uop_exceptionVec_14;
    split_reqs[1].uop.exceptionVec[16] = splitStoreReqs_1_uop_exceptionVec_16;
    split_reqs[1].uop.exceptionVec[17] = splitStoreReqs_1_uop_exceptionVec_17;
    split_reqs[1].uop.exceptionVec[18] = splitStoreReqs_1_uop_exceptionVec_18;
    split_reqs[1].uop.exceptionVec[19] = splitStoreReqs_1_uop_exceptionVec_19;
    split_reqs[1].uop.exceptionVec[20] = splitStoreReqs_1_uop_exceptionVec_20;
    split_reqs[1].uop.exceptionVec[21] = splitStoreReqs_1_uop_exceptionVec_21;
    split_reqs[1].uop.exceptionVec[22] = splitStoreReqs_1_uop_exceptionVec_22;
    split_reqs[1].uop.trigger = splitStoreReqs_1_uop_trigger;
    split_reqs[1].uop.ftqPtr_flag = splitStoreReqs_1_uop_ftqPtr_flag;
    split_reqs[1].uop.ftqPtr_value = splitStoreReqs_1_uop_ftqPtr_value;
    split_reqs[1].uop.ftqOffset = splitStoreReqs_1_uop_ftqOffset;
    split_reqs[1].uop.fuType = splitStoreReqs_1_uop_fuType;
    split_reqs[1].uop.fuOpType = splitStoreReqs_1_uop_fuOpType;
    split_reqs[1].uop.rfWen = splitStoreReqs_1_uop_rfWen;
    split_reqs[1].uop.vpu_vstart = splitStoreReqs_1_uop_vpu_vstart;
    split_reqs[1].uop.vpu_nf = splitStoreReqs_1_uop_vpu_nf;
    split_reqs[1].uop.vpu_veew = splitStoreReqs_1_uop_vpu_veew;
    split_reqs[1].uop.uopIdx = splitStoreReqs_1_uop_uopIdx;
    split_reqs[1].uop.pdest = splitStoreReqs_1_uop_pdest;
    split_reqs[1].uop.robIdx_flag = splitStoreReqs_1_uop_robIdx_flag;
    split_reqs[1].uop.robIdx_value = splitStoreReqs_1_uop_robIdx_value;
    split_reqs[1].uop.debugInfo_eliminatedMove = splitStoreReqs_1_uop_debugInfo_eliminatedMove;
    split_reqs[1].uop.debugInfo_renameTime = splitStoreReqs_1_uop_debugInfo_renameTime;
    split_reqs[1].uop.debugInfo_dispatchTime = splitStoreReqs_1_uop_debugInfo_dispatchTime;
    split_reqs[1].uop.debugInfo_enqRsTime = splitStoreReqs_1_uop_debugInfo_enqRsTime;
    split_reqs[1].uop.debugInfo_selectTime = splitStoreReqs_1_uop_debugInfo_selectTime;
    split_reqs[1].uop.debugInfo_issueTime = splitStoreReqs_1_uop_debugInfo_issueTime;
    split_reqs[1].uop.debugInfo_writebackTime = splitStoreReqs_1_uop_debugInfo_writebackTime;
    split_reqs[1].uop.debugInfo_runahead_checkpoint_id = splitStoreReqs_1_uop_debugInfo_runahead_checkpoint_id;
    split_reqs[1].uop.debugInfo_tlbFirstReqTime = splitStoreReqs_1_uop_debugInfo_tlbFirstReqTime;
    split_reqs[1].uop.debugInfo_tlbRespTime = splitStoreReqs_1_uop_debugInfo_tlbRespTime;
    split_reqs[1].uop.debug_seqNum_seqNum = splitStoreReqs_1_uop_debug_seqNum_seqNum;
    split_reqs[1].uop.debug_seqNum_uopIdx = splitStoreReqs_1_uop_debug_seqNum_uopIdx;
    split_reqs[1].uop.lqIdx_flag = splitStoreReqs_1_uop_lqIdx_flag;
    split_reqs[1].uop.lqIdx_value = splitStoreReqs_1_uop_lqIdx_value;
    split_reqs[1].uop.sqIdx_flag = splitStoreReqs_1_uop_sqIdx_flag;
    split_reqs[1].uop.sqIdx_value = splitStoreReqs_1_uop_sqIdx_value;
    split_reqs[1].vaddr = splitStoreReqs_1_vaddr;
    split_reqs[1].mask = splitStoreReqs_1_mask;
    split_reqs[1].is128bit = splitStoreReqs_1_is128bit;
  end
  // END GENERATED(regs)

endmodule

// =====================================================================
// golden 同名 wrapper —— 端口逐位照抄 golden，拆装成 struct 接核
// =====================================================================
// BEGIN GENERATED(wrapper) —— scripts/gen_smisalign.py 生成，勿手改
module StoreMisalignBuffer
  import storemisalignbuffer_pkg::*;
(
  input           clock,
  input           reset,
  input           io_redirect_valid,
  input           io_redirect_bits_robIdx_flag,
  input  [7:0]    io_redirect_bits_robIdx_value,
  input           io_redirect_bits_level,
  output          io_enq_0_req_ready,
  input           io_enq_0_req_valid,
  input           io_enq_0_req_bits_uop_exceptionVec_0,
  input           io_enq_0_req_bits_uop_exceptionVec_1,
  input           io_enq_0_req_bits_uop_exceptionVec_2,
  input           io_enq_0_req_bits_uop_exceptionVec_4,
  input           io_enq_0_req_bits_uop_exceptionVec_5,
  input           io_enq_0_req_bits_uop_exceptionVec_8,
  input           io_enq_0_req_bits_uop_exceptionVec_9,
  input           io_enq_0_req_bits_uop_exceptionVec_10,
  input           io_enq_0_req_bits_uop_exceptionVec_11,
  input           io_enq_0_req_bits_uop_exceptionVec_12,
  input           io_enq_0_req_bits_uop_exceptionVec_13,
  input           io_enq_0_req_bits_uop_exceptionVec_14,
  input           io_enq_0_req_bits_uop_exceptionVec_16,
  input           io_enq_0_req_bits_uop_exceptionVec_17,
  input           io_enq_0_req_bits_uop_exceptionVec_18,
  input           io_enq_0_req_bits_uop_exceptionVec_19,
  input           io_enq_0_req_bits_uop_exceptionVec_20,
  input           io_enq_0_req_bits_uop_exceptionVec_21,
  input           io_enq_0_req_bits_uop_exceptionVec_22,
  input  [3:0]    io_enq_0_req_bits_uop_trigger,
  input           io_enq_0_req_bits_uop_ftqPtr_flag,
  input  [5:0]    io_enq_0_req_bits_uop_ftqPtr_value,
  input  [3:0]    io_enq_0_req_bits_uop_ftqOffset,
  input  [34:0]   io_enq_0_req_bits_uop_fuType,
  input  [8:0]    io_enq_0_req_bits_uop_fuOpType,
  input           io_enq_0_req_bits_uop_rfWen,
  input  [7:0]    io_enq_0_req_bits_uop_vpu_vstart,
  input  [2:0]    io_enq_0_req_bits_uop_vpu_nf,
  input  [1:0]    io_enq_0_req_bits_uop_vpu_veew,
  input  [6:0]    io_enq_0_req_bits_uop_uopIdx,
  input  [7:0]    io_enq_0_req_bits_uop_pdest,
  input           io_enq_0_req_bits_uop_robIdx_flag,
  input  [7:0]    io_enq_0_req_bits_uop_robIdx_value,
  input           io_enq_0_req_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_renameTime,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_dispatchTime,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_enqRsTime,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_selectTime,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_issueTime,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_writebackTime,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]   io_enq_0_req_bits_uop_debug_seqNum_seqNum,
  input  [7:0]    io_enq_0_req_bits_uop_debug_seqNum_uopIdx,
  input           io_enq_0_req_bits_uop_lqIdx_flag,
  input  [6:0]    io_enq_0_req_bits_uop_lqIdx_value,
  input           io_enq_0_req_bits_uop_sqIdx_flag,
  input  [5:0]    io_enq_0_req_bits_uop_sqIdx_value,
  input  [49:0]   io_enq_0_req_bits_vaddr,
  input  [15:0]   io_enq_0_req_bits_mask,
  input           io_enq_0_req_bits_isvec,
  input  [7:0]    io_enq_0_req_bits_elemIdx,
  input  [2:0]    io_enq_0_req_bits_alignedType,
  input  [3:0]    io_enq_0_req_bits_mbIndex,
  input  [4:0]    io_enq_0_req_bits_splitIndex,
  input           io_enq_0_revoke,
  output          io_enq_1_req_ready,
  input           io_enq_1_req_valid,
  input           io_enq_1_req_bits_uop_exceptionVec_0,
  input           io_enq_1_req_bits_uop_exceptionVec_1,
  input           io_enq_1_req_bits_uop_exceptionVec_2,
  input           io_enq_1_req_bits_uop_exceptionVec_4,
  input           io_enq_1_req_bits_uop_exceptionVec_5,
  input           io_enq_1_req_bits_uop_exceptionVec_8,
  input           io_enq_1_req_bits_uop_exceptionVec_9,
  input           io_enq_1_req_bits_uop_exceptionVec_10,
  input           io_enq_1_req_bits_uop_exceptionVec_11,
  input           io_enq_1_req_bits_uop_exceptionVec_12,
  input           io_enq_1_req_bits_uop_exceptionVec_13,
  input           io_enq_1_req_bits_uop_exceptionVec_14,
  input           io_enq_1_req_bits_uop_exceptionVec_16,
  input           io_enq_1_req_bits_uop_exceptionVec_17,
  input           io_enq_1_req_bits_uop_exceptionVec_18,
  input           io_enq_1_req_bits_uop_exceptionVec_19,
  input           io_enq_1_req_bits_uop_exceptionVec_20,
  input           io_enq_1_req_bits_uop_exceptionVec_21,
  input           io_enq_1_req_bits_uop_exceptionVec_22,
  input  [3:0]    io_enq_1_req_bits_uop_trigger,
  input           io_enq_1_req_bits_uop_ftqPtr_flag,
  input  [5:0]    io_enq_1_req_bits_uop_ftqPtr_value,
  input  [3:0]    io_enq_1_req_bits_uop_ftqOffset,
  input  [34:0]   io_enq_1_req_bits_uop_fuType,
  input  [8:0]    io_enq_1_req_bits_uop_fuOpType,
  input           io_enq_1_req_bits_uop_rfWen,
  input  [7:0]    io_enq_1_req_bits_uop_vpu_vstart,
  input  [2:0]    io_enq_1_req_bits_uop_vpu_nf,
  input  [1:0]    io_enq_1_req_bits_uop_vpu_veew,
  input  [6:0]    io_enq_1_req_bits_uop_uopIdx,
  input  [7:0]    io_enq_1_req_bits_uop_pdest,
  input           io_enq_1_req_bits_uop_robIdx_flag,
  input  [7:0]    io_enq_1_req_bits_uop_robIdx_value,
  input           io_enq_1_req_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_renameTime,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_dispatchTime,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_enqRsTime,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_selectTime,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_issueTime,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_writebackTime,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]   io_enq_1_req_bits_uop_debug_seqNum_seqNum,
  input  [7:0]    io_enq_1_req_bits_uop_debug_seqNum_uopIdx,
  input           io_enq_1_req_bits_uop_lqIdx_flag,
  input  [6:0]    io_enq_1_req_bits_uop_lqIdx_value,
  input           io_enq_1_req_bits_uop_sqIdx_flag,
  input  [5:0]    io_enq_1_req_bits_uop_sqIdx_value,
  input  [49:0]   io_enq_1_req_bits_vaddr,
  input  [15:0]   io_enq_1_req_bits_mask,
  input           io_enq_1_req_bits_isvec,
  input  [7:0]    io_enq_1_req_bits_elemIdx,
  input  [2:0]    io_enq_1_req_bits_alignedType,
  input  [3:0]    io_enq_1_req_bits_mbIndex,
  input  [4:0]    io_enq_1_req_bits_splitIndex,
  input           io_enq_1_revoke,
  input           io_rob_pendingst,
  input           io_rob_pendingPtr_flag,
  input  [7:0]    io_rob_pendingPtr_value,
  input           io_splitStoreReq_ready,
  output          io_splitStoreReq_valid,
  output          io_splitStoreReq_bits_uop_exceptionVec_0,
  output          io_splitStoreReq_bits_uop_exceptionVec_1,
  output          io_splitStoreReq_bits_uop_exceptionVec_2,
  output          io_splitStoreReq_bits_uop_exceptionVec_4,
  output          io_splitStoreReq_bits_uop_exceptionVec_5,
  output          io_splitStoreReq_bits_uop_exceptionVec_8,
  output          io_splitStoreReq_bits_uop_exceptionVec_9,
  output          io_splitStoreReq_bits_uop_exceptionVec_10,
  output          io_splitStoreReq_bits_uop_exceptionVec_11,
  output          io_splitStoreReq_bits_uop_exceptionVec_12,
  output          io_splitStoreReq_bits_uop_exceptionVec_13,
  output          io_splitStoreReq_bits_uop_exceptionVec_14,
  output          io_splitStoreReq_bits_uop_exceptionVec_16,
  output          io_splitStoreReq_bits_uop_exceptionVec_17,
  output          io_splitStoreReq_bits_uop_exceptionVec_18,
  output          io_splitStoreReq_bits_uop_exceptionVec_19,
  output          io_splitStoreReq_bits_uop_exceptionVec_20,
  output          io_splitStoreReq_bits_uop_exceptionVec_21,
  output          io_splitStoreReq_bits_uop_exceptionVec_22,
  output [3:0]    io_splitStoreReq_bits_uop_trigger,
  output          io_splitStoreReq_bits_uop_ftqPtr_flag,
  output [5:0]    io_splitStoreReq_bits_uop_ftqPtr_value,
  output [3:0]    io_splitStoreReq_bits_uop_ftqOffset,
  output [34:0]   io_splitStoreReq_bits_uop_fuType,
  output [8:0]    io_splitStoreReq_bits_uop_fuOpType,
  output          io_splitStoreReq_bits_uop_rfWen,
  output [7:0]    io_splitStoreReq_bits_uop_vpu_vstart,
  output [2:0]    io_splitStoreReq_bits_uop_vpu_nf,
  output [1:0]    io_splitStoreReq_bits_uop_vpu_veew,
  output [6:0]    io_splitStoreReq_bits_uop_uopIdx,
  output [7:0]    io_splitStoreReq_bits_uop_pdest,
  output          io_splitStoreReq_bits_uop_robIdx_flag,
  output [7:0]    io_splitStoreReq_bits_uop_robIdx_value,
  output          io_splitStoreReq_bits_uop_debugInfo_eliminatedMove,
  output [63:0]   io_splitStoreReq_bits_uop_debugInfo_renameTime,
  output [63:0]   io_splitStoreReq_bits_uop_debugInfo_dispatchTime,
  output [63:0]   io_splitStoreReq_bits_uop_debugInfo_enqRsTime,
  output [63:0]   io_splitStoreReq_bits_uop_debugInfo_selectTime,
  output [63:0]   io_splitStoreReq_bits_uop_debugInfo_issueTime,
  output [63:0]   io_splitStoreReq_bits_uop_debugInfo_writebackTime,
  output [63:0]   io_splitStoreReq_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]   io_splitStoreReq_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]   io_splitStoreReq_bits_uop_debugInfo_tlbRespTime,
  output [55:0]   io_splitStoreReq_bits_uop_debug_seqNum_seqNum,
  output [7:0]    io_splitStoreReq_bits_uop_debug_seqNum_uopIdx,
  output          io_splitStoreReq_bits_uop_lqIdx_flag,
  output [6:0]    io_splitStoreReq_bits_uop_lqIdx_value,
  output          io_splitStoreReq_bits_uop_sqIdx_flag,
  output [5:0]    io_splitStoreReq_bits_uop_sqIdx_value,
  output [49:0]   io_splitStoreReq_bits_vaddr,
  output [15:0]   io_splitStoreReq_bits_mask,
  output          io_splitStoreReq_bits_isvec,
  output          io_splitStoreReq_bits_is128bit,
  output          io_splitStoreReq_bits_isFinalSplit,
  input           io_splitStoreResp_valid,
  input           io_splitStoreResp_bits_uop_exceptionVec_3,
  input           io_splitStoreResp_bits_uop_exceptionVec_6,
  input           io_splitStoreResp_bits_uop_exceptionVec_7,
  input           io_splitStoreResp_bits_uop_exceptionVec_15,
  input           io_splitStoreResp_bits_uop_exceptionVec_19,
  input           io_splitStoreResp_bits_uop_exceptionVec_23,
  input  [3:0]    io_splitStoreResp_bits_uop_trigger,
  input           io_splitStoreResp_bits_uop_robIdx_flag,
  input  [7:0]    io_splitStoreResp_bits_uop_robIdx_value,
  input  [49:0]   io_splitStoreResp_bits_vaddr,
  input           io_splitStoreResp_bits_vaNeedExt,
  input  [47:0]   io_splitStoreResp_bits_paddr,
  input  [63:0]   io_splitStoreResp_bits_gpaddr,
  input           io_splitStoreResp_bits_nc,
  input           io_splitStoreResp_bits_mmio,
  input           io_splitStoreResp_bits_memBackTypeMM,
  input           io_splitStoreResp_bits_isForVSnonLeafPTE,
  input           io_splitStoreResp_bits_vecActive,
  input           io_splitStoreResp_bits_need_rep,
  input           io_writeBack_ready,
  output          io_writeBack_valid,
  output          io_writeBack_bits_uop_exceptionVec_3,
  output          io_writeBack_bits_uop_exceptionVec_6,
  output          io_writeBack_bits_uop_exceptionVec_7,
  output          io_writeBack_bits_uop_exceptionVec_15,
  output          io_writeBack_bits_uop_exceptionVec_19,
  output          io_writeBack_bits_uop_exceptionVec_23,
  output [3:0]    io_writeBack_bits_uop_trigger,
  output          io_writeBack_bits_uop_rfWen,
  output [7:0]    io_writeBack_bits_uop_pdest,
  output          io_writeBack_bits_uop_robIdx_flag,
  output [7:0]    io_writeBack_bits_uop_robIdx_value,
  output          io_writeBack_bits_uop_debugInfo_eliminatedMove,
  output [63:0]   io_writeBack_bits_uop_debugInfo_renameTime,
  output [63:0]   io_writeBack_bits_uop_debugInfo_dispatchTime,
  output [63:0]   io_writeBack_bits_uop_debugInfo_enqRsTime,
  output [63:0]   io_writeBack_bits_uop_debugInfo_selectTime,
  output [63:0]   io_writeBack_bits_uop_debugInfo_issueTime,
  output [63:0]   io_writeBack_bits_uop_debugInfo_writebackTime,
  output [63:0]   io_writeBack_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]   io_writeBack_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]   io_writeBack_bits_uop_debugInfo_tlbRespTime,
  output [55:0]   io_writeBack_bits_uop_debug_seqNum_seqNum,
  output [7:0]    io_writeBack_bits_uop_debug_seqNum_uopIdx,
  output          io_writeBack_bits_uop_sqIdx_flag,
  output [5:0]    io_writeBack_bits_uop_sqIdx_value,
  output          io_writeBack_bits_debug_isMMIO,
  output          io_writeBack_bits_debug_isNCIO,
  output [47:0]   io_writeBack_bits_debug_paddr,
  output [49:0]   io_writeBack_bits_debug_vaddr,
  output          io_vecWriteBack_0_valid,
  output [3:0]    io_vecWriteBack_0_bits_mBIndex,
  output          io_vecWriteBack_0_bits_exceptionVec_3,
  output          io_vecWriteBack_0_bits_exceptionVec_6,
  output          io_vecWriteBack_0_bits_exceptionVec_7,
  output          io_vecWriteBack_0_bits_exceptionVec_15,
  output          io_vecWriteBack_0_bits_exceptionVec_19,
  output          io_vecWriteBack_0_bits_exceptionVec_23,
  output          io_vecWriteBack_0_bits_hasException,
  output [63:0]   io_vecWriteBack_0_bits_vaddr,
  output          io_vecWriteBack_0_bits_vaNeedExt,
  output [63:0]   io_vecWriteBack_0_bits_gpaddr,
  output          io_vecWriteBack_0_bits_isForVSnonLeafPTE,
  output [7:0]    io_vecWriteBack_0_bits_vstart,
  output [7:0]    io_vecWriteBack_0_bits_elemIdx,
  output [15:0]   io_vecWriteBack_0_bits_mask,
  output [4:0]    io_vecWriteBack_0_bits_splitIndex,
  output          io_vecWriteBack_1_valid,
  output [3:0]    io_vecWriteBack_1_bits_mBIndex,
  output          io_vecWriteBack_1_bits_exceptionVec_3,
  output          io_vecWriteBack_1_bits_exceptionVec_6,
  output          io_vecWriteBack_1_bits_exceptionVec_7,
  output          io_vecWriteBack_1_bits_exceptionVec_15,
  output          io_vecWriteBack_1_bits_exceptionVec_19,
  output          io_vecWriteBack_1_bits_exceptionVec_23,
  output          io_vecWriteBack_1_bits_hasException,
  output [63:0]   io_vecWriteBack_1_bits_vaddr,
  output          io_vecWriteBack_1_bits_vaNeedExt,
  output [63:0]   io_vecWriteBack_1_bits_gpaddr,
  output          io_vecWriteBack_1_bits_isForVSnonLeafPTE,
  output [7:0]    io_vecWriteBack_1_bits_vstart,
  output [7:0]    io_vecWriteBack_1_bits_elemIdx,
  output [15:0]   io_vecWriteBack_1_bits_mask,
  output [4:0]    io_vecWriteBack_1_bits_splitIndex,
  input           io_storeOutValid,
  input           io_storeVecOutValid,
  output          io_sqControl_toStoreQueue_crossPageWithHit,
  output          io_sqControl_toStoreQueue_crossPageCanDeq,
  output [47:0]   io_sqControl_toStoreQueue_paddr,
  output          io_sqControl_toStoreQueue_withSamePtr,
  input           io_sqControl_toStoreMisalignBuffer_sqPtr_flag,
  input  [5:0]    io_sqControl_toStoreMisalignBuffer_sqPtr_value,
  input           io_sqControl_toStoreMisalignBuffer_doDeq,
  input  [6:0]    io_sqControl_toStoreMisalignBuffer_uop_uopIdx,
  input           io_sqControl_toStoreMisalignBuffer_uop_robIdx_flag,
  input  [7:0]    io_sqControl_toStoreMisalignBuffer_uop_robIdx_value,
  output          io_toVecSplit_empty
);

  // 核端的 struct / 向量信号
  redirect_t   redirect;
  enq_req_t    [NUM_ENQ-1:0] enq_bits;
  rob_t        rob;
  split_req_t  split_req;
  split_resp_t split_resp;
  wb_t         wb;
  vec_wb_t     [NUM_VEC_WB-1:0] vec_wb;
  sq_to_mab_t  sq_in;
  sq_to_sq_t   sq_out;
  logic [NUM_ENQ-1:0] enq_valid, enq_ready, enq_revoke;
  logic [NUM_VEC_WB-1:0] vec_wb_valid;

  always_comb begin
    redirect = '0;   // golden 没有端口的字段（上层恒 0 / 被 DCE）补 0
    redirect.robIdx_flag = io_redirect_bits_robIdx_flag;
    redirect.robIdx_value = io_redirect_bits_robIdx_value;
    redirect.level = io_redirect_bits_level;
  end
  always_comb begin
    enq_bits[0] = '0;   // golden 没有端口的字段（上层恒 0 / 被 DCE）补 0
    enq_bits[0].uop.exceptionVec[0] = io_enq_0_req_bits_uop_exceptionVec_0;
    enq_bits[0].uop.exceptionVec[1] = io_enq_0_req_bits_uop_exceptionVec_1;
    enq_bits[0].uop.exceptionVec[2] = io_enq_0_req_bits_uop_exceptionVec_2;
    enq_bits[0].uop.exceptionVec[4] = io_enq_0_req_bits_uop_exceptionVec_4;
    enq_bits[0].uop.exceptionVec[5] = io_enq_0_req_bits_uop_exceptionVec_5;
    enq_bits[0].uop.exceptionVec[8] = io_enq_0_req_bits_uop_exceptionVec_8;
    enq_bits[0].uop.exceptionVec[9] = io_enq_0_req_bits_uop_exceptionVec_9;
    enq_bits[0].uop.exceptionVec[10] = io_enq_0_req_bits_uop_exceptionVec_10;
    enq_bits[0].uop.exceptionVec[11] = io_enq_0_req_bits_uop_exceptionVec_11;
    enq_bits[0].uop.exceptionVec[12] = io_enq_0_req_bits_uop_exceptionVec_12;
    enq_bits[0].uop.exceptionVec[13] = io_enq_0_req_bits_uop_exceptionVec_13;
    enq_bits[0].uop.exceptionVec[14] = io_enq_0_req_bits_uop_exceptionVec_14;
    enq_bits[0].uop.exceptionVec[16] = io_enq_0_req_bits_uop_exceptionVec_16;
    enq_bits[0].uop.exceptionVec[17] = io_enq_0_req_bits_uop_exceptionVec_17;
    enq_bits[0].uop.exceptionVec[18] = io_enq_0_req_bits_uop_exceptionVec_18;
    enq_bits[0].uop.exceptionVec[19] = io_enq_0_req_bits_uop_exceptionVec_19;
    enq_bits[0].uop.exceptionVec[20] = io_enq_0_req_bits_uop_exceptionVec_20;
    enq_bits[0].uop.exceptionVec[21] = io_enq_0_req_bits_uop_exceptionVec_21;
    enq_bits[0].uop.exceptionVec[22] = io_enq_0_req_bits_uop_exceptionVec_22;
    enq_bits[0].uop.trigger = io_enq_0_req_bits_uop_trigger;
    enq_bits[0].uop.ftqPtr_flag = io_enq_0_req_bits_uop_ftqPtr_flag;
    enq_bits[0].uop.ftqPtr_value = io_enq_0_req_bits_uop_ftqPtr_value;
    enq_bits[0].uop.ftqOffset = io_enq_0_req_bits_uop_ftqOffset;
    enq_bits[0].uop.fuType = io_enq_0_req_bits_uop_fuType;
    enq_bits[0].uop.fuOpType = io_enq_0_req_bits_uop_fuOpType;
    enq_bits[0].uop.rfWen = io_enq_0_req_bits_uop_rfWen;
    enq_bits[0].uop.vpu_vstart = io_enq_0_req_bits_uop_vpu_vstart;
    enq_bits[0].uop.vpu_nf = io_enq_0_req_bits_uop_vpu_nf;
    enq_bits[0].uop.vpu_veew = io_enq_0_req_bits_uop_vpu_veew;
    enq_bits[0].uop.uopIdx = io_enq_0_req_bits_uop_uopIdx;
    enq_bits[0].uop.pdest = io_enq_0_req_bits_uop_pdest;
    enq_bits[0].uop.robIdx_flag = io_enq_0_req_bits_uop_robIdx_flag;
    enq_bits[0].uop.robIdx_value = io_enq_0_req_bits_uop_robIdx_value;
    enq_bits[0].uop.debugInfo_eliminatedMove = io_enq_0_req_bits_uop_debugInfo_eliminatedMove;
    enq_bits[0].uop.debugInfo_renameTime = io_enq_0_req_bits_uop_debugInfo_renameTime;
    enq_bits[0].uop.debugInfo_dispatchTime = io_enq_0_req_bits_uop_debugInfo_dispatchTime;
    enq_bits[0].uop.debugInfo_enqRsTime = io_enq_0_req_bits_uop_debugInfo_enqRsTime;
    enq_bits[0].uop.debugInfo_selectTime = io_enq_0_req_bits_uop_debugInfo_selectTime;
    enq_bits[0].uop.debugInfo_issueTime = io_enq_0_req_bits_uop_debugInfo_issueTime;
    enq_bits[0].uop.debugInfo_writebackTime = io_enq_0_req_bits_uop_debugInfo_writebackTime;
    enq_bits[0].uop.debugInfo_runahead_checkpoint_id = io_enq_0_req_bits_uop_debugInfo_runahead_checkpoint_id;
    enq_bits[0].uop.debugInfo_tlbFirstReqTime = io_enq_0_req_bits_uop_debugInfo_tlbFirstReqTime;
    enq_bits[0].uop.debugInfo_tlbRespTime = io_enq_0_req_bits_uop_debugInfo_tlbRespTime;
    enq_bits[0].uop.debug_seqNum_seqNum = io_enq_0_req_bits_uop_debug_seqNum_seqNum;
    enq_bits[0].uop.debug_seqNum_uopIdx = io_enq_0_req_bits_uop_debug_seqNum_uopIdx;
    enq_bits[0].uop.lqIdx_flag = io_enq_0_req_bits_uop_lqIdx_flag;
    enq_bits[0].uop.lqIdx_value = io_enq_0_req_bits_uop_lqIdx_value;
    enq_bits[0].uop.sqIdx_flag = io_enq_0_req_bits_uop_sqIdx_flag;
    enq_bits[0].uop.sqIdx_value = io_enq_0_req_bits_uop_sqIdx_value;
    enq_bits[0].vaddr = io_enq_0_req_bits_vaddr;
    enq_bits[0].mask = io_enq_0_req_bits_mask;
    enq_bits[0].isvec = io_enq_0_req_bits_isvec;
    enq_bits[0].elemIdx = io_enq_0_req_bits_elemIdx;
    enq_bits[0].alignedType = io_enq_0_req_bits_alignedType;
    enq_bits[0].mbIndex = io_enq_0_req_bits_mbIndex;
    enq_bits[0].splitIndex = io_enq_0_req_bits_splitIndex;
  end
  always_comb begin
    enq_bits[1] = '0;   // golden 没有端口的字段（上层恒 0 / 被 DCE）补 0
    enq_bits[1].uop.exceptionVec[0] = io_enq_1_req_bits_uop_exceptionVec_0;
    enq_bits[1].uop.exceptionVec[1] = io_enq_1_req_bits_uop_exceptionVec_1;
    enq_bits[1].uop.exceptionVec[2] = io_enq_1_req_bits_uop_exceptionVec_2;
    enq_bits[1].uop.exceptionVec[4] = io_enq_1_req_bits_uop_exceptionVec_4;
    enq_bits[1].uop.exceptionVec[5] = io_enq_1_req_bits_uop_exceptionVec_5;
    enq_bits[1].uop.exceptionVec[8] = io_enq_1_req_bits_uop_exceptionVec_8;
    enq_bits[1].uop.exceptionVec[9] = io_enq_1_req_bits_uop_exceptionVec_9;
    enq_bits[1].uop.exceptionVec[10] = io_enq_1_req_bits_uop_exceptionVec_10;
    enq_bits[1].uop.exceptionVec[11] = io_enq_1_req_bits_uop_exceptionVec_11;
    enq_bits[1].uop.exceptionVec[12] = io_enq_1_req_bits_uop_exceptionVec_12;
    enq_bits[1].uop.exceptionVec[13] = io_enq_1_req_bits_uop_exceptionVec_13;
    enq_bits[1].uop.exceptionVec[14] = io_enq_1_req_bits_uop_exceptionVec_14;
    enq_bits[1].uop.exceptionVec[16] = io_enq_1_req_bits_uop_exceptionVec_16;
    enq_bits[1].uop.exceptionVec[17] = io_enq_1_req_bits_uop_exceptionVec_17;
    enq_bits[1].uop.exceptionVec[18] = io_enq_1_req_bits_uop_exceptionVec_18;
    enq_bits[1].uop.exceptionVec[19] = io_enq_1_req_bits_uop_exceptionVec_19;
    enq_bits[1].uop.exceptionVec[20] = io_enq_1_req_bits_uop_exceptionVec_20;
    enq_bits[1].uop.exceptionVec[21] = io_enq_1_req_bits_uop_exceptionVec_21;
    enq_bits[1].uop.exceptionVec[22] = io_enq_1_req_bits_uop_exceptionVec_22;
    enq_bits[1].uop.trigger = io_enq_1_req_bits_uop_trigger;
    enq_bits[1].uop.ftqPtr_flag = io_enq_1_req_bits_uop_ftqPtr_flag;
    enq_bits[1].uop.ftqPtr_value = io_enq_1_req_bits_uop_ftqPtr_value;
    enq_bits[1].uop.ftqOffset = io_enq_1_req_bits_uop_ftqOffset;
    enq_bits[1].uop.fuType = io_enq_1_req_bits_uop_fuType;
    enq_bits[1].uop.fuOpType = io_enq_1_req_bits_uop_fuOpType;
    enq_bits[1].uop.rfWen = io_enq_1_req_bits_uop_rfWen;
    enq_bits[1].uop.vpu_vstart = io_enq_1_req_bits_uop_vpu_vstart;
    enq_bits[1].uop.vpu_nf = io_enq_1_req_bits_uop_vpu_nf;
    enq_bits[1].uop.vpu_veew = io_enq_1_req_bits_uop_vpu_veew;
    enq_bits[1].uop.uopIdx = io_enq_1_req_bits_uop_uopIdx;
    enq_bits[1].uop.pdest = io_enq_1_req_bits_uop_pdest;
    enq_bits[1].uop.robIdx_flag = io_enq_1_req_bits_uop_robIdx_flag;
    enq_bits[1].uop.robIdx_value = io_enq_1_req_bits_uop_robIdx_value;
    enq_bits[1].uop.debugInfo_eliminatedMove = io_enq_1_req_bits_uop_debugInfo_eliminatedMove;
    enq_bits[1].uop.debugInfo_renameTime = io_enq_1_req_bits_uop_debugInfo_renameTime;
    enq_bits[1].uop.debugInfo_dispatchTime = io_enq_1_req_bits_uop_debugInfo_dispatchTime;
    enq_bits[1].uop.debugInfo_enqRsTime = io_enq_1_req_bits_uop_debugInfo_enqRsTime;
    enq_bits[1].uop.debugInfo_selectTime = io_enq_1_req_bits_uop_debugInfo_selectTime;
    enq_bits[1].uop.debugInfo_issueTime = io_enq_1_req_bits_uop_debugInfo_issueTime;
    enq_bits[1].uop.debugInfo_writebackTime = io_enq_1_req_bits_uop_debugInfo_writebackTime;
    enq_bits[1].uop.debugInfo_runahead_checkpoint_id = io_enq_1_req_bits_uop_debugInfo_runahead_checkpoint_id;
    enq_bits[1].uop.debugInfo_tlbFirstReqTime = io_enq_1_req_bits_uop_debugInfo_tlbFirstReqTime;
    enq_bits[1].uop.debugInfo_tlbRespTime = io_enq_1_req_bits_uop_debugInfo_tlbRespTime;
    enq_bits[1].uop.debug_seqNum_seqNum = io_enq_1_req_bits_uop_debug_seqNum_seqNum;
    enq_bits[1].uop.debug_seqNum_uopIdx = io_enq_1_req_bits_uop_debug_seqNum_uopIdx;
    enq_bits[1].uop.lqIdx_flag = io_enq_1_req_bits_uop_lqIdx_flag;
    enq_bits[1].uop.lqIdx_value = io_enq_1_req_bits_uop_lqIdx_value;
    enq_bits[1].uop.sqIdx_flag = io_enq_1_req_bits_uop_sqIdx_flag;
    enq_bits[1].uop.sqIdx_value = io_enq_1_req_bits_uop_sqIdx_value;
    enq_bits[1].vaddr = io_enq_1_req_bits_vaddr;
    enq_bits[1].mask = io_enq_1_req_bits_mask;
    enq_bits[1].isvec = io_enq_1_req_bits_isvec;
    enq_bits[1].elemIdx = io_enq_1_req_bits_elemIdx;
    enq_bits[1].alignedType = io_enq_1_req_bits_alignedType;
    enq_bits[1].mbIndex = io_enq_1_req_bits_mbIndex;
    enq_bits[1].splitIndex = io_enq_1_req_bits_splitIndex;
  end
  always_comb begin
    rob = '0;   // golden 没有端口的字段（上层恒 0 / 被 DCE）补 0
    rob.pendingst = io_rob_pendingst;
    rob.pendingPtr_flag = io_rob_pendingPtr_flag;
    rob.pendingPtr_value = io_rob_pendingPtr_value;
  end
  always_comb begin
    split_resp = '0;   // golden 没有端口的字段（上层恒 0 / 被 DCE）补 0
    split_resp.uop.exceptionVec[3] = io_splitStoreResp_bits_uop_exceptionVec_3;
    split_resp.uop.exceptionVec[6] = io_splitStoreResp_bits_uop_exceptionVec_6;
    split_resp.uop.exceptionVec[7] = io_splitStoreResp_bits_uop_exceptionVec_7;
    split_resp.uop.exceptionVec[15] = io_splitStoreResp_bits_uop_exceptionVec_15;
    split_resp.uop.exceptionVec[19] = io_splitStoreResp_bits_uop_exceptionVec_19;
    split_resp.uop.exceptionVec[23] = io_splitStoreResp_bits_uop_exceptionVec_23;
    split_resp.uop.trigger = io_splitStoreResp_bits_uop_trigger;
    split_resp.uop.robIdx_flag = io_splitStoreResp_bits_uop_robIdx_flag;
    split_resp.uop.robIdx_value = io_splitStoreResp_bits_uop_robIdx_value;
    split_resp.vaddr = io_splitStoreResp_bits_vaddr;
    split_resp.vaNeedExt = io_splitStoreResp_bits_vaNeedExt;
    split_resp.paddr = io_splitStoreResp_bits_paddr;
    split_resp.gpaddr = io_splitStoreResp_bits_gpaddr;
    split_resp.nc = io_splitStoreResp_bits_nc;
    split_resp.mmio = io_splitStoreResp_bits_mmio;
    split_resp.memBackTypeMM = io_splitStoreResp_bits_memBackTypeMM;
    split_resp.isForVSnonLeafPTE = io_splitStoreResp_bits_isForVSnonLeafPTE;
    split_resp.vecActive = io_splitStoreResp_bits_vecActive;
    split_resp.need_rep = io_splitStoreResp_bits_need_rep;
  end
  always_comb begin
    sq_in = '0;   // golden 没有端口的字段（上层恒 0 / 被 DCE）补 0
    sq_in.sqPtr_flag = io_sqControl_toStoreMisalignBuffer_sqPtr_flag;
    sq_in.sqPtr_value = io_sqControl_toStoreMisalignBuffer_sqPtr_value;
    sq_in.doDeq = io_sqControl_toStoreMisalignBuffer_doDeq;
    sq_in.uop.uopIdx = io_sqControl_toStoreMisalignBuffer_uop_uopIdx;
    sq_in.uop.robIdx_flag = io_sqControl_toStoreMisalignBuffer_uop_robIdx_flag;
    sq_in.uop.robIdx_value = io_sqControl_toStoreMisalignBuffer_uop_robIdx_value;
  end

  assign enq_valid[0] = io_enq_0_req_valid;
  assign enq_revoke[0] = io_enq_0_revoke;
  assign enq_valid[1] = io_enq_1_req_valid;
  assign enq_revoke[1] = io_enq_1_revoke;
  assign io_enq_0_req_ready = enq_ready[0];
  assign io_enq_1_req_ready = enq_ready[1];
  assign io_vecWriteBack_0_valid = vec_wb_valid[0];
  assign io_vecWriteBack_1_valid = vec_wb_valid[1];

  assign io_splitStoreReq_bits_uop_exceptionVec_0 = split_req.uop.exceptionVec[0];
  assign io_splitStoreReq_bits_uop_exceptionVec_1 = split_req.uop.exceptionVec[1];
  assign io_splitStoreReq_bits_uop_exceptionVec_2 = split_req.uop.exceptionVec[2];
  assign io_splitStoreReq_bits_uop_exceptionVec_4 = split_req.uop.exceptionVec[4];
  assign io_splitStoreReq_bits_uop_exceptionVec_5 = split_req.uop.exceptionVec[5];
  assign io_splitStoreReq_bits_uop_exceptionVec_8 = split_req.uop.exceptionVec[8];
  assign io_splitStoreReq_bits_uop_exceptionVec_9 = split_req.uop.exceptionVec[9];
  assign io_splitStoreReq_bits_uop_exceptionVec_10 = split_req.uop.exceptionVec[10];
  assign io_splitStoreReq_bits_uop_exceptionVec_11 = split_req.uop.exceptionVec[11];
  assign io_splitStoreReq_bits_uop_exceptionVec_12 = split_req.uop.exceptionVec[12];
  assign io_splitStoreReq_bits_uop_exceptionVec_13 = split_req.uop.exceptionVec[13];
  assign io_splitStoreReq_bits_uop_exceptionVec_14 = split_req.uop.exceptionVec[14];
  assign io_splitStoreReq_bits_uop_exceptionVec_16 = split_req.uop.exceptionVec[16];
  assign io_splitStoreReq_bits_uop_exceptionVec_17 = split_req.uop.exceptionVec[17];
  assign io_splitStoreReq_bits_uop_exceptionVec_18 = split_req.uop.exceptionVec[18];
  assign io_splitStoreReq_bits_uop_exceptionVec_19 = split_req.uop.exceptionVec[19];
  assign io_splitStoreReq_bits_uop_exceptionVec_20 = split_req.uop.exceptionVec[20];
  assign io_splitStoreReq_bits_uop_exceptionVec_21 = split_req.uop.exceptionVec[21];
  assign io_splitStoreReq_bits_uop_exceptionVec_22 = split_req.uop.exceptionVec[22];
  assign io_splitStoreReq_bits_uop_trigger = split_req.uop.trigger;
  assign io_splitStoreReq_bits_uop_ftqPtr_flag = split_req.uop.ftqPtr_flag;
  assign io_splitStoreReq_bits_uop_ftqPtr_value = split_req.uop.ftqPtr_value;
  assign io_splitStoreReq_bits_uop_ftqOffset = split_req.uop.ftqOffset;
  assign io_splitStoreReq_bits_uop_fuType = split_req.uop.fuType;
  assign io_splitStoreReq_bits_uop_fuOpType = split_req.uop.fuOpType;
  assign io_splitStoreReq_bits_uop_rfWen = split_req.uop.rfWen;
  assign io_splitStoreReq_bits_uop_vpu_vstart = split_req.uop.vpu_vstart;
  assign io_splitStoreReq_bits_uop_vpu_nf = split_req.uop.vpu_nf;
  assign io_splitStoreReq_bits_uop_vpu_veew = split_req.uop.vpu_veew;
  assign io_splitStoreReq_bits_uop_uopIdx = split_req.uop.uopIdx;
  assign io_splitStoreReq_bits_uop_pdest = split_req.uop.pdest;
  assign io_splitStoreReq_bits_uop_robIdx_flag = split_req.uop.robIdx_flag;
  assign io_splitStoreReq_bits_uop_robIdx_value = split_req.uop.robIdx_value;
  assign io_splitStoreReq_bits_uop_debugInfo_eliminatedMove = split_req.uop.debugInfo_eliminatedMove;
  assign io_splitStoreReq_bits_uop_debugInfo_renameTime = split_req.uop.debugInfo_renameTime;
  assign io_splitStoreReq_bits_uop_debugInfo_dispatchTime = split_req.uop.debugInfo_dispatchTime;
  assign io_splitStoreReq_bits_uop_debugInfo_enqRsTime = split_req.uop.debugInfo_enqRsTime;
  assign io_splitStoreReq_bits_uop_debugInfo_selectTime = split_req.uop.debugInfo_selectTime;
  assign io_splitStoreReq_bits_uop_debugInfo_issueTime = split_req.uop.debugInfo_issueTime;
  assign io_splitStoreReq_bits_uop_debugInfo_writebackTime = split_req.uop.debugInfo_writebackTime;
  assign io_splitStoreReq_bits_uop_debugInfo_runahead_checkpoint_id = split_req.uop.debugInfo_runahead_checkpoint_id;
  assign io_splitStoreReq_bits_uop_debugInfo_tlbFirstReqTime = split_req.uop.debugInfo_tlbFirstReqTime;
  assign io_splitStoreReq_bits_uop_debugInfo_tlbRespTime = split_req.uop.debugInfo_tlbRespTime;
  assign io_splitStoreReq_bits_uop_debug_seqNum_seqNum = split_req.uop.debug_seqNum_seqNum;
  assign io_splitStoreReq_bits_uop_debug_seqNum_uopIdx = split_req.uop.debug_seqNum_uopIdx;
  assign io_splitStoreReq_bits_uop_lqIdx_flag = split_req.uop.lqIdx_flag;
  assign io_splitStoreReq_bits_uop_lqIdx_value = split_req.uop.lqIdx_value;
  assign io_splitStoreReq_bits_uop_sqIdx_flag = split_req.uop.sqIdx_flag;
  assign io_splitStoreReq_bits_uop_sqIdx_value = split_req.uop.sqIdx_value;
  assign io_splitStoreReq_bits_vaddr = split_req.vaddr;
  assign io_splitStoreReq_bits_mask = split_req.mask;
  assign io_splitStoreReq_bits_isvec = split_req.isvec;
  assign io_splitStoreReq_bits_is128bit = split_req.is128bit;
  assign io_splitStoreReq_bits_isFinalSplit = split_req.isFinalSplit;
  assign io_writeBack_bits_uop_exceptionVec_3 = wb.uop.exceptionVec[3];
  assign io_writeBack_bits_uop_exceptionVec_6 = wb.uop.exceptionVec[6];
  assign io_writeBack_bits_uop_exceptionVec_7 = wb.uop.exceptionVec[7];
  assign io_writeBack_bits_uop_exceptionVec_15 = wb.uop.exceptionVec[15];
  assign io_writeBack_bits_uop_exceptionVec_19 = wb.uop.exceptionVec[19];
  assign io_writeBack_bits_uop_exceptionVec_23 = wb.uop.exceptionVec[23];
  assign io_writeBack_bits_uop_trigger = wb.uop.trigger;
  assign io_writeBack_bits_uop_rfWen = wb.uop.rfWen;
  assign io_writeBack_bits_uop_pdest = wb.uop.pdest;
  assign io_writeBack_bits_uop_robIdx_flag = wb.uop.robIdx_flag;
  assign io_writeBack_bits_uop_robIdx_value = wb.uop.robIdx_value;
  assign io_writeBack_bits_uop_debugInfo_eliminatedMove = wb.uop.debugInfo_eliminatedMove;
  assign io_writeBack_bits_uop_debugInfo_renameTime = wb.uop.debugInfo_renameTime;
  assign io_writeBack_bits_uop_debugInfo_dispatchTime = wb.uop.debugInfo_dispatchTime;
  assign io_writeBack_bits_uop_debugInfo_enqRsTime = wb.uop.debugInfo_enqRsTime;
  assign io_writeBack_bits_uop_debugInfo_selectTime = wb.uop.debugInfo_selectTime;
  assign io_writeBack_bits_uop_debugInfo_issueTime = wb.uop.debugInfo_issueTime;
  assign io_writeBack_bits_uop_debugInfo_writebackTime = wb.uop.debugInfo_writebackTime;
  assign io_writeBack_bits_uop_debugInfo_runahead_checkpoint_id = wb.uop.debugInfo_runahead_checkpoint_id;
  assign io_writeBack_bits_uop_debugInfo_tlbFirstReqTime = wb.uop.debugInfo_tlbFirstReqTime;
  assign io_writeBack_bits_uop_debugInfo_tlbRespTime = wb.uop.debugInfo_tlbRespTime;
  assign io_writeBack_bits_uop_debug_seqNum_seqNum = wb.uop.debug_seqNum_seqNum;
  assign io_writeBack_bits_uop_debug_seqNum_uopIdx = wb.uop.debug_seqNum_uopIdx;
  assign io_writeBack_bits_uop_sqIdx_flag = wb.uop.sqIdx_flag;
  assign io_writeBack_bits_uop_sqIdx_value = wb.uop.sqIdx_value;
  assign io_writeBack_bits_debug_isMMIO = wb.debug_isMMIO;
  assign io_writeBack_bits_debug_isNCIO = wb.debug_isNCIO;
  assign io_writeBack_bits_debug_paddr = wb.debug_paddr;
  assign io_writeBack_bits_debug_vaddr = wb.debug_vaddr;
  assign io_vecWriteBack_0_bits_mBIndex = vec_wb[0].mBIndex;
  assign io_vecWriteBack_0_bits_exceptionVec_3 = vec_wb[0].exceptionVec[3];
  assign io_vecWriteBack_0_bits_exceptionVec_6 = vec_wb[0].exceptionVec[6];
  assign io_vecWriteBack_0_bits_exceptionVec_7 = vec_wb[0].exceptionVec[7];
  assign io_vecWriteBack_0_bits_exceptionVec_15 = vec_wb[0].exceptionVec[15];
  assign io_vecWriteBack_0_bits_exceptionVec_19 = vec_wb[0].exceptionVec[19];
  assign io_vecWriteBack_0_bits_exceptionVec_23 = vec_wb[0].exceptionVec[23];
  assign io_vecWriteBack_0_bits_hasException = vec_wb[0].hasException;
  assign io_vecWriteBack_0_bits_vaddr = vec_wb[0].vaddr;
  assign io_vecWriteBack_0_bits_vaNeedExt = vec_wb[0].vaNeedExt;
  assign io_vecWriteBack_0_bits_gpaddr = vec_wb[0].gpaddr;
  assign io_vecWriteBack_0_bits_isForVSnonLeafPTE = vec_wb[0].isForVSnonLeafPTE;
  assign io_vecWriteBack_0_bits_vstart = vec_wb[0].vstart;
  assign io_vecWriteBack_0_bits_elemIdx = vec_wb[0].elemIdx;
  assign io_vecWriteBack_0_bits_mask = vec_wb[0].mask;
  assign io_vecWriteBack_0_bits_splitIndex = vec_wb[0].splitIndex;
  assign io_vecWriteBack_1_bits_mBIndex = vec_wb[1].mBIndex;
  assign io_vecWriteBack_1_bits_exceptionVec_3 = vec_wb[1].exceptionVec[3];
  assign io_vecWriteBack_1_bits_exceptionVec_6 = vec_wb[1].exceptionVec[6];
  assign io_vecWriteBack_1_bits_exceptionVec_7 = vec_wb[1].exceptionVec[7];
  assign io_vecWriteBack_1_bits_exceptionVec_15 = vec_wb[1].exceptionVec[15];
  assign io_vecWriteBack_1_bits_exceptionVec_19 = vec_wb[1].exceptionVec[19];
  assign io_vecWriteBack_1_bits_exceptionVec_23 = vec_wb[1].exceptionVec[23];
  assign io_vecWriteBack_1_bits_hasException = vec_wb[1].hasException;
  assign io_vecWriteBack_1_bits_vaddr = vec_wb[1].vaddr;
  assign io_vecWriteBack_1_bits_vaNeedExt = vec_wb[1].vaNeedExt;
  assign io_vecWriteBack_1_bits_gpaddr = vec_wb[1].gpaddr;
  assign io_vecWriteBack_1_bits_isForVSnonLeafPTE = vec_wb[1].isForVSnonLeafPTE;
  assign io_vecWriteBack_1_bits_vstart = vec_wb[1].vstart;
  assign io_vecWriteBack_1_bits_elemIdx = vec_wb[1].elemIdx;
  assign io_vecWriteBack_1_bits_mask = vec_wb[1].mask;
  assign io_vecWriteBack_1_bits_splitIndex = vec_wb[1].splitIndex;
  assign io_sqControl_toStoreQueue_crossPageWithHit = sq_out.crossPageWithHit;
  assign io_sqControl_toStoreQueue_crossPageCanDeq = sq_out.crossPageCanDeq;
  assign io_sqControl_toStoreQueue_paddr = sq_out.paddr;
  assign io_sqControl_toStoreQueue_withSamePtr = sq_out.withSamePtr;

  xs_StoreMisalignBuffer_core u_core (
    .clock (clock),
    .reset (reset),
    .redirect_valid (io_redirect_valid),
    .split_req_ready (io_splitStoreReq_ready),
    .split_req_valid (io_splitStoreReq_valid),
    .split_resp_valid (io_splitStoreResp_valid),
    .wb_ready (io_writeBack_ready),
    .wb_valid (io_writeBack_valid),
    .store_out_valid (io_storeOutValid),
    .store_vec_out_valid (io_storeVecOutValid),
    .to_vec_split_empty (io_toVecSplit_empty),
    .enq_valid (enq_valid),
    .enq_ready (enq_ready),
    .enq_revoke (enq_revoke),
    .vec_wb_valid (vec_wb_valid),
    .redirect (redirect),
    .enq_bits (enq_bits),
    .rob (rob),
    .split_req (split_req),
    .split_resp (split_resp),
    .wb (wb),
    .vec_wb (vec_wb),
    .sq_in (sq_in),
    .sq_out (sq_out)
  );

endmodule
// END GENERATED(wrapper)
