// LqRawCam UT —— LqMaskModule / LqPAddrModule_1 两对 golden vs 重写件双例化，逐拍比全部输出
//
// 两个模块共用同一套写激励（写口 3 个、地址 5 位 = 32 项、恰好无越界地址），各自的
// 写数据与 CAM 查询数据分开生成。逐拍比对 2×32 位命中向量（每模块 64 个输出口）。
//
// 定向打的点（纯均匀随机打不到或打到了也看不出）：
//  (1) 同拍多写口撞同一条目：Mux1H 的"按位或"语义（上游保证不撞，golden 仅有非综合断言）；
//  (2) CAM 命中要常见：掩码用稀疏位、地址用小值池（4 个 cacheline × 4 个 16B 块），
//      否则 24 位地址几乎永不命中，比对的全是 0；
//  (3) checkLine=1（整行写）与 =0 两种都要有，且"同 cacheline 不同 16B 块"要常见 ——
//      这是两种规则唯一分得开的输入；
//  (4) 写打拍：写要 1 拍后才落到条目，同拍的 CAM 看到的是旧值。
//
// ★暖机（WARMUP）：本模块全部寄存器不复位。+vcs+initreg+random 下 golden 与重写件的
//   随机初值不同，比对"谁也没写过的条目"必然不一致 —— 那是不复位状态本身没有定义。
//   所以先用 WARMUP 拍把 32 个条目全部写一遍（3 口并行，11 拍写完，留足余量）再开始比对。
`timescale 1ns/1ps
module tb;
  localparam int N  = 32;

  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic        wen [3];
  logic [4:0]  waddr [3];
  logic [15:0] mk_wdata [3];
  logic [23:0] pa_wdata [3];
  logic [15:0] mk_mdata [2];
  logic [23:0] pa_mdata [2];
  logic        pa_line  [2];

  wire [31:0] g_mk [2], i_mk [2], g_pa [2], i_pa [2];

  // ---- 双例化：golden（原名）与重写件（_xs 后缀，由 derive_ut_impl.py 派生）----
  `define LQ_CAM_PORTS(D0, D1, D2) \
    .clock(clk), .reset(rst), \
    .io_wen_0(wen[0]), .io_wen_1(wen[1]), .io_wen_2(wen[2]), \
    .io_waddr_0(waddr[0]), .io_waddr_1(waddr[1]), .io_waddr_2(waddr[2]), \
    .io_wdata_0(D0[0]), .io_wdata_1(D0[1]), .io_wdata_2(D0[2]), \
    .io_violationMdata_0(D1[0]), .io_violationMdata_1(D1[1])

  `define LQ_CAM_OUT(V, C) \
    .io_violationMmask_``C``_0 (V[C][0]),  .io_violationMmask_``C``_1 (V[C][1]), \
    .io_violationMmask_``C``_2 (V[C][2]),  .io_violationMmask_``C``_3 (V[C][3]), \
    .io_violationMmask_``C``_4 (V[C][4]),  .io_violationMmask_``C``_5 (V[C][5]), \
    .io_violationMmask_``C``_6 (V[C][6]),  .io_violationMmask_``C``_7 (V[C][7]), \
    .io_violationMmask_``C``_8 (V[C][8]),  .io_violationMmask_``C``_9 (V[C][9]), \
    .io_violationMmask_``C``_10(V[C][10]), .io_violationMmask_``C``_11(V[C][11]), \
    .io_violationMmask_``C``_12(V[C][12]), .io_violationMmask_``C``_13(V[C][13]), \
    .io_violationMmask_``C``_14(V[C][14]), .io_violationMmask_``C``_15(V[C][15]), \
    .io_violationMmask_``C``_16(V[C][16]), .io_violationMmask_``C``_17(V[C][17]), \
    .io_violationMmask_``C``_18(V[C][18]), .io_violationMmask_``C``_19(V[C][19]), \
    .io_violationMmask_``C``_20(V[C][20]), .io_violationMmask_``C``_21(V[C][21]), \
    .io_violationMmask_``C``_22(V[C][22]), .io_violationMmask_``C``_23(V[C][23]), \
    .io_violationMmask_``C``_24(V[C][24]), .io_violationMmask_``C``_25(V[C][25]), \
    .io_violationMmask_``C``_26(V[C][26]), .io_violationMmask_``C``_27(V[C][27]), \
    .io_violationMmask_``C``_28(V[C][28]), .io_violationMmask_``C``_29(V[C][29]), \
    .io_violationMmask_``C``_30(V[C][30]), .io_violationMmask_``C``_31(V[C][31])

  LqMaskModule    g_mk_u (`LQ_CAM_PORTS(mk_wdata, mk_mdata, 0), `LQ_CAM_OUT(g_mk, 0), `LQ_CAM_OUT(g_mk, 1));
  LqMaskModule_xs i_mk_u (`LQ_CAM_PORTS(mk_wdata, mk_mdata, 0), `LQ_CAM_OUT(i_mk, 0), `LQ_CAM_OUT(i_mk, 1));
  LqPAddrModule_1    g_pa_u (`LQ_CAM_PORTS(pa_wdata, pa_mdata, 0),
                             .io_violationCheckLine_0(pa_line[0]), .io_violationCheckLine_1(pa_line[1]),
                             `LQ_CAM_OUT(g_pa, 0), `LQ_CAM_OUT(g_pa, 1));
  LqPAddrModule_1_xs i_pa_u (`LQ_CAM_PORTS(pa_wdata, pa_mdata, 0),
                             .io_violationCheckLine_0(pa_line[0]), .io_violationCheckLine_1(pa_line[1]),
                             `LQ_CAM_OUT(i_pa, 0), `LQ_CAM_OUT(i_pa, 1));

  // ---------------------------------------------------------------------------
  // 激励
  // ---------------------------------------------------------------------------
  // 地址值池：高 22 位取 4 个 cacheline 标签之一，低 2 位（16B 块号）随机
  logic [21:0] line_pool [4];
  function automatic logic [23:0] rnd_paddr();
    return {line_pool[$urandom_range(0, 3)], 2'($urandom_range(0, 3))};
  endfunction
  // 稀疏字节掩码：1~3 个置位（偶尔全 0 / 全 1）
  function automatic logic [15:0] rnd_mask();
    logic [15:0] m;
    case ($urandom_range(0, 9))
      0: m = '0;
      1: m = 16'hFFFF;
      default: begin
        m = '0;
        repeat ($urandom_range(1, 3)) m[$urandom_range(0, 15)] = 1'b1;
      end
    endcase
    return m;
  endfunction

  localparam int WARMUP = 32;
  int cyc;
  wire warm = (cyc >= WARMUP);
  int cov_collide, cov_hit_mk, cov_hit_pa, cov_line_only;

  always @(negedge clk) begin
    if (rst) cyc <= 0; else cyc <= cyc + 1;
  end

  always @(negedge clk) begin
    if (rst) begin
      for (int w = 0; w < 3; w++) begin
        wen[w] <= 1'b0; waddr[w] <= '0; mk_wdata[w] <= '0; pa_wdata[w] <= '0;
      end
      for (int c = 0; c < 2; c++) begin
        mk_mdata[c] <= '0; pa_mdata[c] <= '0; pa_line[c] <= 1'b0;
      end
    end else if (!warm) begin
      // 暖机：cyc=0..10 按 3 口并行写满 0..31（第 11 拍的 33/34 回绕成 1/2，无害）
      for (int w = 0; w < 3; w++) begin
        wen[w]      <= 1'b1;
        waddr[w]    <= 5'((cyc % 11) * 3 + w);
        mk_wdata[w] <= rnd_mask();
        pa_wdata[w] <= rnd_paddr();
      end
    end else begin
      int a0;
      a0 = $urandom_range(0, N-1);
      case ($urandom_range(0, 9))
        // 定向撞地址：2 口或 3 口同拍写同一条目 → 只有"按位或"对得上
        0: begin
          wen[0] <= 1'b1; wen[1] <= 1'b1; wen[2] <= ($urandom_range(0, 1) == 1);
          waddr[0] <= 5'(a0); waddr[1] <= 5'(a0);
          waddr[2] <= ($urandom_range(0, 1) == 1) ? 5'(a0) : 5'($urandom_range(0, N-1));
          cov_collide <= cov_collide + 1;
        end
        default: begin
          for (int w = 0; w < 3; w++) begin
            wen[w]   <= ($urandom_range(0, 3) != 0);
            waddr[w] <= 5'($urandom_range(0, N-1));
          end
        end
      endcase
      for (int w = 0; w < 3; w++) begin
        mk_wdata[w] <= rnd_mask();
        pa_wdata[w] <= rnd_paddr();
      end
      for (int c = 0; c < 2; c++) begin
        mk_mdata[c] <= rnd_mask();
        // 10% 完全随机（几乎必不命中），其余从值池取
        pa_mdata[c] <= ($urandom_range(0, 9) == 0) ? 24'($urandom) : rnd_paddr();
        pa_line[c]  <= ($urandom_range(0, 2) == 0);
      end
      // 偶尔换一个 cacheline 标签，让池子慢慢漂移
      if ($urandom_range(0, 999) == 0) line_pool[$urandom_range(0, 3)] <= 22'($urandom);
    end
  end

  // ---------------------------------------------------------------------------
  // 比对
  // ---------------------------------------------------------------------------
  `define CHK(nm, g, i) \
    if ((g) !== (i)) begin errors++; \
      if (errors <= 40) $display("[cyc %0d] %s g=%h i=%h", cyc, nm, g, i); end

  always @(negedge clk) if (!rst && warm) begin
    #4; checks++;
    for (int c = 0; c < 2; c++) begin
      `CHK($sformatf("LqMaskModule.violationMmask_%0d", c), g_mk[c], i_mk[c])
      `CHK($sformatf("LqPAddrModule_1.violationMmask_%0d", c), g_pa[c], i_pa[c])
      if (|g_mk[c]) cov_hit_mk++;
      if (|g_pa[c]) cov_hit_pa++;
      if (pa_line[c] && (|g_pa[c])) cov_line_only++;
    end
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (int i = 0; i < 4; i++) line_pool[i] = 22'($urandom);
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("COV collide=%0d hit_mask=%0d hit_paddr=%0d hit_paddr_checkline=%0d",
             cov_collide, cov_hit_mk, cov_hit_pa, cov_line_only);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && cov_collide > 100 && cov_hit_mk > 1000
        && cov_hit_pa > 1000 && cov_line_only > 100)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
