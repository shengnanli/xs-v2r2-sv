// InstrUncache / InstrMMIOEntry 双例化逐拍比对 UT
// ---------------------------------------------------------------------------
// 两对 DUT 同时跑，同一套激励：
//   pair E: golden InstrMMIOEntry vs InstrMMIOEntry_xs —— 状态机本体
//   pair T: golden InstrUncache   vs InstrUncache_xs   —— 顶层壳（含 D 通道 source 分发）
//
// 本轮 G0→G1 只加端口不改逻辑（req 侧 memBackTypeMM/memPageTypeNC/flush 三个输入，
// A 通道 user_memPageType_NC/user_memBackType_MM 两个输出）。这类改动最容易"假绿"：
// 只要激励不去动新端口，把它们漏掉、接反、或者接成常量，逐拍比对照样全通过。
// 状态机模块还有第二种假绿：激励让 DUT 永远卡在某个状态，200k 拍下来 errors=0。
// 所以除比对外守下面这些闸，任一不满足即 FAIL（见文件末尾 check_coverage）：
//   1. 4 个状态每个都进过，且 4 条正常转移 + 3 个自环（0→0/1→1/2→2）都走过；
//   2. A 通道上 {memBackTypeMM, memPageTypeNC} 4 种组合都出现过
//      —— 只有这样，把两根 user 线接反/接成常量才一定会被逐拍比对抓到；
//   3. flush 三种情形都发生过：在途被冲刷(needFlush 置位)、冲刷压掉响应、
//      空闲态收到 flush（**不该**置位，负向覆盖）；
//   4. TileLink A 通道真发生过反压（acquire valid & ~ready）+ wfi 压住发请求；
//   5. 响应数据 4 种切片档位（addr[2:1] = 0/1/2/3）都取过，corrupt=1 也回过；
//   6. 顶层 D 通道 source!=0（回包不是给 entry 0 的）真出现过。
// 另外逐拍比 golden 与重写核的内部状态（state / needFlush），不只比端口——
// 输出恰好相等但内部已经跑偏的情形也要当场抓住。
`timescale 1ns/1ps

`define CHECK(NAME, G, I) begin \
  if ($isunknown(G)) skipped_x++; \
  else begin \
    checks++; \
    if ((G) !== (I)) begin \
      errors++; \
      if (errors <= 30) \
        $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, NAME, (G), (I)); \
    end \
  end \
end

module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0, checks = 0, skipped_x = 0;

  // ---- 状态编码（与 rtl 里 entry_state_e 一致）----
  localparam logic [1:0] S_INVALID     = 2'd0;
  localparam logic [1:0] S_REFILL_REQ  = 2'd1;
  localparam logic [1:0] S_REFILL_RESP = 2'd2;
  localparam logic [1:0] S_SEND_RESP   = 2'd3;

  // ---- 覆盖计数 ----
  int st_cnt[4];              // entry 处于各状态的拍数
  int tr_cnt[4][4];           // 状态转移计数 [from][to]
  int acq_stall     = 0;      // acquire valid & ~ready（TL 反压）
  int acq_fire      = 0;
  int wfi_block     = 0;      // 处于 S_REFILL_REQ 但 wfiReq 压住不发
  int flush_set     = 0;      // 在途（state 1/2）收到 flush → needFlush 置位
  int flush_idle    = 0;      // S_INVALID 收到 flush（负向：不该置位）
  int flush_at_send = 0;      // S_SEND_RESP 收到 flush（负向：不该置位）
  int resp_killed   = 0;      // S_SEND_RESP 且 needFlush → 响应被压掉
  int resp_fire     = 0;      // 正常送出响应的拍数
  int sel_cnt[4];             // 送响应时 addr[2:1] 的四档
  int corrupt_resp  = 0;      // corrupt=1 的响应
  int user_combo[4];          // acquire 时 {memBackTypeMM, memPageTypeNC} 四种组合
  int top_src_block = 0;      // 顶层：d_valid 但 source!=0，回包不该给 entry 0
  int top_resp_fire = 0;
  logic [1:0] prev_state;
  bit         prev_valid = 0;

  always #5 clock = ~clock;

  // ---- 共享激励 ----
  logic        req_valid, req_mm, req_nc, req_flush;
  logic [47:0] req_addr;
  logic        acq_ready, wfi_req;
  logic        grant_valid, grant_corrupt, d_source;
  logic [63:0] grant_data;

  // ---- pair E: InstrMMIOEntry ----
  wire        ge_req_ready,  ie_req_ready;
  wire        ge_resp_valid, ie_resp_valid;
  wire [31:0] ge_resp_data,  ie_resp_data;
  wire        ge_resp_corrupt, ie_resp_corrupt;
  wire        ge_acq_valid,  ie_acq_valid;
  wire [47:0] ge_acq_addr,   ie_acq_addr;
  wire        ge_acq_nc,     ie_acq_nc;
  wire        ge_acq_mm,     ie_acq_mm;
  wire        ge_wfi_safe,   ie_wfi_safe;

  `define ENTRY_PORTS(RR,RV,RD,RC,AV,AA,ANC,AMM,WS) \
    .clock                                    (clock),        \
    .reset                                    (reset),        \
    .io_req_ready                             (RR),           \
    .io_req_valid                             (req_valid),    \
    .io_req_bits_addr                         (req_addr),     \
    .io_req_bits_memBackTypeMM                (req_mm),       \
    .io_req_bits_memPageTypeNC                (req_nc),       \
    .io_req_bits_flush                        (req_flush),    \
    .io_resp_valid                            (RV),           \
    .io_resp_bits_data                        (RD),           \
    .io_resp_bits_corrupt                     (RC),           \
    .io_mmio_acquire_ready                    (acq_ready),    \
    .io_mmio_acquire_valid                    (AV),           \
    .io_mmio_acquire_bits_address             (AA),           \
    .io_mmio_acquire_bits_user_memPageType_NC (ANC),          \
    .io_mmio_acquire_bits_user_memBackType_MM (AMM),          \
    .io_mmio_grant_valid                      (grant_valid),  \
    .io_mmio_grant_bits_data                  (grant_data),   \
    .io_mmio_grant_bits_corrupt               (grant_corrupt),\
    .io_wfi_wfiReq                            (wfi_req),      \
    .io_wfi_wfiSafe                           (WS)

  InstrMMIOEntry    u_g_ent (`ENTRY_PORTS(ge_req_ready, ge_resp_valid, ge_resp_data,
      ge_resp_corrupt, ge_acq_valid, ge_acq_addr, ge_acq_nc, ge_acq_mm, ge_wfi_safe));
  InstrMMIOEntry_xs u_i_ent (`ENTRY_PORTS(ie_req_ready, ie_resp_valid, ie_resp_data,
      ie_resp_corrupt, ie_acq_valid, ie_acq_addr, ie_acq_nc, ie_acq_mm, ie_wfi_safe));

  // ---- pair T: InstrUncache（顶层，多一层 source 分发）----
  wire        gt_a_valid, it_a_valid;
  wire [47:0] gt_a_addr,  it_a_addr;
  wire        gt_a_nc,    it_a_nc;
  wire        gt_a_mm,    it_a_mm;
  wire        gt_req_ready, it_req_ready;
  wire        gt_resp_valid, it_resp_valid;
  wire [31:0] gt_resp_data,  it_resp_data;
  wire        gt_resp_corrupt, it_resp_corrupt;
  wire        gt_wfi_safe, it_wfi_safe;

  `define TOP_PORTS(AV,AA,ANC,AMM,RR,RV,RD,RC,WS) \
    .clock                                     (clock),        \
    .reset                                     (reset),        \
    .auto_client_out_a_ready                   (acq_ready),    \
    .auto_client_out_a_valid                   (AV),           \
    .auto_client_out_a_bits_address            (AA),           \
    .auto_client_out_a_bits_user_memPageType_NC(ANC),          \
    .auto_client_out_a_bits_user_memBackType_MM(AMM),          \
    .auto_client_out_d_valid                   (grant_valid),  \
    .auto_client_out_d_bits_source             (d_source),     \
    .auto_client_out_d_bits_data               (grant_data),   \
    .auto_client_out_d_bits_corrupt            (grant_corrupt),\
    .io_req_ready                              (RR),           \
    .io_req_valid                              (req_valid),    \
    .io_req_bits_addr                          (req_addr),     \
    .io_req_bits_memBackTypeMM                 (req_mm),       \
    .io_req_bits_memPageTypeNC                 (req_nc),       \
    .io_req_bits_flush                         (req_flush),    \
    .io_resp_valid                             (RV),           \
    .io_resp_bits_data                         (RD),           \
    .io_resp_bits_corrupt                      (RC),           \
    .io_wfi_wfiReq                             (wfi_req),      \
    .io_wfi_wfiSafe                            (WS)

  InstrUncache    u_g_top (`TOP_PORTS(gt_a_valid, gt_a_addr, gt_a_nc, gt_a_mm,
      gt_req_ready, gt_resp_valid, gt_resp_data, gt_resp_corrupt, gt_wfi_safe));
  InstrUncache_xs u_i_top (`TOP_PORTS(it_a_valid, it_a_addr, it_a_nc, it_a_mm,
      it_req_ready, it_resp_valid, it_resp_data, it_resp_corrupt, it_wfi_safe));

  // ---- 内部观测点（覆盖统计取 golden 侧；同时逐拍比 golden vs 重写核）----
  wire [1:0] g_state      = u_g_ent.state;
  wire [1:0] i_state      = u_i_ent.u_core.state;
  wire       g_need_flush = u_g_ent.needFlush;
  wire       i_need_flush = u_i_ent.u_core.need_flush;
  wire [1:0] gtop_state   = u_g_top.entries_0.state;
  wire [1:0] itop_state   = u_i_top.entries_0.u_core.state;

  task automatic drive_random_inputs();
    req_valid     <= $urandom_range(0, 1);
    req_addr      <= 48'({$urandom, $urandom});
    req_mm        <= $urandom_range(0, 1);
    req_nc        <= $urandom_range(0, 1);
    req_flush     <= ($urandom_range(0, 7) == 0);   // 1/8：够密能打到，够稀请求还能走完
    acq_ready     <= $urandom_range(0, 1);
    wfi_req       <= ($urandom_range(0, 7) == 0);
    grant_valid   <= $urandom_range(0, 1);
    grant_data    <= 64'({$urandom, $urandom});
    grant_corrupt <= $urandom_range(0, 1);
    d_source      <= ($urandom_range(0, 7) == 0);   // 1/8 是"不给 entry 0"的回包
  endtask

  task automatic check_outputs();
    `CHECK("ent.io_req_ready",        ge_req_ready,    ie_req_ready)
    `CHECK("ent.io_resp_valid",       ge_resp_valid,   ie_resp_valid)
    `CHECK("ent.io_resp_bits_data",   ge_resp_data,    ie_resp_data)
    `CHECK("ent.io_resp_bits_corrupt",ge_resp_corrupt, ie_resp_corrupt)
    `CHECK("ent.io_acq_valid",        ge_acq_valid,    ie_acq_valid)
    `CHECK("ent.io_acq_address",      ge_acq_addr,     ie_acq_addr)
    `CHECK("ent.io_acq_user_NC",      ge_acq_nc,       ie_acq_nc)
    `CHECK("ent.io_acq_user_MM",      ge_acq_mm,       ie_acq_mm)
    `CHECK("ent.io_wfi_wfiSafe",      ge_wfi_safe,     ie_wfi_safe)
    `CHECK("ent.state",               g_state,         i_state)
    `CHECK("ent.needFlush",           g_need_flush,    i_need_flush)

    `CHECK("top.a_valid",             gt_a_valid,      it_a_valid)
    `CHECK("top.a_address",           gt_a_addr,       it_a_addr)
    `CHECK("top.a_user_NC",           gt_a_nc,         it_a_nc)
    `CHECK("top.a_user_MM",           gt_a_mm,         it_a_mm)
    `CHECK("top.io_req_ready",        gt_req_ready,    it_req_ready)
    `CHECK("top.io_resp_valid",       gt_resp_valid,   it_resp_valid)
    `CHECK("top.io_resp_bits_data",   gt_resp_data,    it_resp_data)
    `CHECK("top.io_resp_bits_corrupt",gt_resp_corrupt, it_resp_corrupt)
    `CHECK("top.io_wfi_wfiSafe",      gt_wfi_safe,     it_wfi_safe)
    `CHECK("top.entry.state",         gtop_state,      itop_state)
  endtask

  // posedge 之前采样：此刻的 (state, 输入) 正是下一个 posedge 要吃的那一组。
  task automatic sample_pre();
    if ($isunknown(g_state)) return;
    st_cnt[g_state]++;
    if (ge_acq_valid && !acq_ready) acq_stall++;
    if (ge_acq_valid &&  acq_ready) acq_fire++;
    // 取 A 通道上真正被观测到的两个 user 位 = 锁存下来的请求属性
    if (ge_acq_valid) user_combo[{ge_acq_mm, ge_acq_nc}]++;
    if (g_state == S_REFILL_REQ && wfi_req) wfi_block++;
    if (req_flush) begin
      case (g_state)
        S_INVALID:                 flush_idle++;
        S_REFILL_REQ, S_REFILL_RESP: if (!g_need_flush) flush_set++;
        S_SEND_RESP:               flush_at_send++;
      endcase
    end
    if (g_state == S_SEND_RESP) begin
      if (g_need_flush) resp_killed++;
      else begin
        resp_fire++;
        if (!$isunknown(u_g_ent.req_addr[2:1])) sel_cnt[u_g_ent.req_addr[2:1]]++;
        if (ge_resp_corrupt) corrupt_resp++;
      end
    end
    if (grant_valid && d_source) top_src_block++;
    if (gt_resp_valid) top_resp_fire++;
  endtask

  task automatic sample_post();
    if (!$isunknown(g_state)) begin
      if (prev_valid) tr_cnt[prev_state][g_state]++;
      prev_state = g_state;
      prev_valid = 1;
    end
  endtask

  function automatic bit check_coverage();
    bit ok = 1;
    for (int s = 0; s < 4; s++)
      if (st_cnt[s] == 0) begin
        $display("COVERAGE HOLE: entry 状态 %0d 一次都没进过", s); ok = 0;
      end
    // 4 条正常转移 + 3 个自环（S_SEND_RESP 恒定只待一拍，故没有 3→3 自环）
    if (tr_cnt[S_INVALID][S_REFILL_REQ]      == 0) begin $display("COVERAGE HOLE: 无转移 0->1"); ok = 0; end
    if (tr_cnt[S_REFILL_REQ][S_REFILL_RESP]  == 0) begin $display("COVERAGE HOLE: 无转移 1->2"); ok = 0; end
    if (tr_cnt[S_REFILL_RESP][S_SEND_RESP]   == 0) begin $display("COVERAGE HOLE: 无转移 2->3"); ok = 0; end
    if (tr_cnt[S_SEND_RESP][S_INVALID]       == 0) begin $display("COVERAGE HOLE: 无转移 3->0"); ok = 0; end
    if (tr_cnt[S_INVALID][S_INVALID]         == 0) begin $display("COVERAGE HOLE: 无自环 0->0（从未空转）"); ok = 0; end
    if (tr_cnt[S_REFILL_REQ][S_REFILL_REQ]   == 0) begin $display("COVERAGE HOLE: 无自环 1->1（acquire 从未被压住）"); ok = 0; end
    if (tr_cnt[S_REFILL_RESP][S_REFILL_RESP] == 0) begin $display("COVERAGE HOLE: 无自环 2->2（从未等过 grant）"); ok = 0; end
    if (tr_cnt[S_SEND_RESP][S_SEND_RESP]     != 0) begin
      $display("BUG: 出现 3->3 —— S_SEND_RESP 应当恒定只待一拍"); ok = 0;
    end
    for (int c = 0; c < 4; c++)
      if (user_combo[c] == 0) begin
        $display("COVERAGE HOLE: A 通道 {memBackTypeMM,memPageTypeNC}=%0d%0d 组合从未出现 —— 这两根新线接反/接常量也测不出来",
                 (c >> 1) & 1, c & 1); ok = 0;
      end
    for (int s = 0; s < 4; s++)
      if (sel_cnt[s] == 0) begin
        $display("COVERAGE HOLE: 响应时 addr[2:1]=%0d 这一档从未取过", s); ok = 0;
      end
    if (acq_stall     == 0) begin $display("COVERAGE HOLE: TL A 通道从未反压过"); ok = 0; end
    if (acq_fire      == 0) begin $display("COVERAGE HOLE: TL A 通道从未握手成功"); ok = 0; end
    if (wfi_block     == 0) begin $display("COVERAGE HOLE: wfi 从未压住过发请求"); ok = 0; end
    if (flush_set     == 0) begin $display("COVERAGE HOLE: 从未在请求在途时收到 flush"); ok = 0; end
    if (flush_idle    == 0) begin $display("COVERAGE HOLE: 从未在空闲态收到 flush（负向覆盖缺失）"); ok = 0; end
    if (flush_at_send == 0) begin $display("COVERAGE HOLE: 从未在 S_SEND_RESP 收到 flush（负向覆盖缺失）"); ok = 0; end
    if (resp_killed   == 0) begin $display("COVERAGE HOLE: 从未发生「响应被 flush 压掉」"); ok = 0; end
    if (resp_fire     == 0) begin $display("COVERAGE HOLE: 从未正常送出过响应"); ok = 0; end
    if (corrupt_resp  == 0) begin $display("COVERAGE HOLE: 从未回过 corrupt=1 的响应"); ok = 0; end
    if (top_src_block == 0) begin $display("COVERAGE HOLE: 顶层 D 通道 source!=0 从未出现"); ok = 0; end
    if (top_resp_fire == 0) begin $display("COVERAGE HOLE: 顶层从未送出过响应"); ok = 0; end
    return ok;
  endfunction

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    else if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    foreach (st_cnt[i])  st_cnt[i] = 0;
    foreach (sel_cnt[i]) sel_cnt[i] = 0;
    foreach (user_combo[i]) user_combo[i] = 0;
    foreach (tr_cnt[i,j])   tr_cnt[i][j] = 0;
    reset         = 1'b1;
    req_valid     = '0;
    req_addr      = '0;
    req_mm        = '0;
    req_nc        = '0;
    req_flush     = '0;
    acq_ready     = '0;
    wfi_req       = '0;
    grant_valid   = '0;
    grant_data    = '0;
    grant_corrupt = '0;
    d_source      = '0;
    repeat (8) @(posedge clock);
    @(negedge clock);            // 在 negedge 撤 reset：别和两个 DUT 的 posedge 块抢同一时刻
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1;                 // 输入 NBA 生效、组合输出稳定
      check_outputs();
      sample_pre();
      @(posedge clock);
      #1;
      sample_post();
    end
    $display("InstrUncache checks=%0d errors=%0d skipped_x=%0d", checks, errors, skipped_x);
    $display("  state dwell : S_INVALID=%0d S_REFILL_REQ=%0d S_REFILL_RESP=%0d S_SEND_RESP=%0d",
             st_cnt[0], st_cnt[1], st_cnt[2], st_cnt[3]);
    $display("  transitions : 0->1=%0d 1->2=%0d 2->3=%0d 3->0=%0d | self 0->0=%0d 1->1=%0d 2->2=%0d 3->3=%0d",
             tr_cnt[0][1], tr_cnt[1][2], tr_cnt[2][3], tr_cnt[3][0],
             tr_cnt[0][0], tr_cnt[1][1], tr_cnt[2][2], tr_cnt[3][3]);
    $display("  tilelink A  : fire=%0d stall(valid&~ready)=%0d wfi_block=%0d", acq_fire, acq_stall, wfi_block);
    $display("  A user{MM,NC}: 00=%0d 01=%0d 10=%0d 11=%0d",
             user_combo[0], user_combo[1], user_combo[2], user_combo[3]);
    $display("  flush       : set_inflight=%0d killed_resp=%0d at_idle(no-op)=%0d at_send(no-op)=%0d",
             flush_set, resp_killed, flush_idle, flush_at_send);
    $display("  resp        : fire=%0d corrupt=%0d sel[addr2:1] 0=%0d 1=%0d 2=%0d 3=%0d",
             resp_fire, corrupt_resp, sel_cnt[0], sel_cnt[1], sel_cnt[2], sel_cnt[3]);
    $display("  top level   : resp_fire=%0d d_source!=0=%0d", top_resp_fire, top_src_block);
    if (!check_coverage()) begin
      $display("TEST FAILED");
      $fatal(1);
    end
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
`undef ENTRY_PORTS
`undef TOP_PORTS
