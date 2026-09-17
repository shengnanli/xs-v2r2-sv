// =============================================================================
// verif/ut/StoreExceptionBuffer/tb.sv —— golden 双例化逐拍比对
// -----------------------------------------------------------------------------
// ★ 这个模块用大随机数打等于没打 ★:选择树比的是 robIdx(9 位)和 uopIdx(7 位),
// 均匀随机时"平局"几乎不发生,而平局恰恰是本模块最容易写错的地方(平局取下标小
// 的那片;保持值排在最后,所以与新候选平局时新候选赢)。
// 这里把 robIdx 压到 {flag 2 种 × value 0..7} = 16 个、uopIdx 压到 0..3,
// 让平局成为**常态**。
//
// 覆盖的边界:
//   E1 ★s2 口 6 与保持值 robIdx+uopIdx 完全平局 → 口 6 赢★(树内最后一对)
//   E2 s2 各口之间平局 → 下标小者赢
//   E3 redirect 分别冲掉:S1 输入 / S2 寄存值 / 保持值 —— 三个点各自独立
//   E4 flushItself(level=1)对"就是触发那条"的精确冲刷
//   E5 ★口 6 的常数字段:vaNeedExt=1、gpaddr=0、isHyper=0、isForVSnonLeafPTE=0★
//      必须让口 6 真的赢下选择树,并在输出端看到这四个常数
//   E6 ★口 4/5 没有 isHyper → 它们赢时输出 isHyper 必须是 0★
//   E7 异常向量全 0 → 即使 valid 也不是候选
//   E8 ★中途复位脉冲★ —— 只有 req_valid 复位,其余 65 个寄存器**不复位**
//
// 起手先做"全端口预热":7 个口一起打有效,把 65 个不复位寄存器写满再开比对。
//
// ---------------------------------------------------------------------------
// ★ 判别力证据:注入真 bug 必须被报出来 ★
// ---------------------------------------------------------------------------
// 4 个变异体各只改 rtl/memblock/StoreExceptionBuffer.sv 一处。★不进库★,
// 配方与实测数字(seed=1 / 20000 拍):
//
//   E1 平局规则改成"取下标大者"(pick_older 里 `>` 改 `>=`)  → errors=6156
//   E2 口 6 的 vaNeedExt 常数写成 0(应为 1)                 → errors=5194
//   E3 选择树最后一对的叶子顺序对调(保持值排到前面)          → errors=13788
//   E4 给不复位的 req 负载加复位                             → errors=90
//
// 同一条件下未变异版本 errors=0 / checks=419223。
// E4 只有 90 个 errors —— 同 DatamoduleResultBuffer 的 D3:它只在中途复位脉冲
// 之后的几拍里可见。★没有那个脉冲就是 0。★
// =============================================================================
`timescale 1ns/1ps
module tb;

  localparam int NP = 7;   // enqPortNum

  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  // --- redirect ---
  logic        rd_valid;
  logic        rd_flag;
  logic [7:0]  rd_value;
  logic        rd_level;

  // --- 7 个入队口(★三种形状★,见 RTL 文件头)---
  logic        in_valid [NP];
  logic        exc3  [NP], exc6 [NP], exc7 [NP], exc15 [NP], exc19 [NP], exc23 [NP];
  logic [6:0]  uopIdx [NP];
  logic        robF   [NP];
  logic [7:0]  robV   [NP];
  logic [63:0] fullva [NP];
  logic        vaNeedExt [6];          // 只有口 0..5
  logic [63:0] gpaddr    [6];          // 只有口 0..5
  logic        isForVS   [6];          // 只有口 0..5
  logic        isHyper   [4];          // 只有口 0..3

  // --- 输出 ---
  logic [63:0] g_vaddr, i_vaddr, g_gpaddr, i_gpaddr;
  logic        g_vaNeedExt, i_vaNeedExt, g_isHyper, i_isHyper, g_isForVS, i_isForVS;

  `define SEB_PORTS(SUF, VA, GP, HY, FV) \
    .clock(clk), .reset(rst), \
    .io_redirect_valid(rd_valid), .io_redirect_bits_robIdx_flag(rd_flag), \
    .io_redirect_bits_robIdx_value(rd_value), .io_redirect_bits_level(rd_level), \
    .io_storeAddrIn_0_valid(in_valid[0]), \
    .io_storeAddrIn_0_bits_uop_exceptionVec_3(exc3[0]), \
    .io_storeAddrIn_0_bits_uop_exceptionVec_6(exc6[0]), \
    .io_storeAddrIn_0_bits_uop_exceptionVec_7(exc7[0]), \
    .io_storeAddrIn_0_bits_uop_exceptionVec_15(exc15[0]), \
    .io_storeAddrIn_0_bits_uop_exceptionVec_19(exc19[0]), \
    .io_storeAddrIn_0_bits_uop_exceptionVec_23(exc23[0]), \
    .io_storeAddrIn_0_bits_uop_uopIdx(uopIdx[0]), \
    .io_storeAddrIn_0_bits_uop_robIdx_flag(robF[0]), \
    .io_storeAddrIn_0_bits_uop_robIdx_value(robV[0]), \
    .io_storeAddrIn_0_bits_fullva(fullva[0]), \
    .io_storeAddrIn_0_bits_vaNeedExt(vaNeedExt[0]), \
    .io_storeAddrIn_0_bits_gpaddr(gpaddr[0]), \
    .io_storeAddrIn_0_bits_isHyper(isHyper[0]), \
    .io_storeAddrIn_0_bits_isForVSnonLeafPTE(isForVS[0]), \
    .io_storeAddrIn_1_valid(in_valid[1]), \
    .io_storeAddrIn_1_bits_uop_exceptionVec_3(exc3[1]), \
    .io_storeAddrIn_1_bits_uop_exceptionVec_6(exc6[1]), \
    .io_storeAddrIn_1_bits_uop_exceptionVec_7(exc7[1]), \
    .io_storeAddrIn_1_bits_uop_exceptionVec_15(exc15[1]), \
    .io_storeAddrIn_1_bits_uop_exceptionVec_19(exc19[1]), \
    .io_storeAddrIn_1_bits_uop_exceptionVec_23(exc23[1]), \
    .io_storeAddrIn_1_bits_uop_uopIdx(uopIdx[1]), \
    .io_storeAddrIn_1_bits_uop_robIdx_flag(robF[1]), \
    .io_storeAddrIn_1_bits_uop_robIdx_value(robV[1]), \
    .io_storeAddrIn_1_bits_fullva(fullva[1]), \
    .io_storeAddrIn_1_bits_vaNeedExt(vaNeedExt[1]), \
    .io_storeAddrIn_1_bits_gpaddr(gpaddr[1]), \
    .io_storeAddrIn_1_bits_isHyper(isHyper[1]), \
    .io_storeAddrIn_1_bits_isForVSnonLeafPTE(isForVS[1]), \
    .io_storeAddrIn_2_valid(in_valid[2]), \
    .io_storeAddrIn_2_bits_uop_exceptionVec_3(exc3[2]), \
    .io_storeAddrIn_2_bits_uop_exceptionVec_6(exc6[2]), \
    .io_storeAddrIn_2_bits_uop_exceptionVec_7(exc7[2]), \
    .io_storeAddrIn_2_bits_uop_exceptionVec_15(exc15[2]), \
    .io_storeAddrIn_2_bits_uop_exceptionVec_19(exc19[2]), \
    .io_storeAddrIn_2_bits_uop_exceptionVec_23(exc23[2]), \
    .io_storeAddrIn_2_bits_uop_uopIdx(uopIdx[2]), \
    .io_storeAddrIn_2_bits_uop_robIdx_flag(robF[2]), \
    .io_storeAddrIn_2_bits_uop_robIdx_value(robV[2]), \
    .io_storeAddrIn_2_bits_fullva(fullva[2]), \
    .io_storeAddrIn_2_bits_vaNeedExt(vaNeedExt[2]), \
    .io_storeAddrIn_2_bits_gpaddr(gpaddr[2]), \
    .io_storeAddrIn_2_bits_isHyper(isHyper[2]), \
    .io_storeAddrIn_2_bits_isForVSnonLeafPTE(isForVS[2]), \
    .io_storeAddrIn_3_valid(in_valid[3]), \
    .io_storeAddrIn_3_bits_uop_exceptionVec_3(exc3[3]), \
    .io_storeAddrIn_3_bits_uop_exceptionVec_6(exc6[3]), \
    .io_storeAddrIn_3_bits_uop_exceptionVec_7(exc7[3]), \
    .io_storeAddrIn_3_bits_uop_exceptionVec_15(exc15[3]), \
    .io_storeAddrIn_3_bits_uop_exceptionVec_19(exc19[3]), \
    .io_storeAddrIn_3_bits_uop_exceptionVec_23(exc23[3]), \
    .io_storeAddrIn_3_bits_uop_uopIdx(uopIdx[3]), \
    .io_storeAddrIn_3_bits_uop_robIdx_flag(robF[3]), \
    .io_storeAddrIn_3_bits_uop_robIdx_value(robV[3]), \
    .io_storeAddrIn_3_bits_fullva(fullva[3]), \
    .io_storeAddrIn_3_bits_vaNeedExt(vaNeedExt[3]), \
    .io_storeAddrIn_3_bits_gpaddr(gpaddr[3]), \
    .io_storeAddrIn_3_bits_isHyper(isHyper[3]), \
    .io_storeAddrIn_3_bits_isForVSnonLeafPTE(isForVS[3]), \
    .io_storeAddrIn_4_valid(in_valid[4]), \
    .io_storeAddrIn_4_bits_uop_exceptionVec_3(exc3[4]), \
    .io_storeAddrIn_4_bits_uop_exceptionVec_6(exc6[4]), \
    .io_storeAddrIn_4_bits_uop_exceptionVec_7(exc7[4]), \
    .io_storeAddrIn_4_bits_uop_exceptionVec_15(exc15[4]), \
    .io_storeAddrIn_4_bits_uop_exceptionVec_19(exc19[4]), \
    .io_storeAddrIn_4_bits_uop_exceptionVec_23(exc23[4]), \
    .io_storeAddrIn_4_bits_uop_uopIdx(uopIdx[4]), \
    .io_storeAddrIn_4_bits_uop_robIdx_flag(robF[4]), \
    .io_storeAddrIn_4_bits_uop_robIdx_value(robV[4]), \
    .io_storeAddrIn_4_bits_fullva(fullva[4]), \
    .io_storeAddrIn_4_bits_vaNeedExt(vaNeedExt[4]), \
    .io_storeAddrIn_4_bits_gpaddr(gpaddr[4]), \
    .io_storeAddrIn_4_bits_isForVSnonLeafPTE(isForVS[4]), \
    .io_storeAddrIn_5_valid(in_valid[5]), \
    .io_storeAddrIn_5_bits_uop_exceptionVec_3(exc3[5]), \
    .io_storeAddrIn_5_bits_uop_exceptionVec_6(exc6[5]), \
    .io_storeAddrIn_5_bits_uop_exceptionVec_7(exc7[5]), \
    .io_storeAddrIn_5_bits_uop_exceptionVec_15(exc15[5]), \
    .io_storeAddrIn_5_bits_uop_exceptionVec_19(exc19[5]), \
    .io_storeAddrIn_5_bits_uop_exceptionVec_23(exc23[5]), \
    .io_storeAddrIn_5_bits_uop_uopIdx(uopIdx[5]), \
    .io_storeAddrIn_5_bits_uop_robIdx_flag(robF[5]), \
    .io_storeAddrIn_5_bits_uop_robIdx_value(robV[5]), \
    .io_storeAddrIn_5_bits_fullva(fullva[5]), \
    .io_storeAddrIn_5_bits_vaNeedExt(vaNeedExt[5]), \
    .io_storeAddrIn_5_bits_gpaddr(gpaddr[5]), \
    .io_storeAddrIn_5_bits_isForVSnonLeafPTE(isForVS[5]), \
    .io_storeAddrIn_6_valid(in_valid[6]), \
    .io_storeAddrIn_6_bits_uop_exceptionVec_7(exc7[6]), \
    .io_storeAddrIn_6_bits_uop_exceptionVec_19(exc19[6]), \
    .io_storeAddrIn_6_bits_uop_uopIdx(uopIdx[6]), \
    .io_storeAddrIn_6_bits_uop_robIdx_flag(robF[6]), \
    .io_storeAddrIn_6_bits_uop_robIdx_value(robV[6]), \
    .io_storeAddrIn_6_bits_fullva(fullva[6]), \
    .io_exceptionAddr_vaddr(VA), .io_exceptionAddr_vaNeedExt(GP), \
    .io_exceptionAddr_isHyper(HY), .io_exceptionAddr_gpaddr(FV), \
    .io_exceptionAddr_isForVSnonLeafPTE(SUF)

  StoreExceptionBuffer    g_u (`SEB_PORTS(g_isForVS, g_vaddr, g_vaNeedExt, g_isHyper, g_gpaddr));
  StoreExceptionBuffer_xs i_u (`SEB_PORTS(i_isForVS, i_vaddr, i_vaNeedExt, i_isHyper, i_gpaddr));

  // ---------------------------------------------------------------------------
  int cov_tie_p6_hold = 0, cov_tie_s2 = 0, cov_flush_s1 = 0, cov_flush_s2 = 0;
  int cov_flush_hold = 0, cov_flushitself = 0, cov_p6_wins = 0, cov_p45_wins = 0;
  int cov_exc_zero = 0, cov_mid_reset = 0, cov_empty = 0;

  bit warm = 1;
  int warm_i = 0;

  // robIdx 压到 16 个取值、uopIdx 压到 4 个 —— 让平局成为常态。
  function automatic logic [7:0] pick_robv(); return 8'($urandom_range(0, 7)); endfunction
  function automatic logic [6:0] pick_uop();  return 7'($urandom_range(0, 3)); endfunction

  always @(negedge clk) begin
    if (rst) begin
      for (int p = 0; p < NP; p++) begin
        in_valid[p] <= 1'b0;
        exc3[p] <= 0; exc6[p] <= 0; exc7[p] <= 0; exc15[p] <= 0; exc19[p] <= 0; exc23[p] <= 0;
        uopIdx[p] <= '0; robF[p] <= 1'b0; robV[p] <= '0; fullva[p] <= '0;
      end
      for (int p = 0; p < 6; p++) begin vaNeedExt[p] <= 0; gpaddr[p] <= '0; isForVS[p] <= 0; end
      for (int p = 0; p < 4; p++) isHyper[p] <= 0;
      rd_valid <= 1'b0; rd_flag <= 1'b0; rd_value <= '0; rd_level <= 1'b0;
      // 中途复位不重做预热:除 req_valid 外都不复位。
      if (warm_i < 24) begin warm_i <= 0; warm <= 1; end
    end else begin
      if (warm_i < 24) warm_i <= warm_i + 1; else warm <= 0;

      for (int p = 0; p < NP; p++) begin
        // 预热阶段 7 个口全打有效,把 65 个不复位寄存器写满。
        in_valid[p] <= (warm_i < 24) ? 1'b1 : ($urandom_range(0, 99) < 45);
        uopIdx[p]   <= pick_uop();
        robF[p]     <= 1'($urandom);
        robV[p]     <= pick_robv();
        fullva[p]   <= {32'($urandom), 32'($urandom)};
        // E7:约 12% 的拍子异常向量全 0 —— 即便 valid 也不该成为候选。
        if (warm_i >= 24 && $urandom_range(0, 99) < 12) begin
          exc3[p] <= 0; exc6[p] <= 0; exc7[p] <= 0; exc15[p] <= 0; exc19[p] <= 0; exc23[p] <= 0;
        end else begin
          exc3[p]  <= 1'($urandom); exc6[p]  <= 1'($urandom);
          exc7[p]  <= 1'b1;                       // 口 6 只有 7/19 两位,保证它能成为候选
          exc15[p] <= 1'($urandom); exc19[p] <= 1'($urandom); exc23[p] <= 1'($urandom);
        end
      end
      for (int p = 0; p < 6; p++) begin
        vaNeedExt[p] <= 1'($urandom);
        gpaddr[p]    <= {32'($urandom), 32'($urandom)};
        isForVS[p]   <= 1'($urandom);
      end
      for (int p = 0; p < 4; p++) isHyper[p] <= 1'($urandom);

      // E3/E4:重定向也从同一个小空间取,保证冲刷判据的三种结果都常见。
      rd_valid <= (warm_i >= 24) && ($urandom_range(0, 99) < 25);
      rd_flag  <= 1'($urandom);
      rd_value <= pick_robv();
      rd_level <= 1'($urandom);
    end
  end

  // ---------------------------------------------------------------------------
  // 覆盖统计(用 golden 的内部信号判定,impl 只负责跟上)
  // ---------------------------------------------------------------------------
  always @(posedge clk) if (!rst && !warm) begin
    bit s26v, holdv;
    s26v  = g_u.s2_valid_6;
    holdv = g_u.reqValid;
    // E1:s2 口 6 与保持值 robIdx + uopIdx 完全相等且两者都有效
    if (s26v && holdv &&
        {g_u.s2_req_6_uop_robIdx_flag, g_u.s2_req_6_uop_robIdx_value} ==
        {g_u.req_uop_robIdx_flag, g_u.req_uop_robIdx_value} &&
        g_u.s2_req_6_uop_uopIdx == g_u.req_uop_uopIdx) cov_tie_p6_hold++;
    // E2:s2 口 0/1 平局
    if (g_u.s2_valid_0 && g_u.s2_valid_1 &&
        {g_u.s2_req_0_uop_robIdx_flag, g_u.s2_req_0_uop_robIdx_value} ==
        {g_u.s2_req_1_uop_robIdx_flag, g_u.s2_req_1_uop_robIdx_value} &&
        g_u.s2_req_0_uop_uopIdx == g_u.s2_req_1_uop_uopIdx) cov_tie_s2++;
    // E3:三个冲刷点各自生效
    if (rd_valid && in_valid[0] && !g_u.s1_valid_0 &&
        (exc3[0]|exc6[0]|exc7[0]|exc15[0]|exc19[0]|exc23[0])) cov_flush_s1++;
    if (rd_valid && g_u.s2_valid_REG && !g_u.s2_valid_0) cov_flush_s2++;
    if (rd_valid && g_u.req_valid && !g_u.reqValid)       cov_flush_hold++;
    // E4:flushItself 精确命中
    if (rd_valid && rd_level && g_u.req_valid &&
        {g_u.req_uop_robIdx_flag, g_u.req_uop_robIdx_value} == {rd_flag, rd_value})
      cov_flushitself++;
    // E5/E6:口 6 / 口 4|5 赢下选择树(用 fullva 指纹辨认赢家)
    if (g_u.req_valid) begin
      if (g_u.req_fullva == g_u.s2_req_6_fullva && g_u.req_vaNeedExt == 1'b1 &&
          g_u.req_gpaddr == 64'h0) cov_p6_wins++;
      if ((g_u.req_fullva == g_u.s2_req_4_fullva || g_u.req_fullva == g_u.s2_req_5_fullva)
          && g_u.req_isHyper == 1'b0) cov_p45_wins++;
    end else cov_empty++;
    if (!(exc3[6]|exc6[6]|exc7[6]|exc15[6]|exc19[6]|exc23[6])) cov_exc_zero++;
  end

  // ---------------------------------------------------------------------------
  `define CK(nm, g, i) \
    begin checks++; \
      if ((g) !== (i)) begin errors++; \
        if (errors <= 60) $display("[%0t] %s g=%h i=%h", $time, nm, (g), (i)); end end

  always @(negedge clk) if (!rst && !warm) begin
    #4;
    `CK("vaddr",     g_vaddr,     i_vaddr)
    `CK("vaNeedExt", g_vaNeedExt, i_vaNeedExt)
    `CK("isHyper",   g_isHyper,   i_isHyper)
    `CK("gpaddr",    g_gpaddr,    i_gpaddr)
    `CK("isForVS",   g_isForVS,   i_isForVS)
    // 内部状态:唯一的异步复位位 + 保持负载 + s2 流水
    `CK("req_valid", g_u.req_valid, i_u.u_core.req_valid)
    `CK("req.uopIdx",g_u.req_uop_uopIdx,       i_u.u_core.req.uopIdx)
    `CK("req.robF",  g_u.req_uop_robIdx_flag,  i_u.u_core.req.robIdx.flag)
    `CK("req.robV",  g_u.req_uop_robIdx_value, i_u.u_core.req.robIdx.value)
    `CK("req.fullva",g_u.req_fullva,           i_u.u_core.req.fullva)
    `CK("req.gpaddr",g_u.req_gpaddr,           i_u.u_core.req.gpaddr)
    `CK("req.vaNE",  g_u.req_vaNeedExt,        i_u.u_core.req.vaNeedExt)
    `CK("req.isHy",  g_u.req_isHyper,          i_u.u_core.req.isHyper)
    `CK("req.isFVS", g_u.req_isForVSnonLeafPTE,i_u.u_core.req.isForVSnonLeafPTE)
    `CK("s2vREG_0",  g_u.s2_valid_REG,   i_u.u_core.s2_valid_r[0])
    `CK("s2vREG_4",  g_u.s2_valid_REG_4, i_u.u_core.s2_valid_r[4])
    `CK("s2vREG_6",  g_u.s2_valid_REG_6, i_u.u_core.s2_valid_r[6])
    `CK("s2_0.robV", g_u.s2_req_0_uop_robIdx_value, i_u.u_core.s2_robIdx[0].value)
    `CK("s2_0.isHy", g_u.s2_req_0_isHyper,          i_u.u_core.s2_isHyper[0])
    `CK("s2_4.isFVS",g_u.s2_req_4_isForVSnonLeafPTE,i_u.u_core.s2_isForVSnonLeafPTE[4])
    `CK("s2_6.fva",  g_u.s2_req_6_fullva,           i_u.u_core.s2_fullva[6])
  end

  // ---------------------------------------------------------------------------
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    fork
      forever begin   // ★ E8 中途复位脉冲 ★
        repeat (2800 + $urandom_range(0, 400)) @(posedge clk);
        rst = 1; cov_mid_reset++; repeat (2) @(posedge clk); rst = 0;
      end
    join_none
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    $display("COVERAGE tie_p6_hold=%0d tie_s2=%0d flush_s1=%0d flush_s2=%0d flush_hold=%0d flushitself=%0d",
             cov_tie_p6_hold, cov_tie_s2, cov_flush_s1, cov_flush_s2, cov_flush_hold, cov_flushitself);
    $display("COVERAGE p6_wins=%0d p45_wins=%0d exc_zero=%0d empty=%0d mid_reset=%0d",
             cov_p6_wins, cov_p45_wins, cov_exc_zero, cov_empty, cov_mid_reset);
    if (errors == 0 && checks > 1000 &&
        cov_tie_p6_hold > 50 && cov_tie_s2 > 50 &&
        cov_flush_s1 > 50 && cov_flush_s2 > 50 && cov_flush_hold > 50 &&
        cov_flushitself > 20 && cov_p6_wins > 20 && cov_p45_wins > 20 &&
        cov_exc_zero > 50 && cov_empty > 20 && cov_mid_reset > 2)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
