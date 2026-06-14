// 自动生成：scripts/gen_sram_wrappers.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 40000;
  int unsigned WARMUP  = 400;   // 等最大 set 的 reset FSM 清零完成
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  logic vSRAMTemplate_io_r_req_valid;
  logic [6:0] vSRAMTemplate_io_r_req_bits_setIdx;
  logic vSRAMTemplate_io_w_req_valid;
  logic [6:0] vSRAMTemplate_io_w_req_bits_setIdx;
  logic [36:0] vSRAMTemplate_io_w_req_bits_data_0;
  logic [36:0] vSRAMTemplate_io_w_req_bits_data_1;
  logic [1:0] vSRAMTemplate_io_w_req_bits_waymask;
  logic vSRAMTemplate_io_broadcast_ram_hold;
  logic vSRAMTemplate_io_broadcast_ram_bypass;
  logic vSRAMTemplate_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_io_broadcast_ram_ctl;
  logic vSRAMTemplate_io_broadcast_cgen;
  logic [7:0] vSRAMTemplate_boreChildrenBd_bore_addr;
  logic [7:0] vSRAMTemplate_boreChildrenBd_bore_addr_rd;
  logic [73:0] vSRAMTemplate_boreChildrenBd_bore_wdata;
  logic [1:0] vSRAMTemplate_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_boreChildrenBd_bore_re;
  logic vSRAMTemplate_boreChildrenBd_bore_we;
  logic vSRAMTemplate_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_boreChildrenBd_bore_selectedOH;
  logic vSRAMTemplate_boreChildrenBd_bore_array;
  wire vSRAMTemplate_g_io_r_req_ready;
  wire vSRAMTemplate_i_io_r_req_ready;
  wire [36:0] vSRAMTemplate_g_io_r_resp_data_0;
  wire [36:0] vSRAMTemplate_i_io_r_resp_data_0;
  wire [36:0] vSRAMTemplate_g_io_r_resp_data_1;
  wire [36:0] vSRAMTemplate_i_io_r_resp_data_1;
  wire [73:0] vSRAMTemplate_g_boreChildrenBd_bore_rdata;
  wire [73:0] vSRAMTemplate_i_boreChildrenBd_bore_rdata;
  SRAMTemplate u_g_SRAMTemplate (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_io_w_req_bits_data_1), .io_w_req_bits_waymask(vSRAMTemplate_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_g_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_g_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_xs u_i_SRAMTemplate (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_io_w_req_bits_data_1), .io_w_req_bits_waymask(vSRAMTemplate_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_i_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_i_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_io_r_req_valid <= 1'b0;
      vSRAMTemplate_io_w_req_valid <= 1'b0;
      vSRAMTemplate_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_io_r_req_bits_setIdx <= 7'($urandom);
      vSRAMTemplate_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_io_w_req_bits_setIdx <= 7'($urandom);
      vSRAMTemplate_io_w_req_bits_data_0 <= 37'({$urandom(), $urandom()});
      vSRAMTemplate_io_w_req_bits_data_1 <= 37'({$urandom(), $urandom()});
      vSRAMTemplate_io_w_req_bits_waymask <= 2'($urandom);
      vSRAMTemplate_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_boreChildrenBd_bore_addr <= 8'($urandom);
      vSRAMTemplate_boreChildrenBd_bore_addr_rd <= 8'($urandom);
      vSRAMTemplate_boreChildrenBd_bore_wdata <= 74'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_boreChildrenBd_bore_wmask <= 2'($urandom);
      vSRAMTemplate_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_boreChildrenBd_bore_array <= 1'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_g_io_r_req_ready !== vSRAMTemplate_i_io_r_req_ready) begin errors++;
      $display("[%0t] SRAMTemplate.io_r_req_ready g=%h i=%h", $time, vSRAMTemplate_g_io_r_req_ready, vSRAMTemplate_i_io_r_req_ready); end
    if (vSRAMTemplate_g_io_r_resp_data_0 !== vSRAMTemplate_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_g_io_r_resp_data_0, vSRAMTemplate_i_io_r_resp_data_0); end
    if (vSRAMTemplate_g_io_r_resp_data_1 !== vSRAMTemplate_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_g_io_r_resp_data_1, vSRAMTemplate_i_io_r_resp_data_1); end
    if (vSRAMTemplate_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_g_boreChildrenBd_bore_rdata, vSRAMTemplate_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_2_io_r_req_valid;
  logic [6:0] vSRAMTemplate_2_io_r_req_bits_setIdx;
  logic vSRAMTemplate_2_io_w_req_valid;
  logic [6:0] vSRAMTemplate_2_io_w_req_bits_setIdx;
  logic [36:0] vSRAMTemplate_2_io_w_req_bits_data_0;
  logic [36:0] vSRAMTemplate_2_io_w_req_bits_data_1;
  logic [1:0] vSRAMTemplate_2_io_w_req_bits_waymask;
  logic vSRAMTemplate_2_io_broadcast_ram_hold;
  logic vSRAMTemplate_2_io_broadcast_ram_bypass;
  logic vSRAMTemplate_2_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_2_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_2_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_2_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_2_io_broadcast_ram_ctl;
  logic vSRAMTemplate_2_io_broadcast_cgen;
  logic [7:0] vSRAMTemplate_2_boreChildrenBd_bore_addr;
  logic [7:0] vSRAMTemplate_2_boreChildrenBd_bore_addr_rd;
  logic [73:0] vSRAMTemplate_2_boreChildrenBd_bore_wdata;
  logic [1:0] vSRAMTemplate_2_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_2_boreChildrenBd_bore_re;
  logic vSRAMTemplate_2_boreChildrenBd_bore_we;
  logic vSRAMTemplate_2_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_2_boreChildrenBd_bore_selectedOH;
  logic [1:0] vSRAMTemplate_2_boreChildrenBd_bore_array;
  wire vSRAMTemplate_2_g_io_r_req_ready;
  wire vSRAMTemplate_2_i_io_r_req_ready;
  wire [36:0] vSRAMTemplate_2_g_io_r_resp_data_0;
  wire [36:0] vSRAMTemplate_2_i_io_r_resp_data_0;
  wire [36:0] vSRAMTemplate_2_g_io_r_resp_data_1;
  wire [36:0] vSRAMTemplate_2_i_io_r_resp_data_1;
  wire [73:0] vSRAMTemplate_2_g_boreChildrenBd_bore_rdata;
  wire [73:0] vSRAMTemplate_2_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_2 u_g_SRAMTemplate_2 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_2_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_2_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_2_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_2_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_2_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_2_io_w_req_bits_data_1), .io_w_req_bits_waymask(vSRAMTemplate_2_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_2_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_2_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_2_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_2_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_2_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_2_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_2_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_2_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_2_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_2_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_2_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_2_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_2_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_2_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_2_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_2_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_2_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_2_g_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_2_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_2_g_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_2_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_2_xs u_i_SRAMTemplate_2 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_2_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_2_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_2_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_2_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_2_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_2_io_w_req_bits_data_1), .io_w_req_bits_waymask(vSRAMTemplate_2_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_2_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_2_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_2_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_2_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_2_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_2_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_2_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_2_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_2_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_2_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_2_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_2_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_2_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_2_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_2_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_2_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_2_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_2_i_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_2_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_2_i_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_2_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_2_io_r_req_valid <= 1'b0;
      vSRAMTemplate_2_io_w_req_valid <= 1'b0;
      vSRAMTemplate_2_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_2_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_2_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_2_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_2_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_2_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_2_io_r_req_bits_setIdx <= 7'($urandom);
      vSRAMTemplate_2_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_2_io_w_req_bits_setIdx <= 7'($urandom);
      vSRAMTemplate_2_io_w_req_bits_data_0 <= 37'({$urandom(), $urandom()});
      vSRAMTemplate_2_io_w_req_bits_data_1 <= 37'({$urandom(), $urandom()});
      vSRAMTemplate_2_io_w_req_bits_waymask <= 2'($urandom);
      vSRAMTemplate_2_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_2_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_2_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_2_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_2_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_2_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_2_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_2_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_2_boreChildrenBd_bore_addr <= 8'($urandom);
      vSRAMTemplate_2_boreChildrenBd_bore_addr_rd <= 8'($urandom);
      vSRAMTemplate_2_boreChildrenBd_bore_wdata <= 74'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_2_boreChildrenBd_bore_wmask <= 2'($urandom);
      vSRAMTemplate_2_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_2_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_2_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_2_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_2_boreChildrenBd_bore_array <= 2'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_2_g_io_r_req_ready !== vSRAMTemplate_2_i_io_r_req_ready) begin errors++;
      $display("[%0t] SRAMTemplate_2.io_r_req_ready g=%h i=%h", $time, vSRAMTemplate_2_g_io_r_req_ready, vSRAMTemplate_2_i_io_r_req_ready); end
    if (vSRAMTemplate_2_g_io_r_resp_data_0 !== vSRAMTemplate_2_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_2.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_2_g_io_r_resp_data_0, vSRAMTemplate_2_i_io_r_resp_data_0); end
    if (vSRAMTemplate_2_g_io_r_resp_data_1 !== vSRAMTemplate_2_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_2.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_2_g_io_r_resp_data_1, vSRAMTemplate_2_i_io_r_resp_data_1); end
    if (vSRAMTemplate_2_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_2_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_2.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_2_g_boreChildrenBd_bore_rdata, vSRAMTemplate_2_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_4_io_r_req_valid;
  logic [7:0] vSRAMTemplate_4_io_r_req_bits_setIdx;
  logic vSRAMTemplate_4_io_w_req_valid;
  logic [7:0] vSRAMTemplate_4_io_w_req_bits_setIdx;
  logic [65:0] vSRAMTemplate_4_io_w_req_bits_data_0;
  logic vSRAMTemplate_4_io_broadcast_ram_hold;
  logic vSRAMTemplate_4_io_broadcast_ram_bypass;
  logic vSRAMTemplate_4_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_4_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_4_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_4_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_4_io_broadcast_ram_ctl;
  logic vSRAMTemplate_4_io_broadcast_cgen;
  logic [8:0] vSRAMTemplate_4_boreChildrenBd_bore_addr;
  logic [8:0] vSRAMTemplate_4_boreChildrenBd_bore_addr_rd;
  logic [65:0] vSRAMTemplate_4_boreChildrenBd_bore_wdata;
  logic vSRAMTemplate_4_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_4_boreChildrenBd_bore_re;
  logic vSRAMTemplate_4_boreChildrenBd_bore_we;
  logic vSRAMTemplate_4_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_4_boreChildrenBd_bore_selectedOH;
  logic [2:0] vSRAMTemplate_4_boreChildrenBd_bore_array;
  wire [65:0] vSRAMTemplate_4_g_io_r_resp_data_0;
  wire [65:0] vSRAMTemplate_4_i_io_r_resp_data_0;
  wire [65:0] vSRAMTemplate_4_g_boreChildrenBd_bore_rdata;
  wire [65:0] vSRAMTemplate_4_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_4 u_g_SRAMTemplate_4 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_4_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_4_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_4_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_4_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_4_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_4_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_4_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_4_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_4_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_4_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_4_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_4_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_4_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_4_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_4_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_4_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_4_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_4_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_4_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_4_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_4_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_4_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_4_g_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_4_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_4_xs u_i_SRAMTemplate_4 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_4_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_4_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_4_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_4_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_4_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_4_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_4_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_4_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_4_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_4_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_4_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_4_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_4_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_4_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_4_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_4_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_4_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_4_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_4_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_4_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_4_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_4_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_4_i_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_4_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_4_io_r_req_valid <= 1'b0;
      vSRAMTemplate_4_io_w_req_valid <= 1'b0;
      vSRAMTemplate_4_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_4_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_4_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_4_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_4_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_4_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_4_io_r_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_4_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_4_io_w_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_4_io_w_req_bits_data_0 <= 66'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_4_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_4_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_4_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_4_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_4_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_4_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_4_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_4_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_4_boreChildrenBd_bore_addr <= 9'($urandom);
      vSRAMTemplate_4_boreChildrenBd_bore_addr_rd <= 9'($urandom);
      vSRAMTemplate_4_boreChildrenBd_bore_wdata <= 66'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_4_boreChildrenBd_bore_wmask <= 1'($urandom);
      vSRAMTemplate_4_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_4_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_4_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_4_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_4_boreChildrenBd_bore_array <= 3'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_4_g_io_r_resp_data_0 !== vSRAMTemplate_4_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_4.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_4_g_io_r_resp_data_0, vSRAMTemplate_4_i_io_r_resp_data_0); end
    if (vSRAMTemplate_4_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_4_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_4.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_4_g_boreChildrenBd_bore_rdata, vSRAMTemplate_4_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_8_io_r_req_valid;
  logic [7:0] vSRAMTemplate_8_io_r_req_bits_setIdx;
  logic vSRAMTemplate_8_io_w_req_valid;
  logic [7:0] vSRAMTemplate_8_io_w_req_bits_setIdx;
  logic [65:0] vSRAMTemplate_8_io_w_req_bits_data_0;
  logic vSRAMTemplate_8_io_broadcast_ram_hold;
  logic vSRAMTemplate_8_io_broadcast_ram_bypass;
  logic vSRAMTemplate_8_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_8_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_8_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_8_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_8_io_broadcast_ram_ctl;
  logic vSRAMTemplate_8_io_broadcast_cgen;
  logic [8:0] vSRAMTemplate_8_boreChildrenBd_bore_addr;
  logic [8:0] vSRAMTemplate_8_boreChildrenBd_bore_addr_rd;
  logic [65:0] vSRAMTemplate_8_boreChildrenBd_bore_wdata;
  logic vSRAMTemplate_8_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_8_boreChildrenBd_bore_re;
  logic vSRAMTemplate_8_boreChildrenBd_bore_we;
  logic vSRAMTemplate_8_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_8_boreChildrenBd_bore_selectedOH;
  logic [3:0] vSRAMTemplate_8_boreChildrenBd_bore_array;
  wire [65:0] vSRAMTemplate_8_g_io_r_resp_data_0;
  wire [65:0] vSRAMTemplate_8_i_io_r_resp_data_0;
  wire [65:0] vSRAMTemplate_8_g_boreChildrenBd_bore_rdata;
  wire [65:0] vSRAMTemplate_8_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_8 u_g_SRAMTemplate_8 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_8_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_8_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_8_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_8_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_8_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_8_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_8_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_8_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_8_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_8_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_8_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_8_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_8_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_8_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_8_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_8_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_8_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_8_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_8_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_8_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_8_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_8_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_8_g_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_8_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_8_xs u_i_SRAMTemplate_8 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_8_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_8_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_8_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_8_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_8_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_8_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_8_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_8_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_8_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_8_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_8_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_8_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_8_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_8_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_8_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_8_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_8_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_8_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_8_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_8_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_8_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_8_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_8_i_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_8_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_8_io_r_req_valid <= 1'b0;
      vSRAMTemplate_8_io_w_req_valid <= 1'b0;
      vSRAMTemplate_8_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_8_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_8_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_8_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_8_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_8_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_8_io_r_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_8_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_8_io_w_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_8_io_w_req_bits_data_0 <= 66'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_8_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_8_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_8_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_8_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_8_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_8_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_8_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_8_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_8_boreChildrenBd_bore_addr <= 9'($urandom);
      vSRAMTemplate_8_boreChildrenBd_bore_addr_rd <= 9'($urandom);
      vSRAMTemplate_8_boreChildrenBd_bore_wdata <= 66'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_8_boreChildrenBd_bore_wmask <= 1'($urandom);
      vSRAMTemplate_8_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_8_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_8_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_8_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_8_boreChildrenBd_bore_array <= 4'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_8_g_io_r_resp_data_0 !== vSRAMTemplate_8_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_8.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_8_g_io_r_resp_data_0, vSRAMTemplate_8_i_io_r_resp_data_0); end
    if (vSRAMTemplate_8_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_8_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_8.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_8_g_boreChildrenBd_bore_rdata, vSRAMTemplate_8_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_16_io_r_req_valid;
  logic [7:0] vSRAMTemplate_16_io_r_req_bits_setIdx;
  logic vSRAMTemplate_16_io_w_req_valid;
  logic [7:0] vSRAMTemplate_16_io_w_req_bits_setIdx;
  logic [65:0] vSRAMTemplate_16_io_w_req_bits_data_0;
  logic vSRAMTemplate_16_io_broadcast_ram_hold;
  logic vSRAMTemplate_16_io_broadcast_ram_bypass;
  logic vSRAMTemplate_16_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_16_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_16_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_16_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_16_io_broadcast_ram_ctl;
  logic vSRAMTemplate_16_io_broadcast_cgen;
  logic [8:0] vSRAMTemplate_16_boreChildrenBd_bore_addr;
  logic [8:0] vSRAMTemplate_16_boreChildrenBd_bore_addr_rd;
  logic [65:0] vSRAMTemplate_16_boreChildrenBd_bore_wdata;
  logic vSRAMTemplate_16_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_16_boreChildrenBd_bore_re;
  logic vSRAMTemplate_16_boreChildrenBd_bore_we;
  logic vSRAMTemplate_16_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_16_boreChildrenBd_bore_selectedOH;
  logic [4:0] vSRAMTemplate_16_boreChildrenBd_bore_array;
  wire [65:0] vSRAMTemplate_16_g_io_r_resp_data_0;
  wire [65:0] vSRAMTemplate_16_i_io_r_resp_data_0;
  wire [65:0] vSRAMTemplate_16_g_boreChildrenBd_bore_rdata;
  wire [65:0] vSRAMTemplate_16_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_16 u_g_SRAMTemplate_16 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_16_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_16_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_16_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_16_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_16_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_16_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_16_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_16_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_16_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_16_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_16_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_16_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_16_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_16_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_16_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_16_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_16_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_16_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_16_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_16_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_16_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_16_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_16_g_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_16_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_16_xs u_i_SRAMTemplate_16 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_16_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_16_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_16_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_16_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_16_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_16_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_16_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_16_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_16_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_16_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_16_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_16_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_16_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_16_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_16_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_16_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_16_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_16_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_16_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_16_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_16_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_16_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_16_i_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_16_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_16_io_r_req_valid <= 1'b0;
      vSRAMTemplate_16_io_w_req_valid <= 1'b0;
      vSRAMTemplate_16_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_16_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_16_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_16_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_16_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_16_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_16_io_r_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_16_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_16_io_w_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_16_io_w_req_bits_data_0 <= 66'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_16_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_16_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_16_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_16_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_16_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_16_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_16_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_16_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_16_boreChildrenBd_bore_addr <= 9'($urandom);
      vSRAMTemplate_16_boreChildrenBd_bore_addr_rd <= 9'($urandom);
      vSRAMTemplate_16_boreChildrenBd_bore_wdata <= 66'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_16_boreChildrenBd_bore_wmask <= 1'($urandom);
      vSRAMTemplate_16_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_16_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_16_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_16_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_16_boreChildrenBd_bore_array <= 5'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_16_g_io_r_resp_data_0 !== vSRAMTemplate_16_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_16.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_16_g_io_r_resp_data_0, vSRAMTemplate_16_i_io_r_resp_data_0); end
    if (vSRAMTemplate_16_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_16_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_16.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_16_g_boreChildrenBd_bore_rdata, vSRAMTemplate_16_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_32_io_r_req_valid;
  logic [7:0] vSRAMTemplate_32_io_r_req_bits_setIdx;
  logic vSRAMTemplate_32_io_w_req_valid;
  logic [7:0] vSRAMTemplate_32_io_w_req_bits_setIdx;
  logic [65:0] vSRAMTemplate_32_io_w_req_bits_data_0;
  logic vSRAMTemplate_32_io_broadcast_ram_hold;
  logic vSRAMTemplate_32_io_broadcast_ram_bypass;
  logic vSRAMTemplate_32_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_32_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_32_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_32_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_32_io_broadcast_ram_ctl;
  logic vSRAMTemplate_32_io_broadcast_cgen;
  logic [8:0] vSRAMTemplate_32_boreChildrenBd_bore_addr;
  logic [8:0] vSRAMTemplate_32_boreChildrenBd_bore_addr_rd;
  logic [65:0] vSRAMTemplate_32_boreChildrenBd_bore_wdata;
  logic vSRAMTemplate_32_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_32_boreChildrenBd_bore_re;
  logic vSRAMTemplate_32_boreChildrenBd_bore_we;
  logic vSRAMTemplate_32_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_32_boreChildrenBd_bore_selectedOH;
  logic [5:0] vSRAMTemplate_32_boreChildrenBd_bore_array;
  wire [65:0] vSRAMTemplate_32_g_io_r_resp_data_0;
  wire [65:0] vSRAMTemplate_32_i_io_r_resp_data_0;
  wire [65:0] vSRAMTemplate_32_g_boreChildrenBd_bore_rdata;
  wire [65:0] vSRAMTemplate_32_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_32 u_g_SRAMTemplate_32 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_32_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_32_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_32_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_32_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_32_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_32_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_32_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_32_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_32_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_32_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_32_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_32_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_32_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_32_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_32_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_32_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_32_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_32_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_32_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_32_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_32_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_32_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_32_g_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_32_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_32_xs u_i_SRAMTemplate_32 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_32_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_32_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_32_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_32_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_32_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_32_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_32_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_32_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_32_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_32_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_32_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_32_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_32_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_32_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_32_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_32_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_32_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_32_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_32_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_32_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_32_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_32_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_32_i_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_32_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_32_io_r_req_valid <= 1'b0;
      vSRAMTemplate_32_io_w_req_valid <= 1'b0;
      vSRAMTemplate_32_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_32_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_32_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_32_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_32_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_32_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_32_io_r_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_32_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_32_io_w_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_32_io_w_req_bits_data_0 <= 66'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_32_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_32_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_32_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_32_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_32_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_32_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_32_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_32_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_32_boreChildrenBd_bore_addr <= 9'($urandom);
      vSRAMTemplate_32_boreChildrenBd_bore_addr_rd <= 9'($urandom);
      vSRAMTemplate_32_boreChildrenBd_bore_wdata <= 66'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_32_boreChildrenBd_bore_wmask <= 1'($urandom);
      vSRAMTemplate_32_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_32_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_32_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_32_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_32_boreChildrenBd_bore_array <= 6'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_32_g_io_r_resp_data_0 !== vSRAMTemplate_32_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_32.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_32_g_io_r_resp_data_0, vSRAMTemplate_32_i_io_r_resp_data_0); end
    if (vSRAMTemplate_32_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_32_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_32.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_32_g_boreChildrenBd_bore_rdata, vSRAMTemplate_32_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_36_io_r_req_valid;
  logic [8:0] vSRAMTemplate_36_io_r_req_bits_setIdx;
  logic vSRAMTemplate_36_io_w_req_valid;
  logic [8:0] vSRAMTemplate_36_io_w_req_bits_setIdx;
  logic [9:0] vSRAMTemplate_36_io_w_req_bits_data_0;
  logic [9:0] vSRAMTemplate_36_io_w_req_bits_data_1;
  logic [9:0] vSRAMTemplate_36_io_w_req_bits_data_2;
  logic [9:0] vSRAMTemplate_36_io_w_req_bits_data_3;
  logic [3:0] vSRAMTemplate_36_io_w_req_bits_waymask;
  logic vSRAMTemplate_36_io_broadcast_ram_hold;
  logic vSRAMTemplate_36_io_broadcast_ram_bypass;
  logic vSRAMTemplate_36_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_36_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_36_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_36_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_36_io_broadcast_ram_ctl;
  logic vSRAMTemplate_36_io_broadcast_cgen;
  logic [9:0] vSRAMTemplate_36_boreChildrenBd_bore_addr;
  logic [9:0] vSRAMTemplate_36_boreChildrenBd_bore_addr_rd;
  logic [39:0] vSRAMTemplate_36_boreChildrenBd_bore_wdata;
  logic [3:0] vSRAMTemplate_36_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_36_boreChildrenBd_bore_re;
  logic vSRAMTemplate_36_boreChildrenBd_bore_we;
  logic vSRAMTemplate_36_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_36_boreChildrenBd_bore_selectedOH;
  logic [5:0] vSRAMTemplate_36_boreChildrenBd_bore_array;
  wire vSRAMTemplate_36_g_io_r_req_ready;
  wire vSRAMTemplate_36_i_io_r_req_ready;
  wire [9:0] vSRAMTemplate_36_g_io_r_resp_data_0;
  wire [9:0] vSRAMTemplate_36_i_io_r_resp_data_0;
  wire [9:0] vSRAMTemplate_36_g_io_r_resp_data_1;
  wire [9:0] vSRAMTemplate_36_i_io_r_resp_data_1;
  wire [9:0] vSRAMTemplate_36_g_io_r_resp_data_2;
  wire [9:0] vSRAMTemplate_36_i_io_r_resp_data_2;
  wire [9:0] vSRAMTemplate_36_g_io_r_resp_data_3;
  wire [9:0] vSRAMTemplate_36_i_io_r_resp_data_3;
  wire [39:0] vSRAMTemplate_36_g_boreChildrenBd_bore_rdata;
  wire [39:0] vSRAMTemplate_36_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_36 u_g_SRAMTemplate_36 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_36_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_36_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_36_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_36_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_36_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_36_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_36_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_36_io_w_req_bits_data_3), .io_w_req_bits_waymask(vSRAMTemplate_36_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_36_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_36_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_36_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_36_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_36_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_36_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_36_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_36_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_36_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_36_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_36_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_36_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_36_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_36_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_36_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_36_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_36_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_36_g_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_36_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_36_g_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_36_g_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_36_g_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_36_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_36_xs u_i_SRAMTemplate_36 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_36_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_36_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_36_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_36_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_36_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_36_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_36_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_36_io_w_req_bits_data_3), .io_w_req_bits_waymask(vSRAMTemplate_36_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_36_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_36_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_36_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_36_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_36_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_36_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_36_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_36_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_36_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_36_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_36_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_36_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_36_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_36_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_36_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_36_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_36_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_36_i_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_36_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_36_i_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_36_i_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_36_i_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_36_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_36_io_r_req_valid <= 1'b0;
      vSRAMTemplate_36_io_w_req_valid <= 1'b0;
      vSRAMTemplate_36_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_36_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_36_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_36_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_36_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_36_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_36_io_r_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_36_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_36_io_w_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_36_io_w_req_bits_data_0 <= 10'($urandom);
      vSRAMTemplate_36_io_w_req_bits_data_1 <= 10'($urandom);
      vSRAMTemplate_36_io_w_req_bits_data_2 <= 10'($urandom);
      vSRAMTemplate_36_io_w_req_bits_data_3 <= 10'($urandom);
      vSRAMTemplate_36_io_w_req_bits_waymask <= 4'($urandom);
      vSRAMTemplate_36_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_36_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_36_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_36_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_36_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_36_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_36_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_36_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_36_boreChildrenBd_bore_addr <= 10'($urandom);
      vSRAMTemplate_36_boreChildrenBd_bore_addr_rd <= 10'($urandom);
      vSRAMTemplate_36_boreChildrenBd_bore_wdata <= 40'({$urandom(), $urandom()});
      vSRAMTemplate_36_boreChildrenBd_bore_wmask <= 4'($urandom);
      vSRAMTemplate_36_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_36_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_36_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_36_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_36_boreChildrenBd_bore_array <= 6'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_36_g_io_r_req_ready !== vSRAMTemplate_36_i_io_r_req_ready) begin errors++;
      $display("[%0t] SRAMTemplate_36.io_r_req_ready g=%h i=%h", $time, vSRAMTemplate_36_g_io_r_req_ready, vSRAMTemplate_36_i_io_r_req_ready); end
    if (vSRAMTemplate_36_g_io_r_resp_data_0 !== vSRAMTemplate_36_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_36.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_36_g_io_r_resp_data_0, vSRAMTemplate_36_i_io_r_resp_data_0); end
    if (vSRAMTemplate_36_g_io_r_resp_data_1 !== vSRAMTemplate_36_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_36.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_36_g_io_r_resp_data_1, vSRAMTemplate_36_i_io_r_resp_data_1); end
    if (vSRAMTemplate_36_g_io_r_resp_data_2 !== vSRAMTemplate_36_i_io_r_resp_data_2) begin errors++;
      $display("[%0t] SRAMTemplate_36.io_r_resp_data_2 g=%h i=%h", $time, vSRAMTemplate_36_g_io_r_resp_data_2, vSRAMTemplate_36_i_io_r_resp_data_2); end
    if (vSRAMTemplate_36_g_io_r_resp_data_3 !== vSRAMTemplate_36_i_io_r_resp_data_3) begin errors++;
      $display("[%0t] SRAMTemplate_36.io_r_resp_data_3 g=%h i=%h", $time, vSRAMTemplate_36_g_io_r_resp_data_3, vSRAMTemplate_36_i_io_r_resp_data_3); end
    if (vSRAMTemplate_36_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_36_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_36.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_36_g_boreChildrenBd_bore_rdata, vSRAMTemplate_36_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_45_io_r_req_valid;
  logic [8:0] vSRAMTemplate_45_io_r_req_bits_setIdx;
  logic vSRAMTemplate_45_io_w_req_valid;
  logic [8:0] vSRAMTemplate_45_io_w_req_bits_setIdx;
  logic [11:0] vSRAMTemplate_45_io_w_req_bits_data_0;
  logic [11:0] vSRAMTemplate_45_io_w_req_bits_data_1;
  logic [1:0] vSRAMTemplate_45_io_w_req_bits_waymask;
  logic vSRAMTemplate_45_io_broadcast_ram_hold;
  logic vSRAMTemplate_45_io_broadcast_ram_bypass;
  logic vSRAMTemplate_45_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_45_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_45_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_45_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_45_io_broadcast_ram_ctl;
  logic vSRAMTemplate_45_io_broadcast_cgen;
  logic [9:0] vSRAMTemplate_45_boreChildrenBd_bore_addr;
  logic [9:0] vSRAMTemplate_45_boreChildrenBd_bore_addr_rd;
  logic [23:0] vSRAMTemplate_45_boreChildrenBd_bore_wdata;
  logic [1:0] vSRAMTemplate_45_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_45_boreChildrenBd_bore_re;
  logic vSRAMTemplate_45_boreChildrenBd_bore_we;
  logic vSRAMTemplate_45_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_45_boreChildrenBd_bore_selectedOH;
  logic [5:0] vSRAMTemplate_45_boreChildrenBd_bore_array;
  wire vSRAMTemplate_45_g_io_r_req_ready;
  wire vSRAMTemplate_45_i_io_r_req_ready;
  wire [11:0] vSRAMTemplate_45_g_io_r_resp_data_0;
  wire [11:0] vSRAMTemplate_45_i_io_r_resp_data_0;
  wire [11:0] vSRAMTemplate_45_g_io_r_resp_data_1;
  wire [11:0] vSRAMTemplate_45_i_io_r_resp_data_1;
  wire [23:0] vSRAMTemplate_45_g_boreChildrenBd_bore_rdata;
  wire [23:0] vSRAMTemplate_45_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_45 u_g_SRAMTemplate_45 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_45_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_45_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_45_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_45_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_45_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_45_io_w_req_bits_data_1), .io_w_req_bits_waymask(vSRAMTemplate_45_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_45_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_45_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_45_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_45_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_45_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_45_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_45_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_45_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_45_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_45_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_45_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_45_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_45_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_45_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_45_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_45_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_45_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_45_g_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_45_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_45_g_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_45_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_45_xs u_i_SRAMTemplate_45 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_45_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_45_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_45_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_45_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_45_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_45_io_w_req_bits_data_1), .io_w_req_bits_waymask(vSRAMTemplate_45_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_45_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_45_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_45_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_45_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_45_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_45_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_45_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_45_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_45_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_45_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_45_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_45_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_45_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_45_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_45_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_45_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_45_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_45_i_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_45_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_45_i_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_45_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_45_io_r_req_valid <= 1'b0;
      vSRAMTemplate_45_io_w_req_valid <= 1'b0;
      vSRAMTemplate_45_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_45_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_45_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_45_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_45_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_45_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_45_io_r_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_45_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_45_io_w_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_45_io_w_req_bits_data_0 <= 12'($urandom);
      vSRAMTemplate_45_io_w_req_bits_data_1 <= 12'($urandom);
      vSRAMTemplate_45_io_w_req_bits_waymask <= 2'($urandom);
      vSRAMTemplate_45_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_45_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_45_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_45_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_45_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_45_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_45_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_45_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_45_boreChildrenBd_bore_addr <= 10'($urandom);
      vSRAMTemplate_45_boreChildrenBd_bore_addr_rd <= 10'($urandom);
      vSRAMTemplate_45_boreChildrenBd_bore_wdata <= 24'($urandom);
      vSRAMTemplate_45_boreChildrenBd_bore_wmask <= 2'($urandom);
      vSRAMTemplate_45_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_45_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_45_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_45_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_45_boreChildrenBd_bore_array <= 6'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_45_g_io_r_req_ready !== vSRAMTemplate_45_i_io_r_req_ready) begin errors++;
      $display("[%0t] SRAMTemplate_45.io_r_req_ready g=%h i=%h", $time, vSRAMTemplate_45_g_io_r_req_ready, vSRAMTemplate_45_i_io_r_req_ready); end
    if (vSRAMTemplate_45_g_io_r_resp_data_0 !== vSRAMTemplate_45_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_45.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_45_g_io_r_resp_data_0, vSRAMTemplate_45_i_io_r_resp_data_0); end
    if (vSRAMTemplate_45_g_io_r_resp_data_1 !== vSRAMTemplate_45_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_45.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_45_g_io_r_resp_data_1, vSRAMTemplate_45_i_io_r_resp_data_1); end
    if (vSRAMTemplate_45_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_45_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_45.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_45_g_boreChildrenBd_bore_rdata, vSRAMTemplate_45_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_44_io_r_req_valid;
  logic [7:0] vSRAMTemplate_44_io_r_req_bits_setIdx;
  logic vSRAMTemplate_44_io_w_req_valid;
  logic [7:0] vSRAMTemplate_44_io_w_req_bits_setIdx;
  logic vSRAMTemplate_44_io_w_req_bits_data_0;
  logic vSRAMTemplate_44_io_w_req_bits_data_1;
  logic vSRAMTemplate_44_io_w_req_bits_data_2;
  logic vSRAMTemplate_44_io_w_req_bits_data_3;
  logic vSRAMTemplate_44_io_w_req_bits_data_4;
  logic vSRAMTemplate_44_io_w_req_bits_data_5;
  logic vSRAMTemplate_44_io_w_req_bits_data_6;
  logic vSRAMTemplate_44_io_w_req_bits_data_7;
  logic vSRAMTemplate_44_io_w_req_bits_data_8;
  logic vSRAMTemplate_44_io_w_req_bits_data_9;
  logic vSRAMTemplate_44_io_w_req_bits_data_10;
  logic vSRAMTemplate_44_io_w_req_bits_data_11;
  logic vSRAMTemplate_44_io_w_req_bits_data_12;
  logic vSRAMTemplate_44_io_w_req_bits_data_13;
  logic vSRAMTemplate_44_io_w_req_bits_data_14;
  logic vSRAMTemplate_44_io_w_req_bits_data_15;
  logic [15:0] vSRAMTemplate_44_io_w_req_bits_waymask;
  logic vSRAMTemplate_44_io_broadcast_ram_hold;
  logic vSRAMTemplate_44_io_broadcast_ram_bypass;
  logic vSRAMTemplate_44_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_44_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_44_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_44_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_44_io_broadcast_ram_ctl;
  logic vSRAMTemplate_44_io_broadcast_cgen;
  logic vSRAMTemplate_44_extra_reset;
  logic [8:0] vSRAMTemplate_44_boreChildrenBd_bore_addr;
  logic [8:0] vSRAMTemplate_44_boreChildrenBd_bore_addr_rd;
  logic [15:0] vSRAMTemplate_44_boreChildrenBd_bore_wdata;
  logic [15:0] vSRAMTemplate_44_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_44_boreChildrenBd_bore_re;
  logic vSRAMTemplate_44_boreChildrenBd_bore_we;
  logic vSRAMTemplate_44_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_44_boreChildrenBd_bore_selectedOH;
  logic [5:0] vSRAMTemplate_44_boreChildrenBd_bore_array;
  wire vSRAMTemplate_44_g_io_r_req_ready;
  wire vSRAMTemplate_44_i_io_r_req_ready;
  wire vSRAMTemplate_44_g_io_r_resp_data_0;
  wire vSRAMTemplate_44_i_io_r_resp_data_0;
  wire vSRAMTemplate_44_g_io_r_resp_data_1;
  wire vSRAMTemplate_44_i_io_r_resp_data_1;
  wire vSRAMTemplate_44_g_io_r_resp_data_2;
  wire vSRAMTemplate_44_i_io_r_resp_data_2;
  wire vSRAMTemplate_44_g_io_r_resp_data_3;
  wire vSRAMTemplate_44_i_io_r_resp_data_3;
  wire vSRAMTemplate_44_g_io_r_resp_data_4;
  wire vSRAMTemplate_44_i_io_r_resp_data_4;
  wire vSRAMTemplate_44_g_io_r_resp_data_5;
  wire vSRAMTemplate_44_i_io_r_resp_data_5;
  wire vSRAMTemplate_44_g_io_r_resp_data_6;
  wire vSRAMTemplate_44_i_io_r_resp_data_6;
  wire vSRAMTemplate_44_g_io_r_resp_data_7;
  wire vSRAMTemplate_44_i_io_r_resp_data_7;
  wire vSRAMTemplate_44_g_io_r_resp_data_8;
  wire vSRAMTemplate_44_i_io_r_resp_data_8;
  wire vSRAMTemplate_44_g_io_r_resp_data_9;
  wire vSRAMTemplate_44_i_io_r_resp_data_9;
  wire vSRAMTemplate_44_g_io_r_resp_data_10;
  wire vSRAMTemplate_44_i_io_r_resp_data_10;
  wire vSRAMTemplate_44_g_io_r_resp_data_11;
  wire vSRAMTemplate_44_i_io_r_resp_data_11;
  wire vSRAMTemplate_44_g_io_r_resp_data_12;
  wire vSRAMTemplate_44_i_io_r_resp_data_12;
  wire vSRAMTemplate_44_g_io_r_resp_data_13;
  wire vSRAMTemplate_44_i_io_r_resp_data_13;
  wire vSRAMTemplate_44_g_io_r_resp_data_14;
  wire vSRAMTemplate_44_i_io_r_resp_data_14;
  wire vSRAMTemplate_44_g_io_r_resp_data_15;
  wire vSRAMTemplate_44_i_io_r_resp_data_15;
  wire [15:0] vSRAMTemplate_44_g_boreChildrenBd_bore_rdata;
  wire [15:0] vSRAMTemplate_44_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_44 u_g_SRAMTemplate_44 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_44_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_44_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_44_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_44_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_44_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_44_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_44_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_44_io_w_req_bits_data_3), .io_w_req_bits_data_4(vSRAMTemplate_44_io_w_req_bits_data_4), .io_w_req_bits_data_5(vSRAMTemplate_44_io_w_req_bits_data_5), .io_w_req_bits_data_6(vSRAMTemplate_44_io_w_req_bits_data_6), .io_w_req_bits_data_7(vSRAMTemplate_44_io_w_req_bits_data_7), .io_w_req_bits_data_8(vSRAMTemplate_44_io_w_req_bits_data_8), .io_w_req_bits_data_9(vSRAMTemplate_44_io_w_req_bits_data_9), .io_w_req_bits_data_10(vSRAMTemplate_44_io_w_req_bits_data_10), .io_w_req_bits_data_11(vSRAMTemplate_44_io_w_req_bits_data_11), .io_w_req_bits_data_12(vSRAMTemplate_44_io_w_req_bits_data_12), .io_w_req_bits_data_13(vSRAMTemplate_44_io_w_req_bits_data_13), .io_w_req_bits_data_14(vSRAMTemplate_44_io_w_req_bits_data_14), .io_w_req_bits_data_15(vSRAMTemplate_44_io_w_req_bits_data_15), .io_w_req_bits_waymask(vSRAMTemplate_44_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_44_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_44_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_44_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_44_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_44_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_44_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_44_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_44_io_broadcast_cgen), .extra_reset(vSRAMTemplate_44_extra_reset), .boreChildrenBd_bore_addr(vSRAMTemplate_44_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_44_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_44_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_44_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_44_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_44_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_44_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_44_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_44_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_44_g_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_44_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_44_g_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_44_g_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_44_g_io_r_resp_data_3), .io_r_resp_data_4(vSRAMTemplate_44_g_io_r_resp_data_4), .io_r_resp_data_5(vSRAMTemplate_44_g_io_r_resp_data_5), .io_r_resp_data_6(vSRAMTemplate_44_g_io_r_resp_data_6), .io_r_resp_data_7(vSRAMTemplate_44_g_io_r_resp_data_7), .io_r_resp_data_8(vSRAMTemplate_44_g_io_r_resp_data_8), .io_r_resp_data_9(vSRAMTemplate_44_g_io_r_resp_data_9), .io_r_resp_data_10(vSRAMTemplate_44_g_io_r_resp_data_10), .io_r_resp_data_11(vSRAMTemplate_44_g_io_r_resp_data_11), .io_r_resp_data_12(vSRAMTemplate_44_g_io_r_resp_data_12), .io_r_resp_data_13(vSRAMTemplate_44_g_io_r_resp_data_13), .io_r_resp_data_14(vSRAMTemplate_44_g_io_r_resp_data_14), .io_r_resp_data_15(vSRAMTemplate_44_g_io_r_resp_data_15), .boreChildrenBd_bore_rdata(vSRAMTemplate_44_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_44_xs u_i_SRAMTemplate_44 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_44_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_44_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_44_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_44_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_44_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_44_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_44_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_44_io_w_req_bits_data_3), .io_w_req_bits_data_4(vSRAMTemplate_44_io_w_req_bits_data_4), .io_w_req_bits_data_5(vSRAMTemplate_44_io_w_req_bits_data_5), .io_w_req_bits_data_6(vSRAMTemplate_44_io_w_req_bits_data_6), .io_w_req_bits_data_7(vSRAMTemplate_44_io_w_req_bits_data_7), .io_w_req_bits_data_8(vSRAMTemplate_44_io_w_req_bits_data_8), .io_w_req_bits_data_9(vSRAMTemplate_44_io_w_req_bits_data_9), .io_w_req_bits_data_10(vSRAMTemplate_44_io_w_req_bits_data_10), .io_w_req_bits_data_11(vSRAMTemplate_44_io_w_req_bits_data_11), .io_w_req_bits_data_12(vSRAMTemplate_44_io_w_req_bits_data_12), .io_w_req_bits_data_13(vSRAMTemplate_44_io_w_req_bits_data_13), .io_w_req_bits_data_14(vSRAMTemplate_44_io_w_req_bits_data_14), .io_w_req_bits_data_15(vSRAMTemplate_44_io_w_req_bits_data_15), .io_w_req_bits_waymask(vSRAMTemplate_44_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_44_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_44_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_44_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_44_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_44_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_44_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_44_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_44_io_broadcast_cgen), .extra_reset(vSRAMTemplate_44_extra_reset), .boreChildrenBd_bore_addr(vSRAMTemplate_44_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_44_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_44_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_44_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_44_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_44_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_44_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_44_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_44_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_44_i_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_44_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_44_i_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_44_i_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_44_i_io_r_resp_data_3), .io_r_resp_data_4(vSRAMTemplate_44_i_io_r_resp_data_4), .io_r_resp_data_5(vSRAMTemplate_44_i_io_r_resp_data_5), .io_r_resp_data_6(vSRAMTemplate_44_i_io_r_resp_data_6), .io_r_resp_data_7(vSRAMTemplate_44_i_io_r_resp_data_7), .io_r_resp_data_8(vSRAMTemplate_44_i_io_r_resp_data_8), .io_r_resp_data_9(vSRAMTemplate_44_i_io_r_resp_data_9), .io_r_resp_data_10(vSRAMTemplate_44_i_io_r_resp_data_10), .io_r_resp_data_11(vSRAMTemplate_44_i_io_r_resp_data_11), .io_r_resp_data_12(vSRAMTemplate_44_i_io_r_resp_data_12), .io_r_resp_data_13(vSRAMTemplate_44_i_io_r_resp_data_13), .io_r_resp_data_14(vSRAMTemplate_44_i_io_r_resp_data_14), .io_r_resp_data_15(vSRAMTemplate_44_i_io_r_resp_data_15), .boreChildrenBd_bore_rdata(vSRAMTemplate_44_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_44_io_r_req_valid <= 1'b0;
      vSRAMTemplate_44_io_w_req_valid <= 1'b0;
      vSRAMTemplate_44_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_44_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_44_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_44_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_44_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_44_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_44_io_r_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_44_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_44_io_w_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_44_io_w_req_bits_data_0 <= 1'($urandom);
      vSRAMTemplate_44_io_w_req_bits_data_1 <= 1'($urandom);
      vSRAMTemplate_44_io_w_req_bits_data_2 <= 1'($urandom);
      vSRAMTemplate_44_io_w_req_bits_data_3 <= 1'($urandom);
      vSRAMTemplate_44_io_w_req_bits_data_4 <= 1'($urandom);
      vSRAMTemplate_44_io_w_req_bits_data_5 <= 1'($urandom);
      vSRAMTemplate_44_io_w_req_bits_data_6 <= 1'($urandom);
      vSRAMTemplate_44_io_w_req_bits_data_7 <= 1'($urandom);
      vSRAMTemplate_44_io_w_req_bits_data_8 <= 1'($urandom);
      vSRAMTemplate_44_io_w_req_bits_data_9 <= 1'($urandom);
      vSRAMTemplate_44_io_w_req_bits_data_10 <= 1'($urandom);
      vSRAMTemplate_44_io_w_req_bits_data_11 <= 1'($urandom);
      vSRAMTemplate_44_io_w_req_bits_data_12 <= 1'($urandom);
      vSRAMTemplate_44_io_w_req_bits_data_13 <= 1'($urandom);
      vSRAMTemplate_44_io_w_req_bits_data_14 <= 1'($urandom);
      vSRAMTemplate_44_io_w_req_bits_data_15 <= 1'($urandom);
      vSRAMTemplate_44_io_w_req_bits_waymask <= 16'($urandom);
      vSRAMTemplate_44_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_44_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_44_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_44_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_44_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_44_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_44_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_44_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_44_extra_reset <= 1'($urandom);
      vSRAMTemplate_44_boreChildrenBd_bore_addr <= 9'($urandom);
      vSRAMTemplate_44_boreChildrenBd_bore_addr_rd <= 9'($urandom);
      vSRAMTemplate_44_boreChildrenBd_bore_wdata <= 16'($urandom);
      vSRAMTemplate_44_boreChildrenBd_bore_wmask <= 16'($urandom);
      vSRAMTemplate_44_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_44_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_44_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_44_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_44_boreChildrenBd_bore_array <= 6'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_44_g_io_r_req_ready !== vSRAMTemplate_44_i_io_r_req_ready) begin errors++;
      $display("[%0t] SRAMTemplate_44.io_r_req_ready g=%h i=%h", $time, vSRAMTemplate_44_g_io_r_req_ready, vSRAMTemplate_44_i_io_r_req_ready); end
    if (vSRAMTemplate_44_g_io_r_resp_data_0 !== vSRAMTemplate_44_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_44.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_44_g_io_r_resp_data_0, vSRAMTemplate_44_i_io_r_resp_data_0); end
    if (vSRAMTemplate_44_g_io_r_resp_data_1 !== vSRAMTemplate_44_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_44.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_44_g_io_r_resp_data_1, vSRAMTemplate_44_i_io_r_resp_data_1); end
    if (vSRAMTemplate_44_g_io_r_resp_data_2 !== vSRAMTemplate_44_i_io_r_resp_data_2) begin errors++;
      $display("[%0t] SRAMTemplate_44.io_r_resp_data_2 g=%h i=%h", $time, vSRAMTemplate_44_g_io_r_resp_data_2, vSRAMTemplate_44_i_io_r_resp_data_2); end
    if (vSRAMTemplate_44_g_io_r_resp_data_3 !== vSRAMTemplate_44_i_io_r_resp_data_3) begin errors++;
      $display("[%0t] SRAMTemplate_44.io_r_resp_data_3 g=%h i=%h", $time, vSRAMTemplate_44_g_io_r_resp_data_3, vSRAMTemplate_44_i_io_r_resp_data_3); end
    if (vSRAMTemplate_44_g_io_r_resp_data_4 !== vSRAMTemplate_44_i_io_r_resp_data_4) begin errors++;
      $display("[%0t] SRAMTemplate_44.io_r_resp_data_4 g=%h i=%h", $time, vSRAMTemplate_44_g_io_r_resp_data_4, vSRAMTemplate_44_i_io_r_resp_data_4); end
    if (vSRAMTemplate_44_g_io_r_resp_data_5 !== vSRAMTemplate_44_i_io_r_resp_data_5) begin errors++;
      $display("[%0t] SRAMTemplate_44.io_r_resp_data_5 g=%h i=%h", $time, vSRAMTemplate_44_g_io_r_resp_data_5, vSRAMTemplate_44_i_io_r_resp_data_5); end
    if (vSRAMTemplate_44_g_io_r_resp_data_6 !== vSRAMTemplate_44_i_io_r_resp_data_6) begin errors++;
      $display("[%0t] SRAMTemplate_44.io_r_resp_data_6 g=%h i=%h", $time, vSRAMTemplate_44_g_io_r_resp_data_6, vSRAMTemplate_44_i_io_r_resp_data_6); end
    if (vSRAMTemplate_44_g_io_r_resp_data_7 !== vSRAMTemplate_44_i_io_r_resp_data_7) begin errors++;
      $display("[%0t] SRAMTemplate_44.io_r_resp_data_7 g=%h i=%h", $time, vSRAMTemplate_44_g_io_r_resp_data_7, vSRAMTemplate_44_i_io_r_resp_data_7); end
    if (vSRAMTemplate_44_g_io_r_resp_data_8 !== vSRAMTemplate_44_i_io_r_resp_data_8) begin errors++;
      $display("[%0t] SRAMTemplate_44.io_r_resp_data_8 g=%h i=%h", $time, vSRAMTemplate_44_g_io_r_resp_data_8, vSRAMTemplate_44_i_io_r_resp_data_8); end
    if (vSRAMTemplate_44_g_io_r_resp_data_9 !== vSRAMTemplate_44_i_io_r_resp_data_9) begin errors++;
      $display("[%0t] SRAMTemplate_44.io_r_resp_data_9 g=%h i=%h", $time, vSRAMTemplate_44_g_io_r_resp_data_9, vSRAMTemplate_44_i_io_r_resp_data_9); end
    if (vSRAMTemplate_44_g_io_r_resp_data_10 !== vSRAMTemplate_44_i_io_r_resp_data_10) begin errors++;
      $display("[%0t] SRAMTemplate_44.io_r_resp_data_10 g=%h i=%h", $time, vSRAMTemplate_44_g_io_r_resp_data_10, vSRAMTemplate_44_i_io_r_resp_data_10); end
    if (vSRAMTemplate_44_g_io_r_resp_data_11 !== vSRAMTemplate_44_i_io_r_resp_data_11) begin errors++;
      $display("[%0t] SRAMTemplate_44.io_r_resp_data_11 g=%h i=%h", $time, vSRAMTemplate_44_g_io_r_resp_data_11, vSRAMTemplate_44_i_io_r_resp_data_11); end
    if (vSRAMTemplate_44_g_io_r_resp_data_12 !== vSRAMTemplate_44_i_io_r_resp_data_12) begin errors++;
      $display("[%0t] SRAMTemplate_44.io_r_resp_data_12 g=%h i=%h", $time, vSRAMTemplate_44_g_io_r_resp_data_12, vSRAMTemplate_44_i_io_r_resp_data_12); end
    if (vSRAMTemplate_44_g_io_r_resp_data_13 !== vSRAMTemplate_44_i_io_r_resp_data_13) begin errors++;
      $display("[%0t] SRAMTemplate_44.io_r_resp_data_13 g=%h i=%h", $time, vSRAMTemplate_44_g_io_r_resp_data_13, vSRAMTemplate_44_i_io_r_resp_data_13); end
    if (vSRAMTemplate_44_g_io_r_resp_data_14 !== vSRAMTemplate_44_i_io_r_resp_data_14) begin errors++;
      $display("[%0t] SRAMTemplate_44.io_r_resp_data_14 g=%h i=%h", $time, vSRAMTemplate_44_g_io_r_resp_data_14, vSRAMTemplate_44_i_io_r_resp_data_14); end
    if (vSRAMTemplate_44_g_io_r_resp_data_15 !== vSRAMTemplate_44_i_io_r_resp_data_15) begin errors++;
      $display("[%0t] SRAMTemplate_44.io_r_resp_data_15 g=%h i=%h", $time, vSRAMTemplate_44_g_io_r_resp_data_15, vSRAMTemplate_44_i_io_r_resp_data_15); end
    if (vSRAMTemplate_44_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_44_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_44.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_44_g_boreChildrenBd_bore_rdata, vSRAMTemplate_44_i_boreChildrenBd_bore_rdata); end
  end

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 40000;
    $fsdbDumpfile("novas.fsdb"); $fsdbDumpvars(0, tb);
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("---------------------------------------------");
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
