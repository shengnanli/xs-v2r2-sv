// =============================================================================
// verif/ut/SQData8Module/tb.sv —— golden 双例化逐拍比对
// -----------------------------------------------------------------------------
// ★ 本 tb 刻意不做"604 个输入每个独立均匀随机每拍打"★。
// 上一轮 StoreQueue 的教训:纯均匀随机让队列永远到不了边界,3 seed × 200k 全绿
// 却漏掉了 FM 当年报出来的那条链路。本模块真正有判别力的边界是:
//
//   B1 同拍读写同址(写是两拍流水 → 读到的必须是旧值,2 拍后才是新值)
//   B2 两个写口同址(优先级:口 1 胜口 0)—— golden 带断言禁止,但 FM 要逐位证,
//      所以这里**故意打**,并用 +define+SYNTHESIS 关掉两侧断言
//   B3 ★读地址越界(56..63)★ —— golden 的 64 深 mux 越界槽填的是 data[0] 而不是 0
//   B4 写地址越界(row=7 不存在)→ 不该改动任何条目
//   B5 needForward 稀疏(只 1~2 个候选)/ 全 1 / 全 0 —— 打穿前递优先树的各层
//   B6 掩码写与数据写**地址不同**(两条通路独立)
//
// 都靠定向激励压出来,并在收尾打印覆盖计数。任何一个计数为 0 = 这轮没打到,
// 视同没验。
//
// 复位后先做一次"全条目预热写",把 112 个**不复位**的阵列寄存器写满,再开始
// 比对 —— 否则两侧的不复位寄存器在 +vcs+initreg 下取到不同随机值,比对没有意义。
//
// ---------------------------------------------------------------------------
// ★ 判别力证据:注入真 bug 必须被报出来 ★
// ---------------------------------------------------------------------------
// "errors=0"只有在 tb 抓得住真 bug 时才有意义。下面 4 个变异体各只改 RTL 一处,
// 都是本模块最容易写错的地方;★变异体本身不进库★,这里记配方与实测数字,
// 便于任何人复现(改 rtl/memblock/SQData8Module.sv 的那一行,跑 seed=1 / 20000 拍):
//
//   M1 越界读落到条目 1 而不是条目 0                     → errors=3458
//      clamp_idx 的 `: 0`  改成 `: 1`
//   M2 写口优先级反转(口 0 胜口 1)                        → errors=2163
//      §2.5 的 `for (int w = 0; w < NUM_WRITE; w++)` 改成倒序
//   M3 前递优先级反转(取最老而不是最年轻)                 → errors=51773
//      §2.7 两层 for 都改成倒序
//   M4 给 112 个不复位的阵列寄存器加上复位                 → errors=4311
//      §2.5 的 always_ff 加 `or posedge reset` 与清零分支
//
// 同一条件下未变异版本 errors=0 / checks=418488。
// =============================================================================
`timescale 1ns/1ps
module tb;

  localparam int NE = 56;   // 条目数
  localparam int NW = 2;    // 写口
  localparam int NR = 2;    // 读口
  localparam int NF = 3;    // 前递口

  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  // --- 激励 ---
  logic [5:0]  raddr [NR];
  logic        data_wen   [NW];
  logic [5:0]  data_waddr [NW];
  logic [7:0]  data_wdata [NW];
  logic        mask_wen   [NW];
  logic [5:0]  mask_waddr [NW];
  logic        mask_wdata [NW];
  logic [55:0] needForward [NF][2];

  // --- 两侧输出 ---
  logic       g_rvalid [NR], i_rvalid [NR];
  logic [7:0] g_rdata  [NR], i_rdata  [NR];
  logic       g_fvalid [NF], i_fvalid [NF];
  logic [7:0] g_fdata  [NF], i_fdata  [NF];

  SQData8Module g_u (
    .clock(clk), .reset(rst),
    .io_raddr_0(raddr[0]), .io_raddr_1(raddr[1]),
    .io_rdata_0_valid(g_rvalid[0]), .io_rdata_0_data(g_rdata[0]),
    .io_rdata_1_valid(g_rvalid[1]), .io_rdata_1_data(g_rdata[1]),
    .io_data_wen_0(data_wen[0]), .io_data_wen_1(data_wen[1]),
    .io_data_waddr_0(data_waddr[0]), .io_data_waddr_1(data_waddr[1]),
    .io_data_wdata_0(data_wdata[0]), .io_data_wdata_1(data_wdata[1]),
    .io_mask_wen_0(mask_wen[0]), .io_mask_wen_1(mask_wen[1]),
    .io_mask_waddr_0(mask_waddr[0]), .io_mask_waddr_1(mask_waddr[1]),
    .io_mask_wdata_0(mask_wdata[0]), .io_mask_wdata_1(mask_wdata[1]),
    .io_needForward_0_0(needForward[0][0]), .io_needForward_0_1(needForward[0][1]),
    .io_needForward_1_0(needForward[1][0]), .io_needForward_1_1(needForward[1][1]),
    .io_needForward_2_0(needForward[2][0]), .io_needForward_2_1(needForward[2][1]),
    .io_forwardValid_0(g_fvalid[0]), .io_forwardValid_1(g_fvalid[1]), .io_forwardValid_2(g_fvalid[2]),
    .io_forwardData_0(g_fdata[0]), .io_forwardData_1(g_fdata[1]), .io_forwardData_2(g_fdata[2])
  );

  SQData8Module_xs i_u (
    .clock(clk), .reset(rst),
    .io_raddr_0(raddr[0]), .io_raddr_1(raddr[1]),
    .io_rdata_0_valid(i_rvalid[0]), .io_rdata_0_data(i_rdata[0]),
    .io_rdata_1_valid(i_rvalid[1]), .io_rdata_1_data(i_rdata[1]),
    .io_data_wen_0(data_wen[0]), .io_data_wen_1(data_wen[1]),
    .io_data_waddr_0(data_waddr[0]), .io_data_waddr_1(data_waddr[1]),
    .io_data_wdata_0(data_wdata[0]), .io_data_wdata_1(data_wdata[1]),
    .io_mask_wen_0(mask_wen[0]), .io_mask_wen_1(mask_wen[1]),
    .io_mask_waddr_0(mask_waddr[0]), .io_mask_waddr_1(mask_waddr[1]),
    .io_mask_wdata_0(mask_wdata[0]), .io_mask_wdata_1(mask_wdata[1]),
    .io_needForward_0_0(needForward[0][0]), .io_needForward_0_1(needForward[0][1]),
    .io_needForward_1_0(needForward[1][0]), .io_needForward_1_1(needForward[1][1]),
    .io_needForward_2_0(needForward[2][0]), .io_needForward_2_1(needForward[2][1]),
    .io_forwardValid_0(i_fvalid[0]), .io_forwardValid_1(i_fvalid[1]), .io_forwardValid_2(i_fvalid[2]),
    .io_forwardData_0(i_fdata[0]), .io_forwardData_1(i_fdata[1]), .io_forwardData_2(i_fdata[2])
  );

  // ---------------------------------------------------------------------------
  // 覆盖计数(见文件头 B1..B6)
  // ---------------------------------------------------------------------------
  int cov_rw_same     = 0;  // B1 读地址 == 本拍某个写地址
  int cov_wr_collide  = 0;  // B2 两个写口同址
  int cov_oob_read    = 0;  // B3 读地址 >= 56
  int cov_oob_write   = 0;  // B4 写地址 >= 56
  int cov_fwd_sparse  = 0;  // B5 候选数 1..2
  int cov_fwd_dense   = 0;  // B5 候选数 >= 32
  int cov_fwd_none    = 0;  // B5 候选数 0
  int cov_mask_split  = 0;  // B6 掩码写地址 != 数据写地址
  int cov_fwd_hit     = 0;  // 前递真的命中过
  int cov_fwd_oob_use = 0;  // B3 越界读真的取到了 entry0 且 entry0 与被查槽不同

  // 偏置的地址产生器:热点集中在 0..7 与 48..55,让同址碰撞频繁发生;
  // 另有一小片概率落在 56..63(越界)。
  function automatic logic [5:0] pick_addr(input bit allow_oob);
    int r;
    r = $urandom_range(0, 99);
    if (allow_oob && r < 6)  return 6'(56 + $urandom_range(0, 7));   // 越界
    else if (r < 40)         return 6'($urandom_range(0, 7));        // 低热点
    else if (r < 70)         return 6'(48 + $urandom_range(0, 7));   // 高热点
    else                     return 6'($urandom_range(0, 55));       // 均匀
  endfunction

  // 候选掩码:稀疏 / 全 1 / 全 0 / 均匀 四种形态轮着来。
  function automatic logic [55:0] pick_needfwd();
    int r, n;
    logic [55:0] m;
    r = $urandom_range(0, 99);
    m = '0;
    if (r < 25) begin                       // 稀疏:1~2 位
      n = $urandom_range(1, 2);
      for (int k = 0; k < n; k++) m[$urandom_range(0, 55)] = 1'b1;
    end else if (r < 35) m = '1;            // 全 1:打穿优先树全深度
    else if (r < 50)     m = '0;            // 全 0
    else for (int k = 0; k < 56; k++) m[k] = $urandom_range(0, 1);
    return m;
  endfunction

  bit warm = 1;   // 预热阶段:不比对

  // ★ 中途复位脉冲 ★:不打这个,"给不复位的寄存器加了复位"这类真 bug 在 UT 里
  // 完全不可观测(整轮只在 t=0 复位一次,而那时两侧都还没开始比对)。
  // 打完脉冲后立刻恢复比对:112 个阵列寄存器 + 64 个 s1 负载寄存器 + 2 个读地址
  // 寄存器 + 336 个 needCheckReg 都**不许**被复位清掉,清了就当场失配。
  int  cov_mid_reset = 0;

  // ---------------------------------------------------------------------------
  // 激励
  // ---------------------------------------------------------------------------
  int warm_i = 0;
  always @(negedge clk) begin
    if (rst) begin
      for (int w = 0; w < NW; w++) begin
        data_wen[w] <= 1'b0; mask_wen[w] <= 1'b0;
        data_waddr[w] <= '0; mask_waddr[w] <= '0;
        data_wdata[w] <= '0; mask_wdata[w] <= '0;
      end
      for (int r = 0; r < NR; r++) raddr[r] <= '0;
      for (int f = 0; f < NF; f++) begin needForward[f][0] <= '0; needForward[f][1] <= '0; end
      // 中途复位不重做预热:阵列内容不复位,预热只需要在上电后做一次。
      if (warm_i < NE) begin warm_i <= 0; warm <= 1; end
    end else if (warm_i < NE) begin
      // --- 预热:把 112 个不复位的阵列寄存器全部写一遍 ---
      // 只用写口 0,地址顺序扫描,数据/掩码同址,保证两侧起点一致。
      data_wen[0]   <= 1'b1; data_waddr[0] <= 6'(warm_i); data_wdata[0] <= 8'($urandom);
      mask_wen[0]   <= 1'b1; mask_waddr[0] <= 6'(warm_i); mask_wdata[0] <= 1'($urandom);
      data_wen[1]   <= 1'b0; mask_wen[1]   <= 1'b0;
      for (int r = 0; r < NR; r++) raddr[r] <= '0;
      for (int f = 0; f < NF; f++) begin needForward[f][0] <= '0; needForward[f][1] <= '0; end
      warm_i <= warm_i + 1;
    end else begin
      // 预热写要 2 拍才落到阵列,再多等 2 拍才开比对。
      if (warm_i < NE + 3) warm_i <= warm_i + 1; else warm <= 0;

      // --- 数据写口 ---
      data_wen[0]   <= $urandom_range(0, 1);
      data_wen[1]   <= $urandom_range(0, 1);
      data_waddr[0] <= pick_addr(1);
      // ★ B2:约 8% 的拍子让两个写口撞同一个地址,专门打优先级 ★
      if ($urandom_range(0, 99) < 8) data_waddr[1] <= data_waddr[0];
      else                           data_waddr[1] <= pick_addr(1);
      data_wdata[0] <= 8'($urandom);
      data_wdata[1] <= 8'($urandom);

      // --- 掩码写口(★与数据写口地址独立★,B6)---
      mask_wen[0]   <= $urandom_range(0, 1);
      mask_wen[1]   <= $urandom_range(0, 1);
      mask_waddr[0] <= pick_addr(1);
      if ($urandom_range(0, 99) < 8) mask_waddr[1] <= mask_waddr[0];
      else                           mask_waddr[1] <= pick_addr(1);
      mask_wdata[0] <= 1'($urandom);
      mask_wdata[1] <= 1'($urandom);

      // --- 读口 ---
      // ★ B1:约 35% 的拍子把读地址钉到本拍的某个写地址上 ★
      for (int r = 0; r < NR; r++) begin
        if ($urandom_range(0, 99) < 35) raddr[r] <= data_waddr[0];
        else                            raddr[r] <= pick_addr(1);
      end

      // --- 前递候选 ---
      for (int f = 0; f < NF; f++) begin
        needForward[f][0] <= pick_needfwd();
        needForward[f][1] <= pick_needfwd();
      end
    end
  end

  // ---------------------------------------------------------------------------
  // 覆盖统计
  // ---------------------------------------------------------------------------
  always @(posedge clk) if (!rst && !warm) begin
    int nf_pop;
    if (data_wen[0] && data_wen[1] && data_waddr[0] == data_waddr[1]) cov_wr_collide++;
    if (mask_wen[0] && mask_wen[1] && mask_waddr[0] == mask_waddr[1]) cov_wr_collide++;
    for (int r = 0; r < NR; r++) begin
      if (raddr[r] >= 56) cov_oob_read++;
      for (int w = 0; w < NW; w++)
        if (data_wen[w] && raddr[r] == data_waddr[w]) cov_rw_same++;
    end
    for (int w = 0; w < NW; w++) begin
      if (data_wen[w] && data_waddr[w] >= 56) cov_oob_write++;
      if (data_wen[w] && mask_wen[w] && data_waddr[w] != mask_waddr[w]) cov_mask_split++;
    end
    for (int f = 0; f < NF; f++) begin
      nf_pop = $countones(needForward[f][0]) + $countones(needForward[f][1]);
      if (nf_pop == 0)                     cov_fwd_none++;
      else if (nf_pop <= 2)                cov_fwd_sparse++;
      else if (nf_pop >= 32)               cov_fwd_dense++;
      if (g_fvalid[f])                     cov_fwd_hit++;
    end
  end

  // ---------------------------------------------------------------------------
  // 逐拍比对(输出 + 内部阵列状态)
  // ---------------------------------------------------------------------------
  `define CK(nm, g, i) \
    begin checks++; \
      if ((g) !== (i)) begin errors++; \
        if (errors <= 60) $display("[%0t] %s g=%h i=%h", $time, nm, (g), (i)); end end

  always @(negedge clk) if (!rst && !warm) begin
    #4;
    `CK("rdata_0_valid", g_rvalid[0], i_rvalid[0])
    `CK("rdata_0_data",  g_rdata[0],  i_rdata[0])
    `CK("rdata_1_valid", g_rvalid[1], i_rvalid[1])
    `CK("rdata_1_data",  g_rdata[1],  i_rdata[1])
    `CK("fwdValid_0",    g_fvalid[0], i_fvalid[0])
    `CK("fwdValid_1",    g_fvalid[1], i_fvalid[1])
    `CK("fwdValid_2",    g_fvalid[2], i_fvalid[2])
    // forwardData 在 forwardValid=0 时 golden 也给出确定值(叶子 0 的数据),
    // 所以无条件比 —— 这正是"越界/未命中缺省值"那条陷阱的检查点。
    `CK("fwdData_0",     g_fdata[0],  i_fdata[0])
    `CK("fwdData_1",     g_fdata[1],  i_fdata[1])
    `CK("fwdData_2",     g_fdata[2],  i_fdata[2])

    // 内部阵列逐条比 —— 让失配在传到输出之前就被抓住,便于定位。
    `CK("entry0.valid",  g_u.data_0_valid,  i_u.u_core.entries[0].valid)
    `CK("entry0.data",   g_u.data_0_data,   i_u.u_core.entries[0].data)
    `CK("entry7.valid",  g_u.data_7_valid,  i_u.u_core.entries[7].valid)
    `CK("entry7.data",   g_u.data_7_data,   i_u.u_core.entries[7].data)
    `CK("entry8.data",   g_u.data_8_data,   i_u.u_core.entries[8].data)
    `CK("entry55.valid", g_u.data_55_valid, i_u.u_core.entries[55].valid)
    `CK("entry55.data",  g_u.data_55_data,  i_u.u_core.entries[55].data)
    // 写流水 S1 控制位(本模块唯一的异步复位寄存器组)
    `CK("s1_dwen0_b0",   g_u.s1_wenVec_r_0,   i_u.u_core.s1_data_wen[0][0])
    `CK("s1_dwen1_b3",   g_u.s1_wenVec_r_1_3, i_u.u_core.s1_data_wen[1][3])
    `CK("s1_mwen0_b5",   g_u.s1_wenVec_r_2_5, i_u.u_core.s1_mask_wen[0][5])
    `CK("s1_mwen1_b7",   g_u.s1_wenVec_r_3_7, i_u.u_core.s1_mask_wen[1][7])
  end

  // ---------------------------------------------------------------------------
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    fork
      // ★ 中途复位脉冲 ★ —— 每 ~3000 拍打 2 拍。见 tb 中部注释。
      forever begin
        repeat (2800 + $urandom_range(0, 400)) @(posedge clk);
        rst = 1; cov_mid_reset++; repeat (2) @(posedge clk); rst = 0;
      end
    join_none
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    $display("COVERAGE rw_same=%0d wr_collide=%0d oob_read=%0d oob_write=%0d",
             cov_rw_same, cov_wr_collide, cov_oob_read, cov_oob_write);
    $display("COVERAGE fwd_none=%0d fwd_sparse=%0d fwd_dense=%0d fwd_hit=%0d mask_split=%0d",
             cov_fwd_none, cov_fwd_sparse, cov_fwd_dense, cov_fwd_hit, cov_mask_split);
    $display("COVERAGE mid_reset=%0d", cov_mid_reset);
    // 覆盖判据:任何一类边界一次都没打到,errors=0 也不算通过。
    if (errors == 0 && checks > 1000 &&
        cov_rw_same    > 100 && cov_wr_collide > 100 &&
        cov_oob_read   > 100 && cov_oob_write  > 100 &&
        cov_fwd_none   > 100 && cov_fwd_sparse > 100 &&
        cov_fwd_dense  > 100 && cov_fwd_hit    > 100 && cov_mask_split > 100 &&
        cov_mid_reset  > 2)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
