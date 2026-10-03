// tb.sv —— Bitmap 的双例化逐拍差分 UT（verif/ut/Bitmap）。
//
// 双例化 golden Bitmap 与派生的 Bitmap_xs，同拍同激励，逐拍比全部 27 个输出
// （输出表由 scripts/gen_mmu5.py 从 golden 端口表逐根量出）。mem_arb 两侧各用自己的
// RRArbiterInit（golden 版 / rtl/common 重写版），cache_req_arb 两侧同一份 golden。
//
// 【激励设计——8 条目池要同时在飞、去重路径要真的撞上】
//   · 请求 bmppn 从 6 项池子取（四分之一仍全随机），level 0..3 / n 随机：同一个位图字
//     被多个条目同时要，才会走到"搭别人的访存"（dup_vec_wait / dup_req_fire / dup_wait_resp）。
//   · 访存响应 id：一半取 golden 里某个正在 mem_waiting 条目的 wait_id+8（真对上号），
//     一半全随机（8..15，含对不上号的）；数据 512 位全随机。
//   · cache 响应 order：七成取 golden 里某个正在 cache_resp 条目的编号，三成随机；hit 随机。
//   · io_mem_req_mask 每根 1/8 拍；PMP ld/mmio 各 1/16；wakeup_ready 四分之三；
//     io_resp_ready 十分之九（Chisel 注释说"always true"，这里仍随机压一压）。
//   · hptw_bypassed 四分之一（其余走 wakeup），BMA 每 1024 拍换一次，flush 五根各 1/500。
//
// 【判别力自证】覆盖下限：req fire / resp fire / cache 命中回应 / 访存请求 / 访存响应对号 /
//   入队即搭车（enq→waiting）/ 入队即拿到数据（enq→mem_out）/ PMP 失败 / wakeup fire /
//   refill / 满池拒收，都必须 > 0，否则 tb 自判 FAIL。
//   ★覆盖计数在 posedge 采（NBA 更新前）★：第一版在 negedge 采，看到的是"状态已更新、
//   输入未换"的错位值，order_match 只数到 6（真值 5000+）——量具先错、数字看着还合理。
//
// 【判别力自证——mutant（不进库，20000 拍 seed=1，每个都 diff 确认变异进了 RTL）】
//   M1 去重比 ppn[35:6] 而不是 golden 的 [35:5]        -> cyc 48 io_mem_req_bits_addr/id 失配，抓到
//   M2 cache 命中的 cf 用扇区下标 [5:3] 而不是 [2:0]    -> cyc 14 io_resp_bits_cf 失配，抓到
//   M3 入队搭车时 wait_id 记自己而不是被搭者            -> cyc 506 io_resp_valid 失配，抓到
//   M4 去掉 wakeup_stall（wakeup 不压 resp）             -> cyc 168 io_resp_valid 失配，抓到
//   M5 PMP 失败仍去查 cache                              -> cyc 18 io_resp_valid/cf 失配，抓到
//
// 【实测】两档 initreg × 3 seed × 200000 拍，每拍 30 次比较，全部 errors=0：
//   档  seed  checks    req    resp   cache_hit mem_req resp_match enq_wait enq_memout pmp_af wakeup
//   ir0   1   6000000   77505  66081  29939     29250   26937      562      57         9073   6901
//   ir0   7   6000000   77949  65731  29862     28947   26479      575      67         9303   6853
//   ir0  42   6000000   78133  66137  30094     29041   26697      558      59         9247   6795
//   ir1  1/7/42 与 ir0 逐个相同（本模块不复位寄存器都在被读之前先被写，两档看不出差别——
//   这一条只证明"无 X 依赖失配"，证明不了复位域，复位域靠上面 §复位域 与 golden 的结构对照）。
`timescale 1ns/1ps
module tb;
  int errors = 0;
  int checks = 0;
  int ncycles;
  int cov_req = 0, cov_resp = 0, cov_cache_hit = 0, cov_mem_req = 0, cov_mem_resp_match = 0;
  int cov_enq_wait = 0, cov_enq_memout = 0, cov_pmp_af = 0, cov_wakeup = 0, cov_refill = 0, cov_full = 0;
  int cov_cm_wait = 0;

  // BEGIN GENERATED(harness) —— 由 gen_mmu5.py 生成：信号声明 / 双例化 / 输出逐拍比对
  logic clock, reset;
  logic io_sfence_valid;
  logic io_csr_satp_changed;
  logic io_csr_vsatp_changed;
  logic io_csr_hgatp_changed;
  logic [57:0] io_csr_mbmc_BMA;
  logic io_csr_priv_virt_changed;
  logic io_mem_req_ready;
  logic io_mem_resp_valid;
  logic [3:0] io_mem_resp_bits_id;
  logic [511:0] io_mem_resp_bits_value;
  logic io_mem_req_mask_0;
  logic io_mem_req_mask_1;
  logic io_mem_req_mask_2;
  logic io_mem_req_mask_3;
  logic io_mem_req_mask_4;
  logic io_mem_req_mask_5;
  logic io_mem_req_mask_6;
  logic io_mem_req_mask_7;
  logic io_req_valid;
  logic [35:0] io_req_bits_bmppn;
  logic [2:0] io_req_bits_id;
  logic [37:0] io_req_bits_vpn;
  logic [1:0] io_req_bits_level;
  logic [3:0] io_req_bits_way_info;
  logic io_req_bits_hptw_bypassed;
  logic [1:0] io_req_bits_s2xlate;
  logic io_req_bits_n;
  logic io_resp_ready;
  logic io_pmp_resp_ld;
  logic io_pmp_resp_mmio;
  logic io_wakeup_ready;
  logic io_cache_req_ready;
  logic io_cache_resp_valid;
  logic io_cache_resp_bits_hit;
  logic io_cache_resp_bits_cfs_0;
  logic io_cache_resp_bits_cfs_1;
  logic io_cache_resp_bits_cfs_2;
  logic io_cache_resp_bits_cfs_3;
  logic io_cache_resp_bits_cfs_4;
  logic io_cache_resp_bits_cfs_5;
  logic io_cache_resp_bits_cfs_6;
  logic io_cache_resp_bits_cfs_7;
  logic [7:0] io_cache_resp_bits_order;
  logic g_io_mem_req_valid, i_io_mem_req_valid;
  logic [47:0] g_io_mem_req_bits_addr, i_io_mem_req_bits_addr;
  logic [3:0] g_io_mem_req_bits_id, i_io_mem_req_bits_id;
  logic g_io_req_ready, i_io_req_ready;
  logic g_io_resp_valid, i_io_resp_valid;
  logic g_io_resp_bits_cf, i_io_resp_bits_cf;
  logic g_io_resp_bits_cfs_0, i_io_resp_bits_cfs_0;
  logic g_io_resp_bits_cfs_1, i_io_resp_bits_cfs_1;
  logic g_io_resp_bits_cfs_2, i_io_resp_bits_cfs_2;
  logic g_io_resp_bits_cfs_3, i_io_resp_bits_cfs_3;
  logic g_io_resp_bits_cfs_4, i_io_resp_bits_cfs_4;
  logic g_io_resp_bits_cfs_5, i_io_resp_bits_cfs_5;
  logic g_io_resp_bits_cfs_6, i_io_resp_bits_cfs_6;
  logic g_io_resp_bits_cfs_7, i_io_resp_bits_cfs_7;
  logic [2:0] g_io_resp_bits_id, i_io_resp_bits_id;
  logic [47:0] g_io_pmp_req_bits_addr, i_io_pmp_req_bits_addr;
  logic g_io_wakeup_valid, i_io_wakeup_valid;
  logic [5:0] g_io_wakeup_bits_setIndex, i_io_wakeup_bits_setIndex;
  logic [37:0] g_io_wakeup_bits_tag, i_io_wakeup_bits_tag;
  logic [3:0] g_io_wakeup_bits_way_info, i_io_wakeup_bits_way_info;
  logic [2:0] g_io_wakeup_bits_pte_index, i_io_wakeup_bits_pte_index;
  logic g_io_wakeup_bits_check_success, i_io_wakeup_bits_check_success;
  logic [1:0] g_io_wakeup_bits_s2xlate, i_io_wakeup_bits_s2xlate;
  logic g_io_cache_req_valid, i_io_cache_req_valid;
  logic [7:0] g_io_cache_req_bits_order, i_io_cache_req_bits_order;
  logic [35:0] g_io_cache_req_bits_tag, i_io_cache_req_bits_tag;
  logic g_io_cache_resp_ready, i_io_cache_resp_ready;
  logic g_io_refill_valid, i_io_refill_valid;
  logic [35:0] g_io_refill_bits_tag, i_io_refill_bits_tag;
  logic [63:0] g_io_refill_bits_data, i_io_refill_bits_data;
  Bitmap u_g (
    .clock(clock), .reset(reset),
    .io_sfence_valid              (io_sfence_valid),
    .io_csr_satp_changed          (io_csr_satp_changed),
    .io_csr_vsatp_changed         (io_csr_vsatp_changed),
    .io_csr_hgatp_changed         (io_csr_hgatp_changed),
    .io_csr_mbmc_BMA              (io_csr_mbmc_BMA),
    .io_csr_priv_virt_changed     (io_csr_priv_virt_changed),
    .io_mem_req_ready             (io_mem_req_ready),
    .io_mem_req_valid             (g_io_mem_req_valid),
    .io_mem_req_bits_addr         (g_io_mem_req_bits_addr),
    .io_mem_req_bits_id           (g_io_mem_req_bits_id),
    .io_mem_resp_valid            (io_mem_resp_valid),
    .io_mem_resp_bits_id          (io_mem_resp_bits_id),
    .io_mem_resp_bits_value       (io_mem_resp_bits_value),
    .io_mem_req_mask_0            (io_mem_req_mask_0),
    .io_mem_req_mask_1            (io_mem_req_mask_1),
    .io_mem_req_mask_2            (io_mem_req_mask_2),
    .io_mem_req_mask_3            (io_mem_req_mask_3),
    .io_mem_req_mask_4            (io_mem_req_mask_4),
    .io_mem_req_mask_5            (io_mem_req_mask_5),
    .io_mem_req_mask_6            (io_mem_req_mask_6),
    .io_mem_req_mask_7            (io_mem_req_mask_7),
    .io_req_ready                 (g_io_req_ready),
    .io_req_valid                 (io_req_valid),
    .io_req_bits_bmppn            (io_req_bits_bmppn),
    .io_req_bits_id               (io_req_bits_id),
    .io_req_bits_vpn              (io_req_bits_vpn),
    .io_req_bits_level            (io_req_bits_level),
    .io_req_bits_way_info         (io_req_bits_way_info),
    .io_req_bits_hptw_bypassed    (io_req_bits_hptw_bypassed),
    .io_req_bits_s2xlate          (io_req_bits_s2xlate),
    .io_req_bits_n                (io_req_bits_n),
    .io_resp_ready                (io_resp_ready),
    .io_resp_valid                (g_io_resp_valid),
    .io_resp_bits_cf              (g_io_resp_bits_cf),
    .io_resp_bits_cfs_0           (g_io_resp_bits_cfs_0),
    .io_resp_bits_cfs_1           (g_io_resp_bits_cfs_1),
    .io_resp_bits_cfs_2           (g_io_resp_bits_cfs_2),
    .io_resp_bits_cfs_3           (g_io_resp_bits_cfs_3),
    .io_resp_bits_cfs_4           (g_io_resp_bits_cfs_4),
    .io_resp_bits_cfs_5           (g_io_resp_bits_cfs_5),
    .io_resp_bits_cfs_6           (g_io_resp_bits_cfs_6),
    .io_resp_bits_cfs_7           (g_io_resp_bits_cfs_7),
    .io_resp_bits_id              (g_io_resp_bits_id),
    .io_pmp_req_bits_addr         (g_io_pmp_req_bits_addr),
    .io_pmp_resp_ld               (io_pmp_resp_ld),
    .io_pmp_resp_mmio             (io_pmp_resp_mmio),
    .io_wakeup_ready              (io_wakeup_ready),
    .io_wakeup_valid              (g_io_wakeup_valid),
    .io_wakeup_bits_setIndex      (g_io_wakeup_bits_setIndex),
    .io_wakeup_bits_tag           (g_io_wakeup_bits_tag),
    .io_wakeup_bits_way_info      (g_io_wakeup_bits_way_info),
    .io_wakeup_bits_pte_index     (g_io_wakeup_bits_pte_index),
    .io_wakeup_bits_check_success (g_io_wakeup_bits_check_success),
    .io_wakeup_bits_s2xlate       (g_io_wakeup_bits_s2xlate),
    .io_cache_req_ready           (io_cache_req_ready),
    .io_cache_req_valid           (g_io_cache_req_valid),
    .io_cache_req_bits_order      (g_io_cache_req_bits_order),
    .io_cache_req_bits_tag        (g_io_cache_req_bits_tag),
    .io_cache_resp_ready          (g_io_cache_resp_ready),
    .io_cache_resp_valid          (io_cache_resp_valid),
    .io_cache_resp_bits_hit       (io_cache_resp_bits_hit),
    .io_cache_resp_bits_cfs_0     (io_cache_resp_bits_cfs_0),
    .io_cache_resp_bits_cfs_1     (io_cache_resp_bits_cfs_1),
    .io_cache_resp_bits_cfs_2     (io_cache_resp_bits_cfs_2),
    .io_cache_resp_bits_cfs_3     (io_cache_resp_bits_cfs_3),
    .io_cache_resp_bits_cfs_4     (io_cache_resp_bits_cfs_4),
    .io_cache_resp_bits_cfs_5     (io_cache_resp_bits_cfs_5),
    .io_cache_resp_bits_cfs_6     (io_cache_resp_bits_cfs_6),
    .io_cache_resp_bits_cfs_7     (io_cache_resp_bits_cfs_7),
    .io_cache_resp_bits_order     (io_cache_resp_bits_order),
    .io_refill_valid              (g_io_refill_valid),
    .io_refill_bits_tag           (g_io_refill_bits_tag),
    .io_refill_bits_data          (g_io_refill_bits_data)
  );
  Bitmap_xs u_i (
    .clock(clock), .reset(reset),
    .io_sfence_valid              (io_sfence_valid),
    .io_csr_satp_changed          (io_csr_satp_changed),
    .io_csr_vsatp_changed         (io_csr_vsatp_changed),
    .io_csr_hgatp_changed         (io_csr_hgatp_changed),
    .io_csr_mbmc_BMA              (io_csr_mbmc_BMA),
    .io_csr_priv_virt_changed     (io_csr_priv_virt_changed),
    .io_mem_req_ready             (io_mem_req_ready),
    .io_mem_req_valid             (i_io_mem_req_valid),
    .io_mem_req_bits_addr         (i_io_mem_req_bits_addr),
    .io_mem_req_bits_id           (i_io_mem_req_bits_id),
    .io_mem_resp_valid            (io_mem_resp_valid),
    .io_mem_resp_bits_id          (io_mem_resp_bits_id),
    .io_mem_resp_bits_value       (io_mem_resp_bits_value),
    .io_mem_req_mask_0            (io_mem_req_mask_0),
    .io_mem_req_mask_1            (io_mem_req_mask_1),
    .io_mem_req_mask_2            (io_mem_req_mask_2),
    .io_mem_req_mask_3            (io_mem_req_mask_3),
    .io_mem_req_mask_4            (io_mem_req_mask_4),
    .io_mem_req_mask_5            (io_mem_req_mask_5),
    .io_mem_req_mask_6            (io_mem_req_mask_6),
    .io_mem_req_mask_7            (io_mem_req_mask_7),
    .io_req_ready                 (i_io_req_ready),
    .io_req_valid                 (io_req_valid),
    .io_req_bits_bmppn            (io_req_bits_bmppn),
    .io_req_bits_id               (io_req_bits_id),
    .io_req_bits_vpn              (io_req_bits_vpn),
    .io_req_bits_level            (io_req_bits_level),
    .io_req_bits_way_info         (io_req_bits_way_info),
    .io_req_bits_hptw_bypassed    (io_req_bits_hptw_bypassed),
    .io_req_bits_s2xlate          (io_req_bits_s2xlate),
    .io_req_bits_n                (io_req_bits_n),
    .io_resp_ready                (io_resp_ready),
    .io_resp_valid                (i_io_resp_valid),
    .io_resp_bits_cf              (i_io_resp_bits_cf),
    .io_resp_bits_cfs_0           (i_io_resp_bits_cfs_0),
    .io_resp_bits_cfs_1           (i_io_resp_bits_cfs_1),
    .io_resp_bits_cfs_2           (i_io_resp_bits_cfs_2),
    .io_resp_bits_cfs_3           (i_io_resp_bits_cfs_3),
    .io_resp_bits_cfs_4           (i_io_resp_bits_cfs_4),
    .io_resp_bits_cfs_5           (i_io_resp_bits_cfs_5),
    .io_resp_bits_cfs_6           (i_io_resp_bits_cfs_6),
    .io_resp_bits_cfs_7           (i_io_resp_bits_cfs_7),
    .io_resp_bits_id              (i_io_resp_bits_id),
    .io_pmp_req_bits_addr         (i_io_pmp_req_bits_addr),
    .io_pmp_resp_ld               (io_pmp_resp_ld),
    .io_pmp_resp_mmio             (io_pmp_resp_mmio),
    .io_wakeup_ready              (io_wakeup_ready),
    .io_wakeup_valid              (i_io_wakeup_valid),
    .io_wakeup_bits_setIndex      (i_io_wakeup_bits_setIndex),
    .io_wakeup_bits_tag           (i_io_wakeup_bits_tag),
    .io_wakeup_bits_way_info      (i_io_wakeup_bits_way_info),
    .io_wakeup_bits_pte_index     (i_io_wakeup_bits_pte_index),
    .io_wakeup_bits_check_success (i_io_wakeup_bits_check_success),
    .io_wakeup_bits_s2xlate       (i_io_wakeup_bits_s2xlate),
    .io_cache_req_ready           (io_cache_req_ready),
    .io_cache_req_valid           (i_io_cache_req_valid),
    .io_cache_req_bits_order      (i_io_cache_req_bits_order),
    .io_cache_req_bits_tag        (i_io_cache_req_bits_tag),
    .io_cache_resp_ready          (i_io_cache_resp_ready),
    .io_cache_resp_valid          (io_cache_resp_valid),
    .io_cache_resp_bits_hit       (io_cache_resp_bits_hit),
    .io_cache_resp_bits_cfs_0     (io_cache_resp_bits_cfs_0),
    .io_cache_resp_bits_cfs_1     (io_cache_resp_bits_cfs_1),
    .io_cache_resp_bits_cfs_2     (io_cache_resp_bits_cfs_2),
    .io_cache_resp_bits_cfs_3     (io_cache_resp_bits_cfs_3),
    .io_cache_resp_bits_cfs_4     (io_cache_resp_bits_cfs_4),
    .io_cache_resp_bits_cfs_5     (io_cache_resp_bits_cfs_5),
    .io_cache_resp_bits_cfs_6     (io_cache_resp_bits_cfs_6),
    .io_cache_resp_bits_cfs_7     (io_cache_resp_bits_cfs_7),
    .io_cache_resp_bits_order     (io_cache_resp_bits_order),
    .io_refill_valid              (i_io_refill_valid),
    .io_refill_bits_tag           (i_io_refill_bits_tag),
    .io_refill_bits_data          (i_io_refill_bits_data)
  );
  // 逐拍比全部 30 个输出（golden 端口表逐根量出，不手抄）
  task automatic compare_outputs(input int cyc);
    checks++; if (g_io_mem_req_valid !== i_io_mem_req_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_req_valid g=%h i=%h", cyc, g_io_mem_req_valid, i_io_mem_req_valid); end
    checks++; if (g_io_mem_req_bits_addr !== i_io_mem_req_bits_addr) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_req_bits_addr g=%h i=%h", cyc, g_io_mem_req_bits_addr, i_io_mem_req_bits_addr); end
    checks++; if (g_io_mem_req_bits_id !== i_io_mem_req_bits_id) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_mem_req_bits_id g=%h i=%h", cyc, g_io_mem_req_bits_id, i_io_mem_req_bits_id); end
    checks++; if (g_io_req_ready !== i_io_req_ready) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_req_ready g=%h i=%h", cyc, g_io_req_ready, i_io_req_ready); end
    checks++; if (g_io_resp_valid !== i_io_resp_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_valid g=%h i=%h", cyc, g_io_resp_valid, i_io_resp_valid); end
    checks++; if (g_io_resp_bits_cf !== i_io_resp_bits_cf) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_cf g=%h i=%h", cyc, g_io_resp_bits_cf, i_io_resp_bits_cf); end
    checks++; if (g_io_resp_bits_cfs_0 !== i_io_resp_bits_cfs_0) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_cfs_0 g=%h i=%h", cyc, g_io_resp_bits_cfs_0, i_io_resp_bits_cfs_0); end
    checks++; if (g_io_resp_bits_cfs_1 !== i_io_resp_bits_cfs_1) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_cfs_1 g=%h i=%h", cyc, g_io_resp_bits_cfs_1, i_io_resp_bits_cfs_1); end
    checks++; if (g_io_resp_bits_cfs_2 !== i_io_resp_bits_cfs_2) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_cfs_2 g=%h i=%h", cyc, g_io_resp_bits_cfs_2, i_io_resp_bits_cfs_2); end
    checks++; if (g_io_resp_bits_cfs_3 !== i_io_resp_bits_cfs_3) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_cfs_3 g=%h i=%h", cyc, g_io_resp_bits_cfs_3, i_io_resp_bits_cfs_3); end
    checks++; if (g_io_resp_bits_cfs_4 !== i_io_resp_bits_cfs_4) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_cfs_4 g=%h i=%h", cyc, g_io_resp_bits_cfs_4, i_io_resp_bits_cfs_4); end
    checks++; if (g_io_resp_bits_cfs_5 !== i_io_resp_bits_cfs_5) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_cfs_5 g=%h i=%h", cyc, g_io_resp_bits_cfs_5, i_io_resp_bits_cfs_5); end
    checks++; if (g_io_resp_bits_cfs_6 !== i_io_resp_bits_cfs_6) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_cfs_6 g=%h i=%h", cyc, g_io_resp_bits_cfs_6, i_io_resp_bits_cfs_6); end
    checks++; if (g_io_resp_bits_cfs_7 !== i_io_resp_bits_cfs_7) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_cfs_7 g=%h i=%h", cyc, g_io_resp_bits_cfs_7, i_io_resp_bits_cfs_7); end
    checks++; if (g_io_resp_bits_id !== i_io_resp_bits_id) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_id g=%h i=%h", cyc, g_io_resp_bits_id, i_io_resp_bits_id); end
    checks++; if (g_io_pmp_req_bits_addr !== i_io_pmp_req_bits_addr) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_pmp_req_bits_addr g=%h i=%h", cyc, g_io_pmp_req_bits_addr, i_io_pmp_req_bits_addr); end
    checks++; if (g_io_wakeup_valid !== i_io_wakeup_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_wakeup_valid g=%h i=%h", cyc, g_io_wakeup_valid, i_io_wakeup_valid); end
    checks++; if (g_io_wakeup_bits_setIndex !== i_io_wakeup_bits_setIndex) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_wakeup_bits_setIndex g=%h i=%h", cyc, g_io_wakeup_bits_setIndex, i_io_wakeup_bits_setIndex); end
    checks++; if (g_io_wakeup_bits_tag !== i_io_wakeup_bits_tag) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_wakeup_bits_tag g=%h i=%h", cyc, g_io_wakeup_bits_tag, i_io_wakeup_bits_tag); end
    checks++; if (g_io_wakeup_bits_way_info !== i_io_wakeup_bits_way_info) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_wakeup_bits_way_info g=%h i=%h", cyc, g_io_wakeup_bits_way_info, i_io_wakeup_bits_way_info); end
    checks++; if (g_io_wakeup_bits_pte_index !== i_io_wakeup_bits_pte_index) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_wakeup_bits_pte_index g=%h i=%h", cyc, g_io_wakeup_bits_pte_index, i_io_wakeup_bits_pte_index); end
    checks++; if (g_io_wakeup_bits_check_success !== i_io_wakeup_bits_check_success) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_wakeup_bits_check_success g=%h i=%h", cyc, g_io_wakeup_bits_check_success, i_io_wakeup_bits_check_success); end
    checks++; if (g_io_wakeup_bits_s2xlate !== i_io_wakeup_bits_s2xlate) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_wakeup_bits_s2xlate g=%h i=%h", cyc, g_io_wakeup_bits_s2xlate, i_io_wakeup_bits_s2xlate); end
    checks++; if (g_io_cache_req_valid !== i_io_cache_req_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_cache_req_valid g=%h i=%h", cyc, g_io_cache_req_valid, i_io_cache_req_valid); end
    checks++; if (g_io_cache_req_bits_order !== i_io_cache_req_bits_order) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_cache_req_bits_order g=%h i=%h", cyc, g_io_cache_req_bits_order, i_io_cache_req_bits_order); end
    checks++; if (g_io_cache_req_bits_tag !== i_io_cache_req_bits_tag) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_cache_req_bits_tag g=%h i=%h", cyc, g_io_cache_req_bits_tag, i_io_cache_req_bits_tag); end
    checks++; if (g_io_cache_resp_ready !== i_io_cache_resp_ready) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_cache_resp_ready g=%h i=%h", cyc, g_io_cache_resp_ready, i_io_cache_resp_ready); end
    checks++; if (g_io_refill_valid !== i_io_refill_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_refill_valid g=%h i=%h", cyc, g_io_refill_valid, i_io_refill_valid); end
    checks++; if (g_io_refill_bits_tag !== i_io_refill_bits_tag) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_refill_bits_tag g=%h i=%h", cyc, g_io_refill_bits_tag, i_io_refill_bits_tag); end
    checks++; if (g_io_refill_bits_data !== i_io_refill_bits_data) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_refill_bits_data g=%h i=%h", cyc, g_io_refill_bits_data, i_io_refill_bits_data); end
  endtask
  // END GENERATED(harness)

  logic [35:0] ppn_pool [6];
  int cyc = 0;

  function automatic logic [35:0] pick_ppn();
    if ($urandom_range(0, 3) == 0) return {$urandom(), $urandom()};
    return ppn_pool[$urandom_range(0, 5)];
  endfunction

  // 从 golden 里挑一个处于某状态的条目（没有就返回 -1）
  function automatic int pick_entry_in_state(input logic [2:0] st);
    int cands [8];
    int n = 0;
    logic [2:0] s;
    for (int i = 0; i < 8; i++) begin
      case (i)
        0: s = u_g.state_0; 1: s = u_g.state_1; 2: s = u_g.state_2; 3: s = u_g.state_3;
        4: s = u_g.state_4; 5: s = u_g.state_5; 6: s = u_g.state_6; default: s = u_g.state_7;
      endcase
      if (s == st) begin cands[n] = i; n++; end
    end
    if (n == 0) return -1;
    return cands[$urandom_range(0, n - 1)];
  endfunction

  function automatic logic [2:0] wait_id_of(input int i);
    case (i)
      0: return u_g.entries_0_wait_id; 1: return u_g.entries_1_wait_id;
      2: return u_g.entries_2_wait_id; 3: return u_g.entries_3_wait_id;
      4: return u_g.entries_4_wait_id; 5: return u_g.entries_5_wait_id;
      6: return u_g.entries_6_wait_id; default: return u_g.entries_7_wait_id;
    endcase
  endfunction

  task automatic drive_random();
    int e;
    io_sfence_valid          <= ($urandom_range(0, 499) == 0);
    io_csr_satp_changed      <= ($urandom_range(0, 499) == 0);
    io_csr_vsatp_changed     <= ($urandom_range(0, 499) == 0);
    io_csr_hgatp_changed     <= ($urandom_range(0, 499) == 0);
    io_csr_priv_virt_changed <= ($urandom_range(0, 499) == 0);
    if (cyc % 1024 == 0) io_csr_mbmc_BMA <= {$urandom(), $urandom()};
    io_req_valid            <= $urandom_range(0, 1);
    io_req_bits_bmppn       <= pick_ppn();
    io_req_bits_id          <= $urandom();
    io_req_bits_vpn         <= {$urandom(), $urandom()};
    io_req_bits_level       <= $urandom();
    io_req_bits_way_info    <= $urandom();
    io_req_bits_hptw_bypassed <= $urandom_range(0, 3) == 0;
    io_req_bits_s2xlate     <= $urandom();
    io_req_bits_n           <= $urandom_range(0, 1);
    io_resp_ready           <= $urandom_range(0, 9) != 0;
    io_mem_req_ready        <= $urandom_range(0, 2) != 0;
    io_mem_req_mask_0 <= $urandom_range(0, 7) == 0; io_mem_req_mask_1 <= $urandom_range(0, 7) == 0;
    io_mem_req_mask_2 <= $urandom_range(0, 7) == 0; io_mem_req_mask_3 <= $urandom_range(0, 7) == 0;
    io_mem_req_mask_4 <= $urandom_range(0, 7) == 0; io_mem_req_mask_5 <= $urandom_range(0, 7) == 0;
    io_mem_req_mask_6 <= $urandom_range(0, 7) == 0; io_mem_req_mask_7 <= $urandom_range(0, 7) == 0;
    io_mem_resp_valid       <= $urandom_range(0, 2) == 0;
    e = pick_entry_in_state(3'd5);
    if (e >= 0 && $urandom_range(0, 1)) io_mem_resp_bits_id <= {1'b1, wait_id_of(e)};
    else io_mem_resp_bits_id <= {1'b1, 3'($urandom())};
    for (int k = 0; k < 16; k++) io_mem_resp_bits_value[k*32 +: 32] <= $urandom();
    io_pmp_resp_ld          <= $urandom_range(0, 15) == 0;
    io_pmp_resp_mmio        <= $urandom_range(0, 15) == 0;
    io_wakeup_ready         <= $urandom_range(0, 3) != 0;
    io_cache_req_ready      <= $urandom_range(0, 2) != 0;
    io_cache_resp_valid     <= $urandom_range(0, 1);
    e = pick_entry_in_state(3'd3);
    if (e >= 0 && $urandom_range(0, 9) < 7) io_cache_resp_bits_order <= 8'(e);
    else io_cache_resp_bits_order <= $urandom();
    io_cache_resp_bits_hit  <= $urandom_range(0, 1);
    {io_cache_resp_bits_cfs_7, io_cache_resp_bits_cfs_6, io_cache_resp_bits_cfs_5, io_cache_resp_bits_cfs_4,
     io_cache_resp_bits_cfs_3, io_cache_resp_bits_cfs_2, io_cache_resp_bits_cfs_1, io_cache_resp_bits_cfs_0} <= 8'($urandom());
  endtask

  task automatic count_cov();
    if (g_io_req_ready && io_req_valid) begin
      cov_req++;
      if (u_g.dup_wait_resp) cov_enq_memout++;
      else if (u_g.to_wait) cov_enq_wait++;
    end
    if (!g_io_req_ready) cov_full++;
    if (g_io_resp_valid && io_resp_ready) cov_resp++;
    if (u_g.hit) cov_cache_hit++;
    if (g_io_mem_req_valid && io_mem_req_ready) cov_mem_req++;
    if (u_g._GEN_93 | u_g._GEN_94 | u_g._GEN_95 | u_g._GEN_96 | u_g._GEN_97 | u_g._GEN_98 | u_g._GEN_99 | u_g._GEN_100)
      cov_mem_resp_match++;
    if (u_g.need_addr_check && (io_pmp_resp_ld || io_pmp_resp_mmio)) cov_pmp_af++;
    if (g_io_wakeup_valid && io_wakeup_ready) cov_wakeup++;
    if (g_io_refill_valid) cov_refill++;
    if (u_g._GEN_1 && !u_g.hit && (u_g.cm_to_wait | u_g.cm_to_wait_1 | u_g.cm_to_wait_2 | u_g.cm_to_wait_3 |
        u_g.cm_to_wait_4 | u_g.cm_to_wait_5 | u_g.cm_to_wait_6 | u_g.cm_to_wait_7)) cov_cm_wait++;
  endtask

  initial clock = 0;
  always #5 clock = ~clock;
  // ★覆盖计数在 posedge 采（NBA 更新之前）：此时组合信号 = f(旧状态, 本拍输入)，正是
  //  握手真正发生的那一组值；在 negedge 采会看到"状态已更新、输入未换"的错位值，
  //  fire 类事件会被系统性漏数（实测 order_match 从 6 变成 5000+）。★
  always @(posedge clock) if (!reset) count_cov();

  bit arm_wakeup = 1'b0, arm_pmp = 1'b0;
  initial begin
    if (!$value$plusargs("ncycles=%d", ncycles)) ncycles = 200000;
    for (int i = 0; i < 6; i++) ppn_pool[i] = {$urandom(), $urandom()};
    reset = 1;
    io_sfence_valid = 0; io_csr_satp_changed = 0; io_csr_vsatp_changed = 0; io_csr_hgatp_changed = 0;
    io_csr_mbmc_BMA = 0; io_csr_priv_virt_changed = 0;
    io_mem_req_ready = 0; io_mem_resp_valid = 0; io_mem_resp_bits_id = 0; io_mem_resp_bits_value = 0;
    io_mem_req_mask_0 = 0; io_mem_req_mask_1 = 0; io_mem_req_mask_2 = 0; io_mem_req_mask_3 = 0;
    io_mem_req_mask_4 = 0; io_mem_req_mask_5 = 0; io_mem_req_mask_6 = 0; io_mem_req_mask_7 = 0;
    io_req_valid = 0; io_req_bits_bmppn = 0; io_req_bits_id = 0; io_req_bits_vpn = 0; io_req_bits_level = 0;
    io_req_bits_way_info = 0; io_req_bits_hptw_bypassed = 0; io_req_bits_s2xlate = 0; io_req_bits_n = 0;
    io_resp_ready = 0; io_pmp_resp_ld = 0; io_pmp_resp_mmio = 0; io_wakeup_ready = 0;
    io_cache_req_ready = 0; io_cache_resp_valid = 0; io_cache_resp_bits_hit = 0;
    io_cache_resp_bits_cfs_0 = 0; io_cache_resp_bits_cfs_1 = 0; io_cache_resp_bits_cfs_2 = 0; io_cache_resp_bits_cfs_3 = 0;
    io_cache_resp_bits_cfs_4 = 0; io_cache_resp_bits_cfs_5 = 0; io_cache_resp_bits_cfs_6 = 0; io_cache_resp_bits_cfs_7 = 0;
    io_cache_resp_bits_order = 0;
    repeat (4) @(posedge clock);
    #1 reset = 0;
    // wakeup.bits.* 与 pmp.req.bits.addr 是不复位的寄存器，各自第一次写入之前两侧初值不同：
    // golden 出现过 wakeup.valid、且 req 握手过一次之后再开始比（armed）。
    for (cyc = 1; cyc <= ncycles; cyc++) begin
      @(negedge clock);
      if (arm_wakeup && arm_pmp) compare_outputs(cyc);
      if (g_io_wakeup_valid) arm_wakeup = 1'b1;
      if (io_req_valid && g_io_req_ready) arm_pmp = 1'b1;   // pmp.req.bits.addr 在 req 握手时写入
      drive_random();
    end
    $display("cov: req=%0d resp=%0d cache_hit=%0d mem_req=%0d mem_resp_match=%0d enq_wait=%0d enq_memout=%0d cm_wait=%0d pmp_af=%0d wakeup=%0d refill=%0d full=%0d",
             cov_req, cov_resp, cov_cache_hit, cov_mem_req, cov_mem_resp_match, cov_enq_wait, cov_enq_memout,
             cov_cm_wait, cov_pmp_af, cov_wakeup, cov_refill, cov_full);
    if (cov_req == 0 || cov_resp == 0 || cov_cache_hit == 0 || cov_mem_req == 0 || cov_mem_resp_match == 0 ||
        cov_enq_wait == 0 || cov_enq_memout == 0 || cov_cm_wait == 0 || cov_pmp_af == 0 || cov_wakeup == 0 ||
        cov_refill == 0 || cov_full == 0) begin
      $display("COVERAGE FLOOR NOT MET");
      errors++;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
