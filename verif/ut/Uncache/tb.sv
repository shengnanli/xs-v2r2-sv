// =============================================================================
// tb —— Uncache UT：golden Uncache 与重写件 Uncache_xs 双例化，同激励逐拍比全部输出。
//
// 激励（每拍随机，按"阶段"切换偏好，每 2000 拍换一次阶段）：
//   · LSQ 请求：地址从块池子里取（多数阶段只用 2~6 个块（让同块合并/拒收/waitSame 频繁发生），
//     vaddr 与 paddr 按池子成对映射，偶尔给不成对的 vaddr（制造前递 v/p 失配）；
//     掩码多为自然对齐的 1/2/4/8 字节，偶尔任意；cmd 以读/写为主，偶尔其他编码。
//   · TileLink A ready 随机；D 通道由一个"合法从设备"模型驱动：记下 golden 发出的
//     source，随机延迟后逐个回 D（数据随机，denied/corrupt 小概率）。
//   · LSQ resp ready、enableOutstanding、flush、wfiReq 随阶段随机；3 条前递流水随机查询。
//   · 约 1/20000 的单拍异步复位（从设备模型一起清空）。
// 比对：每拍输入稳定后比较全部输出端口（GENERATED 区的 compare_outputs）。
// 覆盖（探 golden 内部线计数，写进 PASS 判据，任一为 0 即判失败）：见 report()。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0; always #5 clk = ~clk;
  logic rst;
  longint errors = 0, checks = 0;

  `define CMP(g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 40) $display("[%0t] MISMATCH %s golden=%h impl=%h", $time, nm, (g), (i)); \
    end end

  // BEGIN GENERATED(uncache_tb_dut)
  // 由 scripts/gen_uncache.py 生成，勿手改：端口线声明、双例化、逐端口比较。
  logic          auto_client_out_a_ready;
  logic          g_auto_client_out_a_valid, i_auto_client_out_a_valid;
  logic [3:0]    g_auto_client_out_a_bits_opcode, i_auto_client_out_a_bits_opcode;
  logic [1:0]    g_auto_client_out_a_bits_size, i_auto_client_out_a_bits_size;
  logic [3:0]    g_auto_client_out_a_bits_source, i_auto_client_out_a_bits_source;
  logic [47:0]   g_auto_client_out_a_bits_address, i_auto_client_out_a_bits_address;
  logic          g_auto_client_out_a_bits_user_memPageType_NC, i_auto_client_out_a_bits_user_memPageType_NC;
  logic          g_auto_client_out_a_bits_user_memBackType_MM, i_auto_client_out_a_bits_user_memBackType_MM;
  logic [7:0]    g_auto_client_out_a_bits_mask, i_auto_client_out_a_bits_mask;
  logic [63:0]   g_auto_client_out_a_bits_data, i_auto_client_out_a_bits_data;
  logic          auto_client_out_d_valid;
  logic [3:0]    auto_client_out_d_bits_source;
  logic          auto_client_out_d_bits_denied;
  logic [63:0]   auto_client_out_d_bits_data;
  logic          auto_client_out_d_bits_corrupt;
  logic [5:0]    io_hartId;
  logic          io_enableOutstanding;
  logic          io_flush_valid;
  logic          g_io_flush_empty, i_io_flush_empty;
  logic          g_io_lsq_req_ready, i_io_lsq_req_ready;
  logic          io_lsq_req_valid;
  logic [4:0]    io_lsq_req_bits_cmd;
  logic [47:0]   io_lsq_req_bits_addr;
  logic [49:0]   io_lsq_req_bits_vaddr;
  logic [63:0]   io_lsq_req_bits_data;
  logic [7:0]    io_lsq_req_bits_mask;
  logic [6:0]    io_lsq_req_bits_id;
  logic          io_lsq_req_bits_nc;
  logic          io_lsq_req_bits_memBackTypeMM;
  logic          g_io_lsq_idResp_valid, i_io_lsq_idResp_valid;
  logic [6:0]    g_io_lsq_idResp_bits_mid, i_io_lsq_idResp_bits_mid;
  logic [3:0]    g_io_lsq_idResp_bits_sid, i_io_lsq_idResp_bits_sid;
  logic          g_io_lsq_idResp_bits_is2lq, i_io_lsq_idResp_bits_is2lq;
  logic          g_io_lsq_idResp_bits_nc, i_io_lsq_idResp_bits_nc;
  logic          io_lsq_resp_ready;
  logic          g_io_lsq_resp_valid, i_io_lsq_resp_valid;
  logic [63:0]   g_io_lsq_resp_bits_data, i_io_lsq_resp_bits_data;
  logic [3:0]    g_io_lsq_resp_bits_id, i_io_lsq_resp_bits_id;
  logic          g_io_lsq_resp_bits_nc, i_io_lsq_resp_bits_nc;
  logic          g_io_lsq_resp_bits_is2lq, i_io_lsq_resp_bits_is2lq;
  logic          g_io_lsq_resp_bits_denied, i_io_lsq_resp_bits_denied;
  logic          g_io_lsq_resp_bits_corrupt, i_io_lsq_resp_bits_corrupt;
  logic [49:0]   io_forward_0_vaddr;
  logic [47:0]   io_forward_0_paddr;
  logic          io_forward_0_valid;
  logic          g_io_forward_0_forwardMask_0, i_io_forward_0_forwardMask_0;
  logic          g_io_forward_0_forwardMask_1, i_io_forward_0_forwardMask_1;
  logic          g_io_forward_0_forwardMask_2, i_io_forward_0_forwardMask_2;
  logic          g_io_forward_0_forwardMask_3, i_io_forward_0_forwardMask_3;
  logic          g_io_forward_0_forwardMask_4, i_io_forward_0_forwardMask_4;
  logic          g_io_forward_0_forwardMask_5, i_io_forward_0_forwardMask_5;
  logic          g_io_forward_0_forwardMask_6, i_io_forward_0_forwardMask_6;
  logic          g_io_forward_0_forwardMask_7, i_io_forward_0_forwardMask_7;
  logic          g_io_forward_0_forwardMask_8, i_io_forward_0_forwardMask_8;
  logic          g_io_forward_0_forwardMask_9, i_io_forward_0_forwardMask_9;
  logic          g_io_forward_0_forwardMask_10, i_io_forward_0_forwardMask_10;
  logic          g_io_forward_0_forwardMask_11, i_io_forward_0_forwardMask_11;
  logic          g_io_forward_0_forwardMask_12, i_io_forward_0_forwardMask_12;
  logic          g_io_forward_0_forwardMask_13, i_io_forward_0_forwardMask_13;
  logic          g_io_forward_0_forwardMask_14, i_io_forward_0_forwardMask_14;
  logic          g_io_forward_0_forwardMask_15, i_io_forward_0_forwardMask_15;
  logic [7:0]    g_io_forward_0_forwardData_0, i_io_forward_0_forwardData_0;
  logic [7:0]    g_io_forward_0_forwardData_1, i_io_forward_0_forwardData_1;
  logic [7:0]    g_io_forward_0_forwardData_2, i_io_forward_0_forwardData_2;
  logic [7:0]    g_io_forward_0_forwardData_3, i_io_forward_0_forwardData_3;
  logic [7:0]    g_io_forward_0_forwardData_4, i_io_forward_0_forwardData_4;
  logic [7:0]    g_io_forward_0_forwardData_5, i_io_forward_0_forwardData_5;
  logic [7:0]    g_io_forward_0_forwardData_6, i_io_forward_0_forwardData_6;
  logic [7:0]    g_io_forward_0_forwardData_7, i_io_forward_0_forwardData_7;
  logic [7:0]    g_io_forward_0_forwardData_8, i_io_forward_0_forwardData_8;
  logic [7:0]    g_io_forward_0_forwardData_9, i_io_forward_0_forwardData_9;
  logic [7:0]    g_io_forward_0_forwardData_10, i_io_forward_0_forwardData_10;
  logic [7:0]    g_io_forward_0_forwardData_11, i_io_forward_0_forwardData_11;
  logic [7:0]    g_io_forward_0_forwardData_12, i_io_forward_0_forwardData_12;
  logic [7:0]    g_io_forward_0_forwardData_13, i_io_forward_0_forwardData_13;
  logic [7:0]    g_io_forward_0_forwardData_14, i_io_forward_0_forwardData_14;
  logic [7:0]    g_io_forward_0_forwardData_15, i_io_forward_0_forwardData_15;
  logic          g_io_forward_0_matchInvalid, i_io_forward_0_matchInvalid;
  logic [49:0]   io_forward_1_vaddr;
  logic [47:0]   io_forward_1_paddr;
  logic          io_forward_1_valid;
  logic          g_io_forward_1_forwardMask_0, i_io_forward_1_forwardMask_0;
  logic          g_io_forward_1_forwardMask_1, i_io_forward_1_forwardMask_1;
  logic          g_io_forward_1_forwardMask_2, i_io_forward_1_forwardMask_2;
  logic          g_io_forward_1_forwardMask_3, i_io_forward_1_forwardMask_3;
  logic          g_io_forward_1_forwardMask_4, i_io_forward_1_forwardMask_4;
  logic          g_io_forward_1_forwardMask_5, i_io_forward_1_forwardMask_5;
  logic          g_io_forward_1_forwardMask_6, i_io_forward_1_forwardMask_6;
  logic          g_io_forward_1_forwardMask_7, i_io_forward_1_forwardMask_7;
  logic          g_io_forward_1_forwardMask_8, i_io_forward_1_forwardMask_8;
  logic          g_io_forward_1_forwardMask_9, i_io_forward_1_forwardMask_9;
  logic          g_io_forward_1_forwardMask_10, i_io_forward_1_forwardMask_10;
  logic          g_io_forward_1_forwardMask_11, i_io_forward_1_forwardMask_11;
  logic          g_io_forward_1_forwardMask_12, i_io_forward_1_forwardMask_12;
  logic          g_io_forward_1_forwardMask_13, i_io_forward_1_forwardMask_13;
  logic          g_io_forward_1_forwardMask_14, i_io_forward_1_forwardMask_14;
  logic          g_io_forward_1_forwardMask_15, i_io_forward_1_forwardMask_15;
  logic [7:0]    g_io_forward_1_forwardData_0, i_io_forward_1_forwardData_0;
  logic [7:0]    g_io_forward_1_forwardData_1, i_io_forward_1_forwardData_1;
  logic [7:0]    g_io_forward_1_forwardData_2, i_io_forward_1_forwardData_2;
  logic [7:0]    g_io_forward_1_forwardData_3, i_io_forward_1_forwardData_3;
  logic [7:0]    g_io_forward_1_forwardData_4, i_io_forward_1_forwardData_4;
  logic [7:0]    g_io_forward_1_forwardData_5, i_io_forward_1_forwardData_5;
  logic [7:0]    g_io_forward_1_forwardData_6, i_io_forward_1_forwardData_6;
  logic [7:0]    g_io_forward_1_forwardData_7, i_io_forward_1_forwardData_7;
  logic [7:0]    g_io_forward_1_forwardData_8, i_io_forward_1_forwardData_8;
  logic [7:0]    g_io_forward_1_forwardData_9, i_io_forward_1_forwardData_9;
  logic [7:0]    g_io_forward_1_forwardData_10, i_io_forward_1_forwardData_10;
  logic [7:0]    g_io_forward_1_forwardData_11, i_io_forward_1_forwardData_11;
  logic [7:0]    g_io_forward_1_forwardData_12, i_io_forward_1_forwardData_12;
  logic [7:0]    g_io_forward_1_forwardData_13, i_io_forward_1_forwardData_13;
  logic [7:0]    g_io_forward_1_forwardData_14, i_io_forward_1_forwardData_14;
  logic [7:0]    g_io_forward_1_forwardData_15, i_io_forward_1_forwardData_15;
  logic          g_io_forward_1_matchInvalid, i_io_forward_1_matchInvalid;
  logic [49:0]   io_forward_2_vaddr;
  logic [47:0]   io_forward_2_paddr;
  logic          io_forward_2_valid;
  logic          g_io_forward_2_forwardMask_0, i_io_forward_2_forwardMask_0;
  logic          g_io_forward_2_forwardMask_1, i_io_forward_2_forwardMask_1;
  logic          g_io_forward_2_forwardMask_2, i_io_forward_2_forwardMask_2;
  logic          g_io_forward_2_forwardMask_3, i_io_forward_2_forwardMask_3;
  logic          g_io_forward_2_forwardMask_4, i_io_forward_2_forwardMask_4;
  logic          g_io_forward_2_forwardMask_5, i_io_forward_2_forwardMask_5;
  logic          g_io_forward_2_forwardMask_6, i_io_forward_2_forwardMask_6;
  logic          g_io_forward_2_forwardMask_7, i_io_forward_2_forwardMask_7;
  logic          g_io_forward_2_forwardMask_8, i_io_forward_2_forwardMask_8;
  logic          g_io_forward_2_forwardMask_9, i_io_forward_2_forwardMask_9;
  logic          g_io_forward_2_forwardMask_10, i_io_forward_2_forwardMask_10;
  logic          g_io_forward_2_forwardMask_11, i_io_forward_2_forwardMask_11;
  logic          g_io_forward_2_forwardMask_12, i_io_forward_2_forwardMask_12;
  logic          g_io_forward_2_forwardMask_13, i_io_forward_2_forwardMask_13;
  logic          g_io_forward_2_forwardMask_14, i_io_forward_2_forwardMask_14;
  logic          g_io_forward_2_forwardMask_15, i_io_forward_2_forwardMask_15;
  logic [7:0]    g_io_forward_2_forwardData_0, i_io_forward_2_forwardData_0;
  logic [7:0]    g_io_forward_2_forwardData_1, i_io_forward_2_forwardData_1;
  logic [7:0]    g_io_forward_2_forwardData_2, i_io_forward_2_forwardData_2;
  logic [7:0]    g_io_forward_2_forwardData_3, i_io_forward_2_forwardData_3;
  logic [7:0]    g_io_forward_2_forwardData_4, i_io_forward_2_forwardData_4;
  logic [7:0]    g_io_forward_2_forwardData_5, i_io_forward_2_forwardData_5;
  logic [7:0]    g_io_forward_2_forwardData_6, i_io_forward_2_forwardData_6;
  logic [7:0]    g_io_forward_2_forwardData_7, i_io_forward_2_forwardData_7;
  logic [7:0]    g_io_forward_2_forwardData_8, i_io_forward_2_forwardData_8;
  logic [7:0]    g_io_forward_2_forwardData_9, i_io_forward_2_forwardData_9;
  logic [7:0]    g_io_forward_2_forwardData_10, i_io_forward_2_forwardData_10;
  logic [7:0]    g_io_forward_2_forwardData_11, i_io_forward_2_forwardData_11;
  logic [7:0]    g_io_forward_2_forwardData_12, i_io_forward_2_forwardData_12;
  logic [7:0]    g_io_forward_2_forwardData_13, i_io_forward_2_forwardData_13;
  logic [7:0]    g_io_forward_2_forwardData_14, i_io_forward_2_forwardData_14;
  logic [7:0]    g_io_forward_2_forwardData_15, i_io_forward_2_forwardData_15;
  logic          g_io_forward_2_matchInvalid, i_io_forward_2_matchInvalid;
  logic          io_wfi_wfiReq;
  logic          g_io_wfi_wfiSafe, i_io_wfi_wfiSafe;
  logic          g_io_busError_ecc_error_valid, i_io_busError_ecc_error_valid;
  logic [47:0]   g_io_busError_ecc_error_bits, i_io_busError_ecc_error_bits;
  logic [152:0]  g_gatewayIn_packed_42_bore, i_gatewayIn_packed_42_bore;
  Uncache u_g (
    .clock (clk),
    .reset (rst),
    .auto_client_out_a_ready (auto_client_out_a_ready),
    .auto_client_out_a_valid (g_auto_client_out_a_valid),
    .auto_client_out_a_bits_opcode (g_auto_client_out_a_bits_opcode),
    .auto_client_out_a_bits_size (g_auto_client_out_a_bits_size),
    .auto_client_out_a_bits_source (g_auto_client_out_a_bits_source),
    .auto_client_out_a_bits_address (g_auto_client_out_a_bits_address),
    .auto_client_out_a_bits_user_memPageType_NC (g_auto_client_out_a_bits_user_memPageType_NC),
    .auto_client_out_a_bits_user_memBackType_MM (g_auto_client_out_a_bits_user_memBackType_MM),
    .auto_client_out_a_bits_mask (g_auto_client_out_a_bits_mask),
    .auto_client_out_a_bits_data (g_auto_client_out_a_bits_data),
    .auto_client_out_d_valid (auto_client_out_d_valid),
    .auto_client_out_d_bits_source (auto_client_out_d_bits_source),
    .auto_client_out_d_bits_denied (auto_client_out_d_bits_denied),
    .auto_client_out_d_bits_data (auto_client_out_d_bits_data),
    .auto_client_out_d_bits_corrupt (auto_client_out_d_bits_corrupt),
    .io_hartId (io_hartId),
    .io_enableOutstanding (io_enableOutstanding),
    .io_flush_valid (io_flush_valid),
    .io_flush_empty (g_io_flush_empty),
    .io_lsq_req_ready (g_io_lsq_req_ready),
    .io_lsq_req_valid (io_lsq_req_valid),
    .io_lsq_req_bits_cmd (io_lsq_req_bits_cmd),
    .io_lsq_req_bits_addr (io_lsq_req_bits_addr),
    .io_lsq_req_bits_vaddr (io_lsq_req_bits_vaddr),
    .io_lsq_req_bits_data (io_lsq_req_bits_data),
    .io_lsq_req_bits_mask (io_lsq_req_bits_mask),
    .io_lsq_req_bits_id (io_lsq_req_bits_id),
    .io_lsq_req_bits_nc (io_lsq_req_bits_nc),
    .io_lsq_req_bits_memBackTypeMM (io_lsq_req_bits_memBackTypeMM),
    .io_lsq_idResp_valid (g_io_lsq_idResp_valid),
    .io_lsq_idResp_bits_mid (g_io_lsq_idResp_bits_mid),
    .io_lsq_idResp_bits_sid (g_io_lsq_idResp_bits_sid),
    .io_lsq_idResp_bits_is2lq (g_io_lsq_idResp_bits_is2lq),
    .io_lsq_idResp_bits_nc (g_io_lsq_idResp_bits_nc),
    .io_lsq_resp_ready (io_lsq_resp_ready),
    .io_lsq_resp_valid (g_io_lsq_resp_valid),
    .io_lsq_resp_bits_data (g_io_lsq_resp_bits_data),
    .io_lsq_resp_bits_id (g_io_lsq_resp_bits_id),
    .io_lsq_resp_bits_nc (g_io_lsq_resp_bits_nc),
    .io_lsq_resp_bits_is2lq (g_io_lsq_resp_bits_is2lq),
    .io_lsq_resp_bits_denied (g_io_lsq_resp_bits_denied),
    .io_lsq_resp_bits_corrupt (g_io_lsq_resp_bits_corrupt),
    .io_forward_0_vaddr (io_forward_0_vaddr),
    .io_forward_0_paddr (io_forward_0_paddr),
    .io_forward_0_valid (io_forward_0_valid),
    .io_forward_0_forwardMask_0 (g_io_forward_0_forwardMask_0),
    .io_forward_0_forwardMask_1 (g_io_forward_0_forwardMask_1),
    .io_forward_0_forwardMask_2 (g_io_forward_0_forwardMask_2),
    .io_forward_0_forwardMask_3 (g_io_forward_0_forwardMask_3),
    .io_forward_0_forwardMask_4 (g_io_forward_0_forwardMask_4),
    .io_forward_0_forwardMask_5 (g_io_forward_0_forwardMask_5),
    .io_forward_0_forwardMask_6 (g_io_forward_0_forwardMask_6),
    .io_forward_0_forwardMask_7 (g_io_forward_0_forwardMask_7),
    .io_forward_0_forwardMask_8 (g_io_forward_0_forwardMask_8),
    .io_forward_0_forwardMask_9 (g_io_forward_0_forwardMask_9),
    .io_forward_0_forwardMask_10 (g_io_forward_0_forwardMask_10),
    .io_forward_0_forwardMask_11 (g_io_forward_0_forwardMask_11),
    .io_forward_0_forwardMask_12 (g_io_forward_0_forwardMask_12),
    .io_forward_0_forwardMask_13 (g_io_forward_0_forwardMask_13),
    .io_forward_0_forwardMask_14 (g_io_forward_0_forwardMask_14),
    .io_forward_0_forwardMask_15 (g_io_forward_0_forwardMask_15),
    .io_forward_0_forwardData_0 (g_io_forward_0_forwardData_0),
    .io_forward_0_forwardData_1 (g_io_forward_0_forwardData_1),
    .io_forward_0_forwardData_2 (g_io_forward_0_forwardData_2),
    .io_forward_0_forwardData_3 (g_io_forward_0_forwardData_3),
    .io_forward_0_forwardData_4 (g_io_forward_0_forwardData_4),
    .io_forward_0_forwardData_5 (g_io_forward_0_forwardData_5),
    .io_forward_0_forwardData_6 (g_io_forward_0_forwardData_6),
    .io_forward_0_forwardData_7 (g_io_forward_0_forwardData_7),
    .io_forward_0_forwardData_8 (g_io_forward_0_forwardData_8),
    .io_forward_0_forwardData_9 (g_io_forward_0_forwardData_9),
    .io_forward_0_forwardData_10 (g_io_forward_0_forwardData_10),
    .io_forward_0_forwardData_11 (g_io_forward_0_forwardData_11),
    .io_forward_0_forwardData_12 (g_io_forward_0_forwardData_12),
    .io_forward_0_forwardData_13 (g_io_forward_0_forwardData_13),
    .io_forward_0_forwardData_14 (g_io_forward_0_forwardData_14),
    .io_forward_0_forwardData_15 (g_io_forward_0_forwardData_15),
    .io_forward_0_matchInvalid (g_io_forward_0_matchInvalid),
    .io_forward_1_vaddr (io_forward_1_vaddr),
    .io_forward_1_paddr (io_forward_1_paddr),
    .io_forward_1_valid (io_forward_1_valid),
    .io_forward_1_forwardMask_0 (g_io_forward_1_forwardMask_0),
    .io_forward_1_forwardMask_1 (g_io_forward_1_forwardMask_1),
    .io_forward_1_forwardMask_2 (g_io_forward_1_forwardMask_2),
    .io_forward_1_forwardMask_3 (g_io_forward_1_forwardMask_3),
    .io_forward_1_forwardMask_4 (g_io_forward_1_forwardMask_4),
    .io_forward_1_forwardMask_5 (g_io_forward_1_forwardMask_5),
    .io_forward_1_forwardMask_6 (g_io_forward_1_forwardMask_6),
    .io_forward_1_forwardMask_7 (g_io_forward_1_forwardMask_7),
    .io_forward_1_forwardMask_8 (g_io_forward_1_forwardMask_8),
    .io_forward_1_forwardMask_9 (g_io_forward_1_forwardMask_9),
    .io_forward_1_forwardMask_10 (g_io_forward_1_forwardMask_10),
    .io_forward_1_forwardMask_11 (g_io_forward_1_forwardMask_11),
    .io_forward_1_forwardMask_12 (g_io_forward_1_forwardMask_12),
    .io_forward_1_forwardMask_13 (g_io_forward_1_forwardMask_13),
    .io_forward_1_forwardMask_14 (g_io_forward_1_forwardMask_14),
    .io_forward_1_forwardMask_15 (g_io_forward_1_forwardMask_15),
    .io_forward_1_forwardData_0 (g_io_forward_1_forwardData_0),
    .io_forward_1_forwardData_1 (g_io_forward_1_forwardData_1),
    .io_forward_1_forwardData_2 (g_io_forward_1_forwardData_2),
    .io_forward_1_forwardData_3 (g_io_forward_1_forwardData_3),
    .io_forward_1_forwardData_4 (g_io_forward_1_forwardData_4),
    .io_forward_1_forwardData_5 (g_io_forward_1_forwardData_5),
    .io_forward_1_forwardData_6 (g_io_forward_1_forwardData_6),
    .io_forward_1_forwardData_7 (g_io_forward_1_forwardData_7),
    .io_forward_1_forwardData_8 (g_io_forward_1_forwardData_8),
    .io_forward_1_forwardData_9 (g_io_forward_1_forwardData_9),
    .io_forward_1_forwardData_10 (g_io_forward_1_forwardData_10),
    .io_forward_1_forwardData_11 (g_io_forward_1_forwardData_11),
    .io_forward_1_forwardData_12 (g_io_forward_1_forwardData_12),
    .io_forward_1_forwardData_13 (g_io_forward_1_forwardData_13),
    .io_forward_1_forwardData_14 (g_io_forward_1_forwardData_14),
    .io_forward_1_forwardData_15 (g_io_forward_1_forwardData_15),
    .io_forward_1_matchInvalid (g_io_forward_1_matchInvalid),
    .io_forward_2_vaddr (io_forward_2_vaddr),
    .io_forward_2_paddr (io_forward_2_paddr),
    .io_forward_2_valid (io_forward_2_valid),
    .io_forward_2_forwardMask_0 (g_io_forward_2_forwardMask_0),
    .io_forward_2_forwardMask_1 (g_io_forward_2_forwardMask_1),
    .io_forward_2_forwardMask_2 (g_io_forward_2_forwardMask_2),
    .io_forward_2_forwardMask_3 (g_io_forward_2_forwardMask_3),
    .io_forward_2_forwardMask_4 (g_io_forward_2_forwardMask_4),
    .io_forward_2_forwardMask_5 (g_io_forward_2_forwardMask_5),
    .io_forward_2_forwardMask_6 (g_io_forward_2_forwardMask_6),
    .io_forward_2_forwardMask_7 (g_io_forward_2_forwardMask_7),
    .io_forward_2_forwardMask_8 (g_io_forward_2_forwardMask_8),
    .io_forward_2_forwardMask_9 (g_io_forward_2_forwardMask_9),
    .io_forward_2_forwardMask_10 (g_io_forward_2_forwardMask_10),
    .io_forward_2_forwardMask_11 (g_io_forward_2_forwardMask_11),
    .io_forward_2_forwardMask_12 (g_io_forward_2_forwardMask_12),
    .io_forward_2_forwardMask_13 (g_io_forward_2_forwardMask_13),
    .io_forward_2_forwardMask_14 (g_io_forward_2_forwardMask_14),
    .io_forward_2_forwardMask_15 (g_io_forward_2_forwardMask_15),
    .io_forward_2_forwardData_0 (g_io_forward_2_forwardData_0),
    .io_forward_2_forwardData_1 (g_io_forward_2_forwardData_1),
    .io_forward_2_forwardData_2 (g_io_forward_2_forwardData_2),
    .io_forward_2_forwardData_3 (g_io_forward_2_forwardData_3),
    .io_forward_2_forwardData_4 (g_io_forward_2_forwardData_4),
    .io_forward_2_forwardData_5 (g_io_forward_2_forwardData_5),
    .io_forward_2_forwardData_6 (g_io_forward_2_forwardData_6),
    .io_forward_2_forwardData_7 (g_io_forward_2_forwardData_7),
    .io_forward_2_forwardData_8 (g_io_forward_2_forwardData_8),
    .io_forward_2_forwardData_9 (g_io_forward_2_forwardData_9),
    .io_forward_2_forwardData_10 (g_io_forward_2_forwardData_10),
    .io_forward_2_forwardData_11 (g_io_forward_2_forwardData_11),
    .io_forward_2_forwardData_12 (g_io_forward_2_forwardData_12),
    .io_forward_2_forwardData_13 (g_io_forward_2_forwardData_13),
    .io_forward_2_forwardData_14 (g_io_forward_2_forwardData_14),
    .io_forward_2_forwardData_15 (g_io_forward_2_forwardData_15),
    .io_forward_2_matchInvalid (g_io_forward_2_matchInvalid),
    .io_wfi_wfiReq (io_wfi_wfiReq),
    .io_wfi_wfiSafe (g_io_wfi_wfiSafe),
    .io_busError_ecc_error_valid (g_io_busError_ecc_error_valid),
    .io_busError_ecc_error_bits (g_io_busError_ecc_error_bits),
    .gatewayIn_packed_42_bore (g_gatewayIn_packed_42_bore)
  );
  Uncache_xs u_i (
    .clock (clk),
    .reset (rst),
    .auto_client_out_a_ready (auto_client_out_a_ready),
    .auto_client_out_a_valid (i_auto_client_out_a_valid),
    .auto_client_out_a_bits_opcode (i_auto_client_out_a_bits_opcode),
    .auto_client_out_a_bits_size (i_auto_client_out_a_bits_size),
    .auto_client_out_a_bits_source (i_auto_client_out_a_bits_source),
    .auto_client_out_a_bits_address (i_auto_client_out_a_bits_address),
    .auto_client_out_a_bits_user_memPageType_NC (i_auto_client_out_a_bits_user_memPageType_NC),
    .auto_client_out_a_bits_user_memBackType_MM (i_auto_client_out_a_bits_user_memBackType_MM),
    .auto_client_out_a_bits_mask (i_auto_client_out_a_bits_mask),
    .auto_client_out_a_bits_data (i_auto_client_out_a_bits_data),
    .auto_client_out_d_valid (auto_client_out_d_valid),
    .auto_client_out_d_bits_source (auto_client_out_d_bits_source),
    .auto_client_out_d_bits_denied (auto_client_out_d_bits_denied),
    .auto_client_out_d_bits_data (auto_client_out_d_bits_data),
    .auto_client_out_d_bits_corrupt (auto_client_out_d_bits_corrupt),
    .io_hartId (io_hartId),
    .io_enableOutstanding (io_enableOutstanding),
    .io_flush_valid (io_flush_valid),
    .io_flush_empty (i_io_flush_empty),
    .io_lsq_req_ready (i_io_lsq_req_ready),
    .io_lsq_req_valid (io_lsq_req_valid),
    .io_lsq_req_bits_cmd (io_lsq_req_bits_cmd),
    .io_lsq_req_bits_addr (io_lsq_req_bits_addr),
    .io_lsq_req_bits_vaddr (io_lsq_req_bits_vaddr),
    .io_lsq_req_bits_data (io_lsq_req_bits_data),
    .io_lsq_req_bits_mask (io_lsq_req_bits_mask),
    .io_lsq_req_bits_id (io_lsq_req_bits_id),
    .io_lsq_req_bits_nc (io_lsq_req_bits_nc),
    .io_lsq_req_bits_memBackTypeMM (io_lsq_req_bits_memBackTypeMM),
    .io_lsq_idResp_valid (i_io_lsq_idResp_valid),
    .io_lsq_idResp_bits_mid (i_io_lsq_idResp_bits_mid),
    .io_lsq_idResp_bits_sid (i_io_lsq_idResp_bits_sid),
    .io_lsq_idResp_bits_is2lq (i_io_lsq_idResp_bits_is2lq),
    .io_lsq_idResp_bits_nc (i_io_lsq_idResp_bits_nc),
    .io_lsq_resp_ready (io_lsq_resp_ready),
    .io_lsq_resp_valid (i_io_lsq_resp_valid),
    .io_lsq_resp_bits_data (i_io_lsq_resp_bits_data),
    .io_lsq_resp_bits_id (i_io_lsq_resp_bits_id),
    .io_lsq_resp_bits_nc (i_io_lsq_resp_bits_nc),
    .io_lsq_resp_bits_is2lq (i_io_lsq_resp_bits_is2lq),
    .io_lsq_resp_bits_denied (i_io_lsq_resp_bits_denied),
    .io_lsq_resp_bits_corrupt (i_io_lsq_resp_bits_corrupt),
    .io_forward_0_vaddr (io_forward_0_vaddr),
    .io_forward_0_paddr (io_forward_0_paddr),
    .io_forward_0_valid (io_forward_0_valid),
    .io_forward_0_forwardMask_0 (i_io_forward_0_forwardMask_0),
    .io_forward_0_forwardMask_1 (i_io_forward_0_forwardMask_1),
    .io_forward_0_forwardMask_2 (i_io_forward_0_forwardMask_2),
    .io_forward_0_forwardMask_3 (i_io_forward_0_forwardMask_3),
    .io_forward_0_forwardMask_4 (i_io_forward_0_forwardMask_4),
    .io_forward_0_forwardMask_5 (i_io_forward_0_forwardMask_5),
    .io_forward_0_forwardMask_6 (i_io_forward_0_forwardMask_6),
    .io_forward_0_forwardMask_7 (i_io_forward_0_forwardMask_7),
    .io_forward_0_forwardMask_8 (i_io_forward_0_forwardMask_8),
    .io_forward_0_forwardMask_9 (i_io_forward_0_forwardMask_9),
    .io_forward_0_forwardMask_10 (i_io_forward_0_forwardMask_10),
    .io_forward_0_forwardMask_11 (i_io_forward_0_forwardMask_11),
    .io_forward_0_forwardMask_12 (i_io_forward_0_forwardMask_12),
    .io_forward_0_forwardMask_13 (i_io_forward_0_forwardMask_13),
    .io_forward_0_forwardMask_14 (i_io_forward_0_forwardMask_14),
    .io_forward_0_forwardMask_15 (i_io_forward_0_forwardMask_15),
    .io_forward_0_forwardData_0 (i_io_forward_0_forwardData_0),
    .io_forward_0_forwardData_1 (i_io_forward_0_forwardData_1),
    .io_forward_0_forwardData_2 (i_io_forward_0_forwardData_2),
    .io_forward_0_forwardData_3 (i_io_forward_0_forwardData_3),
    .io_forward_0_forwardData_4 (i_io_forward_0_forwardData_4),
    .io_forward_0_forwardData_5 (i_io_forward_0_forwardData_5),
    .io_forward_0_forwardData_6 (i_io_forward_0_forwardData_6),
    .io_forward_0_forwardData_7 (i_io_forward_0_forwardData_7),
    .io_forward_0_forwardData_8 (i_io_forward_0_forwardData_8),
    .io_forward_0_forwardData_9 (i_io_forward_0_forwardData_9),
    .io_forward_0_forwardData_10 (i_io_forward_0_forwardData_10),
    .io_forward_0_forwardData_11 (i_io_forward_0_forwardData_11),
    .io_forward_0_forwardData_12 (i_io_forward_0_forwardData_12),
    .io_forward_0_forwardData_13 (i_io_forward_0_forwardData_13),
    .io_forward_0_forwardData_14 (i_io_forward_0_forwardData_14),
    .io_forward_0_forwardData_15 (i_io_forward_0_forwardData_15),
    .io_forward_0_matchInvalid (i_io_forward_0_matchInvalid),
    .io_forward_1_vaddr (io_forward_1_vaddr),
    .io_forward_1_paddr (io_forward_1_paddr),
    .io_forward_1_valid (io_forward_1_valid),
    .io_forward_1_forwardMask_0 (i_io_forward_1_forwardMask_0),
    .io_forward_1_forwardMask_1 (i_io_forward_1_forwardMask_1),
    .io_forward_1_forwardMask_2 (i_io_forward_1_forwardMask_2),
    .io_forward_1_forwardMask_3 (i_io_forward_1_forwardMask_3),
    .io_forward_1_forwardMask_4 (i_io_forward_1_forwardMask_4),
    .io_forward_1_forwardMask_5 (i_io_forward_1_forwardMask_5),
    .io_forward_1_forwardMask_6 (i_io_forward_1_forwardMask_6),
    .io_forward_1_forwardMask_7 (i_io_forward_1_forwardMask_7),
    .io_forward_1_forwardMask_8 (i_io_forward_1_forwardMask_8),
    .io_forward_1_forwardMask_9 (i_io_forward_1_forwardMask_9),
    .io_forward_1_forwardMask_10 (i_io_forward_1_forwardMask_10),
    .io_forward_1_forwardMask_11 (i_io_forward_1_forwardMask_11),
    .io_forward_1_forwardMask_12 (i_io_forward_1_forwardMask_12),
    .io_forward_1_forwardMask_13 (i_io_forward_1_forwardMask_13),
    .io_forward_1_forwardMask_14 (i_io_forward_1_forwardMask_14),
    .io_forward_1_forwardMask_15 (i_io_forward_1_forwardMask_15),
    .io_forward_1_forwardData_0 (i_io_forward_1_forwardData_0),
    .io_forward_1_forwardData_1 (i_io_forward_1_forwardData_1),
    .io_forward_1_forwardData_2 (i_io_forward_1_forwardData_2),
    .io_forward_1_forwardData_3 (i_io_forward_1_forwardData_3),
    .io_forward_1_forwardData_4 (i_io_forward_1_forwardData_4),
    .io_forward_1_forwardData_5 (i_io_forward_1_forwardData_5),
    .io_forward_1_forwardData_6 (i_io_forward_1_forwardData_6),
    .io_forward_1_forwardData_7 (i_io_forward_1_forwardData_7),
    .io_forward_1_forwardData_8 (i_io_forward_1_forwardData_8),
    .io_forward_1_forwardData_9 (i_io_forward_1_forwardData_9),
    .io_forward_1_forwardData_10 (i_io_forward_1_forwardData_10),
    .io_forward_1_forwardData_11 (i_io_forward_1_forwardData_11),
    .io_forward_1_forwardData_12 (i_io_forward_1_forwardData_12),
    .io_forward_1_forwardData_13 (i_io_forward_1_forwardData_13),
    .io_forward_1_forwardData_14 (i_io_forward_1_forwardData_14),
    .io_forward_1_forwardData_15 (i_io_forward_1_forwardData_15),
    .io_forward_1_matchInvalid (i_io_forward_1_matchInvalid),
    .io_forward_2_vaddr (io_forward_2_vaddr),
    .io_forward_2_paddr (io_forward_2_paddr),
    .io_forward_2_valid (io_forward_2_valid),
    .io_forward_2_forwardMask_0 (i_io_forward_2_forwardMask_0),
    .io_forward_2_forwardMask_1 (i_io_forward_2_forwardMask_1),
    .io_forward_2_forwardMask_2 (i_io_forward_2_forwardMask_2),
    .io_forward_2_forwardMask_3 (i_io_forward_2_forwardMask_3),
    .io_forward_2_forwardMask_4 (i_io_forward_2_forwardMask_4),
    .io_forward_2_forwardMask_5 (i_io_forward_2_forwardMask_5),
    .io_forward_2_forwardMask_6 (i_io_forward_2_forwardMask_6),
    .io_forward_2_forwardMask_7 (i_io_forward_2_forwardMask_7),
    .io_forward_2_forwardMask_8 (i_io_forward_2_forwardMask_8),
    .io_forward_2_forwardMask_9 (i_io_forward_2_forwardMask_9),
    .io_forward_2_forwardMask_10 (i_io_forward_2_forwardMask_10),
    .io_forward_2_forwardMask_11 (i_io_forward_2_forwardMask_11),
    .io_forward_2_forwardMask_12 (i_io_forward_2_forwardMask_12),
    .io_forward_2_forwardMask_13 (i_io_forward_2_forwardMask_13),
    .io_forward_2_forwardMask_14 (i_io_forward_2_forwardMask_14),
    .io_forward_2_forwardMask_15 (i_io_forward_2_forwardMask_15),
    .io_forward_2_forwardData_0 (i_io_forward_2_forwardData_0),
    .io_forward_2_forwardData_1 (i_io_forward_2_forwardData_1),
    .io_forward_2_forwardData_2 (i_io_forward_2_forwardData_2),
    .io_forward_2_forwardData_3 (i_io_forward_2_forwardData_3),
    .io_forward_2_forwardData_4 (i_io_forward_2_forwardData_4),
    .io_forward_2_forwardData_5 (i_io_forward_2_forwardData_5),
    .io_forward_2_forwardData_6 (i_io_forward_2_forwardData_6),
    .io_forward_2_forwardData_7 (i_io_forward_2_forwardData_7),
    .io_forward_2_forwardData_8 (i_io_forward_2_forwardData_8),
    .io_forward_2_forwardData_9 (i_io_forward_2_forwardData_9),
    .io_forward_2_forwardData_10 (i_io_forward_2_forwardData_10),
    .io_forward_2_forwardData_11 (i_io_forward_2_forwardData_11),
    .io_forward_2_forwardData_12 (i_io_forward_2_forwardData_12),
    .io_forward_2_forwardData_13 (i_io_forward_2_forwardData_13),
    .io_forward_2_forwardData_14 (i_io_forward_2_forwardData_14),
    .io_forward_2_forwardData_15 (i_io_forward_2_forwardData_15),
    .io_forward_2_matchInvalid (i_io_forward_2_matchInvalid),
    .io_wfi_wfiReq (io_wfi_wfiReq),
    .io_wfi_wfiSafe (i_io_wfi_wfiSafe),
    .io_busError_ecc_error_valid (i_io_busError_ecc_error_valid),
    .io_busError_ecc_error_bits (i_io_busError_ecc_error_bits),
    .gatewayIn_packed_42_bore (i_gatewayIn_packed_42_bore)
  );
  task automatic compare_outputs();
    `CMP(g_auto_client_out_a_valid, i_auto_client_out_a_valid, "auto_client_out_a_valid")
    `CMP(g_auto_client_out_a_bits_opcode, i_auto_client_out_a_bits_opcode, "auto_client_out_a_bits_opcode")
    `CMP(g_auto_client_out_a_bits_size, i_auto_client_out_a_bits_size, "auto_client_out_a_bits_size")
    `CMP(g_auto_client_out_a_bits_source, i_auto_client_out_a_bits_source, "auto_client_out_a_bits_source")
    `CMP(g_auto_client_out_a_bits_address, i_auto_client_out_a_bits_address, "auto_client_out_a_bits_address")
    `CMP(g_auto_client_out_a_bits_user_memPageType_NC, i_auto_client_out_a_bits_user_memPageType_NC, "auto_client_out_a_bits_user_memPageType_NC")
    `CMP(g_auto_client_out_a_bits_user_memBackType_MM, i_auto_client_out_a_bits_user_memBackType_MM, "auto_client_out_a_bits_user_memBackType_MM")
    `CMP(g_auto_client_out_a_bits_mask, i_auto_client_out_a_bits_mask, "auto_client_out_a_bits_mask")
    `CMP(g_auto_client_out_a_bits_data, i_auto_client_out_a_bits_data, "auto_client_out_a_bits_data")
    `CMP(g_io_flush_empty, i_io_flush_empty, "io_flush_empty")
    `CMP(g_io_lsq_req_ready, i_io_lsq_req_ready, "io_lsq_req_ready")
    `CMP(g_io_lsq_idResp_valid, i_io_lsq_idResp_valid, "io_lsq_idResp_valid")
    `CMP(g_io_lsq_idResp_bits_mid, i_io_lsq_idResp_bits_mid, "io_lsq_idResp_bits_mid")
    `CMP(g_io_lsq_idResp_bits_sid, i_io_lsq_idResp_bits_sid, "io_lsq_idResp_bits_sid")
    `CMP(g_io_lsq_idResp_bits_is2lq, i_io_lsq_idResp_bits_is2lq, "io_lsq_idResp_bits_is2lq")
    `CMP(g_io_lsq_idResp_bits_nc, i_io_lsq_idResp_bits_nc, "io_lsq_idResp_bits_nc")
    `CMP(g_io_lsq_resp_valid, i_io_lsq_resp_valid, "io_lsq_resp_valid")
    `CMP(g_io_lsq_resp_bits_data, i_io_lsq_resp_bits_data, "io_lsq_resp_bits_data")
    `CMP(g_io_lsq_resp_bits_id, i_io_lsq_resp_bits_id, "io_lsq_resp_bits_id")
    `CMP(g_io_lsq_resp_bits_nc, i_io_lsq_resp_bits_nc, "io_lsq_resp_bits_nc")
    `CMP(g_io_lsq_resp_bits_is2lq, i_io_lsq_resp_bits_is2lq, "io_lsq_resp_bits_is2lq")
    `CMP(g_io_lsq_resp_bits_denied, i_io_lsq_resp_bits_denied, "io_lsq_resp_bits_denied")
    `CMP(g_io_lsq_resp_bits_corrupt, i_io_lsq_resp_bits_corrupt, "io_lsq_resp_bits_corrupt")
    `CMP(g_io_forward_0_forwardMask_0, i_io_forward_0_forwardMask_0, "io_forward_0_forwardMask_0")
    `CMP(g_io_forward_0_forwardMask_1, i_io_forward_0_forwardMask_1, "io_forward_0_forwardMask_1")
    `CMP(g_io_forward_0_forwardMask_2, i_io_forward_0_forwardMask_2, "io_forward_0_forwardMask_2")
    `CMP(g_io_forward_0_forwardMask_3, i_io_forward_0_forwardMask_3, "io_forward_0_forwardMask_3")
    `CMP(g_io_forward_0_forwardMask_4, i_io_forward_0_forwardMask_4, "io_forward_0_forwardMask_4")
    `CMP(g_io_forward_0_forwardMask_5, i_io_forward_0_forwardMask_5, "io_forward_0_forwardMask_5")
    `CMP(g_io_forward_0_forwardMask_6, i_io_forward_0_forwardMask_6, "io_forward_0_forwardMask_6")
    `CMP(g_io_forward_0_forwardMask_7, i_io_forward_0_forwardMask_7, "io_forward_0_forwardMask_7")
    `CMP(g_io_forward_0_forwardMask_8, i_io_forward_0_forwardMask_8, "io_forward_0_forwardMask_8")
    `CMP(g_io_forward_0_forwardMask_9, i_io_forward_0_forwardMask_9, "io_forward_0_forwardMask_9")
    `CMP(g_io_forward_0_forwardMask_10, i_io_forward_0_forwardMask_10, "io_forward_0_forwardMask_10")
    `CMP(g_io_forward_0_forwardMask_11, i_io_forward_0_forwardMask_11, "io_forward_0_forwardMask_11")
    `CMP(g_io_forward_0_forwardMask_12, i_io_forward_0_forwardMask_12, "io_forward_0_forwardMask_12")
    `CMP(g_io_forward_0_forwardMask_13, i_io_forward_0_forwardMask_13, "io_forward_0_forwardMask_13")
    `CMP(g_io_forward_0_forwardMask_14, i_io_forward_0_forwardMask_14, "io_forward_0_forwardMask_14")
    `CMP(g_io_forward_0_forwardMask_15, i_io_forward_0_forwardMask_15, "io_forward_0_forwardMask_15")
    `CMP(g_io_forward_0_forwardData_0, i_io_forward_0_forwardData_0, "io_forward_0_forwardData_0")
    `CMP(g_io_forward_0_forwardData_1, i_io_forward_0_forwardData_1, "io_forward_0_forwardData_1")
    `CMP(g_io_forward_0_forwardData_2, i_io_forward_0_forwardData_2, "io_forward_0_forwardData_2")
    `CMP(g_io_forward_0_forwardData_3, i_io_forward_0_forwardData_3, "io_forward_0_forwardData_3")
    `CMP(g_io_forward_0_forwardData_4, i_io_forward_0_forwardData_4, "io_forward_0_forwardData_4")
    `CMP(g_io_forward_0_forwardData_5, i_io_forward_0_forwardData_5, "io_forward_0_forwardData_5")
    `CMP(g_io_forward_0_forwardData_6, i_io_forward_0_forwardData_6, "io_forward_0_forwardData_6")
    `CMP(g_io_forward_0_forwardData_7, i_io_forward_0_forwardData_7, "io_forward_0_forwardData_7")
    `CMP(g_io_forward_0_forwardData_8, i_io_forward_0_forwardData_8, "io_forward_0_forwardData_8")
    `CMP(g_io_forward_0_forwardData_9, i_io_forward_0_forwardData_9, "io_forward_0_forwardData_9")
    `CMP(g_io_forward_0_forwardData_10, i_io_forward_0_forwardData_10, "io_forward_0_forwardData_10")
    `CMP(g_io_forward_0_forwardData_11, i_io_forward_0_forwardData_11, "io_forward_0_forwardData_11")
    `CMP(g_io_forward_0_forwardData_12, i_io_forward_0_forwardData_12, "io_forward_0_forwardData_12")
    `CMP(g_io_forward_0_forwardData_13, i_io_forward_0_forwardData_13, "io_forward_0_forwardData_13")
    `CMP(g_io_forward_0_forwardData_14, i_io_forward_0_forwardData_14, "io_forward_0_forwardData_14")
    `CMP(g_io_forward_0_forwardData_15, i_io_forward_0_forwardData_15, "io_forward_0_forwardData_15")
    `CMP(g_io_forward_0_matchInvalid, i_io_forward_0_matchInvalid, "io_forward_0_matchInvalid")
    `CMP(g_io_forward_1_forwardMask_0, i_io_forward_1_forwardMask_0, "io_forward_1_forwardMask_0")
    `CMP(g_io_forward_1_forwardMask_1, i_io_forward_1_forwardMask_1, "io_forward_1_forwardMask_1")
    `CMP(g_io_forward_1_forwardMask_2, i_io_forward_1_forwardMask_2, "io_forward_1_forwardMask_2")
    `CMP(g_io_forward_1_forwardMask_3, i_io_forward_1_forwardMask_3, "io_forward_1_forwardMask_3")
    `CMP(g_io_forward_1_forwardMask_4, i_io_forward_1_forwardMask_4, "io_forward_1_forwardMask_4")
    `CMP(g_io_forward_1_forwardMask_5, i_io_forward_1_forwardMask_5, "io_forward_1_forwardMask_5")
    `CMP(g_io_forward_1_forwardMask_6, i_io_forward_1_forwardMask_6, "io_forward_1_forwardMask_6")
    `CMP(g_io_forward_1_forwardMask_7, i_io_forward_1_forwardMask_7, "io_forward_1_forwardMask_7")
    `CMP(g_io_forward_1_forwardMask_8, i_io_forward_1_forwardMask_8, "io_forward_1_forwardMask_8")
    `CMP(g_io_forward_1_forwardMask_9, i_io_forward_1_forwardMask_9, "io_forward_1_forwardMask_9")
    `CMP(g_io_forward_1_forwardMask_10, i_io_forward_1_forwardMask_10, "io_forward_1_forwardMask_10")
    `CMP(g_io_forward_1_forwardMask_11, i_io_forward_1_forwardMask_11, "io_forward_1_forwardMask_11")
    `CMP(g_io_forward_1_forwardMask_12, i_io_forward_1_forwardMask_12, "io_forward_1_forwardMask_12")
    `CMP(g_io_forward_1_forwardMask_13, i_io_forward_1_forwardMask_13, "io_forward_1_forwardMask_13")
    `CMP(g_io_forward_1_forwardMask_14, i_io_forward_1_forwardMask_14, "io_forward_1_forwardMask_14")
    `CMP(g_io_forward_1_forwardMask_15, i_io_forward_1_forwardMask_15, "io_forward_1_forwardMask_15")
    `CMP(g_io_forward_1_forwardData_0, i_io_forward_1_forwardData_0, "io_forward_1_forwardData_0")
    `CMP(g_io_forward_1_forwardData_1, i_io_forward_1_forwardData_1, "io_forward_1_forwardData_1")
    `CMP(g_io_forward_1_forwardData_2, i_io_forward_1_forwardData_2, "io_forward_1_forwardData_2")
    `CMP(g_io_forward_1_forwardData_3, i_io_forward_1_forwardData_3, "io_forward_1_forwardData_3")
    `CMP(g_io_forward_1_forwardData_4, i_io_forward_1_forwardData_4, "io_forward_1_forwardData_4")
    `CMP(g_io_forward_1_forwardData_5, i_io_forward_1_forwardData_5, "io_forward_1_forwardData_5")
    `CMP(g_io_forward_1_forwardData_6, i_io_forward_1_forwardData_6, "io_forward_1_forwardData_6")
    `CMP(g_io_forward_1_forwardData_7, i_io_forward_1_forwardData_7, "io_forward_1_forwardData_7")
    `CMP(g_io_forward_1_forwardData_8, i_io_forward_1_forwardData_8, "io_forward_1_forwardData_8")
    `CMP(g_io_forward_1_forwardData_9, i_io_forward_1_forwardData_9, "io_forward_1_forwardData_9")
    `CMP(g_io_forward_1_forwardData_10, i_io_forward_1_forwardData_10, "io_forward_1_forwardData_10")
    `CMP(g_io_forward_1_forwardData_11, i_io_forward_1_forwardData_11, "io_forward_1_forwardData_11")
    `CMP(g_io_forward_1_forwardData_12, i_io_forward_1_forwardData_12, "io_forward_1_forwardData_12")
    `CMP(g_io_forward_1_forwardData_13, i_io_forward_1_forwardData_13, "io_forward_1_forwardData_13")
    `CMP(g_io_forward_1_forwardData_14, i_io_forward_1_forwardData_14, "io_forward_1_forwardData_14")
    `CMP(g_io_forward_1_forwardData_15, i_io_forward_1_forwardData_15, "io_forward_1_forwardData_15")
    `CMP(g_io_forward_1_matchInvalid, i_io_forward_1_matchInvalid, "io_forward_1_matchInvalid")
    `CMP(g_io_forward_2_forwardMask_0, i_io_forward_2_forwardMask_0, "io_forward_2_forwardMask_0")
    `CMP(g_io_forward_2_forwardMask_1, i_io_forward_2_forwardMask_1, "io_forward_2_forwardMask_1")
    `CMP(g_io_forward_2_forwardMask_2, i_io_forward_2_forwardMask_2, "io_forward_2_forwardMask_2")
    `CMP(g_io_forward_2_forwardMask_3, i_io_forward_2_forwardMask_3, "io_forward_2_forwardMask_3")
    `CMP(g_io_forward_2_forwardMask_4, i_io_forward_2_forwardMask_4, "io_forward_2_forwardMask_4")
    `CMP(g_io_forward_2_forwardMask_5, i_io_forward_2_forwardMask_5, "io_forward_2_forwardMask_5")
    `CMP(g_io_forward_2_forwardMask_6, i_io_forward_2_forwardMask_6, "io_forward_2_forwardMask_6")
    `CMP(g_io_forward_2_forwardMask_7, i_io_forward_2_forwardMask_7, "io_forward_2_forwardMask_7")
    `CMP(g_io_forward_2_forwardMask_8, i_io_forward_2_forwardMask_8, "io_forward_2_forwardMask_8")
    `CMP(g_io_forward_2_forwardMask_9, i_io_forward_2_forwardMask_9, "io_forward_2_forwardMask_9")
    `CMP(g_io_forward_2_forwardMask_10, i_io_forward_2_forwardMask_10, "io_forward_2_forwardMask_10")
    `CMP(g_io_forward_2_forwardMask_11, i_io_forward_2_forwardMask_11, "io_forward_2_forwardMask_11")
    `CMP(g_io_forward_2_forwardMask_12, i_io_forward_2_forwardMask_12, "io_forward_2_forwardMask_12")
    `CMP(g_io_forward_2_forwardMask_13, i_io_forward_2_forwardMask_13, "io_forward_2_forwardMask_13")
    `CMP(g_io_forward_2_forwardMask_14, i_io_forward_2_forwardMask_14, "io_forward_2_forwardMask_14")
    `CMP(g_io_forward_2_forwardMask_15, i_io_forward_2_forwardMask_15, "io_forward_2_forwardMask_15")
    `CMP(g_io_forward_2_forwardData_0, i_io_forward_2_forwardData_0, "io_forward_2_forwardData_0")
    `CMP(g_io_forward_2_forwardData_1, i_io_forward_2_forwardData_1, "io_forward_2_forwardData_1")
    `CMP(g_io_forward_2_forwardData_2, i_io_forward_2_forwardData_2, "io_forward_2_forwardData_2")
    `CMP(g_io_forward_2_forwardData_3, i_io_forward_2_forwardData_3, "io_forward_2_forwardData_3")
    `CMP(g_io_forward_2_forwardData_4, i_io_forward_2_forwardData_4, "io_forward_2_forwardData_4")
    `CMP(g_io_forward_2_forwardData_5, i_io_forward_2_forwardData_5, "io_forward_2_forwardData_5")
    `CMP(g_io_forward_2_forwardData_6, i_io_forward_2_forwardData_6, "io_forward_2_forwardData_6")
    `CMP(g_io_forward_2_forwardData_7, i_io_forward_2_forwardData_7, "io_forward_2_forwardData_7")
    `CMP(g_io_forward_2_forwardData_8, i_io_forward_2_forwardData_8, "io_forward_2_forwardData_8")
    `CMP(g_io_forward_2_forwardData_9, i_io_forward_2_forwardData_9, "io_forward_2_forwardData_9")
    `CMP(g_io_forward_2_forwardData_10, i_io_forward_2_forwardData_10, "io_forward_2_forwardData_10")
    `CMP(g_io_forward_2_forwardData_11, i_io_forward_2_forwardData_11, "io_forward_2_forwardData_11")
    `CMP(g_io_forward_2_forwardData_12, i_io_forward_2_forwardData_12, "io_forward_2_forwardData_12")
    `CMP(g_io_forward_2_forwardData_13, i_io_forward_2_forwardData_13, "io_forward_2_forwardData_13")
    `CMP(g_io_forward_2_forwardData_14, i_io_forward_2_forwardData_14, "io_forward_2_forwardData_14")
    `CMP(g_io_forward_2_forwardData_15, i_io_forward_2_forwardData_15, "io_forward_2_forwardData_15")
    `CMP(g_io_forward_2_matchInvalid, i_io_forward_2_matchInvalid, "io_forward_2_matchInvalid")
    `CMP(g_io_wfi_wfiSafe, i_io_wfi_wfiSafe, "io_wfi_wfiSafe")
    `CMP(g_io_busError_ecc_error_valid, i_io_busError_ecc_error_valid, "io_busError_ecc_error_valid")
    `CMP(g_io_busError_ecc_error_bits, i_io_busError_ecc_error_bits, "io_busError_ecc_error_bits")
    `CMP(g_gatewayIn_packed_42_bore, i_gatewayIn_packed_42_bore, "gatewayIn_packed_42_bore")
  endtask
  // END GENERATED

  // ---------------------------------------------------------------------------
  // 地址池：NPOOL 个块（每阶段只用前 p_pool 个），paddr 块号与 vaddr 块号成对
  // ---------------------------------------------------------------------------
  localparam int NPOOL = 24;
  logic [44:0] pblk [NPOOL];
  logic [46:0] vblk [NPOOL];
  initial begin
    for (int k = 0; k < NPOOL; k++) begin
      pblk[k] = {$urandom, $urandom} & 45'h1fff_ffff_ffff;
      vblk[k] = {$urandom, $urandom} & 47'h7fff_ffff_ffff;
    end
    pblk[5] = pblk[4] ^ 45'h8;          // 两个在同一 64B 行里的相邻块
    vblk[5] = vblk[4] ^ 47'h8;
  end

  function automatic logic [7:0] aligned_mask(input logic [2:0] off, input int lg);
    logic [7:0] m;
    int base;
    base = (int'(off) >> lg) << lg;
    m = '0;
    for (int j = 0; j < (1 << lg); j++) m[base + j] = 1'b1;
    return m;
  endfunction

  // ---------------------------------------------------------------------------
  // 阶段参数
  // ---------------------------------------------------------------------------
  int p_req, p_aready, p_rready, p_fwd, p_wfi, p_flush, p_nc, p_store, p_dlat, p_pool;
  bit outst_mode;
  task automatic new_phase();
    p_req    = $urandom_range(10, 90);
    p_aready = $urandom_range(20, 100);
    p_rready = $urandom_range(20, 100);
    p_fwd    = $urandom_range(0, 90);
    p_wfi    = ($urandom_range(0, 3) == 0) ? $urandom_range(5, 60) : 0;
    p_flush  = ($urandom_range(0, 3) == 0) ? 3 : 0;
    p_nc     = $urandom_range(0, 100);
    p_store  = $urandom_range(10, 90);
    p_dlat   = $urandom_range(0, 12);
    outst_mode = $urandom_range(0, 1);
    p_pool   = ($urandom_range(0, 2) == 0) ? NPOOL : $urandom_range(2, 6);  // 大池子才填得满 16 项
  endtask

  // ---------------------------------------------------------------------------
  // 从设备模型：golden 发出的 source 排队，随机延迟后逐个回 D
  // ---------------------------------------------------------------------------
  logic [3:0] pend_q [$];
  int d_wait;
  always @(posedge clk) begin
    if (rst) begin
      pend_q.delete();
      d_wait = 0;
    end
    else begin
      if (g_auto_client_out_a_valid && auto_client_out_a_ready)
        pend_q.push_back(g_auto_client_out_a_bits_source);
    end
  end

  task automatic drive_d();
    int k;
    auto_client_out_d_valid        = 1'b0;
    auto_client_out_d_bits_source  = $urandom;
    auto_client_out_d_bits_data    = {$urandom, $urandom};
    auto_client_out_d_bits_denied  = ($urandom_range(0, 15) == 0);
    auto_client_out_d_bits_corrupt = ($urandom_range(0, 15) == 0);
    if (pend_q.size() > 0) begin
      if (d_wait > 0) d_wait--;
      else begin
        k = $urandom_range(0, pend_q.size() - 1);   // 乱序返回
        auto_client_out_d_valid       = 1'b1;
        auto_client_out_d_bits_source = pend_q[k];
        pend_q.delete(k);
        d_wait = $urandom_range(0, p_dlat);
      end
    end
  endtask

  task automatic drive();
    int k, lg;
    logic [2:0] off;
    // LSQ 请求
    k   = $urandom_range(0, p_pool-1);
    off = $urandom;
    lg  = $urandom_range(0, 3);
    io_lsq_req_valid = ($urandom_range(0, 99) < p_req);
    io_lsq_req_bits_cmd = ($urandom_range(0, 19) == 0) ? 5'($urandom) :
                          (($urandom_range(0, 99) < p_store) ? 5'h1 : 5'h0);
    io_lsq_req_bits_addr  = {pblk[k], off};
    io_lsq_req_bits_vaddr = ($urandom_range(0, 29) == 0) ? {vblk[$urandom_range(0, p_pool-1)], off}
                                                         : {vblk[k], off};
    io_lsq_req_bits_data  = {$urandom, $urandom};
    io_lsq_req_bits_mask  = ($urandom_range(0, 9) == 0) ? 8'($urandom) : aligned_mask(off, lg);
    io_lsq_req_bits_id    = $urandom;
    io_lsq_req_bits_nc    = ($urandom_range(0, 99) < p_nc);
    io_lsq_req_bits_memBackTypeMM = $urandom;
    io_lsq_resp_ready = ($urandom_range(0, 99) < p_rready);
    auto_client_out_a_ready = ($urandom_range(0, 99) < p_aready);
    io_enableOutstanding = outst_mode ^ ($urandom_range(0, 49) == 0);
    io_flush_valid = ($urandom_range(0, 99) < p_flush);
    io_wfi_wfiReq  = ($urandom_range(0, 99) < p_wfi);
    io_hartId      = $urandom;
    // 前递查询
    io_forward_0_valid = ($urandom_range(0, 99) < p_fwd);
    io_forward_1_valid = ($urandom_range(0, 99) < p_fwd);
    io_forward_2_valid = ($urandom_range(0, 99) < p_fwd);
    k = $urandom_range(0, p_pool-1);
    io_forward_0_vaddr = {vblk[k], 3'($urandom)};
    io_forward_0_paddr = ($urandom_range(0, 9) == 0) ? {pblk[$urandom_range(0, p_pool-1)], 3'($urandom)} : {pblk[k], 3'($urandom)};
    k = $urandom_range(0, p_pool-1);
    io_forward_1_vaddr = {vblk[k], 3'($urandom)};
    io_forward_1_paddr = ($urandom_range(0, 9) == 0) ? {pblk[$urandom_range(0, p_pool-1)], 3'($urandom)} : {pblk[k], 3'($urandom)};
    k = $urandom_range(0, p_pool-1);
    io_forward_2_vaddr = {vblk[k], 3'($urandom)};
    io_forward_2_paddr = ($urandom_range(0, 9) == 0) ? {pblk[$urandom_range(0, p_pool-1)], 3'($urandom)} : {pblk[k], 3'($urandom)};
    drive_d();
    rst = ($urandom_range(0, 19999) == 0);
  endtask

  // ---------------------------------------------------------------------------
  // 覆盖计数（探 golden 内部线）
  // ---------------------------------------------------------------------------
  longint c_merge, c_alloc_ws, c_reject, c_drain, c_match_inv, c_fwd_hit, c_bus_err,
          c_ustate_wr, c_waitsame, c_full, c_get, c_put, c_resp, c_wfi_safe, c_mm_store,
          c_fly, c_idle;
  task automatic sample_cov();
    if (u_g.e0_fire_probe && u_g.e0_canMerge) c_merge++;
    if (u_g.e0_fire_probe && !u_g.e0_canMerge && u_g.e0_allocWaitSame) c_alloc_ws++;
    if (io_lsq_req_valid && u_g.e0_reject) c_reject++;
    if (u_g.do_uarch_drain) c_drain++;
    if (g_io_forward_0_matchInvalid | g_io_forward_1_matchInvalid | g_io_forward_2_matchInvalid) c_match_inv++;
    if (|{g_io_forward_0_forwardMask_0, g_io_forward_0_forwardMask_8,
          g_io_forward_1_forwardMask_3, g_io_forward_2_forwardMask_12}) c_fwd_hit++;
    if (g_io_busError_ecc_error_valid) c_bus_err++;
    if (u_g.uState == 2'h2) c_ustate_wr++;
    if (|{u_g.states_0_waitSame, u_g.states_1_waitSame, u_g.states_2_waitSame, u_g.states_3_waitSame}) c_waitsame++;
    if (!u_g.e0_canMerge && &{u_g.states_0_valid, u_g.states_5_valid, u_g.states_10_valid, u_g.states_15_valid}) c_full++;
    if (g_auto_client_out_a_valid && auto_client_out_a_ready) begin
      if (g_auto_client_out_a_bits_opcode == 4'h4) c_get++; else c_put++;
    end
    if (g_io_lsq_resp_valid && io_lsq_resp_ready) c_resp++;
    if (g_io_wfi_wfiSafe) c_wfi_safe++;
    if (g_gatewayIn_packed_42_bore[152]) c_mm_store++;
    if (|{u_g.f1_flyTagMatches_0, u_g.f1_flyTagMatches_1, u_g.f1_flyTagMatches_1_2, u_g.f1_flyTagMatches_2_3}) c_fly++;
    if (|{u_g.f1_idleTagMatches_0, u_g.f1_idleTagMatches_1, u_g.f1_idleTagMatches_1_2, u_g.f1_idleTagMatches_2_3}) c_idle++;
  endtask

  // 预热（不比对）：条目字段、idResp、前递 f1 寄存器都不复位，两个例化体在 initreg 随机档下
  // 初值各不相同。先把它们全部写成确定值，再开始逐拍比对 ——
  //   ① 16 个互不同块的 MMIO 写（nc=0 不合并）、A 不 ready：16 项全部分配，字段全写；
  //      同时 3 条前递流水恒 valid、查询地址逐项扫过：f1 寄存器与候选寄存器全写；
  //   ② 放开 A / D / resp：16 笔全部发出、收 D（写 denied/corrupt）、交回，缓冲排空。
  task automatic warmup();
    for (int c = 0; c < 16; c++) begin
      io_lsq_req_valid = 1'b1;
      io_lsq_req_bits_cmd = 5'h1;
      io_lsq_req_bits_addr  = {45'h1000_0000 + 45'(c), 3'h0};
      io_lsq_req_bits_vaddr = {47'h2000_0000 + 47'(c), 3'h0};
      io_lsq_req_bits_mask  = 8'hFF;
      io_lsq_req_bits_nc    = 1'b0;
      auto_client_out_a_ready = 1'b0;
      io_lsq_resp_ready = 1'b0;
      io_flush_valid = 1'b0;
      io_wfi_wfiReq = 1'b0;
      {io_forward_0_valid, io_forward_1_valid, io_forward_2_valid} = 3'b111;
      io_forward_0_vaddr = {47'h2000_0000 + 47'(c), 3'h0};
      io_forward_1_vaddr = {47'h2000_0000 + 47'((c + 5) % 16), 3'h0};
      io_forward_2_vaddr = {47'h2000_0000 + 47'((c + 11) % 16), 3'h0};
      // paddr 与 vaddr 成对，不制造 v/p 失配（失配会触发 drain、拒收后续预热请求）
      io_forward_0_paddr = {45'h1000_0000 + 45'(c), 3'h0};
      io_forward_1_paddr = {45'h1000_0000 + 45'((c + 5) % 16), 3'h0};
      io_forward_2_paddr = {45'h1000_0000 + 45'((c + 11) % 16), 3'h0};
      @(posedge clk); #1;
    end
    io_lsq_req_valid = 1'b0;
    for (int c = 0; c < 200 && !(g_io_flush_empty && pend_q.size() == 0); c++) begin
      auto_client_out_a_ready = 1'b1;
      io_lsq_resp_ready = 1'b1;
      io_enableOutstanding = 1'b1;
      drive_d();
      @(posedge clk); #1;
    end
    auto_client_out_d_valid = 1'b0;
    if (!g_io_flush_empty || u_g.do_uarch_drain) begin
      $display("WARMUP FAILED: buffer not drained");
      errors++;
    end
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    {c_merge, c_alloc_ws, c_reject, c_drain, c_match_inv, c_fwd_hit, c_bus_err, c_ustate_wr,
     c_waitsame, c_full, c_get, c_put, c_resp, c_wfi_safe, c_mm_store, c_fly, c_idle} = '0;
    new_phase();
    drive();
    rst = 1'b1;
    repeat (4) @(posedge clk);
    #1; rst = 1'b0;
    warmup();
    drive(); rst = 1'b0;
    for (int c = 0; c < NCYCLES; c++) begin
      #3; compare_outputs(); sample_cov();
      @(posedge clk); #1;
      if (c % 2000 == 1999) new_phase();
      drive();
    end
    report();
    $finish;
  end

  task automatic report();
    int bad;
    bad = 0;
    $display("--- coverage ---");
    $display("  merge=%0d alloc_waitSame=%0d reject=%0d drain=%0d matchInvalid=%0d fwdHit=%0d",
             c_merge, c_alloc_ws, c_reject, c_drain, c_match_inv, c_fwd_hit);
    $display("  busError=%0d uState_waitReturn=%0d waitSame=%0d fullish=%0d get=%0d put=%0d",
             c_bus_err, c_ustate_wr, c_waitsame, c_full, c_get, c_put);
    $display("  resp=%0d wfiSafe=%0d mmStore=%0d fly=%0d idle=%0d",
             c_resp, c_wfi_safe, c_mm_store, c_fly, c_idle);
    if (c_merge == 0 || c_alloc_ws == 0 || c_reject == 0 || c_drain == 0 || c_match_inv == 0 ||
        c_fwd_hit == 0 || c_bus_err == 0 || c_ustate_wr == 0 || c_waitsame == 0 || c_full == 0 ||
        c_get == 0 || c_put == 0 || c_resp == 0 || c_wfi_safe == 0 || c_mm_store == 0 ||
        c_fly == 0 || c_idle == 0) bad++;
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
  endtask
endmodule
