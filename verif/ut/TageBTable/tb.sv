// tb.sv —— TageBTable 双例化 UT (golden TageBTable vs 重写 TageBTable_xs)
//
// 激励设计的重点是**别让 tb 假绿**: TageBTable 是一张按 pc 索引的表, 随机 pc 打散到
// 2048 项上, 200k 拍里同一项被命中的次数很少, 于是"写旁路命中""bank 冲突""计数器
// 打到饱和"这些真正要验的路径可能一次都不发生, 输出天天相等, 报绿却什么都没证。
// 所以:
//   1) 请求 pc 与更新 pc 都从一个 8 项 hot idx 池里抽, 制造别名与冲突;
//   2) 更新按"突发"发 (连续 2~4 拍打同一个 idx), 逼出 WrBypass 命中;
//   3) 覆盖闸: 下面每个 cov_* 事件都必须 > 阈值, 且 8 个输出每个都必须至少取到
//      两个不同值 (toggle), 否则判 FAIL —— 数值相等但从未被激励过不算通过。
`timescale 1ns/1ps

module tb;
  int unsigned NCYCLES = 200000;
  localparam int WARMUP = 4;          // 只跳过复位释放后的前几拍

  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  // ---------------- 共享激励 ----------------
  logic        req_valid;
  logic [49:0] req_bits;
  logic        upd_mask_0, upd_mask_1;
  logic [49:0] upd_pc;
  logic [1:0]  upd_cnt_0, upd_cnt_1;
  logic        upd_tk_0, upd_tk_1;

  // MBIST bore: 4 组
  logic [8:0]  bo_addr   [4];
  logic [8:0]  bo_addrrd [4];
  logic [7:0]  bo_wdata  [4];
  logic [3:0]  bo_wmask  [4];
  logic        bo_re     [4];
  logic        bo_we     [4];
  logic        bo_ack    [4];
  logic        bo_sel    [4];
  logic [6:0]  bo_array  [4];

  // ---------------- 两侧输出 ----------------
  wire       g_req_ready,      i_req_ready;
  wire [1:0] g_s1_cnt_0,       i_s1_cnt_0;
  wire [1:0] g_s1_cnt_1,       i_s1_cnt_1;
  wire       g_s1_resp_valid,  i_s1_resp_valid;
  wire [7:0] g_rdata_0, i_rdata_0, g_rdata_1, i_rdata_1;
  wire [7:0] g_rdata_2, i_rdata_2, g_rdata_3, i_rdata_3;

  `define BOREPORTS(P) \
    .boreChildrenBd_bore_addr        (bo_addr[0]),   .boreChildrenBd_bore_addr_rd    (bo_addrrd[0]), \
    .boreChildrenBd_bore_wdata       (bo_wdata[0]),  .boreChildrenBd_bore_wmask      (bo_wmask[0]),  \
    .boreChildrenBd_bore_re          (bo_re[0]),     .boreChildrenBd_bore_we         (bo_we[0]),     \
    .boreChildrenBd_bore_rdata       (P``_rdata_0),  .boreChildrenBd_bore_ack        (bo_ack[0]),    \
    .boreChildrenBd_bore_selectedOH  (bo_sel[0]),    .boreChildrenBd_bore_array      (bo_array[0]),  \
    .boreChildrenBd_bore_1_addr      (bo_addr[1]),   .boreChildrenBd_bore_1_addr_rd  (bo_addrrd[1]), \
    .boreChildrenBd_bore_1_wdata     (bo_wdata[1]),  .boreChildrenBd_bore_1_wmask    (bo_wmask[1]),  \
    .boreChildrenBd_bore_1_re        (bo_re[1]),     .boreChildrenBd_bore_1_we       (bo_we[1]),     \
    .boreChildrenBd_bore_1_rdata     (P``_rdata_1),  .boreChildrenBd_bore_1_ack      (bo_ack[1]),    \
    .boreChildrenBd_bore_1_selectedOH(bo_sel[1]),    .boreChildrenBd_bore_1_array    (bo_array[1]),  \
    .boreChildrenBd_bore_2_addr      (bo_addr[2]),   .boreChildrenBd_bore_2_addr_rd  (bo_addrrd[2]), \
    .boreChildrenBd_bore_2_wdata     (bo_wdata[2]),  .boreChildrenBd_bore_2_wmask    (bo_wmask[2]),  \
    .boreChildrenBd_bore_2_re        (bo_re[2]),     .boreChildrenBd_bore_2_we       (bo_we[2]),     \
    .boreChildrenBd_bore_2_rdata     (P``_rdata_2),  .boreChildrenBd_bore_2_ack      (bo_ack[2]),    \
    .boreChildrenBd_bore_2_selectedOH(bo_sel[2]),    .boreChildrenBd_bore_2_array    (bo_array[2]),  \
    .boreChildrenBd_bore_3_addr      (bo_addr[3]),   .boreChildrenBd_bore_3_addr_rd  (bo_addrrd[3]), \
    .boreChildrenBd_bore_3_wdata     (bo_wdata[3]),  .boreChildrenBd_bore_3_wmask    (bo_wmask[3]),  \
    .boreChildrenBd_bore_3_re        (bo_re[3]),     .boreChildrenBd_bore_3_we       (bo_we[3]),     \
    .boreChildrenBd_bore_3_rdata     (P``_rdata_3),  .boreChildrenBd_bore_3_ack      (bo_ack[3]),    \
    .boreChildrenBd_bore_3_selectedOH(bo_sel[3]),    .boreChildrenBd_bore_3_array    (bo_array[3])

  // DFT 时钟控制信号全部钉 0 (与 TageTable UT 同口径: 它们只影响 SRAM 宏的时钟门控,
  // 功能等价由 FM 覆盖; UT 里若随机翻转会把 SRAM 时钟关掉, 变成噪音而非覆盖)。
  `define SIGPORTS \
    .sigFromSrams_bore_ram_hold      (1'b0), .sigFromSrams_bore_ram_bypass      (1'b0), \
    .sigFromSrams_bore_ram_bp_clken  (1'b0), .sigFromSrams_bore_ram_aux_clk     (1'b0), \
    .sigFromSrams_bore_ram_aux_ckbp  (1'b0), .sigFromSrams_bore_ram_mcp_hold    (1'b0), \
    .sigFromSrams_bore_cgen          (1'b0),                                            \
    .sigFromSrams_bore_1_ram_hold    (1'b0), .sigFromSrams_bore_1_ram_bypass    (1'b0), \
    .sigFromSrams_bore_1_ram_bp_clken(1'b0), .sigFromSrams_bore_1_ram_aux_clk   (1'b0), \
    .sigFromSrams_bore_1_ram_aux_ckbp(1'b0), .sigFromSrams_bore_1_ram_mcp_hold  (1'b0), \
    .sigFromSrams_bore_1_cgen        (1'b0),                                            \
    .sigFromSrams_bore_2_ram_hold    (1'b0), .sigFromSrams_bore_2_ram_bypass    (1'b0), \
    .sigFromSrams_bore_2_ram_bp_clken(1'b0), .sigFromSrams_bore_2_ram_aux_clk   (1'b0), \
    .sigFromSrams_bore_2_ram_aux_ckbp(1'b0), .sigFromSrams_bore_2_ram_mcp_hold  (1'b0), \
    .sigFromSrams_bore_2_cgen        (1'b0),                                            \
    .sigFromSrams_bore_3_ram_hold    (1'b0), .sigFromSrams_bore_3_ram_bypass    (1'b0), \
    .sigFromSrams_bore_3_ram_bp_clken(1'b0), .sigFromSrams_bore_3_ram_aux_clk   (1'b0), \
    .sigFromSrams_bore_3_ram_aux_ckbp(1'b0), .sigFromSrams_bore_3_ram_mcp_hold  (1'b0), \
    .sigFromSrams_bore_3_cgen        (1'b0)

  TageBTable u_g (
    .clock(clk), .reset(rst),
    .io_req_ready(g_req_ready), .io_req_valid(req_valid), .io_req_bits(req_bits),
    .io_s1_cnt_0(g_s1_cnt_0), .io_s1_cnt_1(g_s1_cnt_1), .io_s1_resp_valid(g_s1_resp_valid),
    .io_update_mask_0(upd_mask_0), .io_update_mask_1(upd_mask_1), .io_update_pc(upd_pc),
    .io_update_cnt_0(upd_cnt_0), .io_update_cnt_1(upd_cnt_1),
    .io_update_takens_0(upd_tk_0), .io_update_takens_1(upd_tk_1),
    `BOREPORTS(g), `SIGPORTS
  );

  TageBTable_xs u_i (
    .clock(clk), .reset(rst),
    .io_req_ready(i_req_ready), .io_req_valid(req_valid), .io_req_bits(req_bits),
    .io_s1_cnt_0(i_s1_cnt_0), .io_s1_cnt_1(i_s1_cnt_1), .io_s1_resp_valid(i_s1_resp_valid),
    .io_update_mask_0(upd_mask_0), .io_update_mask_1(upd_mask_1), .io_update_pc(upd_pc),
    .io_update_cnt_0(upd_cnt_0), .io_update_cnt_1(upd_cnt_1),
    .io_update_takens_0(upd_tk_0), .io_update_takens_1(upd_tk_1),
    `BOREPORTS(i), `SIGPORTS
  );

  // ---------------- 激励 ----------------
  logic [10:0] hot [8];          // hot idx 池: 制造别名/冲突/写旁路命中
  logic [10:0] cur_upd_idx;
  int          upd_burst;

  function automatic logic [49:0] mk_pc(input logic [10:0] idx);
    return {38'($urandom), idx, 1'b0};
  endfunction

  function automatic logic [10:0] pick_idx();
    if ($urandom_range(0, 9) < 6) return hot[$urandom_range(0, 7)];
    else                          return 11'($urandom);
  endfunction

  initial begin
    for (int i = 0; i < 8; i++) hot[i] = 11'($urandom);
    cur_upd_idx = 11'd0;
    upd_burst   = 0;
  end

  always @(negedge clk) begin
    if (rst) begin
      req_valid  <= 1'b0;
      upd_mask_0 <= 1'b0;
      upd_mask_1 <= 1'b0;
      for (int k = 0; k < 4; k++) begin
        bo_re[k] <= 1'b0; bo_we[k] <= 1'b0; bo_ack[k] <= 1'b0;
      end
    end else begin
      // ---- 预测请求 ----
      req_valid <= ($urandom_range(0, 3) != 0);       // ~75%
      req_bits  <= mk_pc(pick_idx());

      // ---- 更新: 突发打同一个 idx, 逼出写旁路命中 ----
      if (upd_burst > 0) begin
        upd_burst  <= upd_burst - 1;
        upd_mask_0 <= 1'b1;
        upd_mask_1 <= ($urandom_range(0, 1) == 0);
      end else begin
        cur_upd_idx <= pick_idx();
        upd_mask_0  <= ($urandom_range(0, 2) == 0);
        upd_mask_1  <= ($urandom_range(0, 2) == 0);
        if ($urandom_range(0, 3) == 0) upd_burst <= $urandom_range(1, 3);
      end
      upd_pc    <= mk_pc(upd_burst > 0 ? cur_upd_idx : pick_idx());
      upd_cnt_0 <= 2'($urandom);
      upd_cnt_1 <= 2'($urandom);
      upd_tk_0  <= 1'($urandom);
      upd_tk_1  <= 1'($urandom);

      // ---- MBIST 旁路 (两侧同源, 只验穿线) ----
      for (int k = 0; k < 4; k++) begin
        bo_addr[k]   <= 9'($urandom);
        bo_addrrd[k] <= 9'($urandom);
        bo_wdata[k]  <= 8'($urandom);
        bo_wmask[k]  <= 4'($urandom);
        bo_re[k]     <= ($urandom_range(0, 15) == 0);
        bo_we[k]     <= ($urandom_range(0, 15) == 0);
        bo_ack[k]    <= ($urandom_range(0, 7) == 0);
        bo_sel[k]    <= 1'($urandom);
        bo_array[k]  <= 7'($urandom);
      end
    end
  end

  // ---------------- 覆盖统计 (全部按 golden 侧观测) ----------------
  int cov_req = 0, cov_upd = 0, cov_conflict = 0, cov_clean = 0;
  int cov_bank [2];                 // 请求落到哪个 bank
  int cov_cnt0 [4], cov_cnt1 [4];   // io_s1_cnt_x 取到过的 4 个计数值
  int cov_wrb_hit = 0;              // WrBypass 命中 (层次探针; 从端口看不见)
  int cov_wrb_miss = 0;
  int cov_reset_done = 0;           // 上电清表扫完
  int cov_mbist_we = 0;

  // toggle 闸: 8 个输出各自是否取到过至少两个不同值
  logic [7:0]  tg_seen;             // 是否记录过首值
  logic        tg_tog_ready, tg_tog_rv;
  logic [1:0]  first_cnt0, first_cnt1;
  logic        first_ready, first_rv;
  logic [7:0]  first_rd [4];
  logic        tg_tog_cnt0, tg_tog_cnt1;
  logic        tg_tog_rd [4];

  initial begin
    tg_seen = '0; tg_tog_ready = 0; tg_tog_rv = 0;
    tg_tog_cnt0 = 0; tg_tog_cnt1 = 0;
    for (int k = 0; k < 4; k++) tg_tog_rd[k] = 0;
    for (int k = 0; k < 2; k++) cov_bank[k] = 0;
    for (int k = 0; k < 4; k++) begin cov_cnt0[k] = 0; cov_cnt1[k] = 0; end
  end

  // ---------------- 逐拍比对 ----------------
  `define CMP(sig) \
    if (g_``sig !== i_``sig) begin errors++; \
      if (errors <= 30) $display("[%0t] %s g=%h i=%h", $time, `"sig`", g_``sig, i_``sig); end

  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4;
    checks++;
    `CMP(req_ready)
    `CMP(s1_cnt_0)
    `CMP(s1_cnt_1)
    `CMP(s1_resp_valid)
    `CMP(rdata_0)
    `CMP(rdata_1)
    `CMP(rdata_2)
    `CMP(rdata_3)

    // 白盒: 写旁路命中也必须一致 (它只影响 old_ctr, 端口上可能被掩盖)
    if (u_g.wrbypass.io_hit !== u_i.u_core.wrbypass.io_hit) begin
      errors++;
      if (errors <= 30) $display("[%0t] wrbypass.io_hit g=%b i=%b", $time,
                                 u_g.wrbypass.io_hit, u_i.u_core.wrbypass.io_hit);
    end

    // ---- 覆盖累计 ----
    if (req_valid)             cov_req++;
    if (upd_mask_0|upd_mask_1) cov_upd++;
    if (req_valid)             cov_bank[req_bits[1]]++;
    if (g_req_ready) begin
      cov_reset_done++;
      if (!g_s1_resp_valid) cov_conflict++; else cov_clean++;
    end
    if (u_g.wrbypass.io_hit && (upd_mask_0|upd_mask_1)) cov_wrb_hit++;
    else if (upd_mask_0|upd_mask_1)                     cov_wrb_miss++;
    for (int k = 0; k < 4; k++) if (bo_we[k]) cov_mbist_we++;
    if (g_req_ready && g_s1_resp_valid) begin
      cov_cnt0[g_s1_cnt_0]++;
      cov_cnt1[g_s1_cnt_1]++;
    end

    // ---- toggle ----
    if (!tg_seen[0]) begin tg_seen[0] = 1; first_ready = g_req_ready; end
    else if (g_req_ready !== first_ready) tg_tog_ready = 1;
    if (!tg_seen[1]) begin tg_seen[1] = 1; first_rv = g_s1_resp_valid; end
    else if (g_s1_resp_valid !== first_rv) tg_tog_rv = 1;
    if (!tg_seen[2]) begin tg_seen[2] = 1; first_cnt0 = g_s1_cnt_0; end
    else if (g_s1_cnt_0 !== first_cnt0) tg_tog_cnt0 = 1;
    if (!tg_seen[3]) begin tg_seen[3] = 1; first_cnt1 = g_s1_cnt_1; end
    else if (g_s1_cnt_1 !== first_cnt1) tg_tog_cnt1 = 1;
    if (!tg_seen[4]) begin tg_seen[4] = 1; first_rd[0] = g_rdata_0; end
    else if (g_rdata_0 !== first_rd[0]) tg_tog_rd[0] = 1;
    if (!tg_seen[5]) begin tg_seen[5] = 1; first_rd[1] = g_rdata_1; end
    else if (g_rdata_1 !== first_rd[1]) tg_tog_rd[1] = 1;
    if (!tg_seen[6]) begin tg_seen[6] = 1; first_rd[2] = g_rdata_2; end
    else if (g_rdata_2 !== first_rd[2]) tg_tog_rd[2] = 1;
    if (!tg_seen[7]) begin tg_seen[7] = 1; first_rd[3] = g_rdata_3; end
    else if (g_rdata_3 !== first_rd[3]) tg_tog_rd[3] = 1;
  end

  // ---------------- 收敛判决 ----------------
  int cov_fail = 0;
  task automatic need(input string what, input int got, input int thr);
    $display("  cov %-28s = %0d (need > %0d)%s", what, got, thr,
             (got > thr) ? "" : "   <== COVERAGE HOLE");
    if (!(got > thr)) cov_fail++;
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);

    $display("checks=%0d errors=%0d", checks, errors);
    $display("--- coverage ---");
    need("req fired",            cov_req,        1000);
    need("update fired",         cov_upd,        1000);
    need("reset sweep finished", cov_reset_done, 1000);
    need("bank0 read",           cov_bank[0],     500);
    need("bank1 read",           cov_bank[1],     500);
    need("bank conflict (s1 invalid)", cov_conflict, 100);
    need("clean read",           cov_clean,      1000);
    need("wrbypass hit",         cov_wrb_hit,     100);
    need("wrbypass miss",        cov_wrb_miss,    100);
    need("mbist we",             cov_mbist_we,    100);
    for (int v = 0; v < 4; v++) need($sformatf("s1_cnt_0 == %0d", v), cov_cnt0[v], 50);
    for (int v = 0; v < 4; v++) need($sformatf("s1_cnt_1 == %0d", v), cov_cnt1[v], 50);
    need("toggle io_req_ready",     tg_tog_ready, 0);
    need("toggle io_s1_resp_valid", tg_tog_rv,    0);
    need("toggle io_s1_cnt_0",      tg_tog_cnt0,  0);
    need("toggle io_s1_cnt_1",      tg_tog_cnt1,  0);
    for (int k = 0; k < 4; k++) need($sformatf("toggle bore_%0d_rdata", k), tg_tog_rd[k], 0);

    if (errors == 0 && checks > 100000 && cov_fail == 0) $display("TEST PASSED");
    else $display("TEST FAILED (errors=%0d checks=%0d cov_holes=%0d)", errors, checks, cov_fail);
    $finish;
  end
endmodule
