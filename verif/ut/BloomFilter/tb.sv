// =============================================================================
// BloomFilter UT —— golden BloomFilter 与重写 BloomFilter_xs 双例化同激励，
// 逐拍比对全部 6 个输出端口。
//
// ★ 激励为什么不是「每个输入独立均匀随机」★
// 本模块的全部判别力都在**同址撞车**上：
//   - set 与 clr 同拍点同一位 → 验「clr 压过 set」的优先级；
//   - query 与 set/clr 同拍点同一位 → 验 bypass（读 data_next 而不是 data）；
//   - query_valid=0 的拍 → 验 res 寄存器的**使能**（无效拍必须保持旧值）。
// 地址 12 位 / 4096 位图，三个 query 口若各自均匀随机，两口撞同一位的概率
// 2^-12，set 与 query 撞车 200k 拍里也只有几十次、而且几乎全落在「该位本来
// 就是 1」的无区分情形上 —— 那样的 errors=0 什么都没验到。
// 所以地址取值走三段分布（rand_addr）：
//   55% 落在 16 个地址的密集池  → 制造 set/clr/query 三方撞车
//   25% 落在 256 个地址的中池   → 让位图里有一片「有 1 有 0」的活跃区
//   20% 全 12 位随机            → 覆盖整张位图，验证没有隐含的地址折叠
// 另外每 512 拍左右做一次「把密集池整片 clr 干净」的定向序列，制造
// 「query 命中刚被清掉的位」这一最容易暴露 bypass 方向错误的情形。
//
// ★ 不复位寄存器：暖机窗口与「连复位期间一起比」★
// golden 的 io_resp_*_bits_res_r 是**不复位**寄存器（见 rtl 头注释 §2.3）。
// `+vcs+initreg+random` 下 golden 侧与重写侧的上电值互相独立，比对会报一片假
// 失配。所以前 WARMUP 拍强制三个 query 口全 valid，把三个 res 都写成确定值。
//
// ★ 暖机之后必须**连复位期间也比**，否则复位域的判别力被暖没了 ★
// 第一版写成「只在 !rst 时比」，结果 mutants.py 的 M3（给 res 加复位）跑 20k 拍
// errors=0 —— 漏检。根因：复位期间不比，而复位一放开、data 已被清成全 0，两侧
// 第一次 query 又读回同一个 0，差异当场被抹平。改法有两条，缺一不可：
//   (1) 复位期间**照常打激励**（不把输入清零）；
//   (2) 比对窗口按**绝对拍数 tick** 开闸，开了之后连 rst 高的拍也一起比。
// 这样 golden 的 res 在复位期间继续跟着 query 走、变异件被按成 0，当场炸。
// 改完 M3 从 errors=0 变成 errors>0（见 mutants.py 的输出）。
// =============================================================================
`timescale 1ns/1ps

module tb;

  localparam int WARMUP = 24;   // 暖机拍数：足够把三个 res 都写成确定值

  int unsigned NCYCLES = 200000;
  bit   clk = 0;
  logic rst;
  int   errors  = 0;
  longint checks = 0;
  longint cyc   = 0;    // 只数 !rst 的拍（覆盖统计用）
  longint tick  = 0;    // 数**所有**拍（比对开闸用，含复位期间）

  always #5 clk = ~clk;

  // 三段分布：密集池制造撞车，中池制造活跃区，全随机覆盖整张位图。
  function automatic logic [11:0] rand_addr();
    int unsigned r = $urandom_range(0, 99);
    if (r < 55)      return 12'($urandom_range(0, 15));
    else if (r < 80) return 12'($urandom_range(0, 255));
    else             return 12'($urandom);
  endfunction

  // ---- DUT 输入（两侧共用同一组激励）----
  logic        io_set_valid;
  logic [11:0] io_set_bits_addr;
  logic        io_clr_valid;
  logic [11:0] io_clr_bits_addr;
  logic        io_query_0_valid;
  logic [11:0] io_query_0_bits_addr;
  logic        io_query_1_valid;
  logic [11:0] io_query_1_bits_addr;
  logic        io_query_2_valid;
  logic [11:0] io_query_2_bits_addr;

  // ---- golden 侧输出 ----
  logic g_io_resp_0_valid, g_io_resp_0_bits_res;
  logic g_io_resp_1_valid, g_io_resp_1_bits_res;
  logic g_io_resp_2_valid, g_io_resp_2_bits_res;
  // ---- 重写侧输出 ----
  logic i_io_resp_0_valid, i_io_resp_0_bits_res;
  logic i_io_resp_1_valid, i_io_resp_1_bits_res;
  logic i_io_resp_2_valid, i_io_resp_2_bits_res;

  BloomFilter u_golden (
    .clock(clk), .reset(rst),
    .io_set_valid(io_set_valid), .io_set_bits_addr(io_set_bits_addr),
    .io_clr_valid(io_clr_valid), .io_clr_bits_addr(io_clr_bits_addr),
    .io_query_0_valid(io_query_0_valid), .io_query_0_bits_addr(io_query_0_bits_addr),
    .io_query_1_valid(io_query_1_valid), .io_query_1_bits_addr(io_query_1_bits_addr),
    .io_query_2_valid(io_query_2_valid), .io_query_2_bits_addr(io_query_2_bits_addr),
    .io_resp_0_valid(g_io_resp_0_valid), .io_resp_0_bits_res(g_io_resp_0_bits_res),
    .io_resp_1_valid(g_io_resp_1_valid), .io_resp_1_bits_res(g_io_resp_1_bits_res),
    .io_resp_2_valid(g_io_resp_2_valid), .io_resp_2_bits_res(g_io_resp_2_bits_res)
  );

  BloomFilter_xs u_impl (
    .clock(clk), .reset(rst),
    .io_set_valid(io_set_valid), .io_set_bits_addr(io_set_bits_addr),
    .io_clr_valid(io_clr_valid), .io_clr_bits_addr(io_clr_bits_addr),
    .io_query_0_valid(io_query_0_valid), .io_query_0_bits_addr(io_query_0_bits_addr),
    .io_query_1_valid(io_query_1_valid), .io_query_1_bits_addr(io_query_1_bits_addr),
    .io_query_2_valid(io_query_2_valid), .io_query_2_bits_addr(io_query_2_bits_addr),
    .io_resp_0_valid(i_io_resp_0_valid), .io_resp_0_bits_res(i_io_resp_0_bits_res),
    .io_resp_1_valid(i_io_resp_1_valid), .io_resp_1_bits_res(i_io_resp_1_bits_res),
    .io_resp_2_valid(i_io_resp_2_valid), .io_resp_2_bits_res(i_io_resp_2_bits_res)
  );

  // ---------------------------------------------------------------------------
  // 激励
  // ---------------------------------------------------------------------------
  // 定向序列状态：>0 时正在做「把密集池整片清干净」的扫描
  int sweep = 0;

  task automatic drive();
    logic [11:0] a;
    if (sweep > 0) begin
      // 定向：连续 16 拍逐个 clr 密集池地址，同时让 query 追着同一个地址打，
      // 制造「query 命中刚被清掉/正在被清的位」。
      a                    = 12'(16 - sweep);
      io_clr_valid         = 1'b1;
      io_clr_bits_addr     = a;
      io_set_valid         = ($urandom_range(0, 3) == 0);
      io_set_bits_addr     = a;                 // 同址 set —— 验 clr 优先
      io_query_0_valid     = 1'b1;
      io_query_0_bits_addr = a;                 // 同址 query —— 验 bypass
      io_query_1_valid     = 1'b1;
      io_query_1_bits_addr = rand_addr();
      io_query_2_valid     = ($urandom_range(0, 3) != 0);
      io_query_2_bits_addr = a;
      sweep--;
    end else begin
      io_set_valid         = ($urandom_range(0, 99) < 45);
      io_set_bits_addr     = rand_addr();
      io_clr_valid         = ($urandom_range(0, 99) < 35);
      // 一半概率让 clr 与 set 同址 —— 优先级的唯一判别点
      io_clr_bits_addr     = ($urandom_range(0, 1)) ? io_set_bits_addr : rand_addr();
      io_query_0_valid     = ($urandom_range(0, 99) < 70);
      // 一半概率让 query 与 set/clr 同址 —— bypass 的唯一判别点
      io_query_0_bits_addr = ($urandom_range(0, 2) == 0) ? io_set_bits_addr :
                             ($urandom_range(0, 2) == 0) ? io_clr_bits_addr : rand_addr();
      io_query_1_valid     = ($urandom_range(0, 99) < 55);
      io_query_1_bits_addr = ($urandom_range(0, 2) == 0) ? io_clr_bits_addr : rand_addr();
      io_query_2_valid     = ($urandom_range(0, 99) < 40);
      io_query_2_bits_addr = rand_addr();
      if ($urandom_range(0, 511) == 0) sweep = 16;
    end
  endtask

  // ★ 复位期间也照常打激励 ★：res 寄存器不复位，只有让它在复位期间继续被写，
  // 「给 res 加复位」这种变异才有可观测差异。
  always @(negedge clk) begin
    if (tick < WARMUP) begin
      // 暖机：三个 query 口全 valid，把两侧的不复位 res 寄存器写成确定值
      io_set_valid = ($urandom_range(0, 1) == 0); io_set_bits_addr = rand_addr();
      io_clr_valid = ($urandom_range(0, 1) == 0); io_clr_bits_addr = rand_addr();
      io_query_0_valid = 1'b1; io_query_0_bits_addr = rand_addr();
      io_query_1_valid = 1'b1; io_query_1_bits_addr = rand_addr();
      io_query_2_valid = 1'b1; io_query_2_bits_addr = rand_addr();
      sweep = 0;
    end else begin
      drive();
    end
  end

  // ---------------------------------------------------------------------------
  // 逐拍比对
  //   valid：复位寄存器，从第一拍就比
  //   res  ：不复位寄存器，暖机后才比（理由见文件头）
  // ---------------------------------------------------------------------------
  `define CHK(nm, g, i) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors < 40) $display("[%0t] cyc=%0d %s mismatch: g=%h i=%h", $time, cyc, nm, (g), (i)); \
    end end

  always @(posedge clk) begin
    #1;
    if (tick >= WARMUP) begin   // 开闸后连 rst 高的拍也一起比，理由见文件头
      `CHK("io_resp_0_valid", g_io_resp_0_valid, i_io_resp_0_valid)
      `CHK("io_resp_1_valid", g_io_resp_1_valid, i_io_resp_1_valid)
      `CHK("io_resp_2_valid", g_io_resp_2_valid, i_io_resp_2_valid)
      `CHK("io_resp_0_bits_res", g_io_resp_0_bits_res, i_io_resp_0_bits_res)
      `CHK("io_resp_1_bits_res", g_io_resp_1_bits_res, i_io_resp_1_bits_res)
      `CHK("io_resp_2_bits_res", g_io_resp_2_bits_res, i_io_resp_2_bits_res)
    end
  end

  // ---------------------------------------------------------------------------
  // 覆盖事件（每项必须 > 0，否则对应机制根本没被激励到）
  // 只看激励与 golden 侧，不看重写侧，免得自证。
  // ---------------------------------------------------------------------------
  longint cov_set_clr_same   = 0;  // set 与 clr 同拍同址 → clr 优先的唯一判别点
  longint cov_q_hits_set     = 0;  // query 与 set 同拍同址 → bypass 读到 1
  longint cov_q_hits_clr     = 0;  // query 与 clr 同拍同址 → bypass 读到 0
  longint cov_q_hits_clr_was1= 0;  // 且该位原本是 1 → bypass 方向错误必被抓
  longint cov_q_idle_res1    = 0;  // query 无效但上一拍 res=1 → res 使能的判别点
  longint cov_res_one        = 0;  // golden 输出过 1
  longint cov_res_zero       = 0;  // golden 输出过 0
  longint cov_reset_mid      = 0;  // 运行中异步复位次数

  // 位图影子模型：只用来判断「被 clr 的位原本是不是 1」这类覆盖条件。
  // 它不参与正确性判定（正确性一律以 golden 输出为准）。
  logic [4095:0] shadow = '0;

  always @(negedge clk) begin
    #1;
    if (!rst) begin
      if (io_set_valid && io_clr_valid && io_set_bits_addr == io_clr_bits_addr)
        cov_set_clr_same++;
      for (int q = 0; q < 3; q++) begin
        logic       qv;
        logic [11:0] qa;
        case (q)
          0: begin qv = io_query_0_valid; qa = io_query_0_bits_addr; end
          1: begin qv = io_query_1_valid; qa = io_query_1_bits_addr; end
          default: begin qv = io_query_2_valid; qa = io_query_2_bits_addr; end
        endcase
        if (qv && io_set_valid && qa == io_set_bits_addr && !(io_clr_valid && qa == io_clr_bits_addr))
          cov_q_hits_set++;
        if (qv && io_clr_valid && qa == io_clr_bits_addr) begin
          cov_q_hits_clr++;
          if (shadow[qa]) cov_q_hits_clr_was1++;
        end
      end
      if (!io_query_0_valid && g_io_resp_0_bits_res === 1'b1) cov_q_idle_res1++;
      if (g_io_resp_0_valid && g_io_resp_0_bits_res === 1'b1) cov_res_one++;
      if (g_io_resp_0_valid && g_io_resp_0_bits_res === 1'b0) cov_res_zero++;
    end
  end

  // 影子位图跟随激励（与 DUT 同一时刻更新；仅供覆盖统计）
  always @(posedge clk) begin
    if (rst) shadow <= '0;
    else begin
      if (io_set_valid) shadow[io_set_bits_addr] <= 1'b1;
      if (io_clr_valid) shadow[io_clr_bits_addr] <= 1'b0;  // clr 后写 = clr 优先
    end
  end

  always @(posedge clk) begin tick++; if (!rst) cyc++; end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1'b1;
    repeat (4) @(posedge clk);
    @(negedge clk) rst = 1'b0;
    repeat (NCYCLES / 2) @(posedge clk);
    // 运行中再来一次异步复位：验证「data/valid 复位、res 不复位」这个结构。
    // 若重写件给 res 也加了复位（mutants.py M3），这里立刻炸。
    @(negedge clk) rst = 1'b1; cov_reset_mid++;
    repeat (3) @(posedge clk);
    @(negedge clk) rst = 1'b0;
    repeat (NCYCLES / 2) @(posedge clk);

    $display("--- COVERAGE (每项必须 > 0) ---");
    $display("  set/clr 同拍同址        : %0d", cov_set_clr_same);
    $display("  query 撞 set(bypass=1)  : %0d", cov_q_hits_set);
    $display("  query 撞 clr(bypass=0)  : %0d", cov_q_hits_clr);
    $display("  ...且该位原本为 1       : %0d", cov_q_hits_clr_was1);
    $display("  query 无效而 res 保持 1 : %0d", cov_q_idle_res1);
    $display("  golden res 输出过 1     : %0d", cov_res_one);
    $display("  golden res 输出过 0     : %0d", cov_res_zero);
    $display("  运行中异步复位          : %0d", cov_reset_mid);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 &&
        cov_set_clr_same > 0 && cov_q_hits_set > 0 && cov_q_hits_clr > 0 &&
        cov_q_hits_clr_was1 > 0 && cov_q_idle_res1 > 0 &&
        cov_res_one > 0 && cov_res_zero > 0 && cov_reset_mid > 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED (errors=%0d 或覆盖项为 0)", errors);
    $finish;
  end

endmodule
