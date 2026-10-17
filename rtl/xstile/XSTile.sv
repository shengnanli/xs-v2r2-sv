// XSTile.sv —— 香山 tile 顶层装配：一个处理器核（XSCore）+ 它私有的 L2 子系统（L2Top）+ 4 个中断同步缓冲（IntBuffer）
// =============================================================================
// 在哪一层：SoC（XSTop）之下、XSCore 之上。Chisel 源 xiangshan/XSTile.scala。
//   golden G1-canonical/golden-rtl/XSTile.sv（2,077 行 / 150 端口 / 6 个子模块实例 / 本层 0 个寄存器）。
//
// 数据怎么走：
//   * 核的三路 TileLink（L1D / ICache 桥 / PTW）全部进 L2Top；L2Top 里是 L2 cache 与 TileLink→CHI 桥，
//     对 SoC 的出口是 CHI（io_chi_*）与 MMIO（auto_mmio_*）；
//   * 中断：核外来的 CLINT（msip / mtip）、debug、PLIC（meip / seip）、NMI 先进 L2Top 的中断节点，
//     再各过一个 IntBuffer（一拍异步复位同步寄存器）才到核里 MemBlock 的中断端口；
//   * hartId / 复位向量 / MSI / CLINT 时间也经 L2Top 转给核；核的 BEU 错误、L2 TLB / PMP 共享口、L2 预取控制、
//     trace 接口、停机 / 关键错误等经 L2Top 送出 tile。
//
// 本文件的分工：只有 golden 同名 wrapper XSTile（scripts/gen_xscore_xstile.py 从 golden 例化表机械生成）。
//   本层没有任何逻辑（0 个寄存器），只有纯连线形状，因此没有可读核 xs_XSTile_core：
//   * hartId：顶层 6 位 io_hartId 高位补零成 64 位交给 L2Top（{58'h0, io_hartId}），L2Top 转回来的 64 位只取低 6 位给核；
//   * 核的 io_debugTopDown_robHeadPaddr（48 位）给 L2Top 时只取低 36 位，同时整宽直通 tile 输出；
//   * 核的 L2 刷新完成输入恒 0，核的 L2 刷新请求 / 掉电请求两个输出悬空（本配置不接）。
//   子模块之间的线命名 <驱动实例>_<端口>；接线按"从谁来 / 到哪去"分组并说明。
//
// 4 个 IntBuffer（实例名 golden 原样）：intBuffer（IntBuffer_1，CLINT 两根 msip / mtip）、intBuffer_1（IntBuffer_2，
//   PLIC 两根 meip / seip，端口按 _1_0 / _0_0 编号）、intBuffer_2（IntBuffer，debug 一根）、intBuffer_3（IntBuffer_1，NMI 两根）。

// BEGIN GENERATED(xstile_wrapper) —— 由 scripts/gen_xscore_xstile.py 从 golden 端口表与例化表产出，勿手改
// golden 同名 wrapper：端口与 golden 逐位同名同序；子模块模块名 / 实例名 / 顺序与 golden 一致；
// 子模块之间的线命名为 <驱动实例>_<端口>。
module XSTile (
  input  logic clock,
  input  logic reset,
  output logic auto_l2top_inner_beu_int_out_0,
  input  logic auto_l2top_inner_nmi_int_in_0,
  input  logic auto_l2top_inner_nmi_int_in_1,
  input  logic auto_l2top_inner_plic_int_in_1_0,
  input  logic auto_l2top_inner_plic_int_in_0_0,
  input  logic auto_l2top_inner_debug_int_in_0,
  input  logic auto_l2top_inner_clint_int_in_0,
  input  logic auto_l2top_inner_clint_int_in_1,
  input  logic [5:0] io_hartId,
  input  logic io_msiInfo_valid,
  input  logic [11:0] io_msiInfo_bits,
  output logic io_msiAck,
  input  logic [47:0] io_reset_vector,
  output logic io_cpu_halt,
  output logic io_cpu_crtical_error,
  output logic io_hartIsInReset,
  input  logic io_traceCoreInterface_fromEncoder_enable,
  input  logic io_traceCoreInterface_fromEncoder_stall,
  output logic [2:0] io_traceCoreInterface_toEncoder_priv,
  output logic [63:0] io_traceCoreInterface_toEncoder_mstatus,
  output logic [63:0] io_traceCoreInterface_toEncoder_trap_cause,
  output logic [49:0] io_traceCoreInterface_toEncoder_trap_tval,
  output logic io_traceCoreInterface_toEncoder_groups_0_valid,
  output logic [49:0] io_traceCoreInterface_toEncoder_groups_0_bits_iaddr,
  output logic [3:0] io_traceCoreInterface_toEncoder_groups_0_bits_itype,
  output logic [6:0] io_traceCoreInterface_toEncoder_groups_0_bits_iretire,
  output logic io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize,
  output logic io_traceCoreInterface_toEncoder_groups_1_valid,
  output logic [49:0] io_traceCoreInterface_toEncoder_groups_1_bits_iaddr,
  output logic [3:0] io_traceCoreInterface_toEncoder_groups_1_bits_itype,
  output logic [6:0] io_traceCoreInterface_toEncoder_groups_1_bits_iretire,
  output logic io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize,
  output logic io_traceCoreInterface_toEncoder_groups_2_valid,
  output logic [49:0] io_traceCoreInterface_toEncoder_groups_2_bits_iaddr,
  output logic [3:0] io_traceCoreInterface_toEncoder_groups_2_bits_itype,
  output logic [6:0] io_traceCoreInterface_toEncoder_groups_2_bits_iretire,
  output logic io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize,
  output logic io_debugTopDown_robHeadPaddr_valid,
  output logic [47:0] io_debugTopDown_robHeadPaddr_bits,
  input  logic io_debugTopDown_l3MissMatch,
  input  logic io_l3Miss,
  output logic io_chi_txsactive,
  input  logic io_chi_rxsactive,
  output logic io_chi_syscoreq,
  input  logic io_chi_syscoack,
  output logic io_chi_tx_linkactivereq,
  input  logic io_chi_tx_linkactiveack,
  output logic io_chi_tx_req_flitpend,
  output logic io_chi_tx_req_flitv,
  output logic [161:0] io_chi_tx_req_flit,
  input  logic io_chi_tx_req_lcrdv,
  output logic io_chi_tx_rsp_flitpend,
  output logic io_chi_tx_rsp_flitv,
  output logic [72:0] io_chi_tx_rsp_flit,
  input  logic io_chi_tx_rsp_lcrdv,
  output logic io_chi_tx_dat_flitpend,
  output logic io_chi_tx_dat_flitv,
  output logic [421:0] io_chi_tx_dat_flit,
  input  logic io_chi_tx_dat_lcrdv,
  input  logic io_chi_rx_linkactivereq,
  output logic io_chi_rx_linkactiveack,
  input  logic io_chi_rx_rsp_flitpend,
  input  logic io_chi_rx_rsp_flitv,
  input  logic [72:0] io_chi_rx_rsp_flit,
  output logic io_chi_rx_rsp_lcrdv,
  input  logic io_chi_rx_dat_flitpend,
  input  logic io_chi_rx_dat_flitv,
  input  logic [421:0] io_chi_rx_dat_flit,
  output logic io_chi_rx_dat_lcrdv,
  input  logic io_chi_rx_snp_flitpend,
  input  logic io_chi_rx_snp_flitv,
  input  logic [114:0] io_chi_rx_snp_flit,
  output logic io_chi_rx_snp_lcrdv,
  input  logic [10:0] io_nodeID,
  input  logic io_clintTime_valid,
  input  logic [63:0] io_clintTime_bits,
  input  logic io_dft_ram_hold,
  input  logic io_dft_ram_bypass,
  input  logic io_dft_ram_bp_clken,
  input  logic io_dft_ram_aux_clk,
  input  logic io_dft_ram_aux_ckbp,
  input  logic io_dft_ram_mcp_hold,
  input  logic [63:0] io_dft_ram_ctl,
  input  logic io_dft_cgen,
  input  logic io_dft_reset_lgc_rst_n,
  input  logic io_dft_reset_mode,
  input  logic io_dft_reset_scan_mode,
  output logic [600:0] gatewayIn_packed_0_bore,
  output logic [600:0] gatewayIn_packed_1_bore,
  output logic [600:0] gatewayIn_packed_2_bore,
  output logic [338:0] gatewayIn_packed_3_bore,
  output logic [338:0] gatewayIn_packed_4_bore,
  output logic [338:0] gatewayIn_packed_5_bore,
  output logic [321:0] gatewayIn_packed_6_bore,
  output logic [91:0] gatewayIn_packed_7_bore,
  output logic [321:0] gatewayIn_packed_8_bore,
  output logic [91:0] gatewayIn_packed_9_bore,
  output logic [321:0] gatewayIn_packed_10_bore,
  output logic [91:0] gatewayIn_packed_11_bore,
  output logic [321:0] gatewayIn_packed_12_bore,
  output logic [91:0] gatewayIn_packed_13_bore,
  output logic [321:0] gatewayIn_packed_14_bore,
  output logic [91:0] gatewayIn_packed_15_bore,
  output logic [321:0] gatewayIn_packed_16_bore,
  output logic [91:0] gatewayIn_packed_17_bore,
  output logic [321:0] gatewayIn_packed_18_bore,
  output logic [91:0] gatewayIn_packed_19_bore,
  output logic [321:0] gatewayIn_packed_20_bore,
  output logic [91:0] gatewayIn_packed_21_bore,
  output logic [265:0] gatewayIn_packed_22_bore,
  output logic [263:0] gatewayIn_packed_23_bore,
  output logic [263:0] gatewayIn_packed_24_bore,
  output logic [583:0] gatewayIn_packed_25_bore,
  output logic [14343:0] gatewayIn_packed_26_bore,
  output logic [12295:0] gatewayIn_packed_27_bore,
  output logic [19207:0] gatewayIn_packed_28_bore,
  output logic [172:0] gatewayIn_packed_29_bore,
  output logic [9:0] gatewayIn_packed_30_bore,
  output logic [1159:0] gatewayIn_packed_31_bore,
  output logic [264:0] gatewayIn_packed_32_bore,
  output logic [199:0] gatewayIn_packed_33_bore,
  output logic [455:0] gatewayIn_packed_34_bore,
  output logic [71:0] gatewayIn_packed_35_bore,
  output logic [1095:0] gatewayIn_packed_36_bore,
  output logic [18:0] gatewayIn_packed_37_bore,
  output logic [72:0] gatewayIn_packed_38_bore,
  output logic [264:0] gatewayIn_packed_39_bore,
  output logic [9:0] gatewayIn_packed_40_bore,
  output logic [600:0] gatewayIn_packed_41_bore,
  output logic [152:0] gatewayIn_packed_42_bore,
  output logic [600:0] gatewayIn_packed_43_bore,
  output logic [968:0] gatewayIn_packed_44_bore,
  output logic [968:0] gatewayIn_packed_45_bore,
  output logic [480:0] gatewayIn_packed_46_bore,
  output logic [9:0] gatewayIn_packed_47_bore,
  output logic [72:0] gatewayIn_packed_48_bore,
  output logic [656:0] gatewayIn_packed_49_bore,
  output logic [324:0] gatewayIn_packed_50_bore,
  output logic [324:0] gatewayIn_packed_51_bore,
  output logic [324:0] gatewayIn_packed_52_bore,
  output logic [338:0] gatewayIn_packed_53_bore,
  output logic [338:0] gatewayIn_packed_54_bore,
  output logic [338:0] gatewayIn_packed_55_bore,
  output logic [338:0] gatewayIn_packed_56_bore,
  output logic [338:0] gatewayIn_packed_57_bore,
  output logic [338:0] gatewayIn_packed_58_bore,
  output logic [338:0] gatewayIn_packed_59_bore,
  output logic [338:0] gatewayIn_packed_60_bore
);

  // ===========================================================================
  // core 的输出线（132 根，2500 位）
  // ===========================================================================

  // ---- core → l2top（130 根）----
  logic core_auto_memBlock_inner_buffers_out_a_valid;
  logic [3:0] core_auto_memBlock_inner_buffers_out_a_bits_opcode;
  logic [2:0] core_auto_memBlock_inner_buffers_out_a_bits_param;
  logic [1:0] core_auto_memBlock_inner_buffers_out_a_bits_size;
  logic [3:0] core_auto_memBlock_inner_buffers_out_a_bits_source;
  logic [47:0] core_auto_memBlock_inner_buffers_out_a_bits_address;
  logic core_auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM;
  logic core_auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC;
  logic [7:0] core_auto_memBlock_inner_buffers_out_a_bits_mask;
  logic [63:0] core_auto_memBlock_inner_buffers_out_a_bits_data;
  logic core_auto_memBlock_inner_buffers_out_a_bits_corrupt;
  logic core_auto_memBlock_inner_buffers_out_d_ready;
  logic core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid;
  logic [2:0] core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param;
  logic [47:0] core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address;
  logic core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC;
  logic core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM;
  logic core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt;
  logic core_auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready;
  logic core_auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready;
  logic core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid;
  logic [3:0] core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode;
  logic [1:0] core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param;
  logic [1:0] core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size;
  logic [4:0] core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source;
  logic core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink;
  logic core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied;
  logic [63:0] core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data;
  logic core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt;
  logic core_auto_memBlock_inner_frontendBridge_icache_out_a_valid;
  logic [3:0] core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode;
  logic [2:0] core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_param;
  logic [2:0] core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_size;
  logic [3:0] core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_source;
  logic [47:0] core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_address;
  logic [1:0] core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias;
  logic [4:0] core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource;
  logic core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint;
  logic [31:0] core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask;
  logic [255:0] core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_data;
  logic core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt;
  logic core_auto_memBlock_inner_frontendBridge_icache_out_d_ready;
  logic core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid;
  logic [3:0] core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode;
  logic [2:0] core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param;
  logic [2:0] core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size;
  logic [3:0] core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source;
  logic [47:0] core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address;
  logic [4:0] core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource;
  logic [31:0] core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask;
  logic [255:0] core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data;
  logic core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt;
  logic core_auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready;
  logic [63:0] core_auto_memBlock_inner_l2_pf_sender_out_addr;
  logic [4:0] core_auto_memBlock_inner_l2_pf_sender_out_pf_source;
  logic core_auto_memBlock_inner_l2_pf_sender_out_addr_valid;
  logic core_auto_memBlock_inner_dcache_client_out_a_valid;
  logic [3:0] core_auto_memBlock_inner_dcache_client_out_a_bits_opcode;
  logic [2:0] core_auto_memBlock_inner_dcache_client_out_a_bits_param;
  logic [2:0] core_auto_memBlock_inner_dcache_client_out_a_bits_size;
  logic [5:0] core_auto_memBlock_inner_dcache_client_out_a_bits_source;
  logic [47:0] core_auto_memBlock_inner_dcache_client_out_a_bits_address;
  logic [1:0] core_auto_memBlock_inner_dcache_client_out_a_bits_user_alias;
  logic [43:0] core_auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr;
  logic [4:0] core_auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource;
  logic core_auto_memBlock_inner_dcache_client_out_a_bits_user_needHint;
  logic core_auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword;
  logic [31:0] core_auto_memBlock_inner_dcache_client_out_a_bits_mask;
  logic [255:0] core_auto_memBlock_inner_dcache_client_out_a_bits_data;
  logic core_auto_memBlock_inner_dcache_client_out_a_bits_corrupt;
  logic core_auto_memBlock_inner_dcache_client_out_b_ready;
  logic core_auto_memBlock_inner_dcache_client_out_c_valid;
  logic [2:0] core_auto_memBlock_inner_dcache_client_out_c_bits_opcode;
  logic [2:0] core_auto_memBlock_inner_dcache_client_out_c_bits_param;
  logic [2:0] core_auto_memBlock_inner_dcache_client_out_c_bits_size;
  logic [5:0] core_auto_memBlock_inner_dcache_client_out_c_bits_source;
  logic [47:0] core_auto_memBlock_inner_dcache_client_out_c_bits_address;
  logic [1:0] core_auto_memBlock_inner_dcache_client_out_c_bits_user_alias;
  logic [43:0] core_auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr;
  logic [4:0] core_auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource;
  logic core_auto_memBlock_inner_dcache_client_out_c_bits_user_needHint;
  logic core_auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword;
  logic [255:0] core_auto_memBlock_inner_dcache_client_out_c_bits_data;
  logic core_auto_memBlock_inner_dcache_client_out_c_bits_corrupt;
  logic core_auto_memBlock_inner_dcache_client_out_d_ready;
  logic core_auto_memBlock_inner_dcache_client_out_e_valid;
  logic [9:0] core_auto_memBlock_inner_dcache_client_out_e_bits_sink;
  logic core_io_msiAck;
  logic core_io_cpu_halt;
  logic core_io_cpu_critical_error;
  logic core_io_resetInFrontend;
  logic [2:0] core_io_traceCoreInterface_toEncoder_priv;
  logic [63:0] core_io_traceCoreInterface_toEncoder_mstatus;
  logic [63:0] core_io_traceCoreInterface_toEncoder_trap_cause;
  logic [49:0] core_io_traceCoreInterface_toEncoder_trap_tval;
  logic core_io_traceCoreInterface_toEncoder_groups_0_valid;
  logic [49:0] core_io_traceCoreInterface_toEncoder_groups_0_bits_iaddr;
  logic [3:0] core_io_traceCoreInterface_toEncoder_groups_0_bits_itype;
  logic [6:0] core_io_traceCoreInterface_toEncoder_groups_0_bits_iretire;
  logic core_io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize;
  logic core_io_traceCoreInterface_toEncoder_groups_1_valid;
  logic [49:0] core_io_traceCoreInterface_toEncoder_groups_1_bits_iaddr;
  logic [3:0] core_io_traceCoreInterface_toEncoder_groups_1_bits_itype;
  logic [6:0] core_io_traceCoreInterface_toEncoder_groups_1_bits_iretire;
  logic core_io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize;
  logic core_io_traceCoreInterface_toEncoder_groups_2_valid;
  logic [49:0] core_io_traceCoreInterface_toEncoder_groups_2_bits_iaddr;
  logic [3:0] core_io_traceCoreInterface_toEncoder_groups_2_bits_itype;
  logic [6:0] core_io_traceCoreInterface_toEncoder_groups_2_bits_iretire;
  logic core_io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize;
  logic core_io_l2PfCtrl_l2_pf_master_en;
  logic core_io_l2PfCtrl_l2_pf_recv_en;
  logic core_io_l2PfCtrl_l2_pbop_en;
  logic core_io_l2PfCtrl_l2_vbop_en;
  logic [9:0] core_io_l2PfCtrl_l2_pf_delay_latency;
  logic core_io_beu_errors_icache_ecc_error_valid;
  logic [47:0] core_io_beu_errors_icache_ecc_error_bits;
  logic core_io_beu_errors_dcache_ecc_error_valid;
  logic [47:0] core_io_beu_errors_dcache_ecc_error_bits;
  logic core_io_beu_errors_uncache_ecc_error_valid;
  logic [47:0] core_io_beu_errors_uncache_ecc_error_bits;
  logic core_io_l2_tlb_req_resp_valid;
  logic [47:0] core_io_l2_tlb_req_resp_bits_paddr_0;
  logic [1:0] core_io_l2_tlb_req_resp_bits_pbmt_0;
  logic core_io_l2_tlb_req_resp_bits_miss;
  logic core_io_l2_tlb_req_resp_bits_excp_0_gpf_ld;
  logic core_io_l2_tlb_req_resp_bits_excp_0_pf_ld;
  logic core_io_l2_tlb_req_resp_bits_excp_0_af_ld;
  logic core_io_l2_pmp_resp_ld;
  logic core_io_l2_pmp_resp_mmio;
  // ---- core → l2top / 顶层（2 根）----
  logic core_io_debugTopDown_robHeadPaddr_valid;
  logic [47:0] core_io_debugTopDown_robHeadPaddr_bits;

  // ===========================================================================
  // l2top 的输出线（168 根，2158 位）
  // ===========================================================================

  // ---- l2top → core（161 根）----
  logic l2top_auto_inner_buffers_out_a_valid;
  logic [3:0] l2top_auto_inner_buffers_out_a_bits_opcode;
  logic [2:0] l2top_auto_inner_buffers_out_a_bits_param;
  logic [1:0] l2top_auto_inner_buffers_out_a_bits_size;
  logic [4:0] l2top_auto_inner_buffers_out_a_bits_source;
  logic [29:0] l2top_auto_inner_buffers_out_a_bits_address;
  logic [7:0] l2top_auto_inner_buffers_out_a_bits_mask;
  logic [63:0] l2top_auto_inner_buffers_out_a_bits_data;
  logic l2top_auto_inner_buffers_out_a_bits_corrupt;
  logic l2top_auto_inner_buffers_out_d_ready;
  logic l2top_auto_inner_buffers_in_a_ready;
  logic l2top_auto_inner_buffers_in_d_valid;
  logic [3:0] l2top_auto_inner_buffers_in_d_bits_opcode;
  logic [1:0] l2top_auto_inner_buffers_in_d_bits_param;
  logic [1:0] l2top_auto_inner_buffers_in_d_bits_size;
  logic [3:0] l2top_auto_inner_buffers_in_d_bits_source;
  logic l2top_auto_inner_buffers_in_d_bits_sink;
  logic l2top_auto_inner_buffers_in_d_bits_denied;
  logic [63:0] l2top_auto_inner_buffers_in_d_bits_data;
  logic l2top_auto_inner_buffers_in_d_bits_corrupt;
  logic l2top_auto_inner_intBuffer_out_0;
  logic l2top_auto_inner_i_mmio_buffer_in_a_ready;
  logic l2top_auto_inner_i_mmio_buffer_in_d_valid;
  logic [3:0] l2top_auto_inner_i_mmio_buffer_in_d_bits_opcode;
  logic [1:0] l2top_auto_inner_i_mmio_buffer_in_d_bits_param;
  logic [1:0] l2top_auto_inner_i_mmio_buffer_in_d_bits_size;
  logic l2top_auto_inner_i_mmio_buffer_in_d_bits_source;
  logic l2top_auto_inner_i_mmio_buffer_in_d_bits_sink;
  logic l2top_auto_inner_i_mmio_buffer_in_d_bits_denied;
  logic [63:0] l2top_auto_inner_i_mmio_buffer_in_d_bits_data;
  logic l2top_auto_inner_i_mmio_buffer_in_d_bits_corrupt;
  logic l2top_auto_inner_ptw_to_l2_buffer_in_a_ready;
  logic l2top_auto_inner_ptw_to_l2_buffer_in_d_valid;
  logic [3:0] l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_opcode;
  logic [1:0] l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_param;
  logic [2:0] l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_size;
  logic [3:0] l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_source;
  logic [9:0] l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_sink;
  logic l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_denied;
  logic [255:0] l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_data;
  logic l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt;
  logic l2top_auto_inner_logger_in_1_a_ready;
  logic l2top_auto_inner_logger_in_1_d_valid;
  logic [3:0] l2top_auto_inner_logger_in_1_d_bits_opcode;
  logic [1:0] l2top_auto_inner_logger_in_1_d_bits_param;
  logic [2:0] l2top_auto_inner_logger_in_1_d_bits_size;
  logic [3:0] l2top_auto_inner_logger_in_1_d_bits_source;
  logic [9:0] l2top_auto_inner_logger_in_1_d_bits_sink;
  logic l2top_auto_inner_logger_in_1_d_bits_denied;
  logic [255:0] l2top_auto_inner_logger_in_1_d_bits_data;
  logic l2top_auto_inner_logger_in_1_d_bits_corrupt;
  logic l2top_auto_inner_logger_in_0_a_ready;
  logic l2top_auto_inner_logger_in_0_b_valid;
  logic [2:0] l2top_auto_inner_logger_in_0_b_bits_opcode;
  logic [1:0] l2top_auto_inner_logger_in_0_b_bits_param;
  logic [2:0] l2top_auto_inner_logger_in_0_b_bits_size;
  logic [5:0] l2top_auto_inner_logger_in_0_b_bits_source;
  logic [47:0] l2top_auto_inner_logger_in_0_b_bits_address;
  logic [31:0] l2top_auto_inner_logger_in_0_b_bits_mask;
  logic [255:0] l2top_auto_inner_logger_in_0_b_bits_data;
  logic l2top_auto_inner_logger_in_0_b_bits_corrupt;
  logic l2top_auto_inner_logger_in_0_c_ready;
  logic l2top_auto_inner_logger_in_0_d_valid;
  logic [3:0] l2top_auto_inner_logger_in_0_d_bits_opcode;
  logic [1:0] l2top_auto_inner_logger_in_0_d_bits_param;
  logic [2:0] l2top_auto_inner_logger_in_0_d_bits_size;
  logic [5:0] l2top_auto_inner_logger_in_0_d_bits_source;
  logic [9:0] l2top_auto_inner_logger_in_0_d_bits_sink;
  logic l2top_auto_inner_logger_in_0_d_bits_denied;
  logic l2top_auto_inner_logger_in_0_d_bits_echo_isKeyword;
  logic [255:0] l2top_auto_inner_logger_in_0_d_bits_data;
  logic l2top_auto_inner_logger_in_0_d_bits_corrupt;
  logic l2top_auto_inner_logger_in_0_e_ready;
  logic [47:0] l2top_io_reset_vector_toCore;
  logic [63:0] l2top_io_hartId_toCore;
  logic l2top_io_msiInfo_toCore_valid;
  logic [11:0] l2top_io_msiInfo_toCore_bits;
  logic l2top_io_traceCoreInterface_fromCore_fromEncoder_enable;
  logic l2top_io_traceCoreInterface_fromCore_fromEncoder_stall;
  logic l2top_io_debugTopDown_l2MissMatch;
  logic l2top_io_l2Miss;
  logic l2top_io_l3Miss_toCore;
  logic l2top_io_clintTime_toCore_valid;
  logic [63:0] l2top_io_clintTime_toCore_bits;
  logic l2top_io_l2_tlb_req_req_valid;
  logic [49:0] l2top_io_l2_tlb_req_req_bits_vaddr;
  logic [2:0] l2top_io_l2_tlb_req_req_bits_cmd;
  logic l2top_io_l2_tlb_req_req_bits_kill;
  logic l2top_io_l2_tlb_req_req_bits_isPrefetch;
  logic l2top_io_l2_tlb_req_req_bits_no_translate;
  logic l2top_io_l2_hint_valid;
  logic [3:0] l2top_io_l2_hint_bits_sourceId;
  logic l2top_io_l2_hint_bits_isKeyword;
  logic [5:0] l2top_io_perfEvents_1_value;
  logic [5:0] l2top_io_perfEvents_2_value;
  logic [5:0] l2top_io_perfEvents_3_value;
  logic [5:0] l2top_io_perfEvents_4_value;
  logic [5:0] l2top_io_perfEvents_5_value;
  logic [5:0] l2top_io_perfEvents_6_value;
  logic [5:0] l2top_io_perfEvents_7_value;
  logic [5:0] l2top_io_perfEvents_8_value;
  logic [5:0] l2top_io_perfEvents_9_value;
  logic [5:0] l2top_io_perfEvents_10_value;
  logic [5:0] l2top_io_perfEvents_11_value;
  logic [5:0] l2top_io_perfEvents_12_value;
  logic [5:0] l2top_io_perfEvents_13_value;
  logic [5:0] l2top_io_perfEvents_14_value;
  logic [5:0] l2top_io_perfEvents_15_value;
  logic [5:0] l2top_io_perfEvents_16_value;
  logic [5:0] l2top_io_perfEvents_17_value;
  logic [5:0] l2top_io_perfEvents_18_value;
  logic [5:0] l2top_io_perfEvents_19_value;
  logic [5:0] l2top_io_perfEvents_20_value;
  logic [5:0] l2top_io_perfEvents_21_value;
  logic [5:0] l2top_io_perfEvents_22_value;
  logic [5:0] l2top_io_perfEvents_23_value;
  logic [5:0] l2top_io_perfEvents_24_value;
  logic [5:0] l2top_io_perfEvents_25_value;
  logic [5:0] l2top_io_perfEvents_26_value;
  logic [5:0] l2top_io_perfEvents_27_value;
  logic [5:0] l2top_io_perfEvents_28_value;
  logic [5:0] l2top_io_perfEvents_29_value;
  logic [5:0] l2top_io_perfEvents_30_value;
  logic [5:0] l2top_io_perfEvents_31_value;
  logic [5:0] l2top_io_perfEvents_32_value;
  logic [5:0] l2top_io_perfEvents_33_value;
  logic [5:0] l2top_io_perfEvents_34_value;
  logic [5:0] l2top_io_perfEvents_35_value;
  logic [5:0] l2top_io_perfEvents_36_value;
  logic [5:0] l2top_io_perfEvents_37_value;
  logic [5:0] l2top_io_perfEvents_38_value;
  logic [5:0] l2top_io_perfEvents_39_value;
  logic [5:0] l2top_io_perfEvents_40_value;
  logic [5:0] l2top_io_perfEvents_41_value;
  logic [5:0] l2top_io_perfEvents_42_value;
  logic [5:0] l2top_io_perfEvents_43_value;
  logic [5:0] l2top_io_perfEvents_44_value;
  logic [5:0] l2top_io_perfEvents_45_value;
  logic [5:0] l2top_io_perfEvents_46_value;
  logic [5:0] l2top_io_perfEvents_47_value;
  logic [5:0] l2top_io_perfEvents_48_value;
  logic [5:0] l2top_io_perfEvents_49_value;
  logic [5:0] l2top_io_perfEvents_50_value;
  logic [5:0] l2top_io_perfEvents_51_value;
  logic [5:0] l2top_io_perfEvents_52_value;
  logic [5:0] l2top_io_perfEvents_53_value;
  logic [5:0] l2top_io_perfEvents_54_value;
  logic [5:0] l2top_io_perfEvents_55_value;
  logic [5:0] l2top_io_perfEvents_56_value;
  logic [5:0] l2top_io_perfEvents_57_value;
  logic [5:0] l2top_io_perfEvents_58_value;
  logic [5:0] l2top_io_perfEvents_59_value;
  logic [5:0] l2top_io_perfEvents_60_value;
  logic [5:0] l2top_io_perfEvents_61_value;
  logic [5:0] l2top_io_perfEvents_62_value;
  logic [5:0] l2top_io_perfEvents_63_value;
  logic [5:0] l2top_io_perfEvents_64_value;
  logic [5:0] l2top_io_perfEvents_65_value;
  logic [5:0] l2top_io_perfEvents_66_value;
  logic [5:0] l2top_io_perfEvents_67_value;
  logic [5:0] l2top_io_perfEvents_68_value;
  // ---- l2top → intBuffer_3（2 根）----
  logic l2top_auto_inner_nmi_int_out_0;
  logic l2top_auto_inner_nmi_int_out_1;
  // ---- l2top → intBuffer_1（2 根）----
  logic l2top_auto_inner_plic_int_out_1_0;
  logic l2top_auto_inner_plic_int_out_0_0;
  // ---- l2top → intBuffer_2（1 根）----
  logic l2top_auto_inner_debug_int_out_0;
  // ---- l2top → intBuffer（2 根）----
  logic l2top_auto_inner_clint_int_out_0;
  logic l2top_auto_inner_clint_int_out_1;

  // ===========================================================================
  // intBuffer 的输出线（2 根，2 位）
  // ===========================================================================

  // ---- intBuffer → core（2 根）----
  logic intBuffer_auto_out_0;
  logic intBuffer_auto_out_1;

  // ===========================================================================
  // intBuffer_1 的输出线（2 根，2 位）
  // ===========================================================================

  // ---- intBuffer_1 → core（2 根）----
  logic intBuffer_1_auto_out_1_0;
  logic intBuffer_1_auto_out_0_0;

  // ===========================================================================
  // intBuffer_2 的输出线（1 根，1 位）
  // ===========================================================================

  // ---- intBuffer_2 → core（1 根）----
  logic intBuffer_2_auto_out_0;

  // ===========================================================================
  // intBuffer_3 的输出线（2 根，2 位）
  // ===========================================================================

  // ---- intBuffer_3 → core（2 根）----
  logic intBuffer_3_auto_out_0;
  logic intBuffer_3_auto_out_1;

  // ===========================================================================
  // 子模块 XSCore core（XSCore：处理器核）
  //   374 个端口：输入 179 / 输出 195
  // ===========================================================================
  XSCore core (
    .clock (clock),
    .reset (reset),
    // ← l2top：L2Top → 核：三路 TileLink 回包与反压、hartId（取低 6 位）、复位向量、MSI、CLINT 时间、L2 预取提示、L2 TLB 共享口回应、TopDown 的 L2 missMatch、L2 性能事件
    //   auto_memBlock_inner*（73 根，1485 位）
    .auto_memBlock_inner_buffers_out_a_ready (l2top_auto_inner_buffers_in_a_ready),
    .auto_memBlock_inner_buffers_out_d_valid (l2top_auto_inner_buffers_in_d_valid),
    .auto_memBlock_inner_buffers_out_d_bits_opcode (l2top_auto_inner_buffers_in_d_bits_opcode),
    .auto_memBlock_inner_buffers_out_d_bits_param (l2top_auto_inner_buffers_in_d_bits_param),
    .auto_memBlock_inner_buffers_out_d_bits_size (l2top_auto_inner_buffers_in_d_bits_size),
    .auto_memBlock_inner_buffers_out_d_bits_source (l2top_auto_inner_buffers_in_d_bits_source),
    .auto_memBlock_inner_buffers_out_d_bits_sink (l2top_auto_inner_buffers_in_d_bits_sink),
    .auto_memBlock_inner_buffers_out_d_bits_denied (l2top_auto_inner_buffers_in_d_bits_denied),
    .auto_memBlock_inner_buffers_out_d_bits_data (l2top_auto_inner_buffers_in_d_bits_data),
    .auto_memBlock_inner_buffers_out_d_bits_corrupt (l2top_auto_inner_buffers_in_d_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_ready (l2top_auto_inner_i_mmio_buffer_in_a_ready),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_valid (l2top_auto_inner_i_mmio_buffer_in_d_valid),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_opcode (l2top_auto_inner_i_mmio_buffer_in_d_bits_opcode),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_param (l2top_auto_inner_i_mmio_buffer_in_d_bits_param),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_size (l2top_auto_inner_i_mmio_buffer_in_d_bits_size),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_source (l2top_auto_inner_i_mmio_buffer_in_d_bits_source),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_sink (l2top_auto_inner_i_mmio_buffer_in_d_bits_sink),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_denied (l2top_auto_inner_i_mmio_buffer_in_d_bits_denied),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_data (l2top_auto_inner_i_mmio_buffer_in_d_bits_data),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_corrupt (l2top_auto_inner_i_mmio_buffer_in_d_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_valid (l2top_auto_inner_buffers_out_a_valid),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_opcode (l2top_auto_inner_buffers_out_a_bits_opcode),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_param (l2top_auto_inner_buffers_out_a_bits_param),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_size (l2top_auto_inner_buffers_out_a_bits_size),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_source (l2top_auto_inner_buffers_out_a_bits_source),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_address (l2top_auto_inner_buffers_out_a_bits_address),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_mask (l2top_auto_inner_buffers_out_a_bits_mask),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_data (l2top_auto_inner_buffers_out_a_bits_data),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_corrupt (l2top_auto_inner_buffers_out_a_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_ready (l2top_auto_inner_buffers_out_d_ready),
    .auto_memBlock_inner_frontendBridge_icache_out_a_ready (l2top_auto_inner_logger_in_1_a_ready),
    .auto_memBlock_inner_frontendBridge_icache_out_d_valid (l2top_auto_inner_logger_in_1_d_valid),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_opcode (l2top_auto_inner_logger_in_1_d_bits_opcode),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_param (l2top_auto_inner_logger_in_1_d_bits_param),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_size (l2top_auto_inner_logger_in_1_d_bits_size),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_source (l2top_auto_inner_logger_in_1_d_bits_source),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_sink (l2top_auto_inner_logger_in_1_d_bits_sink),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_denied (l2top_auto_inner_logger_in_1_d_bits_denied),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_data (l2top_auto_inner_logger_in_1_d_bits_data),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_corrupt (l2top_auto_inner_logger_in_1_d_bits_corrupt),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_ready (l2top_auto_inner_ptw_to_l2_buffer_in_a_ready),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_valid (l2top_auto_inner_ptw_to_l2_buffer_in_d_valid),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_opcode (l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_opcode),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_param (l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_param),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_size (l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_size),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_source (l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_source),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_sink (l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_sink),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_denied (l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_denied),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_data (l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_data),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_corrupt (l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt),
    .auto_memBlock_inner_beu_local_int_sink_in_0 (l2top_auto_inner_intBuffer_out_0),
    .auto_memBlock_inner_dcache_client_out_a_ready (l2top_auto_inner_logger_in_0_a_ready),
    .auto_memBlock_inner_dcache_client_out_b_valid (l2top_auto_inner_logger_in_0_b_valid),
    .auto_memBlock_inner_dcache_client_out_b_bits_opcode (l2top_auto_inner_logger_in_0_b_bits_opcode),
    .auto_memBlock_inner_dcache_client_out_b_bits_param (l2top_auto_inner_logger_in_0_b_bits_param),
    .auto_memBlock_inner_dcache_client_out_b_bits_size (l2top_auto_inner_logger_in_0_b_bits_size),
    .auto_memBlock_inner_dcache_client_out_b_bits_source (l2top_auto_inner_logger_in_0_b_bits_source),
    .auto_memBlock_inner_dcache_client_out_b_bits_address (l2top_auto_inner_logger_in_0_b_bits_address),
    .auto_memBlock_inner_dcache_client_out_b_bits_mask (l2top_auto_inner_logger_in_0_b_bits_mask),
    .auto_memBlock_inner_dcache_client_out_b_bits_data (l2top_auto_inner_logger_in_0_b_bits_data),
    .auto_memBlock_inner_dcache_client_out_b_bits_corrupt (l2top_auto_inner_logger_in_0_b_bits_corrupt),
    .auto_memBlock_inner_dcache_client_out_c_ready (l2top_auto_inner_logger_in_0_c_ready),
    .auto_memBlock_inner_dcache_client_out_d_valid (l2top_auto_inner_logger_in_0_d_valid),
    .auto_memBlock_inner_dcache_client_out_d_bits_opcode (l2top_auto_inner_logger_in_0_d_bits_opcode),
    .auto_memBlock_inner_dcache_client_out_d_bits_param (l2top_auto_inner_logger_in_0_d_bits_param),
    .auto_memBlock_inner_dcache_client_out_d_bits_size (l2top_auto_inner_logger_in_0_d_bits_size),
    .auto_memBlock_inner_dcache_client_out_d_bits_source (l2top_auto_inner_logger_in_0_d_bits_source),
    .auto_memBlock_inner_dcache_client_out_d_bits_sink (l2top_auto_inner_logger_in_0_d_bits_sink),
    .auto_memBlock_inner_dcache_client_out_d_bits_denied (l2top_auto_inner_logger_in_0_d_bits_denied),
    .auto_memBlock_inner_dcache_client_out_d_bits_echo_isKeyword (l2top_auto_inner_logger_in_0_d_bits_echo_isKeyword),
    .auto_memBlock_inner_dcache_client_out_d_bits_data (l2top_auto_inner_logger_in_0_d_bits_data),
    .auto_memBlock_inner_dcache_client_out_d_bits_corrupt (l2top_auto_inner_logger_in_0_d_bits_corrupt),
    .auto_memBlock_inner_dcache_client_out_e_ready (l2top_auto_inner_logger_in_0_e_ready),
    //   io_hartId*（1 根，6 位）
    .io_hartId (l2top_io_hartId_toCore[5:0]),
    //   io_msiInfo_valid*（1 根，1 位）
    .io_msiInfo_valid (l2top_io_msiInfo_toCore_valid),
    //   io_msiInfo_bits*（1 根，12 位）
    .io_msiInfo_bits (l2top_io_msiInfo_toCore_bits),
    //   io_clintTime_valid*（1 根，1 位）
    .io_clintTime_valid (l2top_io_clintTime_toCore_valid),
    //   io_clintTime_bits*（1 根，64 位）
    .io_clintTime_bits (l2top_io_clintTime_toCore_bits),
    //   io_reset_vector*（1 根，48 位）
    .io_reset_vector (l2top_io_reset_vector_toCore),
    //   io_traceCoreInterface_fromEncoder*（2 根，2 位）
    .io_traceCoreInterface_fromEncoder_enable (l2top_io_traceCoreInterface_fromCore_fromEncoder_enable),
    .io_traceCoreInterface_fromEncoder_stall (l2top_io_traceCoreInterface_fromCore_fromEncoder_stall),
    //   io_perfEvents_N*（68 根，408 位）
    .io_perfEvents_1_value (l2top_io_perfEvents_1_value),
    .io_perfEvents_2_value (l2top_io_perfEvents_2_value),
    .io_perfEvents_3_value (l2top_io_perfEvents_3_value),
    .io_perfEvents_4_value (l2top_io_perfEvents_4_value),
    .io_perfEvents_5_value (l2top_io_perfEvents_5_value),
    .io_perfEvents_6_value (l2top_io_perfEvents_6_value),
    .io_perfEvents_7_value (l2top_io_perfEvents_7_value),
    .io_perfEvents_8_value (l2top_io_perfEvents_8_value),
    .io_perfEvents_9_value (l2top_io_perfEvents_9_value),
    .io_perfEvents_10_value (l2top_io_perfEvents_10_value),
    .io_perfEvents_11_value (l2top_io_perfEvents_11_value),
    .io_perfEvents_12_value (l2top_io_perfEvents_12_value),
    .io_perfEvents_13_value (l2top_io_perfEvents_13_value),
    .io_perfEvents_14_value (l2top_io_perfEvents_14_value),
    .io_perfEvents_15_value (l2top_io_perfEvents_15_value),
    .io_perfEvents_16_value (l2top_io_perfEvents_16_value),
    .io_perfEvents_17_value (l2top_io_perfEvents_17_value),
    .io_perfEvents_18_value (l2top_io_perfEvents_18_value),
    .io_perfEvents_19_value (l2top_io_perfEvents_19_value),
    .io_perfEvents_20_value (l2top_io_perfEvents_20_value),
    .io_perfEvents_21_value (l2top_io_perfEvents_21_value),
    .io_perfEvents_22_value (l2top_io_perfEvents_22_value),
    .io_perfEvents_23_value (l2top_io_perfEvents_23_value),
    .io_perfEvents_24_value (l2top_io_perfEvents_24_value),
    .io_perfEvents_25_value (l2top_io_perfEvents_25_value),
    .io_perfEvents_26_value (l2top_io_perfEvents_26_value),
    .io_perfEvents_27_value (l2top_io_perfEvents_27_value),
    .io_perfEvents_28_value (l2top_io_perfEvents_28_value),
    .io_perfEvents_29_value (l2top_io_perfEvents_29_value),
    .io_perfEvents_30_value (l2top_io_perfEvents_30_value),
    .io_perfEvents_31_value (l2top_io_perfEvents_31_value),
    .io_perfEvents_32_value (l2top_io_perfEvents_32_value),
    .io_perfEvents_33_value (l2top_io_perfEvents_33_value),
    .io_perfEvents_34_value (l2top_io_perfEvents_34_value),
    .io_perfEvents_35_value (l2top_io_perfEvents_35_value),
    .io_perfEvents_36_value (l2top_io_perfEvents_36_value),
    .io_perfEvents_37_value (l2top_io_perfEvents_37_value),
    .io_perfEvents_38_value (l2top_io_perfEvents_38_value),
    .io_perfEvents_39_value (l2top_io_perfEvents_39_value),
    .io_perfEvents_40_value (l2top_io_perfEvents_40_value),
    .io_perfEvents_41_value (l2top_io_perfEvents_41_value),
    .io_perfEvents_42_value (l2top_io_perfEvents_42_value),
    .io_perfEvents_43_value (l2top_io_perfEvents_43_value),
    .io_perfEvents_44_value (l2top_io_perfEvents_44_value),
    .io_perfEvents_45_value (l2top_io_perfEvents_45_value),
    .io_perfEvents_46_value (l2top_io_perfEvents_46_value),
    .io_perfEvents_47_value (l2top_io_perfEvents_47_value),
    .io_perfEvents_48_value (l2top_io_perfEvents_48_value),
    .io_perfEvents_49_value (l2top_io_perfEvents_49_value),
    .io_perfEvents_50_value (l2top_io_perfEvents_50_value),
    .io_perfEvents_51_value (l2top_io_perfEvents_51_value),
    .io_perfEvents_52_value (l2top_io_perfEvents_52_value),
    .io_perfEvents_53_value (l2top_io_perfEvents_53_value),
    .io_perfEvents_54_value (l2top_io_perfEvents_54_value),
    .io_perfEvents_55_value (l2top_io_perfEvents_55_value),
    .io_perfEvents_56_value (l2top_io_perfEvents_56_value),
    .io_perfEvents_57_value (l2top_io_perfEvents_57_value),
    .io_perfEvents_58_value (l2top_io_perfEvents_58_value),
    .io_perfEvents_59_value (l2top_io_perfEvents_59_value),
    .io_perfEvents_60_value (l2top_io_perfEvents_60_value),
    .io_perfEvents_61_value (l2top_io_perfEvents_61_value),
    .io_perfEvents_62_value (l2top_io_perfEvents_62_value),
    .io_perfEvents_63_value (l2top_io_perfEvents_63_value),
    .io_perfEvents_64_value (l2top_io_perfEvents_64_value),
    .io_perfEvents_65_value (l2top_io_perfEvents_65_value),
    .io_perfEvents_66_value (l2top_io_perfEvents_66_value),
    .io_perfEvents_67_value (l2top_io_perfEvents_67_value),
    .io_perfEvents_68_value (l2top_io_perfEvents_68_value),
    //   io_l2_hint*（3 根，6 位）
    .io_l2_hint_valid (l2top_io_l2_hint_valid),
    .io_l2_hint_bits_sourceId (l2top_io_l2_hint_bits_sourceId),
    .io_l2_hint_bits_isKeyword (l2top_io_l2_hint_bits_isKeyword),
    //   io_l2_tlb*（6 根，57 位）
    .io_l2_tlb_req_req_valid (l2top_io_l2_tlb_req_req_valid),
    .io_l2_tlb_req_req_bits_vaddr (l2top_io_l2_tlb_req_req_bits_vaddr),
    .io_l2_tlb_req_req_bits_cmd (l2top_io_l2_tlb_req_req_bits_cmd),
    .io_l2_tlb_req_req_bits_kill (l2top_io_l2_tlb_req_req_bits_kill),
    .io_l2_tlb_req_req_bits_isPrefetch (l2top_io_l2_tlb_req_req_bits_isPrefetch),
    .io_l2_tlb_req_req_bits_no_translate (l2top_io_l2_tlb_req_req_bits_no_translate),
    //   io_debugTopDown_l2MissMatch*（1 根，1 位）
    .io_debugTopDown_l2MissMatch (l2top_io_debugTopDown_l2MissMatch),
    //   io_topDownInfo_l2Miss*（1 根，1 位）
    .io_topDownInfo_l2Miss (l2top_io_l2Miss),
    //   io_topDownInfo_l3Miss*（1 根，1 位）
    .io_topDownInfo_l3Miss (l2top_io_l3Miss_toCore),
    // → l2top：核 → L2Top：三路 TileLink 请求（L1D / ICache 桥 / PTW）、BEU 错误、L2 TLB / PMP 共享口请求、L2 预取控制、trace 接口、resetInFrontend、停机 / 关键错误 / MSI 应答、ROB 头物理地址（TopDown，取低 36 位）
    //   auto_memBlock_inner*（87 根，1859 位）
    .auto_memBlock_inner_buffers_out_a_valid (core_auto_memBlock_inner_buffers_out_a_valid),
    .auto_memBlock_inner_buffers_out_a_bits_opcode (core_auto_memBlock_inner_buffers_out_a_bits_opcode),
    .auto_memBlock_inner_buffers_out_a_bits_param (core_auto_memBlock_inner_buffers_out_a_bits_param),
    .auto_memBlock_inner_buffers_out_a_bits_size (core_auto_memBlock_inner_buffers_out_a_bits_size),
    .auto_memBlock_inner_buffers_out_a_bits_source (core_auto_memBlock_inner_buffers_out_a_bits_source),
    .auto_memBlock_inner_buffers_out_a_bits_address (core_auto_memBlock_inner_buffers_out_a_bits_address),
    .auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM (core_auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM),
    .auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC (core_auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC),
    .auto_memBlock_inner_buffers_out_a_bits_mask (core_auto_memBlock_inner_buffers_out_a_bits_mask),
    .auto_memBlock_inner_buffers_out_a_bits_data (core_auto_memBlock_inner_buffers_out_a_bits_data),
    .auto_memBlock_inner_buffers_out_a_bits_corrupt (core_auto_memBlock_inner_buffers_out_a_bits_corrupt),
    .auto_memBlock_inner_buffers_out_d_ready (core_auto_memBlock_inner_buffers_out_d_ready),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid (core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param (core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address (core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC (core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM (core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt (core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready (core_auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready (core_auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_icache_out_a_valid (core_auto_memBlock_inner_frontendBridge_icache_out_a_valid),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_param (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_param),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_size (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_size),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_source (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_source),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_address (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_address),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_data (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_data),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_icache_out_d_ready (core_auto_memBlock_inner_frontendBridge_icache_out_d_ready),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready (core_auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready),
    .auto_memBlock_inner_l2_pf_sender_out_addr (core_auto_memBlock_inner_l2_pf_sender_out_addr),
    .auto_memBlock_inner_l2_pf_sender_out_pf_source (core_auto_memBlock_inner_l2_pf_sender_out_pf_source),
    .auto_memBlock_inner_l2_pf_sender_out_addr_valid (core_auto_memBlock_inner_l2_pf_sender_out_addr_valid),
    .auto_memBlock_inner_dcache_client_out_a_valid (core_auto_memBlock_inner_dcache_client_out_a_valid),
    .auto_memBlock_inner_dcache_client_out_a_bits_opcode (core_auto_memBlock_inner_dcache_client_out_a_bits_opcode),
    .auto_memBlock_inner_dcache_client_out_a_bits_param (core_auto_memBlock_inner_dcache_client_out_a_bits_param),
    .auto_memBlock_inner_dcache_client_out_a_bits_size (core_auto_memBlock_inner_dcache_client_out_a_bits_size),
    .auto_memBlock_inner_dcache_client_out_a_bits_source (core_auto_memBlock_inner_dcache_client_out_a_bits_source),
    .auto_memBlock_inner_dcache_client_out_a_bits_address (core_auto_memBlock_inner_dcache_client_out_a_bits_address),
    .auto_memBlock_inner_dcache_client_out_a_bits_user_alias (core_auto_memBlock_inner_dcache_client_out_a_bits_user_alias),
    .auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr (core_auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr),
    .auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource (core_auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource),
    .auto_memBlock_inner_dcache_client_out_a_bits_user_needHint (core_auto_memBlock_inner_dcache_client_out_a_bits_user_needHint),
    .auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword (core_auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword),
    .auto_memBlock_inner_dcache_client_out_a_bits_mask (core_auto_memBlock_inner_dcache_client_out_a_bits_mask),
    .auto_memBlock_inner_dcache_client_out_a_bits_data (core_auto_memBlock_inner_dcache_client_out_a_bits_data),
    .auto_memBlock_inner_dcache_client_out_a_bits_corrupt (core_auto_memBlock_inner_dcache_client_out_a_bits_corrupt),
    .auto_memBlock_inner_dcache_client_out_b_ready (core_auto_memBlock_inner_dcache_client_out_b_ready),
    .auto_memBlock_inner_dcache_client_out_c_valid (core_auto_memBlock_inner_dcache_client_out_c_valid),
    .auto_memBlock_inner_dcache_client_out_c_bits_opcode (core_auto_memBlock_inner_dcache_client_out_c_bits_opcode),
    .auto_memBlock_inner_dcache_client_out_c_bits_param (core_auto_memBlock_inner_dcache_client_out_c_bits_param),
    .auto_memBlock_inner_dcache_client_out_c_bits_size (core_auto_memBlock_inner_dcache_client_out_c_bits_size),
    .auto_memBlock_inner_dcache_client_out_c_bits_source (core_auto_memBlock_inner_dcache_client_out_c_bits_source),
    .auto_memBlock_inner_dcache_client_out_c_bits_address (core_auto_memBlock_inner_dcache_client_out_c_bits_address),
    .auto_memBlock_inner_dcache_client_out_c_bits_user_alias (core_auto_memBlock_inner_dcache_client_out_c_bits_user_alias),
    .auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr (core_auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr),
    .auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource (core_auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource),
    .auto_memBlock_inner_dcache_client_out_c_bits_user_needHint (core_auto_memBlock_inner_dcache_client_out_c_bits_user_needHint),
    .auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword (core_auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword),
    .auto_memBlock_inner_dcache_client_out_c_bits_data (core_auto_memBlock_inner_dcache_client_out_c_bits_data),
    .auto_memBlock_inner_dcache_client_out_c_bits_corrupt (core_auto_memBlock_inner_dcache_client_out_c_bits_corrupt),
    .auto_memBlock_inner_dcache_client_out_d_ready (core_auto_memBlock_inner_dcache_client_out_d_ready),
    .auto_memBlock_inner_dcache_client_out_e_valid (core_auto_memBlock_inner_dcache_client_out_e_valid),
    .auto_memBlock_inner_dcache_client_out_e_bits_sink (core_auto_memBlock_inner_dcache_client_out_e_bits_sink),
    //   io_msiAck*（1 根，1 位）
    .io_msiAck (core_io_msiAck),
    //   io_cpu_halt*（1 根，1 位）
    .io_cpu_halt (core_io_cpu_halt),
    //   io_cpu_critical*（1 根，1 位）
    .io_cpu_critical_error (core_io_cpu_critical_error),
    //   io_resetInFrontend*（1 根，1 位）
    .io_resetInFrontend (core_io_resetInFrontend),
    //   io_traceCoreInterface_toEncoder*（19 根，370 位）
    .io_traceCoreInterface_toEncoder_priv (core_io_traceCoreInterface_toEncoder_priv),
    .io_traceCoreInterface_toEncoder_mstatus (core_io_traceCoreInterface_toEncoder_mstatus),
    .io_traceCoreInterface_toEncoder_trap_cause (core_io_traceCoreInterface_toEncoder_trap_cause),
    .io_traceCoreInterface_toEncoder_trap_tval (core_io_traceCoreInterface_toEncoder_trap_tval),
    .io_traceCoreInterface_toEncoder_groups_0_valid (core_io_traceCoreInterface_toEncoder_groups_0_valid),
    .io_traceCoreInterface_toEncoder_groups_0_bits_iaddr (core_io_traceCoreInterface_toEncoder_groups_0_bits_iaddr),
    .io_traceCoreInterface_toEncoder_groups_0_bits_itype (core_io_traceCoreInterface_toEncoder_groups_0_bits_itype),
    .io_traceCoreInterface_toEncoder_groups_0_bits_iretire (core_io_traceCoreInterface_toEncoder_groups_0_bits_iretire),
    .io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize (core_io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize),
    .io_traceCoreInterface_toEncoder_groups_1_valid (core_io_traceCoreInterface_toEncoder_groups_1_valid),
    .io_traceCoreInterface_toEncoder_groups_1_bits_iaddr (core_io_traceCoreInterface_toEncoder_groups_1_bits_iaddr),
    .io_traceCoreInterface_toEncoder_groups_1_bits_itype (core_io_traceCoreInterface_toEncoder_groups_1_bits_itype),
    .io_traceCoreInterface_toEncoder_groups_1_bits_iretire (core_io_traceCoreInterface_toEncoder_groups_1_bits_iretire),
    .io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize (core_io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize),
    .io_traceCoreInterface_toEncoder_groups_2_valid (core_io_traceCoreInterface_toEncoder_groups_2_valid),
    .io_traceCoreInterface_toEncoder_groups_2_bits_iaddr (core_io_traceCoreInterface_toEncoder_groups_2_bits_iaddr),
    .io_traceCoreInterface_toEncoder_groups_2_bits_itype (core_io_traceCoreInterface_toEncoder_groups_2_bits_itype),
    .io_traceCoreInterface_toEncoder_groups_2_bits_iretire (core_io_traceCoreInterface_toEncoder_groups_2_bits_iretire),
    .io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize (core_io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize),
    //   io_l2PfCtrl_l2*（5 根，14 位）
    .io_l2PfCtrl_l2_pf_master_en (core_io_l2PfCtrl_l2_pf_master_en),
    .io_l2PfCtrl_l2_pf_recv_en (core_io_l2PfCtrl_l2_pf_recv_en),
    .io_l2PfCtrl_l2_pbop_en (core_io_l2PfCtrl_l2_pbop_en),
    .io_l2PfCtrl_l2_vbop_en (core_io_l2PfCtrl_l2_vbop_en),
    .io_l2PfCtrl_l2_pf_delay_latency (core_io_l2PfCtrl_l2_pf_delay_latency),
    //   io_beu_errors*（6 根，147 位）
    .io_beu_errors_icache_ecc_error_valid (core_io_beu_errors_icache_ecc_error_valid),
    .io_beu_errors_icache_ecc_error_bits (core_io_beu_errors_icache_ecc_error_bits),
    .io_beu_errors_dcache_ecc_error_valid (core_io_beu_errors_dcache_ecc_error_valid),
    .io_beu_errors_dcache_ecc_error_bits (core_io_beu_errors_dcache_ecc_error_bits),
    .io_beu_errors_uncache_ecc_error_valid (core_io_beu_errors_uncache_ecc_error_valid),
    .io_beu_errors_uncache_ecc_error_bits (core_io_beu_errors_uncache_ecc_error_bits),
    //   io_l2_tlb*（7 根，55 位）
    .io_l2_tlb_req_resp_valid (core_io_l2_tlb_req_resp_valid),
    .io_l2_tlb_req_resp_bits_paddr_0 (core_io_l2_tlb_req_resp_bits_paddr_0),
    .io_l2_tlb_req_resp_bits_pbmt_0 (core_io_l2_tlb_req_resp_bits_pbmt_0),
    .io_l2_tlb_req_resp_bits_miss (core_io_l2_tlb_req_resp_bits_miss),
    .io_l2_tlb_req_resp_bits_excp_0_gpf_ld (core_io_l2_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_l2_tlb_req_resp_bits_excp_0_pf_ld (core_io_l2_tlb_req_resp_bits_excp_0_pf_ld),
    .io_l2_tlb_req_resp_bits_excp_0_af_ld (core_io_l2_tlb_req_resp_bits_excp_0_af_ld),
    //   io_l2_pmp*（2 根，2 位）
    .io_l2_pmp_resp_ld (core_io_l2_pmp_resp_ld),
    .io_l2_pmp_resp_mmio (core_io_l2_pmp_resp_mmio),
    // ← intBuffer_3：同步后的 NMI 进核
    //   auto_memBlock_inner*（2 根，2 位）
    .auto_memBlock_inner_nmi_int_sink_in_0 (intBuffer_3_auto_out_0),
    .auto_memBlock_inner_nmi_int_sink_in_1 (intBuffer_3_auto_out_1),
    // ← intBuffer_1：同步后的 PLIC 中断进核（MemBlock 的 plic 端口）
    //   auto_memBlock_inner*（2 根，2 位）
    .auto_memBlock_inner_plic_int_sink_in_1_0 (intBuffer_1_auto_out_1_0),
    .auto_memBlock_inner_plic_int_sink_in_0_0 (intBuffer_1_auto_out_0_0),
    // ← intBuffer_2：同步后的 debug 中断进核
    //   auto_memBlock_inner*（1 根，1 位）
    .auto_memBlock_inner_debug_int_sink_in_0 (intBuffer_2_auto_out_0),
    // ← intBuffer：同步后的 CLINT 中断进核（MemBlock 的 clint 端口）
    //   auto_memBlock_inner*（2 根，2 位）
    .auto_memBlock_inner_clint_int_sink_in_0 (intBuffer_auto_out_0),
    .auto_memBlock_inner_clint_int_sink_in_1 (intBuffer_auto_out_1),
    // ← 常量：L2 刷新完成恒 0（本配置不做 L2 刷新）
    //   io_l2_flush*（1 根，1 位）
    .io_l2_flush_done (1'h0),
    // → 悬空：L2 刷新请求 / 掉电请求（本配置不接）
    //   io_l2_flush*（1 根，1 位）
    .io_l2_flush_en (),
    //   io_power_down*（1 根，1 位）
    .io_power_down_en (),
    // → l2top / 顶层：核 → L2Top：三路 TileLink 请求（L1D / ICache 桥 / PTW）、BEU 错误、L2 TLB / PMP 共享口请求、L2 预取控制、trace 接口、resetInFrontend、停机 / 关键错误 / MSI 应答、ROB 头物理地址（TopDown，取低 36 位）；difftest 网关（gatewayIn_packed_*）与 TopDown 的 ROB 头物理地址（整宽直通）
    //   io_debugTopDown_robHeadPaddr*（2 根，49 位）
    .io_debugTopDown_robHeadPaddr_valid (core_io_debugTopDown_robHeadPaddr_valid),
    .io_debugTopDown_robHeadPaddr_bits (core_io_debugTopDown_robHeadPaddr_bits),
    // ← 顶层：时钟 / 复位、DFT 控制、TopDown 的 L3 missMatch
    //   io_debugTopDown_l3MissMatch*（1 根，1 位）
    .io_debugTopDown_l3MissMatch (io_debugTopDown_l3MissMatch),
    //   io_dft_ram*（6 根，6 位）
    .io_dft_ram_hold (io_dft_ram_hold),
    .io_dft_ram_bypass (io_dft_ram_bypass),
    .io_dft_ram_bp_clken (io_dft_ram_bp_clken),
    .io_dft_ram_aux_clk (io_dft_ram_aux_clk),
    .io_dft_ram_aux_ckbp (io_dft_ram_aux_ckbp),
    .io_dft_ram_mcp_hold (io_dft_ram_mcp_hold),
    //   io_dft_cgen*（1 根，1 位）
    .io_dft_cgen (io_dft_cgen),
    // → 顶层：difftest 网关（gatewayIn_packed_*）与 TopDown 的 ROB 头物理地址（整宽直通）
    //   gatewayIn_packed_N*（61 根，65358 位）
    .gatewayIn_packed_0_bore (gatewayIn_packed_0_bore),
    .gatewayIn_packed_1_bore (gatewayIn_packed_1_bore),
    .gatewayIn_packed_2_bore (gatewayIn_packed_2_bore),
    .gatewayIn_packed_3_bore (gatewayIn_packed_3_bore),
    .gatewayIn_packed_4_bore (gatewayIn_packed_4_bore),
    .gatewayIn_packed_5_bore (gatewayIn_packed_5_bore),
    .gatewayIn_packed_6_bore (gatewayIn_packed_6_bore),
    .gatewayIn_packed_7_bore (gatewayIn_packed_7_bore),
    .gatewayIn_packed_8_bore (gatewayIn_packed_8_bore),
    .gatewayIn_packed_9_bore (gatewayIn_packed_9_bore),
    .gatewayIn_packed_10_bore (gatewayIn_packed_10_bore),
    .gatewayIn_packed_11_bore (gatewayIn_packed_11_bore),
    .gatewayIn_packed_12_bore (gatewayIn_packed_12_bore),
    .gatewayIn_packed_13_bore (gatewayIn_packed_13_bore),
    .gatewayIn_packed_14_bore (gatewayIn_packed_14_bore),
    .gatewayIn_packed_15_bore (gatewayIn_packed_15_bore),
    .gatewayIn_packed_16_bore (gatewayIn_packed_16_bore),
    .gatewayIn_packed_17_bore (gatewayIn_packed_17_bore),
    .gatewayIn_packed_18_bore (gatewayIn_packed_18_bore),
    .gatewayIn_packed_19_bore (gatewayIn_packed_19_bore),
    .gatewayIn_packed_20_bore (gatewayIn_packed_20_bore),
    .gatewayIn_packed_21_bore (gatewayIn_packed_21_bore),
    .gatewayIn_packed_22_bore (gatewayIn_packed_22_bore),
    .gatewayIn_packed_23_bore (gatewayIn_packed_23_bore),
    .gatewayIn_packed_24_bore (gatewayIn_packed_24_bore),
    .gatewayIn_packed_25_bore (gatewayIn_packed_25_bore),
    .gatewayIn_packed_26_bore (gatewayIn_packed_26_bore),
    .gatewayIn_packed_27_bore (gatewayIn_packed_27_bore),
    .gatewayIn_packed_28_bore (gatewayIn_packed_28_bore),
    .gatewayIn_packed_29_bore (gatewayIn_packed_29_bore),
    .gatewayIn_packed_30_bore (gatewayIn_packed_30_bore),
    .gatewayIn_packed_31_bore (gatewayIn_packed_31_bore),
    .gatewayIn_packed_32_bore (gatewayIn_packed_32_bore),
    .gatewayIn_packed_33_bore (gatewayIn_packed_33_bore),
    .gatewayIn_packed_34_bore (gatewayIn_packed_34_bore),
    .gatewayIn_packed_35_bore (gatewayIn_packed_35_bore),
    .gatewayIn_packed_36_bore (gatewayIn_packed_36_bore),
    .gatewayIn_packed_37_bore (gatewayIn_packed_37_bore),
    .gatewayIn_packed_38_bore (gatewayIn_packed_38_bore),
    .gatewayIn_packed_39_bore (gatewayIn_packed_39_bore),
    .gatewayIn_packed_40_bore (gatewayIn_packed_40_bore),
    .gatewayIn_packed_41_bore (gatewayIn_packed_41_bore),
    .gatewayIn_packed_42_bore (gatewayIn_packed_42_bore),
    .gatewayIn_packed_43_bore (gatewayIn_packed_43_bore),
    .gatewayIn_packed_44_bore (gatewayIn_packed_44_bore),
    .gatewayIn_packed_45_bore (gatewayIn_packed_45_bore),
    .gatewayIn_packed_46_bore (gatewayIn_packed_46_bore),
    .gatewayIn_packed_47_bore (gatewayIn_packed_47_bore),
    .gatewayIn_packed_48_bore (gatewayIn_packed_48_bore),
    .gatewayIn_packed_49_bore (gatewayIn_packed_49_bore),
    .gatewayIn_packed_50_bore (gatewayIn_packed_50_bore),
    .gatewayIn_packed_51_bore (gatewayIn_packed_51_bore),
    .gatewayIn_packed_52_bore (gatewayIn_packed_52_bore),
    .gatewayIn_packed_53_bore (gatewayIn_packed_53_bore),
    .gatewayIn_packed_54_bore (gatewayIn_packed_54_bore),
    .gatewayIn_packed_55_bore (gatewayIn_packed_55_bore),
    .gatewayIn_packed_56_bore (gatewayIn_packed_56_bore),
    .gatewayIn_packed_57_bore (gatewayIn_packed_57_bore),
    .gatewayIn_packed_58_bore (gatewayIn_packed_58_bore),
    .gatewayIn_packed_59_bore (gatewayIn_packed_59_bore),
    .gatewayIn_packed_60_bore (gatewayIn_packed_60_bore)
  );

  // ===========================================================================
  // 子模块 L2Top l2top（L2Top：L2 cache、TileLink → CHI 桥、MMIO 桥、中断节点、BEU）
  //   382 个端口：输入 174 / 输出 208
  // ===========================================================================
  L2Top l2top (
    .clock (clock),
    .reset (reset),
    // ← core：核 → L2Top：三路 TileLink 请求（L1D / ICache 桥 / PTW）、BEU 错误、L2 TLB / PMP 共享口请求、L2 预取控制、trace 接口、resetInFrontend、停机 / 关键错误 / MSI 应答、ROB 头物理地址（TopDown，取低 36 位）
    //   auto_inner_buffers*（22 根，220 位）
    .auto_inner_buffers_out_a_ready (core_auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready),
    .auto_inner_buffers_out_d_valid (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid),
    .auto_inner_buffers_out_d_bits_opcode (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode),
    .auto_inner_buffers_out_d_bits_param (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param),
    .auto_inner_buffers_out_d_bits_size (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size),
    .auto_inner_buffers_out_d_bits_source (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source),
    .auto_inner_buffers_out_d_bits_sink (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink),
    .auto_inner_buffers_out_d_bits_denied (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied),
    .auto_inner_buffers_out_d_bits_data (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data),
    .auto_inner_buffers_out_d_bits_corrupt (core_auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt),
    .auto_inner_buffers_in_a_valid (core_auto_memBlock_inner_buffers_out_a_valid),
    .auto_inner_buffers_in_a_bits_opcode (core_auto_memBlock_inner_buffers_out_a_bits_opcode),
    .auto_inner_buffers_in_a_bits_param (core_auto_memBlock_inner_buffers_out_a_bits_param),
    .auto_inner_buffers_in_a_bits_size (core_auto_memBlock_inner_buffers_out_a_bits_size),
    .auto_inner_buffers_in_a_bits_source (core_auto_memBlock_inner_buffers_out_a_bits_source),
    .auto_inner_buffers_in_a_bits_address (core_auto_memBlock_inner_buffers_out_a_bits_address),
    .auto_inner_buffers_in_a_bits_user_memBackType_MM (core_auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM),
    .auto_inner_buffers_in_a_bits_user_memPageType_NC (core_auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC),
    .auto_inner_buffers_in_a_bits_mask (core_auto_memBlock_inner_buffers_out_a_bits_mask),
    .auto_inner_buffers_in_a_bits_data (core_auto_memBlock_inner_buffers_out_a_bits_data),
    .auto_inner_buffers_in_a_bits_corrupt (core_auto_memBlock_inner_buffers_out_a_bits_corrupt),
    .auto_inner_buffers_in_d_ready (core_auto_memBlock_inner_buffers_out_d_ready),
    //   auto_inner_l2cache*（3 根，70 位）
    .auto_inner_l2cache_pf_recv_in_addr (core_auto_memBlock_inner_l2_pf_sender_out_addr),
    .auto_inner_l2cache_pf_recv_in_pf_source (core_auto_memBlock_inner_l2_pf_sender_out_pf_source),
    .auto_inner_l2cache_pf_recv_in_addr_valid (core_auto_memBlock_inner_l2_pf_sender_out_addr_valid),
    //   auto_inner_i*（7 根，56 位）
    .auto_inner_i_mmio_buffer_in_a_valid (core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid),
    .auto_inner_i_mmio_buffer_in_a_bits_param (core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param),
    .auto_inner_i_mmio_buffer_in_a_bits_address (core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address),
    .auto_inner_i_mmio_buffer_in_a_bits_user_memPageType_NC (core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC),
    .auto_inner_i_mmio_buffer_in_a_bits_user_memBackType_MM (core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM),
    .auto_inner_i_mmio_buffer_in_a_bits_corrupt (core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt),
    .auto_inner_i_mmio_buffer_in_d_ready (core_auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready),
    //   auto_inner_ptw*（11 根，358 位）
    .auto_inner_ptw_to_l2_buffer_in_a_valid (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_opcode (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_param (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_size (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_source (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_address (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_mask (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_data (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt (core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt),
    .auto_inner_ptw_to_l2_buffer_in_d_ready (core_auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready),
    //   auto_inner_logger*（44 根，1155 位）
    .auto_inner_logger_in_1_a_valid (core_auto_memBlock_inner_frontendBridge_icache_out_a_valid),
    .auto_inner_logger_in_1_a_bits_opcode (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode),
    .auto_inner_logger_in_1_a_bits_param (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_param),
    .auto_inner_logger_in_1_a_bits_size (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_size),
    .auto_inner_logger_in_1_a_bits_source (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_source),
    .auto_inner_logger_in_1_a_bits_address (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_address),
    .auto_inner_logger_in_1_a_bits_user_alias (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias),
    .auto_inner_logger_in_1_a_bits_user_reqSource (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource),
    .auto_inner_logger_in_1_a_bits_user_needHint (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint),
    .auto_inner_logger_in_1_a_bits_mask (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask),
    .auto_inner_logger_in_1_a_bits_data (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_data),
    .auto_inner_logger_in_1_a_bits_corrupt (core_auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt),
    .auto_inner_logger_in_1_d_ready (core_auto_memBlock_inner_frontendBridge_icache_out_d_ready),
    .auto_inner_logger_in_0_a_valid (core_auto_memBlock_inner_dcache_client_out_a_valid),
    .auto_inner_logger_in_0_a_bits_opcode (core_auto_memBlock_inner_dcache_client_out_a_bits_opcode),
    .auto_inner_logger_in_0_a_bits_param (core_auto_memBlock_inner_dcache_client_out_a_bits_param),
    .auto_inner_logger_in_0_a_bits_size (core_auto_memBlock_inner_dcache_client_out_a_bits_size),
    .auto_inner_logger_in_0_a_bits_source (core_auto_memBlock_inner_dcache_client_out_a_bits_source),
    .auto_inner_logger_in_0_a_bits_address (core_auto_memBlock_inner_dcache_client_out_a_bits_address),
    .auto_inner_logger_in_0_a_bits_user_alias (core_auto_memBlock_inner_dcache_client_out_a_bits_user_alias),
    .auto_inner_logger_in_0_a_bits_user_vaddr (core_auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr),
    .auto_inner_logger_in_0_a_bits_user_reqSource (core_auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource),
    .auto_inner_logger_in_0_a_bits_user_needHint (core_auto_memBlock_inner_dcache_client_out_a_bits_user_needHint),
    .auto_inner_logger_in_0_a_bits_echo_isKeyword (core_auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword),
    .auto_inner_logger_in_0_a_bits_mask (core_auto_memBlock_inner_dcache_client_out_a_bits_mask),
    .auto_inner_logger_in_0_a_bits_data (core_auto_memBlock_inner_dcache_client_out_a_bits_data),
    .auto_inner_logger_in_0_a_bits_corrupt (core_auto_memBlock_inner_dcache_client_out_a_bits_corrupt),
    .auto_inner_logger_in_0_b_ready (core_auto_memBlock_inner_dcache_client_out_b_ready),
    .auto_inner_logger_in_0_c_valid (core_auto_memBlock_inner_dcache_client_out_c_valid),
    .auto_inner_logger_in_0_c_bits_opcode (core_auto_memBlock_inner_dcache_client_out_c_bits_opcode),
    .auto_inner_logger_in_0_c_bits_param (core_auto_memBlock_inner_dcache_client_out_c_bits_param),
    .auto_inner_logger_in_0_c_bits_size (core_auto_memBlock_inner_dcache_client_out_c_bits_size),
    .auto_inner_logger_in_0_c_bits_source (core_auto_memBlock_inner_dcache_client_out_c_bits_source),
    .auto_inner_logger_in_0_c_bits_address (core_auto_memBlock_inner_dcache_client_out_c_bits_address),
    .auto_inner_logger_in_0_c_bits_user_alias (core_auto_memBlock_inner_dcache_client_out_c_bits_user_alias),
    .auto_inner_logger_in_0_c_bits_user_vaddr (core_auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr),
    .auto_inner_logger_in_0_c_bits_user_reqSource (core_auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource),
    .auto_inner_logger_in_0_c_bits_user_needHint (core_auto_memBlock_inner_dcache_client_out_c_bits_user_needHint),
    .auto_inner_logger_in_0_c_bits_echo_isKeyword (core_auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword),
    .auto_inner_logger_in_0_c_bits_data (core_auto_memBlock_inner_dcache_client_out_c_bits_data),
    .auto_inner_logger_in_0_c_bits_corrupt (core_auto_memBlock_inner_dcache_client_out_c_bits_corrupt),
    .auto_inner_logger_in_0_d_ready (core_auto_memBlock_inner_dcache_client_out_d_ready),
    .auto_inner_logger_in_0_e_valid (core_auto_memBlock_inner_dcache_client_out_e_valid),
    .auto_inner_logger_in_0_e_bits_sink (core_auto_memBlock_inner_dcache_client_out_e_bits_sink),
    //   io_beu_errors*（6 根，147 位）
    .io_beu_errors_icache_ecc_error_valid (core_io_beu_errors_icache_ecc_error_valid),
    .io_beu_errors_icache_ecc_error_bits (core_io_beu_errors_icache_ecc_error_bits),
    .io_beu_errors_dcache_ecc_error_valid (core_io_beu_errors_dcache_ecc_error_valid),
    .io_beu_errors_dcache_ecc_error_bits (core_io_beu_errors_dcache_ecc_error_bits),
    .io_beu_errors_uncache_ecc_error_valid (core_io_beu_errors_uncache_ecc_error_valid),
    .io_beu_errors_uncache_ecc_error_bits (core_io_beu_errors_uncache_ecc_error_bits),
    //   io_msiAck_fromCore*（1 根，1 位）
    .io_msiAck_fromCore (core_io_msiAck),
    //   io_cpu_halt*（1 根，1 位）
    .io_cpu_halt_fromCore (core_io_cpu_halt),
    //   io_cpu_critical*（1 根，1 位）
    .io_cpu_critical_error_fromCore (core_io_cpu_critical_error),
    //   io_hartIsInReset_resetInFrontend*（1 根，1 位）
    .io_hartIsInReset_resetInFrontend (core_io_resetInFrontend),
    //   io_traceCoreInterface_fromCore*（19 根，370 位）
    .io_traceCoreInterface_fromCore_toEncoder_priv (core_io_traceCoreInterface_toEncoder_priv),
    .io_traceCoreInterface_fromCore_toEncoder_mstatus (core_io_traceCoreInterface_toEncoder_mstatus),
    .io_traceCoreInterface_fromCore_toEncoder_trap_cause (core_io_traceCoreInterface_toEncoder_trap_cause),
    .io_traceCoreInterface_fromCore_toEncoder_trap_tval (core_io_traceCoreInterface_toEncoder_trap_tval),
    .io_traceCoreInterface_fromCore_toEncoder_groups_0_valid (core_io_traceCoreInterface_toEncoder_groups_0_valid),
    .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr (core_io_traceCoreInterface_toEncoder_groups_0_bits_iaddr),
    .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype (core_io_traceCoreInterface_toEncoder_groups_0_bits_itype),
    .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire (core_io_traceCoreInterface_toEncoder_groups_0_bits_iretire),
    .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize (core_io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize),
    .io_traceCoreInterface_fromCore_toEncoder_groups_1_valid (core_io_traceCoreInterface_toEncoder_groups_1_valid),
    .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr (core_io_traceCoreInterface_toEncoder_groups_1_bits_iaddr),
    .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype (core_io_traceCoreInterface_toEncoder_groups_1_bits_itype),
    .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire (core_io_traceCoreInterface_toEncoder_groups_1_bits_iretire),
    .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize (core_io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize),
    .io_traceCoreInterface_fromCore_toEncoder_groups_2_valid (core_io_traceCoreInterface_toEncoder_groups_2_valid),
    .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr (core_io_traceCoreInterface_toEncoder_groups_2_bits_iaddr),
    .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype (core_io_traceCoreInterface_toEncoder_groups_2_bits_itype),
    .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire (core_io_traceCoreInterface_toEncoder_groups_2_bits_iretire),
    .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize (core_io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize),
    //   io_debugTopDown_robHeadPaddr*（2 根，37 位）
    .io_debugTopDown_robHeadPaddr_valid (core_io_debugTopDown_robHeadPaddr_valid),
    .io_debugTopDown_robHeadPaddr_bits (core_io_debugTopDown_robHeadPaddr_bits[35:0]),
    //   io_pfCtrlFromCore_l2*（5 根，14 位）
    .io_pfCtrlFromCore_l2_pf_master_en (core_io_l2PfCtrl_l2_pf_master_en),
    .io_pfCtrlFromCore_l2_pf_recv_en (core_io_l2PfCtrl_l2_pf_recv_en),
    .io_pfCtrlFromCore_l2_pbop_en (core_io_l2PfCtrl_l2_pbop_en),
    .io_pfCtrlFromCore_l2_vbop_en (core_io_l2PfCtrl_l2_vbop_en),
    .io_pfCtrlFromCore_l2_pf_delay_latency (core_io_l2PfCtrl_l2_pf_delay_latency),
    //   io_l2_tlb*（7 根，55 位）
    .io_l2_tlb_req_resp_valid (core_io_l2_tlb_req_resp_valid),
    .io_l2_tlb_req_resp_bits_paddr_0 (core_io_l2_tlb_req_resp_bits_paddr_0),
    .io_l2_tlb_req_resp_bits_pbmt_0 (core_io_l2_tlb_req_resp_bits_pbmt_0),
    .io_l2_tlb_req_resp_bits_miss (core_io_l2_tlb_req_resp_bits_miss),
    .io_l2_tlb_req_resp_bits_excp_0_gpf_ld (core_io_l2_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_l2_tlb_req_resp_bits_excp_0_pf_ld (core_io_l2_tlb_req_resp_bits_excp_0_pf_ld),
    .io_l2_tlb_req_resp_bits_excp_0_af_ld (core_io_l2_tlb_req_resp_bits_excp_0_af_ld),
    //   io_l2_pmp*（2 根，2 位）
    .io_l2_pmp_resp_ld (core_io_l2_pmp_resp_ld),
    .io_l2_pmp_resp_mmio (core_io_l2_pmp_resp_mmio),
    // → core：L2Top → 核：三路 TileLink 回包与反压、hartId（取低 6 位）、复位向量、MSI、CLINT 时间、L2 预取提示、L2 TLB 共享口回应、TopDown 的 L2 missMatch、L2 性能事件
    //   auto_inner_buffers*（20 根，200 位）
    .auto_inner_buffers_out_a_valid (l2top_auto_inner_buffers_out_a_valid),
    .auto_inner_buffers_out_a_bits_opcode (l2top_auto_inner_buffers_out_a_bits_opcode),
    .auto_inner_buffers_out_a_bits_param (l2top_auto_inner_buffers_out_a_bits_param),
    .auto_inner_buffers_out_a_bits_size (l2top_auto_inner_buffers_out_a_bits_size),
    .auto_inner_buffers_out_a_bits_source (l2top_auto_inner_buffers_out_a_bits_source),
    .auto_inner_buffers_out_a_bits_address (l2top_auto_inner_buffers_out_a_bits_address),
    .auto_inner_buffers_out_a_bits_mask (l2top_auto_inner_buffers_out_a_bits_mask),
    .auto_inner_buffers_out_a_bits_data (l2top_auto_inner_buffers_out_a_bits_data),
    .auto_inner_buffers_out_a_bits_corrupt (l2top_auto_inner_buffers_out_a_bits_corrupt),
    .auto_inner_buffers_out_d_ready (l2top_auto_inner_buffers_out_d_ready),
    .auto_inner_buffers_in_a_ready (l2top_auto_inner_buffers_in_a_ready),
    .auto_inner_buffers_in_d_valid (l2top_auto_inner_buffers_in_d_valid),
    .auto_inner_buffers_in_d_bits_opcode (l2top_auto_inner_buffers_in_d_bits_opcode),
    .auto_inner_buffers_in_d_bits_param (l2top_auto_inner_buffers_in_d_bits_param),
    .auto_inner_buffers_in_d_bits_size (l2top_auto_inner_buffers_in_d_bits_size),
    .auto_inner_buffers_in_d_bits_source (l2top_auto_inner_buffers_in_d_bits_source),
    .auto_inner_buffers_in_d_bits_sink (l2top_auto_inner_buffers_in_d_bits_sink),
    .auto_inner_buffers_in_d_bits_denied (l2top_auto_inner_buffers_in_d_bits_denied),
    .auto_inner_buffers_in_d_bits_data (l2top_auto_inner_buffers_in_d_bits_data),
    .auto_inner_buffers_in_d_bits_corrupt (l2top_auto_inner_buffers_in_d_bits_corrupt),
    //   auto_inner_intBuffer*（1 根，1 位）
    .auto_inner_intBuffer_out_0 (l2top_auto_inner_intBuffer_out_0),
    //   auto_inner_i*（10 根，78 位）
    .auto_inner_i_mmio_buffer_in_a_ready (l2top_auto_inner_i_mmio_buffer_in_a_ready),
    .auto_inner_i_mmio_buffer_in_d_valid (l2top_auto_inner_i_mmio_buffer_in_d_valid),
    .auto_inner_i_mmio_buffer_in_d_bits_opcode (l2top_auto_inner_i_mmio_buffer_in_d_bits_opcode),
    .auto_inner_i_mmio_buffer_in_d_bits_param (l2top_auto_inner_i_mmio_buffer_in_d_bits_param),
    .auto_inner_i_mmio_buffer_in_d_bits_size (l2top_auto_inner_i_mmio_buffer_in_d_bits_size),
    .auto_inner_i_mmio_buffer_in_d_bits_source (l2top_auto_inner_i_mmio_buffer_in_d_bits_source),
    .auto_inner_i_mmio_buffer_in_d_bits_sink (l2top_auto_inner_i_mmio_buffer_in_d_bits_sink),
    .auto_inner_i_mmio_buffer_in_d_bits_denied (l2top_auto_inner_i_mmio_buffer_in_d_bits_denied),
    .auto_inner_i_mmio_buffer_in_d_bits_data (l2top_auto_inner_i_mmio_buffer_in_d_bits_data),
    .auto_inner_i_mmio_buffer_in_d_bits_corrupt (l2top_auto_inner_i_mmio_buffer_in_d_bits_corrupt),
    //   auto_inner_ptw*（10 根，283 位）
    .auto_inner_ptw_to_l2_buffer_in_a_ready (l2top_auto_inner_ptw_to_l2_buffer_in_a_ready),
    .auto_inner_ptw_to_l2_buffer_in_d_valid (l2top_auto_inner_ptw_to_l2_buffer_in_d_valid),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_opcode (l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_opcode),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_param (l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_param),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_size (l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_size),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_source (l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_source),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_sink (l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_sink),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_denied (l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_denied),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_data (l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_data),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt (l2top_auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt),
    //   auto_inner_logger*（32 根，923 位）
    .auto_inner_logger_in_1_a_ready (l2top_auto_inner_logger_in_1_a_ready),
    .auto_inner_logger_in_1_d_valid (l2top_auto_inner_logger_in_1_d_valid),
    .auto_inner_logger_in_1_d_bits_opcode (l2top_auto_inner_logger_in_1_d_bits_opcode),
    .auto_inner_logger_in_1_d_bits_param (l2top_auto_inner_logger_in_1_d_bits_param),
    .auto_inner_logger_in_1_d_bits_size (l2top_auto_inner_logger_in_1_d_bits_size),
    .auto_inner_logger_in_1_d_bits_source (l2top_auto_inner_logger_in_1_d_bits_source),
    .auto_inner_logger_in_1_d_bits_sink (l2top_auto_inner_logger_in_1_d_bits_sink),
    .auto_inner_logger_in_1_d_bits_denied (l2top_auto_inner_logger_in_1_d_bits_denied),
    .auto_inner_logger_in_1_d_bits_data (l2top_auto_inner_logger_in_1_d_bits_data),
    .auto_inner_logger_in_1_d_bits_corrupt (l2top_auto_inner_logger_in_1_d_bits_corrupt),
    .auto_inner_logger_in_0_a_ready (l2top_auto_inner_logger_in_0_a_ready),
    .auto_inner_logger_in_0_b_valid (l2top_auto_inner_logger_in_0_b_valid),
    .auto_inner_logger_in_0_b_bits_opcode (l2top_auto_inner_logger_in_0_b_bits_opcode),
    .auto_inner_logger_in_0_b_bits_param (l2top_auto_inner_logger_in_0_b_bits_param),
    .auto_inner_logger_in_0_b_bits_size (l2top_auto_inner_logger_in_0_b_bits_size),
    .auto_inner_logger_in_0_b_bits_source (l2top_auto_inner_logger_in_0_b_bits_source),
    .auto_inner_logger_in_0_b_bits_address (l2top_auto_inner_logger_in_0_b_bits_address),
    .auto_inner_logger_in_0_b_bits_mask (l2top_auto_inner_logger_in_0_b_bits_mask),
    .auto_inner_logger_in_0_b_bits_data (l2top_auto_inner_logger_in_0_b_bits_data),
    .auto_inner_logger_in_0_b_bits_corrupt (l2top_auto_inner_logger_in_0_b_bits_corrupt),
    .auto_inner_logger_in_0_c_ready (l2top_auto_inner_logger_in_0_c_ready),
    .auto_inner_logger_in_0_d_valid (l2top_auto_inner_logger_in_0_d_valid),
    .auto_inner_logger_in_0_d_bits_opcode (l2top_auto_inner_logger_in_0_d_bits_opcode),
    .auto_inner_logger_in_0_d_bits_param (l2top_auto_inner_logger_in_0_d_bits_param),
    .auto_inner_logger_in_0_d_bits_size (l2top_auto_inner_logger_in_0_d_bits_size),
    .auto_inner_logger_in_0_d_bits_source (l2top_auto_inner_logger_in_0_d_bits_source),
    .auto_inner_logger_in_0_d_bits_sink (l2top_auto_inner_logger_in_0_d_bits_sink),
    .auto_inner_logger_in_0_d_bits_denied (l2top_auto_inner_logger_in_0_d_bits_denied),
    .auto_inner_logger_in_0_d_bits_echo_isKeyword (l2top_auto_inner_logger_in_0_d_bits_echo_isKeyword),
    .auto_inner_logger_in_0_d_bits_data (l2top_auto_inner_logger_in_0_d_bits_data),
    .auto_inner_logger_in_0_d_bits_corrupt (l2top_auto_inner_logger_in_0_d_bits_corrupt),
    .auto_inner_logger_in_0_e_ready (l2top_auto_inner_logger_in_0_e_ready),
    //   io_reset_vector*（1 根，48 位）
    .io_reset_vector_toCore (l2top_io_reset_vector_toCore),
    //   io_hartId_toCore*（1 根，64 位）
    .io_hartId_toCore (l2top_io_hartId_toCore),
    //   io_msiInfo_toCore*（2 根，13 位）
    .io_msiInfo_toCore_valid (l2top_io_msiInfo_toCore_valid),
    .io_msiInfo_toCore_bits (l2top_io_msiInfo_toCore_bits),
    //   io_traceCoreInterface_fromCore*（2 根，2 位）
    .io_traceCoreInterface_fromCore_fromEncoder_enable (l2top_io_traceCoreInterface_fromCore_fromEncoder_enable),
    .io_traceCoreInterface_fromCore_fromEncoder_stall (l2top_io_traceCoreInterface_fromCore_fromEncoder_stall),
    //   io_debugTopDown_l2MissMatch*（1 根，1 位）
    .io_debugTopDown_l2MissMatch (l2top_io_debugTopDown_l2MissMatch),
    //   io_l2Miss*（1 根，1 位）
    .io_l2Miss (l2top_io_l2Miss),
    //   io_l3Miss_toCore*（1 根，1 位）
    .io_l3Miss_toCore (l2top_io_l3Miss_toCore),
    //   io_clintTime_toCore*（2 根，65 位）
    .io_clintTime_toCore_valid (l2top_io_clintTime_toCore_valid),
    .io_clintTime_toCore_bits (l2top_io_clintTime_toCore_bits),
    //   io_l2_tlb*（6 根，57 位）
    .io_l2_tlb_req_req_valid (l2top_io_l2_tlb_req_req_valid),
    .io_l2_tlb_req_req_bits_vaddr (l2top_io_l2_tlb_req_req_bits_vaddr),
    .io_l2_tlb_req_req_bits_cmd (l2top_io_l2_tlb_req_req_bits_cmd),
    .io_l2_tlb_req_req_bits_kill (l2top_io_l2_tlb_req_req_bits_kill),
    .io_l2_tlb_req_req_bits_isPrefetch (l2top_io_l2_tlb_req_req_bits_isPrefetch),
    .io_l2_tlb_req_req_bits_no_translate (l2top_io_l2_tlb_req_req_bits_no_translate),
    //   io_l2_hint*（3 根，6 位）
    .io_l2_hint_valid (l2top_io_l2_hint_valid),
    .io_l2_hint_bits_sourceId (l2top_io_l2_hint_bits_sourceId),
    .io_l2_hint_bits_isKeyword (l2top_io_l2_hint_bits_isKeyword),
    //   io_perfEvents_N*（68 根，408 位）
    .io_perfEvents_1_value (l2top_io_perfEvents_1_value),
    .io_perfEvents_2_value (l2top_io_perfEvents_2_value),
    .io_perfEvents_3_value (l2top_io_perfEvents_3_value),
    .io_perfEvents_4_value (l2top_io_perfEvents_4_value),
    .io_perfEvents_5_value (l2top_io_perfEvents_5_value),
    .io_perfEvents_6_value (l2top_io_perfEvents_6_value),
    .io_perfEvents_7_value (l2top_io_perfEvents_7_value),
    .io_perfEvents_8_value (l2top_io_perfEvents_8_value),
    .io_perfEvents_9_value (l2top_io_perfEvents_9_value),
    .io_perfEvents_10_value (l2top_io_perfEvents_10_value),
    .io_perfEvents_11_value (l2top_io_perfEvents_11_value),
    .io_perfEvents_12_value (l2top_io_perfEvents_12_value),
    .io_perfEvents_13_value (l2top_io_perfEvents_13_value),
    .io_perfEvents_14_value (l2top_io_perfEvents_14_value),
    .io_perfEvents_15_value (l2top_io_perfEvents_15_value),
    .io_perfEvents_16_value (l2top_io_perfEvents_16_value),
    .io_perfEvents_17_value (l2top_io_perfEvents_17_value),
    .io_perfEvents_18_value (l2top_io_perfEvents_18_value),
    .io_perfEvents_19_value (l2top_io_perfEvents_19_value),
    .io_perfEvents_20_value (l2top_io_perfEvents_20_value),
    .io_perfEvents_21_value (l2top_io_perfEvents_21_value),
    .io_perfEvents_22_value (l2top_io_perfEvents_22_value),
    .io_perfEvents_23_value (l2top_io_perfEvents_23_value),
    .io_perfEvents_24_value (l2top_io_perfEvents_24_value),
    .io_perfEvents_25_value (l2top_io_perfEvents_25_value),
    .io_perfEvents_26_value (l2top_io_perfEvents_26_value),
    .io_perfEvents_27_value (l2top_io_perfEvents_27_value),
    .io_perfEvents_28_value (l2top_io_perfEvents_28_value),
    .io_perfEvents_29_value (l2top_io_perfEvents_29_value),
    .io_perfEvents_30_value (l2top_io_perfEvents_30_value),
    .io_perfEvents_31_value (l2top_io_perfEvents_31_value),
    .io_perfEvents_32_value (l2top_io_perfEvents_32_value),
    .io_perfEvents_33_value (l2top_io_perfEvents_33_value),
    .io_perfEvents_34_value (l2top_io_perfEvents_34_value),
    .io_perfEvents_35_value (l2top_io_perfEvents_35_value),
    .io_perfEvents_36_value (l2top_io_perfEvents_36_value),
    .io_perfEvents_37_value (l2top_io_perfEvents_37_value),
    .io_perfEvents_38_value (l2top_io_perfEvents_38_value),
    .io_perfEvents_39_value (l2top_io_perfEvents_39_value),
    .io_perfEvents_40_value (l2top_io_perfEvents_40_value),
    .io_perfEvents_41_value (l2top_io_perfEvents_41_value),
    .io_perfEvents_42_value (l2top_io_perfEvents_42_value),
    .io_perfEvents_43_value (l2top_io_perfEvents_43_value),
    .io_perfEvents_44_value (l2top_io_perfEvents_44_value),
    .io_perfEvents_45_value (l2top_io_perfEvents_45_value),
    .io_perfEvents_46_value (l2top_io_perfEvents_46_value),
    .io_perfEvents_47_value (l2top_io_perfEvents_47_value),
    .io_perfEvents_48_value (l2top_io_perfEvents_48_value),
    .io_perfEvents_49_value (l2top_io_perfEvents_49_value),
    .io_perfEvents_50_value (l2top_io_perfEvents_50_value),
    .io_perfEvents_51_value (l2top_io_perfEvents_51_value),
    .io_perfEvents_52_value (l2top_io_perfEvents_52_value),
    .io_perfEvents_53_value (l2top_io_perfEvents_53_value),
    .io_perfEvents_54_value (l2top_io_perfEvents_54_value),
    .io_perfEvents_55_value (l2top_io_perfEvents_55_value),
    .io_perfEvents_56_value (l2top_io_perfEvents_56_value),
    .io_perfEvents_57_value (l2top_io_perfEvents_57_value),
    .io_perfEvents_58_value (l2top_io_perfEvents_58_value),
    .io_perfEvents_59_value (l2top_io_perfEvents_59_value),
    .io_perfEvents_60_value (l2top_io_perfEvents_60_value),
    .io_perfEvents_61_value (l2top_io_perfEvents_61_value),
    .io_perfEvents_62_value (l2top_io_perfEvents_62_value),
    .io_perfEvents_63_value (l2top_io_perfEvents_63_value),
    .io_perfEvents_64_value (l2top_io_perfEvents_64_value),
    .io_perfEvents_65_value (l2top_io_perfEvents_65_value),
    .io_perfEvents_66_value (l2top_io_perfEvents_66_value),
    .io_perfEvents_67_value (l2top_io_perfEvents_67_value),
    .io_perfEvents_68_value (l2top_io_perfEvents_68_value),
    // → 顶层：tile 的全部外部输出：CHI 请求与链路控制、MMIO 请求、trace 接口、停机 / 关键错误 / MSI 应答、复位链
    //   auto_inner_beu*（1 根，1 位）
    .auto_inner_beu_int_out_0 (auto_l2top_inner_beu_int_out_0),
    //   io_msiAck_toTile*（1 根，1 位）
    .io_msiAck_toTile (io_msiAck),
    //   io_cpu_halt*（1 根，1 位）
    .io_cpu_halt_toTile (io_cpu_halt),
    //   io_cpu_critical*（1 根，1 位）
    .io_cpu_critical_error_toTile (io_cpu_crtical_error),
    //   io_hartIsInReset_toTile*（1 根，1 位）
    .io_hartIsInReset_toTile (io_hartIsInReset),
    //   io_traceCoreInterface_toTile*（19 根，370 位）
    .io_traceCoreInterface_toTile_toEncoder_priv (io_traceCoreInterface_toEncoder_priv),
    .io_traceCoreInterface_toTile_toEncoder_mstatus (io_traceCoreInterface_toEncoder_mstatus),
    .io_traceCoreInterface_toTile_toEncoder_trap_cause (io_traceCoreInterface_toEncoder_trap_cause),
    .io_traceCoreInterface_toTile_toEncoder_trap_tval (io_traceCoreInterface_toEncoder_trap_tval),
    .io_traceCoreInterface_toTile_toEncoder_groups_0_valid (io_traceCoreInterface_toEncoder_groups_0_valid),
    .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr (io_traceCoreInterface_toEncoder_groups_0_bits_iaddr),
    .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype (io_traceCoreInterface_toEncoder_groups_0_bits_itype),
    .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire (io_traceCoreInterface_toEncoder_groups_0_bits_iretire),
    .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize (io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize),
    .io_traceCoreInterface_toTile_toEncoder_groups_1_valid (io_traceCoreInterface_toEncoder_groups_1_valid),
    .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr (io_traceCoreInterface_toEncoder_groups_1_bits_iaddr),
    .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype (io_traceCoreInterface_toEncoder_groups_1_bits_itype),
    .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire (io_traceCoreInterface_toEncoder_groups_1_bits_iretire),
    .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize (io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize),
    .io_traceCoreInterface_toTile_toEncoder_groups_2_valid (io_traceCoreInterface_toEncoder_groups_2_valid),
    .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr (io_traceCoreInterface_toEncoder_groups_2_bits_iaddr),
    .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype (io_traceCoreInterface_toEncoder_groups_2_bits_itype),
    .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire (io_traceCoreInterface_toEncoder_groups_2_bits_iretire),
    .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize (io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize),
    //   io_chi_txsactive*（1 根，1 位）
    .io_chi_txsactive (io_chi_txsactive),
    //   io_chi_syscoreq*（1 根，1 位）
    .io_chi_syscoreq (io_chi_syscoreq),
    //   io_chi_tx*（10 根，664 位）
    .io_chi_tx_linkactivereq (io_chi_tx_linkactivereq),
    .io_chi_tx_req_flitpend (io_chi_tx_req_flitpend),
    .io_chi_tx_req_flitv (io_chi_tx_req_flitv),
    .io_chi_tx_req_flit (io_chi_tx_req_flit),
    .io_chi_tx_rsp_flitpend (io_chi_tx_rsp_flitpend),
    .io_chi_tx_rsp_flitv (io_chi_tx_rsp_flitv),
    .io_chi_tx_rsp_flit (io_chi_tx_rsp_flit),
    .io_chi_tx_dat_flitpend (io_chi_tx_dat_flitpend),
    .io_chi_tx_dat_flitv (io_chi_tx_dat_flitv),
    .io_chi_tx_dat_flit (io_chi_tx_dat_flit),
    //   io_chi_rx*（4 根，4 位）
    .io_chi_rx_linkactiveack (io_chi_rx_linkactiveack),
    .io_chi_rx_rsp_lcrdv (io_chi_rx_rsp_lcrdv),
    .io_chi_rx_dat_lcrdv (io_chi_rx_dat_lcrdv),
    .io_chi_rx_snp_lcrdv (io_chi_rx_snp_lcrdv),
    // ← 顶层：tile 的全部外部输入：CHI 回包与链路控制、MMIO 回包、CLINT / debug / PLIC / NMI 中断源、复位向量、MSI、CLINT 时间、trace 编码器回压、DFT 与时钟门控控制
    //   auto_inner_nmi*（2 根，2 位）
    .auto_inner_nmi_int_in_0 (auto_l2top_inner_nmi_int_in_0),
    .auto_inner_nmi_int_in_1 (auto_l2top_inner_nmi_int_in_1),
    //   auto_inner_plic*（2 根，2 位）
    .auto_inner_plic_int_in_1_0 (auto_l2top_inner_plic_int_in_1_0),
    .auto_inner_plic_int_in_0_0 (auto_l2top_inner_plic_int_in_0_0),
    //   auto_inner_debug*（1 根，1 位）
    .auto_inner_debug_int_in_0 (auto_l2top_inner_debug_int_in_0),
    //   auto_inner_clint*（2 根，2 位）
    .auto_inner_clint_int_in_0 (auto_l2top_inner_clint_int_in_0),
    .auto_inner_clint_int_in_1 (auto_l2top_inner_clint_int_in_1),
    //   io_reset_vector*（1 根，48 位）
    .io_reset_vector_fromTile (io_reset_vector),
    //   io_msiInfo_fromTile*（2 根，13 位）
    .io_msiInfo_fromTile_valid (io_msiInfo_valid),
    .io_msiInfo_fromTile_bits (io_msiInfo_bits),
    //   io_traceCoreInterface_toTile*（2 根，2 位）
    .io_traceCoreInterface_toTile_fromEncoder_enable (io_traceCoreInterface_fromEncoder_enable),
    .io_traceCoreInterface_toTile_fromEncoder_stall (io_traceCoreInterface_fromEncoder_stall),
    //   io_l3Miss_fromTile*（1 根，1 位）
    .io_l3Miss_fromTile (io_l3Miss),
    //   io_clintTime_fromTile*（2 根，65 位）
    .io_clintTime_fromTile_valid (io_clintTime_valid),
    .io_clintTime_fromTile_bits (io_clintTime_bits),
    //   io_chi_rxsactive*（1 根，1 位）
    .io_chi_rxsactive (io_chi_rxsactive),
    //   io_chi_syscoack*（1 根，1 位）
    .io_chi_syscoack (io_chi_syscoack),
    //   io_chi_tx*（4 根，4 位）
    .io_chi_tx_linkactiveack (io_chi_tx_linkactiveack),
    .io_chi_tx_req_lcrdv (io_chi_tx_req_lcrdv),
    .io_chi_tx_rsp_lcrdv (io_chi_tx_rsp_lcrdv),
    .io_chi_tx_dat_lcrdv (io_chi_tx_dat_lcrdv),
    //   io_chi_rx*（10 根，617 位）
    .io_chi_rx_linkactivereq (io_chi_rx_linkactivereq),
    .io_chi_rx_rsp_flitpend (io_chi_rx_rsp_flitpend),
    .io_chi_rx_rsp_flitv (io_chi_rx_rsp_flitv),
    .io_chi_rx_rsp_flit (io_chi_rx_rsp_flit),
    .io_chi_rx_dat_flitpend (io_chi_rx_dat_flitpend),
    .io_chi_rx_dat_flitv (io_chi_rx_dat_flitv),
    .io_chi_rx_dat_flit (io_chi_rx_dat_flit),
    .io_chi_rx_snp_flitpend (io_chi_rx_snp_flitpend),
    .io_chi_rx_snp_flitv (io_chi_rx_snp_flitv),
    .io_chi_rx_snp_flit (io_chi_rx_snp_flit),
    //   io_nodeID*（1 根，11 位）
    .io_nodeID (io_nodeID),
    //   io_dft_ram*（6 根，6 位）
    .io_dft_ram_hold (io_dft_ram_hold),
    .io_dft_ram_bypass (io_dft_ram_bypass),
    .io_dft_ram_bp_clken (io_dft_ram_bp_clken),
    .io_dft_ram_aux_clk (io_dft_ram_aux_clk),
    .io_dft_ram_aux_ckbp (io_dft_ram_aux_ckbp),
    .io_dft_ram_mcp_hold (io_dft_ram_mcp_hold),
    //   io_dft_cgen*（1 根，1 位）
    .io_dft_cgen (io_dft_cgen),
    // → intBuffer_3：NMI 中断（nmi_31 / nmi_43）进同步缓冲
    //   auto_inner_nmi*（2 根，2 位）
    .auto_inner_nmi_int_out_0 (l2top_auto_inner_nmi_int_out_0),
    .auto_inner_nmi_int_out_1 (l2top_auto_inner_nmi_int_out_1),
    // → intBuffer_1：PLIC 中断（meip / seip）进同步缓冲
    //   auto_inner_plic*（2 根，2 位）
    .auto_inner_plic_int_out_1_0 (l2top_auto_inner_plic_int_out_1_0),
    .auto_inner_plic_int_out_0_0 (l2top_auto_inner_plic_int_out_0_0),
    // → intBuffer_2：debug 中断进同步缓冲
    //   auto_inner_debug*（1 根，1 位）
    .auto_inner_debug_int_out_0 (l2top_auto_inner_debug_int_out_0),
    // → intBuffer：CLINT 中断（msip / mtip）进同步缓冲
    //   auto_inner_clint*（2 根，2 位）
    .auto_inner_clint_int_out_0 (l2top_auto_inner_clint_int_out_0),
    .auto_inner_clint_int_out_1 (l2top_auto_inner_clint_int_out_1),
    // ← 常量：高位补零：顶层 6 位 hartId 补成 64 位
    //   io_hartId_fromTile*（1 根，64 位）
    .io_hartId_fromTile ({58'h0, io_hartId})
  );

  // ===========================================================================
  // 子模块 IntBuffer_1 intBuffer（IntBuffer_1：CLINT 中断同步（2 根））
  //   6 个端口：输入 4 / 输出 2
  // ===========================================================================
  IntBuffer_1 intBuffer (
    // ← 顶层：时钟 / 复位
    .clock (clock),
    .reset (reset),
    // ← l2top：CLINT 中断（msip / mtip）进同步缓冲
    //   auto_in_N*（2 根，2 位）
    .auto_in_0 (l2top_auto_inner_clint_int_out_0),
    .auto_in_1 (l2top_auto_inner_clint_int_out_1),
    // → core：同步后的 CLINT 中断进核（MemBlock 的 clint 端口）
    //   auto_out_N*（2 根，2 位）
    .auto_out_0 (intBuffer_auto_out_0),
    .auto_out_1 (intBuffer_auto_out_1)
  );

  // ===========================================================================
  // 子模块 IntBuffer_2 intBuffer_1（IntBuffer_2：PLIC 中断同步（2 根））
  //   6 个端口：输入 4 / 输出 2
  // ===========================================================================
  IntBuffer_2 intBuffer_1 (
    // ← 顶层：时钟 / 复位
    .clock (clock),
    .reset (reset),
    // ← l2top：PLIC 中断（meip / seip）进同步缓冲
    //   auto_in_N*（2 根，2 位）
    .auto_in_1_0 (l2top_auto_inner_plic_int_out_1_0),
    .auto_in_0_0 (l2top_auto_inner_plic_int_out_0_0),
    // → core：同步后的 PLIC 中断进核（MemBlock 的 plic 端口）
    //   auto_out_N*（2 根，2 位）
    .auto_out_1_0 (intBuffer_1_auto_out_1_0),
    .auto_out_0_0 (intBuffer_1_auto_out_0_0)
  );

  // ===========================================================================
  // 子模块 IntBuffer intBuffer_2（IntBuffer：debug 中断同步（1 根））
  //   4 个端口：输入 3 / 输出 1
  // ===========================================================================
  IntBuffer intBuffer_2 (
    // ← 顶层：时钟 / 复位
    .clock (clock),
    .reset (reset),
    // ← l2top：debug 中断进同步缓冲
    //   auto_in_N*（1 根，1 位）
    .auto_in_0 (l2top_auto_inner_debug_int_out_0),
    // → core：同步后的 debug 中断进核
    //   auto_out_N*（1 根，1 位）
    .auto_out_0 (intBuffer_2_auto_out_0)
  );

  // ===========================================================================
  // 子模块 IntBuffer_1 intBuffer_3（IntBuffer_1：NMI 同步（2 根））
  //   6 个端口：输入 4 / 输出 2
  // ===========================================================================
  IntBuffer_1 intBuffer_3 (
    // ← 顶层：时钟 / 复位
    .clock (clock),
    .reset (reset),
    // ← l2top：NMI 中断（nmi_31 / nmi_43）进同步缓冲
    //   auto_in_N*（2 根，2 位）
    .auto_in_0 (l2top_auto_inner_nmi_int_out_0),
    .auto_in_1 (l2top_auto_inner_nmi_int_out_1),
    // → core：同步后的 NMI 进核
    //   auto_out_N*（2 根，2 位）
    .auto_out_0 (intBuffer_3_auto_out_0),
    .auto_out_1 (intBuffer_3_auto_out_1)
  );

  // ===========================================================================
  // 顶层输出：子模块输出线直通（这几根同时还有子模块读者，所以经线转一手）
  // ===========================================================================
  assign io_debugTopDown_robHeadPaddr_valid = core_io_debugTopDown_robHeadPaddr_valid;
  assign io_debugTopDown_robHeadPaddr_bits = core_io_debugTopDown_robHeadPaddr_bits;

endmodule
// END GENERATED
