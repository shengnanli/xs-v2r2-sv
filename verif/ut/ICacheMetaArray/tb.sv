// ICacheMetaArray UT：golden（firtool 版）vs ICacheMetaArray_xs（可读 wrapper + 核）。
// 二者各自例化同一批 golden tag SRAM 黑盒，故 tag/code 读出由 SRAM 决定、天然一致；
// 本 UT 着重比对：读端口路由、读响应 bank 选择、valid 触发器阵列（读/写/flush/flushAll）。
//
// 随机激励覆盖：读（含单/双 line、任意 vSetIdx 奇偶组合）、写（任意 way one-hot、bankIdx、
// poison）、两路 flush、flushAll，以及 Mbist 旁路总线随机翻转。
//
// X 处理：tag SRAM 在 +define+SYNTHESIS 下未写项读出 X，且两侧来自不同实例对象，
// 故对 tag/code 仅在 golden 非 X 时比对；valid/ready 一定确定，逐拍严格比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 600;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  int unsigned ev_set_cnt = 0;   // 观测到 entryValid=1 的次数（确认 valid 路径非平凡）
  int unsigned meta_chk_cnt = 0; // 实际比对了 tag（golden 非 X）的次数
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  // ---- 激励信号 ----
  logic        w_valid, r_valid, dbl, fa, f0_v, f1_v, poison, bankIdx;
  logic [7:0]  w_virIdx, vset0, vset1, f0_idx, f1_idx;
  logic [35:0] phyTag;
  logic [3:0]  w_waymask, f0_wm, f1_wm;
  // Mbist 旁路
  logic [1:0]  b_array, b_be;
  logic        b_all, b_req, b_we_en, b_re_en;
  logic [7:0]  b_addr, b_addr_rd;
  logic [73:0] b_indata;

  // ---- golden / impl 输出 ----
  wire        g_rdy, i_rdy;
  wire [35:0] g_m [2][4], i_m [2][4];
  wire        g_c [2][4], i_c [2][4];
  wire        g_ev[2][4], i_ev[2][4];
  wire        g_back, i_back;
  wire [73:0] g_bout, i_bout;

  `define PORTS(RDY,M,C,EV,BACK,BOUT) \
    .clock(clk), .reset(rst), \
    .io_write_valid(w_valid), .io_write_bits_virIdx(w_virIdx), \
    .io_write_bits_phyTag(phyTag), .io_write_bits_waymask(w_waymask), \
    .io_write_bits_bankIdx(bankIdx), .io_write_bits_poison(poison), \
    .io_read_ready(RDY), .io_read_valid(r_valid), \
    .io_read_bits_vSetIdx_0(vset0), .io_read_bits_vSetIdx_1(vset1), \
    .io_read_bits_isDoubleLine(dbl), \
    .io_readResp_metas_0_0_tag(M[0][0]), .io_readResp_metas_0_1_tag(M[0][1]), \
    .io_readResp_metas_0_2_tag(M[0][2]), .io_readResp_metas_0_3_tag(M[0][3]), \
    .io_readResp_metas_1_0_tag(M[1][0]), .io_readResp_metas_1_1_tag(M[1][1]), \
    .io_readResp_metas_1_2_tag(M[1][2]), .io_readResp_metas_1_3_tag(M[1][3]), \
    .io_readResp_codes_0_0(C[0][0]), .io_readResp_codes_0_1(C[0][1]), \
    .io_readResp_codes_0_2(C[0][2]), .io_readResp_codes_0_3(C[0][3]), \
    .io_readResp_codes_1_0(C[1][0]), .io_readResp_codes_1_1(C[1][1]), \
    .io_readResp_codes_1_2(C[1][2]), .io_readResp_codes_1_3(C[1][3]), \
    .io_readResp_entryValid_0_0(EV[0][0]), .io_readResp_entryValid_0_1(EV[0][1]), \
    .io_readResp_entryValid_0_2(EV[0][2]), .io_readResp_entryValid_0_3(EV[0][3]), \
    .io_readResp_entryValid_1_0(EV[1][0]), .io_readResp_entryValid_1_1(EV[1][1]), \
    .io_readResp_entryValid_1_2(EV[1][2]), .io_readResp_entryValid_1_3(EV[1][3]), \
    .io_flush_0_valid(f0_v), .io_flush_0_bits_virIdx(f0_idx), .io_flush_0_bits_waymask(f0_wm), \
    .io_flush_1_valid(f1_v), .io_flush_1_bits_virIdx(f1_idx), .io_flush_1_bits_waymask(f1_wm), \
    .io_flushAll(fa), \
    .boreChildrenBd_bore_array(b_array), .boreChildrenBd_bore_all(b_all), \
    .boreChildrenBd_bore_req(b_req), .boreChildrenBd_bore_ack(BACK), \
    .boreChildrenBd_bore_writeen(b_we_en), .boreChildrenBd_bore_be(b_be), \
    .boreChildrenBd_bore_addr(b_addr), .boreChildrenBd_bore_indata(b_indata), \
    .boreChildrenBd_bore_readen(b_re_en), .boreChildrenBd_bore_addr_rd(b_addr_rd), \
    .boreChildrenBd_bore_outdata(BOUT), \
    .sigFromSrams_bore_ram_hold(1'b0), .sigFromSrams_bore_ram_bypass(1'b0), \
    .sigFromSrams_bore_ram_bp_clken(1'b0), .sigFromSrams_bore_ram_aux_clk(1'b0), \
    .sigFromSrams_bore_ram_aux_ckbp(1'b0), .sigFromSrams_bore_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore_cgen(1'b0), \
    .sigFromSrams_bore_1_ram_hold(1'b0), .sigFromSrams_bore_1_ram_bypass(1'b0), \
    .sigFromSrams_bore_1_ram_bp_clken(1'b0), .sigFromSrams_bore_1_ram_aux_clk(1'b0), \
    .sigFromSrams_bore_1_ram_aux_ckbp(1'b0), .sigFromSrams_bore_1_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore_1_cgen(1'b0), \
    .sigFromSrams_bore_2_ram_hold(1'b0), .sigFromSrams_bore_2_ram_bypass(1'b0), \
    .sigFromSrams_bore_2_ram_bp_clken(1'b0), .sigFromSrams_bore_2_ram_aux_clk(1'b0), \
    .sigFromSrams_bore_2_ram_aux_ckbp(1'b0), .sigFromSrams_bore_2_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore_2_cgen(1'b0), \
    .sigFromSrams_bore_3_ram_hold(1'b0), .sigFromSrams_bore_3_ram_bypass(1'b0), \
    .sigFromSrams_bore_3_ram_bp_clken(1'b0), .sigFromSrams_bore_3_ram_aux_clk(1'b0), \
    .sigFromSrams_bore_3_ram_aux_ckbp(1'b0), .sigFromSrams_bore_3_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore_3_cgen(1'b0)

  ICacheMetaArray    u_g (`PORTS(g_rdy,g_m,g_c,g_ev,g_back,g_bout));
  ICacheMetaArray_xs u_i (`PORTS(i_rdy,i_m,i_c,i_ev,i_back,i_bout));

  // one-hot waymask 生成器（多数情况合法 one-hot，少量非法以测路号压缩一致性）
  function automatic logic [3:0] gen_waymask();
    int unsigned r = $urandom_range(0, 5);
    case (r)
      0: return 4'b0001; 1: return 4'b0010;
      2: return 4'b0100; 3: return 4'b1000;
      default: return 4'($urandom); // 非 one-hot：测压缩与 golden 一致
    endcase
  endfunction

  always @(negedge clk) begin
    if (rst) begin
      w_valid<=0; r_valid<=0; f0_v<=0; f1_v<=0; fa<=0;
      b_req<=0; b_we_en<=0; b_re_en<=0;
    end else begin
      // 读较频繁；写/flush 较稀疏；flushAll 很稀疏，避免常态清空
      r_valid <= ($urandom_range(0,3)!=0);
      w_valid <= ($urandom_range(0,2)==0);
      f0_v    <= ($urandom_range(0,7)==0);
      f1_v    <= ($urandom_range(0,7)==0);
      fa      <= ($urandom_range(0,200)==0);
      dbl     <= $urandom;
      poison  <= $urandom;
      bankIdx <= $urandom;
      vset0   <= 8'($urandom);
      vset1   <= 8'($urandom);
      w_virIdx<= 8'($urandom);
      phyTag  <= 36'($urandom);
      w_waymask<= gen_waymask();
      f0_idx  <= 8'($urandom); f1_idx <= 8'($urandom);
      f0_wm   <= 4'($urandom); f1_wm  <= 4'($urandom);
      // Mbist 旁路随机翻转（黑盒，两侧同子模块，主要测连通一致）
      b_array<=2'($urandom); b_all<=$urandom; b_req<=$urandom;
      b_we_en<=$urandom; b_re_en<=$urandom; b_be<=2'($urandom);
      b_addr<=8'($urandom); b_addr_rd<=8'($urandom); b_indata<=74'($urandom);
    end
  end

  // 逐拍比对（在数据稳定后采样）
  always @(negedge clk) if (!rst && cycle>WARMUP) begin
    #4; checks++;
    if (g_rdy!==i_rdy) begin errors++; if(errors<=30) $display("[%0t] ready mismatch g=%b i=%b",$time,g_rdy,i_rdy); end
    for (int p=0;p<2;p++) for (int w=0;w<4;w++) begin
      // valid 一定确定，严格比对
      if (g_ev[p][w]!==i_ev[p][w]) begin errors++; if(errors<=30) $display("[%0t] entryValid[%0d][%0d] g=%b i=%b",$time,p,w,g_ev[p][w],i_ev[p][w]); end
      if (g_ev[p][w]===1'b1) ev_set_cnt++;
      // tag/code：golden 非 X 时比对（未写 SRAM 项读 X）
      if (!$isunknown(g_m[p][w])) begin
        meta_chk_cnt++;
        if (g_m[p][w]!==i_m[p][w]) begin errors++; if(errors<=30) $display("[%0t] meta[%0d][%0d] g=%h i=%h",$time,p,w,g_m[p][w],i_m[p][w]); end
      end
      if (!$isunknown(g_c[p][w]) && g_c[p][w]!==i_c[p][w]) begin errors++; if(errors<=30) $display("[%0t] code[%0d][%0d] g=%b i=%b",$time,p,w,g_c[p][w],i_c[p][w]); end
    end
    // Mbist 旁路输出：golden 非 X 时比对
    if (g_back!==i_back && !$isunknown(g_back)) begin errors++; if(errors<=30) $display("[%0t] bore_ack mismatch",$time); end
    if (!$isunknown(g_bout) && g_bout!==i_bout) begin errors++; if(errors<=30) $display("[%0t] bore_out mismatch",$time); end
  end

  initial begin
    rst=1; repeat(8) @(posedge clk); rst=0;
    repeat(NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d entryValid1_observed=%0d tag_compared=%0d",
             checks, errors, ev_set_cnt, meta_chk_cnt);
    // 非平凡性门槛：必须真的见过 entryValid=1 且真的比对过非 X 的 tag
    if (errors==0 && checks>1000 && ev_set_cnt>100 && meta_chk_cnt>100)
      $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
