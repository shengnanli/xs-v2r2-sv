// 自动生成：scripts/gen_ittagetable_wrappers.py
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES=40000; localparam int WARMUP=4000;
  bit clk=0,rst; int errors=0,checks=0; int unsigned cycle=0;
  always #5 clk=~clk;  always @(posedge clk) cycle++;
  logic vT_io_req_valid;
  logic [49:0] vT_io_req_bits_pc;
  logic [3:0] vT_io_req_bits_folded_hist_hist_12_folded_hist;
  logic [49:0] vT_io_update_pc;
  logic [255:0] vT_io_update_ghist;
  logic vT_io_update_valid;
  logic vT_io_update_correct;
  logic vT_io_update_alloc;
  logic [1:0] vT_io_update_oldCtr;
  logic vT_io_update_uValid;
  logic vT_io_update_u;
  logic vT_io_update_reset_u;
  logic [19:0] vT_io_update_target_offset_offset;
  logic [3:0] vT_io_update_target_offset_pointer;
  logic vT_io_update_target_offset_usePCRegion;
  logic [19:0] vT_io_update_old_target_offset_offset;
  logic [3:0] vT_io_update_old_target_offset_pointer;
  logic vT_io_update_old_target_offset_usePCRegion;
  logic [6:0] vT_boreChildrenBd_bore_array;
  logic vT_boreChildrenBd_bore_all;
  logic vT_boreChildrenBd_bore_req;
  logic vT_boreChildrenBd_bore_writeen;
  logic [75:0] vT_boreChildrenBd_bore_be;
  logic [7:0] vT_boreChildrenBd_bore_addr;
  logic [75:0] vT_boreChildrenBd_bore_indata;
  logic vT_boreChildrenBd_bore_readen;
  logic [7:0] vT_boreChildrenBd_bore_addr_rd;
  logic vT_sigFromSrams_bore_ram_hold;
  logic vT_sigFromSrams_bore_ram_bypass;
  logic vT_sigFromSrams_bore_ram_bp_clken;
  logic vT_sigFromSrams_bore_ram_aux_clk;
  logic vT_sigFromSrams_bore_ram_aux_ckbp;
  logic vT_sigFromSrams_bore_ram_mcp_hold;
  logic vT_sigFromSrams_bore_cgen;
  wire vT_g_io_req_ready; wire vT_i_io_req_ready;
  wire vT_g_io_resp_valid; wire vT_i_io_resp_valid;
  wire [1:0] vT_g_io_resp_bits_ctr; wire [1:0] vT_i_io_resp_bits_ctr;
  wire vT_g_io_resp_bits_u; wire vT_i_io_resp_bits_u;
  wire [19:0] vT_g_io_resp_bits_target_offset_offset; wire [19:0] vT_i_io_resp_bits_target_offset_offset;
  wire [3:0] vT_g_io_resp_bits_target_offset_pointer; wire [3:0] vT_i_io_resp_bits_target_offset_pointer;
  wire vT_g_io_resp_bits_target_offset_usePCRegion; wire vT_i_io_resp_bits_target_offset_usePCRegion;
  wire vT_g_boreChildrenBd_bore_ack; wire vT_i_boreChildrenBd_bore_ack;
  wire [75:0] vT_g_boreChildrenBd_bore_outdata; wire [75:0] vT_i_boreChildrenBd_bore_outdata;
  ITTageTable    u_g_ITTageTable(.clock(clk), .reset(rst), .io_req_valid(vT_io_req_valid), .io_req_bits_pc(vT_io_req_bits_pc), .io_req_bits_folded_hist_hist_12_folded_hist(vT_io_req_bits_folded_hist_hist_12_folded_hist), .io_update_pc(vT_io_update_pc), .io_update_ghist(vT_io_update_ghist), .io_update_valid(vT_io_update_valid), .io_update_correct(vT_io_update_correct), .io_update_alloc(vT_io_update_alloc), .io_update_oldCtr(vT_io_update_oldCtr), .io_update_uValid(vT_io_update_uValid), .io_update_u(vT_io_update_u), .io_update_reset_u(vT_io_update_reset_u), .io_update_target_offset_offset(vT_io_update_target_offset_offset), .io_update_target_offset_pointer(vT_io_update_target_offset_pointer), .io_update_target_offset_usePCRegion(vT_io_update_target_offset_usePCRegion), .io_update_old_target_offset_offset(vT_io_update_old_target_offset_offset), .io_update_old_target_offset_pointer(vT_io_update_old_target_offset_pointer), .io_update_old_target_offset_usePCRegion(vT_io_update_old_target_offset_usePCRegion), .boreChildrenBd_bore_array(vT_boreChildrenBd_bore_array), .boreChildrenBd_bore_all(vT_boreChildrenBd_bore_all), .boreChildrenBd_bore_req(vT_boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(vT_boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(vT_boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(vT_boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(vT_boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(vT_boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(vT_boreChildrenBd_bore_addr_rd), .sigFromSrams_bore_ram_hold(vT_sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(vT_sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(vT_sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(vT_sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(vT_sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(vT_sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(vT_sigFromSrams_bore_cgen), .io_req_ready(vT_g_io_req_ready), .io_resp_valid(vT_g_io_resp_valid), .io_resp_bits_ctr(vT_g_io_resp_bits_ctr), .io_resp_bits_u(vT_g_io_resp_bits_u), .io_resp_bits_target_offset_offset(vT_g_io_resp_bits_target_offset_offset), .io_resp_bits_target_offset_pointer(vT_g_io_resp_bits_target_offset_pointer), .io_resp_bits_target_offset_usePCRegion(vT_g_io_resp_bits_target_offset_usePCRegion), .boreChildrenBd_bore_ack(vT_g_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(vT_g_boreChildrenBd_bore_outdata));
  ITTageTable_xs u_i_ITTageTable(.clock(clk), .reset(rst), .io_req_valid(vT_io_req_valid), .io_req_bits_pc(vT_io_req_bits_pc), .io_req_bits_folded_hist_hist_12_folded_hist(vT_io_req_bits_folded_hist_hist_12_folded_hist), .io_update_pc(vT_io_update_pc), .io_update_ghist(vT_io_update_ghist), .io_update_valid(vT_io_update_valid), .io_update_correct(vT_io_update_correct), .io_update_alloc(vT_io_update_alloc), .io_update_oldCtr(vT_io_update_oldCtr), .io_update_uValid(vT_io_update_uValid), .io_update_u(vT_io_update_u), .io_update_reset_u(vT_io_update_reset_u), .io_update_target_offset_offset(vT_io_update_target_offset_offset), .io_update_target_offset_pointer(vT_io_update_target_offset_pointer), .io_update_target_offset_usePCRegion(vT_io_update_target_offset_usePCRegion), .io_update_old_target_offset_offset(vT_io_update_old_target_offset_offset), .io_update_old_target_offset_pointer(vT_io_update_old_target_offset_pointer), .io_update_old_target_offset_usePCRegion(vT_io_update_old_target_offset_usePCRegion), .boreChildrenBd_bore_array(vT_boreChildrenBd_bore_array), .boreChildrenBd_bore_all(vT_boreChildrenBd_bore_all), .boreChildrenBd_bore_req(vT_boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(vT_boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(vT_boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(vT_boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(vT_boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(vT_boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(vT_boreChildrenBd_bore_addr_rd), .sigFromSrams_bore_ram_hold(vT_sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(vT_sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(vT_sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(vT_sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(vT_sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(vT_sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(vT_sigFromSrams_bore_cgen), .io_req_ready(vT_i_io_req_ready), .io_resp_valid(vT_i_io_resp_valid), .io_resp_bits_ctr(vT_i_io_resp_bits_ctr), .io_resp_bits_u(vT_i_io_resp_bits_u), .io_resp_bits_target_offset_offset(vT_i_io_resp_bits_target_offset_offset), .io_resp_bits_target_offset_pointer(vT_i_io_resp_bits_target_offset_pointer), .io_resp_bits_target_offset_usePCRegion(vT_i_io_resp_bits_target_offset_usePCRegion), .boreChildrenBd_bore_ack(vT_i_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(vT_i_boreChildrenBd_bore_outdata));
  always @(negedge clk) begin
    if (rst) begin
      vT_io_req_valid<=1'b0;
      vT_io_update_valid<=1'b0;
      vT_io_update_reset_u<=1'b0;
      vT_boreChildrenBd_bore_all<=1'b0;
      vT_boreChildrenBd_bore_req<=1'b0;
      vT_boreChildrenBd_bore_writeen<=1'b0;
      vT_boreChildrenBd_bore_readen<=1'b0;
    end else begin
      vT_io_req_valid<=($urandom_range(0,3)!=0);
      vT_io_req_bits_pc<=50'({$urandom, $urandom});
      vT_io_req_bits_folded_hist_hist_12_folded_hist<=4'($urandom);
      vT_io_update_pc<=50'({$urandom, $urandom});
      vT_io_update_ghist<=256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      vT_io_update_valid<=($urandom_range(0,2)==0);
      vT_io_update_correct<=1'($urandom);
      vT_io_update_alloc<=1'($urandom);
      vT_io_update_oldCtr<=2'($urandom);
      vT_io_update_uValid<=1'($urandom);
      vT_io_update_u<=1'($urandom);
      vT_io_update_reset_u<=($urandom_range(0,63)==0);
      vT_io_update_target_offset_offset<=20'($urandom);
      vT_io_update_target_offset_pointer<=4'($urandom);
      vT_io_update_target_offset_usePCRegion<=1'($urandom);
      vT_io_update_old_target_offset_offset<=20'($urandom);
      vT_io_update_old_target_offset_pointer<=4'($urandom);
      vT_io_update_old_target_offset_usePCRegion<=1'($urandom);
      vT_boreChildrenBd_bore_array<=7'($urandom);
      vT_boreChildrenBd_bore_all<=($urandom_range(0,7)==0);
      vT_boreChildrenBd_bore_req<=($urandom_range(0,7)==0);
      vT_boreChildrenBd_bore_writeen<=($urandom_range(0,7)==0);
      vT_boreChildrenBd_bore_be<=76'({$urandom, $urandom, $urandom});
      vT_boreChildrenBd_bore_addr<=8'($urandom);
      vT_boreChildrenBd_bore_indata<=76'({$urandom, $urandom, $urandom});
      vT_boreChildrenBd_bore_readen<=($urandom_range(0,7)==0);
      vT_boreChildrenBd_bore_addr_rd<=8'($urandom);
      vT_sigFromSrams_bore_ram_hold<=1'b0;
      vT_sigFromSrams_bore_ram_bypass<=1'b0;
      vT_sigFromSrams_bore_ram_bp_clken<=1'b0;
      vT_sigFromSrams_bore_ram_aux_clk<=1'b0;
      vT_sigFromSrams_bore_ram_aux_ckbp<=1'b0;
      vT_sigFromSrams_bore_ram_mcp_hold<=1'b0;
      vT_sigFromSrams_bore_cgen<=1'b0;
    end
  end
  always @(negedge clk) if(!rst&&cycle>WARMUP) begin #4; checks++;
    if (vT_g_io_req_ready!==vT_i_io_req_ready) begin errors++; if(errors<=40) $display("[%0t] ITTageTable.io_req_ready g=%h i=%h",$time,vT_g_io_req_ready,vT_i_io_req_ready); end
    if (vT_g_io_resp_valid!==vT_i_io_resp_valid) begin errors++; if(errors<=40) $display("[%0t] ITTageTable.io_resp_valid g=%h i=%h",$time,vT_g_io_resp_valid,vT_i_io_resp_valid); end
    if (vT_g_io_resp_bits_ctr!==vT_i_io_resp_bits_ctr) begin errors++; if(errors<=40) $display("[%0t] ITTageTable.io_resp_bits_ctr g=%h i=%h",$time,vT_g_io_resp_bits_ctr,vT_i_io_resp_bits_ctr); end
    if (vT_g_io_resp_bits_u!==vT_i_io_resp_bits_u) begin errors++; if(errors<=40) $display("[%0t] ITTageTable.io_resp_bits_u g=%h i=%h",$time,vT_g_io_resp_bits_u,vT_i_io_resp_bits_u); end
    if (vT_g_io_resp_bits_target_offset_offset!==vT_i_io_resp_bits_target_offset_offset) begin errors++; if(errors<=40) $display("[%0t] ITTageTable.io_resp_bits_target_offset_offset g=%h i=%h",$time,vT_g_io_resp_bits_target_offset_offset,vT_i_io_resp_bits_target_offset_offset); end
    if (vT_g_io_resp_bits_target_offset_pointer!==vT_i_io_resp_bits_target_offset_pointer) begin errors++; if(errors<=40) $display("[%0t] ITTageTable.io_resp_bits_target_offset_pointer g=%h i=%h",$time,vT_g_io_resp_bits_target_offset_pointer,vT_i_io_resp_bits_target_offset_pointer); end
    if (vT_g_io_resp_bits_target_offset_usePCRegion!==vT_i_io_resp_bits_target_offset_usePCRegion) begin errors++; if(errors<=40) $display("[%0t] ITTageTable.io_resp_bits_target_offset_usePCRegion g=%h i=%h",$time,vT_g_io_resp_bits_target_offset_usePCRegion,vT_i_io_resp_bits_target_offset_usePCRegion); end
    if (vT_g_boreChildrenBd_bore_ack!==vT_i_boreChildrenBd_bore_ack) begin errors++; if(errors<=40) $display("[%0t] ITTageTable.boreChildrenBd_bore_ack g=%h i=%h",$time,vT_g_boreChildrenBd_bore_ack,vT_i_boreChildrenBd_bore_ack); end
    if (vT_g_boreChildrenBd_bore_outdata!==vT_i_boreChildrenBd_bore_outdata) begin errors++; if(errors<=40) $display("[%0t] ITTageTable.boreChildrenBd_bore_outdata g=%h i=%h",$time,vT_g_boreChildrenBd_bore_outdata,vT_i_boreChildrenBd_bore_outdata); end
  end
  logic vT_1_io_req_valid;
  logic [49:0] vT_1_io_req_bits_pc;
  logic [7:0] vT_1_io_req_bits_folded_hist_hist_14_folded_hist;
  logic [49:0] vT_1_io_update_pc;
  logic [255:0] vT_1_io_update_ghist;
  logic vT_1_io_update_valid;
  logic vT_1_io_update_correct;
  logic vT_1_io_update_alloc;
  logic [1:0] vT_1_io_update_oldCtr;
  logic vT_1_io_update_uValid;
  logic vT_1_io_update_u;
  logic vT_1_io_update_reset_u;
  logic [19:0] vT_1_io_update_target_offset_offset;
  logic [3:0] vT_1_io_update_target_offset_pointer;
  logic vT_1_io_update_target_offset_usePCRegion;
  logic [19:0] vT_1_io_update_old_target_offset_offset;
  logic [3:0] vT_1_io_update_old_target_offset_pointer;
  logic vT_1_io_update_old_target_offset_usePCRegion;
  logic [6:0] vT_1_boreChildrenBd_bore_array;
  logic vT_1_boreChildrenBd_bore_all;
  logic vT_1_boreChildrenBd_bore_req;
  logic vT_1_boreChildrenBd_bore_writeen;
  logic [75:0] vT_1_boreChildrenBd_bore_be;
  logic [7:0] vT_1_boreChildrenBd_bore_addr;
  logic [75:0] vT_1_boreChildrenBd_bore_indata;
  logic vT_1_boreChildrenBd_bore_readen;
  logic [7:0] vT_1_boreChildrenBd_bore_addr_rd;
  logic vT_1_sigFromSrams_bore_ram_hold;
  logic vT_1_sigFromSrams_bore_ram_bypass;
  logic vT_1_sigFromSrams_bore_ram_bp_clken;
  logic vT_1_sigFromSrams_bore_ram_aux_clk;
  logic vT_1_sigFromSrams_bore_ram_aux_ckbp;
  logic vT_1_sigFromSrams_bore_ram_mcp_hold;
  logic vT_1_sigFromSrams_bore_cgen;
  wire vT_1_g_io_req_ready; wire vT_1_i_io_req_ready;
  wire vT_1_g_io_resp_valid; wire vT_1_i_io_resp_valid;
  wire [1:0] vT_1_g_io_resp_bits_ctr; wire [1:0] vT_1_i_io_resp_bits_ctr;
  wire vT_1_g_io_resp_bits_u; wire vT_1_i_io_resp_bits_u;
  wire [19:0] vT_1_g_io_resp_bits_target_offset_offset; wire [19:0] vT_1_i_io_resp_bits_target_offset_offset;
  wire [3:0] vT_1_g_io_resp_bits_target_offset_pointer; wire [3:0] vT_1_i_io_resp_bits_target_offset_pointer;
  wire vT_1_g_io_resp_bits_target_offset_usePCRegion; wire vT_1_i_io_resp_bits_target_offset_usePCRegion;
  wire vT_1_g_boreChildrenBd_bore_ack; wire vT_1_i_boreChildrenBd_bore_ack;
  wire [75:0] vT_1_g_boreChildrenBd_bore_outdata; wire [75:0] vT_1_i_boreChildrenBd_bore_outdata;
  ITTageTable_1    u_g_ITTageTable_1(.clock(clk), .reset(rst), .io_req_valid(vT_1_io_req_valid), .io_req_bits_pc(vT_1_io_req_bits_pc), .io_req_bits_folded_hist_hist_14_folded_hist(vT_1_io_req_bits_folded_hist_hist_14_folded_hist), .io_update_pc(vT_1_io_update_pc), .io_update_ghist(vT_1_io_update_ghist), .io_update_valid(vT_1_io_update_valid), .io_update_correct(vT_1_io_update_correct), .io_update_alloc(vT_1_io_update_alloc), .io_update_oldCtr(vT_1_io_update_oldCtr), .io_update_uValid(vT_1_io_update_uValid), .io_update_u(vT_1_io_update_u), .io_update_reset_u(vT_1_io_update_reset_u), .io_update_target_offset_offset(vT_1_io_update_target_offset_offset), .io_update_target_offset_pointer(vT_1_io_update_target_offset_pointer), .io_update_target_offset_usePCRegion(vT_1_io_update_target_offset_usePCRegion), .io_update_old_target_offset_offset(vT_1_io_update_old_target_offset_offset), .io_update_old_target_offset_pointer(vT_1_io_update_old_target_offset_pointer), .io_update_old_target_offset_usePCRegion(vT_1_io_update_old_target_offset_usePCRegion), .boreChildrenBd_bore_array(vT_1_boreChildrenBd_bore_array), .boreChildrenBd_bore_all(vT_1_boreChildrenBd_bore_all), .boreChildrenBd_bore_req(vT_1_boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(vT_1_boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(vT_1_boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(vT_1_boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(vT_1_boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(vT_1_boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(vT_1_boreChildrenBd_bore_addr_rd), .sigFromSrams_bore_ram_hold(vT_1_sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(vT_1_sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(vT_1_sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(vT_1_sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(vT_1_sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(vT_1_sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(vT_1_sigFromSrams_bore_cgen), .io_req_ready(vT_1_g_io_req_ready), .io_resp_valid(vT_1_g_io_resp_valid), .io_resp_bits_ctr(vT_1_g_io_resp_bits_ctr), .io_resp_bits_u(vT_1_g_io_resp_bits_u), .io_resp_bits_target_offset_offset(vT_1_g_io_resp_bits_target_offset_offset), .io_resp_bits_target_offset_pointer(vT_1_g_io_resp_bits_target_offset_pointer), .io_resp_bits_target_offset_usePCRegion(vT_1_g_io_resp_bits_target_offset_usePCRegion), .boreChildrenBd_bore_ack(vT_1_g_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(vT_1_g_boreChildrenBd_bore_outdata));
  ITTageTable_1_xs u_i_ITTageTable_1(.clock(clk), .reset(rst), .io_req_valid(vT_1_io_req_valid), .io_req_bits_pc(vT_1_io_req_bits_pc), .io_req_bits_folded_hist_hist_14_folded_hist(vT_1_io_req_bits_folded_hist_hist_14_folded_hist), .io_update_pc(vT_1_io_update_pc), .io_update_ghist(vT_1_io_update_ghist), .io_update_valid(vT_1_io_update_valid), .io_update_correct(vT_1_io_update_correct), .io_update_alloc(vT_1_io_update_alloc), .io_update_oldCtr(vT_1_io_update_oldCtr), .io_update_uValid(vT_1_io_update_uValid), .io_update_u(vT_1_io_update_u), .io_update_reset_u(vT_1_io_update_reset_u), .io_update_target_offset_offset(vT_1_io_update_target_offset_offset), .io_update_target_offset_pointer(vT_1_io_update_target_offset_pointer), .io_update_target_offset_usePCRegion(vT_1_io_update_target_offset_usePCRegion), .io_update_old_target_offset_offset(vT_1_io_update_old_target_offset_offset), .io_update_old_target_offset_pointer(vT_1_io_update_old_target_offset_pointer), .io_update_old_target_offset_usePCRegion(vT_1_io_update_old_target_offset_usePCRegion), .boreChildrenBd_bore_array(vT_1_boreChildrenBd_bore_array), .boreChildrenBd_bore_all(vT_1_boreChildrenBd_bore_all), .boreChildrenBd_bore_req(vT_1_boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(vT_1_boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(vT_1_boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(vT_1_boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(vT_1_boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(vT_1_boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(vT_1_boreChildrenBd_bore_addr_rd), .sigFromSrams_bore_ram_hold(vT_1_sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(vT_1_sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(vT_1_sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(vT_1_sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(vT_1_sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(vT_1_sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(vT_1_sigFromSrams_bore_cgen), .io_req_ready(vT_1_i_io_req_ready), .io_resp_valid(vT_1_i_io_resp_valid), .io_resp_bits_ctr(vT_1_i_io_resp_bits_ctr), .io_resp_bits_u(vT_1_i_io_resp_bits_u), .io_resp_bits_target_offset_offset(vT_1_i_io_resp_bits_target_offset_offset), .io_resp_bits_target_offset_pointer(vT_1_i_io_resp_bits_target_offset_pointer), .io_resp_bits_target_offset_usePCRegion(vT_1_i_io_resp_bits_target_offset_usePCRegion), .boreChildrenBd_bore_ack(vT_1_i_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(vT_1_i_boreChildrenBd_bore_outdata));
  always @(negedge clk) begin
    if (rst) begin
      vT_1_io_req_valid<=1'b0;
      vT_1_io_update_valid<=1'b0;
      vT_1_io_update_reset_u<=1'b0;
      vT_1_boreChildrenBd_bore_all<=1'b0;
      vT_1_boreChildrenBd_bore_req<=1'b0;
      vT_1_boreChildrenBd_bore_writeen<=1'b0;
      vT_1_boreChildrenBd_bore_readen<=1'b0;
    end else begin
      vT_1_io_req_valid<=($urandom_range(0,3)!=0);
      vT_1_io_req_bits_pc<=50'({$urandom, $urandom});
      vT_1_io_req_bits_folded_hist_hist_14_folded_hist<=8'($urandom);
      vT_1_io_update_pc<=50'({$urandom, $urandom});
      vT_1_io_update_ghist<=256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      vT_1_io_update_valid<=($urandom_range(0,2)==0);
      vT_1_io_update_correct<=1'($urandom);
      vT_1_io_update_alloc<=1'($urandom);
      vT_1_io_update_oldCtr<=2'($urandom);
      vT_1_io_update_uValid<=1'($urandom);
      vT_1_io_update_u<=1'($urandom);
      vT_1_io_update_reset_u<=($urandom_range(0,63)==0);
      vT_1_io_update_target_offset_offset<=20'($urandom);
      vT_1_io_update_target_offset_pointer<=4'($urandom);
      vT_1_io_update_target_offset_usePCRegion<=1'($urandom);
      vT_1_io_update_old_target_offset_offset<=20'($urandom);
      vT_1_io_update_old_target_offset_pointer<=4'($urandom);
      vT_1_io_update_old_target_offset_usePCRegion<=1'($urandom);
      vT_1_boreChildrenBd_bore_array<=7'($urandom);
      vT_1_boreChildrenBd_bore_all<=($urandom_range(0,7)==0);
      vT_1_boreChildrenBd_bore_req<=($urandom_range(0,7)==0);
      vT_1_boreChildrenBd_bore_writeen<=($urandom_range(0,7)==0);
      vT_1_boreChildrenBd_bore_be<=76'({$urandom, $urandom, $urandom});
      vT_1_boreChildrenBd_bore_addr<=8'($urandom);
      vT_1_boreChildrenBd_bore_indata<=76'({$urandom, $urandom, $urandom});
      vT_1_boreChildrenBd_bore_readen<=($urandom_range(0,7)==0);
      vT_1_boreChildrenBd_bore_addr_rd<=8'($urandom);
      vT_1_sigFromSrams_bore_ram_hold<=1'b0;
      vT_1_sigFromSrams_bore_ram_bypass<=1'b0;
      vT_1_sigFromSrams_bore_ram_bp_clken<=1'b0;
      vT_1_sigFromSrams_bore_ram_aux_clk<=1'b0;
      vT_1_sigFromSrams_bore_ram_aux_ckbp<=1'b0;
      vT_1_sigFromSrams_bore_ram_mcp_hold<=1'b0;
      vT_1_sigFromSrams_bore_cgen<=1'b0;
    end
  end
  always @(negedge clk) if(!rst&&cycle>WARMUP) begin #4; checks++;
    if (vT_1_g_io_req_ready!==vT_1_i_io_req_ready) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_1.io_req_ready g=%h i=%h",$time,vT_1_g_io_req_ready,vT_1_i_io_req_ready); end
    if (vT_1_g_io_resp_valid!==vT_1_i_io_resp_valid) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_1.io_resp_valid g=%h i=%h",$time,vT_1_g_io_resp_valid,vT_1_i_io_resp_valid); end
    if (vT_1_g_io_resp_bits_ctr!==vT_1_i_io_resp_bits_ctr) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_1.io_resp_bits_ctr g=%h i=%h",$time,vT_1_g_io_resp_bits_ctr,vT_1_i_io_resp_bits_ctr); end
    if (vT_1_g_io_resp_bits_u!==vT_1_i_io_resp_bits_u) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_1.io_resp_bits_u g=%h i=%h",$time,vT_1_g_io_resp_bits_u,vT_1_i_io_resp_bits_u); end
    if (vT_1_g_io_resp_bits_target_offset_offset!==vT_1_i_io_resp_bits_target_offset_offset) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_1.io_resp_bits_target_offset_offset g=%h i=%h",$time,vT_1_g_io_resp_bits_target_offset_offset,vT_1_i_io_resp_bits_target_offset_offset); end
    if (vT_1_g_io_resp_bits_target_offset_pointer!==vT_1_i_io_resp_bits_target_offset_pointer) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_1.io_resp_bits_target_offset_pointer g=%h i=%h",$time,vT_1_g_io_resp_bits_target_offset_pointer,vT_1_i_io_resp_bits_target_offset_pointer); end
    if (vT_1_g_io_resp_bits_target_offset_usePCRegion!==vT_1_i_io_resp_bits_target_offset_usePCRegion) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_1.io_resp_bits_target_offset_usePCRegion g=%h i=%h",$time,vT_1_g_io_resp_bits_target_offset_usePCRegion,vT_1_i_io_resp_bits_target_offset_usePCRegion); end
    if (vT_1_g_boreChildrenBd_bore_ack!==vT_1_i_boreChildrenBd_bore_ack) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_1.boreChildrenBd_bore_ack g=%h i=%h",$time,vT_1_g_boreChildrenBd_bore_ack,vT_1_i_boreChildrenBd_bore_ack); end
    if (vT_1_g_boreChildrenBd_bore_outdata!==vT_1_i_boreChildrenBd_bore_outdata) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_1.boreChildrenBd_bore_outdata g=%h i=%h",$time,vT_1_g_boreChildrenBd_bore_outdata,vT_1_i_boreChildrenBd_bore_outdata); end
  end
  logic vT_2_io_req_valid;
  logic [49:0] vT_2_io_req_bits_pc;
  logic [8:0] vT_2_io_req_bits_folded_hist_hist_13_folded_hist;
  logic [7:0] vT_2_io_req_bits_folded_hist_hist_4_folded_hist;
  logic [49:0] vT_2_io_update_pc;
  logic [255:0] vT_2_io_update_ghist;
  logic vT_2_io_update_valid;
  logic vT_2_io_update_correct;
  logic vT_2_io_update_alloc;
  logic [1:0] vT_2_io_update_oldCtr;
  logic vT_2_io_update_uValid;
  logic vT_2_io_update_u;
  logic vT_2_io_update_reset_u;
  logic [19:0] vT_2_io_update_target_offset_offset;
  logic [3:0] vT_2_io_update_target_offset_pointer;
  logic vT_2_io_update_target_offset_usePCRegion;
  logic [19:0] vT_2_io_update_old_target_offset_offset;
  logic [3:0] vT_2_io_update_old_target_offset_pointer;
  logic vT_2_io_update_old_target_offset_usePCRegion;
  logic [6:0] vT_2_boreChildrenBd_bore_array;
  logic vT_2_boreChildrenBd_bore_all;
  logic vT_2_boreChildrenBd_bore_req;
  logic vT_2_boreChildrenBd_bore_writeen;
  logic [75:0] vT_2_boreChildrenBd_bore_be;
  logic [7:0] vT_2_boreChildrenBd_bore_addr;
  logic [75:0] vT_2_boreChildrenBd_bore_indata;
  logic vT_2_boreChildrenBd_bore_readen;
  logic [7:0] vT_2_boreChildrenBd_bore_addr_rd;
  logic vT_2_sigFromSrams_bore_ram_hold;
  logic vT_2_sigFromSrams_bore_ram_bypass;
  logic vT_2_sigFromSrams_bore_ram_bp_clken;
  logic vT_2_sigFromSrams_bore_ram_aux_clk;
  logic vT_2_sigFromSrams_bore_ram_aux_ckbp;
  logic vT_2_sigFromSrams_bore_ram_mcp_hold;
  logic vT_2_sigFromSrams_bore_cgen;
  logic vT_2_sigFromSrams_bore_1_ram_hold;
  logic vT_2_sigFromSrams_bore_1_ram_bypass;
  logic vT_2_sigFromSrams_bore_1_ram_bp_clken;
  logic vT_2_sigFromSrams_bore_1_ram_aux_clk;
  logic vT_2_sigFromSrams_bore_1_ram_aux_ckbp;
  logic vT_2_sigFromSrams_bore_1_ram_mcp_hold;
  logic vT_2_sigFromSrams_bore_1_cgen;
  wire vT_2_g_io_req_ready; wire vT_2_i_io_req_ready;
  wire vT_2_g_io_resp_valid; wire vT_2_i_io_resp_valid;
  wire [1:0] vT_2_g_io_resp_bits_ctr; wire [1:0] vT_2_i_io_resp_bits_ctr;
  wire vT_2_g_io_resp_bits_u; wire vT_2_i_io_resp_bits_u;
  wire [19:0] vT_2_g_io_resp_bits_target_offset_offset; wire [19:0] vT_2_i_io_resp_bits_target_offset_offset;
  wire [3:0] vT_2_g_io_resp_bits_target_offset_pointer; wire [3:0] vT_2_i_io_resp_bits_target_offset_pointer;
  wire vT_2_g_io_resp_bits_target_offset_usePCRegion; wire vT_2_i_io_resp_bits_target_offset_usePCRegion;
  wire vT_2_g_boreChildrenBd_bore_ack; wire vT_2_i_boreChildrenBd_bore_ack;
  wire [75:0] vT_2_g_boreChildrenBd_bore_outdata; wire [75:0] vT_2_i_boreChildrenBd_bore_outdata;
  ITTageTable_2    u_g_ITTageTable_2(.clock(clk), .reset(rst), .io_req_valid(vT_2_io_req_valid), .io_req_bits_pc(vT_2_io_req_bits_pc), .io_req_bits_folded_hist_hist_13_folded_hist(vT_2_io_req_bits_folded_hist_hist_13_folded_hist), .io_req_bits_folded_hist_hist_4_folded_hist(vT_2_io_req_bits_folded_hist_hist_4_folded_hist), .io_update_pc(vT_2_io_update_pc), .io_update_ghist(vT_2_io_update_ghist), .io_update_valid(vT_2_io_update_valid), .io_update_correct(vT_2_io_update_correct), .io_update_alloc(vT_2_io_update_alloc), .io_update_oldCtr(vT_2_io_update_oldCtr), .io_update_uValid(vT_2_io_update_uValid), .io_update_u(vT_2_io_update_u), .io_update_reset_u(vT_2_io_update_reset_u), .io_update_target_offset_offset(vT_2_io_update_target_offset_offset), .io_update_target_offset_pointer(vT_2_io_update_target_offset_pointer), .io_update_target_offset_usePCRegion(vT_2_io_update_target_offset_usePCRegion), .io_update_old_target_offset_offset(vT_2_io_update_old_target_offset_offset), .io_update_old_target_offset_pointer(vT_2_io_update_old_target_offset_pointer), .io_update_old_target_offset_usePCRegion(vT_2_io_update_old_target_offset_usePCRegion), .boreChildrenBd_bore_array(vT_2_boreChildrenBd_bore_array), .boreChildrenBd_bore_all(vT_2_boreChildrenBd_bore_all), .boreChildrenBd_bore_req(vT_2_boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(vT_2_boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(vT_2_boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(vT_2_boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(vT_2_boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(vT_2_boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(vT_2_boreChildrenBd_bore_addr_rd), .sigFromSrams_bore_ram_hold(vT_2_sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(vT_2_sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(vT_2_sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(vT_2_sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(vT_2_sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(vT_2_sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(vT_2_sigFromSrams_bore_cgen), .sigFromSrams_bore_1_ram_hold(vT_2_sigFromSrams_bore_1_ram_hold), .sigFromSrams_bore_1_ram_bypass(vT_2_sigFromSrams_bore_1_ram_bypass), .sigFromSrams_bore_1_ram_bp_clken(vT_2_sigFromSrams_bore_1_ram_bp_clken), .sigFromSrams_bore_1_ram_aux_clk(vT_2_sigFromSrams_bore_1_ram_aux_clk), .sigFromSrams_bore_1_ram_aux_ckbp(vT_2_sigFromSrams_bore_1_ram_aux_ckbp), .sigFromSrams_bore_1_ram_mcp_hold(vT_2_sigFromSrams_bore_1_ram_mcp_hold), .sigFromSrams_bore_1_cgen(vT_2_sigFromSrams_bore_1_cgen), .io_req_ready(vT_2_g_io_req_ready), .io_resp_valid(vT_2_g_io_resp_valid), .io_resp_bits_ctr(vT_2_g_io_resp_bits_ctr), .io_resp_bits_u(vT_2_g_io_resp_bits_u), .io_resp_bits_target_offset_offset(vT_2_g_io_resp_bits_target_offset_offset), .io_resp_bits_target_offset_pointer(vT_2_g_io_resp_bits_target_offset_pointer), .io_resp_bits_target_offset_usePCRegion(vT_2_g_io_resp_bits_target_offset_usePCRegion), .boreChildrenBd_bore_ack(vT_2_g_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(vT_2_g_boreChildrenBd_bore_outdata));
  ITTageTable_2_xs u_i_ITTageTable_2(.clock(clk), .reset(rst), .io_req_valid(vT_2_io_req_valid), .io_req_bits_pc(vT_2_io_req_bits_pc), .io_req_bits_folded_hist_hist_13_folded_hist(vT_2_io_req_bits_folded_hist_hist_13_folded_hist), .io_req_bits_folded_hist_hist_4_folded_hist(vT_2_io_req_bits_folded_hist_hist_4_folded_hist), .io_update_pc(vT_2_io_update_pc), .io_update_ghist(vT_2_io_update_ghist), .io_update_valid(vT_2_io_update_valid), .io_update_correct(vT_2_io_update_correct), .io_update_alloc(vT_2_io_update_alloc), .io_update_oldCtr(vT_2_io_update_oldCtr), .io_update_uValid(vT_2_io_update_uValid), .io_update_u(vT_2_io_update_u), .io_update_reset_u(vT_2_io_update_reset_u), .io_update_target_offset_offset(vT_2_io_update_target_offset_offset), .io_update_target_offset_pointer(vT_2_io_update_target_offset_pointer), .io_update_target_offset_usePCRegion(vT_2_io_update_target_offset_usePCRegion), .io_update_old_target_offset_offset(vT_2_io_update_old_target_offset_offset), .io_update_old_target_offset_pointer(vT_2_io_update_old_target_offset_pointer), .io_update_old_target_offset_usePCRegion(vT_2_io_update_old_target_offset_usePCRegion), .boreChildrenBd_bore_array(vT_2_boreChildrenBd_bore_array), .boreChildrenBd_bore_all(vT_2_boreChildrenBd_bore_all), .boreChildrenBd_bore_req(vT_2_boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(vT_2_boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(vT_2_boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(vT_2_boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(vT_2_boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(vT_2_boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(vT_2_boreChildrenBd_bore_addr_rd), .sigFromSrams_bore_ram_hold(vT_2_sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(vT_2_sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(vT_2_sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(vT_2_sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(vT_2_sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(vT_2_sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(vT_2_sigFromSrams_bore_cgen), .sigFromSrams_bore_1_ram_hold(vT_2_sigFromSrams_bore_1_ram_hold), .sigFromSrams_bore_1_ram_bypass(vT_2_sigFromSrams_bore_1_ram_bypass), .sigFromSrams_bore_1_ram_bp_clken(vT_2_sigFromSrams_bore_1_ram_bp_clken), .sigFromSrams_bore_1_ram_aux_clk(vT_2_sigFromSrams_bore_1_ram_aux_clk), .sigFromSrams_bore_1_ram_aux_ckbp(vT_2_sigFromSrams_bore_1_ram_aux_ckbp), .sigFromSrams_bore_1_ram_mcp_hold(vT_2_sigFromSrams_bore_1_ram_mcp_hold), .sigFromSrams_bore_1_cgen(vT_2_sigFromSrams_bore_1_cgen), .io_req_ready(vT_2_i_io_req_ready), .io_resp_valid(vT_2_i_io_resp_valid), .io_resp_bits_ctr(vT_2_i_io_resp_bits_ctr), .io_resp_bits_u(vT_2_i_io_resp_bits_u), .io_resp_bits_target_offset_offset(vT_2_i_io_resp_bits_target_offset_offset), .io_resp_bits_target_offset_pointer(vT_2_i_io_resp_bits_target_offset_pointer), .io_resp_bits_target_offset_usePCRegion(vT_2_i_io_resp_bits_target_offset_usePCRegion), .boreChildrenBd_bore_ack(vT_2_i_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(vT_2_i_boreChildrenBd_bore_outdata));
  always @(negedge clk) begin
    if (rst) begin
      vT_2_io_req_valid<=1'b0;
      vT_2_io_update_valid<=1'b0;
      vT_2_io_update_reset_u<=1'b0;
      vT_2_boreChildrenBd_bore_all<=1'b0;
      vT_2_boreChildrenBd_bore_req<=1'b0;
      vT_2_boreChildrenBd_bore_writeen<=1'b0;
      vT_2_boreChildrenBd_bore_readen<=1'b0;
    end else begin
      vT_2_io_req_valid<=($urandom_range(0,3)!=0);
      vT_2_io_req_bits_pc<=50'({$urandom, $urandom});
      vT_2_io_req_bits_folded_hist_hist_13_folded_hist<=9'($urandom);
      vT_2_io_req_bits_folded_hist_hist_4_folded_hist<=8'($urandom);
      vT_2_io_update_pc<=50'({$urandom, $urandom});
      vT_2_io_update_ghist<=256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      vT_2_io_update_valid<=($urandom_range(0,2)==0);
      vT_2_io_update_correct<=1'($urandom);
      vT_2_io_update_alloc<=1'($urandom);
      vT_2_io_update_oldCtr<=2'($urandom);
      vT_2_io_update_uValid<=1'($urandom);
      vT_2_io_update_u<=1'($urandom);
      vT_2_io_update_reset_u<=($urandom_range(0,63)==0);
      vT_2_io_update_target_offset_offset<=20'($urandom);
      vT_2_io_update_target_offset_pointer<=4'($urandom);
      vT_2_io_update_target_offset_usePCRegion<=1'($urandom);
      vT_2_io_update_old_target_offset_offset<=20'($urandom);
      vT_2_io_update_old_target_offset_pointer<=4'($urandom);
      vT_2_io_update_old_target_offset_usePCRegion<=1'($urandom);
      vT_2_boreChildrenBd_bore_array<=7'($urandom);
      vT_2_boreChildrenBd_bore_all<=($urandom_range(0,7)==0);
      vT_2_boreChildrenBd_bore_req<=($urandom_range(0,7)==0);
      vT_2_boreChildrenBd_bore_writeen<=($urandom_range(0,7)==0);
      vT_2_boreChildrenBd_bore_be<=76'({$urandom, $urandom, $urandom});
      vT_2_boreChildrenBd_bore_addr<=8'($urandom);
      vT_2_boreChildrenBd_bore_indata<=76'({$urandom, $urandom, $urandom});
      vT_2_boreChildrenBd_bore_readen<=($urandom_range(0,7)==0);
      vT_2_boreChildrenBd_bore_addr_rd<=8'($urandom);
      vT_2_sigFromSrams_bore_ram_hold<=1'b0;
      vT_2_sigFromSrams_bore_ram_bypass<=1'b0;
      vT_2_sigFromSrams_bore_ram_bp_clken<=1'b0;
      vT_2_sigFromSrams_bore_ram_aux_clk<=1'b0;
      vT_2_sigFromSrams_bore_ram_aux_ckbp<=1'b0;
      vT_2_sigFromSrams_bore_ram_mcp_hold<=1'b0;
      vT_2_sigFromSrams_bore_cgen<=1'b0;
      vT_2_sigFromSrams_bore_1_ram_hold<=1'b0;
      vT_2_sigFromSrams_bore_1_ram_bypass<=1'b0;
      vT_2_sigFromSrams_bore_1_ram_bp_clken<=1'b0;
      vT_2_sigFromSrams_bore_1_ram_aux_clk<=1'b0;
      vT_2_sigFromSrams_bore_1_ram_aux_ckbp<=1'b0;
      vT_2_sigFromSrams_bore_1_ram_mcp_hold<=1'b0;
      vT_2_sigFromSrams_bore_1_cgen<=1'b0;
    end
  end
  always @(negedge clk) if(!rst&&cycle>WARMUP) begin #4; checks++;
    if (vT_2_g_io_req_ready!==vT_2_i_io_req_ready) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_2.io_req_ready g=%h i=%h",$time,vT_2_g_io_req_ready,vT_2_i_io_req_ready); end
    if (vT_2_g_io_resp_valid!==vT_2_i_io_resp_valid) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_2.io_resp_valid g=%h i=%h",$time,vT_2_g_io_resp_valid,vT_2_i_io_resp_valid); end
    if (vT_2_g_io_resp_bits_ctr!==vT_2_i_io_resp_bits_ctr) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_2.io_resp_bits_ctr g=%h i=%h",$time,vT_2_g_io_resp_bits_ctr,vT_2_i_io_resp_bits_ctr); end
    if (vT_2_g_io_resp_bits_u!==vT_2_i_io_resp_bits_u) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_2.io_resp_bits_u g=%h i=%h",$time,vT_2_g_io_resp_bits_u,vT_2_i_io_resp_bits_u); end
    if (vT_2_g_io_resp_bits_target_offset_offset!==vT_2_i_io_resp_bits_target_offset_offset) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_2.io_resp_bits_target_offset_offset g=%h i=%h",$time,vT_2_g_io_resp_bits_target_offset_offset,vT_2_i_io_resp_bits_target_offset_offset); end
    if (vT_2_g_io_resp_bits_target_offset_pointer!==vT_2_i_io_resp_bits_target_offset_pointer) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_2.io_resp_bits_target_offset_pointer g=%h i=%h",$time,vT_2_g_io_resp_bits_target_offset_pointer,vT_2_i_io_resp_bits_target_offset_pointer); end
    if (vT_2_g_io_resp_bits_target_offset_usePCRegion!==vT_2_i_io_resp_bits_target_offset_usePCRegion) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_2.io_resp_bits_target_offset_usePCRegion g=%h i=%h",$time,vT_2_g_io_resp_bits_target_offset_usePCRegion,vT_2_i_io_resp_bits_target_offset_usePCRegion); end
    if (vT_2_g_boreChildrenBd_bore_ack!==vT_2_i_boreChildrenBd_bore_ack) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_2.boreChildrenBd_bore_ack g=%h i=%h",$time,vT_2_g_boreChildrenBd_bore_ack,vT_2_i_boreChildrenBd_bore_ack); end
    if (vT_2_g_boreChildrenBd_bore_outdata!==vT_2_i_boreChildrenBd_bore_outdata) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_2.boreChildrenBd_bore_outdata g=%h i=%h",$time,vT_2_g_boreChildrenBd_bore_outdata,vT_2_i_boreChildrenBd_bore_outdata); end
  end
  logic vT_3_io_req_valid;
  logic [49:0] vT_3_io_req_bits_pc;
  logic [8:0] vT_3_io_req_bits_folded_hist_hist_6_folded_hist;
  logic [7:0] vT_3_io_req_bits_folded_hist_hist_2_folded_hist;
  logic [49:0] vT_3_io_update_pc;
  logic [255:0] vT_3_io_update_ghist;
  logic vT_3_io_update_valid;
  logic vT_3_io_update_correct;
  logic vT_3_io_update_alloc;
  logic [1:0] vT_3_io_update_oldCtr;
  logic vT_3_io_update_uValid;
  logic vT_3_io_update_u;
  logic vT_3_io_update_reset_u;
  logic [19:0] vT_3_io_update_target_offset_offset;
  logic [3:0] vT_3_io_update_target_offset_pointer;
  logic vT_3_io_update_target_offset_usePCRegion;
  logic [19:0] vT_3_io_update_old_target_offset_offset;
  logic [3:0] vT_3_io_update_old_target_offset_pointer;
  logic vT_3_io_update_old_target_offset_usePCRegion;
  logic [6:0] vT_3_boreChildrenBd_bore_array;
  logic vT_3_boreChildrenBd_bore_all;
  logic vT_3_boreChildrenBd_bore_req;
  logic vT_3_boreChildrenBd_bore_writeen;
  logic [75:0] vT_3_boreChildrenBd_bore_be;
  logic [7:0] vT_3_boreChildrenBd_bore_addr;
  logic [75:0] vT_3_boreChildrenBd_bore_indata;
  logic vT_3_boreChildrenBd_bore_readen;
  logic [7:0] vT_3_boreChildrenBd_bore_addr_rd;
  logic vT_3_sigFromSrams_bore_ram_hold;
  logic vT_3_sigFromSrams_bore_ram_bypass;
  logic vT_3_sigFromSrams_bore_ram_bp_clken;
  logic vT_3_sigFromSrams_bore_ram_aux_clk;
  logic vT_3_sigFromSrams_bore_ram_aux_ckbp;
  logic vT_3_sigFromSrams_bore_ram_mcp_hold;
  logic vT_3_sigFromSrams_bore_cgen;
  logic vT_3_sigFromSrams_bore_1_ram_hold;
  logic vT_3_sigFromSrams_bore_1_ram_bypass;
  logic vT_3_sigFromSrams_bore_1_ram_bp_clken;
  logic vT_3_sigFromSrams_bore_1_ram_aux_clk;
  logic vT_3_sigFromSrams_bore_1_ram_aux_ckbp;
  logic vT_3_sigFromSrams_bore_1_ram_mcp_hold;
  logic vT_3_sigFromSrams_bore_1_cgen;
  wire vT_3_g_io_req_ready; wire vT_3_i_io_req_ready;
  wire vT_3_g_io_resp_valid; wire vT_3_i_io_resp_valid;
  wire [1:0] vT_3_g_io_resp_bits_ctr; wire [1:0] vT_3_i_io_resp_bits_ctr;
  wire vT_3_g_io_resp_bits_u; wire vT_3_i_io_resp_bits_u;
  wire [19:0] vT_3_g_io_resp_bits_target_offset_offset; wire [19:0] vT_3_i_io_resp_bits_target_offset_offset;
  wire [3:0] vT_3_g_io_resp_bits_target_offset_pointer; wire [3:0] vT_3_i_io_resp_bits_target_offset_pointer;
  wire vT_3_g_io_resp_bits_target_offset_usePCRegion; wire vT_3_i_io_resp_bits_target_offset_usePCRegion;
  wire vT_3_g_boreChildrenBd_bore_ack; wire vT_3_i_boreChildrenBd_bore_ack;
  wire [75:0] vT_3_g_boreChildrenBd_bore_outdata; wire [75:0] vT_3_i_boreChildrenBd_bore_outdata;
  ITTageTable_3    u_g_ITTageTable_3(.clock(clk), .reset(rst), .io_req_valid(vT_3_io_req_valid), .io_req_bits_pc(vT_3_io_req_bits_pc), .io_req_bits_folded_hist_hist_6_folded_hist(vT_3_io_req_bits_folded_hist_hist_6_folded_hist), .io_req_bits_folded_hist_hist_2_folded_hist(vT_3_io_req_bits_folded_hist_hist_2_folded_hist), .io_update_pc(vT_3_io_update_pc), .io_update_ghist(vT_3_io_update_ghist), .io_update_valid(vT_3_io_update_valid), .io_update_correct(vT_3_io_update_correct), .io_update_alloc(vT_3_io_update_alloc), .io_update_oldCtr(vT_3_io_update_oldCtr), .io_update_uValid(vT_3_io_update_uValid), .io_update_u(vT_3_io_update_u), .io_update_reset_u(vT_3_io_update_reset_u), .io_update_target_offset_offset(vT_3_io_update_target_offset_offset), .io_update_target_offset_pointer(vT_3_io_update_target_offset_pointer), .io_update_target_offset_usePCRegion(vT_3_io_update_target_offset_usePCRegion), .io_update_old_target_offset_offset(vT_3_io_update_old_target_offset_offset), .io_update_old_target_offset_pointer(vT_3_io_update_old_target_offset_pointer), .io_update_old_target_offset_usePCRegion(vT_3_io_update_old_target_offset_usePCRegion), .boreChildrenBd_bore_array(vT_3_boreChildrenBd_bore_array), .boreChildrenBd_bore_all(vT_3_boreChildrenBd_bore_all), .boreChildrenBd_bore_req(vT_3_boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(vT_3_boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(vT_3_boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(vT_3_boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(vT_3_boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(vT_3_boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(vT_3_boreChildrenBd_bore_addr_rd), .sigFromSrams_bore_ram_hold(vT_3_sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(vT_3_sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(vT_3_sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(vT_3_sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(vT_3_sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(vT_3_sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(vT_3_sigFromSrams_bore_cgen), .sigFromSrams_bore_1_ram_hold(vT_3_sigFromSrams_bore_1_ram_hold), .sigFromSrams_bore_1_ram_bypass(vT_3_sigFromSrams_bore_1_ram_bypass), .sigFromSrams_bore_1_ram_bp_clken(vT_3_sigFromSrams_bore_1_ram_bp_clken), .sigFromSrams_bore_1_ram_aux_clk(vT_3_sigFromSrams_bore_1_ram_aux_clk), .sigFromSrams_bore_1_ram_aux_ckbp(vT_3_sigFromSrams_bore_1_ram_aux_ckbp), .sigFromSrams_bore_1_ram_mcp_hold(vT_3_sigFromSrams_bore_1_ram_mcp_hold), .sigFromSrams_bore_1_cgen(vT_3_sigFromSrams_bore_1_cgen), .io_req_ready(vT_3_g_io_req_ready), .io_resp_valid(vT_3_g_io_resp_valid), .io_resp_bits_ctr(vT_3_g_io_resp_bits_ctr), .io_resp_bits_u(vT_3_g_io_resp_bits_u), .io_resp_bits_target_offset_offset(vT_3_g_io_resp_bits_target_offset_offset), .io_resp_bits_target_offset_pointer(vT_3_g_io_resp_bits_target_offset_pointer), .io_resp_bits_target_offset_usePCRegion(vT_3_g_io_resp_bits_target_offset_usePCRegion), .boreChildrenBd_bore_ack(vT_3_g_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(vT_3_g_boreChildrenBd_bore_outdata));
  ITTageTable_3_xs u_i_ITTageTable_3(.clock(clk), .reset(rst), .io_req_valid(vT_3_io_req_valid), .io_req_bits_pc(vT_3_io_req_bits_pc), .io_req_bits_folded_hist_hist_6_folded_hist(vT_3_io_req_bits_folded_hist_hist_6_folded_hist), .io_req_bits_folded_hist_hist_2_folded_hist(vT_3_io_req_bits_folded_hist_hist_2_folded_hist), .io_update_pc(vT_3_io_update_pc), .io_update_ghist(vT_3_io_update_ghist), .io_update_valid(vT_3_io_update_valid), .io_update_correct(vT_3_io_update_correct), .io_update_alloc(vT_3_io_update_alloc), .io_update_oldCtr(vT_3_io_update_oldCtr), .io_update_uValid(vT_3_io_update_uValid), .io_update_u(vT_3_io_update_u), .io_update_reset_u(vT_3_io_update_reset_u), .io_update_target_offset_offset(vT_3_io_update_target_offset_offset), .io_update_target_offset_pointer(vT_3_io_update_target_offset_pointer), .io_update_target_offset_usePCRegion(vT_3_io_update_target_offset_usePCRegion), .io_update_old_target_offset_offset(vT_3_io_update_old_target_offset_offset), .io_update_old_target_offset_pointer(vT_3_io_update_old_target_offset_pointer), .io_update_old_target_offset_usePCRegion(vT_3_io_update_old_target_offset_usePCRegion), .boreChildrenBd_bore_array(vT_3_boreChildrenBd_bore_array), .boreChildrenBd_bore_all(vT_3_boreChildrenBd_bore_all), .boreChildrenBd_bore_req(vT_3_boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(vT_3_boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(vT_3_boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(vT_3_boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(vT_3_boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(vT_3_boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(vT_3_boreChildrenBd_bore_addr_rd), .sigFromSrams_bore_ram_hold(vT_3_sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(vT_3_sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(vT_3_sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(vT_3_sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(vT_3_sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(vT_3_sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(vT_3_sigFromSrams_bore_cgen), .sigFromSrams_bore_1_ram_hold(vT_3_sigFromSrams_bore_1_ram_hold), .sigFromSrams_bore_1_ram_bypass(vT_3_sigFromSrams_bore_1_ram_bypass), .sigFromSrams_bore_1_ram_bp_clken(vT_3_sigFromSrams_bore_1_ram_bp_clken), .sigFromSrams_bore_1_ram_aux_clk(vT_3_sigFromSrams_bore_1_ram_aux_clk), .sigFromSrams_bore_1_ram_aux_ckbp(vT_3_sigFromSrams_bore_1_ram_aux_ckbp), .sigFromSrams_bore_1_ram_mcp_hold(vT_3_sigFromSrams_bore_1_ram_mcp_hold), .sigFromSrams_bore_1_cgen(vT_3_sigFromSrams_bore_1_cgen), .io_req_ready(vT_3_i_io_req_ready), .io_resp_valid(vT_3_i_io_resp_valid), .io_resp_bits_ctr(vT_3_i_io_resp_bits_ctr), .io_resp_bits_u(vT_3_i_io_resp_bits_u), .io_resp_bits_target_offset_offset(vT_3_i_io_resp_bits_target_offset_offset), .io_resp_bits_target_offset_pointer(vT_3_i_io_resp_bits_target_offset_pointer), .io_resp_bits_target_offset_usePCRegion(vT_3_i_io_resp_bits_target_offset_usePCRegion), .boreChildrenBd_bore_ack(vT_3_i_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(vT_3_i_boreChildrenBd_bore_outdata));
  always @(negedge clk) begin
    if (rst) begin
      vT_3_io_req_valid<=1'b0;
      vT_3_io_update_valid<=1'b0;
      vT_3_io_update_reset_u<=1'b0;
      vT_3_boreChildrenBd_bore_all<=1'b0;
      vT_3_boreChildrenBd_bore_req<=1'b0;
      vT_3_boreChildrenBd_bore_writeen<=1'b0;
      vT_3_boreChildrenBd_bore_readen<=1'b0;
    end else begin
      vT_3_io_req_valid<=($urandom_range(0,3)!=0);
      vT_3_io_req_bits_pc<=50'({$urandom, $urandom});
      vT_3_io_req_bits_folded_hist_hist_6_folded_hist<=9'($urandom);
      vT_3_io_req_bits_folded_hist_hist_2_folded_hist<=8'($urandom);
      vT_3_io_update_pc<=50'({$urandom, $urandom});
      vT_3_io_update_ghist<=256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      vT_3_io_update_valid<=($urandom_range(0,2)==0);
      vT_3_io_update_correct<=1'($urandom);
      vT_3_io_update_alloc<=1'($urandom);
      vT_3_io_update_oldCtr<=2'($urandom);
      vT_3_io_update_uValid<=1'($urandom);
      vT_3_io_update_u<=1'($urandom);
      vT_3_io_update_reset_u<=($urandom_range(0,63)==0);
      vT_3_io_update_target_offset_offset<=20'($urandom);
      vT_3_io_update_target_offset_pointer<=4'($urandom);
      vT_3_io_update_target_offset_usePCRegion<=1'($urandom);
      vT_3_io_update_old_target_offset_offset<=20'($urandom);
      vT_3_io_update_old_target_offset_pointer<=4'($urandom);
      vT_3_io_update_old_target_offset_usePCRegion<=1'($urandom);
      vT_3_boreChildrenBd_bore_array<=7'($urandom);
      vT_3_boreChildrenBd_bore_all<=($urandom_range(0,7)==0);
      vT_3_boreChildrenBd_bore_req<=($urandom_range(0,7)==0);
      vT_3_boreChildrenBd_bore_writeen<=($urandom_range(0,7)==0);
      vT_3_boreChildrenBd_bore_be<=76'({$urandom, $urandom, $urandom});
      vT_3_boreChildrenBd_bore_addr<=8'($urandom);
      vT_3_boreChildrenBd_bore_indata<=76'({$urandom, $urandom, $urandom});
      vT_3_boreChildrenBd_bore_readen<=($urandom_range(0,7)==0);
      vT_3_boreChildrenBd_bore_addr_rd<=8'($urandom);
      vT_3_sigFromSrams_bore_ram_hold<=1'b0;
      vT_3_sigFromSrams_bore_ram_bypass<=1'b0;
      vT_3_sigFromSrams_bore_ram_bp_clken<=1'b0;
      vT_3_sigFromSrams_bore_ram_aux_clk<=1'b0;
      vT_3_sigFromSrams_bore_ram_aux_ckbp<=1'b0;
      vT_3_sigFromSrams_bore_ram_mcp_hold<=1'b0;
      vT_3_sigFromSrams_bore_cgen<=1'b0;
      vT_3_sigFromSrams_bore_1_ram_hold<=1'b0;
      vT_3_sigFromSrams_bore_1_ram_bypass<=1'b0;
      vT_3_sigFromSrams_bore_1_ram_bp_clken<=1'b0;
      vT_3_sigFromSrams_bore_1_ram_aux_clk<=1'b0;
      vT_3_sigFromSrams_bore_1_ram_aux_ckbp<=1'b0;
      vT_3_sigFromSrams_bore_1_ram_mcp_hold<=1'b0;
      vT_3_sigFromSrams_bore_1_cgen<=1'b0;
    end
  end
  always @(negedge clk) if(!rst&&cycle>WARMUP) begin #4; checks++;
    if (vT_3_g_io_req_ready!==vT_3_i_io_req_ready) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_3.io_req_ready g=%h i=%h",$time,vT_3_g_io_req_ready,vT_3_i_io_req_ready); end
    if (vT_3_g_io_resp_valid!==vT_3_i_io_resp_valid) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_3.io_resp_valid g=%h i=%h",$time,vT_3_g_io_resp_valid,vT_3_i_io_resp_valid); end
    if (vT_3_g_io_resp_bits_ctr!==vT_3_i_io_resp_bits_ctr) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_3.io_resp_bits_ctr g=%h i=%h",$time,vT_3_g_io_resp_bits_ctr,vT_3_i_io_resp_bits_ctr); end
    if (vT_3_g_io_resp_bits_u!==vT_3_i_io_resp_bits_u) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_3.io_resp_bits_u g=%h i=%h",$time,vT_3_g_io_resp_bits_u,vT_3_i_io_resp_bits_u); end
    if (vT_3_g_io_resp_bits_target_offset_offset!==vT_3_i_io_resp_bits_target_offset_offset) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_3.io_resp_bits_target_offset_offset g=%h i=%h",$time,vT_3_g_io_resp_bits_target_offset_offset,vT_3_i_io_resp_bits_target_offset_offset); end
    if (vT_3_g_io_resp_bits_target_offset_pointer!==vT_3_i_io_resp_bits_target_offset_pointer) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_3.io_resp_bits_target_offset_pointer g=%h i=%h",$time,vT_3_g_io_resp_bits_target_offset_pointer,vT_3_i_io_resp_bits_target_offset_pointer); end
    if (vT_3_g_io_resp_bits_target_offset_usePCRegion!==vT_3_i_io_resp_bits_target_offset_usePCRegion) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_3.io_resp_bits_target_offset_usePCRegion g=%h i=%h",$time,vT_3_g_io_resp_bits_target_offset_usePCRegion,vT_3_i_io_resp_bits_target_offset_usePCRegion); end
    if (vT_3_g_boreChildrenBd_bore_ack!==vT_3_i_boreChildrenBd_bore_ack) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_3.boreChildrenBd_bore_ack g=%h i=%h",$time,vT_3_g_boreChildrenBd_bore_ack,vT_3_i_boreChildrenBd_bore_ack); end
    if (vT_3_g_boreChildrenBd_bore_outdata!==vT_3_i_boreChildrenBd_bore_outdata) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_3.boreChildrenBd_bore_outdata g=%h i=%h",$time,vT_3_g_boreChildrenBd_bore_outdata,vT_3_i_boreChildrenBd_bore_outdata); end
  end
  logic vT_4_io_req_valid;
  logic [49:0] vT_4_io_req_bits_pc;
  logic [8:0] vT_4_io_req_bits_folded_hist_hist_10_folded_hist;
  logic [7:0] vT_4_io_req_bits_folded_hist_hist_3_folded_hist;
  logic [49:0] vT_4_io_update_pc;
  logic [255:0] vT_4_io_update_ghist;
  logic vT_4_io_update_valid;
  logic vT_4_io_update_correct;
  logic vT_4_io_update_alloc;
  logic [1:0] vT_4_io_update_oldCtr;
  logic vT_4_io_update_uValid;
  logic vT_4_io_update_u;
  logic vT_4_io_update_reset_u;
  logic [19:0] vT_4_io_update_target_offset_offset;
  logic [3:0] vT_4_io_update_target_offset_pointer;
  logic vT_4_io_update_target_offset_usePCRegion;
  logic [19:0] vT_4_io_update_old_target_offset_offset;
  logic [3:0] vT_4_io_update_old_target_offset_pointer;
  logic vT_4_io_update_old_target_offset_usePCRegion;
  logic [6:0] vT_4_boreChildrenBd_bore_array;
  logic vT_4_boreChildrenBd_bore_all;
  logic vT_4_boreChildrenBd_bore_req;
  logic vT_4_boreChildrenBd_bore_writeen;
  logic [75:0] vT_4_boreChildrenBd_bore_be;
  logic [7:0] vT_4_boreChildrenBd_bore_addr;
  logic [75:0] vT_4_boreChildrenBd_bore_indata;
  logic vT_4_boreChildrenBd_bore_readen;
  logic [7:0] vT_4_boreChildrenBd_bore_addr_rd;
  logic vT_4_sigFromSrams_bore_ram_hold;
  logic vT_4_sigFromSrams_bore_ram_bypass;
  logic vT_4_sigFromSrams_bore_ram_bp_clken;
  logic vT_4_sigFromSrams_bore_ram_aux_clk;
  logic vT_4_sigFromSrams_bore_ram_aux_ckbp;
  logic vT_4_sigFromSrams_bore_ram_mcp_hold;
  logic vT_4_sigFromSrams_bore_cgen;
  logic vT_4_sigFromSrams_bore_1_ram_hold;
  logic vT_4_sigFromSrams_bore_1_ram_bypass;
  logic vT_4_sigFromSrams_bore_1_ram_bp_clken;
  logic vT_4_sigFromSrams_bore_1_ram_aux_clk;
  logic vT_4_sigFromSrams_bore_1_ram_aux_ckbp;
  logic vT_4_sigFromSrams_bore_1_ram_mcp_hold;
  logic vT_4_sigFromSrams_bore_1_cgen;
  wire vT_4_g_io_req_ready; wire vT_4_i_io_req_ready;
  wire vT_4_g_io_resp_valid; wire vT_4_i_io_resp_valid;
  wire [1:0] vT_4_g_io_resp_bits_ctr; wire [1:0] vT_4_i_io_resp_bits_ctr;
  wire vT_4_g_io_resp_bits_u; wire vT_4_i_io_resp_bits_u;
  wire [19:0] vT_4_g_io_resp_bits_target_offset_offset; wire [19:0] vT_4_i_io_resp_bits_target_offset_offset;
  wire [3:0] vT_4_g_io_resp_bits_target_offset_pointer; wire [3:0] vT_4_i_io_resp_bits_target_offset_pointer;
  wire vT_4_g_io_resp_bits_target_offset_usePCRegion; wire vT_4_i_io_resp_bits_target_offset_usePCRegion;
  wire vT_4_g_boreChildrenBd_bore_ack; wire vT_4_i_boreChildrenBd_bore_ack;
  wire [75:0] vT_4_g_boreChildrenBd_bore_outdata; wire [75:0] vT_4_i_boreChildrenBd_bore_outdata;
  ITTageTable_4    u_g_ITTageTable_4(.clock(clk), .reset(rst), .io_req_valid(vT_4_io_req_valid), .io_req_bits_pc(vT_4_io_req_bits_pc), .io_req_bits_folded_hist_hist_10_folded_hist(vT_4_io_req_bits_folded_hist_hist_10_folded_hist), .io_req_bits_folded_hist_hist_3_folded_hist(vT_4_io_req_bits_folded_hist_hist_3_folded_hist), .io_update_pc(vT_4_io_update_pc), .io_update_ghist(vT_4_io_update_ghist), .io_update_valid(vT_4_io_update_valid), .io_update_correct(vT_4_io_update_correct), .io_update_alloc(vT_4_io_update_alloc), .io_update_oldCtr(vT_4_io_update_oldCtr), .io_update_uValid(vT_4_io_update_uValid), .io_update_u(vT_4_io_update_u), .io_update_reset_u(vT_4_io_update_reset_u), .io_update_target_offset_offset(vT_4_io_update_target_offset_offset), .io_update_target_offset_pointer(vT_4_io_update_target_offset_pointer), .io_update_target_offset_usePCRegion(vT_4_io_update_target_offset_usePCRegion), .io_update_old_target_offset_offset(vT_4_io_update_old_target_offset_offset), .io_update_old_target_offset_pointer(vT_4_io_update_old_target_offset_pointer), .io_update_old_target_offset_usePCRegion(vT_4_io_update_old_target_offset_usePCRegion), .boreChildrenBd_bore_array(vT_4_boreChildrenBd_bore_array), .boreChildrenBd_bore_all(vT_4_boreChildrenBd_bore_all), .boreChildrenBd_bore_req(vT_4_boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(vT_4_boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(vT_4_boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(vT_4_boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(vT_4_boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(vT_4_boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(vT_4_boreChildrenBd_bore_addr_rd), .sigFromSrams_bore_ram_hold(vT_4_sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(vT_4_sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(vT_4_sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(vT_4_sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(vT_4_sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(vT_4_sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(vT_4_sigFromSrams_bore_cgen), .sigFromSrams_bore_1_ram_hold(vT_4_sigFromSrams_bore_1_ram_hold), .sigFromSrams_bore_1_ram_bypass(vT_4_sigFromSrams_bore_1_ram_bypass), .sigFromSrams_bore_1_ram_bp_clken(vT_4_sigFromSrams_bore_1_ram_bp_clken), .sigFromSrams_bore_1_ram_aux_clk(vT_4_sigFromSrams_bore_1_ram_aux_clk), .sigFromSrams_bore_1_ram_aux_ckbp(vT_4_sigFromSrams_bore_1_ram_aux_ckbp), .sigFromSrams_bore_1_ram_mcp_hold(vT_4_sigFromSrams_bore_1_ram_mcp_hold), .sigFromSrams_bore_1_cgen(vT_4_sigFromSrams_bore_1_cgen), .io_req_ready(vT_4_g_io_req_ready), .io_resp_valid(vT_4_g_io_resp_valid), .io_resp_bits_ctr(vT_4_g_io_resp_bits_ctr), .io_resp_bits_u(vT_4_g_io_resp_bits_u), .io_resp_bits_target_offset_offset(vT_4_g_io_resp_bits_target_offset_offset), .io_resp_bits_target_offset_pointer(vT_4_g_io_resp_bits_target_offset_pointer), .io_resp_bits_target_offset_usePCRegion(vT_4_g_io_resp_bits_target_offset_usePCRegion), .boreChildrenBd_bore_ack(vT_4_g_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(vT_4_g_boreChildrenBd_bore_outdata));
  ITTageTable_4_xs u_i_ITTageTable_4(.clock(clk), .reset(rst), .io_req_valid(vT_4_io_req_valid), .io_req_bits_pc(vT_4_io_req_bits_pc), .io_req_bits_folded_hist_hist_10_folded_hist(vT_4_io_req_bits_folded_hist_hist_10_folded_hist), .io_req_bits_folded_hist_hist_3_folded_hist(vT_4_io_req_bits_folded_hist_hist_3_folded_hist), .io_update_pc(vT_4_io_update_pc), .io_update_ghist(vT_4_io_update_ghist), .io_update_valid(vT_4_io_update_valid), .io_update_correct(vT_4_io_update_correct), .io_update_alloc(vT_4_io_update_alloc), .io_update_oldCtr(vT_4_io_update_oldCtr), .io_update_uValid(vT_4_io_update_uValid), .io_update_u(vT_4_io_update_u), .io_update_reset_u(vT_4_io_update_reset_u), .io_update_target_offset_offset(vT_4_io_update_target_offset_offset), .io_update_target_offset_pointer(vT_4_io_update_target_offset_pointer), .io_update_target_offset_usePCRegion(vT_4_io_update_target_offset_usePCRegion), .io_update_old_target_offset_offset(vT_4_io_update_old_target_offset_offset), .io_update_old_target_offset_pointer(vT_4_io_update_old_target_offset_pointer), .io_update_old_target_offset_usePCRegion(vT_4_io_update_old_target_offset_usePCRegion), .boreChildrenBd_bore_array(vT_4_boreChildrenBd_bore_array), .boreChildrenBd_bore_all(vT_4_boreChildrenBd_bore_all), .boreChildrenBd_bore_req(vT_4_boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(vT_4_boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(vT_4_boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(vT_4_boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(vT_4_boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(vT_4_boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(vT_4_boreChildrenBd_bore_addr_rd), .sigFromSrams_bore_ram_hold(vT_4_sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(vT_4_sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(vT_4_sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(vT_4_sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(vT_4_sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(vT_4_sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(vT_4_sigFromSrams_bore_cgen), .sigFromSrams_bore_1_ram_hold(vT_4_sigFromSrams_bore_1_ram_hold), .sigFromSrams_bore_1_ram_bypass(vT_4_sigFromSrams_bore_1_ram_bypass), .sigFromSrams_bore_1_ram_bp_clken(vT_4_sigFromSrams_bore_1_ram_bp_clken), .sigFromSrams_bore_1_ram_aux_clk(vT_4_sigFromSrams_bore_1_ram_aux_clk), .sigFromSrams_bore_1_ram_aux_ckbp(vT_4_sigFromSrams_bore_1_ram_aux_ckbp), .sigFromSrams_bore_1_ram_mcp_hold(vT_4_sigFromSrams_bore_1_ram_mcp_hold), .sigFromSrams_bore_1_cgen(vT_4_sigFromSrams_bore_1_cgen), .io_req_ready(vT_4_i_io_req_ready), .io_resp_valid(vT_4_i_io_resp_valid), .io_resp_bits_ctr(vT_4_i_io_resp_bits_ctr), .io_resp_bits_u(vT_4_i_io_resp_bits_u), .io_resp_bits_target_offset_offset(vT_4_i_io_resp_bits_target_offset_offset), .io_resp_bits_target_offset_pointer(vT_4_i_io_resp_bits_target_offset_pointer), .io_resp_bits_target_offset_usePCRegion(vT_4_i_io_resp_bits_target_offset_usePCRegion), .boreChildrenBd_bore_ack(vT_4_i_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(vT_4_i_boreChildrenBd_bore_outdata));
  always @(negedge clk) begin
    if (rst) begin
      vT_4_io_req_valid<=1'b0;
      vT_4_io_update_valid<=1'b0;
      vT_4_io_update_reset_u<=1'b0;
      vT_4_boreChildrenBd_bore_all<=1'b0;
      vT_4_boreChildrenBd_bore_req<=1'b0;
      vT_4_boreChildrenBd_bore_writeen<=1'b0;
      vT_4_boreChildrenBd_bore_readen<=1'b0;
    end else begin
      vT_4_io_req_valid<=($urandom_range(0,3)!=0);
      vT_4_io_req_bits_pc<=50'({$urandom, $urandom});
      vT_4_io_req_bits_folded_hist_hist_10_folded_hist<=9'($urandom);
      vT_4_io_req_bits_folded_hist_hist_3_folded_hist<=8'($urandom);
      vT_4_io_update_pc<=50'({$urandom, $urandom});
      vT_4_io_update_ghist<=256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      vT_4_io_update_valid<=($urandom_range(0,2)==0);
      vT_4_io_update_correct<=1'($urandom);
      vT_4_io_update_alloc<=1'($urandom);
      vT_4_io_update_oldCtr<=2'($urandom);
      vT_4_io_update_uValid<=1'($urandom);
      vT_4_io_update_u<=1'($urandom);
      vT_4_io_update_reset_u<=($urandom_range(0,63)==0);
      vT_4_io_update_target_offset_offset<=20'($urandom);
      vT_4_io_update_target_offset_pointer<=4'($urandom);
      vT_4_io_update_target_offset_usePCRegion<=1'($urandom);
      vT_4_io_update_old_target_offset_offset<=20'($urandom);
      vT_4_io_update_old_target_offset_pointer<=4'($urandom);
      vT_4_io_update_old_target_offset_usePCRegion<=1'($urandom);
      vT_4_boreChildrenBd_bore_array<=7'($urandom);
      vT_4_boreChildrenBd_bore_all<=($urandom_range(0,7)==0);
      vT_4_boreChildrenBd_bore_req<=($urandom_range(0,7)==0);
      vT_4_boreChildrenBd_bore_writeen<=($urandom_range(0,7)==0);
      vT_4_boreChildrenBd_bore_be<=76'({$urandom, $urandom, $urandom});
      vT_4_boreChildrenBd_bore_addr<=8'($urandom);
      vT_4_boreChildrenBd_bore_indata<=76'({$urandom, $urandom, $urandom});
      vT_4_boreChildrenBd_bore_readen<=($urandom_range(0,7)==0);
      vT_4_boreChildrenBd_bore_addr_rd<=8'($urandom);
      vT_4_sigFromSrams_bore_ram_hold<=1'b0;
      vT_4_sigFromSrams_bore_ram_bypass<=1'b0;
      vT_4_sigFromSrams_bore_ram_bp_clken<=1'b0;
      vT_4_sigFromSrams_bore_ram_aux_clk<=1'b0;
      vT_4_sigFromSrams_bore_ram_aux_ckbp<=1'b0;
      vT_4_sigFromSrams_bore_ram_mcp_hold<=1'b0;
      vT_4_sigFromSrams_bore_cgen<=1'b0;
      vT_4_sigFromSrams_bore_1_ram_hold<=1'b0;
      vT_4_sigFromSrams_bore_1_ram_bypass<=1'b0;
      vT_4_sigFromSrams_bore_1_ram_bp_clken<=1'b0;
      vT_4_sigFromSrams_bore_1_ram_aux_clk<=1'b0;
      vT_4_sigFromSrams_bore_1_ram_aux_ckbp<=1'b0;
      vT_4_sigFromSrams_bore_1_ram_mcp_hold<=1'b0;
      vT_4_sigFromSrams_bore_1_cgen<=1'b0;
    end
  end
  always @(negedge clk) if(!rst&&cycle>WARMUP) begin #4; checks++;
    if (vT_4_g_io_req_ready!==vT_4_i_io_req_ready) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_4.io_req_ready g=%h i=%h",$time,vT_4_g_io_req_ready,vT_4_i_io_req_ready); end
    if (vT_4_g_io_resp_valid!==vT_4_i_io_resp_valid) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_4.io_resp_valid g=%h i=%h",$time,vT_4_g_io_resp_valid,vT_4_i_io_resp_valid); end
    if (vT_4_g_io_resp_bits_ctr!==vT_4_i_io_resp_bits_ctr) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_4.io_resp_bits_ctr g=%h i=%h",$time,vT_4_g_io_resp_bits_ctr,vT_4_i_io_resp_bits_ctr); end
    if (vT_4_g_io_resp_bits_u!==vT_4_i_io_resp_bits_u) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_4.io_resp_bits_u g=%h i=%h",$time,vT_4_g_io_resp_bits_u,vT_4_i_io_resp_bits_u); end
    if (vT_4_g_io_resp_bits_target_offset_offset!==vT_4_i_io_resp_bits_target_offset_offset) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_4.io_resp_bits_target_offset_offset g=%h i=%h",$time,vT_4_g_io_resp_bits_target_offset_offset,vT_4_i_io_resp_bits_target_offset_offset); end
    if (vT_4_g_io_resp_bits_target_offset_pointer!==vT_4_i_io_resp_bits_target_offset_pointer) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_4.io_resp_bits_target_offset_pointer g=%h i=%h",$time,vT_4_g_io_resp_bits_target_offset_pointer,vT_4_i_io_resp_bits_target_offset_pointer); end
    if (vT_4_g_io_resp_bits_target_offset_usePCRegion!==vT_4_i_io_resp_bits_target_offset_usePCRegion) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_4.io_resp_bits_target_offset_usePCRegion g=%h i=%h",$time,vT_4_g_io_resp_bits_target_offset_usePCRegion,vT_4_i_io_resp_bits_target_offset_usePCRegion); end
    if (vT_4_g_boreChildrenBd_bore_ack!==vT_4_i_boreChildrenBd_bore_ack) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_4.boreChildrenBd_bore_ack g=%h i=%h",$time,vT_4_g_boreChildrenBd_bore_ack,vT_4_i_boreChildrenBd_bore_ack); end
    if (vT_4_g_boreChildrenBd_bore_outdata!==vT_4_i_boreChildrenBd_bore_outdata) begin errors++; if(errors<=40) $display("[%0t] ITTageTable_4.boreChildrenBd_bore_outdata g=%h i=%h",$time,vT_4_g_boreChildrenBd_bore_outdata,vT_4_i_boreChildrenBd_bore_outdata); end
  end
  initial begin
    if(!$value$plusargs("ncycles=%d",NCYCLES)) NCYCLES=40000;
    rst=1; repeat(5)@(posedge clk); rst=0; repeat(NCYCLES)@(posedge clk);
    $display("checks=%0d errors=%0d",checks,errors);
    if(errors==0&&checks>1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish; end
endmodule