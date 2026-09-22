// tb.sv —— HPTW 的双例化逐拍差分 UT（verif/ut/HPTW）。
//
// 双例化 golden HPTW 与派生的 HPTW_xs，同拍同激励，逐拍比全部 33 个输出
// （输出表由 scripts/gen_mmu5.py 从 golden 端口表逐根量出，不手抄）。
//
// 【激励设计——HPTW 是一台单请求状态机，激励要让它走完每一条路径】
//   · 请求：普通走表 / bitmap 跳转 各半；l3Hit/l2Hit/l1Hit 随机（含全 0 = 从根级走）；
//     gvpn 从 4 项池子里取（保证同一 vpn 多次走到）。
//   · 访存响应 io_mem_resp_valid 随时随机拉高（HPTW 只用 w_mem_resp 门控，不校验 id）；
//     mem_resp_bits 三分之一造干净的 next 型 PTE（r/w/x=0,v=1,其余全清）、三分之一造干净
//     叶子（r=1,v=1,u=1,a=1，ppn 低位按 level 对齐）、三分之一全随机——全随机时 gpf 几乎
//     必中（reserved/pbmt/u/a 任一坏就是 gpf），走表两级就结束，"往下走"路径覆盖不到。
//   · PMP 响应 ld/mmio 各 5%，让 accessFault 路径与"af 期间 flush"都出现。
//   · bitmap：mbmc.BME/CMODE 每 256 拍换一次，使能占一半；resp.valid 随机、cf 随机。
//   · hgatp.mode 每 512 拍换：Sv48 : Sv39 : 其它 = 6 : 3 : 1。
//   · flush 五根各 1/400 拍。
//
// 【判别力自证】覆盖计数下限（见文末断言）：普通走表 fire / 跳转 fire / mem req fire /
//   resp fire / gpf 响应 / gaf 响应 / bitmap req fire / bitmap resp fire / 走到 level 0
//   都必须 > 0，任何一项为 0 则 tb 自判 FAIL。
`timescale 1ns/1ps
module tb;
  int errors = 0;
  int checks = 0;
  int ncycles;
  // 覆盖计数
  int cov_walk_fire = 0, cov_jmp_fire = 0, cov_mem_req = 0, cov_resp = 0;
  int cov_gpf = 0, cov_gaf = 0, cov_bm_req = 0, cov_bm_resp = 0, cov_level0 = 0, cov_sv39 = 0;

  // BEGIN GENERATED(harness) —— 由 gen_mmu5.py 生成：信号声明 / 双例化 / 输出逐拍比对
  logic clock, reset;
  logic io_sfence_valid;
  logic io_csr_satp_changed;
  logic io_csr_vsatp_changed;
  logic [3:0] io_csr_hgatp_mode;
  logic [15:0] io_csr_hgatp_vmid;
  logic [43:0] io_csr_hgatp_ppn;
  logic io_csr_hgatp_changed;
  logic io_csr_mbmc_BME;
  logic io_csr_mbmc_CMODE;
  logic io_csr_priv_virt_changed;
  logic io_csr_mPBMTE;
  logic io_req_valid;
  logic [1:0] io_req_bits_source;
  logic [2:0] io_req_bits_id;
  logic [37:0] io_req_bits_gvpn;
  logic [35:0] io_req_bits_ppn;
  logic io_req_bits_l3Hit;
  logic io_req_bits_l2Hit;
  logic io_req_bits_l1Hit;
  logic io_req_bits_bypassed;
  logic io_req_bits_bitmapCheck_jmp_bitmap_check;
  logic [63:0] io_req_bits_bitmapCheck_pte;
  logic [63:0] io_req_bits_bitmapCheck_ptes_0;
  logic [63:0] io_req_bits_bitmapCheck_ptes_1;
  logic [63:0] io_req_bits_bitmapCheck_ptes_2;
  logic [63:0] io_req_bits_bitmapCheck_ptes_3;
  logic [63:0] io_req_bits_bitmapCheck_ptes_4;
  logic [63:0] io_req_bits_bitmapCheck_ptes_5;
  logic [63:0] io_req_bits_bitmapCheck_ptes_6;
  logic [63:0] io_req_bits_bitmapCheck_ptes_7;
  logic [3:0] io_req_bits_bitmapCheck_hitway;
  logic io_req_bits_bitmapCheck_fromSP;
  logic [1:0] io_req_bits_bitmapCheck_SPlevel;
  logic io_resp_ready;
  logic io_mem_req_ready;
  logic io_mem_resp_valid;
  logic [63:0] io_mem_resp_bits;
  logic io_mem_mask;
  logic io_pmp_resp_ld;
  logic io_pmp_resp_mmio;
  logic io_bitmap_req_ready;
  logic io_bitmap_resp_valid;
  logic io_bitmap_resp_bits_cf;
  logic [3:0] io_l0_way_info;
  logic g_io_req_ready, i_io_req_ready;
  logic g_io_resp_valid, i_io_resp_valid;
  logic [37:0] g_io_resp_bits_resp_entry_tag, i_io_resp_bits_resp_entry_tag;
  logic [13:0] g_io_resp_bits_resp_entry_vmid, i_io_resp_bits_resp_entry_vmid;
  logic g_io_resp_bits_resp_entry_n, i_io_resp_bits_resp_entry_n;
  logic [1:0] g_io_resp_bits_resp_entry_pbmt, i_io_resp_bits_resp_entry_pbmt;
  logic [37:0] g_io_resp_bits_resp_entry_ppn, i_io_resp_bits_resp_entry_ppn;
  logic g_io_resp_bits_resp_entry_perm_d, i_io_resp_bits_resp_entry_perm_d;
  logic g_io_resp_bits_resp_entry_perm_a, i_io_resp_bits_resp_entry_perm_a;
  logic g_io_resp_bits_resp_entry_perm_g, i_io_resp_bits_resp_entry_perm_g;
  logic g_io_resp_bits_resp_entry_perm_u, i_io_resp_bits_resp_entry_perm_u;
  logic g_io_resp_bits_resp_entry_perm_x, i_io_resp_bits_resp_entry_perm_x;
  logic g_io_resp_bits_resp_entry_perm_w, i_io_resp_bits_resp_entry_perm_w;
  logic g_io_resp_bits_resp_entry_perm_r, i_io_resp_bits_resp_entry_perm_r;
  logic [1:0] g_io_resp_bits_resp_entry_level, i_io_resp_bits_resp_entry_level;
  logic g_io_resp_bits_resp_gpf, i_io_resp_bits_resp_gpf;
  logic g_io_resp_bits_resp_gaf, i_io_resp_bits_resp_gaf;
  logic [3:0] g_io_resp_bits_id, i_io_resp_bits_id;
  logic g_io_mem_req_valid, i_io_mem_req_valid;
  logic [47:0] g_io_mem_req_bits_addr, i_io_mem_req_bits_addr;
  logic g_io_mem_req_bits_hptw_bypassed, i_io_mem_req_bits_hptw_bypassed;
  logic [37:0] g_io_refill_req_info_vpn, i_io_refill_req_info_vpn;
  logic [1:0] g_io_refill_req_info_source, i_io_refill_req_info_source;
  logic [1:0] g_io_refill_level, i_io_refill_level;
  logic [47:0] g_io_pmp_req_bits_addr, i_io_pmp_req_bits_addr;
  logic g_io_bitmap_req_valid, i_io_bitmap_req_valid;
  logic [35:0] g_io_bitmap_req_bits_bmppn, i_io_bitmap_req_bits_bmppn;
  logic [37:0] g_io_bitmap_req_bits_vpn, i_io_bitmap_req_bits_vpn;
  logic [1:0] g_io_bitmap_req_bits_level, i_io_bitmap_req_bits_level;
  logic [3:0] g_io_bitmap_req_bits_way_info, i_io_bitmap_req_bits_way_info;
  logic g_io_bitmap_req_bits_hptw_bypassed, i_io_bitmap_req_bits_hptw_bypassed;
  logic g_io_bitmap_req_bits_n, i_io_bitmap_req_bits_n;
  logic g_io_bitmap_resp_ready, i_io_bitmap_resp_ready;
  HPTW u_g (
    .clock(clock), .reset(reset),
    .io_sfence_valid                          (io_sfence_valid),
    .io_csr_satp_changed                      (io_csr_satp_changed),
    .io_csr_vsatp_changed                     (io_csr_vsatp_changed),
    .io_csr_hgatp_mode                        (io_csr_hgatp_mode),
    .io_csr_hgatp_vmid                        (io_csr_hgatp_vmid),
    .io_csr_hgatp_ppn                         (io_csr_hgatp_ppn),
    .io_csr_hgatp_changed                     (io_csr_hgatp_changed),
    .io_csr_mbmc_BME                          (io_csr_mbmc_BME),
    .io_csr_mbmc_CMODE                        (io_csr_mbmc_CMODE),
    .io_csr_priv_virt_changed                 (io_csr_priv_virt_changed),
    .io_csr_mPBMTE                            (io_csr_mPBMTE),
    .io_req_ready                             (g_io_req_ready),
    .io_req_valid                             (io_req_valid),
    .io_req_bits_source                       (io_req_bits_source),
    .io_req_bits_id                           (io_req_bits_id),
    .io_req_bits_gvpn                         (io_req_bits_gvpn),
    .io_req_bits_ppn                          (io_req_bits_ppn),
    .io_req_bits_l3Hit                        (io_req_bits_l3Hit),
    .io_req_bits_l2Hit                        (io_req_bits_l2Hit),
    .io_req_bits_l1Hit                        (io_req_bits_l1Hit),
    .io_req_bits_bypassed                     (io_req_bits_bypassed),
    .io_req_bits_bitmapCheck_jmp_bitmap_check (io_req_bits_bitmapCheck_jmp_bitmap_check),
    .io_req_bits_bitmapCheck_pte              (io_req_bits_bitmapCheck_pte),
    .io_req_bits_bitmapCheck_ptes_0           (io_req_bits_bitmapCheck_ptes_0),
    .io_req_bits_bitmapCheck_ptes_1           (io_req_bits_bitmapCheck_ptes_1),
    .io_req_bits_bitmapCheck_ptes_2           (io_req_bits_bitmapCheck_ptes_2),
    .io_req_bits_bitmapCheck_ptes_3           (io_req_bits_bitmapCheck_ptes_3),
    .io_req_bits_bitmapCheck_ptes_4           (io_req_bits_bitmapCheck_ptes_4),
    .io_req_bits_bitmapCheck_ptes_5           (io_req_bits_bitmapCheck_ptes_5),
    .io_req_bits_bitmapCheck_ptes_6           (io_req_bits_bitmapCheck_ptes_6),
    .io_req_bits_bitmapCheck_ptes_7           (io_req_bits_bitmapCheck_ptes_7),
    .io_req_bits_bitmapCheck_hitway           (io_req_bits_bitmapCheck_hitway),
    .io_req_bits_bitmapCheck_fromSP           (io_req_bits_bitmapCheck_fromSP),
    .io_req_bits_bitmapCheck_SPlevel          (io_req_bits_bitmapCheck_SPlevel),
    .io_resp_ready                            (io_resp_ready),
    .io_resp_valid                            (g_io_resp_valid),
    .io_resp_bits_resp_entry_tag              (g_io_resp_bits_resp_entry_tag),
    .io_resp_bits_resp_entry_vmid             (g_io_resp_bits_resp_entry_vmid),
    .io_resp_bits_resp_entry_n                (g_io_resp_bits_resp_entry_n),
    .io_resp_bits_resp_entry_pbmt             (g_io_resp_bits_resp_entry_pbmt),
    .io_resp_bits_resp_entry_ppn              (g_io_resp_bits_resp_entry_ppn),
    .io_resp_bits_resp_entry_perm_d           (g_io_resp_bits_resp_entry_perm_d),
    .io_resp_bits_resp_entry_perm_a           (g_io_resp_bits_resp_entry_perm_a),
    .io_resp_bits_resp_entry_perm_g           (g_io_resp_bits_resp_entry_perm_g),
    .io_resp_bits_resp_entry_perm_u           (g_io_resp_bits_resp_entry_perm_u),
    .io_resp_bits_resp_entry_perm_x           (g_io_resp_bits_resp_entry_perm_x),
    .io_resp_bits_resp_entry_perm_w           (g_io_resp_bits_resp_entry_perm_w),
    .io_resp_bits_resp_entry_perm_r           (g_io_resp_bits_resp_entry_perm_r),
    .io_resp_bits_resp_entry_level            (g_io_resp_bits_resp_entry_level),
    .io_resp_bits_resp_gpf                    (g_io_resp_bits_resp_gpf),
    .io_resp_bits_resp_gaf                    (g_io_resp_bits_resp_gaf),
    .io_resp_bits_id                          (g_io_resp_bits_id),
    .io_mem_req_ready                         (io_mem_req_ready),
    .io_mem_req_valid                         (g_io_mem_req_valid),
    .io_mem_req_bits_addr                     (g_io_mem_req_bits_addr),
    .io_mem_req_bits_hptw_bypassed            (g_io_mem_req_bits_hptw_bypassed),
    .io_mem_resp_valid                        (io_mem_resp_valid),
    .io_mem_resp_bits                         (io_mem_resp_bits),
    .io_mem_mask                              (io_mem_mask),
    .io_refill_req_info_vpn                   (g_io_refill_req_info_vpn),
    .io_refill_req_info_source                (g_io_refill_req_info_source),
    .io_refill_level                          (g_io_refill_level),
    .io_pmp_req_bits_addr                     (g_io_pmp_req_bits_addr),
    .io_pmp_resp_ld                           (io_pmp_resp_ld),
    .io_pmp_resp_mmio                         (io_pmp_resp_mmio),
    .io_bitmap_req_ready                      (io_bitmap_req_ready),
    .io_bitmap_req_valid                      (g_io_bitmap_req_valid),
    .io_bitmap_req_bits_bmppn                 (g_io_bitmap_req_bits_bmppn),
    .io_bitmap_req_bits_vpn                   (g_io_bitmap_req_bits_vpn),
    .io_bitmap_req_bits_level                 (g_io_bitmap_req_bits_level),
    .io_bitmap_req_bits_way_info              (g_io_bitmap_req_bits_way_info),
    .io_bitmap_req_bits_hptw_bypassed         (g_io_bitmap_req_bits_hptw_bypassed),
    .io_bitmap_req_bits_n                     (g_io_bitmap_req_bits_n),
    .io_bitmap_resp_ready                     (g_io_bitmap_resp_ready),
    .io_bitmap_resp_valid                     (io_bitmap_resp_valid),
    .io_bitmap_resp_bits_cf                   (io_bitmap_resp_bits_cf),
    .io_l0_way_info                           (io_l0_way_info)
  );
  HPTW_xs u_i (
    .clock(clock), .reset(reset),
    .io_sfence_valid                          (io_sfence_valid),
    .io_csr_satp_changed                      (io_csr_satp_changed),
    .io_csr_vsatp_changed                     (io_csr_vsatp_changed),
    .io_csr_hgatp_mode                        (io_csr_hgatp_mode),
    .io_csr_hgatp_vmid                        (io_csr_hgatp_vmid),
    .io_csr_hgatp_ppn                         (io_csr_hgatp_ppn),
    .io_csr_hgatp_changed                     (io_csr_hgatp_changed),
    .io_csr_mbmc_BME                          (io_csr_mbmc_BME),
    .io_csr_mbmc_CMODE                        (io_csr_mbmc_CMODE),
    .io_csr_priv_virt_changed                 (io_csr_priv_virt_changed),
    .io_csr_mPBMTE                            (io_csr_mPBMTE),
    .io_req_ready                             (i_io_req_ready),
    .io_req_valid                             (io_req_valid),
    .io_req_bits_source                       (io_req_bits_source),
    .io_req_bits_id                           (io_req_bits_id),
    .io_req_bits_gvpn                         (io_req_bits_gvpn),
    .io_req_bits_ppn                          (io_req_bits_ppn),
    .io_req_bits_l3Hit                        (io_req_bits_l3Hit),
    .io_req_bits_l2Hit                        (io_req_bits_l2Hit),
    .io_req_bits_l1Hit                        (io_req_bits_l1Hit),
    .io_req_bits_bypassed                     (io_req_bits_bypassed),
    .io_req_bits_bitmapCheck_jmp_bitmap_check (io_req_bits_bitmapCheck_jmp_bitmap_check),
    .io_req_bits_bitmapCheck_pte              (io_req_bits_bitmapCheck_pte),
    .io_req_bits_bitmapCheck_ptes_0           (io_req_bits_bitmapCheck_ptes_0),
    .io_req_bits_bitmapCheck_ptes_1           (io_req_bits_bitmapCheck_ptes_1),
    .io_req_bits_bitmapCheck_ptes_2           (io_req_bits_bitmapCheck_ptes_2),
    .io_req_bits_bitmapCheck_ptes_3           (io_req_bits_bitmapCheck_ptes_3),
    .io_req_bits_bitmapCheck_ptes_4           (io_req_bits_bitmapCheck_ptes_4),
    .io_req_bits_bitmapCheck_ptes_5           (io_req_bits_bitmapCheck_ptes_5),
    .io_req_bits_bitmapCheck_ptes_6           (io_req_bits_bitmapCheck_ptes_6),
    .io_req_bits_bitmapCheck_ptes_7           (io_req_bits_bitmapCheck_ptes_7),
    .io_req_bits_bitmapCheck_hitway           (io_req_bits_bitmapCheck_hitway),
    .io_req_bits_bitmapCheck_fromSP           (io_req_bits_bitmapCheck_fromSP),
    .io_req_bits_bitmapCheck_SPlevel          (io_req_bits_bitmapCheck_SPlevel),
    .io_resp_ready                            (io_resp_ready),
    .io_resp_valid                            (i_io_resp_valid),
    .io_resp_bits_resp_entry_tag              (i_io_resp_bits_resp_entry_tag),
    .io_resp_bits_resp_entry_vmid             (i_io_resp_bits_resp_entry_vmid),
    .io_resp_bits_resp_entry_n                (i_io_resp_bits_resp_entry_n),
    .io_resp_bits_resp_entry_pbmt             (i_io_resp_bits_resp_entry_pbmt),
    .io_resp_bits_resp_entry_ppn              (i_io_resp_bits_resp_entry_ppn),
    .io_resp_bits_resp_entry_perm_d           (i_io_resp_bits_resp_entry_perm_d),
    .io_resp_bits_resp_entry_perm_a           (i_io_resp_bits_resp_entry_perm_a),
    .io_resp_bits_resp_entry_perm_g           (i_io_resp_bits_resp_entry_perm_g),
    .io_resp_bits_resp_entry_perm_u           (i_io_resp_bits_resp_entry_perm_u),
    .io_resp_bits_resp_entry_perm_x           (i_io_resp_bits_resp_entry_perm_x),
    .io_resp_bits_resp_entry_perm_w           (i_io_resp_bits_resp_entry_perm_w),
    .io_resp_bits_resp_entry_perm_r           (i_io_resp_bits_resp_entry_perm_r),
    .io_resp_bits_resp_entry_level            (i_io_resp_bits_resp_entry_level),
    .io_resp_bits_resp_gpf                    (i_io_resp_bits_resp_gpf),
    .io_resp_bits_resp_gaf                    (i_io_resp_bits_resp_gaf),
    .io_resp_bits_id                          (i_io_resp_bits_id),
    .io_mem_req_ready                         (io_mem_req_ready),
    .io_mem_req_valid                         (i_io_mem_req_valid),
    .io_mem_req_bits_addr                     (i_io_mem_req_bits_addr),
    .io_mem_req_bits_hptw_bypassed            (i_io_mem_req_bits_hptw_bypassed),
    .io_mem_resp_valid                        (io_mem_resp_valid),
    .io_mem_resp_bits                         (io_mem_resp_bits),
    .io_mem_mask                              (io_mem_mask),
    .io_refill_req_info_vpn                   (i_io_refill_req_info_vpn),
    .io_refill_req_info_source                (i_io_refill_req_info_source),
    .io_refill_level                          (i_io_refill_level),
    .io_pmp_req_bits_addr                     (i_io_pmp_req_bits_addr),
    .io_pmp_resp_ld                           (io_pmp_resp_ld),
    .io_pmp_resp_mmio                         (io_pmp_resp_mmio),
    .io_bitmap_req_ready                      (io_bitmap_req_ready),
    .io_bitmap_req_valid                      (i_io_bitmap_req_valid),
    .io_bitmap_req_bits_bmppn                 (i_io_bitmap_req_bits_bmppn),
    .io_bitmap_req_bits_vpn                   (i_io_bitmap_req_bits_vpn),
    .io_bitmap_req_bits_level                 (i_io_bitmap_req_bits_level),
    .io_bitmap_req_bits_way_info              (i_io_bitmap_req_bits_way_info),
    .io_bitmap_req_bits_hptw_bypassed         (i_io_bitmap_req_bits_hptw_bypassed),
    .io_bitmap_req_bits_n                     (i_io_bitmap_req_bits_n),
    .io_bitmap_resp_ready                     (i_io_bitmap_resp_ready),
    .io_bitmap_resp_valid                     (io_bitmap_resp_valid),
    .io_bitmap_resp_bits_cf                   (io_bitmap_resp_bits_cf),
    .io_l0_way_info                           (io_l0_way_info)
  );
  // 逐拍比全部 33 个输出（golden 端口表逐根量出，不手抄）
  task automatic compare_outputs(input int cyc);
    checks++; if (g_io_req_ready !== i_io_req_ready) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_req_ready g=%h i=%h", cyc, g_io_req_ready, i_io_req_ready); end
    checks++; if (g_io_resp_valid !== i_io_resp_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_valid g=%h i=%h", cyc, g_io_resp_valid, i_io_resp_valid); end
    checks++; if (g_io_resp_bits_resp_entry_tag !== i_io_resp_bits_resp_entry_tag) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_tag g=%h i=%h", cyc, g_io_resp_bits_resp_entry_tag, i_io_resp_bits_resp_entry_tag); end
    checks++; if (g_io_resp_bits_resp_entry_vmid !== i_io_resp_bits_resp_entry_vmid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_vmid g=%h i=%h", cyc, g_io_resp_bits_resp_entry_vmid, i_io_resp_bits_resp_entry_vmid); end
    checks++; if (g_io_resp_bits_resp_entry_n !== i_io_resp_bits_resp_entry_n) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_n g=%h i=%h", cyc, g_io_resp_bits_resp_entry_n, i_io_resp_bits_resp_entry_n); end
    checks++; if (g_io_resp_bits_resp_entry_pbmt !== i_io_resp_bits_resp_entry_pbmt) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_pbmt g=%h i=%h", cyc, g_io_resp_bits_resp_entry_pbmt, i_io_resp_bits_resp_entry_pbmt); end
    checks++; if (g_io_resp_bits_resp_entry_ppn !== i_io_resp_bits_resp_entry_ppn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_ppn g=%h i=%h", cyc, g_io_resp_bits_resp_entry_ppn, i_io_resp_bits_resp_entry_ppn); end
    checks++; if (g_io_resp_bits_resp_entry_perm_d !== i_io_resp_bits_resp_entry_perm_d) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_perm_d g=%h i=%h", cyc, g_io_resp_bits_resp_entry_perm_d, i_io_resp_bits_resp_entry_perm_d); end
    checks++; if (g_io_resp_bits_resp_entry_perm_a !== i_io_resp_bits_resp_entry_perm_a) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_perm_a g=%h i=%h", cyc, g_io_resp_bits_resp_entry_perm_a, i_io_resp_bits_resp_entry_perm_a); end
    checks++; if (g_io_resp_bits_resp_entry_perm_g !== i_io_resp_bits_resp_entry_perm_g) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_perm_g g=%h i=%h", cyc, g_io_resp_bits_resp_entry_perm_g, i_io_resp_bits_resp_entry_perm_g); end
    checks++; if (g_io_resp_bits_resp_entry_perm_u !== i_io_resp_bits_resp_entry_perm_u) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_perm_u g=%h i=%h", cyc, g_io_resp_bits_resp_entry_perm_u, i_io_resp_bits_resp_entry_perm_u); end
    checks++; if (g_io_resp_bits_resp_entry_perm_x !== i_io_resp_bits_resp_entry_perm_x) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_perm_x g=%h i=%h", cyc, g_io_resp_bits_resp_entry_perm_x, i_io_resp_bits_resp_entry_perm_x); end
    checks++; if (g_io_resp_bits_resp_entry_perm_w !== i_io_resp_bits_resp_entry_perm_w) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_perm_w g=%h i=%h", cyc, g_io_resp_bits_resp_entry_perm_w, i_io_resp_bits_resp_entry_perm_w); end
    checks++; if (g_io_resp_bits_resp_entry_perm_r !== i_io_resp_bits_resp_entry_perm_r) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_perm_r g=%h i=%h", cyc, g_io_resp_bits_resp_entry_perm_r, i_io_resp_bits_resp_entry_perm_r); end
    checks++; if (g_io_resp_bits_resp_entry_level !== i_io_resp_bits_resp_entry_level) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_entry_level g=%h i=%h", cyc, g_io_resp_bits_resp_entry_level, i_io_resp_bits_resp_entry_level); end
    checks++; if (g_io_resp_bits_resp_gpf !== i_io_resp_bits_resp_gpf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_gpf g=%h i=%h", cyc, g_io_resp_bits_resp_gpf, i_io_resp_bits_resp_gpf); end
    checks++; if (g_io_resp_bits_resp_gaf !== i_io_resp_bits_resp_gaf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_resp_gaf g=%h i=%h", cyc, g_io_resp_bits_resp_gaf, i_io_resp_bits_resp_gaf); end
    checks++; if (g_io_resp_bits_id !== i_io_resp_bits_id) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_id g=%h i=%h", cyc, g_io_resp_bits_id, i_io_resp_bits_id); end
    checks++; if (g_io_mem_req_valid !== i_io_mem_req_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_req_valid g=%h i=%h", cyc, g_io_mem_req_valid, i_io_mem_req_valid); end
    checks++; if (g_io_mem_req_bits_addr !== i_io_mem_req_bits_addr) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_req_bits_addr g=%h i=%h", cyc, g_io_mem_req_bits_addr, i_io_mem_req_bits_addr); end
    checks++; if (g_io_mem_req_bits_hptw_bypassed !== i_io_mem_req_bits_hptw_bypassed) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_req_bits_hptw_bypassed g=%h i=%h", cyc, g_io_mem_req_bits_hptw_bypassed, i_io_mem_req_bits_hptw_bypassed); end
    checks++; if (g_io_refill_req_info_vpn !== i_io_refill_req_info_vpn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_refill_req_info_vpn g=%h i=%h", cyc, g_io_refill_req_info_vpn, i_io_refill_req_info_vpn); end
    checks++; if (g_io_refill_req_info_source !== i_io_refill_req_info_source) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_refill_req_info_source g=%h i=%h", cyc, g_io_refill_req_info_source, i_io_refill_req_info_source); end
    checks++; if (g_io_refill_level !== i_io_refill_level) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_refill_level g=%h i=%h", cyc, g_io_refill_level, i_io_refill_level); end
    checks++; if (g_io_pmp_req_bits_addr !== i_io_pmp_req_bits_addr) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_pmp_req_bits_addr g=%h i=%h", cyc, g_io_pmp_req_bits_addr, i_io_pmp_req_bits_addr); end
    checks++; if (g_io_bitmap_req_valid !== i_io_bitmap_req_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_valid g=%h i=%h", cyc, g_io_bitmap_req_valid, i_io_bitmap_req_valid); end
    checks++; if (g_io_bitmap_req_bits_bmppn !== i_io_bitmap_req_bits_bmppn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_bits_bmppn g=%h i=%h", cyc, g_io_bitmap_req_bits_bmppn, i_io_bitmap_req_bits_bmppn); end
    checks++; if (g_io_bitmap_req_bits_vpn !== i_io_bitmap_req_bits_vpn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_bits_vpn g=%h i=%h", cyc, g_io_bitmap_req_bits_vpn, i_io_bitmap_req_bits_vpn); end
    checks++; if (g_io_bitmap_req_bits_level !== i_io_bitmap_req_bits_level) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_bits_level g=%h i=%h", cyc, g_io_bitmap_req_bits_level, i_io_bitmap_req_bits_level); end
    checks++; if (g_io_bitmap_req_bits_way_info !== i_io_bitmap_req_bits_way_info) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_bits_way_info g=%h i=%h", cyc, g_io_bitmap_req_bits_way_info, i_io_bitmap_req_bits_way_info); end
    checks++; if (g_io_bitmap_req_bits_hptw_bypassed !== i_io_bitmap_req_bits_hptw_bypassed) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_bits_hptw_bypassed g=%h i=%h", cyc, g_io_bitmap_req_bits_hptw_bypassed, i_io_bitmap_req_bits_hptw_bypassed); end
    checks++; if (g_io_bitmap_req_bits_n !== i_io_bitmap_req_bits_n) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_bits_n g=%h i=%h", cyc, g_io_bitmap_req_bits_n, i_io_bitmap_req_bits_n); end
    checks++; if (g_io_bitmap_resp_ready !== i_io_bitmap_resp_ready) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_resp_ready g=%h i=%h", cyc, g_io_bitmap_resp_ready, i_io_bitmap_resp_ready); end
  endtask
  // END GENERATED(harness)

  // ---------------------------------------------------------------------------
  // 激励
  // ---------------------------------------------------------------------------
  logic [37:0] vpn_pool [4];
  int cyc = 0;

  function automatic logic [63:0] rand_pte(input logic [1:0] lvl);
    logic [63:0] p;
    int kind;
    p = {$urandom(), $urandom()};
    kind = $urandom_range(0, 2);
    if (kind == 0) begin            // 干净的 next 型
      p[63:46] = '0; p[7:0] = 8'b0000_0001; p[9:8] = '0;
    end else if (kind == 1) begin   // 干净的叶子，按 lvl 对齐
      p[63:46] = '0; p[7:0] = 8'b1101_0011;  // d=1 a=1 u=1 r=1 v=1
      p[5] = $urandom_range(0, 1);           // g 随机
      p[7] = $urandom_range(0, 1);           // d 随机
      p[3] = $urandom_range(0, 1);           // x 随机
      p[2] = $urandom_range(0, 1);           // w 随机
      if (lvl == 2'd1) p[18:10] = '0;
      if (lvl == 2'd2) p[27:10] = '0;
      if (lvl == 2'd3) p[36:10] = '0;
      if ($urandom_range(0, 7) == 0) p[63] = 1'b1;          // 偶尔 napot
      if ($urandom_range(0, 7) == 0) p[13:10] = 4'd8;
    end
    return p;
  endfunction

  task automatic drive_random();
    io_sfence_valid          <= ($urandom_range(0, 399) == 0);
    io_csr_satp_changed      <= ($urandom_range(0, 399) == 0);
    io_csr_vsatp_changed     <= ($urandom_range(0, 399) == 0);
    io_csr_hgatp_changed     <= ($urandom_range(0, 399) == 0);
    io_csr_priv_virt_changed <= ($urandom_range(0, 399) == 0);
    if (cyc % 512 == 0) begin
      automatic int m = $urandom_range(0, 9);
      io_csr_hgatp_mode <= (m < 6) ? 4'h9 : (m < 9) ? 4'h8 : $urandom_range(0, 15);
      io_csr_hgatp_vmid <= $urandom();
      io_csr_hgatp_ppn  <= {$urandom(), $urandom()};
      io_csr_mPBMTE     <= $urandom_range(0, 1);
    end
    if (cyc % 256 == 0) begin
      io_csr_mbmc_BME   <= $urandom_range(0, 1);
      io_csr_mbmc_CMODE <= $urandom_range(0, 2) == 0;
    end
    io_req_valid       <= $urandom_range(0, 1);
    io_req_bits_source <= $urandom();
    io_req_bits_id     <= $urandom();
    io_req_bits_gvpn   <= ($urandom_range(0, 3) == 0) ? {$urandom(), $urandom()} : vpn_pool[$urandom_range(0, 3)];
    io_req_bits_ppn    <= {$urandom(), $urandom()};
    io_req_bits_l3Hit  <= $urandom_range(0, 1);
    io_req_bits_l2Hit  <= $urandom_range(0, 1);
    io_req_bits_l1Hit  <= $urandom_range(0, 2) == 0;
    io_req_bits_bypassed <= $urandom_range(0, 1);
    io_req_bits_bitmapCheck_jmp_bitmap_check <= $urandom_range(0, 1);
    io_req_bits_bitmapCheck_pte    <= rand_pte($urandom_range(0, 3));
    io_req_bits_bitmapCheck_ptes_0 <= rand_pte(0);
    io_req_bits_bitmapCheck_ptes_1 <= rand_pte(0);
    io_req_bits_bitmapCheck_ptes_2 <= rand_pte(0);
    io_req_bits_bitmapCheck_ptes_3 <= rand_pte(0);
    io_req_bits_bitmapCheck_ptes_4 <= rand_pte(0);
    io_req_bits_bitmapCheck_ptes_5 <= rand_pte(0);
    io_req_bits_bitmapCheck_ptes_6 <= rand_pte(0);
    io_req_bits_bitmapCheck_ptes_7 <= rand_pte(0);
    io_req_bits_bitmapCheck_hitway  <= $urandom();
    io_req_bits_bitmapCheck_fromSP  <= $urandom_range(0, 1);
    io_req_bits_bitmapCheck_SPlevel <= $urandom();
    io_resp_ready      <= $urandom_range(0, 3) != 0;
    io_mem_req_ready   <= $urandom_range(0, 3) != 0;
    io_mem_resp_valid  <= $urandom_range(0, 2) == 0;
    io_mem_resp_bits   <= rand_pte(u_g.level);
    io_mem_mask        <= $urandom_range(0, 9) == 0;
    io_pmp_resp_ld     <= $urandom_range(0, 19) == 0;
    io_pmp_resp_mmio   <= $urandom_range(0, 19) == 0;
    io_bitmap_req_ready  <= $urandom_range(0, 3) != 0;
    io_bitmap_resp_valid <= $urandom_range(0, 2) == 0;
    io_bitmap_resp_bits_cf <= $urandom_range(0, 1);
    io_l0_way_info     <= $urandom();
  endtask

  task automatic count_cov();
    if (g_io_req_ready && io_req_valid) begin
      if (io_req_bits_bitmapCheck_jmp_bitmap_check) cov_jmp_fire++; else cov_walk_fire++;
    end
    if (g_io_mem_req_valid && io_mem_req_ready) cov_mem_req++;
    if (g_io_resp_valid && io_resp_ready) begin
      cov_resp++;
      if (g_io_resp_bits_resp_gpf) cov_gpf++;
      if (g_io_resp_bits_resp_gaf) cov_gaf++;
      if (g_io_resp_bits_resp_entry_level == 2'd0) cov_level0++;
      if (io_csr_hgatp_mode == 4'h8) cov_sv39++;
    end
    if (g_io_bitmap_req_valid && io_bitmap_req_ready) cov_bm_req++;
    if (g_io_bitmap_resp_ready && io_bitmap_resp_valid) cov_bm_resp++;
  endtask

  initial clock = 0;
  always #5 clock = ~clock;

  initial begin
    if (!$value$plusargs("ncycles=%d", ncycles)) ncycles = 200000;
    for (int i = 0; i < 4; i++) vpn_pool[i] = {$urandom(), $urandom()};
    reset = 1;
    io_sfence_valid = 0; io_csr_satp_changed = 0; io_csr_vsatp_changed = 0;
    io_csr_hgatp_changed = 0; io_csr_priv_virt_changed = 0;
    io_csr_hgatp_mode = 4'h9; io_csr_hgatp_vmid = 0; io_csr_hgatp_ppn = 0;
    io_csr_mbmc_BME = 0; io_csr_mbmc_CMODE = 0; io_csr_mPBMTE = 0;
    io_req_valid = 0; io_req_bits_source = 0; io_req_bits_id = 0; io_req_bits_gvpn = 0;
    io_req_bits_ppn = 0; io_req_bits_l3Hit = 0; io_req_bits_l2Hit = 0; io_req_bits_l1Hit = 0;
    io_req_bits_bypassed = 0; io_req_bits_bitmapCheck_jmp_bitmap_check = 0;
    io_req_bits_bitmapCheck_pte = 0;
    io_req_bits_bitmapCheck_ptes_0 = 0; io_req_bits_bitmapCheck_ptes_1 = 0;
    io_req_bits_bitmapCheck_ptes_2 = 0; io_req_bits_bitmapCheck_ptes_3 = 0;
    io_req_bits_bitmapCheck_ptes_4 = 0; io_req_bits_bitmapCheck_ptes_5 = 0;
    io_req_bits_bitmapCheck_ptes_6 = 0; io_req_bits_bitmapCheck_ptes_7 = 0;
    io_req_bits_bitmapCheck_hitway = 0; io_req_bits_bitmapCheck_fromSP = 0;
    io_req_bits_bitmapCheck_SPlevel = 0;
    io_resp_ready = 0; io_mem_req_ready = 0; io_mem_resp_valid = 0; io_mem_resp_bits = 0;
    io_mem_mask = 0; io_pmp_resp_ld = 0; io_pmp_resp_mmio = 0;
    io_bitmap_req_ready = 0; io_bitmap_resp_valid = 0; io_bitmap_resp_bits_cf = 0;
    io_l0_way_info = 0;
    repeat (4) @(posedge clock);
    #1 reset = 0;
    for (cyc = 1; cyc <= ncycles; cyc++) begin
      @(negedge clock);
      compare_outputs(cyc);
      count_cov();
      drive_random();
    end
    $display("cov: walk_fire=%0d jmp_fire=%0d mem_req=%0d resp=%0d gpf=%0d gaf=%0d bm_req=%0d bm_resp=%0d level0=%0d sv39_resp=%0d",
             cov_walk_fire, cov_jmp_fire, cov_mem_req, cov_resp, cov_gpf, cov_gaf,
             cov_bm_req, cov_bm_resp, cov_level0, cov_sv39);
    if (cov_walk_fire == 0 || cov_jmp_fire == 0 || cov_mem_req == 0 || cov_resp == 0 ||
        cov_gpf == 0 || cov_gaf == 0 || cov_bm_req == 0 || cov_bm_resp == 0 ||
        cov_level0 == 0 || cov_sv39 == 0) begin
      $display("COVERAGE FLOOR NOT MET");
      errors++;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
