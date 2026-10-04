// tb.sv —— ClockGate standalone UT：golden ClockGate vs 重写 ClockGate_xs 双例化
//
// CK 是被测的时钟输入，由 tb 按"相位"当数据推，而不是自由翻转的 tb 时钟。
// 每个周期分 4 段，所有 E/TE 变化都与 CK 沿错开至少 1ns，避免与锁存采样竞争：
//   1. 低相（CK=0）：E/TE 随机改若干次，每次 #1 后比 Q（应为 0）与锁存值（应跟随 TE|E）
//   2. 上升沿：CK=1，#1 后比 Q（应等于低相最后的 TE|E）
//   3. 高相：E/TE 随机翻若干次，每次 #1 后比 Q —— 必须保持，不许穿透
//   4. 下降沿：CK=0，#1 后比 Q（应为 0）
// 先跑 4 个定向场景（规范要求的四项），再随机跑 NCYCLES 拍。
// 判据三重：golden 与重写逐点 4 态全等 + 两者都等于 tb 参考模型 + 锁存器内部值全等。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint cyc = 0, checks = 0, errors = 0;

  logic TE, E, CK;
  wire  qGolden, qImpl;
  logic modelLatch;        // tb 参考模型的锁存值
  bit   modelValid = 0;    // 第一个低相之前锁存值未知，参考模型不比

  ClockGate    u_g (.TE(TE), .E(E), .CK(CK), .Q(qGolden));
  ClockGate_xs u_i (.TE(TE), .E(E), .CK(CK), .Q(qImpl));

  // 覆盖计数（四个规范场景 + 随机下各种组合）
  longint covLowUpdate = 0;     // 低相内锁存值发生变化
  longint covHoldHigh  = 0;     // 高相内 E/TE 变化而 Q 保持
  longint covBlockOn   = 0;     // 高相内 TE|E 由 0 变 1，Q 仍为 0（不穿透开门）
  longint covBlockOff  = 0;     // 高相内 TE|E 由 1 变 0，Q 仍为 1（不穿透关门）
  longint covTeForce   = 0;     // E=0 而 TE=1 开门，Q 出脉冲
  longint covPulse     = 0;     // Q 出高脉冲
  longint covGated     = 0;     // CK 高而 Q 被门住

  task automatic check(input string where);
    logic exp;
    checks++;
    if (qGolden !== qImpl) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d %s] MISMATCH Q g=%b i=%b", cyc, where, qGolden, qImpl);
    end
    if (u_g.EN !== u_i.enableLatched) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d %s] MISMATCH latch g=%b i=%b", cyc, where, u_g.EN, u_i.enableLatched);
    end
    if (modelValid) begin
      exp = CK & modelLatch;
      if (qGolden !== exp) begin
        errors++;
        if (errors <= 40) $display("[cyc %0d %s] MODEL Q exp=%b g=%b (TE=%b E=%b CK=%b)", cyc, where, exp, qGolden, TE, E, CK);
      end
    end
  endtask

  // 低相：可改 n 次 E/TE；锁存器透明，参考模型跟随
  task automatic lowPhase(input int n, input bit randomize, input logic te0, input logic e0);
    logic latchBefore;
    latchBefore = modelLatch;
    for (int k = 0; k < n; k++) begin
      if (randomize) begin TE = ($urandom % 4) == 0; E = $urandom % 2; end
      else begin TE = te0; E = e0; end
      #1;
      modelLatch = TE | E; modelValid = 1;
      check("low");
    end
    if (modelValid && latchBefore !== modelLatch) covLowUpdate++;
  endtask

  // 高相：E/TE 翻 n 次，Q 必须保持
  task automatic highPhase(input int n, input bit randomize, input logic te0, input logic e0);
    logic qHold, enBefore;
    qHold = qGolden;
    for (int k = 0; k < n; k++) begin
      enBefore = TE | E;
      if (randomize) begin TE = ($urandom % 4) == 0; E = $urandom % 2; end
      else begin TE = te0; E = e0; end
      #1;
      check("high");
      if (qGolden !== qHold) begin
        errors++;
        if (errors <= 40) $display("[cyc %0d] PENETRATE Q changed in high phase %b->%b", cyc, qHold, qGolden);
      end
      if (enBefore !== (TE | E)) begin
        covHoldHigh++;
        if (!enBefore && (TE | E) && qGolden === 1'b0) covBlockOn++;
        if (enBefore && !(TE | E) && qGolden === 1'b1) covBlockOff++;
      end
    end
  endtask

  task automatic rise();
    CK = 1'b1; #1; check("rise");
    if (qGolden === 1'b1) begin covPulse++; if (!E && TE) covTeForce++; end
    else covGated++;
  endtask

  // 下降沿：锁存器重新透明，立即跟随当前 TE|E
  task automatic fall();
    CK = 1'b0; modelLatch = TE | E; modelValid = 1;
    #1; check("fall");
  endtask

  // 一个完整的定向周期：低相设 (te,e)，高相翻成 (teH,eH)
  task automatic directed(input string name, input logic te, input logic e,
                          input logic teH, input logic eH, input logic expQ);
    lowPhase(1, 0, te, e);
    rise();
    if (qGolden !== expQ) begin
      errors++;
      $display("DIRECTED %s: Q=%b exp=%b", name, qGolden, expQ);
    end
    highPhase(1, 0, teH, eH);
    if (qGolden !== expQ) begin
      errors++;
      $display("DIRECTED %s: after high-phase flip Q=%b exp=%b", name, qGolden, expQ);
    end
    fall();
    #1;
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    // 起始在高相：锁存器尚未见过低相，值 = 上电初值。本模块无复位（与库 ICG 一致），
    // 上电初值不是功能的一部分，这里只打印不计错：+vcs+initreg+random / +<seed>017 两档
    // 给 golden 与重写两个实例**各摇各的**初值，seed 42 实测 g=1 i=0 —— 那是双例化的
    // 初值伪影，不是 RTL 差异（见 CONVENTIONS initreg 一节）。第一个低相之后两侧必须全等。
    CK = 1'b1; TE = 1'b0; E = 1'b0;
    #2;
    $display("INFO power-up (before first low phase): Q g=%b i=%b latch g=%b i=%b",
             qGolden, qImpl, u_g.EN, u_i.enableLatched);
    fall();

    // ---- 定向场景（codex 0208 实现约束第 5 条）----
    // 1. 低相更新：E=1 → 上升沿后 Q 出脉冲
    directed("low-update-on",  1'b0, 1'b1, 1'b0, 1'b1, 1'b1);
    directed("low-update-off", 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    // 2+3. 拉高后保持、高相 E/TE 翻转不穿透（开门方向与关门方向各一次）
    directed("hold-block-on",  1'b0, 1'b0, 1'b1, 1'b1, 1'b0);
    directed("hold-block-off", 1'b0, 1'b1, 1'b0, 1'b0, 1'b1);
    // 4. TE 强制开门：E=0、TE=1 → Q 出脉冲
    directed("te-force",       1'b1, 1'b0, 1'b0, 1'b0, 1'b1);
    // 低相内多次改：只有最后的值算数
    TE = 0; E = 1; #1; TE = 0; E = 0; #1; modelLatch = 0; check("low-multi");
    rise();
    if (qGolden !== 1'b0) begin errors++; $display("DIRECTED low-multi: Q=%b exp=0", qGolden); end
    fall();

    // ---- 随机 ----
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      lowPhase(1 + $urandom % 3, 1, 0, 0);
      rise();
      highPhase($urandom % 4, 1, 0, 0);
      fall();
    end

    $display("cover: lowUpdate=%0d holdHigh=%0d blockOn=%0d blockOff=%0d teForce=%0d pulse=%0d gated=%0d",
             covLowUpdate, covHoldHigh, covBlockOn, covBlockOff, covTeForce, covPulse, covGated);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (covLowUpdate == 0 || covHoldHigh == 0 || covBlockOn == 0 || covBlockOff == 0 ||
        covTeForce == 0 || covPulse == 0 || covGated == 0) begin
      $display("TEST FAILED (coverage)"); $fatal(1);
    end
    $display("TEST PASSED");
    $finish;
  end
endmodule
