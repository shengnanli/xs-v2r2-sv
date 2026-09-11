// =============================================================================
// tb —— CompressUnit UT:golden CompressUnit (u_g) vs 可读核 CompressUnit_xs (u_i)。
// 纯组合:每拍随机驱动 6 条 lane 的属性,组合稳定后逐输出比对全部 24 个输出
// (needRobFlags×6 / instrSizes×6 / masks×6 / canCompressVec×6)。
// 激励:重点制造各种 canCompress 游程(连续/间断/全 1/全 0/单点),并随机
//   valid/exceptionVec/trigger/lastUop/commitType 以覆盖各 lane 的"可压缩"判定。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  localparam int W = 6, EXC = 24;

  // 输入(打平成数组便于驱动)
  logic        v   [W];
  logic [EXC-1:0] exc [W];
  logic [3:0]  trg [W];
  logic        crc [W];
  logic        lu  [W];
  logic [2:0]  ct  [W];

  // 输出
  logic g_nrf [W], i_nrf [W];
  logic [2:0] g_sz [W], i_sz [W];
  logic [5:0] g_mk [W], i_mk [W];
  logic g_ccv [W], i_ccv [W];

  // 数组信号 <-> 两个 DUT(golden u_g / 可读核 u_i)的 198 扁平端口,经机械生成
  // 的 cu_bridge 连接(见 scripts/gen_compressunit.py --bridge)。
  cu_bridge #(.W(W),.EXC(EXC)) u_b (
    .v(v), .exc(exc), .trg(trg), .crc(crc), .lu(lu), .ct(ct),
    .g_nrf(g_nrf), .i_nrf(i_nrf), .g_sz(g_sz), .i_sz(i_sz),
    .g_mk(g_mk), .i_mk(i_mk), .g_ccv(g_ccv), .i_ccv(i_ccv)
  );

  initial begin
    drive();
    repeat (NCYCLES) begin
      @(posedge clk);
      #1 check();
      drive();
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end

  // ---- 激励 ----
  task automatic drive();
    int mode = $urandom_range(0, 4);
    logic [W-1:0] cc_pat;
    // 先决定一个"理想 canCompress 模式",再尽量用合法属性实现它
    case (mode)
      0: cc_pat = $urandom;                 // 全随机
      1: cc_pat = 6'b111111;                // 全可压
      2: cc_pat = 6'b000000;                // 全不可压
      3: cc_pat = (6'b1 << $urandom_range(0,5)); // 单点
      default: cc_pat = $urandom & $urandom; // 稀疏
    endcase
    for (int k = 0; k < W; k++) begin
      // 多数 lane 按 cc_pat 安排"可压缩",但仍随机注入异常/非末uop破坏之
      bit want = cc_pat[k];
      v[k]   = want ? 1'b1 : $urandom;
      crc[k] = want ? 1'b1 : $urandom;
      lu[k]  = want ? 1'b1 : $urandom;
      // exceptionVec:want 时清零;否则小概率置位
      exc[k] = (want || ($urandom_range(0,3) != 0)) ? '0 : (24'b1 << $urandom_range(0,23));
      // trigger:want 时非 DebugMode(用 15=None);否则随机(可能命中 DebugMode=1)
      trg[k] = want ? 4'd15 : $urandom;
      // commitType:want 时非 fusion(bit2=0);否则随机
      ct[k]  = want ? ($urandom & 3'b011) : $urandom;
    end
  endtask

  `define CK(g,i,nm,k) \
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \
      if (errors<=80) $display("[%0t] %s[%0d] g=%h i=%h", $time, nm, k, g, i); end \
    checks++;

  task automatic check();
    for (int k = 0; k < W; k++) begin
      `CK(g_nrf[k], i_nrf[k], "needRobFlags",   k)
      `CK(g_sz[k],  i_sz[k],  "instrSizes",     k)
      `CK(g_mk[k],  i_mk[k],  "masks",          k)
      `CK(g_ccv[k], i_ccv[k], "canCompressVec", k)
    end
  endtask
endmodule
