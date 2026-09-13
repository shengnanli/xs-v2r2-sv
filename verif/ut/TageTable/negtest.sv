// 负测台：证明 xs_TageTable_core 的折叠历史位数不变式会在 **elaborate 期** 拦下。
//
// 对照原型 = TageTable_1（HIST_LEN=13；golden 三个 folded_hist 端口分别是
// io_req_bits_folded_hist_hist_1(11 位) / _4(8 位) / _15(7 位)）。两个负例：
//   +define+NEG_TT_HIST      HIST_LEN 13→5 —— 几何历史长度抄错。三份折叠历史的
//        位数是 min(HIST_LEN, …) 派生出来的，抄错后 idx 折叠历史变 5 位，
//        而 golden 端口是 11 位；逻辑一行不改，位宽却已经错了。
//        期望命中「idx 折叠历史 min(HIST_LEN=5, IDX_W=11)=5 位, 但 golden 端口是 11 位」。
//   +define+NEG_TT_NO_ANCHOR 不传 G1_*_FH_W —— 期望命中 fail-closed 那条。
//
// 端口全部悬空：本负测只考验 elaborate 期的参数自检，不跑功能。
// 判据：两个都必须让 VCS 在 elaborate 期非零退出（Error-[FEST]）。
module neg_tt_probe;
`ifdef NEG_TT_HIST
  localparam int unsigned HL = 5;    // <-- 抄错：golden 这张表是 13 拍历史
`else
  localparam int unsigned HL = 13;
`endif

  xs_TageTable_core #(
    .HIST_LEN(HL)
`ifndef NEG_TT_NO_ANCHOR
    , .G1_IDX_FH_W(11), .G1_TAG_FH_W(8), .G1_ALT_FH_W(7)
`endif
  ) u_core ();

  initial begin
    $display("NEGTEST_UNREACHED: 折叠历史位数抄错没有被 elaborate 期不变式拦下");
    $finish;
  end
endmodule
