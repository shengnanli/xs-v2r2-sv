// =============================================================================
// StreamBitVectorArray UT —— golden StreamBitVectorArray 对重写 StreamBitVectorArray_xs
// 双例化，同激励逐拍比对全部 11 根输出。
//
// 激励要点（判别力来自哪里）：
//   · 4 条「流」：各自一个块地址指针，训练请求被收下一次就前进 1 行（偶尔原地或跳 2 行），自然跨区域 —— 让 cnt 攒到 12 → active，
//     下一个区域入表时「邻区活跃」直接 active，然后触发 L1/L2 预取；偶尔倒着走（-1 邻区路径）。
//   · 一个 24 区域的池子随机访问（命中 → update / 不中 → alloc / PLRU 替换）；
//     1/10 的请求只改 region[39:25]（哈希不看这些位）—— 专打哈希冲突；少量完全随机地址。
//   · miss / pfHitStream / io_enable 随机；stride 查询从流指针 / 池子 / 随机地址取。
//   · 负载分相：每 2048 拍换一次训练请求概率（10/40/80/100%），100% 时常撞 s1 反压。
//   · 偶发 3 拍复位脉冲（复位期间不比）。
// 比较窗口：ready / 两路 valid / sink / lookup_resp 从复位释放起逐拍比。
//   bits 由不复位寄存器直接驱动：+random 档两侧初值各摇各的，所以 l1 bits 在 golden 第一次发 L1
//   预取之后、l2_l3 bits 在第一次发 L2 预取再过 2 拍（s5 被写过）之后才开始比，之后逐拍全比。
// 覆盖判据：窗口内 alloc / update / 邻区激活 alloc / L1 预取 / L2 预取 / 反压 / 查询命中活跃 /
//   哈希冲突命中 每一类都必须发生过，否则本轮不作数（TEST FAILED）。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  bit  clk = 0;
  int  errors = 0;
  longint checks = 0;
  always #5 clk = ~clk;

  // ---- 输入（两个 DUT 共用）----
  logic        reset;
  logic        io_enable;
  logic        io_train_req_valid;
  logic [49:0] io_train_req_bits_vaddr;
  logic        io_train_req_bits_miss;
  logic        io_train_req_bits_pfHitStream;
  logic        io_stream_lookup_req_valid;
  logic [49:0] io_stream_lookup_req_bits_vaddr;

  // ---- 输出：g_ = golden，x_ = 重写 ----
  logic        g_ready, x_ready;
  logic        g_l1_valid, x_l1_valid;
  logic [39:0] g_l1_region, x_l1_region;
  logic [15:0] g_l1_bit_vec, x_l1_bit_vec;
  logic        g_l23_valid, x_l23_valid;
  logic [39:0] g_l23_region, x_l23_region;
  logic [15:0] g_l23_bit_vec, x_l23_bit_vec;
  logic [1:0]  g_l23_sink, x_l23_sink;
  logic        g_lookup_resp, x_lookup_resp;

  StreamBitVectorArray g_dut (
    .clock                               (clk),
    .reset                               (reset),
    .io_enable                           (io_enable),
    .io_train_req_ready                  (g_ready),
    .io_train_req_valid                  (io_train_req_valid),
    .io_train_req_bits_vaddr             (io_train_req_bits_vaddr),
    .io_train_req_bits_miss              (io_train_req_bits_miss),
    .io_train_req_bits_pfHitStream       (io_train_req_bits_pfHitStream),
    .io_l1_prefetch_req_valid            (g_l1_valid),
    .io_l1_prefetch_req_bits_region      (g_l1_region),
    .io_l1_prefetch_req_bits_bit_vec     (g_l1_bit_vec),
    .io_l2_l3_prefetch_req_valid         (g_l23_valid),
    .io_l2_l3_prefetch_req_bits_region   (g_l23_region),
    .io_l2_l3_prefetch_req_bits_bit_vec  (g_l23_bit_vec),
    .io_l2_l3_prefetch_req_bits_sink     (g_l23_sink),
    .io_stream_lookup_req_valid          (io_stream_lookup_req_valid),
    .io_stream_lookup_req_bits_vaddr     (io_stream_lookup_req_bits_vaddr),
    .io_stream_lookup_resp               (g_lookup_resp)
  );

  StreamBitVectorArray_xs x_dut (
    .clock                               (clk),
    .reset                               (reset),
    .io_enable                           (io_enable),
    .io_train_req_ready                  (x_ready),
    .io_train_req_valid                  (io_train_req_valid),
    .io_train_req_bits_vaddr             (io_train_req_bits_vaddr),
    .io_train_req_bits_miss              (io_train_req_bits_miss),
    .io_train_req_bits_pfHitStream       (io_train_req_bits_pfHitStream),
    .io_l1_prefetch_req_valid            (x_l1_valid),
    .io_l1_prefetch_req_bits_region      (x_l1_region),
    .io_l1_prefetch_req_bits_bit_vec     (x_l1_bit_vec),
    .io_l2_l3_prefetch_req_valid         (x_l23_valid),
    .io_l2_l3_prefetch_req_bits_region   (x_l23_region),
    .io_l2_l3_prefetch_req_bits_bit_vec  (x_l23_bit_vec),
    .io_l2_l3_prefetch_req_bits_sink     (x_l23_sink),
    .io_stream_lookup_req_valid          (io_stream_lookup_req_valid),
    .io_stream_lookup_req_bits_vaddr     (io_stream_lookup_req_bits_vaddr),
    .io_stream_lookup_resp               (x_lookup_resp)
  );

  // ---- 激励 ----
  logic [39:0] pool [24];
  logic [43:0] stream_blk [4];      // 每条流的当前块地址（vaddr[49:6]）
  bit          stream_down [4];     // 这条流倒着走
  int          load_pct;
  int          train_stream;        // 本拍训练请求用的是哪条流（-1 = 不是流）

  // 训练请求真的被收下（fire）才推进那条流：每次前进 1 行，偶尔原地（同行再访问）或跳 2 行
  task automatic advance_stream(input int s);
    int k;
    k = $urandom_range(0, 19);
    if (k < 2)      ;
    else if (k < 3) stream_blk[s] = stream_down[s] ? stream_blk[s] - 44'd2 : stream_blk[s] + 44'd2;
    else            stream_blk[s] = stream_down[s] ? stream_blk[s] - 44'd1 : stream_blk[s] + 44'd1;
  endtask

  function automatic logic [49:0] pick_addr(input int sel, input bit for_train);
    logic [39:0] r;
    int s;
    if (sel < 50) begin                                   // 流（推进见 advance_stream）
      s = $urandom_range(0, 3);
      if (for_train) train_stream = s;
      return {stream_blk[s], 6'($urandom)};
    end else if (sel < 80) begin                          // 池子
      return {pool[$urandom_range(0, 23)], 4'($urandom), 6'($urandom)};
    end else if (sel < 90) begin                          // 哈希冲突：只改 [39:25]
      r = pool[$urandom_range(0, 23)];
      r[39:25] = 15'($urandom);
      return {r, 4'($urandom), 6'($urandom)};
    end else begin
      return {18'($urandom), 32'($urandom)};
    end
  endfunction

  task automatic step_streams();
    for (int s = 0; s < 4; s++) begin
      if ($urandom_range(0, 19999) == 0) begin           // 偶尔换一条新流
        stream_blk[s]  = {pool[$urandom_range(0, 23)], 4'h0};
        stream_down[s] = ($urandom_range(0, 4) == 0);
      end
    end
  endtask

  task automatic drive_inputs(input longint c);
    if (c % 2048 == 0) begin
      case ($urandom_range(0, 3))
        0: load_pct = 10;
        1: load_pct = 40;
        2: load_pct = 80;
        default: load_pct = 100;
      endcase
    end
    step_streams();
    io_enable                       = ($urandom_range(0, 9) != 0);
    io_train_req_valid              = ($urandom_range(1, 100) <= load_pct);
    train_stream                    = -1;
    io_train_req_bits_vaddr         = pick_addr($urandom_range(0, 99), 1);
    io_train_req_bits_miss          = ($urandom_range(0, 9) < 6);
    io_train_req_bits_pfHitStream   = ($urandom_range(0, 9) < 2);
    io_stream_lookup_req_valid      = ($urandom_range(0, 9) < 3);
    io_stream_lookup_req_bits_vaddr = pick_addr($urandom_range(0, 99), 0);
  endtask

  // ---- 比较 ----
  bit cmp_l1_bits, cmp_l23_bits;
  task automatic cmp1(input string name, input logic [63:0] g, input logic [63:0] x);
    checks++;
    if (g !== x) begin
      errors++;
      if (errors <= 20) $display("[%0t] MISMATCH %s golden=%h rewrite=%h", $time, name, g, x);
    end
  endtask

  task automatic compare_outputs();
    cmp1("io_train_req_ready",            g_ready,       x_ready);
    cmp1("io_l1_prefetch_req_valid",      g_l1_valid,    x_l1_valid);
    cmp1("io_l2_l3_prefetch_req_valid",   g_l23_valid,   x_l23_valid);
    cmp1("io_l2_l3_prefetch_req_bits_sink", g_l23_sink,  x_l23_sink);
    cmp1("io_stream_lookup_resp",         g_lookup_resp, x_lookup_resp);
    if (cmp_l1_bits) begin
      cmp1("io_l1_prefetch_req_bits_region",  g_l1_region,  x_l1_region);
      cmp1("io_l1_prefetch_req_bits_bit_vec", g_l1_bit_vec, x_l1_bit_vec);
    end
    if (cmp_l23_bits) begin
      cmp1("io_l2_l3_prefetch_req_bits_region",  g_l23_region,  x_l23_region);
      cmp1("io_l2_l3_prefetch_req_bits_bit_vec", g_l23_bit_vec, x_l23_bit_vec);
    end
  endtask

  // ---- 覆盖事件（golden 侧计数）----
  longint n_alloc, n_update, n_nb_alloc, n_l1, n_l23, n_backpress, n_lookup_act, n_alias;
  task automatic collect_cov();
    if (g_dut.s1_alloc_probe)                                       n_alloc++;
    if (g_dut.s1_update_probe)                                      n_update++;
    if (g_dut.s1_alloc_probe && (g_dut.s1_plus_one_hit || g_dut.s1_minus_one_hit)) n_nb_alloc++;
    if (g_l1_valid)                                                 n_l1++;
    if (g_l23_valid)                                                n_l23++;
    if (io_train_req_valid && !g_ready)                             n_backpress++;
    if (g_lookup_resp)                                              n_lookup_act++;
    if (g_dut._GEN_114)                                             n_alias++;   // golden 的 hash_conflict 判据
  endtask

  initial begin
    int l23_seen;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int i = 0; i < 24; i++) pool[i] = {8'($urandom), 32'($urandom)};
    // 让池子里有相邻区域（邻区激活路径）
    for (int i = 12; i < 24; i++) pool[i] = pool[i-12] + 40'd1;
    for (int s = 0; s < 4; s++) begin
      stream_blk[s]  = {pool[s], 4'h0};
      stream_down[s] = (s == 3);
    end
    load_pct = 40;
    cmp_l1_bits = 0; cmp_l23_bits = 0; l23_seen = -1;
    reset = 1;
    drive_inputs(1);
    repeat (10) @(negedge clk);
    reset = 0;
    for (longint c = 0; c < NCYCLES; c++) begin
      if (c > 1000 && $urandom_range(0, 39999) == 0) begin
        reset = 1;
        repeat (3) begin drive_inputs(c); @(negedge clk); end
        reset = 0;
      end
      drive_inputs(c);
      #1;
      if (io_train_req_valid && g_ready && train_stream >= 0) advance_stream(train_stream);
      if (g_l1_valid) cmp_l1_bits = 1;
      if (g_l23_valid && l23_seen < 0) l23_seen = 0;
      if (l23_seen >= 0 && !cmp_l23_bits) begin
        l23_seen++;
        if (l23_seen > 2) cmp_l23_bits = 1;
      end
      compare_outputs();
      collect_cov();
      @(negedge clk);
    end
    $display("=== COVERAGE (StreamBitVectorArray) === checks=%0d alloc=%0d update=%0d nb_alloc=%0d l1_pf=%0d l23_pf=%0d backpress=%0d lookup_active=%0d hash_alias=%0d",
             checks, n_alloc, n_update, n_nb_alloc, n_l1, n_l23, n_backpress, n_lookup_act, n_alias);
    if (n_alloc == 0 || n_update == 0 || n_nb_alloc == 0 || n_l1 == 0 || n_l23 == 0 ||
        n_backpress == 0 || n_lookup_act == 0 || n_alias == 0) begin
      $display("COVERAGE INSUFFICIENT");
      errors++;
    end
    if (errors == 0) $display("TEST PASSED (checks=%0d errors=0)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
