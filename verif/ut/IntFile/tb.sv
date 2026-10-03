// =============================================================================
// tb —— IntFile UT：golden IntFile 与重写件 IntFile_xs 双例化，同激励逐拍比全部 5 个输出。
//
// 激励（每拍独立随机）：
//   seteipnum  valid 30%，id 全随机（8 位，覆盖 4 个字各 64 位）；
//   addr       valid 50%；地址 70% 取 10 个合法间接 CSR 号（0x70/0x72/0x80..0x86/0xC0..0xC6），
//              15% 取 [0x80,0xFF] 内奇数（illegal），15% 任意 12 位；
//   wdata      valid 50%，op 均匀 4 种（含 0=非法）；data 四种形状：全随机 / 稀疏 / 全 1 / 低位小值
//              （阈值 eithreshold 要有小值才让 topei 过滤有两种结果）；
//   claim 20%；illegal_priv 15%。
// 复位：前 5 拍 reset=1；全部寄存器异步复位，复位撤销后即逐拍比对。
// 覆盖（写进 PASS 判据，每桶 >= NCYCLES/1000）：10 个合法地址 × 3 个合法 op 的写各桶；claim 命中
//   （claim 且 topei!=0）；topei 非 0 / 被阈值滤成 0（有 ready 位但 topei=0）；pending=1；illegal=1；
//   rdata_valid 由 illegal_priv 单独拉起；每个输出都见过 0/1。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;
  int cyc;
  bit clock = 0;
  bit reset = 1;
  always #5 clock = ~clock;

  logic        seteipnum_valid;
  logic [7:0]  seteipnum_bits;
  logic        addr_valid;
  logic [11:0] addr_bits;
  logic        wdata_valid;
  logic [1:0]  wdata_op;
  logic [63:0] wdata_data;
  logic        claim;
  logic        illegal_priv;
  logic        g_rdata_valid, i_rdata_valid, g_illegal, i_illegal, g_pending, i_pending;
  logic [63:0] g_rdata, i_rdata;
  logic [7:0]  g_topei, i_topei;

  IntFile u_g (
    .clock(clock), .reset(reset),
    .fromCSR_seteipnum_valid(seteipnum_valid), .fromCSR_seteipnum_bits(seteipnum_bits),
    .fromCSR_addr_valid(addr_valid), .fromCSR_addr_bits(addr_bits),
    .fromCSR_wdata_valid(wdata_valid), .fromCSR_wdata_bits_op(wdata_op), .fromCSR_wdata_bits_data(wdata_data),
    .fromCSR_claim(claim), .illegal_io_illegal_priv(illegal_priv),
    .toCSR_rdata_valid(g_rdata_valid), .toCSR_rdata_bits(g_rdata), .toCSR_illegal(g_illegal),
    .toCSR_pending(g_pending), .toCSR_topei(g_topei));
  IntFile_xs u_i (
    .clock(clock), .reset(reset),
    .fromCSR_seteipnum_valid(seteipnum_valid), .fromCSR_seteipnum_bits(seteipnum_bits),
    .fromCSR_addr_valid(addr_valid), .fromCSR_addr_bits(addr_bits),
    .fromCSR_wdata_valid(wdata_valid), .fromCSR_wdata_bits_op(wdata_op), .fromCSR_wdata_bits_data(wdata_data),
    .fromCSR_claim(claim), .illegal_io_illegal_priv(illegal_priv),
    .toCSR_rdata_valid(i_rdata_valid), .toCSR_rdata_bits(i_rdata), .toCSR_illegal(i_illegal),
    .toCSR_pending(i_pending), .toCSR_topei(i_topei));

  localparam int NADDR = 10;
  logic [11:0] ADDRS [NADDR] = '{12'h070, 12'h072, 12'h080, 12'h082, 12'h084, 12'h086,
                                 12'h0C0, 12'h0C2, 12'h0C4, 12'h0C6};
  int cov_wr [NADDR][3];
  int cov_claim_hit, cov_topei_nz, cov_topei_filtered, cov_pending, cov_illegal, cov_rv_priv;
  bit seen0 [5], seen1 [5];

  `define CMP(k, g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      if (|(g)) seen1[k] = 1; if (!(&(g))) seen0[k] = 1; end

  function automatic logic [63:0] shape64();
    logic [63:0] x;
    x = {$urandom, $urandom};
    case ($urandom_range(0, 3))
      0: return x;
      1: return x & {$urandom, $urandom} & {$urandom, $urandom};
      2: return '1;
      default: return 64'($urandom_range(0, 300));
    endcase
  endfunction

  task automatic drive();
    seteipnum_valid = ($urandom_range(0, 9) < 3);
    seteipnum_bits  = $urandom;
    addr_valid      = $urandom_range(0, 1);
    case ($urandom_range(0, 19))
      0, 1, 2:  addr_bits = 12'h080 + 12'($urandom_range(0, 127)) * 2 + 12'd1;
      3, 4, 5:  addr_bits = $urandom;
      default:  addr_bits = ADDRS[$urandom_range(0, NADDR - 1)];
    endcase
    wdata_valid = $urandom_range(0, 1);
    wdata_op    = $urandom;
    wdata_data  = shape64();
    claim       = ($urandom_range(0, 4) == 0);
    illegal_priv = ($urandom_range(0, 19) < 3);
  endtask

  initial begin
    int bad;
    bit any_ready;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    drive();
    repeat (5) @(posedge clock);
    #1 reset = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      drive();
      #1;
      `CMP(0, g_rdata_valid, i_rdata_valid, "rdata_valid")
      `CMP(1, g_rdata, i_rdata, "rdata")
      `CMP(2, g_illegal, i_illegal, "illegal")
      `CMP(3, g_pending, i_pending, "pending")
      `CMP(4, g_topei, i_topei, "topei")
      if (wdata_valid && !illegal_priv && wdata_op != 0)
        for (int a = 0; a < NADDR; a++) if (addr_bits == ADDRS[a]) cov_wr[a][wdata_op - 1]++;
      if (claim && g_topei != 0) cov_claim_hit++;
      if (g_topei != 0) cov_topei_nz++;
      any_ready = |((u_g.eips_0 & u_g.eies_0) | (u_g.eips_1 & u_g.eies_1) |
                    (u_g.eips_2 & u_g.eies_2) | (u_g.eips_3 & u_g.eies_3));
      if (any_ready && g_topei == 0) cov_topei_filtered++;
      if (g_pending) cov_pending++;
      if (g_illegal) cov_illegal++;
      if (!addr_valid && g_rdata_valid) cov_rv_priv++;
    end
    bad = 0;
    foreach (cov_wr[a, o]) begin
      $display("cov write addr=%h op=%0d : %0d", ADDRS[a], o + 1, cov_wr[a][o]);
      if (cov_wr[a][o] < NCYCLES / 1000) bad++;
    end
    $display("cov claim_hit=%0d topei_nz=%0d topei_filtered=%0d pending=%0d illegal=%0d rdata_valid_by_priv=%0d",
             cov_claim_hit, cov_topei_nz, cov_topei_filtered, cov_pending, cov_illegal, cov_rv_priv);
    if (cov_claim_hit < NCYCLES / 1000 || cov_topei_nz < NCYCLES / 1000 || cov_topei_filtered < NCYCLES / 1000 ||
        cov_pending < NCYCLES / 1000 || cov_illegal < NCYCLES / 1000 || cov_rv_priv < NCYCLES / 1000) bad++;
    for (int o = 0; o < 5; o++) if (!seen0[o] || !seen1[o]) begin bad++; $display("output %0d stuck", o); end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
