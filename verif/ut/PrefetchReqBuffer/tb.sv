// PrefetchReqBuffer UT —— golden vs 重写件双例化，逐拍比全部输出
//
// tb 里带一个 TLB 响应模型：对 golden 发出的 tlb_req 固定 1 拍后回答（设计按 s1 发 / s2 收 / s3 PMP 的
// 固定节拍记账，错拍的回答会被当成别人的）；回答 25% miss、少量 pf/gpf/af 异常、pbmt 随机（NC/IO 各 1/4 概率
// 触发 uncache 丢弃）、paddr 随机；PMP 的 ld/mmio 每拍随机。两侧收到完全相同的回答。
// 入口请求：full_vaddr 从小地址池取（打 conflict_prev 与表内全等去重），base/needT/source 取小集合；
// 入队密集相位打"满则丢"。out_ready 随机。中途异步复位 3 次。
// 比对：tlb_req.valid / out_req.valid 逐拍；tlb_req 的 bits 在首个 tlb_req.valid 之后逐拍比（不复位的
// RegEnable(常量) 寄存器在那之前是未定义初值）；out_req 的 bits 在 valid=1 时比。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic        iv, nt, ordy;
  logic [49:0] fva;  logic [43:0] bva;  logic [6:0] src;
  logic        rv, rmiss, rgpf, rpf, raf, pld, pmmio;
  logic [47:0] rpa;  logic [1:0] rpbmt;

  wire        g_tv, i_tv, g_tpf, i_tpf, g_tk, i_tk, g_tnt, i_tnt, g_ov, i_ov, g_ont, i_ont;
  wire [49:0] g_tva, i_tva;  wire [2:0] g_tcmd, i_tcmd;
  wire [32:0] g_otag, i_otag;  wire [8:0] g_oset, i_oset;  wire [43:0] g_ova, i_ova;  wire [6:0] g_osrc, i_osrc;

  `define PRB_PORTS(P) \
    .clock(clk), .reset(rst), .io_in_req_valid(iv), .io_in_req_bits_full_vaddr(fva), .io_in_req_bits_base_vaddr(bva), \
    .io_in_req_bits_needT(nt), .io_in_req_bits_source(src), \
    .io_tlb_req_req_valid(P``_tv), .io_tlb_req_req_bits_vaddr(P``_tva), .io_tlb_req_req_bits_cmd(P``_tcmd), \
    .io_tlb_req_req_bits_isPrefetch(P``_tpf), .io_tlb_req_req_bits_kill(P``_tk), .io_tlb_req_req_bits_no_translate(P``_tnt), \
    .io_tlb_req_resp_valid(rv), .io_tlb_req_resp_bits_paddr_0(rpa), .io_tlb_req_resp_bits_pbmt(rpbmt), .io_tlb_req_resp_bits_miss(rmiss), \
    .io_tlb_req_resp_bits_excp_0_gpf_ld(rgpf), .io_tlb_req_resp_bits_excp_0_pf_ld(rpf), .io_tlb_req_resp_bits_excp_0_af_ld(raf), \
    .io_tlb_req_pmp_resp_ld(pld), .io_tlb_req_pmp_resp_mmio(pmmio), .io_out_req_ready(ordy), \
    .io_out_req_valid(P``_ov), .io_out_req_bits_tag(P``_otag), .io_out_req_bits_set(P``_oset), .io_out_req_bits_vaddr(P``_ova), \
    .io_out_req_bits_needT(P``_ont), .io_out_req_bits_source(P``_osrc)

  PrefetchReqBuffer    g (`PRB_PORTS(g));
  PrefetchReqBuffer_xs i (`PRB_PORTS(i));

  logic [49:0] vpool [8];
  logic [43:0] bpool [4];
  int cyc, phase;
  bit seen_tlb;
  int cov_alloc, cov_conflict, cov_match, cov_full, cov_tlbreq, cov_miss1, cov_miss2, cov_exp, cov_pf, cov_midrst;

  always @(negedge clk) begin
    if (rst) begin
      cyc <= 0; phase <= 0; iv <= 0; fva <= '0; bva <= '0; nt <= 0; src <= '0; ordy <= 0; seen_tlb <= 0;
      rv <= 0; rmiss <= 0; rgpf <= 0; rpf <= 0; raf <= 0; rpa <= '0; rpbmt <= '0; pld <= 0; pmmio <= 0;
    end else begin
      cyc <= cyc + 1;
      if ($urandom_range(0, 399) == 0) phase <= $urandom_range(0, 2);
      if ($urandom_range(0, 199) == 0) vpool[$urandom_range(0, 7)] <= {$urandom, $urandom};
      iv  <= (phase == 0) ? ($urandom_range(0, 1) == 0) : (phase == 1) ? ($urandom_range(0, 7) == 0) : ($urandom_range(0, 3) != 0);
      fva <= ($urandom_range(0, 4) == 0) ? {$urandom, $urandom} : vpool[$urandom_range(0, 7)] + 50'($urandom_range(0, 1) * 64);
      bva <= bpool[$urandom_range(0, 3)];
      nt  <= $urandom_range(0, 1);
      src <= 7'($urandom_range(0, 2));
      ordy <= (phase == 2) ? ($urandom_range(0, 7) == 0) : ($urandom_range(0, 2) != 0);
      // TLB 响应模型：对 golden 的请求 1 拍后回答
      rv    <= g_tv;
      rmiss <= ($urandom_range(0, 3) == 0);
      rgpf  <= ($urandom_range(0, 19) == 0);
      rpf   <= ($urandom_range(0, 19) == 0);
      raf   <= ($urandom_range(0, 19) == 0);
      rpa   <= {$urandom, $urandom};
      rpbmt <= 2'($urandom);
      pld   <= ($urandom_range(0, 9) == 0);
      pmmio <= ($urandom_range(0, 9) == 0);
      if (g_tv) seen_tlb <= 1;
    end
  end

  `define CHK(nm, gg, ii) \
    if ((gg) !== (ii)) begin errors++; \
      if (errors <= 40) $display("[cyc %0d] %s g=%h i=%h", cyc, nm, gg, ii); end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    `CHK("tlb.valid", g_tv, i_tv)
    `CHK("out.valid", g_ov, i_ov)
    if (seen_tlb) begin
      `CHK("tlb.vaddr", g_tva, i_tva) `CHK("tlb.cmd", g_tcmd, i_tcmd) `CHK("tlb.isPrefetch", g_tpf, i_tpf)
      `CHK("tlb.kill", g_tk, i_tk) `CHK("tlb.no_translate", g_tnt, i_tnt)
    end
    if (g_ov) begin
      `CHK("out.tag", g_otag, i_otag) `CHK("out.set", g_oset, i_oset) `CHK("out.vaddr", g_ova, i_ova)
      `CHK("out.needT", g_ont, i_ont) `CHK("out.source", g_osrc, i_osrc)
    end
    if (g.s1_valid) cov_alloc++;
    if (iv && g.s0_conflict_prev) cov_conflict++;
    if (iv && !g.s0_conflict_prev && (|g.s0_match_oh)) cov_match++;
    if (iv && !g.s0_conflict_prev && !(|g.s0_match_oh) && !(|g._s0_has_invalid_way_T)) cov_full++;
    if (g_tv) cov_tlbreq++;
    if (g.miss_first_replay_0 || g.miss_first_replay_5) cov_miss1++;
    if (g.miss_drop_0 || g.miss_drop_5) cov_miss2++;
    if (g.exp_drop_0 || g.exp_drop_5) cov_exp++;
    if (g_ov && ordy) cov_pf++;
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (int k = 0; k < 8; k++) vpool[k] = {$urandom, $urandom};
    for (int k = 0; k < 4; k++) bpool[k] = {$urandom, $urandom};
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    for (int k = 0; k < 4; k++) begin
      repeat (NCYCLES / 4) @(posedge clk);
      if (k < 3) begin
        #2 rst = 1; cov_midrst++;
        repeat (3) @(posedge clk);
        #2 rst = 0;
      end
    end
    $display("COV alloc=%0d conflict=%0d match=%0d full=%0d tlbreq=%0d miss_first=%0d miss_drop=%0d exp_drop=%0d pf=%0d midrst=%0d",
             cov_alloc, cov_conflict, cov_match, cov_full, cov_tlbreq, cov_miss1, cov_miss2, cov_exp, cov_pf, cov_midrst);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && cov_alloc > 1000 && cov_conflict > 1000 && cov_match > 1000 && cov_full > 100
        && cov_tlbreq > 1000 && cov_miss1 > 100 && cov_miss2 > 100 && cov_exp > 100 && cov_pf > 1000)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
