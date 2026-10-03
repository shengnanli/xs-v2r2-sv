// =============================================================================
// xs_IPrefetchPipe —— ICache 预取流水（FDIP：把 FTQ 的取指请求提前做 iTLB/meta 查询）
//
// 对应 Chisel: xiangshan.frontend.icache.IPrefetchPipe（IPrefetch.scala）
// golden: G1-canonical/golden-rtl/IPrefetchPipe.sv（firtool 展平，857 行 / 100 端口）
//
// 【它在 ICache 里的位置】
//   FTQ 每发一个取指块（startAddr 及跨行时的 nextlineStart），先送到本流水而不是
//   直接送 MainPipe：本流水查 iTLB 拿物理地址、查 meta SRAM 得到命中路（waymask），
//   把结果写进 WayLookup FIFO；MainPipe 稍后从 WayLookup 读出，直接按 waymask 读
//   data SRAM。miss 的 cacheline 由本流水的 s2 级向 MissUnit 发预取请求，MainPipe
//   到达时数据往往已经回填。软件预取（prefetch.i）也走这条流水，只是不写 WayLookup。
//
//     FTQ req ─▶ s0 ─▶ s1(iTLB 回应/ meta 比 tag / MSHR 回填监听 / 写 WayLookup)
//                        ─▶ s2(PMP 回应 / MSHR 回填监听 / 向 MissUnit 发 miss)
//
// 【s0】组合级：请求同时送 iTLB（两个端口）和 meta SRAM。s0 能走 = s1 空闲 且
//   meta SRAM 接受读；被 io.flush / BPU s2/s3 flush（ftqIdx 不晚于 flush 指针）/ s1
//   flush 任一命中即丢弃。
//
// 【s1】核心是一个 5 态小状态机（state）：
//   IDLE        : 常态。iTLB 两口都回来了（itlb_finish）就尝试写 WayLookup；写不进
//                 转 ENQ_WAY；写进了但 s2 忙转 ENTER_S2。
//   ITLB_RESEND : iTLB miss，等 iTLB 回填后重发；期间 s1_wait_itlb 记着哪一口还没回。
//                 回来后 meta SRAM 要重读一次（tag 比对要用新 paddr）：SRAM 接受就
//                 转 ENQ_WAY，否则转 META_RESEND 继续等。
//   META_RESEND : 等 meta SRAM 接受重读。
//   ENQ_WAY     : 等 WayLookup 接受写入（软件预取不写，直接放行）。
//   ENTER_S2    : 等 s2 空出来。
//   s1_ready = next_state==IDLE；s1 fire 时若 csr_pf_enable=0，请求就此丢弃不进 s2。
//
//   iTLB 回应按口分别"脉冲+锁存"：tlb_valid_pulse 是回应到达的那一拍（用回应线上的
//   值），之后用 *_q 寄存器里的副本 —— 这就是 Chisel 的 ResultHoldBypass。
//   meta 比 tag 得到 s1_SRAM_waymasks；MissUnit 同拍回填同一组（vSetIdx 相同）时要
//   就地修正：同 tag → 命中路改成回填路；不同 tag 但占了我记的那一路 → 改成 miss。
//   修正后的 waymask/meta_codes 在各口的 waymask_q/meta_codes_q 里保持到 s1 fire。
//
// 【s2】等 PMP 回应（DataHoldBypass：s1 fire 的下一拍取线上值，之后取寄存器），
//   合并 iTLB/PMP 例外与 mmio/pbmt 属性；对没命中、无例外、非 mmio 的行向 MissUnit 发
//   预取请求（两口经固定优先级仲裁 Arbiter2_ICacheMissReq），has_send 防重复发送。
//   s2 期间 MissUnit 回填了同一行也算命中（s2_MSHR_hits）。
//
// 【照抄 golden 的几处怪癖（bug-for-bug）】
//   * s1_backendException 按口各存一份（Scala 用 Vec(PortNumber) 装同一个值）。
//   * s1_wait_itlb[1] 的置位/清零不看 s1_doubleline（只有 need/pulse 才看）。
//   * s2_miss[1] 要求"前面的口也无例外、非 mmio"（Scala 的 take(i+1)）。
//   * 写 WayLookup 时 MissUnit 正在回填（MSHRResp.valid）就不写（避免与 SRAM 写冲突）。
//   * gpf 的 gpaddr：第 1 口给的是 gpaddr - 64（后端要的是取指块基址）。
//   * 无复位寄存器与 golden 同一套：RegNext(s0_fire)、RegNext(s1_need_meta&&ready)、
//     RegNext(s1_real_fire) 及 PMP 结果保持寄存器。golden 里 RegNext(s0_fire) 展平成
//     7 份完全相同的寄存器（s0_fire_r / REG / REG_1 / s1_need_itlb_REG …），这里只留一份。
//
// 【文件结构】package xs_iprefetch_pkg → 核 xs_IPrefetchPipe（struct 端口）
//            → golden 同名 wrapper IPrefetchPipe（扁平端口，仅打包/拆包）
// =============================================================================
package xs_iprefetch_pkg;
  // ---- 规模参数（KunminghuV2 ICache）----
  localparam int unsigned PORT_NUM     = 2;    // 一次取指最多跨 2 个 cacheline
  localparam int unsigned N_WAYS       = 4;    // 组相联路数 → waymask 宽
  localparam int unsigned VADDR_W      = 50;   // VAddrBits
  localparam int unsigned PADDR_W      = 48;   // PAddrBits
  localparam int unsigned GPADDR_IN_W  = 64;   // iTLB 回应里 gpaddr 端口宽（XLEN）
  localparam int unsigned GPADDR_W     = 56;   // PAddrBitsMax：WayLookup 存的 gpaddr 宽
  localparam int unsigned BLK_OFF_BITS = 6;    // log2(64B cacheline)
  localparam int unsigned IDX_BITS     = 8;    // vSetIdx = vaddr[13:6]
  localparam int unsigned UNTAG_BITS   = 12;   // ptag = paddr[47:12]
  localparam int unsigned TAG_BITS     = PADDR_W - UNTAG_BITS;      // 36
  localparam int unsigned BLK_PADDR_W  = PADDR_W - BLK_OFF_BITS;    // 42
  localparam int unsigned FTQ_PTR_W    = 6;    // FtqPtr.value 宽
  localparam int unsigned EXCP_W       = 2;    // ExceptionType.width
  localparam int unsigned PBMT_W       = 2;    // Pbmt.width
  localparam int unsigned META_CODE_W  = 1;    // ICacheMetaCodeBits（奇偶）
  localparam int unsigned BLOCK_BYTES  = 1 << BLK_OFF_BITS;         // 64

  // ---- ExceptionType 编码（FrontendBundle.scala）----
  localparam logic [EXCP_W-1:0] EXCP_NONE = 2'd0;
  localparam logic [EXCP_W-1:0] EXCP_PF   = 2'd1;
  localparam logic [EXCP_W-1:0] EXCP_GPF  = 2'd2;
  localparam logic [EXCP_W-1:0] EXCP_AF   = 2'd3;

  // ---- Pbmt 编码：nc=1 / io=2 视为 uncache ----
  localparam logic [PBMT_W-1:0] PBMT_NC = 2'd1;
  localparam logic [PBMT_W-1:0] PBMT_IO = 2'd2;

  // ---- s1 状态机（Enum(5)，编码与 golden 一致）----
  typedef enum logic [2:0] {
    S_IDLE        = 3'd0,
    S_ITLB_RESEND = 3'd1,
    S_META_RESEND = 3'd2,
    S_ENQ_WAY     = 3'd3,
    S_ENTER_S2    = 3'd4
  } s1_state_e;

  // ---- 端口 bundle ----
  typedef struct packed {
    logic                 flag;
    logic [FTQ_PTR_W-1:0] value;
  } ftq_ptr_t;

  typedef struct packed {                       // IPrefetchReq
    logic [VADDR_W-1:0] startAddr;
    logic [VADDR_W-1:0] nextlineStart;
    ftq_ptr_t           ftqIdx;
    logic               isSoftPrefetch;
    logic [EXCP_W-1:0]  backendException;
  } prefetch_req_t;

  typedef struct packed {                       // BpuFlushInfo 的一级（s2 或 s3）
    logic     valid;
    ftq_ptr_t bits;
  } bpu_flush_t;

  typedef struct packed {                       // TlbResp 里本流水用到的字段
    logic [PADDR_W-1:0]     paddr;
    logic [GPADDR_IN_W-1:0] gpaddr;
    logic [PBMT_W-1:0]      pbmt;
    logic                   miss;
    logic                   isForVSnonLeafPTE;
    logic                   gpf_instr;
    logic                   pf_instr;
    logic                   af_instr;
  } itlb_resp_t;

  typedef struct packed {                       // PMPRespBundle 里本流水用到的字段
    logic instr;                                // 取指 PMP 违例 → af
    logic mmio;
  } pmp_resp_t;

  typedef struct packed {                       // ICacheMetaRespBundle
    logic [PORT_NUM-1:0][N_WAYS-1:0][TAG_BITS-1:0]    tags;
    logic [PORT_NUM-1:0][N_WAYS-1:0][META_CODE_W-1:0] codes;
    logic [PORT_NUM-1:0][N_WAYS-1:0]                  entryValid;
  } meta_resp_t;

  typedef struct packed {                       // ICacheMissReq
    logic [BLK_PADDR_W-1:0] blkPaddr;
    logic [IDX_BITS-1:0]    vSetIdx;
  } miss_req_t;

  typedef struct packed {                       // ICacheMissResp
    logic [BLK_PADDR_W-1:0] blkPaddr;
    logic [IDX_BITS-1:0]    vSetIdx;
    logic [N_WAYS-1:0]      waymask;
    logic                   corrupt;
  } miss_resp_t;

  typedef struct packed {                       // WayLookupEntry 的一个口
    logic [IDX_BITS-1:0]    vSetIdx;
    logic [N_WAYS-1:0]      waymask;
    logic [TAG_BITS-1:0]    ptag;
    logic [EXCP_W-1:0]      itlb_exception;
    logic [PBMT_W-1:0]      itlb_pbmt;
    logic [META_CODE_W-1:0] meta_codes;
  } way_lookup_port_t;

  typedef struct packed {                       // WayLookupInfo
    way_lookup_port_t [PORT_NUM-1:0] entry;
    logic [GPADDR_W-1:0]             gpf_gpaddr;
    logic                            gpf_isForVSnonLeafPTE;
  } way_lookup_info_t;

  // ---- 地址切片 ----
  function automatic logic [IDX_BITS-1:0] get_idx(input logic [VADDR_W-1:0] vaddr);
    return vaddr[BLK_OFF_BITS +: IDX_BITS];
  endfunction

  function automatic logic [TAG_BITS-1:0] get_phy_tag(input logic [PADDR_W-1:0] paddr);
    return paddr[PADDR_W-1 : UNTAG_BITS];
  endfunction

  function automatic logic [BLK_PADDR_W-1:0] get_blk_addr(input logic [PADDR_W-1:0] paddr);
    return paddr[PADDR_W-1 : BLK_OFF_BITS];
  endfunction

  function automatic logic [TAG_BITS-1:0] get_phy_tag_from_blk(input logic [BLK_PADDR_W-1:0] blk);
    return blk[BLK_PADDR_W-1 : BLK_OFF_BITS];
  endfunction

  // meta ECC：1 位奇偶
  function automatic logic [META_CODE_W-1:0] encode_meta_ecc(input logic [TAG_BITS-1:0] ptag);
    return ^ptag;
  endfunction

  // ExceptionType.fromTlbResp：pf > gpf > af（af 展开成 {af,af} = 3）
  function automatic logic [EXCP_W-1:0] excp_from_tlb(input itlb_resp_t r);
    return r.pf_instr ? EXCP_PF : (r.gpf_instr ? EXCP_GPF : {EXCP_W{r.af_instr}});
  endfunction

  // ExceptionType.merge(a, b)：a 非 none 优先
  function automatic logic [EXCP_W-1:0] excp_merge(input logic [EXCP_W-1:0] a,
                                                   input logic [EXCP_W-1:0] b);
    return (|a) ? a : b;
  endfunction

  function automatic logic pbmt_is_uncache(input logic [PBMT_W-1:0] pbmt);
    return (pbmt == PBMT_NC) | (pbmt == PBMT_IO);
  endfunction

  // 环形指针"a 不晚于 b"：!isAfter(a, b) = a.flag ^ b.flag ^ (a.value <= b.value)。
  // BpuFlushInfo.shouldFlushByStageN(ftqIdx) = sN.valid && !isAfter(sN.bits, ftqIdx)
  function automatic logic ftq_not_after(input ftq_ptr_t a, input ftq_ptr_t b);
    return a.flag ^ b.flag ^ (a.value <= b.value);
  endfunction
endpackage


// =============================================================================
// 核：xs_IPrefetchPipe
// =============================================================================
module xs_IPrefetchPipe
  import xs_iprefetch_pkg::*;
(
  input  logic                              clock,
  input  logic                              reset,           // 异步高有效
  input  logic                              io_csr_pf_enable,
  input  logic                              io_flush,
  // FTQ / 软件预取请求
  output logic                              io_req_ready,
  input  logic                              io_req_valid,
  input  prefetch_req_t                     io_req_bits,
  input  bpu_flush_t                        io_flushFromBpu_s2,
  input  bpu_flush_t                        io_flushFromBpu_s3,
  // iTLB（两口，resp 无握手）
  output logic [PORT_NUM-1:0]               io_itlb_req_valid,
  output logic [PORT_NUM-1:0][VADDR_W-1:0]  io_itlb_req_vaddr,
  input  itlb_resp_t [PORT_NUM-1:0]         io_itlb_resp,
  output logic                              io_itlbFlushPipe,
  // PMP（两口）
  output logic [PORT_NUM-1:0]               io_pmp_req_valid,
  output logic [PORT_NUM-1:0][PADDR_W-1:0]  io_pmp_req_addr,
  input  pmp_resp_t [PORT_NUM-1:0]          io_pmp_resp,
  // meta SRAM 读
  input  logic                              io_metaRead_toIMeta_ready,
  output logic                              io_metaRead_toIMeta_valid,
  output logic [PORT_NUM-1:0][IDX_BITS-1:0] io_metaRead_toIMeta_vSetIdx,
  output logic                              io_metaRead_toIMeta_isDoubleLine,
  input  meta_resp_t                        io_metaRead_fromIMeta,
  // MissUnit
  input  logic                              io_MSHRReq_ready,
  output logic                              io_MSHRReq_valid,
  output miss_req_t                         io_MSHRReq_bits,
  input  logic                              io_MSHRResp_valid,
  input  miss_resp_t                        io_MSHRResp_bits,
  // WayLookup 写口
  input  logic                              io_wayLookupWrite_ready,
  output logic                              io_wayLookupWrite_valid,
  output way_lookup_info_t                  io_wayLookupWrite_bits,
  // perf 探针：golden 里是 IPrefetchPipe 内部的 `from_bpu_s1_flush_probe` 线（XSPerfAccumulate
  // bpu_s1_flush），SimTop 用绝对层次引用；按 golden 同名导到 wrapper（见 ICacheMainPipe 同法）。
  output logic                              from_bpu_s1_flush_probe
);

  // ---------------------------------------------------------------------------
  // 级间控制线（先声明，s0 要用到 s1 的）
  // ---------------------------------------------------------------------------
  logic s1_ready, s1_flush, s1_fire, s1_real_fire;
  logic s2_ready, s2_fire;

  // ===========================================================================
  // s0：接 FTQ 请求，同拍送 iTLB 与 meta SRAM
  // ===========================================================================
  logic [PORT_NUM-1:0][VADDR_W-1:0] s0_req_vaddr;
  assign s0_req_vaddr[0] = io_req_bits.startAddr;
  assign s0_req_vaddr[1] = io_req_bits.nextlineStart;
  // crossCacheline：起始地址落在 cacheline 后半（bit5=1）就要取两行
  logic s0_doubleline;
  assign s0_doubleline = io_req_bits.startAddr[5];

  // 硬件预取才受 BPU flush 影响（软件预取没有 ftqIdx 语义）
  logic from_bpu_s0_flush;
  assign from_bpu_s0_flush =
    ~io_req_bits.isSoftPrefetch
    & ((io_flushFromBpu_s2.valid & ftq_not_after(io_flushFromBpu_s2.bits, io_req_bits.ftqIdx))
     | (io_flushFromBpu_s3.valid & ftq_not_after(io_flushFromBpu_s3.bits, io_req_bits.ftqIdx)));

  logic s0_flush, s0_can_go, s0_fire;
  assign s0_flush  = io_flush | from_bpu_s0_flush | s1_flush;
  // Scala 还 && 了 toITLB(i).ready，但 iTLB 请求口 ready 恒 1，golden 里已折掉
  assign s0_can_go = s1_ready & io_metaRead_toIMeta_ready;
  assign s0_fire   = io_req_valid & s0_can_go & ~s0_flush;
  assign io_req_ready = s0_can_go;

  // ===========================================================================
  // s1：iTLB 回应 / meta 比 tag / 监听 MSHR 回填 / 写 WayLookup
  // ===========================================================================
  logic                             s1_valid;
  logic [PORT_NUM-1:0][VADDR_W-1:0] s1_req_vaddr;
  logic                             s1_isSoftPrefetch;
  logic                             s1_doubleline;
  ftq_ptr_t                         s1_req_ftqIdx;
  logic [PORT_NUM-1:0][EXCP_W-1:0]  s1_backendException;   // 两份同值（照抄 Scala Vec）
  s1_state_e                        state, next_state;
  logic                             s0_fire_q;             // RegNext(s0_fire)，无复位

  logic [PORT_NUM-1:0][IDX_BITS-1:0] s1_req_vSetIdx;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s1_idx
    assign s1_req_vSetIdx[p] = get_idx(s1_req_vaddr[p]);
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_valid            <= 1'b0;
      s1_req_vaddr        <= '0;
      s1_isSoftPrefetch   <= 1'b0;
      s1_doubleline       <= 1'b0;
      s1_req_ftqIdx       <= '0;
      s1_backendException <= '0;
      state               <= S_IDLE;
    end
    else begin
      // generatePipeControl(lastFire=s0_fire, thisFire=s1_fire, thisFlush=s1_flush)
      s1_valid <= ~s1_flush & (s0_fire | (~s1_fire & s1_valid));
      if (s0_fire) begin
        s1_req_vaddr        <= s0_req_vaddr;
        s1_isSoftPrefetch   <= io_req_bits.isSoftPrefetch;
        s1_doubleline       <= s0_doubleline;
        s1_req_ftqIdx       <= io_req_bits.ftqIdx;
        s1_backendException <= {PORT_NUM{io_req_bits.backendException}};
      end
      state <= next_state;
    end
  end

  always_ff @(posedge clock) begin
    s0_fire_q <= s0_fire;
  end

  // ---------------------------------------------------------------------------
  // iTLB：miss 就重发；回应到达那拍用线上值，之后用寄存器副本（ResultHoldBypass）
  // ---------------------------------------------------------------------------
  logic [PORT_NUM-1:0] s1_wait_itlb;        // 该口 iTLB miss、正等重填
  logic [PORT_NUM-1:0] s1_need_itlb;        // 本拍要向该口重发 iTLB 请求
  logic [PORT_NUM-1:0] tlb_valid_pulse;     // 该口 iTLB 回应本拍到达
  logic [PORT_NUM-1:0] tlb_valid_latch;     // 该口回应已到过（ValidHoldBypass 的寄存器）
  logic                itlb_finish;

  logic [PORT_NUM-1:0][PADDR_W-1:0]     s1_req_paddr;
  logic [PORT_NUM-1:0][GPADDR_W-1:0]    s1_req_gpaddr_tmp;
  logic [PORT_NUM-1:0]                  s1_isForVSnonLeafPTE_tmp;
  logic [PORT_NUM-1:0][EXCP_W-1:0]      s1_itlb_exception_tmp;
  logic [PORT_NUM-1:0][PBMT_W-1:0]      s1_itlb_pbmt;
  logic [PORT_NUM-1:0][EXCP_W-1:0]      s1_itlb_exception;     // 合并后端例外后
  logic [PORT_NUM-1:0]                  s1_itlb_exception_gpf;

  // 每个口自己的寄存器都放在自己的 generate 块里（一个寄存器只被一个进程写）
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s1_itlb
    // 第 1 口只在跨行请求时有意义
    localparam logic PORT_ALWAYS = (p == 0);
    logic port_active;
    assign port_active = PORT_ALWAYS | s1_doubleline;

    logic                wait_itlb_q;       // s1_wait_itlb(p)
    logic                valid_latch_q;     // tlb_valid_latch(p) 的寄存器
    logic [PADDR_W-1:0]  paddr_q;           // s1_req_paddr_reg(p)
    logic [GPADDR_W-1:0] gpaddr_q;
    logic                isForVSnonLeafPTE_q;
    logic [EXCP_W-1:0]   exception_q;
    logic [PBMT_W-1:0]   pbmt_q;

    assign s1_wait_itlb[p]    = wait_itlb_q;
    assign tlb_valid_latch[p] = valid_latch_q;
    assign s1_need_itlb[p]    = (s0_fire_q | wait_itlb_q) &  io_itlb_resp[p].miss & port_active;
    assign tlb_valid_pulse[p] = (s0_fire_q | wait_itlb_q) & ~io_itlb_resp[p].miss & port_active;

    // s1_wait_itlb：flush 清 > 刚发出去且 miss 置 1 > 等着且回来了清 0 > 保持
    //（★不看 doubleline，照抄 Scala★）
    always_ff @(posedge clock or posedge reset) begin
      if (reset)                                     wait_itlb_q <= 1'b0;
      else if (s1_flush)                             wait_itlb_q <= 1'b0;
      else if (s0_fire_q & io_itlb_resp[p].miss)     wait_itlb_q <= 1'b1;
      else if (wait_itlb_q & ~io_itlb_resp[p].miss)  wait_itlb_q <= 1'b0;
    end

    // ValidHoldBypass(tlb_valid_pulse, s1_fire, flush = s1_flush)：
    // golden 把 flush/fire 的清零放在置位之前
    always_ff @(posedge clock or posedge reset) begin
      if (reset) valid_latch_q <= 1'b0;
      else       valid_latch_q <= ~(s1_flush | s1_fire) & (tlb_valid_pulse[p] | valid_latch_q);
    end

    // 回应内容：到达拍取线上值并存入寄存器，之后取寄存器
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        paddr_q             <= '0;
        gpaddr_q            <= '0;
        isForVSnonLeafPTE_q <= 1'b0;
        exception_q         <= EXCP_NONE;
        pbmt_q              <= '0;
      end
      else if (tlb_valid_pulse[p]) begin
        paddr_q             <= io_itlb_resp[p].paddr;
        gpaddr_q            <= io_itlb_resp[p].gpaddr[GPADDR_W-1:0];
        isForVSnonLeafPTE_q <= io_itlb_resp[p].isForVSnonLeafPTE;
        exception_q         <= excp_from_tlb(io_itlb_resp[p]);
        pbmt_q              <= io_itlb_resp[p].pbmt;
      end
    end
    assign s1_req_paddr[p]             = tlb_valid_pulse[p] ? io_itlb_resp[p].paddr                : paddr_q;
    assign s1_req_gpaddr_tmp[p]        = tlb_valid_pulse[p] ? io_itlb_resp[p].gpaddr[GPADDR_W-1:0] : gpaddr_q;
    assign s1_isForVSnonLeafPTE_tmp[p] = tlb_valid_pulse[p] ? io_itlb_resp[p].isForVSnonLeafPTE    : isForVSnonLeafPTE_q;
    assign s1_itlb_exception_tmp[p]    = tlb_valid_pulse[p] ? excp_from_tlb(io_itlb_resp[p])       : exception_q;
    assign s1_itlb_pbmt[p]             = tlb_valid_pulse[p] ? io_itlb_resp[p].pbmt                 : pbmt_q;

    // 后端（高位 vaddr 检查）的例外优先于 iTLB 例外
    assign s1_itlb_exception[p]     = excp_merge(s1_backendException[p], s1_itlb_exception_tmp[p]);
    assign s1_itlb_exception_gpf[p] = (s1_itlb_exception[p] == EXCP_GPF);
  end

  assign itlb_finish = (tlb_valid_latch[0] | tlb_valid_pulse[0])
                     & (~s1_doubleline | tlb_valid_latch[1] | tlb_valid_pulse[1]);

  // iTLB 请求口：s1 重发优先，否则透传 s0
  assign io_itlb_req_valid[0] = s1_need_itlb[0] | io_req_valid;
  assign io_itlb_req_valid[1] = s1_need_itlb[1] | (io_req_valid & s0_doubleline);
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_itlb_req
    assign io_itlb_req_vaddr[p] = s1_need_itlb[p] ? s1_req_vaddr[p] : s0_req_vaddr[p];
  end
  assign io_itlbFlushPipe = s1_flush;

  // ---------------------------------------------------------------------------
  // meta SRAM：iTLB 重填完成后要重读一次
  // ---------------------------------------------------------------------------
  logic s1_need_meta;
  assign s1_need_meta = ((state == S_ITLB_RESEND) & itlb_finish) | (state == S_META_RESEND);

  assign io_metaRead_toIMeta_valid        = s1_need_meta | io_req_valid;
  assign io_metaRead_toIMeta_isDoubleLine = s1_need_meta ? s1_doubleline : s0_doubleline;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_meta_req
    assign io_metaRead_toIMeta_vSetIdx[p] = s1_need_meta ? s1_req_vSetIdx[p] : get_idx(s0_req_vaddr[p]);
  end

  // ---------------------------------------------------------------------------
  // meta 回应比 tag → 命中路 waymask；Mux1H 选出命中路的 ECC 码
  // ---------------------------------------------------------------------------
  logic [PORT_NUM-1:0][TAG_BITS-1:0]    s1_req_ptags;
  logic [PORT_NUM-1:0][N_WAYS-1:0]      s1_SRAM_waymasks;
  logic [PORT_NUM-1:0][META_CODE_W-1:0] s1_SRAM_meta_codes;

  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s1_meta
    assign s1_req_ptags[p] = get_phy_tag(s1_req_paddr[p]);
    for (genvar w = 0; w < N_WAYS; w++) begin : g_way
      assign s1_SRAM_waymasks[p][w] = (io_metaRead_fromIMeta.tags[p][w] == s1_req_ptags[p])
                                    & io_metaRead_fromIMeta.entryValid[p][w];
    end
    always_comb begin
      s1_SRAM_meta_codes[p] = '0;
      for (int w = 0; w < N_WAYS; w++)
        s1_SRAM_meta_codes[p] |= {META_CODE_W{s1_SRAM_waymasks[p][w]}} & io_metaRead_fromIMeta.codes[p][w];
    end
  end

  // ---------------------------------------------------------------------------
  // 按 MissUnit 回填修正 waymask/meta_codes（updateMetaInfo），并保持到 s1 fire
  // ---------------------------------------------------------------------------
  logic s1_SRAM_valid_q;    // RegNext(s1_need_meta && toMeta.ready)，无复位
  logic s1_SRAM_valid;      // 本拍 meta 回应有效（s0 发的或 s1 重发的）
  logic s1_MSHR_valid;
  always_ff @(posedge clock) begin
    s1_SRAM_valid_q <= s1_need_meta & io_metaRead_toIMeta_ready;
  end
  assign s1_SRAM_valid = s0_fire_q | s1_SRAM_valid_q;
  assign s1_MSHR_valid = io_MSHRResp_valid & ~io_MSHRResp_bits.corrupt;

  logic [PORT_NUM-1:0][N_WAYS-1:0]      s1_waymasks;
  logic [PORT_NUM-1:0][META_CODE_W-1:0] s1_meta_codes;

  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s1_update
    logic [N_WAYS-1:0]      waymask_q;        // s1_waymasks_r(p)
    logic [META_CODE_W-1:0] meta_codes_q;     // s1_meta_codes_r(p)
    logic [N_WAYS-1:0]      old_waymask;
    logic [META_CODE_W-1:0] old_meta_codes;
    logic                   mshr_vset_same, mshr_ptag_same, mshr_way_same;

    assign old_waymask    = s1_SRAM_valid ? s1_SRAM_waymasks[p]   : waymask_q;
    assign old_meta_codes = s1_SRAM_valid ? s1_SRAM_meta_codes[p] : meta_codes_q;

    assign mshr_vset_same = s1_MSHR_valid & (io_MSHRResp_bits.vSetIdx == s1_req_vSetIdx[p]);
    assign mshr_ptag_same = get_phy_tag_from_blk(io_MSHRResp_bits.blkPaddr) == s1_req_ptags[p];
    assign mshr_way_same  = io_MSHRResp_bits.waymask == old_waymask;

    // 同组同 tag：回填的就是我要的行 → 命中路 = 回填路，ECC 按 ptag 重算
    // 同组同路不同 tag：我记的那一路被覆盖了 → 改成 miss（ECC 不重要，不动）
    assign s1_waymasks[p] =
      mshr_vset_same ? (mshr_ptag_same ? io_MSHRResp_bits.waymask
                                       : (mshr_way_same ? '0 : old_waymask))
                     : old_waymask;
    assign s1_meta_codes[p] =
      (mshr_vset_same & mshr_ptag_same) ? encode_meta_ecc(s1_req_ptags[p]) : old_meta_codes;

    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        waymask_q    <= '0;
        meta_codes_q <= '0;
      end
      else if (s1_SRAM_valid | s1_MSHR_valid) begin
        waymask_q    <= s1_waymasks[p];
        meta_codes_q <= s1_meta_codes[p];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // 写 WayLookup（软件预取不写；MissUnit 正在回填时不写）
  // ---------------------------------------------------------------------------
  logic wayLookup_fire;
  assign io_wayLookupWrite_valid =
    ((state == S_ENQ_WAY) | ((state == S_IDLE) & itlb_finish))
    & ~s1_flush & ~io_MSHRResp_valid & ~s1_isSoftPrefetch;
  assign wayLookup_fire = io_wayLookupWrite_ready & io_wayLookupWrite_valid;

  for (genvar p = 0; p < PORT_NUM; p++) begin : g_wl_entry
    localparam logic PORT_ALWAYS = (p == 0);
    logic excp_valid;
    assign excp_valid = PORT_ALWAYS | s1_doubleline;   // 第 1 口的例外只在跨行时有效

    assign io_wayLookupWrite_bits.entry[p].vSetIdx        = s1_req_vSetIdx[p];
    assign io_wayLookupWrite_bits.entry[p].waymask        = s1_waymasks[p];
    assign io_wayLookupWrite_bits.entry[p].ptag           = s1_req_ptags[p];
    assign io_wayLookupWrite_bits.entry[p].itlb_exception = excp_valid ? s1_itlb_exception[p] : EXCP_NONE;
    assign io_wayLookupWrite_bits.entry[p].itlb_pbmt      = excp_valid ? s1_itlb_pbmt[p] : '0;   // Pbmt.pma = 0
    assign io_wayLookupWrite_bits.entry[p].meta_codes     = s1_meta_codes[p];
  end

  // gpf 信息取第一个报 gpf 的口；第 p 口给取指块基址 = gpaddr - p*64（PriorityMuxDefault）
  assign io_wayLookupWrite_bits.gpf_gpaddr =
    s1_itlb_exception_gpf[0] ? s1_req_gpaddr_tmp[0]
  : s1_itlb_exception_gpf[1] ? GPADDR_W'(s1_req_gpaddr_tmp[1] - GPADDR_W'(BLOCK_BYTES))
  : '0;
  assign io_wayLookupWrite_bits.gpf_isForVSnonLeafPTE =
    s1_itlb_exception_gpf[0] ? s1_isForVSnonLeafPTE_tmp[0]
  : s1_itlb_exception_gpf[1] ? s1_isForVSnonLeafPTE_tmp[1]
  : 1'b0;

  // ---------------------------------------------------------------------------
  // PMP：s1 有效期间持续查（iTLB 有例外时 paddr 可能无效，MainPipe 会再查一次）
  // ---------------------------------------------------------------------------
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_pmp_req
    assign io_pmp_req_valid[p] = s1_valid;
    assign io_pmp_req_addr[p]  = s1_req_paddr[p];
  end

  // ---------------------------------------------------------------------------
  // s1 状态机
  // ---------------------------------------------------------------------------
  always_comb begin
    next_state = state;
    case (state)
      S_IDLE: begin
        if (s1_valid) begin
          if (~itlb_finish)         next_state = S_ITLB_RESEND;
          else if (~wayLookup_fire) next_state = S_ENQ_WAY;
          else if (~s2_ready)       next_state = S_ENTER_S2;
        end
      end
      S_ITLB_RESEND: begin
        if (itlb_finish)
          next_state = io_metaRead_toIMeta_ready ? S_ENQ_WAY : S_META_RESEND;
      end
      S_META_RESEND: begin
        if (io_metaRead_toIMeta_ready) next_state = S_ENQ_WAY;
      end
      S_ENQ_WAY: begin
        if (wayLookup_fire | s1_isSoftPrefetch)
          next_state = s2_ready ? S_IDLE : S_ENTER_S2;
      end
      S_ENTER_S2: begin
        if (s2_ready) next_state = S_IDLE;
      end
      default: ;   // 5~7 不可达：保持（与 golden 一致）
    endcase
    if (s1_flush) next_state = S_IDLE;
  end

  logic from_bpu_s1_flush;
  assign from_bpu_s1_flush = s1_valid & ~s1_isSoftPrefetch & io_flushFromBpu_s3.valid
                           & ftq_not_after(io_flushFromBpu_s3.bits, s1_req_ftqIdx);
  assign s1_flush     = io_flush | from_bpu_s1_flush;
  assign from_bpu_s1_flush_probe = from_bpu_s1_flush;
  assign s1_ready     = (next_state == S_IDLE);
  assign s1_fire      = s1_ready & s1_valid & ~s1_flush;
  assign s1_real_fire = s1_fire & io_csr_pf_enable;   // 预取关掉时请求在 s1 就地丢弃

  // ===========================================================================
  // s2：PMP 回应 / 监听 MSHR 回填 / 向 MissUnit 发预取
  // ===========================================================================
  logic                             s2_valid;
  logic [PORT_NUM-1:0][VADDR_W-1:0] s2_req_vaddr;
  logic                             s2_isSoftPrefetch;
  logic                             s2_doubleline;
  logic [PORT_NUM-1:0][PADDR_W-1:0] s2_req_paddr;
  logic [PORT_NUM-1:0][EXCP_W-1:0]  s2_itlb_exception;
  logic [PORT_NUM-1:0][PBMT_W-1:0]  s2_itlb_pbmt;
  logic [PORT_NUM-1:0][N_WAYS-1:0]  s2_waymasks;
  logic                             s2_flush;
  assign s2_flush = io_flush;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s2_valid          <= 1'b0;
      s2_req_vaddr      <= '0;
      s2_isSoftPrefetch <= 1'b0;
      s2_doubleline     <= 1'b0;
      s2_req_paddr      <= '0;
      s2_itlb_exception <= '0;
      s2_itlb_pbmt      <= '0;
      s2_waymasks       <= '0;
    end
    else begin
      s2_valid <= ~s2_flush & (s1_real_fire | (~s2_fire & s2_valid));
      if (s1_real_fire) begin
        s2_req_vaddr      <= s1_req_vaddr;
        s2_isSoftPrefetch <= s1_isSoftPrefetch;
        s2_doubleline     <= s1_doubleline;
        s2_req_paddr      <= s1_req_paddr;
        s2_itlb_exception <= s1_itlb_exception;
        s2_itlb_pbmt      <= s1_itlb_pbmt;
        s2_waymasks       <= s1_waymasks;
      end
    end
  end

  // PMP 回应：DataHoldBypass(_, RegNext(s1_real_fire)) —— 进 s2 的下一拍取线上值并存下
  logic                            s1_real_fire_q;   // 无复位
  logic [PORT_NUM-1:0][EXCP_W-1:0] s2_pmp_exception;
  logic [PORT_NUM-1:0]             s2_pmp_mmio;
  always_ff @(posedge clock) begin
    s1_real_fire_q <= s1_real_fire;
  end
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s2_pmp
    logic [EXCP_W-1:0] pmp_excp_wire;
    logic [EXCP_W-1:0] pmp_excp_q;    // 无复位（golden s2_pmp_exception_r）
    logic              pmp_mmio_q;    // 无复位（golden s2_pmp_mmio_r）
    assign pmp_excp_wire = {EXCP_W{io_pmp_resp[p].instr}};   // ExceptionType.fromPMPResp：af
    always_ff @(posedge clock) begin
      if (s1_real_fire_q) begin
        pmp_excp_q <= pmp_excp_wire;
        pmp_mmio_q <= io_pmp_resp[p].mmio;
      end
    end
    assign s2_pmp_exception[p] = s1_real_fire_q ? pmp_excp_wire        : pmp_excp_q;
    assign s2_pmp_mmio[p]      = s1_real_fire_q ? io_pmp_resp[p].mmio  : pmp_mmio_q;
  end

  // 例外合并（iTLB > PMP）；mmio = PMP mmio | pbmt 是 nc/io
  logic [PORT_NUM-1:0][EXCP_W-1:0]   s2_exception;
  logic [PORT_NUM-1:0]               s2_mmio;
  logic [PORT_NUM-1:0][IDX_BITS-1:0] s2_req_vSetIdx;
  logic [PORT_NUM-1:0][TAG_BITS-1:0] s2_req_ptags;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s2_attr
    assign s2_exception[p]   = excp_merge(s2_itlb_exception[p], s2_pmp_exception[p]);
    assign s2_mmio[p]        = s2_pmp_mmio[p] | pbmt_is_uncache(s2_itlb_pbmt[p]);
    assign s2_req_vSetIdx[p] = get_idx(s2_req_vaddr[p]);
    assign s2_req_ptags[p]   = get_phy_tag(s2_req_paddr[p]);
  end

  // 监听 MissUnit 回填：s2 期间回填了同一行也算命中（corrupt 的不算，要重新预取）
  logic [PORT_NUM-1:0] s2_MSHR_match, s2_hits, s2_miss;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s2_hit
    logic mshr_hit_q;    // ValidHoldBypass(s2_MSHR_match, s2_fire || s2_flush) 的寄存器
    assign s2_MSHR_match[p] = (s2_req_vSetIdx[p] == io_MSHRResp_bits.vSetIdx)
                            & (s2_req_ptags[p] == get_phy_tag_from_blk(io_MSHRResp_bits.blkPaddr))
                            & s2_valid & io_MSHRResp_valid & ~io_MSHRResp_bits.corrupt;
    always_ff @(posedge clock or posedge reset) begin
      if (reset) mshr_hit_q <= 1'b0;
      else       mshr_hit_q <= ~(s2_fire | s2_flush) & (s2_MSHR_match[p] | mshr_hit_q);
    end
    assign s2_hits[p] = mshr_hit_q | s2_MSHR_match[p] | (|s2_waymasks[p]);
  end

  // 没命中、（第 1 口须跨行）、本口及之前的口都无例外且非 mmio，才预取
  assign s2_miss[0] = ~s2_hits[0]
                    & (s2_exception[0] == EXCP_NONE) & ~s2_mmio[0];
  assign s2_miss[1] = ~s2_hits[1] & s2_doubleline
                    & ~((|s2_exception[0]) | (|s2_exception[1]))
                    & ~s2_mmio[0] & ~s2_mmio[1];

  // ---------------------------------------------------------------------------
  // 向 MissUnit 发请求：两口经固定优先级仲裁；has_send 防重复
  // ---------------------------------------------------------------------------
  logic [PORT_NUM-1:0] has_send;
  logic [PORT_NUM-1:0] toMSHR_in_valid, toMSHR_in_ready;
  for (genvar p = 0; p < PORT_NUM; p++) begin : g_s2_send
    logic has_send_q;
    assign has_send[p]        = has_send_q;
    assign toMSHR_in_valid[p] = s2_valid & s2_miss[p] & ~has_send_q;
    always_ff @(posedge clock or posedge reset) begin
      if (reset)                                        has_send_q <= 1'b0;
      else if (s1_real_fire)                            has_send_q <= 1'b0;
      else if (toMSHR_in_ready[p] & toMSHR_in_valid[p]) has_send_q <= 1'b1;
    end
  end

  Arbiter2_ICacheMissReq toMSHRArbiter (
    .io_in_0_ready         (toMSHR_in_ready[0]),
    .io_in_0_valid         (toMSHR_in_valid[0]),
    .io_in_0_bits_blkPaddr (get_blk_addr(s2_req_paddr[0])),
    .io_in_0_bits_vSetIdx  (s2_req_vSetIdx[0]),
    .io_in_1_ready         (toMSHR_in_ready[1]),
    .io_in_1_valid         (toMSHR_in_valid[1]),
    .io_in_1_bits_blkPaddr (get_blk_addr(s2_req_paddr[1])),
    .io_in_1_bits_vSetIdx  (s2_req_vSetIdx[1]),
    .io_out_ready          (io_MSHRReq_ready),
    .io_out_valid          (io_MSHRReq_valid),
    .io_out_bits_blkPaddr  (io_MSHRReq_bits.blkPaddr),
    .io_out_bits_vSetIdx   (io_MSHRReq_bits.vSetIdx)
  );

  // s2 完成 = 每一口要么已发出、要么本来就不需要发（为时序不看本拍 fire）
  logic s2_finish;
  assign s2_finish = &(has_send | ~s2_miss);
  assign s2_ready  = s2_finish | ~s2_valid;
  assign s2_fire   = s2_valid & s2_finish & ~s2_flush;

endmodule


// =============================================================================
// golden 同名 wrapper：IPrefetchPipe（扁平端口 ↔ xs_IPrefetchPipe 的 struct 端口）
// 只做机械的打包/拆包，供 FM 对比与 ST 替换。
// =============================================================================
module IPrefetchPipe
  import xs_iprefetch_pkg::*;
(
  input         clock,
  input         reset,
  input         io_csr_pf_enable,
  input         io_flush,
  output        io_req_ready,
  input         io_req_valid,
  input  [49:0] io_req_bits_startAddr,
  input  [49:0] io_req_bits_nextlineStart,
  input         io_req_bits_ftqIdx_flag,
  input  [5:0]  io_req_bits_ftqIdx_value,
  input         io_req_bits_isSoftPrefetch,
  input  [1:0]  io_req_bits_backendException,
  input         io_flushFromBpu_s2_valid,
  input         io_flushFromBpu_s2_bits_flag,
  input  [5:0]  io_flushFromBpu_s2_bits_value,
  input         io_flushFromBpu_s3_valid,
  input         io_flushFromBpu_s3_bits_flag,
  input  [5:0]  io_flushFromBpu_s3_bits_value,
  output        io_itlb_0_req_valid,
  output [49:0] io_itlb_0_req_bits_vaddr,
  input  [47:0] io_itlb_0_resp_bits_paddr_0,
  input  [63:0] io_itlb_0_resp_bits_gpaddr_0,
  input  [1:0]  io_itlb_0_resp_bits_pbmt_0,
  input         io_itlb_0_resp_bits_miss,
  input         io_itlb_0_resp_bits_isForVSnonLeafPTE,
  input         io_itlb_0_resp_bits_excp_0_gpf_instr,
  input         io_itlb_0_resp_bits_excp_0_pf_instr,
  input         io_itlb_0_resp_bits_excp_0_af_instr,
  output        io_itlb_1_req_valid,
  output [49:0] io_itlb_1_req_bits_vaddr,
  input  [47:0] io_itlb_1_resp_bits_paddr_0,
  input  [63:0] io_itlb_1_resp_bits_gpaddr_0,
  input  [1:0]  io_itlb_1_resp_bits_pbmt_0,
  input         io_itlb_1_resp_bits_miss,
  input         io_itlb_1_resp_bits_isForVSnonLeafPTE,
  input         io_itlb_1_resp_bits_excp_0_gpf_instr,
  input         io_itlb_1_resp_bits_excp_0_pf_instr,
  input         io_itlb_1_resp_bits_excp_0_af_instr,
  output        io_itlbFlushPipe,
  output        io_pmp_0_req_valid,
  output [47:0] io_pmp_0_req_bits_addr,
  input         io_pmp_0_resp_instr,
  input         io_pmp_0_resp_mmio,
  output        io_pmp_1_req_valid,
  output [47:0] io_pmp_1_req_bits_addr,
  input         io_pmp_1_resp_instr,
  input         io_pmp_1_resp_mmio,
  input         io_metaRead_toIMeta_ready,
  output        io_metaRead_toIMeta_valid,
  output [7:0]  io_metaRead_toIMeta_bits_vSetIdx_0,
  output [7:0]  io_metaRead_toIMeta_bits_vSetIdx_1,
  output        io_metaRead_toIMeta_bits_isDoubleLine,
  input  [35:0] io_metaRead_fromIMeta_metas_0_0_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_0_1_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_0_2_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_0_3_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_1_0_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_1_1_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_1_2_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_1_3_tag,
  input         io_metaRead_fromIMeta_codes_0_0,
  input         io_metaRead_fromIMeta_codes_0_1,
  input         io_metaRead_fromIMeta_codes_0_2,
  input         io_metaRead_fromIMeta_codes_0_3,
  input         io_metaRead_fromIMeta_codes_1_0,
  input         io_metaRead_fromIMeta_codes_1_1,
  input         io_metaRead_fromIMeta_codes_1_2,
  input         io_metaRead_fromIMeta_codes_1_3,
  input         io_metaRead_fromIMeta_entryValid_0_0,
  input         io_metaRead_fromIMeta_entryValid_0_1,
  input         io_metaRead_fromIMeta_entryValid_0_2,
  input         io_metaRead_fromIMeta_entryValid_0_3,
  input         io_metaRead_fromIMeta_entryValid_1_0,
  input         io_metaRead_fromIMeta_entryValid_1_1,
  input         io_metaRead_fromIMeta_entryValid_1_2,
  input         io_metaRead_fromIMeta_entryValid_1_3,
  input         io_MSHRReq_ready,
  output        io_MSHRReq_valid,
  output [41:0] io_MSHRReq_bits_blkPaddr,
  output [7:0]  io_MSHRReq_bits_vSetIdx,
  input         io_MSHRResp_valid,
  input  [41:0] io_MSHRResp_bits_blkPaddr,
  input  [7:0]  io_MSHRResp_bits_vSetIdx,
  input  [3:0]  io_MSHRResp_bits_waymask,
  input         io_MSHRResp_bits_corrupt,
  input         io_wayLookupWrite_ready,
  output        io_wayLookupWrite_valid,
  output [7:0]  io_wayLookupWrite_bits_entry_vSetIdx_0,
  output [7:0]  io_wayLookupWrite_bits_entry_vSetIdx_1,
  output [3:0]  io_wayLookupWrite_bits_entry_waymask_0,
  output [3:0]  io_wayLookupWrite_bits_entry_waymask_1,
  output [35:0] io_wayLookupWrite_bits_entry_ptag_0,
  output [35:0] io_wayLookupWrite_bits_entry_ptag_1,
  output [1:0]  io_wayLookupWrite_bits_entry_itlb_exception_0,
  output [1:0]  io_wayLookupWrite_bits_entry_itlb_exception_1,
  output [1:0]  io_wayLookupWrite_bits_entry_itlb_pbmt_0,
  output [1:0]  io_wayLookupWrite_bits_entry_itlb_pbmt_1,
  output        io_wayLookupWrite_bits_entry_meta_codes_0,
  output        io_wayLookupWrite_bits_entry_meta_codes_1,
  output [55:0] io_wayLookupWrite_bits_gpf_gpaddr,
  output        io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE
);
  // ---- flat → struct ----
  prefetch_req_t req_bits;
  assign req_bits.startAddr        = io_req_bits_startAddr;
  assign req_bits.nextlineStart    = io_req_bits_nextlineStart;
  assign req_bits.ftqIdx.flag      = io_req_bits_ftqIdx_flag;
  assign req_bits.ftqIdx.value     = io_req_bits_ftqIdx_value;
  assign req_bits.isSoftPrefetch   = io_req_bits_isSoftPrefetch;
  assign req_bits.backendException = io_req_bits_backendException;

  bpu_flush_t bpu_s2, bpu_s3;
  assign bpu_s2.valid      = io_flushFromBpu_s2_valid;
  assign bpu_s2.bits.flag  = io_flushFromBpu_s2_bits_flag;
  assign bpu_s2.bits.value = io_flushFromBpu_s2_bits_value;
  assign bpu_s3.valid      = io_flushFromBpu_s3_valid;
  assign bpu_s3.bits.flag  = io_flushFromBpu_s3_bits_flag;
  assign bpu_s3.bits.value = io_flushFromBpu_s3_bits_value;

  itlb_resp_t [PORT_NUM-1:0] itlb_resp;
  assign itlb_resp[0].paddr             = io_itlb_0_resp_bits_paddr_0;
  assign itlb_resp[0].gpaddr            = io_itlb_0_resp_bits_gpaddr_0;
  assign itlb_resp[0].pbmt              = io_itlb_0_resp_bits_pbmt_0;
  assign itlb_resp[0].miss              = io_itlb_0_resp_bits_miss;
  assign itlb_resp[0].isForVSnonLeafPTE = io_itlb_0_resp_bits_isForVSnonLeafPTE;
  assign itlb_resp[0].gpf_instr         = io_itlb_0_resp_bits_excp_0_gpf_instr;
  assign itlb_resp[0].pf_instr          = io_itlb_0_resp_bits_excp_0_pf_instr;
  assign itlb_resp[0].af_instr          = io_itlb_0_resp_bits_excp_0_af_instr;
  assign itlb_resp[1].paddr             = io_itlb_1_resp_bits_paddr_0;
  assign itlb_resp[1].gpaddr            = io_itlb_1_resp_bits_gpaddr_0;
  assign itlb_resp[1].pbmt              = io_itlb_1_resp_bits_pbmt_0;
  assign itlb_resp[1].miss              = io_itlb_1_resp_bits_miss;
  assign itlb_resp[1].isForVSnonLeafPTE = io_itlb_1_resp_bits_isForVSnonLeafPTE;
  assign itlb_resp[1].gpf_instr         = io_itlb_1_resp_bits_excp_0_gpf_instr;
  assign itlb_resp[1].pf_instr          = io_itlb_1_resp_bits_excp_0_pf_instr;
  assign itlb_resp[1].af_instr          = io_itlb_1_resp_bits_excp_0_af_instr;

  pmp_resp_t [PORT_NUM-1:0] pmp_resp;
  assign pmp_resp[0].instr = io_pmp_0_resp_instr;
  assign pmp_resp[0].mmio  = io_pmp_0_resp_mmio;
  assign pmp_resp[1].instr = io_pmp_1_resp_instr;
  assign pmp_resp[1].mmio  = io_pmp_1_resp_mmio;

  meta_resp_t meta_resp;
  assign meta_resp.tags[0][0] = io_metaRead_fromIMeta_metas_0_0_tag;
  assign meta_resp.tags[0][1] = io_metaRead_fromIMeta_metas_0_1_tag;
  assign meta_resp.tags[0][2] = io_metaRead_fromIMeta_metas_0_2_tag;
  assign meta_resp.tags[0][3] = io_metaRead_fromIMeta_metas_0_3_tag;
  assign meta_resp.tags[1][0] = io_metaRead_fromIMeta_metas_1_0_tag;
  assign meta_resp.tags[1][1] = io_metaRead_fromIMeta_metas_1_1_tag;
  assign meta_resp.tags[1][2] = io_metaRead_fromIMeta_metas_1_2_tag;
  assign meta_resp.tags[1][3] = io_metaRead_fromIMeta_metas_1_3_tag;
  assign meta_resp.codes[0]   = {io_metaRead_fromIMeta_codes_0_3, io_metaRead_fromIMeta_codes_0_2,
                                 io_metaRead_fromIMeta_codes_0_1, io_metaRead_fromIMeta_codes_0_0};
  assign meta_resp.codes[1]   = {io_metaRead_fromIMeta_codes_1_3, io_metaRead_fromIMeta_codes_1_2,
                                 io_metaRead_fromIMeta_codes_1_1, io_metaRead_fromIMeta_codes_1_0};
  assign meta_resp.entryValid[0] = {io_metaRead_fromIMeta_entryValid_0_3, io_metaRead_fromIMeta_entryValid_0_2,
                                    io_metaRead_fromIMeta_entryValid_0_1, io_metaRead_fromIMeta_entryValid_0_0};
  assign meta_resp.entryValid[1] = {io_metaRead_fromIMeta_entryValid_1_3, io_metaRead_fromIMeta_entryValid_1_2,
                                    io_metaRead_fromIMeta_entryValid_1_1, io_metaRead_fromIMeta_entryValid_1_0};

  miss_resp_t mshr_resp;
  assign mshr_resp.blkPaddr = io_MSHRResp_bits_blkPaddr;
  assign mshr_resp.vSetIdx  = io_MSHRResp_bits_vSetIdx;
  assign mshr_resp.waymask  = io_MSHRResp_bits_waymask;
  assign mshr_resp.corrupt  = io_MSHRResp_bits_corrupt;

  // ---- 核 ----
  logic [PORT_NUM-1:0]               itlb_req_valid;
  logic [PORT_NUM-1:0][VADDR_W-1:0]  itlb_req_vaddr;
  logic [PORT_NUM-1:0]               pmp_req_valid;
  logic [PORT_NUM-1:0][PADDR_W-1:0]  pmp_req_addr;
  logic [PORT_NUM-1:0][IDX_BITS-1:0] meta_req_vSetIdx;
  miss_req_t                         mshr_req;
  way_lookup_info_t                  wl_bits;
  // golden 同名 perf 探针（SimTop XMR 观测点；不是对外端口）
  wire                               from_bpu_s1_flush_probe;

  xs_IPrefetchPipe u_core (
    .clock(clock), .reset(reset),
    .io_csr_pf_enable(io_csr_pf_enable), .io_flush(io_flush),
    .io_req_ready(io_req_ready), .io_req_valid(io_req_valid), .io_req_bits(req_bits),
    .io_flushFromBpu_s2(bpu_s2), .io_flushFromBpu_s3(bpu_s3),
    .io_itlb_req_valid(itlb_req_valid), .io_itlb_req_vaddr(itlb_req_vaddr), .io_itlb_resp(itlb_resp),
    .io_itlbFlushPipe(io_itlbFlushPipe),
    .io_pmp_req_valid(pmp_req_valid), .io_pmp_req_addr(pmp_req_addr), .io_pmp_resp(pmp_resp),
    .io_metaRead_toIMeta_ready(io_metaRead_toIMeta_ready),
    .io_metaRead_toIMeta_valid(io_metaRead_toIMeta_valid),
    .io_metaRead_toIMeta_vSetIdx(meta_req_vSetIdx),
    .io_metaRead_toIMeta_isDoubleLine(io_metaRead_toIMeta_bits_isDoubleLine),
    .io_metaRead_fromIMeta(meta_resp),
    .io_MSHRReq_ready(io_MSHRReq_ready), .io_MSHRReq_valid(io_MSHRReq_valid), .io_MSHRReq_bits(mshr_req),
    .io_MSHRResp_valid(io_MSHRResp_valid), .io_MSHRResp_bits(mshr_resp),
    .io_wayLookupWrite_ready(io_wayLookupWrite_ready),
    .io_wayLookupWrite_valid(io_wayLookupWrite_valid),
    .io_wayLookupWrite_bits(wl_bits),
    .from_bpu_s1_flush_probe(from_bpu_s1_flush_probe)
  );

  // ---- struct → flat ----
  assign io_itlb_0_req_valid      = itlb_req_valid[0];
  assign io_itlb_1_req_valid      = itlb_req_valid[1];
  assign io_itlb_0_req_bits_vaddr = itlb_req_vaddr[0];
  assign io_itlb_1_req_bits_vaddr = itlb_req_vaddr[1];
  assign io_pmp_0_req_valid       = pmp_req_valid[0];
  assign io_pmp_1_req_valid       = pmp_req_valid[1];
  assign io_pmp_0_req_bits_addr   = pmp_req_addr[0];
  assign io_pmp_1_req_bits_addr   = pmp_req_addr[1];
  assign io_metaRead_toIMeta_bits_vSetIdx_0 = meta_req_vSetIdx[0];
  assign io_metaRead_toIMeta_bits_vSetIdx_1 = meta_req_vSetIdx[1];
  assign io_MSHRReq_bits_blkPaddr = mshr_req.blkPaddr;
  assign io_MSHRReq_bits_vSetIdx  = mshr_req.vSetIdx;

  assign io_wayLookupWrite_bits_entry_vSetIdx_0        = wl_bits.entry[0].vSetIdx;
  assign io_wayLookupWrite_bits_entry_vSetIdx_1        = wl_bits.entry[1].vSetIdx;
  assign io_wayLookupWrite_bits_entry_waymask_0        = wl_bits.entry[0].waymask;
  assign io_wayLookupWrite_bits_entry_waymask_1        = wl_bits.entry[1].waymask;
  assign io_wayLookupWrite_bits_entry_ptag_0           = wl_bits.entry[0].ptag;
  assign io_wayLookupWrite_bits_entry_ptag_1           = wl_bits.entry[1].ptag;
  assign io_wayLookupWrite_bits_entry_itlb_exception_0 = wl_bits.entry[0].itlb_exception;
  assign io_wayLookupWrite_bits_entry_itlb_exception_1 = wl_bits.entry[1].itlb_exception;
  assign io_wayLookupWrite_bits_entry_itlb_pbmt_0      = wl_bits.entry[0].itlb_pbmt;
  assign io_wayLookupWrite_bits_entry_itlb_pbmt_1      = wl_bits.entry[1].itlb_pbmt;
  assign io_wayLookupWrite_bits_entry_meta_codes_0     = wl_bits.entry[0].meta_codes;
  assign io_wayLookupWrite_bits_entry_meta_codes_1     = wl_bits.entry[1].meta_codes;
  assign io_wayLookupWrite_bits_gpf_gpaddr             = wl_bits.gpf_gpaddr;
  assign io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE  = wl_bits.gpf_isForVSnonLeafPTE;
endmodule
