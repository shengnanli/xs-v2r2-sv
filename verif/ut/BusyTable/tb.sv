// =============================================================================
// BusyTable 家族 UT：五个 KunminghuV2 单态化变体各一对 DUT（golden <M> 对重写
// <M>_xs），共享时钟/复位，各自独立随机激励，逐拍比对**全部**输出端口。
//
// ★ 激励为什么不是「每个输入独立均匀随机」★
// 忙位表的判别力全在「同一个 preg 上多个事件撞车」：分配与写回同拍撞、快速唤醒被
// og0Cancel 打掉、load 唤醒两拍后被 ld2Cancel 撤销、读口撞上本拍的分配旁路。
// preg 索引 8 位、表深最大 224 —— 六路分配 × 八路写回全均匀随机的话，两路撞同一项
// 的概率低到 200k 拍也凑不出几次，那样的 errors=0 什么都没验到。
// 所以 preg 取值按三段分布（rand_preg）：
//   60% 落在 0..7 的密集池   → 制造撞车（含 Int 表的 0 号项特判）
//   25% 落在 0..NUM_PREGS-1  → 覆盖整张表
//   15% 全 8 位随机          → 制造**越界**读（BusyTable_3 只有 22 项，越界是常态）
// loadDependency 激励同理偏置：一半给 0，另一半偏向最高位置起（正好落在取消窗口）。
//
// ★ 覆盖证据 ★
// tb 统计若干「有判别力的事件」计数（见 $display 的 COVERAGE 段），任何一项为 0
// 都说明对应机制根本没被激励到，这一轮 errors=0 不作数。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  bit  clk = 0;
  logic rst;
  int errors = 0;
  longint checks = 0;

  always #5 clk = ~clk;

  // 三段分布的 preg 取值：密集池制造撞车，全 8 位随机制造越界。
  function automatic logic [7:0] rand_preg(input int unsigned num_pregs);
    int unsigned r = $urandom_range(0, 99);
    if (r < 60)      return 8'($urandom_range(0, 7));
    else if (r < 85) return 8'($urandom_range(0, num_pregs - 1));
    else             return 8'($urandom);
  endfunction

  // loadDependency 激励：一半 0，其余偏向最高位置起（= 正处在 ld2Cancel 窗口里）。
  function automatic logic [1:0] rand_dep();
    int unsigned r = $urandom_range(0, 99);
    if (r < 50) return 2'b00;
    else if (r < 80) return 2'b10;
    else return 2'($urandom);
  endfunction

  // 覆盖计数（每个都是「没有它这一轮就等于没验」的事件）
  longint cov_alloc_wb_clash = 0;   // 同拍同 preg 既分配又写回（清忙必须压过置忙）
  longint cov_wake_wb_clash  = 0;   // 同拍同 preg 既唤醒又分配
  longint cov_og0_kill       = 0;   // 快速唤醒被 is0Lat&og0Cancel 打掉
  longint cov_ldcancel_set   = 0;   // ldCancel 把已清的项重新置忙（Int 表专属）
  longint cov_read_oob       = 0;   // 读口索引越界
  longint cov_oob_dep_nz     = 0;   // 越界读 loadDependency 时第 0 项非零（★坑 4 的判别点）
  longint cov_entry0_alloc   = 0;   // 分配命中 0 号项（★Int 表 0 号项特判的判别点）
  longint cov_alloc_bypass   = 0;   // 读口撞上本拍分配（resp 旁路）
  longint cov_vl_int_wb      = 0;   // vl 表被 int 写回口填
  longint cov_vl_vf_wb       = 0;   // vl 表被 vf  写回口填
  longint cov_vl_other_wb    = 0;   // vl 表被其它写回口置「未知」


  // ==========================================================================
  // BusyTable —— Int 整数物理寄存器堆（IntWB），表深 224，写回口 8，读口 12，唤醒 7 路
  // ==========================================================================
  logic BusyTable_io_allocPregs_0_valid;
  logic [7:0] BusyTable_io_allocPregs_0_bits;
  logic BusyTable_io_allocPregs_1_valid;
  logic [7:0] BusyTable_io_allocPregs_1_bits;
  logic BusyTable_io_allocPregs_2_valid;
  logic [7:0] BusyTable_io_allocPregs_2_bits;
  logic BusyTable_io_allocPregs_3_valid;
  logic [7:0] BusyTable_io_allocPregs_3_bits;
  logic BusyTable_io_allocPregs_4_valid;
  logic [7:0] BusyTable_io_allocPregs_4_bits;
  logic BusyTable_io_allocPregs_5_valid;
  logic [7:0] BusyTable_io_allocPregs_5_bits;
  logic BusyTable_io_wbPregs_0_valid;
  logic [7:0] BusyTable_io_wbPregs_0_bits;
  logic BusyTable_io_wbPregs_1_valid;
  logic [7:0] BusyTable_io_wbPregs_1_bits;
  logic BusyTable_io_wbPregs_2_valid;
  logic [7:0] BusyTable_io_wbPregs_2_bits;
  logic BusyTable_io_wbPregs_3_valid;
  logic [7:0] BusyTable_io_wbPregs_3_bits;
  logic BusyTable_io_wbPregs_4_valid;
  logic [7:0] BusyTable_io_wbPregs_4_bits;
  logic BusyTable_io_wbPregs_5_valid;
  logic [7:0] BusyTable_io_wbPregs_5_bits;
  logic BusyTable_io_wbPregs_6_valid;
  logic [7:0] BusyTable_io_wbPregs_6_bits;
  logic BusyTable_io_wbPregs_7_valid;
  logic [7:0] BusyTable_io_wbPregs_7_bits;
  logic BusyTable_io_wakeUpInt_3_valid;
  logic BusyTable_io_wakeUpInt_3_bits_rfWen;
  logic [7:0] BusyTable_io_wakeUpInt_3_bits_pdest;
  logic [1:0] BusyTable_io_wakeUpInt_3_bits_loadDependency_0;
  logic [1:0] BusyTable_io_wakeUpInt_3_bits_loadDependency_1;
  logic [1:0] BusyTable_io_wakeUpInt_3_bits_loadDependency_2;
  logic BusyTable_io_wakeUpInt_2_valid;
  logic BusyTable_io_wakeUpInt_2_bits_rfWen;
  logic [7:0] BusyTable_io_wakeUpInt_2_bits_pdest;
  logic [1:0] BusyTable_io_wakeUpInt_2_bits_loadDependency_0;
  logic [1:0] BusyTable_io_wakeUpInt_2_bits_loadDependency_1;
  logic [1:0] BusyTable_io_wakeUpInt_2_bits_loadDependency_2;
  logic BusyTable_io_wakeUpInt_1_valid;
  logic BusyTable_io_wakeUpInt_1_bits_rfWen;
  logic [7:0] BusyTable_io_wakeUpInt_1_bits_pdest;
  logic [1:0] BusyTable_io_wakeUpInt_1_bits_loadDependency_0;
  logic [1:0] BusyTable_io_wakeUpInt_1_bits_loadDependency_1;
  logic [1:0] BusyTable_io_wakeUpInt_1_bits_loadDependency_2;
  logic BusyTable_io_wakeUpInt_1_bits_is0Lat;
  logic BusyTable_io_wakeUpInt_0_valid;
  logic BusyTable_io_wakeUpInt_0_bits_rfWen;
  logic [7:0] BusyTable_io_wakeUpInt_0_bits_pdest;
  logic [1:0] BusyTable_io_wakeUpInt_0_bits_loadDependency_0;
  logic [1:0] BusyTable_io_wakeUpInt_0_bits_loadDependency_1;
  logic [1:0] BusyTable_io_wakeUpInt_0_bits_loadDependency_2;
  logic BusyTable_io_wakeUpInt_0_bits_is0Lat;
  logic BusyTable_io_wakeUpMem_2_valid;
  logic BusyTable_io_wakeUpMem_2_bits_rfWen;
  logic [7:0] BusyTable_io_wakeUpMem_2_bits_pdest;
  logic [1:0] BusyTable_io_wakeUpMem_2_bits_loadDependency_0;
  logic [1:0] BusyTable_io_wakeUpMem_2_bits_loadDependency_1;
  logic [1:0] BusyTable_io_wakeUpMem_2_bits_loadDependency_2;
  logic BusyTable_io_wakeUpMem_1_valid;
  logic BusyTable_io_wakeUpMem_1_bits_rfWen;
  logic [7:0] BusyTable_io_wakeUpMem_1_bits_pdest;
  logic [1:0] BusyTable_io_wakeUpMem_1_bits_loadDependency_0;
  logic [1:0] BusyTable_io_wakeUpMem_1_bits_loadDependency_1;
  logic [1:0] BusyTable_io_wakeUpMem_1_bits_loadDependency_2;
  logic BusyTable_io_wakeUpMem_0_valid;
  logic BusyTable_io_wakeUpMem_0_bits_rfWen;
  logic [7:0] BusyTable_io_wakeUpMem_0_bits_pdest;
  logic [1:0] BusyTable_io_wakeUpMem_0_bits_loadDependency_0;
  logic [1:0] BusyTable_io_wakeUpMem_0_bits_loadDependency_1;
  logic [1:0] BusyTable_io_wakeUpMem_0_bits_loadDependency_2;
  logic BusyTable_io_og0Cancel_0;
  logic BusyTable_io_og0Cancel_2;
  logic BusyTable_io_og0Cancel_4;
  logic BusyTable_io_og0Cancel_6;
  logic BusyTable_io_ldCancel_0_ld2Cancel;
  logic BusyTable_io_ldCancel_1_ld2Cancel;
  logic BusyTable_io_ldCancel_2_ld2Cancel;
  logic [7:0] BusyTable_io_read_0_req;
  logic [7:0] BusyTable_io_read_1_req;
  logic [7:0] BusyTable_io_read_2_req;
  logic [7:0] BusyTable_io_read_3_req;
  logic [7:0] BusyTable_io_read_4_req;
  logic [7:0] BusyTable_io_read_5_req;
  logic [7:0] BusyTable_io_read_6_req;
  logic [7:0] BusyTable_io_read_7_req;
  logic [7:0] BusyTable_io_read_8_req;
  logic [7:0] BusyTable_io_read_9_req;
  logic [7:0] BusyTable_io_read_10_req;
  logic [7:0] BusyTable_io_read_11_req;
  wire  BusyTable_g_io_read_0_resp, BusyTable_i_io_read_0_resp;
  wire  [1:0] BusyTable_g_io_read_0_loadDependency_0, BusyTable_i_io_read_0_loadDependency_0;
  wire  [1:0] BusyTable_g_io_read_0_loadDependency_1, BusyTable_i_io_read_0_loadDependency_1;
  wire  [1:0] BusyTable_g_io_read_0_loadDependency_2, BusyTable_i_io_read_0_loadDependency_2;
  wire  BusyTable_g_io_read_1_resp, BusyTable_i_io_read_1_resp;
  wire  [1:0] BusyTable_g_io_read_1_loadDependency_0, BusyTable_i_io_read_1_loadDependency_0;
  wire  [1:0] BusyTable_g_io_read_1_loadDependency_1, BusyTable_i_io_read_1_loadDependency_1;
  wire  [1:0] BusyTable_g_io_read_1_loadDependency_2, BusyTable_i_io_read_1_loadDependency_2;
  wire  BusyTable_g_io_read_2_resp, BusyTable_i_io_read_2_resp;
  wire  [1:0] BusyTable_g_io_read_2_loadDependency_0, BusyTable_i_io_read_2_loadDependency_0;
  wire  [1:0] BusyTable_g_io_read_2_loadDependency_1, BusyTable_i_io_read_2_loadDependency_1;
  wire  [1:0] BusyTable_g_io_read_2_loadDependency_2, BusyTable_i_io_read_2_loadDependency_2;
  wire  BusyTable_g_io_read_3_resp, BusyTable_i_io_read_3_resp;
  wire  [1:0] BusyTable_g_io_read_3_loadDependency_0, BusyTable_i_io_read_3_loadDependency_0;
  wire  [1:0] BusyTable_g_io_read_3_loadDependency_1, BusyTable_i_io_read_3_loadDependency_1;
  wire  [1:0] BusyTable_g_io_read_3_loadDependency_2, BusyTable_i_io_read_3_loadDependency_2;
  wire  BusyTable_g_io_read_4_resp, BusyTable_i_io_read_4_resp;
  wire  [1:0] BusyTable_g_io_read_4_loadDependency_0, BusyTable_i_io_read_4_loadDependency_0;
  wire  [1:0] BusyTable_g_io_read_4_loadDependency_1, BusyTable_i_io_read_4_loadDependency_1;
  wire  [1:0] BusyTable_g_io_read_4_loadDependency_2, BusyTable_i_io_read_4_loadDependency_2;
  wire  BusyTable_g_io_read_5_resp, BusyTable_i_io_read_5_resp;
  wire  [1:0] BusyTable_g_io_read_5_loadDependency_0, BusyTable_i_io_read_5_loadDependency_0;
  wire  [1:0] BusyTable_g_io_read_5_loadDependency_1, BusyTable_i_io_read_5_loadDependency_1;
  wire  [1:0] BusyTable_g_io_read_5_loadDependency_2, BusyTable_i_io_read_5_loadDependency_2;
  wire  BusyTable_g_io_read_6_resp, BusyTable_i_io_read_6_resp;
  wire  [1:0] BusyTable_g_io_read_6_loadDependency_0, BusyTable_i_io_read_6_loadDependency_0;
  wire  [1:0] BusyTable_g_io_read_6_loadDependency_1, BusyTable_i_io_read_6_loadDependency_1;
  wire  [1:0] BusyTable_g_io_read_6_loadDependency_2, BusyTable_i_io_read_6_loadDependency_2;
  wire  BusyTable_g_io_read_7_resp, BusyTable_i_io_read_7_resp;
  wire  [1:0] BusyTable_g_io_read_7_loadDependency_0, BusyTable_i_io_read_7_loadDependency_0;
  wire  [1:0] BusyTable_g_io_read_7_loadDependency_1, BusyTable_i_io_read_7_loadDependency_1;
  wire  [1:0] BusyTable_g_io_read_7_loadDependency_2, BusyTable_i_io_read_7_loadDependency_2;
  wire  BusyTable_g_io_read_8_resp, BusyTable_i_io_read_8_resp;
  wire  [1:0] BusyTable_g_io_read_8_loadDependency_0, BusyTable_i_io_read_8_loadDependency_0;
  wire  [1:0] BusyTable_g_io_read_8_loadDependency_1, BusyTable_i_io_read_8_loadDependency_1;
  wire  [1:0] BusyTable_g_io_read_8_loadDependency_2, BusyTable_i_io_read_8_loadDependency_2;
  wire  BusyTable_g_io_read_9_resp, BusyTable_i_io_read_9_resp;
  wire  [1:0] BusyTable_g_io_read_9_loadDependency_0, BusyTable_i_io_read_9_loadDependency_0;
  wire  [1:0] BusyTable_g_io_read_9_loadDependency_1, BusyTable_i_io_read_9_loadDependency_1;
  wire  [1:0] BusyTable_g_io_read_9_loadDependency_2, BusyTable_i_io_read_9_loadDependency_2;
  wire  BusyTable_g_io_read_10_resp, BusyTable_i_io_read_10_resp;
  wire  [1:0] BusyTable_g_io_read_10_loadDependency_0, BusyTable_i_io_read_10_loadDependency_0;
  wire  [1:0] BusyTable_g_io_read_10_loadDependency_1, BusyTable_i_io_read_10_loadDependency_1;
  wire  [1:0] BusyTable_g_io_read_10_loadDependency_2, BusyTable_i_io_read_10_loadDependency_2;
  wire  BusyTable_g_io_read_11_resp, BusyTable_i_io_read_11_resp;
  wire  [1:0] BusyTable_g_io_read_11_loadDependency_0, BusyTable_i_io_read_11_loadDependency_0;
  wire  [1:0] BusyTable_g_io_read_11_loadDependency_1, BusyTable_i_io_read_11_loadDependency_1;
  wire  [1:0] BusyTable_g_io_read_11_loadDependency_2, BusyTable_i_io_read_11_loadDependency_2;
  BusyTable u_g_BusyTable (
    .clock(clk),
    .reset(rst),
    .io_allocPregs_0_valid(BusyTable_io_allocPregs_0_valid),
    .io_allocPregs_0_bits(BusyTable_io_allocPregs_0_bits),
    .io_allocPregs_1_valid(BusyTable_io_allocPregs_1_valid),
    .io_allocPregs_1_bits(BusyTable_io_allocPregs_1_bits),
    .io_allocPregs_2_valid(BusyTable_io_allocPregs_2_valid),
    .io_allocPregs_2_bits(BusyTable_io_allocPregs_2_bits),
    .io_allocPregs_3_valid(BusyTable_io_allocPregs_3_valid),
    .io_allocPregs_3_bits(BusyTable_io_allocPregs_3_bits),
    .io_allocPregs_4_valid(BusyTable_io_allocPregs_4_valid),
    .io_allocPregs_4_bits(BusyTable_io_allocPregs_4_bits),
    .io_allocPregs_5_valid(BusyTable_io_allocPregs_5_valid),
    .io_allocPregs_5_bits(BusyTable_io_allocPregs_5_bits),
    .io_wbPregs_0_valid(BusyTable_io_wbPregs_0_valid),
    .io_wbPregs_0_bits(BusyTable_io_wbPregs_0_bits),
    .io_wbPregs_1_valid(BusyTable_io_wbPregs_1_valid),
    .io_wbPregs_1_bits(BusyTable_io_wbPregs_1_bits),
    .io_wbPregs_2_valid(BusyTable_io_wbPregs_2_valid),
    .io_wbPregs_2_bits(BusyTable_io_wbPregs_2_bits),
    .io_wbPregs_3_valid(BusyTable_io_wbPregs_3_valid),
    .io_wbPregs_3_bits(BusyTable_io_wbPregs_3_bits),
    .io_wbPregs_4_valid(BusyTable_io_wbPregs_4_valid),
    .io_wbPregs_4_bits(BusyTable_io_wbPregs_4_bits),
    .io_wbPregs_5_valid(BusyTable_io_wbPregs_5_valid),
    .io_wbPregs_5_bits(BusyTable_io_wbPregs_5_bits),
    .io_wbPregs_6_valid(BusyTable_io_wbPregs_6_valid),
    .io_wbPregs_6_bits(BusyTable_io_wbPregs_6_bits),
    .io_wbPregs_7_valid(BusyTable_io_wbPregs_7_valid),
    .io_wbPregs_7_bits(BusyTable_io_wbPregs_7_bits),
    .io_wakeUpInt_3_valid(BusyTable_io_wakeUpInt_3_valid),
    .io_wakeUpInt_3_bits_rfWen(BusyTable_io_wakeUpInt_3_bits_rfWen),
    .io_wakeUpInt_3_bits_pdest(BusyTable_io_wakeUpInt_3_bits_pdest),
    .io_wakeUpInt_3_bits_loadDependency_0(BusyTable_io_wakeUpInt_3_bits_loadDependency_0),
    .io_wakeUpInt_3_bits_loadDependency_1(BusyTable_io_wakeUpInt_3_bits_loadDependency_1),
    .io_wakeUpInt_3_bits_loadDependency_2(BusyTable_io_wakeUpInt_3_bits_loadDependency_2),
    .io_wakeUpInt_2_valid(BusyTable_io_wakeUpInt_2_valid),
    .io_wakeUpInt_2_bits_rfWen(BusyTable_io_wakeUpInt_2_bits_rfWen),
    .io_wakeUpInt_2_bits_pdest(BusyTable_io_wakeUpInt_2_bits_pdest),
    .io_wakeUpInt_2_bits_loadDependency_0(BusyTable_io_wakeUpInt_2_bits_loadDependency_0),
    .io_wakeUpInt_2_bits_loadDependency_1(BusyTable_io_wakeUpInt_2_bits_loadDependency_1),
    .io_wakeUpInt_2_bits_loadDependency_2(BusyTable_io_wakeUpInt_2_bits_loadDependency_2),
    .io_wakeUpInt_1_valid(BusyTable_io_wakeUpInt_1_valid),
    .io_wakeUpInt_1_bits_rfWen(BusyTable_io_wakeUpInt_1_bits_rfWen),
    .io_wakeUpInt_1_bits_pdest(BusyTable_io_wakeUpInt_1_bits_pdest),
    .io_wakeUpInt_1_bits_loadDependency_0(BusyTable_io_wakeUpInt_1_bits_loadDependency_0),
    .io_wakeUpInt_1_bits_loadDependency_1(BusyTable_io_wakeUpInt_1_bits_loadDependency_1),
    .io_wakeUpInt_1_bits_loadDependency_2(BusyTable_io_wakeUpInt_1_bits_loadDependency_2),
    .io_wakeUpInt_1_bits_is0Lat(BusyTable_io_wakeUpInt_1_bits_is0Lat),
    .io_wakeUpInt_0_valid(BusyTable_io_wakeUpInt_0_valid),
    .io_wakeUpInt_0_bits_rfWen(BusyTable_io_wakeUpInt_0_bits_rfWen),
    .io_wakeUpInt_0_bits_pdest(BusyTable_io_wakeUpInt_0_bits_pdest),
    .io_wakeUpInt_0_bits_loadDependency_0(BusyTable_io_wakeUpInt_0_bits_loadDependency_0),
    .io_wakeUpInt_0_bits_loadDependency_1(BusyTable_io_wakeUpInt_0_bits_loadDependency_1),
    .io_wakeUpInt_0_bits_loadDependency_2(BusyTable_io_wakeUpInt_0_bits_loadDependency_2),
    .io_wakeUpInt_0_bits_is0Lat(BusyTable_io_wakeUpInt_0_bits_is0Lat),
    .io_wakeUpMem_2_valid(BusyTable_io_wakeUpMem_2_valid),
    .io_wakeUpMem_2_bits_rfWen(BusyTable_io_wakeUpMem_2_bits_rfWen),
    .io_wakeUpMem_2_bits_pdest(BusyTable_io_wakeUpMem_2_bits_pdest),
    .io_wakeUpMem_2_bits_loadDependency_0(BusyTable_io_wakeUpMem_2_bits_loadDependency_0),
    .io_wakeUpMem_2_bits_loadDependency_1(BusyTable_io_wakeUpMem_2_bits_loadDependency_1),
    .io_wakeUpMem_2_bits_loadDependency_2(BusyTable_io_wakeUpMem_2_bits_loadDependency_2),
    .io_wakeUpMem_1_valid(BusyTable_io_wakeUpMem_1_valid),
    .io_wakeUpMem_1_bits_rfWen(BusyTable_io_wakeUpMem_1_bits_rfWen),
    .io_wakeUpMem_1_bits_pdest(BusyTable_io_wakeUpMem_1_bits_pdest),
    .io_wakeUpMem_1_bits_loadDependency_0(BusyTable_io_wakeUpMem_1_bits_loadDependency_0),
    .io_wakeUpMem_1_bits_loadDependency_1(BusyTable_io_wakeUpMem_1_bits_loadDependency_1),
    .io_wakeUpMem_1_bits_loadDependency_2(BusyTable_io_wakeUpMem_1_bits_loadDependency_2),
    .io_wakeUpMem_0_valid(BusyTable_io_wakeUpMem_0_valid),
    .io_wakeUpMem_0_bits_rfWen(BusyTable_io_wakeUpMem_0_bits_rfWen),
    .io_wakeUpMem_0_bits_pdest(BusyTable_io_wakeUpMem_0_bits_pdest),
    .io_wakeUpMem_0_bits_loadDependency_0(BusyTable_io_wakeUpMem_0_bits_loadDependency_0),
    .io_wakeUpMem_0_bits_loadDependency_1(BusyTable_io_wakeUpMem_0_bits_loadDependency_1),
    .io_wakeUpMem_0_bits_loadDependency_2(BusyTable_io_wakeUpMem_0_bits_loadDependency_2),
    .io_og0Cancel_0(BusyTable_io_og0Cancel_0),
    .io_og0Cancel_2(BusyTable_io_og0Cancel_2),
    .io_og0Cancel_4(BusyTable_io_og0Cancel_4),
    .io_og0Cancel_6(BusyTable_io_og0Cancel_6),
    .io_ldCancel_0_ld2Cancel(BusyTable_io_ldCancel_0_ld2Cancel),
    .io_ldCancel_1_ld2Cancel(BusyTable_io_ldCancel_1_ld2Cancel),
    .io_ldCancel_2_ld2Cancel(BusyTable_io_ldCancel_2_ld2Cancel),
    .io_read_0_req(BusyTable_io_read_0_req),
    .io_read_1_req(BusyTable_io_read_1_req),
    .io_read_2_req(BusyTable_io_read_2_req),
    .io_read_3_req(BusyTable_io_read_3_req),
    .io_read_4_req(BusyTable_io_read_4_req),
    .io_read_5_req(BusyTable_io_read_5_req),
    .io_read_6_req(BusyTable_io_read_6_req),
    .io_read_7_req(BusyTable_io_read_7_req),
    .io_read_8_req(BusyTable_io_read_8_req),
    .io_read_9_req(BusyTable_io_read_9_req),
    .io_read_10_req(BusyTable_io_read_10_req),
    .io_read_11_req(BusyTable_io_read_11_req),
    .io_read_0_resp(BusyTable_g_io_read_0_resp),
    .io_read_0_loadDependency_0(BusyTable_g_io_read_0_loadDependency_0),
    .io_read_0_loadDependency_1(BusyTable_g_io_read_0_loadDependency_1),
    .io_read_0_loadDependency_2(BusyTable_g_io_read_0_loadDependency_2),
    .io_read_1_resp(BusyTable_g_io_read_1_resp),
    .io_read_1_loadDependency_0(BusyTable_g_io_read_1_loadDependency_0),
    .io_read_1_loadDependency_1(BusyTable_g_io_read_1_loadDependency_1),
    .io_read_1_loadDependency_2(BusyTable_g_io_read_1_loadDependency_2),
    .io_read_2_resp(BusyTable_g_io_read_2_resp),
    .io_read_2_loadDependency_0(BusyTable_g_io_read_2_loadDependency_0),
    .io_read_2_loadDependency_1(BusyTable_g_io_read_2_loadDependency_1),
    .io_read_2_loadDependency_2(BusyTable_g_io_read_2_loadDependency_2),
    .io_read_3_resp(BusyTable_g_io_read_3_resp),
    .io_read_3_loadDependency_0(BusyTable_g_io_read_3_loadDependency_0),
    .io_read_3_loadDependency_1(BusyTable_g_io_read_3_loadDependency_1),
    .io_read_3_loadDependency_2(BusyTable_g_io_read_3_loadDependency_2),
    .io_read_4_resp(BusyTable_g_io_read_4_resp),
    .io_read_4_loadDependency_0(BusyTable_g_io_read_4_loadDependency_0),
    .io_read_4_loadDependency_1(BusyTable_g_io_read_4_loadDependency_1),
    .io_read_4_loadDependency_2(BusyTable_g_io_read_4_loadDependency_2),
    .io_read_5_resp(BusyTable_g_io_read_5_resp),
    .io_read_5_loadDependency_0(BusyTable_g_io_read_5_loadDependency_0),
    .io_read_5_loadDependency_1(BusyTable_g_io_read_5_loadDependency_1),
    .io_read_5_loadDependency_2(BusyTable_g_io_read_5_loadDependency_2),
    .io_read_6_resp(BusyTable_g_io_read_6_resp),
    .io_read_6_loadDependency_0(BusyTable_g_io_read_6_loadDependency_0),
    .io_read_6_loadDependency_1(BusyTable_g_io_read_6_loadDependency_1),
    .io_read_6_loadDependency_2(BusyTable_g_io_read_6_loadDependency_2),
    .io_read_7_resp(BusyTable_g_io_read_7_resp),
    .io_read_7_loadDependency_0(BusyTable_g_io_read_7_loadDependency_0),
    .io_read_7_loadDependency_1(BusyTable_g_io_read_7_loadDependency_1),
    .io_read_7_loadDependency_2(BusyTable_g_io_read_7_loadDependency_2),
    .io_read_8_resp(BusyTable_g_io_read_8_resp),
    .io_read_8_loadDependency_0(BusyTable_g_io_read_8_loadDependency_0),
    .io_read_8_loadDependency_1(BusyTable_g_io_read_8_loadDependency_1),
    .io_read_8_loadDependency_2(BusyTable_g_io_read_8_loadDependency_2),
    .io_read_9_resp(BusyTable_g_io_read_9_resp),
    .io_read_9_loadDependency_0(BusyTable_g_io_read_9_loadDependency_0),
    .io_read_9_loadDependency_1(BusyTable_g_io_read_9_loadDependency_1),
    .io_read_9_loadDependency_2(BusyTable_g_io_read_9_loadDependency_2),
    .io_read_10_resp(BusyTable_g_io_read_10_resp),
    .io_read_10_loadDependency_0(BusyTable_g_io_read_10_loadDependency_0),
    .io_read_10_loadDependency_1(BusyTable_g_io_read_10_loadDependency_1),
    .io_read_10_loadDependency_2(BusyTable_g_io_read_10_loadDependency_2),
    .io_read_11_resp(BusyTable_g_io_read_11_resp),
    .io_read_11_loadDependency_0(BusyTable_g_io_read_11_loadDependency_0),
    .io_read_11_loadDependency_1(BusyTable_g_io_read_11_loadDependency_1),
    .io_read_11_loadDependency_2(BusyTable_g_io_read_11_loadDependency_2)
  );
  BusyTable_xs u_i_BusyTable (
    .clock(clk),
    .reset(rst),
    .io_allocPregs_0_valid(BusyTable_io_allocPregs_0_valid),
    .io_allocPregs_0_bits(BusyTable_io_allocPregs_0_bits),
    .io_allocPregs_1_valid(BusyTable_io_allocPregs_1_valid),
    .io_allocPregs_1_bits(BusyTable_io_allocPregs_1_bits),
    .io_allocPregs_2_valid(BusyTable_io_allocPregs_2_valid),
    .io_allocPregs_2_bits(BusyTable_io_allocPregs_2_bits),
    .io_allocPregs_3_valid(BusyTable_io_allocPregs_3_valid),
    .io_allocPregs_3_bits(BusyTable_io_allocPregs_3_bits),
    .io_allocPregs_4_valid(BusyTable_io_allocPregs_4_valid),
    .io_allocPregs_4_bits(BusyTable_io_allocPregs_4_bits),
    .io_allocPregs_5_valid(BusyTable_io_allocPregs_5_valid),
    .io_allocPregs_5_bits(BusyTable_io_allocPregs_5_bits),
    .io_wbPregs_0_valid(BusyTable_io_wbPregs_0_valid),
    .io_wbPregs_0_bits(BusyTable_io_wbPregs_0_bits),
    .io_wbPregs_1_valid(BusyTable_io_wbPregs_1_valid),
    .io_wbPregs_1_bits(BusyTable_io_wbPregs_1_bits),
    .io_wbPregs_2_valid(BusyTable_io_wbPregs_2_valid),
    .io_wbPregs_2_bits(BusyTable_io_wbPregs_2_bits),
    .io_wbPregs_3_valid(BusyTable_io_wbPregs_3_valid),
    .io_wbPregs_3_bits(BusyTable_io_wbPregs_3_bits),
    .io_wbPregs_4_valid(BusyTable_io_wbPregs_4_valid),
    .io_wbPregs_4_bits(BusyTable_io_wbPregs_4_bits),
    .io_wbPregs_5_valid(BusyTable_io_wbPregs_5_valid),
    .io_wbPregs_5_bits(BusyTable_io_wbPregs_5_bits),
    .io_wbPregs_6_valid(BusyTable_io_wbPregs_6_valid),
    .io_wbPregs_6_bits(BusyTable_io_wbPregs_6_bits),
    .io_wbPregs_7_valid(BusyTable_io_wbPregs_7_valid),
    .io_wbPregs_7_bits(BusyTable_io_wbPregs_7_bits),
    .io_wakeUpInt_3_valid(BusyTable_io_wakeUpInt_3_valid),
    .io_wakeUpInt_3_bits_rfWen(BusyTable_io_wakeUpInt_3_bits_rfWen),
    .io_wakeUpInt_3_bits_pdest(BusyTable_io_wakeUpInt_3_bits_pdest),
    .io_wakeUpInt_3_bits_loadDependency_0(BusyTable_io_wakeUpInt_3_bits_loadDependency_0),
    .io_wakeUpInt_3_bits_loadDependency_1(BusyTable_io_wakeUpInt_3_bits_loadDependency_1),
    .io_wakeUpInt_3_bits_loadDependency_2(BusyTable_io_wakeUpInt_3_bits_loadDependency_2),
    .io_wakeUpInt_2_valid(BusyTable_io_wakeUpInt_2_valid),
    .io_wakeUpInt_2_bits_rfWen(BusyTable_io_wakeUpInt_2_bits_rfWen),
    .io_wakeUpInt_2_bits_pdest(BusyTable_io_wakeUpInt_2_bits_pdest),
    .io_wakeUpInt_2_bits_loadDependency_0(BusyTable_io_wakeUpInt_2_bits_loadDependency_0),
    .io_wakeUpInt_2_bits_loadDependency_1(BusyTable_io_wakeUpInt_2_bits_loadDependency_1),
    .io_wakeUpInt_2_bits_loadDependency_2(BusyTable_io_wakeUpInt_2_bits_loadDependency_2),
    .io_wakeUpInt_1_valid(BusyTable_io_wakeUpInt_1_valid),
    .io_wakeUpInt_1_bits_rfWen(BusyTable_io_wakeUpInt_1_bits_rfWen),
    .io_wakeUpInt_1_bits_pdest(BusyTable_io_wakeUpInt_1_bits_pdest),
    .io_wakeUpInt_1_bits_loadDependency_0(BusyTable_io_wakeUpInt_1_bits_loadDependency_0),
    .io_wakeUpInt_1_bits_loadDependency_1(BusyTable_io_wakeUpInt_1_bits_loadDependency_1),
    .io_wakeUpInt_1_bits_loadDependency_2(BusyTable_io_wakeUpInt_1_bits_loadDependency_2),
    .io_wakeUpInt_1_bits_is0Lat(BusyTable_io_wakeUpInt_1_bits_is0Lat),
    .io_wakeUpInt_0_valid(BusyTable_io_wakeUpInt_0_valid),
    .io_wakeUpInt_0_bits_rfWen(BusyTable_io_wakeUpInt_0_bits_rfWen),
    .io_wakeUpInt_0_bits_pdest(BusyTable_io_wakeUpInt_0_bits_pdest),
    .io_wakeUpInt_0_bits_loadDependency_0(BusyTable_io_wakeUpInt_0_bits_loadDependency_0),
    .io_wakeUpInt_0_bits_loadDependency_1(BusyTable_io_wakeUpInt_0_bits_loadDependency_1),
    .io_wakeUpInt_0_bits_loadDependency_2(BusyTable_io_wakeUpInt_0_bits_loadDependency_2),
    .io_wakeUpInt_0_bits_is0Lat(BusyTable_io_wakeUpInt_0_bits_is0Lat),
    .io_wakeUpMem_2_valid(BusyTable_io_wakeUpMem_2_valid),
    .io_wakeUpMem_2_bits_rfWen(BusyTable_io_wakeUpMem_2_bits_rfWen),
    .io_wakeUpMem_2_bits_pdest(BusyTable_io_wakeUpMem_2_bits_pdest),
    .io_wakeUpMem_2_bits_loadDependency_0(BusyTable_io_wakeUpMem_2_bits_loadDependency_0),
    .io_wakeUpMem_2_bits_loadDependency_1(BusyTable_io_wakeUpMem_2_bits_loadDependency_1),
    .io_wakeUpMem_2_bits_loadDependency_2(BusyTable_io_wakeUpMem_2_bits_loadDependency_2),
    .io_wakeUpMem_1_valid(BusyTable_io_wakeUpMem_1_valid),
    .io_wakeUpMem_1_bits_rfWen(BusyTable_io_wakeUpMem_1_bits_rfWen),
    .io_wakeUpMem_1_bits_pdest(BusyTable_io_wakeUpMem_1_bits_pdest),
    .io_wakeUpMem_1_bits_loadDependency_0(BusyTable_io_wakeUpMem_1_bits_loadDependency_0),
    .io_wakeUpMem_1_bits_loadDependency_1(BusyTable_io_wakeUpMem_1_bits_loadDependency_1),
    .io_wakeUpMem_1_bits_loadDependency_2(BusyTable_io_wakeUpMem_1_bits_loadDependency_2),
    .io_wakeUpMem_0_valid(BusyTable_io_wakeUpMem_0_valid),
    .io_wakeUpMem_0_bits_rfWen(BusyTable_io_wakeUpMem_0_bits_rfWen),
    .io_wakeUpMem_0_bits_pdest(BusyTable_io_wakeUpMem_0_bits_pdest),
    .io_wakeUpMem_0_bits_loadDependency_0(BusyTable_io_wakeUpMem_0_bits_loadDependency_0),
    .io_wakeUpMem_0_bits_loadDependency_1(BusyTable_io_wakeUpMem_0_bits_loadDependency_1),
    .io_wakeUpMem_0_bits_loadDependency_2(BusyTable_io_wakeUpMem_0_bits_loadDependency_2),
    .io_og0Cancel_0(BusyTable_io_og0Cancel_0),
    .io_og0Cancel_2(BusyTable_io_og0Cancel_2),
    .io_og0Cancel_4(BusyTable_io_og0Cancel_4),
    .io_og0Cancel_6(BusyTable_io_og0Cancel_6),
    .io_ldCancel_0_ld2Cancel(BusyTable_io_ldCancel_0_ld2Cancel),
    .io_ldCancel_1_ld2Cancel(BusyTable_io_ldCancel_1_ld2Cancel),
    .io_ldCancel_2_ld2Cancel(BusyTable_io_ldCancel_2_ld2Cancel),
    .io_read_0_req(BusyTable_io_read_0_req),
    .io_read_1_req(BusyTable_io_read_1_req),
    .io_read_2_req(BusyTable_io_read_2_req),
    .io_read_3_req(BusyTable_io_read_3_req),
    .io_read_4_req(BusyTable_io_read_4_req),
    .io_read_5_req(BusyTable_io_read_5_req),
    .io_read_6_req(BusyTable_io_read_6_req),
    .io_read_7_req(BusyTable_io_read_7_req),
    .io_read_8_req(BusyTable_io_read_8_req),
    .io_read_9_req(BusyTable_io_read_9_req),
    .io_read_10_req(BusyTable_io_read_10_req),
    .io_read_11_req(BusyTable_io_read_11_req),
    .io_read_0_resp(BusyTable_i_io_read_0_resp),
    .io_read_0_loadDependency_0(BusyTable_i_io_read_0_loadDependency_0),
    .io_read_0_loadDependency_1(BusyTable_i_io_read_0_loadDependency_1),
    .io_read_0_loadDependency_2(BusyTable_i_io_read_0_loadDependency_2),
    .io_read_1_resp(BusyTable_i_io_read_1_resp),
    .io_read_1_loadDependency_0(BusyTable_i_io_read_1_loadDependency_0),
    .io_read_1_loadDependency_1(BusyTable_i_io_read_1_loadDependency_1),
    .io_read_1_loadDependency_2(BusyTable_i_io_read_1_loadDependency_2),
    .io_read_2_resp(BusyTable_i_io_read_2_resp),
    .io_read_2_loadDependency_0(BusyTable_i_io_read_2_loadDependency_0),
    .io_read_2_loadDependency_1(BusyTable_i_io_read_2_loadDependency_1),
    .io_read_2_loadDependency_2(BusyTable_i_io_read_2_loadDependency_2),
    .io_read_3_resp(BusyTable_i_io_read_3_resp),
    .io_read_3_loadDependency_0(BusyTable_i_io_read_3_loadDependency_0),
    .io_read_3_loadDependency_1(BusyTable_i_io_read_3_loadDependency_1),
    .io_read_3_loadDependency_2(BusyTable_i_io_read_3_loadDependency_2),
    .io_read_4_resp(BusyTable_i_io_read_4_resp),
    .io_read_4_loadDependency_0(BusyTable_i_io_read_4_loadDependency_0),
    .io_read_4_loadDependency_1(BusyTable_i_io_read_4_loadDependency_1),
    .io_read_4_loadDependency_2(BusyTable_i_io_read_4_loadDependency_2),
    .io_read_5_resp(BusyTable_i_io_read_5_resp),
    .io_read_5_loadDependency_0(BusyTable_i_io_read_5_loadDependency_0),
    .io_read_5_loadDependency_1(BusyTable_i_io_read_5_loadDependency_1),
    .io_read_5_loadDependency_2(BusyTable_i_io_read_5_loadDependency_2),
    .io_read_6_resp(BusyTable_i_io_read_6_resp),
    .io_read_6_loadDependency_0(BusyTable_i_io_read_6_loadDependency_0),
    .io_read_6_loadDependency_1(BusyTable_i_io_read_6_loadDependency_1),
    .io_read_6_loadDependency_2(BusyTable_i_io_read_6_loadDependency_2),
    .io_read_7_resp(BusyTable_i_io_read_7_resp),
    .io_read_7_loadDependency_0(BusyTable_i_io_read_7_loadDependency_0),
    .io_read_7_loadDependency_1(BusyTable_i_io_read_7_loadDependency_1),
    .io_read_7_loadDependency_2(BusyTable_i_io_read_7_loadDependency_2),
    .io_read_8_resp(BusyTable_i_io_read_8_resp),
    .io_read_8_loadDependency_0(BusyTable_i_io_read_8_loadDependency_0),
    .io_read_8_loadDependency_1(BusyTable_i_io_read_8_loadDependency_1),
    .io_read_8_loadDependency_2(BusyTable_i_io_read_8_loadDependency_2),
    .io_read_9_resp(BusyTable_i_io_read_9_resp),
    .io_read_9_loadDependency_0(BusyTable_i_io_read_9_loadDependency_0),
    .io_read_9_loadDependency_1(BusyTable_i_io_read_9_loadDependency_1),
    .io_read_9_loadDependency_2(BusyTable_i_io_read_9_loadDependency_2),
    .io_read_10_resp(BusyTable_i_io_read_10_resp),
    .io_read_10_loadDependency_0(BusyTable_i_io_read_10_loadDependency_0),
    .io_read_10_loadDependency_1(BusyTable_i_io_read_10_loadDependency_1),
    .io_read_10_loadDependency_2(BusyTable_i_io_read_10_loadDependency_2),
    .io_read_11_resp(BusyTable_i_io_read_11_resp),
    .io_read_11_loadDependency_0(BusyTable_i_io_read_11_loadDependency_0),
    .io_read_11_loadDependency_1(BusyTable_i_io_read_11_loadDependency_1),
    .io_read_11_loadDependency_2(BusyTable_i_io_read_11_loadDependency_2)
  );
  always @(negedge clk) begin
    if (rst) begin
      BusyTable_io_allocPregs_0_valid <= 1'b0;
      BusyTable_io_allocPregs_1_valid <= 1'b0;
      BusyTable_io_allocPregs_2_valid <= 1'b0;
      BusyTable_io_allocPregs_3_valid <= 1'b0;
      BusyTable_io_allocPregs_4_valid <= 1'b0;
      BusyTable_io_allocPregs_5_valid <= 1'b0;
      BusyTable_io_wbPregs_0_valid <= 1'b0;
      BusyTable_io_wbPregs_1_valid <= 1'b0;
      BusyTable_io_wbPregs_2_valid <= 1'b0;
      BusyTable_io_wbPregs_3_valid <= 1'b0;
      BusyTable_io_wbPregs_4_valid <= 1'b0;
      BusyTable_io_wbPregs_5_valid <= 1'b0;
      BusyTable_io_wbPregs_6_valid <= 1'b0;
      BusyTable_io_wbPregs_7_valid <= 1'b0;
      BusyTable_io_wakeUpInt_3_valid <= 1'b0;
      BusyTable_io_wakeUpInt_2_valid <= 1'b0;
      BusyTable_io_wakeUpInt_1_valid <= 1'b0;
      BusyTable_io_wakeUpInt_0_valid <= 1'b0;
      BusyTable_io_wakeUpMem_2_valid <= 1'b0;
      BusyTable_io_wakeUpMem_1_valid <= 1'b0;
      BusyTable_io_wakeUpMem_0_valid <= 1'b0;
    end else begin
      BusyTable_io_allocPregs_0_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_io_allocPregs_0_bits <= rand_preg(224);
      BusyTable_io_allocPregs_1_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_io_allocPregs_1_bits <= rand_preg(224);
      BusyTable_io_allocPregs_2_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_io_allocPregs_2_bits <= rand_preg(224);
      BusyTable_io_allocPregs_3_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_io_allocPregs_3_bits <= rand_preg(224);
      BusyTable_io_allocPregs_4_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_io_allocPregs_4_bits <= rand_preg(224);
      BusyTable_io_allocPregs_5_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_io_allocPregs_5_bits <= rand_preg(224);
      BusyTable_io_wbPregs_0_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_io_wbPregs_0_bits <= rand_preg(224);
      BusyTable_io_wbPregs_1_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_io_wbPregs_1_bits <= rand_preg(224);
      BusyTable_io_wbPregs_2_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_io_wbPregs_2_bits <= rand_preg(224);
      BusyTable_io_wbPregs_3_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_io_wbPregs_3_bits <= rand_preg(224);
      BusyTable_io_wbPregs_4_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_io_wbPregs_4_bits <= rand_preg(224);
      BusyTable_io_wbPregs_5_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_io_wbPregs_5_bits <= rand_preg(224);
      BusyTable_io_wbPregs_6_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_io_wbPregs_6_bits <= rand_preg(224);
      BusyTable_io_wbPregs_7_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_io_wbPregs_7_bits <= rand_preg(224);
      BusyTable_io_wakeUpInt_3_valid <= ($urandom_range(0, 9) < 7);
      BusyTable_io_wakeUpInt_3_bits_rfWen <= ($urandom_range(0, 9) < 8);
      BusyTable_io_wakeUpInt_3_bits_pdest <= rand_preg(224);
      BusyTable_io_wakeUpInt_3_bits_loadDependency_0 <= rand_dep();
      BusyTable_io_wakeUpInt_3_bits_loadDependency_1 <= rand_dep();
      BusyTable_io_wakeUpInt_3_bits_loadDependency_2 <= rand_dep();
      BusyTable_io_wakeUpInt_2_valid <= ($urandom_range(0, 9) < 7);
      BusyTable_io_wakeUpInt_2_bits_rfWen <= ($urandom_range(0, 9) < 8);
      BusyTable_io_wakeUpInt_2_bits_pdest <= rand_preg(224);
      BusyTable_io_wakeUpInt_2_bits_loadDependency_0 <= rand_dep();
      BusyTable_io_wakeUpInt_2_bits_loadDependency_1 <= rand_dep();
      BusyTable_io_wakeUpInt_2_bits_loadDependency_2 <= rand_dep();
      BusyTable_io_wakeUpInt_1_valid <= ($urandom_range(0, 9) < 7);
      BusyTable_io_wakeUpInt_1_bits_rfWen <= ($urandom_range(0, 9) < 8);
      BusyTable_io_wakeUpInt_1_bits_pdest <= rand_preg(224);
      BusyTable_io_wakeUpInt_1_bits_loadDependency_0 <= rand_dep();
      BusyTable_io_wakeUpInt_1_bits_loadDependency_1 <= rand_dep();
      BusyTable_io_wakeUpInt_1_bits_loadDependency_2 <= rand_dep();
      BusyTable_io_wakeUpInt_1_bits_is0Lat <= ($urandom_range(0, 9) < 5);
      BusyTable_io_wakeUpInt_0_valid <= ($urandom_range(0, 9) < 7);
      BusyTable_io_wakeUpInt_0_bits_rfWen <= ($urandom_range(0, 9) < 8);
      BusyTable_io_wakeUpInt_0_bits_pdest <= rand_preg(224);
      BusyTable_io_wakeUpInt_0_bits_loadDependency_0 <= rand_dep();
      BusyTable_io_wakeUpInt_0_bits_loadDependency_1 <= rand_dep();
      BusyTable_io_wakeUpInt_0_bits_loadDependency_2 <= rand_dep();
      BusyTable_io_wakeUpInt_0_bits_is0Lat <= ($urandom_range(0, 9) < 5);
      BusyTable_io_wakeUpMem_2_valid <= ($urandom_range(0, 9) < 7);
      BusyTable_io_wakeUpMem_2_bits_rfWen <= ($urandom_range(0, 9) < 8);
      BusyTable_io_wakeUpMem_2_bits_pdest <= rand_preg(224);
      BusyTable_io_wakeUpMem_2_bits_loadDependency_0 <= rand_dep();
      BusyTable_io_wakeUpMem_2_bits_loadDependency_1 <= rand_dep();
      BusyTable_io_wakeUpMem_2_bits_loadDependency_2 <= rand_dep();
      BusyTable_io_wakeUpMem_1_valid <= ($urandom_range(0, 9) < 7);
      BusyTable_io_wakeUpMem_1_bits_rfWen <= ($urandom_range(0, 9) < 8);
      BusyTable_io_wakeUpMem_1_bits_pdest <= rand_preg(224);
      BusyTable_io_wakeUpMem_1_bits_loadDependency_0 <= rand_dep();
      BusyTable_io_wakeUpMem_1_bits_loadDependency_1 <= rand_dep();
      BusyTable_io_wakeUpMem_1_bits_loadDependency_2 <= rand_dep();
      BusyTable_io_wakeUpMem_0_valid <= ($urandom_range(0, 9) < 7);
      BusyTable_io_wakeUpMem_0_bits_rfWen <= ($urandom_range(0, 9) < 8);
      BusyTable_io_wakeUpMem_0_bits_pdest <= rand_preg(224);
      BusyTable_io_wakeUpMem_0_bits_loadDependency_0 <= rand_dep();
      BusyTable_io_wakeUpMem_0_bits_loadDependency_1 <= rand_dep();
      BusyTable_io_wakeUpMem_0_bits_loadDependency_2 <= rand_dep();
      BusyTable_io_og0Cancel_0 <= ($urandom_range(0, 9) < 3);
      BusyTable_io_og0Cancel_2 <= ($urandom_range(0, 9) < 3);
      BusyTable_io_og0Cancel_4 <= ($urandom_range(0, 9) < 3);
      BusyTable_io_og0Cancel_6 <= ($urandom_range(0, 9) < 3);
      BusyTable_io_ldCancel_0_ld2Cancel <= ($urandom_range(0, 9) < 3);
      BusyTable_io_ldCancel_1_ld2Cancel <= ($urandom_range(0, 9) < 3);
      BusyTable_io_ldCancel_2_ld2Cancel <= ($urandom_range(0, 9) < 3);
      BusyTable_io_read_0_req <= rand_preg(224);
      BusyTable_io_read_1_req <= rand_preg(224);
      BusyTable_io_read_2_req <= rand_preg(224);
      BusyTable_io_read_3_req <= rand_preg(224);
      BusyTable_io_read_4_req <= rand_preg(224);
      BusyTable_io_read_5_req <= rand_preg(224);
      BusyTable_io_read_6_req <= rand_preg(224);
      BusyTable_io_read_7_req <= rand_preg(224);
      BusyTable_io_read_8_req <= rand_preg(224);
      BusyTable_io_read_9_req <= rand_preg(224);
      BusyTable_io_read_10_req <= rand_preg(224);
      BusyTable_io_read_11_req <= rand_preg(224);
    end
  end
  always @(negedge clk) if (!rst) begin
    #4;
    checks++;
    if (BusyTable_g_io_read_0_resp !== BusyTable_i_io_read_0_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_0_resp mismatch: g=%h i=%h", $time, BusyTable_g_io_read_0_resp, BusyTable_i_io_read_0_resp); end
    checks++;
    if (BusyTable_g_io_read_0_loadDependency_0 !== BusyTable_i_io_read_0_loadDependency_0) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_0_loadDependency_0 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_0_loadDependency_0, BusyTable_i_io_read_0_loadDependency_0); end
    checks++;
    if (BusyTable_g_io_read_0_loadDependency_1 !== BusyTable_i_io_read_0_loadDependency_1) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_0_loadDependency_1 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_0_loadDependency_1, BusyTable_i_io_read_0_loadDependency_1); end
    checks++;
    if (BusyTable_g_io_read_0_loadDependency_2 !== BusyTable_i_io_read_0_loadDependency_2) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_0_loadDependency_2 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_0_loadDependency_2, BusyTable_i_io_read_0_loadDependency_2); end
    checks++;
    if (BusyTable_g_io_read_1_resp !== BusyTable_i_io_read_1_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_1_resp mismatch: g=%h i=%h", $time, BusyTable_g_io_read_1_resp, BusyTable_i_io_read_1_resp); end
    checks++;
    if (BusyTable_g_io_read_1_loadDependency_0 !== BusyTable_i_io_read_1_loadDependency_0) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_1_loadDependency_0 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_1_loadDependency_0, BusyTable_i_io_read_1_loadDependency_0); end
    checks++;
    if (BusyTable_g_io_read_1_loadDependency_1 !== BusyTable_i_io_read_1_loadDependency_1) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_1_loadDependency_1 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_1_loadDependency_1, BusyTable_i_io_read_1_loadDependency_1); end
    checks++;
    if (BusyTable_g_io_read_1_loadDependency_2 !== BusyTable_i_io_read_1_loadDependency_2) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_1_loadDependency_2 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_1_loadDependency_2, BusyTable_i_io_read_1_loadDependency_2); end
    checks++;
    if (BusyTable_g_io_read_2_resp !== BusyTable_i_io_read_2_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_2_resp mismatch: g=%h i=%h", $time, BusyTable_g_io_read_2_resp, BusyTable_i_io_read_2_resp); end
    checks++;
    if (BusyTable_g_io_read_2_loadDependency_0 !== BusyTable_i_io_read_2_loadDependency_0) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_2_loadDependency_0 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_2_loadDependency_0, BusyTable_i_io_read_2_loadDependency_0); end
    checks++;
    if (BusyTable_g_io_read_2_loadDependency_1 !== BusyTable_i_io_read_2_loadDependency_1) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_2_loadDependency_1 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_2_loadDependency_1, BusyTable_i_io_read_2_loadDependency_1); end
    checks++;
    if (BusyTable_g_io_read_2_loadDependency_2 !== BusyTable_i_io_read_2_loadDependency_2) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_2_loadDependency_2 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_2_loadDependency_2, BusyTable_i_io_read_2_loadDependency_2); end
    checks++;
    if (BusyTable_g_io_read_3_resp !== BusyTable_i_io_read_3_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_3_resp mismatch: g=%h i=%h", $time, BusyTable_g_io_read_3_resp, BusyTable_i_io_read_3_resp); end
    checks++;
    if (BusyTable_g_io_read_3_loadDependency_0 !== BusyTable_i_io_read_3_loadDependency_0) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_3_loadDependency_0 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_3_loadDependency_0, BusyTable_i_io_read_3_loadDependency_0); end
    checks++;
    if (BusyTable_g_io_read_3_loadDependency_1 !== BusyTable_i_io_read_3_loadDependency_1) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_3_loadDependency_1 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_3_loadDependency_1, BusyTable_i_io_read_3_loadDependency_1); end
    checks++;
    if (BusyTable_g_io_read_3_loadDependency_2 !== BusyTable_i_io_read_3_loadDependency_2) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_3_loadDependency_2 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_3_loadDependency_2, BusyTable_i_io_read_3_loadDependency_2); end
    checks++;
    if (BusyTable_g_io_read_4_resp !== BusyTable_i_io_read_4_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_4_resp mismatch: g=%h i=%h", $time, BusyTable_g_io_read_4_resp, BusyTable_i_io_read_4_resp); end
    checks++;
    if (BusyTable_g_io_read_4_loadDependency_0 !== BusyTable_i_io_read_4_loadDependency_0) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_4_loadDependency_0 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_4_loadDependency_0, BusyTable_i_io_read_4_loadDependency_0); end
    checks++;
    if (BusyTable_g_io_read_4_loadDependency_1 !== BusyTable_i_io_read_4_loadDependency_1) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_4_loadDependency_1 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_4_loadDependency_1, BusyTable_i_io_read_4_loadDependency_1); end
    checks++;
    if (BusyTable_g_io_read_4_loadDependency_2 !== BusyTable_i_io_read_4_loadDependency_2) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_4_loadDependency_2 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_4_loadDependency_2, BusyTable_i_io_read_4_loadDependency_2); end
    checks++;
    if (BusyTable_g_io_read_5_resp !== BusyTable_i_io_read_5_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_5_resp mismatch: g=%h i=%h", $time, BusyTable_g_io_read_5_resp, BusyTable_i_io_read_5_resp); end
    checks++;
    if (BusyTable_g_io_read_5_loadDependency_0 !== BusyTable_i_io_read_5_loadDependency_0) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_5_loadDependency_0 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_5_loadDependency_0, BusyTable_i_io_read_5_loadDependency_0); end
    checks++;
    if (BusyTable_g_io_read_5_loadDependency_1 !== BusyTable_i_io_read_5_loadDependency_1) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_5_loadDependency_1 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_5_loadDependency_1, BusyTable_i_io_read_5_loadDependency_1); end
    checks++;
    if (BusyTable_g_io_read_5_loadDependency_2 !== BusyTable_i_io_read_5_loadDependency_2) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_5_loadDependency_2 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_5_loadDependency_2, BusyTable_i_io_read_5_loadDependency_2); end
    checks++;
    if (BusyTable_g_io_read_6_resp !== BusyTable_i_io_read_6_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_6_resp mismatch: g=%h i=%h", $time, BusyTable_g_io_read_6_resp, BusyTable_i_io_read_6_resp); end
    checks++;
    if (BusyTable_g_io_read_6_loadDependency_0 !== BusyTable_i_io_read_6_loadDependency_0) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_6_loadDependency_0 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_6_loadDependency_0, BusyTable_i_io_read_6_loadDependency_0); end
    checks++;
    if (BusyTable_g_io_read_6_loadDependency_1 !== BusyTable_i_io_read_6_loadDependency_1) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_6_loadDependency_1 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_6_loadDependency_1, BusyTable_i_io_read_6_loadDependency_1); end
    checks++;
    if (BusyTable_g_io_read_6_loadDependency_2 !== BusyTable_i_io_read_6_loadDependency_2) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_6_loadDependency_2 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_6_loadDependency_2, BusyTable_i_io_read_6_loadDependency_2); end
    checks++;
    if (BusyTable_g_io_read_7_resp !== BusyTable_i_io_read_7_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_7_resp mismatch: g=%h i=%h", $time, BusyTable_g_io_read_7_resp, BusyTable_i_io_read_7_resp); end
    checks++;
    if (BusyTable_g_io_read_7_loadDependency_0 !== BusyTable_i_io_read_7_loadDependency_0) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_7_loadDependency_0 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_7_loadDependency_0, BusyTable_i_io_read_7_loadDependency_0); end
    checks++;
    if (BusyTable_g_io_read_7_loadDependency_1 !== BusyTable_i_io_read_7_loadDependency_1) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_7_loadDependency_1 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_7_loadDependency_1, BusyTable_i_io_read_7_loadDependency_1); end
    checks++;
    if (BusyTable_g_io_read_7_loadDependency_2 !== BusyTable_i_io_read_7_loadDependency_2) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_7_loadDependency_2 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_7_loadDependency_2, BusyTable_i_io_read_7_loadDependency_2); end
    checks++;
    if (BusyTable_g_io_read_8_resp !== BusyTable_i_io_read_8_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_8_resp mismatch: g=%h i=%h", $time, BusyTable_g_io_read_8_resp, BusyTable_i_io_read_8_resp); end
    checks++;
    if (BusyTable_g_io_read_8_loadDependency_0 !== BusyTable_i_io_read_8_loadDependency_0) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_8_loadDependency_0 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_8_loadDependency_0, BusyTable_i_io_read_8_loadDependency_0); end
    checks++;
    if (BusyTable_g_io_read_8_loadDependency_1 !== BusyTable_i_io_read_8_loadDependency_1) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_8_loadDependency_1 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_8_loadDependency_1, BusyTable_i_io_read_8_loadDependency_1); end
    checks++;
    if (BusyTable_g_io_read_8_loadDependency_2 !== BusyTable_i_io_read_8_loadDependency_2) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_8_loadDependency_2 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_8_loadDependency_2, BusyTable_i_io_read_8_loadDependency_2); end
    checks++;
    if (BusyTable_g_io_read_9_resp !== BusyTable_i_io_read_9_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_9_resp mismatch: g=%h i=%h", $time, BusyTable_g_io_read_9_resp, BusyTable_i_io_read_9_resp); end
    checks++;
    if (BusyTable_g_io_read_9_loadDependency_0 !== BusyTable_i_io_read_9_loadDependency_0) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_9_loadDependency_0 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_9_loadDependency_0, BusyTable_i_io_read_9_loadDependency_0); end
    checks++;
    if (BusyTable_g_io_read_9_loadDependency_1 !== BusyTable_i_io_read_9_loadDependency_1) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_9_loadDependency_1 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_9_loadDependency_1, BusyTable_i_io_read_9_loadDependency_1); end
    checks++;
    if (BusyTable_g_io_read_9_loadDependency_2 !== BusyTable_i_io_read_9_loadDependency_2) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_9_loadDependency_2 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_9_loadDependency_2, BusyTable_i_io_read_9_loadDependency_2); end
    checks++;
    if (BusyTable_g_io_read_10_resp !== BusyTable_i_io_read_10_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_10_resp mismatch: g=%h i=%h", $time, BusyTable_g_io_read_10_resp, BusyTable_i_io_read_10_resp); end
    checks++;
    if (BusyTable_g_io_read_10_loadDependency_0 !== BusyTable_i_io_read_10_loadDependency_0) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_10_loadDependency_0 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_10_loadDependency_0, BusyTable_i_io_read_10_loadDependency_0); end
    checks++;
    if (BusyTable_g_io_read_10_loadDependency_1 !== BusyTable_i_io_read_10_loadDependency_1) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_10_loadDependency_1 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_10_loadDependency_1, BusyTable_i_io_read_10_loadDependency_1); end
    checks++;
    if (BusyTable_g_io_read_10_loadDependency_2 !== BusyTable_i_io_read_10_loadDependency_2) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_10_loadDependency_2 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_10_loadDependency_2, BusyTable_i_io_read_10_loadDependency_2); end
    checks++;
    if (BusyTable_g_io_read_11_resp !== BusyTable_i_io_read_11_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_11_resp mismatch: g=%h i=%h", $time, BusyTable_g_io_read_11_resp, BusyTable_i_io_read_11_resp); end
    checks++;
    if (BusyTable_g_io_read_11_loadDependency_0 !== BusyTable_i_io_read_11_loadDependency_0) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_11_loadDependency_0 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_11_loadDependency_0, BusyTable_i_io_read_11_loadDependency_0); end
    checks++;
    if (BusyTable_g_io_read_11_loadDependency_1 !== BusyTable_i_io_read_11_loadDependency_1) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_11_loadDependency_1 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_11_loadDependency_1, BusyTable_i_io_read_11_loadDependency_1); end
    checks++;
    if (BusyTable_g_io_read_11_loadDependency_2 !== BusyTable_i_io_read_11_loadDependency_2) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable.io_read_11_loadDependency_2 mismatch: g=%h i=%h", $time, BusyTable_g_io_read_11_loadDependency_2, BusyTable_i_io_read_11_loadDependency_2); end
  end
  // ---- 覆盖事件统计（只读 golden 侧，不看重写侧，免得自证）----
  always @(negedge clk) if (!rst) begin
    #4;
    for (int a = 0; a < 6; a++) begin
      logic v; logic [7:0] b;
      case (a)
        0: begin v = BusyTable_io_allocPregs_0_valid; b = BusyTable_io_allocPregs_0_bits; end
        1: begin v = BusyTable_io_allocPregs_1_valid; b = BusyTable_io_allocPregs_1_bits; end
        2: begin v = BusyTable_io_allocPregs_2_valid; b = BusyTable_io_allocPregs_2_bits; end
        3: begin v = BusyTable_io_allocPregs_3_valid; b = BusyTable_io_allocPregs_3_bits; end
        4: begin v = BusyTable_io_allocPregs_4_valid; b = BusyTable_io_allocPregs_4_bits; end
        5: begin v = BusyTable_io_allocPregs_5_valid; b = BusyTable_io_allocPregs_5_bits; end
        default: begin v = 1'b0; b = 8'h0; end
      endcase
      if (v && b < 224) begin
        if (b == 8'h0) cov_entry0_alloc++;
        for (int w = 0; w < 8; w++) begin
          logic wv; logic [7:0] wb;
          case (w)
            0: begin wv = BusyTable_io_wbPregs_0_valid; wb = BusyTable_io_wbPregs_0_bits; end
            1: begin wv = BusyTable_io_wbPregs_1_valid; wb = BusyTable_io_wbPregs_1_bits; end
            2: begin wv = BusyTable_io_wbPregs_2_valid; wb = BusyTable_io_wbPregs_2_bits; end
            3: begin wv = BusyTable_io_wbPregs_3_valid; wb = BusyTable_io_wbPregs_3_bits; end
            4: begin wv = BusyTable_io_wbPregs_4_valid; wb = BusyTable_io_wbPregs_4_bits; end
            5: begin wv = BusyTable_io_wbPregs_5_valid; wb = BusyTable_io_wbPregs_5_bits; end
            6: begin wv = BusyTable_io_wbPregs_6_valid; wb = BusyTable_io_wbPregs_6_bits; end
            7: begin wv = BusyTable_io_wbPregs_7_valid; wb = BusyTable_io_wbPregs_7_bits; end
            default: begin wv = 1'b0; wb = 8'h0; end
          endcase
          if (wv && wb == b) cov_alloc_wb_clash++;
        end
        for (int k = 0; k < 7; k++) begin
          logic kv; logic [7:0] kp;
          case (k)
            0: begin kv = BusyTable_io_wakeUpInt_0_valid && BusyTable_io_wakeUpInt_0_bits_rfWen; kp = BusyTable_io_wakeUpInt_0_bits_pdest; end
            1: begin kv = BusyTable_io_wakeUpInt_1_valid && BusyTable_io_wakeUpInt_1_bits_rfWen; kp = BusyTable_io_wakeUpInt_1_bits_pdest; end
            2: begin kv = BusyTable_io_wakeUpInt_2_valid && BusyTable_io_wakeUpInt_2_bits_rfWen; kp = BusyTable_io_wakeUpInt_2_bits_pdest; end
            3: begin kv = BusyTable_io_wakeUpInt_3_valid && BusyTable_io_wakeUpInt_3_bits_rfWen; kp = BusyTable_io_wakeUpInt_3_bits_pdest; end
            4: begin kv = BusyTable_io_wakeUpMem_0_valid && BusyTable_io_wakeUpMem_0_bits_rfWen; kp = BusyTable_io_wakeUpMem_0_bits_pdest; end
            5: begin kv = BusyTable_io_wakeUpMem_1_valid && BusyTable_io_wakeUpMem_1_bits_rfWen; kp = BusyTable_io_wakeUpMem_1_bits_pdest; end
            6: begin kv = BusyTable_io_wakeUpMem_2_valid && BusyTable_io_wakeUpMem_2_bits_rfWen; kp = BusyTable_io_wakeUpMem_2_bits_pdest; end
            default: begin kv = 1'b0; kp = 8'h0; end
          endcase
          if (kv && kp == b) cov_wake_wb_clash++;
        end
      end
    end
    if (BusyTable_io_wakeUpInt_0_valid && BusyTable_io_wakeUpInt_0_bits_rfWen && (BusyTable_io_wakeUpInt_0_bits_is0Lat) && (BusyTable_io_og0Cancel_0)) cov_og0_kill++;
    if (BusyTable_io_wakeUpInt_1_valid && BusyTable_io_wakeUpInt_1_bits_rfWen && (BusyTable_io_wakeUpInt_1_bits_is0Lat) && (BusyTable_io_og0Cancel_2)) cov_og0_kill++;
    if (BusyTable_io_wakeUpInt_2_valid && BusyTable_io_wakeUpInt_2_bits_rfWen && (1'b1) && (BusyTable_io_og0Cancel_4)) cov_og0_kill++;
    if (BusyTable_io_wakeUpInt_3_valid && BusyTable_io_wakeUpInt_3_bits_rfWen && (1'b1) && (BusyTable_io_og0Cancel_6)) cov_og0_kill++;
    for (int r = 0; r < 12; r++) begin
      logic [7:0] q;
      case (r)
        0: q = BusyTable_io_read_0_req;
        1: q = BusyTable_io_read_1_req;
        2: q = BusyTable_io_read_2_req;
        3: q = BusyTable_io_read_3_req;
        4: q = BusyTable_io_read_4_req;
        5: q = BusyTable_io_read_5_req;
        6: q = BusyTable_io_read_6_req;
        7: q = BusyTable_io_read_7_req;
        8: q = BusyTable_io_read_8_req;
        9: q = BusyTable_io_read_9_req;
        10: q = BusyTable_io_read_10_req;
        11: q = BusyTable_io_read_11_req;
        default: q = 8'h0;
      endcase
      if (q >= 224) cov_read_oob++;
      for (int a = 0; a < 6; a++) begin
        logic v; logic [7:0] b;
        case (a)
          0: begin v = BusyTable_io_allocPregs_0_valid; b = BusyTable_io_allocPregs_0_bits; end
          1: begin v = BusyTable_io_allocPregs_1_valid; b = BusyTable_io_allocPregs_1_bits; end
          2: begin v = BusyTable_io_allocPregs_2_valid; b = BusyTable_io_allocPregs_2_bits; end
          3: begin v = BusyTable_io_allocPregs_3_valid; b = BusyTable_io_allocPregs_3_bits; end
          4: begin v = BusyTable_io_allocPregs_4_valid; b = BusyTable_io_allocPregs_4_bits; end
          5: begin v = BusyTable_io_allocPregs_5_valid; b = BusyTable_io_allocPregs_5_bits; end
          default: begin v = 1'b0; b = 8'h0; end
        endcase
        if (v && b == q) cov_alloc_bypass++;
      end
    end
    for (int r = 0; r < 12; r++) begin
      logic [7:0] q;
      case (r)
        0: q = BusyTable_io_read_0_req;
        1: q = BusyTable_io_read_1_req;
        2: q = BusyTable_io_read_2_req;
        3: q = BusyTable_io_read_3_req;
        4: q = BusyTable_io_read_4_req;
        5: q = BusyTable_io_read_5_req;
        6: q = BusyTable_io_read_6_req;
        7: q = BusyTable_io_read_7_req;
        8: q = BusyTable_io_read_8_req;
        9: q = BusyTable_io_read_9_req;
        10: q = BusyTable_io_read_10_req;
        11: q = BusyTable_io_read_11_req;
        default: q = 8'h0;
      endcase
      if (q >= 224 &&
          (u_g_BusyTable.loadDependency_0_0 != 0 || u_g_BusyTable.loadDependency_0_1 != 0 ||
           u_g_BusyTable.loadDependency_0_2 != 0)) cov_oob_dep_nz++;
    end
    if (u_g_BusyTable.ldCancelMask_ld2Cancel || u_g_BusyTable.ldCancelMask_ld2Cancel_1 || u_g_BusyTable.ldCancelMask_ld2Cancel_2 || u_g_BusyTable.ldCancelMask_ld2Cancel_3 || u_g_BusyTable.ldCancelMask_ld2Cancel_4 || u_g_BusyTable.ldCancelMask_ld2Cancel_5 || u_g_BusyTable.ldCancelMask_ld2Cancel_6 || u_g_BusyTable.ldCancelMask_ld2Cancel_7) cov_ldcancel_set++;
  end

  // ==========================================================================
  // BusyTable_1 —— Fp 浮点物理寄存器堆（FpWB），表深 192，写回口 6，读口 18，唤醒 3 路
  // ==========================================================================
  logic BusyTable_1_io_allocPregs_0_valid;
  logic [7:0] BusyTable_1_io_allocPregs_0_bits;
  logic BusyTable_1_io_allocPregs_1_valid;
  logic [7:0] BusyTable_1_io_allocPregs_1_bits;
  logic BusyTable_1_io_allocPregs_2_valid;
  logic [7:0] BusyTable_1_io_allocPregs_2_bits;
  logic BusyTable_1_io_allocPregs_3_valid;
  logic [7:0] BusyTable_1_io_allocPregs_3_bits;
  logic BusyTable_1_io_allocPregs_4_valid;
  logic [7:0] BusyTable_1_io_allocPregs_4_bits;
  logic BusyTable_1_io_allocPregs_5_valid;
  logic [7:0] BusyTable_1_io_allocPregs_5_bits;
  logic BusyTable_1_io_wbPregs_0_valid;
  logic [7:0] BusyTable_1_io_wbPregs_0_bits;
  logic BusyTable_1_io_wbPregs_1_valid;
  logic [7:0] BusyTable_1_io_wbPregs_1_bits;
  logic BusyTable_1_io_wbPregs_2_valid;
  logic [7:0] BusyTable_1_io_wbPregs_2_bits;
  logic BusyTable_1_io_wbPregs_3_valid;
  logic [7:0] BusyTable_1_io_wbPregs_3_bits;
  logic BusyTable_1_io_wbPregs_4_valid;
  logic [7:0] BusyTable_1_io_wbPregs_4_bits;
  logic BusyTable_1_io_wbPregs_5_valid;
  logic [7:0] BusyTable_1_io_wbPregs_5_bits;
  logic BusyTable_1_io_wakeUpFp_2_valid;
  logic BusyTable_1_io_wakeUpFp_2_bits_fpWen;
  logic [7:0] BusyTable_1_io_wakeUpFp_2_bits_pdest;
  logic BusyTable_1_io_wakeUpFp_1_valid;
  logic BusyTable_1_io_wakeUpFp_1_bits_fpWen;
  logic [7:0] BusyTable_1_io_wakeUpFp_1_bits_pdest;
  logic BusyTable_1_io_wakeUpFp_0_valid;
  logic BusyTable_1_io_wakeUpFp_0_bits_fpWen;
  logic [7:0] BusyTable_1_io_wakeUpFp_0_bits_pdest;
  logic BusyTable_1_io_wakeUpFp_0_bits_is0Lat;
  logic BusyTable_1_io_og0Cancel_8;
  logic [7:0] BusyTable_1_io_read_0_req;
  logic [7:0] BusyTable_1_io_read_1_req;
  logic [7:0] BusyTable_1_io_read_2_req;
  logic [7:0] BusyTable_1_io_read_3_req;
  logic [7:0] BusyTable_1_io_read_4_req;
  logic [7:0] BusyTable_1_io_read_5_req;
  logic [7:0] BusyTable_1_io_read_6_req;
  logic [7:0] BusyTable_1_io_read_7_req;
  logic [7:0] BusyTable_1_io_read_8_req;
  logic [7:0] BusyTable_1_io_read_9_req;
  logic [7:0] BusyTable_1_io_read_10_req;
  logic [7:0] BusyTable_1_io_read_11_req;
  logic [7:0] BusyTable_1_io_read_12_req;
  logic [7:0] BusyTable_1_io_read_13_req;
  logic [7:0] BusyTable_1_io_read_14_req;
  logic [7:0] BusyTable_1_io_read_15_req;
  logic [7:0] BusyTable_1_io_read_16_req;
  logic [7:0] BusyTable_1_io_read_17_req;
  wire  BusyTable_1_g_io_read_0_resp, BusyTable_1_i_io_read_0_resp;
  wire  BusyTable_1_g_io_read_1_resp, BusyTable_1_i_io_read_1_resp;
  wire  BusyTable_1_g_io_read_2_resp, BusyTable_1_i_io_read_2_resp;
  wire  BusyTable_1_g_io_read_3_resp, BusyTable_1_i_io_read_3_resp;
  wire  BusyTable_1_g_io_read_4_resp, BusyTable_1_i_io_read_4_resp;
  wire  BusyTable_1_g_io_read_5_resp, BusyTable_1_i_io_read_5_resp;
  wire  BusyTable_1_g_io_read_6_resp, BusyTable_1_i_io_read_6_resp;
  wire  BusyTable_1_g_io_read_7_resp, BusyTable_1_i_io_read_7_resp;
  wire  BusyTable_1_g_io_read_8_resp, BusyTable_1_i_io_read_8_resp;
  wire  BusyTable_1_g_io_read_9_resp, BusyTable_1_i_io_read_9_resp;
  wire  BusyTable_1_g_io_read_10_resp, BusyTable_1_i_io_read_10_resp;
  wire  BusyTable_1_g_io_read_11_resp, BusyTable_1_i_io_read_11_resp;
  wire  BusyTable_1_g_io_read_12_resp, BusyTable_1_i_io_read_12_resp;
  wire  BusyTable_1_g_io_read_13_resp, BusyTable_1_i_io_read_13_resp;
  wire  BusyTable_1_g_io_read_14_resp, BusyTable_1_i_io_read_14_resp;
  wire  BusyTable_1_g_io_read_15_resp, BusyTable_1_i_io_read_15_resp;
  wire  BusyTable_1_g_io_read_16_resp, BusyTable_1_i_io_read_16_resp;
  wire  BusyTable_1_g_io_read_17_resp, BusyTable_1_i_io_read_17_resp;
  BusyTable_1 u_g_BusyTable_1 (
    .clock(clk),
    .reset(rst),
    .io_allocPregs_0_valid(BusyTable_1_io_allocPregs_0_valid),
    .io_allocPregs_0_bits(BusyTable_1_io_allocPregs_0_bits),
    .io_allocPregs_1_valid(BusyTable_1_io_allocPregs_1_valid),
    .io_allocPregs_1_bits(BusyTable_1_io_allocPregs_1_bits),
    .io_allocPregs_2_valid(BusyTable_1_io_allocPregs_2_valid),
    .io_allocPregs_2_bits(BusyTable_1_io_allocPregs_2_bits),
    .io_allocPregs_3_valid(BusyTable_1_io_allocPregs_3_valid),
    .io_allocPregs_3_bits(BusyTable_1_io_allocPregs_3_bits),
    .io_allocPregs_4_valid(BusyTable_1_io_allocPregs_4_valid),
    .io_allocPregs_4_bits(BusyTable_1_io_allocPregs_4_bits),
    .io_allocPregs_5_valid(BusyTable_1_io_allocPregs_5_valid),
    .io_allocPregs_5_bits(BusyTable_1_io_allocPregs_5_bits),
    .io_wbPregs_0_valid(BusyTable_1_io_wbPregs_0_valid),
    .io_wbPregs_0_bits(BusyTable_1_io_wbPregs_0_bits),
    .io_wbPregs_1_valid(BusyTable_1_io_wbPregs_1_valid),
    .io_wbPregs_1_bits(BusyTable_1_io_wbPregs_1_bits),
    .io_wbPregs_2_valid(BusyTable_1_io_wbPregs_2_valid),
    .io_wbPregs_2_bits(BusyTable_1_io_wbPregs_2_bits),
    .io_wbPregs_3_valid(BusyTable_1_io_wbPregs_3_valid),
    .io_wbPregs_3_bits(BusyTable_1_io_wbPregs_3_bits),
    .io_wbPregs_4_valid(BusyTable_1_io_wbPregs_4_valid),
    .io_wbPregs_4_bits(BusyTable_1_io_wbPregs_4_bits),
    .io_wbPregs_5_valid(BusyTable_1_io_wbPregs_5_valid),
    .io_wbPregs_5_bits(BusyTable_1_io_wbPregs_5_bits),
    .io_wakeUpFp_2_valid(BusyTable_1_io_wakeUpFp_2_valid),
    .io_wakeUpFp_2_bits_fpWen(BusyTable_1_io_wakeUpFp_2_bits_fpWen),
    .io_wakeUpFp_2_bits_pdest(BusyTable_1_io_wakeUpFp_2_bits_pdest),
    .io_wakeUpFp_1_valid(BusyTable_1_io_wakeUpFp_1_valid),
    .io_wakeUpFp_1_bits_fpWen(BusyTable_1_io_wakeUpFp_1_bits_fpWen),
    .io_wakeUpFp_1_bits_pdest(BusyTable_1_io_wakeUpFp_1_bits_pdest),
    .io_wakeUpFp_0_valid(BusyTable_1_io_wakeUpFp_0_valid),
    .io_wakeUpFp_0_bits_fpWen(BusyTable_1_io_wakeUpFp_0_bits_fpWen),
    .io_wakeUpFp_0_bits_pdest(BusyTable_1_io_wakeUpFp_0_bits_pdest),
    .io_wakeUpFp_0_bits_is0Lat(BusyTable_1_io_wakeUpFp_0_bits_is0Lat),
    .io_og0Cancel_8(BusyTable_1_io_og0Cancel_8),
    .io_read_0_req(BusyTable_1_io_read_0_req),
    .io_read_1_req(BusyTable_1_io_read_1_req),
    .io_read_2_req(BusyTable_1_io_read_2_req),
    .io_read_3_req(BusyTable_1_io_read_3_req),
    .io_read_4_req(BusyTable_1_io_read_4_req),
    .io_read_5_req(BusyTable_1_io_read_5_req),
    .io_read_6_req(BusyTable_1_io_read_6_req),
    .io_read_7_req(BusyTable_1_io_read_7_req),
    .io_read_8_req(BusyTable_1_io_read_8_req),
    .io_read_9_req(BusyTable_1_io_read_9_req),
    .io_read_10_req(BusyTable_1_io_read_10_req),
    .io_read_11_req(BusyTable_1_io_read_11_req),
    .io_read_12_req(BusyTable_1_io_read_12_req),
    .io_read_13_req(BusyTable_1_io_read_13_req),
    .io_read_14_req(BusyTable_1_io_read_14_req),
    .io_read_15_req(BusyTable_1_io_read_15_req),
    .io_read_16_req(BusyTable_1_io_read_16_req),
    .io_read_17_req(BusyTable_1_io_read_17_req),
    .io_read_0_resp(BusyTable_1_g_io_read_0_resp),
    .io_read_1_resp(BusyTable_1_g_io_read_1_resp),
    .io_read_2_resp(BusyTable_1_g_io_read_2_resp),
    .io_read_3_resp(BusyTable_1_g_io_read_3_resp),
    .io_read_4_resp(BusyTable_1_g_io_read_4_resp),
    .io_read_5_resp(BusyTable_1_g_io_read_5_resp),
    .io_read_6_resp(BusyTable_1_g_io_read_6_resp),
    .io_read_7_resp(BusyTable_1_g_io_read_7_resp),
    .io_read_8_resp(BusyTable_1_g_io_read_8_resp),
    .io_read_9_resp(BusyTable_1_g_io_read_9_resp),
    .io_read_10_resp(BusyTable_1_g_io_read_10_resp),
    .io_read_11_resp(BusyTable_1_g_io_read_11_resp),
    .io_read_12_resp(BusyTable_1_g_io_read_12_resp),
    .io_read_13_resp(BusyTable_1_g_io_read_13_resp),
    .io_read_14_resp(BusyTable_1_g_io_read_14_resp),
    .io_read_15_resp(BusyTable_1_g_io_read_15_resp),
    .io_read_16_resp(BusyTable_1_g_io_read_16_resp),
    .io_read_17_resp(BusyTable_1_g_io_read_17_resp)
  );
  BusyTable_1_xs u_i_BusyTable_1 (
    .clock(clk),
    .reset(rst),
    .io_allocPregs_0_valid(BusyTable_1_io_allocPregs_0_valid),
    .io_allocPregs_0_bits(BusyTable_1_io_allocPregs_0_bits),
    .io_allocPregs_1_valid(BusyTable_1_io_allocPregs_1_valid),
    .io_allocPregs_1_bits(BusyTable_1_io_allocPregs_1_bits),
    .io_allocPregs_2_valid(BusyTable_1_io_allocPregs_2_valid),
    .io_allocPregs_2_bits(BusyTable_1_io_allocPregs_2_bits),
    .io_allocPregs_3_valid(BusyTable_1_io_allocPregs_3_valid),
    .io_allocPregs_3_bits(BusyTable_1_io_allocPregs_3_bits),
    .io_allocPregs_4_valid(BusyTable_1_io_allocPregs_4_valid),
    .io_allocPregs_4_bits(BusyTable_1_io_allocPregs_4_bits),
    .io_allocPregs_5_valid(BusyTable_1_io_allocPregs_5_valid),
    .io_allocPregs_5_bits(BusyTable_1_io_allocPregs_5_bits),
    .io_wbPregs_0_valid(BusyTable_1_io_wbPregs_0_valid),
    .io_wbPregs_0_bits(BusyTable_1_io_wbPregs_0_bits),
    .io_wbPregs_1_valid(BusyTable_1_io_wbPregs_1_valid),
    .io_wbPregs_1_bits(BusyTable_1_io_wbPregs_1_bits),
    .io_wbPregs_2_valid(BusyTable_1_io_wbPregs_2_valid),
    .io_wbPregs_2_bits(BusyTable_1_io_wbPregs_2_bits),
    .io_wbPregs_3_valid(BusyTable_1_io_wbPregs_3_valid),
    .io_wbPregs_3_bits(BusyTable_1_io_wbPregs_3_bits),
    .io_wbPregs_4_valid(BusyTable_1_io_wbPregs_4_valid),
    .io_wbPregs_4_bits(BusyTable_1_io_wbPregs_4_bits),
    .io_wbPregs_5_valid(BusyTable_1_io_wbPregs_5_valid),
    .io_wbPregs_5_bits(BusyTable_1_io_wbPregs_5_bits),
    .io_wakeUpFp_2_valid(BusyTable_1_io_wakeUpFp_2_valid),
    .io_wakeUpFp_2_bits_fpWen(BusyTable_1_io_wakeUpFp_2_bits_fpWen),
    .io_wakeUpFp_2_bits_pdest(BusyTable_1_io_wakeUpFp_2_bits_pdest),
    .io_wakeUpFp_1_valid(BusyTable_1_io_wakeUpFp_1_valid),
    .io_wakeUpFp_1_bits_fpWen(BusyTable_1_io_wakeUpFp_1_bits_fpWen),
    .io_wakeUpFp_1_bits_pdest(BusyTable_1_io_wakeUpFp_1_bits_pdest),
    .io_wakeUpFp_0_valid(BusyTable_1_io_wakeUpFp_0_valid),
    .io_wakeUpFp_0_bits_fpWen(BusyTable_1_io_wakeUpFp_0_bits_fpWen),
    .io_wakeUpFp_0_bits_pdest(BusyTable_1_io_wakeUpFp_0_bits_pdest),
    .io_wakeUpFp_0_bits_is0Lat(BusyTable_1_io_wakeUpFp_0_bits_is0Lat),
    .io_og0Cancel_8(BusyTable_1_io_og0Cancel_8),
    .io_read_0_req(BusyTable_1_io_read_0_req),
    .io_read_1_req(BusyTable_1_io_read_1_req),
    .io_read_2_req(BusyTable_1_io_read_2_req),
    .io_read_3_req(BusyTable_1_io_read_3_req),
    .io_read_4_req(BusyTable_1_io_read_4_req),
    .io_read_5_req(BusyTable_1_io_read_5_req),
    .io_read_6_req(BusyTable_1_io_read_6_req),
    .io_read_7_req(BusyTable_1_io_read_7_req),
    .io_read_8_req(BusyTable_1_io_read_8_req),
    .io_read_9_req(BusyTable_1_io_read_9_req),
    .io_read_10_req(BusyTable_1_io_read_10_req),
    .io_read_11_req(BusyTable_1_io_read_11_req),
    .io_read_12_req(BusyTable_1_io_read_12_req),
    .io_read_13_req(BusyTable_1_io_read_13_req),
    .io_read_14_req(BusyTable_1_io_read_14_req),
    .io_read_15_req(BusyTable_1_io_read_15_req),
    .io_read_16_req(BusyTable_1_io_read_16_req),
    .io_read_17_req(BusyTable_1_io_read_17_req),
    .io_read_0_resp(BusyTable_1_i_io_read_0_resp),
    .io_read_1_resp(BusyTable_1_i_io_read_1_resp),
    .io_read_2_resp(BusyTable_1_i_io_read_2_resp),
    .io_read_3_resp(BusyTable_1_i_io_read_3_resp),
    .io_read_4_resp(BusyTable_1_i_io_read_4_resp),
    .io_read_5_resp(BusyTable_1_i_io_read_5_resp),
    .io_read_6_resp(BusyTable_1_i_io_read_6_resp),
    .io_read_7_resp(BusyTable_1_i_io_read_7_resp),
    .io_read_8_resp(BusyTable_1_i_io_read_8_resp),
    .io_read_9_resp(BusyTable_1_i_io_read_9_resp),
    .io_read_10_resp(BusyTable_1_i_io_read_10_resp),
    .io_read_11_resp(BusyTable_1_i_io_read_11_resp),
    .io_read_12_resp(BusyTable_1_i_io_read_12_resp),
    .io_read_13_resp(BusyTable_1_i_io_read_13_resp),
    .io_read_14_resp(BusyTable_1_i_io_read_14_resp),
    .io_read_15_resp(BusyTable_1_i_io_read_15_resp),
    .io_read_16_resp(BusyTable_1_i_io_read_16_resp),
    .io_read_17_resp(BusyTable_1_i_io_read_17_resp)
  );
  always @(negedge clk) begin
    if (rst) begin
      BusyTable_1_io_allocPregs_0_valid <= 1'b0;
      BusyTable_1_io_allocPregs_1_valid <= 1'b0;
      BusyTable_1_io_allocPregs_2_valid <= 1'b0;
      BusyTable_1_io_allocPregs_3_valid <= 1'b0;
      BusyTable_1_io_allocPregs_4_valid <= 1'b0;
      BusyTable_1_io_allocPregs_5_valid <= 1'b0;
      BusyTable_1_io_wbPregs_0_valid <= 1'b0;
      BusyTable_1_io_wbPregs_1_valid <= 1'b0;
      BusyTable_1_io_wbPregs_2_valid <= 1'b0;
      BusyTable_1_io_wbPregs_3_valid <= 1'b0;
      BusyTable_1_io_wbPregs_4_valid <= 1'b0;
      BusyTable_1_io_wbPregs_5_valid <= 1'b0;
      BusyTable_1_io_wakeUpFp_2_valid <= 1'b0;
      BusyTable_1_io_wakeUpFp_1_valid <= 1'b0;
      BusyTable_1_io_wakeUpFp_0_valid <= 1'b0;
    end else begin
      BusyTable_1_io_allocPregs_0_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_1_io_allocPregs_0_bits <= rand_preg(192);
      BusyTable_1_io_allocPregs_1_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_1_io_allocPregs_1_bits <= rand_preg(192);
      BusyTable_1_io_allocPregs_2_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_1_io_allocPregs_2_bits <= rand_preg(192);
      BusyTable_1_io_allocPregs_3_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_1_io_allocPregs_3_bits <= rand_preg(192);
      BusyTable_1_io_allocPregs_4_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_1_io_allocPregs_4_bits <= rand_preg(192);
      BusyTable_1_io_allocPregs_5_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_1_io_allocPregs_5_bits <= rand_preg(192);
      BusyTable_1_io_wbPregs_0_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_1_io_wbPregs_0_bits <= rand_preg(192);
      BusyTable_1_io_wbPregs_1_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_1_io_wbPregs_1_bits <= rand_preg(192);
      BusyTable_1_io_wbPregs_2_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_1_io_wbPregs_2_bits <= rand_preg(192);
      BusyTable_1_io_wbPregs_3_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_1_io_wbPregs_3_bits <= rand_preg(192);
      BusyTable_1_io_wbPregs_4_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_1_io_wbPregs_4_bits <= rand_preg(192);
      BusyTable_1_io_wbPregs_5_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_1_io_wbPregs_5_bits <= rand_preg(192);
      BusyTable_1_io_wakeUpFp_2_valid <= ($urandom_range(0, 9) < 7);
      BusyTable_1_io_wakeUpFp_2_bits_fpWen <= ($urandom_range(0, 9) < 8);
      BusyTable_1_io_wakeUpFp_2_bits_pdest <= rand_preg(192);
      BusyTable_1_io_wakeUpFp_1_valid <= ($urandom_range(0, 9) < 7);
      BusyTable_1_io_wakeUpFp_1_bits_fpWen <= ($urandom_range(0, 9) < 8);
      BusyTable_1_io_wakeUpFp_1_bits_pdest <= rand_preg(192);
      BusyTable_1_io_wakeUpFp_0_valid <= ($urandom_range(0, 9) < 7);
      BusyTable_1_io_wakeUpFp_0_bits_fpWen <= ($urandom_range(0, 9) < 8);
      BusyTable_1_io_wakeUpFp_0_bits_pdest <= rand_preg(192);
      BusyTable_1_io_wakeUpFp_0_bits_is0Lat <= ($urandom_range(0, 9) < 5);
      BusyTable_1_io_og0Cancel_8 <= ($urandom_range(0, 9) < 3);
      BusyTable_1_io_read_0_req <= rand_preg(192);
      BusyTable_1_io_read_1_req <= rand_preg(192);
      BusyTable_1_io_read_2_req <= rand_preg(192);
      BusyTable_1_io_read_3_req <= rand_preg(192);
      BusyTable_1_io_read_4_req <= rand_preg(192);
      BusyTable_1_io_read_5_req <= rand_preg(192);
      BusyTable_1_io_read_6_req <= rand_preg(192);
      BusyTable_1_io_read_7_req <= rand_preg(192);
      BusyTable_1_io_read_8_req <= rand_preg(192);
      BusyTable_1_io_read_9_req <= rand_preg(192);
      BusyTable_1_io_read_10_req <= rand_preg(192);
      BusyTable_1_io_read_11_req <= rand_preg(192);
      BusyTable_1_io_read_12_req <= rand_preg(192);
      BusyTable_1_io_read_13_req <= rand_preg(192);
      BusyTable_1_io_read_14_req <= rand_preg(192);
      BusyTable_1_io_read_15_req <= rand_preg(192);
      BusyTable_1_io_read_16_req <= rand_preg(192);
      BusyTable_1_io_read_17_req <= rand_preg(192);
    end
  end
  always @(negedge clk) if (!rst) begin
    #4;
    checks++;
    if (BusyTable_1_g_io_read_0_resp !== BusyTable_1_i_io_read_0_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_0_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_0_resp, BusyTable_1_i_io_read_0_resp); end
    checks++;
    if (BusyTable_1_g_io_read_1_resp !== BusyTable_1_i_io_read_1_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_1_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_1_resp, BusyTable_1_i_io_read_1_resp); end
    checks++;
    if (BusyTable_1_g_io_read_2_resp !== BusyTable_1_i_io_read_2_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_2_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_2_resp, BusyTable_1_i_io_read_2_resp); end
    checks++;
    if (BusyTable_1_g_io_read_3_resp !== BusyTable_1_i_io_read_3_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_3_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_3_resp, BusyTable_1_i_io_read_3_resp); end
    checks++;
    if (BusyTable_1_g_io_read_4_resp !== BusyTable_1_i_io_read_4_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_4_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_4_resp, BusyTable_1_i_io_read_4_resp); end
    checks++;
    if (BusyTable_1_g_io_read_5_resp !== BusyTable_1_i_io_read_5_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_5_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_5_resp, BusyTable_1_i_io_read_5_resp); end
    checks++;
    if (BusyTable_1_g_io_read_6_resp !== BusyTable_1_i_io_read_6_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_6_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_6_resp, BusyTable_1_i_io_read_6_resp); end
    checks++;
    if (BusyTable_1_g_io_read_7_resp !== BusyTable_1_i_io_read_7_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_7_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_7_resp, BusyTable_1_i_io_read_7_resp); end
    checks++;
    if (BusyTable_1_g_io_read_8_resp !== BusyTable_1_i_io_read_8_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_8_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_8_resp, BusyTable_1_i_io_read_8_resp); end
    checks++;
    if (BusyTable_1_g_io_read_9_resp !== BusyTable_1_i_io_read_9_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_9_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_9_resp, BusyTable_1_i_io_read_9_resp); end
    checks++;
    if (BusyTable_1_g_io_read_10_resp !== BusyTable_1_i_io_read_10_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_10_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_10_resp, BusyTable_1_i_io_read_10_resp); end
    checks++;
    if (BusyTable_1_g_io_read_11_resp !== BusyTable_1_i_io_read_11_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_11_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_11_resp, BusyTable_1_i_io_read_11_resp); end
    checks++;
    if (BusyTable_1_g_io_read_12_resp !== BusyTable_1_i_io_read_12_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_12_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_12_resp, BusyTable_1_i_io_read_12_resp); end
    checks++;
    if (BusyTable_1_g_io_read_13_resp !== BusyTable_1_i_io_read_13_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_13_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_13_resp, BusyTable_1_i_io_read_13_resp); end
    checks++;
    if (BusyTable_1_g_io_read_14_resp !== BusyTable_1_i_io_read_14_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_14_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_14_resp, BusyTable_1_i_io_read_14_resp); end
    checks++;
    if (BusyTable_1_g_io_read_15_resp !== BusyTable_1_i_io_read_15_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_15_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_15_resp, BusyTable_1_i_io_read_15_resp); end
    checks++;
    if (BusyTable_1_g_io_read_16_resp !== BusyTable_1_i_io_read_16_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_16_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_16_resp, BusyTable_1_i_io_read_16_resp); end
    checks++;
    if (BusyTable_1_g_io_read_17_resp !== BusyTable_1_i_io_read_17_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_1.io_read_17_resp mismatch: g=%h i=%h", $time, BusyTable_1_g_io_read_17_resp, BusyTable_1_i_io_read_17_resp); end
  end
  // ---- 覆盖事件统计（只读 golden 侧，不看重写侧，免得自证）----
  always @(negedge clk) if (!rst) begin
    #4;
    for (int a = 0; a < 6; a++) begin
      logic v; logic [7:0] b;
      case (a)
        0: begin v = BusyTable_1_io_allocPregs_0_valid; b = BusyTable_1_io_allocPregs_0_bits; end
        1: begin v = BusyTable_1_io_allocPregs_1_valid; b = BusyTable_1_io_allocPregs_1_bits; end
        2: begin v = BusyTable_1_io_allocPregs_2_valid; b = BusyTable_1_io_allocPregs_2_bits; end
        3: begin v = BusyTable_1_io_allocPregs_3_valid; b = BusyTable_1_io_allocPregs_3_bits; end
        4: begin v = BusyTable_1_io_allocPregs_4_valid; b = BusyTable_1_io_allocPregs_4_bits; end
        5: begin v = BusyTable_1_io_allocPregs_5_valid; b = BusyTable_1_io_allocPregs_5_bits; end
        default: begin v = 1'b0; b = 8'h0; end
      endcase
      if (v && b < 192) begin
        for (int w = 0; w < 6; w++) begin
          logic wv; logic [7:0] wb;
          case (w)
            0: begin wv = BusyTable_1_io_wbPregs_0_valid; wb = BusyTable_1_io_wbPregs_0_bits; end
            1: begin wv = BusyTable_1_io_wbPregs_1_valid; wb = BusyTable_1_io_wbPregs_1_bits; end
            2: begin wv = BusyTable_1_io_wbPregs_2_valid; wb = BusyTable_1_io_wbPregs_2_bits; end
            3: begin wv = BusyTable_1_io_wbPregs_3_valid; wb = BusyTable_1_io_wbPregs_3_bits; end
            4: begin wv = BusyTable_1_io_wbPregs_4_valid; wb = BusyTable_1_io_wbPregs_4_bits; end
            5: begin wv = BusyTable_1_io_wbPregs_5_valid; wb = BusyTable_1_io_wbPregs_5_bits; end
            default: begin wv = 1'b0; wb = 8'h0; end
          endcase
          if (wv && wb == b) cov_alloc_wb_clash++;
        end
        for (int k = 0; k < 3; k++) begin
          logic kv; logic [7:0] kp;
          case (k)
            0: begin kv = BusyTable_1_io_wakeUpFp_0_valid && BusyTable_1_io_wakeUpFp_0_bits_fpWen; kp = BusyTable_1_io_wakeUpFp_0_bits_pdest; end
            1: begin kv = BusyTable_1_io_wakeUpFp_1_valid && BusyTable_1_io_wakeUpFp_1_bits_fpWen; kp = BusyTable_1_io_wakeUpFp_1_bits_pdest; end
            2: begin kv = BusyTable_1_io_wakeUpFp_2_valid && BusyTable_1_io_wakeUpFp_2_bits_fpWen; kp = BusyTable_1_io_wakeUpFp_2_bits_pdest; end
            default: begin kv = 1'b0; kp = 8'h0; end
          endcase
          if (kv && kp == b) cov_wake_wb_clash++;
        end
      end
    end
    if (BusyTable_1_io_wakeUpFp_0_valid && BusyTable_1_io_wakeUpFp_0_bits_fpWen && (BusyTable_1_io_wakeUpFp_0_bits_is0Lat) && (BusyTable_1_io_og0Cancel_8)) cov_og0_kill++;
    for (int r = 0; r < 18; r++) begin
      logic [7:0] q;
      case (r)
        0: q = BusyTable_1_io_read_0_req;
        1: q = BusyTable_1_io_read_1_req;
        2: q = BusyTable_1_io_read_2_req;
        3: q = BusyTable_1_io_read_3_req;
        4: q = BusyTable_1_io_read_4_req;
        5: q = BusyTable_1_io_read_5_req;
        6: q = BusyTable_1_io_read_6_req;
        7: q = BusyTable_1_io_read_7_req;
        8: q = BusyTable_1_io_read_8_req;
        9: q = BusyTable_1_io_read_9_req;
        10: q = BusyTable_1_io_read_10_req;
        11: q = BusyTable_1_io_read_11_req;
        12: q = BusyTable_1_io_read_12_req;
        13: q = BusyTable_1_io_read_13_req;
        14: q = BusyTable_1_io_read_14_req;
        15: q = BusyTable_1_io_read_15_req;
        16: q = BusyTable_1_io_read_16_req;
        17: q = BusyTable_1_io_read_17_req;
        default: q = 8'h0;
      endcase
      if (q >= 192) cov_read_oob++;
      for (int a = 0; a < 6; a++) begin
        logic v; logic [7:0] b;
        case (a)
          0: begin v = BusyTable_1_io_allocPregs_0_valid; b = BusyTable_1_io_allocPregs_0_bits; end
          1: begin v = BusyTable_1_io_allocPregs_1_valid; b = BusyTable_1_io_allocPregs_1_bits; end
          2: begin v = BusyTable_1_io_allocPregs_2_valid; b = BusyTable_1_io_allocPregs_2_bits; end
          3: begin v = BusyTable_1_io_allocPregs_3_valid; b = BusyTable_1_io_allocPregs_3_bits; end
          4: begin v = BusyTable_1_io_allocPregs_4_valid; b = BusyTable_1_io_allocPregs_4_bits; end
          5: begin v = BusyTable_1_io_allocPregs_5_valid; b = BusyTable_1_io_allocPregs_5_bits; end
          default: begin v = 1'b0; b = 8'h0; end
        endcase
        if (v && b == q) cov_alloc_bypass++;
      end
    end
  end

  // ==========================================================================
  // BusyTable_2 —— Vf 向量/浮点物理寄存器堆（VfWB），表深 128，写回口 6，读口 18，唤醒 1 路
  // ==========================================================================
  logic BusyTable_2_io_allocPregs_0_valid;
  logic [7:0] BusyTable_2_io_allocPregs_0_bits;
  logic BusyTable_2_io_allocPregs_1_valid;
  logic [7:0] BusyTable_2_io_allocPregs_1_bits;
  logic BusyTable_2_io_allocPregs_2_valid;
  logic [7:0] BusyTable_2_io_allocPregs_2_bits;
  logic BusyTable_2_io_allocPregs_3_valid;
  logic [7:0] BusyTable_2_io_allocPregs_3_bits;
  logic BusyTable_2_io_allocPregs_4_valid;
  logic [7:0] BusyTable_2_io_allocPregs_4_bits;
  logic BusyTable_2_io_allocPregs_5_valid;
  logic [7:0] BusyTable_2_io_allocPregs_5_bits;
  logic BusyTable_2_io_wbPregs_0_valid;
  logic [7:0] BusyTable_2_io_wbPregs_0_bits;
  logic BusyTable_2_io_wbPregs_1_valid;
  logic [7:0] BusyTable_2_io_wbPregs_1_bits;
  logic BusyTable_2_io_wbPregs_2_valid;
  logic [7:0] BusyTable_2_io_wbPregs_2_bits;
  logic BusyTable_2_io_wbPregs_3_valid;
  logic [7:0] BusyTable_2_io_wbPregs_3_bits;
  logic BusyTable_2_io_wbPregs_4_valid;
  logic [7:0] BusyTable_2_io_wbPregs_4_bits;
  logic BusyTable_2_io_wbPregs_5_valid;
  logic [7:0] BusyTable_2_io_wbPregs_5_bits;
  logic BusyTable_2_io_wakeUpFp_0_valid;
  logic BusyTable_2_io_wakeUpFp_0_bits_vecWen;
  logic [7:0] BusyTable_2_io_wakeUpFp_0_bits_pdest;
  logic BusyTable_2_io_wakeUpFp_0_bits_is0Lat;
  logic BusyTable_2_io_og0Cancel_8;
  logic [7:0] BusyTable_2_io_read_0_req;
  logic [7:0] BusyTable_2_io_read_1_req;
  logic [7:0] BusyTable_2_io_read_2_req;
  logic [7:0] BusyTable_2_io_read_3_req;
  logic [7:0] BusyTable_2_io_read_4_req;
  logic [7:0] BusyTable_2_io_read_5_req;
  logic [7:0] BusyTable_2_io_read_6_req;
  logic [7:0] BusyTable_2_io_read_7_req;
  logic [7:0] BusyTable_2_io_read_8_req;
  logic [7:0] BusyTable_2_io_read_9_req;
  logic [7:0] BusyTable_2_io_read_10_req;
  logic [7:0] BusyTable_2_io_read_11_req;
  logic [7:0] BusyTable_2_io_read_12_req;
  logic [7:0] BusyTable_2_io_read_13_req;
  logic [7:0] BusyTable_2_io_read_14_req;
  logic [7:0] BusyTable_2_io_read_15_req;
  logic [7:0] BusyTable_2_io_read_16_req;
  logic [7:0] BusyTable_2_io_read_17_req;
  wire  BusyTable_2_g_io_read_0_resp, BusyTable_2_i_io_read_0_resp;
  wire  BusyTable_2_g_io_read_1_resp, BusyTable_2_i_io_read_1_resp;
  wire  BusyTable_2_g_io_read_2_resp, BusyTable_2_i_io_read_2_resp;
  wire  BusyTable_2_g_io_read_3_resp, BusyTable_2_i_io_read_3_resp;
  wire  BusyTable_2_g_io_read_4_resp, BusyTable_2_i_io_read_4_resp;
  wire  BusyTable_2_g_io_read_5_resp, BusyTable_2_i_io_read_5_resp;
  wire  BusyTable_2_g_io_read_6_resp, BusyTable_2_i_io_read_6_resp;
  wire  BusyTable_2_g_io_read_7_resp, BusyTable_2_i_io_read_7_resp;
  wire  BusyTable_2_g_io_read_8_resp, BusyTable_2_i_io_read_8_resp;
  wire  BusyTable_2_g_io_read_9_resp, BusyTable_2_i_io_read_9_resp;
  wire  BusyTable_2_g_io_read_10_resp, BusyTable_2_i_io_read_10_resp;
  wire  BusyTable_2_g_io_read_11_resp, BusyTable_2_i_io_read_11_resp;
  wire  BusyTable_2_g_io_read_12_resp, BusyTable_2_i_io_read_12_resp;
  wire  BusyTable_2_g_io_read_13_resp, BusyTable_2_i_io_read_13_resp;
  wire  BusyTable_2_g_io_read_14_resp, BusyTable_2_i_io_read_14_resp;
  wire  BusyTable_2_g_io_read_15_resp, BusyTable_2_i_io_read_15_resp;
  wire  BusyTable_2_g_io_read_16_resp, BusyTable_2_i_io_read_16_resp;
  wire  BusyTable_2_g_io_read_17_resp, BusyTable_2_i_io_read_17_resp;
  BusyTable_2 u_g_BusyTable_2 (
    .clock(clk),
    .reset(rst),
    .io_allocPregs_0_valid(BusyTable_2_io_allocPregs_0_valid),
    .io_allocPregs_0_bits(BusyTable_2_io_allocPregs_0_bits),
    .io_allocPregs_1_valid(BusyTable_2_io_allocPregs_1_valid),
    .io_allocPregs_1_bits(BusyTable_2_io_allocPregs_1_bits),
    .io_allocPregs_2_valid(BusyTable_2_io_allocPregs_2_valid),
    .io_allocPregs_2_bits(BusyTable_2_io_allocPregs_2_bits),
    .io_allocPregs_3_valid(BusyTable_2_io_allocPregs_3_valid),
    .io_allocPregs_3_bits(BusyTable_2_io_allocPregs_3_bits),
    .io_allocPregs_4_valid(BusyTable_2_io_allocPregs_4_valid),
    .io_allocPregs_4_bits(BusyTable_2_io_allocPregs_4_bits),
    .io_allocPregs_5_valid(BusyTable_2_io_allocPregs_5_valid),
    .io_allocPregs_5_bits(BusyTable_2_io_allocPregs_5_bits),
    .io_wbPregs_0_valid(BusyTable_2_io_wbPregs_0_valid),
    .io_wbPregs_0_bits(BusyTable_2_io_wbPregs_0_bits),
    .io_wbPregs_1_valid(BusyTable_2_io_wbPregs_1_valid),
    .io_wbPregs_1_bits(BusyTable_2_io_wbPregs_1_bits),
    .io_wbPregs_2_valid(BusyTable_2_io_wbPregs_2_valid),
    .io_wbPregs_2_bits(BusyTable_2_io_wbPregs_2_bits),
    .io_wbPregs_3_valid(BusyTable_2_io_wbPregs_3_valid),
    .io_wbPregs_3_bits(BusyTable_2_io_wbPregs_3_bits),
    .io_wbPregs_4_valid(BusyTable_2_io_wbPregs_4_valid),
    .io_wbPregs_4_bits(BusyTable_2_io_wbPregs_4_bits),
    .io_wbPregs_5_valid(BusyTable_2_io_wbPregs_5_valid),
    .io_wbPregs_5_bits(BusyTable_2_io_wbPregs_5_bits),
    .io_wakeUpFp_0_valid(BusyTable_2_io_wakeUpFp_0_valid),
    .io_wakeUpFp_0_bits_vecWen(BusyTable_2_io_wakeUpFp_0_bits_vecWen),
    .io_wakeUpFp_0_bits_pdest(BusyTable_2_io_wakeUpFp_0_bits_pdest),
    .io_wakeUpFp_0_bits_is0Lat(BusyTable_2_io_wakeUpFp_0_bits_is0Lat),
    .io_og0Cancel_8(BusyTable_2_io_og0Cancel_8),
    .io_read_0_req(BusyTable_2_io_read_0_req),
    .io_read_1_req(BusyTable_2_io_read_1_req),
    .io_read_2_req(BusyTable_2_io_read_2_req),
    .io_read_3_req(BusyTable_2_io_read_3_req),
    .io_read_4_req(BusyTable_2_io_read_4_req),
    .io_read_5_req(BusyTable_2_io_read_5_req),
    .io_read_6_req(BusyTable_2_io_read_6_req),
    .io_read_7_req(BusyTable_2_io_read_7_req),
    .io_read_8_req(BusyTable_2_io_read_8_req),
    .io_read_9_req(BusyTable_2_io_read_9_req),
    .io_read_10_req(BusyTable_2_io_read_10_req),
    .io_read_11_req(BusyTable_2_io_read_11_req),
    .io_read_12_req(BusyTable_2_io_read_12_req),
    .io_read_13_req(BusyTable_2_io_read_13_req),
    .io_read_14_req(BusyTable_2_io_read_14_req),
    .io_read_15_req(BusyTable_2_io_read_15_req),
    .io_read_16_req(BusyTable_2_io_read_16_req),
    .io_read_17_req(BusyTable_2_io_read_17_req),
    .io_read_0_resp(BusyTable_2_g_io_read_0_resp),
    .io_read_1_resp(BusyTable_2_g_io_read_1_resp),
    .io_read_2_resp(BusyTable_2_g_io_read_2_resp),
    .io_read_3_resp(BusyTable_2_g_io_read_3_resp),
    .io_read_4_resp(BusyTable_2_g_io_read_4_resp),
    .io_read_5_resp(BusyTable_2_g_io_read_5_resp),
    .io_read_6_resp(BusyTable_2_g_io_read_6_resp),
    .io_read_7_resp(BusyTable_2_g_io_read_7_resp),
    .io_read_8_resp(BusyTable_2_g_io_read_8_resp),
    .io_read_9_resp(BusyTable_2_g_io_read_9_resp),
    .io_read_10_resp(BusyTable_2_g_io_read_10_resp),
    .io_read_11_resp(BusyTable_2_g_io_read_11_resp),
    .io_read_12_resp(BusyTable_2_g_io_read_12_resp),
    .io_read_13_resp(BusyTable_2_g_io_read_13_resp),
    .io_read_14_resp(BusyTable_2_g_io_read_14_resp),
    .io_read_15_resp(BusyTable_2_g_io_read_15_resp),
    .io_read_16_resp(BusyTable_2_g_io_read_16_resp),
    .io_read_17_resp(BusyTable_2_g_io_read_17_resp)
  );
  BusyTable_2_xs u_i_BusyTable_2 (
    .clock(clk),
    .reset(rst),
    .io_allocPregs_0_valid(BusyTable_2_io_allocPregs_0_valid),
    .io_allocPregs_0_bits(BusyTable_2_io_allocPregs_0_bits),
    .io_allocPregs_1_valid(BusyTable_2_io_allocPregs_1_valid),
    .io_allocPregs_1_bits(BusyTable_2_io_allocPregs_1_bits),
    .io_allocPregs_2_valid(BusyTable_2_io_allocPregs_2_valid),
    .io_allocPregs_2_bits(BusyTable_2_io_allocPregs_2_bits),
    .io_allocPregs_3_valid(BusyTable_2_io_allocPregs_3_valid),
    .io_allocPregs_3_bits(BusyTable_2_io_allocPregs_3_bits),
    .io_allocPregs_4_valid(BusyTable_2_io_allocPregs_4_valid),
    .io_allocPregs_4_bits(BusyTable_2_io_allocPregs_4_bits),
    .io_allocPregs_5_valid(BusyTable_2_io_allocPregs_5_valid),
    .io_allocPregs_5_bits(BusyTable_2_io_allocPregs_5_bits),
    .io_wbPregs_0_valid(BusyTable_2_io_wbPregs_0_valid),
    .io_wbPregs_0_bits(BusyTable_2_io_wbPregs_0_bits),
    .io_wbPregs_1_valid(BusyTable_2_io_wbPregs_1_valid),
    .io_wbPregs_1_bits(BusyTable_2_io_wbPregs_1_bits),
    .io_wbPregs_2_valid(BusyTable_2_io_wbPregs_2_valid),
    .io_wbPregs_2_bits(BusyTable_2_io_wbPregs_2_bits),
    .io_wbPregs_3_valid(BusyTable_2_io_wbPregs_3_valid),
    .io_wbPregs_3_bits(BusyTable_2_io_wbPregs_3_bits),
    .io_wbPregs_4_valid(BusyTable_2_io_wbPregs_4_valid),
    .io_wbPregs_4_bits(BusyTable_2_io_wbPregs_4_bits),
    .io_wbPregs_5_valid(BusyTable_2_io_wbPregs_5_valid),
    .io_wbPregs_5_bits(BusyTable_2_io_wbPregs_5_bits),
    .io_wakeUpFp_0_valid(BusyTable_2_io_wakeUpFp_0_valid),
    .io_wakeUpFp_0_bits_vecWen(BusyTable_2_io_wakeUpFp_0_bits_vecWen),
    .io_wakeUpFp_0_bits_pdest(BusyTable_2_io_wakeUpFp_0_bits_pdest),
    .io_wakeUpFp_0_bits_is0Lat(BusyTable_2_io_wakeUpFp_0_bits_is0Lat),
    .io_og0Cancel_8(BusyTable_2_io_og0Cancel_8),
    .io_read_0_req(BusyTable_2_io_read_0_req),
    .io_read_1_req(BusyTable_2_io_read_1_req),
    .io_read_2_req(BusyTable_2_io_read_2_req),
    .io_read_3_req(BusyTable_2_io_read_3_req),
    .io_read_4_req(BusyTable_2_io_read_4_req),
    .io_read_5_req(BusyTable_2_io_read_5_req),
    .io_read_6_req(BusyTable_2_io_read_6_req),
    .io_read_7_req(BusyTable_2_io_read_7_req),
    .io_read_8_req(BusyTable_2_io_read_8_req),
    .io_read_9_req(BusyTable_2_io_read_9_req),
    .io_read_10_req(BusyTable_2_io_read_10_req),
    .io_read_11_req(BusyTable_2_io_read_11_req),
    .io_read_12_req(BusyTable_2_io_read_12_req),
    .io_read_13_req(BusyTable_2_io_read_13_req),
    .io_read_14_req(BusyTable_2_io_read_14_req),
    .io_read_15_req(BusyTable_2_io_read_15_req),
    .io_read_16_req(BusyTable_2_io_read_16_req),
    .io_read_17_req(BusyTable_2_io_read_17_req),
    .io_read_0_resp(BusyTable_2_i_io_read_0_resp),
    .io_read_1_resp(BusyTable_2_i_io_read_1_resp),
    .io_read_2_resp(BusyTable_2_i_io_read_2_resp),
    .io_read_3_resp(BusyTable_2_i_io_read_3_resp),
    .io_read_4_resp(BusyTable_2_i_io_read_4_resp),
    .io_read_5_resp(BusyTable_2_i_io_read_5_resp),
    .io_read_6_resp(BusyTable_2_i_io_read_6_resp),
    .io_read_7_resp(BusyTable_2_i_io_read_7_resp),
    .io_read_8_resp(BusyTable_2_i_io_read_8_resp),
    .io_read_9_resp(BusyTable_2_i_io_read_9_resp),
    .io_read_10_resp(BusyTable_2_i_io_read_10_resp),
    .io_read_11_resp(BusyTable_2_i_io_read_11_resp),
    .io_read_12_resp(BusyTable_2_i_io_read_12_resp),
    .io_read_13_resp(BusyTable_2_i_io_read_13_resp),
    .io_read_14_resp(BusyTable_2_i_io_read_14_resp),
    .io_read_15_resp(BusyTable_2_i_io_read_15_resp),
    .io_read_16_resp(BusyTable_2_i_io_read_16_resp),
    .io_read_17_resp(BusyTable_2_i_io_read_17_resp)
  );
  always @(negedge clk) begin
    if (rst) begin
      BusyTable_2_io_allocPregs_0_valid <= 1'b0;
      BusyTable_2_io_allocPregs_1_valid <= 1'b0;
      BusyTable_2_io_allocPregs_2_valid <= 1'b0;
      BusyTable_2_io_allocPregs_3_valid <= 1'b0;
      BusyTable_2_io_allocPregs_4_valid <= 1'b0;
      BusyTable_2_io_allocPregs_5_valid <= 1'b0;
      BusyTable_2_io_wbPregs_0_valid <= 1'b0;
      BusyTable_2_io_wbPregs_1_valid <= 1'b0;
      BusyTable_2_io_wbPregs_2_valid <= 1'b0;
      BusyTable_2_io_wbPregs_3_valid <= 1'b0;
      BusyTable_2_io_wbPregs_4_valid <= 1'b0;
      BusyTable_2_io_wbPregs_5_valid <= 1'b0;
      BusyTable_2_io_wakeUpFp_0_valid <= 1'b0;
    end else begin
      BusyTable_2_io_allocPregs_0_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_2_io_allocPregs_0_bits <= rand_preg(128);
      BusyTable_2_io_allocPregs_1_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_2_io_allocPregs_1_bits <= rand_preg(128);
      BusyTable_2_io_allocPregs_2_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_2_io_allocPregs_2_bits <= rand_preg(128);
      BusyTable_2_io_allocPregs_3_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_2_io_allocPregs_3_bits <= rand_preg(128);
      BusyTable_2_io_allocPregs_4_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_2_io_allocPregs_4_bits <= rand_preg(128);
      BusyTable_2_io_allocPregs_5_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_2_io_allocPregs_5_bits <= rand_preg(128);
      BusyTable_2_io_wbPregs_0_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_2_io_wbPregs_0_bits <= rand_preg(128);
      BusyTable_2_io_wbPregs_1_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_2_io_wbPregs_1_bits <= rand_preg(128);
      BusyTable_2_io_wbPregs_2_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_2_io_wbPregs_2_bits <= rand_preg(128);
      BusyTable_2_io_wbPregs_3_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_2_io_wbPregs_3_bits <= rand_preg(128);
      BusyTable_2_io_wbPregs_4_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_2_io_wbPregs_4_bits <= rand_preg(128);
      BusyTable_2_io_wbPregs_5_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_2_io_wbPregs_5_bits <= rand_preg(128);
      BusyTable_2_io_wakeUpFp_0_valid <= ($urandom_range(0, 9) < 7);
      BusyTable_2_io_wakeUpFp_0_bits_vecWen <= ($urandom_range(0, 9) < 8);
      BusyTable_2_io_wakeUpFp_0_bits_pdest <= rand_preg(128);
      BusyTable_2_io_wakeUpFp_0_bits_is0Lat <= ($urandom_range(0, 9) < 5);
      BusyTable_2_io_og0Cancel_8 <= ($urandom_range(0, 9) < 3);
      BusyTable_2_io_read_0_req <= rand_preg(128);
      BusyTable_2_io_read_1_req <= rand_preg(128);
      BusyTable_2_io_read_2_req <= rand_preg(128);
      BusyTable_2_io_read_3_req <= rand_preg(128);
      BusyTable_2_io_read_4_req <= rand_preg(128);
      BusyTable_2_io_read_5_req <= rand_preg(128);
      BusyTable_2_io_read_6_req <= rand_preg(128);
      BusyTable_2_io_read_7_req <= rand_preg(128);
      BusyTable_2_io_read_8_req <= rand_preg(128);
      BusyTable_2_io_read_9_req <= rand_preg(128);
      BusyTable_2_io_read_10_req <= rand_preg(128);
      BusyTable_2_io_read_11_req <= rand_preg(128);
      BusyTable_2_io_read_12_req <= rand_preg(128);
      BusyTable_2_io_read_13_req <= rand_preg(128);
      BusyTable_2_io_read_14_req <= rand_preg(128);
      BusyTable_2_io_read_15_req <= rand_preg(128);
      BusyTable_2_io_read_16_req <= rand_preg(128);
      BusyTable_2_io_read_17_req <= rand_preg(128);
    end
  end
  always @(negedge clk) if (!rst) begin
    #4;
    checks++;
    if (BusyTable_2_g_io_read_0_resp !== BusyTable_2_i_io_read_0_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_0_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_0_resp, BusyTable_2_i_io_read_0_resp); end
    checks++;
    if (BusyTable_2_g_io_read_1_resp !== BusyTable_2_i_io_read_1_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_1_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_1_resp, BusyTable_2_i_io_read_1_resp); end
    checks++;
    if (BusyTable_2_g_io_read_2_resp !== BusyTable_2_i_io_read_2_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_2_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_2_resp, BusyTable_2_i_io_read_2_resp); end
    checks++;
    if (BusyTable_2_g_io_read_3_resp !== BusyTable_2_i_io_read_3_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_3_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_3_resp, BusyTable_2_i_io_read_3_resp); end
    checks++;
    if (BusyTable_2_g_io_read_4_resp !== BusyTable_2_i_io_read_4_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_4_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_4_resp, BusyTable_2_i_io_read_4_resp); end
    checks++;
    if (BusyTable_2_g_io_read_5_resp !== BusyTable_2_i_io_read_5_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_5_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_5_resp, BusyTable_2_i_io_read_5_resp); end
    checks++;
    if (BusyTable_2_g_io_read_6_resp !== BusyTable_2_i_io_read_6_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_6_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_6_resp, BusyTable_2_i_io_read_6_resp); end
    checks++;
    if (BusyTable_2_g_io_read_7_resp !== BusyTable_2_i_io_read_7_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_7_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_7_resp, BusyTable_2_i_io_read_7_resp); end
    checks++;
    if (BusyTable_2_g_io_read_8_resp !== BusyTable_2_i_io_read_8_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_8_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_8_resp, BusyTable_2_i_io_read_8_resp); end
    checks++;
    if (BusyTable_2_g_io_read_9_resp !== BusyTable_2_i_io_read_9_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_9_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_9_resp, BusyTable_2_i_io_read_9_resp); end
    checks++;
    if (BusyTable_2_g_io_read_10_resp !== BusyTable_2_i_io_read_10_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_10_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_10_resp, BusyTable_2_i_io_read_10_resp); end
    checks++;
    if (BusyTable_2_g_io_read_11_resp !== BusyTable_2_i_io_read_11_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_11_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_11_resp, BusyTable_2_i_io_read_11_resp); end
    checks++;
    if (BusyTable_2_g_io_read_12_resp !== BusyTable_2_i_io_read_12_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_12_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_12_resp, BusyTable_2_i_io_read_12_resp); end
    checks++;
    if (BusyTable_2_g_io_read_13_resp !== BusyTable_2_i_io_read_13_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_13_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_13_resp, BusyTable_2_i_io_read_13_resp); end
    checks++;
    if (BusyTable_2_g_io_read_14_resp !== BusyTable_2_i_io_read_14_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_14_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_14_resp, BusyTable_2_i_io_read_14_resp); end
    checks++;
    if (BusyTable_2_g_io_read_15_resp !== BusyTable_2_i_io_read_15_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_15_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_15_resp, BusyTable_2_i_io_read_15_resp); end
    checks++;
    if (BusyTable_2_g_io_read_16_resp !== BusyTable_2_i_io_read_16_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_16_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_16_resp, BusyTable_2_i_io_read_16_resp); end
    checks++;
    if (BusyTable_2_g_io_read_17_resp !== BusyTable_2_i_io_read_17_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_2.io_read_17_resp mismatch: g=%h i=%h", $time, BusyTable_2_g_io_read_17_resp, BusyTable_2_i_io_read_17_resp); end
  end
  // ---- 覆盖事件统计（只读 golden 侧，不看重写侧，免得自证）----
  always @(negedge clk) if (!rst) begin
    #4;
    for (int a = 0; a < 6; a++) begin
      logic v; logic [7:0] b;
      case (a)
        0: begin v = BusyTable_2_io_allocPregs_0_valid; b = BusyTable_2_io_allocPregs_0_bits; end
        1: begin v = BusyTable_2_io_allocPregs_1_valid; b = BusyTable_2_io_allocPregs_1_bits; end
        2: begin v = BusyTable_2_io_allocPregs_2_valid; b = BusyTable_2_io_allocPregs_2_bits; end
        3: begin v = BusyTable_2_io_allocPregs_3_valid; b = BusyTable_2_io_allocPregs_3_bits; end
        4: begin v = BusyTable_2_io_allocPregs_4_valid; b = BusyTable_2_io_allocPregs_4_bits; end
        5: begin v = BusyTable_2_io_allocPregs_5_valid; b = BusyTable_2_io_allocPregs_5_bits; end
        default: begin v = 1'b0; b = 8'h0; end
      endcase
      if (v && b < 128) begin
        for (int w = 0; w < 6; w++) begin
          logic wv; logic [7:0] wb;
          case (w)
            0: begin wv = BusyTable_2_io_wbPregs_0_valid; wb = BusyTable_2_io_wbPregs_0_bits; end
            1: begin wv = BusyTable_2_io_wbPregs_1_valid; wb = BusyTable_2_io_wbPregs_1_bits; end
            2: begin wv = BusyTable_2_io_wbPregs_2_valid; wb = BusyTable_2_io_wbPregs_2_bits; end
            3: begin wv = BusyTable_2_io_wbPregs_3_valid; wb = BusyTable_2_io_wbPregs_3_bits; end
            4: begin wv = BusyTable_2_io_wbPregs_4_valid; wb = BusyTable_2_io_wbPregs_4_bits; end
            5: begin wv = BusyTable_2_io_wbPregs_5_valid; wb = BusyTable_2_io_wbPregs_5_bits; end
            default: begin wv = 1'b0; wb = 8'h0; end
          endcase
          if (wv && wb == b) cov_alloc_wb_clash++;
        end
        for (int k = 0; k < 1; k++) begin
          logic kv; logic [7:0] kp;
          case (k)
            0: begin kv = BusyTable_2_io_wakeUpFp_0_valid && BusyTable_2_io_wakeUpFp_0_bits_vecWen; kp = BusyTable_2_io_wakeUpFp_0_bits_pdest; end
            default: begin kv = 1'b0; kp = 8'h0; end
          endcase
          if (kv && kp == b) cov_wake_wb_clash++;
        end
      end
    end
    if (BusyTable_2_io_wakeUpFp_0_valid && BusyTable_2_io_wakeUpFp_0_bits_vecWen && (BusyTable_2_io_wakeUpFp_0_bits_is0Lat) && (BusyTable_2_io_og0Cancel_8)) cov_og0_kill++;
    for (int r = 0; r < 18; r++) begin
      logic [7:0] q;
      case (r)
        0: q = BusyTable_2_io_read_0_req;
        1: q = BusyTable_2_io_read_1_req;
        2: q = BusyTable_2_io_read_2_req;
        3: q = BusyTable_2_io_read_3_req;
        4: q = BusyTable_2_io_read_4_req;
        5: q = BusyTable_2_io_read_5_req;
        6: q = BusyTable_2_io_read_6_req;
        7: q = BusyTable_2_io_read_7_req;
        8: q = BusyTable_2_io_read_8_req;
        9: q = BusyTable_2_io_read_9_req;
        10: q = BusyTable_2_io_read_10_req;
        11: q = BusyTable_2_io_read_11_req;
        12: q = BusyTable_2_io_read_12_req;
        13: q = BusyTable_2_io_read_13_req;
        14: q = BusyTable_2_io_read_14_req;
        15: q = BusyTable_2_io_read_15_req;
        16: q = BusyTable_2_io_read_16_req;
        17: q = BusyTable_2_io_read_17_req;
        default: q = 8'h0;
      endcase
      if (q >= 128) cov_read_oob++;
      for (int a = 0; a < 6; a++) begin
        logic v; logic [7:0] b;
        case (a)
          0: begin v = BusyTable_2_io_allocPregs_0_valid; b = BusyTable_2_io_allocPregs_0_bits; end
          1: begin v = BusyTable_2_io_allocPregs_1_valid; b = BusyTable_2_io_allocPregs_1_bits; end
          2: begin v = BusyTable_2_io_allocPregs_2_valid; b = BusyTable_2_io_allocPregs_2_bits; end
          3: begin v = BusyTable_2_io_allocPregs_3_valid; b = BusyTable_2_io_allocPregs_3_bits; end
          4: begin v = BusyTable_2_io_allocPregs_4_valid; b = BusyTable_2_io_allocPregs_4_bits; end
          5: begin v = BusyTable_2_io_allocPregs_5_valid; b = BusyTable_2_io_allocPregs_5_bits; end
          default: begin v = 1'b0; b = 8'h0; end
        endcase
        if (v && b == q) cov_alloc_bypass++;
      end
    end
  end

  // ==========================================================================
  // BusyTable_3 —— V0 向量掩码寄存器堆（V0WB），表深 22，写回口 6，读口 6，唤醒 1 路
  // ==========================================================================
  logic BusyTable_3_io_allocPregs_0_valid;
  logic [7:0] BusyTable_3_io_allocPregs_0_bits;
  logic BusyTable_3_io_allocPregs_1_valid;
  logic [7:0] BusyTable_3_io_allocPregs_1_bits;
  logic BusyTable_3_io_allocPregs_2_valid;
  logic [7:0] BusyTable_3_io_allocPregs_2_bits;
  logic BusyTable_3_io_allocPregs_3_valid;
  logic [7:0] BusyTable_3_io_allocPregs_3_bits;
  logic BusyTable_3_io_allocPregs_4_valid;
  logic [7:0] BusyTable_3_io_allocPregs_4_bits;
  logic BusyTable_3_io_allocPregs_5_valid;
  logic [7:0] BusyTable_3_io_allocPregs_5_bits;
  logic BusyTable_3_io_wbPregs_0_valid;
  logic [7:0] BusyTable_3_io_wbPregs_0_bits;
  logic BusyTable_3_io_wbPregs_1_valid;
  logic [7:0] BusyTable_3_io_wbPregs_1_bits;
  logic BusyTable_3_io_wbPregs_2_valid;
  logic [7:0] BusyTable_3_io_wbPregs_2_bits;
  logic BusyTable_3_io_wbPregs_3_valid;
  logic [7:0] BusyTable_3_io_wbPregs_3_bits;
  logic BusyTable_3_io_wbPregs_4_valid;
  logic [7:0] BusyTable_3_io_wbPregs_4_bits;
  logic BusyTable_3_io_wbPregs_5_valid;
  logic [7:0] BusyTable_3_io_wbPregs_5_bits;
  logic BusyTable_3_io_wakeUpFp_0_valid;
  logic BusyTable_3_io_wakeUpFp_0_bits_v0Wen;
  logic [7:0] BusyTable_3_io_wakeUpFp_0_bits_pdest;
  logic BusyTable_3_io_wakeUpFp_0_bits_is0Lat;
  logic BusyTable_3_io_og0Cancel_8;
  logic [7:0] BusyTable_3_io_read_0_req;
  logic [7:0] BusyTable_3_io_read_1_req;
  logic [7:0] BusyTable_3_io_read_2_req;
  logic [7:0] BusyTable_3_io_read_3_req;
  logic [7:0] BusyTable_3_io_read_4_req;
  logic [7:0] BusyTable_3_io_read_5_req;
  wire  BusyTable_3_g_io_read_0_resp, BusyTable_3_i_io_read_0_resp;
  wire  BusyTable_3_g_io_read_1_resp, BusyTable_3_i_io_read_1_resp;
  wire  BusyTable_3_g_io_read_2_resp, BusyTable_3_i_io_read_2_resp;
  wire  BusyTable_3_g_io_read_3_resp, BusyTable_3_i_io_read_3_resp;
  wire  BusyTable_3_g_io_read_4_resp, BusyTable_3_i_io_read_4_resp;
  wire  BusyTable_3_g_io_read_5_resp, BusyTable_3_i_io_read_5_resp;
  BusyTable_3 u_g_BusyTable_3 (
    .clock(clk),
    .reset(rst),
    .io_allocPregs_0_valid(BusyTable_3_io_allocPregs_0_valid),
    .io_allocPregs_0_bits(BusyTable_3_io_allocPregs_0_bits),
    .io_allocPregs_1_valid(BusyTable_3_io_allocPregs_1_valid),
    .io_allocPregs_1_bits(BusyTable_3_io_allocPregs_1_bits),
    .io_allocPregs_2_valid(BusyTable_3_io_allocPregs_2_valid),
    .io_allocPregs_2_bits(BusyTable_3_io_allocPregs_2_bits),
    .io_allocPregs_3_valid(BusyTable_3_io_allocPregs_3_valid),
    .io_allocPregs_3_bits(BusyTable_3_io_allocPregs_3_bits),
    .io_allocPregs_4_valid(BusyTable_3_io_allocPregs_4_valid),
    .io_allocPregs_4_bits(BusyTable_3_io_allocPregs_4_bits),
    .io_allocPregs_5_valid(BusyTable_3_io_allocPregs_5_valid),
    .io_allocPregs_5_bits(BusyTable_3_io_allocPregs_5_bits),
    .io_wbPregs_0_valid(BusyTable_3_io_wbPregs_0_valid),
    .io_wbPregs_0_bits(BusyTable_3_io_wbPregs_0_bits),
    .io_wbPregs_1_valid(BusyTable_3_io_wbPregs_1_valid),
    .io_wbPregs_1_bits(BusyTable_3_io_wbPregs_1_bits),
    .io_wbPregs_2_valid(BusyTable_3_io_wbPregs_2_valid),
    .io_wbPregs_2_bits(BusyTable_3_io_wbPregs_2_bits),
    .io_wbPregs_3_valid(BusyTable_3_io_wbPregs_3_valid),
    .io_wbPregs_3_bits(BusyTable_3_io_wbPregs_3_bits),
    .io_wbPregs_4_valid(BusyTable_3_io_wbPregs_4_valid),
    .io_wbPregs_4_bits(BusyTable_3_io_wbPregs_4_bits),
    .io_wbPregs_5_valid(BusyTable_3_io_wbPregs_5_valid),
    .io_wbPregs_5_bits(BusyTable_3_io_wbPregs_5_bits),
    .io_wakeUpFp_0_valid(BusyTable_3_io_wakeUpFp_0_valid),
    .io_wakeUpFp_0_bits_v0Wen(BusyTable_3_io_wakeUpFp_0_bits_v0Wen),
    .io_wakeUpFp_0_bits_pdest(BusyTable_3_io_wakeUpFp_0_bits_pdest),
    .io_wakeUpFp_0_bits_is0Lat(BusyTable_3_io_wakeUpFp_0_bits_is0Lat),
    .io_og0Cancel_8(BusyTable_3_io_og0Cancel_8),
    .io_read_0_req(BusyTable_3_io_read_0_req),
    .io_read_1_req(BusyTable_3_io_read_1_req),
    .io_read_2_req(BusyTable_3_io_read_2_req),
    .io_read_3_req(BusyTable_3_io_read_3_req),
    .io_read_4_req(BusyTable_3_io_read_4_req),
    .io_read_5_req(BusyTable_3_io_read_5_req),
    .io_read_0_resp(BusyTable_3_g_io_read_0_resp),
    .io_read_1_resp(BusyTable_3_g_io_read_1_resp),
    .io_read_2_resp(BusyTable_3_g_io_read_2_resp),
    .io_read_3_resp(BusyTable_3_g_io_read_3_resp),
    .io_read_4_resp(BusyTable_3_g_io_read_4_resp),
    .io_read_5_resp(BusyTable_3_g_io_read_5_resp)
  );
  BusyTable_3_xs u_i_BusyTable_3 (
    .clock(clk),
    .reset(rst),
    .io_allocPregs_0_valid(BusyTable_3_io_allocPregs_0_valid),
    .io_allocPregs_0_bits(BusyTable_3_io_allocPregs_0_bits),
    .io_allocPregs_1_valid(BusyTable_3_io_allocPregs_1_valid),
    .io_allocPregs_1_bits(BusyTable_3_io_allocPregs_1_bits),
    .io_allocPregs_2_valid(BusyTable_3_io_allocPregs_2_valid),
    .io_allocPregs_2_bits(BusyTable_3_io_allocPregs_2_bits),
    .io_allocPregs_3_valid(BusyTable_3_io_allocPregs_3_valid),
    .io_allocPregs_3_bits(BusyTable_3_io_allocPregs_3_bits),
    .io_allocPregs_4_valid(BusyTable_3_io_allocPregs_4_valid),
    .io_allocPregs_4_bits(BusyTable_3_io_allocPregs_4_bits),
    .io_allocPregs_5_valid(BusyTable_3_io_allocPregs_5_valid),
    .io_allocPregs_5_bits(BusyTable_3_io_allocPregs_5_bits),
    .io_wbPregs_0_valid(BusyTable_3_io_wbPregs_0_valid),
    .io_wbPregs_0_bits(BusyTable_3_io_wbPregs_0_bits),
    .io_wbPregs_1_valid(BusyTable_3_io_wbPregs_1_valid),
    .io_wbPregs_1_bits(BusyTable_3_io_wbPregs_1_bits),
    .io_wbPregs_2_valid(BusyTable_3_io_wbPregs_2_valid),
    .io_wbPregs_2_bits(BusyTable_3_io_wbPregs_2_bits),
    .io_wbPregs_3_valid(BusyTable_3_io_wbPregs_3_valid),
    .io_wbPregs_3_bits(BusyTable_3_io_wbPregs_3_bits),
    .io_wbPregs_4_valid(BusyTable_3_io_wbPregs_4_valid),
    .io_wbPregs_4_bits(BusyTable_3_io_wbPregs_4_bits),
    .io_wbPregs_5_valid(BusyTable_3_io_wbPregs_5_valid),
    .io_wbPregs_5_bits(BusyTable_3_io_wbPregs_5_bits),
    .io_wakeUpFp_0_valid(BusyTable_3_io_wakeUpFp_0_valid),
    .io_wakeUpFp_0_bits_v0Wen(BusyTable_3_io_wakeUpFp_0_bits_v0Wen),
    .io_wakeUpFp_0_bits_pdest(BusyTable_3_io_wakeUpFp_0_bits_pdest),
    .io_wakeUpFp_0_bits_is0Lat(BusyTable_3_io_wakeUpFp_0_bits_is0Lat),
    .io_og0Cancel_8(BusyTable_3_io_og0Cancel_8),
    .io_read_0_req(BusyTable_3_io_read_0_req),
    .io_read_1_req(BusyTable_3_io_read_1_req),
    .io_read_2_req(BusyTable_3_io_read_2_req),
    .io_read_3_req(BusyTable_3_io_read_3_req),
    .io_read_4_req(BusyTable_3_io_read_4_req),
    .io_read_5_req(BusyTable_3_io_read_5_req),
    .io_read_0_resp(BusyTable_3_i_io_read_0_resp),
    .io_read_1_resp(BusyTable_3_i_io_read_1_resp),
    .io_read_2_resp(BusyTable_3_i_io_read_2_resp),
    .io_read_3_resp(BusyTable_3_i_io_read_3_resp),
    .io_read_4_resp(BusyTable_3_i_io_read_4_resp),
    .io_read_5_resp(BusyTable_3_i_io_read_5_resp)
  );
  always @(negedge clk) begin
    if (rst) begin
      BusyTable_3_io_allocPregs_0_valid <= 1'b0;
      BusyTable_3_io_allocPregs_1_valid <= 1'b0;
      BusyTable_3_io_allocPregs_2_valid <= 1'b0;
      BusyTable_3_io_allocPregs_3_valid <= 1'b0;
      BusyTable_3_io_allocPregs_4_valid <= 1'b0;
      BusyTable_3_io_allocPregs_5_valid <= 1'b0;
      BusyTable_3_io_wbPregs_0_valid <= 1'b0;
      BusyTable_3_io_wbPregs_1_valid <= 1'b0;
      BusyTable_3_io_wbPregs_2_valid <= 1'b0;
      BusyTable_3_io_wbPregs_3_valid <= 1'b0;
      BusyTable_3_io_wbPregs_4_valid <= 1'b0;
      BusyTable_3_io_wbPregs_5_valid <= 1'b0;
      BusyTable_3_io_wakeUpFp_0_valid <= 1'b0;
    end else begin
      BusyTable_3_io_allocPregs_0_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_3_io_allocPregs_0_bits <= rand_preg(22);
      BusyTable_3_io_allocPregs_1_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_3_io_allocPregs_1_bits <= rand_preg(22);
      BusyTable_3_io_allocPregs_2_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_3_io_allocPregs_2_bits <= rand_preg(22);
      BusyTable_3_io_allocPregs_3_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_3_io_allocPregs_3_bits <= rand_preg(22);
      BusyTable_3_io_allocPregs_4_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_3_io_allocPregs_4_bits <= rand_preg(22);
      BusyTable_3_io_allocPregs_5_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_3_io_allocPregs_5_bits <= rand_preg(22);
      BusyTable_3_io_wbPregs_0_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_3_io_wbPregs_0_bits <= rand_preg(22);
      BusyTable_3_io_wbPregs_1_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_3_io_wbPregs_1_bits <= rand_preg(22);
      BusyTable_3_io_wbPregs_2_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_3_io_wbPregs_2_bits <= rand_preg(22);
      BusyTable_3_io_wbPregs_3_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_3_io_wbPregs_3_bits <= rand_preg(22);
      BusyTable_3_io_wbPregs_4_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_3_io_wbPregs_4_bits <= rand_preg(22);
      BusyTable_3_io_wbPregs_5_valid <= ($urandom_range(0, 9) < 5);
      BusyTable_3_io_wbPregs_5_bits <= rand_preg(22);
      BusyTable_3_io_wakeUpFp_0_valid <= ($urandom_range(0, 9) < 7);
      BusyTable_3_io_wakeUpFp_0_bits_v0Wen <= ($urandom_range(0, 9) < 8);
      BusyTable_3_io_wakeUpFp_0_bits_pdest <= rand_preg(22);
      BusyTable_3_io_wakeUpFp_0_bits_is0Lat <= ($urandom_range(0, 9) < 5);
      BusyTable_3_io_og0Cancel_8 <= ($urandom_range(0, 9) < 3);
      BusyTable_3_io_read_0_req <= rand_preg(22);
      BusyTable_3_io_read_1_req <= rand_preg(22);
      BusyTable_3_io_read_2_req <= rand_preg(22);
      BusyTable_3_io_read_3_req <= rand_preg(22);
      BusyTable_3_io_read_4_req <= rand_preg(22);
      BusyTable_3_io_read_5_req <= rand_preg(22);
    end
  end
  always @(negedge clk) if (!rst) begin
    #4;
    checks++;
    if (BusyTable_3_g_io_read_0_resp !== BusyTable_3_i_io_read_0_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_3.io_read_0_resp mismatch: g=%h i=%h", $time, BusyTable_3_g_io_read_0_resp, BusyTable_3_i_io_read_0_resp); end
    checks++;
    if (BusyTable_3_g_io_read_1_resp !== BusyTable_3_i_io_read_1_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_3.io_read_1_resp mismatch: g=%h i=%h", $time, BusyTable_3_g_io_read_1_resp, BusyTable_3_i_io_read_1_resp); end
    checks++;
    if (BusyTable_3_g_io_read_2_resp !== BusyTable_3_i_io_read_2_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_3.io_read_2_resp mismatch: g=%h i=%h", $time, BusyTable_3_g_io_read_2_resp, BusyTable_3_i_io_read_2_resp); end
    checks++;
    if (BusyTable_3_g_io_read_3_resp !== BusyTable_3_i_io_read_3_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_3.io_read_3_resp mismatch: g=%h i=%h", $time, BusyTable_3_g_io_read_3_resp, BusyTable_3_i_io_read_3_resp); end
    checks++;
    if (BusyTable_3_g_io_read_4_resp !== BusyTable_3_i_io_read_4_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_3.io_read_4_resp mismatch: g=%h i=%h", $time, BusyTable_3_g_io_read_4_resp, BusyTable_3_i_io_read_4_resp); end
    checks++;
    if (BusyTable_3_g_io_read_5_resp !== BusyTable_3_i_io_read_5_resp) begin errors++;
      if (errors < 40) $display("[%0t] BusyTable_3.io_read_5_resp mismatch: g=%h i=%h", $time, BusyTable_3_g_io_read_5_resp, BusyTable_3_i_io_read_5_resp); end
  end
  // ---- 覆盖事件统计（只读 golden 侧，不看重写侧，免得自证）----
  always @(negedge clk) if (!rst) begin
    #4;
    for (int a = 0; a < 6; a++) begin
      logic v; logic [7:0] b;
      case (a)
        0: begin v = BusyTable_3_io_allocPregs_0_valid; b = BusyTable_3_io_allocPregs_0_bits; end
        1: begin v = BusyTable_3_io_allocPregs_1_valid; b = BusyTable_3_io_allocPregs_1_bits; end
        2: begin v = BusyTable_3_io_allocPregs_2_valid; b = BusyTable_3_io_allocPregs_2_bits; end
        3: begin v = BusyTable_3_io_allocPregs_3_valid; b = BusyTable_3_io_allocPregs_3_bits; end
        4: begin v = BusyTable_3_io_allocPregs_4_valid; b = BusyTable_3_io_allocPregs_4_bits; end
        5: begin v = BusyTable_3_io_allocPregs_5_valid; b = BusyTable_3_io_allocPregs_5_bits; end
        default: begin v = 1'b0; b = 8'h0; end
      endcase
      if (v && b < 22) begin
        for (int w = 0; w < 6; w++) begin
          logic wv; logic [7:0] wb;
          case (w)
            0: begin wv = BusyTable_3_io_wbPregs_0_valid; wb = BusyTable_3_io_wbPregs_0_bits; end
            1: begin wv = BusyTable_3_io_wbPregs_1_valid; wb = BusyTable_3_io_wbPregs_1_bits; end
            2: begin wv = BusyTable_3_io_wbPregs_2_valid; wb = BusyTable_3_io_wbPregs_2_bits; end
            3: begin wv = BusyTable_3_io_wbPregs_3_valid; wb = BusyTable_3_io_wbPregs_3_bits; end
            4: begin wv = BusyTable_3_io_wbPregs_4_valid; wb = BusyTable_3_io_wbPregs_4_bits; end
            5: begin wv = BusyTable_3_io_wbPregs_5_valid; wb = BusyTable_3_io_wbPregs_5_bits; end
            default: begin wv = 1'b0; wb = 8'h0; end
          endcase
          if (wv && wb == b) cov_alloc_wb_clash++;
        end
        for (int k = 0; k < 1; k++) begin
          logic kv; logic [7:0] kp;
          case (k)
            0: begin kv = BusyTable_3_io_wakeUpFp_0_valid && BusyTable_3_io_wakeUpFp_0_bits_v0Wen; kp = BusyTable_3_io_wakeUpFp_0_bits_pdest; end
            default: begin kv = 1'b0; kp = 8'h0; end
          endcase
          if (kv && kp == b) cov_wake_wb_clash++;
        end
      end
    end
    if (BusyTable_3_io_wakeUpFp_0_valid && BusyTable_3_io_wakeUpFp_0_bits_v0Wen && (BusyTable_3_io_wakeUpFp_0_bits_is0Lat) && (BusyTable_3_io_og0Cancel_8)) cov_og0_kill++;
    for (int r = 0; r < 6; r++) begin
      logic [7:0] q;
      case (r)
        0: q = BusyTable_3_io_read_0_req;
        1: q = BusyTable_3_io_read_1_req;
        2: q = BusyTable_3_io_read_2_req;
        3: q = BusyTable_3_io_read_3_req;
        4: q = BusyTable_3_io_read_4_req;
        5: q = BusyTable_3_io_read_5_req;
        default: q = 8'h0;
      endcase
      if (q >= 22) cov_read_oob++;
      for (int a = 0; a < 6; a++) begin
        logic v; logic [7:0] b;
        case (a)
          0: begin v = BusyTable_3_io_allocPregs_0_valid; b = BusyTable_3_io_allocPregs_0_bits; end
          1: begin v = BusyTable_3_io_allocPregs_1_valid; b = BusyTable_3_io_allocPregs_1_bits; end
          2: begin v = BusyTable_3_io_allocPregs_2_valid; b = BusyTable_3_io_allocPregs_2_bits; end
          3: begin v = BusyTable_3_io_allocPregs_3_valid; b = BusyTable_3_io_allocPregs_3_bits; end
          4: begin v = BusyTable_3_io_allocPregs_4_valid; b = BusyTable_3_io_allocPregs_4_bits; end
          5: begin v = BusyTable_3_io_allocPregs_5_valid; b = BusyTable_3_io_allocPregs_5_bits; end
          default: begin v = 1'b0; b = 8'h0; end
        endcase
        if (v && b == q) cov_alloc_bypass++;
      end
    end
  end

  // ==========================================================================
  // VlBusyTable —— Vl 向量长度寄存器堆（VlWB），表深 32，写回口 4，读口 6，唤醒 0 路
  // ==========================================================================
  logic VlBusyTable_io_allocPregs_0_valid;
  logic [7:0] VlBusyTable_io_allocPregs_0_bits;
  logic VlBusyTable_io_allocPregs_1_valid;
  logic [7:0] VlBusyTable_io_allocPregs_1_bits;
  logic VlBusyTable_io_allocPregs_2_valid;
  logic [7:0] VlBusyTable_io_allocPregs_2_bits;
  logic VlBusyTable_io_allocPregs_3_valid;
  logic [7:0] VlBusyTable_io_allocPregs_3_bits;
  logic VlBusyTable_io_allocPregs_4_valid;
  logic [7:0] VlBusyTable_io_allocPregs_4_bits;
  logic VlBusyTable_io_allocPregs_5_valid;
  logic [7:0] VlBusyTable_io_allocPregs_5_bits;
  logic VlBusyTable_io_wbPregs_0_valid;
  logic [7:0] VlBusyTable_io_wbPregs_0_bits;
  logic VlBusyTable_io_wbPregs_1_valid;
  logic [7:0] VlBusyTable_io_wbPregs_1_bits;
  logic VlBusyTable_io_wbPregs_2_valid;
  logic [7:0] VlBusyTable_io_wbPregs_2_bits;
  logic VlBusyTable_io_wbPregs_3_valid;
  logic [7:0] VlBusyTable_io_wbPregs_3_bits;
  logic [7:0] VlBusyTable_io_read_0_req;
  logic [7:0] VlBusyTable_io_read_1_req;
  logic [7:0] VlBusyTable_io_read_2_req;
  logic [7:0] VlBusyTable_io_read_3_req;
  logic [7:0] VlBusyTable_io_read_4_req;
  logic [7:0] VlBusyTable_io_read_5_req;
  logic VlBusyTable_io_vl_Wb_vlWriteBackInfo_vlFromIntIsZero;
  logic VlBusyTable_io_vl_Wb_vlWriteBackInfo_vlFromIntIsVlmax;
  logic VlBusyTable_io_vl_Wb_vlWriteBackInfo_vlFromVfIsZero;
  logic VlBusyTable_io_vl_Wb_vlWriteBackInfo_vlFromVfIsVlmax;
  wire  VlBusyTable_g_io_read_0_resp, VlBusyTable_i_io_read_0_resp;
  wire  VlBusyTable_g_io_read_1_resp, VlBusyTable_i_io_read_1_resp;
  wire  VlBusyTable_g_io_read_2_resp, VlBusyTable_i_io_read_2_resp;
  wire  VlBusyTable_g_io_read_3_resp, VlBusyTable_i_io_read_3_resp;
  wire  VlBusyTable_g_io_read_4_resp, VlBusyTable_i_io_read_4_resp;
  wire  VlBusyTable_g_io_read_5_resp, VlBusyTable_i_io_read_5_resp;
  wire  VlBusyTable_g_io_vl_read_vlReadInfo_0_is_nonzero, VlBusyTable_i_io_vl_read_vlReadInfo_0_is_nonzero;
  wire  VlBusyTable_g_io_vl_read_vlReadInfo_0_is_vlmax, VlBusyTable_i_io_vl_read_vlReadInfo_0_is_vlmax;
  wire  VlBusyTable_g_io_vl_read_vlReadInfo_1_is_nonzero, VlBusyTable_i_io_vl_read_vlReadInfo_1_is_nonzero;
  wire  VlBusyTable_g_io_vl_read_vlReadInfo_1_is_vlmax, VlBusyTable_i_io_vl_read_vlReadInfo_1_is_vlmax;
  wire  VlBusyTable_g_io_vl_read_vlReadInfo_2_is_nonzero, VlBusyTable_i_io_vl_read_vlReadInfo_2_is_nonzero;
  wire  VlBusyTable_g_io_vl_read_vlReadInfo_2_is_vlmax, VlBusyTable_i_io_vl_read_vlReadInfo_2_is_vlmax;
  wire  VlBusyTable_g_io_vl_read_vlReadInfo_3_is_nonzero, VlBusyTable_i_io_vl_read_vlReadInfo_3_is_nonzero;
  wire  VlBusyTable_g_io_vl_read_vlReadInfo_3_is_vlmax, VlBusyTable_i_io_vl_read_vlReadInfo_3_is_vlmax;
  wire  VlBusyTable_g_io_vl_read_vlReadInfo_4_is_nonzero, VlBusyTable_i_io_vl_read_vlReadInfo_4_is_nonzero;
  wire  VlBusyTable_g_io_vl_read_vlReadInfo_4_is_vlmax, VlBusyTable_i_io_vl_read_vlReadInfo_4_is_vlmax;
  wire  VlBusyTable_g_io_vl_read_vlReadInfo_5_is_nonzero, VlBusyTable_i_io_vl_read_vlReadInfo_5_is_nonzero;
  wire  VlBusyTable_g_io_vl_read_vlReadInfo_5_is_vlmax, VlBusyTable_i_io_vl_read_vlReadInfo_5_is_vlmax;
  VlBusyTable u_g_VlBusyTable (
    .clock(clk),
    .reset(rst),
    .io_allocPregs_0_valid(VlBusyTable_io_allocPregs_0_valid),
    .io_allocPregs_0_bits(VlBusyTable_io_allocPregs_0_bits),
    .io_allocPregs_1_valid(VlBusyTable_io_allocPregs_1_valid),
    .io_allocPregs_1_bits(VlBusyTable_io_allocPregs_1_bits),
    .io_allocPregs_2_valid(VlBusyTable_io_allocPregs_2_valid),
    .io_allocPregs_2_bits(VlBusyTable_io_allocPregs_2_bits),
    .io_allocPregs_3_valid(VlBusyTable_io_allocPregs_3_valid),
    .io_allocPregs_3_bits(VlBusyTable_io_allocPregs_3_bits),
    .io_allocPregs_4_valid(VlBusyTable_io_allocPregs_4_valid),
    .io_allocPregs_4_bits(VlBusyTable_io_allocPregs_4_bits),
    .io_allocPregs_5_valid(VlBusyTable_io_allocPregs_5_valid),
    .io_allocPregs_5_bits(VlBusyTable_io_allocPregs_5_bits),
    .io_wbPregs_0_valid(VlBusyTable_io_wbPregs_0_valid),
    .io_wbPregs_0_bits(VlBusyTable_io_wbPregs_0_bits),
    .io_wbPregs_1_valid(VlBusyTable_io_wbPregs_1_valid),
    .io_wbPregs_1_bits(VlBusyTable_io_wbPregs_1_bits),
    .io_wbPregs_2_valid(VlBusyTable_io_wbPregs_2_valid),
    .io_wbPregs_2_bits(VlBusyTable_io_wbPregs_2_bits),
    .io_wbPregs_3_valid(VlBusyTable_io_wbPregs_3_valid),
    .io_wbPregs_3_bits(VlBusyTable_io_wbPregs_3_bits),
    .io_read_0_req(VlBusyTable_io_read_0_req),
    .io_read_1_req(VlBusyTable_io_read_1_req),
    .io_read_2_req(VlBusyTable_io_read_2_req),
    .io_read_3_req(VlBusyTable_io_read_3_req),
    .io_read_4_req(VlBusyTable_io_read_4_req),
    .io_read_5_req(VlBusyTable_io_read_5_req),
    .io_vl_Wb_vlWriteBackInfo_vlFromIntIsZero(VlBusyTable_io_vl_Wb_vlWriteBackInfo_vlFromIntIsZero),
    .io_vl_Wb_vlWriteBackInfo_vlFromIntIsVlmax(VlBusyTable_io_vl_Wb_vlWriteBackInfo_vlFromIntIsVlmax),
    .io_vl_Wb_vlWriteBackInfo_vlFromVfIsZero(VlBusyTable_io_vl_Wb_vlWriteBackInfo_vlFromVfIsZero),
    .io_vl_Wb_vlWriteBackInfo_vlFromVfIsVlmax(VlBusyTable_io_vl_Wb_vlWriteBackInfo_vlFromVfIsVlmax),
    .io_read_0_resp(VlBusyTable_g_io_read_0_resp),
    .io_read_1_resp(VlBusyTable_g_io_read_1_resp),
    .io_read_2_resp(VlBusyTable_g_io_read_2_resp),
    .io_read_3_resp(VlBusyTable_g_io_read_3_resp),
    .io_read_4_resp(VlBusyTable_g_io_read_4_resp),
    .io_read_5_resp(VlBusyTable_g_io_read_5_resp),
    .io_vl_read_vlReadInfo_0_is_nonzero(VlBusyTable_g_io_vl_read_vlReadInfo_0_is_nonzero),
    .io_vl_read_vlReadInfo_0_is_vlmax(VlBusyTable_g_io_vl_read_vlReadInfo_0_is_vlmax),
    .io_vl_read_vlReadInfo_1_is_nonzero(VlBusyTable_g_io_vl_read_vlReadInfo_1_is_nonzero),
    .io_vl_read_vlReadInfo_1_is_vlmax(VlBusyTable_g_io_vl_read_vlReadInfo_1_is_vlmax),
    .io_vl_read_vlReadInfo_2_is_nonzero(VlBusyTable_g_io_vl_read_vlReadInfo_2_is_nonzero),
    .io_vl_read_vlReadInfo_2_is_vlmax(VlBusyTable_g_io_vl_read_vlReadInfo_2_is_vlmax),
    .io_vl_read_vlReadInfo_3_is_nonzero(VlBusyTable_g_io_vl_read_vlReadInfo_3_is_nonzero),
    .io_vl_read_vlReadInfo_3_is_vlmax(VlBusyTable_g_io_vl_read_vlReadInfo_3_is_vlmax),
    .io_vl_read_vlReadInfo_4_is_nonzero(VlBusyTable_g_io_vl_read_vlReadInfo_4_is_nonzero),
    .io_vl_read_vlReadInfo_4_is_vlmax(VlBusyTable_g_io_vl_read_vlReadInfo_4_is_vlmax),
    .io_vl_read_vlReadInfo_5_is_nonzero(VlBusyTable_g_io_vl_read_vlReadInfo_5_is_nonzero),
    .io_vl_read_vlReadInfo_5_is_vlmax(VlBusyTable_g_io_vl_read_vlReadInfo_5_is_vlmax)
  );
  VlBusyTable_xs u_i_VlBusyTable (
    .clock(clk),
    .reset(rst),
    .io_allocPregs_0_valid(VlBusyTable_io_allocPregs_0_valid),
    .io_allocPregs_0_bits(VlBusyTable_io_allocPregs_0_bits),
    .io_allocPregs_1_valid(VlBusyTable_io_allocPregs_1_valid),
    .io_allocPregs_1_bits(VlBusyTable_io_allocPregs_1_bits),
    .io_allocPregs_2_valid(VlBusyTable_io_allocPregs_2_valid),
    .io_allocPregs_2_bits(VlBusyTable_io_allocPregs_2_bits),
    .io_allocPregs_3_valid(VlBusyTable_io_allocPregs_3_valid),
    .io_allocPregs_3_bits(VlBusyTable_io_allocPregs_3_bits),
    .io_allocPregs_4_valid(VlBusyTable_io_allocPregs_4_valid),
    .io_allocPregs_4_bits(VlBusyTable_io_allocPregs_4_bits),
    .io_allocPregs_5_valid(VlBusyTable_io_allocPregs_5_valid),
    .io_allocPregs_5_bits(VlBusyTable_io_allocPregs_5_bits),
    .io_wbPregs_0_valid(VlBusyTable_io_wbPregs_0_valid),
    .io_wbPregs_0_bits(VlBusyTable_io_wbPregs_0_bits),
    .io_wbPregs_1_valid(VlBusyTable_io_wbPregs_1_valid),
    .io_wbPregs_1_bits(VlBusyTable_io_wbPregs_1_bits),
    .io_wbPregs_2_valid(VlBusyTable_io_wbPregs_2_valid),
    .io_wbPregs_2_bits(VlBusyTable_io_wbPregs_2_bits),
    .io_wbPregs_3_valid(VlBusyTable_io_wbPregs_3_valid),
    .io_wbPregs_3_bits(VlBusyTable_io_wbPregs_3_bits),
    .io_read_0_req(VlBusyTable_io_read_0_req),
    .io_read_1_req(VlBusyTable_io_read_1_req),
    .io_read_2_req(VlBusyTable_io_read_2_req),
    .io_read_3_req(VlBusyTable_io_read_3_req),
    .io_read_4_req(VlBusyTable_io_read_4_req),
    .io_read_5_req(VlBusyTable_io_read_5_req),
    .io_vl_Wb_vlWriteBackInfo_vlFromIntIsZero(VlBusyTable_io_vl_Wb_vlWriteBackInfo_vlFromIntIsZero),
    .io_vl_Wb_vlWriteBackInfo_vlFromIntIsVlmax(VlBusyTable_io_vl_Wb_vlWriteBackInfo_vlFromIntIsVlmax),
    .io_vl_Wb_vlWriteBackInfo_vlFromVfIsZero(VlBusyTable_io_vl_Wb_vlWriteBackInfo_vlFromVfIsZero),
    .io_vl_Wb_vlWriteBackInfo_vlFromVfIsVlmax(VlBusyTable_io_vl_Wb_vlWriteBackInfo_vlFromVfIsVlmax),
    .io_read_0_resp(VlBusyTable_i_io_read_0_resp),
    .io_read_1_resp(VlBusyTable_i_io_read_1_resp),
    .io_read_2_resp(VlBusyTable_i_io_read_2_resp),
    .io_read_3_resp(VlBusyTable_i_io_read_3_resp),
    .io_read_4_resp(VlBusyTable_i_io_read_4_resp),
    .io_read_5_resp(VlBusyTable_i_io_read_5_resp),
    .io_vl_read_vlReadInfo_0_is_nonzero(VlBusyTable_i_io_vl_read_vlReadInfo_0_is_nonzero),
    .io_vl_read_vlReadInfo_0_is_vlmax(VlBusyTable_i_io_vl_read_vlReadInfo_0_is_vlmax),
    .io_vl_read_vlReadInfo_1_is_nonzero(VlBusyTable_i_io_vl_read_vlReadInfo_1_is_nonzero),
    .io_vl_read_vlReadInfo_1_is_vlmax(VlBusyTable_i_io_vl_read_vlReadInfo_1_is_vlmax),
    .io_vl_read_vlReadInfo_2_is_nonzero(VlBusyTable_i_io_vl_read_vlReadInfo_2_is_nonzero),
    .io_vl_read_vlReadInfo_2_is_vlmax(VlBusyTable_i_io_vl_read_vlReadInfo_2_is_vlmax),
    .io_vl_read_vlReadInfo_3_is_nonzero(VlBusyTable_i_io_vl_read_vlReadInfo_3_is_nonzero),
    .io_vl_read_vlReadInfo_3_is_vlmax(VlBusyTable_i_io_vl_read_vlReadInfo_3_is_vlmax),
    .io_vl_read_vlReadInfo_4_is_nonzero(VlBusyTable_i_io_vl_read_vlReadInfo_4_is_nonzero),
    .io_vl_read_vlReadInfo_4_is_vlmax(VlBusyTable_i_io_vl_read_vlReadInfo_4_is_vlmax),
    .io_vl_read_vlReadInfo_5_is_nonzero(VlBusyTable_i_io_vl_read_vlReadInfo_5_is_nonzero),
    .io_vl_read_vlReadInfo_5_is_vlmax(VlBusyTable_i_io_vl_read_vlReadInfo_5_is_vlmax)
  );
  always @(negedge clk) begin
    if (rst) begin
      VlBusyTable_io_allocPregs_0_valid <= 1'b0;
      VlBusyTable_io_allocPregs_1_valid <= 1'b0;
      VlBusyTable_io_allocPregs_2_valid <= 1'b0;
      VlBusyTable_io_allocPregs_3_valid <= 1'b0;
      VlBusyTable_io_allocPregs_4_valid <= 1'b0;
      VlBusyTable_io_allocPregs_5_valid <= 1'b0;
      VlBusyTable_io_wbPregs_0_valid <= 1'b0;
      VlBusyTable_io_wbPregs_1_valid <= 1'b0;
      VlBusyTable_io_wbPregs_2_valid <= 1'b0;
      VlBusyTable_io_wbPregs_3_valid <= 1'b0;
    end else begin
      VlBusyTable_io_allocPregs_0_valid <= ($urandom_range(0, 9) < 5);
      VlBusyTable_io_allocPregs_0_bits <= rand_preg(32);
      VlBusyTable_io_allocPregs_1_valid <= ($urandom_range(0, 9) < 5);
      VlBusyTable_io_allocPregs_1_bits <= rand_preg(32);
      VlBusyTable_io_allocPregs_2_valid <= ($urandom_range(0, 9) < 5);
      VlBusyTable_io_allocPregs_2_bits <= rand_preg(32);
      VlBusyTable_io_allocPregs_3_valid <= ($urandom_range(0, 9) < 5);
      VlBusyTable_io_allocPregs_3_bits <= rand_preg(32);
      VlBusyTable_io_allocPregs_4_valid <= ($urandom_range(0, 9) < 5);
      VlBusyTable_io_allocPregs_4_bits <= rand_preg(32);
      VlBusyTable_io_allocPregs_5_valid <= ($urandom_range(0, 9) < 5);
      VlBusyTable_io_allocPregs_5_bits <= rand_preg(32);
      VlBusyTable_io_wbPregs_0_valid <= ($urandom_range(0, 9) < 5);
      VlBusyTable_io_wbPregs_0_bits <= rand_preg(32);
      VlBusyTable_io_wbPregs_1_valid <= ($urandom_range(0, 9) < 5);
      VlBusyTable_io_wbPregs_1_bits <= rand_preg(32);
      VlBusyTable_io_wbPregs_2_valid <= ($urandom_range(0, 9) < 5);
      VlBusyTable_io_wbPregs_2_bits <= rand_preg(32);
      VlBusyTable_io_wbPregs_3_valid <= ($urandom_range(0, 9) < 5);
      VlBusyTable_io_wbPregs_3_bits <= rand_preg(32);
      VlBusyTable_io_read_0_req <= rand_preg(32);
      VlBusyTable_io_read_1_req <= rand_preg(32);
      VlBusyTable_io_read_2_req <= rand_preg(32);
      VlBusyTable_io_read_3_req <= rand_preg(32);
      VlBusyTable_io_read_4_req <= rand_preg(32);
      VlBusyTable_io_read_5_req <= rand_preg(32);
      VlBusyTable_io_vl_Wb_vlWriteBackInfo_vlFromIntIsZero <= ($urandom_range(0, 9) < 5);
      VlBusyTable_io_vl_Wb_vlWriteBackInfo_vlFromIntIsVlmax <= ($urandom_range(0, 9) < 5);
      VlBusyTable_io_vl_Wb_vlWriteBackInfo_vlFromVfIsZero <= ($urandom_range(0, 9) < 5);
      VlBusyTable_io_vl_Wb_vlWriteBackInfo_vlFromVfIsVlmax <= ($urandom_range(0, 9) < 5);
    end
  end
  always @(negedge clk) if (!rst) begin
    #4;
    checks++;
    if (VlBusyTable_g_io_read_0_resp !== VlBusyTable_i_io_read_0_resp) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_read_0_resp mismatch: g=%h i=%h", $time, VlBusyTable_g_io_read_0_resp, VlBusyTable_i_io_read_0_resp); end
    checks++;
    if (VlBusyTable_g_io_read_1_resp !== VlBusyTable_i_io_read_1_resp) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_read_1_resp mismatch: g=%h i=%h", $time, VlBusyTable_g_io_read_1_resp, VlBusyTable_i_io_read_1_resp); end
    checks++;
    if (VlBusyTable_g_io_read_2_resp !== VlBusyTable_i_io_read_2_resp) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_read_2_resp mismatch: g=%h i=%h", $time, VlBusyTable_g_io_read_2_resp, VlBusyTable_i_io_read_2_resp); end
    checks++;
    if (VlBusyTable_g_io_read_3_resp !== VlBusyTable_i_io_read_3_resp) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_read_3_resp mismatch: g=%h i=%h", $time, VlBusyTable_g_io_read_3_resp, VlBusyTable_i_io_read_3_resp); end
    checks++;
    if (VlBusyTable_g_io_read_4_resp !== VlBusyTable_i_io_read_4_resp) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_read_4_resp mismatch: g=%h i=%h", $time, VlBusyTable_g_io_read_4_resp, VlBusyTable_i_io_read_4_resp); end
    checks++;
    if (VlBusyTable_g_io_read_5_resp !== VlBusyTable_i_io_read_5_resp) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_read_5_resp mismatch: g=%h i=%h", $time, VlBusyTable_g_io_read_5_resp, VlBusyTable_i_io_read_5_resp); end
    checks++;
    if (VlBusyTable_g_io_vl_read_vlReadInfo_0_is_nonzero !== VlBusyTable_i_io_vl_read_vlReadInfo_0_is_nonzero) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_vl_read_vlReadInfo_0_is_nonzero mismatch: g=%h i=%h", $time, VlBusyTable_g_io_vl_read_vlReadInfo_0_is_nonzero, VlBusyTable_i_io_vl_read_vlReadInfo_0_is_nonzero); end
    checks++;
    if (VlBusyTable_g_io_vl_read_vlReadInfo_0_is_vlmax !== VlBusyTable_i_io_vl_read_vlReadInfo_0_is_vlmax) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_vl_read_vlReadInfo_0_is_vlmax mismatch: g=%h i=%h", $time, VlBusyTable_g_io_vl_read_vlReadInfo_0_is_vlmax, VlBusyTable_i_io_vl_read_vlReadInfo_0_is_vlmax); end
    checks++;
    if (VlBusyTable_g_io_vl_read_vlReadInfo_1_is_nonzero !== VlBusyTable_i_io_vl_read_vlReadInfo_1_is_nonzero) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_vl_read_vlReadInfo_1_is_nonzero mismatch: g=%h i=%h", $time, VlBusyTable_g_io_vl_read_vlReadInfo_1_is_nonzero, VlBusyTable_i_io_vl_read_vlReadInfo_1_is_nonzero); end
    checks++;
    if (VlBusyTable_g_io_vl_read_vlReadInfo_1_is_vlmax !== VlBusyTable_i_io_vl_read_vlReadInfo_1_is_vlmax) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_vl_read_vlReadInfo_1_is_vlmax mismatch: g=%h i=%h", $time, VlBusyTable_g_io_vl_read_vlReadInfo_1_is_vlmax, VlBusyTable_i_io_vl_read_vlReadInfo_1_is_vlmax); end
    checks++;
    if (VlBusyTable_g_io_vl_read_vlReadInfo_2_is_nonzero !== VlBusyTable_i_io_vl_read_vlReadInfo_2_is_nonzero) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_vl_read_vlReadInfo_2_is_nonzero mismatch: g=%h i=%h", $time, VlBusyTable_g_io_vl_read_vlReadInfo_2_is_nonzero, VlBusyTable_i_io_vl_read_vlReadInfo_2_is_nonzero); end
    checks++;
    if (VlBusyTable_g_io_vl_read_vlReadInfo_2_is_vlmax !== VlBusyTable_i_io_vl_read_vlReadInfo_2_is_vlmax) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_vl_read_vlReadInfo_2_is_vlmax mismatch: g=%h i=%h", $time, VlBusyTable_g_io_vl_read_vlReadInfo_2_is_vlmax, VlBusyTable_i_io_vl_read_vlReadInfo_2_is_vlmax); end
    checks++;
    if (VlBusyTable_g_io_vl_read_vlReadInfo_3_is_nonzero !== VlBusyTable_i_io_vl_read_vlReadInfo_3_is_nonzero) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_vl_read_vlReadInfo_3_is_nonzero mismatch: g=%h i=%h", $time, VlBusyTable_g_io_vl_read_vlReadInfo_3_is_nonzero, VlBusyTable_i_io_vl_read_vlReadInfo_3_is_nonzero); end
    checks++;
    if (VlBusyTable_g_io_vl_read_vlReadInfo_3_is_vlmax !== VlBusyTable_i_io_vl_read_vlReadInfo_3_is_vlmax) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_vl_read_vlReadInfo_3_is_vlmax mismatch: g=%h i=%h", $time, VlBusyTable_g_io_vl_read_vlReadInfo_3_is_vlmax, VlBusyTable_i_io_vl_read_vlReadInfo_3_is_vlmax); end
    checks++;
    if (VlBusyTable_g_io_vl_read_vlReadInfo_4_is_nonzero !== VlBusyTable_i_io_vl_read_vlReadInfo_4_is_nonzero) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_vl_read_vlReadInfo_4_is_nonzero mismatch: g=%h i=%h", $time, VlBusyTable_g_io_vl_read_vlReadInfo_4_is_nonzero, VlBusyTable_i_io_vl_read_vlReadInfo_4_is_nonzero); end
    checks++;
    if (VlBusyTable_g_io_vl_read_vlReadInfo_4_is_vlmax !== VlBusyTable_i_io_vl_read_vlReadInfo_4_is_vlmax) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_vl_read_vlReadInfo_4_is_vlmax mismatch: g=%h i=%h", $time, VlBusyTable_g_io_vl_read_vlReadInfo_4_is_vlmax, VlBusyTable_i_io_vl_read_vlReadInfo_4_is_vlmax); end
    checks++;
    if (VlBusyTable_g_io_vl_read_vlReadInfo_5_is_nonzero !== VlBusyTable_i_io_vl_read_vlReadInfo_5_is_nonzero) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_vl_read_vlReadInfo_5_is_nonzero mismatch: g=%h i=%h", $time, VlBusyTable_g_io_vl_read_vlReadInfo_5_is_nonzero, VlBusyTable_i_io_vl_read_vlReadInfo_5_is_nonzero); end
    checks++;
    if (VlBusyTable_g_io_vl_read_vlReadInfo_5_is_vlmax !== VlBusyTable_i_io_vl_read_vlReadInfo_5_is_vlmax) begin errors++;
      if (errors < 40) $display("[%0t] VlBusyTable.io_vl_read_vlReadInfo_5_is_vlmax mismatch: g=%h i=%h", $time, VlBusyTable_g_io_vl_read_vlReadInfo_5_is_vlmax, VlBusyTable_i_io_vl_read_vlReadInfo_5_is_vlmax); end
  end
  // ---- 覆盖事件统计（只读 golden 侧，不看重写侧，免得自证）----
  always @(negedge clk) if (!rst) begin
    #4;
    for (int a = 0; a < 6; a++) begin
      logic v; logic [7:0] b;
      case (a)
        0: begin v = VlBusyTable_io_allocPregs_0_valid; b = VlBusyTable_io_allocPregs_0_bits; end
        1: begin v = VlBusyTable_io_allocPregs_1_valid; b = VlBusyTable_io_allocPregs_1_bits; end
        2: begin v = VlBusyTable_io_allocPregs_2_valid; b = VlBusyTable_io_allocPregs_2_bits; end
        3: begin v = VlBusyTable_io_allocPregs_3_valid; b = VlBusyTable_io_allocPregs_3_bits; end
        4: begin v = VlBusyTable_io_allocPregs_4_valid; b = VlBusyTable_io_allocPregs_4_bits; end
        5: begin v = VlBusyTable_io_allocPregs_5_valid; b = VlBusyTable_io_allocPregs_5_bits; end
        default: begin v = 1'b0; b = 8'h0; end
      endcase
      if (v && b < 32) begin
        for (int w = 0; w < 4; w++) begin
          logic wv; logic [7:0] wb;
          case (w)
            0: begin wv = VlBusyTable_io_wbPregs_0_valid; wb = VlBusyTable_io_wbPregs_0_bits; end
            1: begin wv = VlBusyTable_io_wbPregs_1_valid; wb = VlBusyTable_io_wbPregs_1_bits; end
            2: begin wv = VlBusyTable_io_wbPregs_2_valid; wb = VlBusyTable_io_wbPregs_2_bits; end
            3: begin wv = VlBusyTable_io_wbPregs_3_valid; wb = VlBusyTable_io_wbPregs_3_bits; end
            default: begin wv = 1'b0; wb = 8'h0; end
          endcase
          if (wv && wb == b) cov_alloc_wb_clash++;
        end
      end
    end
    for (int r = 0; r < 6; r++) begin
      logic [7:0] q;
      case (r)
        0: q = VlBusyTable_io_read_0_req;
        1: q = VlBusyTable_io_read_1_req;
        2: q = VlBusyTable_io_read_2_req;
        3: q = VlBusyTable_io_read_3_req;
        4: q = VlBusyTable_io_read_4_req;
        5: q = VlBusyTable_io_read_5_req;
        default: q = 8'h0;
      endcase
      if (q >= 32) cov_read_oob++;
      for (int a = 0; a < 6; a++) begin
        logic v; logic [7:0] b;
        case (a)
          0: begin v = VlBusyTable_io_allocPregs_0_valid; b = VlBusyTable_io_allocPregs_0_bits; end
          1: begin v = VlBusyTable_io_allocPregs_1_valid; b = VlBusyTable_io_allocPregs_1_bits; end
          2: begin v = VlBusyTable_io_allocPregs_2_valid; b = VlBusyTable_io_allocPregs_2_bits; end
          3: begin v = VlBusyTable_io_allocPregs_3_valid; b = VlBusyTable_io_allocPregs_3_bits; end
          4: begin v = VlBusyTable_io_allocPregs_4_valid; b = VlBusyTable_io_allocPregs_4_bits; end
          5: begin v = VlBusyTable_io_allocPregs_5_valid; b = VlBusyTable_io_allocPregs_5_bits; end
          default: begin v = 1'b0; b = 8'h0; end
        endcase
        if (v && b == q) cov_alloc_bypass++;
      end
    end
    if (VlBusyTable_io_wbPregs_0_valid && VlBusyTable_io_wbPregs_0_bits < 32) cov_vl_int_wb++;
    if (VlBusyTable_io_wbPregs_1_valid && VlBusyTable_io_wbPregs_1_bits < 32) cov_vl_vf_wb++;
    if ((VlBusyTable_io_wbPregs_2_valid && VlBusyTable_io_wbPregs_2_bits < 32) ||
        (VlBusyTable_io_wbPregs_3_valid && VlBusyTable_io_wbPregs_3_bits < 32)) cov_vl_other_wb++;
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1'b1;
    repeat (4) @(posedge clk);
    @(negedge clk) rst = 1'b0;
    // 中途再来一次异步复位，验证复位域（全家族都是 posedge reset 异步复位）
    repeat (NCYCLES / 2) @(posedge clk);
    @(negedge clk) rst = 1'b1;
    repeat (3) @(posedge clk);
    @(negedge clk) rst = 1'b0;
    repeat (NCYCLES / 2) @(posedge clk);

    $display("--- COVERAGE (每项必须 > 0，否则该机制没被激励到) ---");
    $display("  alloc&wb 同项撞车      : %0d", cov_alloc_wb_clash);
    $display("  wake&alloc 同项撞车    : %0d", cov_wake_wb_clash);
    $display("  og0Cancel 打掉唤醒     : %0d", cov_og0_kill);
    $display("  ldCancel 重新置忙      : %0d", cov_ldcancel_set);
    $display("  读口越界               : %0d", cov_read_oob);
    $display("  越界读 dep 且第0项非零 : %0d", cov_oob_dep_nz);
    $display("  分配命中 0 号项        : %0d", cov_entry0_alloc);
    $display("  读口撞本拍分配(旁路)   : %0d", cov_alloc_bypass);
    $display("  vl int 写回口          : %0d", cov_vl_int_wb);
    $display("  vl vf  写回口          : %0d", cov_vl_vf_wb);
    $display("  vl 其它写回口          : %0d", cov_vl_other_wb);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 &&
        cov_alloc_wb_clash > 0 && cov_wake_wb_clash > 0 && cov_og0_kill > 0 &&
        cov_ldcancel_set > 0 && cov_read_oob > 0 && cov_oob_dep_nz > 0 &&
        cov_entry0_alloc > 0 && cov_alloc_bypass > 0 &&
        cov_vl_int_wb > 0 && cov_vl_vf_wb > 0 && cov_vl_other_wb > 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED (errors=%0d 或覆盖项为 0)", errors);
    $finish;
  end

endmodule
