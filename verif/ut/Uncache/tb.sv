// 自动生成：scripts/gen_uncache.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic auto_client_out_a_ready;
  logic auto_client_out_d_valid;
  logic [1:0] auto_client_out_d_bits_source;
  logic auto_client_out_d_bits_denied;
  logic [63:0] auto_client_out_d_bits_data;
  logic auto_client_out_d_bits_corrupt;
  logic io_enableOutstanding;
  logic io_flush_valid;
  logic io_lsq_req_valid;
  logic [4:0] io_lsq_req_bits_cmd;
  logic [47:0] io_lsq_req_bits_addr;
  logic [49:0] io_lsq_req_bits_vaddr;
  logic [63:0] io_lsq_req_bits_data;
  logic [7:0] io_lsq_req_bits_mask;
  logic [6:0] io_lsq_req_bits_id;
  logic io_lsq_req_bits_nc;
  logic io_lsq_req_bits_memBackTypeMM;
  logic io_lsq_resp_ready;
  logic [49:0] io_forward_0_vaddr;
  logic [47:0] io_forward_0_paddr;
  logic io_forward_0_valid;
  logic [49:0] io_forward_1_vaddr;
  logic [47:0] io_forward_1_paddr;
  logic io_forward_1_valid;
  logic [49:0] io_forward_2_vaddr;
  logic [47:0] io_forward_2_paddr;
  logic io_forward_2_valid;
  logic io_wfi_wfiReq;
  wire g_auto_client_out_a_valid;
  wire i_auto_client_out_a_valid;
  wire [3:0] g_auto_client_out_a_bits_opcode;
  wire [3:0] i_auto_client_out_a_bits_opcode;
  wire [1:0] g_auto_client_out_a_bits_size;
  wire [1:0] i_auto_client_out_a_bits_size;
  wire [1:0] g_auto_client_out_a_bits_source;
  wire [1:0] i_auto_client_out_a_bits_source;
  wire [47:0] g_auto_client_out_a_bits_address;
  wire [47:0] i_auto_client_out_a_bits_address;
  wire g_auto_client_out_a_bits_user_memPageType_NC;
  wire i_auto_client_out_a_bits_user_memPageType_NC;
  wire g_auto_client_out_a_bits_user_memBackType_MM;
  wire i_auto_client_out_a_bits_user_memBackType_MM;
  wire [7:0] g_auto_client_out_a_bits_mask;
  wire [7:0] i_auto_client_out_a_bits_mask;
  wire [63:0] g_auto_client_out_a_bits_data;
  wire [63:0] i_auto_client_out_a_bits_data;
  wire g_io_flush_empty;
  wire i_io_flush_empty;
  wire g_io_lsq_req_ready;
  wire i_io_lsq_req_ready;
  wire g_io_lsq_idResp_valid;
  wire i_io_lsq_idResp_valid;
  wire [6:0] g_io_lsq_idResp_bits_mid;
  wire [6:0] i_io_lsq_idResp_bits_mid;
  wire [1:0] g_io_lsq_idResp_bits_sid;
  wire [1:0] i_io_lsq_idResp_bits_sid;
  wire g_io_lsq_idResp_bits_is2lq;
  wire i_io_lsq_idResp_bits_is2lq;
  wire g_io_lsq_idResp_bits_nc;
  wire i_io_lsq_idResp_bits_nc;
  wire g_io_lsq_resp_valid;
  wire i_io_lsq_resp_valid;
  wire [63:0] g_io_lsq_resp_bits_data;
  wire [63:0] i_io_lsq_resp_bits_data;
  wire [1:0] g_io_lsq_resp_bits_id;
  wire [1:0] i_io_lsq_resp_bits_id;
  wire g_io_lsq_resp_bits_nc;
  wire i_io_lsq_resp_bits_nc;
  wire g_io_lsq_resp_bits_is2lq;
  wire i_io_lsq_resp_bits_is2lq;
  wire g_io_lsq_resp_bits_nderr;
  wire i_io_lsq_resp_bits_nderr;
  wire g_io_forward_0_forwardMask_0;
  wire i_io_forward_0_forwardMask_0;
  wire g_io_forward_0_forwardMask_1;
  wire i_io_forward_0_forwardMask_1;
  wire g_io_forward_0_forwardMask_2;
  wire i_io_forward_0_forwardMask_2;
  wire g_io_forward_0_forwardMask_3;
  wire i_io_forward_0_forwardMask_3;
  wire g_io_forward_0_forwardMask_4;
  wire i_io_forward_0_forwardMask_4;
  wire g_io_forward_0_forwardMask_5;
  wire i_io_forward_0_forwardMask_5;
  wire g_io_forward_0_forwardMask_6;
  wire i_io_forward_0_forwardMask_6;
  wire g_io_forward_0_forwardMask_7;
  wire i_io_forward_0_forwardMask_7;
  wire g_io_forward_0_forwardMask_8;
  wire i_io_forward_0_forwardMask_8;
  wire g_io_forward_0_forwardMask_9;
  wire i_io_forward_0_forwardMask_9;
  wire g_io_forward_0_forwardMask_10;
  wire i_io_forward_0_forwardMask_10;
  wire g_io_forward_0_forwardMask_11;
  wire i_io_forward_0_forwardMask_11;
  wire g_io_forward_0_forwardMask_12;
  wire i_io_forward_0_forwardMask_12;
  wire g_io_forward_0_forwardMask_13;
  wire i_io_forward_0_forwardMask_13;
  wire g_io_forward_0_forwardMask_14;
  wire i_io_forward_0_forwardMask_14;
  wire g_io_forward_0_forwardMask_15;
  wire i_io_forward_0_forwardMask_15;
  wire [7:0] g_io_forward_0_forwardData_0;
  wire [7:0] i_io_forward_0_forwardData_0;
  wire [7:0] g_io_forward_0_forwardData_1;
  wire [7:0] i_io_forward_0_forwardData_1;
  wire [7:0] g_io_forward_0_forwardData_2;
  wire [7:0] i_io_forward_0_forwardData_2;
  wire [7:0] g_io_forward_0_forwardData_3;
  wire [7:0] i_io_forward_0_forwardData_3;
  wire [7:0] g_io_forward_0_forwardData_4;
  wire [7:0] i_io_forward_0_forwardData_4;
  wire [7:0] g_io_forward_0_forwardData_5;
  wire [7:0] i_io_forward_0_forwardData_5;
  wire [7:0] g_io_forward_0_forwardData_6;
  wire [7:0] i_io_forward_0_forwardData_6;
  wire [7:0] g_io_forward_0_forwardData_7;
  wire [7:0] i_io_forward_0_forwardData_7;
  wire [7:0] g_io_forward_0_forwardData_8;
  wire [7:0] i_io_forward_0_forwardData_8;
  wire [7:0] g_io_forward_0_forwardData_9;
  wire [7:0] i_io_forward_0_forwardData_9;
  wire [7:0] g_io_forward_0_forwardData_10;
  wire [7:0] i_io_forward_0_forwardData_10;
  wire [7:0] g_io_forward_0_forwardData_11;
  wire [7:0] i_io_forward_0_forwardData_11;
  wire [7:0] g_io_forward_0_forwardData_12;
  wire [7:0] i_io_forward_0_forwardData_12;
  wire [7:0] g_io_forward_0_forwardData_13;
  wire [7:0] i_io_forward_0_forwardData_13;
  wire [7:0] g_io_forward_0_forwardData_14;
  wire [7:0] i_io_forward_0_forwardData_14;
  wire [7:0] g_io_forward_0_forwardData_15;
  wire [7:0] i_io_forward_0_forwardData_15;
  wire g_io_forward_0_matchInvalid;
  wire i_io_forward_0_matchInvalid;
  wire g_io_forward_1_forwardMask_0;
  wire i_io_forward_1_forwardMask_0;
  wire g_io_forward_1_forwardMask_1;
  wire i_io_forward_1_forwardMask_1;
  wire g_io_forward_1_forwardMask_2;
  wire i_io_forward_1_forwardMask_2;
  wire g_io_forward_1_forwardMask_3;
  wire i_io_forward_1_forwardMask_3;
  wire g_io_forward_1_forwardMask_4;
  wire i_io_forward_1_forwardMask_4;
  wire g_io_forward_1_forwardMask_5;
  wire i_io_forward_1_forwardMask_5;
  wire g_io_forward_1_forwardMask_6;
  wire i_io_forward_1_forwardMask_6;
  wire g_io_forward_1_forwardMask_7;
  wire i_io_forward_1_forwardMask_7;
  wire g_io_forward_1_forwardMask_8;
  wire i_io_forward_1_forwardMask_8;
  wire g_io_forward_1_forwardMask_9;
  wire i_io_forward_1_forwardMask_9;
  wire g_io_forward_1_forwardMask_10;
  wire i_io_forward_1_forwardMask_10;
  wire g_io_forward_1_forwardMask_11;
  wire i_io_forward_1_forwardMask_11;
  wire g_io_forward_1_forwardMask_12;
  wire i_io_forward_1_forwardMask_12;
  wire g_io_forward_1_forwardMask_13;
  wire i_io_forward_1_forwardMask_13;
  wire g_io_forward_1_forwardMask_14;
  wire i_io_forward_1_forwardMask_14;
  wire g_io_forward_1_forwardMask_15;
  wire i_io_forward_1_forwardMask_15;
  wire [7:0] g_io_forward_1_forwardData_0;
  wire [7:0] i_io_forward_1_forwardData_0;
  wire [7:0] g_io_forward_1_forwardData_1;
  wire [7:0] i_io_forward_1_forwardData_1;
  wire [7:0] g_io_forward_1_forwardData_2;
  wire [7:0] i_io_forward_1_forwardData_2;
  wire [7:0] g_io_forward_1_forwardData_3;
  wire [7:0] i_io_forward_1_forwardData_3;
  wire [7:0] g_io_forward_1_forwardData_4;
  wire [7:0] i_io_forward_1_forwardData_4;
  wire [7:0] g_io_forward_1_forwardData_5;
  wire [7:0] i_io_forward_1_forwardData_5;
  wire [7:0] g_io_forward_1_forwardData_6;
  wire [7:0] i_io_forward_1_forwardData_6;
  wire [7:0] g_io_forward_1_forwardData_7;
  wire [7:0] i_io_forward_1_forwardData_7;
  wire [7:0] g_io_forward_1_forwardData_8;
  wire [7:0] i_io_forward_1_forwardData_8;
  wire [7:0] g_io_forward_1_forwardData_9;
  wire [7:0] i_io_forward_1_forwardData_9;
  wire [7:0] g_io_forward_1_forwardData_10;
  wire [7:0] i_io_forward_1_forwardData_10;
  wire [7:0] g_io_forward_1_forwardData_11;
  wire [7:0] i_io_forward_1_forwardData_11;
  wire [7:0] g_io_forward_1_forwardData_12;
  wire [7:0] i_io_forward_1_forwardData_12;
  wire [7:0] g_io_forward_1_forwardData_13;
  wire [7:0] i_io_forward_1_forwardData_13;
  wire [7:0] g_io_forward_1_forwardData_14;
  wire [7:0] i_io_forward_1_forwardData_14;
  wire [7:0] g_io_forward_1_forwardData_15;
  wire [7:0] i_io_forward_1_forwardData_15;
  wire g_io_forward_1_matchInvalid;
  wire i_io_forward_1_matchInvalid;
  wire g_io_forward_2_forwardMask_0;
  wire i_io_forward_2_forwardMask_0;
  wire g_io_forward_2_forwardMask_1;
  wire i_io_forward_2_forwardMask_1;
  wire g_io_forward_2_forwardMask_2;
  wire i_io_forward_2_forwardMask_2;
  wire g_io_forward_2_forwardMask_3;
  wire i_io_forward_2_forwardMask_3;
  wire g_io_forward_2_forwardMask_4;
  wire i_io_forward_2_forwardMask_4;
  wire g_io_forward_2_forwardMask_5;
  wire i_io_forward_2_forwardMask_5;
  wire g_io_forward_2_forwardMask_6;
  wire i_io_forward_2_forwardMask_6;
  wire g_io_forward_2_forwardMask_7;
  wire i_io_forward_2_forwardMask_7;
  wire g_io_forward_2_forwardMask_8;
  wire i_io_forward_2_forwardMask_8;
  wire g_io_forward_2_forwardMask_9;
  wire i_io_forward_2_forwardMask_9;
  wire g_io_forward_2_forwardMask_10;
  wire i_io_forward_2_forwardMask_10;
  wire g_io_forward_2_forwardMask_11;
  wire i_io_forward_2_forwardMask_11;
  wire g_io_forward_2_forwardMask_12;
  wire i_io_forward_2_forwardMask_12;
  wire g_io_forward_2_forwardMask_13;
  wire i_io_forward_2_forwardMask_13;
  wire g_io_forward_2_forwardMask_14;
  wire i_io_forward_2_forwardMask_14;
  wire g_io_forward_2_forwardMask_15;
  wire i_io_forward_2_forwardMask_15;
  wire [7:0] g_io_forward_2_forwardData_0;
  wire [7:0] i_io_forward_2_forwardData_0;
  wire [7:0] g_io_forward_2_forwardData_1;
  wire [7:0] i_io_forward_2_forwardData_1;
  wire [7:0] g_io_forward_2_forwardData_2;
  wire [7:0] i_io_forward_2_forwardData_2;
  wire [7:0] g_io_forward_2_forwardData_3;
  wire [7:0] i_io_forward_2_forwardData_3;
  wire [7:0] g_io_forward_2_forwardData_4;
  wire [7:0] i_io_forward_2_forwardData_4;
  wire [7:0] g_io_forward_2_forwardData_5;
  wire [7:0] i_io_forward_2_forwardData_5;
  wire [7:0] g_io_forward_2_forwardData_6;
  wire [7:0] i_io_forward_2_forwardData_6;
  wire [7:0] g_io_forward_2_forwardData_7;
  wire [7:0] i_io_forward_2_forwardData_7;
  wire [7:0] g_io_forward_2_forwardData_8;
  wire [7:0] i_io_forward_2_forwardData_8;
  wire [7:0] g_io_forward_2_forwardData_9;
  wire [7:0] i_io_forward_2_forwardData_9;
  wire [7:0] g_io_forward_2_forwardData_10;
  wire [7:0] i_io_forward_2_forwardData_10;
  wire [7:0] g_io_forward_2_forwardData_11;
  wire [7:0] i_io_forward_2_forwardData_11;
  wire [7:0] g_io_forward_2_forwardData_12;
  wire [7:0] i_io_forward_2_forwardData_12;
  wire [7:0] g_io_forward_2_forwardData_13;
  wire [7:0] i_io_forward_2_forwardData_13;
  wire [7:0] g_io_forward_2_forwardData_14;
  wire [7:0] i_io_forward_2_forwardData_14;
  wire [7:0] g_io_forward_2_forwardData_15;
  wire [7:0] i_io_forward_2_forwardData_15;
  wire g_io_forward_2_matchInvalid;
  wire i_io_forward_2_matchInvalid;
  wire g_io_wfi_wfiSafe;
  wire i_io_wfi_wfiSafe;
  wire g_io_busError_ecc_error_valid;
  wire i_io_busError_ecc_error_valid;
  wire [47:0] g_io_busError_ecc_error_bits;
  wire [47:0] i_io_busError_ecc_error_bits;
  Uncache    u_g (.clock(clk), .reset(rst), .auto_client_out_a_ready(auto_client_out_a_ready), .auto_client_out_d_valid(auto_client_out_d_valid), .auto_client_out_d_bits_source(auto_client_out_d_bits_source), .auto_client_out_d_bits_denied(auto_client_out_d_bits_denied), .auto_client_out_d_bits_data(auto_client_out_d_bits_data), .auto_client_out_d_bits_corrupt(auto_client_out_d_bits_corrupt), .io_enableOutstanding(io_enableOutstanding), .io_flush_valid(io_flush_valid), .io_lsq_req_valid(io_lsq_req_valid), .io_lsq_req_bits_cmd(io_lsq_req_bits_cmd), .io_lsq_req_bits_addr(io_lsq_req_bits_addr), .io_lsq_req_bits_vaddr(io_lsq_req_bits_vaddr), .io_lsq_req_bits_data(io_lsq_req_bits_data), .io_lsq_req_bits_mask(io_lsq_req_bits_mask), .io_lsq_req_bits_id(io_lsq_req_bits_id), .io_lsq_req_bits_nc(io_lsq_req_bits_nc), .io_lsq_req_bits_memBackTypeMM(io_lsq_req_bits_memBackTypeMM), .io_lsq_resp_ready(io_lsq_resp_ready), .io_forward_0_vaddr(io_forward_0_vaddr), .io_forward_0_paddr(io_forward_0_paddr), .io_forward_0_valid(io_forward_0_valid), .io_forward_1_vaddr(io_forward_1_vaddr), .io_forward_1_paddr(io_forward_1_paddr), .io_forward_1_valid(io_forward_1_valid), .io_forward_2_vaddr(io_forward_2_vaddr), .io_forward_2_paddr(io_forward_2_paddr), .io_forward_2_valid(io_forward_2_valid), .io_wfi_wfiReq(io_wfi_wfiReq), .auto_client_out_a_valid(g_auto_client_out_a_valid), .auto_client_out_a_bits_opcode(g_auto_client_out_a_bits_opcode), .auto_client_out_a_bits_size(g_auto_client_out_a_bits_size), .auto_client_out_a_bits_source(g_auto_client_out_a_bits_source), .auto_client_out_a_bits_address(g_auto_client_out_a_bits_address), .auto_client_out_a_bits_user_memPageType_NC(g_auto_client_out_a_bits_user_memPageType_NC), .auto_client_out_a_bits_user_memBackType_MM(g_auto_client_out_a_bits_user_memBackType_MM), .auto_client_out_a_bits_mask(g_auto_client_out_a_bits_mask), .auto_client_out_a_bits_data(g_auto_client_out_a_bits_data), .io_flush_empty(g_io_flush_empty), .io_lsq_req_ready(g_io_lsq_req_ready), .io_lsq_idResp_valid(g_io_lsq_idResp_valid), .io_lsq_idResp_bits_mid(g_io_lsq_idResp_bits_mid), .io_lsq_idResp_bits_sid(g_io_lsq_idResp_bits_sid), .io_lsq_idResp_bits_is2lq(g_io_lsq_idResp_bits_is2lq), .io_lsq_idResp_bits_nc(g_io_lsq_idResp_bits_nc), .io_lsq_resp_valid(g_io_lsq_resp_valid), .io_lsq_resp_bits_data(g_io_lsq_resp_bits_data), .io_lsq_resp_bits_id(g_io_lsq_resp_bits_id), .io_lsq_resp_bits_nc(g_io_lsq_resp_bits_nc), .io_lsq_resp_bits_is2lq(g_io_lsq_resp_bits_is2lq), .io_lsq_resp_bits_nderr(g_io_lsq_resp_bits_nderr), .io_forward_0_forwardMask_0(g_io_forward_0_forwardMask_0), .io_forward_0_forwardMask_1(g_io_forward_0_forwardMask_1), .io_forward_0_forwardMask_2(g_io_forward_0_forwardMask_2), .io_forward_0_forwardMask_3(g_io_forward_0_forwardMask_3), .io_forward_0_forwardMask_4(g_io_forward_0_forwardMask_4), .io_forward_0_forwardMask_5(g_io_forward_0_forwardMask_5), .io_forward_0_forwardMask_6(g_io_forward_0_forwardMask_6), .io_forward_0_forwardMask_7(g_io_forward_0_forwardMask_7), .io_forward_0_forwardMask_8(g_io_forward_0_forwardMask_8), .io_forward_0_forwardMask_9(g_io_forward_0_forwardMask_9), .io_forward_0_forwardMask_10(g_io_forward_0_forwardMask_10), .io_forward_0_forwardMask_11(g_io_forward_0_forwardMask_11), .io_forward_0_forwardMask_12(g_io_forward_0_forwardMask_12), .io_forward_0_forwardMask_13(g_io_forward_0_forwardMask_13), .io_forward_0_forwardMask_14(g_io_forward_0_forwardMask_14), .io_forward_0_forwardMask_15(g_io_forward_0_forwardMask_15), .io_forward_0_forwardData_0(g_io_forward_0_forwardData_0), .io_forward_0_forwardData_1(g_io_forward_0_forwardData_1), .io_forward_0_forwardData_2(g_io_forward_0_forwardData_2), .io_forward_0_forwardData_3(g_io_forward_0_forwardData_3), .io_forward_0_forwardData_4(g_io_forward_0_forwardData_4), .io_forward_0_forwardData_5(g_io_forward_0_forwardData_5), .io_forward_0_forwardData_6(g_io_forward_0_forwardData_6), .io_forward_0_forwardData_7(g_io_forward_0_forwardData_7), .io_forward_0_forwardData_8(g_io_forward_0_forwardData_8), .io_forward_0_forwardData_9(g_io_forward_0_forwardData_9), .io_forward_0_forwardData_10(g_io_forward_0_forwardData_10), .io_forward_0_forwardData_11(g_io_forward_0_forwardData_11), .io_forward_0_forwardData_12(g_io_forward_0_forwardData_12), .io_forward_0_forwardData_13(g_io_forward_0_forwardData_13), .io_forward_0_forwardData_14(g_io_forward_0_forwardData_14), .io_forward_0_forwardData_15(g_io_forward_0_forwardData_15), .io_forward_0_matchInvalid(g_io_forward_0_matchInvalid), .io_forward_1_forwardMask_0(g_io_forward_1_forwardMask_0), .io_forward_1_forwardMask_1(g_io_forward_1_forwardMask_1), .io_forward_1_forwardMask_2(g_io_forward_1_forwardMask_2), .io_forward_1_forwardMask_3(g_io_forward_1_forwardMask_3), .io_forward_1_forwardMask_4(g_io_forward_1_forwardMask_4), .io_forward_1_forwardMask_5(g_io_forward_1_forwardMask_5), .io_forward_1_forwardMask_6(g_io_forward_1_forwardMask_6), .io_forward_1_forwardMask_7(g_io_forward_1_forwardMask_7), .io_forward_1_forwardMask_8(g_io_forward_1_forwardMask_8), .io_forward_1_forwardMask_9(g_io_forward_1_forwardMask_9), .io_forward_1_forwardMask_10(g_io_forward_1_forwardMask_10), .io_forward_1_forwardMask_11(g_io_forward_1_forwardMask_11), .io_forward_1_forwardMask_12(g_io_forward_1_forwardMask_12), .io_forward_1_forwardMask_13(g_io_forward_1_forwardMask_13), .io_forward_1_forwardMask_14(g_io_forward_1_forwardMask_14), .io_forward_1_forwardMask_15(g_io_forward_1_forwardMask_15), .io_forward_1_forwardData_0(g_io_forward_1_forwardData_0), .io_forward_1_forwardData_1(g_io_forward_1_forwardData_1), .io_forward_1_forwardData_2(g_io_forward_1_forwardData_2), .io_forward_1_forwardData_3(g_io_forward_1_forwardData_3), .io_forward_1_forwardData_4(g_io_forward_1_forwardData_4), .io_forward_1_forwardData_5(g_io_forward_1_forwardData_5), .io_forward_1_forwardData_6(g_io_forward_1_forwardData_6), .io_forward_1_forwardData_7(g_io_forward_1_forwardData_7), .io_forward_1_forwardData_8(g_io_forward_1_forwardData_8), .io_forward_1_forwardData_9(g_io_forward_1_forwardData_9), .io_forward_1_forwardData_10(g_io_forward_1_forwardData_10), .io_forward_1_forwardData_11(g_io_forward_1_forwardData_11), .io_forward_1_forwardData_12(g_io_forward_1_forwardData_12), .io_forward_1_forwardData_13(g_io_forward_1_forwardData_13), .io_forward_1_forwardData_14(g_io_forward_1_forwardData_14), .io_forward_1_forwardData_15(g_io_forward_1_forwardData_15), .io_forward_1_matchInvalid(g_io_forward_1_matchInvalid), .io_forward_2_forwardMask_0(g_io_forward_2_forwardMask_0), .io_forward_2_forwardMask_1(g_io_forward_2_forwardMask_1), .io_forward_2_forwardMask_2(g_io_forward_2_forwardMask_2), .io_forward_2_forwardMask_3(g_io_forward_2_forwardMask_3), .io_forward_2_forwardMask_4(g_io_forward_2_forwardMask_4), .io_forward_2_forwardMask_5(g_io_forward_2_forwardMask_5), .io_forward_2_forwardMask_6(g_io_forward_2_forwardMask_6), .io_forward_2_forwardMask_7(g_io_forward_2_forwardMask_7), .io_forward_2_forwardMask_8(g_io_forward_2_forwardMask_8), .io_forward_2_forwardMask_9(g_io_forward_2_forwardMask_9), .io_forward_2_forwardMask_10(g_io_forward_2_forwardMask_10), .io_forward_2_forwardMask_11(g_io_forward_2_forwardMask_11), .io_forward_2_forwardMask_12(g_io_forward_2_forwardMask_12), .io_forward_2_forwardMask_13(g_io_forward_2_forwardMask_13), .io_forward_2_forwardMask_14(g_io_forward_2_forwardMask_14), .io_forward_2_forwardMask_15(g_io_forward_2_forwardMask_15), .io_forward_2_forwardData_0(g_io_forward_2_forwardData_0), .io_forward_2_forwardData_1(g_io_forward_2_forwardData_1), .io_forward_2_forwardData_2(g_io_forward_2_forwardData_2), .io_forward_2_forwardData_3(g_io_forward_2_forwardData_3), .io_forward_2_forwardData_4(g_io_forward_2_forwardData_4), .io_forward_2_forwardData_5(g_io_forward_2_forwardData_5), .io_forward_2_forwardData_6(g_io_forward_2_forwardData_6), .io_forward_2_forwardData_7(g_io_forward_2_forwardData_7), .io_forward_2_forwardData_8(g_io_forward_2_forwardData_8), .io_forward_2_forwardData_9(g_io_forward_2_forwardData_9), .io_forward_2_forwardData_10(g_io_forward_2_forwardData_10), .io_forward_2_forwardData_11(g_io_forward_2_forwardData_11), .io_forward_2_forwardData_12(g_io_forward_2_forwardData_12), .io_forward_2_forwardData_13(g_io_forward_2_forwardData_13), .io_forward_2_forwardData_14(g_io_forward_2_forwardData_14), .io_forward_2_forwardData_15(g_io_forward_2_forwardData_15), .io_forward_2_matchInvalid(g_io_forward_2_matchInvalid), .io_wfi_wfiSafe(g_io_wfi_wfiSafe), .io_busError_ecc_error_valid(g_io_busError_ecc_error_valid), .io_busError_ecc_error_bits(g_io_busError_ecc_error_bits));
  Uncache_xs u_i (.clock(clk), .reset(rst), .auto_client_out_a_ready(auto_client_out_a_ready), .auto_client_out_d_valid(auto_client_out_d_valid), .auto_client_out_d_bits_source(auto_client_out_d_bits_source), .auto_client_out_d_bits_denied(auto_client_out_d_bits_denied), .auto_client_out_d_bits_data(auto_client_out_d_bits_data), .auto_client_out_d_bits_corrupt(auto_client_out_d_bits_corrupt), .io_enableOutstanding(io_enableOutstanding), .io_flush_valid(io_flush_valid), .io_lsq_req_valid(io_lsq_req_valid), .io_lsq_req_bits_cmd(io_lsq_req_bits_cmd), .io_lsq_req_bits_addr(io_lsq_req_bits_addr), .io_lsq_req_bits_vaddr(io_lsq_req_bits_vaddr), .io_lsq_req_bits_data(io_lsq_req_bits_data), .io_lsq_req_bits_mask(io_lsq_req_bits_mask), .io_lsq_req_bits_id(io_lsq_req_bits_id), .io_lsq_req_bits_nc(io_lsq_req_bits_nc), .io_lsq_req_bits_memBackTypeMM(io_lsq_req_bits_memBackTypeMM), .io_lsq_resp_ready(io_lsq_resp_ready), .io_forward_0_vaddr(io_forward_0_vaddr), .io_forward_0_paddr(io_forward_0_paddr), .io_forward_0_valid(io_forward_0_valid), .io_forward_1_vaddr(io_forward_1_vaddr), .io_forward_1_paddr(io_forward_1_paddr), .io_forward_1_valid(io_forward_1_valid), .io_forward_2_vaddr(io_forward_2_vaddr), .io_forward_2_paddr(io_forward_2_paddr), .io_forward_2_valid(io_forward_2_valid), .io_wfi_wfiReq(io_wfi_wfiReq), .auto_client_out_a_valid(i_auto_client_out_a_valid), .auto_client_out_a_bits_opcode(i_auto_client_out_a_bits_opcode), .auto_client_out_a_bits_size(i_auto_client_out_a_bits_size), .auto_client_out_a_bits_source(i_auto_client_out_a_bits_source), .auto_client_out_a_bits_address(i_auto_client_out_a_bits_address), .auto_client_out_a_bits_user_memPageType_NC(i_auto_client_out_a_bits_user_memPageType_NC), .auto_client_out_a_bits_user_memBackType_MM(i_auto_client_out_a_bits_user_memBackType_MM), .auto_client_out_a_bits_mask(i_auto_client_out_a_bits_mask), .auto_client_out_a_bits_data(i_auto_client_out_a_bits_data), .io_flush_empty(i_io_flush_empty), .io_lsq_req_ready(i_io_lsq_req_ready), .io_lsq_idResp_valid(i_io_lsq_idResp_valid), .io_lsq_idResp_bits_mid(i_io_lsq_idResp_bits_mid), .io_lsq_idResp_bits_sid(i_io_lsq_idResp_bits_sid), .io_lsq_idResp_bits_is2lq(i_io_lsq_idResp_bits_is2lq), .io_lsq_idResp_bits_nc(i_io_lsq_idResp_bits_nc), .io_lsq_resp_valid(i_io_lsq_resp_valid), .io_lsq_resp_bits_data(i_io_lsq_resp_bits_data), .io_lsq_resp_bits_id(i_io_lsq_resp_bits_id), .io_lsq_resp_bits_nc(i_io_lsq_resp_bits_nc), .io_lsq_resp_bits_is2lq(i_io_lsq_resp_bits_is2lq), .io_lsq_resp_bits_nderr(i_io_lsq_resp_bits_nderr), .io_forward_0_forwardMask_0(i_io_forward_0_forwardMask_0), .io_forward_0_forwardMask_1(i_io_forward_0_forwardMask_1), .io_forward_0_forwardMask_2(i_io_forward_0_forwardMask_2), .io_forward_0_forwardMask_3(i_io_forward_0_forwardMask_3), .io_forward_0_forwardMask_4(i_io_forward_0_forwardMask_4), .io_forward_0_forwardMask_5(i_io_forward_0_forwardMask_5), .io_forward_0_forwardMask_6(i_io_forward_0_forwardMask_6), .io_forward_0_forwardMask_7(i_io_forward_0_forwardMask_7), .io_forward_0_forwardMask_8(i_io_forward_0_forwardMask_8), .io_forward_0_forwardMask_9(i_io_forward_0_forwardMask_9), .io_forward_0_forwardMask_10(i_io_forward_0_forwardMask_10), .io_forward_0_forwardMask_11(i_io_forward_0_forwardMask_11), .io_forward_0_forwardMask_12(i_io_forward_0_forwardMask_12), .io_forward_0_forwardMask_13(i_io_forward_0_forwardMask_13), .io_forward_0_forwardMask_14(i_io_forward_0_forwardMask_14), .io_forward_0_forwardMask_15(i_io_forward_0_forwardMask_15), .io_forward_0_forwardData_0(i_io_forward_0_forwardData_0), .io_forward_0_forwardData_1(i_io_forward_0_forwardData_1), .io_forward_0_forwardData_2(i_io_forward_0_forwardData_2), .io_forward_0_forwardData_3(i_io_forward_0_forwardData_3), .io_forward_0_forwardData_4(i_io_forward_0_forwardData_4), .io_forward_0_forwardData_5(i_io_forward_0_forwardData_5), .io_forward_0_forwardData_6(i_io_forward_0_forwardData_6), .io_forward_0_forwardData_7(i_io_forward_0_forwardData_7), .io_forward_0_forwardData_8(i_io_forward_0_forwardData_8), .io_forward_0_forwardData_9(i_io_forward_0_forwardData_9), .io_forward_0_forwardData_10(i_io_forward_0_forwardData_10), .io_forward_0_forwardData_11(i_io_forward_0_forwardData_11), .io_forward_0_forwardData_12(i_io_forward_0_forwardData_12), .io_forward_0_forwardData_13(i_io_forward_0_forwardData_13), .io_forward_0_forwardData_14(i_io_forward_0_forwardData_14), .io_forward_0_forwardData_15(i_io_forward_0_forwardData_15), .io_forward_0_matchInvalid(i_io_forward_0_matchInvalid), .io_forward_1_forwardMask_0(i_io_forward_1_forwardMask_0), .io_forward_1_forwardMask_1(i_io_forward_1_forwardMask_1), .io_forward_1_forwardMask_2(i_io_forward_1_forwardMask_2), .io_forward_1_forwardMask_3(i_io_forward_1_forwardMask_3), .io_forward_1_forwardMask_4(i_io_forward_1_forwardMask_4), .io_forward_1_forwardMask_5(i_io_forward_1_forwardMask_5), .io_forward_1_forwardMask_6(i_io_forward_1_forwardMask_6), .io_forward_1_forwardMask_7(i_io_forward_1_forwardMask_7), .io_forward_1_forwardMask_8(i_io_forward_1_forwardMask_8), .io_forward_1_forwardMask_9(i_io_forward_1_forwardMask_9), .io_forward_1_forwardMask_10(i_io_forward_1_forwardMask_10), .io_forward_1_forwardMask_11(i_io_forward_1_forwardMask_11), .io_forward_1_forwardMask_12(i_io_forward_1_forwardMask_12), .io_forward_1_forwardMask_13(i_io_forward_1_forwardMask_13), .io_forward_1_forwardMask_14(i_io_forward_1_forwardMask_14), .io_forward_1_forwardMask_15(i_io_forward_1_forwardMask_15), .io_forward_1_forwardData_0(i_io_forward_1_forwardData_0), .io_forward_1_forwardData_1(i_io_forward_1_forwardData_1), .io_forward_1_forwardData_2(i_io_forward_1_forwardData_2), .io_forward_1_forwardData_3(i_io_forward_1_forwardData_3), .io_forward_1_forwardData_4(i_io_forward_1_forwardData_4), .io_forward_1_forwardData_5(i_io_forward_1_forwardData_5), .io_forward_1_forwardData_6(i_io_forward_1_forwardData_6), .io_forward_1_forwardData_7(i_io_forward_1_forwardData_7), .io_forward_1_forwardData_8(i_io_forward_1_forwardData_8), .io_forward_1_forwardData_9(i_io_forward_1_forwardData_9), .io_forward_1_forwardData_10(i_io_forward_1_forwardData_10), .io_forward_1_forwardData_11(i_io_forward_1_forwardData_11), .io_forward_1_forwardData_12(i_io_forward_1_forwardData_12), .io_forward_1_forwardData_13(i_io_forward_1_forwardData_13), .io_forward_1_forwardData_14(i_io_forward_1_forwardData_14), .io_forward_1_forwardData_15(i_io_forward_1_forwardData_15), .io_forward_1_matchInvalid(i_io_forward_1_matchInvalid), .io_forward_2_forwardMask_0(i_io_forward_2_forwardMask_0), .io_forward_2_forwardMask_1(i_io_forward_2_forwardMask_1), .io_forward_2_forwardMask_2(i_io_forward_2_forwardMask_2), .io_forward_2_forwardMask_3(i_io_forward_2_forwardMask_3), .io_forward_2_forwardMask_4(i_io_forward_2_forwardMask_4), .io_forward_2_forwardMask_5(i_io_forward_2_forwardMask_5), .io_forward_2_forwardMask_6(i_io_forward_2_forwardMask_6), .io_forward_2_forwardMask_7(i_io_forward_2_forwardMask_7), .io_forward_2_forwardMask_8(i_io_forward_2_forwardMask_8), .io_forward_2_forwardMask_9(i_io_forward_2_forwardMask_9), .io_forward_2_forwardMask_10(i_io_forward_2_forwardMask_10), .io_forward_2_forwardMask_11(i_io_forward_2_forwardMask_11), .io_forward_2_forwardMask_12(i_io_forward_2_forwardMask_12), .io_forward_2_forwardMask_13(i_io_forward_2_forwardMask_13), .io_forward_2_forwardMask_14(i_io_forward_2_forwardMask_14), .io_forward_2_forwardMask_15(i_io_forward_2_forwardMask_15), .io_forward_2_forwardData_0(i_io_forward_2_forwardData_0), .io_forward_2_forwardData_1(i_io_forward_2_forwardData_1), .io_forward_2_forwardData_2(i_io_forward_2_forwardData_2), .io_forward_2_forwardData_3(i_io_forward_2_forwardData_3), .io_forward_2_forwardData_4(i_io_forward_2_forwardData_4), .io_forward_2_forwardData_5(i_io_forward_2_forwardData_5), .io_forward_2_forwardData_6(i_io_forward_2_forwardData_6), .io_forward_2_forwardData_7(i_io_forward_2_forwardData_7), .io_forward_2_forwardData_8(i_io_forward_2_forwardData_8), .io_forward_2_forwardData_9(i_io_forward_2_forwardData_9), .io_forward_2_forwardData_10(i_io_forward_2_forwardData_10), .io_forward_2_forwardData_11(i_io_forward_2_forwardData_11), .io_forward_2_forwardData_12(i_io_forward_2_forwardData_12), .io_forward_2_forwardData_13(i_io_forward_2_forwardData_13), .io_forward_2_forwardData_14(i_io_forward_2_forwardData_14), .io_forward_2_forwardData_15(i_io_forward_2_forwardData_15), .io_forward_2_matchInvalid(i_io_forward_2_matchInvalid), .io_wfi_wfiSafe(i_io_wfi_wfiSafe), .io_busError_ecc_error_valid(i_io_busError_ecc_error_valid), .io_busError_ecc_error_bits(i_io_busError_ecc_error_bits));
  always @(negedge clk) begin
    if (rst) begin
      io_lsq_req_valid <= 1'b0;
      auto_client_out_d_valid <= 1'b0;
      io_flush_valid <= 1'b0;
      io_wfi_wfiReq <= 1'b0;
      io_forward_0_valid <= 1'b0;
      io_forward_1_valid <= 1'b0;
      io_forward_2_valid <= 1'b0;
    end else begin
      auto_client_out_a_ready <= ($urandom_range(0,3)!=0);
      io_enableOutstanding <= ($urandom_range(0,1));
      io_flush_valid <= ($urandom_range(0,31)==0);
      io_lsq_req_valid <= ($urandom_range(0,1));
      io_lsq_req_bits_cmd <= 5'($urandom_range(0,1));
      io_lsq_req_bits_addr <= {42'($urandom_range(0,3)), 6'($urandom)};
      io_lsq_req_bits_vaddr <= {44'($urandom_range(0,3)), 6'($urandom)};
      io_lsq_req_bits_data <= 64'({$urandom(), $urandom()});
      io_lsq_req_bits_mask <= $urandom_range(0,3)==0 ? 8'hff : $urandom_range(0,2)==0 ? (8'h3 << (4*$urandom_range(0,1))) : (8'h1 << $urandom_range(0,7));
      io_lsq_req_bits_id <= 7'($urandom);
      io_lsq_req_bits_nc <= $urandom_range(0,1);
      io_lsq_req_bits_memBackTypeMM <= $urandom_range(0,1);
      io_lsq_resp_ready <= ($urandom_range(0,2)!=0);
      io_forward_0_vaddr <= {44'($urandom_range(0,3)), 6'($urandom)};
      io_forward_0_paddr <= {42'($urandom_range(0,3)), 6'($urandom)};
      io_forward_0_valid <= ($urandom_range(0,1));
      io_forward_1_vaddr <= {44'($urandom_range(0,3)), 6'($urandom)};
      io_forward_1_paddr <= {42'($urandom_range(0,3)), 6'($urandom)};
      io_forward_1_valid <= ($urandom_range(0,1));
      io_forward_2_vaddr <= {44'($urandom_range(0,3)), 6'($urandom)};
      io_forward_2_paddr <= {42'($urandom_range(0,3)), 6'($urandom)};
      io_forward_2_valid <= ($urandom_range(0,1));
      io_wfi_wfiReq <= ($urandom_range(0,7)==0);
    end
  end

  // 在途记录：每个 source(0..3) 是否有未回的请求
  bit [3:0]  inflight_q;
  bit [3:0]  pend_isld;            // 该在途请求是否 load（需回读数据）
  int unsigned start_idx = 0;      // 轮转起点
  // 简单单拍回应：a fire 当拍即可在下一拍择一在途 source 回 d
  always @(negedge clk) begin
    if (rst) begin
      auto_client_out_d_valid         <= 1'b0;
      auto_client_out_d_bits_source   <= 2'h0;
      auto_client_out_d_bits_data     <= 64'h0;
      auto_client_out_d_bits_denied   <= 1'b0;
      auto_client_out_d_bits_corrupt  <= 1'b0;
      inflight_q                      <= 4'h0;
      pend_isld                       <= 4'h0;
    end else begin
      // 记录 golden a fire（a_valid & a_ready）→ 置该 source 在途
      if (g_auto_client_out_a_valid && auto_client_out_a_ready) begin
        inflight_q[g_auto_client_out_a_bits_source] <= 1'b1;
        pend_isld[g_auto_client_out_a_bits_source]  <= (g_auto_client_out_a_bits_opcode == 4'h4);
      end
      // 默认不发 d
      auto_client_out_d_valid <= 1'b0;
      // 随机择一在途 source 回 d（d.ready 在 Uncache 内恒 1，单拍完成）
      if (|inflight_q && ($urandom_range(0,1))) begin
        int unsigned k;
        bit hit;
        hit = 1'b0;
        for (k = 0; k < 4; k++) begin
          if (!hit && inflight_q[(start_idx+k)%4]) begin
            hit = 1'b1;
            auto_client_out_d_valid        <= 1'b1;
            auto_client_out_d_bits_source  <= 2'(((start_idx+k)%4));
            auto_client_out_d_bits_data    <= 64'({$urandom(), $urandom()});
            auto_client_out_d_bits_denied  <= ($urandom_range(0,7)==0);
            auto_client_out_d_bits_corrupt <= ($urandom_range(0,7)==0);
            inflight_q[(start_idx+k)%4]    <= 1'b0; // 这一 source 回完即清在途
          end
        end
        start_idx <= start_idx + 1; // 轮转起点，避免总回同一个
      end
    end
  end

  logic [2:0] fwd_v_q;
  always @(posedge clk) if (!rst) begin
    fwd_v_q[0] <= io_forward_0_valid;
    fwd_v_q[1] <= io_forward_1_valid;
    fwd_v_q[2] <= io_forward_2_valid;
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_auto_client_out_a_valid) && g_auto_client_out_a_valid !== i_auto_client_out_a_valid) begin errors++;
      if(errors<=60) $display("[%0t] auto_client_out_a_valid g=%h i=%h", $time, g_auto_client_out_a_valid, i_auto_client_out_a_valid); end
    if ((g_auto_client_out_a_valid) && !$isunknown(g_auto_client_out_a_bits_opcode) && g_auto_client_out_a_bits_opcode !== i_auto_client_out_a_bits_opcode) begin errors++;
      if(errors<=60) $display("[%0t] auto_client_out_a_bits_opcode g=%h i=%h", $time, g_auto_client_out_a_bits_opcode, i_auto_client_out_a_bits_opcode); end
    if ((g_auto_client_out_a_valid) && !$isunknown(g_auto_client_out_a_bits_size) && g_auto_client_out_a_bits_size !== i_auto_client_out_a_bits_size) begin errors++;
      if(errors<=60) $display("[%0t] auto_client_out_a_bits_size g=%h i=%h", $time, g_auto_client_out_a_bits_size, i_auto_client_out_a_bits_size); end
    if ((g_auto_client_out_a_valid) && !$isunknown(g_auto_client_out_a_bits_source) && g_auto_client_out_a_bits_source !== i_auto_client_out_a_bits_source) begin errors++;
      if(errors<=60) $display("[%0t] auto_client_out_a_bits_source g=%h i=%h", $time, g_auto_client_out_a_bits_source, i_auto_client_out_a_bits_source); end
    if ((g_auto_client_out_a_valid) && !$isunknown(g_auto_client_out_a_bits_address) && g_auto_client_out_a_bits_address !== i_auto_client_out_a_bits_address) begin errors++;
      if(errors<=60) $display("[%0t] auto_client_out_a_bits_address g=%h i=%h", $time, g_auto_client_out_a_bits_address, i_auto_client_out_a_bits_address); end
    if ((g_auto_client_out_a_valid) && !$isunknown(g_auto_client_out_a_bits_user_memPageType_NC) && g_auto_client_out_a_bits_user_memPageType_NC !== i_auto_client_out_a_bits_user_memPageType_NC) begin errors++;
      if(errors<=60) $display("[%0t] auto_client_out_a_bits_user_memPageType_NC g=%h i=%h", $time, g_auto_client_out_a_bits_user_memPageType_NC, i_auto_client_out_a_bits_user_memPageType_NC); end
    if ((g_auto_client_out_a_valid) && !$isunknown(g_auto_client_out_a_bits_user_memBackType_MM) && g_auto_client_out_a_bits_user_memBackType_MM !== i_auto_client_out_a_bits_user_memBackType_MM) begin errors++;
      if(errors<=60) $display("[%0t] auto_client_out_a_bits_user_memBackType_MM g=%h i=%h", $time, g_auto_client_out_a_bits_user_memBackType_MM, i_auto_client_out_a_bits_user_memBackType_MM); end
    if ((g_auto_client_out_a_valid) && !$isunknown(g_auto_client_out_a_bits_mask) && g_auto_client_out_a_bits_mask !== i_auto_client_out_a_bits_mask) begin errors++;
      if(errors<=60) $display("[%0t] auto_client_out_a_bits_mask g=%h i=%h", $time, g_auto_client_out_a_bits_mask, i_auto_client_out_a_bits_mask); end
    if ((g_auto_client_out_a_valid) && !$isunknown(g_auto_client_out_a_bits_data) && g_auto_client_out_a_bits_data !== i_auto_client_out_a_bits_data) begin errors++;
      if(errors<=60) $display("[%0t] auto_client_out_a_bits_data g=%h i=%h", $time, g_auto_client_out_a_bits_data, i_auto_client_out_a_bits_data); end
    if (!$isunknown(g_io_flush_empty) && g_io_flush_empty !== i_io_flush_empty) begin errors++;
      if(errors<=60) $display("[%0t] io_flush_empty g=%h i=%h", $time, g_io_flush_empty, i_io_flush_empty); end
    if (!$isunknown(g_io_lsq_req_ready) && g_io_lsq_req_ready !== i_io_lsq_req_ready) begin errors++;
      if(errors<=60) $display("[%0t] io_lsq_req_ready g=%h i=%h", $time, g_io_lsq_req_ready, i_io_lsq_req_ready); end
    if (!$isunknown(g_io_lsq_idResp_valid) && g_io_lsq_idResp_valid !== i_io_lsq_idResp_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_lsq_idResp_valid g=%h i=%h", $time, g_io_lsq_idResp_valid, i_io_lsq_idResp_valid); end
    if ((g_io_lsq_idResp_valid) && !$isunknown(g_io_lsq_idResp_bits_mid) && g_io_lsq_idResp_bits_mid !== i_io_lsq_idResp_bits_mid) begin errors++;
      if(errors<=60) $display("[%0t] io_lsq_idResp_bits_mid g=%h i=%h", $time, g_io_lsq_idResp_bits_mid, i_io_lsq_idResp_bits_mid); end
    if ((g_io_lsq_idResp_valid) && !$isunknown(g_io_lsq_idResp_bits_sid) && g_io_lsq_idResp_bits_sid !== i_io_lsq_idResp_bits_sid) begin errors++;
      if(errors<=60) $display("[%0t] io_lsq_idResp_bits_sid g=%h i=%h", $time, g_io_lsq_idResp_bits_sid, i_io_lsq_idResp_bits_sid); end
    if ((g_io_lsq_idResp_valid) && !$isunknown(g_io_lsq_idResp_bits_is2lq) && g_io_lsq_idResp_bits_is2lq !== i_io_lsq_idResp_bits_is2lq) begin errors++;
      if(errors<=60) $display("[%0t] io_lsq_idResp_bits_is2lq g=%h i=%h", $time, g_io_lsq_idResp_bits_is2lq, i_io_lsq_idResp_bits_is2lq); end
    if ((g_io_lsq_idResp_valid) && !$isunknown(g_io_lsq_idResp_bits_nc) && g_io_lsq_idResp_bits_nc !== i_io_lsq_idResp_bits_nc) begin errors++;
      if(errors<=60) $display("[%0t] io_lsq_idResp_bits_nc g=%h i=%h", $time, g_io_lsq_idResp_bits_nc, i_io_lsq_idResp_bits_nc); end
    if (!$isunknown(g_io_lsq_resp_valid) && g_io_lsq_resp_valid !== i_io_lsq_resp_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_lsq_resp_valid g=%h i=%h", $time, g_io_lsq_resp_valid, i_io_lsq_resp_valid); end
    if ((g_io_lsq_resp_valid) && !$isunknown(g_io_lsq_resp_bits_data) && g_io_lsq_resp_bits_data !== i_io_lsq_resp_bits_data) begin errors++;
      if(errors<=60) $display("[%0t] io_lsq_resp_bits_data g=%h i=%h", $time, g_io_lsq_resp_bits_data, i_io_lsq_resp_bits_data); end
    if ((g_io_lsq_resp_valid) && !$isunknown(g_io_lsq_resp_bits_id) && g_io_lsq_resp_bits_id !== i_io_lsq_resp_bits_id) begin errors++;
      if(errors<=60) $display("[%0t] io_lsq_resp_bits_id g=%h i=%h", $time, g_io_lsq_resp_bits_id, i_io_lsq_resp_bits_id); end
    if ((g_io_lsq_resp_valid) && !$isunknown(g_io_lsq_resp_bits_nc) && g_io_lsq_resp_bits_nc !== i_io_lsq_resp_bits_nc) begin errors++;
      if(errors<=60) $display("[%0t] io_lsq_resp_bits_nc g=%h i=%h", $time, g_io_lsq_resp_bits_nc, i_io_lsq_resp_bits_nc); end
    if ((g_io_lsq_resp_valid) && !$isunknown(g_io_lsq_resp_bits_is2lq) && g_io_lsq_resp_bits_is2lq !== i_io_lsq_resp_bits_is2lq) begin errors++;
      if(errors<=60) $display("[%0t] io_lsq_resp_bits_is2lq g=%h i=%h", $time, g_io_lsq_resp_bits_is2lq, i_io_lsq_resp_bits_is2lq); end
    if ((g_io_lsq_resp_valid) && !$isunknown(g_io_lsq_resp_bits_nderr) && g_io_lsq_resp_bits_nderr !== i_io_lsq_resp_bits_nderr) begin errors++;
      if(errors<=60) $display("[%0t] io_lsq_resp_bits_nderr g=%h i=%h", $time, g_io_lsq_resp_bits_nderr, i_io_lsq_resp_bits_nderr); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_0) && g_io_forward_0_forwardMask_0 !== i_io_forward_0_forwardMask_0) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardMask_0 g=%h i=%h", $time, g_io_forward_0_forwardMask_0, i_io_forward_0_forwardMask_0); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_1) && g_io_forward_0_forwardMask_1 !== i_io_forward_0_forwardMask_1) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardMask_1 g=%h i=%h", $time, g_io_forward_0_forwardMask_1, i_io_forward_0_forwardMask_1); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_2) && g_io_forward_0_forwardMask_2 !== i_io_forward_0_forwardMask_2) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardMask_2 g=%h i=%h", $time, g_io_forward_0_forwardMask_2, i_io_forward_0_forwardMask_2); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_3) && g_io_forward_0_forwardMask_3 !== i_io_forward_0_forwardMask_3) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardMask_3 g=%h i=%h", $time, g_io_forward_0_forwardMask_3, i_io_forward_0_forwardMask_3); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_4) && g_io_forward_0_forwardMask_4 !== i_io_forward_0_forwardMask_4) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardMask_4 g=%h i=%h", $time, g_io_forward_0_forwardMask_4, i_io_forward_0_forwardMask_4); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_5) && g_io_forward_0_forwardMask_5 !== i_io_forward_0_forwardMask_5) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardMask_5 g=%h i=%h", $time, g_io_forward_0_forwardMask_5, i_io_forward_0_forwardMask_5); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_6) && g_io_forward_0_forwardMask_6 !== i_io_forward_0_forwardMask_6) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardMask_6 g=%h i=%h", $time, g_io_forward_0_forwardMask_6, i_io_forward_0_forwardMask_6); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_7) && g_io_forward_0_forwardMask_7 !== i_io_forward_0_forwardMask_7) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardMask_7 g=%h i=%h", $time, g_io_forward_0_forwardMask_7, i_io_forward_0_forwardMask_7); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_8) && g_io_forward_0_forwardMask_8 !== i_io_forward_0_forwardMask_8) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardMask_8 g=%h i=%h", $time, g_io_forward_0_forwardMask_8, i_io_forward_0_forwardMask_8); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_9) && g_io_forward_0_forwardMask_9 !== i_io_forward_0_forwardMask_9) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardMask_9 g=%h i=%h", $time, g_io_forward_0_forwardMask_9, i_io_forward_0_forwardMask_9); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_10) && g_io_forward_0_forwardMask_10 !== i_io_forward_0_forwardMask_10) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardMask_10 g=%h i=%h", $time, g_io_forward_0_forwardMask_10, i_io_forward_0_forwardMask_10); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_11) && g_io_forward_0_forwardMask_11 !== i_io_forward_0_forwardMask_11) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardMask_11 g=%h i=%h", $time, g_io_forward_0_forwardMask_11, i_io_forward_0_forwardMask_11); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_12) && g_io_forward_0_forwardMask_12 !== i_io_forward_0_forwardMask_12) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardMask_12 g=%h i=%h", $time, g_io_forward_0_forwardMask_12, i_io_forward_0_forwardMask_12); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_13) && g_io_forward_0_forwardMask_13 !== i_io_forward_0_forwardMask_13) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardMask_13 g=%h i=%h", $time, g_io_forward_0_forwardMask_13, i_io_forward_0_forwardMask_13); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_14) && g_io_forward_0_forwardMask_14 !== i_io_forward_0_forwardMask_14) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardMask_14 g=%h i=%h", $time, g_io_forward_0_forwardMask_14, i_io_forward_0_forwardMask_14); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_15) && g_io_forward_0_forwardMask_15 !== i_io_forward_0_forwardMask_15) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardMask_15 g=%h i=%h", $time, g_io_forward_0_forwardMask_15, i_io_forward_0_forwardMask_15); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_0) && g_io_forward_0_forwardData_0 !== i_io_forward_0_forwardData_0) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardData_0 g=%h i=%h", $time, g_io_forward_0_forwardData_0, i_io_forward_0_forwardData_0); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_1) && g_io_forward_0_forwardData_1 !== i_io_forward_0_forwardData_1) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardData_1 g=%h i=%h", $time, g_io_forward_0_forwardData_1, i_io_forward_0_forwardData_1); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_2) && g_io_forward_0_forwardData_2 !== i_io_forward_0_forwardData_2) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardData_2 g=%h i=%h", $time, g_io_forward_0_forwardData_2, i_io_forward_0_forwardData_2); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_3) && g_io_forward_0_forwardData_3 !== i_io_forward_0_forwardData_3) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardData_3 g=%h i=%h", $time, g_io_forward_0_forwardData_3, i_io_forward_0_forwardData_3); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_4) && g_io_forward_0_forwardData_4 !== i_io_forward_0_forwardData_4) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardData_4 g=%h i=%h", $time, g_io_forward_0_forwardData_4, i_io_forward_0_forwardData_4); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_5) && g_io_forward_0_forwardData_5 !== i_io_forward_0_forwardData_5) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardData_5 g=%h i=%h", $time, g_io_forward_0_forwardData_5, i_io_forward_0_forwardData_5); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_6) && g_io_forward_0_forwardData_6 !== i_io_forward_0_forwardData_6) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardData_6 g=%h i=%h", $time, g_io_forward_0_forwardData_6, i_io_forward_0_forwardData_6); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_7) && g_io_forward_0_forwardData_7 !== i_io_forward_0_forwardData_7) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardData_7 g=%h i=%h", $time, g_io_forward_0_forwardData_7, i_io_forward_0_forwardData_7); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_8) && g_io_forward_0_forwardData_8 !== i_io_forward_0_forwardData_8) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardData_8 g=%h i=%h", $time, g_io_forward_0_forwardData_8, i_io_forward_0_forwardData_8); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_9) && g_io_forward_0_forwardData_9 !== i_io_forward_0_forwardData_9) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardData_9 g=%h i=%h", $time, g_io_forward_0_forwardData_9, i_io_forward_0_forwardData_9); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_10) && g_io_forward_0_forwardData_10 !== i_io_forward_0_forwardData_10) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardData_10 g=%h i=%h", $time, g_io_forward_0_forwardData_10, i_io_forward_0_forwardData_10); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_11) && g_io_forward_0_forwardData_11 !== i_io_forward_0_forwardData_11) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardData_11 g=%h i=%h", $time, g_io_forward_0_forwardData_11, i_io_forward_0_forwardData_11); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_12) && g_io_forward_0_forwardData_12 !== i_io_forward_0_forwardData_12) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardData_12 g=%h i=%h", $time, g_io_forward_0_forwardData_12, i_io_forward_0_forwardData_12); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_13) && g_io_forward_0_forwardData_13 !== i_io_forward_0_forwardData_13) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardData_13 g=%h i=%h", $time, g_io_forward_0_forwardData_13, i_io_forward_0_forwardData_13); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_14) && g_io_forward_0_forwardData_14 !== i_io_forward_0_forwardData_14) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardData_14 g=%h i=%h", $time, g_io_forward_0_forwardData_14, i_io_forward_0_forwardData_14); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_15) && g_io_forward_0_forwardData_15 !== i_io_forward_0_forwardData_15) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_forwardData_15 g=%h i=%h", $time, g_io_forward_0_forwardData_15, i_io_forward_0_forwardData_15); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_matchInvalid) && g_io_forward_0_matchInvalid !== i_io_forward_0_matchInvalid) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_0_matchInvalid g=%h i=%h", $time, g_io_forward_0_matchInvalid, i_io_forward_0_matchInvalid); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_0) && g_io_forward_1_forwardMask_0 !== i_io_forward_1_forwardMask_0) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardMask_0 g=%h i=%h", $time, g_io_forward_1_forwardMask_0, i_io_forward_1_forwardMask_0); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_1) && g_io_forward_1_forwardMask_1 !== i_io_forward_1_forwardMask_1) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardMask_1 g=%h i=%h", $time, g_io_forward_1_forwardMask_1, i_io_forward_1_forwardMask_1); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_2) && g_io_forward_1_forwardMask_2 !== i_io_forward_1_forwardMask_2) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardMask_2 g=%h i=%h", $time, g_io_forward_1_forwardMask_2, i_io_forward_1_forwardMask_2); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_3) && g_io_forward_1_forwardMask_3 !== i_io_forward_1_forwardMask_3) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardMask_3 g=%h i=%h", $time, g_io_forward_1_forwardMask_3, i_io_forward_1_forwardMask_3); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_4) && g_io_forward_1_forwardMask_4 !== i_io_forward_1_forwardMask_4) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardMask_4 g=%h i=%h", $time, g_io_forward_1_forwardMask_4, i_io_forward_1_forwardMask_4); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_5) && g_io_forward_1_forwardMask_5 !== i_io_forward_1_forwardMask_5) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardMask_5 g=%h i=%h", $time, g_io_forward_1_forwardMask_5, i_io_forward_1_forwardMask_5); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_6) && g_io_forward_1_forwardMask_6 !== i_io_forward_1_forwardMask_6) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardMask_6 g=%h i=%h", $time, g_io_forward_1_forwardMask_6, i_io_forward_1_forwardMask_6); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_7) && g_io_forward_1_forwardMask_7 !== i_io_forward_1_forwardMask_7) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardMask_7 g=%h i=%h", $time, g_io_forward_1_forwardMask_7, i_io_forward_1_forwardMask_7); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_8) && g_io_forward_1_forwardMask_8 !== i_io_forward_1_forwardMask_8) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardMask_8 g=%h i=%h", $time, g_io_forward_1_forwardMask_8, i_io_forward_1_forwardMask_8); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_9) && g_io_forward_1_forwardMask_9 !== i_io_forward_1_forwardMask_9) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardMask_9 g=%h i=%h", $time, g_io_forward_1_forwardMask_9, i_io_forward_1_forwardMask_9); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_10) && g_io_forward_1_forwardMask_10 !== i_io_forward_1_forwardMask_10) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardMask_10 g=%h i=%h", $time, g_io_forward_1_forwardMask_10, i_io_forward_1_forwardMask_10); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_11) && g_io_forward_1_forwardMask_11 !== i_io_forward_1_forwardMask_11) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardMask_11 g=%h i=%h", $time, g_io_forward_1_forwardMask_11, i_io_forward_1_forwardMask_11); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_12) && g_io_forward_1_forwardMask_12 !== i_io_forward_1_forwardMask_12) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardMask_12 g=%h i=%h", $time, g_io_forward_1_forwardMask_12, i_io_forward_1_forwardMask_12); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_13) && g_io_forward_1_forwardMask_13 !== i_io_forward_1_forwardMask_13) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardMask_13 g=%h i=%h", $time, g_io_forward_1_forwardMask_13, i_io_forward_1_forwardMask_13); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_14) && g_io_forward_1_forwardMask_14 !== i_io_forward_1_forwardMask_14) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardMask_14 g=%h i=%h", $time, g_io_forward_1_forwardMask_14, i_io_forward_1_forwardMask_14); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_15) && g_io_forward_1_forwardMask_15 !== i_io_forward_1_forwardMask_15) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardMask_15 g=%h i=%h", $time, g_io_forward_1_forwardMask_15, i_io_forward_1_forwardMask_15); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_0) && g_io_forward_1_forwardData_0 !== i_io_forward_1_forwardData_0) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardData_0 g=%h i=%h", $time, g_io_forward_1_forwardData_0, i_io_forward_1_forwardData_0); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_1) && g_io_forward_1_forwardData_1 !== i_io_forward_1_forwardData_1) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardData_1 g=%h i=%h", $time, g_io_forward_1_forwardData_1, i_io_forward_1_forwardData_1); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_2) && g_io_forward_1_forwardData_2 !== i_io_forward_1_forwardData_2) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardData_2 g=%h i=%h", $time, g_io_forward_1_forwardData_2, i_io_forward_1_forwardData_2); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_3) && g_io_forward_1_forwardData_3 !== i_io_forward_1_forwardData_3) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardData_3 g=%h i=%h", $time, g_io_forward_1_forwardData_3, i_io_forward_1_forwardData_3); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_4) && g_io_forward_1_forwardData_4 !== i_io_forward_1_forwardData_4) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardData_4 g=%h i=%h", $time, g_io_forward_1_forwardData_4, i_io_forward_1_forwardData_4); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_5) && g_io_forward_1_forwardData_5 !== i_io_forward_1_forwardData_5) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardData_5 g=%h i=%h", $time, g_io_forward_1_forwardData_5, i_io_forward_1_forwardData_5); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_6) && g_io_forward_1_forwardData_6 !== i_io_forward_1_forwardData_6) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardData_6 g=%h i=%h", $time, g_io_forward_1_forwardData_6, i_io_forward_1_forwardData_6); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_7) && g_io_forward_1_forwardData_7 !== i_io_forward_1_forwardData_7) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardData_7 g=%h i=%h", $time, g_io_forward_1_forwardData_7, i_io_forward_1_forwardData_7); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_8) && g_io_forward_1_forwardData_8 !== i_io_forward_1_forwardData_8) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardData_8 g=%h i=%h", $time, g_io_forward_1_forwardData_8, i_io_forward_1_forwardData_8); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_9) && g_io_forward_1_forwardData_9 !== i_io_forward_1_forwardData_9) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardData_9 g=%h i=%h", $time, g_io_forward_1_forwardData_9, i_io_forward_1_forwardData_9); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_10) && g_io_forward_1_forwardData_10 !== i_io_forward_1_forwardData_10) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardData_10 g=%h i=%h", $time, g_io_forward_1_forwardData_10, i_io_forward_1_forwardData_10); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_11) && g_io_forward_1_forwardData_11 !== i_io_forward_1_forwardData_11) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardData_11 g=%h i=%h", $time, g_io_forward_1_forwardData_11, i_io_forward_1_forwardData_11); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_12) && g_io_forward_1_forwardData_12 !== i_io_forward_1_forwardData_12) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardData_12 g=%h i=%h", $time, g_io_forward_1_forwardData_12, i_io_forward_1_forwardData_12); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_13) && g_io_forward_1_forwardData_13 !== i_io_forward_1_forwardData_13) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardData_13 g=%h i=%h", $time, g_io_forward_1_forwardData_13, i_io_forward_1_forwardData_13); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_14) && g_io_forward_1_forwardData_14 !== i_io_forward_1_forwardData_14) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardData_14 g=%h i=%h", $time, g_io_forward_1_forwardData_14, i_io_forward_1_forwardData_14); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_15) && g_io_forward_1_forwardData_15 !== i_io_forward_1_forwardData_15) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_forwardData_15 g=%h i=%h", $time, g_io_forward_1_forwardData_15, i_io_forward_1_forwardData_15); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_matchInvalid) && g_io_forward_1_matchInvalid !== i_io_forward_1_matchInvalid) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_1_matchInvalid g=%h i=%h", $time, g_io_forward_1_matchInvalid, i_io_forward_1_matchInvalid); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_0) && g_io_forward_2_forwardMask_0 !== i_io_forward_2_forwardMask_0) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardMask_0 g=%h i=%h", $time, g_io_forward_2_forwardMask_0, i_io_forward_2_forwardMask_0); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_1) && g_io_forward_2_forwardMask_1 !== i_io_forward_2_forwardMask_1) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardMask_1 g=%h i=%h", $time, g_io_forward_2_forwardMask_1, i_io_forward_2_forwardMask_1); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_2) && g_io_forward_2_forwardMask_2 !== i_io_forward_2_forwardMask_2) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardMask_2 g=%h i=%h", $time, g_io_forward_2_forwardMask_2, i_io_forward_2_forwardMask_2); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_3) && g_io_forward_2_forwardMask_3 !== i_io_forward_2_forwardMask_3) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardMask_3 g=%h i=%h", $time, g_io_forward_2_forwardMask_3, i_io_forward_2_forwardMask_3); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_4) && g_io_forward_2_forwardMask_4 !== i_io_forward_2_forwardMask_4) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardMask_4 g=%h i=%h", $time, g_io_forward_2_forwardMask_4, i_io_forward_2_forwardMask_4); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_5) && g_io_forward_2_forwardMask_5 !== i_io_forward_2_forwardMask_5) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardMask_5 g=%h i=%h", $time, g_io_forward_2_forwardMask_5, i_io_forward_2_forwardMask_5); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_6) && g_io_forward_2_forwardMask_6 !== i_io_forward_2_forwardMask_6) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardMask_6 g=%h i=%h", $time, g_io_forward_2_forwardMask_6, i_io_forward_2_forwardMask_6); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_7) && g_io_forward_2_forwardMask_7 !== i_io_forward_2_forwardMask_7) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardMask_7 g=%h i=%h", $time, g_io_forward_2_forwardMask_7, i_io_forward_2_forwardMask_7); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_8) && g_io_forward_2_forwardMask_8 !== i_io_forward_2_forwardMask_8) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardMask_8 g=%h i=%h", $time, g_io_forward_2_forwardMask_8, i_io_forward_2_forwardMask_8); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_9) && g_io_forward_2_forwardMask_9 !== i_io_forward_2_forwardMask_9) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardMask_9 g=%h i=%h", $time, g_io_forward_2_forwardMask_9, i_io_forward_2_forwardMask_9); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_10) && g_io_forward_2_forwardMask_10 !== i_io_forward_2_forwardMask_10) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardMask_10 g=%h i=%h", $time, g_io_forward_2_forwardMask_10, i_io_forward_2_forwardMask_10); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_11) && g_io_forward_2_forwardMask_11 !== i_io_forward_2_forwardMask_11) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardMask_11 g=%h i=%h", $time, g_io_forward_2_forwardMask_11, i_io_forward_2_forwardMask_11); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_12) && g_io_forward_2_forwardMask_12 !== i_io_forward_2_forwardMask_12) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardMask_12 g=%h i=%h", $time, g_io_forward_2_forwardMask_12, i_io_forward_2_forwardMask_12); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_13) && g_io_forward_2_forwardMask_13 !== i_io_forward_2_forwardMask_13) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardMask_13 g=%h i=%h", $time, g_io_forward_2_forwardMask_13, i_io_forward_2_forwardMask_13); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_14) && g_io_forward_2_forwardMask_14 !== i_io_forward_2_forwardMask_14) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardMask_14 g=%h i=%h", $time, g_io_forward_2_forwardMask_14, i_io_forward_2_forwardMask_14); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_15) && g_io_forward_2_forwardMask_15 !== i_io_forward_2_forwardMask_15) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardMask_15 g=%h i=%h", $time, g_io_forward_2_forwardMask_15, i_io_forward_2_forwardMask_15); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_0) && g_io_forward_2_forwardData_0 !== i_io_forward_2_forwardData_0) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardData_0 g=%h i=%h", $time, g_io_forward_2_forwardData_0, i_io_forward_2_forwardData_0); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_1) && g_io_forward_2_forwardData_1 !== i_io_forward_2_forwardData_1) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardData_1 g=%h i=%h", $time, g_io_forward_2_forwardData_1, i_io_forward_2_forwardData_1); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_2) && g_io_forward_2_forwardData_2 !== i_io_forward_2_forwardData_2) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardData_2 g=%h i=%h", $time, g_io_forward_2_forwardData_2, i_io_forward_2_forwardData_2); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_3) && g_io_forward_2_forwardData_3 !== i_io_forward_2_forwardData_3) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardData_3 g=%h i=%h", $time, g_io_forward_2_forwardData_3, i_io_forward_2_forwardData_3); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_4) && g_io_forward_2_forwardData_4 !== i_io_forward_2_forwardData_4) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardData_4 g=%h i=%h", $time, g_io_forward_2_forwardData_4, i_io_forward_2_forwardData_4); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_5) && g_io_forward_2_forwardData_5 !== i_io_forward_2_forwardData_5) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardData_5 g=%h i=%h", $time, g_io_forward_2_forwardData_5, i_io_forward_2_forwardData_5); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_6) && g_io_forward_2_forwardData_6 !== i_io_forward_2_forwardData_6) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardData_6 g=%h i=%h", $time, g_io_forward_2_forwardData_6, i_io_forward_2_forwardData_6); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_7) && g_io_forward_2_forwardData_7 !== i_io_forward_2_forwardData_7) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardData_7 g=%h i=%h", $time, g_io_forward_2_forwardData_7, i_io_forward_2_forwardData_7); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_8) && g_io_forward_2_forwardData_8 !== i_io_forward_2_forwardData_8) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardData_8 g=%h i=%h", $time, g_io_forward_2_forwardData_8, i_io_forward_2_forwardData_8); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_9) && g_io_forward_2_forwardData_9 !== i_io_forward_2_forwardData_9) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardData_9 g=%h i=%h", $time, g_io_forward_2_forwardData_9, i_io_forward_2_forwardData_9); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_10) && g_io_forward_2_forwardData_10 !== i_io_forward_2_forwardData_10) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardData_10 g=%h i=%h", $time, g_io_forward_2_forwardData_10, i_io_forward_2_forwardData_10); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_11) && g_io_forward_2_forwardData_11 !== i_io_forward_2_forwardData_11) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardData_11 g=%h i=%h", $time, g_io_forward_2_forwardData_11, i_io_forward_2_forwardData_11); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_12) && g_io_forward_2_forwardData_12 !== i_io_forward_2_forwardData_12) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardData_12 g=%h i=%h", $time, g_io_forward_2_forwardData_12, i_io_forward_2_forwardData_12); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_13) && g_io_forward_2_forwardData_13 !== i_io_forward_2_forwardData_13) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardData_13 g=%h i=%h", $time, g_io_forward_2_forwardData_13, i_io_forward_2_forwardData_13); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_14) && g_io_forward_2_forwardData_14 !== i_io_forward_2_forwardData_14) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardData_14 g=%h i=%h", $time, g_io_forward_2_forwardData_14, i_io_forward_2_forwardData_14); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_15) && g_io_forward_2_forwardData_15 !== i_io_forward_2_forwardData_15) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_forwardData_15 g=%h i=%h", $time, g_io_forward_2_forwardData_15, i_io_forward_2_forwardData_15); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_matchInvalid) && g_io_forward_2_matchInvalid !== i_io_forward_2_matchInvalid) begin errors++;
      if(errors<=60) $display("[%0t] io_forward_2_matchInvalid g=%h i=%h", $time, g_io_forward_2_matchInvalid, i_io_forward_2_matchInvalid); end
    if (!$isunknown(g_io_wfi_wfiSafe) && g_io_wfi_wfiSafe !== i_io_wfi_wfiSafe) begin errors++;
      if(errors<=60) $display("[%0t] io_wfi_wfiSafe g=%h i=%h", $time, g_io_wfi_wfiSafe, i_io_wfi_wfiSafe); end
    if (!$isunknown(g_io_busError_ecc_error_valid) && g_io_busError_ecc_error_valid !== i_io_busError_ecc_error_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_busError_ecc_error_valid g=%h i=%h", $time, g_io_busError_ecc_error_valid, i_io_busError_ecc_error_valid); end
    if ((g_io_busError_ecc_error_valid) && !$isunknown(g_io_busError_ecc_error_bits) && g_io_busError_ecc_error_bits !== i_io_busError_ecc_error_bits) begin errors++;
      if(errors<=60) $display("[%0t] io_busError_ecc_error_bits g=%h i=%h", $time, g_io_busError_ecc_error_bits, i_io_busError_ecc_error_bits); end
  end
  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule

// -----------------------------------------------------------------------------
//  golden Uncache 内含两个 difftest 观测探针实例（DelayReg_21 / DummyDPICWrapper_71），
//  它们只是把在途 store 的 commit 打拍/上报给 difftest 框架，是纯输出观测，不回灌
//  DUT 逻辑，也不在等价比对端口集里。UT 环境不带 difftest 库，这里给最小空壳桩，
//  令 golden 能 elaborate；桩的输出恒 0（不参与 tb 的 g/i 逐拍比对）。
// -----------------------------------------------------------------------------
module DelayReg_21 (
  input        clock,
  input        reset,
  input        i_valid,
  input [63:0] i_addr,
  input [7:0]  i_data_0, i_data_1, i_data_2, i_data_3,
  input [7:0]  i_data_4, i_data_5, i_data_6, i_data_7,
  input [7:0]  i_mask,
  input [7:0]  i_coreid,
  output       o_valid,
  output [63:0] o_addr,
  output [7:0] o_data_0, o_data_1, o_data_2, o_data_3,
  output [7:0] o_data_4, o_data_5, o_data_6, o_data_7,
  output [7:0] o_mask,
  output [7:0] o_coreid
);
  assign o_valid  = 1'b0;
  assign o_addr   = 64'h0;
  assign o_data_0 = 8'h0; assign o_data_1 = 8'h0; assign o_data_2 = 8'h0; assign o_data_3 = 8'h0;
  assign o_data_4 = 8'h0; assign o_data_5 = 8'h0; assign o_data_6 = 8'h0; assign o_data_7 = 8'h0;
  assign o_mask   = 8'h0;
  assign o_coreid = 8'h0;
endmodule

module DummyDPICWrapper_71 (
  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [63:0] io_bits_addr,
  input [7:0]  io_bits_data_0, io_bits_data_1, io_bits_data_2, io_bits_data_3,
  input [7:0]  io_bits_data_4, io_bits_data_5, io_bits_data_6, io_bits_data_7,
  input [7:0]  io_bits_mask,
  input [7:0]  io_bits_coreid
);
endmodule
