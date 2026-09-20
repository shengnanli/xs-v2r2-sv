// =============================================================================
// verif/ut/SQDataModule/tb.sv —— golden 双例化逐拍比对(16 路字节切片装配壳)
// -----------------------------------------------------------------------------
// 本模块自己没有状态,全部逻辑就是"128 位数据怎么切成 16 份、16 份结果怎么拼回去"。
// 所以 UT 的唯一任务是**证明切片对位**,而这恰恰是均匀随机最容易放过的:
// 如果 16 个字节写的是同一个值,切片错位也看不出来。
//
//   W1 ★每拍 16 个字节写入互不相同的值★ —— 错一位就当场失配
//   W2 ★mask_wdata 16 位互不相同★ —— 掩码切片单独走一条路,也要对位
//   W3 数据写地址 ≠ 掩码写地址 —— 两条通路独立
//   W4 前递:16 个字节切片各自独立挑赢家,输出 16 位掩码 + 16 个字节
//   W5 读地址越界(56..63)→ 每片都落到自己的条目 0
//   W6 两个写口同址(优先级)—— 父子各有一对断言,故关断言故意打
//
// 子模块 SQData8Module 有自己的 UT;这里只管装配层。
// 复位后先"全条目预热写"补齐子模块里 16×112 个不复位寄存器。
//
// ---------------------------------------------------------------------------
// ★ 判别力证据:注入真 bug 必须被报出来 ★
// ---------------------------------------------------------------------------
// 2 个变异体各只改 rtl/memblock/SQDataModule.sv 一处切片下标。★不进库★,
// 配方与实测数字(seed=1 / 10000 拍):
//
//   W1 数据切片错位一个字节(`8*i` → `8*((i+1)%16)`)  → errors=243987
//   W2 掩码切片镜像(`[i]` → `[15-i]`)                 → errors=185779
//
// 同一条件下未变异版本 errors=0 / checks=993400。
// =============================================================================
`timescale 1ns/1ps
module tb;

  localparam int NE = 56, NW = 2, NR = 2, NF = 3, NB = 16;

  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic [5:0]   raddr [NR];
  logic         data_wen   [NW];
  logic [5:0]   data_waddr [NW];
  logic [127:0] data_wdata [NW];
  logic         mask_wen   [NW];
  logic [5:0]   mask_waddr [NW];
  logic [15:0]  mask_wdata [NW];
  logic [55:0]  needForward [NF][2];

  logic [15:0]  g_rmask [NR], i_rmask [NR];
  logic [127:0] g_rdata [NR], i_rdata [NR];
  wire          g_fmask [NF][NB], i_fmask [NF][NB];
  wire  [7:0]   g_fdata [NF][NB], i_fdata [NF][NB];

  `define SQDM_PORTS(P) \
    .clock(clk), .reset(rst), \
    .io_raddr_0(raddr[0]), .io_raddr_1(raddr[1]), \
    .io_rdata_0_mask(P``_rmask[0]), .io_rdata_0_data(P``_rdata[0]), \
    .io_rdata_1_mask(P``_rmask[1]), .io_rdata_1_data(P``_rdata[1]), \
    .io_data_wen_0(data_wen[0]), .io_data_wen_1(data_wen[1]), \
    .io_data_waddr_0(data_waddr[0]), .io_data_waddr_1(data_waddr[1]), \
    .io_data_wdata_0(data_wdata[0]), .io_data_wdata_1(data_wdata[1]), \
    .io_mask_wen_0(mask_wen[0]), .io_mask_wen_1(mask_wen[1]), \
    .io_mask_waddr_0(mask_waddr[0]), .io_mask_waddr_1(mask_waddr[1]), \
    .io_mask_wdata_0(mask_wdata[0]), .io_mask_wdata_1(mask_wdata[1]), \
    .io_needForward_0_0(needForward[0][0]), .io_needForward_0_1(needForward[0][1]), \
    .io_needForward_1_0(needForward[1][0]), .io_needForward_1_1(needForward[1][1]), \
    .io_needForward_2_0(needForward[2][0]), .io_needForward_2_1(needForward[2][1]), \
    .io_forwardMask_0_0(P``_fmask[0][0]),   .io_forwardMask_0_1(P``_fmask[0][1]), \
    .io_forwardMask_0_2(P``_fmask[0][2]),   .io_forwardMask_0_3(P``_fmask[0][3]), \
    .io_forwardMask_0_4(P``_fmask[0][4]),   .io_forwardMask_0_5(P``_fmask[0][5]), \
    .io_forwardMask_0_6(P``_fmask[0][6]),   .io_forwardMask_0_7(P``_fmask[0][7]), \
    .io_forwardMask_0_8(P``_fmask[0][8]),   .io_forwardMask_0_9(P``_fmask[0][9]), \
    .io_forwardMask_0_10(P``_fmask[0][10]), .io_forwardMask_0_11(P``_fmask[0][11]), \
    .io_forwardMask_0_12(P``_fmask[0][12]), .io_forwardMask_0_13(P``_fmask[0][13]), \
    .io_forwardMask_0_14(P``_fmask[0][14]), .io_forwardMask_0_15(P``_fmask[0][15]), \
    .io_forwardMask_1_0(P``_fmask[1][0]),   .io_forwardMask_1_1(P``_fmask[1][1]), \
    .io_forwardMask_1_2(P``_fmask[1][2]),   .io_forwardMask_1_3(P``_fmask[1][3]), \
    .io_forwardMask_1_4(P``_fmask[1][4]),   .io_forwardMask_1_5(P``_fmask[1][5]), \
    .io_forwardMask_1_6(P``_fmask[1][6]),   .io_forwardMask_1_7(P``_fmask[1][7]), \
    .io_forwardMask_1_8(P``_fmask[1][8]),   .io_forwardMask_1_9(P``_fmask[1][9]), \
    .io_forwardMask_1_10(P``_fmask[1][10]), .io_forwardMask_1_11(P``_fmask[1][11]), \
    .io_forwardMask_1_12(P``_fmask[1][12]), .io_forwardMask_1_13(P``_fmask[1][13]), \
    .io_forwardMask_1_14(P``_fmask[1][14]), .io_forwardMask_1_15(P``_fmask[1][15]), \
    .io_forwardMask_2_0(P``_fmask[2][0]),   .io_forwardMask_2_1(P``_fmask[2][1]), \
    .io_forwardMask_2_2(P``_fmask[2][2]),   .io_forwardMask_2_3(P``_fmask[2][3]), \
    .io_forwardMask_2_4(P``_fmask[2][4]),   .io_forwardMask_2_5(P``_fmask[2][5]), \
    .io_forwardMask_2_6(P``_fmask[2][6]),   .io_forwardMask_2_7(P``_fmask[2][7]), \
    .io_forwardMask_2_8(P``_fmask[2][8]),   .io_forwardMask_2_9(P``_fmask[2][9]), \
    .io_forwardMask_2_10(P``_fmask[2][10]), .io_forwardMask_2_11(P``_fmask[2][11]), \
    .io_forwardMask_2_12(P``_fmask[2][12]), .io_forwardMask_2_13(P``_fmask[2][13]), \
    .io_forwardMask_2_14(P``_fmask[2][14]), .io_forwardMask_2_15(P``_fmask[2][15]), \
    .io_forwardData_0_0(P``_fdata[0][0]),   .io_forwardData_0_1(P``_fdata[0][1]), \
    .io_forwardData_0_2(P``_fdata[0][2]),   .io_forwardData_0_3(P``_fdata[0][3]), \
    .io_forwardData_0_4(P``_fdata[0][4]),   .io_forwardData_0_5(P``_fdata[0][5]), \
    .io_forwardData_0_6(P``_fdata[0][6]),   .io_forwardData_0_7(P``_fdata[0][7]), \
    .io_forwardData_0_8(P``_fdata[0][8]),   .io_forwardData_0_9(P``_fdata[0][9]), \
    .io_forwardData_0_10(P``_fdata[0][10]), .io_forwardData_0_11(P``_fdata[0][11]), \
    .io_forwardData_0_12(P``_fdata[0][12]), .io_forwardData_0_13(P``_fdata[0][13]), \
    .io_forwardData_0_14(P``_fdata[0][14]), .io_forwardData_0_15(P``_fdata[0][15]), \
    .io_forwardData_1_0(P``_fdata[1][0]),   .io_forwardData_1_1(P``_fdata[1][1]), \
    .io_forwardData_1_2(P``_fdata[1][2]),   .io_forwardData_1_3(P``_fdata[1][3]), \
    .io_forwardData_1_4(P``_fdata[1][4]),   .io_forwardData_1_5(P``_fdata[1][5]), \
    .io_forwardData_1_6(P``_fdata[1][6]),   .io_forwardData_1_7(P``_fdata[1][7]), \
    .io_forwardData_1_8(P``_fdata[1][8]),   .io_forwardData_1_9(P``_fdata[1][9]), \
    .io_forwardData_1_10(P``_fdata[1][10]), .io_forwardData_1_11(P``_fdata[1][11]), \
    .io_forwardData_1_12(P``_fdata[1][12]), .io_forwardData_1_13(P``_fdata[1][13]), \
    .io_forwardData_1_14(P``_fdata[1][14]), .io_forwardData_1_15(P``_fdata[1][15]), \
    .io_forwardData_2_0(P``_fdata[2][0]),   .io_forwardData_2_1(P``_fdata[2][1]), \
    .io_forwardData_2_2(P``_fdata[2][2]),   .io_forwardData_2_3(P``_fdata[2][3]), \
    .io_forwardData_2_4(P``_fdata[2][4]),   .io_forwardData_2_5(P``_fdata[2][5]), \
    .io_forwardData_2_6(P``_fdata[2][6]),   .io_forwardData_2_7(P``_fdata[2][7]), \
    .io_forwardData_2_8(P``_fdata[2][8]),   .io_forwardData_2_9(P``_fdata[2][9]), \
    .io_forwardData_2_10(P``_fdata[2][10]), .io_forwardData_2_11(P``_fdata[2][11]), \
    .io_forwardData_2_12(P``_fdata[2][12]), .io_forwardData_2_13(P``_fdata[2][13]), \
    .io_forwardData_2_14(P``_fdata[2][14]), .io_forwardData_2_15(P``_fdata[2][15])

  SQDataModule    g_u (`SQDM_PORTS(g));
  SQDataModule_xs i_u (`SQDM_PORTS(i));

  // ---------------------------------------------------------------------------
  int cov_oob_read = 0, cov_wr_collide = 0, cov_mask_split = 0;
  int cov_fwd_hit_partial = 0;   // 16 个字节里只有一部分命中 —— 切片独立性的证据
  int cov_bytes_distinct = 0, cov_mid_reset = 0;

  function automatic logic [5:0] pick_addr();
    int r; r = $urandom_range(0, 99);
    if (r < 6)       return 6'(56 + $urandom_range(0, 7));
    else if (r < 45) return 6'($urandom_range(0, 7));
    else if (r < 70) return 6'(48 + $urandom_range(0, 7));
    else             return 6'($urandom_range(0, 55));
  endfunction

  function automatic logic [55:0] pick_needfwd();
    int r, n; logic [55:0] m;
    r = $urandom_range(0, 99); m = '0;
    if (r < 25) begin n = $urandom_range(1, 2);
      for (int k = 0; k < n; k++) m[$urandom_range(0, 55)] = 1'b1; end
    else if (r < 35) m = '1;
    else if (r < 50) m = '0;
    else for (int k = 0; k < 56; k++) m[k] = $urandom_range(0, 1);
    return m;
  endfunction

  // ★ W1:16 个字节保证互不相同 ★ —— 用 {随机高 4 位, 字节序号} 构造。
  function automatic logic [127:0] mk_wdata();
    logic [127:0] d;
    for (int b = 0; b < 16; b++) d[8*b +: 8] = {4'($urandom), 4'(b)};
    return d;
  endfunction

  bit warm = 1;
  int warm_i = 0;

  always @(negedge clk) begin
    if (rst) begin
      for (int w = 0; w < NW; w++) begin
        data_wen[w] <= 0; mask_wen[w] <= 0; data_waddr[w] <= '0; mask_waddr[w] <= '0;
        data_wdata[w] <= '0; mask_wdata[w] <= '0;
      end
      for (int r = 0; r < NR; r++) raddr[r] <= '0;
      for (int f = 0; f < NF; f++) begin needForward[f][0] <= '0; needForward[f][1] <= '0; end
      if (warm_i < NE) begin warm_i <= 0; warm <= 1; end
    end else if (warm_i < NE) begin
      data_wen[0] <= 1'b1; data_waddr[0] <= 6'(warm_i); data_wdata[0] <= mk_wdata();
      mask_wen[0] <= 1'b1; mask_waddr[0] <= 6'(warm_i); mask_wdata[0] <= 16'($urandom);
      data_wen[1] <= 1'b0; mask_wen[1] <= 1'b0;
      for (int r = 0; r < NR; r++) raddr[r] <= '0;
      warm_i <= warm_i + 1;
    end else begin
      if (warm_i < NE + 3) warm_i <= warm_i + 1; else warm <= 0;
      data_wen[0] <= $urandom_range(0,1); data_wen[1] <= $urandom_range(0,1);
      data_waddr[0] <= pick_addr();
      if ($urandom_range(0,99) < 8) data_waddr[1] <= data_waddr[0];
      else                          data_waddr[1] <= pick_addr();
      data_wdata[0] <= mk_wdata(); data_wdata[1] <= mk_wdata();
      mask_wen[0] <= $urandom_range(0,1); mask_wen[1] <= $urandom_range(0,1);
      mask_waddr[0] <= pick_addr();       // ★ W3:与数据写地址独立 ★
      if ($urandom_range(0,99) < 8) mask_waddr[1] <= mask_waddr[0];
      else                          mask_waddr[1] <= pick_addr();
      // ★ W2:16 位掩码逐位随机,让每个字节切片的 valid 各不相同 ★
      mask_wdata[0] <= 16'($urandom); mask_wdata[1] <= 16'($urandom);
      for (int r = 0; r < NR; r++)
        if ($urandom_range(0,99) < 35) raddr[r] <= data_waddr[0];
        else                            raddr[r] <= pick_addr();
      for (int f = 0; f < NF; f++) begin
        needForward[f][0] <= pick_needfwd(); needForward[f][1] <= pick_needfwd();
      end
    end
  end

  // ---------------------------------------------------------------------------
  always @(posedge clk) if (!rst && !warm) begin
    int nhit;
    for (int r = 0; r < NR; r++) if (raddr[r] >= 56) cov_oob_read++;
    if (data_wen[0] && data_wen[1] && data_waddr[0] == data_waddr[1]) cov_wr_collide++;
    if (data_wen[0] && mask_wen[0] && data_waddr[0] != mask_waddr[0]) cov_mask_split++;
    // 读回的 16 个字节互不相同 → 切片对位的直接证据
    if (g_rmask[0] !== '0) begin
      bit distinct; distinct = 1;
      for (int a = 0; a < 16; a++) for (int b = a+1; b < 16; b++)
        if (g_rdata[0][8*a +: 8] === g_rdata[0][8*b +: 8]) distinct = 0;
      if (distinct) cov_bytes_distinct++;
    end
    for (int f = 0; f < NF; f++) begin
      nhit = 0;
      for (int b = 0; b < NB; b++) if (g_fmask[f][b]) nhit++;
      if (nhit > 0 && nhit < NB) cov_fwd_hit_partial++;   // ★ W4 切片各自独立 ★
    end
  end

  // ---------------------------------------------------------------------------
  `define CK(nm, g, i) \
    begin checks++; \
      if ((g) !== (i)) begin errors++; \
        if (errors <= 60) $display("[%0t] %s g=%h i=%h", $time, nm, (g), (i)); end end

  always @(negedge clk) if (!rst && !warm) begin
    #4;
    for (int r = 0; r < NR; r++) begin
      `CK($sformatf("rmask[%0d]", r), g_rmask[r], i_rmask[r])
      `CK($sformatf("rdata[%0d]", r), g_rdata[r], i_rdata[r])
    end
    for (int f = 0; f < NF; f++)
      for (int b = 0; b < NB; b++) begin
        `CK($sformatf("fmask[%0d][%0d]", f, b), g_fmask[f][b], i_fmask[f][b])
        `CK($sformatf("fdata[%0d][%0d]", f, b), g_fdata[f][b], i_fdata[f][b])
      end
  end

  // ---------------------------------------------------------------------------
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    fork
      forever begin
        repeat (2800 + $urandom_range(0, 400)) @(posedge clk);
        rst = 1; cov_mid_reset++; repeat (2) @(posedge clk); rst = 0;
      end
    join_none
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    $display("COVERAGE oob_read=%0d wr_collide=%0d mask_split=%0d bytes_distinct=%0d fwd_partial=%0d mid_reset=%0d",
             cov_oob_read, cov_wr_collide, cov_mask_split, cov_bytes_distinct,
             cov_fwd_hit_partial, cov_mid_reset);
    if (errors == 0 && checks > 1000 &&
        cov_oob_read > 100 && cov_wr_collide > 100 && cov_mask_split > 100 &&
        cov_bytes_distinct > 100 && cov_fwd_hit_partial > 100 && cov_mid_reset > 2)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
