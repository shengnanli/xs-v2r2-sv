// IPrefetchPipe 双例化逐拍比对：golden IPrefetchPipe vs 可读重写 IPrefetchPipe_xs
//
// 两侧例化的是同一份 Arbiter2_ICacheMissReq（RTL_GOLDEN_DEPS 两侧同源），所以本 tb
// 验的是流水本体：s0 接请求、s1 的 5 态状态机（iTLB 重发 / meta 重读 / 写 WayLookup /
// 等 s2）、iTLB 回应脉冲+锁存、meta 比 tag、MSHR 回填就地修正 waymask、gpf 选口、
// s2 的 PMP 合并、MSHR 命中监听、防重复的 miss 发射。
//
// 【激励】所有输入逐拍随机，但地址池故意开小：组索引 4 个、物理 tag 4 个，
//   meta 回应的 tag 也从同一个池里抽，这样 tag 命中 / 多路命中 / MSHR 回填同组同 tag /
//   同组同路不同 tag 这些分支都真的走到。iTLB 回应 miss 概率 25%，让 ITLB_RESEND →
//   META_RESEND 这条链常走；MSHRReq_ready 70% 让 s2 堵住、ENTER_S2 可达。
//   csr_pf_enable 成段翻转（关掉时 s1 fire 的请求要在 s1 就地丢弃）。
//
// 【采样相位】驱动用 posedge 非阻塞，比对在 negedge 后 #4（下一个 posedge 前 1ns）。
//
// 【X 守卫必须一次都不触发】判据不只 errors==0，还要求 checks == N_OUT × 比对拍数
//   且 x_skips==0：golden 的无复位寄存器（RegNext(s0_fire) 等）在 initreg 两档下
//   都在进入比对窗口前写定，一旦有 X 让守卫跳过某次比较，恒等式立刻不成立。
//
// 【覆盖闸】状态机 5 态各自的驻留、两口的 iTLB 等待、BPU s0/s1 flush、软件预取、
//   WayLookup 写入握手、两口各自的 miss 发射、MSHR 回填修正（同 tag / 同路）、
//   s2 期间的 MSHR 命中、gpf 选第 0/1 口、pf_enable=0 丢弃、异步复位脉冲 ——
//   每项 >= 门限，不足即 TEST FAILED，不看 errors。
`timescale 1ns/1ps
module tb;

  localparam int N_OUT   = 32;    // golden 输出端口数（比对项数/拍）
  localparam int COV_MIN = 200;

  int unsigned NCYCLES = 200000;

  bit   clk = 0;
  logic rst;
  always #5 clk = ~clk;

  // ---------------------------------------------------------------------
  // DUT 输入（两侧共用）
  // ---------------------------------------------------------------------
  logic        io_csr_pf_enable;
  logic        io_flush;
  logic        io_req_valid;
  logic [49:0] io_req_bits_startAddr;
  logic [49:0] io_req_bits_nextlineStart;
  logic        io_req_bits_ftqIdx_flag;
  logic [5:0]  io_req_bits_ftqIdx_value;
  logic        io_req_bits_isSoftPrefetch;
  logic [1:0]  io_req_bits_backendException;
  logic        io_flushFromBpu_s2_valid;
  logic        io_flushFromBpu_s2_bits_flag;
  logic [5:0]  io_flushFromBpu_s2_bits_value;
  logic        io_flushFromBpu_s3_valid;
  logic        io_flushFromBpu_s3_bits_flag;
  logic [5:0]  io_flushFromBpu_s3_bits_value;
  logic [47:0] io_itlb_resp_paddr      [2];
  logic [63:0] io_itlb_resp_gpaddr     [2];
  logic [1:0]  io_itlb_resp_pbmt       [2];
  logic        io_itlb_resp_miss       [2];
  logic        io_itlb_resp_vsnonleaf  [2];
  logic        io_itlb_resp_gpf        [2];
  logic        io_itlb_resp_pf         [2];
  logic        io_itlb_resp_af         [2];
  logic        io_pmp_resp_instr       [2];
  logic        io_pmp_resp_mmio        [2];
  logic        io_metaRead_toIMeta_ready;
  logic [35:0] io_meta_tag             [2][4];
  logic        io_meta_code            [2][4];
  logic        io_meta_valid           [2][4];
  logic        io_MSHRReq_ready;
  logic        io_MSHRResp_valid;
  logic [41:0] io_MSHRResp_bits_blkPaddr;
  logic [7:0]  io_MSHRResp_bits_vSetIdx;
  logic [3:0]  io_MSHRResp_bits_waymask;
  logic        io_MSHRResp_bits_corrupt;
  logic        io_wayLookupWrite_ready;

  // ---------------------------------------------------------------------
  // DUT 输出（g_ = golden, i_ = 重写）
  // ---------------------------------------------------------------------
  wire        g_req_ready,          i_req_ready;
  wire        g_itlb0_valid,        i_itlb0_valid;
  wire [49:0] g_itlb0_vaddr,        i_itlb0_vaddr;
  wire        g_itlb1_valid,        i_itlb1_valid;
  wire [49:0] g_itlb1_vaddr,        i_itlb1_vaddr;
  wire        g_itlbFlushPipe,      i_itlbFlushPipe;
  wire        g_pmp0_valid,         i_pmp0_valid;
  wire [47:0] g_pmp0_addr,          i_pmp0_addr;
  wire        g_pmp1_valid,         i_pmp1_valid;
  wire [47:0] g_pmp1_addr,          i_pmp1_addr;
  wire        g_meta_valid,         i_meta_valid;
  wire [7:0]  g_meta_vset0,         i_meta_vset0;
  wire [7:0]  g_meta_vset1,         i_meta_vset1;
  wire        g_meta_double,        i_meta_double;
  wire        g_mshr_valid,         i_mshr_valid;
  wire [41:0] g_mshr_blkPaddr,      i_mshr_blkPaddr;
  wire [7:0]  g_mshr_vSetIdx,       i_mshr_vSetIdx;
  wire        g_wl_valid,           i_wl_valid;
  wire [7:0]  g_wl_vset0,           i_wl_vset0;
  wire [7:0]  g_wl_vset1,           i_wl_vset1;
  wire [3:0]  g_wl_way0,            i_wl_way0;
  wire [3:0]  g_wl_way1,            i_wl_way1;
  wire [35:0] g_wl_ptag0,           i_wl_ptag0;
  wire [35:0] g_wl_ptag1,           i_wl_ptag1;
  wire [1:0]  g_wl_excp0,           i_wl_excp0;
  wire [1:0]  g_wl_excp1,           i_wl_excp1;
  wire [1:0]  g_wl_pbmt0,           i_wl_pbmt0;
  wire [1:0]  g_wl_pbmt1,           i_wl_pbmt1;
  wire        g_wl_code0,           i_wl_code0;
  wire        g_wl_code1,           i_wl_code1;
  wire [55:0] g_wl_gpaddr,          i_wl_gpaddr;
  wire        g_wl_vsnonleaf,       i_wl_vsnonleaf;

  `define CONNECT(PFX)                                                          \
    .clock(clk), .reset(rst),                                                   \
    .io_csr_pf_enable(io_csr_pf_enable), .io_flush(io_flush),                   \
    .io_req_ready(PFX``_req_ready), .io_req_valid(io_req_valid),                \
    .io_req_bits_startAddr(io_req_bits_startAddr),                              \
    .io_req_bits_nextlineStart(io_req_bits_nextlineStart),                      \
    .io_req_bits_ftqIdx_flag(io_req_bits_ftqIdx_flag),                          \
    .io_req_bits_ftqIdx_value(io_req_bits_ftqIdx_value),                        \
    .io_req_bits_isSoftPrefetch(io_req_bits_isSoftPrefetch),                    \
    .io_req_bits_backendException(io_req_bits_backendException),                \
    .io_flushFromBpu_s2_valid(io_flushFromBpu_s2_valid),                        \
    .io_flushFromBpu_s2_bits_flag(io_flushFromBpu_s2_bits_flag),                \
    .io_flushFromBpu_s2_bits_value(io_flushFromBpu_s2_bits_value),              \
    .io_flushFromBpu_s3_valid(io_flushFromBpu_s3_valid),                        \
    .io_flushFromBpu_s3_bits_flag(io_flushFromBpu_s3_bits_flag),                \
    .io_flushFromBpu_s3_bits_value(io_flushFromBpu_s3_bits_value),              \
    .io_itlb_0_req_valid(PFX``_itlb0_valid),                                    \
    .io_itlb_0_req_bits_vaddr(PFX``_itlb0_vaddr),                               \
    .io_itlb_0_resp_bits_paddr_0(io_itlb_resp_paddr[0]),                        \
    .io_itlb_0_resp_bits_gpaddr_0(io_itlb_resp_gpaddr[0]),                      \
    .io_itlb_0_resp_bits_pbmt_0(io_itlb_resp_pbmt[0]),                          \
    .io_itlb_0_resp_bits_miss(io_itlb_resp_miss[0]),                            \
    .io_itlb_0_resp_bits_isForVSnonLeafPTE(io_itlb_resp_vsnonleaf[0]),          \
    .io_itlb_0_resp_bits_excp_0_gpf_instr(io_itlb_resp_gpf[0]),                 \
    .io_itlb_0_resp_bits_excp_0_pf_instr(io_itlb_resp_pf[0]),                   \
    .io_itlb_0_resp_bits_excp_0_af_instr(io_itlb_resp_af[0]),                   \
    .io_itlb_1_req_valid(PFX``_itlb1_valid),                                    \
    .io_itlb_1_req_bits_vaddr(PFX``_itlb1_vaddr),                               \
    .io_itlb_1_resp_bits_paddr_0(io_itlb_resp_paddr[1]),                        \
    .io_itlb_1_resp_bits_gpaddr_0(io_itlb_resp_gpaddr[1]),                      \
    .io_itlb_1_resp_bits_pbmt_0(io_itlb_resp_pbmt[1]),                          \
    .io_itlb_1_resp_bits_miss(io_itlb_resp_miss[1]),                            \
    .io_itlb_1_resp_bits_isForVSnonLeafPTE(io_itlb_resp_vsnonleaf[1]),          \
    .io_itlb_1_resp_bits_excp_0_gpf_instr(io_itlb_resp_gpf[1]),                 \
    .io_itlb_1_resp_bits_excp_0_pf_instr(io_itlb_resp_pf[1]),                   \
    .io_itlb_1_resp_bits_excp_0_af_instr(io_itlb_resp_af[1]),                   \
    .io_itlbFlushPipe(PFX``_itlbFlushPipe),                                     \
    .io_pmp_0_req_valid(PFX``_pmp0_valid), .io_pmp_0_req_bits_addr(PFX``_pmp0_addr), \
    .io_pmp_0_resp_instr(io_pmp_resp_instr[0]), .io_pmp_0_resp_mmio(io_pmp_resp_mmio[0]), \
    .io_pmp_1_req_valid(PFX``_pmp1_valid), .io_pmp_1_req_bits_addr(PFX``_pmp1_addr), \
    .io_pmp_1_resp_instr(io_pmp_resp_instr[1]), .io_pmp_1_resp_mmio(io_pmp_resp_mmio[1]), \
    .io_metaRead_toIMeta_ready(io_metaRead_toIMeta_ready),                      \
    .io_metaRead_toIMeta_valid(PFX``_meta_valid),                               \
    .io_metaRead_toIMeta_bits_vSetIdx_0(PFX``_meta_vset0),                      \
    .io_metaRead_toIMeta_bits_vSetIdx_1(PFX``_meta_vset1),                      \
    .io_metaRead_toIMeta_bits_isDoubleLine(PFX``_meta_double),                  \
    .io_metaRead_fromIMeta_metas_0_0_tag(io_meta_tag[0][0]),                    \
    .io_metaRead_fromIMeta_metas_0_1_tag(io_meta_tag[0][1]),                    \
    .io_metaRead_fromIMeta_metas_0_2_tag(io_meta_tag[0][2]),                    \
    .io_metaRead_fromIMeta_metas_0_3_tag(io_meta_tag[0][3]),                    \
    .io_metaRead_fromIMeta_metas_1_0_tag(io_meta_tag[1][0]),                    \
    .io_metaRead_fromIMeta_metas_1_1_tag(io_meta_tag[1][1]),                    \
    .io_metaRead_fromIMeta_metas_1_2_tag(io_meta_tag[1][2]),                    \
    .io_metaRead_fromIMeta_metas_1_3_tag(io_meta_tag[1][3]),                    \
    .io_metaRead_fromIMeta_codes_0_0(io_meta_code[0][0]),                       \
    .io_metaRead_fromIMeta_codes_0_1(io_meta_code[0][1]),                       \
    .io_metaRead_fromIMeta_codes_0_2(io_meta_code[0][2]),                       \
    .io_metaRead_fromIMeta_codes_0_3(io_meta_code[0][3]),                       \
    .io_metaRead_fromIMeta_codes_1_0(io_meta_code[1][0]),                       \
    .io_metaRead_fromIMeta_codes_1_1(io_meta_code[1][1]),                       \
    .io_metaRead_fromIMeta_codes_1_2(io_meta_code[1][2]),                       \
    .io_metaRead_fromIMeta_codes_1_3(io_meta_code[1][3]),                       \
    .io_metaRead_fromIMeta_entryValid_0_0(io_meta_valid[0][0]),                 \
    .io_metaRead_fromIMeta_entryValid_0_1(io_meta_valid[0][1]),                 \
    .io_metaRead_fromIMeta_entryValid_0_2(io_meta_valid[0][2]),                 \
    .io_metaRead_fromIMeta_entryValid_0_3(io_meta_valid[0][3]),                 \
    .io_metaRead_fromIMeta_entryValid_1_0(io_meta_valid[1][0]),                 \
    .io_metaRead_fromIMeta_entryValid_1_1(io_meta_valid[1][1]),                 \
    .io_metaRead_fromIMeta_entryValid_1_2(io_meta_valid[1][2]),                 \
    .io_metaRead_fromIMeta_entryValid_1_3(io_meta_valid[1][3]),                 \
    .io_MSHRReq_ready(io_MSHRReq_ready), .io_MSHRReq_valid(PFX``_mshr_valid),  \
    .io_MSHRReq_bits_blkPaddr(PFX``_mshr_blkPaddr),                             \
    .io_MSHRReq_bits_vSetIdx(PFX``_mshr_vSetIdx),                               \
    .io_MSHRResp_valid(io_MSHRResp_valid),                                      \
    .io_MSHRResp_bits_blkPaddr(io_MSHRResp_bits_blkPaddr),                      \
    .io_MSHRResp_bits_vSetIdx(io_MSHRResp_bits_vSetIdx),                        \
    .io_MSHRResp_bits_waymask(io_MSHRResp_bits_waymask),                        \
    .io_MSHRResp_bits_corrupt(io_MSHRResp_bits_corrupt),                        \
    .io_wayLookupWrite_ready(io_wayLookupWrite_ready),                          \
    .io_wayLookupWrite_valid(PFX``_wl_valid),                                   \
    .io_wayLookupWrite_bits_entry_vSetIdx_0(PFX``_wl_vset0),                    \
    .io_wayLookupWrite_bits_entry_vSetIdx_1(PFX``_wl_vset1),                    \
    .io_wayLookupWrite_bits_entry_waymask_0(PFX``_wl_way0),                     \
    .io_wayLookupWrite_bits_entry_waymask_1(PFX``_wl_way1),                     \
    .io_wayLookupWrite_bits_entry_ptag_0(PFX``_wl_ptag0),                       \
    .io_wayLookupWrite_bits_entry_ptag_1(PFX``_wl_ptag1),                       \
    .io_wayLookupWrite_bits_entry_itlb_exception_0(PFX``_wl_excp0),             \
    .io_wayLookupWrite_bits_entry_itlb_exception_1(PFX``_wl_excp1),             \
    .io_wayLookupWrite_bits_entry_itlb_pbmt_0(PFX``_wl_pbmt0),                  \
    .io_wayLookupWrite_bits_entry_itlb_pbmt_1(PFX``_wl_pbmt1),                  \
    .io_wayLookupWrite_bits_entry_meta_codes_0(PFX``_wl_code0),                 \
    .io_wayLookupWrite_bits_entry_meta_codes_1(PFX``_wl_code1),                 \
    .io_wayLookupWrite_bits_gpf_gpaddr(PFX``_wl_gpaddr),                        \
    .io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE(PFX``_wl_vsnonleaf)

  IPrefetchPipe    u_g ( `CONNECT(g) );
  IPrefetchPipe_xs u_i ( `CONNECT(i) );

  // ---------------------------------------------------------------------
  // 统计
  // ---------------------------------------------------------------------
  int errors = 0, checks = 0, ncompare = 0, x_skips = 0, cov_fail = 0;

  int cov_state [8];
  int cov_s0_fire = 0, cov_s0_fire_double = 0, cov_s0_fire_soft = 0;
  int cov_bpu_s0_flush = 0, cov_bpu_s1_flush = 0, cov_io_flush_s1 = 0;
  int cov_wait_itlb [2];
  int cov_itlb_resend_after_wait = 0;
  int cov_wl_fire = 0, cov_wl_stall = 0, cov_wl_blocked_by_mshr = 0;
  int cov_wl_excp0 = 0, cov_wl_excp1 = 0, cov_wl_hit0 = 0, cov_wl_hit1 = 0;
  int cov_gpf_port0 = 0, cov_gpf_port1 = 0;
  int cov_mshr_upd_ptag [2];
  int cov_mshr_upd_way  [2];
  int cov_s1_fire_pf_off = 0, cov_s1_real_fire = 0;
  int cov_s2_mshr_match [2];
  int cov_mshr_req_fire [2];
  int cov_mshr_req_stall = 0, cov_s2_stall_s1 = 0;
  int cov_s2_pmp_af = 0, cov_s2_mmio = 0;
  int cov_reset_pulse = 0;

  // ---------------------------------------------------------------------
  // 激励参数
  // ---------------------------------------------------------------------
  localparam int N_TAG = 4;   // 物理 tag 池
  localparam int N_SET = 4;   // 组索引池
  logic [35:0] tag_pool [N_TAG];

  int  rst_cnt   = 0;
  bit  init_done = 0;
  int  pf_hold   = 0;         // csr_pf_enable 成段翻转

  function automatic logic [35:0] pick_tag();
    return tag_pool[$urandom_range(0, N_TAG - 1)];
  endfunction

  function automatic logic [47:0] pick_paddr();
    return {pick_tag(), 4'($urandom_range(0, N_SET - 1)), 8'($urandom())};
  endfunction

  function automatic void clear_inputs();
    io_csr_pf_enable              = 1'b1;
    io_flush                      = 1'b0;
    io_req_valid                  = 1'b0;
    io_req_bits_startAddr         = '0;
    io_req_bits_nextlineStart     = '0;
    io_req_bits_ftqIdx_flag       = 1'b0;
    io_req_bits_ftqIdx_value      = '0;
    io_req_bits_isSoftPrefetch    = 1'b0;
    io_req_bits_backendException  = '0;
    io_flushFromBpu_s2_valid      = 1'b0;
    io_flushFromBpu_s2_bits_flag  = 1'b0;
    io_flushFromBpu_s2_bits_value = '0;
    io_flushFromBpu_s3_valid      = 1'b0;
    io_flushFromBpu_s3_bits_flag  = 1'b0;
    io_flushFromBpu_s3_bits_value = '0;
    for (int p = 0; p < 2; p++) begin
      io_itlb_resp_paddr[p]     = '0;
      io_itlb_resp_gpaddr[p]    = '0;
      io_itlb_resp_pbmt[p]      = '0;
      io_itlb_resp_miss[p]      = 1'b0;
      io_itlb_resp_vsnonleaf[p] = 1'b0;
      io_itlb_resp_gpf[p]       = 1'b0;
      io_itlb_resp_pf[p]        = 1'b0;
      io_itlb_resp_af[p]        = 1'b0;
      io_pmp_resp_instr[p]      = 1'b0;
      io_pmp_resp_mmio[p]       = 1'b0;
      for (int w = 0; w < 4; w++) begin
        io_meta_tag[p][w]   = '0;
        io_meta_code[p][w]  = 1'b0;
        io_meta_valid[p][w] = 1'b0;
      end
    end
    io_metaRead_toIMeta_ready = 1'b0;
    io_MSHRReq_ready          = 1'b0;
    io_MSHRResp_valid         = 1'b0;
    io_MSHRResp_bits_blkPaddr = '0;
    io_MSHRResp_bits_vSetIdx  = '0;
    io_MSHRResp_bits_waymask  = '0;
    io_MSHRResp_bits_corrupt  = 1'b0;
    io_wayLookupWrite_ready   = 1'b0;
  endfunction

  // ---------------------------------------------------------------------
  // 事件计数 + 驱动（读到的都是本拍已稳定的值）
  // ---------------------------------------------------------------------
  logic [49:0] nxt_start;
  int          excp_pick;

  always @(posedge clk) begin
    // ---- 事件计数（golden 内部探针）----
    if (!rst) begin
      cov_state[u_g.state]++;
      if (u_g.s0_fire) begin
        cov_s0_fire++;
        if (io_req_bits_startAddr[5])   cov_s0_fire_double++;
        if (io_req_bits_isSoftPrefetch) cov_s0_fire_soft++;
      end
      if (io_req_valid & u_g.from_bpu_s0_flush_probe) cov_bpu_s0_flush++;
      if (u_g.from_bpu_s1_flush_probe)                cov_bpu_s1_flush++;
      if (io_flush & u_g.s1_valid)                    cov_io_flush_s1++;
      if (u_g.s1_wait_itlb_0) cov_wait_itlb[0]++;
      if (u_g.s1_wait_itlb_1) cov_wait_itlb[1]++;
      if (u_g.s1_wait_itlb_0 & g_itlb0_valid & u_g.s1_need_itlb_0) cov_itlb_resend_after_wait++;
      if (g_wl_valid &  io_wayLookupWrite_ready) begin
        cov_wl_fire++;
        if (g_wl_excp0 != 0) cov_wl_excp0++;
        if (g_wl_excp1 != 0) cov_wl_excp1++;
        if (g_wl_way0  != 0) cov_wl_hit0++;
        if (g_wl_way1  != 0) cov_wl_hit1++;
        if (u_g.s1_itlb_exception_gpf_0)                             cov_gpf_port0++;
        if (~u_g.s1_itlb_exception_gpf_0 & u_g.s1_itlb_exception_gpf_1) cov_gpf_port1++;
      end
      if (g_wl_valid & ~io_wayLookupWrite_ready) cov_wl_stall++;
      if ((u_g.state == 3'h3) & io_MSHRResp_valid & ~u_g.s1_isSoftPrefetch) cov_wl_blocked_by_mshr++;
      if (u_g.s1_valid & u_g._new_info_T   &  u_g.new_info_ptag_same)   cov_mshr_upd_ptag[0]++;
      if (u_g.s1_valid & u_g._new_info_T_1 &  u_g.new_info_ptag_same_1) cov_mshr_upd_ptag[1]++;
      if (u_g.s1_valid & u_g._new_info_T   & ~u_g.new_info_ptag_same   & u_g.new_info_way_same)   cov_mshr_upd_way[0]++;
      if (u_g.s1_valid & u_g._new_info_T_1 & ~u_g.new_info_ptag_same_1 & u_g.new_info_way_same_1) cov_mshr_upd_way[1]++;
      if (u_g.s1_fire & ~io_csr_pf_enable) cov_s1_fire_pf_off++;
      if (u_g.s1_real_fire)                cov_s1_real_fire++;
      if (u_g.s2_MSHR_match_0) cov_s2_mshr_match[0]++;
      if (u_g.s2_MSHR_match_1) cov_s2_mshr_match[1]++;
      if (u_g.toMSHRArbiter.io_in_0_valid & u_g.toMSHRArbiter.io_in_0_ready) cov_mshr_req_fire[0]++;
      if (u_g.toMSHRArbiter.io_in_1_valid & u_g.toMSHRArbiter.io_in_1_ready) cov_mshr_req_fire[1]++;
      if (g_mshr_valid & ~io_MSHRReq_ready) cov_mshr_req_stall++;
      if (u_g.s1_valid & ~u_g.s2_ready)     cov_s2_stall_s1++;
      if (u_g.s2_valid & (u_g.s2_exception_0 == 2'h3) & (u_g.s2_itlb_exception_0 == 2'h0)) cov_s2_pmp_af++;
      if (u_g.s2_valid & u_g.s2_mmio_0)     cov_s2_mmio++;
    end

    // ---- 异步复位脉冲 ----
    if (!init_done) begin
    end
    else if (rst_cnt > 0) begin
      rst_cnt <= rst_cnt - 1;
      rst     <= 1'b1;
    end
    else if ($urandom_range(0, 3999) == 0) begin
      rst_cnt <= 2;
      rst     <= 1'b1;
      cov_reset_pulse++;
    end
    else begin
      rst <= 1'b0;
    end

    // ---- 请求 ----
    nxt_start = {36'($urandom()), 4'b0, 4'($urandom_range(0, N_SET - 1)), 6'($urandom())};
    io_req_valid                 <= ($urandom_range(0, 99) < 60);
    io_req_bits_startAddr        <= nxt_start;
    io_req_bits_nextlineStart    <= ($urandom_range(0, 9) == 0) ? 50'($urandom()) : (nxt_start & ~50'h3f) + 50'd64;
    io_req_bits_ftqIdx_flag      <= $urandom();
    io_req_bits_ftqIdx_value     <= 6'($urandom());
    io_req_bits_isSoftPrefetch   <= ($urandom_range(0, 99) < 12);
    io_req_bits_backendException <= ($urandom_range(0, 99) < 6) ? 2'($urandom_range(1, 3)) : 2'd0;

    io_flushFromBpu_s2_valid      <= ($urandom_range(0, 99) < 6);
    io_flushFromBpu_s2_bits_flag  <= $urandom();
    io_flushFromBpu_s2_bits_value <= 6'($urandom());
    io_flushFromBpu_s3_valid      <= ($urandom_range(0, 99) < 6);
    io_flushFromBpu_s3_bits_flag  <= $urandom();
    io_flushFromBpu_s3_bits_value <= 6'($urandom());
    io_flush                      <= ($urandom_range(0, 999) < 15);

    if (pf_hold > 0) pf_hold <= pf_hold - 1;
    else begin
      pf_hold          <= $urandom_range(20, 300);
      io_csr_pf_enable <= ($urandom_range(0, 99) < 80);
    end

    // ---- iTLB / PMP 回应 ----
    for (int p = 0; p < 2; p++) begin
      io_itlb_resp_paddr[p]     <= pick_paddr();
      io_itlb_resp_gpaddr[p]    <= {$urandom(), $urandom()};
      io_itlb_resp_pbmt[p]      <= ($urandom_range(0, 99) < 80) ? 2'd0 : 2'($urandom_range(1, 3));
      io_itlb_resp_miss[p]      <= ($urandom_range(0, 99) < 25);
      io_itlb_resp_vsnonleaf[p] <= $urandom();
      excp_pick = $urandom_range(0, 99);
      io_itlb_resp_pf[p]  <= (excp_pick < 4);
      io_itlb_resp_gpf[p] <= (excp_pick >= 4 && excp_pick < 12);
      io_itlb_resp_af[p]  <= (excp_pick >= 12 && excp_pick < 16);
      io_pmp_resp_instr[p] <= ($urandom_range(0, 99) < 6);
      io_pmp_resp_mmio[p]  <= ($urandom_range(0, 99) < 6);
    end

    // ---- meta SRAM 回应：tag 从池里抽，entryValid 70% ----
    io_metaRead_toIMeta_ready <= ($urandom_range(0, 99) < 85);
    for (int p = 0; p < 2; p++)
      for (int w = 0; w < 4; w++) begin
        io_meta_tag[p][w]   <= pick_tag();
        io_meta_code[p][w]  <= $urandom();
        io_meta_valid[p][w] <= ($urandom_range(0, 99) < 70);
      end

    // ---- MissUnit ----
    io_MSHRReq_ready          <= ($urandom_range(0, 99) < 70);
    io_MSHRResp_valid         <= ($urandom_range(0, 99) < 15);
    io_MSHRResp_bits_blkPaddr <= {pick_tag(), 2'b0, 4'($urandom_range(0, N_SET - 1))};
    io_MSHRResp_bits_vSetIdx  <= 8'($urandom_range(0, N_SET - 1));
    io_MSHRResp_bits_waymask  <= ($urandom_range(0, 9) == 0) ? 4'($urandom()) : 4'(1 << $urandom_range(0, 3));
    io_MSHRResp_bits_corrupt  <= ($urandom_range(0, 99) < 5);

    io_wayLookupWrite_ready   <= ($urandom_range(0, 99) < 80);
  end

  // ---------------------------------------------------------------------
  // 逐拍比对：32 个输出端口，每拍每口一次。X 守卫存在但必须永不触发。
  // ---------------------------------------------------------------------
  `define CMP(NAME, G, I)                                                      \
    if ($isunknown(G) || $isunknown(I)) x_skips++;                             \
    else begin                                                                 \
      checks++;                                                                \
      if ((G) !== (I)) begin                                                   \
        errors++;                                                              \
        if (errors <= 30)                                                      \
          $display("[%0t] %s  g=%h  i=%h", $time, NAME, G, I);                 \
      end                                                                      \
    end

  always @(negedge clk) if (!rst) begin
    #4;
    ncompare++;
    `CMP("io_req_ready",                       g_req_ready,     i_req_ready)
    `CMP("io_itlb_0_req_valid",                g_itlb0_valid,   i_itlb0_valid)
    `CMP("io_itlb_0_req_bits_vaddr",           g_itlb0_vaddr,   i_itlb0_vaddr)
    `CMP("io_itlb_1_req_valid",                g_itlb1_valid,   i_itlb1_valid)
    `CMP("io_itlb_1_req_bits_vaddr",           g_itlb1_vaddr,   i_itlb1_vaddr)
    `CMP("io_itlbFlushPipe",                   g_itlbFlushPipe, i_itlbFlushPipe)
    `CMP("io_pmp_0_req_valid",                 g_pmp0_valid,    i_pmp0_valid)
    `CMP("io_pmp_0_req_bits_addr",             g_pmp0_addr,     i_pmp0_addr)
    `CMP("io_pmp_1_req_valid",                 g_pmp1_valid,    i_pmp1_valid)
    `CMP("io_pmp_1_req_bits_addr",             g_pmp1_addr,     i_pmp1_addr)
    `CMP("io_metaRead_toIMeta_valid",          g_meta_valid,    i_meta_valid)
    `CMP("io_metaRead_toIMeta_bits_vSetIdx_0", g_meta_vset0,    i_meta_vset0)
    `CMP("io_metaRead_toIMeta_bits_vSetIdx_1", g_meta_vset1,    i_meta_vset1)
    `CMP("io_metaRead_toIMeta_bits_isDoubleLine", g_meta_double, i_meta_double)
    `CMP("io_MSHRReq_valid",                   g_mshr_valid,    i_mshr_valid)
    `CMP("io_MSHRReq_bits_blkPaddr",           g_mshr_blkPaddr, i_mshr_blkPaddr)
    `CMP("io_MSHRReq_bits_vSetIdx",            g_mshr_vSetIdx,  i_mshr_vSetIdx)
    `CMP("io_wayLookupWrite_valid",            g_wl_valid,      i_wl_valid)
    `CMP("io_wayLookupWrite_bits_entry_vSetIdx_0",        g_wl_vset0, i_wl_vset0)
    `CMP("io_wayLookupWrite_bits_entry_vSetIdx_1",        g_wl_vset1, i_wl_vset1)
    `CMP("io_wayLookupWrite_bits_entry_waymask_0",        g_wl_way0,  i_wl_way0)
    `CMP("io_wayLookupWrite_bits_entry_waymask_1",        g_wl_way1,  i_wl_way1)
    `CMP("io_wayLookupWrite_bits_entry_ptag_0",           g_wl_ptag0, i_wl_ptag0)
    `CMP("io_wayLookupWrite_bits_entry_ptag_1",           g_wl_ptag1, i_wl_ptag1)
    `CMP("io_wayLookupWrite_bits_entry_itlb_exception_0", g_wl_excp0, i_wl_excp0)
    `CMP("io_wayLookupWrite_bits_entry_itlb_exception_1", g_wl_excp1, i_wl_excp1)
    `CMP("io_wayLookupWrite_bits_entry_itlb_pbmt_0",      g_wl_pbmt0, i_wl_pbmt0)
    `CMP("io_wayLookupWrite_bits_entry_itlb_pbmt_1",      g_wl_pbmt1, i_wl_pbmt1)
    `CMP("io_wayLookupWrite_bits_entry_meta_codes_0",     g_wl_code0, i_wl_code0)
    `CMP("io_wayLookupWrite_bits_entry_meta_codes_1",     g_wl_code1, i_wl_code1)
    `CMP("io_wayLookupWrite_bits_gpf_gpaddr",             g_wl_gpaddr, i_wl_gpaddr)
    `CMP("io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE",  g_wl_vsnonleaf, i_wl_vsnonleaf)
  end

  // ---------------------------------------------------------------------
  // 收尾：覆盖闸
  // ---------------------------------------------------------------------
  function automatic int cov_chk(string name, int v, int lim);
    if (v < lim) begin
      $display("  [COV FAIL] %-32s = %0d  (< %0d)", name, v, lim);
      return 1;
    end
    return 0;
  endfunction

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));   // ut_common.mk 统一下发 200000
    for (int t = 0; t < N_TAG; t++) tag_pool[t] = {4'($urandom()), 32'($urandom())};
    clear_inputs();
    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;
    init_done = 1'b1;
    repeat (NCYCLES) @(posedge clk);

    $display("checks=%0d errors=%0d ncompare=%0d x_skips=%0d", checks, errors, ncompare, x_skips);
    $display("覆盖：");
    $display("  state: idle=%0d itlbResend=%0d metaResend=%0d enqWay=%0d enterS2=%0d",
             cov_state[0], cov_state[1], cov_state[2], cov_state[3], cov_state[4]);
    $display("  s0_fire=%0d double=%0d soft=%0d  flush: bpu_s0=%0d bpu_s1=%0d io_flush_s1=%0d",
             cov_s0_fire, cov_s0_fire_double, cov_s0_fire_soft, cov_bpu_s0_flush, cov_bpu_s1_flush, cov_io_flush_s1);
    $display("  itlb wait=%p resend_after_wait=%0d", cov_wait_itlb, cov_itlb_resend_after_wait);
    $display("  wayLookup: fire=%0d stall=%0d blocked_by_mshr=%0d excp0=%0d excp1=%0d hit0=%0d hit1=%0d gpf0=%0d gpf1=%0d",
             cov_wl_fire, cov_wl_stall, cov_wl_blocked_by_mshr, cov_wl_excp0, cov_wl_excp1,
             cov_wl_hit0, cov_wl_hit1, cov_gpf_port0, cov_gpf_port1);
    $display("  mshr update: ptag_same=%p way_same=%p   s2 match=%p", cov_mshr_upd_ptag, cov_mshr_upd_way, cov_s2_mshr_match);
    $display("  s1: real_fire=%0d pf_off_drop=%0d s2_stall=%0d   mshr req fire=%p stall=%0d  s2: pmp_af=%0d mmio=%0d",
             cov_s1_real_fire, cov_s1_fire_pf_off, cov_s2_stall_s1, cov_mshr_req_fire, cov_mshr_req_stall,
             cov_s2_pmp_af, cov_s2_mmio);
    $display("  reset_pulse=%0d", cov_reset_pulse);

    if (x_skips != 0) begin
      $display("  [COV FAIL] x_skips = %0d（X 守卫触发过，比对被吃掉）", x_skips);
      cov_fail++;
    end
    if (checks != N_OUT * ncompare) begin
      $display("  [COV FAIL] checks=%0d != %0d 输出 × %0d 拍 = %0d",
               checks, N_OUT, ncompare, N_OUT * ncompare);
      cov_fail++;
    end
    for (int s = 0; s < 5; s++)
      cov_fail += cov_chk($sformatf("state[%0d] dwell", s), cov_state[s], COV_MIN);
    if (cov_state[5] + cov_state[6] + cov_state[7] != 0) begin
      $display("  [COV FAIL] 不可达状态 5~7 出现了 %0d 拍", cov_state[5] + cov_state[6] + cov_state[7]);
      cov_fail++;
    end
    cov_fail += cov_chk("s0 fire",                cov_s0_fire,             COV_MIN);
    cov_fail += cov_chk("s0 fire doubleline",     cov_s0_fire_double,      COV_MIN);
    cov_fail += cov_chk("s0 fire soft prefetch",  cov_s0_fire_soft,        COV_MIN);
    cov_fail += cov_chk("bpu s0 flush",           cov_bpu_s0_flush,        COV_MIN);
    cov_fail += cov_chk("bpu s1 flush",           cov_bpu_s1_flush,        COV_MIN);
    cov_fail += cov_chk("io_flush while s1",      cov_io_flush_s1,         COV_MIN);
    cov_fail += cov_chk("itlb wait port0",        cov_wait_itlb[0],        COV_MIN);
    cov_fail += cov_chk("itlb wait port1",        cov_wait_itlb[1],        COV_MIN);
    cov_fail += cov_chk("itlb resend after wait", cov_itlb_resend_after_wait, COV_MIN);
    cov_fail += cov_chk("wayLookup fire",         cov_wl_fire,             COV_MIN);
    cov_fail += cov_chk("wayLookup stall",        cov_wl_stall,            COV_MIN);
    cov_fail += cov_chk("wayLookup blocked mshr", cov_wl_blocked_by_mshr,  COV_MIN);
    cov_fail += cov_chk("wayLookup excp port0",   cov_wl_excp0,            COV_MIN);
    cov_fail += cov_chk("wayLookup excp port1",   cov_wl_excp1,            COV_MIN);
    cov_fail += cov_chk("wayLookup hit port0",    cov_wl_hit0,             COV_MIN);
    cov_fail += cov_chk("wayLookup hit port1",    cov_wl_hit1,             COV_MIN);
    cov_fail += cov_chk("gpf select port0",       cov_gpf_port0,           COV_MIN);
    cov_fail += cov_chk("gpf select port1",       cov_gpf_port1,           COV_MIN);
    cov_fail += cov_chk("mshr upd ptag_same p0",  cov_mshr_upd_ptag[0],    COV_MIN);
    cov_fail += cov_chk("mshr upd ptag_same p1",  cov_mshr_upd_ptag[1],    COV_MIN);
    cov_fail += cov_chk("mshr upd way_same p0",   cov_mshr_upd_way[0],     COV_MIN);
    cov_fail += cov_chk("mshr upd way_same p1",   cov_mshr_upd_way[1],     COV_MIN);
    cov_fail += cov_chk("s1 real fire",           cov_s1_real_fire,        COV_MIN);
    cov_fail += cov_chk("s1 fire pf_enable=0",    cov_s1_fire_pf_off,      COV_MIN);
    cov_fail += cov_chk("s1 stalled by s2",       cov_s2_stall_s1,         COV_MIN);
    cov_fail += cov_chk("s2 mshr match p0",       cov_s2_mshr_match[0],    COV_MIN);
    cov_fail += cov_chk("s2 mshr match p1",       cov_s2_mshr_match[1],    COV_MIN);
    cov_fail += cov_chk("mshr req fire p0",       cov_mshr_req_fire[0],    COV_MIN);
    cov_fail += cov_chk("mshr req fire p1",       cov_mshr_req_fire[1],    COV_MIN);
    cov_fail += cov_chk("mshr req stall",         cov_mshr_req_stall,      COV_MIN);
    cov_fail += cov_chk("s2 pmp af",              cov_s2_pmp_af,           COV_MIN);
    cov_fail += cov_chk("s2 mmio",                cov_s2_mmio,             COV_MIN);
    cov_fail += cov_chk("async reset pulse",      cov_reset_pulse,         10);

    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%0d cov_fail=%0d)", errors, cov_fail);
    $fatal(1);
  end

endmodule
