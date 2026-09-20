// VirtualLoadQueue UT —— golden 与重写件双例化逐拍比对
//
// 激励分三段：
//   1. reset（10 拍）
//   2. fill（1 拍就够）：3 条入队请求分别覆盖 [0,24) [24,48) [48,72)，
//      把 **全部 72 个条目** 的 committed / robIdx / uopIdx 写成确定值。
//      这三个阵列在 golden 里是无复位寄存器（Reg(Vec(...))），不做这一段的话
//      `+vcs+initreg+random` 会给两侧灌**不同**的随机初值，比对必然假红。
//      entryCanEnq 不看 canAccept，所以这一拍不需要队列"有空位"。
//   3. random：加权随机驱动全部 113 个输入，逐拍比 9 个输出。
//
// robIdx / uopIdx 的取值范围故意压小，好让 redirect 的 needFlush、
// vecCommit 的 {robIdx,uopIdx} 反查经常真的命中条目。
`timescale 1ns/1ps

module tb;

  localparam int LQ_SIZE  = 72;
  localparam int ENQ_W    = 6;
  localparam int LD_W     = 3;
  localparam int VEC_W    = 2;

  int ncycles;
  int errors;
  int cyc;
  int cmp_cycles;

  logic clock = 1'b0;
  logic reset = 1'b1;

  always #5 clock = ~clock;

  // ---------------- 输入（两侧共用同一份） ----------------
  logic        redirect_valid;
  logic        redirect_flag;
  logic [7:0]  redirect_value;
  logic        redirect_level;

  logic        vc_valid [VEC_W];
  logic        vc_flag  [VEC_W];
  logic [7:0]  vc_value [VEC_W];
  logic [6:0]  vc_uop   [VEC_W];

  logic        sqCanAccept;
  logic        needAlloc [5];

  logic        req_valid  [ENQ_W];
  logic [34:0] req_fuType [ENQ_W];
  logic [6:0]  req_uopIdx [ENQ_W];
  logic        req_robFlag[ENQ_W];
  logic [7:0]  req_robVal [ENQ_W];
  logic        req_lqFlag [ENQ_W];
  logic [6:0]  req_lqVal  [ENQ_W];
  logic [4:0]  req_numElem[ENQ_W];

  logic        ldin_valid [LD_W];
  logic [6:0]  ldin_lqVal [LD_W];
  logic        ldin_isvec [LD_W];
  logic        ldin_upd   [LD_W];
  logic [10:0] ldin_cause [LD_W];

  // ---------------- 输出（golden / 重写） ----------------
  logic        g_canAccept,  x_canAccept;
  logic        g_wbFlag,     x_wbFlag;
  logic [6:0]  g_wbValue,    x_wbValue;
  logic        g_lqEmpty,    x_lqEmpty;
  logic [3:0]  g_lqDeq,      x_lqDeq;
  logic [6:0]  g_cancelCnt,  x_cancelCnt;
  logic        g_deqRobFlag, x_deqRobFlag;
  logic [7:0]  g_deqRobVal,  x_deqRobVal;
  logic [6:0]  g_deqUop,     x_deqUop;

  `define VLQ_PORTS(P)                                        \
    .clock                            (clock),                \
    .reset                            (reset),                \
    .io_redirect_valid                (redirect_valid),       \
    .io_redirect_bits_robIdx_flag     (redirect_flag),        \
    .io_redirect_bits_robIdx_value    (redirect_value),       \
    .io_redirect_bits_level           (redirect_level),       \
    .io_vecCommit_0_valid             (vc_valid[0]),          \
    .io_vecCommit_0_bits_robidx_flag  (vc_flag[0]),           \
    .io_vecCommit_0_bits_robidx_value (vc_value[0]),          \
    .io_vecCommit_0_bits_uopidx       (vc_uop[0]),            \
    .io_vecCommit_1_valid             (vc_valid[1]),          \
    .io_vecCommit_1_bits_robidx_flag  (vc_flag[1]),           \
    .io_vecCommit_1_bits_robidx_value (vc_value[1]),          \
    .io_vecCommit_1_bits_uopidx       (vc_uop[1]),            \
    .io_enq_canAccept                 (P``_canAccept),        \
    .io_enq_sqCanAccept               (sqCanAccept),          \
    .io_enq_needAlloc_0               (needAlloc[0]),         \
    .io_enq_needAlloc_1               (needAlloc[1]),         \
    .io_enq_needAlloc_2               (needAlloc[2]),         \
    .io_enq_needAlloc_3               (needAlloc[3]),         \
    .io_enq_needAlloc_4               (needAlloc[4]),         \
    .io_enq_req_0_valid               (req_valid[0]),         \
    .io_enq_req_0_bits_fuType         (req_fuType[0]),        \
    .io_enq_req_0_bits_uopIdx         (req_uopIdx[0]),        \
    .io_enq_req_0_bits_robIdx_flag    (req_robFlag[0]),       \
    .io_enq_req_0_bits_robIdx_value   (req_robVal[0]),        \
    .io_enq_req_0_bits_lqIdx_flag     (req_lqFlag[0]),        \
    .io_enq_req_0_bits_lqIdx_value    (req_lqVal[0]),         \
    .io_enq_req_0_bits_numLsElem      (req_numElem[0]),       \
    .io_enq_req_1_valid               (req_valid[1]),         \
    .io_enq_req_1_bits_fuType         (req_fuType[1]),        \
    .io_enq_req_1_bits_uopIdx         (req_uopIdx[1]),        \
    .io_enq_req_1_bits_robIdx_flag    (req_robFlag[1]),       \
    .io_enq_req_1_bits_robIdx_value   (req_robVal[1]),        \
    .io_enq_req_1_bits_lqIdx_flag     (req_lqFlag[1]),        \
    .io_enq_req_1_bits_lqIdx_value    (req_lqVal[1]),         \
    .io_enq_req_1_bits_numLsElem      (req_numElem[1]),       \
    .io_enq_req_2_valid               (req_valid[2]),         \
    .io_enq_req_2_bits_fuType         (req_fuType[2]),        \
    .io_enq_req_2_bits_uopIdx         (req_uopIdx[2]),        \
    .io_enq_req_2_bits_robIdx_flag    (req_robFlag[2]),       \
    .io_enq_req_2_bits_robIdx_value   (req_robVal[2]),        \
    .io_enq_req_2_bits_lqIdx_flag     (req_lqFlag[2]),        \
    .io_enq_req_2_bits_lqIdx_value    (req_lqVal[2]),         \
    .io_enq_req_2_bits_numLsElem      (req_numElem[2]),       \
    .io_enq_req_3_valid               (req_valid[3]),         \
    .io_enq_req_3_bits_fuType         (req_fuType[3]),        \
    .io_enq_req_3_bits_uopIdx         (req_uopIdx[3]),        \
    .io_enq_req_3_bits_robIdx_flag    (req_robFlag[3]),       \
    .io_enq_req_3_bits_robIdx_value   (req_robVal[3]),        \
    .io_enq_req_3_bits_lqIdx_flag     (req_lqFlag[3]),        \
    .io_enq_req_3_bits_lqIdx_value    (req_lqVal[3]),         \
    .io_enq_req_3_bits_numLsElem      (req_numElem[3]),       \
    .io_enq_req_4_valid               (req_valid[4]),         \
    .io_enq_req_4_bits_fuType         (req_fuType[4]),        \
    .io_enq_req_4_bits_uopIdx         (req_uopIdx[4]),        \
    .io_enq_req_4_bits_robIdx_flag    (req_robFlag[4]),       \
    .io_enq_req_4_bits_robIdx_value   (req_robVal[4]),        \
    .io_enq_req_4_bits_lqIdx_flag     (req_lqFlag[4]),        \
    .io_enq_req_4_bits_lqIdx_value    (req_lqVal[4]),         \
    .io_enq_req_4_bits_numLsElem      (req_numElem[4]),       \
    .io_enq_req_5_valid               (req_valid[5]),         \
    .io_enq_req_5_bits_fuType         (req_fuType[5]),        \
    .io_enq_req_5_bits_uopIdx         (req_uopIdx[5]),        \
    .io_enq_req_5_bits_robIdx_flag    (req_robFlag[5]),       \
    .io_enq_req_5_bits_robIdx_value   (req_robVal[5]),        \
    .io_enq_req_5_bits_lqIdx_flag     (req_lqFlag[5]),        \
    .io_enq_req_5_bits_lqIdx_value    (req_lqVal[5]),         \
    .io_enq_req_5_bits_numLsElem      (req_numElem[5]),       \
    .io_ldin_0_valid                  (ldin_valid[0]),        \
    .io_ldin_0_bits_uop_lqIdx_value   (ldin_lqVal[0]),        \
    .io_ldin_0_bits_isvec             (ldin_isvec[0]),        \
    .io_ldin_0_bits_updateAddrValid   (ldin_upd[0]),          \
    .io_ldin_0_bits_rep_info_cause_0  (ldin_cause[0][0]),     \
    .io_ldin_0_bits_rep_info_cause_1  (ldin_cause[0][1]),     \
    .io_ldin_0_bits_rep_info_cause_2  (ldin_cause[0][2]),     \
    .io_ldin_0_bits_rep_info_cause_3  (ldin_cause[0][3]),     \
    .io_ldin_0_bits_rep_info_cause_4  (ldin_cause[0][4]),     \
    .io_ldin_0_bits_rep_info_cause_5  (ldin_cause[0][5]),     \
    .io_ldin_0_bits_rep_info_cause_6  (ldin_cause[0][6]),     \
    .io_ldin_0_bits_rep_info_cause_7  (ldin_cause[0][7]),     \
    .io_ldin_0_bits_rep_info_cause_8  (ldin_cause[0][8]),     \
    .io_ldin_0_bits_rep_info_cause_9  (ldin_cause[0][9]),     \
    .io_ldin_0_bits_rep_info_cause_10 (ldin_cause[0][10]),    \
    .io_ldin_1_valid                  (ldin_valid[1]),        \
    .io_ldin_1_bits_uop_lqIdx_value   (ldin_lqVal[1]),        \
    .io_ldin_1_bits_isvec             (ldin_isvec[1]),        \
    .io_ldin_1_bits_updateAddrValid   (ldin_upd[1]),          \
    .io_ldin_1_bits_rep_info_cause_0  (ldin_cause[1][0]),     \
    .io_ldin_1_bits_rep_info_cause_1  (ldin_cause[1][1]),     \
    .io_ldin_1_bits_rep_info_cause_2  (ldin_cause[1][2]),     \
    .io_ldin_1_bits_rep_info_cause_3  (ldin_cause[1][3]),     \
    .io_ldin_1_bits_rep_info_cause_4  (ldin_cause[1][4]),     \
    .io_ldin_1_bits_rep_info_cause_5  (ldin_cause[1][5]),     \
    .io_ldin_1_bits_rep_info_cause_6  (ldin_cause[1][6]),     \
    .io_ldin_1_bits_rep_info_cause_7  (ldin_cause[1][7]),     \
    .io_ldin_1_bits_rep_info_cause_8  (ldin_cause[1][8]),     \
    .io_ldin_1_bits_rep_info_cause_9  (ldin_cause[1][9]),     \
    .io_ldin_1_bits_rep_info_cause_10 (ldin_cause[1][10]),    \
    .io_ldin_2_valid                  (ldin_valid[2]),        \
    .io_ldin_2_bits_uop_lqIdx_value   (ldin_lqVal[2]),        \
    .io_ldin_2_bits_isvec             (ldin_isvec[2]),        \
    .io_ldin_2_bits_updateAddrValid   (ldin_upd[2]),          \
    .io_ldin_2_bits_rep_info_cause_0  (ldin_cause[2][0]),     \
    .io_ldin_2_bits_rep_info_cause_1  (ldin_cause[2][1]),     \
    .io_ldin_2_bits_rep_info_cause_2  (ldin_cause[2][2]),     \
    .io_ldin_2_bits_rep_info_cause_3  (ldin_cause[2][3]),     \
    .io_ldin_2_bits_rep_info_cause_4  (ldin_cause[2][4]),     \
    .io_ldin_2_bits_rep_info_cause_5  (ldin_cause[2][5]),     \
    .io_ldin_2_bits_rep_info_cause_6  (ldin_cause[2][6]),     \
    .io_ldin_2_bits_rep_info_cause_7  (ldin_cause[2][7]),     \
    .io_ldin_2_bits_rep_info_cause_8  (ldin_cause[2][8]),     \
    .io_ldin_2_bits_rep_info_cause_9  (ldin_cause[2][9]),     \
    .io_ldin_2_bits_rep_info_cause_10 (ldin_cause[2][10]),    \
    .io_ldWbPtr_flag                  (P``_wbFlag),           \
    .io_ldWbPtr_value                 (P``_wbValue),          \
    .io_lqEmpty                       (P``_lqEmpty),          \
    .io_lqDeq                         (P``_lqDeq),            \
    .io_lqCancelCnt                   (P``_cancelCnt),        \
    .io_lqDeqRobIdx_flag              (P``_deqRobFlag),       \
    .io_lqDeqRobIdx_value             (P``_deqRobVal),        \
    .io_lqDeqUopIdx                   (P``_deqUop)

  VirtualLoadQueue    u_golden (`VLQ_PORTS(g));
  VirtualLoadQueue_xs u_impl   (`VLQ_PORTS(x));

  // ---------------- 激励 ----------------
  task automatic drive_idle();
    redirect_valid = 1'b0;
    redirect_flag  = 1'b0;
    redirect_value = 8'h0;
    redirect_level = 1'b0;
    sqCanAccept    = 1'b1;
    for (int j = 0; j < VEC_W; j++) begin
      vc_valid[j] = 1'b0; vc_flag[j] = 1'b0; vc_value[j] = 8'h0; vc_uop[j] = 7'h0;
    end
    for (int j = 0; j < 5; j++) needAlloc[j] = 1'b0;
    for (int j = 0; j < ENQ_W; j++) begin
      req_valid[j]  = 1'b0; req_fuType[j] = 35'h0; req_uopIdx[j] = 7'h0;
      req_robFlag[j]= 1'b0; req_robVal[j] = 8'h0;
      req_lqFlag[j] = 1'b0; req_lqVal[j]  = 7'h0;  req_numElem[j] = 5'h0;
    end
    for (int j = 0; j < LD_W; j++) begin
      ldin_valid[j] = 1'b0; ldin_lqVal[j] = 7'h0; ldin_isvec[j] = 1'b0;
      ldin_upd[j]   = 1'b0; ldin_cause[j] = 11'h0;
    end
  endtask

  // 一拍写满全部 72 个条目，消掉无复位阵列的上电不定态
  task automatic drive_fill();
    drive_idle();
    for (int j = 0; j < 3; j++) begin
      req_valid[j]   = 1'b1;
      req_lqFlag[j]  = 1'b0;
      req_lqVal[j]   = 7'(j * 24);
      req_numElem[j] = 5'd24;
      req_robVal[j]  = 8'(j);
      req_uopIdx[j]  = 7'(j);
      req_fuType[j]  = 35'h0;
    end
  endtask

  task automatic drive_random();
    drive_idle();
    // redirect：约 1/32 的拍数
    if ($urandom_range(0, 31) == 0) begin
      redirect_valid = 1'b1;
      redirect_flag  = $urandom_range(0, 1);
      redirect_value = 8'($urandom_range(0, 47));
      redirect_level = $urandom_range(0, 1);
    end
    sqCanAccept = ($urandom_range(0, 15) != 0);
    // 入队：大多数拍有 1~3 条请求
    for (int j = 0; j < ENQ_W; j++) begin
      req_valid[j]   = ($urandom_range(0, 3) == 0);
      req_lqFlag[j]  = $urandom_range(0, 1);
      req_lqVal[j]   = 7'($urandom_range(0, LQ_SIZE - 1));
      req_numElem[j] = 5'($urandom_range(0, 8));
      req_robFlag[j] = $urandom_range(0, 1);
      req_robVal[j]  = 8'($urandom_range(0, 47));
      req_uopIdx[j]  = 7'($urandom_range(0, 7));
      // fuType 只有 bit31/bit33 被读；别的位随机，顺便验证它们确实不影响结果
      req_fuType[j]  = {$urandom, $urandom} & 35'h7_FFFF_FFFF;
    end
    for (int j = 0; j < 5; j++) needAlloc[j] = $urandom_range(0, 1);
    // 向量提交反馈
    for (int j = 0; j < VEC_W; j++) begin
      vc_valid[j] = ($urandom_range(0, 3) == 0);
      vc_flag[j]  = $urandom_range(0, 1);
      vc_value[j] = 8'($urandom_range(0, 47));
      vc_uop[j]   = 7'($urandom_range(0, 7));
    end
    // load unit s3 写回：cause 多数为 0（= 不需要 replay，这次算完成）
    for (int j = 0; j < LD_W; j++) begin
      ldin_valid[j] = ($urandom_range(0, 2) != 0);
      ldin_lqVal[j] = 7'($urandom_range(0, LQ_SIZE - 1));
      ldin_isvec[j] = ($urandom_range(0, 3) == 0);
      ldin_upd[j]   = ($urandom_range(0, 7) != 0);
      ldin_cause[j] = ($urandom_range(0, 3) == 0) ? 11'(1 << $urandom_range(0, 10)) : 11'h0;
    end
  endtask

  // ---------------- 比对 ----------------
  task automatic check();
    if (g_canAccept  !== x_canAccept ) report_err("io_enq_canAccept",     {31'h0, g_canAccept },  {31'h0, x_canAccept });
    if (g_wbFlag     !== x_wbFlag    ) report_err("io_ldWbPtr_flag",      {31'h0, g_wbFlag    },  {31'h0, x_wbFlag    });
    if (g_wbValue    !== x_wbValue   ) report_err("io_ldWbPtr_value",     {25'h0, g_wbValue   },  {25'h0, x_wbValue   });
    if (g_lqEmpty    !== x_lqEmpty   ) report_err("io_lqEmpty",           {31'h0, g_lqEmpty   },  {31'h0, x_lqEmpty   });
    if (g_lqDeq      !== x_lqDeq     ) report_err("io_lqDeq",             {28'h0, g_lqDeq     },  {28'h0, x_lqDeq     });
    if (g_cancelCnt  !== x_cancelCnt ) report_err("io_lqCancelCnt",       {25'h0, g_cancelCnt },  {25'h0, x_cancelCnt });
    if (g_deqRobFlag !== x_deqRobFlag) report_err("io_lqDeqRobIdx_flag",  {31'h0, g_deqRobFlag},  {31'h0, x_deqRobFlag});
    if (g_deqRobVal  !== x_deqRobVal ) report_err("io_lqDeqRobIdx_value", {24'h0, g_deqRobVal },  {24'h0, x_deqRobVal });
    if (g_deqUop     !== x_deqUop    ) report_err("io_lqDeqUopIdx",       {25'h0, g_deqUop    },  {25'h0, x_deqUop    });
  endtask

  task automatic report_err(string name, logic [31:0] g, logic [31:0] x);
    errors++;
    if (errors <= 20)
      $display("[ERROR] cyc=%0d %s golden=%h impl=%h", cyc, name, g, x);
  endtask

  initial begin
    errors     = 0;
    cyc        = 0;
    cmp_cycles = 0;
    if (!$value$plusargs("ncycles=%d", ncycles)) ncycles = 200000;

    drive_idle();
    reset = 1'b1;
    repeat (10) @(posedge clock);
    @(negedge clock);
    reset = 1'b0;

    // fill：写满 72 个条目（连着两拍，保证打拍寄存器也有确定值）
    for (int k = 0; k < 2; k++) begin
      drive_fill();
      @(posedge clock);
      @(negedge clock);
      cyc++;
    end
    // 再空转几拍让 lqEmpty_REG / lastCycleRedirect 链路稳定
    for (int k = 0; k < 4; k++) begin
      drive_idle();
      @(posedge clock);
      @(negedge clock);
      cyc++;
    end

    while (cyc < ncycles) begin
      drive_random();
      @(posedge clock);
      #1;
      check();
      cmp_cycles++;
      @(negedge clock);
      cyc++;
    end

    drive_idle();
    repeat (2) @(posedge clock);

    $display("=== VirtualLoadQueue UT: cycles=%0d compared=%0d errors=%0d ===",
             cyc, cmp_cycles, errors);
    if (errors == 0) $display("TEST PASSED");
    else             $display("TEST FAILED");
    $finish;
  end

endmodule
