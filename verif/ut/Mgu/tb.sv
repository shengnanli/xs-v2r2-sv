// =============================================================================
// tb —— Mgu UT：golden Mgu（含 golden ByteMaskTailGen 子树）与重写件 Mgu_xs（含重写子树）
// 双例化，同激励逐拍比全部输出（vd 128 位 + active 16 位）。纯组合，每拍一组新输入。
//
// 激励：
//   eew 均匀四种；vdIdx 0~7 均匀；narrow 1/4；dstMask 1/3；ta/ma 随机；
//   vstart 一半为 0、一半 0~255 随机；vl 一半在 [0, 元素数] 内（元素数 = 128>>(3+eew) 按 8 组算）、
//   一半任意 8 位（含超过 vlmax 的非法值，golden 照样有确定输出）；
//   mask / vd / oldVd 按 全随机 / 全 0 / 全 1 / 稀疏 四种形状轮换。
// 覆盖（写进 PASS 判据）：eew × dstMask × narrow 16 格每格 >= 1000；
//   active 字节数 0 / 1~15 / 16 三桶各 >= 1000；每个输出位都见过 0 和 1。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;
  int cyc;

  // ---- 以下声明/例化/比较由 golden 端口表机械展开（11 输入 / 2 输出）----
  logic [127:0] io_in_vd;
  logic [127:0] io_in_oldVd;
  logic [127:0] io_in_mask;
  logic io_in_info_ta;
  logic io_in_info_ma;
  logic [7:0] io_in_info_vl;
  logic [7:0] io_in_info_vstart;
  logic [1:0] io_in_info_eew;
  logic [2:0] io_in_info_vdIdx;
  logic io_in_info_narrow;
  logic io_in_info_dstMask;
  logic [127:0] g_io_out_vd, i_io_out_vd;
  logic [15:0] g_io_out_active, i_io_out_active;
  Mgu u_g (
    .io_in_vd(io_in_vd),
    .io_in_oldVd(io_in_oldVd),
    .io_in_mask(io_in_mask),
    .io_in_info_ta(io_in_info_ta),
    .io_in_info_ma(io_in_info_ma),
    .io_in_info_vl(io_in_info_vl),
    .io_in_info_vstart(io_in_info_vstart),
    .io_in_info_eew(io_in_info_eew),
    .io_in_info_vdIdx(io_in_info_vdIdx),
    .io_in_info_narrow(io_in_info_narrow),
    .io_in_info_dstMask(io_in_info_dstMask),
    .io_out_vd(g_io_out_vd),
    .io_out_active(g_io_out_active)
  );
  Mgu_xs u_i (
    .io_in_vd(io_in_vd),
    .io_in_oldVd(io_in_oldVd),
    .io_in_mask(io_in_mask),
    .io_in_info_ta(io_in_info_ta),
    .io_in_info_ma(io_in_info_ma),
    .io_in_info_vl(io_in_info_vl),
    .io_in_info_vstart(io_in_info_vstart),
    .io_in_info_eew(io_in_info_eew),
    .io_in_info_vdIdx(io_in_info_vdIdx),
    .io_in_info_narrow(io_in_info_narrow),
    .io_in_info_dstMask(io_in_info_dstMask),
    .io_out_vd(i_io_out_vd),
    .io_out_active(i_io_out_active)
  );
  localparam int N_OUT = 2;
  bit seen0 [N_OUT];  // 该输出出现过"某位为 0"
  bit seen1 [N_OUT];  // 该输出出现过"某位为 1"
  `define CMP(k, g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      if (|(g)) seen1[k] = 1; if (!(&(g))) seen0[k] = 1; end
  task automatic compare_all();
    `CMP(0, g_io_out_vd, i_io_out_vd, "io_out_vd")
    `CMP(1, g_io_out_active, i_io_out_active, "io_out_active")
  endtask
  task automatic rand_inputs();
    io_in_vd = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_oldVd = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_mask = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_info_ta = 1'($urandom);
    io_in_info_ma = 1'($urandom);
    io_in_info_vl = 8'($urandom);
    io_in_info_vstart = 8'($urandom);
    io_in_info_eew = 2'($urandom);
    io_in_info_vdIdx = 3'($urandom);
    io_in_info_narrow = 1'($urandom);
    io_in_info_dstMask = 1'($urandom);
  endtask

  int cov_mode [4][2][2];      // [eew][dstMask][narrow]
  int cov_active [3];          // active 字节数 0 / 部分 / 全部

  function automatic logic [127:0] shape128();
    logic [127:0] x;
    x = {$urandom, $urandom, $urandom, $urandom};
    case ($urandom_range(0, 3))
      0: return x;
      1: return '0;
      2: return '1;
      default: return x & {$urandom, $urandom, $urandom, $urandom};
    endcase
  endfunction

  initial begin
    int bad, nact;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      rand_inputs();
      io_in_vd    = shape128();
      io_in_oldVd = shape128();
      io_in_mask  = shape128();
      io_in_info_narrow  = ($urandom_range(0, 3) == 0);
      io_in_info_dstMask = ($urandom_range(0, 2) == 0);
      if ($urandom_range(0, 1)) io_in_info_vstart = 8'd0;
      if ($urandom_range(0, 1)) io_in_info_vl = 8'($urandom_range(0, 128 >> io_in_info_eew));
      #1;
      compare_all();
      cov_mode[io_in_info_eew][io_in_info_dstMask][io_in_info_narrow]++;
      nact = $countones(g_io_out_active);
      cov_active[(nact == 0) ? 0 : (nact == 16) ? 2 : 1]++;
      #1;
    end
    bad = 0;
    foreach (cov_mode[a, b, c]) begin
      $display("cov eew=%0d dstMask=%0d narrow=%0d : %0d", a, b, c, cov_mode[a][b][c]);
      if (cov_mode[a][b][c] < NCYCLES / 200) bad++;
    end
    $display("cov active none/part/all : %0d / %0d / %0d", cov_active[0], cov_active[1], cov_active[2]);
    foreach (cov_active[a]) if (cov_active[a] < NCYCLES / 200) bad++;
    for (int o = 0; o < N_OUT; o++) if (!seen0[o] || !seen1[o]) begin bad++; $display("output %0d stuck", o); end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
