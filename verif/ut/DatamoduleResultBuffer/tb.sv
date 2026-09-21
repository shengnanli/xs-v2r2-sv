// =============================================================================
// verif/ut/DatamoduleResultBuffer/tb.sv —— golden 双例化逐拍比对
// -----------------------------------------------------------------------------
// 深度只有 2 的乒乓缓冲,真正的状态空间很小,但均匀随机打**打不满**:
// enq/deq 各自独立随机时,"两条都在、同拍两进两出"这种状态占比极低。
// 本 tb 用定向配比把下面这些状态压出来:
//
//   B1 缓冲满(两个条目都 valid)且同拍两进两出 —— 进出直通(allowin 旁路)
//   B2 缓冲空
//   B3 ★enq 口 1 的 sqNeedDeq 是模块内部常数 1,不是端口★ ——
//      必须让 enq 口 1 真的写进条目并被读出来,才能验到这条不对称
//   B4 enq_flag / deq_flag 两个轮转指针的全部相位组合(共 4 种)
//   B5 ★中途复位脉冲★ —— valids/flags 异步复位,18 个数据寄存器**不复位**;
//      不打脉冲的话"给数据加了复位"完全不可观测
//
// 接口契约(golden 的 4 条 assert):valid/ready 在 enq 与 deq 两侧都必须是
// "低位先满"的连续前缀。激励遵守它 —— 违反了 golden 的行为就没有定义可言。
//
// ---------------------------------------------------------------------------
// ★ 判别力证据:注入真 bug 必须被报出来 ★
// ---------------------------------------------------------------------------
// 4 个变异体各只改 rtl/memblock/DatamoduleResultBuffer.sv 一处。★不进库★,
// 配方与实测数字(seed=1 / 20000 拍):
//
//   D1 enq 口 1 的 sqNeedDeq 常数写成 0(应为 1)        → errors=32430
//   D2 valids 更新改成"出队清位胜过入队置位"            → errors=244918
//   D3 给 18 个不复位的数据寄存器加复位                  → errors=149
//   D4 enq_flag 在任一口成交时就翻转(应只在恰好成交 1 个时) → errors=228289
//
// 同一条件下未变异版本 errors=0 / checks=619628。
// 注意 D3 只有 149 个 errors —— 它只在中途复位脉冲后的几拍里可见。
// ★没有那个复位脉冲,D3 的 errors 会是 0,整条复位域就等于没验。★
// =============================================================================
`timescale 1ns/1ps
module tb;

  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  // --- enq 激励 ---
  logic         enq_valid [2];
  logic [47:0]  enq_addr  [2];
  logic [49:0]  enq_vaddr [2];
  logic [127:0] enq_data  [2];
  logic [15:0]  enq_mask  [2];
  logic         enq_wline [2];
  logic         enq_sqf   [2];
  logic [5:0]   enq_sqv   [2];
  logic         enq_vecv  [2];
  logic         enq0_sqNeedDeq;      // ★只有 enq 口 0 有这个端口★
  logic         deq_ready [2];

  // --- 两侧输出 ---
  logic         g_enq_ready [2], i_enq_ready [2];
  logic         g_deq_valid [2], i_deq_valid [2];
  logic [47:0]  g_deq_addr  [2], i_deq_addr  [2];
  logic [49:0]  g_deq_vaddr [2], i_deq_vaddr [2];
  logic [127:0] g_deq_data  [2], i_deq_data  [2];
  logic [15:0]  g_deq_mask  [2], i_deq_mask  [2];
  logic         g_deq_wline [2], i_deq_wline [2];
  logic         g_deq_sqf   [2], i_deq_sqf   [2];
  logic [5:0]   g_deq_sqv   [2], i_deq_sqv   [2];
  logic         g_deq_vecv  [2], i_deq_vecv  [2];
  logic         g_deq_snd   [2], i_deq_snd   [2];

  DatamoduleResultBuffer g_u (
    .clock(clk), .reset(rst),
    .io_enq_0_ready(g_enq_ready[0]), .io_enq_0_valid(enq_valid[0]),
    .io_enq_0_bits_addr(enq_addr[0]), .io_enq_0_bits_vaddr(enq_vaddr[0]),
    .io_enq_0_bits_data(enq_data[0]), .io_enq_0_bits_mask(enq_mask[0]),
    .io_enq_0_bits_wline(enq_wline[0]), .io_enq_0_bits_sqPtr_flag(enq_sqf[0]),
    .io_enq_0_bits_sqPtr_value(enq_sqv[0]), .io_enq_0_bits_vecValid(enq_vecv[0]),
    .io_enq_0_bits_sqNeedDeq(enq0_sqNeedDeq),
    .io_enq_1_ready(g_enq_ready[1]), .io_enq_1_valid(enq_valid[1]),
    .io_enq_1_bits_addr(enq_addr[1]), .io_enq_1_bits_vaddr(enq_vaddr[1]),
    .io_enq_1_bits_data(enq_data[1]), .io_enq_1_bits_mask(enq_mask[1]),
    .io_enq_1_bits_wline(enq_wline[1]), .io_enq_1_bits_sqPtr_flag(enq_sqf[1]),
    .io_enq_1_bits_sqPtr_value(enq_sqv[1]), .io_enq_1_bits_vecValid(enq_vecv[1]),
    .io_deq_0_ready(deq_ready[0]), .io_deq_0_valid(g_deq_valid[0]),
    .io_deq_0_bits_addr(g_deq_addr[0]), .io_deq_0_bits_vaddr(g_deq_vaddr[0]),
    .io_deq_0_bits_data(g_deq_data[0]), .io_deq_0_bits_mask(g_deq_mask[0]),
    .io_deq_0_bits_wline(g_deq_wline[0]), .io_deq_0_bits_sqPtr_flag(g_deq_sqf[0]),
    .io_deq_0_bits_sqPtr_value(g_deq_sqv[0]), .io_deq_0_bits_vecValid(g_deq_vecv[0]),
    .io_deq_0_bits_sqNeedDeq(g_deq_snd[0]),
    .io_deq_1_ready(deq_ready[1]), .io_deq_1_valid(g_deq_valid[1]),
    .io_deq_1_bits_addr(g_deq_addr[1]), .io_deq_1_bits_vaddr(g_deq_vaddr[1]),
    .io_deq_1_bits_data(g_deq_data[1]), .io_deq_1_bits_mask(g_deq_mask[1]),
    .io_deq_1_bits_wline(g_deq_wline[1]), .io_deq_1_bits_sqPtr_flag(g_deq_sqf[1]),
    .io_deq_1_bits_sqPtr_value(g_deq_sqv[1]), .io_deq_1_bits_vecValid(g_deq_vecv[1]),
    .io_deq_1_bits_sqNeedDeq(g_deq_snd[1])
  );

  DatamoduleResultBuffer_xs i_u (
    .clock(clk), .reset(rst),
    .io_enq_0_ready(i_enq_ready[0]), .io_enq_0_valid(enq_valid[0]),
    .io_enq_0_bits_addr(enq_addr[0]), .io_enq_0_bits_vaddr(enq_vaddr[0]),
    .io_enq_0_bits_data(enq_data[0]), .io_enq_0_bits_mask(enq_mask[0]),
    .io_enq_0_bits_wline(enq_wline[0]), .io_enq_0_bits_sqPtr_flag(enq_sqf[0]),
    .io_enq_0_bits_sqPtr_value(enq_sqv[0]), .io_enq_0_bits_vecValid(enq_vecv[0]),
    .io_enq_0_bits_sqNeedDeq(enq0_sqNeedDeq),
    .io_enq_1_ready(i_enq_ready[1]), .io_enq_1_valid(enq_valid[1]),
    .io_enq_1_bits_addr(enq_addr[1]), .io_enq_1_bits_vaddr(enq_vaddr[1]),
    .io_enq_1_bits_data(enq_data[1]), .io_enq_1_bits_mask(enq_mask[1]),
    .io_enq_1_bits_wline(enq_wline[1]), .io_enq_1_bits_sqPtr_flag(enq_sqf[1]),
    .io_enq_1_bits_sqPtr_value(enq_sqv[1]), .io_enq_1_bits_vecValid(enq_vecv[1]),
    .io_deq_0_ready(deq_ready[0]), .io_deq_0_valid(i_deq_valid[0]),
    .io_deq_0_bits_addr(i_deq_addr[0]), .io_deq_0_bits_vaddr(i_deq_vaddr[0]),
    .io_deq_0_bits_data(i_deq_data[0]), .io_deq_0_bits_mask(i_deq_mask[0]),
    .io_deq_0_bits_wline(i_deq_wline[0]), .io_deq_0_bits_sqPtr_flag(i_deq_sqf[0]),
    .io_deq_0_bits_sqPtr_value(i_deq_sqv[0]), .io_deq_0_bits_vecValid(i_deq_vecv[0]),
    .io_deq_0_bits_sqNeedDeq(i_deq_snd[0]),
    .io_deq_1_ready(deq_ready[1]), .io_deq_1_valid(i_deq_valid[1]),
    .io_deq_1_bits_addr(i_deq_addr[1]), .io_deq_1_bits_vaddr(i_deq_vaddr[1]),
    .io_deq_1_bits_data(i_deq_data[1]), .io_deq_1_bits_mask(i_deq_mask[1]),
    .io_deq_1_bits_wline(i_deq_wline[1]), .io_deq_1_bits_sqPtr_flag(i_deq_sqf[1]),
    .io_deq_1_bits_sqPtr_value(i_deq_sqv[1]), .io_deq_1_bits_vecValid(i_deq_vecv[1]),
    .io_deq_1_bits_sqNeedDeq(i_deq_snd[1])
  );

  // ---------------------------------------------------------------------------
  int cov_full = 0, cov_empty = 0, cov_2in2out = 0, cov_enq1_fire = 0;
  int cov_snd_from_p1 = 0, cov_mid_reset = 0;
  int cov_phase [4];   // B4:{enq_flag, deq_flag} 四种相位

  // ★ 预热:两个条目各写一次后才开比对 ★
  // 18 个数据寄存器**不复位**。跑 +vcs+initreg+random 时 golden 与 impl 拿到的是
  // 两份不同的随机初值,没写过的条目读出来本来就该不一样 —— 那是 tb 的问题,
  // 不是 RTL 的问题。(不带 initreg 时两侧都是 X,X !== X 为假会把这个坑盖住,
  // 所以**必须**在 initreg 下跑才发现得了。)
  bit warm = 1;
  int warm_i = 0;

  always @(negedge clk) begin
    if (rst) begin
      enq_valid[0] <= 1'b0; enq_valid[1] <= 1'b0;
      deq_ready[0] <= 1'b0; deq_ready[1] <= 1'b0;
      enq0_sqNeedDeq <= 1'b0;
      // 中途复位不重做预热:数据条目不复位,内容还在。
      if (warm_i < 4) begin warm_i <= 0; warm <= 1; end
      for (int p = 0; p < 2; p++) begin
        enq_addr[p] <= '0; enq_vaddr[p] <= '0; enq_data[p] <= '0; enq_mask[p] <= '0;
        enq_wline[p] <= 1'b0; enq_sqf[p] <= 1'b0; enq_sqv[p] <= '0; enq_vecv[p] <= 1'b0;
      end
    end else if (warm_i < 4) begin
      // 预热:两口齐发、下游不收 → 两个条目一次写满,18 个不复位寄存器全部定义。
      enq_valid[0] <= 1'b1; enq_valid[1] <= 1'b1;
      deq_ready[0] <= 1'b0; deq_ready[1] <= 1'b0;
      enq0_sqNeedDeq <= 1'b1;
      for (int p = 0; p < 2; p++) begin
        enq_addr[p]  <= 48'($urandom);
        enq_vaddr[p] <= {18'($urandom), 32'($urandom)};
        enq_data[p]  <= {32'($urandom), 32'($urandom), 32'($urandom), 32'($urandom)};
        enq_mask[p]  <= 16'($urandom);
        enq_wline[p] <= 1'($urandom); enq_sqf[p] <= 1'($urandom);
        enq_sqv[p]   <= 6'($urandom); enq_vecv[p] <= 1'($urandom);
      end
      warm_i <= warm_i + 1;
    end else begin
      if (warm) warm <= 0;
      // ★ 前缀契约:口 1 有效必须口 0 也有效 ★(golden 的 4 条 assert)
      // 配比故意偏向"两个一起进 / 两个一起出",把满/空与直通压出来。
      case ($urandom_range(0, 9))
        0, 1, 2: begin enq_valid[0] <= 1'b0; enq_valid[1] <= 1'b0; end
        3, 4:    begin enq_valid[0] <= 1'b1; enq_valid[1] <= 1'b0; end
        default: begin enq_valid[0] <= 1'b1; enq_valid[1] <= 1'b1; end
      endcase
      case ($urandom_range(0, 9))
        0, 1, 2: begin deq_ready[0] <= 1'b0; deq_ready[1] <= 1'b0; end
        3, 4:    begin deq_ready[0] <= 1'b1; deq_ready[1] <= 1'b0; end
        default: begin deq_ready[0] <= 1'b1; deq_ready[1] <= 1'b1; end
      endcase

      // 负载用可辨认的值:每个条目的每个字段都不同,漏接一根线就会当场失配。
      for (int p = 0; p < 2; p++) begin
        enq_addr[p]  <= 48'($urandom);
        enq_vaddr[p] <= {18'($urandom), 32'($urandom)};
        enq_data[p]  <= {32'($urandom), 32'($urandom), 32'($urandom), 32'($urandom)};
        enq_mask[p]  <= 16'($urandom);
        enq_wline[p] <= 1'($urandom);
        enq_sqf[p]   <= 1'($urandom);
        enq_sqv[p]   <= 6'($urandom);
        enq_vecv[p]  <= 1'($urandom);
      end
      // ★ B3:enq 口 0 的 sqNeedDeq 大部分时间打 0 ★ —— 这样从 deq 端读到 1 就
      // 只可能来自"口 1 写入 → 内部常数 1"这条路径,不对称写错立刻暴露。
      enq0_sqNeedDeq <= ($urandom_range(0, 99) < 15);
    end
  end

  // ---------------------------------------------------------------------------
  always @(posedge clk) if (!rst && !warm) begin
    bit v0, v1, ef, df;
    v0 = g_u.valids_0; v1 = g_u.valids_1; ef = g_u.enq_flag; df = g_u.deq_flag;
    if (v0 && v1)  cov_full++;
    if (!v0 && !v1) cov_empty++;
    cov_phase[{ef, df}]++;
    if (enq_valid[1] && g_enq_ready[1] && deq_ready[1] && g_deq_valid[1]) cov_2in2out++;
    if (enq_valid[1] && g_enq_ready[1]) cov_enq1_fire++;
    // deq 端读出 sqNeedDeq=1 而本拍 enq0 的输入是 0 → 只能来自口 1 的内部常数
    if (g_deq_valid[0] && g_deq_snd[0] && !enq0_sqNeedDeq) cov_snd_from_p1++;
  end

  // ---------------------------------------------------------------------------
  `define CK(nm, g, i) \
    begin checks++; \
      if ((g) !== (i)) begin errors++; \
        if (errors <= 60) $display("[%0t] %s g=%h i=%h", $time, nm, (g), (i)); end end

  always @(negedge clk) if (!rst && !warm) begin
    #4;
    for (int p = 0; p < 2; p++) begin
      `CK($sformatf("enq%0d.ready", p), g_enq_ready[p], i_enq_ready[p])
      `CK($sformatf("deq%0d.valid", p), g_deq_valid[p], i_deq_valid[p])
      `CK($sformatf("deq%0d.addr",  p), g_deq_addr[p],  i_deq_addr[p])
      `CK($sformatf("deq%0d.vaddr", p), g_deq_vaddr[p], i_deq_vaddr[p])
      `CK($sformatf("deq%0d.data",  p), g_deq_data[p],  i_deq_data[p])
      `CK($sformatf("deq%0d.mask",  p), g_deq_mask[p],  i_deq_mask[p])
      `CK($sformatf("deq%0d.wline", p), g_deq_wline[p], i_deq_wline[p])
      `CK($sformatf("deq%0d.sqf",   p), g_deq_sqf[p],   i_deq_sqf[p])
      `CK($sformatf("deq%0d.sqv",   p), g_deq_sqv[p],   i_deq_sqv[p])
      `CK($sformatf("deq%0d.vecv",  p), g_deq_vecv[p],  i_deq_vecv[p])
      `CK($sformatf("deq%0d.snd",   p), g_deq_snd[p],   i_deq_snd[p])
    end
    // 内部状态:4 个异步复位控制位 + 不复位的数据条目
    `CK("valids_0",  g_u.valids_0,  i_u.u_core.valids[0])
    `CK("valids_1",  g_u.valids_1,  i_u.u_core.valids[1])
    `CK("enq_flag",  g_u.enq_flag,  i_u.u_core.enq_flag)
    `CK("deq_flag",  g_u.deq_flag,  i_u.u_core.deq_flag)
    `CK("e0.addr",   g_u.data_0_addr,      i_u.u_core.entries[0].addr)
    `CK("e0.snd",    g_u.data_0_sqNeedDeq, i_u.u_core.entries[0].sqNeedDeq)
    `CK("e1.addr",   g_u.data_1_addr,      i_u.u_core.entries[1].addr)
    `CK("e1.snd",    g_u.data_1_sqNeedDeq, i_u.u_core.entries[1].sqNeedDeq)
    `CK("e1.data",   g_u.data_1_data,      i_u.u_core.entries[1].data)
  end

  // ---------------------------------------------------------------------------
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    foreach (cov_phase[k]) cov_phase[k] = 0;
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    fork
      forever begin   // ★ B5 中途复位脉冲 ★
        repeat (2800 + $urandom_range(0, 400)) @(posedge clk);
        rst = 1; cov_mid_reset++; repeat (2) @(posedge clk); rst = 0;
      end
    join_none
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    $display("COVERAGE full=%0d empty=%0d two_in_two_out=%0d enq1_fire=%0d snd_from_p1=%0d mid_reset=%0d",
             cov_full, cov_empty, cov_2in2out, cov_enq1_fire, cov_snd_from_p1, cov_mid_reset);
    $display("COVERAGE phase00=%0d phase01=%0d phase10=%0d phase11=%0d",
             cov_phase[0], cov_phase[1], cov_phase[2], cov_phase[3]);
    if (errors == 0 && checks > 1000 &&
        cov_full > 100 && cov_empty > 100 && cov_2in2out > 100 &&
        cov_enq1_fire > 100 && cov_snd_from_p1 > 100 && cov_mid_reset > 2 &&
        cov_phase[0] > 100 && cov_phase[1] > 100 && cov_phase[2] > 100 && cov_phase[3] > 100)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
