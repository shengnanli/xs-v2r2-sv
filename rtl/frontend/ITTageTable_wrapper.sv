// 自动生成：scripts/gen_ittagetable_wrappers.py —— 例化 xs_ITTageTable_core + 变体专属黑盒
module ITTageTable(
  input clock,
  input reset,
  output io_req_ready,
  input io_req_valid,
  input [49:0] io_req_bits_pc,
  input [3:0] io_req_bits_folded_hist_hist_12_folded_hist,
  output io_resp_valid,
  output [1:0] io_resp_bits_ctr,
  output io_resp_bits_u,
  output [19:0] io_resp_bits_target_offset_offset,
  output [3:0] io_resp_bits_target_offset_pointer,
  output io_resp_bits_target_offset_usePCRegion,
  input [49:0] io_update_pc,
  input [255:0] io_update_ghist,
  input io_update_valid,
  input io_update_correct,
  input io_update_alloc,
  input [1:0] io_update_oldCtr,
  input io_update_uValid,
  input io_update_u,
  input io_update_reset_u,
  input [19:0] io_update_target_offset_offset,
  input [3:0] io_update_target_offset_pointer,
  input io_update_target_offset_usePCRegion,
  input [19:0] io_update_old_target_offset_offset,
  input [3:0] io_update_old_target_offset_pointer,
  input io_update_old_target_offset_usePCRegion,
  input [6:0] boreChildrenBd_bore_array,
  input boreChildrenBd_bore_all,
  input boreChildrenBd_bore_req,
  output boreChildrenBd_bore_ack,
  input boreChildrenBd_bore_writeen,
  input [75:0] boreChildrenBd_bore_be,
  input [7:0] boreChildrenBd_bore_addr,
  input [75:0] boreChildrenBd_bore_indata,
  input boreChildrenBd_bore_readen,
  input [7:0] boreChildrenBd_bore_addr_rd,
  output [75:0] boreChildrenBd_bore_outdata,
  input sigFromSrams_bore_ram_hold,
  input sigFromSrams_bore_ram_bypass,
  input sigFromSrams_bore_ram_bp_clken,
  input sigFromSrams_bore_ram_aux_clk,
  input sigFromSrams_bore_ram_aux_ckbp,
  input sigFromSrams_bore_ram_mcp_hold,
  input sigFromSrams_bore_cgen
);
  // ===== 核 <-> 条目 SRAM 读/写口 中间线 =====
  wire                sram_r_req_valid;
  wire [7:0]    sram_r_req_setIdx;
  wire                sram_r_req_ready;
  wire                sram_r_resp_valid;
  wire [8:0]          sram_r_resp_tag;
  wire [1:0]          sram_r_resp_ctr;
  wire [19:0]         sram_r_resp_off;
  wire [3:0]          sram_r_resp_ptr;
  wire                sram_r_resp_upr;
  wire                sram_r_resp_useful;
  wire                sram_w_req_valid;
  wire [7:0]    sram_w_req_setIdx;
  wire [8:0]          sram_w_req_tag;
  wire [1:0]          sram_w_req_ctr;
  wire [19:0]         sram_w_req_off;
  wire [3:0]          sram_w_req_ptr;
  wire                sram_w_req_upr;
  wire                sram_w_req_useful;
  wire [37:0]         sram_w_req_bitmask;
  // ===== 核 <-> WrBypass 中间线 =====
  wire                wrbp_wen;
  wire [7:0]    wrbp_write_idx;
  wire [1:0]          wrbp_write_data;
  wire                wrbp_hit;
  wire [1:0]          wrbp_hit_data;
  // ===== MbistPipe <-> SRAM bore 口 中间线 =====
  wire [7:0]  childBd0_addr, childBd0_addr_rd;
  wire [75:0] childBd0_wdata, childBd0_wmask, childBd0_rdata;
  wire        childBd0_re, childBd0_we, childBd0_ack, childBd0_sel;
  wire [6:0]  childBd0_array;
  // ===== 可读功能核 =====
  xs_ITTageTable_core #(
    .IDX_W(8), .IDX_FH_W(4), .TAG_FH_W(4), .ALT_FH_W(4),
    .IDX_HIST_LEN(4), .TAG_HIST_LEN(4), .ALT_HIST_LEN(4)
  ) u_core (
    .clock(clock), .reset(reset),
    .io_req_ready(io_req_ready), .io_req_valid(io_req_valid),
    .io_req_bits_pc(io_req_bits_pc),
    .io_req_idx_fh(io_req_bits_folded_hist_hist_12_folded_hist), .io_req_tag_fh(io_req_bits_folded_hist_hist_12_folded_hist), .io_req_alt_fh(io_req_bits_folded_hist_hist_12_folded_hist),
    .io_resp_valid(io_resp_valid), .io_resp_bits_ctr(io_resp_bits_ctr),
    .io_resp_bits_u(io_resp_bits_u),
    .io_resp_bits_target_offset_offset(io_resp_bits_target_offset_offset),
    .io_resp_bits_target_offset_pointer(io_resp_bits_target_offset_pointer),
    .io_resp_bits_target_offset_usePCRegion(io_resp_bits_target_offset_usePCRegion),
    .io_update_pc(io_update_pc), .io_update_ghist(io_update_ghist),
    .io_update_valid(io_update_valid), .io_update_correct(io_update_correct),
    .io_update_alloc(io_update_alloc), .io_update_oldCtr(io_update_oldCtr),
    .io_update_uValid(io_update_uValid), .io_update_u(io_update_u),
    .io_update_reset_u(io_update_reset_u),
    .io_update_target_offset_offset(io_update_target_offset_offset),
    .io_update_target_offset_pointer(io_update_target_offset_pointer),
    .io_update_target_offset_usePCRegion(io_update_target_offset_usePCRegion),
    .io_update_old_target_offset_offset(io_update_old_target_offset_offset),
    .io_update_old_target_offset_pointer(io_update_old_target_offset_pointer),
    .io_update_old_target_offset_usePCRegion(io_update_old_target_offset_usePCRegion),
    .sram_r_req_valid(sram_r_req_valid), .sram_r_req_setIdx(sram_r_req_setIdx),
    .sram_r_req_ready(sram_r_req_ready), .sram_r_resp_valid(sram_r_resp_valid),
    .sram_r_resp_tag(sram_r_resp_tag), .sram_r_resp_ctr(sram_r_resp_ctr),
    .sram_r_resp_target_offset_offset(sram_r_resp_off),
    .sram_r_resp_target_offset_pointer(sram_r_resp_ptr),
    .sram_r_resp_target_offset_usePCRegion(sram_r_resp_upr),
    .sram_r_resp_useful(sram_r_resp_useful),
    .sram_w_req_valid(sram_w_req_valid), .sram_w_req_setIdx(sram_w_req_setIdx),
    .sram_w_req_tag(sram_w_req_tag), .sram_w_req_ctr(sram_w_req_ctr),
    .sram_w_req_target_offset_offset(sram_w_req_off),
    .sram_w_req_target_offset_pointer(sram_w_req_ptr),
    .sram_w_req_target_offset_usePCRegion(sram_w_req_upr),
    .sram_w_req_useful(sram_w_req_useful), .sram_w_req_bitmask(sram_w_req_bitmask),
    .wrbp_wen(wrbp_wen), .wrbp_write_idx(wrbp_write_idx),
    .wrbp_write_data(wrbp_write_data),
    .wrbp_hit(wrbp_hit), .wrbp_hit_data(wrbp_hit_data)
  );
  // ===== 条目 SRAM（已验证黑盒）=====
  FoldedSRAMTemplate_21 table_0 (
    .clock(clock), .reset(reset),
    .io_r_req_ready(sram_r_req_ready), .io_r_req_valid(sram_r_req_valid),
    .io_r_req_bits_setIdx(sram_r_req_setIdx),
    .io_r_resp_data_0_valid(sram_r_resp_valid),
    .io_r_resp_data_0_tag(sram_r_resp_tag),
    .io_r_resp_data_0_ctr(sram_r_resp_ctr),
    .io_r_resp_data_0_target_offset_offset(sram_r_resp_off),
    .io_r_resp_data_0_target_offset_pointer(sram_r_resp_ptr),
    .io_r_resp_data_0_target_offset_usePCRegion(sram_r_resp_upr),
    .io_r_resp_data_0_useful(sram_r_resp_useful),
    .io_w_req_valid(sram_w_req_valid), .io_w_req_bits_setIdx(sram_w_req_setIdx),
    .io_w_req_bits_data_0_tag(sram_w_req_tag),
    .io_w_req_bits_data_0_ctr(sram_w_req_ctr),
    .io_w_req_bits_data_0_target_offset_offset(sram_w_req_off),
    .io_w_req_bits_data_0_target_offset_pointer(sram_w_req_ptr),
    .io_w_req_bits_data_0_target_offset_usePCRegion(sram_w_req_upr),
    .io_w_req_bits_data_0_useful(sram_w_req_useful),
    .io_w_req_bits_bitmask(sram_w_req_bitmask),
    .boreChildrenBd_bore_addr(childBd0_addr),
    .boreChildrenBd_bore_addr_rd(childBd0_addr_rd),
    .boreChildrenBd_bore_wdata(childBd0_wdata),
    .boreChildrenBd_bore_wmask(childBd0_wmask),
    .boreChildrenBd_bore_re(childBd0_re), .boreChildrenBd_bore_we(childBd0_we),
    .boreChildrenBd_bore_rdata(childBd0_rdata),
    .boreChildrenBd_bore_ack(childBd0_ack),
    .boreChildrenBd_bore_selectedOH(childBd0_sel),
    .boreChildrenBd_bore_array(childBd0_array),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen)
  );
  // ===== WrBypass（已验证黑盒）=====
  WrBypass_41 wrbypass (
    .clock(clock), .reset(reset),
    .io_wen(wrbp_wen), .io_write_idx(wrbp_write_idx),
    .io_write_data_0(wrbp_write_data),
    .io_hit(wrbp_hit), .io_hit_data_0_bits(wrbp_hit_data)
  );
  // ===== MBIST 流水寄存（可读核；上游 mbist 总线 -> SRAM bore 口）=====
  wire [7:0]  ms_addr   [1], ms_addr_rd [1];
  wire [75:0] ms_wdata  [1], ms_wmask   [1], ms_rdata [1];
  wire        ms_re     [1], ms_we      [1], ms_ack [1], ms_sel [1];
  wire [6:0]  ms_array  [1];
  assign childBd0_addr=ms_addr[0];       assign childBd0_addr_rd=ms_addr_rd[0];
  assign childBd0_wdata=ms_wdata[0];     assign childBd0_wmask=ms_wmask[0];
  assign childBd0_re=ms_re[0];           assign childBd0_we=ms_we[0];
  assign childBd0_ack=ms_ack[0];         assign childBd0_sel=ms_sel[0];
  assign childBd0_array=ms_array[0];     assign ms_rdata[0]=childBd0_rdata;
  xs_MbistPipeIttage_core #(.N_SRAM(1), .ARRAY_ID0(7'h46), .ADDR_W(8), .DATA_W(76)) mbistPl (
    .clock(clock), .reset(reset),
    .mbist_array(boreChildrenBd_bore_array), .mbist_all(boreChildrenBd_bore_all),
    .mbist_req(boreChildrenBd_bore_req), .mbist_ack(boreChildrenBd_bore_ack),
    .mbist_writeen(boreChildrenBd_bore_writeen), .mbist_be(boreChildrenBd_bore_be),
    .mbist_addr(boreChildrenBd_bore_addr), .mbist_indata(boreChildrenBd_bore_indata),
    .mbist_readen(boreChildrenBd_bore_readen), .mbist_addr_rd(boreChildrenBd_bore_addr_rd),
    .mbist_outdata(boreChildrenBd_bore_outdata),
    .toSRAM_addr(ms_addr), .toSRAM_addr_rd(ms_addr_rd),
    .toSRAM_wdata(ms_wdata), .toSRAM_wmask(ms_wmask),
    .toSRAM_re(ms_re), .toSRAM_we(ms_we), .toSRAM_rdata(ms_rdata),
    .toSRAM_ack(ms_ack), .toSRAM_selectedOH(ms_sel), .toSRAM_array(ms_array)
  );
endmodule

module ITTageTable_1(
  input clock,
  input reset,
  output io_req_ready,
  input io_req_valid,
  input [49:0] io_req_bits_pc,
  input [7:0] io_req_bits_folded_hist_hist_14_folded_hist,
  output io_resp_valid,
  output [1:0] io_resp_bits_ctr,
  output io_resp_bits_u,
  output [19:0] io_resp_bits_target_offset_offset,
  output [3:0] io_resp_bits_target_offset_pointer,
  output io_resp_bits_target_offset_usePCRegion,
  input [49:0] io_update_pc,
  input [255:0] io_update_ghist,
  input io_update_valid,
  input io_update_correct,
  input io_update_alloc,
  input [1:0] io_update_oldCtr,
  input io_update_uValid,
  input io_update_u,
  input io_update_reset_u,
  input [19:0] io_update_target_offset_offset,
  input [3:0] io_update_target_offset_pointer,
  input io_update_target_offset_usePCRegion,
  input [19:0] io_update_old_target_offset_offset,
  input [3:0] io_update_old_target_offset_pointer,
  input io_update_old_target_offset_usePCRegion,
  input [6:0] boreChildrenBd_bore_array,
  input boreChildrenBd_bore_all,
  input boreChildrenBd_bore_req,
  output boreChildrenBd_bore_ack,
  input boreChildrenBd_bore_writeen,
  input [75:0] boreChildrenBd_bore_be,
  input [7:0] boreChildrenBd_bore_addr,
  input [75:0] boreChildrenBd_bore_indata,
  input boreChildrenBd_bore_readen,
  input [7:0] boreChildrenBd_bore_addr_rd,
  output [75:0] boreChildrenBd_bore_outdata,
  input sigFromSrams_bore_ram_hold,
  input sigFromSrams_bore_ram_bypass,
  input sigFromSrams_bore_ram_bp_clken,
  input sigFromSrams_bore_ram_aux_clk,
  input sigFromSrams_bore_ram_aux_ckbp,
  input sigFromSrams_bore_ram_mcp_hold,
  input sigFromSrams_bore_cgen
);
  // ===== 核 <-> 条目 SRAM 读/写口 中间线 =====
  wire                sram_r_req_valid;
  wire [7:0]    sram_r_req_setIdx;
  wire                sram_r_req_ready;
  wire                sram_r_resp_valid;
  wire [8:0]          sram_r_resp_tag;
  wire [1:0]          sram_r_resp_ctr;
  wire [19:0]         sram_r_resp_off;
  wire [3:0]          sram_r_resp_ptr;
  wire                sram_r_resp_upr;
  wire                sram_r_resp_useful;
  wire                sram_w_req_valid;
  wire [7:0]    sram_w_req_setIdx;
  wire [8:0]          sram_w_req_tag;
  wire [1:0]          sram_w_req_ctr;
  wire [19:0]         sram_w_req_off;
  wire [3:0]          sram_w_req_ptr;
  wire                sram_w_req_upr;
  wire                sram_w_req_useful;
  wire [37:0]         sram_w_req_bitmask;
  // ===== 核 <-> WrBypass 中间线 =====
  wire                wrbp_wen;
  wire [7:0]    wrbp_write_idx;
  wire [1:0]          wrbp_write_data;
  wire                wrbp_hit;
  wire [1:0]          wrbp_hit_data;
  // ===== MbistPipe <-> SRAM bore 口 中间线 =====
  wire [7:0]  childBd0_addr, childBd0_addr_rd;
  wire [75:0] childBd0_wdata, childBd0_wmask, childBd0_rdata;
  wire        childBd0_re, childBd0_we, childBd0_ack, childBd0_sel;
  wire [6:0]  childBd0_array;
  // ===== 可读功能核 =====
  xs_ITTageTable_core #(
    .IDX_W(8), .IDX_FH_W(8), .TAG_FH_W(8), .ALT_FH_W(8),
    .IDX_HIST_LEN(8), .TAG_HIST_LEN(8), .ALT_HIST_LEN(8)
  ) u_core (
    .clock(clock), .reset(reset),
    .io_req_ready(io_req_ready), .io_req_valid(io_req_valid),
    .io_req_bits_pc(io_req_bits_pc),
    .io_req_idx_fh(io_req_bits_folded_hist_hist_14_folded_hist), .io_req_tag_fh(io_req_bits_folded_hist_hist_14_folded_hist), .io_req_alt_fh(io_req_bits_folded_hist_hist_14_folded_hist),
    .io_resp_valid(io_resp_valid), .io_resp_bits_ctr(io_resp_bits_ctr),
    .io_resp_bits_u(io_resp_bits_u),
    .io_resp_bits_target_offset_offset(io_resp_bits_target_offset_offset),
    .io_resp_bits_target_offset_pointer(io_resp_bits_target_offset_pointer),
    .io_resp_bits_target_offset_usePCRegion(io_resp_bits_target_offset_usePCRegion),
    .io_update_pc(io_update_pc), .io_update_ghist(io_update_ghist),
    .io_update_valid(io_update_valid), .io_update_correct(io_update_correct),
    .io_update_alloc(io_update_alloc), .io_update_oldCtr(io_update_oldCtr),
    .io_update_uValid(io_update_uValid), .io_update_u(io_update_u),
    .io_update_reset_u(io_update_reset_u),
    .io_update_target_offset_offset(io_update_target_offset_offset),
    .io_update_target_offset_pointer(io_update_target_offset_pointer),
    .io_update_target_offset_usePCRegion(io_update_target_offset_usePCRegion),
    .io_update_old_target_offset_offset(io_update_old_target_offset_offset),
    .io_update_old_target_offset_pointer(io_update_old_target_offset_pointer),
    .io_update_old_target_offset_usePCRegion(io_update_old_target_offset_usePCRegion),
    .sram_r_req_valid(sram_r_req_valid), .sram_r_req_setIdx(sram_r_req_setIdx),
    .sram_r_req_ready(sram_r_req_ready), .sram_r_resp_valid(sram_r_resp_valid),
    .sram_r_resp_tag(sram_r_resp_tag), .sram_r_resp_ctr(sram_r_resp_ctr),
    .sram_r_resp_target_offset_offset(sram_r_resp_off),
    .sram_r_resp_target_offset_pointer(sram_r_resp_ptr),
    .sram_r_resp_target_offset_usePCRegion(sram_r_resp_upr),
    .sram_r_resp_useful(sram_r_resp_useful),
    .sram_w_req_valid(sram_w_req_valid), .sram_w_req_setIdx(sram_w_req_setIdx),
    .sram_w_req_tag(sram_w_req_tag), .sram_w_req_ctr(sram_w_req_ctr),
    .sram_w_req_target_offset_offset(sram_w_req_off),
    .sram_w_req_target_offset_pointer(sram_w_req_ptr),
    .sram_w_req_target_offset_usePCRegion(sram_w_req_upr),
    .sram_w_req_useful(sram_w_req_useful), .sram_w_req_bitmask(sram_w_req_bitmask),
    .wrbp_wen(wrbp_wen), .wrbp_write_idx(wrbp_write_idx),
    .wrbp_write_data(wrbp_write_data),
    .wrbp_hit(wrbp_hit), .wrbp_hit_data(wrbp_hit_data)
  );
  // ===== 条目 SRAM（已验证黑盒）=====
  FoldedSRAMTemplate_21 table_0 (
    .clock(clock), .reset(reset),
    .io_r_req_ready(sram_r_req_ready), .io_r_req_valid(sram_r_req_valid),
    .io_r_req_bits_setIdx(sram_r_req_setIdx),
    .io_r_resp_data_0_valid(sram_r_resp_valid),
    .io_r_resp_data_0_tag(sram_r_resp_tag),
    .io_r_resp_data_0_ctr(sram_r_resp_ctr),
    .io_r_resp_data_0_target_offset_offset(sram_r_resp_off),
    .io_r_resp_data_0_target_offset_pointer(sram_r_resp_ptr),
    .io_r_resp_data_0_target_offset_usePCRegion(sram_r_resp_upr),
    .io_r_resp_data_0_useful(sram_r_resp_useful),
    .io_w_req_valid(sram_w_req_valid), .io_w_req_bits_setIdx(sram_w_req_setIdx),
    .io_w_req_bits_data_0_tag(sram_w_req_tag),
    .io_w_req_bits_data_0_ctr(sram_w_req_ctr),
    .io_w_req_bits_data_0_target_offset_offset(sram_w_req_off),
    .io_w_req_bits_data_0_target_offset_pointer(sram_w_req_ptr),
    .io_w_req_bits_data_0_target_offset_usePCRegion(sram_w_req_upr),
    .io_w_req_bits_data_0_useful(sram_w_req_useful),
    .io_w_req_bits_bitmask(sram_w_req_bitmask),
    .boreChildrenBd_bore_addr(childBd0_addr),
    .boreChildrenBd_bore_addr_rd(childBd0_addr_rd),
    .boreChildrenBd_bore_wdata(childBd0_wdata),
    .boreChildrenBd_bore_wmask(childBd0_wmask),
    .boreChildrenBd_bore_re(childBd0_re), .boreChildrenBd_bore_we(childBd0_we),
    .boreChildrenBd_bore_rdata(childBd0_rdata),
    .boreChildrenBd_bore_ack(childBd0_ack),
    .boreChildrenBd_bore_selectedOH(childBd0_sel),
    .boreChildrenBd_bore_array(childBd0_array),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen)
  );
  // ===== WrBypass（已验证黑盒）=====
  WrBypass_41 wrbypass (
    .clock(clock), .reset(reset),
    .io_wen(wrbp_wen), .io_write_idx(wrbp_write_idx),
    .io_write_data_0(wrbp_write_data),
    .io_hit(wrbp_hit), .io_hit_data_0_bits(wrbp_hit_data)
  );
  // ===== MBIST 流水寄存（可读核；上游 mbist 总线 -> SRAM bore 口）=====
  wire [7:0]  ms_addr   [1], ms_addr_rd [1];
  wire [75:0] ms_wdata  [1], ms_wmask   [1], ms_rdata [1];
  wire        ms_re     [1], ms_we      [1], ms_ack [1], ms_sel [1];
  wire [6:0]  ms_array  [1];
  assign childBd0_addr=ms_addr[0];       assign childBd0_addr_rd=ms_addr_rd[0];
  assign childBd0_wdata=ms_wdata[0];     assign childBd0_wmask=ms_wmask[0];
  assign childBd0_re=ms_re[0];           assign childBd0_we=ms_we[0];
  assign childBd0_ack=ms_ack[0];         assign childBd0_sel=ms_sel[0];
  assign childBd0_array=ms_array[0];     assign ms_rdata[0]=childBd0_rdata;
  xs_MbistPipeIttage_core #(.N_SRAM(1), .ARRAY_ID0(7'h47), .ADDR_W(8), .DATA_W(76)) mbistPl (
    .clock(clock), .reset(reset),
    .mbist_array(boreChildrenBd_bore_array), .mbist_all(boreChildrenBd_bore_all),
    .mbist_req(boreChildrenBd_bore_req), .mbist_ack(boreChildrenBd_bore_ack),
    .mbist_writeen(boreChildrenBd_bore_writeen), .mbist_be(boreChildrenBd_bore_be),
    .mbist_addr(boreChildrenBd_bore_addr), .mbist_indata(boreChildrenBd_bore_indata),
    .mbist_readen(boreChildrenBd_bore_readen), .mbist_addr_rd(boreChildrenBd_bore_addr_rd),
    .mbist_outdata(boreChildrenBd_bore_outdata),
    .toSRAM_addr(ms_addr), .toSRAM_addr_rd(ms_addr_rd),
    .toSRAM_wdata(ms_wdata), .toSRAM_wmask(ms_wmask),
    .toSRAM_re(ms_re), .toSRAM_we(ms_we), .toSRAM_rdata(ms_rdata),
    .toSRAM_ack(ms_ack), .toSRAM_selectedOH(ms_sel), .toSRAM_array(ms_array)
  );
endmodule

module ITTageTable_2(
  input clock,
  input reset,
  output io_req_ready,
  input io_req_valid,
  input [49:0] io_req_bits_pc,
  input [8:0] io_req_bits_folded_hist_hist_13_folded_hist,
  input [7:0] io_req_bits_folded_hist_hist_4_folded_hist,
  output io_resp_valid,
  output [1:0] io_resp_bits_ctr,
  output io_resp_bits_u,
  output [19:0] io_resp_bits_target_offset_offset,
  output [3:0] io_resp_bits_target_offset_pointer,
  output io_resp_bits_target_offset_usePCRegion,
  input [49:0] io_update_pc,
  input [255:0] io_update_ghist,
  input io_update_valid,
  input io_update_correct,
  input io_update_alloc,
  input [1:0] io_update_oldCtr,
  input io_update_uValid,
  input io_update_u,
  input io_update_reset_u,
  input [19:0] io_update_target_offset_offset,
  input [3:0] io_update_target_offset_pointer,
  input io_update_target_offset_usePCRegion,
  input [19:0] io_update_old_target_offset_offset,
  input [3:0] io_update_old_target_offset_pointer,
  input io_update_old_target_offset_usePCRegion,
  input [6:0] boreChildrenBd_bore_array,
  input boreChildrenBd_bore_all,
  input boreChildrenBd_bore_req,
  output boreChildrenBd_bore_ack,
  input boreChildrenBd_bore_writeen,
  input [75:0] boreChildrenBd_bore_be,
  input [7:0] boreChildrenBd_bore_addr,
  input [75:0] boreChildrenBd_bore_indata,
  input boreChildrenBd_bore_readen,
  input [7:0] boreChildrenBd_bore_addr_rd,
  output [75:0] boreChildrenBd_bore_outdata,
  input sigFromSrams_bore_ram_hold,
  input sigFromSrams_bore_ram_bypass,
  input sigFromSrams_bore_ram_bp_clken,
  input sigFromSrams_bore_ram_aux_clk,
  input sigFromSrams_bore_ram_aux_ckbp,
  input sigFromSrams_bore_ram_mcp_hold,
  input sigFromSrams_bore_cgen,
  input sigFromSrams_bore_1_ram_hold,
  input sigFromSrams_bore_1_ram_bypass,
  input sigFromSrams_bore_1_ram_bp_clken,
  input sigFromSrams_bore_1_ram_aux_clk,
  input sigFromSrams_bore_1_ram_aux_ckbp,
  input sigFromSrams_bore_1_ram_mcp_hold,
  input sigFromSrams_bore_1_cgen
);
  // ===== 核 <-> 条目 SRAM 读/写口 中间线 =====
  wire                sram_r_req_valid;
  wire [8:0]    sram_r_req_setIdx;
  wire                sram_r_req_ready;
  wire                sram_r_resp_valid;
  wire [8:0]          sram_r_resp_tag;
  wire [1:0]          sram_r_resp_ctr;
  wire [19:0]         sram_r_resp_off;
  wire [3:0]          sram_r_resp_ptr;
  wire                sram_r_resp_upr;
  wire                sram_r_resp_useful;
  wire                sram_w_req_valid;
  wire [8:0]    sram_w_req_setIdx;
  wire [8:0]          sram_w_req_tag;
  wire [1:0]          sram_w_req_ctr;
  wire [19:0]         sram_w_req_off;
  wire [3:0]          sram_w_req_ptr;
  wire                sram_w_req_upr;
  wire                sram_w_req_useful;
  wire [37:0]         sram_w_req_bitmask;
  // ===== 核 <-> WrBypass 中间线 =====
  wire                wrbp_wen;
  wire [8:0]    wrbp_write_idx;
  wire [1:0]          wrbp_write_data;
  wire                wrbp_hit;
  wire [1:0]          wrbp_hit_data;
  // ===== MbistPipe <-> SRAM bore 口 中间线 =====
  wire [7:0]  childBd0_addr, childBd0_addr_rd;
  wire [75:0] childBd0_wdata, childBd0_wmask, childBd0_rdata;
  wire        childBd0_re, childBd0_we, childBd0_ack, childBd0_sel;
  wire [6:0]  childBd0_array;
  wire [7:0]  childBd1_addr, childBd1_addr_rd;
  wire [75:0] childBd1_wdata, childBd1_wmask, childBd1_rdata;
  wire        childBd1_re, childBd1_we, childBd1_ack, childBd1_sel;
  wire [6:0]  childBd1_array;
  // ===== 可读功能核 =====
  xs_ITTageTable_core #(
    .IDX_W(9), .IDX_FH_W(9), .TAG_FH_W(9), .ALT_FH_W(8),
    .IDX_HIST_LEN(13), .TAG_HIST_LEN(13), .ALT_HIST_LEN(13)
  ) u_core (
    .clock(clock), .reset(reset),
    .io_req_ready(io_req_ready), .io_req_valid(io_req_valid),
    .io_req_bits_pc(io_req_bits_pc),
    .io_req_idx_fh(io_req_bits_folded_hist_hist_13_folded_hist), .io_req_tag_fh(io_req_bits_folded_hist_hist_13_folded_hist), .io_req_alt_fh(io_req_bits_folded_hist_hist_4_folded_hist),
    .io_resp_valid(io_resp_valid), .io_resp_bits_ctr(io_resp_bits_ctr),
    .io_resp_bits_u(io_resp_bits_u),
    .io_resp_bits_target_offset_offset(io_resp_bits_target_offset_offset),
    .io_resp_bits_target_offset_pointer(io_resp_bits_target_offset_pointer),
    .io_resp_bits_target_offset_usePCRegion(io_resp_bits_target_offset_usePCRegion),
    .io_update_pc(io_update_pc), .io_update_ghist(io_update_ghist),
    .io_update_valid(io_update_valid), .io_update_correct(io_update_correct),
    .io_update_alloc(io_update_alloc), .io_update_oldCtr(io_update_oldCtr),
    .io_update_uValid(io_update_uValid), .io_update_u(io_update_u),
    .io_update_reset_u(io_update_reset_u),
    .io_update_target_offset_offset(io_update_target_offset_offset),
    .io_update_target_offset_pointer(io_update_target_offset_pointer),
    .io_update_target_offset_usePCRegion(io_update_target_offset_usePCRegion),
    .io_update_old_target_offset_offset(io_update_old_target_offset_offset),
    .io_update_old_target_offset_pointer(io_update_old_target_offset_pointer),
    .io_update_old_target_offset_usePCRegion(io_update_old_target_offset_usePCRegion),
    .sram_r_req_valid(sram_r_req_valid), .sram_r_req_setIdx(sram_r_req_setIdx),
    .sram_r_req_ready(sram_r_req_ready), .sram_r_resp_valid(sram_r_resp_valid),
    .sram_r_resp_tag(sram_r_resp_tag), .sram_r_resp_ctr(sram_r_resp_ctr),
    .sram_r_resp_target_offset_offset(sram_r_resp_off),
    .sram_r_resp_target_offset_pointer(sram_r_resp_ptr),
    .sram_r_resp_target_offset_usePCRegion(sram_r_resp_upr),
    .sram_r_resp_useful(sram_r_resp_useful),
    .sram_w_req_valid(sram_w_req_valid), .sram_w_req_setIdx(sram_w_req_setIdx),
    .sram_w_req_tag(sram_w_req_tag), .sram_w_req_ctr(sram_w_req_ctr),
    .sram_w_req_target_offset_offset(sram_w_req_off),
    .sram_w_req_target_offset_pointer(sram_w_req_ptr),
    .sram_w_req_target_offset_usePCRegion(sram_w_req_upr),
    .sram_w_req_useful(sram_w_req_useful), .sram_w_req_bitmask(sram_w_req_bitmask),
    .wrbp_wen(wrbp_wen), .wrbp_write_idx(wrbp_write_idx),
    .wrbp_write_data(wrbp_write_data),
    .wrbp_hit(wrbp_hit), .wrbp_hit_data(wrbp_hit_data)
  );
  // ===== 条目 SRAM（已验证黑盒）=====
  FoldedSRAMTemplate_23 table_0 (
    .clock(clock), .reset(reset),
    .io_r_req_ready(sram_r_req_ready), .io_r_req_valid(sram_r_req_valid),
    .io_r_req_bits_setIdx(sram_r_req_setIdx),
    .io_r_resp_data_0_valid(sram_r_resp_valid),
    .io_r_resp_data_0_tag(sram_r_resp_tag),
    .io_r_resp_data_0_ctr(sram_r_resp_ctr),
    .io_r_resp_data_0_target_offset_offset(sram_r_resp_off),
    .io_r_resp_data_0_target_offset_pointer(sram_r_resp_ptr),
    .io_r_resp_data_0_target_offset_usePCRegion(sram_r_resp_upr),
    .io_r_resp_data_0_useful(sram_r_resp_useful),
    .io_w_req_valid(sram_w_req_valid), .io_w_req_bits_setIdx(sram_w_req_setIdx),
    .io_w_req_bits_data_0_tag(sram_w_req_tag),
    .io_w_req_bits_data_0_ctr(sram_w_req_ctr),
    .io_w_req_bits_data_0_target_offset_offset(sram_w_req_off),
    .io_w_req_bits_data_0_target_offset_pointer(sram_w_req_ptr),
    .io_w_req_bits_data_0_target_offset_usePCRegion(sram_w_req_upr),
    .io_w_req_bits_data_0_useful(sram_w_req_useful),
    .io_w_req_bits_bitmask(sram_w_req_bitmask),
    .boreChildrenBd_bore_addr(childBd0_addr),
    .boreChildrenBd_bore_addr_rd(childBd0_addr_rd),
    .boreChildrenBd_bore_wdata(childBd0_wdata),
    .boreChildrenBd_bore_wmask(childBd0_wmask),
    .boreChildrenBd_bore_re(childBd0_re), .boreChildrenBd_bore_we(childBd0_we),
    .boreChildrenBd_bore_rdata(childBd0_rdata),
    .boreChildrenBd_bore_ack(childBd0_ack),
    .boreChildrenBd_bore_selectedOH(childBd0_sel),
    .boreChildrenBd_bore_array(childBd0_array),
    .boreChildrenBd_bore_1_addr(childBd1_addr),
    .boreChildrenBd_bore_1_addr_rd(childBd1_addr_rd),
    .boreChildrenBd_bore_1_wdata(childBd1_wdata),
    .boreChildrenBd_bore_1_wmask(childBd1_wmask),
    .boreChildrenBd_bore_1_re(childBd1_re), .boreChildrenBd_bore_1_we(childBd1_we),
    .boreChildrenBd_bore_1_rdata(childBd1_rdata),
    .boreChildrenBd_bore_1_ack(childBd1_ack),
    .boreChildrenBd_bore_1_selectedOH(childBd1_sel),
    .boreChildrenBd_bore_1_array(childBd1_array),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen)
  );
  // ===== WrBypass（已验证黑盒）=====
  WrBypass_43 wrbypass (
    .clock(clock), .reset(reset),
    .io_wen(wrbp_wen), .io_write_idx(wrbp_write_idx),
    .io_write_data_0(wrbp_write_data),
    .io_hit(wrbp_hit), .io_hit_data_0_bits(wrbp_hit_data)
  );
  // ===== MBIST 流水寄存（可读核；上游 mbist 总线 -> SRAM bore 口）=====
  wire [7:0]  ms_addr   [2], ms_addr_rd [2];
  wire [75:0] ms_wdata  [2], ms_wmask   [2], ms_rdata [2];
  wire        ms_re     [2], ms_we      [2], ms_ack [2], ms_sel [2];
  wire [6:0]  ms_array  [2];
  assign childBd0_addr=ms_addr[0];       assign childBd0_addr_rd=ms_addr_rd[0];
  assign childBd0_wdata=ms_wdata[0];     assign childBd0_wmask=ms_wmask[0];
  assign childBd0_re=ms_re[0];           assign childBd0_we=ms_we[0];
  assign childBd0_ack=ms_ack[0];         assign childBd0_sel=ms_sel[0];
  assign childBd0_array=ms_array[0];     assign ms_rdata[0]=childBd0_rdata;
  assign childBd1_addr=ms_addr[1];       assign childBd1_addr_rd=ms_addr_rd[1];
  assign childBd1_wdata=ms_wdata[1];     assign childBd1_wmask=ms_wmask[1];
  assign childBd1_re=ms_re[1];           assign childBd1_we=ms_we[1];
  assign childBd1_ack=ms_ack[1];         assign childBd1_sel=ms_sel[1];
  assign childBd1_array=ms_array[1];     assign ms_rdata[1]=childBd1_rdata;
  xs_MbistPipeIttage_core #(.N_SRAM(2), .ARRAY_ID0(7'h48), .ADDR_W(8), .DATA_W(76)) mbistPl (
    .clock(clock), .reset(reset),
    .mbist_array(boreChildrenBd_bore_array), .mbist_all(boreChildrenBd_bore_all),
    .mbist_req(boreChildrenBd_bore_req), .mbist_ack(boreChildrenBd_bore_ack),
    .mbist_writeen(boreChildrenBd_bore_writeen), .mbist_be(boreChildrenBd_bore_be),
    .mbist_addr(boreChildrenBd_bore_addr), .mbist_indata(boreChildrenBd_bore_indata),
    .mbist_readen(boreChildrenBd_bore_readen), .mbist_addr_rd(boreChildrenBd_bore_addr_rd),
    .mbist_outdata(boreChildrenBd_bore_outdata),
    .toSRAM_addr(ms_addr), .toSRAM_addr_rd(ms_addr_rd),
    .toSRAM_wdata(ms_wdata), .toSRAM_wmask(ms_wmask),
    .toSRAM_re(ms_re), .toSRAM_we(ms_we), .toSRAM_rdata(ms_rdata),
    .toSRAM_ack(ms_ack), .toSRAM_selectedOH(ms_sel), .toSRAM_array(ms_array)
  );
endmodule

module ITTageTable_3(
  input clock,
  input reset,
  output io_req_ready,
  input io_req_valid,
  input [49:0] io_req_bits_pc,
  input [8:0] io_req_bits_folded_hist_hist_6_folded_hist,
  input [7:0] io_req_bits_folded_hist_hist_2_folded_hist,
  output io_resp_valid,
  output [1:0] io_resp_bits_ctr,
  output io_resp_bits_u,
  output [19:0] io_resp_bits_target_offset_offset,
  output [3:0] io_resp_bits_target_offset_pointer,
  output io_resp_bits_target_offset_usePCRegion,
  input [49:0] io_update_pc,
  input [255:0] io_update_ghist,
  input io_update_valid,
  input io_update_correct,
  input io_update_alloc,
  input [1:0] io_update_oldCtr,
  input io_update_uValid,
  input io_update_u,
  input io_update_reset_u,
  input [19:0] io_update_target_offset_offset,
  input [3:0] io_update_target_offset_pointer,
  input io_update_target_offset_usePCRegion,
  input [19:0] io_update_old_target_offset_offset,
  input [3:0] io_update_old_target_offset_pointer,
  input io_update_old_target_offset_usePCRegion,
  input [6:0] boreChildrenBd_bore_array,
  input boreChildrenBd_bore_all,
  input boreChildrenBd_bore_req,
  output boreChildrenBd_bore_ack,
  input boreChildrenBd_bore_writeen,
  input [75:0] boreChildrenBd_bore_be,
  input [7:0] boreChildrenBd_bore_addr,
  input [75:0] boreChildrenBd_bore_indata,
  input boreChildrenBd_bore_readen,
  input [7:0] boreChildrenBd_bore_addr_rd,
  output [75:0] boreChildrenBd_bore_outdata,
  input sigFromSrams_bore_ram_hold,
  input sigFromSrams_bore_ram_bypass,
  input sigFromSrams_bore_ram_bp_clken,
  input sigFromSrams_bore_ram_aux_clk,
  input sigFromSrams_bore_ram_aux_ckbp,
  input sigFromSrams_bore_ram_mcp_hold,
  input sigFromSrams_bore_cgen,
  input sigFromSrams_bore_1_ram_hold,
  input sigFromSrams_bore_1_ram_bypass,
  input sigFromSrams_bore_1_ram_bp_clken,
  input sigFromSrams_bore_1_ram_aux_clk,
  input sigFromSrams_bore_1_ram_aux_ckbp,
  input sigFromSrams_bore_1_ram_mcp_hold,
  input sigFromSrams_bore_1_cgen
);
  // ===== 核 <-> 条目 SRAM 读/写口 中间线 =====
  wire                sram_r_req_valid;
  wire [8:0]    sram_r_req_setIdx;
  wire                sram_r_req_ready;
  wire                sram_r_resp_valid;
  wire [8:0]          sram_r_resp_tag;
  wire [1:0]          sram_r_resp_ctr;
  wire [19:0]         sram_r_resp_off;
  wire [3:0]          sram_r_resp_ptr;
  wire                sram_r_resp_upr;
  wire                sram_r_resp_useful;
  wire                sram_w_req_valid;
  wire [8:0]    sram_w_req_setIdx;
  wire [8:0]          sram_w_req_tag;
  wire [1:0]          sram_w_req_ctr;
  wire [19:0]         sram_w_req_off;
  wire [3:0]          sram_w_req_ptr;
  wire                sram_w_req_upr;
  wire                sram_w_req_useful;
  wire [37:0]         sram_w_req_bitmask;
  // ===== 核 <-> WrBypass 中间线 =====
  wire                wrbp_wen;
  wire [8:0]    wrbp_write_idx;
  wire [1:0]          wrbp_write_data;
  wire                wrbp_hit;
  wire [1:0]          wrbp_hit_data;
  // ===== MbistPipe <-> SRAM bore 口 中间线 =====
  wire [7:0]  childBd0_addr, childBd0_addr_rd;
  wire [75:0] childBd0_wdata, childBd0_wmask, childBd0_rdata;
  wire        childBd0_re, childBd0_we, childBd0_ack, childBd0_sel;
  wire [6:0]  childBd0_array;
  wire [7:0]  childBd1_addr, childBd1_addr_rd;
  wire [75:0] childBd1_wdata, childBd1_wmask, childBd1_rdata;
  wire        childBd1_re, childBd1_we, childBd1_ack, childBd1_sel;
  wire [6:0]  childBd1_array;
  // ===== 可读功能核 =====
  xs_ITTageTable_core #(
    .IDX_W(9), .IDX_FH_W(9), .TAG_FH_W(9), .ALT_FH_W(8),
    .IDX_HIST_LEN(16), .TAG_HIST_LEN(16), .ALT_HIST_LEN(16)
  ) u_core (
    .clock(clock), .reset(reset),
    .io_req_ready(io_req_ready), .io_req_valid(io_req_valid),
    .io_req_bits_pc(io_req_bits_pc),
    .io_req_idx_fh(io_req_bits_folded_hist_hist_6_folded_hist), .io_req_tag_fh(io_req_bits_folded_hist_hist_6_folded_hist), .io_req_alt_fh(io_req_bits_folded_hist_hist_2_folded_hist),
    .io_resp_valid(io_resp_valid), .io_resp_bits_ctr(io_resp_bits_ctr),
    .io_resp_bits_u(io_resp_bits_u),
    .io_resp_bits_target_offset_offset(io_resp_bits_target_offset_offset),
    .io_resp_bits_target_offset_pointer(io_resp_bits_target_offset_pointer),
    .io_resp_bits_target_offset_usePCRegion(io_resp_bits_target_offset_usePCRegion),
    .io_update_pc(io_update_pc), .io_update_ghist(io_update_ghist),
    .io_update_valid(io_update_valid), .io_update_correct(io_update_correct),
    .io_update_alloc(io_update_alloc), .io_update_oldCtr(io_update_oldCtr),
    .io_update_uValid(io_update_uValid), .io_update_u(io_update_u),
    .io_update_reset_u(io_update_reset_u),
    .io_update_target_offset_offset(io_update_target_offset_offset),
    .io_update_target_offset_pointer(io_update_target_offset_pointer),
    .io_update_target_offset_usePCRegion(io_update_target_offset_usePCRegion),
    .io_update_old_target_offset_offset(io_update_old_target_offset_offset),
    .io_update_old_target_offset_pointer(io_update_old_target_offset_pointer),
    .io_update_old_target_offset_usePCRegion(io_update_old_target_offset_usePCRegion),
    .sram_r_req_valid(sram_r_req_valid), .sram_r_req_setIdx(sram_r_req_setIdx),
    .sram_r_req_ready(sram_r_req_ready), .sram_r_resp_valid(sram_r_resp_valid),
    .sram_r_resp_tag(sram_r_resp_tag), .sram_r_resp_ctr(sram_r_resp_ctr),
    .sram_r_resp_target_offset_offset(sram_r_resp_off),
    .sram_r_resp_target_offset_pointer(sram_r_resp_ptr),
    .sram_r_resp_target_offset_usePCRegion(sram_r_resp_upr),
    .sram_r_resp_useful(sram_r_resp_useful),
    .sram_w_req_valid(sram_w_req_valid), .sram_w_req_setIdx(sram_w_req_setIdx),
    .sram_w_req_tag(sram_w_req_tag), .sram_w_req_ctr(sram_w_req_ctr),
    .sram_w_req_target_offset_offset(sram_w_req_off),
    .sram_w_req_target_offset_pointer(sram_w_req_ptr),
    .sram_w_req_target_offset_usePCRegion(sram_w_req_upr),
    .sram_w_req_useful(sram_w_req_useful), .sram_w_req_bitmask(sram_w_req_bitmask),
    .wrbp_wen(wrbp_wen), .wrbp_write_idx(wrbp_write_idx),
    .wrbp_write_data(wrbp_write_data),
    .wrbp_hit(wrbp_hit), .wrbp_hit_data(wrbp_hit_data)
  );
  // ===== 条目 SRAM（已验证黑盒）=====
  FoldedSRAMTemplate_23 table_0 (
    .clock(clock), .reset(reset),
    .io_r_req_ready(sram_r_req_ready), .io_r_req_valid(sram_r_req_valid),
    .io_r_req_bits_setIdx(sram_r_req_setIdx),
    .io_r_resp_data_0_valid(sram_r_resp_valid),
    .io_r_resp_data_0_tag(sram_r_resp_tag),
    .io_r_resp_data_0_ctr(sram_r_resp_ctr),
    .io_r_resp_data_0_target_offset_offset(sram_r_resp_off),
    .io_r_resp_data_0_target_offset_pointer(sram_r_resp_ptr),
    .io_r_resp_data_0_target_offset_usePCRegion(sram_r_resp_upr),
    .io_r_resp_data_0_useful(sram_r_resp_useful),
    .io_w_req_valid(sram_w_req_valid), .io_w_req_bits_setIdx(sram_w_req_setIdx),
    .io_w_req_bits_data_0_tag(sram_w_req_tag),
    .io_w_req_bits_data_0_ctr(sram_w_req_ctr),
    .io_w_req_bits_data_0_target_offset_offset(sram_w_req_off),
    .io_w_req_bits_data_0_target_offset_pointer(sram_w_req_ptr),
    .io_w_req_bits_data_0_target_offset_usePCRegion(sram_w_req_upr),
    .io_w_req_bits_data_0_useful(sram_w_req_useful),
    .io_w_req_bits_bitmask(sram_w_req_bitmask),
    .boreChildrenBd_bore_addr(childBd0_addr),
    .boreChildrenBd_bore_addr_rd(childBd0_addr_rd),
    .boreChildrenBd_bore_wdata(childBd0_wdata),
    .boreChildrenBd_bore_wmask(childBd0_wmask),
    .boreChildrenBd_bore_re(childBd0_re), .boreChildrenBd_bore_we(childBd0_we),
    .boreChildrenBd_bore_rdata(childBd0_rdata),
    .boreChildrenBd_bore_ack(childBd0_ack),
    .boreChildrenBd_bore_selectedOH(childBd0_sel),
    .boreChildrenBd_bore_array(childBd0_array),
    .boreChildrenBd_bore_1_addr(childBd1_addr),
    .boreChildrenBd_bore_1_addr_rd(childBd1_addr_rd),
    .boreChildrenBd_bore_1_wdata(childBd1_wdata),
    .boreChildrenBd_bore_1_wmask(childBd1_wmask),
    .boreChildrenBd_bore_1_re(childBd1_re), .boreChildrenBd_bore_1_we(childBd1_we),
    .boreChildrenBd_bore_1_rdata(childBd1_rdata),
    .boreChildrenBd_bore_1_ack(childBd1_ack),
    .boreChildrenBd_bore_1_selectedOH(childBd1_sel),
    .boreChildrenBd_bore_1_array(childBd1_array),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen)
  );
  // ===== WrBypass（已验证黑盒）=====
  WrBypass_43 wrbypass (
    .clock(clock), .reset(reset),
    .io_wen(wrbp_wen), .io_write_idx(wrbp_write_idx),
    .io_write_data_0(wrbp_write_data),
    .io_hit(wrbp_hit), .io_hit_data_0_bits(wrbp_hit_data)
  );
  // ===== MBIST 流水寄存（可读核；上游 mbist 总线 -> SRAM bore 口）=====
  wire [7:0]  ms_addr   [2], ms_addr_rd [2];
  wire [75:0] ms_wdata  [2], ms_wmask   [2], ms_rdata [2];
  wire        ms_re     [2], ms_we      [2], ms_ack [2], ms_sel [2];
  wire [6:0]  ms_array  [2];
  assign childBd0_addr=ms_addr[0];       assign childBd0_addr_rd=ms_addr_rd[0];
  assign childBd0_wdata=ms_wdata[0];     assign childBd0_wmask=ms_wmask[0];
  assign childBd0_re=ms_re[0];           assign childBd0_we=ms_we[0];
  assign childBd0_ack=ms_ack[0];         assign childBd0_sel=ms_sel[0];
  assign childBd0_array=ms_array[0];     assign ms_rdata[0]=childBd0_rdata;
  assign childBd1_addr=ms_addr[1];       assign childBd1_addr_rd=ms_addr_rd[1];
  assign childBd1_wdata=ms_wdata[1];     assign childBd1_wmask=ms_wmask[1];
  assign childBd1_re=ms_re[1];           assign childBd1_we=ms_we[1];
  assign childBd1_ack=ms_ack[1];         assign childBd1_sel=ms_sel[1];
  assign childBd1_array=ms_array[1];     assign ms_rdata[1]=childBd1_rdata;
  xs_MbistPipeIttage_core #(.N_SRAM(2), .ARRAY_ID0(7'h4A), .ADDR_W(8), .DATA_W(76)) mbistPl (
    .clock(clock), .reset(reset),
    .mbist_array(boreChildrenBd_bore_array), .mbist_all(boreChildrenBd_bore_all),
    .mbist_req(boreChildrenBd_bore_req), .mbist_ack(boreChildrenBd_bore_ack),
    .mbist_writeen(boreChildrenBd_bore_writeen), .mbist_be(boreChildrenBd_bore_be),
    .mbist_addr(boreChildrenBd_bore_addr), .mbist_indata(boreChildrenBd_bore_indata),
    .mbist_readen(boreChildrenBd_bore_readen), .mbist_addr_rd(boreChildrenBd_bore_addr_rd),
    .mbist_outdata(boreChildrenBd_bore_outdata),
    .toSRAM_addr(ms_addr), .toSRAM_addr_rd(ms_addr_rd),
    .toSRAM_wdata(ms_wdata), .toSRAM_wmask(ms_wmask),
    .toSRAM_re(ms_re), .toSRAM_we(ms_we), .toSRAM_rdata(ms_rdata),
    .toSRAM_ack(ms_ack), .toSRAM_selectedOH(ms_sel), .toSRAM_array(ms_array)
  );
endmodule

module ITTageTable_4(
  input clock,
  input reset,
  output io_req_ready,
  input io_req_valid,
  input [49:0] io_req_bits_pc,
  input [8:0] io_req_bits_folded_hist_hist_10_folded_hist,
  input [7:0] io_req_bits_folded_hist_hist_3_folded_hist,
  output io_resp_valid,
  output [1:0] io_resp_bits_ctr,
  output io_resp_bits_u,
  output [19:0] io_resp_bits_target_offset_offset,
  output [3:0] io_resp_bits_target_offset_pointer,
  output io_resp_bits_target_offset_usePCRegion,
  input [49:0] io_update_pc,
  input [255:0] io_update_ghist,
  input io_update_valid,
  input io_update_correct,
  input io_update_alloc,
  input [1:0] io_update_oldCtr,
  input io_update_uValid,
  input io_update_u,
  input io_update_reset_u,
  input [19:0] io_update_target_offset_offset,
  input [3:0] io_update_target_offset_pointer,
  input io_update_target_offset_usePCRegion,
  input [19:0] io_update_old_target_offset_offset,
  input [3:0] io_update_old_target_offset_pointer,
  input io_update_old_target_offset_usePCRegion,
  input [6:0] boreChildrenBd_bore_array,
  input boreChildrenBd_bore_all,
  input boreChildrenBd_bore_req,
  output boreChildrenBd_bore_ack,
  input boreChildrenBd_bore_writeen,
  input [75:0] boreChildrenBd_bore_be,
  input [7:0] boreChildrenBd_bore_addr,
  input [75:0] boreChildrenBd_bore_indata,
  input boreChildrenBd_bore_readen,
  input [7:0] boreChildrenBd_bore_addr_rd,
  output [75:0] boreChildrenBd_bore_outdata,
  input sigFromSrams_bore_ram_hold,
  input sigFromSrams_bore_ram_bypass,
  input sigFromSrams_bore_ram_bp_clken,
  input sigFromSrams_bore_ram_aux_clk,
  input sigFromSrams_bore_ram_aux_ckbp,
  input sigFromSrams_bore_ram_mcp_hold,
  input sigFromSrams_bore_cgen,
  input sigFromSrams_bore_1_ram_hold,
  input sigFromSrams_bore_1_ram_bypass,
  input sigFromSrams_bore_1_ram_bp_clken,
  input sigFromSrams_bore_1_ram_aux_clk,
  input sigFromSrams_bore_1_ram_aux_ckbp,
  input sigFromSrams_bore_1_ram_mcp_hold,
  input sigFromSrams_bore_1_cgen
);
  // ===== 核 <-> 条目 SRAM 读/写口 中间线 =====
  wire                sram_r_req_valid;
  wire [8:0]    sram_r_req_setIdx;
  wire                sram_r_req_ready;
  wire                sram_r_resp_valid;
  wire [8:0]          sram_r_resp_tag;
  wire [1:0]          sram_r_resp_ctr;
  wire [19:0]         sram_r_resp_off;
  wire [3:0]          sram_r_resp_ptr;
  wire                sram_r_resp_upr;
  wire                sram_r_resp_useful;
  wire                sram_w_req_valid;
  wire [8:0]    sram_w_req_setIdx;
  wire [8:0]          sram_w_req_tag;
  wire [1:0]          sram_w_req_ctr;
  wire [19:0]         sram_w_req_off;
  wire [3:0]          sram_w_req_ptr;
  wire                sram_w_req_upr;
  wire                sram_w_req_useful;
  wire [37:0]         sram_w_req_bitmask;
  // ===== 核 <-> WrBypass 中间线 =====
  wire                wrbp_wen;
  wire [8:0]    wrbp_write_idx;
  wire [1:0]          wrbp_write_data;
  wire                wrbp_hit;
  wire [1:0]          wrbp_hit_data;
  // ===== MbistPipe <-> SRAM bore 口 中间线 =====
  wire [7:0]  childBd0_addr, childBd0_addr_rd;
  wire [75:0] childBd0_wdata, childBd0_wmask, childBd0_rdata;
  wire        childBd0_re, childBd0_we, childBd0_ack, childBd0_sel;
  wire [6:0]  childBd0_array;
  wire [7:0]  childBd1_addr, childBd1_addr_rd;
  wire [75:0] childBd1_wdata, childBd1_wmask, childBd1_rdata;
  wire        childBd1_re, childBd1_we, childBd1_ack, childBd1_sel;
  wire [6:0]  childBd1_array;
  // ===== 可读功能核 =====
  xs_ITTageTable_core #(
    .IDX_W(9), .IDX_FH_W(9), .TAG_FH_W(9), .ALT_FH_W(8),
    .IDX_HIST_LEN(32), .TAG_HIST_LEN(32), .ALT_HIST_LEN(32)
  ) u_core (
    .clock(clock), .reset(reset),
    .io_req_ready(io_req_ready), .io_req_valid(io_req_valid),
    .io_req_bits_pc(io_req_bits_pc),
    .io_req_idx_fh(io_req_bits_folded_hist_hist_10_folded_hist), .io_req_tag_fh(io_req_bits_folded_hist_hist_10_folded_hist), .io_req_alt_fh(io_req_bits_folded_hist_hist_3_folded_hist),
    .io_resp_valid(io_resp_valid), .io_resp_bits_ctr(io_resp_bits_ctr),
    .io_resp_bits_u(io_resp_bits_u),
    .io_resp_bits_target_offset_offset(io_resp_bits_target_offset_offset),
    .io_resp_bits_target_offset_pointer(io_resp_bits_target_offset_pointer),
    .io_resp_bits_target_offset_usePCRegion(io_resp_bits_target_offset_usePCRegion),
    .io_update_pc(io_update_pc), .io_update_ghist(io_update_ghist),
    .io_update_valid(io_update_valid), .io_update_correct(io_update_correct),
    .io_update_alloc(io_update_alloc), .io_update_oldCtr(io_update_oldCtr),
    .io_update_uValid(io_update_uValid), .io_update_u(io_update_u),
    .io_update_reset_u(io_update_reset_u),
    .io_update_target_offset_offset(io_update_target_offset_offset),
    .io_update_target_offset_pointer(io_update_target_offset_pointer),
    .io_update_target_offset_usePCRegion(io_update_target_offset_usePCRegion),
    .io_update_old_target_offset_offset(io_update_old_target_offset_offset),
    .io_update_old_target_offset_pointer(io_update_old_target_offset_pointer),
    .io_update_old_target_offset_usePCRegion(io_update_old_target_offset_usePCRegion),
    .sram_r_req_valid(sram_r_req_valid), .sram_r_req_setIdx(sram_r_req_setIdx),
    .sram_r_req_ready(sram_r_req_ready), .sram_r_resp_valid(sram_r_resp_valid),
    .sram_r_resp_tag(sram_r_resp_tag), .sram_r_resp_ctr(sram_r_resp_ctr),
    .sram_r_resp_target_offset_offset(sram_r_resp_off),
    .sram_r_resp_target_offset_pointer(sram_r_resp_ptr),
    .sram_r_resp_target_offset_usePCRegion(sram_r_resp_upr),
    .sram_r_resp_useful(sram_r_resp_useful),
    .sram_w_req_valid(sram_w_req_valid), .sram_w_req_setIdx(sram_w_req_setIdx),
    .sram_w_req_tag(sram_w_req_tag), .sram_w_req_ctr(sram_w_req_ctr),
    .sram_w_req_target_offset_offset(sram_w_req_off),
    .sram_w_req_target_offset_pointer(sram_w_req_ptr),
    .sram_w_req_target_offset_usePCRegion(sram_w_req_upr),
    .sram_w_req_useful(sram_w_req_useful), .sram_w_req_bitmask(sram_w_req_bitmask),
    .wrbp_wen(wrbp_wen), .wrbp_write_idx(wrbp_write_idx),
    .wrbp_write_data(wrbp_write_data),
    .wrbp_hit(wrbp_hit), .wrbp_hit_data(wrbp_hit_data)
  );
  // ===== 条目 SRAM（已验证黑盒）=====
  FoldedSRAMTemplate_23 table_0 (
    .clock(clock), .reset(reset),
    .io_r_req_ready(sram_r_req_ready), .io_r_req_valid(sram_r_req_valid),
    .io_r_req_bits_setIdx(sram_r_req_setIdx),
    .io_r_resp_data_0_valid(sram_r_resp_valid),
    .io_r_resp_data_0_tag(sram_r_resp_tag),
    .io_r_resp_data_0_ctr(sram_r_resp_ctr),
    .io_r_resp_data_0_target_offset_offset(sram_r_resp_off),
    .io_r_resp_data_0_target_offset_pointer(sram_r_resp_ptr),
    .io_r_resp_data_0_target_offset_usePCRegion(sram_r_resp_upr),
    .io_r_resp_data_0_useful(sram_r_resp_useful),
    .io_w_req_valid(sram_w_req_valid), .io_w_req_bits_setIdx(sram_w_req_setIdx),
    .io_w_req_bits_data_0_tag(sram_w_req_tag),
    .io_w_req_bits_data_0_ctr(sram_w_req_ctr),
    .io_w_req_bits_data_0_target_offset_offset(sram_w_req_off),
    .io_w_req_bits_data_0_target_offset_pointer(sram_w_req_ptr),
    .io_w_req_bits_data_0_target_offset_usePCRegion(sram_w_req_upr),
    .io_w_req_bits_data_0_useful(sram_w_req_useful),
    .io_w_req_bits_bitmask(sram_w_req_bitmask),
    .boreChildrenBd_bore_addr(childBd0_addr),
    .boreChildrenBd_bore_addr_rd(childBd0_addr_rd),
    .boreChildrenBd_bore_wdata(childBd0_wdata),
    .boreChildrenBd_bore_wmask(childBd0_wmask),
    .boreChildrenBd_bore_re(childBd0_re), .boreChildrenBd_bore_we(childBd0_we),
    .boreChildrenBd_bore_rdata(childBd0_rdata),
    .boreChildrenBd_bore_ack(childBd0_ack),
    .boreChildrenBd_bore_selectedOH(childBd0_sel),
    .boreChildrenBd_bore_array(childBd0_array),
    .boreChildrenBd_bore_1_addr(childBd1_addr),
    .boreChildrenBd_bore_1_addr_rd(childBd1_addr_rd),
    .boreChildrenBd_bore_1_wdata(childBd1_wdata),
    .boreChildrenBd_bore_1_wmask(childBd1_wmask),
    .boreChildrenBd_bore_1_re(childBd1_re), .boreChildrenBd_bore_1_we(childBd1_we),
    .boreChildrenBd_bore_1_rdata(childBd1_rdata),
    .boreChildrenBd_bore_1_ack(childBd1_ack),
    .boreChildrenBd_bore_1_selectedOH(childBd1_sel),
    .boreChildrenBd_bore_1_array(childBd1_array),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen)
  );
  // ===== WrBypass（已验证黑盒）=====
  WrBypass_43 wrbypass (
    .clock(clock), .reset(reset),
    .io_wen(wrbp_wen), .io_write_idx(wrbp_write_idx),
    .io_write_data_0(wrbp_write_data),
    .io_hit(wrbp_hit), .io_hit_data_0_bits(wrbp_hit_data)
  );
  // ===== MBIST 流水寄存（可读核；上游 mbist 总线 -> SRAM bore 口）=====
  wire [7:0]  ms_addr   [2], ms_addr_rd [2];
  wire [75:0] ms_wdata  [2], ms_wmask   [2], ms_rdata [2];
  wire        ms_re     [2], ms_we      [2], ms_ack [2], ms_sel [2];
  wire [6:0]  ms_array  [2];
  assign childBd0_addr=ms_addr[0];       assign childBd0_addr_rd=ms_addr_rd[0];
  assign childBd0_wdata=ms_wdata[0];     assign childBd0_wmask=ms_wmask[0];
  assign childBd0_re=ms_re[0];           assign childBd0_we=ms_we[0];
  assign childBd0_ack=ms_ack[0];         assign childBd0_sel=ms_sel[0];
  assign childBd0_array=ms_array[0];     assign ms_rdata[0]=childBd0_rdata;
  assign childBd1_addr=ms_addr[1];       assign childBd1_addr_rd=ms_addr_rd[1];
  assign childBd1_wdata=ms_wdata[1];     assign childBd1_wmask=ms_wmask[1];
  assign childBd1_re=ms_re[1];           assign childBd1_we=ms_we[1];
  assign childBd1_ack=ms_ack[1];         assign childBd1_sel=ms_sel[1];
  assign childBd1_array=ms_array[1];     assign ms_rdata[1]=childBd1_rdata;
  xs_MbistPipeIttage_core #(.N_SRAM(2), .ARRAY_ID0(7'h4C), .ADDR_W(8), .DATA_W(76)) mbistPl (
    .clock(clock), .reset(reset),
    .mbist_array(boreChildrenBd_bore_array), .mbist_all(boreChildrenBd_bore_all),
    .mbist_req(boreChildrenBd_bore_req), .mbist_ack(boreChildrenBd_bore_ack),
    .mbist_writeen(boreChildrenBd_bore_writeen), .mbist_be(boreChildrenBd_bore_be),
    .mbist_addr(boreChildrenBd_bore_addr), .mbist_indata(boreChildrenBd_bore_indata),
    .mbist_readen(boreChildrenBd_bore_readen), .mbist_addr_rd(boreChildrenBd_bore_addr_rd),
    .mbist_outdata(boreChildrenBd_bore_outdata),
    .toSRAM_addr(ms_addr), .toSRAM_addr_rd(ms_addr_rd),
    .toSRAM_wdata(ms_wdata), .toSRAM_wmask(ms_wmask),
    .toSRAM_re(ms_re), .toSRAM_we(ms_we), .toSRAM_rdata(ms_rdata),
    .toSRAM_ack(ms_ack), .toSRAM_selectedOH(ms_sel), .toSRAM_array(ms_array)
  );
endmodule