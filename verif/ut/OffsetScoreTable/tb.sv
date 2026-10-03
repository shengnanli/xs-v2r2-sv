// OffsetScoreTable UT —— OffsetScoreTable / OffsetScoreTable_1 两对 golden vs 重写件双例化，逐拍比全部输出
//
// 两对共用同一组 req / resp 激励（resp.ptr 7 位，窄的那个取低 6 位）。
// 学习阶段的两种结束方式需要完全不同的激励，所以分相位（每 ~6000 拍随机换）：
//   HOT    命中率高、ptr 随机           → 分数慢慢涨，多半靠轮数到顶结束
//   FOCUS  命中集中在 2 个 ptr 上        → 很快有得分加到 31（结束条件 1）
//   COLD   完全不命中                   → 轮数到顶且 bestScore=0（发布 prefetchDisable=1）
//   SPARSE 极稀疏命中                   → bestScore 落在 0/1/2 附近，打 BAD_SCORE 边界（两变体阈值 1 / 2 不同）
// 另：resp.ptr 有 1/16 概率取越界值（>=N），打"越界读第 0 项、不写分"的怪癖。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic        req_valid;
  logic [49:0] req_bits;
  logic        resp_valid, resp_hit;
  logic [6:0]  resp_ptr;

  wire        g0_rdy, g0_dis, g0_tv, i0_rdy, i0_dis, i0_tv;
  wire [6:0]  g0_off, g0_toff, i0_off, i0_toff;
  wire [47:0] g0_ta, i0_ta;
  wire [5:0]  g0_tp, i0_tp;
  wire        g1_rdy, g1_dis, g1_tv, i1_rdy, i1_dis, i1_tv;
  wire [9:0]  g1_off, g1_toff, i1_off, i1_toff;
  wire [49:0] g1_ta, i1_ta;
  wire [6:0]  g1_tp, i1_tp;

  `define OST_PORTS(P, AW, PW) \
    .clock(clk), .reset(rst), .io_req_ready(P``_rdy), .io_req_valid(req_valid), .io_req_bits(req_bits[AW-1:0]), \
    .io_prefetchOffset(P``_off), .io_prefetchDisable(P``_dis), .io_test_req_valid(P``_tv), \
    .io_test_req_bits_addr(P``_ta), .io_test_req_bits_testOffset(P``_toff), .io_test_req_bits_ptr(P``_tp), \
    .io_test_resp_valid(resp_valid), .io_test_resp_bits_ptr(resp_ptr[PW-1:0]), .io_test_resp_bits_hit(resp_hit)

  OffsetScoreTable      g0 (`OST_PORTS(g0, 48, 6));
  OffsetScoreTable_xs   i0 (`OST_PORTS(i0, 48, 6));
  OffsetScoreTable_1    g1 (`OST_PORTS(g1, 50, 7));
  OffsetScoreTable_1_xs i1 (`OST_PORTS(i1, 50, 7));

  typedef enum int { HOT, FOCUS, COLD, SPARSE } phase_e;
  phase_e phase;
  logic [6:0] focus_ptr [2];
  int cyc;
  int cov_idle0, cov_idle1, cov_full0, cov_full1, cov_rounds0, cov_rounds1;
  int cov_dis0, cov_dis1, cov_oob0, cov_oob1, cov_midrst;

  always @(negedge clk) begin
    if (rst) begin
      cyc <= 0; req_valid <= 0; req_bits <= '0; resp_valid <= 0; resp_hit <= 0; resp_ptr <= '0; phase <= HOT;
    end else begin
      cyc <= cyc + 1;
      if ($urandom_range(0, 5999) == 0) begin
        phase <= phase_e'($urandom_range(0, 3));
        focus_ptr[0] <= 7'($urandom); focus_ptr[1] <= 7'($urandom_range(0, 36));
      end
      req_valid <= ($urandom_range(0, 7) != 0);
      req_bits  <= {$urandom, $urandom};
      case (phase)
        HOT:    begin resp_valid <= $urandom_range(0, 1); resp_hit <= ($urandom_range(0, 3) == 0); end
        FOCUS:  begin resp_valid <= 1'b1;                 resp_hit <= $urandom_range(0, 1); end
        COLD:   begin resp_valid <= $urandom_range(0, 1); resp_hit <= 1'b0; end
        SPARSE: begin resp_valid <= 1'b1;                 resp_hit <= ($urandom_range(0, 2999) == 0); end
      endcase
      if (phase == FOCUS && $urandom_range(0, 7) != 0) resp_ptr <= focus_ptr[$urandom_range(0, 1)];
      else if ($urandom_range(0, 15) == 0)             resp_ptr <= $urandom_range(0, 1) ? 7'($urandom_range(37, 127)) : 7'($urandom_range(109, 127));
      else                                             resp_ptr <= 7'($urandom_range(0, 108));
    end
  end

  `define CHK(nm, g, i) \
    if ((g) !== (i)) begin errors++; \
      if (errors <= 40) $display("[cyc %0d] %s g=%h i=%h", cyc, nm, g, i); end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    `CHK("OST.req_ready",   g0_rdy,  i0_rdy)   `CHK("OST_1.req_ready",   g1_rdy,  i1_rdy)
    `CHK("OST.pfOffset",    g0_off,  i0_off)   `CHK("OST_1.pfOffset",    g1_off,  i1_off)
    `CHK("OST.pfDisable",   g0_dis,  i0_dis)   `CHK("OST_1.pfDisable",   g1_dis,  i1_dis)
    `CHK("OST.test_valid",  g0_tv,   i0_tv)    `CHK("OST_1.test_valid",  g1_tv,   i1_tv)
    `CHK("OST.test_addr",   g0_ta,   i0_ta)    `CHK("OST_1.test_addr",   g1_ta,   i1_ta)
    `CHK("OST.test_offset", g0_toff, i0_toff)  `CHK("OST_1.test_offset", g1_toff, i1_toff)
    `CHK("OST.test_ptr",    g0_tp,   i0_tp)    `CHK("OST_1.test_ptr",    g1_tp,   i1_tp)
    // 覆盖（读 golden 内部，仅计数）
    if (!g0.state) begin cov_idle0++; if (g0.isBad) cov_dis0++; end
    if (!g1.state) begin cov_idle1++; if (g1.isBad) cov_dis1++; end
    if (g0.state && resp_valid && resp_hit && (&g0._newScore_T)) cov_full0++;
    if (g1.state && resp_valid && resp_hit && (&g1._newScore_T)) cov_full1++;
    if (g0.state && g0.round >= 50) cov_rounds0++;
    if (g1.state && g1.round >= 50) cov_rounds1++;
    if (g0.state && resp_valid && resp_hit && resp_ptr[5:0] >= 37) cov_oob0++;
    if (g1.state && resp_valid && resp_hit && resp_ptr >= 109)     cov_oob1++;
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    for (int k = 0; k < 4; k++) begin
      repeat (NCYCLES / 4) @(posedge clk);
      if (k < 3) begin
        #2 rst = 1; cov_midrst++;
        repeat (3) @(posedge clk);
        #2 rst = 0;
      end
    end
    $display("COV idle=%0d/%0d score_full=%0d/%0d rounds_done=%0d/%0d disable=%0d/%0d oob_hit=%0d/%0d midrst=%0d",
             cov_idle0, cov_idle1, cov_full0, cov_full1, cov_rounds0, cov_rounds1,
             cov_dis0, cov_dis1, cov_oob0, cov_oob1, cov_midrst);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && cov_idle0 > 20 && cov_idle1 > 20 && cov_full0 > 5 && cov_full1 > 5
        && cov_rounds0 > 5 && cov_rounds1 > 2 && cov_dis0 > 2 && cov_dis1 > 2 && cov_oob0 > 100 && cov_oob1 > 100)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
