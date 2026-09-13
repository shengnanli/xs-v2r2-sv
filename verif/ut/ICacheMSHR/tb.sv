// 自动生成：verif/ut/ICacheMSHR/gen.py（读 G1 golden）—— 勿手改
// ICacheMSHR 家族 14 变体双例化逐拍比对：golden <V> vs 可读重写 <V>_xs
// （同一个 xs_ICacheMSHR_core：取指变体 HAS_FLUSH=0，预取变体 HAS_FLUSH=1）。
//
// 每个变体一对实例、各自独立的随机激励；比对的是全部 11 个输出打成的 114 位向量
// （wfiSafe/req_ready/acquire_valid/acquire_address/acquire_vSetIdx/两个 hit/
//   resp_valid/resp_blkPaddr/resp_vSetIdx/resp_way）。
//
// 激励设计：地址池故意开得很小（blkPaddr 0..3 × vSetIdx 0..1），
//   让并行查询口经常撞上本格登记的地址，把 hit 分支真正跑起来；
//   fencei / flush / invalid / wfiReq 以低概率注入，reset 偶尔异步脉冲一拍
//   （golden 是异步高有效复位，这条路径必须走到）。
//
// 采样点：**先驱动、再 #1 比对、然后过 posedge**。为什么不能反过来（先比对再驱动）：
//   那样在比对时刻，寄存器已经被"当前这份输入"更新过了，于是像
//   "io_invalid 为 1 且本格仍占用" 这类事件按构造恒为 0 —— 覆盖计数会永远是 0，
//   而 errors 照样 0。本 tb 第一版就踩了这个坑，是覆盖闸把它抓出来的。
//
// 覆盖闸（本轮已发生"tb 20 万拍只 fire 1 次却报 errors=0"的事故）：每个变体都要
//   (1) 有效比对 >= COV_MIN；
//   (2) 入队 enq、发出 send、命中 hit、resp_valid、wfi 不安全、被冲刷 kill、
//       invalid 清除 —— 七类关键事件各 >= COV_MIN；
//   (3) 预取变体还要单独统计 io_flush 触发的冲刷 >= COV_MIN。
//   任何一项不足即 TEST FAILED，不看 errors。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 500;
  bit clock = 0;
  logic reset;
  int errors = 0;
  int checks = 0;
  int cov_fail = 0;
  always #5 clock = ~clock;

  // ---- ICacheMSHR (fetchMSHRs_0, HAS_FLUSH=0) ----
  logic m0_fencei, m0_flush, m0_wfiReq, m0_invalid, m0_req_valid, m0_acq_ready;
  logic [41:0] m0_req_paddr, m0_lk0_paddr, m0_lk1_paddr;
  logic [7:0]  m0_req_vset,  m0_lk0_vset,  m0_lk1_vset;
  logic [1:0]  m0_victim;
  int m0_checks, m0_enq, m0_send, m0_hit, m0_resp, m0_unsafe, m0_kill, m0_inval;
  wire g_m0_wfiSafe, g_m0_req_ready, g_m0_acq_valid,
       g_m0_lk0_hit, g_m0_lk1_hit, g_m0_resp_valid;
  wire [47:0] g_m0_acq_addr;
  wire [7:0]  g_m0_acq_vset, g_m0_resp_vset;
  wire [41:0] g_m0_resp_paddr;
  wire [1:0]  g_m0_resp_way;
  wire i_m0_wfiSafe, i_m0_req_ready, i_m0_acq_valid,
       i_m0_lk0_hit, i_m0_lk1_hit, i_m0_resp_valid;
  wire [47:0] i_m0_acq_addr;
  wire [7:0]  i_m0_acq_vset, i_m0_resp_vset;
  wire [41:0] i_m0_resp_paddr;
  wire [1:0]  i_m0_resp_way;
  ICacheMSHR u_g_m0 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m0_fencei),
    .io_wfi_wfiReq(m0_wfiReq),
    .io_wfi_wfiSafe(g_m0_wfiSafe),
    .io_invalid(m0_invalid),
    .io_req_ready(g_m0_req_ready),
    .io_req_valid(m0_req_valid),
    .io_req_bits_blkPaddr(m0_req_paddr),
    .io_req_bits_vSetIdx(m0_req_vset),
    .io_acquire_ready(m0_acq_ready),
    .io_acquire_valid(g_m0_acq_valid),
    .io_acquire_bits_acquire_address(g_m0_acq_addr),
    .io_acquire_bits_vSetIdx(g_m0_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m0_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m0_lk0_vset),
    .io_lookUps_0_hit(g_m0_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m0_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m0_lk1_vset),
    .io_lookUps_1_hit(g_m0_lk1_hit),
    .io_resp_valid(g_m0_resp_valid),
    .io_resp_bits_blkPaddr(g_m0_resp_paddr),
    .io_resp_bits_vSetIdx(g_m0_resp_vset),
    .io_resp_bits_way(g_m0_resp_way),
    .io_victimWay(m0_victim)
  );
  ICacheMSHR_xs u_i_m0 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m0_fencei),
    .io_wfi_wfiReq(m0_wfiReq),
    .io_wfi_wfiSafe(i_m0_wfiSafe),
    .io_invalid(m0_invalid),
    .io_req_ready(i_m0_req_ready),
    .io_req_valid(m0_req_valid),
    .io_req_bits_blkPaddr(m0_req_paddr),
    .io_req_bits_vSetIdx(m0_req_vset),
    .io_acquire_ready(m0_acq_ready),
    .io_acquire_valid(i_m0_acq_valid),
    .io_acquire_bits_acquire_address(i_m0_acq_addr),
    .io_acquire_bits_vSetIdx(i_m0_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m0_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m0_lk0_vset),
    .io_lookUps_0_hit(i_m0_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m0_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m0_lk1_vset),
    .io_lookUps_1_hit(i_m0_lk1_hit),
    .io_resp_valid(i_m0_resp_valid),
    .io_resp_bits_blkPaddr(i_m0_resp_paddr),
    .io_resp_bits_vSetIdx(i_m0_resp_vset),
    .io_resp_bits_way(i_m0_resp_way),
    .io_victimWay(m0_victim)
  );
  wire [113:0] g_m0_out =
    {g_m0_wfiSafe, g_m0_req_ready, g_m0_acq_valid, g_m0_acq_addr, g_m0_acq_vset,
     g_m0_lk0_hit, g_m0_lk1_hit, g_m0_resp_valid, g_m0_resp_paddr, g_m0_resp_vset, g_m0_resp_way};
  wire [113:0] i_m0_out =
    {i_m0_wfiSafe, i_m0_req_ready, i_m0_acq_valid, i_m0_acq_addr, i_m0_acq_vset,
     i_m0_lk0_hit, i_m0_lk1_hit, i_m0_resp_valid, i_m0_resp_paddr, i_m0_resp_vset, i_m0_resp_way};

  // ---- ICacheMSHR_1 (fetchMSHRs_1, HAS_FLUSH=0) ----
  logic m1_fencei, m1_flush, m1_wfiReq, m1_invalid, m1_req_valid, m1_acq_ready;
  logic [41:0] m1_req_paddr, m1_lk0_paddr, m1_lk1_paddr;
  logic [7:0]  m1_req_vset,  m1_lk0_vset,  m1_lk1_vset;
  logic [1:0]  m1_victim;
  int m1_checks, m1_enq, m1_send, m1_hit, m1_resp, m1_unsafe, m1_kill, m1_inval;
  wire g_m1_wfiSafe, g_m1_req_ready, g_m1_acq_valid,
       g_m1_lk0_hit, g_m1_lk1_hit, g_m1_resp_valid;
  wire [47:0] g_m1_acq_addr;
  wire [7:0]  g_m1_acq_vset, g_m1_resp_vset;
  wire [41:0] g_m1_resp_paddr;
  wire [1:0]  g_m1_resp_way;
  wire i_m1_wfiSafe, i_m1_req_ready, i_m1_acq_valid,
       i_m1_lk0_hit, i_m1_lk1_hit, i_m1_resp_valid;
  wire [47:0] i_m1_acq_addr;
  wire [7:0]  i_m1_acq_vset, i_m1_resp_vset;
  wire [41:0] i_m1_resp_paddr;
  wire [1:0]  i_m1_resp_way;
  ICacheMSHR_1 u_g_m1 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m1_fencei),
    .io_wfi_wfiReq(m1_wfiReq),
    .io_wfi_wfiSafe(g_m1_wfiSafe),
    .io_invalid(m1_invalid),
    .io_req_ready(g_m1_req_ready),
    .io_req_valid(m1_req_valid),
    .io_req_bits_blkPaddr(m1_req_paddr),
    .io_req_bits_vSetIdx(m1_req_vset),
    .io_acquire_ready(m1_acq_ready),
    .io_acquire_valid(g_m1_acq_valid),
    .io_acquire_bits_acquire_address(g_m1_acq_addr),
    .io_acquire_bits_vSetIdx(g_m1_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m1_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m1_lk0_vset),
    .io_lookUps_0_hit(g_m1_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m1_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m1_lk1_vset),
    .io_lookUps_1_hit(g_m1_lk1_hit),
    .io_resp_valid(g_m1_resp_valid),
    .io_resp_bits_blkPaddr(g_m1_resp_paddr),
    .io_resp_bits_vSetIdx(g_m1_resp_vset),
    .io_resp_bits_way(g_m1_resp_way),
    .io_victimWay(m1_victim)
  );
  ICacheMSHR_1_xs u_i_m1 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m1_fencei),
    .io_wfi_wfiReq(m1_wfiReq),
    .io_wfi_wfiSafe(i_m1_wfiSafe),
    .io_invalid(m1_invalid),
    .io_req_ready(i_m1_req_ready),
    .io_req_valid(m1_req_valid),
    .io_req_bits_blkPaddr(m1_req_paddr),
    .io_req_bits_vSetIdx(m1_req_vset),
    .io_acquire_ready(m1_acq_ready),
    .io_acquire_valid(i_m1_acq_valid),
    .io_acquire_bits_acquire_address(i_m1_acq_addr),
    .io_acquire_bits_vSetIdx(i_m1_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m1_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m1_lk0_vset),
    .io_lookUps_0_hit(i_m1_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m1_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m1_lk1_vset),
    .io_lookUps_1_hit(i_m1_lk1_hit),
    .io_resp_valid(i_m1_resp_valid),
    .io_resp_bits_blkPaddr(i_m1_resp_paddr),
    .io_resp_bits_vSetIdx(i_m1_resp_vset),
    .io_resp_bits_way(i_m1_resp_way),
    .io_victimWay(m1_victim)
  );
  wire [113:0] g_m1_out =
    {g_m1_wfiSafe, g_m1_req_ready, g_m1_acq_valid, g_m1_acq_addr, g_m1_acq_vset,
     g_m1_lk0_hit, g_m1_lk1_hit, g_m1_resp_valid, g_m1_resp_paddr, g_m1_resp_vset, g_m1_resp_way};
  wire [113:0] i_m1_out =
    {i_m1_wfiSafe, i_m1_req_ready, i_m1_acq_valid, i_m1_acq_addr, i_m1_acq_vset,
     i_m1_lk0_hit, i_m1_lk1_hit, i_m1_resp_valid, i_m1_resp_paddr, i_m1_resp_vset, i_m1_resp_way};

  // ---- ICacheMSHR_2 (fetchMSHRs_2, HAS_FLUSH=0) ----
  logic m2_fencei, m2_flush, m2_wfiReq, m2_invalid, m2_req_valid, m2_acq_ready;
  logic [41:0] m2_req_paddr, m2_lk0_paddr, m2_lk1_paddr;
  logic [7:0]  m2_req_vset,  m2_lk0_vset,  m2_lk1_vset;
  logic [1:0]  m2_victim;
  int m2_checks, m2_enq, m2_send, m2_hit, m2_resp, m2_unsafe, m2_kill, m2_inval;
  wire g_m2_wfiSafe, g_m2_req_ready, g_m2_acq_valid,
       g_m2_lk0_hit, g_m2_lk1_hit, g_m2_resp_valid;
  wire [47:0] g_m2_acq_addr;
  wire [7:0]  g_m2_acq_vset, g_m2_resp_vset;
  wire [41:0] g_m2_resp_paddr;
  wire [1:0]  g_m2_resp_way;
  wire i_m2_wfiSafe, i_m2_req_ready, i_m2_acq_valid,
       i_m2_lk0_hit, i_m2_lk1_hit, i_m2_resp_valid;
  wire [47:0] i_m2_acq_addr;
  wire [7:0]  i_m2_acq_vset, i_m2_resp_vset;
  wire [41:0] i_m2_resp_paddr;
  wire [1:0]  i_m2_resp_way;
  ICacheMSHR_2 u_g_m2 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m2_fencei),
    .io_wfi_wfiReq(m2_wfiReq),
    .io_wfi_wfiSafe(g_m2_wfiSafe),
    .io_invalid(m2_invalid),
    .io_req_ready(g_m2_req_ready),
    .io_req_valid(m2_req_valid),
    .io_req_bits_blkPaddr(m2_req_paddr),
    .io_req_bits_vSetIdx(m2_req_vset),
    .io_acquire_ready(m2_acq_ready),
    .io_acquire_valid(g_m2_acq_valid),
    .io_acquire_bits_acquire_address(g_m2_acq_addr),
    .io_acquire_bits_vSetIdx(g_m2_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m2_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m2_lk0_vset),
    .io_lookUps_0_hit(g_m2_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m2_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m2_lk1_vset),
    .io_lookUps_1_hit(g_m2_lk1_hit),
    .io_resp_valid(g_m2_resp_valid),
    .io_resp_bits_blkPaddr(g_m2_resp_paddr),
    .io_resp_bits_vSetIdx(g_m2_resp_vset),
    .io_resp_bits_way(g_m2_resp_way),
    .io_victimWay(m2_victim)
  );
  ICacheMSHR_2_xs u_i_m2 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m2_fencei),
    .io_wfi_wfiReq(m2_wfiReq),
    .io_wfi_wfiSafe(i_m2_wfiSafe),
    .io_invalid(m2_invalid),
    .io_req_ready(i_m2_req_ready),
    .io_req_valid(m2_req_valid),
    .io_req_bits_blkPaddr(m2_req_paddr),
    .io_req_bits_vSetIdx(m2_req_vset),
    .io_acquire_ready(m2_acq_ready),
    .io_acquire_valid(i_m2_acq_valid),
    .io_acquire_bits_acquire_address(i_m2_acq_addr),
    .io_acquire_bits_vSetIdx(i_m2_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m2_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m2_lk0_vset),
    .io_lookUps_0_hit(i_m2_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m2_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m2_lk1_vset),
    .io_lookUps_1_hit(i_m2_lk1_hit),
    .io_resp_valid(i_m2_resp_valid),
    .io_resp_bits_blkPaddr(i_m2_resp_paddr),
    .io_resp_bits_vSetIdx(i_m2_resp_vset),
    .io_resp_bits_way(i_m2_resp_way),
    .io_victimWay(m2_victim)
  );
  wire [113:0] g_m2_out =
    {g_m2_wfiSafe, g_m2_req_ready, g_m2_acq_valid, g_m2_acq_addr, g_m2_acq_vset,
     g_m2_lk0_hit, g_m2_lk1_hit, g_m2_resp_valid, g_m2_resp_paddr, g_m2_resp_vset, g_m2_resp_way};
  wire [113:0] i_m2_out =
    {i_m2_wfiSafe, i_m2_req_ready, i_m2_acq_valid, i_m2_acq_addr, i_m2_acq_vset,
     i_m2_lk0_hit, i_m2_lk1_hit, i_m2_resp_valid, i_m2_resp_paddr, i_m2_resp_vset, i_m2_resp_way};

  // ---- ICacheMSHR_3 (fetchMSHRs_3, HAS_FLUSH=0) ----
  logic m3_fencei, m3_flush, m3_wfiReq, m3_invalid, m3_req_valid, m3_acq_ready;
  logic [41:0] m3_req_paddr, m3_lk0_paddr, m3_lk1_paddr;
  logic [7:0]  m3_req_vset,  m3_lk0_vset,  m3_lk1_vset;
  logic [1:0]  m3_victim;
  int m3_checks, m3_enq, m3_send, m3_hit, m3_resp, m3_unsafe, m3_kill, m3_inval;
  wire g_m3_wfiSafe, g_m3_req_ready, g_m3_acq_valid,
       g_m3_lk0_hit, g_m3_lk1_hit, g_m3_resp_valid;
  wire [47:0] g_m3_acq_addr;
  wire [7:0]  g_m3_acq_vset, g_m3_resp_vset;
  wire [41:0] g_m3_resp_paddr;
  wire [1:0]  g_m3_resp_way;
  wire i_m3_wfiSafe, i_m3_req_ready, i_m3_acq_valid,
       i_m3_lk0_hit, i_m3_lk1_hit, i_m3_resp_valid;
  wire [47:0] i_m3_acq_addr;
  wire [7:0]  i_m3_acq_vset, i_m3_resp_vset;
  wire [41:0] i_m3_resp_paddr;
  wire [1:0]  i_m3_resp_way;
  ICacheMSHR_3 u_g_m3 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m3_fencei),
    .io_wfi_wfiReq(m3_wfiReq),
    .io_wfi_wfiSafe(g_m3_wfiSafe),
    .io_invalid(m3_invalid),
    .io_req_ready(g_m3_req_ready),
    .io_req_valid(m3_req_valid),
    .io_req_bits_blkPaddr(m3_req_paddr),
    .io_req_bits_vSetIdx(m3_req_vset),
    .io_acquire_ready(m3_acq_ready),
    .io_acquire_valid(g_m3_acq_valid),
    .io_acquire_bits_acquire_address(g_m3_acq_addr),
    .io_acquire_bits_vSetIdx(g_m3_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m3_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m3_lk0_vset),
    .io_lookUps_0_hit(g_m3_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m3_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m3_lk1_vset),
    .io_lookUps_1_hit(g_m3_lk1_hit),
    .io_resp_valid(g_m3_resp_valid),
    .io_resp_bits_blkPaddr(g_m3_resp_paddr),
    .io_resp_bits_vSetIdx(g_m3_resp_vset),
    .io_resp_bits_way(g_m3_resp_way),
    .io_victimWay(m3_victim)
  );
  ICacheMSHR_3_xs u_i_m3 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m3_fencei),
    .io_wfi_wfiReq(m3_wfiReq),
    .io_wfi_wfiSafe(i_m3_wfiSafe),
    .io_invalid(m3_invalid),
    .io_req_ready(i_m3_req_ready),
    .io_req_valid(m3_req_valid),
    .io_req_bits_blkPaddr(m3_req_paddr),
    .io_req_bits_vSetIdx(m3_req_vset),
    .io_acquire_ready(m3_acq_ready),
    .io_acquire_valid(i_m3_acq_valid),
    .io_acquire_bits_acquire_address(i_m3_acq_addr),
    .io_acquire_bits_vSetIdx(i_m3_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m3_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m3_lk0_vset),
    .io_lookUps_0_hit(i_m3_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m3_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m3_lk1_vset),
    .io_lookUps_1_hit(i_m3_lk1_hit),
    .io_resp_valid(i_m3_resp_valid),
    .io_resp_bits_blkPaddr(i_m3_resp_paddr),
    .io_resp_bits_vSetIdx(i_m3_resp_vset),
    .io_resp_bits_way(i_m3_resp_way),
    .io_victimWay(m3_victim)
  );
  wire [113:0] g_m3_out =
    {g_m3_wfiSafe, g_m3_req_ready, g_m3_acq_valid, g_m3_acq_addr, g_m3_acq_vset,
     g_m3_lk0_hit, g_m3_lk1_hit, g_m3_resp_valid, g_m3_resp_paddr, g_m3_resp_vset, g_m3_resp_way};
  wire [113:0] i_m3_out =
    {i_m3_wfiSafe, i_m3_req_ready, i_m3_acq_valid, i_m3_acq_addr, i_m3_acq_vset,
     i_m3_lk0_hit, i_m3_lk1_hit, i_m3_resp_valid, i_m3_resp_paddr, i_m3_resp_vset, i_m3_resp_way};

  // ---- ICacheMSHR_4 (prefetchMSHRs_0, HAS_FLUSH=1) ----
  logic m4_fencei, m4_flush, m4_wfiReq, m4_invalid, m4_req_valid, m4_acq_ready;
  logic [41:0] m4_req_paddr, m4_lk0_paddr, m4_lk1_paddr;
  logic [7:0]  m4_req_vset,  m4_lk0_vset,  m4_lk1_vset;
  logic [1:0]  m4_victim;
  int m4_checks, m4_enq, m4_send, m4_hit, m4_resp, m4_unsafe, m4_kill, m4_inval;
  wire g_m4_wfiSafe, g_m4_req_ready, g_m4_acq_valid,
       g_m4_lk0_hit, g_m4_lk1_hit, g_m4_resp_valid;
  wire [47:0] g_m4_acq_addr;
  wire [7:0]  g_m4_acq_vset, g_m4_resp_vset;
  wire [41:0] g_m4_resp_paddr;
  wire [1:0]  g_m4_resp_way;
  wire i_m4_wfiSafe, i_m4_req_ready, i_m4_acq_valid,
       i_m4_lk0_hit, i_m4_lk1_hit, i_m4_resp_valid;
  wire [47:0] i_m4_acq_addr;
  wire [7:0]  i_m4_acq_vset, i_m4_resp_vset;
  wire [41:0] i_m4_resp_paddr;
  wire [1:0]  i_m4_resp_way;
  ICacheMSHR_4 u_g_m4 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m4_fencei),
    .io_flush(m4_flush),
    .io_wfi_wfiReq(m4_wfiReq),
    .io_wfi_wfiSafe(g_m4_wfiSafe),
    .io_invalid(m4_invalid),
    .io_req_ready(g_m4_req_ready),
    .io_req_valid(m4_req_valid),
    .io_req_bits_blkPaddr(m4_req_paddr),
    .io_req_bits_vSetIdx(m4_req_vset),
    .io_acquire_ready(m4_acq_ready),
    .io_acquire_valid(g_m4_acq_valid),
    .io_acquire_bits_acquire_address(g_m4_acq_addr),
    .io_acquire_bits_vSetIdx(g_m4_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m4_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m4_lk0_vset),
    .io_lookUps_0_hit(g_m4_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m4_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m4_lk1_vset),
    .io_lookUps_1_hit(g_m4_lk1_hit),
    .io_resp_valid(g_m4_resp_valid),
    .io_resp_bits_blkPaddr(g_m4_resp_paddr),
    .io_resp_bits_vSetIdx(g_m4_resp_vset),
    .io_resp_bits_way(g_m4_resp_way),
    .io_victimWay(m4_victim)
  );
  ICacheMSHR_4_xs u_i_m4 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m4_fencei),
    .io_flush(m4_flush),
    .io_wfi_wfiReq(m4_wfiReq),
    .io_wfi_wfiSafe(i_m4_wfiSafe),
    .io_invalid(m4_invalid),
    .io_req_ready(i_m4_req_ready),
    .io_req_valid(m4_req_valid),
    .io_req_bits_blkPaddr(m4_req_paddr),
    .io_req_bits_vSetIdx(m4_req_vset),
    .io_acquire_ready(m4_acq_ready),
    .io_acquire_valid(i_m4_acq_valid),
    .io_acquire_bits_acquire_address(i_m4_acq_addr),
    .io_acquire_bits_vSetIdx(i_m4_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m4_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m4_lk0_vset),
    .io_lookUps_0_hit(i_m4_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m4_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m4_lk1_vset),
    .io_lookUps_1_hit(i_m4_lk1_hit),
    .io_resp_valid(i_m4_resp_valid),
    .io_resp_bits_blkPaddr(i_m4_resp_paddr),
    .io_resp_bits_vSetIdx(i_m4_resp_vset),
    .io_resp_bits_way(i_m4_resp_way),
    .io_victimWay(m4_victim)
  );
  wire [113:0] g_m4_out =
    {g_m4_wfiSafe, g_m4_req_ready, g_m4_acq_valid, g_m4_acq_addr, g_m4_acq_vset,
     g_m4_lk0_hit, g_m4_lk1_hit, g_m4_resp_valid, g_m4_resp_paddr, g_m4_resp_vset, g_m4_resp_way};
  wire [113:0] i_m4_out =
    {i_m4_wfiSafe, i_m4_req_ready, i_m4_acq_valid, i_m4_acq_addr, i_m4_acq_vset,
     i_m4_lk0_hit, i_m4_lk1_hit, i_m4_resp_valid, i_m4_resp_paddr, i_m4_resp_vset, i_m4_resp_way};

  // ---- ICacheMSHR_5 (prefetchMSHRs_1, HAS_FLUSH=1) ----
  logic m5_fencei, m5_flush, m5_wfiReq, m5_invalid, m5_req_valid, m5_acq_ready;
  logic [41:0] m5_req_paddr, m5_lk0_paddr, m5_lk1_paddr;
  logic [7:0]  m5_req_vset,  m5_lk0_vset,  m5_lk1_vset;
  logic [1:0]  m5_victim;
  int m5_checks, m5_enq, m5_send, m5_hit, m5_resp, m5_unsafe, m5_kill, m5_inval;
  wire g_m5_wfiSafe, g_m5_req_ready, g_m5_acq_valid,
       g_m5_lk0_hit, g_m5_lk1_hit, g_m5_resp_valid;
  wire [47:0] g_m5_acq_addr;
  wire [7:0]  g_m5_acq_vset, g_m5_resp_vset;
  wire [41:0] g_m5_resp_paddr;
  wire [1:0]  g_m5_resp_way;
  wire i_m5_wfiSafe, i_m5_req_ready, i_m5_acq_valid,
       i_m5_lk0_hit, i_m5_lk1_hit, i_m5_resp_valid;
  wire [47:0] i_m5_acq_addr;
  wire [7:0]  i_m5_acq_vset, i_m5_resp_vset;
  wire [41:0] i_m5_resp_paddr;
  wire [1:0]  i_m5_resp_way;
  ICacheMSHR_5 u_g_m5 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m5_fencei),
    .io_flush(m5_flush),
    .io_wfi_wfiReq(m5_wfiReq),
    .io_wfi_wfiSafe(g_m5_wfiSafe),
    .io_invalid(m5_invalid),
    .io_req_ready(g_m5_req_ready),
    .io_req_valid(m5_req_valid),
    .io_req_bits_blkPaddr(m5_req_paddr),
    .io_req_bits_vSetIdx(m5_req_vset),
    .io_acquire_ready(m5_acq_ready),
    .io_acquire_valid(g_m5_acq_valid),
    .io_acquire_bits_acquire_address(g_m5_acq_addr),
    .io_acquire_bits_vSetIdx(g_m5_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m5_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m5_lk0_vset),
    .io_lookUps_0_hit(g_m5_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m5_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m5_lk1_vset),
    .io_lookUps_1_hit(g_m5_lk1_hit),
    .io_resp_valid(g_m5_resp_valid),
    .io_resp_bits_blkPaddr(g_m5_resp_paddr),
    .io_resp_bits_vSetIdx(g_m5_resp_vset),
    .io_resp_bits_way(g_m5_resp_way),
    .io_victimWay(m5_victim)
  );
  ICacheMSHR_5_xs u_i_m5 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m5_fencei),
    .io_flush(m5_flush),
    .io_wfi_wfiReq(m5_wfiReq),
    .io_wfi_wfiSafe(i_m5_wfiSafe),
    .io_invalid(m5_invalid),
    .io_req_ready(i_m5_req_ready),
    .io_req_valid(m5_req_valid),
    .io_req_bits_blkPaddr(m5_req_paddr),
    .io_req_bits_vSetIdx(m5_req_vset),
    .io_acquire_ready(m5_acq_ready),
    .io_acquire_valid(i_m5_acq_valid),
    .io_acquire_bits_acquire_address(i_m5_acq_addr),
    .io_acquire_bits_vSetIdx(i_m5_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m5_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m5_lk0_vset),
    .io_lookUps_0_hit(i_m5_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m5_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m5_lk1_vset),
    .io_lookUps_1_hit(i_m5_lk1_hit),
    .io_resp_valid(i_m5_resp_valid),
    .io_resp_bits_blkPaddr(i_m5_resp_paddr),
    .io_resp_bits_vSetIdx(i_m5_resp_vset),
    .io_resp_bits_way(i_m5_resp_way),
    .io_victimWay(m5_victim)
  );
  wire [113:0] g_m5_out =
    {g_m5_wfiSafe, g_m5_req_ready, g_m5_acq_valid, g_m5_acq_addr, g_m5_acq_vset,
     g_m5_lk0_hit, g_m5_lk1_hit, g_m5_resp_valid, g_m5_resp_paddr, g_m5_resp_vset, g_m5_resp_way};
  wire [113:0] i_m5_out =
    {i_m5_wfiSafe, i_m5_req_ready, i_m5_acq_valid, i_m5_acq_addr, i_m5_acq_vset,
     i_m5_lk0_hit, i_m5_lk1_hit, i_m5_resp_valid, i_m5_resp_paddr, i_m5_resp_vset, i_m5_resp_way};

  // ---- ICacheMSHR_6 (prefetchMSHRs_2, HAS_FLUSH=1) ----
  logic m6_fencei, m6_flush, m6_wfiReq, m6_invalid, m6_req_valid, m6_acq_ready;
  logic [41:0] m6_req_paddr, m6_lk0_paddr, m6_lk1_paddr;
  logic [7:0]  m6_req_vset,  m6_lk0_vset,  m6_lk1_vset;
  logic [1:0]  m6_victim;
  int m6_checks, m6_enq, m6_send, m6_hit, m6_resp, m6_unsafe, m6_kill, m6_inval;
  wire g_m6_wfiSafe, g_m6_req_ready, g_m6_acq_valid,
       g_m6_lk0_hit, g_m6_lk1_hit, g_m6_resp_valid;
  wire [47:0] g_m6_acq_addr;
  wire [7:0]  g_m6_acq_vset, g_m6_resp_vset;
  wire [41:0] g_m6_resp_paddr;
  wire [1:0]  g_m6_resp_way;
  wire i_m6_wfiSafe, i_m6_req_ready, i_m6_acq_valid,
       i_m6_lk0_hit, i_m6_lk1_hit, i_m6_resp_valid;
  wire [47:0] i_m6_acq_addr;
  wire [7:0]  i_m6_acq_vset, i_m6_resp_vset;
  wire [41:0] i_m6_resp_paddr;
  wire [1:0]  i_m6_resp_way;
  ICacheMSHR_6 u_g_m6 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m6_fencei),
    .io_flush(m6_flush),
    .io_wfi_wfiReq(m6_wfiReq),
    .io_wfi_wfiSafe(g_m6_wfiSafe),
    .io_invalid(m6_invalid),
    .io_req_ready(g_m6_req_ready),
    .io_req_valid(m6_req_valid),
    .io_req_bits_blkPaddr(m6_req_paddr),
    .io_req_bits_vSetIdx(m6_req_vset),
    .io_acquire_ready(m6_acq_ready),
    .io_acquire_valid(g_m6_acq_valid),
    .io_acquire_bits_acquire_address(g_m6_acq_addr),
    .io_acquire_bits_vSetIdx(g_m6_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m6_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m6_lk0_vset),
    .io_lookUps_0_hit(g_m6_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m6_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m6_lk1_vset),
    .io_lookUps_1_hit(g_m6_lk1_hit),
    .io_resp_valid(g_m6_resp_valid),
    .io_resp_bits_blkPaddr(g_m6_resp_paddr),
    .io_resp_bits_vSetIdx(g_m6_resp_vset),
    .io_resp_bits_way(g_m6_resp_way),
    .io_victimWay(m6_victim)
  );
  ICacheMSHR_6_xs u_i_m6 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m6_fencei),
    .io_flush(m6_flush),
    .io_wfi_wfiReq(m6_wfiReq),
    .io_wfi_wfiSafe(i_m6_wfiSafe),
    .io_invalid(m6_invalid),
    .io_req_ready(i_m6_req_ready),
    .io_req_valid(m6_req_valid),
    .io_req_bits_blkPaddr(m6_req_paddr),
    .io_req_bits_vSetIdx(m6_req_vset),
    .io_acquire_ready(m6_acq_ready),
    .io_acquire_valid(i_m6_acq_valid),
    .io_acquire_bits_acquire_address(i_m6_acq_addr),
    .io_acquire_bits_vSetIdx(i_m6_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m6_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m6_lk0_vset),
    .io_lookUps_0_hit(i_m6_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m6_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m6_lk1_vset),
    .io_lookUps_1_hit(i_m6_lk1_hit),
    .io_resp_valid(i_m6_resp_valid),
    .io_resp_bits_blkPaddr(i_m6_resp_paddr),
    .io_resp_bits_vSetIdx(i_m6_resp_vset),
    .io_resp_bits_way(i_m6_resp_way),
    .io_victimWay(m6_victim)
  );
  wire [113:0] g_m6_out =
    {g_m6_wfiSafe, g_m6_req_ready, g_m6_acq_valid, g_m6_acq_addr, g_m6_acq_vset,
     g_m6_lk0_hit, g_m6_lk1_hit, g_m6_resp_valid, g_m6_resp_paddr, g_m6_resp_vset, g_m6_resp_way};
  wire [113:0] i_m6_out =
    {i_m6_wfiSafe, i_m6_req_ready, i_m6_acq_valid, i_m6_acq_addr, i_m6_acq_vset,
     i_m6_lk0_hit, i_m6_lk1_hit, i_m6_resp_valid, i_m6_resp_paddr, i_m6_resp_vset, i_m6_resp_way};

  // ---- ICacheMSHR_7 (prefetchMSHRs_3, HAS_FLUSH=1) ----
  logic m7_fencei, m7_flush, m7_wfiReq, m7_invalid, m7_req_valid, m7_acq_ready;
  logic [41:0] m7_req_paddr, m7_lk0_paddr, m7_lk1_paddr;
  logic [7:0]  m7_req_vset,  m7_lk0_vset,  m7_lk1_vset;
  logic [1:0]  m7_victim;
  int m7_checks, m7_enq, m7_send, m7_hit, m7_resp, m7_unsafe, m7_kill, m7_inval;
  wire g_m7_wfiSafe, g_m7_req_ready, g_m7_acq_valid,
       g_m7_lk0_hit, g_m7_lk1_hit, g_m7_resp_valid;
  wire [47:0] g_m7_acq_addr;
  wire [7:0]  g_m7_acq_vset, g_m7_resp_vset;
  wire [41:0] g_m7_resp_paddr;
  wire [1:0]  g_m7_resp_way;
  wire i_m7_wfiSafe, i_m7_req_ready, i_m7_acq_valid,
       i_m7_lk0_hit, i_m7_lk1_hit, i_m7_resp_valid;
  wire [47:0] i_m7_acq_addr;
  wire [7:0]  i_m7_acq_vset, i_m7_resp_vset;
  wire [41:0] i_m7_resp_paddr;
  wire [1:0]  i_m7_resp_way;
  ICacheMSHR_7 u_g_m7 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m7_fencei),
    .io_flush(m7_flush),
    .io_wfi_wfiReq(m7_wfiReq),
    .io_wfi_wfiSafe(g_m7_wfiSafe),
    .io_invalid(m7_invalid),
    .io_req_ready(g_m7_req_ready),
    .io_req_valid(m7_req_valid),
    .io_req_bits_blkPaddr(m7_req_paddr),
    .io_req_bits_vSetIdx(m7_req_vset),
    .io_acquire_ready(m7_acq_ready),
    .io_acquire_valid(g_m7_acq_valid),
    .io_acquire_bits_acquire_address(g_m7_acq_addr),
    .io_acquire_bits_vSetIdx(g_m7_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m7_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m7_lk0_vset),
    .io_lookUps_0_hit(g_m7_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m7_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m7_lk1_vset),
    .io_lookUps_1_hit(g_m7_lk1_hit),
    .io_resp_valid(g_m7_resp_valid),
    .io_resp_bits_blkPaddr(g_m7_resp_paddr),
    .io_resp_bits_vSetIdx(g_m7_resp_vset),
    .io_resp_bits_way(g_m7_resp_way),
    .io_victimWay(m7_victim)
  );
  ICacheMSHR_7_xs u_i_m7 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m7_fencei),
    .io_flush(m7_flush),
    .io_wfi_wfiReq(m7_wfiReq),
    .io_wfi_wfiSafe(i_m7_wfiSafe),
    .io_invalid(m7_invalid),
    .io_req_ready(i_m7_req_ready),
    .io_req_valid(m7_req_valid),
    .io_req_bits_blkPaddr(m7_req_paddr),
    .io_req_bits_vSetIdx(m7_req_vset),
    .io_acquire_ready(m7_acq_ready),
    .io_acquire_valid(i_m7_acq_valid),
    .io_acquire_bits_acquire_address(i_m7_acq_addr),
    .io_acquire_bits_vSetIdx(i_m7_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m7_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m7_lk0_vset),
    .io_lookUps_0_hit(i_m7_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m7_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m7_lk1_vset),
    .io_lookUps_1_hit(i_m7_lk1_hit),
    .io_resp_valid(i_m7_resp_valid),
    .io_resp_bits_blkPaddr(i_m7_resp_paddr),
    .io_resp_bits_vSetIdx(i_m7_resp_vset),
    .io_resp_bits_way(i_m7_resp_way),
    .io_victimWay(m7_victim)
  );
  wire [113:0] g_m7_out =
    {g_m7_wfiSafe, g_m7_req_ready, g_m7_acq_valid, g_m7_acq_addr, g_m7_acq_vset,
     g_m7_lk0_hit, g_m7_lk1_hit, g_m7_resp_valid, g_m7_resp_paddr, g_m7_resp_vset, g_m7_resp_way};
  wire [113:0] i_m7_out =
    {i_m7_wfiSafe, i_m7_req_ready, i_m7_acq_valid, i_m7_acq_addr, i_m7_acq_vset,
     i_m7_lk0_hit, i_m7_lk1_hit, i_m7_resp_valid, i_m7_resp_paddr, i_m7_resp_vset, i_m7_resp_way};

  // ---- ICacheMSHR_8 (prefetchMSHRs_4, HAS_FLUSH=1) ----
  logic m8_fencei, m8_flush, m8_wfiReq, m8_invalid, m8_req_valid, m8_acq_ready;
  logic [41:0] m8_req_paddr, m8_lk0_paddr, m8_lk1_paddr;
  logic [7:0]  m8_req_vset,  m8_lk0_vset,  m8_lk1_vset;
  logic [1:0]  m8_victim;
  int m8_checks, m8_enq, m8_send, m8_hit, m8_resp, m8_unsafe, m8_kill, m8_inval;
  wire g_m8_wfiSafe, g_m8_req_ready, g_m8_acq_valid,
       g_m8_lk0_hit, g_m8_lk1_hit, g_m8_resp_valid;
  wire [47:0] g_m8_acq_addr;
  wire [7:0]  g_m8_acq_vset, g_m8_resp_vset;
  wire [41:0] g_m8_resp_paddr;
  wire [1:0]  g_m8_resp_way;
  wire i_m8_wfiSafe, i_m8_req_ready, i_m8_acq_valid,
       i_m8_lk0_hit, i_m8_lk1_hit, i_m8_resp_valid;
  wire [47:0] i_m8_acq_addr;
  wire [7:0]  i_m8_acq_vset, i_m8_resp_vset;
  wire [41:0] i_m8_resp_paddr;
  wire [1:0]  i_m8_resp_way;
  ICacheMSHR_8 u_g_m8 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m8_fencei),
    .io_flush(m8_flush),
    .io_wfi_wfiReq(m8_wfiReq),
    .io_wfi_wfiSafe(g_m8_wfiSafe),
    .io_invalid(m8_invalid),
    .io_req_ready(g_m8_req_ready),
    .io_req_valid(m8_req_valid),
    .io_req_bits_blkPaddr(m8_req_paddr),
    .io_req_bits_vSetIdx(m8_req_vset),
    .io_acquire_ready(m8_acq_ready),
    .io_acquire_valid(g_m8_acq_valid),
    .io_acquire_bits_acquire_address(g_m8_acq_addr),
    .io_acquire_bits_vSetIdx(g_m8_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m8_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m8_lk0_vset),
    .io_lookUps_0_hit(g_m8_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m8_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m8_lk1_vset),
    .io_lookUps_1_hit(g_m8_lk1_hit),
    .io_resp_valid(g_m8_resp_valid),
    .io_resp_bits_blkPaddr(g_m8_resp_paddr),
    .io_resp_bits_vSetIdx(g_m8_resp_vset),
    .io_resp_bits_way(g_m8_resp_way),
    .io_victimWay(m8_victim)
  );
  ICacheMSHR_8_xs u_i_m8 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m8_fencei),
    .io_flush(m8_flush),
    .io_wfi_wfiReq(m8_wfiReq),
    .io_wfi_wfiSafe(i_m8_wfiSafe),
    .io_invalid(m8_invalid),
    .io_req_ready(i_m8_req_ready),
    .io_req_valid(m8_req_valid),
    .io_req_bits_blkPaddr(m8_req_paddr),
    .io_req_bits_vSetIdx(m8_req_vset),
    .io_acquire_ready(m8_acq_ready),
    .io_acquire_valid(i_m8_acq_valid),
    .io_acquire_bits_acquire_address(i_m8_acq_addr),
    .io_acquire_bits_vSetIdx(i_m8_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m8_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m8_lk0_vset),
    .io_lookUps_0_hit(i_m8_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m8_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m8_lk1_vset),
    .io_lookUps_1_hit(i_m8_lk1_hit),
    .io_resp_valid(i_m8_resp_valid),
    .io_resp_bits_blkPaddr(i_m8_resp_paddr),
    .io_resp_bits_vSetIdx(i_m8_resp_vset),
    .io_resp_bits_way(i_m8_resp_way),
    .io_victimWay(m8_victim)
  );
  wire [113:0] g_m8_out =
    {g_m8_wfiSafe, g_m8_req_ready, g_m8_acq_valid, g_m8_acq_addr, g_m8_acq_vset,
     g_m8_lk0_hit, g_m8_lk1_hit, g_m8_resp_valid, g_m8_resp_paddr, g_m8_resp_vset, g_m8_resp_way};
  wire [113:0] i_m8_out =
    {i_m8_wfiSafe, i_m8_req_ready, i_m8_acq_valid, i_m8_acq_addr, i_m8_acq_vset,
     i_m8_lk0_hit, i_m8_lk1_hit, i_m8_resp_valid, i_m8_resp_paddr, i_m8_resp_vset, i_m8_resp_way};

  // ---- ICacheMSHR_9 (prefetchMSHRs_5, HAS_FLUSH=1) ----
  logic m9_fencei, m9_flush, m9_wfiReq, m9_invalid, m9_req_valid, m9_acq_ready;
  logic [41:0] m9_req_paddr, m9_lk0_paddr, m9_lk1_paddr;
  logic [7:0]  m9_req_vset,  m9_lk0_vset,  m9_lk1_vset;
  logic [1:0]  m9_victim;
  int m9_checks, m9_enq, m9_send, m9_hit, m9_resp, m9_unsafe, m9_kill, m9_inval;
  wire g_m9_wfiSafe, g_m9_req_ready, g_m9_acq_valid,
       g_m9_lk0_hit, g_m9_lk1_hit, g_m9_resp_valid;
  wire [47:0] g_m9_acq_addr;
  wire [7:0]  g_m9_acq_vset, g_m9_resp_vset;
  wire [41:0] g_m9_resp_paddr;
  wire [1:0]  g_m9_resp_way;
  wire i_m9_wfiSafe, i_m9_req_ready, i_m9_acq_valid,
       i_m9_lk0_hit, i_m9_lk1_hit, i_m9_resp_valid;
  wire [47:0] i_m9_acq_addr;
  wire [7:0]  i_m9_acq_vset, i_m9_resp_vset;
  wire [41:0] i_m9_resp_paddr;
  wire [1:0]  i_m9_resp_way;
  ICacheMSHR_9 u_g_m9 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m9_fencei),
    .io_flush(m9_flush),
    .io_wfi_wfiReq(m9_wfiReq),
    .io_wfi_wfiSafe(g_m9_wfiSafe),
    .io_invalid(m9_invalid),
    .io_req_ready(g_m9_req_ready),
    .io_req_valid(m9_req_valid),
    .io_req_bits_blkPaddr(m9_req_paddr),
    .io_req_bits_vSetIdx(m9_req_vset),
    .io_acquire_ready(m9_acq_ready),
    .io_acquire_valid(g_m9_acq_valid),
    .io_acquire_bits_acquire_address(g_m9_acq_addr),
    .io_acquire_bits_vSetIdx(g_m9_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m9_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m9_lk0_vset),
    .io_lookUps_0_hit(g_m9_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m9_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m9_lk1_vset),
    .io_lookUps_1_hit(g_m9_lk1_hit),
    .io_resp_valid(g_m9_resp_valid),
    .io_resp_bits_blkPaddr(g_m9_resp_paddr),
    .io_resp_bits_vSetIdx(g_m9_resp_vset),
    .io_resp_bits_way(g_m9_resp_way),
    .io_victimWay(m9_victim)
  );
  ICacheMSHR_9_xs u_i_m9 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m9_fencei),
    .io_flush(m9_flush),
    .io_wfi_wfiReq(m9_wfiReq),
    .io_wfi_wfiSafe(i_m9_wfiSafe),
    .io_invalid(m9_invalid),
    .io_req_ready(i_m9_req_ready),
    .io_req_valid(m9_req_valid),
    .io_req_bits_blkPaddr(m9_req_paddr),
    .io_req_bits_vSetIdx(m9_req_vset),
    .io_acquire_ready(m9_acq_ready),
    .io_acquire_valid(i_m9_acq_valid),
    .io_acquire_bits_acquire_address(i_m9_acq_addr),
    .io_acquire_bits_vSetIdx(i_m9_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m9_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m9_lk0_vset),
    .io_lookUps_0_hit(i_m9_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m9_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m9_lk1_vset),
    .io_lookUps_1_hit(i_m9_lk1_hit),
    .io_resp_valid(i_m9_resp_valid),
    .io_resp_bits_blkPaddr(i_m9_resp_paddr),
    .io_resp_bits_vSetIdx(i_m9_resp_vset),
    .io_resp_bits_way(i_m9_resp_way),
    .io_victimWay(m9_victim)
  );
  wire [113:0] g_m9_out =
    {g_m9_wfiSafe, g_m9_req_ready, g_m9_acq_valid, g_m9_acq_addr, g_m9_acq_vset,
     g_m9_lk0_hit, g_m9_lk1_hit, g_m9_resp_valid, g_m9_resp_paddr, g_m9_resp_vset, g_m9_resp_way};
  wire [113:0] i_m9_out =
    {i_m9_wfiSafe, i_m9_req_ready, i_m9_acq_valid, i_m9_acq_addr, i_m9_acq_vset,
     i_m9_lk0_hit, i_m9_lk1_hit, i_m9_resp_valid, i_m9_resp_paddr, i_m9_resp_vset, i_m9_resp_way};

  // ---- ICacheMSHR_10 (prefetchMSHRs_6, HAS_FLUSH=1) ----
  logic m10_fencei, m10_flush, m10_wfiReq, m10_invalid, m10_req_valid, m10_acq_ready;
  logic [41:0] m10_req_paddr, m10_lk0_paddr, m10_lk1_paddr;
  logic [7:0]  m10_req_vset,  m10_lk0_vset,  m10_lk1_vset;
  logic [1:0]  m10_victim;
  int m10_checks, m10_enq, m10_send, m10_hit, m10_resp, m10_unsafe, m10_kill, m10_inval;
  wire g_m10_wfiSafe, g_m10_req_ready, g_m10_acq_valid,
       g_m10_lk0_hit, g_m10_lk1_hit, g_m10_resp_valid;
  wire [47:0] g_m10_acq_addr;
  wire [7:0]  g_m10_acq_vset, g_m10_resp_vset;
  wire [41:0] g_m10_resp_paddr;
  wire [1:0]  g_m10_resp_way;
  wire i_m10_wfiSafe, i_m10_req_ready, i_m10_acq_valid,
       i_m10_lk0_hit, i_m10_lk1_hit, i_m10_resp_valid;
  wire [47:0] i_m10_acq_addr;
  wire [7:0]  i_m10_acq_vset, i_m10_resp_vset;
  wire [41:0] i_m10_resp_paddr;
  wire [1:0]  i_m10_resp_way;
  ICacheMSHR_10 u_g_m10 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m10_fencei),
    .io_flush(m10_flush),
    .io_wfi_wfiReq(m10_wfiReq),
    .io_wfi_wfiSafe(g_m10_wfiSafe),
    .io_invalid(m10_invalid),
    .io_req_ready(g_m10_req_ready),
    .io_req_valid(m10_req_valid),
    .io_req_bits_blkPaddr(m10_req_paddr),
    .io_req_bits_vSetIdx(m10_req_vset),
    .io_acquire_ready(m10_acq_ready),
    .io_acquire_valid(g_m10_acq_valid),
    .io_acquire_bits_acquire_address(g_m10_acq_addr),
    .io_acquire_bits_vSetIdx(g_m10_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m10_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m10_lk0_vset),
    .io_lookUps_0_hit(g_m10_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m10_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m10_lk1_vset),
    .io_lookUps_1_hit(g_m10_lk1_hit),
    .io_resp_valid(g_m10_resp_valid),
    .io_resp_bits_blkPaddr(g_m10_resp_paddr),
    .io_resp_bits_vSetIdx(g_m10_resp_vset),
    .io_resp_bits_way(g_m10_resp_way),
    .io_victimWay(m10_victim)
  );
  ICacheMSHR_10_xs u_i_m10 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m10_fencei),
    .io_flush(m10_flush),
    .io_wfi_wfiReq(m10_wfiReq),
    .io_wfi_wfiSafe(i_m10_wfiSafe),
    .io_invalid(m10_invalid),
    .io_req_ready(i_m10_req_ready),
    .io_req_valid(m10_req_valid),
    .io_req_bits_blkPaddr(m10_req_paddr),
    .io_req_bits_vSetIdx(m10_req_vset),
    .io_acquire_ready(m10_acq_ready),
    .io_acquire_valid(i_m10_acq_valid),
    .io_acquire_bits_acquire_address(i_m10_acq_addr),
    .io_acquire_bits_vSetIdx(i_m10_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m10_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m10_lk0_vset),
    .io_lookUps_0_hit(i_m10_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m10_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m10_lk1_vset),
    .io_lookUps_1_hit(i_m10_lk1_hit),
    .io_resp_valid(i_m10_resp_valid),
    .io_resp_bits_blkPaddr(i_m10_resp_paddr),
    .io_resp_bits_vSetIdx(i_m10_resp_vset),
    .io_resp_bits_way(i_m10_resp_way),
    .io_victimWay(m10_victim)
  );
  wire [113:0] g_m10_out =
    {g_m10_wfiSafe, g_m10_req_ready, g_m10_acq_valid, g_m10_acq_addr, g_m10_acq_vset,
     g_m10_lk0_hit, g_m10_lk1_hit, g_m10_resp_valid, g_m10_resp_paddr, g_m10_resp_vset, g_m10_resp_way};
  wire [113:0] i_m10_out =
    {i_m10_wfiSafe, i_m10_req_ready, i_m10_acq_valid, i_m10_acq_addr, i_m10_acq_vset,
     i_m10_lk0_hit, i_m10_lk1_hit, i_m10_resp_valid, i_m10_resp_paddr, i_m10_resp_vset, i_m10_resp_way};

  // ---- ICacheMSHR_11 (prefetchMSHRs_7, HAS_FLUSH=1) ----
  logic m11_fencei, m11_flush, m11_wfiReq, m11_invalid, m11_req_valid, m11_acq_ready;
  logic [41:0] m11_req_paddr, m11_lk0_paddr, m11_lk1_paddr;
  logic [7:0]  m11_req_vset,  m11_lk0_vset,  m11_lk1_vset;
  logic [1:0]  m11_victim;
  int m11_checks, m11_enq, m11_send, m11_hit, m11_resp, m11_unsafe, m11_kill, m11_inval;
  wire g_m11_wfiSafe, g_m11_req_ready, g_m11_acq_valid,
       g_m11_lk0_hit, g_m11_lk1_hit, g_m11_resp_valid;
  wire [47:0] g_m11_acq_addr;
  wire [7:0]  g_m11_acq_vset, g_m11_resp_vset;
  wire [41:0] g_m11_resp_paddr;
  wire [1:0]  g_m11_resp_way;
  wire i_m11_wfiSafe, i_m11_req_ready, i_m11_acq_valid,
       i_m11_lk0_hit, i_m11_lk1_hit, i_m11_resp_valid;
  wire [47:0] i_m11_acq_addr;
  wire [7:0]  i_m11_acq_vset, i_m11_resp_vset;
  wire [41:0] i_m11_resp_paddr;
  wire [1:0]  i_m11_resp_way;
  ICacheMSHR_11 u_g_m11 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m11_fencei),
    .io_flush(m11_flush),
    .io_wfi_wfiReq(m11_wfiReq),
    .io_wfi_wfiSafe(g_m11_wfiSafe),
    .io_invalid(m11_invalid),
    .io_req_ready(g_m11_req_ready),
    .io_req_valid(m11_req_valid),
    .io_req_bits_blkPaddr(m11_req_paddr),
    .io_req_bits_vSetIdx(m11_req_vset),
    .io_acquire_ready(m11_acq_ready),
    .io_acquire_valid(g_m11_acq_valid),
    .io_acquire_bits_acquire_address(g_m11_acq_addr),
    .io_acquire_bits_vSetIdx(g_m11_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m11_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m11_lk0_vset),
    .io_lookUps_0_hit(g_m11_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m11_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m11_lk1_vset),
    .io_lookUps_1_hit(g_m11_lk1_hit),
    .io_resp_valid(g_m11_resp_valid),
    .io_resp_bits_blkPaddr(g_m11_resp_paddr),
    .io_resp_bits_vSetIdx(g_m11_resp_vset),
    .io_resp_bits_way(g_m11_resp_way),
    .io_victimWay(m11_victim)
  );
  ICacheMSHR_11_xs u_i_m11 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m11_fencei),
    .io_flush(m11_flush),
    .io_wfi_wfiReq(m11_wfiReq),
    .io_wfi_wfiSafe(i_m11_wfiSafe),
    .io_invalid(m11_invalid),
    .io_req_ready(i_m11_req_ready),
    .io_req_valid(m11_req_valid),
    .io_req_bits_blkPaddr(m11_req_paddr),
    .io_req_bits_vSetIdx(m11_req_vset),
    .io_acquire_ready(m11_acq_ready),
    .io_acquire_valid(i_m11_acq_valid),
    .io_acquire_bits_acquire_address(i_m11_acq_addr),
    .io_acquire_bits_vSetIdx(i_m11_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m11_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m11_lk0_vset),
    .io_lookUps_0_hit(i_m11_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m11_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m11_lk1_vset),
    .io_lookUps_1_hit(i_m11_lk1_hit),
    .io_resp_valid(i_m11_resp_valid),
    .io_resp_bits_blkPaddr(i_m11_resp_paddr),
    .io_resp_bits_vSetIdx(i_m11_resp_vset),
    .io_resp_bits_way(i_m11_resp_way),
    .io_victimWay(m11_victim)
  );
  wire [113:0] g_m11_out =
    {g_m11_wfiSafe, g_m11_req_ready, g_m11_acq_valid, g_m11_acq_addr, g_m11_acq_vset,
     g_m11_lk0_hit, g_m11_lk1_hit, g_m11_resp_valid, g_m11_resp_paddr, g_m11_resp_vset, g_m11_resp_way};
  wire [113:0] i_m11_out =
    {i_m11_wfiSafe, i_m11_req_ready, i_m11_acq_valid, i_m11_acq_addr, i_m11_acq_vset,
     i_m11_lk0_hit, i_m11_lk1_hit, i_m11_resp_valid, i_m11_resp_paddr, i_m11_resp_vset, i_m11_resp_way};

  // ---- ICacheMSHR_12 (prefetchMSHRs_8, HAS_FLUSH=1) ----
  logic m12_fencei, m12_flush, m12_wfiReq, m12_invalid, m12_req_valid, m12_acq_ready;
  logic [41:0] m12_req_paddr, m12_lk0_paddr, m12_lk1_paddr;
  logic [7:0]  m12_req_vset,  m12_lk0_vset,  m12_lk1_vset;
  logic [1:0]  m12_victim;
  int m12_checks, m12_enq, m12_send, m12_hit, m12_resp, m12_unsafe, m12_kill, m12_inval;
  wire g_m12_wfiSafe, g_m12_req_ready, g_m12_acq_valid,
       g_m12_lk0_hit, g_m12_lk1_hit, g_m12_resp_valid;
  wire [47:0] g_m12_acq_addr;
  wire [7:0]  g_m12_acq_vset, g_m12_resp_vset;
  wire [41:0] g_m12_resp_paddr;
  wire [1:0]  g_m12_resp_way;
  wire i_m12_wfiSafe, i_m12_req_ready, i_m12_acq_valid,
       i_m12_lk0_hit, i_m12_lk1_hit, i_m12_resp_valid;
  wire [47:0] i_m12_acq_addr;
  wire [7:0]  i_m12_acq_vset, i_m12_resp_vset;
  wire [41:0] i_m12_resp_paddr;
  wire [1:0]  i_m12_resp_way;
  ICacheMSHR_12 u_g_m12 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m12_fencei),
    .io_flush(m12_flush),
    .io_wfi_wfiReq(m12_wfiReq),
    .io_wfi_wfiSafe(g_m12_wfiSafe),
    .io_invalid(m12_invalid),
    .io_req_ready(g_m12_req_ready),
    .io_req_valid(m12_req_valid),
    .io_req_bits_blkPaddr(m12_req_paddr),
    .io_req_bits_vSetIdx(m12_req_vset),
    .io_acquire_ready(m12_acq_ready),
    .io_acquire_valid(g_m12_acq_valid),
    .io_acquire_bits_acquire_address(g_m12_acq_addr),
    .io_acquire_bits_vSetIdx(g_m12_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m12_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m12_lk0_vset),
    .io_lookUps_0_hit(g_m12_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m12_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m12_lk1_vset),
    .io_lookUps_1_hit(g_m12_lk1_hit),
    .io_resp_valid(g_m12_resp_valid),
    .io_resp_bits_blkPaddr(g_m12_resp_paddr),
    .io_resp_bits_vSetIdx(g_m12_resp_vset),
    .io_resp_bits_way(g_m12_resp_way),
    .io_victimWay(m12_victim)
  );
  ICacheMSHR_12_xs u_i_m12 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m12_fencei),
    .io_flush(m12_flush),
    .io_wfi_wfiReq(m12_wfiReq),
    .io_wfi_wfiSafe(i_m12_wfiSafe),
    .io_invalid(m12_invalid),
    .io_req_ready(i_m12_req_ready),
    .io_req_valid(m12_req_valid),
    .io_req_bits_blkPaddr(m12_req_paddr),
    .io_req_bits_vSetIdx(m12_req_vset),
    .io_acquire_ready(m12_acq_ready),
    .io_acquire_valid(i_m12_acq_valid),
    .io_acquire_bits_acquire_address(i_m12_acq_addr),
    .io_acquire_bits_vSetIdx(i_m12_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m12_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m12_lk0_vset),
    .io_lookUps_0_hit(i_m12_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m12_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m12_lk1_vset),
    .io_lookUps_1_hit(i_m12_lk1_hit),
    .io_resp_valid(i_m12_resp_valid),
    .io_resp_bits_blkPaddr(i_m12_resp_paddr),
    .io_resp_bits_vSetIdx(i_m12_resp_vset),
    .io_resp_bits_way(i_m12_resp_way),
    .io_victimWay(m12_victim)
  );
  wire [113:0] g_m12_out =
    {g_m12_wfiSafe, g_m12_req_ready, g_m12_acq_valid, g_m12_acq_addr, g_m12_acq_vset,
     g_m12_lk0_hit, g_m12_lk1_hit, g_m12_resp_valid, g_m12_resp_paddr, g_m12_resp_vset, g_m12_resp_way};
  wire [113:0] i_m12_out =
    {i_m12_wfiSafe, i_m12_req_ready, i_m12_acq_valid, i_m12_acq_addr, i_m12_acq_vset,
     i_m12_lk0_hit, i_m12_lk1_hit, i_m12_resp_valid, i_m12_resp_paddr, i_m12_resp_vset, i_m12_resp_way};

  // ---- ICacheMSHR_13 (prefetchMSHRs_9, HAS_FLUSH=1) ----
  logic m13_fencei, m13_flush, m13_wfiReq, m13_invalid, m13_req_valid, m13_acq_ready;
  logic [41:0] m13_req_paddr, m13_lk0_paddr, m13_lk1_paddr;
  logic [7:0]  m13_req_vset,  m13_lk0_vset,  m13_lk1_vset;
  logic [1:0]  m13_victim;
  int m13_checks, m13_enq, m13_send, m13_hit, m13_resp, m13_unsafe, m13_kill, m13_inval;
  wire g_m13_wfiSafe, g_m13_req_ready, g_m13_acq_valid,
       g_m13_lk0_hit, g_m13_lk1_hit, g_m13_resp_valid;
  wire [47:0] g_m13_acq_addr;
  wire [7:0]  g_m13_acq_vset, g_m13_resp_vset;
  wire [41:0] g_m13_resp_paddr;
  wire [1:0]  g_m13_resp_way;
  wire i_m13_wfiSafe, i_m13_req_ready, i_m13_acq_valid,
       i_m13_lk0_hit, i_m13_lk1_hit, i_m13_resp_valid;
  wire [47:0] i_m13_acq_addr;
  wire [7:0]  i_m13_acq_vset, i_m13_resp_vset;
  wire [41:0] i_m13_resp_paddr;
  wire [1:0]  i_m13_resp_way;
  ICacheMSHR_13 u_g_m13 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m13_fencei),
    .io_flush(m13_flush),
    .io_wfi_wfiReq(m13_wfiReq),
    .io_wfi_wfiSafe(g_m13_wfiSafe),
    .io_invalid(m13_invalid),
    .io_req_ready(g_m13_req_ready),
    .io_req_valid(m13_req_valid),
    .io_req_bits_blkPaddr(m13_req_paddr),
    .io_req_bits_vSetIdx(m13_req_vset),
    .io_acquire_ready(m13_acq_ready),
    .io_acquire_valid(g_m13_acq_valid),
    .io_acquire_bits_acquire_address(g_m13_acq_addr),
    .io_acquire_bits_vSetIdx(g_m13_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m13_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m13_lk0_vset),
    .io_lookUps_0_hit(g_m13_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m13_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m13_lk1_vset),
    .io_lookUps_1_hit(g_m13_lk1_hit),
    .io_resp_valid(g_m13_resp_valid),
    .io_resp_bits_blkPaddr(g_m13_resp_paddr),
    .io_resp_bits_vSetIdx(g_m13_resp_vset),
    .io_resp_bits_way(g_m13_resp_way),
    .io_victimWay(m13_victim)
  );
  ICacheMSHR_13_xs u_i_m13 (
    .clock(clock),
    .reset(reset),
    .io_fencei(m13_fencei),
    .io_flush(m13_flush),
    .io_wfi_wfiReq(m13_wfiReq),
    .io_wfi_wfiSafe(i_m13_wfiSafe),
    .io_invalid(m13_invalid),
    .io_req_ready(i_m13_req_ready),
    .io_req_valid(m13_req_valid),
    .io_req_bits_blkPaddr(m13_req_paddr),
    .io_req_bits_vSetIdx(m13_req_vset),
    .io_acquire_ready(m13_acq_ready),
    .io_acquire_valid(i_m13_acq_valid),
    .io_acquire_bits_acquire_address(i_m13_acq_addr),
    .io_acquire_bits_vSetIdx(i_m13_acq_vset),
    .io_lookUps_0_info_bits_blkPaddr(m13_lk0_paddr),
    .io_lookUps_0_info_bits_vSetIdx(m13_lk0_vset),
    .io_lookUps_0_hit(i_m13_lk0_hit),
    .io_lookUps_1_info_bits_blkPaddr(m13_lk1_paddr),
    .io_lookUps_1_info_bits_vSetIdx(m13_lk1_vset),
    .io_lookUps_1_hit(i_m13_lk1_hit),
    .io_resp_valid(i_m13_resp_valid),
    .io_resp_bits_blkPaddr(i_m13_resp_paddr),
    .io_resp_bits_vSetIdx(i_m13_resp_vset),
    .io_resp_bits_way(i_m13_resp_way),
    .io_victimWay(m13_victim)
  );
  wire [113:0] g_m13_out =
    {g_m13_wfiSafe, g_m13_req_ready, g_m13_acq_valid, g_m13_acq_addr, g_m13_acq_vset,
     g_m13_lk0_hit, g_m13_lk1_hit, g_m13_resp_valid, g_m13_resp_paddr, g_m13_resp_vset, g_m13_resp_way};
  wire [113:0] i_m13_out =
    {i_m13_wfiSafe, i_m13_req_ready, i_m13_acq_valid, i_m13_acq_addr, i_m13_acq_vset,
     i_m13_lk0_hit, i_m13_lk1_hit, i_m13_resp_valid, i_m13_resp_paddr, i_m13_resp_vset, i_m13_resp_way};


  function automatic int cov_short(string what, int n);
    if (n < COV_MIN) begin
      $display("COVERAGE FAIL: %s 只发生 %0d 次 (需 >= %0d)", what, n, COV_MIN);
      return 1;
    end
    return 0;
  endfunction

  task automatic drive_random_inputs();
    m0_fencei  = ($urandom_range(0, 63) == 0);
    m0_flush   = 1'b0;   // 取指变体 golden 没有这条端口
    m0_wfiReq  = ($urandom_range(0, 15) == 0);
    m0_invalid = ($urandom_range(0, 7) == 0);
    m0_req_valid = ($urandom_range(0, 9) < 6);
    m0_acq_ready = ($urandom_range(0, 9) < 6);
    m0_req_paddr = 42'($urandom_range(0, 3));
    m0_req_vset  = 8'($urandom_range(0, 1));
    m0_lk0_paddr = 42'($urandom_range(0, 3));
    m0_lk0_vset  = 8'($urandom_range(0, 1));
    m0_lk1_paddr = 42'($urandom_range(0, 3));
    m0_lk1_vset  = 8'($urandom_range(0, 1));
    m0_victim    = 2'($urandom);
    m1_fencei  = ($urandom_range(0, 63) == 0);
    m1_flush   = 1'b0;   // 取指变体 golden 没有这条端口
    m1_wfiReq  = ($urandom_range(0, 15) == 0);
    m1_invalid = ($urandom_range(0, 7) == 0);
    m1_req_valid = ($urandom_range(0, 9) < 6);
    m1_acq_ready = ($urandom_range(0, 9) < 6);
    m1_req_paddr = 42'($urandom_range(0, 3));
    m1_req_vset  = 8'($urandom_range(0, 1));
    m1_lk0_paddr = 42'($urandom_range(0, 3));
    m1_lk0_vset  = 8'($urandom_range(0, 1));
    m1_lk1_paddr = 42'($urandom_range(0, 3));
    m1_lk1_vset  = 8'($urandom_range(0, 1));
    m1_victim    = 2'($urandom);
    m2_fencei  = ($urandom_range(0, 63) == 0);
    m2_flush   = 1'b0;   // 取指变体 golden 没有这条端口
    m2_wfiReq  = ($urandom_range(0, 15) == 0);
    m2_invalid = ($urandom_range(0, 7) == 0);
    m2_req_valid = ($urandom_range(0, 9) < 6);
    m2_acq_ready = ($urandom_range(0, 9) < 6);
    m2_req_paddr = 42'($urandom_range(0, 3));
    m2_req_vset  = 8'($urandom_range(0, 1));
    m2_lk0_paddr = 42'($urandom_range(0, 3));
    m2_lk0_vset  = 8'($urandom_range(0, 1));
    m2_lk1_paddr = 42'($urandom_range(0, 3));
    m2_lk1_vset  = 8'($urandom_range(0, 1));
    m2_victim    = 2'($urandom);
    m3_fencei  = ($urandom_range(0, 63) == 0);
    m3_flush   = 1'b0;   // 取指变体 golden 没有这条端口
    m3_wfiReq  = ($urandom_range(0, 15) == 0);
    m3_invalid = ($urandom_range(0, 7) == 0);
    m3_req_valid = ($urandom_range(0, 9) < 6);
    m3_acq_ready = ($urandom_range(0, 9) < 6);
    m3_req_paddr = 42'($urandom_range(0, 3));
    m3_req_vset  = 8'($urandom_range(0, 1));
    m3_lk0_paddr = 42'($urandom_range(0, 3));
    m3_lk0_vset  = 8'($urandom_range(0, 1));
    m3_lk1_paddr = 42'($urandom_range(0, 3));
    m3_lk1_vset  = 8'($urandom_range(0, 1));
    m3_victim    = 2'($urandom);
    m4_fencei  = ($urandom_range(0, 63) == 0);
    m4_flush   = ($urandom_range(0, 47) == 0);
    m4_wfiReq  = ($urandom_range(0, 15) == 0);
    m4_invalid = ($urandom_range(0, 7) == 0);
    m4_req_valid = ($urandom_range(0, 9) < 6);
    m4_acq_ready = ($urandom_range(0, 9) < 6);
    m4_req_paddr = 42'($urandom_range(0, 3));
    m4_req_vset  = 8'($urandom_range(0, 1));
    m4_lk0_paddr = 42'($urandom_range(0, 3));
    m4_lk0_vset  = 8'($urandom_range(0, 1));
    m4_lk1_paddr = 42'($urandom_range(0, 3));
    m4_lk1_vset  = 8'($urandom_range(0, 1));
    m4_victim    = 2'($urandom);
    m5_fencei  = ($urandom_range(0, 63) == 0);
    m5_flush   = ($urandom_range(0, 47) == 0);
    m5_wfiReq  = ($urandom_range(0, 15) == 0);
    m5_invalid = ($urandom_range(0, 7) == 0);
    m5_req_valid = ($urandom_range(0, 9) < 6);
    m5_acq_ready = ($urandom_range(0, 9) < 6);
    m5_req_paddr = 42'($urandom_range(0, 3));
    m5_req_vset  = 8'($urandom_range(0, 1));
    m5_lk0_paddr = 42'($urandom_range(0, 3));
    m5_lk0_vset  = 8'($urandom_range(0, 1));
    m5_lk1_paddr = 42'($urandom_range(0, 3));
    m5_lk1_vset  = 8'($urandom_range(0, 1));
    m5_victim    = 2'($urandom);
    m6_fencei  = ($urandom_range(0, 63) == 0);
    m6_flush   = ($urandom_range(0, 47) == 0);
    m6_wfiReq  = ($urandom_range(0, 15) == 0);
    m6_invalid = ($urandom_range(0, 7) == 0);
    m6_req_valid = ($urandom_range(0, 9) < 6);
    m6_acq_ready = ($urandom_range(0, 9) < 6);
    m6_req_paddr = 42'($urandom_range(0, 3));
    m6_req_vset  = 8'($urandom_range(0, 1));
    m6_lk0_paddr = 42'($urandom_range(0, 3));
    m6_lk0_vset  = 8'($urandom_range(0, 1));
    m6_lk1_paddr = 42'($urandom_range(0, 3));
    m6_lk1_vset  = 8'($urandom_range(0, 1));
    m6_victim    = 2'($urandom);
    m7_fencei  = ($urandom_range(0, 63) == 0);
    m7_flush   = ($urandom_range(0, 47) == 0);
    m7_wfiReq  = ($urandom_range(0, 15) == 0);
    m7_invalid = ($urandom_range(0, 7) == 0);
    m7_req_valid = ($urandom_range(0, 9) < 6);
    m7_acq_ready = ($urandom_range(0, 9) < 6);
    m7_req_paddr = 42'($urandom_range(0, 3));
    m7_req_vset  = 8'($urandom_range(0, 1));
    m7_lk0_paddr = 42'($urandom_range(0, 3));
    m7_lk0_vset  = 8'($urandom_range(0, 1));
    m7_lk1_paddr = 42'($urandom_range(0, 3));
    m7_lk1_vset  = 8'($urandom_range(0, 1));
    m7_victim    = 2'($urandom);
    m8_fencei  = ($urandom_range(0, 63) == 0);
    m8_flush   = ($urandom_range(0, 47) == 0);
    m8_wfiReq  = ($urandom_range(0, 15) == 0);
    m8_invalid = ($urandom_range(0, 7) == 0);
    m8_req_valid = ($urandom_range(0, 9) < 6);
    m8_acq_ready = ($urandom_range(0, 9) < 6);
    m8_req_paddr = 42'($urandom_range(0, 3));
    m8_req_vset  = 8'($urandom_range(0, 1));
    m8_lk0_paddr = 42'($urandom_range(0, 3));
    m8_lk0_vset  = 8'($urandom_range(0, 1));
    m8_lk1_paddr = 42'($urandom_range(0, 3));
    m8_lk1_vset  = 8'($urandom_range(0, 1));
    m8_victim    = 2'($urandom);
    m9_fencei  = ($urandom_range(0, 63) == 0);
    m9_flush   = ($urandom_range(0, 47) == 0);
    m9_wfiReq  = ($urandom_range(0, 15) == 0);
    m9_invalid = ($urandom_range(0, 7) == 0);
    m9_req_valid = ($urandom_range(0, 9) < 6);
    m9_acq_ready = ($urandom_range(0, 9) < 6);
    m9_req_paddr = 42'($urandom_range(0, 3));
    m9_req_vset  = 8'($urandom_range(0, 1));
    m9_lk0_paddr = 42'($urandom_range(0, 3));
    m9_lk0_vset  = 8'($urandom_range(0, 1));
    m9_lk1_paddr = 42'($urandom_range(0, 3));
    m9_lk1_vset  = 8'($urandom_range(0, 1));
    m9_victim    = 2'($urandom);
    m10_fencei  = ($urandom_range(0, 63) == 0);
    m10_flush   = ($urandom_range(0, 47) == 0);
    m10_wfiReq  = ($urandom_range(0, 15) == 0);
    m10_invalid = ($urandom_range(0, 7) == 0);
    m10_req_valid = ($urandom_range(0, 9) < 6);
    m10_acq_ready = ($urandom_range(0, 9) < 6);
    m10_req_paddr = 42'($urandom_range(0, 3));
    m10_req_vset  = 8'($urandom_range(0, 1));
    m10_lk0_paddr = 42'($urandom_range(0, 3));
    m10_lk0_vset  = 8'($urandom_range(0, 1));
    m10_lk1_paddr = 42'($urandom_range(0, 3));
    m10_lk1_vset  = 8'($urandom_range(0, 1));
    m10_victim    = 2'($urandom);
    m11_fencei  = ($urandom_range(0, 63) == 0);
    m11_flush   = ($urandom_range(0, 47) == 0);
    m11_wfiReq  = ($urandom_range(0, 15) == 0);
    m11_invalid = ($urandom_range(0, 7) == 0);
    m11_req_valid = ($urandom_range(0, 9) < 6);
    m11_acq_ready = ($urandom_range(0, 9) < 6);
    m11_req_paddr = 42'($urandom_range(0, 3));
    m11_req_vset  = 8'($urandom_range(0, 1));
    m11_lk0_paddr = 42'($urandom_range(0, 3));
    m11_lk0_vset  = 8'($urandom_range(0, 1));
    m11_lk1_paddr = 42'($urandom_range(0, 3));
    m11_lk1_vset  = 8'($urandom_range(0, 1));
    m11_victim    = 2'($urandom);
    m12_fencei  = ($urandom_range(0, 63) == 0);
    m12_flush   = ($urandom_range(0, 47) == 0);
    m12_wfiReq  = ($urandom_range(0, 15) == 0);
    m12_invalid = ($urandom_range(0, 7) == 0);
    m12_req_valid = ($urandom_range(0, 9) < 6);
    m12_acq_ready = ($urandom_range(0, 9) < 6);
    m12_req_paddr = 42'($urandom_range(0, 3));
    m12_req_vset  = 8'($urandom_range(0, 1));
    m12_lk0_paddr = 42'($urandom_range(0, 3));
    m12_lk0_vset  = 8'($urandom_range(0, 1));
    m12_lk1_paddr = 42'($urandom_range(0, 3));
    m12_lk1_vset  = 8'($urandom_range(0, 1));
    m12_victim    = 2'($urandom);
    m13_fencei  = ($urandom_range(0, 63) == 0);
    m13_flush   = ($urandom_range(0, 47) == 0);
    m13_wfiReq  = ($urandom_range(0, 15) == 0);
    m13_invalid = ($urandom_range(0, 7) == 0);
    m13_req_valid = ($urandom_range(0, 9) < 6);
    m13_acq_ready = ($urandom_range(0, 9) < 6);
    m13_req_paddr = 42'($urandom_range(0, 3));
    m13_req_vset  = 8'($urandom_range(0, 1));
    m13_lk0_paddr = 42'($urandom_range(0, 3));
    m13_lk0_vset  = 8'($urandom_range(0, 1));
    m13_lk1_paddr = 42'($urandom_range(0, 3));
    m13_lk1_vset  = 8'($urandom_range(0, 1));
    m13_victim    = 2'($urandom);
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_m0_out)) begin
      checks++; m0_checks++;
      if (g_m0_req_ready & m0_req_valid) m0_enq++;
      if (m0_acq_ready & g_m0_acq_valid) m0_send++;
      if (g_m0_lk0_hit | g_m0_lk1_hit)   m0_hit++;
      if (g_m0_resp_valid)                m0_resp++;
      if (!g_m0_wfiSafe)                  m0_unsafe++;
      if (m0_fencei | m0_flush)          m0_kill++;
      if (m0_invalid & g_m0_resp_valid)  m0_inval++;
      if (g_m0_out !== i_m0_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH ICacheMSHR g=%0h i=%0h", $time, g_m0_out, i_m0_out);
      end
    end
    if (!$isunknown(g_m1_out)) begin
      checks++; m1_checks++;
      if (g_m1_req_ready & m1_req_valid) m1_enq++;
      if (m1_acq_ready & g_m1_acq_valid) m1_send++;
      if (g_m1_lk0_hit | g_m1_lk1_hit)   m1_hit++;
      if (g_m1_resp_valid)                m1_resp++;
      if (!g_m1_wfiSafe)                  m1_unsafe++;
      if (m1_fencei | m1_flush)          m1_kill++;
      if (m1_invalid & g_m1_resp_valid)  m1_inval++;
      if (g_m1_out !== i_m1_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH ICacheMSHR_1 g=%0h i=%0h", $time, g_m1_out, i_m1_out);
      end
    end
    if (!$isunknown(g_m2_out)) begin
      checks++; m2_checks++;
      if (g_m2_req_ready & m2_req_valid) m2_enq++;
      if (m2_acq_ready & g_m2_acq_valid) m2_send++;
      if (g_m2_lk0_hit | g_m2_lk1_hit)   m2_hit++;
      if (g_m2_resp_valid)                m2_resp++;
      if (!g_m2_wfiSafe)                  m2_unsafe++;
      if (m2_fencei | m2_flush)          m2_kill++;
      if (m2_invalid & g_m2_resp_valid)  m2_inval++;
      if (g_m2_out !== i_m2_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH ICacheMSHR_2 g=%0h i=%0h", $time, g_m2_out, i_m2_out);
      end
    end
    if (!$isunknown(g_m3_out)) begin
      checks++; m3_checks++;
      if (g_m3_req_ready & m3_req_valid) m3_enq++;
      if (m3_acq_ready & g_m3_acq_valid) m3_send++;
      if (g_m3_lk0_hit | g_m3_lk1_hit)   m3_hit++;
      if (g_m3_resp_valid)                m3_resp++;
      if (!g_m3_wfiSafe)                  m3_unsafe++;
      if (m3_fencei | m3_flush)          m3_kill++;
      if (m3_invalid & g_m3_resp_valid)  m3_inval++;
      if (g_m3_out !== i_m3_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH ICacheMSHR_3 g=%0h i=%0h", $time, g_m3_out, i_m3_out);
      end
    end
    if (!$isunknown(g_m4_out)) begin
      checks++; m4_checks++;
      if (g_m4_req_ready & m4_req_valid) m4_enq++;
      if (m4_acq_ready & g_m4_acq_valid) m4_send++;
      if (g_m4_lk0_hit | g_m4_lk1_hit)   m4_hit++;
      if (g_m4_resp_valid)                m4_resp++;
      if (!g_m4_wfiSafe)                  m4_unsafe++;
      if (m4_fencei | m4_flush)          m4_kill++;
      if (m4_invalid & g_m4_resp_valid)  m4_inval++;
      if (g_m4_out !== i_m4_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH ICacheMSHR_4 g=%0h i=%0h", $time, g_m4_out, i_m4_out);
      end
    end
    if (!$isunknown(g_m5_out)) begin
      checks++; m5_checks++;
      if (g_m5_req_ready & m5_req_valid) m5_enq++;
      if (m5_acq_ready & g_m5_acq_valid) m5_send++;
      if (g_m5_lk0_hit | g_m5_lk1_hit)   m5_hit++;
      if (g_m5_resp_valid)                m5_resp++;
      if (!g_m5_wfiSafe)                  m5_unsafe++;
      if (m5_fencei | m5_flush)          m5_kill++;
      if (m5_invalid & g_m5_resp_valid)  m5_inval++;
      if (g_m5_out !== i_m5_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH ICacheMSHR_5 g=%0h i=%0h", $time, g_m5_out, i_m5_out);
      end
    end
    if (!$isunknown(g_m6_out)) begin
      checks++; m6_checks++;
      if (g_m6_req_ready & m6_req_valid) m6_enq++;
      if (m6_acq_ready & g_m6_acq_valid) m6_send++;
      if (g_m6_lk0_hit | g_m6_lk1_hit)   m6_hit++;
      if (g_m6_resp_valid)                m6_resp++;
      if (!g_m6_wfiSafe)                  m6_unsafe++;
      if (m6_fencei | m6_flush)          m6_kill++;
      if (m6_invalid & g_m6_resp_valid)  m6_inval++;
      if (g_m6_out !== i_m6_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH ICacheMSHR_6 g=%0h i=%0h", $time, g_m6_out, i_m6_out);
      end
    end
    if (!$isunknown(g_m7_out)) begin
      checks++; m7_checks++;
      if (g_m7_req_ready & m7_req_valid) m7_enq++;
      if (m7_acq_ready & g_m7_acq_valid) m7_send++;
      if (g_m7_lk0_hit | g_m7_lk1_hit)   m7_hit++;
      if (g_m7_resp_valid)                m7_resp++;
      if (!g_m7_wfiSafe)                  m7_unsafe++;
      if (m7_fencei | m7_flush)          m7_kill++;
      if (m7_invalid & g_m7_resp_valid)  m7_inval++;
      if (g_m7_out !== i_m7_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH ICacheMSHR_7 g=%0h i=%0h", $time, g_m7_out, i_m7_out);
      end
    end
    if (!$isunknown(g_m8_out)) begin
      checks++; m8_checks++;
      if (g_m8_req_ready & m8_req_valid) m8_enq++;
      if (m8_acq_ready & g_m8_acq_valid) m8_send++;
      if (g_m8_lk0_hit | g_m8_lk1_hit)   m8_hit++;
      if (g_m8_resp_valid)                m8_resp++;
      if (!g_m8_wfiSafe)                  m8_unsafe++;
      if (m8_fencei | m8_flush)          m8_kill++;
      if (m8_invalid & g_m8_resp_valid)  m8_inval++;
      if (g_m8_out !== i_m8_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH ICacheMSHR_8 g=%0h i=%0h", $time, g_m8_out, i_m8_out);
      end
    end
    if (!$isunknown(g_m9_out)) begin
      checks++; m9_checks++;
      if (g_m9_req_ready & m9_req_valid) m9_enq++;
      if (m9_acq_ready & g_m9_acq_valid) m9_send++;
      if (g_m9_lk0_hit | g_m9_lk1_hit)   m9_hit++;
      if (g_m9_resp_valid)                m9_resp++;
      if (!g_m9_wfiSafe)                  m9_unsafe++;
      if (m9_fencei | m9_flush)          m9_kill++;
      if (m9_invalid & g_m9_resp_valid)  m9_inval++;
      if (g_m9_out !== i_m9_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH ICacheMSHR_9 g=%0h i=%0h", $time, g_m9_out, i_m9_out);
      end
    end
    if (!$isunknown(g_m10_out)) begin
      checks++; m10_checks++;
      if (g_m10_req_ready & m10_req_valid) m10_enq++;
      if (m10_acq_ready & g_m10_acq_valid) m10_send++;
      if (g_m10_lk0_hit | g_m10_lk1_hit)   m10_hit++;
      if (g_m10_resp_valid)                m10_resp++;
      if (!g_m10_wfiSafe)                  m10_unsafe++;
      if (m10_fencei | m10_flush)          m10_kill++;
      if (m10_invalid & g_m10_resp_valid)  m10_inval++;
      if (g_m10_out !== i_m10_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH ICacheMSHR_10 g=%0h i=%0h", $time, g_m10_out, i_m10_out);
      end
    end
    if (!$isunknown(g_m11_out)) begin
      checks++; m11_checks++;
      if (g_m11_req_ready & m11_req_valid) m11_enq++;
      if (m11_acq_ready & g_m11_acq_valid) m11_send++;
      if (g_m11_lk0_hit | g_m11_lk1_hit)   m11_hit++;
      if (g_m11_resp_valid)                m11_resp++;
      if (!g_m11_wfiSafe)                  m11_unsafe++;
      if (m11_fencei | m11_flush)          m11_kill++;
      if (m11_invalid & g_m11_resp_valid)  m11_inval++;
      if (g_m11_out !== i_m11_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH ICacheMSHR_11 g=%0h i=%0h", $time, g_m11_out, i_m11_out);
      end
    end
    if (!$isunknown(g_m12_out)) begin
      checks++; m12_checks++;
      if (g_m12_req_ready & m12_req_valid) m12_enq++;
      if (m12_acq_ready & g_m12_acq_valid) m12_send++;
      if (g_m12_lk0_hit | g_m12_lk1_hit)   m12_hit++;
      if (g_m12_resp_valid)                m12_resp++;
      if (!g_m12_wfiSafe)                  m12_unsafe++;
      if (m12_fencei | m12_flush)          m12_kill++;
      if (m12_invalid & g_m12_resp_valid)  m12_inval++;
      if (g_m12_out !== i_m12_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH ICacheMSHR_12 g=%0h i=%0h", $time, g_m12_out, i_m12_out);
      end
    end
    if (!$isunknown(g_m13_out)) begin
      checks++; m13_checks++;
      if (g_m13_req_ready & m13_req_valid) m13_enq++;
      if (m13_acq_ready & g_m13_acq_valid) m13_send++;
      if (g_m13_lk0_hit | g_m13_lk1_hit)   m13_hit++;
      if (g_m13_resp_valid)                m13_resp++;
      if (!g_m13_wfiSafe)                  m13_unsafe++;
      if (m13_fencei | m13_flush)          m13_kill++;
      if (m13_invalid & g_m13_resp_valid)  m13_inval++;
      if (g_m13_out !== i_m13_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH ICacheMSHR_13 g=%0h i=%0h", $time, g_m13_out, i_m13_out);
      end
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    reset = 1'b1;
    m0_fencei = 0; m0_flush = 0; m0_wfiReq = 0; m0_invalid = 0;
    m0_req_valid = 0; m0_acq_ready = 0; m0_req_paddr = '0;
    m0_req_vset = '0; m0_lk0_paddr = '0; m0_lk0_vset = '0;
    m0_lk1_paddr = '0; m0_lk1_vset = '0; m0_victim = '0;
    m0_checks = 0; m0_enq = 0; m0_send = 0; m0_hit = 0;
    m0_resp = 0; m0_unsafe = 0; m0_kill = 0; m0_inval = 0;
    m1_fencei = 0; m1_flush = 0; m1_wfiReq = 0; m1_invalid = 0;
    m1_req_valid = 0; m1_acq_ready = 0; m1_req_paddr = '0;
    m1_req_vset = '0; m1_lk0_paddr = '0; m1_lk0_vset = '0;
    m1_lk1_paddr = '0; m1_lk1_vset = '0; m1_victim = '0;
    m1_checks = 0; m1_enq = 0; m1_send = 0; m1_hit = 0;
    m1_resp = 0; m1_unsafe = 0; m1_kill = 0; m1_inval = 0;
    m2_fencei = 0; m2_flush = 0; m2_wfiReq = 0; m2_invalid = 0;
    m2_req_valid = 0; m2_acq_ready = 0; m2_req_paddr = '0;
    m2_req_vset = '0; m2_lk0_paddr = '0; m2_lk0_vset = '0;
    m2_lk1_paddr = '0; m2_lk1_vset = '0; m2_victim = '0;
    m2_checks = 0; m2_enq = 0; m2_send = 0; m2_hit = 0;
    m2_resp = 0; m2_unsafe = 0; m2_kill = 0; m2_inval = 0;
    m3_fencei = 0; m3_flush = 0; m3_wfiReq = 0; m3_invalid = 0;
    m3_req_valid = 0; m3_acq_ready = 0; m3_req_paddr = '0;
    m3_req_vset = '0; m3_lk0_paddr = '0; m3_lk0_vset = '0;
    m3_lk1_paddr = '0; m3_lk1_vset = '0; m3_victim = '0;
    m3_checks = 0; m3_enq = 0; m3_send = 0; m3_hit = 0;
    m3_resp = 0; m3_unsafe = 0; m3_kill = 0; m3_inval = 0;
    m4_fencei = 0; m4_flush = 0; m4_wfiReq = 0; m4_invalid = 0;
    m4_req_valid = 0; m4_acq_ready = 0; m4_req_paddr = '0;
    m4_req_vset = '0; m4_lk0_paddr = '0; m4_lk0_vset = '0;
    m4_lk1_paddr = '0; m4_lk1_vset = '0; m4_victim = '0;
    m4_checks = 0; m4_enq = 0; m4_send = 0; m4_hit = 0;
    m4_resp = 0; m4_unsafe = 0; m4_kill = 0; m4_inval = 0;
    m5_fencei = 0; m5_flush = 0; m5_wfiReq = 0; m5_invalid = 0;
    m5_req_valid = 0; m5_acq_ready = 0; m5_req_paddr = '0;
    m5_req_vset = '0; m5_lk0_paddr = '0; m5_lk0_vset = '0;
    m5_lk1_paddr = '0; m5_lk1_vset = '0; m5_victim = '0;
    m5_checks = 0; m5_enq = 0; m5_send = 0; m5_hit = 0;
    m5_resp = 0; m5_unsafe = 0; m5_kill = 0; m5_inval = 0;
    m6_fencei = 0; m6_flush = 0; m6_wfiReq = 0; m6_invalid = 0;
    m6_req_valid = 0; m6_acq_ready = 0; m6_req_paddr = '0;
    m6_req_vset = '0; m6_lk0_paddr = '0; m6_lk0_vset = '0;
    m6_lk1_paddr = '0; m6_lk1_vset = '0; m6_victim = '0;
    m6_checks = 0; m6_enq = 0; m6_send = 0; m6_hit = 0;
    m6_resp = 0; m6_unsafe = 0; m6_kill = 0; m6_inval = 0;
    m7_fencei = 0; m7_flush = 0; m7_wfiReq = 0; m7_invalid = 0;
    m7_req_valid = 0; m7_acq_ready = 0; m7_req_paddr = '0;
    m7_req_vset = '0; m7_lk0_paddr = '0; m7_lk0_vset = '0;
    m7_lk1_paddr = '0; m7_lk1_vset = '0; m7_victim = '0;
    m7_checks = 0; m7_enq = 0; m7_send = 0; m7_hit = 0;
    m7_resp = 0; m7_unsafe = 0; m7_kill = 0; m7_inval = 0;
    m8_fencei = 0; m8_flush = 0; m8_wfiReq = 0; m8_invalid = 0;
    m8_req_valid = 0; m8_acq_ready = 0; m8_req_paddr = '0;
    m8_req_vset = '0; m8_lk0_paddr = '0; m8_lk0_vset = '0;
    m8_lk1_paddr = '0; m8_lk1_vset = '0; m8_victim = '0;
    m8_checks = 0; m8_enq = 0; m8_send = 0; m8_hit = 0;
    m8_resp = 0; m8_unsafe = 0; m8_kill = 0; m8_inval = 0;
    m9_fencei = 0; m9_flush = 0; m9_wfiReq = 0; m9_invalid = 0;
    m9_req_valid = 0; m9_acq_ready = 0; m9_req_paddr = '0;
    m9_req_vset = '0; m9_lk0_paddr = '0; m9_lk0_vset = '0;
    m9_lk1_paddr = '0; m9_lk1_vset = '0; m9_victim = '0;
    m9_checks = 0; m9_enq = 0; m9_send = 0; m9_hit = 0;
    m9_resp = 0; m9_unsafe = 0; m9_kill = 0; m9_inval = 0;
    m10_fencei = 0; m10_flush = 0; m10_wfiReq = 0; m10_invalid = 0;
    m10_req_valid = 0; m10_acq_ready = 0; m10_req_paddr = '0;
    m10_req_vset = '0; m10_lk0_paddr = '0; m10_lk0_vset = '0;
    m10_lk1_paddr = '0; m10_lk1_vset = '0; m10_victim = '0;
    m10_checks = 0; m10_enq = 0; m10_send = 0; m10_hit = 0;
    m10_resp = 0; m10_unsafe = 0; m10_kill = 0; m10_inval = 0;
    m11_fencei = 0; m11_flush = 0; m11_wfiReq = 0; m11_invalid = 0;
    m11_req_valid = 0; m11_acq_ready = 0; m11_req_paddr = '0;
    m11_req_vset = '0; m11_lk0_paddr = '0; m11_lk0_vset = '0;
    m11_lk1_paddr = '0; m11_lk1_vset = '0; m11_victim = '0;
    m11_checks = 0; m11_enq = 0; m11_send = 0; m11_hit = 0;
    m11_resp = 0; m11_unsafe = 0; m11_kill = 0; m11_inval = 0;
    m12_fencei = 0; m12_flush = 0; m12_wfiReq = 0; m12_invalid = 0;
    m12_req_valid = 0; m12_acq_ready = 0; m12_req_paddr = '0;
    m12_req_vset = '0; m12_lk0_paddr = '0; m12_lk0_vset = '0;
    m12_lk1_paddr = '0; m12_lk1_vset = '0; m12_victim = '0;
    m12_checks = 0; m12_enq = 0; m12_send = 0; m12_hit = 0;
    m12_resp = 0; m12_unsafe = 0; m12_kill = 0; m12_inval = 0;
    m13_fencei = 0; m13_flush = 0; m13_wfiReq = 0; m13_invalid = 0;
    m13_req_valid = 0; m13_acq_ready = 0; m13_req_paddr = '0;
    m13_req_vset = '0; m13_lk0_paddr = '0; m13_lk0_vset = '0;
    m13_lk1_paddr = '0; m13_lk1_vset = '0; m13_victim = '0;
    m13_checks = 0; m13_enq = 0; m13_send = 0; m13_hit = 0;
    m13_resp = 0; m13_unsafe = 0; m13_kill = 0; m13_inval = 0;
    repeat (4) @(negedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();   // 先换激励
      #1 check_outputs();      // 组合输出已稳定；此刻的输入就是 posedge 要采样的那一份
      @(posedge clock);
      // 异步复位偶尔脉冲一下：golden 是 posedge reset 异步复位，这条路径必须走到
      if ($urandom_range(0, 4999) == 0) begin
        reset = 1'b1;
        #1 reset = 1'b0;
      end
    end
    $display("ICacheMSHR family checks=%0d errors=%0d", checks, errors);
    $display("  ICacheMSHR: checks=%0d enq=%0d send=%0d hit=%0d resp=%0d unsafe=%0d kill=%0d inval=%0d",
             m0_checks, m0_enq, m0_send, m0_hit, m0_resp, m0_unsafe, m0_kill, m0_inval);
    cov_fail += cov_short("ICacheMSHR checks", m0_checks)
              + cov_short("ICacheMSHR enq",    m0_enq)
              + cov_short("ICacheMSHR send",   m0_send)
              + cov_short("ICacheMSHR hit",    m0_hit)
              + cov_short("ICacheMSHR resp",   m0_resp)
              + cov_short("ICacheMSHR unsafe", m0_unsafe)
              + cov_short("ICacheMSHR kill",   m0_kill)
              + cov_short("ICacheMSHR inval",  m0_inval);
    $display("  ICacheMSHR_1: checks=%0d enq=%0d send=%0d hit=%0d resp=%0d unsafe=%0d kill=%0d inval=%0d",
             m1_checks, m1_enq, m1_send, m1_hit, m1_resp, m1_unsafe, m1_kill, m1_inval);
    cov_fail += cov_short("ICacheMSHR_1 checks", m1_checks)
              + cov_short("ICacheMSHR_1 enq",    m1_enq)
              + cov_short("ICacheMSHR_1 send",   m1_send)
              + cov_short("ICacheMSHR_1 hit",    m1_hit)
              + cov_short("ICacheMSHR_1 resp",   m1_resp)
              + cov_short("ICacheMSHR_1 unsafe", m1_unsafe)
              + cov_short("ICacheMSHR_1 kill",   m1_kill)
              + cov_short("ICacheMSHR_1 inval",  m1_inval);
    $display("  ICacheMSHR_2: checks=%0d enq=%0d send=%0d hit=%0d resp=%0d unsafe=%0d kill=%0d inval=%0d",
             m2_checks, m2_enq, m2_send, m2_hit, m2_resp, m2_unsafe, m2_kill, m2_inval);
    cov_fail += cov_short("ICacheMSHR_2 checks", m2_checks)
              + cov_short("ICacheMSHR_2 enq",    m2_enq)
              + cov_short("ICacheMSHR_2 send",   m2_send)
              + cov_short("ICacheMSHR_2 hit",    m2_hit)
              + cov_short("ICacheMSHR_2 resp",   m2_resp)
              + cov_short("ICacheMSHR_2 unsafe", m2_unsafe)
              + cov_short("ICacheMSHR_2 kill",   m2_kill)
              + cov_short("ICacheMSHR_2 inval",  m2_inval);
    $display("  ICacheMSHR_3: checks=%0d enq=%0d send=%0d hit=%0d resp=%0d unsafe=%0d kill=%0d inval=%0d",
             m3_checks, m3_enq, m3_send, m3_hit, m3_resp, m3_unsafe, m3_kill, m3_inval);
    cov_fail += cov_short("ICacheMSHR_3 checks", m3_checks)
              + cov_short("ICacheMSHR_3 enq",    m3_enq)
              + cov_short("ICacheMSHR_3 send",   m3_send)
              + cov_short("ICacheMSHR_3 hit",    m3_hit)
              + cov_short("ICacheMSHR_3 resp",   m3_resp)
              + cov_short("ICacheMSHR_3 unsafe", m3_unsafe)
              + cov_short("ICacheMSHR_3 kill",   m3_kill)
              + cov_short("ICacheMSHR_3 inval",  m3_inval);
    $display("  ICacheMSHR_4: checks=%0d enq=%0d send=%0d hit=%0d resp=%0d unsafe=%0d kill=%0d inval=%0d",
             m4_checks, m4_enq, m4_send, m4_hit, m4_resp, m4_unsafe, m4_kill, m4_inval);
    cov_fail += cov_short("ICacheMSHR_4 checks", m4_checks)
              + cov_short("ICacheMSHR_4 enq",    m4_enq)
              + cov_short("ICacheMSHR_4 send",   m4_send)
              + cov_short("ICacheMSHR_4 hit",    m4_hit)
              + cov_short("ICacheMSHR_4 resp",   m4_resp)
              + cov_short("ICacheMSHR_4 unsafe", m4_unsafe)
              + cov_short("ICacheMSHR_4 kill",   m4_kill)
              + cov_short("ICacheMSHR_4 inval",  m4_inval);
    $display("  ICacheMSHR_5: checks=%0d enq=%0d send=%0d hit=%0d resp=%0d unsafe=%0d kill=%0d inval=%0d",
             m5_checks, m5_enq, m5_send, m5_hit, m5_resp, m5_unsafe, m5_kill, m5_inval);
    cov_fail += cov_short("ICacheMSHR_5 checks", m5_checks)
              + cov_short("ICacheMSHR_5 enq",    m5_enq)
              + cov_short("ICacheMSHR_5 send",   m5_send)
              + cov_short("ICacheMSHR_5 hit",    m5_hit)
              + cov_short("ICacheMSHR_5 resp",   m5_resp)
              + cov_short("ICacheMSHR_5 unsafe", m5_unsafe)
              + cov_short("ICacheMSHR_5 kill",   m5_kill)
              + cov_short("ICacheMSHR_5 inval",  m5_inval);
    $display("  ICacheMSHR_6: checks=%0d enq=%0d send=%0d hit=%0d resp=%0d unsafe=%0d kill=%0d inval=%0d",
             m6_checks, m6_enq, m6_send, m6_hit, m6_resp, m6_unsafe, m6_kill, m6_inval);
    cov_fail += cov_short("ICacheMSHR_6 checks", m6_checks)
              + cov_short("ICacheMSHR_6 enq",    m6_enq)
              + cov_short("ICacheMSHR_6 send",   m6_send)
              + cov_short("ICacheMSHR_6 hit",    m6_hit)
              + cov_short("ICacheMSHR_6 resp",   m6_resp)
              + cov_short("ICacheMSHR_6 unsafe", m6_unsafe)
              + cov_short("ICacheMSHR_6 kill",   m6_kill)
              + cov_short("ICacheMSHR_6 inval",  m6_inval);
    $display("  ICacheMSHR_7: checks=%0d enq=%0d send=%0d hit=%0d resp=%0d unsafe=%0d kill=%0d inval=%0d",
             m7_checks, m7_enq, m7_send, m7_hit, m7_resp, m7_unsafe, m7_kill, m7_inval);
    cov_fail += cov_short("ICacheMSHR_7 checks", m7_checks)
              + cov_short("ICacheMSHR_7 enq",    m7_enq)
              + cov_short("ICacheMSHR_7 send",   m7_send)
              + cov_short("ICacheMSHR_7 hit",    m7_hit)
              + cov_short("ICacheMSHR_7 resp",   m7_resp)
              + cov_short("ICacheMSHR_7 unsafe", m7_unsafe)
              + cov_short("ICacheMSHR_7 kill",   m7_kill)
              + cov_short("ICacheMSHR_7 inval",  m7_inval);
    $display("  ICacheMSHR_8: checks=%0d enq=%0d send=%0d hit=%0d resp=%0d unsafe=%0d kill=%0d inval=%0d",
             m8_checks, m8_enq, m8_send, m8_hit, m8_resp, m8_unsafe, m8_kill, m8_inval);
    cov_fail += cov_short("ICacheMSHR_8 checks", m8_checks)
              + cov_short("ICacheMSHR_8 enq",    m8_enq)
              + cov_short("ICacheMSHR_8 send",   m8_send)
              + cov_short("ICacheMSHR_8 hit",    m8_hit)
              + cov_short("ICacheMSHR_8 resp",   m8_resp)
              + cov_short("ICacheMSHR_8 unsafe", m8_unsafe)
              + cov_short("ICacheMSHR_8 kill",   m8_kill)
              + cov_short("ICacheMSHR_8 inval",  m8_inval);
    $display("  ICacheMSHR_9: checks=%0d enq=%0d send=%0d hit=%0d resp=%0d unsafe=%0d kill=%0d inval=%0d",
             m9_checks, m9_enq, m9_send, m9_hit, m9_resp, m9_unsafe, m9_kill, m9_inval);
    cov_fail += cov_short("ICacheMSHR_9 checks", m9_checks)
              + cov_short("ICacheMSHR_9 enq",    m9_enq)
              + cov_short("ICacheMSHR_9 send",   m9_send)
              + cov_short("ICacheMSHR_9 hit",    m9_hit)
              + cov_short("ICacheMSHR_9 resp",   m9_resp)
              + cov_short("ICacheMSHR_9 unsafe", m9_unsafe)
              + cov_short("ICacheMSHR_9 kill",   m9_kill)
              + cov_short("ICacheMSHR_9 inval",  m9_inval);
    $display("  ICacheMSHR_10: checks=%0d enq=%0d send=%0d hit=%0d resp=%0d unsafe=%0d kill=%0d inval=%0d",
             m10_checks, m10_enq, m10_send, m10_hit, m10_resp, m10_unsafe, m10_kill, m10_inval);
    cov_fail += cov_short("ICacheMSHR_10 checks", m10_checks)
              + cov_short("ICacheMSHR_10 enq",    m10_enq)
              + cov_short("ICacheMSHR_10 send",   m10_send)
              + cov_short("ICacheMSHR_10 hit",    m10_hit)
              + cov_short("ICacheMSHR_10 resp",   m10_resp)
              + cov_short("ICacheMSHR_10 unsafe", m10_unsafe)
              + cov_short("ICacheMSHR_10 kill",   m10_kill)
              + cov_short("ICacheMSHR_10 inval",  m10_inval);
    $display("  ICacheMSHR_11: checks=%0d enq=%0d send=%0d hit=%0d resp=%0d unsafe=%0d kill=%0d inval=%0d",
             m11_checks, m11_enq, m11_send, m11_hit, m11_resp, m11_unsafe, m11_kill, m11_inval);
    cov_fail += cov_short("ICacheMSHR_11 checks", m11_checks)
              + cov_short("ICacheMSHR_11 enq",    m11_enq)
              + cov_short("ICacheMSHR_11 send",   m11_send)
              + cov_short("ICacheMSHR_11 hit",    m11_hit)
              + cov_short("ICacheMSHR_11 resp",   m11_resp)
              + cov_short("ICacheMSHR_11 unsafe", m11_unsafe)
              + cov_short("ICacheMSHR_11 kill",   m11_kill)
              + cov_short("ICacheMSHR_11 inval",  m11_inval);
    $display("  ICacheMSHR_12: checks=%0d enq=%0d send=%0d hit=%0d resp=%0d unsafe=%0d kill=%0d inval=%0d",
             m12_checks, m12_enq, m12_send, m12_hit, m12_resp, m12_unsafe, m12_kill, m12_inval);
    cov_fail += cov_short("ICacheMSHR_12 checks", m12_checks)
              + cov_short("ICacheMSHR_12 enq",    m12_enq)
              + cov_short("ICacheMSHR_12 send",   m12_send)
              + cov_short("ICacheMSHR_12 hit",    m12_hit)
              + cov_short("ICacheMSHR_12 resp",   m12_resp)
              + cov_short("ICacheMSHR_12 unsafe", m12_unsafe)
              + cov_short("ICacheMSHR_12 kill",   m12_kill)
              + cov_short("ICacheMSHR_12 inval",  m12_inval);
    $display("  ICacheMSHR_13: checks=%0d enq=%0d send=%0d hit=%0d resp=%0d unsafe=%0d kill=%0d inval=%0d",
             m13_checks, m13_enq, m13_send, m13_hit, m13_resp, m13_unsafe, m13_kill, m13_inval);
    cov_fail += cov_short("ICacheMSHR_13 checks", m13_checks)
              + cov_short("ICacheMSHR_13 enq",    m13_enq)
              + cov_short("ICacheMSHR_13 send",   m13_send)
              + cov_short("ICacheMSHR_13 hit",    m13_hit)
              + cov_short("ICacheMSHR_13 resp",   m13_resp)
              + cov_short("ICacheMSHR_13 unsafe", m13_unsafe)
              + cov_short("ICacheMSHR_13 kill",   m13_kill)
              + cov_short("ICacheMSHR_13 inval",  m13_inval);
    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%0d cov_fail=%0d)", errors, cov_fail);
    $fatal(1);
  end
endmodule
