// ICacheMainPipe 双例化逐拍比对：golden ICacheMainPipe vs 可读重写 ICacheMainPipe_xs
//
// 两侧例化的是同一份 Arbiter2_ICacheMissReq（RTL_GOLDEN_DEPS 两侧同源），所以本 tb
// 验的是流水本体：s0 的 data SRAM 读请求与 WayLookup 握手、s1 的 SRAM 数据保持 /
// MSHR 回填覆盖 bank / meta ECC / touch / PMP、s2 的 data ECC / 重取 / miss 发射 /
// 回填接收 / L2 corrupt 上报 / 回 IFU / perf / DiffTest 探针打包。
//
// 【激励】所有输入逐拍随机，地址池故意开小（组索引 4 个、物理 tag 4 个）。带一个极简
//   MissUnit 模型：真的发出去的 miss 请求记进队列、稍后按原样回填（s2 要等到回填才能
//   fire，回填也可能落在 s1 监听窗口里），另掺 6% 从池里抽的"别人的"回填。WayLookup 给的
//   waymask 8% 多路命中、meta_codes 15% 故意错，data codes 8% 故意错，配合 ecc_enable
//   成段翻转，把 meta/data 出错 → metaArrayFlush → 重取这条链走透。respStall 20%、
//   mshr_req_ready 70% 让 s2 真的堵住。
//   ★坑（第一版踩到）：always 块里 `logic [35:0] t = pick_tag();` 是**静态**变量，
//   初始化只在 0 时刻执行一次（那时 tag 池还没填），于是所有 ptag 都是同一个 X ——
//   输出成片 X、回填永远配不上。临时量一律用模块级变量 + 阻塞赋值。
//
// 【暖机窗口】golden 的 PMP 结果保持寄存器（s2_pmp_exception_r_* / s2_pmp_mmio_r_*）
//   没有复位，且直接可见于 io_fetch_resp_bits_pmp_mmio_* / io_perfInfo_except_0。
//   +vcs+initreg+random 给两个实例各摇各的初值，在第一次 s1 fire 之前它们必然不同——
//   这与重写无关。所以复位后先用确定性激励让一次命中取指走完 s0→s1→s2（把这些
//   寄存器写定），再打开比对窗口；之后所有无复位寄存器两侧历史相同、值也相同。
//
// 【采样相位】驱动用 posedge 非阻塞，比对在 negedge 后 #4（下一个 posedge 前 1ns）。
//
// 【X 守卫必须一次都不触发】判据不只 errors==0，还要求 checks == N_OUT × 比对拍数
//   且 x_skips==0。
`timescale 1ns/1ps
module tb;

  localparam int N_OUT   = 80;    // golden 输出端口数（比对项数/拍）
  localparam int COV_MIN = 200;
  localparam int WARMUP  = 12;    // 暖机拍数

  int unsigned NCYCLES = 200000;

  bit   clk = 0;
  logic rst;
  always #5 clk = ~clk;

  // ---------------------------------------------------------------------
  // DUT 输入（两侧共用）
  // ---------------------------------------------------------------------
  logic [5:0]   io_hartId;
  logic         io_toIData_3_ready;
  logic [63:0]  io_data          [8];
  logic         io_code          [8];
  logic         io_wl_valid;
  logic [7:0]   io_wl_vset       [2];
  logic [3:0]   io_wl_way        [2];
  logic [35:0]  io_wl_ptag       [2];
  logic [1:0]   io_wl_excp       [2];
  logic [1:0]   io_wl_pbmt       [2];
  logic         io_wl_code       [2];
  logic [55:0]  io_wl_gpaddr;
  logic         io_wl_vsnonleaf;
  logic         io_mshr_req_ready;
  logic         io_mshr_resp_valid;
  logic [41:0]  io_mshr_resp_blkPaddr;
  logic [7:0]   io_mshr_resp_vSetIdx;
  logic [511:0] io_mshr_resp_data;
  logic         io_mshr_resp_corrupt;
  logic         io_ecc_enable;
  logic         io_fetch_req_valid;
  logic [49:0]  io_pc_start      [5];
  logic [49:0]  io_pc_next       [5];
  logic         io_readValid     [5];
  logic         io_backendException;
  logic         io_hasSatpFlush;
  logic         io_flush;
  logic         io_pmp_instr     [2];
  logic         io_pmp_mmio      [2];
  logic         io_respStall;

  // ---------------------------------------------------------------------
  // DUT 输出（g_ = golden, i_ = 重写）
  // ---------------------------------------------------------------------
  wire         g_td0_valid,    i_td0_valid;
  wire [7:0]   g_td0_vset0,    i_td0_vset0;
  wire [7:0]   g_td0_vset1,    i_td0_vset1;
  wire         g_td0_w00, i_td0_w00, g_td0_w01, i_td0_w01, g_td0_w02, i_td0_w02, g_td0_w03, i_td0_w03;
  wire         g_td0_w10, i_td0_w10, g_td0_w11, i_td0_w11, g_td0_w12, i_td0_w12, g_td0_w13, i_td0_w13;
  wire [5:0]   g_td0_off,      i_td0_off;
  wire         g_td1_valid,    i_td1_valid;
  wire [7:0]   g_td1_vset0,    i_td1_vset0;
  wire [7:0]   g_td1_vset1,    i_td1_vset1;
  wire         g_td2_valid,    i_td2_valid;
  wire [7:0]   g_td2_vset0,    i_td2_vset0;
  wire [7:0]   g_td2_vset1,    i_td2_vset1;
  wire         g_td3_valid,    i_td3_valid;
  wire [7:0]   g_td3_vset0,    i_td3_vset0;
  wire [7:0]   g_td3_vset1,    i_td3_vset1;
  wire         g_mf0_valid,    i_mf0_valid;
  wire [7:0]   g_mf0_idx,      i_mf0_idx;
  wire [3:0]   g_mf0_way,      i_mf0_way;
  wire         g_mf1_valid,    i_mf1_valid;
  wire [7:0]   g_mf1_idx,      i_mf1_idx;
  wire [3:0]   g_mf1_way,      i_mf1_way;
  wire         g_t0_valid,     i_t0_valid;
  wire [7:0]   g_t0_vset,      i_t0_vset;
  wire [1:0]   g_t0_way,       i_t0_way;
  wire         g_t1_valid,     i_t1_valid;
  wire [7:0]   g_t1_vset,      i_t1_vset;
  wire [1:0]   g_t1_way,       i_t1_way;
  wire         g_wl_ready,     i_wl_ready;
  wire         g_mreq_valid,   i_mreq_valid;
  wire [41:0]  g_mreq_blk,     i_mreq_blk;
  wire [7:0]   g_mreq_vset,    i_mreq_vset;
  wire         g_freq_ready,   i_freq_ready;
  wire         g_fr_valid,     i_fr_valid;
  wire         g_fr_double,    i_fr_double;
  wire [49:0]  g_fr_vaddr0,    i_fr_vaddr0;
  wire [49:0]  g_fr_vaddr1,    i_fr_vaddr1;
  wire [511:0] g_fr_data,      i_fr_data;
  wire [47:0]  g_fr_paddr0,    i_fr_paddr0;
  wire [1:0]   g_fr_excp0,     i_fr_excp0;
  wire [1:0]   g_fr_excp1,     i_fr_excp1;
  wire         g_fr_mmio0,     i_fr_mmio0;
  wire         g_fr_mmio1,     i_fr_mmio1;
  wire [1:0]   g_fr_pbmt0,     i_fr_pbmt0;
  wire [1:0]   g_fr_pbmt1,     i_fr_pbmt1;
  wire         g_fr_bexc,      i_fr_bexc;
  wire         g_fr_satp,      i_fr_satp;
  wire [55:0]  g_fr_gpaddr,    i_fr_gpaddr;
  wire         g_fr_vsnl,      i_fr_vsnl;
  wire         g_td_icmiss,    i_td_icmiss;
  wire         g_td_tlbmiss,   i_td_tlbmiss;
  wire         g_pmp0_valid,   i_pmp0_valid;
  wire [47:0]  g_pmp0_addr,    i_pmp0_addr;
  wire         g_pmp1_valid,   i_pmp1_valid;
  wire [47:0]  g_pmp1_addr,    i_pmp1_addr;
  wire         g_err0_valid,   i_err0_valid;
  wire [47:0]  g_err0_paddr,   i_err0_paddr;
  wire         g_err0_beu,     i_err0_beu;
  wire         g_err1_valid,   i_err1_valid;
  wire [47:0]  g_err1_paddr,   i_err1_paddr;
  wire         g_err1_beu,     i_err1_beu;
  wire         g_pf_o0h, i_pf_o0h, g_pf_o0m, i_pf_o0m, g_pf_h0h1, i_pf_h0h1, g_pf_h0m1, i_pf_h0m1;
  wire         g_pf_m0h1, i_pf_m0h1, g_pf_m0m1, i_pf_m0m1, g_pf_h0e1, i_pf_h0e1, g_pf_m0e1, i_pf_m0e1;
  wire         g_pf_e0, i_pf_e0, g_pf_bh0, i_pf_bh0, g_pf_bh1, i_pf_bh1, g_pf_hit, i_pf_hit;
  wire [600:0] g_bore0,        i_bore0;
  wire [600:0] g_bore1,        i_bore1;

  `define CONNECT(PFX)                                                                    \
    .clock(clk), .reset(rst), .io_hartId(io_hartId),                                      \
    .io_dataArray_toIData_0_valid(PFX``_td0_valid),                                       \
    .io_dataArray_toIData_0_bits_vSetIdx_0(PFX``_td0_vset0),                              \
    .io_dataArray_toIData_0_bits_vSetIdx_1(PFX``_td0_vset1),                              \
    .io_dataArray_toIData_0_bits_waymask_0_0(PFX``_td0_w00),                              \
    .io_dataArray_toIData_0_bits_waymask_0_1(PFX``_td0_w01),                              \
    .io_dataArray_toIData_0_bits_waymask_0_2(PFX``_td0_w02),                              \
    .io_dataArray_toIData_0_bits_waymask_0_3(PFX``_td0_w03),                              \
    .io_dataArray_toIData_0_bits_waymask_1_0(PFX``_td0_w10),                              \
    .io_dataArray_toIData_0_bits_waymask_1_1(PFX``_td0_w11),                              \
    .io_dataArray_toIData_0_bits_waymask_1_2(PFX``_td0_w12),                              \
    .io_dataArray_toIData_0_bits_waymask_1_3(PFX``_td0_w13),                              \
    .io_dataArray_toIData_0_bits_blkOffset(PFX``_td0_off),                                \
    .io_dataArray_toIData_1_valid(PFX``_td1_valid),                                       \
    .io_dataArray_toIData_1_bits_vSetIdx_0(PFX``_td1_vset0),                              \
    .io_dataArray_toIData_1_bits_vSetIdx_1(PFX``_td1_vset1),                              \
    .io_dataArray_toIData_2_valid(PFX``_td2_valid),                                       \
    .io_dataArray_toIData_2_bits_vSetIdx_0(PFX``_td2_vset0),                              \
    .io_dataArray_toIData_2_bits_vSetIdx_1(PFX``_td2_vset1),                              \
    .io_dataArray_toIData_3_ready(io_toIData_3_ready),                                    \
    .io_dataArray_toIData_3_valid(PFX``_td3_valid),                                       \
    .io_dataArray_toIData_3_bits_vSetIdx_0(PFX``_td3_vset0),                              \
    .io_dataArray_toIData_3_bits_vSetIdx_1(PFX``_td3_vset1),                              \
    .io_dataArray_fromIData_datas_0(io_data[0]), .io_dataArray_fromIData_datas_1(io_data[1]), \
    .io_dataArray_fromIData_datas_2(io_data[2]), .io_dataArray_fromIData_datas_3(io_data[3]), \
    .io_dataArray_fromIData_datas_4(io_data[4]), .io_dataArray_fromIData_datas_5(io_data[5]), \
    .io_dataArray_fromIData_datas_6(io_data[6]), .io_dataArray_fromIData_datas_7(io_data[7]), \
    .io_dataArray_fromIData_codes_0(io_code[0]), .io_dataArray_fromIData_codes_1(io_code[1]), \
    .io_dataArray_fromIData_codes_2(io_code[2]), .io_dataArray_fromIData_codes_3(io_code[3]), \
    .io_dataArray_fromIData_codes_4(io_code[4]), .io_dataArray_fromIData_codes_5(io_code[5]), \
    .io_dataArray_fromIData_codes_6(io_code[6]), .io_dataArray_fromIData_codes_7(io_code[7]), \
    .io_metaArrayFlush_0_valid(PFX``_mf0_valid),                                          \
    .io_metaArrayFlush_0_bits_virIdx(PFX``_mf0_idx),                                      \
    .io_metaArrayFlush_0_bits_waymask(PFX``_mf0_way),                                     \
    .io_metaArrayFlush_1_valid(PFX``_mf1_valid),                                          \
    .io_metaArrayFlush_1_bits_virIdx(PFX``_mf1_idx),                                      \
    .io_metaArrayFlush_1_bits_waymask(PFX``_mf1_way),                                     \
    .io_touch_0_valid(PFX``_t0_valid), .io_touch_0_bits_vSetIdx(PFX``_t0_vset),           \
    .io_touch_0_bits_way(PFX``_t0_way),                                                   \
    .io_touch_1_valid(PFX``_t1_valid), .io_touch_1_bits_vSetIdx(PFX``_t1_vset),           \
    .io_touch_1_bits_way(PFX``_t1_way),                                                   \
    .io_wayLookupRead_ready(PFX``_wl_ready), .io_wayLookupRead_valid(io_wl_valid),        \
    .io_wayLookupRead_bits_entry_vSetIdx_0(io_wl_vset[0]),                                \
    .io_wayLookupRead_bits_entry_vSetIdx_1(io_wl_vset[1]),                                \
    .io_wayLookupRead_bits_entry_waymask_0(io_wl_way[0]),                                 \
    .io_wayLookupRead_bits_entry_waymask_1(io_wl_way[1]),                                 \
    .io_wayLookupRead_bits_entry_ptag_0(io_wl_ptag[0]),                                   \
    .io_wayLookupRead_bits_entry_ptag_1(io_wl_ptag[1]),                                   \
    .io_wayLookupRead_bits_entry_itlb_exception_0(io_wl_excp[0]),                         \
    .io_wayLookupRead_bits_entry_itlb_exception_1(io_wl_excp[1]),                         \
    .io_wayLookupRead_bits_entry_itlb_pbmt_0(io_wl_pbmt[0]),                              \
    .io_wayLookupRead_bits_entry_itlb_pbmt_1(io_wl_pbmt[1]),                              \
    .io_wayLookupRead_bits_entry_meta_codes_0(io_wl_code[0]),                             \
    .io_wayLookupRead_bits_entry_meta_codes_1(io_wl_code[1]),                             \
    .io_wayLookupRead_bits_gpf_gpaddr(io_wl_gpaddr),                                      \
    .io_wayLookupRead_bits_gpf_isForVSnonLeafPTE(io_wl_vsnonleaf),                        \
    .io_mshr_req_ready(io_mshr_req_ready), .io_mshr_req_valid(PFX``_mreq_valid),          \
    .io_mshr_req_bits_blkPaddr(PFX``_mreq_blk), .io_mshr_req_bits_vSetIdx(PFX``_mreq_vset), \
    .io_mshr_resp_valid(io_mshr_resp_valid),                                              \
    .io_mshr_resp_bits_blkPaddr(io_mshr_resp_blkPaddr),                                   \
    .io_mshr_resp_bits_vSetIdx(io_mshr_resp_vSetIdx),                                     \
    .io_mshr_resp_bits_data(io_mshr_resp_data),                                           \
    .io_mshr_resp_bits_corrupt(io_mshr_resp_corrupt),                                     \
    .io_ecc_enable(io_ecc_enable),                                                        \
    .io_fetch_req_ready(PFX``_freq_ready), .io_fetch_req_valid(io_fetch_req_valid),       \
    .io_fetch_req_bits_pcMemRead_0_startAddr(io_pc_start[0]),                             \
    .io_fetch_req_bits_pcMemRead_0_nextlineStart(io_pc_next[0]),                          \
    .io_fetch_req_bits_pcMemRead_1_startAddr(io_pc_start[1]),                             \
    .io_fetch_req_bits_pcMemRead_1_nextlineStart(io_pc_next[1]),                          \
    .io_fetch_req_bits_pcMemRead_2_startAddr(io_pc_start[2]),                             \
    .io_fetch_req_bits_pcMemRead_2_nextlineStart(io_pc_next[2]),                          \
    .io_fetch_req_bits_pcMemRead_3_startAddr(io_pc_start[3]),                             \
    .io_fetch_req_bits_pcMemRead_3_nextlineStart(io_pc_next[3]),                          \
    .io_fetch_req_bits_pcMemRead_4_startAddr(io_pc_start[4]),                             \
    .io_fetch_req_bits_pcMemRead_4_nextlineStart(io_pc_next[4]),                          \
    .io_fetch_req_bits_readValid_0(io_readValid[0]),                                      \
    .io_fetch_req_bits_readValid_1(io_readValid[1]),                                      \
    .io_fetch_req_bits_readValid_2(io_readValid[2]),                                      \
    .io_fetch_req_bits_readValid_3(io_readValid[3]),                                      \
    .io_fetch_req_bits_readValid_4(io_readValid[4]),                                      \
    .io_fetch_req_bits_backendException(io_backendException),                             \
    .io_fetch_req_bits_hasSatpFlush(io_hasSatpFlush),                                     \
    .io_fetch_resp_valid(PFX``_fr_valid), .io_fetch_resp_bits_doubleline(PFX``_fr_double), \
    .io_fetch_resp_bits_vaddr_0(PFX``_fr_vaddr0), .io_fetch_resp_bits_vaddr_1(PFX``_fr_vaddr1), \
    .io_fetch_resp_bits_data(PFX``_fr_data), .io_fetch_resp_bits_paddr_0(PFX``_fr_paddr0), \
    .io_fetch_resp_bits_exception_0(PFX``_fr_excp0), .io_fetch_resp_bits_exception_1(PFX``_fr_excp1), \
    .io_fetch_resp_bits_pmp_mmio_0(PFX``_fr_mmio0), .io_fetch_resp_bits_pmp_mmio_1(PFX``_fr_mmio1), \
    .io_fetch_resp_bits_itlb_pbmt_0(PFX``_fr_pbmt0), .io_fetch_resp_bits_itlb_pbmt_1(PFX``_fr_pbmt1), \
    .io_fetch_resp_bits_backendException(PFX``_fr_bexc), .io_fetch_resp_bits_hasSatpFlush(PFX``_fr_satp), \
    .io_fetch_resp_bits_gpaddr(PFX``_fr_gpaddr), .io_fetch_resp_bits_isForVSnonLeafPTE(PFX``_fr_vsnl), \
    .io_fetch_topdownIcacheMiss(PFX``_td_icmiss), .io_fetch_topdownItlbMiss(PFX``_td_tlbmiss), \
    .io_flush(io_flush),                                                                  \
    .io_pmp_0_req_valid(PFX``_pmp0_valid), .io_pmp_0_req_bits_addr(PFX``_pmp0_addr),      \
    .io_pmp_0_resp_instr(io_pmp_instr[0]), .io_pmp_0_resp_mmio(io_pmp_mmio[0]),           \
    .io_pmp_1_req_valid(PFX``_pmp1_valid), .io_pmp_1_req_bits_addr(PFX``_pmp1_addr),      \
    .io_pmp_1_resp_instr(io_pmp_instr[1]), .io_pmp_1_resp_mmio(io_pmp_mmio[1]),           \
    .io_respStall(io_respStall),                                                          \
    .io_errors_0_valid(PFX``_err0_valid), .io_errors_0_bits_paddr(PFX``_err0_paddr),      \
    .io_errors_0_bits_report_to_beu(PFX``_err0_beu),                                      \
    .io_errors_1_valid(PFX``_err1_valid), .io_errors_1_bits_paddr(PFX``_err1_paddr),      \
    .io_errors_1_bits_report_to_beu(PFX``_err1_beu),                                      \
    .io_perfInfo_only_0_hit(PFX``_pf_o0h), .io_perfInfo_only_0_miss(PFX``_pf_o0m),        \
    .io_perfInfo_hit_0_hit_1(PFX``_pf_h0h1), .io_perfInfo_hit_0_miss_1(PFX``_pf_h0m1),    \
    .io_perfInfo_miss_0_hit_1(PFX``_pf_m0h1), .io_perfInfo_miss_0_miss_1(PFX``_pf_m0m1),  \
    .io_perfInfo_hit_0_except_1(PFX``_pf_h0e1), .io_perfInfo_miss_0_except_1(PFX``_pf_m0e1), \
    .io_perfInfo_except_0(PFX``_pf_e0), .io_perfInfo_bank_hit_0(PFX``_pf_bh0),            \
    .io_perfInfo_bank_hit_1(PFX``_pf_bh1), .io_perfInfo_hit(PFX``_pf_hit),                \
    .gatewayIn_packed_0_bore(PFX``_bore0), .gatewayIn_packed_1_bore(PFX``_bore1)

  ICacheMainPipe    u_g ( `CONNECT(g) );
  ICacheMainPipe_xs u_i ( `CONNECT(i) );

  // ---------------------------------------------------------------------
  // 统计
  // ---------------------------------------------------------------------
  int errors = 0, checks = 0, ncompare = 0, x_skips = 0, cov_fail = 0;
  bit compare_en = 0;

  int cov_s0_fire = 0, cov_s0_double = 0, cov_s1_fire = 0, cov_s2_fire = 0, cov_s2_fire_double = 0;
  int cov_s0_stall_wl = 0, cov_s0_stall_data = 0, cov_s0_stall_s1 = 0;
  int cov_s1_mshr_hit [2];
  int cov_s2_mshr_hit [2];
  int cov_s2_mshr_hit_corrupt = 0;
  int cov_touch [2];
  int cov_meta_corrupt [2];
  int cov_data_corrupt [2];
  int cov_meta_flush [2];
  int cov_err_ecc [2];
  int cov_err_l2 [2];
  int cov_refetch_after_hit = 0;
  int cov_mshr_req_fire [2];
  int cov_mshr_req_stall = 0;
  int cov_resp_stall = 0, cov_flush_s1 = 0, cov_flush_s2 = 0;
  int cov_excp_out [2];
  int cov_mmio_out [2];
  int cov_l2_af = 0;
  int cov_ecc_off_fire = 0;
  int cov_bank_low [8];
  int cov_reset_pulse = 0;

  // ---------------------------------------------------------------------
  // 激励参数
  // ---------------------------------------------------------------------
  localparam int N_TAG = 4;
  localparam int N_SET = 4;
  logic [35:0] tag_pool [N_TAG];

  int  rst_cnt   = 0;
  bit  init_done = 0;
  int  ecc_hold  = 0;

  function automatic logic [35:0] pick_tag();
    return tag_pool[$urandom_range(0, N_TAG - 1)];
  endfunction

  function automatic logic [49:0] pick_vaddr();
    return {36'($urandom()), 4'b0, 4'($urandom_range(0, N_SET - 1)), 6'($urandom())};
  endfunction

  function automatic logic [3:0] pick_waymask();
    int r = $urandom_range(0, 99);
    if (r < 65) return 4'(1 << $urandom_range(0, 3));   // 单路命中
    if (r < 92) return 4'b0;                             // miss
    return 4'($urandom());                               // 多路（ECC 错的形态）
  endfunction

  function automatic void clear_inputs();
    io_hartId              = '0;
    io_toIData_3_ready     = 1'b0;
    for (int b = 0; b < 8; b++) begin io_data[b] = '0; io_code[b] = 1'b0; end
    io_wl_valid            = 1'b0;
    for (int p = 0; p < 2; p++) begin
      io_wl_vset[p] = '0; io_wl_way[p] = '0; io_wl_ptag[p] = '0;
      io_wl_excp[p] = '0; io_wl_pbmt[p] = '0; io_wl_code[p] = 1'b0;
      io_pmp_instr[p] = 1'b0; io_pmp_mmio[p] = 1'b0;
    end
    io_wl_gpaddr           = '0;
    io_wl_vsnonleaf        = 1'b0;
    io_mshr_req_ready      = 1'b0;
    io_mshr_resp_valid     = 1'b0;
    io_mshr_resp_blkPaddr  = '0;
    io_mshr_resp_vSetIdx   = '0;
    io_mshr_resp_data      = '0;
    io_mshr_resp_corrupt   = 1'b0;
    io_ecc_enable          = 1'b1;
    io_fetch_req_valid     = 1'b0;
    for (int k = 0; k < 5; k++) begin io_pc_start[k] = '0; io_pc_next[k] = '0; io_readValid[k] = 1'b0; end
    io_backendException    = 1'b0;
    io_hasSatpFlush        = 1'b0;
    io_flush               = 1'b0;
    io_respStall           = 1'b0;
  endfunction

  // 暖机：一次必定命中、无例外的单行取指（确定性，让 PMP 保持寄存器被写定）
  function automatic void drive_warmup();
    clear_inputs();
    io_toIData_3_ready = 1'b1;
    io_wl_valid        = 1'b1;
    io_wl_way[0]       = 4'b0001;
    io_wl_way[1]       = 4'b0001;
    io_wl_ptag[0]      = tag_pool[0];
    io_wl_ptag[1]      = tag_pool[0];
    io_wl_code[0]      = ^tag_pool[0];
    io_wl_code[1]      = ^tag_pool[0];
    io_mshr_req_ready  = 1'b1;
    io_fetch_req_valid = 1'b1;
    for (int k = 0; k < 5; k++) begin
      io_pc_start[k]  = 50'h40;    // bit5=0：单行
      io_pc_next[k]   = 50'h80;
      io_readValid[k] = 1'b1;
    end
  endfunction

  // ---------------------------------------------------------------------
  // 事件计数 + 驱动
  // ---------------------------------------------------------------------
  logic [49:0] nxt_start, nxt_next;
  logic [63:0] nxt_data;
  logic [35:0] nxt_tag;
  // 极简 MissUnit 模型：记下真的发出去的 miss 请求，稍后按原样回填（让 s2 真的等到回填、
  // s1/s2 的回填监听都能命中）；另掺少量从池里抽的"别人的"回填。
  typedef struct { logic [41:0] blk; logic [7:0] vset; } pend_t;
  pend_t pend[$];
  int    pick;

  always @(posedge clk) begin
    // ---- 事件计数（golden 内部探针）----
    if (!rst && compare_en) begin
      if (u_g.s0_fire) begin
        cov_s0_fire++;
        if (io_readValid[4] & io_pc_start[4][5]) cov_s0_double++;
      end
      if (io_fetch_req_valid & ~io_wl_valid)                          cov_s0_stall_wl++;
      if (io_fetch_req_valid & io_wl_valid & ~io_toIData_3_ready)     cov_s0_stall_data++;
      if (io_fetch_req_valid & io_wl_valid & io_toIData_3_ready & ~u_g.s1_ready) cov_s0_stall_s1++;
      if (u_g.s1_fire) cov_s1_fire++;
      if (u_g.s2_fire) begin
        cov_s2_fire++;
        if (u_g.s2_doubleline) cov_s2_fire_double++;
        cov_bank_low[u_g.s2_req_vaddr_0[5:3]]++;
        if (~io_ecc_enable) cov_ecc_off_fire++;
        if (g_fr_excp0 != 0) cov_excp_out[0]++;
        if (g_fr_excp1 != 0) cov_excp_out[1]++;
        if (g_fr_mmio0)      cov_mmio_out[0]++;
        if (g_fr_mmio1)      cov_mmio_out[1]++;
        if ((g_fr_excp0 == 2'h3) & (u_g.s2_exception_0 == 2'h0)) cov_l2_af++;
      end
      if (u_g.s1_bankMSHRHit_7) cov_s1_mshr_hit[0]++;
      if (u_g.s1_MSHR_hits_1)   cov_s1_mshr_hit[1]++;
      if (u_g.s2_bankMSHRHit_7) cov_s2_mshr_hit[0]++;
      if (u_g.s2_MSHR_hits_1)   cov_s2_mshr_hit[1]++;
      if (u_g.s2_bankMSHRHit_7 & io_mshr_resp_corrupt) cov_s2_mshr_hit_corrupt++;
      if (g_t0_valid) cov_touch[0]++;
      if (g_t1_valid) cov_touch[1]++;
      if (u_g.s2_meta_corrupt_0 & u_g.REG) cov_meta_corrupt[0]++;
      if (u_g.s2_meta_corrupt_1 & u_g.REG) cov_meta_corrupt[1]++;
      if (u_g.s2_data_corrupt_0 & u_g.REG) cov_data_corrupt[0]++;
      if (u_g.s2_data_corrupt_1 & u_g.REG) cov_data_corrupt[1]++;
      if (g_mf0_valid) cov_meta_flush[0]++;
      if (g_mf1_valid) cov_meta_flush[1]++;
      if (g_err0_valid &  g_err0_beu) cov_err_ecc[0]++;
      if (g_err1_valid &  g_err1_beu) cov_err_ecc[1]++;
      if (g_err0_valid & ~g_err0_beu) cov_err_l2[0]++;
      if (g_err1_valid & ~g_err1_beu) cov_err_l2[1]++;
      if (u_g.s2_valid & u_g.s2_hits_0 & u_g.s2_should_fetch_0) cov_refetch_after_hit++;
      if (u_g.toMSHRArbiter.io_in_0_valid & u_g.toMSHRArbiter.io_in_0_ready) cov_mshr_req_fire[0]++;
      if (u_g.toMSHRArbiter.io_in_1_valid & u_g.toMSHRArbiter.io_in_1_ready) cov_mshr_req_fire[1]++;
      if (g_mreq_valid & ~io_mshr_req_ready) cov_mshr_req_stall++;
      if (u_g.s2_valid & io_respStall & ~u_g._io_fetch_topdownIcacheMiss_T) cov_resp_stall++;
      if (io_flush & u_g.s1_valid) cov_flush_s1++;
      if (io_flush & u_g.s2_valid) cov_flush_s2++;
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
      pend.delete();
      cov_reset_pulse++;
    end
    else begin
      rst <= 1'b0;
    end

    if (init_done) begin
      // ---- FTQ 请求：5 份地址，4 号是本流水用的；0..3 号大多与 4 号相同 ----
      nxt_start = pick_vaddr();
      nxt_next  = ($urandom_range(0, 9) == 0) ? pick_vaddr() : (nxt_start & ~50'h3f) + 50'd64;
      io_fetch_req_valid <= ($urandom_range(0, 99) < 65);
      for (int k = 0; k < 5; k++) begin
        if (k == 4 || $urandom_range(0, 4) != 0) begin
          io_pc_start[k] <= nxt_start;
          io_pc_next[k]  <= nxt_next;
        end
        else begin
          io_pc_start[k] <= pick_vaddr();
          io_pc_next[k]  <= pick_vaddr();
        end
        io_readValid[k] <= ($urandom_range(0, 99) < 85);
      end
      io_backendException <= ($urandom_range(0, 99) < 5);
      io_hasSatpFlush     <= ($urandom_range(0, 99) < 5);
      io_flush            <= ($urandom_range(0, 999) < 15);
      io_respStall        <= ($urandom_range(0, 99) < 20);
      if ($urandom_range(0, 999) == 0) io_hartId <= 6'($urandom());

      // ---- WayLookup 读口 ----
      io_wl_valid <= ($urandom_range(0, 99) < 80);
      for (int p = 0; p < 2; p++) begin
        nxt_tag = pick_tag();
        io_wl_vset[p] <= 8'($urandom_range(0, N_SET - 1));
        io_wl_way[p]  <= pick_waymask();
        io_wl_ptag[p] <= nxt_tag;
        io_wl_code[p] <= ($urandom_range(0, 99) < 85) ? ^nxt_tag : ~^nxt_tag;   // 15% 奇偶故意错
        io_wl_excp[p] <= ($urandom_range(0, 99) < 10) ? 2'($urandom_range(1, 3)) : 2'd0;
        io_wl_pbmt[p] <= ($urandom_range(0, 99) < 85) ? 2'd0 : 2'($urandom_range(1, 3));
      end
      io_wl_gpaddr    <= {24'($urandom()), $urandom()};
      io_wl_vsnonleaf <= $urandom();

      // ---- data SRAM 回应 ----
      io_toIData_3_ready <= ($urandom_range(0, 99) < 85);
      for (int b = 0; b < 8; b++) begin
        nxt_data = {$urandom(), $urandom()};
        io_data[b] <= nxt_data;
        io_code[b] <= ($urandom_range(0, 99) < 92) ? ^nxt_data : ~^nxt_data;   // 8% 奇偶故意错
      end

      // ---- MissUnit 模型：记下本拍握手成功的请求；随机回填在途的一条，或掺一条池里的 ----
      if (!rst && g_mreq_valid && io_mshr_req_ready)
        pend.push_back('{blk: g_mreq_blk, vset: g_mreq_vset});
      io_mshr_req_ready     <= ($urandom_range(0, 99) < 70);
      io_mshr_resp_data     <= {$urandom(), $urandom(), $urandom(), $urandom(),
                                $urandom(), $urandom(), $urandom(), $urandom(),
                                $urandom(), $urandom(), $urandom(), $urandom(),
                                $urandom(), $urandom(), $urandom(), $urandom()};
      io_mshr_resp_corrupt  <= ($urandom_range(0, 99) < 8);
      if (pend.size() != 0 && $urandom_range(0, 99) < 35) begin
        pick = $urandom_range(0, pend.size() - 1);
        io_mshr_resp_valid    <= 1'b1;
        io_mshr_resp_blkPaddr <= pend[pick].blk;
        io_mshr_resp_vSetIdx  <= pend[pick].vset;
        pend.delete(pick);
      end
      else if ($urandom_range(0, 99) < 6) begin
        io_mshr_resp_valid    <= 1'b1;
        io_mshr_resp_blkPaddr <= {pick_tag(), 6'($urandom())};
        io_mshr_resp_vSetIdx  <= 8'($urandom_range(0, N_SET - 1));
      end
      else begin
        io_mshr_resp_valid    <= 1'b0;
      end

      // ---- PMP / ECC 开关（成段翻转）----
      for (int p = 0; p < 2; p++) begin
        io_pmp_instr[p] <= ($urandom_range(0, 99) < 6);
        io_pmp_mmio[p]  <= ($urandom_range(0, 99) < 8);
      end
      if (ecc_hold > 0) ecc_hold <= ecc_hold - 1;
      else begin
        ecc_hold      <= $urandom_range(50, 400);
        io_ecc_enable <= ($urandom_range(0, 99) < 75);
      end
    end
  end

  // ---------------------------------------------------------------------
  // 逐拍比对：80 个输出端口，每拍每口一次。X 守卫存在但必须永不触发。
  // ---------------------------------------------------------------------
  `define CMP(NAME, G, I)                                                      \
    if ($isunknown(G) || $isunknown(I)) begin                                  \
      x_skips++;                                                               \
      if (x_skips <= 20) $display("[%0t] X-SKIP %s  g=%h  i=%h", $time, NAME, G, I); \
    end                                                                        \
    else begin                                                                 \
      checks++;                                                                \
      if ((G) !== (I)) begin                                                   \
        errors++;                                                              \
        if (errors <= 30)                                                      \
          $display("[%0t] %s  g=%h  i=%h", $time, NAME, G, I);                 \
      end                                                                      \
    end

  always @(negedge clk) if (!rst && compare_en) begin
    #4;
    ncompare++;
    `CMP("toIData_0_valid",        g_td0_valid, i_td0_valid)
    `CMP("toIData_0_vSetIdx_0",    g_td0_vset0, i_td0_vset0)
    `CMP("toIData_0_vSetIdx_1",    g_td0_vset1, i_td0_vset1)
    `CMP("toIData_0_waymask_0_0",  g_td0_w00, i_td0_w00)
    `CMP("toIData_0_waymask_0_1",  g_td0_w01, i_td0_w01)
    `CMP("toIData_0_waymask_0_2",  g_td0_w02, i_td0_w02)
    `CMP("toIData_0_waymask_0_3",  g_td0_w03, i_td0_w03)
    `CMP("toIData_0_waymask_1_0",  g_td0_w10, i_td0_w10)
    `CMP("toIData_0_waymask_1_1",  g_td0_w11, i_td0_w11)
    `CMP("toIData_0_waymask_1_2",  g_td0_w12, i_td0_w12)
    `CMP("toIData_0_waymask_1_3",  g_td0_w13, i_td0_w13)
    `CMP("toIData_0_blkOffset",    g_td0_off, i_td0_off)
    `CMP("toIData_1_valid",        g_td1_valid, i_td1_valid)
    `CMP("toIData_1_vSetIdx_0",    g_td1_vset0, i_td1_vset0)
    `CMP("toIData_1_vSetIdx_1",    g_td1_vset1, i_td1_vset1)
    `CMP("toIData_2_valid",        g_td2_valid, i_td2_valid)
    `CMP("toIData_2_vSetIdx_0",    g_td2_vset0, i_td2_vset0)
    `CMP("toIData_2_vSetIdx_1",    g_td2_vset1, i_td2_vset1)
    `CMP("toIData_3_valid",        g_td3_valid, i_td3_valid)
    `CMP("toIData_3_vSetIdx_0",    g_td3_vset0, i_td3_vset0)
    `CMP("toIData_3_vSetIdx_1",    g_td3_vset1, i_td3_vset1)
    `CMP("metaArrayFlush_0_valid", g_mf0_valid, i_mf0_valid)
    `CMP("metaArrayFlush_0_virIdx", g_mf0_idx, i_mf0_idx)
    `CMP("metaArrayFlush_0_waymask", g_mf0_way, i_mf0_way)
    `CMP("metaArrayFlush_1_valid", g_mf1_valid, i_mf1_valid)
    `CMP("metaArrayFlush_1_virIdx", g_mf1_idx, i_mf1_idx)
    `CMP("metaArrayFlush_1_waymask", g_mf1_way, i_mf1_way)
    `CMP("touch_0_valid",          g_t0_valid, i_t0_valid)
    `CMP("touch_0_vSetIdx",        g_t0_vset, i_t0_vset)
    `CMP("touch_0_way",            g_t0_way, i_t0_way)
    `CMP("touch_1_valid",          g_t1_valid, i_t1_valid)
    `CMP("touch_1_vSetIdx",        g_t1_vset, i_t1_vset)
    `CMP("touch_1_way",            g_t1_way, i_t1_way)
    `CMP("wayLookupRead_ready",    g_wl_ready, i_wl_ready)
    `CMP("mshr_req_valid",         g_mreq_valid, i_mreq_valid)
    `CMP("mshr_req_blkPaddr",      g_mreq_blk, i_mreq_blk)
    `CMP("mshr_req_vSetIdx",       g_mreq_vset, i_mreq_vset)
    `CMP("fetch_req_ready",        g_freq_ready, i_freq_ready)
    `CMP("fetch_resp_valid",       g_fr_valid, i_fr_valid)
    `CMP("fetch_resp_doubleline",  g_fr_double, i_fr_double)
    `CMP("fetch_resp_vaddr_0",     g_fr_vaddr0, i_fr_vaddr0)
    `CMP("fetch_resp_vaddr_1",     g_fr_vaddr1, i_fr_vaddr1)
    `CMP("fetch_resp_data",        g_fr_data, i_fr_data)
    `CMP("fetch_resp_paddr_0",     g_fr_paddr0, i_fr_paddr0)
    `CMP("fetch_resp_exception_0", g_fr_excp0, i_fr_excp0)
    `CMP("fetch_resp_exception_1", g_fr_excp1, i_fr_excp1)
    `CMP("fetch_resp_pmp_mmio_0",  g_fr_mmio0, i_fr_mmio0)
    `CMP("fetch_resp_pmp_mmio_1",  g_fr_mmio1, i_fr_mmio1)
    `CMP("fetch_resp_itlb_pbmt_0", g_fr_pbmt0, i_fr_pbmt0)
    `CMP("fetch_resp_itlb_pbmt_1", g_fr_pbmt1, i_fr_pbmt1)
    `CMP("fetch_resp_backendException", g_fr_bexc, i_fr_bexc)
    `CMP("fetch_resp_hasSatpFlush", g_fr_satp, i_fr_satp)
    `CMP("fetch_resp_gpaddr",      g_fr_gpaddr, i_fr_gpaddr)
    `CMP("fetch_resp_isForVSnonLeafPTE", g_fr_vsnl, i_fr_vsnl)
    `CMP("topdownIcacheMiss",      g_td_icmiss, i_td_icmiss)
    `CMP("topdownItlbMiss",        g_td_tlbmiss, i_td_tlbmiss)
    `CMP("pmp_0_req_valid",        g_pmp0_valid, i_pmp0_valid)
    `CMP("pmp_0_req_addr",         g_pmp0_addr, i_pmp0_addr)
    `CMP("pmp_1_req_valid",        g_pmp1_valid, i_pmp1_valid)
    `CMP("pmp_1_req_addr",         g_pmp1_addr, i_pmp1_addr)
    `CMP("errors_0_valid",         g_err0_valid, i_err0_valid)
    `CMP("errors_0_paddr",         g_err0_paddr, i_err0_paddr)
    `CMP("errors_0_report_to_beu", g_err0_beu, i_err0_beu)
    `CMP("errors_1_valid",         g_err1_valid, i_err1_valid)
    `CMP("errors_1_paddr",         g_err1_paddr, i_err1_paddr)
    `CMP("errors_1_report_to_beu", g_err1_beu, i_err1_beu)
    `CMP("perf_only_0_hit",        g_pf_o0h, i_pf_o0h)
    `CMP("perf_only_0_miss",       g_pf_o0m, i_pf_o0m)
    `CMP("perf_hit_0_hit_1",       g_pf_h0h1, i_pf_h0h1)
    `CMP("perf_hit_0_miss_1",      g_pf_h0m1, i_pf_h0m1)
    `CMP("perf_miss_0_hit_1",      g_pf_m0h1, i_pf_m0h1)
    `CMP("perf_miss_0_miss_1",     g_pf_m0m1, i_pf_m0m1)
    `CMP("perf_hit_0_except_1",    g_pf_h0e1, i_pf_h0e1)
    `CMP("perf_miss_0_except_1",   g_pf_m0e1, i_pf_m0e1)
    `CMP("perf_except_0",          g_pf_e0, i_pf_e0)
    `CMP("perf_bank_hit_0",        g_pf_bh0, i_pf_bh0)
    `CMP("perf_bank_hit_1",        g_pf_bh1, i_pf_bh1)
    `CMP("perf_hit",               g_pf_hit, i_pf_hit)
    `CMP("gatewayIn_packed_0_bore", g_bore0, i_bore0)
    `CMP("gatewayIn_packed_1_bore", g_bore1, i_bore1)
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

  int warm_s1_fire = 0;

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));   // ut_common.mk 统一下发 200000
    for (int t = 0; t < N_TAG; t++) tag_pool[t] = {4'($urandom()), 32'($urandom())};
    clear_inputs();
    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;
    // 暖机：确定性命中取指，直到 golden 至少 s1 fire 过一次且其后一拍已过（PMP 保持寄存器写定）
    drive_warmup();
    repeat (WARMUP) begin
      @(posedge clk);
      if (u_g.s1_fire) warm_s1_fire++;
    end
    if (warm_s1_fire == 0) begin
      $display("TEST FAILED (暖机期间 golden 没有 s1 fire，PMP 保持寄存器未写定)");
      $fatal(1);
    end
    init_done  = 1'b1;               // 从这里起激励随机、rst 交给随机脉冲逻辑
    @(posedge clk);
    compare_en = 1'b1;
    repeat (NCYCLES) @(posedge clk);

    $display("checks=%0d errors=%0d ncompare=%0d x_skips=%0d", checks, errors, ncompare, x_skips);
    $display("覆盖：");
    $display("  s0_fire=%0d double=%0d s1_fire=%0d s2_fire=%0d s2_fire_double=%0d  s0 stall: wl=%0d data=%0d s1=%0d",
             cov_s0_fire, cov_s0_double, cov_s1_fire, cov_s2_fire, cov_s2_fire_double,
             cov_s0_stall_wl, cov_s0_stall_data, cov_s0_stall_s1);
    $display("  mshr hit: s1=%p s2=%p s2_corrupt=%0d  touch=%p", cov_s1_mshr_hit, cov_s2_mshr_hit, cov_s2_mshr_hit_corrupt, cov_touch);
    $display("  ecc: meta_corrupt=%p data_corrupt=%p meta_flush=%p err_ecc=%p err_l2=%p refetch_after_hit=%0d ecc_off_fire=%0d",
             cov_meta_corrupt, cov_data_corrupt, cov_meta_flush, cov_err_ecc, cov_err_l2, cov_refetch_after_hit, cov_ecc_off_fire);
    $display("  mshr req fire=%p stall=%0d  resp_stall=%0d flush_s1=%0d flush_s2=%0d  excp_out=%p mmio_out=%p l2_af=%0d",
             cov_mshr_req_fire, cov_mshr_req_stall, cov_resp_stall, cov_flush_s1, cov_flush_s2, cov_excp_out, cov_mmio_out, cov_l2_af);
    $display("  bank_low=%p reset_pulse=%0d", cov_bank_low, cov_reset_pulse);

    if (x_skips != 0) begin
      $display("  [COV FAIL] x_skips = %0d（X 守卫触发过，比对被吃掉）", x_skips);
      cov_fail++;
    end
    if (checks != N_OUT * ncompare) begin
      $display("  [COV FAIL] checks=%0d != %0d 输出 × %0d 拍 = %0d", checks, N_OUT, ncompare, N_OUT * ncompare);
      cov_fail++;
    end
    cov_fail += cov_chk("s0 fire",                 cov_s0_fire,          COV_MIN);
    cov_fail += cov_chk("s0 fire doubleline",      cov_s0_double,        COV_MIN);
    cov_fail += cov_chk("s1 fire",                 cov_s1_fire,          COV_MIN);
    cov_fail += cov_chk("s2 fire",                 cov_s2_fire,          COV_MIN);
    cov_fail += cov_chk("s2 fire doubleline",      cov_s2_fire_double,   COV_MIN);
    cov_fail += cov_chk("s0 stall wayLookup",      cov_s0_stall_wl,      COV_MIN);
    cov_fail += cov_chk("s0 stall data ready",     cov_s0_stall_data,    COV_MIN);
    cov_fail += cov_chk("s0 stall s1 busy",        cov_s0_stall_s1,      COV_MIN);
    cov_fail += cov_chk("s1 mshr hit p0",          cov_s1_mshr_hit[0],   COV_MIN);
    cov_fail += cov_chk("s1 mshr hit p1",          cov_s1_mshr_hit[1],   COV_MIN);
    cov_fail += cov_chk("s2 mshr hit p0",          cov_s2_mshr_hit[0],   COV_MIN);
    cov_fail += cov_chk("s2 mshr hit p1",          cov_s2_mshr_hit[1],   COV_MIN);
    cov_fail += cov_chk("s2 mshr hit corrupt",     cov_s2_mshr_hit_corrupt, 50);
    cov_fail += cov_chk("touch p0",                cov_touch[0],         COV_MIN);
    cov_fail += cov_chk("touch p1",                cov_touch[1],         COV_MIN);
    cov_fail += cov_chk("meta corrupt p0",         cov_meta_corrupt[0],  COV_MIN);
    cov_fail += cov_chk("meta corrupt p1",         cov_meta_corrupt[1],  COV_MIN);
    cov_fail += cov_chk("data corrupt p0",         cov_data_corrupt[0],  COV_MIN);
    cov_fail += cov_chk("data corrupt p1",         cov_data_corrupt[1],  COV_MIN);
    cov_fail += cov_chk("meta flush p0",           cov_meta_flush[0],    COV_MIN);
    cov_fail += cov_chk("meta flush p1",           cov_meta_flush[1],    COV_MIN);
    cov_fail += cov_chk("errors ecc p0",           cov_err_ecc[0],       COV_MIN);
    cov_fail += cov_chk("errors ecc p1",           cov_err_ecc[1],       COV_MIN);
    cov_fail += cov_chk("errors l2 p0",            cov_err_l2[0],        50);
    cov_fail += cov_chk("errors l2 p1",            cov_err_l2[1],        50);
    cov_fail += cov_chk("refetch after hit",       cov_refetch_after_hit, COV_MIN);
    cov_fail += cov_chk("ecc off fire",            cov_ecc_off_fire,     COV_MIN);
    cov_fail += cov_chk("mshr req fire p0",        cov_mshr_req_fire[0], COV_MIN);
    cov_fail += cov_chk("mshr req fire p1",        cov_mshr_req_fire[1], COV_MIN);
    cov_fail += cov_chk("mshr req stall",          cov_mshr_req_stall,   COV_MIN);
    cov_fail += cov_chk("resp stall",              cov_resp_stall,       COV_MIN);
    cov_fail += cov_chk("flush while s1",          cov_flush_s1,         COV_MIN);
    cov_fail += cov_chk("flush while s2",          cov_flush_s2,         COV_MIN);
    cov_fail += cov_chk("exception out p0",        cov_excp_out[0],      COV_MIN);
    cov_fail += cov_chk("exception out p1",        cov_excp_out[1],      COV_MIN);
    cov_fail += cov_chk("mmio out p0",             cov_mmio_out[0],      COV_MIN);
    cov_fail += cov_chk("mmio out p1",             cov_mmio_out[1],      COV_MIN);
    cov_fail += cov_chk("l2 corrupt af",           cov_l2_af,            50);
    for (int b = 0; b < 8; b++)
      cov_fail += cov_chk($sformatf("s2 fire bank_low=%0d", b), cov_bank_low[b], COV_MIN);
    cov_fail += cov_chk("async reset pulse",       cov_reset_pulse,      10);

    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%0d cov_fail=%0d)", errors, cov_fail);
    $fatal(1);
  end

endmodule
