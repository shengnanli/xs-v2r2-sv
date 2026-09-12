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

  logic vSRAMTemplate_100_io_r_req_valid;
  logic [7:0] vSRAMTemplate_100_io_r_req_bits_setIdx;
  logic vSRAMTemplate_100_io_w_req_valid;
  logic [7:0] vSRAMTemplate_100_io_w_req_bits_setIdx;
  logic [71:0] vSRAMTemplate_100_io_w_req_bits_data_0;
  logic vSRAMTemplate_100_io_broadcast_ram_hold;
  logic vSRAMTemplate_100_io_broadcast_ram_bypass;
  logic vSRAMTemplate_100_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_100_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_100_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_100_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_100_io_broadcast_ram_ctl;
  logic vSRAMTemplate_100_io_broadcast_cgen;
  logic [8:0] vSRAMTemplate_100_boreChildrenBd_bore_addr;
  logic [8:0] vSRAMTemplate_100_boreChildrenBd_bore_addr_rd;
  logic [71:0] vSRAMTemplate_100_boreChildrenBd_bore_wdata;
  logic vSRAMTemplate_100_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_100_boreChildrenBd_bore_re;
  logic vSRAMTemplate_100_boreChildrenBd_bore_we;
  logic vSRAMTemplate_100_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_100_boreChildrenBd_bore_selectedOH;
  logic [4:0] vSRAMTemplate_100_boreChildrenBd_bore_array;
  wire [71:0] vSRAMTemplate_100_g_io_r_resp_data_0;
  wire [71:0] vSRAMTemplate_100_i_io_r_resp_data_0;
  wire [71:0] vSRAMTemplate_100_g_boreChildrenBd_bore_rdata;
  wire [71:0] vSRAMTemplate_100_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_100 u_g_SRAMTemplate_100 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_100_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_100_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_100_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_100_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_100_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_100_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_100_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_100_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_100_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_100_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_100_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_100_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_100_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_100_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_100_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_100_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_100_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_100_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_100_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_100_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_100_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_100_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_100_g_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_100_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_100_xs u_i_SRAMTemplate_100 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_100_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_100_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_100_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_100_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_100_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_100_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_100_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_100_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_100_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_100_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_100_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_100_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_100_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_100_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_100_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_100_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_100_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_100_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_100_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_100_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_100_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_100_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_100_i_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_100_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_100_io_r_req_valid <= 1'b0;
      vSRAMTemplate_100_io_w_req_valid <= 1'b0;
      vSRAMTemplate_100_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_100_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_100_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_100_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_100_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_100_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_100_io_r_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_100_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_100_io_w_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_100_io_w_req_bits_data_0 <= 72'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_100_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_100_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_100_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_100_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_100_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_100_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_100_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_100_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_100_boreChildrenBd_bore_addr <= 9'($urandom);
      vSRAMTemplate_100_boreChildrenBd_bore_addr_rd <= 9'($urandom);
      vSRAMTemplate_100_boreChildrenBd_bore_wdata <= 72'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_100_boreChildrenBd_bore_wmask <= 1'($urandom);
      vSRAMTemplate_100_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_100_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_100_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_100_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_100_boreChildrenBd_bore_array <= 5'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_100_g_io_r_resp_data_0 !== vSRAMTemplate_100_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_100.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_100_g_io_r_resp_data_0, vSRAMTemplate_100_i_io_r_resp_data_0); end
    if (vSRAMTemplate_100_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_100_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_100.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_100_g_boreChildrenBd_bore_rdata, vSRAMTemplate_100_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_116_io_r_req_valid;
  logic [7:0] vSRAMTemplate_116_io_r_req_bits_setIdx;
  logic vSRAMTemplate_116_io_w_req_valid;
  logic [7:0] vSRAMTemplate_116_io_w_req_bits_setIdx;
  logic [42:0] vSRAMTemplate_116_io_w_req_bits_data_0;
  logic [42:0] vSRAMTemplate_116_io_w_req_bits_data_1;
  logic [1:0] vSRAMTemplate_116_io_w_req_bits_waymask;
  logic vSRAMTemplate_116_io_broadcast_ram_hold;
  logic vSRAMTemplate_116_io_broadcast_ram_bypass;
  logic vSRAMTemplate_116_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_116_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_116_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_116_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_116_io_broadcast_ram_ctl;
  logic vSRAMTemplate_116_io_broadcast_cgen;
  logic [8:0] vSRAMTemplate_116_boreChildrenBd_bore_addr;
  logic [8:0] vSRAMTemplate_116_boreChildrenBd_bore_addr_rd;
  logic [85:0] vSRAMTemplate_116_boreChildrenBd_bore_wdata;
  logic [1:0] vSRAMTemplate_116_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_116_boreChildrenBd_bore_re;
  logic vSRAMTemplate_116_boreChildrenBd_bore_we;
  logic vSRAMTemplate_116_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_116_boreChildrenBd_bore_selectedOH;
  logic [5:0] vSRAMTemplate_116_boreChildrenBd_bore_array;
  wire [42:0] vSRAMTemplate_116_g_io_r_resp_data_0;
  wire [42:0] vSRAMTemplate_116_i_io_r_resp_data_0;
  wire [42:0] vSRAMTemplate_116_g_io_r_resp_data_1;
  wire [42:0] vSRAMTemplate_116_i_io_r_resp_data_1;
  wire [85:0] vSRAMTemplate_116_g_boreChildrenBd_bore_rdata;
  wire [85:0] vSRAMTemplate_116_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_116 u_g_SRAMTemplate_116 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_116_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_116_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_116_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_116_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_116_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_116_io_w_req_bits_data_1), .io_w_req_bits_waymask(vSRAMTemplate_116_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_116_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_116_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_116_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_116_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_116_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_116_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_116_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_116_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_116_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_116_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_116_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_116_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_116_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_116_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_116_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_116_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_116_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_116_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_116_g_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_116_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_116_xs u_i_SRAMTemplate_116 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_116_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_116_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_116_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_116_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_116_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_116_io_w_req_bits_data_1), .io_w_req_bits_waymask(vSRAMTemplate_116_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_116_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_116_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_116_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_116_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_116_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_116_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_116_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_116_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_116_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_116_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_116_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_116_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_116_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_116_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_116_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_116_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_116_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_116_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_116_i_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_116_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_116_io_r_req_valid <= 1'b0;
      vSRAMTemplate_116_io_w_req_valid <= 1'b0;
      vSRAMTemplate_116_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_116_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_116_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_116_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_116_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_116_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_116_io_r_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_116_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_116_io_w_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_116_io_w_req_bits_data_0 <= 43'({$urandom(), $urandom()});
      vSRAMTemplate_116_io_w_req_bits_data_1 <= 43'({$urandom(), $urandom()});
      vSRAMTemplate_116_io_w_req_bits_waymask <= 2'($urandom);
      vSRAMTemplate_116_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_116_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_116_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_116_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_116_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_116_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_116_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_116_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_116_boreChildrenBd_bore_addr <= 9'($urandom);
      vSRAMTemplate_116_boreChildrenBd_bore_addr_rd <= 9'($urandom);
      vSRAMTemplate_116_boreChildrenBd_bore_wdata <= 86'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_116_boreChildrenBd_bore_wmask <= 2'($urandom);
      vSRAMTemplate_116_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_116_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_116_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_116_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_116_boreChildrenBd_bore_array <= 6'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_116_g_io_r_resp_data_0 !== vSRAMTemplate_116_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_116.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_116_g_io_r_resp_data_0, vSRAMTemplate_116_i_io_r_resp_data_0); end
    if (vSRAMTemplate_116_g_io_r_resp_data_1 !== vSRAMTemplate_116_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_116.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_116_g_io_r_resp_data_1, vSRAMTemplate_116_i_io_r_resp_data_1); end
    if (vSRAMTemplate_116_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_116_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_116.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_116_g_boreChildrenBd_bore_rdata, vSRAMTemplate_116_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_124_io_r_req_valid;
  logic [4:0] vSRAMTemplate_124_io_r_req_bits_setIdx;
  logic vSRAMTemplate_124_io_w_req_valid;
  logic [4:0] vSRAMTemplate_124_io_w_req_bits_setIdx;
  logic [44:0] vSRAMTemplate_124_io_w_req_bits_data_0;
  logic [44:0] vSRAMTemplate_124_io_w_req_bits_data_1;
  logic [1:0] vSRAMTemplate_124_io_w_req_bits_waymask;
  logic vSRAMTemplate_124_io_broadcast_ram_hold;
  logic vSRAMTemplate_124_io_broadcast_ram_bypass;
  logic vSRAMTemplate_124_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_124_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_124_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_124_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_124_io_broadcast_ram_ctl;
  logic vSRAMTemplate_124_io_broadcast_cgen;
  logic [5:0] vSRAMTemplate_124_boreChildrenBd_bore_addr;
  logic [5:0] vSRAMTemplate_124_boreChildrenBd_bore_addr_rd;
  logic [89:0] vSRAMTemplate_124_boreChildrenBd_bore_wdata;
  logic [1:0] vSRAMTemplate_124_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_124_boreChildrenBd_bore_re;
  logic vSRAMTemplate_124_boreChildrenBd_bore_we;
  logic vSRAMTemplate_124_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_124_boreChildrenBd_bore_selectedOH;
  logic [5:0] vSRAMTemplate_124_boreChildrenBd_bore_array;
  wire [44:0] vSRAMTemplate_124_g_io_r_resp_data_0;
  wire [44:0] vSRAMTemplate_124_i_io_r_resp_data_0;
  wire [44:0] vSRAMTemplate_124_g_io_r_resp_data_1;
  wire [44:0] vSRAMTemplate_124_i_io_r_resp_data_1;
  wire [89:0] vSRAMTemplate_124_g_boreChildrenBd_bore_rdata;
  wire [89:0] vSRAMTemplate_124_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_124 u_g_SRAMTemplate_124 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_124_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_124_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_124_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_124_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_124_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_124_io_w_req_bits_data_1), .io_w_req_bits_waymask(vSRAMTemplate_124_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_124_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_124_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_124_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_124_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_124_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_124_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_124_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_124_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_124_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_124_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_124_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_124_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_124_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_124_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_124_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_124_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_124_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_124_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_124_g_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_124_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_124_xs u_i_SRAMTemplate_124 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_124_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_124_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_124_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_124_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_124_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_124_io_w_req_bits_data_1), .io_w_req_bits_waymask(vSRAMTemplate_124_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_124_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_124_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_124_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_124_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_124_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_124_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_124_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_124_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_124_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_124_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_124_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_124_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_124_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_124_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_124_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_124_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_124_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_124_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_124_i_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_124_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_124_io_r_req_valid <= 1'b0;
      vSRAMTemplate_124_io_w_req_valid <= 1'b0;
      vSRAMTemplate_124_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_124_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_124_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_124_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_124_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_124_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_124_io_r_req_bits_setIdx <= 5'($urandom);
      vSRAMTemplate_124_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_124_io_w_req_bits_setIdx <= 5'($urandom);
      vSRAMTemplate_124_io_w_req_bits_data_0 <= 45'({$urandom(), $urandom()});
      vSRAMTemplate_124_io_w_req_bits_data_1 <= 45'({$urandom(), $urandom()});
      vSRAMTemplate_124_io_w_req_bits_waymask <= 2'($urandom);
      vSRAMTemplate_124_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_124_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_124_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_124_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_124_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_124_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_124_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_124_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_124_boreChildrenBd_bore_addr <= 6'($urandom);
      vSRAMTemplate_124_boreChildrenBd_bore_addr_rd <= 6'($urandom);
      vSRAMTemplate_124_boreChildrenBd_bore_wdata <= 90'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_124_boreChildrenBd_bore_wmask <= 2'($urandom);
      vSRAMTemplate_124_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_124_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_124_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_124_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_124_boreChildrenBd_bore_array <= 6'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_124_g_io_r_resp_data_0 !== vSRAMTemplate_124_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_124.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_124_g_io_r_resp_data_0, vSRAMTemplate_124_i_io_r_resp_data_0); end
    if (vSRAMTemplate_124_g_io_r_resp_data_1 !== vSRAMTemplate_124_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_124.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_124_g_io_r_resp_data_1, vSRAMTemplate_124_i_io_r_resp_data_1); end
    if (vSRAMTemplate_124_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_124_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_124.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_124_g_boreChildrenBd_bore_rdata, vSRAMTemplate_124_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_129_io_r_req_valid;
  logic [5:0] vSRAMTemplate_129_io_r_req_bits_setIdx;
  logic vSRAMTemplate_129_io_w_req_valid;
  logic [5:0] vSRAMTemplate_129_io_w_req_bits_setIdx;
  logic [56:0] vSRAMTemplate_129_io_w_req_bits_data_0;
  logic [56:0] vSRAMTemplate_129_io_w_req_bits_data_1;
  logic [1:0] vSRAMTemplate_129_io_w_req_bits_waymask;
  logic vSRAMTemplate_129_io_broadcast_ram_hold;
  logic vSRAMTemplate_129_io_broadcast_ram_bypass;
  logic vSRAMTemplate_129_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_129_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_129_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_129_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_129_io_broadcast_ram_ctl;
  logic vSRAMTemplate_129_io_broadcast_cgen;
  logic [6:0] vSRAMTemplate_129_boreChildrenBd_bore_addr;
  logic [6:0] vSRAMTemplate_129_boreChildrenBd_bore_addr_rd;
  logic [113:0] vSRAMTemplate_129_boreChildrenBd_bore_wdata;
  logic [1:0] vSRAMTemplate_129_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_129_boreChildrenBd_bore_re;
  logic vSRAMTemplate_129_boreChildrenBd_bore_we;
  logic vSRAMTemplate_129_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_129_boreChildrenBd_bore_selectedOH;
  logic [5:0] vSRAMTemplate_129_boreChildrenBd_bore_array;
  wire [56:0] vSRAMTemplate_129_g_io_r_resp_data_0;
  wire [56:0] vSRAMTemplate_129_i_io_r_resp_data_0;
  wire [56:0] vSRAMTemplate_129_g_io_r_resp_data_1;
  wire [56:0] vSRAMTemplate_129_i_io_r_resp_data_1;
  wire [113:0] vSRAMTemplate_129_g_boreChildrenBd_bore_rdata;
  wire [113:0] vSRAMTemplate_129_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_129 u_g_SRAMTemplate_129 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_129_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_129_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_129_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_129_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_129_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_129_io_w_req_bits_data_1), .io_w_req_bits_waymask(vSRAMTemplate_129_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_129_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_129_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_129_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_129_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_129_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_129_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_129_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_129_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_129_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_129_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_129_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_129_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_129_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_129_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_129_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_129_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_129_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_129_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_129_g_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_129_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_129_xs u_i_SRAMTemplate_129 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_129_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_129_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_129_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_129_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_129_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_129_io_w_req_bits_data_1), .io_w_req_bits_waymask(vSRAMTemplate_129_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_129_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_129_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_129_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_129_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_129_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_129_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_129_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_129_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_129_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_129_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_129_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_129_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_129_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_129_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_129_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_129_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_129_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_129_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_129_i_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_129_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_129_io_r_req_valid <= 1'b0;
      vSRAMTemplate_129_io_w_req_valid <= 1'b0;
      vSRAMTemplate_129_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_129_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_129_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_129_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_129_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_129_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_129_io_r_req_bits_setIdx <= 6'($urandom);
      vSRAMTemplate_129_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_129_io_w_req_bits_setIdx <= 6'($urandom);
      vSRAMTemplate_129_io_w_req_bits_data_0 <= 57'({$urandom(), $urandom()});
      vSRAMTemplate_129_io_w_req_bits_data_1 <= 57'({$urandom(), $urandom()});
      vSRAMTemplate_129_io_w_req_bits_waymask <= 2'($urandom);
      vSRAMTemplate_129_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_129_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_129_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_129_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_129_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_129_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_129_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_129_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_129_boreChildrenBd_bore_addr <= 7'($urandom);
      vSRAMTemplate_129_boreChildrenBd_bore_addr_rd <= 7'($urandom);
      vSRAMTemplate_129_boreChildrenBd_bore_wdata <= 114'({$urandom(), $urandom(), $urandom(), $urandom()});
      vSRAMTemplate_129_boreChildrenBd_bore_wmask <= 2'($urandom);
      vSRAMTemplate_129_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_129_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_129_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_129_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_129_boreChildrenBd_bore_array <= 6'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_129_g_io_r_resp_data_0 !== vSRAMTemplate_129_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_129.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_129_g_io_r_resp_data_0, vSRAMTemplate_129_i_io_r_resp_data_0); end
    if (vSRAMTemplate_129_g_io_r_resp_data_1 !== vSRAMTemplate_129_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_129.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_129_g_io_r_resp_data_1, vSRAMTemplate_129_i_io_r_resp_data_1); end
    if (vSRAMTemplate_129_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_129_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_129.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_129_g_boreChildrenBd_bore_rdata, vSRAMTemplate_129_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_143_io_r_req_valid;
  logic [5:0] vSRAMTemplate_143_io_r_req_bits_setIdx;
  logic vSRAMTemplate_143_io_w_req_valid;
  logic [5:0] vSRAMTemplate_143_io_w_req_bits_setIdx;
  logic [56:0] vSRAMTemplate_143_io_w_req_bits_data_0;
  logic [56:0] vSRAMTemplate_143_io_w_req_bits_data_1;
  logic [1:0] vSRAMTemplate_143_io_w_req_bits_waymask;
  logic vSRAMTemplate_143_io_broadcast_ram_hold;
  logic vSRAMTemplate_143_io_broadcast_ram_bypass;
  logic vSRAMTemplate_143_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_143_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_143_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_143_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_143_io_broadcast_ram_ctl;
  logic vSRAMTemplate_143_io_broadcast_cgen;
  logic [6:0] vSRAMTemplate_143_boreChildrenBd_bore_addr;
  logic [6:0] vSRAMTemplate_143_boreChildrenBd_bore_addr_rd;
  logic [113:0] vSRAMTemplate_143_boreChildrenBd_bore_wdata;
  logic [1:0] vSRAMTemplate_143_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_143_boreChildrenBd_bore_re;
  logic vSRAMTemplate_143_boreChildrenBd_bore_we;
  logic vSRAMTemplate_143_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_143_boreChildrenBd_bore_selectedOH;
  logic [6:0] vSRAMTemplate_143_boreChildrenBd_bore_array;
  wire [56:0] vSRAMTemplate_143_g_io_r_resp_data_0;
  wire [56:0] vSRAMTemplate_143_i_io_r_resp_data_0;
  wire [56:0] vSRAMTemplate_143_g_io_r_resp_data_1;
  wire [56:0] vSRAMTemplate_143_i_io_r_resp_data_1;
  wire [113:0] vSRAMTemplate_143_g_boreChildrenBd_bore_rdata;
  wire [113:0] vSRAMTemplate_143_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_143 u_g_SRAMTemplate_143 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_143_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_143_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_143_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_143_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_143_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_143_io_w_req_bits_data_1), .io_w_req_bits_waymask(vSRAMTemplate_143_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_143_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_143_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_143_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_143_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_143_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_143_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_143_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_143_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_143_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_143_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_143_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_143_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_143_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_143_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_143_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_143_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_143_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_143_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_143_g_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_143_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_143_xs u_i_SRAMTemplate_143 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_143_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_143_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_143_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_143_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_143_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_143_io_w_req_bits_data_1), .io_w_req_bits_waymask(vSRAMTemplate_143_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_143_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_143_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_143_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_143_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_143_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_143_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_143_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_143_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_143_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_143_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_143_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_143_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_143_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_143_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_143_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_143_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_143_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_143_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_143_i_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_143_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_143_io_r_req_valid <= 1'b0;
      vSRAMTemplate_143_io_w_req_valid <= 1'b0;
      vSRAMTemplate_143_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_143_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_143_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_143_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_143_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_143_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_143_io_r_req_bits_setIdx <= 6'($urandom);
      vSRAMTemplate_143_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_143_io_w_req_bits_setIdx <= 6'($urandom);
      vSRAMTemplate_143_io_w_req_bits_data_0 <= 57'({$urandom(), $urandom()});
      vSRAMTemplate_143_io_w_req_bits_data_1 <= 57'({$urandom(), $urandom()});
      vSRAMTemplate_143_io_w_req_bits_waymask <= 2'($urandom);
      vSRAMTemplate_143_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_143_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_143_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_143_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_143_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_143_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_143_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_143_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_143_boreChildrenBd_bore_addr <= 7'($urandom);
      vSRAMTemplate_143_boreChildrenBd_bore_addr_rd <= 7'($urandom);
      vSRAMTemplate_143_boreChildrenBd_bore_wdata <= 114'({$urandom(), $urandom(), $urandom(), $urandom()});
      vSRAMTemplate_143_boreChildrenBd_bore_wmask <= 2'($urandom);
      vSRAMTemplate_143_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_143_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_143_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_143_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_143_boreChildrenBd_bore_array <= 7'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_143_g_io_r_resp_data_0 !== vSRAMTemplate_143_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_143.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_143_g_io_r_resp_data_0, vSRAMTemplate_143_i_io_r_resp_data_0); end
    if (vSRAMTemplate_143_g_io_r_resp_data_1 !== vSRAMTemplate_143_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_143.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_143_g_io_r_resp_data_1, vSRAMTemplate_143_i_io_r_resp_data_1); end
    if (vSRAMTemplate_143_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_143_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_143.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_143_g_boreChildrenBd_bore_rdata, vSRAMTemplate_143_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_148_io_r_req_valid;
  logic [8:0] vSRAMTemplate_148_io_r_req_bits_setIdx;
  logic vSRAMTemplate_148_io_w_req_valid;
  logic [8:0] vSRAMTemplate_148_io_w_req_bits_setIdx;
  logic [18:0] vSRAMTemplate_148_io_w_req_bits_data_0;
  logic [18:0] vSRAMTemplate_148_io_w_req_bits_data_1;
  logic [18:0] vSRAMTemplate_148_io_w_req_bits_data_2;
  logic [18:0] vSRAMTemplate_148_io_w_req_bits_data_3;
  logic [3:0] vSRAMTemplate_148_io_w_req_bits_waymask;
  logic vSRAMTemplate_148_io_broadcast_ram_hold;
  logic vSRAMTemplate_148_io_broadcast_ram_bypass;
  logic vSRAMTemplate_148_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_148_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_148_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_148_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_148_io_broadcast_ram_ctl;
  logic vSRAMTemplate_148_io_broadcast_cgen;
  logic [9:0] vSRAMTemplate_148_boreChildrenBd_bore_addr;
  logic [9:0] vSRAMTemplate_148_boreChildrenBd_bore_addr_rd;
  logic [75:0] vSRAMTemplate_148_boreChildrenBd_bore_wdata;
  logic [3:0] vSRAMTemplate_148_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_148_boreChildrenBd_bore_re;
  logic vSRAMTemplate_148_boreChildrenBd_bore_we;
  logic vSRAMTemplate_148_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_148_boreChildrenBd_bore_selectedOH;
  logic [1:0] vSRAMTemplate_148_boreChildrenBd_bore_array;
  wire vSRAMTemplate_148_g_io_r_req_ready;
  wire vSRAMTemplate_148_i_io_r_req_ready;
  wire [18:0] vSRAMTemplate_148_g_io_r_resp_data_0;
  wire [18:0] vSRAMTemplate_148_i_io_r_resp_data_0;
  wire [18:0] vSRAMTemplate_148_g_io_r_resp_data_1;
  wire [18:0] vSRAMTemplate_148_i_io_r_resp_data_1;
  wire [18:0] vSRAMTemplate_148_g_io_r_resp_data_2;
  wire [18:0] vSRAMTemplate_148_i_io_r_resp_data_2;
  wire [18:0] vSRAMTemplate_148_g_io_r_resp_data_3;
  wire [18:0] vSRAMTemplate_148_i_io_r_resp_data_3;
  wire [75:0] vSRAMTemplate_148_g_boreChildrenBd_bore_rdata;
  wire [75:0] vSRAMTemplate_148_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_148 u_g_SRAMTemplate_148 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_148_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_148_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_148_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_148_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_148_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_148_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_148_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_148_io_w_req_bits_data_3), .io_w_req_bits_waymask(vSRAMTemplate_148_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_148_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_148_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_148_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_148_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_148_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_148_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_148_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_148_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_148_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_148_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_148_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_148_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_148_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_148_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_148_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_148_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_148_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_148_g_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_148_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_148_g_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_148_g_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_148_g_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_148_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_148_xs u_i_SRAMTemplate_148 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_148_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_148_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_148_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_148_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_148_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_148_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_148_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_148_io_w_req_bits_data_3), .io_w_req_bits_waymask(vSRAMTemplate_148_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_148_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_148_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_148_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_148_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_148_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_148_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_148_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_148_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_148_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_148_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_148_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_148_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_148_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_148_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_148_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_148_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_148_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_148_i_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_148_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_148_i_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_148_i_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_148_i_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_148_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_148_io_r_req_valid <= 1'b0;
      vSRAMTemplate_148_io_w_req_valid <= 1'b0;
      vSRAMTemplate_148_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_148_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_148_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_148_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_148_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_148_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_148_io_r_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_148_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_148_io_w_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_148_io_w_req_bits_data_0 <= 19'($urandom);
      vSRAMTemplate_148_io_w_req_bits_data_1 <= 19'($urandom);
      vSRAMTemplate_148_io_w_req_bits_data_2 <= 19'($urandom);
      vSRAMTemplate_148_io_w_req_bits_data_3 <= 19'($urandom);
      vSRAMTemplate_148_io_w_req_bits_waymask <= 4'($urandom);
      vSRAMTemplate_148_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_148_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_148_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_148_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_148_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_148_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_148_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_148_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_148_boreChildrenBd_bore_addr <= 10'($urandom);
      vSRAMTemplate_148_boreChildrenBd_bore_addr_rd <= 10'($urandom);
      vSRAMTemplate_148_boreChildrenBd_bore_wdata <= 76'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_148_boreChildrenBd_bore_wmask <= 4'($urandom);
      vSRAMTemplate_148_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_148_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_148_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_148_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_148_boreChildrenBd_bore_array <= 2'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_148_g_io_r_req_ready !== vSRAMTemplate_148_i_io_r_req_ready) begin errors++;
      $display("[%0t] SRAMTemplate_148.io_r_req_ready g=%h i=%h", $time, vSRAMTemplate_148_g_io_r_req_ready, vSRAMTemplate_148_i_io_r_req_ready); end
    if (vSRAMTemplate_148_g_io_r_resp_data_0 !== vSRAMTemplate_148_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_148.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_148_g_io_r_resp_data_0, vSRAMTemplate_148_i_io_r_resp_data_0); end
    if (vSRAMTemplate_148_g_io_r_resp_data_1 !== vSRAMTemplate_148_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_148.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_148_g_io_r_resp_data_1, vSRAMTemplate_148_i_io_r_resp_data_1); end
    if (vSRAMTemplate_148_g_io_r_resp_data_2 !== vSRAMTemplate_148_i_io_r_resp_data_2) begin errors++;
      $display("[%0t] SRAMTemplate_148.io_r_resp_data_2 g=%h i=%h", $time, vSRAMTemplate_148_g_io_r_resp_data_2, vSRAMTemplate_148_i_io_r_resp_data_2); end
    if (vSRAMTemplate_148_g_io_r_resp_data_3 !== vSRAMTemplate_148_i_io_r_resp_data_3) begin errors++;
      $display("[%0t] SRAMTemplate_148.io_r_resp_data_3 g=%h i=%h", $time, vSRAMTemplate_148_g_io_r_resp_data_3, vSRAMTemplate_148_i_io_r_resp_data_3); end
    if (vSRAMTemplate_148_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_148_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_148.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_148_g_boreChildrenBd_bore_rdata, vSRAMTemplate_148_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_150_io_r_req_valid;
  logic [8:0] vSRAMTemplate_150_io_r_req_bits_setIdx;
  logic vSRAMTemplate_150_io_w_req_valid;
  logic [8:0] vSRAMTemplate_150_io_w_req_bits_setIdx;
  logic [18:0] vSRAMTemplate_150_io_w_req_bits_data_0;
  logic [18:0] vSRAMTemplate_150_io_w_req_bits_data_1;
  logic [18:0] vSRAMTemplate_150_io_w_req_bits_data_2;
  logic [18:0] vSRAMTemplate_150_io_w_req_bits_data_3;
  logic [3:0] vSRAMTemplate_150_io_w_req_bits_waymask;
  logic vSRAMTemplate_150_io_broadcast_ram_hold;
  logic vSRAMTemplate_150_io_broadcast_ram_bypass;
  logic vSRAMTemplate_150_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_150_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_150_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_150_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_150_io_broadcast_ram_ctl;
  logic vSRAMTemplate_150_io_broadcast_cgen;
  logic [9:0] vSRAMTemplate_150_boreChildrenBd_bore_addr;
  logic [9:0] vSRAMTemplate_150_boreChildrenBd_bore_addr_rd;
  logic [75:0] vSRAMTemplate_150_boreChildrenBd_bore_wdata;
  logic [3:0] vSRAMTemplate_150_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_150_boreChildrenBd_bore_re;
  logic vSRAMTemplate_150_boreChildrenBd_bore_we;
  logic vSRAMTemplate_150_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_150_boreChildrenBd_bore_selectedOH;
  logic [2:0] vSRAMTemplate_150_boreChildrenBd_bore_array;
  wire [18:0] vSRAMTemplate_150_g_io_r_resp_data_0;
  wire [18:0] vSRAMTemplate_150_i_io_r_resp_data_0;
  wire [18:0] vSRAMTemplate_150_g_io_r_resp_data_1;
  wire [18:0] vSRAMTemplate_150_i_io_r_resp_data_1;
  wire [18:0] vSRAMTemplate_150_g_io_r_resp_data_2;
  wire [18:0] vSRAMTemplate_150_i_io_r_resp_data_2;
  wire [18:0] vSRAMTemplate_150_g_io_r_resp_data_3;
  wire [18:0] vSRAMTemplate_150_i_io_r_resp_data_3;
  wire [75:0] vSRAMTemplate_150_g_boreChildrenBd_bore_rdata;
  wire [75:0] vSRAMTemplate_150_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_150 u_g_SRAMTemplate_150 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_150_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_150_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_150_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_150_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_150_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_150_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_150_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_150_io_w_req_bits_data_3), .io_w_req_bits_waymask(vSRAMTemplate_150_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_150_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_150_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_150_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_150_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_150_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_150_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_150_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_150_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_150_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_150_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_150_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_150_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_150_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_150_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_150_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_150_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_150_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_150_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_150_g_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_150_g_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_150_g_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_150_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_150_xs u_i_SRAMTemplate_150 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_150_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_150_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_150_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_150_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_150_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_150_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_150_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_150_io_w_req_bits_data_3), .io_w_req_bits_waymask(vSRAMTemplate_150_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_150_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_150_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_150_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_150_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_150_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_150_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_150_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_150_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_150_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_150_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_150_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_150_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_150_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_150_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_150_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_150_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_150_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_150_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_150_i_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_150_i_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_150_i_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_150_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_150_io_r_req_valid <= 1'b0;
      vSRAMTemplate_150_io_w_req_valid <= 1'b0;
      vSRAMTemplate_150_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_150_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_150_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_150_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_150_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_150_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_150_io_r_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_150_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_150_io_w_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_150_io_w_req_bits_data_0 <= 19'($urandom);
      vSRAMTemplate_150_io_w_req_bits_data_1 <= 19'($urandom);
      vSRAMTemplate_150_io_w_req_bits_data_2 <= 19'($urandom);
      vSRAMTemplate_150_io_w_req_bits_data_3 <= 19'($urandom);
      vSRAMTemplate_150_io_w_req_bits_waymask <= 4'($urandom);
      vSRAMTemplate_150_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_150_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_150_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_150_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_150_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_150_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_150_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_150_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_150_boreChildrenBd_bore_addr <= 10'($urandom);
      vSRAMTemplate_150_boreChildrenBd_bore_addr_rd <= 10'($urandom);
      vSRAMTemplate_150_boreChildrenBd_bore_wdata <= 76'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_150_boreChildrenBd_bore_wmask <= 4'($urandom);
      vSRAMTemplate_150_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_150_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_150_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_150_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_150_boreChildrenBd_bore_array <= 3'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_150_g_io_r_resp_data_0 !== vSRAMTemplate_150_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_150.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_150_g_io_r_resp_data_0, vSRAMTemplate_150_i_io_r_resp_data_0); end
    if (vSRAMTemplate_150_g_io_r_resp_data_1 !== vSRAMTemplate_150_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_150.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_150_g_io_r_resp_data_1, vSRAMTemplate_150_i_io_r_resp_data_1); end
    if (vSRAMTemplate_150_g_io_r_resp_data_2 !== vSRAMTemplate_150_i_io_r_resp_data_2) begin errors++;
      $display("[%0t] SRAMTemplate_150.io_r_resp_data_2 g=%h i=%h", $time, vSRAMTemplate_150_g_io_r_resp_data_2, vSRAMTemplate_150_i_io_r_resp_data_2); end
    if (vSRAMTemplate_150_g_io_r_resp_data_3 !== vSRAMTemplate_150_i_io_r_resp_data_3) begin errors++;
      $display("[%0t] SRAMTemplate_150.io_r_resp_data_3 g=%h i=%h", $time, vSRAMTemplate_150_g_io_r_resp_data_3, vSRAMTemplate_150_i_io_r_resp_data_3); end
    if (vSRAMTemplate_150_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_150_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_150.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_150_g_boreChildrenBd_bore_rdata, vSRAMTemplate_150_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_153_io_r_req_valid;
  logic [8:0] vSRAMTemplate_153_io_r_req_bits_setIdx;
  logic vSRAMTemplate_153_io_w_req_valid;
  logic [8:0] vSRAMTemplate_153_io_w_req_bits_setIdx;
  logic [15:0] vSRAMTemplate_153_io_w_req_bits_data_0;
  logic vSRAMTemplate_153_io_broadcast_ram_hold;
  logic vSRAMTemplate_153_io_broadcast_ram_bypass;
  logic vSRAMTemplate_153_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_153_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_153_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_153_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_153_io_broadcast_ram_ctl;
  logic vSRAMTemplate_153_io_broadcast_cgen;
  logic [9:0] vSRAMTemplate_153_boreChildrenBd_bore_addr;
  logic [9:0] vSRAMTemplate_153_boreChildrenBd_bore_addr_rd;
  logic [15:0] vSRAMTemplate_153_boreChildrenBd_bore_wdata;
  logic vSRAMTemplate_153_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_153_boreChildrenBd_bore_re;
  logic vSRAMTemplate_153_boreChildrenBd_bore_we;
  logic vSRAMTemplate_153_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_153_boreChildrenBd_bore_selectedOH;
  logic [2:0] vSRAMTemplate_153_boreChildrenBd_bore_array;
  wire [15:0] vSRAMTemplate_153_g_io_r_resp_data_0;
  wire [15:0] vSRAMTemplate_153_i_io_r_resp_data_0;
  wire [15:0] vSRAMTemplate_153_g_boreChildrenBd_bore_rdata;
  wire [15:0] vSRAMTemplate_153_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_153 u_g_SRAMTemplate_153 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_153_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_153_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_153_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_153_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_153_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_153_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_153_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_153_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_153_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_153_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_153_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_153_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_153_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_153_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_153_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_153_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_153_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_153_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_153_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_153_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_153_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_153_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_153_g_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_153_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_153_xs u_i_SRAMTemplate_153 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_153_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_153_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_153_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_153_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_153_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_153_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_153_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_153_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_153_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_153_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_153_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_153_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_153_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_153_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_153_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_153_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_153_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_153_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_153_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_153_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_153_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_153_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_153_i_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_153_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_153_io_r_req_valid <= 1'b0;
      vSRAMTemplate_153_io_w_req_valid <= 1'b0;
      vSRAMTemplate_153_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_153_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_153_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_153_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_153_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_153_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_153_io_r_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_153_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_153_io_w_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_153_io_w_req_bits_data_0 <= 16'($urandom);
      vSRAMTemplate_153_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_153_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_153_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_153_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_153_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_153_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_153_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_153_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_153_boreChildrenBd_bore_addr <= 10'($urandom);
      vSRAMTemplate_153_boreChildrenBd_bore_addr_rd <= 10'($urandom);
      vSRAMTemplate_153_boreChildrenBd_bore_wdata <= 16'($urandom);
      vSRAMTemplate_153_boreChildrenBd_bore_wmask <= 1'($urandom);
      vSRAMTemplate_153_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_153_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_153_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_153_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_153_boreChildrenBd_bore_array <= 3'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_153_g_io_r_resp_data_0 !== vSRAMTemplate_153_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_153.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_153_g_io_r_resp_data_0, vSRAMTemplate_153_i_io_r_resp_data_0); end
    if (vSRAMTemplate_153_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_153_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_153.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_153_g_boreChildrenBd_bore_rdata, vSRAMTemplate_153_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_154_io_r_req_valid;
  logic [8:0] vSRAMTemplate_154_io_r_req_bits_setIdx;
  logic vSRAMTemplate_154_io_w_req_valid;
  logic [8:0] vSRAMTemplate_154_io_w_req_bits_setIdx;
  logic vSRAMTemplate_154_io_w_req_bits_data_0;
  logic vSRAMTemplate_154_io_w_req_bits_data_1;
  logic vSRAMTemplate_154_io_w_req_bits_data_2;
  logic vSRAMTemplate_154_io_w_req_bits_data_3;
  logic vSRAMTemplate_154_io_w_req_bits_data_4;
  logic vSRAMTemplate_154_io_w_req_bits_data_5;
  logic vSRAMTemplate_154_io_w_req_bits_data_6;
  logic vSRAMTemplate_154_io_w_req_bits_data_7;
  logic [7:0] vSRAMTemplate_154_io_w_req_bits_waymask;
  logic vSRAMTemplate_154_io_broadcast_ram_hold;
  logic vSRAMTemplate_154_io_broadcast_ram_bypass;
  logic vSRAMTemplate_154_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_154_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_154_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_154_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_154_io_broadcast_ram_ctl;
  logic vSRAMTemplate_154_io_broadcast_cgen;
  logic [9:0] vSRAMTemplate_154_boreChildrenBd_bore_addr;
  logic [9:0] vSRAMTemplate_154_boreChildrenBd_bore_addr_rd;
  logic [7:0] vSRAMTemplate_154_boreChildrenBd_bore_wdata;
  logic [7:0] vSRAMTemplate_154_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_154_boreChildrenBd_bore_re;
  logic vSRAMTemplate_154_boreChildrenBd_bore_we;
  logic vSRAMTemplate_154_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_154_boreChildrenBd_bore_selectedOH;
  logic [3:0] vSRAMTemplate_154_boreChildrenBd_bore_array;
  wire vSRAMTemplate_154_g_io_r_resp_data_0;
  wire vSRAMTemplate_154_i_io_r_resp_data_0;
  wire vSRAMTemplate_154_g_io_r_resp_data_1;
  wire vSRAMTemplate_154_i_io_r_resp_data_1;
  wire vSRAMTemplate_154_g_io_r_resp_data_2;
  wire vSRAMTemplate_154_i_io_r_resp_data_2;
  wire vSRAMTemplate_154_g_io_r_resp_data_3;
  wire vSRAMTemplate_154_i_io_r_resp_data_3;
  wire vSRAMTemplate_154_g_io_r_resp_data_4;
  wire vSRAMTemplate_154_i_io_r_resp_data_4;
  wire vSRAMTemplate_154_g_io_r_resp_data_5;
  wire vSRAMTemplate_154_i_io_r_resp_data_5;
  wire vSRAMTemplate_154_g_io_r_resp_data_6;
  wire vSRAMTemplate_154_i_io_r_resp_data_6;
  wire vSRAMTemplate_154_g_io_r_resp_data_7;
  wire vSRAMTemplate_154_i_io_r_resp_data_7;
  wire [7:0] vSRAMTemplate_154_g_boreChildrenBd_bore_rdata;
  wire [7:0] vSRAMTemplate_154_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_154 u_g_SRAMTemplate_154 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_154_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_154_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_154_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_154_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_154_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_154_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_154_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_154_io_w_req_bits_data_3), .io_w_req_bits_data_4(vSRAMTemplate_154_io_w_req_bits_data_4), .io_w_req_bits_data_5(vSRAMTemplate_154_io_w_req_bits_data_5), .io_w_req_bits_data_6(vSRAMTemplate_154_io_w_req_bits_data_6), .io_w_req_bits_data_7(vSRAMTemplate_154_io_w_req_bits_data_7), .io_w_req_bits_waymask(vSRAMTemplate_154_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_154_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_154_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_154_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_154_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_154_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_154_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_154_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_154_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_154_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_154_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_154_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_154_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_154_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_154_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_154_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_154_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_154_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_154_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_154_g_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_154_g_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_154_g_io_r_resp_data_3), .io_r_resp_data_4(vSRAMTemplate_154_g_io_r_resp_data_4), .io_r_resp_data_5(vSRAMTemplate_154_g_io_r_resp_data_5), .io_r_resp_data_6(vSRAMTemplate_154_g_io_r_resp_data_6), .io_r_resp_data_7(vSRAMTemplate_154_g_io_r_resp_data_7), .boreChildrenBd_bore_rdata(vSRAMTemplate_154_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_154_xs u_i_SRAMTemplate_154 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_154_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_154_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_154_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_154_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_154_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_154_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_154_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_154_io_w_req_bits_data_3), .io_w_req_bits_data_4(vSRAMTemplate_154_io_w_req_bits_data_4), .io_w_req_bits_data_5(vSRAMTemplate_154_io_w_req_bits_data_5), .io_w_req_bits_data_6(vSRAMTemplate_154_io_w_req_bits_data_6), .io_w_req_bits_data_7(vSRAMTemplate_154_io_w_req_bits_data_7), .io_w_req_bits_waymask(vSRAMTemplate_154_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_154_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_154_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_154_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_154_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_154_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_154_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_154_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_154_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_154_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_154_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_154_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_154_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_154_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_154_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_154_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_154_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_154_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_154_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_154_i_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_154_i_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_154_i_io_r_resp_data_3), .io_r_resp_data_4(vSRAMTemplate_154_i_io_r_resp_data_4), .io_r_resp_data_5(vSRAMTemplate_154_i_io_r_resp_data_5), .io_r_resp_data_6(vSRAMTemplate_154_i_io_r_resp_data_6), .io_r_resp_data_7(vSRAMTemplate_154_i_io_r_resp_data_7), .boreChildrenBd_bore_rdata(vSRAMTemplate_154_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_154_io_r_req_valid <= 1'b0;
      vSRAMTemplate_154_io_w_req_valid <= 1'b0;
      vSRAMTemplate_154_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_154_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_154_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_154_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_154_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_154_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_154_io_r_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_154_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_154_io_w_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_154_io_w_req_bits_data_0 <= 1'($urandom);
      vSRAMTemplate_154_io_w_req_bits_data_1 <= 1'($urandom);
      vSRAMTemplate_154_io_w_req_bits_data_2 <= 1'($urandom);
      vSRAMTemplate_154_io_w_req_bits_data_3 <= 1'($urandom);
      vSRAMTemplate_154_io_w_req_bits_data_4 <= 1'($urandom);
      vSRAMTemplate_154_io_w_req_bits_data_5 <= 1'($urandom);
      vSRAMTemplate_154_io_w_req_bits_data_6 <= 1'($urandom);
      vSRAMTemplate_154_io_w_req_bits_data_7 <= 1'($urandom);
      vSRAMTemplate_154_io_w_req_bits_waymask <= 8'($urandom);
      vSRAMTemplate_154_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_154_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_154_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_154_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_154_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_154_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_154_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_154_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_154_boreChildrenBd_bore_addr <= 10'($urandom);
      vSRAMTemplate_154_boreChildrenBd_bore_addr_rd <= 10'($urandom);
      vSRAMTemplate_154_boreChildrenBd_bore_wdata <= 8'($urandom);
      vSRAMTemplate_154_boreChildrenBd_bore_wmask <= 8'($urandom);
      vSRAMTemplate_154_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_154_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_154_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_154_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_154_boreChildrenBd_bore_array <= 4'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_154_g_io_r_resp_data_0 !== vSRAMTemplate_154_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_154.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_154_g_io_r_resp_data_0, vSRAMTemplate_154_i_io_r_resp_data_0); end
    if (vSRAMTemplate_154_g_io_r_resp_data_1 !== vSRAMTemplate_154_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_154.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_154_g_io_r_resp_data_1, vSRAMTemplate_154_i_io_r_resp_data_1); end
    if (vSRAMTemplate_154_g_io_r_resp_data_2 !== vSRAMTemplate_154_i_io_r_resp_data_2) begin errors++;
      $display("[%0t] SRAMTemplate_154.io_r_resp_data_2 g=%h i=%h", $time, vSRAMTemplate_154_g_io_r_resp_data_2, vSRAMTemplate_154_i_io_r_resp_data_2); end
    if (vSRAMTemplate_154_g_io_r_resp_data_3 !== vSRAMTemplate_154_i_io_r_resp_data_3) begin errors++;
      $display("[%0t] SRAMTemplate_154.io_r_resp_data_3 g=%h i=%h", $time, vSRAMTemplate_154_g_io_r_resp_data_3, vSRAMTemplate_154_i_io_r_resp_data_3); end
    if (vSRAMTemplate_154_g_io_r_resp_data_4 !== vSRAMTemplate_154_i_io_r_resp_data_4) begin errors++;
      $display("[%0t] SRAMTemplate_154.io_r_resp_data_4 g=%h i=%h", $time, vSRAMTemplate_154_g_io_r_resp_data_4, vSRAMTemplate_154_i_io_r_resp_data_4); end
    if (vSRAMTemplate_154_g_io_r_resp_data_5 !== vSRAMTemplate_154_i_io_r_resp_data_5) begin errors++;
      $display("[%0t] SRAMTemplate_154.io_r_resp_data_5 g=%h i=%h", $time, vSRAMTemplate_154_g_io_r_resp_data_5, vSRAMTemplate_154_i_io_r_resp_data_5); end
    if (vSRAMTemplate_154_g_io_r_resp_data_6 !== vSRAMTemplate_154_i_io_r_resp_data_6) begin errors++;
      $display("[%0t] SRAMTemplate_154.io_r_resp_data_6 g=%h i=%h", $time, vSRAMTemplate_154_g_io_r_resp_data_6, vSRAMTemplate_154_i_io_r_resp_data_6); end
    if (vSRAMTemplate_154_g_io_r_resp_data_7 !== vSRAMTemplate_154_i_io_r_resp_data_7) begin errors++;
      $display("[%0t] SRAMTemplate_154.io_r_resp_data_7 g=%h i=%h", $time, vSRAMTemplate_154_g_io_r_resp_data_7, vSRAMTemplate_154_i_io_r_resp_data_7); end
    if (vSRAMTemplate_154_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_154_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_154.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_154_g_boreChildrenBd_bore_rdata, vSRAMTemplate_154_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_159_io_r_req_valid;
  logic [8:0] vSRAMTemplate_159_io_r_req_bits_setIdx;
  logic vSRAMTemplate_159_io_w_req_valid;
  logic [8:0] vSRAMTemplate_159_io_w_req_bits_setIdx;
  logic [18:0] vSRAMTemplate_159_io_w_req_bits_data_0;
  logic [18:0] vSRAMTemplate_159_io_w_req_bits_data_1;
  logic [18:0] vSRAMTemplate_159_io_w_req_bits_data_2;
  logic [18:0] vSRAMTemplate_159_io_w_req_bits_data_3;
  logic [3:0] vSRAMTemplate_159_io_w_req_bits_waymask;
  logic vSRAMTemplate_159_io_broadcast_ram_hold;
  logic vSRAMTemplate_159_io_broadcast_ram_bypass;
  logic vSRAMTemplate_159_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_159_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_159_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_159_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_159_io_broadcast_ram_ctl;
  logic vSRAMTemplate_159_io_broadcast_cgen;
  logic [9:0] vSRAMTemplate_159_boreChildrenBd_bore_addr;
  logic [9:0] vSRAMTemplate_159_boreChildrenBd_bore_addr_rd;
  logic [75:0] vSRAMTemplate_159_boreChildrenBd_bore_wdata;
  logic [3:0] vSRAMTemplate_159_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_159_boreChildrenBd_bore_re;
  logic vSRAMTemplate_159_boreChildrenBd_bore_we;
  logic vSRAMTemplate_159_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_159_boreChildrenBd_bore_selectedOH;
  logic [3:0] vSRAMTemplate_159_boreChildrenBd_bore_array;
  wire vSRAMTemplate_159_g_io_r_req_ready;
  wire vSRAMTemplate_159_i_io_r_req_ready;
  wire [18:0] vSRAMTemplate_159_g_io_r_resp_data_0;
  wire [18:0] vSRAMTemplate_159_i_io_r_resp_data_0;
  wire [18:0] vSRAMTemplate_159_g_io_r_resp_data_1;
  wire [18:0] vSRAMTemplate_159_i_io_r_resp_data_1;
  wire [18:0] vSRAMTemplate_159_g_io_r_resp_data_2;
  wire [18:0] vSRAMTemplate_159_i_io_r_resp_data_2;
  wire [18:0] vSRAMTemplate_159_g_io_r_resp_data_3;
  wire [18:0] vSRAMTemplate_159_i_io_r_resp_data_3;
  wire [75:0] vSRAMTemplate_159_g_boreChildrenBd_bore_rdata;
  wire [75:0] vSRAMTemplate_159_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_159 u_g_SRAMTemplate_159 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_159_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_159_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_159_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_159_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_159_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_159_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_159_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_159_io_w_req_bits_data_3), .io_w_req_bits_waymask(vSRAMTemplate_159_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_159_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_159_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_159_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_159_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_159_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_159_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_159_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_159_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_159_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_159_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_159_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_159_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_159_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_159_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_159_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_159_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_159_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_159_g_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_159_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_159_g_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_159_g_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_159_g_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_159_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_159_xs u_i_SRAMTemplate_159 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_159_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_159_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_159_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_159_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_159_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_159_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_159_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_159_io_w_req_bits_data_3), .io_w_req_bits_waymask(vSRAMTemplate_159_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_159_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_159_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_159_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_159_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_159_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_159_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_159_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_159_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_159_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_159_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_159_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_159_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_159_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_159_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_159_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_159_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_159_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_159_i_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_159_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_159_i_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_159_i_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_159_i_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_159_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_159_io_r_req_valid <= 1'b0;
      vSRAMTemplate_159_io_w_req_valid <= 1'b0;
      vSRAMTemplate_159_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_159_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_159_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_159_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_159_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_159_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_159_io_r_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_159_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_159_io_w_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_159_io_w_req_bits_data_0 <= 19'($urandom);
      vSRAMTemplate_159_io_w_req_bits_data_1 <= 19'($urandom);
      vSRAMTemplate_159_io_w_req_bits_data_2 <= 19'($urandom);
      vSRAMTemplate_159_io_w_req_bits_data_3 <= 19'($urandom);
      vSRAMTemplate_159_io_w_req_bits_waymask <= 4'($urandom);
      vSRAMTemplate_159_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_159_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_159_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_159_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_159_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_159_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_159_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_159_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_159_boreChildrenBd_bore_addr <= 10'($urandom);
      vSRAMTemplate_159_boreChildrenBd_bore_addr_rd <= 10'($urandom);
      vSRAMTemplate_159_boreChildrenBd_bore_wdata <= 76'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_159_boreChildrenBd_bore_wmask <= 4'($urandom);
      vSRAMTemplate_159_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_159_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_159_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_159_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_159_boreChildrenBd_bore_array <= 4'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_159_g_io_r_req_ready !== vSRAMTemplate_159_i_io_r_req_ready) begin errors++;
      $display("[%0t] SRAMTemplate_159.io_r_req_ready g=%h i=%h", $time, vSRAMTemplate_159_g_io_r_req_ready, vSRAMTemplate_159_i_io_r_req_ready); end
    if (vSRAMTemplate_159_g_io_r_resp_data_0 !== vSRAMTemplate_159_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_159.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_159_g_io_r_resp_data_0, vSRAMTemplate_159_i_io_r_resp_data_0); end
    if (vSRAMTemplate_159_g_io_r_resp_data_1 !== vSRAMTemplate_159_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_159.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_159_g_io_r_resp_data_1, vSRAMTemplate_159_i_io_r_resp_data_1); end
    if (vSRAMTemplate_159_g_io_r_resp_data_2 !== vSRAMTemplate_159_i_io_r_resp_data_2) begin errors++;
      $display("[%0t] SRAMTemplate_159.io_r_resp_data_2 g=%h i=%h", $time, vSRAMTemplate_159_g_io_r_resp_data_2, vSRAMTemplate_159_i_io_r_resp_data_2); end
    if (vSRAMTemplate_159_g_io_r_resp_data_3 !== vSRAMTemplate_159_i_io_r_resp_data_3) begin errors++;
      $display("[%0t] SRAMTemplate_159.io_r_resp_data_3 g=%h i=%h", $time, vSRAMTemplate_159_g_io_r_resp_data_3, vSRAMTemplate_159_i_io_r_resp_data_3); end
    if (vSRAMTemplate_159_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_159_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_159.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_159_g_boreChildrenBd_bore_rdata, vSRAMTemplate_159_i_boreChildrenBd_bore_rdata); end
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

  logic vSRAMTemplate_162_io_r_req_valid;
  logic [8:0] vSRAMTemplate_162_io_r_req_bits_setIdx;
  logic vSRAMTemplate_162_io_w_req_valid;
  logic [8:0] vSRAMTemplate_162_io_w_req_bits_setIdx;
  logic [18:0] vSRAMTemplate_162_io_w_req_bits_data_0;
  logic [18:0] vSRAMTemplate_162_io_w_req_bits_data_1;
  logic [18:0] vSRAMTemplate_162_io_w_req_bits_data_2;
  logic [18:0] vSRAMTemplate_162_io_w_req_bits_data_3;
  logic [3:0] vSRAMTemplate_162_io_w_req_bits_waymask;
  logic vSRAMTemplate_162_io_broadcast_ram_hold;
  logic vSRAMTemplate_162_io_broadcast_ram_bypass;
  logic vSRAMTemplate_162_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_162_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_162_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_162_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_162_io_broadcast_ram_ctl;
  logic vSRAMTemplate_162_io_broadcast_cgen;
  logic [9:0] vSRAMTemplate_162_boreChildrenBd_bore_addr;
  logic [9:0] vSRAMTemplate_162_boreChildrenBd_bore_addr_rd;
  logic [75:0] vSRAMTemplate_162_boreChildrenBd_bore_wdata;
  logic [3:0] vSRAMTemplate_162_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_162_boreChildrenBd_bore_re;
  logic vSRAMTemplate_162_boreChildrenBd_bore_we;
  logic vSRAMTemplate_162_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_162_boreChildrenBd_bore_selectedOH;
  logic [4:0] vSRAMTemplate_162_boreChildrenBd_bore_array;
  wire vSRAMTemplate_162_g_io_r_req_ready;
  wire vSRAMTemplate_162_i_io_r_req_ready;
  wire [18:0] vSRAMTemplate_162_g_io_r_resp_data_0;
  wire [18:0] vSRAMTemplate_162_i_io_r_resp_data_0;
  wire [18:0] vSRAMTemplate_162_g_io_r_resp_data_1;
  wire [18:0] vSRAMTemplate_162_i_io_r_resp_data_1;
  wire [18:0] vSRAMTemplate_162_g_io_r_resp_data_2;
  wire [18:0] vSRAMTemplate_162_i_io_r_resp_data_2;
  wire [18:0] vSRAMTemplate_162_g_io_r_resp_data_3;
  wire [18:0] vSRAMTemplate_162_i_io_r_resp_data_3;
  wire [75:0] vSRAMTemplate_162_g_boreChildrenBd_bore_rdata;
  wire [75:0] vSRAMTemplate_162_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_162 u_g_SRAMTemplate_162 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_162_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_162_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_162_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_162_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_162_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_162_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_162_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_162_io_w_req_bits_data_3), .io_w_req_bits_waymask(vSRAMTemplate_162_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_162_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_162_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_162_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_162_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_162_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_162_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_162_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_162_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_162_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_162_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_162_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_162_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_162_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_162_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_162_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_162_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_162_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_162_g_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_162_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_162_g_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_162_g_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_162_g_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_162_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_162_xs u_i_SRAMTemplate_162 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_162_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_162_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_162_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_162_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_162_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_162_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_162_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_162_io_w_req_bits_data_3), .io_w_req_bits_waymask(vSRAMTemplate_162_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_162_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_162_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_162_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_162_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_162_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_162_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_162_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_162_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_162_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_162_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_162_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_162_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_162_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_162_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_162_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_162_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_162_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_162_i_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_162_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_162_i_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_162_i_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_162_i_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_162_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_162_io_r_req_valid <= 1'b0;
      vSRAMTemplate_162_io_w_req_valid <= 1'b0;
      vSRAMTemplate_162_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_162_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_162_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_162_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_162_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_162_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_162_io_r_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_162_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_162_io_w_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_162_io_w_req_bits_data_0 <= 19'($urandom);
      vSRAMTemplate_162_io_w_req_bits_data_1 <= 19'($urandom);
      vSRAMTemplate_162_io_w_req_bits_data_2 <= 19'($urandom);
      vSRAMTemplate_162_io_w_req_bits_data_3 <= 19'($urandom);
      vSRAMTemplate_162_io_w_req_bits_waymask <= 4'($urandom);
      vSRAMTemplate_162_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_162_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_162_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_162_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_162_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_162_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_162_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_162_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_162_boreChildrenBd_bore_addr <= 10'($urandom);
      vSRAMTemplate_162_boreChildrenBd_bore_addr_rd <= 10'($urandom);
      vSRAMTemplate_162_boreChildrenBd_bore_wdata <= 76'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_162_boreChildrenBd_bore_wmask <= 4'($urandom);
      vSRAMTemplate_162_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_162_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_162_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_162_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_162_boreChildrenBd_bore_array <= 5'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_162_g_io_r_req_ready !== vSRAMTemplate_162_i_io_r_req_ready) begin errors++;
      $display("[%0t] SRAMTemplate_162.io_r_req_ready g=%h i=%h", $time, vSRAMTemplate_162_g_io_r_req_ready, vSRAMTemplate_162_i_io_r_req_ready); end
    if (vSRAMTemplate_162_g_io_r_resp_data_0 !== vSRAMTemplate_162_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_162.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_162_g_io_r_resp_data_0, vSRAMTemplate_162_i_io_r_resp_data_0); end
    if (vSRAMTemplate_162_g_io_r_resp_data_1 !== vSRAMTemplate_162_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_162.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_162_g_io_r_resp_data_1, vSRAMTemplate_162_i_io_r_resp_data_1); end
    if (vSRAMTemplate_162_g_io_r_resp_data_2 !== vSRAMTemplate_162_i_io_r_resp_data_2) begin errors++;
      $display("[%0t] SRAMTemplate_162.io_r_resp_data_2 g=%h i=%h", $time, vSRAMTemplate_162_g_io_r_resp_data_2, vSRAMTemplate_162_i_io_r_resp_data_2); end
    if (vSRAMTemplate_162_g_io_r_resp_data_3 !== vSRAMTemplate_162_i_io_r_resp_data_3) begin errors++;
      $display("[%0t] SRAMTemplate_162.io_r_resp_data_3 g=%h i=%h", $time, vSRAMTemplate_162_g_io_r_resp_data_3, vSRAMTemplate_162_i_io_r_resp_data_3); end
    if (vSRAMTemplate_162_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_162_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_162.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_162_g_boreChildrenBd_bore_rdata, vSRAMTemplate_162_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_164_io_r_req_valid;
  logic [8:0] vSRAMTemplate_164_io_r_req_bits_setIdx;
  logic vSRAMTemplate_164_io_w_req_valid;
  logic [8:0] vSRAMTemplate_164_io_w_req_bits_setIdx;
  logic [15:0] vSRAMTemplate_164_io_w_req_bits_data_0;
  logic vSRAMTemplate_164_io_broadcast_ram_hold;
  logic vSRAMTemplate_164_io_broadcast_ram_bypass;
  logic vSRAMTemplate_164_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_164_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_164_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_164_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_164_io_broadcast_ram_ctl;
  logic vSRAMTemplate_164_io_broadcast_cgen;
  logic [9:0] vSRAMTemplate_164_boreChildrenBd_bore_addr;
  logic [9:0] vSRAMTemplate_164_boreChildrenBd_bore_addr_rd;
  logic [15:0] vSRAMTemplate_164_boreChildrenBd_bore_wdata;
  logic vSRAMTemplate_164_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_164_boreChildrenBd_bore_re;
  logic vSRAMTemplate_164_boreChildrenBd_bore_we;
  logic vSRAMTemplate_164_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_164_boreChildrenBd_bore_selectedOH;
  logic [4:0] vSRAMTemplate_164_boreChildrenBd_bore_array;
  wire [15:0] vSRAMTemplate_164_g_io_r_resp_data_0;
  wire [15:0] vSRAMTemplate_164_i_io_r_resp_data_0;
  wire [15:0] vSRAMTemplate_164_g_boreChildrenBd_bore_rdata;
  wire [15:0] vSRAMTemplate_164_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_164 u_g_SRAMTemplate_164 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_164_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_164_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_164_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_164_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_164_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_164_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_164_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_164_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_164_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_164_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_164_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_164_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_164_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_164_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_164_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_164_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_164_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_164_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_164_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_164_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_164_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_164_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_164_g_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_164_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_164_xs u_i_SRAMTemplate_164 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_164_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_164_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_164_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_164_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_164_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_164_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_164_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_164_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_164_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_164_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_164_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_164_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_164_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_164_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_164_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_164_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_164_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_164_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_164_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_164_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_164_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_164_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_164_i_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_164_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_164_io_r_req_valid <= 1'b0;
      vSRAMTemplate_164_io_w_req_valid <= 1'b0;
      vSRAMTemplate_164_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_164_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_164_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_164_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_164_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_164_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_164_io_r_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_164_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_164_io_w_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_164_io_w_req_bits_data_0 <= 16'($urandom);
      vSRAMTemplate_164_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_164_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_164_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_164_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_164_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_164_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_164_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_164_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_164_boreChildrenBd_bore_addr <= 10'($urandom);
      vSRAMTemplate_164_boreChildrenBd_bore_addr_rd <= 10'($urandom);
      vSRAMTemplate_164_boreChildrenBd_bore_wdata <= 16'($urandom);
      vSRAMTemplate_164_boreChildrenBd_bore_wmask <= 1'($urandom);
      vSRAMTemplate_164_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_164_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_164_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_164_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_164_boreChildrenBd_bore_array <= 5'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_164_g_io_r_resp_data_0 !== vSRAMTemplate_164_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_164.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_164_g_io_r_resp_data_0, vSRAMTemplate_164_i_io_r_resp_data_0); end
    if (vSRAMTemplate_164_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_164_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_164.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_164_g_boreChildrenBd_bore_rdata, vSRAMTemplate_164_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_165_io_r_req_valid;
  logic [8:0] vSRAMTemplate_165_io_r_req_bits_setIdx;
  logic vSRAMTemplate_165_io_w_req_valid;
  logic [8:0] vSRAMTemplate_165_io_w_req_bits_setIdx;
  logic vSRAMTemplate_165_io_w_req_bits_data_0;
  logic vSRAMTemplate_165_io_w_req_bits_data_1;
  logic vSRAMTemplate_165_io_w_req_bits_data_2;
  logic vSRAMTemplate_165_io_w_req_bits_data_3;
  logic vSRAMTemplate_165_io_w_req_bits_data_4;
  logic vSRAMTemplate_165_io_w_req_bits_data_5;
  logic vSRAMTemplate_165_io_w_req_bits_data_6;
  logic vSRAMTemplate_165_io_w_req_bits_data_7;
  logic [7:0] vSRAMTemplate_165_io_w_req_bits_waymask;
  logic vSRAMTemplate_165_io_broadcast_ram_hold;
  logic vSRAMTemplate_165_io_broadcast_ram_bypass;
  logic vSRAMTemplate_165_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_165_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_165_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_165_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_165_io_broadcast_ram_ctl;
  logic vSRAMTemplate_165_io_broadcast_cgen;
  logic [9:0] vSRAMTemplate_165_boreChildrenBd_bore_addr;
  logic [9:0] vSRAMTemplate_165_boreChildrenBd_bore_addr_rd;
  logic [7:0] vSRAMTemplate_165_boreChildrenBd_bore_wdata;
  logic [7:0] vSRAMTemplate_165_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_165_boreChildrenBd_bore_re;
  logic vSRAMTemplate_165_boreChildrenBd_bore_we;
  logic vSRAMTemplate_165_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_165_boreChildrenBd_bore_selectedOH;
  logic [4:0] vSRAMTemplate_165_boreChildrenBd_bore_array;
  wire vSRAMTemplate_165_g_io_r_resp_data_0;
  wire vSRAMTemplate_165_i_io_r_resp_data_0;
  wire vSRAMTemplate_165_g_io_r_resp_data_1;
  wire vSRAMTemplate_165_i_io_r_resp_data_1;
  wire vSRAMTemplate_165_g_io_r_resp_data_2;
  wire vSRAMTemplate_165_i_io_r_resp_data_2;
  wire vSRAMTemplate_165_g_io_r_resp_data_3;
  wire vSRAMTemplate_165_i_io_r_resp_data_3;
  wire vSRAMTemplate_165_g_io_r_resp_data_4;
  wire vSRAMTemplate_165_i_io_r_resp_data_4;
  wire vSRAMTemplate_165_g_io_r_resp_data_5;
  wire vSRAMTemplate_165_i_io_r_resp_data_5;
  wire vSRAMTemplate_165_g_io_r_resp_data_6;
  wire vSRAMTemplate_165_i_io_r_resp_data_6;
  wire vSRAMTemplate_165_g_io_r_resp_data_7;
  wire vSRAMTemplate_165_i_io_r_resp_data_7;
  wire [7:0] vSRAMTemplate_165_g_boreChildrenBd_bore_rdata;
  wire [7:0] vSRAMTemplate_165_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_165 u_g_SRAMTemplate_165 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_165_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_165_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_165_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_165_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_165_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_165_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_165_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_165_io_w_req_bits_data_3), .io_w_req_bits_data_4(vSRAMTemplate_165_io_w_req_bits_data_4), .io_w_req_bits_data_5(vSRAMTemplate_165_io_w_req_bits_data_5), .io_w_req_bits_data_6(vSRAMTemplate_165_io_w_req_bits_data_6), .io_w_req_bits_data_7(vSRAMTemplate_165_io_w_req_bits_data_7), .io_w_req_bits_waymask(vSRAMTemplate_165_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_165_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_165_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_165_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_165_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_165_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_165_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_165_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_165_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_165_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_165_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_165_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_165_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_165_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_165_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_165_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_165_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_165_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_165_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_165_g_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_165_g_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_165_g_io_r_resp_data_3), .io_r_resp_data_4(vSRAMTemplate_165_g_io_r_resp_data_4), .io_r_resp_data_5(vSRAMTemplate_165_g_io_r_resp_data_5), .io_r_resp_data_6(vSRAMTemplate_165_g_io_r_resp_data_6), .io_r_resp_data_7(vSRAMTemplate_165_g_io_r_resp_data_7), .boreChildrenBd_bore_rdata(vSRAMTemplate_165_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_165_xs u_i_SRAMTemplate_165 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_165_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_165_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_165_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_165_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_165_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_165_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_165_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_165_io_w_req_bits_data_3), .io_w_req_bits_data_4(vSRAMTemplate_165_io_w_req_bits_data_4), .io_w_req_bits_data_5(vSRAMTemplate_165_io_w_req_bits_data_5), .io_w_req_bits_data_6(vSRAMTemplate_165_io_w_req_bits_data_6), .io_w_req_bits_data_7(vSRAMTemplate_165_io_w_req_bits_data_7), .io_w_req_bits_waymask(vSRAMTemplate_165_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_165_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_165_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_165_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_165_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_165_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_165_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_165_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_165_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_165_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_165_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_165_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_165_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_165_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_165_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_165_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_165_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_165_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_165_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_165_i_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_165_i_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_165_i_io_r_resp_data_3), .io_r_resp_data_4(vSRAMTemplate_165_i_io_r_resp_data_4), .io_r_resp_data_5(vSRAMTemplate_165_i_io_r_resp_data_5), .io_r_resp_data_6(vSRAMTemplate_165_i_io_r_resp_data_6), .io_r_resp_data_7(vSRAMTemplate_165_i_io_r_resp_data_7), .boreChildrenBd_bore_rdata(vSRAMTemplate_165_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_165_io_r_req_valid <= 1'b0;
      vSRAMTemplate_165_io_w_req_valid <= 1'b0;
      vSRAMTemplate_165_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_165_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_165_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_165_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_165_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_165_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_165_io_r_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_165_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_165_io_w_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_165_io_w_req_bits_data_0 <= 1'($urandom);
      vSRAMTemplate_165_io_w_req_bits_data_1 <= 1'($urandom);
      vSRAMTemplate_165_io_w_req_bits_data_2 <= 1'($urandom);
      vSRAMTemplate_165_io_w_req_bits_data_3 <= 1'($urandom);
      vSRAMTemplate_165_io_w_req_bits_data_4 <= 1'($urandom);
      vSRAMTemplate_165_io_w_req_bits_data_5 <= 1'($urandom);
      vSRAMTemplate_165_io_w_req_bits_data_6 <= 1'($urandom);
      vSRAMTemplate_165_io_w_req_bits_data_7 <= 1'($urandom);
      vSRAMTemplate_165_io_w_req_bits_waymask <= 8'($urandom);
      vSRAMTemplate_165_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_165_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_165_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_165_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_165_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_165_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_165_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_165_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_165_boreChildrenBd_bore_addr <= 10'($urandom);
      vSRAMTemplate_165_boreChildrenBd_bore_addr_rd <= 10'($urandom);
      vSRAMTemplate_165_boreChildrenBd_bore_wdata <= 8'($urandom);
      vSRAMTemplate_165_boreChildrenBd_bore_wmask <= 8'($urandom);
      vSRAMTemplate_165_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_165_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_165_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_165_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_165_boreChildrenBd_bore_array <= 5'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_165_g_io_r_resp_data_0 !== vSRAMTemplate_165_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_165.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_165_g_io_r_resp_data_0, vSRAMTemplate_165_i_io_r_resp_data_0); end
    if (vSRAMTemplate_165_g_io_r_resp_data_1 !== vSRAMTemplate_165_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_165.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_165_g_io_r_resp_data_1, vSRAMTemplate_165_i_io_r_resp_data_1); end
    if (vSRAMTemplate_165_g_io_r_resp_data_2 !== vSRAMTemplate_165_i_io_r_resp_data_2) begin errors++;
      $display("[%0t] SRAMTemplate_165.io_r_resp_data_2 g=%h i=%h", $time, vSRAMTemplate_165_g_io_r_resp_data_2, vSRAMTemplate_165_i_io_r_resp_data_2); end
    if (vSRAMTemplate_165_g_io_r_resp_data_3 !== vSRAMTemplate_165_i_io_r_resp_data_3) begin errors++;
      $display("[%0t] SRAMTemplate_165.io_r_resp_data_3 g=%h i=%h", $time, vSRAMTemplate_165_g_io_r_resp_data_3, vSRAMTemplate_165_i_io_r_resp_data_3); end
    if (vSRAMTemplate_165_g_io_r_resp_data_4 !== vSRAMTemplate_165_i_io_r_resp_data_4) begin errors++;
      $display("[%0t] SRAMTemplate_165.io_r_resp_data_4 g=%h i=%h", $time, vSRAMTemplate_165_g_io_r_resp_data_4, vSRAMTemplate_165_i_io_r_resp_data_4); end
    if (vSRAMTemplate_165_g_io_r_resp_data_5 !== vSRAMTemplate_165_i_io_r_resp_data_5) begin errors++;
      $display("[%0t] SRAMTemplate_165.io_r_resp_data_5 g=%h i=%h", $time, vSRAMTemplate_165_g_io_r_resp_data_5, vSRAMTemplate_165_i_io_r_resp_data_5); end
    if (vSRAMTemplate_165_g_io_r_resp_data_6 !== vSRAMTemplate_165_i_io_r_resp_data_6) begin errors++;
      $display("[%0t] SRAMTemplate_165.io_r_resp_data_6 g=%h i=%h", $time, vSRAMTemplate_165_g_io_r_resp_data_6, vSRAMTemplate_165_i_io_r_resp_data_6); end
    if (vSRAMTemplate_165_g_io_r_resp_data_7 !== vSRAMTemplate_165_i_io_r_resp_data_7) begin errors++;
      $display("[%0t] SRAMTemplate_165.io_r_resp_data_7 g=%h i=%h", $time, vSRAMTemplate_165_g_io_r_resp_data_7, vSRAMTemplate_165_i_io_r_resp_data_7); end
    if (vSRAMTemplate_165_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_165_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_165.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_165_g_boreChildrenBd_bore_rdata, vSRAMTemplate_165_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_181_io_r_req_valid;
  logic [8:0] vSRAMTemplate_181_io_r_req_bits_setIdx;
  logic vSRAMTemplate_181_io_w_req_valid;
  logic [8:0] vSRAMTemplate_181_io_w_req_bits_setIdx;
  logic [18:0] vSRAMTemplate_181_io_w_req_bits_data_0;
  logic [18:0] vSRAMTemplate_181_io_w_req_bits_data_1;
  logic [18:0] vSRAMTemplate_181_io_w_req_bits_data_2;
  logic [18:0] vSRAMTemplate_181_io_w_req_bits_data_3;
  logic [3:0] vSRAMTemplate_181_io_w_req_bits_waymask;
  logic vSRAMTemplate_181_io_broadcast_ram_hold;
  logic vSRAMTemplate_181_io_broadcast_ram_bypass;
  logic vSRAMTemplate_181_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_181_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_181_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_181_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_181_io_broadcast_ram_ctl;
  logic vSRAMTemplate_181_io_broadcast_cgen;
  logic [9:0] vSRAMTemplate_181_boreChildrenBd_bore_addr;
  logic [9:0] vSRAMTemplate_181_boreChildrenBd_bore_addr_rd;
  logic [75:0] vSRAMTemplate_181_boreChildrenBd_bore_wdata;
  logic [3:0] vSRAMTemplate_181_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_181_boreChildrenBd_bore_re;
  logic vSRAMTemplate_181_boreChildrenBd_bore_we;
  logic vSRAMTemplate_181_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_181_boreChildrenBd_bore_selectedOH;
  logic [5:0] vSRAMTemplate_181_boreChildrenBd_bore_array;
  wire vSRAMTemplate_181_g_io_r_req_ready;
  wire vSRAMTemplate_181_i_io_r_req_ready;
  wire [18:0] vSRAMTemplate_181_g_io_r_resp_data_0;
  wire [18:0] vSRAMTemplate_181_i_io_r_resp_data_0;
  wire [18:0] vSRAMTemplate_181_g_io_r_resp_data_1;
  wire [18:0] vSRAMTemplate_181_i_io_r_resp_data_1;
  wire [18:0] vSRAMTemplate_181_g_io_r_resp_data_2;
  wire [18:0] vSRAMTemplate_181_i_io_r_resp_data_2;
  wire [18:0] vSRAMTemplate_181_g_io_r_resp_data_3;
  wire [18:0] vSRAMTemplate_181_i_io_r_resp_data_3;
  wire [75:0] vSRAMTemplate_181_g_boreChildrenBd_bore_rdata;
  wire [75:0] vSRAMTemplate_181_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_181 u_g_SRAMTemplate_181 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_181_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_181_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_181_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_181_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_181_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_181_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_181_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_181_io_w_req_bits_data_3), .io_w_req_bits_waymask(vSRAMTemplate_181_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_181_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_181_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_181_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_181_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_181_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_181_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_181_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_181_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_181_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_181_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_181_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_181_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_181_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_181_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_181_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_181_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_181_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_181_g_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_181_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_181_g_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_181_g_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_181_g_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_181_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_181_xs u_i_SRAMTemplate_181 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_181_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_181_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_181_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_181_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_181_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_181_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_181_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_181_io_w_req_bits_data_3), .io_w_req_bits_waymask(vSRAMTemplate_181_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_181_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_181_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_181_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_181_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_181_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_181_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_181_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_181_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_181_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_181_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_181_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_181_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_181_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_181_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_181_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_181_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_181_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_181_i_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_181_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_181_i_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_181_i_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_181_i_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_181_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_181_io_r_req_valid <= 1'b0;
      vSRAMTemplate_181_io_w_req_valid <= 1'b0;
      vSRAMTemplate_181_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_181_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_181_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_181_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_181_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_181_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_181_io_r_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_181_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_181_io_w_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_181_io_w_req_bits_data_0 <= 19'($urandom);
      vSRAMTemplate_181_io_w_req_bits_data_1 <= 19'($urandom);
      vSRAMTemplate_181_io_w_req_bits_data_2 <= 19'($urandom);
      vSRAMTemplate_181_io_w_req_bits_data_3 <= 19'($urandom);
      vSRAMTemplate_181_io_w_req_bits_waymask <= 4'($urandom);
      vSRAMTemplate_181_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_181_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_181_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_181_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_181_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_181_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_181_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_181_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_181_boreChildrenBd_bore_addr <= 10'($urandom);
      vSRAMTemplate_181_boreChildrenBd_bore_addr_rd <= 10'($urandom);
      vSRAMTemplate_181_boreChildrenBd_bore_wdata <= 76'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_181_boreChildrenBd_bore_wmask <= 4'($urandom);
      vSRAMTemplate_181_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_181_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_181_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_181_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_181_boreChildrenBd_bore_array <= 6'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_181_g_io_r_req_ready !== vSRAMTemplate_181_i_io_r_req_ready) begin errors++;
      $display("[%0t] SRAMTemplate_181.io_r_req_ready g=%h i=%h", $time, vSRAMTemplate_181_g_io_r_req_ready, vSRAMTemplate_181_i_io_r_req_ready); end
    if (vSRAMTemplate_181_g_io_r_resp_data_0 !== vSRAMTemplate_181_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_181.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_181_g_io_r_resp_data_0, vSRAMTemplate_181_i_io_r_resp_data_0); end
    if (vSRAMTemplate_181_g_io_r_resp_data_1 !== vSRAMTemplate_181_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_181.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_181_g_io_r_resp_data_1, vSRAMTemplate_181_i_io_r_resp_data_1); end
    if (vSRAMTemplate_181_g_io_r_resp_data_2 !== vSRAMTemplate_181_i_io_r_resp_data_2) begin errors++;
      $display("[%0t] SRAMTemplate_181.io_r_resp_data_2 g=%h i=%h", $time, vSRAMTemplate_181_g_io_r_resp_data_2, vSRAMTemplate_181_i_io_r_resp_data_2); end
    if (vSRAMTemplate_181_g_io_r_resp_data_3 !== vSRAMTemplate_181_i_io_r_resp_data_3) begin errors++;
      $display("[%0t] SRAMTemplate_181.io_r_resp_data_3 g=%h i=%h", $time, vSRAMTemplate_181_g_io_r_resp_data_3, vSRAMTemplate_181_i_io_r_resp_data_3); end
    if (vSRAMTemplate_181_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_181_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_181.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_181_g_boreChildrenBd_bore_rdata, vSRAMTemplate_181_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_186_io_r_req_valid;
  logic [8:0] vSRAMTemplate_186_io_r_req_bits_setIdx;
  logic vSRAMTemplate_186_io_w_req_valid;
  logic [8:0] vSRAMTemplate_186_io_w_req_bits_setIdx;
  logic [15:0] vSRAMTemplate_186_io_w_req_bits_data_0;
  logic vSRAMTemplate_186_io_broadcast_ram_hold;
  logic vSRAMTemplate_186_io_broadcast_ram_bypass;
  logic vSRAMTemplate_186_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_186_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_186_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_186_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_186_io_broadcast_ram_ctl;
  logic vSRAMTemplate_186_io_broadcast_cgen;
  logic [9:0] vSRAMTemplate_186_boreChildrenBd_bore_addr;
  logic [9:0] vSRAMTemplate_186_boreChildrenBd_bore_addr_rd;
  logic [15:0] vSRAMTemplate_186_boreChildrenBd_bore_wdata;
  logic vSRAMTemplate_186_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_186_boreChildrenBd_bore_re;
  logic vSRAMTemplate_186_boreChildrenBd_bore_we;
  logic vSRAMTemplate_186_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_186_boreChildrenBd_bore_selectedOH;
  logic [5:0] vSRAMTemplate_186_boreChildrenBd_bore_array;
  wire [15:0] vSRAMTemplate_186_g_io_r_resp_data_0;
  wire [15:0] vSRAMTemplate_186_i_io_r_resp_data_0;
  wire [15:0] vSRAMTemplate_186_g_boreChildrenBd_bore_rdata;
  wire [15:0] vSRAMTemplate_186_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_186 u_g_SRAMTemplate_186 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_186_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_186_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_186_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_186_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_186_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_186_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_186_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_186_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_186_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_186_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_186_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_186_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_186_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_186_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_186_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_186_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_186_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_186_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_186_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_186_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_186_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_186_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_186_g_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_186_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_186_xs u_i_SRAMTemplate_186 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_186_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_186_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_186_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_186_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_186_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_186_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_186_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_186_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_186_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_186_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_186_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_186_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_186_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_186_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_186_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_186_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_186_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_186_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_186_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_186_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_186_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_186_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_186_i_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_186_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_186_io_r_req_valid <= 1'b0;
      vSRAMTemplate_186_io_w_req_valid <= 1'b0;
      vSRAMTemplate_186_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_186_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_186_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_186_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_186_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_186_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_186_io_r_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_186_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_186_io_w_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_186_io_w_req_bits_data_0 <= 16'($urandom);
      vSRAMTemplate_186_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_186_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_186_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_186_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_186_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_186_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_186_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_186_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_186_boreChildrenBd_bore_addr <= 10'($urandom);
      vSRAMTemplate_186_boreChildrenBd_bore_addr_rd <= 10'($urandom);
      vSRAMTemplate_186_boreChildrenBd_bore_wdata <= 16'($urandom);
      vSRAMTemplate_186_boreChildrenBd_bore_wmask <= 1'($urandom);
      vSRAMTemplate_186_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_186_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_186_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_186_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_186_boreChildrenBd_bore_array <= 6'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_186_g_io_r_resp_data_0 !== vSRAMTemplate_186_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_186.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_186_g_io_r_resp_data_0, vSRAMTemplate_186_i_io_r_resp_data_0); end
    if (vSRAMTemplate_186_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_186_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_186.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_186_g_boreChildrenBd_bore_rdata, vSRAMTemplate_186_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_187_io_r_req_valid;
  logic [8:0] vSRAMTemplate_187_io_r_req_bits_setIdx;
  logic vSRAMTemplate_187_io_w_req_valid;
  logic [8:0] vSRAMTemplate_187_io_w_req_bits_setIdx;
  logic vSRAMTemplate_187_io_w_req_bits_data_0;
  logic vSRAMTemplate_187_io_w_req_bits_data_1;
  logic vSRAMTemplate_187_io_w_req_bits_data_2;
  logic vSRAMTemplate_187_io_w_req_bits_data_3;
  logic vSRAMTemplate_187_io_w_req_bits_data_4;
  logic vSRAMTemplate_187_io_w_req_bits_data_5;
  logic vSRAMTemplate_187_io_w_req_bits_data_6;
  logic vSRAMTemplate_187_io_w_req_bits_data_7;
  logic [7:0] vSRAMTemplate_187_io_w_req_bits_waymask;
  logic vSRAMTemplate_187_io_broadcast_ram_hold;
  logic vSRAMTemplate_187_io_broadcast_ram_bypass;
  logic vSRAMTemplate_187_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_187_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_187_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_187_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_187_io_broadcast_ram_ctl;
  logic vSRAMTemplate_187_io_broadcast_cgen;
  logic [9:0] vSRAMTemplate_187_boreChildrenBd_bore_addr;
  logic [9:0] vSRAMTemplate_187_boreChildrenBd_bore_addr_rd;
  logic [7:0] vSRAMTemplate_187_boreChildrenBd_bore_wdata;
  logic [7:0] vSRAMTemplate_187_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_187_boreChildrenBd_bore_re;
  logic vSRAMTemplate_187_boreChildrenBd_bore_we;
  logic vSRAMTemplate_187_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_187_boreChildrenBd_bore_selectedOH;
  logic [5:0] vSRAMTemplate_187_boreChildrenBd_bore_array;
  wire vSRAMTemplate_187_g_io_r_resp_data_0;
  wire vSRAMTemplate_187_i_io_r_resp_data_0;
  wire vSRAMTemplate_187_g_io_r_resp_data_1;
  wire vSRAMTemplate_187_i_io_r_resp_data_1;
  wire vSRAMTemplate_187_g_io_r_resp_data_2;
  wire vSRAMTemplate_187_i_io_r_resp_data_2;
  wire vSRAMTemplate_187_g_io_r_resp_data_3;
  wire vSRAMTemplate_187_i_io_r_resp_data_3;
  wire vSRAMTemplate_187_g_io_r_resp_data_4;
  wire vSRAMTemplate_187_i_io_r_resp_data_4;
  wire vSRAMTemplate_187_g_io_r_resp_data_5;
  wire vSRAMTemplate_187_i_io_r_resp_data_5;
  wire vSRAMTemplate_187_g_io_r_resp_data_6;
  wire vSRAMTemplate_187_i_io_r_resp_data_6;
  wire vSRAMTemplate_187_g_io_r_resp_data_7;
  wire vSRAMTemplate_187_i_io_r_resp_data_7;
  wire [7:0] vSRAMTemplate_187_g_boreChildrenBd_bore_rdata;
  wire [7:0] vSRAMTemplate_187_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_187 u_g_SRAMTemplate_187 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_187_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_187_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_187_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_187_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_187_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_187_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_187_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_187_io_w_req_bits_data_3), .io_w_req_bits_data_4(vSRAMTemplate_187_io_w_req_bits_data_4), .io_w_req_bits_data_5(vSRAMTemplate_187_io_w_req_bits_data_5), .io_w_req_bits_data_6(vSRAMTemplate_187_io_w_req_bits_data_6), .io_w_req_bits_data_7(vSRAMTemplate_187_io_w_req_bits_data_7), .io_w_req_bits_waymask(vSRAMTemplate_187_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_187_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_187_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_187_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_187_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_187_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_187_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_187_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_187_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_187_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_187_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_187_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_187_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_187_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_187_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_187_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_187_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_187_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_187_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_187_g_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_187_g_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_187_g_io_r_resp_data_3), .io_r_resp_data_4(vSRAMTemplate_187_g_io_r_resp_data_4), .io_r_resp_data_5(vSRAMTemplate_187_g_io_r_resp_data_5), .io_r_resp_data_6(vSRAMTemplate_187_g_io_r_resp_data_6), .io_r_resp_data_7(vSRAMTemplate_187_g_io_r_resp_data_7), .boreChildrenBd_bore_rdata(vSRAMTemplate_187_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_187_xs u_i_SRAMTemplate_187 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_187_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_187_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_187_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_187_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_187_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_187_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_187_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_187_io_w_req_bits_data_3), .io_w_req_bits_data_4(vSRAMTemplate_187_io_w_req_bits_data_4), .io_w_req_bits_data_5(vSRAMTemplate_187_io_w_req_bits_data_5), .io_w_req_bits_data_6(vSRAMTemplate_187_io_w_req_bits_data_6), .io_w_req_bits_data_7(vSRAMTemplate_187_io_w_req_bits_data_7), .io_w_req_bits_waymask(vSRAMTemplate_187_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_187_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_187_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_187_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_187_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_187_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_187_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_187_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_187_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_187_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_187_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_187_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_187_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_187_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_187_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_187_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_187_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_187_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_187_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_187_i_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_187_i_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_187_i_io_r_resp_data_3), .io_r_resp_data_4(vSRAMTemplate_187_i_io_r_resp_data_4), .io_r_resp_data_5(vSRAMTemplate_187_i_io_r_resp_data_5), .io_r_resp_data_6(vSRAMTemplate_187_i_io_r_resp_data_6), .io_r_resp_data_7(vSRAMTemplate_187_i_io_r_resp_data_7), .boreChildrenBd_bore_rdata(vSRAMTemplate_187_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_187_io_r_req_valid <= 1'b0;
      vSRAMTemplate_187_io_w_req_valid <= 1'b0;
      vSRAMTemplate_187_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_187_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_187_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_187_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_187_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_187_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_187_io_r_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_187_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_187_io_w_req_bits_setIdx <= 9'($urandom);
      vSRAMTemplate_187_io_w_req_bits_data_0 <= 1'($urandom);
      vSRAMTemplate_187_io_w_req_bits_data_1 <= 1'($urandom);
      vSRAMTemplate_187_io_w_req_bits_data_2 <= 1'($urandom);
      vSRAMTemplate_187_io_w_req_bits_data_3 <= 1'($urandom);
      vSRAMTemplate_187_io_w_req_bits_data_4 <= 1'($urandom);
      vSRAMTemplate_187_io_w_req_bits_data_5 <= 1'($urandom);
      vSRAMTemplate_187_io_w_req_bits_data_6 <= 1'($urandom);
      vSRAMTemplate_187_io_w_req_bits_data_7 <= 1'($urandom);
      vSRAMTemplate_187_io_w_req_bits_waymask <= 8'($urandom);
      vSRAMTemplate_187_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_187_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_187_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_187_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_187_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_187_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_187_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_187_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_187_boreChildrenBd_bore_addr <= 10'($urandom);
      vSRAMTemplate_187_boreChildrenBd_bore_addr_rd <= 10'($urandom);
      vSRAMTemplate_187_boreChildrenBd_bore_wdata <= 8'($urandom);
      vSRAMTemplate_187_boreChildrenBd_bore_wmask <= 8'($urandom);
      vSRAMTemplate_187_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_187_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_187_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_187_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_187_boreChildrenBd_bore_array <= 6'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_187_g_io_r_resp_data_0 !== vSRAMTemplate_187_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_187.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_187_g_io_r_resp_data_0, vSRAMTemplate_187_i_io_r_resp_data_0); end
    if (vSRAMTemplate_187_g_io_r_resp_data_1 !== vSRAMTemplate_187_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_187.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_187_g_io_r_resp_data_1, vSRAMTemplate_187_i_io_r_resp_data_1); end
    if (vSRAMTemplate_187_g_io_r_resp_data_2 !== vSRAMTemplate_187_i_io_r_resp_data_2) begin errors++;
      $display("[%0t] SRAMTemplate_187.io_r_resp_data_2 g=%h i=%h", $time, vSRAMTemplate_187_g_io_r_resp_data_2, vSRAMTemplate_187_i_io_r_resp_data_2); end
    if (vSRAMTemplate_187_g_io_r_resp_data_3 !== vSRAMTemplate_187_i_io_r_resp_data_3) begin errors++;
      $display("[%0t] SRAMTemplate_187.io_r_resp_data_3 g=%h i=%h", $time, vSRAMTemplate_187_g_io_r_resp_data_3, vSRAMTemplate_187_i_io_r_resp_data_3); end
    if (vSRAMTemplate_187_g_io_r_resp_data_4 !== vSRAMTemplate_187_i_io_r_resp_data_4) begin errors++;
      $display("[%0t] SRAMTemplate_187.io_r_resp_data_4 g=%h i=%h", $time, vSRAMTemplate_187_g_io_r_resp_data_4, vSRAMTemplate_187_i_io_r_resp_data_4); end
    if (vSRAMTemplate_187_g_io_r_resp_data_5 !== vSRAMTemplate_187_i_io_r_resp_data_5) begin errors++;
      $display("[%0t] SRAMTemplate_187.io_r_resp_data_5 g=%h i=%h", $time, vSRAMTemplate_187_g_io_r_resp_data_5, vSRAMTemplate_187_i_io_r_resp_data_5); end
    if (vSRAMTemplate_187_g_io_r_resp_data_6 !== vSRAMTemplate_187_i_io_r_resp_data_6) begin errors++;
      $display("[%0t] SRAMTemplate_187.io_r_resp_data_6 g=%h i=%h", $time, vSRAMTemplate_187_g_io_r_resp_data_6, vSRAMTemplate_187_i_io_r_resp_data_6); end
    if (vSRAMTemplate_187_g_io_r_resp_data_7 !== vSRAMTemplate_187_i_io_r_resp_data_7) begin errors++;
      $display("[%0t] SRAMTemplate_187.io_r_resp_data_7 g=%h i=%h", $time, vSRAMTemplate_187_g_io_r_resp_data_7, vSRAMTemplate_187_i_io_r_resp_data_7); end
    if (vSRAMTemplate_187_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_187_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_187.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_187_g_boreChildrenBd_bore_rdata, vSRAMTemplate_187_i_boreChildrenBd_bore_rdata); end
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

  logic vSRAMTemplate_64_io_r_req_valid;
  logic [7:0] vSRAMTemplate_64_io_r_req_bits_setIdx;
  logic vSRAMTemplate_64_io_w_req_valid;
  logic [7:0] vSRAMTemplate_64_io_w_req_bits_setIdx;
  logic [1:0] vSRAMTemplate_64_io_w_req_bits_data_0;
  logic [1:0] vSRAMTemplate_64_io_w_req_bits_data_1;
  logic [1:0] vSRAMTemplate_64_io_w_req_bits_data_2;
  logic [1:0] vSRAMTemplate_64_io_w_req_bits_data_3;
  logic [3:0] vSRAMTemplate_64_io_w_req_bits_waymask;
  logic vSRAMTemplate_64_io_broadcast_ram_hold;
  logic vSRAMTemplate_64_io_broadcast_ram_bypass;
  logic vSRAMTemplate_64_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_64_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_64_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_64_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_64_io_broadcast_ram_ctl;
  logic vSRAMTemplate_64_io_broadcast_cgen;
  logic [8:0] vSRAMTemplate_64_boreChildrenBd_bore_addr;
  logic [8:0] vSRAMTemplate_64_boreChildrenBd_bore_addr_rd;
  logic [7:0] vSRAMTemplate_64_boreChildrenBd_bore_wdata;
  logic [3:0] vSRAMTemplate_64_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_64_boreChildrenBd_bore_re;
  logic vSRAMTemplate_64_boreChildrenBd_bore_we;
  logic vSRAMTemplate_64_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_64_boreChildrenBd_bore_selectedOH;
  logic [6:0] vSRAMTemplate_64_boreChildrenBd_bore_array;
  wire [1:0] vSRAMTemplate_64_g_io_r_resp_data_0;
  wire [1:0] vSRAMTemplate_64_i_io_r_resp_data_0;
  wire [1:0] vSRAMTemplate_64_g_io_r_resp_data_1;
  wire [1:0] vSRAMTemplate_64_i_io_r_resp_data_1;
  wire [1:0] vSRAMTemplate_64_g_io_r_resp_data_2;
  wire [1:0] vSRAMTemplate_64_i_io_r_resp_data_2;
  wire [1:0] vSRAMTemplate_64_g_io_r_resp_data_3;
  wire [1:0] vSRAMTemplate_64_i_io_r_resp_data_3;
  wire [7:0] vSRAMTemplate_64_g_boreChildrenBd_bore_rdata;
  wire [7:0] vSRAMTemplate_64_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_64 u_g_SRAMTemplate_64 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_64_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_64_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_64_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_64_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_64_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_64_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_64_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_64_io_w_req_bits_data_3), .io_w_req_bits_waymask(vSRAMTemplate_64_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_64_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_64_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_64_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_64_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_64_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_64_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_64_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_64_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_64_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_64_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_64_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_64_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_64_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_64_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_64_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_64_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_64_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_64_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_64_g_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_64_g_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_64_g_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_64_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_64_xs u_i_SRAMTemplate_64 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_64_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_64_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_64_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_64_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_64_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_64_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_64_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_64_io_w_req_bits_data_3), .io_w_req_bits_waymask(vSRAMTemplate_64_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_64_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_64_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_64_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_64_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_64_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_64_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_64_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_64_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_64_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_64_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_64_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_64_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_64_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_64_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_64_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_64_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_64_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_64_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_64_i_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_64_i_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_64_i_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_64_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_64_io_r_req_valid <= 1'b0;
      vSRAMTemplate_64_io_w_req_valid <= 1'b0;
      vSRAMTemplate_64_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_64_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_64_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_64_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_64_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_64_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_64_io_r_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_64_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_64_io_w_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_64_io_w_req_bits_data_0 <= 2'($urandom);
      vSRAMTemplate_64_io_w_req_bits_data_1 <= 2'($urandom);
      vSRAMTemplate_64_io_w_req_bits_data_2 <= 2'($urandom);
      vSRAMTemplate_64_io_w_req_bits_data_3 <= 2'($urandom);
      vSRAMTemplate_64_io_w_req_bits_waymask <= 4'($urandom);
      vSRAMTemplate_64_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_64_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_64_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_64_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_64_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_64_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_64_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_64_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_64_boreChildrenBd_bore_addr <= 9'($urandom);
      vSRAMTemplate_64_boreChildrenBd_bore_addr_rd <= 9'($urandom);
      vSRAMTemplate_64_boreChildrenBd_bore_wdata <= 8'($urandom);
      vSRAMTemplate_64_boreChildrenBd_bore_wmask <= 4'($urandom);
      vSRAMTemplate_64_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_64_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_64_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_64_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_64_boreChildrenBd_bore_array <= 7'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_64_g_io_r_resp_data_0 !== vSRAMTemplate_64_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_64.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_64_g_io_r_resp_data_0, vSRAMTemplate_64_i_io_r_resp_data_0); end
    if (vSRAMTemplate_64_g_io_r_resp_data_1 !== vSRAMTemplate_64_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_64.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_64_g_io_r_resp_data_1, vSRAMTemplate_64_i_io_r_resp_data_1); end
    if (vSRAMTemplate_64_g_io_r_resp_data_2 !== vSRAMTemplate_64_i_io_r_resp_data_2) begin errors++;
      $display("[%0t] SRAMTemplate_64.io_r_resp_data_2 g=%h i=%h", $time, vSRAMTemplate_64_g_io_r_resp_data_2, vSRAMTemplate_64_i_io_r_resp_data_2); end
    if (vSRAMTemplate_64_g_io_r_resp_data_3 !== vSRAMTemplate_64_i_io_r_resp_data_3) begin errors++;
      $display("[%0t] SRAMTemplate_64.io_r_resp_data_3 g=%h i=%h", $time, vSRAMTemplate_64_g_io_r_resp_data_3, vSRAMTemplate_64_i_io_r_resp_data_3); end
    if (vSRAMTemplate_64_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_64_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_64.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_64_g_boreChildrenBd_bore_rdata, vSRAMTemplate_64_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_68_io_r_req_valid;
  logic [6:0] vSRAMTemplate_68_io_r_req_bits_setIdx;
  logic vSRAMTemplate_68_io_w_req_valid;
  logic [6:0] vSRAMTemplate_68_io_w_req_bits_setIdx;
  logic [5:0] vSRAMTemplate_68_io_w_req_bits_data_0;
  logic [5:0] vSRAMTemplate_68_io_w_req_bits_data_1;
  logic [5:0] vSRAMTemplate_68_io_w_req_bits_data_2;
  logic [5:0] vSRAMTemplate_68_io_w_req_bits_data_3;
  logic [3:0] vSRAMTemplate_68_io_w_req_bits_waymask;
  logic vSRAMTemplate_68_io_broadcast_ram_hold;
  logic vSRAMTemplate_68_io_broadcast_ram_bypass;
  logic vSRAMTemplate_68_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_68_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_68_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_68_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_68_io_broadcast_ram_ctl;
  logic vSRAMTemplate_68_io_broadcast_cgen;
  logic [7:0] vSRAMTemplate_68_boreChildrenBd_bore_addr;
  logic [7:0] vSRAMTemplate_68_boreChildrenBd_bore_addr_rd;
  logic [23:0] vSRAMTemplate_68_boreChildrenBd_bore_wdata;
  logic [3:0] vSRAMTemplate_68_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_68_boreChildrenBd_bore_re;
  logic vSRAMTemplate_68_boreChildrenBd_bore_we;
  logic vSRAMTemplate_68_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_68_boreChildrenBd_bore_selectedOH;
  logic [6:0] vSRAMTemplate_68_boreChildrenBd_bore_array;
  wire [5:0] vSRAMTemplate_68_g_io_r_resp_data_0;
  wire [5:0] vSRAMTemplate_68_i_io_r_resp_data_0;
  wire [5:0] vSRAMTemplate_68_g_io_r_resp_data_1;
  wire [5:0] vSRAMTemplate_68_i_io_r_resp_data_1;
  wire [5:0] vSRAMTemplate_68_g_io_r_resp_data_2;
  wire [5:0] vSRAMTemplate_68_i_io_r_resp_data_2;
  wire [5:0] vSRAMTemplate_68_g_io_r_resp_data_3;
  wire [5:0] vSRAMTemplate_68_i_io_r_resp_data_3;
  wire [23:0] vSRAMTemplate_68_g_boreChildrenBd_bore_rdata;
  wire [23:0] vSRAMTemplate_68_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_68 u_g_SRAMTemplate_68 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_68_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_68_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_68_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_68_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_68_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_68_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_68_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_68_io_w_req_bits_data_3), .io_w_req_bits_waymask(vSRAMTemplate_68_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_68_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_68_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_68_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_68_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_68_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_68_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_68_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_68_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_68_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_68_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_68_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_68_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_68_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_68_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_68_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_68_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_68_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_68_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_68_g_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_68_g_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_68_g_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_68_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_68_xs u_i_SRAMTemplate_68 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_68_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_68_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_68_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_68_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_68_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_68_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_68_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_68_io_w_req_bits_data_3), .io_w_req_bits_waymask(vSRAMTemplate_68_io_w_req_bits_waymask), .io_broadcast_ram_hold(vSRAMTemplate_68_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_68_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_68_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_68_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_68_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_68_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_68_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_68_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_68_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_68_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_68_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_68_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_68_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_68_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_68_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_68_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_68_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_68_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_68_i_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_68_i_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_68_i_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_68_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_68_io_r_req_valid <= 1'b0;
      vSRAMTemplate_68_io_w_req_valid <= 1'b0;
      vSRAMTemplate_68_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_68_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_68_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_68_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_68_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_68_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_68_io_r_req_bits_setIdx <= 7'($urandom);
      vSRAMTemplate_68_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_68_io_w_req_bits_setIdx <= 7'($urandom);
      vSRAMTemplate_68_io_w_req_bits_data_0 <= 6'($urandom);
      vSRAMTemplate_68_io_w_req_bits_data_1 <= 6'($urandom);
      vSRAMTemplate_68_io_w_req_bits_data_2 <= 6'($urandom);
      vSRAMTemplate_68_io_w_req_bits_data_3 <= 6'($urandom);
      vSRAMTemplate_68_io_w_req_bits_waymask <= 4'($urandom);
      vSRAMTemplate_68_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_68_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_68_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_68_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_68_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_68_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_68_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_68_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_68_boreChildrenBd_bore_addr <= 8'($urandom);
      vSRAMTemplate_68_boreChildrenBd_bore_addr_rd <= 8'($urandom);
      vSRAMTemplate_68_boreChildrenBd_bore_wdata <= 24'($urandom);
      vSRAMTemplate_68_boreChildrenBd_bore_wmask <= 4'($urandom);
      vSRAMTemplate_68_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_68_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_68_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_68_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_68_boreChildrenBd_bore_array <= 7'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_68_g_io_r_resp_data_0 !== vSRAMTemplate_68_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_68.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_68_g_io_r_resp_data_0, vSRAMTemplate_68_i_io_r_resp_data_0); end
    if (vSRAMTemplate_68_g_io_r_resp_data_1 !== vSRAMTemplate_68_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_68.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_68_g_io_r_resp_data_1, vSRAMTemplate_68_i_io_r_resp_data_1); end
    if (vSRAMTemplate_68_g_io_r_resp_data_2 !== vSRAMTemplate_68_i_io_r_resp_data_2) begin errors++;
      $display("[%0t] SRAMTemplate_68.io_r_resp_data_2 g=%h i=%h", $time, vSRAMTemplate_68_g_io_r_resp_data_2, vSRAMTemplate_68_i_io_r_resp_data_2); end
    if (vSRAMTemplate_68_g_io_r_resp_data_3 !== vSRAMTemplate_68_i_io_r_resp_data_3) begin errors++;
      $display("[%0t] SRAMTemplate_68.io_r_resp_data_3 g=%h i=%h", $time, vSRAMTemplate_68_g_io_r_resp_data_3, vSRAMTemplate_68_i_io_r_resp_data_3); end
    if (vSRAMTemplate_68_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_68_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_68.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_68_g_boreChildrenBd_bore_rdata, vSRAMTemplate_68_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_76_io_r_req_valid;
  logic [6:0] vSRAMTemplate_76_io_r_req_bits_setIdx;
  logic vSRAMTemplate_76_io_w_req_valid;
  logic [6:0] vSRAMTemplate_76_io_w_req_bits_setIdx;
  logic [37:0] vSRAMTemplate_76_io_w_req_bits_data_0;
  logic [37:0] vSRAMTemplate_76_io_w_req_bits_data_1;
  logic [75:0] vSRAMTemplate_76_io_w_req_bits_flattened_bitmask;
  logic vSRAMTemplate_76_io_broadcast_ram_hold;
  logic vSRAMTemplate_76_io_broadcast_ram_bypass;
  logic vSRAMTemplate_76_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_76_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_76_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_76_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_76_io_broadcast_ram_ctl;
  logic vSRAMTemplate_76_io_broadcast_cgen;
  logic [7:0] vSRAMTemplate_76_boreChildrenBd_bore_addr;
  logic [7:0] vSRAMTemplate_76_boreChildrenBd_bore_addr_rd;
  logic [75:0] vSRAMTemplate_76_boreChildrenBd_bore_wdata;
  logic [75:0] vSRAMTemplate_76_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_76_boreChildrenBd_bore_re;
  logic vSRAMTemplate_76_boreChildrenBd_bore_we;
  logic vSRAMTemplate_76_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_76_boreChildrenBd_bore_selectedOH;
  logic [6:0] vSRAMTemplate_76_boreChildrenBd_bore_array;
  wire vSRAMTemplate_76_g_io_r_req_ready;
  wire vSRAMTemplate_76_i_io_r_req_ready;
  wire [37:0] vSRAMTemplate_76_g_io_r_resp_data_0;
  wire [37:0] vSRAMTemplate_76_i_io_r_resp_data_0;
  wire [37:0] vSRAMTemplate_76_g_io_r_resp_data_1;
  wire [37:0] vSRAMTemplate_76_i_io_r_resp_data_1;
  wire [75:0] vSRAMTemplate_76_g_boreChildrenBd_bore_rdata;
  wire [75:0] vSRAMTemplate_76_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_76 u_g_SRAMTemplate_76 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_76_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_76_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_76_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_76_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_76_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_76_io_w_req_bits_data_1), .io_w_req_bits_flattened_bitmask(vSRAMTemplate_76_io_w_req_bits_flattened_bitmask), .io_broadcast_ram_hold(vSRAMTemplate_76_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_76_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_76_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_76_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_76_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_76_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_76_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_76_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_76_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_76_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_76_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_76_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_76_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_76_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_76_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_76_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_76_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_76_g_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_76_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_76_g_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_76_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_76_xs u_i_SRAMTemplate_76 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_76_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_76_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_76_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_76_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_76_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_76_io_w_req_bits_data_1), .io_w_req_bits_flattened_bitmask(vSRAMTemplate_76_io_w_req_bits_flattened_bitmask), .io_broadcast_ram_hold(vSRAMTemplate_76_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_76_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_76_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_76_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_76_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_76_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_76_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_76_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_76_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_76_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_76_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_76_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_76_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_76_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_76_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_76_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_76_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_76_i_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_76_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_76_i_io_r_resp_data_1), .boreChildrenBd_bore_rdata(vSRAMTemplate_76_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_76_io_r_req_valid <= 1'b0;
      vSRAMTemplate_76_io_w_req_valid <= 1'b0;
      vSRAMTemplate_76_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_76_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_76_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_76_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_76_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_76_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_76_io_r_req_bits_setIdx <= 7'($urandom);
      vSRAMTemplate_76_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_76_io_w_req_bits_setIdx <= 7'($urandom);
      vSRAMTemplate_76_io_w_req_bits_data_0 <= 38'({$urandom(), $urandom()});
      vSRAMTemplate_76_io_w_req_bits_data_1 <= 38'({$urandom(), $urandom()});
      vSRAMTemplate_76_io_w_req_bits_flattened_bitmask <= 76'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_76_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_76_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_76_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_76_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_76_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_76_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_76_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_76_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_76_boreChildrenBd_bore_addr <= 8'($urandom);
      vSRAMTemplate_76_boreChildrenBd_bore_addr_rd <= 8'($urandom);
      vSRAMTemplate_76_boreChildrenBd_bore_wdata <= 76'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_76_boreChildrenBd_bore_wmask <= 76'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_76_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_76_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_76_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_76_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_76_boreChildrenBd_bore_array <= 7'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_76_g_io_r_req_ready !== vSRAMTemplate_76_i_io_r_req_ready) begin errors++;
      $display("[%0t] SRAMTemplate_76.io_r_req_ready g=%h i=%h", $time, vSRAMTemplate_76_g_io_r_req_ready, vSRAMTemplate_76_i_io_r_req_ready); end
    if (vSRAMTemplate_76_g_io_r_resp_data_0 !== vSRAMTemplate_76_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_76.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_76_g_io_r_resp_data_0, vSRAMTemplate_76_i_io_r_resp_data_0); end
    if (vSRAMTemplate_76_g_io_r_resp_data_1 !== vSRAMTemplate_76_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_76.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_76_g_io_r_resp_data_1, vSRAMTemplate_76_i_io_r_resp_data_1); end
    if (vSRAMTemplate_76_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_76_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_76.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_76_g_boreChildrenBd_bore_rdata, vSRAMTemplate_76_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_78_io_r_req_valid;
  logic [6:0] vSRAMTemplate_78_io_r_req_bits_setIdx;
  logic vSRAMTemplate_78_io_w_req_valid;
  logic [6:0] vSRAMTemplate_78_io_w_req_bits_setIdx;
  logic [18:0] vSRAMTemplate_78_io_w_req_bits_data_0;
  logic [18:0] vSRAMTemplate_78_io_w_req_bits_data_1;
  logic [18:0] vSRAMTemplate_78_io_w_req_bits_data_2;
  logic [18:0] vSRAMTemplate_78_io_w_req_bits_data_3;
  logic [75:0] vSRAMTemplate_78_io_w_req_bits_flattened_bitmask;
  logic vSRAMTemplate_78_io_broadcast_ram_hold;
  logic vSRAMTemplate_78_io_broadcast_ram_bypass;
  logic vSRAMTemplate_78_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_78_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_78_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_78_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_78_io_broadcast_ram_ctl;
  logic vSRAMTemplate_78_io_broadcast_cgen;
  logic [7:0] vSRAMTemplate_78_boreChildrenBd_bore_addr;
  logic [7:0] vSRAMTemplate_78_boreChildrenBd_bore_addr_rd;
  logic [75:0] vSRAMTemplate_78_boreChildrenBd_bore_wdata;
  logic [75:0] vSRAMTemplate_78_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_78_boreChildrenBd_bore_re;
  logic vSRAMTemplate_78_boreChildrenBd_bore_we;
  logic vSRAMTemplate_78_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_78_boreChildrenBd_bore_selectedOH;
  logic [6:0] vSRAMTemplate_78_boreChildrenBd_bore_array;
  wire vSRAMTemplate_78_g_io_r_req_ready;
  wire vSRAMTemplate_78_i_io_r_req_ready;
  wire [18:0] vSRAMTemplate_78_g_io_r_resp_data_0;
  wire [18:0] vSRAMTemplate_78_i_io_r_resp_data_0;
  wire [18:0] vSRAMTemplate_78_g_io_r_resp_data_1;
  wire [18:0] vSRAMTemplate_78_i_io_r_resp_data_1;
  wire [18:0] vSRAMTemplate_78_g_io_r_resp_data_2;
  wire [18:0] vSRAMTemplate_78_i_io_r_resp_data_2;
  wire [18:0] vSRAMTemplate_78_g_io_r_resp_data_3;
  wire [18:0] vSRAMTemplate_78_i_io_r_resp_data_3;
  wire [75:0] vSRAMTemplate_78_g_boreChildrenBd_bore_rdata;
  wire [75:0] vSRAMTemplate_78_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_78 u_g_SRAMTemplate_78 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_78_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_78_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_78_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_78_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_78_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_78_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_78_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_78_io_w_req_bits_data_3), .io_w_req_bits_flattened_bitmask(vSRAMTemplate_78_io_w_req_bits_flattened_bitmask), .io_broadcast_ram_hold(vSRAMTemplate_78_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_78_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_78_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_78_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_78_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_78_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_78_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_78_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_78_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_78_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_78_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_78_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_78_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_78_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_78_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_78_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_78_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_78_g_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_78_g_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_78_g_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_78_g_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_78_g_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_78_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_78_xs u_i_SRAMTemplate_78 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_78_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_78_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_78_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_78_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_78_io_w_req_bits_data_0), .io_w_req_bits_data_1(vSRAMTemplate_78_io_w_req_bits_data_1), .io_w_req_bits_data_2(vSRAMTemplate_78_io_w_req_bits_data_2), .io_w_req_bits_data_3(vSRAMTemplate_78_io_w_req_bits_data_3), .io_w_req_bits_flattened_bitmask(vSRAMTemplate_78_io_w_req_bits_flattened_bitmask), .io_broadcast_ram_hold(vSRAMTemplate_78_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_78_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_78_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_78_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_78_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_78_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_78_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_78_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_78_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_78_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_78_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_78_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_78_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_78_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_78_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_78_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_78_boreChildrenBd_bore_array), .io_r_req_ready(vSRAMTemplate_78_i_io_r_req_ready), .io_r_resp_data_0(vSRAMTemplate_78_i_io_r_resp_data_0), .io_r_resp_data_1(vSRAMTemplate_78_i_io_r_resp_data_1), .io_r_resp_data_2(vSRAMTemplate_78_i_io_r_resp_data_2), .io_r_resp_data_3(vSRAMTemplate_78_i_io_r_resp_data_3), .boreChildrenBd_bore_rdata(vSRAMTemplate_78_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_78_io_r_req_valid <= 1'b0;
      vSRAMTemplate_78_io_w_req_valid <= 1'b0;
      vSRAMTemplate_78_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_78_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_78_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_78_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_78_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_78_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_78_io_r_req_bits_setIdx <= 7'($urandom);
      vSRAMTemplate_78_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_78_io_w_req_bits_setIdx <= 7'($urandom);
      vSRAMTemplate_78_io_w_req_bits_data_0 <= 19'($urandom);
      vSRAMTemplate_78_io_w_req_bits_data_1 <= 19'($urandom);
      vSRAMTemplate_78_io_w_req_bits_data_2 <= 19'($urandom);
      vSRAMTemplate_78_io_w_req_bits_data_3 <= 19'($urandom);
      vSRAMTemplate_78_io_w_req_bits_flattened_bitmask <= 76'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_78_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_78_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_78_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_78_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_78_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_78_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_78_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_78_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_78_boreChildrenBd_bore_addr <= 8'($urandom);
      vSRAMTemplate_78_boreChildrenBd_bore_addr_rd <= 8'($urandom);
      vSRAMTemplate_78_boreChildrenBd_bore_wdata <= 76'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_78_boreChildrenBd_bore_wmask <= 76'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_78_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_78_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_78_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_78_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_78_boreChildrenBd_bore_array <= 7'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_78_g_io_r_req_ready !== vSRAMTemplate_78_i_io_r_req_ready) begin errors++;
      $display("[%0t] SRAMTemplate_78.io_r_req_ready g=%h i=%h", $time, vSRAMTemplate_78_g_io_r_req_ready, vSRAMTemplate_78_i_io_r_req_ready); end
    if (vSRAMTemplate_78_g_io_r_resp_data_0 !== vSRAMTemplate_78_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_78.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_78_g_io_r_resp_data_0, vSRAMTemplate_78_i_io_r_resp_data_0); end
    if (vSRAMTemplate_78_g_io_r_resp_data_1 !== vSRAMTemplate_78_i_io_r_resp_data_1) begin errors++;
      $display("[%0t] SRAMTemplate_78.io_r_resp_data_1 g=%h i=%h", $time, vSRAMTemplate_78_g_io_r_resp_data_1, vSRAMTemplate_78_i_io_r_resp_data_1); end
    if (vSRAMTemplate_78_g_io_r_resp_data_2 !== vSRAMTemplate_78_i_io_r_resp_data_2) begin errors++;
      $display("[%0t] SRAMTemplate_78.io_r_resp_data_2 g=%h i=%h", $time, vSRAMTemplate_78_g_io_r_resp_data_2, vSRAMTemplate_78_i_io_r_resp_data_2); end
    if (vSRAMTemplate_78_g_io_r_resp_data_3 !== vSRAMTemplate_78_i_io_r_resp_data_3) begin errors++;
      $display("[%0t] SRAMTemplate_78.io_r_resp_data_3 g=%h i=%h", $time, vSRAMTemplate_78_g_io_r_resp_data_3, vSRAMTemplate_78_i_io_r_resp_data_3); end
    if (vSRAMTemplate_78_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_78_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_78.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_78_g_boreChildrenBd_bore_rdata, vSRAMTemplate_78_i_boreChildrenBd_bore_rdata); end
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

  logic vSRAMTemplate_84_io_r_req_valid;
  logic [7:0] vSRAMTemplate_84_io_r_req_bits_setIdx;
  logic vSRAMTemplate_84_io_w_req_valid;
  logic [7:0] vSRAMTemplate_84_io_w_req_bits_setIdx;
  logic [71:0] vSRAMTemplate_84_io_w_req_bits_data_0;
  logic vSRAMTemplate_84_io_broadcast_ram_hold;
  logic vSRAMTemplate_84_io_broadcast_ram_bypass;
  logic vSRAMTemplate_84_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_84_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_84_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_84_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_84_io_broadcast_ram_ctl;
  logic vSRAMTemplate_84_io_broadcast_cgen;
  logic [8:0] vSRAMTemplate_84_boreChildrenBd_bore_addr;
  logic [8:0] vSRAMTemplate_84_boreChildrenBd_bore_addr_rd;
  logic [71:0] vSRAMTemplate_84_boreChildrenBd_bore_wdata;
  logic vSRAMTemplate_84_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_84_boreChildrenBd_bore_re;
  logic vSRAMTemplate_84_boreChildrenBd_bore_we;
  logic vSRAMTemplate_84_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_84_boreChildrenBd_bore_selectedOH;
  logic vSRAMTemplate_84_boreChildrenBd_bore_array;
  wire [71:0] vSRAMTemplate_84_g_io_r_resp_data_0;
  wire [71:0] vSRAMTemplate_84_i_io_r_resp_data_0;
  wire [71:0] vSRAMTemplate_84_g_boreChildrenBd_bore_rdata;
  wire [71:0] vSRAMTemplate_84_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_84 u_g_SRAMTemplate_84 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_84_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_84_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_84_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_84_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_84_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_84_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_84_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_84_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_84_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_84_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_84_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_84_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_84_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_84_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_84_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_84_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_84_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_84_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_84_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_84_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_84_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_84_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_84_g_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_84_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_84_xs u_i_SRAMTemplate_84 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_84_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_84_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_84_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_84_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_84_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_84_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_84_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_84_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_84_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_84_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_84_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_84_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_84_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_84_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_84_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_84_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_84_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_84_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_84_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_84_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_84_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_84_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_84_i_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_84_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_84_io_r_req_valid <= 1'b0;
      vSRAMTemplate_84_io_w_req_valid <= 1'b0;
      vSRAMTemplate_84_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_84_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_84_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_84_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_84_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_84_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_84_io_r_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_84_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_84_io_w_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_84_io_w_req_bits_data_0 <= 72'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_84_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_84_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_84_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_84_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_84_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_84_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_84_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_84_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_84_boreChildrenBd_bore_addr <= 9'($urandom);
      vSRAMTemplate_84_boreChildrenBd_bore_addr_rd <= 9'($urandom);
      vSRAMTemplate_84_boreChildrenBd_bore_wdata <= 72'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_84_boreChildrenBd_bore_wmask <= 1'($urandom);
      vSRAMTemplate_84_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_84_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_84_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_84_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_84_boreChildrenBd_bore_array <= 1'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_84_g_io_r_resp_data_0 !== vSRAMTemplate_84_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_84.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_84_g_io_r_resp_data_0, vSRAMTemplate_84_i_io_r_resp_data_0); end
    if (vSRAMTemplate_84_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_84_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_84.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_84_g_boreChildrenBd_bore_rdata, vSRAMTemplate_84_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_86_io_r_req_valid;
  logic [7:0] vSRAMTemplate_86_io_r_req_bits_setIdx;
  logic vSRAMTemplate_86_io_w_req_valid;
  logic [7:0] vSRAMTemplate_86_io_w_req_bits_setIdx;
  logic [71:0] vSRAMTemplate_86_io_w_req_bits_data_0;
  logic vSRAMTemplate_86_io_broadcast_ram_hold;
  logic vSRAMTemplate_86_io_broadcast_ram_bypass;
  logic vSRAMTemplate_86_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_86_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_86_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_86_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_86_io_broadcast_ram_ctl;
  logic vSRAMTemplate_86_io_broadcast_cgen;
  logic [8:0] vSRAMTemplate_86_boreChildrenBd_bore_addr;
  logic [8:0] vSRAMTemplate_86_boreChildrenBd_bore_addr_rd;
  logic [71:0] vSRAMTemplate_86_boreChildrenBd_bore_wdata;
  logic vSRAMTemplate_86_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_86_boreChildrenBd_bore_re;
  logic vSRAMTemplate_86_boreChildrenBd_bore_we;
  logic vSRAMTemplate_86_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_86_boreChildrenBd_bore_selectedOH;
  logic [1:0] vSRAMTemplate_86_boreChildrenBd_bore_array;
  wire [71:0] vSRAMTemplate_86_g_io_r_resp_data_0;
  wire [71:0] vSRAMTemplate_86_i_io_r_resp_data_0;
  wire [71:0] vSRAMTemplate_86_g_boreChildrenBd_bore_rdata;
  wire [71:0] vSRAMTemplate_86_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_86 u_g_SRAMTemplate_86 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_86_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_86_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_86_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_86_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_86_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_86_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_86_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_86_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_86_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_86_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_86_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_86_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_86_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_86_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_86_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_86_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_86_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_86_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_86_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_86_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_86_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_86_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_86_g_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_86_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_86_xs u_i_SRAMTemplate_86 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_86_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_86_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_86_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_86_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_86_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_86_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_86_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_86_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_86_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_86_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_86_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_86_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_86_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_86_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_86_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_86_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_86_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_86_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_86_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_86_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_86_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_86_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_86_i_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_86_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_86_io_r_req_valid <= 1'b0;
      vSRAMTemplate_86_io_w_req_valid <= 1'b0;
      vSRAMTemplate_86_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_86_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_86_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_86_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_86_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_86_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_86_io_r_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_86_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_86_io_w_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_86_io_w_req_bits_data_0 <= 72'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_86_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_86_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_86_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_86_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_86_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_86_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_86_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_86_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_86_boreChildrenBd_bore_addr <= 9'($urandom);
      vSRAMTemplate_86_boreChildrenBd_bore_addr_rd <= 9'($urandom);
      vSRAMTemplate_86_boreChildrenBd_bore_wdata <= 72'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_86_boreChildrenBd_bore_wmask <= 1'($urandom);
      vSRAMTemplate_86_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_86_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_86_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_86_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_86_boreChildrenBd_bore_array <= 2'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_86_g_io_r_resp_data_0 !== vSRAMTemplate_86_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_86.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_86_g_io_r_resp_data_0, vSRAMTemplate_86_i_io_r_resp_data_0); end
    if (vSRAMTemplate_86_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_86_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_86.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_86_g_boreChildrenBd_bore_rdata, vSRAMTemplate_86_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_88_io_r_req_valid;
  logic [7:0] vSRAMTemplate_88_io_r_req_bits_setIdx;
  logic vSRAMTemplate_88_io_w_req_valid;
  logic [7:0] vSRAMTemplate_88_io_w_req_bits_setIdx;
  logic [71:0] vSRAMTemplate_88_io_w_req_bits_data_0;
  logic vSRAMTemplate_88_io_broadcast_ram_hold;
  logic vSRAMTemplate_88_io_broadcast_ram_bypass;
  logic vSRAMTemplate_88_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_88_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_88_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_88_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_88_io_broadcast_ram_ctl;
  logic vSRAMTemplate_88_io_broadcast_cgen;
  logic [8:0] vSRAMTemplate_88_boreChildrenBd_bore_addr;
  logic [8:0] vSRAMTemplate_88_boreChildrenBd_bore_addr_rd;
  logic [71:0] vSRAMTemplate_88_boreChildrenBd_bore_wdata;
  logic vSRAMTemplate_88_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_88_boreChildrenBd_bore_re;
  logic vSRAMTemplate_88_boreChildrenBd_bore_we;
  logic vSRAMTemplate_88_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_88_boreChildrenBd_bore_selectedOH;
  logic [2:0] vSRAMTemplate_88_boreChildrenBd_bore_array;
  wire [71:0] vSRAMTemplate_88_g_io_r_resp_data_0;
  wire [71:0] vSRAMTemplate_88_i_io_r_resp_data_0;
  wire [71:0] vSRAMTemplate_88_g_boreChildrenBd_bore_rdata;
  wire [71:0] vSRAMTemplate_88_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_88 u_g_SRAMTemplate_88 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_88_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_88_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_88_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_88_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_88_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_88_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_88_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_88_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_88_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_88_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_88_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_88_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_88_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_88_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_88_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_88_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_88_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_88_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_88_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_88_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_88_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_88_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_88_g_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_88_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_88_xs u_i_SRAMTemplate_88 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_88_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_88_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_88_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_88_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_88_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_88_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_88_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_88_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_88_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_88_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_88_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_88_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_88_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_88_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_88_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_88_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_88_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_88_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_88_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_88_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_88_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_88_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_88_i_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_88_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_88_io_r_req_valid <= 1'b0;
      vSRAMTemplate_88_io_w_req_valid <= 1'b0;
      vSRAMTemplate_88_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_88_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_88_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_88_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_88_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_88_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_88_io_r_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_88_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_88_io_w_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_88_io_w_req_bits_data_0 <= 72'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_88_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_88_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_88_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_88_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_88_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_88_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_88_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_88_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_88_boreChildrenBd_bore_addr <= 9'($urandom);
      vSRAMTemplate_88_boreChildrenBd_bore_addr_rd <= 9'($urandom);
      vSRAMTemplate_88_boreChildrenBd_bore_wdata <= 72'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_88_boreChildrenBd_bore_wmask <= 1'($urandom);
      vSRAMTemplate_88_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_88_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_88_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_88_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_88_boreChildrenBd_bore_array <= 3'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_88_g_io_r_resp_data_0 !== vSRAMTemplate_88_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_88.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_88_g_io_r_resp_data_0, vSRAMTemplate_88_i_io_r_resp_data_0); end
    if (vSRAMTemplate_88_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_88_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_88.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_88_g_boreChildrenBd_bore_rdata, vSRAMTemplate_88_i_boreChildrenBd_bore_rdata); end
  end

  logic vSRAMTemplate_92_io_r_req_valid;
  logic [7:0] vSRAMTemplate_92_io_r_req_bits_setIdx;
  logic vSRAMTemplate_92_io_w_req_valid;
  logic [7:0] vSRAMTemplate_92_io_w_req_bits_setIdx;
  logic [71:0] vSRAMTemplate_92_io_w_req_bits_data_0;
  logic vSRAMTemplate_92_io_broadcast_ram_hold;
  logic vSRAMTemplate_92_io_broadcast_ram_bypass;
  logic vSRAMTemplate_92_io_broadcast_ram_bp_clken;
  logic vSRAMTemplate_92_io_broadcast_ram_aux_clk;
  logic vSRAMTemplate_92_io_broadcast_ram_aux_ckbp;
  logic vSRAMTemplate_92_io_broadcast_ram_mcp_hold;
  logic [63:0] vSRAMTemplate_92_io_broadcast_ram_ctl;
  logic vSRAMTemplate_92_io_broadcast_cgen;
  logic [8:0] vSRAMTemplate_92_boreChildrenBd_bore_addr;
  logic [8:0] vSRAMTemplate_92_boreChildrenBd_bore_addr_rd;
  logic [71:0] vSRAMTemplate_92_boreChildrenBd_bore_wdata;
  logic vSRAMTemplate_92_boreChildrenBd_bore_wmask;
  logic vSRAMTemplate_92_boreChildrenBd_bore_re;
  logic vSRAMTemplate_92_boreChildrenBd_bore_we;
  logic vSRAMTemplate_92_boreChildrenBd_bore_ack;
  logic vSRAMTemplate_92_boreChildrenBd_bore_selectedOH;
  logic [3:0] vSRAMTemplate_92_boreChildrenBd_bore_array;
  wire [71:0] vSRAMTemplate_92_g_io_r_resp_data_0;
  wire [71:0] vSRAMTemplate_92_i_io_r_resp_data_0;
  wire [71:0] vSRAMTemplate_92_g_boreChildrenBd_bore_rdata;
  wire [71:0] vSRAMTemplate_92_i_boreChildrenBd_bore_rdata;
  SRAMTemplate_92 u_g_SRAMTemplate_92 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_92_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_92_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_92_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_92_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_92_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_92_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_92_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_92_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_92_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_92_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_92_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_92_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_92_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_92_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_92_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_92_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_92_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_92_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_92_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_92_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_92_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_92_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_92_g_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_92_g_boreChildrenBd_bore_rdata));
  SRAMTemplate_92_xs u_i_SRAMTemplate_92 (.clock(clk), .reset(rst), .io_r_req_valid(vSRAMTemplate_92_io_r_req_valid), .io_r_req_bits_setIdx(vSRAMTemplate_92_io_r_req_bits_setIdx), .io_w_req_valid(vSRAMTemplate_92_io_w_req_valid), .io_w_req_bits_setIdx(vSRAMTemplate_92_io_w_req_bits_setIdx), .io_w_req_bits_data_0(vSRAMTemplate_92_io_w_req_bits_data_0), .io_broadcast_ram_hold(vSRAMTemplate_92_io_broadcast_ram_hold), .io_broadcast_ram_bypass(vSRAMTemplate_92_io_broadcast_ram_bypass), .io_broadcast_ram_bp_clken(vSRAMTemplate_92_io_broadcast_ram_bp_clken), .io_broadcast_ram_aux_clk(vSRAMTemplate_92_io_broadcast_ram_aux_clk), .io_broadcast_ram_aux_ckbp(vSRAMTemplate_92_io_broadcast_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(vSRAMTemplate_92_io_broadcast_ram_mcp_hold), .io_broadcast_ram_ctl(vSRAMTemplate_92_io_broadcast_ram_ctl), .io_broadcast_cgen(vSRAMTemplate_92_io_broadcast_cgen), .boreChildrenBd_bore_addr(vSRAMTemplate_92_boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(vSRAMTemplate_92_boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_wdata(vSRAMTemplate_92_boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(vSRAMTemplate_92_boreChildrenBd_bore_wmask), .boreChildrenBd_bore_re(vSRAMTemplate_92_boreChildrenBd_bore_re), .boreChildrenBd_bore_we(vSRAMTemplate_92_boreChildrenBd_bore_we), .boreChildrenBd_bore_ack(vSRAMTemplate_92_boreChildrenBd_bore_ack), .boreChildrenBd_bore_selectedOH(vSRAMTemplate_92_boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(vSRAMTemplate_92_boreChildrenBd_bore_array), .io_r_resp_data_0(vSRAMTemplate_92_i_io_r_resp_data_0), .boreChildrenBd_bore_rdata(vSRAMTemplate_92_i_boreChildrenBd_bore_rdata));
  always @(negedge clk) begin
    if (rst) begin
      vSRAMTemplate_92_io_r_req_valid <= 1'b0;
      vSRAMTemplate_92_io_w_req_valid <= 1'b0;
      vSRAMTemplate_92_io_broadcast_ram_hold <= 1'b0;
      vSRAMTemplate_92_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_92_boreChildrenBd_bore_re <= 1'b0;
      vSRAMTemplate_92_boreChildrenBd_bore_we <= 1'b0;
      vSRAMTemplate_92_boreChildrenBd_bore_ack <= 1'b0;
    end else begin
      vSRAMTemplate_92_io_r_req_valid <= ($urandom_range(0,3)!=0);
      vSRAMTemplate_92_io_r_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_92_io_w_req_valid <= ($urandom_range(0,2)==0);
      vSRAMTemplate_92_io_w_req_bits_setIdx <= 8'($urandom);
      vSRAMTemplate_92_io_w_req_bits_data_0 <= 72'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_92_io_broadcast_ram_hold <= ($urandom_range(0,15)==0);
      vSRAMTemplate_92_io_broadcast_ram_bypass <= 1'b0;
      vSRAMTemplate_92_io_broadcast_ram_bp_clken <= 1'b0;
      vSRAMTemplate_92_io_broadcast_ram_aux_clk <= 1'b0;
      vSRAMTemplate_92_io_broadcast_ram_aux_ckbp <= 1'b0;
      vSRAMTemplate_92_io_broadcast_ram_mcp_hold <= 1'b0;
      vSRAMTemplate_92_io_broadcast_ram_ctl <= 64'({$urandom(), $urandom()});
      vSRAMTemplate_92_io_broadcast_cgen <= 1'($urandom);
      vSRAMTemplate_92_boreChildrenBd_bore_addr <= 9'($urandom);
      vSRAMTemplate_92_boreChildrenBd_bore_addr_rd <= 9'($urandom);
      vSRAMTemplate_92_boreChildrenBd_bore_wdata <= 72'({$urandom(), $urandom(), $urandom()});
      vSRAMTemplate_92_boreChildrenBd_bore_wmask <= 1'($urandom);
      vSRAMTemplate_92_boreChildrenBd_bore_re <= ($urandom_range(0,7)==0);
      vSRAMTemplate_92_boreChildrenBd_bore_we <= ($urandom_range(0,7)==0);
      vSRAMTemplate_92_boreChildrenBd_bore_ack <= ($urandom_range(0,7)==0);
      vSRAMTemplate_92_boreChildrenBd_bore_selectedOH <= 1'($urandom);
      vSRAMTemplate_92_boreChildrenBd_bore_array <= 4'($urandom);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vSRAMTemplate_92_g_io_r_resp_data_0 !== vSRAMTemplate_92_i_io_r_resp_data_0) begin errors++;
      $display("[%0t] SRAMTemplate_92.io_r_resp_data_0 g=%h i=%h", $time, vSRAMTemplate_92_g_io_r_resp_data_0, vSRAMTemplate_92_i_io_r_resp_data_0); end
    if (vSRAMTemplate_92_g_boreChildrenBd_bore_rdata !== vSRAMTemplate_92_i_boreChildrenBd_bore_rdata) begin errors++;
      $display("[%0t] SRAMTemplate_92.boreChildrenBd_bore_rdata g=%h i=%h", $time, vSRAMTemplate_92_g_boreChildrenBd_bore_rdata, vSRAMTemplate_92_i_boreChildrenBd_bore_rdata); end
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
