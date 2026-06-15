// =============================================================================
// SCTable UT testbench
//
// 对 4 个变体（SCTable / SCTable_1 / SCTable_2 / SCTable_3）各双例化 golden 与
// 可读重写 _xs，灌同一套随机激励，逐拍比对全部功能输出（4 个 io_resp_ctrs +
// boreChildrenBd_bore_ack/outdata）。
//
// 激励要点：
//   - io_req_valid 高概率拉高，pc 随机 → 充分覆盖各读索引（含历史折叠）。
//   - update 通道随机：mask/oldCtrs/tagePreds/takens/ghist 全随机，覆盖饱和边界、
//     way 选择、WrBypass 命中（连续更新同一 idx）。
//   - 偶尔定向连续命中同一 update_pc，制造 WrBypass 写后读冒险。
//   - MBIST(boreChildrenBd) 通道随机激励，覆盖 DFT 透传路径与 ack/outdata。
// =============================================================================
`timescale 1ns/1ps
module tb;
  localparam int NCYCLES = 60000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  // ---- 公共激励信号 ----
  logic        io_req_valid;
  logic [49:0] io_req_bits_pc;
  logic [3:0]  fh4;            // 变体1 折叠历史
  logic [7:0]  fh8_2, fh8_3;   // 变体2/3 折叠历史
  logic [49:0] io_update_pc;
  logic [255:0] io_update_ghist;
  logic        io_update_mask_0, io_update_mask_1;
  logic [5:0]  io_update_oldCtrs_0, io_update_oldCtrs_1;
  logic        io_update_tagePreds_0, io_update_tagePreds_1;
  logic        io_update_takens_0, io_update_takens_1;
  // MBIST
  logic [6:0]  bd_array;
  logic        bd_all, bd_req, bd_writeen, bd_readen;
  logic [3:0]  bd_be;
  logic [8:0]  bd_addr, bd_addr_rd;
  logic [23:0] bd_indata;
  logic        sig_hold, sig_bypass, sig_bp_clken, sig_aux_clk, sig_aux_ckbp, sig_mcp_hold, sig_cgen;

  // ---- 每个变体的输出（g_=golden, i_=_xs）----
  // verilog 宏：声明一个变体的全部输出对
  `define OUTS(P) \
    wire [5:0] g``P``_c00, i``P``_c00, g``P``_c01, i``P``_c01, g``P``_c10, i``P``_c10, g``P``_c11, i``P``_c11; \
    wire       g``P``_ack, i``P``_ack; \
    wire [23:0] g``P``_od, i``P``_od;
  `OUTS(0) `OUTS(1) `OUTS(2) `OUTS(3)

  // ---- 例化所有变体（golden 与 _xs 各一份）----
  // 变体 0：无折叠历史/ghist
  SCTable    u_g0 (.clock(clk), .reset(rst), .io_req_valid(io_req_valid), .io_req_bits_pc(io_req_bits_pc),
    .io_resp_ctrs_0_0(g0_c00), .io_resp_ctrs_0_1(g0_c01), .io_resp_ctrs_1_0(g0_c10), .io_resp_ctrs_1_1(g0_c11),
    .io_update_pc(io_update_pc), .io_update_mask_0(io_update_mask_0), .io_update_mask_1(io_update_mask_1),
    .io_update_oldCtrs_0(io_update_oldCtrs_0), .io_update_oldCtrs_1(io_update_oldCtrs_1),
    .io_update_tagePreds_0(io_update_tagePreds_0), .io_update_tagePreds_1(io_update_tagePreds_1),
    .io_update_takens_0(io_update_takens_0), .io_update_takens_1(io_update_takens_1),
    .boreChildrenBd_bore_array(bd_array), .boreChildrenBd_bore_all(bd_all), .boreChildrenBd_bore_req(bd_req),
    .boreChildrenBd_bore_ack(g0_ack), .boreChildrenBd_bore_writeen(bd_writeen), .boreChildrenBd_bore_be(bd_be),
    .boreChildrenBd_bore_addr(bd_addr), .boreChildrenBd_bore_indata(bd_indata), .boreChildrenBd_bore_readen(bd_readen),
    .boreChildrenBd_bore_addr_rd(bd_addr_rd), .boreChildrenBd_bore_outdata(g0_od),
    .sigFromSrams_bore_ram_hold(sig_hold), .sigFromSrams_bore_ram_bypass(sig_bypass), .sigFromSrams_bore_ram_bp_clken(sig_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sig_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(sig_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sig_mcp_hold), .sigFromSrams_bore_cgen(sig_cgen));
  SCTable_xs u_i0 (.clock(clk), .reset(rst), .io_req_valid(io_req_valid), .io_req_bits_pc(io_req_bits_pc),
    .io_resp_ctrs_0_0(i0_c00), .io_resp_ctrs_0_1(i0_c01), .io_resp_ctrs_1_0(i0_c10), .io_resp_ctrs_1_1(i0_c11),
    .io_update_pc(io_update_pc), .io_update_mask_0(io_update_mask_0), .io_update_mask_1(io_update_mask_1),
    .io_update_oldCtrs_0(io_update_oldCtrs_0), .io_update_oldCtrs_1(io_update_oldCtrs_1),
    .io_update_tagePreds_0(io_update_tagePreds_0), .io_update_tagePreds_1(io_update_tagePreds_1),
    .io_update_takens_0(io_update_takens_0), .io_update_takens_1(io_update_takens_1),
    .boreChildrenBd_bore_array(bd_array), .boreChildrenBd_bore_all(bd_all), .boreChildrenBd_bore_req(bd_req),
    .boreChildrenBd_bore_ack(i0_ack), .boreChildrenBd_bore_writeen(bd_writeen), .boreChildrenBd_bore_be(bd_be),
    .boreChildrenBd_bore_addr(bd_addr), .boreChildrenBd_bore_indata(bd_indata), .boreChildrenBd_bore_readen(bd_readen),
    .boreChildrenBd_bore_addr_rd(bd_addr_rd), .boreChildrenBd_bore_outdata(i0_od),
    .sigFromSrams_bore_ram_hold(sig_hold), .sigFromSrams_bore_ram_bypass(sig_bypass), .sigFromSrams_bore_ram_bp_clken(sig_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sig_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(sig_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sig_mcp_hold), .sigFromSrams_bore_cgen(sig_cgen));

  // 变体 1：4-bit 折叠历史 + ghist
  `define INST_H(MOD, INST, PFX, HP, HW) \
    MOD INST (.clock(clk), .reset(rst), .io_req_valid(io_req_valid), .io_req_bits_pc(io_req_bits_pc), \
      .HP, \
      .io_resp_ctrs_0_0(PFX``_c00), .io_resp_ctrs_0_1(PFX``_c01), .io_resp_ctrs_1_0(PFX``_c10), .io_resp_ctrs_1_1(PFX``_c11), \
      .io_update_pc(io_update_pc), .io_update_ghist(io_update_ghist), \
      .io_update_mask_0(io_update_mask_0), .io_update_mask_1(io_update_mask_1), \
      .io_update_oldCtrs_0(io_update_oldCtrs_0), .io_update_oldCtrs_1(io_update_oldCtrs_1), \
      .io_update_tagePreds_0(io_update_tagePreds_0), .io_update_tagePreds_1(io_update_tagePreds_1), \
      .io_update_takens_0(io_update_takens_0), .io_update_takens_1(io_update_takens_1), \
      .boreChildrenBd_bore_array(bd_array), .boreChildrenBd_bore_all(bd_all), .boreChildrenBd_bore_req(bd_req), \
      .boreChildrenBd_bore_ack(PFX``_ack), .boreChildrenBd_bore_writeen(bd_writeen), .boreChildrenBd_bore_be(bd_be), \
      .boreChildrenBd_bore_addr(bd_addr), .boreChildrenBd_bore_indata(bd_indata), .boreChildrenBd_bore_readen(bd_readen), \
      .boreChildrenBd_bore_addr_rd(bd_addr_rd), .boreChildrenBd_bore_outdata(PFX``_od), \
      .sigFromSrams_bore_ram_hold(sig_hold), .sigFromSrams_bore_ram_bypass(sig_bypass), .sigFromSrams_bore_ram_bp_clken(sig_bp_clken), \
      .sigFromSrams_bore_ram_aux_clk(sig_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(sig_aux_ckbp), \
      .sigFromSrams_bore_ram_mcp_hold(sig_mcp_hold), .sigFromSrams_bore_cgen(sig_cgen));

  `INST_H(SCTable_1,    u_g1, g1, io_req_bits_folded_hist_hist_12_folded_hist(fh4), 4)
  `INST_H(SCTable_1_xs, u_i1, i1, io_req_bits_folded_hist_hist_12_folded_hist(fh4), 4)
  `INST_H(SCTable_2,    u_g2, g2, io_req_bits_folded_hist_hist_11_folded_hist(fh8_2), 8)
  `INST_H(SCTable_2_xs, u_i2, i2, io_req_bits_folded_hist_hist_11_folded_hist(fh8_2), 8)
  `INST_H(SCTable_3,    u_g3, g3, io_req_bits_folded_hist_hist_2_folded_hist(fh8_3), 8)
  `INST_H(SCTable_3_xs, u_i3, i3, io_req_bits_folded_hist_hist_2_folded_hist(fh8_3), 8)

  // ---- 随机激励 ----
  logic [49:0] sticky_upd_pc;
  always @(negedge clk) begin
    if (rst) begin
      io_req_valid <= 0; io_req_bits_pc <= 0;
      fh4 <= 0; fh8_2 <= 0; fh8_3 <= 0;
      io_update_pc <= 0; io_update_ghist <= 0;
      io_update_mask_0 <= 0; io_update_mask_1 <= 0;
      io_update_oldCtrs_0 <= 0; io_update_oldCtrs_1 <= 0;
      io_update_tagePreds_0 <= 0; io_update_tagePreds_1 <= 0;
      io_update_takens_0 <= 0; io_update_takens_1 <= 0;
      bd_array <= 0; bd_all <= 0; bd_req <= 0; bd_writeen <= 0; bd_readen <= 0;
      bd_be <= 0; bd_addr <= 0; bd_addr_rd <= 0; bd_indata <= 0;
      sig_hold <= 0; sig_bypass <= 0; sig_bp_clken <= 0; sig_aux_clk <= 0;
      sig_aux_ckbp <= 0; sig_mcp_hold <= 0; sig_cgen <= 0;
      sticky_upd_pc <= 0;
    end else begin
      // 读/写互斥，避免 golden SRAM 的同址读写冲突断言（真实设计预测与提交不同拍）。
      // 写周期：req_valid=0；读周期：update_mask=0。
      automatic bit do_update = ($urandom_range(0,1) == 0);
      io_req_valid   <= ~do_update & ($urandom_range(0,9) != 0);
      io_req_bits_pc <= {$urandom, $urandom} & 50'h3FFFFFFFFFFFF;
      fh4   <= $urandom;
      fh8_2 <= $urandom;
      fh8_3 <= $urandom;

      // update：偶尔粘住同一 pc 制造 WrBypass 写后读
      if ($urandom_range(0,3) == 0) sticky_upd_pc <= {$urandom, $urandom} & 50'h3FFFFFFFFFFFF;
      io_update_pc   <= ($urandom_range(0,2)==0) ? sticky_upd_pc : ({$urandom,$urandom} & 50'h3FFFFFFFFFFFF);
      io_update_ghist <= {$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom};
      io_update_mask_0 <= do_update & ($urandom_range(0,2) != 0);
      io_update_mask_1 <= do_update & ($urandom_range(0,2) != 0);
      // oldCtrs 偏向饱和边界以覆盖封顶/封底
      io_update_oldCtrs_0 <= ($urandom_range(0,3)==0) ? (($urandom&1)?6'h1F:6'h20) : $urandom;
      io_update_oldCtrs_1 <= ($urandom_range(0,3)==0) ? (($urandom&1)?6'h1F:6'h20) : $urandom;
      io_update_tagePreds_0 <= $urandom;
      io_update_tagePreds_1 <= $urandom;
      io_update_takens_0 <= $urandom;
      io_update_takens_1 <= $urandom;

      bd_array <= ($urandom_range(0,2)==0) ? (7'h42 + ($urandom_range(0,3))) : $urandom;
      bd_all <= ($urandom_range(0,7)==0);
      bd_req <= $urandom;
      bd_writeen <= $urandom; bd_readen <= $urandom;
      bd_be <= $urandom; bd_addr <= $urandom; bd_addr_rd <= $urandom; bd_indata <= $urandom;
      sig_hold <= $urandom; sig_bypass <= $urandom; sig_bp_clken <= $urandom;
      sig_aux_clk <= $urandom; sig_aux_ckbp <= $urandom; sig_mcp_hold <= $urandom; sig_cgen <= $urandom;
    end
  end

  // ---- 逐拍比对 ----
  task automatic chk(input string nm, input logic [23:0] g, input logic [23:0] i);
    checks++;
    if (g !== i) begin errors++;
      if (errors <= 40) $display("[%0t] MISMATCH %s g=%h i=%h", $time, nm, g, i);
    end
  endtask

  always @(negedge clk) if (!rst) begin
    #2;
    chk("v0.c00", g0_c00, i0_c00); chk("v0.c01", g0_c01, i0_c01);
    chk("v0.c10", g0_c10, i0_c10); chk("v0.c11", g0_c11, i0_c11);
    chk("v0.ack", g0_ack, i0_ack); chk("v0.od",  g0_od,  i0_od);
    chk("v1.c00", g1_c00, i1_c00); chk("v1.c01", g1_c01, i1_c01);
    chk("v1.c10", g1_c10, i1_c10); chk("v1.c11", g1_c11, i1_c11);
    chk("v1.ack", g1_ack, i1_ack); chk("v1.od",  g1_od,  i1_od);
    chk("v2.c00", g2_c00, i2_c00); chk("v2.c01", g2_c01, i2_c01);
    chk("v2.c10", g2_c10, i2_c10); chk("v2.c11", g2_c11, i2_c11);
    chk("v2.ack", g2_ack, i2_ack); chk("v2.od",  g2_od,  i2_od);
    chk("v3.c00", g3_c00, i3_c00); chk("v3.c01", g3_c01, i3_c01);
    chk("v3.c10", g3_c10, i3_c10); chk("v3.c11", g3_c11, i3_c11);
    chk("v3.ack", g3_ack, i3_ack); chk("v3.od",  g3_od,  i3_od);
  end

  // ---- 主流程 ----
  initial begin
    rst = 1;
    repeat (6) @(negedge clk);
    rst = 0;
    repeat (NCYCLES) @(negedge clk);
    $display("=== SCTable UT done: checks=%0d errors=%0d ===", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
