// tb.sv —— LLPTW 的双例化逐拍差分 UT（verif/ut/LLPTW）。
//
// 双例化 golden LLPTW 与派生的 LLPTW_xs，同拍同激励，逐拍比全部 74 个输出
// （输出表由 scripts/gen_mmu5.py 从 golden 端口表逐根量出）。impl 侧的三个 RRArbiterInit_1 与
// bitmap_arb 用 rtl/common 的重写件，hptw_req_arb（Arbiter2_LLPTW_Anon）两侧同源 golden。
//
// 【激励设计——6 条目的池子要填满、同扇区要撞、四种 s2xlate 要都走】
//   · io_in 的 vpn 从 6 项池子里取（四分之一全随机），池子里的 vpn 高 35 位（扇区号）只有 3 种，
//     让"同扇区合并"（to_wait / to_cache / dup_req_fire）常态发生；s2xlate 四种按 4:2:1:3 配比；
//     source==2（预取）占五分之一，让 enq_state=idle 的丢弃路径出现；jmp_bitmap_check 六分之一。
//   · 访存响应 io_mem_resp_valid 四分之一拍拉高，id 随机 0..7（★含 6/7，打 golden 的 Vec 越界语义★），
//     512 位块由 8 条 PTE 拼成：每条三分之一干净 next / 三分之一干净叶子 / 三分之一全随机。
//   · HPTW 响应 id 随机 0..7；entry.tag 一半概率取自 golden 某个条目当前的 ppn（否则匹配条件
//     tag==entries(i).ppn 几乎不可能成立，hptw_resp 状态永远走不出去）；gpf/gaf 各 10%，perm_r 70%。
//   · bitmap 响应 id 随机 0..7，cf/cfs 随机；req_mask/flush_latch 各 10%/5%；PMP 各 5%。
//   · mbmc.BME/CMODE 每 256 拍换；hgatp.mode Sv39x4/Sv48x4/其它 = 3:6:1，每 512 拍换；
//     mPBMTE/hPBMTE 同步换；flush 五根各 1/500 拍。
//
// 【判别力自证】覆盖下限（见文末）：12 个状态每个都要有条目到达过；in/out/cache/mem_req/hptw_req/
//   bitmap_req 的 fire 都 > 0；io_in 被 full 顶回过；访存响应 id 为 6/7 且被某条目接受过。任何一项为 0 自判 FAIL。
//   注入过的 mutant（都不进库；同一份激励，seed=1，20000 拍）：
//     M1 dup_wait_resp 对 id 6/7 不再映射到条目 0     -> errors>0（首失配 cyc 4227 io_out_valid）抓到
//     M2 priority encoder 全不命中时默认 0 而不是 5   -> errors>0（首失配 cyc 1 io_out_bits_id）抓到
//     M3 HPTW 无故障响应不跟随同扇区 mem_waiting 条目 -> errors=0，**没抓到**：需要 allStage 条目在 hptw_resp
//        时恰有同扇区同 s2xlate 条目在 mem_waiting，本激励 20k 拍内没造出来，留给 FM。
//     M4 预取请求不丢弃（enq_state 不改 idle）        -> errors>0（首失配 cyc 12 io_mem_enq_ptr）抓到
//     M5 mem_resp_hit 不在下一拍清零                  -> errors>0（首失配 cyc 9 io_mem_buffer_it_1）抓到
//
// 【实测】两档 initreg × 3 seed × 200000 拍，每拍 74 个输出，全部 errors=0：
//     make run SEED=1|7|42 NCYCLES=200000 INITREG=0|1
//   seed 1 initreg0：cov in=25978 out=16070 cache=962 mem=11426 hptw=3328 bm=5201 full=53678 oob_resp=274
//                   s2x=10099/5153/2541/8185；12 个状态到达拍数（条目累计）
//                   184290 206910 120964 17688 24362 430833 31033 7654 2094 1320 9008 163844
`timescale 1ns/1ps
module tb;
  int errors = 0;
  int checks = 0;
  int ncycles;
  int cov_state [12];
  int cov_in = 0, cov_out = 0, cov_cache = 0, cov_mem = 0, cov_hptw = 0, cov_bm = 0, cov_full = 0, cov_oob = 0;
  int cov_s2x [4];

  // BEGIN GENERATED(harness) —— 由 gen_mmu5.py 生成：信号声明 / 双例化 / 输出逐拍比对
  logic clock, reset;
  logic io_sfence_valid;
  logic io_csr_satp_changed;
  logic io_csr_vsatp_changed;
  logic [3:0] io_csr_hgatp_mode;
  logic io_csr_hgatp_changed;
  logic io_csr_mbmc_BME;
  logic io_csr_mbmc_CMODE;
  logic io_csr_priv_virt_changed;
  logic io_csr_mPBMTE;
  logic io_csr_hPBMTE;
  logic io_in_valid;
  logic [37:0] io_in_bits_req_info_vpn;
  logic [1:0] io_in_bits_req_info_s2xlate;
  logic [1:0] io_in_bits_req_info_source;
  logic [43:0] io_in_bits_ppn;
  logic io_in_bits_bitmapCheck_jmp_bitmap_check;
  logic [63:0] io_in_bits_bitmapCheck_ptes_0;
  logic [63:0] io_in_bits_bitmapCheck_ptes_1;
  logic [63:0] io_in_bits_bitmapCheck_ptes_2;
  logic [63:0] io_in_bits_bitmapCheck_ptes_3;
  logic [63:0] io_in_bits_bitmapCheck_ptes_4;
  logic [63:0] io_in_bits_bitmapCheck_ptes_5;
  logic [63:0] io_in_bits_bitmapCheck_ptes_6;
  logic [63:0] io_in_bits_bitmapCheck_ptes_7;
  logic io_in_bits_bitmapCheck_cfs_0;
  logic io_in_bits_bitmapCheck_cfs_1;
  logic io_in_bits_bitmapCheck_cfs_2;
  logic io_in_bits_bitmapCheck_cfs_3;
  logic io_in_bits_bitmapCheck_cfs_4;
  logic io_in_bits_bitmapCheck_cfs_5;
  logic io_in_bits_bitmapCheck_cfs_6;
  logic io_in_bits_bitmapCheck_cfs_7;
  logic [3:0] io_in_bits_bitmapCheck_hitway;
  logic io_out_ready;
  logic io_mem_req_ready;
  logic io_mem_resp_valid;
  logic [2:0] io_mem_resp_bits_id;
  logic [511:0] io_mem_resp_bits_value;
  logic io_mem_req_mask_0;
  logic io_mem_req_mask_1;
  logic io_mem_req_mask_2;
  logic io_mem_req_mask_3;
  logic io_mem_req_mask_4;
  logic io_mem_req_mask_5;
  logic io_mem_flush_latch_0;
  logic io_mem_flush_latch_1;
  logic io_mem_flush_latch_2;
  logic io_mem_flush_latch_3;
  logic io_mem_flush_latch_4;
  logic io_mem_flush_latch_5;
  logic io_cache_ready;
  logic io_pmp_0_resp_ld;
  logic io_pmp_0_resp_mmio;
  logic io_pmp_1_resp_ld;
  logic io_pmp_1_resp_mmio;
  logic io_hptw_req_ready;
  logic io_hptw_resp_valid;
  logic [2:0] io_hptw_resp_bits_id;
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
  logic io_bitmap_req_ready;
  logic io_bitmap_resp_valid;
  logic io_bitmap_resp_bits_cf;
  logic io_bitmap_resp_bits_cfs_0;
  logic io_bitmap_resp_bits_cfs_1;
  logic io_bitmap_resp_bits_cfs_2;
  logic io_bitmap_resp_bits_cfs_3;
  logic io_bitmap_resp_bits_cfs_4;
  logic io_bitmap_resp_bits_cfs_5;
  logic io_bitmap_resp_bits_cfs_6;
  logic io_bitmap_resp_bits_cfs_7;
  logic [2:0] io_bitmap_resp_bits_id;
  logic [3:0] io_l0_way_info;
  logic g_io_in_ready, i_io_in_ready;
  logic g_io_out_valid, i_io_out_valid;
  logic [37:0] g_io_out_bits_req_info_vpn, i_io_out_bits_req_info_vpn;
  logic [1:0] g_io_out_bits_req_info_s2xlate, i_io_out_bits_req_info_s2xlate;
  logic [1:0] g_io_out_bits_req_info_source, i_io_out_bits_req_info_source;
  logic [3:0] g_io_out_bits_id, i_io_out_bits_id;
  logic [37:0] g_io_out_bits_h_resp_entry_tag, i_io_out_bits_h_resp_entry_tag;
  logic [13:0] g_io_out_bits_h_resp_entry_vmid, i_io_out_bits_h_resp_entry_vmid;
  logic g_io_out_bits_h_resp_entry_n, i_io_out_bits_h_resp_entry_n;
  logic [1:0] g_io_out_bits_h_resp_entry_pbmt, i_io_out_bits_h_resp_entry_pbmt;
  logic [37:0] g_io_out_bits_h_resp_entry_ppn, i_io_out_bits_h_resp_entry_ppn;
  logic g_io_out_bits_h_resp_entry_perm_d, i_io_out_bits_h_resp_entry_perm_d;
  logic g_io_out_bits_h_resp_entry_perm_a, i_io_out_bits_h_resp_entry_perm_a;
  logic g_io_out_bits_h_resp_entry_perm_g, i_io_out_bits_h_resp_entry_perm_g;
  logic g_io_out_bits_h_resp_entry_perm_u, i_io_out_bits_h_resp_entry_perm_u;
  logic g_io_out_bits_h_resp_entry_perm_x, i_io_out_bits_h_resp_entry_perm_x;
  logic g_io_out_bits_h_resp_entry_perm_w, i_io_out_bits_h_resp_entry_perm_w;
  logic g_io_out_bits_h_resp_entry_perm_r, i_io_out_bits_h_resp_entry_perm_r;
  logic [1:0] g_io_out_bits_h_resp_entry_level, i_io_out_bits_h_resp_entry_level;
  logic g_io_out_bits_h_resp_gpf, i_io_out_bits_h_resp_gpf;
  logic g_io_out_bits_h_resp_gaf, i_io_out_bits_h_resp_gaf;
  logic g_io_out_bits_first_s2xlate_fault, i_io_out_bits_first_s2xlate_fault;
  logic g_io_out_bits_af, i_io_out_bits_af;
  logic g_io_out_bits_bitmapCheck_jmp_bitmap_check, i_io_out_bits_bitmapCheck_jmp_bitmap_check;
  logic [63:0] g_io_out_bits_bitmapCheck_ptes_0, i_io_out_bits_bitmapCheck_ptes_0;
  logic [63:0] g_io_out_bits_bitmapCheck_ptes_1, i_io_out_bits_bitmapCheck_ptes_1;
  logic [63:0] g_io_out_bits_bitmapCheck_ptes_2, i_io_out_bits_bitmapCheck_ptes_2;
  logic [63:0] g_io_out_bits_bitmapCheck_ptes_3, i_io_out_bits_bitmapCheck_ptes_3;
  logic [63:0] g_io_out_bits_bitmapCheck_ptes_4, i_io_out_bits_bitmapCheck_ptes_4;
  logic [63:0] g_io_out_bits_bitmapCheck_ptes_5, i_io_out_bits_bitmapCheck_ptes_5;
  logic [63:0] g_io_out_bits_bitmapCheck_ptes_6, i_io_out_bits_bitmapCheck_ptes_6;
  logic [63:0] g_io_out_bits_bitmapCheck_ptes_7, i_io_out_bits_bitmapCheck_ptes_7;
  logic g_io_out_bits_bitmapCheck_cfs_0, i_io_out_bits_bitmapCheck_cfs_0;
  logic g_io_out_bits_bitmapCheck_cfs_1, i_io_out_bits_bitmapCheck_cfs_1;
  logic g_io_out_bits_bitmapCheck_cfs_2, i_io_out_bits_bitmapCheck_cfs_2;
  logic g_io_out_bits_bitmapCheck_cfs_3, i_io_out_bits_bitmapCheck_cfs_3;
  logic g_io_out_bits_bitmapCheck_cfs_4, i_io_out_bits_bitmapCheck_cfs_4;
  logic g_io_out_bits_bitmapCheck_cfs_5, i_io_out_bits_bitmapCheck_cfs_5;
  logic g_io_out_bits_bitmapCheck_cfs_6, i_io_out_bits_bitmapCheck_cfs_6;
  logic g_io_out_bits_bitmapCheck_cfs_7, i_io_out_bits_bitmapCheck_cfs_7;
  logic g_io_mem_req_valid, i_io_mem_req_valid;
  logic [47:0] g_io_mem_req_bits_addr, i_io_mem_req_bits_addr;
  logic [3:0] g_io_mem_req_bits_id, i_io_mem_req_bits_id;
  logic [2:0] g_io_mem_enq_ptr, i_io_mem_enq_ptr;
  logic g_io_mem_buffer_it_0, i_io_mem_buffer_it_0;
  logic g_io_mem_buffer_it_1, i_io_mem_buffer_it_1;
  logic g_io_mem_buffer_it_2, i_io_mem_buffer_it_2;
  logic g_io_mem_buffer_it_3, i_io_mem_buffer_it_3;
  logic g_io_mem_buffer_it_4, i_io_mem_buffer_it_4;
  logic g_io_mem_buffer_it_5, i_io_mem_buffer_it_5;
  logic [37:0] g_io_mem_refill_vpn, i_io_mem_refill_vpn;
  logic [1:0] g_io_mem_refill_s2xlate, i_io_mem_refill_s2xlate;
  logic [1:0] g_io_mem_refill_source, i_io_mem_refill_source;
  logic g_io_cache_valid, i_io_cache_valid;
  logic [37:0] g_io_cache_bits_vpn, i_io_cache_bits_vpn;
  logic [1:0] g_io_cache_bits_s2xlate, i_io_cache_bits_s2xlate;
  logic [1:0] g_io_cache_bits_source, i_io_cache_bits_source;
  logic [47:0] g_io_pmp_0_req_bits_addr, i_io_pmp_0_req_bits_addr;
  logic [47:0] g_io_pmp_1_req_bits_addr, i_io_pmp_1_req_bits_addr;
  logic g_io_hptw_req_valid, i_io_hptw_req_valid;
  logic [1:0] g_io_hptw_req_bits_source, i_io_hptw_req_bits_source;
  logic [2:0] g_io_hptw_req_bits_id, i_io_hptw_req_bits_id;
  logic [43:0] g_io_hptw_req_bits_gvpn, i_io_hptw_req_bits_gvpn;
  logic g_io_bitmap_req_valid, i_io_bitmap_req_valid;
  logic [35:0] g_io_bitmap_req_bits_bmppn, i_io_bitmap_req_bits_bmppn;
  logic [2:0] g_io_bitmap_req_bits_id, i_io_bitmap_req_bits_id;
  logic [37:0] g_io_bitmap_req_bits_vpn, i_io_bitmap_req_bits_vpn;
  logic [3:0] g_io_bitmap_req_bits_way_info, i_io_bitmap_req_bits_way_info;
  logic [1:0] g_io_bitmap_req_bits_s2xlate, i_io_bitmap_req_bits_s2xlate;
  logic g_io_bitmap_req_bits_n, i_io_bitmap_req_bits_n;
  logic g_io_bitmap_resp_ready, i_io_bitmap_resp_ready;
  logic [5:0] g_io_perf_0_value, i_io_perf_0_value;
  logic [5:0] g_io_perf_1_value, i_io_perf_1_value;
  logic [5:0] g_io_perf_2_value, i_io_perf_2_value;
  logic [5:0] g_io_perf_3_value, i_io_perf_3_value;
  LLPTW u_g (
    .clock(clock), .reset(reset),
    .io_sfence_valid                          (io_sfence_valid),
    .io_csr_satp_changed                      (io_csr_satp_changed),
    .io_csr_vsatp_changed                     (io_csr_vsatp_changed),
    .io_csr_hgatp_mode                        (io_csr_hgatp_mode),
    .io_csr_hgatp_changed                     (io_csr_hgatp_changed),
    .io_csr_mbmc_BME                          (io_csr_mbmc_BME),
    .io_csr_mbmc_CMODE                        (io_csr_mbmc_CMODE),
    .io_csr_priv_virt_changed                 (io_csr_priv_virt_changed),
    .io_csr_mPBMTE                            (io_csr_mPBMTE),
    .io_csr_hPBMTE                            (io_csr_hPBMTE),
    .io_in_ready                              (g_io_in_ready),
    .io_in_valid                              (io_in_valid),
    .io_in_bits_req_info_vpn                  (io_in_bits_req_info_vpn),
    .io_in_bits_req_info_s2xlate              (io_in_bits_req_info_s2xlate),
    .io_in_bits_req_info_source               (io_in_bits_req_info_source),
    .io_in_bits_ppn                           (io_in_bits_ppn),
    .io_in_bits_bitmapCheck_jmp_bitmap_check  (io_in_bits_bitmapCheck_jmp_bitmap_check),
    .io_in_bits_bitmapCheck_ptes_0            (io_in_bits_bitmapCheck_ptes_0),
    .io_in_bits_bitmapCheck_ptes_1            (io_in_bits_bitmapCheck_ptes_1),
    .io_in_bits_bitmapCheck_ptes_2            (io_in_bits_bitmapCheck_ptes_2),
    .io_in_bits_bitmapCheck_ptes_3            (io_in_bits_bitmapCheck_ptes_3),
    .io_in_bits_bitmapCheck_ptes_4            (io_in_bits_bitmapCheck_ptes_4),
    .io_in_bits_bitmapCheck_ptes_5            (io_in_bits_bitmapCheck_ptes_5),
    .io_in_bits_bitmapCheck_ptes_6            (io_in_bits_bitmapCheck_ptes_6),
    .io_in_bits_bitmapCheck_ptes_7            (io_in_bits_bitmapCheck_ptes_7),
    .io_in_bits_bitmapCheck_cfs_0             (io_in_bits_bitmapCheck_cfs_0),
    .io_in_bits_bitmapCheck_cfs_1             (io_in_bits_bitmapCheck_cfs_1),
    .io_in_bits_bitmapCheck_cfs_2             (io_in_bits_bitmapCheck_cfs_2),
    .io_in_bits_bitmapCheck_cfs_3             (io_in_bits_bitmapCheck_cfs_3),
    .io_in_bits_bitmapCheck_cfs_4             (io_in_bits_bitmapCheck_cfs_4),
    .io_in_bits_bitmapCheck_cfs_5             (io_in_bits_bitmapCheck_cfs_5),
    .io_in_bits_bitmapCheck_cfs_6             (io_in_bits_bitmapCheck_cfs_6),
    .io_in_bits_bitmapCheck_cfs_7             (io_in_bits_bitmapCheck_cfs_7),
    .io_in_bits_bitmapCheck_hitway            (io_in_bits_bitmapCheck_hitway),
    .io_out_ready                             (io_out_ready),
    .io_out_valid                             (g_io_out_valid),
    .io_out_bits_req_info_vpn                 (g_io_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate             (g_io_out_bits_req_info_s2xlate),
    .io_out_bits_req_info_source              (g_io_out_bits_req_info_source),
    .io_out_bits_id                           (g_io_out_bits_id),
    .io_out_bits_h_resp_entry_tag             (g_io_out_bits_h_resp_entry_tag),
    .io_out_bits_h_resp_entry_vmid            (g_io_out_bits_h_resp_entry_vmid),
    .io_out_bits_h_resp_entry_n               (g_io_out_bits_h_resp_entry_n),
    .io_out_bits_h_resp_entry_pbmt            (g_io_out_bits_h_resp_entry_pbmt),
    .io_out_bits_h_resp_entry_ppn             (g_io_out_bits_h_resp_entry_ppn),
    .io_out_bits_h_resp_entry_perm_d          (g_io_out_bits_h_resp_entry_perm_d),
    .io_out_bits_h_resp_entry_perm_a          (g_io_out_bits_h_resp_entry_perm_a),
    .io_out_bits_h_resp_entry_perm_g          (g_io_out_bits_h_resp_entry_perm_g),
    .io_out_bits_h_resp_entry_perm_u          (g_io_out_bits_h_resp_entry_perm_u),
    .io_out_bits_h_resp_entry_perm_x          (g_io_out_bits_h_resp_entry_perm_x),
    .io_out_bits_h_resp_entry_perm_w          (g_io_out_bits_h_resp_entry_perm_w),
    .io_out_bits_h_resp_entry_perm_r          (g_io_out_bits_h_resp_entry_perm_r),
    .io_out_bits_h_resp_entry_level           (g_io_out_bits_h_resp_entry_level),
    .io_out_bits_h_resp_gpf                   (g_io_out_bits_h_resp_gpf),
    .io_out_bits_h_resp_gaf                   (g_io_out_bits_h_resp_gaf),
    .io_out_bits_first_s2xlate_fault          (g_io_out_bits_first_s2xlate_fault),
    .io_out_bits_af                           (g_io_out_bits_af),
    .io_out_bits_bitmapCheck_jmp_bitmap_check (g_io_out_bits_bitmapCheck_jmp_bitmap_check),
    .io_out_bits_bitmapCheck_ptes_0           (g_io_out_bits_bitmapCheck_ptes_0),
    .io_out_bits_bitmapCheck_ptes_1           (g_io_out_bits_bitmapCheck_ptes_1),
    .io_out_bits_bitmapCheck_ptes_2           (g_io_out_bits_bitmapCheck_ptes_2),
    .io_out_bits_bitmapCheck_ptes_3           (g_io_out_bits_bitmapCheck_ptes_3),
    .io_out_bits_bitmapCheck_ptes_4           (g_io_out_bits_bitmapCheck_ptes_4),
    .io_out_bits_bitmapCheck_ptes_5           (g_io_out_bits_bitmapCheck_ptes_5),
    .io_out_bits_bitmapCheck_ptes_6           (g_io_out_bits_bitmapCheck_ptes_6),
    .io_out_bits_bitmapCheck_ptes_7           (g_io_out_bits_bitmapCheck_ptes_7),
    .io_out_bits_bitmapCheck_cfs_0            (g_io_out_bits_bitmapCheck_cfs_0),
    .io_out_bits_bitmapCheck_cfs_1            (g_io_out_bits_bitmapCheck_cfs_1),
    .io_out_bits_bitmapCheck_cfs_2            (g_io_out_bits_bitmapCheck_cfs_2),
    .io_out_bits_bitmapCheck_cfs_3            (g_io_out_bits_bitmapCheck_cfs_3),
    .io_out_bits_bitmapCheck_cfs_4            (g_io_out_bits_bitmapCheck_cfs_4),
    .io_out_bits_bitmapCheck_cfs_5            (g_io_out_bits_bitmapCheck_cfs_5),
    .io_out_bits_bitmapCheck_cfs_6            (g_io_out_bits_bitmapCheck_cfs_6),
    .io_out_bits_bitmapCheck_cfs_7            (g_io_out_bits_bitmapCheck_cfs_7),
    .io_mem_req_ready                         (io_mem_req_ready),
    .io_mem_req_valid                         (g_io_mem_req_valid),
    .io_mem_req_bits_addr                     (g_io_mem_req_bits_addr),
    .io_mem_req_bits_id                       (g_io_mem_req_bits_id),
    .io_mem_resp_valid                        (io_mem_resp_valid),
    .io_mem_resp_bits_id                      (io_mem_resp_bits_id),
    .io_mem_resp_bits_value                   (io_mem_resp_bits_value),
    .io_mem_enq_ptr                           (g_io_mem_enq_ptr),
    .io_mem_buffer_it_0                       (g_io_mem_buffer_it_0),
    .io_mem_buffer_it_1                       (g_io_mem_buffer_it_1),
    .io_mem_buffer_it_2                       (g_io_mem_buffer_it_2),
    .io_mem_buffer_it_3                       (g_io_mem_buffer_it_3),
    .io_mem_buffer_it_4                       (g_io_mem_buffer_it_4),
    .io_mem_buffer_it_5                       (g_io_mem_buffer_it_5),
    .io_mem_refill_vpn                        (g_io_mem_refill_vpn),
    .io_mem_refill_s2xlate                    (g_io_mem_refill_s2xlate),
    .io_mem_refill_source                     (g_io_mem_refill_source),
    .io_mem_req_mask_0                        (io_mem_req_mask_0),
    .io_mem_req_mask_1                        (io_mem_req_mask_1),
    .io_mem_req_mask_2                        (io_mem_req_mask_2),
    .io_mem_req_mask_3                        (io_mem_req_mask_3),
    .io_mem_req_mask_4                        (io_mem_req_mask_4),
    .io_mem_req_mask_5                        (io_mem_req_mask_5),
    .io_mem_flush_latch_0                     (io_mem_flush_latch_0),
    .io_mem_flush_latch_1                     (io_mem_flush_latch_1),
    .io_mem_flush_latch_2                     (io_mem_flush_latch_2),
    .io_mem_flush_latch_3                     (io_mem_flush_latch_3),
    .io_mem_flush_latch_4                     (io_mem_flush_latch_4),
    .io_mem_flush_latch_5                     (io_mem_flush_latch_5),
    .io_cache_ready                           (io_cache_ready),
    .io_cache_valid                           (g_io_cache_valid),
    .io_cache_bits_vpn                        (g_io_cache_bits_vpn),
    .io_cache_bits_s2xlate                    (g_io_cache_bits_s2xlate),
    .io_cache_bits_source                     (g_io_cache_bits_source),
    .io_pmp_0_req_bits_addr                   (g_io_pmp_0_req_bits_addr),
    .io_pmp_0_resp_ld                         (io_pmp_0_resp_ld),
    .io_pmp_0_resp_mmio                       (io_pmp_0_resp_mmio),
    .io_pmp_1_req_bits_addr                   (g_io_pmp_1_req_bits_addr),
    .io_pmp_1_resp_ld                         (io_pmp_1_resp_ld),
    .io_pmp_1_resp_mmio                       (io_pmp_1_resp_mmio),
    .io_hptw_req_ready                        (io_hptw_req_ready),
    .io_hptw_req_valid                        (g_io_hptw_req_valid),
    .io_hptw_req_bits_source                  (g_io_hptw_req_bits_source),
    .io_hptw_req_bits_id                      (g_io_hptw_req_bits_id),
    .io_hptw_req_bits_gvpn                    (g_io_hptw_req_bits_gvpn),
    .io_hptw_resp_valid                       (io_hptw_resp_valid),
    .io_hptw_resp_bits_id                     (io_hptw_resp_bits_id),
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
    .io_bitmap_req_ready                      (io_bitmap_req_ready),
    .io_bitmap_req_valid                      (g_io_bitmap_req_valid),
    .io_bitmap_req_bits_bmppn                 (g_io_bitmap_req_bits_bmppn),
    .io_bitmap_req_bits_id                    (g_io_bitmap_req_bits_id),
    .io_bitmap_req_bits_vpn                   (g_io_bitmap_req_bits_vpn),
    .io_bitmap_req_bits_way_info              (g_io_bitmap_req_bits_way_info),
    .io_bitmap_req_bits_s2xlate               (g_io_bitmap_req_bits_s2xlate),
    .io_bitmap_req_bits_n                     (g_io_bitmap_req_bits_n),
    .io_bitmap_resp_ready                     (g_io_bitmap_resp_ready),
    .io_bitmap_resp_valid                     (io_bitmap_resp_valid),
    .io_bitmap_resp_bits_cf                   (io_bitmap_resp_bits_cf),
    .io_bitmap_resp_bits_cfs_0                (io_bitmap_resp_bits_cfs_0),
    .io_bitmap_resp_bits_cfs_1                (io_bitmap_resp_bits_cfs_1),
    .io_bitmap_resp_bits_cfs_2                (io_bitmap_resp_bits_cfs_2),
    .io_bitmap_resp_bits_cfs_3                (io_bitmap_resp_bits_cfs_3),
    .io_bitmap_resp_bits_cfs_4                (io_bitmap_resp_bits_cfs_4),
    .io_bitmap_resp_bits_cfs_5                (io_bitmap_resp_bits_cfs_5),
    .io_bitmap_resp_bits_cfs_6                (io_bitmap_resp_bits_cfs_6),
    .io_bitmap_resp_bits_cfs_7                (io_bitmap_resp_bits_cfs_7),
    .io_bitmap_resp_bits_id                   (io_bitmap_resp_bits_id),
    .io_l0_way_info                           (io_l0_way_info),
    .io_perf_0_value                          (g_io_perf_0_value),
    .io_perf_1_value                          (g_io_perf_1_value),
    .io_perf_2_value                          (g_io_perf_2_value),
    .io_perf_3_value                          (g_io_perf_3_value)
  );
  LLPTW_xs u_i (
    .clock(clock), .reset(reset),
    .io_sfence_valid                          (io_sfence_valid),
    .io_csr_satp_changed                      (io_csr_satp_changed),
    .io_csr_vsatp_changed                     (io_csr_vsatp_changed),
    .io_csr_hgatp_mode                        (io_csr_hgatp_mode),
    .io_csr_hgatp_changed                     (io_csr_hgatp_changed),
    .io_csr_mbmc_BME                          (io_csr_mbmc_BME),
    .io_csr_mbmc_CMODE                        (io_csr_mbmc_CMODE),
    .io_csr_priv_virt_changed                 (io_csr_priv_virt_changed),
    .io_csr_mPBMTE                            (io_csr_mPBMTE),
    .io_csr_hPBMTE                            (io_csr_hPBMTE),
    .io_in_ready                              (i_io_in_ready),
    .io_in_valid                              (io_in_valid),
    .io_in_bits_req_info_vpn                  (io_in_bits_req_info_vpn),
    .io_in_bits_req_info_s2xlate              (io_in_bits_req_info_s2xlate),
    .io_in_bits_req_info_source               (io_in_bits_req_info_source),
    .io_in_bits_ppn                           (io_in_bits_ppn),
    .io_in_bits_bitmapCheck_jmp_bitmap_check  (io_in_bits_bitmapCheck_jmp_bitmap_check),
    .io_in_bits_bitmapCheck_ptes_0            (io_in_bits_bitmapCheck_ptes_0),
    .io_in_bits_bitmapCheck_ptes_1            (io_in_bits_bitmapCheck_ptes_1),
    .io_in_bits_bitmapCheck_ptes_2            (io_in_bits_bitmapCheck_ptes_2),
    .io_in_bits_bitmapCheck_ptes_3            (io_in_bits_bitmapCheck_ptes_3),
    .io_in_bits_bitmapCheck_ptes_4            (io_in_bits_bitmapCheck_ptes_4),
    .io_in_bits_bitmapCheck_ptes_5            (io_in_bits_bitmapCheck_ptes_5),
    .io_in_bits_bitmapCheck_ptes_6            (io_in_bits_bitmapCheck_ptes_6),
    .io_in_bits_bitmapCheck_ptes_7            (io_in_bits_bitmapCheck_ptes_7),
    .io_in_bits_bitmapCheck_cfs_0             (io_in_bits_bitmapCheck_cfs_0),
    .io_in_bits_bitmapCheck_cfs_1             (io_in_bits_bitmapCheck_cfs_1),
    .io_in_bits_bitmapCheck_cfs_2             (io_in_bits_bitmapCheck_cfs_2),
    .io_in_bits_bitmapCheck_cfs_3             (io_in_bits_bitmapCheck_cfs_3),
    .io_in_bits_bitmapCheck_cfs_4             (io_in_bits_bitmapCheck_cfs_4),
    .io_in_bits_bitmapCheck_cfs_5             (io_in_bits_bitmapCheck_cfs_5),
    .io_in_bits_bitmapCheck_cfs_6             (io_in_bits_bitmapCheck_cfs_6),
    .io_in_bits_bitmapCheck_cfs_7             (io_in_bits_bitmapCheck_cfs_7),
    .io_in_bits_bitmapCheck_hitway            (io_in_bits_bitmapCheck_hitway),
    .io_out_ready                             (io_out_ready),
    .io_out_valid                             (i_io_out_valid),
    .io_out_bits_req_info_vpn                 (i_io_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate             (i_io_out_bits_req_info_s2xlate),
    .io_out_bits_req_info_source              (i_io_out_bits_req_info_source),
    .io_out_bits_id                           (i_io_out_bits_id),
    .io_out_bits_h_resp_entry_tag             (i_io_out_bits_h_resp_entry_tag),
    .io_out_bits_h_resp_entry_vmid            (i_io_out_bits_h_resp_entry_vmid),
    .io_out_bits_h_resp_entry_n               (i_io_out_bits_h_resp_entry_n),
    .io_out_bits_h_resp_entry_pbmt            (i_io_out_bits_h_resp_entry_pbmt),
    .io_out_bits_h_resp_entry_ppn             (i_io_out_bits_h_resp_entry_ppn),
    .io_out_bits_h_resp_entry_perm_d          (i_io_out_bits_h_resp_entry_perm_d),
    .io_out_bits_h_resp_entry_perm_a          (i_io_out_bits_h_resp_entry_perm_a),
    .io_out_bits_h_resp_entry_perm_g          (i_io_out_bits_h_resp_entry_perm_g),
    .io_out_bits_h_resp_entry_perm_u          (i_io_out_bits_h_resp_entry_perm_u),
    .io_out_bits_h_resp_entry_perm_x          (i_io_out_bits_h_resp_entry_perm_x),
    .io_out_bits_h_resp_entry_perm_w          (i_io_out_bits_h_resp_entry_perm_w),
    .io_out_bits_h_resp_entry_perm_r          (i_io_out_bits_h_resp_entry_perm_r),
    .io_out_bits_h_resp_entry_level           (i_io_out_bits_h_resp_entry_level),
    .io_out_bits_h_resp_gpf                   (i_io_out_bits_h_resp_gpf),
    .io_out_bits_h_resp_gaf                   (i_io_out_bits_h_resp_gaf),
    .io_out_bits_first_s2xlate_fault          (i_io_out_bits_first_s2xlate_fault),
    .io_out_bits_af                           (i_io_out_bits_af),
    .io_out_bits_bitmapCheck_jmp_bitmap_check (i_io_out_bits_bitmapCheck_jmp_bitmap_check),
    .io_out_bits_bitmapCheck_ptes_0           (i_io_out_bits_bitmapCheck_ptes_0),
    .io_out_bits_bitmapCheck_ptes_1           (i_io_out_bits_bitmapCheck_ptes_1),
    .io_out_bits_bitmapCheck_ptes_2           (i_io_out_bits_bitmapCheck_ptes_2),
    .io_out_bits_bitmapCheck_ptes_3           (i_io_out_bits_bitmapCheck_ptes_3),
    .io_out_bits_bitmapCheck_ptes_4           (i_io_out_bits_bitmapCheck_ptes_4),
    .io_out_bits_bitmapCheck_ptes_5           (i_io_out_bits_bitmapCheck_ptes_5),
    .io_out_bits_bitmapCheck_ptes_6           (i_io_out_bits_bitmapCheck_ptes_6),
    .io_out_bits_bitmapCheck_ptes_7           (i_io_out_bits_bitmapCheck_ptes_7),
    .io_out_bits_bitmapCheck_cfs_0            (i_io_out_bits_bitmapCheck_cfs_0),
    .io_out_bits_bitmapCheck_cfs_1            (i_io_out_bits_bitmapCheck_cfs_1),
    .io_out_bits_bitmapCheck_cfs_2            (i_io_out_bits_bitmapCheck_cfs_2),
    .io_out_bits_bitmapCheck_cfs_3            (i_io_out_bits_bitmapCheck_cfs_3),
    .io_out_bits_bitmapCheck_cfs_4            (i_io_out_bits_bitmapCheck_cfs_4),
    .io_out_bits_bitmapCheck_cfs_5            (i_io_out_bits_bitmapCheck_cfs_5),
    .io_out_bits_bitmapCheck_cfs_6            (i_io_out_bits_bitmapCheck_cfs_6),
    .io_out_bits_bitmapCheck_cfs_7            (i_io_out_bits_bitmapCheck_cfs_7),
    .io_mem_req_ready                         (io_mem_req_ready),
    .io_mem_req_valid                         (i_io_mem_req_valid),
    .io_mem_req_bits_addr                     (i_io_mem_req_bits_addr),
    .io_mem_req_bits_id                       (i_io_mem_req_bits_id),
    .io_mem_resp_valid                        (io_mem_resp_valid),
    .io_mem_resp_bits_id                      (io_mem_resp_bits_id),
    .io_mem_resp_bits_value                   (io_mem_resp_bits_value),
    .io_mem_enq_ptr                           (i_io_mem_enq_ptr),
    .io_mem_buffer_it_0                       (i_io_mem_buffer_it_0),
    .io_mem_buffer_it_1                       (i_io_mem_buffer_it_1),
    .io_mem_buffer_it_2                       (i_io_mem_buffer_it_2),
    .io_mem_buffer_it_3                       (i_io_mem_buffer_it_3),
    .io_mem_buffer_it_4                       (i_io_mem_buffer_it_4),
    .io_mem_buffer_it_5                       (i_io_mem_buffer_it_5),
    .io_mem_refill_vpn                        (i_io_mem_refill_vpn),
    .io_mem_refill_s2xlate                    (i_io_mem_refill_s2xlate),
    .io_mem_refill_source                     (i_io_mem_refill_source),
    .io_mem_req_mask_0                        (io_mem_req_mask_0),
    .io_mem_req_mask_1                        (io_mem_req_mask_1),
    .io_mem_req_mask_2                        (io_mem_req_mask_2),
    .io_mem_req_mask_3                        (io_mem_req_mask_3),
    .io_mem_req_mask_4                        (io_mem_req_mask_4),
    .io_mem_req_mask_5                        (io_mem_req_mask_5),
    .io_mem_flush_latch_0                     (io_mem_flush_latch_0),
    .io_mem_flush_latch_1                     (io_mem_flush_latch_1),
    .io_mem_flush_latch_2                     (io_mem_flush_latch_2),
    .io_mem_flush_latch_3                     (io_mem_flush_latch_3),
    .io_mem_flush_latch_4                     (io_mem_flush_latch_4),
    .io_mem_flush_latch_5                     (io_mem_flush_latch_5),
    .io_cache_ready                           (io_cache_ready),
    .io_cache_valid                           (i_io_cache_valid),
    .io_cache_bits_vpn                        (i_io_cache_bits_vpn),
    .io_cache_bits_s2xlate                    (i_io_cache_bits_s2xlate),
    .io_cache_bits_source                     (i_io_cache_bits_source),
    .io_pmp_0_req_bits_addr                   (i_io_pmp_0_req_bits_addr),
    .io_pmp_0_resp_ld                         (io_pmp_0_resp_ld),
    .io_pmp_0_resp_mmio                       (io_pmp_0_resp_mmio),
    .io_pmp_1_req_bits_addr                   (i_io_pmp_1_req_bits_addr),
    .io_pmp_1_resp_ld                         (io_pmp_1_resp_ld),
    .io_pmp_1_resp_mmio                       (io_pmp_1_resp_mmio),
    .io_hptw_req_ready                        (io_hptw_req_ready),
    .io_hptw_req_valid                        (i_io_hptw_req_valid),
    .io_hptw_req_bits_source                  (i_io_hptw_req_bits_source),
    .io_hptw_req_bits_id                      (i_io_hptw_req_bits_id),
    .io_hptw_req_bits_gvpn                    (i_io_hptw_req_bits_gvpn),
    .io_hptw_resp_valid                       (io_hptw_resp_valid),
    .io_hptw_resp_bits_id                     (io_hptw_resp_bits_id),
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
    .io_bitmap_req_ready                      (io_bitmap_req_ready),
    .io_bitmap_req_valid                      (i_io_bitmap_req_valid),
    .io_bitmap_req_bits_bmppn                 (i_io_bitmap_req_bits_bmppn),
    .io_bitmap_req_bits_id                    (i_io_bitmap_req_bits_id),
    .io_bitmap_req_bits_vpn                   (i_io_bitmap_req_bits_vpn),
    .io_bitmap_req_bits_way_info              (i_io_bitmap_req_bits_way_info),
    .io_bitmap_req_bits_s2xlate               (i_io_bitmap_req_bits_s2xlate),
    .io_bitmap_req_bits_n                     (i_io_bitmap_req_bits_n),
    .io_bitmap_resp_ready                     (i_io_bitmap_resp_ready),
    .io_bitmap_resp_valid                     (io_bitmap_resp_valid),
    .io_bitmap_resp_bits_cf                   (io_bitmap_resp_bits_cf),
    .io_bitmap_resp_bits_cfs_0                (io_bitmap_resp_bits_cfs_0),
    .io_bitmap_resp_bits_cfs_1                (io_bitmap_resp_bits_cfs_1),
    .io_bitmap_resp_bits_cfs_2                (io_bitmap_resp_bits_cfs_2),
    .io_bitmap_resp_bits_cfs_3                (io_bitmap_resp_bits_cfs_3),
    .io_bitmap_resp_bits_cfs_4                (io_bitmap_resp_bits_cfs_4),
    .io_bitmap_resp_bits_cfs_5                (io_bitmap_resp_bits_cfs_5),
    .io_bitmap_resp_bits_cfs_6                (io_bitmap_resp_bits_cfs_6),
    .io_bitmap_resp_bits_cfs_7                (io_bitmap_resp_bits_cfs_7),
    .io_bitmap_resp_bits_id                   (io_bitmap_resp_bits_id),
    .io_l0_way_info                           (io_l0_way_info),
    .io_perf_0_value                          (i_io_perf_0_value),
    .io_perf_1_value                          (i_io_perf_1_value),
    .io_perf_2_value                          (i_io_perf_2_value),
    .io_perf_3_value                          (i_io_perf_3_value)
  );
  // 逐拍比全部 75 个输出（golden 端口表逐根量出，不手抄）
  task automatic compare_outputs(input int cyc);
    checks++; if (g_io_in_ready !== i_io_in_ready) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_in_ready g=%h i=%h", cyc, g_io_in_ready, i_io_in_ready); end
    checks++; if (g_io_out_valid !== i_io_out_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_valid g=%h i=%h", cyc, g_io_out_valid, i_io_out_valid); end
    checks++; if (g_io_out_bits_req_info_vpn !== i_io_out_bits_req_info_vpn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_req_info_vpn g=%h i=%h", cyc, g_io_out_bits_req_info_vpn, i_io_out_bits_req_info_vpn); end
    checks++; if (g_io_out_bits_req_info_s2xlate !== i_io_out_bits_req_info_s2xlate) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_req_info_s2xlate g=%h i=%h", cyc, g_io_out_bits_req_info_s2xlate, i_io_out_bits_req_info_s2xlate); end
    checks++; if (g_io_out_bits_req_info_source !== i_io_out_bits_req_info_source) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_req_info_source g=%h i=%h", cyc, g_io_out_bits_req_info_source, i_io_out_bits_req_info_source); end
    checks++; if (g_io_out_bits_id !== i_io_out_bits_id) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_id g=%h i=%h", cyc, g_io_out_bits_id, i_io_out_bits_id); end
    checks++; if (g_io_out_bits_h_resp_entry_tag !== i_io_out_bits_h_resp_entry_tag) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_h_resp_entry_tag g=%h i=%h", cyc, g_io_out_bits_h_resp_entry_tag, i_io_out_bits_h_resp_entry_tag); end
    checks++; if (g_io_out_bits_h_resp_entry_vmid !== i_io_out_bits_h_resp_entry_vmid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_h_resp_entry_vmid g=%h i=%h", cyc, g_io_out_bits_h_resp_entry_vmid, i_io_out_bits_h_resp_entry_vmid); end
    checks++; if (g_io_out_bits_h_resp_entry_n !== i_io_out_bits_h_resp_entry_n) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_h_resp_entry_n g=%h i=%h", cyc, g_io_out_bits_h_resp_entry_n, i_io_out_bits_h_resp_entry_n); end
    checks++; if (g_io_out_bits_h_resp_entry_pbmt !== i_io_out_bits_h_resp_entry_pbmt) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_h_resp_entry_pbmt g=%h i=%h", cyc, g_io_out_bits_h_resp_entry_pbmt, i_io_out_bits_h_resp_entry_pbmt); end
    checks++; if (g_io_out_bits_h_resp_entry_ppn !== i_io_out_bits_h_resp_entry_ppn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_h_resp_entry_ppn g=%h i=%h", cyc, g_io_out_bits_h_resp_entry_ppn, i_io_out_bits_h_resp_entry_ppn); end
    checks++; if (g_io_out_bits_h_resp_entry_perm_d !== i_io_out_bits_h_resp_entry_perm_d) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_h_resp_entry_perm_d g=%h i=%h", cyc, g_io_out_bits_h_resp_entry_perm_d, i_io_out_bits_h_resp_entry_perm_d); end
    checks++; if (g_io_out_bits_h_resp_entry_perm_a !== i_io_out_bits_h_resp_entry_perm_a) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_h_resp_entry_perm_a g=%h i=%h", cyc, g_io_out_bits_h_resp_entry_perm_a, i_io_out_bits_h_resp_entry_perm_a); end
    checks++; if (g_io_out_bits_h_resp_entry_perm_g !== i_io_out_bits_h_resp_entry_perm_g) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_h_resp_entry_perm_g g=%h i=%h", cyc, g_io_out_bits_h_resp_entry_perm_g, i_io_out_bits_h_resp_entry_perm_g); end
    checks++; if (g_io_out_bits_h_resp_entry_perm_u !== i_io_out_bits_h_resp_entry_perm_u) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_h_resp_entry_perm_u g=%h i=%h", cyc, g_io_out_bits_h_resp_entry_perm_u, i_io_out_bits_h_resp_entry_perm_u); end
    checks++; if (g_io_out_bits_h_resp_entry_perm_x !== i_io_out_bits_h_resp_entry_perm_x) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_h_resp_entry_perm_x g=%h i=%h", cyc, g_io_out_bits_h_resp_entry_perm_x, i_io_out_bits_h_resp_entry_perm_x); end
    checks++; if (g_io_out_bits_h_resp_entry_perm_w !== i_io_out_bits_h_resp_entry_perm_w) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_h_resp_entry_perm_w g=%h i=%h", cyc, g_io_out_bits_h_resp_entry_perm_w, i_io_out_bits_h_resp_entry_perm_w); end
    checks++; if (g_io_out_bits_h_resp_entry_perm_r !== i_io_out_bits_h_resp_entry_perm_r) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_h_resp_entry_perm_r g=%h i=%h", cyc, g_io_out_bits_h_resp_entry_perm_r, i_io_out_bits_h_resp_entry_perm_r); end
    checks++; if (g_io_out_bits_h_resp_entry_level !== i_io_out_bits_h_resp_entry_level) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_h_resp_entry_level g=%h i=%h", cyc, g_io_out_bits_h_resp_entry_level, i_io_out_bits_h_resp_entry_level); end
    checks++; if (g_io_out_bits_h_resp_gpf !== i_io_out_bits_h_resp_gpf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_h_resp_gpf g=%h i=%h", cyc, g_io_out_bits_h_resp_gpf, i_io_out_bits_h_resp_gpf); end
    checks++; if (g_io_out_bits_h_resp_gaf !== i_io_out_bits_h_resp_gaf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_h_resp_gaf g=%h i=%h", cyc, g_io_out_bits_h_resp_gaf, i_io_out_bits_h_resp_gaf); end
    checks++; if (g_io_out_bits_first_s2xlate_fault !== i_io_out_bits_first_s2xlate_fault) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_first_s2xlate_fault g=%h i=%h", cyc, g_io_out_bits_first_s2xlate_fault, i_io_out_bits_first_s2xlate_fault); end
    checks++; if (g_io_out_bits_af !== i_io_out_bits_af) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_af g=%h i=%h", cyc, g_io_out_bits_af, i_io_out_bits_af); end
    checks++; if (g_io_out_bits_bitmapCheck_jmp_bitmap_check !== i_io_out_bits_bitmapCheck_jmp_bitmap_check) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_bitmapCheck_jmp_bitmap_check g=%h i=%h", cyc, g_io_out_bits_bitmapCheck_jmp_bitmap_check, i_io_out_bits_bitmapCheck_jmp_bitmap_check); end
    checks++; if (g_io_out_bits_bitmapCheck_ptes_0 !== i_io_out_bits_bitmapCheck_ptes_0) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_bitmapCheck_ptes_0 g=%h i=%h", cyc, g_io_out_bits_bitmapCheck_ptes_0, i_io_out_bits_bitmapCheck_ptes_0); end
    checks++; if (g_io_out_bits_bitmapCheck_ptes_1 !== i_io_out_bits_bitmapCheck_ptes_1) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_bitmapCheck_ptes_1 g=%h i=%h", cyc, g_io_out_bits_bitmapCheck_ptes_1, i_io_out_bits_bitmapCheck_ptes_1); end
    checks++; if (g_io_out_bits_bitmapCheck_ptes_2 !== i_io_out_bits_bitmapCheck_ptes_2) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_bitmapCheck_ptes_2 g=%h i=%h", cyc, g_io_out_bits_bitmapCheck_ptes_2, i_io_out_bits_bitmapCheck_ptes_2); end
    checks++; if (g_io_out_bits_bitmapCheck_ptes_3 !== i_io_out_bits_bitmapCheck_ptes_3) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_bitmapCheck_ptes_3 g=%h i=%h", cyc, g_io_out_bits_bitmapCheck_ptes_3, i_io_out_bits_bitmapCheck_ptes_3); end
    checks++; if (g_io_out_bits_bitmapCheck_ptes_4 !== i_io_out_bits_bitmapCheck_ptes_4) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_bitmapCheck_ptes_4 g=%h i=%h", cyc, g_io_out_bits_bitmapCheck_ptes_4, i_io_out_bits_bitmapCheck_ptes_4); end
    checks++; if (g_io_out_bits_bitmapCheck_ptes_5 !== i_io_out_bits_bitmapCheck_ptes_5) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_bitmapCheck_ptes_5 g=%h i=%h", cyc, g_io_out_bits_bitmapCheck_ptes_5, i_io_out_bits_bitmapCheck_ptes_5); end
    checks++; if (g_io_out_bits_bitmapCheck_ptes_6 !== i_io_out_bits_bitmapCheck_ptes_6) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_bitmapCheck_ptes_6 g=%h i=%h", cyc, g_io_out_bits_bitmapCheck_ptes_6, i_io_out_bits_bitmapCheck_ptes_6); end
    checks++; if (g_io_out_bits_bitmapCheck_ptes_7 !== i_io_out_bits_bitmapCheck_ptes_7) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_bitmapCheck_ptes_7 g=%h i=%h", cyc, g_io_out_bits_bitmapCheck_ptes_7, i_io_out_bits_bitmapCheck_ptes_7); end
    checks++; if (g_io_out_bits_bitmapCheck_cfs_0 !== i_io_out_bits_bitmapCheck_cfs_0) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_bitmapCheck_cfs_0 g=%h i=%h", cyc, g_io_out_bits_bitmapCheck_cfs_0, i_io_out_bits_bitmapCheck_cfs_0); end
    checks++; if (g_io_out_bits_bitmapCheck_cfs_1 !== i_io_out_bits_bitmapCheck_cfs_1) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_bitmapCheck_cfs_1 g=%h i=%h", cyc, g_io_out_bits_bitmapCheck_cfs_1, i_io_out_bits_bitmapCheck_cfs_1); end
    checks++; if (g_io_out_bits_bitmapCheck_cfs_2 !== i_io_out_bits_bitmapCheck_cfs_2) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_bitmapCheck_cfs_2 g=%h i=%h", cyc, g_io_out_bits_bitmapCheck_cfs_2, i_io_out_bits_bitmapCheck_cfs_2); end
    checks++; if (g_io_out_bits_bitmapCheck_cfs_3 !== i_io_out_bits_bitmapCheck_cfs_3) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_bitmapCheck_cfs_3 g=%h i=%h", cyc, g_io_out_bits_bitmapCheck_cfs_3, i_io_out_bits_bitmapCheck_cfs_3); end
    checks++; if (g_io_out_bits_bitmapCheck_cfs_4 !== i_io_out_bits_bitmapCheck_cfs_4) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_bitmapCheck_cfs_4 g=%h i=%h", cyc, g_io_out_bits_bitmapCheck_cfs_4, i_io_out_bits_bitmapCheck_cfs_4); end
    checks++; if (g_io_out_bits_bitmapCheck_cfs_5 !== i_io_out_bits_bitmapCheck_cfs_5) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_bitmapCheck_cfs_5 g=%h i=%h", cyc, g_io_out_bits_bitmapCheck_cfs_5, i_io_out_bits_bitmapCheck_cfs_5); end
    checks++; if (g_io_out_bits_bitmapCheck_cfs_6 !== i_io_out_bits_bitmapCheck_cfs_6) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_bitmapCheck_cfs_6 g=%h i=%h", cyc, g_io_out_bits_bitmapCheck_cfs_6, i_io_out_bits_bitmapCheck_cfs_6); end
    checks++; if (g_io_out_bits_bitmapCheck_cfs_7 !== i_io_out_bits_bitmapCheck_cfs_7) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_out_bits_bitmapCheck_cfs_7 g=%h i=%h", cyc, g_io_out_bits_bitmapCheck_cfs_7, i_io_out_bits_bitmapCheck_cfs_7); end
    checks++; if (g_io_mem_req_valid !== i_io_mem_req_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_req_valid g=%h i=%h", cyc, g_io_mem_req_valid, i_io_mem_req_valid); end
    checks++; if (g_io_mem_req_bits_addr !== i_io_mem_req_bits_addr) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_req_bits_addr g=%h i=%h", cyc, g_io_mem_req_bits_addr, i_io_mem_req_bits_addr); end
    checks++; if (g_io_mem_req_bits_id !== i_io_mem_req_bits_id) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_req_bits_id g=%h i=%h", cyc, g_io_mem_req_bits_id, i_io_mem_req_bits_id); end
    checks++; if (g_io_mem_enq_ptr !== i_io_mem_enq_ptr) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_enq_ptr g=%h i=%h", cyc, g_io_mem_enq_ptr, i_io_mem_enq_ptr); end
    checks++; if (g_io_mem_buffer_it_0 !== i_io_mem_buffer_it_0) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_buffer_it_0 g=%h i=%h", cyc, g_io_mem_buffer_it_0, i_io_mem_buffer_it_0); end
    checks++; if (g_io_mem_buffer_it_1 !== i_io_mem_buffer_it_1) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_buffer_it_1 g=%h i=%h", cyc, g_io_mem_buffer_it_1, i_io_mem_buffer_it_1); end
    checks++; if (g_io_mem_buffer_it_2 !== i_io_mem_buffer_it_2) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_buffer_it_2 g=%h i=%h", cyc, g_io_mem_buffer_it_2, i_io_mem_buffer_it_2); end
    checks++; if (g_io_mem_buffer_it_3 !== i_io_mem_buffer_it_3) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_buffer_it_3 g=%h i=%h", cyc, g_io_mem_buffer_it_3, i_io_mem_buffer_it_3); end
    checks++; if (g_io_mem_buffer_it_4 !== i_io_mem_buffer_it_4) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_buffer_it_4 g=%h i=%h", cyc, g_io_mem_buffer_it_4, i_io_mem_buffer_it_4); end
    checks++; if (g_io_mem_buffer_it_5 !== i_io_mem_buffer_it_5) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_buffer_it_5 g=%h i=%h", cyc, g_io_mem_buffer_it_5, i_io_mem_buffer_it_5); end
    checks++; if (g_io_mem_refill_vpn !== i_io_mem_refill_vpn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_refill_vpn g=%h i=%h", cyc, g_io_mem_refill_vpn, i_io_mem_refill_vpn); end
    checks++; if (g_io_mem_refill_s2xlate !== i_io_mem_refill_s2xlate) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_refill_s2xlate g=%h i=%h", cyc, g_io_mem_refill_s2xlate, i_io_mem_refill_s2xlate); end
    checks++; if (g_io_mem_refill_source !== i_io_mem_refill_source) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_refill_source g=%h i=%h", cyc, g_io_mem_refill_source, i_io_mem_refill_source); end
    checks++; if (g_io_cache_valid !== i_io_cache_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_cache_valid g=%h i=%h", cyc, g_io_cache_valid, i_io_cache_valid); end
    checks++; if (g_io_cache_bits_vpn !== i_io_cache_bits_vpn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_cache_bits_vpn g=%h i=%h", cyc, g_io_cache_bits_vpn, i_io_cache_bits_vpn); end
    checks++; if (g_io_cache_bits_s2xlate !== i_io_cache_bits_s2xlate) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_cache_bits_s2xlate g=%h i=%h", cyc, g_io_cache_bits_s2xlate, i_io_cache_bits_s2xlate); end
    checks++; if (g_io_cache_bits_source !== i_io_cache_bits_source) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_cache_bits_source g=%h i=%h", cyc, g_io_cache_bits_source, i_io_cache_bits_source); end
    checks++; if (g_io_pmp_0_req_bits_addr !== i_io_pmp_0_req_bits_addr) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_pmp_0_req_bits_addr g=%h i=%h", cyc, g_io_pmp_0_req_bits_addr, i_io_pmp_0_req_bits_addr); end
    checks++; if (g_io_pmp_1_req_bits_addr !== i_io_pmp_1_req_bits_addr) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_pmp_1_req_bits_addr g=%h i=%h", cyc, g_io_pmp_1_req_bits_addr, i_io_pmp_1_req_bits_addr); end
    checks++; if (g_io_hptw_req_valid !== i_io_hptw_req_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_hptw_req_valid g=%h i=%h", cyc, g_io_hptw_req_valid, i_io_hptw_req_valid); end
    checks++; if (g_io_hptw_req_bits_source !== i_io_hptw_req_bits_source) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_hptw_req_bits_source g=%h i=%h", cyc, g_io_hptw_req_bits_source, i_io_hptw_req_bits_source); end
    checks++; if (g_io_hptw_req_bits_id !== i_io_hptw_req_bits_id) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_hptw_req_bits_id g=%h i=%h", cyc, g_io_hptw_req_bits_id, i_io_hptw_req_bits_id); end
    checks++; if (g_io_hptw_req_bits_gvpn !== i_io_hptw_req_bits_gvpn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_hptw_req_bits_gvpn g=%h i=%h", cyc, g_io_hptw_req_bits_gvpn, i_io_hptw_req_bits_gvpn); end
    checks++; if (g_io_bitmap_req_valid !== i_io_bitmap_req_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_valid g=%h i=%h", cyc, g_io_bitmap_req_valid, i_io_bitmap_req_valid); end
    checks++; if (g_io_bitmap_req_bits_bmppn !== i_io_bitmap_req_bits_bmppn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_bits_bmppn g=%h i=%h", cyc, g_io_bitmap_req_bits_bmppn, i_io_bitmap_req_bits_bmppn); end
    checks++; if (g_io_bitmap_req_bits_id !== i_io_bitmap_req_bits_id) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_bits_id g=%h i=%h", cyc, g_io_bitmap_req_bits_id, i_io_bitmap_req_bits_id); end
    checks++; if (g_io_bitmap_req_bits_vpn !== i_io_bitmap_req_bits_vpn) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_bits_vpn g=%h i=%h", cyc, g_io_bitmap_req_bits_vpn, i_io_bitmap_req_bits_vpn); end
    checks++; if (g_io_bitmap_req_bits_way_info !== i_io_bitmap_req_bits_way_info) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_bitmap_req_bits_way_info g=%h i=%h", cyc, g_io_bitmap_req_bits_way_info, i_io_bitmap_req_bits_way_info); end
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
  endtask
  // END GENERATED(harness)

  logic [37:0] vpn_pool [6];
  int cyc = 0;

  function automatic logic [63:0] rand_pte();
    logic [63:0] p;
    int kind;
    p = {$urandom(), $urandom()};
    kind = $urandom_range(0, 2);
    if (kind == 0) begin            // 干净的 next 型（level 0 上就是 pf：非叶子）
      p[63:46] = '0; p[9:0] = 10'b00_0000_0001;
    end else if (kind == 1) begin   // 干净的叶子
      p[63:46] = '0; p[7:0] = 8'b1101_0011;   // d a u r v
      p[5] = $urandom_range(0, 1); p[3] = $urandom_range(0, 1); p[2] = $urandom_range(0, 1);
      if ($urandom_range(0, 7) == 0) begin p[63] = 1'b1; p[13:10] = 4'd8; end   // napot
      if ($urandom_range(0, 7) == 0) p[53:46] = $urandom();                     // 偶尔 ppn 越界 (gpf)
    end
    return p;
  endfunction

  function automatic logic [37:0] pick_vpn();
    logic [37:0] v;
    if ($urandom_range(0, 3) == 0) v = {$urandom(), $urandom()};
    else v = vpn_pool[$urandom_range(0, 5)];
    v[2:0] = $urandom();
    return v;
  endfunction

  function automatic logic [1:0] pick_s2x();
    int r = $urandom_range(0, 9);
    return (r < 4) ? 2'd0 : (r < 6) ? 2'd1 : (r < 7) ? 2'd2 : 2'd3;
  endfunction

  // HPTW 响应要"对号"才有人接：id 必须等于某个在等的条目的 wait_id，tag 必须等于它的 ppn。
  // 一半概率从 golden 里正在 hptw_resp / last_hptw_resp 的条目中挑一个对号，另一半全随机
  // （随机的那一半负责"不对号的响应必须被忽略"这条路径）。
  logic [2:0]  hptw_pick_id;
  logic [37:0] hptw_pick_tag;
  task automatic pick_hptw();
    automatic int cand [6];
    automatic int n = 0;
    hptw_pick_id  = $urandom_range(0, 7);
    hptw_pick_tag = {$urandom(), $urandom()};
    if (u_g.state_0 == 4'd2 || u_g.state_0 == 4'd8) cand[n++] = 0;
    if (u_g.state_1 == 4'd2 || u_g.state_1 == 4'd8) cand[n++] = 1;
    if (u_g.state_2 == 4'd2 || u_g.state_2 == 4'd8) cand[n++] = 2;
    if (u_g.state_3 == 4'd2 || u_g.state_3 == 4'd8) cand[n++] = 3;
    if (u_g.state_4 == 4'd2 || u_g.state_4 == 4'd8) cand[n++] = 4;
    if (u_g.state_5 == 4'd2 || u_g.state_5 == 4'd8) cand[n++] = 5;
    if (n > 0 && $urandom_range(0, 1)) begin
      case (cand[$urandom_range(0, n - 1)])
        0: begin hptw_pick_id = u_g.entries_0_wait_id; hptw_pick_tag = u_g.entries_0_ppn[37:0]; end
        1: begin hptw_pick_id = u_g.entries_1_wait_id; hptw_pick_tag = u_g.entries_1_ppn[37:0]; end
        2: begin hptw_pick_id = u_g.entries_2_wait_id; hptw_pick_tag = u_g.entries_2_ppn[37:0]; end
        3: begin hptw_pick_id = u_g.entries_3_wait_id; hptw_pick_tag = u_g.entries_3_ppn[37:0]; end
        4: begin hptw_pick_id = u_g.entries_4_wait_id; hptw_pick_tag = u_g.entries_4_ppn[37:0]; end
        default: begin hptw_pick_id = u_g.entries_5_wait_id; hptw_pick_tag = u_g.entries_5_ppn[37:0]; end
      endcase
    end
  endtask

  task automatic drive_random();
    io_sfence_valid          <= ($urandom_range(0, 499) == 0);
    io_csr_satp_changed      <= ($urandom_range(0, 499) == 0);
    io_csr_vsatp_changed     <= ($urandom_range(0, 499) == 0);
    io_csr_hgatp_changed     <= ($urandom_range(0, 499) == 0);
    io_csr_priv_virt_changed <= ($urandom_range(0, 499) == 0);
    if (cyc % 512 == 0) begin
      automatic int m = $urandom_range(0, 9);
      io_csr_hgatp_mode <= (m < 6) ? 4'h9 : (m < 9) ? 4'h8 : $urandom_range(0, 15);
      io_csr_mPBMTE <= $urandom_range(0, 1);
      io_csr_hPBMTE <= $urandom_range(0, 1);
    end
    if (cyc % 256 == 0) begin
      io_csr_mbmc_BME   <= $urandom_range(0, 1);
      io_csr_mbmc_CMODE <= $urandom_range(0, 2) == 0;
    end
    io_in_valid                 <= $urandom_range(0, 4) < 2;
    io_in_bits_req_info_vpn     <= pick_vpn();
    io_in_bits_req_info_s2xlate <= pick_s2x();
    io_in_bits_req_info_source  <= ($urandom_range(0, 4) == 0) ? 2'd2 : 2'($urandom_range(0, 1));
    io_in_bits_ppn              <= ($urandom_range(0, 3) == 0) ? {$urandom(), $urandom()} : {8'h0, 4'h0, 32'($urandom())};
    io_in_bits_bitmapCheck_jmp_bitmap_check <= $urandom_range(0, 5) == 0;
    io_in_bits_bitmapCheck_ptes_0 <= rand_pte(); io_in_bits_bitmapCheck_ptes_1 <= rand_pte();
    io_in_bits_bitmapCheck_ptes_2 <= rand_pte(); io_in_bits_bitmapCheck_ptes_3 <= rand_pte();
    io_in_bits_bitmapCheck_ptes_4 <= rand_pte(); io_in_bits_bitmapCheck_ptes_5 <= rand_pte();
    io_in_bits_bitmapCheck_ptes_6 <= rand_pte(); io_in_bits_bitmapCheck_ptes_7 <= rand_pte();
    {io_in_bits_bitmapCheck_cfs_7, io_in_bits_bitmapCheck_cfs_6, io_in_bits_bitmapCheck_cfs_5, io_in_bits_bitmapCheck_cfs_4,
     io_in_bits_bitmapCheck_cfs_3, io_in_bits_bitmapCheck_cfs_2, io_in_bits_bitmapCheck_cfs_1, io_in_bits_bitmapCheck_cfs_0} <= 8'($urandom());
    io_in_bits_bitmapCheck_hitway <= $urandom();
    io_out_ready       <= $urandom_range(0, 3) != 0;
    io_cache_ready     <= $urandom_range(0, 3) != 0;
    io_mem_req_ready   <= $urandom_range(0, 3) != 0;
    io_mem_resp_valid  <= $urandom_range(0, 3) == 0;
    io_mem_resp_bits_id <= $urandom_range(0, 7);
    io_mem_resp_bits_value <= {rand_pte(), rand_pte(), rand_pte(), rand_pte(), rand_pte(), rand_pte(), rand_pte(), rand_pte()};
    {io_mem_req_mask_5, io_mem_req_mask_4, io_mem_req_mask_3, io_mem_req_mask_2, io_mem_req_mask_1, io_mem_req_mask_0} <=
        {$urandom_range(0, 9) == 0, $urandom_range(0, 9) == 0, $urandom_range(0, 9) == 0,
         $urandom_range(0, 9) == 0, $urandom_range(0, 9) == 0, $urandom_range(0, 9) == 0};
    {io_mem_flush_latch_5, io_mem_flush_latch_4, io_mem_flush_latch_3, io_mem_flush_latch_2, io_mem_flush_latch_1, io_mem_flush_latch_0} <=
        {$urandom_range(0, 19) == 0, $urandom_range(0, 19) == 0, $urandom_range(0, 19) == 0,
         $urandom_range(0, 19) == 0, $urandom_range(0, 19) == 0, $urandom_range(0, 19) == 0};
    io_pmp_0_resp_ld   <= $urandom_range(0, 19) == 0;
    io_pmp_0_resp_mmio <= $urandom_range(0, 19) == 0;
    io_pmp_1_resp_ld   <= $urandom_range(0, 19) == 0;
    io_pmp_1_resp_mmio <= $urandom_range(0, 19) == 0;
    io_hptw_req_ready  <= $urandom_range(0, 3) != 0;
    io_hptw_resp_valid <= $urandom_range(0, 3) == 0;
    pick_hptw();
    io_hptw_resp_bits_id <= hptw_pick_id;
    io_hptw_resp_bits_h_resp_entry_tag   <= hptw_pick_tag;
    io_hptw_resp_bits_h_resp_entry_vmid  <= $urandom();
    io_hptw_resp_bits_h_resp_entry_n     <= $urandom_range(0, 3) == 0;
    io_hptw_resp_bits_h_resp_entry_pbmt  <= $urandom();
    io_hptw_resp_bits_h_resp_entry_ppn   <= {$urandom(), $urandom()};
    io_hptw_resp_bits_h_resp_entry_perm_d <= $urandom_range(0, 1);
    io_hptw_resp_bits_h_resp_entry_perm_a <= $urandom_range(0, 1);
    io_hptw_resp_bits_h_resp_entry_perm_g <= $urandom_range(0, 1);
    io_hptw_resp_bits_h_resp_entry_perm_u <= $urandom_range(0, 1);
    io_hptw_resp_bits_h_resp_entry_perm_x <= $urandom_range(0, 1);
    io_hptw_resp_bits_h_resp_entry_perm_w <= $urandom_range(0, 1);
    io_hptw_resp_bits_h_resp_entry_perm_r <= $urandom_range(0, 9) < 7;
    io_hptw_resp_bits_h_resp_entry_level <= $urandom();
    io_hptw_resp_bits_h_resp_gpf <= $urandom_range(0, 9) == 0;
    io_hptw_resp_bits_h_resp_gaf <= $urandom_range(0, 9) == 0;
    io_bitmap_req_ready  <= $urandom_range(0, 3) != 0;
    io_bitmap_resp_valid <= $urandom_range(0, 3) == 0;
    io_bitmap_resp_bits_cf <= $urandom_range(0, 1);
    {io_bitmap_resp_bits_cfs_7, io_bitmap_resp_bits_cfs_6, io_bitmap_resp_bits_cfs_5, io_bitmap_resp_bits_cfs_4,
     io_bitmap_resp_bits_cfs_3, io_bitmap_resp_bits_cfs_2, io_bitmap_resp_bits_cfs_1, io_bitmap_resp_bits_cfs_0} <= 8'($urandom());
    io_bitmap_resp_bits_id <= $urandom_range(0, 7);
    io_l0_way_info <= $urandom();
  endtask

  task automatic count_cov();
    cov_state[u_g.state_0]++; cov_state[u_g.state_1]++; cov_state[u_g.state_2]++;
    cov_state[u_g.state_3]++; cov_state[u_g.state_4]++; cov_state[u_g.state_5]++;
    if (g_io_in_ready && io_in_valid) begin cov_in++; cov_s2x[io_in_bits_req_info_s2xlate]++; end
    if (io_in_valid && !g_io_in_ready) cov_full++;
    if (g_io_out_valid && io_out_ready) cov_out++;
    if (g_io_cache_valid && io_cache_ready) cov_cache++;
    if (g_io_mem_req_valid && io_mem_req_ready) cov_mem++;
    if (g_io_hptw_req_valid) cov_hptw++;
    if (g_io_bitmap_req_valid && io_bitmap_req_ready) cov_bm++;
    if (io_mem_resp_valid && io_mem_resp_bits_id >= 6 && u_g.dup_wait_resp) cov_oob++;
  endtask

  initial clock = 0;
  always #5 clock = ~clock;

  initial begin
    if (!$value$plusargs("ncycles=%d", ncycles)) ncycles = 200000;
    for (int i = 0; i < 12; i++) cov_state[i] = 0;
    for (int i = 0; i < 4; i++) cov_s2x[i] = 0;
    for (int i = 0; i < 6; i++) begin
      vpn_pool[i] = {$urandom(), $urandom()};
      vpn_pool[i][37:3] = 35'(i % 3) * 35'h123456789 + 35'h7;   // 3 个扇区
    end
    reset = 1;
    io_sfence_valid = 0; io_csr_satp_changed = 0; io_csr_vsatp_changed = 0; io_csr_hgatp_changed = 0;
    io_csr_priv_virt_changed = 0; io_csr_hgatp_mode = 4'h9; io_csr_mbmc_BME = 0; io_csr_mbmc_CMODE = 0;
    io_csr_mPBMTE = 0; io_csr_hPBMTE = 0;
    io_in_valid = 0; io_in_bits_req_info_vpn = 0; io_in_bits_req_info_s2xlate = 0; io_in_bits_req_info_source = 0;
    io_in_bits_ppn = 0; io_in_bits_bitmapCheck_jmp_bitmap_check = 0;
    io_in_bits_bitmapCheck_ptes_0 = 0; io_in_bits_bitmapCheck_ptes_1 = 0; io_in_bits_bitmapCheck_ptes_2 = 0;
    io_in_bits_bitmapCheck_ptes_3 = 0; io_in_bits_bitmapCheck_ptes_4 = 0; io_in_bits_bitmapCheck_ptes_5 = 0;
    io_in_bits_bitmapCheck_ptes_6 = 0; io_in_bits_bitmapCheck_ptes_7 = 0;
    io_in_bits_bitmapCheck_cfs_0 = 0; io_in_bits_bitmapCheck_cfs_1 = 0; io_in_bits_bitmapCheck_cfs_2 = 0;
    io_in_bits_bitmapCheck_cfs_3 = 0; io_in_bits_bitmapCheck_cfs_4 = 0; io_in_bits_bitmapCheck_cfs_5 = 0;
    io_in_bits_bitmapCheck_cfs_6 = 0; io_in_bits_bitmapCheck_cfs_7 = 0; io_in_bits_bitmapCheck_hitway = 0;
    io_out_ready = 0; io_mem_req_ready = 0; io_mem_resp_valid = 0; io_mem_resp_bits_id = 0; io_mem_resp_bits_value = 0;
    io_mem_req_mask_0 = 0; io_mem_req_mask_1 = 0; io_mem_req_mask_2 = 0; io_mem_req_mask_3 = 0; io_mem_req_mask_4 = 0; io_mem_req_mask_5 = 0;
    io_mem_flush_latch_0 = 0; io_mem_flush_latch_1 = 0; io_mem_flush_latch_2 = 0; io_mem_flush_latch_3 = 0;
    io_mem_flush_latch_4 = 0; io_mem_flush_latch_5 = 0;
    io_cache_ready = 0; io_pmp_0_resp_ld = 0; io_pmp_0_resp_mmio = 0; io_pmp_1_resp_ld = 0; io_pmp_1_resp_mmio = 0;
    io_hptw_req_ready = 0; io_hptw_resp_valid = 0; io_hptw_resp_bits_id = 0;
    io_hptw_resp_bits_h_resp_entry_tag = 0; io_hptw_resp_bits_h_resp_entry_vmid = 0; io_hptw_resp_bits_h_resp_entry_n = 0;
    io_hptw_resp_bits_h_resp_entry_pbmt = 0; io_hptw_resp_bits_h_resp_entry_ppn = 0;
    io_hptw_resp_bits_h_resp_entry_perm_d = 0; io_hptw_resp_bits_h_resp_entry_perm_a = 0; io_hptw_resp_bits_h_resp_entry_perm_g = 0;
    io_hptw_resp_bits_h_resp_entry_perm_u = 0; io_hptw_resp_bits_h_resp_entry_perm_x = 0; io_hptw_resp_bits_h_resp_entry_perm_w = 0;
    io_hptw_resp_bits_h_resp_entry_perm_r = 0; io_hptw_resp_bits_h_resp_entry_level = 0;
    io_hptw_resp_bits_h_resp_gpf = 0; io_hptw_resp_bits_h_resp_gaf = 0;
    io_bitmap_req_ready = 0; io_bitmap_resp_valid = 0; io_bitmap_resp_bits_cf = 0;
    io_bitmap_resp_bits_cfs_0 = 0; io_bitmap_resp_bits_cfs_1 = 0; io_bitmap_resp_bits_cfs_2 = 0; io_bitmap_resp_bits_cfs_3 = 0;
    io_bitmap_resp_bits_cfs_4 = 0; io_bitmap_resp_bits_cfs_5 = 0; io_bitmap_resp_bits_cfs_6 = 0; io_bitmap_resp_bits_cfs_7 = 0;
    io_bitmap_resp_bits_id = 0; io_l0_way_info = 0;
    repeat (4) @(posedge clock);
    #1 reset = 0;
    for (cyc = 1; cyc <= ncycles; cyc++) begin
      @(negedge clock);
      compare_outputs(cyc);
      count_cov();
      drive_random();
    end
    $display("cov: in=%0d out=%0d cache=%0d mem=%0d hptw=%0d bm=%0d full=%0d oob_resp=%0d s2x=%0d/%0d/%0d/%0d",
             cov_in, cov_out, cov_cache, cov_mem, cov_hptw, cov_bm, cov_full, cov_oob,
             cov_s2x[0], cov_s2x[1], cov_s2x[2], cov_s2x[3]);
    $display("cov_state: %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d",
             cov_state[0], cov_state[1], cov_state[2], cov_state[3], cov_state[4], cov_state[5],
             cov_state[6], cov_state[7], cov_state[8], cov_state[9], cov_state[10], cov_state[11]);
    for (int i = 0; i < 12; i++) if (cov_state[i] == 0) begin $display("COVERAGE FLOOR NOT MET: state %0d", i); errors++; end
    for (int i = 0; i < 4; i++) if (cov_s2x[i] == 0) begin $display("COVERAGE FLOOR NOT MET: s2xlate %0d", i); errors++; end
    if (cov_in == 0 || cov_out == 0 || cov_cache == 0 || cov_mem == 0 || cov_hptw == 0 || cov_bm == 0 ||
        cov_full == 0 || cov_oob == 0) begin
      $display("COVERAGE FLOOR NOT MET");
      errors++;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
