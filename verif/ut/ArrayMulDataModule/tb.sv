// =============================================================================
// tb —— ArrayMulDataModule 家族 UT：golden 与重写件双例化逐拍比对。
//
// 覆盖 5 个 golden 顶层：
//   ArrayMulDataModule（Booth + Wallace 乘法阵列，两级流水）
//   C22 / C32 / C53（压缩树算子）+ CSA3_2（C53 的子实例，与 C32 同体不同名）
//
// ★压缩器是纯组合的进位算子，激励必须覆盖进位链的边界★：前 64 拍对
//   C22(4)/C32(8)/CSA3_2(8)/C53(32) 做**穷举**扫描（它们的输入空间就这么大），
//   之后转随机并掺入全 0 / 全 1 / 交替 / 单点进位四种定向模式。
//
// ★乘法阵列的寄存器一个都不复位★（golden 无 reset 端口）。initreg 会给两侧
//   寄存器**各自不同**的上电值，所以先暖机：把两级使能顶住若干拍，等 2562 个
//   寄存器全部被写过一遍，两侧才进入同一状态；之后才开始比对。暖机长度取 8 拍
//   （只需 2 拍即可定型，留足余量）。暖机不会掩盖变异——见 README 的 mutant 记录。
//
// 乘数激励：随机 + 定向语料（0 / ±1 / 2^k / 全 1 / 0x5555… / 0xAAAA… /
//   仅符号位 / 合法的三种 MulUnit 操作数形态），并随机拉低两级使能以检验"保持"。
// =============================================================================
`timescale 1ns/1ps
module tb;

  // ---- 运行参数 ----
  int unsigned NCYCLES = 200000;
  localparam int WARMUP = 8;

  bit clk = 0;
  always #5 clk = ~clk;

  longint errors = 0, checks = 0;
  longint cyc = 0;

  // ---------------------------------------------------------------------------
  // 1) 压缩器：golden vs 重写，纯组合
  // ---------------------------------------------------------------------------
  logic [4:0] cin;            // 5 根输入，按需取低位
  logic g_c22_0, g_c22_1, i_c22_0, i_c22_1;
  logic g_c32_0, g_c32_1, i_c32_0, i_c32_1;
  logic g_csa_0, g_csa_1, i_csa_0, i_csa_1;
  logic g_c53_0, g_c53_1, g_c53_2, i_c53_0, i_c53_1, i_c53_2;

  C22    u_g_c22 (.io_in_0(cin[0]), .io_in_1(cin[1]), .io_out_0(g_c22_0), .io_out_1(g_c22_1));
  C22_xs u_i_c22 (.io_in_0(cin[0]), .io_in_1(cin[1]), .io_out_0(i_c22_0), .io_out_1(i_c22_1));

  C32    u_g_c32 (.io_in_0(cin[0]), .io_in_1(cin[1]), .io_in_2(cin[2]),
                  .io_out_0(g_c32_0), .io_out_1(g_c32_1));
  C32_xs u_i_c32 (.io_in_0(cin[0]), .io_in_1(cin[1]), .io_in_2(cin[2]),
                  .io_out_0(i_c32_0), .io_out_1(i_c32_1));

  CSA3_2    u_g_csa (.io_in_0(cin[0]), .io_in_1(cin[1]), .io_in_2(cin[2]),
                     .io_out_0(g_csa_0), .io_out_1(g_csa_1));
  CSA3_2_xs u_i_csa (.io_in_0(cin[0]), .io_in_1(cin[1]), .io_in_2(cin[2]),
                     .io_out_0(i_csa_0), .io_out_1(i_csa_1));

  C53    u_g_c53 (.io_in_0(cin[0]), .io_in_1(cin[1]), .io_in_2(cin[2]),
                  .io_in_3(cin[3]), .io_in_4(cin[4]),
                  .io_out_0(g_c53_0), .io_out_1(g_c53_1), .io_out_2(g_c53_2));
  C53_xs u_i_c53 (.io_in_0(cin[0]), .io_in_1(cin[1]), .io_in_2(cin[2]),
                  .io_in_3(cin[3]), .io_in_4(cin[4]),
                  .io_out_0(i_c53_0), .io_out_1(i_c53_1), .io_out_2(i_c53_2));

  // ---------------------------------------------------------------------------
  // 2) 乘法阵列：golden vs 重写，两级流水
  // ---------------------------------------------------------------------------
  logic [64:0]  a, b;
  logic         en0, en1;
  logic [129:0] g_res, i_res;

  ArrayMulDataModule    u_g (.clock(clk), .io_a(a), .io_b(b),
                             .io_regEnables_0(en0), .io_regEnables_1(en1), .io_result(g_res));
  ArrayMulDataModule_xs u_i (.clock(clk), .io_a(a), .io_b(b),
                             .io_regEnables_0(en0), .io_regEnables_1(en1), .io_result(i_res));

  // ---------------------------------------------------------------------------
  // 3) 覆盖证据（不是 covergroup，而是逐项计数，收尾时打印并判最低水位）
  // ---------------------------------------------------------------------------
  int unsigned cov_csa_pat [32];      // 压缩器 5 位输入的 32 种组合
  int unsigned cov_window  [8];       // Booth 3 位窗口的 8 种取值（跨所有 33 行累计）
  int unsigned cov_en      [4];       // {en1,en0} 四种组合
  int unsigned cov_a_class [8];       // 乘数 a 的定向语料类别
  int unsigned cov_carry_out;         // 130 位加法产生过"最高列进位被丢弃"的拍数
  int unsigned cov_res_nz;            // 乘积非 0 的拍数

  function automatic void note_window(input logic [64:0] av);
    logic [2:0] w;
    for (int k = 0; k < 33; k++) begin
      if (k == 0)            w = {av[1:0], 1'b0};
      else if (2*k == 64)    w = {av[64], av[64:63]};
      else                   w = av[2*k+1 -: 3];
      cov_window[w]++;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // 4) 激励
  // ---------------------------------------------------------------------------
  function automatic logic [64:0] gen_operand(output int cls);
    logic [63:0] lo;
    cls = $urandom_range(0, 7);
    case (cls)
      0: gen_operand = '0;                                   // 全 0
      1: gen_operand = '1;                                   // 全 1（= -1）
      2: gen_operand = 65'h1 << $urandom_range(0, 64);       // 单点（2 的幂）
      3: gen_operand = {1'b0, 64'h5555_5555_5555_5555};      // 交替 01
      4: gen_operand = {1'b1, 64'hAAAA_AAAA_AAAA_AAAA};      // 交替 10
      5: begin lo = {$urandom, $urandom};                    // 合法带符号形态 a[64]=a[63]
           gen_operand = {lo[63], lo}; end
      6: begin lo = {$urandom, $urandom};                    // 合法无符号形态 a[64]=0
           gen_operand = {1'b0, lo}; end
      default: gen_operand = {$urandom, $urandom, $urandom}; // 全随机（含非法形态）
    endcase
  endfunction

  task automatic drive();
    int ca, cb;
    // 压缩器：前 64 拍穷举 5 位输入空间（每个组合至少两拍），之后随机 + 定向
    if (cyc < 64) cin = cyc[5:1];
    else begin
      case ($urandom_range(0, 4))
        0: cin = 5'b00000;                       // 全 0：进位链静默
        1: cin = 5'b11111;                       // 全 1：进位链满载
        2: cin = 5'b10101;                       // 交替
        3: cin = 5'b1 << $urandom_range(0, 4);   // 单点进位
        default: cin = $urandom;
      endcase
    end
    cov_csa_pat[cin]++;

    a = gen_operand(ca);
    b = gen_operand(cb);
    cov_a_class[ca]++;
    note_window(a);

    // 暖机期两级使能顶住，之后随机（含长时间保持，检验"不复位寄存器保持值"）
    if (cyc < WARMUP) begin en0 = 1'b1; en1 = 1'b1; end
    else begin
      en0 = ($urandom_range(0, 9) != 0);
      en1 = ($urandom_range(0, 9) != 0);
    end
    cov_en[{en1, en0}]++;
  endtask

  // ---------------------------------------------------------------------------
  // 5) 比对
  // ---------------------------------------------------------------------------
  `define CK(g,i,nm) \
    begin checks++; \
      if ((g) !== (i)) begin errors++; \
        if (errors <= 40) $display("[%0t cyc=%0d] MISMATCH %s golden=%h impl=%h", \
                                   $time, cyc, nm, (g), (i)); end end

  task automatic check_comb();
    `CK(g_c22_0, i_c22_0, "C22.out0")
    `CK(g_c22_1, i_c22_1, "C22.out1")
    `CK(g_c32_0, i_c32_0, "C32.out0")
    `CK(g_c32_1, i_c32_1, "C32.out1")
    `CK(g_csa_0, i_csa_0, "CSA3_2.out0")
    `CK(g_csa_1, i_csa_1, "CSA3_2.out1")
    `CK(g_c53_0, i_c53_0, "C53.out0")
    `CK(g_c53_1, i_c53_1, "C53.out1")
    `CK(g_c53_2, i_c53_2, "C53.out2")
  endtask

  task automatic check_mul();
    `CK(g_res, i_res, "ArrayMulDataModule.io_result")
    if (g_res !== 130'b0) cov_res_nz++;
  endtask

  // ---------------------------------------------------------------------------
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int k = 0; k < 32; k++) cov_csa_pat[k] = 0;
    for (int k = 0; k < 8;  k++) begin cov_window[k] = 0; cov_a_class[k] = 0; end
    for (int k = 0; k < 4;  k++) cov_en[k] = 0;
    cov_carry_out = 0; cov_res_nz = 0;

    drive();
    for (cyc = 1; cyc <= NCYCLES; cyc++) begin
      @(posedge clk);
      #1;
      check_comb();                      // 组合件每拍都比（与暖机无关）
      if (cyc > WARMUP) check_mul();     // 阵列等两级寄存器都被写过一遍再比
      drive();
    end

    report();
    $finish;
  end

  task automatic report();
    int unsigned min_pat = 32'hFFFF_FFFF, min_win = 32'hFFFF_FFFF, min_en = 32'hFFFF_FFFF;
    int unsigned min_cls = 32'hFFFF_FFFF;
    for (int k = 0; k < 32; k++) if (cov_csa_pat[k] < min_pat) min_pat = cov_csa_pat[k];
    for (int k = 0; k < 8;  k++) if (cov_window[k]  < min_win) min_win = cov_window[k];
    for (int k = 0; k < 8;  k++) if (cov_a_class[k] < min_cls) min_cls = cov_a_class[k];
    for (int k = 0; k < 4;  k++) if (cov_en[k]      < min_en)  min_en  = cov_en[k];
    $display("--- coverage ---");
    $display("compressor 5-bit input patterns : 32/32 seen, min hits = %0d", min_pat);
    $display("booth windows 0..7              : 8/8 seen,  min hits = %0d", min_win);
    $display("operand classes 0..7            : 8/8 seen,  min hits = %0d", min_cls);
    $display("regEnables {en1,en0} combos     : 4/4 seen,  min hits = %0d", min_en);
    $display("cycles with non-zero product    : %0d", cov_res_nz);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 &&
        min_pat > 0 && min_win > 0 && min_cls > 0 && min_en > 0 && cov_res_nz > 1000)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
  endtask

endmodule
