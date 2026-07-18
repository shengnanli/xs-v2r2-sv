// =============================================================================
// xs_IPrefetchPipe —— ICache 预取流水（IPrefetch pipeline）
//
// 对应 Chisel: xiangshan.frontend.icache.IPrefetchPipe（IPrefetch.scala）
//
// 【它在前端的位置】
//   FTQ（或软件预取）给出一个取指块的起始 vaddr → 本流水负责把它「翻译 + 查 ICache」，
//   并在 miss 时主动向 MissUnit（MSHR）发预取请求，把数据提前搬进 L1 ICache。命中信息
//   （waymask/ptag/例外）经 WayLookup FIFO 交给 ICacheMainPipe 取数据。它本身不读 data
//   SRAM，只读 meta SRAM 判断「这块在不在 cache、在哪一路」。
//
//     FTQ/SoftPrefetch ──req──▶ [ s0 ]─▶[ s1 ]─▶[ s2 ]
//                                  │       │        └─miss─▶ MissUnit(MSHR)
//                                  │       ├─meta 命中信息─▶ WayLookup FIFO ─▶ MainPipe
//                                  ├─ITLB 翻译        ▲
//                                  └─meta SRAM 读 ────┘（MSHRResp 回填时就地修正命中路）
//
// 【一次请求覆盖两条 cacheline（PORT_NUM=2）】
//   取指块可能跨 64B cacheline 边界（startAddr 的 blockOffBit 位为 1 → crossCacheline/
//   doubleline）。port0 = startAddr 所在 line，port1 = 下一条 line（nextlineStart）。
//   非 doubleline 时 port1 的翻译/查表/异常/miss 一律视为无效。
//
// 【三级流水职责】
//   s0（纯组合接收）：收 FTQ req，把 vaddr 同拍旁路发给 ITLB 与 meta SRAM 读口；
//                     s0_fire 时把请求打入 s1。
//   s1（核心，状态机驱动）：收 ITLB 回（可能 miss 需多拍重发 itlb→重发 meta）；收 meta
//                     回，比 ptag 得 waymask 与 meta ECC；期间监听 MSHRResp 就地修正
//                     waymask（refill 把 miss 变 hit、或覆盖某路把 hit 变 miss）；
//                     完成后把命中信息写入 WayLookup FIFO；s1_real_fire 打入 s2。
//   s2（发预取）：用 s1 锁存的 paddr 做 PMP 检查得最终 exception/mmio；非命中、无例外、
//                     非 mmio 的 line 经 2 路优先级 Arbiter 向 MSHR 发预取请求；
//                     has_send 防重发，全部处理完 s2 推进。
//
// 【s1 状态机 ip_state_e（对应 Chisel m_*）】
//   S_IDLE       一拍就能查完（itlb 命中、meta 同拍读到）的常态
//   S_ITLB_RESEND  ITLB miss，需保持 valid 重发 itlb 直到翻译完成
//   S_META_RESEND  itlb 翻译好了但 meta SRAM 读口当时没 ready，需重发 meta 读
//   S_ENQ_WAY      已拿到命中信息，等待 WayLookup FIFO 接收（写入 toWayLookup）
//   S_ENTER_S2     已 enq 完但 s2 还没腾出位置，等待 s2_ready
//
// 【为什么 ITLB / Meta 都可能要「重发」】
//   ITLB 是共享资源，可能 miss（需 PTW 回填，多拍后才出 paddr）；meta SRAM 读口也可能
//   被别人占用（toMeta.ready=0）。s1 必须把请求「黏住」并重发，否则会丢失这次预取。
//   s1_wait_itlb 记录「某 port 已经历过一次 itlb miss、正在等翻译完成」。
//
// 【可读性重写要点（相对 firtool golden）】
//   · 两个 port 一律用 [PORT_NUM] 数组 + for 循环，消除 _0/_1 展平标量；
//   · 状态机用 typedef enum，消除裸 3'h1/3'h2…；
//   · waymask 比较、meta ECC、tag 提取、MSHR 修正抽成 package 内纯函数；
//   · 按 s0/s1/s2 流水级分节，每节讲「这一级在干什么、为什么」。
// =============================================================================
package xs_iprefetch_pkg;
  // ---- 容量/位宽参数（与 KunminghuV2 ICache 一致）----
  localparam int unsigned PORT_NUM     = 2;   // 一次取指跨 2 条 cacheline → 2 个查表 port
  localparam int unsigned N_WAYS       = 4;   // ICache 组相联路数 → waymask 宽
  localparam int unsigned VADDR_W      = 50;  // VAddrBits
  localparam int unsigned PADDR_W      = 48;  // PAddrBits（ITLB 给出的物理地址宽）
  localparam int unsigned GPADDR_W     = 56;  // PAddrBitsMax（gpaddr 截断宽，见 Scala 注释）
  localparam int unsigned IDX_W        = 8;   // vSetIdx 宽
  localparam int unsigned TAG_W        = 36;  // 物理 tag 宽 = paddr[47:12]
  localparam int unsigned BLK_PADDR_W  = 42;  // MSHR blkPaddr 宽 = paddr[47:6]
  localparam int unsigned FTQ_PTR_W    = 6;   // FtqPtr value 宽
  localparam int unsigned EXCP_W       = 2;   // ExceptionType.width
  localparam int unsigned PBMT_W       = 2;   // Pbmt.width
  localparam int unsigned META_CODE_W  = 1;   // ICacheMetaCodeBits（meta ECC 奇偶校验 1 位）

  // 地址切片位置（KunminghuV2：blockOffBits=6，tag=[47:12]，vSetIdx=[13:6]）
  localparam int unsigned BLK_OFF_BITS = 6;   // log2(blockBytes=64)
  localparam int unsigned IDX_LO       = 6;   // vSetIdx = vaddr[13:6]
  localparam int unsigned IDX_HI       = 13;
  localparam int unsigned TAG_LO       = 12;  // ptag = paddr[47:12]
  localparam int unsigned TAG_HI       = 47;
  localparam int unsigned CROSS_LINE_BIT = 5; // startAddr[5]=1 → 跨 line（doubleline）

  // ExceptionType 编码（FrontendBundle.scala）
  localparam logic [EXCP_W-1:0] EXCP_NONE = 2'd0;
  localparam logic [EXCP_W-1:0] EXCP_PF   = 2'd1;  // page fault
  localparam logic [EXCP_W-1:0] EXCP_GPF  = 2'd2;  // guest page fault
  localparam logic [EXCP_W-1:0] EXCP_AF   = 2'd3;  // access fault

  // Pbmt 编码（页属性，非 PMA 即视为 uncache/mmio）
  localparam logic [PBMT_W-1:0] PBMT_PMA = 2'd0;
  localparam logic [PBMT_W-1:0] PBMT_NC  = 2'd1;  // non-cacheable
  localparam logic [PBMT_W-1:0] PBMT_IO  = 2'd2;  // strong order IO

  // ---- 单个 meta SRAM way 的内容 ----
  typedef struct packed {
    logic [TAG_W-1:0]       tag;          // 该 way 存的物理 tag
    logic [META_CODE_W-1:0] code;         // 该 way tag 的 ECC（奇偶）
    logic                   entry_valid;  // 该 way 是否有效
  } meta_way_t;

  // ---- 单个 port（一条 cacheline）的查表命中信息 ----
  typedef struct packed {
    logic [IDX_W-1:0]       vSetIdx;
    logic [N_WAYS-1:0]      waymask;        // 命中路 one-hot（全 0 = miss）
    logic [TAG_W-1:0]       ptag;
    logic [EXCP_W-1:0]      itlb_exception;
    logic [PBMT_W-1:0]      itlb_pbmt;
    logic [META_CODE_W-1:0] meta_codes;     // 命中路的 meta ECC
  } way_lookup_port_t;

  typedef struct packed {
    way_lookup_port_t [PORT_NUM-1:0] port;
  } way_lookup_entry_t;

  // ---- 写入 WayLookup 时附带的 gpf 信息（全局一份）----
  typedef struct packed {
    logic [GPADDR_W-1:0] gpaddr;
    logic                isForVSnonLeafPTE;
  } way_lookup_gpf_t;

  // ---- s1 状态机 ----
  typedef enum logic [2:0] {
    S_IDLE        = 3'd0,  // m_idle
    S_ITLB_RESEND = 3'd1,  // m_itlbResend
    S_META_RESEND = 3'd2,  // m_metaResend
    S_ENQ_WAY     = 3'd3,  // m_enqWay
    S_ENTER_S2    = 3'd4   // m_enterS2
  } ip_state_e;

  // 地址切片
  function automatic logic [IDX_W-1:0] get_idx(input logic [VADDR_W-1:0] va);
    return va[IDX_HI:IDX_LO];
  endfunction
  function automatic logic [TAG_W-1:0] get_phy_tag(input logic [PADDR_W-1:0] pa);
    return pa[TAG_HI:TAG_LO];
  endfunction
  function automatic logic [TAG_W-1:0] get_phy_tag_from_blk(input logic [BLK_PADDR_W-1:0] blk);
    return blk[BLK_PADDR_W-1 : BLK_OFF_BITS];   // blkPaddr 高位即 ptag
  endfunction
  function automatic logic [BLK_PADDR_W-1:0] get_blk_addr(input logic [PADDR_W-1:0] pa);
    return pa[PADDR_W-1 : BLK_OFF_BITS];
  endfunction

  // meta ECC（KunminghuV2：tag 全位异或的 1-bit 奇偶校验）
  function automatic logic [META_CODE_W-1:0] encode_meta_ecc(input logic [TAG_W-1:0] ptag);
    return ^ptag;
  endfunction

  // ITLB 例外三选一（pf/gpf/af），优先级 pf > gpf > af；与 ExceptionType.fromTlbResp 一致
  function automatic logic [EXCP_W-1:0] tlb_excp(input logic pf, input logic gpf, input logic af);
    return pf ? EXCP_PF : gpf ? EXCP_GPF : af ? EXCP_AF : EXCP_NONE;
  endfunction

  // 例外合并：高优先级（itlb/backend）非 none 则取之，否则取低优先级（pmp）
  function automatic logic [EXCP_W-1:0] excp_merge(input logic [EXCP_W-1:0] hi,
                                                   input logic [EXCP_W-1:0] lo);
    return (hi != EXCP_NONE) ? hi : lo;
  endfunction

  // pbmt 是否为 uncache（NC/IO）→ mmio
  function automatic logic pbmt_is_uncache(input logic [PBMT_W-1:0] pbmt);
    return (pbmt == PBMT_NC) || (pbmt == PBMT_IO);
  endfunction
endpackage


module xs_IPrefetchPipe
  import xs_iprefetch_pkg::*;
(
  input  logic clock,
  input  logic reset,

  // ---- 全局控制 ----
  input  logic io_csr_pf_enable,   // CSR 硬件预取使能（关时 s1 不进 s2，不发预取）
  input  logic io_flush,           // 顶层冲刷

  // ---- FTQ / 软件预取请求（DecoupledIO）----
  input  logic                 io_req_valid,
  output logic                 io_req_ready,
  input  logic [VADDR_W-1:0]   io_req_bits_startAddr,
  input  logic [VADDR_W-1:0]   io_req_bits_nextlineStart,
  input  logic                 io_req_bits_ftqIdx_flag,
  input  logic [FTQ_PTR_W-1:0] io_req_bits_ftqIdx_value,
  input  logic                 io_req_bits_isSoftPrefetch,
  input  logic [EXCP_W-1:0]    io_req_bits_backendException,

  // ---- BPU 冲刷信息（s2/s3 级，按 FtqPtr 比较决定是否冲掉本请求）----
  input  logic                 io_flushFromBpu_s2_valid,
  input  logic                 io_flushFromBpu_s2_bits_flag,
  input  logic [FTQ_PTR_W-1:0] io_flushFromBpu_s2_bits_value,
  input  logic                 io_flushFromBpu_s3_valid,
  input  logic                 io_flushFromBpu_s3_bits_flag,
  input  logic [FTQ_PTR_W-1:0] io_flushFromBpu_s3_bits_value,

  // ---- ITLB（每 port 一个 req/resp）----
  output logic                 io_itlb_req_valid          [PORT_NUM],
  output logic [VADDR_W-1:0]   io_itlb_req_bits_vaddr     [PORT_NUM],
  input  logic [PADDR_W-1:0]   io_itlb_resp_bits_paddr    [PORT_NUM],
  input  logic [63:0]          io_itlb_resp_bits_gpaddr   [PORT_NUM],
  input  logic [PBMT_W-1:0]    io_itlb_resp_bits_pbmt     [PORT_NUM],
  input  logic                 io_itlb_resp_bits_miss     [PORT_NUM],
  input  logic                 io_itlb_resp_bits_isForVSnonLeafPTE [PORT_NUM],
  input  logic                 io_itlb_resp_bits_excp_gpf [PORT_NUM],
  input  logic                 io_itlb_resp_bits_excp_pf  [PORT_NUM],
  input  logic                 io_itlb_resp_bits_excp_af  [PORT_NUM],
  output logic                 io_itlbFlushPipe,

  // ---- PMP（s1 paddr 做物理保护检查）----
  output logic [PADDR_W-1:0]   io_pmp_req_bits_addr [PORT_NUM],
  input  logic                 io_pmp_resp_instr    [PORT_NUM],  // pmp 拒绝 → access fault
  input  logic                 io_pmp_resp_mmio     [PORT_NUM],

  // ---- meta SRAM 读口 ----
  input  logic                 io_metaRead_toIMeta_ready,
  output logic                 io_metaRead_toIMeta_valid,
  output logic [IDX_W-1:0]     io_metaRead_toIMeta_bits_vSetIdx [PORT_NUM],
  output logic                 io_metaRead_toIMeta_bits_isDoubleLine,
  input  meta_way_t            io_metaRead_fromIMeta [PORT_NUM][N_WAYS],

  // ---- 向 MissUnit 发预取请求（DecoupledIO）----
  input  logic                 io_MSHRReq_ready,
  output logic                 io_MSHRReq_valid,
  output logic [BLK_PADDR_W-1:0] io_MSHRReq_bits_blkPaddr,
  output logic [IDX_W-1:0]     io_MSHRReq_bits_vSetIdx,

  // ---- MissUnit refill 回应（ValidIO，用于就地修正 waymask）----
  input  logic                 io_MSHRResp_valid,
  input  logic [BLK_PADDR_W-1:0] io_MSHRResp_bits_blkPaddr,
  input  logic [IDX_W-1:0]     io_MSHRResp_bits_vSetIdx,
  input  logic [N_WAYS-1:0]    io_MSHRResp_bits_waymask,
  input  logic                 io_MSHRResp_bits_corrupt,

  // ---- 写 WayLookup FIFO（DecoupledIO）----
  input  logic                 io_wayLookupWrite_ready,
  output logic                 io_wayLookupWrite_valid,
  output way_lookup_entry_t    io_wayLookupWrite_bits_entry,
  output way_lookup_gpf_t      io_wayLookupWrite_bits_gpf
);

  // ===========================================================================
  // 流水级握手/冲刷线（声明在前，定义散落在各级）
  // ===========================================================================
  logic s0_fire, s1_fire, s2_fire;
  logic s1_ready, s2_ready;
  logic s0_flush, s1_flush, s2_flush;
  logic from_bpu_s0_flush, from_bpu_s1_flush;

  // BPU 冲刷比较：FtqPtr(flag,value) 做「环形序」比较，flushPtr <= reqPtr 则冲掉。
  // 等价 Chisel shouldFlushByStageX：valid & (flag^flag) ^ (flushVal <= reqVal)。
  function automatic logic bpu_should_flush(
      input logic         flush_valid,
      input logic         flush_flag, input logic [FTQ_PTR_W-1:0] flush_val,
      input logic         req_flag,   input logic [FTQ_PTR_W-1:0] req_val);
    return flush_valid && (flush_flag ^ req_flag ^ (flush_val <= req_val));
  endfunction

  // ===========================================================================
  // Stage 0 —— 接收 FTQ 请求；旁路发 ITLB / meta 读；s0_fire 打入 s1
  // ===========================================================================
  logic                s0_valid;
  logic [VADDR_W-1:0]  s0_req_vaddr   [PORT_NUM];
  logic [IDX_W-1:0]    s0_req_vSetIdx [PORT_NUM];
  logic                s0_isSoftPrefetch;
  logic                s0_doubleline;     // 是否跨 cacheline（startAddr[5]）

  assign s0_valid          = io_req_valid;
  assign s0_req_vaddr[0]   = io_req_bits_startAddr;
  assign s0_req_vaddr[1]   = io_req_bits_nextlineStart;
  assign s0_isSoftPrefetch = io_req_bits_isSoftPrefetch;
  assign s0_doubleline     = io_req_bits_startAddr[CROSS_LINE_BIT];
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s0_idx
    assign s0_req_vSetIdx[p] = get_idx(s0_req_vaddr[p]);
  end

  // 软件预取不受 BPU 冲刷影响；硬件预取按 ftqIdx 比较 s2/s3 冲刷
  assign from_bpu_s0_flush = !s0_isSoftPrefetch &&
    (bpu_should_flush(io_flushFromBpu_s2_valid, io_flushFromBpu_s2_bits_flag,
                      io_flushFromBpu_s2_bits_value, io_req_bits_ftqIdx_flag,
                      io_req_bits_ftqIdx_value) ||
     bpu_should_flush(io_flushFromBpu_s3_valid, io_flushFromBpu_s3_bits_flag,
                      io_flushFromBpu_s3_bits_value, io_req_bits_ftqIdx_flag,
                      io_req_bits_ftqIdx_value));
  assign s0_flush = io_flush || from_bpu_s0_flush || s1_flush;

  // s0 能走：s1 已腾出 + meta 读口 ready（ITLB 在 KunminghuV2 恒 ready，故不并入；
  // 与 golden 一致：s0_can_go = s1_ready & toIMeta.ready）
  logic s0_can_go;
  assign s0_can_go    = s1_ready && io_metaRead_toIMeta_ready;
  assign io_req_ready = s0_can_go;
  assign s0_fire      = s0_valid && s0_can_go && !s0_flush;

  // ===========================================================================
  // Stage 1 —— ITLB 翻译 / meta 查表 / MSHR 修正 / 写 WayLookup
  // ===========================================================================
  ip_state_e state, next_state;

  // s1 流水寄存器
  logic                 s1_valid;
  logic [VADDR_W-1:0]   s1_req_vaddr   [PORT_NUM];
  logic [IDX_W-1:0]     s1_req_vSetIdx [PORT_NUM];
  logic                 s1_isSoftPrefetch;
  logic                 s1_doubleline;
  logic                 s1_req_ftqIdx_flag;
  logic [FTQ_PTR_W-1:0] s1_req_ftqIdx_value;
  logic [EXCP_W-1:0]    s1_backendException [PORT_NUM];

  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s1_idx
    assign s1_req_vSetIdx[p] = get_idx(s1_req_vaddr[p]);
  end

  // s0_fire 打一拍：RegNext(s0_fire)，多处复用（首拍 itlb/meta 结果有效标志）
  logic s0_fire_r;
  always_ff @(posedge clock) s0_fire_r <= s0_fire;

  // -------- ITLB 重发控制 --------
  // s1_wait_itlb[p]：port p 经历过一次 itlb miss、正在等翻译完成（重发期间保持置位）。
  logic s1_wait_itlb [PORT_NUM];
  // 「本拍 itlb resp 是首拍刚到 (s0_fire_r) 或仍在等 (wait)」——决定本拍 resp 是否归本请求
  logic s1_itlb_active [PORT_NUM];
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_itlb_active
    assign s1_itlb_active[p] = s0_fire_r || s1_wait_itlb[p];
  end

  // 该 port 本拍 itlb 仍 miss → 需重发；非命中且属本请求 → 翻译成功脉冲
  logic s1_need_itlb       [PORT_NUM];
  logic s1_tlb_valid_pulse [PORT_NUM];
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_itlb_pulse
    // port1 仅在 doubleline 时参与
    wire port_en = (p == 0) ? 1'b1 : s1_doubleline;
    assign s1_need_itlb[p]       = s1_itlb_active[p] &&  io_itlb_resp_bits_miss[p] && port_en;
    assign s1_tlb_valid_pulse[p] = s1_itlb_active[p] && !io_itlb_resp_bits_miss[p] && port_en;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int p = 0; p < PORT_NUM; p++) s1_wait_itlb[p] <= 1'b0;
    end else begin
      for (int p = 0; p < PORT_NUM; p++) begin
        if (s1_flush)
          s1_wait_itlb[p] <= 1'b0;
        else if (s0_fire_r && io_itlb_resp_bits_miss[p])        // 首拍就 miss → 进入等待
          s1_wait_itlb[p] <= 1'b1;
        else if (s1_wait_itlb[p] && !io_itlb_resp_bits_miss[p]) // 翻译完成 → 退出等待
          s1_wait_itlb[p] <= 1'b0;
      end
    end
  end

  // 翻译完成锁存（ValidHoldBypass）：脉冲到来即置位并保持，直到 s1_fire/flush 清。
  // itlb_finish：port0 翻译好（doubleline 时还需 port1 也好）。
  logic s1_tlb_valid_latch [PORT_NUM];
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int p = 0; p < PORT_NUM; p++) s1_tlb_valid_latch[p] <= 1'b0;
    end else begin
      for (int p = 0; p < PORT_NUM; p++) begin
        if (s1_flush || s1_fire)
          s1_tlb_valid_latch[p] <= 1'b0;
        else if (s1_tlb_valid_pulse[p])
          s1_tlb_valid_latch[p] <= 1'b1;
      end
    end
  end
  logic itlb_finish;
  assign itlb_finish = (s1_tlb_valid_latch[0] || s1_tlb_valid_pulse[0]) &&
    (!s1_doubleline || s1_tlb_valid_latch[1] || s1_tlb_valid_pulse[1]);

  // -------- 发 ITLB 请求 --------
  // 重发用 s1 锁存的 vaddr，否则旁路 s0 的 vaddr（s0/s1 同口复用）
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_itlb_req
    wire s0_port_en = (p == 0) ? 1'b1 : s0_doubleline;
    assign io_itlb_req_valid[p]      = s1_need_itlb[p] || (s0_valid && s0_port_en);
    assign io_itlb_req_bits_vaddr[p] = s1_need_itlb[p] ? s1_req_vaddr[p] : s0_req_vaddr[p];
  end

  // -------- 锁存 ITLB 翻译结果（脉冲到来当拍写入；用 mux 选当拍/已存）--------
  logic [PADDR_W-1:0]  s1_paddr_reg            [PORT_NUM];
  logic [GPADDR_W-1:0] s1_gpaddr_reg           [PORT_NUM];
  logic                s1_isForVSnonLeafPTE_reg[PORT_NUM];
  logic [EXCP_W-1:0]   s1_itlb_excp_reg        [PORT_NUM];
  logic [PBMT_W-1:0]   s1_pbmt_reg             [PORT_NUM];

  // 本 port 当拍 itlb 给出的例外（pf/gpf/af 三选一）
  logic [EXCP_W-1:0] s1_itlb_excp_wire [PORT_NUM];
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_itlb_excp_wire
    assign s1_itlb_excp_wire[p] = tlb_excp(io_itlb_resp_bits_excp_pf[p],
                                           io_itlb_resp_bits_excp_gpf[p],
                                           io_itlb_resp_bits_excp_af[p]);
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int p = 0; p < PORT_NUM; p++) begin
        s1_paddr_reg[p]             <= '0;
        s1_gpaddr_reg[p]            <= '0;
        s1_isForVSnonLeafPTE_reg[p] <= 1'b0;
        s1_itlb_excp_reg[p]         <= EXCP_NONE;
        s1_pbmt_reg[p]              <= PBMT_PMA;
      end
    end else begin
      for (int p = 0; p < PORT_NUM; p++) begin
        if (s1_tlb_valid_pulse[p]) begin
          s1_paddr_reg[p]             <= io_itlb_resp_bits_paddr[p];
          s1_gpaddr_reg[p]            <= io_itlb_resp_bits_gpaddr[p][GPADDR_W-1:0];
          s1_isForVSnonLeafPTE_reg[p] <= io_itlb_resp_bits_isForVSnonLeafPTE[p];
          s1_itlb_excp_reg[p]         <= s1_itlb_excp_wire[p];
          s1_pbmt_reg[p]              <= io_itlb_resp_bits_pbmt[p];
        end
      end
    end
  end

  // 当拍优先用脉冲值，否则用锁存值（ResultHoldBypass 语义）
  logic [PADDR_W-1:0]  s1_req_paddr             [PORT_NUM];
  logic [GPADDR_W-1:0] s1_req_gpaddr_tmp        [PORT_NUM];
  logic                s1_isForVSnonLeafPTE_tmp [PORT_NUM];
  logic [EXCP_W-1:0]   s1_itlb_exception_tmp    [PORT_NUM];
  logic [PBMT_W-1:0]   s1_itlb_pbmt             [PORT_NUM];
  logic [TAG_W-1:0]    s1_req_ptags             [PORT_NUM];
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_itlb_sel
    assign s1_req_paddr[p]             = s1_tlb_valid_pulse[p] ? io_itlb_resp_bits_paddr[p]                : s1_paddr_reg[p];
    assign s1_req_gpaddr_tmp[p]        = s1_tlb_valid_pulse[p] ? io_itlb_resp_bits_gpaddr[p][GPADDR_W-1:0] : s1_gpaddr_reg[p];
    assign s1_isForVSnonLeafPTE_tmp[p] = s1_tlb_valid_pulse[p] ? io_itlb_resp_bits_isForVSnonLeafPTE[p]    : s1_isForVSnonLeafPTE_reg[p];
    assign s1_itlb_exception_tmp[p]    = s1_tlb_valid_pulse[p] ? s1_itlb_excp_wire[p]                      : s1_itlb_excp_reg[p];
    assign s1_itlb_pbmt[p]             = s1_tlb_valid_pulse[p] ? io_itlb_resp_bits_pbmt[p]                 : s1_pbmt_reg[p];
    assign s1_req_ptags[p]             = get_phy_tag(s1_req_paddr[p]);
  end

  // backend 例外（高位非全 0/1 的 vaddr 视为页错，后端检测后随 redirect 带来）优先于 itlb
  logic [EXCP_W-1:0] s1_itlb_exception     [PORT_NUM];
  logic              s1_itlb_exception_gpf [PORT_NUM];
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_excp_merge
    assign s1_itlb_exception[p]     = excp_merge(s1_backendException[p], s1_itlb_exception_tmp[p]);
    assign s1_itlb_exception_gpf[p] = (s1_itlb_exception[p] == EXCP_GPF);
  end

  // gpf 的 gpaddr/isForVS：取「第一个有 gpf」的 port；port i 的基址需减 i*blocksize
  // （PriorityMuxDefault：port0 优先，全无 gpf 时为 0）
  logic [GPADDR_W-1:0] s1_req_gpaddr;
  logic                s1_req_isForVSnonLeafPTE;
  always_comb begin
    s1_req_gpaddr            = '0;
    s1_req_isForVSnonLeafPTE = 1'b0;
    if (s1_itlb_exception_gpf[0]) begin
      s1_req_gpaddr            = s1_req_gpaddr_tmp[0];                                  // port0：减 0
      s1_req_isForVSnonLeafPTE = s1_isForVSnonLeafPTE_tmp[0];
    end else if (s1_itlb_exception_gpf[1]) begin
      s1_req_gpaddr            = s1_req_gpaddr_tmp[1] - GPADDR_W'(1 << BLK_OFF_BITS);   // port1：减 1*64
      s1_req_isForVSnonLeafPTE = s1_isForVSnonLeafPTE_tmp[1];
    end
  end

  // -------- 重发 meta 读 --------
  // itlbResend 翻译完成、或 metaResend 态 → 需要再发一次 meta 读（s0 同口复用）
  logic s1_need_meta;
  assign s1_need_meta = ((state == S_ITLB_RESEND) && itlb_finish) || (state == S_META_RESEND);
  assign io_metaRead_toIMeta_valid             = s1_need_meta || s0_valid;
  assign io_metaRead_toIMeta_bits_isDoubleLine = s1_need_meta ? s1_doubleline : s0_doubleline;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_meta_req
    assign io_metaRead_toIMeta_bits_vSetIdx[p] = s1_need_meta ? s1_req_vSetIdx[p] : s0_req_vSetIdx[p];
  end

  // -------- meta 命中比较：ptag 相等 & way 有效 → 该 way 命中 --------
  function automatic logic [N_WAYS-1:0] match_waymask(
      input logic [TAG_W-1:0] ptag, input meta_way_t ways [N_WAYS]);
    logic [N_WAYS-1:0] m;
    for (int w = 0; w < N_WAYS; w++)
      m[w] = (ways[w].tag == ptag) && ways[w].entry_valid;
    return m;
  endfunction
  function automatic logic [META_CODE_W-1:0] select_meta_code(
      input logic [N_WAYS-1:0] mask, input meta_way_t ways [N_WAYS]);
    logic [META_CODE_W-1:0] c;
    c = '0;
    for (int w = 0; w < N_WAYS; w++)
      if (mask[w]) c = c | ways[w].code;   // Mux1H
    return c;
  endfunction

  logic [N_WAYS-1:0]      s1_SRAM_waymasks   [PORT_NUM];
  logic [META_CODE_W-1:0] s1_SRAM_meta_codes [PORT_NUM];
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_sram_match
    // 当拍翻译脉冲 → 用 io_itlb 的 paddr 算 ptag；否则用已锁存 paddr（与 meta 时序对齐）
    wire [TAG_W-1:0] cmp_ptag = s1_tlb_valid_pulse[p]
                              ? get_phy_tag(io_itlb_resp_bits_paddr[p])
                              : get_phy_tag(s1_paddr_reg[p]);
    assign s1_SRAM_waymasks[p]   = match_waymask(cmp_ptag, io_metaRead_fromIMeta[p]);
    assign s1_SRAM_meta_codes[p] = select_meta_code(s1_SRAM_waymasks[p], io_metaRead_fromIMeta[p]);
  end

  // -------- MSHR refill 就地修正 waymask / meta_code --------
  // refill 命中同 vSet：ptag 也同 → 这正是它 miss 的 line，waymask←本次填的路、code 重算；
  //                      否则若填的路恰是已记命中路 → 数据被覆盖，hit→miss（waymask←0）。
  logic s1_SRAM_valid;     // 本拍 meta SRAM 结果有效（首拍或重发 meta 命中后一拍）
  logic s1_SRAM_valid_r;
  logic s1_MSHR_valid;
  assign s1_MSHR_valid = io_MSHRResp_valid && !io_MSHRResp_bits_corrupt;
  always_ff @(posedge clock) s1_SRAM_valid_r <= s1_need_meta && io_metaRead_toIMeta_ready;
  assign s1_SRAM_valid = s0_fire_r || s1_SRAM_valid_r;

  // waymask/meta_code：SRAM 有效时取本拍 SRAM 结果，否则取上次锁存
  logic [N_WAYS-1:0]      s1_waymasks_r   [PORT_NUM];
  logic [META_CODE_W-1:0] s1_meta_codes_r [PORT_NUM];
  logic [N_WAYS-1:0]      s1_waymasks     [PORT_NUM];   // 修正后（最终输出）
  logic [META_CODE_W-1:0] s1_meta_codes   [PORT_NUM];

  for (genvar p = 0; p < PORT_NUM; p++) begin : g_update
    wire [N_WAYS-1:0]      old_mask = s1_SRAM_valid ? s1_SRAM_waymasks[p]   : s1_waymasks_r[p];
    wire [META_CODE_W-1:0] old_code = s1_SRAM_valid ? s1_SRAM_meta_codes[p] : s1_meta_codes_r[p];
    wire vset_same = s1_MSHR_valid && (io_MSHRResp_bits_vSetIdx == s1_req_vSetIdx[p]);
    wire ptag_same = (get_phy_tag_from_blk(io_MSHRResp_bits_blkPaddr) == s1_req_ptags[p]);
    wire way_same  = (io_MSHRResp_bits_waymask == old_mask);

    always_comb begin
      s1_waymasks[p]   = old_mask;
      s1_meta_codes[p] = old_code;
      if (vset_same) begin
        if (ptag_same) begin
          s1_waymasks[p]   = io_MSHRResp_bits_waymask;          // miss→hit
          s1_meta_codes[p] = encode_meta_ecc(s1_req_ptags[p]);  // 用 ptag 重算（时序更优）
        end else if (way_same) begin
          s1_waymasks[p]   = '0;                                // hit→miss
        end
      end
    end
  end

  // 锁存修正后的 waymask/meta_code（供 s2 与下次比较使用）
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int p = 0; p < PORT_NUM; p++) begin
        s1_waymasks_r[p]   <= '0;
        s1_meta_codes_r[p] <= '0;
      end
    end else if (s1_SRAM_valid || s1_MSHR_valid) begin
      for (int p = 0; p < PORT_NUM; p++) begin
        s1_waymasks_r[p]   <= s1_waymasks[p];
        s1_meta_codes_r[p] <= s1_meta_codes[p];
      end
    end
  end

  // -------- 写 WayLookup FIFO --------
  // 仅在「enqWay 态，或 idle 态且本拍 itlb 已完成」时尝试写；soft prefetch 不入队；
  // 且 SRAM 正被 MSHR 写时（fromMSHR.valid）不入队（避免与 refill 冲突）。
  assign io_wayLookupWrite_valid =
    ((state == S_ENQ_WAY) || ((state == S_IDLE) && itlb_finish)) &&
    !s1_flush && !io_MSHRResp_valid && !s1_isSoftPrefetch;

  for (genvar p = 0; p < PORT_NUM; p++) begin : g_waylookup_bits
    // port0 例外恒有效；port1 仅 doubleline 有效
    wire excp_valid = (p == 0) ? 1'b1 : s1_doubleline;
    assign io_wayLookupWrite_bits_entry.port[p].vSetIdx        = s1_req_vSetIdx[p];
    assign io_wayLookupWrite_bits_entry.port[p].waymask        = s1_waymasks[p];
    assign io_wayLookupWrite_bits_entry.port[p].ptag           = s1_req_ptags[p];
    assign io_wayLookupWrite_bits_entry.port[p].itlb_exception = excp_valid ? s1_itlb_exception[p] : EXCP_NONE;
    assign io_wayLookupWrite_bits_entry.port[p].itlb_pbmt      = excp_valid ? s1_itlb_pbmt[p]      : PBMT_PMA;
    assign io_wayLookupWrite_bits_entry.port[p].meta_codes     = s1_meta_codes[p];
  end
  assign io_wayLookupWrite_bits_gpf.gpaddr            = s1_req_gpaddr;
  assign io_wayLookupWrite_bits_gpf.isForVSnonLeafPTE = s1_req_isForVSnonLeafPTE;

  // -------- PMP 检查（用 s1 paddr）--------
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_pmp
    assign io_pmp_req_bits_addr[p] = s1_req_paddr[p];
  end
  logic [EXCP_W-1:0] s1_pmp_exception [PORT_NUM];
  logic [EXCP_W-1:0] s1_exception_out [PORT_NUM];
  logic              s1_mmio          [PORT_NUM];
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_pmp_excp
    assign s1_pmp_exception[p] = io_pmp_resp_instr[p] ? EXCP_AF : EXCP_NONE;
    // itlb 例外优先于 pmp（meta_corrupt 为时序不并入，且不取消预取）
    assign s1_exception_out[p] = excp_merge(s1_itlb_exception[p], s1_pmp_exception[p]);
    assign s1_mmio[p]          = io_pmp_resp_mmio[p] || pbmt_is_uncache(s1_itlb_pbmt[p]);
  end

  // -------- s1 状态机 --------
  always_comb begin
    next_state = state;
    case (state)
      S_IDLE: begin
        if (s1_valid) begin
          if (!itlb_finish)                  next_state = S_ITLB_RESEND;
          else if (!(io_wayLookupWrite_ready && io_wayLookupWrite_valid))
                                             next_state = S_ENQ_WAY;
          else if (!s2_ready)                next_state = S_ENTER_S2;
        end
      end
      S_ITLB_RESEND: begin
        if (itlb_finish)
          next_state = io_metaRead_toIMeta_ready ? S_ENQ_WAY : S_META_RESEND;
      end
      S_META_RESEND: begin
        if (io_metaRead_toIMeta_ready)       next_state = S_ENQ_WAY;
      end
      S_ENQ_WAY: begin
        if ((io_wayLookupWrite_ready && io_wayLookupWrite_valid) || s1_isSoftPrefetch)
          next_state = s2_ready ? S_IDLE : S_ENTER_S2;
      end
      S_ENTER_S2: begin
        if (s2_ready)                        next_state = S_IDLE;
      end
      default: ;   // 非法编码 5/6/7 保持（golden 的嵌套三元对其兜底为 state，勿归零）
    endcase
    if (s1_flush) next_state = S_IDLE;   // flush 优先
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) state <= S_IDLE;
    else       state <= next_state;
  end

  // s1 控制
  assign from_bpu_s1_flush = s1_valid && !s1_isSoftPrefetch &&
    bpu_should_flush(io_flushFromBpu_s3_valid, io_flushFromBpu_s3_bits_flag,
                     io_flushFromBpu_s3_bits_value, s1_req_ftqIdx_flag, s1_req_ftqIdx_value);
  assign s1_flush         = io_flush || from_bpu_s1_flush;
  assign io_itlbFlushPipe = s1_flush;   // s1 冲刷时 itlb 流水也要冲

  assign s1_ready = (next_state == S_IDLE);
  assign s1_fire  = (next_state == S_IDLE) && s1_valid && !s1_flush;
  logic s1_real_fire;                   // 真正进入 s2（需 csr 预取使能）
  assign s1_real_fire = s1_fire && io_csr_pf_enable;

  // s1_valid（generatePipeControl）
  always_ff @(posedge clock or posedge reset) begin
    if (reset) s1_valid <= 1'b0;
    else       s1_valid <= !s1_flush && (s0_fire || (!s1_fire && s1_valid));
  end

  // s1 payload 寄存器
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int p = 0; p < PORT_NUM; p++) begin
        s1_req_vaddr[p]        <= '0;
        s1_backendException[p] <= EXCP_NONE;
      end
      s1_isSoftPrefetch   <= 1'b0;
      s1_doubleline       <= 1'b0;
      s1_req_ftqIdx_flag  <= 1'b0;
      s1_req_ftqIdx_value <= '0;
    end else if (s0_fire) begin
      s1_req_vaddr[0]     <= io_req_bits_startAddr;
      s1_req_vaddr[1]     <= io_req_bits_nextlineStart;
      s1_isSoftPrefetch   <= s0_isSoftPrefetch;
      s1_doubleline       <= s0_doubleline;
      s1_req_ftqIdx_flag  <= io_req_bits_ftqIdx_flag;
      s1_req_ftqIdx_value <= io_req_bits_ftqIdx_value;
      for (int p = 0; p < PORT_NUM; p++)
        s1_backendException[p] <= io_req_bits_backendException;
    end
  end

  // ===========================================================================
  // Stage 2 —— 判 miss / 监听 MSHR / 经优先级 Arbiter 发预取请求
  // ===========================================================================
  logic                s2_valid;
  logic [VADDR_W-1:0]  s2_req_vaddr   [PORT_NUM];
  logic                s2_isSoftPrefetch;
  logic                s2_doubleline;
  logic [PADDR_W-1:0]  s2_req_paddr   [PORT_NUM];
  logic [EXCP_W-1:0]   s2_exception   [PORT_NUM];
  logic                s2_mmio        [PORT_NUM];
  logic [N_WAYS-1:0]   s2_waymasks    [PORT_NUM];

  logic [IDX_W-1:0]    s2_req_vSetIdx [PORT_NUM];
  logic [TAG_W-1:0]    s2_req_ptags   [PORT_NUM];
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s2_slice
    assign s2_req_vSetIdx[p] = get_idx(s2_req_vaddr[p]);
    assign s2_req_ptags[p]   = get_phy_tag(s2_req_paddr[p]);
  end

  assign s2_flush = io_flush;

  // s2_valid（generatePipeControl，lastFire = s1_real_fire）
  always_ff @(posedge clock or posedge reset) begin
    if (reset) s2_valid <= 1'b0;
    else       s2_valid <= !io_flush && (s1_real_fire || (!s2_fire && s2_valid));
  end

  // s2 payload（s1_real_fire 打入）
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int p = 0; p < PORT_NUM; p++) begin
        s2_req_vaddr[p] <= '0;
        s2_req_paddr[p] <= '0;
        s2_exception[p] <= EXCP_NONE;
        s2_mmio[p]      <= 1'b0;
        s2_waymasks[p]  <= '0;
      end
      s2_isSoftPrefetch <= 1'b0;
      s2_doubleline     <= 1'b0;
    end else if (s1_real_fire) begin
      s2_isSoftPrefetch <= s1_isSoftPrefetch;
      s2_doubleline     <= s1_doubleline;
      for (int p = 0; p < PORT_NUM; p++) begin
        s2_req_vaddr[p] <= s1_req_vaddr[p];
        s2_req_paddr[p] <= s1_req_paddr[p];
        s2_exception[p] <= s1_exception_out[p];
        s2_mmio[p]      <= s1_mmio[p];
        s2_waymasks[p]  <= s1_waymasks[p];
      end
    end
  end

  // -------- s2 监听 MSHR：本周期 refill 命中本请求则视为已命中（ValidHoldBypass）--------
  // 注意：corrupt 的 refill 不算命中（与 mainPipe 相反），需再次发预取。
  logic s2_MSHR_match [PORT_NUM];
  logic s2_MSHR_hits  [PORT_NUM];
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_mshr_match
    assign s2_MSHR_match[p] =
      (s2_req_vSetIdx[p] == io_MSHRResp_bits_vSetIdx) &&
      (s2_req_ptags[p]   == get_phy_tag_from_blk(io_MSHRResp_bits_blkPaddr)) &&
      s2_valid && io_MSHRResp_valid && !io_MSHRResp_bits_corrupt;
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int p = 0; p < PORT_NUM; p++) s2_MSHR_hits[p] <= 1'b0;
    end else begin
      for (int p = 0; p < PORT_NUM; p++) begin
        if (s2_fire || io_flush)   s2_MSHR_hits[p] <= 1'b0;
        else if (s2_MSHR_match[p]) s2_MSHR_hits[p] <= 1'b1;
      end
    end
  end

  // -------- 判 miss --------
  // miss = 既非 SRAM 命中也非 MSHR 命中，且满足 doubleline 约束，且本 port 及之前 port 无例外、
  //        本 port 及之前 port 非 mmio（前序有例外/ mmio 则后序 port 不预取）。
  logic s2_SRAM_hits [PORT_NUM];
  logic s2_hits      [PORT_NUM];
  logic s2_miss      [PORT_NUM];
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_hits
    assign s2_SRAM_hits[p] = |s2_waymasks[p];
    // 当拍 refill 命中脉冲 s2_MSHR_match 需旁路进 hits（golden：hits_valid|match|waymask），
    // 否则 refill 当拍会误判 miss 而多发一次预取。
    assign s2_hits[p]      = s2_MSHR_hits[p] || s2_MSHR_match[p] || s2_SRAM_hits[p];
  end
  always_comb begin
    logic prefix_ok;    // 「本 port 之前的所有 port 都无例外且非 mmio」
    logic this_clean;
    logic port_en;
    prefix_ok = 1'b1;
    for (int p = 0; p < PORT_NUM; p++) begin
      this_clean = (s2_exception[p] == EXCP_NONE) && !s2_mmio[p];
      port_en    = (p == 0) ? 1'b1 : s2_doubleline;
      s2_miss[p] = !s2_hits[p] && port_en && prefix_ok && this_clean;
      prefix_ok  = prefix_ok && this_clean;
    end
  end

  // -------- 发预取请求（2 路优先级 Arbiter：port0 优先）--------
  // has_send 防重发：s1_real_fire 清零，某口 fire 后置位。
  logic mshr_in_valid [PORT_NUM];
  logic mshr_in_ready [PORT_NUM];
  logic has_send      [PORT_NUM];
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_mshr_in
    assign mshr_in_valid[p] = s2_valid && s2_miss[p] && !has_send[p];
  end

  // 内联 Arbiter2_ICacheMissReq（纯组合优先级仲裁）：port0 优先，输出选第一个 valid。
  logic mshr_out_valid;
  assign mshr_in_ready[0]   = io_MSHRReq_ready;
  assign mshr_in_ready[1]   = !mshr_in_valid[0] && io_MSHRReq_ready;
  assign mshr_out_valid     = mshr_in_valid[0] || mshr_in_valid[1];
  assign io_MSHRReq_valid   = mshr_out_valid;
  assign io_MSHRReq_bits_blkPaddr = mshr_in_valid[0] ? get_blk_addr(s2_req_paddr[0]) : get_blk_addr(s2_req_paddr[1]);
  assign io_MSHRReq_bits_vSetIdx  = mshr_in_valid[0] ? s2_req_vSetIdx[0]             : s2_req_vSetIdx[1];

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int p = 0; p < PORT_NUM; p++) has_send[p] <= 1'b0;
    end else begin
      for (int p = 0; p < PORT_NUM; p++) begin
        if (s1_real_fire)                              has_send[p] <= 1'b0;
        else if (mshr_in_ready[p] && mshr_in_valid[p]) has_send[p] <= 1'b1;
      end
    end
  end

  // s2 完成：每口要么已发、要么本就不 miss（为时序不并入 arbiter.fire）
  logic s2_finish;
  always_comb begin
    s2_finish = 1'b1;
    for (int p = 0; p < PORT_NUM; p++)
      s2_finish = s2_finish && (has_send[p] || !s2_miss[p]);
  end
  assign s2_ready = s2_finish || !s2_valid;
  assign s2_fire  = s2_valid && s2_finish && !s2_flush;

endmodule
