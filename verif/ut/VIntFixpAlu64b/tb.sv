// =============================================================================
// tb —— VIntFixpAlu64b UT：golden VIntFixpAlu64b（含 golden VIntAdder64b / VIntMisc64b(+CLZ) /
// VFixPoint64b(+Adder_chain_rnd)）与重写件 VIntFixpAlu64b_xs（含全部重写子树）双例化，
// 同时钟同激励，每拍比全部输出（vd / narrowVd / cmpOut / vxsat）。
//
// 复位域：golden 全部流水寄存器不复位（RegEnable(fire)）。+random 档两侧上电值不同，所以
//   只在第一次 fire 之后的拍才比对（那时所有 S1 寄存器都已被写过一次；没有任何寄存器只在
//   部分路径下写）。fire 四分之三的拍为 1，fire=0 的拍输入照样变（检查保持）。
// 激励：opcode 八成取 0..32 与 46（isIntFixp 的全部编码）、两成任意 6 位；srcType/vdType 随机 4 位
//   （[1:0] 是 SEW，[3:2]=1 表示有符号）；isSub/isMisc/isFixp/widen/widen_vs2 随机；
//   vs1/vs2_adder/vs2_misc 按 全随机/全 0/全 1/稀疏 四种形状；vmask/oldVd/narrow 随机。
// 覆盖（写进 PASS 判据）：isFixp×isMisc 四格 ≥ 2000；定点六编码 × SEW 四种每格 ≥ 200；
//   fire=0 的比对拍 ≥ 10000；每个输出位都见过 0 和 1。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;
  int cyc;
  logic clock = 0;
  always #5 clock = ~clock;

  // ---- 以下声明/例化/比较由 golden 端口表机械展开（21 输入 / 4 输出）----
  logic io_fire;
  logic [5:0] io_opcode_op;
  logic io_info_vm;
  logic io_info_ma;
  logic [5:0] io_info_uopIdx;
  logic [1:0] io_info_vxrm;
  logic [3:0] io_srcType_0;
  logic [3:0] io_srcType_1;
  logic [3:0] io_vdType;
  logic [63:0] io_vs1;
  logic [63:0] io_vs2_adder;
  logic [63:0] io_vs2_misc;
  logic [7:0] io_vmask;
  logic [7:0] io_oldVd;
  logic [7:0] io_narrow;
  logic io_isSub;
  logic io_isMisc;
  logic io_isFixp;
  logic io_widen;
  logic io_widen_vs2;
  logic [63:0] g_io_vd, i_io_vd;
  logic [31:0] g_io_narrowVd, i_io_narrowVd;
  logic [7:0] g_io_cmpOut, i_io_cmpOut;
  logic [7:0] g_io_vxsat, i_io_vxsat;
  VIntFixpAlu64b u_g (
    .clock(clock),
    .io_fire(io_fire),
    .io_opcode_op(io_opcode_op),
    .io_info_vm(io_info_vm),
    .io_info_ma(io_info_ma),
    .io_info_uopIdx(io_info_uopIdx),
    .io_info_vxrm(io_info_vxrm),
    .io_srcType_0(io_srcType_0),
    .io_srcType_1(io_srcType_1),
    .io_vdType(io_vdType),
    .io_vs1(io_vs1),
    .io_vs2_adder(io_vs2_adder),
    .io_vs2_misc(io_vs2_misc),
    .io_vmask(io_vmask),
    .io_oldVd(io_oldVd),
    .io_narrow(io_narrow),
    .io_isSub(io_isSub),
    .io_isMisc(io_isMisc),
    .io_isFixp(io_isFixp),
    .io_widen(io_widen),
    .io_widen_vs2(io_widen_vs2),
    .io_vd(g_io_vd),
    .io_narrowVd(g_io_narrowVd),
    .io_cmpOut(g_io_cmpOut),
    .io_vxsat(g_io_vxsat)
  );
  VIntFixpAlu64b_xs u_i (
    .clock(clock),
    .io_fire(io_fire),
    .io_opcode_op(io_opcode_op),
    .io_info_vm(io_info_vm),
    .io_info_ma(io_info_ma),
    .io_info_uopIdx(io_info_uopIdx),
    .io_info_vxrm(io_info_vxrm),
    .io_srcType_0(io_srcType_0),
    .io_srcType_1(io_srcType_1),
    .io_vdType(io_vdType),
    .io_vs1(io_vs1),
    .io_vs2_adder(io_vs2_adder),
    .io_vs2_misc(io_vs2_misc),
    .io_vmask(io_vmask),
    .io_oldVd(io_oldVd),
    .io_narrow(io_narrow),
    .io_isSub(io_isSub),
    .io_isMisc(io_isMisc),
    .io_isFixp(io_isFixp),
    .io_widen(io_widen),
    .io_widen_vs2(io_widen_vs2),
    .io_vd(i_io_vd),
    .io_narrowVd(i_io_narrowVd),
    .io_cmpOut(i_io_cmpOut),
    .io_vxsat(i_io_vxsat)
  );
  localparam int N_OUT = 4;
  bit seen0 [N_OUT];  // 该输出出现过"某位为 0"
  bit seen1 [N_OUT];  // 该输出出现过"某位为 1"
  `define CMP(k, g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      if (|(g)) seen1[k] = 1; if (!(&(g))) seen0[k] = 1; end
  task automatic compare_all();
    `CMP(0, g_io_vd, i_io_vd, "io_vd")
    `CMP(1, g_io_narrowVd, i_io_narrowVd, "io_narrowVd")
    `CMP(2, g_io_cmpOut, i_io_cmpOut, "io_cmpOut")
    `CMP(3, g_io_vxsat, i_io_vxsat, "io_vxsat")
  endtask
  task automatic rand_inputs();
    io_fire = 1'($urandom);
    io_opcode_op = 6'($urandom);
    io_info_vm = 1'($urandom);
    io_info_ma = 1'($urandom);
    io_info_uopIdx = 6'($urandom);
    io_info_vxrm = 2'($urandom);
    io_srcType_0 = 4'($urandom);
    io_srcType_1 = 4'($urandom);
    io_vdType = 4'($urandom);
    io_vs1 = 64'({$urandom, $urandom});
    io_vs2_adder = 64'({$urandom, $urandom});
    io_vs2_misc = 64'({$urandom, $urandom});
    io_vmask = 8'($urandom);
    io_oldVd = 8'($urandom);
    io_narrow = 8'($urandom);
    io_isSub = 1'($urandom);
    io_isMisc = 1'($urandom);
    io_isFixp = 1'($urandom);
    io_widen = 1'($urandom);
    io_widen_vs2 = 1'($urandom);
  endtask

  int cov_mode [2][2];       // [isFixp][isMisc] 在 S1 侧的组合（按打拍前的输入计）
  int cov_fixp_sew [6][4];
  int cov_hold;
  bit fired = 0;

  function automatic logic [63:0] shape64();
    logic [63:0] x;
    x = {$urandom, $urandom};
    case ($urandom_range(0, 3))
      0: return x;
      1: return '0;
      2: return '1;
      default: return x & {$urandom, $urandom};
    endcase
  endfunction

  task automatic drive();
    rand_inputs();
    io_fire = ($urandom_range(0, 3) != 0);
    if ($urandom_range(0, 4) != 0) begin
      io_opcode_op = 6'($urandom_range(0, 33));
      if (io_opcode_op == 33) io_opcode_op = 6'd46;
    end
    io_vs1       = shape64();
    io_vs2_adder = shape64();
    io_vs2_misc  = shape64();
  endtask

  initial begin
    int bad;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    io_fire = 0;
    drive(); io_fire = 0;
    @(negedge clock);
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      // negedge：换激励；posedge 前比较上一拍打拍后的输出（组合输出随输入变，比的是当拍值）
      drive();
      #2;
      if (fired) begin
        compare_all();
        if (!io_fire) cov_hold++;
        if (io_isFixp && io_opcode_op >= 27 && io_opcode_op <= 32)
          cov_fixp_sew[io_opcode_op - 27][io_vdType[1:0]]++;
        cov_mode[io_isFixp][io_isMisc]++;
      end
      @(posedge clock);
      if (io_fire) fired = 1;
      @(negedge clock);
    end
    bad = 0;
    foreach (cov_mode[a, b]) begin
      $display("cov isFixp=%0d isMisc=%0d : %0d", a, b, cov_mode[a][b]);
      if (cov_mode[a][b] < NCYCLES / 100) bad++;
    end
    foreach (cov_fixp_sew[a, b]) begin
      $display("cov fixp op=%0d sew=%0d : %0d", a + 27, b, cov_fixp_sew[a][b]);
      if (cov_fixp_sew[a][b] < NCYCLES / 1000) bad++;
    end
    $display("cov hold(fire=0) : %0d", cov_hold);
    if (cov_hold < NCYCLES / 20) bad++;
    for (int o = 0; o < N_OUT; o++) if (!seen0[o] || !seen1[o]) begin bad++; $display("output %0d stuck", o); end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
