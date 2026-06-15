module SplittedSRAMTemplate_26_xs(
  input         clock,
  input         reset,
  output        io_r_req_ready,
  input         io_r_req_valid,
  input  [6:0]  io_r_req_bits_setIdx,
  output        io_r_resp_data_0_valid,
  output [8:0]  io_r_resp_data_0_tag,
  output [1:0]  io_r_resp_data_0_ctr,
  output [19:0] io_r_resp_data_0_target_offset_offset,
  output [3:0]  io_r_resp_data_0_target_offset_pointer,
  output        io_r_resp_data_0_target_offset_usePCRegion,
  output        io_r_resp_data_0_useful,
  output        io_r_resp_data_1_valid,
  output [8:0]  io_r_resp_data_1_tag,
  output [1:0]  io_r_resp_data_1_ctr,
  output [19:0] io_r_resp_data_1_target_offset_offset,
  output [3:0]  io_r_resp_data_1_target_offset_pointer,
  output        io_r_resp_data_1_target_offset_usePCRegion,
  output        io_r_resp_data_1_useful,
  output        io_r_resp_data_2_valid,
  output [8:0]  io_r_resp_data_2_tag,
  output [1:0]  io_r_resp_data_2_ctr,
  output [19:0] io_r_resp_data_2_target_offset_offset,
  output [3:0]  io_r_resp_data_2_target_offset_pointer,
  output        io_r_resp_data_2_target_offset_usePCRegion,
  output        io_r_resp_data_2_useful,
  output        io_r_resp_data_3_valid,
  output [8:0]  io_r_resp_data_3_tag,
  output [1:0]  io_r_resp_data_3_ctr,
  output [19:0] io_r_resp_data_3_target_offset_offset,
  output [3:0]  io_r_resp_data_3_target_offset_pointer,
  output        io_r_resp_data_3_target_offset_usePCRegion,
  output        io_r_resp_data_3_useful,
  input         io_w_req_valid,
  input  [6:0]  io_w_req_bits_setIdx,
  input  [8:0]  io_w_req_bits_data_0_tag,
  input  [1:0]  io_w_req_bits_data_0_ctr,
  input  [19:0] io_w_req_bits_data_0_target_offset_offset,
  input  [3:0]  io_w_req_bits_data_0_target_offset_pointer,
  input         io_w_req_bits_data_0_target_offset_usePCRegion,
  input         io_w_req_bits_data_0_useful,
  input  [8:0]  io_w_req_bits_data_1_tag,
  input  [1:0]  io_w_req_bits_data_1_ctr,
  input  [19:0] io_w_req_bits_data_1_target_offset_offset,
  input  [3:0]  io_w_req_bits_data_1_target_offset_pointer,
  input         io_w_req_bits_data_1_target_offset_usePCRegion,
  input         io_w_req_bits_data_1_useful,
  input  [8:0]  io_w_req_bits_data_2_tag,
  input  [1:0]  io_w_req_bits_data_2_ctr,
  input  [19:0] io_w_req_bits_data_2_target_offset_offset,
  input  [3:0]  io_w_req_bits_data_2_target_offset_pointer,
  input         io_w_req_bits_data_2_target_offset_usePCRegion,
  input         io_w_req_bits_data_2_useful,
  input  [8:0]  io_w_req_bits_data_3_tag,
  input  [1:0]  io_w_req_bits_data_3_ctr,
  input  [19:0] io_w_req_bits_data_3_target_offset_offset,
  input  [3:0]  io_w_req_bits_data_3_target_offset_pointer,
  input         io_w_req_bits_data_3_target_offset_usePCRegion,
  input         io_w_req_bits_data_3_useful,
  input  [3:0]  io_w_req_bits_waymask,
  input  [37:0] io_w_req_bits_bitmask,
  input  [7:0]  boreChildrenBd_bore_addr,
  input  [7:0]  boreChildrenBd_bore_addr_rd,
  input  [75:0] boreChildrenBd_bore_wdata,
  input  [75:0] boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re,
  input         boreChildrenBd_bore_we,
  output [75:0] boreChildrenBd_bore_rdata,
  input         boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_selectedOH,
  input  [6:0]  boreChildrenBd_bore_array,
  input  [7:0]  boreChildrenBd_bore_1_addr,
  input  [7:0]  boreChildrenBd_bore_1_addr_rd,
  input  [75:0] boreChildrenBd_bore_1_wdata,
  input  [75:0] boreChildrenBd_bore_1_wmask,
  input         boreChildrenBd_bore_1_re,
  input         boreChildrenBd_bore_1_we,
  output [75:0] boreChildrenBd_bore_1_rdata,
  input         boreChildrenBd_bore_1_ack,
  input         boreChildrenBd_bore_1_selectedOH,
  input  [6:0]  boreChildrenBd_bore_1_array,
  input         sigFromSrams_bore_ram_hold,
  input         sigFromSrams_bore_ram_bypass,
  input         sigFromSrams_bore_ram_bp_clken,
  input         sigFromSrams_bore_ram_aux_clk,
  input         sigFromSrams_bore_ram_aux_ckbp,
  input         sigFromSrams_bore_ram_mcp_hold,
  input         sigFromSrams_bore_cgen,
  input         sigFromSrams_bore_1_ram_hold,
  input         sigFromSrams_bore_1_ram_bypass,
  input         sigFromSrams_bore_1_ram_bp_clken,
  input         sigFromSrams_bore_1_ram_aux_clk,
  input         sigFromSrams_bore_1_ram_aux_ckbp,
  input         sigFromSrams_bore_1_ram_mcp_hold,
  input         sigFromSrams_bore_1_cgen
);
  localparam int HALF_W = 19;  // 每个数据切片的位宽（38/2）

  // ---- 把 4 路 struct 打包成「低半 / 高半」两个 19 位切片 ----
  wire [HALF_W-1:0] lo_wd [4];  // inner0：每路低半
  wire [HALF_W-1:0] hi_wd [4];  // inner1：每路高半
  // 用数组聚合 4 路输入，便于 genvar 打包（避免 4×手抄）
  wire [8:0]  in_tag       [4];
  wire [1:0]  in_ctr       [4];
  wire [19:0] in_offset    [4];
  wire [3:0]  in_pointer   [4];
  wire        in_usePCReg  [4];
  wire        in_useful    [4];
  assign in_tag[0]=io_w_req_bits_data_0_tag; assign in_tag[1]=io_w_req_bits_data_1_tag;
  assign in_tag[2]=io_w_req_bits_data_2_tag; assign in_tag[3]=io_w_req_bits_data_3_tag;
  assign in_ctr[0]=io_w_req_bits_data_0_ctr; assign in_ctr[1]=io_w_req_bits_data_1_ctr;
  assign in_ctr[2]=io_w_req_bits_data_2_ctr; assign in_ctr[3]=io_w_req_bits_data_3_ctr;
  assign in_offset[0]=io_w_req_bits_data_0_target_offset_offset;
  assign in_offset[1]=io_w_req_bits_data_1_target_offset_offset;
  assign in_offset[2]=io_w_req_bits_data_2_target_offset_offset;
  assign in_offset[3]=io_w_req_bits_data_3_target_offset_offset;
  assign in_pointer[0]=io_w_req_bits_data_0_target_offset_pointer;
  assign in_pointer[1]=io_w_req_bits_data_1_target_offset_pointer;
  assign in_pointer[2]=io_w_req_bits_data_2_target_offset_pointer;
  assign in_pointer[3]=io_w_req_bits_data_3_target_offset_pointer;
  assign in_usePCReg[0]=io_w_req_bits_data_0_target_offset_usePCRegion;
  assign in_usePCReg[1]=io_w_req_bits_data_1_target_offset_usePCRegion;
  assign in_usePCReg[2]=io_w_req_bits_data_2_target_offset_usePCRegion;
  assign in_usePCReg[3]=io_w_req_bits_data_3_target_offset_usePCRegion;
  assign in_useful[0]=io_w_req_bits_data_0_useful; assign in_useful[1]=io_w_req_bits_data_1_useful;
  assign in_useful[2]=io_w_req_bits_data_2_useful; assign in_useful[3]=io_w_req_bits_data_3_useful;

  genvar wy, bt;
  generate
    for (wy = 0; wy < 4; wy++) begin : g_pack
      // 低半 = {offset[12:0], pointer[3:0], usePCRegion, useful}
      assign lo_wd[wy] = {in_offset[wy][12:0], in_pointer[wy], in_usePCReg[wy], in_useful[wy]};
      // 高半 = {valid=1, tag[8:0], ctr[1:0], offset[19:13]}
      assign hi_wd[wy] = {1'b1, in_tag[wy], in_ctr[wy], in_offset[wy][19:13]};
    end
  endgenerate

  // ---- 逐位写掩码：先按数据维取该切片对应的 19 位，再按 4 路用 waymask 铺开 ----
  wire [4*HALF_W-1:0] lo_bitmask;  // inner0：{way3..way0} 各 19 位
  wire [4*HALF_W-1:0] hi_bitmask;  // inner1
  generate
    for (wy = 0; wy < 4; wy++) begin : g_mask_way
      for (bt = 0; bt < HALF_W; bt++) begin : g_mask_bit
        // 低半对应原 bitmask[18:0]，高半对应原 bitmask[37:19]
        assign lo_bitmask[wy*HALF_W + bt] = io_w_req_bits_waymask[wy] & io_w_req_bits_bitmask[bt];
        assign hi_bitmask[wy*HALF_W + bt] = io_w_req_bits_waymask[wy] & io_w_req_bits_bitmask[HALF_W + bt];
      end
    end
  endgenerate

  wire [HALF_W-1:0] lo_rd [4];  // inner0 读出
  wire [HALF_W-1:0] hi_rd [4];  // inner1 读出

  // inner0：低半切片（bore）
  SRAMTemplate_72 array_0_0_0 (
    .clock(clock), .reset(reset),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(lo_rd[0]), .io_r_resp_data_1(lo_rd[1]),
    .io_r_resp_data_2(lo_rd[2]), .io_r_resp_data_3(lo_rd[3]),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(lo_wd[0]), .io_w_req_bits_data_1(lo_wd[1]),
    .io_w_req_bits_data_2(lo_wd[2]), .io_w_req_bits_data_3(lo_wd[3]),
    .io_w_req_bits_flattened_bitmask(lo_bitmask),
    .io_broadcast_ram_hold(sigFromSrams_bore_ram_hold),
    .io_broadcast_ram_bypass(sigFromSrams_bore_ram_bypass),
    .io_broadcast_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .io_broadcast_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .io_broadcast_ram_ctl(64'h0), .io_broadcast_cgen(sigFromSrams_bore_cgen),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array)
  );

  // inner1：高半切片（bore_1）
  SRAMTemplate_72 array_0_0_1 (
    .clock(clock), .reset(reset),
    .io_r_req_ready(/* unused */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(hi_rd[0]), .io_r_resp_data_1(hi_rd[1]),
    .io_r_resp_data_2(hi_rd[2]), .io_r_resp_data_3(hi_rd[3]),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(hi_wd[0]), .io_w_req_bits_data_1(hi_wd[1]),
    .io_w_req_bits_data_2(hi_wd[2]), .io_w_req_bits_data_3(hi_wd[3]),
    .io_w_req_bits_flattened_bitmask(hi_bitmask),
    .io_broadcast_ram_hold(sigFromSrams_bore_1_ram_hold),
    .io_broadcast_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .io_broadcast_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .io_broadcast_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .io_broadcast_ram_ctl(64'h0), .io_broadcast_cgen(sigFromSrams_bore_1_cgen),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_wmask(boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_we(boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_ack(boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_1_array)
  );

  // ---- 读：高低半拼回 struct 字段 ----
  // 低半：[18:6]=offset[12:0], [5:2]=pointer, [1]=usePCRegion, [0]=useful
  // 高半：[18]=valid, [17:9]=tag, [8:7]=ctr, [6:0]=offset[19:13]
  assign io_r_resp_data_0_valid                     = hi_rd[0][18];
  assign io_r_resp_data_0_tag                       = hi_rd[0][17:9];
  assign io_r_resp_data_0_ctr                       = hi_rd[0][8:7];
  assign io_r_resp_data_0_target_offset_offset      = {hi_rd[0][6:0], lo_rd[0][18:6]};
  assign io_r_resp_data_0_target_offset_pointer     = lo_rd[0][5:2];
  assign io_r_resp_data_0_target_offset_usePCRegion = lo_rd[0][1];
  assign io_r_resp_data_0_useful                    = lo_rd[0][0];
  assign io_r_resp_data_1_valid                     = hi_rd[1][18];
  assign io_r_resp_data_1_tag                       = hi_rd[1][17:9];
  assign io_r_resp_data_1_ctr                       = hi_rd[1][8:7];
  assign io_r_resp_data_1_target_offset_offset      = {hi_rd[1][6:0], lo_rd[1][18:6]};
  assign io_r_resp_data_1_target_offset_pointer     = lo_rd[1][5:2];
  assign io_r_resp_data_1_target_offset_usePCRegion = lo_rd[1][1];
  assign io_r_resp_data_1_useful                    = lo_rd[1][0];
  assign io_r_resp_data_2_valid                     = hi_rd[2][18];
  assign io_r_resp_data_2_tag                       = hi_rd[2][17:9];
  assign io_r_resp_data_2_ctr                       = hi_rd[2][8:7];
  assign io_r_resp_data_2_target_offset_offset      = {hi_rd[2][6:0], lo_rd[2][18:6]};
  assign io_r_resp_data_2_target_offset_pointer     = lo_rd[2][5:2];
  assign io_r_resp_data_2_target_offset_usePCRegion = lo_rd[2][1];
  assign io_r_resp_data_2_useful                    = lo_rd[2][0];
  assign io_r_resp_data_3_valid                     = hi_rd[3][18];
  assign io_r_resp_data_3_tag                       = hi_rd[3][17:9];
  assign io_r_resp_data_3_ctr                       = hi_rd[3][8:7];
  assign io_r_resp_data_3_target_offset_offset      = {hi_rd[3][6:0], lo_rd[3][18:6]};
  assign io_r_resp_data_3_target_offset_pointer     = lo_rd[3][5:2];
  assign io_r_resp_data_3_target_offset_usePCRegion = lo_rd[3][1];
  assign io_r_resp_data_3_useful                    = lo_rd[3][0];
endmodule
