// =============================================================================
// tb —— Permutation UT：golden Permutation（含 golden slide*Vs2VdTable）与重写件 Permutation_xs
// （含重写 slide*Vs2VdTable_xs）双例化，同激励逐拍比 io_out_vd。
//
// 激励：每拍 in_valid 约 75%；opcode 八成五取本单元 8 个编码、其余任意 6 位值；
//   vs2 的 SEW（srcType0 低 2 位）随机；vrgather 有一半按 ei16+SEW8（srcType1=1、srcType0=0）出；
//   vlmul 0..7 全取（含保留值 4 与分数 LMUL）；uopIdx 七成 0..15、两成 0..42、一成任意；
//   vl 分 "0..16 / 0..128 / 0..255" 三档；vstart 六成 0；vs1 按 "全随机 / 每字节小下标 /
//   低 64 位小滑动量" 轮换（gather 下标与 slide 量要大量落在有效区间附近）；v0 六种形状。
// 不复位寄存器（reg1 一组、reg0 的不复位一组）在 +random 档初值不同：开头 4 拍复位后再空跑 4 拍
//   fire=0 不比较（此时 io_out_vd 取决于 reg1 的未初始化值），之后每拍比较。
//   ★仍然可能遇到"首次 fire 之前 reg1 未写过"的窗口★：tb 在第一次 fire 之后再过 3 拍才开始比较。
// 覆盖（写进 PASS 判据，按 fire 的 uop 计）：8 opcode × 4 SEW 每格 >= 1000；vrgather16_sew8 >= 1000；
//   slide 类在 8 个 vlmul 上各 >= 300；vcompress 计数 uop >= 300；vstart>=vl >= 1000。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;

  logic         clock = 0, reset = 1;
  logic         valid;
  logic [5:0]   op, uop_idx;
  logic         vm, ma, ta;
  logic [2:0]   vlmul;
  logic [7:0]   vl;
  logic [6:0]   vstart;
  logic [3:0]   st0, st1;
  logic [127:0] vs1, vs2, old_vd, mask;
  logic [127:0] g_vd, i_vd;

  Permutation u_g (
    .clock(clock), .reset(reset), .io_in_valid(valid), .io_in_bits_opcode_op(op),
    .io_in_bits_info_vm(vm), .io_in_bits_info_ma(ma), .io_in_bits_info_ta(ta),
    .io_in_bits_info_vlmul(vlmul), .io_in_bits_info_vl(vl), .io_in_bits_info_vstart(vstart),
    .io_in_bits_info_uopIdx(uop_idx), .io_in_bits_srcType_0(st0), .io_in_bits_srcType_1(st1),
    .io_in_bits_vs1(vs1), .io_in_bits_vs2(vs2), .io_in_bits_old_vd(old_vd),
    .io_in_bits_mask(mask), .io_out_vd(g_vd));
  Permutation_xs u_i (
    .clock(clock), .reset(reset), .io_in_valid(valid), .io_in_bits_opcode_op(op),
    .io_in_bits_info_vm(vm), .io_in_bits_info_ma(ma), .io_in_bits_info_ta(ta),
    .io_in_bits_info_vlmul(vlmul), .io_in_bits_info_vl(vl), .io_in_bits_info_vstart(vstart),
    .io_in_bits_info_uopIdx(uop_idx), .io_in_bits_srcType_0(st0), .io_in_bits_srcType_1(st1),
    .io_in_bits_vs1(vs1), .io_in_bits_vs2(vs2), .io_in_bits_old_vd(old_vd),
    .io_in_bits_mask(mask), .io_out_vd(i_vd));

  localparam int NOPS = 8;
  string NAMES [NOPS] = '{"vslideup", "vslidedn", "vslide1up", "vslide1dn", "vrgather", "vrgather_vx", "vcompress", "vmvnr"};
  int cov [NOPS][4];
  int cov_rg16, cov_slide_lmul [8], cov_cmprs_cnt, cov_vstart_ge_vl;

  function automatic logic [127:0] rnd128();
    return {$urandom, $urandom, $urandom, $urandom};
  endfunction
  function automatic logic [127:0] shape();
    case ($urandom_range(0, 5))
      0: return rnd128();
      1: return rnd128() & rnd128() & rnd128();
      2: return rnd128() | rnd128();
      3: return '0;
      4: return '1;
      default: return 128'(1) << $urandom_range(0, 127);
    endcase
  endfunction

  task automatic drive();
    valid  = ($urandom_range(0, 3) != 0);
    op     = ($urandom_range(0, 19) < 17) ? 6'($urandom_range(0, 7)) : 6'($urandom);
    vm = $urandom; ma = $urandom; ta = $urandom;
    st0    = $urandom;
    st1    = ($urandom_range(0, 1)) ? {2'($urandom), st0[1:0]} : 4'($urandom);
    if (op == 6'd4 && $urandom_range(0, 1)) begin st0 = 4'd0; st1 = 4'd1; end
    vlmul  = $urandom;
    case ($urandom_range(0, 9))
      0, 1, 2, 3, 4, 5, 6: uop_idx = $urandom_range(0, 15);
      7, 8: uop_idx = $urandom_range(0, 42);
      default: uop_idx = $urandom;
    endcase
    case ($urandom_range(0, 2))
      0: vl = $urandom_range(0, 16);
      1: vl = $urandom_range(0, 128);
      default: vl = $urandom;
    endcase
    vstart = ($urandom_range(0, 9) < 6) ? 7'd0 : 7'($urandom);
    case ($urandom_range(0, 2))
      0: vs1 = rnd128();
      1: begin
        vs1 = rnd128();
        for (int b = 0; b < 16; b++) if ($urandom_range(0, 3) != 0) vs1[8*b +: 8] = $urandom_range(0, 63);
      end
      default: begin
        vs1 = rnd128();
        vs1[63:0] = ($urandom_range(0, 3) != 0) ? 64'($urandom_range(0, 40)) : {$urandom, $urandom};
      end
    endcase
    vs2    = rnd128();
    old_vd = rnd128();
    mask   = shape();
  endtask

  initial begin
    int fires = 0;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    foreach (cov[a, b]) cov[a][b] = 0;
    cov_rg16 = 0; cov_cmprs_cnt = 0; cov_vstart_ge_vl = 0;
    foreach (cov_slide_lmul[a]) cov_slide_lmul[a] = 0;
    drive();
    reset = 1;
    repeat (4) begin #5 clock = 1; #5 clock = 0; end
    reset = 0;
    for (int c = 0; c < NCYCLES; c++) begin
      drive();
      if (valid) begin
        fires++;
        if (op < 8) begin
          cov[op][st0[1:0]]++;
          if (op <= 3) cov_slide_lmul[vlmul]++;
          if (op == 6'd6 && uop_idx inside {1, 4, 8, 13, 19, 26, 34}) cov_cmprs_cnt++;
          if ({1'b0, vstart} >= vl) cov_vstart_ge_vl++;
        end
        if (op == 6'd4 && st0 == 4'd0 && st1 == 4'd1) cov_rg16++;
      end
      #5 clock = 1;
      #4;
      // 第一次 fire 之后 3 拍 reg1 才全部写过（reg1 不复位）
      if (fires > 0 && c >= 3 + first_fire_cycle()) begin
        checks++;
        if (g_vd !== i_vd) begin
          errors++;
          if (errors <= 40) $display("[%0d] MISMATCH vd golden=%h impl=%h", c, g_vd, i_vd);
        end
      end
      #1 clock = 0;
    end
    begin
      int bad, minc, mins;
      bad = 0; minc = 1 << 30; mins = 1 << 30;
      foreach (cov[a, b]) begin
        if (cov[a][b] < minc) minc = cov[a][b];
        if (cov[a][b] < 1000) bad++;
      end
      foreach (cov_slide_lmul[a]) begin
        if (cov_slide_lmul[a] < mins) mins = cov_slide_lmul[a];
        if (cov_slide_lmul[a] < 300) bad++;
      end
      if (cov_rg16 < 1000 || cov_cmprs_cnt < 300 || cov_vstart_ge_vl < 1000) bad++;
      $display("--- coverage: op x sew min=%0d", minc);
      for (int a = 0; a < NOPS; a++)
        $display("    %-11s sew8=%0d sew16=%0d sew32=%0d sew64=%0d", NAMES[a], cov[a][0], cov[a][1], cov[a][2], cov[a][3]);
      $display("    vrgather16_sew8=%0d slide x vlmul min=%0d vcompress count-uop=%0d vstart>=vl=%0d",
               cov_rg16, mins, cov_cmprs_cnt, cov_vstart_ge_vl);
      $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
      if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
      else $display("TEST FAILED");
    end
    $finish;
  end

  // 记录第一次 fire 的拍号
  int ffc = -1;
  int cyc = 0;
  always @(posedge clock) begin
    if (!reset) begin
      if (ffc < 0 && valid) ffc = cyc;
      cyc++;
    end
  end
  function automatic int first_fire_cycle();
    return (ffc < 0) ? 1 << 30 : ffc;
  endfunction
endmodule
