// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：XSTile
// golden <T> 与派生 <T>_xs 双例化，同激励逐拍 4 态比全部输出；覆盖闸见文件尾。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  always #5 clock = ~clock;
  logic reset;
  longint checks = 0, errors = 0;
  longint cyc = 0;   // 复位释放后的拍号（--narrow 表达式可用它做分相激励）
  function automatic logic [4095:0] rnd(input int w);
    logic [4095:0] v;
    v = '0;
    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  // ======================= XSTile =======================
  logic XSTile__auto_l2top_inner_nmi_int_in_0;
  logic XSTile__auto_l2top_inner_nmi_int_in_1;
  logic XSTile__auto_l2top_inner_plic_int_in_1_0;
  logic XSTile__auto_l2top_inner_plic_int_in_0_0;
  logic XSTile__auto_l2top_inner_debug_int_in_0;
  logic XSTile__auto_l2top_inner_clint_int_in_0;
  logic XSTile__auto_l2top_inner_clint_int_in_1;
  logic [5:0] XSTile__io_hartId;
  logic XSTile__io_msiInfo_valid;
  logic [11:0] XSTile__io_msiInfo_bits;
  logic [47:0] XSTile__io_reset_vector;
  logic XSTile__io_traceCoreInterface_fromEncoder_enable;
  logic XSTile__io_traceCoreInterface_fromEncoder_stall;
  logic XSTile__io_debugTopDown_l3MissMatch;
  logic XSTile__io_l3Miss;
  logic XSTile__io_chi_rxsactive;
  logic XSTile__io_chi_syscoack;
  logic XSTile__io_chi_tx_linkactiveack;
  logic XSTile__io_chi_tx_req_lcrdv;
  logic XSTile__io_chi_tx_rsp_lcrdv;
  logic XSTile__io_chi_tx_dat_lcrdv;
  logic XSTile__io_chi_rx_linkactivereq;
  logic XSTile__io_chi_rx_rsp_flitpend;
  logic XSTile__io_chi_rx_rsp_flitv;
  logic [72:0] XSTile__io_chi_rx_rsp_flit;
  logic XSTile__io_chi_rx_dat_flitpend;
  logic XSTile__io_chi_rx_dat_flitv;
  logic [421:0] XSTile__io_chi_rx_dat_flit;
  logic XSTile__io_chi_rx_snp_flitpend;
  logic XSTile__io_chi_rx_snp_flitv;
  logic [114:0] XSTile__io_chi_rx_snp_flit;
  logic [10:0] XSTile__io_nodeID;
  logic XSTile__io_clintTime_valid;
  logic [63:0] XSTile__io_clintTime_bits;
  logic XSTile__io_dft_ram_hold;
  logic XSTile__io_dft_ram_bypass;
  logic XSTile__io_dft_ram_bp_clken;
  logic XSTile__io_dft_ram_aux_clk;
  logic XSTile__io_dft_ram_aux_ckbp;
  logic XSTile__io_dft_ram_mcp_hold;
  logic [63:0] XSTile__io_dft_ram_ctl;
  logic XSTile__io_dft_cgen;
  logic XSTile__io_dft_reset_lgc_rst_n;
  logic XSTile__io_dft_reset_mode;
  logic XSTile__io_dft_reset_scan_mode;
  wire  g_XSTile__auto_l2top_inner_beu_int_out_0;
  wire  i_XSTile__auto_l2top_inner_beu_int_out_0;
  logic p_XSTile__auto_l2top_inner_beu_int_out_0;
  bit   t_XSTile__auto_l2top_inner_beu_int_out_0;
  wire  g_XSTile__io_msiAck;
  wire  i_XSTile__io_msiAck;
  logic p_XSTile__io_msiAck;
  bit   t_XSTile__io_msiAck;
  wire  g_XSTile__io_cpu_halt;
  wire  i_XSTile__io_cpu_halt;
  logic p_XSTile__io_cpu_halt;
  bit   t_XSTile__io_cpu_halt;
  wire  g_XSTile__io_cpu_crtical_error;
  wire  i_XSTile__io_cpu_crtical_error;
  logic p_XSTile__io_cpu_crtical_error;
  bit   t_XSTile__io_cpu_crtical_error;
  wire  g_XSTile__io_hartIsInReset;
  wire  i_XSTile__io_hartIsInReset;
  logic p_XSTile__io_hartIsInReset;
  bit   t_XSTile__io_hartIsInReset;
  wire  [2:0] g_XSTile__io_traceCoreInterface_toEncoder_priv;
  wire  [2:0] i_XSTile__io_traceCoreInterface_toEncoder_priv;
  logic [2:0] p_XSTile__io_traceCoreInterface_toEncoder_priv;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_priv;
  wire  [63:0] g_XSTile__io_traceCoreInterface_toEncoder_mstatus;
  wire  [63:0] i_XSTile__io_traceCoreInterface_toEncoder_mstatus;
  logic [63:0] p_XSTile__io_traceCoreInterface_toEncoder_mstatus;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_mstatus;
  wire  [63:0] g_XSTile__io_traceCoreInterface_toEncoder_trap_cause;
  wire  [63:0] i_XSTile__io_traceCoreInterface_toEncoder_trap_cause;
  logic [63:0] p_XSTile__io_traceCoreInterface_toEncoder_trap_cause;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_trap_cause;
  wire  [49:0] g_XSTile__io_traceCoreInterface_toEncoder_trap_tval;
  wire  [49:0] i_XSTile__io_traceCoreInterface_toEncoder_trap_tval;
  logic [49:0] p_XSTile__io_traceCoreInterface_toEncoder_trap_tval;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_trap_tval;
  wire  g_XSTile__io_traceCoreInterface_toEncoder_groups_0_valid;
  wire  i_XSTile__io_traceCoreInterface_toEncoder_groups_0_valid;
  logic p_XSTile__io_traceCoreInterface_toEncoder_groups_0_valid;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_groups_0_valid;
  wire  [49:0] g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr;
  wire  [49:0] i_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr;
  logic [49:0] p_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr;
  wire  [3:0] g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_itype;
  wire  [3:0] i_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_itype;
  logic [3:0] p_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_itype;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_itype;
  wire  [6:0] g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iretire;
  wire  [6:0] i_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iretire;
  logic [6:0] p_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iretire;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iretire;
  wire  g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize;
  wire  i_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize;
  logic p_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize;
  wire  g_XSTile__io_traceCoreInterface_toEncoder_groups_1_valid;
  wire  i_XSTile__io_traceCoreInterface_toEncoder_groups_1_valid;
  logic p_XSTile__io_traceCoreInterface_toEncoder_groups_1_valid;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_groups_1_valid;
  wire  [49:0] g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr;
  wire  [49:0] i_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr;
  logic [49:0] p_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr;
  wire  [3:0] g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_itype;
  wire  [3:0] i_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_itype;
  logic [3:0] p_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_itype;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_itype;
  wire  [6:0] g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iretire;
  wire  [6:0] i_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iretire;
  logic [6:0] p_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iretire;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iretire;
  wire  g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize;
  wire  i_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize;
  logic p_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize;
  wire  g_XSTile__io_traceCoreInterface_toEncoder_groups_2_valid;
  wire  i_XSTile__io_traceCoreInterface_toEncoder_groups_2_valid;
  logic p_XSTile__io_traceCoreInterface_toEncoder_groups_2_valid;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_groups_2_valid;
  wire  [49:0] g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr;
  wire  [49:0] i_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr;
  logic [49:0] p_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr;
  wire  [3:0] g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_itype;
  wire  [3:0] i_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_itype;
  logic [3:0] p_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_itype;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_itype;
  wire  [6:0] g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iretire;
  wire  [6:0] i_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iretire;
  logic [6:0] p_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iretire;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iretire;
  wire  g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize;
  wire  i_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize;
  logic p_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize;
  bit   t_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize;
  wire  g_XSTile__io_debugTopDown_robHeadPaddr_valid;
  wire  i_XSTile__io_debugTopDown_robHeadPaddr_valid;
  logic p_XSTile__io_debugTopDown_robHeadPaddr_valid;
  bit   t_XSTile__io_debugTopDown_robHeadPaddr_valid;
  wire  [47:0] g_XSTile__io_debugTopDown_robHeadPaddr_bits;
  wire  [47:0] i_XSTile__io_debugTopDown_robHeadPaddr_bits;
  logic [47:0] p_XSTile__io_debugTopDown_robHeadPaddr_bits;
  bit   t_XSTile__io_debugTopDown_robHeadPaddr_bits;
  wire  g_XSTile__io_chi_txsactive;
  wire  i_XSTile__io_chi_txsactive;
  logic p_XSTile__io_chi_txsactive;
  bit   t_XSTile__io_chi_txsactive;
  wire  g_XSTile__io_chi_syscoreq;
  wire  i_XSTile__io_chi_syscoreq;
  logic p_XSTile__io_chi_syscoreq;
  bit   t_XSTile__io_chi_syscoreq;
  wire  g_XSTile__io_chi_tx_linkactivereq;
  wire  i_XSTile__io_chi_tx_linkactivereq;
  logic p_XSTile__io_chi_tx_linkactivereq;
  bit   t_XSTile__io_chi_tx_linkactivereq;
  wire  g_XSTile__io_chi_tx_req_flitpend;
  wire  i_XSTile__io_chi_tx_req_flitpend;
  logic p_XSTile__io_chi_tx_req_flitpend;
  bit   t_XSTile__io_chi_tx_req_flitpend;
  wire  g_XSTile__io_chi_tx_req_flitv;
  wire  i_XSTile__io_chi_tx_req_flitv;
  logic p_XSTile__io_chi_tx_req_flitv;
  bit   t_XSTile__io_chi_tx_req_flitv;
  wire  [161:0] g_XSTile__io_chi_tx_req_flit;
  wire  [161:0] i_XSTile__io_chi_tx_req_flit;
  logic [161:0] p_XSTile__io_chi_tx_req_flit;
  bit   t_XSTile__io_chi_tx_req_flit;
  wire  g_XSTile__io_chi_tx_rsp_flitpend;
  wire  i_XSTile__io_chi_tx_rsp_flitpend;
  logic p_XSTile__io_chi_tx_rsp_flitpend;
  bit   t_XSTile__io_chi_tx_rsp_flitpend;
  wire  g_XSTile__io_chi_tx_rsp_flitv;
  wire  i_XSTile__io_chi_tx_rsp_flitv;
  logic p_XSTile__io_chi_tx_rsp_flitv;
  bit   t_XSTile__io_chi_tx_rsp_flitv;
  wire  [72:0] g_XSTile__io_chi_tx_rsp_flit;
  wire  [72:0] i_XSTile__io_chi_tx_rsp_flit;
  logic [72:0] p_XSTile__io_chi_tx_rsp_flit;
  bit   t_XSTile__io_chi_tx_rsp_flit;
  wire  g_XSTile__io_chi_tx_dat_flitpend;
  wire  i_XSTile__io_chi_tx_dat_flitpend;
  logic p_XSTile__io_chi_tx_dat_flitpend;
  bit   t_XSTile__io_chi_tx_dat_flitpend;
  wire  g_XSTile__io_chi_tx_dat_flitv;
  wire  i_XSTile__io_chi_tx_dat_flitv;
  logic p_XSTile__io_chi_tx_dat_flitv;
  bit   t_XSTile__io_chi_tx_dat_flitv;
  wire  [421:0] g_XSTile__io_chi_tx_dat_flit;
  wire  [421:0] i_XSTile__io_chi_tx_dat_flit;
  logic [421:0] p_XSTile__io_chi_tx_dat_flit;
  bit   t_XSTile__io_chi_tx_dat_flit;
  wire  g_XSTile__io_chi_rx_linkactiveack;
  wire  i_XSTile__io_chi_rx_linkactiveack;
  logic p_XSTile__io_chi_rx_linkactiveack;
  bit   t_XSTile__io_chi_rx_linkactiveack;
  wire  g_XSTile__io_chi_rx_rsp_lcrdv;
  wire  i_XSTile__io_chi_rx_rsp_lcrdv;
  logic p_XSTile__io_chi_rx_rsp_lcrdv;
  bit   t_XSTile__io_chi_rx_rsp_lcrdv;
  wire  g_XSTile__io_chi_rx_dat_lcrdv;
  wire  i_XSTile__io_chi_rx_dat_lcrdv;
  logic p_XSTile__io_chi_rx_dat_lcrdv;
  bit   t_XSTile__io_chi_rx_dat_lcrdv;
  wire  g_XSTile__io_chi_rx_snp_lcrdv;
  wire  i_XSTile__io_chi_rx_snp_lcrdv;
  logic p_XSTile__io_chi_rx_snp_lcrdv;
  bit   t_XSTile__io_chi_rx_snp_lcrdv;
  wire  [600:0] g_XSTile__gatewayIn_packed_0_bore;
  wire  [600:0] i_XSTile__gatewayIn_packed_0_bore;
  logic [600:0] p_XSTile__gatewayIn_packed_0_bore;
  bit   t_XSTile__gatewayIn_packed_0_bore;
  wire  [600:0] g_XSTile__gatewayIn_packed_1_bore;
  wire  [600:0] i_XSTile__gatewayIn_packed_1_bore;
  logic [600:0] p_XSTile__gatewayIn_packed_1_bore;
  bit   t_XSTile__gatewayIn_packed_1_bore;
  wire  [600:0] g_XSTile__gatewayIn_packed_2_bore;
  wire  [600:0] i_XSTile__gatewayIn_packed_2_bore;
  logic [600:0] p_XSTile__gatewayIn_packed_2_bore;
  bit   t_XSTile__gatewayIn_packed_2_bore;
  wire  [338:0] g_XSTile__gatewayIn_packed_3_bore;
  wire  [338:0] i_XSTile__gatewayIn_packed_3_bore;
  logic [338:0] p_XSTile__gatewayIn_packed_3_bore;
  bit   t_XSTile__gatewayIn_packed_3_bore;
  wire  [338:0] g_XSTile__gatewayIn_packed_4_bore;
  wire  [338:0] i_XSTile__gatewayIn_packed_4_bore;
  logic [338:0] p_XSTile__gatewayIn_packed_4_bore;
  bit   t_XSTile__gatewayIn_packed_4_bore;
  wire  [338:0] g_XSTile__gatewayIn_packed_5_bore;
  wire  [338:0] i_XSTile__gatewayIn_packed_5_bore;
  logic [338:0] p_XSTile__gatewayIn_packed_5_bore;
  bit   t_XSTile__gatewayIn_packed_5_bore;
  wire  [321:0] g_XSTile__gatewayIn_packed_6_bore;
  wire  [321:0] i_XSTile__gatewayIn_packed_6_bore;
  logic [321:0] p_XSTile__gatewayIn_packed_6_bore;
  bit   t_XSTile__gatewayIn_packed_6_bore;
  wire  [91:0] g_XSTile__gatewayIn_packed_7_bore;
  wire  [91:0] i_XSTile__gatewayIn_packed_7_bore;
  logic [91:0] p_XSTile__gatewayIn_packed_7_bore;
  bit   t_XSTile__gatewayIn_packed_7_bore;
  wire  [321:0] g_XSTile__gatewayIn_packed_8_bore;
  wire  [321:0] i_XSTile__gatewayIn_packed_8_bore;
  logic [321:0] p_XSTile__gatewayIn_packed_8_bore;
  bit   t_XSTile__gatewayIn_packed_8_bore;
  wire  [91:0] g_XSTile__gatewayIn_packed_9_bore;
  wire  [91:0] i_XSTile__gatewayIn_packed_9_bore;
  logic [91:0] p_XSTile__gatewayIn_packed_9_bore;
  bit   t_XSTile__gatewayIn_packed_9_bore;
  wire  [321:0] g_XSTile__gatewayIn_packed_10_bore;
  wire  [321:0] i_XSTile__gatewayIn_packed_10_bore;
  logic [321:0] p_XSTile__gatewayIn_packed_10_bore;
  bit   t_XSTile__gatewayIn_packed_10_bore;
  wire  [91:0] g_XSTile__gatewayIn_packed_11_bore;
  wire  [91:0] i_XSTile__gatewayIn_packed_11_bore;
  logic [91:0] p_XSTile__gatewayIn_packed_11_bore;
  bit   t_XSTile__gatewayIn_packed_11_bore;
  wire  [321:0] g_XSTile__gatewayIn_packed_12_bore;
  wire  [321:0] i_XSTile__gatewayIn_packed_12_bore;
  logic [321:0] p_XSTile__gatewayIn_packed_12_bore;
  bit   t_XSTile__gatewayIn_packed_12_bore;
  wire  [91:0] g_XSTile__gatewayIn_packed_13_bore;
  wire  [91:0] i_XSTile__gatewayIn_packed_13_bore;
  logic [91:0] p_XSTile__gatewayIn_packed_13_bore;
  bit   t_XSTile__gatewayIn_packed_13_bore;
  wire  [321:0] g_XSTile__gatewayIn_packed_14_bore;
  wire  [321:0] i_XSTile__gatewayIn_packed_14_bore;
  logic [321:0] p_XSTile__gatewayIn_packed_14_bore;
  bit   t_XSTile__gatewayIn_packed_14_bore;
  wire  [91:0] g_XSTile__gatewayIn_packed_15_bore;
  wire  [91:0] i_XSTile__gatewayIn_packed_15_bore;
  logic [91:0] p_XSTile__gatewayIn_packed_15_bore;
  bit   t_XSTile__gatewayIn_packed_15_bore;
  wire  [321:0] g_XSTile__gatewayIn_packed_16_bore;
  wire  [321:0] i_XSTile__gatewayIn_packed_16_bore;
  logic [321:0] p_XSTile__gatewayIn_packed_16_bore;
  bit   t_XSTile__gatewayIn_packed_16_bore;
  wire  [91:0] g_XSTile__gatewayIn_packed_17_bore;
  wire  [91:0] i_XSTile__gatewayIn_packed_17_bore;
  logic [91:0] p_XSTile__gatewayIn_packed_17_bore;
  bit   t_XSTile__gatewayIn_packed_17_bore;
  wire  [321:0] g_XSTile__gatewayIn_packed_18_bore;
  wire  [321:0] i_XSTile__gatewayIn_packed_18_bore;
  logic [321:0] p_XSTile__gatewayIn_packed_18_bore;
  bit   t_XSTile__gatewayIn_packed_18_bore;
  wire  [91:0] g_XSTile__gatewayIn_packed_19_bore;
  wire  [91:0] i_XSTile__gatewayIn_packed_19_bore;
  logic [91:0] p_XSTile__gatewayIn_packed_19_bore;
  bit   t_XSTile__gatewayIn_packed_19_bore;
  wire  [321:0] g_XSTile__gatewayIn_packed_20_bore;
  wire  [321:0] i_XSTile__gatewayIn_packed_20_bore;
  logic [321:0] p_XSTile__gatewayIn_packed_20_bore;
  bit   t_XSTile__gatewayIn_packed_20_bore;
  wire  [91:0] g_XSTile__gatewayIn_packed_21_bore;
  wire  [91:0] i_XSTile__gatewayIn_packed_21_bore;
  logic [91:0] p_XSTile__gatewayIn_packed_21_bore;
  bit   t_XSTile__gatewayIn_packed_21_bore;
  wire  [265:0] g_XSTile__gatewayIn_packed_22_bore;
  wire  [265:0] i_XSTile__gatewayIn_packed_22_bore;
  logic [265:0] p_XSTile__gatewayIn_packed_22_bore;
  bit   t_XSTile__gatewayIn_packed_22_bore;
  wire  [263:0] g_XSTile__gatewayIn_packed_23_bore;
  wire  [263:0] i_XSTile__gatewayIn_packed_23_bore;
  logic [263:0] p_XSTile__gatewayIn_packed_23_bore;
  bit   t_XSTile__gatewayIn_packed_23_bore;
  wire  [263:0] g_XSTile__gatewayIn_packed_24_bore;
  wire  [263:0] i_XSTile__gatewayIn_packed_24_bore;
  logic [263:0] p_XSTile__gatewayIn_packed_24_bore;
  bit   t_XSTile__gatewayIn_packed_24_bore;
  wire  [583:0] g_XSTile__gatewayIn_packed_25_bore;
  wire  [583:0] i_XSTile__gatewayIn_packed_25_bore;
  logic [583:0] p_XSTile__gatewayIn_packed_25_bore;
  bit   t_XSTile__gatewayIn_packed_25_bore;
  wire  [14343:0] g_XSTile__gatewayIn_packed_26_bore;
  wire  [14343:0] i_XSTile__gatewayIn_packed_26_bore;
  logic [14343:0] p_XSTile__gatewayIn_packed_26_bore;
  bit   t_XSTile__gatewayIn_packed_26_bore;
  wire  [12295:0] g_XSTile__gatewayIn_packed_27_bore;
  wire  [12295:0] i_XSTile__gatewayIn_packed_27_bore;
  logic [12295:0] p_XSTile__gatewayIn_packed_27_bore;
  bit   t_XSTile__gatewayIn_packed_27_bore;
  wire  [19207:0] g_XSTile__gatewayIn_packed_28_bore;
  wire  [19207:0] i_XSTile__gatewayIn_packed_28_bore;
  logic [19207:0] p_XSTile__gatewayIn_packed_28_bore;
  bit   t_XSTile__gatewayIn_packed_28_bore;
  wire  [172:0] g_XSTile__gatewayIn_packed_29_bore;
  wire  [172:0] i_XSTile__gatewayIn_packed_29_bore;
  logic [172:0] p_XSTile__gatewayIn_packed_29_bore;
  bit   t_XSTile__gatewayIn_packed_29_bore;
  wire  [9:0] g_XSTile__gatewayIn_packed_30_bore;
  wire  [9:0] i_XSTile__gatewayIn_packed_30_bore;
  logic [9:0] p_XSTile__gatewayIn_packed_30_bore;
  bit   t_XSTile__gatewayIn_packed_30_bore;
  wire  [1159:0] g_XSTile__gatewayIn_packed_31_bore;
  wire  [1159:0] i_XSTile__gatewayIn_packed_31_bore;
  logic [1159:0] p_XSTile__gatewayIn_packed_31_bore;
  bit   t_XSTile__gatewayIn_packed_31_bore;
  wire  [264:0] g_XSTile__gatewayIn_packed_32_bore;
  wire  [264:0] i_XSTile__gatewayIn_packed_32_bore;
  logic [264:0] p_XSTile__gatewayIn_packed_32_bore;
  bit   t_XSTile__gatewayIn_packed_32_bore;
  wire  [199:0] g_XSTile__gatewayIn_packed_33_bore;
  wire  [199:0] i_XSTile__gatewayIn_packed_33_bore;
  logic [199:0] p_XSTile__gatewayIn_packed_33_bore;
  bit   t_XSTile__gatewayIn_packed_33_bore;
  wire  [455:0] g_XSTile__gatewayIn_packed_34_bore;
  wire  [455:0] i_XSTile__gatewayIn_packed_34_bore;
  logic [455:0] p_XSTile__gatewayIn_packed_34_bore;
  bit   t_XSTile__gatewayIn_packed_34_bore;
  wire  [71:0] g_XSTile__gatewayIn_packed_35_bore;
  wire  [71:0] i_XSTile__gatewayIn_packed_35_bore;
  logic [71:0] p_XSTile__gatewayIn_packed_35_bore;
  bit   t_XSTile__gatewayIn_packed_35_bore;
  wire  [1095:0] g_XSTile__gatewayIn_packed_36_bore;
  wire  [1095:0] i_XSTile__gatewayIn_packed_36_bore;
  logic [1095:0] p_XSTile__gatewayIn_packed_36_bore;
  bit   t_XSTile__gatewayIn_packed_36_bore;
  wire  [18:0] g_XSTile__gatewayIn_packed_37_bore;
  wire  [18:0] i_XSTile__gatewayIn_packed_37_bore;
  logic [18:0] p_XSTile__gatewayIn_packed_37_bore;
  bit   t_XSTile__gatewayIn_packed_37_bore;
  wire  [72:0] g_XSTile__gatewayIn_packed_38_bore;
  wire  [72:0] i_XSTile__gatewayIn_packed_38_bore;
  logic [72:0] p_XSTile__gatewayIn_packed_38_bore;
  bit   t_XSTile__gatewayIn_packed_38_bore;
  wire  [264:0] g_XSTile__gatewayIn_packed_39_bore;
  wire  [264:0] i_XSTile__gatewayIn_packed_39_bore;
  logic [264:0] p_XSTile__gatewayIn_packed_39_bore;
  bit   t_XSTile__gatewayIn_packed_39_bore;
  wire  [9:0] g_XSTile__gatewayIn_packed_40_bore;
  wire  [9:0] i_XSTile__gatewayIn_packed_40_bore;
  logic [9:0] p_XSTile__gatewayIn_packed_40_bore;
  bit   t_XSTile__gatewayIn_packed_40_bore;
  wire  [600:0] g_XSTile__gatewayIn_packed_41_bore;
  wire  [600:0] i_XSTile__gatewayIn_packed_41_bore;
  logic [600:0] p_XSTile__gatewayIn_packed_41_bore;
  bit   t_XSTile__gatewayIn_packed_41_bore;
  wire  [152:0] g_XSTile__gatewayIn_packed_42_bore;
  wire  [152:0] i_XSTile__gatewayIn_packed_42_bore;
  logic [152:0] p_XSTile__gatewayIn_packed_42_bore;
  bit   t_XSTile__gatewayIn_packed_42_bore;
  wire  [600:0] g_XSTile__gatewayIn_packed_43_bore;
  wire  [600:0] i_XSTile__gatewayIn_packed_43_bore;
  logic [600:0] p_XSTile__gatewayIn_packed_43_bore;
  bit   t_XSTile__gatewayIn_packed_43_bore;
  wire  [968:0] g_XSTile__gatewayIn_packed_44_bore;
  wire  [968:0] i_XSTile__gatewayIn_packed_44_bore;
  logic [968:0] p_XSTile__gatewayIn_packed_44_bore;
  bit   t_XSTile__gatewayIn_packed_44_bore;
  wire  [968:0] g_XSTile__gatewayIn_packed_45_bore;
  wire  [968:0] i_XSTile__gatewayIn_packed_45_bore;
  logic [968:0] p_XSTile__gatewayIn_packed_45_bore;
  bit   t_XSTile__gatewayIn_packed_45_bore;
  wire  [480:0] g_XSTile__gatewayIn_packed_46_bore;
  wire  [480:0] i_XSTile__gatewayIn_packed_46_bore;
  logic [480:0] p_XSTile__gatewayIn_packed_46_bore;
  bit   t_XSTile__gatewayIn_packed_46_bore;
  wire  [9:0] g_XSTile__gatewayIn_packed_47_bore;
  wire  [9:0] i_XSTile__gatewayIn_packed_47_bore;
  logic [9:0] p_XSTile__gatewayIn_packed_47_bore;
  bit   t_XSTile__gatewayIn_packed_47_bore;
  wire  [72:0] g_XSTile__gatewayIn_packed_48_bore;
  wire  [72:0] i_XSTile__gatewayIn_packed_48_bore;
  logic [72:0] p_XSTile__gatewayIn_packed_48_bore;
  bit   t_XSTile__gatewayIn_packed_48_bore;
  wire  [656:0] g_XSTile__gatewayIn_packed_49_bore;
  wire  [656:0] i_XSTile__gatewayIn_packed_49_bore;
  logic [656:0] p_XSTile__gatewayIn_packed_49_bore;
  bit   t_XSTile__gatewayIn_packed_49_bore;
  wire  [324:0] g_XSTile__gatewayIn_packed_50_bore;
  wire  [324:0] i_XSTile__gatewayIn_packed_50_bore;
  logic [324:0] p_XSTile__gatewayIn_packed_50_bore;
  bit   t_XSTile__gatewayIn_packed_50_bore;
  wire  [324:0] g_XSTile__gatewayIn_packed_51_bore;
  wire  [324:0] i_XSTile__gatewayIn_packed_51_bore;
  logic [324:0] p_XSTile__gatewayIn_packed_51_bore;
  bit   t_XSTile__gatewayIn_packed_51_bore;
  wire  [324:0] g_XSTile__gatewayIn_packed_52_bore;
  wire  [324:0] i_XSTile__gatewayIn_packed_52_bore;
  logic [324:0] p_XSTile__gatewayIn_packed_52_bore;
  bit   t_XSTile__gatewayIn_packed_52_bore;
  wire  [338:0] g_XSTile__gatewayIn_packed_53_bore;
  wire  [338:0] i_XSTile__gatewayIn_packed_53_bore;
  logic [338:0] p_XSTile__gatewayIn_packed_53_bore;
  bit   t_XSTile__gatewayIn_packed_53_bore;
  wire  [338:0] g_XSTile__gatewayIn_packed_54_bore;
  wire  [338:0] i_XSTile__gatewayIn_packed_54_bore;
  logic [338:0] p_XSTile__gatewayIn_packed_54_bore;
  bit   t_XSTile__gatewayIn_packed_54_bore;
  wire  [338:0] g_XSTile__gatewayIn_packed_55_bore;
  wire  [338:0] i_XSTile__gatewayIn_packed_55_bore;
  logic [338:0] p_XSTile__gatewayIn_packed_55_bore;
  bit   t_XSTile__gatewayIn_packed_55_bore;
  wire  [338:0] g_XSTile__gatewayIn_packed_56_bore;
  wire  [338:0] i_XSTile__gatewayIn_packed_56_bore;
  logic [338:0] p_XSTile__gatewayIn_packed_56_bore;
  bit   t_XSTile__gatewayIn_packed_56_bore;
  wire  [338:0] g_XSTile__gatewayIn_packed_57_bore;
  wire  [338:0] i_XSTile__gatewayIn_packed_57_bore;
  logic [338:0] p_XSTile__gatewayIn_packed_57_bore;
  bit   t_XSTile__gatewayIn_packed_57_bore;
  wire  [338:0] g_XSTile__gatewayIn_packed_58_bore;
  wire  [338:0] i_XSTile__gatewayIn_packed_58_bore;
  logic [338:0] p_XSTile__gatewayIn_packed_58_bore;
  bit   t_XSTile__gatewayIn_packed_58_bore;
  wire  [338:0] g_XSTile__gatewayIn_packed_59_bore;
  wire  [338:0] i_XSTile__gatewayIn_packed_59_bore;
  logic [338:0] p_XSTile__gatewayIn_packed_59_bore;
  bit   t_XSTile__gatewayIn_packed_59_bore;
  wire  [338:0] g_XSTile__gatewayIn_packed_60_bore;
  wire  [338:0] i_XSTile__gatewayIn_packed_60_bore;
  logic [338:0] p_XSTile__gatewayIn_packed_60_bore;
  bit   t_XSTile__gatewayIn_packed_60_bore;
  XSTile u_g_XSTile (
    .clock (clock),
    .reset (reset),
    .auto_l2top_inner_beu_int_out_0 (g_XSTile__auto_l2top_inner_beu_int_out_0),
    .auto_l2top_inner_nmi_int_in_0 (XSTile__auto_l2top_inner_nmi_int_in_0),
    .auto_l2top_inner_nmi_int_in_1 (XSTile__auto_l2top_inner_nmi_int_in_1),
    .auto_l2top_inner_plic_int_in_1_0 (XSTile__auto_l2top_inner_plic_int_in_1_0),
    .auto_l2top_inner_plic_int_in_0_0 (XSTile__auto_l2top_inner_plic_int_in_0_0),
    .auto_l2top_inner_debug_int_in_0 (XSTile__auto_l2top_inner_debug_int_in_0),
    .auto_l2top_inner_clint_int_in_0 (XSTile__auto_l2top_inner_clint_int_in_0),
    .auto_l2top_inner_clint_int_in_1 (XSTile__auto_l2top_inner_clint_int_in_1),
    .io_hartId (XSTile__io_hartId),
    .io_msiInfo_valid (XSTile__io_msiInfo_valid),
    .io_msiInfo_bits (XSTile__io_msiInfo_bits),
    .io_msiAck (g_XSTile__io_msiAck),
    .io_reset_vector (XSTile__io_reset_vector),
    .io_cpu_halt (g_XSTile__io_cpu_halt),
    .io_cpu_crtical_error (g_XSTile__io_cpu_crtical_error),
    .io_hartIsInReset (g_XSTile__io_hartIsInReset),
    .io_traceCoreInterface_fromEncoder_enable (XSTile__io_traceCoreInterface_fromEncoder_enable),
    .io_traceCoreInterface_fromEncoder_stall (XSTile__io_traceCoreInterface_fromEncoder_stall),
    .io_traceCoreInterface_toEncoder_priv (g_XSTile__io_traceCoreInterface_toEncoder_priv),
    .io_traceCoreInterface_toEncoder_mstatus (g_XSTile__io_traceCoreInterface_toEncoder_mstatus),
    .io_traceCoreInterface_toEncoder_trap_cause (g_XSTile__io_traceCoreInterface_toEncoder_trap_cause),
    .io_traceCoreInterface_toEncoder_trap_tval (g_XSTile__io_traceCoreInterface_toEncoder_trap_tval),
    .io_traceCoreInterface_toEncoder_groups_0_valid (g_XSTile__io_traceCoreInterface_toEncoder_groups_0_valid),
    .io_traceCoreInterface_toEncoder_groups_0_bits_iaddr (g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr),
    .io_traceCoreInterface_toEncoder_groups_0_bits_itype (g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_itype),
    .io_traceCoreInterface_toEncoder_groups_0_bits_iretire (g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iretire),
    .io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize (g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize),
    .io_traceCoreInterface_toEncoder_groups_1_valid (g_XSTile__io_traceCoreInterface_toEncoder_groups_1_valid),
    .io_traceCoreInterface_toEncoder_groups_1_bits_iaddr (g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr),
    .io_traceCoreInterface_toEncoder_groups_1_bits_itype (g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_itype),
    .io_traceCoreInterface_toEncoder_groups_1_bits_iretire (g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iretire),
    .io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize (g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize),
    .io_traceCoreInterface_toEncoder_groups_2_valid (g_XSTile__io_traceCoreInterface_toEncoder_groups_2_valid),
    .io_traceCoreInterface_toEncoder_groups_2_bits_iaddr (g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr),
    .io_traceCoreInterface_toEncoder_groups_2_bits_itype (g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_itype),
    .io_traceCoreInterface_toEncoder_groups_2_bits_iretire (g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iretire),
    .io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize (g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize),
    .io_debugTopDown_robHeadPaddr_valid (g_XSTile__io_debugTopDown_robHeadPaddr_valid),
    .io_debugTopDown_robHeadPaddr_bits (g_XSTile__io_debugTopDown_robHeadPaddr_bits),
    .io_debugTopDown_l3MissMatch (XSTile__io_debugTopDown_l3MissMatch),
    .io_l3Miss (XSTile__io_l3Miss),
    .io_chi_txsactive (g_XSTile__io_chi_txsactive),
    .io_chi_rxsactive (XSTile__io_chi_rxsactive),
    .io_chi_syscoreq (g_XSTile__io_chi_syscoreq),
    .io_chi_syscoack (XSTile__io_chi_syscoack),
    .io_chi_tx_linkactivereq (g_XSTile__io_chi_tx_linkactivereq),
    .io_chi_tx_linkactiveack (XSTile__io_chi_tx_linkactiveack),
    .io_chi_tx_req_flitpend (g_XSTile__io_chi_tx_req_flitpend),
    .io_chi_tx_req_flitv (g_XSTile__io_chi_tx_req_flitv),
    .io_chi_tx_req_flit (g_XSTile__io_chi_tx_req_flit),
    .io_chi_tx_req_lcrdv (XSTile__io_chi_tx_req_lcrdv),
    .io_chi_tx_rsp_flitpend (g_XSTile__io_chi_tx_rsp_flitpend),
    .io_chi_tx_rsp_flitv (g_XSTile__io_chi_tx_rsp_flitv),
    .io_chi_tx_rsp_flit (g_XSTile__io_chi_tx_rsp_flit),
    .io_chi_tx_rsp_lcrdv (XSTile__io_chi_tx_rsp_lcrdv),
    .io_chi_tx_dat_flitpend (g_XSTile__io_chi_tx_dat_flitpend),
    .io_chi_tx_dat_flitv (g_XSTile__io_chi_tx_dat_flitv),
    .io_chi_tx_dat_flit (g_XSTile__io_chi_tx_dat_flit),
    .io_chi_tx_dat_lcrdv (XSTile__io_chi_tx_dat_lcrdv),
    .io_chi_rx_linkactivereq (XSTile__io_chi_rx_linkactivereq),
    .io_chi_rx_linkactiveack (g_XSTile__io_chi_rx_linkactiveack),
    .io_chi_rx_rsp_flitpend (XSTile__io_chi_rx_rsp_flitpend),
    .io_chi_rx_rsp_flitv (XSTile__io_chi_rx_rsp_flitv),
    .io_chi_rx_rsp_flit (XSTile__io_chi_rx_rsp_flit),
    .io_chi_rx_rsp_lcrdv (g_XSTile__io_chi_rx_rsp_lcrdv),
    .io_chi_rx_dat_flitpend (XSTile__io_chi_rx_dat_flitpend),
    .io_chi_rx_dat_flitv (XSTile__io_chi_rx_dat_flitv),
    .io_chi_rx_dat_flit (XSTile__io_chi_rx_dat_flit),
    .io_chi_rx_dat_lcrdv (g_XSTile__io_chi_rx_dat_lcrdv),
    .io_chi_rx_snp_flitpend (XSTile__io_chi_rx_snp_flitpend),
    .io_chi_rx_snp_flitv (XSTile__io_chi_rx_snp_flitv),
    .io_chi_rx_snp_flit (XSTile__io_chi_rx_snp_flit),
    .io_chi_rx_snp_lcrdv (g_XSTile__io_chi_rx_snp_lcrdv),
    .io_nodeID (XSTile__io_nodeID),
    .io_clintTime_valid (XSTile__io_clintTime_valid),
    .io_clintTime_bits (XSTile__io_clintTime_bits),
    .io_dft_ram_hold (XSTile__io_dft_ram_hold),
    .io_dft_ram_bypass (XSTile__io_dft_ram_bypass),
    .io_dft_ram_bp_clken (XSTile__io_dft_ram_bp_clken),
    .io_dft_ram_aux_clk (XSTile__io_dft_ram_aux_clk),
    .io_dft_ram_aux_ckbp (XSTile__io_dft_ram_aux_ckbp),
    .io_dft_ram_mcp_hold (XSTile__io_dft_ram_mcp_hold),
    .io_dft_ram_ctl (XSTile__io_dft_ram_ctl),
    .io_dft_cgen (XSTile__io_dft_cgen),
    .io_dft_reset_lgc_rst_n (XSTile__io_dft_reset_lgc_rst_n),
    .io_dft_reset_mode (XSTile__io_dft_reset_mode),
    .io_dft_reset_scan_mode (XSTile__io_dft_reset_scan_mode),
    .gatewayIn_packed_0_bore (g_XSTile__gatewayIn_packed_0_bore),
    .gatewayIn_packed_1_bore (g_XSTile__gatewayIn_packed_1_bore),
    .gatewayIn_packed_2_bore (g_XSTile__gatewayIn_packed_2_bore),
    .gatewayIn_packed_3_bore (g_XSTile__gatewayIn_packed_3_bore),
    .gatewayIn_packed_4_bore (g_XSTile__gatewayIn_packed_4_bore),
    .gatewayIn_packed_5_bore (g_XSTile__gatewayIn_packed_5_bore),
    .gatewayIn_packed_6_bore (g_XSTile__gatewayIn_packed_6_bore),
    .gatewayIn_packed_7_bore (g_XSTile__gatewayIn_packed_7_bore),
    .gatewayIn_packed_8_bore (g_XSTile__gatewayIn_packed_8_bore),
    .gatewayIn_packed_9_bore (g_XSTile__gatewayIn_packed_9_bore),
    .gatewayIn_packed_10_bore (g_XSTile__gatewayIn_packed_10_bore),
    .gatewayIn_packed_11_bore (g_XSTile__gatewayIn_packed_11_bore),
    .gatewayIn_packed_12_bore (g_XSTile__gatewayIn_packed_12_bore),
    .gatewayIn_packed_13_bore (g_XSTile__gatewayIn_packed_13_bore),
    .gatewayIn_packed_14_bore (g_XSTile__gatewayIn_packed_14_bore),
    .gatewayIn_packed_15_bore (g_XSTile__gatewayIn_packed_15_bore),
    .gatewayIn_packed_16_bore (g_XSTile__gatewayIn_packed_16_bore),
    .gatewayIn_packed_17_bore (g_XSTile__gatewayIn_packed_17_bore),
    .gatewayIn_packed_18_bore (g_XSTile__gatewayIn_packed_18_bore),
    .gatewayIn_packed_19_bore (g_XSTile__gatewayIn_packed_19_bore),
    .gatewayIn_packed_20_bore (g_XSTile__gatewayIn_packed_20_bore),
    .gatewayIn_packed_21_bore (g_XSTile__gatewayIn_packed_21_bore),
    .gatewayIn_packed_22_bore (g_XSTile__gatewayIn_packed_22_bore),
    .gatewayIn_packed_23_bore (g_XSTile__gatewayIn_packed_23_bore),
    .gatewayIn_packed_24_bore (g_XSTile__gatewayIn_packed_24_bore),
    .gatewayIn_packed_25_bore (g_XSTile__gatewayIn_packed_25_bore),
    .gatewayIn_packed_26_bore (g_XSTile__gatewayIn_packed_26_bore),
    .gatewayIn_packed_27_bore (g_XSTile__gatewayIn_packed_27_bore),
    .gatewayIn_packed_28_bore (g_XSTile__gatewayIn_packed_28_bore),
    .gatewayIn_packed_29_bore (g_XSTile__gatewayIn_packed_29_bore),
    .gatewayIn_packed_30_bore (g_XSTile__gatewayIn_packed_30_bore),
    .gatewayIn_packed_31_bore (g_XSTile__gatewayIn_packed_31_bore),
    .gatewayIn_packed_32_bore (g_XSTile__gatewayIn_packed_32_bore),
    .gatewayIn_packed_33_bore (g_XSTile__gatewayIn_packed_33_bore),
    .gatewayIn_packed_34_bore (g_XSTile__gatewayIn_packed_34_bore),
    .gatewayIn_packed_35_bore (g_XSTile__gatewayIn_packed_35_bore),
    .gatewayIn_packed_36_bore (g_XSTile__gatewayIn_packed_36_bore),
    .gatewayIn_packed_37_bore (g_XSTile__gatewayIn_packed_37_bore),
    .gatewayIn_packed_38_bore (g_XSTile__gatewayIn_packed_38_bore),
    .gatewayIn_packed_39_bore (g_XSTile__gatewayIn_packed_39_bore),
    .gatewayIn_packed_40_bore (g_XSTile__gatewayIn_packed_40_bore),
    .gatewayIn_packed_41_bore (g_XSTile__gatewayIn_packed_41_bore),
    .gatewayIn_packed_42_bore (g_XSTile__gatewayIn_packed_42_bore),
    .gatewayIn_packed_43_bore (g_XSTile__gatewayIn_packed_43_bore),
    .gatewayIn_packed_44_bore (g_XSTile__gatewayIn_packed_44_bore),
    .gatewayIn_packed_45_bore (g_XSTile__gatewayIn_packed_45_bore),
    .gatewayIn_packed_46_bore (g_XSTile__gatewayIn_packed_46_bore),
    .gatewayIn_packed_47_bore (g_XSTile__gatewayIn_packed_47_bore),
    .gatewayIn_packed_48_bore (g_XSTile__gatewayIn_packed_48_bore),
    .gatewayIn_packed_49_bore (g_XSTile__gatewayIn_packed_49_bore),
    .gatewayIn_packed_50_bore (g_XSTile__gatewayIn_packed_50_bore),
    .gatewayIn_packed_51_bore (g_XSTile__gatewayIn_packed_51_bore),
    .gatewayIn_packed_52_bore (g_XSTile__gatewayIn_packed_52_bore),
    .gatewayIn_packed_53_bore (g_XSTile__gatewayIn_packed_53_bore),
    .gatewayIn_packed_54_bore (g_XSTile__gatewayIn_packed_54_bore),
    .gatewayIn_packed_55_bore (g_XSTile__gatewayIn_packed_55_bore),
    .gatewayIn_packed_56_bore (g_XSTile__gatewayIn_packed_56_bore),
    .gatewayIn_packed_57_bore (g_XSTile__gatewayIn_packed_57_bore),
    .gatewayIn_packed_58_bore (g_XSTile__gatewayIn_packed_58_bore),
    .gatewayIn_packed_59_bore (g_XSTile__gatewayIn_packed_59_bore),
    .gatewayIn_packed_60_bore (g_XSTile__gatewayIn_packed_60_bore)
  );
  XSTile_xs u_i_XSTile (
    .clock (clock),
    .reset (reset),
    .auto_l2top_inner_beu_int_out_0 (i_XSTile__auto_l2top_inner_beu_int_out_0),
    .auto_l2top_inner_nmi_int_in_0 (XSTile__auto_l2top_inner_nmi_int_in_0),
    .auto_l2top_inner_nmi_int_in_1 (XSTile__auto_l2top_inner_nmi_int_in_1),
    .auto_l2top_inner_plic_int_in_1_0 (XSTile__auto_l2top_inner_plic_int_in_1_0),
    .auto_l2top_inner_plic_int_in_0_0 (XSTile__auto_l2top_inner_plic_int_in_0_0),
    .auto_l2top_inner_debug_int_in_0 (XSTile__auto_l2top_inner_debug_int_in_0),
    .auto_l2top_inner_clint_int_in_0 (XSTile__auto_l2top_inner_clint_int_in_0),
    .auto_l2top_inner_clint_int_in_1 (XSTile__auto_l2top_inner_clint_int_in_1),
    .io_hartId (XSTile__io_hartId),
    .io_msiInfo_valid (XSTile__io_msiInfo_valid),
    .io_msiInfo_bits (XSTile__io_msiInfo_bits),
    .io_msiAck (i_XSTile__io_msiAck),
    .io_reset_vector (XSTile__io_reset_vector),
    .io_cpu_halt (i_XSTile__io_cpu_halt),
    .io_cpu_crtical_error (i_XSTile__io_cpu_crtical_error),
    .io_hartIsInReset (i_XSTile__io_hartIsInReset),
    .io_traceCoreInterface_fromEncoder_enable (XSTile__io_traceCoreInterface_fromEncoder_enable),
    .io_traceCoreInterface_fromEncoder_stall (XSTile__io_traceCoreInterface_fromEncoder_stall),
    .io_traceCoreInterface_toEncoder_priv (i_XSTile__io_traceCoreInterface_toEncoder_priv),
    .io_traceCoreInterface_toEncoder_mstatus (i_XSTile__io_traceCoreInterface_toEncoder_mstatus),
    .io_traceCoreInterface_toEncoder_trap_cause (i_XSTile__io_traceCoreInterface_toEncoder_trap_cause),
    .io_traceCoreInterface_toEncoder_trap_tval (i_XSTile__io_traceCoreInterface_toEncoder_trap_tval),
    .io_traceCoreInterface_toEncoder_groups_0_valid (i_XSTile__io_traceCoreInterface_toEncoder_groups_0_valid),
    .io_traceCoreInterface_toEncoder_groups_0_bits_iaddr (i_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr),
    .io_traceCoreInterface_toEncoder_groups_0_bits_itype (i_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_itype),
    .io_traceCoreInterface_toEncoder_groups_0_bits_iretire (i_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iretire),
    .io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize (i_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize),
    .io_traceCoreInterface_toEncoder_groups_1_valid (i_XSTile__io_traceCoreInterface_toEncoder_groups_1_valid),
    .io_traceCoreInterface_toEncoder_groups_1_bits_iaddr (i_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr),
    .io_traceCoreInterface_toEncoder_groups_1_bits_itype (i_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_itype),
    .io_traceCoreInterface_toEncoder_groups_1_bits_iretire (i_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iretire),
    .io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize (i_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize),
    .io_traceCoreInterface_toEncoder_groups_2_valid (i_XSTile__io_traceCoreInterface_toEncoder_groups_2_valid),
    .io_traceCoreInterface_toEncoder_groups_2_bits_iaddr (i_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr),
    .io_traceCoreInterface_toEncoder_groups_2_bits_itype (i_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_itype),
    .io_traceCoreInterface_toEncoder_groups_2_bits_iretire (i_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iretire),
    .io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize (i_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize),
    .io_debugTopDown_robHeadPaddr_valid (i_XSTile__io_debugTopDown_robHeadPaddr_valid),
    .io_debugTopDown_robHeadPaddr_bits (i_XSTile__io_debugTopDown_robHeadPaddr_bits),
    .io_debugTopDown_l3MissMatch (XSTile__io_debugTopDown_l3MissMatch),
    .io_l3Miss (XSTile__io_l3Miss),
    .io_chi_txsactive (i_XSTile__io_chi_txsactive),
    .io_chi_rxsactive (XSTile__io_chi_rxsactive),
    .io_chi_syscoreq (i_XSTile__io_chi_syscoreq),
    .io_chi_syscoack (XSTile__io_chi_syscoack),
    .io_chi_tx_linkactivereq (i_XSTile__io_chi_tx_linkactivereq),
    .io_chi_tx_linkactiveack (XSTile__io_chi_tx_linkactiveack),
    .io_chi_tx_req_flitpend (i_XSTile__io_chi_tx_req_flitpend),
    .io_chi_tx_req_flitv (i_XSTile__io_chi_tx_req_flitv),
    .io_chi_tx_req_flit (i_XSTile__io_chi_tx_req_flit),
    .io_chi_tx_req_lcrdv (XSTile__io_chi_tx_req_lcrdv),
    .io_chi_tx_rsp_flitpend (i_XSTile__io_chi_tx_rsp_flitpend),
    .io_chi_tx_rsp_flitv (i_XSTile__io_chi_tx_rsp_flitv),
    .io_chi_tx_rsp_flit (i_XSTile__io_chi_tx_rsp_flit),
    .io_chi_tx_rsp_lcrdv (XSTile__io_chi_tx_rsp_lcrdv),
    .io_chi_tx_dat_flitpend (i_XSTile__io_chi_tx_dat_flitpend),
    .io_chi_tx_dat_flitv (i_XSTile__io_chi_tx_dat_flitv),
    .io_chi_tx_dat_flit (i_XSTile__io_chi_tx_dat_flit),
    .io_chi_tx_dat_lcrdv (XSTile__io_chi_tx_dat_lcrdv),
    .io_chi_rx_linkactivereq (XSTile__io_chi_rx_linkactivereq),
    .io_chi_rx_linkactiveack (i_XSTile__io_chi_rx_linkactiveack),
    .io_chi_rx_rsp_flitpend (XSTile__io_chi_rx_rsp_flitpend),
    .io_chi_rx_rsp_flitv (XSTile__io_chi_rx_rsp_flitv),
    .io_chi_rx_rsp_flit (XSTile__io_chi_rx_rsp_flit),
    .io_chi_rx_rsp_lcrdv (i_XSTile__io_chi_rx_rsp_lcrdv),
    .io_chi_rx_dat_flitpend (XSTile__io_chi_rx_dat_flitpend),
    .io_chi_rx_dat_flitv (XSTile__io_chi_rx_dat_flitv),
    .io_chi_rx_dat_flit (XSTile__io_chi_rx_dat_flit),
    .io_chi_rx_dat_lcrdv (i_XSTile__io_chi_rx_dat_lcrdv),
    .io_chi_rx_snp_flitpend (XSTile__io_chi_rx_snp_flitpend),
    .io_chi_rx_snp_flitv (XSTile__io_chi_rx_snp_flitv),
    .io_chi_rx_snp_flit (XSTile__io_chi_rx_snp_flit),
    .io_chi_rx_snp_lcrdv (i_XSTile__io_chi_rx_snp_lcrdv),
    .io_nodeID (XSTile__io_nodeID),
    .io_clintTime_valid (XSTile__io_clintTime_valid),
    .io_clintTime_bits (XSTile__io_clintTime_bits),
    .io_dft_ram_hold (XSTile__io_dft_ram_hold),
    .io_dft_ram_bypass (XSTile__io_dft_ram_bypass),
    .io_dft_ram_bp_clken (XSTile__io_dft_ram_bp_clken),
    .io_dft_ram_aux_clk (XSTile__io_dft_ram_aux_clk),
    .io_dft_ram_aux_ckbp (XSTile__io_dft_ram_aux_ckbp),
    .io_dft_ram_mcp_hold (XSTile__io_dft_ram_mcp_hold),
    .io_dft_ram_ctl (XSTile__io_dft_ram_ctl),
    .io_dft_cgen (XSTile__io_dft_cgen),
    .io_dft_reset_lgc_rst_n (XSTile__io_dft_reset_lgc_rst_n),
    .io_dft_reset_mode (XSTile__io_dft_reset_mode),
    .io_dft_reset_scan_mode (XSTile__io_dft_reset_scan_mode),
    .gatewayIn_packed_0_bore (i_XSTile__gatewayIn_packed_0_bore),
    .gatewayIn_packed_1_bore (i_XSTile__gatewayIn_packed_1_bore),
    .gatewayIn_packed_2_bore (i_XSTile__gatewayIn_packed_2_bore),
    .gatewayIn_packed_3_bore (i_XSTile__gatewayIn_packed_3_bore),
    .gatewayIn_packed_4_bore (i_XSTile__gatewayIn_packed_4_bore),
    .gatewayIn_packed_5_bore (i_XSTile__gatewayIn_packed_5_bore),
    .gatewayIn_packed_6_bore (i_XSTile__gatewayIn_packed_6_bore),
    .gatewayIn_packed_7_bore (i_XSTile__gatewayIn_packed_7_bore),
    .gatewayIn_packed_8_bore (i_XSTile__gatewayIn_packed_8_bore),
    .gatewayIn_packed_9_bore (i_XSTile__gatewayIn_packed_9_bore),
    .gatewayIn_packed_10_bore (i_XSTile__gatewayIn_packed_10_bore),
    .gatewayIn_packed_11_bore (i_XSTile__gatewayIn_packed_11_bore),
    .gatewayIn_packed_12_bore (i_XSTile__gatewayIn_packed_12_bore),
    .gatewayIn_packed_13_bore (i_XSTile__gatewayIn_packed_13_bore),
    .gatewayIn_packed_14_bore (i_XSTile__gatewayIn_packed_14_bore),
    .gatewayIn_packed_15_bore (i_XSTile__gatewayIn_packed_15_bore),
    .gatewayIn_packed_16_bore (i_XSTile__gatewayIn_packed_16_bore),
    .gatewayIn_packed_17_bore (i_XSTile__gatewayIn_packed_17_bore),
    .gatewayIn_packed_18_bore (i_XSTile__gatewayIn_packed_18_bore),
    .gatewayIn_packed_19_bore (i_XSTile__gatewayIn_packed_19_bore),
    .gatewayIn_packed_20_bore (i_XSTile__gatewayIn_packed_20_bore),
    .gatewayIn_packed_21_bore (i_XSTile__gatewayIn_packed_21_bore),
    .gatewayIn_packed_22_bore (i_XSTile__gatewayIn_packed_22_bore),
    .gatewayIn_packed_23_bore (i_XSTile__gatewayIn_packed_23_bore),
    .gatewayIn_packed_24_bore (i_XSTile__gatewayIn_packed_24_bore),
    .gatewayIn_packed_25_bore (i_XSTile__gatewayIn_packed_25_bore),
    .gatewayIn_packed_26_bore (i_XSTile__gatewayIn_packed_26_bore),
    .gatewayIn_packed_27_bore (i_XSTile__gatewayIn_packed_27_bore),
    .gatewayIn_packed_28_bore (i_XSTile__gatewayIn_packed_28_bore),
    .gatewayIn_packed_29_bore (i_XSTile__gatewayIn_packed_29_bore),
    .gatewayIn_packed_30_bore (i_XSTile__gatewayIn_packed_30_bore),
    .gatewayIn_packed_31_bore (i_XSTile__gatewayIn_packed_31_bore),
    .gatewayIn_packed_32_bore (i_XSTile__gatewayIn_packed_32_bore),
    .gatewayIn_packed_33_bore (i_XSTile__gatewayIn_packed_33_bore),
    .gatewayIn_packed_34_bore (i_XSTile__gatewayIn_packed_34_bore),
    .gatewayIn_packed_35_bore (i_XSTile__gatewayIn_packed_35_bore),
    .gatewayIn_packed_36_bore (i_XSTile__gatewayIn_packed_36_bore),
    .gatewayIn_packed_37_bore (i_XSTile__gatewayIn_packed_37_bore),
    .gatewayIn_packed_38_bore (i_XSTile__gatewayIn_packed_38_bore),
    .gatewayIn_packed_39_bore (i_XSTile__gatewayIn_packed_39_bore),
    .gatewayIn_packed_40_bore (i_XSTile__gatewayIn_packed_40_bore),
    .gatewayIn_packed_41_bore (i_XSTile__gatewayIn_packed_41_bore),
    .gatewayIn_packed_42_bore (i_XSTile__gatewayIn_packed_42_bore),
    .gatewayIn_packed_43_bore (i_XSTile__gatewayIn_packed_43_bore),
    .gatewayIn_packed_44_bore (i_XSTile__gatewayIn_packed_44_bore),
    .gatewayIn_packed_45_bore (i_XSTile__gatewayIn_packed_45_bore),
    .gatewayIn_packed_46_bore (i_XSTile__gatewayIn_packed_46_bore),
    .gatewayIn_packed_47_bore (i_XSTile__gatewayIn_packed_47_bore),
    .gatewayIn_packed_48_bore (i_XSTile__gatewayIn_packed_48_bore),
    .gatewayIn_packed_49_bore (i_XSTile__gatewayIn_packed_49_bore),
    .gatewayIn_packed_50_bore (i_XSTile__gatewayIn_packed_50_bore),
    .gatewayIn_packed_51_bore (i_XSTile__gatewayIn_packed_51_bore),
    .gatewayIn_packed_52_bore (i_XSTile__gatewayIn_packed_52_bore),
    .gatewayIn_packed_53_bore (i_XSTile__gatewayIn_packed_53_bore),
    .gatewayIn_packed_54_bore (i_XSTile__gatewayIn_packed_54_bore),
    .gatewayIn_packed_55_bore (i_XSTile__gatewayIn_packed_55_bore),
    .gatewayIn_packed_56_bore (i_XSTile__gatewayIn_packed_56_bore),
    .gatewayIn_packed_57_bore (i_XSTile__gatewayIn_packed_57_bore),
    .gatewayIn_packed_58_bore (i_XSTile__gatewayIn_packed_58_bore),
    .gatewayIn_packed_59_bore (i_XSTile__gatewayIn_packed_59_bore),
    .gatewayIn_packed_60_bore (i_XSTile__gatewayIn_packed_60_bore)
  );
  task automatic drive_XSTile();
    XSTile__auto_l2top_inner_nmi_int_in_0 = $urandom % 2;
    XSTile__auto_l2top_inner_nmi_int_in_1 = $urandom % 2;
    XSTile__auto_l2top_inner_plic_int_in_1_0 = $urandom % 2;
    XSTile__auto_l2top_inner_plic_int_in_0_0 = $urandom % 2;
    XSTile__auto_l2top_inner_debug_int_in_0 = $urandom % 2;
    XSTile__auto_l2top_inner_clint_int_in_0 = $urandom % 2;
    XSTile__auto_l2top_inner_clint_int_in_1 = $urandom % 2;
    XSTile__io_hartId = rnd(6);
    XSTile__io_msiInfo_valid = $urandom % 2;
    XSTile__io_msiInfo_bits = rnd(12);
    XSTile__io_reset_vector = (((cyc / 5000) % 4) == 2) ? rnd(48) : 48'h8000_0000;
    XSTile__io_traceCoreInterface_fromEncoder_enable = $urandom % 2;
    XSTile__io_traceCoreInterface_fromEncoder_stall = $urandom % 2;
    XSTile__io_debugTopDown_l3MissMatch = $urandom % 2;
    XSTile__io_l3Miss = $urandom % 2;
    XSTile__io_chi_rxsactive = $urandom % 2;
    XSTile__io_chi_syscoack = $urandom % 2;
    XSTile__io_chi_tx_linkactiveack = $urandom % 2;
    XSTile__io_chi_tx_req_lcrdv = $urandom % 2;
    XSTile__io_chi_tx_rsp_lcrdv = $urandom % 2;
    XSTile__io_chi_tx_dat_lcrdv = $urandom % 2;
    XSTile__io_chi_rx_linkactivereq = $urandom % 2;
    XSTile__io_chi_rx_rsp_flitpend = $urandom % 2;
    XSTile__io_chi_rx_rsp_flitv = $urandom % 2;
    XSTile__io_chi_rx_rsp_flit = rnd(73);
    XSTile__io_chi_rx_dat_flitpend = $urandom % 2;
    XSTile__io_chi_rx_dat_flitv = $urandom % 2;
    XSTile__io_chi_rx_dat_flit = rnd(422);
    XSTile__io_chi_rx_snp_flitpend = $urandom % 2;
    XSTile__io_chi_rx_snp_flitv = $urandom % 2;
    XSTile__io_chi_rx_snp_flit = rnd(115);
    XSTile__io_nodeID = rnd(11);
    XSTile__io_clintTime_valid = $urandom % 2;
    XSTile__io_clintTime_bits = rnd(64);
    XSTile__io_dft_ram_hold = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
    XSTile__io_dft_ram_bypass = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
    XSTile__io_dft_ram_bp_clken = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
    XSTile__io_dft_ram_aux_clk = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
    XSTile__io_dft_ram_aux_ckbp = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
    XSTile__io_dft_ram_mcp_hold = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
    XSTile__io_dft_ram_ctl = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
    XSTile__io_dft_cgen = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
    XSTile__io_dft_reset_lgc_rst_n = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
    XSTile__io_dft_reset_mode = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
    XSTile__io_dft_reset_scan_mode = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
  endtask
  task automatic check_XSTile();
    checks++;
    if (g_XSTile__auto_l2top_inner_beu_int_out_0 !== i_XSTile__auto_l2top_inner_beu_int_out_0) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.auto_l2top_inner_beu_int_out_0 g=%h i=%h", cyc, g_XSTile__auto_l2top_inner_beu_int_out_0, i_XSTile__auto_l2top_inner_beu_int_out_0);
    end
    if (g_XSTile__auto_l2top_inner_beu_int_out_0 !== p_XSTile__auto_l2top_inner_beu_int_out_0) t_XSTile__auto_l2top_inner_beu_int_out_0 = 1'b1;
    p_XSTile__auto_l2top_inner_beu_int_out_0 = g_XSTile__auto_l2top_inner_beu_int_out_0;
    checks++;
    if (g_XSTile__io_msiAck !== i_XSTile__io_msiAck) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_msiAck g=%h i=%h", cyc, g_XSTile__io_msiAck, i_XSTile__io_msiAck);
    end
    if (g_XSTile__io_msiAck !== p_XSTile__io_msiAck) t_XSTile__io_msiAck = 1'b1;
    p_XSTile__io_msiAck = g_XSTile__io_msiAck;
    checks++;
    if (g_XSTile__io_cpu_halt !== i_XSTile__io_cpu_halt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_cpu_halt g=%h i=%h", cyc, g_XSTile__io_cpu_halt, i_XSTile__io_cpu_halt);
    end
    if (g_XSTile__io_cpu_halt !== p_XSTile__io_cpu_halt) t_XSTile__io_cpu_halt = 1'b1;
    p_XSTile__io_cpu_halt = g_XSTile__io_cpu_halt;
    checks++;
    if (g_XSTile__io_cpu_crtical_error !== i_XSTile__io_cpu_crtical_error) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_cpu_crtical_error g=%h i=%h", cyc, g_XSTile__io_cpu_crtical_error, i_XSTile__io_cpu_crtical_error);
    end
    if (g_XSTile__io_cpu_crtical_error !== p_XSTile__io_cpu_crtical_error) t_XSTile__io_cpu_crtical_error = 1'b1;
    p_XSTile__io_cpu_crtical_error = g_XSTile__io_cpu_crtical_error;
    checks++;
    if (g_XSTile__io_hartIsInReset !== i_XSTile__io_hartIsInReset) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_hartIsInReset g=%h i=%h", cyc, g_XSTile__io_hartIsInReset, i_XSTile__io_hartIsInReset);
    end
    if (g_XSTile__io_hartIsInReset !== p_XSTile__io_hartIsInReset) t_XSTile__io_hartIsInReset = 1'b1;
    p_XSTile__io_hartIsInReset = g_XSTile__io_hartIsInReset;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_priv !== i_XSTile__io_traceCoreInterface_toEncoder_priv) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_priv g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_priv, i_XSTile__io_traceCoreInterface_toEncoder_priv);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_priv !== p_XSTile__io_traceCoreInterface_toEncoder_priv) t_XSTile__io_traceCoreInterface_toEncoder_priv = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_priv = g_XSTile__io_traceCoreInterface_toEncoder_priv;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_mstatus !== i_XSTile__io_traceCoreInterface_toEncoder_mstatus) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_mstatus g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_mstatus, i_XSTile__io_traceCoreInterface_toEncoder_mstatus);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_mstatus !== p_XSTile__io_traceCoreInterface_toEncoder_mstatus) t_XSTile__io_traceCoreInterface_toEncoder_mstatus = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_mstatus = g_XSTile__io_traceCoreInterface_toEncoder_mstatus;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_trap_cause !== i_XSTile__io_traceCoreInterface_toEncoder_trap_cause) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_trap_cause g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_trap_cause, i_XSTile__io_traceCoreInterface_toEncoder_trap_cause);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_trap_cause !== p_XSTile__io_traceCoreInterface_toEncoder_trap_cause) t_XSTile__io_traceCoreInterface_toEncoder_trap_cause = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_trap_cause = g_XSTile__io_traceCoreInterface_toEncoder_trap_cause;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_trap_tval !== i_XSTile__io_traceCoreInterface_toEncoder_trap_tval) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_trap_tval g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_trap_tval, i_XSTile__io_traceCoreInterface_toEncoder_trap_tval);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_trap_tval !== p_XSTile__io_traceCoreInterface_toEncoder_trap_tval) t_XSTile__io_traceCoreInterface_toEncoder_trap_tval = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_trap_tval = g_XSTile__io_traceCoreInterface_toEncoder_trap_tval;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_0_valid !== i_XSTile__io_traceCoreInterface_toEncoder_groups_0_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_groups_0_valid g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_groups_0_valid, i_XSTile__io_traceCoreInterface_toEncoder_groups_0_valid);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_0_valid !== p_XSTile__io_traceCoreInterface_toEncoder_groups_0_valid) t_XSTile__io_traceCoreInterface_toEncoder_groups_0_valid = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_groups_0_valid = g_XSTile__io_traceCoreInterface_toEncoder_groups_0_valid;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr !== i_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_groups_0_bits_iaddr g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr, i_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr !== p_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr) t_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr = g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_itype !== i_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_itype) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_groups_0_bits_itype g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_itype, i_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_itype);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_itype !== p_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_itype) t_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_itype = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_itype = g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_itype;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iretire !== i_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iretire) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_groups_0_bits_iretire g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iretire, i_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iretire);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iretire !== p_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iretire) t_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iretire = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iretire = g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iretire;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize !== i_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize, i_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize !== p_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize) t_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize = g_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_1_valid !== i_XSTile__io_traceCoreInterface_toEncoder_groups_1_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_groups_1_valid g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_groups_1_valid, i_XSTile__io_traceCoreInterface_toEncoder_groups_1_valid);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_1_valid !== p_XSTile__io_traceCoreInterface_toEncoder_groups_1_valid) t_XSTile__io_traceCoreInterface_toEncoder_groups_1_valid = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_groups_1_valid = g_XSTile__io_traceCoreInterface_toEncoder_groups_1_valid;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr !== i_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_groups_1_bits_iaddr g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr, i_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr !== p_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr) t_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr = g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_itype !== i_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_itype) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_groups_1_bits_itype g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_itype, i_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_itype);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_itype !== p_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_itype) t_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_itype = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_itype = g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_itype;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iretire !== i_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iretire) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_groups_1_bits_iretire g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iretire, i_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iretire);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iretire !== p_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iretire) t_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iretire = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iretire = g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iretire;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize !== i_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize, i_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize !== p_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize) t_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize = g_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_2_valid !== i_XSTile__io_traceCoreInterface_toEncoder_groups_2_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_groups_2_valid g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_groups_2_valid, i_XSTile__io_traceCoreInterface_toEncoder_groups_2_valid);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_2_valid !== p_XSTile__io_traceCoreInterface_toEncoder_groups_2_valid) t_XSTile__io_traceCoreInterface_toEncoder_groups_2_valid = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_groups_2_valid = g_XSTile__io_traceCoreInterface_toEncoder_groups_2_valid;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr !== i_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_groups_2_bits_iaddr g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr, i_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr !== p_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr) t_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr = g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_itype !== i_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_itype) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_groups_2_bits_itype g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_itype, i_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_itype);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_itype !== p_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_itype) t_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_itype = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_itype = g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_itype;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iretire !== i_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iretire) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_groups_2_bits_iretire g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iretire, i_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iretire);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iretire !== p_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iretire) t_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iretire = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iretire = g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iretire;
    checks++;
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize !== i_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize g=%h i=%h", cyc, g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize, i_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize);
    end
    if (g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize !== p_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize) t_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize = 1'b1;
    p_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize = g_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize;
    checks++;
    if (g_XSTile__io_debugTopDown_robHeadPaddr_valid !== i_XSTile__io_debugTopDown_robHeadPaddr_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_debugTopDown_robHeadPaddr_valid g=%h i=%h", cyc, g_XSTile__io_debugTopDown_robHeadPaddr_valid, i_XSTile__io_debugTopDown_robHeadPaddr_valid);
    end
    if (g_XSTile__io_debugTopDown_robHeadPaddr_valid !== p_XSTile__io_debugTopDown_robHeadPaddr_valid) t_XSTile__io_debugTopDown_robHeadPaddr_valid = 1'b1;
    p_XSTile__io_debugTopDown_robHeadPaddr_valid = g_XSTile__io_debugTopDown_robHeadPaddr_valid;
    checks++;
    if (g_XSTile__io_debugTopDown_robHeadPaddr_bits !== i_XSTile__io_debugTopDown_robHeadPaddr_bits) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_debugTopDown_robHeadPaddr_bits g=%h i=%h", cyc, g_XSTile__io_debugTopDown_robHeadPaddr_bits, i_XSTile__io_debugTopDown_robHeadPaddr_bits);
    end
    if (g_XSTile__io_debugTopDown_robHeadPaddr_bits !== p_XSTile__io_debugTopDown_robHeadPaddr_bits) t_XSTile__io_debugTopDown_robHeadPaddr_bits = 1'b1;
    p_XSTile__io_debugTopDown_robHeadPaddr_bits = g_XSTile__io_debugTopDown_robHeadPaddr_bits;
    checks++;
    if (g_XSTile__io_chi_txsactive !== i_XSTile__io_chi_txsactive) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_chi_txsactive g=%h i=%h", cyc, g_XSTile__io_chi_txsactive, i_XSTile__io_chi_txsactive);
    end
    if (g_XSTile__io_chi_txsactive !== p_XSTile__io_chi_txsactive) t_XSTile__io_chi_txsactive = 1'b1;
    p_XSTile__io_chi_txsactive = g_XSTile__io_chi_txsactive;
    checks++;
    if (g_XSTile__io_chi_syscoreq !== i_XSTile__io_chi_syscoreq) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_chi_syscoreq g=%h i=%h", cyc, g_XSTile__io_chi_syscoreq, i_XSTile__io_chi_syscoreq);
    end
    if (g_XSTile__io_chi_syscoreq !== p_XSTile__io_chi_syscoreq) t_XSTile__io_chi_syscoreq = 1'b1;
    p_XSTile__io_chi_syscoreq = g_XSTile__io_chi_syscoreq;
    checks++;
    if (g_XSTile__io_chi_tx_linkactivereq !== i_XSTile__io_chi_tx_linkactivereq) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_chi_tx_linkactivereq g=%h i=%h", cyc, g_XSTile__io_chi_tx_linkactivereq, i_XSTile__io_chi_tx_linkactivereq);
    end
    if (g_XSTile__io_chi_tx_linkactivereq !== p_XSTile__io_chi_tx_linkactivereq) t_XSTile__io_chi_tx_linkactivereq = 1'b1;
    p_XSTile__io_chi_tx_linkactivereq = g_XSTile__io_chi_tx_linkactivereq;
    checks++;
    if (g_XSTile__io_chi_tx_req_flitpend !== i_XSTile__io_chi_tx_req_flitpend) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_chi_tx_req_flitpend g=%h i=%h", cyc, g_XSTile__io_chi_tx_req_flitpend, i_XSTile__io_chi_tx_req_flitpend);
    end
    if (g_XSTile__io_chi_tx_req_flitpend !== p_XSTile__io_chi_tx_req_flitpend) t_XSTile__io_chi_tx_req_flitpend = 1'b1;
    p_XSTile__io_chi_tx_req_flitpend = g_XSTile__io_chi_tx_req_flitpend;
    checks++;
    if (g_XSTile__io_chi_tx_req_flitv !== i_XSTile__io_chi_tx_req_flitv) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_chi_tx_req_flitv g=%h i=%h", cyc, g_XSTile__io_chi_tx_req_flitv, i_XSTile__io_chi_tx_req_flitv);
    end
    if (g_XSTile__io_chi_tx_req_flitv !== p_XSTile__io_chi_tx_req_flitv) t_XSTile__io_chi_tx_req_flitv = 1'b1;
    p_XSTile__io_chi_tx_req_flitv = g_XSTile__io_chi_tx_req_flitv;
    checks++;
    if (g_XSTile__io_chi_tx_req_flit !== i_XSTile__io_chi_tx_req_flit) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_chi_tx_req_flit g=%h i=%h", cyc, g_XSTile__io_chi_tx_req_flit, i_XSTile__io_chi_tx_req_flit);
    end
    if (g_XSTile__io_chi_tx_req_flit !== p_XSTile__io_chi_tx_req_flit) t_XSTile__io_chi_tx_req_flit = 1'b1;
    p_XSTile__io_chi_tx_req_flit = g_XSTile__io_chi_tx_req_flit;
    checks++;
    if (g_XSTile__io_chi_tx_rsp_flitpend !== i_XSTile__io_chi_tx_rsp_flitpend) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_chi_tx_rsp_flitpend g=%h i=%h", cyc, g_XSTile__io_chi_tx_rsp_flitpend, i_XSTile__io_chi_tx_rsp_flitpend);
    end
    if (g_XSTile__io_chi_tx_rsp_flitpend !== p_XSTile__io_chi_tx_rsp_flitpend) t_XSTile__io_chi_tx_rsp_flitpend = 1'b1;
    p_XSTile__io_chi_tx_rsp_flitpend = g_XSTile__io_chi_tx_rsp_flitpend;
    checks++;
    if (g_XSTile__io_chi_tx_rsp_flitv !== i_XSTile__io_chi_tx_rsp_flitv) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_chi_tx_rsp_flitv g=%h i=%h", cyc, g_XSTile__io_chi_tx_rsp_flitv, i_XSTile__io_chi_tx_rsp_flitv);
    end
    if (g_XSTile__io_chi_tx_rsp_flitv !== p_XSTile__io_chi_tx_rsp_flitv) t_XSTile__io_chi_tx_rsp_flitv = 1'b1;
    p_XSTile__io_chi_tx_rsp_flitv = g_XSTile__io_chi_tx_rsp_flitv;
    checks++;
    if (g_XSTile__io_chi_tx_rsp_flit !== i_XSTile__io_chi_tx_rsp_flit) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_chi_tx_rsp_flit g=%h i=%h", cyc, g_XSTile__io_chi_tx_rsp_flit, i_XSTile__io_chi_tx_rsp_flit);
    end
    if (g_XSTile__io_chi_tx_rsp_flit !== p_XSTile__io_chi_tx_rsp_flit) t_XSTile__io_chi_tx_rsp_flit = 1'b1;
    p_XSTile__io_chi_tx_rsp_flit = g_XSTile__io_chi_tx_rsp_flit;
    checks++;
    if (g_XSTile__io_chi_tx_dat_flitpend !== i_XSTile__io_chi_tx_dat_flitpend) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_chi_tx_dat_flitpend g=%h i=%h", cyc, g_XSTile__io_chi_tx_dat_flitpend, i_XSTile__io_chi_tx_dat_flitpend);
    end
    if (g_XSTile__io_chi_tx_dat_flitpend !== p_XSTile__io_chi_tx_dat_flitpend) t_XSTile__io_chi_tx_dat_flitpend = 1'b1;
    p_XSTile__io_chi_tx_dat_flitpend = g_XSTile__io_chi_tx_dat_flitpend;
    checks++;
    if (g_XSTile__io_chi_tx_dat_flitv !== i_XSTile__io_chi_tx_dat_flitv) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_chi_tx_dat_flitv g=%h i=%h", cyc, g_XSTile__io_chi_tx_dat_flitv, i_XSTile__io_chi_tx_dat_flitv);
    end
    if (g_XSTile__io_chi_tx_dat_flitv !== p_XSTile__io_chi_tx_dat_flitv) t_XSTile__io_chi_tx_dat_flitv = 1'b1;
    p_XSTile__io_chi_tx_dat_flitv = g_XSTile__io_chi_tx_dat_flitv;
    checks++;
    if (g_XSTile__io_chi_tx_dat_flit !== i_XSTile__io_chi_tx_dat_flit) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_chi_tx_dat_flit g=%h i=%h", cyc, g_XSTile__io_chi_tx_dat_flit, i_XSTile__io_chi_tx_dat_flit);
    end
    if (g_XSTile__io_chi_tx_dat_flit !== p_XSTile__io_chi_tx_dat_flit) t_XSTile__io_chi_tx_dat_flit = 1'b1;
    p_XSTile__io_chi_tx_dat_flit = g_XSTile__io_chi_tx_dat_flit;
    checks++;
    if (g_XSTile__io_chi_rx_linkactiveack !== i_XSTile__io_chi_rx_linkactiveack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_chi_rx_linkactiveack g=%h i=%h", cyc, g_XSTile__io_chi_rx_linkactiveack, i_XSTile__io_chi_rx_linkactiveack);
    end
    if (g_XSTile__io_chi_rx_linkactiveack !== p_XSTile__io_chi_rx_linkactiveack) t_XSTile__io_chi_rx_linkactiveack = 1'b1;
    p_XSTile__io_chi_rx_linkactiveack = g_XSTile__io_chi_rx_linkactiveack;
    checks++;
    if (g_XSTile__io_chi_rx_rsp_lcrdv !== i_XSTile__io_chi_rx_rsp_lcrdv) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_chi_rx_rsp_lcrdv g=%h i=%h", cyc, g_XSTile__io_chi_rx_rsp_lcrdv, i_XSTile__io_chi_rx_rsp_lcrdv);
    end
    if (g_XSTile__io_chi_rx_rsp_lcrdv !== p_XSTile__io_chi_rx_rsp_lcrdv) t_XSTile__io_chi_rx_rsp_lcrdv = 1'b1;
    p_XSTile__io_chi_rx_rsp_lcrdv = g_XSTile__io_chi_rx_rsp_lcrdv;
    checks++;
    if (g_XSTile__io_chi_rx_dat_lcrdv !== i_XSTile__io_chi_rx_dat_lcrdv) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_chi_rx_dat_lcrdv g=%h i=%h", cyc, g_XSTile__io_chi_rx_dat_lcrdv, i_XSTile__io_chi_rx_dat_lcrdv);
    end
    if (g_XSTile__io_chi_rx_dat_lcrdv !== p_XSTile__io_chi_rx_dat_lcrdv) t_XSTile__io_chi_rx_dat_lcrdv = 1'b1;
    p_XSTile__io_chi_rx_dat_lcrdv = g_XSTile__io_chi_rx_dat_lcrdv;
    checks++;
    if (g_XSTile__io_chi_rx_snp_lcrdv !== i_XSTile__io_chi_rx_snp_lcrdv) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.io_chi_rx_snp_lcrdv g=%h i=%h", cyc, g_XSTile__io_chi_rx_snp_lcrdv, i_XSTile__io_chi_rx_snp_lcrdv);
    end
    if (g_XSTile__io_chi_rx_snp_lcrdv !== p_XSTile__io_chi_rx_snp_lcrdv) t_XSTile__io_chi_rx_snp_lcrdv = 1'b1;
    p_XSTile__io_chi_rx_snp_lcrdv = g_XSTile__io_chi_rx_snp_lcrdv;
    checks++;
    if (g_XSTile__gatewayIn_packed_0_bore !== i_XSTile__gatewayIn_packed_0_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_0_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_0_bore, i_XSTile__gatewayIn_packed_0_bore);
    end
    if (g_XSTile__gatewayIn_packed_0_bore !== p_XSTile__gatewayIn_packed_0_bore) t_XSTile__gatewayIn_packed_0_bore = 1'b1;
    p_XSTile__gatewayIn_packed_0_bore = g_XSTile__gatewayIn_packed_0_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_1_bore !== i_XSTile__gatewayIn_packed_1_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_1_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_1_bore, i_XSTile__gatewayIn_packed_1_bore);
    end
    if (g_XSTile__gatewayIn_packed_1_bore !== p_XSTile__gatewayIn_packed_1_bore) t_XSTile__gatewayIn_packed_1_bore = 1'b1;
    p_XSTile__gatewayIn_packed_1_bore = g_XSTile__gatewayIn_packed_1_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_2_bore !== i_XSTile__gatewayIn_packed_2_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_2_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_2_bore, i_XSTile__gatewayIn_packed_2_bore);
    end
    if (g_XSTile__gatewayIn_packed_2_bore !== p_XSTile__gatewayIn_packed_2_bore) t_XSTile__gatewayIn_packed_2_bore = 1'b1;
    p_XSTile__gatewayIn_packed_2_bore = g_XSTile__gatewayIn_packed_2_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_3_bore !== i_XSTile__gatewayIn_packed_3_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_3_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_3_bore, i_XSTile__gatewayIn_packed_3_bore);
    end
    if (g_XSTile__gatewayIn_packed_3_bore !== p_XSTile__gatewayIn_packed_3_bore) t_XSTile__gatewayIn_packed_3_bore = 1'b1;
    p_XSTile__gatewayIn_packed_3_bore = g_XSTile__gatewayIn_packed_3_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_4_bore !== i_XSTile__gatewayIn_packed_4_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_4_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_4_bore, i_XSTile__gatewayIn_packed_4_bore);
    end
    if (g_XSTile__gatewayIn_packed_4_bore !== p_XSTile__gatewayIn_packed_4_bore) t_XSTile__gatewayIn_packed_4_bore = 1'b1;
    p_XSTile__gatewayIn_packed_4_bore = g_XSTile__gatewayIn_packed_4_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_5_bore !== i_XSTile__gatewayIn_packed_5_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_5_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_5_bore, i_XSTile__gatewayIn_packed_5_bore);
    end
    if (g_XSTile__gatewayIn_packed_5_bore !== p_XSTile__gatewayIn_packed_5_bore) t_XSTile__gatewayIn_packed_5_bore = 1'b1;
    p_XSTile__gatewayIn_packed_5_bore = g_XSTile__gatewayIn_packed_5_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_6_bore !== i_XSTile__gatewayIn_packed_6_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_6_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_6_bore, i_XSTile__gatewayIn_packed_6_bore);
    end
    if (g_XSTile__gatewayIn_packed_6_bore !== p_XSTile__gatewayIn_packed_6_bore) t_XSTile__gatewayIn_packed_6_bore = 1'b1;
    p_XSTile__gatewayIn_packed_6_bore = g_XSTile__gatewayIn_packed_6_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_7_bore !== i_XSTile__gatewayIn_packed_7_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_7_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_7_bore, i_XSTile__gatewayIn_packed_7_bore);
    end
    if (g_XSTile__gatewayIn_packed_7_bore !== p_XSTile__gatewayIn_packed_7_bore) t_XSTile__gatewayIn_packed_7_bore = 1'b1;
    p_XSTile__gatewayIn_packed_7_bore = g_XSTile__gatewayIn_packed_7_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_8_bore !== i_XSTile__gatewayIn_packed_8_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_8_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_8_bore, i_XSTile__gatewayIn_packed_8_bore);
    end
    if (g_XSTile__gatewayIn_packed_8_bore !== p_XSTile__gatewayIn_packed_8_bore) t_XSTile__gatewayIn_packed_8_bore = 1'b1;
    p_XSTile__gatewayIn_packed_8_bore = g_XSTile__gatewayIn_packed_8_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_9_bore !== i_XSTile__gatewayIn_packed_9_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_9_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_9_bore, i_XSTile__gatewayIn_packed_9_bore);
    end
    if (g_XSTile__gatewayIn_packed_9_bore !== p_XSTile__gatewayIn_packed_9_bore) t_XSTile__gatewayIn_packed_9_bore = 1'b1;
    p_XSTile__gatewayIn_packed_9_bore = g_XSTile__gatewayIn_packed_9_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_10_bore !== i_XSTile__gatewayIn_packed_10_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_10_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_10_bore, i_XSTile__gatewayIn_packed_10_bore);
    end
    if (g_XSTile__gatewayIn_packed_10_bore !== p_XSTile__gatewayIn_packed_10_bore) t_XSTile__gatewayIn_packed_10_bore = 1'b1;
    p_XSTile__gatewayIn_packed_10_bore = g_XSTile__gatewayIn_packed_10_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_11_bore !== i_XSTile__gatewayIn_packed_11_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_11_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_11_bore, i_XSTile__gatewayIn_packed_11_bore);
    end
    if (g_XSTile__gatewayIn_packed_11_bore !== p_XSTile__gatewayIn_packed_11_bore) t_XSTile__gatewayIn_packed_11_bore = 1'b1;
    p_XSTile__gatewayIn_packed_11_bore = g_XSTile__gatewayIn_packed_11_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_12_bore !== i_XSTile__gatewayIn_packed_12_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_12_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_12_bore, i_XSTile__gatewayIn_packed_12_bore);
    end
    if (g_XSTile__gatewayIn_packed_12_bore !== p_XSTile__gatewayIn_packed_12_bore) t_XSTile__gatewayIn_packed_12_bore = 1'b1;
    p_XSTile__gatewayIn_packed_12_bore = g_XSTile__gatewayIn_packed_12_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_13_bore !== i_XSTile__gatewayIn_packed_13_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_13_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_13_bore, i_XSTile__gatewayIn_packed_13_bore);
    end
    if (g_XSTile__gatewayIn_packed_13_bore !== p_XSTile__gatewayIn_packed_13_bore) t_XSTile__gatewayIn_packed_13_bore = 1'b1;
    p_XSTile__gatewayIn_packed_13_bore = g_XSTile__gatewayIn_packed_13_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_14_bore !== i_XSTile__gatewayIn_packed_14_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_14_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_14_bore, i_XSTile__gatewayIn_packed_14_bore);
    end
    if (g_XSTile__gatewayIn_packed_14_bore !== p_XSTile__gatewayIn_packed_14_bore) t_XSTile__gatewayIn_packed_14_bore = 1'b1;
    p_XSTile__gatewayIn_packed_14_bore = g_XSTile__gatewayIn_packed_14_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_15_bore !== i_XSTile__gatewayIn_packed_15_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_15_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_15_bore, i_XSTile__gatewayIn_packed_15_bore);
    end
    if (g_XSTile__gatewayIn_packed_15_bore !== p_XSTile__gatewayIn_packed_15_bore) t_XSTile__gatewayIn_packed_15_bore = 1'b1;
    p_XSTile__gatewayIn_packed_15_bore = g_XSTile__gatewayIn_packed_15_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_16_bore !== i_XSTile__gatewayIn_packed_16_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_16_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_16_bore, i_XSTile__gatewayIn_packed_16_bore);
    end
    if (g_XSTile__gatewayIn_packed_16_bore !== p_XSTile__gatewayIn_packed_16_bore) t_XSTile__gatewayIn_packed_16_bore = 1'b1;
    p_XSTile__gatewayIn_packed_16_bore = g_XSTile__gatewayIn_packed_16_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_17_bore !== i_XSTile__gatewayIn_packed_17_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_17_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_17_bore, i_XSTile__gatewayIn_packed_17_bore);
    end
    if (g_XSTile__gatewayIn_packed_17_bore !== p_XSTile__gatewayIn_packed_17_bore) t_XSTile__gatewayIn_packed_17_bore = 1'b1;
    p_XSTile__gatewayIn_packed_17_bore = g_XSTile__gatewayIn_packed_17_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_18_bore !== i_XSTile__gatewayIn_packed_18_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_18_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_18_bore, i_XSTile__gatewayIn_packed_18_bore);
    end
    if (g_XSTile__gatewayIn_packed_18_bore !== p_XSTile__gatewayIn_packed_18_bore) t_XSTile__gatewayIn_packed_18_bore = 1'b1;
    p_XSTile__gatewayIn_packed_18_bore = g_XSTile__gatewayIn_packed_18_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_19_bore !== i_XSTile__gatewayIn_packed_19_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_19_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_19_bore, i_XSTile__gatewayIn_packed_19_bore);
    end
    if (g_XSTile__gatewayIn_packed_19_bore !== p_XSTile__gatewayIn_packed_19_bore) t_XSTile__gatewayIn_packed_19_bore = 1'b1;
    p_XSTile__gatewayIn_packed_19_bore = g_XSTile__gatewayIn_packed_19_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_20_bore !== i_XSTile__gatewayIn_packed_20_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_20_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_20_bore, i_XSTile__gatewayIn_packed_20_bore);
    end
    if (g_XSTile__gatewayIn_packed_20_bore !== p_XSTile__gatewayIn_packed_20_bore) t_XSTile__gatewayIn_packed_20_bore = 1'b1;
    p_XSTile__gatewayIn_packed_20_bore = g_XSTile__gatewayIn_packed_20_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_21_bore !== i_XSTile__gatewayIn_packed_21_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_21_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_21_bore, i_XSTile__gatewayIn_packed_21_bore);
    end
    if (g_XSTile__gatewayIn_packed_21_bore !== p_XSTile__gatewayIn_packed_21_bore) t_XSTile__gatewayIn_packed_21_bore = 1'b1;
    p_XSTile__gatewayIn_packed_21_bore = g_XSTile__gatewayIn_packed_21_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_22_bore !== i_XSTile__gatewayIn_packed_22_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_22_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_22_bore, i_XSTile__gatewayIn_packed_22_bore);
    end
    if (g_XSTile__gatewayIn_packed_22_bore !== p_XSTile__gatewayIn_packed_22_bore) t_XSTile__gatewayIn_packed_22_bore = 1'b1;
    p_XSTile__gatewayIn_packed_22_bore = g_XSTile__gatewayIn_packed_22_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_23_bore !== i_XSTile__gatewayIn_packed_23_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_23_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_23_bore, i_XSTile__gatewayIn_packed_23_bore);
    end
    if (g_XSTile__gatewayIn_packed_23_bore !== p_XSTile__gatewayIn_packed_23_bore) t_XSTile__gatewayIn_packed_23_bore = 1'b1;
    p_XSTile__gatewayIn_packed_23_bore = g_XSTile__gatewayIn_packed_23_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_24_bore !== i_XSTile__gatewayIn_packed_24_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_24_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_24_bore, i_XSTile__gatewayIn_packed_24_bore);
    end
    if (g_XSTile__gatewayIn_packed_24_bore !== p_XSTile__gatewayIn_packed_24_bore) t_XSTile__gatewayIn_packed_24_bore = 1'b1;
    p_XSTile__gatewayIn_packed_24_bore = g_XSTile__gatewayIn_packed_24_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_25_bore !== i_XSTile__gatewayIn_packed_25_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_25_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_25_bore, i_XSTile__gatewayIn_packed_25_bore);
    end
    if (g_XSTile__gatewayIn_packed_25_bore !== p_XSTile__gatewayIn_packed_25_bore) t_XSTile__gatewayIn_packed_25_bore = 1'b1;
    p_XSTile__gatewayIn_packed_25_bore = g_XSTile__gatewayIn_packed_25_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_26_bore !== i_XSTile__gatewayIn_packed_26_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_26_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_26_bore, i_XSTile__gatewayIn_packed_26_bore);
    end
    if (g_XSTile__gatewayIn_packed_26_bore !== p_XSTile__gatewayIn_packed_26_bore) t_XSTile__gatewayIn_packed_26_bore = 1'b1;
    p_XSTile__gatewayIn_packed_26_bore = g_XSTile__gatewayIn_packed_26_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_27_bore !== i_XSTile__gatewayIn_packed_27_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_27_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_27_bore, i_XSTile__gatewayIn_packed_27_bore);
    end
    if (g_XSTile__gatewayIn_packed_27_bore !== p_XSTile__gatewayIn_packed_27_bore) t_XSTile__gatewayIn_packed_27_bore = 1'b1;
    p_XSTile__gatewayIn_packed_27_bore = g_XSTile__gatewayIn_packed_27_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_28_bore !== i_XSTile__gatewayIn_packed_28_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_28_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_28_bore, i_XSTile__gatewayIn_packed_28_bore);
    end
    if (g_XSTile__gatewayIn_packed_28_bore !== p_XSTile__gatewayIn_packed_28_bore) t_XSTile__gatewayIn_packed_28_bore = 1'b1;
    p_XSTile__gatewayIn_packed_28_bore = g_XSTile__gatewayIn_packed_28_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_29_bore !== i_XSTile__gatewayIn_packed_29_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_29_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_29_bore, i_XSTile__gatewayIn_packed_29_bore);
    end
    if (g_XSTile__gatewayIn_packed_29_bore !== p_XSTile__gatewayIn_packed_29_bore) t_XSTile__gatewayIn_packed_29_bore = 1'b1;
    p_XSTile__gatewayIn_packed_29_bore = g_XSTile__gatewayIn_packed_29_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_30_bore !== i_XSTile__gatewayIn_packed_30_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_30_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_30_bore, i_XSTile__gatewayIn_packed_30_bore);
    end
    if (g_XSTile__gatewayIn_packed_30_bore !== p_XSTile__gatewayIn_packed_30_bore) t_XSTile__gatewayIn_packed_30_bore = 1'b1;
    p_XSTile__gatewayIn_packed_30_bore = g_XSTile__gatewayIn_packed_30_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_31_bore !== i_XSTile__gatewayIn_packed_31_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_31_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_31_bore, i_XSTile__gatewayIn_packed_31_bore);
    end
    if (g_XSTile__gatewayIn_packed_31_bore !== p_XSTile__gatewayIn_packed_31_bore) t_XSTile__gatewayIn_packed_31_bore = 1'b1;
    p_XSTile__gatewayIn_packed_31_bore = g_XSTile__gatewayIn_packed_31_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_32_bore !== i_XSTile__gatewayIn_packed_32_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_32_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_32_bore, i_XSTile__gatewayIn_packed_32_bore);
    end
    if (g_XSTile__gatewayIn_packed_32_bore !== p_XSTile__gatewayIn_packed_32_bore) t_XSTile__gatewayIn_packed_32_bore = 1'b1;
    p_XSTile__gatewayIn_packed_32_bore = g_XSTile__gatewayIn_packed_32_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_33_bore !== i_XSTile__gatewayIn_packed_33_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_33_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_33_bore, i_XSTile__gatewayIn_packed_33_bore);
    end
    if (g_XSTile__gatewayIn_packed_33_bore !== p_XSTile__gatewayIn_packed_33_bore) t_XSTile__gatewayIn_packed_33_bore = 1'b1;
    p_XSTile__gatewayIn_packed_33_bore = g_XSTile__gatewayIn_packed_33_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_34_bore !== i_XSTile__gatewayIn_packed_34_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_34_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_34_bore, i_XSTile__gatewayIn_packed_34_bore);
    end
    if (g_XSTile__gatewayIn_packed_34_bore !== p_XSTile__gatewayIn_packed_34_bore) t_XSTile__gatewayIn_packed_34_bore = 1'b1;
    p_XSTile__gatewayIn_packed_34_bore = g_XSTile__gatewayIn_packed_34_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_35_bore !== i_XSTile__gatewayIn_packed_35_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_35_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_35_bore, i_XSTile__gatewayIn_packed_35_bore);
    end
    if (g_XSTile__gatewayIn_packed_35_bore !== p_XSTile__gatewayIn_packed_35_bore) t_XSTile__gatewayIn_packed_35_bore = 1'b1;
    p_XSTile__gatewayIn_packed_35_bore = g_XSTile__gatewayIn_packed_35_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_36_bore !== i_XSTile__gatewayIn_packed_36_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_36_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_36_bore, i_XSTile__gatewayIn_packed_36_bore);
    end
    if (g_XSTile__gatewayIn_packed_36_bore !== p_XSTile__gatewayIn_packed_36_bore) t_XSTile__gatewayIn_packed_36_bore = 1'b1;
    p_XSTile__gatewayIn_packed_36_bore = g_XSTile__gatewayIn_packed_36_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_37_bore !== i_XSTile__gatewayIn_packed_37_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_37_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_37_bore, i_XSTile__gatewayIn_packed_37_bore);
    end
    if (g_XSTile__gatewayIn_packed_37_bore !== p_XSTile__gatewayIn_packed_37_bore) t_XSTile__gatewayIn_packed_37_bore = 1'b1;
    p_XSTile__gatewayIn_packed_37_bore = g_XSTile__gatewayIn_packed_37_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_38_bore !== i_XSTile__gatewayIn_packed_38_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_38_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_38_bore, i_XSTile__gatewayIn_packed_38_bore);
    end
    if (g_XSTile__gatewayIn_packed_38_bore !== p_XSTile__gatewayIn_packed_38_bore) t_XSTile__gatewayIn_packed_38_bore = 1'b1;
    p_XSTile__gatewayIn_packed_38_bore = g_XSTile__gatewayIn_packed_38_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_39_bore !== i_XSTile__gatewayIn_packed_39_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_39_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_39_bore, i_XSTile__gatewayIn_packed_39_bore);
    end
    if (g_XSTile__gatewayIn_packed_39_bore !== p_XSTile__gatewayIn_packed_39_bore) t_XSTile__gatewayIn_packed_39_bore = 1'b1;
    p_XSTile__gatewayIn_packed_39_bore = g_XSTile__gatewayIn_packed_39_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_40_bore !== i_XSTile__gatewayIn_packed_40_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_40_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_40_bore, i_XSTile__gatewayIn_packed_40_bore);
    end
    if (g_XSTile__gatewayIn_packed_40_bore !== p_XSTile__gatewayIn_packed_40_bore) t_XSTile__gatewayIn_packed_40_bore = 1'b1;
    p_XSTile__gatewayIn_packed_40_bore = g_XSTile__gatewayIn_packed_40_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_41_bore !== i_XSTile__gatewayIn_packed_41_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_41_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_41_bore, i_XSTile__gatewayIn_packed_41_bore);
    end
    if (g_XSTile__gatewayIn_packed_41_bore !== p_XSTile__gatewayIn_packed_41_bore) t_XSTile__gatewayIn_packed_41_bore = 1'b1;
    p_XSTile__gatewayIn_packed_41_bore = g_XSTile__gatewayIn_packed_41_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_42_bore !== i_XSTile__gatewayIn_packed_42_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_42_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_42_bore, i_XSTile__gatewayIn_packed_42_bore);
    end
    if (g_XSTile__gatewayIn_packed_42_bore !== p_XSTile__gatewayIn_packed_42_bore) t_XSTile__gatewayIn_packed_42_bore = 1'b1;
    p_XSTile__gatewayIn_packed_42_bore = g_XSTile__gatewayIn_packed_42_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_43_bore !== i_XSTile__gatewayIn_packed_43_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_43_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_43_bore, i_XSTile__gatewayIn_packed_43_bore);
    end
    if (g_XSTile__gatewayIn_packed_43_bore !== p_XSTile__gatewayIn_packed_43_bore) t_XSTile__gatewayIn_packed_43_bore = 1'b1;
    p_XSTile__gatewayIn_packed_43_bore = g_XSTile__gatewayIn_packed_43_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_44_bore !== i_XSTile__gatewayIn_packed_44_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_44_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_44_bore, i_XSTile__gatewayIn_packed_44_bore);
    end
    if (g_XSTile__gatewayIn_packed_44_bore !== p_XSTile__gatewayIn_packed_44_bore) t_XSTile__gatewayIn_packed_44_bore = 1'b1;
    p_XSTile__gatewayIn_packed_44_bore = g_XSTile__gatewayIn_packed_44_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_45_bore !== i_XSTile__gatewayIn_packed_45_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_45_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_45_bore, i_XSTile__gatewayIn_packed_45_bore);
    end
    if (g_XSTile__gatewayIn_packed_45_bore !== p_XSTile__gatewayIn_packed_45_bore) t_XSTile__gatewayIn_packed_45_bore = 1'b1;
    p_XSTile__gatewayIn_packed_45_bore = g_XSTile__gatewayIn_packed_45_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_46_bore !== i_XSTile__gatewayIn_packed_46_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_46_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_46_bore, i_XSTile__gatewayIn_packed_46_bore);
    end
    if (g_XSTile__gatewayIn_packed_46_bore !== p_XSTile__gatewayIn_packed_46_bore) t_XSTile__gatewayIn_packed_46_bore = 1'b1;
    p_XSTile__gatewayIn_packed_46_bore = g_XSTile__gatewayIn_packed_46_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_47_bore !== i_XSTile__gatewayIn_packed_47_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_47_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_47_bore, i_XSTile__gatewayIn_packed_47_bore);
    end
    if (g_XSTile__gatewayIn_packed_47_bore !== p_XSTile__gatewayIn_packed_47_bore) t_XSTile__gatewayIn_packed_47_bore = 1'b1;
    p_XSTile__gatewayIn_packed_47_bore = g_XSTile__gatewayIn_packed_47_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_48_bore !== i_XSTile__gatewayIn_packed_48_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_48_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_48_bore, i_XSTile__gatewayIn_packed_48_bore);
    end
    if (g_XSTile__gatewayIn_packed_48_bore !== p_XSTile__gatewayIn_packed_48_bore) t_XSTile__gatewayIn_packed_48_bore = 1'b1;
    p_XSTile__gatewayIn_packed_48_bore = g_XSTile__gatewayIn_packed_48_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_49_bore !== i_XSTile__gatewayIn_packed_49_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_49_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_49_bore, i_XSTile__gatewayIn_packed_49_bore);
    end
    if (g_XSTile__gatewayIn_packed_49_bore !== p_XSTile__gatewayIn_packed_49_bore) t_XSTile__gatewayIn_packed_49_bore = 1'b1;
    p_XSTile__gatewayIn_packed_49_bore = g_XSTile__gatewayIn_packed_49_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_50_bore !== i_XSTile__gatewayIn_packed_50_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_50_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_50_bore, i_XSTile__gatewayIn_packed_50_bore);
    end
    if (g_XSTile__gatewayIn_packed_50_bore !== p_XSTile__gatewayIn_packed_50_bore) t_XSTile__gatewayIn_packed_50_bore = 1'b1;
    p_XSTile__gatewayIn_packed_50_bore = g_XSTile__gatewayIn_packed_50_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_51_bore !== i_XSTile__gatewayIn_packed_51_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_51_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_51_bore, i_XSTile__gatewayIn_packed_51_bore);
    end
    if (g_XSTile__gatewayIn_packed_51_bore !== p_XSTile__gatewayIn_packed_51_bore) t_XSTile__gatewayIn_packed_51_bore = 1'b1;
    p_XSTile__gatewayIn_packed_51_bore = g_XSTile__gatewayIn_packed_51_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_52_bore !== i_XSTile__gatewayIn_packed_52_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_52_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_52_bore, i_XSTile__gatewayIn_packed_52_bore);
    end
    if (g_XSTile__gatewayIn_packed_52_bore !== p_XSTile__gatewayIn_packed_52_bore) t_XSTile__gatewayIn_packed_52_bore = 1'b1;
    p_XSTile__gatewayIn_packed_52_bore = g_XSTile__gatewayIn_packed_52_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_53_bore !== i_XSTile__gatewayIn_packed_53_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_53_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_53_bore, i_XSTile__gatewayIn_packed_53_bore);
    end
    if (g_XSTile__gatewayIn_packed_53_bore !== p_XSTile__gatewayIn_packed_53_bore) t_XSTile__gatewayIn_packed_53_bore = 1'b1;
    p_XSTile__gatewayIn_packed_53_bore = g_XSTile__gatewayIn_packed_53_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_54_bore !== i_XSTile__gatewayIn_packed_54_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_54_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_54_bore, i_XSTile__gatewayIn_packed_54_bore);
    end
    if (g_XSTile__gatewayIn_packed_54_bore !== p_XSTile__gatewayIn_packed_54_bore) t_XSTile__gatewayIn_packed_54_bore = 1'b1;
    p_XSTile__gatewayIn_packed_54_bore = g_XSTile__gatewayIn_packed_54_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_55_bore !== i_XSTile__gatewayIn_packed_55_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_55_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_55_bore, i_XSTile__gatewayIn_packed_55_bore);
    end
    if (g_XSTile__gatewayIn_packed_55_bore !== p_XSTile__gatewayIn_packed_55_bore) t_XSTile__gatewayIn_packed_55_bore = 1'b1;
    p_XSTile__gatewayIn_packed_55_bore = g_XSTile__gatewayIn_packed_55_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_56_bore !== i_XSTile__gatewayIn_packed_56_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_56_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_56_bore, i_XSTile__gatewayIn_packed_56_bore);
    end
    if (g_XSTile__gatewayIn_packed_56_bore !== p_XSTile__gatewayIn_packed_56_bore) t_XSTile__gatewayIn_packed_56_bore = 1'b1;
    p_XSTile__gatewayIn_packed_56_bore = g_XSTile__gatewayIn_packed_56_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_57_bore !== i_XSTile__gatewayIn_packed_57_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_57_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_57_bore, i_XSTile__gatewayIn_packed_57_bore);
    end
    if (g_XSTile__gatewayIn_packed_57_bore !== p_XSTile__gatewayIn_packed_57_bore) t_XSTile__gatewayIn_packed_57_bore = 1'b1;
    p_XSTile__gatewayIn_packed_57_bore = g_XSTile__gatewayIn_packed_57_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_58_bore !== i_XSTile__gatewayIn_packed_58_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_58_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_58_bore, i_XSTile__gatewayIn_packed_58_bore);
    end
    if (g_XSTile__gatewayIn_packed_58_bore !== p_XSTile__gatewayIn_packed_58_bore) t_XSTile__gatewayIn_packed_58_bore = 1'b1;
    p_XSTile__gatewayIn_packed_58_bore = g_XSTile__gatewayIn_packed_58_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_59_bore !== i_XSTile__gatewayIn_packed_59_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_59_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_59_bore, i_XSTile__gatewayIn_packed_59_bore);
    end
    if (g_XSTile__gatewayIn_packed_59_bore !== p_XSTile__gatewayIn_packed_59_bore) t_XSTile__gatewayIn_packed_59_bore = 1'b1;
    p_XSTile__gatewayIn_packed_59_bore = g_XSTile__gatewayIn_packed_59_bore;
    checks++;
    if (g_XSTile__gatewayIn_packed_60_bore !== i_XSTile__gatewayIn_packed_60_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSTile.gatewayIn_packed_60_bore g=%h i=%h", cyc, g_XSTile__gatewayIn_packed_60_bore, i_XSTile__gatewayIn_packed_60_bore);
    end
    if (g_XSTile__gatewayIn_packed_60_bore !== p_XSTile__gatewayIn_packed_60_bore) t_XSTile__gatewayIn_packed_60_bore = 1'b1;
    p_XSTile__gatewayIn_packed_60_bore = g_XSTile__gatewayIn_packed_60_bore;
  endtask
  longint cov_XSTile_immio_a = 0;
  longint cov_XSTile_trace_v = 0;
  longint cov_XSTile_msi_v = 0;
  longint cov_XSTile_int_clint = 0;
  longint cov_XSTile_int_plic = 0;
  longint cov_XSTile_int_debug = 0;
  longint cov_XSTile_int_nmi = 0;
  task automatic cover_XSTile();
    if (u_g_XSTile._core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid) cov_XSTile_immio_a++;
    if (u_g_XSTile._core_io_traceCoreInterface_toEncoder_groups_0_valid) cov_XSTile_trace_v++;
    if (u_g_XSTile._l2top_io_msiInfo_toCore_valid) cov_XSTile_msi_v++;
    if (u_g_XSTile._intBuffer_auto_out_0) cov_XSTile_int_clint++;
    if (u_g_XSTile._intBuffer_1_auto_out_0_0) cov_XSTile_int_plic++;
    if (u_g_XSTile._intBuffer_2_auto_out_0) cov_XSTile_int_debug++;
    if (u_g_XSTile._intBuffer_3_auto_out_0) cov_XSTile_int_nmi++;
  endtask
  task automatic preinit_XSTile();
  endtask
  task automatic sync_XSTile();
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_XSTile();
    #1;
    preinit_XSTile();
    sync_XSTile();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 20000) == 0) reset = 1'b1;
      drive_XSTile();
      #1;
      check_XSTile();
      cover_XSTile();
    end
    begin int tg; tg = 0;
      if (t_XSTile__auto_l2top_inner_beu_int_out_0) tg++; else $display("COV: XSTile.auto_l2top_inner_beu_int_out_0 never toggled");
      if (t_XSTile__io_msiAck) tg++; else $display("COV: XSTile.io_msiAck never toggled");
      if (t_XSTile__io_cpu_halt) tg++; else $display("COV: XSTile.io_cpu_halt never toggled");
      if (t_XSTile__io_cpu_crtical_error) tg++; else $display("COV: XSTile.io_cpu_crtical_error never toggled");
      if (t_XSTile__io_hartIsInReset) tg++; else $display("COV: XSTile.io_hartIsInReset never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_priv) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_priv never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_mstatus) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_mstatus never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_trap_cause) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_trap_cause never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_trap_tval) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_trap_tval never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_groups_0_valid) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_groups_0_valid never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_groups_0_bits_iaddr never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_itype) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_groups_0_bits_itype never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_iretire) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_groups_0_bits_iretire never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_groups_1_valid) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_groups_1_valid never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_groups_1_bits_iaddr never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_itype) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_groups_1_bits_itype never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_iretire) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_groups_1_bits_iretire never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_groups_2_valid) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_groups_2_valid never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_groups_2_bits_iaddr never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_itype) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_groups_2_bits_itype never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_iretire) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_groups_2_bits_iretire never toggled");
      if (t_XSTile__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize) tg++; else $display("COV: XSTile.io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize never toggled");
      if (t_XSTile__io_debugTopDown_robHeadPaddr_valid) tg++; else $display("COV: XSTile.io_debugTopDown_robHeadPaddr_valid never toggled");
      if (t_XSTile__io_debugTopDown_robHeadPaddr_bits) tg++; else $display("COV: XSTile.io_debugTopDown_robHeadPaddr_bits never toggled");
      if (t_XSTile__io_chi_txsactive) tg++; else $display("COV: XSTile.io_chi_txsactive never toggled");
      if (t_XSTile__io_chi_syscoreq) tg++; else $display("COV: XSTile.io_chi_syscoreq never toggled");
      if (t_XSTile__io_chi_tx_linkactivereq) tg++; else $display("COV: XSTile.io_chi_tx_linkactivereq never toggled");
      if (t_XSTile__io_chi_tx_req_flitpend) tg++; else $display("COV: XSTile.io_chi_tx_req_flitpend never toggled");
      if (t_XSTile__io_chi_tx_req_flitv) tg++; else $display("COV: XSTile.io_chi_tx_req_flitv never toggled");
      if (t_XSTile__io_chi_tx_req_flit) tg++; else $display("COV: XSTile.io_chi_tx_req_flit never toggled");
      if (t_XSTile__io_chi_tx_rsp_flitpend) tg++; else $display("COV: XSTile.io_chi_tx_rsp_flitpend never toggled");
      if (t_XSTile__io_chi_tx_rsp_flitv) tg++; else $display("COV: XSTile.io_chi_tx_rsp_flitv never toggled");
      if (t_XSTile__io_chi_tx_rsp_flit) tg++; else $display("COV: XSTile.io_chi_tx_rsp_flit never toggled");
      if (t_XSTile__io_chi_tx_dat_flitpend) tg++; else $display("COV: XSTile.io_chi_tx_dat_flitpend never toggled");
      if (t_XSTile__io_chi_tx_dat_flitv) tg++; else $display("COV: XSTile.io_chi_tx_dat_flitv never toggled");
      if (t_XSTile__io_chi_tx_dat_flit) tg++; else $display("COV: XSTile.io_chi_tx_dat_flit never toggled");
      if (t_XSTile__io_chi_rx_linkactiveack) tg++; else $display("COV: XSTile.io_chi_rx_linkactiveack never toggled");
      if (t_XSTile__io_chi_rx_rsp_lcrdv) tg++; else $display("COV: XSTile.io_chi_rx_rsp_lcrdv never toggled");
      if (t_XSTile__io_chi_rx_dat_lcrdv) tg++; else $display("COV: XSTile.io_chi_rx_dat_lcrdv never toggled");
      if (t_XSTile__io_chi_rx_snp_lcrdv) tg++; else $display("COV: XSTile.io_chi_rx_snp_lcrdv never toggled");
      if (t_XSTile__gatewayIn_packed_0_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_0_bore never toggled");
      if (t_XSTile__gatewayIn_packed_1_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_1_bore never toggled");
      if (t_XSTile__gatewayIn_packed_2_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_2_bore never toggled");
      if (t_XSTile__gatewayIn_packed_3_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_3_bore never toggled");
      if (t_XSTile__gatewayIn_packed_4_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_4_bore never toggled");
      if (t_XSTile__gatewayIn_packed_5_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_5_bore never toggled");
      if (t_XSTile__gatewayIn_packed_6_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_6_bore never toggled");
      if (t_XSTile__gatewayIn_packed_7_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_7_bore never toggled");
      if (t_XSTile__gatewayIn_packed_8_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_8_bore never toggled");
      if (t_XSTile__gatewayIn_packed_9_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_9_bore never toggled");
      if (t_XSTile__gatewayIn_packed_10_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_10_bore never toggled");
      if (t_XSTile__gatewayIn_packed_11_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_11_bore never toggled");
      if (t_XSTile__gatewayIn_packed_12_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_12_bore never toggled");
      if (t_XSTile__gatewayIn_packed_13_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_13_bore never toggled");
      if (t_XSTile__gatewayIn_packed_14_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_14_bore never toggled");
      if (t_XSTile__gatewayIn_packed_15_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_15_bore never toggled");
      if (t_XSTile__gatewayIn_packed_16_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_16_bore never toggled");
      if (t_XSTile__gatewayIn_packed_17_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_17_bore never toggled");
      if (t_XSTile__gatewayIn_packed_18_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_18_bore never toggled");
      if (t_XSTile__gatewayIn_packed_19_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_19_bore never toggled");
      if (t_XSTile__gatewayIn_packed_20_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_20_bore never toggled");
      if (t_XSTile__gatewayIn_packed_21_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_21_bore never toggled");
      if (t_XSTile__gatewayIn_packed_22_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_22_bore never toggled");
      if (t_XSTile__gatewayIn_packed_23_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_23_bore never toggled");
      if (t_XSTile__gatewayIn_packed_24_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_24_bore never toggled");
      if (t_XSTile__gatewayIn_packed_25_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_25_bore never toggled");
      if (t_XSTile__gatewayIn_packed_26_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_26_bore never toggled");
      if (t_XSTile__gatewayIn_packed_27_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_27_bore never toggled");
      if (t_XSTile__gatewayIn_packed_28_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_28_bore never toggled");
      if (t_XSTile__gatewayIn_packed_29_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_29_bore never toggled");
      if (t_XSTile__gatewayIn_packed_30_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_30_bore never toggled");
      if (t_XSTile__gatewayIn_packed_31_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_31_bore never toggled");
      if (t_XSTile__gatewayIn_packed_32_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_32_bore never toggled");
      if (t_XSTile__gatewayIn_packed_33_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_33_bore never toggled");
      if (t_XSTile__gatewayIn_packed_34_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_34_bore never toggled");
      if (t_XSTile__gatewayIn_packed_35_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_35_bore never toggled");
      if (t_XSTile__gatewayIn_packed_36_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_36_bore never toggled");
      if (t_XSTile__gatewayIn_packed_37_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_37_bore never toggled");
      if (t_XSTile__gatewayIn_packed_38_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_38_bore never toggled");
      if (t_XSTile__gatewayIn_packed_39_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_39_bore never toggled");
      if (t_XSTile__gatewayIn_packed_40_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_40_bore never toggled");
      if (t_XSTile__gatewayIn_packed_41_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_41_bore never toggled");
      if (t_XSTile__gatewayIn_packed_42_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_42_bore never toggled");
      if (t_XSTile__gatewayIn_packed_43_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_43_bore never toggled");
      if (t_XSTile__gatewayIn_packed_44_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_44_bore never toggled");
      if (t_XSTile__gatewayIn_packed_45_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_45_bore never toggled");
      if (t_XSTile__gatewayIn_packed_46_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_46_bore never toggled");
      if (t_XSTile__gatewayIn_packed_47_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_47_bore never toggled");
      if (t_XSTile__gatewayIn_packed_48_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_48_bore never toggled");
      if (t_XSTile__gatewayIn_packed_49_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_49_bore never toggled");
      if (t_XSTile__gatewayIn_packed_50_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_50_bore never toggled");
      if (t_XSTile__gatewayIn_packed_51_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_51_bore never toggled");
      if (t_XSTile__gatewayIn_packed_52_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_52_bore never toggled");
      if (t_XSTile__gatewayIn_packed_53_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_53_bore never toggled");
      if (t_XSTile__gatewayIn_packed_54_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_54_bore never toggled");
      if (t_XSTile__gatewayIn_packed_55_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_55_bore never toggled");
      if (t_XSTile__gatewayIn_packed_56_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_56_bore never toggled");
      if (t_XSTile__gatewayIn_packed_57_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_57_bore never toggled");
      if (t_XSTile__gatewayIn_packed_58_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_58_bore never toggled");
      if (t_XSTile__gatewayIn_packed_59_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_59_bore never toggled");
      if (t_XSTile__gatewayIn_packed_60_bore) tg++; else $display("COV: XSTile.gatewayIn_packed_60_bore never toggled");
      $display("XSTile: toggled=%0d/103 (need >= 1)", tg);
      if (tg < 1) covfail = 1;
      $display("XSTile: cover immio_a = %0d", cov_XSTile_immio_a);
      if (cov_XSTile_immio_a == 0) covfail = 1;
      $display("XSTile: cover trace_v = %0d", cov_XSTile_trace_v);
      if (cov_XSTile_trace_v == 0) covfail = 1;
      $display("XSTile: cover msi_v = %0d", cov_XSTile_msi_v);
      if (cov_XSTile_msi_v == 0) covfail = 1;
      $display("XSTile: cover int_clint = %0d", cov_XSTile_int_clint);
      if (cov_XSTile_int_clint == 0) covfail = 1;
      $display("XSTile: cover int_plic = %0d", cov_XSTile_int_plic);
      if (cov_XSTile_int_plic == 0) covfail = 1;
      $display("XSTile: cover int_debug = %0d", cov_XSTile_int_debug);
      if (cov_XSTile_int_debug == 0) covfail = 1;
      $display("XSTile: cover int_nmi = %0d", cov_XSTile_int_nmi);
      if (cov_XSTile_int_nmi == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
