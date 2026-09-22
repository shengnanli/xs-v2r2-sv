// tb.sv —— BitmapCache 的双例化逐拍差分 UT（verif/ut/BitmapCache）。
//
// 双例化 golden BitmapCache 与派生的 BitmapCache_xs，同拍同激励，逐拍比全部 13 个输出
// （输出表由 scripts/gen_mmu5.py 从 golden 端口表逐根量出）。两侧的 SRAM/MBIST/ClockGate
// 子模块都是同一份 golden 定义（见 Makefile），所以比的是本层的流水/命中/替换/有效位逻辑。
//
// 【激励设计】
//   · 请求与回填的 tag 都从 8 项池子里取（四分之一仍全随机）：全随机时回填的行下一拍就再
//     也匹配不上，命中计数恒 0。池子里的 tag 组号有意集中在少数几组，让同组 4 路填满、
//     逼出 PLRU 受害者选择（而不是永远走"填空路"）。
//   · io_refill_valid 约 1/6 拍（它同时封住 stageReq_ready，比例太高请求就进不去）。
//   · mbmc.BCLEAR 约 1/2000 拍（清空有效位但 SRAM 不清，之后同 tag 必须重新回填才命中）；
//     另有约 1/4000 拍 BCLEAR 与 refill 同拍，逼出「BCLEAR 优先于 refill 置位」这条优先级。
//   · flush 五根各 1/500 拍；io_resp_ready 四分之三拍为 1。
//   · MBIST/DFT 通路只钉 0（与 PtwCache UT 同口径），bore_ack/outdata 比的是"两侧都不动"。
//
// 【判别力自证】覆盖下限：命中响应、未命中响应、"组满后再回填"（PLRU 路径）、BCLEAR 后
//   再命中，都必须 > 0，否则 tb 自判 FAIL。
//   注入过的 mutant（不进库；seed=1，改完先 diff 确认变异真的进了 RTL）：
//     M1 BCLEAR 优先级低于 refill      -> 20k 拍 errors=0 **没抓到**；补了"BCLEAR 与 refill
//        同拍"的激励后 200k 拍抓到（首个失配 cyc=6808 io_resp_bits_cfs_1）。
//     M2 满组时受害者取路 0 而不是 PLRU -> 20k 拍抓到（cyc=138 cfs_0/cfs_3）。
//     M3 命中优先级树反转             -> 20k 拍抓到（cyc=1 io_resp_bits_hit）。
//
// 【实测】3 seed × 2 档 initreg × 200k 拍，每拍 14 次比较，全部 errors=0（见 Makefile 的
//   `make run SEED=<n> INITREG=<0|1>`；seed=1 覆盖：reqfire 88555 / hit 51162 / miss 30657 /
//   refill 33219 / refill_full 27330 / bclear 110 / hit_after_clear 49315）。
`timescale 1ns/1ps
module tb;
  int errors = 0;
  int checks = 0;
  int ncycles;
  int cov_hit = 0, cov_miss = 0, cov_refill = 0, cov_refill_full = 0, cov_bclear = 0, cov_hit_after_clear = 0;
  int cov_reqfire = 0;

  // BEGIN GENERATED(harness) —— 由 gen_mmu5.py 生成：信号声明 / 双例化 / 输出逐拍比对
  logic clock, reset;
  logic io_sfence_valid;
  logic io_csr_satp_changed;
  logic io_csr_vsatp_changed;
  logic io_csr_hgatp_changed;
  logic io_csr_mbmc_BCLEAR;
  logic io_csr_priv_virt_changed;
  logic io_req_valid;
  logic [7:0] io_req_bits_order;
  logic [35:0] io_req_bits_tag;
  logic io_resp_ready;
  logic io_refill_valid;
  logic [35:0] io_refill_bits_tag;
  logic [63:0] io_refill_bits_data;
  logic [5:0] boreChildrenBd_bore_array;
  logic boreChildrenBd_bore_all;
  logic boreChildrenBd_bore_req;
  logic boreChildrenBd_bore_writeen;
  logic [1:0] boreChildrenBd_bore_be;
  logic [5:0] boreChildrenBd_bore_addr;
  logic [89:0] boreChildrenBd_bore_indata;
  logic boreChildrenBd_bore_readen;
  logic [5:0] boreChildrenBd_bore_addr_rd;
  logic sigFromSrams_bore_ram_hold;
  logic sigFromSrams_bore_ram_bypass;
  logic sigFromSrams_bore_ram_bp_clken;
  logic sigFromSrams_bore_ram_aux_clk;
  logic sigFromSrams_bore_ram_aux_ckbp;
  logic sigFromSrams_bore_ram_mcp_hold;
  logic sigFromSrams_bore_cgen;
  logic sigFromSrams_bore_1_ram_hold;
  logic sigFromSrams_bore_1_ram_bypass;
  logic sigFromSrams_bore_1_ram_bp_clken;
  logic sigFromSrams_bore_1_ram_aux_clk;
  logic sigFromSrams_bore_1_ram_aux_ckbp;
  logic sigFromSrams_bore_1_ram_mcp_hold;
  logic sigFromSrams_bore_1_cgen;
  logic sigFromSrams_bore_2_ram_hold;
  logic sigFromSrams_bore_2_ram_bypass;
  logic sigFromSrams_bore_2_ram_bp_clken;
  logic sigFromSrams_bore_2_ram_aux_clk;
  logic sigFromSrams_bore_2_ram_aux_ckbp;
  logic sigFromSrams_bore_2_ram_mcp_hold;
  logic sigFromSrams_bore_2_cgen;
  logic sigFromSrams_bore_3_ram_hold;
  logic sigFromSrams_bore_3_ram_bypass;
  logic sigFromSrams_bore_3_ram_bp_clken;
  logic sigFromSrams_bore_3_ram_aux_clk;
  logic sigFromSrams_bore_3_ram_aux_ckbp;
  logic sigFromSrams_bore_3_ram_mcp_hold;
  logic sigFromSrams_bore_3_cgen;
  logic cg_bore_cgen;
  logic g_io_req_ready, i_io_req_ready;
  logic g_io_resp_valid, i_io_resp_valid;
  logic g_io_resp_bits_hit, i_io_resp_bits_hit;
  logic g_io_resp_bits_cfs_0, i_io_resp_bits_cfs_0;
  logic g_io_resp_bits_cfs_1, i_io_resp_bits_cfs_1;
  logic g_io_resp_bits_cfs_2, i_io_resp_bits_cfs_2;
  logic g_io_resp_bits_cfs_3, i_io_resp_bits_cfs_3;
  logic g_io_resp_bits_cfs_4, i_io_resp_bits_cfs_4;
  logic g_io_resp_bits_cfs_5, i_io_resp_bits_cfs_5;
  logic g_io_resp_bits_cfs_6, i_io_resp_bits_cfs_6;
  logic g_io_resp_bits_cfs_7, i_io_resp_bits_cfs_7;
  logic [7:0] g_io_resp_bits_order, i_io_resp_bits_order;
  logic g_boreChildrenBd_bore_ack, i_boreChildrenBd_bore_ack;
  logic [89:0] g_boreChildrenBd_bore_outdata, i_boreChildrenBd_bore_outdata;
  BitmapCache u_g (
    .clock(clock), .reset(reset),
    .io_sfence_valid                  (io_sfence_valid),
    .io_csr_satp_changed              (io_csr_satp_changed),
    .io_csr_vsatp_changed             (io_csr_vsatp_changed),
    .io_csr_hgatp_changed             (io_csr_hgatp_changed),
    .io_csr_mbmc_BCLEAR               (io_csr_mbmc_BCLEAR),
    .io_csr_priv_virt_changed         (io_csr_priv_virt_changed),
    .io_req_ready                     (g_io_req_ready),
    .io_req_valid                     (io_req_valid),
    .io_req_bits_order                (io_req_bits_order),
    .io_req_bits_tag                  (io_req_bits_tag),
    .io_resp_ready                    (io_resp_ready),
    .io_resp_valid                    (g_io_resp_valid),
    .io_resp_bits_hit                 (g_io_resp_bits_hit),
    .io_resp_bits_cfs_0               (g_io_resp_bits_cfs_0),
    .io_resp_bits_cfs_1               (g_io_resp_bits_cfs_1),
    .io_resp_bits_cfs_2               (g_io_resp_bits_cfs_2),
    .io_resp_bits_cfs_3               (g_io_resp_bits_cfs_3),
    .io_resp_bits_cfs_4               (g_io_resp_bits_cfs_4),
    .io_resp_bits_cfs_5               (g_io_resp_bits_cfs_5),
    .io_resp_bits_cfs_6               (g_io_resp_bits_cfs_6),
    .io_resp_bits_cfs_7               (g_io_resp_bits_cfs_7),
    .io_resp_bits_order               (g_io_resp_bits_order),
    .io_refill_valid                  (io_refill_valid),
    .io_refill_bits_tag               (io_refill_bits_tag),
    .io_refill_bits_data              (io_refill_bits_data),
    .boreChildrenBd_bore_array        (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all          (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req          (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack          (g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen      (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be           (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr         (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata       (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen       (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd      (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata      (g_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold     (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass   (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk  (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen         (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold     (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass   (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk  (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen         (sigFromSrams_bore_3_cgen),
    .cg_bore_cgen                     (cg_bore_cgen)
  );
  BitmapCache_xs u_i (
    .clock(clock), .reset(reset),
    .io_sfence_valid                  (io_sfence_valid),
    .io_csr_satp_changed              (io_csr_satp_changed),
    .io_csr_vsatp_changed             (io_csr_vsatp_changed),
    .io_csr_hgatp_changed             (io_csr_hgatp_changed),
    .io_csr_mbmc_BCLEAR               (io_csr_mbmc_BCLEAR),
    .io_csr_priv_virt_changed         (io_csr_priv_virt_changed),
    .io_req_ready                     (i_io_req_ready),
    .io_req_valid                     (io_req_valid),
    .io_req_bits_order                (io_req_bits_order),
    .io_req_bits_tag                  (io_req_bits_tag),
    .io_resp_ready                    (io_resp_ready),
    .io_resp_valid                    (i_io_resp_valid),
    .io_resp_bits_hit                 (i_io_resp_bits_hit),
    .io_resp_bits_cfs_0               (i_io_resp_bits_cfs_0),
    .io_resp_bits_cfs_1               (i_io_resp_bits_cfs_1),
    .io_resp_bits_cfs_2               (i_io_resp_bits_cfs_2),
    .io_resp_bits_cfs_3               (i_io_resp_bits_cfs_3),
    .io_resp_bits_cfs_4               (i_io_resp_bits_cfs_4),
    .io_resp_bits_cfs_5               (i_io_resp_bits_cfs_5),
    .io_resp_bits_cfs_6               (i_io_resp_bits_cfs_6),
    .io_resp_bits_cfs_7               (i_io_resp_bits_cfs_7),
    .io_resp_bits_order               (i_io_resp_bits_order),
    .io_refill_valid                  (io_refill_valid),
    .io_refill_bits_tag               (io_refill_bits_tag),
    .io_refill_bits_data              (io_refill_bits_data),
    .boreChildrenBd_bore_array        (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all          (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req          (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack          (i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen      (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be           (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr         (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata       (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen       (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd      (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata      (i_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold     (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass   (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk  (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen         (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold     (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass   (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk  (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen         (sigFromSrams_bore_3_cgen),
    .cg_bore_cgen                     (cg_bore_cgen)
  );
  // 逐拍比全部 14 个输出（golden 端口表逐根量出，不手抄）
  task automatic compare_outputs(input int cyc);
    checks++; if (g_io_req_ready !== i_io_req_ready) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_req_ready g=%h i=%h", cyc, g_io_req_ready, i_io_req_ready); end
    checks++; if (g_io_resp_valid !== i_io_resp_valid) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_valid g=%h i=%h", cyc, g_io_resp_valid, i_io_resp_valid); end
    checks++; if (g_io_resp_bits_hit !== i_io_resp_bits_hit) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_hit g=%h i=%h", cyc, g_io_resp_bits_hit, i_io_resp_bits_hit); end
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
    checks++; if (g_io_resp_bits_order !== i_io_resp_bits_order) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d io_resp_bits_order g=%h i=%h", cyc, g_io_resp_bits_order, i_io_resp_bits_order); end
    checks++; if (g_boreChildrenBd_bore_ack !== i_boreChildrenBd_bore_ack) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d boreChildrenBd_bore_ack g=%h i=%h", cyc, g_boreChildrenBd_bore_ack, i_boreChildrenBd_bore_ack); end
    checks++; if (g_boreChildrenBd_bore_outdata !== i_boreChildrenBd_bore_outdata) begin errors++; if (errors <= 20)
      $display("MISMATCH cyc=%0d boreChildrenBd_bore_outdata g=%h i=%h", cyc, g_boreChildrenBd_bore_outdata, i_boreChildrenBd_bore_outdata); end
  endtask
  // END GENERATED(harness)

  logic [35:0] tag_pool [8];
  int cyc = 0;
  logic seen_bclear = 0;

  function automatic logic [35:0] pick_tag();
    logic [35:0] t;
    if ($urandom_range(0, 3) == 0) t = {$urandom(), $urandom()};
    else t = tag_pool[$urandom_range(0, 7)];
    t[5:0] = $urandom();   // 字节选择与低位随机
    return t;
  endfunction

  task automatic drive_random();
    io_sfence_valid          <= ($urandom_range(0, 499) == 0);
    io_csr_satp_changed      <= ($urandom_range(0, 499) == 0);
    io_csr_vsatp_changed     <= ($urandom_range(0, 499) == 0);
    io_csr_hgatp_changed     <= ($urandom_range(0, 499) == 0);
    io_csr_priv_virt_changed <= ($urandom_range(0, 499) == 0);
    io_csr_mbmc_BCLEAR       <= ($urandom_range(0, 1999) == 0);
    io_req_valid       <= $urandom_range(0, 2) != 0;
    io_req_bits_order  <= $urandom();
    io_req_bits_tag    <= pick_tag();
    io_resp_ready      <= $urandom_range(0, 3) != 0;
    // BCLEAR 那一拍有一半概率同时来 refill：逼出"BCLEAR 优先于 refill 置位"这条优先级
    io_refill_valid    <= ($urandom_range(0, 5) == 0) | (($urandom_range(0, 1999) == 0) & $urandom_range(0, 1));
    io_refill_bits_tag <= pick_tag();
    io_refill_bits_data <= {$urandom(), $urandom()};
  endtask

  task automatic count_cov();
    if (g_io_req_ready && io_req_valid) cov_reqfire++;
    if (g_io_resp_valid && io_resp_ready) begin
      if (g_io_resp_bits_hit) begin cov_hit++; if (seen_bclear) cov_hit_after_clear++; end
      else cov_miss++;
    end
    if (io_refill_valid) begin
      cov_refill++;
      if (&u_g.bcv[io_refill_bits_tag[10:6]*4 +: 4]) cov_refill_full++;
    end
    if (io_csr_mbmc_BCLEAR) begin cov_bclear++; seen_bclear = 1; end
  endtask

  initial clock = 0;
  always #5 clock = ~clock;

  initial begin
    if (!$value$plusargs("ncycles=%d", ncycles)) ncycles = 200000;
    for (int i = 0; i < 8; i++) begin
      tag_pool[i] = {$urandom(), $urandom()};
      tag_pool[i][10:6] = 5'(i % 3);   // 8 条 tag 挤进 3 个组，逼出满组替换
    end
    reset = 1;
    io_sfence_valid = 0; io_csr_satp_changed = 0; io_csr_vsatp_changed = 0;
    io_csr_hgatp_changed = 0; io_csr_mbmc_BCLEAR = 0; io_csr_priv_virt_changed = 0;
    io_req_valid = 0; io_req_bits_order = 0; io_req_bits_tag = 0; io_resp_ready = 0;
    io_refill_valid = 0; io_refill_bits_tag = 0; io_refill_bits_data = 0;
    boreChildrenBd_bore_array = 0; boreChildrenBd_bore_all = 0; boreChildrenBd_bore_req = 0;
    boreChildrenBd_bore_writeen = 0; boreChildrenBd_bore_be = 0; boreChildrenBd_bore_addr = 0;
    boreChildrenBd_bore_indata = 0; boreChildrenBd_bore_readen = 0; boreChildrenBd_bore_addr_rd = 0;
    sigFromSrams_bore_ram_hold = 0; sigFromSrams_bore_ram_bypass = 0; sigFromSrams_bore_ram_bp_clken = 0;
    sigFromSrams_bore_ram_aux_clk = 0; sigFromSrams_bore_ram_aux_ckbp = 0; sigFromSrams_bore_ram_mcp_hold = 0;
    sigFromSrams_bore_cgen = 0;
    sigFromSrams_bore_1_ram_hold = 0; sigFromSrams_bore_1_ram_bypass = 0; sigFromSrams_bore_1_ram_bp_clken = 0;
    sigFromSrams_bore_1_ram_aux_clk = 0; sigFromSrams_bore_1_ram_aux_ckbp = 0; sigFromSrams_bore_1_ram_mcp_hold = 0;
    sigFromSrams_bore_1_cgen = 0;
    sigFromSrams_bore_2_ram_hold = 0; sigFromSrams_bore_2_ram_bypass = 0; sigFromSrams_bore_2_ram_bp_clken = 0;
    sigFromSrams_bore_2_ram_aux_clk = 0; sigFromSrams_bore_2_ram_aux_ckbp = 0; sigFromSrams_bore_2_ram_mcp_hold = 0;
    sigFromSrams_bore_2_cgen = 0;
    sigFromSrams_bore_3_ram_hold = 0; sigFromSrams_bore_3_ram_bypass = 0; sigFromSrams_bore_3_ram_bp_clken = 0;
    sigFromSrams_bore_3_ram_aux_clk = 0; sigFromSrams_bore_3_ram_aux_ckbp = 0; sigFromSrams_bore_3_ram_mcp_hold = 0;
    sigFromSrams_bore_3_cgen = 0;
    cg_bore_cgen = 0;
    repeat (4) @(posedge clock);
    #1 reset = 0;
    for (cyc = 1; cyc <= ncycles; cyc++) begin
      @(negedge clock);
      compare_outputs(cyc);
      count_cov();
      drive_random();
    end
    $display("cov: reqfire=%0d hit=%0d miss=%0d refill=%0d refill_full=%0d bclear=%0d hit_after_clear=%0d",
             cov_reqfire, cov_hit, cov_miss, cov_refill, cov_refill_full, cov_bclear, cov_hit_after_clear);
    if (cov_hit == 0 || cov_miss == 0 || cov_refill_full == 0 || cov_bclear == 0 || cov_hit_after_clear == 0) begin
      $display("COVERAGE FLOOR NOT MET");
      errors++;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
