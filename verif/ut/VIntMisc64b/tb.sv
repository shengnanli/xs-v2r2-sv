// =============================================================================
// tb —— VIntMisc64b UT：golden VIntMisc64b（含 golden CLZ 子模块）与重写件 VIntMisc64b_xs
// （含重写 CLZ_*_xs）双例化，同激励逐拍比全部 5 个输出。纯组合，每拍一组新输入。
//
// 激励：opcode 八成取本单元负责的 26 个编码、两成任意 6 位值（含其他单元的编码与非法值）；
//   vdType/srcType 全随机（含 SEW 组合不合法的情形，golden 照样有确定输出）；
//   vs1/vs2 按"全随机 / 稀疏 / 稠密 / 全 0 / 全 1 / 单字节非零"六种形状轮换
//   （计数类指令需要大量前导零/尾随零）；uopIdx/vm/vmask/narrow 随机。
// 覆盖（写进 PASS 判据）：26 个 opcode × 4 个目的 SEW 每格至少命中 50 次；
//   narrow=1 与移位组合、vf2/vf4/vf8 三种扩展、有/无符号各至少 50 次。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;

  logic [5:0]  op;
  logic        vm;
  logic [5:0]  uop_idx;
  logic [3:0]  src_type0, vd_type;
  logic [63:0] vs1, vs2;
  logic [7:0]  vmask;
  logic        narrow;
  logic [63:0] g_vd, i_vd, g_so, i_so;
  logic [31:0] g_nvd, i_nvd;
  logic [7:0]  g_rh, i_rh, g_rt, i_rt;

  VIntMisc64b u_g (
    .io_opcode_op(op), .io_info_vm(vm), .io_info_uopIdx(uop_idx), .io_srcType_0(src_type0),
    .io_vdType(vd_type), .io_vs1(vs1), .io_vs2(vs2), .io_vmask(vmask), .io_narrow(narrow),
    .io_vd(g_vd), .io_narrowVd(g_nvd), .io_toFixP_shiftOut(g_so),
    .io_toFixP_rnd_high(g_rh), .io_toFixP_rnd_tail(g_rt));
  VIntMisc64b_xs u_i (
    .io_opcode_op(op), .io_info_vm(vm), .io_info_uopIdx(uop_idx), .io_srcType_0(src_type0),
    .io_vdType(vd_type), .io_vs1(vs1), .io_vs2(vs2), .io_vmask(vmask), .io_narrow(narrow),
    .io_vd(i_vd), .io_narrowVd(i_nvd), .io_toFixP_shiftOut(i_so),
    .io_toFixP_rnd_high(i_rh), .io_toFixP_rnd_tail(i_rt));

  localparam int NOPS = 26;
  logic [5:0] OPS [NOPS] = '{6'd2, 6'd7, 6'd8, 6'd9, 6'd10, 6'd11, 6'd12, 6'd13, 6'd14, 6'd15,
                             6'd16, 6'd17, 6'd25, 6'd26, 6'd31, 6'd32, 6'd39, 6'd46, 6'd48,
                             6'd49, 6'd50, 6'd51, 6'd52, 6'd53, 6'd54, 6'd55};
  int cov [NOPS][4];
  int cov_narrow, cov_vf [3], cov_signed, cov_unsigned;

  `define CMP(g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 40) $display("[%0d] MISMATCH %s golden=%h impl=%h op=%0d vdT=%h s0=%h n=%b vs1=%h vs2=%h", \
                                 c, nm, (g), (i), op, vd_type, src_type0, narrow, vs1, vs2); \
    end end

  function automatic logic [63:0] shape();
    logic [63:0] x;
    x = {$urandom, $urandom};
    case ($urandom_range(0, 5))
      0: return x;
      1: return x & {$urandom, $urandom} & {$urandom, $urandom};
      2: return x | {$urandom, $urandom};
      3: return 64'h0;
      4: return '1;
      default: return 64'(8'($urandom)) << (8 * $urandom_range(0, 7));
    endcase
  endfunction

  initial begin
    int c, k;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    foreach (cov[a, b]) cov[a][b] = 0;
    cov_narrow = 0; cov_vf = '{0, 0, 0}; cov_signed = 0; cov_unsigned = 0;
    for (c = 0; c < NCYCLES; c++) begin
      k = $urandom_range(0, NOPS - 1);
      op        = ($urandom_range(0, 4) == 0) ? 6'($urandom) : OPS[k];
      vm        = $urandom;
      uop_idx   = $urandom;
      src_type0 = $urandom;
      vd_type   = $urandom;
      vs1       = shape();
      vs2       = shape();
      vmask     = $urandom;
      narrow    = ($urandom_range(0, 3) == 0);
      #1;
      `CMP(g_vd,  i_vd,  "vd")
      `CMP(g_nvd, i_nvd, "narrowVd")
      `CMP(g_so,  i_so,  "shiftOut")
      `CMP(g_rh,  i_rh,  "rnd_high")
      `CMP(g_rt,  i_rt,  "rnd_tail")
      for (int j = 0; j < NOPS; j++) if (op == OPS[j]) cov[j][vd_type[1:0]]++;
      if (narrow && op inside {6'd16, 6'd17, 6'd31, 6'd32}) cov_narrow++;
      if (op == 6'd2) begin
        case (2'(vd_type[1:0] - src_type0[1:0]))
          2'd1: cov_vf[0]++;
          2'd2: cov_vf[1]++;
          default: cov_vf[2]++;
        endcase
        if (src_type0[3:2] == 2'd1) cov_signed++; else cov_unsigned++;
      end
      #1;
    end
    begin
      int bad, minc;
      bad = 0; minc = 1 << 30;
      foreach (cov[a, b]) begin
        if (cov[a][b] < minc) minc = cov[a][b];
        if (cov[a][b] < 50) bad++;
      end
      if (cov_narrow < 50 || cov_vf[0] < 50 || cov_vf[1] < 50 || cov_vf[2] < 50 ||
          cov_signed < 50 || cov_unsigned < 50) bad++;
      $display("--- coverage: op x sew min=%0d narrow_shift=%0d vf2/4/8=%0d/%0d/%0d signed=%0d unsigned=%0d",
               minc, cov_narrow, cov_vf[0], cov_vf[1], cov_vf[2], cov_signed, cov_unsigned);
      $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
      if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
      else $display("TEST FAILED");
    end
    $finish;
  end
endmodule
