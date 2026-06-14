// =============================================================================
// UT-only: 关闭 golden RASStack 内仅供仿真的 $fatal 越界断言 (随机激励会触发
//   distanceBetween(commit_meta_TOSW, BOS) > 2 的非法 RAS 使用断言)。
//   仅在非 SYNTHESIS (即 VCS UT) 下生效; FM 用 -define SYNTHESIS, 不受影响,
//   断言本身在 SYNTHESIS 下也被 golden 用 `ifndef SYNTHESIS 剔除。
//   本文件是 RTL_SRCS 首个被编译的文件, 抢先 define 使 golden 的 `ifndef 跳过。
// =============================================================================
`ifndef SYNTHESIS
  `ifndef STOP_COND_
    `define STOP_COND_ 0
  `endif
  `ifndef ASSERT_VERBOSE_COND_
    `define ASSERT_VERBOSE_COND_ 0
  `endif
`endif

// =============================================================================
// xs_RAS_core / xs_RASStack —— 返回地址栈预测器 (Return Address Stack)
//
// 对应 Chisel: xiangshan.frontend.RAS / RAS.RASStack
//
// 顶层 xs_RAS_core 是 BasePredictor 的一个预测器：io_in / io_out 流水 bundle 绝大
// 部分原样透传 (passthrough)，RAS 只改写其中 jalr_target / targets.last 等与返回
// 目标相关的少数字段，并维护 s1/s2/s3 流水的 pc 复制寄存器、redirect/update 的
// 输入打拍寄存器、s3 meta 寄存器等。真正的栈逻辑在子模块 xs_RASStack 中。
//
// xs_RASStack 维护两套栈：
//   - spec 推测栈: spec_queue[RasSpecSize] (retAddr+ctr) + spec_nos[RasSpecSize]
//     (每条记录指向其下一项 NOS 的环形指针)，配 ssp/sctr/TOSR/TOSW/BOS 指针。
//   - commit 提交栈: commit_stack[RasSize] (retAddr+ctr) + nsp。
//   还有 s2→s3 写旁路 (writeBypass*) 与 redirect / s3_cancel 的恢复逻辑。
//
// 环形指针 (RASPtr) = {flag, value}；flag 为环绕翻转位。比较函数:
//   isBefore(a,b) = (a.flag ^ b.flag) ^ (a.value < b.value)
//   即 a 严格早于 b。distanceBetween 用 6 位带翻转的差值。
//
// 为便于 Formality 按名字自动配对寄存器，本文件里栈的状态元件采用与 golden 完全
// 一致的"展平标量"命名 (commit_stack_<i>_retAddr 等)；组合读出与控制逻辑则用可读
// 的聚合 wire / 函数重写。
//
// 参数 (KunmingHu V2R2): RasSize=16, RasSpecSize=32, RasCtrSize=3, VAddrBits=50。
// =============================================================================

// -----------------------------------------------------------------------------
// xs_RASStack: 双栈返回地址栈核心
// -----------------------------------------------------------------------------
module xs_RASStack (
  input         clock,
  input         reset,
  input         io_spec_push_valid,
  input         io_spec_pop_valid,
  input  [49:0] io_spec_push_addr,
  input         io_s2_fire,
  input         io_s3_fire,
  input         io_s3_cancel,
  input  [3:0]  io_s3_meta_ssp,
  input  [2:0]  io_s3_meta_sctr,
  input         io_s3_meta_TOSW_flag,
  input  [4:0]  io_s3_meta_TOSW_value,
  input         io_s3_meta_TOSR_flag,
  input  [4:0]  io_s3_meta_TOSR_value,
  input         io_s3_meta_NOS_flag,
  input  [4:0]  io_s3_meta_NOS_value,
  input         io_s3_missed_pop,
  input         io_s3_missed_push,
  input  [49:0] io_s3_pushAddr,
  output [49:0] io_spec_pop_addr,
  input         io_commit_valid,
  input         io_commit_push_valid,
  input         io_commit_pop_valid,
  input         io_commit_meta_TOSW_flag,
  input  [4:0]  io_commit_meta_TOSW_value,
  input  [3:0]  io_commit_meta_ssp,
  input         io_redirect_valid,
  input         io_redirect_isCall,
  input         io_redirect_isRet,
  input  [3:0]  io_redirect_meta_ssp,
  input  [2:0]  io_redirect_meta_sctr,
  input         io_redirect_meta_TOSW_flag,
  input  [4:0]  io_redirect_meta_TOSW_value,
  input         io_redirect_meta_TOSR_flag,
  input  [4:0]  io_redirect_meta_TOSR_value,
  input         io_redirect_meta_NOS_flag,
  input  [4:0]  io_redirect_meta_NOS_value,
  input  [49:0] io_redirect_callAddr,
  output [3:0]  io_ssp,
  output [2:0]  io_sctr,
  output        io_TOSR_flag,
  output [4:0]  io_TOSR_value,
  output        io_TOSW_flag,
  output [4:0]  io_TOSW_value,
  output        io_NOS_flag,
  output [4:0]  io_NOS_value,
  output        io_spec_near_overflow
);

  localparam int RAS_SIZE      = 16;  // commit 栈深度
  localparam int RAS_SPEC_SIZE = 32;  // spec 栈深度
  localparam int CTR_MAX       = 7;   // (1<<RasCtrSize)-1

  // --------------------------------------------------------------------------
  // 状态寄存器
  // commit 栈用与 golden 一致的"展平标量"命名 (commit_stack_<N>_retAddr/ctr), 这样
  // Formality 能按名字 1:1 配对 (含正确位序); 否则二维数组寄存器的位序会被签名分析
  // 弄混。读出/写入仍用可读的数组视图 + 译码, 见下。spec 栈用普通数组 (FM 可正常配对)。
  // --------------------------------------------------------------------------
  // commit 栈: 展平标量存储
  reg  [49:0] commit_stack_0_retAddr,  commit_stack_1_retAddr,  commit_stack_2_retAddr,  commit_stack_3_retAddr;
  reg  [49:0] commit_stack_4_retAddr,  commit_stack_5_retAddr,  commit_stack_6_retAddr,  commit_stack_7_retAddr;
  reg  [49:0] commit_stack_8_retAddr,  commit_stack_9_retAddr,  commit_stack_10_retAddr, commit_stack_11_retAddr;
  reg  [49:0] commit_stack_12_retAddr, commit_stack_13_retAddr, commit_stack_14_retAddr, commit_stack_15_retAddr;
  reg  [2:0]  commit_stack_0_ctr,  commit_stack_1_ctr,  commit_stack_2_ctr,  commit_stack_3_ctr;
  reg  [2:0]  commit_stack_4_ctr,  commit_stack_5_ctr,  commit_stack_6_ctr,  commit_stack_7_ctr;
  reg  [2:0]  commit_stack_8_ctr,  commit_stack_9_ctr,  commit_stack_10_ctr, commit_stack_11_ctr;
  reg  [2:0]  commit_stack_12_ctr, commit_stack_13_ctr, commit_stack_14_ctr, commit_stack_15_ctr;
  // commit 栈: 可读数组视图 (组合, 供索引读出)
  wire [49:0] commit_stack_retAddr [0:RAS_SIZE-1];
  wire [2:0]  commit_stack_ctr     [0:RAS_SIZE-1];
  assign commit_stack_retAddr[0]=commit_stack_0_retAddr;   assign commit_stack_ctr[0]=commit_stack_0_ctr;
  assign commit_stack_retAddr[1]=commit_stack_1_retAddr;   assign commit_stack_ctr[1]=commit_stack_1_ctr;
  assign commit_stack_retAddr[2]=commit_stack_2_retAddr;   assign commit_stack_ctr[2]=commit_stack_2_ctr;
  assign commit_stack_retAddr[3]=commit_stack_3_retAddr;   assign commit_stack_ctr[3]=commit_stack_3_ctr;
  assign commit_stack_retAddr[4]=commit_stack_4_retAddr;   assign commit_stack_ctr[4]=commit_stack_4_ctr;
  assign commit_stack_retAddr[5]=commit_stack_5_retAddr;   assign commit_stack_ctr[5]=commit_stack_5_ctr;
  assign commit_stack_retAddr[6]=commit_stack_6_retAddr;   assign commit_stack_ctr[6]=commit_stack_6_ctr;
  assign commit_stack_retAddr[7]=commit_stack_7_retAddr;   assign commit_stack_ctr[7]=commit_stack_7_ctr;
  assign commit_stack_retAddr[8]=commit_stack_8_retAddr;   assign commit_stack_ctr[8]=commit_stack_8_ctr;
  assign commit_stack_retAddr[9]=commit_stack_9_retAddr;   assign commit_stack_ctr[9]=commit_stack_9_ctr;
  assign commit_stack_retAddr[10]=commit_stack_10_retAddr; assign commit_stack_ctr[10]=commit_stack_10_ctr;
  assign commit_stack_retAddr[11]=commit_stack_11_retAddr; assign commit_stack_ctr[11]=commit_stack_11_ctr;
  assign commit_stack_retAddr[12]=commit_stack_12_retAddr; assign commit_stack_ctr[12]=commit_stack_12_ctr;
  assign commit_stack_retAddr[13]=commit_stack_13_retAddr; assign commit_stack_ctr[13]=commit_stack_13_ctr;
  assign commit_stack_retAddr[14]=commit_stack_14_retAddr; assign commit_stack_ctr[14]=commit_stack_14_ctr;
  assign commit_stack_retAddr[15]=commit_stack_15_retAddr; assign commit_stack_ctr[15]=commit_stack_15_ctr;
  // spec 栈
  reg  [49:0] spec_queue_retAddr   [0:RAS_SPEC_SIZE-1];
  reg  [2:0]  spec_queue_ctr       [0:RAS_SPEC_SIZE-1];
  reg         spec_nos_flag        [0:RAS_SPEC_SIZE-1];
  reg  [4:0]  spec_nos_value       [0:RAS_SPEC_SIZE-1];

  // commit 栈 retAddr 写译码 (组合): 仅 push 新建项时写 1 个 retAddr (索引 meta_ssp+1)
  reg        commit_adr_we;   reg [3:0] commit_adr_idx;   reg [49:0] commit_adr_val;

  reg  [3:0]  nsp;
  reg  [3:0]  ssp;
  reg  [2:0]  sctr;
  reg         TOSR_flag;  reg [4:0] TOSR_value;
  reg         TOSW_flag;  reg [4:0] TOSW_value;
  reg         BOS_flag;   reg [4:0] BOS_value;
  reg         spec_near_overflowed;

  reg  [49:0] writeBypassEntry_retAddr;
  reg  [2:0]  writeBypassEntry_ctr;
  reg         writeBypassNos_flag;
  reg  [4:0]  writeBypassNos_value;
  reg         writeBypassValid;

  reg  [49:0] timingTop_retAddr;

  // s2 锁存、待 s3 真正写入的条目
  reg  [49:0] realWriteEntry_next_retAddr;
  reg  [2:0]  realWriteEntry_next_ctr;
  reg  [4:0]  realWriteAddr_next_value;
  reg         realNos_next_flag;
  reg  [4:0]  realNos_next_value;
  reg         realPush_r;    // s2 锁存的 spec_push_valid
  reg         realPush_REG;  // 上拍 redirect&isCall

  // --------------------------------------------------------------------------
  // 环形指针比较辅助
  // --------------------------------------------------------------------------
  // isBefore(a, b): a 严格早于 b
  function automatic logic isBefore(input logic af, input logic [4:0] av,
                                    input logic bf, input logic [4:0] bv);
    isBefore = (af ^ bf) ^ (av < bv);
  endfunction
  // 指针在 [BOS, TOSW) 范围内: 不早于 BOS 且 严格早于 TOSW
  // 注意: BOS 显式作为入参传入 (而非读模块级寄存器), 这样 wire 连续赋值能正确将
  // BOS 纳入敏感列表 —— 否则 BOS 变化而 r/w 不变时组合输出不会重算 (VCS 仿真坑)。
  function automatic logic ptrInRange(input logic rf, input logic [4:0] rv,
                                      input logic wf, input logic [4:0] wv,
                                      input logic bf, input logic [4:0] bv);
    ptrInRange = (~isBefore(rf, rv, bf, bv)) & isBefore(rf, rv, wf, wv);
  endfunction

  // --------------------------------------------------------------------------
  // 组合读出: spec_queue / spec_nos / commit_stack 的索引读
  // --------------------------------------------------------------------------
  wire [49:0] specQ_at_TOSR_addr = spec_queue_retAddr[TOSR_value];
  wire [2:0]  specQ_at_TOSR_ctr  = spec_queue_ctr   [TOSR_value];
  wire [49:0] commit_at_ssp_addr = commit_stack_retAddr[ssp];
  wire [2:0]  commit_at_ssp_ctr  = commit_stack_ctr   [ssp];

  // 当前 top: writeBypass 优先 → spec 在范围内 → commit
  wire        topEntry_inRange = ptrInRange(TOSR_flag, TOSR_value, TOSW_flag, TOSW_value, BOS_flag, BOS_value);
  wire [49:0] topEntry_inflight_addr = topEntry_inRange ? specQ_at_TOSR_addr : commit_at_ssp_addr;
  wire [49:0] topEntry_retAddr = writeBypassValid ? writeBypassEntry_retAddr : topEntry_inflight_addr;

  // 当前 topNos: writeBypass 优先 → spec_nos[TOSR]
  wire        topNos_flag  = writeBypassValid ? writeBypassNos_flag  : spec_nos_flag [TOSR_value];
  wire [4:0]  topNos_value = writeBypassValid ? writeBypassNos_value : spec_nos_value[TOSR_value];

  // --------------------------------------------------------------------------
  // writeBypassValid 的下一拍值 (组合)
  //   redirect&isCall → 1; redirect → 0; s2_fire → spec_push_valid;
  //   s3_fire → 0; else 保持
  // --------------------------------------------------------------------------
  wire redirectIsCall = io_redirect_valid & io_redirect_isCall;
  wire writeBypassValidWire =
        redirectIsCall |
        (~io_redirect_valid &
          (io_s2_fire ? io_spec_push_valid : (~io_s3_fire & writeBypassValid)));

  // --------------------------------------------------------------------------
  // writeEntry: 本拍要写入 spec 的条目 (push 来源 = redirect call 地址 或 s2 地址)
  // --------------------------------------------------------------------------
  wire [49:0] writeEntry_retAddr = redirectIsCall ? io_redirect_callAddr : io_spec_push_addr;

  // redirect 路径上的 top (不走 bypass)
  wire        redTop_inRange =
        ptrInRange(io_redirect_meta_TOSR_flag, io_redirect_meta_TOSR_value,
                   io_redirect_meta_TOSW_flag, io_redirect_meta_TOSW_value, BOS_flag, BOS_value);
  wire [49:0] redTop_addr = redTop_inRange ? spec_queue_retAddr[io_redirect_meta_TOSR_value]
                                           : commit_stack_retAddr[io_redirect_meta_ssp];
  wire [2:0]  redTop_ctr  = redTop_inRange ? spec_queue_ctr[io_redirect_meta_TOSR_value]
                                           : commit_stack_ctr[io_redirect_meta_ssp];

  // s3 路径上的 top
  wire        s3Top_inRange =
        ptrInRange(io_s3_meta_TOSR_flag, io_s3_meta_TOSR_value,
                   io_s3_meta_TOSW_flag, io_s3_meta_TOSW_value, BOS_flag, BOS_value);
  wire [49:0] s3Top_addr = s3Top_inRange ? spec_queue_retAddr[io_s3_meta_TOSR_value]
                                         : commit_stack_retAddr[io_s3_meta_ssp];
  wire [2:0]  s3Top_ctr  = s3Top_inRange ? spec_queue_ctr[io_s3_meta_TOSR_value]
                                         : commit_stack_ctr[io_s3_meta_ssp];

  wire [2:0] sctr_p1    = sctr + 3'h1;
  wire [2:0] redSctr_p1 = io_redirect_meta_sctr + 3'h1;

  // 当前 top 的 ctr (走 bypass 优先)，用于计算"新 writeEntry 的 ctr"
  wire [2:0] topEntry_ctr =
        writeBypassValid ? writeBypassEntry_ctr
                         : (topEntry_inRange ? specQ_at_TOSR_ctr : commit_at_ssp_ctr);

  // -- writeEntry.ctr 自增判定 (Scala: topEntry.retAddr==addr && topEntry.ctr<max) --
  // redirect call 路径用 redirectTopEntry; 普通 push 路径用当前 topEntry
  wire writeEntry_ctr_redInc  = (redTop_addr == io_redirect_callAddr) & (redTop_ctr  != CTR_MAX[2:0]);
  wire writeEntry_ctr_specInc = (topEntry_retAddr == io_spec_push_addr) & (topEntry_ctr != CTR_MAX[2:0]);

  // -- 推测栈 sctr 寄存器自增判定 (Scala specPush: topEntry.retAddr==addr && currentSctr<max) --
  // 注意: 用的是 currentSctr (指针 sctr / meta_sctr), 不是 topEntry.ctr
  wire push_addr_hit     = (topEntry_retAddr == io_spec_push_addr);
  wire redPush_addr_hit  = (redTop_addr == io_redirect_callAddr);
  wire specPush_sctr_inc = push_addr_hit    & (sctr != CTR_MAX[2:0]);
  wire redPush_sctr_inc  = redPush_addr_hit & (io_redirect_meta_sctr != CTR_MAX[2:0]);

  // --------------------------------------------------------------------------
  // realPush: s3 真正提交到 spec 栈
  // --------------------------------------------------------------------------
  wire realPush = (io_s3_fire & ((~io_s3_cancel & realPush_r) | io_s3_missed_push)) | realPush_REG;

  // realWrite*: redirect 路径用 s2 锁存值; s3_missed_push 用 s3 现场值
  wire use_next = io_redirect_isCall | ~io_s3_missed_push;
  wire [49:0] realWriteEntry_retAddr = use_next ? realWriteEntry_next_retAddr : io_s3_pushAddr;
  wire [4:0]  realWriteAddr_value    = use_next ? realWriteAddr_next_value   : io_s3_meta_TOSW_value;
  wire        realNos_flag           = use_next ? realNos_next_flag          : io_s3_meta_TOSR_flag;
  wire [4:0]  realNos_value          = use_next ? realNos_next_value         : io_s3_meta_TOSR_value;
  // s3_missed_push 时计算的 ctr
  // spec_queue 写入用 s3TopEntry.ctr; sctr 寄存器用 s3_meta.sctr (两套判定)
  wire s3Push_addr_hit   = (s3Top_addr == io_s3_pushAddr);
  wire s3miss_queue_inc  = s3Push_addr_hit & (s3Top_ctr != CTR_MAX[2:0]);
  wire s3Push_sctr_inc   = s3Push_addr_hit & (io_s3_meta_sctr != CTR_MAX[2:0]);
  wire [2:0] s3meta_sctr_p1 = io_s3_meta_sctr + 3'h1;

  // --------------------------------------------------------------------------
  // commit 栈访问
  // --------------------------------------------------------------------------
  wire [2:0] commit_top_ctr = commit_stack_ctr[nsp];
  // commit_push_addr 来自 spec 栈 @ TOSW
  wire [49:0] commit_push_addr = spec_queue_retAddr[io_commit_meta_TOSW_value];
  // nsp_update: ssp != nsp 时强制对齐到 commit ssp
  wire [3:0] nsp_update = (io_commit_meta_ssp != nsp) ? io_commit_meta_ssp : nsp;
  // commit push: ctr<max && top.addr==push.addr → ++ctr@nsp_update 否则 ++nsp 新建
  wire commit_push_incCtr = (commit_top_ctr != CTR_MAX[2:0]) & (commit_stack_retAddr[nsp] == commit_push_addr);
  wire [3:0] nsp_update_p1 = io_commit_meta_ssp + 4'h1;
  // commit pop: ctr>0 → --ctr 否则 --nsp
  wire commit_pop_decCtr = |commit_top_ctr;

  // --------------------------------------------------------------------------
  // BOS 更新 / near overflow / 越界断言
  // --------------------------------------------------------------------------
  // distanceBetween(a,b) = a - b 的 6 位带翻转环形差
  function automatic logic [5:0] distBetween(input logic af, input logic [4:0] av,
                                             input logic bf, input logic [4:0] bv);
    distBetween = (af == bf) ? {1'b0, (av - bv)}
                             : ({1'b0, av} - 6'h20) - {1'b0, bv};
  endfunction
  wire [5:0] dist_commitTOSW_BOS = distBetween(io_commit_meta_TOSW_flag, io_commit_meta_TOSW_value,
                                               BOS_flag, BOS_value);
  wire commit_BOS_advance = io_commit_valid & (dist_commitTOSW_BOS > 6'h2);
  // BOS = specPtrDec(commit_meta_TOSW)
  wire [5:0] bos_dec = {io_commit_meta_TOSW_flag, io_commit_meta_TOSW_value} + 6'h1F;

  // TOSW 自增 (push)
  wire [5:0] TOSW_inc      = {TOSW_flag, TOSW_value} + 6'h1;
  wire [5:0] redTOSW_inc   = {io_redirect_meta_TOSW_flag, io_redirect_meta_TOSW_value} + 6'h1;
  wire [5:0] s3TOSW_inc    = {io_s3_meta_TOSW_flag, io_s3_meta_TOSW_value} + 6'h1;

  wire [3:0] ssp_dec       = ssp - 4'h1;
  wire [3:0] redSsp_dec    = io_redirect_meta_ssp - 4'h1;
  wire [3:0] s3Ssp_dec     = io_s3_meta_ssp - 4'h1;

  // --------------------------------------------------------------------------
  // timingTop 的下一拍值 (组合, 与主时序分支优先级一致)
  // 用 always_comb 而非 function, 以免 Formality 把"函数读非局部变量"判为 RTL
  // 解释错误而无法 elaborate。
  // --------------------------------------------------------------------------
  reg  [49:0] timingTop_next;
  reg  [3:0]  tt_ssp_sel;
  always @* begin
    if (writeBypassValidWire) begin
      timingTop_next = (redirectIsCall | io_spec_push_valid)
                        ? writeEntry_retAddr : writeBypassEntry_retAddr;
    end else if (io_redirect_valid & io_redirect_isRet) begin
      if (ptrInRange(io_redirect_meta_NOS_flag, io_redirect_meta_NOS_value,
                     io_redirect_meta_TOSW_flag, io_redirect_meta_TOSW_value, BOS_flag, BOS_value)) begin
        timingTop_next = spec_queue_retAddr[io_redirect_meta_NOS_value];
      end else begin
        tt_ssp_sel = (|io_redirect_meta_sctr) ? io_redirect_meta_ssp : redSsp_dec;
        timingTop_next = commit_stack_retAddr[tt_ssp_sel];
      end
    end else if (io_redirect_valid) begin
      timingTop_next = redTop_inRange ? spec_queue_retAddr[io_redirect_meta_TOSR_value]
                                      : commit_stack_retAddr[io_redirect_meta_ssp];
    end else if (io_spec_pop_valid) begin
      if (ptrInRange(topNos_flag, topNos_value, TOSW_flag, TOSW_value, BOS_flag, BOS_value)) begin
        timingTop_next = spec_queue_retAddr[topNos_value];
      end else begin
        tt_ssp_sel = (|sctr) ? ssp : ssp_dec;
        timingTop_next = commit_stack_retAddr[tt_ssp_sel];
      end
    end else if (realPush) begin
      timingTop_next = realWriteEntry_retAddr;
    end else if (io_s3_cancel) begin
      if (io_s3_missed_push) begin
        timingTop_next = io_s3_pushAddr;
      end else if (io_s3_missed_pop) begin
        if (ptrInRange(io_s3_meta_NOS_flag, io_s3_meta_NOS_value,
                       io_s3_meta_TOSW_flag, io_s3_meta_TOSW_value, BOS_flag, BOS_value)) begin
          timingTop_next = spec_queue_retAddr[io_s3_meta_NOS_value];
        end else begin
          tt_ssp_sel = (|io_s3_meta_sctr) ? io_s3_meta_ssp : s3Ssp_dec;
          timingTop_next = commit_stack_retAddr[tt_ssp_sel];
        end
      end else begin
        timingTop_next = s3Top_inRange ? spec_queue_retAddr[io_s3_meta_TOSR_value]
                                       : commit_stack_retAddr[io_s3_meta_ssp];
      end
    end else begin
      timingTop_next = topEntry_inRange ? specQ_at_TOSR_addr : commit_at_ssp_addr;
    end
  end

  // commit retAddr 写译码 (组合)
  always @* begin
    commit_adr_we = 1'b0; commit_adr_idx = 4'h0; commit_adr_val = 50'h0;
    if (io_commit_push_valid & ~commit_push_incCtr) begin
      commit_adr_we = 1'b1; commit_adr_idx = nsp_update_p1; commit_adr_val = commit_push_addr;
    end
  end

  // commit ctr 写的公共组合量 (与 golden 一致, 支持 push 与 pop 同周期写不同项)
  wire [2:0] commit_ctr_inc = commit_top_ctr + 3'h1;   // ctr[nsp]+1
  wire [2:0] commit_ctr_dec = commit_top_ctr - 3'h1;   // ctr[nsp]-1
  wire       commit_pop_dec = io_commit_pop_valid & commit_pop_decCtr; // pop 且 ctr[nsp]>0

  // --------------------------------------------------------------------------
  // 时序: commit 栈展平寄存器锁存 (异步复位)
  // 每索引 N 的 ctr 下一拍逻辑严格复刻 golden:
  //   push&incCtr:   N==meta_ssp        -> ctr[nsp]+1
  //   push&!incCtr:  N==meta_ssp+1      -> 0; 否则 pop_dec & N==meta_ssp -> ctr[nsp]-1
  //   !push:         pop_dec & N==meta_ssp -> ctr[nsp]-1
  // (push 新建项与 pop 递减可同周期命中不同索引)
  // --------------------------------------------------------------------------
  `define CMT_RST(N)  begin commit_stack_``N``_retAddr <= 50'h0; commit_stack_``N``_ctr <= 3'h0; end
  `define CMT_WR(N) \
      if (commit_adr_we & (commit_adr_idx == 4'd``N``)) commit_stack_``N``_retAddr <= commit_adr_val; \
      if (io_commit_push_valid) begin \
        if (commit_push_incCtr) begin \
          if (nsp_update == 4'd``N``)             commit_stack_``N``_ctr <= commit_ctr_inc; \
        end else begin \
          if (nsp_update_p1 == 4'd``N``)          commit_stack_``N``_ctr <= 3'h0; \
          else if (commit_pop_dec & (nsp_update == 4'd``N``)) commit_stack_``N``_ctr <= commit_ctr_dec; \
        end \
      end else if (commit_pop_dec & (nsp_update == 4'd``N``)) commit_stack_``N``_ctr <= commit_ctr_dec;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      `CMT_RST(0)  `CMT_RST(1)  `CMT_RST(2)  `CMT_RST(3)
      `CMT_RST(4)  `CMT_RST(5)  `CMT_RST(6)  `CMT_RST(7)
      `CMT_RST(8)  `CMT_RST(9)  `CMT_RST(10) `CMT_RST(11)
      `CMT_RST(12) `CMT_RST(13) `CMT_RST(14) `CMT_RST(15)
    end else begin
      `CMT_WR(0)  `CMT_WR(1)  `CMT_WR(2)  `CMT_WR(3)
      `CMT_WR(4)  `CMT_WR(5)  `CMT_WR(6)  `CMT_WR(7)
      `CMT_WR(8)  `CMT_WR(9)  `CMT_WR(10) `CMT_WR(11)
      `CMT_WR(12) `CMT_WR(13) `CMT_WR(14) `CMT_WR(15)
    end
  end
  `undef CMT_RST
  `undef CMT_WR

  // --------------------------------------------------------------------------
  // 时序: 主状态更新 (异步复位)
  // --------------------------------------------------------------------------
  integer i;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      for (i = 0; i < RAS_SPEC_SIZE; i = i + 1) begin
        spec_queue_retAddr[i] <= 50'h0;
        spec_queue_ctr[i]     <= 3'h0;
        spec_nos_flag[i]      <= 1'h0;
        spec_nos_value[i]     <= 5'h0;
      end
      nsp <= 4'h0;  ssp <= 4'h0;  sctr <= 3'h0;
      TOSR_flag <= 1'h1;  TOSR_value <= 5'h1F;
      TOSW_flag <= 1'h0;  TOSW_value <= 5'h0;
      BOS_flag  <= 1'h0;  BOS_value  <= 5'h0;
      spec_near_overflowed <= 1'h0;
      writeBypassValid <= 1'h0;
      timingTop_retAddr <= 50'h0;
    end else begin
      // ---- commit 栈指针 nsp / BOS 更新 (commit_stack 内容由 CMT_LATCH 译码写入) ----
      if (io_commit_push_valid) begin
        if (commit_push_incCtr)
          nsp <= nsp_update;
        else
          nsp <= nsp_update_p1;
        BOS_flag  <= io_commit_meta_TOSW_flag;
        BOS_value <= io_commit_meta_TOSW_value;
      end else begin
        if (io_commit_pop_valid) begin
          if (commit_pop_decCtr)
            nsp <= nsp_update;
          else
            nsp <= nsp_update - 4'h1;
        end
        if (commit_BOS_advance) begin
          BOS_flag  <= ~bos_dec[5];
          BOS_value <= bos_dec[4:0];
        end
      end

      // ---- spec 栈写入 (realPush) ----
      if (realPush) begin
        spec_queue_retAddr[realWriteAddr_value] <= realWriteEntry_retAddr;
        if (use_next)
          spec_queue_ctr[realWriteAddr_value] <= realWriteEntry_next_ctr;
        else if (s3miss_queue_inc)
          spec_queue_ctr[realWriteAddr_value] <= s3meta_sctr_p1;
        else
          spec_queue_ctr[realWriteAddr_value] <= 3'h0;
        spec_nos_flag [realWriteAddr_value] <= realNos_flag;
        spec_nos_value[realWriteAddr_value] <= realNos_value;
      end

      // ---- spec 指针 ssp/sctr/TOSR/TOSW 更新 ----
      if (io_redirect_valid) begin
        // redirect (与 Scala 一致): 先整体恢复到 meta, 再 isCall 时 specPush 覆盖,
        // 最后 isRet 时 specPop 覆盖 —— 故 isCall 与 isRet 同时为真这种异常激励下,
        // specPop 对 TOSR/ssp/sctr 的写覆盖 specPush, 而 TOSW 仅 specPush 改写。
        // (各寄存器用独立 if, 后写者胜, 复刻 Chisel last-connect 语义)
        // -- 基础恢复 --
        TOSR_flag  <= io_redirect_meta_TOSR_flag;
        TOSR_value <= io_redirect_meta_TOSR_value;
        TOSW_flag  <= io_redirect_meta_TOSW_flag;
        TOSW_value <= io_redirect_meta_TOSW_value;
        ssp  <= io_redirect_meta_ssp;
        sctr <= io_redirect_meta_sctr;
        // -- specPush (isCall) 覆盖 --
        if (io_redirect_isCall) begin
          TOSR_flag  <= io_redirect_meta_TOSW_flag;
          TOSR_value <= io_redirect_meta_TOSW_value;
          TOSW_flag  <= redTOSW_inc[5];
          TOSW_value <= redTOSW_inc[4:0];
          if (redPush_sctr_inc) begin
            // specPush 在 ctr 自增时只动 sctr, 不动 ssp
            sctr <= redSctr_p1;
          end else begin
            ssp  <= io_redirect_meta_ssp + 4'h1;
            sctr <= 3'h0;
          end
        end
        // -- specPop (isRet) 覆盖 (TOSW 不动) --
        if (io_redirect_isRet) begin
          // specPop: 仅当 currentTOSR 在范围内才把 TOSR 移到 NOS; 否则不动 TOSR
          if (ptrInRange(io_redirect_meta_TOSR_flag, io_redirect_meta_TOSR_value,
                         io_redirect_meta_TOSW_flag, io_redirect_meta_TOSW_value, BOS_flag, BOS_value)) begin
            TOSR_flag  <= io_redirect_meta_NOS_flag;
            TOSR_value <= io_redirect_meta_NOS_value;
          end
          if (|io_redirect_meta_sctr) begin
            // specPop 在 sctr>0 时只动 sctr, 不动 ssp (保留 base/specPush 写的 ssp)
            sctr <= io_redirect_meta_sctr - 3'h1;
          end else if (ptrInRange(io_redirect_meta_NOS_flag, io_redirect_meta_NOS_value,
                                  io_redirect_meta_TOSW_flag, io_redirect_meta_TOSW_value, BOS_flag, BOS_value)) begin
            ssp  <= redSsp_dec;
            sctr <= spec_queue_ctr[io_redirect_meta_NOS_value];
          end else begin
            ssp  <= redSsp_dec;
            sctr <= commit_stack_ctr[redSsp_dec];
          end
        end
      end else if (io_s3_cancel) begin
        // s3 取消 (与 Scala 一致): 先整体恢复到 s3_meta, 再 missed_pop 时 specPop 覆盖,
        // 最后 missed_push 时 specPush 覆盖 —— 二者同真时 specPush 对 TOSR/ssp/sctr/TOSW
        // 的写胜出 (specPop 不动 TOSW)。各寄存器独立 if, 后写者胜。
        // -- 基础恢复 --
        TOSR_flag  <= io_s3_meta_TOSR_flag;
        TOSR_value <= io_s3_meta_TOSR_value;
        TOSW_flag  <= io_s3_meta_TOSW_flag;
        TOSW_value <= io_s3_meta_TOSW_value;
        ssp  <= io_s3_meta_ssp;
        sctr <= io_s3_meta_sctr;
        // -- specPop (missed_pop) 覆盖 (TOSW 不动) --
        if (io_s3_missed_pop) begin
          // specPop: 仅当 currentTOSR 在范围内才把 TOSR 移到 NOS; 否则不动 TOSR
          if (ptrInRange(io_s3_meta_TOSR_flag, io_s3_meta_TOSR_value,
                         io_s3_meta_TOSW_flag, io_s3_meta_TOSW_value, BOS_flag, BOS_value)) begin
            TOSR_flag  <= io_s3_meta_NOS_flag;
            TOSR_value <= io_s3_meta_NOS_value;
          end
          if (|io_s3_meta_sctr) begin
            // specPop 在 sctr>0 时只动 sctr, 不动 ssp
            sctr <= io_s3_meta_sctr - 3'h1;
          end else if (ptrInRange(io_s3_meta_NOS_flag, io_s3_meta_NOS_value,
                                  io_s3_meta_TOSW_flag, io_s3_meta_TOSW_value, BOS_flag, BOS_value)) begin
            ssp  <= s3Ssp_dec;
            sctr <= spec_queue_ctr[io_s3_meta_NOS_value];
          end else begin
            ssp  <= s3Ssp_dec;
            sctr <= commit_stack_ctr[s3Ssp_dec];
          end
        end
        // -- specPush (missed_push) 覆盖 --
        if (io_s3_missed_push) begin
          TOSR_flag  <= io_s3_meta_TOSW_flag;
          TOSR_value <= io_s3_meta_TOSW_value;
          TOSW_flag  <= s3TOSW_inc[5];
          TOSW_value <= s3TOSW_inc[4:0];
          if (s3Push_sctr_inc) begin
            // specPush 在 ctr 自增时只动 sctr, 不动 ssp (保留 specPop/base 的 ssp)
            sctr <= s3meta_sctr_p1;
          end else begin
            ssp  <= io_s3_meta_ssp + 4'h1;
            sctr <= 3'h0;
          end
        end
      end else begin
        // 正常推测 push / pop —— 与 golden 一致, 对各指针用相互独立的 if
        // (当 push 与 pop 同时为真这种非常规激励下, 每个指针各自按其优先级更新)。
        // ssp: pop 优先决定, 其次 push
        if ((~io_spec_pop_valid) | (|sctr)) begin
          if (io_spec_push_valid & ~specPush_sctr_inc)
            ssp <= ssp + 4'h1;
        end else if (ptrInRange(topNos_flag, topNos_value, TOSW_flag, TOSW_value, BOS_flag, BOS_value)) begin
          ssp <= ssp_dec;
        end else begin
          ssp <= ssp_dec;
        end
        // sctr: pop 优先, 其次 push
        if (io_spec_pop_valid) begin
          if (|sctr)
            sctr <= sctr - 3'h1;
          else if (ptrInRange(topNos_flag, topNos_value, TOSW_flag, TOSW_value, BOS_flag, BOS_value))
            sctr <= spec_queue_ctr[topNos_value];
          else
            sctr <= commit_stack_ctr[ssp_dec];
        end else if (io_spec_push_valid) begin
          sctr <= specPush_sctr_inc ? sctr_p1 : 3'h0;
        end
        // TOSR: pop (且 spec 非空) 优先, 其次 push
        if (io_spec_pop_valid & ptrInRange(TOSR_flag, TOSR_value, TOSW_flag, TOSW_value, BOS_flag, BOS_value)) begin
          TOSR_flag  <= topNos_flag;
          TOSR_value <= topNos_value;
        end else if (io_spec_push_valid) begin
          TOSR_flag  <= TOSW_flag;
          TOSR_value <= TOSW_value;
        end
        // TOSW: 仅 push 影响 (独立, 即使同时 pop 也照常自增)
        if (io_spec_push_valid) begin
          TOSW_flag  <= TOSW_inc[5];
          TOSW_value <= TOSW_inc[4:0];
        end
      end

      // ---- near overflow ----
      spec_near_overflowed <=
        (distBetween(TOSW_flag, TOSW_value, BOS_flag, BOS_value) > 6'h1E);

      // ---- writeBypassValid ----
      writeBypassValid <= writeBypassValidWire;

      // ---- timingTop_retAddr: 下一拍 top 地址的预计算 ----
      timingTop_retAddr <= timingTop_next;
    end
  end


  // --------------------------------------------------------------------------
  // 时序: 写旁路 / s2 锁存 (同步)
  // --------------------------------------------------------------------------
  always @(posedge clock) begin
    if (io_spec_push_valid | redirectIsCall) begin
      writeBypassEntry_retAddr <= writeEntry_retAddr;
      if (redirectIsCall)
        writeBypassEntry_ctr <= (writeEntry_ctr_redInc ? redSctr_p1 : 3'h0);
      else if (writeEntry_ctr_specInc)
        writeBypassEntry_ctr <= sctr_p1;
      else
        writeBypassEntry_ctr <= 3'h0;
      writeBypassNos_flag  <= redirectIsCall ? io_redirect_meta_TOSR_flag  : TOSR_flag;
      writeBypassNos_value <= redirectIsCall ? io_redirect_meta_TOSR_value : TOSR_value;
    end

    if (io_s2_fire | io_redirect_isCall) begin
      realWriteEntry_next_retAddr <= writeEntry_retAddr;
      realWriteEntry_next_ctr <=
        redirectIsCall ? (writeEntry_ctr_redInc ? redSctr_p1 : 3'h0)
                       : (writeEntry_ctr_specInc ? sctr_p1 : 3'h0);
    end
    if (io_s2_fire | redirectIsCall)
      realWriteAddr_next_value <= redirectIsCall ? io_redirect_meta_TOSW_value : TOSW_value;
    if (io_s2_fire | redirectIsCall) begin
      realNos_next_flag  <= redirectIsCall ? io_redirect_meta_TOSR_flag  : TOSR_flag;
      realNos_next_value <= redirectIsCall ? io_redirect_meta_TOSR_value : TOSR_value;
    end
    if (io_s2_fire)
      realPush_r <= io_spec_push_valid;
    realPush_REG <= redirectIsCall;
  end

  // --------------------------------------------------------------------------
  // 输出
  // --------------------------------------------------------------------------
  assign io_spec_pop_addr      = timingTop_retAddr;
  assign io_ssp                = ssp;
  assign io_sctr               = sctr;
  assign io_TOSR_flag          = TOSR_flag;
  assign io_TOSR_value         = TOSR_value;
  assign io_TOSW_flag          = TOSW_flag;
  assign io_TOSW_value         = TOSW_value;
  assign io_NOS_flag           = topNos_flag;
  assign io_NOS_value          = topNos_value;
  assign io_spec_near_overflow = spec_near_overflowed;

endmodule
