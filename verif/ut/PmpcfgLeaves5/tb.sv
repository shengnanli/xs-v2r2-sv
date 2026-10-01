// PmpcfgLeaves5 双例化逐拍比对 tb —— golden Pmp{0..4}cfgModule vs 重写 Pmp{0..4}cfgModule_xs
// （ut_gen/ 下由 derive_ut_impl.py 派生）。五变体共享同一组 w_wen/w_wdata 激励：变体间逻辑
// 逐字节相同（差异只在模块名与父层地址译码），双例化一轮同时验 5 份 wrapper 的端口转接
// 与共享核的行为。每拍比对每变体 6 个输出（rdata[7:0]、regOut_R/W/X/A/L）。
// 覆盖闸（防 "DUT 根本没动也全绿"）：
//   checks      输出打包比对次数（0 直接 FAIL）；
//   toggled     5 变体 x 6 信号 = 30 个输出里至少翻转过一次的个数（< 30 判 FAIL）；
//   fires       w_wen 写拍数（< MIN_FIRES 判 FAIL）；
//   warl_a2     写数据 A 字段 = 2（NA4 保留编码，WARL 落 NAPOT）的写拍数（< MIN_WARL_A2 判 FAIL）；
//   w_reserved  写数据 R=0 且 W=1（保留组合，该拍 W 被抑制）的写拍数（< MIN_W_RES 判 FAIL）；
//   l_rewrite   L 已置 1（锁定）期间又发起写的拍数（< MIN_L_REWRITE 判 FAIL；
//               本族 L 不回读门控写，golden 即如此，此桶验"置 L 后仍改写"这条路径）。
`timescale 1ns/1ps
module tb;
  // 拍数默认 200000，被 ut_common.mk 下发的 +ncycles=<n> 覆盖。
  int unsigned NCYCLES = 200000;
  localparam int NVAR = 5;    // 变体数
  localparam int NSIG = 6;    // 每变体输出信号数（rdata/R/W/X/A/L）
  localparam int DIRECTED = 16;
  localparam longint MIN_FIRES     = 10000;
  localparam longint MIN_WARL_A2   = 1000;
  localparam longint MIN_W_RES     = 1000;
  localparam longint MIN_L_REWRITE = 1000;

  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;
  longint checks = 0, errors = 0, fires = 0;
  longint warl_a2 = 0, w_reserved = 0, l_rewrite = 0;

  logic        w_wen;
  logic [63:0] w_wdata;

  // golden / impl 各 5 例化的输出
  wire [7:0] g_rdata [NVAR];
  wire       g_r [NVAR];
  wire       g_w [NVAR];
  wire       g_x [NVAR];
  wire [1:0] g_a [NVAR];
  wire       g_l [NVAR];
  wire [7:0] i_rdata [NVAR];
  wire       i_r [NVAR];
  wire       i_w [NVAR];
  wire       i_x [NVAR];
  wire [1:0] i_a [NVAR];
  wire       i_l [NVAR];

  Pmp0cfgModule u_g0 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(g_rdata[0]), .regOut_R(g_r[0]), .regOut_W(g_w[0]), .regOut_X(g_x[0]),
    .regOut_A(g_a[0]), .regOut_L(g_l[0]));
  Pmp1cfgModule u_g1 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(g_rdata[1]), .regOut_R(g_r[1]), .regOut_W(g_w[1]), .regOut_X(g_x[1]),
    .regOut_A(g_a[1]), .regOut_L(g_l[1]));
  Pmp2cfgModule u_g2 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(g_rdata[2]), .regOut_R(g_r[2]), .regOut_W(g_w[2]), .regOut_X(g_x[2]),
    .regOut_A(g_a[2]), .regOut_L(g_l[2]));
  Pmp3cfgModule u_g3 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(g_rdata[3]), .regOut_R(g_r[3]), .regOut_W(g_w[3]), .regOut_X(g_x[3]),
    .regOut_A(g_a[3]), .regOut_L(g_l[3]));
  Pmp4cfgModule u_g4 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(g_rdata[4]), .regOut_R(g_r[4]), .regOut_W(g_w[4]), .regOut_X(g_x[4]),
    .regOut_A(g_a[4]), .regOut_L(g_l[4]));

  Pmp0cfgModule_xs u_i0 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(i_rdata[0]), .regOut_R(i_r[0]), .regOut_W(i_w[0]), .regOut_X(i_x[0]),
    .regOut_A(i_a[0]), .regOut_L(i_l[0]));
  Pmp1cfgModule_xs u_i1 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(i_rdata[1]), .regOut_R(i_r[1]), .regOut_W(i_w[1]), .regOut_X(i_x[1]),
    .regOut_A(i_a[1]), .regOut_L(i_l[1]));
  Pmp2cfgModule_xs u_i2 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(i_rdata[2]), .regOut_R(i_r[2]), .regOut_W(i_w[2]), .regOut_X(i_x[2]),
    .regOut_A(i_a[2]), .regOut_L(i_l[2]));
  Pmp3cfgModule_xs u_i3 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(i_rdata[3]), .regOut_R(i_r[3]), .regOut_W(i_w[3]), .regOut_X(i_x[3]),
    .regOut_A(i_a[3]), .regOut_L(i_l[3]));
  Pmp4cfgModule_xs u_i4 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(i_rdata[4]), .regOut_R(i_r[4]), .regOut_W(i_w[4]), .regOut_X(i_x[4]),
    .regOut_A(i_a[4]), .regOut_L(i_l[4]));

  // 打包便于比对与翻转统计：[13:6]=rdata [5]=L [4:3]=A [2]=X [1]=W [0]=R
  wire [13:0] g_pack [NVAR];
  wire [13:0] i_pack [NVAR];
  for (genvar v = 0; v < NVAR; v++) begin : pack_loop
    assign g_pack[v] = {g_rdata[v], g_l[v], g_a[v], g_x[v], g_w[v], g_r[v]};
    assign i_pack[v] = {i_rdata[v], i_l[v], i_a[v], i_x[v], i_w[v], i_r[v]};
  end

  logic [13:0] prev_pack [NVAR];
  bit [NVAR*NSIG-1:0] tog_mask;   // v*NSIG+0=rdata 1=L 2=A 3=X 4=W 5=R

  task automatic check_outputs();
    for (int v = 0; v < NVAR; v++) begin
      if (!$isunknown(g_pack[v])) begin
        checks++;
        if (g_pack[v] !== i_pack[v]) begin
          errors++;
          if (errors <= 30)
            $display("[%0t] MISMATCH variant=%0d g=%b i=%b", $time, v, g_pack[v], i_pack[v]);
        end
      end
    end
  endtask

  task automatic sample_coverage();
    for (int v = 0; v < NVAR; v++) begin
      if (g_pack[v][13:6] !== prev_pack[v][13:6]) tog_mask[v*NSIG+0] = 1'b1;
      if (g_pack[v][5]    !== prev_pack[v][5])    tog_mask[v*NSIG+1] = 1'b1;
      if (g_pack[v][4:3]  !== prev_pack[v][4:3])  tog_mask[v*NSIG+2] = 1'b1;
      if (g_pack[v][2]    !== prev_pack[v][2])    tog_mask[v*NSIG+3] = 1'b1;
      if (g_pack[v][1]    !== prev_pack[v][1])    tog_mask[v*NSIG+4] = 1'b1;
      if (g_pack[v][0]    !== prev_pack[v][0])    tog_mask[v*NSIG+5] = 1'b1;
      prev_pack[v] = g_pack[v];
    end
    if (w_wen) begin
      fires++;
      if (w_wdata[4:3] == 2'd2) warl_a2++;
      if (!w_wdata[0] && w_wdata[1]) w_reserved++;
      if (g_l[0]) l_rewrite++;   // 采样点在写提交前，g_l[0] 是改写前的旧 L
    end
  endtask

  // 定向段：把两条 WARL 规则、L 置位后改写、写使能关断、全角写数据逐一点名。
  task automatic drive_directed(input int unsigned c);
    w_wen = 1'b1;
    w_wdata = 64'h0;
    case (c)
      0:  w_wdata[7:0] = 8'h00;                                  // 全清
      1:  w_wdata[4:3] = 2'd0;                                   // A=OFF
      2:  w_wdata[4:3] = 2'd1;                                   // A=TOR
      3:  w_wdata[4:3] = 2'd2;                                   // A 写保留编码 2 -> 落 3(NAPOT)
      4:  w_wdata[4:3] = 2'd3;                                   // A=NAPOT
      5:  begin w_wdata[0] = 1'b0; w_wdata[1] = 1'b1; end        // R=0,W=1：W 保持 0（抑制）
      6:  begin w_wdata[0] = 1'b1; w_wdata[1] = 1'b1; end        // R=1,W=1：W 落 1
      7:  begin w_wdata[0] = 1'b0; w_wdata[1] = 1'b1; end        // R=0,W=1：W 保持 1（抑制）
      8:  w_wdata[7:0] = 8'h80;                                  // 置 L，清其余
      9:  w_wdata[7:0] = 8'hFF;                                  // L 锁定期间全 1 改写尝试
      10: w_wdata[7:0] = 8'h00;                                  // L 锁定期间清零尝试（本族 L 不门控）
      11: begin w_wen = 1'b0; w_wdata = {64{1'b1}}; end          // 写使能关断一拍
      12: w_wdata = 64'hFFFF_FFFF_FFFF_FFFF;                     // 全角写数据（高 56 位无字段）
      13: w_wdata = 64'h0000_0000_0000_0055;                     // 低字节 0101_0101
      default: begin w_wdata = {$urandom, $urandom}; end
    endcase
  endtask

  // 随机段：75% 写使能，低字节按 1/4 概率压向各 WARL/边界形状。
  task automatic drive_random();
    w_wen = (($urandom % 4) != 0);
    w_wdata = {$urandom, $urandom};
    case ($urandom % 8)
      0, 1: w_wdata[4:3] = 2'd2;                                 // WARL：A 写保留编码 2
      2, 3: begin w_wdata[0] = 1'b0; w_wdata[1] = 1'b1; end      // 保留组合 R=0,W=1
      4:    w_wdata[7] = 1'b1;                                   // 置 L
      5:    w_wdata[7:0] = 8'hFF;                                // 全 1 低字节
      6:    w_wdata[7:0] = 8'h00;                                // 全 0 低字节
      default: begin end                                         // 纯随机
    endcase
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    w_wen = 1'b0;
    w_wdata = '0;
    for (int v = 0; v < NVAR; v++) prev_pack[v] = '0;
    tog_mask = '0;
    reset = 1'b1;
    repeat (5) @(posedge clock);
    @(negedge clock);
    reset = 1'b0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      // 中途再复位一次，覆盖复位路径（两侧同拍同源）。
      // 复位后 prev_pack 与现值的差会多记几个翻转位——覆盖闸是最低门槛，偏保守，无害。
      if (c == NCYCLES/2) begin
        reset = 1'b1;
        repeat (3) @(posedge clock);
        @(negedge clock);
        reset = 1'b0;
      end
      // 激励一律在 negedge 驱动：若在 posedge 同一时刻改 w_wdata，两侧 always_ff
      // 与 tb 阻塞赋值的求值顺序是竞争，golden 与 impl 可能各采到新旧不同值。
      @(negedge clock);
      if (c < DIRECTED) drive_directed(c); else drive_random();
      #1 check_outputs();
      sample_coverage();
      @(posedge clock);
    end

    begin
      int t = 0;
      for (int s = 0; s < NVAR*NSIG; s++) begin
        if (tog_mask[s]) t++;
        else $display("COV: output signal %0d never toggled", s);
      end
      $display("PmpcfgLeaves5 checks=%0d errors=%0d toggled=%0d/%0d fires=%0d warl_a2=%0d w_reserved=%0d l_rewrite=%0d",
               checks, errors, t, NVAR*NSIG, fires, warl_a2, w_reserved, l_rewrite);
      if (errors != 0) begin
        $display("TEST FAILED (mismatch)"); $fatal(1);
      end
      if (checks == 0) begin
        $display("TEST FAILED (coverage: no comparison happened)"); $fatal(1);
      end
      if (t < NVAR*NSIG) begin
        $display("TEST FAILED (coverage: only %0d outputs toggled, need %0d)", t, NVAR*NSIG);
        $fatal(1);
      end
      if (fires < MIN_FIRES) begin
        $display("TEST FAILED (coverage: only %0d write fires, need >= %0d)", fires, MIN_FIRES);
        $fatal(1);
      end
      if (warl_a2 < MIN_WARL_A2) begin
        $display("TEST FAILED (coverage: A=2 WARL writes only %0d, need >= %0d)", warl_a2, MIN_WARL_A2);
        $fatal(1);
      end
      if (w_reserved < MIN_W_RES) begin
        $display("TEST FAILED (coverage: R=0&W=1 reserved writes only %0d, need >= %0d)", w_reserved, MIN_W_RES);
        $fatal(1);
      end
      if (l_rewrite < MIN_L_REWRITE) begin
        $display("TEST FAILED (coverage: writes while L set only %0d, need >= %0d)", l_rewrite, MIN_L_REWRITE);
        $fatal(1);
      end
      $display("TEST PASSED");
      $finish;
    end
  end
endmodule
