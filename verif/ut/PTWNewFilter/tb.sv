// =============================================================================
// PTWNewFilter UT —— golden PTWNewFilter 对重写 PTWNewFilter_xs 双例化，同激励逐拍比对全部 78 根输出（340 位）。
// 本文件由 verif/ut/PTWNewFilter/gen_tb.py 生成（幂等），不要手改。
//
// 激励要点（判别力来自哪里）：
//   · 8 个 dtlb 口（load 0..3 / store 4..5 / prefetch 6..7）的 miss vpn 从 12 项小池子取，组内常常同页
//     （同拍借 id）、跨组同页（两张表各自入表、各自发出）、与表内已有项同页（去重）；池里有同一 2MB 区域
//     的几页，PTW 回超页时一次销多项、多张表同拍 refill。
//   · PTW 模型：golden 发出且被收下的请求在 1~6 拍后回一个**就是那一页**的响应（命中键对得上，其余载荷全随机），
//     偶尔凭空回应；ptw_req.ready 随机（60%），三张表常同时有待发请求 → 轮转仲裁的每个相位都会走到。
//   · flush 五个源（sfence / satp / vsatp / hgatp / virt changed）各以小概率单独脉冲，经 2 拍延迟清表。
//   · 偶发 3 拍复位脉冲（复位期间不比）。
// 比较窗口：表项载荷、PTW 响应载荷寄存器、hint 打拍寄存器都不复位，+random 档两侧初值不同。复位释放后先等：
//   三张表共 32 项每一项都入过表、PTW 响应来过、load 表 hint.resp.valid 出现过（RegEnable 的 hint.resp.bits
//   才被写过），再加 4 拍，之后逐拍全比。这段等待在 +0 档同样生效，checks 照实打印。
// 覆盖判据（在重写核的语义名上数；输出逐拍相等）：三张表各自入表 / 各自被仲裁发出 / 各自 refill / 两张以上
//   表同时待发 / 两张以上表同拍 refill / flush 时表非空 / load hint replay_all / 三张表各自 getGpa /
//   rob_head_miss —— 每一类都必须发生过，否则本轮不作数（TEST FAILED）。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  bit  clk = 0;
  int  errors = 0;
  longint checks = 0;
  always #5 clk = ~clk;

  logic reset;
  logic io_sfence_valid;
  logic [15:0] io_csr_satp_asid;
  logic io_csr_satp_changed;
  logic [15:0] io_csr_vsatp_asid;
  logic io_csr_vsatp_changed;
  logic [15:0] io_csr_hgatp_vmid;
  logic io_csr_hgatp_changed;
  logic io_csr_priv_virt_changed;
  logic io_tlb_req_0_valid;
  logic [37:0] io_tlb_req_0_bits_vpn;
  logic [1:0] io_tlb_req_0_bits_s2xlate;
  logic io_tlb_req_0_bits_getGpa;
  logic io_tlb_req_1_valid;
  logic [37:0] io_tlb_req_1_bits_vpn;
  logic [1:0] io_tlb_req_1_bits_s2xlate;
  logic io_tlb_req_1_bits_getGpa;
  logic io_tlb_req_2_valid;
  logic [37:0] io_tlb_req_2_bits_vpn;
  logic [1:0] io_tlb_req_2_bits_s2xlate;
  logic io_tlb_req_2_bits_getGpa;
  logic io_tlb_req_3_valid;
  logic [37:0] io_tlb_req_3_bits_vpn;
  logic [1:0] io_tlb_req_3_bits_s2xlate;
  logic io_tlb_req_3_bits_getGpa;
  logic io_tlb_req_4_valid;
  logic [37:0] io_tlb_req_4_bits_vpn;
  logic [1:0] io_tlb_req_4_bits_s2xlate;
  logic io_tlb_req_4_bits_getGpa;
  logic io_tlb_req_5_valid;
  logic [37:0] io_tlb_req_5_bits_vpn;
  logic [1:0] io_tlb_req_5_bits_s2xlate;
  logic io_tlb_req_5_bits_getGpa;
  logic io_tlb_req_6_valid;
  logic [37:0] io_tlb_req_6_bits_vpn;
  logic [1:0] io_tlb_req_6_bits_s2xlate;
  logic io_tlb_req_6_bits_getGpa;
  logic io_tlb_req_7_valid;
  logic [37:0] io_tlb_req_7_bits_vpn;
  logic [1:0] io_tlb_req_7_bits_s2xlate;
  logic io_tlb_req_7_bits_getGpa;
  logic g_io_tlb_resp_valid, x_io_tlb_resp_valid;
  logic [1:0] g_io_tlb_resp_bits_data_s2xlate, x_io_tlb_resp_bits_data_s2xlate;
  logic [34:0] g_io_tlb_resp_bits_data_s1_entry_tag, x_io_tlb_resp_bits_data_s1_entry_tag;
  logic [15:0] g_io_tlb_resp_bits_data_s1_entry_asid, x_io_tlb_resp_bits_data_s1_entry_asid;
  logic [13:0] g_io_tlb_resp_bits_data_s1_entry_vmid, x_io_tlb_resp_bits_data_s1_entry_vmid;
  logic g_io_tlb_resp_bits_data_s1_entry_n, x_io_tlb_resp_bits_data_s1_entry_n;
  logic [1:0] g_io_tlb_resp_bits_data_s1_entry_pbmt, x_io_tlb_resp_bits_data_s1_entry_pbmt;
  logic g_io_tlb_resp_bits_data_s1_entry_perm_d, x_io_tlb_resp_bits_data_s1_entry_perm_d;
  logic g_io_tlb_resp_bits_data_s1_entry_perm_a, x_io_tlb_resp_bits_data_s1_entry_perm_a;
  logic g_io_tlb_resp_bits_data_s1_entry_perm_g, x_io_tlb_resp_bits_data_s1_entry_perm_g;
  logic g_io_tlb_resp_bits_data_s1_entry_perm_u, x_io_tlb_resp_bits_data_s1_entry_perm_u;
  logic g_io_tlb_resp_bits_data_s1_entry_perm_x, x_io_tlb_resp_bits_data_s1_entry_perm_x;
  logic g_io_tlb_resp_bits_data_s1_entry_perm_w, x_io_tlb_resp_bits_data_s1_entry_perm_w;
  logic g_io_tlb_resp_bits_data_s1_entry_perm_r, x_io_tlb_resp_bits_data_s1_entry_perm_r;
  logic [1:0] g_io_tlb_resp_bits_data_s1_entry_level, x_io_tlb_resp_bits_data_s1_entry_level;
  logic g_io_tlb_resp_bits_data_s1_entry_v, x_io_tlb_resp_bits_data_s1_entry_v;
  logic [40:0] g_io_tlb_resp_bits_data_s1_entry_ppn, x_io_tlb_resp_bits_data_s1_entry_ppn;
  logic [2:0] g_io_tlb_resp_bits_data_s1_addr_low, x_io_tlb_resp_bits_data_s1_addr_low;
  logic [2:0] g_io_tlb_resp_bits_data_s1_ppn_low_0, x_io_tlb_resp_bits_data_s1_ppn_low_0;
  logic [2:0] g_io_tlb_resp_bits_data_s1_ppn_low_1, x_io_tlb_resp_bits_data_s1_ppn_low_1;
  logic [2:0] g_io_tlb_resp_bits_data_s1_ppn_low_2, x_io_tlb_resp_bits_data_s1_ppn_low_2;
  logic [2:0] g_io_tlb_resp_bits_data_s1_ppn_low_3, x_io_tlb_resp_bits_data_s1_ppn_low_3;
  logic [2:0] g_io_tlb_resp_bits_data_s1_ppn_low_4, x_io_tlb_resp_bits_data_s1_ppn_low_4;
  logic [2:0] g_io_tlb_resp_bits_data_s1_ppn_low_5, x_io_tlb_resp_bits_data_s1_ppn_low_5;
  logic [2:0] g_io_tlb_resp_bits_data_s1_ppn_low_6, x_io_tlb_resp_bits_data_s1_ppn_low_6;
  logic [2:0] g_io_tlb_resp_bits_data_s1_ppn_low_7, x_io_tlb_resp_bits_data_s1_ppn_low_7;
  logic g_io_tlb_resp_bits_data_s1_valididx_0, x_io_tlb_resp_bits_data_s1_valididx_0;
  logic g_io_tlb_resp_bits_data_s1_valididx_1, x_io_tlb_resp_bits_data_s1_valididx_1;
  logic g_io_tlb_resp_bits_data_s1_valididx_2, x_io_tlb_resp_bits_data_s1_valididx_2;
  logic g_io_tlb_resp_bits_data_s1_valididx_3, x_io_tlb_resp_bits_data_s1_valididx_3;
  logic g_io_tlb_resp_bits_data_s1_valididx_4, x_io_tlb_resp_bits_data_s1_valididx_4;
  logic g_io_tlb_resp_bits_data_s1_valididx_5, x_io_tlb_resp_bits_data_s1_valididx_5;
  logic g_io_tlb_resp_bits_data_s1_valididx_6, x_io_tlb_resp_bits_data_s1_valididx_6;
  logic g_io_tlb_resp_bits_data_s1_valididx_7, x_io_tlb_resp_bits_data_s1_valididx_7;
  logic g_io_tlb_resp_bits_data_s1_pteidx_0, x_io_tlb_resp_bits_data_s1_pteidx_0;
  logic g_io_tlb_resp_bits_data_s1_pteidx_1, x_io_tlb_resp_bits_data_s1_pteidx_1;
  logic g_io_tlb_resp_bits_data_s1_pteidx_2, x_io_tlb_resp_bits_data_s1_pteidx_2;
  logic g_io_tlb_resp_bits_data_s1_pteidx_3, x_io_tlb_resp_bits_data_s1_pteidx_3;
  logic g_io_tlb_resp_bits_data_s1_pteidx_4, x_io_tlb_resp_bits_data_s1_pteidx_4;
  logic g_io_tlb_resp_bits_data_s1_pteidx_5, x_io_tlb_resp_bits_data_s1_pteidx_5;
  logic g_io_tlb_resp_bits_data_s1_pteidx_6, x_io_tlb_resp_bits_data_s1_pteidx_6;
  logic g_io_tlb_resp_bits_data_s1_pteidx_7, x_io_tlb_resp_bits_data_s1_pteidx_7;
  logic g_io_tlb_resp_bits_data_s1_pf, x_io_tlb_resp_bits_data_s1_pf;
  logic g_io_tlb_resp_bits_data_s1_af, x_io_tlb_resp_bits_data_s1_af;
  logic [37:0] g_io_tlb_resp_bits_data_s2_entry_tag, x_io_tlb_resp_bits_data_s2_entry_tag;
  logic [13:0] g_io_tlb_resp_bits_data_s2_entry_vmid, x_io_tlb_resp_bits_data_s2_entry_vmid;
  logic g_io_tlb_resp_bits_data_s2_entry_n, x_io_tlb_resp_bits_data_s2_entry_n;
  logic [1:0] g_io_tlb_resp_bits_data_s2_entry_pbmt, x_io_tlb_resp_bits_data_s2_entry_pbmt;
  logic [37:0] g_io_tlb_resp_bits_data_s2_entry_ppn, x_io_tlb_resp_bits_data_s2_entry_ppn;
  logic g_io_tlb_resp_bits_data_s2_entry_perm_d, x_io_tlb_resp_bits_data_s2_entry_perm_d;
  logic g_io_tlb_resp_bits_data_s2_entry_perm_a, x_io_tlb_resp_bits_data_s2_entry_perm_a;
  logic g_io_tlb_resp_bits_data_s2_entry_perm_g, x_io_tlb_resp_bits_data_s2_entry_perm_g;
  logic g_io_tlb_resp_bits_data_s2_entry_perm_u, x_io_tlb_resp_bits_data_s2_entry_perm_u;
  logic g_io_tlb_resp_bits_data_s2_entry_perm_x, x_io_tlb_resp_bits_data_s2_entry_perm_x;
  logic g_io_tlb_resp_bits_data_s2_entry_perm_w, x_io_tlb_resp_bits_data_s2_entry_perm_w;
  logic g_io_tlb_resp_bits_data_s2_entry_perm_r, x_io_tlb_resp_bits_data_s2_entry_perm_r;
  logic [1:0] g_io_tlb_resp_bits_data_s2_entry_level, x_io_tlb_resp_bits_data_s2_entry_level;
  logic g_io_tlb_resp_bits_data_s2_gpf, x_io_tlb_resp_bits_data_s2_gpf;
  logic g_io_tlb_resp_bits_data_s2_gaf, x_io_tlb_resp_bits_data_s2_gaf;
  logic g_io_tlb_resp_bits_vector_0, x_io_tlb_resp_bits_vector_0;
  logic g_io_tlb_resp_bits_vector_4, x_io_tlb_resp_bits_vector_4;
  logic g_io_tlb_resp_bits_vector_6, x_io_tlb_resp_bits_vector_6;
  logic g_io_tlb_resp_bits_getGpa_0, x_io_tlb_resp_bits_getGpa_0;
  logic g_io_tlb_resp_bits_getGpa_4, x_io_tlb_resp_bits_getGpa_4;
  logic g_io_tlb_resp_bits_getGpa_6, x_io_tlb_resp_bits_getGpa_6;
  logic io_ptw_req_0_ready;
  logic g_io_ptw_req_0_valid, x_io_ptw_req_0_valid;
  logic [37:0] g_io_ptw_req_0_bits_vpn, x_io_ptw_req_0_bits_vpn;
  logic [1:0] g_io_ptw_req_0_bits_s2xlate, x_io_ptw_req_0_bits_s2xlate;
  logic io_ptw_resp_valid;
  logic [1:0] io_ptw_resp_bits_s2xlate;
  logic [34:0] io_ptw_resp_bits_s1_entry_tag;
  logic [15:0] io_ptw_resp_bits_s1_entry_asid;
  logic [13:0] io_ptw_resp_bits_s1_entry_vmid;
  logic io_ptw_resp_bits_s1_entry_n;
  logic [1:0] io_ptw_resp_bits_s1_entry_pbmt;
  logic io_ptw_resp_bits_s1_entry_perm_d;
  logic io_ptw_resp_bits_s1_entry_perm_a;
  logic io_ptw_resp_bits_s1_entry_perm_g;
  logic io_ptw_resp_bits_s1_entry_perm_u;
  logic io_ptw_resp_bits_s1_entry_perm_x;
  logic io_ptw_resp_bits_s1_entry_perm_w;
  logic io_ptw_resp_bits_s1_entry_perm_r;
  logic [1:0] io_ptw_resp_bits_s1_entry_level;
  logic io_ptw_resp_bits_s1_entry_v;
  logic [40:0] io_ptw_resp_bits_s1_entry_ppn;
  logic [2:0] io_ptw_resp_bits_s1_addr_low;
  logic [2:0] io_ptw_resp_bits_s1_ppn_low_0;
  logic [2:0] io_ptw_resp_bits_s1_ppn_low_1;
  logic [2:0] io_ptw_resp_bits_s1_ppn_low_2;
  logic [2:0] io_ptw_resp_bits_s1_ppn_low_3;
  logic [2:0] io_ptw_resp_bits_s1_ppn_low_4;
  logic [2:0] io_ptw_resp_bits_s1_ppn_low_5;
  logic [2:0] io_ptw_resp_bits_s1_ppn_low_6;
  logic [2:0] io_ptw_resp_bits_s1_ppn_low_7;
  logic io_ptw_resp_bits_s1_valididx_0;
  logic io_ptw_resp_bits_s1_valididx_1;
  logic io_ptw_resp_bits_s1_valididx_2;
  logic io_ptw_resp_bits_s1_valididx_3;
  logic io_ptw_resp_bits_s1_valididx_4;
  logic io_ptw_resp_bits_s1_valididx_5;
  logic io_ptw_resp_bits_s1_valididx_6;
  logic io_ptw_resp_bits_s1_valididx_7;
  logic io_ptw_resp_bits_s1_pteidx_0;
  logic io_ptw_resp_bits_s1_pteidx_1;
  logic io_ptw_resp_bits_s1_pteidx_2;
  logic io_ptw_resp_bits_s1_pteidx_3;
  logic io_ptw_resp_bits_s1_pteidx_4;
  logic io_ptw_resp_bits_s1_pteidx_5;
  logic io_ptw_resp_bits_s1_pteidx_6;
  logic io_ptw_resp_bits_s1_pteidx_7;
  logic io_ptw_resp_bits_s1_pf;
  logic io_ptw_resp_bits_s1_af;
  logic [37:0] io_ptw_resp_bits_s2_entry_tag;
  logic [13:0] io_ptw_resp_bits_s2_entry_vmid;
  logic io_ptw_resp_bits_s2_entry_n;
  logic [1:0] io_ptw_resp_bits_s2_entry_pbmt;
  logic [37:0] io_ptw_resp_bits_s2_entry_ppn;
  logic io_ptw_resp_bits_s2_entry_perm_d;
  logic io_ptw_resp_bits_s2_entry_perm_a;
  logic io_ptw_resp_bits_s2_entry_perm_g;
  logic io_ptw_resp_bits_s2_entry_perm_u;
  logic io_ptw_resp_bits_s2_entry_perm_x;
  logic io_ptw_resp_bits_s2_entry_perm_w;
  logic io_ptw_resp_bits_s2_entry_perm_r;
  logic [1:0] io_ptw_resp_bits_s2_entry_level;
  logic io_ptw_resp_bits_s2_gpf;
  logic io_ptw_resp_bits_s2_gaf;
  logic [3:0] g_io_hint_req_0_id, x_io_hint_req_0_id;
  logic g_io_hint_req_0_full, x_io_hint_req_0_full;
  logic [3:0] g_io_hint_req_1_id, x_io_hint_req_1_id;
  logic g_io_hint_req_1_full, x_io_hint_req_1_full;
  logic [3:0] g_io_hint_req_2_id, x_io_hint_req_2_id;
  logic g_io_hint_req_2_full, x_io_hint_req_2_full;
  logic g_io_hint_resp_valid, x_io_hint_resp_valid;
  logic [3:0] g_io_hint_resp_bits_id, x_io_hint_resp_bits_id;
  logic g_io_hint_resp_bits_replay_all, x_io_hint_resp_bits_replay_all;
  logic g_io_rob_head_miss_in_tlb, x_io_rob_head_miss_in_tlb;
  logic io_debugTopDown_robHeadVaddr_valid;
  logic [49:0] io_debugTopDown_robHeadVaddr_bits;

`define PNF_PORTS(P) \
    .clock                                 (clk), \
    .reset                                 (reset), \
    .io_sfence_valid                       (io_sfence_valid), \
    .io_csr_satp_asid                      (io_csr_satp_asid), \
    .io_csr_satp_changed                   (io_csr_satp_changed), \
    .io_csr_vsatp_asid                     (io_csr_vsatp_asid), \
    .io_csr_vsatp_changed                  (io_csr_vsatp_changed), \
    .io_csr_hgatp_vmid                     (io_csr_hgatp_vmid), \
    .io_csr_hgatp_changed                  (io_csr_hgatp_changed), \
    .io_csr_priv_virt_changed              (io_csr_priv_virt_changed), \
    .io_tlb_req_0_valid                    (io_tlb_req_0_valid), \
    .io_tlb_req_0_bits_vpn                 (io_tlb_req_0_bits_vpn), \
    .io_tlb_req_0_bits_s2xlate             (io_tlb_req_0_bits_s2xlate), \
    .io_tlb_req_0_bits_getGpa              (io_tlb_req_0_bits_getGpa), \
    .io_tlb_req_1_valid                    (io_tlb_req_1_valid), \
    .io_tlb_req_1_bits_vpn                 (io_tlb_req_1_bits_vpn), \
    .io_tlb_req_1_bits_s2xlate             (io_tlb_req_1_bits_s2xlate), \
    .io_tlb_req_1_bits_getGpa              (io_tlb_req_1_bits_getGpa), \
    .io_tlb_req_2_valid                    (io_tlb_req_2_valid), \
    .io_tlb_req_2_bits_vpn                 (io_tlb_req_2_bits_vpn), \
    .io_tlb_req_2_bits_s2xlate             (io_tlb_req_2_bits_s2xlate), \
    .io_tlb_req_2_bits_getGpa              (io_tlb_req_2_bits_getGpa), \
    .io_tlb_req_3_valid                    (io_tlb_req_3_valid), \
    .io_tlb_req_3_bits_vpn                 (io_tlb_req_3_bits_vpn), \
    .io_tlb_req_3_bits_s2xlate             (io_tlb_req_3_bits_s2xlate), \
    .io_tlb_req_3_bits_getGpa              (io_tlb_req_3_bits_getGpa), \
    .io_tlb_req_4_valid                    (io_tlb_req_4_valid), \
    .io_tlb_req_4_bits_vpn                 (io_tlb_req_4_bits_vpn), \
    .io_tlb_req_4_bits_s2xlate             (io_tlb_req_4_bits_s2xlate), \
    .io_tlb_req_4_bits_getGpa              (io_tlb_req_4_bits_getGpa), \
    .io_tlb_req_5_valid                    (io_tlb_req_5_valid), \
    .io_tlb_req_5_bits_vpn                 (io_tlb_req_5_bits_vpn), \
    .io_tlb_req_5_bits_s2xlate             (io_tlb_req_5_bits_s2xlate), \
    .io_tlb_req_5_bits_getGpa              (io_tlb_req_5_bits_getGpa), \
    .io_tlb_req_6_valid                    (io_tlb_req_6_valid), \
    .io_tlb_req_6_bits_vpn                 (io_tlb_req_6_bits_vpn), \
    .io_tlb_req_6_bits_s2xlate             (io_tlb_req_6_bits_s2xlate), \
    .io_tlb_req_6_bits_getGpa              (io_tlb_req_6_bits_getGpa), \
    .io_tlb_req_7_valid                    (io_tlb_req_7_valid), \
    .io_tlb_req_7_bits_vpn                 (io_tlb_req_7_bits_vpn), \
    .io_tlb_req_7_bits_s2xlate             (io_tlb_req_7_bits_s2xlate), \
    .io_tlb_req_7_bits_getGpa              (io_tlb_req_7_bits_getGpa), \
    .io_tlb_resp_valid                     (P``_io_tlb_resp_valid), \
    .io_tlb_resp_bits_data_s2xlate         (P``_io_tlb_resp_bits_data_s2xlate), \
    .io_tlb_resp_bits_data_s1_entry_tag    (P``_io_tlb_resp_bits_data_s1_entry_tag), \
    .io_tlb_resp_bits_data_s1_entry_asid   (P``_io_tlb_resp_bits_data_s1_entry_asid), \
    .io_tlb_resp_bits_data_s1_entry_vmid   (P``_io_tlb_resp_bits_data_s1_entry_vmid), \
    .io_tlb_resp_bits_data_s1_entry_n      (P``_io_tlb_resp_bits_data_s1_entry_n), \
    .io_tlb_resp_bits_data_s1_entry_pbmt   (P``_io_tlb_resp_bits_data_s1_entry_pbmt), \
    .io_tlb_resp_bits_data_s1_entry_perm_d (P``_io_tlb_resp_bits_data_s1_entry_perm_d), \
    .io_tlb_resp_bits_data_s1_entry_perm_a (P``_io_tlb_resp_bits_data_s1_entry_perm_a), \
    .io_tlb_resp_bits_data_s1_entry_perm_g (P``_io_tlb_resp_bits_data_s1_entry_perm_g), \
    .io_tlb_resp_bits_data_s1_entry_perm_u (P``_io_tlb_resp_bits_data_s1_entry_perm_u), \
    .io_tlb_resp_bits_data_s1_entry_perm_x (P``_io_tlb_resp_bits_data_s1_entry_perm_x), \
    .io_tlb_resp_bits_data_s1_entry_perm_w (P``_io_tlb_resp_bits_data_s1_entry_perm_w), \
    .io_tlb_resp_bits_data_s1_entry_perm_r (P``_io_tlb_resp_bits_data_s1_entry_perm_r), \
    .io_tlb_resp_bits_data_s1_entry_level  (P``_io_tlb_resp_bits_data_s1_entry_level), \
    .io_tlb_resp_bits_data_s1_entry_v      (P``_io_tlb_resp_bits_data_s1_entry_v), \
    .io_tlb_resp_bits_data_s1_entry_ppn    (P``_io_tlb_resp_bits_data_s1_entry_ppn), \
    .io_tlb_resp_bits_data_s1_addr_low     (P``_io_tlb_resp_bits_data_s1_addr_low), \
    .io_tlb_resp_bits_data_s1_ppn_low_0    (P``_io_tlb_resp_bits_data_s1_ppn_low_0), \
    .io_tlb_resp_bits_data_s1_ppn_low_1    (P``_io_tlb_resp_bits_data_s1_ppn_low_1), \
    .io_tlb_resp_bits_data_s1_ppn_low_2    (P``_io_tlb_resp_bits_data_s1_ppn_low_2), \
    .io_tlb_resp_bits_data_s1_ppn_low_3    (P``_io_tlb_resp_bits_data_s1_ppn_low_3), \
    .io_tlb_resp_bits_data_s1_ppn_low_4    (P``_io_tlb_resp_bits_data_s1_ppn_low_4), \
    .io_tlb_resp_bits_data_s1_ppn_low_5    (P``_io_tlb_resp_bits_data_s1_ppn_low_5), \
    .io_tlb_resp_bits_data_s1_ppn_low_6    (P``_io_tlb_resp_bits_data_s1_ppn_low_6), \
    .io_tlb_resp_bits_data_s1_ppn_low_7    (P``_io_tlb_resp_bits_data_s1_ppn_low_7), \
    .io_tlb_resp_bits_data_s1_valididx_0   (P``_io_tlb_resp_bits_data_s1_valididx_0), \
    .io_tlb_resp_bits_data_s1_valididx_1   (P``_io_tlb_resp_bits_data_s1_valididx_1), \
    .io_tlb_resp_bits_data_s1_valididx_2   (P``_io_tlb_resp_bits_data_s1_valididx_2), \
    .io_tlb_resp_bits_data_s1_valididx_3   (P``_io_tlb_resp_bits_data_s1_valididx_3), \
    .io_tlb_resp_bits_data_s1_valididx_4   (P``_io_tlb_resp_bits_data_s1_valididx_4), \
    .io_tlb_resp_bits_data_s1_valididx_5   (P``_io_tlb_resp_bits_data_s1_valididx_5), \
    .io_tlb_resp_bits_data_s1_valididx_6   (P``_io_tlb_resp_bits_data_s1_valididx_6), \
    .io_tlb_resp_bits_data_s1_valididx_7   (P``_io_tlb_resp_bits_data_s1_valididx_7), \
    .io_tlb_resp_bits_data_s1_pteidx_0     (P``_io_tlb_resp_bits_data_s1_pteidx_0), \
    .io_tlb_resp_bits_data_s1_pteidx_1     (P``_io_tlb_resp_bits_data_s1_pteidx_1), \
    .io_tlb_resp_bits_data_s1_pteidx_2     (P``_io_tlb_resp_bits_data_s1_pteidx_2), \
    .io_tlb_resp_bits_data_s1_pteidx_3     (P``_io_tlb_resp_bits_data_s1_pteidx_3), \
    .io_tlb_resp_bits_data_s1_pteidx_4     (P``_io_tlb_resp_bits_data_s1_pteidx_4), \
    .io_tlb_resp_bits_data_s1_pteidx_5     (P``_io_tlb_resp_bits_data_s1_pteidx_5), \
    .io_tlb_resp_bits_data_s1_pteidx_6     (P``_io_tlb_resp_bits_data_s1_pteidx_6), \
    .io_tlb_resp_bits_data_s1_pteidx_7     (P``_io_tlb_resp_bits_data_s1_pteidx_7), \
    .io_tlb_resp_bits_data_s1_pf           (P``_io_tlb_resp_bits_data_s1_pf), \
    .io_tlb_resp_bits_data_s1_af           (P``_io_tlb_resp_bits_data_s1_af), \
    .io_tlb_resp_bits_data_s2_entry_tag    (P``_io_tlb_resp_bits_data_s2_entry_tag), \
    .io_tlb_resp_bits_data_s2_entry_vmid   (P``_io_tlb_resp_bits_data_s2_entry_vmid), \
    .io_tlb_resp_bits_data_s2_entry_n      (P``_io_tlb_resp_bits_data_s2_entry_n), \
    .io_tlb_resp_bits_data_s2_entry_pbmt   (P``_io_tlb_resp_bits_data_s2_entry_pbmt), \
    .io_tlb_resp_bits_data_s2_entry_ppn    (P``_io_tlb_resp_bits_data_s2_entry_ppn), \
    .io_tlb_resp_bits_data_s2_entry_perm_d (P``_io_tlb_resp_bits_data_s2_entry_perm_d), \
    .io_tlb_resp_bits_data_s2_entry_perm_a (P``_io_tlb_resp_bits_data_s2_entry_perm_a), \
    .io_tlb_resp_bits_data_s2_entry_perm_g (P``_io_tlb_resp_bits_data_s2_entry_perm_g), \
    .io_tlb_resp_bits_data_s2_entry_perm_u (P``_io_tlb_resp_bits_data_s2_entry_perm_u), \
    .io_tlb_resp_bits_data_s2_entry_perm_x (P``_io_tlb_resp_bits_data_s2_entry_perm_x), \
    .io_tlb_resp_bits_data_s2_entry_perm_w (P``_io_tlb_resp_bits_data_s2_entry_perm_w), \
    .io_tlb_resp_bits_data_s2_entry_perm_r (P``_io_tlb_resp_bits_data_s2_entry_perm_r), \
    .io_tlb_resp_bits_data_s2_entry_level  (P``_io_tlb_resp_bits_data_s2_entry_level), \
    .io_tlb_resp_bits_data_s2_gpf          (P``_io_tlb_resp_bits_data_s2_gpf), \
    .io_tlb_resp_bits_data_s2_gaf          (P``_io_tlb_resp_bits_data_s2_gaf), \
    .io_tlb_resp_bits_vector_0             (P``_io_tlb_resp_bits_vector_0), \
    .io_tlb_resp_bits_vector_4             (P``_io_tlb_resp_bits_vector_4), \
    .io_tlb_resp_bits_vector_6             (P``_io_tlb_resp_bits_vector_6), \
    .io_tlb_resp_bits_getGpa_0             (P``_io_tlb_resp_bits_getGpa_0), \
    .io_tlb_resp_bits_getGpa_4             (P``_io_tlb_resp_bits_getGpa_4), \
    .io_tlb_resp_bits_getGpa_6             (P``_io_tlb_resp_bits_getGpa_6), \
    .io_ptw_req_0_ready                    (io_ptw_req_0_ready), \
    .io_ptw_req_0_valid                    (P``_io_ptw_req_0_valid), \
    .io_ptw_req_0_bits_vpn                 (P``_io_ptw_req_0_bits_vpn), \
    .io_ptw_req_0_bits_s2xlate             (P``_io_ptw_req_0_bits_s2xlate), \
    .io_ptw_resp_valid                     (io_ptw_resp_valid), \
    .io_ptw_resp_bits_s2xlate              (io_ptw_resp_bits_s2xlate), \
    .io_ptw_resp_bits_s1_entry_tag         (io_ptw_resp_bits_s1_entry_tag), \
    .io_ptw_resp_bits_s1_entry_asid        (io_ptw_resp_bits_s1_entry_asid), \
    .io_ptw_resp_bits_s1_entry_vmid        (io_ptw_resp_bits_s1_entry_vmid), \
    .io_ptw_resp_bits_s1_entry_n           (io_ptw_resp_bits_s1_entry_n), \
    .io_ptw_resp_bits_s1_entry_pbmt        (io_ptw_resp_bits_s1_entry_pbmt), \
    .io_ptw_resp_bits_s1_entry_perm_d      (io_ptw_resp_bits_s1_entry_perm_d), \
    .io_ptw_resp_bits_s1_entry_perm_a      (io_ptw_resp_bits_s1_entry_perm_a), \
    .io_ptw_resp_bits_s1_entry_perm_g      (io_ptw_resp_bits_s1_entry_perm_g), \
    .io_ptw_resp_bits_s1_entry_perm_u      (io_ptw_resp_bits_s1_entry_perm_u), \
    .io_ptw_resp_bits_s1_entry_perm_x      (io_ptw_resp_bits_s1_entry_perm_x), \
    .io_ptw_resp_bits_s1_entry_perm_w      (io_ptw_resp_bits_s1_entry_perm_w), \
    .io_ptw_resp_bits_s1_entry_perm_r      (io_ptw_resp_bits_s1_entry_perm_r), \
    .io_ptw_resp_bits_s1_entry_level       (io_ptw_resp_bits_s1_entry_level), \
    .io_ptw_resp_bits_s1_entry_v           (io_ptw_resp_bits_s1_entry_v), \
    .io_ptw_resp_bits_s1_entry_ppn         (io_ptw_resp_bits_s1_entry_ppn), \
    .io_ptw_resp_bits_s1_addr_low          (io_ptw_resp_bits_s1_addr_low), \
    .io_ptw_resp_bits_s1_ppn_low_0         (io_ptw_resp_bits_s1_ppn_low_0), \
    .io_ptw_resp_bits_s1_ppn_low_1         (io_ptw_resp_bits_s1_ppn_low_1), \
    .io_ptw_resp_bits_s1_ppn_low_2         (io_ptw_resp_bits_s1_ppn_low_2), \
    .io_ptw_resp_bits_s1_ppn_low_3         (io_ptw_resp_bits_s1_ppn_low_3), \
    .io_ptw_resp_bits_s1_ppn_low_4         (io_ptw_resp_bits_s1_ppn_low_4), \
    .io_ptw_resp_bits_s1_ppn_low_5         (io_ptw_resp_bits_s1_ppn_low_5), \
    .io_ptw_resp_bits_s1_ppn_low_6         (io_ptw_resp_bits_s1_ppn_low_6), \
    .io_ptw_resp_bits_s1_ppn_low_7         (io_ptw_resp_bits_s1_ppn_low_7), \
    .io_ptw_resp_bits_s1_valididx_0        (io_ptw_resp_bits_s1_valididx_0), \
    .io_ptw_resp_bits_s1_valididx_1        (io_ptw_resp_bits_s1_valididx_1), \
    .io_ptw_resp_bits_s1_valididx_2        (io_ptw_resp_bits_s1_valididx_2), \
    .io_ptw_resp_bits_s1_valididx_3        (io_ptw_resp_bits_s1_valididx_3), \
    .io_ptw_resp_bits_s1_valididx_4        (io_ptw_resp_bits_s1_valididx_4), \
    .io_ptw_resp_bits_s1_valididx_5        (io_ptw_resp_bits_s1_valididx_5), \
    .io_ptw_resp_bits_s1_valididx_6        (io_ptw_resp_bits_s1_valididx_6), \
    .io_ptw_resp_bits_s1_valididx_7        (io_ptw_resp_bits_s1_valididx_7), \
    .io_ptw_resp_bits_s1_pteidx_0          (io_ptw_resp_bits_s1_pteidx_0), \
    .io_ptw_resp_bits_s1_pteidx_1          (io_ptw_resp_bits_s1_pteidx_1), \
    .io_ptw_resp_bits_s1_pteidx_2          (io_ptw_resp_bits_s1_pteidx_2), \
    .io_ptw_resp_bits_s1_pteidx_3          (io_ptw_resp_bits_s1_pteidx_3), \
    .io_ptw_resp_bits_s1_pteidx_4          (io_ptw_resp_bits_s1_pteidx_4), \
    .io_ptw_resp_bits_s1_pteidx_5          (io_ptw_resp_bits_s1_pteidx_5), \
    .io_ptw_resp_bits_s1_pteidx_6          (io_ptw_resp_bits_s1_pteidx_6), \
    .io_ptw_resp_bits_s1_pteidx_7          (io_ptw_resp_bits_s1_pteidx_7), \
    .io_ptw_resp_bits_s1_pf                (io_ptw_resp_bits_s1_pf), \
    .io_ptw_resp_bits_s1_af                (io_ptw_resp_bits_s1_af), \
    .io_ptw_resp_bits_s2_entry_tag         (io_ptw_resp_bits_s2_entry_tag), \
    .io_ptw_resp_bits_s2_entry_vmid        (io_ptw_resp_bits_s2_entry_vmid), \
    .io_ptw_resp_bits_s2_entry_n           (io_ptw_resp_bits_s2_entry_n), \
    .io_ptw_resp_bits_s2_entry_pbmt        (io_ptw_resp_bits_s2_entry_pbmt), \
    .io_ptw_resp_bits_s2_entry_ppn         (io_ptw_resp_bits_s2_entry_ppn), \
    .io_ptw_resp_bits_s2_entry_perm_d      (io_ptw_resp_bits_s2_entry_perm_d), \
    .io_ptw_resp_bits_s2_entry_perm_a      (io_ptw_resp_bits_s2_entry_perm_a), \
    .io_ptw_resp_bits_s2_entry_perm_g      (io_ptw_resp_bits_s2_entry_perm_g), \
    .io_ptw_resp_bits_s2_entry_perm_u      (io_ptw_resp_bits_s2_entry_perm_u), \
    .io_ptw_resp_bits_s2_entry_perm_x      (io_ptw_resp_bits_s2_entry_perm_x), \
    .io_ptw_resp_bits_s2_entry_perm_w      (io_ptw_resp_bits_s2_entry_perm_w), \
    .io_ptw_resp_bits_s2_entry_perm_r      (io_ptw_resp_bits_s2_entry_perm_r), \
    .io_ptw_resp_bits_s2_entry_level       (io_ptw_resp_bits_s2_entry_level), \
    .io_ptw_resp_bits_s2_gpf               (io_ptw_resp_bits_s2_gpf), \
    .io_ptw_resp_bits_s2_gaf               (io_ptw_resp_bits_s2_gaf), \
    .io_hint_req_0_id                      (P``_io_hint_req_0_id), \
    .io_hint_req_0_full                    (P``_io_hint_req_0_full), \
    .io_hint_req_1_id                      (P``_io_hint_req_1_id), \
    .io_hint_req_1_full                    (P``_io_hint_req_1_full), \
    .io_hint_req_2_id                      (P``_io_hint_req_2_id), \
    .io_hint_req_2_full                    (P``_io_hint_req_2_full), \
    .io_hint_resp_valid                    (P``_io_hint_resp_valid), \
    .io_hint_resp_bits_id                  (P``_io_hint_resp_bits_id), \
    .io_hint_resp_bits_replay_all          (P``_io_hint_resp_bits_replay_all), \
    .io_rob_head_miss_in_tlb               (P``_io_rob_head_miss_in_tlb), \
    .io_debugTopDown_robHeadVaddr_valid    (io_debugTopDown_robHeadVaddr_valid), \
    .io_debugTopDown_robHeadVaddr_bits     (io_debugTopDown_robHeadVaddr_bits)

  PTWNewFilter    g_dut (`PNF_PORTS(g));
  PTWNewFilter_xs x_dut (`PNF_PORTS(x));

  task automatic rand_resp_payload();
    io_ptw_resp_bits_s2xlate = 2'($urandom);
    io_ptw_resp_bits_s1_entry_tag = 35'({$urandom, $urandom});
    io_ptw_resp_bits_s1_entry_asid = 16'($urandom);
    io_ptw_resp_bits_s1_entry_vmid = 14'($urandom);
    io_ptw_resp_bits_s1_entry_n = 1'($urandom);
    io_ptw_resp_bits_s1_entry_pbmt = 2'($urandom);
    io_ptw_resp_bits_s1_entry_perm_d = 1'($urandom);
    io_ptw_resp_bits_s1_entry_perm_a = 1'($urandom);
    io_ptw_resp_bits_s1_entry_perm_g = 1'($urandom);
    io_ptw_resp_bits_s1_entry_perm_u = 1'($urandom);
    io_ptw_resp_bits_s1_entry_perm_x = 1'($urandom);
    io_ptw_resp_bits_s1_entry_perm_w = 1'($urandom);
    io_ptw_resp_bits_s1_entry_perm_r = 1'($urandom);
    io_ptw_resp_bits_s1_entry_level = 2'($urandom);
    io_ptw_resp_bits_s1_entry_v = 1'($urandom);
    io_ptw_resp_bits_s1_entry_ppn = 41'({$urandom, $urandom});
    io_ptw_resp_bits_s1_addr_low = 3'($urandom);
    io_ptw_resp_bits_s1_ppn_low_0 = 3'($urandom);
    io_ptw_resp_bits_s1_ppn_low_1 = 3'($urandom);
    io_ptw_resp_bits_s1_ppn_low_2 = 3'($urandom);
    io_ptw_resp_bits_s1_ppn_low_3 = 3'($urandom);
    io_ptw_resp_bits_s1_ppn_low_4 = 3'($urandom);
    io_ptw_resp_bits_s1_ppn_low_5 = 3'($urandom);
    io_ptw_resp_bits_s1_ppn_low_6 = 3'($urandom);
    io_ptw_resp_bits_s1_ppn_low_7 = 3'($urandom);
    io_ptw_resp_bits_s1_valididx_0 = 1'($urandom);
    io_ptw_resp_bits_s1_valididx_1 = 1'($urandom);
    io_ptw_resp_bits_s1_valididx_2 = 1'($urandom);
    io_ptw_resp_bits_s1_valididx_3 = 1'($urandom);
    io_ptw_resp_bits_s1_valididx_4 = 1'($urandom);
    io_ptw_resp_bits_s1_valididx_5 = 1'($urandom);
    io_ptw_resp_bits_s1_valididx_6 = 1'($urandom);
    io_ptw_resp_bits_s1_valididx_7 = 1'($urandom);
    io_ptw_resp_bits_s1_pteidx_0 = 1'($urandom);
    io_ptw_resp_bits_s1_pteidx_1 = 1'($urandom);
    io_ptw_resp_bits_s1_pteidx_2 = 1'($urandom);
    io_ptw_resp_bits_s1_pteidx_3 = 1'($urandom);
    io_ptw_resp_bits_s1_pteidx_4 = 1'($urandom);
    io_ptw_resp_bits_s1_pteidx_5 = 1'($urandom);
    io_ptw_resp_bits_s1_pteidx_6 = 1'($urandom);
    io_ptw_resp_bits_s1_pteidx_7 = 1'($urandom);
    io_ptw_resp_bits_s1_pf = 1'($urandom);
    io_ptw_resp_bits_s1_af = 1'($urandom);
    io_ptw_resp_bits_s2_entry_tag = 38'({$urandom, $urandom});
    io_ptw_resp_bits_s2_entry_vmid = 14'($urandom);
    io_ptw_resp_bits_s2_entry_n = 1'($urandom);
    io_ptw_resp_bits_s2_entry_pbmt = 2'($urandom);
    io_ptw_resp_bits_s2_entry_ppn = 38'({$urandom, $urandom});
    io_ptw_resp_bits_s2_entry_perm_d = 1'($urandom);
    io_ptw_resp_bits_s2_entry_perm_a = 1'($urandom);
    io_ptw_resp_bits_s2_entry_perm_g = 1'($urandom);
    io_ptw_resp_bits_s2_entry_perm_u = 1'($urandom);
    io_ptw_resp_bits_s2_entry_perm_x = 1'($urandom);
    io_ptw_resp_bits_s2_entry_perm_w = 1'($urandom);
    io_ptw_resp_bits_s2_entry_perm_r = 1'($urandom);
    io_ptw_resp_bits_s2_entry_level = 2'($urandom);
    io_ptw_resp_bits_s2_gpf = 1'($urandom);
    io_ptw_resp_bits_s2_gaf = 1'($urandom);
  endtask

  // ---- 激励 ----
  localparam int POOL = 12;
  logic [37:0] pool [POOL];
  typedef struct { logic [37:0] vpn; logic [1:0] s2x; int delay; } job_t;
  job_t jobs[$];

  task automatic set_resp(input logic [37:0] vpn, input logic [1:0] s2x);
    logic [7:0] vidx;
    rand_resp_payload();
    io_ptw_resp_bits_s2xlate          = s2x;
    io_ptw_resp_bits_s1_entry_tag     = vpn[37:3];
    io_ptw_resp_bits_s1_entry_asid    = ($urandom_range(0, 9) == 0) ? 16'($urandom) : 16'h5;
    io_ptw_resp_bits_s1_entry_vmid    = ($urandom_range(0, 9) == 0) ? 14'($urandom) : 14'h3;
    io_ptw_resp_bits_s1_entry_n       = ($urandom_range(0, 9) == 0);
    io_ptw_resp_bits_s1_entry_perm_g  = ($urandom_range(0, 4) == 0);
    io_ptw_resp_bits_s1_entry_level   = ($urandom_range(0, 3) == 0) ? 2'($urandom_range(1, 3)) : 2'd0;
    io_ptw_resp_bits_s1_addr_low      = vpn[2:0];
    vidx = 8'($urandom) | (($urandom_range(0, 7) != 0) ? (8'd1 << vpn[2:0]) : 8'd0);
    io_ptw_resp_bits_s1_valididx_0 = vidx[0];
    io_ptw_resp_bits_s1_valididx_1 = vidx[1];
    io_ptw_resp_bits_s1_valididx_2 = vidx[2];
    io_ptw_resp_bits_s1_valididx_3 = vidx[3];
    io_ptw_resp_bits_s1_valididx_4 = vidx[4];
    io_ptw_resp_bits_s1_valididx_5 = vidx[5];
    io_ptw_resp_bits_s1_valididx_6 = vidx[6];
    io_ptw_resp_bits_s1_valididx_7 = vidx[7];
    io_ptw_resp_bits_s2_entry_tag     = vpn;
    io_ptw_resp_bits_s2_entry_vmid    = ($urandom_range(0, 9) == 0) ? 14'($urandom) : 14'h3;
    io_ptw_resp_bits_s2_entry_n       = ($urandom_range(0, 9) == 0);
    io_ptw_resp_bits_s2_entry_level   = ($urandom_range(0, 3) == 0) ? 2'($urandom_range(1, 3)) : 2'd0;
  endtask

  function automatic logic [37:0] pick_vpn(input logic [37:0] buddy);
    return ($urandom_range(0, 3) == 0) ? buddy : pool[$urandom_range(0, POOL - 1)];
  endfunction

  task automatic drive_inputs();
    logic [7:0] v;
    logic [7:0][37:0] vpn;
    logic [7:0][1:0] s2x;
    logic [7:0] gpa;
    io_csr_satp_asid  = 16'h5;
    io_csr_vsatp_asid = 16'h5;
    io_csr_hgatp_vmid = 16'h3;
    io_sfence_valid          = ($urandom_range(0, 999) < 3);
    io_csr_satp_changed      = ($urandom_range(0, 999) < 2);
    io_csr_vsatp_changed     = ($urandom_range(0, 999) < 2);
    io_csr_hgatp_changed     = ($urandom_range(0, 999) < 2);
    io_csr_priv_virt_changed = ($urandom_range(0, 999) < 2);
    for (int i = 0; i < 8; i++) begin
      v[i]   = ($urandom_range(0, 9) < ((i < 4) ? 4 : 5));
      vpn[i] = pick_vpn((i == 0) ? pool[0] : vpn[i - 1]);
      s2x[i] = ($urandom_range(0, 3) == 0) ? 2'($urandom) : 2'd0;
      gpa[i] = ($urandom_range(0, 4) == 0);
    end
    // 跨组同页：store / prefetch 口有时抄 load 口的页
    if ($urandom_range(0, 4) == 0) begin vpn[4] = vpn[0]; s2x[4] = s2x[0]; end
    if ($urandom_range(0, 4) == 0) begin vpn[6] = vpn[1]; s2x[6] = s2x[1]; end
    io_tlb_req_0_valid = v[0];
    io_tlb_req_0_bits_vpn = vpn[0];
    io_tlb_req_0_bits_s2xlate = s2x[0];
    io_tlb_req_0_bits_getGpa = gpa[0];
    io_tlb_req_1_valid = v[1];
    io_tlb_req_1_bits_vpn = vpn[1];
    io_tlb_req_1_bits_s2xlate = s2x[1];
    io_tlb_req_1_bits_getGpa = gpa[1];
    io_tlb_req_2_valid = v[2];
    io_tlb_req_2_bits_vpn = vpn[2];
    io_tlb_req_2_bits_s2xlate = s2x[2];
    io_tlb_req_2_bits_getGpa = gpa[2];
    io_tlb_req_3_valid = v[3];
    io_tlb_req_3_bits_vpn = vpn[3];
    io_tlb_req_3_bits_s2xlate = s2x[3];
    io_tlb_req_3_bits_getGpa = gpa[3];
    io_tlb_req_4_valid = v[4];
    io_tlb_req_4_bits_vpn = vpn[4];
    io_tlb_req_4_bits_s2xlate = s2x[4];
    io_tlb_req_4_bits_getGpa = gpa[4];
    io_tlb_req_5_valid = v[5];
    io_tlb_req_5_bits_vpn = vpn[5];
    io_tlb_req_5_bits_s2xlate = s2x[5];
    io_tlb_req_5_bits_getGpa = gpa[5];
    io_tlb_req_6_valid = v[6];
    io_tlb_req_6_bits_vpn = vpn[6];
    io_tlb_req_6_bits_s2xlate = s2x[6];
    io_tlb_req_6_bits_getGpa = gpa[6];
    io_tlb_req_7_valid = v[7];
    io_tlb_req_7_bits_vpn = vpn[7];
    io_tlb_req_7_bits_s2xlate = s2x[7];
    io_tlb_req_7_bits_getGpa = gpa[7];
    io_ptw_req_0_ready = ($urandom_range(0, 9) < 6);
    io_debugTopDown_robHeadVaddr_valid = $urandom_range(0, 1);
    io_debugTopDown_robHeadVaddr_bits  = {pool[$urandom_range(0, POOL - 1)], 12'($urandom)};
    io_ptw_resp_valid = 1'b0;
    set_resp(pool[$urandom_range(0, POOL - 1)], 2'($urandom));
    if (jobs.size() > 0 && jobs[0].delay <= 0) begin
      job_t j = jobs.pop_front();
      set_resp(j.vpn, ($urandom_range(0, 19) == 0) ? 2'($urandom) : j.s2x);
      io_ptw_resp_valid = 1'b1;
    end else if ($urandom_range(0, 29) == 0) begin
      io_ptw_resp_valid = 1'b1;
    end
    foreach (jobs[k]) jobs[k].delay--;
  endtask

  task automatic cmp1(input string name, input logic [63:0] g, input logic [63:0] x);
    checks++;
    if (g !== x) begin
      errors++;
      if (errors <= 20) $display("[%0t] MISMATCH %s golden=%h rewrite=%h", $time, name, g, x);
    end
  endtask

  task automatic compare_outputs();
    cmp1("io_tlb_resp_valid",                     g_io_tlb_resp_valid,                     x_io_tlb_resp_valid);
    cmp1("io_tlb_resp_bits_data_s2xlate",         g_io_tlb_resp_bits_data_s2xlate,         x_io_tlb_resp_bits_data_s2xlate);
    cmp1("io_tlb_resp_bits_data_s1_entry_tag",    g_io_tlb_resp_bits_data_s1_entry_tag,    x_io_tlb_resp_bits_data_s1_entry_tag);
    cmp1("io_tlb_resp_bits_data_s1_entry_asid",   g_io_tlb_resp_bits_data_s1_entry_asid,   x_io_tlb_resp_bits_data_s1_entry_asid);
    cmp1("io_tlb_resp_bits_data_s1_entry_vmid",   g_io_tlb_resp_bits_data_s1_entry_vmid,   x_io_tlb_resp_bits_data_s1_entry_vmid);
    cmp1("io_tlb_resp_bits_data_s1_entry_n",      g_io_tlb_resp_bits_data_s1_entry_n,      x_io_tlb_resp_bits_data_s1_entry_n);
    cmp1("io_tlb_resp_bits_data_s1_entry_pbmt",   g_io_tlb_resp_bits_data_s1_entry_pbmt,   x_io_tlb_resp_bits_data_s1_entry_pbmt);
    cmp1("io_tlb_resp_bits_data_s1_entry_perm_d", g_io_tlb_resp_bits_data_s1_entry_perm_d, x_io_tlb_resp_bits_data_s1_entry_perm_d);
    cmp1("io_tlb_resp_bits_data_s1_entry_perm_a", g_io_tlb_resp_bits_data_s1_entry_perm_a, x_io_tlb_resp_bits_data_s1_entry_perm_a);
    cmp1("io_tlb_resp_bits_data_s1_entry_perm_g", g_io_tlb_resp_bits_data_s1_entry_perm_g, x_io_tlb_resp_bits_data_s1_entry_perm_g);
    cmp1("io_tlb_resp_bits_data_s1_entry_perm_u", g_io_tlb_resp_bits_data_s1_entry_perm_u, x_io_tlb_resp_bits_data_s1_entry_perm_u);
    cmp1("io_tlb_resp_bits_data_s1_entry_perm_x", g_io_tlb_resp_bits_data_s1_entry_perm_x, x_io_tlb_resp_bits_data_s1_entry_perm_x);
    cmp1("io_tlb_resp_bits_data_s1_entry_perm_w", g_io_tlb_resp_bits_data_s1_entry_perm_w, x_io_tlb_resp_bits_data_s1_entry_perm_w);
    cmp1("io_tlb_resp_bits_data_s1_entry_perm_r", g_io_tlb_resp_bits_data_s1_entry_perm_r, x_io_tlb_resp_bits_data_s1_entry_perm_r);
    cmp1("io_tlb_resp_bits_data_s1_entry_level",  g_io_tlb_resp_bits_data_s1_entry_level,  x_io_tlb_resp_bits_data_s1_entry_level);
    cmp1("io_tlb_resp_bits_data_s1_entry_v",      g_io_tlb_resp_bits_data_s1_entry_v,      x_io_tlb_resp_bits_data_s1_entry_v);
    cmp1("io_tlb_resp_bits_data_s1_entry_ppn",    g_io_tlb_resp_bits_data_s1_entry_ppn,    x_io_tlb_resp_bits_data_s1_entry_ppn);
    cmp1("io_tlb_resp_bits_data_s1_addr_low",     g_io_tlb_resp_bits_data_s1_addr_low,     x_io_tlb_resp_bits_data_s1_addr_low);
    cmp1("io_tlb_resp_bits_data_s1_ppn_low_0",    g_io_tlb_resp_bits_data_s1_ppn_low_0,    x_io_tlb_resp_bits_data_s1_ppn_low_0);
    cmp1("io_tlb_resp_bits_data_s1_ppn_low_1",    g_io_tlb_resp_bits_data_s1_ppn_low_1,    x_io_tlb_resp_bits_data_s1_ppn_low_1);
    cmp1("io_tlb_resp_bits_data_s1_ppn_low_2",    g_io_tlb_resp_bits_data_s1_ppn_low_2,    x_io_tlb_resp_bits_data_s1_ppn_low_2);
    cmp1("io_tlb_resp_bits_data_s1_ppn_low_3",    g_io_tlb_resp_bits_data_s1_ppn_low_3,    x_io_tlb_resp_bits_data_s1_ppn_low_3);
    cmp1("io_tlb_resp_bits_data_s1_ppn_low_4",    g_io_tlb_resp_bits_data_s1_ppn_low_4,    x_io_tlb_resp_bits_data_s1_ppn_low_4);
    cmp1("io_tlb_resp_bits_data_s1_ppn_low_5",    g_io_tlb_resp_bits_data_s1_ppn_low_5,    x_io_tlb_resp_bits_data_s1_ppn_low_5);
    cmp1("io_tlb_resp_bits_data_s1_ppn_low_6",    g_io_tlb_resp_bits_data_s1_ppn_low_6,    x_io_tlb_resp_bits_data_s1_ppn_low_6);
    cmp1("io_tlb_resp_bits_data_s1_ppn_low_7",    g_io_tlb_resp_bits_data_s1_ppn_low_7,    x_io_tlb_resp_bits_data_s1_ppn_low_7);
    cmp1("io_tlb_resp_bits_data_s1_valididx_0",   g_io_tlb_resp_bits_data_s1_valididx_0,   x_io_tlb_resp_bits_data_s1_valididx_0);
    cmp1("io_tlb_resp_bits_data_s1_valididx_1",   g_io_tlb_resp_bits_data_s1_valididx_1,   x_io_tlb_resp_bits_data_s1_valididx_1);
    cmp1("io_tlb_resp_bits_data_s1_valididx_2",   g_io_tlb_resp_bits_data_s1_valididx_2,   x_io_tlb_resp_bits_data_s1_valididx_2);
    cmp1("io_tlb_resp_bits_data_s1_valididx_3",   g_io_tlb_resp_bits_data_s1_valididx_3,   x_io_tlb_resp_bits_data_s1_valididx_3);
    cmp1("io_tlb_resp_bits_data_s1_valididx_4",   g_io_tlb_resp_bits_data_s1_valididx_4,   x_io_tlb_resp_bits_data_s1_valididx_4);
    cmp1("io_tlb_resp_bits_data_s1_valididx_5",   g_io_tlb_resp_bits_data_s1_valididx_5,   x_io_tlb_resp_bits_data_s1_valididx_5);
    cmp1("io_tlb_resp_bits_data_s1_valididx_6",   g_io_tlb_resp_bits_data_s1_valididx_6,   x_io_tlb_resp_bits_data_s1_valididx_6);
    cmp1("io_tlb_resp_bits_data_s1_valididx_7",   g_io_tlb_resp_bits_data_s1_valididx_7,   x_io_tlb_resp_bits_data_s1_valididx_7);
    cmp1("io_tlb_resp_bits_data_s1_pteidx_0",     g_io_tlb_resp_bits_data_s1_pteidx_0,     x_io_tlb_resp_bits_data_s1_pteidx_0);
    cmp1("io_tlb_resp_bits_data_s1_pteidx_1",     g_io_tlb_resp_bits_data_s1_pteidx_1,     x_io_tlb_resp_bits_data_s1_pteidx_1);
    cmp1("io_tlb_resp_bits_data_s1_pteidx_2",     g_io_tlb_resp_bits_data_s1_pteidx_2,     x_io_tlb_resp_bits_data_s1_pteidx_2);
    cmp1("io_tlb_resp_bits_data_s1_pteidx_3",     g_io_tlb_resp_bits_data_s1_pteidx_3,     x_io_tlb_resp_bits_data_s1_pteidx_3);
    cmp1("io_tlb_resp_bits_data_s1_pteidx_4",     g_io_tlb_resp_bits_data_s1_pteidx_4,     x_io_tlb_resp_bits_data_s1_pteidx_4);
    cmp1("io_tlb_resp_bits_data_s1_pteidx_5",     g_io_tlb_resp_bits_data_s1_pteidx_5,     x_io_tlb_resp_bits_data_s1_pteidx_5);
    cmp1("io_tlb_resp_bits_data_s1_pteidx_6",     g_io_tlb_resp_bits_data_s1_pteidx_6,     x_io_tlb_resp_bits_data_s1_pteidx_6);
    cmp1("io_tlb_resp_bits_data_s1_pteidx_7",     g_io_tlb_resp_bits_data_s1_pteidx_7,     x_io_tlb_resp_bits_data_s1_pteidx_7);
    cmp1("io_tlb_resp_bits_data_s1_pf",           g_io_tlb_resp_bits_data_s1_pf,           x_io_tlb_resp_bits_data_s1_pf);
    cmp1("io_tlb_resp_bits_data_s1_af",           g_io_tlb_resp_bits_data_s1_af,           x_io_tlb_resp_bits_data_s1_af);
    cmp1("io_tlb_resp_bits_data_s2_entry_tag",    g_io_tlb_resp_bits_data_s2_entry_tag,    x_io_tlb_resp_bits_data_s2_entry_tag);
    cmp1("io_tlb_resp_bits_data_s2_entry_vmid",   g_io_tlb_resp_bits_data_s2_entry_vmid,   x_io_tlb_resp_bits_data_s2_entry_vmid);
    cmp1("io_tlb_resp_bits_data_s2_entry_n",      g_io_tlb_resp_bits_data_s2_entry_n,      x_io_tlb_resp_bits_data_s2_entry_n);
    cmp1("io_tlb_resp_bits_data_s2_entry_pbmt",   g_io_tlb_resp_bits_data_s2_entry_pbmt,   x_io_tlb_resp_bits_data_s2_entry_pbmt);
    cmp1("io_tlb_resp_bits_data_s2_entry_ppn",    g_io_tlb_resp_bits_data_s2_entry_ppn,    x_io_tlb_resp_bits_data_s2_entry_ppn);
    cmp1("io_tlb_resp_bits_data_s2_entry_perm_d", g_io_tlb_resp_bits_data_s2_entry_perm_d, x_io_tlb_resp_bits_data_s2_entry_perm_d);
    cmp1("io_tlb_resp_bits_data_s2_entry_perm_a", g_io_tlb_resp_bits_data_s2_entry_perm_a, x_io_tlb_resp_bits_data_s2_entry_perm_a);
    cmp1("io_tlb_resp_bits_data_s2_entry_perm_g", g_io_tlb_resp_bits_data_s2_entry_perm_g, x_io_tlb_resp_bits_data_s2_entry_perm_g);
    cmp1("io_tlb_resp_bits_data_s2_entry_perm_u", g_io_tlb_resp_bits_data_s2_entry_perm_u, x_io_tlb_resp_bits_data_s2_entry_perm_u);
    cmp1("io_tlb_resp_bits_data_s2_entry_perm_x", g_io_tlb_resp_bits_data_s2_entry_perm_x, x_io_tlb_resp_bits_data_s2_entry_perm_x);
    cmp1("io_tlb_resp_bits_data_s2_entry_perm_w", g_io_tlb_resp_bits_data_s2_entry_perm_w, x_io_tlb_resp_bits_data_s2_entry_perm_w);
    cmp1("io_tlb_resp_bits_data_s2_entry_perm_r", g_io_tlb_resp_bits_data_s2_entry_perm_r, x_io_tlb_resp_bits_data_s2_entry_perm_r);
    cmp1("io_tlb_resp_bits_data_s2_entry_level",  g_io_tlb_resp_bits_data_s2_entry_level,  x_io_tlb_resp_bits_data_s2_entry_level);
    cmp1("io_tlb_resp_bits_data_s2_gpf",          g_io_tlb_resp_bits_data_s2_gpf,          x_io_tlb_resp_bits_data_s2_gpf);
    cmp1("io_tlb_resp_bits_data_s2_gaf",          g_io_tlb_resp_bits_data_s2_gaf,          x_io_tlb_resp_bits_data_s2_gaf);
    cmp1("io_tlb_resp_bits_vector_0",             g_io_tlb_resp_bits_vector_0,             x_io_tlb_resp_bits_vector_0);
    cmp1("io_tlb_resp_bits_vector_4",             g_io_tlb_resp_bits_vector_4,             x_io_tlb_resp_bits_vector_4);
    cmp1("io_tlb_resp_bits_vector_6",             g_io_tlb_resp_bits_vector_6,             x_io_tlb_resp_bits_vector_6);
    cmp1("io_tlb_resp_bits_getGpa_0",             g_io_tlb_resp_bits_getGpa_0,             x_io_tlb_resp_bits_getGpa_0);
    cmp1("io_tlb_resp_bits_getGpa_4",             g_io_tlb_resp_bits_getGpa_4,             x_io_tlb_resp_bits_getGpa_4);
    cmp1("io_tlb_resp_bits_getGpa_6",             g_io_tlb_resp_bits_getGpa_6,             x_io_tlb_resp_bits_getGpa_6);
    cmp1("io_ptw_req_0_valid",                    g_io_ptw_req_0_valid,                    x_io_ptw_req_0_valid);
    cmp1("io_ptw_req_0_bits_vpn",                 g_io_ptw_req_0_bits_vpn,                 x_io_ptw_req_0_bits_vpn);
    cmp1("io_ptw_req_0_bits_s2xlate",             g_io_ptw_req_0_bits_s2xlate,             x_io_ptw_req_0_bits_s2xlate);
    cmp1("io_hint_req_0_id",                      g_io_hint_req_0_id,                      x_io_hint_req_0_id);
    cmp1("io_hint_req_0_full",                    g_io_hint_req_0_full,                    x_io_hint_req_0_full);
    cmp1("io_hint_req_1_id",                      g_io_hint_req_1_id,                      x_io_hint_req_1_id);
    cmp1("io_hint_req_1_full",                    g_io_hint_req_1_full,                    x_io_hint_req_1_full);
    cmp1("io_hint_req_2_id",                      g_io_hint_req_2_id,                      x_io_hint_req_2_id);
    cmp1("io_hint_req_2_full",                    g_io_hint_req_2_full,                    x_io_hint_req_2_full);
    cmp1("io_hint_resp_valid",                    g_io_hint_resp_valid,                    x_io_hint_resp_valid);
    cmp1("io_hint_resp_bits_id",                  g_io_hint_resp_bits_id,                  x_io_hint_resp_bits_id);
    cmp1("io_hint_resp_bits_replay_all",          g_io_hint_resp_bits_replay_all,          x_io_hint_resp_bits_replay_all);
    cmp1("io_rob_head_miss_in_tlb",               g_io_rob_head_miss_in_tlb,               x_io_rob_head_miss_in_tlb);
  endtask

  // ---- 覆盖事件 ----
  longint n_enq[3], n_issue[3], n_refill[3], n_gpa[3];
  longint n_contend, n_multi_refill, n_flush, n_replay, n_robhead;
  task automatic collect_cov();
    for (int f = 0; f < 3; f++) begin
      if (x_dut.u_core.filt_req_valid[f] & x_dut.u_core.filt_req_ready[f]) n_issue[f]++;
      if (x_dut.u_core.filt_refill[f]) n_refill[f]++;
      if (x_dut.u_core.filt_get_gpa[f]) n_gpa[f]++;
    end
    if (|x_dut.u_core.load_filter.u_core.enqvalid)     n_enq[0]++;
    if (|x_dut.u_core.store_filter.u_core.enqvalid)    n_enq[1]++;
    if (|x_dut.u_core.prefetch_filter.u_core.enqvalid) n_enq[2]++;
    if ($countones(x_dut.u_core.filt_req_valid) > 1) n_contend++;
    if ($countones(x_dut.u_core.filt_refill) > 1) n_multi_refill++;
    if (x_dut.u_core.flush && ((|x_dut.u_core.load_filter.u_core.v) || (|x_dut.u_core.store_filter.u_core.v)
                               || (|x_dut.u_core.prefetch_filter.u_core.v))) n_flush++;
    if (g_io_hint_resp_valid && g_io_hint_resp_bits_replay_all) n_replay++;
    if (g_io_rob_head_miss_in_tlb) n_robhead++;
  endtask

  initial begin
    logic [15:0] ever_ld;
    logic [7:0]  ever_st, ever_pf;
    bit seen_resp, seen_hint, cmp_on;
    int warm_cnt;
    bit cov_ok;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int i = 0; i < POOL; i++) pool[i] = {6'($urandom), 32'($urandom)};
    pool[1] = {pool[0][37:9], 9'h0a7};     // 与 pool[0] 同一 2MB 区域
    pool[2] = {pool[0][37:9], 9'h1c2};
    pool[3] = {pool[0][37:3], 3'd6};       // 与 pool[0] 同一 sector
    ever_ld = '0; ever_st = '0; ever_pf = '0;
    seen_resp = 0; seen_hint = 0; cmp_on = 0; warm_cnt = 0;
    reset = 1;
    drive_inputs();
    repeat (10) @(negedge clk);
    reset = 0;
    for (longint c = 0; c < NCYCLES; c++) begin
      if (c > 1000 && $urandom_range(0, 39999) == 0) begin
        reset = 1;
        repeat (3) begin drive_inputs(); @(negedge clk); end
        reset = 0;
        jobs.delete();
      end
      drive_inputs();
      #1;
      ever_ld |= {g_dut.load_filter_load_entry.v_15, g_dut.load_filter_load_entry.v_14, g_dut.load_filter_load_entry.v_13, g_dut.load_filter_load_entry.v_12, g_dut.load_filter_load_entry.v_11, g_dut.load_filter_load_entry.v_10, g_dut.load_filter_load_entry.v_9, g_dut.load_filter_load_entry.v_8, g_dut.load_filter_load_entry.v_7, g_dut.load_filter_load_entry.v_6, g_dut.load_filter_load_entry.v_5, g_dut.load_filter_load_entry.v_4, g_dut.load_filter_load_entry.v_3, g_dut.load_filter_load_entry.v_2, g_dut.load_filter_load_entry.v_1, g_dut.load_filter_load_entry.v_0};
      ever_st |= {g_dut.store_filter_store_entry.v_7, g_dut.store_filter_store_entry.v_6, g_dut.store_filter_store_entry.v_5, g_dut.store_filter_store_entry.v_4, g_dut.store_filter_store_entry.v_3, g_dut.store_filter_store_entry.v_2, g_dut.store_filter_store_entry.v_1, g_dut.store_filter_store_entry.v_0};
      ever_pf |= {g_dut.prefetch_filter_prefetch_entry.v_7, g_dut.prefetch_filter_prefetch_entry.v_6, g_dut.prefetch_filter_prefetch_entry.v_5, g_dut.prefetch_filter_prefetch_entry.v_4, g_dut.prefetch_filter_prefetch_entry.v_3, g_dut.prefetch_filter_prefetch_entry.v_2, g_dut.prefetch_filter_prefetch_entry.v_1, g_dut.prefetch_filter_prefetch_entry.v_0};
      if (io_ptw_resp_valid) seen_resp = 1;
      if (g_io_hint_resp_valid) seen_hint = 1;
      if ((&ever_ld) && (&ever_st) && (&ever_pf) && seen_resp && seen_hint && !cmp_on) begin
        warm_cnt++;
        if (warm_cnt > 4) cmp_on = 1;
      end
      if (cmp_on) begin compare_outputs(); collect_cov(); end
      if (g_io_ptw_req_0_valid && io_ptw_req_0_ready)
        jobs.push_back('{g_io_ptw_req_0_bits_vpn, g_io_ptw_req_0_bits_s2xlate, $urandom_range(1, 6)});
      while (jobs.size() > 16) void'(jobs.pop_front());
      @(negedge clk);
    end
    $display("=== COVERAGE (PTWNewFilter) === checks=%0d enq=%0d/%0d/%0d issue=%0d/%0d/%0d refill=%0d/%0d/%0d getGpa=%0d/%0d/%0d contend=%0d multi_refill=%0d flush_nonempty=%0d replay_all=%0d robhead=%0d",
             checks, n_enq[0], n_enq[1], n_enq[2], n_issue[0], n_issue[1], n_issue[2],
             n_refill[0], n_refill[1], n_refill[2], n_gpa[0], n_gpa[1], n_gpa[2],
             n_contend, n_multi_refill, n_flush, n_replay, n_robhead);
    cov_ok = (n_contend != 0) && (n_multi_refill != 0) && (n_flush != 0) && (n_replay != 0) && (n_robhead != 0);
    for (int f = 0; f < 3; f++)
      if (n_enq[f] == 0 || n_issue[f] == 0 || n_refill[f] == 0 || n_gpa[f] == 0) cov_ok = 0;
    if (!cov_ok) begin
      $display("COVERAGE INSUFFICIENT");
      errors++;
    end
    if (errors == 0) $display("TEST PASSED (checks=%0d errors=0)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
