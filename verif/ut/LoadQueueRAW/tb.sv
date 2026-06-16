// 自动生成：scripts/gen_loadqueueraw.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_redirect_valid;
  logic io_redirect_bits_robIdx_flag;
  logic [7:0] io_redirect_bits_robIdx_value;
  logic io_redirect_bits_level;
  logic io_query_0_req_valid;
  logic io_query_0_req_bits_uop_preDecodeInfo_isRVC;
  logic io_query_0_req_bits_uop_ftqPtr_flag;
  logic [5:0] io_query_0_req_bits_uop_ftqPtr_value;
  logic [3:0] io_query_0_req_bits_uop_ftqOffset;
  logic io_query_0_req_bits_uop_robIdx_flag;
  logic [7:0] io_query_0_req_bits_uop_robIdx_value;
  logic io_query_0_req_bits_uop_sqIdx_flag;
  logic [5:0] io_query_0_req_bits_uop_sqIdx_value;
  logic [15:0] io_query_0_req_bits_mask;
  logic [47:0] io_query_0_req_bits_paddr;
  logic io_query_0_req_bits_data_valid;
  logic io_query_0_revoke;
  logic io_query_1_req_valid;
  logic io_query_1_req_bits_uop_preDecodeInfo_isRVC;
  logic io_query_1_req_bits_uop_ftqPtr_flag;
  logic [5:0] io_query_1_req_bits_uop_ftqPtr_value;
  logic [3:0] io_query_1_req_bits_uop_ftqOffset;
  logic io_query_1_req_bits_uop_robIdx_flag;
  logic [7:0] io_query_1_req_bits_uop_robIdx_value;
  logic io_query_1_req_bits_uop_sqIdx_flag;
  logic [5:0] io_query_1_req_bits_uop_sqIdx_value;
  logic [15:0] io_query_1_req_bits_mask;
  logic [47:0] io_query_1_req_bits_paddr;
  logic io_query_1_req_bits_data_valid;
  logic io_query_1_revoke;
  logic io_query_2_req_valid;
  logic io_query_2_req_bits_uop_preDecodeInfo_isRVC;
  logic io_query_2_req_bits_uop_ftqPtr_flag;
  logic [5:0] io_query_2_req_bits_uop_ftqPtr_value;
  logic [3:0] io_query_2_req_bits_uop_ftqOffset;
  logic io_query_2_req_bits_uop_robIdx_flag;
  logic [7:0] io_query_2_req_bits_uop_robIdx_value;
  logic io_query_2_req_bits_uop_sqIdx_flag;
  logic [5:0] io_query_2_req_bits_uop_sqIdx_value;
  logic [15:0] io_query_2_req_bits_mask;
  logic [47:0] io_query_2_req_bits_paddr;
  logic io_query_2_req_bits_data_valid;
  logic io_query_2_revoke;
  logic io_storeIn_0_valid;
  logic [5:0] io_storeIn_0_bits_uop_ftqPtr_value;
  logic [3:0] io_storeIn_0_bits_uop_ftqOffset;
  logic io_storeIn_0_bits_uop_robIdx_flag;
  logic [7:0] io_storeIn_0_bits_uop_robIdx_value;
  logic [47:0] io_storeIn_0_bits_paddr;
  logic [15:0] io_storeIn_0_bits_mask;
  logic io_storeIn_0_bits_wlineflag;
  logic io_storeIn_0_bits_miss;
  logic io_storeIn_1_valid;
  logic [5:0] io_storeIn_1_bits_uop_ftqPtr_value;
  logic [3:0] io_storeIn_1_bits_uop_ftqOffset;
  logic io_storeIn_1_bits_uop_robIdx_flag;
  logic [7:0] io_storeIn_1_bits_uop_robIdx_value;
  logic [47:0] io_storeIn_1_bits_paddr;
  logic [15:0] io_storeIn_1_bits_mask;
  logic io_storeIn_1_bits_wlineflag;
  logic io_storeIn_1_bits_miss;
  logic io_stAddrReadySqPtr_flag;
  logic [5:0] io_stAddrReadySqPtr_value;
  logic io_stIssuePtr_flag;
  logic [5:0] io_stIssuePtr_value;
  wire g_io_query_0_req_ready;
  wire i_io_query_0_req_ready;
  wire g_io_query_1_req_ready;
  wire i_io_query_1_req_ready;
  wire g_io_query_2_req_ready;
  wire i_io_query_2_req_ready;
  wire g_io_rollback_0_valid;
  wire i_io_rollback_0_valid;
  wire g_io_rollback_0_bits_isRVC;
  wire i_io_rollback_0_bits_isRVC;
  wire g_io_rollback_0_bits_robIdx_flag;
  wire i_io_rollback_0_bits_robIdx_flag;
  wire [7:0] g_io_rollback_0_bits_robIdx_value;
  wire [7:0] i_io_rollback_0_bits_robIdx_value;
  wire g_io_rollback_0_bits_ftqIdx_flag;
  wire i_io_rollback_0_bits_ftqIdx_flag;
  wire [5:0] g_io_rollback_0_bits_ftqIdx_value;
  wire [5:0] i_io_rollback_0_bits_ftqIdx_value;
  wire [3:0] g_io_rollback_0_bits_ftqOffset;
  wire [3:0] i_io_rollback_0_bits_ftqOffset;
  wire [5:0] g_io_rollback_0_bits_stFtqIdx_value;
  wire [5:0] i_io_rollback_0_bits_stFtqIdx_value;
  wire [3:0] g_io_rollback_0_bits_stFtqOffset;
  wire [3:0] i_io_rollback_0_bits_stFtqOffset;
  wire g_io_rollback_1_valid;
  wire i_io_rollback_1_valid;
  wire g_io_rollback_1_bits_isRVC;
  wire i_io_rollback_1_bits_isRVC;
  wire g_io_rollback_1_bits_robIdx_flag;
  wire i_io_rollback_1_bits_robIdx_flag;
  wire [7:0] g_io_rollback_1_bits_robIdx_value;
  wire [7:0] i_io_rollback_1_bits_robIdx_value;
  wire g_io_rollback_1_bits_ftqIdx_flag;
  wire i_io_rollback_1_bits_ftqIdx_flag;
  wire [5:0] g_io_rollback_1_bits_ftqIdx_value;
  wire [5:0] i_io_rollback_1_bits_ftqIdx_value;
  wire [3:0] g_io_rollback_1_bits_ftqOffset;
  wire [3:0] i_io_rollback_1_bits_ftqOffset;
  wire [5:0] g_io_rollback_1_bits_stFtqIdx_value;
  wire [5:0] i_io_rollback_1_bits_stFtqIdx_value;
  wire [3:0] g_io_rollback_1_bits_stFtqOffset;
  wire [3:0] i_io_rollback_1_bits_stFtqOffset;
  wire g_io_lqFull;
  wire i_io_lqFull;
  wire [5:0] g_io_perf_0_value;
  wire [5:0] i_io_perf_0_value;
  wire [5:0] g_io_perf_1_value;
  wire [5:0] i_io_perf_1_value;
  LoadQueueRAW    u_g (.clock(clk), .reset(rst), .io_redirect_valid(io_redirect_valid), .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag), .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value), .io_redirect_bits_level(io_redirect_bits_level), .io_query_0_req_valid(io_query_0_req_valid), .io_query_0_req_bits_uop_preDecodeInfo_isRVC(io_query_0_req_bits_uop_preDecodeInfo_isRVC), .io_query_0_req_bits_uop_ftqPtr_flag(io_query_0_req_bits_uop_ftqPtr_flag), .io_query_0_req_bits_uop_ftqPtr_value(io_query_0_req_bits_uop_ftqPtr_value), .io_query_0_req_bits_uop_ftqOffset(io_query_0_req_bits_uop_ftqOffset), .io_query_0_req_bits_uop_robIdx_flag(io_query_0_req_bits_uop_robIdx_flag), .io_query_0_req_bits_uop_robIdx_value(io_query_0_req_bits_uop_robIdx_value), .io_query_0_req_bits_uop_sqIdx_flag(io_query_0_req_bits_uop_sqIdx_flag), .io_query_0_req_bits_uop_sqIdx_value(io_query_0_req_bits_uop_sqIdx_value), .io_query_0_req_bits_mask(io_query_0_req_bits_mask), .io_query_0_req_bits_paddr(io_query_0_req_bits_paddr), .io_query_0_req_bits_data_valid(io_query_0_req_bits_data_valid), .io_query_0_revoke(io_query_0_revoke), .io_query_1_req_valid(io_query_1_req_valid), .io_query_1_req_bits_uop_preDecodeInfo_isRVC(io_query_1_req_bits_uop_preDecodeInfo_isRVC), .io_query_1_req_bits_uop_ftqPtr_flag(io_query_1_req_bits_uop_ftqPtr_flag), .io_query_1_req_bits_uop_ftqPtr_value(io_query_1_req_bits_uop_ftqPtr_value), .io_query_1_req_bits_uop_ftqOffset(io_query_1_req_bits_uop_ftqOffset), .io_query_1_req_bits_uop_robIdx_flag(io_query_1_req_bits_uop_robIdx_flag), .io_query_1_req_bits_uop_robIdx_value(io_query_1_req_bits_uop_robIdx_value), .io_query_1_req_bits_uop_sqIdx_flag(io_query_1_req_bits_uop_sqIdx_flag), .io_query_1_req_bits_uop_sqIdx_value(io_query_1_req_bits_uop_sqIdx_value), .io_query_1_req_bits_mask(io_query_1_req_bits_mask), .io_query_1_req_bits_paddr(io_query_1_req_bits_paddr), .io_query_1_req_bits_data_valid(io_query_1_req_bits_data_valid), .io_query_1_revoke(io_query_1_revoke), .io_query_2_req_valid(io_query_2_req_valid), .io_query_2_req_bits_uop_preDecodeInfo_isRVC(io_query_2_req_bits_uop_preDecodeInfo_isRVC), .io_query_2_req_bits_uop_ftqPtr_flag(io_query_2_req_bits_uop_ftqPtr_flag), .io_query_2_req_bits_uop_ftqPtr_value(io_query_2_req_bits_uop_ftqPtr_value), .io_query_2_req_bits_uop_ftqOffset(io_query_2_req_bits_uop_ftqOffset), .io_query_2_req_bits_uop_robIdx_flag(io_query_2_req_bits_uop_robIdx_flag), .io_query_2_req_bits_uop_robIdx_value(io_query_2_req_bits_uop_robIdx_value), .io_query_2_req_bits_uop_sqIdx_flag(io_query_2_req_bits_uop_sqIdx_flag), .io_query_2_req_bits_uop_sqIdx_value(io_query_2_req_bits_uop_sqIdx_value), .io_query_2_req_bits_mask(io_query_2_req_bits_mask), .io_query_2_req_bits_paddr(io_query_2_req_bits_paddr), .io_query_2_req_bits_data_valid(io_query_2_req_bits_data_valid), .io_query_2_revoke(io_query_2_revoke), .io_storeIn_0_valid(io_storeIn_0_valid), .io_storeIn_0_bits_uop_ftqPtr_value(io_storeIn_0_bits_uop_ftqPtr_value), .io_storeIn_0_bits_uop_ftqOffset(io_storeIn_0_bits_uop_ftqOffset), .io_storeIn_0_bits_uop_robIdx_flag(io_storeIn_0_bits_uop_robIdx_flag), .io_storeIn_0_bits_uop_robIdx_value(io_storeIn_0_bits_uop_robIdx_value), .io_storeIn_0_bits_paddr(io_storeIn_0_bits_paddr), .io_storeIn_0_bits_mask(io_storeIn_0_bits_mask), .io_storeIn_0_bits_wlineflag(io_storeIn_0_bits_wlineflag), .io_storeIn_0_bits_miss(io_storeIn_0_bits_miss), .io_storeIn_1_valid(io_storeIn_1_valid), .io_storeIn_1_bits_uop_ftqPtr_value(io_storeIn_1_bits_uop_ftqPtr_value), .io_storeIn_1_bits_uop_ftqOffset(io_storeIn_1_bits_uop_ftqOffset), .io_storeIn_1_bits_uop_robIdx_flag(io_storeIn_1_bits_uop_robIdx_flag), .io_storeIn_1_bits_uop_robIdx_value(io_storeIn_1_bits_uop_robIdx_value), .io_storeIn_1_bits_paddr(io_storeIn_1_bits_paddr), .io_storeIn_1_bits_mask(io_storeIn_1_bits_mask), .io_storeIn_1_bits_wlineflag(io_storeIn_1_bits_wlineflag), .io_storeIn_1_bits_miss(io_storeIn_1_bits_miss), .io_stAddrReadySqPtr_flag(io_stAddrReadySqPtr_flag), .io_stAddrReadySqPtr_value(io_stAddrReadySqPtr_value), .io_stIssuePtr_flag(io_stIssuePtr_flag), .io_stIssuePtr_value(io_stIssuePtr_value), .io_query_0_req_ready(g_io_query_0_req_ready), .io_query_1_req_ready(g_io_query_1_req_ready), .io_query_2_req_ready(g_io_query_2_req_ready), .io_rollback_0_valid(g_io_rollback_0_valid), .io_rollback_0_bits_isRVC(g_io_rollback_0_bits_isRVC), .io_rollback_0_bits_robIdx_flag(g_io_rollback_0_bits_robIdx_flag), .io_rollback_0_bits_robIdx_value(g_io_rollback_0_bits_robIdx_value), .io_rollback_0_bits_ftqIdx_flag(g_io_rollback_0_bits_ftqIdx_flag), .io_rollback_0_bits_ftqIdx_value(g_io_rollback_0_bits_ftqIdx_value), .io_rollback_0_bits_ftqOffset(g_io_rollback_0_bits_ftqOffset), .io_rollback_0_bits_stFtqIdx_value(g_io_rollback_0_bits_stFtqIdx_value), .io_rollback_0_bits_stFtqOffset(g_io_rollback_0_bits_stFtqOffset), .io_rollback_1_valid(g_io_rollback_1_valid), .io_rollback_1_bits_isRVC(g_io_rollback_1_bits_isRVC), .io_rollback_1_bits_robIdx_flag(g_io_rollback_1_bits_robIdx_flag), .io_rollback_1_bits_robIdx_value(g_io_rollback_1_bits_robIdx_value), .io_rollback_1_bits_ftqIdx_flag(g_io_rollback_1_bits_ftqIdx_flag), .io_rollback_1_bits_ftqIdx_value(g_io_rollback_1_bits_ftqIdx_value), .io_rollback_1_bits_ftqOffset(g_io_rollback_1_bits_ftqOffset), .io_rollback_1_bits_stFtqIdx_value(g_io_rollback_1_bits_stFtqIdx_value), .io_rollback_1_bits_stFtqOffset(g_io_rollback_1_bits_stFtqOffset), .io_lqFull(g_io_lqFull), .io_perf_0_value(g_io_perf_0_value), .io_perf_1_value(g_io_perf_1_value));
  LoadQueueRAW_xs u_i (.clock(clk), .reset(rst), .io_redirect_valid(io_redirect_valid), .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag), .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value), .io_redirect_bits_level(io_redirect_bits_level), .io_query_0_req_valid(io_query_0_req_valid), .io_query_0_req_bits_uop_preDecodeInfo_isRVC(io_query_0_req_bits_uop_preDecodeInfo_isRVC), .io_query_0_req_bits_uop_ftqPtr_flag(io_query_0_req_bits_uop_ftqPtr_flag), .io_query_0_req_bits_uop_ftqPtr_value(io_query_0_req_bits_uop_ftqPtr_value), .io_query_0_req_bits_uop_ftqOffset(io_query_0_req_bits_uop_ftqOffset), .io_query_0_req_bits_uop_robIdx_flag(io_query_0_req_bits_uop_robIdx_flag), .io_query_0_req_bits_uop_robIdx_value(io_query_0_req_bits_uop_robIdx_value), .io_query_0_req_bits_uop_sqIdx_flag(io_query_0_req_bits_uop_sqIdx_flag), .io_query_0_req_bits_uop_sqIdx_value(io_query_0_req_bits_uop_sqIdx_value), .io_query_0_req_bits_mask(io_query_0_req_bits_mask), .io_query_0_req_bits_paddr(io_query_0_req_bits_paddr), .io_query_0_req_bits_data_valid(io_query_0_req_bits_data_valid), .io_query_0_revoke(io_query_0_revoke), .io_query_1_req_valid(io_query_1_req_valid), .io_query_1_req_bits_uop_preDecodeInfo_isRVC(io_query_1_req_bits_uop_preDecodeInfo_isRVC), .io_query_1_req_bits_uop_ftqPtr_flag(io_query_1_req_bits_uop_ftqPtr_flag), .io_query_1_req_bits_uop_ftqPtr_value(io_query_1_req_bits_uop_ftqPtr_value), .io_query_1_req_bits_uop_ftqOffset(io_query_1_req_bits_uop_ftqOffset), .io_query_1_req_bits_uop_robIdx_flag(io_query_1_req_bits_uop_robIdx_flag), .io_query_1_req_bits_uop_robIdx_value(io_query_1_req_bits_uop_robIdx_value), .io_query_1_req_bits_uop_sqIdx_flag(io_query_1_req_bits_uop_sqIdx_flag), .io_query_1_req_bits_uop_sqIdx_value(io_query_1_req_bits_uop_sqIdx_value), .io_query_1_req_bits_mask(io_query_1_req_bits_mask), .io_query_1_req_bits_paddr(io_query_1_req_bits_paddr), .io_query_1_req_bits_data_valid(io_query_1_req_bits_data_valid), .io_query_1_revoke(io_query_1_revoke), .io_query_2_req_valid(io_query_2_req_valid), .io_query_2_req_bits_uop_preDecodeInfo_isRVC(io_query_2_req_bits_uop_preDecodeInfo_isRVC), .io_query_2_req_bits_uop_ftqPtr_flag(io_query_2_req_bits_uop_ftqPtr_flag), .io_query_2_req_bits_uop_ftqPtr_value(io_query_2_req_bits_uop_ftqPtr_value), .io_query_2_req_bits_uop_ftqOffset(io_query_2_req_bits_uop_ftqOffset), .io_query_2_req_bits_uop_robIdx_flag(io_query_2_req_bits_uop_robIdx_flag), .io_query_2_req_bits_uop_robIdx_value(io_query_2_req_bits_uop_robIdx_value), .io_query_2_req_bits_uop_sqIdx_flag(io_query_2_req_bits_uop_sqIdx_flag), .io_query_2_req_bits_uop_sqIdx_value(io_query_2_req_bits_uop_sqIdx_value), .io_query_2_req_bits_mask(io_query_2_req_bits_mask), .io_query_2_req_bits_paddr(io_query_2_req_bits_paddr), .io_query_2_req_bits_data_valid(io_query_2_req_bits_data_valid), .io_query_2_revoke(io_query_2_revoke), .io_storeIn_0_valid(io_storeIn_0_valid), .io_storeIn_0_bits_uop_ftqPtr_value(io_storeIn_0_bits_uop_ftqPtr_value), .io_storeIn_0_bits_uop_ftqOffset(io_storeIn_0_bits_uop_ftqOffset), .io_storeIn_0_bits_uop_robIdx_flag(io_storeIn_0_bits_uop_robIdx_flag), .io_storeIn_0_bits_uop_robIdx_value(io_storeIn_0_bits_uop_robIdx_value), .io_storeIn_0_bits_paddr(io_storeIn_0_bits_paddr), .io_storeIn_0_bits_mask(io_storeIn_0_bits_mask), .io_storeIn_0_bits_wlineflag(io_storeIn_0_bits_wlineflag), .io_storeIn_0_bits_miss(io_storeIn_0_bits_miss), .io_storeIn_1_valid(io_storeIn_1_valid), .io_storeIn_1_bits_uop_ftqPtr_value(io_storeIn_1_bits_uop_ftqPtr_value), .io_storeIn_1_bits_uop_ftqOffset(io_storeIn_1_bits_uop_ftqOffset), .io_storeIn_1_bits_uop_robIdx_flag(io_storeIn_1_bits_uop_robIdx_flag), .io_storeIn_1_bits_uop_robIdx_value(io_storeIn_1_bits_uop_robIdx_value), .io_storeIn_1_bits_paddr(io_storeIn_1_bits_paddr), .io_storeIn_1_bits_mask(io_storeIn_1_bits_mask), .io_storeIn_1_bits_wlineflag(io_storeIn_1_bits_wlineflag), .io_storeIn_1_bits_miss(io_storeIn_1_bits_miss), .io_stAddrReadySqPtr_flag(io_stAddrReadySqPtr_flag), .io_stAddrReadySqPtr_value(io_stAddrReadySqPtr_value), .io_stIssuePtr_flag(io_stIssuePtr_flag), .io_stIssuePtr_value(io_stIssuePtr_value), .io_query_0_req_ready(i_io_query_0_req_ready), .io_query_1_req_ready(i_io_query_1_req_ready), .io_query_2_req_ready(i_io_query_2_req_ready), .io_rollback_0_valid(i_io_rollback_0_valid), .io_rollback_0_bits_isRVC(i_io_rollback_0_bits_isRVC), .io_rollback_0_bits_robIdx_flag(i_io_rollback_0_bits_robIdx_flag), .io_rollback_0_bits_robIdx_value(i_io_rollback_0_bits_robIdx_value), .io_rollback_0_bits_ftqIdx_flag(i_io_rollback_0_bits_ftqIdx_flag), .io_rollback_0_bits_ftqIdx_value(i_io_rollback_0_bits_ftqIdx_value), .io_rollback_0_bits_ftqOffset(i_io_rollback_0_bits_ftqOffset), .io_rollback_0_bits_stFtqIdx_value(i_io_rollback_0_bits_stFtqIdx_value), .io_rollback_0_bits_stFtqOffset(i_io_rollback_0_bits_stFtqOffset), .io_rollback_1_valid(i_io_rollback_1_valid), .io_rollback_1_bits_isRVC(i_io_rollback_1_bits_isRVC), .io_rollback_1_bits_robIdx_flag(i_io_rollback_1_bits_robIdx_flag), .io_rollback_1_bits_robIdx_value(i_io_rollback_1_bits_robIdx_value), .io_rollback_1_bits_ftqIdx_flag(i_io_rollback_1_bits_ftqIdx_flag), .io_rollback_1_bits_ftqIdx_value(i_io_rollback_1_bits_ftqIdx_value), .io_rollback_1_bits_ftqOffset(i_io_rollback_1_bits_ftqOffset), .io_rollback_1_bits_stFtqIdx_value(i_io_rollback_1_bits_stFtqIdx_value), .io_rollback_1_bits_stFtqOffset(i_io_rollback_1_bits_stFtqOffset), .io_lqFull(i_io_lqFull), .io_perf_0_value(i_io_perf_0_value), .io_perf_1_value(i_io_perf_1_value));
  always @(negedge clk) begin
    if (rst) begin
      io_query_0_req_valid <= 1'b0;
      io_query_1_req_valid <= 1'b0;
      io_query_2_req_valid <= 1'b0;
      io_storeIn_0_valid <= 1'b0;
      io_storeIn_1_valid <= 1'b0;
      io_redirect_valid <= 1'b0;
      io_query_0_revoke <= 1'b0;
      io_query_1_revoke <= 1'b0;
      io_query_2_revoke <= 1'b0;
    end else begin
      io_redirect_valid <= ($urandom_range(0,15)==0);
      io_redirect_bits_robIdx_flag <= $urandom_range(0,1);
      io_redirect_bits_robIdx_value <= {4'h0, 4'($urandom)};
      io_redirect_bits_level <= $urandom_range(0,1);
      io_query_0_req_valid <= ($urandom_range(0,1));
      io_query_0_req_bits_uop_preDecodeInfo_isRVC <= $urandom_range(0,1);
      io_query_0_req_bits_uop_ftqPtr_flag <= $urandom_range(0,1);
      io_query_0_req_bits_uop_ftqPtr_value <= 6'($urandom);
      io_query_0_req_bits_uop_ftqOffset <= 4'($urandom);
      io_query_0_req_bits_uop_robIdx_flag <= $urandom_range(0,1);
      io_query_0_req_bits_uop_robIdx_value <= {4'h0, 4'($urandom)};
      io_query_0_req_bits_uop_sqIdx_flag <= $urandom_range(0,1);
      io_query_0_req_bits_uop_sqIdx_value <= {2'h0, 4'($urandom)};
      io_query_0_req_bits_mask <= 16'($urandom);
      io_query_0_req_bits_paddr <= {38'h0, 10'($urandom)};
      io_query_0_req_bits_data_valid <= $urandom_range(0,1);
      io_query_0_revoke <= ($urandom_range(0,7)==0);
      io_query_1_req_valid <= ($urandom_range(0,1));
      io_query_1_req_bits_uop_preDecodeInfo_isRVC <= $urandom_range(0,1);
      io_query_1_req_bits_uop_ftqPtr_flag <= $urandom_range(0,1);
      io_query_1_req_bits_uop_ftqPtr_value <= 6'($urandom);
      io_query_1_req_bits_uop_ftqOffset <= 4'($urandom);
      io_query_1_req_bits_uop_robIdx_flag <= $urandom_range(0,1);
      io_query_1_req_bits_uop_robIdx_value <= {4'h0, 4'($urandom)};
      io_query_1_req_bits_uop_sqIdx_flag <= $urandom_range(0,1);
      io_query_1_req_bits_uop_sqIdx_value <= {2'h0, 4'($urandom)};
      io_query_1_req_bits_mask <= 16'($urandom);
      io_query_1_req_bits_paddr <= {38'h0, 10'($urandom)};
      io_query_1_req_bits_data_valid <= $urandom_range(0,1);
      io_query_1_revoke <= ($urandom_range(0,7)==0);
      io_query_2_req_valid <= ($urandom_range(0,1));
      io_query_2_req_bits_uop_preDecodeInfo_isRVC <= $urandom_range(0,1);
      io_query_2_req_bits_uop_ftqPtr_flag <= $urandom_range(0,1);
      io_query_2_req_bits_uop_ftqPtr_value <= 6'($urandom);
      io_query_2_req_bits_uop_ftqOffset <= 4'($urandom);
      io_query_2_req_bits_uop_robIdx_flag <= $urandom_range(0,1);
      io_query_2_req_bits_uop_robIdx_value <= {4'h0, 4'($urandom)};
      io_query_2_req_bits_uop_sqIdx_flag <= $urandom_range(0,1);
      io_query_2_req_bits_uop_sqIdx_value <= {2'h0, 4'($urandom)};
      io_query_2_req_bits_mask <= 16'($urandom);
      io_query_2_req_bits_paddr <= {38'h0, 10'($urandom)};
      io_query_2_req_bits_data_valid <= $urandom_range(0,1);
      io_query_2_revoke <= ($urandom_range(0,7)==0);
      io_storeIn_0_valid <= ($urandom_range(0,1));
      io_storeIn_0_bits_uop_ftqPtr_value <= 6'($urandom);
      io_storeIn_0_bits_uop_ftqOffset <= 4'($urandom);
      io_storeIn_0_bits_uop_robIdx_flag <= $urandom_range(0,1);
      io_storeIn_0_bits_uop_robIdx_value <= {4'h0, 4'($urandom)};
      io_storeIn_0_bits_paddr <= {38'h0, 10'($urandom)};
      io_storeIn_0_bits_mask <= 16'($urandom);
      io_storeIn_0_bits_wlineflag <= ($urandom_range(0,7)==0);
      io_storeIn_0_bits_miss <= ($urandom_range(0,3)==0);
      io_storeIn_1_valid <= ($urandom_range(0,1));
      io_storeIn_1_bits_uop_ftqPtr_value <= 6'($urandom);
      io_storeIn_1_bits_uop_ftqOffset <= 4'($urandom);
      io_storeIn_1_bits_uop_robIdx_flag <= $urandom_range(0,1);
      io_storeIn_1_bits_uop_robIdx_value <= {4'h0, 4'($urandom)};
      io_storeIn_1_bits_paddr <= {38'h0, 10'($urandom)};
      io_storeIn_1_bits_mask <= 16'($urandom);
      io_storeIn_1_bits_wlineflag <= ($urandom_range(0,7)==0);
      io_storeIn_1_bits_miss <= ($urandom_range(0,3)==0);
      io_stAddrReadySqPtr_flag <= $urandom_range(0,1);
      io_stAddrReadySqPtr_value <= {4'h0, 2'($urandom)};
      io_stIssuePtr_flag <= $urandom_range(0,1);
      io_stIssuePtr_value <= {4'h0, 2'($urandom)};
    end
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_query_0_req_ready) && g_io_query_0_req_ready !== i_io_query_0_req_ready) begin errors++;
      if(errors<=60) $display("[%0t] io_query_0_req_ready g=%h i=%h", $time, g_io_query_0_req_ready, i_io_query_0_req_ready); end
    if (!$isunknown(g_io_query_1_req_ready) && g_io_query_1_req_ready !== i_io_query_1_req_ready) begin errors++;
      if(errors<=60) $display("[%0t] io_query_1_req_ready g=%h i=%h", $time, g_io_query_1_req_ready, i_io_query_1_req_ready); end
    if (!$isunknown(g_io_query_2_req_ready) && g_io_query_2_req_ready !== i_io_query_2_req_ready) begin errors++;
      if(errors<=60) $display("[%0t] io_query_2_req_ready g=%h i=%h", $time, g_io_query_2_req_ready, i_io_query_2_req_ready); end
    if (!$isunknown(g_io_rollback_0_valid) && g_io_rollback_0_valid !== i_io_rollback_0_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_0_valid g=%h i=%h", $time, g_io_rollback_0_valid, i_io_rollback_0_valid); end
    if (!$isunknown(g_io_rollback_0_bits_isRVC) && g_io_rollback_0_bits_isRVC !== i_io_rollback_0_bits_isRVC) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_0_bits_isRVC g=%h i=%h", $time, g_io_rollback_0_bits_isRVC, i_io_rollback_0_bits_isRVC); end
    if (!$isunknown(g_io_rollback_0_bits_robIdx_flag) && g_io_rollback_0_bits_robIdx_flag !== i_io_rollback_0_bits_robIdx_flag) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_0_bits_robIdx_flag g=%h i=%h", $time, g_io_rollback_0_bits_robIdx_flag, i_io_rollback_0_bits_robIdx_flag); end
    if (!$isunknown(g_io_rollback_0_bits_robIdx_value) && g_io_rollback_0_bits_robIdx_value !== i_io_rollback_0_bits_robIdx_value) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_0_bits_robIdx_value g=%h i=%h", $time, g_io_rollback_0_bits_robIdx_value, i_io_rollback_0_bits_robIdx_value); end
    if (!$isunknown(g_io_rollback_0_bits_ftqIdx_flag) && g_io_rollback_0_bits_ftqIdx_flag !== i_io_rollback_0_bits_ftqIdx_flag) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_0_bits_ftqIdx_flag g=%h i=%h", $time, g_io_rollback_0_bits_ftqIdx_flag, i_io_rollback_0_bits_ftqIdx_flag); end
    if (!$isunknown(g_io_rollback_0_bits_ftqIdx_value) && g_io_rollback_0_bits_ftqIdx_value !== i_io_rollback_0_bits_ftqIdx_value) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_0_bits_ftqIdx_value g=%h i=%h", $time, g_io_rollback_0_bits_ftqIdx_value, i_io_rollback_0_bits_ftqIdx_value); end
    if (!$isunknown(g_io_rollback_0_bits_ftqOffset) && g_io_rollback_0_bits_ftqOffset !== i_io_rollback_0_bits_ftqOffset) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_0_bits_ftqOffset g=%h i=%h", $time, g_io_rollback_0_bits_ftqOffset, i_io_rollback_0_bits_ftqOffset); end
    if (!$isunknown(g_io_rollback_0_bits_stFtqIdx_value) && g_io_rollback_0_bits_stFtqIdx_value !== i_io_rollback_0_bits_stFtqIdx_value) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_0_bits_stFtqIdx_value g=%h i=%h", $time, g_io_rollback_0_bits_stFtqIdx_value, i_io_rollback_0_bits_stFtqIdx_value); end
    if (!$isunknown(g_io_rollback_0_bits_stFtqOffset) && g_io_rollback_0_bits_stFtqOffset !== i_io_rollback_0_bits_stFtqOffset) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_0_bits_stFtqOffset g=%h i=%h", $time, g_io_rollback_0_bits_stFtqOffset, i_io_rollback_0_bits_stFtqOffset); end
    if (!$isunknown(g_io_rollback_1_valid) && g_io_rollback_1_valid !== i_io_rollback_1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_1_valid g=%h i=%h", $time, g_io_rollback_1_valid, i_io_rollback_1_valid); end
    if (!$isunknown(g_io_rollback_1_bits_isRVC) && g_io_rollback_1_bits_isRVC !== i_io_rollback_1_bits_isRVC) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_1_bits_isRVC g=%h i=%h", $time, g_io_rollback_1_bits_isRVC, i_io_rollback_1_bits_isRVC); end
    if (!$isunknown(g_io_rollback_1_bits_robIdx_flag) && g_io_rollback_1_bits_robIdx_flag !== i_io_rollback_1_bits_robIdx_flag) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_1_bits_robIdx_flag g=%h i=%h", $time, g_io_rollback_1_bits_robIdx_flag, i_io_rollback_1_bits_robIdx_flag); end
    if (!$isunknown(g_io_rollback_1_bits_robIdx_value) && g_io_rollback_1_bits_robIdx_value !== i_io_rollback_1_bits_robIdx_value) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_1_bits_robIdx_value g=%h i=%h", $time, g_io_rollback_1_bits_robIdx_value, i_io_rollback_1_bits_robIdx_value); end
    if (!$isunknown(g_io_rollback_1_bits_ftqIdx_flag) && g_io_rollback_1_bits_ftqIdx_flag !== i_io_rollback_1_bits_ftqIdx_flag) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_1_bits_ftqIdx_flag g=%h i=%h", $time, g_io_rollback_1_bits_ftqIdx_flag, i_io_rollback_1_bits_ftqIdx_flag); end
    if (!$isunknown(g_io_rollback_1_bits_ftqIdx_value) && g_io_rollback_1_bits_ftqIdx_value !== i_io_rollback_1_bits_ftqIdx_value) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_1_bits_ftqIdx_value g=%h i=%h", $time, g_io_rollback_1_bits_ftqIdx_value, i_io_rollback_1_bits_ftqIdx_value); end
    if (!$isunknown(g_io_rollback_1_bits_ftqOffset) && g_io_rollback_1_bits_ftqOffset !== i_io_rollback_1_bits_ftqOffset) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_1_bits_ftqOffset g=%h i=%h", $time, g_io_rollback_1_bits_ftqOffset, i_io_rollback_1_bits_ftqOffset); end
    if (!$isunknown(g_io_rollback_1_bits_stFtqIdx_value) && g_io_rollback_1_bits_stFtqIdx_value !== i_io_rollback_1_bits_stFtqIdx_value) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_1_bits_stFtqIdx_value g=%h i=%h", $time, g_io_rollback_1_bits_stFtqIdx_value, i_io_rollback_1_bits_stFtqIdx_value); end
    if (!$isunknown(g_io_rollback_1_bits_stFtqOffset) && g_io_rollback_1_bits_stFtqOffset !== i_io_rollback_1_bits_stFtqOffset) begin errors++;
      if(errors<=60) $display("[%0t] io_rollback_1_bits_stFtqOffset g=%h i=%h", $time, g_io_rollback_1_bits_stFtqOffset, i_io_rollback_1_bits_stFtqOffset); end
    if (!$isunknown(g_io_lqFull) && g_io_lqFull !== i_io_lqFull) begin errors++;
      if(errors<=60) $display("[%0t] io_lqFull g=%h i=%h", $time, g_io_lqFull, i_io_lqFull); end
    if (!$isunknown(g_io_perf_0_value) && g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
      if(errors<=60) $display("[%0t] io_perf_0_value g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end
    if (!$isunknown(g_io_perf_1_value) && g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
      if(errors<=60) $display("[%0t] io_perf_1_value g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end
  end
  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
