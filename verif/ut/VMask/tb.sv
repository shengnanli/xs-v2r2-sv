// =============================================================================
// tb —— VMask UT：golden VMask 与重写件 VMask_xs 双例化，同激励逐拍比 io_out_vd。
//
// 激励：每拍 in_valid 约 75%；opcode 八成取本单元的 7 个编码、两成任意 6 位值；
//   vdType 全随机（SEW = 低 2 位）；uopIdx 七成 0..15、三成任意；vl 按
//   "0..16 / 0..128 / 0..255"三档；vstart 六成 0、四成任意；vm/ma/ta 随机；
//   vs2 / v0 按"全随机 / 稀疏 / 稠密 / 全 0 / 全 1 / 单个 1"六种形状轮换
//   （vfirst/vmsbf 需要大量"第一个 1 落在各处"与"根本没有 1"）。
// 开头 4 拍复位；复位撤掉后第 2 拍起每拍比较（fire_reg_s1 不复位，第 1 拍可能不定）。
// 覆盖（写进 PASS 判据，按 fire 的 uop 计）：7 opcode × 4 SEW 每格 >= 1000；
//   以及 vstart>=vl / vfirst 无 1 / viota·vid 奇偶 uop / ma / ta 各分支 >= 1000。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;

  logic         clock = 0, reset = 1;
  logic         valid;
  logic [5:0]   op, uop_idx;
  logic         vm, ma, ta;
  logic [7:0]   vl;
  logic [6:0]   vstart;
  logic [3:0]   vd_type;
  logic [127:0] vs1, vs2, old_vd, mask;
  logic [127:0] g_vd, i_vd;

  VMask u_g (
    .clock(clock), .reset(reset), .io_in_valid(valid), .io_in_bits_opcode_op(op),
    .io_in_bits_info_vm(vm), .io_in_bits_info_ma(ma), .io_in_bits_info_ta(ta),
    .io_in_bits_info_vl(vl), .io_in_bits_info_vstart(vstart), .io_in_bits_info_uopIdx(uop_idx),
    .io_in_bits_vdType(vd_type), .io_in_bits_vs1(vs1), .io_in_bits_vs2(vs2),
    .io_in_bits_old_vd(old_vd), .io_in_bits_mask(mask), .io_out_vd(g_vd));
  VMask_xs u_i (
    .clock(clock), .reset(reset), .io_in_valid(valid), .io_in_bits_opcode_op(op),
    .io_in_bits_info_vm(vm), .io_in_bits_info_ma(ma), .io_in_bits_info_ta(ta),
    .io_in_bits_info_vl(vl), .io_in_bits_info_vstart(vstart), .io_in_bits_info_uopIdx(uop_idx),
    .io_in_bits_vdType(vd_type), .io_in_bits_vs1(vs1), .io_in_bits_vs2(vs2),
    .io_in_bits_old_vd(old_vd), .io_in_bits_mask(mask), .io_out_vd(i_vd));

  localparam int NOPS = 7;
  logic [5:0] OPS [NOPS] = '{6'd39, 6'd40, 6'd41, 6'd42, 6'd43, 6'd44, 6'd45};
  string NAMES [NOPS] = '{"vcpop", "vfirst", "vmsbf", "vmsif", "vmsof", "viota", "vid"};
  int cov [NOPS][4];
  int cov_vstart_ge_vl, cov_vfirst_none, cov_uop_odd, cov_uop_even, cov_ma, cov_ta;

  function automatic logic [127:0] shape();
    logic [127:0] x;
    x = {$urandom, $urandom, $urandom, $urandom};
    case ($urandom_range(0, 5))
      0: return x;
      1: return x & {$urandom, $urandom, $urandom, $urandom} & {$urandom, $urandom, $urandom, $urandom}
                  & {$urandom, $urandom, $urandom, $urandom};
      2: return x | {$urandom, $urandom, $urandom, $urandom};
      3: return '0;
      4: return '1;
      default: return 128'(1) << $urandom_range(0, 127);
    endcase
  endfunction

  task automatic drive();
    valid   = ($urandom_range(0, 3) != 0);
    op      = ($urandom_range(0, 4) == 0) ? 6'($urandom) : OPS[$urandom_range(0, NOPS - 1)];
    vm      = $urandom; ma = $urandom; ta = $urandom;
    vd_type = $urandom;
    uop_idx = ($urandom_range(0, 9) < 7) ? 6'($urandom_range(0, 15)) : 6'($urandom);
    case ($urandom_range(0, 2))
      0: vl = $urandom_range(0, 16);
      1: vl = $urandom_range(0, 128);
      default: vl = $urandom;
    endcase
    vstart  = ($urandom_range(0, 9) < 6) ? 7'd0 : 7'($urandom);
    vs1     = {$urandom, $urandom, $urandom, $urandom};
    vs2     = shape();
    mask    = shape();
    old_vd  = {$urandom, $urandom, $urandom, $urandom};
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    foreach (cov[a, b]) cov[a][b] = 0;
    {cov_vstart_ge_vl, cov_vfirst_none, cov_uop_odd, cov_uop_even, cov_ma, cov_ta} = '0;
    drive();
    reset = 1;
    repeat (4) begin #5 clock = 1; #5 clock = 0; end
    reset = 0;
    for (int c = 0; c < NCYCLES; c++) begin
      drive();
      // 覆盖统计（按本拍 fire 的 uop）
      if (valid) begin
        logic [127:0] vs2m;
        for (int j = 0; j < NOPS; j++) if (op == OPS[j]) begin
          cov[j][vd_type[1:0]]++;
          if (j >= 5) begin if (uop_idx[0]) cov_uop_odd++; else cov_uop_even++; end
          if (j >= 2) begin if (ma) cov_ma++; if (ta) cov_ta++; end
        end
        if ({1'b0, vstart} >= vl && op inside {[6'd41:6'd45]}) cov_vstart_ge_vl++;
        for (int b = 0; b < 128; b++) vs2m[b] = vs2[b] & (mask[b] | vm) & (b < vl);
        if (op == 6'd40 && vs2m == 0) cov_vfirst_none++;
      end
      #5 clock = 1;
      #4;
      if (c >= 1) begin
        checks++;
        if (g_vd !== i_vd) begin
          errors++;
          if (errors <= 40) $display("[%0d] MISMATCH vd golden=%h impl=%h", c, g_vd, i_vd);
        end
      end
      #1 clock = 0;
    end
    begin
      int bad, minc;
      bad = 0; minc = 1 << 30;
      foreach (cov[a, b]) begin
        if (cov[a][b] < minc) minc = cov[a][b];
        if (cov[a][b] < 1000) bad++;
      end
      if (cov_vstart_ge_vl < 1000 || cov_vfirst_none < 1000 || cov_uop_odd < 1000 ||
          cov_uop_even < 1000 || cov_ma < 1000 || cov_ta < 1000) bad++;
      $display("--- coverage: op x sew min=%0d", minc);
      for (int a = 0; a < NOPS; a++)
        $display("    %-7s sew8=%0d sew16=%0d sew32=%0d sew64=%0d", NAMES[a], cov[a][0], cov[a][1], cov[a][2], cov[a][3]);
      $display("    vstart>=vl=%0d vfirst_none=%0d iota/vid odd=%0d even=%0d ma=%0d ta=%0d",
               cov_vstart_ge_vl, cov_vfirst_none, cov_uop_odd, cov_uop_even, cov_ma, cov_ta);
      $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
      if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
      else $display("TEST FAILED");
    end
    $finish;
  end
endmodule
