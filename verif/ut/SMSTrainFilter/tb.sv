// SMSTrainFilter UT —— golden vs 重写件双例化，逐拍比全部输出
//
// 激励与 verif/ut/TrainFilter 同一套思路（同块去重 / robIdx 重排 / 指针回绕），差别：
//   没有 enable 与 train_ready（队头有效即出队），每拍必出 1 项，所以 8 项"全满"在判定时刻不可达，
//   "满"的覆盖按"任一路 needAlloc 但分配指针已追上 deqPtr（被判满）"计；
//   条目复位清零，故 train_req.bits 逐拍全比（不只在 valid 时）。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic        v   [3];
  logic [49:0] pc  [3];
  logic [49:0] va  [3];
  logic [47:0] pa  [3];
  logic        rf  [3];
  logic [7:0]  rv  [3];

  wire        g_v, i_v;
  wire [49:0] g_va, i_va, g_pc, i_pc;
  wire [47:0] g_pa, i_pa;

  `define SMS_IN(I) \
    .io_ld_in_``I``_valid(v[I]), .io_ld_in_``I``_bits_uop_pc(pc[I]), .io_ld_in_``I``_bits_uop_robIdx_flag(rf[I]), \
    .io_ld_in_``I``_bits_uop_robIdx_value(rv[I]), .io_ld_in_``I``_bits_vaddr(va[I]), .io_ld_in_``I``_bits_paddr(pa[I])

  SMSTrainFilter    g (.clock(clk), .reset(rst), `SMS_IN(0), `SMS_IN(1), `SMS_IN(2),
    .io_train_req_valid(g_v), .io_train_req_bits_vaddr(g_va), .io_train_req_bits_paddr(g_pa), .io_train_req_bits_pc(g_pc));
  SMSTrainFilter_xs i (.clock(clk), .reset(rst), `SMS_IN(0), `SMS_IN(1), `SMS_IN(2),
    .io_train_req_valid(i_v), .io_train_req_bits_vaddr(i_va), .io_train_req_bits_paddr(i_pa), .io_train_req_bits_pc(i_pc));

  logic [49:0] pool [8];
  logic [8:0]  rob_base;
  int cyc, phase;
  int cov_three_valid, cov_swap, cov_dedup_entry, cov_dedup_prev, cov_full, cov_fire, cov_wrap, cov_midrst;

  function automatic logic [49:0] rnd_va();
    logic [49:0] b;
    b = pool[$urandom_range(0, 7)];
    case ($urandom_range(0, 9))
      0: b[31+$urandom_range(0, 18)] ^= 1'b1;
      1: b[6+$urandom_range(0, 24)]  ^= 1'b1;
      2: b = {$urandom, $urandom};
      default: b[5:0] = 6'($urandom);
    endcase
    return b;
  endfunction

  always @(negedge clk) begin
    if (rst) begin
      cyc <= 0; phase <= 0;
      for (int k = 0; k < 3; k++) begin v[k] <= 0; pc[k] <= '0; va[k] <= '0; pa[k] <= '0; rf[k] <= 0; rv[k] <= '0; end
    end else begin
      cyc <= cyc + 1;
      if ($urandom_range(0, 799) == 0) phase <= $urandom_range(0, 2);
      if ($urandom_range(0, 1999) == 0) pool[$urandom_range(0, 7)] <= {$urandom, $urandom};
      rob_base <= rob_base + 9'($urandom_range(0, 3));
      for (int k = 0; k < 3; k++) begin
        // phase 0：三路几乎全有效且地址全随机（打满）；1：稀疏；2：中等
        v[k]  <= (phase == 0) ? ($urandom_range(0, 9) != 0) : (phase == 1) ? ($urandom_range(0, 5) == 0) : $urandom_range(0, 1);
        va[k] <= (phase == 0 && $urandom_range(0, 2) != 0) ? {$urandom, $urandom} : rnd_va();
        pc[k] <= {$urandom, $urandom};
        pa[k] <= {$urandom, $urandom};
        {rf[k], rv[k]} <= rob_base + 9'($urandom_range(0, 7));
      end
    end
  end

  `define CHK(nm, g, i) \
    if ((g) !== (i)) begin errors++; \
      if (errors <= 40) $display("[cyc %0d] %s g=%h i=%h", cyc, nm, g, i); end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    `CHK("SMS.valid", g_v, i_v)
    `CHK("SMS.vaddr", g_va, i_va)
    `CHK("SMS.paddr", g_pa, i_pa)
    `CHK("SMS.pc",    g_pc, i_pc)
    if (g.ld_reorder_0_valid && g.ld_reorder_1_valid && g.ld_reorder_2_valid) cov_three_valid++;
    if (g.ld_reorder_tmp_source_1_older || g.ld_reorder_tmp_1_source_1_older || g.ld_reorder_tmp_2_source_1_older) cov_swap++;
    if (g.ld_reorder_1_valid && !g.needAlloc_1 && g.ld_reorder_0_valid) cov_dedup_prev++;
    if (g.ld_reorder_0_valid && !g.needAlloc_0) cov_dedup_entry++;
    if ((g.needAlloc_0 && !g.canAlloc_0) || (g.needAlloc_1 && !g.canAlloc_1) || (g.needAlloc_2 && !g.canAlloc_2)) cov_full++;
    if (g_v) cov_fire++;
    if (g_v && g.deqPtrExt_value == 3'd7) cov_wrap++;
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (int k = 0; k < 8; k++) pool[k] = {$urandom, $urandom};
    rob_base = 9'($urandom);
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    for (int k = 0; k < 4; k++) begin
      repeat (NCYCLES / 4) @(posedge clk);
      if (k < 3) begin
        #2 rst = 1; cov_midrst++;
        repeat (6) @(posedge clk);
        #2 rst = 0;
      end
    end
    $display("COV three_valid=%0d swap=%0d dedup_entry=%0d dedup_prev=%0d full=%0d fire=%0d wrap=%0d midrst=%0d",
             cov_three_valid, cov_swap, cov_dedup_entry, cov_dedup_prev, cov_full, cov_fire, cov_wrap, cov_midrst);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && cov_three_valid > 1000 && cov_swap > 1000 && cov_dedup_entry > 1000
        && cov_dedup_prev > 100 && cov_full > 1000 && cov_fire > 1000 && cov_wrap > 100)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
