// DCache 双例化逐拍比对：golden DCache vs 重写件 DCache_xs（xs_DCache_core + 生成的 wrapper）。
// 两侧例化同一份子模块重写件（LoadPipe / MainPipe / MissQueue / BankedDataArray / ……，均已单独签核），
// 所以这里比的是 DCache 本体的胶水：D/B 通道分发、forward_D 拍计数、PLRU 替换、各回应打拍、错误上报、
// 预取统计、性能事件，以及 wrapper 的全部接线。
// GENERATED 区由 scripts/gen_dcache.py 从 G1 golden 端口表生成（勿手改）；其余为手写激励与覆盖。
//
// 激励（每拍在 negedge 驱动，posedge 观察握手）：
//   · 地址取自 30 行的小池（6 个 set × 5 个 tag，同一 set 的 tag 数多于 4 路 → 反复替换、写回）；
//     vaddr = paddr（恒等映射），Probe 的别名位 data[2:1] = paddr[13:12]；
//   · 3 条 load：s0 发请求，s1 给上一拍握手成功那条的 paddr，s1_kill / s2_kill 偶发；
//   · store（整行，掩码随机）、原子（发一条等回应）、CMO、forward_mshr 查询、l2_hint、wfi 段；
//   · L2 模型：A 通道 Acquire → 延迟 2..24 拍回 GrantData(2 拍)/Grant，CBO → CBOAck；
//     C 通道 Release[Data] 收完 → ReleaseAck；B 通道偶发 Probe（toN/toB/toT）；E 通道随机 ready；
//     D 消息偶发 denied / corrupt；千分之三的拍插一个非法 opcode 的"噪声" D 消息（覆盖 d_ready=0 那一支）；
//   · CtrlUnit（TL-UL 寄存器口）每约 1500 拍写一次 8 个掩码与 ctrl，注入 tag / data 伪 ECC 错误。
// 初值档（Makefile 的 INITREG）：
//   0      : +vcs+initreg+0，全设计 0，复位后全部输出逐拍全比（cmp_all=1）；
//   glue   : +vcs+initreg+config+<cfg>，cfg = 子模块 0、两侧 DCache 本层（golden 的 DCache 作用域、
//            重写的 u_core 作用域）随机 —— 子模块两侧同码，各摇各的初值只会比出与重写无关的差
//            （L2TLB lane 实测；SRAM 阵列里的随机内容也在此列），所以只对被测的这一层摇；
//            随机档下各端口在两侧第一次相等后才开比，*_bits_* 只在对应 *_valid 时比。
// 覆盖闸：各胶水事件计数 >= COV_MIN（见末尾 report），外加输出位翻转统计（只报告）。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 20;
  localparam int RESET_CYC = 20;
  int errors = 0, checks = 0, cov_fail = 0, cyc = 0;
  bit   clock = 0;
  logic reset;
  bit   cmp_all = 1;
  always #5 clock = ~clock;

  // BEGIN GENERATED(tb-ports)
  // ---- 输入（两侧共用；clock/reset 由手写区驱动；未驱动的口保持 0）----
  logic auto_cacheCtrlOpt_in_a_valid = '0;
  logic [3:0] auto_cacheCtrlOpt_in_a_bits_opcode = '0;
  logic [1:0] auto_cacheCtrlOpt_in_a_bits_size = '0;
  logic [3:0] auto_cacheCtrlOpt_in_a_bits_source = '0;
  logic [29:0] auto_cacheCtrlOpt_in_a_bits_address = '0;
  logic [7:0] auto_cacheCtrlOpt_in_a_bits_mask = '0;
  logic [63:0] auto_cacheCtrlOpt_in_a_bits_data = '0;
  logic auto_cacheCtrlOpt_in_d_ready = '0;
  logic auto_client_out_a_ready = '0;
  logic auto_client_out_b_valid = '0;
  logic [2:0] auto_client_out_b_bits_opcode = '0;
  logic [1:0] auto_client_out_b_bits_param = '0;
  logic [47:0] auto_client_out_b_bits_address = '0;
  logic [255:0] auto_client_out_b_bits_data = '0;
  logic auto_client_out_c_ready = '0;
  logic auto_client_out_d_valid = '0;
  logic [3:0] auto_client_out_d_bits_opcode = '0;
  logic [1:0] auto_client_out_d_bits_param = '0;
  logic [2:0] auto_client_out_d_bits_size = '0;
  logic [5:0] auto_client_out_d_bits_source = '0;
  logic [9:0] auto_client_out_d_bits_sink = '0;
  logic auto_client_out_d_bits_denied = '0;
  logic auto_client_out_d_bits_echo_isKeyword = '0;
  logic [255:0] auto_client_out_d_bits_data = '0;
  logic auto_client_out_d_bits_corrupt = '0;
  logic auto_client_out_e_ready = '0;
  logic [5:0] io_hartId = '0;
  logic io_l2_pf_store_only = '0;
  logic io_lsu_load_0_req_valid = '0;
  logic [4:0] io_lsu_load_0_req_bits_cmd = '0;
  logic [49:0] io_lsu_load_0_req_bits_vaddr = '0;
  logic [49:0] io_lsu_load_0_req_bits_vaddr_dup = '0;
  logic [3:0] io_lsu_load_0_req_bits_instrtype = '0;
  logic io_lsu_load_0_req_bits_isFirstIssue = '0;
  logic io_lsu_load_0_req_bits_lqIdx_flag = '0;
  logic [6:0] io_lsu_load_0_req_bits_lqIdx_value = '0;
  logic io_lsu_load_0_s1_kill_data_read = '0;
  logic io_lsu_load_0_s1_kill = '0;
  logic io_lsu_load_0_s2_kill = '0;
  logic io_lsu_load_0_is128Req = '0;
  logic [2:0] io_lsu_load_0_pf_source = '0;
  logic [47:0] io_lsu_load_0_s1_paddr_dup_lsu = '0;
  logic [47:0] io_lsu_load_0_s1_paddr_dup_dcache = '0;
  logic io_lsu_load_1_req_valid = '0;
  logic [4:0] io_lsu_load_1_req_bits_cmd = '0;
  logic [49:0] io_lsu_load_1_req_bits_vaddr = '0;
  logic [49:0] io_lsu_load_1_req_bits_vaddr_dup = '0;
  logic [3:0] io_lsu_load_1_req_bits_instrtype = '0;
  logic io_lsu_load_1_req_bits_isFirstIssue = '0;
  logic io_lsu_load_1_req_bits_lqIdx_flag = '0;
  logic [6:0] io_lsu_load_1_req_bits_lqIdx_value = '0;
  logic io_lsu_load_1_s1_kill_data_read = '0;
  logic io_lsu_load_1_s1_kill = '0;
  logic io_lsu_load_1_s2_kill = '0;
  logic io_lsu_load_1_is128Req = '0;
  logic [2:0] io_lsu_load_1_pf_source = '0;
  logic [47:0] io_lsu_load_1_s1_paddr_dup_lsu = '0;
  logic [47:0] io_lsu_load_1_s1_paddr_dup_dcache = '0;
  logic io_lsu_load_2_req_valid = '0;
  logic [4:0] io_lsu_load_2_req_bits_cmd = '0;
  logic [49:0] io_lsu_load_2_req_bits_vaddr = '0;
  logic [49:0] io_lsu_load_2_req_bits_vaddr_dup = '0;
  logic [3:0] io_lsu_load_2_req_bits_instrtype = '0;
  logic io_lsu_load_2_req_bits_isFirstIssue = '0;
  logic io_lsu_load_2_req_bits_lqIdx_flag = '0;
  logic [6:0] io_lsu_load_2_req_bits_lqIdx_value = '0;
  logic io_lsu_load_2_s1_kill_data_read = '0;
  logic io_lsu_load_2_s1_kill = '0;
  logic io_lsu_load_2_s2_kill = '0;
  logic io_lsu_load_2_is128Req = '0;
  logic [2:0] io_lsu_load_2_pf_source = '0;
  logic [47:0] io_lsu_load_2_s1_paddr_dup_lsu = '0;
  logic [47:0] io_lsu_load_2_s1_paddr_dup_dcache = '0;
  logic io_lsu_sta_0_req_valid = '0;
  logic io_lsu_sta_1_req_valid = '0;
  logic io_lsu_store_req_valid = '0;
  logic [49:0] io_lsu_store_req_bits_vaddr = '0;
  logic [47:0] io_lsu_store_req_bits_addr = '0;
  logic [511:0] io_lsu_store_req_bits_data = '0;
  logic [63:0] io_lsu_store_req_bits_mask = '0;
  logic [5:0] io_lsu_store_req_bits_id = '0;
  logic io_lsu_atomics_req_valid = '0;
  logic [4:0] io_lsu_atomics_req_bits_cmd = '0;
  logic [49:0] io_lsu_atomics_req_bits_vaddr = '0;
  logic [47:0] io_lsu_atomics_req_bits_addr = '0;
  logic [2:0] io_lsu_atomics_req_bits_word_idx = '0;
  logic [127:0] io_lsu_atomics_req_bits_amo_data = '0;
  logic [15:0] io_lsu_atomics_req_bits_amo_mask = '0;
  logic [127:0] io_lsu_atomics_req_bits_amo_cmp = '0;
  logic io_lsu_forward_mshr_0_valid = '0;
  logic [3:0] io_lsu_forward_mshr_0_mshrid = '0;
  logic [47:0] io_lsu_forward_mshr_0_paddr = '0;
  logic io_lsu_forward_mshr_1_valid = '0;
  logic [3:0] io_lsu_forward_mshr_1_mshrid = '0;
  logic [47:0] io_lsu_forward_mshr_1_paddr = '0;
  logic io_lsu_forward_mshr_2_valid = '0;
  logic [3:0] io_lsu_forward_mshr_2_mshrid = '0;
  logic [47:0] io_lsu_forward_mshr_2_paddr = '0;
  logic io_lqEmpty = '0;
  logic io_debugTopDown_robHeadVaddr_valid = '0;
  logic [49:0] io_debugTopDown_robHeadVaddr_bits = '0;
  logic io_l2_hint_valid = '0;
  logic [3:0] io_l2_hint_bits_sourceId = '0;
  logic io_cmoOpReq_valid = '0;
  logic [2:0] io_cmoOpReq_bits_opcode = '0;
  logic [63:0] io_cmoOpReq_bits_address = '0;
  logic io_cmoOpResp_ready = '0;
  logic io_wfi_wfiReq = '0;
  logic [4:0] boreChildrenBd_bore_array = '0;
  logic boreChildrenBd_bore_all = '0;
  logic boreChildrenBd_bore_req = '0;
  logic boreChildrenBd_bore_writeen = '0;
  logic boreChildrenBd_bore_be = '0;
  logic [8:0] boreChildrenBd_bore_addr = '0;
  logic [71:0] boreChildrenBd_bore_indata = '0;
  logic boreChildrenBd_bore_readen = '0;
  logic [8:0] boreChildrenBd_bore_addr_rd = '0;
  logic [5:0] boreChildrenBd_bore_1_array = '0;
  logic boreChildrenBd_bore_1_all = '0;
  logic boreChildrenBd_bore_1_req = '0;
  logic boreChildrenBd_bore_1_writeen = '0;
  logic [1:0] boreChildrenBd_bore_1_be = '0;
  logic [8:0] boreChildrenBd_bore_1_addr = '0;
  logic [85:0] boreChildrenBd_bore_1_indata = '0;
  logic boreChildrenBd_bore_1_readen = '0;
  logic [8:0] boreChildrenBd_bore_1_addr_rd = '0;
  logic sigFromSrams_bore_ram_hold = '0;
  logic sigFromSrams_bore_ram_bypass = '0;
  logic sigFromSrams_bore_ram_bp_clken = '0;
  logic sigFromSrams_bore_ram_aux_clk = '0;
  logic sigFromSrams_bore_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_ram_mcp_hold = '0;
  logic sigFromSrams_bore_cgen = '0;
  logic sigFromSrams_bore_1_ram_hold = '0;
  logic sigFromSrams_bore_1_ram_bypass = '0;
  logic sigFromSrams_bore_1_ram_bp_clken = '0;
  logic sigFromSrams_bore_1_ram_aux_clk = '0;
  logic sigFromSrams_bore_1_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_1_ram_mcp_hold = '0;
  logic sigFromSrams_bore_1_cgen = '0;
  logic sigFromSrams_bore_2_ram_hold = '0;
  logic sigFromSrams_bore_2_ram_bypass = '0;
  logic sigFromSrams_bore_2_ram_bp_clken = '0;
  logic sigFromSrams_bore_2_ram_aux_clk = '0;
  logic sigFromSrams_bore_2_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_2_ram_mcp_hold = '0;
  logic sigFromSrams_bore_2_cgen = '0;
  logic sigFromSrams_bore_3_ram_hold = '0;
  logic sigFromSrams_bore_3_ram_bypass = '0;
  logic sigFromSrams_bore_3_ram_bp_clken = '0;
  logic sigFromSrams_bore_3_ram_aux_clk = '0;
  logic sigFromSrams_bore_3_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_3_ram_mcp_hold = '0;
  logic sigFromSrams_bore_3_cgen = '0;
  logic sigFromSrams_bore_4_ram_hold = '0;
  logic sigFromSrams_bore_4_ram_bypass = '0;
  logic sigFromSrams_bore_4_ram_bp_clken = '0;
  logic sigFromSrams_bore_4_ram_aux_clk = '0;
  logic sigFromSrams_bore_4_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_4_ram_mcp_hold = '0;
  logic sigFromSrams_bore_4_cgen = '0;
  logic sigFromSrams_bore_5_ram_hold = '0;
  logic sigFromSrams_bore_5_ram_bypass = '0;
  logic sigFromSrams_bore_5_ram_bp_clken = '0;
  logic sigFromSrams_bore_5_ram_aux_clk = '0;
  logic sigFromSrams_bore_5_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_5_ram_mcp_hold = '0;
  logic sigFromSrams_bore_5_cgen = '0;
  logic sigFromSrams_bore_6_ram_hold = '0;
  logic sigFromSrams_bore_6_ram_bypass = '0;
  logic sigFromSrams_bore_6_ram_bp_clken = '0;
  logic sigFromSrams_bore_6_ram_aux_clk = '0;
  logic sigFromSrams_bore_6_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_6_ram_mcp_hold = '0;
  logic sigFromSrams_bore_6_cgen = '0;
  logic sigFromSrams_bore_7_ram_hold = '0;
  logic sigFromSrams_bore_7_ram_bypass = '0;
  logic sigFromSrams_bore_7_ram_bp_clken = '0;
  logic sigFromSrams_bore_7_ram_aux_clk = '0;
  logic sigFromSrams_bore_7_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_7_ram_mcp_hold = '0;
  logic sigFromSrams_bore_7_cgen = '0;
  logic sigFromSrams_bore_8_ram_hold = '0;
  logic sigFromSrams_bore_8_ram_bypass = '0;
  logic sigFromSrams_bore_8_ram_bp_clken = '0;
  logic sigFromSrams_bore_8_ram_aux_clk = '0;
  logic sigFromSrams_bore_8_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_8_ram_mcp_hold = '0;
  logic sigFromSrams_bore_8_cgen = '0;
  logic sigFromSrams_bore_9_ram_hold = '0;
  logic sigFromSrams_bore_9_ram_bypass = '0;
  logic sigFromSrams_bore_9_ram_bp_clken = '0;
  logic sigFromSrams_bore_9_ram_aux_clk = '0;
  logic sigFromSrams_bore_9_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_9_ram_mcp_hold = '0;
  logic sigFromSrams_bore_9_cgen = '0;
  logic sigFromSrams_bore_10_ram_hold = '0;
  logic sigFromSrams_bore_10_ram_bypass = '0;
  logic sigFromSrams_bore_10_ram_bp_clken = '0;
  logic sigFromSrams_bore_10_ram_aux_clk = '0;
  logic sigFromSrams_bore_10_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_10_ram_mcp_hold = '0;
  logic sigFromSrams_bore_10_cgen = '0;
  logic sigFromSrams_bore_11_ram_hold = '0;
  logic sigFromSrams_bore_11_ram_bypass = '0;
  logic sigFromSrams_bore_11_ram_bp_clken = '0;
  logic sigFromSrams_bore_11_ram_aux_clk = '0;
  logic sigFromSrams_bore_11_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_11_ram_mcp_hold = '0;
  logic sigFromSrams_bore_11_cgen = '0;
  logic sigFromSrams_bore_12_ram_hold = '0;
  logic sigFromSrams_bore_12_ram_bypass = '0;
  logic sigFromSrams_bore_12_ram_bp_clken = '0;
  logic sigFromSrams_bore_12_ram_aux_clk = '0;
  logic sigFromSrams_bore_12_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_12_ram_mcp_hold = '0;
  logic sigFromSrams_bore_12_cgen = '0;
  logic sigFromSrams_bore_13_ram_hold = '0;
  logic sigFromSrams_bore_13_ram_bypass = '0;
  logic sigFromSrams_bore_13_ram_bp_clken = '0;
  logic sigFromSrams_bore_13_ram_aux_clk = '0;
  logic sigFromSrams_bore_13_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_13_ram_mcp_hold = '0;
  logic sigFromSrams_bore_13_cgen = '0;
  logic sigFromSrams_bore_14_ram_hold = '0;
  logic sigFromSrams_bore_14_ram_bypass = '0;
  logic sigFromSrams_bore_14_ram_bp_clken = '0;
  logic sigFromSrams_bore_14_ram_aux_clk = '0;
  logic sigFromSrams_bore_14_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_14_ram_mcp_hold = '0;
  logic sigFromSrams_bore_14_cgen = '0;
  logic sigFromSrams_bore_15_ram_hold = '0;
  logic sigFromSrams_bore_15_ram_bypass = '0;
  logic sigFromSrams_bore_15_ram_bp_clken = '0;
  logic sigFromSrams_bore_15_ram_aux_clk = '0;
  logic sigFromSrams_bore_15_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_15_ram_mcp_hold = '0;
  logic sigFromSrams_bore_15_cgen = '0;
  logic sigFromSrams_bore_16_ram_hold = '0;
  logic sigFromSrams_bore_16_ram_bypass = '0;
  logic sigFromSrams_bore_16_ram_bp_clken = '0;
  logic sigFromSrams_bore_16_ram_aux_clk = '0;
  logic sigFromSrams_bore_16_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_16_ram_mcp_hold = '0;
  logic sigFromSrams_bore_16_cgen = '0;
  logic sigFromSrams_bore_17_ram_hold = '0;
  logic sigFromSrams_bore_17_ram_bypass = '0;
  logic sigFromSrams_bore_17_ram_bp_clken = '0;
  logic sigFromSrams_bore_17_ram_aux_clk = '0;
  logic sigFromSrams_bore_17_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_17_ram_mcp_hold = '0;
  logic sigFromSrams_bore_17_cgen = '0;
  logic sigFromSrams_bore_18_ram_hold = '0;
  logic sigFromSrams_bore_18_ram_bypass = '0;
  logic sigFromSrams_bore_18_ram_bp_clken = '0;
  logic sigFromSrams_bore_18_ram_aux_clk = '0;
  logic sigFromSrams_bore_18_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_18_ram_mcp_hold = '0;
  logic sigFromSrams_bore_18_cgen = '0;
  logic sigFromSrams_bore_19_ram_hold = '0;
  logic sigFromSrams_bore_19_ram_bypass = '0;
  logic sigFromSrams_bore_19_ram_bp_clken = '0;
  logic sigFromSrams_bore_19_ram_aux_clk = '0;
  logic sigFromSrams_bore_19_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_19_ram_mcp_hold = '0;
  logic sigFromSrams_bore_19_cgen = '0;
  logic sigFromSrams_bore_20_ram_hold = '0;
  logic sigFromSrams_bore_20_ram_bypass = '0;
  logic sigFromSrams_bore_20_ram_bp_clken = '0;
  logic sigFromSrams_bore_20_ram_aux_clk = '0;
  logic sigFromSrams_bore_20_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_20_ram_mcp_hold = '0;
  logic sigFromSrams_bore_20_cgen = '0;
  logic sigFromSrams_bore_21_ram_hold = '0;
  logic sigFromSrams_bore_21_ram_bypass = '0;
  logic sigFromSrams_bore_21_ram_bp_clken = '0;
  logic sigFromSrams_bore_21_ram_aux_clk = '0;
  logic sigFromSrams_bore_21_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_21_ram_mcp_hold = '0;
  logic sigFromSrams_bore_21_cgen = '0;
  logic sigFromSrams_bore_22_ram_hold = '0;
  logic sigFromSrams_bore_22_ram_bypass = '0;
  logic sigFromSrams_bore_22_ram_bp_clken = '0;
  logic sigFromSrams_bore_22_ram_aux_clk = '0;
  logic sigFromSrams_bore_22_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_22_ram_mcp_hold = '0;
  logic sigFromSrams_bore_22_cgen = '0;
  logic sigFromSrams_bore_23_ram_hold = '0;
  logic sigFromSrams_bore_23_ram_bypass = '0;
  logic sigFromSrams_bore_23_ram_bp_clken = '0;
  logic sigFromSrams_bore_23_ram_aux_clk = '0;
  logic sigFromSrams_bore_23_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_23_ram_mcp_hold = '0;
  logic sigFromSrams_bore_23_cgen = '0;
  logic sigFromSrams_bore_24_ram_hold = '0;
  logic sigFromSrams_bore_24_ram_bypass = '0;
  logic sigFromSrams_bore_24_ram_bp_clken = '0;
  logic sigFromSrams_bore_24_ram_aux_clk = '0;
  logic sigFromSrams_bore_24_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_24_ram_mcp_hold = '0;
  logic sigFromSrams_bore_24_cgen = '0;
  logic sigFromSrams_bore_25_ram_hold = '0;
  logic sigFromSrams_bore_25_ram_bypass = '0;
  logic sigFromSrams_bore_25_ram_bp_clken = '0;
  logic sigFromSrams_bore_25_ram_aux_clk = '0;
  logic sigFromSrams_bore_25_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_25_ram_mcp_hold = '0;
  logic sigFromSrams_bore_25_cgen = '0;
  logic sigFromSrams_bore_26_ram_hold = '0;
  logic sigFromSrams_bore_26_ram_bypass = '0;
  logic sigFromSrams_bore_26_ram_bp_clken = '0;
  logic sigFromSrams_bore_26_ram_aux_clk = '0;
  logic sigFromSrams_bore_26_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_26_ram_mcp_hold = '0;
  logic sigFromSrams_bore_26_cgen = '0;
  logic sigFromSrams_bore_27_ram_hold = '0;
  logic sigFromSrams_bore_27_ram_bypass = '0;
  logic sigFromSrams_bore_27_ram_bp_clken = '0;
  logic sigFromSrams_bore_27_ram_aux_clk = '0;
  logic sigFromSrams_bore_27_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_27_ram_mcp_hold = '0;
  logic sigFromSrams_bore_27_cgen = '0;
  logic sigFromSrams_bore_28_ram_hold = '0;
  logic sigFromSrams_bore_28_ram_bypass = '0;
  logic sigFromSrams_bore_28_ram_bp_clken = '0;
  logic sigFromSrams_bore_28_ram_aux_clk = '0;
  logic sigFromSrams_bore_28_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_28_ram_mcp_hold = '0;
  logic sigFromSrams_bore_28_cgen = '0;
  logic sigFromSrams_bore_29_ram_hold = '0;
  logic sigFromSrams_bore_29_ram_bypass = '0;
  logic sigFromSrams_bore_29_ram_bp_clken = '0;
  logic sigFromSrams_bore_29_ram_aux_clk = '0;
  logic sigFromSrams_bore_29_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_29_ram_mcp_hold = '0;
  logic sigFromSrams_bore_29_cgen = '0;
  logic sigFromSrams_bore_30_ram_hold = '0;
  logic sigFromSrams_bore_30_ram_bypass = '0;
  logic sigFromSrams_bore_30_ram_bp_clken = '0;
  logic sigFromSrams_bore_30_ram_aux_clk = '0;
  logic sigFromSrams_bore_30_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_30_ram_mcp_hold = '0;
  logic sigFromSrams_bore_30_cgen = '0;
  logic sigFromSrams_bore_31_ram_hold = '0;
  logic sigFromSrams_bore_31_ram_bypass = '0;
  logic sigFromSrams_bore_31_ram_bp_clken = '0;
  logic sigFromSrams_bore_31_ram_aux_clk = '0;
  logic sigFromSrams_bore_31_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_31_ram_mcp_hold = '0;
  logic sigFromSrams_bore_31_cgen = '0;
  logic sigFromSrams_bore_32_ram_hold = '0;
  logic sigFromSrams_bore_32_ram_bypass = '0;
  logic sigFromSrams_bore_32_ram_bp_clken = '0;
  logic sigFromSrams_bore_32_ram_aux_clk = '0;
  logic sigFromSrams_bore_32_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_32_ram_mcp_hold = '0;
  logic sigFromSrams_bore_32_cgen = '0;
  logic sigFromSrams_bore_33_ram_hold = '0;
  logic sigFromSrams_bore_33_ram_bypass = '0;
  logic sigFromSrams_bore_33_ram_bp_clken = '0;
  logic sigFromSrams_bore_33_ram_aux_clk = '0;
  logic sigFromSrams_bore_33_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_33_ram_mcp_hold = '0;
  logic sigFromSrams_bore_33_cgen = '0;
  logic sigFromSrams_bore_34_ram_hold = '0;
  logic sigFromSrams_bore_34_ram_bypass = '0;
  logic sigFromSrams_bore_34_ram_bp_clken = '0;
  logic sigFromSrams_bore_34_ram_aux_clk = '0;
  logic sigFromSrams_bore_34_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_34_ram_mcp_hold = '0;
  logic sigFromSrams_bore_34_cgen = '0;
  logic sigFromSrams_bore_35_ram_hold = '0;
  logic sigFromSrams_bore_35_ram_bypass = '0;
  logic sigFromSrams_bore_35_ram_bp_clken = '0;
  logic sigFromSrams_bore_35_ram_aux_clk = '0;
  logic sigFromSrams_bore_35_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_35_ram_mcp_hold = '0;
  logic sigFromSrams_bore_35_cgen = '0;
  logic sigFromSrams_bore_36_ram_hold = '0;
  logic sigFromSrams_bore_36_ram_bypass = '0;
  logic sigFromSrams_bore_36_ram_bp_clken = '0;
  logic sigFromSrams_bore_36_ram_aux_clk = '0;
  logic sigFromSrams_bore_36_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_36_ram_mcp_hold = '0;
  logic sigFromSrams_bore_36_cgen = '0;
  logic sigFromSrams_bore_37_ram_hold = '0;
  logic sigFromSrams_bore_37_ram_bypass = '0;
  logic sigFromSrams_bore_37_ram_bp_clken = '0;
  logic sigFromSrams_bore_37_ram_aux_clk = '0;
  logic sigFromSrams_bore_37_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_37_ram_mcp_hold = '0;
  logic sigFromSrams_bore_37_cgen = '0;
  logic sigFromSrams_bore_38_ram_hold = '0;
  logic sigFromSrams_bore_38_ram_bypass = '0;
  logic sigFromSrams_bore_38_ram_bp_clken = '0;
  logic sigFromSrams_bore_38_ram_aux_clk = '0;
  logic sigFromSrams_bore_38_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_38_ram_mcp_hold = '0;
  logic sigFromSrams_bore_38_cgen = '0;
  logic sigFromSrams_bore_39_ram_hold = '0;
  logic sigFromSrams_bore_39_ram_bypass = '0;
  logic sigFromSrams_bore_39_ram_bp_clken = '0;
  logic sigFromSrams_bore_39_ram_aux_clk = '0;
  logic sigFromSrams_bore_39_ram_aux_ckbp = '0;
  logic sigFromSrams_bore_39_ram_mcp_hold = '0;
  logic sigFromSrams_bore_39_cgen = '0;
  // ---- 输出（g_ = golden，i_ = 重写）----
  wire  g_auto_cacheCtrlOpt_in_a_ready, i_auto_cacheCtrlOpt_in_a_ready;
  wire  g_auto_cacheCtrlOpt_in_d_valid, i_auto_cacheCtrlOpt_in_d_valid;
  wire  [3:0] g_auto_cacheCtrlOpt_in_d_bits_opcode, i_auto_cacheCtrlOpt_in_d_bits_opcode;
  wire  [1:0] g_auto_cacheCtrlOpt_in_d_bits_size, i_auto_cacheCtrlOpt_in_d_bits_size;
  wire  [3:0] g_auto_cacheCtrlOpt_in_d_bits_source, i_auto_cacheCtrlOpt_in_d_bits_source;
  wire  [63:0] g_auto_cacheCtrlOpt_in_d_bits_data, i_auto_cacheCtrlOpt_in_d_bits_data;
  wire  g_auto_client_out_a_valid, i_auto_client_out_a_valid;
  wire  [3:0] g_auto_client_out_a_bits_opcode, i_auto_client_out_a_bits_opcode;
  wire  [2:0] g_auto_client_out_a_bits_param, i_auto_client_out_a_bits_param;
  wire  [2:0] g_auto_client_out_a_bits_size, i_auto_client_out_a_bits_size;
  wire  [5:0] g_auto_client_out_a_bits_source, i_auto_client_out_a_bits_source;
  wire  [47:0] g_auto_client_out_a_bits_address, i_auto_client_out_a_bits_address;
  wire  [1:0] g_auto_client_out_a_bits_user_alias, i_auto_client_out_a_bits_user_alias;
  wire  [43:0] g_auto_client_out_a_bits_user_vaddr, i_auto_client_out_a_bits_user_vaddr;
  wire  [4:0] g_auto_client_out_a_bits_user_reqSource, i_auto_client_out_a_bits_user_reqSource;
  wire  g_auto_client_out_a_bits_user_needHint, i_auto_client_out_a_bits_user_needHint;
  wire  g_auto_client_out_a_bits_echo_isKeyword, i_auto_client_out_a_bits_echo_isKeyword;
  wire  [31:0] g_auto_client_out_a_bits_mask, i_auto_client_out_a_bits_mask;
  wire  g_auto_client_out_b_ready, i_auto_client_out_b_ready;
  wire  g_auto_client_out_c_valid, i_auto_client_out_c_valid;
  wire  [2:0] g_auto_client_out_c_bits_opcode, i_auto_client_out_c_bits_opcode;
  wire  [2:0] g_auto_client_out_c_bits_param, i_auto_client_out_c_bits_param;
  wire  [2:0] g_auto_client_out_c_bits_size, i_auto_client_out_c_bits_size;
  wire  [5:0] g_auto_client_out_c_bits_source, i_auto_client_out_c_bits_source;
  wire  [47:0] g_auto_client_out_c_bits_address, i_auto_client_out_c_bits_address;
  wire  [255:0] g_auto_client_out_c_bits_data, i_auto_client_out_c_bits_data;
  wire  g_auto_client_out_c_bits_corrupt, i_auto_client_out_c_bits_corrupt;
  wire  g_auto_client_out_d_ready, i_auto_client_out_d_ready;
  wire  g_auto_client_out_e_valid, i_auto_client_out_e_valid;
  wire  [9:0] g_auto_client_out_e_bits_sink, i_auto_client_out_e_bits_sink;
  wire  g_io_lsu_load_0_req_ready, i_io_lsu_load_0_req_ready;
  wire  g_io_lsu_load_0_resp_valid, i_io_lsu_load_0_resp_valid;
  wire  [127:0] g_io_lsu_load_0_resp_bits_data, i_io_lsu_load_0_resp_bits_data;
  wire  [127:0] g_io_lsu_load_0_resp_bits_data_delayed, i_io_lsu_load_0_resp_bits_data_delayed;
  wire  g_io_lsu_load_0_resp_bits_miss, i_io_lsu_load_0_resp_bits_miss;
  wire  [3:0] g_io_lsu_load_0_resp_bits_mshr_id, i_io_lsu_load_0_resp_bits_mshr_id;
  wire  [2:0] g_io_lsu_load_0_resp_bits_meta_prefetch, i_io_lsu_load_0_resp_bits_meta_prefetch;
  wire  g_io_lsu_load_0_resp_bits_handled, i_io_lsu_load_0_resp_bits_handled;
  wire  g_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied, i_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied;
  wire  g_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt, i_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt;
  wire  g_io_lsu_load_0_s2_bank_conflict, i_io_lsu_load_0_s2_bank_conflict;
  wire  g_io_lsu_load_0_s2_mq_nack, i_io_lsu_load_0_s2_mq_nack;
  wire  g_io_lsu_load_1_req_ready, i_io_lsu_load_1_req_ready;
  wire  g_io_lsu_load_1_resp_valid, i_io_lsu_load_1_resp_valid;
  wire  [127:0] g_io_lsu_load_1_resp_bits_data, i_io_lsu_load_1_resp_bits_data;
  wire  g_io_lsu_load_1_resp_bits_miss, i_io_lsu_load_1_resp_bits_miss;
  wire  [3:0] g_io_lsu_load_1_resp_bits_mshr_id, i_io_lsu_load_1_resp_bits_mshr_id;
  wire  [2:0] g_io_lsu_load_1_resp_bits_meta_prefetch, i_io_lsu_load_1_resp_bits_meta_prefetch;
  wire  g_io_lsu_load_1_resp_bits_handled, i_io_lsu_load_1_resp_bits_handled;
  wire  g_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied, i_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied;
  wire  g_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt, i_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt;
  wire  g_io_lsu_load_1_s2_bank_conflict, i_io_lsu_load_1_s2_bank_conflict;
  wire  g_io_lsu_load_1_s2_mq_nack, i_io_lsu_load_1_s2_mq_nack;
  wire  g_io_lsu_load_2_req_ready, i_io_lsu_load_2_req_ready;
  wire  g_io_lsu_load_2_resp_valid, i_io_lsu_load_2_resp_valid;
  wire  [127:0] g_io_lsu_load_2_resp_bits_data, i_io_lsu_load_2_resp_bits_data;
  wire  g_io_lsu_load_2_resp_bits_miss, i_io_lsu_load_2_resp_bits_miss;
  wire  [3:0] g_io_lsu_load_2_resp_bits_mshr_id, i_io_lsu_load_2_resp_bits_mshr_id;
  wire  [2:0] g_io_lsu_load_2_resp_bits_meta_prefetch, i_io_lsu_load_2_resp_bits_meta_prefetch;
  wire  g_io_lsu_load_2_resp_bits_handled, i_io_lsu_load_2_resp_bits_handled;
  wire  g_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied, i_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied;
  wire  g_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt, i_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt;
  wire  g_io_lsu_load_2_s2_bank_conflict, i_io_lsu_load_2_s2_bank_conflict;
  wire  g_io_lsu_load_2_s2_mq_nack, i_io_lsu_load_2_s2_mq_nack;
  wire  g_io_lsu_tl_d_channel_valid, i_io_lsu_tl_d_channel_valid;
  wire  [3:0] g_io_lsu_tl_d_channel_mshrid, i_io_lsu_tl_d_channel_mshrid;
  wire  g_io_lsu_store_req_ready, i_io_lsu_store_req_ready;
  wire  g_io_lsu_store_main_pipe_hit_resp_valid, i_io_lsu_store_main_pipe_hit_resp_valid;
  wire  [5:0] g_io_lsu_store_main_pipe_hit_resp_bits_id, i_io_lsu_store_main_pipe_hit_resp_bits_id;
  wire  g_io_lsu_store_replay_resp_valid, i_io_lsu_store_replay_resp_valid;
  wire  [5:0] g_io_lsu_store_replay_resp_bits_id, i_io_lsu_store_replay_resp_bits_id;
  wire  g_io_lsu_atomics_req_ready, i_io_lsu_atomics_req_ready;
  wire  g_io_lsu_atomics_resp_valid, i_io_lsu_atomics_resp_valid;
  wire  [127:0] g_io_lsu_atomics_resp_bits_data, i_io_lsu_atomics_resp_bits_data;
  wire  g_io_lsu_atomics_resp_bits_miss, i_io_lsu_atomics_resp_bits_miss;
  wire  g_io_lsu_atomics_resp_bits_replay, i_io_lsu_atomics_resp_bits_replay;
  wire  g_io_lsu_atomics_resp_bits_tl_error_tl_denied, i_io_lsu_atomics_resp_bits_tl_error_tl_denied;
  wire  g_io_lsu_atomics_resp_bits_tl_error_tl_corrupt, i_io_lsu_atomics_resp_bits_tl_error_tl_corrupt;
  wire  [5:0] g_io_lsu_atomics_resp_bits_id, i_io_lsu_atomics_resp_bits_id;
  wire  g_io_lsu_atomics_block_lr, i_io_lsu_atomics_block_lr;
  wire  g_io_lsu_release_valid, i_io_lsu_release_valid;
  wire  [47:0] g_io_lsu_release_bits_paddr, i_io_lsu_release_bits_paddr;
  wire  g_io_lsu_forward_D_0_valid, i_io_lsu_forward_D_0_valid;
  wire  [255:0] g_io_lsu_forward_D_0_data, i_io_lsu_forward_D_0_data;
  wire  [3:0] g_io_lsu_forward_D_0_mshrid, i_io_lsu_forward_D_0_mshrid;
  wire  g_io_lsu_forward_D_0_last, i_io_lsu_forward_D_0_last;
  wire  g_io_lsu_forward_D_0_denied, i_io_lsu_forward_D_0_denied;
  wire  g_io_lsu_forward_D_0_corrupt, i_io_lsu_forward_D_0_corrupt;
  wire  g_io_lsu_forward_D_1_valid, i_io_lsu_forward_D_1_valid;
  wire  [255:0] g_io_lsu_forward_D_1_data, i_io_lsu_forward_D_1_data;
  wire  [3:0] g_io_lsu_forward_D_1_mshrid, i_io_lsu_forward_D_1_mshrid;
  wire  g_io_lsu_forward_D_1_last, i_io_lsu_forward_D_1_last;
  wire  g_io_lsu_forward_D_1_denied, i_io_lsu_forward_D_1_denied;
  wire  g_io_lsu_forward_D_1_corrupt, i_io_lsu_forward_D_1_corrupt;
  wire  g_io_lsu_forward_D_2_valid, i_io_lsu_forward_D_2_valid;
  wire  [255:0] g_io_lsu_forward_D_2_data, i_io_lsu_forward_D_2_data;
  wire  [3:0] g_io_lsu_forward_D_2_mshrid, i_io_lsu_forward_D_2_mshrid;
  wire  g_io_lsu_forward_D_2_last, i_io_lsu_forward_D_2_last;
  wire  g_io_lsu_forward_D_2_denied, i_io_lsu_forward_D_2_denied;
  wire  g_io_lsu_forward_D_2_corrupt, i_io_lsu_forward_D_2_corrupt;
  wire  g_io_lsu_forward_mshr_0_forward_mshr, i_io_lsu_forward_mshr_0_forward_mshr;
  wire  [7:0] g_io_lsu_forward_mshr_0_forwardData_0, i_io_lsu_forward_mshr_0_forwardData_0;
  wire  [7:0] g_io_lsu_forward_mshr_0_forwardData_1, i_io_lsu_forward_mshr_0_forwardData_1;
  wire  [7:0] g_io_lsu_forward_mshr_0_forwardData_2, i_io_lsu_forward_mshr_0_forwardData_2;
  wire  [7:0] g_io_lsu_forward_mshr_0_forwardData_3, i_io_lsu_forward_mshr_0_forwardData_3;
  wire  [7:0] g_io_lsu_forward_mshr_0_forwardData_4, i_io_lsu_forward_mshr_0_forwardData_4;
  wire  [7:0] g_io_lsu_forward_mshr_0_forwardData_5, i_io_lsu_forward_mshr_0_forwardData_5;
  wire  [7:0] g_io_lsu_forward_mshr_0_forwardData_6, i_io_lsu_forward_mshr_0_forwardData_6;
  wire  [7:0] g_io_lsu_forward_mshr_0_forwardData_7, i_io_lsu_forward_mshr_0_forwardData_7;
  wire  [7:0] g_io_lsu_forward_mshr_0_forwardData_8, i_io_lsu_forward_mshr_0_forwardData_8;
  wire  [7:0] g_io_lsu_forward_mshr_0_forwardData_9, i_io_lsu_forward_mshr_0_forwardData_9;
  wire  [7:0] g_io_lsu_forward_mshr_0_forwardData_10, i_io_lsu_forward_mshr_0_forwardData_10;
  wire  [7:0] g_io_lsu_forward_mshr_0_forwardData_11, i_io_lsu_forward_mshr_0_forwardData_11;
  wire  [7:0] g_io_lsu_forward_mshr_0_forwardData_12, i_io_lsu_forward_mshr_0_forwardData_12;
  wire  [7:0] g_io_lsu_forward_mshr_0_forwardData_13, i_io_lsu_forward_mshr_0_forwardData_13;
  wire  [7:0] g_io_lsu_forward_mshr_0_forwardData_14, i_io_lsu_forward_mshr_0_forwardData_14;
  wire  [7:0] g_io_lsu_forward_mshr_0_forwardData_15, i_io_lsu_forward_mshr_0_forwardData_15;
  wire  g_io_lsu_forward_mshr_0_forward_result_valid, i_io_lsu_forward_mshr_0_forward_result_valid;
  wire  g_io_lsu_forward_mshr_0_denied, i_io_lsu_forward_mshr_0_denied;
  wire  g_io_lsu_forward_mshr_0_corrupt, i_io_lsu_forward_mshr_0_corrupt;
  wire  g_io_lsu_forward_mshr_1_forward_mshr, i_io_lsu_forward_mshr_1_forward_mshr;
  wire  [7:0] g_io_lsu_forward_mshr_1_forwardData_0, i_io_lsu_forward_mshr_1_forwardData_0;
  wire  [7:0] g_io_lsu_forward_mshr_1_forwardData_1, i_io_lsu_forward_mshr_1_forwardData_1;
  wire  [7:0] g_io_lsu_forward_mshr_1_forwardData_2, i_io_lsu_forward_mshr_1_forwardData_2;
  wire  [7:0] g_io_lsu_forward_mshr_1_forwardData_3, i_io_lsu_forward_mshr_1_forwardData_3;
  wire  [7:0] g_io_lsu_forward_mshr_1_forwardData_4, i_io_lsu_forward_mshr_1_forwardData_4;
  wire  [7:0] g_io_lsu_forward_mshr_1_forwardData_5, i_io_lsu_forward_mshr_1_forwardData_5;
  wire  [7:0] g_io_lsu_forward_mshr_1_forwardData_6, i_io_lsu_forward_mshr_1_forwardData_6;
  wire  [7:0] g_io_lsu_forward_mshr_1_forwardData_7, i_io_lsu_forward_mshr_1_forwardData_7;
  wire  [7:0] g_io_lsu_forward_mshr_1_forwardData_8, i_io_lsu_forward_mshr_1_forwardData_8;
  wire  [7:0] g_io_lsu_forward_mshr_1_forwardData_9, i_io_lsu_forward_mshr_1_forwardData_9;
  wire  [7:0] g_io_lsu_forward_mshr_1_forwardData_10, i_io_lsu_forward_mshr_1_forwardData_10;
  wire  [7:0] g_io_lsu_forward_mshr_1_forwardData_11, i_io_lsu_forward_mshr_1_forwardData_11;
  wire  [7:0] g_io_lsu_forward_mshr_1_forwardData_12, i_io_lsu_forward_mshr_1_forwardData_12;
  wire  [7:0] g_io_lsu_forward_mshr_1_forwardData_13, i_io_lsu_forward_mshr_1_forwardData_13;
  wire  [7:0] g_io_lsu_forward_mshr_1_forwardData_14, i_io_lsu_forward_mshr_1_forwardData_14;
  wire  [7:0] g_io_lsu_forward_mshr_1_forwardData_15, i_io_lsu_forward_mshr_1_forwardData_15;
  wire  g_io_lsu_forward_mshr_1_forward_result_valid, i_io_lsu_forward_mshr_1_forward_result_valid;
  wire  g_io_lsu_forward_mshr_1_denied, i_io_lsu_forward_mshr_1_denied;
  wire  g_io_lsu_forward_mshr_1_corrupt, i_io_lsu_forward_mshr_1_corrupt;
  wire  g_io_lsu_forward_mshr_2_forward_mshr, i_io_lsu_forward_mshr_2_forward_mshr;
  wire  [7:0] g_io_lsu_forward_mshr_2_forwardData_0, i_io_lsu_forward_mshr_2_forwardData_0;
  wire  [7:0] g_io_lsu_forward_mshr_2_forwardData_1, i_io_lsu_forward_mshr_2_forwardData_1;
  wire  [7:0] g_io_lsu_forward_mshr_2_forwardData_2, i_io_lsu_forward_mshr_2_forwardData_2;
  wire  [7:0] g_io_lsu_forward_mshr_2_forwardData_3, i_io_lsu_forward_mshr_2_forwardData_3;
  wire  [7:0] g_io_lsu_forward_mshr_2_forwardData_4, i_io_lsu_forward_mshr_2_forwardData_4;
  wire  [7:0] g_io_lsu_forward_mshr_2_forwardData_5, i_io_lsu_forward_mshr_2_forwardData_5;
  wire  [7:0] g_io_lsu_forward_mshr_2_forwardData_6, i_io_lsu_forward_mshr_2_forwardData_6;
  wire  [7:0] g_io_lsu_forward_mshr_2_forwardData_7, i_io_lsu_forward_mshr_2_forwardData_7;
  wire  [7:0] g_io_lsu_forward_mshr_2_forwardData_8, i_io_lsu_forward_mshr_2_forwardData_8;
  wire  [7:0] g_io_lsu_forward_mshr_2_forwardData_9, i_io_lsu_forward_mshr_2_forwardData_9;
  wire  [7:0] g_io_lsu_forward_mshr_2_forwardData_10, i_io_lsu_forward_mshr_2_forwardData_10;
  wire  [7:0] g_io_lsu_forward_mshr_2_forwardData_11, i_io_lsu_forward_mshr_2_forwardData_11;
  wire  [7:0] g_io_lsu_forward_mshr_2_forwardData_12, i_io_lsu_forward_mshr_2_forwardData_12;
  wire  [7:0] g_io_lsu_forward_mshr_2_forwardData_13, i_io_lsu_forward_mshr_2_forwardData_13;
  wire  [7:0] g_io_lsu_forward_mshr_2_forwardData_14, i_io_lsu_forward_mshr_2_forwardData_14;
  wire  [7:0] g_io_lsu_forward_mshr_2_forwardData_15, i_io_lsu_forward_mshr_2_forwardData_15;
  wire  g_io_lsu_forward_mshr_2_forward_result_valid, i_io_lsu_forward_mshr_2_forward_result_valid;
  wire  g_io_lsu_forward_mshr_2_denied, i_io_lsu_forward_mshr_2_denied;
  wire  g_io_lsu_forward_mshr_2_corrupt, i_io_lsu_forward_mshr_2_corrupt;
  wire  g_io_error_valid, i_io_error_valid;
  wire  [47:0] g_io_error_bits_paddr, i_io_error_bits_paddr;
  wire  g_io_error_bits_report_to_beu, i_io_error_bits_report_to_beu;
  wire  g_io_pf_ctrl_enable, i_io_pf_ctrl_enable;
  wire  g_io_pf_ctrl_confidence, i_io_pf_ctrl_confidence;
  wire  g_io_sms_agt_evict_req_valid, i_io_sms_agt_evict_req_valid;
  wire  [49:0] g_io_sms_agt_evict_req_bits_vaddr, i_io_sms_agt_evict_req_bits_vaddr;
  wire  g_io_debugTopDown_robHeadMissInDCache, i_io_debugTopDown_robHeadMissInDCache;
  wire  g_io_cmoOpReq_ready, i_io_cmoOpReq_ready;
  wire  g_io_cmoOpResp_valid, i_io_cmoOpResp_valid;
  wire  g_io_cmoOpResp_bits_denied, i_io_cmoOpResp_bits_denied;
  wire  g_io_cmoOpResp_bits_corrupt, i_io_cmoOpResp_bits_corrupt;
  wire  g_io_l1Miss, i_io_l1Miss;
  wire  g_io_wfi_wfiSafe, i_io_wfi_wfiSafe;
  wire  [5:0] g_io_perf_0_value, i_io_perf_0_value;
  wire  [5:0] g_io_perf_1_value, i_io_perf_1_value;
  wire  [5:0] g_io_perf_2_value, i_io_perf_2_value;
  wire  [5:0] g_io_perf_3_value, i_io_perf_3_value;
  wire  [5:0] g_io_perf_4_value, i_io_perf_4_value;
  wire  [5:0] g_io_perf_5_value, i_io_perf_5_value;
  wire  [5:0] g_io_perf_6_value, i_io_perf_6_value;
  wire  [5:0] g_io_perf_7_value, i_io_perf_7_value;
  wire  [5:0] g_io_perf_8_value, i_io_perf_8_value;
  wire  [5:0] g_io_perf_9_value, i_io_perf_9_value;
  wire  [5:0] g_io_perf_10_value, i_io_perf_10_value;
  wire  [5:0] g_io_perf_11_value, i_io_perf_11_value;
  wire  [5:0] g_io_perf_12_value, i_io_perf_12_value;
  wire  [5:0] g_io_perf_13_value, i_io_perf_13_value;
  wire  [5:0] g_io_perf_14_value, i_io_perf_14_value;
  wire  [5:0] g_io_perf_15_value, i_io_perf_15_value;
  wire  [5:0] g_io_perf_16_value, i_io_perf_16_value;
  wire  [5:0] g_io_perf_17_value, i_io_perf_17_value;
  wire  [5:0] g_io_perf_18_value, i_io_perf_18_value;
  wire  [5:0] g_io_perf_19_value, i_io_perf_19_value;
  wire  [5:0] g_io_perf_20_value, i_io_perf_20_value;
  wire  [5:0] g_io_perf_21_value, i_io_perf_21_value;
  wire  [5:0] g_io_perf_22_value, i_io_perf_22_value;
  wire  [5:0] g_io_perf_23_value, i_io_perf_23_value;
  wire  [5:0] g_io_perf_24_value, i_io_perf_24_value;
  wire  [5:0] g_io_perf_25_value, i_io_perf_25_value;
  wire  [5:0] g_io_perf_26_value, i_io_perf_26_value;
  wire  [5:0] g_io_perf_27_value, i_io_perf_27_value;
  wire  [5:0] g_io_perf_28_value, i_io_perf_28_value;
  wire  [5:0] g_io_perf_29_value, i_io_perf_29_value;
  wire  [5:0] g_io_perf_30_value, i_io_perf_30_value;
  wire  [5:0] g_io_perf_31_value, i_io_perf_31_value;
  wire  [5:0] g_io_perf_32_value, i_io_perf_32_value;
  wire  [5:0] g_io_perf_33_value, i_io_perf_33_value;
  wire  [5:0] g_io_perf_34_value, i_io_perf_34_value;
  wire  [5:0] g_io_perf_35_value, i_io_perf_35_value;
  wire  [5:0] g_io_perf_36_value, i_io_perf_36_value;
  wire  [5:0] g_io_perf_37_value, i_io_perf_37_value;
  wire  [5:0] g_io_perf_38_value, i_io_perf_38_value;
  wire  [5:0] g_io_perf_39_value, i_io_perf_39_value;
  wire  g_boreChildrenBd_bore_ack, i_boreChildrenBd_bore_ack;
  wire  [71:0] g_boreChildrenBd_bore_outdata, i_boreChildrenBd_bore_outdata;
  wire  g_boreChildrenBd_bore_1_ack, i_boreChildrenBd_bore_1_ack;
  wire  [85:0] g_boreChildrenBd_bore_1_outdata, i_boreChildrenBd_bore_1_outdata;
  wire  [600:0] g_gatewayIn_packed_41_bore, i_gatewayIn_packed_41_bore;
  DCache u_gold (
    .clock(clock),
    .reset(reset),
    .auto_cacheCtrlOpt_in_a_ready(g_auto_cacheCtrlOpt_in_a_ready),
    .auto_cacheCtrlOpt_in_a_valid(auto_cacheCtrlOpt_in_a_valid),
    .auto_cacheCtrlOpt_in_a_bits_opcode(auto_cacheCtrlOpt_in_a_bits_opcode),
    .auto_cacheCtrlOpt_in_a_bits_size(auto_cacheCtrlOpt_in_a_bits_size),
    .auto_cacheCtrlOpt_in_a_bits_source(auto_cacheCtrlOpt_in_a_bits_source),
    .auto_cacheCtrlOpt_in_a_bits_address(auto_cacheCtrlOpt_in_a_bits_address),
    .auto_cacheCtrlOpt_in_a_bits_mask(auto_cacheCtrlOpt_in_a_bits_mask),
    .auto_cacheCtrlOpt_in_a_bits_data(auto_cacheCtrlOpt_in_a_bits_data),
    .auto_cacheCtrlOpt_in_d_ready(auto_cacheCtrlOpt_in_d_ready),
    .auto_cacheCtrlOpt_in_d_valid(g_auto_cacheCtrlOpt_in_d_valid),
    .auto_cacheCtrlOpt_in_d_bits_opcode(g_auto_cacheCtrlOpt_in_d_bits_opcode),
    .auto_cacheCtrlOpt_in_d_bits_size(g_auto_cacheCtrlOpt_in_d_bits_size),
    .auto_cacheCtrlOpt_in_d_bits_source(g_auto_cacheCtrlOpt_in_d_bits_source),
    .auto_cacheCtrlOpt_in_d_bits_data(g_auto_cacheCtrlOpt_in_d_bits_data),
    .auto_client_out_a_ready(auto_client_out_a_ready),
    .auto_client_out_a_valid(g_auto_client_out_a_valid),
    .auto_client_out_a_bits_opcode(g_auto_client_out_a_bits_opcode),
    .auto_client_out_a_bits_param(g_auto_client_out_a_bits_param),
    .auto_client_out_a_bits_size(g_auto_client_out_a_bits_size),
    .auto_client_out_a_bits_source(g_auto_client_out_a_bits_source),
    .auto_client_out_a_bits_address(g_auto_client_out_a_bits_address),
    .auto_client_out_a_bits_user_alias(g_auto_client_out_a_bits_user_alias),
    .auto_client_out_a_bits_user_vaddr(g_auto_client_out_a_bits_user_vaddr),
    .auto_client_out_a_bits_user_reqSource(g_auto_client_out_a_bits_user_reqSource),
    .auto_client_out_a_bits_user_needHint(g_auto_client_out_a_bits_user_needHint),
    .auto_client_out_a_bits_echo_isKeyword(g_auto_client_out_a_bits_echo_isKeyword),
    .auto_client_out_a_bits_mask(g_auto_client_out_a_bits_mask),
    .auto_client_out_b_ready(g_auto_client_out_b_ready),
    .auto_client_out_b_valid(auto_client_out_b_valid),
    .auto_client_out_b_bits_opcode(auto_client_out_b_bits_opcode),
    .auto_client_out_b_bits_param(auto_client_out_b_bits_param),
    .auto_client_out_b_bits_address(auto_client_out_b_bits_address),
    .auto_client_out_b_bits_data(auto_client_out_b_bits_data),
    .auto_client_out_c_ready(auto_client_out_c_ready),
    .auto_client_out_c_valid(g_auto_client_out_c_valid),
    .auto_client_out_c_bits_opcode(g_auto_client_out_c_bits_opcode),
    .auto_client_out_c_bits_param(g_auto_client_out_c_bits_param),
    .auto_client_out_c_bits_size(g_auto_client_out_c_bits_size),
    .auto_client_out_c_bits_source(g_auto_client_out_c_bits_source),
    .auto_client_out_c_bits_address(g_auto_client_out_c_bits_address),
    .auto_client_out_c_bits_data(g_auto_client_out_c_bits_data),
    .auto_client_out_c_bits_corrupt(g_auto_client_out_c_bits_corrupt),
    .auto_client_out_d_ready(g_auto_client_out_d_ready),
    .auto_client_out_d_valid(auto_client_out_d_valid),
    .auto_client_out_d_bits_opcode(auto_client_out_d_bits_opcode),
    .auto_client_out_d_bits_param(auto_client_out_d_bits_param),
    .auto_client_out_d_bits_size(auto_client_out_d_bits_size),
    .auto_client_out_d_bits_source(auto_client_out_d_bits_source),
    .auto_client_out_d_bits_sink(auto_client_out_d_bits_sink),
    .auto_client_out_d_bits_denied(auto_client_out_d_bits_denied),
    .auto_client_out_d_bits_echo_isKeyword(auto_client_out_d_bits_echo_isKeyword),
    .auto_client_out_d_bits_data(auto_client_out_d_bits_data),
    .auto_client_out_d_bits_corrupt(auto_client_out_d_bits_corrupt),
    .auto_client_out_e_ready(auto_client_out_e_ready),
    .auto_client_out_e_valid(g_auto_client_out_e_valid),
    .auto_client_out_e_bits_sink(g_auto_client_out_e_bits_sink),
    .io_hartId(io_hartId),
    .io_l2_pf_store_only(io_l2_pf_store_only),
    .io_lsu_load_0_req_ready(g_io_lsu_load_0_req_ready),
    .io_lsu_load_0_req_valid(io_lsu_load_0_req_valid),
    .io_lsu_load_0_req_bits_cmd(io_lsu_load_0_req_bits_cmd),
    .io_lsu_load_0_req_bits_vaddr(io_lsu_load_0_req_bits_vaddr),
    .io_lsu_load_0_req_bits_vaddr_dup(io_lsu_load_0_req_bits_vaddr_dup),
    .io_lsu_load_0_req_bits_instrtype(io_lsu_load_0_req_bits_instrtype),
    .io_lsu_load_0_req_bits_isFirstIssue(io_lsu_load_0_req_bits_isFirstIssue),
    .io_lsu_load_0_req_bits_lqIdx_flag(io_lsu_load_0_req_bits_lqIdx_flag),
    .io_lsu_load_0_req_bits_lqIdx_value(io_lsu_load_0_req_bits_lqIdx_value),
    .io_lsu_load_0_resp_valid(g_io_lsu_load_0_resp_valid),
    .io_lsu_load_0_resp_bits_data(g_io_lsu_load_0_resp_bits_data),
    .io_lsu_load_0_resp_bits_data_delayed(g_io_lsu_load_0_resp_bits_data_delayed),
    .io_lsu_load_0_resp_bits_miss(g_io_lsu_load_0_resp_bits_miss),
    .io_lsu_load_0_resp_bits_mshr_id(g_io_lsu_load_0_resp_bits_mshr_id),
    .io_lsu_load_0_resp_bits_meta_prefetch(g_io_lsu_load_0_resp_bits_meta_prefetch),
    .io_lsu_load_0_resp_bits_handled(g_io_lsu_load_0_resp_bits_handled),
    .io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied(g_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied),
    .io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt(g_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt),
    .io_lsu_load_0_s1_kill_data_read(io_lsu_load_0_s1_kill_data_read),
    .io_lsu_load_0_s1_kill(io_lsu_load_0_s1_kill),
    .io_lsu_load_0_s2_kill(io_lsu_load_0_s2_kill),
    .io_lsu_load_0_is128Req(io_lsu_load_0_is128Req),
    .io_lsu_load_0_pf_source(io_lsu_load_0_pf_source),
    .io_lsu_load_0_s1_paddr_dup_lsu(io_lsu_load_0_s1_paddr_dup_lsu),
    .io_lsu_load_0_s1_paddr_dup_dcache(io_lsu_load_0_s1_paddr_dup_dcache),
    .io_lsu_load_0_s2_bank_conflict(g_io_lsu_load_0_s2_bank_conflict),
    .io_lsu_load_0_s2_mq_nack(g_io_lsu_load_0_s2_mq_nack),
    .io_lsu_load_1_req_ready(g_io_lsu_load_1_req_ready),
    .io_lsu_load_1_req_valid(io_lsu_load_1_req_valid),
    .io_lsu_load_1_req_bits_cmd(io_lsu_load_1_req_bits_cmd),
    .io_lsu_load_1_req_bits_vaddr(io_lsu_load_1_req_bits_vaddr),
    .io_lsu_load_1_req_bits_vaddr_dup(io_lsu_load_1_req_bits_vaddr_dup),
    .io_lsu_load_1_req_bits_instrtype(io_lsu_load_1_req_bits_instrtype),
    .io_lsu_load_1_req_bits_isFirstIssue(io_lsu_load_1_req_bits_isFirstIssue),
    .io_lsu_load_1_req_bits_lqIdx_flag(io_lsu_load_1_req_bits_lqIdx_flag),
    .io_lsu_load_1_req_bits_lqIdx_value(io_lsu_load_1_req_bits_lqIdx_value),
    .io_lsu_load_1_resp_valid(g_io_lsu_load_1_resp_valid),
    .io_lsu_load_1_resp_bits_data(g_io_lsu_load_1_resp_bits_data),
    .io_lsu_load_1_resp_bits_miss(g_io_lsu_load_1_resp_bits_miss),
    .io_lsu_load_1_resp_bits_mshr_id(g_io_lsu_load_1_resp_bits_mshr_id),
    .io_lsu_load_1_resp_bits_meta_prefetch(g_io_lsu_load_1_resp_bits_meta_prefetch),
    .io_lsu_load_1_resp_bits_handled(g_io_lsu_load_1_resp_bits_handled),
    .io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied(g_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied),
    .io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt(g_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt),
    .io_lsu_load_1_s1_kill_data_read(io_lsu_load_1_s1_kill_data_read),
    .io_lsu_load_1_s1_kill(io_lsu_load_1_s1_kill),
    .io_lsu_load_1_s2_kill(io_lsu_load_1_s2_kill),
    .io_lsu_load_1_is128Req(io_lsu_load_1_is128Req),
    .io_lsu_load_1_pf_source(io_lsu_load_1_pf_source),
    .io_lsu_load_1_s1_paddr_dup_lsu(io_lsu_load_1_s1_paddr_dup_lsu),
    .io_lsu_load_1_s1_paddr_dup_dcache(io_lsu_load_1_s1_paddr_dup_dcache),
    .io_lsu_load_1_s2_bank_conflict(g_io_lsu_load_1_s2_bank_conflict),
    .io_lsu_load_1_s2_mq_nack(g_io_lsu_load_1_s2_mq_nack),
    .io_lsu_load_2_req_ready(g_io_lsu_load_2_req_ready),
    .io_lsu_load_2_req_valid(io_lsu_load_2_req_valid),
    .io_lsu_load_2_req_bits_cmd(io_lsu_load_2_req_bits_cmd),
    .io_lsu_load_2_req_bits_vaddr(io_lsu_load_2_req_bits_vaddr),
    .io_lsu_load_2_req_bits_vaddr_dup(io_lsu_load_2_req_bits_vaddr_dup),
    .io_lsu_load_2_req_bits_instrtype(io_lsu_load_2_req_bits_instrtype),
    .io_lsu_load_2_req_bits_isFirstIssue(io_lsu_load_2_req_bits_isFirstIssue),
    .io_lsu_load_2_req_bits_lqIdx_flag(io_lsu_load_2_req_bits_lqIdx_flag),
    .io_lsu_load_2_req_bits_lqIdx_value(io_lsu_load_2_req_bits_lqIdx_value),
    .io_lsu_load_2_resp_valid(g_io_lsu_load_2_resp_valid),
    .io_lsu_load_2_resp_bits_data(g_io_lsu_load_2_resp_bits_data),
    .io_lsu_load_2_resp_bits_miss(g_io_lsu_load_2_resp_bits_miss),
    .io_lsu_load_2_resp_bits_mshr_id(g_io_lsu_load_2_resp_bits_mshr_id),
    .io_lsu_load_2_resp_bits_meta_prefetch(g_io_lsu_load_2_resp_bits_meta_prefetch),
    .io_lsu_load_2_resp_bits_handled(g_io_lsu_load_2_resp_bits_handled),
    .io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied(g_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied),
    .io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt(g_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt),
    .io_lsu_load_2_s1_kill_data_read(io_lsu_load_2_s1_kill_data_read),
    .io_lsu_load_2_s1_kill(io_lsu_load_2_s1_kill),
    .io_lsu_load_2_s2_kill(io_lsu_load_2_s2_kill),
    .io_lsu_load_2_is128Req(io_lsu_load_2_is128Req),
    .io_lsu_load_2_pf_source(io_lsu_load_2_pf_source),
    .io_lsu_load_2_s1_paddr_dup_lsu(io_lsu_load_2_s1_paddr_dup_lsu),
    .io_lsu_load_2_s1_paddr_dup_dcache(io_lsu_load_2_s1_paddr_dup_dcache),
    .io_lsu_load_2_s2_bank_conflict(g_io_lsu_load_2_s2_bank_conflict),
    .io_lsu_load_2_s2_mq_nack(g_io_lsu_load_2_s2_mq_nack),
    .io_lsu_sta_0_req_valid(io_lsu_sta_0_req_valid),
    .io_lsu_sta_1_req_valid(io_lsu_sta_1_req_valid),
    .io_lsu_tl_d_channel_valid(g_io_lsu_tl_d_channel_valid),
    .io_lsu_tl_d_channel_mshrid(g_io_lsu_tl_d_channel_mshrid),
    .io_lsu_store_req_ready(g_io_lsu_store_req_ready),
    .io_lsu_store_req_valid(io_lsu_store_req_valid),
    .io_lsu_store_req_bits_vaddr(io_lsu_store_req_bits_vaddr),
    .io_lsu_store_req_bits_addr(io_lsu_store_req_bits_addr),
    .io_lsu_store_req_bits_data(io_lsu_store_req_bits_data),
    .io_lsu_store_req_bits_mask(io_lsu_store_req_bits_mask),
    .io_lsu_store_req_bits_id(io_lsu_store_req_bits_id),
    .io_lsu_store_main_pipe_hit_resp_valid(g_io_lsu_store_main_pipe_hit_resp_valid),
    .io_lsu_store_main_pipe_hit_resp_bits_id(g_io_lsu_store_main_pipe_hit_resp_bits_id),
    .io_lsu_store_replay_resp_valid(g_io_lsu_store_replay_resp_valid),
    .io_lsu_store_replay_resp_bits_id(g_io_lsu_store_replay_resp_bits_id),
    .io_lsu_atomics_req_ready(g_io_lsu_atomics_req_ready),
    .io_lsu_atomics_req_valid(io_lsu_atomics_req_valid),
    .io_lsu_atomics_req_bits_cmd(io_lsu_atomics_req_bits_cmd),
    .io_lsu_atomics_req_bits_vaddr(io_lsu_atomics_req_bits_vaddr),
    .io_lsu_atomics_req_bits_addr(io_lsu_atomics_req_bits_addr),
    .io_lsu_atomics_req_bits_word_idx(io_lsu_atomics_req_bits_word_idx),
    .io_lsu_atomics_req_bits_amo_data(io_lsu_atomics_req_bits_amo_data),
    .io_lsu_atomics_req_bits_amo_mask(io_lsu_atomics_req_bits_amo_mask),
    .io_lsu_atomics_req_bits_amo_cmp(io_lsu_atomics_req_bits_amo_cmp),
    .io_lsu_atomics_resp_valid(g_io_lsu_atomics_resp_valid),
    .io_lsu_atomics_resp_bits_data(g_io_lsu_atomics_resp_bits_data),
    .io_lsu_atomics_resp_bits_miss(g_io_lsu_atomics_resp_bits_miss),
    .io_lsu_atomics_resp_bits_replay(g_io_lsu_atomics_resp_bits_replay),
    .io_lsu_atomics_resp_bits_tl_error_tl_denied(g_io_lsu_atomics_resp_bits_tl_error_tl_denied),
    .io_lsu_atomics_resp_bits_tl_error_tl_corrupt(g_io_lsu_atomics_resp_bits_tl_error_tl_corrupt),
    .io_lsu_atomics_resp_bits_id(g_io_lsu_atomics_resp_bits_id),
    .io_lsu_atomics_block_lr(g_io_lsu_atomics_block_lr),
    .io_lsu_release_valid(g_io_lsu_release_valid),
    .io_lsu_release_bits_paddr(g_io_lsu_release_bits_paddr),
    .io_lsu_forward_D_0_valid(g_io_lsu_forward_D_0_valid),
    .io_lsu_forward_D_0_data(g_io_lsu_forward_D_0_data),
    .io_lsu_forward_D_0_mshrid(g_io_lsu_forward_D_0_mshrid),
    .io_lsu_forward_D_0_last(g_io_lsu_forward_D_0_last),
    .io_lsu_forward_D_0_denied(g_io_lsu_forward_D_0_denied),
    .io_lsu_forward_D_0_corrupt(g_io_lsu_forward_D_0_corrupt),
    .io_lsu_forward_D_1_valid(g_io_lsu_forward_D_1_valid),
    .io_lsu_forward_D_1_data(g_io_lsu_forward_D_1_data),
    .io_lsu_forward_D_1_mshrid(g_io_lsu_forward_D_1_mshrid),
    .io_lsu_forward_D_1_last(g_io_lsu_forward_D_1_last),
    .io_lsu_forward_D_1_denied(g_io_lsu_forward_D_1_denied),
    .io_lsu_forward_D_1_corrupt(g_io_lsu_forward_D_1_corrupt),
    .io_lsu_forward_D_2_valid(g_io_lsu_forward_D_2_valid),
    .io_lsu_forward_D_2_data(g_io_lsu_forward_D_2_data),
    .io_lsu_forward_D_2_mshrid(g_io_lsu_forward_D_2_mshrid),
    .io_lsu_forward_D_2_last(g_io_lsu_forward_D_2_last),
    .io_lsu_forward_D_2_denied(g_io_lsu_forward_D_2_denied),
    .io_lsu_forward_D_2_corrupt(g_io_lsu_forward_D_2_corrupt),
    .io_lsu_forward_mshr_0_valid(io_lsu_forward_mshr_0_valid),
    .io_lsu_forward_mshr_0_mshrid(io_lsu_forward_mshr_0_mshrid),
    .io_lsu_forward_mshr_0_paddr(io_lsu_forward_mshr_0_paddr),
    .io_lsu_forward_mshr_0_forward_mshr(g_io_lsu_forward_mshr_0_forward_mshr),
    .io_lsu_forward_mshr_0_forwardData_0(g_io_lsu_forward_mshr_0_forwardData_0),
    .io_lsu_forward_mshr_0_forwardData_1(g_io_lsu_forward_mshr_0_forwardData_1),
    .io_lsu_forward_mshr_0_forwardData_2(g_io_lsu_forward_mshr_0_forwardData_2),
    .io_lsu_forward_mshr_0_forwardData_3(g_io_lsu_forward_mshr_0_forwardData_3),
    .io_lsu_forward_mshr_0_forwardData_4(g_io_lsu_forward_mshr_0_forwardData_4),
    .io_lsu_forward_mshr_0_forwardData_5(g_io_lsu_forward_mshr_0_forwardData_5),
    .io_lsu_forward_mshr_0_forwardData_6(g_io_lsu_forward_mshr_0_forwardData_6),
    .io_lsu_forward_mshr_0_forwardData_7(g_io_lsu_forward_mshr_0_forwardData_7),
    .io_lsu_forward_mshr_0_forwardData_8(g_io_lsu_forward_mshr_0_forwardData_8),
    .io_lsu_forward_mshr_0_forwardData_9(g_io_lsu_forward_mshr_0_forwardData_9),
    .io_lsu_forward_mshr_0_forwardData_10(g_io_lsu_forward_mshr_0_forwardData_10),
    .io_lsu_forward_mshr_0_forwardData_11(g_io_lsu_forward_mshr_0_forwardData_11),
    .io_lsu_forward_mshr_0_forwardData_12(g_io_lsu_forward_mshr_0_forwardData_12),
    .io_lsu_forward_mshr_0_forwardData_13(g_io_lsu_forward_mshr_0_forwardData_13),
    .io_lsu_forward_mshr_0_forwardData_14(g_io_lsu_forward_mshr_0_forwardData_14),
    .io_lsu_forward_mshr_0_forwardData_15(g_io_lsu_forward_mshr_0_forwardData_15),
    .io_lsu_forward_mshr_0_forward_result_valid(g_io_lsu_forward_mshr_0_forward_result_valid),
    .io_lsu_forward_mshr_0_denied(g_io_lsu_forward_mshr_0_denied),
    .io_lsu_forward_mshr_0_corrupt(g_io_lsu_forward_mshr_0_corrupt),
    .io_lsu_forward_mshr_1_valid(io_lsu_forward_mshr_1_valid),
    .io_lsu_forward_mshr_1_mshrid(io_lsu_forward_mshr_1_mshrid),
    .io_lsu_forward_mshr_1_paddr(io_lsu_forward_mshr_1_paddr),
    .io_lsu_forward_mshr_1_forward_mshr(g_io_lsu_forward_mshr_1_forward_mshr),
    .io_lsu_forward_mshr_1_forwardData_0(g_io_lsu_forward_mshr_1_forwardData_0),
    .io_lsu_forward_mshr_1_forwardData_1(g_io_lsu_forward_mshr_1_forwardData_1),
    .io_lsu_forward_mshr_1_forwardData_2(g_io_lsu_forward_mshr_1_forwardData_2),
    .io_lsu_forward_mshr_1_forwardData_3(g_io_lsu_forward_mshr_1_forwardData_3),
    .io_lsu_forward_mshr_1_forwardData_4(g_io_lsu_forward_mshr_1_forwardData_4),
    .io_lsu_forward_mshr_1_forwardData_5(g_io_lsu_forward_mshr_1_forwardData_5),
    .io_lsu_forward_mshr_1_forwardData_6(g_io_lsu_forward_mshr_1_forwardData_6),
    .io_lsu_forward_mshr_1_forwardData_7(g_io_lsu_forward_mshr_1_forwardData_7),
    .io_lsu_forward_mshr_1_forwardData_8(g_io_lsu_forward_mshr_1_forwardData_8),
    .io_lsu_forward_mshr_1_forwardData_9(g_io_lsu_forward_mshr_1_forwardData_9),
    .io_lsu_forward_mshr_1_forwardData_10(g_io_lsu_forward_mshr_1_forwardData_10),
    .io_lsu_forward_mshr_1_forwardData_11(g_io_lsu_forward_mshr_1_forwardData_11),
    .io_lsu_forward_mshr_1_forwardData_12(g_io_lsu_forward_mshr_1_forwardData_12),
    .io_lsu_forward_mshr_1_forwardData_13(g_io_lsu_forward_mshr_1_forwardData_13),
    .io_lsu_forward_mshr_1_forwardData_14(g_io_lsu_forward_mshr_1_forwardData_14),
    .io_lsu_forward_mshr_1_forwardData_15(g_io_lsu_forward_mshr_1_forwardData_15),
    .io_lsu_forward_mshr_1_forward_result_valid(g_io_lsu_forward_mshr_1_forward_result_valid),
    .io_lsu_forward_mshr_1_denied(g_io_lsu_forward_mshr_1_denied),
    .io_lsu_forward_mshr_1_corrupt(g_io_lsu_forward_mshr_1_corrupt),
    .io_lsu_forward_mshr_2_valid(io_lsu_forward_mshr_2_valid),
    .io_lsu_forward_mshr_2_mshrid(io_lsu_forward_mshr_2_mshrid),
    .io_lsu_forward_mshr_2_paddr(io_lsu_forward_mshr_2_paddr),
    .io_lsu_forward_mshr_2_forward_mshr(g_io_lsu_forward_mshr_2_forward_mshr),
    .io_lsu_forward_mshr_2_forwardData_0(g_io_lsu_forward_mshr_2_forwardData_0),
    .io_lsu_forward_mshr_2_forwardData_1(g_io_lsu_forward_mshr_2_forwardData_1),
    .io_lsu_forward_mshr_2_forwardData_2(g_io_lsu_forward_mshr_2_forwardData_2),
    .io_lsu_forward_mshr_2_forwardData_3(g_io_lsu_forward_mshr_2_forwardData_3),
    .io_lsu_forward_mshr_2_forwardData_4(g_io_lsu_forward_mshr_2_forwardData_4),
    .io_lsu_forward_mshr_2_forwardData_5(g_io_lsu_forward_mshr_2_forwardData_5),
    .io_lsu_forward_mshr_2_forwardData_6(g_io_lsu_forward_mshr_2_forwardData_6),
    .io_lsu_forward_mshr_2_forwardData_7(g_io_lsu_forward_mshr_2_forwardData_7),
    .io_lsu_forward_mshr_2_forwardData_8(g_io_lsu_forward_mshr_2_forwardData_8),
    .io_lsu_forward_mshr_2_forwardData_9(g_io_lsu_forward_mshr_2_forwardData_9),
    .io_lsu_forward_mshr_2_forwardData_10(g_io_lsu_forward_mshr_2_forwardData_10),
    .io_lsu_forward_mshr_2_forwardData_11(g_io_lsu_forward_mshr_2_forwardData_11),
    .io_lsu_forward_mshr_2_forwardData_12(g_io_lsu_forward_mshr_2_forwardData_12),
    .io_lsu_forward_mshr_2_forwardData_13(g_io_lsu_forward_mshr_2_forwardData_13),
    .io_lsu_forward_mshr_2_forwardData_14(g_io_lsu_forward_mshr_2_forwardData_14),
    .io_lsu_forward_mshr_2_forwardData_15(g_io_lsu_forward_mshr_2_forwardData_15),
    .io_lsu_forward_mshr_2_forward_result_valid(g_io_lsu_forward_mshr_2_forward_result_valid),
    .io_lsu_forward_mshr_2_denied(g_io_lsu_forward_mshr_2_denied),
    .io_lsu_forward_mshr_2_corrupt(g_io_lsu_forward_mshr_2_corrupt),
    .io_error_valid(g_io_error_valid),
    .io_error_bits_paddr(g_io_error_bits_paddr),
    .io_error_bits_report_to_beu(g_io_error_bits_report_to_beu),
    .io_lqEmpty(io_lqEmpty),
    .io_pf_ctrl_enable(g_io_pf_ctrl_enable),
    .io_pf_ctrl_confidence(g_io_pf_ctrl_confidence),
    .io_sms_agt_evict_req_valid(g_io_sms_agt_evict_req_valid),
    .io_sms_agt_evict_req_bits_vaddr(g_io_sms_agt_evict_req_bits_vaddr),
    .io_debugTopDown_robHeadVaddr_valid(io_debugTopDown_robHeadVaddr_valid),
    .io_debugTopDown_robHeadVaddr_bits(io_debugTopDown_robHeadVaddr_bits),
    .io_debugTopDown_robHeadMissInDCache(g_io_debugTopDown_robHeadMissInDCache),
    .io_l2_hint_valid(io_l2_hint_valid),
    .io_l2_hint_bits_sourceId(io_l2_hint_bits_sourceId),
    .io_cmoOpReq_ready(g_io_cmoOpReq_ready),
    .io_cmoOpReq_valid(io_cmoOpReq_valid),
    .io_cmoOpReq_bits_opcode(io_cmoOpReq_bits_opcode),
    .io_cmoOpReq_bits_address(io_cmoOpReq_bits_address),
    .io_cmoOpResp_ready(io_cmoOpResp_ready),
    .io_cmoOpResp_valid(g_io_cmoOpResp_valid),
    .io_cmoOpResp_bits_denied(g_io_cmoOpResp_bits_denied),
    .io_cmoOpResp_bits_corrupt(g_io_cmoOpResp_bits_corrupt),
    .io_l1Miss(g_io_l1Miss),
    .io_wfi_wfiReq(io_wfi_wfiReq),
    .io_wfi_wfiSafe(g_io_wfi_wfiSafe),
    .io_perf_0_value(g_io_perf_0_value),
    .io_perf_1_value(g_io_perf_1_value),
    .io_perf_2_value(g_io_perf_2_value),
    .io_perf_3_value(g_io_perf_3_value),
    .io_perf_4_value(g_io_perf_4_value),
    .io_perf_5_value(g_io_perf_5_value),
    .io_perf_6_value(g_io_perf_6_value),
    .io_perf_7_value(g_io_perf_7_value),
    .io_perf_8_value(g_io_perf_8_value),
    .io_perf_9_value(g_io_perf_9_value),
    .io_perf_10_value(g_io_perf_10_value),
    .io_perf_11_value(g_io_perf_11_value),
    .io_perf_12_value(g_io_perf_12_value),
    .io_perf_13_value(g_io_perf_13_value),
    .io_perf_14_value(g_io_perf_14_value),
    .io_perf_15_value(g_io_perf_15_value),
    .io_perf_16_value(g_io_perf_16_value),
    .io_perf_17_value(g_io_perf_17_value),
    .io_perf_18_value(g_io_perf_18_value),
    .io_perf_19_value(g_io_perf_19_value),
    .io_perf_20_value(g_io_perf_20_value),
    .io_perf_21_value(g_io_perf_21_value),
    .io_perf_22_value(g_io_perf_22_value),
    .io_perf_23_value(g_io_perf_23_value),
    .io_perf_24_value(g_io_perf_24_value),
    .io_perf_25_value(g_io_perf_25_value),
    .io_perf_26_value(g_io_perf_26_value),
    .io_perf_27_value(g_io_perf_27_value),
    .io_perf_28_value(g_io_perf_28_value),
    .io_perf_29_value(g_io_perf_29_value),
    .io_perf_30_value(g_io_perf_30_value),
    .io_perf_31_value(g_io_perf_31_value),
    .io_perf_32_value(g_io_perf_32_value),
    .io_perf_33_value(g_io_perf_33_value),
    .io_perf_34_value(g_io_perf_34_value),
    .io_perf_35_value(g_io_perf_35_value),
    .io_perf_36_value(g_io_perf_36_value),
    .io_perf_37_value(g_io_perf_37_value),
    .io_perf_38_value(g_io_perf_38_value),
    .io_perf_39_value(g_io_perf_39_value),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(g_boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_array(boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all(boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req(boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_ack(g_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_writeen(boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be(boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr(boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata(boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen(boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd(boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_outdata(g_boreChildrenBd_bore_1_outdata),
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
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold(sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass(sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken(sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk(sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp(sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold(sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen(sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold(sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass(sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken(sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk(sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp(sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold(sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen(sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold(sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass(sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken(sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk(sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp(sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold(sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen(sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold(sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass(sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken(sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk(sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp(sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold(sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen(sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold(sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass(sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken(sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk(sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp(sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold(sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen(sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold(sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass(sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken(sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk(sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp(sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold(sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen(sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_17_ram_hold(sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_17_ram_bypass(sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken(sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk(sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp(sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold(sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen(sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_18_ram_hold(sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_18_ram_bypass(sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken(sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk(sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp(sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold(sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen(sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_19_ram_hold(sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_19_ram_bypass(sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken(sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk(sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp(sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold(sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen(sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_20_ram_hold(sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_20_ram_bypass(sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken(sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk(sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp(sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold(sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen(sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_21_ram_hold(sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_21_ram_bypass(sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_21_ram_bp_clken(sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_21_ram_aux_clk(sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_21_ram_aux_ckbp(sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_21_ram_mcp_hold(sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_21_cgen(sigFromSrams_bore_21_cgen),
    .sigFromSrams_bore_22_ram_hold(sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_22_ram_bypass(sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_22_ram_bp_clken(sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_22_ram_aux_clk(sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_22_ram_aux_ckbp(sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_22_ram_mcp_hold(sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_22_cgen(sigFromSrams_bore_22_cgen),
    .sigFromSrams_bore_23_ram_hold(sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_23_ram_bypass(sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_23_ram_bp_clken(sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_23_ram_aux_clk(sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_23_ram_aux_ckbp(sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_23_ram_mcp_hold(sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_23_cgen(sigFromSrams_bore_23_cgen),
    .sigFromSrams_bore_24_ram_hold(sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_24_ram_bypass(sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_24_ram_bp_clken(sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_24_ram_aux_clk(sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_24_ram_aux_ckbp(sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_24_ram_mcp_hold(sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_24_cgen(sigFromSrams_bore_24_cgen),
    .sigFromSrams_bore_25_ram_hold(sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_25_ram_bypass(sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_25_ram_bp_clken(sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_25_ram_aux_clk(sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_25_ram_aux_ckbp(sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_25_ram_mcp_hold(sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_25_cgen(sigFromSrams_bore_25_cgen),
    .sigFromSrams_bore_26_ram_hold(sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_26_ram_bypass(sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_26_ram_bp_clken(sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_26_ram_aux_clk(sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_26_ram_aux_ckbp(sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_26_ram_mcp_hold(sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_26_cgen(sigFromSrams_bore_26_cgen),
    .sigFromSrams_bore_27_ram_hold(sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_27_ram_bypass(sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_27_ram_bp_clken(sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_27_ram_aux_clk(sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_27_ram_aux_ckbp(sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_27_ram_mcp_hold(sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_27_cgen(sigFromSrams_bore_27_cgen),
    .sigFromSrams_bore_28_ram_hold(sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_28_ram_bypass(sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_28_ram_bp_clken(sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_28_ram_aux_clk(sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_28_ram_aux_ckbp(sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_28_ram_mcp_hold(sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_28_cgen(sigFromSrams_bore_28_cgen),
    .sigFromSrams_bore_29_ram_hold(sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_29_ram_bypass(sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_29_ram_bp_clken(sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_29_ram_aux_clk(sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_29_ram_aux_ckbp(sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_29_ram_mcp_hold(sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_29_cgen(sigFromSrams_bore_29_cgen),
    .sigFromSrams_bore_30_ram_hold(sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_30_ram_bypass(sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_30_ram_bp_clken(sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_30_ram_aux_clk(sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_30_ram_aux_ckbp(sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_30_ram_mcp_hold(sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_30_cgen(sigFromSrams_bore_30_cgen),
    .sigFromSrams_bore_31_ram_hold(sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_31_ram_bypass(sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_31_ram_bp_clken(sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_31_ram_aux_clk(sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_31_ram_aux_ckbp(sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_31_ram_mcp_hold(sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_31_cgen(sigFromSrams_bore_31_cgen),
    .sigFromSrams_bore_32_ram_hold(sigFromSrams_bore_32_ram_hold),
    .sigFromSrams_bore_32_ram_bypass(sigFromSrams_bore_32_ram_bypass),
    .sigFromSrams_bore_32_ram_bp_clken(sigFromSrams_bore_32_ram_bp_clken),
    .sigFromSrams_bore_32_ram_aux_clk(sigFromSrams_bore_32_ram_aux_clk),
    .sigFromSrams_bore_32_ram_aux_ckbp(sigFromSrams_bore_32_ram_aux_ckbp),
    .sigFromSrams_bore_32_ram_mcp_hold(sigFromSrams_bore_32_ram_mcp_hold),
    .sigFromSrams_bore_32_cgen(sigFromSrams_bore_32_cgen),
    .sigFromSrams_bore_33_ram_hold(sigFromSrams_bore_33_ram_hold),
    .sigFromSrams_bore_33_ram_bypass(sigFromSrams_bore_33_ram_bypass),
    .sigFromSrams_bore_33_ram_bp_clken(sigFromSrams_bore_33_ram_bp_clken),
    .sigFromSrams_bore_33_ram_aux_clk(sigFromSrams_bore_33_ram_aux_clk),
    .sigFromSrams_bore_33_ram_aux_ckbp(sigFromSrams_bore_33_ram_aux_ckbp),
    .sigFromSrams_bore_33_ram_mcp_hold(sigFromSrams_bore_33_ram_mcp_hold),
    .sigFromSrams_bore_33_cgen(sigFromSrams_bore_33_cgen),
    .sigFromSrams_bore_34_ram_hold(sigFromSrams_bore_34_ram_hold),
    .sigFromSrams_bore_34_ram_bypass(sigFromSrams_bore_34_ram_bypass),
    .sigFromSrams_bore_34_ram_bp_clken(sigFromSrams_bore_34_ram_bp_clken),
    .sigFromSrams_bore_34_ram_aux_clk(sigFromSrams_bore_34_ram_aux_clk),
    .sigFromSrams_bore_34_ram_aux_ckbp(sigFromSrams_bore_34_ram_aux_ckbp),
    .sigFromSrams_bore_34_ram_mcp_hold(sigFromSrams_bore_34_ram_mcp_hold),
    .sigFromSrams_bore_34_cgen(sigFromSrams_bore_34_cgen),
    .sigFromSrams_bore_35_ram_hold(sigFromSrams_bore_35_ram_hold),
    .sigFromSrams_bore_35_ram_bypass(sigFromSrams_bore_35_ram_bypass),
    .sigFromSrams_bore_35_ram_bp_clken(sigFromSrams_bore_35_ram_bp_clken),
    .sigFromSrams_bore_35_ram_aux_clk(sigFromSrams_bore_35_ram_aux_clk),
    .sigFromSrams_bore_35_ram_aux_ckbp(sigFromSrams_bore_35_ram_aux_ckbp),
    .sigFromSrams_bore_35_ram_mcp_hold(sigFromSrams_bore_35_ram_mcp_hold),
    .sigFromSrams_bore_35_cgen(sigFromSrams_bore_35_cgen),
    .sigFromSrams_bore_36_ram_hold(sigFromSrams_bore_36_ram_hold),
    .sigFromSrams_bore_36_ram_bypass(sigFromSrams_bore_36_ram_bypass),
    .sigFromSrams_bore_36_ram_bp_clken(sigFromSrams_bore_36_ram_bp_clken),
    .sigFromSrams_bore_36_ram_aux_clk(sigFromSrams_bore_36_ram_aux_clk),
    .sigFromSrams_bore_36_ram_aux_ckbp(sigFromSrams_bore_36_ram_aux_ckbp),
    .sigFromSrams_bore_36_ram_mcp_hold(sigFromSrams_bore_36_ram_mcp_hold),
    .sigFromSrams_bore_36_cgen(sigFromSrams_bore_36_cgen),
    .sigFromSrams_bore_37_ram_hold(sigFromSrams_bore_37_ram_hold),
    .sigFromSrams_bore_37_ram_bypass(sigFromSrams_bore_37_ram_bypass),
    .sigFromSrams_bore_37_ram_bp_clken(sigFromSrams_bore_37_ram_bp_clken),
    .sigFromSrams_bore_37_ram_aux_clk(sigFromSrams_bore_37_ram_aux_clk),
    .sigFromSrams_bore_37_ram_aux_ckbp(sigFromSrams_bore_37_ram_aux_ckbp),
    .sigFromSrams_bore_37_ram_mcp_hold(sigFromSrams_bore_37_ram_mcp_hold),
    .sigFromSrams_bore_37_cgen(sigFromSrams_bore_37_cgen),
    .sigFromSrams_bore_38_ram_hold(sigFromSrams_bore_38_ram_hold),
    .sigFromSrams_bore_38_ram_bypass(sigFromSrams_bore_38_ram_bypass),
    .sigFromSrams_bore_38_ram_bp_clken(sigFromSrams_bore_38_ram_bp_clken),
    .sigFromSrams_bore_38_ram_aux_clk(sigFromSrams_bore_38_ram_aux_clk),
    .sigFromSrams_bore_38_ram_aux_ckbp(sigFromSrams_bore_38_ram_aux_ckbp),
    .sigFromSrams_bore_38_ram_mcp_hold(sigFromSrams_bore_38_ram_mcp_hold),
    .sigFromSrams_bore_38_cgen(sigFromSrams_bore_38_cgen),
    .sigFromSrams_bore_39_ram_hold(sigFromSrams_bore_39_ram_hold),
    .sigFromSrams_bore_39_ram_bypass(sigFromSrams_bore_39_ram_bypass),
    .sigFromSrams_bore_39_ram_bp_clken(sigFromSrams_bore_39_ram_bp_clken),
    .sigFromSrams_bore_39_ram_aux_clk(sigFromSrams_bore_39_ram_aux_clk),
    .sigFromSrams_bore_39_ram_aux_ckbp(sigFromSrams_bore_39_ram_aux_ckbp),
    .sigFromSrams_bore_39_ram_mcp_hold(sigFromSrams_bore_39_ram_mcp_hold),
    .sigFromSrams_bore_39_cgen(sigFromSrams_bore_39_cgen),
    .gatewayIn_packed_41_bore(g_gatewayIn_packed_41_bore)
  );
  DCache_xs u_impl (
    .clock(clock),
    .reset(reset),
    .auto_cacheCtrlOpt_in_a_ready(i_auto_cacheCtrlOpt_in_a_ready),
    .auto_cacheCtrlOpt_in_a_valid(auto_cacheCtrlOpt_in_a_valid),
    .auto_cacheCtrlOpt_in_a_bits_opcode(auto_cacheCtrlOpt_in_a_bits_opcode),
    .auto_cacheCtrlOpt_in_a_bits_size(auto_cacheCtrlOpt_in_a_bits_size),
    .auto_cacheCtrlOpt_in_a_bits_source(auto_cacheCtrlOpt_in_a_bits_source),
    .auto_cacheCtrlOpt_in_a_bits_address(auto_cacheCtrlOpt_in_a_bits_address),
    .auto_cacheCtrlOpt_in_a_bits_mask(auto_cacheCtrlOpt_in_a_bits_mask),
    .auto_cacheCtrlOpt_in_a_bits_data(auto_cacheCtrlOpt_in_a_bits_data),
    .auto_cacheCtrlOpt_in_d_ready(auto_cacheCtrlOpt_in_d_ready),
    .auto_cacheCtrlOpt_in_d_valid(i_auto_cacheCtrlOpt_in_d_valid),
    .auto_cacheCtrlOpt_in_d_bits_opcode(i_auto_cacheCtrlOpt_in_d_bits_opcode),
    .auto_cacheCtrlOpt_in_d_bits_size(i_auto_cacheCtrlOpt_in_d_bits_size),
    .auto_cacheCtrlOpt_in_d_bits_source(i_auto_cacheCtrlOpt_in_d_bits_source),
    .auto_cacheCtrlOpt_in_d_bits_data(i_auto_cacheCtrlOpt_in_d_bits_data),
    .auto_client_out_a_ready(auto_client_out_a_ready),
    .auto_client_out_a_valid(i_auto_client_out_a_valid),
    .auto_client_out_a_bits_opcode(i_auto_client_out_a_bits_opcode),
    .auto_client_out_a_bits_param(i_auto_client_out_a_bits_param),
    .auto_client_out_a_bits_size(i_auto_client_out_a_bits_size),
    .auto_client_out_a_bits_source(i_auto_client_out_a_bits_source),
    .auto_client_out_a_bits_address(i_auto_client_out_a_bits_address),
    .auto_client_out_a_bits_user_alias(i_auto_client_out_a_bits_user_alias),
    .auto_client_out_a_bits_user_vaddr(i_auto_client_out_a_bits_user_vaddr),
    .auto_client_out_a_bits_user_reqSource(i_auto_client_out_a_bits_user_reqSource),
    .auto_client_out_a_bits_user_needHint(i_auto_client_out_a_bits_user_needHint),
    .auto_client_out_a_bits_echo_isKeyword(i_auto_client_out_a_bits_echo_isKeyword),
    .auto_client_out_a_bits_mask(i_auto_client_out_a_bits_mask),
    .auto_client_out_b_ready(i_auto_client_out_b_ready),
    .auto_client_out_b_valid(auto_client_out_b_valid),
    .auto_client_out_b_bits_opcode(auto_client_out_b_bits_opcode),
    .auto_client_out_b_bits_param(auto_client_out_b_bits_param),
    .auto_client_out_b_bits_address(auto_client_out_b_bits_address),
    .auto_client_out_b_bits_data(auto_client_out_b_bits_data),
    .auto_client_out_c_ready(auto_client_out_c_ready),
    .auto_client_out_c_valid(i_auto_client_out_c_valid),
    .auto_client_out_c_bits_opcode(i_auto_client_out_c_bits_opcode),
    .auto_client_out_c_bits_param(i_auto_client_out_c_bits_param),
    .auto_client_out_c_bits_size(i_auto_client_out_c_bits_size),
    .auto_client_out_c_bits_source(i_auto_client_out_c_bits_source),
    .auto_client_out_c_bits_address(i_auto_client_out_c_bits_address),
    .auto_client_out_c_bits_data(i_auto_client_out_c_bits_data),
    .auto_client_out_c_bits_corrupt(i_auto_client_out_c_bits_corrupt),
    .auto_client_out_d_ready(i_auto_client_out_d_ready),
    .auto_client_out_d_valid(auto_client_out_d_valid),
    .auto_client_out_d_bits_opcode(auto_client_out_d_bits_opcode),
    .auto_client_out_d_bits_param(auto_client_out_d_bits_param),
    .auto_client_out_d_bits_size(auto_client_out_d_bits_size),
    .auto_client_out_d_bits_source(auto_client_out_d_bits_source),
    .auto_client_out_d_bits_sink(auto_client_out_d_bits_sink),
    .auto_client_out_d_bits_denied(auto_client_out_d_bits_denied),
    .auto_client_out_d_bits_echo_isKeyword(auto_client_out_d_bits_echo_isKeyword),
    .auto_client_out_d_bits_data(auto_client_out_d_bits_data),
    .auto_client_out_d_bits_corrupt(auto_client_out_d_bits_corrupt),
    .auto_client_out_e_ready(auto_client_out_e_ready),
    .auto_client_out_e_valid(i_auto_client_out_e_valid),
    .auto_client_out_e_bits_sink(i_auto_client_out_e_bits_sink),
    .io_hartId(io_hartId),
    .io_l2_pf_store_only(io_l2_pf_store_only),
    .io_lsu_load_0_req_ready(i_io_lsu_load_0_req_ready),
    .io_lsu_load_0_req_valid(io_lsu_load_0_req_valid),
    .io_lsu_load_0_req_bits_cmd(io_lsu_load_0_req_bits_cmd),
    .io_lsu_load_0_req_bits_vaddr(io_lsu_load_0_req_bits_vaddr),
    .io_lsu_load_0_req_bits_vaddr_dup(io_lsu_load_0_req_bits_vaddr_dup),
    .io_lsu_load_0_req_bits_instrtype(io_lsu_load_0_req_bits_instrtype),
    .io_lsu_load_0_req_bits_isFirstIssue(io_lsu_load_0_req_bits_isFirstIssue),
    .io_lsu_load_0_req_bits_lqIdx_flag(io_lsu_load_0_req_bits_lqIdx_flag),
    .io_lsu_load_0_req_bits_lqIdx_value(io_lsu_load_0_req_bits_lqIdx_value),
    .io_lsu_load_0_resp_valid(i_io_lsu_load_0_resp_valid),
    .io_lsu_load_0_resp_bits_data(i_io_lsu_load_0_resp_bits_data),
    .io_lsu_load_0_resp_bits_data_delayed(i_io_lsu_load_0_resp_bits_data_delayed),
    .io_lsu_load_0_resp_bits_miss(i_io_lsu_load_0_resp_bits_miss),
    .io_lsu_load_0_resp_bits_mshr_id(i_io_lsu_load_0_resp_bits_mshr_id),
    .io_lsu_load_0_resp_bits_meta_prefetch(i_io_lsu_load_0_resp_bits_meta_prefetch),
    .io_lsu_load_0_resp_bits_handled(i_io_lsu_load_0_resp_bits_handled),
    .io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied(i_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied),
    .io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt(i_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt),
    .io_lsu_load_0_s1_kill_data_read(io_lsu_load_0_s1_kill_data_read),
    .io_lsu_load_0_s1_kill(io_lsu_load_0_s1_kill),
    .io_lsu_load_0_s2_kill(io_lsu_load_0_s2_kill),
    .io_lsu_load_0_is128Req(io_lsu_load_0_is128Req),
    .io_lsu_load_0_pf_source(io_lsu_load_0_pf_source),
    .io_lsu_load_0_s1_paddr_dup_lsu(io_lsu_load_0_s1_paddr_dup_lsu),
    .io_lsu_load_0_s1_paddr_dup_dcache(io_lsu_load_0_s1_paddr_dup_dcache),
    .io_lsu_load_0_s2_bank_conflict(i_io_lsu_load_0_s2_bank_conflict),
    .io_lsu_load_0_s2_mq_nack(i_io_lsu_load_0_s2_mq_nack),
    .io_lsu_load_1_req_ready(i_io_lsu_load_1_req_ready),
    .io_lsu_load_1_req_valid(io_lsu_load_1_req_valid),
    .io_lsu_load_1_req_bits_cmd(io_lsu_load_1_req_bits_cmd),
    .io_lsu_load_1_req_bits_vaddr(io_lsu_load_1_req_bits_vaddr),
    .io_lsu_load_1_req_bits_vaddr_dup(io_lsu_load_1_req_bits_vaddr_dup),
    .io_lsu_load_1_req_bits_instrtype(io_lsu_load_1_req_bits_instrtype),
    .io_lsu_load_1_req_bits_isFirstIssue(io_lsu_load_1_req_bits_isFirstIssue),
    .io_lsu_load_1_req_bits_lqIdx_flag(io_lsu_load_1_req_bits_lqIdx_flag),
    .io_lsu_load_1_req_bits_lqIdx_value(io_lsu_load_1_req_bits_lqIdx_value),
    .io_lsu_load_1_resp_valid(i_io_lsu_load_1_resp_valid),
    .io_lsu_load_1_resp_bits_data(i_io_lsu_load_1_resp_bits_data),
    .io_lsu_load_1_resp_bits_miss(i_io_lsu_load_1_resp_bits_miss),
    .io_lsu_load_1_resp_bits_mshr_id(i_io_lsu_load_1_resp_bits_mshr_id),
    .io_lsu_load_1_resp_bits_meta_prefetch(i_io_lsu_load_1_resp_bits_meta_prefetch),
    .io_lsu_load_1_resp_bits_handled(i_io_lsu_load_1_resp_bits_handled),
    .io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied(i_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied),
    .io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt(i_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt),
    .io_lsu_load_1_s1_kill_data_read(io_lsu_load_1_s1_kill_data_read),
    .io_lsu_load_1_s1_kill(io_lsu_load_1_s1_kill),
    .io_lsu_load_1_s2_kill(io_lsu_load_1_s2_kill),
    .io_lsu_load_1_is128Req(io_lsu_load_1_is128Req),
    .io_lsu_load_1_pf_source(io_lsu_load_1_pf_source),
    .io_lsu_load_1_s1_paddr_dup_lsu(io_lsu_load_1_s1_paddr_dup_lsu),
    .io_lsu_load_1_s1_paddr_dup_dcache(io_lsu_load_1_s1_paddr_dup_dcache),
    .io_lsu_load_1_s2_bank_conflict(i_io_lsu_load_1_s2_bank_conflict),
    .io_lsu_load_1_s2_mq_nack(i_io_lsu_load_1_s2_mq_nack),
    .io_lsu_load_2_req_ready(i_io_lsu_load_2_req_ready),
    .io_lsu_load_2_req_valid(io_lsu_load_2_req_valid),
    .io_lsu_load_2_req_bits_cmd(io_lsu_load_2_req_bits_cmd),
    .io_lsu_load_2_req_bits_vaddr(io_lsu_load_2_req_bits_vaddr),
    .io_lsu_load_2_req_bits_vaddr_dup(io_lsu_load_2_req_bits_vaddr_dup),
    .io_lsu_load_2_req_bits_instrtype(io_lsu_load_2_req_bits_instrtype),
    .io_lsu_load_2_req_bits_isFirstIssue(io_lsu_load_2_req_bits_isFirstIssue),
    .io_lsu_load_2_req_bits_lqIdx_flag(io_lsu_load_2_req_bits_lqIdx_flag),
    .io_lsu_load_2_req_bits_lqIdx_value(io_lsu_load_2_req_bits_lqIdx_value),
    .io_lsu_load_2_resp_valid(i_io_lsu_load_2_resp_valid),
    .io_lsu_load_2_resp_bits_data(i_io_lsu_load_2_resp_bits_data),
    .io_lsu_load_2_resp_bits_miss(i_io_lsu_load_2_resp_bits_miss),
    .io_lsu_load_2_resp_bits_mshr_id(i_io_lsu_load_2_resp_bits_mshr_id),
    .io_lsu_load_2_resp_bits_meta_prefetch(i_io_lsu_load_2_resp_bits_meta_prefetch),
    .io_lsu_load_2_resp_bits_handled(i_io_lsu_load_2_resp_bits_handled),
    .io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied(i_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied),
    .io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt(i_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt),
    .io_lsu_load_2_s1_kill_data_read(io_lsu_load_2_s1_kill_data_read),
    .io_lsu_load_2_s1_kill(io_lsu_load_2_s1_kill),
    .io_lsu_load_2_s2_kill(io_lsu_load_2_s2_kill),
    .io_lsu_load_2_is128Req(io_lsu_load_2_is128Req),
    .io_lsu_load_2_pf_source(io_lsu_load_2_pf_source),
    .io_lsu_load_2_s1_paddr_dup_lsu(io_lsu_load_2_s1_paddr_dup_lsu),
    .io_lsu_load_2_s1_paddr_dup_dcache(io_lsu_load_2_s1_paddr_dup_dcache),
    .io_lsu_load_2_s2_bank_conflict(i_io_lsu_load_2_s2_bank_conflict),
    .io_lsu_load_2_s2_mq_nack(i_io_lsu_load_2_s2_mq_nack),
    .io_lsu_sta_0_req_valid(io_lsu_sta_0_req_valid),
    .io_lsu_sta_1_req_valid(io_lsu_sta_1_req_valid),
    .io_lsu_tl_d_channel_valid(i_io_lsu_tl_d_channel_valid),
    .io_lsu_tl_d_channel_mshrid(i_io_lsu_tl_d_channel_mshrid),
    .io_lsu_store_req_ready(i_io_lsu_store_req_ready),
    .io_lsu_store_req_valid(io_lsu_store_req_valid),
    .io_lsu_store_req_bits_vaddr(io_lsu_store_req_bits_vaddr),
    .io_lsu_store_req_bits_addr(io_lsu_store_req_bits_addr),
    .io_lsu_store_req_bits_data(io_lsu_store_req_bits_data),
    .io_lsu_store_req_bits_mask(io_lsu_store_req_bits_mask),
    .io_lsu_store_req_bits_id(io_lsu_store_req_bits_id),
    .io_lsu_store_main_pipe_hit_resp_valid(i_io_lsu_store_main_pipe_hit_resp_valid),
    .io_lsu_store_main_pipe_hit_resp_bits_id(i_io_lsu_store_main_pipe_hit_resp_bits_id),
    .io_lsu_store_replay_resp_valid(i_io_lsu_store_replay_resp_valid),
    .io_lsu_store_replay_resp_bits_id(i_io_lsu_store_replay_resp_bits_id),
    .io_lsu_atomics_req_ready(i_io_lsu_atomics_req_ready),
    .io_lsu_atomics_req_valid(io_lsu_atomics_req_valid),
    .io_lsu_atomics_req_bits_cmd(io_lsu_atomics_req_bits_cmd),
    .io_lsu_atomics_req_bits_vaddr(io_lsu_atomics_req_bits_vaddr),
    .io_lsu_atomics_req_bits_addr(io_lsu_atomics_req_bits_addr),
    .io_lsu_atomics_req_bits_word_idx(io_lsu_atomics_req_bits_word_idx),
    .io_lsu_atomics_req_bits_amo_data(io_lsu_atomics_req_bits_amo_data),
    .io_lsu_atomics_req_bits_amo_mask(io_lsu_atomics_req_bits_amo_mask),
    .io_lsu_atomics_req_bits_amo_cmp(io_lsu_atomics_req_bits_amo_cmp),
    .io_lsu_atomics_resp_valid(i_io_lsu_atomics_resp_valid),
    .io_lsu_atomics_resp_bits_data(i_io_lsu_atomics_resp_bits_data),
    .io_lsu_atomics_resp_bits_miss(i_io_lsu_atomics_resp_bits_miss),
    .io_lsu_atomics_resp_bits_replay(i_io_lsu_atomics_resp_bits_replay),
    .io_lsu_atomics_resp_bits_tl_error_tl_denied(i_io_lsu_atomics_resp_bits_tl_error_tl_denied),
    .io_lsu_atomics_resp_bits_tl_error_tl_corrupt(i_io_lsu_atomics_resp_bits_tl_error_tl_corrupt),
    .io_lsu_atomics_resp_bits_id(i_io_lsu_atomics_resp_bits_id),
    .io_lsu_atomics_block_lr(i_io_lsu_atomics_block_lr),
    .io_lsu_release_valid(i_io_lsu_release_valid),
    .io_lsu_release_bits_paddr(i_io_lsu_release_bits_paddr),
    .io_lsu_forward_D_0_valid(i_io_lsu_forward_D_0_valid),
    .io_lsu_forward_D_0_data(i_io_lsu_forward_D_0_data),
    .io_lsu_forward_D_0_mshrid(i_io_lsu_forward_D_0_mshrid),
    .io_lsu_forward_D_0_last(i_io_lsu_forward_D_0_last),
    .io_lsu_forward_D_0_denied(i_io_lsu_forward_D_0_denied),
    .io_lsu_forward_D_0_corrupt(i_io_lsu_forward_D_0_corrupt),
    .io_lsu_forward_D_1_valid(i_io_lsu_forward_D_1_valid),
    .io_lsu_forward_D_1_data(i_io_lsu_forward_D_1_data),
    .io_lsu_forward_D_1_mshrid(i_io_lsu_forward_D_1_mshrid),
    .io_lsu_forward_D_1_last(i_io_lsu_forward_D_1_last),
    .io_lsu_forward_D_1_denied(i_io_lsu_forward_D_1_denied),
    .io_lsu_forward_D_1_corrupt(i_io_lsu_forward_D_1_corrupt),
    .io_lsu_forward_D_2_valid(i_io_lsu_forward_D_2_valid),
    .io_lsu_forward_D_2_data(i_io_lsu_forward_D_2_data),
    .io_lsu_forward_D_2_mshrid(i_io_lsu_forward_D_2_mshrid),
    .io_lsu_forward_D_2_last(i_io_lsu_forward_D_2_last),
    .io_lsu_forward_D_2_denied(i_io_lsu_forward_D_2_denied),
    .io_lsu_forward_D_2_corrupt(i_io_lsu_forward_D_2_corrupt),
    .io_lsu_forward_mshr_0_valid(io_lsu_forward_mshr_0_valid),
    .io_lsu_forward_mshr_0_mshrid(io_lsu_forward_mshr_0_mshrid),
    .io_lsu_forward_mshr_0_paddr(io_lsu_forward_mshr_0_paddr),
    .io_lsu_forward_mshr_0_forward_mshr(i_io_lsu_forward_mshr_0_forward_mshr),
    .io_lsu_forward_mshr_0_forwardData_0(i_io_lsu_forward_mshr_0_forwardData_0),
    .io_lsu_forward_mshr_0_forwardData_1(i_io_lsu_forward_mshr_0_forwardData_1),
    .io_lsu_forward_mshr_0_forwardData_2(i_io_lsu_forward_mshr_0_forwardData_2),
    .io_lsu_forward_mshr_0_forwardData_3(i_io_lsu_forward_mshr_0_forwardData_3),
    .io_lsu_forward_mshr_0_forwardData_4(i_io_lsu_forward_mshr_0_forwardData_4),
    .io_lsu_forward_mshr_0_forwardData_5(i_io_lsu_forward_mshr_0_forwardData_5),
    .io_lsu_forward_mshr_0_forwardData_6(i_io_lsu_forward_mshr_0_forwardData_6),
    .io_lsu_forward_mshr_0_forwardData_7(i_io_lsu_forward_mshr_0_forwardData_7),
    .io_lsu_forward_mshr_0_forwardData_8(i_io_lsu_forward_mshr_0_forwardData_8),
    .io_lsu_forward_mshr_0_forwardData_9(i_io_lsu_forward_mshr_0_forwardData_9),
    .io_lsu_forward_mshr_0_forwardData_10(i_io_lsu_forward_mshr_0_forwardData_10),
    .io_lsu_forward_mshr_0_forwardData_11(i_io_lsu_forward_mshr_0_forwardData_11),
    .io_lsu_forward_mshr_0_forwardData_12(i_io_lsu_forward_mshr_0_forwardData_12),
    .io_lsu_forward_mshr_0_forwardData_13(i_io_lsu_forward_mshr_0_forwardData_13),
    .io_lsu_forward_mshr_0_forwardData_14(i_io_lsu_forward_mshr_0_forwardData_14),
    .io_lsu_forward_mshr_0_forwardData_15(i_io_lsu_forward_mshr_0_forwardData_15),
    .io_lsu_forward_mshr_0_forward_result_valid(i_io_lsu_forward_mshr_0_forward_result_valid),
    .io_lsu_forward_mshr_0_denied(i_io_lsu_forward_mshr_0_denied),
    .io_lsu_forward_mshr_0_corrupt(i_io_lsu_forward_mshr_0_corrupt),
    .io_lsu_forward_mshr_1_valid(io_lsu_forward_mshr_1_valid),
    .io_lsu_forward_mshr_1_mshrid(io_lsu_forward_mshr_1_mshrid),
    .io_lsu_forward_mshr_1_paddr(io_lsu_forward_mshr_1_paddr),
    .io_lsu_forward_mshr_1_forward_mshr(i_io_lsu_forward_mshr_1_forward_mshr),
    .io_lsu_forward_mshr_1_forwardData_0(i_io_lsu_forward_mshr_1_forwardData_0),
    .io_lsu_forward_mshr_1_forwardData_1(i_io_lsu_forward_mshr_1_forwardData_1),
    .io_lsu_forward_mshr_1_forwardData_2(i_io_lsu_forward_mshr_1_forwardData_2),
    .io_lsu_forward_mshr_1_forwardData_3(i_io_lsu_forward_mshr_1_forwardData_3),
    .io_lsu_forward_mshr_1_forwardData_4(i_io_lsu_forward_mshr_1_forwardData_4),
    .io_lsu_forward_mshr_1_forwardData_5(i_io_lsu_forward_mshr_1_forwardData_5),
    .io_lsu_forward_mshr_1_forwardData_6(i_io_lsu_forward_mshr_1_forwardData_6),
    .io_lsu_forward_mshr_1_forwardData_7(i_io_lsu_forward_mshr_1_forwardData_7),
    .io_lsu_forward_mshr_1_forwardData_8(i_io_lsu_forward_mshr_1_forwardData_8),
    .io_lsu_forward_mshr_1_forwardData_9(i_io_lsu_forward_mshr_1_forwardData_9),
    .io_lsu_forward_mshr_1_forwardData_10(i_io_lsu_forward_mshr_1_forwardData_10),
    .io_lsu_forward_mshr_1_forwardData_11(i_io_lsu_forward_mshr_1_forwardData_11),
    .io_lsu_forward_mshr_1_forwardData_12(i_io_lsu_forward_mshr_1_forwardData_12),
    .io_lsu_forward_mshr_1_forwardData_13(i_io_lsu_forward_mshr_1_forwardData_13),
    .io_lsu_forward_mshr_1_forwardData_14(i_io_lsu_forward_mshr_1_forwardData_14),
    .io_lsu_forward_mshr_1_forwardData_15(i_io_lsu_forward_mshr_1_forwardData_15),
    .io_lsu_forward_mshr_1_forward_result_valid(i_io_lsu_forward_mshr_1_forward_result_valid),
    .io_lsu_forward_mshr_1_denied(i_io_lsu_forward_mshr_1_denied),
    .io_lsu_forward_mshr_1_corrupt(i_io_lsu_forward_mshr_1_corrupt),
    .io_lsu_forward_mshr_2_valid(io_lsu_forward_mshr_2_valid),
    .io_lsu_forward_mshr_2_mshrid(io_lsu_forward_mshr_2_mshrid),
    .io_lsu_forward_mshr_2_paddr(io_lsu_forward_mshr_2_paddr),
    .io_lsu_forward_mshr_2_forward_mshr(i_io_lsu_forward_mshr_2_forward_mshr),
    .io_lsu_forward_mshr_2_forwardData_0(i_io_lsu_forward_mshr_2_forwardData_0),
    .io_lsu_forward_mshr_2_forwardData_1(i_io_lsu_forward_mshr_2_forwardData_1),
    .io_lsu_forward_mshr_2_forwardData_2(i_io_lsu_forward_mshr_2_forwardData_2),
    .io_lsu_forward_mshr_2_forwardData_3(i_io_lsu_forward_mshr_2_forwardData_3),
    .io_lsu_forward_mshr_2_forwardData_4(i_io_lsu_forward_mshr_2_forwardData_4),
    .io_lsu_forward_mshr_2_forwardData_5(i_io_lsu_forward_mshr_2_forwardData_5),
    .io_lsu_forward_mshr_2_forwardData_6(i_io_lsu_forward_mshr_2_forwardData_6),
    .io_lsu_forward_mshr_2_forwardData_7(i_io_lsu_forward_mshr_2_forwardData_7),
    .io_lsu_forward_mshr_2_forwardData_8(i_io_lsu_forward_mshr_2_forwardData_8),
    .io_lsu_forward_mshr_2_forwardData_9(i_io_lsu_forward_mshr_2_forwardData_9),
    .io_lsu_forward_mshr_2_forwardData_10(i_io_lsu_forward_mshr_2_forwardData_10),
    .io_lsu_forward_mshr_2_forwardData_11(i_io_lsu_forward_mshr_2_forwardData_11),
    .io_lsu_forward_mshr_2_forwardData_12(i_io_lsu_forward_mshr_2_forwardData_12),
    .io_lsu_forward_mshr_2_forwardData_13(i_io_lsu_forward_mshr_2_forwardData_13),
    .io_lsu_forward_mshr_2_forwardData_14(i_io_lsu_forward_mshr_2_forwardData_14),
    .io_lsu_forward_mshr_2_forwardData_15(i_io_lsu_forward_mshr_2_forwardData_15),
    .io_lsu_forward_mshr_2_forward_result_valid(i_io_lsu_forward_mshr_2_forward_result_valid),
    .io_lsu_forward_mshr_2_denied(i_io_lsu_forward_mshr_2_denied),
    .io_lsu_forward_mshr_2_corrupt(i_io_lsu_forward_mshr_2_corrupt),
    .io_error_valid(i_io_error_valid),
    .io_error_bits_paddr(i_io_error_bits_paddr),
    .io_error_bits_report_to_beu(i_io_error_bits_report_to_beu),
    .io_lqEmpty(io_lqEmpty),
    .io_pf_ctrl_enable(i_io_pf_ctrl_enable),
    .io_pf_ctrl_confidence(i_io_pf_ctrl_confidence),
    .io_sms_agt_evict_req_valid(i_io_sms_agt_evict_req_valid),
    .io_sms_agt_evict_req_bits_vaddr(i_io_sms_agt_evict_req_bits_vaddr),
    .io_debugTopDown_robHeadVaddr_valid(io_debugTopDown_robHeadVaddr_valid),
    .io_debugTopDown_robHeadVaddr_bits(io_debugTopDown_robHeadVaddr_bits),
    .io_debugTopDown_robHeadMissInDCache(i_io_debugTopDown_robHeadMissInDCache),
    .io_l2_hint_valid(io_l2_hint_valid),
    .io_l2_hint_bits_sourceId(io_l2_hint_bits_sourceId),
    .io_cmoOpReq_ready(i_io_cmoOpReq_ready),
    .io_cmoOpReq_valid(io_cmoOpReq_valid),
    .io_cmoOpReq_bits_opcode(io_cmoOpReq_bits_opcode),
    .io_cmoOpReq_bits_address(io_cmoOpReq_bits_address),
    .io_cmoOpResp_ready(io_cmoOpResp_ready),
    .io_cmoOpResp_valid(i_io_cmoOpResp_valid),
    .io_cmoOpResp_bits_denied(i_io_cmoOpResp_bits_denied),
    .io_cmoOpResp_bits_corrupt(i_io_cmoOpResp_bits_corrupt),
    .io_l1Miss(i_io_l1Miss),
    .io_wfi_wfiReq(io_wfi_wfiReq),
    .io_wfi_wfiSafe(i_io_wfi_wfiSafe),
    .io_perf_0_value(i_io_perf_0_value),
    .io_perf_1_value(i_io_perf_1_value),
    .io_perf_2_value(i_io_perf_2_value),
    .io_perf_3_value(i_io_perf_3_value),
    .io_perf_4_value(i_io_perf_4_value),
    .io_perf_5_value(i_io_perf_5_value),
    .io_perf_6_value(i_io_perf_6_value),
    .io_perf_7_value(i_io_perf_7_value),
    .io_perf_8_value(i_io_perf_8_value),
    .io_perf_9_value(i_io_perf_9_value),
    .io_perf_10_value(i_io_perf_10_value),
    .io_perf_11_value(i_io_perf_11_value),
    .io_perf_12_value(i_io_perf_12_value),
    .io_perf_13_value(i_io_perf_13_value),
    .io_perf_14_value(i_io_perf_14_value),
    .io_perf_15_value(i_io_perf_15_value),
    .io_perf_16_value(i_io_perf_16_value),
    .io_perf_17_value(i_io_perf_17_value),
    .io_perf_18_value(i_io_perf_18_value),
    .io_perf_19_value(i_io_perf_19_value),
    .io_perf_20_value(i_io_perf_20_value),
    .io_perf_21_value(i_io_perf_21_value),
    .io_perf_22_value(i_io_perf_22_value),
    .io_perf_23_value(i_io_perf_23_value),
    .io_perf_24_value(i_io_perf_24_value),
    .io_perf_25_value(i_io_perf_25_value),
    .io_perf_26_value(i_io_perf_26_value),
    .io_perf_27_value(i_io_perf_27_value),
    .io_perf_28_value(i_io_perf_28_value),
    .io_perf_29_value(i_io_perf_29_value),
    .io_perf_30_value(i_io_perf_30_value),
    .io_perf_31_value(i_io_perf_31_value),
    .io_perf_32_value(i_io_perf_32_value),
    .io_perf_33_value(i_io_perf_33_value),
    .io_perf_34_value(i_io_perf_34_value),
    .io_perf_35_value(i_io_perf_35_value),
    .io_perf_36_value(i_io_perf_36_value),
    .io_perf_37_value(i_io_perf_37_value),
    .io_perf_38_value(i_io_perf_38_value),
    .io_perf_39_value(i_io_perf_39_value),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(i_boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_array(boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all(boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req(boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_ack(i_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_writeen(boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be(boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr(boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata(boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen(boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd(boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_outdata(i_boreChildrenBd_bore_1_outdata),
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
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold(sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass(sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken(sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk(sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp(sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold(sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen(sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold(sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass(sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken(sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk(sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp(sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold(sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen(sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold(sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass(sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken(sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk(sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp(sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold(sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen(sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold(sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass(sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken(sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk(sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp(sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold(sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen(sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold(sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass(sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken(sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk(sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp(sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold(sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen(sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold(sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass(sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken(sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk(sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp(sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold(sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen(sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_17_ram_hold(sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_17_ram_bypass(sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken(sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk(sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp(sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold(sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen(sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_18_ram_hold(sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_18_ram_bypass(sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken(sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk(sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp(sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold(sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen(sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_19_ram_hold(sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_19_ram_bypass(sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken(sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk(sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp(sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold(sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen(sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_20_ram_hold(sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_20_ram_bypass(sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken(sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk(sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp(sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold(sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen(sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_21_ram_hold(sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_21_ram_bypass(sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_21_ram_bp_clken(sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_21_ram_aux_clk(sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_21_ram_aux_ckbp(sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_21_ram_mcp_hold(sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_21_cgen(sigFromSrams_bore_21_cgen),
    .sigFromSrams_bore_22_ram_hold(sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_22_ram_bypass(sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_22_ram_bp_clken(sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_22_ram_aux_clk(sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_22_ram_aux_ckbp(sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_22_ram_mcp_hold(sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_22_cgen(sigFromSrams_bore_22_cgen),
    .sigFromSrams_bore_23_ram_hold(sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_23_ram_bypass(sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_23_ram_bp_clken(sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_23_ram_aux_clk(sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_23_ram_aux_ckbp(sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_23_ram_mcp_hold(sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_23_cgen(sigFromSrams_bore_23_cgen),
    .sigFromSrams_bore_24_ram_hold(sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_24_ram_bypass(sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_24_ram_bp_clken(sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_24_ram_aux_clk(sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_24_ram_aux_ckbp(sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_24_ram_mcp_hold(sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_24_cgen(sigFromSrams_bore_24_cgen),
    .sigFromSrams_bore_25_ram_hold(sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_25_ram_bypass(sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_25_ram_bp_clken(sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_25_ram_aux_clk(sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_25_ram_aux_ckbp(sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_25_ram_mcp_hold(sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_25_cgen(sigFromSrams_bore_25_cgen),
    .sigFromSrams_bore_26_ram_hold(sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_26_ram_bypass(sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_26_ram_bp_clken(sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_26_ram_aux_clk(sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_26_ram_aux_ckbp(sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_26_ram_mcp_hold(sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_26_cgen(sigFromSrams_bore_26_cgen),
    .sigFromSrams_bore_27_ram_hold(sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_27_ram_bypass(sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_27_ram_bp_clken(sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_27_ram_aux_clk(sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_27_ram_aux_ckbp(sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_27_ram_mcp_hold(sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_27_cgen(sigFromSrams_bore_27_cgen),
    .sigFromSrams_bore_28_ram_hold(sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_28_ram_bypass(sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_28_ram_bp_clken(sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_28_ram_aux_clk(sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_28_ram_aux_ckbp(sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_28_ram_mcp_hold(sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_28_cgen(sigFromSrams_bore_28_cgen),
    .sigFromSrams_bore_29_ram_hold(sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_29_ram_bypass(sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_29_ram_bp_clken(sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_29_ram_aux_clk(sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_29_ram_aux_ckbp(sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_29_ram_mcp_hold(sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_29_cgen(sigFromSrams_bore_29_cgen),
    .sigFromSrams_bore_30_ram_hold(sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_30_ram_bypass(sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_30_ram_bp_clken(sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_30_ram_aux_clk(sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_30_ram_aux_ckbp(sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_30_ram_mcp_hold(sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_30_cgen(sigFromSrams_bore_30_cgen),
    .sigFromSrams_bore_31_ram_hold(sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_31_ram_bypass(sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_31_ram_bp_clken(sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_31_ram_aux_clk(sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_31_ram_aux_ckbp(sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_31_ram_mcp_hold(sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_31_cgen(sigFromSrams_bore_31_cgen),
    .sigFromSrams_bore_32_ram_hold(sigFromSrams_bore_32_ram_hold),
    .sigFromSrams_bore_32_ram_bypass(sigFromSrams_bore_32_ram_bypass),
    .sigFromSrams_bore_32_ram_bp_clken(sigFromSrams_bore_32_ram_bp_clken),
    .sigFromSrams_bore_32_ram_aux_clk(sigFromSrams_bore_32_ram_aux_clk),
    .sigFromSrams_bore_32_ram_aux_ckbp(sigFromSrams_bore_32_ram_aux_ckbp),
    .sigFromSrams_bore_32_ram_mcp_hold(sigFromSrams_bore_32_ram_mcp_hold),
    .sigFromSrams_bore_32_cgen(sigFromSrams_bore_32_cgen),
    .sigFromSrams_bore_33_ram_hold(sigFromSrams_bore_33_ram_hold),
    .sigFromSrams_bore_33_ram_bypass(sigFromSrams_bore_33_ram_bypass),
    .sigFromSrams_bore_33_ram_bp_clken(sigFromSrams_bore_33_ram_bp_clken),
    .sigFromSrams_bore_33_ram_aux_clk(sigFromSrams_bore_33_ram_aux_clk),
    .sigFromSrams_bore_33_ram_aux_ckbp(sigFromSrams_bore_33_ram_aux_ckbp),
    .sigFromSrams_bore_33_ram_mcp_hold(sigFromSrams_bore_33_ram_mcp_hold),
    .sigFromSrams_bore_33_cgen(sigFromSrams_bore_33_cgen),
    .sigFromSrams_bore_34_ram_hold(sigFromSrams_bore_34_ram_hold),
    .sigFromSrams_bore_34_ram_bypass(sigFromSrams_bore_34_ram_bypass),
    .sigFromSrams_bore_34_ram_bp_clken(sigFromSrams_bore_34_ram_bp_clken),
    .sigFromSrams_bore_34_ram_aux_clk(sigFromSrams_bore_34_ram_aux_clk),
    .sigFromSrams_bore_34_ram_aux_ckbp(sigFromSrams_bore_34_ram_aux_ckbp),
    .sigFromSrams_bore_34_ram_mcp_hold(sigFromSrams_bore_34_ram_mcp_hold),
    .sigFromSrams_bore_34_cgen(sigFromSrams_bore_34_cgen),
    .sigFromSrams_bore_35_ram_hold(sigFromSrams_bore_35_ram_hold),
    .sigFromSrams_bore_35_ram_bypass(sigFromSrams_bore_35_ram_bypass),
    .sigFromSrams_bore_35_ram_bp_clken(sigFromSrams_bore_35_ram_bp_clken),
    .sigFromSrams_bore_35_ram_aux_clk(sigFromSrams_bore_35_ram_aux_clk),
    .sigFromSrams_bore_35_ram_aux_ckbp(sigFromSrams_bore_35_ram_aux_ckbp),
    .sigFromSrams_bore_35_ram_mcp_hold(sigFromSrams_bore_35_ram_mcp_hold),
    .sigFromSrams_bore_35_cgen(sigFromSrams_bore_35_cgen),
    .sigFromSrams_bore_36_ram_hold(sigFromSrams_bore_36_ram_hold),
    .sigFromSrams_bore_36_ram_bypass(sigFromSrams_bore_36_ram_bypass),
    .sigFromSrams_bore_36_ram_bp_clken(sigFromSrams_bore_36_ram_bp_clken),
    .sigFromSrams_bore_36_ram_aux_clk(sigFromSrams_bore_36_ram_aux_clk),
    .sigFromSrams_bore_36_ram_aux_ckbp(sigFromSrams_bore_36_ram_aux_ckbp),
    .sigFromSrams_bore_36_ram_mcp_hold(sigFromSrams_bore_36_ram_mcp_hold),
    .sigFromSrams_bore_36_cgen(sigFromSrams_bore_36_cgen),
    .sigFromSrams_bore_37_ram_hold(sigFromSrams_bore_37_ram_hold),
    .sigFromSrams_bore_37_ram_bypass(sigFromSrams_bore_37_ram_bypass),
    .sigFromSrams_bore_37_ram_bp_clken(sigFromSrams_bore_37_ram_bp_clken),
    .sigFromSrams_bore_37_ram_aux_clk(sigFromSrams_bore_37_ram_aux_clk),
    .sigFromSrams_bore_37_ram_aux_ckbp(sigFromSrams_bore_37_ram_aux_ckbp),
    .sigFromSrams_bore_37_ram_mcp_hold(sigFromSrams_bore_37_ram_mcp_hold),
    .sigFromSrams_bore_37_cgen(sigFromSrams_bore_37_cgen),
    .sigFromSrams_bore_38_ram_hold(sigFromSrams_bore_38_ram_hold),
    .sigFromSrams_bore_38_ram_bypass(sigFromSrams_bore_38_ram_bypass),
    .sigFromSrams_bore_38_ram_bp_clken(sigFromSrams_bore_38_ram_bp_clken),
    .sigFromSrams_bore_38_ram_aux_clk(sigFromSrams_bore_38_ram_aux_clk),
    .sigFromSrams_bore_38_ram_aux_ckbp(sigFromSrams_bore_38_ram_aux_ckbp),
    .sigFromSrams_bore_38_ram_mcp_hold(sigFromSrams_bore_38_ram_mcp_hold),
    .sigFromSrams_bore_38_cgen(sigFromSrams_bore_38_cgen),
    .sigFromSrams_bore_39_ram_hold(sigFromSrams_bore_39_ram_hold),
    .sigFromSrams_bore_39_ram_bypass(sigFromSrams_bore_39_ram_bypass),
    .sigFromSrams_bore_39_ram_bp_clken(sigFromSrams_bore_39_ram_bp_clken),
    .sigFromSrams_bore_39_ram_aux_clk(sigFromSrams_bore_39_ram_aux_clk),
    .sigFromSrams_bore_39_ram_aux_ckbp(sigFromSrams_bore_39_ram_aux_ckbp),
    .sigFromSrams_bore_39_ram_mcp_hold(sigFromSrams_bore_39_ram_mcp_hold),
    .sigFromSrams_bore_39_cgen(sigFromSrams_bore_39_cgen),
    .gatewayIn_packed_41_bore(i_gatewayIn_packed_41_bore)
  );
  // END GENERATED

  // BEGIN GENERATED(tb-compare)
  logic seen1_auto_cacheCtrlOpt_in_a_ready = '0, seen0_auto_cacheCtrlOpt_in_a_ready = '0;
  logic seen1_auto_cacheCtrlOpt_in_d_valid = '0, seen0_auto_cacheCtrlOpt_in_d_valid = '0;
  logic [3:0] seen1_auto_cacheCtrlOpt_in_d_bits_opcode = '0, seen0_auto_cacheCtrlOpt_in_d_bits_opcode = '0;
  logic [1:0] seen1_auto_cacheCtrlOpt_in_d_bits_size = '0, seen0_auto_cacheCtrlOpt_in_d_bits_size = '0;
  logic [3:0] seen1_auto_cacheCtrlOpt_in_d_bits_source = '0, seen0_auto_cacheCtrlOpt_in_d_bits_source = '0;
  logic [63:0] seen1_auto_cacheCtrlOpt_in_d_bits_data = '0, seen0_auto_cacheCtrlOpt_in_d_bits_data = '0;
  logic seen1_auto_client_out_a_valid = '0, seen0_auto_client_out_a_valid = '0;
  logic [3:0] seen1_auto_client_out_a_bits_opcode = '0, seen0_auto_client_out_a_bits_opcode = '0;
  logic [2:0] seen1_auto_client_out_a_bits_param = '0, seen0_auto_client_out_a_bits_param = '0;
  logic [2:0] seen1_auto_client_out_a_bits_size = '0, seen0_auto_client_out_a_bits_size = '0;
  logic [5:0] seen1_auto_client_out_a_bits_source = '0, seen0_auto_client_out_a_bits_source = '0;
  logic [47:0] seen1_auto_client_out_a_bits_address = '0, seen0_auto_client_out_a_bits_address = '0;
  logic [1:0] seen1_auto_client_out_a_bits_user_alias = '0, seen0_auto_client_out_a_bits_user_alias = '0;
  logic [43:0] seen1_auto_client_out_a_bits_user_vaddr = '0, seen0_auto_client_out_a_bits_user_vaddr = '0;
  logic [4:0] seen1_auto_client_out_a_bits_user_reqSource = '0, seen0_auto_client_out_a_bits_user_reqSource = '0;
  logic seen1_auto_client_out_a_bits_user_needHint = '0, seen0_auto_client_out_a_bits_user_needHint = '0;
  logic seen1_auto_client_out_a_bits_echo_isKeyword = '0, seen0_auto_client_out_a_bits_echo_isKeyword = '0;
  logic [31:0] seen1_auto_client_out_a_bits_mask = '0, seen0_auto_client_out_a_bits_mask = '0;
  logic seen1_auto_client_out_b_ready = '0, seen0_auto_client_out_b_ready = '0;
  logic seen1_auto_client_out_c_valid = '0, seen0_auto_client_out_c_valid = '0;
  logic [2:0] seen1_auto_client_out_c_bits_opcode = '0, seen0_auto_client_out_c_bits_opcode = '0;
  logic [2:0] seen1_auto_client_out_c_bits_param = '0, seen0_auto_client_out_c_bits_param = '0;
  logic [2:0] seen1_auto_client_out_c_bits_size = '0, seen0_auto_client_out_c_bits_size = '0;
  logic [5:0] seen1_auto_client_out_c_bits_source = '0, seen0_auto_client_out_c_bits_source = '0;
  logic [47:0] seen1_auto_client_out_c_bits_address = '0, seen0_auto_client_out_c_bits_address = '0;
  logic [255:0] seen1_auto_client_out_c_bits_data = '0, seen0_auto_client_out_c_bits_data = '0;
  logic seen1_auto_client_out_c_bits_corrupt = '0, seen0_auto_client_out_c_bits_corrupt = '0;
  logic seen1_auto_client_out_d_ready = '0, seen0_auto_client_out_d_ready = '0;
  logic seen1_auto_client_out_e_valid = '0, seen0_auto_client_out_e_valid = '0;
  logic [9:0] seen1_auto_client_out_e_bits_sink = '0, seen0_auto_client_out_e_bits_sink = '0;
  logic seen1_io_lsu_load_0_req_ready = '0, seen0_io_lsu_load_0_req_ready = '0;
  logic seen1_io_lsu_load_0_resp_valid = '0, seen0_io_lsu_load_0_resp_valid = '0;
  logic [127:0] seen1_io_lsu_load_0_resp_bits_data = '0, seen0_io_lsu_load_0_resp_bits_data = '0;
  logic [127:0] seen1_io_lsu_load_0_resp_bits_data_delayed = '0, seen0_io_lsu_load_0_resp_bits_data_delayed = '0;
  logic seen1_io_lsu_load_0_resp_bits_miss = '0, seen0_io_lsu_load_0_resp_bits_miss = '0;
  logic [3:0] seen1_io_lsu_load_0_resp_bits_mshr_id = '0, seen0_io_lsu_load_0_resp_bits_mshr_id = '0;
  logic [2:0] seen1_io_lsu_load_0_resp_bits_meta_prefetch = '0, seen0_io_lsu_load_0_resp_bits_meta_prefetch = '0;
  logic seen1_io_lsu_load_0_resp_bits_handled = '0, seen0_io_lsu_load_0_resp_bits_handled = '0;
  logic seen1_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied = '0, seen0_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied = '0;
  logic seen1_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt = '0, seen0_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt = '0;
  logic seen1_io_lsu_load_0_s2_bank_conflict = '0, seen0_io_lsu_load_0_s2_bank_conflict = '0;
  logic seen1_io_lsu_load_0_s2_mq_nack = '0, seen0_io_lsu_load_0_s2_mq_nack = '0;
  logic seen1_io_lsu_load_1_req_ready = '0, seen0_io_lsu_load_1_req_ready = '0;
  logic seen1_io_lsu_load_1_resp_valid = '0, seen0_io_lsu_load_1_resp_valid = '0;
  logic [127:0] seen1_io_lsu_load_1_resp_bits_data = '0, seen0_io_lsu_load_1_resp_bits_data = '0;
  logic seen1_io_lsu_load_1_resp_bits_miss = '0, seen0_io_lsu_load_1_resp_bits_miss = '0;
  logic [3:0] seen1_io_lsu_load_1_resp_bits_mshr_id = '0, seen0_io_lsu_load_1_resp_bits_mshr_id = '0;
  logic [2:0] seen1_io_lsu_load_1_resp_bits_meta_prefetch = '0, seen0_io_lsu_load_1_resp_bits_meta_prefetch = '0;
  logic seen1_io_lsu_load_1_resp_bits_handled = '0, seen0_io_lsu_load_1_resp_bits_handled = '0;
  logic seen1_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied = '0, seen0_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied = '0;
  logic seen1_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt = '0, seen0_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt = '0;
  logic seen1_io_lsu_load_1_s2_bank_conflict = '0, seen0_io_lsu_load_1_s2_bank_conflict = '0;
  logic seen1_io_lsu_load_1_s2_mq_nack = '0, seen0_io_lsu_load_1_s2_mq_nack = '0;
  logic seen1_io_lsu_load_2_req_ready = '0, seen0_io_lsu_load_2_req_ready = '0;
  logic seen1_io_lsu_load_2_resp_valid = '0, seen0_io_lsu_load_2_resp_valid = '0;
  logic [127:0] seen1_io_lsu_load_2_resp_bits_data = '0, seen0_io_lsu_load_2_resp_bits_data = '0;
  logic seen1_io_lsu_load_2_resp_bits_miss = '0, seen0_io_lsu_load_2_resp_bits_miss = '0;
  logic [3:0] seen1_io_lsu_load_2_resp_bits_mshr_id = '0, seen0_io_lsu_load_2_resp_bits_mshr_id = '0;
  logic [2:0] seen1_io_lsu_load_2_resp_bits_meta_prefetch = '0, seen0_io_lsu_load_2_resp_bits_meta_prefetch = '0;
  logic seen1_io_lsu_load_2_resp_bits_handled = '0, seen0_io_lsu_load_2_resp_bits_handled = '0;
  logic seen1_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied = '0, seen0_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied = '0;
  logic seen1_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt = '0, seen0_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt = '0;
  logic seen1_io_lsu_load_2_s2_bank_conflict = '0, seen0_io_lsu_load_2_s2_bank_conflict = '0;
  logic seen1_io_lsu_load_2_s2_mq_nack = '0, seen0_io_lsu_load_2_s2_mq_nack = '0;
  logic seen1_io_lsu_tl_d_channel_valid = '0, seen0_io_lsu_tl_d_channel_valid = '0;
  logic [3:0] seen1_io_lsu_tl_d_channel_mshrid = '0, seen0_io_lsu_tl_d_channel_mshrid = '0;
  logic seen1_io_lsu_store_req_ready = '0, seen0_io_lsu_store_req_ready = '0;
  logic seen1_io_lsu_store_main_pipe_hit_resp_valid = '0, seen0_io_lsu_store_main_pipe_hit_resp_valid = '0;
  logic [5:0] seen1_io_lsu_store_main_pipe_hit_resp_bits_id = '0, seen0_io_lsu_store_main_pipe_hit_resp_bits_id = '0;
  logic seen1_io_lsu_store_replay_resp_valid = '0, seen0_io_lsu_store_replay_resp_valid = '0;
  logic [5:0] seen1_io_lsu_store_replay_resp_bits_id = '0, seen0_io_lsu_store_replay_resp_bits_id = '0;
  logic seen1_io_lsu_atomics_req_ready = '0, seen0_io_lsu_atomics_req_ready = '0;
  logic seen1_io_lsu_atomics_resp_valid = '0, seen0_io_lsu_atomics_resp_valid = '0;
  logic [127:0] seen1_io_lsu_atomics_resp_bits_data = '0, seen0_io_lsu_atomics_resp_bits_data = '0;
  logic seen1_io_lsu_atomics_resp_bits_miss = '0, seen0_io_lsu_atomics_resp_bits_miss = '0;
  logic seen1_io_lsu_atomics_resp_bits_replay = '0, seen0_io_lsu_atomics_resp_bits_replay = '0;
  logic seen1_io_lsu_atomics_resp_bits_tl_error_tl_denied = '0, seen0_io_lsu_atomics_resp_bits_tl_error_tl_denied = '0;
  logic seen1_io_lsu_atomics_resp_bits_tl_error_tl_corrupt = '0, seen0_io_lsu_atomics_resp_bits_tl_error_tl_corrupt = '0;
  logic [5:0] seen1_io_lsu_atomics_resp_bits_id = '0, seen0_io_lsu_atomics_resp_bits_id = '0;
  logic seen1_io_lsu_atomics_block_lr = '0, seen0_io_lsu_atomics_block_lr = '0;
  logic seen1_io_lsu_release_valid = '0, seen0_io_lsu_release_valid = '0;
  logic [47:0] seen1_io_lsu_release_bits_paddr = '0, seen0_io_lsu_release_bits_paddr = '0;
  logic seen1_io_lsu_forward_D_0_valid = '0, seen0_io_lsu_forward_D_0_valid = '0;
  logic [255:0] seen1_io_lsu_forward_D_0_data = '0, seen0_io_lsu_forward_D_0_data = '0;
  logic [3:0] seen1_io_lsu_forward_D_0_mshrid = '0, seen0_io_lsu_forward_D_0_mshrid = '0;
  logic seen1_io_lsu_forward_D_0_last = '0, seen0_io_lsu_forward_D_0_last = '0;
  logic seen1_io_lsu_forward_D_0_denied = '0, seen0_io_lsu_forward_D_0_denied = '0;
  logic seen1_io_lsu_forward_D_0_corrupt = '0, seen0_io_lsu_forward_D_0_corrupt = '0;
  logic seen1_io_lsu_forward_D_1_valid = '0, seen0_io_lsu_forward_D_1_valid = '0;
  logic [255:0] seen1_io_lsu_forward_D_1_data = '0, seen0_io_lsu_forward_D_1_data = '0;
  logic [3:0] seen1_io_lsu_forward_D_1_mshrid = '0, seen0_io_lsu_forward_D_1_mshrid = '0;
  logic seen1_io_lsu_forward_D_1_last = '0, seen0_io_lsu_forward_D_1_last = '0;
  logic seen1_io_lsu_forward_D_1_denied = '0, seen0_io_lsu_forward_D_1_denied = '0;
  logic seen1_io_lsu_forward_D_1_corrupt = '0, seen0_io_lsu_forward_D_1_corrupt = '0;
  logic seen1_io_lsu_forward_D_2_valid = '0, seen0_io_lsu_forward_D_2_valid = '0;
  logic [255:0] seen1_io_lsu_forward_D_2_data = '0, seen0_io_lsu_forward_D_2_data = '0;
  logic [3:0] seen1_io_lsu_forward_D_2_mshrid = '0, seen0_io_lsu_forward_D_2_mshrid = '0;
  logic seen1_io_lsu_forward_D_2_last = '0, seen0_io_lsu_forward_D_2_last = '0;
  logic seen1_io_lsu_forward_D_2_denied = '0, seen0_io_lsu_forward_D_2_denied = '0;
  logic seen1_io_lsu_forward_D_2_corrupt = '0, seen0_io_lsu_forward_D_2_corrupt = '0;
  logic seen1_io_lsu_forward_mshr_0_forward_mshr = '0, seen0_io_lsu_forward_mshr_0_forward_mshr = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_0_forwardData_0 = '0, seen0_io_lsu_forward_mshr_0_forwardData_0 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_0_forwardData_1 = '0, seen0_io_lsu_forward_mshr_0_forwardData_1 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_0_forwardData_2 = '0, seen0_io_lsu_forward_mshr_0_forwardData_2 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_0_forwardData_3 = '0, seen0_io_lsu_forward_mshr_0_forwardData_3 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_0_forwardData_4 = '0, seen0_io_lsu_forward_mshr_0_forwardData_4 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_0_forwardData_5 = '0, seen0_io_lsu_forward_mshr_0_forwardData_5 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_0_forwardData_6 = '0, seen0_io_lsu_forward_mshr_0_forwardData_6 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_0_forwardData_7 = '0, seen0_io_lsu_forward_mshr_0_forwardData_7 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_0_forwardData_8 = '0, seen0_io_lsu_forward_mshr_0_forwardData_8 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_0_forwardData_9 = '0, seen0_io_lsu_forward_mshr_0_forwardData_9 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_0_forwardData_10 = '0, seen0_io_lsu_forward_mshr_0_forwardData_10 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_0_forwardData_11 = '0, seen0_io_lsu_forward_mshr_0_forwardData_11 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_0_forwardData_12 = '0, seen0_io_lsu_forward_mshr_0_forwardData_12 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_0_forwardData_13 = '0, seen0_io_lsu_forward_mshr_0_forwardData_13 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_0_forwardData_14 = '0, seen0_io_lsu_forward_mshr_0_forwardData_14 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_0_forwardData_15 = '0, seen0_io_lsu_forward_mshr_0_forwardData_15 = '0;
  logic seen1_io_lsu_forward_mshr_0_forward_result_valid = '0, seen0_io_lsu_forward_mshr_0_forward_result_valid = '0;
  logic seen1_io_lsu_forward_mshr_0_denied = '0, seen0_io_lsu_forward_mshr_0_denied = '0;
  logic seen1_io_lsu_forward_mshr_0_corrupt = '0, seen0_io_lsu_forward_mshr_0_corrupt = '0;
  logic seen1_io_lsu_forward_mshr_1_forward_mshr = '0, seen0_io_lsu_forward_mshr_1_forward_mshr = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_1_forwardData_0 = '0, seen0_io_lsu_forward_mshr_1_forwardData_0 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_1_forwardData_1 = '0, seen0_io_lsu_forward_mshr_1_forwardData_1 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_1_forwardData_2 = '0, seen0_io_lsu_forward_mshr_1_forwardData_2 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_1_forwardData_3 = '0, seen0_io_lsu_forward_mshr_1_forwardData_3 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_1_forwardData_4 = '0, seen0_io_lsu_forward_mshr_1_forwardData_4 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_1_forwardData_5 = '0, seen0_io_lsu_forward_mshr_1_forwardData_5 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_1_forwardData_6 = '0, seen0_io_lsu_forward_mshr_1_forwardData_6 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_1_forwardData_7 = '0, seen0_io_lsu_forward_mshr_1_forwardData_7 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_1_forwardData_8 = '0, seen0_io_lsu_forward_mshr_1_forwardData_8 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_1_forwardData_9 = '0, seen0_io_lsu_forward_mshr_1_forwardData_9 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_1_forwardData_10 = '0, seen0_io_lsu_forward_mshr_1_forwardData_10 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_1_forwardData_11 = '0, seen0_io_lsu_forward_mshr_1_forwardData_11 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_1_forwardData_12 = '0, seen0_io_lsu_forward_mshr_1_forwardData_12 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_1_forwardData_13 = '0, seen0_io_lsu_forward_mshr_1_forwardData_13 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_1_forwardData_14 = '0, seen0_io_lsu_forward_mshr_1_forwardData_14 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_1_forwardData_15 = '0, seen0_io_lsu_forward_mshr_1_forwardData_15 = '0;
  logic seen1_io_lsu_forward_mshr_1_forward_result_valid = '0, seen0_io_lsu_forward_mshr_1_forward_result_valid = '0;
  logic seen1_io_lsu_forward_mshr_1_denied = '0, seen0_io_lsu_forward_mshr_1_denied = '0;
  logic seen1_io_lsu_forward_mshr_1_corrupt = '0, seen0_io_lsu_forward_mshr_1_corrupt = '0;
  logic seen1_io_lsu_forward_mshr_2_forward_mshr = '0, seen0_io_lsu_forward_mshr_2_forward_mshr = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_2_forwardData_0 = '0, seen0_io_lsu_forward_mshr_2_forwardData_0 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_2_forwardData_1 = '0, seen0_io_lsu_forward_mshr_2_forwardData_1 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_2_forwardData_2 = '0, seen0_io_lsu_forward_mshr_2_forwardData_2 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_2_forwardData_3 = '0, seen0_io_lsu_forward_mshr_2_forwardData_3 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_2_forwardData_4 = '0, seen0_io_lsu_forward_mshr_2_forwardData_4 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_2_forwardData_5 = '0, seen0_io_lsu_forward_mshr_2_forwardData_5 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_2_forwardData_6 = '0, seen0_io_lsu_forward_mshr_2_forwardData_6 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_2_forwardData_7 = '0, seen0_io_lsu_forward_mshr_2_forwardData_7 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_2_forwardData_8 = '0, seen0_io_lsu_forward_mshr_2_forwardData_8 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_2_forwardData_9 = '0, seen0_io_lsu_forward_mshr_2_forwardData_9 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_2_forwardData_10 = '0, seen0_io_lsu_forward_mshr_2_forwardData_10 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_2_forwardData_11 = '0, seen0_io_lsu_forward_mshr_2_forwardData_11 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_2_forwardData_12 = '0, seen0_io_lsu_forward_mshr_2_forwardData_12 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_2_forwardData_13 = '0, seen0_io_lsu_forward_mshr_2_forwardData_13 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_2_forwardData_14 = '0, seen0_io_lsu_forward_mshr_2_forwardData_14 = '0;
  logic [7:0] seen1_io_lsu_forward_mshr_2_forwardData_15 = '0, seen0_io_lsu_forward_mshr_2_forwardData_15 = '0;
  logic seen1_io_lsu_forward_mshr_2_forward_result_valid = '0, seen0_io_lsu_forward_mshr_2_forward_result_valid = '0;
  logic seen1_io_lsu_forward_mshr_2_denied = '0, seen0_io_lsu_forward_mshr_2_denied = '0;
  logic seen1_io_lsu_forward_mshr_2_corrupt = '0, seen0_io_lsu_forward_mshr_2_corrupt = '0;
  logic seen1_io_error_valid = '0, seen0_io_error_valid = '0;
  logic [47:0] seen1_io_error_bits_paddr = '0, seen0_io_error_bits_paddr = '0;
  logic seen1_io_error_bits_report_to_beu = '0, seen0_io_error_bits_report_to_beu = '0;
  logic seen1_io_pf_ctrl_enable = '0, seen0_io_pf_ctrl_enable = '0;
  logic seen1_io_pf_ctrl_confidence = '0, seen0_io_pf_ctrl_confidence = '0;
  logic seen1_io_sms_agt_evict_req_valid = '0, seen0_io_sms_agt_evict_req_valid = '0;
  logic [49:0] seen1_io_sms_agt_evict_req_bits_vaddr = '0, seen0_io_sms_agt_evict_req_bits_vaddr = '0;
  logic seen1_io_debugTopDown_robHeadMissInDCache = '0, seen0_io_debugTopDown_robHeadMissInDCache = '0;
  logic seen1_io_cmoOpReq_ready = '0, seen0_io_cmoOpReq_ready = '0;
  logic seen1_io_cmoOpResp_valid = '0, seen0_io_cmoOpResp_valid = '0;
  logic seen1_io_cmoOpResp_bits_denied = '0, seen0_io_cmoOpResp_bits_denied = '0;
  logic seen1_io_cmoOpResp_bits_corrupt = '0, seen0_io_cmoOpResp_bits_corrupt = '0;
  logic seen1_io_l1Miss = '0, seen0_io_l1Miss = '0;
  logic seen1_io_wfi_wfiSafe = '0, seen0_io_wfi_wfiSafe = '0;
  logic [5:0] seen1_io_perf_0_value = '0, seen0_io_perf_0_value = '0;
  logic [5:0] seen1_io_perf_1_value = '0, seen0_io_perf_1_value = '0;
  logic [5:0] seen1_io_perf_2_value = '0, seen0_io_perf_2_value = '0;
  logic [5:0] seen1_io_perf_3_value = '0, seen0_io_perf_3_value = '0;
  logic [5:0] seen1_io_perf_4_value = '0, seen0_io_perf_4_value = '0;
  logic [5:0] seen1_io_perf_5_value = '0, seen0_io_perf_5_value = '0;
  logic [5:0] seen1_io_perf_6_value = '0, seen0_io_perf_6_value = '0;
  logic [5:0] seen1_io_perf_7_value = '0, seen0_io_perf_7_value = '0;
  logic [5:0] seen1_io_perf_8_value = '0, seen0_io_perf_8_value = '0;
  logic [5:0] seen1_io_perf_9_value = '0, seen0_io_perf_9_value = '0;
  logic [5:0] seen1_io_perf_10_value = '0, seen0_io_perf_10_value = '0;
  logic [5:0] seen1_io_perf_11_value = '0, seen0_io_perf_11_value = '0;
  logic [5:0] seen1_io_perf_12_value = '0, seen0_io_perf_12_value = '0;
  logic [5:0] seen1_io_perf_13_value = '0, seen0_io_perf_13_value = '0;
  logic [5:0] seen1_io_perf_14_value = '0, seen0_io_perf_14_value = '0;
  logic [5:0] seen1_io_perf_15_value = '0, seen0_io_perf_15_value = '0;
  logic [5:0] seen1_io_perf_16_value = '0, seen0_io_perf_16_value = '0;
  logic [5:0] seen1_io_perf_17_value = '0, seen0_io_perf_17_value = '0;
  logic [5:0] seen1_io_perf_18_value = '0, seen0_io_perf_18_value = '0;
  logic [5:0] seen1_io_perf_19_value = '0, seen0_io_perf_19_value = '0;
  logic [5:0] seen1_io_perf_20_value = '0, seen0_io_perf_20_value = '0;
  logic [5:0] seen1_io_perf_21_value = '0, seen0_io_perf_21_value = '0;
  logic [5:0] seen1_io_perf_22_value = '0, seen0_io_perf_22_value = '0;
  logic [5:0] seen1_io_perf_23_value = '0, seen0_io_perf_23_value = '0;
  logic [5:0] seen1_io_perf_24_value = '0, seen0_io_perf_24_value = '0;
  logic [5:0] seen1_io_perf_25_value = '0, seen0_io_perf_25_value = '0;
  logic [5:0] seen1_io_perf_26_value = '0, seen0_io_perf_26_value = '0;
  logic [5:0] seen1_io_perf_27_value = '0, seen0_io_perf_27_value = '0;
  logic [5:0] seen1_io_perf_28_value = '0, seen0_io_perf_28_value = '0;
  logic [5:0] seen1_io_perf_29_value = '0, seen0_io_perf_29_value = '0;
  logic [5:0] seen1_io_perf_30_value = '0, seen0_io_perf_30_value = '0;
  logic [5:0] seen1_io_perf_31_value = '0, seen0_io_perf_31_value = '0;
  logic [5:0] seen1_io_perf_32_value = '0, seen0_io_perf_32_value = '0;
  logic [5:0] seen1_io_perf_33_value = '0, seen0_io_perf_33_value = '0;
  logic [5:0] seen1_io_perf_34_value = '0, seen0_io_perf_34_value = '0;
  logic [5:0] seen1_io_perf_35_value = '0, seen0_io_perf_35_value = '0;
  logic [5:0] seen1_io_perf_36_value = '0, seen0_io_perf_36_value = '0;
  logic [5:0] seen1_io_perf_37_value = '0, seen0_io_perf_37_value = '0;
  logic [5:0] seen1_io_perf_38_value = '0, seen0_io_perf_38_value = '0;
  logic [5:0] seen1_io_perf_39_value = '0, seen0_io_perf_39_value = '0;
  logic seen1_boreChildrenBd_bore_ack = '0, seen0_boreChildrenBd_bore_ack = '0;
  logic [71:0] seen1_boreChildrenBd_bore_outdata = '0, seen0_boreChildrenBd_bore_outdata = '0;
  logic seen1_boreChildrenBd_bore_1_ack = '0, seen0_boreChildrenBd_bore_1_ack = '0;
  logic [85:0] seen1_boreChildrenBd_bore_1_outdata = '0, seen0_boreChildrenBd_bore_1_outdata = '0;
  logic [600:0] seen1_gatewayIn_packed_41_bore = '0, seen0_gatewayIn_packed_41_bore = '0;
  bit armed_auto_cacheCtrlOpt_in_a_ready = 0;
  bit armed_auto_cacheCtrlOpt_in_d_valid = 0;
  bit armed_auto_cacheCtrlOpt_in_d_bits_opcode = 0;
  bit armed_auto_cacheCtrlOpt_in_d_bits_size = 0;
  bit armed_auto_cacheCtrlOpt_in_d_bits_source = 0;
  bit armed_auto_cacheCtrlOpt_in_d_bits_data = 0;
  bit armed_auto_client_out_a_valid = 0;
  bit armed_auto_client_out_a_bits_opcode = 0;
  bit armed_auto_client_out_a_bits_param = 0;
  bit armed_auto_client_out_a_bits_size = 0;
  bit armed_auto_client_out_a_bits_source = 0;
  bit armed_auto_client_out_a_bits_address = 0;
  bit armed_auto_client_out_a_bits_user_alias = 0;
  bit armed_auto_client_out_a_bits_user_vaddr = 0;
  bit armed_auto_client_out_a_bits_user_reqSource = 0;
  bit armed_auto_client_out_a_bits_user_needHint = 0;
  bit armed_auto_client_out_a_bits_echo_isKeyword = 0;
  bit armed_auto_client_out_a_bits_mask = 0;
  bit armed_auto_client_out_b_ready = 0;
  bit armed_auto_client_out_c_valid = 0;
  bit armed_auto_client_out_c_bits_opcode = 0;
  bit armed_auto_client_out_c_bits_param = 0;
  bit armed_auto_client_out_c_bits_size = 0;
  bit armed_auto_client_out_c_bits_source = 0;
  bit armed_auto_client_out_c_bits_address = 0;
  bit armed_auto_client_out_c_bits_data = 0;
  bit armed_auto_client_out_c_bits_corrupt = 0;
  bit armed_auto_client_out_d_ready = 0;
  bit armed_auto_client_out_e_valid = 0;
  bit armed_auto_client_out_e_bits_sink = 0;
  bit armed_io_lsu_load_0_req_ready = 0;
  bit armed_io_lsu_load_0_resp_valid = 0;
  bit armed_io_lsu_load_0_resp_bits_data = 0;
  bit armed_io_lsu_load_0_resp_bits_data_delayed = 0;
  bit armed_io_lsu_load_0_resp_bits_miss = 0;
  bit armed_io_lsu_load_0_resp_bits_mshr_id = 0;
  bit armed_io_lsu_load_0_resp_bits_meta_prefetch = 0;
  bit armed_io_lsu_load_0_resp_bits_handled = 0;
  bit armed_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied = 0;
  bit armed_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt = 0;
  bit armed_io_lsu_load_0_s2_bank_conflict = 0;
  bit armed_io_lsu_load_0_s2_mq_nack = 0;
  bit armed_io_lsu_load_1_req_ready = 0;
  bit armed_io_lsu_load_1_resp_valid = 0;
  bit armed_io_lsu_load_1_resp_bits_data = 0;
  bit armed_io_lsu_load_1_resp_bits_miss = 0;
  bit armed_io_lsu_load_1_resp_bits_mshr_id = 0;
  bit armed_io_lsu_load_1_resp_bits_meta_prefetch = 0;
  bit armed_io_lsu_load_1_resp_bits_handled = 0;
  bit armed_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied = 0;
  bit armed_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt = 0;
  bit armed_io_lsu_load_1_s2_bank_conflict = 0;
  bit armed_io_lsu_load_1_s2_mq_nack = 0;
  bit armed_io_lsu_load_2_req_ready = 0;
  bit armed_io_lsu_load_2_resp_valid = 0;
  bit armed_io_lsu_load_2_resp_bits_data = 0;
  bit armed_io_lsu_load_2_resp_bits_miss = 0;
  bit armed_io_lsu_load_2_resp_bits_mshr_id = 0;
  bit armed_io_lsu_load_2_resp_bits_meta_prefetch = 0;
  bit armed_io_lsu_load_2_resp_bits_handled = 0;
  bit armed_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied = 0;
  bit armed_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt = 0;
  bit armed_io_lsu_load_2_s2_bank_conflict = 0;
  bit armed_io_lsu_load_2_s2_mq_nack = 0;
  bit armed_io_lsu_tl_d_channel_valid = 0;
  bit armed_io_lsu_tl_d_channel_mshrid = 0;
  bit armed_io_lsu_store_req_ready = 0;
  bit armed_io_lsu_store_main_pipe_hit_resp_valid = 0;
  bit armed_io_lsu_store_main_pipe_hit_resp_bits_id = 0;
  bit armed_io_lsu_store_replay_resp_valid = 0;
  bit armed_io_lsu_store_replay_resp_bits_id = 0;
  bit armed_io_lsu_atomics_req_ready = 0;
  bit armed_io_lsu_atomics_resp_valid = 0;
  bit armed_io_lsu_atomics_resp_bits_data = 0;
  bit armed_io_lsu_atomics_resp_bits_miss = 0;
  bit armed_io_lsu_atomics_resp_bits_replay = 0;
  bit armed_io_lsu_atomics_resp_bits_tl_error_tl_denied = 0;
  bit armed_io_lsu_atomics_resp_bits_tl_error_tl_corrupt = 0;
  bit armed_io_lsu_atomics_resp_bits_id = 0;
  bit armed_io_lsu_atomics_block_lr = 0;
  bit armed_io_lsu_release_valid = 0;
  bit armed_io_lsu_release_bits_paddr = 0;
  bit armed_io_lsu_forward_D_0_valid = 0;
  bit armed_io_lsu_forward_D_0_data = 0;
  bit armed_io_lsu_forward_D_0_mshrid = 0;
  bit armed_io_lsu_forward_D_0_last = 0;
  bit armed_io_lsu_forward_D_0_denied = 0;
  bit armed_io_lsu_forward_D_0_corrupt = 0;
  bit armed_io_lsu_forward_D_1_valid = 0;
  bit armed_io_lsu_forward_D_1_data = 0;
  bit armed_io_lsu_forward_D_1_mshrid = 0;
  bit armed_io_lsu_forward_D_1_last = 0;
  bit armed_io_lsu_forward_D_1_denied = 0;
  bit armed_io_lsu_forward_D_1_corrupt = 0;
  bit armed_io_lsu_forward_D_2_valid = 0;
  bit armed_io_lsu_forward_D_2_data = 0;
  bit armed_io_lsu_forward_D_2_mshrid = 0;
  bit armed_io_lsu_forward_D_2_last = 0;
  bit armed_io_lsu_forward_D_2_denied = 0;
  bit armed_io_lsu_forward_D_2_corrupt = 0;
  bit armed_io_lsu_forward_mshr_0_forward_mshr = 0;
  bit armed_io_lsu_forward_mshr_0_forwardData_0 = 0;
  bit armed_io_lsu_forward_mshr_0_forwardData_1 = 0;
  bit armed_io_lsu_forward_mshr_0_forwardData_2 = 0;
  bit armed_io_lsu_forward_mshr_0_forwardData_3 = 0;
  bit armed_io_lsu_forward_mshr_0_forwardData_4 = 0;
  bit armed_io_lsu_forward_mshr_0_forwardData_5 = 0;
  bit armed_io_lsu_forward_mshr_0_forwardData_6 = 0;
  bit armed_io_lsu_forward_mshr_0_forwardData_7 = 0;
  bit armed_io_lsu_forward_mshr_0_forwardData_8 = 0;
  bit armed_io_lsu_forward_mshr_0_forwardData_9 = 0;
  bit armed_io_lsu_forward_mshr_0_forwardData_10 = 0;
  bit armed_io_lsu_forward_mshr_0_forwardData_11 = 0;
  bit armed_io_lsu_forward_mshr_0_forwardData_12 = 0;
  bit armed_io_lsu_forward_mshr_0_forwardData_13 = 0;
  bit armed_io_lsu_forward_mshr_0_forwardData_14 = 0;
  bit armed_io_lsu_forward_mshr_0_forwardData_15 = 0;
  bit armed_io_lsu_forward_mshr_0_forward_result_valid = 0;
  bit armed_io_lsu_forward_mshr_0_denied = 0;
  bit armed_io_lsu_forward_mshr_0_corrupt = 0;
  bit armed_io_lsu_forward_mshr_1_forward_mshr = 0;
  bit armed_io_lsu_forward_mshr_1_forwardData_0 = 0;
  bit armed_io_lsu_forward_mshr_1_forwardData_1 = 0;
  bit armed_io_lsu_forward_mshr_1_forwardData_2 = 0;
  bit armed_io_lsu_forward_mshr_1_forwardData_3 = 0;
  bit armed_io_lsu_forward_mshr_1_forwardData_4 = 0;
  bit armed_io_lsu_forward_mshr_1_forwardData_5 = 0;
  bit armed_io_lsu_forward_mshr_1_forwardData_6 = 0;
  bit armed_io_lsu_forward_mshr_1_forwardData_7 = 0;
  bit armed_io_lsu_forward_mshr_1_forwardData_8 = 0;
  bit armed_io_lsu_forward_mshr_1_forwardData_9 = 0;
  bit armed_io_lsu_forward_mshr_1_forwardData_10 = 0;
  bit armed_io_lsu_forward_mshr_1_forwardData_11 = 0;
  bit armed_io_lsu_forward_mshr_1_forwardData_12 = 0;
  bit armed_io_lsu_forward_mshr_1_forwardData_13 = 0;
  bit armed_io_lsu_forward_mshr_1_forwardData_14 = 0;
  bit armed_io_lsu_forward_mshr_1_forwardData_15 = 0;
  bit armed_io_lsu_forward_mshr_1_forward_result_valid = 0;
  bit armed_io_lsu_forward_mshr_1_denied = 0;
  bit armed_io_lsu_forward_mshr_1_corrupt = 0;
  bit armed_io_lsu_forward_mshr_2_forward_mshr = 0;
  bit armed_io_lsu_forward_mshr_2_forwardData_0 = 0;
  bit armed_io_lsu_forward_mshr_2_forwardData_1 = 0;
  bit armed_io_lsu_forward_mshr_2_forwardData_2 = 0;
  bit armed_io_lsu_forward_mshr_2_forwardData_3 = 0;
  bit armed_io_lsu_forward_mshr_2_forwardData_4 = 0;
  bit armed_io_lsu_forward_mshr_2_forwardData_5 = 0;
  bit armed_io_lsu_forward_mshr_2_forwardData_6 = 0;
  bit armed_io_lsu_forward_mshr_2_forwardData_7 = 0;
  bit armed_io_lsu_forward_mshr_2_forwardData_8 = 0;
  bit armed_io_lsu_forward_mshr_2_forwardData_9 = 0;
  bit armed_io_lsu_forward_mshr_2_forwardData_10 = 0;
  bit armed_io_lsu_forward_mshr_2_forwardData_11 = 0;
  bit armed_io_lsu_forward_mshr_2_forwardData_12 = 0;
  bit armed_io_lsu_forward_mshr_2_forwardData_13 = 0;
  bit armed_io_lsu_forward_mshr_2_forwardData_14 = 0;
  bit armed_io_lsu_forward_mshr_2_forwardData_15 = 0;
  bit armed_io_lsu_forward_mshr_2_forward_result_valid = 0;
  bit armed_io_lsu_forward_mshr_2_denied = 0;
  bit armed_io_lsu_forward_mshr_2_corrupt = 0;
  bit armed_io_error_valid = 0;
  bit armed_io_error_bits_paddr = 0;
  bit armed_io_error_bits_report_to_beu = 0;
  bit armed_io_pf_ctrl_enable = 0;
  bit armed_io_pf_ctrl_confidence = 0;
  bit armed_io_sms_agt_evict_req_valid = 0;
  bit armed_io_sms_agt_evict_req_bits_vaddr = 0;
  bit armed_io_debugTopDown_robHeadMissInDCache = 0;
  bit armed_io_cmoOpReq_ready = 0;
  bit armed_io_cmoOpResp_valid = 0;
  bit armed_io_cmoOpResp_bits_denied = 0;
  bit armed_io_cmoOpResp_bits_corrupt = 0;
  bit armed_io_l1Miss = 0;
  bit armed_io_wfi_wfiSafe = 0;
  bit armed_io_perf_0_value = 0;
  bit armed_io_perf_1_value = 0;
  bit armed_io_perf_2_value = 0;
  bit armed_io_perf_3_value = 0;
  bit armed_io_perf_4_value = 0;
  bit armed_io_perf_5_value = 0;
  bit armed_io_perf_6_value = 0;
  bit armed_io_perf_7_value = 0;
  bit armed_io_perf_8_value = 0;
  bit armed_io_perf_9_value = 0;
  bit armed_io_perf_10_value = 0;
  bit armed_io_perf_11_value = 0;
  bit armed_io_perf_12_value = 0;
  bit armed_io_perf_13_value = 0;
  bit armed_io_perf_14_value = 0;
  bit armed_io_perf_15_value = 0;
  bit armed_io_perf_16_value = 0;
  bit armed_io_perf_17_value = 0;
  bit armed_io_perf_18_value = 0;
  bit armed_io_perf_19_value = 0;
  bit armed_io_perf_20_value = 0;
  bit armed_io_perf_21_value = 0;
  bit armed_io_perf_22_value = 0;
  bit armed_io_perf_23_value = 0;
  bit armed_io_perf_24_value = 0;
  bit armed_io_perf_25_value = 0;
  bit armed_io_perf_26_value = 0;
  bit armed_io_perf_27_value = 0;
  bit armed_io_perf_28_value = 0;
  bit armed_io_perf_29_value = 0;
  bit armed_io_perf_30_value = 0;
  bit armed_io_perf_31_value = 0;
  bit armed_io_perf_32_value = 0;
  bit armed_io_perf_33_value = 0;
  bit armed_io_perf_34_value = 0;
  bit armed_io_perf_35_value = 0;
  bit armed_io_perf_36_value = 0;
  bit armed_io_perf_37_value = 0;
  bit armed_io_perf_38_value = 0;
  bit armed_io_perf_39_value = 0;
  bit armed_boreChildrenBd_bore_ack = 0;
  bit armed_boreChildrenBd_bore_outdata = 0;
  bit armed_boreChildrenBd_bore_1_ack = 0;
  bit armed_boreChildrenBd_bore_1_outdata = 0;
  bit armed_gatewayIn_packed_41_bore = 0;
  task automatic compare_outputs();
    if (!cmp_all && !armed_auto_cacheCtrlOpt_in_a_ready && g_auto_cacheCtrlOpt_in_a_ready === i_auto_cacheCtrlOpt_in_a_ready) armed_auto_cacheCtrlOpt_in_a_ready = 1;
    if ((cmp_all | armed_auto_cacheCtrlOpt_in_a_ready) && g_auto_cacheCtrlOpt_in_a_ready !== i_auto_cacheCtrlOpt_in_a_ready) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_cacheCtrlOpt_in_a_ready: g=%h i=%h", cyc, g_auto_cacheCtrlOpt_in_a_ready, i_auto_cacheCtrlOpt_in_a_ready);
    end
    seen1_auto_cacheCtrlOpt_in_a_ready |= g_auto_cacheCtrlOpt_in_a_ready;
    seen0_auto_cacheCtrlOpt_in_a_ready |= ~g_auto_cacheCtrlOpt_in_a_ready;
    if (!cmp_all && !armed_auto_cacheCtrlOpt_in_d_valid && g_auto_cacheCtrlOpt_in_d_valid === i_auto_cacheCtrlOpt_in_d_valid) armed_auto_cacheCtrlOpt_in_d_valid = 1;
    if ((cmp_all | armed_auto_cacheCtrlOpt_in_d_valid) && g_auto_cacheCtrlOpt_in_d_valid !== i_auto_cacheCtrlOpt_in_d_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_cacheCtrlOpt_in_d_valid: g=%h i=%h", cyc, g_auto_cacheCtrlOpt_in_d_valid, i_auto_cacheCtrlOpt_in_d_valid);
    end
    seen1_auto_cacheCtrlOpt_in_d_valid |= g_auto_cacheCtrlOpt_in_d_valid;
    seen0_auto_cacheCtrlOpt_in_d_valid |= ~g_auto_cacheCtrlOpt_in_d_valid;
    if (!cmp_all && !armed_auto_cacheCtrlOpt_in_d_bits_opcode && g_auto_cacheCtrlOpt_in_d_bits_opcode === i_auto_cacheCtrlOpt_in_d_bits_opcode) armed_auto_cacheCtrlOpt_in_d_bits_opcode = 1;
    if ((cmp_all | armed_auto_cacheCtrlOpt_in_d_bits_opcode) && (cmp_all | g_auto_cacheCtrlOpt_in_d_valid) && (g_auto_cacheCtrlOpt_in_d_bits_opcode !== i_auto_cacheCtrlOpt_in_d_bits_opcode)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_cacheCtrlOpt_in_d_bits_opcode: g=%h i=%h", cyc, g_auto_cacheCtrlOpt_in_d_bits_opcode, i_auto_cacheCtrlOpt_in_d_bits_opcode);
    end
    seen1_auto_cacheCtrlOpt_in_d_bits_opcode |= g_auto_cacheCtrlOpt_in_d_bits_opcode;
    seen0_auto_cacheCtrlOpt_in_d_bits_opcode |= ~g_auto_cacheCtrlOpt_in_d_bits_opcode;
    if (!cmp_all && !armed_auto_cacheCtrlOpt_in_d_bits_size && g_auto_cacheCtrlOpt_in_d_bits_size === i_auto_cacheCtrlOpt_in_d_bits_size) armed_auto_cacheCtrlOpt_in_d_bits_size = 1;
    if ((cmp_all | armed_auto_cacheCtrlOpt_in_d_bits_size) && (cmp_all | g_auto_cacheCtrlOpt_in_d_valid) && (g_auto_cacheCtrlOpt_in_d_bits_size !== i_auto_cacheCtrlOpt_in_d_bits_size)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_cacheCtrlOpt_in_d_bits_size: g=%h i=%h", cyc, g_auto_cacheCtrlOpt_in_d_bits_size, i_auto_cacheCtrlOpt_in_d_bits_size);
    end
    seen1_auto_cacheCtrlOpt_in_d_bits_size |= g_auto_cacheCtrlOpt_in_d_bits_size;
    seen0_auto_cacheCtrlOpt_in_d_bits_size |= ~g_auto_cacheCtrlOpt_in_d_bits_size;
    if (!cmp_all && !armed_auto_cacheCtrlOpt_in_d_bits_source && g_auto_cacheCtrlOpt_in_d_bits_source === i_auto_cacheCtrlOpt_in_d_bits_source) armed_auto_cacheCtrlOpt_in_d_bits_source = 1;
    if ((cmp_all | armed_auto_cacheCtrlOpt_in_d_bits_source) && (cmp_all | g_auto_cacheCtrlOpt_in_d_valid) && (g_auto_cacheCtrlOpt_in_d_bits_source !== i_auto_cacheCtrlOpt_in_d_bits_source)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_cacheCtrlOpt_in_d_bits_source: g=%h i=%h", cyc, g_auto_cacheCtrlOpt_in_d_bits_source, i_auto_cacheCtrlOpt_in_d_bits_source);
    end
    seen1_auto_cacheCtrlOpt_in_d_bits_source |= g_auto_cacheCtrlOpt_in_d_bits_source;
    seen0_auto_cacheCtrlOpt_in_d_bits_source |= ~g_auto_cacheCtrlOpt_in_d_bits_source;
    if (!cmp_all && !armed_auto_cacheCtrlOpt_in_d_bits_data && g_auto_cacheCtrlOpt_in_d_bits_data === i_auto_cacheCtrlOpt_in_d_bits_data) armed_auto_cacheCtrlOpt_in_d_bits_data = 1;
    if ((cmp_all | armed_auto_cacheCtrlOpt_in_d_bits_data) && (cmp_all | g_auto_cacheCtrlOpt_in_d_valid) && (g_auto_cacheCtrlOpt_in_d_bits_data !== i_auto_cacheCtrlOpt_in_d_bits_data)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_cacheCtrlOpt_in_d_bits_data: g=%h i=%h", cyc, g_auto_cacheCtrlOpt_in_d_bits_data, i_auto_cacheCtrlOpt_in_d_bits_data);
    end
    seen1_auto_cacheCtrlOpt_in_d_bits_data |= g_auto_cacheCtrlOpt_in_d_bits_data;
    seen0_auto_cacheCtrlOpt_in_d_bits_data |= ~g_auto_cacheCtrlOpt_in_d_bits_data;
    if (!cmp_all && !armed_auto_client_out_a_valid && g_auto_client_out_a_valid === i_auto_client_out_a_valid) armed_auto_client_out_a_valid = 1;
    if ((cmp_all | armed_auto_client_out_a_valid) && g_auto_client_out_a_valid !== i_auto_client_out_a_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_a_valid: g=%h i=%h", cyc, g_auto_client_out_a_valid, i_auto_client_out_a_valid);
    end
    seen1_auto_client_out_a_valid |= g_auto_client_out_a_valid;
    seen0_auto_client_out_a_valid |= ~g_auto_client_out_a_valid;
    if (!cmp_all && !armed_auto_client_out_a_bits_opcode && g_auto_client_out_a_bits_opcode === i_auto_client_out_a_bits_opcode) armed_auto_client_out_a_bits_opcode = 1;
    if ((cmp_all | armed_auto_client_out_a_bits_opcode) && (cmp_all | g_auto_client_out_a_valid) && (g_auto_client_out_a_bits_opcode !== i_auto_client_out_a_bits_opcode)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_a_bits_opcode: g=%h i=%h", cyc, g_auto_client_out_a_bits_opcode, i_auto_client_out_a_bits_opcode);
    end
    seen1_auto_client_out_a_bits_opcode |= g_auto_client_out_a_bits_opcode;
    seen0_auto_client_out_a_bits_opcode |= ~g_auto_client_out_a_bits_opcode;
    if (!cmp_all && !armed_auto_client_out_a_bits_param && g_auto_client_out_a_bits_param === i_auto_client_out_a_bits_param) armed_auto_client_out_a_bits_param = 1;
    if ((cmp_all | armed_auto_client_out_a_bits_param) && (cmp_all | g_auto_client_out_a_valid) && (g_auto_client_out_a_bits_param !== i_auto_client_out_a_bits_param)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_a_bits_param: g=%h i=%h", cyc, g_auto_client_out_a_bits_param, i_auto_client_out_a_bits_param);
    end
    seen1_auto_client_out_a_bits_param |= g_auto_client_out_a_bits_param;
    seen0_auto_client_out_a_bits_param |= ~g_auto_client_out_a_bits_param;
    if (!cmp_all && !armed_auto_client_out_a_bits_size && g_auto_client_out_a_bits_size === i_auto_client_out_a_bits_size) armed_auto_client_out_a_bits_size = 1;
    if ((cmp_all | armed_auto_client_out_a_bits_size) && (cmp_all | g_auto_client_out_a_valid) && (g_auto_client_out_a_bits_size !== i_auto_client_out_a_bits_size)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_a_bits_size: g=%h i=%h", cyc, g_auto_client_out_a_bits_size, i_auto_client_out_a_bits_size);
    end
    seen1_auto_client_out_a_bits_size |= g_auto_client_out_a_bits_size;
    seen0_auto_client_out_a_bits_size |= ~g_auto_client_out_a_bits_size;
    if (!cmp_all && !armed_auto_client_out_a_bits_source && g_auto_client_out_a_bits_source === i_auto_client_out_a_bits_source) armed_auto_client_out_a_bits_source = 1;
    if ((cmp_all | armed_auto_client_out_a_bits_source) && (cmp_all | g_auto_client_out_a_valid) && (g_auto_client_out_a_bits_source !== i_auto_client_out_a_bits_source)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_a_bits_source: g=%h i=%h", cyc, g_auto_client_out_a_bits_source, i_auto_client_out_a_bits_source);
    end
    seen1_auto_client_out_a_bits_source |= g_auto_client_out_a_bits_source;
    seen0_auto_client_out_a_bits_source |= ~g_auto_client_out_a_bits_source;
    if (!cmp_all && !armed_auto_client_out_a_bits_address && g_auto_client_out_a_bits_address === i_auto_client_out_a_bits_address) armed_auto_client_out_a_bits_address = 1;
    if ((cmp_all | armed_auto_client_out_a_bits_address) && (cmp_all | g_auto_client_out_a_valid) && (g_auto_client_out_a_bits_address !== i_auto_client_out_a_bits_address)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_a_bits_address: g=%h i=%h", cyc, g_auto_client_out_a_bits_address, i_auto_client_out_a_bits_address);
    end
    seen1_auto_client_out_a_bits_address |= g_auto_client_out_a_bits_address;
    seen0_auto_client_out_a_bits_address |= ~g_auto_client_out_a_bits_address;
    if (!cmp_all && !armed_auto_client_out_a_bits_user_alias && g_auto_client_out_a_bits_user_alias === i_auto_client_out_a_bits_user_alias) armed_auto_client_out_a_bits_user_alias = 1;
    if ((cmp_all | armed_auto_client_out_a_bits_user_alias) && (cmp_all | g_auto_client_out_a_valid) && (g_auto_client_out_a_bits_user_alias !== i_auto_client_out_a_bits_user_alias)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_a_bits_user_alias: g=%h i=%h", cyc, g_auto_client_out_a_bits_user_alias, i_auto_client_out_a_bits_user_alias);
    end
    seen1_auto_client_out_a_bits_user_alias |= g_auto_client_out_a_bits_user_alias;
    seen0_auto_client_out_a_bits_user_alias |= ~g_auto_client_out_a_bits_user_alias;
    if (!cmp_all && !armed_auto_client_out_a_bits_user_vaddr && g_auto_client_out_a_bits_user_vaddr === i_auto_client_out_a_bits_user_vaddr) armed_auto_client_out_a_bits_user_vaddr = 1;
    if ((cmp_all | armed_auto_client_out_a_bits_user_vaddr) && (cmp_all | g_auto_client_out_a_valid) && (g_auto_client_out_a_bits_user_vaddr !== i_auto_client_out_a_bits_user_vaddr)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_a_bits_user_vaddr: g=%h i=%h", cyc, g_auto_client_out_a_bits_user_vaddr, i_auto_client_out_a_bits_user_vaddr);
    end
    seen1_auto_client_out_a_bits_user_vaddr |= g_auto_client_out_a_bits_user_vaddr;
    seen0_auto_client_out_a_bits_user_vaddr |= ~g_auto_client_out_a_bits_user_vaddr;
    if (!cmp_all && !armed_auto_client_out_a_bits_user_reqSource && g_auto_client_out_a_bits_user_reqSource === i_auto_client_out_a_bits_user_reqSource) armed_auto_client_out_a_bits_user_reqSource = 1;
    if ((cmp_all | armed_auto_client_out_a_bits_user_reqSource) && (cmp_all | g_auto_client_out_a_valid) && (g_auto_client_out_a_bits_user_reqSource !== i_auto_client_out_a_bits_user_reqSource)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_a_bits_user_reqSource: g=%h i=%h", cyc, g_auto_client_out_a_bits_user_reqSource, i_auto_client_out_a_bits_user_reqSource);
    end
    seen1_auto_client_out_a_bits_user_reqSource |= g_auto_client_out_a_bits_user_reqSource;
    seen0_auto_client_out_a_bits_user_reqSource |= ~g_auto_client_out_a_bits_user_reqSource;
    if (!cmp_all && !armed_auto_client_out_a_bits_user_needHint && g_auto_client_out_a_bits_user_needHint === i_auto_client_out_a_bits_user_needHint) armed_auto_client_out_a_bits_user_needHint = 1;
    if ((cmp_all | armed_auto_client_out_a_bits_user_needHint) && (cmp_all | g_auto_client_out_a_valid) && (g_auto_client_out_a_bits_user_needHint !== i_auto_client_out_a_bits_user_needHint)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_a_bits_user_needHint: g=%h i=%h", cyc, g_auto_client_out_a_bits_user_needHint, i_auto_client_out_a_bits_user_needHint);
    end
    seen1_auto_client_out_a_bits_user_needHint |= g_auto_client_out_a_bits_user_needHint;
    seen0_auto_client_out_a_bits_user_needHint |= ~g_auto_client_out_a_bits_user_needHint;
    if (!cmp_all && !armed_auto_client_out_a_bits_echo_isKeyword && g_auto_client_out_a_bits_echo_isKeyword === i_auto_client_out_a_bits_echo_isKeyword) armed_auto_client_out_a_bits_echo_isKeyword = 1;
    if ((cmp_all | armed_auto_client_out_a_bits_echo_isKeyword) && (cmp_all | g_auto_client_out_a_valid) && (g_auto_client_out_a_bits_echo_isKeyword !== i_auto_client_out_a_bits_echo_isKeyword)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_a_bits_echo_isKeyword: g=%h i=%h", cyc, g_auto_client_out_a_bits_echo_isKeyword, i_auto_client_out_a_bits_echo_isKeyword);
    end
    seen1_auto_client_out_a_bits_echo_isKeyword |= g_auto_client_out_a_bits_echo_isKeyword;
    seen0_auto_client_out_a_bits_echo_isKeyword |= ~g_auto_client_out_a_bits_echo_isKeyword;
    if (!cmp_all && !armed_auto_client_out_a_bits_mask && g_auto_client_out_a_bits_mask === i_auto_client_out_a_bits_mask) armed_auto_client_out_a_bits_mask = 1;
    if ((cmp_all | armed_auto_client_out_a_bits_mask) && (cmp_all | g_auto_client_out_a_valid) && (g_auto_client_out_a_bits_mask !== i_auto_client_out_a_bits_mask)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_a_bits_mask: g=%h i=%h", cyc, g_auto_client_out_a_bits_mask, i_auto_client_out_a_bits_mask);
    end
    seen1_auto_client_out_a_bits_mask |= g_auto_client_out_a_bits_mask;
    seen0_auto_client_out_a_bits_mask |= ~g_auto_client_out_a_bits_mask;
    if (!cmp_all && !armed_auto_client_out_b_ready && g_auto_client_out_b_ready === i_auto_client_out_b_ready) armed_auto_client_out_b_ready = 1;
    if ((cmp_all | armed_auto_client_out_b_ready) && g_auto_client_out_b_ready !== i_auto_client_out_b_ready) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_b_ready: g=%h i=%h", cyc, g_auto_client_out_b_ready, i_auto_client_out_b_ready);
    end
    seen1_auto_client_out_b_ready |= g_auto_client_out_b_ready;
    seen0_auto_client_out_b_ready |= ~g_auto_client_out_b_ready;
    if (!cmp_all && !armed_auto_client_out_c_valid && g_auto_client_out_c_valid === i_auto_client_out_c_valid) armed_auto_client_out_c_valid = 1;
    if ((cmp_all | armed_auto_client_out_c_valid) && g_auto_client_out_c_valid !== i_auto_client_out_c_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_c_valid: g=%h i=%h", cyc, g_auto_client_out_c_valid, i_auto_client_out_c_valid);
    end
    seen1_auto_client_out_c_valid |= g_auto_client_out_c_valid;
    seen0_auto_client_out_c_valid |= ~g_auto_client_out_c_valid;
    if (!cmp_all && !armed_auto_client_out_c_bits_opcode && g_auto_client_out_c_bits_opcode === i_auto_client_out_c_bits_opcode) armed_auto_client_out_c_bits_opcode = 1;
    if ((cmp_all | armed_auto_client_out_c_bits_opcode) && (cmp_all | g_auto_client_out_c_valid) && (g_auto_client_out_c_bits_opcode !== i_auto_client_out_c_bits_opcode)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_c_bits_opcode: g=%h i=%h", cyc, g_auto_client_out_c_bits_opcode, i_auto_client_out_c_bits_opcode);
    end
    seen1_auto_client_out_c_bits_opcode |= g_auto_client_out_c_bits_opcode;
    seen0_auto_client_out_c_bits_opcode |= ~g_auto_client_out_c_bits_opcode;
    if (!cmp_all && !armed_auto_client_out_c_bits_param && g_auto_client_out_c_bits_param === i_auto_client_out_c_bits_param) armed_auto_client_out_c_bits_param = 1;
    if ((cmp_all | armed_auto_client_out_c_bits_param) && (cmp_all | g_auto_client_out_c_valid) && (g_auto_client_out_c_bits_param !== i_auto_client_out_c_bits_param)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_c_bits_param: g=%h i=%h", cyc, g_auto_client_out_c_bits_param, i_auto_client_out_c_bits_param);
    end
    seen1_auto_client_out_c_bits_param |= g_auto_client_out_c_bits_param;
    seen0_auto_client_out_c_bits_param |= ~g_auto_client_out_c_bits_param;
    if (!cmp_all && !armed_auto_client_out_c_bits_size && g_auto_client_out_c_bits_size === i_auto_client_out_c_bits_size) armed_auto_client_out_c_bits_size = 1;
    if ((cmp_all | armed_auto_client_out_c_bits_size) && (cmp_all | g_auto_client_out_c_valid) && (g_auto_client_out_c_bits_size !== i_auto_client_out_c_bits_size)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_c_bits_size: g=%h i=%h", cyc, g_auto_client_out_c_bits_size, i_auto_client_out_c_bits_size);
    end
    seen1_auto_client_out_c_bits_size |= g_auto_client_out_c_bits_size;
    seen0_auto_client_out_c_bits_size |= ~g_auto_client_out_c_bits_size;
    if (!cmp_all && !armed_auto_client_out_c_bits_source && g_auto_client_out_c_bits_source === i_auto_client_out_c_bits_source) armed_auto_client_out_c_bits_source = 1;
    if ((cmp_all | armed_auto_client_out_c_bits_source) && (cmp_all | g_auto_client_out_c_valid) && (g_auto_client_out_c_bits_source !== i_auto_client_out_c_bits_source)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_c_bits_source: g=%h i=%h", cyc, g_auto_client_out_c_bits_source, i_auto_client_out_c_bits_source);
    end
    seen1_auto_client_out_c_bits_source |= g_auto_client_out_c_bits_source;
    seen0_auto_client_out_c_bits_source |= ~g_auto_client_out_c_bits_source;
    if (!cmp_all && !armed_auto_client_out_c_bits_address && g_auto_client_out_c_bits_address === i_auto_client_out_c_bits_address) armed_auto_client_out_c_bits_address = 1;
    if ((cmp_all | armed_auto_client_out_c_bits_address) && (cmp_all | g_auto_client_out_c_valid) && (g_auto_client_out_c_bits_address !== i_auto_client_out_c_bits_address)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_c_bits_address: g=%h i=%h", cyc, g_auto_client_out_c_bits_address, i_auto_client_out_c_bits_address);
    end
    seen1_auto_client_out_c_bits_address |= g_auto_client_out_c_bits_address;
    seen0_auto_client_out_c_bits_address |= ~g_auto_client_out_c_bits_address;
    if (!cmp_all && !armed_auto_client_out_c_bits_data && g_auto_client_out_c_bits_data === i_auto_client_out_c_bits_data) armed_auto_client_out_c_bits_data = 1;
    if ((cmp_all | armed_auto_client_out_c_bits_data) && (cmp_all | g_auto_client_out_c_valid) && (g_auto_client_out_c_bits_data !== i_auto_client_out_c_bits_data)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_c_bits_data: g=%h i=%h", cyc, g_auto_client_out_c_bits_data, i_auto_client_out_c_bits_data);
    end
    seen1_auto_client_out_c_bits_data |= g_auto_client_out_c_bits_data;
    seen0_auto_client_out_c_bits_data |= ~g_auto_client_out_c_bits_data;
    if (!cmp_all && !armed_auto_client_out_c_bits_corrupt && g_auto_client_out_c_bits_corrupt === i_auto_client_out_c_bits_corrupt) armed_auto_client_out_c_bits_corrupt = 1;
    if ((cmp_all | armed_auto_client_out_c_bits_corrupt) && (cmp_all | g_auto_client_out_c_valid) && (g_auto_client_out_c_bits_corrupt !== i_auto_client_out_c_bits_corrupt)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_c_bits_corrupt: g=%h i=%h", cyc, g_auto_client_out_c_bits_corrupt, i_auto_client_out_c_bits_corrupt);
    end
    seen1_auto_client_out_c_bits_corrupt |= g_auto_client_out_c_bits_corrupt;
    seen0_auto_client_out_c_bits_corrupt |= ~g_auto_client_out_c_bits_corrupt;
    if (!cmp_all && !armed_auto_client_out_d_ready && g_auto_client_out_d_ready === i_auto_client_out_d_ready) armed_auto_client_out_d_ready = 1;
    if ((cmp_all | armed_auto_client_out_d_ready) && g_auto_client_out_d_ready !== i_auto_client_out_d_ready) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_d_ready: g=%h i=%h", cyc, g_auto_client_out_d_ready, i_auto_client_out_d_ready);
    end
    seen1_auto_client_out_d_ready |= g_auto_client_out_d_ready;
    seen0_auto_client_out_d_ready |= ~g_auto_client_out_d_ready;
    if (!cmp_all && !armed_auto_client_out_e_valid && g_auto_client_out_e_valid === i_auto_client_out_e_valid) armed_auto_client_out_e_valid = 1;
    if ((cmp_all | armed_auto_client_out_e_valid) && g_auto_client_out_e_valid !== i_auto_client_out_e_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_e_valid: g=%h i=%h", cyc, g_auto_client_out_e_valid, i_auto_client_out_e_valid);
    end
    seen1_auto_client_out_e_valid |= g_auto_client_out_e_valid;
    seen0_auto_client_out_e_valid |= ~g_auto_client_out_e_valid;
    if (!cmp_all && !armed_auto_client_out_e_bits_sink && g_auto_client_out_e_bits_sink === i_auto_client_out_e_bits_sink) armed_auto_client_out_e_bits_sink = 1;
    if ((cmp_all | armed_auto_client_out_e_bits_sink) && (cmp_all | g_auto_client_out_e_valid) && (g_auto_client_out_e_bits_sink !== i_auto_client_out_e_bits_sink)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d auto_client_out_e_bits_sink: g=%h i=%h", cyc, g_auto_client_out_e_bits_sink, i_auto_client_out_e_bits_sink);
    end
    seen1_auto_client_out_e_bits_sink |= g_auto_client_out_e_bits_sink;
    seen0_auto_client_out_e_bits_sink |= ~g_auto_client_out_e_bits_sink;
    if (!cmp_all && !armed_io_lsu_load_0_req_ready && g_io_lsu_load_0_req_ready === i_io_lsu_load_0_req_ready) armed_io_lsu_load_0_req_ready = 1;
    if ((cmp_all | armed_io_lsu_load_0_req_ready) && g_io_lsu_load_0_req_ready !== i_io_lsu_load_0_req_ready) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_0_req_ready: g=%h i=%h", cyc, g_io_lsu_load_0_req_ready, i_io_lsu_load_0_req_ready);
    end
    seen1_io_lsu_load_0_req_ready |= g_io_lsu_load_0_req_ready;
    seen0_io_lsu_load_0_req_ready |= ~g_io_lsu_load_0_req_ready;
    if (!cmp_all && !armed_io_lsu_load_0_resp_valid && g_io_lsu_load_0_resp_valid === i_io_lsu_load_0_resp_valid) armed_io_lsu_load_0_resp_valid = 1;
    if ((cmp_all | armed_io_lsu_load_0_resp_valid) && g_io_lsu_load_0_resp_valid !== i_io_lsu_load_0_resp_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_0_resp_valid: g=%h i=%h", cyc, g_io_lsu_load_0_resp_valid, i_io_lsu_load_0_resp_valid);
    end
    seen1_io_lsu_load_0_resp_valid |= g_io_lsu_load_0_resp_valid;
    seen0_io_lsu_load_0_resp_valid |= ~g_io_lsu_load_0_resp_valid;
    if (!cmp_all && !armed_io_lsu_load_0_resp_bits_data && g_io_lsu_load_0_resp_bits_data === i_io_lsu_load_0_resp_bits_data) armed_io_lsu_load_0_resp_bits_data = 1;
    if ((cmp_all | armed_io_lsu_load_0_resp_bits_data) && (cmp_all | g_io_lsu_load_0_resp_valid) && (g_io_lsu_load_0_resp_bits_data !== i_io_lsu_load_0_resp_bits_data)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_0_resp_bits_data: g=%h i=%h", cyc, g_io_lsu_load_0_resp_bits_data, i_io_lsu_load_0_resp_bits_data);
    end
    seen1_io_lsu_load_0_resp_bits_data |= g_io_lsu_load_0_resp_bits_data;
    seen0_io_lsu_load_0_resp_bits_data |= ~g_io_lsu_load_0_resp_bits_data;
    if (!cmp_all && !armed_io_lsu_load_0_resp_bits_data_delayed && g_io_lsu_load_0_resp_bits_data_delayed === i_io_lsu_load_0_resp_bits_data_delayed) armed_io_lsu_load_0_resp_bits_data_delayed = 1;
    if ((cmp_all | armed_io_lsu_load_0_resp_bits_data_delayed) && (cmp_all | g_io_lsu_load_0_resp_valid) && (g_io_lsu_load_0_resp_bits_data_delayed !== i_io_lsu_load_0_resp_bits_data_delayed)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_0_resp_bits_data_delayed: g=%h i=%h", cyc, g_io_lsu_load_0_resp_bits_data_delayed, i_io_lsu_load_0_resp_bits_data_delayed);
    end
    seen1_io_lsu_load_0_resp_bits_data_delayed |= g_io_lsu_load_0_resp_bits_data_delayed;
    seen0_io_lsu_load_0_resp_bits_data_delayed |= ~g_io_lsu_load_0_resp_bits_data_delayed;
    if (!cmp_all && !armed_io_lsu_load_0_resp_bits_miss && g_io_lsu_load_0_resp_bits_miss === i_io_lsu_load_0_resp_bits_miss) armed_io_lsu_load_0_resp_bits_miss = 1;
    if ((cmp_all | armed_io_lsu_load_0_resp_bits_miss) && (cmp_all | g_io_lsu_load_0_resp_valid) && (g_io_lsu_load_0_resp_bits_miss !== i_io_lsu_load_0_resp_bits_miss)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_0_resp_bits_miss: g=%h i=%h", cyc, g_io_lsu_load_0_resp_bits_miss, i_io_lsu_load_0_resp_bits_miss);
    end
    seen1_io_lsu_load_0_resp_bits_miss |= g_io_lsu_load_0_resp_bits_miss;
    seen0_io_lsu_load_0_resp_bits_miss |= ~g_io_lsu_load_0_resp_bits_miss;
    if (!cmp_all && !armed_io_lsu_load_0_resp_bits_mshr_id && g_io_lsu_load_0_resp_bits_mshr_id === i_io_lsu_load_0_resp_bits_mshr_id) armed_io_lsu_load_0_resp_bits_mshr_id = 1;
    if ((cmp_all | armed_io_lsu_load_0_resp_bits_mshr_id) && (cmp_all | g_io_lsu_load_0_resp_valid) && (g_io_lsu_load_0_resp_bits_mshr_id !== i_io_lsu_load_0_resp_bits_mshr_id)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_0_resp_bits_mshr_id: g=%h i=%h", cyc, g_io_lsu_load_0_resp_bits_mshr_id, i_io_lsu_load_0_resp_bits_mshr_id);
    end
    seen1_io_lsu_load_0_resp_bits_mshr_id |= g_io_lsu_load_0_resp_bits_mshr_id;
    seen0_io_lsu_load_0_resp_bits_mshr_id |= ~g_io_lsu_load_0_resp_bits_mshr_id;
    if (!cmp_all && !armed_io_lsu_load_0_resp_bits_meta_prefetch && g_io_lsu_load_0_resp_bits_meta_prefetch === i_io_lsu_load_0_resp_bits_meta_prefetch) armed_io_lsu_load_0_resp_bits_meta_prefetch = 1;
    if ((cmp_all | armed_io_lsu_load_0_resp_bits_meta_prefetch) && (cmp_all | g_io_lsu_load_0_resp_valid) && (g_io_lsu_load_0_resp_bits_meta_prefetch !== i_io_lsu_load_0_resp_bits_meta_prefetch)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_0_resp_bits_meta_prefetch: g=%h i=%h", cyc, g_io_lsu_load_0_resp_bits_meta_prefetch, i_io_lsu_load_0_resp_bits_meta_prefetch);
    end
    seen1_io_lsu_load_0_resp_bits_meta_prefetch |= g_io_lsu_load_0_resp_bits_meta_prefetch;
    seen0_io_lsu_load_0_resp_bits_meta_prefetch |= ~g_io_lsu_load_0_resp_bits_meta_prefetch;
    if (!cmp_all && !armed_io_lsu_load_0_resp_bits_handled && g_io_lsu_load_0_resp_bits_handled === i_io_lsu_load_0_resp_bits_handled) armed_io_lsu_load_0_resp_bits_handled = 1;
    if ((cmp_all | armed_io_lsu_load_0_resp_bits_handled) && (cmp_all | g_io_lsu_load_0_resp_valid) && (g_io_lsu_load_0_resp_bits_handled !== i_io_lsu_load_0_resp_bits_handled)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_0_resp_bits_handled: g=%h i=%h", cyc, g_io_lsu_load_0_resp_bits_handled, i_io_lsu_load_0_resp_bits_handled);
    end
    seen1_io_lsu_load_0_resp_bits_handled |= g_io_lsu_load_0_resp_bits_handled;
    seen0_io_lsu_load_0_resp_bits_handled |= ~g_io_lsu_load_0_resp_bits_handled;
    if (!cmp_all && !armed_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied && g_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied === i_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied) armed_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied = 1;
    if ((cmp_all | armed_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied) && (cmp_all | g_io_lsu_load_0_resp_valid) && (g_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied !== i_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied: g=%h i=%h", cyc, g_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied, i_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied);
    end
    seen1_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied |= g_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied;
    seen0_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied |= ~g_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied;
    if (!cmp_all && !armed_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt && g_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt === i_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt) armed_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt = 1;
    if ((cmp_all | armed_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt) && (cmp_all | g_io_lsu_load_0_resp_valid) && (g_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt !== i_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt: g=%h i=%h", cyc, g_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt, i_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt);
    end
    seen1_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt |= g_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt;
    seen0_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt |= ~g_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt;
    if (!cmp_all && !armed_io_lsu_load_0_s2_bank_conflict && g_io_lsu_load_0_s2_bank_conflict === i_io_lsu_load_0_s2_bank_conflict) armed_io_lsu_load_0_s2_bank_conflict = 1;
    if ((cmp_all | armed_io_lsu_load_0_s2_bank_conflict) && g_io_lsu_load_0_s2_bank_conflict !== i_io_lsu_load_0_s2_bank_conflict) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_0_s2_bank_conflict: g=%h i=%h", cyc, g_io_lsu_load_0_s2_bank_conflict, i_io_lsu_load_0_s2_bank_conflict);
    end
    seen1_io_lsu_load_0_s2_bank_conflict |= g_io_lsu_load_0_s2_bank_conflict;
    seen0_io_lsu_load_0_s2_bank_conflict |= ~g_io_lsu_load_0_s2_bank_conflict;
    if (!cmp_all && !armed_io_lsu_load_0_s2_mq_nack && g_io_lsu_load_0_s2_mq_nack === i_io_lsu_load_0_s2_mq_nack) armed_io_lsu_load_0_s2_mq_nack = 1;
    if ((cmp_all | armed_io_lsu_load_0_s2_mq_nack) && g_io_lsu_load_0_s2_mq_nack !== i_io_lsu_load_0_s2_mq_nack) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_0_s2_mq_nack: g=%h i=%h", cyc, g_io_lsu_load_0_s2_mq_nack, i_io_lsu_load_0_s2_mq_nack);
    end
    seen1_io_lsu_load_0_s2_mq_nack |= g_io_lsu_load_0_s2_mq_nack;
    seen0_io_lsu_load_0_s2_mq_nack |= ~g_io_lsu_load_0_s2_mq_nack;
    if (!cmp_all && !armed_io_lsu_load_1_req_ready && g_io_lsu_load_1_req_ready === i_io_lsu_load_1_req_ready) armed_io_lsu_load_1_req_ready = 1;
    if ((cmp_all | armed_io_lsu_load_1_req_ready) && g_io_lsu_load_1_req_ready !== i_io_lsu_load_1_req_ready) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_1_req_ready: g=%h i=%h", cyc, g_io_lsu_load_1_req_ready, i_io_lsu_load_1_req_ready);
    end
    seen1_io_lsu_load_1_req_ready |= g_io_lsu_load_1_req_ready;
    seen0_io_lsu_load_1_req_ready |= ~g_io_lsu_load_1_req_ready;
    if (!cmp_all && !armed_io_lsu_load_1_resp_valid && g_io_lsu_load_1_resp_valid === i_io_lsu_load_1_resp_valid) armed_io_lsu_load_1_resp_valid = 1;
    if ((cmp_all | armed_io_lsu_load_1_resp_valid) && g_io_lsu_load_1_resp_valid !== i_io_lsu_load_1_resp_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_1_resp_valid: g=%h i=%h", cyc, g_io_lsu_load_1_resp_valid, i_io_lsu_load_1_resp_valid);
    end
    seen1_io_lsu_load_1_resp_valid |= g_io_lsu_load_1_resp_valid;
    seen0_io_lsu_load_1_resp_valid |= ~g_io_lsu_load_1_resp_valid;
    if (!cmp_all && !armed_io_lsu_load_1_resp_bits_data && g_io_lsu_load_1_resp_bits_data === i_io_lsu_load_1_resp_bits_data) armed_io_lsu_load_1_resp_bits_data = 1;
    if ((cmp_all | armed_io_lsu_load_1_resp_bits_data) && (cmp_all | g_io_lsu_load_1_resp_valid) && (g_io_lsu_load_1_resp_bits_data !== i_io_lsu_load_1_resp_bits_data)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_1_resp_bits_data: g=%h i=%h", cyc, g_io_lsu_load_1_resp_bits_data, i_io_lsu_load_1_resp_bits_data);
    end
    seen1_io_lsu_load_1_resp_bits_data |= g_io_lsu_load_1_resp_bits_data;
    seen0_io_lsu_load_1_resp_bits_data |= ~g_io_lsu_load_1_resp_bits_data;
    if (!cmp_all && !armed_io_lsu_load_1_resp_bits_miss && g_io_lsu_load_1_resp_bits_miss === i_io_lsu_load_1_resp_bits_miss) armed_io_lsu_load_1_resp_bits_miss = 1;
    if ((cmp_all | armed_io_lsu_load_1_resp_bits_miss) && (cmp_all | g_io_lsu_load_1_resp_valid) && (g_io_lsu_load_1_resp_bits_miss !== i_io_lsu_load_1_resp_bits_miss)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_1_resp_bits_miss: g=%h i=%h", cyc, g_io_lsu_load_1_resp_bits_miss, i_io_lsu_load_1_resp_bits_miss);
    end
    seen1_io_lsu_load_1_resp_bits_miss |= g_io_lsu_load_1_resp_bits_miss;
    seen0_io_lsu_load_1_resp_bits_miss |= ~g_io_lsu_load_1_resp_bits_miss;
    if (!cmp_all && !armed_io_lsu_load_1_resp_bits_mshr_id && g_io_lsu_load_1_resp_bits_mshr_id === i_io_lsu_load_1_resp_bits_mshr_id) armed_io_lsu_load_1_resp_bits_mshr_id = 1;
    if ((cmp_all | armed_io_lsu_load_1_resp_bits_mshr_id) && (cmp_all | g_io_lsu_load_1_resp_valid) && (g_io_lsu_load_1_resp_bits_mshr_id !== i_io_lsu_load_1_resp_bits_mshr_id)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_1_resp_bits_mshr_id: g=%h i=%h", cyc, g_io_lsu_load_1_resp_bits_mshr_id, i_io_lsu_load_1_resp_bits_mshr_id);
    end
    seen1_io_lsu_load_1_resp_bits_mshr_id |= g_io_lsu_load_1_resp_bits_mshr_id;
    seen0_io_lsu_load_1_resp_bits_mshr_id |= ~g_io_lsu_load_1_resp_bits_mshr_id;
    if (!cmp_all && !armed_io_lsu_load_1_resp_bits_meta_prefetch && g_io_lsu_load_1_resp_bits_meta_prefetch === i_io_lsu_load_1_resp_bits_meta_prefetch) armed_io_lsu_load_1_resp_bits_meta_prefetch = 1;
    if ((cmp_all | armed_io_lsu_load_1_resp_bits_meta_prefetch) && (cmp_all | g_io_lsu_load_1_resp_valid) && (g_io_lsu_load_1_resp_bits_meta_prefetch !== i_io_lsu_load_1_resp_bits_meta_prefetch)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_1_resp_bits_meta_prefetch: g=%h i=%h", cyc, g_io_lsu_load_1_resp_bits_meta_prefetch, i_io_lsu_load_1_resp_bits_meta_prefetch);
    end
    seen1_io_lsu_load_1_resp_bits_meta_prefetch |= g_io_lsu_load_1_resp_bits_meta_prefetch;
    seen0_io_lsu_load_1_resp_bits_meta_prefetch |= ~g_io_lsu_load_1_resp_bits_meta_prefetch;
    if (!cmp_all && !armed_io_lsu_load_1_resp_bits_handled && g_io_lsu_load_1_resp_bits_handled === i_io_lsu_load_1_resp_bits_handled) armed_io_lsu_load_1_resp_bits_handled = 1;
    if ((cmp_all | armed_io_lsu_load_1_resp_bits_handled) && (cmp_all | g_io_lsu_load_1_resp_valid) && (g_io_lsu_load_1_resp_bits_handled !== i_io_lsu_load_1_resp_bits_handled)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_1_resp_bits_handled: g=%h i=%h", cyc, g_io_lsu_load_1_resp_bits_handled, i_io_lsu_load_1_resp_bits_handled);
    end
    seen1_io_lsu_load_1_resp_bits_handled |= g_io_lsu_load_1_resp_bits_handled;
    seen0_io_lsu_load_1_resp_bits_handled |= ~g_io_lsu_load_1_resp_bits_handled;
    if (!cmp_all && !armed_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied && g_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied === i_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied) armed_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied = 1;
    if ((cmp_all | armed_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied) && (cmp_all | g_io_lsu_load_1_resp_valid) && (g_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied !== i_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied: g=%h i=%h", cyc, g_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied, i_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied);
    end
    seen1_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied |= g_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied;
    seen0_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied |= ~g_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied;
    if (!cmp_all && !armed_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt && g_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt === i_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt) armed_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt = 1;
    if ((cmp_all | armed_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt) && (cmp_all | g_io_lsu_load_1_resp_valid) && (g_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt !== i_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt: g=%h i=%h", cyc, g_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt, i_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt);
    end
    seen1_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt |= g_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt;
    seen0_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt |= ~g_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt;
    if (!cmp_all && !armed_io_lsu_load_1_s2_bank_conflict && g_io_lsu_load_1_s2_bank_conflict === i_io_lsu_load_1_s2_bank_conflict) armed_io_lsu_load_1_s2_bank_conflict = 1;
    if ((cmp_all | armed_io_lsu_load_1_s2_bank_conflict) && g_io_lsu_load_1_s2_bank_conflict !== i_io_lsu_load_1_s2_bank_conflict) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_1_s2_bank_conflict: g=%h i=%h", cyc, g_io_lsu_load_1_s2_bank_conflict, i_io_lsu_load_1_s2_bank_conflict);
    end
    seen1_io_lsu_load_1_s2_bank_conflict |= g_io_lsu_load_1_s2_bank_conflict;
    seen0_io_lsu_load_1_s2_bank_conflict |= ~g_io_lsu_load_1_s2_bank_conflict;
    if (!cmp_all && !armed_io_lsu_load_1_s2_mq_nack && g_io_lsu_load_1_s2_mq_nack === i_io_lsu_load_1_s2_mq_nack) armed_io_lsu_load_1_s2_mq_nack = 1;
    if ((cmp_all | armed_io_lsu_load_1_s2_mq_nack) && g_io_lsu_load_1_s2_mq_nack !== i_io_lsu_load_1_s2_mq_nack) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_1_s2_mq_nack: g=%h i=%h", cyc, g_io_lsu_load_1_s2_mq_nack, i_io_lsu_load_1_s2_mq_nack);
    end
    seen1_io_lsu_load_1_s2_mq_nack |= g_io_lsu_load_1_s2_mq_nack;
    seen0_io_lsu_load_1_s2_mq_nack |= ~g_io_lsu_load_1_s2_mq_nack;
    if (!cmp_all && !armed_io_lsu_load_2_req_ready && g_io_lsu_load_2_req_ready === i_io_lsu_load_2_req_ready) armed_io_lsu_load_2_req_ready = 1;
    if ((cmp_all | armed_io_lsu_load_2_req_ready) && g_io_lsu_load_2_req_ready !== i_io_lsu_load_2_req_ready) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_2_req_ready: g=%h i=%h", cyc, g_io_lsu_load_2_req_ready, i_io_lsu_load_2_req_ready);
    end
    seen1_io_lsu_load_2_req_ready |= g_io_lsu_load_2_req_ready;
    seen0_io_lsu_load_2_req_ready |= ~g_io_lsu_load_2_req_ready;
    if (!cmp_all && !armed_io_lsu_load_2_resp_valid && g_io_lsu_load_2_resp_valid === i_io_lsu_load_2_resp_valid) armed_io_lsu_load_2_resp_valid = 1;
    if ((cmp_all | armed_io_lsu_load_2_resp_valid) && g_io_lsu_load_2_resp_valid !== i_io_lsu_load_2_resp_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_2_resp_valid: g=%h i=%h", cyc, g_io_lsu_load_2_resp_valid, i_io_lsu_load_2_resp_valid);
    end
    seen1_io_lsu_load_2_resp_valid |= g_io_lsu_load_2_resp_valid;
    seen0_io_lsu_load_2_resp_valid |= ~g_io_lsu_load_2_resp_valid;
    if (!cmp_all && !armed_io_lsu_load_2_resp_bits_data && g_io_lsu_load_2_resp_bits_data === i_io_lsu_load_2_resp_bits_data) armed_io_lsu_load_2_resp_bits_data = 1;
    if ((cmp_all | armed_io_lsu_load_2_resp_bits_data) && (cmp_all | g_io_lsu_load_2_resp_valid) && (g_io_lsu_load_2_resp_bits_data !== i_io_lsu_load_2_resp_bits_data)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_2_resp_bits_data: g=%h i=%h", cyc, g_io_lsu_load_2_resp_bits_data, i_io_lsu_load_2_resp_bits_data);
    end
    seen1_io_lsu_load_2_resp_bits_data |= g_io_lsu_load_2_resp_bits_data;
    seen0_io_lsu_load_2_resp_bits_data |= ~g_io_lsu_load_2_resp_bits_data;
    if (!cmp_all && !armed_io_lsu_load_2_resp_bits_miss && g_io_lsu_load_2_resp_bits_miss === i_io_lsu_load_2_resp_bits_miss) armed_io_lsu_load_2_resp_bits_miss = 1;
    if ((cmp_all | armed_io_lsu_load_2_resp_bits_miss) && (cmp_all | g_io_lsu_load_2_resp_valid) && (g_io_lsu_load_2_resp_bits_miss !== i_io_lsu_load_2_resp_bits_miss)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_2_resp_bits_miss: g=%h i=%h", cyc, g_io_lsu_load_2_resp_bits_miss, i_io_lsu_load_2_resp_bits_miss);
    end
    seen1_io_lsu_load_2_resp_bits_miss |= g_io_lsu_load_2_resp_bits_miss;
    seen0_io_lsu_load_2_resp_bits_miss |= ~g_io_lsu_load_2_resp_bits_miss;
    if (!cmp_all && !armed_io_lsu_load_2_resp_bits_mshr_id && g_io_lsu_load_2_resp_bits_mshr_id === i_io_lsu_load_2_resp_bits_mshr_id) armed_io_lsu_load_2_resp_bits_mshr_id = 1;
    if ((cmp_all | armed_io_lsu_load_2_resp_bits_mshr_id) && (cmp_all | g_io_lsu_load_2_resp_valid) && (g_io_lsu_load_2_resp_bits_mshr_id !== i_io_lsu_load_2_resp_bits_mshr_id)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_2_resp_bits_mshr_id: g=%h i=%h", cyc, g_io_lsu_load_2_resp_bits_mshr_id, i_io_lsu_load_2_resp_bits_mshr_id);
    end
    seen1_io_lsu_load_2_resp_bits_mshr_id |= g_io_lsu_load_2_resp_bits_mshr_id;
    seen0_io_lsu_load_2_resp_bits_mshr_id |= ~g_io_lsu_load_2_resp_bits_mshr_id;
    if (!cmp_all && !armed_io_lsu_load_2_resp_bits_meta_prefetch && g_io_lsu_load_2_resp_bits_meta_prefetch === i_io_lsu_load_2_resp_bits_meta_prefetch) armed_io_lsu_load_2_resp_bits_meta_prefetch = 1;
    if ((cmp_all | armed_io_lsu_load_2_resp_bits_meta_prefetch) && (cmp_all | g_io_lsu_load_2_resp_valid) && (g_io_lsu_load_2_resp_bits_meta_prefetch !== i_io_lsu_load_2_resp_bits_meta_prefetch)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_2_resp_bits_meta_prefetch: g=%h i=%h", cyc, g_io_lsu_load_2_resp_bits_meta_prefetch, i_io_lsu_load_2_resp_bits_meta_prefetch);
    end
    seen1_io_lsu_load_2_resp_bits_meta_prefetch |= g_io_lsu_load_2_resp_bits_meta_prefetch;
    seen0_io_lsu_load_2_resp_bits_meta_prefetch |= ~g_io_lsu_load_2_resp_bits_meta_prefetch;
    if (!cmp_all && !armed_io_lsu_load_2_resp_bits_handled && g_io_lsu_load_2_resp_bits_handled === i_io_lsu_load_2_resp_bits_handled) armed_io_lsu_load_2_resp_bits_handled = 1;
    if ((cmp_all | armed_io_lsu_load_2_resp_bits_handled) && (cmp_all | g_io_lsu_load_2_resp_valid) && (g_io_lsu_load_2_resp_bits_handled !== i_io_lsu_load_2_resp_bits_handled)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_2_resp_bits_handled: g=%h i=%h", cyc, g_io_lsu_load_2_resp_bits_handled, i_io_lsu_load_2_resp_bits_handled);
    end
    seen1_io_lsu_load_2_resp_bits_handled |= g_io_lsu_load_2_resp_bits_handled;
    seen0_io_lsu_load_2_resp_bits_handled |= ~g_io_lsu_load_2_resp_bits_handled;
    if (!cmp_all && !armed_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied && g_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied === i_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied) armed_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied = 1;
    if ((cmp_all | armed_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied) && (cmp_all | g_io_lsu_load_2_resp_valid) && (g_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied !== i_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied: g=%h i=%h", cyc, g_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied, i_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied);
    end
    seen1_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied |= g_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied;
    seen0_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied |= ~g_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied;
    if (!cmp_all && !armed_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt && g_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt === i_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt) armed_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt = 1;
    if ((cmp_all | armed_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt) && (cmp_all | g_io_lsu_load_2_resp_valid) && (g_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt !== i_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt: g=%h i=%h", cyc, g_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt, i_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt);
    end
    seen1_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt |= g_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt;
    seen0_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt |= ~g_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt;
    if (!cmp_all && !armed_io_lsu_load_2_s2_bank_conflict && g_io_lsu_load_2_s2_bank_conflict === i_io_lsu_load_2_s2_bank_conflict) armed_io_lsu_load_2_s2_bank_conflict = 1;
    if ((cmp_all | armed_io_lsu_load_2_s2_bank_conflict) && g_io_lsu_load_2_s2_bank_conflict !== i_io_lsu_load_2_s2_bank_conflict) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_2_s2_bank_conflict: g=%h i=%h", cyc, g_io_lsu_load_2_s2_bank_conflict, i_io_lsu_load_2_s2_bank_conflict);
    end
    seen1_io_lsu_load_2_s2_bank_conflict |= g_io_lsu_load_2_s2_bank_conflict;
    seen0_io_lsu_load_2_s2_bank_conflict |= ~g_io_lsu_load_2_s2_bank_conflict;
    if (!cmp_all && !armed_io_lsu_load_2_s2_mq_nack && g_io_lsu_load_2_s2_mq_nack === i_io_lsu_load_2_s2_mq_nack) armed_io_lsu_load_2_s2_mq_nack = 1;
    if ((cmp_all | armed_io_lsu_load_2_s2_mq_nack) && g_io_lsu_load_2_s2_mq_nack !== i_io_lsu_load_2_s2_mq_nack) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_load_2_s2_mq_nack: g=%h i=%h", cyc, g_io_lsu_load_2_s2_mq_nack, i_io_lsu_load_2_s2_mq_nack);
    end
    seen1_io_lsu_load_2_s2_mq_nack |= g_io_lsu_load_2_s2_mq_nack;
    seen0_io_lsu_load_2_s2_mq_nack |= ~g_io_lsu_load_2_s2_mq_nack;
    if (!cmp_all && !armed_io_lsu_tl_d_channel_valid && g_io_lsu_tl_d_channel_valid === i_io_lsu_tl_d_channel_valid) armed_io_lsu_tl_d_channel_valid = 1;
    if ((cmp_all | armed_io_lsu_tl_d_channel_valid) && g_io_lsu_tl_d_channel_valid !== i_io_lsu_tl_d_channel_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_tl_d_channel_valid: g=%h i=%h", cyc, g_io_lsu_tl_d_channel_valid, i_io_lsu_tl_d_channel_valid);
    end
    seen1_io_lsu_tl_d_channel_valid |= g_io_lsu_tl_d_channel_valid;
    seen0_io_lsu_tl_d_channel_valid |= ~g_io_lsu_tl_d_channel_valid;
    if (!cmp_all && !armed_io_lsu_tl_d_channel_mshrid && g_io_lsu_tl_d_channel_mshrid === i_io_lsu_tl_d_channel_mshrid) armed_io_lsu_tl_d_channel_mshrid = 1;
    if ((cmp_all | armed_io_lsu_tl_d_channel_mshrid) && g_io_lsu_tl_d_channel_mshrid !== i_io_lsu_tl_d_channel_mshrid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_tl_d_channel_mshrid: g=%h i=%h", cyc, g_io_lsu_tl_d_channel_mshrid, i_io_lsu_tl_d_channel_mshrid);
    end
    seen1_io_lsu_tl_d_channel_mshrid |= g_io_lsu_tl_d_channel_mshrid;
    seen0_io_lsu_tl_d_channel_mshrid |= ~g_io_lsu_tl_d_channel_mshrid;
    if (!cmp_all && !armed_io_lsu_store_req_ready && g_io_lsu_store_req_ready === i_io_lsu_store_req_ready) armed_io_lsu_store_req_ready = 1;
    if ((cmp_all | armed_io_lsu_store_req_ready) && g_io_lsu_store_req_ready !== i_io_lsu_store_req_ready) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_store_req_ready: g=%h i=%h", cyc, g_io_lsu_store_req_ready, i_io_lsu_store_req_ready);
    end
    seen1_io_lsu_store_req_ready |= g_io_lsu_store_req_ready;
    seen0_io_lsu_store_req_ready |= ~g_io_lsu_store_req_ready;
    if (!cmp_all && !armed_io_lsu_store_main_pipe_hit_resp_valid && g_io_lsu_store_main_pipe_hit_resp_valid === i_io_lsu_store_main_pipe_hit_resp_valid) armed_io_lsu_store_main_pipe_hit_resp_valid = 1;
    if ((cmp_all | armed_io_lsu_store_main_pipe_hit_resp_valid) && g_io_lsu_store_main_pipe_hit_resp_valid !== i_io_lsu_store_main_pipe_hit_resp_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_store_main_pipe_hit_resp_valid: g=%h i=%h", cyc, g_io_lsu_store_main_pipe_hit_resp_valid, i_io_lsu_store_main_pipe_hit_resp_valid);
    end
    seen1_io_lsu_store_main_pipe_hit_resp_valid |= g_io_lsu_store_main_pipe_hit_resp_valid;
    seen0_io_lsu_store_main_pipe_hit_resp_valid |= ~g_io_lsu_store_main_pipe_hit_resp_valid;
    if (!cmp_all && !armed_io_lsu_store_main_pipe_hit_resp_bits_id && g_io_lsu_store_main_pipe_hit_resp_bits_id === i_io_lsu_store_main_pipe_hit_resp_bits_id) armed_io_lsu_store_main_pipe_hit_resp_bits_id = 1;
    if ((cmp_all | armed_io_lsu_store_main_pipe_hit_resp_bits_id) && (cmp_all | g_io_lsu_store_main_pipe_hit_resp_valid) && (g_io_lsu_store_main_pipe_hit_resp_bits_id !== i_io_lsu_store_main_pipe_hit_resp_bits_id)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_store_main_pipe_hit_resp_bits_id: g=%h i=%h", cyc, g_io_lsu_store_main_pipe_hit_resp_bits_id, i_io_lsu_store_main_pipe_hit_resp_bits_id);
    end
    seen1_io_lsu_store_main_pipe_hit_resp_bits_id |= g_io_lsu_store_main_pipe_hit_resp_bits_id;
    seen0_io_lsu_store_main_pipe_hit_resp_bits_id |= ~g_io_lsu_store_main_pipe_hit_resp_bits_id;
    if (!cmp_all && !armed_io_lsu_store_replay_resp_valid && g_io_lsu_store_replay_resp_valid === i_io_lsu_store_replay_resp_valid) armed_io_lsu_store_replay_resp_valid = 1;
    if ((cmp_all | armed_io_lsu_store_replay_resp_valid) && g_io_lsu_store_replay_resp_valid !== i_io_lsu_store_replay_resp_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_store_replay_resp_valid: g=%h i=%h", cyc, g_io_lsu_store_replay_resp_valid, i_io_lsu_store_replay_resp_valid);
    end
    seen1_io_lsu_store_replay_resp_valid |= g_io_lsu_store_replay_resp_valid;
    seen0_io_lsu_store_replay_resp_valid |= ~g_io_lsu_store_replay_resp_valid;
    if (!cmp_all && !armed_io_lsu_store_replay_resp_bits_id && g_io_lsu_store_replay_resp_bits_id === i_io_lsu_store_replay_resp_bits_id) armed_io_lsu_store_replay_resp_bits_id = 1;
    if ((cmp_all | armed_io_lsu_store_replay_resp_bits_id) && (cmp_all | g_io_lsu_store_replay_resp_valid) && (g_io_lsu_store_replay_resp_bits_id !== i_io_lsu_store_replay_resp_bits_id)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_store_replay_resp_bits_id: g=%h i=%h", cyc, g_io_lsu_store_replay_resp_bits_id, i_io_lsu_store_replay_resp_bits_id);
    end
    seen1_io_lsu_store_replay_resp_bits_id |= g_io_lsu_store_replay_resp_bits_id;
    seen0_io_lsu_store_replay_resp_bits_id |= ~g_io_lsu_store_replay_resp_bits_id;
    if (!cmp_all && !armed_io_lsu_atomics_req_ready && g_io_lsu_atomics_req_ready === i_io_lsu_atomics_req_ready) armed_io_lsu_atomics_req_ready = 1;
    if ((cmp_all | armed_io_lsu_atomics_req_ready) && g_io_lsu_atomics_req_ready !== i_io_lsu_atomics_req_ready) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_atomics_req_ready: g=%h i=%h", cyc, g_io_lsu_atomics_req_ready, i_io_lsu_atomics_req_ready);
    end
    seen1_io_lsu_atomics_req_ready |= g_io_lsu_atomics_req_ready;
    seen0_io_lsu_atomics_req_ready |= ~g_io_lsu_atomics_req_ready;
    if (!cmp_all && !armed_io_lsu_atomics_resp_valid && g_io_lsu_atomics_resp_valid === i_io_lsu_atomics_resp_valid) armed_io_lsu_atomics_resp_valid = 1;
    if ((cmp_all | armed_io_lsu_atomics_resp_valid) && g_io_lsu_atomics_resp_valid !== i_io_lsu_atomics_resp_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_atomics_resp_valid: g=%h i=%h", cyc, g_io_lsu_atomics_resp_valid, i_io_lsu_atomics_resp_valid);
    end
    seen1_io_lsu_atomics_resp_valid |= g_io_lsu_atomics_resp_valid;
    seen0_io_lsu_atomics_resp_valid |= ~g_io_lsu_atomics_resp_valid;
    if (!cmp_all && !armed_io_lsu_atomics_resp_bits_data && g_io_lsu_atomics_resp_bits_data === i_io_lsu_atomics_resp_bits_data) armed_io_lsu_atomics_resp_bits_data = 1;
    if ((cmp_all | armed_io_lsu_atomics_resp_bits_data) && (cmp_all | g_io_lsu_atomics_resp_valid) && (g_io_lsu_atomics_resp_bits_data !== i_io_lsu_atomics_resp_bits_data)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_atomics_resp_bits_data: g=%h i=%h", cyc, g_io_lsu_atomics_resp_bits_data, i_io_lsu_atomics_resp_bits_data);
    end
    seen1_io_lsu_atomics_resp_bits_data |= g_io_lsu_atomics_resp_bits_data;
    seen0_io_lsu_atomics_resp_bits_data |= ~g_io_lsu_atomics_resp_bits_data;
    if (!cmp_all && !armed_io_lsu_atomics_resp_bits_miss && g_io_lsu_atomics_resp_bits_miss === i_io_lsu_atomics_resp_bits_miss) armed_io_lsu_atomics_resp_bits_miss = 1;
    if ((cmp_all | armed_io_lsu_atomics_resp_bits_miss) && (cmp_all | g_io_lsu_atomics_resp_valid) && (g_io_lsu_atomics_resp_bits_miss !== i_io_lsu_atomics_resp_bits_miss)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_atomics_resp_bits_miss: g=%h i=%h", cyc, g_io_lsu_atomics_resp_bits_miss, i_io_lsu_atomics_resp_bits_miss);
    end
    seen1_io_lsu_atomics_resp_bits_miss |= g_io_lsu_atomics_resp_bits_miss;
    seen0_io_lsu_atomics_resp_bits_miss |= ~g_io_lsu_atomics_resp_bits_miss;
    if (!cmp_all && !armed_io_lsu_atomics_resp_bits_replay && g_io_lsu_atomics_resp_bits_replay === i_io_lsu_atomics_resp_bits_replay) armed_io_lsu_atomics_resp_bits_replay = 1;
    if ((cmp_all | armed_io_lsu_atomics_resp_bits_replay) && (cmp_all | g_io_lsu_atomics_resp_valid) && (g_io_lsu_atomics_resp_bits_replay !== i_io_lsu_atomics_resp_bits_replay)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_atomics_resp_bits_replay: g=%h i=%h", cyc, g_io_lsu_atomics_resp_bits_replay, i_io_lsu_atomics_resp_bits_replay);
    end
    seen1_io_lsu_atomics_resp_bits_replay |= g_io_lsu_atomics_resp_bits_replay;
    seen0_io_lsu_atomics_resp_bits_replay |= ~g_io_lsu_atomics_resp_bits_replay;
    if (!cmp_all && !armed_io_lsu_atomics_resp_bits_tl_error_tl_denied && g_io_lsu_atomics_resp_bits_tl_error_tl_denied === i_io_lsu_atomics_resp_bits_tl_error_tl_denied) armed_io_lsu_atomics_resp_bits_tl_error_tl_denied = 1;
    if ((cmp_all | armed_io_lsu_atomics_resp_bits_tl_error_tl_denied) && (cmp_all | g_io_lsu_atomics_resp_valid) && (g_io_lsu_atomics_resp_bits_tl_error_tl_denied !== i_io_lsu_atomics_resp_bits_tl_error_tl_denied)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_atomics_resp_bits_tl_error_tl_denied: g=%h i=%h", cyc, g_io_lsu_atomics_resp_bits_tl_error_tl_denied, i_io_lsu_atomics_resp_bits_tl_error_tl_denied);
    end
    seen1_io_lsu_atomics_resp_bits_tl_error_tl_denied |= g_io_lsu_atomics_resp_bits_tl_error_tl_denied;
    seen0_io_lsu_atomics_resp_bits_tl_error_tl_denied |= ~g_io_lsu_atomics_resp_bits_tl_error_tl_denied;
    if (!cmp_all && !armed_io_lsu_atomics_resp_bits_tl_error_tl_corrupt && g_io_lsu_atomics_resp_bits_tl_error_tl_corrupt === i_io_lsu_atomics_resp_bits_tl_error_tl_corrupt) armed_io_lsu_atomics_resp_bits_tl_error_tl_corrupt = 1;
    if ((cmp_all | armed_io_lsu_atomics_resp_bits_tl_error_tl_corrupt) && (cmp_all | g_io_lsu_atomics_resp_valid) && (g_io_lsu_atomics_resp_bits_tl_error_tl_corrupt !== i_io_lsu_atomics_resp_bits_tl_error_tl_corrupt)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_atomics_resp_bits_tl_error_tl_corrupt: g=%h i=%h", cyc, g_io_lsu_atomics_resp_bits_tl_error_tl_corrupt, i_io_lsu_atomics_resp_bits_tl_error_tl_corrupt);
    end
    seen1_io_lsu_atomics_resp_bits_tl_error_tl_corrupt |= g_io_lsu_atomics_resp_bits_tl_error_tl_corrupt;
    seen0_io_lsu_atomics_resp_bits_tl_error_tl_corrupt |= ~g_io_lsu_atomics_resp_bits_tl_error_tl_corrupt;
    if (!cmp_all && !armed_io_lsu_atomics_resp_bits_id && g_io_lsu_atomics_resp_bits_id === i_io_lsu_atomics_resp_bits_id) armed_io_lsu_atomics_resp_bits_id = 1;
    if ((cmp_all | armed_io_lsu_atomics_resp_bits_id) && (cmp_all | g_io_lsu_atomics_resp_valid) && (g_io_lsu_atomics_resp_bits_id !== i_io_lsu_atomics_resp_bits_id)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_atomics_resp_bits_id: g=%h i=%h", cyc, g_io_lsu_atomics_resp_bits_id, i_io_lsu_atomics_resp_bits_id);
    end
    seen1_io_lsu_atomics_resp_bits_id |= g_io_lsu_atomics_resp_bits_id;
    seen0_io_lsu_atomics_resp_bits_id |= ~g_io_lsu_atomics_resp_bits_id;
    if (!cmp_all && !armed_io_lsu_atomics_block_lr && g_io_lsu_atomics_block_lr === i_io_lsu_atomics_block_lr) armed_io_lsu_atomics_block_lr = 1;
    if ((cmp_all | armed_io_lsu_atomics_block_lr) && g_io_lsu_atomics_block_lr !== i_io_lsu_atomics_block_lr) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_atomics_block_lr: g=%h i=%h", cyc, g_io_lsu_atomics_block_lr, i_io_lsu_atomics_block_lr);
    end
    seen1_io_lsu_atomics_block_lr |= g_io_lsu_atomics_block_lr;
    seen0_io_lsu_atomics_block_lr |= ~g_io_lsu_atomics_block_lr;
    if (!cmp_all && !armed_io_lsu_release_valid && g_io_lsu_release_valid === i_io_lsu_release_valid) armed_io_lsu_release_valid = 1;
    if ((cmp_all | armed_io_lsu_release_valid) && g_io_lsu_release_valid !== i_io_lsu_release_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_release_valid: g=%h i=%h", cyc, g_io_lsu_release_valid, i_io_lsu_release_valid);
    end
    seen1_io_lsu_release_valid |= g_io_lsu_release_valid;
    seen0_io_lsu_release_valid |= ~g_io_lsu_release_valid;
    if (!cmp_all && !armed_io_lsu_release_bits_paddr && g_io_lsu_release_bits_paddr === i_io_lsu_release_bits_paddr) armed_io_lsu_release_bits_paddr = 1;
    if ((cmp_all | armed_io_lsu_release_bits_paddr) && (cmp_all | g_io_lsu_release_valid) && (g_io_lsu_release_bits_paddr !== i_io_lsu_release_bits_paddr)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_release_bits_paddr: g=%h i=%h", cyc, g_io_lsu_release_bits_paddr, i_io_lsu_release_bits_paddr);
    end
    seen1_io_lsu_release_bits_paddr |= g_io_lsu_release_bits_paddr;
    seen0_io_lsu_release_bits_paddr |= ~g_io_lsu_release_bits_paddr;
    if (!cmp_all && !armed_io_lsu_forward_D_0_valid && g_io_lsu_forward_D_0_valid === i_io_lsu_forward_D_0_valid) armed_io_lsu_forward_D_0_valid = 1;
    if ((cmp_all | armed_io_lsu_forward_D_0_valid) && g_io_lsu_forward_D_0_valid !== i_io_lsu_forward_D_0_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_0_valid: g=%h i=%h", cyc, g_io_lsu_forward_D_0_valid, i_io_lsu_forward_D_0_valid);
    end
    seen1_io_lsu_forward_D_0_valid |= g_io_lsu_forward_D_0_valid;
    seen0_io_lsu_forward_D_0_valid |= ~g_io_lsu_forward_D_0_valid;
    if (!cmp_all && !armed_io_lsu_forward_D_0_data && g_io_lsu_forward_D_0_data === i_io_lsu_forward_D_0_data) armed_io_lsu_forward_D_0_data = 1;
    if ((cmp_all | armed_io_lsu_forward_D_0_data) && g_io_lsu_forward_D_0_data !== i_io_lsu_forward_D_0_data) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_0_data: g=%h i=%h", cyc, g_io_lsu_forward_D_0_data, i_io_lsu_forward_D_0_data);
    end
    seen1_io_lsu_forward_D_0_data |= g_io_lsu_forward_D_0_data;
    seen0_io_lsu_forward_D_0_data |= ~g_io_lsu_forward_D_0_data;
    if (!cmp_all && !armed_io_lsu_forward_D_0_mshrid && g_io_lsu_forward_D_0_mshrid === i_io_lsu_forward_D_0_mshrid) armed_io_lsu_forward_D_0_mshrid = 1;
    if ((cmp_all | armed_io_lsu_forward_D_0_mshrid) && g_io_lsu_forward_D_0_mshrid !== i_io_lsu_forward_D_0_mshrid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_0_mshrid: g=%h i=%h", cyc, g_io_lsu_forward_D_0_mshrid, i_io_lsu_forward_D_0_mshrid);
    end
    seen1_io_lsu_forward_D_0_mshrid |= g_io_lsu_forward_D_0_mshrid;
    seen0_io_lsu_forward_D_0_mshrid |= ~g_io_lsu_forward_D_0_mshrid;
    if (!cmp_all && !armed_io_lsu_forward_D_0_last && g_io_lsu_forward_D_0_last === i_io_lsu_forward_D_0_last) armed_io_lsu_forward_D_0_last = 1;
    if ((cmp_all | armed_io_lsu_forward_D_0_last) && g_io_lsu_forward_D_0_last !== i_io_lsu_forward_D_0_last) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_0_last: g=%h i=%h", cyc, g_io_lsu_forward_D_0_last, i_io_lsu_forward_D_0_last);
    end
    seen1_io_lsu_forward_D_0_last |= g_io_lsu_forward_D_0_last;
    seen0_io_lsu_forward_D_0_last |= ~g_io_lsu_forward_D_0_last;
    if (!cmp_all && !armed_io_lsu_forward_D_0_denied && g_io_lsu_forward_D_0_denied === i_io_lsu_forward_D_0_denied) armed_io_lsu_forward_D_0_denied = 1;
    if ((cmp_all | armed_io_lsu_forward_D_0_denied) && g_io_lsu_forward_D_0_denied !== i_io_lsu_forward_D_0_denied) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_0_denied: g=%h i=%h", cyc, g_io_lsu_forward_D_0_denied, i_io_lsu_forward_D_0_denied);
    end
    seen1_io_lsu_forward_D_0_denied |= g_io_lsu_forward_D_0_denied;
    seen0_io_lsu_forward_D_0_denied |= ~g_io_lsu_forward_D_0_denied;
    if (!cmp_all && !armed_io_lsu_forward_D_0_corrupt && g_io_lsu_forward_D_0_corrupt === i_io_lsu_forward_D_0_corrupt) armed_io_lsu_forward_D_0_corrupt = 1;
    if ((cmp_all | armed_io_lsu_forward_D_0_corrupt) && g_io_lsu_forward_D_0_corrupt !== i_io_lsu_forward_D_0_corrupt) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_0_corrupt: g=%h i=%h", cyc, g_io_lsu_forward_D_0_corrupt, i_io_lsu_forward_D_0_corrupt);
    end
    seen1_io_lsu_forward_D_0_corrupt |= g_io_lsu_forward_D_0_corrupt;
    seen0_io_lsu_forward_D_0_corrupt |= ~g_io_lsu_forward_D_0_corrupt;
    if (!cmp_all && !armed_io_lsu_forward_D_1_valid && g_io_lsu_forward_D_1_valid === i_io_lsu_forward_D_1_valid) armed_io_lsu_forward_D_1_valid = 1;
    if ((cmp_all | armed_io_lsu_forward_D_1_valid) && g_io_lsu_forward_D_1_valid !== i_io_lsu_forward_D_1_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_1_valid: g=%h i=%h", cyc, g_io_lsu_forward_D_1_valid, i_io_lsu_forward_D_1_valid);
    end
    seen1_io_lsu_forward_D_1_valid |= g_io_lsu_forward_D_1_valid;
    seen0_io_lsu_forward_D_1_valid |= ~g_io_lsu_forward_D_1_valid;
    if (!cmp_all && !armed_io_lsu_forward_D_1_data && g_io_lsu_forward_D_1_data === i_io_lsu_forward_D_1_data) armed_io_lsu_forward_D_1_data = 1;
    if ((cmp_all | armed_io_lsu_forward_D_1_data) && g_io_lsu_forward_D_1_data !== i_io_lsu_forward_D_1_data) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_1_data: g=%h i=%h", cyc, g_io_lsu_forward_D_1_data, i_io_lsu_forward_D_1_data);
    end
    seen1_io_lsu_forward_D_1_data |= g_io_lsu_forward_D_1_data;
    seen0_io_lsu_forward_D_1_data |= ~g_io_lsu_forward_D_1_data;
    if (!cmp_all && !armed_io_lsu_forward_D_1_mshrid && g_io_lsu_forward_D_1_mshrid === i_io_lsu_forward_D_1_mshrid) armed_io_lsu_forward_D_1_mshrid = 1;
    if ((cmp_all | armed_io_lsu_forward_D_1_mshrid) && g_io_lsu_forward_D_1_mshrid !== i_io_lsu_forward_D_1_mshrid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_1_mshrid: g=%h i=%h", cyc, g_io_lsu_forward_D_1_mshrid, i_io_lsu_forward_D_1_mshrid);
    end
    seen1_io_lsu_forward_D_1_mshrid |= g_io_lsu_forward_D_1_mshrid;
    seen0_io_lsu_forward_D_1_mshrid |= ~g_io_lsu_forward_D_1_mshrid;
    if (!cmp_all && !armed_io_lsu_forward_D_1_last && g_io_lsu_forward_D_1_last === i_io_lsu_forward_D_1_last) armed_io_lsu_forward_D_1_last = 1;
    if ((cmp_all | armed_io_lsu_forward_D_1_last) && g_io_lsu_forward_D_1_last !== i_io_lsu_forward_D_1_last) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_1_last: g=%h i=%h", cyc, g_io_lsu_forward_D_1_last, i_io_lsu_forward_D_1_last);
    end
    seen1_io_lsu_forward_D_1_last |= g_io_lsu_forward_D_1_last;
    seen0_io_lsu_forward_D_1_last |= ~g_io_lsu_forward_D_1_last;
    if (!cmp_all && !armed_io_lsu_forward_D_1_denied && g_io_lsu_forward_D_1_denied === i_io_lsu_forward_D_1_denied) armed_io_lsu_forward_D_1_denied = 1;
    if ((cmp_all | armed_io_lsu_forward_D_1_denied) && g_io_lsu_forward_D_1_denied !== i_io_lsu_forward_D_1_denied) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_1_denied: g=%h i=%h", cyc, g_io_lsu_forward_D_1_denied, i_io_lsu_forward_D_1_denied);
    end
    seen1_io_lsu_forward_D_1_denied |= g_io_lsu_forward_D_1_denied;
    seen0_io_lsu_forward_D_1_denied |= ~g_io_lsu_forward_D_1_denied;
    if (!cmp_all && !armed_io_lsu_forward_D_1_corrupt && g_io_lsu_forward_D_1_corrupt === i_io_lsu_forward_D_1_corrupt) armed_io_lsu_forward_D_1_corrupt = 1;
    if ((cmp_all | armed_io_lsu_forward_D_1_corrupt) && g_io_lsu_forward_D_1_corrupt !== i_io_lsu_forward_D_1_corrupt) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_1_corrupt: g=%h i=%h", cyc, g_io_lsu_forward_D_1_corrupt, i_io_lsu_forward_D_1_corrupt);
    end
    seen1_io_lsu_forward_D_1_corrupt |= g_io_lsu_forward_D_1_corrupt;
    seen0_io_lsu_forward_D_1_corrupt |= ~g_io_lsu_forward_D_1_corrupt;
    if (!cmp_all && !armed_io_lsu_forward_D_2_valid && g_io_lsu_forward_D_2_valid === i_io_lsu_forward_D_2_valid) armed_io_lsu_forward_D_2_valid = 1;
    if ((cmp_all | armed_io_lsu_forward_D_2_valid) && g_io_lsu_forward_D_2_valid !== i_io_lsu_forward_D_2_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_2_valid: g=%h i=%h", cyc, g_io_lsu_forward_D_2_valid, i_io_lsu_forward_D_2_valid);
    end
    seen1_io_lsu_forward_D_2_valid |= g_io_lsu_forward_D_2_valid;
    seen0_io_lsu_forward_D_2_valid |= ~g_io_lsu_forward_D_2_valid;
    if (!cmp_all && !armed_io_lsu_forward_D_2_data && g_io_lsu_forward_D_2_data === i_io_lsu_forward_D_2_data) armed_io_lsu_forward_D_2_data = 1;
    if ((cmp_all | armed_io_lsu_forward_D_2_data) && g_io_lsu_forward_D_2_data !== i_io_lsu_forward_D_2_data) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_2_data: g=%h i=%h", cyc, g_io_lsu_forward_D_2_data, i_io_lsu_forward_D_2_data);
    end
    seen1_io_lsu_forward_D_2_data |= g_io_lsu_forward_D_2_data;
    seen0_io_lsu_forward_D_2_data |= ~g_io_lsu_forward_D_2_data;
    if (!cmp_all && !armed_io_lsu_forward_D_2_mshrid && g_io_lsu_forward_D_2_mshrid === i_io_lsu_forward_D_2_mshrid) armed_io_lsu_forward_D_2_mshrid = 1;
    if ((cmp_all | armed_io_lsu_forward_D_2_mshrid) && g_io_lsu_forward_D_2_mshrid !== i_io_lsu_forward_D_2_mshrid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_2_mshrid: g=%h i=%h", cyc, g_io_lsu_forward_D_2_mshrid, i_io_lsu_forward_D_2_mshrid);
    end
    seen1_io_lsu_forward_D_2_mshrid |= g_io_lsu_forward_D_2_mshrid;
    seen0_io_lsu_forward_D_2_mshrid |= ~g_io_lsu_forward_D_2_mshrid;
    if (!cmp_all && !armed_io_lsu_forward_D_2_last && g_io_lsu_forward_D_2_last === i_io_lsu_forward_D_2_last) armed_io_lsu_forward_D_2_last = 1;
    if ((cmp_all | armed_io_lsu_forward_D_2_last) && g_io_lsu_forward_D_2_last !== i_io_lsu_forward_D_2_last) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_2_last: g=%h i=%h", cyc, g_io_lsu_forward_D_2_last, i_io_lsu_forward_D_2_last);
    end
    seen1_io_lsu_forward_D_2_last |= g_io_lsu_forward_D_2_last;
    seen0_io_lsu_forward_D_2_last |= ~g_io_lsu_forward_D_2_last;
    if (!cmp_all && !armed_io_lsu_forward_D_2_denied && g_io_lsu_forward_D_2_denied === i_io_lsu_forward_D_2_denied) armed_io_lsu_forward_D_2_denied = 1;
    if ((cmp_all | armed_io_lsu_forward_D_2_denied) && g_io_lsu_forward_D_2_denied !== i_io_lsu_forward_D_2_denied) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_2_denied: g=%h i=%h", cyc, g_io_lsu_forward_D_2_denied, i_io_lsu_forward_D_2_denied);
    end
    seen1_io_lsu_forward_D_2_denied |= g_io_lsu_forward_D_2_denied;
    seen0_io_lsu_forward_D_2_denied |= ~g_io_lsu_forward_D_2_denied;
    if (!cmp_all && !armed_io_lsu_forward_D_2_corrupt && g_io_lsu_forward_D_2_corrupt === i_io_lsu_forward_D_2_corrupt) armed_io_lsu_forward_D_2_corrupt = 1;
    if ((cmp_all | armed_io_lsu_forward_D_2_corrupt) && g_io_lsu_forward_D_2_corrupt !== i_io_lsu_forward_D_2_corrupt) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_D_2_corrupt: g=%h i=%h", cyc, g_io_lsu_forward_D_2_corrupt, i_io_lsu_forward_D_2_corrupt);
    end
    seen1_io_lsu_forward_D_2_corrupt |= g_io_lsu_forward_D_2_corrupt;
    seen0_io_lsu_forward_D_2_corrupt |= ~g_io_lsu_forward_D_2_corrupt;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forward_mshr && g_io_lsu_forward_mshr_0_forward_mshr === i_io_lsu_forward_mshr_0_forward_mshr) armed_io_lsu_forward_mshr_0_forward_mshr = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forward_mshr) && g_io_lsu_forward_mshr_0_forward_mshr !== i_io_lsu_forward_mshr_0_forward_mshr) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forward_mshr: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forward_mshr, i_io_lsu_forward_mshr_0_forward_mshr);
    end
    seen1_io_lsu_forward_mshr_0_forward_mshr |= g_io_lsu_forward_mshr_0_forward_mshr;
    seen0_io_lsu_forward_mshr_0_forward_mshr |= ~g_io_lsu_forward_mshr_0_forward_mshr;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_0 && g_io_lsu_forward_mshr_0_forwardData_0 === i_io_lsu_forward_mshr_0_forwardData_0) armed_io_lsu_forward_mshr_0_forwardData_0 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forwardData_0) && g_io_lsu_forward_mshr_0_forwardData_0 !== i_io_lsu_forward_mshr_0_forwardData_0) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forwardData_0: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forwardData_0, i_io_lsu_forward_mshr_0_forwardData_0);
    end
    seen1_io_lsu_forward_mshr_0_forwardData_0 |= g_io_lsu_forward_mshr_0_forwardData_0;
    seen0_io_lsu_forward_mshr_0_forwardData_0 |= ~g_io_lsu_forward_mshr_0_forwardData_0;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_1 && g_io_lsu_forward_mshr_0_forwardData_1 === i_io_lsu_forward_mshr_0_forwardData_1) armed_io_lsu_forward_mshr_0_forwardData_1 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forwardData_1) && g_io_lsu_forward_mshr_0_forwardData_1 !== i_io_lsu_forward_mshr_0_forwardData_1) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forwardData_1: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forwardData_1, i_io_lsu_forward_mshr_0_forwardData_1);
    end
    seen1_io_lsu_forward_mshr_0_forwardData_1 |= g_io_lsu_forward_mshr_0_forwardData_1;
    seen0_io_lsu_forward_mshr_0_forwardData_1 |= ~g_io_lsu_forward_mshr_0_forwardData_1;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_2 && g_io_lsu_forward_mshr_0_forwardData_2 === i_io_lsu_forward_mshr_0_forwardData_2) armed_io_lsu_forward_mshr_0_forwardData_2 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forwardData_2) && g_io_lsu_forward_mshr_0_forwardData_2 !== i_io_lsu_forward_mshr_0_forwardData_2) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forwardData_2: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forwardData_2, i_io_lsu_forward_mshr_0_forwardData_2);
    end
    seen1_io_lsu_forward_mshr_0_forwardData_2 |= g_io_lsu_forward_mshr_0_forwardData_2;
    seen0_io_lsu_forward_mshr_0_forwardData_2 |= ~g_io_lsu_forward_mshr_0_forwardData_2;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_3 && g_io_lsu_forward_mshr_0_forwardData_3 === i_io_lsu_forward_mshr_0_forwardData_3) armed_io_lsu_forward_mshr_0_forwardData_3 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forwardData_3) && g_io_lsu_forward_mshr_0_forwardData_3 !== i_io_lsu_forward_mshr_0_forwardData_3) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forwardData_3: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forwardData_3, i_io_lsu_forward_mshr_0_forwardData_3);
    end
    seen1_io_lsu_forward_mshr_0_forwardData_3 |= g_io_lsu_forward_mshr_0_forwardData_3;
    seen0_io_lsu_forward_mshr_0_forwardData_3 |= ~g_io_lsu_forward_mshr_0_forwardData_3;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_4 && g_io_lsu_forward_mshr_0_forwardData_4 === i_io_lsu_forward_mshr_0_forwardData_4) armed_io_lsu_forward_mshr_0_forwardData_4 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forwardData_4) && g_io_lsu_forward_mshr_0_forwardData_4 !== i_io_lsu_forward_mshr_0_forwardData_4) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forwardData_4: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forwardData_4, i_io_lsu_forward_mshr_0_forwardData_4);
    end
    seen1_io_lsu_forward_mshr_0_forwardData_4 |= g_io_lsu_forward_mshr_0_forwardData_4;
    seen0_io_lsu_forward_mshr_0_forwardData_4 |= ~g_io_lsu_forward_mshr_0_forwardData_4;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_5 && g_io_lsu_forward_mshr_0_forwardData_5 === i_io_lsu_forward_mshr_0_forwardData_5) armed_io_lsu_forward_mshr_0_forwardData_5 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forwardData_5) && g_io_lsu_forward_mshr_0_forwardData_5 !== i_io_lsu_forward_mshr_0_forwardData_5) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forwardData_5: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forwardData_5, i_io_lsu_forward_mshr_0_forwardData_5);
    end
    seen1_io_lsu_forward_mshr_0_forwardData_5 |= g_io_lsu_forward_mshr_0_forwardData_5;
    seen0_io_lsu_forward_mshr_0_forwardData_5 |= ~g_io_lsu_forward_mshr_0_forwardData_5;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_6 && g_io_lsu_forward_mshr_0_forwardData_6 === i_io_lsu_forward_mshr_0_forwardData_6) armed_io_lsu_forward_mshr_0_forwardData_6 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forwardData_6) && g_io_lsu_forward_mshr_0_forwardData_6 !== i_io_lsu_forward_mshr_0_forwardData_6) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forwardData_6: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forwardData_6, i_io_lsu_forward_mshr_0_forwardData_6);
    end
    seen1_io_lsu_forward_mshr_0_forwardData_6 |= g_io_lsu_forward_mshr_0_forwardData_6;
    seen0_io_lsu_forward_mshr_0_forwardData_6 |= ~g_io_lsu_forward_mshr_0_forwardData_6;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_7 && g_io_lsu_forward_mshr_0_forwardData_7 === i_io_lsu_forward_mshr_0_forwardData_7) armed_io_lsu_forward_mshr_0_forwardData_7 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forwardData_7) && g_io_lsu_forward_mshr_0_forwardData_7 !== i_io_lsu_forward_mshr_0_forwardData_7) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forwardData_7: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forwardData_7, i_io_lsu_forward_mshr_0_forwardData_7);
    end
    seen1_io_lsu_forward_mshr_0_forwardData_7 |= g_io_lsu_forward_mshr_0_forwardData_7;
    seen0_io_lsu_forward_mshr_0_forwardData_7 |= ~g_io_lsu_forward_mshr_0_forwardData_7;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_8 && g_io_lsu_forward_mshr_0_forwardData_8 === i_io_lsu_forward_mshr_0_forwardData_8) armed_io_lsu_forward_mshr_0_forwardData_8 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forwardData_8) && g_io_lsu_forward_mshr_0_forwardData_8 !== i_io_lsu_forward_mshr_0_forwardData_8) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forwardData_8: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forwardData_8, i_io_lsu_forward_mshr_0_forwardData_8);
    end
    seen1_io_lsu_forward_mshr_0_forwardData_8 |= g_io_lsu_forward_mshr_0_forwardData_8;
    seen0_io_lsu_forward_mshr_0_forwardData_8 |= ~g_io_lsu_forward_mshr_0_forwardData_8;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_9 && g_io_lsu_forward_mshr_0_forwardData_9 === i_io_lsu_forward_mshr_0_forwardData_9) armed_io_lsu_forward_mshr_0_forwardData_9 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forwardData_9) && g_io_lsu_forward_mshr_0_forwardData_9 !== i_io_lsu_forward_mshr_0_forwardData_9) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forwardData_9: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forwardData_9, i_io_lsu_forward_mshr_0_forwardData_9);
    end
    seen1_io_lsu_forward_mshr_0_forwardData_9 |= g_io_lsu_forward_mshr_0_forwardData_9;
    seen0_io_lsu_forward_mshr_0_forwardData_9 |= ~g_io_lsu_forward_mshr_0_forwardData_9;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_10 && g_io_lsu_forward_mshr_0_forwardData_10 === i_io_lsu_forward_mshr_0_forwardData_10) armed_io_lsu_forward_mshr_0_forwardData_10 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forwardData_10) && g_io_lsu_forward_mshr_0_forwardData_10 !== i_io_lsu_forward_mshr_0_forwardData_10) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forwardData_10: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forwardData_10, i_io_lsu_forward_mshr_0_forwardData_10);
    end
    seen1_io_lsu_forward_mshr_0_forwardData_10 |= g_io_lsu_forward_mshr_0_forwardData_10;
    seen0_io_lsu_forward_mshr_0_forwardData_10 |= ~g_io_lsu_forward_mshr_0_forwardData_10;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_11 && g_io_lsu_forward_mshr_0_forwardData_11 === i_io_lsu_forward_mshr_0_forwardData_11) armed_io_lsu_forward_mshr_0_forwardData_11 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forwardData_11) && g_io_lsu_forward_mshr_0_forwardData_11 !== i_io_lsu_forward_mshr_0_forwardData_11) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forwardData_11: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forwardData_11, i_io_lsu_forward_mshr_0_forwardData_11);
    end
    seen1_io_lsu_forward_mshr_0_forwardData_11 |= g_io_lsu_forward_mshr_0_forwardData_11;
    seen0_io_lsu_forward_mshr_0_forwardData_11 |= ~g_io_lsu_forward_mshr_0_forwardData_11;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_12 && g_io_lsu_forward_mshr_0_forwardData_12 === i_io_lsu_forward_mshr_0_forwardData_12) armed_io_lsu_forward_mshr_0_forwardData_12 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forwardData_12) && g_io_lsu_forward_mshr_0_forwardData_12 !== i_io_lsu_forward_mshr_0_forwardData_12) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forwardData_12: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forwardData_12, i_io_lsu_forward_mshr_0_forwardData_12);
    end
    seen1_io_lsu_forward_mshr_0_forwardData_12 |= g_io_lsu_forward_mshr_0_forwardData_12;
    seen0_io_lsu_forward_mshr_0_forwardData_12 |= ~g_io_lsu_forward_mshr_0_forwardData_12;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_13 && g_io_lsu_forward_mshr_0_forwardData_13 === i_io_lsu_forward_mshr_0_forwardData_13) armed_io_lsu_forward_mshr_0_forwardData_13 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forwardData_13) && g_io_lsu_forward_mshr_0_forwardData_13 !== i_io_lsu_forward_mshr_0_forwardData_13) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forwardData_13: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forwardData_13, i_io_lsu_forward_mshr_0_forwardData_13);
    end
    seen1_io_lsu_forward_mshr_0_forwardData_13 |= g_io_lsu_forward_mshr_0_forwardData_13;
    seen0_io_lsu_forward_mshr_0_forwardData_13 |= ~g_io_lsu_forward_mshr_0_forwardData_13;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_14 && g_io_lsu_forward_mshr_0_forwardData_14 === i_io_lsu_forward_mshr_0_forwardData_14) armed_io_lsu_forward_mshr_0_forwardData_14 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forwardData_14) && g_io_lsu_forward_mshr_0_forwardData_14 !== i_io_lsu_forward_mshr_0_forwardData_14) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forwardData_14: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forwardData_14, i_io_lsu_forward_mshr_0_forwardData_14);
    end
    seen1_io_lsu_forward_mshr_0_forwardData_14 |= g_io_lsu_forward_mshr_0_forwardData_14;
    seen0_io_lsu_forward_mshr_0_forwardData_14 |= ~g_io_lsu_forward_mshr_0_forwardData_14;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_15 && g_io_lsu_forward_mshr_0_forwardData_15 === i_io_lsu_forward_mshr_0_forwardData_15) armed_io_lsu_forward_mshr_0_forwardData_15 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forwardData_15) && g_io_lsu_forward_mshr_0_forwardData_15 !== i_io_lsu_forward_mshr_0_forwardData_15) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forwardData_15: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forwardData_15, i_io_lsu_forward_mshr_0_forwardData_15);
    end
    seen1_io_lsu_forward_mshr_0_forwardData_15 |= g_io_lsu_forward_mshr_0_forwardData_15;
    seen0_io_lsu_forward_mshr_0_forwardData_15 |= ~g_io_lsu_forward_mshr_0_forwardData_15;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_forward_result_valid && g_io_lsu_forward_mshr_0_forward_result_valid === i_io_lsu_forward_mshr_0_forward_result_valid) armed_io_lsu_forward_mshr_0_forward_result_valid = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_forward_result_valid) && g_io_lsu_forward_mshr_0_forward_result_valid !== i_io_lsu_forward_mshr_0_forward_result_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_forward_result_valid: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_forward_result_valid, i_io_lsu_forward_mshr_0_forward_result_valid);
    end
    seen1_io_lsu_forward_mshr_0_forward_result_valid |= g_io_lsu_forward_mshr_0_forward_result_valid;
    seen0_io_lsu_forward_mshr_0_forward_result_valid |= ~g_io_lsu_forward_mshr_0_forward_result_valid;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_denied && g_io_lsu_forward_mshr_0_denied === i_io_lsu_forward_mshr_0_denied) armed_io_lsu_forward_mshr_0_denied = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_denied) && g_io_lsu_forward_mshr_0_denied !== i_io_lsu_forward_mshr_0_denied) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_denied: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_denied, i_io_lsu_forward_mshr_0_denied);
    end
    seen1_io_lsu_forward_mshr_0_denied |= g_io_lsu_forward_mshr_0_denied;
    seen0_io_lsu_forward_mshr_0_denied |= ~g_io_lsu_forward_mshr_0_denied;
    if (!cmp_all && !armed_io_lsu_forward_mshr_0_corrupt && g_io_lsu_forward_mshr_0_corrupt === i_io_lsu_forward_mshr_0_corrupt) armed_io_lsu_forward_mshr_0_corrupt = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_0_corrupt) && g_io_lsu_forward_mshr_0_corrupt !== i_io_lsu_forward_mshr_0_corrupt) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_0_corrupt: g=%h i=%h", cyc, g_io_lsu_forward_mshr_0_corrupt, i_io_lsu_forward_mshr_0_corrupt);
    end
    seen1_io_lsu_forward_mshr_0_corrupt |= g_io_lsu_forward_mshr_0_corrupt;
    seen0_io_lsu_forward_mshr_0_corrupt |= ~g_io_lsu_forward_mshr_0_corrupt;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forward_mshr && g_io_lsu_forward_mshr_1_forward_mshr === i_io_lsu_forward_mshr_1_forward_mshr) armed_io_lsu_forward_mshr_1_forward_mshr = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forward_mshr) && g_io_lsu_forward_mshr_1_forward_mshr !== i_io_lsu_forward_mshr_1_forward_mshr) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forward_mshr: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forward_mshr, i_io_lsu_forward_mshr_1_forward_mshr);
    end
    seen1_io_lsu_forward_mshr_1_forward_mshr |= g_io_lsu_forward_mshr_1_forward_mshr;
    seen0_io_lsu_forward_mshr_1_forward_mshr |= ~g_io_lsu_forward_mshr_1_forward_mshr;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_0 && g_io_lsu_forward_mshr_1_forwardData_0 === i_io_lsu_forward_mshr_1_forwardData_0) armed_io_lsu_forward_mshr_1_forwardData_0 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forwardData_0) && g_io_lsu_forward_mshr_1_forwardData_0 !== i_io_lsu_forward_mshr_1_forwardData_0) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forwardData_0: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forwardData_0, i_io_lsu_forward_mshr_1_forwardData_0);
    end
    seen1_io_lsu_forward_mshr_1_forwardData_0 |= g_io_lsu_forward_mshr_1_forwardData_0;
    seen0_io_lsu_forward_mshr_1_forwardData_0 |= ~g_io_lsu_forward_mshr_1_forwardData_0;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_1 && g_io_lsu_forward_mshr_1_forwardData_1 === i_io_lsu_forward_mshr_1_forwardData_1) armed_io_lsu_forward_mshr_1_forwardData_1 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forwardData_1) && g_io_lsu_forward_mshr_1_forwardData_1 !== i_io_lsu_forward_mshr_1_forwardData_1) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forwardData_1: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forwardData_1, i_io_lsu_forward_mshr_1_forwardData_1);
    end
    seen1_io_lsu_forward_mshr_1_forwardData_1 |= g_io_lsu_forward_mshr_1_forwardData_1;
    seen0_io_lsu_forward_mshr_1_forwardData_1 |= ~g_io_lsu_forward_mshr_1_forwardData_1;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_2 && g_io_lsu_forward_mshr_1_forwardData_2 === i_io_lsu_forward_mshr_1_forwardData_2) armed_io_lsu_forward_mshr_1_forwardData_2 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forwardData_2) && g_io_lsu_forward_mshr_1_forwardData_2 !== i_io_lsu_forward_mshr_1_forwardData_2) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forwardData_2: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forwardData_2, i_io_lsu_forward_mshr_1_forwardData_2);
    end
    seen1_io_lsu_forward_mshr_1_forwardData_2 |= g_io_lsu_forward_mshr_1_forwardData_2;
    seen0_io_lsu_forward_mshr_1_forwardData_2 |= ~g_io_lsu_forward_mshr_1_forwardData_2;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_3 && g_io_lsu_forward_mshr_1_forwardData_3 === i_io_lsu_forward_mshr_1_forwardData_3) armed_io_lsu_forward_mshr_1_forwardData_3 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forwardData_3) && g_io_lsu_forward_mshr_1_forwardData_3 !== i_io_lsu_forward_mshr_1_forwardData_3) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forwardData_3: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forwardData_3, i_io_lsu_forward_mshr_1_forwardData_3);
    end
    seen1_io_lsu_forward_mshr_1_forwardData_3 |= g_io_lsu_forward_mshr_1_forwardData_3;
    seen0_io_lsu_forward_mshr_1_forwardData_3 |= ~g_io_lsu_forward_mshr_1_forwardData_3;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_4 && g_io_lsu_forward_mshr_1_forwardData_4 === i_io_lsu_forward_mshr_1_forwardData_4) armed_io_lsu_forward_mshr_1_forwardData_4 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forwardData_4) && g_io_lsu_forward_mshr_1_forwardData_4 !== i_io_lsu_forward_mshr_1_forwardData_4) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forwardData_4: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forwardData_4, i_io_lsu_forward_mshr_1_forwardData_4);
    end
    seen1_io_lsu_forward_mshr_1_forwardData_4 |= g_io_lsu_forward_mshr_1_forwardData_4;
    seen0_io_lsu_forward_mshr_1_forwardData_4 |= ~g_io_lsu_forward_mshr_1_forwardData_4;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_5 && g_io_lsu_forward_mshr_1_forwardData_5 === i_io_lsu_forward_mshr_1_forwardData_5) armed_io_lsu_forward_mshr_1_forwardData_5 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forwardData_5) && g_io_lsu_forward_mshr_1_forwardData_5 !== i_io_lsu_forward_mshr_1_forwardData_5) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forwardData_5: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forwardData_5, i_io_lsu_forward_mshr_1_forwardData_5);
    end
    seen1_io_lsu_forward_mshr_1_forwardData_5 |= g_io_lsu_forward_mshr_1_forwardData_5;
    seen0_io_lsu_forward_mshr_1_forwardData_5 |= ~g_io_lsu_forward_mshr_1_forwardData_5;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_6 && g_io_lsu_forward_mshr_1_forwardData_6 === i_io_lsu_forward_mshr_1_forwardData_6) armed_io_lsu_forward_mshr_1_forwardData_6 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forwardData_6) && g_io_lsu_forward_mshr_1_forwardData_6 !== i_io_lsu_forward_mshr_1_forwardData_6) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forwardData_6: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forwardData_6, i_io_lsu_forward_mshr_1_forwardData_6);
    end
    seen1_io_lsu_forward_mshr_1_forwardData_6 |= g_io_lsu_forward_mshr_1_forwardData_6;
    seen0_io_lsu_forward_mshr_1_forwardData_6 |= ~g_io_lsu_forward_mshr_1_forwardData_6;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_7 && g_io_lsu_forward_mshr_1_forwardData_7 === i_io_lsu_forward_mshr_1_forwardData_7) armed_io_lsu_forward_mshr_1_forwardData_7 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forwardData_7) && g_io_lsu_forward_mshr_1_forwardData_7 !== i_io_lsu_forward_mshr_1_forwardData_7) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forwardData_7: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forwardData_7, i_io_lsu_forward_mshr_1_forwardData_7);
    end
    seen1_io_lsu_forward_mshr_1_forwardData_7 |= g_io_lsu_forward_mshr_1_forwardData_7;
    seen0_io_lsu_forward_mshr_1_forwardData_7 |= ~g_io_lsu_forward_mshr_1_forwardData_7;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_8 && g_io_lsu_forward_mshr_1_forwardData_8 === i_io_lsu_forward_mshr_1_forwardData_8) armed_io_lsu_forward_mshr_1_forwardData_8 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forwardData_8) && g_io_lsu_forward_mshr_1_forwardData_8 !== i_io_lsu_forward_mshr_1_forwardData_8) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forwardData_8: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forwardData_8, i_io_lsu_forward_mshr_1_forwardData_8);
    end
    seen1_io_lsu_forward_mshr_1_forwardData_8 |= g_io_lsu_forward_mshr_1_forwardData_8;
    seen0_io_lsu_forward_mshr_1_forwardData_8 |= ~g_io_lsu_forward_mshr_1_forwardData_8;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_9 && g_io_lsu_forward_mshr_1_forwardData_9 === i_io_lsu_forward_mshr_1_forwardData_9) armed_io_lsu_forward_mshr_1_forwardData_9 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forwardData_9) && g_io_lsu_forward_mshr_1_forwardData_9 !== i_io_lsu_forward_mshr_1_forwardData_9) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forwardData_9: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forwardData_9, i_io_lsu_forward_mshr_1_forwardData_9);
    end
    seen1_io_lsu_forward_mshr_1_forwardData_9 |= g_io_lsu_forward_mshr_1_forwardData_9;
    seen0_io_lsu_forward_mshr_1_forwardData_9 |= ~g_io_lsu_forward_mshr_1_forwardData_9;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_10 && g_io_lsu_forward_mshr_1_forwardData_10 === i_io_lsu_forward_mshr_1_forwardData_10) armed_io_lsu_forward_mshr_1_forwardData_10 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forwardData_10) && g_io_lsu_forward_mshr_1_forwardData_10 !== i_io_lsu_forward_mshr_1_forwardData_10) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forwardData_10: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forwardData_10, i_io_lsu_forward_mshr_1_forwardData_10);
    end
    seen1_io_lsu_forward_mshr_1_forwardData_10 |= g_io_lsu_forward_mshr_1_forwardData_10;
    seen0_io_lsu_forward_mshr_1_forwardData_10 |= ~g_io_lsu_forward_mshr_1_forwardData_10;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_11 && g_io_lsu_forward_mshr_1_forwardData_11 === i_io_lsu_forward_mshr_1_forwardData_11) armed_io_lsu_forward_mshr_1_forwardData_11 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forwardData_11) && g_io_lsu_forward_mshr_1_forwardData_11 !== i_io_lsu_forward_mshr_1_forwardData_11) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forwardData_11: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forwardData_11, i_io_lsu_forward_mshr_1_forwardData_11);
    end
    seen1_io_lsu_forward_mshr_1_forwardData_11 |= g_io_lsu_forward_mshr_1_forwardData_11;
    seen0_io_lsu_forward_mshr_1_forwardData_11 |= ~g_io_lsu_forward_mshr_1_forwardData_11;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_12 && g_io_lsu_forward_mshr_1_forwardData_12 === i_io_lsu_forward_mshr_1_forwardData_12) armed_io_lsu_forward_mshr_1_forwardData_12 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forwardData_12) && g_io_lsu_forward_mshr_1_forwardData_12 !== i_io_lsu_forward_mshr_1_forwardData_12) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forwardData_12: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forwardData_12, i_io_lsu_forward_mshr_1_forwardData_12);
    end
    seen1_io_lsu_forward_mshr_1_forwardData_12 |= g_io_lsu_forward_mshr_1_forwardData_12;
    seen0_io_lsu_forward_mshr_1_forwardData_12 |= ~g_io_lsu_forward_mshr_1_forwardData_12;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_13 && g_io_lsu_forward_mshr_1_forwardData_13 === i_io_lsu_forward_mshr_1_forwardData_13) armed_io_lsu_forward_mshr_1_forwardData_13 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forwardData_13) && g_io_lsu_forward_mshr_1_forwardData_13 !== i_io_lsu_forward_mshr_1_forwardData_13) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forwardData_13: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forwardData_13, i_io_lsu_forward_mshr_1_forwardData_13);
    end
    seen1_io_lsu_forward_mshr_1_forwardData_13 |= g_io_lsu_forward_mshr_1_forwardData_13;
    seen0_io_lsu_forward_mshr_1_forwardData_13 |= ~g_io_lsu_forward_mshr_1_forwardData_13;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_14 && g_io_lsu_forward_mshr_1_forwardData_14 === i_io_lsu_forward_mshr_1_forwardData_14) armed_io_lsu_forward_mshr_1_forwardData_14 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forwardData_14) && g_io_lsu_forward_mshr_1_forwardData_14 !== i_io_lsu_forward_mshr_1_forwardData_14) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forwardData_14: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forwardData_14, i_io_lsu_forward_mshr_1_forwardData_14);
    end
    seen1_io_lsu_forward_mshr_1_forwardData_14 |= g_io_lsu_forward_mshr_1_forwardData_14;
    seen0_io_lsu_forward_mshr_1_forwardData_14 |= ~g_io_lsu_forward_mshr_1_forwardData_14;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_15 && g_io_lsu_forward_mshr_1_forwardData_15 === i_io_lsu_forward_mshr_1_forwardData_15) armed_io_lsu_forward_mshr_1_forwardData_15 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forwardData_15) && g_io_lsu_forward_mshr_1_forwardData_15 !== i_io_lsu_forward_mshr_1_forwardData_15) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forwardData_15: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forwardData_15, i_io_lsu_forward_mshr_1_forwardData_15);
    end
    seen1_io_lsu_forward_mshr_1_forwardData_15 |= g_io_lsu_forward_mshr_1_forwardData_15;
    seen0_io_lsu_forward_mshr_1_forwardData_15 |= ~g_io_lsu_forward_mshr_1_forwardData_15;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_forward_result_valid && g_io_lsu_forward_mshr_1_forward_result_valid === i_io_lsu_forward_mshr_1_forward_result_valid) armed_io_lsu_forward_mshr_1_forward_result_valid = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_forward_result_valid) && g_io_lsu_forward_mshr_1_forward_result_valid !== i_io_lsu_forward_mshr_1_forward_result_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_forward_result_valid: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_forward_result_valid, i_io_lsu_forward_mshr_1_forward_result_valid);
    end
    seen1_io_lsu_forward_mshr_1_forward_result_valid |= g_io_lsu_forward_mshr_1_forward_result_valid;
    seen0_io_lsu_forward_mshr_1_forward_result_valid |= ~g_io_lsu_forward_mshr_1_forward_result_valid;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_denied && g_io_lsu_forward_mshr_1_denied === i_io_lsu_forward_mshr_1_denied) armed_io_lsu_forward_mshr_1_denied = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_denied) && g_io_lsu_forward_mshr_1_denied !== i_io_lsu_forward_mshr_1_denied) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_denied: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_denied, i_io_lsu_forward_mshr_1_denied);
    end
    seen1_io_lsu_forward_mshr_1_denied |= g_io_lsu_forward_mshr_1_denied;
    seen0_io_lsu_forward_mshr_1_denied |= ~g_io_lsu_forward_mshr_1_denied;
    if (!cmp_all && !armed_io_lsu_forward_mshr_1_corrupt && g_io_lsu_forward_mshr_1_corrupt === i_io_lsu_forward_mshr_1_corrupt) armed_io_lsu_forward_mshr_1_corrupt = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_1_corrupt) && g_io_lsu_forward_mshr_1_corrupt !== i_io_lsu_forward_mshr_1_corrupt) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_1_corrupt: g=%h i=%h", cyc, g_io_lsu_forward_mshr_1_corrupt, i_io_lsu_forward_mshr_1_corrupt);
    end
    seen1_io_lsu_forward_mshr_1_corrupt |= g_io_lsu_forward_mshr_1_corrupt;
    seen0_io_lsu_forward_mshr_1_corrupt |= ~g_io_lsu_forward_mshr_1_corrupt;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forward_mshr && g_io_lsu_forward_mshr_2_forward_mshr === i_io_lsu_forward_mshr_2_forward_mshr) armed_io_lsu_forward_mshr_2_forward_mshr = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forward_mshr) && g_io_lsu_forward_mshr_2_forward_mshr !== i_io_lsu_forward_mshr_2_forward_mshr) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forward_mshr: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forward_mshr, i_io_lsu_forward_mshr_2_forward_mshr);
    end
    seen1_io_lsu_forward_mshr_2_forward_mshr |= g_io_lsu_forward_mshr_2_forward_mshr;
    seen0_io_lsu_forward_mshr_2_forward_mshr |= ~g_io_lsu_forward_mshr_2_forward_mshr;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_0 && g_io_lsu_forward_mshr_2_forwardData_0 === i_io_lsu_forward_mshr_2_forwardData_0) armed_io_lsu_forward_mshr_2_forwardData_0 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forwardData_0) && g_io_lsu_forward_mshr_2_forwardData_0 !== i_io_lsu_forward_mshr_2_forwardData_0) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forwardData_0: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forwardData_0, i_io_lsu_forward_mshr_2_forwardData_0);
    end
    seen1_io_lsu_forward_mshr_2_forwardData_0 |= g_io_lsu_forward_mshr_2_forwardData_0;
    seen0_io_lsu_forward_mshr_2_forwardData_0 |= ~g_io_lsu_forward_mshr_2_forwardData_0;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_1 && g_io_lsu_forward_mshr_2_forwardData_1 === i_io_lsu_forward_mshr_2_forwardData_1) armed_io_lsu_forward_mshr_2_forwardData_1 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forwardData_1) && g_io_lsu_forward_mshr_2_forwardData_1 !== i_io_lsu_forward_mshr_2_forwardData_1) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forwardData_1: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forwardData_1, i_io_lsu_forward_mshr_2_forwardData_1);
    end
    seen1_io_lsu_forward_mshr_2_forwardData_1 |= g_io_lsu_forward_mshr_2_forwardData_1;
    seen0_io_lsu_forward_mshr_2_forwardData_1 |= ~g_io_lsu_forward_mshr_2_forwardData_1;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_2 && g_io_lsu_forward_mshr_2_forwardData_2 === i_io_lsu_forward_mshr_2_forwardData_2) armed_io_lsu_forward_mshr_2_forwardData_2 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forwardData_2) && g_io_lsu_forward_mshr_2_forwardData_2 !== i_io_lsu_forward_mshr_2_forwardData_2) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forwardData_2: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forwardData_2, i_io_lsu_forward_mshr_2_forwardData_2);
    end
    seen1_io_lsu_forward_mshr_2_forwardData_2 |= g_io_lsu_forward_mshr_2_forwardData_2;
    seen0_io_lsu_forward_mshr_2_forwardData_2 |= ~g_io_lsu_forward_mshr_2_forwardData_2;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_3 && g_io_lsu_forward_mshr_2_forwardData_3 === i_io_lsu_forward_mshr_2_forwardData_3) armed_io_lsu_forward_mshr_2_forwardData_3 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forwardData_3) && g_io_lsu_forward_mshr_2_forwardData_3 !== i_io_lsu_forward_mshr_2_forwardData_3) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forwardData_3: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forwardData_3, i_io_lsu_forward_mshr_2_forwardData_3);
    end
    seen1_io_lsu_forward_mshr_2_forwardData_3 |= g_io_lsu_forward_mshr_2_forwardData_3;
    seen0_io_lsu_forward_mshr_2_forwardData_3 |= ~g_io_lsu_forward_mshr_2_forwardData_3;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_4 && g_io_lsu_forward_mshr_2_forwardData_4 === i_io_lsu_forward_mshr_2_forwardData_4) armed_io_lsu_forward_mshr_2_forwardData_4 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forwardData_4) && g_io_lsu_forward_mshr_2_forwardData_4 !== i_io_lsu_forward_mshr_2_forwardData_4) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forwardData_4: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forwardData_4, i_io_lsu_forward_mshr_2_forwardData_4);
    end
    seen1_io_lsu_forward_mshr_2_forwardData_4 |= g_io_lsu_forward_mshr_2_forwardData_4;
    seen0_io_lsu_forward_mshr_2_forwardData_4 |= ~g_io_lsu_forward_mshr_2_forwardData_4;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_5 && g_io_lsu_forward_mshr_2_forwardData_5 === i_io_lsu_forward_mshr_2_forwardData_5) armed_io_lsu_forward_mshr_2_forwardData_5 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forwardData_5) && g_io_lsu_forward_mshr_2_forwardData_5 !== i_io_lsu_forward_mshr_2_forwardData_5) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forwardData_5: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forwardData_5, i_io_lsu_forward_mshr_2_forwardData_5);
    end
    seen1_io_lsu_forward_mshr_2_forwardData_5 |= g_io_lsu_forward_mshr_2_forwardData_5;
    seen0_io_lsu_forward_mshr_2_forwardData_5 |= ~g_io_lsu_forward_mshr_2_forwardData_5;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_6 && g_io_lsu_forward_mshr_2_forwardData_6 === i_io_lsu_forward_mshr_2_forwardData_6) armed_io_lsu_forward_mshr_2_forwardData_6 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forwardData_6) && g_io_lsu_forward_mshr_2_forwardData_6 !== i_io_lsu_forward_mshr_2_forwardData_6) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forwardData_6: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forwardData_6, i_io_lsu_forward_mshr_2_forwardData_6);
    end
    seen1_io_lsu_forward_mshr_2_forwardData_6 |= g_io_lsu_forward_mshr_2_forwardData_6;
    seen0_io_lsu_forward_mshr_2_forwardData_6 |= ~g_io_lsu_forward_mshr_2_forwardData_6;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_7 && g_io_lsu_forward_mshr_2_forwardData_7 === i_io_lsu_forward_mshr_2_forwardData_7) armed_io_lsu_forward_mshr_2_forwardData_7 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forwardData_7) && g_io_lsu_forward_mshr_2_forwardData_7 !== i_io_lsu_forward_mshr_2_forwardData_7) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forwardData_7: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forwardData_7, i_io_lsu_forward_mshr_2_forwardData_7);
    end
    seen1_io_lsu_forward_mshr_2_forwardData_7 |= g_io_lsu_forward_mshr_2_forwardData_7;
    seen0_io_lsu_forward_mshr_2_forwardData_7 |= ~g_io_lsu_forward_mshr_2_forwardData_7;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_8 && g_io_lsu_forward_mshr_2_forwardData_8 === i_io_lsu_forward_mshr_2_forwardData_8) armed_io_lsu_forward_mshr_2_forwardData_8 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forwardData_8) && g_io_lsu_forward_mshr_2_forwardData_8 !== i_io_lsu_forward_mshr_2_forwardData_8) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forwardData_8: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forwardData_8, i_io_lsu_forward_mshr_2_forwardData_8);
    end
    seen1_io_lsu_forward_mshr_2_forwardData_8 |= g_io_lsu_forward_mshr_2_forwardData_8;
    seen0_io_lsu_forward_mshr_2_forwardData_8 |= ~g_io_lsu_forward_mshr_2_forwardData_8;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_9 && g_io_lsu_forward_mshr_2_forwardData_9 === i_io_lsu_forward_mshr_2_forwardData_9) armed_io_lsu_forward_mshr_2_forwardData_9 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forwardData_9) && g_io_lsu_forward_mshr_2_forwardData_9 !== i_io_lsu_forward_mshr_2_forwardData_9) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forwardData_9: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forwardData_9, i_io_lsu_forward_mshr_2_forwardData_9);
    end
    seen1_io_lsu_forward_mshr_2_forwardData_9 |= g_io_lsu_forward_mshr_2_forwardData_9;
    seen0_io_lsu_forward_mshr_2_forwardData_9 |= ~g_io_lsu_forward_mshr_2_forwardData_9;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_10 && g_io_lsu_forward_mshr_2_forwardData_10 === i_io_lsu_forward_mshr_2_forwardData_10) armed_io_lsu_forward_mshr_2_forwardData_10 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forwardData_10) && g_io_lsu_forward_mshr_2_forwardData_10 !== i_io_lsu_forward_mshr_2_forwardData_10) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forwardData_10: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forwardData_10, i_io_lsu_forward_mshr_2_forwardData_10);
    end
    seen1_io_lsu_forward_mshr_2_forwardData_10 |= g_io_lsu_forward_mshr_2_forwardData_10;
    seen0_io_lsu_forward_mshr_2_forwardData_10 |= ~g_io_lsu_forward_mshr_2_forwardData_10;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_11 && g_io_lsu_forward_mshr_2_forwardData_11 === i_io_lsu_forward_mshr_2_forwardData_11) armed_io_lsu_forward_mshr_2_forwardData_11 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forwardData_11) && g_io_lsu_forward_mshr_2_forwardData_11 !== i_io_lsu_forward_mshr_2_forwardData_11) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forwardData_11: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forwardData_11, i_io_lsu_forward_mshr_2_forwardData_11);
    end
    seen1_io_lsu_forward_mshr_2_forwardData_11 |= g_io_lsu_forward_mshr_2_forwardData_11;
    seen0_io_lsu_forward_mshr_2_forwardData_11 |= ~g_io_lsu_forward_mshr_2_forwardData_11;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_12 && g_io_lsu_forward_mshr_2_forwardData_12 === i_io_lsu_forward_mshr_2_forwardData_12) armed_io_lsu_forward_mshr_2_forwardData_12 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forwardData_12) && g_io_lsu_forward_mshr_2_forwardData_12 !== i_io_lsu_forward_mshr_2_forwardData_12) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forwardData_12: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forwardData_12, i_io_lsu_forward_mshr_2_forwardData_12);
    end
    seen1_io_lsu_forward_mshr_2_forwardData_12 |= g_io_lsu_forward_mshr_2_forwardData_12;
    seen0_io_lsu_forward_mshr_2_forwardData_12 |= ~g_io_lsu_forward_mshr_2_forwardData_12;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_13 && g_io_lsu_forward_mshr_2_forwardData_13 === i_io_lsu_forward_mshr_2_forwardData_13) armed_io_lsu_forward_mshr_2_forwardData_13 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forwardData_13) && g_io_lsu_forward_mshr_2_forwardData_13 !== i_io_lsu_forward_mshr_2_forwardData_13) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forwardData_13: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forwardData_13, i_io_lsu_forward_mshr_2_forwardData_13);
    end
    seen1_io_lsu_forward_mshr_2_forwardData_13 |= g_io_lsu_forward_mshr_2_forwardData_13;
    seen0_io_lsu_forward_mshr_2_forwardData_13 |= ~g_io_lsu_forward_mshr_2_forwardData_13;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_14 && g_io_lsu_forward_mshr_2_forwardData_14 === i_io_lsu_forward_mshr_2_forwardData_14) armed_io_lsu_forward_mshr_2_forwardData_14 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forwardData_14) && g_io_lsu_forward_mshr_2_forwardData_14 !== i_io_lsu_forward_mshr_2_forwardData_14) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forwardData_14: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forwardData_14, i_io_lsu_forward_mshr_2_forwardData_14);
    end
    seen1_io_lsu_forward_mshr_2_forwardData_14 |= g_io_lsu_forward_mshr_2_forwardData_14;
    seen0_io_lsu_forward_mshr_2_forwardData_14 |= ~g_io_lsu_forward_mshr_2_forwardData_14;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_15 && g_io_lsu_forward_mshr_2_forwardData_15 === i_io_lsu_forward_mshr_2_forwardData_15) armed_io_lsu_forward_mshr_2_forwardData_15 = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forwardData_15) && g_io_lsu_forward_mshr_2_forwardData_15 !== i_io_lsu_forward_mshr_2_forwardData_15) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forwardData_15: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forwardData_15, i_io_lsu_forward_mshr_2_forwardData_15);
    end
    seen1_io_lsu_forward_mshr_2_forwardData_15 |= g_io_lsu_forward_mshr_2_forwardData_15;
    seen0_io_lsu_forward_mshr_2_forwardData_15 |= ~g_io_lsu_forward_mshr_2_forwardData_15;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_forward_result_valid && g_io_lsu_forward_mshr_2_forward_result_valid === i_io_lsu_forward_mshr_2_forward_result_valid) armed_io_lsu_forward_mshr_2_forward_result_valid = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_forward_result_valid) && g_io_lsu_forward_mshr_2_forward_result_valid !== i_io_lsu_forward_mshr_2_forward_result_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_forward_result_valid: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_forward_result_valid, i_io_lsu_forward_mshr_2_forward_result_valid);
    end
    seen1_io_lsu_forward_mshr_2_forward_result_valid |= g_io_lsu_forward_mshr_2_forward_result_valid;
    seen0_io_lsu_forward_mshr_2_forward_result_valid |= ~g_io_lsu_forward_mshr_2_forward_result_valid;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_denied && g_io_lsu_forward_mshr_2_denied === i_io_lsu_forward_mshr_2_denied) armed_io_lsu_forward_mshr_2_denied = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_denied) && g_io_lsu_forward_mshr_2_denied !== i_io_lsu_forward_mshr_2_denied) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_denied: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_denied, i_io_lsu_forward_mshr_2_denied);
    end
    seen1_io_lsu_forward_mshr_2_denied |= g_io_lsu_forward_mshr_2_denied;
    seen0_io_lsu_forward_mshr_2_denied |= ~g_io_lsu_forward_mshr_2_denied;
    if (!cmp_all && !armed_io_lsu_forward_mshr_2_corrupt && g_io_lsu_forward_mshr_2_corrupt === i_io_lsu_forward_mshr_2_corrupt) armed_io_lsu_forward_mshr_2_corrupt = 1;
    if ((cmp_all | armed_io_lsu_forward_mshr_2_corrupt) && g_io_lsu_forward_mshr_2_corrupt !== i_io_lsu_forward_mshr_2_corrupt) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_lsu_forward_mshr_2_corrupt: g=%h i=%h", cyc, g_io_lsu_forward_mshr_2_corrupt, i_io_lsu_forward_mshr_2_corrupt);
    end
    seen1_io_lsu_forward_mshr_2_corrupt |= g_io_lsu_forward_mshr_2_corrupt;
    seen0_io_lsu_forward_mshr_2_corrupt |= ~g_io_lsu_forward_mshr_2_corrupt;
    if (!cmp_all && !armed_io_error_valid && g_io_error_valid === i_io_error_valid) armed_io_error_valid = 1;
    if ((cmp_all | armed_io_error_valid) && g_io_error_valid !== i_io_error_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_error_valid: g=%h i=%h", cyc, g_io_error_valid, i_io_error_valid);
    end
    seen1_io_error_valid |= g_io_error_valid;
    seen0_io_error_valid |= ~g_io_error_valid;
    if (!cmp_all && !armed_io_error_bits_paddr && g_io_error_bits_paddr === i_io_error_bits_paddr) armed_io_error_bits_paddr = 1;
    if ((cmp_all | armed_io_error_bits_paddr) && (cmp_all | g_io_error_valid) && (g_io_error_bits_paddr !== i_io_error_bits_paddr)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_error_bits_paddr: g=%h i=%h", cyc, g_io_error_bits_paddr, i_io_error_bits_paddr);
    end
    seen1_io_error_bits_paddr |= g_io_error_bits_paddr;
    seen0_io_error_bits_paddr |= ~g_io_error_bits_paddr;
    if (!cmp_all && !armed_io_error_bits_report_to_beu && g_io_error_bits_report_to_beu === i_io_error_bits_report_to_beu) armed_io_error_bits_report_to_beu = 1;
    if ((cmp_all | armed_io_error_bits_report_to_beu) && (cmp_all | g_io_error_valid) && (g_io_error_bits_report_to_beu !== i_io_error_bits_report_to_beu)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_error_bits_report_to_beu: g=%h i=%h", cyc, g_io_error_bits_report_to_beu, i_io_error_bits_report_to_beu);
    end
    seen1_io_error_bits_report_to_beu |= g_io_error_bits_report_to_beu;
    seen0_io_error_bits_report_to_beu |= ~g_io_error_bits_report_to_beu;
    if (!cmp_all && !armed_io_pf_ctrl_enable && g_io_pf_ctrl_enable === i_io_pf_ctrl_enable) armed_io_pf_ctrl_enable = 1;
    if ((cmp_all | armed_io_pf_ctrl_enable) && g_io_pf_ctrl_enable !== i_io_pf_ctrl_enable) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_pf_ctrl_enable: g=%h i=%h", cyc, g_io_pf_ctrl_enable, i_io_pf_ctrl_enable);
    end
    seen1_io_pf_ctrl_enable |= g_io_pf_ctrl_enable;
    seen0_io_pf_ctrl_enable |= ~g_io_pf_ctrl_enable;
    if (!cmp_all && !armed_io_pf_ctrl_confidence && g_io_pf_ctrl_confidence === i_io_pf_ctrl_confidence) armed_io_pf_ctrl_confidence = 1;
    if ((cmp_all | armed_io_pf_ctrl_confidence) && g_io_pf_ctrl_confidence !== i_io_pf_ctrl_confidence) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_pf_ctrl_confidence: g=%h i=%h", cyc, g_io_pf_ctrl_confidence, i_io_pf_ctrl_confidence);
    end
    seen1_io_pf_ctrl_confidence |= g_io_pf_ctrl_confidence;
    seen0_io_pf_ctrl_confidence |= ~g_io_pf_ctrl_confidence;
    if (!cmp_all && !armed_io_sms_agt_evict_req_valid && g_io_sms_agt_evict_req_valid === i_io_sms_agt_evict_req_valid) armed_io_sms_agt_evict_req_valid = 1;
    if ((cmp_all | armed_io_sms_agt_evict_req_valid) && g_io_sms_agt_evict_req_valid !== i_io_sms_agt_evict_req_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_sms_agt_evict_req_valid: g=%h i=%h", cyc, g_io_sms_agt_evict_req_valid, i_io_sms_agt_evict_req_valid);
    end
    seen1_io_sms_agt_evict_req_valid |= g_io_sms_agt_evict_req_valid;
    seen0_io_sms_agt_evict_req_valid |= ~g_io_sms_agt_evict_req_valid;
    if (!cmp_all && !armed_io_sms_agt_evict_req_bits_vaddr && g_io_sms_agt_evict_req_bits_vaddr === i_io_sms_agt_evict_req_bits_vaddr) armed_io_sms_agt_evict_req_bits_vaddr = 1;
    if ((cmp_all | armed_io_sms_agt_evict_req_bits_vaddr) && (cmp_all | g_io_sms_agt_evict_req_valid) && (g_io_sms_agt_evict_req_bits_vaddr !== i_io_sms_agt_evict_req_bits_vaddr)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_sms_agt_evict_req_bits_vaddr: g=%h i=%h", cyc, g_io_sms_agt_evict_req_bits_vaddr, i_io_sms_agt_evict_req_bits_vaddr);
    end
    seen1_io_sms_agt_evict_req_bits_vaddr |= g_io_sms_agt_evict_req_bits_vaddr;
    seen0_io_sms_agt_evict_req_bits_vaddr |= ~g_io_sms_agt_evict_req_bits_vaddr;
    if (!cmp_all && !armed_io_debugTopDown_robHeadMissInDCache && g_io_debugTopDown_robHeadMissInDCache === i_io_debugTopDown_robHeadMissInDCache) armed_io_debugTopDown_robHeadMissInDCache = 1;
    if ((cmp_all | armed_io_debugTopDown_robHeadMissInDCache) && g_io_debugTopDown_robHeadMissInDCache !== i_io_debugTopDown_robHeadMissInDCache) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_debugTopDown_robHeadMissInDCache: g=%h i=%h", cyc, g_io_debugTopDown_robHeadMissInDCache, i_io_debugTopDown_robHeadMissInDCache);
    end
    seen1_io_debugTopDown_robHeadMissInDCache |= g_io_debugTopDown_robHeadMissInDCache;
    seen0_io_debugTopDown_robHeadMissInDCache |= ~g_io_debugTopDown_robHeadMissInDCache;
    if (!cmp_all && !armed_io_cmoOpReq_ready && g_io_cmoOpReq_ready === i_io_cmoOpReq_ready) armed_io_cmoOpReq_ready = 1;
    if ((cmp_all | armed_io_cmoOpReq_ready) && g_io_cmoOpReq_ready !== i_io_cmoOpReq_ready) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_cmoOpReq_ready: g=%h i=%h", cyc, g_io_cmoOpReq_ready, i_io_cmoOpReq_ready);
    end
    seen1_io_cmoOpReq_ready |= g_io_cmoOpReq_ready;
    seen0_io_cmoOpReq_ready |= ~g_io_cmoOpReq_ready;
    if (!cmp_all && !armed_io_cmoOpResp_valid && g_io_cmoOpResp_valid === i_io_cmoOpResp_valid) armed_io_cmoOpResp_valid = 1;
    if ((cmp_all | armed_io_cmoOpResp_valid) && g_io_cmoOpResp_valid !== i_io_cmoOpResp_valid) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_cmoOpResp_valid: g=%h i=%h", cyc, g_io_cmoOpResp_valid, i_io_cmoOpResp_valid);
    end
    seen1_io_cmoOpResp_valid |= g_io_cmoOpResp_valid;
    seen0_io_cmoOpResp_valid |= ~g_io_cmoOpResp_valid;
    if (!cmp_all && !armed_io_cmoOpResp_bits_denied && g_io_cmoOpResp_bits_denied === i_io_cmoOpResp_bits_denied) armed_io_cmoOpResp_bits_denied = 1;
    if ((cmp_all | armed_io_cmoOpResp_bits_denied) && (cmp_all | g_io_cmoOpResp_valid) && (g_io_cmoOpResp_bits_denied !== i_io_cmoOpResp_bits_denied)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_cmoOpResp_bits_denied: g=%h i=%h", cyc, g_io_cmoOpResp_bits_denied, i_io_cmoOpResp_bits_denied);
    end
    seen1_io_cmoOpResp_bits_denied |= g_io_cmoOpResp_bits_denied;
    seen0_io_cmoOpResp_bits_denied |= ~g_io_cmoOpResp_bits_denied;
    if (!cmp_all && !armed_io_cmoOpResp_bits_corrupt && g_io_cmoOpResp_bits_corrupt === i_io_cmoOpResp_bits_corrupt) armed_io_cmoOpResp_bits_corrupt = 1;
    if ((cmp_all | armed_io_cmoOpResp_bits_corrupt) && (cmp_all | g_io_cmoOpResp_valid) && (g_io_cmoOpResp_bits_corrupt !== i_io_cmoOpResp_bits_corrupt)) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_cmoOpResp_bits_corrupt: g=%h i=%h", cyc, g_io_cmoOpResp_bits_corrupt, i_io_cmoOpResp_bits_corrupt);
    end
    seen1_io_cmoOpResp_bits_corrupt |= g_io_cmoOpResp_bits_corrupt;
    seen0_io_cmoOpResp_bits_corrupt |= ~g_io_cmoOpResp_bits_corrupt;
    if (!cmp_all && !armed_io_l1Miss && g_io_l1Miss === i_io_l1Miss) armed_io_l1Miss = 1;
    if ((cmp_all | armed_io_l1Miss) && g_io_l1Miss !== i_io_l1Miss) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_l1Miss: g=%h i=%h", cyc, g_io_l1Miss, i_io_l1Miss);
    end
    seen1_io_l1Miss |= g_io_l1Miss;
    seen0_io_l1Miss |= ~g_io_l1Miss;
    if (!cmp_all && !armed_io_wfi_wfiSafe && g_io_wfi_wfiSafe === i_io_wfi_wfiSafe) armed_io_wfi_wfiSafe = 1;
    if ((cmp_all | armed_io_wfi_wfiSafe) && g_io_wfi_wfiSafe !== i_io_wfi_wfiSafe) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_wfi_wfiSafe: g=%h i=%h", cyc, g_io_wfi_wfiSafe, i_io_wfi_wfiSafe);
    end
    seen1_io_wfi_wfiSafe |= g_io_wfi_wfiSafe;
    seen0_io_wfi_wfiSafe |= ~g_io_wfi_wfiSafe;
    if (!cmp_all && !armed_io_perf_0_value && g_io_perf_0_value === i_io_perf_0_value) armed_io_perf_0_value = 1;
    if ((cmp_all | armed_io_perf_0_value) && g_io_perf_0_value !== i_io_perf_0_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_0_value: g=%h i=%h", cyc, g_io_perf_0_value, i_io_perf_0_value);
    end
    seen1_io_perf_0_value |= g_io_perf_0_value;
    seen0_io_perf_0_value |= ~g_io_perf_0_value;
    if (!cmp_all && !armed_io_perf_1_value && g_io_perf_1_value === i_io_perf_1_value) armed_io_perf_1_value = 1;
    if ((cmp_all | armed_io_perf_1_value) && g_io_perf_1_value !== i_io_perf_1_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_1_value: g=%h i=%h", cyc, g_io_perf_1_value, i_io_perf_1_value);
    end
    seen1_io_perf_1_value |= g_io_perf_1_value;
    seen0_io_perf_1_value |= ~g_io_perf_1_value;
    if (!cmp_all && !armed_io_perf_2_value && g_io_perf_2_value === i_io_perf_2_value) armed_io_perf_2_value = 1;
    if ((cmp_all | armed_io_perf_2_value) && g_io_perf_2_value !== i_io_perf_2_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_2_value: g=%h i=%h", cyc, g_io_perf_2_value, i_io_perf_2_value);
    end
    seen1_io_perf_2_value |= g_io_perf_2_value;
    seen0_io_perf_2_value |= ~g_io_perf_2_value;
    if (!cmp_all && !armed_io_perf_3_value && g_io_perf_3_value === i_io_perf_3_value) armed_io_perf_3_value = 1;
    if ((cmp_all | armed_io_perf_3_value) && g_io_perf_3_value !== i_io_perf_3_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_3_value: g=%h i=%h", cyc, g_io_perf_3_value, i_io_perf_3_value);
    end
    seen1_io_perf_3_value |= g_io_perf_3_value;
    seen0_io_perf_3_value |= ~g_io_perf_3_value;
    if (!cmp_all && !armed_io_perf_4_value && g_io_perf_4_value === i_io_perf_4_value) armed_io_perf_4_value = 1;
    if ((cmp_all | armed_io_perf_4_value) && g_io_perf_4_value !== i_io_perf_4_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_4_value: g=%h i=%h", cyc, g_io_perf_4_value, i_io_perf_4_value);
    end
    seen1_io_perf_4_value |= g_io_perf_4_value;
    seen0_io_perf_4_value |= ~g_io_perf_4_value;
    if (!cmp_all && !armed_io_perf_5_value && g_io_perf_5_value === i_io_perf_5_value) armed_io_perf_5_value = 1;
    if ((cmp_all | armed_io_perf_5_value) && g_io_perf_5_value !== i_io_perf_5_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_5_value: g=%h i=%h", cyc, g_io_perf_5_value, i_io_perf_5_value);
    end
    seen1_io_perf_5_value |= g_io_perf_5_value;
    seen0_io_perf_5_value |= ~g_io_perf_5_value;
    if (!cmp_all && !armed_io_perf_6_value && g_io_perf_6_value === i_io_perf_6_value) armed_io_perf_6_value = 1;
    if ((cmp_all | armed_io_perf_6_value) && g_io_perf_6_value !== i_io_perf_6_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_6_value: g=%h i=%h", cyc, g_io_perf_6_value, i_io_perf_6_value);
    end
    seen1_io_perf_6_value |= g_io_perf_6_value;
    seen0_io_perf_6_value |= ~g_io_perf_6_value;
    if (!cmp_all && !armed_io_perf_7_value && g_io_perf_7_value === i_io_perf_7_value) armed_io_perf_7_value = 1;
    if ((cmp_all | armed_io_perf_7_value) && g_io_perf_7_value !== i_io_perf_7_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_7_value: g=%h i=%h", cyc, g_io_perf_7_value, i_io_perf_7_value);
    end
    seen1_io_perf_7_value |= g_io_perf_7_value;
    seen0_io_perf_7_value |= ~g_io_perf_7_value;
    if (!cmp_all && !armed_io_perf_8_value && g_io_perf_8_value === i_io_perf_8_value) armed_io_perf_8_value = 1;
    if ((cmp_all | armed_io_perf_8_value) && g_io_perf_8_value !== i_io_perf_8_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_8_value: g=%h i=%h", cyc, g_io_perf_8_value, i_io_perf_8_value);
    end
    seen1_io_perf_8_value |= g_io_perf_8_value;
    seen0_io_perf_8_value |= ~g_io_perf_8_value;
    if (!cmp_all && !armed_io_perf_9_value && g_io_perf_9_value === i_io_perf_9_value) armed_io_perf_9_value = 1;
    if ((cmp_all | armed_io_perf_9_value) && g_io_perf_9_value !== i_io_perf_9_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_9_value: g=%h i=%h", cyc, g_io_perf_9_value, i_io_perf_9_value);
    end
    seen1_io_perf_9_value |= g_io_perf_9_value;
    seen0_io_perf_9_value |= ~g_io_perf_9_value;
    if (!cmp_all && !armed_io_perf_10_value && g_io_perf_10_value === i_io_perf_10_value) armed_io_perf_10_value = 1;
    if ((cmp_all | armed_io_perf_10_value) && g_io_perf_10_value !== i_io_perf_10_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_10_value: g=%h i=%h", cyc, g_io_perf_10_value, i_io_perf_10_value);
    end
    seen1_io_perf_10_value |= g_io_perf_10_value;
    seen0_io_perf_10_value |= ~g_io_perf_10_value;
    if (!cmp_all && !armed_io_perf_11_value && g_io_perf_11_value === i_io_perf_11_value) armed_io_perf_11_value = 1;
    if ((cmp_all | armed_io_perf_11_value) && g_io_perf_11_value !== i_io_perf_11_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_11_value: g=%h i=%h", cyc, g_io_perf_11_value, i_io_perf_11_value);
    end
    seen1_io_perf_11_value |= g_io_perf_11_value;
    seen0_io_perf_11_value |= ~g_io_perf_11_value;
    if (!cmp_all && !armed_io_perf_12_value && g_io_perf_12_value === i_io_perf_12_value) armed_io_perf_12_value = 1;
    if ((cmp_all | armed_io_perf_12_value) && g_io_perf_12_value !== i_io_perf_12_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_12_value: g=%h i=%h", cyc, g_io_perf_12_value, i_io_perf_12_value);
    end
    seen1_io_perf_12_value |= g_io_perf_12_value;
    seen0_io_perf_12_value |= ~g_io_perf_12_value;
    if (!cmp_all && !armed_io_perf_13_value && g_io_perf_13_value === i_io_perf_13_value) armed_io_perf_13_value = 1;
    if ((cmp_all | armed_io_perf_13_value) && g_io_perf_13_value !== i_io_perf_13_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_13_value: g=%h i=%h", cyc, g_io_perf_13_value, i_io_perf_13_value);
    end
    seen1_io_perf_13_value |= g_io_perf_13_value;
    seen0_io_perf_13_value |= ~g_io_perf_13_value;
    if (!cmp_all && !armed_io_perf_14_value && g_io_perf_14_value === i_io_perf_14_value) armed_io_perf_14_value = 1;
    if ((cmp_all | armed_io_perf_14_value) && g_io_perf_14_value !== i_io_perf_14_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_14_value: g=%h i=%h", cyc, g_io_perf_14_value, i_io_perf_14_value);
    end
    seen1_io_perf_14_value |= g_io_perf_14_value;
    seen0_io_perf_14_value |= ~g_io_perf_14_value;
    if (!cmp_all && !armed_io_perf_15_value && g_io_perf_15_value === i_io_perf_15_value) armed_io_perf_15_value = 1;
    if ((cmp_all | armed_io_perf_15_value) && g_io_perf_15_value !== i_io_perf_15_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_15_value: g=%h i=%h", cyc, g_io_perf_15_value, i_io_perf_15_value);
    end
    seen1_io_perf_15_value |= g_io_perf_15_value;
    seen0_io_perf_15_value |= ~g_io_perf_15_value;
    if (!cmp_all && !armed_io_perf_16_value && g_io_perf_16_value === i_io_perf_16_value) armed_io_perf_16_value = 1;
    if ((cmp_all | armed_io_perf_16_value) && g_io_perf_16_value !== i_io_perf_16_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_16_value: g=%h i=%h", cyc, g_io_perf_16_value, i_io_perf_16_value);
    end
    seen1_io_perf_16_value |= g_io_perf_16_value;
    seen0_io_perf_16_value |= ~g_io_perf_16_value;
    if (!cmp_all && !armed_io_perf_17_value && g_io_perf_17_value === i_io_perf_17_value) armed_io_perf_17_value = 1;
    if ((cmp_all | armed_io_perf_17_value) && g_io_perf_17_value !== i_io_perf_17_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_17_value: g=%h i=%h", cyc, g_io_perf_17_value, i_io_perf_17_value);
    end
    seen1_io_perf_17_value |= g_io_perf_17_value;
    seen0_io_perf_17_value |= ~g_io_perf_17_value;
    if (!cmp_all && !armed_io_perf_18_value && g_io_perf_18_value === i_io_perf_18_value) armed_io_perf_18_value = 1;
    if ((cmp_all | armed_io_perf_18_value) && g_io_perf_18_value !== i_io_perf_18_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_18_value: g=%h i=%h", cyc, g_io_perf_18_value, i_io_perf_18_value);
    end
    seen1_io_perf_18_value |= g_io_perf_18_value;
    seen0_io_perf_18_value |= ~g_io_perf_18_value;
    if (!cmp_all && !armed_io_perf_19_value && g_io_perf_19_value === i_io_perf_19_value) armed_io_perf_19_value = 1;
    if ((cmp_all | armed_io_perf_19_value) && g_io_perf_19_value !== i_io_perf_19_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_19_value: g=%h i=%h", cyc, g_io_perf_19_value, i_io_perf_19_value);
    end
    seen1_io_perf_19_value |= g_io_perf_19_value;
    seen0_io_perf_19_value |= ~g_io_perf_19_value;
    if (!cmp_all && !armed_io_perf_20_value && g_io_perf_20_value === i_io_perf_20_value) armed_io_perf_20_value = 1;
    if ((cmp_all | armed_io_perf_20_value) && g_io_perf_20_value !== i_io_perf_20_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_20_value: g=%h i=%h", cyc, g_io_perf_20_value, i_io_perf_20_value);
    end
    seen1_io_perf_20_value |= g_io_perf_20_value;
    seen0_io_perf_20_value |= ~g_io_perf_20_value;
    if (!cmp_all && !armed_io_perf_21_value && g_io_perf_21_value === i_io_perf_21_value) armed_io_perf_21_value = 1;
    if ((cmp_all | armed_io_perf_21_value) && g_io_perf_21_value !== i_io_perf_21_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_21_value: g=%h i=%h", cyc, g_io_perf_21_value, i_io_perf_21_value);
    end
    seen1_io_perf_21_value |= g_io_perf_21_value;
    seen0_io_perf_21_value |= ~g_io_perf_21_value;
    if (!cmp_all && !armed_io_perf_22_value && g_io_perf_22_value === i_io_perf_22_value) armed_io_perf_22_value = 1;
    if ((cmp_all | armed_io_perf_22_value) && g_io_perf_22_value !== i_io_perf_22_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_22_value: g=%h i=%h", cyc, g_io_perf_22_value, i_io_perf_22_value);
    end
    seen1_io_perf_22_value |= g_io_perf_22_value;
    seen0_io_perf_22_value |= ~g_io_perf_22_value;
    if (!cmp_all && !armed_io_perf_23_value && g_io_perf_23_value === i_io_perf_23_value) armed_io_perf_23_value = 1;
    if ((cmp_all | armed_io_perf_23_value) && g_io_perf_23_value !== i_io_perf_23_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_23_value: g=%h i=%h", cyc, g_io_perf_23_value, i_io_perf_23_value);
    end
    seen1_io_perf_23_value |= g_io_perf_23_value;
    seen0_io_perf_23_value |= ~g_io_perf_23_value;
    if (!cmp_all && !armed_io_perf_24_value && g_io_perf_24_value === i_io_perf_24_value) armed_io_perf_24_value = 1;
    if ((cmp_all | armed_io_perf_24_value) && g_io_perf_24_value !== i_io_perf_24_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_24_value: g=%h i=%h", cyc, g_io_perf_24_value, i_io_perf_24_value);
    end
    seen1_io_perf_24_value |= g_io_perf_24_value;
    seen0_io_perf_24_value |= ~g_io_perf_24_value;
    if (!cmp_all && !armed_io_perf_25_value && g_io_perf_25_value === i_io_perf_25_value) armed_io_perf_25_value = 1;
    if ((cmp_all | armed_io_perf_25_value) && g_io_perf_25_value !== i_io_perf_25_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_25_value: g=%h i=%h", cyc, g_io_perf_25_value, i_io_perf_25_value);
    end
    seen1_io_perf_25_value |= g_io_perf_25_value;
    seen0_io_perf_25_value |= ~g_io_perf_25_value;
    if (!cmp_all && !armed_io_perf_26_value && g_io_perf_26_value === i_io_perf_26_value) armed_io_perf_26_value = 1;
    if ((cmp_all | armed_io_perf_26_value) && g_io_perf_26_value !== i_io_perf_26_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_26_value: g=%h i=%h", cyc, g_io_perf_26_value, i_io_perf_26_value);
    end
    seen1_io_perf_26_value |= g_io_perf_26_value;
    seen0_io_perf_26_value |= ~g_io_perf_26_value;
    if (!cmp_all && !armed_io_perf_27_value && g_io_perf_27_value === i_io_perf_27_value) armed_io_perf_27_value = 1;
    if ((cmp_all | armed_io_perf_27_value) && g_io_perf_27_value !== i_io_perf_27_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_27_value: g=%h i=%h", cyc, g_io_perf_27_value, i_io_perf_27_value);
    end
    seen1_io_perf_27_value |= g_io_perf_27_value;
    seen0_io_perf_27_value |= ~g_io_perf_27_value;
    if (!cmp_all && !armed_io_perf_28_value && g_io_perf_28_value === i_io_perf_28_value) armed_io_perf_28_value = 1;
    if ((cmp_all | armed_io_perf_28_value) && g_io_perf_28_value !== i_io_perf_28_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_28_value: g=%h i=%h", cyc, g_io_perf_28_value, i_io_perf_28_value);
    end
    seen1_io_perf_28_value |= g_io_perf_28_value;
    seen0_io_perf_28_value |= ~g_io_perf_28_value;
    if (!cmp_all && !armed_io_perf_29_value && g_io_perf_29_value === i_io_perf_29_value) armed_io_perf_29_value = 1;
    if ((cmp_all | armed_io_perf_29_value) && g_io_perf_29_value !== i_io_perf_29_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_29_value: g=%h i=%h", cyc, g_io_perf_29_value, i_io_perf_29_value);
    end
    seen1_io_perf_29_value |= g_io_perf_29_value;
    seen0_io_perf_29_value |= ~g_io_perf_29_value;
    if (!cmp_all && !armed_io_perf_30_value && g_io_perf_30_value === i_io_perf_30_value) armed_io_perf_30_value = 1;
    if ((cmp_all | armed_io_perf_30_value) && g_io_perf_30_value !== i_io_perf_30_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_30_value: g=%h i=%h", cyc, g_io_perf_30_value, i_io_perf_30_value);
    end
    seen1_io_perf_30_value |= g_io_perf_30_value;
    seen0_io_perf_30_value |= ~g_io_perf_30_value;
    if (!cmp_all && !armed_io_perf_31_value && g_io_perf_31_value === i_io_perf_31_value) armed_io_perf_31_value = 1;
    if ((cmp_all | armed_io_perf_31_value) && g_io_perf_31_value !== i_io_perf_31_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_31_value: g=%h i=%h", cyc, g_io_perf_31_value, i_io_perf_31_value);
    end
    seen1_io_perf_31_value |= g_io_perf_31_value;
    seen0_io_perf_31_value |= ~g_io_perf_31_value;
    if (!cmp_all && !armed_io_perf_32_value && g_io_perf_32_value === i_io_perf_32_value) armed_io_perf_32_value = 1;
    if ((cmp_all | armed_io_perf_32_value) && g_io_perf_32_value !== i_io_perf_32_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_32_value: g=%h i=%h", cyc, g_io_perf_32_value, i_io_perf_32_value);
    end
    seen1_io_perf_32_value |= g_io_perf_32_value;
    seen0_io_perf_32_value |= ~g_io_perf_32_value;
    if (!cmp_all && !armed_io_perf_33_value && g_io_perf_33_value === i_io_perf_33_value) armed_io_perf_33_value = 1;
    if ((cmp_all | armed_io_perf_33_value) && g_io_perf_33_value !== i_io_perf_33_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_33_value: g=%h i=%h", cyc, g_io_perf_33_value, i_io_perf_33_value);
    end
    seen1_io_perf_33_value |= g_io_perf_33_value;
    seen0_io_perf_33_value |= ~g_io_perf_33_value;
    if (!cmp_all && !armed_io_perf_34_value && g_io_perf_34_value === i_io_perf_34_value) armed_io_perf_34_value = 1;
    if ((cmp_all | armed_io_perf_34_value) && g_io_perf_34_value !== i_io_perf_34_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_34_value: g=%h i=%h", cyc, g_io_perf_34_value, i_io_perf_34_value);
    end
    seen1_io_perf_34_value |= g_io_perf_34_value;
    seen0_io_perf_34_value |= ~g_io_perf_34_value;
    if (!cmp_all && !armed_io_perf_35_value && g_io_perf_35_value === i_io_perf_35_value) armed_io_perf_35_value = 1;
    if ((cmp_all | armed_io_perf_35_value) && g_io_perf_35_value !== i_io_perf_35_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_35_value: g=%h i=%h", cyc, g_io_perf_35_value, i_io_perf_35_value);
    end
    seen1_io_perf_35_value |= g_io_perf_35_value;
    seen0_io_perf_35_value |= ~g_io_perf_35_value;
    if (!cmp_all && !armed_io_perf_36_value && g_io_perf_36_value === i_io_perf_36_value) armed_io_perf_36_value = 1;
    if ((cmp_all | armed_io_perf_36_value) && g_io_perf_36_value !== i_io_perf_36_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_36_value: g=%h i=%h", cyc, g_io_perf_36_value, i_io_perf_36_value);
    end
    seen1_io_perf_36_value |= g_io_perf_36_value;
    seen0_io_perf_36_value |= ~g_io_perf_36_value;
    if (!cmp_all && !armed_io_perf_37_value && g_io_perf_37_value === i_io_perf_37_value) armed_io_perf_37_value = 1;
    if ((cmp_all | armed_io_perf_37_value) && g_io_perf_37_value !== i_io_perf_37_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_37_value: g=%h i=%h", cyc, g_io_perf_37_value, i_io_perf_37_value);
    end
    seen1_io_perf_37_value |= g_io_perf_37_value;
    seen0_io_perf_37_value |= ~g_io_perf_37_value;
    if (!cmp_all && !armed_io_perf_38_value && g_io_perf_38_value === i_io_perf_38_value) armed_io_perf_38_value = 1;
    if ((cmp_all | armed_io_perf_38_value) && g_io_perf_38_value !== i_io_perf_38_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_38_value: g=%h i=%h", cyc, g_io_perf_38_value, i_io_perf_38_value);
    end
    seen1_io_perf_38_value |= g_io_perf_38_value;
    seen0_io_perf_38_value |= ~g_io_perf_38_value;
    if (!cmp_all && !armed_io_perf_39_value && g_io_perf_39_value === i_io_perf_39_value) armed_io_perf_39_value = 1;
    if ((cmp_all | armed_io_perf_39_value) && g_io_perf_39_value !== i_io_perf_39_value) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d io_perf_39_value: g=%h i=%h", cyc, g_io_perf_39_value, i_io_perf_39_value);
    end
    seen1_io_perf_39_value |= g_io_perf_39_value;
    seen0_io_perf_39_value |= ~g_io_perf_39_value;
    if (!cmp_all && !armed_boreChildrenBd_bore_ack && g_boreChildrenBd_bore_ack === i_boreChildrenBd_bore_ack) armed_boreChildrenBd_bore_ack = 1;
    if ((cmp_all | armed_boreChildrenBd_bore_ack) && g_boreChildrenBd_bore_ack !== i_boreChildrenBd_bore_ack) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d boreChildrenBd_bore_ack: g=%h i=%h", cyc, g_boreChildrenBd_bore_ack, i_boreChildrenBd_bore_ack);
    end
    seen1_boreChildrenBd_bore_ack |= g_boreChildrenBd_bore_ack;
    seen0_boreChildrenBd_bore_ack |= ~g_boreChildrenBd_bore_ack;
    if (!cmp_all && !armed_boreChildrenBd_bore_outdata && g_boreChildrenBd_bore_outdata === i_boreChildrenBd_bore_outdata) armed_boreChildrenBd_bore_outdata = 1;
    if ((cmp_all | armed_boreChildrenBd_bore_outdata) && g_boreChildrenBd_bore_outdata !== i_boreChildrenBd_bore_outdata) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d boreChildrenBd_bore_outdata: g=%h i=%h", cyc, g_boreChildrenBd_bore_outdata, i_boreChildrenBd_bore_outdata);
    end
    seen1_boreChildrenBd_bore_outdata |= g_boreChildrenBd_bore_outdata;
    seen0_boreChildrenBd_bore_outdata |= ~g_boreChildrenBd_bore_outdata;
    if (!cmp_all && !armed_boreChildrenBd_bore_1_ack && g_boreChildrenBd_bore_1_ack === i_boreChildrenBd_bore_1_ack) armed_boreChildrenBd_bore_1_ack = 1;
    if ((cmp_all | armed_boreChildrenBd_bore_1_ack) && g_boreChildrenBd_bore_1_ack !== i_boreChildrenBd_bore_1_ack) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d boreChildrenBd_bore_1_ack: g=%h i=%h", cyc, g_boreChildrenBd_bore_1_ack, i_boreChildrenBd_bore_1_ack);
    end
    seen1_boreChildrenBd_bore_1_ack |= g_boreChildrenBd_bore_1_ack;
    seen0_boreChildrenBd_bore_1_ack |= ~g_boreChildrenBd_bore_1_ack;
    if (!cmp_all && !armed_boreChildrenBd_bore_1_outdata && g_boreChildrenBd_bore_1_outdata === i_boreChildrenBd_bore_1_outdata) armed_boreChildrenBd_bore_1_outdata = 1;
    if ((cmp_all | armed_boreChildrenBd_bore_1_outdata) && g_boreChildrenBd_bore_1_outdata !== i_boreChildrenBd_bore_1_outdata) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d boreChildrenBd_bore_1_outdata: g=%h i=%h", cyc, g_boreChildrenBd_bore_1_outdata, i_boreChildrenBd_bore_1_outdata);
    end
    seen1_boreChildrenBd_bore_1_outdata |= g_boreChildrenBd_bore_1_outdata;
    seen0_boreChildrenBd_bore_1_outdata |= ~g_boreChildrenBd_bore_1_outdata;
    if (!cmp_all && !armed_gatewayIn_packed_41_bore && g_gatewayIn_packed_41_bore === i_gatewayIn_packed_41_bore) armed_gatewayIn_packed_41_bore = 1;
    if ((cmp_all | armed_gatewayIn_packed_41_bore) && g_gatewayIn_packed_41_bore !== i_gatewayIn_packed_41_bore) begin
      errors++;
      if (errors <= 30) $display("MISMATCH cyc=%0d gatewayIn_packed_41_bore: g=%h i=%h", cyc, g_gatewayIn_packed_41_bore, i_gatewayIn_packed_41_bore);
    end
    seen1_gatewayIn_packed_41_bore |= g_gatewayIn_packed_41_bore;
    seen0_gatewayIn_packed_41_bore |= ~g_gatewayIn_packed_41_bore;
    checks++;
  endtask
  // 从未翻转过的输出位个数（逐端口打印前 60 个）
  function automatic int report_toggle();
    int bad = 0;
    int ports = 0;
    if ((~seen1_auto_cacheCtrlOpt_in_a_ready | ~seen0_auto_cacheCtrlOpt_in_a_ready) != '0) begin ports++; bad += $countones(~seen1_auto_cacheCtrlOpt_in_a_ready | ~seen0_auto_cacheCtrlOpt_in_a_ready); if (ports <= 60) $display("TOGGLE MISS auto_cacheCtrlOpt_in_a_ready 1=%h 0=%h", seen1_auto_cacheCtrlOpt_in_a_ready, seen0_auto_cacheCtrlOpt_in_a_ready); end
    if ((~seen1_auto_cacheCtrlOpt_in_d_valid | ~seen0_auto_cacheCtrlOpt_in_d_valid) != '0) begin ports++; bad += $countones(~seen1_auto_cacheCtrlOpt_in_d_valid | ~seen0_auto_cacheCtrlOpt_in_d_valid); if (ports <= 60) $display("TOGGLE MISS auto_cacheCtrlOpt_in_d_valid 1=%h 0=%h", seen1_auto_cacheCtrlOpt_in_d_valid, seen0_auto_cacheCtrlOpt_in_d_valid); end
    if ((~seen1_auto_cacheCtrlOpt_in_d_bits_opcode | ~seen0_auto_cacheCtrlOpt_in_d_bits_opcode) != '0) begin ports++; bad += $countones(~seen1_auto_cacheCtrlOpt_in_d_bits_opcode | ~seen0_auto_cacheCtrlOpt_in_d_bits_opcode); if (ports <= 60) $display("TOGGLE MISS auto_cacheCtrlOpt_in_d_bits_opcode 1=%h 0=%h", seen1_auto_cacheCtrlOpt_in_d_bits_opcode, seen0_auto_cacheCtrlOpt_in_d_bits_opcode); end
    if ((~seen1_auto_cacheCtrlOpt_in_d_bits_size | ~seen0_auto_cacheCtrlOpt_in_d_bits_size) != '0) begin ports++; bad += $countones(~seen1_auto_cacheCtrlOpt_in_d_bits_size | ~seen0_auto_cacheCtrlOpt_in_d_bits_size); if (ports <= 60) $display("TOGGLE MISS auto_cacheCtrlOpt_in_d_bits_size 1=%h 0=%h", seen1_auto_cacheCtrlOpt_in_d_bits_size, seen0_auto_cacheCtrlOpt_in_d_bits_size); end
    if ((~seen1_auto_cacheCtrlOpt_in_d_bits_source | ~seen0_auto_cacheCtrlOpt_in_d_bits_source) != '0) begin ports++; bad += $countones(~seen1_auto_cacheCtrlOpt_in_d_bits_source | ~seen0_auto_cacheCtrlOpt_in_d_bits_source); if (ports <= 60) $display("TOGGLE MISS auto_cacheCtrlOpt_in_d_bits_source 1=%h 0=%h", seen1_auto_cacheCtrlOpt_in_d_bits_source, seen0_auto_cacheCtrlOpt_in_d_bits_source); end
    if ((~seen1_auto_cacheCtrlOpt_in_d_bits_data | ~seen0_auto_cacheCtrlOpt_in_d_bits_data) != '0) begin ports++; bad += $countones(~seen1_auto_cacheCtrlOpt_in_d_bits_data | ~seen0_auto_cacheCtrlOpt_in_d_bits_data); if (ports <= 60) $display("TOGGLE MISS auto_cacheCtrlOpt_in_d_bits_data 1=%h 0=%h", seen1_auto_cacheCtrlOpt_in_d_bits_data, seen0_auto_cacheCtrlOpt_in_d_bits_data); end
    if ((~seen1_auto_client_out_a_valid | ~seen0_auto_client_out_a_valid) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_a_valid | ~seen0_auto_client_out_a_valid); if (ports <= 60) $display("TOGGLE MISS auto_client_out_a_valid 1=%h 0=%h", seen1_auto_client_out_a_valid, seen0_auto_client_out_a_valid); end
    if ((~seen1_auto_client_out_a_bits_opcode | ~seen0_auto_client_out_a_bits_opcode) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_a_bits_opcode | ~seen0_auto_client_out_a_bits_opcode); if (ports <= 60) $display("TOGGLE MISS auto_client_out_a_bits_opcode 1=%h 0=%h", seen1_auto_client_out_a_bits_opcode, seen0_auto_client_out_a_bits_opcode); end
    if ((~seen1_auto_client_out_a_bits_param | ~seen0_auto_client_out_a_bits_param) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_a_bits_param | ~seen0_auto_client_out_a_bits_param); if (ports <= 60) $display("TOGGLE MISS auto_client_out_a_bits_param 1=%h 0=%h", seen1_auto_client_out_a_bits_param, seen0_auto_client_out_a_bits_param); end
    if ((~seen1_auto_client_out_a_bits_size | ~seen0_auto_client_out_a_bits_size) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_a_bits_size | ~seen0_auto_client_out_a_bits_size); if (ports <= 60) $display("TOGGLE MISS auto_client_out_a_bits_size 1=%h 0=%h", seen1_auto_client_out_a_bits_size, seen0_auto_client_out_a_bits_size); end
    if ((~seen1_auto_client_out_a_bits_source | ~seen0_auto_client_out_a_bits_source) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_a_bits_source | ~seen0_auto_client_out_a_bits_source); if (ports <= 60) $display("TOGGLE MISS auto_client_out_a_bits_source 1=%h 0=%h", seen1_auto_client_out_a_bits_source, seen0_auto_client_out_a_bits_source); end
    if ((~seen1_auto_client_out_a_bits_address | ~seen0_auto_client_out_a_bits_address) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_a_bits_address | ~seen0_auto_client_out_a_bits_address); if (ports <= 60) $display("TOGGLE MISS auto_client_out_a_bits_address 1=%h 0=%h", seen1_auto_client_out_a_bits_address, seen0_auto_client_out_a_bits_address); end
    if ((~seen1_auto_client_out_a_bits_user_alias | ~seen0_auto_client_out_a_bits_user_alias) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_a_bits_user_alias | ~seen0_auto_client_out_a_bits_user_alias); if (ports <= 60) $display("TOGGLE MISS auto_client_out_a_bits_user_alias 1=%h 0=%h", seen1_auto_client_out_a_bits_user_alias, seen0_auto_client_out_a_bits_user_alias); end
    if ((~seen1_auto_client_out_a_bits_user_vaddr | ~seen0_auto_client_out_a_bits_user_vaddr) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_a_bits_user_vaddr | ~seen0_auto_client_out_a_bits_user_vaddr); if (ports <= 60) $display("TOGGLE MISS auto_client_out_a_bits_user_vaddr 1=%h 0=%h", seen1_auto_client_out_a_bits_user_vaddr, seen0_auto_client_out_a_bits_user_vaddr); end
    if ((~seen1_auto_client_out_a_bits_user_reqSource | ~seen0_auto_client_out_a_bits_user_reqSource) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_a_bits_user_reqSource | ~seen0_auto_client_out_a_bits_user_reqSource); if (ports <= 60) $display("TOGGLE MISS auto_client_out_a_bits_user_reqSource 1=%h 0=%h", seen1_auto_client_out_a_bits_user_reqSource, seen0_auto_client_out_a_bits_user_reqSource); end
    if ((~seen1_auto_client_out_a_bits_user_needHint | ~seen0_auto_client_out_a_bits_user_needHint) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_a_bits_user_needHint | ~seen0_auto_client_out_a_bits_user_needHint); if (ports <= 60) $display("TOGGLE MISS auto_client_out_a_bits_user_needHint 1=%h 0=%h", seen1_auto_client_out_a_bits_user_needHint, seen0_auto_client_out_a_bits_user_needHint); end
    if ((~seen1_auto_client_out_a_bits_echo_isKeyword | ~seen0_auto_client_out_a_bits_echo_isKeyword) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_a_bits_echo_isKeyword | ~seen0_auto_client_out_a_bits_echo_isKeyword); if (ports <= 60) $display("TOGGLE MISS auto_client_out_a_bits_echo_isKeyword 1=%h 0=%h", seen1_auto_client_out_a_bits_echo_isKeyword, seen0_auto_client_out_a_bits_echo_isKeyword); end
    if ((~seen1_auto_client_out_a_bits_mask | ~seen0_auto_client_out_a_bits_mask) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_a_bits_mask | ~seen0_auto_client_out_a_bits_mask); if (ports <= 60) $display("TOGGLE MISS auto_client_out_a_bits_mask 1=%h 0=%h", seen1_auto_client_out_a_bits_mask, seen0_auto_client_out_a_bits_mask); end
    if ((~seen1_auto_client_out_b_ready | ~seen0_auto_client_out_b_ready) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_b_ready | ~seen0_auto_client_out_b_ready); if (ports <= 60) $display("TOGGLE MISS auto_client_out_b_ready 1=%h 0=%h", seen1_auto_client_out_b_ready, seen0_auto_client_out_b_ready); end
    if ((~seen1_auto_client_out_c_valid | ~seen0_auto_client_out_c_valid) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_c_valid | ~seen0_auto_client_out_c_valid); if (ports <= 60) $display("TOGGLE MISS auto_client_out_c_valid 1=%h 0=%h", seen1_auto_client_out_c_valid, seen0_auto_client_out_c_valid); end
    if ((~seen1_auto_client_out_c_bits_opcode | ~seen0_auto_client_out_c_bits_opcode) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_c_bits_opcode | ~seen0_auto_client_out_c_bits_opcode); if (ports <= 60) $display("TOGGLE MISS auto_client_out_c_bits_opcode 1=%h 0=%h", seen1_auto_client_out_c_bits_opcode, seen0_auto_client_out_c_bits_opcode); end
    if ((~seen1_auto_client_out_c_bits_param | ~seen0_auto_client_out_c_bits_param) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_c_bits_param | ~seen0_auto_client_out_c_bits_param); if (ports <= 60) $display("TOGGLE MISS auto_client_out_c_bits_param 1=%h 0=%h", seen1_auto_client_out_c_bits_param, seen0_auto_client_out_c_bits_param); end
    if ((~seen1_auto_client_out_c_bits_size | ~seen0_auto_client_out_c_bits_size) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_c_bits_size | ~seen0_auto_client_out_c_bits_size); if (ports <= 60) $display("TOGGLE MISS auto_client_out_c_bits_size 1=%h 0=%h", seen1_auto_client_out_c_bits_size, seen0_auto_client_out_c_bits_size); end
    if ((~seen1_auto_client_out_c_bits_source | ~seen0_auto_client_out_c_bits_source) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_c_bits_source | ~seen0_auto_client_out_c_bits_source); if (ports <= 60) $display("TOGGLE MISS auto_client_out_c_bits_source 1=%h 0=%h", seen1_auto_client_out_c_bits_source, seen0_auto_client_out_c_bits_source); end
    if ((~seen1_auto_client_out_c_bits_address | ~seen0_auto_client_out_c_bits_address) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_c_bits_address | ~seen0_auto_client_out_c_bits_address); if (ports <= 60) $display("TOGGLE MISS auto_client_out_c_bits_address 1=%h 0=%h", seen1_auto_client_out_c_bits_address, seen0_auto_client_out_c_bits_address); end
    if ((~seen1_auto_client_out_c_bits_data | ~seen0_auto_client_out_c_bits_data) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_c_bits_data | ~seen0_auto_client_out_c_bits_data); if (ports <= 60) $display("TOGGLE MISS auto_client_out_c_bits_data 1=%h 0=%h", seen1_auto_client_out_c_bits_data, seen0_auto_client_out_c_bits_data); end
    if ((~seen1_auto_client_out_c_bits_corrupt | ~seen0_auto_client_out_c_bits_corrupt) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_c_bits_corrupt | ~seen0_auto_client_out_c_bits_corrupt); if (ports <= 60) $display("TOGGLE MISS auto_client_out_c_bits_corrupt 1=%h 0=%h", seen1_auto_client_out_c_bits_corrupt, seen0_auto_client_out_c_bits_corrupt); end
    if ((~seen1_auto_client_out_d_ready | ~seen0_auto_client_out_d_ready) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_d_ready | ~seen0_auto_client_out_d_ready); if (ports <= 60) $display("TOGGLE MISS auto_client_out_d_ready 1=%h 0=%h", seen1_auto_client_out_d_ready, seen0_auto_client_out_d_ready); end
    if ((~seen1_auto_client_out_e_valid | ~seen0_auto_client_out_e_valid) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_e_valid | ~seen0_auto_client_out_e_valid); if (ports <= 60) $display("TOGGLE MISS auto_client_out_e_valid 1=%h 0=%h", seen1_auto_client_out_e_valid, seen0_auto_client_out_e_valid); end
    if ((~seen1_auto_client_out_e_bits_sink | ~seen0_auto_client_out_e_bits_sink) != '0) begin ports++; bad += $countones(~seen1_auto_client_out_e_bits_sink | ~seen0_auto_client_out_e_bits_sink); if (ports <= 60) $display("TOGGLE MISS auto_client_out_e_bits_sink 1=%h 0=%h", seen1_auto_client_out_e_bits_sink, seen0_auto_client_out_e_bits_sink); end
    if ((~seen1_io_lsu_load_0_req_ready | ~seen0_io_lsu_load_0_req_ready) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_0_req_ready | ~seen0_io_lsu_load_0_req_ready); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_0_req_ready 1=%h 0=%h", seen1_io_lsu_load_0_req_ready, seen0_io_lsu_load_0_req_ready); end
    if ((~seen1_io_lsu_load_0_resp_valid | ~seen0_io_lsu_load_0_resp_valid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_0_resp_valid | ~seen0_io_lsu_load_0_resp_valid); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_0_resp_valid 1=%h 0=%h", seen1_io_lsu_load_0_resp_valid, seen0_io_lsu_load_0_resp_valid); end
    if ((~seen1_io_lsu_load_0_resp_bits_data | ~seen0_io_lsu_load_0_resp_bits_data) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_0_resp_bits_data | ~seen0_io_lsu_load_0_resp_bits_data); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_0_resp_bits_data 1=%h 0=%h", seen1_io_lsu_load_0_resp_bits_data, seen0_io_lsu_load_0_resp_bits_data); end
    if ((~seen1_io_lsu_load_0_resp_bits_data_delayed | ~seen0_io_lsu_load_0_resp_bits_data_delayed) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_0_resp_bits_data_delayed | ~seen0_io_lsu_load_0_resp_bits_data_delayed); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_0_resp_bits_data_delayed 1=%h 0=%h", seen1_io_lsu_load_0_resp_bits_data_delayed, seen0_io_lsu_load_0_resp_bits_data_delayed); end
    if ((~seen1_io_lsu_load_0_resp_bits_miss | ~seen0_io_lsu_load_0_resp_bits_miss) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_0_resp_bits_miss | ~seen0_io_lsu_load_0_resp_bits_miss); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_0_resp_bits_miss 1=%h 0=%h", seen1_io_lsu_load_0_resp_bits_miss, seen0_io_lsu_load_0_resp_bits_miss); end
    if ((~seen1_io_lsu_load_0_resp_bits_mshr_id | ~seen0_io_lsu_load_0_resp_bits_mshr_id) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_0_resp_bits_mshr_id | ~seen0_io_lsu_load_0_resp_bits_mshr_id); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_0_resp_bits_mshr_id 1=%h 0=%h", seen1_io_lsu_load_0_resp_bits_mshr_id, seen0_io_lsu_load_0_resp_bits_mshr_id); end
    if ((~seen1_io_lsu_load_0_resp_bits_meta_prefetch | ~seen0_io_lsu_load_0_resp_bits_meta_prefetch) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_0_resp_bits_meta_prefetch | ~seen0_io_lsu_load_0_resp_bits_meta_prefetch); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_0_resp_bits_meta_prefetch 1=%h 0=%h", seen1_io_lsu_load_0_resp_bits_meta_prefetch, seen0_io_lsu_load_0_resp_bits_meta_prefetch); end
    if ((~seen1_io_lsu_load_0_resp_bits_handled | ~seen0_io_lsu_load_0_resp_bits_handled) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_0_resp_bits_handled | ~seen0_io_lsu_load_0_resp_bits_handled); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_0_resp_bits_handled 1=%h 0=%h", seen1_io_lsu_load_0_resp_bits_handled, seen0_io_lsu_load_0_resp_bits_handled); end
    if ((~seen1_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied | ~seen0_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied | ~seen0_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied 1=%h 0=%h", seen1_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied, seen0_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied); end
    if ((~seen1_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt | ~seen0_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt | ~seen0_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt 1=%h 0=%h", seen1_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt, seen0_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt); end
    if ((~seen1_io_lsu_load_0_s2_bank_conflict | ~seen0_io_lsu_load_0_s2_bank_conflict) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_0_s2_bank_conflict | ~seen0_io_lsu_load_0_s2_bank_conflict); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_0_s2_bank_conflict 1=%h 0=%h", seen1_io_lsu_load_0_s2_bank_conflict, seen0_io_lsu_load_0_s2_bank_conflict); end
    if ((~seen1_io_lsu_load_0_s2_mq_nack | ~seen0_io_lsu_load_0_s2_mq_nack) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_0_s2_mq_nack | ~seen0_io_lsu_load_0_s2_mq_nack); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_0_s2_mq_nack 1=%h 0=%h", seen1_io_lsu_load_0_s2_mq_nack, seen0_io_lsu_load_0_s2_mq_nack); end
    if ((~seen1_io_lsu_load_1_req_ready | ~seen0_io_lsu_load_1_req_ready) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_1_req_ready | ~seen0_io_lsu_load_1_req_ready); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_1_req_ready 1=%h 0=%h", seen1_io_lsu_load_1_req_ready, seen0_io_lsu_load_1_req_ready); end
    if ((~seen1_io_lsu_load_1_resp_valid | ~seen0_io_lsu_load_1_resp_valid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_1_resp_valid | ~seen0_io_lsu_load_1_resp_valid); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_1_resp_valid 1=%h 0=%h", seen1_io_lsu_load_1_resp_valid, seen0_io_lsu_load_1_resp_valid); end
    if ((~seen1_io_lsu_load_1_resp_bits_data | ~seen0_io_lsu_load_1_resp_bits_data) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_1_resp_bits_data | ~seen0_io_lsu_load_1_resp_bits_data); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_1_resp_bits_data 1=%h 0=%h", seen1_io_lsu_load_1_resp_bits_data, seen0_io_lsu_load_1_resp_bits_data); end
    if ((~seen1_io_lsu_load_1_resp_bits_miss | ~seen0_io_lsu_load_1_resp_bits_miss) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_1_resp_bits_miss | ~seen0_io_lsu_load_1_resp_bits_miss); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_1_resp_bits_miss 1=%h 0=%h", seen1_io_lsu_load_1_resp_bits_miss, seen0_io_lsu_load_1_resp_bits_miss); end
    if ((~seen1_io_lsu_load_1_resp_bits_mshr_id | ~seen0_io_lsu_load_1_resp_bits_mshr_id) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_1_resp_bits_mshr_id | ~seen0_io_lsu_load_1_resp_bits_mshr_id); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_1_resp_bits_mshr_id 1=%h 0=%h", seen1_io_lsu_load_1_resp_bits_mshr_id, seen0_io_lsu_load_1_resp_bits_mshr_id); end
    if ((~seen1_io_lsu_load_1_resp_bits_meta_prefetch | ~seen0_io_lsu_load_1_resp_bits_meta_prefetch) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_1_resp_bits_meta_prefetch | ~seen0_io_lsu_load_1_resp_bits_meta_prefetch); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_1_resp_bits_meta_prefetch 1=%h 0=%h", seen1_io_lsu_load_1_resp_bits_meta_prefetch, seen0_io_lsu_load_1_resp_bits_meta_prefetch); end
    if ((~seen1_io_lsu_load_1_resp_bits_handled | ~seen0_io_lsu_load_1_resp_bits_handled) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_1_resp_bits_handled | ~seen0_io_lsu_load_1_resp_bits_handled); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_1_resp_bits_handled 1=%h 0=%h", seen1_io_lsu_load_1_resp_bits_handled, seen0_io_lsu_load_1_resp_bits_handled); end
    if ((~seen1_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied | ~seen0_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied | ~seen0_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied 1=%h 0=%h", seen1_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied, seen0_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied); end
    if ((~seen1_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt | ~seen0_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt | ~seen0_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt 1=%h 0=%h", seen1_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt, seen0_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt); end
    if ((~seen1_io_lsu_load_1_s2_bank_conflict | ~seen0_io_lsu_load_1_s2_bank_conflict) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_1_s2_bank_conflict | ~seen0_io_lsu_load_1_s2_bank_conflict); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_1_s2_bank_conflict 1=%h 0=%h", seen1_io_lsu_load_1_s2_bank_conflict, seen0_io_lsu_load_1_s2_bank_conflict); end
    if ((~seen1_io_lsu_load_1_s2_mq_nack | ~seen0_io_lsu_load_1_s2_mq_nack) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_1_s2_mq_nack | ~seen0_io_lsu_load_1_s2_mq_nack); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_1_s2_mq_nack 1=%h 0=%h", seen1_io_lsu_load_1_s2_mq_nack, seen0_io_lsu_load_1_s2_mq_nack); end
    if ((~seen1_io_lsu_load_2_req_ready | ~seen0_io_lsu_load_2_req_ready) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_2_req_ready | ~seen0_io_lsu_load_2_req_ready); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_2_req_ready 1=%h 0=%h", seen1_io_lsu_load_2_req_ready, seen0_io_lsu_load_2_req_ready); end
    if ((~seen1_io_lsu_load_2_resp_valid | ~seen0_io_lsu_load_2_resp_valid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_2_resp_valid | ~seen0_io_lsu_load_2_resp_valid); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_2_resp_valid 1=%h 0=%h", seen1_io_lsu_load_2_resp_valid, seen0_io_lsu_load_2_resp_valid); end
    if ((~seen1_io_lsu_load_2_resp_bits_data | ~seen0_io_lsu_load_2_resp_bits_data) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_2_resp_bits_data | ~seen0_io_lsu_load_2_resp_bits_data); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_2_resp_bits_data 1=%h 0=%h", seen1_io_lsu_load_2_resp_bits_data, seen0_io_lsu_load_2_resp_bits_data); end
    if ((~seen1_io_lsu_load_2_resp_bits_miss | ~seen0_io_lsu_load_2_resp_bits_miss) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_2_resp_bits_miss | ~seen0_io_lsu_load_2_resp_bits_miss); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_2_resp_bits_miss 1=%h 0=%h", seen1_io_lsu_load_2_resp_bits_miss, seen0_io_lsu_load_2_resp_bits_miss); end
    if ((~seen1_io_lsu_load_2_resp_bits_mshr_id | ~seen0_io_lsu_load_2_resp_bits_mshr_id) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_2_resp_bits_mshr_id | ~seen0_io_lsu_load_2_resp_bits_mshr_id); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_2_resp_bits_mshr_id 1=%h 0=%h", seen1_io_lsu_load_2_resp_bits_mshr_id, seen0_io_lsu_load_2_resp_bits_mshr_id); end
    if ((~seen1_io_lsu_load_2_resp_bits_meta_prefetch | ~seen0_io_lsu_load_2_resp_bits_meta_prefetch) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_2_resp_bits_meta_prefetch | ~seen0_io_lsu_load_2_resp_bits_meta_prefetch); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_2_resp_bits_meta_prefetch 1=%h 0=%h", seen1_io_lsu_load_2_resp_bits_meta_prefetch, seen0_io_lsu_load_2_resp_bits_meta_prefetch); end
    if ((~seen1_io_lsu_load_2_resp_bits_handled | ~seen0_io_lsu_load_2_resp_bits_handled) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_2_resp_bits_handled | ~seen0_io_lsu_load_2_resp_bits_handled); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_2_resp_bits_handled 1=%h 0=%h", seen1_io_lsu_load_2_resp_bits_handled, seen0_io_lsu_load_2_resp_bits_handled); end
    if ((~seen1_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied | ~seen0_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied | ~seen0_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied 1=%h 0=%h", seen1_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied, seen0_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied); end
    if ((~seen1_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt | ~seen0_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt | ~seen0_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt 1=%h 0=%h", seen1_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt, seen0_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt); end
    if ((~seen1_io_lsu_load_2_s2_bank_conflict | ~seen0_io_lsu_load_2_s2_bank_conflict) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_2_s2_bank_conflict | ~seen0_io_lsu_load_2_s2_bank_conflict); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_2_s2_bank_conflict 1=%h 0=%h", seen1_io_lsu_load_2_s2_bank_conflict, seen0_io_lsu_load_2_s2_bank_conflict); end
    if ((~seen1_io_lsu_load_2_s2_mq_nack | ~seen0_io_lsu_load_2_s2_mq_nack) != '0) begin ports++; bad += $countones(~seen1_io_lsu_load_2_s2_mq_nack | ~seen0_io_lsu_load_2_s2_mq_nack); if (ports <= 60) $display("TOGGLE MISS io_lsu_load_2_s2_mq_nack 1=%h 0=%h", seen1_io_lsu_load_2_s2_mq_nack, seen0_io_lsu_load_2_s2_mq_nack); end
    if ((~seen1_io_lsu_tl_d_channel_valid | ~seen0_io_lsu_tl_d_channel_valid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_tl_d_channel_valid | ~seen0_io_lsu_tl_d_channel_valid); if (ports <= 60) $display("TOGGLE MISS io_lsu_tl_d_channel_valid 1=%h 0=%h", seen1_io_lsu_tl_d_channel_valid, seen0_io_lsu_tl_d_channel_valid); end
    if ((~seen1_io_lsu_tl_d_channel_mshrid | ~seen0_io_lsu_tl_d_channel_mshrid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_tl_d_channel_mshrid | ~seen0_io_lsu_tl_d_channel_mshrid); if (ports <= 60) $display("TOGGLE MISS io_lsu_tl_d_channel_mshrid 1=%h 0=%h", seen1_io_lsu_tl_d_channel_mshrid, seen0_io_lsu_tl_d_channel_mshrid); end
    if ((~seen1_io_lsu_store_req_ready | ~seen0_io_lsu_store_req_ready) != '0) begin ports++; bad += $countones(~seen1_io_lsu_store_req_ready | ~seen0_io_lsu_store_req_ready); if (ports <= 60) $display("TOGGLE MISS io_lsu_store_req_ready 1=%h 0=%h", seen1_io_lsu_store_req_ready, seen0_io_lsu_store_req_ready); end
    if ((~seen1_io_lsu_store_main_pipe_hit_resp_valid | ~seen0_io_lsu_store_main_pipe_hit_resp_valid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_store_main_pipe_hit_resp_valid | ~seen0_io_lsu_store_main_pipe_hit_resp_valid); if (ports <= 60) $display("TOGGLE MISS io_lsu_store_main_pipe_hit_resp_valid 1=%h 0=%h", seen1_io_lsu_store_main_pipe_hit_resp_valid, seen0_io_lsu_store_main_pipe_hit_resp_valid); end
    if ((~seen1_io_lsu_store_main_pipe_hit_resp_bits_id | ~seen0_io_lsu_store_main_pipe_hit_resp_bits_id) != '0) begin ports++; bad += $countones(~seen1_io_lsu_store_main_pipe_hit_resp_bits_id | ~seen0_io_lsu_store_main_pipe_hit_resp_bits_id); if (ports <= 60) $display("TOGGLE MISS io_lsu_store_main_pipe_hit_resp_bits_id 1=%h 0=%h", seen1_io_lsu_store_main_pipe_hit_resp_bits_id, seen0_io_lsu_store_main_pipe_hit_resp_bits_id); end
    if ((~seen1_io_lsu_store_replay_resp_valid | ~seen0_io_lsu_store_replay_resp_valid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_store_replay_resp_valid | ~seen0_io_lsu_store_replay_resp_valid); if (ports <= 60) $display("TOGGLE MISS io_lsu_store_replay_resp_valid 1=%h 0=%h", seen1_io_lsu_store_replay_resp_valid, seen0_io_lsu_store_replay_resp_valid); end
    if ((~seen1_io_lsu_store_replay_resp_bits_id | ~seen0_io_lsu_store_replay_resp_bits_id) != '0) begin ports++; bad += $countones(~seen1_io_lsu_store_replay_resp_bits_id | ~seen0_io_lsu_store_replay_resp_bits_id); if (ports <= 60) $display("TOGGLE MISS io_lsu_store_replay_resp_bits_id 1=%h 0=%h", seen1_io_lsu_store_replay_resp_bits_id, seen0_io_lsu_store_replay_resp_bits_id); end
    if ((~seen1_io_lsu_atomics_req_ready | ~seen0_io_lsu_atomics_req_ready) != '0) begin ports++; bad += $countones(~seen1_io_lsu_atomics_req_ready | ~seen0_io_lsu_atomics_req_ready); if (ports <= 60) $display("TOGGLE MISS io_lsu_atomics_req_ready 1=%h 0=%h", seen1_io_lsu_atomics_req_ready, seen0_io_lsu_atomics_req_ready); end
    if ((~seen1_io_lsu_atomics_resp_valid | ~seen0_io_lsu_atomics_resp_valid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_atomics_resp_valid | ~seen0_io_lsu_atomics_resp_valid); if (ports <= 60) $display("TOGGLE MISS io_lsu_atomics_resp_valid 1=%h 0=%h", seen1_io_lsu_atomics_resp_valid, seen0_io_lsu_atomics_resp_valid); end
    if ((~seen1_io_lsu_atomics_resp_bits_data | ~seen0_io_lsu_atomics_resp_bits_data) != '0) begin ports++; bad += $countones(~seen1_io_lsu_atomics_resp_bits_data | ~seen0_io_lsu_atomics_resp_bits_data); if (ports <= 60) $display("TOGGLE MISS io_lsu_atomics_resp_bits_data 1=%h 0=%h", seen1_io_lsu_atomics_resp_bits_data, seen0_io_lsu_atomics_resp_bits_data); end
    if ((~seen1_io_lsu_atomics_resp_bits_miss | ~seen0_io_lsu_atomics_resp_bits_miss) != '0) begin ports++; bad += $countones(~seen1_io_lsu_atomics_resp_bits_miss | ~seen0_io_lsu_atomics_resp_bits_miss); if (ports <= 60) $display("TOGGLE MISS io_lsu_atomics_resp_bits_miss 1=%h 0=%h", seen1_io_lsu_atomics_resp_bits_miss, seen0_io_lsu_atomics_resp_bits_miss); end
    if ((~seen1_io_lsu_atomics_resp_bits_replay | ~seen0_io_lsu_atomics_resp_bits_replay) != '0) begin ports++; bad += $countones(~seen1_io_lsu_atomics_resp_bits_replay | ~seen0_io_lsu_atomics_resp_bits_replay); if (ports <= 60) $display("TOGGLE MISS io_lsu_atomics_resp_bits_replay 1=%h 0=%h", seen1_io_lsu_atomics_resp_bits_replay, seen0_io_lsu_atomics_resp_bits_replay); end
    if ((~seen1_io_lsu_atomics_resp_bits_tl_error_tl_denied | ~seen0_io_lsu_atomics_resp_bits_tl_error_tl_denied) != '0) begin ports++; bad += $countones(~seen1_io_lsu_atomics_resp_bits_tl_error_tl_denied | ~seen0_io_lsu_atomics_resp_bits_tl_error_tl_denied); if (ports <= 60) $display("TOGGLE MISS io_lsu_atomics_resp_bits_tl_error_tl_denied 1=%h 0=%h", seen1_io_lsu_atomics_resp_bits_tl_error_tl_denied, seen0_io_lsu_atomics_resp_bits_tl_error_tl_denied); end
    if ((~seen1_io_lsu_atomics_resp_bits_tl_error_tl_corrupt | ~seen0_io_lsu_atomics_resp_bits_tl_error_tl_corrupt) != '0) begin ports++; bad += $countones(~seen1_io_lsu_atomics_resp_bits_tl_error_tl_corrupt | ~seen0_io_lsu_atomics_resp_bits_tl_error_tl_corrupt); if (ports <= 60) $display("TOGGLE MISS io_lsu_atomics_resp_bits_tl_error_tl_corrupt 1=%h 0=%h", seen1_io_lsu_atomics_resp_bits_tl_error_tl_corrupt, seen0_io_lsu_atomics_resp_bits_tl_error_tl_corrupt); end
    if ((~seen1_io_lsu_atomics_resp_bits_id | ~seen0_io_lsu_atomics_resp_bits_id) != '0) begin ports++; bad += $countones(~seen1_io_lsu_atomics_resp_bits_id | ~seen0_io_lsu_atomics_resp_bits_id); if (ports <= 60) $display("TOGGLE MISS io_lsu_atomics_resp_bits_id 1=%h 0=%h", seen1_io_lsu_atomics_resp_bits_id, seen0_io_lsu_atomics_resp_bits_id); end
    if ((~seen1_io_lsu_atomics_block_lr | ~seen0_io_lsu_atomics_block_lr) != '0) begin ports++; bad += $countones(~seen1_io_lsu_atomics_block_lr | ~seen0_io_lsu_atomics_block_lr); if (ports <= 60) $display("TOGGLE MISS io_lsu_atomics_block_lr 1=%h 0=%h", seen1_io_lsu_atomics_block_lr, seen0_io_lsu_atomics_block_lr); end
    if ((~seen1_io_lsu_release_valid | ~seen0_io_lsu_release_valid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_release_valid | ~seen0_io_lsu_release_valid); if (ports <= 60) $display("TOGGLE MISS io_lsu_release_valid 1=%h 0=%h", seen1_io_lsu_release_valid, seen0_io_lsu_release_valid); end
    if ((~seen1_io_lsu_release_bits_paddr | ~seen0_io_lsu_release_bits_paddr) != '0) begin ports++; bad += $countones(~seen1_io_lsu_release_bits_paddr | ~seen0_io_lsu_release_bits_paddr); if (ports <= 60) $display("TOGGLE MISS io_lsu_release_bits_paddr 1=%h 0=%h", seen1_io_lsu_release_bits_paddr, seen0_io_lsu_release_bits_paddr); end
    if ((~seen1_io_lsu_forward_D_0_valid | ~seen0_io_lsu_forward_D_0_valid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_0_valid | ~seen0_io_lsu_forward_D_0_valid); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_0_valid 1=%h 0=%h", seen1_io_lsu_forward_D_0_valid, seen0_io_lsu_forward_D_0_valid); end
    if ((~seen1_io_lsu_forward_D_0_data | ~seen0_io_lsu_forward_D_0_data) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_0_data | ~seen0_io_lsu_forward_D_0_data); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_0_data 1=%h 0=%h", seen1_io_lsu_forward_D_0_data, seen0_io_lsu_forward_D_0_data); end
    if ((~seen1_io_lsu_forward_D_0_mshrid | ~seen0_io_lsu_forward_D_0_mshrid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_0_mshrid | ~seen0_io_lsu_forward_D_0_mshrid); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_0_mshrid 1=%h 0=%h", seen1_io_lsu_forward_D_0_mshrid, seen0_io_lsu_forward_D_0_mshrid); end
    if ((~seen1_io_lsu_forward_D_0_last | ~seen0_io_lsu_forward_D_0_last) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_0_last | ~seen0_io_lsu_forward_D_0_last); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_0_last 1=%h 0=%h", seen1_io_lsu_forward_D_0_last, seen0_io_lsu_forward_D_0_last); end
    if ((~seen1_io_lsu_forward_D_0_denied | ~seen0_io_lsu_forward_D_0_denied) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_0_denied | ~seen0_io_lsu_forward_D_0_denied); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_0_denied 1=%h 0=%h", seen1_io_lsu_forward_D_0_denied, seen0_io_lsu_forward_D_0_denied); end
    if ((~seen1_io_lsu_forward_D_0_corrupt | ~seen0_io_lsu_forward_D_0_corrupt) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_0_corrupt | ~seen0_io_lsu_forward_D_0_corrupt); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_0_corrupt 1=%h 0=%h", seen1_io_lsu_forward_D_0_corrupt, seen0_io_lsu_forward_D_0_corrupt); end
    if ((~seen1_io_lsu_forward_D_1_valid | ~seen0_io_lsu_forward_D_1_valid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_1_valid | ~seen0_io_lsu_forward_D_1_valid); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_1_valid 1=%h 0=%h", seen1_io_lsu_forward_D_1_valid, seen0_io_lsu_forward_D_1_valid); end
    if ((~seen1_io_lsu_forward_D_1_data | ~seen0_io_lsu_forward_D_1_data) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_1_data | ~seen0_io_lsu_forward_D_1_data); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_1_data 1=%h 0=%h", seen1_io_lsu_forward_D_1_data, seen0_io_lsu_forward_D_1_data); end
    if ((~seen1_io_lsu_forward_D_1_mshrid | ~seen0_io_lsu_forward_D_1_mshrid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_1_mshrid | ~seen0_io_lsu_forward_D_1_mshrid); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_1_mshrid 1=%h 0=%h", seen1_io_lsu_forward_D_1_mshrid, seen0_io_lsu_forward_D_1_mshrid); end
    if ((~seen1_io_lsu_forward_D_1_last | ~seen0_io_lsu_forward_D_1_last) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_1_last | ~seen0_io_lsu_forward_D_1_last); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_1_last 1=%h 0=%h", seen1_io_lsu_forward_D_1_last, seen0_io_lsu_forward_D_1_last); end
    if ((~seen1_io_lsu_forward_D_1_denied | ~seen0_io_lsu_forward_D_1_denied) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_1_denied | ~seen0_io_lsu_forward_D_1_denied); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_1_denied 1=%h 0=%h", seen1_io_lsu_forward_D_1_denied, seen0_io_lsu_forward_D_1_denied); end
    if ((~seen1_io_lsu_forward_D_1_corrupt | ~seen0_io_lsu_forward_D_1_corrupt) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_1_corrupt | ~seen0_io_lsu_forward_D_1_corrupt); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_1_corrupt 1=%h 0=%h", seen1_io_lsu_forward_D_1_corrupt, seen0_io_lsu_forward_D_1_corrupt); end
    if ((~seen1_io_lsu_forward_D_2_valid | ~seen0_io_lsu_forward_D_2_valid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_2_valid | ~seen0_io_lsu_forward_D_2_valid); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_2_valid 1=%h 0=%h", seen1_io_lsu_forward_D_2_valid, seen0_io_lsu_forward_D_2_valid); end
    if ((~seen1_io_lsu_forward_D_2_data | ~seen0_io_lsu_forward_D_2_data) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_2_data | ~seen0_io_lsu_forward_D_2_data); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_2_data 1=%h 0=%h", seen1_io_lsu_forward_D_2_data, seen0_io_lsu_forward_D_2_data); end
    if ((~seen1_io_lsu_forward_D_2_mshrid | ~seen0_io_lsu_forward_D_2_mshrid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_2_mshrid | ~seen0_io_lsu_forward_D_2_mshrid); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_2_mshrid 1=%h 0=%h", seen1_io_lsu_forward_D_2_mshrid, seen0_io_lsu_forward_D_2_mshrid); end
    if ((~seen1_io_lsu_forward_D_2_last | ~seen0_io_lsu_forward_D_2_last) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_2_last | ~seen0_io_lsu_forward_D_2_last); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_2_last 1=%h 0=%h", seen1_io_lsu_forward_D_2_last, seen0_io_lsu_forward_D_2_last); end
    if ((~seen1_io_lsu_forward_D_2_denied | ~seen0_io_lsu_forward_D_2_denied) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_2_denied | ~seen0_io_lsu_forward_D_2_denied); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_2_denied 1=%h 0=%h", seen1_io_lsu_forward_D_2_denied, seen0_io_lsu_forward_D_2_denied); end
    if ((~seen1_io_lsu_forward_D_2_corrupt | ~seen0_io_lsu_forward_D_2_corrupt) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_D_2_corrupt | ~seen0_io_lsu_forward_D_2_corrupt); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_D_2_corrupt 1=%h 0=%h", seen1_io_lsu_forward_D_2_corrupt, seen0_io_lsu_forward_D_2_corrupt); end
    if ((~seen1_io_lsu_forward_mshr_0_forward_mshr | ~seen0_io_lsu_forward_mshr_0_forward_mshr) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forward_mshr | ~seen0_io_lsu_forward_mshr_0_forward_mshr); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forward_mshr 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forward_mshr, seen0_io_lsu_forward_mshr_0_forward_mshr); end
    if ((~seen1_io_lsu_forward_mshr_0_forwardData_0 | ~seen0_io_lsu_forward_mshr_0_forwardData_0) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forwardData_0 | ~seen0_io_lsu_forward_mshr_0_forwardData_0); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forwardData_0 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forwardData_0, seen0_io_lsu_forward_mshr_0_forwardData_0); end
    if ((~seen1_io_lsu_forward_mshr_0_forwardData_1 | ~seen0_io_lsu_forward_mshr_0_forwardData_1) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forwardData_1 | ~seen0_io_lsu_forward_mshr_0_forwardData_1); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forwardData_1 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forwardData_1, seen0_io_lsu_forward_mshr_0_forwardData_1); end
    if ((~seen1_io_lsu_forward_mshr_0_forwardData_2 | ~seen0_io_lsu_forward_mshr_0_forwardData_2) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forwardData_2 | ~seen0_io_lsu_forward_mshr_0_forwardData_2); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forwardData_2 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forwardData_2, seen0_io_lsu_forward_mshr_0_forwardData_2); end
    if ((~seen1_io_lsu_forward_mshr_0_forwardData_3 | ~seen0_io_lsu_forward_mshr_0_forwardData_3) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forwardData_3 | ~seen0_io_lsu_forward_mshr_0_forwardData_3); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forwardData_3 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forwardData_3, seen0_io_lsu_forward_mshr_0_forwardData_3); end
    if ((~seen1_io_lsu_forward_mshr_0_forwardData_4 | ~seen0_io_lsu_forward_mshr_0_forwardData_4) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forwardData_4 | ~seen0_io_lsu_forward_mshr_0_forwardData_4); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forwardData_4 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forwardData_4, seen0_io_lsu_forward_mshr_0_forwardData_4); end
    if ((~seen1_io_lsu_forward_mshr_0_forwardData_5 | ~seen0_io_lsu_forward_mshr_0_forwardData_5) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forwardData_5 | ~seen0_io_lsu_forward_mshr_0_forwardData_5); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forwardData_5 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forwardData_5, seen0_io_lsu_forward_mshr_0_forwardData_5); end
    if ((~seen1_io_lsu_forward_mshr_0_forwardData_6 | ~seen0_io_lsu_forward_mshr_0_forwardData_6) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forwardData_6 | ~seen0_io_lsu_forward_mshr_0_forwardData_6); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forwardData_6 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forwardData_6, seen0_io_lsu_forward_mshr_0_forwardData_6); end
    if ((~seen1_io_lsu_forward_mshr_0_forwardData_7 | ~seen0_io_lsu_forward_mshr_0_forwardData_7) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forwardData_7 | ~seen0_io_lsu_forward_mshr_0_forwardData_7); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forwardData_7 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forwardData_7, seen0_io_lsu_forward_mshr_0_forwardData_7); end
    if ((~seen1_io_lsu_forward_mshr_0_forwardData_8 | ~seen0_io_lsu_forward_mshr_0_forwardData_8) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forwardData_8 | ~seen0_io_lsu_forward_mshr_0_forwardData_8); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forwardData_8 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forwardData_8, seen0_io_lsu_forward_mshr_0_forwardData_8); end
    if ((~seen1_io_lsu_forward_mshr_0_forwardData_9 | ~seen0_io_lsu_forward_mshr_0_forwardData_9) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forwardData_9 | ~seen0_io_lsu_forward_mshr_0_forwardData_9); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forwardData_9 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forwardData_9, seen0_io_lsu_forward_mshr_0_forwardData_9); end
    if ((~seen1_io_lsu_forward_mshr_0_forwardData_10 | ~seen0_io_lsu_forward_mshr_0_forwardData_10) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forwardData_10 | ~seen0_io_lsu_forward_mshr_0_forwardData_10); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forwardData_10 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forwardData_10, seen0_io_lsu_forward_mshr_0_forwardData_10); end
    if ((~seen1_io_lsu_forward_mshr_0_forwardData_11 | ~seen0_io_lsu_forward_mshr_0_forwardData_11) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forwardData_11 | ~seen0_io_lsu_forward_mshr_0_forwardData_11); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forwardData_11 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forwardData_11, seen0_io_lsu_forward_mshr_0_forwardData_11); end
    if ((~seen1_io_lsu_forward_mshr_0_forwardData_12 | ~seen0_io_lsu_forward_mshr_0_forwardData_12) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forwardData_12 | ~seen0_io_lsu_forward_mshr_0_forwardData_12); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forwardData_12 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forwardData_12, seen0_io_lsu_forward_mshr_0_forwardData_12); end
    if ((~seen1_io_lsu_forward_mshr_0_forwardData_13 | ~seen0_io_lsu_forward_mshr_0_forwardData_13) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forwardData_13 | ~seen0_io_lsu_forward_mshr_0_forwardData_13); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forwardData_13 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forwardData_13, seen0_io_lsu_forward_mshr_0_forwardData_13); end
    if ((~seen1_io_lsu_forward_mshr_0_forwardData_14 | ~seen0_io_lsu_forward_mshr_0_forwardData_14) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forwardData_14 | ~seen0_io_lsu_forward_mshr_0_forwardData_14); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forwardData_14 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forwardData_14, seen0_io_lsu_forward_mshr_0_forwardData_14); end
    if ((~seen1_io_lsu_forward_mshr_0_forwardData_15 | ~seen0_io_lsu_forward_mshr_0_forwardData_15) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forwardData_15 | ~seen0_io_lsu_forward_mshr_0_forwardData_15); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forwardData_15 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forwardData_15, seen0_io_lsu_forward_mshr_0_forwardData_15); end
    if ((~seen1_io_lsu_forward_mshr_0_forward_result_valid | ~seen0_io_lsu_forward_mshr_0_forward_result_valid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_forward_result_valid | ~seen0_io_lsu_forward_mshr_0_forward_result_valid); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_forward_result_valid 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_forward_result_valid, seen0_io_lsu_forward_mshr_0_forward_result_valid); end
    if ((~seen1_io_lsu_forward_mshr_0_denied | ~seen0_io_lsu_forward_mshr_0_denied) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_denied | ~seen0_io_lsu_forward_mshr_0_denied); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_denied 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_denied, seen0_io_lsu_forward_mshr_0_denied); end
    if ((~seen1_io_lsu_forward_mshr_0_corrupt | ~seen0_io_lsu_forward_mshr_0_corrupt) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_0_corrupt | ~seen0_io_lsu_forward_mshr_0_corrupt); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_0_corrupt 1=%h 0=%h", seen1_io_lsu_forward_mshr_0_corrupt, seen0_io_lsu_forward_mshr_0_corrupt); end
    if ((~seen1_io_lsu_forward_mshr_1_forward_mshr | ~seen0_io_lsu_forward_mshr_1_forward_mshr) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forward_mshr | ~seen0_io_lsu_forward_mshr_1_forward_mshr); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forward_mshr 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forward_mshr, seen0_io_lsu_forward_mshr_1_forward_mshr); end
    if ((~seen1_io_lsu_forward_mshr_1_forwardData_0 | ~seen0_io_lsu_forward_mshr_1_forwardData_0) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forwardData_0 | ~seen0_io_lsu_forward_mshr_1_forwardData_0); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forwardData_0 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forwardData_0, seen0_io_lsu_forward_mshr_1_forwardData_0); end
    if ((~seen1_io_lsu_forward_mshr_1_forwardData_1 | ~seen0_io_lsu_forward_mshr_1_forwardData_1) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forwardData_1 | ~seen0_io_lsu_forward_mshr_1_forwardData_1); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forwardData_1 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forwardData_1, seen0_io_lsu_forward_mshr_1_forwardData_1); end
    if ((~seen1_io_lsu_forward_mshr_1_forwardData_2 | ~seen0_io_lsu_forward_mshr_1_forwardData_2) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forwardData_2 | ~seen0_io_lsu_forward_mshr_1_forwardData_2); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forwardData_2 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forwardData_2, seen0_io_lsu_forward_mshr_1_forwardData_2); end
    if ((~seen1_io_lsu_forward_mshr_1_forwardData_3 | ~seen0_io_lsu_forward_mshr_1_forwardData_3) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forwardData_3 | ~seen0_io_lsu_forward_mshr_1_forwardData_3); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forwardData_3 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forwardData_3, seen0_io_lsu_forward_mshr_1_forwardData_3); end
    if ((~seen1_io_lsu_forward_mshr_1_forwardData_4 | ~seen0_io_lsu_forward_mshr_1_forwardData_4) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forwardData_4 | ~seen0_io_lsu_forward_mshr_1_forwardData_4); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forwardData_4 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forwardData_4, seen0_io_lsu_forward_mshr_1_forwardData_4); end
    if ((~seen1_io_lsu_forward_mshr_1_forwardData_5 | ~seen0_io_lsu_forward_mshr_1_forwardData_5) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forwardData_5 | ~seen0_io_lsu_forward_mshr_1_forwardData_5); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forwardData_5 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forwardData_5, seen0_io_lsu_forward_mshr_1_forwardData_5); end
    if ((~seen1_io_lsu_forward_mshr_1_forwardData_6 | ~seen0_io_lsu_forward_mshr_1_forwardData_6) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forwardData_6 | ~seen0_io_lsu_forward_mshr_1_forwardData_6); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forwardData_6 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forwardData_6, seen0_io_lsu_forward_mshr_1_forwardData_6); end
    if ((~seen1_io_lsu_forward_mshr_1_forwardData_7 | ~seen0_io_lsu_forward_mshr_1_forwardData_7) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forwardData_7 | ~seen0_io_lsu_forward_mshr_1_forwardData_7); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forwardData_7 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forwardData_7, seen0_io_lsu_forward_mshr_1_forwardData_7); end
    if ((~seen1_io_lsu_forward_mshr_1_forwardData_8 | ~seen0_io_lsu_forward_mshr_1_forwardData_8) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forwardData_8 | ~seen0_io_lsu_forward_mshr_1_forwardData_8); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forwardData_8 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forwardData_8, seen0_io_lsu_forward_mshr_1_forwardData_8); end
    if ((~seen1_io_lsu_forward_mshr_1_forwardData_9 | ~seen0_io_lsu_forward_mshr_1_forwardData_9) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forwardData_9 | ~seen0_io_lsu_forward_mshr_1_forwardData_9); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forwardData_9 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forwardData_9, seen0_io_lsu_forward_mshr_1_forwardData_9); end
    if ((~seen1_io_lsu_forward_mshr_1_forwardData_10 | ~seen0_io_lsu_forward_mshr_1_forwardData_10) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forwardData_10 | ~seen0_io_lsu_forward_mshr_1_forwardData_10); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forwardData_10 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forwardData_10, seen0_io_lsu_forward_mshr_1_forwardData_10); end
    if ((~seen1_io_lsu_forward_mshr_1_forwardData_11 | ~seen0_io_lsu_forward_mshr_1_forwardData_11) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forwardData_11 | ~seen0_io_lsu_forward_mshr_1_forwardData_11); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forwardData_11 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forwardData_11, seen0_io_lsu_forward_mshr_1_forwardData_11); end
    if ((~seen1_io_lsu_forward_mshr_1_forwardData_12 | ~seen0_io_lsu_forward_mshr_1_forwardData_12) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forwardData_12 | ~seen0_io_lsu_forward_mshr_1_forwardData_12); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forwardData_12 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forwardData_12, seen0_io_lsu_forward_mshr_1_forwardData_12); end
    if ((~seen1_io_lsu_forward_mshr_1_forwardData_13 | ~seen0_io_lsu_forward_mshr_1_forwardData_13) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forwardData_13 | ~seen0_io_lsu_forward_mshr_1_forwardData_13); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forwardData_13 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forwardData_13, seen0_io_lsu_forward_mshr_1_forwardData_13); end
    if ((~seen1_io_lsu_forward_mshr_1_forwardData_14 | ~seen0_io_lsu_forward_mshr_1_forwardData_14) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forwardData_14 | ~seen0_io_lsu_forward_mshr_1_forwardData_14); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forwardData_14 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forwardData_14, seen0_io_lsu_forward_mshr_1_forwardData_14); end
    if ((~seen1_io_lsu_forward_mshr_1_forwardData_15 | ~seen0_io_lsu_forward_mshr_1_forwardData_15) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forwardData_15 | ~seen0_io_lsu_forward_mshr_1_forwardData_15); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forwardData_15 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forwardData_15, seen0_io_lsu_forward_mshr_1_forwardData_15); end
    if ((~seen1_io_lsu_forward_mshr_1_forward_result_valid | ~seen0_io_lsu_forward_mshr_1_forward_result_valid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_forward_result_valid | ~seen0_io_lsu_forward_mshr_1_forward_result_valid); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_forward_result_valid 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_forward_result_valid, seen0_io_lsu_forward_mshr_1_forward_result_valid); end
    if ((~seen1_io_lsu_forward_mshr_1_denied | ~seen0_io_lsu_forward_mshr_1_denied) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_denied | ~seen0_io_lsu_forward_mshr_1_denied); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_denied 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_denied, seen0_io_lsu_forward_mshr_1_denied); end
    if ((~seen1_io_lsu_forward_mshr_1_corrupt | ~seen0_io_lsu_forward_mshr_1_corrupt) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_1_corrupt | ~seen0_io_lsu_forward_mshr_1_corrupt); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_1_corrupt 1=%h 0=%h", seen1_io_lsu_forward_mshr_1_corrupt, seen0_io_lsu_forward_mshr_1_corrupt); end
    if ((~seen1_io_lsu_forward_mshr_2_forward_mshr | ~seen0_io_lsu_forward_mshr_2_forward_mshr) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forward_mshr | ~seen0_io_lsu_forward_mshr_2_forward_mshr); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forward_mshr 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forward_mshr, seen0_io_lsu_forward_mshr_2_forward_mshr); end
    if ((~seen1_io_lsu_forward_mshr_2_forwardData_0 | ~seen0_io_lsu_forward_mshr_2_forwardData_0) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forwardData_0 | ~seen0_io_lsu_forward_mshr_2_forwardData_0); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forwardData_0 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forwardData_0, seen0_io_lsu_forward_mshr_2_forwardData_0); end
    if ((~seen1_io_lsu_forward_mshr_2_forwardData_1 | ~seen0_io_lsu_forward_mshr_2_forwardData_1) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forwardData_1 | ~seen0_io_lsu_forward_mshr_2_forwardData_1); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forwardData_1 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forwardData_1, seen0_io_lsu_forward_mshr_2_forwardData_1); end
    if ((~seen1_io_lsu_forward_mshr_2_forwardData_2 | ~seen0_io_lsu_forward_mshr_2_forwardData_2) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forwardData_2 | ~seen0_io_lsu_forward_mshr_2_forwardData_2); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forwardData_2 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forwardData_2, seen0_io_lsu_forward_mshr_2_forwardData_2); end
    if ((~seen1_io_lsu_forward_mshr_2_forwardData_3 | ~seen0_io_lsu_forward_mshr_2_forwardData_3) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forwardData_3 | ~seen0_io_lsu_forward_mshr_2_forwardData_3); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forwardData_3 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forwardData_3, seen0_io_lsu_forward_mshr_2_forwardData_3); end
    if ((~seen1_io_lsu_forward_mshr_2_forwardData_4 | ~seen0_io_lsu_forward_mshr_2_forwardData_4) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forwardData_4 | ~seen0_io_lsu_forward_mshr_2_forwardData_4); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forwardData_4 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forwardData_4, seen0_io_lsu_forward_mshr_2_forwardData_4); end
    if ((~seen1_io_lsu_forward_mshr_2_forwardData_5 | ~seen0_io_lsu_forward_mshr_2_forwardData_5) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forwardData_5 | ~seen0_io_lsu_forward_mshr_2_forwardData_5); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forwardData_5 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forwardData_5, seen0_io_lsu_forward_mshr_2_forwardData_5); end
    if ((~seen1_io_lsu_forward_mshr_2_forwardData_6 | ~seen0_io_lsu_forward_mshr_2_forwardData_6) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forwardData_6 | ~seen0_io_lsu_forward_mshr_2_forwardData_6); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forwardData_6 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forwardData_6, seen0_io_lsu_forward_mshr_2_forwardData_6); end
    if ((~seen1_io_lsu_forward_mshr_2_forwardData_7 | ~seen0_io_lsu_forward_mshr_2_forwardData_7) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forwardData_7 | ~seen0_io_lsu_forward_mshr_2_forwardData_7); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forwardData_7 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forwardData_7, seen0_io_lsu_forward_mshr_2_forwardData_7); end
    if ((~seen1_io_lsu_forward_mshr_2_forwardData_8 | ~seen0_io_lsu_forward_mshr_2_forwardData_8) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forwardData_8 | ~seen0_io_lsu_forward_mshr_2_forwardData_8); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forwardData_8 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forwardData_8, seen0_io_lsu_forward_mshr_2_forwardData_8); end
    if ((~seen1_io_lsu_forward_mshr_2_forwardData_9 | ~seen0_io_lsu_forward_mshr_2_forwardData_9) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forwardData_9 | ~seen0_io_lsu_forward_mshr_2_forwardData_9); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forwardData_9 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forwardData_9, seen0_io_lsu_forward_mshr_2_forwardData_9); end
    if ((~seen1_io_lsu_forward_mshr_2_forwardData_10 | ~seen0_io_lsu_forward_mshr_2_forwardData_10) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forwardData_10 | ~seen0_io_lsu_forward_mshr_2_forwardData_10); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forwardData_10 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forwardData_10, seen0_io_lsu_forward_mshr_2_forwardData_10); end
    if ((~seen1_io_lsu_forward_mshr_2_forwardData_11 | ~seen0_io_lsu_forward_mshr_2_forwardData_11) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forwardData_11 | ~seen0_io_lsu_forward_mshr_2_forwardData_11); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forwardData_11 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forwardData_11, seen0_io_lsu_forward_mshr_2_forwardData_11); end
    if ((~seen1_io_lsu_forward_mshr_2_forwardData_12 | ~seen0_io_lsu_forward_mshr_2_forwardData_12) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forwardData_12 | ~seen0_io_lsu_forward_mshr_2_forwardData_12); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forwardData_12 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forwardData_12, seen0_io_lsu_forward_mshr_2_forwardData_12); end
    if ((~seen1_io_lsu_forward_mshr_2_forwardData_13 | ~seen0_io_lsu_forward_mshr_2_forwardData_13) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forwardData_13 | ~seen0_io_lsu_forward_mshr_2_forwardData_13); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forwardData_13 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forwardData_13, seen0_io_lsu_forward_mshr_2_forwardData_13); end
    if ((~seen1_io_lsu_forward_mshr_2_forwardData_14 | ~seen0_io_lsu_forward_mshr_2_forwardData_14) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forwardData_14 | ~seen0_io_lsu_forward_mshr_2_forwardData_14); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forwardData_14 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forwardData_14, seen0_io_lsu_forward_mshr_2_forwardData_14); end
    if ((~seen1_io_lsu_forward_mshr_2_forwardData_15 | ~seen0_io_lsu_forward_mshr_2_forwardData_15) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forwardData_15 | ~seen0_io_lsu_forward_mshr_2_forwardData_15); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forwardData_15 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forwardData_15, seen0_io_lsu_forward_mshr_2_forwardData_15); end
    if ((~seen1_io_lsu_forward_mshr_2_forward_result_valid | ~seen0_io_lsu_forward_mshr_2_forward_result_valid) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_forward_result_valid | ~seen0_io_lsu_forward_mshr_2_forward_result_valid); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_forward_result_valid 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_forward_result_valid, seen0_io_lsu_forward_mshr_2_forward_result_valid); end
    if ((~seen1_io_lsu_forward_mshr_2_denied | ~seen0_io_lsu_forward_mshr_2_denied) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_denied | ~seen0_io_lsu_forward_mshr_2_denied); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_denied 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_denied, seen0_io_lsu_forward_mshr_2_denied); end
    if ((~seen1_io_lsu_forward_mshr_2_corrupt | ~seen0_io_lsu_forward_mshr_2_corrupt) != '0) begin ports++; bad += $countones(~seen1_io_lsu_forward_mshr_2_corrupt | ~seen0_io_lsu_forward_mshr_2_corrupt); if (ports <= 60) $display("TOGGLE MISS io_lsu_forward_mshr_2_corrupt 1=%h 0=%h", seen1_io_lsu_forward_mshr_2_corrupt, seen0_io_lsu_forward_mshr_2_corrupt); end
    if ((~seen1_io_error_valid | ~seen0_io_error_valid) != '0) begin ports++; bad += $countones(~seen1_io_error_valid | ~seen0_io_error_valid); if (ports <= 60) $display("TOGGLE MISS io_error_valid 1=%h 0=%h", seen1_io_error_valid, seen0_io_error_valid); end
    if ((~seen1_io_error_bits_paddr | ~seen0_io_error_bits_paddr) != '0) begin ports++; bad += $countones(~seen1_io_error_bits_paddr | ~seen0_io_error_bits_paddr); if (ports <= 60) $display("TOGGLE MISS io_error_bits_paddr 1=%h 0=%h", seen1_io_error_bits_paddr, seen0_io_error_bits_paddr); end
    if ((~seen1_io_error_bits_report_to_beu | ~seen0_io_error_bits_report_to_beu) != '0) begin ports++; bad += $countones(~seen1_io_error_bits_report_to_beu | ~seen0_io_error_bits_report_to_beu); if (ports <= 60) $display("TOGGLE MISS io_error_bits_report_to_beu 1=%h 0=%h", seen1_io_error_bits_report_to_beu, seen0_io_error_bits_report_to_beu); end
    if ((~seen1_io_pf_ctrl_enable | ~seen0_io_pf_ctrl_enable) != '0) begin ports++; bad += $countones(~seen1_io_pf_ctrl_enable | ~seen0_io_pf_ctrl_enable); if (ports <= 60) $display("TOGGLE MISS io_pf_ctrl_enable 1=%h 0=%h", seen1_io_pf_ctrl_enable, seen0_io_pf_ctrl_enable); end
    if ((~seen1_io_pf_ctrl_confidence | ~seen0_io_pf_ctrl_confidence) != '0) begin ports++; bad += $countones(~seen1_io_pf_ctrl_confidence | ~seen0_io_pf_ctrl_confidence); if (ports <= 60) $display("TOGGLE MISS io_pf_ctrl_confidence 1=%h 0=%h", seen1_io_pf_ctrl_confidence, seen0_io_pf_ctrl_confidence); end
    if ((~seen1_io_sms_agt_evict_req_valid | ~seen0_io_sms_agt_evict_req_valid) != '0) begin ports++; bad += $countones(~seen1_io_sms_agt_evict_req_valid | ~seen0_io_sms_agt_evict_req_valid); if (ports <= 60) $display("TOGGLE MISS io_sms_agt_evict_req_valid 1=%h 0=%h", seen1_io_sms_agt_evict_req_valid, seen0_io_sms_agt_evict_req_valid); end
    if ((~seen1_io_sms_agt_evict_req_bits_vaddr | ~seen0_io_sms_agt_evict_req_bits_vaddr) != '0) begin ports++; bad += $countones(~seen1_io_sms_agt_evict_req_bits_vaddr | ~seen0_io_sms_agt_evict_req_bits_vaddr); if (ports <= 60) $display("TOGGLE MISS io_sms_agt_evict_req_bits_vaddr 1=%h 0=%h", seen1_io_sms_agt_evict_req_bits_vaddr, seen0_io_sms_agt_evict_req_bits_vaddr); end
    if ((~seen1_io_debugTopDown_robHeadMissInDCache | ~seen0_io_debugTopDown_robHeadMissInDCache) != '0) begin ports++; bad += $countones(~seen1_io_debugTopDown_robHeadMissInDCache | ~seen0_io_debugTopDown_robHeadMissInDCache); if (ports <= 60) $display("TOGGLE MISS io_debugTopDown_robHeadMissInDCache 1=%h 0=%h", seen1_io_debugTopDown_robHeadMissInDCache, seen0_io_debugTopDown_robHeadMissInDCache); end
    if ((~seen1_io_cmoOpReq_ready | ~seen0_io_cmoOpReq_ready) != '0) begin ports++; bad += $countones(~seen1_io_cmoOpReq_ready | ~seen0_io_cmoOpReq_ready); if (ports <= 60) $display("TOGGLE MISS io_cmoOpReq_ready 1=%h 0=%h", seen1_io_cmoOpReq_ready, seen0_io_cmoOpReq_ready); end
    if ((~seen1_io_cmoOpResp_valid | ~seen0_io_cmoOpResp_valid) != '0) begin ports++; bad += $countones(~seen1_io_cmoOpResp_valid | ~seen0_io_cmoOpResp_valid); if (ports <= 60) $display("TOGGLE MISS io_cmoOpResp_valid 1=%h 0=%h", seen1_io_cmoOpResp_valid, seen0_io_cmoOpResp_valid); end
    if ((~seen1_io_cmoOpResp_bits_denied | ~seen0_io_cmoOpResp_bits_denied) != '0) begin ports++; bad += $countones(~seen1_io_cmoOpResp_bits_denied | ~seen0_io_cmoOpResp_bits_denied); if (ports <= 60) $display("TOGGLE MISS io_cmoOpResp_bits_denied 1=%h 0=%h", seen1_io_cmoOpResp_bits_denied, seen0_io_cmoOpResp_bits_denied); end
    if ((~seen1_io_cmoOpResp_bits_corrupt | ~seen0_io_cmoOpResp_bits_corrupt) != '0) begin ports++; bad += $countones(~seen1_io_cmoOpResp_bits_corrupt | ~seen0_io_cmoOpResp_bits_corrupt); if (ports <= 60) $display("TOGGLE MISS io_cmoOpResp_bits_corrupt 1=%h 0=%h", seen1_io_cmoOpResp_bits_corrupt, seen0_io_cmoOpResp_bits_corrupt); end
    if ((~seen1_io_l1Miss | ~seen0_io_l1Miss) != '0) begin ports++; bad += $countones(~seen1_io_l1Miss | ~seen0_io_l1Miss); if (ports <= 60) $display("TOGGLE MISS io_l1Miss 1=%h 0=%h", seen1_io_l1Miss, seen0_io_l1Miss); end
    if ((~seen1_io_wfi_wfiSafe | ~seen0_io_wfi_wfiSafe) != '0) begin ports++; bad += $countones(~seen1_io_wfi_wfiSafe | ~seen0_io_wfi_wfiSafe); if (ports <= 60) $display("TOGGLE MISS io_wfi_wfiSafe 1=%h 0=%h", seen1_io_wfi_wfiSafe, seen0_io_wfi_wfiSafe); end
    if ((~seen1_io_perf_0_value | ~seen0_io_perf_0_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_0_value | ~seen0_io_perf_0_value); if (ports <= 60) $display("TOGGLE MISS io_perf_0_value 1=%h 0=%h", seen1_io_perf_0_value, seen0_io_perf_0_value); end
    if ((~seen1_io_perf_1_value | ~seen0_io_perf_1_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_1_value | ~seen0_io_perf_1_value); if (ports <= 60) $display("TOGGLE MISS io_perf_1_value 1=%h 0=%h", seen1_io_perf_1_value, seen0_io_perf_1_value); end
    if ((~seen1_io_perf_2_value | ~seen0_io_perf_2_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_2_value | ~seen0_io_perf_2_value); if (ports <= 60) $display("TOGGLE MISS io_perf_2_value 1=%h 0=%h", seen1_io_perf_2_value, seen0_io_perf_2_value); end
    if ((~seen1_io_perf_3_value | ~seen0_io_perf_3_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_3_value | ~seen0_io_perf_3_value); if (ports <= 60) $display("TOGGLE MISS io_perf_3_value 1=%h 0=%h", seen1_io_perf_3_value, seen0_io_perf_3_value); end
    if ((~seen1_io_perf_4_value | ~seen0_io_perf_4_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_4_value | ~seen0_io_perf_4_value); if (ports <= 60) $display("TOGGLE MISS io_perf_4_value 1=%h 0=%h", seen1_io_perf_4_value, seen0_io_perf_4_value); end
    if ((~seen1_io_perf_5_value | ~seen0_io_perf_5_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_5_value | ~seen0_io_perf_5_value); if (ports <= 60) $display("TOGGLE MISS io_perf_5_value 1=%h 0=%h", seen1_io_perf_5_value, seen0_io_perf_5_value); end
    if ((~seen1_io_perf_6_value | ~seen0_io_perf_6_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_6_value | ~seen0_io_perf_6_value); if (ports <= 60) $display("TOGGLE MISS io_perf_6_value 1=%h 0=%h", seen1_io_perf_6_value, seen0_io_perf_6_value); end
    if ((~seen1_io_perf_7_value | ~seen0_io_perf_7_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_7_value | ~seen0_io_perf_7_value); if (ports <= 60) $display("TOGGLE MISS io_perf_7_value 1=%h 0=%h", seen1_io_perf_7_value, seen0_io_perf_7_value); end
    if ((~seen1_io_perf_8_value | ~seen0_io_perf_8_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_8_value | ~seen0_io_perf_8_value); if (ports <= 60) $display("TOGGLE MISS io_perf_8_value 1=%h 0=%h", seen1_io_perf_8_value, seen0_io_perf_8_value); end
    if ((~seen1_io_perf_9_value | ~seen0_io_perf_9_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_9_value | ~seen0_io_perf_9_value); if (ports <= 60) $display("TOGGLE MISS io_perf_9_value 1=%h 0=%h", seen1_io_perf_9_value, seen0_io_perf_9_value); end
    if ((~seen1_io_perf_10_value | ~seen0_io_perf_10_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_10_value | ~seen0_io_perf_10_value); if (ports <= 60) $display("TOGGLE MISS io_perf_10_value 1=%h 0=%h", seen1_io_perf_10_value, seen0_io_perf_10_value); end
    if ((~seen1_io_perf_11_value | ~seen0_io_perf_11_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_11_value | ~seen0_io_perf_11_value); if (ports <= 60) $display("TOGGLE MISS io_perf_11_value 1=%h 0=%h", seen1_io_perf_11_value, seen0_io_perf_11_value); end
    if ((~seen1_io_perf_12_value | ~seen0_io_perf_12_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_12_value | ~seen0_io_perf_12_value); if (ports <= 60) $display("TOGGLE MISS io_perf_12_value 1=%h 0=%h", seen1_io_perf_12_value, seen0_io_perf_12_value); end
    if ((~seen1_io_perf_13_value | ~seen0_io_perf_13_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_13_value | ~seen0_io_perf_13_value); if (ports <= 60) $display("TOGGLE MISS io_perf_13_value 1=%h 0=%h", seen1_io_perf_13_value, seen0_io_perf_13_value); end
    if ((~seen1_io_perf_14_value | ~seen0_io_perf_14_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_14_value | ~seen0_io_perf_14_value); if (ports <= 60) $display("TOGGLE MISS io_perf_14_value 1=%h 0=%h", seen1_io_perf_14_value, seen0_io_perf_14_value); end
    if ((~seen1_io_perf_15_value | ~seen0_io_perf_15_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_15_value | ~seen0_io_perf_15_value); if (ports <= 60) $display("TOGGLE MISS io_perf_15_value 1=%h 0=%h", seen1_io_perf_15_value, seen0_io_perf_15_value); end
    if ((~seen1_io_perf_16_value | ~seen0_io_perf_16_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_16_value | ~seen0_io_perf_16_value); if (ports <= 60) $display("TOGGLE MISS io_perf_16_value 1=%h 0=%h", seen1_io_perf_16_value, seen0_io_perf_16_value); end
    if ((~seen1_io_perf_17_value | ~seen0_io_perf_17_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_17_value | ~seen0_io_perf_17_value); if (ports <= 60) $display("TOGGLE MISS io_perf_17_value 1=%h 0=%h", seen1_io_perf_17_value, seen0_io_perf_17_value); end
    if ((~seen1_io_perf_18_value | ~seen0_io_perf_18_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_18_value | ~seen0_io_perf_18_value); if (ports <= 60) $display("TOGGLE MISS io_perf_18_value 1=%h 0=%h", seen1_io_perf_18_value, seen0_io_perf_18_value); end
    if ((~seen1_io_perf_19_value | ~seen0_io_perf_19_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_19_value | ~seen0_io_perf_19_value); if (ports <= 60) $display("TOGGLE MISS io_perf_19_value 1=%h 0=%h", seen1_io_perf_19_value, seen0_io_perf_19_value); end
    if ((~seen1_io_perf_20_value | ~seen0_io_perf_20_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_20_value | ~seen0_io_perf_20_value); if (ports <= 60) $display("TOGGLE MISS io_perf_20_value 1=%h 0=%h", seen1_io_perf_20_value, seen0_io_perf_20_value); end
    if ((~seen1_io_perf_21_value | ~seen0_io_perf_21_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_21_value | ~seen0_io_perf_21_value); if (ports <= 60) $display("TOGGLE MISS io_perf_21_value 1=%h 0=%h", seen1_io_perf_21_value, seen0_io_perf_21_value); end
    if ((~seen1_io_perf_22_value | ~seen0_io_perf_22_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_22_value | ~seen0_io_perf_22_value); if (ports <= 60) $display("TOGGLE MISS io_perf_22_value 1=%h 0=%h", seen1_io_perf_22_value, seen0_io_perf_22_value); end
    if ((~seen1_io_perf_23_value | ~seen0_io_perf_23_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_23_value | ~seen0_io_perf_23_value); if (ports <= 60) $display("TOGGLE MISS io_perf_23_value 1=%h 0=%h", seen1_io_perf_23_value, seen0_io_perf_23_value); end
    if ((~seen1_io_perf_24_value | ~seen0_io_perf_24_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_24_value | ~seen0_io_perf_24_value); if (ports <= 60) $display("TOGGLE MISS io_perf_24_value 1=%h 0=%h", seen1_io_perf_24_value, seen0_io_perf_24_value); end
    if ((~seen1_io_perf_25_value | ~seen0_io_perf_25_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_25_value | ~seen0_io_perf_25_value); if (ports <= 60) $display("TOGGLE MISS io_perf_25_value 1=%h 0=%h", seen1_io_perf_25_value, seen0_io_perf_25_value); end
    if ((~seen1_io_perf_26_value | ~seen0_io_perf_26_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_26_value | ~seen0_io_perf_26_value); if (ports <= 60) $display("TOGGLE MISS io_perf_26_value 1=%h 0=%h", seen1_io_perf_26_value, seen0_io_perf_26_value); end
    if ((~seen1_io_perf_27_value | ~seen0_io_perf_27_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_27_value | ~seen0_io_perf_27_value); if (ports <= 60) $display("TOGGLE MISS io_perf_27_value 1=%h 0=%h", seen1_io_perf_27_value, seen0_io_perf_27_value); end
    if ((~seen1_io_perf_28_value | ~seen0_io_perf_28_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_28_value | ~seen0_io_perf_28_value); if (ports <= 60) $display("TOGGLE MISS io_perf_28_value 1=%h 0=%h", seen1_io_perf_28_value, seen0_io_perf_28_value); end
    if ((~seen1_io_perf_29_value | ~seen0_io_perf_29_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_29_value | ~seen0_io_perf_29_value); if (ports <= 60) $display("TOGGLE MISS io_perf_29_value 1=%h 0=%h", seen1_io_perf_29_value, seen0_io_perf_29_value); end
    if ((~seen1_io_perf_30_value | ~seen0_io_perf_30_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_30_value | ~seen0_io_perf_30_value); if (ports <= 60) $display("TOGGLE MISS io_perf_30_value 1=%h 0=%h", seen1_io_perf_30_value, seen0_io_perf_30_value); end
    if ((~seen1_io_perf_31_value | ~seen0_io_perf_31_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_31_value | ~seen0_io_perf_31_value); if (ports <= 60) $display("TOGGLE MISS io_perf_31_value 1=%h 0=%h", seen1_io_perf_31_value, seen0_io_perf_31_value); end
    if ((~seen1_io_perf_32_value | ~seen0_io_perf_32_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_32_value | ~seen0_io_perf_32_value); if (ports <= 60) $display("TOGGLE MISS io_perf_32_value 1=%h 0=%h", seen1_io_perf_32_value, seen0_io_perf_32_value); end
    if ((~seen1_io_perf_33_value | ~seen0_io_perf_33_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_33_value | ~seen0_io_perf_33_value); if (ports <= 60) $display("TOGGLE MISS io_perf_33_value 1=%h 0=%h", seen1_io_perf_33_value, seen0_io_perf_33_value); end
    if ((~seen1_io_perf_34_value | ~seen0_io_perf_34_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_34_value | ~seen0_io_perf_34_value); if (ports <= 60) $display("TOGGLE MISS io_perf_34_value 1=%h 0=%h", seen1_io_perf_34_value, seen0_io_perf_34_value); end
    if ((~seen1_io_perf_35_value | ~seen0_io_perf_35_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_35_value | ~seen0_io_perf_35_value); if (ports <= 60) $display("TOGGLE MISS io_perf_35_value 1=%h 0=%h", seen1_io_perf_35_value, seen0_io_perf_35_value); end
    if ((~seen1_io_perf_36_value | ~seen0_io_perf_36_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_36_value | ~seen0_io_perf_36_value); if (ports <= 60) $display("TOGGLE MISS io_perf_36_value 1=%h 0=%h", seen1_io_perf_36_value, seen0_io_perf_36_value); end
    if ((~seen1_io_perf_37_value | ~seen0_io_perf_37_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_37_value | ~seen0_io_perf_37_value); if (ports <= 60) $display("TOGGLE MISS io_perf_37_value 1=%h 0=%h", seen1_io_perf_37_value, seen0_io_perf_37_value); end
    if ((~seen1_io_perf_38_value | ~seen0_io_perf_38_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_38_value | ~seen0_io_perf_38_value); if (ports <= 60) $display("TOGGLE MISS io_perf_38_value 1=%h 0=%h", seen1_io_perf_38_value, seen0_io_perf_38_value); end
    if ((~seen1_io_perf_39_value | ~seen0_io_perf_39_value) != '0) begin ports++; bad += $countones(~seen1_io_perf_39_value | ~seen0_io_perf_39_value); if (ports <= 60) $display("TOGGLE MISS io_perf_39_value 1=%h 0=%h", seen1_io_perf_39_value, seen0_io_perf_39_value); end
    if ((~seen1_boreChildrenBd_bore_ack | ~seen0_boreChildrenBd_bore_ack) != '0) begin ports++; bad += $countones(~seen1_boreChildrenBd_bore_ack | ~seen0_boreChildrenBd_bore_ack); if (ports <= 60) $display("TOGGLE MISS boreChildrenBd_bore_ack 1=%h 0=%h", seen1_boreChildrenBd_bore_ack, seen0_boreChildrenBd_bore_ack); end
    if ((~seen1_boreChildrenBd_bore_outdata | ~seen0_boreChildrenBd_bore_outdata) != '0) begin ports++; bad += $countones(~seen1_boreChildrenBd_bore_outdata | ~seen0_boreChildrenBd_bore_outdata); if (ports <= 60) $display("TOGGLE MISS boreChildrenBd_bore_outdata 1=%h 0=%h", seen1_boreChildrenBd_bore_outdata, seen0_boreChildrenBd_bore_outdata); end
    if ((~seen1_boreChildrenBd_bore_1_ack | ~seen0_boreChildrenBd_bore_1_ack) != '0) begin ports++; bad += $countones(~seen1_boreChildrenBd_bore_1_ack | ~seen0_boreChildrenBd_bore_1_ack); if (ports <= 60) $display("TOGGLE MISS boreChildrenBd_bore_1_ack 1=%h 0=%h", seen1_boreChildrenBd_bore_1_ack, seen0_boreChildrenBd_bore_1_ack); end
    if ((~seen1_boreChildrenBd_bore_1_outdata | ~seen0_boreChildrenBd_bore_1_outdata) != '0) begin ports++; bad += $countones(~seen1_boreChildrenBd_bore_1_outdata | ~seen0_boreChildrenBd_bore_1_outdata); if (ports <= 60) $display("TOGGLE MISS boreChildrenBd_bore_1_outdata 1=%h 0=%h", seen1_boreChildrenBd_bore_1_outdata, seen0_boreChildrenBd_bore_1_outdata); end
    if ((~seen1_gatewayIn_packed_41_bore | ~seen0_gatewayIn_packed_41_bore) != '0) begin ports++; bad += $countones(~seen1_gatewayIn_packed_41_bore | ~seen0_gatewayIn_packed_41_bore); if (ports <= 60) $display("TOGGLE MISS gatewayIn_packed_41_bore 1=%h 0=%h", seen1_gatewayIn_packed_41_bore, seen0_gatewayIn_packed_41_bore); end
    begin int na = 0;
      if (!cmp_all && !armed_auto_cacheCtrlOpt_in_a_ready) begin na++; if (na <= 40) $display("NEVER ARMED auto_cacheCtrlOpt_in_a_ready"); end
      if (!cmp_all && !armed_auto_cacheCtrlOpt_in_d_valid) begin na++; if (na <= 40) $display("NEVER ARMED auto_cacheCtrlOpt_in_d_valid"); end
      if (!cmp_all && !armed_auto_cacheCtrlOpt_in_d_bits_opcode) begin na++; if (na <= 40) $display("NEVER ARMED auto_cacheCtrlOpt_in_d_bits_opcode"); end
      if (!cmp_all && !armed_auto_cacheCtrlOpt_in_d_bits_size) begin na++; if (na <= 40) $display("NEVER ARMED auto_cacheCtrlOpt_in_d_bits_size"); end
      if (!cmp_all && !armed_auto_cacheCtrlOpt_in_d_bits_source) begin na++; if (na <= 40) $display("NEVER ARMED auto_cacheCtrlOpt_in_d_bits_source"); end
      if (!cmp_all && !armed_auto_cacheCtrlOpt_in_d_bits_data) begin na++; if (na <= 40) $display("NEVER ARMED auto_cacheCtrlOpt_in_d_bits_data"); end
      if (!cmp_all && !armed_auto_client_out_a_valid) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_a_valid"); end
      if (!cmp_all && !armed_auto_client_out_a_bits_opcode) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_a_bits_opcode"); end
      if (!cmp_all && !armed_auto_client_out_a_bits_param) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_a_bits_param"); end
      if (!cmp_all && !armed_auto_client_out_a_bits_size) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_a_bits_size"); end
      if (!cmp_all && !armed_auto_client_out_a_bits_source) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_a_bits_source"); end
      if (!cmp_all && !armed_auto_client_out_a_bits_address) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_a_bits_address"); end
      if (!cmp_all && !armed_auto_client_out_a_bits_user_alias) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_a_bits_user_alias"); end
      if (!cmp_all && !armed_auto_client_out_a_bits_user_vaddr) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_a_bits_user_vaddr"); end
      if (!cmp_all && !armed_auto_client_out_a_bits_user_reqSource) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_a_bits_user_reqSource"); end
      if (!cmp_all && !armed_auto_client_out_a_bits_user_needHint) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_a_bits_user_needHint"); end
      if (!cmp_all && !armed_auto_client_out_a_bits_echo_isKeyword) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_a_bits_echo_isKeyword"); end
      if (!cmp_all && !armed_auto_client_out_a_bits_mask) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_a_bits_mask"); end
      if (!cmp_all && !armed_auto_client_out_b_ready) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_b_ready"); end
      if (!cmp_all && !armed_auto_client_out_c_valid) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_c_valid"); end
      if (!cmp_all && !armed_auto_client_out_c_bits_opcode) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_c_bits_opcode"); end
      if (!cmp_all && !armed_auto_client_out_c_bits_param) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_c_bits_param"); end
      if (!cmp_all && !armed_auto_client_out_c_bits_size) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_c_bits_size"); end
      if (!cmp_all && !armed_auto_client_out_c_bits_source) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_c_bits_source"); end
      if (!cmp_all && !armed_auto_client_out_c_bits_address) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_c_bits_address"); end
      if (!cmp_all && !armed_auto_client_out_c_bits_data) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_c_bits_data"); end
      if (!cmp_all && !armed_auto_client_out_c_bits_corrupt) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_c_bits_corrupt"); end
      if (!cmp_all && !armed_auto_client_out_d_ready) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_d_ready"); end
      if (!cmp_all && !armed_auto_client_out_e_valid) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_e_valid"); end
      if (!cmp_all && !armed_auto_client_out_e_bits_sink) begin na++; if (na <= 40) $display("NEVER ARMED auto_client_out_e_bits_sink"); end
      if (!cmp_all && !armed_io_lsu_load_0_req_ready) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_0_req_ready"); end
      if (!cmp_all && !armed_io_lsu_load_0_resp_valid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_0_resp_valid"); end
      if (!cmp_all && !armed_io_lsu_load_0_resp_bits_data) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_0_resp_bits_data"); end
      if (!cmp_all && !armed_io_lsu_load_0_resp_bits_data_delayed) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_0_resp_bits_data_delayed"); end
      if (!cmp_all && !armed_io_lsu_load_0_resp_bits_miss) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_0_resp_bits_miss"); end
      if (!cmp_all && !armed_io_lsu_load_0_resp_bits_mshr_id) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_0_resp_bits_mshr_id"); end
      if (!cmp_all && !armed_io_lsu_load_0_resp_bits_meta_prefetch) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_0_resp_bits_meta_prefetch"); end
      if (!cmp_all && !armed_io_lsu_load_0_resp_bits_handled) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_0_resp_bits_handled"); end
      if (!cmp_all && !armed_io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_0_resp_bits_tl_error_delayed_tl_denied"); end
      if (!cmp_all && !armed_io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_0_resp_bits_tl_error_delayed_tl_corrupt"); end
      if (!cmp_all && !armed_io_lsu_load_0_s2_bank_conflict) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_0_s2_bank_conflict"); end
      if (!cmp_all && !armed_io_lsu_load_0_s2_mq_nack) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_0_s2_mq_nack"); end
      if (!cmp_all && !armed_io_lsu_load_1_req_ready) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_1_req_ready"); end
      if (!cmp_all && !armed_io_lsu_load_1_resp_valid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_1_resp_valid"); end
      if (!cmp_all && !armed_io_lsu_load_1_resp_bits_data) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_1_resp_bits_data"); end
      if (!cmp_all && !armed_io_lsu_load_1_resp_bits_miss) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_1_resp_bits_miss"); end
      if (!cmp_all && !armed_io_lsu_load_1_resp_bits_mshr_id) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_1_resp_bits_mshr_id"); end
      if (!cmp_all && !armed_io_lsu_load_1_resp_bits_meta_prefetch) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_1_resp_bits_meta_prefetch"); end
      if (!cmp_all && !armed_io_lsu_load_1_resp_bits_handled) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_1_resp_bits_handled"); end
      if (!cmp_all && !armed_io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_1_resp_bits_tl_error_delayed_tl_denied"); end
      if (!cmp_all && !armed_io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_1_resp_bits_tl_error_delayed_tl_corrupt"); end
      if (!cmp_all && !armed_io_lsu_load_1_s2_bank_conflict) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_1_s2_bank_conflict"); end
      if (!cmp_all && !armed_io_lsu_load_1_s2_mq_nack) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_1_s2_mq_nack"); end
      if (!cmp_all && !armed_io_lsu_load_2_req_ready) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_2_req_ready"); end
      if (!cmp_all && !armed_io_lsu_load_2_resp_valid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_2_resp_valid"); end
      if (!cmp_all && !armed_io_lsu_load_2_resp_bits_data) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_2_resp_bits_data"); end
      if (!cmp_all && !armed_io_lsu_load_2_resp_bits_miss) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_2_resp_bits_miss"); end
      if (!cmp_all && !armed_io_lsu_load_2_resp_bits_mshr_id) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_2_resp_bits_mshr_id"); end
      if (!cmp_all && !armed_io_lsu_load_2_resp_bits_meta_prefetch) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_2_resp_bits_meta_prefetch"); end
      if (!cmp_all && !armed_io_lsu_load_2_resp_bits_handled) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_2_resp_bits_handled"); end
      if (!cmp_all && !armed_io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_2_resp_bits_tl_error_delayed_tl_denied"); end
      if (!cmp_all && !armed_io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_2_resp_bits_tl_error_delayed_tl_corrupt"); end
      if (!cmp_all && !armed_io_lsu_load_2_s2_bank_conflict) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_2_s2_bank_conflict"); end
      if (!cmp_all && !armed_io_lsu_load_2_s2_mq_nack) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_load_2_s2_mq_nack"); end
      if (!cmp_all && !armed_io_lsu_tl_d_channel_valid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_tl_d_channel_valid"); end
      if (!cmp_all && !armed_io_lsu_tl_d_channel_mshrid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_tl_d_channel_mshrid"); end
      if (!cmp_all && !armed_io_lsu_store_req_ready) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_store_req_ready"); end
      if (!cmp_all && !armed_io_lsu_store_main_pipe_hit_resp_valid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_store_main_pipe_hit_resp_valid"); end
      if (!cmp_all && !armed_io_lsu_store_main_pipe_hit_resp_bits_id) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_store_main_pipe_hit_resp_bits_id"); end
      if (!cmp_all && !armed_io_lsu_store_replay_resp_valid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_store_replay_resp_valid"); end
      if (!cmp_all && !armed_io_lsu_store_replay_resp_bits_id) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_store_replay_resp_bits_id"); end
      if (!cmp_all && !armed_io_lsu_atomics_req_ready) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_atomics_req_ready"); end
      if (!cmp_all && !armed_io_lsu_atomics_resp_valid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_atomics_resp_valid"); end
      if (!cmp_all && !armed_io_lsu_atomics_resp_bits_data) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_atomics_resp_bits_data"); end
      if (!cmp_all && !armed_io_lsu_atomics_resp_bits_miss) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_atomics_resp_bits_miss"); end
      if (!cmp_all && !armed_io_lsu_atomics_resp_bits_replay) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_atomics_resp_bits_replay"); end
      if (!cmp_all && !armed_io_lsu_atomics_resp_bits_tl_error_tl_denied) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_atomics_resp_bits_tl_error_tl_denied"); end
      if (!cmp_all && !armed_io_lsu_atomics_resp_bits_tl_error_tl_corrupt) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_atomics_resp_bits_tl_error_tl_corrupt"); end
      if (!cmp_all && !armed_io_lsu_atomics_resp_bits_id) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_atomics_resp_bits_id"); end
      if (!cmp_all && !armed_io_lsu_atomics_block_lr) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_atomics_block_lr"); end
      if (!cmp_all && !armed_io_lsu_release_valid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_release_valid"); end
      if (!cmp_all && !armed_io_lsu_release_bits_paddr) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_release_bits_paddr"); end
      if (!cmp_all && !armed_io_lsu_forward_D_0_valid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_0_valid"); end
      if (!cmp_all && !armed_io_lsu_forward_D_0_data) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_0_data"); end
      if (!cmp_all && !armed_io_lsu_forward_D_0_mshrid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_0_mshrid"); end
      if (!cmp_all && !armed_io_lsu_forward_D_0_last) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_0_last"); end
      if (!cmp_all && !armed_io_lsu_forward_D_0_denied) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_0_denied"); end
      if (!cmp_all && !armed_io_lsu_forward_D_0_corrupt) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_0_corrupt"); end
      if (!cmp_all && !armed_io_lsu_forward_D_1_valid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_1_valid"); end
      if (!cmp_all && !armed_io_lsu_forward_D_1_data) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_1_data"); end
      if (!cmp_all && !armed_io_lsu_forward_D_1_mshrid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_1_mshrid"); end
      if (!cmp_all && !armed_io_lsu_forward_D_1_last) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_1_last"); end
      if (!cmp_all && !armed_io_lsu_forward_D_1_denied) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_1_denied"); end
      if (!cmp_all && !armed_io_lsu_forward_D_1_corrupt) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_1_corrupt"); end
      if (!cmp_all && !armed_io_lsu_forward_D_2_valid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_2_valid"); end
      if (!cmp_all && !armed_io_lsu_forward_D_2_data) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_2_data"); end
      if (!cmp_all && !armed_io_lsu_forward_D_2_mshrid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_2_mshrid"); end
      if (!cmp_all && !armed_io_lsu_forward_D_2_last) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_2_last"); end
      if (!cmp_all && !armed_io_lsu_forward_D_2_denied) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_2_denied"); end
      if (!cmp_all && !armed_io_lsu_forward_D_2_corrupt) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_D_2_corrupt"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forward_mshr) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forward_mshr"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_0) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forwardData_0"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_1) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forwardData_1"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_2) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forwardData_2"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_3) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forwardData_3"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_4) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forwardData_4"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_5) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forwardData_5"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_6) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forwardData_6"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_7) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forwardData_7"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_8) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forwardData_8"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_9) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forwardData_9"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_10) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forwardData_10"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_11) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forwardData_11"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_12) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forwardData_12"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_13) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forwardData_13"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_14) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forwardData_14"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forwardData_15) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forwardData_15"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_forward_result_valid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_forward_result_valid"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_denied) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_denied"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_0_corrupt) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_0_corrupt"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forward_mshr) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forward_mshr"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_0) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forwardData_0"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_1) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forwardData_1"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_2) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forwardData_2"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_3) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forwardData_3"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_4) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forwardData_4"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_5) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forwardData_5"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_6) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forwardData_6"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_7) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forwardData_7"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_8) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forwardData_8"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_9) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forwardData_9"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_10) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forwardData_10"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_11) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forwardData_11"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_12) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forwardData_12"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_13) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forwardData_13"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_14) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forwardData_14"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forwardData_15) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forwardData_15"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_forward_result_valid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_forward_result_valid"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_denied) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_denied"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_1_corrupt) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_1_corrupt"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forward_mshr) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forward_mshr"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_0) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forwardData_0"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_1) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forwardData_1"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_2) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forwardData_2"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_3) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forwardData_3"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_4) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forwardData_4"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_5) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forwardData_5"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_6) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forwardData_6"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_7) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forwardData_7"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_8) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forwardData_8"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_9) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forwardData_9"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_10) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forwardData_10"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_11) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forwardData_11"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_12) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forwardData_12"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_13) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forwardData_13"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_14) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forwardData_14"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forwardData_15) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forwardData_15"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_forward_result_valid) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_forward_result_valid"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_denied) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_denied"); end
      if (!cmp_all && !armed_io_lsu_forward_mshr_2_corrupt) begin na++; if (na <= 40) $display("NEVER ARMED io_lsu_forward_mshr_2_corrupt"); end
      if (!cmp_all && !armed_io_error_valid) begin na++; if (na <= 40) $display("NEVER ARMED io_error_valid"); end
      if (!cmp_all && !armed_io_error_bits_paddr) begin na++; if (na <= 40) $display("NEVER ARMED io_error_bits_paddr"); end
      if (!cmp_all && !armed_io_error_bits_report_to_beu) begin na++; if (na <= 40) $display("NEVER ARMED io_error_bits_report_to_beu"); end
      if (!cmp_all && !armed_io_pf_ctrl_enable) begin na++; if (na <= 40) $display("NEVER ARMED io_pf_ctrl_enable"); end
      if (!cmp_all && !armed_io_pf_ctrl_confidence) begin na++; if (na <= 40) $display("NEVER ARMED io_pf_ctrl_confidence"); end
      if (!cmp_all && !armed_io_sms_agt_evict_req_valid) begin na++; if (na <= 40) $display("NEVER ARMED io_sms_agt_evict_req_valid"); end
      if (!cmp_all && !armed_io_sms_agt_evict_req_bits_vaddr) begin na++; if (na <= 40) $display("NEVER ARMED io_sms_agt_evict_req_bits_vaddr"); end
      if (!cmp_all && !armed_io_debugTopDown_robHeadMissInDCache) begin na++; if (na <= 40) $display("NEVER ARMED io_debugTopDown_robHeadMissInDCache"); end
      if (!cmp_all && !armed_io_cmoOpReq_ready) begin na++; if (na <= 40) $display("NEVER ARMED io_cmoOpReq_ready"); end
      if (!cmp_all && !armed_io_cmoOpResp_valid) begin na++; if (na <= 40) $display("NEVER ARMED io_cmoOpResp_valid"); end
      if (!cmp_all && !armed_io_cmoOpResp_bits_denied) begin na++; if (na <= 40) $display("NEVER ARMED io_cmoOpResp_bits_denied"); end
      if (!cmp_all && !armed_io_cmoOpResp_bits_corrupt) begin na++; if (na <= 40) $display("NEVER ARMED io_cmoOpResp_bits_corrupt"); end
      if (!cmp_all && !armed_io_l1Miss) begin na++; if (na <= 40) $display("NEVER ARMED io_l1Miss"); end
      if (!cmp_all && !armed_io_wfi_wfiSafe) begin na++; if (na <= 40) $display("NEVER ARMED io_wfi_wfiSafe"); end
      if (!cmp_all && !armed_io_perf_0_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_0_value"); end
      if (!cmp_all && !armed_io_perf_1_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_1_value"); end
      if (!cmp_all && !armed_io_perf_2_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_2_value"); end
      if (!cmp_all && !armed_io_perf_3_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_3_value"); end
      if (!cmp_all && !armed_io_perf_4_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_4_value"); end
      if (!cmp_all && !armed_io_perf_5_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_5_value"); end
      if (!cmp_all && !armed_io_perf_6_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_6_value"); end
      if (!cmp_all && !armed_io_perf_7_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_7_value"); end
      if (!cmp_all && !armed_io_perf_8_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_8_value"); end
      if (!cmp_all && !armed_io_perf_9_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_9_value"); end
      if (!cmp_all && !armed_io_perf_10_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_10_value"); end
      if (!cmp_all && !armed_io_perf_11_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_11_value"); end
      if (!cmp_all && !armed_io_perf_12_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_12_value"); end
      if (!cmp_all && !armed_io_perf_13_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_13_value"); end
      if (!cmp_all && !armed_io_perf_14_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_14_value"); end
      if (!cmp_all && !armed_io_perf_15_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_15_value"); end
      if (!cmp_all && !armed_io_perf_16_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_16_value"); end
      if (!cmp_all && !armed_io_perf_17_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_17_value"); end
      if (!cmp_all && !armed_io_perf_18_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_18_value"); end
      if (!cmp_all && !armed_io_perf_19_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_19_value"); end
      if (!cmp_all && !armed_io_perf_20_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_20_value"); end
      if (!cmp_all && !armed_io_perf_21_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_21_value"); end
      if (!cmp_all && !armed_io_perf_22_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_22_value"); end
      if (!cmp_all && !armed_io_perf_23_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_23_value"); end
      if (!cmp_all && !armed_io_perf_24_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_24_value"); end
      if (!cmp_all && !armed_io_perf_25_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_25_value"); end
      if (!cmp_all && !armed_io_perf_26_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_26_value"); end
      if (!cmp_all && !armed_io_perf_27_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_27_value"); end
      if (!cmp_all && !armed_io_perf_28_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_28_value"); end
      if (!cmp_all && !armed_io_perf_29_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_29_value"); end
      if (!cmp_all && !armed_io_perf_30_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_30_value"); end
      if (!cmp_all && !armed_io_perf_31_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_31_value"); end
      if (!cmp_all && !armed_io_perf_32_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_32_value"); end
      if (!cmp_all && !armed_io_perf_33_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_33_value"); end
      if (!cmp_all && !armed_io_perf_34_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_34_value"); end
      if (!cmp_all && !armed_io_perf_35_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_35_value"); end
      if (!cmp_all && !armed_io_perf_36_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_36_value"); end
      if (!cmp_all && !armed_io_perf_37_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_37_value"); end
      if (!cmp_all && !armed_io_perf_38_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_38_value"); end
      if (!cmp_all && !armed_io_perf_39_value) begin na++; if (na <= 40) $display("NEVER ARMED io_perf_39_value"); end
      if (!cmp_all && !armed_boreChildrenBd_bore_ack) begin na++; if (na <= 40) $display("NEVER ARMED boreChildrenBd_bore_ack"); end
      if (!cmp_all && !armed_boreChildrenBd_bore_outdata) begin na++; if (na <= 40) $display("NEVER ARMED boreChildrenBd_bore_outdata"); end
      if (!cmp_all && !armed_boreChildrenBd_bore_1_ack) begin na++; if (na <= 40) $display("NEVER ARMED boreChildrenBd_bore_1_ack"); end
      if (!cmp_all && !armed_boreChildrenBd_bore_1_outdata) begin na++; if (na <= 40) $display("NEVER ARMED boreChildrenBd_bore_1_outdata"); end
      if (!cmp_all && !armed_gatewayIn_packed_41_bore) begin na++; if (na <= 40) $display("NEVER ARMED gatewayIn_packed_41_bore"); end
      $display("ARMED: %0d ports never armed (glue-random mode only)", na);
    end
    $display("TOGGLE: %0d output bits never toggled, in %0d ports (of 219 ports / 3626 bits)", bad, ports);
    return bad;
  endfunction
  // END GENERATED

  // ===========================================================================
  // 地址池：6 个 set × 5 个 tag（PMEM 区 0x8000_0000 起；5 > 4 路，同 set 反复替换、写回）
  // ===========================================================================
  localparam int NPOOL = 30;
  logic [47:0] pool [NPOOL];
  initial begin
    automatic int k = 0;
    automatic int sets [6] = '{8'h00, 8'h01, 8'h02, 8'h3f, 8'h80, 8'hff};
    for (int s = 0; s < 6; s++)
      for (int t = 0; t < 5; t++) begin
        // paddr = {tag, set[7:0], 6'b0}；set 位在 [13:6]，tag 在 [47:14]
        pool[k] = 48'h0000_8000_0000 | (48'(t + (s % 2) * 4) << 14) | (48'(sets[s]) << 6);
        k++;
      end
  end
  function automatic logic [47:0] pick_line();
    return pool[$urandom_range(NPOOL - 1)];
  endfunction

  // ===========================================================================
  // L2 模型：D 通道消息队列
  // ===========================================================================
  typedef struct {
    logic [3:0] opcode;
    logic [1:0] param;
    logic [2:0] size;
    logic [5:0] source;
    logic [9:0] sink;
    logic       denied;
    logic       corrupt;
    logic       kw;
    int         beats;
    int         ready_at;
  } dmsg_t;
  dmsg_t dq [$];
  int    d_beat = 0;
  bit    d_noise = 0;       // 本拍 D 上是噪声消息（不从队列出）
  logic [3:0] noise_ops [11] = '{4'h0, 4'h1, 4'h2, 4'h3, 4'h7, 4'h9, 4'hA, 4'hB, 4'hC, 4'hD, 4'hF};
  int    c_beat = 0;
  bit    probe_pending = 0;
  bit    amo_pending = 0;
  int    amo_age = 0;
  bit    cmo_pending = 0;
  int    ctrl_step = -1;    // CtrlUnit 写序列：-1 空闲，0..9 = 写 mask0..7 / delay / ctrl
  logic [63:0] ctrl_word;
  int    wfi_left = 0;
  logic [47:0] s1_line [3];
  bit    store_acc = 0, amo_acc = 0, cmo_acc = 0, ctrl_acc = 0;

  function automatic dmsg_t mk_grant(logic [3:0] a_op, logic [2:0] a_param, logic [5:0] src, logic kw);
    dmsg_t m;
    m.source  = src;
    m.sink    = 10'($urandom());
    m.denied  = ($urandom_range(99) < 2);
    m.corrupt = ($urandom_range(99) < 2);
    m.kw      = kw;
    m.ready_at = cyc + 2 + $urandom_range(22);
    if (a_op >= 4'hC) begin            // CBO -> CBOAck
      m.opcode = 4'h8; m.param = 2'd0; m.size = 3'd6; m.beats = 1;
    end else if (a_op == 4'h6) begin   // AcquireBlock -> GrantData（NtoB 给 toB，其余给 toT）
      m.opcode = 4'h5; m.param = (a_param == 3'd0) ? 2'd1 : 2'd0; m.size = 3'd6; m.beats = 2;
    end else begin                     // AcquirePerm -> Grant（toT）
      m.opcode = 4'h4; m.param = 2'd0; m.size = 3'd6; m.beats = 1;
    end
    return m;
  endfunction

  // ===========================================================================
  // 激励
  // ===========================================================================
  task automatic drive_inputs();
    // 未单独驱动的 MBIST / bore 口保持声明时的 0（MBIST 穿线两侧都是已签核子模块，本 UT 不测）。
    // ---- 上一个 posedge 被收下的请求撤 valid ----
    if (store_acc) begin io_lsu_store_req_valid = 0; store_acc = 0; end
    if (amo_acc) begin io_lsu_atomics_req_valid = 0; amo_acc = 0; end
    if (cmo_acc) begin io_cmoOpReq_valid = 0; cmo_acc = 0; end
    if (ctrl_acc) begin
      auto_cacheCtrlOpt_in_a_valid = 0;
      ctrl_step = (ctrl_step >= 9) ? -1 : ctrl_step + 1;
      ctrl_acc = 0;
    end
    // ---- TileLink A / C / E ready ----
    auto_client_out_a_ready = ($urandom_range(99) < 80);
    auto_client_out_c_ready = ($urandom_range(99) < 80);
    auto_client_out_e_ready = ($urandom_range(99) < 85);

    // ---- D 通道 ----
    d_noise = 0;
    if (dq.size() > 0 && dq[0].ready_at <= cyc && $urandom_range(99) < 85) begin
      auto_client_out_d_valid        = 1;
      auto_client_out_d_bits_opcode  = dq[0].opcode;
      auto_client_out_d_bits_param   = dq[0].param;
      auto_client_out_d_bits_size    = dq[0].size;
      auto_client_out_d_bits_source  = dq[0].source;
      auto_client_out_d_bits_sink    = dq[0].sink;
      auto_client_out_d_bits_denied  = dq[0].denied;
      auto_client_out_d_bits_corrupt = dq[0].corrupt;
      auto_client_out_d_bits_echo_isKeyword = dq[0].kw;
      auto_client_out_d_bits_data    = {8{$urandom()}};
    end else if ($urandom_range(999) < 3) begin
      d_noise = 1;
      auto_client_out_d_valid        = 1;
      // 只用 DCache 不认的 opcode（d_ready 恒 0、不分给任何子模块）：覆盖非法 opcode 那一支，
      // 又不会把合法 Grant 塞给空闲 MSHR、把 L2 模型与 MissQueue 的状态搅乱（那会让后半程 MSHR 卡死、覆盖塌掉）
      auto_client_out_d_bits_opcode  = noise_ops[$urandom_range(10)];
      auto_client_out_d_bits_param   = 2'($urandom());
      auto_client_out_d_bits_size    = 3'($urandom());
      auto_client_out_d_bits_source  = 6'($urandom());
      auto_client_out_d_bits_sink    = 10'($urandom());
      auto_client_out_d_bits_denied  = 1'($urandom());
      auto_client_out_d_bits_corrupt = 1'($urandom());
      auto_client_out_d_bits_echo_isKeyword = 1'($urandom());
      auto_client_out_d_bits_data    = {8{$urandom()}};
    end else begin
      auto_client_out_d_valid        = 0;
      auto_client_out_d_bits_opcode  = 4'($urandom());
      auto_client_out_d_bits_size    = 3'($urandom());
      auto_client_out_d_bits_source  = 6'($urandom());
      auto_client_out_d_bits_echo_isKeyword = 1'($urandom());
      auto_client_out_d_bits_denied  = 1'($urandom());
      auto_client_out_d_bits_corrupt = 1'($urandom());
    end

    // ---- B 通道：Probe ----
    if (!probe_pending && $urandom_range(999) < 8) begin
      automatic logic [47:0] a = pick_line();
      probe_pending = 1;
      auto_client_out_b_bits_opcode  = 3'd6;
      auto_client_out_b_bits_param   = 2'($urandom_range(2));
      auto_client_out_b_bits_address = a;
      auto_client_out_b_bits_data    = {{8{$urandom()}} & ~256'h6} | (256'(a[13:12]) << 1);
    end
    auto_client_out_b_valid = probe_pending;

    // ---- 3 条 load ----
    for (int k = 0; k < 3; k++) begin
      automatic logic        v  = ($urandom_range(99) < 45);
      automatic logic [47:0] la = pick_line() | 48'($urandom_range(7) << 3);
      automatic logic        pf = ($urandom_range(99) < 15);    // 软件/硬件预取请求
      case (k)
        0: begin
          io_lsu_load_0_req_valid = v; io_lsu_load_0_req_bits_cmd = 5'd0;
          io_lsu_load_0_req_bits_vaddr = 50'(la); io_lsu_load_0_req_bits_vaddr_dup = 50'(la);
          io_lsu_load_0_req_bits_instrtype = pf ? 4'd3 : 4'd0;   // 3 = DCACHE_PREFETCH_SOURCE
          io_lsu_load_0_req_bits_isFirstIssue = $urandom_range(1);
          io_lsu_load_0_req_bits_lqIdx_flag = $urandom_range(1); io_lsu_load_0_req_bits_lqIdx_value = 7'($urandom());
          io_lsu_load_0_pf_source = pf ? 3'($urandom_range(1, 7)) : 3'd0;
          io_lsu_load_0_is128Req = ($urandom_range(3) == 0);
          io_lsu_load_0_s1_paddr_dup_lsu = s1_line[0]; io_lsu_load_0_s1_paddr_dup_dcache = s1_line[0];
          io_lsu_load_0_s1_kill = ($urandom_range(99) < 4); io_lsu_load_0_s1_kill_data_read = ($urandom_range(99) < 4);
          io_lsu_load_0_s2_kill = ($urandom_range(99) < 3);
        end
        1: begin
          io_lsu_load_1_req_valid = v; io_lsu_load_1_req_bits_cmd = 5'd0;
          io_lsu_load_1_req_bits_vaddr = 50'(la); io_lsu_load_1_req_bits_vaddr_dup = 50'(la);
          io_lsu_load_1_req_bits_instrtype = pf ? 4'd3 : 4'd0;   // 3 = DCACHE_PREFETCH_SOURCE
          io_lsu_load_1_req_bits_isFirstIssue = $urandom_range(1);
          io_lsu_load_1_req_bits_lqIdx_flag = $urandom_range(1); io_lsu_load_1_req_bits_lqIdx_value = 7'($urandom());
          io_lsu_load_1_pf_source = pf ? 3'($urandom_range(1, 7)) : 3'd0;
          io_lsu_load_1_is128Req = ($urandom_range(3) == 0);
          io_lsu_load_1_s1_paddr_dup_lsu = s1_line[1]; io_lsu_load_1_s1_paddr_dup_dcache = s1_line[1];
          io_lsu_load_1_s1_kill = ($urandom_range(99) < 4); io_lsu_load_1_s1_kill_data_read = ($urandom_range(99) < 4);
          io_lsu_load_1_s2_kill = ($urandom_range(99) < 3);
        end
        default: begin
          io_lsu_load_2_req_valid = v; io_lsu_load_2_req_bits_cmd = 5'd0;
          io_lsu_load_2_req_bits_vaddr = 50'(la); io_lsu_load_2_req_bits_vaddr_dup = 50'(la);
          io_lsu_load_2_req_bits_instrtype = pf ? 4'd3 : 4'd0;   // 3 = DCACHE_PREFETCH_SOURCE
          io_lsu_load_2_req_bits_isFirstIssue = $urandom_range(1);
          io_lsu_load_2_req_bits_lqIdx_flag = $urandom_range(1); io_lsu_load_2_req_bits_lqIdx_value = 7'($urandom());
          io_lsu_load_2_pf_source = pf ? 3'($urandom_range(1, 7)) : 3'd0;
          io_lsu_load_2_is128Req = ($urandom_range(3) == 0);
          io_lsu_load_2_s1_paddr_dup_lsu = s1_line[2]; io_lsu_load_2_s1_paddr_dup_dcache = s1_line[2];
          io_lsu_load_2_s1_kill = ($urandom_range(99) < 4); io_lsu_load_2_s1_kill_data_read = ($urandom_range(99) < 4);
          io_lsu_load_2_s2_kill = ($urandom_range(99) < 3);
        end
      endcase
    end
    io_lsu_sta_0_req_valid = $urandom_range(1);
    io_lsu_sta_1_req_valid = $urandom_range(1);

    // ---- store（整行；保持到被收下）----
    // MainPipe 的 store 口与原子口互斥（store ready 含 ~atomic_req_valid、原子 ready 含 ~store_req_valid，
    // 两个同时挂着就互相等死）；真实 LSU 里原子执行时 sbuffer 已排空，这里也不同时发。
    if (!(io_lsu_store_req_valid) && !amo_pending && !io_lsu_atomics_req_valid) begin
      if ($urandom_range(99) < 20) begin
        automatic logic [47:0] sa = pick_line();
        io_lsu_store_req_valid = 1;
        io_lsu_store_req_bits_addr = sa;
        io_lsu_store_req_bits_vaddr = 50'(sa);
        io_lsu_store_req_bits_data = {16{$urandom()}};
        io_lsu_store_req_bits_mask = ($urandom_range(3) == 0) ? '1 : {$urandom(), $urandom()};
        io_lsu_store_req_bits_id = 6'($urandom());
      end
    end

    // ---- 原子：发一条，等回应（或 600 拍超时）----
    if (!amo_pending && !io_lsu_atomics_req_valid && !io_lsu_store_req_valid && $urandom_range(999) < 15) begin
      automatic logic [47:0] aa = pick_line() | 48'($urandom_range(7) << 3);
      // LR 加权（LR 锁住的行被替换写回时要作废保留集）
      automatic logic [4:0]  cmds [14] = '{5'h4, 5'h6, 5'h6, 5'h6, 5'h6, 5'h7, 5'h8, 5'h9, 5'hA, 5'hB, 5'hC, 5'hD, 5'hE, 5'hF};
      io_lsu_atomics_req_valid = 1;
      io_lsu_atomics_req_bits_cmd = cmds[$urandom_range(13)];
      io_lsu_atomics_req_bits_addr = aa;
      io_lsu_atomics_req_bits_vaddr = 50'(aa);
      io_lsu_atomics_req_bits_word_idx = aa[5:3];
      io_lsu_atomics_req_bits_amo_data = {4{$urandom()}};
      io_lsu_atomics_req_bits_amo_cmp = {4{$urandom()}};
      io_lsu_atomics_req_bits_amo_mask = aa[3] ? 16'hFF00 : 16'h00FF;
      amo_pending = 1;
      amo_age = 0;
    end

    // ---- CMO（保持到被收下）----
    if (!io_cmoOpReq_valid && !cmo_pending && $urandom_range(999) < 2) begin
      io_cmoOpReq_valid = 1;
      io_cmoOpReq_bits_opcode = 3'($urandom_range(2));
      io_cmoOpReq_bits_address = 64'(pick_line());
      cmo_pending = 1;
    end
    io_cmoOpResp_ready = ($urandom_range(99) < 70);

    // ---- MSHR 前递查询、l2 提示、其它 ----
    io_lsu_forward_mshr_0_valid = ($urandom_range(99) < 20);
    io_lsu_forward_mshr_0_mshrid = 4'($urandom());
    io_lsu_forward_mshr_0_paddr = pick_line() | 48'($urandom_range(7) << 3);
    io_lsu_forward_mshr_1_valid = ($urandom_range(99) < 20);
    io_lsu_forward_mshr_1_mshrid = 4'($urandom());
    io_lsu_forward_mshr_1_paddr = pick_line() | 48'($urandom_range(7) << 3);
    io_lsu_forward_mshr_2_valid = ($urandom_range(99) < 20);
    io_lsu_forward_mshr_2_mshrid = 4'($urandom());
    io_lsu_forward_mshr_2_paddr = pick_line() | 48'($urandom_range(7) << 3);
    io_l2_hint_valid = ($urandom_range(99) < 3);
    io_l2_hint_bits_sourceId = 4'($urandom());
    if ($urandom_range(999) < 2) io_l2_pf_store_only = ~io_l2_pf_store_only;
    if ($urandom_range(99) < 5) io_lqEmpty = ~io_lqEmpty;
    io_debugTopDown_robHeadVaddr_valid = ($urandom_range(99) < 30);
    io_debugTopDown_robHeadVaddr_bits = 50'(pick_line());
    if (wfi_left > 0) wfi_left--;
    else if ($urandom_range(9999) < 5) wfi_left = 50 + $urandom_range(200);
    io_wfi_wfiReq = (wfi_left > 0);

    // ---- CtrlUnit：写 8 个掩码 + delay + ctrl，注入伪 ECC 错误 ----
    auto_cacheCtrlOpt_in_d_ready = ($urandom_range(99) < 90);
    if (ctrl_step < 0 && !auto_cacheCtrlOpt_in_a_valid && $urandom_range(9999) < 7) ctrl_step = 0;
    if (ctrl_step >= 0 && !auto_cacheCtrlOpt_in_a_valid) begin
      // index: 0 ctrl, 1 delay, 2..9 mask_0..7；先写掩码与 delay，最后写 ctrl
      automatic int idx = (ctrl_step < 8) ? ctrl_step + 2 : (ctrl_step == 8 ? 1 : 0);
      auto_cacheCtrlOpt_in_a_valid = 1;
      auto_cacheCtrlOpt_in_a_bits_opcode = 4'd0;           // PutFullData
      auto_cacheCtrlOpt_in_a_bits_size = 2'd3;
      auto_cacheCtrlOpt_in_a_bits_source = 4'($urandom());
      auto_cacheCtrlOpt_in_a_bits_address = 30'(idx << 3);
      auto_cacheCtrlOpt_in_a_bits_mask = 8'hFF;
      if (idx >= 2)
        auto_cacheCtrlOpt_in_a_bits_data = {$urandom(), $urandom()} & ({$urandom(), $urandom()} | 64'h1);
      else if (idx == 1)
        auto_cacheCtrlOpt_in_a_bits_data = 64'($urandom_range(40));
      else begin
        // ctrl = {zero, bank[7:0], comp, ede, persist, ese}；ese=1
        ctrl_word = {52'd0, 8'($urandom()), 1'($urandom()), 1'($urandom()), ($urandom_range(3) == 0), 1'b1};
        auto_cacheCtrlOpt_in_a_bits_data = ctrl_word;
      end
    end
  endtask

  // 握手观察（posedge 当拍、NBA 之前读，即沿前的值）
  always @(posedge clock) if (!reset) begin
    // A：收 Acquire / CBO，排一条 D 回应
    if (g_auto_client_out_a_valid && auto_client_out_a_ready)
      dq.push_back(mk_grant(g_auto_client_out_a_bits_opcode, g_auto_client_out_a_bits_param,
                            g_auto_client_out_a_bits_source, g_auto_client_out_a_bits_echo_isKeyword));
    // C：Release[Data] 收完排 ReleaseAck
    if (g_auto_client_out_c_valid && auto_client_out_c_ready) begin
      automatic int nb = (g_auto_client_out_c_bits_opcode[0]) ? 2 : 1;   // *Data 两拍
      c_beat++;
      if (c_beat >= nb) begin
        c_beat = 0;
        if (g_auto_client_out_c_bits_opcode[2:1] == 2'b11) begin   // Release(6) / ReleaseData(7)
          automatic dmsg_t m;
          m.opcode = 4'h6; m.param = 2'd0; m.size = 3'd6; m.source = g_auto_client_out_c_bits_source;
          m.sink = 10'($urandom()); m.denied = 0; m.corrupt = 0; m.kw = 0; m.beats = 1;
          m.ready_at = cyc + 1 + $urandom_range(10);
          dq.push_back(m);
        end
      end
    end
    // D：队首一拍被收下
    if (auto_client_out_d_valid && g_auto_client_out_d_ready && !d_noise && dq.size() > 0) begin
      d_beat++;
      if (d_beat >= dq[0].beats) begin
        d_beat = 0;
        void'(dq.pop_front());
      end
    end
    // B
    if (auto_client_out_b_valid && g_auto_client_out_b_ready) probe_pending = 0;
    // load s0 握手 -> s1 地址
    s1_line[0] = io_lsu_load_0_req_bits_vaddr[47:0];
    s1_line[1] = io_lsu_load_1_req_bits_vaddr[47:0];
    s1_line[2] = io_lsu_load_2_req_bits_vaddr[47:0];
    // store / 原子 / CMO / CtrlUnit 被收下：只记标志，下一个 negedge 再撤 valid（posedge 当拍改 DUT 输入会与采样竞争）
    if (io_lsu_store_req_valid && g_io_lsu_store_req_ready) store_acc = 1;
    if (io_lsu_atomics_req_valid && g_io_lsu_atomics_req_ready) amo_acc = 1;
    if (amo_pending) begin
      amo_age++;
      if (g_io_lsu_atomics_resp_valid || amo_age > 600) amo_pending = 0;
    end
    if (io_cmoOpReq_valid && g_io_cmoOpReq_ready) cmo_acc = 1;
    if (g_io_cmoOpResp_valid && io_cmoOpResp_ready) cmo_pending = 0;
    if (auto_cacheCtrlOpt_in_a_valid && g_auto_cacheCtrlOpt_in_a_ready) ctrl_acc = 1;
  end

  // ===========================================================================
  // 胶水覆盖：从重写核里读（两侧比对已逐拍保证与 golden 一致）
  // ===========================================================================
  int cov_d_mq, cov_d_wb, cov_d_illegal, cov_fwd_last2, cov_fwd_kw, cov_probe_blocked, cov_probe_fire;
  int cov_plru_multi, cov_plru_mp, cov_atomic_lsu, cov_atomic_mq_only, cov_store_replay, cov_release;
  int cov_resv_inval, cov_err [4], cov_err_multi, cov_err_out, cov_pf_good, cov_pf_bad, cov_pf_same;
  int cov_ptag_ready, cov_pdata_ready, cov_l2hint, cov_tag_unintended;

  always @(posedge clock) if (!reset && cyc > RESET_CYC) begin
    automatic int nt = 0;
    if (u_impl.u_core.mq_grant_valid && u_impl.u_core.d_ready) cov_d_mq++;
    if (u_impl.u_core.wb_grant_valid) cov_d_wb++;
    if (u_impl.u_core.d_valid && !u_impl.u_core.d_to_miss_queue && !u_impl.u_core.d_is_release_ack) cov_d_illegal++;
    if (u_impl.u_core.fwd_d_last[0] && u_impl.u_core.d_beats_minus1 && u_impl.u_core.d_fire) cov_fwd_last2++;
    if (u_impl.u_core.d_echo_is_keyword && u_impl.u_core.fwd_d_valid[0]) cov_fwd_kw++;
    if (u_impl.u_core.b_valid && u_impl.u_core.mq_probe_block) cov_probe_blocked++;
    if (u_impl.u_core.b_valid && u_impl.u_core.b_ready) cov_probe_fire++;
    for (int p = 0; p <= 3; p++)
      for (int q = p + 1; q <= 3; q++)
        if (u_impl.u_core.touch_valid[p] && u_impl.u_core.touch_valid[q]
            && u_impl.u_core.touch_set[p] == u_impl.u_core.touch_set[q]) nt++;
    if (nt > 0) cov_plru_multi++;
    if (u_impl.u_core.mp_repl_valid) cov_plru_mp++;
    if (u_impl.u_core.atomic_to_lsu) cov_atomic_lsu++;
    if (u_impl.u_core.mp_atomic_valid && !u_impl.u_core.atomic_to_lsu) cov_atomic_mq_only++;
    if (u_impl.u_core.mp_store_replay_valid) cov_store_replay++;
    if (u_impl.u_core.wb_req_fire) cov_release++;
    if (u_impl.u_core.invalid_resv_set_q) cov_resv_inval++;
    for (int k = 0; k < 4; k++) if (u_impl.u_core.err_valid[k]) cov_err[k]++;
    if ($countones(u_impl.u_core.err_valid) > 1) cov_err_multi++;
    if (u_impl.u_core.error_valid) cov_err_out++;
    if (u_impl.u_core.pfm_good_prefetch) cov_pf_good++;
    if (u_impl.u_core.pfm_bad_prefetch) cov_pf_bad++;
    if (u_impl.u_core.same_cycle_update_pf_flag) cov_pf_same++;
    if (u_impl.u_core.pseudo_tag_error_ready) cov_ptag_ready++;
    if (u_impl.u_core.pseudo_data_error_ready) cov_pdata_ready++;
    if (u_impl.u_core.l2_hint_valid) cov_l2hint++;
    if (u_impl.u_core.tag_write_unintended_q) cov_tag_unintended++;
  end

  // 初值档自证：time 1（复位边沿之前）打印两侧本层几个不复位寄存器与一个子模块寄存器。
  // glue 档下本层应为随机且两侧不同，子模块应为 0；0 档下全 0。
  initial begin
    #1;
    $display("[INITREG] gold perf0_q1=%h err_r_paddr=%h atom_data=%h | impl perf_q1[0]=%h err_src_paddr_q[0]=%h atom_data=%h | child gold.ldu_0 / impl.ldu_0 lsu_req_ready=%b/%b",
             u_gold.io_perf_0_value_REG, u_gold.io_error_bits_r_paddr, u_gold.io_lsu_atomics_resp_bits_r_data,
             u_impl.u_core.perf_q1[0], u_impl.u_core.err_src_paddr_q[0], u_impl.u_core.lsu_atomic_data_q,
             g_io_lsu_load_0_req_ready, i_io_lsu_load_0_req_ready);
  end

  task automatic cov(string name, int n, int min = COV_MIN);
    $display("[COV] %-28s %0d%s", name, n, (n < min) ? "  <-- BELOW MIN" : "");
    if (n < min) cov_fail++;
  endtask

  // ===========================================================================
  // 主流程
  // ===========================================================================
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    if ($test$plusargs("glue_random")) cmp_all = 0;
    // 全部输入清零
    {auto_cacheCtrlOpt_in_a_valid, auto_cacheCtrlOpt_in_d_ready} = '0;
    io_lsu_store_req_valid = 0;
    io_lsu_atomics_req_valid = 0;
    io_cmoOpReq_valid = 0;
    io_l2_pf_store_only = 0;
    io_lqEmpty = 1;
    io_hartId = 6'd0;
    for (int k = 0; k < 3; k++) s1_line[k] = '0;
    reset = 1;
    repeat (RESET_CYC) @(negedge clock) begin drive_inputs(); cyc++; end
    reset = 0;
    while (cyc < NCYCLES) begin
      @(negedge clock);
      if (cyc > RESET_CYC + 2) compare_outputs();
      drive_inputs();
      cyc++;
    end
    $display("=== DCache UT: checks=%0d errors=%0d (cmp_all=%0d) ===", checks, errors, cmp_all);
    cov("d_to_missqueue_fire", cov_d_mq);
    cov("d_releaseack", cov_d_wb);
    cov("d_illegal_opcode", cov_d_illegal);
    cov("fwd_d_last_of_2beat", cov_fwd_last2);
    cov("fwd_d_isKeyword", cov_fwd_kw);
    cov("probe_blocked_by_mq", cov_probe_blocked);
    cov("probe_fire", cov_probe_fire);
    cov("plru_same_set_multi_touch", cov_plru_multi);
    cov("plru_mainpipe_touch", cov_plru_mp);
    cov("atomic_resp_to_lsu", cov_atomic_lsu);
    // MainPipe 的 atomic_resp 在 golden 里只在 AMO 来源时拉高（s2 replay / s3 amo 都带 AMO source），
    // "只给 MissQueue 不给 LSU" 这一支本配置下结构上走不到 —— 只报告，不设门槛（FM 逐点比 source 判断）。
    cov("atomic_resp_mq_only", cov_atomic_mq_only, 0);
    cov("store_replay", cov_store_replay);
    cov("release_to_lsq", cov_release);
    cov("lrsc_resv_invalidate", cov_resv_inval, 1);
    cov("error_mainpipe", cov_err[0]);
    cov("error_ldu0", cov_err[1]);
    cov("error_ldu1", cov_err[2]);
    cov("error_ldu2", cov_err[3]);
    cov("error_multi_source", cov_err_multi, 1);
    cov("error_reported", cov_err_out);
    cov("pf_good", cov_pf_good, 1);
    cov("pf_bad", cov_pf_bad, 1);
    cov("pf_same_cycle_update", cov_pf_same, 1);
    cov("pseudo_tag_ready", cov_ptag_ready, 1);
    cov("pseudo_data_ready", cov_pdata_ready, 1);
    cov("l2_hint", cov_l2hint);
    cov("tag_write_unintended(assert)", cov_tag_unintended, 0);
    void'(report_toggle());
    $display("COVERAGE: cov_fail=%0d", cov_fail);
    if (errors == 0 && checks > 0 && cov_fail == 0) $display("TEST PASSED");
    else $display("TEST FAILED errors=%0d cov_fail=%0d", errors, cov_fail);
    $finish;
  end
endmodule
