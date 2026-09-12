// 自动生成：verif/ut/SRAMTemplateNewForm/gen.py —— 勿手改
// G1 新形态 SRAMTemplate 八变体的双例化 UT：golden <名> 与重写 <名>_xs 吃同一份激励，
// 每拍比全部输出。
//
// 存储类模块最容易出的假绿是"UT 全过但根本没写进去"（两边都读出 x，比较当然相等）。
// 所以除 errors 外还有两道闸：
//   * z 闸：任何一侧输出出现 z（未驱动）直接算错——上一轮出过输出悬空的 SRAM wrapper；
//   * 覆盖闸：写掩码全 0 / 全 1 / 混合、读写同 set、时钟门控关闭拍、MBIST 读写、
//     以及"读回数据无 x"与"读回非全 0"（证明数据真写进去又读出来）各自计数，
//     任一项为 0 判 FAIL。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 120000;
  int unsigned WARMUP  = 1000;   // 等最大的 reset FSM(256 set) 清零完成并写热几个 set
  bit clk = 0, rst;
  int errors = 0, checks = 0, zhits = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  // 某个值里有没有 z 位（x 是允许的：没写过的 RAM 本来就读出 x）
  function automatic bit has_z(input logic [1023:0] v, input int w);
    has_z = 1'b0;
    for (int b = 0; b < w; b++) if (v[b] === 1'bz) has_z = 1'b1;
  endfunction
  function automatic bit has_x(input logic [1023:0] v, input int w);
    has_x = 1'b0;
    for (int b = 0; b < w; b++) if (v[b] === 1'bx) has_x = 1'b1;
  endfunction

  // ================= SRAMTemplate_128 =================
  logic vSRAMTemplate_128_io_r_req_valid;
  logic [1:0] vSRAMTemplate_128_io_r_req_bits_setIdx;
  logic vSRAMTemplate_128_io_w_req_valid;
  logic [1:0] vSRAMTemplate_128_io_w_req_bits_setIdx;
  logic [392:0] vSRAMTemplate_128_io_w_req_bits_data_0;
  logic [392:0] vSRAMTemplate_128_io_w_req_bits_data_1;
  logic [1:0] vSRAMTemplate_128_io_w_req_bits_waymask;
  logic vSRAMTemplate_128_io_broadcast_ram_hold;
  logic vSRAMTemplate_128_io_broadcast_ram_bypass;
  logic vSRAMTemplate_128_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_128_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_128_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_128_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_128_io_broadcast_ram_ctl;
  logic vSRAMTemplate_128_io_broadcast_cgen;
  logic [2:0] vSRAMTemplate_128_boreChildrenBd_bore_addr;
  logic [2:0] vSRAMTemplate_128_boreChildrenBd_bore_addr_rd;
  logic [130:0] vSRAMTemplate_128_boreChildrenBd_bore_wdata;
  logic vSRAMTemplate_128_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_128_boreChildrenBd_bore_re;
  logic vSRAMTemplate_128_boreChildrenBd_bore_we;
  logic vSRAMTemplate_128_boreChildrenBd_bore_ack;
  logic [5:0] vSRAMTemplate_128_boreChildrenBd_bore_selectedOH;
  logic [5:0] vSRAMTemplate_128_boreChildrenBd_bore_array;
  wire [392:0] vSRAMTemplate_128_g_io_r_resp_data_0;
  wire [392:0] vSRAMTemplate_128_i_io_r_resp_data_0;
  wire [392:0] vSRAMTemplate_128_g_io_r_resp_data_1;
  wire [392:0] vSRAMTemplate_128_i_io_r_resp_data_1;
  wire [130:0] vSRAMTemplate_128_g_boreChildrenBd_bore_rdata;
  wire [130:0] vSRAMTemplate_128_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_128    u_g_SRAMTemplate_128 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_128_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_128_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_128_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_128_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_128_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_128_io_w_req_bits_data_1), .io_w_req_bits_waymask(vSRAMTemplate_128_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_128_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_128_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_128_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_128_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_128_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_128_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_128_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_128_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_128_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_128_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_128_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_128_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_128_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_128_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_128_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_128_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_128_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_128_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_128_g_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_128_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_128_xs u_i_SRAMTemplate_128 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_128_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_128_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_128_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_128_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_128_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_128_io_w_req_bits_data_1), .io_w_req_bits_waymask(vSRAMTemplate_128_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_128_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_128_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_128_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_128_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_128_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_128_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_128_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_128_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_128_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_128_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_128_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_128_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_128_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_128_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_128_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_128_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_128_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_128_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_128_i_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_128_i_boreChildrenBd_bore_rdata));
  int vSRAMTemplate_128_cov_w = 0, vSRAMTemplate_128_cov_rw_same = 0, vSRAMTemplate_128_cov_cgoff = 0, vSRAMTemplate_128_cov_bore_w = 0, vSRAMTemplate_128_cov_bore_r = 0, vSRAMTemplate_128_cov_hold = 0, vSRAMTemplate_128_cov_rd_known = 0, vSRAMTemplate_128_cov_rd_nonzero = 0, vSRAMTemplate_128_cov_m0 = 0, vSRAMTemplate_128_cov_m1 = 0, vSRAMTemplate_128_cov_mmix = 0, vSRAMTemplate_128_cov_seg_all = 0;
  logic [5:0] vSRAMTemplate_128_seg_seen = '0;
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_128_io_r_req_valid <= 1'b0;
      vSRAMTemplate_128_io_w_req_valid <= 1'b0;
      vSRAMTemplate_128_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_128_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_128_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_128_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_128_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_128_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_128_io_r_req_bits_setIdx <= ($urandom_range(0,3)!=0) ? 2'($urandom_range(0,7)) : 2'($urandom);
      vSRAMTemplate_128_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_128_io_w_req_bits_setIdx <= ($urandom_range(0,3)!=0) ? 2'($urandom_range(0,7)) : 2'($urandom);
      vSRAMTemplate_128_io_w_req_bits_data_0 <= 393'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      vSRAMTemplate_128_io_w_req_bits_data_1 <= 393'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      case ($urandom_range(0,2))   // 全 0 / 全 1 / 混合 各 1/3
        0: vSRAMTemplate_128_io_w_req_bits_waymask <= 2'b0;
        1: vSRAMTemplate_128_io_w_req_bits_waymask <= {2{1'b1}};
        default: vSRAMTemplate_128_io_w_req_bits_waymask <= 2'($urandom);
      endcase
      vSRAMTemplate_128_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_128_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_128_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_128_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_128_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_128_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_128_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_128_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_128_boreChildrenBd_bore_addr <= 3'($urandom);
      vSRAMTemplate_128_boreChildrenBd_bore_addr_rd <= 3'($urandom);
      vSRAMTemplate_128_boreChildrenBd_bore_wdata <= 131'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      vSRAMTemplate_128_boreChildrenBd_bore_wmask <= 1'($urandom);
      vSRAMTemplate_128_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_128_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_128_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_128_boreChildrenBd_bore_selectedOH <= 6'(1) << $urandom_range(0,5);
      vSRAMTemplate_128_boreChildrenBd_bore_array <= 6'($urandom);
    end
  end
  always @(posedge clk) if (!rst && cycle > WARMUP) begin
    if (vSRAMTemplate_128_io_w_req_valid && !vSRAMTemplate_128_io_broadcast_ram_hold) vSRAMTemplate_128_cov_w++;
    if (vSRAMTemplate_128_io_w_req_valid && vSRAMTemplate_128_io_r_req_valid && vSRAMTemplate_128_io_w_req_bits_setIdx == vSRAMTemplate_128_io_r_req_bits_setIdx) vSRAMTemplate_128_cov_rw_same++;
    if (!vSRAMTemplate_128_io_w_req_valid && !vSRAMTemplate_128_io_r_req_valid && !vSRAMTemplate_128_boreChildrenBd_bore_ack) vSRAMTemplate_128_cov_cgoff++;
    if (vSRAMTemplate_128_boreChildrenBd_bore_ack && vSRAMTemplate_128_boreChildrenBd_bore_we) vSRAMTemplate_128_cov_bore_w++;
    if (vSRAMTemplate_128_boreChildrenBd_bore_ack && vSRAMTemplate_128_boreChildrenBd_bore_re) vSRAMTemplate_128_cov_bore_r++;
    if (vSRAMTemplate_128_io_broadcast_ram_hold) vSRAMTemplate_128_cov_hold++;
    if (vSRAMTemplate_128_io_w_req_valid) begin
      if (vSRAMTemplate_128_io_w_req_bits_waymask == 2'b0)      vSRAMTemplate_128_cov_m0++;
      else if (&vSRAMTemplate_128_io_w_req_bits_waymask)            vSRAMTemplate_128_cov_m1++;
      else                                  vSRAMTemplate_128_cov_mmix++;
    end
    if (vSRAMTemplate_128_boreChildrenBd_bore_ack) vSRAMTemplate_128_seg_seen <= vSRAMTemplate_128_seg_seen | vSRAMTemplate_128_boreChildrenBd_bore_selectedOH;
    vSRAMTemplate_128_cov_seg_all = &vSRAMTemplate_128_seg_seen;
    if (!has_x({vSRAMTemplate_128_g_io_r_resp_data_0, vSRAMTemplate_128_g_io_r_resp_data_1}, 786) && !has_z({vSRAMTemplate_128_g_io_r_resp_data_0, vSRAMTemplate_128_g_io_r_resp_data_1}, 786)) begin
      vSRAMTemplate_128_cov_rd_known++;
      if (|{vSRAMTemplate_128_g_io_r_resp_data_0, vSRAMTemplate_128_g_io_r_resp_data_1}) vSRAMTemplate_128_cov_rd_nonzero++;
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_128_g_io_r_resp_data_0 !== vSRAMTemplate_128_i_io_r_resp_data_0) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_128.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_128_g_io_r_resp_data_0, vSRAMTemplate_128_i_io_r_resp_data_0); end
    if (has_z(vSRAMTemplate_128_g_io_r_resp_data_0, 393) || has_z(vSRAMTemplate_128_i_io_r_resp_data_0, 393)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_128.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_128_g_io_r_resp_data_0, vSRAMTemplate_128_i_io_r_resp_data_0); end
    if (vSRAMTemplate_128_g_io_r_resp_data_1 !== vSRAMTemplate_128_i_io_r_resp_data_1) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_128.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_128_g_io_r_resp_data_1, vSRAMTemplate_128_i_io_r_resp_data_1); end
    if (has_z(vSRAMTemplate_128_g_io_r_resp_data_1, 393) || has_z(vSRAMTemplate_128_i_io_r_resp_data_1, 393)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_128.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_128_g_io_r_resp_data_1, vSRAMTemplate_128_i_io_r_resp_data_1); end
    if (vSRAMTemplate_128_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_128_i_boreChildrenBd_bore_rdata) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_128.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_128_g_boreChildrenBd_bore_rdata, vSRAMTemplate_128_i_boreChildrenBd_bore_rdata); end
    if (has_z(vSRAMTemplate_128_g_boreChildrenBd_bore_rdata, 131) || has_z(vSRAMTemplate_128_i_boreChildrenBd_bore_rdata, 131)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_128.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_128_g_boreChildrenBd_bore_rdata, vSRAMTemplate_128_i_boreChildrenBd_bore_rdata); end
  end

  // ================= SRAMTemplate_145 =================
  logic vSRAMTemplate_145_io_r_req_valid;
  logic [4:0] vSRAMTemplate_145_io_r_req_bits_setIdx;
  logic vSRAMTemplate_145_io_w_req_valid;
  logic [4:0] vSRAMTemplate_145_io_w_req_bits_setIdx;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_0;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_1;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_2;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_3;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_4;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_5;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_6;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_7;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_8;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_9;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_10;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_11;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_12;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_13;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_14;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_15;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_16;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_17;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_18;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_19;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_20;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_21;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_22;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_23;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_24;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_25;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_26;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_27;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_28;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_0_hist_29;
  logic [12:0] vSRAMTemplate_145_io_w_req_bits_data_0_tag;
  logic vSRAMTemplate_145_io_w_req_bits_data_0_decr_mode;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_0;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_1;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_2;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_3;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_4;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_5;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_6;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_7;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_8;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_9;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_10;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_11;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_12;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_13;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_14;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_15;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_16;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_17;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_18;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_19;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_20;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_21;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_22;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_23;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_24;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_25;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_26;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_27;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_28;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_data_1_hist_29;
  logic [12:0] vSRAMTemplate_145_io_w_req_bits_data_1_tag;
  logic vSRAMTemplate_145_io_w_req_bits_data_1_decr_mode;
  logic [1:0] vSRAMTemplate_145_io_w_req_bits_waymask;
  logic vSRAMTemplate_145_io_broadcast_ram_hold;
  logic vSRAMTemplate_145_io_broadcast_ram_bypass;
  logic vSRAMTemplate_145_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_145_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_145_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_145_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_145_io_broadcast_ram_ctl;
  logic vSRAMTemplate_145_io_broadcast_cgen;
  logic [5:0] vSRAMTemplate_145_boreChildrenBd_bore_addr;
  logic [5:0] vSRAMTemplate_145_boreChildrenBd_bore_addr_rd;
  logic [147:0] vSRAMTemplate_145_boreChildrenBd_bore_wdata;
  logic [1:0] vSRAMTemplate_145_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_145_boreChildrenBd_bore_re;
  logic vSRAMTemplate_145_boreChildrenBd_bore_we;
  logic vSRAMTemplate_145_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_145_boreChildrenBd_bore_selectedOH;
  logic [6:0] vSRAMTemplate_145_boreChildrenBd_bore_array;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_0;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_0;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_1;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_1;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_2;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_2;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_3;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_3;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_4;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_4;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_5;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_5;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_6;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_6;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_7;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_7;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_8;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_8;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_9;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_9;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_10;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_10;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_11;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_11;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_12;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_12;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_13;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_13;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_14;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_14;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_15;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_15;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_16;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_16;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_17;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_17;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_18;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_18;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_19;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_19;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_20;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_20;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_21;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_21;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_22;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_22;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_23;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_23;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_24;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_24;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_25;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_25;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_26;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_26;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_27;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_27;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_28;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_28;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_0_hist_29;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_0_hist_29;
  wire [12:0] vSRAMTemplate_145_g_io_r_resp_data_0_tag;
  wire [12:0] vSRAMTemplate_145_i_io_r_resp_data_0_tag;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_0;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_0;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_1;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_1;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_2;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_2;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_3;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_3;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_4;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_4;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_5;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_5;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_6;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_6;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_7;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_7;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_8;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_8;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_9;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_9;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_10;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_10;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_11;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_11;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_12;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_12;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_13;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_13;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_14;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_14;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_15;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_15;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_16;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_16;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_17;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_17;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_18;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_18;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_19;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_19;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_20;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_20;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_21;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_21;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_22;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_22;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_23;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_23;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_24;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_24;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_25;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_25;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_26;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_26;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_27;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_27;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_28;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_28;
  wire [1:0] vSRAMTemplate_145_g_io_r_resp_data_1_hist_29;
  wire [1:0] vSRAMTemplate_145_i_io_r_resp_data_1_hist_29;
  wire [12:0] vSRAMTemplate_145_g_io_r_resp_data_1_tag;
  wire [12:0] vSRAMTemplate_145_i_io_r_resp_data_1_tag;
  wire [147:0] vSRAMTemplate_145_g_boreChildrenBd_bore_rdata;
  wire [147:0] vSRAMTemplate_145_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_145    u_g_SRAMTemplate_145 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_145_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_145_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_145_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_145_io_w_req_bits_setIdx), .io_w_req_bits_data_0_hist_0(vSRAMTemplate_145_io_w_req_bits_data_0_hist_0), .io_w_req_bits_data_0_hist_1(vSRAMTemplate_145_io_w_req_bits_data_0_hist_1), .io_w_req_bits_data_0_hist_2(vSRAMTemplate_145_io_w_req_bits_data_0_hist_2), .io_w_req_bits_data_0_hist_3(vSRAMTemplate_145_io_w_req_bits_data_0_hist_3), .io_w_req_bits_data_0_hist_4(vSRAMTemplate_145_io_w_req_bits_data_0_hist_4), .io_w_req_bits_data_0_hist_5(vSRAMTemplate_145_io_w_req_bits_data_0_hist_5), .io_w_req_bits_data_0_hist_6(vSRAMTemplate_145_io_w_req_bits_data_0_hist_6), .io_w_req_bits_data_0_hist_7(vSRAMTemplate_145_io_w_req_bits_data_0_hist_7), .io_w_req_bits_data_0_hist_8(vSRAMTemplate_145_io_w_req_bits_data_0_hist_8), .io_w_req_bits_data_0_hist_9(vSRAMTemplate_145_io_w_req_bits_data_0_hist_9), .io_w_req_bits_data_0_hist_10(vSRAMTemplate_145_io_w_req_bits_data_0_hist_10), .io_w_req_bits_data_0_hist_11(vSRAMTemplate_145_io_w_req_bits_data_0_hist_11), .io_w_req_bits_data_0_hist_12(vSRAMTemplate_145_io_w_req_bits_data_0_hist_12), .io_w_req_bits_data_0_hist_13(vSRAMTemplate_145_io_w_req_bits_data_0_hist_13), .io_w_req_bits_data_0_hist_14(vSRAMTemplate_145_io_w_req_bits_data_0_hist_14), .io_w_req_bits_data_0_hist_15(vSRAMTemplate_145_io_w_req_bits_data_0_hist_15), .io_w_req_bits_data_0_hist_16(vSRAMTemplate_145_io_w_req_bits_data_0_hist_16), .io_w_req_bits_data_0_hist_17(vSRAMTemplate_145_io_w_req_bits_data_0_hist_17), .io_w_req_bits_data_0_hist_18(vSRAMTemplate_145_io_w_req_bits_data_0_hist_18), .io_w_req_bits_data_0_hist_19(vSRAMTemplate_145_io_w_req_bits_data_0_hist_19), .io_w_req_bits_data_0_hist_20(vSRAMTemplate_145_io_w_req_bits_data_0_hist_20), .io_w_req_bits_data_0_hist_21(vSRAMTemplate_145_io_w_req_bits_data_0_hist_21), .io_w_req_bits_data_0_hist_22(vSRAMTemplate_145_io_w_req_bits_data_0_hist_22), .io_w_req_bits_data_0_hist_23(vSRAMTemplate_145_io_w_req_bits_data_0_hist_23), .io_w_req_bits_data_0_hist_24(vSRAMTemplate_145_io_w_req_bits_data_0_hist_24), .io_w_req_bits_data_0_hist_25(vSRAMTemplate_145_io_w_req_bits_data_0_hist_25), .io_w_req_bits_data_0_hist_26(vSRAMTemplate_145_io_w_req_bits_data_0_hist_26), .io_w_req_bits_data_0_hist_27(vSRAMTemplate_145_io_w_req_bits_data_0_hist_27), .io_w_req_bits_data_0_hist_28(vSRAMTemplate_145_io_w_req_bits_data_0_hist_28), .io_w_req_bits_data_0_hist_29(vSRAMTemplate_145_io_w_req_bits_data_0_hist_29), .io_w_req_bits_data_0_tag(vSRAMTemplate_145_io_w_req_bits_data_0_tag), .io_w_req_bits_data_0_decr_mode(vSRAMTemplate_145_io_w_req_bits_data_0_decr_mode), .io_w_req_bits_data_1_hist_0(vSRAMTemplate_145_io_w_req_bits_data_1_hist_0), .io_w_req_bits_data_1_hist_1(vSRAMTemplate_145_io_w_req_bits_data_1_hist_1), .io_w_req_bits_data_1_hist_2(vSRAMTemplate_145_io_w_req_bits_data_1_hist_2), .io_w_req_bits_data_1_hist_3(vSRAMTemplate_145_io_w_req_bits_data_1_hist_3), .io_w_req_bits_data_1_hist_4(vSRAMTemplate_145_io_w_req_bits_data_1_hist_4), .io_w_req_bits_data_1_hist_5(vSRAMTemplate_145_io_w_req_bits_data_1_hist_5), .io_w_req_bits_data_1_hist_6(vSRAMTemplate_145_io_w_req_bits_data_1_hist_6), .io_w_req_bits_data_1_hist_7(vSRAMTemplate_145_io_w_req_bits_data_1_hist_7), .io_w_req_bits_data_1_hist_8(vSRAMTemplate_145_io_w_req_bits_data_1_hist_8), .io_w_req_bits_data_1_hist_9(vSRAMTemplate_145_io_w_req_bits_data_1_hist_9), .io_w_req_bits_data_1_hist_10(vSRAMTemplate_145_io_w_req_bits_data_1_hist_10), .io_w_req_bits_data_1_hist_11(vSRAMTemplate_145_io_w_req_bits_data_1_hist_11), .io_w_req_bits_data_1_hist_12(vSRAMTemplate_145_io_w_req_bits_data_1_hist_12), .io_w_req_bits_data_1_hist_13(vSRAMTemplate_145_io_w_req_bits_data_1_hist_13), .io_w_req_bits_data_1_hist_14(vSRAMTemplate_145_io_w_req_bits_data_1_hist_14), .io_w_req_bits_data_1_hist_15(vSRAMTemplate_145_io_w_req_bits_data_1_hist_15), .io_w_req_bits_data_1_hist_16(vSRAMTemplate_145_io_w_req_bits_data_1_hist_16), .io_w_req_bits_data_1_hist_17(vSRAMTemplate_145_io_w_req_bits_data_1_hist_17), .io_w_req_bits_data_1_hist_18(vSRAMTemplate_145_io_w_req_bits_data_1_hist_18), .io_w_req_bits_data_1_hist_19(vSRAMTemplate_145_io_w_req_bits_data_1_hist_19), .io_w_req_bits_data_1_hist_20(vSRAMTemplate_145_io_w_req_bits_data_1_hist_20), .io_w_req_bits_data_1_hist_21(vSRAMTemplate_145_io_w_req_bits_data_1_hist_21), .io_w_req_bits_data_1_hist_22(vSRAMTemplate_145_io_w_req_bits_data_1_hist_22), .io_w_req_bits_data_1_hist_23(vSRAMTemplate_145_io_w_req_bits_data_1_hist_23), .io_w_req_bits_data_1_hist_24(vSRAMTemplate_145_io_w_req_bits_data_1_hist_24), .io_w_req_bits_data_1_hist_25(vSRAMTemplate_145_io_w_req_bits_data_1_hist_25), .io_w_req_bits_data_1_hist_26(vSRAMTemplate_145_io_w_req_bits_data_1_hist_26), .io_w_req_bits_data_1_hist_27(vSRAMTemplate_145_io_w_req_bits_data_1_hist_27), .io_w_req_bits_data_1_hist_28(vSRAMTemplate_145_io_w_req_bits_data_1_hist_28), .io_w_req_bits_data_1_hist_29(vSRAMTemplate_145_io_w_req_bits_data_1_hist_29), .io_w_req_bits_data_1_tag(vSRAMTemplate_145_io_w_req_bits_data_1_tag), .io_w_req_bits_data_1_decr_mode(vSRAMTemplate_145_io_w_req_bits_data_1_decr_mode), .io_w_req_bits_waymask(vSRAMTemplate_145_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_145_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_145_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_145_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_145_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_145_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_145_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_145_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_145_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_145_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_145_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_145_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_145_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_145_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_145_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_145_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_145_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_145_boreChildrenBd_bore_array), .io_r_resp_data_0_hist_0(vSRAMTemplate_145_g_io_r_resp_data_0_hist_0), .io_r_resp_data_0_hist_1(vSRAMTemplate_145_g_io_r_resp_data_0_hist_1), .io_r_resp_data_0_hist_2(vSRAMTemplate_145_g_io_r_resp_data_0_hist_2), .io_r_resp_data_0_hist_3(vSRAMTemplate_145_g_io_r_resp_data_0_hist_3), .io_r_resp_data_0_hist_4(vSRAMTemplate_145_g_io_r_resp_data_0_hist_4), .io_r_resp_data_0_hist_5(vSRAMTemplate_145_g_io_r_resp_data_0_hist_5), .io_r_resp_data_0_hist_6(vSRAMTemplate_145_g_io_r_resp_data_0_hist_6), .io_r_resp_data_0_hist_7(vSRAMTemplate_145_g_io_r_resp_data_0_hist_7), .io_r_resp_data_0_hist_8(vSRAMTemplate_145_g_io_r_resp_data_0_hist_8), .io_r_resp_data_0_hist_9(vSRAMTemplate_145_g_io_r_resp_data_0_hist_9), .io_r_resp_data_0_hist_10(vSRAMTemplate_145_g_io_r_resp_data_0_hist_10), .io_r_resp_data_0_hist_11(vSRAMTemplate_145_g_io_r_resp_data_0_hist_11), .io_r_resp_data_0_hist_12(vSRAMTemplate_145_g_io_r_resp_data_0_hist_12), .io_r_resp_data_0_hist_13(vSRAMTemplate_145_g_io_r_resp_data_0_hist_13), .io_r_resp_data_0_hist_14(vSRAMTemplate_145_g_io_r_resp_data_0_hist_14), .io_r_resp_data_0_hist_15(vSRAMTemplate_145_g_io_r_resp_data_0_hist_15), .io_r_resp_data_0_hist_16(vSRAMTemplate_145_g_io_r_resp_data_0_hist_16), .io_r_resp_data_0_hist_17(vSRAMTemplate_145_g_io_r_resp_data_0_hist_17), .io_r_resp_data_0_hist_18(vSRAMTemplate_145_g_io_r_resp_data_0_hist_18), .io_r_resp_data_0_hist_19(vSRAMTemplate_145_g_io_r_resp_data_0_hist_19), .io_r_resp_data_0_hist_20(vSRAMTemplate_145_g_io_r_resp_data_0_hist_20), .io_r_resp_data_0_hist_21(vSRAMTemplate_145_g_io_r_resp_data_0_hist_21), .io_r_resp_data_0_hist_22(vSRAMTemplate_145_g_io_r_resp_data_0_hist_22), .io_r_resp_data_0_hist_23(vSRAMTemplate_145_g_io_r_resp_data_0_hist_23), .io_r_resp_data_0_hist_24(vSRAMTemplate_145_g_io_r_resp_data_0_hist_24), .io_r_resp_data_0_hist_25(vSRAMTemplate_145_g_io_r_resp_data_0_hist_25), .io_r_resp_data_0_hist_26(vSRAMTemplate_145_g_io_r_resp_data_0_hist_26), .io_r_resp_data_0_hist_27(vSRAMTemplate_145_g_io_r_resp_data_0_hist_27), .io_r_resp_data_0_hist_28(vSRAMTemplate_145_g_io_r_resp_data_0_hist_28), .io_r_resp_data_0_hist_29(vSRAMTemplate_145_g_io_r_resp_data_0_hist_29), .io_r_resp_data_0_tag(vSRAMTemplate_145_g_io_r_resp_data_0_tag), .io_r_resp_data_1_hist_0(vSRAMTemplate_145_g_io_r_resp_data_1_hist_0), .io_r_resp_data_1_hist_1(vSRAMTemplate_145_g_io_r_resp_data_1_hist_1), .io_r_resp_data_1_hist_2(vSRAMTemplate_145_g_io_r_resp_data_1_hist_2), .io_r_resp_data_1_hist_3(vSRAMTemplate_145_g_io_r_resp_data_1_hist_3), .io_r_resp_data_1_hist_4(vSRAMTemplate_145_g_io_r_resp_data_1_hist_4), .io_r_resp_data_1_hist_5(vSRAMTemplate_145_g_io_r_resp_data_1_hist_5), .io_r_resp_data_1_hist_6(vSRAMTemplate_145_g_io_r_resp_data_1_hist_6), .io_r_resp_data_1_hist_7(vSRAMTemplate_145_g_io_r_resp_data_1_hist_7), .io_r_resp_data_1_hist_8(vSRAMTemplate_145_g_io_r_resp_data_1_hist_8), .io_r_resp_data_1_hist_9(vSRAMTemplate_145_g_io_r_resp_data_1_hist_9), .io_r_resp_data_1_hist_10(vSRAMTemplate_145_g_io_r_resp_data_1_hist_10), .io_r_resp_data_1_hist_11(vSRAMTemplate_145_g_io_r_resp_data_1_hist_11), .io_r_resp_data_1_hist_12(vSRAMTemplate_145_g_io_r_resp_data_1_hist_12), .io_r_resp_data_1_hist_13(vSRAMTemplate_145_g_io_r_resp_data_1_hist_13), .io_r_resp_data_1_hist_14(vSRAMTemplate_145_g_io_r_resp_data_1_hist_14), .io_r_resp_data_1_hist_15(vSRAMTemplate_145_g_io_r_resp_data_1_hist_15), .io_r_resp_data_1_hist_16(vSRAMTemplate_145_g_io_r_resp_data_1_hist_16), .io_r_resp_data_1_hist_17(vSRAMTemplate_145_g_io_r_resp_data_1_hist_17), .io_r_resp_data_1_hist_18(vSRAMTemplate_145_g_io_r_resp_data_1_hist_18), .io_r_resp_data_1_hist_19(vSRAMTemplate_145_g_io_r_resp_data_1_hist_19), .io_r_resp_data_1_hist_20(vSRAMTemplate_145_g_io_r_resp_data_1_hist_20), .io_r_resp_data_1_hist_21(vSRAMTemplate_145_g_io_r_resp_data_1_hist_21), .io_r_resp_data_1_hist_22(vSRAMTemplate_145_g_io_r_resp_data_1_hist_22), .io_r_resp_data_1_hist_23(vSRAMTemplate_145_g_io_r_resp_data_1_hist_23), .io_r_resp_data_1_hist_24(vSRAMTemplate_145_g_io_r_resp_data_1_hist_24), .io_r_resp_data_1_hist_25(vSRAMTemplate_145_g_io_r_resp_data_1_hist_25), .io_r_resp_data_1_hist_26(vSRAMTemplate_145_g_io_r_resp_data_1_hist_26), .io_r_resp_data_1_hist_27(vSRAMTemplate_145_g_io_r_resp_data_1_hist_27), .io_r_resp_data_1_hist_28(vSRAMTemplate_145_g_io_r_resp_data_1_hist_28), .io_r_resp_data_1_hist_29(vSRAMTemplate_145_g_io_r_resp_data_1_hist_29), .io_r_resp_data_1_tag(vSRAMTemplate_145_g_io_r_resp_data_1_tag), .boreChildrenBd_bore_rdata(vSRAMTemplate_145_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_145_xs u_i_SRAMTemplate_145 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_145_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_145_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_145_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_145_io_w_req_bits_setIdx), .io_w_req_bits_data_0_hist_0(vSRAMTemplate_145_io_w_req_bits_data_0_hist_0), .io_w_req_bits_data_0_hist_1(vSRAMTemplate_145_io_w_req_bits_data_0_hist_1), .io_w_req_bits_data_0_hist_2(vSRAMTemplate_145_io_w_req_bits_data_0_hist_2), .io_w_req_bits_data_0_hist_3(vSRAMTemplate_145_io_w_req_bits_data_0_hist_3), .io_w_req_bits_data_0_hist_4(vSRAMTemplate_145_io_w_req_bits_data_0_hist_4), .io_w_req_bits_data_0_hist_5(vSRAMTemplate_145_io_w_req_bits_data_0_hist_5), .io_w_req_bits_data_0_hist_6(vSRAMTemplate_145_io_w_req_bits_data_0_hist_6), .io_w_req_bits_data_0_hist_7(vSRAMTemplate_145_io_w_req_bits_data_0_hist_7), .io_w_req_bits_data_0_hist_8(vSRAMTemplate_145_io_w_req_bits_data_0_hist_8), .io_w_req_bits_data_0_hist_9(vSRAMTemplate_145_io_w_req_bits_data_0_hist_9), .io_w_req_bits_data_0_hist_10(vSRAMTemplate_145_io_w_req_bits_data_0_hist_10), .io_w_req_bits_data_0_hist_11(vSRAMTemplate_145_io_w_req_bits_data_0_hist_11), .io_w_req_bits_data_0_hist_12(vSRAMTemplate_145_io_w_req_bits_data_0_hist_12), .io_w_req_bits_data_0_hist_13(vSRAMTemplate_145_io_w_req_bits_data_0_hist_13), .io_w_req_bits_data_0_hist_14(vSRAMTemplate_145_io_w_req_bits_data_0_hist_14), .io_w_req_bits_data_0_hist_15(vSRAMTemplate_145_io_w_req_bits_data_0_hist_15), .io_w_req_bits_data_0_hist_16(vSRAMTemplate_145_io_w_req_bits_data_0_hist_16), .io_w_req_bits_data_0_hist_17(vSRAMTemplate_145_io_w_req_bits_data_0_hist_17), .io_w_req_bits_data_0_hist_18(vSRAMTemplate_145_io_w_req_bits_data_0_hist_18), .io_w_req_bits_data_0_hist_19(vSRAMTemplate_145_io_w_req_bits_data_0_hist_19), .io_w_req_bits_data_0_hist_20(vSRAMTemplate_145_io_w_req_bits_data_0_hist_20), .io_w_req_bits_data_0_hist_21(vSRAMTemplate_145_io_w_req_bits_data_0_hist_21), .io_w_req_bits_data_0_hist_22(vSRAMTemplate_145_io_w_req_bits_data_0_hist_22), .io_w_req_bits_data_0_hist_23(vSRAMTemplate_145_io_w_req_bits_data_0_hist_23), .io_w_req_bits_data_0_hist_24(vSRAMTemplate_145_io_w_req_bits_data_0_hist_24), .io_w_req_bits_data_0_hist_25(vSRAMTemplate_145_io_w_req_bits_data_0_hist_25), .io_w_req_bits_data_0_hist_26(vSRAMTemplate_145_io_w_req_bits_data_0_hist_26), .io_w_req_bits_data_0_hist_27(vSRAMTemplate_145_io_w_req_bits_data_0_hist_27), .io_w_req_bits_data_0_hist_28(vSRAMTemplate_145_io_w_req_bits_data_0_hist_28), .io_w_req_bits_data_0_hist_29(vSRAMTemplate_145_io_w_req_bits_data_0_hist_29), .io_w_req_bits_data_0_tag(vSRAMTemplate_145_io_w_req_bits_data_0_tag), .io_w_req_bits_data_0_decr_mode(vSRAMTemplate_145_io_w_req_bits_data_0_decr_mode), .io_w_req_bits_data_1_hist_0(vSRAMTemplate_145_io_w_req_bits_data_1_hist_0), .io_w_req_bits_data_1_hist_1(vSRAMTemplate_145_io_w_req_bits_data_1_hist_1), .io_w_req_bits_data_1_hist_2(vSRAMTemplate_145_io_w_req_bits_data_1_hist_2), .io_w_req_bits_data_1_hist_3(vSRAMTemplate_145_io_w_req_bits_data_1_hist_3), .io_w_req_bits_data_1_hist_4(vSRAMTemplate_145_io_w_req_bits_data_1_hist_4), .io_w_req_bits_data_1_hist_5(vSRAMTemplate_145_io_w_req_bits_data_1_hist_5), .io_w_req_bits_data_1_hist_6(vSRAMTemplate_145_io_w_req_bits_data_1_hist_6), .io_w_req_bits_data_1_hist_7(vSRAMTemplate_145_io_w_req_bits_data_1_hist_7), .io_w_req_bits_data_1_hist_8(vSRAMTemplate_145_io_w_req_bits_data_1_hist_8), .io_w_req_bits_data_1_hist_9(vSRAMTemplate_145_io_w_req_bits_data_1_hist_9), .io_w_req_bits_data_1_hist_10(vSRAMTemplate_145_io_w_req_bits_data_1_hist_10), .io_w_req_bits_data_1_hist_11(vSRAMTemplate_145_io_w_req_bits_data_1_hist_11), .io_w_req_bits_data_1_hist_12(vSRAMTemplate_145_io_w_req_bits_data_1_hist_12), .io_w_req_bits_data_1_hist_13(vSRAMTemplate_145_io_w_req_bits_data_1_hist_13), .io_w_req_bits_data_1_hist_14(vSRAMTemplate_145_io_w_req_bits_data_1_hist_14), .io_w_req_bits_data_1_hist_15(vSRAMTemplate_145_io_w_req_bits_data_1_hist_15), .io_w_req_bits_data_1_hist_16(vSRAMTemplate_145_io_w_req_bits_data_1_hist_16), .io_w_req_bits_data_1_hist_17(vSRAMTemplate_145_io_w_req_bits_data_1_hist_17), .io_w_req_bits_data_1_hist_18(vSRAMTemplate_145_io_w_req_bits_data_1_hist_18), .io_w_req_bits_data_1_hist_19(vSRAMTemplate_145_io_w_req_bits_data_1_hist_19), .io_w_req_bits_data_1_hist_20(vSRAMTemplate_145_io_w_req_bits_data_1_hist_20), .io_w_req_bits_data_1_hist_21(vSRAMTemplate_145_io_w_req_bits_data_1_hist_21), .io_w_req_bits_data_1_hist_22(vSRAMTemplate_145_io_w_req_bits_data_1_hist_22), .io_w_req_bits_data_1_hist_23(vSRAMTemplate_145_io_w_req_bits_data_1_hist_23), .io_w_req_bits_data_1_hist_24(vSRAMTemplate_145_io_w_req_bits_data_1_hist_24), .io_w_req_bits_data_1_hist_25(vSRAMTemplate_145_io_w_req_bits_data_1_hist_25), .io_w_req_bits_data_1_hist_26(vSRAMTemplate_145_io_w_req_bits_data_1_hist_26), .io_w_req_bits_data_1_hist_27(vSRAMTemplate_145_io_w_req_bits_data_1_hist_27), .io_w_req_bits_data_1_hist_28(vSRAMTemplate_145_io_w_req_bits_data_1_hist_28), .io_w_req_bits_data_1_hist_29(vSRAMTemplate_145_io_w_req_bits_data_1_hist_29), .io_w_req_bits_data_1_tag(vSRAMTemplate_145_io_w_req_bits_data_1_tag), .io_w_req_bits_data_1_decr_mode(vSRAMTemplate_145_io_w_req_bits_data_1_decr_mode), .io_w_req_bits_waymask(vSRAMTemplate_145_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_145_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_145_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_145_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_145_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_145_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_145_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_145_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_145_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_145_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_145_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_145_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_145_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_145_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_145_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_145_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_145_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_145_boreChildrenBd_bore_array), .io_r_resp_data_0_hist_0(vSRAMTemplate_145_i_io_r_resp_data_0_hist_0), .io_r_resp_data_0_hist_1(vSRAMTemplate_145_i_io_r_resp_data_0_hist_1), .io_r_resp_data_0_hist_2(vSRAMTemplate_145_i_io_r_resp_data_0_hist_2), .io_r_resp_data_0_hist_3(vSRAMTemplate_145_i_io_r_resp_data_0_hist_3), .io_r_resp_data_0_hist_4(vSRAMTemplate_145_i_io_r_resp_data_0_hist_4), .io_r_resp_data_0_hist_5(vSRAMTemplate_145_i_io_r_resp_data_0_hist_5), .io_r_resp_data_0_hist_6(vSRAMTemplate_145_i_io_r_resp_data_0_hist_6), .io_r_resp_data_0_hist_7(vSRAMTemplate_145_i_io_r_resp_data_0_hist_7), .io_r_resp_data_0_hist_8(vSRAMTemplate_145_i_io_r_resp_data_0_hist_8), .io_r_resp_data_0_hist_9(vSRAMTemplate_145_i_io_r_resp_data_0_hist_9), .io_r_resp_data_0_hist_10(vSRAMTemplate_145_i_io_r_resp_data_0_hist_10), .io_r_resp_data_0_hist_11(vSRAMTemplate_145_i_io_r_resp_data_0_hist_11), .io_r_resp_data_0_hist_12(vSRAMTemplate_145_i_io_r_resp_data_0_hist_12), .io_r_resp_data_0_hist_13(vSRAMTemplate_145_i_io_r_resp_data_0_hist_13), .io_r_resp_data_0_hist_14(vSRAMTemplate_145_i_io_r_resp_data_0_hist_14), .io_r_resp_data_0_hist_15(vSRAMTemplate_145_i_io_r_resp_data_0_hist_15), .io_r_resp_data_0_hist_16(vSRAMTemplate_145_i_io_r_resp_data_0_hist_16), .io_r_resp_data_0_hist_17(vSRAMTemplate_145_i_io_r_resp_data_0_hist_17), .io_r_resp_data_0_hist_18(vSRAMTemplate_145_i_io_r_resp_data_0_hist_18), .io_r_resp_data_0_hist_19(vSRAMTemplate_145_i_io_r_resp_data_0_hist_19), .io_r_resp_data_0_hist_20(vSRAMTemplate_145_i_io_r_resp_data_0_hist_20), .io_r_resp_data_0_hist_21(vSRAMTemplate_145_i_io_r_resp_data_0_hist_21), .io_r_resp_data_0_hist_22(vSRAMTemplate_145_i_io_r_resp_data_0_hist_22), .io_r_resp_data_0_hist_23(vSRAMTemplate_145_i_io_r_resp_data_0_hist_23), .io_r_resp_data_0_hist_24(vSRAMTemplate_145_i_io_r_resp_data_0_hist_24), .io_r_resp_data_0_hist_25(vSRAMTemplate_145_i_io_r_resp_data_0_hist_25), .io_r_resp_data_0_hist_26(vSRAMTemplate_145_i_io_r_resp_data_0_hist_26), .io_r_resp_data_0_hist_27(vSRAMTemplate_145_i_io_r_resp_data_0_hist_27), .io_r_resp_data_0_hist_28(vSRAMTemplate_145_i_io_r_resp_data_0_hist_28), .io_r_resp_data_0_hist_29(vSRAMTemplate_145_i_io_r_resp_data_0_hist_29), .io_r_resp_data_0_tag(vSRAMTemplate_145_i_io_r_resp_data_0_tag), .io_r_resp_data_1_hist_0(vSRAMTemplate_145_i_io_r_resp_data_1_hist_0), .io_r_resp_data_1_hist_1(vSRAMTemplate_145_i_io_r_resp_data_1_hist_1), .io_r_resp_data_1_hist_2(vSRAMTemplate_145_i_io_r_resp_data_1_hist_2), .io_r_resp_data_1_hist_3(vSRAMTemplate_145_i_io_r_resp_data_1_hist_3), .io_r_resp_data_1_hist_4(vSRAMTemplate_145_i_io_r_resp_data_1_hist_4), .io_r_resp_data_1_hist_5(vSRAMTemplate_145_i_io_r_resp_data_1_hist_5), .io_r_resp_data_1_hist_6(vSRAMTemplate_145_i_io_r_resp_data_1_hist_6), .io_r_resp_data_1_hist_7(vSRAMTemplate_145_i_io_r_resp_data_1_hist_7), .io_r_resp_data_1_hist_8(vSRAMTemplate_145_i_io_r_resp_data_1_hist_8), .io_r_resp_data_1_hist_9(vSRAMTemplate_145_i_io_r_resp_data_1_hist_9), .io_r_resp_data_1_hist_10(vSRAMTemplate_145_i_io_r_resp_data_1_hist_10), .io_r_resp_data_1_hist_11(vSRAMTemplate_145_i_io_r_resp_data_1_hist_11), .io_r_resp_data_1_hist_12(vSRAMTemplate_145_i_io_r_resp_data_1_hist_12), .io_r_resp_data_1_hist_13(vSRAMTemplate_145_i_io_r_resp_data_1_hist_13), .io_r_resp_data_1_hist_14(vSRAMTemplate_145_i_io_r_resp_data_1_hist_14), .io_r_resp_data_1_hist_15(vSRAMTemplate_145_i_io_r_resp_data_1_hist_15), .io_r_resp_data_1_hist_16(vSRAMTemplate_145_i_io_r_resp_data_1_hist_16), .io_r_resp_data_1_hist_17(vSRAMTemplate_145_i_io_r_resp_data_1_hist_17), .io_r_resp_data_1_hist_18(vSRAMTemplate_145_i_io_r_resp_data_1_hist_18), .io_r_resp_data_1_hist_19(vSRAMTemplate_145_i_io_r_resp_data_1_hist_19), .io_r_resp_data_1_hist_20(vSRAMTemplate_145_i_io_r_resp_data_1_hist_20), .io_r_resp_data_1_hist_21(vSRAMTemplate_145_i_io_r_resp_data_1_hist_21), .io_r_resp_data_1_hist_22(vSRAMTemplate_145_i_io_r_resp_data_1_hist_22), .io_r_resp_data_1_hist_23(vSRAMTemplate_145_i_io_r_resp_data_1_hist_23), .io_r_resp_data_1_hist_24(vSRAMTemplate_145_i_io_r_resp_data_1_hist_24), .io_r_resp_data_1_hist_25(vSRAMTemplate_145_i_io_r_resp_data_1_hist_25), .io_r_resp_data_1_hist_26(vSRAMTemplate_145_i_io_r_resp_data_1_hist_26), .io_r_resp_data_1_hist_27(vSRAMTemplate_145_i_io_r_resp_data_1_hist_27), .io_r_resp_data_1_hist_28(vSRAMTemplate_145_i_io_r_resp_data_1_hist_28), .io_r_resp_data_1_hist_29(vSRAMTemplate_145_i_io_r_resp_data_1_hist_29), .io_r_resp_data_1_tag(vSRAMTemplate_145_i_io_r_resp_data_1_tag), .boreChildrenBd_bore_rdata(vSRAMTemplate_145_i_boreChildrenBd_bore_rdata));
  int vSRAMTemplate_145_cov_w = 0, vSRAMTemplate_145_cov_rw_same = 0, vSRAMTemplate_145_cov_cgoff = 0, vSRAMTemplate_145_cov_bore_w = 0, vSRAMTemplate_145_cov_bore_r = 0, vSRAMTemplate_145_cov_hold = 0, vSRAMTemplate_145_cov_rd_known = 0, vSRAMTemplate_145_cov_rd_nonzero = 0, vSRAMTemplate_145_cov_m0 = 0, vSRAMTemplate_145_cov_m1 = 0, vSRAMTemplate_145_cov_mmix = 0;
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_145_io_r_req_valid <= 1'b0;
      vSRAMTemplate_145_io_w_req_valid <= 1'b0;
      vSRAMTemplate_145_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_145_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_145_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_145_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_145_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_145_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_145_io_r_req_bits_setIdx <= ($urandom_range(0,3)!=0) ? 5'($urandom_range(0,7)) : 5'($urandom);
      vSRAMTemplate_145_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_145_io_w_req_bits_setIdx <= ($urandom_range(0,3)!=0) ? 5'($urandom_range(0,7)) : 5'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_0 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_1 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_2 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_3 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_4 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_5 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_6 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_7 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_8 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_9 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_10 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_11 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_12 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_13 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_14 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_15 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_16 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_17 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_18 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_19 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_20 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_21 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_22 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_23 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_24 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_25 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_26 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_27 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_28 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_hist_29 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_tag <= 13'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_0_decr_mode <= 1'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_0 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_1 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_2 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_3 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_4 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_5 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_6 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_7 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_8 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_9 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_10 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_11 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_12 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_13 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_14 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_15 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_16 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_17 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_18 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_19 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_20 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_21 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_22 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_23 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_24 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_25 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_26 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_27 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_28 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_hist_29 <= 2'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_tag <= 13'($urandom);
      vSRAMTemplate_145_io_w_req_bits_data_1_decr_mode <= 1'($urandom);
      case ($urandom_range(0,2))   // 全 0 / 全 1 / 混合 各 1/3
        0: vSRAMTemplate_145_io_w_req_bits_waymask <= 2'b0;
        1: vSRAMTemplate_145_io_w_req_bits_waymask <= {2{1'b1}};
        default: vSRAMTemplate_145_io_w_req_bits_waymask <= 2'($urandom);
      endcase
      vSRAMTemplate_145_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_145_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_145_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_145_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_145_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_145_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_145_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_145_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_145_boreChildrenBd_bore_addr <= 6'($urandom);
      vSRAMTemplate_145_boreChildrenBd_bore_addr_rd <= 6'($urandom);
      vSRAMTemplate_145_boreChildrenBd_bore_wdata <= 148'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      vSRAMTemplate_145_boreChildrenBd_bore_wmask <= 2'($urandom);
      vSRAMTemplate_145_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_145_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_145_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_145_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_145_boreChildrenBd_bore_array <= 7'($urandom);
    end
  end
  always @(posedge clk) if (!rst && cycle > WARMUP) begin
    if (vSRAMTemplate_145_io_w_req_valid && !vSRAMTemplate_145_io_broadcast_ram_hold) vSRAMTemplate_145_cov_w++;
    if (vSRAMTemplate_145_io_w_req_valid && vSRAMTemplate_145_io_r_req_valid && vSRAMTemplate_145_io_w_req_bits_setIdx == vSRAMTemplate_145_io_r_req_bits_setIdx) vSRAMTemplate_145_cov_rw_same++;
    if (!vSRAMTemplate_145_io_w_req_valid && !vSRAMTemplate_145_io_r_req_valid && !vSRAMTemplate_145_boreChildrenBd_bore_ack) vSRAMTemplate_145_cov_cgoff++;
    if (vSRAMTemplate_145_boreChildrenBd_bore_ack && vSRAMTemplate_145_boreChildrenBd_bore_we) vSRAMTemplate_145_cov_bore_w++;
    if (vSRAMTemplate_145_boreChildrenBd_bore_ack && vSRAMTemplate_145_boreChildrenBd_bore_re) vSRAMTemplate_145_cov_bore_r++;
    if (vSRAMTemplate_145_io_broadcast_ram_hold) vSRAMTemplate_145_cov_hold++;
    if (vSRAMTemplate_145_io_w_req_valid) begin
      if (vSRAMTemplate_145_io_w_req_bits_waymask == 2'b0)      vSRAMTemplate_145_cov_m0++;
      else if (&vSRAMTemplate_145_io_w_req_bits_waymask)            vSRAMTemplate_145_cov_m1++;
      else                                  vSRAMTemplate_145_cov_mmix++;
    end
    if (!has_x({vSRAMTemplate_145_g_io_r_resp_data_0_hist_0, vSRAMTemplate_145_g_io_r_resp_data_0_hist_1, vSRAMTemplate_145_g_io_r_resp_data_0_hist_2, vSRAMTemplate_145_g_io_r_resp_data_0_hist_3, vSRAMTemplate_145_g_io_r_resp_data_0_hist_4, vSRAMTemplate_145_g_io_r_resp_data_0_hist_5, vSRAMTemplate_145_g_io_r_resp_data_0_hist_6, vSRAMTemplate_145_g_io_r_resp_data_0_hist_7, vSRAMTemplate_145_g_io_r_resp_data_0_hist_8, vSRAMTemplate_145_g_io_r_resp_data_0_hist_9, vSRAMTemplate_145_g_io_r_resp_data_0_hist_10, vSRAMTemplate_145_g_io_r_resp_data_0_hist_11, vSRAMTemplate_145_g_io_r_resp_data_0_hist_12, vSRAMTemplate_145_g_io_r_resp_data_0_hist_13, vSRAMTemplate_145_g_io_r_resp_data_0_hist_14, vSRAMTemplate_145_g_io_r_resp_data_0_hist_15, vSRAMTemplate_145_g_io_r_resp_data_0_hist_16, vSRAMTemplate_145_g_io_r_resp_data_0_hist_17, vSRAMTemplate_145_g_io_r_resp_data_0_hist_18, vSRAMTemplate_145_g_io_r_resp_data_0_hist_19, vSRAMTemplate_145_g_io_r_resp_data_0_hist_20, vSRAMTemplate_145_g_io_r_resp_data_0_hist_21, vSRAMTemplate_145_g_io_r_resp_data_0_hist_22, vSRAMTemplate_145_g_io_r_resp_data_0_hist_23, vSRAMTemplate_145_g_io_r_resp_data_0_hist_24, vSRAMTemplate_145_g_io_r_resp_data_0_hist_25, vSRAMTemplate_145_g_io_r_resp_data_0_hist_26, vSRAMTemplate_145_g_io_r_resp_data_0_hist_27, vSRAMTemplate_145_g_io_r_resp_data_0_hist_28, vSRAMTemplate_145_g_io_r_resp_data_0_hist_29, vSRAMTemplate_145_g_io_r_resp_data_0_tag, vSRAMTemplate_145_g_io_r_resp_data_1_hist_0, vSRAMTemplate_145_g_io_r_resp_data_1_hist_1, vSRAMTemplate_145_g_io_r_resp_data_1_hist_2, vSRAMTemplate_145_g_io_r_resp_data_1_hist_3, vSRAMTemplate_145_g_io_r_resp_data_1_hist_4, vSRAMTemplate_145_g_io_r_resp_data_1_hist_5, vSRAMTemplate_145_g_io_r_resp_data_1_hist_6, vSRAMTemplate_145_g_io_r_resp_data_1_hist_7, vSRAMTemplate_145_g_io_r_resp_data_1_hist_8, vSRAMTemplate_145_g_io_r_resp_data_1_hist_9, vSRAMTemplate_145_g_io_r_resp_data_1_hist_10, vSRAMTemplate_145_g_io_r_resp_data_1_hist_11, vSRAMTemplate_145_g_io_r_resp_data_1_hist_12, vSRAMTemplate_145_g_io_r_resp_data_1_hist_13, vSRAMTemplate_145_g_io_r_resp_data_1_hist_14, vSRAMTemplate_145_g_io_r_resp_data_1_hist_15, vSRAMTemplate_145_g_io_r_resp_data_1_hist_16, vSRAMTemplate_145_g_io_r_resp_data_1_hist_17, vSRAMTemplate_145_g_io_r_resp_data_1_hist_18, vSRAMTemplate_145_g_io_r_resp_data_1_hist_19, vSRAMTemplate_145_g_io_r_resp_data_1_hist_20, vSRAMTemplate_145_g_io_r_resp_data_1_hist_21, vSRAMTemplate_145_g_io_r_resp_data_1_hist_22, vSRAMTemplate_145_g_io_r_resp_data_1_hist_23, vSRAMTemplate_145_g_io_r_resp_data_1_hist_24, vSRAMTemplate_145_g_io_r_resp_data_1_hist_25, vSRAMTemplate_145_g_io_r_resp_data_1_hist_26, vSRAMTemplate_145_g_io_r_resp_data_1_hist_27, vSRAMTemplate_145_g_io_r_resp_data_1_hist_28, vSRAMTemplate_145_g_io_r_resp_data_1_hist_29, vSRAMTemplate_145_g_io_r_resp_data_1_tag}, 146) && !has_z({vSRAMTemplate_145_g_io_r_resp_data_0_hist_0, vSRAMTemplate_145_g_io_r_resp_data_0_hist_1, vSRAMTemplate_145_g_io_r_resp_data_0_hist_2, vSRAMTemplate_145_g_io_r_resp_data_0_hist_3, vSRAMTemplate_145_g_io_r_resp_data_0_hist_4, vSRAMTemplate_145_g_io_r_resp_data_0_hist_5, vSRAMTemplate_145_g_io_r_resp_data_0_hist_6, vSRAMTemplate_145_g_io_r_resp_data_0_hist_7, vSRAMTemplate_145_g_io_r_resp_data_0_hist_8, vSRAMTemplate_145_g_io_r_resp_data_0_hist_9, vSRAMTemplate_145_g_io_r_resp_data_0_hist_10, vSRAMTemplate_145_g_io_r_resp_data_0_hist_11, vSRAMTemplate_145_g_io_r_resp_data_0_hist_12, vSRAMTemplate_145_g_io_r_resp_data_0_hist_13, vSRAMTemplate_145_g_io_r_resp_data_0_hist_14, vSRAMTemplate_145_g_io_r_resp_data_0_hist_15, vSRAMTemplate_145_g_io_r_resp_data_0_hist_16, vSRAMTemplate_145_g_io_r_resp_data_0_hist_17, vSRAMTemplate_145_g_io_r_resp_data_0_hist_18, vSRAMTemplate_145_g_io_r_resp_data_0_hist_19, vSRAMTemplate_145_g_io_r_resp_data_0_hist_20, vSRAMTemplate_145_g_io_r_resp_data_0_hist_21, vSRAMTemplate_145_g_io_r_resp_data_0_hist_22, vSRAMTemplate_145_g_io_r_resp_data_0_hist_23, vSRAMTemplate_145_g_io_r_resp_data_0_hist_24, vSRAMTemplate_145_g_io_r_resp_data_0_hist_25, vSRAMTemplate_145_g_io_r_resp_data_0_hist_26, vSRAMTemplate_145_g_io_r_resp_data_0_hist_27, vSRAMTemplate_145_g_io_r_resp_data_0_hist_28, vSRAMTemplate_145_g_io_r_resp_data_0_hist_29, vSRAMTemplate_145_g_io_r_resp_data_0_tag, vSRAMTemplate_145_g_io_r_resp_data_1_hist_0, vSRAMTemplate_145_g_io_r_resp_data_1_hist_1, vSRAMTemplate_145_g_io_r_resp_data_1_hist_2, vSRAMTemplate_145_g_io_r_resp_data_1_hist_3, vSRAMTemplate_145_g_io_r_resp_data_1_hist_4, vSRAMTemplate_145_g_io_r_resp_data_1_hist_5, vSRAMTemplate_145_g_io_r_resp_data_1_hist_6, vSRAMTemplate_145_g_io_r_resp_data_1_hist_7, vSRAMTemplate_145_g_io_r_resp_data_1_hist_8, vSRAMTemplate_145_g_io_r_resp_data_1_hist_9, vSRAMTemplate_145_g_io_r_resp_data_1_hist_10, vSRAMTemplate_145_g_io_r_resp_data_1_hist_11, vSRAMTemplate_145_g_io_r_resp_data_1_hist_12, vSRAMTemplate_145_g_io_r_resp_data_1_hist_13, vSRAMTemplate_145_g_io_r_resp_data_1_hist_14, vSRAMTemplate_145_g_io_r_resp_data_1_hist_15, vSRAMTemplate_145_g_io_r_resp_data_1_hist_16, vSRAMTemplate_145_g_io_r_resp_data_1_hist_17, vSRAMTemplate_145_g_io_r_resp_data_1_hist_18, vSRAMTemplate_145_g_io_r_resp_data_1_hist_19, vSRAMTemplate_145_g_io_r_resp_data_1_hist_20, vSRAMTemplate_145_g_io_r_resp_data_1_hist_21, vSRAMTemplate_145_g_io_r_resp_data_1_hist_22, vSRAMTemplate_145_g_io_r_resp_data_1_hist_23, vSRAMTemplate_145_g_io_r_resp_data_1_hist_24, vSRAMTemplate_145_g_io_r_resp_data_1_hist_25, vSRAMTemplate_145_g_io_r_resp_data_1_hist_26, vSRAMTemplate_145_g_io_r_resp_data_1_hist_27, vSRAMTemplate_145_g_io_r_resp_data_1_hist_28, vSRAMTemplate_145_g_io_r_resp_data_1_hist_29, vSRAMTemplate_145_g_io_r_resp_data_1_tag}, 146)) begin
      vSRAMTemplate_145_cov_rd_known++;
      if (|{vSRAMTemplate_145_g_io_r_resp_data_0_hist_0, vSRAMTemplate_145_g_io_r_resp_data_0_hist_1, vSRAMTemplate_145_g_io_r_resp_data_0_hist_2, vSRAMTemplate_145_g_io_r_resp_data_0_hist_3, vSRAMTemplate_145_g_io_r_resp_data_0_hist_4, vSRAMTemplate_145_g_io_r_resp_data_0_hist_5, vSRAMTemplate_145_g_io_r_resp_data_0_hist_6, vSRAMTemplate_145_g_io_r_resp_data_0_hist_7, vSRAMTemplate_145_g_io_r_resp_data_0_hist_8, vSRAMTemplate_145_g_io_r_resp_data_0_hist_9, vSRAMTemplate_145_g_io_r_resp_data_0_hist_10, vSRAMTemplate_145_g_io_r_resp_data_0_hist_11, vSRAMTemplate_145_g_io_r_resp_data_0_hist_12, vSRAMTemplate_145_g_io_r_resp_data_0_hist_13, vSRAMTemplate_145_g_io_r_resp_data_0_hist_14, vSRAMTemplate_145_g_io_r_resp_data_0_hist_15, vSRAMTemplate_145_g_io_r_resp_data_0_hist_16, vSRAMTemplate_145_g_io_r_resp_data_0_hist_17, vSRAMTemplate_145_g_io_r_resp_data_0_hist_18, vSRAMTemplate_145_g_io_r_resp_data_0_hist_19, vSRAMTemplate_145_g_io_r_resp_data_0_hist_20, vSRAMTemplate_145_g_io_r_resp_data_0_hist_21, vSRAMTemplate_145_g_io_r_resp_data_0_hist_22, vSRAMTemplate_145_g_io_r_resp_data_0_hist_23, vSRAMTemplate_145_g_io_r_resp_data_0_hist_24, vSRAMTemplate_145_g_io_r_resp_data_0_hist_25, vSRAMTemplate_145_g_io_r_resp_data_0_hist_26, vSRAMTemplate_145_g_io_r_resp_data_0_hist_27, vSRAMTemplate_145_g_io_r_resp_data_0_hist_28, vSRAMTemplate_145_g_io_r_resp_data_0_hist_29, vSRAMTemplate_145_g_io_r_resp_data_0_tag, vSRAMTemplate_145_g_io_r_resp_data_1_hist_0, vSRAMTemplate_145_g_io_r_resp_data_1_hist_1, vSRAMTemplate_145_g_io_r_resp_data_1_hist_2, vSRAMTemplate_145_g_io_r_resp_data_1_hist_3, vSRAMTemplate_145_g_io_r_resp_data_1_hist_4, vSRAMTemplate_145_g_io_r_resp_data_1_hist_5, vSRAMTemplate_145_g_io_r_resp_data_1_hist_6, vSRAMTemplate_145_g_io_r_resp_data_1_hist_7, vSRAMTemplate_145_g_io_r_resp_data_1_hist_8, vSRAMTemplate_145_g_io_r_resp_data_1_hist_9, vSRAMTemplate_145_g_io_r_resp_data_1_hist_10, vSRAMTemplate_145_g_io_r_resp_data_1_hist_11, vSRAMTemplate_145_g_io_r_resp_data_1_hist_12, vSRAMTemplate_145_g_io_r_resp_data_1_hist_13, vSRAMTemplate_145_g_io_r_resp_data_1_hist_14, vSRAMTemplate_145_g_io_r_resp_data_1_hist_15, vSRAMTemplate_145_g_io_r_resp_data_1_hist_16, vSRAMTemplate_145_g_io_r_resp_data_1_hist_17, vSRAMTemplate_145_g_io_r_resp_data_1_hist_18, vSRAMTemplate_145_g_io_r_resp_data_1_hist_19, vSRAMTemplate_145_g_io_r_resp_data_1_hist_20, vSRAMTemplate_145_g_io_r_resp_data_1_hist_21, vSRAMTemplate_145_g_io_r_resp_data_1_hist_22, vSRAMTemplate_145_g_io_r_resp_data_1_hist_23, vSRAMTemplate_145_g_io_r_resp_data_1_hist_24, vSRAMTemplate_145_g_io_r_resp_data_1_hist_25, vSRAMTemplate_145_g_io_r_resp_data_1_hist_26, vSRAMTemplate_145_g_io_r_resp_data_1_hist_27, vSRAMTemplate_145_g_io_r_resp_data_1_hist_28, vSRAMTemplate_145_g_io_r_resp_data_1_hist_29, vSRAMTemplate_145_g_io_r_resp_data_1_tag}) vSRAMTemplate_145_cov_rd_nonzero++;
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_0 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_0) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_0 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_0, vSRAMTemplate_145_i_io_r_resp_data_0_hist_0); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_0, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_0, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_0 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_0, vSRAMTemplate_145_i_io_r_resp_data_0_hist_0); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_1 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_1) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_1 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_1, vSRAMTemplate_145_i_io_r_resp_data_0_hist_1); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_1, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_1, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_1 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_1, vSRAMTemplate_145_i_io_r_resp_data_0_hist_1); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_2 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_2) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_2 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_2, vSRAMTemplate_145_i_io_r_resp_data_0_hist_2); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_2, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_2, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_2 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_2, vSRAMTemplate_145_i_io_r_resp_data_0_hist_2); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_3 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_3) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_3 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_3, vSRAMTemplate_145_i_io_r_resp_data_0_hist_3); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_3, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_3, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_3 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_3, vSRAMTemplate_145_i_io_r_resp_data_0_hist_3); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_4 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_4) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_4 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_4, vSRAMTemplate_145_i_io_r_resp_data_0_hist_4); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_4, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_4, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_4 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_4, vSRAMTemplate_145_i_io_r_resp_data_0_hist_4); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_5 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_5) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_5 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_5, vSRAMTemplate_145_i_io_r_resp_data_0_hist_5); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_5, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_5, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_5 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_5, vSRAMTemplate_145_i_io_r_resp_data_0_hist_5); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_6 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_6) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_6 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_6, vSRAMTemplate_145_i_io_r_resp_data_0_hist_6); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_6, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_6, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_6 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_6, vSRAMTemplate_145_i_io_r_resp_data_0_hist_6); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_7 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_7) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_7 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_7, vSRAMTemplate_145_i_io_r_resp_data_0_hist_7); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_7, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_7, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_7 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_7, vSRAMTemplate_145_i_io_r_resp_data_0_hist_7); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_8 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_8) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_8 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_8, vSRAMTemplate_145_i_io_r_resp_data_0_hist_8); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_8, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_8, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_8 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_8, vSRAMTemplate_145_i_io_r_resp_data_0_hist_8); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_9 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_9) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_9 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_9, vSRAMTemplate_145_i_io_r_resp_data_0_hist_9); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_9, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_9, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_9 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_9, vSRAMTemplate_145_i_io_r_resp_data_0_hist_9); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_10 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_10) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_10 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_10, vSRAMTemplate_145_i_io_r_resp_data_0_hist_10); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_10, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_10, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_10 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_10, vSRAMTemplate_145_i_io_r_resp_data_0_hist_10); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_11 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_11) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_11 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_11, vSRAMTemplate_145_i_io_r_resp_data_0_hist_11); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_11, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_11, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_11 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_11, vSRAMTemplate_145_i_io_r_resp_data_0_hist_11); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_12 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_12) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_12 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_12, vSRAMTemplate_145_i_io_r_resp_data_0_hist_12); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_12, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_12, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_12 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_12, vSRAMTemplate_145_i_io_r_resp_data_0_hist_12); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_13 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_13) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_13 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_13, vSRAMTemplate_145_i_io_r_resp_data_0_hist_13); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_13, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_13, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_13 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_13, vSRAMTemplate_145_i_io_r_resp_data_0_hist_13); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_14 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_14) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_14 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_14, vSRAMTemplate_145_i_io_r_resp_data_0_hist_14); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_14, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_14, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_14 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_14, vSRAMTemplate_145_i_io_r_resp_data_0_hist_14); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_15 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_15) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_15 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_15, vSRAMTemplate_145_i_io_r_resp_data_0_hist_15); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_15, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_15, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_15 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_15, vSRAMTemplate_145_i_io_r_resp_data_0_hist_15); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_16 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_16) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_16 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_16, vSRAMTemplate_145_i_io_r_resp_data_0_hist_16); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_16, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_16, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_16 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_16, vSRAMTemplate_145_i_io_r_resp_data_0_hist_16); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_17 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_17) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_17 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_17, vSRAMTemplate_145_i_io_r_resp_data_0_hist_17); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_17, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_17, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_17 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_17, vSRAMTemplate_145_i_io_r_resp_data_0_hist_17); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_18 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_18) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_18 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_18, vSRAMTemplate_145_i_io_r_resp_data_0_hist_18); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_18, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_18, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_18 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_18, vSRAMTemplate_145_i_io_r_resp_data_0_hist_18); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_19 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_19) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_19 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_19, vSRAMTemplate_145_i_io_r_resp_data_0_hist_19); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_19, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_19, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_19 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_19, vSRAMTemplate_145_i_io_r_resp_data_0_hist_19); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_20 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_20) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_20 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_20, vSRAMTemplate_145_i_io_r_resp_data_0_hist_20); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_20, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_20, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_20 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_20, vSRAMTemplate_145_i_io_r_resp_data_0_hist_20); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_21 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_21) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_21 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_21, vSRAMTemplate_145_i_io_r_resp_data_0_hist_21); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_21, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_21, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_21 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_21, vSRAMTemplate_145_i_io_r_resp_data_0_hist_21); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_22 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_22) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_22 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_22, vSRAMTemplate_145_i_io_r_resp_data_0_hist_22); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_22, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_22, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_22 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_22, vSRAMTemplate_145_i_io_r_resp_data_0_hist_22); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_23 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_23) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_23 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_23, vSRAMTemplate_145_i_io_r_resp_data_0_hist_23); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_23, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_23, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_23 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_23, vSRAMTemplate_145_i_io_r_resp_data_0_hist_23); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_24 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_24) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_24 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_24, vSRAMTemplate_145_i_io_r_resp_data_0_hist_24); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_24, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_24, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_24 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_24, vSRAMTemplate_145_i_io_r_resp_data_0_hist_24); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_25 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_25) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_25 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_25, vSRAMTemplate_145_i_io_r_resp_data_0_hist_25); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_25, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_25, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_25 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_25, vSRAMTemplate_145_i_io_r_resp_data_0_hist_25); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_26 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_26) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_26 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_26, vSRAMTemplate_145_i_io_r_resp_data_0_hist_26); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_26, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_26, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_26 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_26, vSRAMTemplate_145_i_io_r_resp_data_0_hist_26); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_27 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_27) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_27 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_27, vSRAMTemplate_145_i_io_r_resp_data_0_hist_27); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_27, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_27, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_27 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_27, vSRAMTemplate_145_i_io_r_resp_data_0_hist_27); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_28 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_28) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_28 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_28, vSRAMTemplate_145_i_io_r_resp_data_0_hist_28); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_28, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_28, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_28 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_28, vSRAMTemplate_145_i_io_r_resp_data_0_hist_28); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_hist_29 !== vSRAMTemplate_145_i_io_r_resp_data_0_hist_29) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_hist_29 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_29, vSRAMTemplate_145_i_io_r_resp_data_0_hist_29); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_hist_29, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_hist_29, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_hist_29 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_hist_29, vSRAMTemplate_145_i_io_r_resp_data_0_hist_29); end
    if (vSRAMTemplate_145_g_io_r_resp_data_0_tag !== vSRAMTemplate_145_i_io_r_resp_data_0_tag) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_0_tag g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_tag, vSRAMTemplate_145_i_io_r_resp_data_0_tag); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_0_tag, 13) || has_z(vSRAMTemplate_145_i_io_r_resp_data_0_tag, 13)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_0_tag g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_0_tag, vSRAMTemplate_145_i_io_r_resp_data_0_tag); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_0 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_0) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_0 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_0, vSRAMTemplate_145_i_io_r_resp_data_1_hist_0); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_0, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_0, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_0 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_0, vSRAMTemplate_145_i_io_r_resp_data_1_hist_0); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_1 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_1) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_1 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_1, vSRAMTemplate_145_i_io_r_resp_data_1_hist_1); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_1, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_1, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_1 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_1, vSRAMTemplate_145_i_io_r_resp_data_1_hist_1); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_2 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_2) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_2 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_2, vSRAMTemplate_145_i_io_r_resp_data_1_hist_2); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_2, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_2, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_2 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_2, vSRAMTemplate_145_i_io_r_resp_data_1_hist_2); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_3 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_3) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_3 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_3, vSRAMTemplate_145_i_io_r_resp_data_1_hist_3); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_3, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_3, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_3 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_3, vSRAMTemplate_145_i_io_r_resp_data_1_hist_3); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_4 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_4) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_4 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_4, vSRAMTemplate_145_i_io_r_resp_data_1_hist_4); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_4, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_4, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_4 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_4, vSRAMTemplate_145_i_io_r_resp_data_1_hist_4); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_5 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_5) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_5 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_5, vSRAMTemplate_145_i_io_r_resp_data_1_hist_5); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_5, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_5, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_5 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_5, vSRAMTemplate_145_i_io_r_resp_data_1_hist_5); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_6 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_6) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_6 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_6, vSRAMTemplate_145_i_io_r_resp_data_1_hist_6); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_6, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_6, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_6 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_6, vSRAMTemplate_145_i_io_r_resp_data_1_hist_6); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_7 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_7) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_7 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_7, vSRAMTemplate_145_i_io_r_resp_data_1_hist_7); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_7, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_7, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_7 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_7, vSRAMTemplate_145_i_io_r_resp_data_1_hist_7); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_8 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_8) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_8 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_8, vSRAMTemplate_145_i_io_r_resp_data_1_hist_8); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_8, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_8, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_8 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_8, vSRAMTemplate_145_i_io_r_resp_data_1_hist_8); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_9 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_9) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_9 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_9, vSRAMTemplate_145_i_io_r_resp_data_1_hist_9); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_9, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_9, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_9 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_9, vSRAMTemplate_145_i_io_r_resp_data_1_hist_9); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_10 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_10) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_10 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_10, vSRAMTemplate_145_i_io_r_resp_data_1_hist_10); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_10, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_10, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_10 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_10, vSRAMTemplate_145_i_io_r_resp_data_1_hist_10); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_11 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_11) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_11 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_11, vSRAMTemplate_145_i_io_r_resp_data_1_hist_11); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_11, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_11, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_11 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_11, vSRAMTemplate_145_i_io_r_resp_data_1_hist_11); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_12 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_12) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_12 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_12, vSRAMTemplate_145_i_io_r_resp_data_1_hist_12); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_12, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_12, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_12 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_12, vSRAMTemplate_145_i_io_r_resp_data_1_hist_12); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_13 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_13) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_13 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_13, vSRAMTemplate_145_i_io_r_resp_data_1_hist_13); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_13, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_13, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_13 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_13, vSRAMTemplate_145_i_io_r_resp_data_1_hist_13); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_14 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_14) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_14 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_14, vSRAMTemplate_145_i_io_r_resp_data_1_hist_14); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_14, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_14, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_14 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_14, vSRAMTemplate_145_i_io_r_resp_data_1_hist_14); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_15 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_15) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_15 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_15, vSRAMTemplate_145_i_io_r_resp_data_1_hist_15); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_15, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_15, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_15 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_15, vSRAMTemplate_145_i_io_r_resp_data_1_hist_15); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_16 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_16) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_16 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_16, vSRAMTemplate_145_i_io_r_resp_data_1_hist_16); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_16, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_16, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_16 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_16, vSRAMTemplate_145_i_io_r_resp_data_1_hist_16); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_17 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_17) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_17 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_17, vSRAMTemplate_145_i_io_r_resp_data_1_hist_17); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_17, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_17, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_17 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_17, vSRAMTemplate_145_i_io_r_resp_data_1_hist_17); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_18 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_18) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_18 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_18, vSRAMTemplate_145_i_io_r_resp_data_1_hist_18); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_18, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_18, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_18 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_18, vSRAMTemplate_145_i_io_r_resp_data_1_hist_18); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_19 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_19) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_19 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_19, vSRAMTemplate_145_i_io_r_resp_data_1_hist_19); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_19, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_19, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_19 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_19, vSRAMTemplate_145_i_io_r_resp_data_1_hist_19); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_20 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_20) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_20 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_20, vSRAMTemplate_145_i_io_r_resp_data_1_hist_20); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_20, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_20, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_20 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_20, vSRAMTemplate_145_i_io_r_resp_data_1_hist_20); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_21 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_21) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_21 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_21, vSRAMTemplate_145_i_io_r_resp_data_1_hist_21); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_21, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_21, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_21 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_21, vSRAMTemplate_145_i_io_r_resp_data_1_hist_21); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_22 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_22) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_22 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_22, vSRAMTemplate_145_i_io_r_resp_data_1_hist_22); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_22, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_22, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_22 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_22, vSRAMTemplate_145_i_io_r_resp_data_1_hist_22); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_23 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_23) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_23 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_23, vSRAMTemplate_145_i_io_r_resp_data_1_hist_23); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_23, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_23, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_23 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_23, vSRAMTemplate_145_i_io_r_resp_data_1_hist_23); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_24 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_24) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_24 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_24, vSRAMTemplate_145_i_io_r_resp_data_1_hist_24); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_24, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_24, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_24 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_24, vSRAMTemplate_145_i_io_r_resp_data_1_hist_24); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_25 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_25) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_25 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_25, vSRAMTemplate_145_i_io_r_resp_data_1_hist_25); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_25, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_25, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_25 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_25, vSRAMTemplate_145_i_io_r_resp_data_1_hist_25); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_26 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_26) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_26 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_26, vSRAMTemplate_145_i_io_r_resp_data_1_hist_26); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_26, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_26, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_26 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_26, vSRAMTemplate_145_i_io_r_resp_data_1_hist_26); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_27 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_27) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_27 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_27, vSRAMTemplate_145_i_io_r_resp_data_1_hist_27); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_27, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_27, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_27 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_27, vSRAMTemplate_145_i_io_r_resp_data_1_hist_27); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_28 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_28) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_28 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_28, vSRAMTemplate_145_i_io_r_resp_data_1_hist_28); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_28, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_28, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_28 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_28, vSRAMTemplate_145_i_io_r_resp_data_1_hist_28); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_hist_29 !== vSRAMTemplate_145_i_io_r_resp_data_1_hist_29) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_hist_29 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_29, vSRAMTemplate_145_i_io_r_resp_data_1_hist_29); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_hist_29, 2) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_hist_29, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_hist_29 g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_hist_29, vSRAMTemplate_145_i_io_r_resp_data_1_hist_29); end
    if (vSRAMTemplate_145_g_io_r_resp_data_1_tag !== vSRAMTemplate_145_i_io_r_resp_data_1_tag) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.io_r_resp_data_1_tag g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_tag, vSRAMTemplate_145_i_io_r_resp_data_1_tag); end
    if (has_z(vSRAMTemplate_145_g_io_r_resp_data_1_tag, 13) || has_z(vSRAMTemplate_145_i_io_r_resp_data_1_tag, 13)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.io_r_resp_data_1_tag g=%h i=%h", $time, vSRAMTemplate_145_g_io_r_resp_data_1_tag, vSRAMTemplate_145_i_io_r_resp_data_1_tag); end
    if (vSRAMTemplate_145_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_145_i_boreChildrenBd_bore_rdata) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_145.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_145_g_boreChildrenBd_bore_rdata, vSRAMTemplate_145_i_boreChildrenBd_bore_rdata); end
    if (has_z(vSRAMTemplate_145_g_boreChildrenBd_bore_rdata, 148) || has_z(vSRAMTemplate_145_i_boreChildrenBd_bore_rdata, 148)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_145.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_145_g_boreChildrenBd_bore_rdata, vSRAMTemplate_145_i_boreChildrenBd_bore_rdata); end
  end

  // ================= SRAMTemplate_146 =================
  logic vSRAMTemplate_146_io_r_req_valid;
  logic [7:0] vSRAMTemplate_146_io_r_req_bits_setIdx;
  logic vSRAMTemplate_146_io_w_req_valid;
  logic [7:0] vSRAMTemplate_146_io_w_req_bits_setIdx;
  logic [11:0] vSRAMTemplate_146_io_w_req_bits_data_0_tag;
  logic vSRAMTemplate_146_io_broadcast_ram_hold;
  logic vSRAMTemplate_146_io_broadcast_ram_bypass;
  logic vSRAMTemplate_146_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_146_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_146_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_146_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_146_io_broadcast_ram_ctl;
  logic vSRAMTemplate_146_io_broadcast_cgen;
  logic [8:0] vSRAMTemplate_146_boreChildrenBd_bore_addr;
  logic [8:0] vSRAMTemplate_146_boreChildrenBd_bore_addr_rd;
  logic [12:0] vSRAMTemplate_146_boreChildrenBd_bore_wdata;
  logic vSRAMTemplate_146_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_146_boreChildrenBd_bore_re;
  logic vSRAMTemplate_146_boreChildrenBd_bore_we;
  logic vSRAMTemplate_146_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_146_boreChildrenBd_bore_selectedOH;
  logic vSRAMTemplate_146_boreChildrenBd_bore_array;
  wire vSRAMTemplate_146_g_io_r_req_ready;
  wire vSRAMTemplate_146_i_io_r_req_ready;
  wire vSRAMTemplate_146_g_io_r_resp_data_0_valid;
  wire vSRAMTemplate_146_i_io_r_resp_data_0_valid;
  wire [11:0] vSRAMTemplate_146_g_io_r_resp_data_0_tag;
  wire [11:0] vSRAMTemplate_146_i_io_r_resp_data_0_tag;
  wire vSRAMTemplate_146_g_io_w_req_ready;
  wire vSRAMTemplate_146_i_io_w_req_ready;
  wire [12:0] vSRAMTemplate_146_g_boreChildrenBd_bore_rdata;
  wire [12:0] vSRAMTemplate_146_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_146    u_g_SRAMTemplate_146 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_146_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_146_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_146_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_146_io_w_req_bits_setIdx), .io_w_req_bits_data_0_tag(vSRAMTemplate_146_io_w_req_bits_data_0_tag), .io_broadcast_ram_hold(vSRAMTemplate_146_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_146_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_146_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_146_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_146_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_146_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_146_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_146_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_146_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_146_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_146_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_146_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_146_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_146_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_146_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_146_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_146_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_146_g_io_r_req_ready), .io_r_resp_data_0_valid(vSRAMTemplate_146_g_io_r_resp_data_0_valid), .io_r_resp_data_0_tag(vSRAMTemplate_146_g_io_r_resp_data_0_tag), .io_w_req_ready(vSRAMTemplate_146_g_io_w_req_ready), .boreChildrenBd_bore_rdata(vSRAMTemplate_146_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_146_xs u_i_SRAMTemplate_146 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_146_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_146_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_146_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_146_io_w_req_bits_setIdx), .io_w_req_bits_data_0_tag(vSRAMTemplate_146_io_w_req_bits_data_0_tag), .io_broadcast_ram_hold(vSRAMTemplate_146_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_146_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_146_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_146_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_146_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_146_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_146_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_146_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_146_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_146_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_146_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_146_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_146_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_146_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_146_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_146_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_146_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_146_i_io_r_req_ready), .io_r_resp_data_0_valid(vSRAMTemplate_146_i_io_r_resp_data_0_valid), .io_r_resp_data_0_tag(vSRAMTemplate_146_i_io_r_resp_data_0_tag), .io_w_req_ready(vSRAMTemplate_146_i_io_w_req_ready), .boreChildrenBd_bore_rdata(vSRAMTemplate_146_i_boreChildrenBd_bore_rdata));
  int vSRAMTemplate_146_cov_w = 0, vSRAMTemplate_146_cov_rw_same = 0, vSRAMTemplate_146_cov_cgoff = 0, vSRAMTemplate_146_cov_bore_w = 0, vSRAMTemplate_146_cov_bore_r = 0, vSRAMTemplate_146_cov_hold = 0, vSRAMTemplate_146_cov_rd_known = 0, vSRAMTemplate_146_cov_rd_nonzero = 0;
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_146_io_r_req_valid <= 1'b0;
      vSRAMTemplate_146_io_w_req_valid <= 1'b0;
      vSRAMTemplate_146_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_146_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_146_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_146_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_146_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_146_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_146_io_r_req_bits_setIdx <= ($urandom_range(0,3)!=0) ? 8'($urandom_range(0,7)) : 8'($urandom);
      vSRAMTemplate_146_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_146_io_w_req_bits_setIdx <= ($urandom_range(0,3)!=0) ? 8'($urandom_range(0,7)) : 8'($urandom);
      vSRAMTemplate_146_io_w_req_bits_data_0_tag <= 12'($urandom);
      vSRAMTemplate_146_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_146_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_146_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_146_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_146_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_146_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_146_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_146_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_146_boreChildrenBd_bore_addr <= 9'($urandom);
      vSRAMTemplate_146_boreChildrenBd_bore_addr_rd <= 9'($urandom);
      vSRAMTemplate_146_boreChildrenBd_bore_wdata <= 13'($urandom);
      vSRAMTemplate_146_boreChildrenBd_bore_wmask <= 1'($urandom);
      vSRAMTemplate_146_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_146_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_146_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_146_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_146_boreChildrenBd_bore_array <= 1'($urandom);
    end
  end
  always @(posedge clk) if (!rst && cycle > WARMUP) begin
    if (vSRAMTemplate_146_io_w_req_valid && !vSRAMTemplate_146_io_broadcast_ram_hold) vSRAMTemplate_146_cov_w++;
    if (vSRAMTemplate_146_io_w_req_valid && vSRAMTemplate_146_io_r_req_valid && vSRAMTemplate_146_io_w_req_bits_setIdx == vSRAMTemplate_146_io_r_req_bits_setIdx) vSRAMTemplate_146_cov_rw_same++;
    if (!vSRAMTemplate_146_io_w_req_valid && !vSRAMTemplate_146_io_r_req_valid && !vSRAMTemplate_146_boreChildrenBd_bore_ack) vSRAMTemplate_146_cov_cgoff++;
    if (vSRAMTemplate_146_boreChildrenBd_bore_ack && vSRAMTemplate_146_boreChildrenBd_bore_we) vSRAMTemplate_146_cov_bore_w++;
    if (vSRAMTemplate_146_boreChildrenBd_bore_ack && vSRAMTemplate_146_boreChildrenBd_bore_re) vSRAMTemplate_146_cov_bore_r++;
    if (vSRAMTemplate_146_io_broadcast_ram_hold) vSRAMTemplate_146_cov_hold++;
    if (!has_x({vSRAMTemplate_146_g_io_r_resp_data_0_valid, vSRAMTemplate_146_g_io_r_resp_data_0_tag}, 13) && !has_z({vSRAMTemplate_146_g_io_r_resp_data_0_valid, vSRAMTemplate_146_g_io_r_resp_data_0_tag}, 13)) begin
      vSRAMTemplate_146_cov_rd_known++;
      if (|{vSRAMTemplate_146_g_io_r_resp_data_0_valid, vSRAMTemplate_146_g_io_r_resp_data_0_tag}) vSRAMTemplate_146_cov_rd_nonzero++;
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_146_g_io_r_req_ready !== vSRAMTemplate_146_i_io_r_req_ready) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_146.io_r_req_ready g=%h i=%h", $time, vSRAMTemplate_146_g_io_r_req_ready, vSRAMTemplate_146_i_io_r_req_ready); end
    if (has_z(vSRAMTemplate_146_g_io_r_req_ready, 1) || has_z(vSRAMTemplate_146_i_io_r_req_ready, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_146.io_r_req_ready g=%h i=%h", $time, vSRAMTemplate_146_g_io_r_req_ready, vSRAMTemplate_146_i_io_r_req_ready); end
    if (vSRAMTemplate_146_g_io_r_resp_data_0_valid !== vSRAMTemplate_146_i_io_r_resp_data_0_valid) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_146.io_r_resp_data_0_valid g=%h i=%h", $time, vSRAMTemplate_146_g_io_r_resp_data_0_valid, vSRAMTemplate_146_i_io_r_resp_data_0_valid); end
    if (has_z(vSRAMTemplate_146_g_io_r_resp_data_0_valid, 1) || has_z(vSRAMTemplate_146_i_io_r_resp_data_0_valid, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_146.io_r_resp_data_0_valid g=%h i=%h", $time, vSRAMTemplate_146_g_io_r_resp_data_0_valid, vSRAMTemplate_146_i_io_r_resp_data_0_valid); end
    if (vSRAMTemplate_146_g_io_r_resp_data_0_tag !== vSRAMTemplate_146_i_io_r_resp_data_0_tag) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_146.io_r_resp_data_0_tag g=%h i=%h", $time, vSRAMTemplate_146_g_io_r_resp_data_0_tag, vSRAMTemplate_146_i_io_r_resp_data_0_tag); end
    if (has_z(vSRAMTemplate_146_g_io_r_resp_data_0_tag, 12) || has_z(vSRAMTemplate_146_i_io_r_resp_data_0_tag, 12)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_146.io_r_resp_data_0_tag g=%h i=%h", $time, vSRAMTemplate_146_g_io_r_resp_data_0_tag, vSRAMTemplate_146_i_io_r_resp_data_0_tag); end
    if (vSRAMTemplate_146_g_io_w_req_ready !== vSRAMTemplate_146_i_io_w_req_ready) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_146.io_w_req_ready g=%h i=%h", $time, vSRAMTemplate_146_g_io_w_req_ready, vSRAMTemplate_146_i_io_w_req_ready); end
    if (has_z(vSRAMTemplate_146_g_io_w_req_ready, 1) || has_z(vSRAMTemplate_146_i_io_w_req_ready, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_146.io_w_req_ready g=%h i=%h", $time, vSRAMTemplate_146_g_io_w_req_ready, vSRAMTemplate_146_i_io_w_req_ready); end
    if (vSRAMTemplate_146_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_146_i_boreChildrenBd_bore_rdata) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_146.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_146_g_boreChildrenBd_bore_rdata, vSRAMTemplate_146_i_boreChildrenBd_bore_rdata); end
    if (has_z(vSRAMTemplate_146_g_boreChildrenBd_bore_rdata, 13) || has_z(vSRAMTemplate_146_i_boreChildrenBd_bore_rdata, 13)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_146.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_146_g_boreChildrenBd_bore_rdata, vSRAMTemplate_146_i_boreChildrenBd_bore_rdata); end
  end

  // ================= SRAMTemplate_155 =================
  logic vSRAMTemplate_155_io_r_req_valid;
  logic [11:0] vSRAMTemplate_155_io_r_req_bits_setIdx;
  logic vSRAMTemplate_155_io_w_req_valid;
  logic [11:0] vSRAMTemplate_155_io_w_req_bits_setIdx;
  logic [136:0] vSRAMTemplate_155_io_w_req_bits_data_0;
  logic vSRAMTemplate_155_io_broadcast_ram_hold;
  logic vSRAMTemplate_155_io_broadcast_ram_bypass;
  logic vSRAMTemplate_155_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_155_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_155_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_155_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_155_io_broadcast_ram_ctl;
  logic vSRAMTemplate_155_io_broadcast_cgen;
  logic [12:0] vSRAMTemplate_155_boreChildrenBd_bore_addr;
  logic [12:0] vSRAMTemplate_155_boreChildrenBd_bore_addr_rd;
  logic [136:0] vSRAMTemplate_155_boreChildrenBd_bore_wdata;
  logic vSRAMTemplate_155_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_155_boreChildrenBd_bore_re;
  logic vSRAMTemplate_155_boreChildrenBd_bore_we;
  logic vSRAMTemplate_155_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_155_boreChildrenBd_bore_selectedOH;
  logic [3:0] vSRAMTemplate_155_boreChildrenBd_bore_array;
  wire [136:0] vSRAMTemplate_155_g_io_r_resp_data_0;
  wire [136:0] vSRAMTemplate_155_i_io_r_resp_data_0;
  wire vSRAMTemplate_155_g_io_mbistCgCtl_en;
  wire vSRAMTemplate_155_i_io_mbistCgCtl_en;
  wire vSRAMTemplate_155_g_io_mbistCgCtl_rckEn;
  wire vSRAMTemplate_155_i_io_mbistCgCtl_rckEn;
  wire vSRAMTemplate_155_g_io_mbistCgCtl_wckEn;
  wire vSRAMTemplate_155_i_io_mbistCgCtl_wckEn;
  wire [136:0] vSRAMTemplate_155_g_boreChildrenBd_bore_rdata;
  wire [136:0] vSRAMTemplate_155_i_boreChildrenBd_bore_rdata;
  logic vSRAMTemplate_155_g_lat, vSRAMTemplate_155_i_lat;
  wire  vSRAMTemplate_155_g_rclk = clk & vSRAMTemplate_155_g_lat;
  wire  vSRAMTemplate_155_i_rclk = clk & vSRAMTemplate_155_i_lat;
  always @(*) if (!clk) begin
    vSRAMTemplate_155_g_lat = vSRAMTemplate_155_g_io_mbistCgCtl_rckEn | vSRAMTemplate_155_g_io_mbistCgCtl_wckEn;
    vSRAMTemplate_155_i_lat = vSRAMTemplate_155_i_io_mbistCgCtl_rckEn | vSRAMTemplate_155_i_io_mbistCgCtl_wckEn;
  end
  SRAMTemplate_155    u_g_SRAMTemplate_155 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_155_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_155_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_155_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_155_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_155_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_155_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_155_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_155_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_155_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_155_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_155_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_155_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_155_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_155_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_155_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_155_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_155_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_155_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_155_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_155_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_155_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_155_boreChildrenBd_bore_array), .io_mbistCgCtl_rclk(vSRAMTemplate_155_g_rclk), .io_r_resp_data_0(vSRAMTemplate_155_g_io_r_resp_data_0), .io_mbistCgCtl_en(vSRAMTemplate_155_g_io_mbistCgCtl_en), .io_mbistCgCtl_rckEn(vSRAMTemplate_155_g_io_mbistCgCtl_rckEn), .io_mbistCgCtl_wckEn(vSRAMTemplate_155_g_io_mbistCgCtl_wckEn), .boreChildrenBd_bore_rdata(vSRAMTemplate_155_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_155_xs u_i_SRAMTemplate_155 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_155_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_155_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_155_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_155_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_155_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_155_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_155_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_155_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_155_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_155_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_155_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_155_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_155_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_155_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_155_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_155_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_155_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_155_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_155_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_155_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_155_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_155_boreChildrenBd_bore_array), .io_mbistCgCtl_rclk(vSRAMTemplate_155_i_rclk), .io_r_resp_data_0(vSRAMTemplate_155_i_io_r_resp_data_0), .io_mbistCgCtl_en(vSRAMTemplate_155_i_io_mbistCgCtl_en), .io_mbistCgCtl_rckEn(vSRAMTemplate_155_i_io_mbistCgCtl_rckEn), .io_mbistCgCtl_wckEn(vSRAMTemplate_155_i_io_mbistCgCtl_wckEn), .boreChildrenBd_bore_rdata(vSRAMTemplate_155_i_boreChildrenBd_bore_rdata));
  int vSRAMTemplate_155_cov_w = 0, vSRAMTemplate_155_cov_rw_same = 0, vSRAMTemplate_155_cov_cgoff = 0, vSRAMTemplate_155_cov_bore_w = 0, vSRAMTemplate_155_cov_bore_r = 0, vSRAMTemplate_155_cov_hold = 0, vSRAMTemplate_155_cov_rd_known = 0, vSRAMTemplate_155_cov_rd_nonzero = 0;
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_155_io_r_req_valid <= 1'b0;
      vSRAMTemplate_155_io_w_req_valid <= 1'b0;
      vSRAMTemplate_155_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_155_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_155_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_155_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_155_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_155_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_155_io_r_req_bits_setIdx <= ($urandom_range(0,3)!=0) ? 12'($urandom_range(0,7)) : 12'($urandom);
      vSRAMTemplate_155_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_155_io_w_req_bits_setIdx <= ($urandom_range(0,3)!=0) ? 12'($urandom_range(0,7)) : 12'($urandom);
      vSRAMTemplate_155_io_w_req_bits_data_0 <= 137'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      vSRAMTemplate_155_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_155_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_155_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_155_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_155_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_155_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_155_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_155_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_155_boreChildrenBd_bore_addr <= 13'($urandom);
      vSRAMTemplate_155_boreChildrenBd_bore_addr_rd <= 13'($urandom);
      vSRAMTemplate_155_boreChildrenBd_bore_wdata <= 137'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      vSRAMTemplate_155_boreChildrenBd_bore_wmask <= 1'($urandom);
      vSRAMTemplate_155_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_155_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_155_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_155_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_155_boreChildrenBd_bore_array <= 4'($urandom);
    end
  end
  always @(posedge clk) if (!rst && cycle > WARMUP) begin
    if (vSRAMTemplate_155_io_w_req_valid && !vSRAMTemplate_155_io_broadcast_ram_hold) vSRAMTemplate_155_cov_w++;
    if (vSRAMTemplate_155_io_w_req_valid && vSRAMTemplate_155_io_r_req_valid && vSRAMTemplate_155_io_w_req_bits_setIdx == vSRAMTemplate_155_io_r_req_bits_setIdx) vSRAMTemplate_155_cov_rw_same++;
    if (!vSRAMTemplate_155_io_w_req_valid && !vSRAMTemplate_155_io_r_req_valid && !vSRAMTemplate_155_boreChildrenBd_bore_ack) vSRAMTemplate_155_cov_cgoff++;
    if (vSRAMTemplate_155_boreChildrenBd_bore_ack && vSRAMTemplate_155_boreChildrenBd_bore_we) vSRAMTemplate_155_cov_bore_w++;
    if (vSRAMTemplate_155_boreChildrenBd_bore_ack && vSRAMTemplate_155_boreChildrenBd_bore_re) vSRAMTemplate_155_cov_bore_r++;
    if (vSRAMTemplate_155_io_broadcast_ram_hold) vSRAMTemplate_155_cov_hold++;
    if (!has_x({vSRAMTemplate_155_g_io_r_resp_data_0}, 137) && !has_z({vSRAMTemplate_155_g_io_r_resp_data_0}, 137)) begin
      vSRAMTemplate_155_cov_rd_known++;
      if (|{vSRAMTemplate_155_g_io_r_resp_data_0}) vSRAMTemplate_155_cov_rd_nonzero++;
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_155_g_io_r_resp_data_0 !== vSRAMTemplate_155_i_io_r_resp_data_0) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_155.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_155_g_io_r_resp_data_0, vSRAMTemplate_155_i_io_r_resp_data_0); end
    if (has_z(vSRAMTemplate_155_g_io_r_resp_data_0, 137) || has_z(vSRAMTemplate_155_i_io_r_resp_data_0, 137)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_155.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_155_g_io_r_resp_data_0, vSRAMTemplate_155_i_io_r_resp_data_0); end
    if (vSRAMTemplate_155_g_io_mbistCgCtl_en !== vSRAMTemplate_155_i_io_mbistCgCtl_en) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_155.io_mbistCgCtl_en g=%h i=%h", $time, vSRAMTemplate_155_g_io_mbistCgCtl_en, vSRAMTemplate_155_i_io_mbistCgCtl_en); end
    if (has_z(vSRAMTemplate_155_g_io_mbistCgCtl_en, 1) || has_z(vSRAMTemplate_155_i_io_mbistCgCtl_en, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_155.io_mbistCgCtl_en g=%h i=%h", $time, vSRAMTemplate_155_g_io_mbistCgCtl_en, vSRAMTemplate_155_i_io_mbistCgCtl_en); end
    if (vSRAMTemplate_155_g_io_mbistCgCtl_rckEn !== vSRAMTemplate_155_i_io_mbistCgCtl_rckEn) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_155.io_mbistCgCtl_rckEn g=%h i=%h", $time, vSRAMTemplate_155_g_io_mbistCgCtl_rckEn, vSRAMTemplate_155_i_io_mbistCgCtl_rckEn); end
    if (has_z(vSRAMTemplate_155_g_io_mbistCgCtl_rckEn, 1) || has_z(vSRAMTemplate_155_i_io_mbistCgCtl_rckEn, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_155.io_mbistCgCtl_rckEn g=%h i=%h", $time, vSRAMTemplate_155_g_io_mbistCgCtl_rckEn, vSRAMTemplate_155_i_io_mbistCgCtl_rckEn); end
    if (vSRAMTemplate_155_g_io_mbistCgCtl_wckEn !== vSRAMTemplate_155_i_io_mbistCgCtl_wckEn) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_155.io_mbistCgCtl_wckEn g=%h i=%h", $time, vSRAMTemplate_155_g_io_mbistCgCtl_wckEn, vSRAMTemplate_155_i_io_mbistCgCtl_wckEn); end
    if (has_z(vSRAMTemplate_155_g_io_mbistCgCtl_wckEn, 1) || has_z(vSRAMTemplate_155_i_io_mbistCgCtl_wckEn, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_155.io_mbistCgCtl_wckEn g=%h i=%h", $time, vSRAMTemplate_155_g_io_mbistCgCtl_wckEn, vSRAMTemplate_155_i_io_mbistCgCtl_wckEn); end
    if (vSRAMTemplate_155_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_155_i_boreChildrenBd_bore_rdata) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_155.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_155_g_boreChildrenBd_bore_rdata, vSRAMTemplate_155_i_boreChildrenBd_bore_rdata); end
    if (has_z(vSRAMTemplate_155_g_boreChildrenBd_bore_rdata, 137) || has_z(vSRAMTemplate_155_i_boreChildrenBd_bore_rdata, 137)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_155.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_155_g_boreChildrenBd_bore_rdata, vSRAMTemplate_155_i_boreChildrenBd_bore_rdata); end
  end

  // ================= SRAMTemplate_163 =================
  logic vSRAMTemplate_163_io_r_req_valid;
  logic [8:0] vSRAMTemplate_163_io_r_req_bits_setIdx;
  logic vSRAMTemplate_163_io_w_req_valid;
  logic [8:0] vSRAMTemplate_163_io_w_req_bits_setIdx;
  logic vSRAMTemplate_163_io_w_req_bits_data_0_dirty;
  logic [1:0] vSRAMTemplate_163_io_w_req_bits_data_0_state;
  logic vSRAMTemplate_163_io_w_req_bits_data_0_clients;
  logic [1:0] vSRAMTemplate_163_io_w_req_bits_data_0_alias;
  logic vSRAMTemplate_163_io_w_req_bits_data_0_prefetch;
  logic [2:0] vSRAMTemplate_163_io_w_req_bits_data_0_prefetchSrc;
  logic vSRAMTemplate_163_io_w_req_bits_data_0_accessed;
  logic vSRAMTemplate_163_io_w_req_bits_data_0_tagErr;
  logic vSRAMTemplate_163_io_w_req_bits_data_0_dataErr;
  logic vSRAMTemplate_163_io_w_req_bits_data_1_dirty;
  logic [1:0] vSRAMTemplate_163_io_w_req_bits_data_1_state;
  logic vSRAMTemplate_163_io_w_req_bits_data_1_clients;
  logic [1:0] vSRAMTemplate_163_io_w_req_bits_data_1_alias;
  logic vSRAMTemplate_163_io_w_req_bits_data_1_prefetch;
  logic [2:0] vSRAMTemplate_163_io_w_req_bits_data_1_prefetchSrc;
  logic vSRAMTemplate_163_io_w_req_bits_data_1_accessed;
  logic vSRAMTemplate_163_io_w_req_bits_data_1_tagErr;
  logic vSRAMTemplate_163_io_w_req_bits_data_1_dataErr;
  logic vSRAMTemplate_163_io_w_req_bits_data_2_dirty;
  logic [1:0] vSRAMTemplate_163_io_w_req_bits_data_2_state;
  logic vSRAMTemplate_163_io_w_req_bits_data_2_clients;
  logic [1:0] vSRAMTemplate_163_io_w_req_bits_data_2_alias;
  logic vSRAMTemplate_163_io_w_req_bits_data_2_prefetch;
  logic [2:0] vSRAMTemplate_163_io_w_req_bits_data_2_prefetchSrc;
  logic vSRAMTemplate_163_io_w_req_bits_data_2_accessed;
  logic vSRAMTemplate_163_io_w_req_bits_data_2_tagErr;
  logic vSRAMTemplate_163_io_w_req_bits_data_2_dataErr;
  logic vSRAMTemplate_163_io_w_req_bits_data_3_dirty;
  logic [1:0] vSRAMTemplate_163_io_w_req_bits_data_3_state;
  logic vSRAMTemplate_163_io_w_req_bits_data_3_clients;
  logic [1:0] vSRAMTemplate_163_io_w_req_bits_data_3_alias;
  logic vSRAMTemplate_163_io_w_req_bits_data_3_prefetch;
  logic [2:0] vSRAMTemplate_163_io_w_req_bits_data_3_prefetchSrc;
  logic vSRAMTemplate_163_io_w_req_bits_data_3_accessed;
  logic vSRAMTemplate_163_io_w_req_bits_data_3_tagErr;
  logic vSRAMTemplate_163_io_w_req_bits_data_3_dataErr;
  logic vSRAMTemplate_163_io_w_req_bits_data_4_dirty;
  logic [1:0] vSRAMTemplate_163_io_w_req_bits_data_4_state;
  logic vSRAMTemplate_163_io_w_req_bits_data_4_clients;
  logic [1:0] vSRAMTemplate_163_io_w_req_bits_data_4_alias;
  logic vSRAMTemplate_163_io_w_req_bits_data_4_prefetch;
  logic [2:0] vSRAMTemplate_163_io_w_req_bits_data_4_prefetchSrc;
  logic vSRAMTemplate_163_io_w_req_bits_data_4_accessed;
  logic vSRAMTemplate_163_io_w_req_bits_data_4_tagErr;
  logic vSRAMTemplate_163_io_w_req_bits_data_4_dataErr;
  logic vSRAMTemplate_163_io_w_req_bits_data_5_dirty;
  logic [1:0] vSRAMTemplate_163_io_w_req_bits_data_5_state;
  logic vSRAMTemplate_163_io_w_req_bits_data_5_clients;
  logic [1:0] vSRAMTemplate_163_io_w_req_bits_data_5_alias;
  logic vSRAMTemplate_163_io_w_req_bits_data_5_prefetch;
  logic [2:0] vSRAMTemplate_163_io_w_req_bits_data_5_prefetchSrc;
  logic vSRAMTemplate_163_io_w_req_bits_data_5_accessed;
  logic vSRAMTemplate_163_io_w_req_bits_data_5_tagErr;
  logic vSRAMTemplate_163_io_w_req_bits_data_5_dataErr;
  logic vSRAMTemplate_163_io_w_req_bits_data_6_dirty;
  logic [1:0] vSRAMTemplate_163_io_w_req_bits_data_6_state;
  logic vSRAMTemplate_163_io_w_req_bits_data_6_clients;
  logic [1:0] vSRAMTemplate_163_io_w_req_bits_data_6_alias;
  logic vSRAMTemplate_163_io_w_req_bits_data_6_prefetch;
  logic [2:0] vSRAMTemplate_163_io_w_req_bits_data_6_prefetchSrc;
  logic vSRAMTemplate_163_io_w_req_bits_data_6_accessed;
  logic vSRAMTemplate_163_io_w_req_bits_data_6_tagErr;
  logic vSRAMTemplate_163_io_w_req_bits_data_6_dataErr;
  logic vSRAMTemplate_163_io_w_req_bits_data_7_dirty;
  logic [1:0] vSRAMTemplate_163_io_w_req_bits_data_7_state;
  logic vSRAMTemplate_163_io_w_req_bits_data_7_clients;
  logic [1:0] vSRAMTemplate_163_io_w_req_bits_data_7_alias;
  logic vSRAMTemplate_163_io_w_req_bits_data_7_prefetch;
  logic [2:0] vSRAMTemplate_163_io_w_req_bits_data_7_prefetchSrc;
  logic vSRAMTemplate_163_io_w_req_bits_data_7_accessed;
  logic vSRAMTemplate_163_io_w_req_bits_data_7_tagErr;
  logic vSRAMTemplate_163_io_w_req_bits_data_7_dataErr;
  logic [7:0] vSRAMTemplate_163_io_w_req_bits_waymask;
  logic vSRAMTemplate_163_io_broadcast_ram_hold;
  logic vSRAMTemplate_163_io_broadcast_ram_bypass;
  logic vSRAMTemplate_163_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_163_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_163_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_163_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_163_io_broadcast_ram_ctl;
  logic vSRAMTemplate_163_io_broadcast_cgen;
  logic [9:0] vSRAMTemplate_163_boreChildrenBd_bore_addr;
  logic [9:0] vSRAMTemplate_163_boreChildrenBd_bore_addr_rd;
  logic [103:0] vSRAMTemplate_163_boreChildrenBd_bore_wdata;
  logic [7:0] vSRAMTemplate_163_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_163_boreChildrenBd_bore_re;
  logic vSRAMTemplate_163_boreChildrenBd_bore_we;
  logic vSRAMTemplate_163_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_163_boreChildrenBd_bore_selectedOH;
  logic [4:0] vSRAMTemplate_163_boreChildrenBd_bore_array;
  wire vSRAMTemplate_163_g_io_r_req_ready;
  wire vSRAMTemplate_163_i_io_r_req_ready;
  wire vSRAMTemplate_163_g_io_r_resp_data_0_dirty;
  wire vSRAMTemplate_163_i_io_r_resp_data_0_dirty;
  wire [1:0] vSRAMTemplate_163_g_io_r_resp_data_0_state;
  wire [1:0] vSRAMTemplate_163_i_io_r_resp_data_0_state;
  wire vSRAMTemplate_163_g_io_r_resp_data_0_clients;
  wire vSRAMTemplate_163_i_io_r_resp_data_0_clients;
  wire [1:0] vSRAMTemplate_163_g_io_r_resp_data_0_alias;
  wire [1:0] vSRAMTemplate_163_i_io_r_resp_data_0_alias;
  wire vSRAMTemplate_163_g_io_r_resp_data_0_prefetch;
  wire vSRAMTemplate_163_i_io_r_resp_data_0_prefetch;
  wire [2:0] vSRAMTemplate_163_g_io_r_resp_data_0_prefetchSrc;
  wire [2:0] vSRAMTemplate_163_i_io_r_resp_data_0_prefetchSrc;
  wire vSRAMTemplate_163_g_io_r_resp_data_0_accessed;
  wire vSRAMTemplate_163_i_io_r_resp_data_0_accessed;
  wire vSRAMTemplate_163_g_io_r_resp_data_0_tagErr;
  wire vSRAMTemplate_163_i_io_r_resp_data_0_tagErr;
  wire vSRAMTemplate_163_g_io_r_resp_data_0_dataErr;
  wire vSRAMTemplate_163_i_io_r_resp_data_0_dataErr;
  wire vSRAMTemplate_163_g_io_r_resp_data_1_dirty;
  wire vSRAMTemplate_163_i_io_r_resp_data_1_dirty;
  wire [1:0] vSRAMTemplate_163_g_io_r_resp_data_1_state;
  wire [1:0] vSRAMTemplate_163_i_io_r_resp_data_1_state;
  wire vSRAMTemplate_163_g_io_r_resp_data_1_clients;
  wire vSRAMTemplate_163_i_io_r_resp_data_1_clients;
  wire [1:0] vSRAMTemplate_163_g_io_r_resp_data_1_alias;
  wire [1:0] vSRAMTemplate_163_i_io_r_resp_data_1_alias;
  wire vSRAMTemplate_163_g_io_r_resp_data_1_prefetch;
  wire vSRAMTemplate_163_i_io_r_resp_data_1_prefetch;
  wire [2:0] vSRAMTemplate_163_g_io_r_resp_data_1_prefetchSrc;
  wire [2:0] vSRAMTemplate_163_i_io_r_resp_data_1_prefetchSrc;
  wire vSRAMTemplate_163_g_io_r_resp_data_1_accessed;
  wire vSRAMTemplate_163_i_io_r_resp_data_1_accessed;
  wire vSRAMTemplate_163_g_io_r_resp_data_1_tagErr;
  wire vSRAMTemplate_163_i_io_r_resp_data_1_tagErr;
  wire vSRAMTemplate_163_g_io_r_resp_data_1_dataErr;
  wire vSRAMTemplate_163_i_io_r_resp_data_1_dataErr;
  wire vSRAMTemplate_163_g_io_r_resp_data_2_dirty;
  wire vSRAMTemplate_163_i_io_r_resp_data_2_dirty;
  wire [1:0] vSRAMTemplate_163_g_io_r_resp_data_2_state;
  wire [1:0] vSRAMTemplate_163_i_io_r_resp_data_2_state;
  wire vSRAMTemplate_163_g_io_r_resp_data_2_clients;
  wire vSRAMTemplate_163_i_io_r_resp_data_2_clients;
  wire [1:0] vSRAMTemplate_163_g_io_r_resp_data_2_alias;
  wire [1:0] vSRAMTemplate_163_i_io_r_resp_data_2_alias;
  wire vSRAMTemplate_163_g_io_r_resp_data_2_prefetch;
  wire vSRAMTemplate_163_i_io_r_resp_data_2_prefetch;
  wire [2:0] vSRAMTemplate_163_g_io_r_resp_data_2_prefetchSrc;
  wire [2:0] vSRAMTemplate_163_i_io_r_resp_data_2_prefetchSrc;
  wire vSRAMTemplate_163_g_io_r_resp_data_2_accessed;
  wire vSRAMTemplate_163_i_io_r_resp_data_2_accessed;
  wire vSRAMTemplate_163_g_io_r_resp_data_2_tagErr;
  wire vSRAMTemplate_163_i_io_r_resp_data_2_tagErr;
  wire vSRAMTemplate_163_g_io_r_resp_data_2_dataErr;
  wire vSRAMTemplate_163_i_io_r_resp_data_2_dataErr;
  wire vSRAMTemplate_163_g_io_r_resp_data_3_dirty;
  wire vSRAMTemplate_163_i_io_r_resp_data_3_dirty;
  wire [1:0] vSRAMTemplate_163_g_io_r_resp_data_3_state;
  wire [1:0] vSRAMTemplate_163_i_io_r_resp_data_3_state;
  wire vSRAMTemplate_163_g_io_r_resp_data_3_clients;
  wire vSRAMTemplate_163_i_io_r_resp_data_3_clients;
  wire [1:0] vSRAMTemplate_163_g_io_r_resp_data_3_alias;
  wire [1:0] vSRAMTemplate_163_i_io_r_resp_data_3_alias;
  wire vSRAMTemplate_163_g_io_r_resp_data_3_prefetch;
  wire vSRAMTemplate_163_i_io_r_resp_data_3_prefetch;
  wire [2:0] vSRAMTemplate_163_g_io_r_resp_data_3_prefetchSrc;
  wire [2:0] vSRAMTemplate_163_i_io_r_resp_data_3_prefetchSrc;
  wire vSRAMTemplate_163_g_io_r_resp_data_3_accessed;
  wire vSRAMTemplate_163_i_io_r_resp_data_3_accessed;
  wire vSRAMTemplate_163_g_io_r_resp_data_3_tagErr;
  wire vSRAMTemplate_163_i_io_r_resp_data_3_tagErr;
  wire vSRAMTemplate_163_g_io_r_resp_data_3_dataErr;
  wire vSRAMTemplate_163_i_io_r_resp_data_3_dataErr;
  wire vSRAMTemplate_163_g_io_r_resp_data_4_dirty;
  wire vSRAMTemplate_163_i_io_r_resp_data_4_dirty;
  wire [1:0] vSRAMTemplate_163_g_io_r_resp_data_4_state;
  wire [1:0] vSRAMTemplate_163_i_io_r_resp_data_4_state;
  wire vSRAMTemplate_163_g_io_r_resp_data_4_clients;
  wire vSRAMTemplate_163_i_io_r_resp_data_4_clients;
  wire [1:0] vSRAMTemplate_163_g_io_r_resp_data_4_alias;
  wire [1:0] vSRAMTemplate_163_i_io_r_resp_data_4_alias;
  wire vSRAMTemplate_163_g_io_r_resp_data_4_prefetch;
  wire vSRAMTemplate_163_i_io_r_resp_data_4_prefetch;
  wire [2:0] vSRAMTemplate_163_g_io_r_resp_data_4_prefetchSrc;
  wire [2:0] vSRAMTemplate_163_i_io_r_resp_data_4_prefetchSrc;
  wire vSRAMTemplate_163_g_io_r_resp_data_4_accessed;
  wire vSRAMTemplate_163_i_io_r_resp_data_4_accessed;
  wire vSRAMTemplate_163_g_io_r_resp_data_4_tagErr;
  wire vSRAMTemplate_163_i_io_r_resp_data_4_tagErr;
  wire vSRAMTemplate_163_g_io_r_resp_data_4_dataErr;
  wire vSRAMTemplate_163_i_io_r_resp_data_4_dataErr;
  wire vSRAMTemplate_163_g_io_r_resp_data_5_dirty;
  wire vSRAMTemplate_163_i_io_r_resp_data_5_dirty;
  wire [1:0] vSRAMTemplate_163_g_io_r_resp_data_5_state;
  wire [1:0] vSRAMTemplate_163_i_io_r_resp_data_5_state;
  wire vSRAMTemplate_163_g_io_r_resp_data_5_clients;
  wire vSRAMTemplate_163_i_io_r_resp_data_5_clients;
  wire [1:0] vSRAMTemplate_163_g_io_r_resp_data_5_alias;
  wire [1:0] vSRAMTemplate_163_i_io_r_resp_data_5_alias;
  wire vSRAMTemplate_163_g_io_r_resp_data_5_prefetch;
  wire vSRAMTemplate_163_i_io_r_resp_data_5_prefetch;
  wire [2:0] vSRAMTemplate_163_g_io_r_resp_data_5_prefetchSrc;
  wire [2:0] vSRAMTemplate_163_i_io_r_resp_data_5_prefetchSrc;
  wire vSRAMTemplate_163_g_io_r_resp_data_5_accessed;
  wire vSRAMTemplate_163_i_io_r_resp_data_5_accessed;
  wire vSRAMTemplate_163_g_io_r_resp_data_5_tagErr;
  wire vSRAMTemplate_163_i_io_r_resp_data_5_tagErr;
  wire vSRAMTemplate_163_g_io_r_resp_data_5_dataErr;
  wire vSRAMTemplate_163_i_io_r_resp_data_5_dataErr;
  wire vSRAMTemplate_163_g_io_r_resp_data_6_dirty;
  wire vSRAMTemplate_163_i_io_r_resp_data_6_dirty;
  wire [1:0] vSRAMTemplate_163_g_io_r_resp_data_6_state;
  wire [1:0] vSRAMTemplate_163_i_io_r_resp_data_6_state;
  wire vSRAMTemplate_163_g_io_r_resp_data_6_clients;
  wire vSRAMTemplate_163_i_io_r_resp_data_6_clients;
  wire [1:0] vSRAMTemplate_163_g_io_r_resp_data_6_alias;
  wire [1:0] vSRAMTemplate_163_i_io_r_resp_data_6_alias;
  wire vSRAMTemplate_163_g_io_r_resp_data_6_prefetch;
  wire vSRAMTemplate_163_i_io_r_resp_data_6_prefetch;
  wire [2:0] vSRAMTemplate_163_g_io_r_resp_data_6_prefetchSrc;
  wire [2:0] vSRAMTemplate_163_i_io_r_resp_data_6_prefetchSrc;
  wire vSRAMTemplate_163_g_io_r_resp_data_6_accessed;
  wire vSRAMTemplate_163_i_io_r_resp_data_6_accessed;
  wire vSRAMTemplate_163_g_io_r_resp_data_6_tagErr;
  wire vSRAMTemplate_163_i_io_r_resp_data_6_tagErr;
  wire vSRAMTemplate_163_g_io_r_resp_data_6_dataErr;
  wire vSRAMTemplate_163_i_io_r_resp_data_6_dataErr;
  wire vSRAMTemplate_163_g_io_r_resp_data_7_dirty;
  wire vSRAMTemplate_163_i_io_r_resp_data_7_dirty;
  wire [1:0] vSRAMTemplate_163_g_io_r_resp_data_7_state;
  wire [1:0] vSRAMTemplate_163_i_io_r_resp_data_7_state;
  wire vSRAMTemplate_163_g_io_r_resp_data_7_clients;
  wire vSRAMTemplate_163_i_io_r_resp_data_7_clients;
  wire [1:0] vSRAMTemplate_163_g_io_r_resp_data_7_alias;
  wire [1:0] vSRAMTemplate_163_i_io_r_resp_data_7_alias;
  wire vSRAMTemplate_163_g_io_r_resp_data_7_prefetch;
  wire vSRAMTemplate_163_i_io_r_resp_data_7_prefetch;
  wire [2:0] vSRAMTemplate_163_g_io_r_resp_data_7_prefetchSrc;
  wire [2:0] vSRAMTemplate_163_i_io_r_resp_data_7_prefetchSrc;
  wire vSRAMTemplate_163_g_io_r_resp_data_7_accessed;
  wire vSRAMTemplate_163_i_io_r_resp_data_7_accessed;
  wire vSRAMTemplate_163_g_io_r_resp_data_7_tagErr;
  wire vSRAMTemplate_163_i_io_r_resp_data_7_tagErr;
  wire vSRAMTemplate_163_g_io_r_resp_data_7_dataErr;
  wire vSRAMTemplate_163_i_io_r_resp_data_7_dataErr;
  wire vSRAMTemplate_163_g_io_w_req_ready;
  wire vSRAMTemplate_163_i_io_w_req_ready;
  wire vSRAMTemplate_163_g_io_resetDone;
  wire vSRAMTemplate_163_i_io_resetDone;
  wire [103:0] vSRAMTemplate_163_g_boreChildrenBd_bore_rdata;
  wire [103:0] vSRAMTemplate_163_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_163    u_g_SRAMTemplate_163 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_163_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_163_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_163_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_163_io_w_req_bits_setIdx), .io_w_req_bits_data_0_dirty(vSRAMTemplate_163_io_w_req_bits_data_0_dirty), .io_w_req_bits_data_0_state(vSRAMTemplate_163_io_w_req_bits_data_0_state), .io_w_req_bits_data_0_clients(vSRAMTemplate_163_io_w_req_bits_data_0_clients), .io_w_req_bits_data_0_alias(vSRAMTemplate_163_io_w_req_bits_data_0_alias), .io_w_req_bits_data_0_prefetch(vSRAMTemplate_163_io_w_req_bits_data_0_prefetch), .io_w_req_bits_data_0_prefetchSrc(vSRAMTemplate_163_io_w_req_bits_data_0_prefetchSrc), .io_w_req_bits_data_0_accessed(vSRAMTemplate_163_io_w_req_bits_data_0_accessed), .io_w_req_bits_data_0_tagErr(vSRAMTemplate_163_io_w_req_bits_data_0_tagErr), .io_w_req_bits_data_0_dataErr(vSRAMTemplate_163_io_w_req_bits_data_0_dataErr), .io_w_req_bits_data_1_dirty(vSRAMTemplate_163_io_w_req_bits_data_1_dirty), .io_w_req_bits_data_1_state(vSRAMTemplate_163_io_w_req_bits_data_1_state), .io_w_req_bits_data_1_clients(vSRAMTemplate_163_io_w_req_bits_data_1_clients), .io_w_req_bits_data_1_alias(vSRAMTemplate_163_io_w_req_bits_data_1_alias), .io_w_req_bits_data_1_prefetch(vSRAMTemplate_163_io_w_req_bits_data_1_prefetch), .io_w_req_bits_data_1_prefetchSrc(vSRAMTemplate_163_io_w_req_bits_data_1_prefetchSrc), .io_w_req_bits_data_1_accessed(vSRAMTemplate_163_io_w_req_bits_data_1_accessed), .io_w_req_bits_data_1_tagErr(vSRAMTemplate_163_io_w_req_bits_data_1_tagErr), .io_w_req_bits_data_1_dataErr(vSRAMTemplate_163_io_w_req_bits_data_1_dataErr), .io_w_req_bits_data_2_dirty(vSRAMTemplate_163_io_w_req_bits_data_2_dirty), .io_w_req_bits_data_2_state(vSRAMTemplate_163_io_w_req_bits_data_2_state), .io_w_req_bits_data_2_clients(vSRAMTemplate_163_io_w_req_bits_data_2_clients), .io_w_req_bits_data_2_alias(vSRAMTemplate_163_io_w_req_bits_data_2_alias), .io_w_req_bits_data_2_prefetch(vSRAMTemplate_163_io_w_req_bits_data_2_prefetch), .io_w_req_bits_data_2_prefetchSrc(vSRAMTemplate_163_io_w_req_bits_data_2_prefetchSrc), .io_w_req_bits_data_2_accessed(vSRAMTemplate_163_io_w_req_bits_data_2_accessed), .io_w_req_bits_data_2_tagErr(vSRAMTemplate_163_io_w_req_bits_data_2_tagErr), .io_w_req_bits_data_2_dataErr(vSRAMTemplate_163_io_w_req_bits_data_2_dataErr), .io_w_req_bits_data_3_dirty(vSRAMTemplate_163_io_w_req_bits_data_3_dirty), .io_w_req_bits_data_3_state(vSRAMTemplate_163_io_w_req_bits_data_3_state), .io_w_req_bits_data_3_clients(vSRAMTemplate_163_io_w_req_bits_data_3_clients), .io_w_req_bits_data_3_alias(vSRAMTemplate_163_io_w_req_bits_data_3_alias), .io_w_req_bits_data_3_prefetch(vSRAMTemplate_163_io_w_req_bits_data_3_prefetch), .io_w_req_bits_data_3_prefetchSrc(vSRAMTemplate_163_io_w_req_bits_data_3_prefetchSrc), .io_w_req_bits_data_3_accessed(vSRAMTemplate_163_io_w_req_bits_data_3_accessed), .io_w_req_bits_data_3_tagErr(vSRAMTemplate_163_io_w_req_bits_data_3_tagErr), .io_w_req_bits_data_3_dataErr(vSRAMTemplate_163_io_w_req_bits_data_3_dataErr), .io_w_req_bits_data_4_dirty(vSRAMTemplate_163_io_w_req_bits_data_4_dirty), .io_w_req_bits_data_4_state(vSRAMTemplate_163_io_w_req_bits_data_4_state), .io_w_req_bits_data_4_clients(vSRAMTemplate_163_io_w_req_bits_data_4_clients), .io_w_req_bits_data_4_alias(vSRAMTemplate_163_io_w_req_bits_data_4_alias), .io_w_req_bits_data_4_prefetch(vSRAMTemplate_163_io_w_req_bits_data_4_prefetch), .io_w_req_bits_data_4_prefetchSrc(vSRAMTemplate_163_io_w_req_bits_data_4_prefetchSrc), .io_w_req_bits_data_4_accessed(vSRAMTemplate_163_io_w_req_bits_data_4_accessed), .io_w_req_bits_data_4_tagErr(vSRAMTemplate_163_io_w_req_bits_data_4_tagErr), .io_w_req_bits_data_4_dataErr(vSRAMTemplate_163_io_w_req_bits_data_4_dataErr), .io_w_req_bits_data_5_dirty(vSRAMTemplate_163_io_w_req_bits_data_5_dirty), .io_w_req_bits_data_5_state(vSRAMTemplate_163_io_w_req_bits_data_5_state), .io_w_req_bits_data_5_clients(vSRAMTemplate_163_io_w_req_bits_data_5_clients), .io_w_req_bits_data_5_alias(vSRAMTemplate_163_io_w_req_bits_data_5_alias), .io_w_req_bits_data_5_prefetch(vSRAMTemplate_163_io_w_req_bits_data_5_prefetch), .io_w_req_bits_data_5_prefetchSrc(vSRAMTemplate_163_io_w_req_bits_data_5_prefetchSrc), .io_w_req_bits_data_5_accessed(vSRAMTemplate_163_io_w_req_bits_data_5_accessed), .io_w_req_bits_data_5_tagErr(vSRAMTemplate_163_io_w_req_bits_data_5_tagErr), .io_w_req_bits_data_5_dataErr(vSRAMTemplate_163_io_w_req_bits_data_5_dataErr), .io_w_req_bits_data_6_dirty(vSRAMTemplate_163_io_w_req_bits_data_6_dirty), .io_w_req_bits_data_6_state(vSRAMTemplate_163_io_w_req_bits_data_6_state), .io_w_req_bits_data_6_clients(vSRAMTemplate_163_io_w_req_bits_data_6_clients), .io_w_req_bits_data_6_alias(vSRAMTemplate_163_io_w_req_bits_data_6_alias), .io_w_req_bits_data_6_prefetch(vSRAMTemplate_163_io_w_req_bits_data_6_prefetch), .io_w_req_bits_data_6_prefetchSrc(vSRAMTemplate_163_io_w_req_bits_data_6_prefetchSrc), .io_w_req_bits_data_6_accessed(vSRAMTemplate_163_io_w_req_bits_data_6_accessed), .io_w_req_bits_data_6_tagErr(vSRAMTemplate_163_io_w_req_bits_data_6_tagErr), .io_w_req_bits_data_6_dataErr(vSRAMTemplate_163_io_w_req_bits_data_6_dataErr), .io_w_req_bits_data_7_dirty(vSRAMTemplate_163_io_w_req_bits_data_7_dirty), .io_w_req_bits_data_7_state(vSRAMTemplate_163_io_w_req_bits_data_7_state), .io_w_req_bits_data_7_clients(vSRAMTemplate_163_io_w_req_bits_data_7_clients), .io_w_req_bits_data_7_alias(vSRAMTemplate_163_io_w_req_bits_data_7_alias), .io_w_req_bits_data_7_prefetch(vSRAMTemplate_163_io_w_req_bits_data_7_prefetch), .io_w_req_bits_data_7_prefetchSrc(vSRAMTemplate_163_io_w_req_bits_data_7_prefetchSrc), .io_w_req_bits_data_7_accessed(vSRAMTemplate_163_io_w_req_bits_data_7_accessed), .io_w_req_bits_data_7_tagErr(vSRAMTemplate_163_io_w_req_bits_data_7_tagErr), .io_w_req_bits_data_7_dataErr(vSRAMTemplate_163_io_w_req_bits_data_7_dataErr), .io_w_req_bits_waymask(vSRAMTemplate_163_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_163_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_163_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_163_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_163_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_163_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_163_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_163_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_163_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_163_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_163_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_163_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_163_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_163_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_163_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_163_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_163_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_163_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_163_g_io_r_req_ready), .io_r_resp_data_0_dirty(vSRAMTemplate_163_g_io_r_resp_data_0_dirty), .io_r_resp_data_0_state(vSRAMTemplate_163_g_io_r_resp_data_0_state), .io_r_resp_data_0_clients(vSRAMTemplate_163_g_io_r_resp_data_0_clients), .io_r_resp_data_0_alias(vSRAMTemplate_163_g_io_r_resp_data_0_alias), .io_r_resp_data_0_prefetch(vSRAMTemplate_163_g_io_r_resp_data_0_prefetch), .io_r_resp_data_0_prefetchSrc(vSRAMTemplate_163_g_io_r_resp_data_0_prefetchSrc), .io_r_resp_data_0_accessed(vSRAMTemplate_163_g_io_r_resp_data_0_accessed), .io_r_resp_data_0_tagErr(vSRAMTemplate_163_g_io_r_resp_data_0_tagErr), .io_r_resp_data_0_dataErr(vSRAMTemplate_163_g_io_r_resp_data_0_dataErr), .io_r_resp_data_1_dirty(vSRAMTemplate_163_g_io_r_resp_data_1_dirty), .io_r_resp_data_1_state(vSRAMTemplate_163_g_io_r_resp_data_1_state), .io_r_resp_data_1_clients(vSRAMTemplate_163_g_io_r_resp_data_1_clients), .io_r_resp_data_1_alias(vSRAMTemplate_163_g_io_r_resp_data_1_alias), .io_r_resp_data_1_prefetch(vSRAMTemplate_163_g_io_r_resp_data_1_prefetch), .io_r_resp_data_1_prefetchSrc(vSRAMTemplate_163_g_io_r_resp_data_1_prefetchSrc), .io_r_resp_data_1_accessed(vSRAMTemplate_163_g_io_r_resp_data_1_accessed), .io_r_resp_data_1_tagErr(vSRAMTemplate_163_g_io_r_resp_data_1_tagErr), .io_r_resp_data_1_dataErr(vSRAMTemplate_163_g_io_r_resp_data_1_dataErr), .io_r_resp_data_2_dirty(vSRAMTemplate_163_g_io_r_resp_data_2_dirty), .io_r_resp_data_2_state(vSRAMTemplate_163_g_io_r_resp_data_2_state), .io_r_resp_data_2_clients(vSRAMTemplate_163_g_io_r_resp_data_2_clients), .io_r_resp_data_2_alias(vSRAMTemplate_163_g_io_r_resp_data_2_alias), .io_r_resp_data_2_prefetch(vSRAMTemplate_163_g_io_r_resp_data_2_prefetch), .io_r_resp_data_2_prefetchSrc(vSRAMTemplate_163_g_io_r_resp_data_2_prefetchSrc), .io_r_resp_data_2_accessed(vSRAMTemplate_163_g_io_r_resp_data_2_accessed), .io_r_resp_data_2_tagErr(vSRAMTemplate_163_g_io_r_resp_data_2_tagErr), .io_r_resp_data_2_dataErr(vSRAMTemplate_163_g_io_r_resp_data_2_dataErr), .io_r_resp_data_3_dirty(vSRAMTemplate_163_g_io_r_resp_data_3_dirty), .io_r_resp_data_3_state(vSRAMTemplate_163_g_io_r_resp_data_3_state), .io_r_resp_data_3_clients(vSRAMTemplate_163_g_io_r_resp_data_3_clients), .io_r_resp_data_3_alias(vSRAMTemplate_163_g_io_r_resp_data_3_alias), .io_r_resp_data_3_prefetch(vSRAMTemplate_163_g_io_r_resp_data_3_prefetch), .io_r_resp_data_3_prefetchSrc(vSRAMTemplate_163_g_io_r_resp_data_3_prefetchSrc), .io_r_resp_data_3_accessed(vSRAMTemplate_163_g_io_r_resp_data_3_accessed), .io_r_resp_data_3_tagErr(vSRAMTemplate_163_g_io_r_resp_data_3_tagErr), .io_r_resp_data_3_dataErr(vSRAMTemplate_163_g_io_r_resp_data_3_dataErr), .io_r_resp_data_4_dirty(vSRAMTemplate_163_g_io_r_resp_data_4_dirty), .io_r_resp_data_4_state(vSRAMTemplate_163_g_io_r_resp_data_4_state), .io_r_resp_data_4_clients(vSRAMTemplate_163_g_io_r_resp_data_4_clients), .io_r_resp_data_4_alias(vSRAMTemplate_163_g_io_r_resp_data_4_alias), .io_r_resp_data_4_prefetch(vSRAMTemplate_163_g_io_r_resp_data_4_prefetch), .io_r_resp_data_4_prefetchSrc(vSRAMTemplate_163_g_io_r_resp_data_4_prefetchSrc), .io_r_resp_data_4_accessed(vSRAMTemplate_163_g_io_r_resp_data_4_accessed), .io_r_resp_data_4_tagErr(vSRAMTemplate_163_g_io_r_resp_data_4_tagErr), .io_r_resp_data_4_dataErr(vSRAMTemplate_163_g_io_r_resp_data_4_dataErr), .io_r_resp_data_5_dirty(vSRAMTemplate_163_g_io_r_resp_data_5_dirty), .io_r_resp_data_5_state(vSRAMTemplate_163_g_io_r_resp_data_5_state), .io_r_resp_data_5_clients(vSRAMTemplate_163_g_io_r_resp_data_5_clients), .io_r_resp_data_5_alias(vSRAMTemplate_163_g_io_r_resp_data_5_alias), .io_r_resp_data_5_prefetch(vSRAMTemplate_163_g_io_r_resp_data_5_prefetch), .io_r_resp_data_5_prefetchSrc(vSRAMTemplate_163_g_io_r_resp_data_5_prefetchSrc), .io_r_resp_data_5_accessed(vSRAMTemplate_163_g_io_r_resp_data_5_accessed), .io_r_resp_data_5_tagErr(vSRAMTemplate_163_g_io_r_resp_data_5_tagErr), .io_r_resp_data_5_dataErr(vSRAMTemplate_163_g_io_r_resp_data_5_dataErr), .io_r_resp_data_6_dirty(vSRAMTemplate_163_g_io_r_resp_data_6_dirty), .io_r_resp_data_6_state(vSRAMTemplate_163_g_io_r_resp_data_6_state), .io_r_resp_data_6_clients(vSRAMTemplate_163_g_io_r_resp_data_6_clients), .io_r_resp_data_6_alias(vSRAMTemplate_163_g_io_r_resp_data_6_alias), .io_r_resp_data_6_prefetch(vSRAMTemplate_163_g_io_r_resp_data_6_prefetch), .io_r_resp_data_6_prefetchSrc(vSRAMTemplate_163_g_io_r_resp_data_6_prefetchSrc), .io_r_resp_data_6_accessed(vSRAMTemplate_163_g_io_r_resp_data_6_accessed), .io_r_resp_data_6_tagErr(vSRAMTemplate_163_g_io_r_resp_data_6_tagErr), .io_r_resp_data_6_dataErr(vSRAMTemplate_163_g_io_r_resp_data_6_dataErr), .io_r_resp_data_7_dirty(vSRAMTemplate_163_g_io_r_resp_data_7_dirty), .io_r_resp_data_7_state(vSRAMTemplate_163_g_io_r_resp_data_7_state), .io_r_resp_data_7_clients(vSRAMTemplate_163_g_io_r_resp_data_7_clients), .io_r_resp_data_7_alias(vSRAMTemplate_163_g_io_r_resp_data_7_alias), .io_r_resp_data_7_prefetch(vSRAMTemplate_163_g_io_r_resp_data_7_prefetch), .io_r_resp_data_7_prefetchSrc(vSRAMTemplate_163_g_io_r_resp_data_7_prefetchSrc), .io_r_resp_data_7_accessed(vSRAMTemplate_163_g_io_r_resp_data_7_accessed), .io_r_resp_data_7_tagErr(vSRAMTemplate_163_g_io_r_resp_data_7_tagErr), .io_r_resp_data_7_dataErr(vSRAMTemplate_163_g_io_r_resp_data_7_dataErr), .io_w_req_ready(vSRAMTemplate_163_g_io_w_req_ready), .io_resetDone(vSRAMTemplate_163_g_io_resetDone), .boreChildrenBd_bore_rdata(vSRAMTemplate_163_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_163_xs u_i_SRAMTemplate_163 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_163_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_163_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_163_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_163_io_w_req_bits_setIdx), .io_w_req_bits_data_0_dirty(vSRAMTemplate_163_io_w_req_bits_data_0_dirty), .io_w_req_bits_data_0_state(vSRAMTemplate_163_io_w_req_bits_data_0_state), .io_w_req_bits_data_0_clients(vSRAMTemplate_163_io_w_req_bits_data_0_clients), .io_w_req_bits_data_0_alias(vSRAMTemplate_163_io_w_req_bits_data_0_alias), .io_w_req_bits_data_0_prefetch(vSRAMTemplate_163_io_w_req_bits_data_0_prefetch), .io_w_req_bits_data_0_prefetchSrc(vSRAMTemplate_163_io_w_req_bits_data_0_prefetchSrc), .io_w_req_bits_data_0_accessed(vSRAMTemplate_163_io_w_req_bits_data_0_accessed), .io_w_req_bits_data_0_tagErr(vSRAMTemplate_163_io_w_req_bits_data_0_tagErr), .io_w_req_bits_data_0_dataErr(vSRAMTemplate_163_io_w_req_bits_data_0_dataErr), .io_w_req_bits_data_1_dirty(vSRAMTemplate_163_io_w_req_bits_data_1_dirty), .io_w_req_bits_data_1_state(vSRAMTemplate_163_io_w_req_bits_data_1_state), .io_w_req_bits_data_1_clients(vSRAMTemplate_163_io_w_req_bits_data_1_clients), .io_w_req_bits_data_1_alias(vSRAMTemplate_163_io_w_req_bits_data_1_alias), .io_w_req_bits_data_1_prefetch(vSRAMTemplate_163_io_w_req_bits_data_1_prefetch), .io_w_req_bits_data_1_prefetchSrc(vSRAMTemplate_163_io_w_req_bits_data_1_prefetchSrc), .io_w_req_bits_data_1_accessed(vSRAMTemplate_163_io_w_req_bits_data_1_accessed), .io_w_req_bits_data_1_tagErr(vSRAMTemplate_163_io_w_req_bits_data_1_tagErr), .io_w_req_bits_data_1_dataErr(vSRAMTemplate_163_io_w_req_bits_data_1_dataErr), .io_w_req_bits_data_2_dirty(vSRAMTemplate_163_io_w_req_bits_data_2_dirty), .io_w_req_bits_data_2_state(vSRAMTemplate_163_io_w_req_bits_data_2_state), .io_w_req_bits_data_2_clients(vSRAMTemplate_163_io_w_req_bits_data_2_clients), .io_w_req_bits_data_2_alias(vSRAMTemplate_163_io_w_req_bits_data_2_alias), .io_w_req_bits_data_2_prefetch(vSRAMTemplate_163_io_w_req_bits_data_2_prefetch), .io_w_req_bits_data_2_prefetchSrc(vSRAMTemplate_163_io_w_req_bits_data_2_prefetchSrc), .io_w_req_bits_data_2_accessed(vSRAMTemplate_163_io_w_req_bits_data_2_accessed), .io_w_req_bits_data_2_tagErr(vSRAMTemplate_163_io_w_req_bits_data_2_tagErr), .io_w_req_bits_data_2_dataErr(vSRAMTemplate_163_io_w_req_bits_data_2_dataErr), .io_w_req_bits_data_3_dirty(vSRAMTemplate_163_io_w_req_bits_data_3_dirty), .io_w_req_bits_data_3_state(vSRAMTemplate_163_io_w_req_bits_data_3_state), .io_w_req_bits_data_3_clients(vSRAMTemplate_163_io_w_req_bits_data_3_clients), .io_w_req_bits_data_3_alias(vSRAMTemplate_163_io_w_req_bits_data_3_alias), .io_w_req_bits_data_3_prefetch(vSRAMTemplate_163_io_w_req_bits_data_3_prefetch), .io_w_req_bits_data_3_prefetchSrc(vSRAMTemplate_163_io_w_req_bits_data_3_prefetchSrc), .io_w_req_bits_data_3_accessed(vSRAMTemplate_163_io_w_req_bits_data_3_accessed), .io_w_req_bits_data_3_tagErr(vSRAMTemplate_163_io_w_req_bits_data_3_tagErr), .io_w_req_bits_data_3_dataErr(vSRAMTemplate_163_io_w_req_bits_data_3_dataErr), .io_w_req_bits_data_4_dirty(vSRAMTemplate_163_io_w_req_bits_data_4_dirty), .io_w_req_bits_data_4_state(vSRAMTemplate_163_io_w_req_bits_data_4_state), .io_w_req_bits_data_4_clients(vSRAMTemplate_163_io_w_req_bits_data_4_clients), .io_w_req_bits_data_4_alias(vSRAMTemplate_163_io_w_req_bits_data_4_alias), .io_w_req_bits_data_4_prefetch(vSRAMTemplate_163_io_w_req_bits_data_4_prefetch), .io_w_req_bits_data_4_prefetchSrc(vSRAMTemplate_163_io_w_req_bits_data_4_prefetchSrc), .io_w_req_bits_data_4_accessed(vSRAMTemplate_163_io_w_req_bits_data_4_accessed), .io_w_req_bits_data_4_tagErr(vSRAMTemplate_163_io_w_req_bits_data_4_tagErr), .io_w_req_bits_data_4_dataErr(vSRAMTemplate_163_io_w_req_bits_data_4_dataErr), .io_w_req_bits_data_5_dirty(vSRAMTemplate_163_io_w_req_bits_data_5_dirty), .io_w_req_bits_data_5_state(vSRAMTemplate_163_io_w_req_bits_data_5_state), .io_w_req_bits_data_5_clients(vSRAMTemplate_163_io_w_req_bits_data_5_clients), .io_w_req_bits_data_5_alias(vSRAMTemplate_163_io_w_req_bits_data_5_alias), .io_w_req_bits_data_5_prefetch(vSRAMTemplate_163_io_w_req_bits_data_5_prefetch), .io_w_req_bits_data_5_prefetchSrc(vSRAMTemplate_163_io_w_req_bits_data_5_prefetchSrc), .io_w_req_bits_data_5_accessed(vSRAMTemplate_163_io_w_req_bits_data_5_accessed), .io_w_req_bits_data_5_tagErr(vSRAMTemplate_163_io_w_req_bits_data_5_tagErr), .io_w_req_bits_data_5_dataErr(vSRAMTemplate_163_io_w_req_bits_data_5_dataErr), .io_w_req_bits_data_6_dirty(vSRAMTemplate_163_io_w_req_bits_data_6_dirty), .io_w_req_bits_data_6_state(vSRAMTemplate_163_io_w_req_bits_data_6_state), .io_w_req_bits_data_6_clients(vSRAMTemplate_163_io_w_req_bits_data_6_clients), .io_w_req_bits_data_6_alias(vSRAMTemplate_163_io_w_req_bits_data_6_alias), .io_w_req_bits_data_6_prefetch(vSRAMTemplate_163_io_w_req_bits_data_6_prefetch), .io_w_req_bits_data_6_prefetchSrc(vSRAMTemplate_163_io_w_req_bits_data_6_prefetchSrc), .io_w_req_bits_data_6_accessed(vSRAMTemplate_163_io_w_req_bits_data_6_accessed), .io_w_req_bits_data_6_tagErr(vSRAMTemplate_163_io_w_req_bits_data_6_tagErr), .io_w_req_bits_data_6_dataErr(vSRAMTemplate_163_io_w_req_bits_data_6_dataErr), .io_w_req_bits_data_7_dirty(vSRAMTemplate_163_io_w_req_bits_data_7_dirty), .io_w_req_bits_data_7_state(vSRAMTemplate_163_io_w_req_bits_data_7_state), .io_w_req_bits_data_7_clients(vSRAMTemplate_163_io_w_req_bits_data_7_clients), .io_w_req_bits_data_7_alias(vSRAMTemplate_163_io_w_req_bits_data_7_alias), .io_w_req_bits_data_7_prefetch(vSRAMTemplate_163_io_w_req_bits_data_7_prefetch), .io_w_req_bits_data_7_prefetchSrc(vSRAMTemplate_163_io_w_req_bits_data_7_prefetchSrc), .io_w_req_bits_data_7_accessed(vSRAMTemplate_163_io_w_req_bits_data_7_accessed), .io_w_req_bits_data_7_tagErr(vSRAMTemplate_163_io_w_req_bits_data_7_tagErr), .io_w_req_bits_data_7_dataErr(vSRAMTemplate_163_io_w_req_bits_data_7_dataErr), .io_w_req_bits_waymask(vSRAMTemplate_163_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_163_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_163_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_163_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_163_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_163_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_163_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_163_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_163_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_163_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_163_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_163_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_163_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_163_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_163_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_163_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_163_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_163_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_163_i_io_r_req_ready), .io_r_resp_data_0_dirty(vSRAMTemplate_163_i_io_r_resp_data_0_dirty), .io_r_resp_data_0_state(vSRAMTemplate_163_i_io_r_resp_data_0_state), .io_r_resp_data_0_clients(vSRAMTemplate_163_i_io_r_resp_data_0_clients), .io_r_resp_data_0_alias(vSRAMTemplate_163_i_io_r_resp_data_0_alias), .io_r_resp_data_0_prefetch(vSRAMTemplate_163_i_io_r_resp_data_0_prefetch), .io_r_resp_data_0_prefetchSrc(vSRAMTemplate_163_i_io_r_resp_data_0_prefetchSrc), .io_r_resp_data_0_accessed(vSRAMTemplate_163_i_io_r_resp_data_0_accessed), .io_r_resp_data_0_tagErr(vSRAMTemplate_163_i_io_r_resp_data_0_tagErr), .io_r_resp_data_0_dataErr(vSRAMTemplate_163_i_io_r_resp_data_0_dataErr), .io_r_resp_data_1_dirty(vSRAMTemplate_163_i_io_r_resp_data_1_dirty), .io_r_resp_data_1_state(vSRAMTemplate_163_i_io_r_resp_data_1_state), .io_r_resp_data_1_clients(vSRAMTemplate_163_i_io_r_resp_data_1_clients), .io_r_resp_data_1_alias(vSRAMTemplate_163_i_io_r_resp_data_1_alias), .io_r_resp_data_1_prefetch(vSRAMTemplate_163_i_io_r_resp_data_1_prefetch), .io_r_resp_data_1_prefetchSrc(vSRAMTemplate_163_i_io_r_resp_data_1_prefetchSrc), .io_r_resp_data_1_accessed(vSRAMTemplate_163_i_io_r_resp_data_1_accessed), .io_r_resp_data_1_tagErr(vSRAMTemplate_163_i_io_r_resp_data_1_tagErr), .io_r_resp_data_1_dataErr(vSRAMTemplate_163_i_io_r_resp_data_1_dataErr), .io_r_resp_data_2_dirty(vSRAMTemplate_163_i_io_r_resp_data_2_dirty), .io_r_resp_data_2_state(vSRAMTemplate_163_i_io_r_resp_data_2_state), .io_r_resp_data_2_clients(vSRAMTemplate_163_i_io_r_resp_data_2_clients), .io_r_resp_data_2_alias(vSRAMTemplate_163_i_io_r_resp_data_2_alias), .io_r_resp_data_2_prefetch(vSRAMTemplate_163_i_io_r_resp_data_2_prefetch), .io_r_resp_data_2_prefetchSrc(vSRAMTemplate_163_i_io_r_resp_data_2_prefetchSrc), .io_r_resp_data_2_accessed(vSRAMTemplate_163_i_io_r_resp_data_2_accessed), .io_r_resp_data_2_tagErr(vSRAMTemplate_163_i_io_r_resp_data_2_tagErr), .io_r_resp_data_2_dataErr(vSRAMTemplate_163_i_io_r_resp_data_2_dataErr), .io_r_resp_data_3_dirty(vSRAMTemplate_163_i_io_r_resp_data_3_dirty), .io_r_resp_data_3_state(vSRAMTemplate_163_i_io_r_resp_data_3_state), .io_r_resp_data_3_clients(vSRAMTemplate_163_i_io_r_resp_data_3_clients), .io_r_resp_data_3_alias(vSRAMTemplate_163_i_io_r_resp_data_3_alias), .io_r_resp_data_3_prefetch(vSRAMTemplate_163_i_io_r_resp_data_3_prefetch), .io_r_resp_data_3_prefetchSrc(vSRAMTemplate_163_i_io_r_resp_data_3_prefetchSrc), .io_r_resp_data_3_accessed(vSRAMTemplate_163_i_io_r_resp_data_3_accessed), .io_r_resp_data_3_tagErr(vSRAMTemplate_163_i_io_r_resp_data_3_tagErr), .io_r_resp_data_3_dataErr(vSRAMTemplate_163_i_io_r_resp_data_3_dataErr), .io_r_resp_data_4_dirty(vSRAMTemplate_163_i_io_r_resp_data_4_dirty), .io_r_resp_data_4_state(vSRAMTemplate_163_i_io_r_resp_data_4_state), .io_r_resp_data_4_clients(vSRAMTemplate_163_i_io_r_resp_data_4_clients), .io_r_resp_data_4_alias(vSRAMTemplate_163_i_io_r_resp_data_4_alias), .io_r_resp_data_4_prefetch(vSRAMTemplate_163_i_io_r_resp_data_4_prefetch), .io_r_resp_data_4_prefetchSrc(vSRAMTemplate_163_i_io_r_resp_data_4_prefetchSrc), .io_r_resp_data_4_accessed(vSRAMTemplate_163_i_io_r_resp_data_4_accessed), .io_r_resp_data_4_tagErr(vSRAMTemplate_163_i_io_r_resp_data_4_tagErr), .io_r_resp_data_4_dataErr(vSRAMTemplate_163_i_io_r_resp_data_4_dataErr), .io_r_resp_data_5_dirty(vSRAMTemplate_163_i_io_r_resp_data_5_dirty), .io_r_resp_data_5_state(vSRAMTemplate_163_i_io_r_resp_data_5_state), .io_r_resp_data_5_clients(vSRAMTemplate_163_i_io_r_resp_data_5_clients), .io_r_resp_data_5_alias(vSRAMTemplate_163_i_io_r_resp_data_5_alias), .io_r_resp_data_5_prefetch(vSRAMTemplate_163_i_io_r_resp_data_5_prefetch), .io_r_resp_data_5_prefetchSrc(vSRAMTemplate_163_i_io_r_resp_data_5_prefetchSrc), .io_r_resp_data_5_accessed(vSRAMTemplate_163_i_io_r_resp_data_5_accessed), .io_r_resp_data_5_tagErr(vSRAMTemplate_163_i_io_r_resp_data_5_tagErr), .io_r_resp_data_5_dataErr(vSRAMTemplate_163_i_io_r_resp_data_5_dataErr), .io_r_resp_data_6_dirty(vSRAMTemplate_163_i_io_r_resp_data_6_dirty), .io_r_resp_data_6_state(vSRAMTemplate_163_i_io_r_resp_data_6_state), .io_r_resp_data_6_clients(vSRAMTemplate_163_i_io_r_resp_data_6_clients), .io_r_resp_data_6_alias(vSRAMTemplate_163_i_io_r_resp_data_6_alias), .io_r_resp_data_6_prefetch(vSRAMTemplate_163_i_io_r_resp_data_6_prefetch), .io_r_resp_data_6_prefetchSrc(vSRAMTemplate_163_i_io_r_resp_data_6_prefetchSrc), .io_r_resp_data_6_accessed(vSRAMTemplate_163_i_io_r_resp_data_6_accessed), .io_r_resp_data_6_tagErr(vSRAMTemplate_163_i_io_r_resp_data_6_tagErr), .io_r_resp_data_6_dataErr(vSRAMTemplate_163_i_io_r_resp_data_6_dataErr), .io_r_resp_data_7_dirty(vSRAMTemplate_163_i_io_r_resp_data_7_dirty), .io_r_resp_data_7_state(vSRAMTemplate_163_i_io_r_resp_data_7_state), .io_r_resp_data_7_clients(vSRAMTemplate_163_i_io_r_resp_data_7_clients), .io_r_resp_data_7_alias(vSRAMTemplate_163_i_io_r_resp_data_7_alias), .io_r_resp_data_7_prefetch(vSRAMTemplate_163_i_io_r_resp_data_7_prefetch), .io_r_resp_data_7_prefetchSrc(vSRAMTemplate_163_i_io_r_resp_data_7_prefetchSrc), .io_r_resp_data_7_accessed(vSRAMTemplate_163_i_io_r_resp_data_7_accessed), .io_r_resp_data_7_tagErr(vSRAMTemplate_163_i_io_r_resp_data_7_tagErr), .io_r_resp_data_7_dataErr(vSRAMTemplate_163_i_io_r_resp_data_7_dataErr), .io_w_req_ready(vSRAMTemplate_163_i_io_w_req_ready), .io_resetDone(vSRAMTemplate_163_i_io_resetDone), .boreChildrenBd_bore_rdata(vSRAMTemplate_163_i_boreChildrenBd_bore_rdata));
  int vSRAMTemplate_163_cov_w = 0, vSRAMTemplate_163_cov_rw_same = 0, vSRAMTemplate_163_cov_cgoff = 0, vSRAMTemplate_163_cov_bore_w = 0, vSRAMTemplate_163_cov_bore_r = 0, vSRAMTemplate_163_cov_hold = 0, vSRAMTemplate_163_cov_rd_known = 0, vSRAMTemplate_163_cov_rd_nonzero = 0, vSRAMTemplate_163_cov_m0 = 0, vSRAMTemplate_163_cov_m1 = 0, vSRAMTemplate_163_cov_mmix = 0;
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_163_io_r_req_valid <= 1'b0;
      vSRAMTemplate_163_io_w_req_valid <= 1'b0;
      vSRAMTemplate_163_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_163_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_163_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_163_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_163_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_163_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_163_io_r_req_bits_setIdx <= ($urandom_range(0,3)!=0) ? 9'($urandom_range(0,7)) : 9'($urandom);
      vSRAMTemplate_163_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_163_io_w_req_bits_setIdx <= ($urandom_range(0,3)!=0) ? 9'($urandom_range(0,7)) : 9'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_0_dirty <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_0_state <= 2'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_0_clients <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_0_alias <= 2'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_0_prefetch <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_0_prefetchSrc <= 3'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_0_accessed <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_0_tagErr <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_0_dataErr <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_1_dirty <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_1_state <= 2'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_1_clients <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_1_alias <= 2'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_1_prefetch <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_1_prefetchSrc <= 3'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_1_accessed <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_1_tagErr <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_1_dataErr <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_2_dirty <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_2_state <= 2'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_2_clients <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_2_alias <= 2'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_2_prefetch <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_2_prefetchSrc <= 3'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_2_accessed <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_2_tagErr <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_2_dataErr <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_3_dirty <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_3_state <= 2'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_3_clients <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_3_alias <= 2'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_3_prefetch <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_3_prefetchSrc <= 3'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_3_accessed <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_3_tagErr <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_3_dataErr <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_4_dirty <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_4_state <= 2'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_4_clients <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_4_alias <= 2'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_4_prefetch <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_4_prefetchSrc <= 3'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_4_accessed <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_4_tagErr <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_4_dataErr <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_5_dirty <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_5_state <= 2'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_5_clients <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_5_alias <= 2'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_5_prefetch <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_5_prefetchSrc <= 3'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_5_accessed <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_5_tagErr <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_5_dataErr <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_6_dirty <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_6_state <= 2'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_6_clients <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_6_alias <= 2'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_6_prefetch <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_6_prefetchSrc <= 3'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_6_accessed <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_6_tagErr <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_6_dataErr <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_7_dirty <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_7_state <= 2'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_7_clients <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_7_alias <= 2'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_7_prefetch <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_7_prefetchSrc <= 3'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_7_accessed <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_7_tagErr <= 1'($urandom);
      vSRAMTemplate_163_io_w_req_bits_data_7_dataErr <= 1'($urandom);
      case ($urandom_range(0,2))   // 全 0 / 全 1 / 混合 各 1/3
        0: vSRAMTemplate_163_io_w_req_bits_waymask <= 8'b0;
        1: vSRAMTemplate_163_io_w_req_bits_waymask <= {8{1'b1}};
        default: vSRAMTemplate_163_io_w_req_bits_waymask <= 8'($urandom);
      endcase
      vSRAMTemplate_163_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_163_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_163_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_163_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_163_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_163_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_163_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_163_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_163_boreChildrenBd_bore_addr <= 10'($urandom);
      vSRAMTemplate_163_boreChildrenBd_bore_addr_rd <= 10'($urandom);
      vSRAMTemplate_163_boreChildrenBd_bore_wdata <= 104'({$urandom(), $urandom(), $urandom(), $urandom()});
      vSRAMTemplate_163_boreChildrenBd_bore_wmask <= 8'($urandom);
      vSRAMTemplate_163_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_163_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_163_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_163_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_163_boreChildrenBd_bore_array <= 5'($urandom);
    end
  end
  always @(posedge clk) if (!rst && cycle > WARMUP) begin
    if (vSRAMTemplate_163_io_w_req_valid && !vSRAMTemplate_163_io_broadcast_ram_hold) vSRAMTemplate_163_cov_w++;
    if (vSRAMTemplate_163_io_w_req_valid && vSRAMTemplate_163_io_r_req_valid && vSRAMTemplate_163_io_w_req_bits_setIdx == vSRAMTemplate_163_io_r_req_bits_setIdx) vSRAMTemplate_163_cov_rw_same++;
    if (!vSRAMTemplate_163_io_w_req_valid && !vSRAMTemplate_163_io_r_req_valid && !vSRAMTemplate_163_boreChildrenBd_bore_ack) vSRAMTemplate_163_cov_cgoff++;
    if (vSRAMTemplate_163_boreChildrenBd_bore_ack && vSRAMTemplate_163_boreChildrenBd_bore_we) vSRAMTemplate_163_cov_bore_w++;
    if (vSRAMTemplate_163_boreChildrenBd_bore_ack && vSRAMTemplate_163_boreChildrenBd_bore_re) vSRAMTemplate_163_cov_bore_r++;
    if (vSRAMTemplate_163_io_broadcast_ram_hold) vSRAMTemplate_163_cov_hold++;
    if (vSRAMTemplate_163_io_w_req_valid) begin
      if (vSRAMTemplate_163_io_w_req_bits_waymask == 8'b0)      vSRAMTemplate_163_cov_m0++;
      else if (&vSRAMTemplate_163_io_w_req_bits_waymask)            vSRAMTemplate_163_cov_m1++;
      else                                  vSRAMTemplate_163_cov_mmix++;
    end
    if (!has_x({vSRAMTemplate_163_g_io_r_resp_data_0_dirty, vSRAMTemplate_163_g_io_r_resp_data_0_state, vSRAMTemplate_163_g_io_r_resp_data_0_clients, vSRAMTemplate_163_g_io_r_resp_data_0_alias, vSRAMTemplate_163_g_io_r_resp_data_0_prefetch, vSRAMTemplate_163_g_io_r_resp_data_0_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_0_accessed, vSRAMTemplate_163_g_io_r_resp_data_0_tagErr, vSRAMTemplate_163_g_io_r_resp_data_0_dataErr, vSRAMTemplate_163_g_io_r_resp_data_1_dirty, vSRAMTemplate_163_g_io_r_resp_data_1_state, vSRAMTemplate_163_g_io_r_resp_data_1_clients, vSRAMTemplate_163_g_io_r_resp_data_1_alias, vSRAMTemplate_163_g_io_r_resp_data_1_prefetch, vSRAMTemplate_163_g_io_r_resp_data_1_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_1_accessed, vSRAMTemplate_163_g_io_r_resp_data_1_tagErr, vSRAMTemplate_163_g_io_r_resp_data_1_dataErr, vSRAMTemplate_163_g_io_r_resp_data_2_dirty, vSRAMTemplate_163_g_io_r_resp_data_2_state, vSRAMTemplate_163_g_io_r_resp_data_2_clients, vSRAMTemplate_163_g_io_r_resp_data_2_alias, vSRAMTemplate_163_g_io_r_resp_data_2_prefetch, vSRAMTemplate_163_g_io_r_resp_data_2_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_2_accessed, vSRAMTemplate_163_g_io_r_resp_data_2_tagErr, vSRAMTemplate_163_g_io_r_resp_data_2_dataErr, vSRAMTemplate_163_g_io_r_resp_data_3_dirty, vSRAMTemplate_163_g_io_r_resp_data_3_state, vSRAMTemplate_163_g_io_r_resp_data_3_clients, vSRAMTemplate_163_g_io_r_resp_data_3_alias, vSRAMTemplate_163_g_io_r_resp_data_3_prefetch, vSRAMTemplate_163_g_io_r_resp_data_3_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_3_accessed, vSRAMTemplate_163_g_io_r_resp_data_3_tagErr, vSRAMTemplate_163_g_io_r_resp_data_3_dataErr, vSRAMTemplate_163_g_io_r_resp_data_4_dirty, vSRAMTemplate_163_g_io_r_resp_data_4_state, vSRAMTemplate_163_g_io_r_resp_data_4_clients, vSRAMTemplate_163_g_io_r_resp_data_4_alias, vSRAMTemplate_163_g_io_r_resp_data_4_prefetch, vSRAMTemplate_163_g_io_r_resp_data_4_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_4_accessed, vSRAMTemplate_163_g_io_r_resp_data_4_tagErr, vSRAMTemplate_163_g_io_r_resp_data_4_dataErr, vSRAMTemplate_163_g_io_r_resp_data_5_dirty, vSRAMTemplate_163_g_io_r_resp_data_5_state, vSRAMTemplate_163_g_io_r_resp_data_5_clients, vSRAMTemplate_163_g_io_r_resp_data_5_alias, vSRAMTemplate_163_g_io_r_resp_data_5_prefetch, vSRAMTemplate_163_g_io_r_resp_data_5_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_5_accessed, vSRAMTemplate_163_g_io_r_resp_data_5_tagErr, vSRAMTemplate_163_g_io_r_resp_data_5_dataErr, vSRAMTemplate_163_g_io_r_resp_data_6_dirty, vSRAMTemplate_163_g_io_r_resp_data_6_state, vSRAMTemplate_163_g_io_r_resp_data_6_clients, vSRAMTemplate_163_g_io_r_resp_data_6_alias, vSRAMTemplate_163_g_io_r_resp_data_6_prefetch, vSRAMTemplate_163_g_io_r_resp_data_6_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_6_accessed, vSRAMTemplate_163_g_io_r_resp_data_6_tagErr, vSRAMTemplate_163_g_io_r_resp_data_6_dataErr, vSRAMTemplate_163_g_io_r_resp_data_7_dirty, vSRAMTemplate_163_g_io_r_resp_data_7_state, vSRAMTemplate_163_g_io_r_resp_data_7_clients, vSRAMTemplate_163_g_io_r_resp_data_7_alias, vSRAMTemplate_163_g_io_r_resp_data_7_prefetch, vSRAMTemplate_163_g_io_r_resp_data_7_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_7_accessed, vSRAMTemplate_163_g_io_r_resp_data_7_tagErr, vSRAMTemplate_163_g_io_r_resp_data_7_dataErr}, 104) && !has_z({vSRAMTemplate_163_g_io_r_resp_data_0_dirty, vSRAMTemplate_163_g_io_r_resp_data_0_state, vSRAMTemplate_163_g_io_r_resp_data_0_clients, vSRAMTemplate_163_g_io_r_resp_data_0_alias, vSRAMTemplate_163_g_io_r_resp_data_0_prefetch, vSRAMTemplate_163_g_io_r_resp_data_0_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_0_accessed, vSRAMTemplate_163_g_io_r_resp_data_0_tagErr, vSRAMTemplate_163_g_io_r_resp_data_0_dataErr, vSRAMTemplate_163_g_io_r_resp_data_1_dirty, vSRAMTemplate_163_g_io_r_resp_data_1_state, vSRAMTemplate_163_g_io_r_resp_data_1_clients, vSRAMTemplate_163_g_io_r_resp_data_1_alias, vSRAMTemplate_163_g_io_r_resp_data_1_prefetch, vSRAMTemplate_163_g_io_r_resp_data_1_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_1_accessed, vSRAMTemplate_163_g_io_r_resp_data_1_tagErr, vSRAMTemplate_163_g_io_r_resp_data_1_dataErr, vSRAMTemplate_163_g_io_r_resp_data_2_dirty, vSRAMTemplate_163_g_io_r_resp_data_2_state, vSRAMTemplate_163_g_io_r_resp_data_2_clients, vSRAMTemplate_163_g_io_r_resp_data_2_alias, vSRAMTemplate_163_g_io_r_resp_data_2_prefetch, vSRAMTemplate_163_g_io_r_resp_data_2_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_2_accessed, vSRAMTemplate_163_g_io_r_resp_data_2_tagErr, vSRAMTemplate_163_g_io_r_resp_data_2_dataErr, vSRAMTemplate_163_g_io_r_resp_data_3_dirty, vSRAMTemplate_163_g_io_r_resp_data_3_state, vSRAMTemplate_163_g_io_r_resp_data_3_clients, vSRAMTemplate_163_g_io_r_resp_data_3_alias, vSRAMTemplate_163_g_io_r_resp_data_3_prefetch, vSRAMTemplate_163_g_io_r_resp_data_3_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_3_accessed, vSRAMTemplate_163_g_io_r_resp_data_3_tagErr, vSRAMTemplate_163_g_io_r_resp_data_3_dataErr, vSRAMTemplate_163_g_io_r_resp_data_4_dirty, vSRAMTemplate_163_g_io_r_resp_data_4_state, vSRAMTemplate_163_g_io_r_resp_data_4_clients, vSRAMTemplate_163_g_io_r_resp_data_4_alias, vSRAMTemplate_163_g_io_r_resp_data_4_prefetch, vSRAMTemplate_163_g_io_r_resp_data_4_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_4_accessed, vSRAMTemplate_163_g_io_r_resp_data_4_tagErr, vSRAMTemplate_163_g_io_r_resp_data_4_dataErr, vSRAMTemplate_163_g_io_r_resp_data_5_dirty, vSRAMTemplate_163_g_io_r_resp_data_5_state, vSRAMTemplate_163_g_io_r_resp_data_5_clients, vSRAMTemplate_163_g_io_r_resp_data_5_alias, vSRAMTemplate_163_g_io_r_resp_data_5_prefetch, vSRAMTemplate_163_g_io_r_resp_data_5_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_5_accessed, vSRAMTemplate_163_g_io_r_resp_data_5_tagErr, vSRAMTemplate_163_g_io_r_resp_data_5_dataErr, vSRAMTemplate_163_g_io_r_resp_data_6_dirty, vSRAMTemplate_163_g_io_r_resp_data_6_state, vSRAMTemplate_163_g_io_r_resp_data_6_clients, vSRAMTemplate_163_g_io_r_resp_data_6_alias, vSRAMTemplate_163_g_io_r_resp_data_6_prefetch, vSRAMTemplate_163_g_io_r_resp_data_6_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_6_accessed, vSRAMTemplate_163_g_io_r_resp_data_6_tagErr, vSRAMTemplate_163_g_io_r_resp_data_6_dataErr, vSRAMTemplate_163_g_io_r_resp_data_7_dirty, vSRAMTemplate_163_g_io_r_resp_data_7_state, vSRAMTemplate_163_g_io_r_resp_data_7_clients, vSRAMTemplate_163_g_io_r_resp_data_7_alias, vSRAMTemplate_163_g_io_r_resp_data_7_prefetch, vSRAMTemplate_163_g_io_r_resp_data_7_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_7_accessed, vSRAMTemplate_163_g_io_r_resp_data_7_tagErr, vSRAMTemplate_163_g_io_r_resp_data_7_dataErr}, 104)) begin
      vSRAMTemplate_163_cov_rd_known++;
      if (|{vSRAMTemplate_163_g_io_r_resp_data_0_dirty, vSRAMTemplate_163_g_io_r_resp_data_0_state, vSRAMTemplate_163_g_io_r_resp_data_0_clients, vSRAMTemplate_163_g_io_r_resp_data_0_alias, vSRAMTemplate_163_g_io_r_resp_data_0_prefetch, vSRAMTemplate_163_g_io_r_resp_data_0_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_0_accessed, vSRAMTemplate_163_g_io_r_resp_data_0_tagErr, vSRAMTemplate_163_g_io_r_resp_data_0_dataErr, vSRAMTemplate_163_g_io_r_resp_data_1_dirty, vSRAMTemplate_163_g_io_r_resp_data_1_state, vSRAMTemplate_163_g_io_r_resp_data_1_clients, vSRAMTemplate_163_g_io_r_resp_data_1_alias, vSRAMTemplate_163_g_io_r_resp_data_1_prefetch, vSRAMTemplate_163_g_io_r_resp_data_1_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_1_accessed, vSRAMTemplate_163_g_io_r_resp_data_1_tagErr, vSRAMTemplate_163_g_io_r_resp_data_1_dataErr, vSRAMTemplate_163_g_io_r_resp_data_2_dirty, vSRAMTemplate_163_g_io_r_resp_data_2_state, vSRAMTemplate_163_g_io_r_resp_data_2_clients, vSRAMTemplate_163_g_io_r_resp_data_2_alias, vSRAMTemplate_163_g_io_r_resp_data_2_prefetch, vSRAMTemplate_163_g_io_r_resp_data_2_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_2_accessed, vSRAMTemplate_163_g_io_r_resp_data_2_tagErr, vSRAMTemplate_163_g_io_r_resp_data_2_dataErr, vSRAMTemplate_163_g_io_r_resp_data_3_dirty, vSRAMTemplate_163_g_io_r_resp_data_3_state, vSRAMTemplate_163_g_io_r_resp_data_3_clients, vSRAMTemplate_163_g_io_r_resp_data_3_alias, vSRAMTemplate_163_g_io_r_resp_data_3_prefetch, vSRAMTemplate_163_g_io_r_resp_data_3_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_3_accessed, vSRAMTemplate_163_g_io_r_resp_data_3_tagErr, vSRAMTemplate_163_g_io_r_resp_data_3_dataErr, vSRAMTemplate_163_g_io_r_resp_data_4_dirty, vSRAMTemplate_163_g_io_r_resp_data_4_state, vSRAMTemplate_163_g_io_r_resp_data_4_clients, vSRAMTemplate_163_g_io_r_resp_data_4_alias, vSRAMTemplate_163_g_io_r_resp_data_4_prefetch, vSRAMTemplate_163_g_io_r_resp_data_4_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_4_accessed, vSRAMTemplate_163_g_io_r_resp_data_4_tagErr, vSRAMTemplate_163_g_io_r_resp_data_4_dataErr, vSRAMTemplate_163_g_io_r_resp_data_5_dirty, vSRAMTemplate_163_g_io_r_resp_data_5_state, vSRAMTemplate_163_g_io_r_resp_data_5_clients, vSRAMTemplate_163_g_io_r_resp_data_5_alias, vSRAMTemplate_163_g_io_r_resp_data_5_prefetch, vSRAMTemplate_163_g_io_r_resp_data_5_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_5_accessed, vSRAMTemplate_163_g_io_r_resp_data_5_tagErr, vSRAMTemplate_163_g_io_r_resp_data_5_dataErr, vSRAMTemplate_163_g_io_r_resp_data_6_dirty, vSRAMTemplate_163_g_io_r_resp_data_6_state, vSRAMTemplate_163_g_io_r_resp_data_6_clients, vSRAMTemplate_163_g_io_r_resp_data_6_alias, vSRAMTemplate_163_g_io_r_resp_data_6_prefetch, vSRAMTemplate_163_g_io_r_resp_data_6_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_6_accessed, vSRAMTemplate_163_g_io_r_resp_data_6_tagErr, vSRAMTemplate_163_g_io_r_resp_data_6_dataErr, vSRAMTemplate_163_g_io_r_resp_data_7_dirty, vSRAMTemplate_163_g_io_r_resp_data_7_state, vSRAMTemplate_163_g_io_r_resp_data_7_clients, vSRAMTemplate_163_g_io_r_resp_data_7_alias, vSRAMTemplate_163_g_io_r_resp_data_7_prefetch, vSRAMTemplate_163_g_io_r_resp_data_7_prefetchSrc, vSRAMTemplate_163_g_io_r_resp_data_7_accessed, vSRAMTemplate_163_g_io_r_resp_data_7_tagErr, vSRAMTemplate_163_g_io_r_resp_data_7_dataErr}) vSRAMTemplate_163_cov_rd_nonzero++;
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_163_g_io_r_req_ready !== vSRAMTemplate_163_i_io_r_req_ready) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_req_ready g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_req_ready, vSRAMTemplate_163_i_io_r_req_ready); end
    if (has_z(vSRAMTemplate_163_g_io_r_req_ready, 1) || has_z(vSRAMTemplate_163_i_io_r_req_ready, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_req_ready g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_req_ready, vSRAMTemplate_163_i_io_r_req_ready); end
    if (vSRAMTemplate_163_g_io_r_resp_data_0_dirty !== vSRAMTemplate_163_i_io_r_resp_data_0_dirty) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_0_dirty g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_dirty, vSRAMTemplate_163_i_io_r_resp_data_0_dirty); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_0_dirty, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_0_dirty, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_0_dirty g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_dirty, vSRAMTemplate_163_i_io_r_resp_data_0_dirty); end
    if (vSRAMTemplate_163_g_io_r_resp_data_0_state !== vSRAMTemplate_163_i_io_r_resp_data_0_state) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_0_state g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_state, vSRAMTemplate_163_i_io_r_resp_data_0_state); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_0_state, 2) || has_z(vSRAMTemplate_163_i_io_r_resp_data_0_state, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_0_state g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_state, vSRAMTemplate_163_i_io_r_resp_data_0_state); end
    if (vSRAMTemplate_163_g_io_r_resp_data_0_clients !== vSRAMTemplate_163_i_io_r_resp_data_0_clients) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_0_clients g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_clients, vSRAMTemplate_163_i_io_r_resp_data_0_clients); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_0_clients, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_0_clients, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_0_clients g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_clients, vSRAMTemplate_163_i_io_r_resp_data_0_clients); end
    if (vSRAMTemplate_163_g_io_r_resp_data_0_alias !== vSRAMTemplate_163_i_io_r_resp_data_0_alias) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_0_alias g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_alias, vSRAMTemplate_163_i_io_r_resp_data_0_alias); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_0_alias, 2) || has_z(vSRAMTemplate_163_i_io_r_resp_data_0_alias, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_0_alias g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_alias, vSRAMTemplate_163_i_io_r_resp_data_0_alias); end
    if (vSRAMTemplate_163_g_io_r_resp_data_0_prefetch !== vSRAMTemplate_163_i_io_r_resp_data_0_prefetch) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_0_prefetch g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_prefetch, vSRAMTemplate_163_i_io_r_resp_data_0_prefetch); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_0_prefetch, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_0_prefetch, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_0_prefetch g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_prefetch, vSRAMTemplate_163_i_io_r_resp_data_0_prefetch); end
    if (vSRAMTemplate_163_g_io_r_resp_data_0_prefetchSrc !== vSRAMTemplate_163_i_io_r_resp_data_0_prefetchSrc) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_0_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_prefetchSrc, vSRAMTemplate_163_i_io_r_resp_data_0_prefetchSrc); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_0_prefetchSrc, 3) || has_z(vSRAMTemplate_163_i_io_r_resp_data_0_prefetchSrc, 3)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_0_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_prefetchSrc, vSRAMTemplate_163_i_io_r_resp_data_0_prefetchSrc); end
    if (vSRAMTemplate_163_g_io_r_resp_data_0_accessed !== vSRAMTemplate_163_i_io_r_resp_data_0_accessed) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_0_accessed g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_accessed, vSRAMTemplate_163_i_io_r_resp_data_0_accessed); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_0_accessed, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_0_accessed, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_0_accessed g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_accessed, vSRAMTemplate_163_i_io_r_resp_data_0_accessed); end
    if (vSRAMTemplate_163_g_io_r_resp_data_0_tagErr !== vSRAMTemplate_163_i_io_r_resp_data_0_tagErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_0_tagErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_tagErr, vSRAMTemplate_163_i_io_r_resp_data_0_tagErr); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_0_tagErr, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_0_tagErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_0_tagErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_tagErr, vSRAMTemplate_163_i_io_r_resp_data_0_tagErr); end
    if (vSRAMTemplate_163_g_io_r_resp_data_0_dataErr !== vSRAMTemplate_163_i_io_r_resp_data_0_dataErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_0_dataErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_dataErr, vSRAMTemplate_163_i_io_r_resp_data_0_dataErr); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_0_dataErr, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_0_dataErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_0_dataErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_0_dataErr, vSRAMTemplate_163_i_io_r_resp_data_0_dataErr); end
    if (vSRAMTemplate_163_g_io_r_resp_data_1_dirty !== vSRAMTemplate_163_i_io_r_resp_data_1_dirty) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_1_dirty g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_dirty, vSRAMTemplate_163_i_io_r_resp_data_1_dirty); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_1_dirty, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_1_dirty, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_1_dirty g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_dirty, vSRAMTemplate_163_i_io_r_resp_data_1_dirty); end
    if (vSRAMTemplate_163_g_io_r_resp_data_1_state !== vSRAMTemplate_163_i_io_r_resp_data_1_state) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_1_state g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_state, vSRAMTemplate_163_i_io_r_resp_data_1_state); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_1_state, 2) || has_z(vSRAMTemplate_163_i_io_r_resp_data_1_state, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_1_state g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_state, vSRAMTemplate_163_i_io_r_resp_data_1_state); end
    if (vSRAMTemplate_163_g_io_r_resp_data_1_clients !== vSRAMTemplate_163_i_io_r_resp_data_1_clients) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_1_clients g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_clients, vSRAMTemplate_163_i_io_r_resp_data_1_clients); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_1_clients, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_1_clients, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_1_clients g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_clients, vSRAMTemplate_163_i_io_r_resp_data_1_clients); end
    if (vSRAMTemplate_163_g_io_r_resp_data_1_alias !== vSRAMTemplate_163_i_io_r_resp_data_1_alias) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_1_alias g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_alias, vSRAMTemplate_163_i_io_r_resp_data_1_alias); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_1_alias, 2) || has_z(vSRAMTemplate_163_i_io_r_resp_data_1_alias, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_1_alias g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_alias, vSRAMTemplate_163_i_io_r_resp_data_1_alias); end
    if (vSRAMTemplate_163_g_io_r_resp_data_1_prefetch !== vSRAMTemplate_163_i_io_r_resp_data_1_prefetch) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_1_prefetch g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_prefetch, vSRAMTemplate_163_i_io_r_resp_data_1_prefetch); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_1_prefetch, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_1_prefetch, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_1_prefetch g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_prefetch, vSRAMTemplate_163_i_io_r_resp_data_1_prefetch); end
    if (vSRAMTemplate_163_g_io_r_resp_data_1_prefetchSrc !== vSRAMTemplate_163_i_io_r_resp_data_1_prefetchSrc) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_1_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_prefetchSrc, vSRAMTemplate_163_i_io_r_resp_data_1_prefetchSrc); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_1_prefetchSrc, 3) || has_z(vSRAMTemplate_163_i_io_r_resp_data_1_prefetchSrc, 3)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_1_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_prefetchSrc, vSRAMTemplate_163_i_io_r_resp_data_1_prefetchSrc); end
    if (vSRAMTemplate_163_g_io_r_resp_data_1_accessed !== vSRAMTemplate_163_i_io_r_resp_data_1_accessed) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_1_accessed g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_accessed, vSRAMTemplate_163_i_io_r_resp_data_1_accessed); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_1_accessed, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_1_accessed, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_1_accessed g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_accessed, vSRAMTemplate_163_i_io_r_resp_data_1_accessed); end
    if (vSRAMTemplate_163_g_io_r_resp_data_1_tagErr !== vSRAMTemplate_163_i_io_r_resp_data_1_tagErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_1_tagErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_tagErr, vSRAMTemplate_163_i_io_r_resp_data_1_tagErr); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_1_tagErr, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_1_tagErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_1_tagErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_tagErr, vSRAMTemplate_163_i_io_r_resp_data_1_tagErr); end
    if (vSRAMTemplate_163_g_io_r_resp_data_1_dataErr !== vSRAMTemplate_163_i_io_r_resp_data_1_dataErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_1_dataErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_dataErr, vSRAMTemplate_163_i_io_r_resp_data_1_dataErr); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_1_dataErr, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_1_dataErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_1_dataErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_1_dataErr, vSRAMTemplate_163_i_io_r_resp_data_1_dataErr); end
    if (vSRAMTemplate_163_g_io_r_resp_data_2_dirty !== vSRAMTemplate_163_i_io_r_resp_data_2_dirty) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_2_dirty g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_dirty, vSRAMTemplate_163_i_io_r_resp_data_2_dirty); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_2_dirty, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_2_dirty, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_2_dirty g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_dirty, vSRAMTemplate_163_i_io_r_resp_data_2_dirty); end
    if (vSRAMTemplate_163_g_io_r_resp_data_2_state !== vSRAMTemplate_163_i_io_r_resp_data_2_state) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_2_state g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_state, vSRAMTemplate_163_i_io_r_resp_data_2_state); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_2_state, 2) || has_z(vSRAMTemplate_163_i_io_r_resp_data_2_state, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_2_state g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_state, vSRAMTemplate_163_i_io_r_resp_data_2_state); end
    if (vSRAMTemplate_163_g_io_r_resp_data_2_clients !== vSRAMTemplate_163_i_io_r_resp_data_2_clients) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_2_clients g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_clients, vSRAMTemplate_163_i_io_r_resp_data_2_clients); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_2_clients, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_2_clients, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_2_clients g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_clients, vSRAMTemplate_163_i_io_r_resp_data_2_clients); end
    if (vSRAMTemplate_163_g_io_r_resp_data_2_alias !== vSRAMTemplate_163_i_io_r_resp_data_2_alias) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_2_alias g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_alias, vSRAMTemplate_163_i_io_r_resp_data_2_alias); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_2_alias, 2) || has_z(vSRAMTemplate_163_i_io_r_resp_data_2_alias, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_2_alias g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_alias, vSRAMTemplate_163_i_io_r_resp_data_2_alias); end
    if (vSRAMTemplate_163_g_io_r_resp_data_2_prefetch !== vSRAMTemplate_163_i_io_r_resp_data_2_prefetch) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_2_prefetch g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_prefetch, vSRAMTemplate_163_i_io_r_resp_data_2_prefetch); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_2_prefetch, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_2_prefetch, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_2_prefetch g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_prefetch, vSRAMTemplate_163_i_io_r_resp_data_2_prefetch); end
    if (vSRAMTemplate_163_g_io_r_resp_data_2_prefetchSrc !== vSRAMTemplate_163_i_io_r_resp_data_2_prefetchSrc) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_2_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_prefetchSrc, vSRAMTemplate_163_i_io_r_resp_data_2_prefetchSrc); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_2_prefetchSrc, 3) || has_z(vSRAMTemplate_163_i_io_r_resp_data_2_prefetchSrc, 3)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_2_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_prefetchSrc, vSRAMTemplate_163_i_io_r_resp_data_2_prefetchSrc); end
    if (vSRAMTemplate_163_g_io_r_resp_data_2_accessed !== vSRAMTemplate_163_i_io_r_resp_data_2_accessed) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_2_accessed g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_accessed, vSRAMTemplate_163_i_io_r_resp_data_2_accessed); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_2_accessed, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_2_accessed, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_2_accessed g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_accessed, vSRAMTemplate_163_i_io_r_resp_data_2_accessed); end
    if (vSRAMTemplate_163_g_io_r_resp_data_2_tagErr !== vSRAMTemplate_163_i_io_r_resp_data_2_tagErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_2_tagErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_tagErr, vSRAMTemplate_163_i_io_r_resp_data_2_tagErr); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_2_tagErr, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_2_tagErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_2_tagErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_tagErr, vSRAMTemplate_163_i_io_r_resp_data_2_tagErr); end
    if (vSRAMTemplate_163_g_io_r_resp_data_2_dataErr !== vSRAMTemplate_163_i_io_r_resp_data_2_dataErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_2_dataErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_dataErr, vSRAMTemplate_163_i_io_r_resp_data_2_dataErr); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_2_dataErr, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_2_dataErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_2_dataErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_2_dataErr, vSRAMTemplate_163_i_io_r_resp_data_2_dataErr); end
    if (vSRAMTemplate_163_g_io_r_resp_data_3_dirty !== vSRAMTemplate_163_i_io_r_resp_data_3_dirty) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_3_dirty g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_dirty, vSRAMTemplate_163_i_io_r_resp_data_3_dirty); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_3_dirty, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_3_dirty, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_3_dirty g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_dirty, vSRAMTemplate_163_i_io_r_resp_data_3_dirty); end
    if (vSRAMTemplate_163_g_io_r_resp_data_3_state !== vSRAMTemplate_163_i_io_r_resp_data_3_state) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_3_state g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_state, vSRAMTemplate_163_i_io_r_resp_data_3_state); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_3_state, 2) || has_z(vSRAMTemplate_163_i_io_r_resp_data_3_state, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_3_state g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_state, vSRAMTemplate_163_i_io_r_resp_data_3_state); end
    if (vSRAMTemplate_163_g_io_r_resp_data_3_clients !== vSRAMTemplate_163_i_io_r_resp_data_3_clients) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_3_clients g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_clients, vSRAMTemplate_163_i_io_r_resp_data_3_clients); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_3_clients, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_3_clients, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_3_clients g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_clients, vSRAMTemplate_163_i_io_r_resp_data_3_clients); end
    if (vSRAMTemplate_163_g_io_r_resp_data_3_alias !== vSRAMTemplate_163_i_io_r_resp_data_3_alias) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_3_alias g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_alias, vSRAMTemplate_163_i_io_r_resp_data_3_alias); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_3_alias, 2) || has_z(vSRAMTemplate_163_i_io_r_resp_data_3_alias, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_3_alias g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_alias, vSRAMTemplate_163_i_io_r_resp_data_3_alias); end
    if (vSRAMTemplate_163_g_io_r_resp_data_3_prefetch !== vSRAMTemplate_163_i_io_r_resp_data_3_prefetch) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_3_prefetch g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_prefetch, vSRAMTemplate_163_i_io_r_resp_data_3_prefetch); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_3_prefetch, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_3_prefetch, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_3_prefetch g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_prefetch, vSRAMTemplate_163_i_io_r_resp_data_3_prefetch); end
    if (vSRAMTemplate_163_g_io_r_resp_data_3_prefetchSrc !== vSRAMTemplate_163_i_io_r_resp_data_3_prefetchSrc) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_3_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_prefetchSrc, vSRAMTemplate_163_i_io_r_resp_data_3_prefetchSrc); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_3_prefetchSrc, 3) || has_z(vSRAMTemplate_163_i_io_r_resp_data_3_prefetchSrc, 3)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_3_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_prefetchSrc, vSRAMTemplate_163_i_io_r_resp_data_3_prefetchSrc); end
    if (vSRAMTemplate_163_g_io_r_resp_data_3_accessed !== vSRAMTemplate_163_i_io_r_resp_data_3_accessed) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_3_accessed g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_accessed, vSRAMTemplate_163_i_io_r_resp_data_3_accessed); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_3_accessed, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_3_accessed, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_3_accessed g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_accessed, vSRAMTemplate_163_i_io_r_resp_data_3_accessed); end
    if (vSRAMTemplate_163_g_io_r_resp_data_3_tagErr !== vSRAMTemplate_163_i_io_r_resp_data_3_tagErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_3_tagErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_tagErr, vSRAMTemplate_163_i_io_r_resp_data_3_tagErr); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_3_tagErr, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_3_tagErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_3_tagErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_tagErr, vSRAMTemplate_163_i_io_r_resp_data_3_tagErr); end
    if (vSRAMTemplate_163_g_io_r_resp_data_3_dataErr !== vSRAMTemplate_163_i_io_r_resp_data_3_dataErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_3_dataErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_dataErr, vSRAMTemplate_163_i_io_r_resp_data_3_dataErr); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_3_dataErr, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_3_dataErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_3_dataErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_3_dataErr, vSRAMTemplate_163_i_io_r_resp_data_3_dataErr); end
    if (vSRAMTemplate_163_g_io_r_resp_data_4_dirty !== vSRAMTemplate_163_i_io_r_resp_data_4_dirty) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_4_dirty g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_dirty, vSRAMTemplate_163_i_io_r_resp_data_4_dirty); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_4_dirty, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_4_dirty, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_4_dirty g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_dirty, vSRAMTemplate_163_i_io_r_resp_data_4_dirty); end
    if (vSRAMTemplate_163_g_io_r_resp_data_4_state !== vSRAMTemplate_163_i_io_r_resp_data_4_state) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_4_state g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_state, vSRAMTemplate_163_i_io_r_resp_data_4_state); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_4_state, 2) || has_z(vSRAMTemplate_163_i_io_r_resp_data_4_state, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_4_state g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_state, vSRAMTemplate_163_i_io_r_resp_data_4_state); end
    if (vSRAMTemplate_163_g_io_r_resp_data_4_clients !== vSRAMTemplate_163_i_io_r_resp_data_4_clients) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_4_clients g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_clients, vSRAMTemplate_163_i_io_r_resp_data_4_clients); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_4_clients, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_4_clients, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_4_clients g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_clients, vSRAMTemplate_163_i_io_r_resp_data_4_clients); end
    if (vSRAMTemplate_163_g_io_r_resp_data_4_alias !== vSRAMTemplate_163_i_io_r_resp_data_4_alias) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_4_alias g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_alias, vSRAMTemplate_163_i_io_r_resp_data_4_alias); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_4_alias, 2) || has_z(vSRAMTemplate_163_i_io_r_resp_data_4_alias, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_4_alias g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_alias, vSRAMTemplate_163_i_io_r_resp_data_4_alias); end
    if (vSRAMTemplate_163_g_io_r_resp_data_4_prefetch !== vSRAMTemplate_163_i_io_r_resp_data_4_prefetch) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_4_prefetch g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_prefetch, vSRAMTemplate_163_i_io_r_resp_data_4_prefetch); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_4_prefetch, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_4_prefetch, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_4_prefetch g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_prefetch, vSRAMTemplate_163_i_io_r_resp_data_4_prefetch); end
    if (vSRAMTemplate_163_g_io_r_resp_data_4_prefetchSrc !== vSRAMTemplate_163_i_io_r_resp_data_4_prefetchSrc) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_4_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_prefetchSrc, vSRAMTemplate_163_i_io_r_resp_data_4_prefetchSrc); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_4_prefetchSrc, 3) || has_z(vSRAMTemplate_163_i_io_r_resp_data_4_prefetchSrc, 3)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_4_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_prefetchSrc, vSRAMTemplate_163_i_io_r_resp_data_4_prefetchSrc); end
    if (vSRAMTemplate_163_g_io_r_resp_data_4_accessed !== vSRAMTemplate_163_i_io_r_resp_data_4_accessed) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_4_accessed g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_accessed, vSRAMTemplate_163_i_io_r_resp_data_4_accessed); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_4_accessed, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_4_accessed, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_4_accessed g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_accessed, vSRAMTemplate_163_i_io_r_resp_data_4_accessed); end
    if (vSRAMTemplate_163_g_io_r_resp_data_4_tagErr !== vSRAMTemplate_163_i_io_r_resp_data_4_tagErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_4_tagErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_tagErr, vSRAMTemplate_163_i_io_r_resp_data_4_tagErr); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_4_tagErr, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_4_tagErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_4_tagErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_tagErr, vSRAMTemplate_163_i_io_r_resp_data_4_tagErr); end
    if (vSRAMTemplate_163_g_io_r_resp_data_4_dataErr !== vSRAMTemplate_163_i_io_r_resp_data_4_dataErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_4_dataErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_dataErr, vSRAMTemplate_163_i_io_r_resp_data_4_dataErr); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_4_dataErr, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_4_dataErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_4_dataErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_4_dataErr, vSRAMTemplate_163_i_io_r_resp_data_4_dataErr); end
    if (vSRAMTemplate_163_g_io_r_resp_data_5_dirty !== vSRAMTemplate_163_i_io_r_resp_data_5_dirty) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_5_dirty g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_dirty, vSRAMTemplate_163_i_io_r_resp_data_5_dirty); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_5_dirty, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_5_dirty, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_5_dirty g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_dirty, vSRAMTemplate_163_i_io_r_resp_data_5_dirty); end
    if (vSRAMTemplate_163_g_io_r_resp_data_5_state !== vSRAMTemplate_163_i_io_r_resp_data_5_state) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_5_state g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_state, vSRAMTemplate_163_i_io_r_resp_data_5_state); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_5_state, 2) || has_z(vSRAMTemplate_163_i_io_r_resp_data_5_state, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_5_state g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_state, vSRAMTemplate_163_i_io_r_resp_data_5_state); end
    if (vSRAMTemplate_163_g_io_r_resp_data_5_clients !== vSRAMTemplate_163_i_io_r_resp_data_5_clients) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_5_clients g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_clients, vSRAMTemplate_163_i_io_r_resp_data_5_clients); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_5_clients, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_5_clients, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_5_clients g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_clients, vSRAMTemplate_163_i_io_r_resp_data_5_clients); end
    if (vSRAMTemplate_163_g_io_r_resp_data_5_alias !== vSRAMTemplate_163_i_io_r_resp_data_5_alias) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_5_alias g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_alias, vSRAMTemplate_163_i_io_r_resp_data_5_alias); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_5_alias, 2) || has_z(vSRAMTemplate_163_i_io_r_resp_data_5_alias, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_5_alias g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_alias, vSRAMTemplate_163_i_io_r_resp_data_5_alias); end
    if (vSRAMTemplate_163_g_io_r_resp_data_5_prefetch !== vSRAMTemplate_163_i_io_r_resp_data_5_prefetch) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_5_prefetch g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_prefetch, vSRAMTemplate_163_i_io_r_resp_data_5_prefetch); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_5_prefetch, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_5_prefetch, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_5_prefetch g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_prefetch, vSRAMTemplate_163_i_io_r_resp_data_5_prefetch); end
    if (vSRAMTemplate_163_g_io_r_resp_data_5_prefetchSrc !== vSRAMTemplate_163_i_io_r_resp_data_5_prefetchSrc) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_5_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_prefetchSrc, vSRAMTemplate_163_i_io_r_resp_data_5_prefetchSrc); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_5_prefetchSrc, 3) || has_z(vSRAMTemplate_163_i_io_r_resp_data_5_prefetchSrc, 3)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_5_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_prefetchSrc, vSRAMTemplate_163_i_io_r_resp_data_5_prefetchSrc); end
    if (vSRAMTemplate_163_g_io_r_resp_data_5_accessed !== vSRAMTemplate_163_i_io_r_resp_data_5_accessed) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_5_accessed g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_accessed, vSRAMTemplate_163_i_io_r_resp_data_5_accessed); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_5_accessed, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_5_accessed, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_5_accessed g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_accessed, vSRAMTemplate_163_i_io_r_resp_data_5_accessed); end
    if (vSRAMTemplate_163_g_io_r_resp_data_5_tagErr !== vSRAMTemplate_163_i_io_r_resp_data_5_tagErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_5_tagErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_tagErr, vSRAMTemplate_163_i_io_r_resp_data_5_tagErr); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_5_tagErr, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_5_tagErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_5_tagErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_tagErr, vSRAMTemplate_163_i_io_r_resp_data_5_tagErr); end
    if (vSRAMTemplate_163_g_io_r_resp_data_5_dataErr !== vSRAMTemplate_163_i_io_r_resp_data_5_dataErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_5_dataErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_dataErr, vSRAMTemplate_163_i_io_r_resp_data_5_dataErr); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_5_dataErr, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_5_dataErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_5_dataErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_5_dataErr, vSRAMTemplate_163_i_io_r_resp_data_5_dataErr); end
    if (vSRAMTemplate_163_g_io_r_resp_data_6_dirty !== vSRAMTemplate_163_i_io_r_resp_data_6_dirty) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_6_dirty g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_dirty, vSRAMTemplate_163_i_io_r_resp_data_6_dirty); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_6_dirty, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_6_dirty, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_6_dirty g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_dirty, vSRAMTemplate_163_i_io_r_resp_data_6_dirty); end
    if (vSRAMTemplate_163_g_io_r_resp_data_6_state !== vSRAMTemplate_163_i_io_r_resp_data_6_state) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_6_state g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_state, vSRAMTemplate_163_i_io_r_resp_data_6_state); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_6_state, 2) || has_z(vSRAMTemplate_163_i_io_r_resp_data_6_state, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_6_state g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_state, vSRAMTemplate_163_i_io_r_resp_data_6_state); end
    if (vSRAMTemplate_163_g_io_r_resp_data_6_clients !== vSRAMTemplate_163_i_io_r_resp_data_6_clients) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_6_clients g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_clients, vSRAMTemplate_163_i_io_r_resp_data_6_clients); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_6_clients, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_6_clients, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_6_clients g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_clients, vSRAMTemplate_163_i_io_r_resp_data_6_clients); end
    if (vSRAMTemplate_163_g_io_r_resp_data_6_alias !== vSRAMTemplate_163_i_io_r_resp_data_6_alias) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_6_alias g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_alias, vSRAMTemplate_163_i_io_r_resp_data_6_alias); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_6_alias, 2) || has_z(vSRAMTemplate_163_i_io_r_resp_data_6_alias, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_6_alias g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_alias, vSRAMTemplate_163_i_io_r_resp_data_6_alias); end
    if (vSRAMTemplate_163_g_io_r_resp_data_6_prefetch !== vSRAMTemplate_163_i_io_r_resp_data_6_prefetch) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_6_prefetch g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_prefetch, vSRAMTemplate_163_i_io_r_resp_data_6_prefetch); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_6_prefetch, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_6_prefetch, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_6_prefetch g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_prefetch, vSRAMTemplate_163_i_io_r_resp_data_6_prefetch); end
    if (vSRAMTemplate_163_g_io_r_resp_data_6_prefetchSrc !== vSRAMTemplate_163_i_io_r_resp_data_6_prefetchSrc) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_6_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_prefetchSrc, vSRAMTemplate_163_i_io_r_resp_data_6_prefetchSrc); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_6_prefetchSrc, 3) || has_z(vSRAMTemplate_163_i_io_r_resp_data_6_prefetchSrc, 3)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_6_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_prefetchSrc, vSRAMTemplate_163_i_io_r_resp_data_6_prefetchSrc); end
    if (vSRAMTemplate_163_g_io_r_resp_data_6_accessed !== vSRAMTemplate_163_i_io_r_resp_data_6_accessed) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_6_accessed g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_accessed, vSRAMTemplate_163_i_io_r_resp_data_6_accessed); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_6_accessed, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_6_accessed, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_6_accessed g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_accessed, vSRAMTemplate_163_i_io_r_resp_data_6_accessed); end
    if (vSRAMTemplate_163_g_io_r_resp_data_6_tagErr !== vSRAMTemplate_163_i_io_r_resp_data_6_tagErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_6_tagErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_tagErr, vSRAMTemplate_163_i_io_r_resp_data_6_tagErr); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_6_tagErr, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_6_tagErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_6_tagErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_tagErr, vSRAMTemplate_163_i_io_r_resp_data_6_tagErr); end
    if (vSRAMTemplate_163_g_io_r_resp_data_6_dataErr !== vSRAMTemplate_163_i_io_r_resp_data_6_dataErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_6_dataErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_dataErr, vSRAMTemplate_163_i_io_r_resp_data_6_dataErr); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_6_dataErr, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_6_dataErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_6_dataErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_6_dataErr, vSRAMTemplate_163_i_io_r_resp_data_6_dataErr); end
    if (vSRAMTemplate_163_g_io_r_resp_data_7_dirty !== vSRAMTemplate_163_i_io_r_resp_data_7_dirty) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_7_dirty g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_dirty, vSRAMTemplate_163_i_io_r_resp_data_7_dirty); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_7_dirty, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_7_dirty, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_7_dirty g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_dirty, vSRAMTemplate_163_i_io_r_resp_data_7_dirty); end
    if (vSRAMTemplate_163_g_io_r_resp_data_7_state !== vSRAMTemplate_163_i_io_r_resp_data_7_state) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_7_state g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_state, vSRAMTemplate_163_i_io_r_resp_data_7_state); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_7_state, 2) || has_z(vSRAMTemplate_163_i_io_r_resp_data_7_state, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_7_state g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_state, vSRAMTemplate_163_i_io_r_resp_data_7_state); end
    if (vSRAMTemplate_163_g_io_r_resp_data_7_clients !== vSRAMTemplate_163_i_io_r_resp_data_7_clients) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_7_clients g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_clients, vSRAMTemplate_163_i_io_r_resp_data_7_clients); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_7_clients, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_7_clients, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_7_clients g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_clients, vSRAMTemplate_163_i_io_r_resp_data_7_clients); end
    if (vSRAMTemplate_163_g_io_r_resp_data_7_alias !== vSRAMTemplate_163_i_io_r_resp_data_7_alias) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_7_alias g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_alias, vSRAMTemplate_163_i_io_r_resp_data_7_alias); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_7_alias, 2) || has_z(vSRAMTemplate_163_i_io_r_resp_data_7_alias, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_7_alias g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_alias, vSRAMTemplate_163_i_io_r_resp_data_7_alias); end
    if (vSRAMTemplate_163_g_io_r_resp_data_7_prefetch !== vSRAMTemplate_163_i_io_r_resp_data_7_prefetch) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_7_prefetch g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_prefetch, vSRAMTemplate_163_i_io_r_resp_data_7_prefetch); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_7_prefetch, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_7_prefetch, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_7_prefetch g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_prefetch, vSRAMTemplate_163_i_io_r_resp_data_7_prefetch); end
    if (vSRAMTemplate_163_g_io_r_resp_data_7_prefetchSrc !== vSRAMTemplate_163_i_io_r_resp_data_7_prefetchSrc) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_7_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_prefetchSrc, vSRAMTemplate_163_i_io_r_resp_data_7_prefetchSrc); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_7_prefetchSrc, 3) || has_z(vSRAMTemplate_163_i_io_r_resp_data_7_prefetchSrc, 3)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_7_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_prefetchSrc, vSRAMTemplate_163_i_io_r_resp_data_7_prefetchSrc); end
    if (vSRAMTemplate_163_g_io_r_resp_data_7_accessed !== vSRAMTemplate_163_i_io_r_resp_data_7_accessed) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_7_accessed g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_accessed, vSRAMTemplate_163_i_io_r_resp_data_7_accessed); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_7_accessed, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_7_accessed, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_7_accessed g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_accessed, vSRAMTemplate_163_i_io_r_resp_data_7_accessed); end
    if (vSRAMTemplate_163_g_io_r_resp_data_7_tagErr !== vSRAMTemplate_163_i_io_r_resp_data_7_tagErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_7_tagErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_tagErr, vSRAMTemplate_163_i_io_r_resp_data_7_tagErr); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_7_tagErr, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_7_tagErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_7_tagErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_tagErr, vSRAMTemplate_163_i_io_r_resp_data_7_tagErr); end
    if (vSRAMTemplate_163_g_io_r_resp_data_7_dataErr !== vSRAMTemplate_163_i_io_r_resp_data_7_dataErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_r_resp_data_7_dataErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_dataErr, vSRAMTemplate_163_i_io_r_resp_data_7_dataErr); end
    if (has_z(vSRAMTemplate_163_g_io_r_resp_data_7_dataErr, 1) || has_z(vSRAMTemplate_163_i_io_r_resp_data_7_dataErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_r_resp_data_7_dataErr g=%h i=%h", $time, vSRAMTemplate_163_g_io_r_resp_data_7_dataErr, vSRAMTemplate_163_i_io_r_resp_data_7_dataErr); end
    if (vSRAMTemplate_163_g_io_w_req_ready !== vSRAMTemplate_163_i_io_w_req_ready) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_w_req_ready g=%h i=%h", $time, vSRAMTemplate_163_g_io_w_req_ready, vSRAMTemplate_163_i_io_w_req_ready); end
    if (has_z(vSRAMTemplate_163_g_io_w_req_ready, 1) || has_z(vSRAMTemplate_163_i_io_w_req_ready, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_w_req_ready g=%h i=%h", $time, vSRAMTemplate_163_g_io_w_req_ready, vSRAMTemplate_163_i_io_w_req_ready); end
    if (vSRAMTemplate_163_g_io_resetDone !== vSRAMTemplate_163_i_io_resetDone) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.io_resetDone g=%h i=%h", $time, vSRAMTemplate_163_g_io_resetDone, vSRAMTemplate_163_i_io_resetDone); end
    if (has_z(vSRAMTemplate_163_g_io_resetDone, 1) || has_z(vSRAMTemplate_163_i_io_resetDone, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.io_resetDone g=%h i=%h", $time, vSRAMTemplate_163_g_io_resetDone, vSRAMTemplate_163_i_io_resetDone); end
    if (vSRAMTemplate_163_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_163_i_boreChildrenBd_bore_rdata) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_163.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_163_g_boreChildrenBd_bore_rdata, vSRAMTemplate_163_i_boreChildrenBd_bore_rdata); end
    if (has_z(vSRAMTemplate_163_g_boreChildrenBd_bore_rdata, 104) || has_z(vSRAMTemplate_163_i_boreChildrenBd_bore_rdata, 104)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_163.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_163_g_boreChildrenBd_bore_rdata, vSRAMTemplate_163_i_boreChildrenBd_bore_rdata); end
  end

  // ================= SRAMTemplate_166 =================
  logic vSRAMTemplate_166_io_r_req_valid;
  logic [11:0] vSRAMTemplate_166_io_r_req_bits_setIdx;
  logic vSRAMTemplate_166_io_w_req_valid;
  logic [11:0] vSRAMTemplate_166_io_w_req_bits_setIdx;
  logic [136:0] vSRAMTemplate_166_io_w_req_bits_data_0;
  logic vSRAMTemplate_166_io_broadcast_ram_hold;
  logic vSRAMTemplate_166_io_broadcast_ram_bypass;
  logic vSRAMTemplate_166_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_166_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_166_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_166_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_166_io_broadcast_ram_ctl;
  logic vSRAMTemplate_166_io_broadcast_cgen;
  logic [12:0] vSRAMTemplate_166_boreChildrenBd_bore_addr;
  logic [12:0] vSRAMTemplate_166_boreChildrenBd_bore_addr_rd;
  logic [136:0] vSRAMTemplate_166_boreChildrenBd_bore_wdata;
  logic vSRAMTemplate_166_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_166_boreChildrenBd_bore_re;
  logic vSRAMTemplate_166_boreChildrenBd_bore_we;
  logic vSRAMTemplate_166_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_166_boreChildrenBd_bore_selectedOH;
  logic [4:0] vSRAMTemplate_166_boreChildrenBd_bore_array;
  wire [136:0] vSRAMTemplate_166_g_io_r_resp_data_0;
  wire [136:0] vSRAMTemplate_166_i_io_r_resp_data_0;
  wire vSRAMTemplate_166_g_io_mbistCgCtl_en;
  wire vSRAMTemplate_166_i_io_mbistCgCtl_en;
  wire vSRAMTemplate_166_g_io_mbistCgCtl_rckEn;
  wire vSRAMTemplate_166_i_io_mbistCgCtl_rckEn;
  wire vSRAMTemplate_166_g_io_mbistCgCtl_wckEn;
  wire vSRAMTemplate_166_i_io_mbistCgCtl_wckEn;
  wire [136:0] vSRAMTemplate_166_g_boreChildrenBd_bore_rdata;
  wire [136:0] vSRAMTemplate_166_i_boreChildrenBd_bore_rdata;
  logic vSRAMTemplate_166_g_lat, vSRAMTemplate_166_i_lat;
  wire  vSRAMTemplate_166_g_rclk = clk & vSRAMTemplate_166_g_lat;
  wire  vSRAMTemplate_166_i_rclk = clk & vSRAMTemplate_166_i_lat;
  always @(*) if (!clk) begin
    vSRAMTemplate_166_g_lat = vSRAMTemplate_166_g_io_mbistCgCtl_rckEn | vSRAMTemplate_166_g_io_mbistCgCtl_wckEn;
    vSRAMTemplate_166_i_lat = vSRAMTemplate_166_i_io_mbistCgCtl_rckEn | vSRAMTemplate_166_i_io_mbistCgCtl_wckEn;
  end
  SRAMTemplate_166    u_g_SRAMTemplate_166 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_166_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_166_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_166_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_166_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_166_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_166_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_166_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_166_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_166_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_166_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_166_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_166_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_166_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_166_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_166_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_166_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_166_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_166_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_166_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_166_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_166_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_166_boreChildrenBd_bore_array), .io_mbistCgCtl_rclk(vSRAMTemplate_166_g_rclk), .io_r_resp_data_0(vSRAMTemplate_166_g_io_r_resp_data_0), .io_mbistCgCtl_en(vSRAMTemplate_166_g_io_mbistCgCtl_en), .io_mbistCgCtl_rckEn(vSRAMTemplate_166_g_io_mbistCgCtl_rckEn), .io_mbistCgCtl_wckEn(vSRAMTemplate_166_g_io_mbistCgCtl_wckEn), .boreChildrenBd_bore_rdata(vSRAMTemplate_166_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_166_xs u_i_SRAMTemplate_166 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_166_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_166_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_166_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_166_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_166_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_166_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_166_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_166_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_166_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_166_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_166_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_166_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_166_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_166_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_166_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_166_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_166_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_166_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_166_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_166_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_166_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_166_boreChildrenBd_bore_array), .io_mbistCgCtl_rclk(vSRAMTemplate_166_i_rclk), .io_r_resp_data_0(vSRAMTemplate_166_i_io_r_resp_data_0), .io_mbistCgCtl_en(vSRAMTemplate_166_i_io_mbistCgCtl_en), .io_mbistCgCtl_rckEn(vSRAMTemplate_166_i_io_mbistCgCtl_rckEn), .io_mbistCgCtl_wckEn(vSRAMTemplate_166_i_io_mbistCgCtl_wckEn), .boreChildrenBd_bore_rdata(vSRAMTemplate_166_i_boreChildrenBd_bore_rdata));
  int vSRAMTemplate_166_cov_w = 0, vSRAMTemplate_166_cov_rw_same = 0, vSRAMTemplate_166_cov_cgoff = 0, vSRAMTemplate_166_cov_bore_w = 0, vSRAMTemplate_166_cov_bore_r = 0, vSRAMTemplate_166_cov_hold = 0, vSRAMTemplate_166_cov_rd_known = 0, vSRAMTemplate_166_cov_rd_nonzero = 0;
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_166_io_r_req_valid <= 1'b0;
      vSRAMTemplate_166_io_w_req_valid <= 1'b0;
      vSRAMTemplate_166_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_166_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_166_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_166_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_166_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_166_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_166_io_r_req_bits_setIdx <= ($urandom_range(0,3)!=0) ? 12'($urandom_range(0,7)) : 12'($urandom);
      vSRAMTemplate_166_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_166_io_w_req_bits_setIdx <= ($urandom_range(0,3)!=0) ? 12'($urandom_range(0,7)) : 12'($urandom);
      vSRAMTemplate_166_io_w_req_bits_data_0 <= 137'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      vSRAMTemplate_166_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_166_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_166_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_166_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_166_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_166_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_166_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_166_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_166_boreChildrenBd_bore_addr <= 13'($urandom);
      vSRAMTemplate_166_boreChildrenBd_bore_addr_rd <= 13'($urandom);
      vSRAMTemplate_166_boreChildrenBd_bore_wdata <= 137'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      vSRAMTemplate_166_boreChildrenBd_bore_wmask <= 1'($urandom);
      vSRAMTemplate_166_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_166_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_166_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_166_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_166_boreChildrenBd_bore_array <= 5'($urandom);
    end
  end
  always @(posedge clk) if (!rst && cycle > WARMUP) begin
    if (vSRAMTemplate_166_io_w_req_valid && !vSRAMTemplate_166_io_broadcast_ram_hold) vSRAMTemplate_166_cov_w++;
    if (vSRAMTemplate_166_io_w_req_valid && vSRAMTemplate_166_io_r_req_valid && vSRAMTemplate_166_io_w_req_bits_setIdx == vSRAMTemplate_166_io_r_req_bits_setIdx) vSRAMTemplate_166_cov_rw_same++;
    if (!vSRAMTemplate_166_io_w_req_valid && !vSRAMTemplate_166_io_r_req_valid && !vSRAMTemplate_166_boreChildrenBd_bore_ack) vSRAMTemplate_166_cov_cgoff++;
    if (vSRAMTemplate_166_boreChildrenBd_bore_ack && vSRAMTemplate_166_boreChildrenBd_bore_we) vSRAMTemplate_166_cov_bore_w++;
    if (vSRAMTemplate_166_boreChildrenBd_bore_ack && vSRAMTemplate_166_boreChildrenBd_bore_re) vSRAMTemplate_166_cov_bore_r++;
    if (vSRAMTemplate_166_io_broadcast_ram_hold) vSRAMTemplate_166_cov_hold++;
    if (!has_x({vSRAMTemplate_166_g_io_r_resp_data_0}, 137) && !has_z({vSRAMTemplate_166_g_io_r_resp_data_0}, 137)) begin
      vSRAMTemplate_166_cov_rd_known++;
      if (|{vSRAMTemplate_166_g_io_r_resp_data_0}) vSRAMTemplate_166_cov_rd_nonzero++;
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_166_g_io_r_resp_data_0 !== vSRAMTemplate_166_i_io_r_resp_data_0) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_166.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_166_g_io_r_resp_data_0, vSRAMTemplate_166_i_io_r_resp_data_0); end
    if (has_z(vSRAMTemplate_166_g_io_r_resp_data_0, 137) || has_z(vSRAMTemplate_166_i_io_r_resp_data_0, 137)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_166.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_166_g_io_r_resp_data_0, vSRAMTemplate_166_i_io_r_resp_data_0); end
    if (vSRAMTemplate_166_g_io_mbistCgCtl_en !== vSRAMTemplate_166_i_io_mbistCgCtl_en) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_166.io_mbistCgCtl_en g=%h i=%h", $time, vSRAMTemplate_166_g_io_mbistCgCtl_en, vSRAMTemplate_166_i_io_mbistCgCtl_en); end
    if (has_z(vSRAMTemplate_166_g_io_mbistCgCtl_en, 1) || has_z(vSRAMTemplate_166_i_io_mbistCgCtl_en, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_166.io_mbistCgCtl_en g=%h i=%h", $time, vSRAMTemplate_166_g_io_mbistCgCtl_en, vSRAMTemplate_166_i_io_mbistCgCtl_en); end
    if (vSRAMTemplate_166_g_io_mbistCgCtl_rckEn !== vSRAMTemplate_166_i_io_mbistCgCtl_rckEn) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_166.io_mbistCgCtl_rckEn g=%h i=%h", $time, vSRAMTemplate_166_g_io_mbistCgCtl_rckEn, vSRAMTemplate_166_i_io_mbistCgCtl_rckEn); end
    if (has_z(vSRAMTemplate_166_g_io_mbistCgCtl_rckEn, 1) || has_z(vSRAMTemplate_166_i_io_mbistCgCtl_rckEn, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_166.io_mbistCgCtl_rckEn g=%h i=%h", $time, vSRAMTemplate_166_g_io_mbistCgCtl_rckEn, vSRAMTemplate_166_i_io_mbistCgCtl_rckEn); end
    if (vSRAMTemplate_166_g_io_mbistCgCtl_wckEn !== vSRAMTemplate_166_i_io_mbistCgCtl_wckEn) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_166.io_mbistCgCtl_wckEn g=%h i=%h", $time, vSRAMTemplate_166_g_io_mbistCgCtl_wckEn, vSRAMTemplate_166_i_io_mbistCgCtl_wckEn); end
    if (has_z(vSRAMTemplate_166_g_io_mbistCgCtl_wckEn, 1) || has_z(vSRAMTemplate_166_i_io_mbistCgCtl_wckEn, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_166.io_mbistCgCtl_wckEn g=%h i=%h", $time, vSRAMTemplate_166_g_io_mbistCgCtl_wckEn, vSRAMTemplate_166_i_io_mbistCgCtl_wckEn); end
    if (vSRAMTemplate_166_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_166_i_boreChildrenBd_bore_rdata) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_166.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_166_g_boreChildrenBd_bore_rdata, vSRAMTemplate_166_i_boreChildrenBd_bore_rdata); end
    if (has_z(vSRAMTemplate_166_g_boreChildrenBd_bore_rdata, 137) || has_z(vSRAMTemplate_166_i_boreChildrenBd_bore_rdata, 137)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_166.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_166_g_boreChildrenBd_bore_rdata, vSRAMTemplate_166_i_boreChildrenBd_bore_rdata); end
  end

  // ================= SRAMTemplate_178 =================
  logic vSRAMTemplate_178_io_r_req_valid;
  logic [11:0] vSRAMTemplate_178_io_r_req_bits_setIdx;
  logic vSRAMTemplate_178_io_w_req_valid;
  logic [11:0] vSRAMTemplate_178_io_w_req_bits_setIdx;
  logic [136:0] vSRAMTemplate_178_io_w_req_bits_data_0;
  logic vSRAMTemplate_178_io_broadcast_ram_hold;
  logic vSRAMTemplate_178_io_broadcast_ram_bypass;
  logic vSRAMTemplate_178_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_178_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_178_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_178_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_178_io_broadcast_ram_ctl;
  logic vSRAMTemplate_178_io_broadcast_cgen;
  logic [12:0] vSRAMTemplate_178_boreChildrenBd_bore_addr;
  logic [12:0] vSRAMTemplate_178_boreChildrenBd_bore_addr_rd;
  logic [136:0] vSRAMTemplate_178_boreChildrenBd_bore_wdata;
  logic vSRAMTemplate_178_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_178_boreChildrenBd_bore_re;
  logic vSRAMTemplate_178_boreChildrenBd_bore_we;
  logic vSRAMTemplate_178_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_178_boreChildrenBd_bore_selectedOH;
  logic [5:0] vSRAMTemplate_178_boreChildrenBd_bore_array;
  wire [136:0] vSRAMTemplate_178_g_io_r_resp_data_0;
  wire [136:0] vSRAMTemplate_178_i_io_r_resp_data_0;
  wire vSRAMTemplate_178_g_io_mbistCgCtl_en;
  wire vSRAMTemplate_178_i_io_mbistCgCtl_en;
  wire vSRAMTemplate_178_g_io_mbistCgCtl_rckEn;
  wire vSRAMTemplate_178_i_io_mbistCgCtl_rckEn;
  wire vSRAMTemplate_178_g_io_mbistCgCtl_wckEn;
  wire vSRAMTemplate_178_i_io_mbistCgCtl_wckEn;
  wire [136:0] vSRAMTemplate_178_g_boreChildrenBd_bore_rdata;
  wire [136:0] vSRAMTemplate_178_i_boreChildrenBd_bore_rdata;
  logic vSRAMTemplate_178_g_lat, vSRAMTemplate_178_i_lat;
  wire  vSRAMTemplate_178_g_rclk = clk & vSRAMTemplate_178_g_lat;
  wire  vSRAMTemplate_178_i_rclk = clk & vSRAMTemplate_178_i_lat;
  always @(*) if (!clk) begin
    vSRAMTemplate_178_g_lat = vSRAMTemplate_178_g_io_mbistCgCtl_rckEn | vSRAMTemplate_178_g_io_mbistCgCtl_wckEn;
    vSRAMTemplate_178_i_lat = vSRAMTemplate_178_i_io_mbistCgCtl_rckEn | vSRAMTemplate_178_i_io_mbistCgCtl_wckEn;
  end
  SRAMTemplate_178    u_g_SRAMTemplate_178 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_178_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_178_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_178_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_178_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_178_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_178_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_178_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_178_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_178_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_178_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_178_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_178_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_178_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_178_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_178_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_178_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_178_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_178_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_178_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_178_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_178_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_178_boreChildrenBd_bore_array), .io_mbistCgCtl_rclk(vSRAMTemplate_178_g_rclk), .io_r_resp_data_0(vSRAMTemplate_178_g_io_r_resp_data_0), .io_mbistCgCtl_en(vSRAMTemplate_178_g_io_mbistCgCtl_en), .io_mbistCgCtl_rckEn(vSRAMTemplate_178_g_io_mbistCgCtl_rckEn), .io_mbistCgCtl_wckEn(vSRAMTemplate_178_g_io_mbistCgCtl_wckEn), .boreChildrenBd_bore_rdata(vSRAMTemplate_178_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_178_xs u_i_SRAMTemplate_178 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_178_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_178_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_178_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_178_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_178_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_178_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_178_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_178_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_178_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_178_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_178_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_178_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_178_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_178_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_178_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_178_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_178_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_178_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_178_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_178_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_178_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_178_boreChildrenBd_bore_array), .io_mbistCgCtl_rclk(vSRAMTemplate_178_i_rclk), .io_r_resp_data_0(vSRAMTemplate_178_i_io_r_resp_data_0), .io_mbistCgCtl_en(vSRAMTemplate_178_i_io_mbistCgCtl_en), .io_mbistCgCtl_rckEn(vSRAMTemplate_178_i_io_mbistCgCtl_rckEn), .io_mbistCgCtl_wckEn(vSRAMTemplate_178_i_io_mbistCgCtl_wckEn), .boreChildrenBd_bore_rdata(vSRAMTemplate_178_i_boreChildrenBd_bore_rdata));
  int vSRAMTemplate_178_cov_w = 0, vSRAMTemplate_178_cov_rw_same = 0, vSRAMTemplate_178_cov_cgoff = 0, vSRAMTemplate_178_cov_bore_w = 0, vSRAMTemplate_178_cov_bore_r = 0, vSRAMTemplate_178_cov_hold = 0, vSRAMTemplate_178_cov_rd_known = 0, vSRAMTemplate_178_cov_rd_nonzero = 0;
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_178_io_r_req_valid <= 1'b0;
      vSRAMTemplate_178_io_w_req_valid <= 1'b0;
      vSRAMTemplate_178_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_178_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_178_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_178_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_178_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_178_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_178_io_r_req_bits_setIdx <= ($urandom_range(0,3)!=0) ? 12'($urandom_range(0,7)) : 12'($urandom);
      vSRAMTemplate_178_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_178_io_w_req_bits_setIdx <= ($urandom_range(0,3)!=0) ? 12'($urandom_range(0,7)) : 12'($urandom);
      vSRAMTemplate_178_io_w_req_bits_data_0 <= 137'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      vSRAMTemplate_178_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_178_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_178_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_178_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_178_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_178_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_178_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_178_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_178_boreChildrenBd_bore_addr <= 13'($urandom);
      vSRAMTemplate_178_boreChildrenBd_bore_addr_rd <= 13'($urandom);
      vSRAMTemplate_178_boreChildrenBd_bore_wdata <= 137'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      vSRAMTemplate_178_boreChildrenBd_bore_wmask <= 1'($urandom);
      vSRAMTemplate_178_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_178_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_178_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_178_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_178_boreChildrenBd_bore_array <= 6'($urandom);
    end
  end
  always @(posedge clk) if (!rst && cycle > WARMUP) begin
    if (vSRAMTemplate_178_io_w_req_valid && !vSRAMTemplate_178_io_broadcast_ram_hold) vSRAMTemplate_178_cov_w++;
    if (vSRAMTemplate_178_io_w_req_valid && vSRAMTemplate_178_io_r_req_valid && vSRAMTemplate_178_io_w_req_bits_setIdx == vSRAMTemplate_178_io_r_req_bits_setIdx) vSRAMTemplate_178_cov_rw_same++;
    if (!vSRAMTemplate_178_io_w_req_valid && !vSRAMTemplate_178_io_r_req_valid && !vSRAMTemplate_178_boreChildrenBd_bore_ack) vSRAMTemplate_178_cov_cgoff++;
    if (vSRAMTemplate_178_boreChildrenBd_bore_ack && vSRAMTemplate_178_boreChildrenBd_bore_we) vSRAMTemplate_178_cov_bore_w++;
    if (vSRAMTemplate_178_boreChildrenBd_bore_ack && vSRAMTemplate_178_boreChildrenBd_bore_re) vSRAMTemplate_178_cov_bore_r++;
    if (vSRAMTemplate_178_io_broadcast_ram_hold) vSRAMTemplate_178_cov_hold++;
    if (!has_x({vSRAMTemplate_178_g_io_r_resp_data_0}, 137) && !has_z({vSRAMTemplate_178_g_io_r_resp_data_0}, 137)) begin
      vSRAMTemplate_178_cov_rd_known++;
      if (|{vSRAMTemplate_178_g_io_r_resp_data_0}) vSRAMTemplate_178_cov_rd_nonzero++;
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_178_g_io_r_resp_data_0 !== vSRAMTemplate_178_i_io_r_resp_data_0) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_178.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_178_g_io_r_resp_data_0, vSRAMTemplate_178_i_io_r_resp_data_0); end
    if (has_z(vSRAMTemplate_178_g_io_r_resp_data_0, 137) || has_z(vSRAMTemplate_178_i_io_r_resp_data_0, 137)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_178.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_178_g_io_r_resp_data_0, vSRAMTemplate_178_i_io_r_resp_data_0); end
    if (vSRAMTemplate_178_g_io_mbistCgCtl_en !== vSRAMTemplate_178_i_io_mbistCgCtl_en) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_178.io_mbistCgCtl_en g=%h i=%h", $time, vSRAMTemplate_178_g_io_mbistCgCtl_en, vSRAMTemplate_178_i_io_mbistCgCtl_en); end
    if (has_z(vSRAMTemplate_178_g_io_mbistCgCtl_en, 1) || has_z(vSRAMTemplate_178_i_io_mbistCgCtl_en, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_178.io_mbistCgCtl_en g=%h i=%h", $time, vSRAMTemplate_178_g_io_mbistCgCtl_en, vSRAMTemplate_178_i_io_mbistCgCtl_en); end
    if (vSRAMTemplate_178_g_io_mbistCgCtl_rckEn !== vSRAMTemplate_178_i_io_mbistCgCtl_rckEn) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_178.io_mbistCgCtl_rckEn g=%h i=%h", $time, vSRAMTemplate_178_g_io_mbistCgCtl_rckEn, vSRAMTemplate_178_i_io_mbistCgCtl_rckEn); end
    if (has_z(vSRAMTemplate_178_g_io_mbistCgCtl_rckEn, 1) || has_z(vSRAMTemplate_178_i_io_mbistCgCtl_rckEn, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_178.io_mbistCgCtl_rckEn g=%h i=%h", $time, vSRAMTemplate_178_g_io_mbistCgCtl_rckEn, vSRAMTemplate_178_i_io_mbistCgCtl_rckEn); end
    if (vSRAMTemplate_178_g_io_mbistCgCtl_wckEn !== vSRAMTemplate_178_i_io_mbistCgCtl_wckEn) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_178.io_mbistCgCtl_wckEn g=%h i=%h", $time, vSRAMTemplate_178_g_io_mbistCgCtl_wckEn, vSRAMTemplate_178_i_io_mbistCgCtl_wckEn); end
    if (has_z(vSRAMTemplate_178_g_io_mbistCgCtl_wckEn, 1) || has_z(vSRAMTemplate_178_i_io_mbistCgCtl_wckEn, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_178.io_mbistCgCtl_wckEn g=%h i=%h", $time, vSRAMTemplate_178_g_io_mbistCgCtl_wckEn, vSRAMTemplate_178_i_io_mbistCgCtl_wckEn); end
    if (vSRAMTemplate_178_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_178_i_boreChildrenBd_bore_rdata) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_178.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_178_g_boreChildrenBd_bore_rdata, vSRAMTemplate_178_i_boreChildrenBd_bore_rdata); end
    if (has_z(vSRAMTemplate_178_g_boreChildrenBd_bore_rdata, 137) || has_z(vSRAMTemplate_178_i_boreChildrenBd_bore_rdata, 137)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_178.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_178_g_boreChildrenBd_bore_rdata, vSRAMTemplate_178_i_boreChildrenBd_bore_rdata); end
  end

  // ================= SRAMTemplate_185 =================
  logic vSRAMTemplate_185_io_r_req_valid;
  logic [8:0] vSRAMTemplate_185_io_r_req_bits_setIdx;
  logic vSRAMTemplate_185_io_w_req_valid;
  logic [8:0] vSRAMTemplate_185_io_w_req_bits_setIdx;
  logic vSRAMTemplate_185_io_w_req_bits_data_0_dirty;
  logic [1:0] vSRAMTemplate_185_io_w_req_bits_data_0_state;
  logic vSRAMTemplate_185_io_w_req_bits_data_0_clients;
  logic [1:0] vSRAMTemplate_185_io_w_req_bits_data_0_alias;
  logic vSRAMTemplate_185_io_w_req_bits_data_0_prefetch;
  logic [2:0] vSRAMTemplate_185_io_w_req_bits_data_0_prefetchSrc;
  logic vSRAMTemplate_185_io_w_req_bits_data_0_accessed;
  logic vSRAMTemplate_185_io_w_req_bits_data_0_tagErr;
  logic vSRAMTemplate_185_io_w_req_bits_data_0_dataErr;
  logic vSRAMTemplate_185_io_w_req_bits_data_1_dirty;
  logic [1:0] vSRAMTemplate_185_io_w_req_bits_data_1_state;
  logic vSRAMTemplate_185_io_w_req_bits_data_1_clients;
  logic [1:0] vSRAMTemplate_185_io_w_req_bits_data_1_alias;
  logic vSRAMTemplate_185_io_w_req_bits_data_1_prefetch;
  logic [2:0] vSRAMTemplate_185_io_w_req_bits_data_1_prefetchSrc;
  logic vSRAMTemplate_185_io_w_req_bits_data_1_accessed;
  logic vSRAMTemplate_185_io_w_req_bits_data_1_tagErr;
  logic vSRAMTemplate_185_io_w_req_bits_data_1_dataErr;
  logic vSRAMTemplate_185_io_w_req_bits_data_2_dirty;
  logic [1:0] vSRAMTemplate_185_io_w_req_bits_data_2_state;
  logic vSRAMTemplate_185_io_w_req_bits_data_2_clients;
  logic [1:0] vSRAMTemplate_185_io_w_req_bits_data_2_alias;
  logic vSRAMTemplate_185_io_w_req_bits_data_2_prefetch;
  logic [2:0] vSRAMTemplate_185_io_w_req_bits_data_2_prefetchSrc;
  logic vSRAMTemplate_185_io_w_req_bits_data_2_accessed;
  logic vSRAMTemplate_185_io_w_req_bits_data_2_tagErr;
  logic vSRAMTemplate_185_io_w_req_bits_data_2_dataErr;
  logic vSRAMTemplate_185_io_w_req_bits_data_3_dirty;
  logic [1:0] vSRAMTemplate_185_io_w_req_bits_data_3_state;
  logic vSRAMTemplate_185_io_w_req_bits_data_3_clients;
  logic [1:0] vSRAMTemplate_185_io_w_req_bits_data_3_alias;
  logic vSRAMTemplate_185_io_w_req_bits_data_3_prefetch;
  logic [2:0] vSRAMTemplate_185_io_w_req_bits_data_3_prefetchSrc;
  logic vSRAMTemplate_185_io_w_req_bits_data_3_accessed;
  logic vSRAMTemplate_185_io_w_req_bits_data_3_tagErr;
  logic vSRAMTemplate_185_io_w_req_bits_data_3_dataErr;
  logic vSRAMTemplate_185_io_w_req_bits_data_4_dirty;
  logic [1:0] vSRAMTemplate_185_io_w_req_bits_data_4_state;
  logic vSRAMTemplate_185_io_w_req_bits_data_4_clients;
  logic [1:0] vSRAMTemplate_185_io_w_req_bits_data_4_alias;
  logic vSRAMTemplate_185_io_w_req_bits_data_4_prefetch;
  logic [2:0] vSRAMTemplate_185_io_w_req_bits_data_4_prefetchSrc;
  logic vSRAMTemplate_185_io_w_req_bits_data_4_accessed;
  logic vSRAMTemplate_185_io_w_req_bits_data_4_tagErr;
  logic vSRAMTemplate_185_io_w_req_bits_data_4_dataErr;
  logic vSRAMTemplate_185_io_w_req_bits_data_5_dirty;
  logic [1:0] vSRAMTemplate_185_io_w_req_bits_data_5_state;
  logic vSRAMTemplate_185_io_w_req_bits_data_5_clients;
  logic [1:0] vSRAMTemplate_185_io_w_req_bits_data_5_alias;
  logic vSRAMTemplate_185_io_w_req_bits_data_5_prefetch;
  logic [2:0] vSRAMTemplate_185_io_w_req_bits_data_5_prefetchSrc;
  logic vSRAMTemplate_185_io_w_req_bits_data_5_accessed;
  logic vSRAMTemplate_185_io_w_req_bits_data_5_tagErr;
  logic vSRAMTemplate_185_io_w_req_bits_data_5_dataErr;
  logic vSRAMTemplate_185_io_w_req_bits_data_6_dirty;
  logic [1:0] vSRAMTemplate_185_io_w_req_bits_data_6_state;
  logic vSRAMTemplate_185_io_w_req_bits_data_6_clients;
  logic [1:0] vSRAMTemplate_185_io_w_req_bits_data_6_alias;
  logic vSRAMTemplate_185_io_w_req_bits_data_6_prefetch;
  logic [2:0] vSRAMTemplate_185_io_w_req_bits_data_6_prefetchSrc;
  logic vSRAMTemplate_185_io_w_req_bits_data_6_accessed;
  logic vSRAMTemplate_185_io_w_req_bits_data_6_tagErr;
  logic vSRAMTemplate_185_io_w_req_bits_data_6_dataErr;
  logic vSRAMTemplate_185_io_w_req_bits_data_7_dirty;
  logic [1:0] vSRAMTemplate_185_io_w_req_bits_data_7_state;
  logic vSRAMTemplate_185_io_w_req_bits_data_7_clients;
  logic [1:0] vSRAMTemplate_185_io_w_req_bits_data_7_alias;
  logic vSRAMTemplate_185_io_w_req_bits_data_7_prefetch;
  logic [2:0] vSRAMTemplate_185_io_w_req_bits_data_7_prefetchSrc;
  logic vSRAMTemplate_185_io_w_req_bits_data_7_accessed;
  logic vSRAMTemplate_185_io_w_req_bits_data_7_tagErr;
  logic vSRAMTemplate_185_io_w_req_bits_data_7_dataErr;
  logic [7:0] vSRAMTemplate_185_io_w_req_bits_waymask;
  logic vSRAMTemplate_185_io_broadcast_ram_hold;
  logic vSRAMTemplate_185_io_broadcast_ram_bypass;
  logic vSRAMTemplate_185_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_185_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_185_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_185_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_185_io_broadcast_ram_ctl;
  logic vSRAMTemplate_185_io_broadcast_cgen;
  logic [9:0] vSRAMTemplate_185_boreChildrenBd_bore_addr;
  logic [9:0] vSRAMTemplate_185_boreChildrenBd_bore_addr_rd;
  logic [103:0] vSRAMTemplate_185_boreChildrenBd_bore_wdata;
  logic [7:0] vSRAMTemplate_185_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_185_boreChildrenBd_bore_re;
  logic vSRAMTemplate_185_boreChildrenBd_bore_we;
  logic vSRAMTemplate_185_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_185_boreChildrenBd_bore_selectedOH;
  logic [5:0] vSRAMTemplate_185_boreChildrenBd_bore_array;
  wire vSRAMTemplate_185_g_io_r_req_ready;
  wire vSRAMTemplate_185_i_io_r_req_ready;
  wire vSRAMTemplate_185_g_io_r_resp_data_0_dirty;
  wire vSRAMTemplate_185_i_io_r_resp_data_0_dirty;
  wire [1:0] vSRAMTemplate_185_g_io_r_resp_data_0_state;
  wire [1:0] vSRAMTemplate_185_i_io_r_resp_data_0_state;
  wire vSRAMTemplate_185_g_io_r_resp_data_0_clients;
  wire vSRAMTemplate_185_i_io_r_resp_data_0_clients;
  wire [1:0] vSRAMTemplate_185_g_io_r_resp_data_0_alias;
  wire [1:0] vSRAMTemplate_185_i_io_r_resp_data_0_alias;
  wire vSRAMTemplate_185_g_io_r_resp_data_0_prefetch;
  wire vSRAMTemplate_185_i_io_r_resp_data_0_prefetch;
  wire [2:0] vSRAMTemplate_185_g_io_r_resp_data_0_prefetchSrc;
  wire [2:0] vSRAMTemplate_185_i_io_r_resp_data_0_prefetchSrc;
  wire vSRAMTemplate_185_g_io_r_resp_data_0_accessed;
  wire vSRAMTemplate_185_i_io_r_resp_data_0_accessed;
  wire vSRAMTemplate_185_g_io_r_resp_data_0_tagErr;
  wire vSRAMTemplate_185_i_io_r_resp_data_0_tagErr;
  wire vSRAMTemplate_185_g_io_r_resp_data_0_dataErr;
  wire vSRAMTemplate_185_i_io_r_resp_data_0_dataErr;
  wire vSRAMTemplate_185_g_io_r_resp_data_1_dirty;
  wire vSRAMTemplate_185_i_io_r_resp_data_1_dirty;
  wire [1:0] vSRAMTemplate_185_g_io_r_resp_data_1_state;
  wire [1:0] vSRAMTemplate_185_i_io_r_resp_data_1_state;
  wire vSRAMTemplate_185_g_io_r_resp_data_1_clients;
  wire vSRAMTemplate_185_i_io_r_resp_data_1_clients;
  wire [1:0] vSRAMTemplate_185_g_io_r_resp_data_1_alias;
  wire [1:0] vSRAMTemplate_185_i_io_r_resp_data_1_alias;
  wire vSRAMTemplate_185_g_io_r_resp_data_1_prefetch;
  wire vSRAMTemplate_185_i_io_r_resp_data_1_prefetch;
  wire [2:0] vSRAMTemplate_185_g_io_r_resp_data_1_prefetchSrc;
  wire [2:0] vSRAMTemplate_185_i_io_r_resp_data_1_prefetchSrc;
  wire vSRAMTemplate_185_g_io_r_resp_data_1_accessed;
  wire vSRAMTemplate_185_i_io_r_resp_data_1_accessed;
  wire vSRAMTemplate_185_g_io_r_resp_data_1_tagErr;
  wire vSRAMTemplate_185_i_io_r_resp_data_1_tagErr;
  wire vSRAMTemplate_185_g_io_r_resp_data_1_dataErr;
  wire vSRAMTemplate_185_i_io_r_resp_data_1_dataErr;
  wire vSRAMTemplate_185_g_io_r_resp_data_2_dirty;
  wire vSRAMTemplate_185_i_io_r_resp_data_2_dirty;
  wire [1:0] vSRAMTemplate_185_g_io_r_resp_data_2_state;
  wire [1:0] vSRAMTemplate_185_i_io_r_resp_data_2_state;
  wire vSRAMTemplate_185_g_io_r_resp_data_2_clients;
  wire vSRAMTemplate_185_i_io_r_resp_data_2_clients;
  wire [1:0] vSRAMTemplate_185_g_io_r_resp_data_2_alias;
  wire [1:0] vSRAMTemplate_185_i_io_r_resp_data_2_alias;
  wire vSRAMTemplate_185_g_io_r_resp_data_2_prefetch;
  wire vSRAMTemplate_185_i_io_r_resp_data_2_prefetch;
  wire [2:0] vSRAMTemplate_185_g_io_r_resp_data_2_prefetchSrc;
  wire [2:0] vSRAMTemplate_185_i_io_r_resp_data_2_prefetchSrc;
  wire vSRAMTemplate_185_g_io_r_resp_data_2_accessed;
  wire vSRAMTemplate_185_i_io_r_resp_data_2_accessed;
  wire vSRAMTemplate_185_g_io_r_resp_data_2_tagErr;
  wire vSRAMTemplate_185_i_io_r_resp_data_2_tagErr;
  wire vSRAMTemplate_185_g_io_r_resp_data_2_dataErr;
  wire vSRAMTemplate_185_i_io_r_resp_data_2_dataErr;
  wire vSRAMTemplate_185_g_io_r_resp_data_3_dirty;
  wire vSRAMTemplate_185_i_io_r_resp_data_3_dirty;
  wire [1:0] vSRAMTemplate_185_g_io_r_resp_data_3_state;
  wire [1:0] vSRAMTemplate_185_i_io_r_resp_data_3_state;
  wire vSRAMTemplate_185_g_io_r_resp_data_3_clients;
  wire vSRAMTemplate_185_i_io_r_resp_data_3_clients;
  wire [1:0] vSRAMTemplate_185_g_io_r_resp_data_3_alias;
  wire [1:0] vSRAMTemplate_185_i_io_r_resp_data_3_alias;
  wire vSRAMTemplate_185_g_io_r_resp_data_3_prefetch;
  wire vSRAMTemplate_185_i_io_r_resp_data_3_prefetch;
  wire [2:0] vSRAMTemplate_185_g_io_r_resp_data_3_prefetchSrc;
  wire [2:0] vSRAMTemplate_185_i_io_r_resp_data_3_prefetchSrc;
  wire vSRAMTemplate_185_g_io_r_resp_data_3_accessed;
  wire vSRAMTemplate_185_i_io_r_resp_data_3_accessed;
  wire vSRAMTemplate_185_g_io_r_resp_data_3_tagErr;
  wire vSRAMTemplate_185_i_io_r_resp_data_3_tagErr;
  wire vSRAMTemplate_185_g_io_r_resp_data_3_dataErr;
  wire vSRAMTemplate_185_i_io_r_resp_data_3_dataErr;
  wire vSRAMTemplate_185_g_io_r_resp_data_4_dirty;
  wire vSRAMTemplate_185_i_io_r_resp_data_4_dirty;
  wire [1:0] vSRAMTemplate_185_g_io_r_resp_data_4_state;
  wire [1:0] vSRAMTemplate_185_i_io_r_resp_data_4_state;
  wire vSRAMTemplate_185_g_io_r_resp_data_4_clients;
  wire vSRAMTemplate_185_i_io_r_resp_data_4_clients;
  wire [1:0] vSRAMTemplate_185_g_io_r_resp_data_4_alias;
  wire [1:0] vSRAMTemplate_185_i_io_r_resp_data_4_alias;
  wire vSRAMTemplate_185_g_io_r_resp_data_4_prefetch;
  wire vSRAMTemplate_185_i_io_r_resp_data_4_prefetch;
  wire [2:0] vSRAMTemplate_185_g_io_r_resp_data_4_prefetchSrc;
  wire [2:0] vSRAMTemplate_185_i_io_r_resp_data_4_prefetchSrc;
  wire vSRAMTemplate_185_g_io_r_resp_data_4_accessed;
  wire vSRAMTemplate_185_i_io_r_resp_data_4_accessed;
  wire vSRAMTemplate_185_g_io_r_resp_data_4_tagErr;
  wire vSRAMTemplate_185_i_io_r_resp_data_4_tagErr;
  wire vSRAMTemplate_185_g_io_r_resp_data_4_dataErr;
  wire vSRAMTemplate_185_i_io_r_resp_data_4_dataErr;
  wire vSRAMTemplate_185_g_io_r_resp_data_5_dirty;
  wire vSRAMTemplate_185_i_io_r_resp_data_5_dirty;
  wire [1:0] vSRAMTemplate_185_g_io_r_resp_data_5_state;
  wire [1:0] vSRAMTemplate_185_i_io_r_resp_data_5_state;
  wire vSRAMTemplate_185_g_io_r_resp_data_5_clients;
  wire vSRAMTemplate_185_i_io_r_resp_data_5_clients;
  wire [1:0] vSRAMTemplate_185_g_io_r_resp_data_5_alias;
  wire [1:0] vSRAMTemplate_185_i_io_r_resp_data_5_alias;
  wire vSRAMTemplate_185_g_io_r_resp_data_5_prefetch;
  wire vSRAMTemplate_185_i_io_r_resp_data_5_prefetch;
  wire [2:0] vSRAMTemplate_185_g_io_r_resp_data_5_prefetchSrc;
  wire [2:0] vSRAMTemplate_185_i_io_r_resp_data_5_prefetchSrc;
  wire vSRAMTemplate_185_g_io_r_resp_data_5_accessed;
  wire vSRAMTemplate_185_i_io_r_resp_data_5_accessed;
  wire vSRAMTemplate_185_g_io_r_resp_data_5_tagErr;
  wire vSRAMTemplate_185_i_io_r_resp_data_5_tagErr;
  wire vSRAMTemplate_185_g_io_r_resp_data_5_dataErr;
  wire vSRAMTemplate_185_i_io_r_resp_data_5_dataErr;
  wire vSRAMTemplate_185_g_io_r_resp_data_6_dirty;
  wire vSRAMTemplate_185_i_io_r_resp_data_6_dirty;
  wire [1:0] vSRAMTemplate_185_g_io_r_resp_data_6_state;
  wire [1:0] vSRAMTemplate_185_i_io_r_resp_data_6_state;
  wire vSRAMTemplate_185_g_io_r_resp_data_6_clients;
  wire vSRAMTemplate_185_i_io_r_resp_data_6_clients;
  wire [1:0] vSRAMTemplate_185_g_io_r_resp_data_6_alias;
  wire [1:0] vSRAMTemplate_185_i_io_r_resp_data_6_alias;
  wire vSRAMTemplate_185_g_io_r_resp_data_6_prefetch;
  wire vSRAMTemplate_185_i_io_r_resp_data_6_prefetch;
  wire [2:0] vSRAMTemplate_185_g_io_r_resp_data_6_prefetchSrc;
  wire [2:0] vSRAMTemplate_185_i_io_r_resp_data_6_prefetchSrc;
  wire vSRAMTemplate_185_g_io_r_resp_data_6_accessed;
  wire vSRAMTemplate_185_i_io_r_resp_data_6_accessed;
  wire vSRAMTemplate_185_g_io_r_resp_data_6_tagErr;
  wire vSRAMTemplate_185_i_io_r_resp_data_6_tagErr;
  wire vSRAMTemplate_185_g_io_r_resp_data_6_dataErr;
  wire vSRAMTemplate_185_i_io_r_resp_data_6_dataErr;
  wire vSRAMTemplate_185_g_io_r_resp_data_7_dirty;
  wire vSRAMTemplate_185_i_io_r_resp_data_7_dirty;
  wire [1:0] vSRAMTemplate_185_g_io_r_resp_data_7_state;
  wire [1:0] vSRAMTemplate_185_i_io_r_resp_data_7_state;
  wire vSRAMTemplate_185_g_io_r_resp_data_7_clients;
  wire vSRAMTemplate_185_i_io_r_resp_data_7_clients;
  wire [1:0] vSRAMTemplate_185_g_io_r_resp_data_7_alias;
  wire [1:0] vSRAMTemplate_185_i_io_r_resp_data_7_alias;
  wire vSRAMTemplate_185_g_io_r_resp_data_7_prefetch;
  wire vSRAMTemplate_185_i_io_r_resp_data_7_prefetch;
  wire [2:0] vSRAMTemplate_185_g_io_r_resp_data_7_prefetchSrc;
  wire [2:0] vSRAMTemplate_185_i_io_r_resp_data_7_prefetchSrc;
  wire vSRAMTemplate_185_g_io_r_resp_data_7_accessed;
  wire vSRAMTemplate_185_i_io_r_resp_data_7_accessed;
  wire vSRAMTemplate_185_g_io_r_resp_data_7_tagErr;
  wire vSRAMTemplate_185_i_io_r_resp_data_7_tagErr;
  wire vSRAMTemplate_185_g_io_r_resp_data_7_dataErr;
  wire vSRAMTemplate_185_i_io_r_resp_data_7_dataErr;
  wire vSRAMTemplate_185_g_io_w_req_ready;
  wire vSRAMTemplate_185_i_io_w_req_ready;
  wire vSRAMTemplate_185_g_io_resetDone;
  wire vSRAMTemplate_185_i_io_resetDone;
  wire [103:0] vSRAMTemplate_185_g_boreChildrenBd_bore_rdata;
  wire [103:0] vSRAMTemplate_185_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_185    u_g_SRAMTemplate_185 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_185_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_185_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_185_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_185_io_w_req_bits_setIdx), .io_w_req_bits_data_0_dirty(vSRAMTemplate_185_io_w_req_bits_data_0_dirty), .io_w_req_bits_data_0_state(vSRAMTemplate_185_io_w_req_bits_data_0_state), .io_w_req_bits_data_0_clients(vSRAMTemplate_185_io_w_req_bits_data_0_clients), .io_w_req_bits_data_0_alias(vSRAMTemplate_185_io_w_req_bits_data_0_alias), .io_w_req_bits_data_0_prefetch(vSRAMTemplate_185_io_w_req_bits_data_0_prefetch), .io_w_req_bits_data_0_prefetchSrc(vSRAMTemplate_185_io_w_req_bits_data_0_prefetchSrc), .io_w_req_bits_data_0_accessed(vSRAMTemplate_185_io_w_req_bits_data_0_accessed), .io_w_req_bits_data_0_tagErr(vSRAMTemplate_185_io_w_req_bits_data_0_tagErr), .io_w_req_bits_data_0_dataErr(vSRAMTemplate_185_io_w_req_bits_data_0_dataErr), .io_w_req_bits_data_1_dirty(vSRAMTemplate_185_io_w_req_bits_data_1_dirty), .io_w_req_bits_data_1_state(vSRAMTemplate_185_io_w_req_bits_data_1_state), .io_w_req_bits_data_1_clients(vSRAMTemplate_185_io_w_req_bits_data_1_clients), .io_w_req_bits_data_1_alias(vSRAMTemplate_185_io_w_req_bits_data_1_alias), .io_w_req_bits_data_1_prefetch(vSRAMTemplate_185_io_w_req_bits_data_1_prefetch), .io_w_req_bits_data_1_prefetchSrc(vSRAMTemplate_185_io_w_req_bits_data_1_prefetchSrc), .io_w_req_bits_data_1_accessed(vSRAMTemplate_185_io_w_req_bits_data_1_accessed), .io_w_req_bits_data_1_tagErr(vSRAMTemplate_185_io_w_req_bits_data_1_tagErr), .io_w_req_bits_data_1_dataErr(vSRAMTemplate_185_io_w_req_bits_data_1_dataErr), .io_w_req_bits_data_2_dirty(vSRAMTemplate_185_io_w_req_bits_data_2_dirty), .io_w_req_bits_data_2_state(vSRAMTemplate_185_io_w_req_bits_data_2_state), .io_w_req_bits_data_2_clients(vSRAMTemplate_185_io_w_req_bits_data_2_clients), .io_w_req_bits_data_2_alias(vSRAMTemplate_185_io_w_req_bits_data_2_alias), .io_w_req_bits_data_2_prefetch(vSRAMTemplate_185_io_w_req_bits_data_2_prefetch), .io_w_req_bits_data_2_prefetchSrc(vSRAMTemplate_185_io_w_req_bits_data_2_prefetchSrc), .io_w_req_bits_data_2_accessed(vSRAMTemplate_185_io_w_req_bits_data_2_accessed), .io_w_req_bits_data_2_tagErr(vSRAMTemplate_185_io_w_req_bits_data_2_tagErr), .io_w_req_bits_data_2_dataErr(vSRAMTemplate_185_io_w_req_bits_data_2_dataErr), .io_w_req_bits_data_3_dirty(vSRAMTemplate_185_io_w_req_bits_data_3_dirty), .io_w_req_bits_data_3_state(vSRAMTemplate_185_io_w_req_bits_data_3_state), .io_w_req_bits_data_3_clients(vSRAMTemplate_185_io_w_req_bits_data_3_clients), .io_w_req_bits_data_3_alias(vSRAMTemplate_185_io_w_req_bits_data_3_alias), .io_w_req_bits_data_3_prefetch(vSRAMTemplate_185_io_w_req_bits_data_3_prefetch), .io_w_req_bits_data_3_prefetchSrc(vSRAMTemplate_185_io_w_req_bits_data_3_prefetchSrc), .io_w_req_bits_data_3_accessed(vSRAMTemplate_185_io_w_req_bits_data_3_accessed), .io_w_req_bits_data_3_tagErr(vSRAMTemplate_185_io_w_req_bits_data_3_tagErr), .io_w_req_bits_data_3_dataErr(vSRAMTemplate_185_io_w_req_bits_data_3_dataErr), .io_w_req_bits_data_4_dirty(vSRAMTemplate_185_io_w_req_bits_data_4_dirty), .io_w_req_bits_data_4_state(vSRAMTemplate_185_io_w_req_bits_data_4_state), .io_w_req_bits_data_4_clients(vSRAMTemplate_185_io_w_req_bits_data_4_clients), .io_w_req_bits_data_4_alias(vSRAMTemplate_185_io_w_req_bits_data_4_alias), .io_w_req_bits_data_4_prefetch(vSRAMTemplate_185_io_w_req_bits_data_4_prefetch), .io_w_req_bits_data_4_prefetchSrc(vSRAMTemplate_185_io_w_req_bits_data_4_prefetchSrc), .io_w_req_bits_data_4_accessed(vSRAMTemplate_185_io_w_req_bits_data_4_accessed), .io_w_req_bits_data_4_tagErr(vSRAMTemplate_185_io_w_req_bits_data_4_tagErr), .io_w_req_bits_data_4_dataErr(vSRAMTemplate_185_io_w_req_bits_data_4_dataErr), .io_w_req_bits_data_5_dirty(vSRAMTemplate_185_io_w_req_bits_data_5_dirty), .io_w_req_bits_data_5_state(vSRAMTemplate_185_io_w_req_bits_data_5_state), .io_w_req_bits_data_5_clients(vSRAMTemplate_185_io_w_req_bits_data_5_clients), .io_w_req_bits_data_5_alias(vSRAMTemplate_185_io_w_req_bits_data_5_alias), .io_w_req_bits_data_5_prefetch(vSRAMTemplate_185_io_w_req_bits_data_5_prefetch), .io_w_req_bits_data_5_prefetchSrc(vSRAMTemplate_185_io_w_req_bits_data_5_prefetchSrc), .io_w_req_bits_data_5_accessed(vSRAMTemplate_185_io_w_req_bits_data_5_accessed), .io_w_req_bits_data_5_tagErr(vSRAMTemplate_185_io_w_req_bits_data_5_tagErr), .io_w_req_bits_data_5_dataErr(vSRAMTemplate_185_io_w_req_bits_data_5_dataErr), .io_w_req_bits_data_6_dirty(vSRAMTemplate_185_io_w_req_bits_data_6_dirty), .io_w_req_bits_data_6_state(vSRAMTemplate_185_io_w_req_bits_data_6_state), .io_w_req_bits_data_6_clients(vSRAMTemplate_185_io_w_req_bits_data_6_clients), .io_w_req_bits_data_6_alias(vSRAMTemplate_185_io_w_req_bits_data_6_alias), .io_w_req_bits_data_6_prefetch(vSRAMTemplate_185_io_w_req_bits_data_6_prefetch), .io_w_req_bits_data_6_prefetchSrc(vSRAMTemplate_185_io_w_req_bits_data_6_prefetchSrc), .io_w_req_bits_data_6_accessed(vSRAMTemplate_185_io_w_req_bits_data_6_accessed), .io_w_req_bits_data_6_tagErr(vSRAMTemplate_185_io_w_req_bits_data_6_tagErr), .io_w_req_bits_data_6_dataErr(vSRAMTemplate_185_io_w_req_bits_data_6_dataErr), .io_w_req_bits_data_7_dirty(vSRAMTemplate_185_io_w_req_bits_data_7_dirty), .io_w_req_bits_data_7_state(vSRAMTemplate_185_io_w_req_bits_data_7_state), .io_w_req_bits_data_7_clients(vSRAMTemplate_185_io_w_req_bits_data_7_clients), .io_w_req_bits_data_7_alias(vSRAMTemplate_185_io_w_req_bits_data_7_alias), .io_w_req_bits_data_7_prefetch(vSRAMTemplate_185_io_w_req_bits_data_7_prefetch), .io_w_req_bits_data_7_prefetchSrc(vSRAMTemplate_185_io_w_req_bits_data_7_prefetchSrc), .io_w_req_bits_data_7_accessed(vSRAMTemplate_185_io_w_req_bits_data_7_accessed), .io_w_req_bits_data_7_tagErr(vSRAMTemplate_185_io_w_req_bits_data_7_tagErr), .io_w_req_bits_data_7_dataErr(vSRAMTemplate_185_io_w_req_bits_data_7_dataErr), .io_w_req_bits_waymask(vSRAMTemplate_185_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_185_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_185_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_185_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_185_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_185_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_185_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_185_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_185_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_185_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_185_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_185_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_185_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_185_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_185_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_185_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_185_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_185_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_185_g_io_r_req_ready), .io_r_resp_data_0_dirty(vSRAMTemplate_185_g_io_r_resp_data_0_dirty), .io_r_resp_data_0_state(vSRAMTemplate_185_g_io_r_resp_data_0_state), .io_r_resp_data_0_clients(vSRAMTemplate_185_g_io_r_resp_data_0_clients), .io_r_resp_data_0_alias(vSRAMTemplate_185_g_io_r_resp_data_0_alias), .io_r_resp_data_0_prefetch(vSRAMTemplate_185_g_io_r_resp_data_0_prefetch), .io_r_resp_data_0_prefetchSrc(vSRAMTemplate_185_g_io_r_resp_data_0_prefetchSrc), .io_r_resp_data_0_accessed(vSRAMTemplate_185_g_io_r_resp_data_0_accessed), .io_r_resp_data_0_tagErr(vSRAMTemplate_185_g_io_r_resp_data_0_tagErr), .io_r_resp_data_0_dataErr(vSRAMTemplate_185_g_io_r_resp_data_0_dataErr), .io_r_resp_data_1_dirty(vSRAMTemplate_185_g_io_r_resp_data_1_dirty), .io_r_resp_data_1_state(vSRAMTemplate_185_g_io_r_resp_data_1_state), .io_r_resp_data_1_clients(vSRAMTemplate_185_g_io_r_resp_data_1_clients), .io_r_resp_data_1_alias(vSRAMTemplate_185_g_io_r_resp_data_1_alias), .io_r_resp_data_1_prefetch(vSRAMTemplate_185_g_io_r_resp_data_1_prefetch), .io_r_resp_data_1_prefetchSrc(vSRAMTemplate_185_g_io_r_resp_data_1_prefetchSrc), .io_r_resp_data_1_accessed(vSRAMTemplate_185_g_io_r_resp_data_1_accessed), .io_r_resp_data_1_tagErr(vSRAMTemplate_185_g_io_r_resp_data_1_tagErr), .io_r_resp_data_1_dataErr(vSRAMTemplate_185_g_io_r_resp_data_1_dataErr), .io_r_resp_data_2_dirty(vSRAMTemplate_185_g_io_r_resp_data_2_dirty), .io_r_resp_data_2_state(vSRAMTemplate_185_g_io_r_resp_data_2_state), .io_r_resp_data_2_clients(vSRAMTemplate_185_g_io_r_resp_data_2_clients), .io_r_resp_data_2_alias(vSRAMTemplate_185_g_io_r_resp_data_2_alias), .io_r_resp_data_2_prefetch(vSRAMTemplate_185_g_io_r_resp_data_2_prefetch), .io_r_resp_data_2_prefetchSrc(vSRAMTemplate_185_g_io_r_resp_data_2_prefetchSrc), .io_r_resp_data_2_accessed(vSRAMTemplate_185_g_io_r_resp_data_2_accessed), .io_r_resp_data_2_tagErr(vSRAMTemplate_185_g_io_r_resp_data_2_tagErr), .io_r_resp_data_2_dataErr(vSRAMTemplate_185_g_io_r_resp_data_2_dataErr), .io_r_resp_data_3_dirty(vSRAMTemplate_185_g_io_r_resp_data_3_dirty), .io_r_resp_data_3_state(vSRAMTemplate_185_g_io_r_resp_data_3_state), .io_r_resp_data_3_clients(vSRAMTemplate_185_g_io_r_resp_data_3_clients), .io_r_resp_data_3_alias(vSRAMTemplate_185_g_io_r_resp_data_3_alias), .io_r_resp_data_3_prefetch(vSRAMTemplate_185_g_io_r_resp_data_3_prefetch), .io_r_resp_data_3_prefetchSrc(vSRAMTemplate_185_g_io_r_resp_data_3_prefetchSrc), .io_r_resp_data_3_accessed(vSRAMTemplate_185_g_io_r_resp_data_3_accessed), .io_r_resp_data_3_tagErr(vSRAMTemplate_185_g_io_r_resp_data_3_tagErr), .io_r_resp_data_3_dataErr(vSRAMTemplate_185_g_io_r_resp_data_3_dataErr), .io_r_resp_data_4_dirty(vSRAMTemplate_185_g_io_r_resp_data_4_dirty), .io_r_resp_data_4_state(vSRAMTemplate_185_g_io_r_resp_data_4_state), .io_r_resp_data_4_clients(vSRAMTemplate_185_g_io_r_resp_data_4_clients), .io_r_resp_data_4_alias(vSRAMTemplate_185_g_io_r_resp_data_4_alias), .io_r_resp_data_4_prefetch(vSRAMTemplate_185_g_io_r_resp_data_4_prefetch), .io_r_resp_data_4_prefetchSrc(vSRAMTemplate_185_g_io_r_resp_data_4_prefetchSrc), .io_r_resp_data_4_accessed(vSRAMTemplate_185_g_io_r_resp_data_4_accessed), .io_r_resp_data_4_tagErr(vSRAMTemplate_185_g_io_r_resp_data_4_tagErr), .io_r_resp_data_4_dataErr(vSRAMTemplate_185_g_io_r_resp_data_4_dataErr), .io_r_resp_data_5_dirty(vSRAMTemplate_185_g_io_r_resp_data_5_dirty), .io_r_resp_data_5_state(vSRAMTemplate_185_g_io_r_resp_data_5_state), .io_r_resp_data_5_clients(vSRAMTemplate_185_g_io_r_resp_data_5_clients), .io_r_resp_data_5_alias(vSRAMTemplate_185_g_io_r_resp_data_5_alias), .io_r_resp_data_5_prefetch(vSRAMTemplate_185_g_io_r_resp_data_5_prefetch), .io_r_resp_data_5_prefetchSrc(vSRAMTemplate_185_g_io_r_resp_data_5_prefetchSrc), .io_r_resp_data_5_accessed(vSRAMTemplate_185_g_io_r_resp_data_5_accessed), .io_r_resp_data_5_tagErr(vSRAMTemplate_185_g_io_r_resp_data_5_tagErr), .io_r_resp_data_5_dataErr(vSRAMTemplate_185_g_io_r_resp_data_5_dataErr), .io_r_resp_data_6_dirty(vSRAMTemplate_185_g_io_r_resp_data_6_dirty), .io_r_resp_data_6_state(vSRAMTemplate_185_g_io_r_resp_data_6_state), .io_r_resp_data_6_clients(vSRAMTemplate_185_g_io_r_resp_data_6_clients), .io_r_resp_data_6_alias(vSRAMTemplate_185_g_io_r_resp_data_6_alias), .io_r_resp_data_6_prefetch(vSRAMTemplate_185_g_io_r_resp_data_6_prefetch), .io_r_resp_data_6_prefetchSrc(vSRAMTemplate_185_g_io_r_resp_data_6_prefetchSrc), .io_r_resp_data_6_accessed(vSRAMTemplate_185_g_io_r_resp_data_6_accessed), .io_r_resp_data_6_tagErr(vSRAMTemplate_185_g_io_r_resp_data_6_tagErr), .io_r_resp_data_6_dataErr(vSRAMTemplate_185_g_io_r_resp_data_6_dataErr), .io_r_resp_data_7_dirty(vSRAMTemplate_185_g_io_r_resp_data_7_dirty), .io_r_resp_data_7_state(vSRAMTemplate_185_g_io_r_resp_data_7_state), .io_r_resp_data_7_clients(vSRAMTemplate_185_g_io_r_resp_data_7_clients), .io_r_resp_data_7_alias(vSRAMTemplate_185_g_io_r_resp_data_7_alias), .io_r_resp_data_7_prefetch(vSRAMTemplate_185_g_io_r_resp_data_7_prefetch), .io_r_resp_data_7_prefetchSrc(vSRAMTemplate_185_g_io_r_resp_data_7_prefetchSrc), .io_r_resp_data_7_accessed(vSRAMTemplate_185_g_io_r_resp_data_7_accessed), .io_r_resp_data_7_tagErr(vSRAMTemplate_185_g_io_r_resp_data_7_tagErr), .io_r_resp_data_7_dataErr(vSRAMTemplate_185_g_io_r_resp_data_7_dataErr), .io_w_req_ready(vSRAMTemplate_185_g_io_w_req_ready), .io_resetDone(vSRAMTemplate_185_g_io_resetDone), .boreChildrenBd_bore_rdata(vSRAMTemplate_185_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_185_xs u_i_SRAMTemplate_185 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_185_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_185_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_185_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_185_io_w_req_bits_setIdx), .io_w_req_bits_data_0_dirty(vSRAMTemplate_185_io_w_req_bits_data_0_dirty), .io_w_req_bits_data_0_state(vSRAMTemplate_185_io_w_req_bits_data_0_state), .io_w_req_bits_data_0_clients(vSRAMTemplate_185_io_w_req_bits_data_0_clients), .io_w_req_bits_data_0_alias(vSRAMTemplate_185_io_w_req_bits_data_0_alias), .io_w_req_bits_data_0_prefetch(vSRAMTemplate_185_io_w_req_bits_data_0_prefetch), .io_w_req_bits_data_0_prefetchSrc(vSRAMTemplate_185_io_w_req_bits_data_0_prefetchSrc), .io_w_req_bits_data_0_accessed(vSRAMTemplate_185_io_w_req_bits_data_0_accessed), .io_w_req_bits_data_0_tagErr(vSRAMTemplate_185_io_w_req_bits_data_0_tagErr), .io_w_req_bits_data_0_dataErr(vSRAMTemplate_185_io_w_req_bits_data_0_dataErr), .io_w_req_bits_data_1_dirty(vSRAMTemplate_185_io_w_req_bits_data_1_dirty), .io_w_req_bits_data_1_state(vSRAMTemplate_185_io_w_req_bits_data_1_state), .io_w_req_bits_data_1_clients(vSRAMTemplate_185_io_w_req_bits_data_1_clients), .io_w_req_bits_data_1_alias(vSRAMTemplate_185_io_w_req_bits_data_1_alias), .io_w_req_bits_data_1_prefetch(vSRAMTemplate_185_io_w_req_bits_data_1_prefetch), .io_w_req_bits_data_1_prefetchSrc(vSRAMTemplate_185_io_w_req_bits_data_1_prefetchSrc), .io_w_req_bits_data_1_accessed(vSRAMTemplate_185_io_w_req_bits_data_1_accessed), .io_w_req_bits_data_1_tagErr(vSRAMTemplate_185_io_w_req_bits_data_1_tagErr), .io_w_req_bits_data_1_dataErr(vSRAMTemplate_185_io_w_req_bits_data_1_dataErr), .io_w_req_bits_data_2_dirty(vSRAMTemplate_185_io_w_req_bits_data_2_dirty), .io_w_req_bits_data_2_state(vSRAMTemplate_185_io_w_req_bits_data_2_state), .io_w_req_bits_data_2_clients(vSRAMTemplate_185_io_w_req_bits_data_2_clients), .io_w_req_bits_data_2_alias(vSRAMTemplate_185_io_w_req_bits_data_2_alias), .io_w_req_bits_data_2_prefetch(vSRAMTemplate_185_io_w_req_bits_data_2_prefetch), .io_w_req_bits_data_2_prefetchSrc(vSRAMTemplate_185_io_w_req_bits_data_2_prefetchSrc), .io_w_req_bits_data_2_accessed(vSRAMTemplate_185_io_w_req_bits_data_2_accessed), .io_w_req_bits_data_2_tagErr(vSRAMTemplate_185_io_w_req_bits_data_2_tagErr), .io_w_req_bits_data_2_dataErr(vSRAMTemplate_185_io_w_req_bits_data_2_dataErr), .io_w_req_bits_data_3_dirty(vSRAMTemplate_185_io_w_req_bits_data_3_dirty), .io_w_req_bits_data_3_state(vSRAMTemplate_185_io_w_req_bits_data_3_state), .io_w_req_bits_data_3_clients(vSRAMTemplate_185_io_w_req_bits_data_3_clients), .io_w_req_bits_data_3_alias(vSRAMTemplate_185_io_w_req_bits_data_3_alias), .io_w_req_bits_data_3_prefetch(vSRAMTemplate_185_io_w_req_bits_data_3_prefetch), .io_w_req_bits_data_3_prefetchSrc(vSRAMTemplate_185_io_w_req_bits_data_3_prefetchSrc), .io_w_req_bits_data_3_accessed(vSRAMTemplate_185_io_w_req_bits_data_3_accessed), .io_w_req_bits_data_3_tagErr(vSRAMTemplate_185_io_w_req_bits_data_3_tagErr), .io_w_req_bits_data_3_dataErr(vSRAMTemplate_185_io_w_req_bits_data_3_dataErr), .io_w_req_bits_data_4_dirty(vSRAMTemplate_185_io_w_req_bits_data_4_dirty), .io_w_req_bits_data_4_state(vSRAMTemplate_185_io_w_req_bits_data_4_state), .io_w_req_bits_data_4_clients(vSRAMTemplate_185_io_w_req_bits_data_4_clients), .io_w_req_bits_data_4_alias(vSRAMTemplate_185_io_w_req_bits_data_4_alias), .io_w_req_bits_data_4_prefetch(vSRAMTemplate_185_io_w_req_bits_data_4_prefetch), .io_w_req_bits_data_4_prefetchSrc(vSRAMTemplate_185_io_w_req_bits_data_4_prefetchSrc), .io_w_req_bits_data_4_accessed(vSRAMTemplate_185_io_w_req_bits_data_4_accessed), .io_w_req_bits_data_4_tagErr(vSRAMTemplate_185_io_w_req_bits_data_4_tagErr), .io_w_req_bits_data_4_dataErr(vSRAMTemplate_185_io_w_req_bits_data_4_dataErr), .io_w_req_bits_data_5_dirty(vSRAMTemplate_185_io_w_req_bits_data_5_dirty), .io_w_req_bits_data_5_state(vSRAMTemplate_185_io_w_req_bits_data_5_state), .io_w_req_bits_data_5_clients(vSRAMTemplate_185_io_w_req_bits_data_5_clients), .io_w_req_bits_data_5_alias(vSRAMTemplate_185_io_w_req_bits_data_5_alias), .io_w_req_bits_data_5_prefetch(vSRAMTemplate_185_io_w_req_bits_data_5_prefetch), .io_w_req_bits_data_5_prefetchSrc(vSRAMTemplate_185_io_w_req_bits_data_5_prefetchSrc), .io_w_req_bits_data_5_accessed(vSRAMTemplate_185_io_w_req_bits_data_5_accessed), .io_w_req_bits_data_5_tagErr(vSRAMTemplate_185_io_w_req_bits_data_5_tagErr), .io_w_req_bits_data_5_dataErr(vSRAMTemplate_185_io_w_req_bits_data_5_dataErr), .io_w_req_bits_data_6_dirty(vSRAMTemplate_185_io_w_req_bits_data_6_dirty), .io_w_req_bits_data_6_state(vSRAMTemplate_185_io_w_req_bits_data_6_state), .io_w_req_bits_data_6_clients(vSRAMTemplate_185_io_w_req_bits_data_6_clients), .io_w_req_bits_data_6_alias(vSRAMTemplate_185_io_w_req_bits_data_6_alias), .io_w_req_bits_data_6_prefetch(vSRAMTemplate_185_io_w_req_bits_data_6_prefetch), .io_w_req_bits_data_6_prefetchSrc(vSRAMTemplate_185_io_w_req_bits_data_6_prefetchSrc), .io_w_req_bits_data_6_accessed(vSRAMTemplate_185_io_w_req_bits_data_6_accessed), .io_w_req_bits_data_6_tagErr(vSRAMTemplate_185_io_w_req_bits_data_6_tagErr), .io_w_req_bits_data_6_dataErr(vSRAMTemplate_185_io_w_req_bits_data_6_dataErr), .io_w_req_bits_data_7_dirty(vSRAMTemplate_185_io_w_req_bits_data_7_dirty), .io_w_req_bits_data_7_state(vSRAMTemplate_185_io_w_req_bits_data_7_state), .io_w_req_bits_data_7_clients(vSRAMTemplate_185_io_w_req_bits_data_7_clients), .io_w_req_bits_data_7_alias(vSRAMTemplate_185_io_w_req_bits_data_7_alias), .io_w_req_bits_data_7_prefetch(vSRAMTemplate_185_io_w_req_bits_data_7_prefetch), .io_w_req_bits_data_7_prefetchSrc(vSRAMTemplate_185_io_w_req_bits_data_7_prefetchSrc), .io_w_req_bits_data_7_accessed(vSRAMTemplate_185_io_w_req_bits_data_7_accessed), .io_w_req_bits_data_7_tagErr(vSRAMTemplate_185_io_w_req_bits_data_7_tagErr), .io_w_req_bits_data_7_dataErr(vSRAMTemplate_185_io_w_req_bits_data_7_dataErr), .io_w_req_bits_waymask(vSRAMTemplate_185_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_185_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_185_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_185_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_185_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_185_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_185_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_185_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_185_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_185_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_185_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_185_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_185_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_185_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_185_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_185_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_185_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_185_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_185_i_io_r_req_ready), .io_r_resp_data_0_dirty(vSRAMTemplate_185_i_io_r_resp_data_0_dirty), .io_r_resp_data_0_state(vSRAMTemplate_185_i_io_r_resp_data_0_state), .io_r_resp_data_0_clients(vSRAMTemplate_185_i_io_r_resp_data_0_clients), .io_r_resp_data_0_alias(vSRAMTemplate_185_i_io_r_resp_data_0_alias), .io_r_resp_data_0_prefetch(vSRAMTemplate_185_i_io_r_resp_data_0_prefetch), .io_r_resp_data_0_prefetchSrc(vSRAMTemplate_185_i_io_r_resp_data_0_prefetchSrc), .io_r_resp_data_0_accessed(vSRAMTemplate_185_i_io_r_resp_data_0_accessed), .io_r_resp_data_0_tagErr(vSRAMTemplate_185_i_io_r_resp_data_0_tagErr), .io_r_resp_data_0_dataErr(vSRAMTemplate_185_i_io_r_resp_data_0_dataErr), .io_r_resp_data_1_dirty(vSRAMTemplate_185_i_io_r_resp_data_1_dirty), .io_r_resp_data_1_state(vSRAMTemplate_185_i_io_r_resp_data_1_state), .io_r_resp_data_1_clients(vSRAMTemplate_185_i_io_r_resp_data_1_clients), .io_r_resp_data_1_alias(vSRAMTemplate_185_i_io_r_resp_data_1_alias), .io_r_resp_data_1_prefetch(vSRAMTemplate_185_i_io_r_resp_data_1_prefetch), .io_r_resp_data_1_prefetchSrc(vSRAMTemplate_185_i_io_r_resp_data_1_prefetchSrc), .io_r_resp_data_1_accessed(vSRAMTemplate_185_i_io_r_resp_data_1_accessed), .io_r_resp_data_1_tagErr(vSRAMTemplate_185_i_io_r_resp_data_1_tagErr), .io_r_resp_data_1_dataErr(vSRAMTemplate_185_i_io_r_resp_data_1_dataErr), .io_r_resp_data_2_dirty(vSRAMTemplate_185_i_io_r_resp_data_2_dirty), .io_r_resp_data_2_state(vSRAMTemplate_185_i_io_r_resp_data_2_state), .io_r_resp_data_2_clients(vSRAMTemplate_185_i_io_r_resp_data_2_clients), .io_r_resp_data_2_alias(vSRAMTemplate_185_i_io_r_resp_data_2_alias), .io_r_resp_data_2_prefetch(vSRAMTemplate_185_i_io_r_resp_data_2_prefetch), .io_r_resp_data_2_prefetchSrc(vSRAMTemplate_185_i_io_r_resp_data_2_prefetchSrc), .io_r_resp_data_2_accessed(vSRAMTemplate_185_i_io_r_resp_data_2_accessed), .io_r_resp_data_2_tagErr(vSRAMTemplate_185_i_io_r_resp_data_2_tagErr), .io_r_resp_data_2_dataErr(vSRAMTemplate_185_i_io_r_resp_data_2_dataErr), .io_r_resp_data_3_dirty(vSRAMTemplate_185_i_io_r_resp_data_3_dirty), .io_r_resp_data_3_state(vSRAMTemplate_185_i_io_r_resp_data_3_state), .io_r_resp_data_3_clients(vSRAMTemplate_185_i_io_r_resp_data_3_clients), .io_r_resp_data_3_alias(vSRAMTemplate_185_i_io_r_resp_data_3_alias), .io_r_resp_data_3_prefetch(vSRAMTemplate_185_i_io_r_resp_data_3_prefetch), .io_r_resp_data_3_prefetchSrc(vSRAMTemplate_185_i_io_r_resp_data_3_prefetchSrc), .io_r_resp_data_3_accessed(vSRAMTemplate_185_i_io_r_resp_data_3_accessed), .io_r_resp_data_3_tagErr(vSRAMTemplate_185_i_io_r_resp_data_3_tagErr), .io_r_resp_data_3_dataErr(vSRAMTemplate_185_i_io_r_resp_data_3_dataErr), .io_r_resp_data_4_dirty(vSRAMTemplate_185_i_io_r_resp_data_4_dirty), .io_r_resp_data_4_state(vSRAMTemplate_185_i_io_r_resp_data_4_state), .io_r_resp_data_4_clients(vSRAMTemplate_185_i_io_r_resp_data_4_clients), .io_r_resp_data_4_alias(vSRAMTemplate_185_i_io_r_resp_data_4_alias), .io_r_resp_data_4_prefetch(vSRAMTemplate_185_i_io_r_resp_data_4_prefetch), .io_r_resp_data_4_prefetchSrc(vSRAMTemplate_185_i_io_r_resp_data_4_prefetchSrc), .io_r_resp_data_4_accessed(vSRAMTemplate_185_i_io_r_resp_data_4_accessed), .io_r_resp_data_4_tagErr(vSRAMTemplate_185_i_io_r_resp_data_4_tagErr), .io_r_resp_data_4_dataErr(vSRAMTemplate_185_i_io_r_resp_data_4_dataErr), .io_r_resp_data_5_dirty(vSRAMTemplate_185_i_io_r_resp_data_5_dirty), .io_r_resp_data_5_state(vSRAMTemplate_185_i_io_r_resp_data_5_state), .io_r_resp_data_5_clients(vSRAMTemplate_185_i_io_r_resp_data_5_clients), .io_r_resp_data_5_alias(vSRAMTemplate_185_i_io_r_resp_data_5_alias), .io_r_resp_data_5_prefetch(vSRAMTemplate_185_i_io_r_resp_data_5_prefetch), .io_r_resp_data_5_prefetchSrc(vSRAMTemplate_185_i_io_r_resp_data_5_prefetchSrc), .io_r_resp_data_5_accessed(vSRAMTemplate_185_i_io_r_resp_data_5_accessed), .io_r_resp_data_5_tagErr(vSRAMTemplate_185_i_io_r_resp_data_5_tagErr), .io_r_resp_data_5_dataErr(vSRAMTemplate_185_i_io_r_resp_data_5_dataErr), .io_r_resp_data_6_dirty(vSRAMTemplate_185_i_io_r_resp_data_6_dirty), .io_r_resp_data_6_state(vSRAMTemplate_185_i_io_r_resp_data_6_state), .io_r_resp_data_6_clients(vSRAMTemplate_185_i_io_r_resp_data_6_clients), .io_r_resp_data_6_alias(vSRAMTemplate_185_i_io_r_resp_data_6_alias), .io_r_resp_data_6_prefetch(vSRAMTemplate_185_i_io_r_resp_data_6_prefetch), .io_r_resp_data_6_prefetchSrc(vSRAMTemplate_185_i_io_r_resp_data_6_prefetchSrc), .io_r_resp_data_6_accessed(vSRAMTemplate_185_i_io_r_resp_data_6_accessed), .io_r_resp_data_6_tagErr(vSRAMTemplate_185_i_io_r_resp_data_6_tagErr), .io_r_resp_data_6_dataErr(vSRAMTemplate_185_i_io_r_resp_data_6_dataErr), .io_r_resp_data_7_dirty(vSRAMTemplate_185_i_io_r_resp_data_7_dirty), .io_r_resp_data_7_state(vSRAMTemplate_185_i_io_r_resp_data_7_state), .io_r_resp_data_7_clients(vSRAMTemplate_185_i_io_r_resp_data_7_clients), .io_r_resp_data_7_alias(vSRAMTemplate_185_i_io_r_resp_data_7_alias), .io_r_resp_data_7_prefetch(vSRAMTemplate_185_i_io_r_resp_data_7_prefetch), .io_r_resp_data_7_prefetchSrc(vSRAMTemplate_185_i_io_r_resp_data_7_prefetchSrc), .io_r_resp_data_7_accessed(vSRAMTemplate_185_i_io_r_resp_data_7_accessed), .io_r_resp_data_7_tagErr(vSRAMTemplate_185_i_io_r_resp_data_7_tagErr), .io_r_resp_data_7_dataErr(vSRAMTemplate_185_i_io_r_resp_data_7_dataErr), .io_w_req_ready(vSRAMTemplate_185_i_io_w_req_ready), .io_resetDone(vSRAMTemplate_185_i_io_resetDone), .boreChildrenBd_bore_rdata(vSRAMTemplate_185_i_boreChildrenBd_bore_rdata));
  int vSRAMTemplate_185_cov_w = 0, vSRAMTemplate_185_cov_rw_same = 0, vSRAMTemplate_185_cov_cgoff = 0, vSRAMTemplate_185_cov_bore_w = 0, vSRAMTemplate_185_cov_bore_r = 0, vSRAMTemplate_185_cov_hold = 0, vSRAMTemplate_185_cov_rd_known = 0, vSRAMTemplate_185_cov_rd_nonzero = 0, vSRAMTemplate_185_cov_m0 = 0, vSRAMTemplate_185_cov_m1 = 0, vSRAMTemplate_185_cov_mmix = 0;
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_185_io_r_req_valid <= 1'b0;
      vSRAMTemplate_185_io_w_req_valid <= 1'b0;
      vSRAMTemplate_185_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_185_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_185_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_185_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_185_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_185_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_185_io_r_req_bits_setIdx <= ($urandom_range(0,3)!=0) ? 9'($urandom_range(0,7)) : 9'($urandom);
      vSRAMTemplate_185_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_185_io_w_req_bits_setIdx <= ($urandom_range(0,3)!=0) ? 9'($urandom_range(0,7)) : 9'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_0_dirty <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_0_state <= 2'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_0_clients <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_0_alias <= 2'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_0_prefetch <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_0_prefetchSrc <= 3'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_0_accessed <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_0_tagErr <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_0_dataErr <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_1_dirty <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_1_state <= 2'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_1_clients <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_1_alias <= 2'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_1_prefetch <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_1_prefetchSrc <= 3'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_1_accessed <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_1_tagErr <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_1_dataErr <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_2_dirty <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_2_state <= 2'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_2_clients <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_2_alias <= 2'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_2_prefetch <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_2_prefetchSrc <= 3'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_2_accessed <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_2_tagErr <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_2_dataErr <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_3_dirty <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_3_state <= 2'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_3_clients <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_3_alias <= 2'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_3_prefetch <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_3_prefetchSrc <= 3'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_3_accessed <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_3_tagErr <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_3_dataErr <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_4_dirty <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_4_state <= 2'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_4_clients <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_4_alias <= 2'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_4_prefetch <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_4_prefetchSrc <= 3'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_4_accessed <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_4_tagErr <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_4_dataErr <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_5_dirty <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_5_state <= 2'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_5_clients <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_5_alias <= 2'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_5_prefetch <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_5_prefetchSrc <= 3'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_5_accessed <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_5_tagErr <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_5_dataErr <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_6_dirty <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_6_state <= 2'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_6_clients <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_6_alias <= 2'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_6_prefetch <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_6_prefetchSrc <= 3'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_6_accessed <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_6_tagErr <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_6_dataErr <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_7_dirty <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_7_state <= 2'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_7_clients <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_7_alias <= 2'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_7_prefetch <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_7_prefetchSrc <= 3'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_7_accessed <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_7_tagErr <= 1'($urandom);
      vSRAMTemplate_185_io_w_req_bits_data_7_dataErr <= 1'($urandom);
      case ($urandom_range(0,2))   // 全 0 / 全 1 / 混合 各 1/3
        0: vSRAMTemplate_185_io_w_req_bits_waymask <= 8'b0;
        1: vSRAMTemplate_185_io_w_req_bits_waymask <= {8{1'b1}};
        default: vSRAMTemplate_185_io_w_req_bits_waymask <= 8'($urandom);
      endcase
      vSRAMTemplate_185_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_185_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_185_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_185_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_185_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_185_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_185_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_185_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_185_boreChildrenBd_bore_addr <= 10'($urandom);
      vSRAMTemplate_185_boreChildrenBd_bore_addr_rd <= 10'($urandom);
      vSRAMTemplate_185_boreChildrenBd_bore_wdata <= 104'({$urandom(), $urandom(), $urandom(), $urandom()});
      vSRAMTemplate_185_boreChildrenBd_bore_wmask <= 8'($urandom);
      vSRAMTemplate_185_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_185_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_185_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_185_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_185_boreChildrenBd_bore_array <= 6'($urandom);
    end
  end
  always @(posedge clk) if (!rst && cycle > WARMUP) begin
    if (vSRAMTemplate_185_io_w_req_valid && !vSRAMTemplate_185_io_broadcast_ram_hold) vSRAMTemplate_185_cov_w++;
    if (vSRAMTemplate_185_io_w_req_valid && vSRAMTemplate_185_io_r_req_valid && vSRAMTemplate_185_io_w_req_bits_setIdx == vSRAMTemplate_185_io_r_req_bits_setIdx) vSRAMTemplate_185_cov_rw_same++;
    if (!vSRAMTemplate_185_io_w_req_valid && !vSRAMTemplate_185_io_r_req_valid && !vSRAMTemplate_185_boreChildrenBd_bore_ack) vSRAMTemplate_185_cov_cgoff++;
    if (vSRAMTemplate_185_boreChildrenBd_bore_ack && vSRAMTemplate_185_boreChildrenBd_bore_we) vSRAMTemplate_185_cov_bore_w++;
    if (vSRAMTemplate_185_boreChildrenBd_bore_ack && vSRAMTemplate_185_boreChildrenBd_bore_re) vSRAMTemplate_185_cov_bore_r++;
    if (vSRAMTemplate_185_io_broadcast_ram_hold) vSRAMTemplate_185_cov_hold++;
    if (vSRAMTemplate_185_io_w_req_valid) begin
      if (vSRAMTemplate_185_io_w_req_bits_waymask == 8'b0)      vSRAMTemplate_185_cov_m0++;
      else if (&vSRAMTemplate_185_io_w_req_bits_waymask)            vSRAMTemplate_185_cov_m1++;
      else                                  vSRAMTemplate_185_cov_mmix++;
    end
    if (!has_x({vSRAMTemplate_185_g_io_r_resp_data_0_dirty, vSRAMTemplate_185_g_io_r_resp_data_0_state, vSRAMTemplate_185_g_io_r_resp_data_0_clients, vSRAMTemplate_185_g_io_r_resp_data_0_alias, vSRAMTemplate_185_g_io_r_resp_data_0_prefetch, vSRAMTemplate_185_g_io_r_resp_data_0_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_0_accessed, vSRAMTemplate_185_g_io_r_resp_data_0_tagErr, vSRAMTemplate_185_g_io_r_resp_data_0_dataErr, vSRAMTemplate_185_g_io_r_resp_data_1_dirty, vSRAMTemplate_185_g_io_r_resp_data_1_state, vSRAMTemplate_185_g_io_r_resp_data_1_clients, vSRAMTemplate_185_g_io_r_resp_data_1_alias, vSRAMTemplate_185_g_io_r_resp_data_1_prefetch, vSRAMTemplate_185_g_io_r_resp_data_1_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_1_accessed, vSRAMTemplate_185_g_io_r_resp_data_1_tagErr, vSRAMTemplate_185_g_io_r_resp_data_1_dataErr, vSRAMTemplate_185_g_io_r_resp_data_2_dirty, vSRAMTemplate_185_g_io_r_resp_data_2_state, vSRAMTemplate_185_g_io_r_resp_data_2_clients, vSRAMTemplate_185_g_io_r_resp_data_2_alias, vSRAMTemplate_185_g_io_r_resp_data_2_prefetch, vSRAMTemplate_185_g_io_r_resp_data_2_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_2_accessed, vSRAMTemplate_185_g_io_r_resp_data_2_tagErr, vSRAMTemplate_185_g_io_r_resp_data_2_dataErr, vSRAMTemplate_185_g_io_r_resp_data_3_dirty, vSRAMTemplate_185_g_io_r_resp_data_3_state, vSRAMTemplate_185_g_io_r_resp_data_3_clients, vSRAMTemplate_185_g_io_r_resp_data_3_alias, vSRAMTemplate_185_g_io_r_resp_data_3_prefetch, vSRAMTemplate_185_g_io_r_resp_data_3_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_3_accessed, vSRAMTemplate_185_g_io_r_resp_data_3_tagErr, vSRAMTemplate_185_g_io_r_resp_data_3_dataErr, vSRAMTemplate_185_g_io_r_resp_data_4_dirty, vSRAMTemplate_185_g_io_r_resp_data_4_state, vSRAMTemplate_185_g_io_r_resp_data_4_clients, vSRAMTemplate_185_g_io_r_resp_data_4_alias, vSRAMTemplate_185_g_io_r_resp_data_4_prefetch, vSRAMTemplate_185_g_io_r_resp_data_4_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_4_accessed, vSRAMTemplate_185_g_io_r_resp_data_4_tagErr, vSRAMTemplate_185_g_io_r_resp_data_4_dataErr, vSRAMTemplate_185_g_io_r_resp_data_5_dirty, vSRAMTemplate_185_g_io_r_resp_data_5_state, vSRAMTemplate_185_g_io_r_resp_data_5_clients, vSRAMTemplate_185_g_io_r_resp_data_5_alias, vSRAMTemplate_185_g_io_r_resp_data_5_prefetch, vSRAMTemplate_185_g_io_r_resp_data_5_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_5_accessed, vSRAMTemplate_185_g_io_r_resp_data_5_tagErr, vSRAMTemplate_185_g_io_r_resp_data_5_dataErr, vSRAMTemplate_185_g_io_r_resp_data_6_dirty, vSRAMTemplate_185_g_io_r_resp_data_6_state, vSRAMTemplate_185_g_io_r_resp_data_6_clients, vSRAMTemplate_185_g_io_r_resp_data_6_alias, vSRAMTemplate_185_g_io_r_resp_data_6_prefetch, vSRAMTemplate_185_g_io_r_resp_data_6_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_6_accessed, vSRAMTemplate_185_g_io_r_resp_data_6_tagErr, vSRAMTemplate_185_g_io_r_resp_data_6_dataErr, vSRAMTemplate_185_g_io_r_resp_data_7_dirty, vSRAMTemplate_185_g_io_r_resp_data_7_state, vSRAMTemplate_185_g_io_r_resp_data_7_clients, vSRAMTemplate_185_g_io_r_resp_data_7_alias, vSRAMTemplate_185_g_io_r_resp_data_7_prefetch, vSRAMTemplate_185_g_io_r_resp_data_7_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_7_accessed, vSRAMTemplate_185_g_io_r_resp_data_7_tagErr, vSRAMTemplate_185_g_io_r_resp_data_7_dataErr}, 104) && !has_z({vSRAMTemplate_185_g_io_r_resp_data_0_dirty, vSRAMTemplate_185_g_io_r_resp_data_0_state, vSRAMTemplate_185_g_io_r_resp_data_0_clients, vSRAMTemplate_185_g_io_r_resp_data_0_alias, vSRAMTemplate_185_g_io_r_resp_data_0_prefetch, vSRAMTemplate_185_g_io_r_resp_data_0_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_0_accessed, vSRAMTemplate_185_g_io_r_resp_data_0_tagErr, vSRAMTemplate_185_g_io_r_resp_data_0_dataErr, vSRAMTemplate_185_g_io_r_resp_data_1_dirty, vSRAMTemplate_185_g_io_r_resp_data_1_state, vSRAMTemplate_185_g_io_r_resp_data_1_clients, vSRAMTemplate_185_g_io_r_resp_data_1_alias, vSRAMTemplate_185_g_io_r_resp_data_1_prefetch, vSRAMTemplate_185_g_io_r_resp_data_1_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_1_accessed, vSRAMTemplate_185_g_io_r_resp_data_1_tagErr, vSRAMTemplate_185_g_io_r_resp_data_1_dataErr, vSRAMTemplate_185_g_io_r_resp_data_2_dirty, vSRAMTemplate_185_g_io_r_resp_data_2_state, vSRAMTemplate_185_g_io_r_resp_data_2_clients, vSRAMTemplate_185_g_io_r_resp_data_2_alias, vSRAMTemplate_185_g_io_r_resp_data_2_prefetch, vSRAMTemplate_185_g_io_r_resp_data_2_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_2_accessed, vSRAMTemplate_185_g_io_r_resp_data_2_tagErr, vSRAMTemplate_185_g_io_r_resp_data_2_dataErr, vSRAMTemplate_185_g_io_r_resp_data_3_dirty, vSRAMTemplate_185_g_io_r_resp_data_3_state, vSRAMTemplate_185_g_io_r_resp_data_3_clients, vSRAMTemplate_185_g_io_r_resp_data_3_alias, vSRAMTemplate_185_g_io_r_resp_data_3_prefetch, vSRAMTemplate_185_g_io_r_resp_data_3_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_3_accessed, vSRAMTemplate_185_g_io_r_resp_data_3_tagErr, vSRAMTemplate_185_g_io_r_resp_data_3_dataErr, vSRAMTemplate_185_g_io_r_resp_data_4_dirty, vSRAMTemplate_185_g_io_r_resp_data_4_state, vSRAMTemplate_185_g_io_r_resp_data_4_clients, vSRAMTemplate_185_g_io_r_resp_data_4_alias, vSRAMTemplate_185_g_io_r_resp_data_4_prefetch, vSRAMTemplate_185_g_io_r_resp_data_4_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_4_accessed, vSRAMTemplate_185_g_io_r_resp_data_4_tagErr, vSRAMTemplate_185_g_io_r_resp_data_4_dataErr, vSRAMTemplate_185_g_io_r_resp_data_5_dirty, vSRAMTemplate_185_g_io_r_resp_data_5_state, vSRAMTemplate_185_g_io_r_resp_data_5_clients, vSRAMTemplate_185_g_io_r_resp_data_5_alias, vSRAMTemplate_185_g_io_r_resp_data_5_prefetch, vSRAMTemplate_185_g_io_r_resp_data_5_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_5_accessed, vSRAMTemplate_185_g_io_r_resp_data_5_tagErr, vSRAMTemplate_185_g_io_r_resp_data_5_dataErr, vSRAMTemplate_185_g_io_r_resp_data_6_dirty, vSRAMTemplate_185_g_io_r_resp_data_6_state, vSRAMTemplate_185_g_io_r_resp_data_6_clients, vSRAMTemplate_185_g_io_r_resp_data_6_alias, vSRAMTemplate_185_g_io_r_resp_data_6_prefetch, vSRAMTemplate_185_g_io_r_resp_data_6_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_6_accessed, vSRAMTemplate_185_g_io_r_resp_data_6_tagErr, vSRAMTemplate_185_g_io_r_resp_data_6_dataErr, vSRAMTemplate_185_g_io_r_resp_data_7_dirty, vSRAMTemplate_185_g_io_r_resp_data_7_state, vSRAMTemplate_185_g_io_r_resp_data_7_clients, vSRAMTemplate_185_g_io_r_resp_data_7_alias, vSRAMTemplate_185_g_io_r_resp_data_7_prefetch, vSRAMTemplate_185_g_io_r_resp_data_7_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_7_accessed, vSRAMTemplate_185_g_io_r_resp_data_7_tagErr, vSRAMTemplate_185_g_io_r_resp_data_7_dataErr}, 104)) begin
      vSRAMTemplate_185_cov_rd_known++;
      if (|{vSRAMTemplate_185_g_io_r_resp_data_0_dirty, vSRAMTemplate_185_g_io_r_resp_data_0_state, vSRAMTemplate_185_g_io_r_resp_data_0_clients, vSRAMTemplate_185_g_io_r_resp_data_0_alias, vSRAMTemplate_185_g_io_r_resp_data_0_prefetch, vSRAMTemplate_185_g_io_r_resp_data_0_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_0_accessed, vSRAMTemplate_185_g_io_r_resp_data_0_tagErr, vSRAMTemplate_185_g_io_r_resp_data_0_dataErr, vSRAMTemplate_185_g_io_r_resp_data_1_dirty, vSRAMTemplate_185_g_io_r_resp_data_1_state, vSRAMTemplate_185_g_io_r_resp_data_1_clients, vSRAMTemplate_185_g_io_r_resp_data_1_alias, vSRAMTemplate_185_g_io_r_resp_data_1_prefetch, vSRAMTemplate_185_g_io_r_resp_data_1_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_1_accessed, vSRAMTemplate_185_g_io_r_resp_data_1_tagErr, vSRAMTemplate_185_g_io_r_resp_data_1_dataErr, vSRAMTemplate_185_g_io_r_resp_data_2_dirty, vSRAMTemplate_185_g_io_r_resp_data_2_state, vSRAMTemplate_185_g_io_r_resp_data_2_clients, vSRAMTemplate_185_g_io_r_resp_data_2_alias, vSRAMTemplate_185_g_io_r_resp_data_2_prefetch, vSRAMTemplate_185_g_io_r_resp_data_2_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_2_accessed, vSRAMTemplate_185_g_io_r_resp_data_2_tagErr, vSRAMTemplate_185_g_io_r_resp_data_2_dataErr, vSRAMTemplate_185_g_io_r_resp_data_3_dirty, vSRAMTemplate_185_g_io_r_resp_data_3_state, vSRAMTemplate_185_g_io_r_resp_data_3_clients, vSRAMTemplate_185_g_io_r_resp_data_3_alias, vSRAMTemplate_185_g_io_r_resp_data_3_prefetch, vSRAMTemplate_185_g_io_r_resp_data_3_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_3_accessed, vSRAMTemplate_185_g_io_r_resp_data_3_tagErr, vSRAMTemplate_185_g_io_r_resp_data_3_dataErr, vSRAMTemplate_185_g_io_r_resp_data_4_dirty, vSRAMTemplate_185_g_io_r_resp_data_4_state, vSRAMTemplate_185_g_io_r_resp_data_4_clients, vSRAMTemplate_185_g_io_r_resp_data_4_alias, vSRAMTemplate_185_g_io_r_resp_data_4_prefetch, vSRAMTemplate_185_g_io_r_resp_data_4_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_4_accessed, vSRAMTemplate_185_g_io_r_resp_data_4_tagErr, vSRAMTemplate_185_g_io_r_resp_data_4_dataErr, vSRAMTemplate_185_g_io_r_resp_data_5_dirty, vSRAMTemplate_185_g_io_r_resp_data_5_state, vSRAMTemplate_185_g_io_r_resp_data_5_clients, vSRAMTemplate_185_g_io_r_resp_data_5_alias, vSRAMTemplate_185_g_io_r_resp_data_5_prefetch, vSRAMTemplate_185_g_io_r_resp_data_5_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_5_accessed, vSRAMTemplate_185_g_io_r_resp_data_5_tagErr, vSRAMTemplate_185_g_io_r_resp_data_5_dataErr, vSRAMTemplate_185_g_io_r_resp_data_6_dirty, vSRAMTemplate_185_g_io_r_resp_data_6_state, vSRAMTemplate_185_g_io_r_resp_data_6_clients, vSRAMTemplate_185_g_io_r_resp_data_6_alias, vSRAMTemplate_185_g_io_r_resp_data_6_prefetch, vSRAMTemplate_185_g_io_r_resp_data_6_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_6_accessed, vSRAMTemplate_185_g_io_r_resp_data_6_tagErr, vSRAMTemplate_185_g_io_r_resp_data_6_dataErr, vSRAMTemplate_185_g_io_r_resp_data_7_dirty, vSRAMTemplate_185_g_io_r_resp_data_7_state, vSRAMTemplate_185_g_io_r_resp_data_7_clients, vSRAMTemplate_185_g_io_r_resp_data_7_alias, vSRAMTemplate_185_g_io_r_resp_data_7_prefetch, vSRAMTemplate_185_g_io_r_resp_data_7_prefetchSrc, vSRAMTemplate_185_g_io_r_resp_data_7_accessed, vSRAMTemplate_185_g_io_r_resp_data_7_tagErr, vSRAMTemplate_185_g_io_r_resp_data_7_dataErr}) vSRAMTemplate_185_cov_rd_nonzero++;
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_185_g_io_r_req_ready !== vSRAMTemplate_185_i_io_r_req_ready) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_req_ready g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_req_ready, vSRAMTemplate_185_i_io_r_req_ready); end
    if (has_z(vSRAMTemplate_185_g_io_r_req_ready, 1) || has_z(vSRAMTemplate_185_i_io_r_req_ready, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_req_ready g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_req_ready, vSRAMTemplate_185_i_io_r_req_ready); end
    if (vSRAMTemplate_185_g_io_r_resp_data_0_dirty !== vSRAMTemplate_185_i_io_r_resp_data_0_dirty) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_0_dirty g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_dirty, vSRAMTemplate_185_i_io_r_resp_data_0_dirty); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_0_dirty, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_0_dirty, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_0_dirty g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_dirty, vSRAMTemplate_185_i_io_r_resp_data_0_dirty); end
    if (vSRAMTemplate_185_g_io_r_resp_data_0_state !== vSRAMTemplate_185_i_io_r_resp_data_0_state) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_0_state g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_state, vSRAMTemplate_185_i_io_r_resp_data_0_state); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_0_state, 2) || has_z(vSRAMTemplate_185_i_io_r_resp_data_0_state, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_0_state g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_state, vSRAMTemplate_185_i_io_r_resp_data_0_state); end
    if (vSRAMTemplate_185_g_io_r_resp_data_0_clients !== vSRAMTemplate_185_i_io_r_resp_data_0_clients) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_0_clients g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_clients, vSRAMTemplate_185_i_io_r_resp_data_0_clients); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_0_clients, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_0_clients, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_0_clients g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_clients, vSRAMTemplate_185_i_io_r_resp_data_0_clients); end
    if (vSRAMTemplate_185_g_io_r_resp_data_0_alias !== vSRAMTemplate_185_i_io_r_resp_data_0_alias) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_0_alias g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_alias, vSRAMTemplate_185_i_io_r_resp_data_0_alias); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_0_alias, 2) || has_z(vSRAMTemplate_185_i_io_r_resp_data_0_alias, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_0_alias g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_alias, vSRAMTemplate_185_i_io_r_resp_data_0_alias); end
    if (vSRAMTemplate_185_g_io_r_resp_data_0_prefetch !== vSRAMTemplate_185_i_io_r_resp_data_0_prefetch) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_0_prefetch g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_prefetch, vSRAMTemplate_185_i_io_r_resp_data_0_prefetch); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_0_prefetch, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_0_prefetch, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_0_prefetch g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_prefetch, vSRAMTemplate_185_i_io_r_resp_data_0_prefetch); end
    if (vSRAMTemplate_185_g_io_r_resp_data_0_prefetchSrc !== vSRAMTemplate_185_i_io_r_resp_data_0_prefetchSrc) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_0_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_prefetchSrc, vSRAMTemplate_185_i_io_r_resp_data_0_prefetchSrc); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_0_prefetchSrc, 3) || has_z(vSRAMTemplate_185_i_io_r_resp_data_0_prefetchSrc, 3)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_0_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_prefetchSrc, vSRAMTemplate_185_i_io_r_resp_data_0_prefetchSrc); end
    if (vSRAMTemplate_185_g_io_r_resp_data_0_accessed !== vSRAMTemplate_185_i_io_r_resp_data_0_accessed) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_0_accessed g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_accessed, vSRAMTemplate_185_i_io_r_resp_data_0_accessed); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_0_accessed, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_0_accessed, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_0_accessed g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_accessed, vSRAMTemplate_185_i_io_r_resp_data_0_accessed); end
    if (vSRAMTemplate_185_g_io_r_resp_data_0_tagErr !== vSRAMTemplate_185_i_io_r_resp_data_0_tagErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_0_tagErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_tagErr, vSRAMTemplate_185_i_io_r_resp_data_0_tagErr); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_0_tagErr, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_0_tagErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_0_tagErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_tagErr, vSRAMTemplate_185_i_io_r_resp_data_0_tagErr); end
    if (vSRAMTemplate_185_g_io_r_resp_data_0_dataErr !== vSRAMTemplate_185_i_io_r_resp_data_0_dataErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_0_dataErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_dataErr, vSRAMTemplate_185_i_io_r_resp_data_0_dataErr); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_0_dataErr, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_0_dataErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_0_dataErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_0_dataErr, vSRAMTemplate_185_i_io_r_resp_data_0_dataErr); end
    if (vSRAMTemplate_185_g_io_r_resp_data_1_dirty !== vSRAMTemplate_185_i_io_r_resp_data_1_dirty) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_1_dirty g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_dirty, vSRAMTemplate_185_i_io_r_resp_data_1_dirty); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_1_dirty, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_1_dirty, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_1_dirty g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_dirty, vSRAMTemplate_185_i_io_r_resp_data_1_dirty); end
    if (vSRAMTemplate_185_g_io_r_resp_data_1_state !== vSRAMTemplate_185_i_io_r_resp_data_1_state) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_1_state g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_state, vSRAMTemplate_185_i_io_r_resp_data_1_state); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_1_state, 2) || has_z(vSRAMTemplate_185_i_io_r_resp_data_1_state, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_1_state g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_state, vSRAMTemplate_185_i_io_r_resp_data_1_state); end
    if (vSRAMTemplate_185_g_io_r_resp_data_1_clients !== vSRAMTemplate_185_i_io_r_resp_data_1_clients) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_1_clients g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_clients, vSRAMTemplate_185_i_io_r_resp_data_1_clients); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_1_clients, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_1_clients, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_1_clients g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_clients, vSRAMTemplate_185_i_io_r_resp_data_1_clients); end
    if (vSRAMTemplate_185_g_io_r_resp_data_1_alias !== vSRAMTemplate_185_i_io_r_resp_data_1_alias) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_1_alias g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_alias, vSRAMTemplate_185_i_io_r_resp_data_1_alias); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_1_alias, 2) || has_z(vSRAMTemplate_185_i_io_r_resp_data_1_alias, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_1_alias g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_alias, vSRAMTemplate_185_i_io_r_resp_data_1_alias); end
    if (vSRAMTemplate_185_g_io_r_resp_data_1_prefetch !== vSRAMTemplate_185_i_io_r_resp_data_1_prefetch) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_1_prefetch g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_prefetch, vSRAMTemplate_185_i_io_r_resp_data_1_prefetch); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_1_prefetch, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_1_prefetch, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_1_prefetch g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_prefetch, vSRAMTemplate_185_i_io_r_resp_data_1_prefetch); end
    if (vSRAMTemplate_185_g_io_r_resp_data_1_prefetchSrc !== vSRAMTemplate_185_i_io_r_resp_data_1_prefetchSrc) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_1_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_prefetchSrc, vSRAMTemplate_185_i_io_r_resp_data_1_prefetchSrc); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_1_prefetchSrc, 3) || has_z(vSRAMTemplate_185_i_io_r_resp_data_1_prefetchSrc, 3)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_1_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_prefetchSrc, vSRAMTemplate_185_i_io_r_resp_data_1_prefetchSrc); end
    if (vSRAMTemplate_185_g_io_r_resp_data_1_accessed !== vSRAMTemplate_185_i_io_r_resp_data_1_accessed) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_1_accessed g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_accessed, vSRAMTemplate_185_i_io_r_resp_data_1_accessed); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_1_accessed, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_1_accessed, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_1_accessed g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_accessed, vSRAMTemplate_185_i_io_r_resp_data_1_accessed); end
    if (vSRAMTemplate_185_g_io_r_resp_data_1_tagErr !== vSRAMTemplate_185_i_io_r_resp_data_1_tagErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_1_tagErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_tagErr, vSRAMTemplate_185_i_io_r_resp_data_1_tagErr); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_1_tagErr, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_1_tagErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_1_tagErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_tagErr, vSRAMTemplate_185_i_io_r_resp_data_1_tagErr); end
    if (vSRAMTemplate_185_g_io_r_resp_data_1_dataErr !== vSRAMTemplate_185_i_io_r_resp_data_1_dataErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_1_dataErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_dataErr, vSRAMTemplate_185_i_io_r_resp_data_1_dataErr); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_1_dataErr, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_1_dataErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_1_dataErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_1_dataErr, vSRAMTemplate_185_i_io_r_resp_data_1_dataErr); end
    if (vSRAMTemplate_185_g_io_r_resp_data_2_dirty !== vSRAMTemplate_185_i_io_r_resp_data_2_dirty) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_2_dirty g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_dirty, vSRAMTemplate_185_i_io_r_resp_data_2_dirty); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_2_dirty, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_2_dirty, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_2_dirty g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_dirty, vSRAMTemplate_185_i_io_r_resp_data_2_dirty); end
    if (vSRAMTemplate_185_g_io_r_resp_data_2_state !== vSRAMTemplate_185_i_io_r_resp_data_2_state) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_2_state g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_state, vSRAMTemplate_185_i_io_r_resp_data_2_state); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_2_state, 2) || has_z(vSRAMTemplate_185_i_io_r_resp_data_2_state, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_2_state g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_state, vSRAMTemplate_185_i_io_r_resp_data_2_state); end
    if (vSRAMTemplate_185_g_io_r_resp_data_2_clients !== vSRAMTemplate_185_i_io_r_resp_data_2_clients) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_2_clients g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_clients, vSRAMTemplate_185_i_io_r_resp_data_2_clients); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_2_clients, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_2_clients, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_2_clients g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_clients, vSRAMTemplate_185_i_io_r_resp_data_2_clients); end
    if (vSRAMTemplate_185_g_io_r_resp_data_2_alias !== vSRAMTemplate_185_i_io_r_resp_data_2_alias) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_2_alias g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_alias, vSRAMTemplate_185_i_io_r_resp_data_2_alias); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_2_alias, 2) || has_z(vSRAMTemplate_185_i_io_r_resp_data_2_alias, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_2_alias g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_alias, vSRAMTemplate_185_i_io_r_resp_data_2_alias); end
    if (vSRAMTemplate_185_g_io_r_resp_data_2_prefetch !== vSRAMTemplate_185_i_io_r_resp_data_2_prefetch) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_2_prefetch g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_prefetch, vSRAMTemplate_185_i_io_r_resp_data_2_prefetch); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_2_prefetch, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_2_prefetch, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_2_prefetch g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_prefetch, vSRAMTemplate_185_i_io_r_resp_data_2_prefetch); end
    if (vSRAMTemplate_185_g_io_r_resp_data_2_prefetchSrc !== vSRAMTemplate_185_i_io_r_resp_data_2_prefetchSrc) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_2_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_prefetchSrc, vSRAMTemplate_185_i_io_r_resp_data_2_prefetchSrc); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_2_prefetchSrc, 3) || has_z(vSRAMTemplate_185_i_io_r_resp_data_2_prefetchSrc, 3)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_2_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_prefetchSrc, vSRAMTemplate_185_i_io_r_resp_data_2_prefetchSrc); end
    if (vSRAMTemplate_185_g_io_r_resp_data_2_accessed !== vSRAMTemplate_185_i_io_r_resp_data_2_accessed) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_2_accessed g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_accessed, vSRAMTemplate_185_i_io_r_resp_data_2_accessed); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_2_accessed, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_2_accessed, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_2_accessed g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_accessed, vSRAMTemplate_185_i_io_r_resp_data_2_accessed); end
    if (vSRAMTemplate_185_g_io_r_resp_data_2_tagErr !== vSRAMTemplate_185_i_io_r_resp_data_2_tagErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_2_tagErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_tagErr, vSRAMTemplate_185_i_io_r_resp_data_2_tagErr); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_2_tagErr, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_2_tagErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_2_tagErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_tagErr, vSRAMTemplate_185_i_io_r_resp_data_2_tagErr); end
    if (vSRAMTemplate_185_g_io_r_resp_data_2_dataErr !== vSRAMTemplate_185_i_io_r_resp_data_2_dataErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_2_dataErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_dataErr, vSRAMTemplate_185_i_io_r_resp_data_2_dataErr); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_2_dataErr, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_2_dataErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_2_dataErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_2_dataErr, vSRAMTemplate_185_i_io_r_resp_data_2_dataErr); end
    if (vSRAMTemplate_185_g_io_r_resp_data_3_dirty !== vSRAMTemplate_185_i_io_r_resp_data_3_dirty) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_3_dirty g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_dirty, vSRAMTemplate_185_i_io_r_resp_data_3_dirty); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_3_dirty, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_3_dirty, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_3_dirty g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_dirty, vSRAMTemplate_185_i_io_r_resp_data_3_dirty); end
    if (vSRAMTemplate_185_g_io_r_resp_data_3_state !== vSRAMTemplate_185_i_io_r_resp_data_3_state) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_3_state g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_state, vSRAMTemplate_185_i_io_r_resp_data_3_state); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_3_state, 2) || has_z(vSRAMTemplate_185_i_io_r_resp_data_3_state, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_3_state g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_state, vSRAMTemplate_185_i_io_r_resp_data_3_state); end
    if (vSRAMTemplate_185_g_io_r_resp_data_3_clients !== vSRAMTemplate_185_i_io_r_resp_data_3_clients) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_3_clients g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_clients, vSRAMTemplate_185_i_io_r_resp_data_3_clients); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_3_clients, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_3_clients, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_3_clients g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_clients, vSRAMTemplate_185_i_io_r_resp_data_3_clients); end
    if (vSRAMTemplate_185_g_io_r_resp_data_3_alias !== vSRAMTemplate_185_i_io_r_resp_data_3_alias) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_3_alias g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_alias, vSRAMTemplate_185_i_io_r_resp_data_3_alias); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_3_alias, 2) || has_z(vSRAMTemplate_185_i_io_r_resp_data_3_alias, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_3_alias g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_alias, vSRAMTemplate_185_i_io_r_resp_data_3_alias); end
    if (vSRAMTemplate_185_g_io_r_resp_data_3_prefetch !== vSRAMTemplate_185_i_io_r_resp_data_3_prefetch) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_3_prefetch g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_prefetch, vSRAMTemplate_185_i_io_r_resp_data_3_prefetch); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_3_prefetch, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_3_prefetch, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_3_prefetch g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_prefetch, vSRAMTemplate_185_i_io_r_resp_data_3_prefetch); end
    if (vSRAMTemplate_185_g_io_r_resp_data_3_prefetchSrc !== vSRAMTemplate_185_i_io_r_resp_data_3_prefetchSrc) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_3_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_prefetchSrc, vSRAMTemplate_185_i_io_r_resp_data_3_prefetchSrc); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_3_prefetchSrc, 3) || has_z(vSRAMTemplate_185_i_io_r_resp_data_3_prefetchSrc, 3)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_3_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_prefetchSrc, vSRAMTemplate_185_i_io_r_resp_data_3_prefetchSrc); end
    if (vSRAMTemplate_185_g_io_r_resp_data_3_accessed !== vSRAMTemplate_185_i_io_r_resp_data_3_accessed) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_3_accessed g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_accessed, vSRAMTemplate_185_i_io_r_resp_data_3_accessed); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_3_accessed, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_3_accessed, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_3_accessed g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_accessed, vSRAMTemplate_185_i_io_r_resp_data_3_accessed); end
    if (vSRAMTemplate_185_g_io_r_resp_data_3_tagErr !== vSRAMTemplate_185_i_io_r_resp_data_3_tagErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_3_tagErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_tagErr, vSRAMTemplate_185_i_io_r_resp_data_3_tagErr); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_3_tagErr, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_3_tagErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_3_tagErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_tagErr, vSRAMTemplate_185_i_io_r_resp_data_3_tagErr); end
    if (vSRAMTemplate_185_g_io_r_resp_data_3_dataErr !== vSRAMTemplate_185_i_io_r_resp_data_3_dataErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_3_dataErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_dataErr, vSRAMTemplate_185_i_io_r_resp_data_3_dataErr); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_3_dataErr, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_3_dataErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_3_dataErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_3_dataErr, vSRAMTemplate_185_i_io_r_resp_data_3_dataErr); end
    if (vSRAMTemplate_185_g_io_r_resp_data_4_dirty !== vSRAMTemplate_185_i_io_r_resp_data_4_dirty) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_4_dirty g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_dirty, vSRAMTemplate_185_i_io_r_resp_data_4_dirty); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_4_dirty, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_4_dirty, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_4_dirty g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_dirty, vSRAMTemplate_185_i_io_r_resp_data_4_dirty); end
    if (vSRAMTemplate_185_g_io_r_resp_data_4_state !== vSRAMTemplate_185_i_io_r_resp_data_4_state) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_4_state g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_state, vSRAMTemplate_185_i_io_r_resp_data_4_state); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_4_state, 2) || has_z(vSRAMTemplate_185_i_io_r_resp_data_4_state, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_4_state g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_state, vSRAMTemplate_185_i_io_r_resp_data_4_state); end
    if (vSRAMTemplate_185_g_io_r_resp_data_4_clients !== vSRAMTemplate_185_i_io_r_resp_data_4_clients) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_4_clients g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_clients, vSRAMTemplate_185_i_io_r_resp_data_4_clients); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_4_clients, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_4_clients, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_4_clients g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_clients, vSRAMTemplate_185_i_io_r_resp_data_4_clients); end
    if (vSRAMTemplate_185_g_io_r_resp_data_4_alias !== vSRAMTemplate_185_i_io_r_resp_data_4_alias) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_4_alias g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_alias, vSRAMTemplate_185_i_io_r_resp_data_4_alias); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_4_alias, 2) || has_z(vSRAMTemplate_185_i_io_r_resp_data_4_alias, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_4_alias g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_alias, vSRAMTemplate_185_i_io_r_resp_data_4_alias); end
    if (vSRAMTemplate_185_g_io_r_resp_data_4_prefetch !== vSRAMTemplate_185_i_io_r_resp_data_4_prefetch) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_4_prefetch g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_prefetch, vSRAMTemplate_185_i_io_r_resp_data_4_prefetch); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_4_prefetch, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_4_prefetch, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_4_prefetch g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_prefetch, vSRAMTemplate_185_i_io_r_resp_data_4_prefetch); end
    if (vSRAMTemplate_185_g_io_r_resp_data_4_prefetchSrc !== vSRAMTemplate_185_i_io_r_resp_data_4_prefetchSrc) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_4_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_prefetchSrc, vSRAMTemplate_185_i_io_r_resp_data_4_prefetchSrc); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_4_prefetchSrc, 3) || has_z(vSRAMTemplate_185_i_io_r_resp_data_4_prefetchSrc, 3)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_4_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_prefetchSrc, vSRAMTemplate_185_i_io_r_resp_data_4_prefetchSrc); end
    if (vSRAMTemplate_185_g_io_r_resp_data_4_accessed !== vSRAMTemplate_185_i_io_r_resp_data_4_accessed) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_4_accessed g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_accessed, vSRAMTemplate_185_i_io_r_resp_data_4_accessed); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_4_accessed, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_4_accessed, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_4_accessed g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_accessed, vSRAMTemplate_185_i_io_r_resp_data_4_accessed); end
    if (vSRAMTemplate_185_g_io_r_resp_data_4_tagErr !== vSRAMTemplate_185_i_io_r_resp_data_4_tagErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_4_tagErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_tagErr, vSRAMTemplate_185_i_io_r_resp_data_4_tagErr); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_4_tagErr, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_4_tagErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_4_tagErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_tagErr, vSRAMTemplate_185_i_io_r_resp_data_4_tagErr); end
    if (vSRAMTemplate_185_g_io_r_resp_data_4_dataErr !== vSRAMTemplate_185_i_io_r_resp_data_4_dataErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_4_dataErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_dataErr, vSRAMTemplate_185_i_io_r_resp_data_4_dataErr); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_4_dataErr, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_4_dataErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_4_dataErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_4_dataErr, vSRAMTemplate_185_i_io_r_resp_data_4_dataErr); end
    if (vSRAMTemplate_185_g_io_r_resp_data_5_dirty !== vSRAMTemplate_185_i_io_r_resp_data_5_dirty) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_5_dirty g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_dirty, vSRAMTemplate_185_i_io_r_resp_data_5_dirty); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_5_dirty, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_5_dirty, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_5_dirty g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_dirty, vSRAMTemplate_185_i_io_r_resp_data_5_dirty); end
    if (vSRAMTemplate_185_g_io_r_resp_data_5_state !== vSRAMTemplate_185_i_io_r_resp_data_5_state) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_5_state g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_state, vSRAMTemplate_185_i_io_r_resp_data_5_state); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_5_state, 2) || has_z(vSRAMTemplate_185_i_io_r_resp_data_5_state, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_5_state g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_state, vSRAMTemplate_185_i_io_r_resp_data_5_state); end
    if (vSRAMTemplate_185_g_io_r_resp_data_5_clients !== vSRAMTemplate_185_i_io_r_resp_data_5_clients) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_5_clients g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_clients, vSRAMTemplate_185_i_io_r_resp_data_5_clients); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_5_clients, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_5_clients, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_5_clients g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_clients, vSRAMTemplate_185_i_io_r_resp_data_5_clients); end
    if (vSRAMTemplate_185_g_io_r_resp_data_5_alias !== vSRAMTemplate_185_i_io_r_resp_data_5_alias) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_5_alias g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_alias, vSRAMTemplate_185_i_io_r_resp_data_5_alias); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_5_alias, 2) || has_z(vSRAMTemplate_185_i_io_r_resp_data_5_alias, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_5_alias g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_alias, vSRAMTemplate_185_i_io_r_resp_data_5_alias); end
    if (vSRAMTemplate_185_g_io_r_resp_data_5_prefetch !== vSRAMTemplate_185_i_io_r_resp_data_5_prefetch) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_5_prefetch g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_prefetch, vSRAMTemplate_185_i_io_r_resp_data_5_prefetch); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_5_prefetch, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_5_prefetch, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_5_prefetch g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_prefetch, vSRAMTemplate_185_i_io_r_resp_data_5_prefetch); end
    if (vSRAMTemplate_185_g_io_r_resp_data_5_prefetchSrc !== vSRAMTemplate_185_i_io_r_resp_data_5_prefetchSrc) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_5_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_prefetchSrc, vSRAMTemplate_185_i_io_r_resp_data_5_prefetchSrc); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_5_prefetchSrc, 3) || has_z(vSRAMTemplate_185_i_io_r_resp_data_5_prefetchSrc, 3)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_5_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_prefetchSrc, vSRAMTemplate_185_i_io_r_resp_data_5_prefetchSrc); end
    if (vSRAMTemplate_185_g_io_r_resp_data_5_accessed !== vSRAMTemplate_185_i_io_r_resp_data_5_accessed) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_5_accessed g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_accessed, vSRAMTemplate_185_i_io_r_resp_data_5_accessed); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_5_accessed, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_5_accessed, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_5_accessed g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_accessed, vSRAMTemplate_185_i_io_r_resp_data_5_accessed); end
    if (vSRAMTemplate_185_g_io_r_resp_data_5_tagErr !== vSRAMTemplate_185_i_io_r_resp_data_5_tagErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_5_tagErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_tagErr, vSRAMTemplate_185_i_io_r_resp_data_5_tagErr); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_5_tagErr, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_5_tagErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_5_tagErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_tagErr, vSRAMTemplate_185_i_io_r_resp_data_5_tagErr); end
    if (vSRAMTemplate_185_g_io_r_resp_data_5_dataErr !== vSRAMTemplate_185_i_io_r_resp_data_5_dataErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_5_dataErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_dataErr, vSRAMTemplate_185_i_io_r_resp_data_5_dataErr); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_5_dataErr, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_5_dataErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_5_dataErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_5_dataErr, vSRAMTemplate_185_i_io_r_resp_data_5_dataErr); end
    if (vSRAMTemplate_185_g_io_r_resp_data_6_dirty !== vSRAMTemplate_185_i_io_r_resp_data_6_dirty) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_6_dirty g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_dirty, vSRAMTemplate_185_i_io_r_resp_data_6_dirty); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_6_dirty, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_6_dirty, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_6_dirty g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_dirty, vSRAMTemplate_185_i_io_r_resp_data_6_dirty); end
    if (vSRAMTemplate_185_g_io_r_resp_data_6_state !== vSRAMTemplate_185_i_io_r_resp_data_6_state) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_6_state g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_state, vSRAMTemplate_185_i_io_r_resp_data_6_state); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_6_state, 2) || has_z(vSRAMTemplate_185_i_io_r_resp_data_6_state, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_6_state g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_state, vSRAMTemplate_185_i_io_r_resp_data_6_state); end
    if (vSRAMTemplate_185_g_io_r_resp_data_6_clients !== vSRAMTemplate_185_i_io_r_resp_data_6_clients) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_6_clients g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_clients, vSRAMTemplate_185_i_io_r_resp_data_6_clients); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_6_clients, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_6_clients, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_6_clients g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_clients, vSRAMTemplate_185_i_io_r_resp_data_6_clients); end
    if (vSRAMTemplate_185_g_io_r_resp_data_6_alias !== vSRAMTemplate_185_i_io_r_resp_data_6_alias) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_6_alias g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_alias, vSRAMTemplate_185_i_io_r_resp_data_6_alias); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_6_alias, 2) || has_z(vSRAMTemplate_185_i_io_r_resp_data_6_alias, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_6_alias g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_alias, vSRAMTemplate_185_i_io_r_resp_data_6_alias); end
    if (vSRAMTemplate_185_g_io_r_resp_data_6_prefetch !== vSRAMTemplate_185_i_io_r_resp_data_6_prefetch) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_6_prefetch g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_prefetch, vSRAMTemplate_185_i_io_r_resp_data_6_prefetch); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_6_prefetch, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_6_prefetch, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_6_prefetch g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_prefetch, vSRAMTemplate_185_i_io_r_resp_data_6_prefetch); end
    if (vSRAMTemplate_185_g_io_r_resp_data_6_prefetchSrc !== vSRAMTemplate_185_i_io_r_resp_data_6_prefetchSrc) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_6_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_prefetchSrc, vSRAMTemplate_185_i_io_r_resp_data_6_prefetchSrc); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_6_prefetchSrc, 3) || has_z(vSRAMTemplate_185_i_io_r_resp_data_6_prefetchSrc, 3)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_6_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_prefetchSrc, vSRAMTemplate_185_i_io_r_resp_data_6_prefetchSrc); end
    if (vSRAMTemplate_185_g_io_r_resp_data_6_accessed !== vSRAMTemplate_185_i_io_r_resp_data_6_accessed) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_6_accessed g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_accessed, vSRAMTemplate_185_i_io_r_resp_data_6_accessed); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_6_accessed, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_6_accessed, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_6_accessed g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_accessed, vSRAMTemplate_185_i_io_r_resp_data_6_accessed); end
    if (vSRAMTemplate_185_g_io_r_resp_data_6_tagErr !== vSRAMTemplate_185_i_io_r_resp_data_6_tagErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_6_tagErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_tagErr, vSRAMTemplate_185_i_io_r_resp_data_6_tagErr); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_6_tagErr, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_6_tagErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_6_tagErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_tagErr, vSRAMTemplate_185_i_io_r_resp_data_6_tagErr); end
    if (vSRAMTemplate_185_g_io_r_resp_data_6_dataErr !== vSRAMTemplate_185_i_io_r_resp_data_6_dataErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_6_dataErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_dataErr, vSRAMTemplate_185_i_io_r_resp_data_6_dataErr); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_6_dataErr, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_6_dataErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_6_dataErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_6_dataErr, vSRAMTemplate_185_i_io_r_resp_data_6_dataErr); end
    if (vSRAMTemplate_185_g_io_r_resp_data_7_dirty !== vSRAMTemplate_185_i_io_r_resp_data_7_dirty) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_7_dirty g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_dirty, vSRAMTemplate_185_i_io_r_resp_data_7_dirty); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_7_dirty, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_7_dirty, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_7_dirty g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_dirty, vSRAMTemplate_185_i_io_r_resp_data_7_dirty); end
    if (vSRAMTemplate_185_g_io_r_resp_data_7_state !== vSRAMTemplate_185_i_io_r_resp_data_7_state) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_7_state g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_state, vSRAMTemplate_185_i_io_r_resp_data_7_state); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_7_state, 2) || has_z(vSRAMTemplate_185_i_io_r_resp_data_7_state, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_7_state g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_state, vSRAMTemplate_185_i_io_r_resp_data_7_state); end
    if (vSRAMTemplate_185_g_io_r_resp_data_7_clients !== vSRAMTemplate_185_i_io_r_resp_data_7_clients) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_7_clients g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_clients, vSRAMTemplate_185_i_io_r_resp_data_7_clients); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_7_clients, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_7_clients, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_7_clients g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_clients, vSRAMTemplate_185_i_io_r_resp_data_7_clients); end
    if (vSRAMTemplate_185_g_io_r_resp_data_7_alias !== vSRAMTemplate_185_i_io_r_resp_data_7_alias) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_7_alias g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_alias, vSRAMTemplate_185_i_io_r_resp_data_7_alias); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_7_alias, 2) || has_z(vSRAMTemplate_185_i_io_r_resp_data_7_alias, 2)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_7_alias g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_alias, vSRAMTemplate_185_i_io_r_resp_data_7_alias); end
    if (vSRAMTemplate_185_g_io_r_resp_data_7_prefetch !== vSRAMTemplate_185_i_io_r_resp_data_7_prefetch) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_7_prefetch g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_prefetch, vSRAMTemplate_185_i_io_r_resp_data_7_prefetch); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_7_prefetch, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_7_prefetch, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_7_prefetch g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_prefetch, vSRAMTemplate_185_i_io_r_resp_data_7_prefetch); end
    if (vSRAMTemplate_185_g_io_r_resp_data_7_prefetchSrc !== vSRAMTemplate_185_i_io_r_resp_data_7_prefetchSrc) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_7_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_prefetchSrc, vSRAMTemplate_185_i_io_r_resp_data_7_prefetchSrc); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_7_prefetchSrc, 3) || has_z(vSRAMTemplate_185_i_io_r_resp_data_7_prefetchSrc, 3)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_7_prefetchSrc g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_prefetchSrc, vSRAMTemplate_185_i_io_r_resp_data_7_prefetchSrc); end
    if (vSRAMTemplate_185_g_io_r_resp_data_7_accessed !== vSRAMTemplate_185_i_io_r_resp_data_7_accessed) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_7_accessed g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_accessed, vSRAMTemplate_185_i_io_r_resp_data_7_accessed); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_7_accessed, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_7_accessed, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_7_accessed g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_accessed, vSRAMTemplate_185_i_io_r_resp_data_7_accessed); end
    if (vSRAMTemplate_185_g_io_r_resp_data_7_tagErr !== vSRAMTemplate_185_i_io_r_resp_data_7_tagErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_7_tagErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_tagErr, vSRAMTemplate_185_i_io_r_resp_data_7_tagErr); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_7_tagErr, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_7_tagErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_7_tagErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_tagErr, vSRAMTemplate_185_i_io_r_resp_data_7_tagErr); end
    if (vSRAMTemplate_185_g_io_r_resp_data_7_dataErr !== vSRAMTemplate_185_i_io_r_resp_data_7_dataErr) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_r_resp_data_7_dataErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_dataErr, vSRAMTemplate_185_i_io_r_resp_data_7_dataErr); end
    if (has_z(vSRAMTemplate_185_g_io_r_resp_data_7_dataErr, 1) || has_z(vSRAMTemplate_185_i_io_r_resp_data_7_dataErr, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_r_resp_data_7_dataErr g=%h i=%h", $time, vSRAMTemplate_185_g_io_r_resp_data_7_dataErr, vSRAMTemplate_185_i_io_r_resp_data_7_dataErr); end
    if (vSRAMTemplate_185_g_io_w_req_ready !== vSRAMTemplate_185_i_io_w_req_ready) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_w_req_ready g=%h i=%h", $time, vSRAMTemplate_185_g_io_w_req_ready, vSRAMTemplate_185_i_io_w_req_ready); end
    if (has_z(vSRAMTemplate_185_g_io_w_req_ready, 1) || has_z(vSRAMTemplate_185_i_io_w_req_ready, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_w_req_ready g=%h i=%h", $time, vSRAMTemplate_185_g_io_w_req_ready, vSRAMTemplate_185_i_io_w_req_ready); end
    if (vSRAMTemplate_185_g_io_resetDone !== vSRAMTemplate_185_i_io_resetDone) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.io_resetDone g=%h i=%h", $time, vSRAMTemplate_185_g_io_resetDone, vSRAMTemplate_185_i_io_resetDone); end
    if (has_z(vSRAMTemplate_185_g_io_resetDone, 1) || has_z(vSRAMTemplate_185_i_io_resetDone, 1)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.io_resetDone g=%h i=%h", $time, vSRAMTemplate_185_g_io_resetDone, vSRAMTemplate_185_i_io_resetDone); end
    if (vSRAMTemplate_185_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_185_i_boreChildrenBd_bore_rdata) begin errors++;
      if (errors < 40) $display("[%0t] SRAMTemplate_185.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_185_g_boreChildrenBd_bore_rdata, vSRAMTemplate_185_i_boreChildrenBd_bore_rdata); end
    if (has_z(vSRAMTemplate_185_g_boreChildrenBd_bore_rdata, 104) || has_z(vSRAMTemplate_185_i_boreChildrenBd_bore_rdata, 104)) begin zhits++;
      if (zhits < 20) $display("[%0t] Z-DRIVE SRAMTemplate_185.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_185_g_boreChildrenBd_bore_rdata, vSRAMTemplate_185_i_boreChildrenBd_bore_rdata); end
  end

  int cov_fail = 0;
  task automatic covchk(string nm, int v);
    $display("  cov %-38s = %0d", nm, v);
    if (v == 0) begin cov_fail++; $display("  *** COVERAGE HOLE: %s == 0", nm); end
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 120000;
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("---------------------------------------------");
    covchk("SRAMTemplate_128_cov_w", vSRAMTemplate_128_cov_w);
    covchk("SRAMTemplate_128_cov_rw_same", vSRAMTemplate_128_cov_rw_same);
    covchk("SRAMTemplate_128_cov_cgoff", vSRAMTemplate_128_cov_cgoff);
    covchk("SRAMTemplate_128_cov_bore_w", vSRAMTemplate_128_cov_bore_w);
    covchk("SRAMTemplate_128_cov_bore_r", vSRAMTemplate_128_cov_bore_r);
    covchk("SRAMTemplate_128_cov_hold", vSRAMTemplate_128_cov_hold);
    covchk("SRAMTemplate_128_cov_rd_known", vSRAMTemplate_128_cov_rd_known);
    covchk("SRAMTemplate_128_cov_rd_nonzero", vSRAMTemplate_128_cov_rd_nonzero);
    covchk("SRAMTemplate_128_cov_m0", vSRAMTemplate_128_cov_m0);
    covchk("SRAMTemplate_128_cov_m1", vSRAMTemplate_128_cov_m1);
    covchk("SRAMTemplate_128_cov_mmix", vSRAMTemplate_128_cov_mmix);
    covchk("SRAMTemplate_128_cov_seg_all", vSRAMTemplate_128_cov_seg_all);
    covchk("SRAMTemplate_145_cov_w", vSRAMTemplate_145_cov_w);
    covchk("SRAMTemplate_145_cov_rw_same", vSRAMTemplate_145_cov_rw_same);
    covchk("SRAMTemplate_145_cov_cgoff", vSRAMTemplate_145_cov_cgoff);
    covchk("SRAMTemplate_145_cov_bore_w", vSRAMTemplate_145_cov_bore_w);
    covchk("SRAMTemplate_145_cov_bore_r", vSRAMTemplate_145_cov_bore_r);
    covchk("SRAMTemplate_145_cov_hold", vSRAMTemplate_145_cov_hold);
    covchk("SRAMTemplate_145_cov_rd_known", vSRAMTemplate_145_cov_rd_known);
    covchk("SRAMTemplate_145_cov_rd_nonzero", vSRAMTemplate_145_cov_rd_nonzero);
    covchk("SRAMTemplate_145_cov_m0", vSRAMTemplate_145_cov_m0);
    covchk("SRAMTemplate_145_cov_m1", vSRAMTemplate_145_cov_m1);
    covchk("SRAMTemplate_145_cov_mmix", vSRAMTemplate_145_cov_mmix);
    covchk("SRAMTemplate_146_cov_w", vSRAMTemplate_146_cov_w);
    covchk("SRAMTemplate_146_cov_rw_same", vSRAMTemplate_146_cov_rw_same);
    covchk("SRAMTemplate_146_cov_cgoff", vSRAMTemplate_146_cov_cgoff);
    covchk("SRAMTemplate_146_cov_bore_w", vSRAMTemplate_146_cov_bore_w);
    covchk("SRAMTemplate_146_cov_bore_r", vSRAMTemplate_146_cov_bore_r);
    covchk("SRAMTemplate_146_cov_hold", vSRAMTemplate_146_cov_hold);
    covchk("SRAMTemplate_146_cov_rd_known", vSRAMTemplate_146_cov_rd_known);
    covchk("SRAMTemplate_146_cov_rd_nonzero", vSRAMTemplate_146_cov_rd_nonzero);
    covchk("SRAMTemplate_155_cov_w", vSRAMTemplate_155_cov_w);
    covchk("SRAMTemplate_155_cov_rw_same", vSRAMTemplate_155_cov_rw_same);
    covchk("SRAMTemplate_155_cov_cgoff", vSRAMTemplate_155_cov_cgoff);
    covchk("SRAMTemplate_155_cov_bore_w", vSRAMTemplate_155_cov_bore_w);
    covchk("SRAMTemplate_155_cov_bore_r", vSRAMTemplate_155_cov_bore_r);
    covchk("SRAMTemplate_155_cov_hold", vSRAMTemplate_155_cov_hold);
    covchk("SRAMTemplate_155_cov_rd_known", vSRAMTemplate_155_cov_rd_known);
    covchk("SRAMTemplate_155_cov_rd_nonzero", vSRAMTemplate_155_cov_rd_nonzero);
    covchk("SRAMTemplate_163_cov_w", vSRAMTemplate_163_cov_w);
    covchk("SRAMTemplate_163_cov_rw_same", vSRAMTemplate_163_cov_rw_same);
    covchk("SRAMTemplate_163_cov_cgoff", vSRAMTemplate_163_cov_cgoff);
    covchk("SRAMTemplate_163_cov_bore_w", vSRAMTemplate_163_cov_bore_w);
    covchk("SRAMTemplate_163_cov_bore_r", vSRAMTemplate_163_cov_bore_r);
    covchk("SRAMTemplate_163_cov_hold", vSRAMTemplate_163_cov_hold);
    covchk("SRAMTemplate_163_cov_rd_known", vSRAMTemplate_163_cov_rd_known);
    covchk("SRAMTemplate_163_cov_rd_nonzero", vSRAMTemplate_163_cov_rd_nonzero);
    covchk("SRAMTemplate_163_cov_m0", vSRAMTemplate_163_cov_m0);
    covchk("SRAMTemplate_163_cov_m1", vSRAMTemplate_163_cov_m1);
    covchk("SRAMTemplate_163_cov_mmix", vSRAMTemplate_163_cov_mmix);
    covchk("SRAMTemplate_166_cov_w", vSRAMTemplate_166_cov_w);
    covchk("SRAMTemplate_166_cov_rw_same", vSRAMTemplate_166_cov_rw_same);
    covchk("SRAMTemplate_166_cov_cgoff", vSRAMTemplate_166_cov_cgoff);
    covchk("SRAMTemplate_166_cov_bore_w", vSRAMTemplate_166_cov_bore_w);
    covchk("SRAMTemplate_166_cov_bore_r", vSRAMTemplate_166_cov_bore_r);
    covchk("SRAMTemplate_166_cov_hold", vSRAMTemplate_166_cov_hold);
    covchk("SRAMTemplate_166_cov_rd_known", vSRAMTemplate_166_cov_rd_known);
    covchk("SRAMTemplate_166_cov_rd_nonzero", vSRAMTemplate_166_cov_rd_nonzero);
    covchk("SRAMTemplate_178_cov_w", vSRAMTemplate_178_cov_w);
    covchk("SRAMTemplate_178_cov_rw_same", vSRAMTemplate_178_cov_rw_same);
    covchk("SRAMTemplate_178_cov_cgoff", vSRAMTemplate_178_cov_cgoff);
    covchk("SRAMTemplate_178_cov_bore_w", vSRAMTemplate_178_cov_bore_w);
    covchk("SRAMTemplate_178_cov_bore_r", vSRAMTemplate_178_cov_bore_r);
    covchk("SRAMTemplate_178_cov_hold", vSRAMTemplate_178_cov_hold);
    covchk("SRAMTemplate_178_cov_rd_known", vSRAMTemplate_178_cov_rd_known);
    covchk("SRAMTemplate_178_cov_rd_nonzero", vSRAMTemplate_178_cov_rd_nonzero);
    covchk("SRAMTemplate_185_cov_w", vSRAMTemplate_185_cov_w);
    covchk("SRAMTemplate_185_cov_rw_same", vSRAMTemplate_185_cov_rw_same);
    covchk("SRAMTemplate_185_cov_cgoff", vSRAMTemplate_185_cov_cgoff);
    covchk("SRAMTemplate_185_cov_bore_w", vSRAMTemplate_185_cov_bore_w);
    covchk("SRAMTemplate_185_cov_bore_r", vSRAMTemplate_185_cov_bore_r);
    covchk("SRAMTemplate_185_cov_hold", vSRAMTemplate_185_cov_hold);
    covchk("SRAMTemplate_185_cov_rd_known", vSRAMTemplate_185_cov_rd_known);
    covchk("SRAMTemplate_185_cov_rd_nonzero", vSRAMTemplate_185_cov_rd_nonzero);
    covchk("SRAMTemplate_185_cov_m0", vSRAMTemplate_185_cov_m0);
    covchk("SRAMTemplate_185_cov_m1", vSRAMTemplate_185_cov_m1);
    covchk("SRAMTemplate_185_cov_mmix", vSRAMTemplate_185_cov_mmix);
    $display("---------------------------------------------");
    $display("checks=%0d errors=%0d zhits=%0d cov_holes=%0d", checks, errors, zhits, cov_fail);
    if (errors == 0 && zhits == 0 && cov_fail == 0 && checks > 100000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
