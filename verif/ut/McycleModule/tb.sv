// Base-counter / time CSR family UT: golden vs 可读 primitive(_xs)逐拍比对。
// 覆盖 6 形态: cycle(ucounter,无reset), Mcycle(mcounter incr=1,无reset),
// Minstret(mcounter incr=robCommit), Stimecmp(rwlatch reset=all-ones),
// Htimedelta(rwlatch reset=0), time(bespoke)。全宽随机激励。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  // 共享激励
  logic        w_wen;
  logic [63:0] w_wdata;
  logic [63:0] mHPM;                 // cycle 用
  logic        debugModeStopCount;
  logic        unprivCountUpdate;
  logic        inhibit;
  logic [6:0]  robInst;
  // time 激励
  logic        mHPM_time_valid, v, nextV, debugModeStopTime;
  logic [63:0] mHPM_time_bits, htimedelta;

  // cycle
  logic [63:0] g_cy, i_cy;
  cycleModule    u_gcy(.clock(clk),.rdata(g_cy),.mHPM_cycle(mHPM),
                       .debugModeStopCount(debugModeStopCount),.unprivCountUpdate(unprivCountUpdate));
  cycleModule_xs u_icy(.clock(clk),.rdata(i_cy),.mHPM_cycle(mHPM),
                       .debugModeStopCount(debugModeStopCount),.unprivCountUpdate(unprivCountUpdate));

  // Mcycle
  logic [63:0] g_mc_rd,i_mc_rd, g_mc_ro,i_mc_ro;
  McycleModule    u_gmc(.clock(clk),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(g_mc_rd),
                        .regOut_ALL(g_mc_ro),.mcountinhibit_CY(inhibit));
  McycleModule_xs u_imc(.clock(clk),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(i_mc_rd),
                        .regOut_ALL(i_mc_ro),.mcountinhibit_CY(inhibit));

  // Minstret
  logic [63:0] g_mi_rd,i_mi_rd, g_mi_ro,i_mi_ro;
  MinstretModule    u_gmi(.clock(clk),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(g_mi_rd),
                          .regOut_ALL(g_mi_ro),.mcountinhibit_IR(inhibit),.robCommit_instNum_bits(robInst));
  MinstretModule_xs u_imi(.clock(clk),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(i_mi_rd),
                          .regOut_ALL(i_mi_ro),.mcountinhibit_IR(inhibit),.robCommit_instNum_bits(robInst));

  // Stimecmp (reset=all-ones)
  logic [63:0] g_st_rd,i_st_rd, g_st_ro,i_st_ro;
  StimecmpModule    u_gst(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
                          .rdata(g_st_rd),.regOut_stimecmp(g_st_ro));
  StimecmpModule_xs u_ist(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
                          .rdata(i_st_rd),.regOut_stimecmp(i_st_ro));

  // Htimedelta (reset=0)
  logic [63:0] g_ht_rd,i_ht_rd, g_ht_ro,i_ht_ro;
  HtimedeltaModule    u_ght(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
                            .rdata(g_ht_rd),.regOut_ALL(g_ht_ro));
  HtimedeltaModule_xs u_iht(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
                            .rdata(i_ht_rd),.regOut_ALL(i_ht_ro));

  // time (bespoke)
  logic [63:0] g_t_rd,i_t_rd, g_t_s,i_t_s, g_t_vs,i_t_vs;
  logic        g_t_u,i_t_u;
  timeModule    u_gt(.clock(clk),.reset(rst),.rdata(g_t_rd),.mHPM_time_valid(mHPM_time_valid),
                     .mHPM_time_bits(mHPM_time_bits),.v(v),.nextV(nextV),.htimedelta(htimedelta),
                     .debugModeStopTime(debugModeStopTime),.updated(g_t_u),.stime(g_t_s),.vstime(g_t_vs));
  timeModule_xs u_it(.clock(clk),.reset(rst),.rdata(i_t_rd),.mHPM_time_valid(mHPM_time_valid),
                     .mHPM_time_bits(mHPM_time_bits),.v(v),.nextV(nextV),.htimedelta(htimedelta),
                     .debugModeStopTime(debugModeStopTime),.updated(i_t_u),.stime(i_t_s),.vstime(i_t_vs));

  always @(negedge clk) begin
    if (rst) begin
      w_wen<='0; w_wdata<='0; mHPM<='0; debugModeStopCount<='0; unprivCountUpdate<='0;
      inhibit<='0; robInst<='0; mHPM_time_valid<='0; v<='0; nextV<='0; debugModeStopTime<='0;
      mHPM_time_bits<='0; htimedelta<='0;
    end else begin
      w_wen<=($urandom_range(0,1)==0); w_wdata<={$urandom,$urandom};
      mHPM<={$urandom,$urandom};
      debugModeStopCount<=1'($urandom); unprivCountUpdate<=($urandom_range(0,1)==0);
      inhibit<=($urandom_range(0,1)==0); robInst<={$urandom}[6:0];
      mHPM_time_valid<=($urandom_range(0,1)==0); v<=1'($urandom); nextV<=1'($urandom);
      debugModeStopTime<=1'($urandom);
      mHPM_time_bits<={$urandom,$urandom}; htimedelta<={$urandom,$urandom};
    end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g_cy!==i_cy ||
          g_mc_rd!==i_mc_rd || g_mc_ro!==i_mc_ro ||
          g_mi_rd!==i_mi_rd || g_mi_ro!==i_mi_ro ||
          g_st_rd!==i_st_rd || g_st_ro!==i_st_ro ||
          g_ht_rd!==i_ht_rd || g_ht_ro!==i_ht_ro ||
          g_t_rd!==i_t_rd || g_t_u!==i_t_u || g_t_s!==i_t_s || g_t_vs!==i_t_vs) begin
        errors++;
        if (errors<=30) $display("[%0t] cy g=%h i=%h mc g=%h i=%h mi g=%h i=%h st g=%h i=%h ht g=%h i=%h t g=%h i=%h",
          $time, g_cy,i_cy, g_mc_rd,i_mc_rd, g_mi_rd,i_mi_rd, g_st_rd,i_st_rd, g_ht_rd,i_ht_rd, g_t_rd,i_t_rd);
      end
    end
  end

  initial begin
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
