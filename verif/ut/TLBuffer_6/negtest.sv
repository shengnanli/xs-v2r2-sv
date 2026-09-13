// 负测台：证明 xs_TLBuffer_ad_core 的载荷位数等式不变式会在 **elaborate 期** 拦下。
//
// 对照原型 = TLBuffer_6（golden Queue2_TLBundleA_6 里是 ram_2x356、
// Queue2_TLBundleD_7 里是 ram_2x281）。两个负例：
//   +define+NEG_TLB_SOURCE     SOURCE_W 4→2，即 G0->G1 那次真实事故（source id 加宽
//        没跟上）。逻辑一行不改, 随机激励也未必打到高位。
//        期望命中「A 通道载荷 354 位 != golden ram_2x356」。
//   +define+NEG_TLB_NO_ANCHOR  不传 A_RAM_WIDTH/D_RAM_WIDTH —— 改造前默认值是
//        356/281（TLBuffer_6 自己的数），等于"不传即拿别人的值当真"，是 fail-open；
//        现在期望命中 fail-closed 那条。
//
// 判据：两个都必须让 VCS 在 elaborate 期非零退出（Error-[FEST]）。
module neg_tlb_probe;
`ifdef NEG_TLB_SOURCE
  localparam int unsigned SRC_W = 2;   // <-- 抄错：golden 是 4 位 source
`else
  localparam int unsigned SRC_W = 4;
`endif
  localparam int unsigned A_SZ = 3, D_SZ = 3, ADDR = 48, MASK = 32, DATA = 256,
                          SINK = 10, USER = 5;

  // 端口全部悬空：本负测只考验 elaborate 期的参数自检，不跑功能。
  xs_TLBuffer_ad_core #(
    .A_SIZE_W(A_SZ), .D_SIZE_W(D_SZ), .SOURCE_W(SRC_W), .ADDR_W(ADDR),
    .MASK_W(MASK), .DATA_W(DATA), .D_SINK_W(SINK), .A_USER_W(USER)
`ifndef NEG_TLB_NO_ANCHOR
    , .A_RAM_WIDTH(356), .D_RAM_WIDTH(281)
`endif
  ) u_core ();

  initial begin
    $display("NEGTEST_UNREACHED: 载荷位数抄错没有被 elaborate 期不变式拦下");
    $finish;
  end
endmodule
