// =============================================================================
// VTypeGen UT —— golden VTypeGen（含 golden VsetModule）对重写 VTypeGen_xs 双例化，
// 同激励逐拍比对 5 根输出（vtype 的 illegal/vma/vta/vsew/vlmul）。
//
// ★ 判别力在哪 ★
//   · 6 路指令要经常出现 vsetvli/vsetivli（opcode 1010111 + funct3 111 + bit31 形态），
//     并且要覆盖 zimm 的合法/非法组合（vlmul=100、vsew[2]=1、SEW 超 ELEN*LMUL、保留位非 0）；
//     还要常常出现 vsetvl（bit31:30=10）来验证它**不**触发译码级更新。
//   · 四个更新来源（hasVsetvl / walkVType / walkToArchVType / 本拍 vset）要以随机相位互相
//     撞上，验证 when 链优先级。
//   · 复位：运行中多次异步复位，复位拍也比对（复位值 illegal=1）。
// 覆盖判据：vset 命中、非法 vtype、每种更新来源各 ≥ 1 次，否则 errors=0 不作数。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  localparam int WARMUP = 8;
  bit  clk = 0;
  logic rst;
  int  errors = 0;
  longint checks = 0;
  always #5 clk = ~clk;

  logic        io_insts_0_valid, io_insts_1_valid, io_insts_2_valid, io_insts_3_valid, io_insts_4_valid, io_insts_5_valid;
  logic [31:0] io_insts_0_bits, io_insts_1_bits, io_insts_2_bits, io_insts_3_bits, io_insts_4_bits, io_insts_5_bits;
  logic        io_walkToArchVType, io_walkVType_valid;
  logic        io_walkVType_bits_illegal, io_walkVType_bits_vma, io_walkVType_bits_vta;
  logic [1:0]  io_walkVType_bits_vsew;
  logic [2:0]  io_walkVType_bits_vlmul;
  logic        io_canUpdateVType;
  logic        io_vsetvlVType_illegal, io_vsetvlVType_vma, io_vsetvlVType_vta;
  logic [1:0]  io_vsetvlVType_vsew;
  logic [2:0]  io_vsetvlVType_vlmul;
  logic        io_commitVType_vtype_valid;
  logic        io_commitVType_vtype_bits_illegal, io_commitVType_vtype_bits_vma, io_commitVType_vtype_bits_vta;
  logic [1:0]  io_commitVType_vtype_bits_vsew;
  logic [2:0]  io_commitVType_vtype_bits_vlmul;
  logic        io_commitVType_hasVsetvl;

  logic        g_illegal, g_vma, g_vta, x_illegal, x_vma, x_vta;
  logic [1:0]  g_vsew, x_vsew;
  logic [2:0]  g_vlmul, x_vlmul;

`define VTG_CONNS(pfx) \
    .clock(clk), .reset(rst), \
    .io_insts_0_valid(io_insts_0_valid), .io_insts_0_bits(io_insts_0_bits), \
    .io_insts_1_valid(io_insts_1_valid), .io_insts_1_bits(io_insts_1_bits), \
    .io_insts_2_valid(io_insts_2_valid), .io_insts_2_bits(io_insts_2_bits), \
    .io_insts_3_valid(io_insts_3_valid), .io_insts_3_bits(io_insts_3_bits), \
    .io_insts_4_valid(io_insts_4_valid), .io_insts_4_bits(io_insts_4_bits), \
    .io_insts_5_valid(io_insts_5_valid), .io_insts_5_bits(io_insts_5_bits), \
    .io_walkToArchVType(io_walkToArchVType), .io_walkVType_valid(io_walkVType_valid), \
    .io_walkVType_bits_illegal(io_walkVType_bits_illegal), .io_walkVType_bits_vma(io_walkVType_bits_vma), \
    .io_walkVType_bits_vta(io_walkVType_bits_vta), .io_walkVType_bits_vsew(io_walkVType_bits_vsew), \
    .io_walkVType_bits_vlmul(io_walkVType_bits_vlmul), .io_canUpdateVType(io_canUpdateVType), \
    .io_vtype_illegal(pfx``_illegal), .io_vtype_vma(pfx``_vma), .io_vtype_vta(pfx``_vta), \
    .io_vtype_vsew(pfx``_vsew), .io_vtype_vlmul(pfx``_vlmul), \
    .io_vsetvlVType_illegal(io_vsetvlVType_illegal), .io_vsetvlVType_vma(io_vsetvlVType_vma), \
    .io_vsetvlVType_vta(io_vsetvlVType_vta), .io_vsetvlVType_vsew(io_vsetvlVType_vsew), \
    .io_vsetvlVType_vlmul(io_vsetvlVType_vlmul), \
    .io_commitVType_vtype_valid(io_commitVType_vtype_valid), \
    .io_commitVType_vtype_bits_illegal(io_commitVType_vtype_bits_illegal), \
    .io_commitVType_vtype_bits_vma(io_commitVType_vtype_bits_vma), \
    .io_commitVType_vtype_bits_vta(io_commitVType_vtype_bits_vta), \
    .io_commitVType_vtype_bits_vsew(io_commitVType_vtype_bits_vsew), \
    .io_commitVType_vtype_bits_vlmul(io_commitVType_vtype_bits_vlmul), \
    .io_commitVType_hasVsetvl(io_commitVType_hasVsetvl)

  VTypeGen    u_g (`VTG_CONNS(g));
  VTypeGen_xs u_x (`VTG_CONNS(x));

  // ---- 覆盖计数（取自 golden 侧内部信号）----
  int cov_vset = 0, cov_illegal = 0, cov_hasvsetvl = 0, cov_walk = 0, cov_walk2arch = 0, cov_specupd = 0, cov_vsetvl_seen = 0;

  function automatic logic [31:0] mk_instr();
    logic [4:0] rd = 5'($urandom), rs1 = 5'($urandom);
    int pick = $urandom_range(0, 99);
    if (pick < 30)      return {1'b0, 11'($urandom), rs1, 3'b111, rd, 7'h57};                 // vsetvli（zimm 全随机：含非法）
    else if (pick < 45) return {1'b0, 3'b000, 1'($urandom), 1'($urandom), 1'b0, 2'($urandom), 3'($urandom), rs1, 3'b111, rd, 7'h57}; // vsetvli，多半合法
    else if (pick < 60) return {2'b11, 5'($urandom), 5'($urandom), 5'($urandom), rs1, 3'b111, rd, 7'h57}; // vsetivli
    else if (pick < 70) return {2'b10, 5'b00000, 5'($urandom), rs1, 3'b111, rd, 7'h57};       // vsetvl（不该触发）
    else if (pick < 80) return {7'($urandom), 5'($urandom), rs1, 3'($urandom_range(0,6)), rd, 7'h57}; // OP-V 非 vset
    else                return $urandom;
  endfunction

  task automatic drive_inputs();
    io_insts_0_valid = 1'($urandom); io_insts_0_bits = mk_instr();
    io_insts_1_valid = 1'($urandom); io_insts_1_bits = mk_instr();
    io_insts_2_valid = 1'($urandom); io_insts_2_bits = mk_instr();
    io_insts_3_valid = 1'($urandom); io_insts_3_bits = mk_instr();
    io_insts_4_valid = 1'($urandom); io_insts_4_bits = mk_instr();
    io_insts_5_valid = 1'($urandom); io_insts_5_bits = mk_instr();
    io_walkToArchVType = ($urandom_range(0, 7) == 0);
    io_walkVType_valid = ($urandom_range(0, 7) == 0);
    io_walkVType_bits_illegal = 1'($urandom); io_walkVType_bits_vma = 1'($urandom); io_walkVType_bits_vta = 1'($urandom);
    io_walkVType_bits_vsew = 2'($urandom); io_walkVType_bits_vlmul = 3'($urandom);
    io_canUpdateVType = ($urandom_range(0, 3) != 0);
    io_vsetvlVType_illegal = 1'($urandom); io_vsetvlVType_vma = 1'($urandom); io_vsetvlVType_vta = 1'($urandom);
    io_vsetvlVType_vsew = 2'($urandom); io_vsetvlVType_vlmul = 3'($urandom);
    io_commitVType_vtype_valid = ($urandom_range(0, 5) == 0);
    io_commitVType_vtype_bits_illegal = 1'($urandom); io_commitVType_vtype_bits_vma = 1'($urandom);
    io_commitVType_vtype_bits_vta = 1'($urandom); io_commitVType_vtype_bits_vsew = 2'($urandom);
    io_commitVType_vtype_bits_vlmul = 3'($urandom);
    io_commitVType_hasVsetvl = ($urandom_range(0, 15) == 0);
  endtask

  task automatic compare_outputs();
    checks++;
    if (g_illegal !== x_illegal) begin errors++; if (errors < 20) $display("MISMATCH @%0t illegal g=%b x=%b", $time, g_illegal, x_illegal); end
    if (g_vma     !== x_vma)     begin errors++; if (errors < 20) $display("MISMATCH @%0t vma g=%b x=%b", $time, g_vma, x_vma); end
    if (g_vta     !== x_vta)     begin errors++; if (errors < 20) $display("MISMATCH @%0t vta g=%b x=%b", $time, g_vta, x_vta); end
    if (g_vsew    !== x_vsew)    begin errors++; if (errors < 20) $display("MISMATCH @%0t vsew g=%h x=%h", $time, g_vsew, x_vsew); end
    if (g_vlmul   !== x_vlmul)   begin errors++; if (errors < 20) $display("MISMATCH @%0t vlmul g=%h x=%h", $time, g_vlmul, x_vlmul); end
  endtask

  task automatic collect_cov();
    logic anyvset = |{u_g.isVsetVec_0, u_g.isVsetVec_1, u_g.isVsetVec_2, u_g.isVsetVec_3, u_g.isVsetVec_4, u_g.isVsetVec_5};
    if (anyvset) cov_vset++;
    if (anyvset && u_g.vsetModule.io_out_vconfig_vtype_illegal) cov_illegal++;
    if (io_commitVType_hasVsetvl) cov_hasvsetvl++;
    else begin
      if (io_walkVType_valid) cov_walk++;
      else if (io_walkToArchVType) cov_walk2arch++;
      else if (anyvset && io_canUpdateVType) cov_specupd++;
    end
    if (io_insts_0_valid && io_insts_0_bits[6:0] == 7'h57 && io_insts_0_bits[14:12] == 3'b111 && io_insts_0_bits[31:30] == 2'b10) cov_vsetvl_seen++;
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    rst = 1'b1; drive_inputs();
    repeat (4) @(negedge clk);
    rst = 1'b0;
    for (longint c = 0; c < NCYCLES; c++) begin
      // 运行中多次异步复位（每 ~16000 拍 2 拍），复位拍也打激励、也比对
      rst = ((c % 16384) < 2) && (c > WARMUP);
      drive_inputs();
      #1;
      if (c >= WARMUP) begin compare_outputs(); collect_cov(); end
      @(negedge clk);
    end
    $display("=== COVERAGE (VTypeGen) === checks=%0d vset=%0d illegal=%0d hasVsetvl=%0d walk=%0d walkToArch=%0d specUpdate=%0d vsetvl_seen=%0d",
             checks, cov_vset, cov_illegal, cov_hasvsetvl, cov_walk, cov_walk2arch, cov_specupd, cov_vsetvl_seen);
    if (cov_vset == 0 || cov_illegal == 0 || cov_hasvsetvl == 0 || cov_walk == 0 || cov_walk2arch == 0 || cov_specupd == 0 || cov_vsetvl_seen == 0) begin
      $display("COVERAGE INSUFFICIENT"); errors++;
    end
    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
