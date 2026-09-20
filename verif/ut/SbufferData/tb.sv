// =============================================================================
// tb —— SbufferData UT：golden SbufferData 与重写件 SbufferData_xs 双例化逐拍比对。
//
// 比什么：两侧各 1024 个 io_dataOut_* 与 1024 个 io_maskOut_*，由机械生成的
//   sbd_bridge 打包成向量后整体比较；一旦不等再逐字节定位并打印
//   (line, vword, byte) 三元组。
//
// ★暖机（data 不复位，必须先写满）★
//   golden 的 1024 个 data 字节是 `Reg(...)` 无复位，上电是随机值；initreg 会给
//   两侧**各自不同**的随机值，此时比 dataOut 只会比出"上电值不同"这种废话。
//   所以复位释放后先发一发 wvec=16'hFFFF + wline=1 的整行写：一拍就把 16 行 ×
//   4 vword × 16 字节 = 全部 1024 个字节写成同一份确定值，两侧从此完全同步。
//   maskOut 从复位起就可比（mask 是 RegInit(false)）。
//   ★暖机只对齐初值，不掩盖逻辑差异★：暖机后每一个字节都还在被随机写、被清掩码，
//   变异测试（见 README）证明暖机之后仍能抓到注入的 bug。
//
// ★定向激励（纯随机打不全的那几类）★
//   A 同拍两口写同一字节  —— 两口同 wvec、同 vwordOffset、掩码重叠、数据不同：
//                            验"写口 1 压过写口 0"的优先级。
//   B 写与清掩码同拍冲突  —— maskFlushReq 与写请求同拍给同一行（两者都打一拍后
//                            在同一拍落地）：验"写压过清"。
//   C 部分置位的字节掩码  —— 单点 / 稀疏 / 全 0 / 全 1 四档。
//   D 行边界与 vword 边界 —— 多热 wvec（一发写多行）、vwordOffset 取遍 0..3、
//                            wline 整行写（无视掩码与 vword）。
//   E 空闲保持            —— 两口都无效：验不复位寄存器"使能低时保持"。
//   F 中途随机复位脉冲    —— ★这一条专治复位域★。暖机之后两侧 data 已完全同步，
//                            此时拉一下 reset：golden 的 data **不复位**所以原样
//                            保持，mask 则立刻异步清零。若重写件多给 data 加了复位
//                            （elaborate 与 lint 都不会报的那类真 bug），这一拍就
//                            当场失配。用随机初值(initreg random)跑也照样有判别力，
//                            因为比的是"复位前后 data 有没有变"，不是上电值。
// =============================================================================
`timescale 1ns/1ps
module tb;

  int unsigned NCYCLES = 200000;
  localparam int RST_CYC  = 4;    // 复位保持拍数
  localparam int WARM_CYC = 8;    // 暖机（写满 data）结束拍；此后开始比 dataOut

  bit clk = 0;
  always #5 clk = ~clk;

  longint errors = 0, checks = 0;
  longint cyc = 0;
  int     rst_hold = 0;         // 复位脉冲剩余拍数

  logic        rst;
  logic [1:0]        wvalid;
  logic [1:0][15:0]  wvec;
  logic [1:0][15:0]  wmask;
  logic [1:0][127:0] wdata;
  logic [1:0][43:0]  wvwoff;
  logic [1:0]        wline;
  logic              fvalid;
  logic [15:0]       fvec;

  logic [1023:0][7:0] g_data, i_data;
  logic [1023:0]      g_mask, i_mask;

  sbd_bridge u_b (
    .clk(clk), .rst(rst),
    .wvalid(wvalid), .wvec(wvec), .wmask(wmask), .wdata(wdata),
    .wvwoff(wvwoff), .wline(wline), .fvalid(fvalid), .fvec(fvec),
    .g_data(g_data), .g_mask(g_mask), .i_data(i_data), .i_mask(i_mask)
  );

  // ---------------------------------------------------------------------------
  // 覆盖证据
  // ---------------------------------------------------------------------------
  int unsigned cov_mode      [8];   // 8 种激励模式
  int unsigned cov_vword     [4];   // vwordOffset 低两位取遍 0..3
  int unsigned cov_line      [16];  // 每一行都被写过
  int unsigned cov_maskcls   [4];   // 字节掩码：全 0 / 单点 / 稀疏 / 全 1
  int unsigned cov_wline;           // 整行写
  int unsigned cov_2port;           // 两口同拍都有效
  int unsigned cov_byte_clash;      // ★两口同拍写同一字节（优先级冲突）★
  int unsigned cov_wr_vs_clean;     // ★写与清掩码同拍打到同一行★
  int unsigned cov_idle;            // 两口都空闲
  int unsigned cov_mask_set, cov_mask_clr;  // 观察到 maskOut 置位 / 清零的拍数
  int unsigned cov_rst_pulse;       // 暖机后的随机复位脉冲次数（复位域判别力来源）

  logic [1023:0] prev_gmask;

  function automatic int mask_class(input logic [15:0] m);
    int n = $countones(m);
    if (n == 0)  return 0;
    if (n == 1)  return 1;
    if (n == 16) return 3;
    return 2;
  endfunction

  // ---------------------------------------------------------------------------
  // 激励
  // ---------------------------------------------------------------------------
  function automatic logic [15:0] rand_wvec();
    case ($urandom_range(0, 3))
      0: rand_wvec = 16'h1 << $urandom_range(0, 15);                 // 单行
      1: rand_wvec = (16'h1 << $urandom_range(0, 15))
                   | (16'h1 << $urandom_range(0, 15));               // 两行
      2: rand_wvec = $urandom & $urandom;                            // 稀疏多行
      default: rand_wvec = 16'hFFFF;                                 // 全行（行边界）
    endcase
  endfunction

  function automatic logic [15:0] rand_bmask();
    case ($urandom_range(0, 4))
      0: rand_bmask = 16'h0;                                         // 全 0：谁也不写
      1: rand_bmask = 16'h1 << $urandom_range(0, 15);                // 单字节
      2: rand_bmask = 16'hFFFF;                                      // 整 vword
      3: rand_bmask = $urandom & $urandom;                           // 稀疏
      default: rand_bmask = $urandom;
    endcase
  endfunction

  task automatic drive();
    int mode;
    logic [15:0] shared_vec;
    logic [1:0]  shared_off;

    // ---- 复位控制 ----
    // 开头 RST_CYC 拍拉住；暖机之后偶发 2 拍脉冲（见文件头 F）。
    if (cyc < RST_CYC) begin
      rst = 1'b1;
    end else if (rst_hold > 0) begin
      rst = 1'b1; rst_hold--;
    end else if (cyc > WARM_CYC && $urandom_range(0, 1999) == 0) begin
      rst = 1'b1; rst_hold = 2; cov_rst_pulse++;
    end else begin
      rst = 1'b0;
    end

    if (cyc < RST_CYC) begin                     // 复位窗口：不发请求
      wvalid = 2'b00; wvec = '0; wmask = '0; wdata = '0; wvwoff = '0; wline = '0;
      fvalid = 1'b0;  fvec = '0;
      return;
    end
    if (cyc < WARM_CYC) begin                    // 暖机：整行写，一拍写满 1024 字节
      wvalid = 2'b11;
      wvec   = {16'hFFFF, 16'hFFFF};
      wmask  = {16'hFFFF, 16'hFFFF};
      wdata  = {{4{32'hA5A5_5A5A}}, {4{32'h1234_5678}}};
      wvwoff = '0;
      wline  = 2'b11;                            // 无视 mask/vword，整 64 字节都写
      fvalid = 1'b0; fvec = '0;
      return;
    end

    mode = $urandom_range(0, 7);
    cov_mode[mode]++;
    shared_vec = rand_wvec();
    shared_off = $urandom_range(0, 3);

    // 缺省：两口独立随机
    for (int p = 0; p < 2; p++) begin
      wvalid[p] = $urandom_range(0, 3) != 0;
      wvec  [p] = rand_wvec();
      wmask [p] = rand_bmask();
      wdata [p] = {$urandom, $urandom, $urandom, $urandom};
      wvwoff[p] = {$urandom, $urandom_range(0, 4095)};   // 高 42 位随机（应被忽略）
      wline [p] = ($urandom_range(0, 7) == 0);
    end
    fvalid = ($urandom_range(0, 3) == 0);
    fvec   = rand_wvec();

    case (mode)
      0: begin  // A 同拍两口写同一字节：同行、同 vword、掩码重叠、数据不同
        wvalid = 2'b11;
        wvec   = {shared_vec, shared_vec};
        wmask  = {16'hFFFF, 16'hFFFF};
        wvwoff = {{42'h0, shared_off}, {42'h0, shared_off}};
        wline  = 2'b00;
        wdata  = {{4{32'hDEAD_BEEF}}, {4{32'h0BAD_C0DE}}};
      end
      1: begin  // C 部分置位掩码：单点 + 稀疏
        wvalid = 2'b11;
        wmask  = {16'h1 << $urandom_range(0, 15), $urandom & $urandom & $urandom};
        wline  = 2'b00;
      end
      2: begin  // D 整行写
        wvalid[$urandom_range(0, 1)] = 1'b1;
        wline  = 2'b11;
      end
      3: begin  // B 写与清掩码同拍打到同一行
        wvalid = 2'b11;
        wvec   = {shared_vec, shared_vec};
        wline  = 2'b00;
        wmask  = {16'hFFFF, 16'hFFFF};
        fvalid = 1'b1;
        fvec   = shared_vec;
      end
      4: begin  // 只清掩码
        wvalid = 2'b00;
        fvalid = 1'b1;
        fvec   = rand_wvec();
      end
      5: begin  // D vword 边界：两口分别打 0 与 3
        wvalid = 2'b11;
        wline  = 2'b00;
        wvwoff = {44'h3, 44'h0};
        wmask  = {16'hFFFF, 16'hFFFF};
      end
      6: begin  // E 空闲：验不复位寄存器保持
        wvalid = 2'b00;
        fvalid = 1'b0;
      end
      default: ;  // 全随机，保持上面的缺省
    endcase

    // ---- 记录覆盖 ----
    if (wvalid == 2'b00 && !fvalid) cov_idle++;
    if (wvalid == 2'b11) cov_2port++;
    for (int p = 0; p < 2; p++) if (wvalid[p]) begin
      cov_vword[wvwoff[p][1:0]]++;
      cov_maskcls[mask_class(wmask[p])]++;
      if (wline[p]) cov_wline++;
      for (int l = 0; l < 16; l++) if (wvec[p][l]) cov_line[l]++;
    end
    // 两口同拍写同一字节：同一行 且 (任一口整行写 或 同 vword 且掩码重叠)
    if (wvalid == 2'b11 && |(wvec[0] & wvec[1])
        && (wline[0] || wline[1]
            || (wvwoff[0][1:0] == wvwoff[1][1:0] && |(wmask[0] & wmask[1]))))
      cov_byte_clash++;
    // 写与清掩码同拍打到同一行
    if (fvalid && |((wvec[0] & {16{wvalid[0]}} | wvec[1] & {16{wvalid[1]}}) & fvec))
      cov_wr_vs_clean++;
  endtask

  // ---------------------------------------------------------------------------
  // 比对
  // ---------------------------------------------------------------------------
  task automatic check();
    if (g_mask !== i_mask) begin
      errors++;
      if (errors <= 20)
        for (int k = 0; k < 1024; k++)
          if (g_mask[k] !== i_mask[k]) begin
            $display("[%0t cyc=%0d] maskOut[%0d][%0d][%0d] golden=%b impl=%b",
                     $time, cyc, k/64, (k%64)/16, k%16, g_mask[k], i_mask[k]);
            break;
          end
    end
    checks++;

    if (cyc > WARM_CYC) begin
      if (g_data !== i_data) begin
        errors++;
        if (errors <= 20)
          for (int k = 0; k < 1024; k++)
            if (g_data[k] !== i_data[k]) begin
              $display("[%0t cyc=%0d] dataOut[%0d][%0d][%0d] golden=%h impl=%h",
                       $time, cyc, k/64, (k%64)/16, k%16, g_data[k], i_data[k]);
              break;
            end
      end
      checks++;
    end

    // 观察掩码确实在动（置位 / 清零都发生过）
    if ((g_mask & ~prev_gmask) != 1024'b0) cov_mask_set++;
    if ((~g_mask & prev_gmask) != 1024'b0) cov_mask_clr++;
    prev_gmask = g_mask;
  endtask

  // ---------------------------------------------------------------------------
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int k = 0; k < 8;  k++) cov_mode[k] = 0;
    for (int k = 0; k < 4;  k++) begin cov_vword[k] = 0; cov_maskcls[k] = 0; end
    for (int k = 0; k < 16; k++) cov_line[k] = 0;
    cov_wline = 0; cov_2port = 0; cov_byte_clash = 0; cov_wr_vs_clean = 0;
    cov_idle = 0; cov_mask_set = 0; cov_mask_clr = 0; cov_rst_pulse = 0;
    prev_gmask = '0;

    drive();
    for (cyc = 1; cyc <= NCYCLES; cyc++) begin
      @(posedge clk);
      #1;
      check();
      drive();
    end
    report();
    $finish;
  end

  task automatic report();
    int unsigned min_mode = 32'hFFFF_FFFF, min_vw = 32'hFFFF_FFFF;
    int unsigned min_line = 32'hFFFF_FFFF, min_mc = 32'hFFFF_FFFF;
    for (int k = 0; k < 8;  k++) if (cov_mode[k]    < min_mode) min_mode = cov_mode[k];
    for (int k = 0; k < 4;  k++) if (cov_vword[k]   < min_vw)   min_vw   = cov_vword[k];
    for (int k = 0; k < 16; k++) if (cov_line[k]    < min_line) min_line = cov_line[k];
    for (int k = 0; k < 4;  k++) if (cov_maskcls[k] < min_mc)   min_mc   = cov_maskcls[k];
    $display("--- coverage ---");
    $display("stimulus modes 0..7        : 8/8,  min hits = %0d", min_mode);
    $display("vwordOffset[1:0] 0..3      : 4/4,  min hits = %0d", min_vw);
    $display("lines 0..15 written        : 16/16, min hits = %0d", min_line);
    $display("byte-mask classes 0/1/n/all: 4/4,  min hits = %0d", min_mc);
    $display("whole-line writes (wline)  : %0d", cov_wline);
    $display("both ports active          : %0d", cov_2port);
    $display("two ports -> SAME byte     : %0d   <- port1-wins priority", cov_byte_clash);
    $display("write vs maskFlush同行     : %0d   <- write-beats-clean priority",
             cov_wr_vs_clean);
    $display("idle cycles (hold)         : %0d", cov_idle);
    $display("cycles maskOut gained bits : %0d", cov_mask_set);
    $display("cycles maskOut lost bits   : %0d", cov_mask_clr);
    $display("mid-test reset pulses      : %0d   <- reset-domain discriminator",
             cov_rst_pulse);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && min_mode > 0 && min_vw > 0 && min_line > 0
        && min_mc > 0 && cov_wline > 100 && cov_byte_clash > 100
        && cov_wr_vs_clean > 100 && cov_idle > 100
        && cov_mask_set > 100 && cov_mask_clr > 100 && cov_rst_pulse > 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
  endtask

endmodule
