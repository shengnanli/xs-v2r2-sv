// LqVAddrModule UT —— golden 与重写件双例化逐拍比对（72 项 × 50 位，3 读 3 写）
//
// 三个必须定向打的点（纯均匀随机要么打不到、要么打到了也看不出）：
//  (1) **越界读**：raddr 是 7 位，条目只有 72 个。firtool 把 Vec 读展开成 128 项
//      查找表，72..127 全部返回 data[0]（不是 0）。均匀随机 raddr 有 44% 概率
//      越界，但只有在 data[0] != 0 时才分得出"返回 data[0]"和"返回 0"，
//      所以这里先把 data[0] 写成非 0，再专门扫 72..127。
//  (2) **同拍两写口撞同一地址**：Chisel 用 Mux1H，结果是两份写数据**按位或**，
//      不是优先级选择。上游保证不撞（golden 有非综合断言），随机地址撞的概率
//      只有 ~1.4%/对，且要求两份数据不同才分得出，所以定向制造。
//  (3) **写打拍**：写要 1 拍以后才落到条目，读在同拍看到的是旧值。
//
// ★ 暖机（WARMUP）：本模块 75 个寄存器**全部不复位**。`+vcs+initreg+random` 下
//   golden 与重写件各自拿到**不同**的随机初值，此时比对读出的是"谁也没写过的
//   条目"，必然不一致 —— 这不是 bug，是不复位状态本身没有定义。所以先用
//   WARMUP 拍把 72 个条目全部写一遍（3 个写口并行，24 拍写完，留足余量），
//   写完之后两侧状态才有可比性，从那时起才开始计 checks/errors。
//   实测（不做暖机时）：错误全部集中在解复位后的头 14 拍，之后自动消失。
`timescale 1ns/1ps
module tb;
  localparam int N  = 72;
  localparam int DW = 50;

  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic        io_ren_0, io_ren_1, io_ren_2;
  logic [6:0]  io_raddr_0, io_raddr_1, io_raddr_2;
  logic        io_wen_0, io_wen_1, io_wen_2;
  logic [6:0]  io_waddr_0, io_waddr_1, io_waddr_2;
  logic [49:0] io_wdata_0, io_wdata_1, io_wdata_2;
  logic [49:0] g_rdata_0, g_rdata_1, g_rdata_2, i_rdata_0, i_rdata_1, i_rdata_2;

  LqVAddrModule g_u (
    .clock(clk), .reset(rst),
    .io_ren_0(io_ren_0), .io_ren_1(io_ren_1), .io_ren_2(io_ren_2),
    .io_raddr_0(io_raddr_0), .io_raddr_1(io_raddr_1), .io_raddr_2(io_raddr_2),
    .io_rdata_0(g_rdata_0), .io_rdata_1(g_rdata_1), .io_rdata_2(g_rdata_2),
    .io_wen_0(io_wen_0), .io_wen_1(io_wen_1), .io_wen_2(io_wen_2),
    .io_waddr_0(io_waddr_0), .io_waddr_1(io_waddr_1), .io_waddr_2(io_waddr_2),
    .io_wdata_0(io_wdata_0), .io_wdata_1(io_wdata_1), .io_wdata_2(io_wdata_2));

  LqVAddrModule_xs i_u (
    .clock(clk), .reset(rst),
    .io_ren_0(io_ren_0), .io_ren_1(io_ren_1), .io_ren_2(io_ren_2),
    .io_raddr_0(io_raddr_0), .io_raddr_1(io_raddr_1), .io_raddr_2(io_raddr_2),
    .io_rdata_0(i_rdata_0), .io_rdata_1(i_rdata_1), .io_rdata_2(i_rdata_2),
    .io_wen_0(io_wen_0), .io_wen_1(io_wen_1), .io_wen_2(io_wen_2),
    .io_waddr_0(io_waddr_0), .io_waddr_1(io_waddr_1), .io_waddr_2(io_waddr_2),
    .io_wdata_0(io_wdata_0), .io_wdata_1(io_wdata_1), .io_wdata_2(io_wdata_2));

  // ---------------------------------------------------------------------------
  // 覆盖统计
  // ---------------------------------------------------------------------------
  int cov_oob_read, cov_collide_w, cov_collide_w3, cov_write [N];
  int cov_bank_touch [8];

  function automatic logic [49:0] rnd50();
    return {$urandom, $urandom} & 50'h3_FFFF_FFFF_FFFF;
  endfunction

  int phase;

  // 暖机：0..WARMUP-1 拍按 3 口并行把 72 个条目全部写一遍，期间不比对
  localparam int WARMUP = 64;
  int cyc;
  wire warm = (cyc >= WARMUP);

  always @(negedge clk) begin
    if (rst) cyc <= 0; else cyc <= cyc + 1;
  end

  always @(negedge clk) begin
    if (rst) begin
      io_ren_0 <= 1'b0; io_ren_1 <= 1'b0; io_ren_2 <= 1'b0;
      io_wen_0 <= 1'b0; io_wen_1 <= 1'b0; io_wen_2 <= 1'b0;
      io_raddr_0 <= 7'h0; io_raddr_1 <= 7'h0; io_raddr_2 <= 7'h0;
      io_waddr_0 <= 7'h0; io_waddr_1 <= 7'h0; io_waddr_2 <= 7'h0;
      io_wdata_0 <= 50'h0; io_wdata_1 <= 50'h0; io_wdata_2 <= 50'h0;
      phase <= 0; cov_oob_read <= 0; cov_collide_w <= 0; cov_collide_w3 <= 0;
    end else if (!warm) begin
      // 暖机：每拍 3 口写 3 个条目，cyc=0..23 覆盖 0..71；其余暖机拍随便重写。
      int base;
      base = (cyc % 24) * 3;
      io_wen_0 <= 1'b1; io_wen_1 <= 1'b1; io_wen_2 <= 1'b1;
      io_waddr_0 <= 7'(base); io_waddr_1 <= 7'(base + 1); io_waddr_2 <= 7'(base + 2);
      io_wdata_0 <= rnd50(); io_wdata_1 <= rnd50(); io_wdata_2 <= rnd50();
      io_ren_0 <= 1'b1; io_ren_1 <= 1'b1; io_ren_2 <= 1'b1;
      io_raddr_0 <= 7'(base); io_raddr_1 <= 7'(base + 1); io_raddr_2 <= 7'(base + 2);
    end else begin
      int wa0, wa1, wa2, ra0, ra1, ra2;
      phase <= $urandom_range(0, 9);

      // ---- 写激励 ----
      case (phase)
        // 定向撞地址：两口/三口同拍写同一条目，数据互不相同 → 只有"按位或"
        // 才能对上 golden；优先级选择会立刻失配。
        0: begin
          wa0 = $urandom_range(0, N-1); wa1 = wa0; wa2 = $urandom_range(0, N-1);
          io_wen_0 <= 1'b1; io_wen_1 <= 1'b1; io_wen_2 <= ($urandom_range(0,1) == 1);
          cov_collide_w <= cov_collide_w + 1;
        end
        1: begin
          wa0 = $urandom_range(0, N-1); wa1 = wa0; wa2 = wa0;
          io_wen_0 <= 1'b1; io_wen_1 <= 1'b1; io_wen_2 <= 1'b1;
          cov_collide_w3 <= cov_collide_w3 + 1;
        end
        // 越界写地址：bank 切片全 0 ⇒ 不写任何条目
        2: begin
          wa0 = $urandom_range(N, 127); wa1 = $urandom_range(0, N-1);
          wa2 = $urandom_range(0, N-1);
          io_wen_0 <= 1'b1; io_wen_1 <= 1'b1; io_wen_2 <= 1'b1;
        end
        // 把 data[0] 写成随机非 0 —— 越界读要能与"返回 0"区分开，靠的就是它
        3: begin
          wa0 = 0; wa1 = $urandom_range(1, N-1); wa2 = $urandom_range(1, N-1);
          io_wen_0 <= 1'b1; io_wen_1 <= ($urandom_range(0,1) == 1);
          io_wen_2 <= ($urandom_range(0,1) == 1);
        end
        default: begin
          wa0 = $urandom_range(0, N-1); wa1 = $urandom_range(0, N-1);
          wa2 = $urandom_range(0, N-1);
          io_wen_0 <= ($urandom_range(0,3) != 0);
          io_wen_1 <= ($urandom_range(0,3) != 0);
          io_wen_2 <= ($urandom_range(0,3) != 0);
        end
      endcase
      io_waddr_0 <= wa0[6:0]; io_waddr_1 <= wa1[6:0]; io_waddr_2 <= wa2[6:0];
      io_wdata_0 <= rnd50();  io_wdata_1 <= rnd50();  io_wdata_2 <= rnd50();
      if (wa0 < N) cov_bank_touch[wa0/9] <= cov_bank_touch[wa0/9] + 1;

      // ---- 读激励：1/3 的拍子故意给越界地址 ----
      ra0 = ($urandom_range(0,2) == 0) ? $urandom_range(N,127) : $urandom_range(0,N-1);
      ra1 = ($urandom_range(0,2) == 0) ? $urandom_range(N,127) : $urandom_range(0,N-1);
      ra2 = $urandom_range(0,127);
      if (ra0 >= N || ra1 >= N || ra2 >= N) cov_oob_read <= cov_oob_read + 1;
      io_raddr_0 <= ra0[6:0]; io_raddr_1 <= ra1[6:0]; io_raddr_2 <= ra2[6:0];
      // ren 有时为 0：读数据寄存器要保持旧值（RegEnable 语义）
      io_ren_0 <= ($urandom_range(0,3) != 0);
      io_ren_1 <= ($urandom_range(0,3) != 0);
      io_ren_2 <= ($urandom_range(0,3) != 0);
    end
  end

  `define CHK(nm, g, i) \
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \
      if (errors <= 80) $display("[%0t] %s g=%h i=%h", $time, nm, g, i); end

  always @(negedge clk) if (!rst && warm) begin
    #4; checks++;
    `CHK("io_rdata_0", g_rdata_0, i_rdata_0)
    `CHK("io_rdata_1", g_rdata_1, i_rdata_1)
    `CHK("io_rdata_2", g_rdata_2, i_rdata_2)
    // 内部条目也比：输出只在 ren 拍暴露，条目写错可能要很久才漏出来
    if (!$isunknown(g_u.data_0)) begin
      `CHK("data_0",  g_u.data_0,  i_u.u_core.data[0])
      `CHK("data_8",  g_u.data_8,  i_u.u_core.data[8])
      `CHK("data_9",  g_u.data_9,  i_u.u_core.data[9])
      `CHK("data_71", g_u.data_71, i_u.u_core.data[71])
    end
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("COV oob_read=%0d collide_2w=%0d collide_3w=%0d", cov_oob_read,
             cov_collide_w, cov_collide_w3);
    $write("COV bank_touch:"); for (int b = 0; b < 8; b++) $write(" %0d", cov_bank_touch[b]);
    $display("");
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
