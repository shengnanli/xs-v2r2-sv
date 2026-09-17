// tb.sv —— PtwCache 回填写数据锥体的**定向差分对照**（verif/study，不是验收 UT）。
//
// 目的很窄：§6.1/§6.2 刚把 golden 里约 1200 行展平的 canRefill/isPf/isGpf/onlyPf/
// napot 判定重写成了 10 个函数。这些函数写对没写对，光看是看不出来的，UT 也还没有。
// 这里双例化 golden PtwCache 与派生的 PtwCache_xs，只驱动 refill 相关输入，
// 用层次引用比两侧 **l1/l0 SRAM 写端口**上的每一根线（59 + 371 根）。
//
// ★它不能替代验收 UT★：只覆盖组合回填锥体，不含流水/命中/sfence/响应。
//
// 【判别力：注入过的 mutant（都不进库，结果记在这儿）】
//   A  pte_is_pf 的 napot 分支去掉 `| (level != 0)`
//        -> errors=0，**没抓到**。查清了原因：level>0 时 ppn[3:0]==8 蕴含
//           ppn[8:0]!=0，紧接着的 unaligned(level) 对同一批输入也给 1，
//           两者**值恒等**。所以这不是本对照的漏洞，是这个 mutant 本身无效。
//           （RTL 里那一项照抄保留，理由写在 §6.1 该行注释。）
//   B  pbmte 改用 dup_1（本工程反复吃亏的「dup 归属写错」形态）
//        -> errors=6164 / 20000 拍，抓到。
//   C  pte_only_pf 去掉 `& ~pte_is_af(p)`
//        -> errors=28536 / 20000 拍，抓到。
//   另有一条**常态自证**：waymask 仍是 §8 的占位，untraced_diff 必须 > 0；
//   若它掉到 0，说明本对照退化成了"什么都不比"，判 FAIL。
//
// 【实测（commit 见 git log，文件 sha256 见 rtl/mmu/PtwCache.sv）】
//   make run NCYCLES=200000 SEED=1|7|42
//   -> 每轮 checks=86,000,000  errors=0  untraced_diff=400,000  STUDY PASS
`timescale 1ns/1ps
module tb;
  int errors = 0;          // 已追清信号的失配 —— 一个都不许有
  int checks = 0;
  int untraced_diff = 0;   // 仍是占位（§8 钉 0）的信号的失配 —— ★必须 > 0★
  int ncycles;

  logic            io_csr_mPBMTE;
  logic            io_csr_hPBMTE;
  logic            g_io_req_ready, i_io_req_ready;
  logic            io_req_valid;
  logic [37:0]     io_req_bits_req_info_vpn;
  logic [1:0]      io_req_bits_req_info_s2xlate;
  logic [1:0]      io_req_bits_req_info_source;
  logic            io_req_bits_isFirst;
  logic            io_req_bits_isHptwReq;
  logic [2:0]      io_req_bits_hptwId;
  logic            io_resp_ready;
  logic            g_io_resp_valid, i_io_resp_valid;
  logic [37:0]     g_io_resp_bits_req_info_vpn, i_io_resp_bits_req_info_vpn;
  logic [1:0]      g_io_resp_bits_req_info_s2xlate, i_io_resp_bits_req_info_s2xlate;
  logic [1:0]      g_io_resp_bits_req_info_source, i_io_resp_bits_req_info_source;
  logic            g_io_resp_bits_isFirst, i_io_resp_bits_isFirst;
  logic            g_io_resp_bits_hit, i_io_resp_bits_hit;
  logic            g_io_resp_bits_prefetch, i_io_resp_bits_prefetch;
  logic            g_io_resp_bits_bypassed, i_io_resp_bits_bypassed;
  logic            g_io_resp_bits_toFsm_l3Hit, i_io_resp_bits_toFsm_l3Hit;
  logic            g_io_resp_bits_toFsm_l2Hit, i_io_resp_bits_toFsm_l2Hit;
  logic            g_io_resp_bits_toFsm_l1Hit, i_io_resp_bits_toFsm_l1Hit;
  logic [37:0]     g_io_resp_bits_toFsm_ppn, i_io_resp_bits_toFsm_ppn;
  logic            g_io_resp_bits_toFsm_stage1Hit, i_io_resp_bits_toFsm_stage1Hit;
  logic            g_io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check, i_io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check;
  logic            g_io_resp_bits_toFsm_bitmapCheck_toLLPTW, i_io_resp_bits_toFsm_bitmapCheck_toLLPTW;
  logic [3:0]      g_io_resp_bits_toFsm_bitmapCheck_hitway, i_io_resp_bits_toFsm_bitmapCheck_hitway;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_pte, i_io_resp_bits_toFsm_bitmapCheck_pte;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_ptes_0, i_io_resp_bits_toFsm_bitmapCheck_ptes_0;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_ptes_1, i_io_resp_bits_toFsm_bitmapCheck_ptes_1;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_ptes_2, i_io_resp_bits_toFsm_bitmapCheck_ptes_2;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_ptes_3, i_io_resp_bits_toFsm_bitmapCheck_ptes_3;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_ptes_4, i_io_resp_bits_toFsm_bitmapCheck_ptes_4;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_ptes_5, i_io_resp_bits_toFsm_bitmapCheck_ptes_5;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_ptes_6, i_io_resp_bits_toFsm_bitmapCheck_ptes_6;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_ptes_7, i_io_resp_bits_toFsm_bitmapCheck_ptes_7;
  logic            g_io_resp_bits_toFsm_bitmapCheck_cfs_0, i_io_resp_bits_toFsm_bitmapCheck_cfs_0;
  logic            g_io_resp_bits_toFsm_bitmapCheck_cfs_1, i_io_resp_bits_toFsm_bitmapCheck_cfs_1;
  logic            g_io_resp_bits_toFsm_bitmapCheck_cfs_2, i_io_resp_bits_toFsm_bitmapCheck_cfs_2;
  logic            g_io_resp_bits_toFsm_bitmapCheck_cfs_3, i_io_resp_bits_toFsm_bitmapCheck_cfs_3;
  logic            g_io_resp_bits_toFsm_bitmapCheck_cfs_4, i_io_resp_bits_toFsm_bitmapCheck_cfs_4;
  logic            g_io_resp_bits_toFsm_bitmapCheck_cfs_5, i_io_resp_bits_toFsm_bitmapCheck_cfs_5;
  logic            g_io_resp_bits_toFsm_bitmapCheck_cfs_6, i_io_resp_bits_toFsm_bitmapCheck_cfs_6;
  logic            g_io_resp_bits_toFsm_bitmapCheck_cfs_7, i_io_resp_bits_toFsm_bitmapCheck_cfs_7;
  logic [1:0]      g_io_resp_bits_toFsm_bitmapCheck_SPlevel, i_io_resp_bits_toFsm_bitmapCheck_SPlevel;
  logic [34:0]     g_io_resp_bits_stage1_entry_0_tag, i_io_resp_bits_stage1_entry_0_tag;
  logic [15:0]     g_io_resp_bits_stage1_entry_0_asid, i_io_resp_bits_stage1_entry_0_asid;
  logic [13:0]     g_io_resp_bits_stage1_entry_0_vmid, i_io_resp_bits_stage1_entry_0_vmid;
  logic            g_io_resp_bits_stage1_entry_0_n, i_io_resp_bits_stage1_entry_0_n;
  logic [1:0]      g_io_resp_bits_stage1_entry_0_pbmt, i_io_resp_bits_stage1_entry_0_pbmt;
  logic            g_io_resp_bits_stage1_entry_0_perm_d, i_io_resp_bits_stage1_entry_0_perm_d;
  logic            g_io_resp_bits_stage1_entry_0_perm_a, i_io_resp_bits_stage1_entry_0_perm_a;
  logic            g_io_resp_bits_stage1_entry_0_perm_g, i_io_resp_bits_stage1_entry_0_perm_g;
  logic            g_io_resp_bits_stage1_entry_0_perm_u, i_io_resp_bits_stage1_entry_0_perm_u;
  logic            g_io_resp_bits_stage1_entry_0_perm_x, i_io_resp_bits_stage1_entry_0_perm_x;
  logic            g_io_resp_bits_stage1_entry_0_perm_w, i_io_resp_bits_stage1_entry_0_perm_w;
  logic            g_io_resp_bits_stage1_entry_0_perm_r, i_io_resp_bits_stage1_entry_0_perm_r;
  logic [1:0]      g_io_resp_bits_stage1_entry_0_level, i_io_resp_bits_stage1_entry_0_level;
  logic            g_io_resp_bits_stage1_entry_0_v, i_io_resp_bits_stage1_entry_0_v;
  logic [40:0]     g_io_resp_bits_stage1_entry_0_ppn, i_io_resp_bits_stage1_entry_0_ppn;
  logic [2:0]      g_io_resp_bits_stage1_entry_0_ppn_low, i_io_resp_bits_stage1_entry_0_ppn_low;
  logic            g_io_resp_bits_stage1_entry_0_pf, i_io_resp_bits_stage1_entry_0_pf;
  logic            g_io_resp_bits_stage1_entry_0_cf, i_io_resp_bits_stage1_entry_0_cf;
  logic [34:0]     g_io_resp_bits_stage1_entry_1_tag, i_io_resp_bits_stage1_entry_1_tag;
  logic [15:0]     g_io_resp_bits_stage1_entry_1_asid, i_io_resp_bits_stage1_entry_1_asid;
  logic [13:0]     g_io_resp_bits_stage1_entry_1_vmid, i_io_resp_bits_stage1_entry_1_vmid;
  logic            g_io_resp_bits_stage1_entry_1_n, i_io_resp_bits_stage1_entry_1_n;
  logic [1:0]      g_io_resp_bits_stage1_entry_1_pbmt, i_io_resp_bits_stage1_entry_1_pbmt;
  logic            g_io_resp_bits_stage1_entry_1_perm_d, i_io_resp_bits_stage1_entry_1_perm_d;
  logic            g_io_resp_bits_stage1_entry_1_perm_a, i_io_resp_bits_stage1_entry_1_perm_a;
  logic            g_io_resp_bits_stage1_entry_1_perm_g, i_io_resp_bits_stage1_entry_1_perm_g;
  logic            g_io_resp_bits_stage1_entry_1_perm_u, i_io_resp_bits_stage1_entry_1_perm_u;
  logic            g_io_resp_bits_stage1_entry_1_perm_x, i_io_resp_bits_stage1_entry_1_perm_x;
  logic            g_io_resp_bits_stage1_entry_1_perm_w, i_io_resp_bits_stage1_entry_1_perm_w;
  logic            g_io_resp_bits_stage1_entry_1_perm_r, i_io_resp_bits_stage1_entry_1_perm_r;
  logic [1:0]      g_io_resp_bits_stage1_entry_1_level, i_io_resp_bits_stage1_entry_1_level;
  logic            g_io_resp_bits_stage1_entry_1_v, i_io_resp_bits_stage1_entry_1_v;
  logic [40:0]     g_io_resp_bits_stage1_entry_1_ppn, i_io_resp_bits_stage1_entry_1_ppn;
  logic [2:0]      g_io_resp_bits_stage1_entry_1_ppn_low, i_io_resp_bits_stage1_entry_1_ppn_low;
  logic            g_io_resp_bits_stage1_entry_1_pf, i_io_resp_bits_stage1_entry_1_pf;
  logic            g_io_resp_bits_stage1_entry_1_cf, i_io_resp_bits_stage1_entry_1_cf;
  logic [34:0]     g_io_resp_bits_stage1_entry_2_tag, i_io_resp_bits_stage1_entry_2_tag;
  logic [15:0]     g_io_resp_bits_stage1_entry_2_asid, i_io_resp_bits_stage1_entry_2_asid;
  logic [13:0]     g_io_resp_bits_stage1_entry_2_vmid, i_io_resp_bits_stage1_entry_2_vmid;
  logic            g_io_resp_bits_stage1_entry_2_n, i_io_resp_bits_stage1_entry_2_n;
  logic [1:0]      g_io_resp_bits_stage1_entry_2_pbmt, i_io_resp_bits_stage1_entry_2_pbmt;
  logic            g_io_resp_bits_stage1_entry_2_perm_d, i_io_resp_bits_stage1_entry_2_perm_d;
  logic            g_io_resp_bits_stage1_entry_2_perm_a, i_io_resp_bits_stage1_entry_2_perm_a;
  logic            g_io_resp_bits_stage1_entry_2_perm_g, i_io_resp_bits_stage1_entry_2_perm_g;
  logic            g_io_resp_bits_stage1_entry_2_perm_u, i_io_resp_bits_stage1_entry_2_perm_u;
  logic            g_io_resp_bits_stage1_entry_2_perm_x, i_io_resp_bits_stage1_entry_2_perm_x;
  logic            g_io_resp_bits_stage1_entry_2_perm_w, i_io_resp_bits_stage1_entry_2_perm_w;
  logic            g_io_resp_bits_stage1_entry_2_perm_r, i_io_resp_bits_stage1_entry_2_perm_r;
  logic [1:0]      g_io_resp_bits_stage1_entry_2_level, i_io_resp_bits_stage1_entry_2_level;
  logic            g_io_resp_bits_stage1_entry_2_v, i_io_resp_bits_stage1_entry_2_v;
  logic [40:0]     g_io_resp_bits_stage1_entry_2_ppn, i_io_resp_bits_stage1_entry_2_ppn;
  logic [2:0]      g_io_resp_bits_stage1_entry_2_ppn_low, i_io_resp_bits_stage1_entry_2_ppn_low;
  logic            g_io_resp_bits_stage1_entry_2_pf, i_io_resp_bits_stage1_entry_2_pf;
  logic            g_io_resp_bits_stage1_entry_2_cf, i_io_resp_bits_stage1_entry_2_cf;
  logic [34:0]     g_io_resp_bits_stage1_entry_3_tag, i_io_resp_bits_stage1_entry_3_tag;
  logic [15:0]     g_io_resp_bits_stage1_entry_3_asid, i_io_resp_bits_stage1_entry_3_asid;
  logic [13:0]     g_io_resp_bits_stage1_entry_3_vmid, i_io_resp_bits_stage1_entry_3_vmid;
  logic            g_io_resp_bits_stage1_entry_3_n, i_io_resp_bits_stage1_entry_3_n;
  logic [1:0]      g_io_resp_bits_stage1_entry_3_pbmt, i_io_resp_bits_stage1_entry_3_pbmt;
  logic            g_io_resp_bits_stage1_entry_3_perm_d, i_io_resp_bits_stage1_entry_3_perm_d;
  logic            g_io_resp_bits_stage1_entry_3_perm_a, i_io_resp_bits_stage1_entry_3_perm_a;
  logic            g_io_resp_bits_stage1_entry_3_perm_g, i_io_resp_bits_stage1_entry_3_perm_g;
  logic            g_io_resp_bits_stage1_entry_3_perm_u, i_io_resp_bits_stage1_entry_3_perm_u;
  logic            g_io_resp_bits_stage1_entry_3_perm_x, i_io_resp_bits_stage1_entry_3_perm_x;
  logic            g_io_resp_bits_stage1_entry_3_perm_w, i_io_resp_bits_stage1_entry_3_perm_w;
  logic            g_io_resp_bits_stage1_entry_3_perm_r, i_io_resp_bits_stage1_entry_3_perm_r;
  logic [1:0]      g_io_resp_bits_stage1_entry_3_level, i_io_resp_bits_stage1_entry_3_level;
  logic            g_io_resp_bits_stage1_entry_3_v, i_io_resp_bits_stage1_entry_3_v;
  logic [40:0]     g_io_resp_bits_stage1_entry_3_ppn, i_io_resp_bits_stage1_entry_3_ppn;
  logic [2:0]      g_io_resp_bits_stage1_entry_3_ppn_low, i_io_resp_bits_stage1_entry_3_ppn_low;
  logic            g_io_resp_bits_stage1_entry_3_pf, i_io_resp_bits_stage1_entry_3_pf;
  logic            g_io_resp_bits_stage1_entry_3_cf, i_io_resp_bits_stage1_entry_3_cf;
  logic [34:0]     g_io_resp_bits_stage1_entry_4_tag, i_io_resp_bits_stage1_entry_4_tag;
  logic [15:0]     g_io_resp_bits_stage1_entry_4_asid, i_io_resp_bits_stage1_entry_4_asid;
  logic [13:0]     g_io_resp_bits_stage1_entry_4_vmid, i_io_resp_bits_stage1_entry_4_vmid;
  logic            g_io_resp_bits_stage1_entry_4_n, i_io_resp_bits_stage1_entry_4_n;
  logic [1:0]      g_io_resp_bits_stage1_entry_4_pbmt, i_io_resp_bits_stage1_entry_4_pbmt;
  logic            g_io_resp_bits_stage1_entry_4_perm_d, i_io_resp_bits_stage1_entry_4_perm_d;
  logic            g_io_resp_bits_stage1_entry_4_perm_a, i_io_resp_bits_stage1_entry_4_perm_a;
  logic            g_io_resp_bits_stage1_entry_4_perm_g, i_io_resp_bits_stage1_entry_4_perm_g;
  logic            g_io_resp_bits_stage1_entry_4_perm_u, i_io_resp_bits_stage1_entry_4_perm_u;
  logic            g_io_resp_bits_stage1_entry_4_perm_x, i_io_resp_bits_stage1_entry_4_perm_x;
  logic            g_io_resp_bits_stage1_entry_4_perm_w, i_io_resp_bits_stage1_entry_4_perm_w;
  logic            g_io_resp_bits_stage1_entry_4_perm_r, i_io_resp_bits_stage1_entry_4_perm_r;
  logic [1:0]      g_io_resp_bits_stage1_entry_4_level, i_io_resp_bits_stage1_entry_4_level;
  logic            g_io_resp_bits_stage1_entry_4_v, i_io_resp_bits_stage1_entry_4_v;
  logic [40:0]     g_io_resp_bits_stage1_entry_4_ppn, i_io_resp_bits_stage1_entry_4_ppn;
  logic [2:0]      g_io_resp_bits_stage1_entry_4_ppn_low, i_io_resp_bits_stage1_entry_4_ppn_low;
  logic            g_io_resp_bits_stage1_entry_4_pf, i_io_resp_bits_stage1_entry_4_pf;
  logic            g_io_resp_bits_stage1_entry_4_cf, i_io_resp_bits_stage1_entry_4_cf;
  logic [34:0]     g_io_resp_bits_stage1_entry_5_tag, i_io_resp_bits_stage1_entry_5_tag;
  logic [15:0]     g_io_resp_bits_stage1_entry_5_asid, i_io_resp_bits_stage1_entry_5_asid;
  logic [13:0]     g_io_resp_bits_stage1_entry_5_vmid, i_io_resp_bits_stage1_entry_5_vmid;
  logic            g_io_resp_bits_stage1_entry_5_n, i_io_resp_bits_stage1_entry_5_n;
  logic [1:0]      g_io_resp_bits_stage1_entry_5_pbmt, i_io_resp_bits_stage1_entry_5_pbmt;
  logic            g_io_resp_bits_stage1_entry_5_perm_d, i_io_resp_bits_stage1_entry_5_perm_d;
  logic            g_io_resp_bits_stage1_entry_5_perm_a, i_io_resp_bits_stage1_entry_5_perm_a;
  logic            g_io_resp_bits_stage1_entry_5_perm_g, i_io_resp_bits_stage1_entry_5_perm_g;
  logic            g_io_resp_bits_stage1_entry_5_perm_u, i_io_resp_bits_stage1_entry_5_perm_u;
  logic            g_io_resp_bits_stage1_entry_5_perm_x, i_io_resp_bits_stage1_entry_5_perm_x;
  logic            g_io_resp_bits_stage1_entry_5_perm_w, i_io_resp_bits_stage1_entry_5_perm_w;
  logic            g_io_resp_bits_stage1_entry_5_perm_r, i_io_resp_bits_stage1_entry_5_perm_r;
  logic [1:0]      g_io_resp_bits_stage1_entry_5_level, i_io_resp_bits_stage1_entry_5_level;
  logic            g_io_resp_bits_stage1_entry_5_v, i_io_resp_bits_stage1_entry_5_v;
  logic [40:0]     g_io_resp_bits_stage1_entry_5_ppn, i_io_resp_bits_stage1_entry_5_ppn;
  logic [2:0]      g_io_resp_bits_stage1_entry_5_ppn_low, i_io_resp_bits_stage1_entry_5_ppn_low;
  logic            g_io_resp_bits_stage1_entry_5_pf, i_io_resp_bits_stage1_entry_5_pf;
  logic            g_io_resp_bits_stage1_entry_5_cf, i_io_resp_bits_stage1_entry_5_cf;
  logic [34:0]     g_io_resp_bits_stage1_entry_6_tag, i_io_resp_bits_stage1_entry_6_tag;
  logic [15:0]     g_io_resp_bits_stage1_entry_6_asid, i_io_resp_bits_stage1_entry_6_asid;
  logic [13:0]     g_io_resp_bits_stage1_entry_6_vmid, i_io_resp_bits_stage1_entry_6_vmid;
  logic            g_io_resp_bits_stage1_entry_6_n, i_io_resp_bits_stage1_entry_6_n;
  logic [1:0]      g_io_resp_bits_stage1_entry_6_pbmt, i_io_resp_bits_stage1_entry_6_pbmt;
  logic            g_io_resp_bits_stage1_entry_6_perm_d, i_io_resp_bits_stage1_entry_6_perm_d;
  logic            g_io_resp_bits_stage1_entry_6_perm_a, i_io_resp_bits_stage1_entry_6_perm_a;
  logic            g_io_resp_bits_stage1_entry_6_perm_g, i_io_resp_bits_stage1_entry_6_perm_g;
  logic            g_io_resp_bits_stage1_entry_6_perm_u, i_io_resp_bits_stage1_entry_6_perm_u;
  logic            g_io_resp_bits_stage1_entry_6_perm_x, i_io_resp_bits_stage1_entry_6_perm_x;
  logic            g_io_resp_bits_stage1_entry_6_perm_w, i_io_resp_bits_stage1_entry_6_perm_w;
  logic            g_io_resp_bits_stage1_entry_6_perm_r, i_io_resp_bits_stage1_entry_6_perm_r;
  logic [1:0]      g_io_resp_bits_stage1_entry_6_level, i_io_resp_bits_stage1_entry_6_level;
  logic            g_io_resp_bits_stage1_entry_6_v, i_io_resp_bits_stage1_entry_6_v;
  logic [40:0]     g_io_resp_bits_stage1_entry_6_ppn, i_io_resp_bits_stage1_entry_6_ppn;
  logic [2:0]      g_io_resp_bits_stage1_entry_6_ppn_low, i_io_resp_bits_stage1_entry_6_ppn_low;
  logic            g_io_resp_bits_stage1_entry_6_pf, i_io_resp_bits_stage1_entry_6_pf;
  logic            g_io_resp_bits_stage1_entry_6_cf, i_io_resp_bits_stage1_entry_6_cf;
  logic [34:0]     g_io_resp_bits_stage1_entry_7_tag, i_io_resp_bits_stage1_entry_7_tag;
  logic [15:0]     g_io_resp_bits_stage1_entry_7_asid, i_io_resp_bits_stage1_entry_7_asid;
  logic [13:0]     g_io_resp_bits_stage1_entry_7_vmid, i_io_resp_bits_stage1_entry_7_vmid;
  logic            g_io_resp_bits_stage1_entry_7_n, i_io_resp_bits_stage1_entry_7_n;
  logic [1:0]      g_io_resp_bits_stage1_entry_7_pbmt, i_io_resp_bits_stage1_entry_7_pbmt;
  logic            g_io_resp_bits_stage1_entry_7_perm_d, i_io_resp_bits_stage1_entry_7_perm_d;
  logic            g_io_resp_bits_stage1_entry_7_perm_a, i_io_resp_bits_stage1_entry_7_perm_a;
  logic            g_io_resp_bits_stage1_entry_7_perm_g, i_io_resp_bits_stage1_entry_7_perm_g;
  logic            g_io_resp_bits_stage1_entry_7_perm_u, i_io_resp_bits_stage1_entry_7_perm_u;
  logic            g_io_resp_bits_stage1_entry_7_perm_x, i_io_resp_bits_stage1_entry_7_perm_x;
  logic            g_io_resp_bits_stage1_entry_7_perm_w, i_io_resp_bits_stage1_entry_7_perm_w;
  logic            g_io_resp_bits_stage1_entry_7_perm_r, i_io_resp_bits_stage1_entry_7_perm_r;
  logic [1:0]      g_io_resp_bits_stage1_entry_7_level, i_io_resp_bits_stage1_entry_7_level;
  logic            g_io_resp_bits_stage1_entry_7_v, i_io_resp_bits_stage1_entry_7_v;
  logic [40:0]     g_io_resp_bits_stage1_entry_7_ppn, i_io_resp_bits_stage1_entry_7_ppn;
  logic [2:0]      g_io_resp_bits_stage1_entry_7_ppn_low, i_io_resp_bits_stage1_entry_7_ppn_low;
  logic            g_io_resp_bits_stage1_entry_7_pf, i_io_resp_bits_stage1_entry_7_pf;
  logic            g_io_resp_bits_stage1_entry_7_cf, i_io_resp_bits_stage1_entry_7_cf;
  logic            g_io_resp_bits_stage1_pteidx_0, i_io_resp_bits_stage1_pteidx_0;
  logic            g_io_resp_bits_stage1_pteidx_1, i_io_resp_bits_stage1_pteidx_1;
  logic            g_io_resp_bits_stage1_pteidx_2, i_io_resp_bits_stage1_pteidx_2;
  logic            g_io_resp_bits_stage1_pteidx_3, i_io_resp_bits_stage1_pteidx_3;
  logic            g_io_resp_bits_stage1_pteidx_4, i_io_resp_bits_stage1_pteidx_4;
  logic            g_io_resp_bits_stage1_pteidx_5, i_io_resp_bits_stage1_pteidx_5;
  logic            g_io_resp_bits_stage1_pteidx_6, i_io_resp_bits_stage1_pteidx_6;
  logic            g_io_resp_bits_stage1_pteidx_7, i_io_resp_bits_stage1_pteidx_7;
  logic            g_io_resp_bits_stage1_not_super, i_io_resp_bits_stage1_not_super;
  logic            g_io_resp_bits_isHptwReq, i_io_resp_bits_isHptwReq;
  logic            g_io_resp_bits_toHptw_l3Hit, i_io_resp_bits_toHptw_l3Hit;
  logic            g_io_resp_bits_toHptw_l2Hit, i_io_resp_bits_toHptw_l2Hit;
  logic            g_io_resp_bits_toHptw_l1Hit, i_io_resp_bits_toHptw_l1Hit;
  logic [35:0]     g_io_resp_bits_toHptw_ppn, i_io_resp_bits_toHptw_ppn;
  logic [2:0]      g_io_resp_bits_toHptw_id, i_io_resp_bits_toHptw_id;
  logic [37:0]     g_io_resp_bits_toHptw_resp_entry_tag, i_io_resp_bits_toHptw_resp_entry_tag;
  logic [13:0]     g_io_resp_bits_toHptw_resp_entry_vmid, i_io_resp_bits_toHptw_resp_entry_vmid;
  logic            g_io_resp_bits_toHptw_resp_entry_n, i_io_resp_bits_toHptw_resp_entry_n;
  logic [1:0]      g_io_resp_bits_toHptw_resp_entry_pbmt, i_io_resp_bits_toHptw_resp_entry_pbmt;
  logic [37:0]     g_io_resp_bits_toHptw_resp_entry_ppn, i_io_resp_bits_toHptw_resp_entry_ppn;
  logic            g_io_resp_bits_toHptw_resp_entry_perm_d, i_io_resp_bits_toHptw_resp_entry_perm_d;
  logic            g_io_resp_bits_toHptw_resp_entry_perm_a, i_io_resp_bits_toHptw_resp_entry_perm_a;
  logic            g_io_resp_bits_toHptw_resp_entry_perm_g, i_io_resp_bits_toHptw_resp_entry_perm_g;
  logic            g_io_resp_bits_toHptw_resp_entry_perm_u, i_io_resp_bits_toHptw_resp_entry_perm_u;
  logic            g_io_resp_bits_toHptw_resp_entry_perm_x, i_io_resp_bits_toHptw_resp_entry_perm_x;
  logic            g_io_resp_bits_toHptw_resp_entry_perm_w, i_io_resp_bits_toHptw_resp_entry_perm_w;
  logic            g_io_resp_bits_toHptw_resp_entry_perm_r, i_io_resp_bits_toHptw_resp_entry_perm_r;
  logic [1:0]      g_io_resp_bits_toHptw_resp_entry_level, i_io_resp_bits_toHptw_resp_entry_level;
  logic            g_io_resp_bits_toHptw_resp_gpf, i_io_resp_bits_toHptw_resp_gpf;
  logic            g_io_resp_bits_toHptw_bypassed, i_io_resp_bits_toHptw_bypassed;
  logic            g_io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check, i_io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check;
  logic [3:0]      g_io_resp_bits_toHptw_bitmapCheck_hitway, i_io_resp_bits_toHptw_bitmapCheck_hitway;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_pte, i_io_resp_bits_toHptw_bitmapCheck_pte;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_ptes_0, i_io_resp_bits_toHptw_bitmapCheck_ptes_0;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_ptes_1, i_io_resp_bits_toHptw_bitmapCheck_ptes_1;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_ptes_2, i_io_resp_bits_toHptw_bitmapCheck_ptes_2;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_ptes_3, i_io_resp_bits_toHptw_bitmapCheck_ptes_3;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_ptes_4, i_io_resp_bits_toHptw_bitmapCheck_ptes_4;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_ptes_5, i_io_resp_bits_toHptw_bitmapCheck_ptes_5;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_ptes_6, i_io_resp_bits_toHptw_bitmapCheck_ptes_6;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_ptes_7, i_io_resp_bits_toHptw_bitmapCheck_ptes_7;
  logic            g_io_resp_bits_toHptw_bitmapCheck_fromSP, i_io_resp_bits_toHptw_bitmapCheck_fromSP;
  logic [1:0]      g_io_resp_bits_toHptw_bitmapCheck_SPlevel, i_io_resp_bits_toHptw_bitmapCheck_SPlevel;
  logic            io_refill_valid;
  logic [511:0]    io_refill_bits_ptes;
  logic            io_refill_bits_levelOH_sp;
  logic            io_refill_bits_levelOH_l0;
  logic            io_refill_bits_levelOH_l1;
  logic            io_refill_bits_levelOH_l2;
  logic            io_refill_bits_levelOH_l3;
  logic [37:0]     io_refill_bits_req_info_dup_0_vpn;
  logic [1:0]      io_refill_bits_req_info_dup_0_s2xlate;
  logic [1:0]      io_refill_bits_req_info_dup_0_source;
  logic [37:0]     io_refill_bits_req_info_dup_1_vpn;
  logic [1:0]      io_refill_bits_req_info_dup_1_s2xlate;
  logic [1:0]      io_refill_bits_req_info_dup_1_source;
  logic [37:0]     io_refill_bits_req_info_dup_2_vpn;
  logic [1:0]      io_refill_bits_req_info_dup_2_s2xlate;
  logic [1:0]      io_refill_bits_req_info_dup_2_source;
  logic [1:0]      io_refill_bits_level_dup_0;
  logic [1:0]      io_refill_bits_level_dup_2;
  logic [63:0]     io_refill_bits_sel_pte_dup_0;
  logic [63:0]     io_refill_bits_sel_pte_dup_2;
  logic [3:0]      g_io_l0_way_info, i_io_l0_way_info;
  logic            io_sfence_dup_0_valid;
  logic            io_sfence_dup_0_bits_rs1;
  logic            io_sfence_dup_0_bits_rs2;
  logic [49:0]     io_sfence_dup_0_bits_addr;
  logic [15:0]     io_sfence_dup_0_bits_id;
  logic            io_sfence_dup_0_bits_hv;
  logic            io_sfence_dup_0_bits_hg;
  logic            io_sfence_dup_1_valid;
  logic [15:0]     io_sfence_dup_1_bits_id;
  logic            io_sfence_dup_2_valid;
  logic            io_sfence_dup_2_bits_rs1;
  logic            io_sfence_dup_2_bits_rs2;
  logic [15:0]     io_sfence_dup_2_bits_id;
  logic [15:0]     io_csr_dup_0_satp_asid;
  logic            io_csr_dup_0_satp_changed;
  logic [15:0]     io_csr_dup_0_vsatp_asid;
  logic            io_csr_dup_0_vsatp_changed;
  logic [3:0]      io_csr_dup_0_hgatp_mode;
  logic [15:0]     io_csr_dup_0_hgatp_vmid;
  logic            io_csr_dup_0_hgatp_changed;
  logic            io_csr_dup_0_mbmc_BME;
  logic            io_csr_dup_0_mbmc_CMODE;
  logic            io_csr_dup_0_priv_virt;
  logic            io_csr_dup_0_priv_virt_changed;
  logic [15:0]     io_csr_dup_1_satp_asid;
  logic            io_csr_dup_1_satp_changed;
  logic [15:0]     io_csr_dup_1_vsatp_asid;
  logic            io_csr_dup_1_vsatp_changed;
  logic [3:0]      io_csr_dup_1_hgatp_mode;
  logic [15:0]     io_csr_dup_1_hgatp_vmid;
  logic            io_csr_dup_1_hgatp_changed;
  logic            io_csr_dup_1_priv_virt;
  logic            io_csr_dup_1_priv_virt_changed;
  logic [15:0]     io_csr_dup_2_satp_asid;
  logic            io_csr_dup_2_satp_changed;
  logic [15:0]     io_csr_dup_2_vsatp_asid;
  logic            io_csr_dup_2_vsatp_changed;
  logic [3:0]      io_csr_dup_2_hgatp_mode;
  logic [15:0]     io_csr_dup_2_hgatp_vmid;
  logic            io_csr_dup_2_hgatp_changed;
  logic            io_csr_dup_2_priv_virt;
  logic            io_csr_dup_2_priv_virt_changed;
  logic            g_io_bitmap_wakeup_ready, i_io_bitmap_wakeup_ready;
  logic            io_bitmap_wakeup_valid;
  logic [5:0]      io_bitmap_wakeup_bits_setIndex;
  logic [37:0]     io_bitmap_wakeup_bits_tag;
  logic [3:0]      io_bitmap_wakeup_bits_way_info;
  logic [2:0]      io_bitmap_wakeup_bits_pte_index;
  logic            io_bitmap_wakeup_bits_check_success;
  logic [1:0]      io_bitmap_wakeup_bits_s2xlate;
  logic [5:0]      g_io_perf_0_value, i_io_perf_0_value;
  logic [5:0]      g_io_perf_1_value, i_io_perf_1_value;
  logic [5:0]      g_io_perf_2_value, i_io_perf_2_value;
  logic [5:0]      g_io_perf_3_value, i_io_perf_3_value;
  logic [5:0]      g_io_perf_4_value, i_io_perf_4_value;
  logic [5:0]      g_io_perf_5_value, i_io_perf_5_value;
  logic [5:0]      g_io_perf_6_value, i_io_perf_6_value;
  logic [5:0]      g_io_perf_7_value, i_io_perf_7_value;
  logic [5:0]      boreChildrenBd_bore_array;
  logic            boreChildrenBd_bore_all;
  logic            boreChildrenBd_bore_req;
  logic            g_boreChildrenBd_bore_ack, i_boreChildrenBd_bore_ack;
  logic            boreChildrenBd_bore_writeen;
  logic            boreChildrenBd_bore_be;
  logic [2:0]      boreChildrenBd_bore_addr;
  logic [130:0]    boreChildrenBd_bore_indata;
  logic            boreChildrenBd_bore_readen;
  logic [2:0]      boreChildrenBd_bore_addr_rd;
  logic [130:0]    g_boreChildrenBd_bore_outdata, i_boreChildrenBd_bore_outdata;
  logic [6:0]      boreChildrenBd_bore_1_array;
  logic            boreChildrenBd_bore_1_all;
  logic            boreChildrenBd_bore_1_req;
  logic            g_boreChildrenBd_bore_1_ack, i_boreChildrenBd_bore_1_ack;
  logic            boreChildrenBd_bore_1_writeen;
  logic [1:0]      boreChildrenBd_bore_1_be;
  logic [6:0]      boreChildrenBd_bore_1_addr;
  logic [113:0]    boreChildrenBd_bore_1_indata;
  logic            boreChildrenBd_bore_1_readen;
  logic [6:0]      boreChildrenBd_bore_1_addr_rd;
  logic [113:0]    g_boreChildrenBd_bore_1_outdata, i_boreChildrenBd_bore_1_outdata;
  logic            sigFromSrams_bore_ram_hold;
  logic            sigFromSrams_bore_ram_bypass;
  logic            sigFromSrams_bore_ram_bp_clken;
  logic            sigFromSrams_bore_ram_aux_clk;
  logic            sigFromSrams_bore_ram_aux_ckbp;
  logic            sigFromSrams_bore_ram_mcp_hold;
  logic            sigFromSrams_bore_cgen;
  logic            sigFromSrams_bore_1_ram_hold;
  logic            sigFromSrams_bore_1_ram_bypass;
  logic            sigFromSrams_bore_1_ram_bp_clken;
  logic            sigFromSrams_bore_1_ram_aux_clk;
  logic            sigFromSrams_bore_1_ram_aux_ckbp;
  logic            sigFromSrams_bore_1_ram_mcp_hold;
  logic            sigFromSrams_bore_1_cgen;
  logic            sigFromSrams_bore_2_ram_hold;
  logic            sigFromSrams_bore_2_ram_bypass;
  logic            sigFromSrams_bore_2_ram_bp_clken;
  logic            sigFromSrams_bore_2_ram_aux_clk;
  logic            sigFromSrams_bore_2_ram_aux_ckbp;
  logic            sigFromSrams_bore_2_ram_mcp_hold;
  logic            sigFromSrams_bore_2_cgen;
  logic            sigFromSrams_bore_3_ram_hold;
  logic            sigFromSrams_bore_3_ram_bypass;
  logic            sigFromSrams_bore_3_ram_bp_clken;
  logic            sigFromSrams_bore_3_ram_aux_clk;
  logic            sigFromSrams_bore_3_ram_aux_ckbp;
  logic            sigFromSrams_bore_3_ram_mcp_hold;
  logic            sigFromSrams_bore_3_cgen;
  logic            sigFromSrams_bore_4_ram_hold;
  logic            sigFromSrams_bore_4_ram_bypass;
  logic            sigFromSrams_bore_4_ram_bp_clken;
  logic            sigFromSrams_bore_4_ram_aux_clk;
  logic            sigFromSrams_bore_4_ram_aux_ckbp;
  logic            sigFromSrams_bore_4_ram_mcp_hold;
  logic            sigFromSrams_bore_4_cgen;
  logic            sigFromSrams_bore_5_ram_hold;
  logic            sigFromSrams_bore_5_ram_bypass;
  logic            sigFromSrams_bore_5_ram_bp_clken;
  logic            sigFromSrams_bore_5_ram_aux_clk;
  logic            sigFromSrams_bore_5_ram_aux_ckbp;
  logic            sigFromSrams_bore_5_ram_mcp_hold;
  logic            sigFromSrams_bore_5_cgen;
  logic            sigFromSrams_bore_6_ram_hold;
  logic            sigFromSrams_bore_6_ram_bypass;
  logic            sigFromSrams_bore_6_ram_bp_clken;
  logic            sigFromSrams_bore_6_ram_aux_clk;
  logic            sigFromSrams_bore_6_ram_aux_ckbp;
  logic            sigFromSrams_bore_6_ram_mcp_hold;
  logic            sigFromSrams_bore_6_cgen;
  logic            sigFromSrams_bore_7_ram_hold;
  logic            sigFromSrams_bore_7_ram_bypass;
  logic            sigFromSrams_bore_7_ram_bp_clken;
  logic            sigFromSrams_bore_7_ram_aux_clk;
  logic            sigFromSrams_bore_7_ram_aux_ckbp;
  logic            sigFromSrams_bore_7_ram_mcp_hold;
  logic            sigFromSrams_bore_7_cgen;
  logic            sigFromSrams_bore_8_ram_hold;
  logic            sigFromSrams_bore_8_ram_bypass;
  logic            sigFromSrams_bore_8_ram_bp_clken;
  logic            sigFromSrams_bore_8_ram_aux_clk;
  logic            sigFromSrams_bore_8_ram_aux_ckbp;
  logic            sigFromSrams_bore_8_ram_mcp_hold;
  logic            sigFromSrams_bore_8_cgen;
  logic            sigFromSrams_bore_9_ram_hold;
  logic            sigFromSrams_bore_9_ram_bypass;
  logic            sigFromSrams_bore_9_ram_bp_clken;
  logic            sigFromSrams_bore_9_ram_aux_clk;
  logic            sigFromSrams_bore_9_ram_aux_ckbp;
  logic            sigFromSrams_bore_9_ram_mcp_hold;
  logic            sigFromSrams_bore_9_cgen;
  logic            sigFromSrams_bore_10_ram_hold;
  logic            sigFromSrams_bore_10_ram_bypass;
  logic            sigFromSrams_bore_10_ram_bp_clken;
  logic            sigFromSrams_bore_10_ram_aux_clk;
  logic            sigFromSrams_bore_10_ram_aux_ckbp;
  logic            sigFromSrams_bore_10_ram_mcp_hold;
  logic            sigFromSrams_bore_10_cgen;
  logic            sigFromSrams_bore_11_ram_hold;
  logic            sigFromSrams_bore_11_ram_bypass;
  logic            sigFromSrams_bore_11_ram_bp_clken;
  logic            sigFromSrams_bore_11_ram_aux_clk;
  logic            sigFromSrams_bore_11_ram_aux_ckbp;
  logic            sigFromSrams_bore_11_ram_mcp_hold;
  logic            sigFromSrams_bore_11_cgen;
  logic            sigFromSrams_bore_12_ram_hold;
  logic            sigFromSrams_bore_12_ram_bypass;
  logic            sigFromSrams_bore_12_ram_bp_clken;
  logic            sigFromSrams_bore_12_ram_aux_clk;
  logic            sigFromSrams_bore_12_ram_aux_ckbp;
  logic            sigFromSrams_bore_12_ram_mcp_hold;
  logic            sigFromSrams_bore_12_cgen;
  logic            sigFromSrams_bore_13_ram_hold;
  logic            sigFromSrams_bore_13_ram_bypass;
  logic            sigFromSrams_bore_13_ram_bp_clken;
  logic            sigFromSrams_bore_13_ram_aux_clk;
  logic            sigFromSrams_bore_13_ram_aux_ckbp;
  logic            sigFromSrams_bore_13_ram_mcp_hold;
  logic            sigFromSrams_bore_13_cgen;
  logic            sigFromSrams_bore_14_ram_hold;
  logic            sigFromSrams_bore_14_ram_bypass;
  logic            sigFromSrams_bore_14_ram_bp_clken;
  logic            sigFromSrams_bore_14_ram_aux_clk;
  logic            sigFromSrams_bore_14_ram_aux_ckbp;
  logic            sigFromSrams_bore_14_ram_mcp_hold;
  logic            sigFromSrams_bore_14_cgen;
  logic            sigFromSrams_bore_15_ram_hold;
  logic            sigFromSrams_bore_15_ram_bypass;
  logic            sigFromSrams_bore_15_ram_bp_clken;
  logic            sigFromSrams_bore_15_ram_aux_clk;
  logic            sigFromSrams_bore_15_ram_aux_ckbp;
  logic            sigFromSrams_bore_15_ram_mcp_hold;
  logic            sigFromSrams_bore_15_cgen;
  logic            sigFromSrams_bore_16_ram_hold;
  logic            sigFromSrams_bore_16_ram_bypass;
  logic            sigFromSrams_bore_16_ram_bp_clken;
  logic            sigFromSrams_bore_16_ram_aux_clk;
  logic            sigFromSrams_bore_16_ram_aux_ckbp;
  logic            sigFromSrams_bore_16_ram_mcp_hold;
  logic            sigFromSrams_bore_16_cgen;
  logic            cg_bore_cgen;
  logic clock = 1'b0;
  logic reset = 1'b1;
  always #5 clock = ~clock;

  PtwCache dut_g (
    .clock                                      (clock),
    .reset                                      (reset),
    .io_csr_mPBMTE                              (io_csr_mPBMTE),
    .io_csr_hPBMTE                              (io_csr_hPBMTE),
    .io_req_ready                               (g_io_req_ready),
    .io_req_valid                               (io_req_valid),
    .io_req_bits_req_info_vpn                   (io_req_bits_req_info_vpn),
    .io_req_bits_req_info_s2xlate               (io_req_bits_req_info_s2xlate),
    .io_req_bits_req_info_source                (io_req_bits_req_info_source),
    .io_req_bits_isFirst                        (io_req_bits_isFirst),
    .io_req_bits_isHptwReq                      (io_req_bits_isHptwReq),
    .io_req_bits_hptwId                         (io_req_bits_hptwId),
    .io_resp_ready                              (io_resp_ready),
    .io_resp_valid                              (g_io_resp_valid),
    .io_resp_bits_req_info_vpn                  (g_io_resp_bits_req_info_vpn),
    .io_resp_bits_req_info_s2xlate              (g_io_resp_bits_req_info_s2xlate),
    .io_resp_bits_req_info_source               (g_io_resp_bits_req_info_source),
    .io_resp_bits_isFirst                       (g_io_resp_bits_isFirst),
    .io_resp_bits_hit                           (g_io_resp_bits_hit),
    .io_resp_bits_prefetch                      (g_io_resp_bits_prefetch),
    .io_resp_bits_bypassed                      (g_io_resp_bits_bypassed),
    .io_resp_bits_toFsm_l3Hit                   (g_io_resp_bits_toFsm_l3Hit),
    .io_resp_bits_toFsm_l2Hit                   (g_io_resp_bits_toFsm_l2Hit),
    .io_resp_bits_toFsm_l1Hit                   (g_io_resp_bits_toFsm_l1Hit),
    .io_resp_bits_toFsm_ppn                     (g_io_resp_bits_toFsm_ppn),
    .io_resp_bits_toFsm_stage1Hit               (g_io_resp_bits_toFsm_stage1Hit),
    .io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check (g_io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check),
    .io_resp_bits_toFsm_bitmapCheck_toLLPTW     (g_io_resp_bits_toFsm_bitmapCheck_toLLPTW),
    .io_resp_bits_toFsm_bitmapCheck_hitway      (g_io_resp_bits_toFsm_bitmapCheck_hitway),
    .io_resp_bits_toFsm_bitmapCheck_pte         (g_io_resp_bits_toFsm_bitmapCheck_pte),
    .io_resp_bits_toFsm_bitmapCheck_ptes_0      (g_io_resp_bits_toFsm_bitmapCheck_ptes_0),
    .io_resp_bits_toFsm_bitmapCheck_ptes_1      (g_io_resp_bits_toFsm_bitmapCheck_ptes_1),
    .io_resp_bits_toFsm_bitmapCheck_ptes_2      (g_io_resp_bits_toFsm_bitmapCheck_ptes_2),
    .io_resp_bits_toFsm_bitmapCheck_ptes_3      (g_io_resp_bits_toFsm_bitmapCheck_ptes_3),
    .io_resp_bits_toFsm_bitmapCheck_ptes_4      (g_io_resp_bits_toFsm_bitmapCheck_ptes_4),
    .io_resp_bits_toFsm_bitmapCheck_ptes_5      (g_io_resp_bits_toFsm_bitmapCheck_ptes_5),
    .io_resp_bits_toFsm_bitmapCheck_ptes_6      (g_io_resp_bits_toFsm_bitmapCheck_ptes_6),
    .io_resp_bits_toFsm_bitmapCheck_ptes_7      (g_io_resp_bits_toFsm_bitmapCheck_ptes_7),
    .io_resp_bits_toFsm_bitmapCheck_cfs_0       (g_io_resp_bits_toFsm_bitmapCheck_cfs_0),
    .io_resp_bits_toFsm_bitmapCheck_cfs_1       (g_io_resp_bits_toFsm_bitmapCheck_cfs_1),
    .io_resp_bits_toFsm_bitmapCheck_cfs_2       (g_io_resp_bits_toFsm_bitmapCheck_cfs_2),
    .io_resp_bits_toFsm_bitmapCheck_cfs_3       (g_io_resp_bits_toFsm_bitmapCheck_cfs_3),
    .io_resp_bits_toFsm_bitmapCheck_cfs_4       (g_io_resp_bits_toFsm_bitmapCheck_cfs_4),
    .io_resp_bits_toFsm_bitmapCheck_cfs_5       (g_io_resp_bits_toFsm_bitmapCheck_cfs_5),
    .io_resp_bits_toFsm_bitmapCheck_cfs_6       (g_io_resp_bits_toFsm_bitmapCheck_cfs_6),
    .io_resp_bits_toFsm_bitmapCheck_cfs_7       (g_io_resp_bits_toFsm_bitmapCheck_cfs_7),
    .io_resp_bits_toFsm_bitmapCheck_SPlevel     (g_io_resp_bits_toFsm_bitmapCheck_SPlevel),
    .io_resp_bits_stage1_entry_0_tag            (g_io_resp_bits_stage1_entry_0_tag),
    .io_resp_bits_stage1_entry_0_asid           (g_io_resp_bits_stage1_entry_0_asid),
    .io_resp_bits_stage1_entry_0_vmid           (g_io_resp_bits_stage1_entry_0_vmid),
    .io_resp_bits_stage1_entry_0_n              (g_io_resp_bits_stage1_entry_0_n),
    .io_resp_bits_stage1_entry_0_pbmt           (g_io_resp_bits_stage1_entry_0_pbmt),
    .io_resp_bits_stage1_entry_0_perm_d         (g_io_resp_bits_stage1_entry_0_perm_d),
    .io_resp_bits_stage1_entry_0_perm_a         (g_io_resp_bits_stage1_entry_0_perm_a),
    .io_resp_bits_stage1_entry_0_perm_g         (g_io_resp_bits_stage1_entry_0_perm_g),
    .io_resp_bits_stage1_entry_0_perm_u         (g_io_resp_bits_stage1_entry_0_perm_u),
    .io_resp_bits_stage1_entry_0_perm_x         (g_io_resp_bits_stage1_entry_0_perm_x),
    .io_resp_bits_stage1_entry_0_perm_w         (g_io_resp_bits_stage1_entry_0_perm_w),
    .io_resp_bits_stage1_entry_0_perm_r         (g_io_resp_bits_stage1_entry_0_perm_r),
    .io_resp_bits_stage1_entry_0_level          (g_io_resp_bits_stage1_entry_0_level),
    .io_resp_bits_stage1_entry_0_v              (g_io_resp_bits_stage1_entry_0_v),
    .io_resp_bits_stage1_entry_0_ppn            (g_io_resp_bits_stage1_entry_0_ppn),
    .io_resp_bits_stage1_entry_0_ppn_low        (g_io_resp_bits_stage1_entry_0_ppn_low),
    .io_resp_bits_stage1_entry_0_pf             (g_io_resp_bits_stage1_entry_0_pf),
    .io_resp_bits_stage1_entry_0_cf             (g_io_resp_bits_stage1_entry_0_cf),
    .io_resp_bits_stage1_entry_1_tag            (g_io_resp_bits_stage1_entry_1_tag),
    .io_resp_bits_stage1_entry_1_asid           (g_io_resp_bits_stage1_entry_1_asid),
    .io_resp_bits_stage1_entry_1_vmid           (g_io_resp_bits_stage1_entry_1_vmid),
    .io_resp_bits_stage1_entry_1_n              (g_io_resp_bits_stage1_entry_1_n),
    .io_resp_bits_stage1_entry_1_pbmt           (g_io_resp_bits_stage1_entry_1_pbmt),
    .io_resp_bits_stage1_entry_1_perm_d         (g_io_resp_bits_stage1_entry_1_perm_d),
    .io_resp_bits_stage1_entry_1_perm_a         (g_io_resp_bits_stage1_entry_1_perm_a),
    .io_resp_bits_stage1_entry_1_perm_g         (g_io_resp_bits_stage1_entry_1_perm_g),
    .io_resp_bits_stage1_entry_1_perm_u         (g_io_resp_bits_stage1_entry_1_perm_u),
    .io_resp_bits_stage1_entry_1_perm_x         (g_io_resp_bits_stage1_entry_1_perm_x),
    .io_resp_bits_stage1_entry_1_perm_w         (g_io_resp_bits_stage1_entry_1_perm_w),
    .io_resp_bits_stage1_entry_1_perm_r         (g_io_resp_bits_stage1_entry_1_perm_r),
    .io_resp_bits_stage1_entry_1_level          (g_io_resp_bits_stage1_entry_1_level),
    .io_resp_bits_stage1_entry_1_v              (g_io_resp_bits_stage1_entry_1_v),
    .io_resp_bits_stage1_entry_1_ppn            (g_io_resp_bits_stage1_entry_1_ppn),
    .io_resp_bits_stage1_entry_1_ppn_low        (g_io_resp_bits_stage1_entry_1_ppn_low),
    .io_resp_bits_stage1_entry_1_pf             (g_io_resp_bits_stage1_entry_1_pf),
    .io_resp_bits_stage1_entry_1_cf             (g_io_resp_bits_stage1_entry_1_cf),
    .io_resp_bits_stage1_entry_2_tag            (g_io_resp_bits_stage1_entry_2_tag),
    .io_resp_bits_stage1_entry_2_asid           (g_io_resp_bits_stage1_entry_2_asid),
    .io_resp_bits_stage1_entry_2_vmid           (g_io_resp_bits_stage1_entry_2_vmid),
    .io_resp_bits_stage1_entry_2_n              (g_io_resp_bits_stage1_entry_2_n),
    .io_resp_bits_stage1_entry_2_pbmt           (g_io_resp_bits_stage1_entry_2_pbmt),
    .io_resp_bits_stage1_entry_2_perm_d         (g_io_resp_bits_stage1_entry_2_perm_d),
    .io_resp_bits_stage1_entry_2_perm_a         (g_io_resp_bits_stage1_entry_2_perm_a),
    .io_resp_bits_stage1_entry_2_perm_g         (g_io_resp_bits_stage1_entry_2_perm_g),
    .io_resp_bits_stage1_entry_2_perm_u         (g_io_resp_bits_stage1_entry_2_perm_u),
    .io_resp_bits_stage1_entry_2_perm_x         (g_io_resp_bits_stage1_entry_2_perm_x),
    .io_resp_bits_stage1_entry_2_perm_w         (g_io_resp_bits_stage1_entry_2_perm_w),
    .io_resp_bits_stage1_entry_2_perm_r         (g_io_resp_bits_stage1_entry_2_perm_r),
    .io_resp_bits_stage1_entry_2_level          (g_io_resp_bits_stage1_entry_2_level),
    .io_resp_bits_stage1_entry_2_v              (g_io_resp_bits_stage1_entry_2_v),
    .io_resp_bits_stage1_entry_2_ppn            (g_io_resp_bits_stage1_entry_2_ppn),
    .io_resp_bits_stage1_entry_2_ppn_low        (g_io_resp_bits_stage1_entry_2_ppn_low),
    .io_resp_bits_stage1_entry_2_pf             (g_io_resp_bits_stage1_entry_2_pf),
    .io_resp_bits_stage1_entry_2_cf             (g_io_resp_bits_stage1_entry_2_cf),
    .io_resp_bits_stage1_entry_3_tag            (g_io_resp_bits_stage1_entry_3_tag),
    .io_resp_bits_stage1_entry_3_asid           (g_io_resp_bits_stage1_entry_3_asid),
    .io_resp_bits_stage1_entry_3_vmid           (g_io_resp_bits_stage1_entry_3_vmid),
    .io_resp_bits_stage1_entry_3_n              (g_io_resp_bits_stage1_entry_3_n),
    .io_resp_bits_stage1_entry_3_pbmt           (g_io_resp_bits_stage1_entry_3_pbmt),
    .io_resp_bits_stage1_entry_3_perm_d         (g_io_resp_bits_stage1_entry_3_perm_d),
    .io_resp_bits_stage1_entry_3_perm_a         (g_io_resp_bits_stage1_entry_3_perm_a),
    .io_resp_bits_stage1_entry_3_perm_g         (g_io_resp_bits_stage1_entry_3_perm_g),
    .io_resp_bits_stage1_entry_3_perm_u         (g_io_resp_bits_stage1_entry_3_perm_u),
    .io_resp_bits_stage1_entry_3_perm_x         (g_io_resp_bits_stage1_entry_3_perm_x),
    .io_resp_bits_stage1_entry_3_perm_w         (g_io_resp_bits_stage1_entry_3_perm_w),
    .io_resp_bits_stage1_entry_3_perm_r         (g_io_resp_bits_stage1_entry_3_perm_r),
    .io_resp_bits_stage1_entry_3_level          (g_io_resp_bits_stage1_entry_3_level),
    .io_resp_bits_stage1_entry_3_v              (g_io_resp_bits_stage1_entry_3_v),
    .io_resp_bits_stage1_entry_3_ppn            (g_io_resp_bits_stage1_entry_3_ppn),
    .io_resp_bits_stage1_entry_3_ppn_low        (g_io_resp_bits_stage1_entry_3_ppn_low),
    .io_resp_bits_stage1_entry_3_pf             (g_io_resp_bits_stage1_entry_3_pf),
    .io_resp_bits_stage1_entry_3_cf             (g_io_resp_bits_stage1_entry_3_cf),
    .io_resp_bits_stage1_entry_4_tag            (g_io_resp_bits_stage1_entry_4_tag),
    .io_resp_bits_stage1_entry_4_asid           (g_io_resp_bits_stage1_entry_4_asid),
    .io_resp_bits_stage1_entry_4_vmid           (g_io_resp_bits_stage1_entry_4_vmid),
    .io_resp_bits_stage1_entry_4_n              (g_io_resp_bits_stage1_entry_4_n),
    .io_resp_bits_stage1_entry_4_pbmt           (g_io_resp_bits_stage1_entry_4_pbmt),
    .io_resp_bits_stage1_entry_4_perm_d         (g_io_resp_bits_stage1_entry_4_perm_d),
    .io_resp_bits_stage1_entry_4_perm_a         (g_io_resp_bits_stage1_entry_4_perm_a),
    .io_resp_bits_stage1_entry_4_perm_g         (g_io_resp_bits_stage1_entry_4_perm_g),
    .io_resp_bits_stage1_entry_4_perm_u         (g_io_resp_bits_stage1_entry_4_perm_u),
    .io_resp_bits_stage1_entry_4_perm_x         (g_io_resp_bits_stage1_entry_4_perm_x),
    .io_resp_bits_stage1_entry_4_perm_w         (g_io_resp_bits_stage1_entry_4_perm_w),
    .io_resp_bits_stage1_entry_4_perm_r         (g_io_resp_bits_stage1_entry_4_perm_r),
    .io_resp_bits_stage1_entry_4_level          (g_io_resp_bits_stage1_entry_4_level),
    .io_resp_bits_stage1_entry_4_v              (g_io_resp_bits_stage1_entry_4_v),
    .io_resp_bits_stage1_entry_4_ppn            (g_io_resp_bits_stage1_entry_4_ppn),
    .io_resp_bits_stage1_entry_4_ppn_low        (g_io_resp_bits_stage1_entry_4_ppn_low),
    .io_resp_bits_stage1_entry_4_pf             (g_io_resp_bits_stage1_entry_4_pf),
    .io_resp_bits_stage1_entry_4_cf             (g_io_resp_bits_stage1_entry_4_cf),
    .io_resp_bits_stage1_entry_5_tag            (g_io_resp_bits_stage1_entry_5_tag),
    .io_resp_bits_stage1_entry_5_asid           (g_io_resp_bits_stage1_entry_5_asid),
    .io_resp_bits_stage1_entry_5_vmid           (g_io_resp_bits_stage1_entry_5_vmid),
    .io_resp_bits_stage1_entry_5_n              (g_io_resp_bits_stage1_entry_5_n),
    .io_resp_bits_stage1_entry_5_pbmt           (g_io_resp_bits_stage1_entry_5_pbmt),
    .io_resp_bits_stage1_entry_5_perm_d         (g_io_resp_bits_stage1_entry_5_perm_d),
    .io_resp_bits_stage1_entry_5_perm_a         (g_io_resp_bits_stage1_entry_5_perm_a),
    .io_resp_bits_stage1_entry_5_perm_g         (g_io_resp_bits_stage1_entry_5_perm_g),
    .io_resp_bits_stage1_entry_5_perm_u         (g_io_resp_bits_stage1_entry_5_perm_u),
    .io_resp_bits_stage1_entry_5_perm_x         (g_io_resp_bits_stage1_entry_5_perm_x),
    .io_resp_bits_stage1_entry_5_perm_w         (g_io_resp_bits_stage1_entry_5_perm_w),
    .io_resp_bits_stage1_entry_5_perm_r         (g_io_resp_bits_stage1_entry_5_perm_r),
    .io_resp_bits_stage1_entry_5_level          (g_io_resp_bits_stage1_entry_5_level),
    .io_resp_bits_stage1_entry_5_v              (g_io_resp_bits_stage1_entry_5_v),
    .io_resp_bits_stage1_entry_5_ppn            (g_io_resp_bits_stage1_entry_5_ppn),
    .io_resp_bits_stage1_entry_5_ppn_low        (g_io_resp_bits_stage1_entry_5_ppn_low),
    .io_resp_bits_stage1_entry_5_pf             (g_io_resp_bits_stage1_entry_5_pf),
    .io_resp_bits_stage1_entry_5_cf             (g_io_resp_bits_stage1_entry_5_cf),
    .io_resp_bits_stage1_entry_6_tag            (g_io_resp_bits_stage1_entry_6_tag),
    .io_resp_bits_stage1_entry_6_asid           (g_io_resp_bits_stage1_entry_6_asid),
    .io_resp_bits_stage1_entry_6_vmid           (g_io_resp_bits_stage1_entry_6_vmid),
    .io_resp_bits_stage1_entry_6_n              (g_io_resp_bits_stage1_entry_6_n),
    .io_resp_bits_stage1_entry_6_pbmt           (g_io_resp_bits_stage1_entry_6_pbmt),
    .io_resp_bits_stage1_entry_6_perm_d         (g_io_resp_bits_stage1_entry_6_perm_d),
    .io_resp_bits_stage1_entry_6_perm_a         (g_io_resp_bits_stage1_entry_6_perm_a),
    .io_resp_bits_stage1_entry_6_perm_g         (g_io_resp_bits_stage1_entry_6_perm_g),
    .io_resp_bits_stage1_entry_6_perm_u         (g_io_resp_bits_stage1_entry_6_perm_u),
    .io_resp_bits_stage1_entry_6_perm_x         (g_io_resp_bits_stage1_entry_6_perm_x),
    .io_resp_bits_stage1_entry_6_perm_w         (g_io_resp_bits_stage1_entry_6_perm_w),
    .io_resp_bits_stage1_entry_6_perm_r         (g_io_resp_bits_stage1_entry_6_perm_r),
    .io_resp_bits_stage1_entry_6_level          (g_io_resp_bits_stage1_entry_6_level),
    .io_resp_bits_stage1_entry_6_v              (g_io_resp_bits_stage1_entry_6_v),
    .io_resp_bits_stage1_entry_6_ppn            (g_io_resp_bits_stage1_entry_6_ppn),
    .io_resp_bits_stage1_entry_6_ppn_low        (g_io_resp_bits_stage1_entry_6_ppn_low),
    .io_resp_bits_stage1_entry_6_pf             (g_io_resp_bits_stage1_entry_6_pf),
    .io_resp_bits_stage1_entry_6_cf             (g_io_resp_bits_stage1_entry_6_cf),
    .io_resp_bits_stage1_entry_7_tag            (g_io_resp_bits_stage1_entry_7_tag),
    .io_resp_bits_stage1_entry_7_asid           (g_io_resp_bits_stage1_entry_7_asid),
    .io_resp_bits_stage1_entry_7_vmid           (g_io_resp_bits_stage1_entry_7_vmid),
    .io_resp_bits_stage1_entry_7_n              (g_io_resp_bits_stage1_entry_7_n),
    .io_resp_bits_stage1_entry_7_pbmt           (g_io_resp_bits_stage1_entry_7_pbmt),
    .io_resp_bits_stage1_entry_7_perm_d         (g_io_resp_bits_stage1_entry_7_perm_d),
    .io_resp_bits_stage1_entry_7_perm_a         (g_io_resp_bits_stage1_entry_7_perm_a),
    .io_resp_bits_stage1_entry_7_perm_g         (g_io_resp_bits_stage1_entry_7_perm_g),
    .io_resp_bits_stage1_entry_7_perm_u         (g_io_resp_bits_stage1_entry_7_perm_u),
    .io_resp_bits_stage1_entry_7_perm_x         (g_io_resp_bits_stage1_entry_7_perm_x),
    .io_resp_bits_stage1_entry_7_perm_w         (g_io_resp_bits_stage1_entry_7_perm_w),
    .io_resp_bits_stage1_entry_7_perm_r         (g_io_resp_bits_stage1_entry_7_perm_r),
    .io_resp_bits_stage1_entry_7_level          (g_io_resp_bits_stage1_entry_7_level),
    .io_resp_bits_stage1_entry_7_v              (g_io_resp_bits_stage1_entry_7_v),
    .io_resp_bits_stage1_entry_7_ppn            (g_io_resp_bits_stage1_entry_7_ppn),
    .io_resp_bits_stage1_entry_7_ppn_low        (g_io_resp_bits_stage1_entry_7_ppn_low),
    .io_resp_bits_stage1_entry_7_pf             (g_io_resp_bits_stage1_entry_7_pf),
    .io_resp_bits_stage1_entry_7_cf             (g_io_resp_bits_stage1_entry_7_cf),
    .io_resp_bits_stage1_pteidx_0               (g_io_resp_bits_stage1_pteidx_0),
    .io_resp_bits_stage1_pteidx_1               (g_io_resp_bits_stage1_pteidx_1),
    .io_resp_bits_stage1_pteidx_2               (g_io_resp_bits_stage1_pteidx_2),
    .io_resp_bits_stage1_pteidx_3               (g_io_resp_bits_stage1_pteidx_3),
    .io_resp_bits_stage1_pteidx_4               (g_io_resp_bits_stage1_pteidx_4),
    .io_resp_bits_stage1_pteidx_5               (g_io_resp_bits_stage1_pteidx_5),
    .io_resp_bits_stage1_pteidx_6               (g_io_resp_bits_stage1_pteidx_6),
    .io_resp_bits_stage1_pteidx_7               (g_io_resp_bits_stage1_pteidx_7),
    .io_resp_bits_stage1_not_super              (g_io_resp_bits_stage1_not_super),
    .io_resp_bits_isHptwReq                     (g_io_resp_bits_isHptwReq),
    .io_resp_bits_toHptw_l3Hit                  (g_io_resp_bits_toHptw_l3Hit),
    .io_resp_bits_toHptw_l2Hit                  (g_io_resp_bits_toHptw_l2Hit),
    .io_resp_bits_toHptw_l1Hit                  (g_io_resp_bits_toHptw_l1Hit),
    .io_resp_bits_toHptw_ppn                    (g_io_resp_bits_toHptw_ppn),
    .io_resp_bits_toHptw_id                     (g_io_resp_bits_toHptw_id),
    .io_resp_bits_toHptw_resp_entry_tag         (g_io_resp_bits_toHptw_resp_entry_tag),
    .io_resp_bits_toHptw_resp_entry_vmid        (g_io_resp_bits_toHptw_resp_entry_vmid),
    .io_resp_bits_toHptw_resp_entry_n           (g_io_resp_bits_toHptw_resp_entry_n),
    .io_resp_bits_toHptw_resp_entry_pbmt        (g_io_resp_bits_toHptw_resp_entry_pbmt),
    .io_resp_bits_toHptw_resp_entry_ppn         (g_io_resp_bits_toHptw_resp_entry_ppn),
    .io_resp_bits_toHptw_resp_entry_perm_d      (g_io_resp_bits_toHptw_resp_entry_perm_d),
    .io_resp_bits_toHptw_resp_entry_perm_a      (g_io_resp_bits_toHptw_resp_entry_perm_a),
    .io_resp_bits_toHptw_resp_entry_perm_g      (g_io_resp_bits_toHptw_resp_entry_perm_g),
    .io_resp_bits_toHptw_resp_entry_perm_u      (g_io_resp_bits_toHptw_resp_entry_perm_u),
    .io_resp_bits_toHptw_resp_entry_perm_x      (g_io_resp_bits_toHptw_resp_entry_perm_x),
    .io_resp_bits_toHptw_resp_entry_perm_w      (g_io_resp_bits_toHptw_resp_entry_perm_w),
    .io_resp_bits_toHptw_resp_entry_perm_r      (g_io_resp_bits_toHptw_resp_entry_perm_r),
    .io_resp_bits_toHptw_resp_entry_level       (g_io_resp_bits_toHptw_resp_entry_level),
    .io_resp_bits_toHptw_resp_gpf               (g_io_resp_bits_toHptw_resp_gpf),
    .io_resp_bits_toHptw_bypassed               (g_io_resp_bits_toHptw_bypassed),
    .io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check (g_io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check),
    .io_resp_bits_toHptw_bitmapCheck_hitway     (g_io_resp_bits_toHptw_bitmapCheck_hitway),
    .io_resp_bits_toHptw_bitmapCheck_pte        (g_io_resp_bits_toHptw_bitmapCheck_pte),
    .io_resp_bits_toHptw_bitmapCheck_ptes_0     (g_io_resp_bits_toHptw_bitmapCheck_ptes_0),
    .io_resp_bits_toHptw_bitmapCheck_ptes_1     (g_io_resp_bits_toHptw_bitmapCheck_ptes_1),
    .io_resp_bits_toHptw_bitmapCheck_ptes_2     (g_io_resp_bits_toHptw_bitmapCheck_ptes_2),
    .io_resp_bits_toHptw_bitmapCheck_ptes_3     (g_io_resp_bits_toHptw_bitmapCheck_ptes_3),
    .io_resp_bits_toHptw_bitmapCheck_ptes_4     (g_io_resp_bits_toHptw_bitmapCheck_ptes_4),
    .io_resp_bits_toHptw_bitmapCheck_ptes_5     (g_io_resp_bits_toHptw_bitmapCheck_ptes_5),
    .io_resp_bits_toHptw_bitmapCheck_ptes_6     (g_io_resp_bits_toHptw_bitmapCheck_ptes_6),
    .io_resp_bits_toHptw_bitmapCheck_ptes_7     (g_io_resp_bits_toHptw_bitmapCheck_ptes_7),
    .io_resp_bits_toHptw_bitmapCheck_fromSP     (g_io_resp_bits_toHptw_bitmapCheck_fromSP),
    .io_resp_bits_toHptw_bitmapCheck_SPlevel    (g_io_resp_bits_toHptw_bitmapCheck_SPlevel),
    .io_refill_valid                            (io_refill_valid),
    .io_refill_bits_ptes                        (io_refill_bits_ptes),
    .io_refill_bits_levelOH_sp                  (io_refill_bits_levelOH_sp),
    .io_refill_bits_levelOH_l0                  (io_refill_bits_levelOH_l0),
    .io_refill_bits_levelOH_l1                  (io_refill_bits_levelOH_l1),
    .io_refill_bits_levelOH_l2                  (io_refill_bits_levelOH_l2),
    .io_refill_bits_levelOH_l3                  (io_refill_bits_levelOH_l3),
    .io_refill_bits_req_info_dup_0_vpn          (io_refill_bits_req_info_dup_0_vpn),
    .io_refill_bits_req_info_dup_0_s2xlate      (io_refill_bits_req_info_dup_0_s2xlate),
    .io_refill_bits_req_info_dup_0_source       (io_refill_bits_req_info_dup_0_source),
    .io_refill_bits_req_info_dup_1_vpn          (io_refill_bits_req_info_dup_1_vpn),
    .io_refill_bits_req_info_dup_1_s2xlate      (io_refill_bits_req_info_dup_1_s2xlate),
    .io_refill_bits_req_info_dup_1_source       (io_refill_bits_req_info_dup_1_source),
    .io_refill_bits_req_info_dup_2_vpn          (io_refill_bits_req_info_dup_2_vpn),
    .io_refill_bits_req_info_dup_2_s2xlate      (io_refill_bits_req_info_dup_2_s2xlate),
    .io_refill_bits_req_info_dup_2_source       (io_refill_bits_req_info_dup_2_source),
    .io_refill_bits_level_dup_0                 (io_refill_bits_level_dup_0),
    .io_refill_bits_level_dup_2                 (io_refill_bits_level_dup_2),
    .io_refill_bits_sel_pte_dup_0               (io_refill_bits_sel_pte_dup_0),
    .io_refill_bits_sel_pte_dup_2               (io_refill_bits_sel_pte_dup_2),
    .io_l0_way_info                             (g_io_l0_way_info),
    .io_sfence_dup_0_valid                      (io_sfence_dup_0_valid),
    .io_sfence_dup_0_bits_rs1                   (io_sfence_dup_0_bits_rs1),
    .io_sfence_dup_0_bits_rs2                   (io_sfence_dup_0_bits_rs2),
    .io_sfence_dup_0_bits_addr                  (io_sfence_dup_0_bits_addr),
    .io_sfence_dup_0_bits_id                    (io_sfence_dup_0_bits_id),
    .io_sfence_dup_0_bits_hv                    (io_sfence_dup_0_bits_hv),
    .io_sfence_dup_0_bits_hg                    (io_sfence_dup_0_bits_hg),
    .io_sfence_dup_1_valid                      (io_sfence_dup_1_valid),
    .io_sfence_dup_1_bits_id                    (io_sfence_dup_1_bits_id),
    .io_sfence_dup_2_valid                      (io_sfence_dup_2_valid),
    .io_sfence_dup_2_bits_rs1                   (io_sfence_dup_2_bits_rs1),
    .io_sfence_dup_2_bits_rs2                   (io_sfence_dup_2_bits_rs2),
    .io_sfence_dup_2_bits_id                    (io_sfence_dup_2_bits_id),
    .io_csr_dup_0_satp_asid                     (io_csr_dup_0_satp_asid),
    .io_csr_dup_0_satp_changed                  (io_csr_dup_0_satp_changed),
    .io_csr_dup_0_vsatp_asid                    (io_csr_dup_0_vsatp_asid),
    .io_csr_dup_0_vsatp_changed                 (io_csr_dup_0_vsatp_changed),
    .io_csr_dup_0_hgatp_mode                    (io_csr_dup_0_hgatp_mode),
    .io_csr_dup_0_hgatp_vmid                    (io_csr_dup_0_hgatp_vmid),
    .io_csr_dup_0_hgatp_changed                 (io_csr_dup_0_hgatp_changed),
    .io_csr_dup_0_mbmc_BME                      (io_csr_dup_0_mbmc_BME),
    .io_csr_dup_0_mbmc_CMODE                    (io_csr_dup_0_mbmc_CMODE),
    .io_csr_dup_0_priv_virt                     (io_csr_dup_0_priv_virt),
    .io_csr_dup_0_priv_virt_changed             (io_csr_dup_0_priv_virt_changed),
    .io_csr_dup_1_satp_asid                     (io_csr_dup_1_satp_asid),
    .io_csr_dup_1_satp_changed                  (io_csr_dup_1_satp_changed),
    .io_csr_dup_1_vsatp_asid                    (io_csr_dup_1_vsatp_asid),
    .io_csr_dup_1_vsatp_changed                 (io_csr_dup_1_vsatp_changed),
    .io_csr_dup_1_hgatp_mode                    (io_csr_dup_1_hgatp_mode),
    .io_csr_dup_1_hgatp_vmid                    (io_csr_dup_1_hgatp_vmid),
    .io_csr_dup_1_hgatp_changed                 (io_csr_dup_1_hgatp_changed),
    .io_csr_dup_1_priv_virt                     (io_csr_dup_1_priv_virt),
    .io_csr_dup_1_priv_virt_changed             (io_csr_dup_1_priv_virt_changed),
    .io_csr_dup_2_satp_asid                     (io_csr_dup_2_satp_asid),
    .io_csr_dup_2_satp_changed                  (io_csr_dup_2_satp_changed),
    .io_csr_dup_2_vsatp_asid                    (io_csr_dup_2_vsatp_asid),
    .io_csr_dup_2_vsatp_changed                 (io_csr_dup_2_vsatp_changed),
    .io_csr_dup_2_hgatp_mode                    (io_csr_dup_2_hgatp_mode),
    .io_csr_dup_2_hgatp_vmid                    (io_csr_dup_2_hgatp_vmid),
    .io_csr_dup_2_hgatp_changed                 (io_csr_dup_2_hgatp_changed),
    .io_csr_dup_2_priv_virt                     (io_csr_dup_2_priv_virt),
    .io_csr_dup_2_priv_virt_changed             (io_csr_dup_2_priv_virt_changed),
    .io_bitmap_wakeup_ready                     (g_io_bitmap_wakeup_ready),
    .io_bitmap_wakeup_valid                     (io_bitmap_wakeup_valid),
    .io_bitmap_wakeup_bits_setIndex             (io_bitmap_wakeup_bits_setIndex),
    .io_bitmap_wakeup_bits_tag                  (io_bitmap_wakeup_bits_tag),
    .io_bitmap_wakeup_bits_way_info             (io_bitmap_wakeup_bits_way_info),
    .io_bitmap_wakeup_bits_pte_index            (io_bitmap_wakeup_bits_pte_index),
    .io_bitmap_wakeup_bits_check_success        (io_bitmap_wakeup_bits_check_success),
    .io_bitmap_wakeup_bits_s2xlate              (io_bitmap_wakeup_bits_s2xlate),
    .io_perf_0_value                            (g_io_perf_0_value),
    .io_perf_1_value                            (g_io_perf_1_value),
    .io_perf_2_value                            (g_io_perf_2_value),
    .io_perf_3_value                            (g_io_perf_3_value),
    .io_perf_4_value                            (g_io_perf_4_value),
    .io_perf_5_value                            (g_io_perf_5_value),
    .io_perf_6_value                            (g_io_perf_6_value),
    .io_perf_7_value                            (g_io_perf_7_value),
    .boreChildrenBd_bore_array                  (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all                    (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req                    (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack                    (g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen                (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be                     (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr                   (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata                 (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen                 (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd                (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata                (g_boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_array                (boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all                  (boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req                  (boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_ack                  (g_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_writeen              (boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be                   (boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr                 (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata               (boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen               (boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd              (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_outdata              (g_boreChildrenBd_bore_1_outdata),
    .sigFromSrams_bore_ram_hold                 (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass               (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken             (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk              (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp             (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold             (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen                     (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold               (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass             (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken           (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk            (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp           (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold           (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                   (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold               (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass             (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken           (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk            (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp           (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold           (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                   (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold               (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass             (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken           (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk            (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp           (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold           (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                   (sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold               (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass             (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken           (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk            (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp           (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold           (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                   (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold               (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass             (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken           (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk            (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp           (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold           (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                   (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold               (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass             (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken           (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk            (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp           (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold           (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                   (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold               (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass             (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken           (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk            (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp           (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold           (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                   (sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold               (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass             (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken           (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk            (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp           (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold           (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen                   (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold               (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass             (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken           (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk            (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp           (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold           (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen                   (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold              (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass            (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken          (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk           (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp          (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold          (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen                  (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold              (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass            (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken          (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk           (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp          (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold          (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen                  (sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold              (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass            (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken          (sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk           (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp          (sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold          (sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen                  (sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold              (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass            (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken          (sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk           (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp          (sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold          (sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen                  (sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold              (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass            (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken          (sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk           (sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp          (sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold          (sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen                  (sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold              (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass            (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken          (sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk           (sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp          (sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold          (sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen                  (sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold              (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass            (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken          (sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk           (sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp          (sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold          (sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen                  (sigFromSrams_bore_16_cgen),
    .cg_bore_cgen                               (cg_bore_cgen)
  );
  PtwCache_xs dut_i (
    .clock                                      (clock),
    .reset                                      (reset),
    .io_csr_mPBMTE                              (io_csr_mPBMTE),
    .io_csr_hPBMTE                              (io_csr_hPBMTE),
    .io_req_ready                               (i_io_req_ready),
    .io_req_valid                               (io_req_valid),
    .io_req_bits_req_info_vpn                   (io_req_bits_req_info_vpn),
    .io_req_bits_req_info_s2xlate               (io_req_bits_req_info_s2xlate),
    .io_req_bits_req_info_source                (io_req_bits_req_info_source),
    .io_req_bits_isFirst                        (io_req_bits_isFirst),
    .io_req_bits_isHptwReq                      (io_req_bits_isHptwReq),
    .io_req_bits_hptwId                         (io_req_bits_hptwId),
    .io_resp_ready                              (io_resp_ready),
    .io_resp_valid                              (i_io_resp_valid),
    .io_resp_bits_req_info_vpn                  (i_io_resp_bits_req_info_vpn),
    .io_resp_bits_req_info_s2xlate              (i_io_resp_bits_req_info_s2xlate),
    .io_resp_bits_req_info_source               (i_io_resp_bits_req_info_source),
    .io_resp_bits_isFirst                       (i_io_resp_bits_isFirst),
    .io_resp_bits_hit                           (i_io_resp_bits_hit),
    .io_resp_bits_prefetch                      (i_io_resp_bits_prefetch),
    .io_resp_bits_bypassed                      (i_io_resp_bits_bypassed),
    .io_resp_bits_toFsm_l3Hit                   (i_io_resp_bits_toFsm_l3Hit),
    .io_resp_bits_toFsm_l2Hit                   (i_io_resp_bits_toFsm_l2Hit),
    .io_resp_bits_toFsm_l1Hit                   (i_io_resp_bits_toFsm_l1Hit),
    .io_resp_bits_toFsm_ppn                     (i_io_resp_bits_toFsm_ppn),
    .io_resp_bits_toFsm_stage1Hit               (i_io_resp_bits_toFsm_stage1Hit),
    .io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check (i_io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check),
    .io_resp_bits_toFsm_bitmapCheck_toLLPTW     (i_io_resp_bits_toFsm_bitmapCheck_toLLPTW),
    .io_resp_bits_toFsm_bitmapCheck_hitway      (i_io_resp_bits_toFsm_bitmapCheck_hitway),
    .io_resp_bits_toFsm_bitmapCheck_pte         (i_io_resp_bits_toFsm_bitmapCheck_pte),
    .io_resp_bits_toFsm_bitmapCheck_ptes_0      (i_io_resp_bits_toFsm_bitmapCheck_ptes_0),
    .io_resp_bits_toFsm_bitmapCheck_ptes_1      (i_io_resp_bits_toFsm_bitmapCheck_ptes_1),
    .io_resp_bits_toFsm_bitmapCheck_ptes_2      (i_io_resp_bits_toFsm_bitmapCheck_ptes_2),
    .io_resp_bits_toFsm_bitmapCheck_ptes_3      (i_io_resp_bits_toFsm_bitmapCheck_ptes_3),
    .io_resp_bits_toFsm_bitmapCheck_ptes_4      (i_io_resp_bits_toFsm_bitmapCheck_ptes_4),
    .io_resp_bits_toFsm_bitmapCheck_ptes_5      (i_io_resp_bits_toFsm_bitmapCheck_ptes_5),
    .io_resp_bits_toFsm_bitmapCheck_ptes_6      (i_io_resp_bits_toFsm_bitmapCheck_ptes_6),
    .io_resp_bits_toFsm_bitmapCheck_ptes_7      (i_io_resp_bits_toFsm_bitmapCheck_ptes_7),
    .io_resp_bits_toFsm_bitmapCheck_cfs_0       (i_io_resp_bits_toFsm_bitmapCheck_cfs_0),
    .io_resp_bits_toFsm_bitmapCheck_cfs_1       (i_io_resp_bits_toFsm_bitmapCheck_cfs_1),
    .io_resp_bits_toFsm_bitmapCheck_cfs_2       (i_io_resp_bits_toFsm_bitmapCheck_cfs_2),
    .io_resp_bits_toFsm_bitmapCheck_cfs_3       (i_io_resp_bits_toFsm_bitmapCheck_cfs_3),
    .io_resp_bits_toFsm_bitmapCheck_cfs_4       (i_io_resp_bits_toFsm_bitmapCheck_cfs_4),
    .io_resp_bits_toFsm_bitmapCheck_cfs_5       (i_io_resp_bits_toFsm_bitmapCheck_cfs_5),
    .io_resp_bits_toFsm_bitmapCheck_cfs_6       (i_io_resp_bits_toFsm_bitmapCheck_cfs_6),
    .io_resp_bits_toFsm_bitmapCheck_cfs_7       (i_io_resp_bits_toFsm_bitmapCheck_cfs_7),
    .io_resp_bits_toFsm_bitmapCheck_SPlevel     (i_io_resp_bits_toFsm_bitmapCheck_SPlevel),
    .io_resp_bits_stage1_entry_0_tag            (i_io_resp_bits_stage1_entry_0_tag),
    .io_resp_bits_stage1_entry_0_asid           (i_io_resp_bits_stage1_entry_0_asid),
    .io_resp_bits_stage1_entry_0_vmid           (i_io_resp_bits_stage1_entry_0_vmid),
    .io_resp_bits_stage1_entry_0_n              (i_io_resp_bits_stage1_entry_0_n),
    .io_resp_bits_stage1_entry_0_pbmt           (i_io_resp_bits_stage1_entry_0_pbmt),
    .io_resp_bits_stage1_entry_0_perm_d         (i_io_resp_bits_stage1_entry_0_perm_d),
    .io_resp_bits_stage1_entry_0_perm_a         (i_io_resp_bits_stage1_entry_0_perm_a),
    .io_resp_bits_stage1_entry_0_perm_g         (i_io_resp_bits_stage1_entry_0_perm_g),
    .io_resp_bits_stage1_entry_0_perm_u         (i_io_resp_bits_stage1_entry_0_perm_u),
    .io_resp_bits_stage1_entry_0_perm_x         (i_io_resp_bits_stage1_entry_0_perm_x),
    .io_resp_bits_stage1_entry_0_perm_w         (i_io_resp_bits_stage1_entry_0_perm_w),
    .io_resp_bits_stage1_entry_0_perm_r         (i_io_resp_bits_stage1_entry_0_perm_r),
    .io_resp_bits_stage1_entry_0_level          (i_io_resp_bits_stage1_entry_0_level),
    .io_resp_bits_stage1_entry_0_v              (i_io_resp_bits_stage1_entry_0_v),
    .io_resp_bits_stage1_entry_0_ppn            (i_io_resp_bits_stage1_entry_0_ppn),
    .io_resp_bits_stage1_entry_0_ppn_low        (i_io_resp_bits_stage1_entry_0_ppn_low),
    .io_resp_bits_stage1_entry_0_pf             (i_io_resp_bits_stage1_entry_0_pf),
    .io_resp_bits_stage1_entry_0_cf             (i_io_resp_bits_stage1_entry_0_cf),
    .io_resp_bits_stage1_entry_1_tag            (i_io_resp_bits_stage1_entry_1_tag),
    .io_resp_bits_stage1_entry_1_asid           (i_io_resp_bits_stage1_entry_1_asid),
    .io_resp_bits_stage1_entry_1_vmid           (i_io_resp_bits_stage1_entry_1_vmid),
    .io_resp_bits_stage1_entry_1_n              (i_io_resp_bits_stage1_entry_1_n),
    .io_resp_bits_stage1_entry_1_pbmt           (i_io_resp_bits_stage1_entry_1_pbmt),
    .io_resp_bits_stage1_entry_1_perm_d         (i_io_resp_bits_stage1_entry_1_perm_d),
    .io_resp_bits_stage1_entry_1_perm_a         (i_io_resp_bits_stage1_entry_1_perm_a),
    .io_resp_bits_stage1_entry_1_perm_g         (i_io_resp_bits_stage1_entry_1_perm_g),
    .io_resp_bits_stage1_entry_1_perm_u         (i_io_resp_bits_stage1_entry_1_perm_u),
    .io_resp_bits_stage1_entry_1_perm_x         (i_io_resp_bits_stage1_entry_1_perm_x),
    .io_resp_bits_stage1_entry_1_perm_w         (i_io_resp_bits_stage1_entry_1_perm_w),
    .io_resp_bits_stage1_entry_1_perm_r         (i_io_resp_bits_stage1_entry_1_perm_r),
    .io_resp_bits_stage1_entry_1_level          (i_io_resp_bits_stage1_entry_1_level),
    .io_resp_bits_stage1_entry_1_v              (i_io_resp_bits_stage1_entry_1_v),
    .io_resp_bits_stage1_entry_1_ppn            (i_io_resp_bits_stage1_entry_1_ppn),
    .io_resp_bits_stage1_entry_1_ppn_low        (i_io_resp_bits_stage1_entry_1_ppn_low),
    .io_resp_bits_stage1_entry_1_pf             (i_io_resp_bits_stage1_entry_1_pf),
    .io_resp_bits_stage1_entry_1_cf             (i_io_resp_bits_stage1_entry_1_cf),
    .io_resp_bits_stage1_entry_2_tag            (i_io_resp_bits_stage1_entry_2_tag),
    .io_resp_bits_stage1_entry_2_asid           (i_io_resp_bits_stage1_entry_2_asid),
    .io_resp_bits_stage1_entry_2_vmid           (i_io_resp_bits_stage1_entry_2_vmid),
    .io_resp_bits_stage1_entry_2_n              (i_io_resp_bits_stage1_entry_2_n),
    .io_resp_bits_stage1_entry_2_pbmt           (i_io_resp_bits_stage1_entry_2_pbmt),
    .io_resp_bits_stage1_entry_2_perm_d         (i_io_resp_bits_stage1_entry_2_perm_d),
    .io_resp_bits_stage1_entry_2_perm_a         (i_io_resp_bits_stage1_entry_2_perm_a),
    .io_resp_bits_stage1_entry_2_perm_g         (i_io_resp_bits_stage1_entry_2_perm_g),
    .io_resp_bits_stage1_entry_2_perm_u         (i_io_resp_bits_stage1_entry_2_perm_u),
    .io_resp_bits_stage1_entry_2_perm_x         (i_io_resp_bits_stage1_entry_2_perm_x),
    .io_resp_bits_stage1_entry_2_perm_w         (i_io_resp_bits_stage1_entry_2_perm_w),
    .io_resp_bits_stage1_entry_2_perm_r         (i_io_resp_bits_stage1_entry_2_perm_r),
    .io_resp_bits_stage1_entry_2_level          (i_io_resp_bits_stage1_entry_2_level),
    .io_resp_bits_stage1_entry_2_v              (i_io_resp_bits_stage1_entry_2_v),
    .io_resp_bits_stage1_entry_2_ppn            (i_io_resp_bits_stage1_entry_2_ppn),
    .io_resp_bits_stage1_entry_2_ppn_low        (i_io_resp_bits_stage1_entry_2_ppn_low),
    .io_resp_bits_stage1_entry_2_pf             (i_io_resp_bits_stage1_entry_2_pf),
    .io_resp_bits_stage1_entry_2_cf             (i_io_resp_bits_stage1_entry_2_cf),
    .io_resp_bits_stage1_entry_3_tag            (i_io_resp_bits_stage1_entry_3_tag),
    .io_resp_bits_stage1_entry_3_asid           (i_io_resp_bits_stage1_entry_3_asid),
    .io_resp_bits_stage1_entry_3_vmid           (i_io_resp_bits_stage1_entry_3_vmid),
    .io_resp_bits_stage1_entry_3_n              (i_io_resp_bits_stage1_entry_3_n),
    .io_resp_bits_stage1_entry_3_pbmt           (i_io_resp_bits_stage1_entry_3_pbmt),
    .io_resp_bits_stage1_entry_3_perm_d         (i_io_resp_bits_stage1_entry_3_perm_d),
    .io_resp_bits_stage1_entry_3_perm_a         (i_io_resp_bits_stage1_entry_3_perm_a),
    .io_resp_bits_stage1_entry_3_perm_g         (i_io_resp_bits_stage1_entry_3_perm_g),
    .io_resp_bits_stage1_entry_3_perm_u         (i_io_resp_bits_stage1_entry_3_perm_u),
    .io_resp_bits_stage1_entry_3_perm_x         (i_io_resp_bits_stage1_entry_3_perm_x),
    .io_resp_bits_stage1_entry_3_perm_w         (i_io_resp_bits_stage1_entry_3_perm_w),
    .io_resp_bits_stage1_entry_3_perm_r         (i_io_resp_bits_stage1_entry_3_perm_r),
    .io_resp_bits_stage1_entry_3_level          (i_io_resp_bits_stage1_entry_3_level),
    .io_resp_bits_stage1_entry_3_v              (i_io_resp_bits_stage1_entry_3_v),
    .io_resp_bits_stage1_entry_3_ppn            (i_io_resp_bits_stage1_entry_3_ppn),
    .io_resp_bits_stage1_entry_3_ppn_low        (i_io_resp_bits_stage1_entry_3_ppn_low),
    .io_resp_bits_stage1_entry_3_pf             (i_io_resp_bits_stage1_entry_3_pf),
    .io_resp_bits_stage1_entry_3_cf             (i_io_resp_bits_stage1_entry_3_cf),
    .io_resp_bits_stage1_entry_4_tag            (i_io_resp_bits_stage1_entry_4_tag),
    .io_resp_bits_stage1_entry_4_asid           (i_io_resp_bits_stage1_entry_4_asid),
    .io_resp_bits_stage1_entry_4_vmid           (i_io_resp_bits_stage1_entry_4_vmid),
    .io_resp_bits_stage1_entry_4_n              (i_io_resp_bits_stage1_entry_4_n),
    .io_resp_bits_stage1_entry_4_pbmt           (i_io_resp_bits_stage1_entry_4_pbmt),
    .io_resp_bits_stage1_entry_4_perm_d         (i_io_resp_bits_stage1_entry_4_perm_d),
    .io_resp_bits_stage1_entry_4_perm_a         (i_io_resp_bits_stage1_entry_4_perm_a),
    .io_resp_bits_stage1_entry_4_perm_g         (i_io_resp_bits_stage1_entry_4_perm_g),
    .io_resp_bits_stage1_entry_4_perm_u         (i_io_resp_bits_stage1_entry_4_perm_u),
    .io_resp_bits_stage1_entry_4_perm_x         (i_io_resp_bits_stage1_entry_4_perm_x),
    .io_resp_bits_stage1_entry_4_perm_w         (i_io_resp_bits_stage1_entry_4_perm_w),
    .io_resp_bits_stage1_entry_4_perm_r         (i_io_resp_bits_stage1_entry_4_perm_r),
    .io_resp_bits_stage1_entry_4_level          (i_io_resp_bits_stage1_entry_4_level),
    .io_resp_bits_stage1_entry_4_v              (i_io_resp_bits_stage1_entry_4_v),
    .io_resp_bits_stage1_entry_4_ppn            (i_io_resp_bits_stage1_entry_4_ppn),
    .io_resp_bits_stage1_entry_4_ppn_low        (i_io_resp_bits_stage1_entry_4_ppn_low),
    .io_resp_bits_stage1_entry_4_pf             (i_io_resp_bits_stage1_entry_4_pf),
    .io_resp_bits_stage1_entry_4_cf             (i_io_resp_bits_stage1_entry_4_cf),
    .io_resp_bits_stage1_entry_5_tag            (i_io_resp_bits_stage1_entry_5_tag),
    .io_resp_bits_stage1_entry_5_asid           (i_io_resp_bits_stage1_entry_5_asid),
    .io_resp_bits_stage1_entry_5_vmid           (i_io_resp_bits_stage1_entry_5_vmid),
    .io_resp_bits_stage1_entry_5_n              (i_io_resp_bits_stage1_entry_5_n),
    .io_resp_bits_stage1_entry_5_pbmt           (i_io_resp_bits_stage1_entry_5_pbmt),
    .io_resp_bits_stage1_entry_5_perm_d         (i_io_resp_bits_stage1_entry_5_perm_d),
    .io_resp_bits_stage1_entry_5_perm_a         (i_io_resp_bits_stage1_entry_5_perm_a),
    .io_resp_bits_stage1_entry_5_perm_g         (i_io_resp_bits_stage1_entry_5_perm_g),
    .io_resp_bits_stage1_entry_5_perm_u         (i_io_resp_bits_stage1_entry_5_perm_u),
    .io_resp_bits_stage1_entry_5_perm_x         (i_io_resp_bits_stage1_entry_5_perm_x),
    .io_resp_bits_stage1_entry_5_perm_w         (i_io_resp_bits_stage1_entry_5_perm_w),
    .io_resp_bits_stage1_entry_5_perm_r         (i_io_resp_bits_stage1_entry_5_perm_r),
    .io_resp_bits_stage1_entry_5_level          (i_io_resp_bits_stage1_entry_5_level),
    .io_resp_bits_stage1_entry_5_v              (i_io_resp_bits_stage1_entry_5_v),
    .io_resp_bits_stage1_entry_5_ppn            (i_io_resp_bits_stage1_entry_5_ppn),
    .io_resp_bits_stage1_entry_5_ppn_low        (i_io_resp_bits_stage1_entry_5_ppn_low),
    .io_resp_bits_stage1_entry_5_pf             (i_io_resp_bits_stage1_entry_5_pf),
    .io_resp_bits_stage1_entry_5_cf             (i_io_resp_bits_stage1_entry_5_cf),
    .io_resp_bits_stage1_entry_6_tag            (i_io_resp_bits_stage1_entry_6_tag),
    .io_resp_bits_stage1_entry_6_asid           (i_io_resp_bits_stage1_entry_6_asid),
    .io_resp_bits_stage1_entry_6_vmid           (i_io_resp_bits_stage1_entry_6_vmid),
    .io_resp_bits_stage1_entry_6_n              (i_io_resp_bits_stage1_entry_6_n),
    .io_resp_bits_stage1_entry_6_pbmt           (i_io_resp_bits_stage1_entry_6_pbmt),
    .io_resp_bits_stage1_entry_6_perm_d         (i_io_resp_bits_stage1_entry_6_perm_d),
    .io_resp_bits_stage1_entry_6_perm_a         (i_io_resp_bits_stage1_entry_6_perm_a),
    .io_resp_bits_stage1_entry_6_perm_g         (i_io_resp_bits_stage1_entry_6_perm_g),
    .io_resp_bits_stage1_entry_6_perm_u         (i_io_resp_bits_stage1_entry_6_perm_u),
    .io_resp_bits_stage1_entry_6_perm_x         (i_io_resp_bits_stage1_entry_6_perm_x),
    .io_resp_bits_stage1_entry_6_perm_w         (i_io_resp_bits_stage1_entry_6_perm_w),
    .io_resp_bits_stage1_entry_6_perm_r         (i_io_resp_bits_stage1_entry_6_perm_r),
    .io_resp_bits_stage1_entry_6_level          (i_io_resp_bits_stage1_entry_6_level),
    .io_resp_bits_stage1_entry_6_v              (i_io_resp_bits_stage1_entry_6_v),
    .io_resp_bits_stage1_entry_6_ppn            (i_io_resp_bits_stage1_entry_6_ppn),
    .io_resp_bits_stage1_entry_6_ppn_low        (i_io_resp_bits_stage1_entry_6_ppn_low),
    .io_resp_bits_stage1_entry_6_pf             (i_io_resp_bits_stage1_entry_6_pf),
    .io_resp_bits_stage1_entry_6_cf             (i_io_resp_bits_stage1_entry_6_cf),
    .io_resp_bits_stage1_entry_7_tag            (i_io_resp_bits_stage1_entry_7_tag),
    .io_resp_bits_stage1_entry_7_asid           (i_io_resp_bits_stage1_entry_7_asid),
    .io_resp_bits_stage1_entry_7_vmid           (i_io_resp_bits_stage1_entry_7_vmid),
    .io_resp_bits_stage1_entry_7_n              (i_io_resp_bits_stage1_entry_7_n),
    .io_resp_bits_stage1_entry_7_pbmt           (i_io_resp_bits_stage1_entry_7_pbmt),
    .io_resp_bits_stage1_entry_7_perm_d         (i_io_resp_bits_stage1_entry_7_perm_d),
    .io_resp_bits_stage1_entry_7_perm_a         (i_io_resp_bits_stage1_entry_7_perm_a),
    .io_resp_bits_stage1_entry_7_perm_g         (i_io_resp_bits_stage1_entry_7_perm_g),
    .io_resp_bits_stage1_entry_7_perm_u         (i_io_resp_bits_stage1_entry_7_perm_u),
    .io_resp_bits_stage1_entry_7_perm_x         (i_io_resp_bits_stage1_entry_7_perm_x),
    .io_resp_bits_stage1_entry_7_perm_w         (i_io_resp_bits_stage1_entry_7_perm_w),
    .io_resp_bits_stage1_entry_7_perm_r         (i_io_resp_bits_stage1_entry_7_perm_r),
    .io_resp_bits_stage1_entry_7_level          (i_io_resp_bits_stage1_entry_7_level),
    .io_resp_bits_stage1_entry_7_v              (i_io_resp_bits_stage1_entry_7_v),
    .io_resp_bits_stage1_entry_7_ppn            (i_io_resp_bits_stage1_entry_7_ppn),
    .io_resp_bits_stage1_entry_7_ppn_low        (i_io_resp_bits_stage1_entry_7_ppn_low),
    .io_resp_bits_stage1_entry_7_pf             (i_io_resp_bits_stage1_entry_7_pf),
    .io_resp_bits_stage1_entry_7_cf             (i_io_resp_bits_stage1_entry_7_cf),
    .io_resp_bits_stage1_pteidx_0               (i_io_resp_bits_stage1_pteidx_0),
    .io_resp_bits_stage1_pteidx_1               (i_io_resp_bits_stage1_pteidx_1),
    .io_resp_bits_stage1_pteidx_2               (i_io_resp_bits_stage1_pteidx_2),
    .io_resp_bits_stage1_pteidx_3               (i_io_resp_bits_stage1_pteidx_3),
    .io_resp_bits_stage1_pteidx_4               (i_io_resp_bits_stage1_pteidx_4),
    .io_resp_bits_stage1_pteidx_5               (i_io_resp_bits_stage1_pteidx_5),
    .io_resp_bits_stage1_pteidx_6               (i_io_resp_bits_stage1_pteidx_6),
    .io_resp_bits_stage1_pteidx_7               (i_io_resp_bits_stage1_pteidx_7),
    .io_resp_bits_stage1_not_super              (i_io_resp_bits_stage1_not_super),
    .io_resp_bits_isHptwReq                     (i_io_resp_bits_isHptwReq),
    .io_resp_bits_toHptw_l3Hit                  (i_io_resp_bits_toHptw_l3Hit),
    .io_resp_bits_toHptw_l2Hit                  (i_io_resp_bits_toHptw_l2Hit),
    .io_resp_bits_toHptw_l1Hit                  (i_io_resp_bits_toHptw_l1Hit),
    .io_resp_bits_toHptw_ppn                    (i_io_resp_bits_toHptw_ppn),
    .io_resp_bits_toHptw_id                     (i_io_resp_bits_toHptw_id),
    .io_resp_bits_toHptw_resp_entry_tag         (i_io_resp_bits_toHptw_resp_entry_tag),
    .io_resp_bits_toHptw_resp_entry_vmid        (i_io_resp_bits_toHptw_resp_entry_vmid),
    .io_resp_bits_toHptw_resp_entry_n           (i_io_resp_bits_toHptw_resp_entry_n),
    .io_resp_bits_toHptw_resp_entry_pbmt        (i_io_resp_bits_toHptw_resp_entry_pbmt),
    .io_resp_bits_toHptw_resp_entry_ppn         (i_io_resp_bits_toHptw_resp_entry_ppn),
    .io_resp_bits_toHptw_resp_entry_perm_d      (i_io_resp_bits_toHptw_resp_entry_perm_d),
    .io_resp_bits_toHptw_resp_entry_perm_a      (i_io_resp_bits_toHptw_resp_entry_perm_a),
    .io_resp_bits_toHptw_resp_entry_perm_g      (i_io_resp_bits_toHptw_resp_entry_perm_g),
    .io_resp_bits_toHptw_resp_entry_perm_u      (i_io_resp_bits_toHptw_resp_entry_perm_u),
    .io_resp_bits_toHptw_resp_entry_perm_x      (i_io_resp_bits_toHptw_resp_entry_perm_x),
    .io_resp_bits_toHptw_resp_entry_perm_w      (i_io_resp_bits_toHptw_resp_entry_perm_w),
    .io_resp_bits_toHptw_resp_entry_perm_r      (i_io_resp_bits_toHptw_resp_entry_perm_r),
    .io_resp_bits_toHptw_resp_entry_level       (i_io_resp_bits_toHptw_resp_entry_level),
    .io_resp_bits_toHptw_resp_gpf               (i_io_resp_bits_toHptw_resp_gpf),
    .io_resp_bits_toHptw_bypassed               (i_io_resp_bits_toHptw_bypassed),
    .io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check (i_io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check),
    .io_resp_bits_toHptw_bitmapCheck_hitway     (i_io_resp_bits_toHptw_bitmapCheck_hitway),
    .io_resp_bits_toHptw_bitmapCheck_pte        (i_io_resp_bits_toHptw_bitmapCheck_pte),
    .io_resp_bits_toHptw_bitmapCheck_ptes_0     (i_io_resp_bits_toHptw_bitmapCheck_ptes_0),
    .io_resp_bits_toHptw_bitmapCheck_ptes_1     (i_io_resp_bits_toHptw_bitmapCheck_ptes_1),
    .io_resp_bits_toHptw_bitmapCheck_ptes_2     (i_io_resp_bits_toHptw_bitmapCheck_ptes_2),
    .io_resp_bits_toHptw_bitmapCheck_ptes_3     (i_io_resp_bits_toHptw_bitmapCheck_ptes_3),
    .io_resp_bits_toHptw_bitmapCheck_ptes_4     (i_io_resp_bits_toHptw_bitmapCheck_ptes_4),
    .io_resp_bits_toHptw_bitmapCheck_ptes_5     (i_io_resp_bits_toHptw_bitmapCheck_ptes_5),
    .io_resp_bits_toHptw_bitmapCheck_ptes_6     (i_io_resp_bits_toHptw_bitmapCheck_ptes_6),
    .io_resp_bits_toHptw_bitmapCheck_ptes_7     (i_io_resp_bits_toHptw_bitmapCheck_ptes_7),
    .io_resp_bits_toHptw_bitmapCheck_fromSP     (i_io_resp_bits_toHptw_bitmapCheck_fromSP),
    .io_resp_bits_toHptw_bitmapCheck_SPlevel    (i_io_resp_bits_toHptw_bitmapCheck_SPlevel),
    .io_refill_valid                            (io_refill_valid),
    .io_refill_bits_ptes                        (io_refill_bits_ptes),
    .io_refill_bits_levelOH_sp                  (io_refill_bits_levelOH_sp),
    .io_refill_bits_levelOH_l0                  (io_refill_bits_levelOH_l0),
    .io_refill_bits_levelOH_l1                  (io_refill_bits_levelOH_l1),
    .io_refill_bits_levelOH_l2                  (io_refill_bits_levelOH_l2),
    .io_refill_bits_levelOH_l3                  (io_refill_bits_levelOH_l3),
    .io_refill_bits_req_info_dup_0_vpn          (io_refill_bits_req_info_dup_0_vpn),
    .io_refill_bits_req_info_dup_0_s2xlate      (io_refill_bits_req_info_dup_0_s2xlate),
    .io_refill_bits_req_info_dup_0_source       (io_refill_bits_req_info_dup_0_source),
    .io_refill_bits_req_info_dup_1_vpn          (io_refill_bits_req_info_dup_1_vpn),
    .io_refill_bits_req_info_dup_1_s2xlate      (io_refill_bits_req_info_dup_1_s2xlate),
    .io_refill_bits_req_info_dup_1_source       (io_refill_bits_req_info_dup_1_source),
    .io_refill_bits_req_info_dup_2_vpn          (io_refill_bits_req_info_dup_2_vpn),
    .io_refill_bits_req_info_dup_2_s2xlate      (io_refill_bits_req_info_dup_2_s2xlate),
    .io_refill_bits_req_info_dup_2_source       (io_refill_bits_req_info_dup_2_source),
    .io_refill_bits_level_dup_0                 (io_refill_bits_level_dup_0),
    .io_refill_bits_level_dup_2                 (io_refill_bits_level_dup_2),
    .io_refill_bits_sel_pte_dup_0               (io_refill_bits_sel_pte_dup_0),
    .io_refill_bits_sel_pte_dup_2               (io_refill_bits_sel_pte_dup_2),
    .io_l0_way_info                             (i_io_l0_way_info),
    .io_sfence_dup_0_valid                      (io_sfence_dup_0_valid),
    .io_sfence_dup_0_bits_rs1                   (io_sfence_dup_0_bits_rs1),
    .io_sfence_dup_0_bits_rs2                   (io_sfence_dup_0_bits_rs2),
    .io_sfence_dup_0_bits_addr                  (io_sfence_dup_0_bits_addr),
    .io_sfence_dup_0_bits_id                    (io_sfence_dup_0_bits_id),
    .io_sfence_dup_0_bits_hv                    (io_sfence_dup_0_bits_hv),
    .io_sfence_dup_0_bits_hg                    (io_sfence_dup_0_bits_hg),
    .io_sfence_dup_1_valid                      (io_sfence_dup_1_valid),
    .io_sfence_dup_1_bits_id                    (io_sfence_dup_1_bits_id),
    .io_sfence_dup_2_valid                      (io_sfence_dup_2_valid),
    .io_sfence_dup_2_bits_rs1                   (io_sfence_dup_2_bits_rs1),
    .io_sfence_dup_2_bits_rs2                   (io_sfence_dup_2_bits_rs2),
    .io_sfence_dup_2_bits_id                    (io_sfence_dup_2_bits_id),
    .io_csr_dup_0_satp_asid                     (io_csr_dup_0_satp_asid),
    .io_csr_dup_0_satp_changed                  (io_csr_dup_0_satp_changed),
    .io_csr_dup_0_vsatp_asid                    (io_csr_dup_0_vsatp_asid),
    .io_csr_dup_0_vsatp_changed                 (io_csr_dup_0_vsatp_changed),
    .io_csr_dup_0_hgatp_mode                    (io_csr_dup_0_hgatp_mode),
    .io_csr_dup_0_hgatp_vmid                    (io_csr_dup_0_hgatp_vmid),
    .io_csr_dup_0_hgatp_changed                 (io_csr_dup_0_hgatp_changed),
    .io_csr_dup_0_mbmc_BME                      (io_csr_dup_0_mbmc_BME),
    .io_csr_dup_0_mbmc_CMODE                    (io_csr_dup_0_mbmc_CMODE),
    .io_csr_dup_0_priv_virt                     (io_csr_dup_0_priv_virt),
    .io_csr_dup_0_priv_virt_changed             (io_csr_dup_0_priv_virt_changed),
    .io_csr_dup_1_satp_asid                     (io_csr_dup_1_satp_asid),
    .io_csr_dup_1_satp_changed                  (io_csr_dup_1_satp_changed),
    .io_csr_dup_1_vsatp_asid                    (io_csr_dup_1_vsatp_asid),
    .io_csr_dup_1_vsatp_changed                 (io_csr_dup_1_vsatp_changed),
    .io_csr_dup_1_hgatp_mode                    (io_csr_dup_1_hgatp_mode),
    .io_csr_dup_1_hgatp_vmid                    (io_csr_dup_1_hgatp_vmid),
    .io_csr_dup_1_hgatp_changed                 (io_csr_dup_1_hgatp_changed),
    .io_csr_dup_1_priv_virt                     (io_csr_dup_1_priv_virt),
    .io_csr_dup_1_priv_virt_changed             (io_csr_dup_1_priv_virt_changed),
    .io_csr_dup_2_satp_asid                     (io_csr_dup_2_satp_asid),
    .io_csr_dup_2_satp_changed                  (io_csr_dup_2_satp_changed),
    .io_csr_dup_2_vsatp_asid                    (io_csr_dup_2_vsatp_asid),
    .io_csr_dup_2_vsatp_changed                 (io_csr_dup_2_vsatp_changed),
    .io_csr_dup_2_hgatp_mode                    (io_csr_dup_2_hgatp_mode),
    .io_csr_dup_2_hgatp_vmid                    (io_csr_dup_2_hgatp_vmid),
    .io_csr_dup_2_hgatp_changed                 (io_csr_dup_2_hgatp_changed),
    .io_csr_dup_2_priv_virt                     (io_csr_dup_2_priv_virt),
    .io_csr_dup_2_priv_virt_changed             (io_csr_dup_2_priv_virt_changed),
    .io_bitmap_wakeup_ready                     (i_io_bitmap_wakeup_ready),
    .io_bitmap_wakeup_valid                     (io_bitmap_wakeup_valid),
    .io_bitmap_wakeup_bits_setIndex             (io_bitmap_wakeup_bits_setIndex),
    .io_bitmap_wakeup_bits_tag                  (io_bitmap_wakeup_bits_tag),
    .io_bitmap_wakeup_bits_way_info             (io_bitmap_wakeup_bits_way_info),
    .io_bitmap_wakeup_bits_pte_index            (io_bitmap_wakeup_bits_pte_index),
    .io_bitmap_wakeup_bits_check_success        (io_bitmap_wakeup_bits_check_success),
    .io_bitmap_wakeup_bits_s2xlate              (io_bitmap_wakeup_bits_s2xlate),
    .io_perf_0_value                            (i_io_perf_0_value),
    .io_perf_1_value                            (i_io_perf_1_value),
    .io_perf_2_value                            (i_io_perf_2_value),
    .io_perf_3_value                            (i_io_perf_3_value),
    .io_perf_4_value                            (i_io_perf_4_value),
    .io_perf_5_value                            (i_io_perf_5_value),
    .io_perf_6_value                            (i_io_perf_6_value),
    .io_perf_7_value                            (i_io_perf_7_value),
    .boreChildrenBd_bore_array                  (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all                    (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req                    (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack                    (i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen                (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be                     (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr                   (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata                 (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen                 (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd                (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata                (i_boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_array                (boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all                  (boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req                  (boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_ack                  (i_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_writeen              (boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be                   (boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr                 (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata               (boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen               (boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd              (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_outdata              (i_boreChildrenBd_bore_1_outdata),
    .sigFromSrams_bore_ram_hold                 (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass               (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken             (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk              (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp             (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold             (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen                     (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold               (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass             (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken           (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk            (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp           (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold           (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                   (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold               (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass             (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken           (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk            (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp           (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold           (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                   (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold               (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass             (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken           (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk            (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp           (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold           (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                   (sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold               (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass             (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken           (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk            (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp           (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold           (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                   (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold               (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass             (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken           (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk            (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp           (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold           (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                   (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold               (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass             (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken           (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk            (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp           (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold           (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                   (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold               (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass             (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken           (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk            (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp           (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold           (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                   (sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold               (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass             (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken           (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk            (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp           (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold           (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen                   (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold               (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass             (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken           (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk            (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp           (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold           (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen                   (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold              (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass            (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken          (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk           (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp          (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold          (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen                  (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold              (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass            (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken          (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk           (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp          (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold          (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen                  (sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold              (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass            (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken          (sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk           (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp          (sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold          (sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen                  (sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold              (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass            (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken          (sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk           (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp          (sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold          (sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen                  (sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold              (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass            (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken          (sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk           (sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp          (sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold          (sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen                  (sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold              (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass            (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken          (sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk           (sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp          (sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold          (sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen                  (sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold              (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass            (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken          (sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk           (sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp          (sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold          (sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen                  (sigFromSrams_bore_16_cgen),
    .cg_bore_cgen                               (cg_bore_cgen)
  );

  // waymask 依赖受害者选择 + PLRU，还没追清，在 §8 里被显式钉 0。
  // 这里**不把它排除在比较之外**，而是单独计数：它必须一直失配。
  // 理由：一个"什么都不比"的对照也会 errors=0。untraced_diff>0 就是本对照
  // 有判别力的自证——占位一旦被真实逻辑取代，这个计数会掉到 0，届时应把
  // 对应信号从 is_untraced() 里删掉，而不是让它悄悄变绿。
  function automatic bit is_untraced(input string nm);
    return (nm == "l1.io_w_req_bits_waymask") || (nm == "l0.io_w_req_bits_waymask");
  endfunction

  task automatic chk(input string nm, input logic [63:0] a, input logic [63:0] b);
    checks++;
    if (a !== b) begin
      if (is_untraced(nm)) begin
        untraced_diff++;
      end
      else begin
        errors++;
        if (errors <= 20)
          $display("MISMATCH t=%0t %s golden=%0h impl=%0h", $time, nm, a, b);
      end
    end
  endtask

  // 随机 PTE：整 64 位随机会让 reserved/ppn_high 几乎恒非零，isPf 早早短路，
  // 后面几级判据一条都走不到。所以按字段加权，让每条 when 分支都有机会被走到。
  function automatic logic [63:0] rand_pte();
    logic [63:0] p;
    p = {$urandom(), $urandom()};
    if ($urandom_range(0,3) != 0) p[60:54] = 7'h0;   // reserved 多数清零
    if ($urandom_range(0,3) != 0) p[53:46] = 8'h0;   // ppn_high 多数清零
    if ($urandom_range(0,2) != 0) p[63]    = 1'b0;   // napot 少见
    if ($urandom_range(0,1) == 0) p[13:10] = 4'h8;   // 但一旦有就多给合法 napot
    if ($urandom_range(0,2) != 0) p[62:61] = $urandom_range(0,1) ? 2'b00 : p[62:61];
    if ($urandom_range(0,2) != 0) p[18:10] = 9'h0;   // 让 unaligned 两侧都能取到
    return p;
  endfunction

  task automatic drive_random();
    for (int k = 0; k < 8; k++) io_refill_bits_ptes[64*k +: 64] = rand_pte();
    io_refill_bits_sel_pte_dup_0 = rand_pte();
    io_refill_bits_sel_pte_dup_2 = rand_pte();
    io_refill_valid               = $urandom_range(0,1);
    io_refill_bits_levelOH_sp     = $urandom_range(0,1);
    io_refill_bits_levelOH_l0     = $urandom_range(0,1);
    io_refill_bits_levelOH_l1     = $urandom_range(0,1);
    io_refill_bits_levelOH_l2     = $urandom_range(0,1);
    io_refill_bits_levelOH_l3     = $urandom_range(0,1);
    io_refill_bits_level_dup_0    = $urandom_range(0,3);
    io_refill_bits_level_dup_2    = $urandom_range(0,3);
    io_csr_mPBMTE = $urandom_range(0,1);
    io_csr_hPBMTE = $urandom_range(0,1);
    // ★三份 dup 必须各自独立随机★：绑成一根线的话，"dup 归属写错"这类
    // 错误在本对照里按构造测不出来。
    io_refill_bits_req_info_dup_0_vpn     = {$urandom(), $urandom()};
    io_refill_bits_req_info_dup_0_s2xlate = $urandom_range(0,3);
    io_refill_bits_req_info_dup_0_source  = $urandom_range(0,3);
    io_csr_dup_0_satp_asid  = $urandom();
    io_csr_dup_0_vsatp_asid = $urandom();
    io_csr_dup_0_hgatp_vmid = $urandom();
    io_csr_dup_0_hgatp_mode = $urandom_range(0,1) ? ($urandom_range(0,1) ? 4'h8 : 4'h9) : $urandom_range(0,15);
    io_refill_bits_req_info_dup_1_vpn     = {$urandom(), $urandom()};
    io_refill_bits_req_info_dup_1_s2xlate = $urandom_range(0,3);
    io_refill_bits_req_info_dup_1_source  = $urandom_range(0,3);
    io_csr_dup_1_satp_asid  = $urandom();
    io_csr_dup_1_vsatp_asid = $urandom();
    io_csr_dup_1_hgatp_vmid = $urandom();
    io_csr_dup_1_hgatp_mode = $urandom_range(0,1) ? ($urandom_range(0,1) ? 4'h8 : 4'h9) : $urandom_range(0,15);
    io_refill_bits_req_info_dup_2_vpn     = {$urandom(), $urandom()};
    io_refill_bits_req_info_dup_2_s2xlate = $urandom_range(0,3);
    io_refill_bits_req_info_dup_2_source  = $urandom_range(0,3);
    io_csr_dup_2_satp_asid  = $urandom();
    io_csr_dup_2_vsatp_asid = $urandom();
    io_csr_dup_2_hgatp_vmid = $urandom();
    io_csr_dup_2_hgatp_mode = $urandom_range(0,1) ? ($urandom_range(0,1) ? 4'h8 : 4'h9) : $urandom_range(0,15);
  endtask

  task automatic compare_write_ports();
    chk("l1.io_w_req_valid", dut_g.l1.io_w_req_valid, dut_i.u_core.u_l1_sram.io_w_req_valid);
    chk("l1.io_w_req_bits_setIdx", dut_g.l1.io_w_req_bits_setIdx, dut_i.u_core.u_l1_sram.io_w_req_bits_setIdx);
    chk("l1.io_w_req_bits_data_0_entries_tag", dut_g.l1.io_w_req_bits_data_0_entries_tag, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_tag);
    chk("l1.io_w_req_bits_data_0_entries_asid", dut_g.l1.io_w_req_bits_data_0_entries_asid, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_asid);
    chk("l1.io_w_req_bits_data_0_entries_vmid", dut_g.l1.io_w_req_bits_data_0_entries_vmid, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vmid);
    chk("l1.io_w_req_bits_data_0_entries_pbmts_0", dut_g.l1.io_w_req_bits_data_0_entries_pbmts_0, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_pbmts_0);
    chk("l1.io_w_req_bits_data_0_entries_pbmts_1", dut_g.l1.io_w_req_bits_data_0_entries_pbmts_1, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_pbmts_1);
    chk("l1.io_w_req_bits_data_0_entries_pbmts_2", dut_g.l1.io_w_req_bits_data_0_entries_pbmts_2, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_pbmts_2);
    chk("l1.io_w_req_bits_data_0_entries_pbmts_3", dut_g.l1.io_w_req_bits_data_0_entries_pbmts_3, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_pbmts_3);
    chk("l1.io_w_req_bits_data_0_entries_pbmts_4", dut_g.l1.io_w_req_bits_data_0_entries_pbmts_4, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_pbmts_4);
    chk("l1.io_w_req_bits_data_0_entries_pbmts_5", dut_g.l1.io_w_req_bits_data_0_entries_pbmts_5, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_pbmts_5);
    chk("l1.io_w_req_bits_data_0_entries_pbmts_6", dut_g.l1.io_w_req_bits_data_0_entries_pbmts_6, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_pbmts_6);
    chk("l1.io_w_req_bits_data_0_entries_pbmts_7", dut_g.l1.io_w_req_bits_data_0_entries_pbmts_7, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_pbmts_7);
    chk("l1.io_w_req_bits_data_0_entries_ppns_0", dut_g.l1.io_w_req_bits_data_0_entries_ppns_0, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_ppns_0);
    chk("l1.io_w_req_bits_data_0_entries_ppns_1", dut_g.l1.io_w_req_bits_data_0_entries_ppns_1, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_ppns_1);
    chk("l1.io_w_req_bits_data_0_entries_ppns_2", dut_g.l1.io_w_req_bits_data_0_entries_ppns_2, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_ppns_2);
    chk("l1.io_w_req_bits_data_0_entries_ppns_3", dut_g.l1.io_w_req_bits_data_0_entries_ppns_3, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_ppns_3);
    chk("l1.io_w_req_bits_data_0_entries_ppns_4", dut_g.l1.io_w_req_bits_data_0_entries_ppns_4, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_ppns_4);
    chk("l1.io_w_req_bits_data_0_entries_ppns_5", dut_g.l1.io_w_req_bits_data_0_entries_ppns_5, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_ppns_5);
    chk("l1.io_w_req_bits_data_0_entries_ppns_6", dut_g.l1.io_w_req_bits_data_0_entries_ppns_6, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_ppns_6);
    chk("l1.io_w_req_bits_data_0_entries_ppns_7", dut_g.l1.io_w_req_bits_data_0_entries_ppns_7, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_ppns_7);
    chk("l1.io_w_req_bits_data_0_entries_vs_0", dut_g.l1.io_w_req_bits_data_0_entries_vs_0, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vs_0);
    chk("l1.io_w_req_bits_data_0_entries_vs_1", dut_g.l1.io_w_req_bits_data_0_entries_vs_1, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vs_1);
    chk("l1.io_w_req_bits_data_0_entries_vs_2", dut_g.l1.io_w_req_bits_data_0_entries_vs_2, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vs_2);
    chk("l1.io_w_req_bits_data_0_entries_vs_3", dut_g.l1.io_w_req_bits_data_0_entries_vs_3, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vs_3);
    chk("l1.io_w_req_bits_data_0_entries_vs_4", dut_g.l1.io_w_req_bits_data_0_entries_vs_4, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vs_4);
    chk("l1.io_w_req_bits_data_0_entries_vs_5", dut_g.l1.io_w_req_bits_data_0_entries_vs_5, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vs_5);
    chk("l1.io_w_req_bits_data_0_entries_vs_6", dut_g.l1.io_w_req_bits_data_0_entries_vs_6, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vs_6);
    chk("l1.io_w_req_bits_data_0_entries_vs_7", dut_g.l1.io_w_req_bits_data_0_entries_vs_7, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vs_7);
    chk("l1.io_w_req_bits_data_0_entries_prefetch", dut_g.l1.io_w_req_bits_data_0_entries_prefetch, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_prefetch);
    chk("l1.io_w_req_bits_data_1_entries_tag", dut_g.l1.io_w_req_bits_data_1_entries_tag, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_tag);
    chk("l1.io_w_req_bits_data_1_entries_asid", dut_g.l1.io_w_req_bits_data_1_entries_asid, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_asid);
    chk("l1.io_w_req_bits_data_1_entries_vmid", dut_g.l1.io_w_req_bits_data_1_entries_vmid, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vmid);
    chk("l1.io_w_req_bits_data_1_entries_pbmts_0", dut_g.l1.io_w_req_bits_data_1_entries_pbmts_0, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_pbmts_0);
    chk("l1.io_w_req_bits_data_1_entries_pbmts_1", dut_g.l1.io_w_req_bits_data_1_entries_pbmts_1, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_pbmts_1);
    chk("l1.io_w_req_bits_data_1_entries_pbmts_2", dut_g.l1.io_w_req_bits_data_1_entries_pbmts_2, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_pbmts_2);
    chk("l1.io_w_req_bits_data_1_entries_pbmts_3", dut_g.l1.io_w_req_bits_data_1_entries_pbmts_3, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_pbmts_3);
    chk("l1.io_w_req_bits_data_1_entries_pbmts_4", dut_g.l1.io_w_req_bits_data_1_entries_pbmts_4, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_pbmts_4);
    chk("l1.io_w_req_bits_data_1_entries_pbmts_5", dut_g.l1.io_w_req_bits_data_1_entries_pbmts_5, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_pbmts_5);
    chk("l1.io_w_req_bits_data_1_entries_pbmts_6", dut_g.l1.io_w_req_bits_data_1_entries_pbmts_6, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_pbmts_6);
    chk("l1.io_w_req_bits_data_1_entries_pbmts_7", dut_g.l1.io_w_req_bits_data_1_entries_pbmts_7, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_pbmts_7);
    chk("l1.io_w_req_bits_data_1_entries_ppns_0", dut_g.l1.io_w_req_bits_data_1_entries_ppns_0, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_ppns_0);
    chk("l1.io_w_req_bits_data_1_entries_ppns_1", dut_g.l1.io_w_req_bits_data_1_entries_ppns_1, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_ppns_1);
    chk("l1.io_w_req_bits_data_1_entries_ppns_2", dut_g.l1.io_w_req_bits_data_1_entries_ppns_2, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_ppns_2);
    chk("l1.io_w_req_bits_data_1_entries_ppns_3", dut_g.l1.io_w_req_bits_data_1_entries_ppns_3, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_ppns_3);
    chk("l1.io_w_req_bits_data_1_entries_ppns_4", dut_g.l1.io_w_req_bits_data_1_entries_ppns_4, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_ppns_4);
    chk("l1.io_w_req_bits_data_1_entries_ppns_5", dut_g.l1.io_w_req_bits_data_1_entries_ppns_5, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_ppns_5);
    chk("l1.io_w_req_bits_data_1_entries_ppns_6", dut_g.l1.io_w_req_bits_data_1_entries_ppns_6, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_ppns_6);
    chk("l1.io_w_req_bits_data_1_entries_ppns_7", dut_g.l1.io_w_req_bits_data_1_entries_ppns_7, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_ppns_7);
    chk("l1.io_w_req_bits_data_1_entries_vs_0", dut_g.l1.io_w_req_bits_data_1_entries_vs_0, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vs_0);
    chk("l1.io_w_req_bits_data_1_entries_vs_1", dut_g.l1.io_w_req_bits_data_1_entries_vs_1, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vs_1);
    chk("l1.io_w_req_bits_data_1_entries_vs_2", dut_g.l1.io_w_req_bits_data_1_entries_vs_2, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vs_2);
    chk("l1.io_w_req_bits_data_1_entries_vs_3", dut_g.l1.io_w_req_bits_data_1_entries_vs_3, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vs_3);
    chk("l1.io_w_req_bits_data_1_entries_vs_4", dut_g.l1.io_w_req_bits_data_1_entries_vs_4, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vs_4);
    chk("l1.io_w_req_bits_data_1_entries_vs_5", dut_g.l1.io_w_req_bits_data_1_entries_vs_5, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vs_5);
    chk("l1.io_w_req_bits_data_1_entries_vs_6", dut_g.l1.io_w_req_bits_data_1_entries_vs_6, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vs_6);
    chk("l1.io_w_req_bits_data_1_entries_vs_7", dut_g.l1.io_w_req_bits_data_1_entries_vs_7, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vs_7);
    chk("l1.io_w_req_bits_data_1_entries_prefetch", dut_g.l1.io_w_req_bits_data_1_entries_prefetch, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_prefetch);
    chk("l1.io_w_req_bits_waymask", dut_g.l1.io_w_req_bits_waymask, dut_i.u_core.u_l1_sram.io_w_req_bits_waymask);
    chk("l0.io_w_req_valid", dut_g.l0.io_w_req_valid, dut_i.u_core.u_l0_sram.io_w_req_valid);
    chk("l0.io_w_req_bits_setIdx", dut_g.l0.io_w_req_bits_setIdx, dut_i.u_core.u_l0_sram.io_w_req_bits_setIdx);
    chk("l0.io_w_req_bits_data_0_entries_tag", dut_g.l0.io_w_req_bits_data_0_entries_tag, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_tag);
    chk("l0.io_w_req_bits_data_0_entries_asid", dut_g.l0.io_w_req_bits_data_0_entries_asid, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_asid);
    chk("l0.io_w_req_bits_data_0_entries_vmid", dut_g.l0.io_w_req_bits_data_0_entries_vmid, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vmid);
    chk("l0.io_w_req_bits_data_0_entries_pbmts_0", dut_g.l0.io_w_req_bits_data_0_entries_pbmts_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_pbmts_0);
    chk("l0.io_w_req_bits_data_0_entries_pbmts_1", dut_g.l0.io_w_req_bits_data_0_entries_pbmts_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_pbmts_1);
    chk("l0.io_w_req_bits_data_0_entries_pbmts_2", dut_g.l0.io_w_req_bits_data_0_entries_pbmts_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_pbmts_2);
    chk("l0.io_w_req_bits_data_0_entries_pbmts_3", dut_g.l0.io_w_req_bits_data_0_entries_pbmts_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_pbmts_3);
    chk("l0.io_w_req_bits_data_0_entries_pbmts_4", dut_g.l0.io_w_req_bits_data_0_entries_pbmts_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_pbmts_4);
    chk("l0.io_w_req_bits_data_0_entries_pbmts_5", dut_g.l0.io_w_req_bits_data_0_entries_pbmts_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_pbmts_5);
    chk("l0.io_w_req_bits_data_0_entries_pbmts_6", dut_g.l0.io_w_req_bits_data_0_entries_pbmts_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_pbmts_6);
    chk("l0.io_w_req_bits_data_0_entries_pbmts_7", dut_g.l0.io_w_req_bits_data_0_entries_pbmts_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_pbmts_7);
    chk("l0.io_w_req_bits_data_0_entries_ppns_0", dut_g.l0.io_w_req_bits_data_0_entries_ppns_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_ppns_0);
    chk("l0.io_w_req_bits_data_0_entries_ppns_1", dut_g.l0.io_w_req_bits_data_0_entries_ppns_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_ppns_1);
    chk("l0.io_w_req_bits_data_0_entries_ppns_2", dut_g.l0.io_w_req_bits_data_0_entries_ppns_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_ppns_2);
    chk("l0.io_w_req_bits_data_0_entries_ppns_3", dut_g.l0.io_w_req_bits_data_0_entries_ppns_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_ppns_3);
    chk("l0.io_w_req_bits_data_0_entries_ppns_4", dut_g.l0.io_w_req_bits_data_0_entries_ppns_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_ppns_4);
    chk("l0.io_w_req_bits_data_0_entries_ppns_5", dut_g.l0.io_w_req_bits_data_0_entries_ppns_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_ppns_5);
    chk("l0.io_w_req_bits_data_0_entries_ppns_6", dut_g.l0.io_w_req_bits_data_0_entries_ppns_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_ppns_6);
    chk("l0.io_w_req_bits_data_0_entries_ppns_7", dut_g.l0.io_w_req_bits_data_0_entries_ppns_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_ppns_7);
    chk("l0.io_w_req_bits_data_0_entries_vs_0", dut_g.l0.io_w_req_bits_data_0_entries_vs_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vs_0);
    chk("l0.io_w_req_bits_data_0_entries_vs_1", dut_g.l0.io_w_req_bits_data_0_entries_vs_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vs_1);
    chk("l0.io_w_req_bits_data_0_entries_vs_2", dut_g.l0.io_w_req_bits_data_0_entries_vs_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vs_2);
    chk("l0.io_w_req_bits_data_0_entries_vs_3", dut_g.l0.io_w_req_bits_data_0_entries_vs_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vs_3);
    chk("l0.io_w_req_bits_data_0_entries_vs_4", dut_g.l0.io_w_req_bits_data_0_entries_vs_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vs_4);
    chk("l0.io_w_req_bits_data_0_entries_vs_5", dut_g.l0.io_w_req_bits_data_0_entries_vs_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vs_5);
    chk("l0.io_w_req_bits_data_0_entries_vs_6", dut_g.l0.io_w_req_bits_data_0_entries_vs_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vs_6);
    chk("l0.io_w_req_bits_data_0_entries_vs_7", dut_g.l0.io_w_req_bits_data_0_entries_vs_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vs_7);
    chk("l0.io_w_req_bits_data_0_entries_onlypf_0", dut_g.l0.io_w_req_bits_data_0_entries_onlypf_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_onlypf_0);
    chk("l0.io_w_req_bits_data_0_entries_onlypf_1", dut_g.l0.io_w_req_bits_data_0_entries_onlypf_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_onlypf_1);
    chk("l0.io_w_req_bits_data_0_entries_onlypf_2", dut_g.l0.io_w_req_bits_data_0_entries_onlypf_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_onlypf_2);
    chk("l0.io_w_req_bits_data_0_entries_onlypf_3", dut_g.l0.io_w_req_bits_data_0_entries_onlypf_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_onlypf_3);
    chk("l0.io_w_req_bits_data_0_entries_onlypf_4", dut_g.l0.io_w_req_bits_data_0_entries_onlypf_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_onlypf_4);
    chk("l0.io_w_req_bits_data_0_entries_onlypf_5", dut_g.l0.io_w_req_bits_data_0_entries_onlypf_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_onlypf_5);
    chk("l0.io_w_req_bits_data_0_entries_onlypf_6", dut_g.l0.io_w_req_bits_data_0_entries_onlypf_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_onlypf_6);
    chk("l0.io_w_req_bits_data_0_entries_onlypf_7", dut_g.l0.io_w_req_bits_data_0_entries_onlypf_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_onlypf_7);
    chk("l0.io_w_req_bits_data_0_entries_perms_0_d", dut_g.l0.io_w_req_bits_data_0_entries_perms_0_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_0_d);
    chk("l0.io_w_req_bits_data_0_entries_perms_0_a", dut_g.l0.io_w_req_bits_data_0_entries_perms_0_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_0_a);
    chk("l0.io_w_req_bits_data_0_entries_perms_0_g", dut_g.l0.io_w_req_bits_data_0_entries_perms_0_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_0_g);
    chk("l0.io_w_req_bits_data_0_entries_perms_0_u", dut_g.l0.io_w_req_bits_data_0_entries_perms_0_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_0_u);
    chk("l0.io_w_req_bits_data_0_entries_perms_0_x", dut_g.l0.io_w_req_bits_data_0_entries_perms_0_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_0_x);
    chk("l0.io_w_req_bits_data_0_entries_perms_0_w", dut_g.l0.io_w_req_bits_data_0_entries_perms_0_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_0_w);
    chk("l0.io_w_req_bits_data_0_entries_perms_0_r", dut_g.l0.io_w_req_bits_data_0_entries_perms_0_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_0_r);
    chk("l0.io_w_req_bits_data_0_entries_perms_1_d", dut_g.l0.io_w_req_bits_data_0_entries_perms_1_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_1_d);
    chk("l0.io_w_req_bits_data_0_entries_perms_1_a", dut_g.l0.io_w_req_bits_data_0_entries_perms_1_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_1_a);
    chk("l0.io_w_req_bits_data_0_entries_perms_1_g", dut_g.l0.io_w_req_bits_data_0_entries_perms_1_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_1_g);
    chk("l0.io_w_req_bits_data_0_entries_perms_1_u", dut_g.l0.io_w_req_bits_data_0_entries_perms_1_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_1_u);
    chk("l0.io_w_req_bits_data_0_entries_perms_1_x", dut_g.l0.io_w_req_bits_data_0_entries_perms_1_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_1_x);
    chk("l0.io_w_req_bits_data_0_entries_perms_1_w", dut_g.l0.io_w_req_bits_data_0_entries_perms_1_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_1_w);
    chk("l0.io_w_req_bits_data_0_entries_perms_1_r", dut_g.l0.io_w_req_bits_data_0_entries_perms_1_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_1_r);
    chk("l0.io_w_req_bits_data_0_entries_perms_2_d", dut_g.l0.io_w_req_bits_data_0_entries_perms_2_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_2_d);
    chk("l0.io_w_req_bits_data_0_entries_perms_2_a", dut_g.l0.io_w_req_bits_data_0_entries_perms_2_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_2_a);
    chk("l0.io_w_req_bits_data_0_entries_perms_2_g", dut_g.l0.io_w_req_bits_data_0_entries_perms_2_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_2_g);
    chk("l0.io_w_req_bits_data_0_entries_perms_2_u", dut_g.l0.io_w_req_bits_data_0_entries_perms_2_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_2_u);
    chk("l0.io_w_req_bits_data_0_entries_perms_2_x", dut_g.l0.io_w_req_bits_data_0_entries_perms_2_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_2_x);
    chk("l0.io_w_req_bits_data_0_entries_perms_2_w", dut_g.l0.io_w_req_bits_data_0_entries_perms_2_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_2_w);
    chk("l0.io_w_req_bits_data_0_entries_perms_2_r", dut_g.l0.io_w_req_bits_data_0_entries_perms_2_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_2_r);
    chk("l0.io_w_req_bits_data_0_entries_perms_3_d", dut_g.l0.io_w_req_bits_data_0_entries_perms_3_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_3_d);
    chk("l0.io_w_req_bits_data_0_entries_perms_3_a", dut_g.l0.io_w_req_bits_data_0_entries_perms_3_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_3_a);
    chk("l0.io_w_req_bits_data_0_entries_perms_3_g", dut_g.l0.io_w_req_bits_data_0_entries_perms_3_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_3_g);
    chk("l0.io_w_req_bits_data_0_entries_perms_3_u", dut_g.l0.io_w_req_bits_data_0_entries_perms_3_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_3_u);
    chk("l0.io_w_req_bits_data_0_entries_perms_3_x", dut_g.l0.io_w_req_bits_data_0_entries_perms_3_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_3_x);
    chk("l0.io_w_req_bits_data_0_entries_perms_3_w", dut_g.l0.io_w_req_bits_data_0_entries_perms_3_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_3_w);
    chk("l0.io_w_req_bits_data_0_entries_perms_3_r", dut_g.l0.io_w_req_bits_data_0_entries_perms_3_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_3_r);
    chk("l0.io_w_req_bits_data_0_entries_perms_4_d", dut_g.l0.io_w_req_bits_data_0_entries_perms_4_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_4_d);
    chk("l0.io_w_req_bits_data_0_entries_perms_4_a", dut_g.l0.io_w_req_bits_data_0_entries_perms_4_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_4_a);
    chk("l0.io_w_req_bits_data_0_entries_perms_4_g", dut_g.l0.io_w_req_bits_data_0_entries_perms_4_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_4_g);
    chk("l0.io_w_req_bits_data_0_entries_perms_4_u", dut_g.l0.io_w_req_bits_data_0_entries_perms_4_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_4_u);
    chk("l0.io_w_req_bits_data_0_entries_perms_4_x", dut_g.l0.io_w_req_bits_data_0_entries_perms_4_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_4_x);
    chk("l0.io_w_req_bits_data_0_entries_perms_4_w", dut_g.l0.io_w_req_bits_data_0_entries_perms_4_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_4_w);
    chk("l0.io_w_req_bits_data_0_entries_perms_4_r", dut_g.l0.io_w_req_bits_data_0_entries_perms_4_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_4_r);
    chk("l0.io_w_req_bits_data_0_entries_perms_5_d", dut_g.l0.io_w_req_bits_data_0_entries_perms_5_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_5_d);
    chk("l0.io_w_req_bits_data_0_entries_perms_5_a", dut_g.l0.io_w_req_bits_data_0_entries_perms_5_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_5_a);
    chk("l0.io_w_req_bits_data_0_entries_perms_5_g", dut_g.l0.io_w_req_bits_data_0_entries_perms_5_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_5_g);
    chk("l0.io_w_req_bits_data_0_entries_perms_5_u", dut_g.l0.io_w_req_bits_data_0_entries_perms_5_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_5_u);
    chk("l0.io_w_req_bits_data_0_entries_perms_5_x", dut_g.l0.io_w_req_bits_data_0_entries_perms_5_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_5_x);
    chk("l0.io_w_req_bits_data_0_entries_perms_5_w", dut_g.l0.io_w_req_bits_data_0_entries_perms_5_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_5_w);
    chk("l0.io_w_req_bits_data_0_entries_perms_5_r", dut_g.l0.io_w_req_bits_data_0_entries_perms_5_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_5_r);
    chk("l0.io_w_req_bits_data_0_entries_perms_6_d", dut_g.l0.io_w_req_bits_data_0_entries_perms_6_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_6_d);
    chk("l0.io_w_req_bits_data_0_entries_perms_6_a", dut_g.l0.io_w_req_bits_data_0_entries_perms_6_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_6_a);
    chk("l0.io_w_req_bits_data_0_entries_perms_6_g", dut_g.l0.io_w_req_bits_data_0_entries_perms_6_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_6_g);
    chk("l0.io_w_req_bits_data_0_entries_perms_6_u", dut_g.l0.io_w_req_bits_data_0_entries_perms_6_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_6_u);
    chk("l0.io_w_req_bits_data_0_entries_perms_6_x", dut_g.l0.io_w_req_bits_data_0_entries_perms_6_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_6_x);
    chk("l0.io_w_req_bits_data_0_entries_perms_6_w", dut_g.l0.io_w_req_bits_data_0_entries_perms_6_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_6_w);
    chk("l0.io_w_req_bits_data_0_entries_perms_6_r", dut_g.l0.io_w_req_bits_data_0_entries_perms_6_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_6_r);
    chk("l0.io_w_req_bits_data_0_entries_perms_7_d", dut_g.l0.io_w_req_bits_data_0_entries_perms_7_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_7_d);
    chk("l0.io_w_req_bits_data_0_entries_perms_7_a", dut_g.l0.io_w_req_bits_data_0_entries_perms_7_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_7_a);
    chk("l0.io_w_req_bits_data_0_entries_perms_7_g", dut_g.l0.io_w_req_bits_data_0_entries_perms_7_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_7_g);
    chk("l0.io_w_req_bits_data_0_entries_perms_7_u", dut_g.l0.io_w_req_bits_data_0_entries_perms_7_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_7_u);
    chk("l0.io_w_req_bits_data_0_entries_perms_7_x", dut_g.l0.io_w_req_bits_data_0_entries_perms_7_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_7_x);
    chk("l0.io_w_req_bits_data_0_entries_perms_7_w", dut_g.l0.io_w_req_bits_data_0_entries_perms_7_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_7_w);
    chk("l0.io_w_req_bits_data_0_entries_perms_7_r", dut_g.l0.io_w_req_bits_data_0_entries_perms_7_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_7_r);
    chk("l0.io_w_req_bits_data_0_entries_prefetch", dut_g.l0.io_w_req_bits_data_0_entries_prefetch, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_prefetch);
    chk("l0.io_w_req_bits_data_1_entries_tag", dut_g.l0.io_w_req_bits_data_1_entries_tag, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_tag);
    chk("l0.io_w_req_bits_data_1_entries_asid", dut_g.l0.io_w_req_bits_data_1_entries_asid, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_asid);
    chk("l0.io_w_req_bits_data_1_entries_vmid", dut_g.l0.io_w_req_bits_data_1_entries_vmid, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vmid);
    chk("l0.io_w_req_bits_data_1_entries_pbmts_0", dut_g.l0.io_w_req_bits_data_1_entries_pbmts_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_pbmts_0);
    chk("l0.io_w_req_bits_data_1_entries_pbmts_1", dut_g.l0.io_w_req_bits_data_1_entries_pbmts_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_pbmts_1);
    chk("l0.io_w_req_bits_data_1_entries_pbmts_2", dut_g.l0.io_w_req_bits_data_1_entries_pbmts_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_pbmts_2);
    chk("l0.io_w_req_bits_data_1_entries_pbmts_3", dut_g.l0.io_w_req_bits_data_1_entries_pbmts_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_pbmts_3);
    chk("l0.io_w_req_bits_data_1_entries_pbmts_4", dut_g.l0.io_w_req_bits_data_1_entries_pbmts_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_pbmts_4);
    chk("l0.io_w_req_bits_data_1_entries_pbmts_5", dut_g.l0.io_w_req_bits_data_1_entries_pbmts_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_pbmts_5);
    chk("l0.io_w_req_bits_data_1_entries_pbmts_6", dut_g.l0.io_w_req_bits_data_1_entries_pbmts_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_pbmts_6);
    chk("l0.io_w_req_bits_data_1_entries_pbmts_7", dut_g.l0.io_w_req_bits_data_1_entries_pbmts_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_pbmts_7);
    chk("l0.io_w_req_bits_data_1_entries_ppns_0", dut_g.l0.io_w_req_bits_data_1_entries_ppns_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_ppns_0);
    chk("l0.io_w_req_bits_data_1_entries_ppns_1", dut_g.l0.io_w_req_bits_data_1_entries_ppns_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_ppns_1);
    chk("l0.io_w_req_bits_data_1_entries_ppns_2", dut_g.l0.io_w_req_bits_data_1_entries_ppns_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_ppns_2);
    chk("l0.io_w_req_bits_data_1_entries_ppns_3", dut_g.l0.io_w_req_bits_data_1_entries_ppns_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_ppns_3);
    chk("l0.io_w_req_bits_data_1_entries_ppns_4", dut_g.l0.io_w_req_bits_data_1_entries_ppns_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_ppns_4);
    chk("l0.io_w_req_bits_data_1_entries_ppns_5", dut_g.l0.io_w_req_bits_data_1_entries_ppns_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_ppns_5);
    chk("l0.io_w_req_bits_data_1_entries_ppns_6", dut_g.l0.io_w_req_bits_data_1_entries_ppns_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_ppns_6);
    chk("l0.io_w_req_bits_data_1_entries_ppns_7", dut_g.l0.io_w_req_bits_data_1_entries_ppns_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_ppns_7);
    chk("l0.io_w_req_bits_data_1_entries_vs_0", dut_g.l0.io_w_req_bits_data_1_entries_vs_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vs_0);
    chk("l0.io_w_req_bits_data_1_entries_vs_1", dut_g.l0.io_w_req_bits_data_1_entries_vs_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vs_1);
    chk("l0.io_w_req_bits_data_1_entries_vs_2", dut_g.l0.io_w_req_bits_data_1_entries_vs_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vs_2);
    chk("l0.io_w_req_bits_data_1_entries_vs_3", dut_g.l0.io_w_req_bits_data_1_entries_vs_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vs_3);
    chk("l0.io_w_req_bits_data_1_entries_vs_4", dut_g.l0.io_w_req_bits_data_1_entries_vs_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vs_4);
    chk("l0.io_w_req_bits_data_1_entries_vs_5", dut_g.l0.io_w_req_bits_data_1_entries_vs_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vs_5);
    chk("l0.io_w_req_bits_data_1_entries_vs_6", dut_g.l0.io_w_req_bits_data_1_entries_vs_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vs_6);
    chk("l0.io_w_req_bits_data_1_entries_vs_7", dut_g.l0.io_w_req_bits_data_1_entries_vs_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vs_7);
    chk("l0.io_w_req_bits_data_1_entries_onlypf_0", dut_g.l0.io_w_req_bits_data_1_entries_onlypf_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_onlypf_0);
    chk("l0.io_w_req_bits_data_1_entries_onlypf_1", dut_g.l0.io_w_req_bits_data_1_entries_onlypf_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_onlypf_1);
    chk("l0.io_w_req_bits_data_1_entries_onlypf_2", dut_g.l0.io_w_req_bits_data_1_entries_onlypf_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_onlypf_2);
    chk("l0.io_w_req_bits_data_1_entries_onlypf_3", dut_g.l0.io_w_req_bits_data_1_entries_onlypf_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_onlypf_3);
    chk("l0.io_w_req_bits_data_1_entries_onlypf_4", dut_g.l0.io_w_req_bits_data_1_entries_onlypf_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_onlypf_4);
    chk("l0.io_w_req_bits_data_1_entries_onlypf_5", dut_g.l0.io_w_req_bits_data_1_entries_onlypf_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_onlypf_5);
    chk("l0.io_w_req_bits_data_1_entries_onlypf_6", dut_g.l0.io_w_req_bits_data_1_entries_onlypf_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_onlypf_6);
    chk("l0.io_w_req_bits_data_1_entries_onlypf_7", dut_g.l0.io_w_req_bits_data_1_entries_onlypf_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_onlypf_7);
    chk("l0.io_w_req_bits_data_1_entries_perms_0_d", dut_g.l0.io_w_req_bits_data_1_entries_perms_0_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_0_d);
    chk("l0.io_w_req_bits_data_1_entries_perms_0_a", dut_g.l0.io_w_req_bits_data_1_entries_perms_0_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_0_a);
    chk("l0.io_w_req_bits_data_1_entries_perms_0_g", dut_g.l0.io_w_req_bits_data_1_entries_perms_0_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_0_g);
    chk("l0.io_w_req_bits_data_1_entries_perms_0_u", dut_g.l0.io_w_req_bits_data_1_entries_perms_0_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_0_u);
    chk("l0.io_w_req_bits_data_1_entries_perms_0_x", dut_g.l0.io_w_req_bits_data_1_entries_perms_0_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_0_x);
    chk("l0.io_w_req_bits_data_1_entries_perms_0_w", dut_g.l0.io_w_req_bits_data_1_entries_perms_0_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_0_w);
    chk("l0.io_w_req_bits_data_1_entries_perms_0_r", dut_g.l0.io_w_req_bits_data_1_entries_perms_0_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_0_r);
    chk("l0.io_w_req_bits_data_1_entries_perms_1_d", dut_g.l0.io_w_req_bits_data_1_entries_perms_1_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_1_d);
    chk("l0.io_w_req_bits_data_1_entries_perms_1_a", dut_g.l0.io_w_req_bits_data_1_entries_perms_1_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_1_a);
    chk("l0.io_w_req_bits_data_1_entries_perms_1_g", dut_g.l0.io_w_req_bits_data_1_entries_perms_1_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_1_g);
    chk("l0.io_w_req_bits_data_1_entries_perms_1_u", dut_g.l0.io_w_req_bits_data_1_entries_perms_1_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_1_u);
    chk("l0.io_w_req_bits_data_1_entries_perms_1_x", dut_g.l0.io_w_req_bits_data_1_entries_perms_1_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_1_x);
    chk("l0.io_w_req_bits_data_1_entries_perms_1_w", dut_g.l0.io_w_req_bits_data_1_entries_perms_1_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_1_w);
    chk("l0.io_w_req_bits_data_1_entries_perms_1_r", dut_g.l0.io_w_req_bits_data_1_entries_perms_1_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_1_r);
    chk("l0.io_w_req_bits_data_1_entries_perms_2_d", dut_g.l0.io_w_req_bits_data_1_entries_perms_2_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_2_d);
    chk("l0.io_w_req_bits_data_1_entries_perms_2_a", dut_g.l0.io_w_req_bits_data_1_entries_perms_2_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_2_a);
    chk("l0.io_w_req_bits_data_1_entries_perms_2_g", dut_g.l0.io_w_req_bits_data_1_entries_perms_2_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_2_g);
    chk("l0.io_w_req_bits_data_1_entries_perms_2_u", dut_g.l0.io_w_req_bits_data_1_entries_perms_2_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_2_u);
    chk("l0.io_w_req_bits_data_1_entries_perms_2_x", dut_g.l0.io_w_req_bits_data_1_entries_perms_2_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_2_x);
    chk("l0.io_w_req_bits_data_1_entries_perms_2_w", dut_g.l0.io_w_req_bits_data_1_entries_perms_2_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_2_w);
    chk("l0.io_w_req_bits_data_1_entries_perms_2_r", dut_g.l0.io_w_req_bits_data_1_entries_perms_2_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_2_r);
    chk("l0.io_w_req_bits_data_1_entries_perms_3_d", dut_g.l0.io_w_req_bits_data_1_entries_perms_3_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_3_d);
    chk("l0.io_w_req_bits_data_1_entries_perms_3_a", dut_g.l0.io_w_req_bits_data_1_entries_perms_3_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_3_a);
    chk("l0.io_w_req_bits_data_1_entries_perms_3_g", dut_g.l0.io_w_req_bits_data_1_entries_perms_3_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_3_g);
    chk("l0.io_w_req_bits_data_1_entries_perms_3_u", dut_g.l0.io_w_req_bits_data_1_entries_perms_3_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_3_u);
    chk("l0.io_w_req_bits_data_1_entries_perms_3_x", dut_g.l0.io_w_req_bits_data_1_entries_perms_3_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_3_x);
    chk("l0.io_w_req_bits_data_1_entries_perms_3_w", dut_g.l0.io_w_req_bits_data_1_entries_perms_3_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_3_w);
    chk("l0.io_w_req_bits_data_1_entries_perms_3_r", dut_g.l0.io_w_req_bits_data_1_entries_perms_3_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_3_r);
    chk("l0.io_w_req_bits_data_1_entries_perms_4_d", dut_g.l0.io_w_req_bits_data_1_entries_perms_4_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_4_d);
    chk("l0.io_w_req_bits_data_1_entries_perms_4_a", dut_g.l0.io_w_req_bits_data_1_entries_perms_4_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_4_a);
    chk("l0.io_w_req_bits_data_1_entries_perms_4_g", dut_g.l0.io_w_req_bits_data_1_entries_perms_4_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_4_g);
    chk("l0.io_w_req_bits_data_1_entries_perms_4_u", dut_g.l0.io_w_req_bits_data_1_entries_perms_4_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_4_u);
    chk("l0.io_w_req_bits_data_1_entries_perms_4_x", dut_g.l0.io_w_req_bits_data_1_entries_perms_4_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_4_x);
    chk("l0.io_w_req_bits_data_1_entries_perms_4_w", dut_g.l0.io_w_req_bits_data_1_entries_perms_4_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_4_w);
    chk("l0.io_w_req_bits_data_1_entries_perms_4_r", dut_g.l0.io_w_req_bits_data_1_entries_perms_4_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_4_r);
    chk("l0.io_w_req_bits_data_1_entries_perms_5_d", dut_g.l0.io_w_req_bits_data_1_entries_perms_5_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_5_d);
    chk("l0.io_w_req_bits_data_1_entries_perms_5_a", dut_g.l0.io_w_req_bits_data_1_entries_perms_5_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_5_a);
    chk("l0.io_w_req_bits_data_1_entries_perms_5_g", dut_g.l0.io_w_req_bits_data_1_entries_perms_5_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_5_g);
    chk("l0.io_w_req_bits_data_1_entries_perms_5_u", dut_g.l0.io_w_req_bits_data_1_entries_perms_5_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_5_u);
    chk("l0.io_w_req_bits_data_1_entries_perms_5_x", dut_g.l0.io_w_req_bits_data_1_entries_perms_5_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_5_x);
    chk("l0.io_w_req_bits_data_1_entries_perms_5_w", dut_g.l0.io_w_req_bits_data_1_entries_perms_5_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_5_w);
    chk("l0.io_w_req_bits_data_1_entries_perms_5_r", dut_g.l0.io_w_req_bits_data_1_entries_perms_5_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_5_r);
    chk("l0.io_w_req_bits_data_1_entries_perms_6_d", dut_g.l0.io_w_req_bits_data_1_entries_perms_6_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_6_d);
    chk("l0.io_w_req_bits_data_1_entries_perms_6_a", dut_g.l0.io_w_req_bits_data_1_entries_perms_6_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_6_a);
    chk("l0.io_w_req_bits_data_1_entries_perms_6_g", dut_g.l0.io_w_req_bits_data_1_entries_perms_6_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_6_g);
    chk("l0.io_w_req_bits_data_1_entries_perms_6_u", dut_g.l0.io_w_req_bits_data_1_entries_perms_6_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_6_u);
    chk("l0.io_w_req_bits_data_1_entries_perms_6_x", dut_g.l0.io_w_req_bits_data_1_entries_perms_6_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_6_x);
    chk("l0.io_w_req_bits_data_1_entries_perms_6_w", dut_g.l0.io_w_req_bits_data_1_entries_perms_6_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_6_w);
    chk("l0.io_w_req_bits_data_1_entries_perms_6_r", dut_g.l0.io_w_req_bits_data_1_entries_perms_6_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_6_r);
    chk("l0.io_w_req_bits_data_1_entries_perms_7_d", dut_g.l0.io_w_req_bits_data_1_entries_perms_7_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_7_d);
    chk("l0.io_w_req_bits_data_1_entries_perms_7_a", dut_g.l0.io_w_req_bits_data_1_entries_perms_7_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_7_a);
    chk("l0.io_w_req_bits_data_1_entries_perms_7_g", dut_g.l0.io_w_req_bits_data_1_entries_perms_7_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_7_g);
    chk("l0.io_w_req_bits_data_1_entries_perms_7_u", dut_g.l0.io_w_req_bits_data_1_entries_perms_7_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_7_u);
    chk("l0.io_w_req_bits_data_1_entries_perms_7_x", dut_g.l0.io_w_req_bits_data_1_entries_perms_7_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_7_x);
    chk("l0.io_w_req_bits_data_1_entries_perms_7_w", dut_g.l0.io_w_req_bits_data_1_entries_perms_7_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_7_w);
    chk("l0.io_w_req_bits_data_1_entries_perms_7_r", dut_g.l0.io_w_req_bits_data_1_entries_perms_7_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_7_r);
    chk("l0.io_w_req_bits_data_1_entries_prefetch", dut_g.l0.io_w_req_bits_data_1_entries_prefetch, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_prefetch);
    chk("l0.io_w_req_bits_data_2_entries_tag", dut_g.l0.io_w_req_bits_data_2_entries_tag, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_tag);
    chk("l0.io_w_req_bits_data_2_entries_asid", dut_g.l0.io_w_req_bits_data_2_entries_asid, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_asid);
    chk("l0.io_w_req_bits_data_2_entries_vmid", dut_g.l0.io_w_req_bits_data_2_entries_vmid, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vmid);
    chk("l0.io_w_req_bits_data_2_entries_pbmts_0", dut_g.l0.io_w_req_bits_data_2_entries_pbmts_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_pbmts_0);
    chk("l0.io_w_req_bits_data_2_entries_pbmts_1", dut_g.l0.io_w_req_bits_data_2_entries_pbmts_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_pbmts_1);
    chk("l0.io_w_req_bits_data_2_entries_pbmts_2", dut_g.l0.io_w_req_bits_data_2_entries_pbmts_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_pbmts_2);
    chk("l0.io_w_req_bits_data_2_entries_pbmts_3", dut_g.l0.io_w_req_bits_data_2_entries_pbmts_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_pbmts_3);
    chk("l0.io_w_req_bits_data_2_entries_pbmts_4", dut_g.l0.io_w_req_bits_data_2_entries_pbmts_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_pbmts_4);
    chk("l0.io_w_req_bits_data_2_entries_pbmts_5", dut_g.l0.io_w_req_bits_data_2_entries_pbmts_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_pbmts_5);
    chk("l0.io_w_req_bits_data_2_entries_pbmts_6", dut_g.l0.io_w_req_bits_data_2_entries_pbmts_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_pbmts_6);
    chk("l0.io_w_req_bits_data_2_entries_pbmts_7", dut_g.l0.io_w_req_bits_data_2_entries_pbmts_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_pbmts_7);
    chk("l0.io_w_req_bits_data_2_entries_ppns_0", dut_g.l0.io_w_req_bits_data_2_entries_ppns_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_ppns_0);
    chk("l0.io_w_req_bits_data_2_entries_ppns_1", dut_g.l0.io_w_req_bits_data_2_entries_ppns_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_ppns_1);
    chk("l0.io_w_req_bits_data_2_entries_ppns_2", dut_g.l0.io_w_req_bits_data_2_entries_ppns_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_ppns_2);
    chk("l0.io_w_req_bits_data_2_entries_ppns_3", dut_g.l0.io_w_req_bits_data_2_entries_ppns_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_ppns_3);
    chk("l0.io_w_req_bits_data_2_entries_ppns_4", dut_g.l0.io_w_req_bits_data_2_entries_ppns_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_ppns_4);
    chk("l0.io_w_req_bits_data_2_entries_ppns_5", dut_g.l0.io_w_req_bits_data_2_entries_ppns_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_ppns_5);
    chk("l0.io_w_req_bits_data_2_entries_ppns_6", dut_g.l0.io_w_req_bits_data_2_entries_ppns_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_ppns_6);
    chk("l0.io_w_req_bits_data_2_entries_ppns_7", dut_g.l0.io_w_req_bits_data_2_entries_ppns_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_ppns_7);
    chk("l0.io_w_req_bits_data_2_entries_vs_0", dut_g.l0.io_w_req_bits_data_2_entries_vs_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vs_0);
    chk("l0.io_w_req_bits_data_2_entries_vs_1", dut_g.l0.io_w_req_bits_data_2_entries_vs_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vs_1);
    chk("l0.io_w_req_bits_data_2_entries_vs_2", dut_g.l0.io_w_req_bits_data_2_entries_vs_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vs_2);
    chk("l0.io_w_req_bits_data_2_entries_vs_3", dut_g.l0.io_w_req_bits_data_2_entries_vs_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vs_3);
    chk("l0.io_w_req_bits_data_2_entries_vs_4", dut_g.l0.io_w_req_bits_data_2_entries_vs_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vs_4);
    chk("l0.io_w_req_bits_data_2_entries_vs_5", dut_g.l0.io_w_req_bits_data_2_entries_vs_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vs_5);
    chk("l0.io_w_req_bits_data_2_entries_vs_6", dut_g.l0.io_w_req_bits_data_2_entries_vs_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vs_6);
    chk("l0.io_w_req_bits_data_2_entries_vs_7", dut_g.l0.io_w_req_bits_data_2_entries_vs_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vs_7);
    chk("l0.io_w_req_bits_data_2_entries_onlypf_0", dut_g.l0.io_w_req_bits_data_2_entries_onlypf_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_onlypf_0);
    chk("l0.io_w_req_bits_data_2_entries_onlypf_1", dut_g.l0.io_w_req_bits_data_2_entries_onlypf_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_onlypf_1);
    chk("l0.io_w_req_bits_data_2_entries_onlypf_2", dut_g.l0.io_w_req_bits_data_2_entries_onlypf_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_onlypf_2);
    chk("l0.io_w_req_bits_data_2_entries_onlypf_3", dut_g.l0.io_w_req_bits_data_2_entries_onlypf_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_onlypf_3);
    chk("l0.io_w_req_bits_data_2_entries_onlypf_4", dut_g.l0.io_w_req_bits_data_2_entries_onlypf_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_onlypf_4);
    chk("l0.io_w_req_bits_data_2_entries_onlypf_5", dut_g.l0.io_w_req_bits_data_2_entries_onlypf_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_onlypf_5);
    chk("l0.io_w_req_bits_data_2_entries_onlypf_6", dut_g.l0.io_w_req_bits_data_2_entries_onlypf_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_onlypf_6);
    chk("l0.io_w_req_bits_data_2_entries_onlypf_7", dut_g.l0.io_w_req_bits_data_2_entries_onlypf_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_onlypf_7);
    chk("l0.io_w_req_bits_data_2_entries_perms_0_d", dut_g.l0.io_w_req_bits_data_2_entries_perms_0_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_0_d);
    chk("l0.io_w_req_bits_data_2_entries_perms_0_a", dut_g.l0.io_w_req_bits_data_2_entries_perms_0_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_0_a);
    chk("l0.io_w_req_bits_data_2_entries_perms_0_g", dut_g.l0.io_w_req_bits_data_2_entries_perms_0_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_0_g);
    chk("l0.io_w_req_bits_data_2_entries_perms_0_u", dut_g.l0.io_w_req_bits_data_2_entries_perms_0_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_0_u);
    chk("l0.io_w_req_bits_data_2_entries_perms_0_x", dut_g.l0.io_w_req_bits_data_2_entries_perms_0_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_0_x);
    chk("l0.io_w_req_bits_data_2_entries_perms_0_w", dut_g.l0.io_w_req_bits_data_2_entries_perms_0_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_0_w);
    chk("l0.io_w_req_bits_data_2_entries_perms_0_r", dut_g.l0.io_w_req_bits_data_2_entries_perms_0_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_0_r);
    chk("l0.io_w_req_bits_data_2_entries_perms_1_d", dut_g.l0.io_w_req_bits_data_2_entries_perms_1_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_1_d);
    chk("l0.io_w_req_bits_data_2_entries_perms_1_a", dut_g.l0.io_w_req_bits_data_2_entries_perms_1_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_1_a);
    chk("l0.io_w_req_bits_data_2_entries_perms_1_g", dut_g.l0.io_w_req_bits_data_2_entries_perms_1_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_1_g);
    chk("l0.io_w_req_bits_data_2_entries_perms_1_u", dut_g.l0.io_w_req_bits_data_2_entries_perms_1_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_1_u);
    chk("l0.io_w_req_bits_data_2_entries_perms_1_x", dut_g.l0.io_w_req_bits_data_2_entries_perms_1_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_1_x);
    chk("l0.io_w_req_bits_data_2_entries_perms_1_w", dut_g.l0.io_w_req_bits_data_2_entries_perms_1_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_1_w);
    chk("l0.io_w_req_bits_data_2_entries_perms_1_r", dut_g.l0.io_w_req_bits_data_2_entries_perms_1_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_1_r);
    chk("l0.io_w_req_bits_data_2_entries_perms_2_d", dut_g.l0.io_w_req_bits_data_2_entries_perms_2_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_2_d);
    chk("l0.io_w_req_bits_data_2_entries_perms_2_a", dut_g.l0.io_w_req_bits_data_2_entries_perms_2_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_2_a);
    chk("l0.io_w_req_bits_data_2_entries_perms_2_g", dut_g.l0.io_w_req_bits_data_2_entries_perms_2_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_2_g);
    chk("l0.io_w_req_bits_data_2_entries_perms_2_u", dut_g.l0.io_w_req_bits_data_2_entries_perms_2_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_2_u);
    chk("l0.io_w_req_bits_data_2_entries_perms_2_x", dut_g.l0.io_w_req_bits_data_2_entries_perms_2_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_2_x);
    chk("l0.io_w_req_bits_data_2_entries_perms_2_w", dut_g.l0.io_w_req_bits_data_2_entries_perms_2_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_2_w);
    chk("l0.io_w_req_bits_data_2_entries_perms_2_r", dut_g.l0.io_w_req_bits_data_2_entries_perms_2_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_2_r);
    chk("l0.io_w_req_bits_data_2_entries_perms_3_d", dut_g.l0.io_w_req_bits_data_2_entries_perms_3_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_3_d);
    chk("l0.io_w_req_bits_data_2_entries_perms_3_a", dut_g.l0.io_w_req_bits_data_2_entries_perms_3_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_3_a);
    chk("l0.io_w_req_bits_data_2_entries_perms_3_g", dut_g.l0.io_w_req_bits_data_2_entries_perms_3_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_3_g);
    chk("l0.io_w_req_bits_data_2_entries_perms_3_u", dut_g.l0.io_w_req_bits_data_2_entries_perms_3_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_3_u);
    chk("l0.io_w_req_bits_data_2_entries_perms_3_x", dut_g.l0.io_w_req_bits_data_2_entries_perms_3_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_3_x);
    chk("l0.io_w_req_bits_data_2_entries_perms_3_w", dut_g.l0.io_w_req_bits_data_2_entries_perms_3_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_3_w);
    chk("l0.io_w_req_bits_data_2_entries_perms_3_r", dut_g.l0.io_w_req_bits_data_2_entries_perms_3_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_3_r);
    chk("l0.io_w_req_bits_data_2_entries_perms_4_d", dut_g.l0.io_w_req_bits_data_2_entries_perms_4_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_4_d);
    chk("l0.io_w_req_bits_data_2_entries_perms_4_a", dut_g.l0.io_w_req_bits_data_2_entries_perms_4_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_4_a);
    chk("l0.io_w_req_bits_data_2_entries_perms_4_g", dut_g.l0.io_w_req_bits_data_2_entries_perms_4_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_4_g);
    chk("l0.io_w_req_bits_data_2_entries_perms_4_u", dut_g.l0.io_w_req_bits_data_2_entries_perms_4_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_4_u);
    chk("l0.io_w_req_bits_data_2_entries_perms_4_x", dut_g.l0.io_w_req_bits_data_2_entries_perms_4_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_4_x);
    chk("l0.io_w_req_bits_data_2_entries_perms_4_w", dut_g.l0.io_w_req_bits_data_2_entries_perms_4_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_4_w);
    chk("l0.io_w_req_bits_data_2_entries_perms_4_r", dut_g.l0.io_w_req_bits_data_2_entries_perms_4_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_4_r);
    chk("l0.io_w_req_bits_data_2_entries_perms_5_d", dut_g.l0.io_w_req_bits_data_2_entries_perms_5_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_5_d);
    chk("l0.io_w_req_bits_data_2_entries_perms_5_a", dut_g.l0.io_w_req_bits_data_2_entries_perms_5_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_5_a);
    chk("l0.io_w_req_bits_data_2_entries_perms_5_g", dut_g.l0.io_w_req_bits_data_2_entries_perms_5_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_5_g);
    chk("l0.io_w_req_bits_data_2_entries_perms_5_u", dut_g.l0.io_w_req_bits_data_2_entries_perms_5_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_5_u);
    chk("l0.io_w_req_bits_data_2_entries_perms_5_x", dut_g.l0.io_w_req_bits_data_2_entries_perms_5_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_5_x);
    chk("l0.io_w_req_bits_data_2_entries_perms_5_w", dut_g.l0.io_w_req_bits_data_2_entries_perms_5_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_5_w);
    chk("l0.io_w_req_bits_data_2_entries_perms_5_r", dut_g.l0.io_w_req_bits_data_2_entries_perms_5_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_5_r);
    chk("l0.io_w_req_bits_data_2_entries_perms_6_d", dut_g.l0.io_w_req_bits_data_2_entries_perms_6_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_6_d);
    chk("l0.io_w_req_bits_data_2_entries_perms_6_a", dut_g.l0.io_w_req_bits_data_2_entries_perms_6_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_6_a);
    chk("l0.io_w_req_bits_data_2_entries_perms_6_g", dut_g.l0.io_w_req_bits_data_2_entries_perms_6_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_6_g);
    chk("l0.io_w_req_bits_data_2_entries_perms_6_u", dut_g.l0.io_w_req_bits_data_2_entries_perms_6_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_6_u);
    chk("l0.io_w_req_bits_data_2_entries_perms_6_x", dut_g.l0.io_w_req_bits_data_2_entries_perms_6_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_6_x);
    chk("l0.io_w_req_bits_data_2_entries_perms_6_w", dut_g.l0.io_w_req_bits_data_2_entries_perms_6_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_6_w);
    chk("l0.io_w_req_bits_data_2_entries_perms_6_r", dut_g.l0.io_w_req_bits_data_2_entries_perms_6_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_6_r);
    chk("l0.io_w_req_bits_data_2_entries_perms_7_d", dut_g.l0.io_w_req_bits_data_2_entries_perms_7_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_7_d);
    chk("l0.io_w_req_bits_data_2_entries_perms_7_a", dut_g.l0.io_w_req_bits_data_2_entries_perms_7_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_7_a);
    chk("l0.io_w_req_bits_data_2_entries_perms_7_g", dut_g.l0.io_w_req_bits_data_2_entries_perms_7_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_7_g);
    chk("l0.io_w_req_bits_data_2_entries_perms_7_u", dut_g.l0.io_w_req_bits_data_2_entries_perms_7_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_7_u);
    chk("l0.io_w_req_bits_data_2_entries_perms_7_x", dut_g.l0.io_w_req_bits_data_2_entries_perms_7_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_7_x);
    chk("l0.io_w_req_bits_data_2_entries_perms_7_w", dut_g.l0.io_w_req_bits_data_2_entries_perms_7_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_7_w);
    chk("l0.io_w_req_bits_data_2_entries_perms_7_r", dut_g.l0.io_w_req_bits_data_2_entries_perms_7_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_7_r);
    chk("l0.io_w_req_bits_data_2_entries_prefetch", dut_g.l0.io_w_req_bits_data_2_entries_prefetch, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_prefetch);
    chk("l0.io_w_req_bits_data_3_entries_tag", dut_g.l0.io_w_req_bits_data_3_entries_tag, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_tag);
    chk("l0.io_w_req_bits_data_3_entries_asid", dut_g.l0.io_w_req_bits_data_3_entries_asid, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_asid);
    chk("l0.io_w_req_bits_data_3_entries_vmid", dut_g.l0.io_w_req_bits_data_3_entries_vmid, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vmid);
    chk("l0.io_w_req_bits_data_3_entries_pbmts_0", dut_g.l0.io_w_req_bits_data_3_entries_pbmts_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_pbmts_0);
    chk("l0.io_w_req_bits_data_3_entries_pbmts_1", dut_g.l0.io_w_req_bits_data_3_entries_pbmts_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_pbmts_1);
    chk("l0.io_w_req_bits_data_3_entries_pbmts_2", dut_g.l0.io_w_req_bits_data_3_entries_pbmts_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_pbmts_2);
    chk("l0.io_w_req_bits_data_3_entries_pbmts_3", dut_g.l0.io_w_req_bits_data_3_entries_pbmts_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_pbmts_3);
    chk("l0.io_w_req_bits_data_3_entries_pbmts_4", dut_g.l0.io_w_req_bits_data_3_entries_pbmts_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_pbmts_4);
    chk("l0.io_w_req_bits_data_3_entries_pbmts_5", dut_g.l0.io_w_req_bits_data_3_entries_pbmts_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_pbmts_5);
    chk("l0.io_w_req_bits_data_3_entries_pbmts_6", dut_g.l0.io_w_req_bits_data_3_entries_pbmts_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_pbmts_6);
    chk("l0.io_w_req_bits_data_3_entries_pbmts_7", dut_g.l0.io_w_req_bits_data_3_entries_pbmts_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_pbmts_7);
    chk("l0.io_w_req_bits_data_3_entries_ppns_0", dut_g.l0.io_w_req_bits_data_3_entries_ppns_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_ppns_0);
    chk("l0.io_w_req_bits_data_3_entries_ppns_1", dut_g.l0.io_w_req_bits_data_3_entries_ppns_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_ppns_1);
    chk("l0.io_w_req_bits_data_3_entries_ppns_2", dut_g.l0.io_w_req_bits_data_3_entries_ppns_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_ppns_2);
    chk("l0.io_w_req_bits_data_3_entries_ppns_3", dut_g.l0.io_w_req_bits_data_3_entries_ppns_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_ppns_3);
    chk("l0.io_w_req_bits_data_3_entries_ppns_4", dut_g.l0.io_w_req_bits_data_3_entries_ppns_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_ppns_4);
    chk("l0.io_w_req_bits_data_3_entries_ppns_5", dut_g.l0.io_w_req_bits_data_3_entries_ppns_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_ppns_5);
    chk("l0.io_w_req_bits_data_3_entries_ppns_6", dut_g.l0.io_w_req_bits_data_3_entries_ppns_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_ppns_6);
    chk("l0.io_w_req_bits_data_3_entries_ppns_7", dut_g.l0.io_w_req_bits_data_3_entries_ppns_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_ppns_7);
    chk("l0.io_w_req_bits_data_3_entries_vs_0", dut_g.l0.io_w_req_bits_data_3_entries_vs_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vs_0);
    chk("l0.io_w_req_bits_data_3_entries_vs_1", dut_g.l0.io_w_req_bits_data_3_entries_vs_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vs_1);
    chk("l0.io_w_req_bits_data_3_entries_vs_2", dut_g.l0.io_w_req_bits_data_3_entries_vs_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vs_2);
    chk("l0.io_w_req_bits_data_3_entries_vs_3", dut_g.l0.io_w_req_bits_data_3_entries_vs_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vs_3);
    chk("l0.io_w_req_bits_data_3_entries_vs_4", dut_g.l0.io_w_req_bits_data_3_entries_vs_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vs_4);
    chk("l0.io_w_req_bits_data_3_entries_vs_5", dut_g.l0.io_w_req_bits_data_3_entries_vs_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vs_5);
    chk("l0.io_w_req_bits_data_3_entries_vs_6", dut_g.l0.io_w_req_bits_data_3_entries_vs_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vs_6);
    chk("l0.io_w_req_bits_data_3_entries_vs_7", dut_g.l0.io_w_req_bits_data_3_entries_vs_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vs_7);
    chk("l0.io_w_req_bits_data_3_entries_onlypf_0", dut_g.l0.io_w_req_bits_data_3_entries_onlypf_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_onlypf_0);
    chk("l0.io_w_req_bits_data_3_entries_onlypf_1", dut_g.l0.io_w_req_bits_data_3_entries_onlypf_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_onlypf_1);
    chk("l0.io_w_req_bits_data_3_entries_onlypf_2", dut_g.l0.io_w_req_bits_data_3_entries_onlypf_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_onlypf_2);
    chk("l0.io_w_req_bits_data_3_entries_onlypf_3", dut_g.l0.io_w_req_bits_data_3_entries_onlypf_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_onlypf_3);
    chk("l0.io_w_req_bits_data_3_entries_onlypf_4", dut_g.l0.io_w_req_bits_data_3_entries_onlypf_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_onlypf_4);
    chk("l0.io_w_req_bits_data_3_entries_onlypf_5", dut_g.l0.io_w_req_bits_data_3_entries_onlypf_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_onlypf_5);
    chk("l0.io_w_req_bits_data_3_entries_onlypf_6", dut_g.l0.io_w_req_bits_data_3_entries_onlypf_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_onlypf_6);
    chk("l0.io_w_req_bits_data_3_entries_onlypf_7", dut_g.l0.io_w_req_bits_data_3_entries_onlypf_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_onlypf_7);
    chk("l0.io_w_req_bits_data_3_entries_perms_0_d", dut_g.l0.io_w_req_bits_data_3_entries_perms_0_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_0_d);
    chk("l0.io_w_req_bits_data_3_entries_perms_0_a", dut_g.l0.io_w_req_bits_data_3_entries_perms_0_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_0_a);
    chk("l0.io_w_req_bits_data_3_entries_perms_0_g", dut_g.l0.io_w_req_bits_data_3_entries_perms_0_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_0_g);
    chk("l0.io_w_req_bits_data_3_entries_perms_0_u", dut_g.l0.io_w_req_bits_data_3_entries_perms_0_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_0_u);
    chk("l0.io_w_req_bits_data_3_entries_perms_0_x", dut_g.l0.io_w_req_bits_data_3_entries_perms_0_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_0_x);
    chk("l0.io_w_req_bits_data_3_entries_perms_0_w", dut_g.l0.io_w_req_bits_data_3_entries_perms_0_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_0_w);
    chk("l0.io_w_req_bits_data_3_entries_perms_0_r", dut_g.l0.io_w_req_bits_data_3_entries_perms_0_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_0_r);
    chk("l0.io_w_req_bits_data_3_entries_perms_1_d", dut_g.l0.io_w_req_bits_data_3_entries_perms_1_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_1_d);
    chk("l0.io_w_req_bits_data_3_entries_perms_1_a", dut_g.l0.io_w_req_bits_data_3_entries_perms_1_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_1_a);
    chk("l0.io_w_req_bits_data_3_entries_perms_1_g", dut_g.l0.io_w_req_bits_data_3_entries_perms_1_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_1_g);
    chk("l0.io_w_req_bits_data_3_entries_perms_1_u", dut_g.l0.io_w_req_bits_data_3_entries_perms_1_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_1_u);
    chk("l0.io_w_req_bits_data_3_entries_perms_1_x", dut_g.l0.io_w_req_bits_data_3_entries_perms_1_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_1_x);
    chk("l0.io_w_req_bits_data_3_entries_perms_1_w", dut_g.l0.io_w_req_bits_data_3_entries_perms_1_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_1_w);
    chk("l0.io_w_req_bits_data_3_entries_perms_1_r", dut_g.l0.io_w_req_bits_data_3_entries_perms_1_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_1_r);
    chk("l0.io_w_req_bits_data_3_entries_perms_2_d", dut_g.l0.io_w_req_bits_data_3_entries_perms_2_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_2_d);
    chk("l0.io_w_req_bits_data_3_entries_perms_2_a", dut_g.l0.io_w_req_bits_data_3_entries_perms_2_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_2_a);
    chk("l0.io_w_req_bits_data_3_entries_perms_2_g", dut_g.l0.io_w_req_bits_data_3_entries_perms_2_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_2_g);
    chk("l0.io_w_req_bits_data_3_entries_perms_2_u", dut_g.l0.io_w_req_bits_data_3_entries_perms_2_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_2_u);
    chk("l0.io_w_req_bits_data_3_entries_perms_2_x", dut_g.l0.io_w_req_bits_data_3_entries_perms_2_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_2_x);
    chk("l0.io_w_req_bits_data_3_entries_perms_2_w", dut_g.l0.io_w_req_bits_data_3_entries_perms_2_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_2_w);
    chk("l0.io_w_req_bits_data_3_entries_perms_2_r", dut_g.l0.io_w_req_bits_data_3_entries_perms_2_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_2_r);
    chk("l0.io_w_req_bits_data_3_entries_perms_3_d", dut_g.l0.io_w_req_bits_data_3_entries_perms_3_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_3_d);
    chk("l0.io_w_req_bits_data_3_entries_perms_3_a", dut_g.l0.io_w_req_bits_data_3_entries_perms_3_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_3_a);
    chk("l0.io_w_req_bits_data_3_entries_perms_3_g", dut_g.l0.io_w_req_bits_data_3_entries_perms_3_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_3_g);
    chk("l0.io_w_req_bits_data_3_entries_perms_3_u", dut_g.l0.io_w_req_bits_data_3_entries_perms_3_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_3_u);
    chk("l0.io_w_req_bits_data_3_entries_perms_3_x", dut_g.l0.io_w_req_bits_data_3_entries_perms_3_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_3_x);
    chk("l0.io_w_req_bits_data_3_entries_perms_3_w", dut_g.l0.io_w_req_bits_data_3_entries_perms_3_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_3_w);
    chk("l0.io_w_req_bits_data_3_entries_perms_3_r", dut_g.l0.io_w_req_bits_data_3_entries_perms_3_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_3_r);
    chk("l0.io_w_req_bits_data_3_entries_perms_4_d", dut_g.l0.io_w_req_bits_data_3_entries_perms_4_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_4_d);
    chk("l0.io_w_req_bits_data_3_entries_perms_4_a", dut_g.l0.io_w_req_bits_data_3_entries_perms_4_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_4_a);
    chk("l0.io_w_req_bits_data_3_entries_perms_4_g", dut_g.l0.io_w_req_bits_data_3_entries_perms_4_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_4_g);
    chk("l0.io_w_req_bits_data_3_entries_perms_4_u", dut_g.l0.io_w_req_bits_data_3_entries_perms_4_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_4_u);
    chk("l0.io_w_req_bits_data_3_entries_perms_4_x", dut_g.l0.io_w_req_bits_data_3_entries_perms_4_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_4_x);
    chk("l0.io_w_req_bits_data_3_entries_perms_4_w", dut_g.l0.io_w_req_bits_data_3_entries_perms_4_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_4_w);
    chk("l0.io_w_req_bits_data_3_entries_perms_4_r", dut_g.l0.io_w_req_bits_data_3_entries_perms_4_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_4_r);
    chk("l0.io_w_req_bits_data_3_entries_perms_5_d", dut_g.l0.io_w_req_bits_data_3_entries_perms_5_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_5_d);
    chk("l0.io_w_req_bits_data_3_entries_perms_5_a", dut_g.l0.io_w_req_bits_data_3_entries_perms_5_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_5_a);
    chk("l0.io_w_req_bits_data_3_entries_perms_5_g", dut_g.l0.io_w_req_bits_data_3_entries_perms_5_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_5_g);
    chk("l0.io_w_req_bits_data_3_entries_perms_5_u", dut_g.l0.io_w_req_bits_data_3_entries_perms_5_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_5_u);
    chk("l0.io_w_req_bits_data_3_entries_perms_5_x", dut_g.l0.io_w_req_bits_data_3_entries_perms_5_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_5_x);
    chk("l0.io_w_req_bits_data_3_entries_perms_5_w", dut_g.l0.io_w_req_bits_data_3_entries_perms_5_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_5_w);
    chk("l0.io_w_req_bits_data_3_entries_perms_5_r", dut_g.l0.io_w_req_bits_data_3_entries_perms_5_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_5_r);
    chk("l0.io_w_req_bits_data_3_entries_perms_6_d", dut_g.l0.io_w_req_bits_data_3_entries_perms_6_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_6_d);
    chk("l0.io_w_req_bits_data_3_entries_perms_6_a", dut_g.l0.io_w_req_bits_data_3_entries_perms_6_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_6_a);
    chk("l0.io_w_req_bits_data_3_entries_perms_6_g", dut_g.l0.io_w_req_bits_data_3_entries_perms_6_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_6_g);
    chk("l0.io_w_req_bits_data_3_entries_perms_6_u", dut_g.l0.io_w_req_bits_data_3_entries_perms_6_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_6_u);
    chk("l0.io_w_req_bits_data_3_entries_perms_6_x", dut_g.l0.io_w_req_bits_data_3_entries_perms_6_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_6_x);
    chk("l0.io_w_req_bits_data_3_entries_perms_6_w", dut_g.l0.io_w_req_bits_data_3_entries_perms_6_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_6_w);
    chk("l0.io_w_req_bits_data_3_entries_perms_6_r", dut_g.l0.io_w_req_bits_data_3_entries_perms_6_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_6_r);
    chk("l0.io_w_req_bits_data_3_entries_perms_7_d", dut_g.l0.io_w_req_bits_data_3_entries_perms_7_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_7_d);
    chk("l0.io_w_req_bits_data_3_entries_perms_7_a", dut_g.l0.io_w_req_bits_data_3_entries_perms_7_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_7_a);
    chk("l0.io_w_req_bits_data_3_entries_perms_7_g", dut_g.l0.io_w_req_bits_data_3_entries_perms_7_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_7_g);
    chk("l0.io_w_req_bits_data_3_entries_perms_7_u", dut_g.l0.io_w_req_bits_data_3_entries_perms_7_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_7_u);
    chk("l0.io_w_req_bits_data_3_entries_perms_7_x", dut_g.l0.io_w_req_bits_data_3_entries_perms_7_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_7_x);
    chk("l0.io_w_req_bits_data_3_entries_perms_7_w", dut_g.l0.io_w_req_bits_data_3_entries_perms_7_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_7_w);
    chk("l0.io_w_req_bits_data_3_entries_perms_7_r", dut_g.l0.io_w_req_bits_data_3_entries_perms_7_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_7_r);
    chk("l0.io_w_req_bits_data_3_entries_prefetch", dut_g.l0.io_w_req_bits_data_3_entries_prefetch, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_prefetch);
    chk("l0.io_w_req_bits_waymask", dut_g.l0.io_w_req_bits_waymask, dut_i.u_core.u_l0_sram.io_w_req_bits_waymask);
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", ncycles)) ncycles = 20000;
    // 未驱动的输入全部清零（本对照只关心回填锥体）
    io_csr_mPBMTE = '0;
    io_csr_hPBMTE = '0;
    io_req_valid = '0;
    io_req_bits_req_info_vpn = '0;
    io_req_bits_req_info_s2xlate = '0;
    io_req_bits_req_info_source = '0;
    io_req_bits_isFirst = '0;
    io_req_bits_isHptwReq = '0;
    io_req_bits_hptwId = '0;
    io_resp_ready = '0;
    io_refill_valid = '0;
    io_refill_bits_ptes = '0;
    io_refill_bits_levelOH_sp = '0;
    io_refill_bits_levelOH_l0 = '0;
    io_refill_bits_levelOH_l1 = '0;
    io_refill_bits_levelOH_l2 = '0;
    io_refill_bits_levelOH_l3 = '0;
    io_refill_bits_req_info_dup_0_vpn = '0;
    io_refill_bits_req_info_dup_0_s2xlate = '0;
    io_refill_bits_req_info_dup_0_source = '0;
    io_refill_bits_req_info_dup_1_vpn = '0;
    io_refill_bits_req_info_dup_1_s2xlate = '0;
    io_refill_bits_req_info_dup_1_source = '0;
    io_refill_bits_req_info_dup_2_vpn = '0;
    io_refill_bits_req_info_dup_2_s2xlate = '0;
    io_refill_bits_req_info_dup_2_source = '0;
    io_refill_bits_level_dup_0 = '0;
    io_refill_bits_level_dup_2 = '0;
    io_refill_bits_sel_pte_dup_0 = '0;
    io_refill_bits_sel_pte_dup_2 = '0;
    io_sfence_dup_0_valid = '0;
    io_sfence_dup_0_bits_rs1 = '0;
    io_sfence_dup_0_bits_rs2 = '0;
    io_sfence_dup_0_bits_addr = '0;
    io_sfence_dup_0_bits_id = '0;
    io_sfence_dup_0_bits_hv = '0;
    io_sfence_dup_0_bits_hg = '0;
    io_sfence_dup_1_valid = '0;
    io_sfence_dup_1_bits_id = '0;
    io_sfence_dup_2_valid = '0;
    io_sfence_dup_2_bits_rs1 = '0;
    io_sfence_dup_2_bits_rs2 = '0;
    io_sfence_dup_2_bits_id = '0;
    io_csr_dup_0_satp_asid = '0;
    io_csr_dup_0_satp_changed = '0;
    io_csr_dup_0_vsatp_asid = '0;
    io_csr_dup_0_vsatp_changed = '0;
    io_csr_dup_0_hgatp_mode = '0;
    io_csr_dup_0_hgatp_vmid = '0;
    io_csr_dup_0_hgatp_changed = '0;
    io_csr_dup_0_mbmc_BME = '0;
    io_csr_dup_0_mbmc_CMODE = '0;
    io_csr_dup_0_priv_virt = '0;
    io_csr_dup_0_priv_virt_changed = '0;
    io_csr_dup_1_satp_asid = '0;
    io_csr_dup_1_satp_changed = '0;
    io_csr_dup_1_vsatp_asid = '0;
    io_csr_dup_1_vsatp_changed = '0;
    io_csr_dup_1_hgatp_mode = '0;
    io_csr_dup_1_hgatp_vmid = '0;
    io_csr_dup_1_hgatp_changed = '0;
    io_csr_dup_1_priv_virt = '0;
    io_csr_dup_1_priv_virt_changed = '0;
    io_csr_dup_2_satp_asid = '0;
    io_csr_dup_2_satp_changed = '0;
    io_csr_dup_2_vsatp_asid = '0;
    io_csr_dup_2_vsatp_changed = '0;
    io_csr_dup_2_hgatp_mode = '0;
    io_csr_dup_2_hgatp_vmid = '0;
    io_csr_dup_2_hgatp_changed = '0;
    io_csr_dup_2_priv_virt = '0;
    io_csr_dup_2_priv_virt_changed = '0;
    io_bitmap_wakeup_valid = '0;
    io_bitmap_wakeup_bits_setIndex = '0;
    io_bitmap_wakeup_bits_tag = '0;
    io_bitmap_wakeup_bits_way_info = '0;
    io_bitmap_wakeup_bits_pte_index = '0;
    io_bitmap_wakeup_bits_check_success = '0;
    io_bitmap_wakeup_bits_s2xlate = '0;
    boreChildrenBd_bore_array = '0;
    boreChildrenBd_bore_all = '0;
    boreChildrenBd_bore_req = '0;
    boreChildrenBd_bore_writeen = '0;
    boreChildrenBd_bore_be = '0;
    boreChildrenBd_bore_addr = '0;
    boreChildrenBd_bore_indata = '0;
    boreChildrenBd_bore_readen = '0;
    boreChildrenBd_bore_addr_rd = '0;
    boreChildrenBd_bore_1_array = '0;
    boreChildrenBd_bore_1_all = '0;
    boreChildrenBd_bore_1_req = '0;
    boreChildrenBd_bore_1_writeen = '0;
    boreChildrenBd_bore_1_be = '0;
    boreChildrenBd_bore_1_addr = '0;
    boreChildrenBd_bore_1_indata = '0;
    boreChildrenBd_bore_1_readen = '0;
    boreChildrenBd_bore_1_addr_rd = '0;
    sigFromSrams_bore_ram_hold = '0;
    sigFromSrams_bore_ram_bypass = '0;
    sigFromSrams_bore_ram_bp_clken = '0;
    sigFromSrams_bore_ram_aux_clk = '0;
    sigFromSrams_bore_ram_aux_ckbp = '0;
    sigFromSrams_bore_ram_mcp_hold = '0;
    sigFromSrams_bore_cgen = '0;
    sigFromSrams_bore_1_ram_hold = '0;
    sigFromSrams_bore_1_ram_bypass = '0;
    sigFromSrams_bore_1_ram_bp_clken = '0;
    sigFromSrams_bore_1_ram_aux_clk = '0;
    sigFromSrams_bore_1_ram_aux_ckbp = '0;
    sigFromSrams_bore_1_ram_mcp_hold = '0;
    sigFromSrams_bore_1_cgen = '0;
    sigFromSrams_bore_2_ram_hold = '0;
    sigFromSrams_bore_2_ram_bypass = '0;
    sigFromSrams_bore_2_ram_bp_clken = '0;
    sigFromSrams_bore_2_ram_aux_clk = '0;
    sigFromSrams_bore_2_ram_aux_ckbp = '0;
    sigFromSrams_bore_2_ram_mcp_hold = '0;
    sigFromSrams_bore_2_cgen = '0;
    sigFromSrams_bore_3_ram_hold = '0;
    sigFromSrams_bore_3_ram_bypass = '0;
    sigFromSrams_bore_3_ram_bp_clken = '0;
    sigFromSrams_bore_3_ram_aux_clk = '0;
    sigFromSrams_bore_3_ram_aux_ckbp = '0;
    sigFromSrams_bore_3_ram_mcp_hold = '0;
    sigFromSrams_bore_3_cgen = '0;
    sigFromSrams_bore_4_ram_hold = '0;
    sigFromSrams_bore_4_ram_bypass = '0;
    sigFromSrams_bore_4_ram_bp_clken = '0;
    sigFromSrams_bore_4_ram_aux_clk = '0;
    sigFromSrams_bore_4_ram_aux_ckbp = '0;
    sigFromSrams_bore_4_ram_mcp_hold = '0;
    sigFromSrams_bore_4_cgen = '0;
    sigFromSrams_bore_5_ram_hold = '0;
    sigFromSrams_bore_5_ram_bypass = '0;
    sigFromSrams_bore_5_ram_bp_clken = '0;
    sigFromSrams_bore_5_ram_aux_clk = '0;
    sigFromSrams_bore_5_ram_aux_ckbp = '0;
    sigFromSrams_bore_5_ram_mcp_hold = '0;
    sigFromSrams_bore_5_cgen = '0;
    sigFromSrams_bore_6_ram_hold = '0;
    sigFromSrams_bore_6_ram_bypass = '0;
    sigFromSrams_bore_6_ram_bp_clken = '0;
    sigFromSrams_bore_6_ram_aux_clk = '0;
    sigFromSrams_bore_6_ram_aux_ckbp = '0;
    sigFromSrams_bore_6_ram_mcp_hold = '0;
    sigFromSrams_bore_6_cgen = '0;
    sigFromSrams_bore_7_ram_hold = '0;
    sigFromSrams_bore_7_ram_bypass = '0;
    sigFromSrams_bore_7_ram_bp_clken = '0;
    sigFromSrams_bore_7_ram_aux_clk = '0;
    sigFromSrams_bore_7_ram_aux_ckbp = '0;
    sigFromSrams_bore_7_ram_mcp_hold = '0;
    sigFromSrams_bore_7_cgen = '0;
    sigFromSrams_bore_8_ram_hold = '0;
    sigFromSrams_bore_8_ram_bypass = '0;
    sigFromSrams_bore_8_ram_bp_clken = '0;
    sigFromSrams_bore_8_ram_aux_clk = '0;
    sigFromSrams_bore_8_ram_aux_ckbp = '0;
    sigFromSrams_bore_8_ram_mcp_hold = '0;
    sigFromSrams_bore_8_cgen = '0;
    sigFromSrams_bore_9_ram_hold = '0;
    sigFromSrams_bore_9_ram_bypass = '0;
    sigFromSrams_bore_9_ram_bp_clken = '0;
    sigFromSrams_bore_9_ram_aux_clk = '0;
    sigFromSrams_bore_9_ram_aux_ckbp = '0;
    sigFromSrams_bore_9_ram_mcp_hold = '0;
    sigFromSrams_bore_9_cgen = '0;
    sigFromSrams_bore_10_ram_hold = '0;
    sigFromSrams_bore_10_ram_bypass = '0;
    sigFromSrams_bore_10_ram_bp_clken = '0;
    sigFromSrams_bore_10_ram_aux_clk = '0;
    sigFromSrams_bore_10_ram_aux_ckbp = '0;
    sigFromSrams_bore_10_ram_mcp_hold = '0;
    sigFromSrams_bore_10_cgen = '0;
    sigFromSrams_bore_11_ram_hold = '0;
    sigFromSrams_bore_11_ram_bypass = '0;
    sigFromSrams_bore_11_ram_bp_clken = '0;
    sigFromSrams_bore_11_ram_aux_clk = '0;
    sigFromSrams_bore_11_ram_aux_ckbp = '0;
    sigFromSrams_bore_11_ram_mcp_hold = '0;
    sigFromSrams_bore_11_cgen = '0;
    sigFromSrams_bore_12_ram_hold = '0;
    sigFromSrams_bore_12_ram_bypass = '0;
    sigFromSrams_bore_12_ram_bp_clken = '0;
    sigFromSrams_bore_12_ram_aux_clk = '0;
    sigFromSrams_bore_12_ram_aux_ckbp = '0;
    sigFromSrams_bore_12_ram_mcp_hold = '0;
    sigFromSrams_bore_12_cgen = '0;
    sigFromSrams_bore_13_ram_hold = '0;
    sigFromSrams_bore_13_ram_bypass = '0;
    sigFromSrams_bore_13_ram_bp_clken = '0;
    sigFromSrams_bore_13_ram_aux_clk = '0;
    sigFromSrams_bore_13_ram_aux_ckbp = '0;
    sigFromSrams_bore_13_ram_mcp_hold = '0;
    sigFromSrams_bore_13_cgen = '0;
    sigFromSrams_bore_14_ram_hold = '0;
    sigFromSrams_bore_14_ram_bypass = '0;
    sigFromSrams_bore_14_ram_bp_clken = '0;
    sigFromSrams_bore_14_ram_aux_clk = '0;
    sigFromSrams_bore_14_ram_aux_ckbp = '0;
    sigFromSrams_bore_14_ram_mcp_hold = '0;
    sigFromSrams_bore_14_cgen = '0;
    sigFromSrams_bore_15_ram_hold = '0;
    sigFromSrams_bore_15_ram_bypass = '0;
    sigFromSrams_bore_15_ram_bp_clken = '0;
    sigFromSrams_bore_15_ram_aux_clk = '0;
    sigFromSrams_bore_15_ram_aux_ckbp = '0;
    sigFromSrams_bore_15_ram_mcp_hold = '0;
    sigFromSrams_bore_15_cgen = '0;
    sigFromSrams_bore_16_ram_hold = '0;
    sigFromSrams_bore_16_ram_bypass = '0;
    sigFromSrams_bore_16_ram_bp_clken = '0;
    sigFromSrams_bore_16_ram_aux_clk = '0;
    sigFromSrams_bore_16_ram_aux_ckbp = '0;
    sigFromSrams_bore_16_ram_mcp_hold = '0;
    sigFromSrams_bore_16_cgen = '0;
    cg_bore_cgen = '0;
    repeat (4) @(posedge clock);
    reset = 1'b0;
    for (int c = 0; c < ncycles; c++) begin
      @(negedge clock);
      drive_random();
      #1;
      compare_write_ports();
    end
    $display("PtwCache_refill study: cycles=%0d checks=%0d errors=%0d untraced_diff=%0d",
             ncycles, checks, errors, untraced_diff);
    if (errors != 0)
      $display("STUDY FAIL (已追清信号失配)");
    else if (untraced_diff == 0)
      $display("STUDY FAIL (占位信号也不失配 —— 本对照没有判别力，先查 tb 再信它)");
    else
      $display("STUDY PASS");
    $finish;
  end
endmodule
