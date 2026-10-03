// =============================================================================
// tb —— slideupVs2VdTable / slidednVs2VdTable UT：golden 与重写件双例化，并对一个独立 oracle
// （照 Scala compute_vs2_vd 逐字翻成 SV 的行为函数）三方比对。纯组合。
// 激励：src 在 0..255 上按拍轮转（每 256 拍穷举一遍全部输入），共 NCYCLES 拍。
// 覆盖（写进 PASS 判据）：4 个 lmul × 表内每个 uopIdx 至少命中 1 次，另穷举表外输入（全 0 输出）。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;

  logic [7:0] src;
  logic [2:0] gu_vs2, gu_vd, iu_vs2, iu_vd, gd_vs2, gd_vd, id_vs2, id_vd;
  logic       gd_first, id_first;

  slideupVs2VdTable    u_gu (.src(src), .outOffsetVs2(gu_vs2), .outOffsetVd(gu_vd));
  slideupVs2VdTable_xs u_iu (.src(src), .outOffsetVs2(iu_vs2), .outOffsetVd(iu_vd));
  slidednVs2VdTable    u_gd (.src(src), .outOffsetVs2(gd_vs2), .outOffsetVd(gd_vd), .outIsFirst(gd_first));
  slidednVs2VdTable_xs u_id (.src(src), .outOffsetVs2(id_vs2), .outOffsetVd(id_vd), .outIsFirst(id_first));

  // 独立 oracle：Scala compute_vs2_vd（带 return 的首个匹配）
  function automatic logic [5:0] up_oracle(int lm, int uop);
    for (int i = 0; i < lm; i++) begin
      int prev = i * (i + 1) / 2;
      for (int j = 0; j < i + 1; j++) if (uop == prev + j) return {3'(i - j), 3'(i)};
    end
    return 6'd0;
  endfunction
  function automatic logic [6:0] dn_oracle(int lm, int uop);
    for (int i = 0; i < lm; i++) begin
      int prev = lm * i - i * (i - 1) / 2;
      for (int j = 0; j < lm - i; j++)
        if (uop == prev + lm - i - j - 1) return {(j == lm - i - 1), 3'(j), 3'(i)};
    end
    return 7'd0;
  endfunction

  `define CMP(g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 40) $display("[%0d] MISMATCH %s src=%h exp=%h got=%h", c, nm, src, (g), (i)); \
    end end

  initial begin
    int hit [4][64];
    int c;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    foreach (hit[a, b]) hit[a][b] = 0;
    for (c = 0; c < NCYCLES; c++) begin
      logic [5:0] uo; logic [6:0] dno;
      src = 8'(c);
      #1;
      uo  = up_oracle(1 << src[7:6], src[5:0]);
      dno = dn_oracle(1 << src[7:6], src[5:0]);
      `CMP({gu_vs2, gu_vd}, {iu_vs2, iu_vd}, "up golden/impl")
      `CMP(uo, {gu_vs2, gu_vd}, "up oracle/golden")
      `CMP({gd_first, gd_vs2, gd_vd}, {id_first, id_vs2, id_vd}, "dn golden/impl")
      `CMP(dno, {gd_first, gd_vs2, gd_vd}, "dn oracle/golden")
      hit[src[7:6]][src[5:0]]++;
      #1;
    end
    begin
      int bad = 0;
      for (int l = 0; l < 4; l++) for (int u = 0; u < 64; u++) if (hit[l][u] == 0) bad++;
      $display("--- coverage: 256 src values each hit >= %0d times", hit[3][63]);
      $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
      if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
      else $display("TEST FAILED");
    end
    $finish;
  end
endmodule
