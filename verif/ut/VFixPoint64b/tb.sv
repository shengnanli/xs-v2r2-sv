// =============================================================================
// tb —— VFixPoint64b UT：golden VFixPoint64b（含 golden Adder_chain_rnd）与重写件 VFixPoint64b_xs
// （含重写 Adder_chain_rnd_xs）双例化，同激励逐拍比全部输出（vd / narrowVd / vxsat）。纯组合。
//
// 激励：opcode 八成取定点六个编码（vsadd 27 / vssub 28 / vaadd 29 / vasub 30 / vssrl 31 / vssra 32）、
//   两成任意 6 位；sew_oneHot 九成 one-hot、一成任意 4 位（含非 one-hot，golden 各项相或）；
//   vxrm 均匀四种；isSub/isSigned/isNClip 随机；fromAdder 的 vd 按 全随机/全 0/全 1/0x7F|0x80 边界 四种形状，
//   cout/vs2H/vs1H 随机；fromMisc 的 shiftOut 同四种形状，rnd_high/rnd_tail 随机。
// 覆盖（写进 PASS 判据）：6 编码 × 4 vxrm 每格 >= 500；4 种 one-hot sew × isNClip 每格 >= 500；
//   vxsat 非零拍 >= 1000；每个输出位都见过 0 和 1。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;
  int cyc;

  // ---- 以下声明/例化/比较由 golden 端口表机械展开（41 输入 / 3 输出）----
  logic [5:0] io_opcode_op;
  logic [1:0] io_info_vxrm;
  logic [3:0] io_sew_oneHot;
  logic io_isSub;
  logic io_isSigned;
  logic io_isNClip;
  logic io_fromAdder_cout_0;
  logic io_fromAdder_cout_1;
  logic io_fromAdder_cout_2;
  logic io_fromAdder_cout_3;
  logic io_fromAdder_cout_4;
  logic io_fromAdder_cout_5;
  logic io_fromAdder_cout_6;
  logic io_fromAdder_cout_7;
  logic [7:0] io_fromAdder_vd_0;
  logic [7:0] io_fromAdder_vd_1;
  logic [7:0] io_fromAdder_vd_2;
  logic [7:0] io_fromAdder_vd_3;
  logic [7:0] io_fromAdder_vd_4;
  logic [7:0] io_fromAdder_vd_5;
  logic [7:0] io_fromAdder_vd_6;
  logic [7:0] io_fromAdder_vd_7;
  logic io_fromAdder_vs2H_0;
  logic io_fromAdder_vs2H_1;
  logic io_fromAdder_vs2H_2;
  logic io_fromAdder_vs2H_3;
  logic io_fromAdder_vs2H_4;
  logic io_fromAdder_vs2H_5;
  logic io_fromAdder_vs2H_6;
  logic io_fromAdder_vs2H_7;
  logic io_fromAdder_vs1H_0;
  logic io_fromAdder_vs1H_1;
  logic io_fromAdder_vs1H_2;
  logic io_fromAdder_vs1H_3;
  logic io_fromAdder_vs1H_4;
  logic io_fromAdder_vs1H_5;
  logic io_fromAdder_vs1H_6;
  logic io_fromAdder_vs1H_7;
  logic [63:0] io_fromMisc_shiftOut;
  logic [7:0] io_fromMisc_rnd_high;
  logic [7:0] io_fromMisc_rnd_tail;
  logic [63:0] g_io_vd, i_io_vd;
  logic [31:0] g_io_narrowVd, i_io_narrowVd;
  logic [7:0] g_io_vxsat, i_io_vxsat;
  VFixPoint64b u_g (
    .io_opcode_op(io_opcode_op),
    .io_info_vxrm(io_info_vxrm),
    .io_sew_oneHot(io_sew_oneHot),
    .io_isSub(io_isSub),
    .io_isSigned(io_isSigned),
    .io_isNClip(io_isNClip),
    .io_fromAdder_cout_0(io_fromAdder_cout_0),
    .io_fromAdder_cout_1(io_fromAdder_cout_1),
    .io_fromAdder_cout_2(io_fromAdder_cout_2),
    .io_fromAdder_cout_3(io_fromAdder_cout_3),
    .io_fromAdder_cout_4(io_fromAdder_cout_4),
    .io_fromAdder_cout_5(io_fromAdder_cout_5),
    .io_fromAdder_cout_6(io_fromAdder_cout_6),
    .io_fromAdder_cout_7(io_fromAdder_cout_7),
    .io_fromAdder_vd_0(io_fromAdder_vd_0),
    .io_fromAdder_vd_1(io_fromAdder_vd_1),
    .io_fromAdder_vd_2(io_fromAdder_vd_2),
    .io_fromAdder_vd_3(io_fromAdder_vd_3),
    .io_fromAdder_vd_4(io_fromAdder_vd_4),
    .io_fromAdder_vd_5(io_fromAdder_vd_5),
    .io_fromAdder_vd_6(io_fromAdder_vd_6),
    .io_fromAdder_vd_7(io_fromAdder_vd_7),
    .io_fromAdder_vs2H_0(io_fromAdder_vs2H_0),
    .io_fromAdder_vs2H_1(io_fromAdder_vs2H_1),
    .io_fromAdder_vs2H_2(io_fromAdder_vs2H_2),
    .io_fromAdder_vs2H_3(io_fromAdder_vs2H_3),
    .io_fromAdder_vs2H_4(io_fromAdder_vs2H_4),
    .io_fromAdder_vs2H_5(io_fromAdder_vs2H_5),
    .io_fromAdder_vs2H_6(io_fromAdder_vs2H_6),
    .io_fromAdder_vs2H_7(io_fromAdder_vs2H_7),
    .io_fromAdder_vs1H_0(io_fromAdder_vs1H_0),
    .io_fromAdder_vs1H_1(io_fromAdder_vs1H_1),
    .io_fromAdder_vs1H_2(io_fromAdder_vs1H_2),
    .io_fromAdder_vs1H_3(io_fromAdder_vs1H_3),
    .io_fromAdder_vs1H_4(io_fromAdder_vs1H_4),
    .io_fromAdder_vs1H_5(io_fromAdder_vs1H_5),
    .io_fromAdder_vs1H_6(io_fromAdder_vs1H_6),
    .io_fromAdder_vs1H_7(io_fromAdder_vs1H_7),
    .io_fromMisc_shiftOut(io_fromMisc_shiftOut),
    .io_fromMisc_rnd_high(io_fromMisc_rnd_high),
    .io_fromMisc_rnd_tail(io_fromMisc_rnd_tail),
    .io_vd(g_io_vd),
    .io_narrowVd(g_io_narrowVd),
    .io_vxsat(g_io_vxsat)
  );
  VFixPoint64b_xs u_i (
    .io_opcode_op(io_opcode_op),
    .io_info_vxrm(io_info_vxrm),
    .io_sew_oneHot(io_sew_oneHot),
    .io_isSub(io_isSub),
    .io_isSigned(io_isSigned),
    .io_isNClip(io_isNClip),
    .io_fromAdder_cout_0(io_fromAdder_cout_0),
    .io_fromAdder_cout_1(io_fromAdder_cout_1),
    .io_fromAdder_cout_2(io_fromAdder_cout_2),
    .io_fromAdder_cout_3(io_fromAdder_cout_3),
    .io_fromAdder_cout_4(io_fromAdder_cout_4),
    .io_fromAdder_cout_5(io_fromAdder_cout_5),
    .io_fromAdder_cout_6(io_fromAdder_cout_6),
    .io_fromAdder_cout_7(io_fromAdder_cout_7),
    .io_fromAdder_vd_0(io_fromAdder_vd_0),
    .io_fromAdder_vd_1(io_fromAdder_vd_1),
    .io_fromAdder_vd_2(io_fromAdder_vd_2),
    .io_fromAdder_vd_3(io_fromAdder_vd_3),
    .io_fromAdder_vd_4(io_fromAdder_vd_4),
    .io_fromAdder_vd_5(io_fromAdder_vd_5),
    .io_fromAdder_vd_6(io_fromAdder_vd_6),
    .io_fromAdder_vd_7(io_fromAdder_vd_7),
    .io_fromAdder_vs2H_0(io_fromAdder_vs2H_0),
    .io_fromAdder_vs2H_1(io_fromAdder_vs2H_1),
    .io_fromAdder_vs2H_2(io_fromAdder_vs2H_2),
    .io_fromAdder_vs2H_3(io_fromAdder_vs2H_3),
    .io_fromAdder_vs2H_4(io_fromAdder_vs2H_4),
    .io_fromAdder_vs2H_5(io_fromAdder_vs2H_5),
    .io_fromAdder_vs2H_6(io_fromAdder_vs2H_6),
    .io_fromAdder_vs2H_7(io_fromAdder_vs2H_7),
    .io_fromAdder_vs1H_0(io_fromAdder_vs1H_0),
    .io_fromAdder_vs1H_1(io_fromAdder_vs1H_1),
    .io_fromAdder_vs1H_2(io_fromAdder_vs1H_2),
    .io_fromAdder_vs1H_3(io_fromAdder_vs1H_3),
    .io_fromAdder_vs1H_4(io_fromAdder_vs1H_4),
    .io_fromAdder_vs1H_5(io_fromAdder_vs1H_5),
    .io_fromAdder_vs1H_6(io_fromAdder_vs1H_6),
    .io_fromAdder_vs1H_7(io_fromAdder_vs1H_7),
    .io_fromMisc_shiftOut(io_fromMisc_shiftOut),
    .io_fromMisc_rnd_high(io_fromMisc_rnd_high),
    .io_fromMisc_rnd_tail(io_fromMisc_rnd_tail),
    .io_vd(i_io_vd),
    .io_narrowVd(i_io_narrowVd),
    .io_vxsat(i_io_vxsat)
  );
  localparam int N_OUT = 3;
  bit seen0 [N_OUT];  // 该输出出现过"某位为 0"
  bit seen1 [N_OUT];  // 该输出出现过"某位为 1"
  `define CMP(k, g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      if (|(g)) seen1[k] = 1; if (!(&(g))) seen0[k] = 1; end
  task automatic compare_all();
    `CMP(0, g_io_vd, i_io_vd, "io_vd")
    `CMP(1, g_io_narrowVd, i_io_narrowVd, "io_narrowVd")
    `CMP(2, g_io_vxsat, i_io_vxsat, "io_vxsat")
  endtask
  task automatic rand_inputs();
    io_opcode_op = 6'($urandom);
    io_info_vxrm = 2'($urandom);
    io_sew_oneHot = 4'($urandom);
    io_isSub = 1'($urandom);
    io_isSigned = 1'($urandom);
    io_isNClip = 1'($urandom);
    io_fromAdder_cout_0 = 1'($urandom);
    io_fromAdder_cout_1 = 1'($urandom);
    io_fromAdder_cout_2 = 1'($urandom);
    io_fromAdder_cout_3 = 1'($urandom);
    io_fromAdder_cout_4 = 1'($urandom);
    io_fromAdder_cout_5 = 1'($urandom);
    io_fromAdder_cout_6 = 1'($urandom);
    io_fromAdder_cout_7 = 1'($urandom);
    io_fromAdder_vd_0 = 8'($urandom);
    io_fromAdder_vd_1 = 8'($urandom);
    io_fromAdder_vd_2 = 8'($urandom);
    io_fromAdder_vd_3 = 8'($urandom);
    io_fromAdder_vd_4 = 8'($urandom);
    io_fromAdder_vd_5 = 8'($urandom);
    io_fromAdder_vd_6 = 8'($urandom);
    io_fromAdder_vd_7 = 8'($urandom);
    io_fromAdder_vs2H_0 = 1'($urandom);
    io_fromAdder_vs2H_1 = 1'($urandom);
    io_fromAdder_vs2H_2 = 1'($urandom);
    io_fromAdder_vs2H_3 = 1'($urandom);
    io_fromAdder_vs2H_4 = 1'($urandom);
    io_fromAdder_vs2H_5 = 1'($urandom);
    io_fromAdder_vs2H_6 = 1'($urandom);
    io_fromAdder_vs2H_7 = 1'($urandom);
    io_fromAdder_vs1H_0 = 1'($urandom);
    io_fromAdder_vs1H_1 = 1'($urandom);
    io_fromAdder_vs1H_2 = 1'($urandom);
    io_fromAdder_vs1H_3 = 1'($urandom);
    io_fromAdder_vs1H_4 = 1'($urandom);
    io_fromAdder_vs1H_5 = 1'($urandom);
    io_fromAdder_vs1H_6 = 1'($urandom);
    io_fromAdder_vs1H_7 = 1'($urandom);
    io_fromMisc_shiftOut = 64'({$urandom, $urandom});
    io_fromMisc_rnd_high = 8'($urandom);
    io_fromMisc_rnd_tail = 8'($urandom);
  endtask

  int cov_op_rm [6][4];
  int cov_sew_nclip [4][2];
  int cov_vxsat;

  function automatic logic [63:0] shape64();
    logic [63:0] x;
    x = {$urandom, $urandom};
    case ($urandom_range(0, 3))
      0: return x;
      1: return '0;
      2: return '1;
      default: begin
        for (int b = 0; b < 8; b++) x[b*8 +: 8] = $urandom_range(0, 1) ? 8'h7F : 8'h80;
        return x;
      end
    endcase
  endfunction

  initial begin
    int bad, k;
    logic [63:0] av;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      rand_inputs();
      if ($urandom_range(0, 4) != 0) io_opcode_op = 6'($urandom_range(27, 32));
      if ($urandom_range(0, 9) != 0) io_sew_oneHot = 4'b1 << $urandom_range(0, 3);
      av = shape64();
      {io_fromAdder_vd_7, io_fromAdder_vd_6, io_fromAdder_vd_5, io_fromAdder_vd_4,
       io_fromAdder_vd_3, io_fromAdder_vd_2, io_fromAdder_vd_1, io_fromAdder_vd_0} = av;
      io_fromMisc_shiftOut = shape64();
      #1;
      compare_all();
      if (io_opcode_op >= 27 && io_opcode_op <= 32) cov_op_rm[io_opcode_op - 27][io_info_vxrm]++;
      if ($onehot(io_sew_oneHot)) begin
        k = 0; for (int b = 0; b < 4; b++) if (io_sew_oneHot[b]) k = b;
        cov_sew_nclip[k][io_isNClip]++;
      end
      if (|g_io_vxsat) cov_vxsat++;
      #1;
    end
    bad = 0;
    foreach (cov_op_rm[a, b]) begin
      $display("cov op=%0d vxrm=%0d : %0d", a + 27, b, cov_op_rm[a][b]);
      if (cov_op_rm[a][b] < NCYCLES / 400) bad++;
    end
    foreach (cov_sew_nclip[a, b]) begin
      $display("cov sew=%0d nclip=%0d : %0d", 8 << a, b, cov_sew_nclip[a][b]);
      if (cov_sew_nclip[a][b] < NCYCLES / 400) bad++;
    end
    $display("cov vxsat!=0 : %0d", cov_vxsat);
    if (cov_vxsat < NCYCLES / 200) bad++;
    for (int o = 0; o < N_OUT; o++) if (!seen0[o] || !seen1[o]) begin bad++; $display("output %0d stuck", o); end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
