// tb.sv —— PTW 的双例化逐拍差分 UT（verif/ut/PTW）。
//
// 双例化 golden PTW 与派生的 PTW_xs，同拍同激励，逐拍比全部 211 个输出
// （输出表由 scripts/gen_mmu5.py 从 golden 端口表逐根量出，不手抄）。
//
// 【激励设计——PTW 是一台单请求状态机，激励要让它走完每条路径】
//   · 请求：s2xlate 四种均匀（noS2xlate / onlyStage1 / onlyStage2 / allStage）；stage1Hit 1/4、
//     bitmap 跳转 1/4、其余普通走表；l3Hit/l2Hit 随机；vpn 从 4 项池子取（四分之一全随机，
//     且高位 [37:29] 一半清 0 —— 否则 onlyStage2 + Sv39x4 时入口 GPA 越界几乎必中）。
//   · CSR 每 512 拍换：satp/vsatp/hgatp 的 mode Sv48:Sv39:其它 = 6:3:1；satp/vsatp 的 ppn 与
//     req.ppn 四分之三清高位（allStage 入口的 GPA 越界检查看的是根页表 ppn 的高位）。
//   · 访存响应 io_mem_resp_valid 随时随机拉高（PTW 只用 w_mem_resp 门控）；mem_resp_bits
//     三分之一干净 next 型、三分之一干净叶子（按 golden 当前 level 对齐）、三分之一全随机。
//   · HPTW 响应 valid 1/3：gpf/gaf 各 1/8，perm.r 3/4 为 1（不可读会被 PTW 当 gpf）。
//   · PMP 响应 ld/mmio 各 1/20；bitmap：mbmc 每 256 拍换、resp 随机、cf 随机；
//     llptw/hptw.req/mem.req/resp/bitmap.req 的 ready 各 3/4；flush 五根各 1/500 拍。
//
// 【判别力自证】覆盖计数下限（见文末断言）：resp fire / llptw fire / hptw req fire /
//   mem req fire / gpf / gaf / entry pf / entry af / stage1Hit 回应 / 跳转回应 / bitmap req fire /
//   四种 s2xlate 各自的回应 / Sv39 回应 都必须 > 0，任何一项为 0 则 tb 自判 FAIL。
`timescale 1ns/1ps
module tb;
  int errors = 0;
  int checks = 0;
  int ncycles;
  int cov_resp = 0, cov_llptw = 0, cov_hptw_req = 0, cov_mem_req = 0, cov_gpf = 0, cov_gaf = 0;
  int cov_pf = 0, cov_af = 0, cov_s1 = 0, cov_jmp = 0, cov_bm_req = 0, cov_sv39 = 0;
  int cov_s2x [4] = '{0, 0, 0, 0};

  // BEGIN GENERATED(harness) —— 由 gen_mmu5.py 生成：信号声明 / 双例化 / 输出逐拍比对
  logic clock, reset;
  logic io_sfence_valid;
  logic [3:0] io_csr_satp_mode;
  logic [15:0] io_csr_satp_asid;
  logic [43:0] io_csr_satp_ppn;
  logic io_csr_satp_changed;
  logic [3:0] io_csr_vsatp_mode;
  logic [15:0] io_csr_vsatp_asid;
  logic [43:0] io_csr_vsatp_ppn;
  logic io_csr_vsatp_changed;
  logic [3:0] io_csr_hgatp_mode;
  logic [15:0] io_csr_hgatp_vmid;
  logic io_csr_hgatp_changed;
  logic io_csr_mbmc_BME;
  logic io_csr_mbmc_CMODE;
  logic io_csr_priv_virt_changed;
  logic io_csr_mPBMTE;
  logic io_csr_hPBMTE;
  logic io_req_valid;
  logic [37:0] io_req_bits_req_info_vpn;
  logic [1:0] io_req_bits_req_info_s2xlate;
  logic [1:0] io_req_bits_req_info_source;
  logic io_req_bits_l3Hit;
  logic io_req_bits_l2Hit;
  logic [43:0] io_req_bits_ppn;
  logic io_req_bits_stage1Hit;
  logic [34:0] io_req_bits_stage1_entry_0_tag;
  logic [15:0] io_req_bits_stage1_entry_0_asid;
  logic [13:0] io_req_bits_stage1_entry_0_vmid;
  logic io_req_bits_stage1_entry_0_n;
  logic [1:0] io_req_bits_stage1_entry_0_pbmt;
  logic io_req_bits_stage1_entry_0_perm_d;
  logic io_req_bits_stage1_entry_0_perm_a;
  logic io_req_bits_stage1_entry_0_perm_g;
  logic io_req_bits_stage1_entry_0_perm_u;
  logic io_req_bits_stage1_entry_0_perm_x;
  logic io_req_bits_stage1_entry_0_perm_w;
  logic io_req_bits_stage1_entry_0_perm_r;
  logic [1:0] io_req_bits_stage1_entry_0_level;
  logic io_req_bits_stage1_entry_0_v;
  logic [40:0] io_req_bits_stage1_entry_0_ppn;
  logic [2:0] io_req_bits_stage1_entry_0_ppn_low;
  logic io_req_bits_stage1_entry_0_pf;
  logic io_req_bits_stage1_entry_0_cf;
  logic [34:0] io_req_bits_stage1_entry_1_tag;
  logic [15:0] io_req_bits_stage1_entry_1_asid;
  logic [13:0] io_req_bits_stage1_entry_1_vmid;
  logic io_req_bits_stage1_entry_1_n;
  logic [1:0] io_req_bits_stage1_entry_1_pbmt;
  logic io_req_bits_stage1_entry_1_perm_d;
  logic io_req_bits_stage1_entry_1_perm_a;
  logic io_req_bits_stage1_entry_1_perm_g;
  logic io_req_bits_stage1_entry_1_perm_u;
  logic io_req_bits_stage1_entry_1_perm_x;
  logic io_req_bits_stage1_entry_1_perm_w;
  logic io_req_bits_stage1_entry_1_perm_r;
  logic [1:0] io_req_bits_stage1_entry_1_level;
  logic io_req_bits_stage1_entry_1_v;
  logic [40:0] io_req_bits_stage1_entry_1_ppn;
  logic [2:0] io_req_bits_stage1_entry_1_ppn_low;
  logic io_req_bits_stage1_entry_1_pf;
  logic io_req_bits_stage1_entry_1_cf;
  logic [34:0] io_req_bits_stage1_entry_2_tag;
  logic [15:0] io_req_bits_stage1_entry_2_asid;
  logic [13:0] io_req_bits_stage1_entry_2_vmid;
  logic io_req_bits_stage1_entry_2_n;
  logic [1:0] io_req_bits_stage1_entry_2_pbmt;
  logic io_req_bits_stage1_entry_2_perm_d;
  logic io_req_bits_stage1_entry_2_perm_a;
  logic io_req_bits_stage1_entry_2_perm_g;
  logic io_req_bits_stage1_entry_2_perm_u;
  logic io_req_bits_stage1_entry_2_perm_x;
  logic io_req_bits_stage1_entry_2_perm_w;
  logic io_req_bits_stage1_entry_2_perm_r;
  logic [1:0] io_req_bits_stage1_entry_2_level;
  logic io_req_bits_stage1_entry_2_v;
  logic [40:0] io_req_bits_stage1_entry_2_ppn;
  logic [2:0] io_req_bits_stage1_entry_2_ppn_low;
  logic io_req_bits_stage1_entry_2_pf;
  logic io_req_bits_stage1_entry_2_cf;
  logic [34:0] io_req_bits_stage1_entry_3_tag;
  logic [15:0] io_req_bits_stage1_entry_3_asid;
  logic [13:0] io_req_bits_stage1_entry_3_vmid;
  logic io_req_bits_stage1_entry_3_n;
  logic [1:0] io_req_bits_stage1_entry_3_pbmt;
  logic io_req_bits_stage1_entry_3_perm_d;
  logic io_req_bits_stage1_entry_3_perm_a;
  logic io_req_bits_stage1_entry_3_perm_g;
  logic io_req_bits_stage1_entry_3_perm_u;
  logic io_req_bits_stage1_entry_3_perm_x;
  logic io_req_bits_stage1_entry_3_perm_w;
  logic io_req_bits_stage1_entry_3_perm_r;
  logic [1:0] io_req_bits_stage1_entry_3_level;
  logic io_req_bits_stage1_entry_3_v;
  logic [40:0] io_req_bits_stage1_entry_3_ppn;
  logic [2:0] io_req_bits_stage1_entry_3_ppn_low;
  logic io_req_bits_stage1_entry_3_pf;
  logic io_req_bits_stage1_entry_3_cf;
  logic [34:0] io_req_bits_stage1_entry_4_tag;
  logic [15:0] io_req_bits_stage1_entry_4_asid;
  logic [13:0] io_req_bits_stage1_entry_4_vmid;
  logic io_req_bits_stage1_entry_4_n;
  logic [1:0] io_req_bits_stage1_entry_4_pbmt;
  logic io_req_bits_stage1_entry_4_perm_d;
  logic io_req_bits_stage1_entry_4_perm_a;
  logic io_req_bits_stage1_entry_4_perm_g;
  logic io_req_bits_stage1_entry_4_perm_u;
  logic io_req_bits_stage1_entry_4_perm_x;
  logic io_req_bits_stage1_entry_4_perm_w;
  logic io_req_bits_stage1_entry_4_perm_r;
  logic [1:0] io_req_bits_stage1_entry_4_level;
  logic io_req_bits_stage1_entry_4_v;
  logic [40:0] io_req_bits_stage1_entry_4_ppn;
  logic [2:0] io_req_bits_stage1_entry_4_ppn_low;
  logic io_req_bits_stage1_entry_4_pf;
  logic io_req_bits_stage1_entry_4_cf;
  logic [34:0] io_req_bits_stage1_entry_5_tag;
  logic [15:0] io_req_bits_stage1_entry_5_asid;
  logic [13:0] io_req_bits_stage1_entry_5_vmid;
  logic io_req_bits_stage1_entry_5_n;
  logic [1:0] io_req_bits_stage1_entry_5_pbmt;
  logic io_req_bits_stage1_entry_5_perm_d;
  logic io_req_bits_stage1_entry_5_perm_a;
  logic io_req_bits_stage1_entry_5_perm_g;
  logic io_req_bits_stage1_entry_5_perm_u;
  logic io_req_bits_stage1_entry_5_perm_x;
  logic io_req_bits_stage1_entry_5_perm_w;
  logic io_req_bits_stage1_entry_5_perm_r;
  logic [1:0] io_req_bits_stage1_entry_5_level;
  logic io_req_bits_stage1_entry_5_v;
  logic [40:0] io_req_bits_stage1_entry_5_ppn;
  logic [2:0] io_req_bits_stage1_entry_5_ppn_low;
  logic io_req_bits_stage1_entry_5_pf;
  logic io_req_bits_stage1_entry_5_cf;
  logic [34:0] io_req_bits_stage1_entry_6_tag;
  logic [15:0] io_req_bits_stage1_entry_6_asid;
  logic [13:0] io_req_bits_stage1_entry_6_vmid;
  logic io_req_bits_stage1_entry_6_n;
  logic [1:0] io_req_bits_stage1_entry_6_pbmt;
  logic io_req_bits_stage1_entry_6_perm_d;
  logic io_req_bits_stage1_entry_6_perm_a;
  logic io_req_bits_stage1_entry_6_perm_g;
  logic io_req_bits_stage1_entry_6_perm_u;
  logic io_req_bits_stage1_entry_6_perm_x;
  logic io_req_bits_stage1_entry_6_perm_w;
  logic io_req_bits_stage1_entry_6_perm_r;
  logic [1:0] io_req_bits_stage1_entry_6_level;
  logic io_req_bits_stage1_entry_6_v;
  logic [40:0] io_req_bits_stage1_entry_6_ppn;
  logic [2:0] io_req_bits_stage1_entry_6_ppn_low;
  logic io_req_bits_stage1_entry_6_pf;
  logic io_req_bits_stage1_entry_6_cf;
  logic [34:0] io_req_bits_stage1_entry_7_tag;
  logic [15:0] io_req_bits_stage1_entry_7_asid;
  logic [13:0] io_req_bits_stage1_entry_7_vmid;
  logic io_req_bits_stage1_entry_7_n;
  logic [1:0] io_req_bits_stage1_entry_7_pbmt;
  logic io_req_bits_stage1_entry_7_perm_d;
  logic io_req_bits_stage1_entry_7_perm_a;
  logic io_req_bits_stage1_entry_7_perm_g;
  logic io_req_bits_stage1_entry_7_perm_u;
  logic io_req_bits_stage1_entry_7_perm_x;
  logic io_req_bits_stage1_entry_7_perm_w;
  logic io_req_bits_stage1_entry_7_perm_r;
  logic [1:0] io_req_bits_stage1_entry_7_level;
  logic io_req_bits_stage1_entry_7_v;
  logic [40:0] io_req_bits_stage1_entry_7_ppn;
  logic [2:0] io_req_bits_stage1_entry_7_ppn_low;
  logic io_req_bits_stage1_entry_7_pf;
  logic io_req_bits_stage1_entry_7_cf;
  logic io_req_bits_stage1_pteidx_0;
  logic io_req_bits_stage1_pteidx_1;
  logic io_req_bits_stage1_pteidx_2;
  logic io_req_bits_stage1_pteidx_3;
  logic io_req_bits_stage1_pteidx_4;
  logic io_req_bits_stage1_pteidx_5;
  logic io_req_bits_stage1_pteidx_6;
  logic io_req_bits_stage1_pteidx_7;
  logic io_req_bits_stage1_not_super;
  logic io_req_bits_bitmapCheck_jmp_bitmap_check;
  logic [63:0] io_req_bits_bitmapCheck_pte;
  logic [1:0] io_req_bits_bitmapCheck_SPlevel;
  logic io_resp_ready;
  logic io_llptw_ready;
  logic io_hptw_req_ready;
  logic io_hptw_resp_valid;
  logic [37:0] io_hptw_resp_bits_h_resp_entry_tag;
  logic [13:0] io_hptw_resp_bits_h_resp_entry_vmid;
  logic io_hptw_resp_bits_h_resp_entry_n;
  logic [1:0] io_hptw_resp_bits_h_resp_entry_pbmt;
  logic [37:0] io_hptw_resp_bits_h_resp_entry_ppn;
  logic io_hptw_resp_bits_h_resp_entry_perm_d;
  logic io_hptw_resp_bits_h_resp_entry_perm_a;
  logic io_hptw_resp_bits_h_resp_entry_perm_g;
  logic io_hptw_resp_bits_h_resp_entry_perm_u;
  logic io_hptw_resp_bits_h_resp_entry_perm_x;
  logic io_hptw_resp_bits_h_resp_entry_perm_w;
  logic io_hptw_resp_bits_h_resp_entry_perm_r;
  logic [1:0] io_hptw_resp_bits_h_resp_entry_level;
  logic io_hptw_resp_bits_h_resp_gpf;
  logic io_hptw_resp_bits_h_resp_gaf;
  logic io_mem_req_ready;
  logic io_mem_resp_valid;
  logic [63:0] io_mem_resp_bits;
  logic io_mem_mask;
  logic io_pmp_resp_ld;
  logic io_pmp_resp_mmio;
  logic io_bitmap_req_ready;
  logic io_bitmap_resp_valid;
  logic io_bitmap_resp_bits_cf;
  logic g_io_req_ready, i_io_req_ready;
  logic g_io_resp_valid, i_io_resp_valid;
  logic [1:0] g_io_resp_bits_source, i_io_resp_bits_source;
  logic [1:0] g_io_resp_bits_s2xlate, i_io_resp_bits_s2xlate;
  logic [34:0] g_io_resp_bits_resp_entry_0_tag, i_io_resp_bits_resp_entry_0_tag;
  logic [15:0] g_io_resp_bits_resp_entry_0_asid, i_io_resp_bits_resp_entry_0_asid;
  logic [13:0] g_io_resp_bits_resp_entry_0_vmid, i_io_resp_bits_resp_entry_0_vmid;
  logic g_io_resp_bits_resp_entry_0_n, i_io_resp_bits_resp_entry_0_n;
  logic [1:0] g_io_resp_bits_resp_entry_0_pbmt, i_io_resp_bits_resp_entry_0_pbmt;
  logic g_io_resp_bits_resp_entry_0_perm_d, i_io_resp_bits_resp_entry_0_perm_d;
  logic g_io_resp_bits_resp_entry_0_perm_a, i_io_resp_bits_resp_entry_0_perm_a;
  logic g_io_resp_bits_resp_entry_0_perm_g, i_io_resp_bits_resp_entry_0_perm_g;
  logic g_io_resp_bits_resp_entry_0_perm_u, i_io_resp_bits_resp_entry_0_perm_u;
  logic g_io_resp_bits_resp_entry_0_perm_x, i_io_resp_bits_resp_entry_0_perm_x;
  logic g_io_resp_bits_resp_entry_0_perm_w, i_io_resp_bits_resp_entry_0_perm_w;
  logic g_io_resp_bits_resp_entry_0_perm_r, i_io_resp_bits_resp_entry_0_perm_r;
  logic [1:0] g_io_resp_bits_resp_entry_0_level, i_io_resp_bits_resp_entry_0_level;
  logic g_io_resp_bits_resp_entry_0_v, i_io_resp_bits_resp_entry_0_v;
  logic [40:0] g_io_resp_bits_resp_entry_0_ppn, i_io_resp_bits_resp_entry_0_ppn;
  logic [2:0] g_io_resp_bits_resp_entry_0_ppn_low, i_io_resp_bits_resp_entry_0_ppn_low;
  logic g_io_resp_bits_resp_entry_0_af, i_io_resp_bits_resp_entry_0_af;
  logic g_io_resp_bits_resp_entry_0_pf, i_io_resp_bits_resp_entry_0_pf;
  logic g_io_resp_bits_resp_entry_0_cf, i_io_resp_bits_resp_entry_0_cf;
  logic [34:0] g_io_resp_bits_resp_entry_1_tag, i_io_resp_bits_resp_entry_1_tag;
  logic [15:0] g_io_resp_bits_resp_entry_1_asid, i_io_resp_bits_resp_entry_1_asid;
  logic [13:0] g_io_resp_bits_resp_entry_1_vmid, i_io_resp_bits_resp_entry_1_vmid;
  logic g_io_resp_bits_resp_entry_1_n, i_io_resp_bits_resp_entry_1_n;
  logic [1:0] g_io_resp_bits_resp_entry_1_pbmt, i_io_resp_bits_resp_entry_1_pbmt;
  logic g_io_resp_bits_resp_entry_1_perm_d, i_io_resp_bits_resp_entry_1_perm_d;
  logic g_io_resp_bits_resp_entry_1_perm_a, i_io_resp_bits_resp_entry_1_perm_a;
  logic g_io_resp_bits_resp_entry_1_perm_g, i_io_resp_bits_resp_entry_1_perm_g;
  logic g_io_resp_bits_resp_entry_1_perm_u, i_io_resp_bits_resp_entry_1_perm_u;
  logic g_io_resp_bits_resp_entry_1_perm_x, i_io_resp_bits_resp_entry_1_perm_x;
  logic g_io_resp_bits_resp_entry_1_perm_w, i_io_resp_bits_resp_entry_1_perm_w;
  logic g_io_resp_bits_resp_entry_1_perm_r, i_io_resp_bits_resp_entry_1_perm_r;
  logic [1:0] g_io_resp_bits_resp_entry_1_level, i_io_resp_bits_resp_entry_1_level;
  logic g_io_resp_bits_resp_entry_1_v, i_io_resp_bits_resp_entry_1_v;
  logic [40:0] g_io_resp_bits_resp_entry_1_ppn, i_io_resp_bits_resp_entry_1_ppn;
  logic [2:0] g_io_resp_bits_resp_entry_1_ppn_low, i_io_resp_bits_resp_entry_1_ppn_low;
  logic g_io_resp_bits_resp_entry_1_af, i_io_resp_bits_resp_entry_1_af;
  logic g_io_resp_bits_resp_entry_1_pf, i_io_resp_bits_resp_entry_1_pf;
  logic g_io_resp_bits_resp_entry_1_cf, i_io_resp_bits_resp_entry_1_cf;
  logic [34:0] g_io_resp_bits_resp_entry_2_tag, i_io_resp_bits_resp_entry_2_tag;
  logic [15:0] g_io_resp_bits_resp_entry_2_asid, i_io_resp_bits_resp_entry_2_asid;
  logic [13:0] g_io_resp_bits_resp_entry_2_vmid, i_io_resp_bits_resp_entry_2_vmid;
  logic g_io_resp_bits_resp_entry_2_n, i_io_resp_bits_resp_entry_2_n;
  logic [1:0] g_io_resp_bits_resp_entry_2_pbmt, i_io_resp_bits_resp_entry_2_pbmt;
  logic g_io_resp_bits_resp_entry_2_perm_d, i_io_resp_bits_resp_entry_2_perm_d;
  logic g_io_resp_bits_resp_entry_2_perm_a, i_io_resp_bits_resp_entry_2_perm_a;
  logic g_io_resp_bits_resp_entry_2_perm_g, i_io_resp_bits_resp_entry_2_perm_g;
  logic g_io_resp_bits_resp_entry_2_perm_u, i_io_resp_bits_resp_entry_2_perm_u;
  logic g_io_resp_bits_resp_entry_2_perm_x, i_io_resp_bits_resp_entry_2_perm_x;
  logic g_io_resp_bits_resp_entry_2_perm_w, i_io_resp_bits_resp_entry_2_perm_w;
  logic g_io_resp_bits_resp_entry_2_perm_r, i_io_resp_bits_resp_entry_2_perm_r;
  logic [1:0] g_io_resp_bits_resp_entry_2_level, i_io_resp_bits_resp_entry_2_level;
  logic g_io_resp_bits_resp_entry_2_v, i_io_resp_bits_resp_entry_2_v;
  logic [40:0] g_io_resp_bits_resp_entry_2_ppn, i_io_resp_bits_resp_entry_2_ppn;
  logic [2:0] g_io_resp_bits_resp_entry_2_ppn_low, i_io_resp_bits_resp_entry_2_ppn_low;
  logic g_io_resp_bits_resp_entry_2_af, i_io_resp_bits_resp_entry_2_af;
  logic g_io_resp_bits_resp_entry_2_pf, i_io_resp_bits_resp_entry_2_pf;
  logic g_io_resp_bits_resp_entry_2_cf, i_io_resp_bits_resp_entry_2_cf;
  logic [34:0] g_io_resp_bits_resp_entry_3_tag, i_io_resp_bits_resp_entry_3_tag;
  logic [15:0] g_io_resp_bits_resp_entry_3_asid, i_io_resp_bits_resp_entry_3_asid;
  logic [13:0] g_io_resp_bits_resp_entry_3_vmid, i_io_resp_bits_resp_entry_3_vmid;
  logic g_io_resp_bits_resp_entry_3_n, i_io_resp_bits_resp_entry_3_n;
  logic [1:0] g_io_resp_bits_resp_entry_3_pbmt, i_io_resp_bits_resp_entry_3_pbmt;
  logic g_io_resp_bits_resp_entry_3_perm_d, i_io_resp_bits_resp_entry_3_perm_d;
  logic g_io_resp_bits_resp_entry_3_perm_a, i_io_resp_bits_resp_entry_3_perm_a;
  logic g_io_resp_bits_resp_entry_3_perm_g, i_io_resp_bits_resp_entry_3_perm_g;
  logic g_io_resp_bits_resp_entry_3_perm_u, i_io_resp_bits_resp_entry_3_perm_u;
  logic g_io_resp_bits_resp_entry_3_perm_x, i_io_resp_bits_resp_entry_3_perm_x;
  logic g_io_resp_bits_resp_entry_3_perm_w, i_io_resp_bits_resp_entry_3_perm_w;
  logic g_io_resp_bits_resp_entry_3_perm_r, i_io_resp_bits_resp_entry_3_perm_r;
  logic [1:0] g_io_resp_bits_resp_entry_3_level, i_io_resp_bits_resp_entry_3_level;
  logic g_io_resp_bits_resp_entry_3_v, i_io_resp_bits_resp_entry_3_v;
  logic [40:0] g_io_resp_bits_resp_entry_3_ppn, i_io_resp_bits_resp_entry_3_ppn;
  logic [2:0] g_io_resp_bits_resp_entry_3_ppn_low, i_io_resp_bits_resp_entry_3_ppn_low;
  logic g_io_resp_bits_resp_entry_3_af, i_io_resp_bits_resp_entry_3_af;
  logic g_io_resp_bits_resp_entry_3_pf, i_io_resp_bits_resp_entry_3_pf;
  logic g_io_resp_bits_resp_entry_3_cf, i_io_resp_bits_resp_entry_3_cf;
  logic [34:0] g_io_resp_bits_resp_entry_4_tag, i_io_resp_bits_resp_entry_4_tag;
  logic [15:0] g_io_resp_bits_resp_entry_4_asid, i_io_resp_bits_resp_entry_4_asid;
  logic [13:0] g_io_resp_bits_resp_entry_4_vmid, i_io_resp_bits_resp_entry_4_vmid;
  logic g_io_resp_bits_resp_entry_4_n, i_io_resp_bits_resp_entry_4_n;
  logic [1:0] g_io_resp_bits_resp_entry_4_pbmt, i_io_resp_bits_resp_entry_4_pbmt;
  logic g_io_resp_bits_resp_entry_4_perm_d, i_io_resp_bits_resp_entry_4_perm_d;
  logic g_io_resp_bits_resp_entry_4_perm_a, i_io_resp_bits_resp_entry_4_perm_a;
  logic g_io_resp_bits_resp_entry_4_perm_g, i_io_resp_bits_resp_entry_4_perm_g;
  logic g_io_resp_bits_resp_entry_4_perm_u, i_io_resp_bits_resp_entry_4_perm_u;
  logic g_io_resp_bits_resp_entry_4_perm_x, i_io_resp_bits_resp_entry_4_perm_x;
  logic g_io_resp_bits_resp_entry_4_perm_w, i_io_resp_bits_resp_entry_4_perm_w;
  logic g_io_resp_bits_resp_entry_4_perm_r, i_io_resp_bits_resp_entry_4_perm_r;
  logic [1:0] g_io_resp_bits_resp_entry_4_level, i_io_resp_bits_resp_entry_4_level;
  logic g_io_resp_bits_resp_entry_4_v, i_io_resp_bits_resp_entry_4_v;
  logic [40:0] g_io_resp_bits_resp_entry_4_ppn, i_io_resp_bits_resp_entry_4_ppn;
  logic [2:0] g_io_resp_bits_resp_entry_4_ppn_low, i_io_resp_bits_resp_entry_4_ppn_low;
  logic g_io_resp_bits_resp_entry_4_af, i_io_resp_bits_resp_entry_4_af;
  logic g_io_resp_bits_resp_entry_4_pf, i_io_resp_bits_resp_entry_4_pf;
  logic g_io_resp_bits_resp_entry_4_cf, i_io_resp_bits_resp_entry_4_cf;
  logic [34:0] g_io_resp_bits_resp_entry_5_tag, i_io_resp_bits_resp_entry_5_tag;
  logic [15:0] g_io_resp_bits_resp_entry_5_asid, i_io_resp_bits_resp_entry_5_asid;
  logic [13:0] g_io_resp_bits_resp_entry_5_vmid, i_io_resp_bits_resp_entry_5_vmid;
  logic g_io_resp_bits_resp_entry_5_n, i_io_resp_bits_resp_entry_5_n;
  logic [1:0] g_io_resp_bits_resp_entry_5_pbmt, i_io_resp_bits_resp_entry_5_pbmt;
  logic g_io_resp_bits_resp_entry_5_perm_d, i_io_resp_bits_resp_entry_5_perm_d;
  logic g_io_resp_bits_resp_entry_5_perm_a, i_io_resp_bits_resp_entry_5_perm_a;
  logic g_io_resp_bits_resp_entry_5_perm_g, i_io_resp_bits_resp_entry_5_perm_g;
  logic g_io_resp_bits_resp_entry_5_perm_u, i_io_resp_bits_resp_entry_5_perm_u;
  logic g_io_resp_bits_resp_entry_5_perm_x, i_io_resp_bits_resp_entry_5_perm_x;
  logic g_io_resp_bits_resp_entry_5_perm_w, i_io_resp_bits_resp_entry_5_perm_w;
  logic g_io_resp_bits_resp_entry_5_perm_r, i_io_resp_bits_resp_entry_5_perm_r;
  logic [1:0] g_io_resp_bits_resp_entry_5_level, i_io_resp_bits_resp_entry_5_level;
  logic g_io_resp_bits_resp_entry_5_v, i_io_resp_bits_resp_entry_5_v;
  logic [40:0] g_io_resp_bits_resp_entry_5_ppn, i_io_resp_bits_resp_entry_5_ppn;
  logic [2:0] g_io_resp_bits_resp_entry_5_ppn_low, i_io_resp_bits_resp_entry_5_ppn_low;
  logic g_io_resp_bits_resp_entry_5_af, i_io_resp_bits_resp_entry_5_af;
  logic g_io_resp_bits_resp_entry_5_pf, i_io_resp_bits_resp_entry_5_pf;
  logic g_io_resp_bits_resp_entry_5_cf, i_io_resp_bits_resp_entry_5_cf;
  logic [34:0] g_io_resp_bits_resp_entry_6_tag, i_io_resp_bits_resp_entry_6_tag;
  logic [15:0] g_io_resp_bits_resp_entry_6_asid, i_io_resp_bits_resp_entry_6_asid;
  logic [13:0] g_io_resp_bits_resp_entry_6_vmid, i_io_resp_bits_resp_entry_6_vmid;
  logic g_io_resp_bits_resp_entry_6_n, i_io_resp_bits_resp_entry_6_n;
  logic [1:0] g_io_resp_bits_resp_entry_6_pbmt, i_io_resp_bits_resp_entry_6_pbmt;
  logic g_io_resp_bits_resp_entry_6_perm_d, i_io_resp_bits_resp_entry_6_perm_d;
  logic g_io_resp_bits_resp_entry_6_perm_a, i_io_resp_bits_resp_entry_6_perm_a;
  logic g_io_resp_bits_resp_entry_6_perm_g, i_io_resp_bits_resp_entry_6_perm_g;
  logic g_io_resp_bits_resp_entry_6_perm_u, i_io_resp_bits_resp_entry_6_perm_u;
  logic g_io_resp_bits_resp_entry_6_perm_x, i_io_resp_bits_resp_entry_6_perm_x;
  logic g_io_resp_bits_resp_entry_6_perm_w, i_io_resp_bits_resp_entry_6_perm_w;
  logic g_io_resp_bits_resp_entry_6_perm_r, i_io_resp_bits_resp_entry_6_perm_r;
  logic [1:0] g_io_resp_bits_resp_entry_6_level, i_io_resp_bits_resp_entry_6_level;
  logic g_io_resp_bits_resp_entry_6_v, i_io_resp_bits_resp_entry_6_v;
  logic [40:0] g_io_resp_bits_resp_entry_6_ppn, i_io_resp_bits_resp_entry_6_ppn;
  logic [2:0] g_io_resp_bits_resp_entry_6_ppn_low, i_io_resp_bits_resp_entry_6_ppn_low;
  logic g_io_resp_bits_resp_entry_6_af, i_io_resp_bits_resp_entry_6_af;
  logic g_io_resp_bits_resp_entry_6_pf, i_io_resp_bits_resp_entry_6_pf;
  logic g_io_resp_bits_resp_entry_6_cf, i_io_resp_bits_resp_entry_6_cf;
  logic [34:0] g_io_resp_bits_resp_entry_7_tag, i_io_resp_bits_resp_entry_7_tag;
  logic [15:0] g_io_resp_bits_resp_entry_7_asid, i_io_resp_bits_resp_entry_7_asid;
  logic [13:0] g_io_resp_bits_resp_entry_7_vmid, i_io_resp_bits_resp_entry_7_vmid;
  logic g_io_resp_bits_resp_entry_7_n, i_io_resp_bits_resp_entry_7_n;
  logic [1:0] g_io_resp_bits_resp_entry_7_pbmt, i_io_resp_bits_resp_entry_7_pbmt;
  logic g_io_resp_bits_resp_entry_7_perm_d, i_io_resp_bits_resp_entry_7_perm_d;
  logic g_io_resp_bits_resp_entry_7_perm_a, i_io_resp_bits_resp_entry_7_perm_a;
  logic g_io_resp_bits_resp_entry_7_perm_g, i_io_resp_bits_resp_entry_7_perm_g;
  logic g_io_resp_bits_resp_entry_7_perm_u, i_io_resp_bits_resp_entry_7_perm_u;
  logic g_io_resp_bits_resp_entry_7_perm_x, i_io_resp_bits_resp_entry_7_perm_x;
  logic g_io_resp_bits_resp_entry_7_perm_w, i_io_resp_bits_resp_entry_7_perm_w;
  logic g_io_resp_bits_resp_entry_7_perm_r, i_io_resp_bits_resp_entry_7_perm_r;
  logic [1:0] g_io_resp_bits_resp_entry_7_level, i_io_resp_bits_resp_entry_7_level;
  logic g_io_resp_bits_resp_entry_7_v, i_io_resp_bits_resp_entry_7_v;
  logic [40:0] g_io_resp_bits_resp_entry_7_ppn, i_io_resp_bits_resp_entry_7_ppn;
  logic [2:0] g_io_resp_bits_resp_entry_7_ppn_low, i_io_resp_bits_resp_entry_7_ppn_low;
  logic g_io_resp_bits_resp_entry_7_af, i_io_resp_bits_resp_entry_7_af;
  logic g_io_resp_bits_resp_entry_7_pf, i_io_resp_bits_resp_entry_7_pf;
  logic g_io_resp_bits_resp_entry_7_cf, i_io_resp_bits_resp_entry_7_cf;
  logic g_io_resp_bits_resp_pteidx_0, i_io_resp_bits_resp_pteidx_0;
  logic g_io_resp_bits_resp_pteidx_1, i_io_resp_bits_resp_pteidx_1;
  logic g_io_resp_bits_resp_pteidx_2, i_io_resp_bits_resp_pteidx_2;
  logic g_io_resp_bits_resp_pteidx_3, i_io_resp_bits_resp_pteidx_3;
  logic g_io_resp_bits_resp_pteidx_4, i_io_resp_bits_resp_pteidx_4;
  logic g_io_resp_bits_resp_pteidx_5, i_io_resp_bits_resp_pteidx_5;
  logic g_io_resp_bits_resp_pteidx_6, i_io_resp_bits_resp_pteidx_6;
  logic g_io_resp_bits_resp_pteidx_7, i_io_resp_bits_resp_pteidx_7;
  logic g_io_resp_bits_resp_not_super, i_io_resp_bits_resp_not_super;
  logic [37:0] g_io_resp_bits_h_resp_entry_tag, i_io_resp_bits_h_resp_entry_tag;
  logic [13:0] g_io_resp_bits_h_resp_entry_vmid, i_io_resp_bits_h_resp_entry_vmid;
  logic g_io_resp_bits_h_resp_entry_n, i_io_resp_bits_h_resp_entry_n;
  logic [1:0] g_io_resp_bits_h_resp_entry_pbmt, i_io_resp_bits_h_resp_entry_pbmt;
  logic [37:0] g_io_resp_bits_h_resp_entry_ppn, i_io_resp_bits_h_resp_entry_ppn;
  logic g_io_resp_bits_h_resp_entry_perm_d, i_io_resp_bits_h_resp_entry_perm_d;
  logic g_io_resp_bits_h_resp_entry_perm_a, i_io_resp_bits_h_resp_entry_perm_a;
  logic g_io_resp_bits_h_resp_entry_perm_g, i_io_resp_bits_h_resp_entry_perm_g;
  logic g_io_resp_bits_h_resp_entry_perm_u, i_io_resp_bits_h_resp_entry_perm_u;
  logic g_io_resp_bits_h_resp_entry_perm_x, i_io_resp_bits_h_resp_entry_perm_x;
  logic g_io_resp_bits_h_resp_entry_perm_w, i_io_resp_bits_h_resp_entry_perm_w;
  logic g_io_resp_bits_h_resp_entry_perm_r, i_io_resp_bits_h_resp_entry_perm_r;
  logic [1:0] g_io_resp_bits_h_resp_entry_level, i_io_resp_bits_h_resp_entry_level;
  logic g_io_resp_bits_h_resp_gpf, i_io_resp_bits_h_resp_gpf;
  logic g_io_resp_bits_h_resp_gaf, i_io_resp_bits_h_resp_gaf;
  logic g_io_llptw_valid, i_io_llptw_valid;
  logic [37:0] g_io_llptw_bits_req_info_vpn, i_io_llptw_bits_req_info_vpn;
  logic [1:0] g_io_llptw_bits_req_info_s2xlate, i_io_llptw_bits_req_info_s2xlate;
  logic [1:0] g_io_llptw_bits_req_info_source, i_io_llptw_bits_req_info_source;
  logic g_io_hptw_req_valid, i_io_hptw_req_valid;
  logic [1:0] g_io_hptw_req_bits_source, i_io_hptw_req_bits_source;
  logic [43:0] g_io_hptw_req_bits_gvpn, i_io_hptw_req_bits_gvpn;
  logic g_io_mem_req_valid, i_io_mem_req_valid;
  logic [47:0] g_io_mem_req_bits_addr, i_io_mem_req_bits_addr;
  logic [47:0] g_io_pmp_req_bits_addr, i_io_pmp_req_bits_addr;
  logic [37:0] g_io_refill_req_info_vpn, i_io_refill_req_info_vpn;
  logic [1:0] g_io_refill_req_info_s2xlate, i_io_refill_req_info_s2xlate;
  logic [1:0] g_io_refill_req_info_source, i_io_refill_req_info_source;
  logic [1:0] g_io_refill_level, i_io_refill_level;
  logic g_io_bitmap_req_valid, i_io_bitmap_req_valid;
  logic [35:0] g_io_bitmap_req_bits_bmppn, i_io_bitmap_req_bits_bmppn;
  logic [37:0] g_io_bitmap_req_bits_vpn, i_io_bitmap_req_bits_vpn;
  logic [1:0] g_io_bitmap_req_bits_level, i_io_bitmap_req_bits_level;
  logic [1:0] g_io_bitmap_req_bits_s2xlate, i_io_bitmap_req_bits_s2xlate;
  logic g_io_bitmap_req_bits_n, i_io_bitmap_req_bits_n;
  logic g_io_bitmap_resp_ready, i_io_bitmap_resp_ready;
  logic [5:0] g_io_perf_0_value, i_io_perf_0_value;
  logic [5:0] g_io_perf_1_value, i_io_perf_1_value;
  logic [5:0] g_io_perf_2_value, i_io_perf_2_value;
  logic [5:0] g_io_perf_3_value, i_io_perf_3_value;
  logic [5:0] g_io_perf_4_value, i_io_perf_4_value;
  logic [5:0] g_io_perf_5_value, i_io_perf_5_value;
  logic [5:0] g_io_perf_6_value, i_io_perf_6_value;
  PTW u_g (
    .clock(clock), .reset(reset),
    .io_sfence_valid                          (io_sfence_valid),
    .io_csr_satp_mode                         (io_csr_satp_mode),
    .io_csr_satp_asid                         (io_csr_satp_asid),
    .io_csr_satp_ppn                          (io_csr_satp_ppn),
    .io_csr_satp_changed                      (io_csr_satp_changed),
    .io_csr_vsatp_mode                        (io_csr_vsatp_mode),
    .io_csr_vsatp_asid                        (io_csr_vsatp_asid),
    .io_csr_vsatp_ppn                         (io_csr_vsatp_ppn),
    .io_csr_vsatp_changed                     (io_csr_vsatp_changed),
    .io_csr_hgatp_mode                        (io_csr_hgatp_mode),
    .io_csr_hgatp_vmid                        (io_csr_hgatp_vmid),
    .io_csr_hgatp_changed                     (io_csr_hgatp_changed),
    .io_csr_mbmc_BME                          (io_csr_mbmc_BME),
    .io_csr_mbmc_CMODE                        (io_csr_mbmc_CMODE),
    .io_csr_priv_virt_changed                 (io_csr_priv_virt_changed),
    .io_csr_mPBMTE                            (io_csr_mPBMTE),
    .io_csr_hPBMTE                            (io_csr_hPBMTE),
    .io_req_ready                             (g_io_req_ready),
    .io_req_valid                             (io_req_valid),
    .io_req_bits_req_info_vpn                 (io_req_bits_req_info_vpn),
    .io_req_bits_req_info_s2xlate             (io_req_bits_req_info_s2xlate),
    .io_req_bits_req_info_source              (io_req_bits_req_info_source),
    .io_req_bits_l3Hit                        (io_req_bits_l3Hit),
    .io_req_bits_l2Hit                        (io_req_bits_l2Hit),
    .io_req_bits_ppn                          (io_req_bits_ppn),
    .io_req_bits_stage1Hit                    (io_req_bits_stage1Hit),
    .io_req_bits_stage1_entry_0_tag           (io_req_bits_stage1_entry_0_tag),
    .io_req_bits_stage1_entry_0_asid          (io_req_bits_stage1_entry_0_asid),
    .io_req_bits_stage1_entry_0_vmid          (io_req_bits_stage1_entry_0_vmid),
    .io_req_bits_stage1_entry_0_n             (io_req_bits_stage1_entry_0_n),
    .io_req_bits_stage1_entry_0_pbmt          (io_req_bits_stage1_entry_0_pbmt),
    .io_req_bits_stage1_entry_0_perm_d        (io_req_bits_stage1_entry_0_perm_d),
    .io_req_bits_stage1_entry_0_perm_a        (io_req_bits_stage1_entry_0_perm_a),
    .io_req_bits_stage1_entry_0_perm_g        (io_req_bits_stage1_entry_0_perm_g),
    .io_req_bits_stage1_entry_0_perm_u        (io_req_bits_stage1_entry_0_perm_u),
    .io_req_bits_stage1_entry_0_perm_x        (io_req_bits_stage1_entry_0_perm_x),
    .io_req_bits_stage1_entry_0_perm_w        (io_req_bits_stage1_entry_0_perm_w),
    .io_req_bits_stage1_entry_0_perm_r        (io_req_bits_stage1_entry_0_perm_r),
    .io_req_bits_stage1_entry_0_level         (io_req_bits_stage1_entry_0_level),
    .io_req_bits_stage1_entry_0_v             (io_req_bits_stage1_entry_0_v),
    .io_req_bits_stage1_entry_0_ppn           (io_req_bits_stage1_entry_0_ppn),
    .io_req_bits_stage1_entry_0_ppn_low       (io_req_bits_stage1_entry_0_ppn_low),
    .io_req_bits_stage1_entry_0_pf            (io_req_bits_stage1_entry_0_pf),
    .io_req_bits_stage1_entry_0_cf            (io_req_bits_stage1_entry_0_cf),
    .io_req_bits_stage1_entry_1_tag           (io_req_bits_stage1_entry_1_tag),
    .io_req_bits_stage1_entry_1_asid          (io_req_bits_stage1_entry_1_asid),
    .io_req_bits_stage1_entry_1_vmid          (io_req_bits_stage1_entry_1_vmid),
    .io_req_bits_stage1_entry_1_n             (io_req_bits_stage1_entry_1_n),
    .io_req_bits_stage1_entry_1_pbmt          (io_req_bits_stage1_entry_1_pbmt),
    .io_req_bits_stage1_entry_1_perm_d        (io_req_bits_stage1_entry_1_perm_d),
    .io_req_bits_stage1_entry_1_perm_a        (io_req_bits_stage1_entry_1_perm_a),
    .io_req_bits_stage1_entry_1_perm_g        (io_req_bits_stage1_entry_1_perm_g),
    .io_req_bits_stage1_entry_1_perm_u        (io_req_bits_stage1_entry_1_perm_u),
    .io_req_bits_stage1_entry_1_perm_x        (io_req_bits_stage1_entry_1_perm_x),
    .io_req_bits_stage1_entry_1_perm_w        (io_req_bits_stage1_entry_1_perm_w),
    .io_req_bits_stage1_entry_1_perm_r        (io_req_bits_stage1_entry_1_perm_r),
    .io_req_bits_stage1_entry_1_level         (io_req_bits_stage1_entry_1_level),
    .io_req_bits_stage1_entry_1_v             (io_req_bits_stage1_entry_1_v),
    .io_req_bits_stage1_entry_1_ppn           (io_req_bits_stage1_entry_1_ppn),
    .io_req_bits_stage1_entry_1_ppn_low       (io_req_bits_stage1_entry_1_ppn_low),
    .io_req_bits_stage1_entry_1_pf            (io_req_bits_stage1_entry_1_pf),
    .io_req_bits_stage1_entry_1_cf            (io_req_bits_stage1_entry_1_cf),
    .io_req_bits_stage1_entry_2_tag           (io_req_bits_stage1_entry_2_tag),
    .io_req_bits_stage1_entry_2_asid          (io_req_bits_stage1_entry_2_asid),
    .io_req_bits_stage1_entry_2_vmid          (io_req_bits_stage1_entry_2_vmid),
    .io_req_bits_stage1_entry_2_n             (io_req_bits_stage1_entry_2_n),
    .io_req_bits_stage1_entry_2_pbmt          (io_req_bits_stage1_entry_2_pbmt),
    .io_req_bits_stage1_entry_2_perm_d        (io_req_bits_stage1_entry_2_perm_d),
    .io_req_bits_stage1_entry_2_perm_a        (io_req_bits_stage1_entry_2_perm_a),
    .io_req_bits_stage1_entry_2_perm_g        (io_req_bits_stage1_entry_2_perm_g),
    .io_req_bits_stage1_entry_2_perm_u        (io_req_bits_stage1_entry_2_perm_u),
    .io_req_bits_stage1_entry_2_perm_x        (io_req_bits_stage1_entry_2_perm_x),
    .io_req_bits_stage1_entry_2_perm_w        (io_req_bits_stage1_entry_2_perm_w),
    .io_req_bits_stage1_entry_2_perm_r        (io_req_bits_stage1_entry_2_perm_r),
    .io_req_bits_stage1_entry_2_level         (io_req_bits_stage1_entry_2_level),
    .io_req_bits_stage1_entry_2_v             (io_req_bits_stage1_entry_2_v),
    .io_req_bits_stage1_entry_2_ppn           (io_req_bits_stage1_entry_2_ppn),
    .io_req_bits_stage1_entry_2_ppn_low       (io_req_bits_stage1_entry_2_ppn_low),
    .io_req_bits_stage1_entry_2_pf            (io_req_bits_stage1_entry_2_pf),
    .io_req_bits_stage1_entry_2_cf            (io_req_bits_stage1_entry_2_cf),
    .io_req_bits_stage1_entry_3_tag           (io_req_bits_stage1_entry_3_tag),
    .io_req_bits_stage1_entry_3_asid          (io_req_bits_stage1_entry_3_asid),
    .io_req_bits_stage1_entry_3_vmid          (io_req_bits_stage1_entry_3_vmid),
    .io_req_bits_stage1_entry_3_n             (io_req_bits_stage1_entry_3_n),
    .io_req_bits_stage1_entry_3_pbmt          (io_req_bits_stage1_entry_3_pbmt),
    .io_req_bits_stage1_entry_3_perm_d        (io_req_bits_stage1_entry_3_perm_d),
    .io_req_bits_stage1_entry_3_perm_a        (io_req_bits_stage1_entry_3_perm_a),
    .io_req_bits_stage1_entry_3_perm_g        (io_req_bits_stage1_entry_3_perm_g),
    .io_req_bits_stage1_entry_3_perm_u        (io_req_bits_stage1_entry_3_perm_u),
    .io_req_bits_stage1_entry_3_perm_x        (io_req_bits_stage1_entry_3_perm_x),
    .io_req_bits_stage1_entry_3_perm_w        (io_req_bits_stage1_entry_3_perm_w),
    .io_req_bits_stage1_entry_3_perm_r        (io_req_bits_stage1_entry_3_perm_r),
    .io_req_bits_stage1_entry_3_level         (io_req_bits_stage1_entry_3_level),
    .io_req_bits_stage1_entry_3_v             (io_req_bits_stage1_entry_3_v),
    .io_req_bits_stage1_entry_3_ppn           (io_req_bits_stage1_entry_3_ppn),
    .io_req_bits_stage1_entry_3_ppn_low       (io_req_bits_stage1_entry_3_ppn_low),
    .io_req_bits_stage1_entry_3_pf            (io_req_bits_stage1_entry_3_pf),
    .io_req_bits_stage1_entry_3_cf            (io_req_bits_stage1_entry_3_cf),
    .io_req_bits_stage1_entry_4_tag           (io_req_bits_stage1_entry_4_tag),
    .io_req_bits_stage1_entry_4_asid          (io_req_bits_stage1_entry_4_asid),
    .io_req_bits_stage1_entry_4_vmid          (io_req_bits_stage1_entry_4_vmid),
    .io_req_bits_stage1_entry_4_n             (io_req_bits_stage1_entry_4_n),
    .io_req_bits_stage1_entry_4_pbmt          (io_req_bits_stage1_entry_4_pbmt),
    .io_req_bits_stage1_entry_4_perm_d        (io_req_bits_stage1_entry_4_perm_d),
    .io_req_bits_stage1_entry_4_perm_a        (io_req_bits_stage1_entry_4_perm_a),
    .io_req_bits_stage1_entry_4_perm_g        (io_req_bits_stage1_entry_4_perm_g),
    .io_req_bits_stage1_entry_4_perm_u        (io_req_bits_stage1_entry_4_perm_u),
    .io_req_bits_stage1_entry_4_perm_x        (io_req_bits_stage1_entry_4_perm_x),
    .io_req_bits_stage1_entry_4_perm_w        (io_req_bits_stage1_entry_4_perm_w),
    .io_req_bits_stage1_entry_4_perm_r        (io_req_bits_stage1_entry_4_perm_r),
    .io_req_bits_stage1_entry_4_level         (io_req_bits_stage1_entry_4_level),
    .io_req_bits_stage1_entry_4_v             (io_req_bits_stage1_entry_4_v),
    .io_req_bits_stage1_entry_4_ppn           (io_req_bits_stage1_entry_4_ppn),
    .io_req_bits_stage1_entry_4_ppn_low       (io_req_bits_stage1_entry_4_ppn_low),
    .io_req_bits_stage1_entry_4_pf            (io_req_bits_stage1_entry_4_pf),
    .io_req_bits_stage1_entry_4_cf            (io_req_bits_stage1_entry_4_cf),
    .io_req_bits_stage1_entry_5_tag           (io_req_bits_stage1_entry_5_tag),
    .io_req_bits_stage1_entry_5_asid          (io_req_bits_stage1_entry_5_asid),
    .io_req_bits_stage1_entry_5_vmid          (io_req_bits_stage1_entry_5_vmid),
    .io_req_bits_stage1_entry_5_n             (io_req_bits_stage1_entry_5_n),
    .io_req_bits_stage1_entry_5_pbmt          (io_req_bits_stage1_entry_5_pbmt),
    .io_req_bits_stage1_entry_5_perm_d        (io_req_bits_stage1_entry_5_perm_d),
    .io_req_bits_stage1_entry_5_perm_a        (io_req_bits_stage1_entry_5_perm_a),
    .io_req_bits_stage1_entry_5_perm_g        (io_req_bits_stage1_entry_5_perm_g),
    .io_req_bits_stage1_entry_5_perm_u        (io_req_bits_stage1_entry_5_perm_u),
    .io_req_bits_stage1_entry_5_perm_x        (io_req_bits_stage1_entry_5_perm_x),
    .io_req_bits_stage1_entry_5_perm_w        (io_req_bits_stage1_entry_5_perm_w),
    .io_req_bits_stage1_entry_5_perm_r        (io_req_bits_stage1_entry_5_perm_r),
    .io_req_bits_stage1_entry_5_level         (io_req_bits_stage1_entry_5_level),
    .io_req_bits_stage1_entry_5_v             (io_req_bits_stage1_entry_5_v),
    .io_req_bits_stage1_entry_5_ppn           (io_req_bits_stage1_entry_5_ppn),
    .io_req_bits_stage1_entry_5_ppn_low       (io_req_bits_stage1_entry_5_ppn_low),
    .io_req_bits_stage1_entry_5_pf            (io_req_bits_stage1_entry_5_pf),
    .io_req_bits_stage1_entry_5_cf            (io_req_bits_stage1_entry_5_cf),
    .io_req_bits_stage1_entry_6_tag           (io_req_bits_stage1_entry_6_tag),
    .io_req_bits_stage1_entry_6_asid          (io_req_bits_stage1_entry_6_asid),
    .io_req_bits_stage1_entry_6_vmid          (io_req_bits_stage1_entry_6_vmid),
    .io_req_bits_stage1_entry_6_n             (io_req_bits_stage1_entry_6_n),
    .io_req_bits_stage1_entry_6_pbmt          (io_req_bits_stage1_entry_6_pbmt),
    .io_req_bits_stage1_entry_6_perm_d        (io_req_bits_stage1_entry_6_perm_d),
    .io_req_bits_stage1_entry_6_perm_a        (io_req_bits_stage1_entry_6_perm_a),
    .io_req_bits_stage1_entry_6_perm_g        (io_req_bits_stage1_entry_6_perm_g),
    .io_req_bits_stage1_entry_6_perm_u        (io_req_bits_stage1_entry_6_perm_u),
    .io_req_bits_stage1_entry_6_perm_x        (io_req_bits_stage1_entry_6_perm_x),
    .io_req_bits_stage1_entry_6_perm_w        (io_req_bits_stage1_entry_6_perm_w),
    .io_req_bits_stage1_entry_6_perm_r        (io_req_bits_stage1_entry_6_perm_r),
    .io_req_bits_stage1_entry_6_level         (io_req_bits_stage1_entry_6_level),
    .io_req_bits_stage1_entry_6_v             (io_req_bits_stage1_entry_6_v),
    .io_req_bits_stage1_entry_6_ppn           (io_req_bits_stage1_entry_6_ppn),
    .io_req_bits_stage1_entry_6_ppn_low       (io_req_bits_stage1_entry_6_ppn_low),
    .io_req_bits_stage1_entry_6_pf            (io_req_bits_stage1_entry_6_pf),
    .io_req_bits_stage1_entry_6_cf            (io_req_bits_stage1_entry_6_cf),
    .io_req_bits_stage1_entry_7_tag           (io_req_bits_stage1_entry_7_tag),
    .io_req_bits_stage1_entry_7_asid          (io_req_bits_stage1_entry_7_asid),
    .io_req_bits_stage1_entry_7_vmid          (io_req_bits_stage1_entry_7_vmid),
    .io_req_bits_stage1_entry_7_n             (io_req_bits_stage1_entry_7_n),
    .io_req_bits_stage1_entry_7_pbmt          (io_req_bits_stage1_entry_7_pbmt),
    .io_req_bits_stage1_entry_7_perm_d        (io_req_bits_stage1_entry_7_perm_d),
    .io_req_bits_stage1_entry_7_perm_a        (io_req_bits_stage1_entry_7_perm_a),
    .io_req_bits_stage1_entry_7_perm_g        (io_req_bits_stage1_entry_7_perm_g),
    .io_req_bits_stage1_entry_7_perm_u        (io_req_bits_stage1_entry_7_perm_u),
    .io_req_bits_stage1_entry_7_perm_x        (io_req_bits_stage1_entry_7_perm_x),
    .io_req_bits_stage1_entry_7_perm_w        (io_req_bits_stage1_entry_7_perm_w),
    .io_req_bits_stage1_entry_7_perm_r        (io_req_bits_stage1_entry_7_perm_r),
    .io_req_bits_stage1_entry_7_level         (io_req_bits_stage1_entry_7_level),
    .io_req_bits_stage1_entry_7_v             (io_req_bits_stage1_entry_7_v),
    .io_req_bits_stage1_entry_7_ppn           (io_req_bits_stage1_entry_7_ppn),
    .io_req_bits_stage1_entry_7_ppn_low       (io_req_bits_stage1_entry_7_ppn_low),
    .io_req_bits_stage1_entry_7_pf            (io_req_bits_stage1_entry_7_pf),
    .io_req_bits_stage1_entry_7_cf            (io_req_bits_stage1_entry_7_cf),
    .io_req_bits_stage1_pteidx_0              (io_req_bits_stage1_pteidx_0),
    .io_req_bits_stage1_pteidx_1              (io_req_bits_stage1_pteidx_1),
    .io_req_bits_stage1_pteidx_2              (io_req_bits_stage1_pteidx_2),
    .io_req_bits_stage1_pteidx_3              (io_req_bits_stage1_pteidx_3),
    .io_req_bits_stage1_pteidx_4              (io_req_bits_stage1_pteidx_4),
    .io_req_bits_stage1_pteidx_5              (io_req_bits_stage1_pteidx_5),
    .io_req_bits_stage1_pteidx_6              (io_req_bits_stage1_pteidx_6),
    .io_req_bits_stage1_pteidx_7              (io_req_bits_stage1_pteidx_7),
    .io_req_bits_stage1_not_super             (io_req_bits_stage1_not_super),
    .io_req_bits_bitmapCheck_jmp_bitmap_check (io_req_bits_bitmapCheck_jmp_bitmap_check),
    .io_req_bits_bitmapCheck_pte              (io_req_bits_bitmapCheck_pte),
    .io_req_bits_bitmapCheck_SPlevel          (io_req_bits_bitmapCheck_SPlevel),
    .io_resp_ready                            (io_resp_ready),
    .io_resp_valid                            (g_io_resp_valid),
    .io_resp_bits_source                      (g_io_resp_bits_source),
    .io_resp_bits_s2xlate                     (g_io_resp_bits_s2xlate),
    .io_resp_bits_resp_entry_0_tag            (g_io_resp_bits_resp_entry_0_tag),
    .io_resp_bits_resp_entry_0_asid           (g_io_resp_bits_resp_entry_0_asid),
    .io_resp_bits_resp_entry_0_vmid           (g_io_resp_bits_resp_entry_0_vmid),
    .io_resp_bits_resp_entry_0_n              (g_io_resp_bits_resp_entry_0_n),
    .io_resp_bits_resp_entry_0_pbmt           (g_io_resp_bits_resp_entry_0_pbmt),
    .io_resp_bits_resp_entry_0_perm_d         (g_io_resp_bits_resp_entry_0_perm_d),
    .io_resp_bits_resp_entry_0_perm_a         (g_io_resp_bits_resp_entry_0_perm_a),
    .io_resp_bits_resp_entry_0_perm_g         (g_io_resp_bits_resp_entry_0_perm_g),
    .io_resp_bits_resp_entry_0_perm_u         (g_io_resp_bits_resp_entry_0_perm_u),
    .io_resp_bits_resp_entry_0_perm_x         (g_io_resp_bits_resp_entry_0_perm_x),
    .io_resp_bits_resp_entry_0_perm_w         (g_io_resp_bits_resp_entry_0_perm_w),
    .io_resp_bits_resp_entry_0_perm_r         (g_io_resp_bits_resp_entry_0_perm_r),
    .io_resp_bits_resp_entry_0_level          (g_io_resp_bits_resp_entry_0_level),
    .io_resp_bits_resp_entry_0_v              (g_io_resp_bits_resp_entry_0_v),
    .io_resp_bits_resp_entry_0_ppn            (g_io_resp_bits_resp_entry_0_ppn),
    .io_resp_bits_resp_entry_0_ppn_low        (g_io_resp_bits_resp_entry_0_ppn_low),
    .io_resp_bits_resp_entry_0_af             (g_io_resp_bits_resp_entry_0_af),
    .io_resp_bits_resp_entry_0_pf             (g_io_resp_bits_resp_entry_0_pf),
    .io_resp_bits_resp_entry_0_cf             (g_io_resp_bits_resp_entry_0_cf),
    .io_resp_bits_resp_entry_1_tag            (g_io_resp_bits_resp_entry_1_tag),
    .io_resp_bits_resp_entry_1_asid           (g_io_resp_bits_resp_entry_1_asid),
    .io_resp_bits_resp_entry_1_vmid           (g_io_resp_bits_resp_entry_1_vmid),
    .io_resp_bits_resp_entry_1_n              (g_io_resp_bits_resp_entry_1_n),
    .io_resp_bits_resp_entry_1_pbmt           (g_io_resp_bits_resp_entry_1_pbmt),
    .io_resp_bits_resp_entry_1_perm_d         (g_io_resp_bits_resp_entry_1_perm_d),
    .io_resp_bits_resp_entry_1_perm_a         (g_io_resp_bits_resp_entry_1_perm_a),
    .io_resp_bits_resp_entry_1_perm_g         (g_io_resp_bits_resp_entry_1_perm_g),
    .io_resp_bits_resp_entry_1_perm_u         (g_io_resp_bits_resp_entry_1_perm_u),
    .io_resp_bits_resp_entry_1_perm_x         (g_io_resp_bits_resp_entry_1_perm_x),
    .io_resp_bits_resp_entry_1_perm_w         (g_io_resp_bits_resp_entry_1_perm_w),
    .io_resp_bits_resp_entry_1_perm_r         (g_io_resp_bits_resp_entry_1_perm_r),
    .io_resp_bits_resp_entry_1_level          (g_io_resp_bits_resp_entry_1_level),
    .io_resp_bits_resp_entry_1_v              (g_io_resp_bits_resp_entry_1_v),
    .io_resp_bits_resp_entry_1_ppn            (g_io_resp_bits_resp_entry_1_ppn),
    .io_resp_bits_resp_entry_1_ppn_low        (g_io_resp_bits_resp_entry_1_ppn_low),
    .io_resp_bits_resp_entry_1_af             (g_io_resp_bits_resp_entry_1_af),
    .io_resp_bits_resp_entry_1_pf             (g_io_resp_bits_resp_entry_1_pf),
    .io_resp_bits_resp_entry_1_cf             (g_io_resp_bits_resp_entry_1_cf),
    .io_resp_bits_resp_entry_2_tag            (g_io_resp_bits_resp_entry_2_tag),
    .io_resp_bits_resp_entry_2_asid           (g_io_resp_bits_resp_entry_2_asid),
    .io_resp_bits_resp_entry_2_vmid           (g_io_resp_bits_resp_entry_2_vmid),
    .io_resp_bits_resp_entry_2_n              (g_io_resp_bits_resp_entry_2_n),
    .io_resp_bits_resp_entry_2_pbmt           (g_io_resp_bits_resp_entry_2_pbmt),
    .io_resp_bits_resp_entry_2_perm_d         (g_io_resp_bits_resp_entry_2_perm_d),
    .io_resp_bits_resp_entry_2_perm_a         (g_io_resp_bits_resp_entry_2_perm_a),
    .io_resp_bits_resp_entry_2_perm_g         (g_io_resp_bits_resp_entry_2_perm_g),
    .io_resp_bits_resp_entry_2_perm_u         (g_io_resp_bits_resp_entry_2_perm_u),
    .io_resp_bits_resp_entry_2_perm_x         (g_io_resp_bits_resp_entry_2_perm_x),
    .io_resp_bits_resp_entry_2_perm_w         (g_io_resp_bits_resp_entry_2_perm_w),
    .io_resp_bits_resp_entry_2_perm_r         (g_io_resp_bits_resp_entry_2_perm_r),
    .io_resp_bits_resp_entry_2_level          (g_io_resp_bits_resp_entry_2_level),
    .io_resp_bits_resp_entry_2_v              (g_io_resp_bits_resp_entry_2_v),
    .io_resp_bits_resp_entry_2_ppn            (g_io_resp_bits_resp_entry_2_ppn),
    .io_resp_bits_resp_entry_2_ppn_low        (g_io_resp_bits_resp_entry_2_ppn_low),
    .io_resp_bits_resp_entry_2_af             (g_io_resp_bits_resp_entry_2_af),
    .io_resp_bits_resp_entry_2_pf             (g_io_resp_bits_resp_entry_2_pf),
    .io_resp_bits_resp_entry_2_cf             (g_io_resp_bits_resp_entry_2_cf),
    .io_resp_bits_resp_entry_3_tag            (g_io_resp_bits_resp_entry_3_tag),
    .io_resp_bits_resp_entry_3_asid           (g_io_resp_bits_resp_entry_3_asid),
    .io_resp_bits_resp_entry_3_vmid           (g_io_resp_bits_resp_entry_3_vmid),
    .io_resp_bits_resp_entry_3_n              (g_io_resp_bits_resp_entry_3_n),
    .io_resp_bits_resp_entry_3_pbmt           (g_io_resp_bits_resp_entry_3_pbmt),
    .io_resp_bits_resp_entry_3_perm_d         (g_io_resp_bits_resp_entry_3_perm_d),
    .io_resp_bits_resp_entry_3_perm_a         (g_io_resp_bits_resp_entry_3_perm_a),
    .io_resp_bits_resp_entry_3_perm_g         (g_io_resp_bits_resp_entry_3_perm_g),
    .io_resp_bits_resp_entry_3_perm_u         (g_io_resp_bits_resp_entry_3_perm_u),
    .io_resp_bits_resp_entry_3_perm_x         (g_io_resp_bits_resp_entry_3_perm_x),
    .io_resp_bits_resp_entry_3_perm_w         (g_io_resp_bits_resp_entry_3_perm_w),
    .io_resp_bits_resp_entry_3_perm_r         (g_io_resp_bits_resp_entry_3_perm_r),
    .io_resp_bits_resp_entry_3_level          (g_io_resp_bits_resp_entry_3_level),
    .io_resp_bits_resp_entry_3_v              (g_io_resp_bits_resp_entry_3_v),
    .io_resp_bits_resp_entry_3_ppn            (g_io_resp_bits_resp_entry_3_ppn),
    .io_resp_bits_resp_entry_3_ppn_low        (g_io_resp_bits_resp_entry_3_ppn_low),
    .io_resp_bits_resp_entry_3_af             (g_io_resp_bits_resp_entry_3_af),
    .io_resp_bits_resp_entry_3_pf             (g_io_resp_bits_resp_entry_3_pf),
    .io_resp_bits_resp_entry_3_cf             (g_io_resp_bits_resp_entry_3_cf),
    .io_resp_bits_resp_entry_4_tag            (g_io_resp_bits_resp_entry_4_tag),
    .io_resp_bits_resp_entry_4_asid           (g_io_resp_bits_resp_entry_4_asid),
    .io_resp_bits_resp_entry_4_vmid           (g_io_resp_bits_resp_entry_4_vmid),
    .io_resp_bits_resp_entry_4_n              (g_io_resp_bits_resp_entry_4_n),
    .io_resp_bits_resp_entry_4_pbmt           (g_io_resp_bits_resp_entry_4_pbmt),
    .io_resp_bits_resp_entry_4_perm_d         (g_io_resp_bits_resp_entry_4_perm_d),
    .io_resp_bits_resp_entry_4_perm_a         (g_io_resp_bits_resp_entry_4_perm_a),
    .io_resp_bits_resp_entry_4_perm_g         (g_io_resp_bits_resp_entry_4_perm_g),
    .io_resp_bits_resp_entry_4_perm_u         (g_io_resp_bits_resp_entry_4_perm_u),
    .io_resp_bits_resp_entry_4_perm_x         (g_io_resp_bits_resp_entry_4_perm_x),
    .io_resp_bits_resp_entry_4_perm_w         (g_io_resp_bits_resp_entry_4_perm_w),
    .io_resp_bits_resp_entry_4_perm_r         (g_io_resp_bits_resp_entry_4_perm_r),
    .io_resp_bits_resp_entry_4_level          (g_io_resp_bits_resp_entry_4_level),
    .io_resp_bits_resp_entry_4_v              (g_io_resp_bits_resp_entry_4_v),
    .io_resp_bits_resp_entry_4_ppn            (g_io_resp_bits_resp_entry_4_ppn),
    .io_resp_bits_resp_entry_4_ppn_low        (g_io_resp_bits_resp_entry_4_ppn_low),
    .io_resp_bits_resp_entry_4_af             (g_io_resp_bits_resp_entry_4_af),
    .io_resp_bits_resp_entry_4_pf             (g_io_resp_bits_resp_entry_4_pf),
    .io_resp_bits_resp_entry_4_cf             (g_io_resp_bits_resp_entry_4_cf),
    .io_resp_bits_resp_entry_5_tag            (g_io_resp_bits_resp_entry_5_tag),
    .io_resp_bits_resp_entry_5_asid           (g_io_resp_bits_resp_entry_5_asid),
    .io_resp_bits_resp_entry_5_vmid           (g_io_resp_bits_resp_entry_5_vmid),
    .io_resp_bits_resp_entry_5_n              (g_io_resp_bits_resp_entry_5_n),
    .io_resp_bits_resp_entry_5_pbmt           (g_io_resp_bits_resp_entry_5_pbmt),
    .io_resp_bits_resp_entry_5_perm_d         (g_io_resp_bits_resp_entry_5_perm_d),
    .io_resp_bits_resp_entry_5_perm_a         (g_io_resp_bits_resp_entry_5_perm_a),
    .io_resp_bits_resp_entry_5_perm_g         (g_io_resp_bits_resp_entry_5_perm_g),
    .io_resp_bits_resp_entry_5_perm_u         (g_io_resp_bits_resp_entry_5_perm_u),
    .io_resp_bits_resp_entry_5_perm_x         (g_io_resp_bits_resp_entry_5_perm_x),
    .io_resp_bits_resp_entry_5_perm_w         (g_io_resp_bits_resp_entry_5_perm_w),
    .io_resp_bits_resp_entry_5_perm_r         (g_io_resp_bits_resp_entry_5_perm_r),
    .io_resp_bits_resp_entry_5_level          (g_io_resp_bits_resp_entry_5_level),
    .io_resp_bits_resp_entry_5_v              (g_io_resp_bits_resp_entry_5_v),
    .io_resp_bits_resp_entry_5_ppn            (g_io_resp_bits_resp_entry_5_ppn),
    .io_resp_bits_resp_entry_5_ppn_low        (g_io_resp_bits_resp_entry_5_ppn_low),
    .io_resp_bits_resp_entry_5_af             (g_io_resp_bits_resp_entry_5_af),
    .io_resp_bits_resp_entry_5_pf             (g_io_resp_bits_resp_entry_5_pf),
    .io_resp_bits_resp_entry_5_cf             (g_io_resp_bits_resp_entry_5_cf),
    .io_resp_bits_resp_entry_6_tag            (g_io_resp_bits_resp_entry_6_tag),
    .io_resp_bits_resp_entry_6_asid           (g_io_resp_bits_resp_entry_6_asid),
    .io_resp_bits_resp_entry_6_vmid           (g_io_resp_bits_resp_entry_6_vmid),
    .io_resp_bits_resp_entry_6_n              (g_io_resp_bits_resp_entry_6_n),
    .io_resp_bits_resp_entry_6_pbmt           (g_io_resp_bits_resp_entry_6_pbmt),
    .io_resp_bits_resp_entry_6_perm_d         (g_io_resp_bits_resp_entry_6_perm_d),
    .io_resp_bits_resp_entry_6_perm_a         (g_io_resp_bits_resp_entry_6_perm_a),
    .io_resp_bits_resp_entry_6_perm_g         (g_io_resp_bits_resp_entry_6_perm_g),
    .io_resp_bits_resp_entry_6_perm_u         (g_io_resp_bits_resp_entry_6_perm_u),
    .io_resp_bits_resp_entry_6_perm_x         (g_io_resp_bits_resp_entry_6_perm_x),
    .io_resp_bits_resp_entry_6_perm_w         (g_io_resp_bits_resp_entry_6_perm_w),
    .io_resp_bits_resp_entry_6_perm_r         (g_io_resp_bits_resp_entry_6_perm_r),
    .io_resp_bits_resp_entry_6_level          (g_io_resp_bits_resp_entry_6_level),
    .io_resp_bits_resp_entry_6_v              (g_io_resp_bits_resp_entry_6_v),
    .io_resp_bits_resp_entry_6_ppn            (g_io_resp_bits_resp_entry_6_ppn),
    .io_resp_bits_resp_entry_6_ppn_low        (g_io_resp_bits_resp_entry_6_ppn_low),
    .io_resp_bits_resp_entry_6_af             (g_io_resp_bits_resp_entry_6_af),
    .io_resp_bits_resp_entry_6_pf             (g_io_resp_bits_resp_entry_6_pf),
    .io_resp_bits_resp_entry_6_cf             (g_io_resp_bits_resp_entry_6_cf),
    .io_resp_bits_resp_entry_7_tag            (g_io_resp_bits_resp_entry_7_tag),
    .io_resp_bits_resp_entry_7_asid           (g_io_resp_bits_resp_entry_7_asid),
    .io_resp_bits_resp_entry_7_vmid           (g_io_resp_bits_resp_entry_7_vmid),
    .io_resp_bits_resp_entry_7_n              (g_io_resp_bits_resp_entry_7_n),
    .io_resp_bits_resp_entry_7_pbmt           (g_io_resp_bits_resp_entry_7_pbmt),
    .io_resp_bits_resp_entry_7_perm_d         (g_io_resp_bits_resp_entry_7_perm_d),
    .io_resp_bits_resp_entry_7_perm_a         (g_io_resp_bits_resp_entry_7_perm_a),
    .io_resp_bits_resp_entry_7_perm_g         (g_io_resp_bits_resp_entry_7_perm_g),
    .io_resp_bits_resp_entry_7_perm_u         (g_io_resp_bits_resp_entry_7_perm_u),
    .io_resp_bits_resp_entry_7_perm_x         (g_io_resp_bits_resp_entry_7_perm_x),
    .io_resp_bits_resp_entry_7_perm_w         (g_io_resp_bits_resp_entry_7_perm_w),
    .io_resp_bits_resp_entry_7_perm_r         (g_io_resp_bits_resp_entry_7_perm_r),
    .io_resp_bits_resp_entry_7_level          (g_io_resp_bits_resp_entry_7_level),
    .io_resp_bits_resp_entry_7_v              (g_io_resp_bits_resp_entry_7_v),
    .io_resp_bits_resp_entry_7_ppn            (g_io_resp_bits_resp_entry_7_ppn),
    .io_resp_bits_resp_entry_7_ppn_low        (g_io_resp_bits_resp_entry_7_ppn_low),
    .io_resp_bits_resp_entry_7_af             (g_io_resp_bits_resp_entry_7_af),
    .io_resp_bits_resp_entry_7_pf             (g_io_resp_bits_resp_entry_7_pf),
    .io_resp_bits_resp_entry_7_cf             (g_io_resp_bits_resp_entry_7_cf),
    .io_resp_bits_resp_pteidx_0               (g_io_resp_bits_resp_pteidx_0),
    .io_resp_bits_resp_pteidx_1               (g_io_resp_bits_resp_pteidx_1),
    .io_resp_bits_resp_pteidx_2               (g_io_resp_bits_resp_pteidx_2),
    .io_resp_bits_resp_pteidx_3               (g_io_resp_bits_resp_pteidx_3),
    .io_resp_bits_resp_pteidx_4               (g_io_resp_bits_resp_pteidx_4),
    .io_resp_bits_resp_pteidx_5               (g_io_resp_bits_resp_pteidx_5),
    .io_resp_bits_resp_pteidx_6               (g_io_resp_bits_resp_pteidx_6),
    .io_resp_bits_resp_pteidx_7               (g_io_resp_bits_resp_pteidx_7),
    .io_resp_bits_resp_not_super              (g_io_resp_bits_resp_not_super),
    .io_resp_bits_h_resp_entry_tag            (g_io_resp_bits_h_resp_entry_tag),
    .io_resp_bits_h_resp_entry_vmid           (g_io_resp_bits_h_resp_entry_vmid),
    .io_resp_bits_h_resp_entry_n              (g_io_resp_bits_h_resp_entry_n),
    .io_resp_bits_h_resp_entry_pbmt           (g_io_resp_bits_h_resp_entry_pbmt),
    .io_resp_bits_h_resp_entry_ppn            (g_io_resp_bits_h_resp_entry_ppn),
    .io_resp_bits_h_resp_entry_perm_d         (g_io_resp_bits_h_resp_entry_perm_d),
    .io_resp_bits_h_resp_entry_perm_a         (g_io_resp_bits_h_resp_entry_perm_a),
    .io_resp_bits_h_resp_entry_perm_g         (g_io_resp_bits_h_resp_entry_perm_g),
    .io_resp_bits_h_resp_entry_perm_u         (g_io_resp_bits_h_resp_entry_perm_u),
    .io_resp_bits_h_resp_entry_perm_x         (g_io_resp_bits_h_resp_entry_perm_x),
    .io_resp_bits_h_resp_entry_perm_w         (g_io_resp_bits_h_resp_entry_perm_w),
    .io_resp_bits_h_resp_entry_perm_r         (g_io_resp_bits_h_resp_entry_perm_r),
    .io_resp_bits_h_resp_entry_level          (g_io_resp_bits_h_resp_entry_level),
    .io_resp_bits_h_resp_gpf                  (g_io_resp_bits_h_resp_gpf),
    .io_resp_bits_h_resp_gaf                  (g_io_resp_bits_h_resp_gaf),
    .io_llptw_ready                           (io_llptw_ready),
    .io_llptw_valid                           (g_io_llptw_valid),
    .io_llptw_bits_req_info_vpn               (g_io_llptw_bits_req_info_vpn),
    .io_llptw_bits_req_info_s2xlate           (g_io_llptw_bits_req_info_s2xlate),
    .io_llptw_bits_req_info_source            (g_io_llptw_bits_req_info_source),
    .io_hptw_req_ready                        (io_hptw_req_ready),
    .io_hptw_req_valid                        (g_io_hptw_req_valid),
    .io_hptw_req_bits_source                  (g_io_hptw_req_bits_source),
    .io_hptw_req_bits_gvpn                    (g_io_hptw_req_bits_gvpn),
    .io_hptw_resp_valid                       (io_hptw_resp_valid),
    .io_hptw_resp_bits_h_resp_entry_tag       (io_hptw_resp_bits_h_resp_entry_tag),
    .io_hptw_resp_bits_h_resp_entry_vmid      (io_hptw_resp_bits_h_resp_entry_vmid),
    .io_hptw_resp_bits_h_resp_entry_n         (io_hptw_resp_bits_h_resp_entry_n),
    .io_hptw_resp_bits_h_resp_entry_pbmt      (io_hptw_resp_bits_h_resp_entry_pbmt),
    .io_hptw_resp_bits_h_resp_entry_ppn       (io_hptw_resp_bits_h_resp_entry_ppn),
    .io_hptw_resp_bits_h_resp_entry_perm_d    (io_hptw_resp_bits_h_resp_entry_perm_d),
    .io_hptw_resp_bits_h_resp_entry_perm_a    (io_hptw_resp_bits_h_resp_entry_perm_a),
    .io_hptw_resp_bits_h_resp_entry_perm_g    (io_hptw_resp_bits_h_resp_entry_perm_g),
    .io_hptw_resp_bits_h_resp_entry_perm_u    (io_hptw_resp_bits_h_resp_entry_perm_u),
    .io_hptw_resp_bits_h_resp_entry_perm_x    (io_hptw_resp_bits_h_resp_entry_perm_x),
    .io_hptw_resp_bits_h_resp_entry_perm_w    (io_hptw_resp_bits_h_resp_entry_perm_w),
    .io_hptw_resp_bits_h_resp_entry_perm_r    (io_hptw_resp_bits_h_resp_entry_perm_r),
    .io_hptw_resp_bits_h_resp_entry_level     (io_hptw_resp_bits_h_resp_entry_level),
    .io_hptw_resp_bits_h_resp_gpf             (io_hptw_resp_bits_h_resp_gpf),
    .io_hptw_resp_bits_h_resp_gaf             (io_hptw_resp_bits_h_resp_gaf),
    .io_mem_req_ready                         (io_mem_req_ready),
    .io_mem_req_valid                         (g_io_mem_req_valid),
    .io_mem_req_bits_addr                     (g_io_mem_req_bits_addr),
    .io_mem_resp_valid                        (io_mem_resp_valid),
    .io_mem_resp_bits                         (io_mem_resp_bits),
    .io_mem_mask                              (io_mem_mask),
    .io_pmp_req_bits_addr                     (g_io_pmp_req_bits_addr),
    .io_pmp_resp_ld                           (io_pmp_resp_ld),
    .io_pmp_resp_mmio                         (io_pmp_resp_mmio),
    .io_refill_req_info_vpn                   (g_io_refill_req_info_vpn),
    .io_refill_req_info_s2xlate               (g_io_refill_req_info_s2xlate),
    .io_refill_req_info_source                (g_io_refill_req_info_source),
    .io_refill_level                          (g_io_refill_level),
    .io_bitmap_req_ready                      (io_bitmap_req_ready),
    .io_bitmap_req_valid                      (g_io_bitmap_req_valid),
    .io_bitmap_req_bits_bmppn                 (g_io_bitmap_req_bits_bmppn),
    .io_bitmap_req_bits_vpn                   (g_io_bitmap_req_bits_vpn),
    .io_bitmap_req_bits_level                 (g_io_bitmap_req_bits_level),
    .io_bitmap_req_bits_s2xlate               (g_io_bitmap_req_bits_s2xlate),
    .io_bitmap_req_bits_n                     (g_io_bitmap_req_bits_n),
    .io_bitmap_resp_ready                     (g_io_bitmap_resp_ready),
    .io_bitmap_resp_valid                     (io_bitmap_resp_valid),
    .io_bitmap_resp_bits_cf                   (io_bitmap_resp_bits_cf),
    .io_perf_0_value                          (g_io_perf_0_value),
    .io_perf_1_value                          (g_io_perf_1_value),
    .io_perf_2_value                          (g_io_perf_2_value),
    .io_perf_3_value                          (g_io_perf_3_value),
    .io_perf_4_value                          (g_io_perf_4_value),
    .io_perf_5_value                          (g_io_perf_5_value),
    .io_perf_6_value                          (g_io_perf_6_value)
  );
  PTW_xs u_i (
    .clock(clock), .reset(reset),
    .io_sfence_valid                          (io_sfence_valid),
    .io_csr_satp_mode                         (io_csr_satp_mode),
    .io_csr_satp_asid                         (io_csr_satp_asid),
    .io_csr_satp_ppn                          (io_csr_satp_ppn),
    .io_csr_satp_changed                      (io_csr_satp_changed),
    .io_csr_vsatp_mode                        (io_csr_vsatp_mode),
    .io_csr_vsatp_asid                        (io_csr_vsatp_asid),
    .io_csr_vsatp_ppn                         (io_csr_vsatp_ppn),
    .io_csr_vsatp_changed                     (io_csr_vsatp_changed),
    .io_csr_hgatp_mode                        (io_csr_hgatp_mode),
    .io_csr_hgatp_vmid                        (io_csr_hgatp_vmid),
    .io_csr_hgatp_changed                     (io_csr_hgatp_changed),
    .io_csr_mbmc_BME                          (io_csr_mbmc_BME),
    .io_csr_mbmc_CMODE                        (io_csr_mbmc_CMODE),
    .io_csr_priv_virt_changed                 (io_csr_priv_virt_changed),
    .io_csr_mPBMTE                            (io_csr_mPBMTE),
    .io_csr_hPBMTE                            (io_csr_hPBMTE),
    .io_req_ready                             (i_io_req_ready),
    .io_req_valid                             (io_req_valid),
    .io_req_bits_req_info_vpn                 (io_req_bits_req_info_vpn),
    .io_req_bits_req_info_s2xlate             (io_req_bits_req_info_s2xlate),
    .io_req_bits_req_info_source              (io_req_bits_req_info_source),
    .io_req_bits_l3Hit                        (io_req_bits_l3Hit),
    .io_req_bits_l2Hit                        (io_req_bits_l2Hit),
    .io_req_bits_ppn                          (io_req_bits_ppn),
    .io_req_bits_stage1Hit                    (io_req_bits_stage1Hit),
    .io_req_bits_stage1_entry_0_tag           (io_req_bits_stage1_entry_0_tag),
    .io_req_bits_stage1_entry_0_asid          (io_req_bits_stage1_entry_0_asid),
    .io_req_bits_stage1_entry_0_vmid          (io_req_bits_stage1_entry_0_vmid),
    .io_req_bits_stage1_entry_0_n             (io_req_bits_stage1_entry_0_n),
    .io_req_bits_stage1_entry_0_pbmt          (io_req_bits_stage1_entry_0_pbmt),
    .io_req_bits_stage1_entry_0_perm_d        (io_req_bits_stage1_entry_0_perm_d),
    .io_req_bits_stage1_entry_0_perm_a        (io_req_bits_stage1_entry_0_perm_a),
    .io_req_bits_stage1_entry_0_perm_g        (io_req_bits_stage1_entry_0_perm_g),
    .io_req_bits_stage1_entry_0_perm_u        (io_req_bits_stage1_entry_0_perm_u),
    .io_req_bits_stage1_entry_0_perm_x        (io_req_bits_stage1_entry_0_perm_x),
    .io_req_bits_stage1_entry_0_perm_w        (io_req_bits_stage1_entry_0_perm_w),
    .io_req_bits_stage1_entry_0_perm_r        (io_req_bits_stage1_entry_0_perm_r),
    .io_req_bits_stage1_entry_0_level         (io_req_bits_stage1_entry_0_level),
    .io_req_bits_stage1_entry_0_v             (io_req_bits_stage1_entry_0_v),
    .io_req_bits_stage1_entry_0_ppn           (io_req_bits_stage1_entry_0_ppn),
    .io_req_bits_stage1_entry_0_ppn_low       (io_req_bits_stage1_entry_0_ppn_low),
    .io_req_bits_stage1_entry_0_pf            (io_req_bits_stage1_entry_0_pf),
    .io_req_bits_stage1_entry_0_cf            (io_req_bits_stage1_entry_0_cf),
    .io_req_bits_stage1_entry_1_tag           (io_req_bits_stage1_entry_1_tag),
    .io_req_bits_stage1_entry_1_asid          (io_req_bits_stage1_entry_1_asid),
    .io_req_bits_stage1_entry_1_vmid          (io_req_bits_stage1_entry_1_vmid),
    .io_req_bits_stage1_entry_1_n             (io_req_bits_stage1_entry_1_n),
    .io_req_bits_stage1_entry_1_pbmt          (io_req_bits_stage1_entry_1_pbmt),
    .io_req_bits_stage1_entry_1_perm_d        (io_req_bits_stage1_entry_1_perm_d),
    .io_req_bits_stage1_entry_1_perm_a        (io_req_bits_stage1_entry_1_perm_a),
    .io_req_bits_stage1_entry_1_perm_g        (io_req_bits_stage1_entry_1_perm_g),
    .io_req_bits_stage1_entry_1_perm_u        (io_req_bits_stage1_entry_1_perm_u),
    .io_req_bits_stage1_entry_1_perm_x        (io_req_bits_stage1_entry_1_perm_x),
    .io_req_bits_stage1_entry_1_perm_w        (io_req_bits_stage1_entry_1_perm_w),
    .io_req_bits_stage1_entry_1_perm_r        (io_req_bits_stage1_entry_1_perm_r),
    .io_req_bits_stage1_entry_1_level         (io_req_bits_stage1_entry_1_level),
    .io_req_bits_stage1_entry_1_v             (io_req_bits_stage1_entry_1_v),
    .io_req_bits_stage1_entry_1_ppn           (io_req_bits_stage1_entry_1_ppn),
    .io_req_bits_stage1_entry_1_ppn_low       (io_req_bits_stage1_entry_1_ppn_low),
    .io_req_bits_stage1_entry_1_pf            (io_req_bits_stage1_entry_1_pf),
    .io_req_bits_stage1_entry_1_cf            (io_req_bits_stage1_entry_1_cf),
    .io_req_bits_stage1_entry_2_tag           (io_req_bits_stage1_entry_2_tag),
    .io_req_bits_stage1_entry_2_asid          (io_req_bits_stage1_entry_2_asid),
    .io_req_bits_stage1_entry_2_vmid          (io_req_bits_stage1_entry_2_vmid),
    .io_req_bits_stage1_entry_2_n             (io_req_bits_stage1_entry_2_n),
    .io_req_bits_stage1_entry_2_pbmt          (io_req_bits_stage1_entry_2_pbmt),
    .io_req_bits_stage1_entry_2_perm_d        (io_req_bits_stage1_entry_2_perm_d),
    .io_req_bits_stage1_entry_2_perm_a        (io_req_bits_stage1_entry_2_perm_a),
    .io_req_bits_stage1_entry_2_perm_g        (io_req_bits_stage1_entry_2_perm_g),
    .io_req_bits_stage1_entry_2_perm_u        (io_req_bits_stage1_entry_2_perm_u),
    .io_req_bits_stage1_entry_2_perm_x        (io_req_bits_stage1_entry_2_perm_x),
    .io_req_bits_stage1_entry_2_perm_w        (io_req_bits_stage1_entry_2_perm_w),
    .io_req_bits_stage1_entry_2_perm_r        (io_req_bits_stage1_entry_2_perm_r),
    .io_req_bits_stage1_entry_2_level         (io_req_bits_stage1_entry_2_level),
    .io_req_bits_stage1_entry_2_v             (io_req_bits_stage1_entry_2_v),
    .io_req_bits_stage1_entry_2_ppn           (io_req_bits_stage1_entry_2_ppn),
    .io_req_bits_stage1_entry_2_ppn_low       (io_req_bits_stage1_entry_2_ppn_low),
    .io_req_bits_stage1_entry_2_pf            (io_req_bits_stage1_entry_2_pf),
    .io_req_bits_stage1_entry_2_cf            (io_req_bits_stage1_entry_2_cf),
    .io_req_bits_stage1_entry_3_tag           (io_req_bits_stage1_entry_3_tag),
    .io_req_bits_stage1_entry_3_asid          (io_req_bits_stage1_entry_3_asid),
    .io_req_bits_stage1_entry_3_vmid          (io_req_bits_stage1_entry_3_vmid),
    .io_req_bits_stage1_entry_3_n             (io_req_bits_stage1_entry_3_n),
    .io_req_bits_stage1_entry_3_pbmt          (io_req_bits_stage1_entry_3_pbmt),
    .io_req_bits_stage1_entry_3_perm_d        (io_req_bits_stage1_entry_3_perm_d),
    .io_req_bits_stage1_entry_3_perm_a        (io_req_bits_stage1_entry_3_perm_a),
    .io_req_bits_stage1_entry_3_perm_g        (io_req_bits_stage1_entry_3_perm_g),
    .io_req_bits_stage1_entry_3_perm_u        (io_req_bits_stage1_entry_3_perm_u),
    .io_req_bits_stage1_entry_3_perm_x        (io_req_bits_stage1_entry_3_perm_x),
    .io_req_bits_stage1_entry_3_perm_w        (io_req_bits_stage1_entry_3_perm_w),
    .io_req_bits_stage1_entry_3_perm_r        (io_req_bits_stage1_entry_3_perm_r),
    .io_req_bits_stage1_entry_3_level         (io_req_bits_stage1_entry_3_level),
    .io_req_bits_stage1_entry_3_v             (io_req_bits_stage1_entry_3_v),
    .io_req_bits_stage1_entry_3_ppn           (io_req_bits_stage1_entry_3_ppn),
    .io_req_bits_stage1_entry_3_ppn_low       (io_req_bits_stage1_entry_3_ppn_low),
    .io_req_bits_stage1_entry_3_pf            (io_req_bits_stage1_entry_3_pf),
    .io_req_bits_stage1_entry_3_cf            (io_req_bits_stage1_entry_3_cf),
    .io_req_bits_stage1_entry_4_tag           (io_req_bits_stage1_entry_4_tag),
    .io_req_bits_stage1_entry_4_asid          (io_req_bits_stage1_entry_4_asid),
    .io_req_bits_stage1_entry_4_vmid          (io_req_bits_stage1_entry_4_vmid),
    .io_req_bits_stage1_entry_4_n             (io_req_bits_stage1_entry_4_n),
    .io_req_bits_stage1_entry_4_pbmt          (io_req_bits_stage1_entry_4_pbmt),
    .io_req_bits_stage1_entry_4_perm_d        (io_req_bits_stage1_entry_4_perm_d),
    .io_req_bits_stage1_entry_4_perm_a        (io_req_bits_stage1_entry_4_perm_a),
    .io_req_bits_stage1_entry_4_perm_g        (io_req_bits_stage1_entry_4_perm_g),
    .io_req_bits_stage1_entry_4_perm_u        (io_req_bits_stage1_entry_4_perm_u),
    .io_req_bits_stage1_entry_4_perm_x        (io_req_bits_stage1_entry_4_perm_x),
    .io_req_bits_stage1_entry_4_perm_w        (io_req_bits_stage1_entry_4_perm_w),
    .io_req_bits_stage1_entry_4_perm_r        (io_req_bits_stage1_entry_4_perm_r),
    .io_req_bits_stage1_entry_4_level         (io_req_bits_stage1_entry_4_level),
    .io_req_bits_stage1_entry_4_v             (io_req_bits_stage1_entry_4_v),
    .io_req_bits_stage1_entry_4_ppn           (io_req_bits_stage1_entry_4_ppn),
    .io_req_bits_stage1_entry_4_ppn_low       (io_req_bits_stage1_entry_4_ppn_low),
    .io_req_bits_stage1_entry_4_pf            (io_req_bits_stage1_entry_4_pf),
    .io_req_bits_stage1_entry_4_cf            (io_req_bits_stage1_entry_4_cf),
    .io_req_bits_stage1_entry_5_tag           (io_req_bits_stage1_entry_5_tag),
    .io_req_bits_stage1_entry_5_asid          (io_req_bits_stage1_entry_5_asid),
    .io_req_bits_stage1_entry_5_vmid          (io_req_bits_stage1_entry_5_vmid),
    .io_req_bits_stage1_entry_5_n             (io_req_bits_stage1_entry_5_n),
    .io_req_bits_stage1_entry_5_pbmt          (io_req_bits_stage1_entry_5_pbmt),
    .io_req_bits_stage1_entry_5_perm_d        (io_req_bits_stage1_entry_5_perm_d),
    .io_req_bits_stage1_entry_5_perm_a        (io_req_bits_stage1_entry_5_perm_a),
    .io_req_bits_stage1_entry_5_perm_g        (io_req_bits_stage1_entry_5_perm_g),
    .io_req_bits_stage1_entry_5_perm_u        (io_req_bits_stage1_entry_5_perm_u),
    .io_req_bits_stage1_entry_5_perm_x        (io_req_bits_stage1_entry_5_perm_x),
    .io_req_bits_stage1_entry_5_perm_w        (io_req_bits_stage1_entry_5_perm_w),
    .io_req_bits_stage1_entry_5_perm_r        (io_req_bits_stage1_entry_5_perm_r),
    .io_req_bits_stage1_entry_5_level         (io_req_bits_stage1_entry_5_level),
    .io_req_bits_stage1_entry_5_v             (io_req_bits_stage1_entry_5_v),
    .io_req_bits_stage1_entry_5_ppn           (io_req_bits_stage1_entry_5_ppn),
    .io_req_bits_stage1_entry_5_ppn_low       (io_req_bits_stage1_entry_5_ppn_low),
    .io_req_bits_stage1_entry_5_pf            (io_req_bits_stage1_entry_5_pf),
    .io_req_bits_stage1_entry_5_cf            (io_req_bits_stage1_entry_5_cf),
    .io_req_bits_stage1_entry_6_tag           (io_req_bits_stage1_entry_6_tag),
    .io_req_bits_stage1_entry_6_asid          (io_req_bits_stage1_entry_6_asid),
    .io_req_bits_stage1_entry_6_vmid          (io_req_bits_stage1_entry_6_vmid),
    .io_req_bits_stage1_entry_6_n             (io_req_bits_stage1_entry_6_n),
    .io_req_bits_stage1_entry_6_pbmt          (io_req_bits_stage1_entry_6_pbmt),
    .io_req_bits_stage1_entry_6_perm_d        (io_req_bits_stage1_entry_6_perm_d),
    .io_req_bits_stage1_entry_6_perm_a        (io_req_bits_stage1_entry_6_perm_a),
    .io_req_bits_stage1_entry_6_perm_g        (io_req_bits_stage1_entry_6_perm_g),
    .io_req_bits_stage1_entry_6_perm_u        (io_req_bits_stage1_entry_6_perm_u),
    .io_req_bits_stage1_entry_6_perm_x        (io_req_bits_stage1_entry_6_perm_x),
    .io_req_bits_stage1_entry_6_perm_w        (io_req_bits_stage1_entry_6_perm_w),
    .io_req_bits_stage1_entry_6_perm_r        (io_req_bits_stage1_entry_6_perm_r),
    .io_req_bits_stage1_entry_6_level         (io_req_bits_stage1_entry_6_level),
    .io_req_bits_stage1_entry_6_v             (io_req_bits_stage1_entry_6_v),
    .io_req_bits_stage1_entry_6_ppn           (io_req_bits_stage1_entry_6_ppn),
    .io_req_bits_stage1_entry_6_ppn_low       (io_req_bits_stage1_entry_6_ppn_low),
    .io_req_bits_stage1_entry_6_pf            (io_req_bits_stage1_entry_6_pf),
    .io_req_bits_stage1_entry_6_cf            (io_req_bits_stage1_entry_6_cf),
    .io_req_bits_stage1_entry_7_tag           (io_req_bits_stage1_entry_7_tag),
    .io_req_bits_stage1_entry_7_asid          (io_req_bits_stage1_entry_7_asid),
    .io_req_bits_stage1_entry_7_vmid          (io_req_bits_stage1_entry_7_vmid),
    .io_req_bits_stage1_entry_7_n             (io_req_bits_stage1_entry_7_n),
    .io_req_bits_stage1_entry_7_pbmt          (io_req_bits_stage1_entry_7_pbmt),
    .io_req_bits_stage1_entry_7_perm_d        (io_req_bits_stage1_entry_7_perm_d),
    .io_req_bits_stage1_entry_7_perm_a        (io_req_bits_stage1_entry_7_perm_a),
    .io_req_bits_stage1_entry_7_perm_g        (io_req_bits_stage1_entry_7_perm_g),
    .io_req_bits_stage1_entry_7_perm_u        (io_req_bits_stage1_entry_7_perm_u),
    .io_req_bits_stage1_entry_7_perm_x        (io_req_bits_stage1_entry_7_perm_x),
    .io_req_bits_stage1_entry_7_perm_w        (io_req_bits_stage1_entry_7_perm_w),
    .io_req_bits_stage1_entry_7_perm_r        (io_req_bits_stage1_entry_7_perm_r),
    .io_req_bits_stage1_entry_7_level         (io_req_bits_stage1_entry_7_level),
    .io_req_bits_stage1_entry_7_v             (io_req_bits_stage1_entry_7_v),
    .io_req_bits_stage1_entry_7_ppn           (io_req_bits_stage1_entry_7_ppn),
    .io_req_bits_stage1_entry_7_ppn_low       (io_req_bits_stage1_entry_7_ppn_low),
    .io_req_bits_stage1_entry_7_pf            (io_req_bits_stage1_entry_7_pf),
    .io_req_bits_stage1_entry_7_cf            (io_req_bits_stage1_entry_7_cf),
    .io_req_bits_stage1_pteidx_0              (io_req_bits_stage1_pteidx_0),
    .io_req_bits_stage1_pteidx_1              (io_req_bits_stage1_pteidx_1),
    .io_req_bits_stage1_pteidx_2              (io_req_bits_stage1_pteidx_2),
    .io_req_bits_stage1_pteidx_3              (io_req_bits_stage1_pteidx_3),
    .io_req_bits_stage1_pteidx_4              (io_req_bits_stage1_pteidx_4),
    .io_req_bits_stage1_pteidx_5              (io_req_bits_stage1_pteidx_5),
    .io_req_bits_stage1_pteidx_6              (io_req_bits_stage1_pteidx_6),
    .io_req_bits_stage1_pteidx_7              (io_req_bits_stage1_pteidx_7),
    .io_req_bits_stage1_not_super             (io_req_bits_stage1_not_super),
    .io_req_bits_bitmapCheck_jmp_bitmap_check (io_req_bits_bitmapCheck_jmp_bitmap_check),
    .io_req_bits_bitmapCheck_pte              (io_req_bits_bitmapCheck_pte),
    .io_req_bits_bitmapCheck_SPlevel          (io_req_bits_bitmapCheck_SPlevel),
    .io_resp_ready                            (io_resp_ready),
    .io_resp_valid                            (i_io_resp_valid),
    .io_resp_bits_source                      (i_io_resp_bits_source),
    .io_resp_bits_s2xlate                     (i_io_resp_bits_s2xlate),
    .io_resp_bits_resp_entry_0_tag            (i_io_resp_bits_resp_entry_0_tag),
    .io_resp_bits_resp_entry_0_asid           (i_io_resp_bits_resp_entry_0_asid),
    .io_resp_bits_resp_entry_0_vmid           (i_io_resp_bits_resp_entry_0_vmid),
    .io_resp_bits_resp_entry_0_n              (i_io_resp_bits_resp_entry_0_n),
    .io_resp_bits_resp_entry_0_pbmt           (i_io_resp_bits_resp_entry_0_pbmt),
    .io_resp_bits_resp_entry_0_perm_d         (i_io_resp_bits_resp_entry_0_perm_d),
    .io_resp_bits_resp_entry_0_perm_a         (i_io_resp_bits_resp_entry_0_perm_a),
    .io_resp_bits_resp_entry_0_perm_g         (i_io_resp_bits_resp_entry_0_perm_g),
    .io_resp_bits_resp_entry_0_perm_u         (i_io_resp_bits_resp_entry_0_perm_u),
    .io_resp_bits_resp_entry_0_perm_x         (i_io_resp_bits_resp_entry_0_perm_x),
    .io_resp_bits_resp_entry_0_perm_w         (i_io_resp_bits_resp_entry_0_perm_w),
    .io_resp_bits_resp_entry_0_perm_r         (i_io_resp_bits_resp_entry_0_perm_r),
    .io_resp_bits_resp_entry_0_level          (i_io_resp_bits_resp_entry_0_level),
    .io_resp_bits_resp_entry_0_v              (i_io_resp_bits_resp_entry_0_v),
    .io_resp_bits_resp_entry_0_ppn            (i_io_resp_bits_resp_entry_0_ppn),
    .io_resp_bits_resp_entry_0_ppn_low        (i_io_resp_bits_resp_entry_0_ppn_low),
    .io_resp_bits_resp_entry_0_af             (i_io_resp_bits_resp_entry_0_af),
    .io_resp_bits_resp_entry_0_pf             (i_io_resp_bits_resp_entry_0_pf),
    .io_resp_bits_resp_entry_0_cf             (i_io_resp_bits_resp_entry_0_cf),
    .io_resp_bits_resp_entry_1_tag            (i_io_resp_bits_resp_entry_1_tag),
    .io_resp_bits_resp_entry_1_asid           (i_io_resp_bits_resp_entry_1_asid),
    .io_resp_bits_resp_entry_1_vmid           (i_io_resp_bits_resp_entry_1_vmid),
    .io_resp_bits_resp_entry_1_n              (i_io_resp_bits_resp_entry_1_n),
    .io_resp_bits_resp_entry_1_pbmt           (i_io_resp_bits_resp_entry_1_pbmt),
    .io_resp_bits_resp_entry_1_perm_d         (i_io_resp_bits_resp_entry_1_perm_d),
    .io_resp_bits_resp_entry_1_perm_a         (i_io_resp_bits_resp_entry_1_perm_a),
    .io_resp_bits_resp_entry_1_perm_g         (i_io_resp_bits_resp_entry_1_perm_g),
    .io_resp_bits_resp_entry_1_perm_u         (i_io_resp_bits_resp_entry_1_perm_u),
    .io_resp_bits_resp_entry_1_perm_x         (i_io_resp_bits_resp_entry_1_perm_x),
    .io_resp_bits_resp_entry_1_perm_w         (i_io_resp_bits_resp_entry_1_perm_w),
    .io_resp_bits_resp_entry_1_perm_r         (i_io_resp_bits_resp_entry_1_perm_r),
    .io_resp_bits_resp_entry_1_level          (i_io_resp_bits_resp_entry_1_level),
    .io_resp_bits_resp_entry_1_v              (i_io_resp_bits_resp_entry_1_v),
    .io_resp_bits_resp_entry_1_ppn            (i_io_resp_bits_resp_entry_1_ppn),
    .io_resp_bits_resp_entry_1_ppn_low        (i_io_resp_bits_resp_entry_1_ppn_low),
    .io_resp_bits_resp_entry_1_af             (i_io_resp_bits_resp_entry_1_af),
    .io_resp_bits_resp_entry_1_pf             (i_io_resp_bits_resp_entry_1_pf),
    .io_resp_bits_resp_entry_1_cf             (i_io_resp_bits_resp_entry_1_cf),
    .io_resp_bits_resp_entry_2_tag            (i_io_resp_bits_resp_entry_2_tag),
    .io_resp_bits_resp_entry_2_asid           (i_io_resp_bits_resp_entry_2_asid),
    .io_resp_bits_resp_entry_2_vmid           (i_io_resp_bits_resp_entry_2_vmid),
    .io_resp_bits_resp_entry_2_n              (i_io_resp_bits_resp_entry_2_n),
    .io_resp_bits_resp_entry_2_pbmt           (i_io_resp_bits_resp_entry_2_pbmt),
    .io_resp_bits_resp_entry_2_perm_d         (i_io_resp_bits_resp_entry_2_perm_d),
    .io_resp_bits_resp_entry_2_perm_a         (i_io_resp_bits_resp_entry_2_perm_a),
    .io_resp_bits_resp_entry_2_perm_g         (i_io_resp_bits_resp_entry_2_perm_g),
    .io_resp_bits_resp_entry_2_perm_u         (i_io_resp_bits_resp_entry_2_perm_u),
    .io_resp_bits_resp_entry_2_perm_x         (i_io_resp_bits_resp_entry_2_perm_x),
    .io_resp_bits_resp_entry_2_perm_w         (i_io_resp_bits_resp_entry_2_perm_w),
    .io_resp_bits_resp_entry_2_perm_r         (i_io_resp_bits_resp_entry_2_perm_r),
    .io_resp_bits_resp_entry_2_level          (i_io_resp_bits_resp_entry_2_level),
    .io_resp_bits_resp_entry_2_v              (i_io_resp_bits_resp_entry_2_v),
    .io_resp_bits_resp_entry_2_ppn            (i_io_resp_bits_resp_entry_2_ppn),
    .io_resp_bits_resp_entry_2_ppn_low        (i_io_resp_bits_resp_entry_2_ppn_low),
    .io_resp_bits_resp_entry_2_af             (i_io_resp_bits_resp_entry_2_af),
    .io_resp_bits_resp_entry_2_pf             (i_io_resp_bits_resp_entry_2_pf),
    .io_resp_bits_resp_entry_2_cf             (i_io_resp_bits_resp_entry_2_cf),
    .io_resp_bits_resp_entry_3_tag            (i_io_resp_bits_resp_entry_3_tag),
    .io_resp_bits_resp_entry_3_asid           (i_io_resp_bits_resp_entry_3_asid),
    .io_resp_bits_resp_entry_3_vmid           (i_io_resp_bits_resp_entry_3_vmid),
    .io_resp_bits_resp_entry_3_n              (i_io_resp_bits_resp_entry_3_n),
    .io_resp_bits_resp_entry_3_pbmt           (i_io_resp_bits_resp_entry_3_pbmt),
    .io_resp_bits_resp_entry_3_perm_d         (i_io_resp_bits_resp_entry_3_perm_d),
    .io_resp_bits_resp_entry_3_perm_a         (i_io_resp_bits_resp_entry_3_perm_a),
    .io_resp_bits_resp_entry_3_perm_g         (i_io_resp_bits_resp_entry_3_perm_g),
    .io_resp_bits_resp_entry_3_perm_u         (i_io_resp_bits_resp_entry_3_perm_u),
    .io_resp_bits_resp_entry_3_perm_x         (i_io_resp_bits_resp_entry_3_perm_x),
    .io_resp_bits_resp_entry_3_perm_w         (i_io_resp_bits_resp_entry_3_perm_w),
    .io_resp_bits_resp_entry_3_perm_r         (i_io_resp_bits_resp_entry_3_perm_r),
    .io_resp_bits_resp_entry_3_level          (i_io_resp_bits_resp_entry_3_level),
    .io_resp_bits_resp_entry_3_v              (i_io_resp_bits_resp_entry_3_v),
    .io_resp_bits_resp_entry_3_ppn            (i_io_resp_bits_resp_entry_3_ppn),
    .io_resp_bits_resp_entry_3_ppn_low        (i_io_resp_bits_resp_entry_3_ppn_low),
    .io_resp_bits_resp_entry_3_af             (i_io_resp_bits_resp_entry_3_af),
    .io_resp_bits_resp_entry_3_pf             (i_io_resp_bits_resp_entry_3_pf),
    .io_resp_bits_resp_entry_3_cf             (i_io_resp_bits_resp_entry_3_cf),
    .io_resp_bits_resp_entry_4_tag            (i_io_resp_bits_resp_entry_4_tag),
    .io_resp_bits_resp_entry_4_asid           (i_io_resp_bits_resp_entry_4_asid),
    .io_resp_bits_resp_entry_4_vmid           (i_io_resp_bits_resp_entry_4_vmid),
    .io_resp_bits_resp_entry_4_n              (i_io_resp_bits_resp_entry_4_n),
    .io_resp_bits_resp_entry_4_pbmt           (i_io_resp_bits_resp_entry_4_pbmt),
    .io_resp_bits_resp_entry_4_perm_d         (i_io_resp_bits_resp_entry_4_perm_d),
    .io_resp_bits_resp_entry_4_perm_a         (i_io_resp_bits_resp_entry_4_perm_a),
    .io_resp_bits_resp_entry_4_perm_g         (i_io_resp_bits_resp_entry_4_perm_g),
    .io_resp_bits_resp_entry_4_perm_u         (i_io_resp_bits_resp_entry_4_perm_u),
    .io_resp_bits_resp_entry_4_perm_x         (i_io_resp_bits_resp_entry_4_perm_x),
    .io_resp_bits_resp_entry_4_perm_w         (i_io_resp_bits_resp_entry_4_perm_w),
    .io_resp_bits_resp_entry_4_perm_r         (i_io_resp_bits_resp_entry_4_perm_r),
    .io_resp_bits_resp_entry_4_level          (i_io_resp_bits_resp_entry_4_level),
    .io_resp_bits_resp_entry_4_v              (i_io_resp_bits_resp_entry_4_v),
    .io_resp_bits_resp_entry_4_ppn            (i_io_resp_bits_resp_entry_4_ppn),
    .io_resp_bits_resp_entry_4_ppn_low        (i_io_resp_bits_resp_entry_4_ppn_low),
    .io_resp_bits_resp_entry_4_af             (i_io_resp_bits_resp_entry_4_af),
    .io_resp_bits_resp_entry_4_pf             (i_io_resp_bits_resp_entry_4_pf),
    .io_resp_bits_resp_entry_4_cf             (i_io_resp_bits_resp_entry_4_cf),
    .io_resp_bits_resp_entry_5_tag            (i_io_resp_bits_resp_entry_5_tag),
    .io_resp_bits_resp_entry_5_asid           (i_io_resp_bits_resp_entry_5_asid),
    .io_resp_bits_resp_entry_5_vmid           (i_io_resp_bits_resp_entry_5_vmid),
    .io_resp_bits_resp_entry_5_n              (i_io_resp_bits_resp_entry_5_n),
    .io_resp_bits_resp_entry_5_pbmt           (i_io_resp_bits_resp_entry_5_pbmt),
    .io_resp_bits_resp_entry_5_perm_d         (i_io_resp_bits_resp_entry_5_perm_d),
    .io_resp_bits_resp_entry_5_perm_a         (i_io_resp_bits_resp_entry_5_perm_a),
    .io_resp_bits_resp_entry_5_perm_g         (i_io_resp_bits_resp_entry_5_perm_g),
    .io_resp_bits_resp_entry_5_perm_u         (i_io_resp_bits_resp_entry_5_perm_u),
    .io_resp_bits_resp_entry_5_perm_x         (i_io_resp_bits_resp_entry_5_perm_x),
    .io_resp_bits_resp_entry_5_perm_w         (i_io_resp_bits_resp_entry_5_perm_w),
    .io_resp_bits_resp_entry_5_perm_r         (i_io_resp_bits_resp_entry_5_perm_r),
    .io_resp_bits_resp_entry_5_level          (i_io_resp_bits_resp_entry_5_level),
    .io_resp_bits_resp_entry_5_v              (i_io_resp_bits_resp_entry_5_v),
    .io_resp_bits_resp_entry_5_ppn            (i_io_resp_bits_resp_entry_5_ppn),
    .io_resp_bits_resp_entry_5_ppn_low        (i_io_resp_bits_resp_entry_5_ppn_low),
    .io_resp_bits_resp_entry_5_af             (i_io_resp_bits_resp_entry_5_af),
    .io_resp_bits_resp_entry_5_pf             (i_io_resp_bits_resp_entry_5_pf),
    .io_resp_bits_resp_entry_5_cf             (i_io_resp_bits_resp_entry_5_cf),
    .io_resp_bits_resp_entry_6_tag            (i_io_resp_bits_resp_entry_6_tag),
    .io_resp_bits_resp_entry_6_asid           (i_io_resp_bits_resp_entry_6_asid),
    .io_resp_bits_resp_entry_6_vmid           (i_io_resp_bits_resp_entry_6_vmid),
    .io_resp_bits_resp_entry_6_n              (i_io_resp_bits_resp_entry_6_n),
    .io_resp_bits_resp_entry_6_pbmt           (i_io_resp_bits_resp_entry_6_pbmt),
    .io_resp_bits_resp_entry_6_perm_d         (i_io_resp_bits_resp_entry_6_perm_d),
    .io_resp_bits_resp_entry_6_perm_a         (i_io_resp_bits_resp_entry_6_perm_a),
    .io_resp_bits_resp_entry_6_perm_g         (i_io_resp_bits_resp_entry_6_perm_g),
    .io_resp_bits_resp_entry_6_perm_u         (i_io_resp_bits_resp_entry_6_perm_u),
    .io_resp_bits_resp_entry_6_perm_x         (i_io_resp_bits_resp_entry_6_perm_x),
    .io_resp_bits_resp_entry_6_perm_w         (i_io_resp_bits_resp_entry_6_perm_w),
    .io_resp_bits_resp_entry_6_perm_r         (i_io_resp_bits_resp_entry_6_perm_r),
    .io_resp_bits_resp_entry_6_level          (i_io_resp_bits_resp_entry_6_level),
    .io_resp_bits_resp_entry_6_v              (i_io_resp_bits_resp_entry_6_v),
    .io_resp_bits_resp_entry_6_ppn            (i_io_resp_bits_resp_entry_6_ppn),
    .io_resp_bits_resp_entry_6_ppn_low        (i_io_resp_bits_resp_entry_6_ppn_low),
    .io_resp_bits_resp_entry_6_af             (i_io_resp_bits_resp_entry_6_af),
    .io_resp_bits_resp_entry_6_pf             (i_io_resp_bits_resp_entry_6_pf),
    .io_resp_bits_resp_entry_6_cf             (i_io_resp_bits_resp_entry_6_cf),
    .io_resp_bits_resp_entry_7_tag            (i_io_resp_bits_resp_entry_7_tag),
    .io_resp_bits_resp_entry_7_asid           (i_io_resp_bits_resp_entry_7_asid),
    .io_resp_bits_resp_entry_7_vmid           (i_io_resp_bits_resp_entry_7_vmid),
    .io_resp_bits_resp_entry_7_n              (i_io_resp_bits_resp_entry_7_n),
    .io_resp_bits_resp_entry_7_pbmt           (i_io_resp_bits_resp_entry_7_pbmt),
    .io_resp_bits_resp_entry_7_perm_d         (i_io_resp_bits_resp_entry_7_perm_d),
    .io_resp_bits_resp_entry_7_perm_a         (i_io_resp_bits_resp_entry_7_perm_a),
    .io_resp_bits_resp_entry_7_perm_g         (i_io_resp_bits_resp_entry_7_perm_g),
    .io_resp_bits_resp_entry_7_perm_u         (i_io_resp_bits_resp_entry_7_perm_u),
    .io_resp_bits_resp_entry_7_perm_x         (i_io_resp_bits_resp_entry_7_perm_x),
    .io_resp_bits_resp_entry_7_perm_w         (i_io_resp_bits_resp_entry_7_perm_w),
    .io_resp_bits_resp_entry_7_perm_r         (i_io_resp_bits_resp_entry_7_perm_r),
    .io_resp_bits_resp_entry_7_level          (i_io_resp_bits_resp_entry_7_level),
    .io_resp_bits_resp_entry_7_v              (i_io_resp_bits_resp_entry_7_v),
    .io_resp_bits_resp_entry_7_ppn            (i_io_resp_bits_resp_entry_7_ppn),
    .io_resp_bits_resp_entry_7_ppn_low        (i_io_resp_bits_resp_entry_7_ppn_low),
    .io_resp_bits_resp_entry_7_af             (i_io_resp_bits_resp_entry_7_af),
    .io_resp_bits_resp_entry_7_pf             (i_io_resp_bits_resp_entry_7_pf),
    .io_resp_bits_resp_entry_7_cf             (i_io_resp_bits_resp_entry_7_cf),
    .io_resp_bits_resp_pteidx_0               (i_io_resp_bits_resp_pteidx_0),
    .io_resp_bits_resp_pteidx_1               (i_io_resp_bits_resp_pteidx_1),
    .io_resp_bits_resp_pteidx_2               (i_io_resp_bits_resp_pteidx_2),
    .io_resp_bits_resp_pteidx_3               (i_io_resp_bits_resp_pteidx_3),
    .io_resp_bits_resp_pteidx_4               (i_io_resp_bits_resp_pteidx_4),
    .io_resp_bits_resp_pteidx_5               (i_io_resp_bits_resp_pteidx_5),
    .io_resp_bits_resp_pteidx_6               (i_io_resp_bits_resp_pteidx_6),
    .io_resp_bits_resp_pteidx_7               (i_io_resp_bits_resp_pteidx_7),
    .io_resp_bits_resp_not_super              (i_io_resp_bits_resp_not_super),
    .io_resp_bits_h_resp_entry_tag            (i_io_resp_bits_h_resp_entry_tag),
    .io_resp_bits_h_resp_entry_vmid           (i_io_resp_bits_h_resp_entry_vmid),
    .io_resp_bits_h_resp_entry_n              (i_io_resp_bits_h_resp_entry_n),
    .io_resp_bits_h_resp_entry_pbmt           (i_io_resp_bits_h_resp_entry_pbmt),
    .io_resp_bits_h_resp_entry_ppn            (i_io_resp_bits_h_resp_entry_ppn),
    .io_resp_bits_h_resp_entry_perm_d         (i_io_resp_bits_h_resp_entry_perm_d),
    .io_resp_bits_h_resp_entry_perm_a         (i_io_resp_bits_h_resp_entry_perm_a),
    .io_resp_bits_h_resp_entry_perm_g         (i_io_resp_bits_h_resp_entry_perm_g),
    .io_resp_bits_h_resp_entry_perm_u         (i_io_resp_bits_h_resp_entry_perm_u),
    .io_resp_bits_h_resp_entry_perm_x         (i_io_resp_bits_h_resp_entry_perm_x),
    .io_resp_bits_h_resp_entry_perm_w         (i_io_resp_bits_h_resp_entry_perm_w),
    .io_resp_bits_h_resp_entry_perm_r         (i_io_resp_bits_h_resp_entry_perm_r),
    .io_resp_bits_h_resp_entry_level          (i_io_resp_bits_h_resp_entry_level),
    .io_resp_bits_h_resp_gpf                  (i_io_resp_bits_h_resp_gpf),
    .io_resp_bits_h_resp_gaf                  (i_io_resp_bits_h_resp_gaf),
    .io_llptw_ready                           (io_llptw_ready),
    .io_llptw_valid                           (i_io_llptw_valid),
    .io_llptw_bits_req_info_vpn               (i_io_llptw_bits_req_info_vpn),
    .io_llptw_bits_req_info_s2xlate           (i_io_llptw_bits_req_info_s2xlate),
    .io_llptw_bits_req_info_source            (i_io_llptw_bits_req_info_source),
    .io_hptw_req_ready                        (io_hptw_req_ready),
    .io_hptw_req_valid                        (i_io_hptw_req_valid),
    .io_hptw_req_bits_source                  (i_io_hptw_req_bits_source),
    .io_hptw_req_bits_gvpn                    (i_io_hptw_req_bits_gvpn),
    .io_hptw_resp_valid                       (io_hptw_resp_valid),
    .io_hptw_resp_bits_h_resp_entry_tag       (io_hptw_resp_bits_h_resp_entry_tag),
    .io_hptw_resp_bits_h_resp_entry_vmid      (io_hptw_resp_bits_h_resp_entry_vmid),
    .io_hptw_resp_bits_h_resp_entry_n         (io_hptw_resp_bits_h_resp_entry_n),
    .io_hptw_resp_bits_h_resp_entry_pbmt      (io_hptw_resp_bits_h_resp_entry_pbmt),
    .io_hptw_resp_bits_h_resp_entry_ppn       (io_hptw_resp_bits_h_resp_entry_ppn),
    .io_hptw_resp_bits_h_resp_entry_perm_d    (io_hptw_resp_bits_h_resp_entry_perm_d),
    .io_hptw_resp_bits_h_resp_entry_perm_a    (io_hptw_resp_bits_h_resp_entry_perm_a),
    .io_hptw_resp_bits_h_resp_entry_perm_g    (io_hptw_resp_bits_h_resp_entry_perm_g),
    .io_hptw_resp_bits_h_resp_entry_perm_u    (io_hptw_resp_bits_h_resp_entry_perm_u),
    .io_hptw_resp_bits_h_resp_entry_perm_x    (io_hptw_resp_bits_h_resp_entry_perm_x),
    .io_hptw_resp_bits_h_resp_entry_perm_w    (io_hptw_resp_bits_h_resp_entry_perm_w),
    .io_hptw_resp_bits_h_resp_entry_perm_r    (io_hptw_resp_bits_h_resp_entry_perm_r),
    .io_hptw_resp_bits_h_resp_entry_level     (io_hptw_resp_bits_h_resp_entry_level),
    .io_hptw_resp_bits_h_resp_gpf             (io_hptw_resp_bits_h_resp_gpf),
    .io_hptw_resp_bits_h_resp_gaf             (io_hptw_resp_bits_h_resp_gaf),
    .io_mem_req_ready                         (io_mem_req_ready),
    .io_mem_req_valid                         (i_io_mem_req_valid),
    .io_mem_req_bits_addr                     (i_io_mem_req_bits_addr),
    .io_mem_resp_valid                        (io_mem_resp_valid),
    .io_mem_resp_bits                         (io_mem_resp_bits),
    .io_mem_mask                              (io_mem_mask),
    .io_pmp_req_bits_addr                     (i_io_pmp_req_bits_addr),
    .io_pmp_resp_ld                           (io_pmp_resp_ld),
    .io_pmp_resp_mmio                         (io_pmp_resp_mmio),
    .io_refill_req_info_vpn                   (i_io_refill_req_info_vpn),
    .io_refill_req_info_s2xlate               (i_io_refill_req_info_s2xlate),
    .io_refill_req_info_source                (i_io_refill_req_info_source),
    .io_refill_level                          (i_io_refill_level),
    .io_bitmap_req_ready                      (io_bitmap_req_ready),
    .io_bitmap_req_valid                      (i_io_bitmap_req_valid),
    .io_bitmap_req_bits_bmppn                 (i_io_bitmap_req_bits_bmppn),
    .io_bitmap_req_bits_vpn                   (i_io_bitmap_req_bits_vpn),
    .io_bitmap_req_bits_level                 (i_io_bitmap_req_bits_level),
    .io_bitmap_req_bits_s2xlate               (i_io_bitmap_req_bits_s2xlate),
    .io_bitmap_req_bits_n                     (i_io_bitmap_req_bits_n),
    .io_bitmap_resp_ready                     (i_io_bitmap_resp_ready),
    .io_bitmap_resp_valid                     (io_bitmap_resp_valid),
    .io_bitmap_resp_bits_cf                   (io_bitmap_resp_bits_cf),
    .io_perf_0_value                          (i_io_perf_0_value),
    .io_perf_1_value                          (i_io_perf_1_value),
    .io_perf_2_value                          (i_io_perf_2_value),
    .io_perf_3_value                          (i_io_perf_3_value),
    .io_perf_4_value                          (i_io_perf_4_value),
    .io_perf_5_value                          (i_io_perf_5_value),
    .io_perf_6_value                          (i_io_perf_6_value)
  );
  // 逐拍比全部 208 个输出（golden 端口表逐根量出，不手抄）
  task automatic compare_outputs(input int cyc);
    checks++; if (g_io_req_ready !== i_io_req_ready) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_req_ready g=%h i=%h", cyc, g_io_req_ready, i_io_req_ready); end
    checks++; if (g_io_resp_valid !== i_io_resp_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_valid g=%h i=%h", cyc, g_io_resp_valid, i_io_resp_valid); end
    checks++; if (g_io_resp_bits_source !== i_io_resp_bits_source) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_source g=%h i=%h", cyc, g_io_resp_bits_source, i_io_resp_bits_source); end
    checks++; if (g_io_resp_bits_s2xlate !== i_io_resp_bits_s2xlate) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_s2xlate g=%h i=%h", cyc, g_io_resp_bits_s2xlate, i_io_resp_bits_s2xlate); end
    checks++; if (g_io_resp_bits_resp_entry_0_tag !== i_io_resp_bits_resp_entry_0_tag) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_tag g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_tag, i_io_resp_bits_resp_entry_0_tag); end
    checks++; if (g_io_resp_bits_resp_entry_0_asid !== i_io_resp_bits_resp_entry_0_asid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_asid g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_asid, i_io_resp_bits_resp_entry_0_asid); end
    checks++; if (g_io_resp_bits_resp_entry_0_vmid !== i_io_resp_bits_resp_entry_0_vmid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_vmid g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_vmid, i_io_resp_bits_resp_entry_0_vmid); end
    checks++; if (g_io_resp_bits_resp_entry_0_n !== i_io_resp_bits_resp_entry_0_n) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_n g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_n, i_io_resp_bits_resp_entry_0_n); end
    checks++; if (g_io_resp_bits_resp_entry_0_pbmt !== i_io_resp_bits_resp_entry_0_pbmt) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_pbmt g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_pbmt, i_io_resp_bits_resp_entry_0_pbmt); end
    checks++; if (g_io_resp_bits_resp_entry_0_perm_d !== i_io_resp_bits_resp_entry_0_perm_d) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_perm_d g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_perm_d, i_io_resp_bits_resp_entry_0_perm_d); end
    checks++; if (g_io_resp_bits_resp_entry_0_perm_a !== i_io_resp_bits_resp_entry_0_perm_a) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_perm_a g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_perm_a, i_io_resp_bits_resp_entry_0_perm_a); end
    checks++; if (g_io_resp_bits_resp_entry_0_perm_g !== i_io_resp_bits_resp_entry_0_perm_g) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_perm_g g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_perm_g, i_io_resp_bits_resp_entry_0_perm_g); end
    checks++; if (g_io_resp_bits_resp_entry_0_perm_u !== i_io_resp_bits_resp_entry_0_perm_u) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_perm_u g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_perm_u, i_io_resp_bits_resp_entry_0_perm_u); end
    checks++; if (g_io_resp_bits_resp_entry_0_perm_x !== i_io_resp_bits_resp_entry_0_perm_x) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_perm_x g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_perm_x, i_io_resp_bits_resp_entry_0_perm_x); end
    checks++; if (g_io_resp_bits_resp_entry_0_perm_w !== i_io_resp_bits_resp_entry_0_perm_w) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_perm_w g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_perm_w, i_io_resp_bits_resp_entry_0_perm_w); end
    checks++; if (g_io_resp_bits_resp_entry_0_perm_r !== i_io_resp_bits_resp_entry_0_perm_r) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_perm_r g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_perm_r, i_io_resp_bits_resp_entry_0_perm_r); end
    checks++; if (g_io_resp_bits_resp_entry_0_level !== i_io_resp_bits_resp_entry_0_level) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_level g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_level, i_io_resp_bits_resp_entry_0_level); end
    checks++; if (g_io_resp_bits_resp_entry_0_v !== i_io_resp_bits_resp_entry_0_v) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_v g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_v, i_io_resp_bits_resp_entry_0_v); end
    checks++; if (g_io_resp_bits_resp_entry_0_ppn !== i_io_resp_bits_resp_entry_0_ppn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_ppn g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_ppn, i_io_resp_bits_resp_entry_0_ppn); end
    checks++; if (g_io_resp_bits_resp_entry_0_ppn_low !== i_io_resp_bits_resp_entry_0_ppn_low) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_ppn_low g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_ppn_low, i_io_resp_bits_resp_entry_0_ppn_low); end
    checks++; if (g_io_resp_bits_resp_entry_0_af !== i_io_resp_bits_resp_entry_0_af) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_af g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_af, i_io_resp_bits_resp_entry_0_af); end
    checks++; if (g_io_resp_bits_resp_entry_0_pf !== i_io_resp_bits_resp_entry_0_pf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_pf g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_pf, i_io_resp_bits_resp_entry_0_pf); end
    checks++; if (g_io_resp_bits_resp_entry_0_cf !== i_io_resp_bits_resp_entry_0_cf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_0_cf g=%h i=%h", cyc, g_io_resp_bits_resp_entry_0_cf, i_io_resp_bits_resp_entry_0_cf); end
    checks++; if (g_io_resp_bits_resp_entry_1_tag !== i_io_resp_bits_resp_entry_1_tag) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_tag g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_tag, i_io_resp_bits_resp_entry_1_tag); end
    checks++; if (g_io_resp_bits_resp_entry_1_asid !== i_io_resp_bits_resp_entry_1_asid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_asid g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_asid, i_io_resp_bits_resp_entry_1_asid); end
    checks++; if (g_io_resp_bits_resp_entry_1_vmid !== i_io_resp_bits_resp_entry_1_vmid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_vmid g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_vmid, i_io_resp_bits_resp_entry_1_vmid); end
    checks++; if (g_io_resp_bits_resp_entry_1_n !== i_io_resp_bits_resp_entry_1_n) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_n g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_n, i_io_resp_bits_resp_entry_1_n); end
    checks++; if (g_io_resp_bits_resp_entry_1_pbmt !== i_io_resp_bits_resp_entry_1_pbmt) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_pbmt g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_pbmt, i_io_resp_bits_resp_entry_1_pbmt); end
    checks++; if (g_io_resp_bits_resp_entry_1_perm_d !== i_io_resp_bits_resp_entry_1_perm_d) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_perm_d g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_perm_d, i_io_resp_bits_resp_entry_1_perm_d); end
    checks++; if (g_io_resp_bits_resp_entry_1_perm_a !== i_io_resp_bits_resp_entry_1_perm_a) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_perm_a g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_perm_a, i_io_resp_bits_resp_entry_1_perm_a); end
    checks++; if (g_io_resp_bits_resp_entry_1_perm_g !== i_io_resp_bits_resp_entry_1_perm_g) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_perm_g g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_perm_g, i_io_resp_bits_resp_entry_1_perm_g); end
    checks++; if (g_io_resp_bits_resp_entry_1_perm_u !== i_io_resp_bits_resp_entry_1_perm_u) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_perm_u g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_perm_u, i_io_resp_bits_resp_entry_1_perm_u); end
    checks++; if (g_io_resp_bits_resp_entry_1_perm_x !== i_io_resp_bits_resp_entry_1_perm_x) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_perm_x g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_perm_x, i_io_resp_bits_resp_entry_1_perm_x); end
    checks++; if (g_io_resp_bits_resp_entry_1_perm_w !== i_io_resp_bits_resp_entry_1_perm_w) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_perm_w g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_perm_w, i_io_resp_bits_resp_entry_1_perm_w); end
    checks++; if (g_io_resp_bits_resp_entry_1_perm_r !== i_io_resp_bits_resp_entry_1_perm_r) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_perm_r g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_perm_r, i_io_resp_bits_resp_entry_1_perm_r); end
    checks++; if (g_io_resp_bits_resp_entry_1_level !== i_io_resp_bits_resp_entry_1_level) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_level g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_level, i_io_resp_bits_resp_entry_1_level); end
    checks++; if (g_io_resp_bits_resp_entry_1_v !== i_io_resp_bits_resp_entry_1_v) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_v g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_v, i_io_resp_bits_resp_entry_1_v); end
    checks++; if (g_io_resp_bits_resp_entry_1_ppn !== i_io_resp_bits_resp_entry_1_ppn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_ppn g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_ppn, i_io_resp_bits_resp_entry_1_ppn); end
    checks++; if (g_io_resp_bits_resp_entry_1_ppn_low !== i_io_resp_bits_resp_entry_1_ppn_low) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_ppn_low g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_ppn_low, i_io_resp_bits_resp_entry_1_ppn_low); end
    checks++; if (g_io_resp_bits_resp_entry_1_af !== i_io_resp_bits_resp_entry_1_af) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_af g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_af, i_io_resp_bits_resp_entry_1_af); end
    checks++; if (g_io_resp_bits_resp_entry_1_pf !== i_io_resp_bits_resp_entry_1_pf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_pf g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_pf, i_io_resp_bits_resp_entry_1_pf); end
    checks++; if (g_io_resp_bits_resp_entry_1_cf !== i_io_resp_bits_resp_entry_1_cf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_1_cf g=%h i=%h", cyc, g_io_resp_bits_resp_entry_1_cf, i_io_resp_bits_resp_entry_1_cf); end
    checks++; if (g_io_resp_bits_resp_entry_2_tag !== i_io_resp_bits_resp_entry_2_tag) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_tag g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_tag, i_io_resp_bits_resp_entry_2_tag); end
    checks++; if (g_io_resp_bits_resp_entry_2_asid !== i_io_resp_bits_resp_entry_2_asid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_asid g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_asid, i_io_resp_bits_resp_entry_2_asid); end
    checks++; if (g_io_resp_bits_resp_entry_2_vmid !== i_io_resp_bits_resp_entry_2_vmid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_vmid g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_vmid, i_io_resp_bits_resp_entry_2_vmid); end
    checks++; if (g_io_resp_bits_resp_entry_2_n !== i_io_resp_bits_resp_entry_2_n) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_n g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_n, i_io_resp_bits_resp_entry_2_n); end
    checks++; if (g_io_resp_bits_resp_entry_2_pbmt !== i_io_resp_bits_resp_entry_2_pbmt) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_pbmt g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_pbmt, i_io_resp_bits_resp_entry_2_pbmt); end
    checks++; if (g_io_resp_bits_resp_entry_2_perm_d !== i_io_resp_bits_resp_entry_2_perm_d) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_perm_d g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_perm_d, i_io_resp_bits_resp_entry_2_perm_d); end
    checks++; if (g_io_resp_bits_resp_entry_2_perm_a !== i_io_resp_bits_resp_entry_2_perm_a) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_perm_a g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_perm_a, i_io_resp_bits_resp_entry_2_perm_a); end
    checks++; if (g_io_resp_bits_resp_entry_2_perm_g !== i_io_resp_bits_resp_entry_2_perm_g) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_perm_g g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_perm_g, i_io_resp_bits_resp_entry_2_perm_g); end
    checks++; if (g_io_resp_bits_resp_entry_2_perm_u !== i_io_resp_bits_resp_entry_2_perm_u) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_perm_u g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_perm_u, i_io_resp_bits_resp_entry_2_perm_u); end
    checks++; if (g_io_resp_bits_resp_entry_2_perm_x !== i_io_resp_bits_resp_entry_2_perm_x) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_perm_x g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_perm_x, i_io_resp_bits_resp_entry_2_perm_x); end
    checks++; if (g_io_resp_bits_resp_entry_2_perm_w !== i_io_resp_bits_resp_entry_2_perm_w) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_perm_w g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_perm_w, i_io_resp_bits_resp_entry_2_perm_w); end
    checks++; if (g_io_resp_bits_resp_entry_2_perm_r !== i_io_resp_bits_resp_entry_2_perm_r) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_perm_r g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_perm_r, i_io_resp_bits_resp_entry_2_perm_r); end
    checks++; if (g_io_resp_bits_resp_entry_2_level !== i_io_resp_bits_resp_entry_2_level) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_level g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_level, i_io_resp_bits_resp_entry_2_level); end
    checks++; if (g_io_resp_bits_resp_entry_2_v !== i_io_resp_bits_resp_entry_2_v) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_v g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_v, i_io_resp_bits_resp_entry_2_v); end
    checks++; if (g_io_resp_bits_resp_entry_2_ppn !== i_io_resp_bits_resp_entry_2_ppn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_ppn g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_ppn, i_io_resp_bits_resp_entry_2_ppn); end
    checks++; if (g_io_resp_bits_resp_entry_2_ppn_low !== i_io_resp_bits_resp_entry_2_ppn_low) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_ppn_low g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_ppn_low, i_io_resp_bits_resp_entry_2_ppn_low); end
    checks++; if (g_io_resp_bits_resp_entry_2_af !== i_io_resp_bits_resp_entry_2_af) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_af g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_af, i_io_resp_bits_resp_entry_2_af); end
    checks++; if (g_io_resp_bits_resp_entry_2_pf !== i_io_resp_bits_resp_entry_2_pf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_pf g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_pf, i_io_resp_bits_resp_entry_2_pf); end
    checks++; if (g_io_resp_bits_resp_entry_2_cf !== i_io_resp_bits_resp_entry_2_cf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_2_cf g=%h i=%h", cyc, g_io_resp_bits_resp_entry_2_cf, i_io_resp_bits_resp_entry_2_cf); end
    checks++; if (g_io_resp_bits_resp_entry_3_tag !== i_io_resp_bits_resp_entry_3_tag) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_tag g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_tag, i_io_resp_bits_resp_entry_3_tag); end
    checks++; if (g_io_resp_bits_resp_entry_3_asid !== i_io_resp_bits_resp_entry_3_asid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_asid g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_asid, i_io_resp_bits_resp_entry_3_asid); end
    checks++; if (g_io_resp_bits_resp_entry_3_vmid !== i_io_resp_bits_resp_entry_3_vmid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_vmid g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_vmid, i_io_resp_bits_resp_entry_3_vmid); end
    checks++; if (g_io_resp_bits_resp_entry_3_n !== i_io_resp_bits_resp_entry_3_n) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_n g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_n, i_io_resp_bits_resp_entry_3_n); end
    checks++; if (g_io_resp_bits_resp_entry_3_pbmt !== i_io_resp_bits_resp_entry_3_pbmt) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_pbmt g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_pbmt, i_io_resp_bits_resp_entry_3_pbmt); end
    checks++; if (g_io_resp_bits_resp_entry_3_perm_d !== i_io_resp_bits_resp_entry_3_perm_d) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_perm_d g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_perm_d, i_io_resp_bits_resp_entry_3_perm_d); end
    checks++; if (g_io_resp_bits_resp_entry_3_perm_a !== i_io_resp_bits_resp_entry_3_perm_a) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_perm_a g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_perm_a, i_io_resp_bits_resp_entry_3_perm_a); end
    checks++; if (g_io_resp_bits_resp_entry_3_perm_g !== i_io_resp_bits_resp_entry_3_perm_g) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_perm_g g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_perm_g, i_io_resp_bits_resp_entry_3_perm_g); end
    checks++; if (g_io_resp_bits_resp_entry_3_perm_u !== i_io_resp_bits_resp_entry_3_perm_u) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_perm_u g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_perm_u, i_io_resp_bits_resp_entry_3_perm_u); end
    checks++; if (g_io_resp_bits_resp_entry_3_perm_x !== i_io_resp_bits_resp_entry_3_perm_x) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_perm_x g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_perm_x, i_io_resp_bits_resp_entry_3_perm_x); end
    checks++; if (g_io_resp_bits_resp_entry_3_perm_w !== i_io_resp_bits_resp_entry_3_perm_w) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_perm_w g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_perm_w, i_io_resp_bits_resp_entry_3_perm_w); end
    checks++; if (g_io_resp_bits_resp_entry_3_perm_r !== i_io_resp_bits_resp_entry_3_perm_r) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_perm_r g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_perm_r, i_io_resp_bits_resp_entry_3_perm_r); end
    checks++; if (g_io_resp_bits_resp_entry_3_level !== i_io_resp_bits_resp_entry_3_level) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_level g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_level, i_io_resp_bits_resp_entry_3_level); end
    checks++; if (g_io_resp_bits_resp_entry_3_v !== i_io_resp_bits_resp_entry_3_v) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_v g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_v, i_io_resp_bits_resp_entry_3_v); end
    checks++; if (g_io_resp_bits_resp_entry_3_ppn !== i_io_resp_bits_resp_entry_3_ppn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_ppn g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_ppn, i_io_resp_bits_resp_entry_3_ppn); end
    checks++; if (g_io_resp_bits_resp_entry_3_ppn_low !== i_io_resp_bits_resp_entry_3_ppn_low) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_ppn_low g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_ppn_low, i_io_resp_bits_resp_entry_3_ppn_low); end
    checks++; if (g_io_resp_bits_resp_entry_3_af !== i_io_resp_bits_resp_entry_3_af) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_af g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_af, i_io_resp_bits_resp_entry_3_af); end
    checks++; if (g_io_resp_bits_resp_entry_3_pf !== i_io_resp_bits_resp_entry_3_pf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_pf g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_pf, i_io_resp_bits_resp_entry_3_pf); end
    checks++; if (g_io_resp_bits_resp_entry_3_cf !== i_io_resp_bits_resp_entry_3_cf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_3_cf g=%h i=%h", cyc, g_io_resp_bits_resp_entry_3_cf, i_io_resp_bits_resp_entry_3_cf); end
    checks++; if (g_io_resp_bits_resp_entry_4_tag !== i_io_resp_bits_resp_entry_4_tag) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_tag g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_tag, i_io_resp_bits_resp_entry_4_tag); end
    checks++; if (g_io_resp_bits_resp_entry_4_asid !== i_io_resp_bits_resp_entry_4_asid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_asid g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_asid, i_io_resp_bits_resp_entry_4_asid); end
    checks++; if (g_io_resp_bits_resp_entry_4_vmid !== i_io_resp_bits_resp_entry_4_vmid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_vmid g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_vmid, i_io_resp_bits_resp_entry_4_vmid); end
    checks++; if (g_io_resp_bits_resp_entry_4_n !== i_io_resp_bits_resp_entry_4_n) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_n g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_n, i_io_resp_bits_resp_entry_4_n); end
    checks++; if (g_io_resp_bits_resp_entry_4_pbmt !== i_io_resp_bits_resp_entry_4_pbmt) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_pbmt g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_pbmt, i_io_resp_bits_resp_entry_4_pbmt); end
    checks++; if (g_io_resp_bits_resp_entry_4_perm_d !== i_io_resp_bits_resp_entry_4_perm_d) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_perm_d g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_perm_d, i_io_resp_bits_resp_entry_4_perm_d); end
    checks++; if (g_io_resp_bits_resp_entry_4_perm_a !== i_io_resp_bits_resp_entry_4_perm_a) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_perm_a g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_perm_a, i_io_resp_bits_resp_entry_4_perm_a); end
    checks++; if (g_io_resp_bits_resp_entry_4_perm_g !== i_io_resp_bits_resp_entry_4_perm_g) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_perm_g g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_perm_g, i_io_resp_bits_resp_entry_4_perm_g); end
    checks++; if (g_io_resp_bits_resp_entry_4_perm_u !== i_io_resp_bits_resp_entry_4_perm_u) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_perm_u g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_perm_u, i_io_resp_bits_resp_entry_4_perm_u); end
    checks++; if (g_io_resp_bits_resp_entry_4_perm_x !== i_io_resp_bits_resp_entry_4_perm_x) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_perm_x g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_perm_x, i_io_resp_bits_resp_entry_4_perm_x); end
    checks++; if (g_io_resp_bits_resp_entry_4_perm_w !== i_io_resp_bits_resp_entry_4_perm_w) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_perm_w g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_perm_w, i_io_resp_bits_resp_entry_4_perm_w); end
    checks++; if (g_io_resp_bits_resp_entry_4_perm_r !== i_io_resp_bits_resp_entry_4_perm_r) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_perm_r g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_perm_r, i_io_resp_bits_resp_entry_4_perm_r); end
    checks++; if (g_io_resp_bits_resp_entry_4_level !== i_io_resp_bits_resp_entry_4_level) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_level g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_level, i_io_resp_bits_resp_entry_4_level); end
    checks++; if (g_io_resp_bits_resp_entry_4_v !== i_io_resp_bits_resp_entry_4_v) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_v g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_v, i_io_resp_bits_resp_entry_4_v); end
    checks++; if (g_io_resp_bits_resp_entry_4_ppn !== i_io_resp_bits_resp_entry_4_ppn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_ppn g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_ppn, i_io_resp_bits_resp_entry_4_ppn); end
    checks++; if (g_io_resp_bits_resp_entry_4_ppn_low !== i_io_resp_bits_resp_entry_4_ppn_low) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_ppn_low g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_ppn_low, i_io_resp_bits_resp_entry_4_ppn_low); end
    checks++; if (g_io_resp_bits_resp_entry_4_af !== i_io_resp_bits_resp_entry_4_af) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_af g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_af, i_io_resp_bits_resp_entry_4_af); end
    checks++; if (g_io_resp_bits_resp_entry_4_pf !== i_io_resp_bits_resp_entry_4_pf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_pf g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_pf, i_io_resp_bits_resp_entry_4_pf); end
    checks++; if (g_io_resp_bits_resp_entry_4_cf !== i_io_resp_bits_resp_entry_4_cf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_4_cf g=%h i=%h", cyc, g_io_resp_bits_resp_entry_4_cf, i_io_resp_bits_resp_entry_4_cf); end
    checks++; if (g_io_resp_bits_resp_entry_5_tag !== i_io_resp_bits_resp_entry_5_tag) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_tag g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_tag, i_io_resp_bits_resp_entry_5_tag); end
    checks++; if (g_io_resp_bits_resp_entry_5_asid !== i_io_resp_bits_resp_entry_5_asid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_asid g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_asid, i_io_resp_bits_resp_entry_5_asid); end
    checks++; if (g_io_resp_bits_resp_entry_5_vmid !== i_io_resp_bits_resp_entry_5_vmid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_vmid g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_vmid, i_io_resp_bits_resp_entry_5_vmid); end
    checks++; if (g_io_resp_bits_resp_entry_5_n !== i_io_resp_bits_resp_entry_5_n) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_n g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_n, i_io_resp_bits_resp_entry_5_n); end
    checks++; if (g_io_resp_bits_resp_entry_5_pbmt !== i_io_resp_bits_resp_entry_5_pbmt) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_pbmt g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_pbmt, i_io_resp_bits_resp_entry_5_pbmt); end
    checks++; if (g_io_resp_bits_resp_entry_5_perm_d !== i_io_resp_bits_resp_entry_5_perm_d) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_perm_d g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_perm_d, i_io_resp_bits_resp_entry_5_perm_d); end
    checks++; if (g_io_resp_bits_resp_entry_5_perm_a !== i_io_resp_bits_resp_entry_5_perm_a) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_perm_a g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_perm_a, i_io_resp_bits_resp_entry_5_perm_a); end
    checks++; if (g_io_resp_bits_resp_entry_5_perm_g !== i_io_resp_bits_resp_entry_5_perm_g) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_perm_g g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_perm_g, i_io_resp_bits_resp_entry_5_perm_g); end
    checks++; if (g_io_resp_bits_resp_entry_5_perm_u !== i_io_resp_bits_resp_entry_5_perm_u) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_perm_u g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_perm_u, i_io_resp_bits_resp_entry_5_perm_u); end
    checks++; if (g_io_resp_bits_resp_entry_5_perm_x !== i_io_resp_bits_resp_entry_5_perm_x) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_perm_x g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_perm_x, i_io_resp_bits_resp_entry_5_perm_x); end
    checks++; if (g_io_resp_bits_resp_entry_5_perm_w !== i_io_resp_bits_resp_entry_5_perm_w) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_perm_w g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_perm_w, i_io_resp_bits_resp_entry_5_perm_w); end
    checks++; if (g_io_resp_bits_resp_entry_5_perm_r !== i_io_resp_bits_resp_entry_5_perm_r) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_perm_r g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_perm_r, i_io_resp_bits_resp_entry_5_perm_r); end
    checks++; if (g_io_resp_bits_resp_entry_5_level !== i_io_resp_bits_resp_entry_5_level) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_level g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_level, i_io_resp_bits_resp_entry_5_level); end
    checks++; if (g_io_resp_bits_resp_entry_5_v !== i_io_resp_bits_resp_entry_5_v) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_v g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_v, i_io_resp_bits_resp_entry_5_v); end
    checks++; if (g_io_resp_bits_resp_entry_5_ppn !== i_io_resp_bits_resp_entry_5_ppn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_ppn g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_ppn, i_io_resp_bits_resp_entry_5_ppn); end
    checks++; if (g_io_resp_bits_resp_entry_5_ppn_low !== i_io_resp_bits_resp_entry_5_ppn_low) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_ppn_low g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_ppn_low, i_io_resp_bits_resp_entry_5_ppn_low); end
    checks++; if (g_io_resp_bits_resp_entry_5_af !== i_io_resp_bits_resp_entry_5_af) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_af g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_af, i_io_resp_bits_resp_entry_5_af); end
    checks++; if (g_io_resp_bits_resp_entry_5_pf !== i_io_resp_bits_resp_entry_5_pf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_pf g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_pf, i_io_resp_bits_resp_entry_5_pf); end
    checks++; if (g_io_resp_bits_resp_entry_5_cf !== i_io_resp_bits_resp_entry_5_cf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_5_cf g=%h i=%h", cyc, g_io_resp_bits_resp_entry_5_cf, i_io_resp_bits_resp_entry_5_cf); end
    checks++; if (g_io_resp_bits_resp_entry_6_tag !== i_io_resp_bits_resp_entry_6_tag) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_tag g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_tag, i_io_resp_bits_resp_entry_6_tag); end
    checks++; if (g_io_resp_bits_resp_entry_6_asid !== i_io_resp_bits_resp_entry_6_asid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_asid g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_asid, i_io_resp_bits_resp_entry_6_asid); end
    checks++; if (g_io_resp_bits_resp_entry_6_vmid !== i_io_resp_bits_resp_entry_6_vmid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_vmid g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_vmid, i_io_resp_bits_resp_entry_6_vmid); end
    checks++; if (g_io_resp_bits_resp_entry_6_n !== i_io_resp_bits_resp_entry_6_n) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_n g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_n, i_io_resp_bits_resp_entry_6_n); end
    checks++; if (g_io_resp_bits_resp_entry_6_pbmt !== i_io_resp_bits_resp_entry_6_pbmt) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_pbmt g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_pbmt, i_io_resp_bits_resp_entry_6_pbmt); end
    checks++; if (g_io_resp_bits_resp_entry_6_perm_d !== i_io_resp_bits_resp_entry_6_perm_d) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_perm_d g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_perm_d, i_io_resp_bits_resp_entry_6_perm_d); end
    checks++; if (g_io_resp_bits_resp_entry_6_perm_a !== i_io_resp_bits_resp_entry_6_perm_a) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_perm_a g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_perm_a, i_io_resp_bits_resp_entry_6_perm_a); end
    checks++; if (g_io_resp_bits_resp_entry_6_perm_g !== i_io_resp_bits_resp_entry_6_perm_g) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_perm_g g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_perm_g, i_io_resp_bits_resp_entry_6_perm_g); end
    checks++; if (g_io_resp_bits_resp_entry_6_perm_u !== i_io_resp_bits_resp_entry_6_perm_u) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_perm_u g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_perm_u, i_io_resp_bits_resp_entry_6_perm_u); end
    checks++; if (g_io_resp_bits_resp_entry_6_perm_x !== i_io_resp_bits_resp_entry_6_perm_x) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_perm_x g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_perm_x, i_io_resp_bits_resp_entry_6_perm_x); end
    checks++; if (g_io_resp_bits_resp_entry_6_perm_w !== i_io_resp_bits_resp_entry_6_perm_w) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_perm_w g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_perm_w, i_io_resp_bits_resp_entry_6_perm_w); end
    checks++; if (g_io_resp_bits_resp_entry_6_perm_r !== i_io_resp_bits_resp_entry_6_perm_r) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_perm_r g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_perm_r, i_io_resp_bits_resp_entry_6_perm_r); end
    checks++; if (g_io_resp_bits_resp_entry_6_level !== i_io_resp_bits_resp_entry_6_level) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_level g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_level, i_io_resp_bits_resp_entry_6_level); end
    checks++; if (g_io_resp_bits_resp_entry_6_v !== i_io_resp_bits_resp_entry_6_v) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_v g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_v, i_io_resp_bits_resp_entry_6_v); end
    checks++; if (g_io_resp_bits_resp_entry_6_ppn !== i_io_resp_bits_resp_entry_6_ppn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_ppn g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_ppn, i_io_resp_bits_resp_entry_6_ppn); end
    checks++; if (g_io_resp_bits_resp_entry_6_ppn_low !== i_io_resp_bits_resp_entry_6_ppn_low) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_ppn_low g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_ppn_low, i_io_resp_bits_resp_entry_6_ppn_low); end
    checks++; if (g_io_resp_bits_resp_entry_6_af !== i_io_resp_bits_resp_entry_6_af) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_af g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_af, i_io_resp_bits_resp_entry_6_af); end
    checks++; if (g_io_resp_bits_resp_entry_6_pf !== i_io_resp_bits_resp_entry_6_pf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_pf g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_pf, i_io_resp_bits_resp_entry_6_pf); end
    checks++; if (g_io_resp_bits_resp_entry_6_cf !== i_io_resp_bits_resp_entry_6_cf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_6_cf g=%h i=%h", cyc, g_io_resp_bits_resp_entry_6_cf, i_io_resp_bits_resp_entry_6_cf); end
    checks++; if (g_io_resp_bits_resp_entry_7_tag !== i_io_resp_bits_resp_entry_7_tag) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_tag g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_tag, i_io_resp_bits_resp_entry_7_tag); end
    checks++; if (g_io_resp_bits_resp_entry_7_asid !== i_io_resp_bits_resp_entry_7_asid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_asid g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_asid, i_io_resp_bits_resp_entry_7_asid); end
    checks++; if (g_io_resp_bits_resp_entry_7_vmid !== i_io_resp_bits_resp_entry_7_vmid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_vmid g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_vmid, i_io_resp_bits_resp_entry_7_vmid); end
    checks++; if (g_io_resp_bits_resp_entry_7_n !== i_io_resp_bits_resp_entry_7_n) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_n g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_n, i_io_resp_bits_resp_entry_7_n); end
    checks++; if (g_io_resp_bits_resp_entry_7_pbmt !== i_io_resp_bits_resp_entry_7_pbmt) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_pbmt g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_pbmt, i_io_resp_bits_resp_entry_7_pbmt); end
    checks++; if (g_io_resp_bits_resp_entry_7_perm_d !== i_io_resp_bits_resp_entry_7_perm_d) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_perm_d g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_perm_d, i_io_resp_bits_resp_entry_7_perm_d); end
    checks++; if (g_io_resp_bits_resp_entry_7_perm_a !== i_io_resp_bits_resp_entry_7_perm_a) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_perm_a g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_perm_a, i_io_resp_bits_resp_entry_7_perm_a); end
    checks++; if (g_io_resp_bits_resp_entry_7_perm_g !== i_io_resp_bits_resp_entry_7_perm_g) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_perm_g g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_perm_g, i_io_resp_bits_resp_entry_7_perm_g); end
    checks++; if (g_io_resp_bits_resp_entry_7_perm_u !== i_io_resp_bits_resp_entry_7_perm_u) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_perm_u g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_perm_u, i_io_resp_bits_resp_entry_7_perm_u); end
    checks++; if (g_io_resp_bits_resp_entry_7_perm_x !== i_io_resp_bits_resp_entry_7_perm_x) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_perm_x g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_perm_x, i_io_resp_bits_resp_entry_7_perm_x); end
    checks++; if (g_io_resp_bits_resp_entry_7_perm_w !== i_io_resp_bits_resp_entry_7_perm_w) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_perm_w g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_perm_w, i_io_resp_bits_resp_entry_7_perm_w); end
    checks++; if (g_io_resp_bits_resp_entry_7_perm_r !== i_io_resp_bits_resp_entry_7_perm_r) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_perm_r g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_perm_r, i_io_resp_bits_resp_entry_7_perm_r); end
    checks++; if (g_io_resp_bits_resp_entry_7_level !== i_io_resp_bits_resp_entry_7_level) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_level g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_level, i_io_resp_bits_resp_entry_7_level); end
    checks++; if (g_io_resp_bits_resp_entry_7_v !== i_io_resp_bits_resp_entry_7_v) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_v g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_v, i_io_resp_bits_resp_entry_7_v); end
    checks++; if (g_io_resp_bits_resp_entry_7_ppn !== i_io_resp_bits_resp_entry_7_ppn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_ppn g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_ppn, i_io_resp_bits_resp_entry_7_ppn); end
    checks++; if (g_io_resp_bits_resp_entry_7_ppn_low !== i_io_resp_bits_resp_entry_7_ppn_low) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_ppn_low g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_ppn_low, i_io_resp_bits_resp_entry_7_ppn_low); end
    checks++; if (g_io_resp_bits_resp_entry_7_af !== i_io_resp_bits_resp_entry_7_af) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_af g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_af, i_io_resp_bits_resp_entry_7_af); end
    checks++; if (g_io_resp_bits_resp_entry_7_pf !== i_io_resp_bits_resp_entry_7_pf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_pf g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_pf, i_io_resp_bits_resp_entry_7_pf); end
    checks++; if (g_io_resp_bits_resp_entry_7_cf !== i_io_resp_bits_resp_entry_7_cf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_7_cf g=%h i=%h", cyc, g_io_resp_bits_resp_entry_7_cf, i_io_resp_bits_resp_entry_7_cf); end
    checks++; if (g_io_resp_bits_resp_pteidx_0 !== i_io_resp_bits_resp_pteidx_0) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_pteidx_0 g=%h i=%h", cyc, g_io_resp_bits_resp_pteidx_0, i_io_resp_bits_resp_pteidx_0); end
    checks++; if (g_io_resp_bits_resp_pteidx_1 !== i_io_resp_bits_resp_pteidx_1) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_pteidx_1 g=%h i=%h", cyc, g_io_resp_bits_resp_pteidx_1, i_io_resp_bits_resp_pteidx_1); end
    checks++; if (g_io_resp_bits_resp_pteidx_2 !== i_io_resp_bits_resp_pteidx_2) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_pteidx_2 g=%h i=%h", cyc, g_io_resp_bits_resp_pteidx_2, i_io_resp_bits_resp_pteidx_2); end
    checks++; if (g_io_resp_bits_resp_pteidx_3 !== i_io_resp_bits_resp_pteidx_3) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_pteidx_3 g=%h i=%h", cyc, g_io_resp_bits_resp_pteidx_3, i_io_resp_bits_resp_pteidx_3); end
    checks++; if (g_io_resp_bits_resp_pteidx_4 !== i_io_resp_bits_resp_pteidx_4) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_pteidx_4 g=%h i=%h", cyc, g_io_resp_bits_resp_pteidx_4, i_io_resp_bits_resp_pteidx_4); end
    checks++; if (g_io_resp_bits_resp_pteidx_5 !== i_io_resp_bits_resp_pteidx_5) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_pteidx_5 g=%h i=%h", cyc, g_io_resp_bits_resp_pteidx_5, i_io_resp_bits_resp_pteidx_5); end
    checks++; if (g_io_resp_bits_resp_pteidx_6 !== i_io_resp_bits_resp_pteidx_6) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_pteidx_6 g=%h i=%h", cyc, g_io_resp_bits_resp_pteidx_6, i_io_resp_bits_resp_pteidx_6); end
    checks++; if (g_io_resp_bits_resp_pteidx_7 !== i_io_resp_bits_resp_pteidx_7) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_pteidx_7 g=%h i=%h", cyc, g_io_resp_bits_resp_pteidx_7, i_io_resp_bits_resp_pteidx_7); end
    checks++; if (g_io_resp_bits_resp_not_super !== i_io_resp_bits_resp_not_super) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_not_super g=%h i=%h", cyc, g_io_resp_bits_resp_not_super, i_io_resp_bits_resp_not_super); end
    checks++; if (g_io_resp_bits_h_resp_entry_tag !== i_io_resp_bits_h_resp_entry_tag) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_h_resp_entry_tag g=%h i=%h", cyc, g_io_resp_bits_h_resp_entry_tag, i_io_resp_bits_h_resp_entry_tag); end
    checks++; if (g_io_resp_bits_h_resp_entry_vmid !== i_io_resp_bits_h_resp_entry_vmid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_h_resp_entry_vmid g=%h i=%h", cyc, g_io_resp_bits_h_resp_entry_vmid, i_io_resp_bits_h_resp_entry_vmid); end
    checks++; if (g_io_resp_bits_h_resp_entry_n !== i_io_resp_bits_h_resp_entry_n) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_h_resp_entry_n g=%h i=%h", cyc, g_io_resp_bits_h_resp_entry_n, i_io_resp_bits_h_resp_entry_n); end
    checks++; if (g_io_resp_bits_h_resp_entry_pbmt !== i_io_resp_bits_h_resp_entry_pbmt) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_h_resp_entry_pbmt g=%h i=%h", cyc, g_io_resp_bits_h_resp_entry_pbmt, i_io_resp_bits_h_resp_entry_pbmt); end
    checks++; if (g_io_resp_bits_h_resp_entry_ppn !== i_io_resp_bits_h_resp_entry_ppn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_h_resp_entry_ppn g=%h i=%h", cyc, g_io_resp_bits_h_resp_entry_ppn, i_io_resp_bits_h_resp_entry_ppn); end
    checks++; if (g_io_resp_bits_h_resp_entry_perm_d !== i_io_resp_bits_h_resp_entry_perm_d) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_h_resp_entry_perm_d g=%h i=%h", cyc, g_io_resp_bits_h_resp_entry_perm_d, i_io_resp_bits_h_resp_entry_perm_d); end
    checks++; if (g_io_resp_bits_h_resp_entry_perm_a !== i_io_resp_bits_h_resp_entry_perm_a) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_h_resp_entry_perm_a g=%h i=%h", cyc, g_io_resp_bits_h_resp_entry_perm_a, i_io_resp_bits_h_resp_entry_perm_a); end
    checks++; if (g_io_resp_bits_h_resp_entry_perm_g !== i_io_resp_bits_h_resp_entry_perm_g) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_h_resp_entry_perm_g g=%h i=%h", cyc, g_io_resp_bits_h_resp_entry_perm_g, i_io_resp_bits_h_resp_entry_perm_g); end
    checks++; if (g_io_resp_bits_h_resp_entry_perm_u !== i_io_resp_bits_h_resp_entry_perm_u) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_h_resp_entry_perm_u g=%h i=%h", cyc, g_io_resp_bits_h_resp_entry_perm_u, i_io_resp_bits_h_resp_entry_perm_u); end
    checks++; if (g_io_resp_bits_h_resp_entry_perm_x !== i_io_resp_bits_h_resp_entry_perm_x) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_h_resp_entry_perm_x g=%h i=%h", cyc, g_io_resp_bits_h_resp_entry_perm_x, i_io_resp_bits_h_resp_entry_perm_x); end
    checks++; if (g_io_resp_bits_h_resp_entry_perm_w !== i_io_resp_bits_h_resp_entry_perm_w) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_h_resp_entry_perm_w g=%h i=%h", cyc, g_io_resp_bits_h_resp_entry_perm_w, i_io_resp_bits_h_resp_entry_perm_w); end
    checks++; if (g_io_resp_bits_h_resp_entry_perm_r !== i_io_resp_bits_h_resp_entry_perm_r) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_h_resp_entry_perm_r g=%h i=%h", cyc, g_io_resp_bits_h_resp_entry_perm_r, i_io_resp_bits_h_resp_entry_perm_r); end
    checks++; if (g_io_resp_bits_h_resp_entry_level !== i_io_resp_bits_h_resp_entry_level) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_h_resp_entry_level g=%h i=%h", cyc, g_io_resp_bits_h_resp_entry_level, i_io_resp_bits_h_resp_entry_level); end
    checks++; if (g_io_resp_bits_h_resp_gpf !== i_io_resp_bits_h_resp_gpf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_h_resp_gpf g=%h i=%h", cyc, g_io_resp_bits_h_resp_gpf, i_io_resp_bits_h_resp_gpf); end
    checks++; if (g_io_resp_bits_h_resp_gaf !== i_io_resp_bits_h_resp_gaf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_h_resp_gaf g=%h i=%h", cyc, g_io_resp_bits_h_resp_gaf, i_io_resp_bits_h_resp_gaf); end
    checks++; if (g_io_llptw_valid !== i_io_llptw_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_llptw_valid g=%h i=%h", cyc, g_io_llptw_valid, i_io_llptw_valid); end
    checks++; if (g_io_llptw_bits_req_info_vpn !== i_io_llptw_bits_req_info_vpn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_llptw_bits_req_info_vpn g=%h i=%h", cyc, g_io_llptw_bits_req_info_vpn, i_io_llptw_bits_req_info_vpn); end
    checks++; if (g_io_llptw_bits_req_info_s2xlate !== i_io_llptw_bits_req_info_s2xlate) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_llptw_bits_req_info_s2xlate g=%h i=%h", cyc, g_io_llptw_bits_req_info_s2xlate, i_io_llptw_bits_req_info_s2xlate); end
    checks++; if (g_io_llptw_bits_req_info_source !== i_io_llptw_bits_req_info_source) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_llptw_bits_req_info_source g=%h i=%h", cyc, g_io_llptw_bits_req_info_source, i_io_llptw_bits_req_info_source); end
    checks++; if (g_io_hptw_req_valid !== i_io_hptw_req_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_hptw_req_valid g=%h i=%h", cyc, g_io_hptw_req_valid, i_io_hptw_req_valid); end
    checks++; if (g_io_hptw_req_bits_source !== i_io_hptw_req_bits_source) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_hptw_req_bits_source g=%h i=%h", cyc, g_io_hptw_req_bits_source, i_io_hptw_req_bits_source); end
    checks++; if (g_io_hptw_req_bits_gvpn !== i_io_hptw_req_bits_gvpn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_hptw_req_bits_gvpn g=%h i=%h", cyc, g_io_hptw_req_bits_gvpn, i_io_hptw_req_bits_gvpn); end
    checks++; if (g_io_mem_req_valid !== i_io_mem_req_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_req_valid g=%h i=%h", cyc, g_io_mem_req_valid, i_io_mem_req_valid); end
    checks++; if (g_io_mem_req_bits_addr !== i_io_mem_req_bits_addr) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_req_bits_addr g=%h i=%h", cyc, g_io_mem_req_bits_addr, i_io_mem_req_bits_addr); end
    checks++; if (g_io_pmp_req_bits_addr !== i_io_pmp_req_bits_addr) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_pmp_req_bits_addr g=%h i=%h", cyc, g_io_pmp_req_bits_addr, i_io_pmp_req_bits_addr); end
    checks++; if (g_io_refill_req_info_vpn !== i_io_refill_req_info_vpn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_refill_req_info_vpn g=%h i=%h", cyc, g_io_refill_req_info_vpn, i_io_refill_req_info_vpn); end
    checks++; if (g_io_refill_req_info_s2xlate !== i_io_refill_req_info_s2xlate) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_refill_req_info_s2xlate g=%h i=%h", cyc, g_io_refill_req_info_s2xlate, i_io_refill_req_info_s2xlate); end
    checks++; if (g_io_refill_req_info_source !== i_io_refill_req_info_source) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_refill_req_info_source g=%h i=%h", cyc, g_io_refill_req_info_source, i_io_refill_req_info_source); end
    checks++; if (g_io_refill_level !== i_io_refill_level) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_refill_level g=%h i=%h", cyc, g_io_refill_level, i_io_refill_level); end
    checks++; if (g_io_bitmap_req_valid !== i_io_bitmap_req_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_valid g=%h i=%h", cyc, g_io_bitmap_req_valid, i_io_bitmap_req_valid); end
    checks++; if (g_io_bitmap_req_bits_bmppn !== i_io_bitmap_req_bits_bmppn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_bits_bmppn g=%h i=%h", cyc, g_io_bitmap_req_bits_bmppn, i_io_bitmap_req_bits_bmppn); end
    checks++; if (g_io_bitmap_req_bits_vpn !== i_io_bitmap_req_bits_vpn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_bits_vpn g=%h i=%h", cyc, g_io_bitmap_req_bits_vpn, i_io_bitmap_req_bits_vpn); end
    checks++; if (g_io_bitmap_req_bits_level !== i_io_bitmap_req_bits_level) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_bits_level g=%h i=%h", cyc, g_io_bitmap_req_bits_level, i_io_bitmap_req_bits_level); end
    checks++; if (g_io_bitmap_req_bits_s2xlate !== i_io_bitmap_req_bits_s2xlate) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_bits_s2xlate g=%h i=%h", cyc, g_io_bitmap_req_bits_s2xlate, i_io_bitmap_req_bits_s2xlate); end
    checks++; if (g_io_bitmap_req_bits_n !== i_io_bitmap_req_bits_n) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_bits_n g=%h i=%h", cyc, g_io_bitmap_req_bits_n, i_io_bitmap_req_bits_n); end
    checks++; if (g_io_bitmap_resp_ready !== i_io_bitmap_resp_ready) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_resp_ready g=%h i=%h", cyc, g_io_bitmap_resp_ready, i_io_bitmap_resp_ready); end
    checks++; if (g_io_perf_0_value !== i_io_perf_0_value) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_perf_0_value g=%h i=%h", cyc, g_io_perf_0_value, i_io_perf_0_value); end
    checks++; if (g_io_perf_1_value !== i_io_perf_1_value) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_perf_1_value g=%h i=%h", cyc, g_io_perf_1_value, i_io_perf_1_value); end
    checks++; if (g_io_perf_2_value !== i_io_perf_2_value) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_perf_2_value g=%h i=%h", cyc, g_io_perf_2_value, i_io_perf_2_value); end
    checks++; if (g_io_perf_3_value !== i_io_perf_3_value) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_perf_3_value g=%h i=%h", cyc, g_io_perf_3_value, i_io_perf_3_value); end
    checks++; if (g_io_perf_4_value !== i_io_perf_4_value) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_perf_4_value g=%h i=%h", cyc, g_io_perf_4_value, i_io_perf_4_value); end
    checks++; if (g_io_perf_5_value !== i_io_perf_5_value) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_perf_5_value g=%h i=%h", cyc, g_io_perf_5_value, i_io_perf_5_value); end
    checks++; if (g_io_perf_6_value !== i_io_perf_6_value) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_perf_6_value g=%h i=%h", cyc, g_io_perf_6_value, i_io_perf_6_value); end
  endtask
  // END GENERATED(harness)

  logic [37:0] vpn_pool [4];
  int cyc = 0;

  function automatic logic [3:0] rand_mode();
    int m = $urandom_range(0, 9);
    return (m < 6) ? 4'h9 : (m < 9) ? 4'h8 : 4'($urandom());
  endfunction

  function automatic logic [43:0] rand_ppn44();
    logic [43:0] p = {$urandom(), $urandom()};
    if ($urandom_range(0, 3) != 0) p[43:29] = '0;
    return p;
  endfunction

  function automatic logic [63:0] rand_pte(input logic [1:0] lvl);
    logic [63:0] p;
    int kind;
    p = {$urandom(), $urandom()};
    kind = $urandom_range(0, 2);
    if (kind == 0) begin            // 干净的 next 型
      p[63:46] = '0; p[7:0] = 8'b0000_0001; p[9:8] = '0;
    end else if (kind == 1) begin   // 干净的叶子，按 lvl 对齐
      p[63:46] = '0; p[7:0] = 8'b1101_0011;  // d=1 a=1 u=1 r=1 v=1
      p[5] = $urandom_range(0, 1); p[7] = $urandom_range(0, 1);
      p[3] = $urandom_range(0, 1); p[2] = $urandom_range(0, 1);
      if (lvl == 2'd1) p[18:10] = '0;
      if (lvl == 2'd2) p[27:10] = '0;
      if (lvl == 2'd3) p[36:10] = '0;
      if ($urandom_range(0, 7) == 0) p[63] = 1'b1;
      if ($urandom_range(0, 7) == 0) p[13:10] = 4'd8;
    end
    return p;
  endfunction

  task automatic drive_random();
    io_sfence_valid          <= ($urandom_range(0, 499) == 0);
    io_csr_satp_changed      <= ($urandom_range(0, 499) == 0);
    io_csr_vsatp_changed     <= ($urandom_range(0, 499) == 0);
    io_csr_hgatp_changed     <= ($urandom_range(0, 499) == 0);
    io_csr_priv_virt_changed <= ($urandom_range(0, 499) == 0);
    if (cyc % 512 == 0) begin
      io_csr_satp_mode  <= rand_mode();  io_csr_satp_asid  <= $urandom();  io_csr_satp_ppn  <= rand_ppn44();
      io_csr_vsatp_mode <= rand_mode();  io_csr_vsatp_asid <= $urandom();  io_csr_vsatp_ppn <= rand_ppn44();
      io_csr_hgatp_mode <= rand_mode();  io_csr_hgatp_vmid <= $urandom();
      io_csr_mPBMTE <= $urandom_range(0, 1); io_csr_hPBMTE <= $urandom_range(0, 1);
    end
    if (cyc % 256 == 0) begin
      io_csr_mbmc_BME   <= $urandom_range(0, 1);
      io_csr_mbmc_CMODE <= $urandom_range(0, 2) == 0;
    end
    // ---- 请求 ----
    io_req_valid <= $urandom_range(0, 1);
    begin
      automatic logic [37:0] v = ($urandom_range(0, 3) == 0) ? {$urandom(), $urandom()} : vpn_pool[$urandom_range(0, 3)];
      if ($urandom_range(0, 1)) v[37:29] = '0;
      io_req_bits_req_info_vpn <= v;
    end
    io_req_bits_req_info_s2xlate <= $urandom();
    io_req_bits_req_info_source  <= $urandom();
    io_req_bits_l3Hit <= $urandom_range(0, 1);
    io_req_bits_l2Hit <= $urandom_range(0, 1);
    io_req_bits_ppn   <= rand_ppn44();
    io_req_bits_stage1Hit <= $urandom_range(0, 3) == 0;
    io_req_bits_bitmapCheck_jmp_bitmap_check <= $urandom_range(0, 3) == 0;
    io_req_bits_bitmapCheck_pte     <= rand_pte($urandom_range(0, 3));
    io_req_bits_bitmapCheck_SPlevel <= $urandom();
    begin
      automatic logic [7:0] oh = 8'd1 << $urandom_range(0, 7);
      if ($urandom_range(0, 7) == 0) oh = $urandom();
      {io_req_bits_stage1_pteidx_7, io_req_bits_stage1_pteidx_6, io_req_bits_stage1_pteidx_5, io_req_bits_stage1_pteidx_4,
       io_req_bits_stage1_pteidx_3, io_req_bits_stage1_pteidx_2, io_req_bits_stage1_pteidx_1, io_req_bits_stage1_pteidx_0} <= oh;
    end
    io_req_bits_stage1_not_super <= $urandom_range(0, 1);
    `define S1_RAND(i) \
      io_req_bits_stage1_entry_``i``_tag <= {$urandom(), $urandom()}; io_req_bits_stage1_entry_``i``_asid <= $urandom(); \
      io_req_bits_stage1_entry_``i``_vmid <= $urandom(); io_req_bits_stage1_entry_``i``_n <= $urandom_range(0, 1); \
      io_req_bits_stage1_entry_``i``_pbmt <= $urandom(); \
      io_req_bits_stage1_entry_``i``_perm_d <= $urandom_range(0, 1); io_req_bits_stage1_entry_``i``_perm_a <= $urandom_range(0, 1); \
      io_req_bits_stage1_entry_``i``_perm_g <= $urandom_range(0, 1); io_req_bits_stage1_entry_``i``_perm_u <= $urandom_range(0, 1); \
      io_req_bits_stage1_entry_``i``_perm_x <= $urandom_range(0, 1); io_req_bits_stage1_entry_``i``_perm_w <= $urandom_range(0, 1); \
      io_req_bits_stage1_entry_``i``_perm_r <= $urandom_range(0, 1); io_req_bits_stage1_entry_``i``_level <= $urandom(); \
      io_req_bits_stage1_entry_``i``_v <= $urandom_range(0, 1); io_req_bits_stage1_entry_``i``_ppn <= {$urandom(), $urandom()}; \
      io_req_bits_stage1_entry_``i``_ppn_low <= $urandom(); io_req_bits_stage1_entry_``i``_pf <= $urandom_range(0, 1); \
      io_req_bits_stage1_entry_``i``_cf <= $urandom_range(0, 1);
    `S1_RAND(0) `S1_RAND(1) `S1_RAND(2) `S1_RAND(3) `S1_RAND(4) `S1_RAND(5) `S1_RAND(6) `S1_RAND(7)
    // ---- 各响应通道 ----
    io_resp_ready      <= $urandom_range(0, 3) != 0;
    io_llptw_ready     <= $urandom_range(0, 3) != 0;
    io_hptw_req_ready  <= $urandom_range(0, 3) != 0;
    io_hptw_resp_valid <= $urandom_range(0, 2) == 0;
    io_hptw_resp_bits_h_resp_entry_tag  <= {$urandom(), $urandom()};
    io_hptw_resp_bits_h_resp_entry_vmid <= $urandom();
    io_hptw_resp_bits_h_resp_entry_n    <= $urandom_range(0, 1);
    io_hptw_resp_bits_h_resp_entry_pbmt <= $urandom();
    io_hptw_resp_bits_h_resp_entry_ppn  <= {$urandom(), $urandom()};
    io_hptw_resp_bits_h_resp_entry_perm_d <= $urandom_range(0, 1);
    io_hptw_resp_bits_h_resp_entry_perm_a <= $urandom_range(0, 1);
    io_hptw_resp_bits_h_resp_entry_perm_g <= $urandom_range(0, 1);
    io_hptw_resp_bits_h_resp_entry_perm_u <= $urandom_range(0, 1);
    io_hptw_resp_bits_h_resp_entry_perm_x <= $urandom_range(0, 1);
    io_hptw_resp_bits_h_resp_entry_perm_w <= $urandom_range(0, 1);
    io_hptw_resp_bits_h_resp_entry_perm_r <= $urandom_range(0, 3) != 0;
    io_hptw_resp_bits_h_resp_entry_level  <= $urandom();
    io_hptw_resp_bits_h_resp_gpf <= $urandom_range(0, 7) == 0;
    io_hptw_resp_bits_h_resp_gaf <= $urandom_range(0, 7) == 0;
    io_mem_req_ready  <= $urandom_range(0, 3) != 0;
    io_mem_resp_valid <= $urandom_range(0, 2) == 0;
    io_mem_resp_bits  <= rand_pte(u_g.level);
    io_mem_mask       <= $urandom_range(0, 9) == 0;
    io_pmp_resp_ld    <= $urandom_range(0, 19) == 0;
    io_pmp_resp_mmio  <= $urandom_range(0, 19) == 0;
    io_bitmap_req_ready    <= $urandom_range(0, 3) != 0;
    io_bitmap_resp_valid   <= $urandom_range(0, 2) == 0;
    io_bitmap_resp_bits_cf <= $urandom_range(0, 1);
  endtask

  task automatic count_cov();
    if (g_io_resp_valid && io_resp_ready) begin
      cov_resp++;
      cov_s2x[g_io_resp_bits_s2xlate]++;
      if (g_io_resp_bits_h_resp_gpf) cov_gpf++;
      if (g_io_resp_bits_h_resp_gaf) cov_gaf++;
      if (g_io_resp_bits_resp_entry_0_pf) cov_pf++;
      if (g_io_resp_bits_resp_entry_0_af) cov_af++;
      if (u_g.stage1Hit) cov_s1++;
      if (u_g.jmp_bitmap_check_r) cov_jmp++;
      if (io_csr_satp_mode == 4'h8) cov_sv39++;
    end
    if (g_io_llptw_valid && io_llptw_ready) cov_llptw++;
    if (g_io_hptw_req_valid && io_hptw_req_ready) cov_hptw_req++;
    if (g_io_mem_req_valid && io_mem_req_ready) cov_mem_req++;
    if (g_io_bitmap_req_valid && io_bitmap_req_ready) cov_bm_req++;
  endtask

  initial clock = 0;
  always #5 clock = ~clock;

  initial begin
    if (!$value$plusargs("ncycles=%d", ncycles)) ncycles = 200000;
    for (int i = 0; i < 4; i++) vpn_pool[i] = {$urandom(), $urandom()};
    reset = 1;
    io_sfence_valid = 0;
    io_csr_satp_mode = 0;
    io_csr_satp_asid = 0;
    io_csr_satp_ppn = 0;
    io_csr_satp_changed = 0;
    io_csr_vsatp_mode = 0;
    io_csr_vsatp_asid = 0;
    io_csr_vsatp_ppn = 0;
    io_csr_vsatp_changed = 0;
    io_csr_hgatp_mode = 0;
    io_csr_hgatp_vmid = 0;
    io_csr_hgatp_changed = 0;
    io_csr_mbmc_BME = 0;
    io_csr_mbmc_CMODE = 0;
    io_csr_priv_virt_changed = 0;
    io_csr_mPBMTE = 0;
    io_csr_hPBMTE = 0;
    io_req_valid = 0;
    io_req_bits_req_info_vpn = 0;
    io_req_bits_req_info_s2xlate = 0;
    io_req_bits_req_info_source = 0;
    io_req_bits_l3Hit = 0;
    io_req_bits_l2Hit = 0;
    io_req_bits_ppn = 0;
    io_req_bits_stage1Hit = 0;
    io_req_bits_stage1_entry_0_tag = 0;
    io_req_bits_stage1_entry_0_asid = 0;
    io_req_bits_stage1_entry_0_vmid = 0;
    io_req_bits_stage1_entry_0_n = 0;
    io_req_bits_stage1_entry_0_pbmt = 0;
    io_req_bits_stage1_entry_0_perm_d = 0;
    io_req_bits_stage1_entry_0_perm_a = 0;
    io_req_bits_stage1_entry_0_perm_g = 0;
    io_req_bits_stage1_entry_0_perm_u = 0;
    io_req_bits_stage1_entry_0_perm_x = 0;
    io_req_bits_stage1_entry_0_perm_w = 0;
    io_req_bits_stage1_entry_0_perm_r = 0;
    io_req_bits_stage1_entry_0_level = 0;
    io_req_bits_stage1_entry_0_v = 0;
    io_req_bits_stage1_entry_0_ppn = 0;
    io_req_bits_stage1_entry_0_ppn_low = 0;
    io_req_bits_stage1_entry_0_pf = 0;
    io_req_bits_stage1_entry_0_cf = 0;
    io_req_bits_stage1_entry_1_tag = 0;
    io_req_bits_stage1_entry_1_asid = 0;
    io_req_bits_stage1_entry_1_vmid = 0;
    io_req_bits_stage1_entry_1_n = 0;
    io_req_bits_stage1_entry_1_pbmt = 0;
    io_req_bits_stage1_entry_1_perm_d = 0;
    io_req_bits_stage1_entry_1_perm_a = 0;
    io_req_bits_stage1_entry_1_perm_g = 0;
    io_req_bits_stage1_entry_1_perm_u = 0;
    io_req_bits_stage1_entry_1_perm_x = 0;
    io_req_bits_stage1_entry_1_perm_w = 0;
    io_req_bits_stage1_entry_1_perm_r = 0;
    io_req_bits_stage1_entry_1_level = 0;
    io_req_bits_stage1_entry_1_v = 0;
    io_req_bits_stage1_entry_1_ppn = 0;
    io_req_bits_stage1_entry_1_ppn_low = 0;
    io_req_bits_stage1_entry_1_pf = 0;
    io_req_bits_stage1_entry_1_cf = 0;
    io_req_bits_stage1_entry_2_tag = 0;
    io_req_bits_stage1_entry_2_asid = 0;
    io_req_bits_stage1_entry_2_vmid = 0;
    io_req_bits_stage1_entry_2_n = 0;
    io_req_bits_stage1_entry_2_pbmt = 0;
    io_req_bits_stage1_entry_2_perm_d = 0;
    io_req_bits_stage1_entry_2_perm_a = 0;
    io_req_bits_stage1_entry_2_perm_g = 0;
    io_req_bits_stage1_entry_2_perm_u = 0;
    io_req_bits_stage1_entry_2_perm_x = 0;
    io_req_bits_stage1_entry_2_perm_w = 0;
    io_req_bits_stage1_entry_2_perm_r = 0;
    io_req_bits_stage1_entry_2_level = 0;
    io_req_bits_stage1_entry_2_v = 0;
    io_req_bits_stage1_entry_2_ppn = 0;
    io_req_bits_stage1_entry_2_ppn_low = 0;
    io_req_bits_stage1_entry_2_pf = 0;
    io_req_bits_stage1_entry_2_cf = 0;
    io_req_bits_stage1_entry_3_tag = 0;
    io_req_bits_stage1_entry_3_asid = 0;
    io_req_bits_stage1_entry_3_vmid = 0;
    io_req_bits_stage1_entry_3_n = 0;
    io_req_bits_stage1_entry_3_pbmt = 0;
    io_req_bits_stage1_entry_3_perm_d = 0;
    io_req_bits_stage1_entry_3_perm_a = 0;
    io_req_bits_stage1_entry_3_perm_g = 0;
    io_req_bits_stage1_entry_3_perm_u = 0;
    io_req_bits_stage1_entry_3_perm_x = 0;
    io_req_bits_stage1_entry_3_perm_w = 0;
    io_req_bits_stage1_entry_3_perm_r = 0;
    io_req_bits_stage1_entry_3_level = 0;
    io_req_bits_stage1_entry_3_v = 0;
    io_req_bits_stage1_entry_3_ppn = 0;
    io_req_bits_stage1_entry_3_ppn_low = 0;
    io_req_bits_stage1_entry_3_pf = 0;
    io_req_bits_stage1_entry_3_cf = 0;
    io_req_bits_stage1_entry_4_tag = 0;
    io_req_bits_stage1_entry_4_asid = 0;
    io_req_bits_stage1_entry_4_vmid = 0;
    io_req_bits_stage1_entry_4_n = 0;
    io_req_bits_stage1_entry_4_pbmt = 0;
    io_req_bits_stage1_entry_4_perm_d = 0;
    io_req_bits_stage1_entry_4_perm_a = 0;
    io_req_bits_stage1_entry_4_perm_g = 0;
    io_req_bits_stage1_entry_4_perm_u = 0;
    io_req_bits_stage1_entry_4_perm_x = 0;
    io_req_bits_stage1_entry_4_perm_w = 0;
    io_req_bits_stage1_entry_4_perm_r = 0;
    io_req_bits_stage1_entry_4_level = 0;
    io_req_bits_stage1_entry_4_v = 0;
    io_req_bits_stage1_entry_4_ppn = 0;
    io_req_bits_stage1_entry_4_ppn_low = 0;
    io_req_bits_stage1_entry_4_pf = 0;
    io_req_bits_stage1_entry_4_cf = 0;
    io_req_bits_stage1_entry_5_tag = 0;
    io_req_bits_stage1_entry_5_asid = 0;
    io_req_bits_stage1_entry_5_vmid = 0;
    io_req_bits_stage1_entry_5_n = 0;
    io_req_bits_stage1_entry_5_pbmt = 0;
    io_req_bits_stage1_entry_5_perm_d = 0;
    io_req_bits_stage1_entry_5_perm_a = 0;
    io_req_bits_stage1_entry_5_perm_g = 0;
    io_req_bits_stage1_entry_5_perm_u = 0;
    io_req_bits_stage1_entry_5_perm_x = 0;
    io_req_bits_stage1_entry_5_perm_w = 0;
    io_req_bits_stage1_entry_5_perm_r = 0;
    io_req_bits_stage1_entry_5_level = 0;
    io_req_bits_stage1_entry_5_v = 0;
    io_req_bits_stage1_entry_5_ppn = 0;
    io_req_bits_stage1_entry_5_ppn_low = 0;
    io_req_bits_stage1_entry_5_pf = 0;
    io_req_bits_stage1_entry_5_cf = 0;
    io_req_bits_stage1_entry_6_tag = 0;
    io_req_bits_stage1_entry_6_asid = 0;
    io_req_bits_stage1_entry_6_vmid = 0;
    io_req_bits_stage1_entry_6_n = 0;
    io_req_bits_stage1_entry_6_pbmt = 0;
    io_req_bits_stage1_entry_6_perm_d = 0;
    io_req_bits_stage1_entry_6_perm_a = 0;
    io_req_bits_stage1_entry_6_perm_g = 0;
    io_req_bits_stage1_entry_6_perm_u = 0;
    io_req_bits_stage1_entry_6_perm_x = 0;
    io_req_bits_stage1_entry_6_perm_w = 0;
    io_req_bits_stage1_entry_6_perm_r = 0;
    io_req_bits_stage1_entry_6_level = 0;
    io_req_bits_stage1_entry_6_v = 0;
    io_req_bits_stage1_entry_6_ppn = 0;
    io_req_bits_stage1_entry_6_ppn_low = 0;
    io_req_bits_stage1_entry_6_pf = 0;
    io_req_bits_stage1_entry_6_cf = 0;
    io_req_bits_stage1_entry_7_tag = 0;
    io_req_bits_stage1_entry_7_asid = 0;
    io_req_bits_stage1_entry_7_vmid = 0;
    io_req_bits_stage1_entry_7_n = 0;
    io_req_bits_stage1_entry_7_pbmt = 0;
    io_req_bits_stage1_entry_7_perm_d = 0;
    io_req_bits_stage1_entry_7_perm_a = 0;
    io_req_bits_stage1_entry_7_perm_g = 0;
    io_req_bits_stage1_entry_7_perm_u = 0;
    io_req_bits_stage1_entry_7_perm_x = 0;
    io_req_bits_stage1_entry_7_perm_w = 0;
    io_req_bits_stage1_entry_7_perm_r = 0;
    io_req_bits_stage1_entry_7_level = 0;
    io_req_bits_stage1_entry_7_v = 0;
    io_req_bits_stage1_entry_7_ppn = 0;
    io_req_bits_stage1_entry_7_ppn_low = 0;
    io_req_bits_stage1_entry_7_pf = 0;
    io_req_bits_stage1_entry_7_cf = 0;
    io_req_bits_stage1_pteidx_0 = 0;
    io_req_bits_stage1_pteidx_1 = 0;
    io_req_bits_stage1_pteidx_2 = 0;
    io_req_bits_stage1_pteidx_3 = 0;
    io_req_bits_stage1_pteidx_4 = 0;
    io_req_bits_stage1_pteidx_5 = 0;
    io_req_bits_stage1_pteidx_6 = 0;
    io_req_bits_stage1_pteidx_7 = 0;
    io_req_bits_stage1_not_super = 0;
    io_req_bits_bitmapCheck_jmp_bitmap_check = 0;
    io_req_bits_bitmapCheck_pte = 0;
    io_req_bits_bitmapCheck_SPlevel = 0;
    io_resp_ready = 0;
    io_llptw_ready = 0;
    io_hptw_req_ready = 0;
    io_hptw_resp_valid = 0;
    io_hptw_resp_bits_h_resp_entry_tag = 0;
    io_hptw_resp_bits_h_resp_entry_vmid = 0;
    io_hptw_resp_bits_h_resp_entry_n = 0;
    io_hptw_resp_bits_h_resp_entry_pbmt = 0;
    io_hptw_resp_bits_h_resp_entry_ppn = 0;
    io_hptw_resp_bits_h_resp_entry_perm_d = 0;
    io_hptw_resp_bits_h_resp_entry_perm_a = 0;
    io_hptw_resp_bits_h_resp_entry_perm_g = 0;
    io_hptw_resp_bits_h_resp_entry_perm_u = 0;
    io_hptw_resp_bits_h_resp_entry_perm_x = 0;
    io_hptw_resp_bits_h_resp_entry_perm_w = 0;
    io_hptw_resp_bits_h_resp_entry_perm_r = 0;
    io_hptw_resp_bits_h_resp_entry_level = 0;
    io_hptw_resp_bits_h_resp_gpf = 0;
    io_hptw_resp_bits_h_resp_gaf = 0;
    io_mem_req_ready = 0;
    io_mem_resp_valid = 0;
    io_mem_resp_bits = 0;
    io_mem_mask = 0;
    io_pmp_resp_ld = 0;
    io_pmp_resp_mmio = 0;
    io_bitmap_req_ready = 0;
    io_bitmap_resp_valid = 0;
    io_bitmap_resp_bits_cf = 0;
    io_csr_satp_mode = 4'h9; io_csr_vsatp_mode = 4'h9; io_csr_hgatp_mode = 4'h9;
    repeat (4) @(posedge clock);
    #1 reset = 0;
    for (cyc = 1; cyc <= ncycles; cyc++) begin
      @(negedge clock);
      compare_outputs(cyc);
      count_cov();
      drive_random();
    end
    $display("cov: resp=%0d llptw=%0d hptw_req=%0d mem_req=%0d gpf=%0d gaf=%0d pf=%0d af=%0d s1=%0d jmp=%0d bm_req=%0d sv39=%0d s2x=%0d/%0d/%0d/%0d",
             cov_resp, cov_llptw, cov_hptw_req, cov_mem_req, cov_gpf, cov_gaf, cov_pf, cov_af, cov_s1, cov_jmp, cov_bm_req, cov_sv39,
             cov_s2x[0], cov_s2x[1], cov_s2x[2], cov_s2x[3]);
    if (cov_resp == 0 || cov_llptw == 0 || cov_hptw_req == 0 || cov_mem_req == 0 || cov_gpf == 0 || cov_gaf == 0 ||
        cov_pf == 0 || cov_af == 0 || cov_s1 == 0 || cov_jmp == 0 || cov_bm_req == 0 || cov_sv39 == 0 ||
        cov_s2x[0] == 0 || cov_s2x[1] == 0 || cov_s2x[2] == 0 || cov_s2x[3] == 0) begin
      $display("COVERAGE FLOOR NOT MET");
      errors++;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
