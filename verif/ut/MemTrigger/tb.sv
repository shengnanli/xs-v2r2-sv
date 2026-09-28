// =============================================================================
// MemTrigger UT —— golden MemTrigger 对重写 MemTrigger_xs 双例化，同激励逐拍比 3 根输出。
//
// 激励要点（均匀随机几乎打不中 64 位地址相等，所以按"构造命中"出激励）：
//   · vaddr 随机；每个触发器的 tdata2 以 1/2 概率取 vaddr 附近（±小偏移、同 16B 块、
//     高位 [63:50] 偶尔置 1 以打"块号比较零扩展"那一支），否则全随机；
//   · matchType 覆盖 0/1/2/3，chain/timing/action 随机（action 偏向 0/1），
//     select/debugMode/isPrf/tEnable/load 以低概率置成阻断值；
//   · isVectorUnitStride 1/3，mask 随机（含全 0）。
// 覆盖判据（读重写核内部信号）：每个触发器 标量命中/向量命中/canFire 各 ≥1，
//   三种 triggerAction(1/0/F) 各 ≥1，链上触发（chain[i-1]=1 且 canFire[i]）≥1，
//   返回 vaddr 来自每个触发器编号各 ≥1。不达标则本轮不作数。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  int  errors = 0;
  longint checks = 0;

  logic [3:0][1:0]  matchType;
  logic [3:0]       sel, timing, chain, load, tEnable;
  logic [3:0][3:0]  action;
  logic [3:0][63:0] tdata2;
  logic             debugMode, canBp, isVUS, isPrf;
  logic [49:0]      vaddr;
  logic [15:0]      mask;

  wire [3:0]  g_act, x_act;
  wire [49:0] g_va,  x_va;
  wire [15:0] g_mk,  x_mk;

`define MT_PORTS(ACT, VA, MK) \
    .tdataVec_io_fromCsrTrigger_tdataVec_0_matchType(matchType[0]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_0_select(sel[0]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_0_timing(timing[0]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_0_action(action[0]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_0_chain(chain[0]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_0_load(load[0]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_0_tdata2(tdata2[0]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_1_matchType(matchType[1]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_1_select(sel[1]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_1_timing(timing[1]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_1_action(action[1]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_1_chain(chain[1]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_1_load(load[1]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_1_tdata2(tdata2[1]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_2_matchType(matchType[2]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_2_select(sel[2]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_2_timing(timing[2]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_2_action(action[2]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_2_chain(chain[2]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_2_load(load[2]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_2_tdata2(tdata2[2]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_3_matchType(matchType[3]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_3_select(sel[3]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_3_timing(timing[3]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_3_action(action[3]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_3_chain(chain[3]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_3_load(load[3]), \
    .tdataVec_io_fromCsrTrigger_tdataVec_3_tdata2(tdata2[3]), \
    .tdataVec_io_fromCsrTrigger_tEnableVec_0(tEnable[0]), \
    .tdataVec_io_fromCsrTrigger_tEnableVec_1(tEnable[1]), \
    .tdataVec_io_fromCsrTrigger_tEnableVec_2(tEnable[2]), \
    .tdataVec_io_fromCsrTrigger_tEnableVec_3(tEnable[3]), \
    .tdataVec_io_fromCsrTrigger_debugMode(debugMode), \
    .tdataVec_io_fromCsrTrigger_triggerCanRaiseBpExp(canBp), \
    .tdataVec_io_fromLoadStore_vaddr(vaddr), \
    .tdataVec_io_fromLoadStore_isVectorUnitStride(isVUS), \
    .tdataVec_io_fromLoadStore_mask(mask), \
    .tdataVec_io_toLoadStore_triggerAction(ACT), \
    .tdataVec_io_toLoadStore_triggerVaddr(VA), \
    .tdataVec_io_toLoadStore_triggerMask(MK), \
    .tdataVec_io_isPrf(isPrf)

  MemTrigger    u_golden (`MT_PORTS(g_act, g_va, g_mk));
  MemTrigger_xs u_impl   (`MT_PORTS(x_act, x_va, x_mk));

  // ---- 覆盖计数 ----
  longint cov_scalar[4], cov_vector[4], cov_fire[4], cov_chainfire[4], cov_pick[4];
  longint cov_act_dm = 0, cov_act_bp = 0, cov_act_none = 0;

  function automatic logic [63:0] near(logic [49:0] va);
    logic [63:0] t;
    case ($urandom_range(0, 5))
      0: t = {14'h0, va};                                 // 恰好相等
      1: t = {14'h0, va} + $urandom_range(1, 40);         // 略大
      2: t = {14'h0, va} - $urandom_range(1, 40);         // 略小
      3: t = {14'h0, va[49:4], 4'($urandom)};             // 同 16B 块
      4: t = {14'($urandom), va[49:4], 4'($urandom)};     // 同块但高位非 0（向量比较不命中）
      default: t = {$urandom, $urandom};
    endcase
    return t;
  endfunction

  task automatic drive();
    vaddr     = {$urandom, $urandom};
    if ($urandom_range(0, 3) == 0) vaddr[49:20] = '0;
    isVUS     = ($urandom_range(0, 2) == 0);
    mask      = ($urandom_range(0, 7) == 0) ? 16'h0 : 16'($urandom);
    debugMode = ($urandom_range(0, 15) == 0);
    isPrf     = ($urandom_range(0, 7) == 0);
    canBp     = ($urandom_range(0, 5) != 0);
    for (int i = 0; i < 4; i++) begin
      matchType[i] = $urandom;
      sel[i]       = ($urandom_range(0, 9) == 0);
      timing[i]    = ($urandom_range(0, 3) == 0);
      chain[i]     = ($urandom_range(0, 3) == 0);
      load[i]      = ($urandom_range(0, 9) != 0);
      tEnable[i]   = ($urandom_range(0, 9) != 0);
      action[i]    = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'($urandom_range(0, 1));
      tdata2[i]    = $urandom_range(0, 1) ? near(vaddr) : {$urandom, $urandom};
    end
  endtask

  task automatic compare();
    checks++;
    if (g_act !== x_act || g_va !== x_va || g_mk !== x_mk) begin
      errors++;
      if (errors < 20)
        $display("MISMATCH #%0d vaddr=%h vus=%0d act g=%h x=%h va g=%h x=%h mask g=%h x=%h",
                 checks, vaddr, isVUS, g_act, x_act, g_va, x_va, g_mk, x_mk);
    end
  endtask

  task automatic collect_cov();
    for (int i = 0; i < 4; i++) begin
      if (u_impl.u_core.scalarHit[i] & ~isVUS) cov_scalar[i]++;
      if (u_impl.u_core.vectorHit[i] &  isVUS) cov_vector[i]++;
      if (u_impl.u_core.canFire[i]) cov_fire[i]++;
      if (i > 0 && chain[i-1] && u_impl.u_core.canFire[i]) cov_chainfire[i]++;
    end
    for (int i = 0; i < 4; i++)
      if (u_impl.u_core.fireVec[i]) begin cov_pick[i]++; break; end
    case (x_act)
      4'h1: cov_act_dm++;
      4'h0: cov_act_bp++;
      4'hF: cov_act_none++;
      default: ;
    endcase
  endtask

  initial begin
    int bad = 0;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int i = 0; i < 4; i++) begin
      cov_scalar[i] = 0; cov_vector[i] = 0; cov_fire[i] = 0; cov_chainfire[i] = 0; cov_pick[i] = 0;
    end
    for (int c = 0; c < NCYCLES; c++) begin
      drive();
      #1;
      compare();
      collect_cov();
      #4;
    end
    for (int i = 0; i < 4; i++) begin
      $display("  trig%0d scalarHit=%0d vectorHit=%0d canFire=%0d chainFire=%0d picked=%0d",
               i, cov_scalar[i], cov_vector[i], cov_fire[i], cov_chainfire[i], cov_pick[i]);
      if (cov_scalar[i] == 0 || cov_vector[i] == 0 || cov_fire[i] == 0 || cov_pick[i] == 0) bad++;
      if (i > 0 && cov_chainfire[i] == 0) bad++;
    end
    $display("  action DebugMode=%0d Breakpoint=%0d None=%0d", cov_act_dm, cov_act_bp, cov_act_none);
    if (cov_act_dm == 0 || cov_act_bp == 0 || cov_act_none == 0) bad++;
    $display("=== COVERAGE (MemTrigger) === checks=%0d uncovered=%0d", checks, bad);
    if (bad != 0) begin $display("COVERAGE INSUFFICIENT"); errors++; end
    $display("MemTrigger UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
