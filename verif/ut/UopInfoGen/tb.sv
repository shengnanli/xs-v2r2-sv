// =============================================================================
// tb —— UopInfoGen UT:golden UopInfoGen (u_g) vs 可读核 UopInfoGen_xs (u_i)。
// 纯组合:每拍随机驱动 PreInfo,组合稳定后逐输出比对(isComplex/numOfUop/
//   numOfWB/lmul)。激励:typeOfSplit 大概率取"合法 split 码表"(覆盖全部 47 种),
//   vsew/vlmul/vwidth/nf/vmvn 全随机,isVlsr/isVlsm/isVecArith… 随机。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic        isVecArith, isVecMem, isAmoCAS, isVlsr, isVlsm;
  logic [5:0]  typeOfSplit;
  logic [1:0]  vsew;
  logic [2:0]  vlmul, vwidth, nf, vmvn;

  logic        g_cplx, i_cplx;
  logic [6:0]  g_nu, i_nu, g_nwb, i_nwb;
  logic [3:0]  g_lmul, i_lmul;

  UopInfoGen u_g (
    .io_in_preInfo_isVecArith(isVecArith), .io_in_preInfo_isVecMem(isVecMem),
    .io_in_preInfo_isAmoCAS(isAmoCAS), .io_in_preInfo_typeOfSplit(typeOfSplit),
    .io_in_preInfo_vsew(vsew), .io_in_preInfo_vlmul(vlmul), .io_in_preInfo_vwidth(vwidth),
    .io_in_preInfo_nf(nf), .io_in_preInfo_vmvn(vmvn),
    .io_in_preInfo_isVlsr(isVlsr), .io_in_preInfo_isVlsm(isVlsm),
    .io_out_isComplex(g_cplx), .io_out_uopInfo_numOfUop(g_nu),
    .io_out_uopInfo_numOfWB(g_nwb), .io_out_uopInfo_lmul(g_lmul)
  );
  UopInfoGen_xs u_i (
    .io_in_preInfo_isVecArith(isVecArith), .io_in_preInfo_isVecMem(isVecMem),
    .io_in_preInfo_isAmoCAS(isAmoCAS), .io_in_preInfo_typeOfSplit(typeOfSplit),
    .io_in_preInfo_vsew(vsew), .io_in_preInfo_vlmul(vlmul), .io_in_preInfo_vwidth(vwidth),
    .io_in_preInfo_nf(nf), .io_in_preInfo_vmvn(vmvn),
    .io_in_preInfo_isVlsr(isVlsr), .io_in_preInfo_isVlsm(isVlsm),
    .io_out_isComplex(i_cplx), .io_out_uopInfo_numOfUop(i_nu),
    .io_out_uopInfo_numOfWB(i_nwb), .io_out_uopInfo_lmul(i_lmul)
  );

  // 合法 split 码表(与 UopSplitType 一致)。
  localparam int NSP = 47;
  logic [5:0] SPLITS [NSP] = '{
    6'h00,6'h04,6'h11,6'h12,6'h13,6'h14,6'h15,6'h16,6'h17,6'h18,6'h19,6'h1A,
    6'h1B,6'h1C,6'h1D,6'h1E,6'h1F,6'h20,6'h21,6'h22,6'h23,6'h24,6'h25,6'h27,
    6'h29,6'h2A,6'h2C,6'h2D,6'h2E,6'h2F,6'h30,6'h31,6'h32,6'h33,6'h34,6'h35,
    6'h36,6'h37,6'h38,6'h39,6'h3A,6'h3B,6'h3C,6'h3D,6'h02,6'h0A,6'h3F
  };

  task automatic drive();
    int pick = $urandom_range(0, 99);
    if (pick < 92) typeOfSplit = SPLITS[$urandom_range(0, NSP-1)];
    else           typeOfSplit = $urandom;       // 偶尔随机 split 码
    isVecArith = $urandom; isVecMem = $urandom; isAmoCAS = $urandom;
    isVlsr = $urandom; isVlsm = $urandom;
    vsew   = $urandom; vlmul = $urandom; vwidth = $urandom;
    nf     = $urandom; vmvn  = $urandom;
  endtask

  `define CK(g,i,nm) \
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \
      if (errors<=80) $display("[%0t] %s g=%h i=%h (split=%h vsew=%h vlmul=%h vwidth=%h nf=%h vlsr=%b vlsm=%b)", \
        $time, nm, g, i, typeOfSplit, vsew, vlmul, vwidth, nf, isVlsr, isVlsm); end \
    checks++;

  task automatic check();
    `CK(g_cplx, i_cplx, "isComplex")
    `CK(g_nu,   i_nu,   "numOfUop")
    `CK(g_nwb,  i_nwb,  "numOfWB")
    `CK(g_lmul, i_lmul, "lmul")
  endtask

  initial begin
    drive();
    repeat (NCYCLES) begin
      @(posedge clk);
      #1 check();
      drive();
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
