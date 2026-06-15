// SplittedSRAMTemplate_2 UT：golden vs _xs（均例化 golden 内层 SRAMTemplate_36）。
// 测 FTB 条目 dataSplit=8（每路 80 位切成 8×10），精确位打包/拼回 + 8 套 bore 路由。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 40000;
  int unsigned WARMUP  = 400;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  logic        r_valid, w_valid;
  logic [8:0]  r_setIdx, w_setIdx;
  logic [3:0]  waymask;
  // 每路 FTB 条目字段（4 路）
  logic        isCall[4],isRet[4],isJalr[4],e_valid[4];
  logic [3:0]  br_off[4]; logic br_sh[4],br_v[4]; logic [11:0] br_lo[4]; logic [1:0] br_ts[4];
  logic [3:0]  tl_off[4]; logic tl_sh[4],tl_v[4]; logic [19:0] tl_lo[4]; logic [1:0] tl_ts[4];
  logic [3:0]  pft[4]; logic carry[4],lastrvi[4],sb0[4],sb1[4]; logic [19:0] tag[4];
  // 8 套 bore
  logic [9:0]  ba[8],bar[8]; logic [39:0] bwd[8]; logic [3:0] bwm[8];
  logic        bre[8],bwe[8],back[8],bsel[8];

  wire        g_ready, i_ready;
  // 读输出（4 路）：用一个聚合向量逐路比对
  wire        g_isCall[4],g_isRet[4],g_isJalr[4],g_evalid[4];
  wire [3:0]  g_broff[4]; wire g_brsh[4],g_brv[4]; wire [11:0] g_brlo[4]; wire [1:0] g_brts[4];
  wire [3:0]  g_tloff[4]; wire g_tlsh[4],g_tlv[4]; wire [19:0] g_tllo[4]; wire [1:0] g_tlts[4];
  wire [3:0]  g_pft[4]; wire g_carry[4],g_lastrvi[4],g_sb0[4],g_sb1[4]; wire [19:0] g_tag[4];
  wire        i_isCall[4],i_isRet[4],i_isJalr[4],i_evalid[4];
  wire [3:0]  i_broff[4]; wire i_brsh[4],i_brv[4]; wire [11:0] i_brlo[4]; wire [1:0] i_brts[4];
  wire [3:0]  i_tloff[4]; wire i_tlsh[4],i_tlv[4]; wire [19:0] i_tllo[4]; wire [1:0] i_tlts[4];
  wire [3:0]  i_pft[4]; wire i_carry[4],i_lastrvi[4],i_sb0[4],i_sb1[4]; wire [19:0] i_tag[4];
  wire [39:0] g_brd[8], i_brd[8];

  `define WAYW(N) \
    .io_w_req_bits_data_``N``_entry_isCall(isCall[N]), .io_w_req_bits_data_``N``_entry_isRet(isRet[N]), \
    .io_w_req_bits_data_``N``_entry_isJalr(isJalr[N]), .io_w_req_bits_data_``N``_entry_valid(e_valid[N]), \
    .io_w_req_bits_data_``N``_entry_brSlots_0_offset(br_off[N]), .io_w_req_bits_data_``N``_entry_brSlots_0_sharing(br_sh[N]), \
    .io_w_req_bits_data_``N``_entry_brSlots_0_valid(br_v[N]), .io_w_req_bits_data_``N``_entry_brSlots_0_lower(br_lo[N]), \
    .io_w_req_bits_data_``N``_entry_brSlots_0_tarStat(br_ts[N]), \
    .io_w_req_bits_data_``N``_entry_tailSlot_offset(tl_off[N]), .io_w_req_bits_data_``N``_entry_tailSlot_sharing(tl_sh[N]), \
    .io_w_req_bits_data_``N``_entry_tailSlot_valid(tl_v[N]), .io_w_req_bits_data_``N``_entry_tailSlot_lower(tl_lo[N]), \
    .io_w_req_bits_data_``N``_entry_tailSlot_tarStat(tl_ts[N]), \
    .io_w_req_bits_data_``N``_entry_pftAddr(pft[N]), .io_w_req_bits_data_``N``_entry_carry(carry[N]), \
    .io_w_req_bits_data_``N``_entry_last_may_be_rvi_call(lastrvi[N]), \
    .io_w_req_bits_data_``N``_entry_strong_bias_0(sb0[N]), .io_w_req_bits_data_``N``_entry_strong_bias_1(sb1[N]), \
    .io_w_req_bits_data_``N``_tag(tag[N])
  `define WAYR(N,P) \
    .io_r_resp_data_``N``_entry_isCall(P``isCall[N]), .io_r_resp_data_``N``_entry_isRet(P``isRet[N]), \
    .io_r_resp_data_``N``_entry_isJalr(P``isJalr[N]), .io_r_resp_data_``N``_entry_valid(P``evalid[N]), \
    .io_r_resp_data_``N``_entry_brSlots_0_offset(P``broff[N]), .io_r_resp_data_``N``_entry_brSlots_0_sharing(P``brsh[N]), \
    .io_r_resp_data_``N``_entry_brSlots_0_valid(P``brv[N]), .io_r_resp_data_``N``_entry_brSlots_0_lower(P``brlo[N]), \
    .io_r_resp_data_``N``_entry_brSlots_0_tarStat(P``brts[N]), \
    .io_r_resp_data_``N``_entry_tailSlot_offset(P``tloff[N]), .io_r_resp_data_``N``_entry_tailSlot_sharing(P``tlsh[N]), \
    .io_r_resp_data_``N``_entry_tailSlot_valid(P``tlv[N]), .io_r_resp_data_``N``_entry_tailSlot_lower(P``tllo[N]), \
    .io_r_resp_data_``N``_entry_tailSlot_tarStat(P``tlts[N]), \
    .io_r_resp_data_``N``_entry_pftAddr(P``pft[N]), .io_r_resp_data_``N``_entry_carry(P``carry[N]), \
    .io_r_resp_data_``N``_entry_last_may_be_rvi_call(P``lastrvi[N]), \
    .io_r_resp_data_``N``_entry_strong_bias_0(P``sb0[N]), .io_r_resp_data_``N``_entry_strong_bias_1(P``sb1[N]), \
    .io_r_resp_data_``N``_tag(P``tag[N])
  `define BORE(S,IDX,BRD) \
    .boreChildrenBd_bore``S``_addr(ba[IDX]), .boreChildrenBd_bore``S``_addr_rd(bar[IDX]), \
    .boreChildrenBd_bore``S``_wdata(bwd[IDX]), .boreChildrenBd_bore``S``_wmask(bwm[IDX]), \
    .boreChildrenBd_bore``S``_re(bre[IDX]), .boreChildrenBd_bore``S``_we(bwe[IDX]), \
    .boreChildrenBd_bore``S``_rdata(BRD[IDX]), .boreChildrenBd_bore``S``_ack(back[IDX]), \
    .boreChildrenBd_bore``S``_selectedOH(bsel[IDX]), .boreChildrenBd_bore``S``_array(6'h0)
  `define BC(N) \
    .sigFromSrams_bore``N``_ram_hold(1'b0), .sigFromSrams_bore``N``_ram_bypass(1'b0), \
    .sigFromSrams_bore``N``_ram_bp_clken(1'b0), .sigFromSrams_bore``N``_ram_aux_clk(1'b0), \
    .sigFromSrams_bore``N``_ram_aux_ckbp(1'b0), .sigFromSrams_bore``N``_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore``N``_cgen(1'b0)

  `define PORTS(RDY,P,BRD) \
    .clock(clk), .reset(rst), \
    .io_r_req_ready(RDY), .io_r_req_valid(r_valid), .io_r_req_bits_setIdx(r_setIdx), \
    `WAYR(0,P), `WAYR(1,P), `WAYR(2,P), `WAYR(3,P), \
    .io_w_req_valid(w_valid), .io_w_req_bits_setIdx(w_setIdx), \
    `WAYW(0), `WAYW(1), `WAYW(2), `WAYW(3), \
    .io_w_req_bits_waymask(waymask), \
    `BORE(,0,BRD), `BORE(_1,1,BRD), `BORE(_2,2,BRD), `BORE(_3,3,BRD), \
    `BORE(_4,4,BRD), `BORE(_5,5,BRD), `BORE(_6,6,BRD), `BORE(_7,7,BRD), \
    `BC(), `BC(_1), `BC(_2), `BC(_3), `BC(_4), `BC(_5), `BC(_6), `BC(_7)

  SplittedSRAMTemplate_2    u_g (`PORTS(g_ready,g_,g_brd));
  SplittedSRAMTemplate_2_xs u_i (`PORTS(i_ready,i_,i_brd));

  int k;
  always @(negedge clk) begin
    if (rst) begin
      r_valid<=0; w_valid<=0;
      for (k=0;k<8;k++) begin back[k]<=0; bre[k]<=0; bwe[k]<=0; end
    end else begin
      r_valid <= ($urandom_range(0,3)!=0);
      w_valid <= ($urandom_range(0,2)==0);
      r_setIdx<= 9'($urandom); w_setIdx<= 9'($urandom); waymask<=4'($urandom);
      for (k=0;k<4;k++) begin
        isCall[k]<=$urandom; isRet[k]<=$urandom; isJalr[k]<=$urandom; e_valid[k]<=$urandom;
        br_off[k]<=4'($urandom); br_sh[k]<=$urandom; br_v[k]<=$urandom;
        br_lo[k]<=12'($urandom); br_ts[k]<=2'($urandom);
        tl_off[k]<=4'($urandom); tl_sh[k]<=$urandom; tl_v[k]<=$urandom;
        tl_lo[k]<=20'($urandom); tl_ts[k]<=2'($urandom);
        pft[k]<=4'($urandom); carry[k]<=$urandom; lastrvi[k]<=$urandom;
        sb0[k]<=$urandom; sb1[k]<=$urandom; tag[k]<=20'($urandom);
      end
      for (k=0;k<8;k++) begin
        back[k]<=($urandom_range(0,7)==0); bre[k]<=$urandom; bwe[k]<=$urandom;
        ba[k]<=10'($urandom); bar[k]<=10'($urandom); bwd[k]<=40'($urandom);
        bwm[k]<=4'($urandom); bsel[k]<=$urandom;
      end
    end
  end

  int j;
  always @(negedge clk) if (!rst && cycle>WARMUP) begin
    #4; checks++;
    if (g_ready!==i_ready) begin errors++; $display("[%0t] ready mismatch",$time); end
    for (j=0;j<4;j++)
      if ({g_isCall[j],g_isRet[j],g_isJalr[j],g_evalid[j],g_broff[j],g_brsh[j],g_brv[j],g_brlo[j],g_brts[j],
           g_tloff[j],g_tlsh[j],g_tlv[j],g_tllo[j],g_tlts[j],g_pft[j],g_carry[j],g_lastrvi[j],g_sb0[j],g_sb1[j],g_tag[j]} !==
          {i_isCall[j],i_isRet[j],i_isJalr[j],i_evalid[j],i_broff[j],i_brsh[j],i_brv[j],i_brlo[j],i_brts[j],
           i_tloff[j],i_tlsh[j],i_tlv[j],i_tllo[j],i_tlts[j],i_pft[j],i_carry[j],i_lastrvi[j],i_sb0[j],i_sb1[j],i_tag[j]})
        begin errors++; if(errors<=20) $display("[%0t] rdata way%0d mismatch",$time,j); end
    for (j=0;j<8;j++)
      if (g_brd[j]!==i_brd[j]) begin errors++; if(errors<=20) $display("[%0t] bore%0d_rd mismatch",$time,j); end
  end

  initial begin
    rst=1; repeat(5) @(posedge clk); rst=0;
    repeat(NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors==0 && checks>1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
