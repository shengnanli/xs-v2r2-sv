// 自动生成:scripts/gen_xstile.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)

`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic auto_l2top_inner_nmi_int_in_0;
  logic auto_l2top_inner_nmi_int_in_1;
  logic auto_l2top_inner_plic_int_in_1_0;
  logic auto_l2top_inner_plic_int_in_0_0;
  logic auto_l2top_inner_debug_int_in_0;
  logic auto_l2top_inner_clint_int_in_0;
  logic auto_l2top_inner_clint_int_in_1;
  logic [5:0] io_hartId;
  logic io_msiInfo_valid;
  logic [10:0] io_msiInfo_bits;
  logic [47:0] io_reset_vector;
  logic io_traceCoreInterface_fromEncoder_enable;
  logic io_traceCoreInterface_fromEncoder_stall;
  logic io_debugTopDown_l3MissMatch;
  logic io_l3Miss;
  logic io_chi_rxsactive;
  logic io_chi_syscoack;
  logic io_chi_tx_linkactiveack;
  logic io_chi_tx_req_lcrdv;
  logic io_chi_tx_rsp_lcrdv;
  logic io_chi_tx_dat_lcrdv;
  logic io_chi_rx_linkactivereq;
  logic io_chi_rx_rsp_flitpend;
  logic io_chi_rx_rsp_flitv;
  logic [72:0] io_chi_rx_rsp_flit;
  logic io_chi_rx_dat_flitpend;
  logic io_chi_rx_dat_flitv;
  logic [421:0] io_chi_rx_dat_flit;
  logic io_chi_rx_snp_flitpend;
  logic io_chi_rx_snp_flitv;
  logic [114:0] io_chi_rx_snp_flit;
  logic [10:0] io_nodeID;
  logic io_clintTime_valid;
  logic [63:0] io_clintTime_bits;
  logic io_dft_ram_hold;
  logic io_dft_ram_bypass;
  logic io_dft_ram_bp_clken;
  logic io_dft_ram_aux_clk;
  logic io_dft_ram_aux_ckbp;
  logic io_dft_ram_mcp_hold;
  logic [63:0] io_dft_ram_ctl;
  logic io_dft_cgen;
  logic io_dft_reset_lgc_rst_n;
  logic io_dft_reset_mode;
  logic io_dft_reset_scan_mode;
  wire g_auto_l2top_inner_beu_int_out_0;
  wire i_auto_l2top_inner_beu_int_out_0;
  wire g_io_cpu_halt;
  wire i_io_cpu_halt;
  wire g_io_cpu_crtical_error;
  wire i_io_cpu_crtical_error;
  wire g_io_hartIsInReset;
  wire i_io_hartIsInReset;
  wire [2:0] g_io_traceCoreInterface_toEncoder_priv;
  wire [2:0] i_io_traceCoreInterface_toEncoder_priv;
  wire [63:0] g_io_traceCoreInterface_toEncoder_trap_cause;
  wire [63:0] i_io_traceCoreInterface_toEncoder_trap_cause;
  wire [49:0] g_io_traceCoreInterface_toEncoder_trap_tval;
  wire [49:0] i_io_traceCoreInterface_toEncoder_trap_tval;
  wire [49:0] g_io_traceCoreInterface_toEncoder_groups_0_bits_iaddr;
  wire [49:0] i_io_traceCoreInterface_toEncoder_groups_0_bits_iaddr;
  wire [3:0] g_io_traceCoreInterface_toEncoder_groups_0_bits_itype;
  wire [3:0] i_io_traceCoreInterface_toEncoder_groups_0_bits_itype;
  wire [6:0] g_io_traceCoreInterface_toEncoder_groups_0_bits_iretire;
  wire [6:0] i_io_traceCoreInterface_toEncoder_groups_0_bits_iretire;
  wire g_io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize;
  wire i_io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize;
  wire [49:0] g_io_traceCoreInterface_toEncoder_groups_1_bits_iaddr;
  wire [49:0] i_io_traceCoreInterface_toEncoder_groups_1_bits_iaddr;
  wire [3:0] g_io_traceCoreInterface_toEncoder_groups_1_bits_itype;
  wire [3:0] i_io_traceCoreInterface_toEncoder_groups_1_bits_itype;
  wire [6:0] g_io_traceCoreInterface_toEncoder_groups_1_bits_iretire;
  wire [6:0] i_io_traceCoreInterface_toEncoder_groups_1_bits_iretire;
  wire g_io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize;
  wire i_io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize;
  wire [49:0] g_io_traceCoreInterface_toEncoder_groups_2_bits_iaddr;
  wire [49:0] i_io_traceCoreInterface_toEncoder_groups_2_bits_iaddr;
  wire [3:0] g_io_traceCoreInterface_toEncoder_groups_2_bits_itype;
  wire [3:0] i_io_traceCoreInterface_toEncoder_groups_2_bits_itype;
  wire [6:0] g_io_traceCoreInterface_toEncoder_groups_2_bits_iretire;
  wire [6:0] i_io_traceCoreInterface_toEncoder_groups_2_bits_iretire;
  wire g_io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize;
  wire i_io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize;
  wire g_io_debugTopDown_robHeadPaddr_valid;
  wire i_io_debugTopDown_robHeadPaddr_valid;
  wire [47:0] g_io_debugTopDown_robHeadPaddr_bits;
  wire [47:0] i_io_debugTopDown_robHeadPaddr_bits;
  wire g_io_chi_txsactive;
  wire i_io_chi_txsactive;
  wire g_io_chi_syscoreq;
  wire i_io_chi_syscoreq;
  wire g_io_chi_tx_linkactivereq;
  wire i_io_chi_tx_linkactivereq;
  wire g_io_chi_tx_req_flitpend;
  wire i_io_chi_tx_req_flitpend;
  wire g_io_chi_tx_req_flitv;
  wire i_io_chi_tx_req_flitv;
  wire [161:0] g_io_chi_tx_req_flit;
  wire [161:0] i_io_chi_tx_req_flit;
  wire g_io_chi_tx_rsp_flitpend;
  wire i_io_chi_tx_rsp_flitpend;
  wire g_io_chi_tx_rsp_flitv;
  wire i_io_chi_tx_rsp_flitv;
  wire [72:0] g_io_chi_tx_rsp_flit;
  wire [72:0] i_io_chi_tx_rsp_flit;
  wire g_io_chi_tx_dat_flitpend;
  wire i_io_chi_tx_dat_flitpend;
  wire g_io_chi_tx_dat_flitv;
  wire i_io_chi_tx_dat_flitv;
  wire [421:0] g_io_chi_tx_dat_flit;
  wire [421:0] i_io_chi_tx_dat_flit;
  wire g_io_chi_rx_linkactiveack;
  wire i_io_chi_rx_linkactiveack;
  wire g_io_chi_rx_rsp_lcrdv;
  wire i_io_chi_rx_rsp_lcrdv;
  wire g_io_chi_rx_dat_lcrdv;
  wire i_io_chi_rx_dat_lcrdv;
  wire g_io_chi_rx_snp_lcrdv;
  wire i_io_chi_rx_snp_lcrdv;

  XSTile    u_g (.clock(clk), .reset(rst), .auto_l2top_inner_beu_int_out_0(g_auto_l2top_inner_beu_int_out_0), .auto_l2top_inner_nmi_int_in_0(auto_l2top_inner_nmi_int_in_0), .auto_l2top_inner_nmi_int_in_1(auto_l2top_inner_nmi_int_in_1), .auto_l2top_inner_plic_int_in_1_0(auto_l2top_inner_plic_int_in_1_0), .auto_l2top_inner_plic_int_in_0_0(auto_l2top_inner_plic_int_in_0_0), .auto_l2top_inner_debug_int_in_0(auto_l2top_inner_debug_int_in_0), .auto_l2top_inner_clint_int_in_0(auto_l2top_inner_clint_int_in_0), .auto_l2top_inner_clint_int_in_1(auto_l2top_inner_clint_int_in_1), .io_hartId(io_hartId), .io_msiInfo_valid(io_msiInfo_valid), .io_msiInfo_bits(io_msiInfo_bits), .io_reset_vector(io_reset_vector), .io_cpu_halt(g_io_cpu_halt), .io_cpu_crtical_error(g_io_cpu_crtical_error), .io_hartIsInReset(g_io_hartIsInReset), .io_traceCoreInterface_fromEncoder_enable(io_traceCoreInterface_fromEncoder_enable), .io_traceCoreInterface_fromEncoder_stall(io_traceCoreInterface_fromEncoder_stall), .io_traceCoreInterface_toEncoder_priv(g_io_traceCoreInterface_toEncoder_priv), .io_traceCoreInterface_toEncoder_trap_cause(g_io_traceCoreInterface_toEncoder_trap_cause), .io_traceCoreInterface_toEncoder_trap_tval(g_io_traceCoreInterface_toEncoder_trap_tval), .io_traceCoreInterface_toEncoder_groups_0_bits_iaddr(g_io_traceCoreInterface_toEncoder_groups_0_bits_iaddr), .io_traceCoreInterface_toEncoder_groups_0_bits_itype(g_io_traceCoreInterface_toEncoder_groups_0_bits_itype), .io_traceCoreInterface_toEncoder_groups_0_bits_iretire(g_io_traceCoreInterface_toEncoder_groups_0_bits_iretire), .io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize(g_io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize), .io_traceCoreInterface_toEncoder_groups_1_bits_iaddr(g_io_traceCoreInterface_toEncoder_groups_1_bits_iaddr), .io_traceCoreInterface_toEncoder_groups_1_bits_itype(g_io_traceCoreInterface_toEncoder_groups_1_bits_itype), .io_traceCoreInterface_toEncoder_groups_1_bits_iretire(g_io_traceCoreInterface_toEncoder_groups_1_bits_iretire), .io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize(g_io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize), .io_traceCoreInterface_toEncoder_groups_2_bits_iaddr(g_io_traceCoreInterface_toEncoder_groups_2_bits_iaddr), .io_traceCoreInterface_toEncoder_groups_2_bits_itype(g_io_traceCoreInterface_toEncoder_groups_2_bits_itype), .io_traceCoreInterface_toEncoder_groups_2_bits_iretire(g_io_traceCoreInterface_toEncoder_groups_2_bits_iretire), .io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize(g_io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize), .io_debugTopDown_robHeadPaddr_valid(g_io_debugTopDown_robHeadPaddr_valid), .io_debugTopDown_robHeadPaddr_bits(g_io_debugTopDown_robHeadPaddr_bits), .io_debugTopDown_l3MissMatch(io_debugTopDown_l3MissMatch), .io_l3Miss(io_l3Miss), .io_chi_txsactive(g_io_chi_txsactive), .io_chi_rxsactive(io_chi_rxsactive), .io_chi_syscoreq(g_io_chi_syscoreq), .io_chi_syscoack(io_chi_syscoack), .io_chi_tx_linkactivereq(g_io_chi_tx_linkactivereq), .io_chi_tx_linkactiveack(io_chi_tx_linkactiveack), .io_chi_tx_req_flitpend(g_io_chi_tx_req_flitpend), .io_chi_tx_req_flitv(g_io_chi_tx_req_flitv), .io_chi_tx_req_flit(g_io_chi_tx_req_flit), .io_chi_tx_req_lcrdv(io_chi_tx_req_lcrdv), .io_chi_tx_rsp_flitpend(g_io_chi_tx_rsp_flitpend), .io_chi_tx_rsp_flitv(g_io_chi_tx_rsp_flitv), .io_chi_tx_rsp_flit(g_io_chi_tx_rsp_flit), .io_chi_tx_rsp_lcrdv(io_chi_tx_rsp_lcrdv), .io_chi_tx_dat_flitpend(g_io_chi_tx_dat_flitpend), .io_chi_tx_dat_flitv(g_io_chi_tx_dat_flitv), .io_chi_tx_dat_flit(g_io_chi_tx_dat_flit), .io_chi_tx_dat_lcrdv(io_chi_tx_dat_lcrdv), .io_chi_rx_linkactivereq(io_chi_rx_linkactivereq), .io_chi_rx_linkactiveack(g_io_chi_rx_linkactiveack), .io_chi_rx_rsp_flitpend(io_chi_rx_rsp_flitpend), .io_chi_rx_rsp_flitv(io_chi_rx_rsp_flitv), .io_chi_rx_rsp_flit(io_chi_rx_rsp_flit), .io_chi_rx_rsp_lcrdv(g_io_chi_rx_rsp_lcrdv), .io_chi_rx_dat_flitpend(io_chi_rx_dat_flitpend), .io_chi_rx_dat_flitv(io_chi_rx_dat_flitv), .io_chi_rx_dat_flit(io_chi_rx_dat_flit), .io_chi_rx_dat_lcrdv(g_io_chi_rx_dat_lcrdv), .io_chi_rx_snp_flitpend(io_chi_rx_snp_flitpend), .io_chi_rx_snp_flitv(io_chi_rx_snp_flitv), .io_chi_rx_snp_flit(io_chi_rx_snp_flit), .io_chi_rx_snp_lcrdv(g_io_chi_rx_snp_lcrdv), .io_nodeID(io_nodeID), .io_clintTime_valid(io_clintTime_valid), .io_clintTime_bits(io_clintTime_bits), .io_dft_ram_hold(io_dft_ram_hold), .io_dft_ram_bypass(io_dft_ram_bypass), .io_dft_ram_bp_clken(io_dft_ram_bp_clken), .io_dft_ram_aux_clk(io_dft_ram_aux_clk), .io_dft_ram_aux_ckbp(io_dft_ram_aux_ckbp), .io_dft_ram_mcp_hold(io_dft_ram_mcp_hold), .io_dft_ram_ctl(io_dft_ram_ctl), .io_dft_cgen(io_dft_cgen), .io_dft_reset_lgc_rst_n(io_dft_reset_lgc_rst_n), .io_dft_reset_mode(io_dft_reset_mode), .io_dft_reset_scan_mode(io_dft_reset_scan_mode));
  XSTile_xs u_i (.clock(clk), .reset(rst), .auto_l2top_inner_beu_int_out_0(i_auto_l2top_inner_beu_int_out_0), .auto_l2top_inner_nmi_int_in_0(auto_l2top_inner_nmi_int_in_0), .auto_l2top_inner_nmi_int_in_1(auto_l2top_inner_nmi_int_in_1), .auto_l2top_inner_plic_int_in_1_0(auto_l2top_inner_plic_int_in_1_0), .auto_l2top_inner_plic_int_in_0_0(auto_l2top_inner_plic_int_in_0_0), .auto_l2top_inner_debug_int_in_0(auto_l2top_inner_debug_int_in_0), .auto_l2top_inner_clint_int_in_0(auto_l2top_inner_clint_int_in_0), .auto_l2top_inner_clint_int_in_1(auto_l2top_inner_clint_int_in_1), .io_hartId(io_hartId), .io_msiInfo_valid(io_msiInfo_valid), .io_msiInfo_bits(io_msiInfo_bits), .io_reset_vector(io_reset_vector), .io_cpu_halt(i_io_cpu_halt), .io_cpu_crtical_error(i_io_cpu_crtical_error), .io_hartIsInReset(i_io_hartIsInReset), .io_traceCoreInterface_fromEncoder_enable(io_traceCoreInterface_fromEncoder_enable), .io_traceCoreInterface_fromEncoder_stall(io_traceCoreInterface_fromEncoder_stall), .io_traceCoreInterface_toEncoder_priv(i_io_traceCoreInterface_toEncoder_priv), .io_traceCoreInterface_toEncoder_trap_cause(i_io_traceCoreInterface_toEncoder_trap_cause), .io_traceCoreInterface_toEncoder_trap_tval(i_io_traceCoreInterface_toEncoder_trap_tval), .io_traceCoreInterface_toEncoder_groups_0_bits_iaddr(i_io_traceCoreInterface_toEncoder_groups_0_bits_iaddr), .io_traceCoreInterface_toEncoder_groups_0_bits_itype(i_io_traceCoreInterface_toEncoder_groups_0_bits_itype), .io_traceCoreInterface_toEncoder_groups_0_bits_iretire(i_io_traceCoreInterface_toEncoder_groups_0_bits_iretire), .io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize(i_io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize), .io_traceCoreInterface_toEncoder_groups_1_bits_iaddr(i_io_traceCoreInterface_toEncoder_groups_1_bits_iaddr), .io_traceCoreInterface_toEncoder_groups_1_bits_itype(i_io_traceCoreInterface_toEncoder_groups_1_bits_itype), .io_traceCoreInterface_toEncoder_groups_1_bits_iretire(i_io_traceCoreInterface_toEncoder_groups_1_bits_iretire), .io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize(i_io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize), .io_traceCoreInterface_toEncoder_groups_2_bits_iaddr(i_io_traceCoreInterface_toEncoder_groups_2_bits_iaddr), .io_traceCoreInterface_toEncoder_groups_2_bits_itype(i_io_traceCoreInterface_toEncoder_groups_2_bits_itype), .io_traceCoreInterface_toEncoder_groups_2_bits_iretire(i_io_traceCoreInterface_toEncoder_groups_2_bits_iretire), .io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize(i_io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize), .io_debugTopDown_robHeadPaddr_valid(i_io_debugTopDown_robHeadPaddr_valid), .io_debugTopDown_robHeadPaddr_bits(i_io_debugTopDown_robHeadPaddr_bits), .io_debugTopDown_l3MissMatch(io_debugTopDown_l3MissMatch), .io_l3Miss(io_l3Miss), .io_chi_txsactive(i_io_chi_txsactive), .io_chi_rxsactive(io_chi_rxsactive), .io_chi_syscoreq(i_io_chi_syscoreq), .io_chi_syscoack(io_chi_syscoack), .io_chi_tx_linkactivereq(i_io_chi_tx_linkactivereq), .io_chi_tx_linkactiveack(io_chi_tx_linkactiveack), .io_chi_tx_req_flitpend(i_io_chi_tx_req_flitpend), .io_chi_tx_req_flitv(i_io_chi_tx_req_flitv), .io_chi_tx_req_flit(i_io_chi_tx_req_flit), .io_chi_tx_req_lcrdv(io_chi_tx_req_lcrdv), .io_chi_tx_rsp_flitpend(i_io_chi_tx_rsp_flitpend), .io_chi_tx_rsp_flitv(i_io_chi_tx_rsp_flitv), .io_chi_tx_rsp_flit(i_io_chi_tx_rsp_flit), .io_chi_tx_rsp_lcrdv(io_chi_tx_rsp_lcrdv), .io_chi_tx_dat_flitpend(i_io_chi_tx_dat_flitpend), .io_chi_tx_dat_flitv(i_io_chi_tx_dat_flitv), .io_chi_tx_dat_flit(i_io_chi_tx_dat_flit), .io_chi_tx_dat_lcrdv(io_chi_tx_dat_lcrdv), .io_chi_rx_linkactivereq(io_chi_rx_linkactivereq), .io_chi_rx_linkactiveack(i_io_chi_rx_linkactiveack), .io_chi_rx_rsp_flitpend(io_chi_rx_rsp_flitpend), .io_chi_rx_rsp_flitv(io_chi_rx_rsp_flitv), .io_chi_rx_rsp_flit(io_chi_rx_rsp_flit), .io_chi_rx_rsp_lcrdv(i_io_chi_rx_rsp_lcrdv), .io_chi_rx_dat_flitpend(io_chi_rx_dat_flitpend), .io_chi_rx_dat_flitv(io_chi_rx_dat_flitv), .io_chi_rx_dat_flit(io_chi_rx_dat_flit), .io_chi_rx_dat_lcrdv(i_io_chi_rx_dat_lcrdv), .io_chi_rx_snp_flitpend(io_chi_rx_snp_flitpend), .io_chi_rx_snp_flitv(io_chi_rx_snp_flitv), .io_chi_rx_snp_flit(io_chi_rx_snp_flit), .io_chi_rx_snp_lcrdv(i_io_chi_rx_snp_lcrdv), .io_nodeID(io_nodeID), .io_clintTime_valid(io_clintTime_valid), .io_clintTime_bits(io_clintTime_bits), .io_dft_ram_hold(io_dft_ram_hold), .io_dft_ram_bypass(io_dft_ram_bypass), .io_dft_ram_bp_clken(io_dft_ram_bp_clken), .io_dft_ram_aux_clk(io_dft_ram_aux_clk), .io_dft_ram_aux_ckbp(io_dft_ram_aux_ckbp), .io_dft_ram_mcp_hold(io_dft_ram_mcp_hold), .io_dft_ram_ctl(io_dft_ram_ctl), .io_dft_cgen(io_dft_cgen), .io_dft_reset_lgc_rst_n(io_dft_reset_lgc_rst_n), .io_dft_reset_mode(io_dft_reset_mode), .io_dft_reset_scan_mode(io_dft_reset_scan_mode));

  bit reported [0:36];
  int distinct_div = 0;

  always @(negedge clk) begin
    if (rst) begin
      io_msiInfo_valid <= 1'b0;
      io_clintTime_valid <= 1'b0;
    end else begin
      auto_l2top_inner_nmi_int_in_0 <= $urandom_range(0,1);
      auto_l2top_inner_nmi_int_in_1 <= $urandom_range(0,1);
      auto_l2top_inner_plic_int_in_1_0 <= $urandom_range(0,1);
      auto_l2top_inner_plic_int_in_0_0 <= $urandom_range(0,1);
      auto_l2top_inner_debug_int_in_0 <= $urandom_range(0,1);
      auto_l2top_inner_clint_int_in_0 <= $urandom_range(0,1);
      auto_l2top_inner_clint_int_in_1 <= $urandom_range(0,1);
      io_hartId <= 6'($urandom);
      io_msiInfo_valid <= $urandom_range(0,1);
      io_msiInfo_bits <= 11'($urandom);
      io_reset_vector <= {$urandom(), $urandom()};
      io_traceCoreInterface_fromEncoder_enable <= $urandom_range(0,1);
      io_traceCoreInterface_fromEncoder_stall <= $urandom_range(0,1);
      io_debugTopDown_l3MissMatch <= $urandom_range(0,1);
      io_l3Miss <= $urandom_range(0,1);
      io_chi_rxsactive <= $urandom_range(0,1);
      io_chi_syscoack <= $urandom_range(0,1);
      io_chi_tx_linkactiveack <= $urandom_range(0,1);
      io_chi_tx_req_lcrdv <= $urandom_range(0,1);
      io_chi_tx_rsp_lcrdv <= $urandom_range(0,1);
      io_chi_tx_dat_lcrdv <= $urandom_range(0,1);
      io_chi_rx_linkactivereq <= $urandom_range(0,1);
      io_chi_rx_rsp_flitpend <= $urandom_range(0,1);
      io_chi_rx_rsp_flitv <= $urandom_range(0,1);
      io_chi_rx_rsp_flit <= {$urandom(), $urandom(), $urandom()};
      io_chi_rx_dat_flitpend <= $urandom_range(0,1);
      io_chi_rx_dat_flitv <= $urandom_range(0,1);
      io_chi_rx_dat_flit <= {$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()};
      io_chi_rx_snp_flitpend <= $urandom_range(0,1);
      io_chi_rx_snp_flitv <= $urandom_range(0,1);
      io_chi_rx_snp_flit <= {$urandom(), $urandom(), $urandom(), $urandom()};
      io_nodeID <= 11'($urandom);
      io_clintTime_valid <= $urandom_range(0,1);
      io_clintTime_bits <= {$urandom(), $urandom()};
      io_dft_ram_hold <= $urandom_range(0,1);
      io_dft_ram_bypass <= $urandom_range(0,1);
      io_dft_ram_bp_clken <= $urandom_range(0,1);
      io_dft_ram_aux_clk <= $urandom_range(0,1);
      io_dft_ram_aux_ckbp <= $urandom_range(0,1);
      io_dft_ram_mcp_hold <= $urandom_range(0,1);
      io_dft_ram_ctl <= {$urandom(), $urandom()};
      io_dft_cgen <= $urandom_range(0,1);
      io_dft_reset_lgc_rst_n <= $urandom_range(0,1);
      io_dft_reset_mode <= $urandom_range(0,1);
      io_dft_reset_scan_mode <= $urandom_range(0,1);
    end
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_auto_l2top_inner_beu_int_out_0) && g_auto_l2top_inner_beu_int_out_0 !== i_auto_l2top_inner_beu_int_out_0) begin errors++;
      if(!reported[0]) begin reported[0]=1; distinct_div++;
        $display("[DIV %0t] auto_l2top_inner_beu_int_out_0 g=%h i=%h", $time, g_auto_l2top_inner_beu_int_out_0, i_auto_l2top_inner_beu_int_out_0); end end
    if (!$isunknown(g_io_cpu_halt) && g_io_cpu_halt !== i_io_cpu_halt) begin errors++;
      if(!reported[1]) begin reported[1]=1; distinct_div++;
        $display("[DIV %0t] io_cpu_halt g=%h i=%h", $time, g_io_cpu_halt, i_io_cpu_halt); end end
    if (!$isunknown(g_io_cpu_crtical_error) && g_io_cpu_crtical_error !== i_io_cpu_crtical_error) begin errors++;
      if(!reported[2]) begin reported[2]=1; distinct_div++;
        $display("[DIV %0t] io_cpu_crtical_error g=%h i=%h", $time, g_io_cpu_crtical_error, i_io_cpu_crtical_error); end end
    if (!$isunknown(g_io_hartIsInReset) && g_io_hartIsInReset !== i_io_hartIsInReset) begin errors++;
      if(!reported[3]) begin reported[3]=1; distinct_div++;
        $display("[DIV %0t] io_hartIsInReset g=%h i=%h", $time, g_io_hartIsInReset, i_io_hartIsInReset); end end
    if (!$isunknown(g_io_traceCoreInterface_toEncoder_priv) && g_io_traceCoreInterface_toEncoder_priv !== i_io_traceCoreInterface_toEncoder_priv) begin errors++;
      if(!reported[4]) begin reported[4]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toEncoder_priv g=%h i=%h", $time, g_io_traceCoreInterface_toEncoder_priv, i_io_traceCoreInterface_toEncoder_priv); end end
    if (!$isunknown(g_io_traceCoreInterface_toEncoder_trap_cause) && g_io_traceCoreInterface_toEncoder_trap_cause !== i_io_traceCoreInterface_toEncoder_trap_cause) begin errors++;
      if(!reported[5]) begin reported[5]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toEncoder_trap_cause g=%h i=%h", $time, g_io_traceCoreInterface_toEncoder_trap_cause, i_io_traceCoreInterface_toEncoder_trap_cause); end end
    if (!$isunknown(g_io_traceCoreInterface_toEncoder_trap_tval) && g_io_traceCoreInterface_toEncoder_trap_tval !== i_io_traceCoreInterface_toEncoder_trap_tval) begin errors++;
      if(!reported[6]) begin reported[6]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toEncoder_trap_tval g=%h i=%h", $time, g_io_traceCoreInterface_toEncoder_trap_tval, i_io_traceCoreInterface_toEncoder_trap_tval); end end
    if (!$isunknown(g_io_traceCoreInterface_toEncoder_groups_0_bits_iaddr) && g_io_traceCoreInterface_toEncoder_groups_0_bits_iaddr !== i_io_traceCoreInterface_toEncoder_groups_0_bits_iaddr) begin errors++;
      if(!reported[7]) begin reported[7]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toEncoder_groups_0_bits_iaddr g=%h i=%h", $time, g_io_traceCoreInterface_toEncoder_groups_0_bits_iaddr, i_io_traceCoreInterface_toEncoder_groups_0_bits_iaddr); end end
    if (!$isunknown(g_io_traceCoreInterface_toEncoder_groups_0_bits_itype) && g_io_traceCoreInterface_toEncoder_groups_0_bits_itype !== i_io_traceCoreInterface_toEncoder_groups_0_bits_itype) begin errors++;
      if(!reported[8]) begin reported[8]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toEncoder_groups_0_bits_itype g=%h i=%h", $time, g_io_traceCoreInterface_toEncoder_groups_0_bits_itype, i_io_traceCoreInterface_toEncoder_groups_0_bits_itype); end end
    if (!$isunknown(g_io_traceCoreInterface_toEncoder_groups_0_bits_iretire) && g_io_traceCoreInterface_toEncoder_groups_0_bits_iretire !== i_io_traceCoreInterface_toEncoder_groups_0_bits_iretire) begin errors++;
      if(!reported[9]) begin reported[9]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toEncoder_groups_0_bits_iretire g=%h i=%h", $time, g_io_traceCoreInterface_toEncoder_groups_0_bits_iretire, i_io_traceCoreInterface_toEncoder_groups_0_bits_iretire); end end
    if (!$isunknown(g_io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize) && g_io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize !== i_io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize) begin errors++;
      if(!reported[10]) begin reported[10]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize g=%h i=%h", $time, g_io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize, i_io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize); end end
    if (!$isunknown(g_io_traceCoreInterface_toEncoder_groups_1_bits_iaddr) && g_io_traceCoreInterface_toEncoder_groups_1_bits_iaddr !== i_io_traceCoreInterface_toEncoder_groups_1_bits_iaddr) begin errors++;
      if(!reported[11]) begin reported[11]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toEncoder_groups_1_bits_iaddr g=%h i=%h", $time, g_io_traceCoreInterface_toEncoder_groups_1_bits_iaddr, i_io_traceCoreInterface_toEncoder_groups_1_bits_iaddr); end end
    if (!$isunknown(g_io_traceCoreInterface_toEncoder_groups_1_bits_itype) && g_io_traceCoreInterface_toEncoder_groups_1_bits_itype !== i_io_traceCoreInterface_toEncoder_groups_1_bits_itype) begin errors++;
      if(!reported[12]) begin reported[12]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toEncoder_groups_1_bits_itype g=%h i=%h", $time, g_io_traceCoreInterface_toEncoder_groups_1_bits_itype, i_io_traceCoreInterface_toEncoder_groups_1_bits_itype); end end
    if (!$isunknown(g_io_traceCoreInterface_toEncoder_groups_1_bits_iretire) && g_io_traceCoreInterface_toEncoder_groups_1_bits_iretire !== i_io_traceCoreInterface_toEncoder_groups_1_bits_iretire) begin errors++;
      if(!reported[13]) begin reported[13]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toEncoder_groups_1_bits_iretire g=%h i=%h", $time, g_io_traceCoreInterface_toEncoder_groups_1_bits_iretire, i_io_traceCoreInterface_toEncoder_groups_1_bits_iretire); end end
    if (!$isunknown(g_io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize) && g_io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize !== i_io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize) begin errors++;
      if(!reported[14]) begin reported[14]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize g=%h i=%h", $time, g_io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize, i_io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize); end end
    if (!$isunknown(g_io_traceCoreInterface_toEncoder_groups_2_bits_iaddr) && g_io_traceCoreInterface_toEncoder_groups_2_bits_iaddr !== i_io_traceCoreInterface_toEncoder_groups_2_bits_iaddr) begin errors++;
      if(!reported[15]) begin reported[15]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toEncoder_groups_2_bits_iaddr g=%h i=%h", $time, g_io_traceCoreInterface_toEncoder_groups_2_bits_iaddr, i_io_traceCoreInterface_toEncoder_groups_2_bits_iaddr); end end
    if (!$isunknown(g_io_traceCoreInterface_toEncoder_groups_2_bits_itype) && g_io_traceCoreInterface_toEncoder_groups_2_bits_itype !== i_io_traceCoreInterface_toEncoder_groups_2_bits_itype) begin errors++;
      if(!reported[16]) begin reported[16]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toEncoder_groups_2_bits_itype g=%h i=%h", $time, g_io_traceCoreInterface_toEncoder_groups_2_bits_itype, i_io_traceCoreInterface_toEncoder_groups_2_bits_itype); end end
    if (!$isunknown(g_io_traceCoreInterface_toEncoder_groups_2_bits_iretire) && g_io_traceCoreInterface_toEncoder_groups_2_bits_iretire !== i_io_traceCoreInterface_toEncoder_groups_2_bits_iretire) begin errors++;
      if(!reported[17]) begin reported[17]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toEncoder_groups_2_bits_iretire g=%h i=%h", $time, g_io_traceCoreInterface_toEncoder_groups_2_bits_iretire, i_io_traceCoreInterface_toEncoder_groups_2_bits_iretire); end end
    if (!$isunknown(g_io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize) && g_io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize !== i_io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize) begin errors++;
      if(!reported[18]) begin reported[18]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize g=%h i=%h", $time, g_io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize, i_io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize); end end
    if (!$isunknown(g_io_debugTopDown_robHeadPaddr_valid) && g_io_debugTopDown_robHeadPaddr_valid !== i_io_debugTopDown_robHeadPaddr_valid) begin errors++;
      if(!reported[19]) begin reported[19]=1; distinct_div++;
        $display("[DIV %0t] io_debugTopDown_robHeadPaddr_valid g=%h i=%h", $time, g_io_debugTopDown_robHeadPaddr_valid, i_io_debugTopDown_robHeadPaddr_valid); end end
    if (!$isunknown(g_io_debugTopDown_robHeadPaddr_bits) && g_io_debugTopDown_robHeadPaddr_bits !== i_io_debugTopDown_robHeadPaddr_bits) begin errors++;
      if(!reported[20]) begin reported[20]=1; distinct_div++;
        $display("[DIV %0t] io_debugTopDown_robHeadPaddr_bits g=%h i=%h", $time, g_io_debugTopDown_robHeadPaddr_bits, i_io_debugTopDown_robHeadPaddr_bits); end end
    if (!$isunknown(g_io_chi_txsactive) && g_io_chi_txsactive !== i_io_chi_txsactive) begin errors++;
      if(!reported[21]) begin reported[21]=1; distinct_div++;
        $display("[DIV %0t] io_chi_txsactive g=%h i=%h", $time, g_io_chi_txsactive, i_io_chi_txsactive); end end
    if (!$isunknown(g_io_chi_syscoreq) && g_io_chi_syscoreq !== i_io_chi_syscoreq) begin errors++;
      if(!reported[22]) begin reported[22]=1; distinct_div++;
        $display("[DIV %0t] io_chi_syscoreq g=%h i=%h", $time, g_io_chi_syscoreq, i_io_chi_syscoreq); end end
    if (!$isunknown(g_io_chi_tx_linkactivereq) && g_io_chi_tx_linkactivereq !== i_io_chi_tx_linkactivereq) begin errors++;
      if(!reported[23]) begin reported[23]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_linkactivereq g=%h i=%h", $time, g_io_chi_tx_linkactivereq, i_io_chi_tx_linkactivereq); end end
    if (!$isunknown(g_io_chi_tx_req_flitpend) && g_io_chi_tx_req_flitpend !== i_io_chi_tx_req_flitpend) begin errors++;
      if(!reported[24]) begin reported[24]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_req_flitpend g=%h i=%h", $time, g_io_chi_tx_req_flitpend, i_io_chi_tx_req_flitpend); end end
    if (!$isunknown(g_io_chi_tx_req_flitv) && g_io_chi_tx_req_flitv !== i_io_chi_tx_req_flitv) begin errors++;
      if(!reported[25]) begin reported[25]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_req_flitv g=%h i=%h", $time, g_io_chi_tx_req_flitv, i_io_chi_tx_req_flitv); end end
    if (!$isunknown(g_io_chi_tx_req_flit) && g_io_chi_tx_req_flit !== i_io_chi_tx_req_flit) begin errors++;
      if(!reported[26]) begin reported[26]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_req_flit g=%h i=%h", $time, g_io_chi_tx_req_flit, i_io_chi_tx_req_flit); end end
    if (!$isunknown(g_io_chi_tx_rsp_flitpend) && g_io_chi_tx_rsp_flitpend !== i_io_chi_tx_rsp_flitpend) begin errors++;
      if(!reported[27]) begin reported[27]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_rsp_flitpend g=%h i=%h", $time, g_io_chi_tx_rsp_flitpend, i_io_chi_tx_rsp_flitpend); end end
    if (!$isunknown(g_io_chi_tx_rsp_flitv) && g_io_chi_tx_rsp_flitv !== i_io_chi_tx_rsp_flitv) begin errors++;
      if(!reported[28]) begin reported[28]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_rsp_flitv g=%h i=%h", $time, g_io_chi_tx_rsp_flitv, i_io_chi_tx_rsp_flitv); end end
    if (!$isunknown(g_io_chi_tx_rsp_flit) && g_io_chi_tx_rsp_flit !== i_io_chi_tx_rsp_flit) begin errors++;
      if(!reported[29]) begin reported[29]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_rsp_flit g=%h i=%h", $time, g_io_chi_tx_rsp_flit, i_io_chi_tx_rsp_flit); end end
    if (!$isunknown(g_io_chi_tx_dat_flitpend) && g_io_chi_tx_dat_flitpend !== i_io_chi_tx_dat_flitpend) begin errors++;
      if(!reported[30]) begin reported[30]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_dat_flitpend g=%h i=%h", $time, g_io_chi_tx_dat_flitpend, i_io_chi_tx_dat_flitpend); end end
    if (!$isunknown(g_io_chi_tx_dat_flitv) && g_io_chi_tx_dat_flitv !== i_io_chi_tx_dat_flitv) begin errors++;
      if(!reported[31]) begin reported[31]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_dat_flitv g=%h i=%h", $time, g_io_chi_tx_dat_flitv, i_io_chi_tx_dat_flitv); end end
    if (!$isunknown(g_io_chi_tx_dat_flit) && g_io_chi_tx_dat_flit !== i_io_chi_tx_dat_flit) begin errors++;
      if(!reported[32]) begin reported[32]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_dat_flit g=%h i=%h", $time, g_io_chi_tx_dat_flit, i_io_chi_tx_dat_flit); end end
    if (!$isunknown(g_io_chi_rx_linkactiveack) && g_io_chi_rx_linkactiveack !== i_io_chi_rx_linkactiveack) begin errors++;
      if(!reported[33]) begin reported[33]=1; distinct_div++;
        $display("[DIV %0t] io_chi_rx_linkactiveack g=%h i=%h", $time, g_io_chi_rx_linkactiveack, i_io_chi_rx_linkactiveack); end end
    if (!$isunknown(g_io_chi_rx_rsp_lcrdv) && g_io_chi_rx_rsp_lcrdv !== i_io_chi_rx_rsp_lcrdv) begin errors++;
      if(!reported[34]) begin reported[34]=1; distinct_div++;
        $display("[DIV %0t] io_chi_rx_rsp_lcrdv g=%h i=%h", $time, g_io_chi_rx_rsp_lcrdv, i_io_chi_rx_rsp_lcrdv); end end
    if (!$isunknown(g_io_chi_rx_dat_lcrdv) && g_io_chi_rx_dat_lcrdv !== i_io_chi_rx_dat_lcrdv) begin errors++;
      if(!reported[35]) begin reported[35]=1; distinct_div++;
        $display("[DIV %0t] io_chi_rx_dat_lcrdv g=%h i=%h", $time, g_io_chi_rx_dat_lcrdv, i_io_chi_rx_dat_lcrdv); end end
    if (!$isunknown(g_io_chi_rx_snp_lcrdv) && g_io_chi_rx_snp_lcrdv !== i_io_chi_rx_snp_lcrdv) begin errors++;
      if(!reported[36]) begin reported[36]=1; distinct_div++;
        $display("[DIV %0t] io_chi_rx_snp_lcrdv g=%h i=%h", $time, g_io_chi_rx_snp_lcrdv, i_io_chi_rx_snp_lcrdv); end end
  end

  initial begin
    if (!$value$plusargs("NCYCLES=%d", NCYCLES)) NCYCLES = 200000;
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("distinct_diverging_ports=%0d / %0d", distinct_div, 37);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
