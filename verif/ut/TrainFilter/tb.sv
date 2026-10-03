// TrainFilter UT —— TrainFilter / TrainFilter_1 两对 golden vs 重写件双例化，逐拍比全部输出
//
// 两对共用同一组 3 路训练激励。定向打的点：
//  (1) 同块去重：vaddr 从小地址池取（池内只差 [5:0] 与 [31+] 位 → 同哈希），既打"与 FIFO 已有项同块"
//      也打"同拍更早的路同块"；另掺入 [30:6] 内差一位的"近邻地址"打哈希的异或折叠。
//  (2) 重排序：robIdx 从一个滑动窗口取，三路随机打乱，含 flag 翻转边界；三路都有效的拍要常见。
//  (3) FIFO 满：train_ready 分相位长时间为 0 → 指针回绕（深 6）与 "allocPtr >= deqPtr" 判满。
//  (4) enable 偶尔拉低（入队与出队都被门）。
//  (5) 变体 1：meta_prefetch 以较高概率取 3（pfHitStream）。
//  (6) 中途异步复位 3 次（复位期间三路 valid=0 冲掉不复位的流水）。
// 比对：train_req.valid 逐拍；vaddr/pc/miss/pfHitStream 只在 golden valid=1 时比（见 Makefile 注释）。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic        enable, ready;
  logic        v   [3];
  logic [49:0] pc  [3];
  logic [49:0] va  [3];
  logic        rf  [3];
  logic [7:0]  rv  [3];
  logic        miss[3];
  logic [2:0]  mp  [3];

  wire        g0_v, i0_v, g1_v, i1_v, g1_m, i1_m, g1_s, i1_s;
  wire [49:0] g0_va, i0_va, g0_pc, i0_pc, g1_va, i1_va;

  `define TF_IN(I) \
    .io_ld_in_``I``_valid(v[I]), .io_ld_in_``I``_bits_uop_robIdx_flag(rf[I]), \
    .io_ld_in_``I``_bits_uop_robIdx_value(rv[I]), .io_ld_in_``I``_bits_vaddr(va[I])

  TrainFilter      g0 (.clock(clk), .reset(rst), .io_enable(enable),
    `TF_IN(0), .io_ld_in_0_bits_uop_pc(pc[0]), `TF_IN(1), .io_ld_in_1_bits_uop_pc(pc[1]), `TF_IN(2), .io_ld_in_2_bits_uop_pc(pc[2]),
    .io_train_req_ready(ready), .io_train_req_valid(g0_v), .io_train_req_bits_vaddr(g0_va), .io_train_req_bits_pc(g0_pc));
  TrainFilter_xs   i0 (.clock(clk), .reset(rst), .io_enable(enable),
    `TF_IN(0), .io_ld_in_0_bits_uop_pc(pc[0]), `TF_IN(1), .io_ld_in_1_bits_uop_pc(pc[1]), `TF_IN(2), .io_ld_in_2_bits_uop_pc(pc[2]),
    .io_train_req_ready(ready), .io_train_req_valid(i0_v), .io_train_req_bits_vaddr(i0_va), .io_train_req_bits_pc(i0_pc));
  TrainFilter_1    g1 (.clock(clk), .reset(rst), .io_enable(enable),
    `TF_IN(0), .io_ld_in_0_bits_miss(miss[0]), .io_ld_in_0_bits_meta_prefetch(mp[0]),
    `TF_IN(1), .io_ld_in_1_bits_miss(miss[1]), .io_ld_in_1_bits_meta_prefetch(mp[1]),
    `TF_IN(2), .io_ld_in_2_bits_miss(miss[2]), .io_ld_in_2_bits_meta_prefetch(mp[2]),
    .io_train_req_ready(ready), .io_train_req_valid(g1_v), .io_train_req_bits_vaddr(g1_va),
    .io_train_req_bits_miss(g1_m), .io_train_req_bits_pfHitStream(g1_s));
  TrainFilter_1_xs i1 (.clock(clk), .reset(rst), .io_enable(enable),
    `TF_IN(0), .io_ld_in_0_bits_miss(miss[0]), .io_ld_in_0_bits_meta_prefetch(mp[0]),
    `TF_IN(1), .io_ld_in_1_bits_miss(miss[1]), .io_ld_in_1_bits_meta_prefetch(mp[1]),
    `TF_IN(2), .io_ld_in_2_bits_miss(miss[2]), .io_ld_in_2_bits_meta_prefetch(mp[2]),
    .io_train_req_ready(ready), .io_train_req_valid(i1_v), .io_train_req_bits_vaddr(i1_va),
    .io_train_req_bits_miss(i1_m), .io_train_req_bits_pfHitStream(i1_s));

  logic [49:0] pool [8];
  logic [8:0]  rob_base;   // {flag, value} 滑动窗口
  int cyc, phase;
  int cov_three_valid, cov_swap, cov_dedup_entry, cov_dedup_prev, cov_full, cov_fire, cov_disable, cov_wrap, cov_midrst, cov_stream;

  function automatic logic [49:0] rnd_va();
    logic [49:0] b;
    b = pool[$urandom_range(0, 7)];
    case ($urandom_range(0, 9))
      0: b[31+$urandom_range(0, 18)] ^= 1'b1;          // 高位不同、哈希相同
      1: b[6+$urandom_range(0, 24)]  ^= 1'b1;          // [30:6] 内差一位
      2: b = {$urandom, $urandom};                      // 全随机
      default: b[5:0] = 6'($urandom);                   // 同块不同偏移
    endcase
    return b;
  endfunction

  always @(negedge clk) begin
    if (rst) begin
      cyc <= 0; enable <= 1; ready <= 0; phase <= 0;
      for (int i = 0; i < 3; i++) begin v[i] <= 0; pc[i] <= '0; va[i] <= '0; rf[i] <= 0; rv[i] <= '0; miss[i] <= 0; mp[i] <= '0; end
    end else begin
      cyc <= cyc + 1;
      if ($urandom_range(0, 799) == 0) phase <= $urandom_range(0, 2);
      if ($urandom_range(0, 1999) == 0) pool[$urandom_range(0, 7)] <= {$urandom, $urandom};
      rob_base <= rob_base + 9'($urandom_range(0, 3));
      enable <= ($urandom_range(0, 99) != 0);
      ready  <= (phase == 1) ? ($urandom_range(0, 19) == 0) : (phase == 2) ? 1'b1 : ($urandom_range(0, 2) != 0);
      for (int i = 0; i < 3; i++) begin
        v[i]    <= (phase == 0) ? ($urandom_range(0, 2) != 0) : $urandom_range(0, 1);
        va[i]   <= rnd_va();
        pc[i]   <= {$urandom, $urandom};
        {rf[i], rv[i]} <= rob_base + 9'($urandom_range(0, 7));
        miss[i] <= $urandom_range(0, 1);
        mp[i]   <= ($urandom_range(0, 2) == 0) ? 3'd3 : 3'($urandom);
      end
    end
  end

  `define CHK(nm, g, i) \
    if ((g) !== (i)) begin errors++; \
      if (errors <= 40) $display("[cyc %0d] %s g=%h i=%h", cyc, nm, g, i); end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    `CHK("TF.valid",   g0_v, i0_v)
    `CHK("TF_1.valid", g1_v, i1_v)
    if (g0_v) begin `CHK("TF.vaddr", g0_va, i0_va) `CHK("TF.pc", g0_pc, i0_pc) end
    if (g1_v) begin `CHK("TF_1.vaddr", g1_va, i1_va) `CHK("TF_1.miss", g1_m, i1_m) `CHK("TF_1.pfHitStream", g1_s, i1_s) end
    // 覆盖（读 golden 内部）
    if (g0.ld_in_reordered_0_valid && g0.ld_in_reordered_1_valid && g0.ld_in_reordered_2_valid) cov_three_valid++;
    if (g0.ld_in_reordered_tmp_source_1_older || g0.ld_in_reordered_tmp_1_source_1_older || g0.ld_in_reordered_tmp_2_source_1_older) cov_swap++;
    if (g0.ld_in_reordered_1_valid && !g0.needAlloc_1 && g0.ld_in_reordered_0_valid) cov_dedup_prev++;
    if (g0.ld_in_reordered_0_valid && !g0.needAlloc_0) cov_dedup_entry++;
    if (g0.needAlloc_0 && !g0.canAlloc_0 && enable) cov_full++;
    if (g0_v && ready) cov_fire++;
    if (!enable) cov_disable++;
    if (g0.deqPtrExt_reverse_flag && g0._GEN_25) cov_wrap++;
    if (g1_v && g1_s) cov_stream++;
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (int i = 0; i < 8; i++) pool[i] = {$urandom, $urandom};
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
    $display("COV three_valid=%0d swap=%0d dedup_entry=%0d dedup_prev=%0d full=%0d fire=%0d disable=%0d wrap=%0d stream=%0d midrst=%0d",
             cov_three_valid, cov_swap, cov_dedup_entry, cov_dedup_prev, cov_full, cov_fire, cov_disable, cov_wrap, cov_stream, cov_midrst);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && cov_three_valid > 1000 && cov_swap > 1000 && cov_dedup_entry > 1000
        && cov_dedup_prev > 100 && cov_full > 1000 && cov_fire > 1000 && cov_disable > 100 && cov_wrap > 100 && cov_stream > 100)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
