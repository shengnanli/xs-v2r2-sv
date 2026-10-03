// StrideMetaArray UT —— golden vs 重写件双例化，逐拍比全部输出
//
// 激励：维护 12 条"指令"（pc 池 > 10 项 → 打 PLRU 替换），每条有自己的当前地址与步长（块数 0..9，
// 含 0/1 两个"非法步长"），每次训练地址 += 步长×64 并以小概率扰动（打置信度 -1、改写 stride），
// 另掺 10% 全随机 {pc, vaddr}。pc 池里故意放两条 pc 哈希相同（高位不同）的指令打误命中（多命中在可达状态下不存在：同哈希只会命中不会再分配）；
// train_valid 偶尔连续同 pc（打 ready 的背靠背拦截）。中途异步复位 3 次。
// 比对：ready / stream_lookup / 两路 pf valid 逐拍；pf 的 region/bit_vec 只在 valid=1 时比（见 Makefile）。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic        tv;
  logic [49:0] tva, tpc;
  wire        g_rdy, i_rdy, g_l1v, i_l1v, g_l2v, i_l2v, g_slv, i_slv;
  wire [39:0] g_l1r, i_l1r, g_l2r, i_l2r;
  wire [15:0] g_l1b, i_l1b, g_l2b, i_l2b;
  wire [49:0] g_sla, i_sla;

  `define SMA_PORTS(P) \
    .clock(clk), .reset(rst), .io_train_req_ready(P``_rdy), .io_train_req_valid(tv), \
    .io_train_req_bits_vaddr(tva), .io_train_req_bits_pc(tpc), \
    .io_l1_prefetch_req_valid(P``_l1v), .io_l1_prefetch_req_bits_region(P``_l1r), .io_l1_prefetch_req_bits_bit_vec(P``_l1b), \
    .io_l2_l3_prefetch_req_valid(P``_l2v), .io_l2_l3_prefetch_req_bits_region(P``_l2r), .io_l2_l3_prefetch_req_bits_bit_vec(P``_l2b), \
    .io_stream_lookup_req_valid(P``_slv), .io_stream_lookup_req_bits_vaddr(P``_sla)

  StrideMetaArray    g (`SMA_PORTS(g));
  StrideMetaArray_xs i (`SMA_PORTS(i));

  localparam int NPC = 12;
  logic [49:0] pcs  [NPC];
  logic [49:0] addr [NPC];
  int          strd [NPC];
  int cyc, last_k;
  int cov_hit, cov_alloc, cov_pf, cov_notready, cov_conf3, cov_multihit, cov_midrst, cov_strideinvalid;

  always @(negedge clk) begin
    if (rst) begin
      cyc <= 0; tv <= 0; tva <= '0; tpc <= '0;
    end else begin
      cyc <= cyc + 1;
      tv <= ($urandom_range(0, 2) != 0);
      if ($urandom_range(0, 9) == 0) begin
        tpc <= {$urandom, $urandom}; tva <= {$urandom, $urandom};
      end else begin
        int k;
        k = ($urandom_range(0, 3) == 0) ? last_k : $urandom_range(0, NPC-1);
        last_k = k;
        tpc <= pcs[k];
        if ($urandom_range(0, 39) == 0) addr[k] = addr[k] + 50'($urandom_range(0, 2047));   // 扰动
        else                            addr[k] = addr[k] + 50'(strd[k] * 64);
        tva <= addr[k];
        if ($urandom_range(0, 499) == 0) strd[k] = $urandom_range(0, 9);
      end
    end
  end

  `define CHK(nm, gg, ii) \
    if ((gg) !== (ii)) begin errors++; \
      if (errors <= 40) $display("[cyc %0d] %s g=%h i=%h", cyc, nm, gg, ii); end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    `CHK("ready",   g_rdy, i_rdy)
    `CHK("sl.valid", g_slv, i_slv)
    `CHK("sl.vaddr", g_sla, i_sla)
    `CHK("l1.valid", g_l1v, i_l1v)
    `CHK("l2.valid", g_l2v, i_l2v)
    if (g_l1v) begin `CHK("l1.region", g_l1r, i_l1r) `CHK("l1.bit_vec", g_l1b, i_l1b) end
    if (g_l2v) begin `CHK("l2.region", g_l2r, i_l2r) `CHK("l2.bit_vec", g_l2b, i_l2b) end
    if (g.s0_valid_probe && (|g.s0_pc_match_vec)) cov_hit++;
    if (g.s0_valid_probe && !(|g.s0_pc_match_vec)) cov_alloc++;
    if (g.s0_valid_probe && $countones(g.s0_pc_match_vec) > 1) cov_multihit++;
    if (g_l1v) cov_pf++;
    if (tv && !g_rdy) cov_notready++;
    if (g.s1_update && (&g._GEN_25)) cov_conf3++;
    if (g.s1_update && !g.res_stride_valid) cov_strideinvalid++;
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (int k = 0; k < NPC; k++) begin
      pcs[k] = {$urandom, $urandom}; addr[k] = {$urandom, $urandom}; strd[k] = $urandom_range(0, 9);
    end
    pcs[1] = pcs[0] ^ (50'h3 << 30);   // 与 pcs[0] 同哈希（哈希只看 [24:0]）：命中到对方的表项、步长被搅乱
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    for (int k = 0; k < 4; k++) begin
      repeat (NCYCLES / 4) @(posedge clk);
      if (k < 3) begin
        #2 rst = 1; cov_midrst++;
        repeat (3) @(posedge clk);
        #2 rst = 0;
      end
    end
    $display("COV hit=%0d alloc=%0d multihit=%0d pf=%0d notready=%0d conf3=%0d stride_invalid=%0d midrst=%0d",
             cov_hit, cov_alloc, cov_multihit, cov_pf, cov_notready, cov_conf3, cov_strideinvalid, cov_midrst);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && cov_hit > 1000 && cov_alloc > 1000 && cov_pf > 1000 && cov_notready > 100
        && cov_conf3 > 1000 && cov_strideinvalid > 1000)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
