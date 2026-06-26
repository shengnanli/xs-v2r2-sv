// 自动生成:scripts/gen_xstop.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)

`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic nmi_0_0;
  logic nmi_0_1;
  logic peripheral_awready;
  logic peripheral_wready;
  logic peripheral_bvalid;
  logic [1:0] peripheral_bid;
  logic [1:0] peripheral_bresp;
  logic peripheral_arready;
  logic peripheral_rvalid;
  logic [1:0] peripheral_rid;
  logic [63:0] peripheral_rdata;
  logic [1:0] peripheral_rresp;
  logic peripheral_rlast;
  logic memory_awready;
  logic memory_wready;
  logic memory_bvalid;
  logic [13:0] memory_bid;
  logic [1:0] memory_bresp;
  logic memory_arready;
  logic memory_rvalid;
  logic [13:0] memory_rid;
  logic [255:0] memory_rdata;
  logic [1:0] memory_rresp;
  logic memory_rlast;
  logic io_clock;
  logic io_reset;
  logic [15:0] io_sram_config;
  logic [63:0] io_extIntrs;
  logic io_pll0_lock;
  logic io_systemjtag_jtag_TCK;
  logic io_systemjtag_jtag_TMS;
  logic io_systemjtag_jtag_TDI;
  logic io_systemjtag_reset;
  logic [10:0] io_systemjtag_mfr_id;
  logic [15:0] io_systemjtag_part_number;
  logic [3:0] io_systemjtag_version;
  logic io_rtc_clock;
  logic io_cacheable_check_req_0_valid;
  logic [47:0] io_cacheable_check_req_0_bits_addr;
  logic [1:0] io_cacheable_check_req_0_bits_size;
  logic [2:0] io_cacheable_check_req_0_bits_cmd;
  logic io_cacheable_check_req_1_valid;
  logic [47:0] io_cacheable_check_req_1_bits_addr;
  logic [1:0] io_cacheable_check_req_1_bits_size;
  logic [2:0] io_cacheable_check_req_1_bits_cmd;
  logic [47:0] io_riscv_rst_vec_0;
  logic io_traceCoreInterface_0_fromEncoder_enable;
  logic io_traceCoreInterface_0_fromEncoder_stall;
  wire g_peripheral_awvalid;
  wire i_peripheral_awvalid;
  wire [1:0] g_peripheral_awid;
  wire [1:0] i_peripheral_awid;
  wire [30:0] g_peripheral_awaddr;
  wire [30:0] i_peripheral_awaddr;
  wire [7:0] g_peripheral_awlen;
  wire [7:0] i_peripheral_awlen;
  wire [2:0] g_peripheral_awsize;
  wire [2:0] i_peripheral_awsize;
  wire [1:0] g_peripheral_awburst;
  wire [1:0] i_peripheral_awburst;
  wire g_peripheral_awlock;
  wire i_peripheral_awlock;
  wire [3:0] g_peripheral_awcache;
  wire [3:0] i_peripheral_awcache;
  wire [2:0] g_peripheral_awprot;
  wire [2:0] i_peripheral_awprot;
  wire [3:0] g_peripheral_awqos;
  wire [3:0] i_peripheral_awqos;
  wire g_peripheral_wvalid;
  wire i_peripheral_wvalid;
  wire [63:0] g_peripheral_wdata;
  wire [63:0] i_peripheral_wdata;
  wire [7:0] g_peripheral_wstrb;
  wire [7:0] i_peripheral_wstrb;
  wire g_peripheral_wlast;
  wire i_peripheral_wlast;
  wire g_peripheral_bready;
  wire i_peripheral_bready;
  wire g_peripheral_arvalid;
  wire i_peripheral_arvalid;
  wire [1:0] g_peripheral_arid;
  wire [1:0] i_peripheral_arid;
  wire [30:0] g_peripheral_araddr;
  wire [30:0] i_peripheral_araddr;
  wire [7:0] g_peripheral_arlen;
  wire [7:0] i_peripheral_arlen;
  wire [2:0] g_peripheral_arsize;
  wire [2:0] i_peripheral_arsize;
  wire [1:0] g_peripheral_arburst;
  wire [1:0] i_peripheral_arburst;
  wire g_peripheral_arlock;
  wire i_peripheral_arlock;
  wire [3:0] g_peripheral_arcache;
  wire [3:0] i_peripheral_arcache;
  wire [2:0] g_peripheral_arprot;
  wire [2:0] i_peripheral_arprot;
  wire [3:0] g_peripheral_arqos;
  wire [3:0] i_peripheral_arqos;
  wire g_peripheral_rready;
  wire i_peripheral_rready;
  wire g_memory_awvalid;
  wire i_memory_awvalid;
  wire [13:0] g_memory_awid;
  wire [13:0] i_memory_awid;
  wire [47:0] g_memory_awaddr;
  wire [47:0] i_memory_awaddr;
  wire [7:0] g_memory_awlen;
  wire [7:0] i_memory_awlen;
  wire [2:0] g_memory_awsize;
  wire [2:0] i_memory_awsize;
  wire [1:0] g_memory_awburst;
  wire [1:0] i_memory_awburst;
  wire g_memory_awlock;
  wire i_memory_awlock;
  wire [3:0] g_memory_awcache;
  wire [3:0] i_memory_awcache;
  wire [2:0] g_memory_awprot;
  wire [2:0] i_memory_awprot;
  wire [3:0] g_memory_awqos;
  wire [3:0] i_memory_awqos;
  wire g_memory_wvalid;
  wire i_memory_wvalid;
  wire [255:0] g_memory_wdata;
  wire [255:0] i_memory_wdata;
  wire [31:0] g_memory_wstrb;
  wire [31:0] i_memory_wstrb;
  wire g_memory_wlast;
  wire i_memory_wlast;
  wire g_memory_bready;
  wire i_memory_bready;
  wire g_memory_arvalid;
  wire i_memory_arvalid;
  wire [13:0] g_memory_arid;
  wire [13:0] i_memory_arid;
  wire [47:0] g_memory_araddr;
  wire [47:0] i_memory_araddr;
  wire [7:0] g_memory_arlen;
  wire [7:0] i_memory_arlen;
  wire [2:0] g_memory_arsize;
  wire [2:0] i_memory_arsize;
  wire [1:0] g_memory_arburst;
  wire [1:0] i_memory_arburst;
  wire g_memory_arlock;
  wire i_memory_arlock;
  wire [3:0] g_memory_arcache;
  wire [3:0] i_memory_arcache;
  wire [2:0] g_memory_arprot;
  wire [2:0] i_memory_arprot;
  wire [3:0] g_memory_arqos;
  wire [3:0] i_memory_arqos;
  wire g_memory_rready;
  wire i_memory_rready;
  wire [31:0] g_io_pll0_ctrl_0;
  wire [31:0] i_io_pll0_ctrl_0;
  wire [31:0] g_io_pll0_ctrl_1;
  wire [31:0] i_io_pll0_ctrl_1;
  wire [31:0] g_io_pll0_ctrl_2;
  wire [31:0] i_io_pll0_ctrl_2;
  wire [31:0] g_io_pll0_ctrl_3;
  wire [31:0] i_io_pll0_ctrl_3;
  wire [31:0] g_io_pll0_ctrl_4;
  wire [31:0] i_io_pll0_ctrl_4;
  wire [31:0] g_io_pll0_ctrl_5;
  wire [31:0] i_io_pll0_ctrl_5;
  wire g_io_systemjtag_jtag_TDO_data;
  wire i_io_systemjtag_jtag_TDO_data;
  wire g_io_systemjtag_jtag_TDO_driven;
  wire i_io_systemjtag_jtag_TDO_driven;
  wire g_io_debug_reset;
  wire i_io_debug_reset;
  wire g_io_cacheable_check_resp_0_ld;
  wire i_io_cacheable_check_resp_0_ld;
  wire g_io_cacheable_check_resp_0_st;
  wire i_io_cacheable_check_resp_0_st;
  wire g_io_cacheable_check_resp_0_instr;
  wire i_io_cacheable_check_resp_0_instr;
  wire g_io_cacheable_check_resp_0_mmio;
  wire i_io_cacheable_check_resp_0_mmio;
  wire g_io_cacheable_check_resp_0_atomic;
  wire i_io_cacheable_check_resp_0_atomic;
  wire g_io_cacheable_check_resp_1_ld;
  wire i_io_cacheable_check_resp_1_ld;
  wire g_io_cacheable_check_resp_1_st;
  wire i_io_cacheable_check_resp_1_st;
  wire g_io_cacheable_check_resp_1_instr;
  wire i_io_cacheable_check_resp_1_instr;
  wire g_io_cacheable_check_resp_1_mmio;
  wire i_io_cacheable_check_resp_1_mmio;
  wire g_io_cacheable_check_resp_1_atomic;
  wire i_io_cacheable_check_resp_1_atomic;
  wire g_io_riscv_halt_0;
  wire i_io_riscv_halt_0;
  wire g_io_riscv_critical_error_0;
  wire i_io_riscv_critical_error_0;
  wire [63:0] g_io_traceCoreInterface_0_toEncoder_cause;
  wire [63:0] i_io_traceCoreInterface_0_toEncoder_cause;
  wire [49:0] g_io_traceCoreInterface_0_toEncoder_tval;
  wire [49:0] i_io_traceCoreInterface_0_toEncoder_tval;
  wire [2:0] g_io_traceCoreInterface_0_toEncoder_priv;
  wire [2:0] i_io_traceCoreInterface_0_toEncoder_priv;
  wire [149:0] g_io_traceCoreInterface_0_toEncoder_iaddr;
  wire [149:0] i_io_traceCoreInterface_0_toEncoder_iaddr;
  wire [11:0] g_io_traceCoreInterface_0_toEncoder_itype;
  wire [11:0] i_io_traceCoreInterface_0_toEncoder_itype;
  wire [20:0] g_io_traceCoreInterface_0_toEncoder_iretire;
  wire [20:0] i_io_traceCoreInterface_0_toEncoder_iretire;
  wire [2:0] g_io_traceCoreInterface_0_toEncoder_ilastsize;
  wire [2:0] i_io_traceCoreInterface_0_toEncoder_ilastsize;

  XSTop    u_g (.nmi_0_0(nmi_0_0), .nmi_0_1(nmi_0_1), .peripheral_awready(peripheral_awready), .peripheral_awvalid(g_peripheral_awvalid), .peripheral_awid(g_peripheral_awid), .peripheral_awaddr(g_peripheral_awaddr), .peripheral_awlen(g_peripheral_awlen), .peripheral_awsize(g_peripheral_awsize), .peripheral_awburst(g_peripheral_awburst), .peripheral_awlock(g_peripheral_awlock), .peripheral_awcache(g_peripheral_awcache), .peripheral_awprot(g_peripheral_awprot), .peripheral_awqos(g_peripheral_awqos), .peripheral_wready(peripheral_wready), .peripheral_wvalid(g_peripheral_wvalid), .peripheral_wdata(g_peripheral_wdata), .peripheral_wstrb(g_peripheral_wstrb), .peripheral_wlast(g_peripheral_wlast), .peripheral_bready(g_peripheral_bready), .peripheral_bvalid(peripheral_bvalid), .peripheral_bid(peripheral_bid), .peripheral_bresp(peripheral_bresp), .peripheral_arready(peripheral_arready), .peripheral_arvalid(g_peripheral_arvalid), .peripheral_arid(g_peripheral_arid), .peripheral_araddr(g_peripheral_araddr), .peripheral_arlen(g_peripheral_arlen), .peripheral_arsize(g_peripheral_arsize), .peripheral_arburst(g_peripheral_arburst), .peripheral_arlock(g_peripheral_arlock), .peripheral_arcache(g_peripheral_arcache), .peripheral_arprot(g_peripheral_arprot), .peripheral_arqos(g_peripheral_arqos), .peripheral_rready(g_peripheral_rready), .peripheral_rvalid(peripheral_rvalid), .peripheral_rid(peripheral_rid), .peripheral_rdata(peripheral_rdata), .peripheral_rresp(peripheral_rresp), .peripheral_rlast(peripheral_rlast), .memory_awready(memory_awready), .memory_awvalid(g_memory_awvalid), .memory_awid(g_memory_awid), .memory_awaddr(g_memory_awaddr), .memory_awlen(g_memory_awlen), .memory_awsize(g_memory_awsize), .memory_awburst(g_memory_awburst), .memory_awlock(g_memory_awlock), .memory_awcache(g_memory_awcache), .memory_awprot(g_memory_awprot), .memory_awqos(g_memory_awqos), .memory_wready(memory_wready), .memory_wvalid(g_memory_wvalid), .memory_wdata(g_memory_wdata), .memory_wstrb(g_memory_wstrb), .memory_wlast(g_memory_wlast), .memory_bready(g_memory_bready), .memory_bvalid(memory_bvalid), .memory_bid(memory_bid), .memory_bresp(memory_bresp), .memory_arready(memory_arready), .memory_arvalid(g_memory_arvalid), .memory_arid(g_memory_arid), .memory_araddr(g_memory_araddr), .memory_arlen(g_memory_arlen), .memory_arsize(g_memory_arsize), .memory_arburst(g_memory_arburst), .memory_arlock(g_memory_arlock), .memory_arcache(g_memory_arcache), .memory_arprot(g_memory_arprot), .memory_arqos(g_memory_arqos), .memory_rready(g_memory_rready), .memory_rvalid(memory_rvalid), .memory_rid(memory_rid), .memory_rdata(memory_rdata), .memory_rresp(memory_rresp), .memory_rlast(memory_rlast), .io_clock(io_clock), .io_reset(io_reset), .io_sram_config(io_sram_config), .io_extIntrs(io_extIntrs), .io_pll0_lock(io_pll0_lock), .io_pll0_ctrl_0(g_io_pll0_ctrl_0), .io_pll0_ctrl_1(g_io_pll0_ctrl_1), .io_pll0_ctrl_2(g_io_pll0_ctrl_2), .io_pll0_ctrl_3(g_io_pll0_ctrl_3), .io_pll0_ctrl_4(g_io_pll0_ctrl_4), .io_pll0_ctrl_5(g_io_pll0_ctrl_5), .io_systemjtag_jtag_TCK(io_systemjtag_jtag_TCK), .io_systemjtag_jtag_TMS(io_systemjtag_jtag_TMS), .io_systemjtag_jtag_TDI(io_systemjtag_jtag_TDI), .io_systemjtag_jtag_TDO_data(g_io_systemjtag_jtag_TDO_data), .io_systemjtag_jtag_TDO_driven(g_io_systemjtag_jtag_TDO_driven), .io_systemjtag_reset(io_systemjtag_reset), .io_systemjtag_mfr_id(io_systemjtag_mfr_id), .io_systemjtag_part_number(io_systemjtag_part_number), .io_systemjtag_version(io_systemjtag_version), .io_debug_reset(g_io_debug_reset), .io_rtc_clock(io_rtc_clock), .io_cacheable_check_req_0_valid(io_cacheable_check_req_0_valid), .io_cacheable_check_req_0_bits_addr(io_cacheable_check_req_0_bits_addr), .io_cacheable_check_req_0_bits_size(io_cacheable_check_req_0_bits_size), .io_cacheable_check_req_0_bits_cmd(io_cacheable_check_req_0_bits_cmd), .io_cacheable_check_req_1_valid(io_cacheable_check_req_1_valid), .io_cacheable_check_req_1_bits_addr(io_cacheable_check_req_1_bits_addr), .io_cacheable_check_req_1_bits_size(io_cacheable_check_req_1_bits_size), .io_cacheable_check_req_1_bits_cmd(io_cacheable_check_req_1_bits_cmd), .io_cacheable_check_resp_0_ld(g_io_cacheable_check_resp_0_ld), .io_cacheable_check_resp_0_st(g_io_cacheable_check_resp_0_st), .io_cacheable_check_resp_0_instr(g_io_cacheable_check_resp_0_instr), .io_cacheable_check_resp_0_mmio(g_io_cacheable_check_resp_0_mmio), .io_cacheable_check_resp_0_atomic(g_io_cacheable_check_resp_0_atomic), .io_cacheable_check_resp_1_ld(g_io_cacheable_check_resp_1_ld), .io_cacheable_check_resp_1_st(g_io_cacheable_check_resp_1_st), .io_cacheable_check_resp_1_instr(g_io_cacheable_check_resp_1_instr), .io_cacheable_check_resp_1_mmio(g_io_cacheable_check_resp_1_mmio), .io_cacheable_check_resp_1_atomic(g_io_cacheable_check_resp_1_atomic), .io_riscv_halt_0(g_io_riscv_halt_0), .io_riscv_critical_error_0(g_io_riscv_critical_error_0), .io_riscv_rst_vec_0(io_riscv_rst_vec_0), .io_traceCoreInterface_0_fromEncoder_enable(io_traceCoreInterface_0_fromEncoder_enable), .io_traceCoreInterface_0_fromEncoder_stall(io_traceCoreInterface_0_fromEncoder_stall), .io_traceCoreInterface_0_toEncoder_cause(g_io_traceCoreInterface_0_toEncoder_cause), .io_traceCoreInterface_0_toEncoder_tval(g_io_traceCoreInterface_0_toEncoder_tval), .io_traceCoreInterface_0_toEncoder_priv(g_io_traceCoreInterface_0_toEncoder_priv), .io_traceCoreInterface_0_toEncoder_iaddr(g_io_traceCoreInterface_0_toEncoder_iaddr), .io_traceCoreInterface_0_toEncoder_itype(g_io_traceCoreInterface_0_toEncoder_itype), .io_traceCoreInterface_0_toEncoder_iretire(g_io_traceCoreInterface_0_toEncoder_iretire), .io_traceCoreInterface_0_toEncoder_ilastsize(g_io_traceCoreInterface_0_toEncoder_ilastsize));
  XSTop_xs u_i (.nmi_0_0(nmi_0_0), .nmi_0_1(nmi_0_1), .peripheral_awready(peripheral_awready), .peripheral_awvalid(i_peripheral_awvalid), .peripheral_awid(i_peripheral_awid), .peripheral_awaddr(i_peripheral_awaddr), .peripheral_awlen(i_peripheral_awlen), .peripheral_awsize(i_peripheral_awsize), .peripheral_awburst(i_peripheral_awburst), .peripheral_awlock(i_peripheral_awlock), .peripheral_awcache(i_peripheral_awcache), .peripheral_awprot(i_peripheral_awprot), .peripheral_awqos(i_peripheral_awqos), .peripheral_wready(peripheral_wready), .peripheral_wvalid(i_peripheral_wvalid), .peripheral_wdata(i_peripheral_wdata), .peripheral_wstrb(i_peripheral_wstrb), .peripheral_wlast(i_peripheral_wlast), .peripheral_bready(i_peripheral_bready), .peripheral_bvalid(peripheral_bvalid), .peripheral_bid(peripheral_bid), .peripheral_bresp(peripheral_bresp), .peripheral_arready(peripheral_arready), .peripheral_arvalid(i_peripheral_arvalid), .peripheral_arid(i_peripheral_arid), .peripheral_araddr(i_peripheral_araddr), .peripheral_arlen(i_peripheral_arlen), .peripheral_arsize(i_peripheral_arsize), .peripheral_arburst(i_peripheral_arburst), .peripheral_arlock(i_peripheral_arlock), .peripheral_arcache(i_peripheral_arcache), .peripheral_arprot(i_peripheral_arprot), .peripheral_arqos(i_peripheral_arqos), .peripheral_rready(i_peripheral_rready), .peripheral_rvalid(peripheral_rvalid), .peripheral_rid(peripheral_rid), .peripheral_rdata(peripheral_rdata), .peripheral_rresp(peripheral_rresp), .peripheral_rlast(peripheral_rlast), .memory_awready(memory_awready), .memory_awvalid(i_memory_awvalid), .memory_awid(i_memory_awid), .memory_awaddr(i_memory_awaddr), .memory_awlen(i_memory_awlen), .memory_awsize(i_memory_awsize), .memory_awburst(i_memory_awburst), .memory_awlock(i_memory_awlock), .memory_awcache(i_memory_awcache), .memory_awprot(i_memory_awprot), .memory_awqos(i_memory_awqos), .memory_wready(memory_wready), .memory_wvalid(i_memory_wvalid), .memory_wdata(i_memory_wdata), .memory_wstrb(i_memory_wstrb), .memory_wlast(i_memory_wlast), .memory_bready(i_memory_bready), .memory_bvalid(memory_bvalid), .memory_bid(memory_bid), .memory_bresp(memory_bresp), .memory_arready(memory_arready), .memory_arvalid(i_memory_arvalid), .memory_arid(i_memory_arid), .memory_araddr(i_memory_araddr), .memory_arlen(i_memory_arlen), .memory_arsize(i_memory_arsize), .memory_arburst(i_memory_arburst), .memory_arlock(i_memory_arlock), .memory_arcache(i_memory_arcache), .memory_arprot(i_memory_arprot), .memory_arqos(i_memory_arqos), .memory_rready(i_memory_rready), .memory_rvalid(memory_rvalid), .memory_rid(memory_rid), .memory_rdata(memory_rdata), .memory_rresp(memory_rresp), .memory_rlast(memory_rlast), .io_clock(io_clock), .io_reset(io_reset), .io_sram_config(io_sram_config), .io_extIntrs(io_extIntrs), .io_pll0_lock(io_pll0_lock), .io_pll0_ctrl_0(i_io_pll0_ctrl_0), .io_pll0_ctrl_1(i_io_pll0_ctrl_1), .io_pll0_ctrl_2(i_io_pll0_ctrl_2), .io_pll0_ctrl_3(i_io_pll0_ctrl_3), .io_pll0_ctrl_4(i_io_pll0_ctrl_4), .io_pll0_ctrl_5(i_io_pll0_ctrl_5), .io_systemjtag_jtag_TCK(io_systemjtag_jtag_TCK), .io_systemjtag_jtag_TMS(io_systemjtag_jtag_TMS), .io_systemjtag_jtag_TDI(io_systemjtag_jtag_TDI), .io_systemjtag_jtag_TDO_data(i_io_systemjtag_jtag_TDO_data), .io_systemjtag_jtag_TDO_driven(i_io_systemjtag_jtag_TDO_driven), .io_systemjtag_reset(io_systemjtag_reset), .io_systemjtag_mfr_id(io_systemjtag_mfr_id), .io_systemjtag_part_number(io_systemjtag_part_number), .io_systemjtag_version(io_systemjtag_version), .io_debug_reset(i_io_debug_reset), .io_rtc_clock(io_rtc_clock), .io_cacheable_check_req_0_valid(io_cacheable_check_req_0_valid), .io_cacheable_check_req_0_bits_addr(io_cacheable_check_req_0_bits_addr), .io_cacheable_check_req_0_bits_size(io_cacheable_check_req_0_bits_size), .io_cacheable_check_req_0_bits_cmd(io_cacheable_check_req_0_bits_cmd), .io_cacheable_check_req_1_valid(io_cacheable_check_req_1_valid), .io_cacheable_check_req_1_bits_addr(io_cacheable_check_req_1_bits_addr), .io_cacheable_check_req_1_bits_size(io_cacheable_check_req_1_bits_size), .io_cacheable_check_req_1_bits_cmd(io_cacheable_check_req_1_bits_cmd), .io_cacheable_check_resp_0_ld(i_io_cacheable_check_resp_0_ld), .io_cacheable_check_resp_0_st(i_io_cacheable_check_resp_0_st), .io_cacheable_check_resp_0_instr(i_io_cacheable_check_resp_0_instr), .io_cacheable_check_resp_0_mmio(i_io_cacheable_check_resp_0_mmio), .io_cacheable_check_resp_0_atomic(i_io_cacheable_check_resp_0_atomic), .io_cacheable_check_resp_1_ld(i_io_cacheable_check_resp_1_ld), .io_cacheable_check_resp_1_st(i_io_cacheable_check_resp_1_st), .io_cacheable_check_resp_1_instr(i_io_cacheable_check_resp_1_instr), .io_cacheable_check_resp_1_mmio(i_io_cacheable_check_resp_1_mmio), .io_cacheable_check_resp_1_atomic(i_io_cacheable_check_resp_1_atomic), .io_riscv_halt_0(i_io_riscv_halt_0), .io_riscv_critical_error_0(i_io_riscv_critical_error_0), .io_riscv_rst_vec_0(io_riscv_rst_vec_0), .io_traceCoreInterface_0_fromEncoder_enable(io_traceCoreInterface_0_fromEncoder_enable), .io_traceCoreInterface_0_fromEncoder_stall(io_traceCoreInterface_0_fromEncoder_stall), .io_traceCoreInterface_0_toEncoder_cause(i_io_traceCoreInterface_0_toEncoder_cause), .io_traceCoreInterface_0_toEncoder_tval(i_io_traceCoreInterface_0_toEncoder_tval), .io_traceCoreInterface_0_toEncoder_priv(i_io_traceCoreInterface_0_toEncoder_priv), .io_traceCoreInterface_0_toEncoder_iaddr(i_io_traceCoreInterface_0_toEncoder_iaddr), .io_traceCoreInterface_0_toEncoder_itype(i_io_traceCoreInterface_0_toEncoder_itype), .io_traceCoreInterface_0_toEncoder_iretire(i_io_traceCoreInterface_0_toEncoder_iretire), .io_traceCoreInterface_0_toEncoder_ilastsize(i_io_traceCoreInterface_0_toEncoder_ilastsize));

  bit reported [0:79];
  int distinct_div = 0;

  always @(negedge clk) begin
    if (rst) begin
      io_cacheable_check_req_0_valid <= 1'b0;
      io_cacheable_check_req_1_valid <= 1'b0;
    end else begin
      nmi_0_0 <= $urandom_range(0,1);
      nmi_0_1 <= $urandom_range(0,1);
      peripheral_awready <= $urandom_range(0,1);
      peripheral_wready <= $urandom_range(0,1);
      peripheral_bvalid <= $urandom_range(0,1);
      peripheral_bid <= 2'($urandom);
      peripheral_bresp <= 2'($urandom);
      peripheral_arready <= $urandom_range(0,1);
      peripheral_rvalid <= $urandom_range(0,1);
      peripheral_rid <= 2'($urandom);
      peripheral_rdata <= {$urandom(), $urandom()};
      peripheral_rresp <= 2'($urandom);
      peripheral_rlast <= $urandom_range(0,1);
      memory_awready <= $urandom_range(0,1);
      memory_wready <= $urandom_range(0,1);
      memory_bvalid <= $urandom_range(0,1);
      memory_bid <= 14'($urandom);
      memory_bresp <= 2'($urandom);
      memory_arready <= $urandom_range(0,1);
      memory_rvalid <= $urandom_range(0,1);
      memory_rid <= 14'($urandom);
      memory_rdata <= {$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()};
      memory_rresp <= 2'($urandom);
      memory_rlast <= $urandom_range(0,1);
      io_sram_config <= 16'($urandom);
      io_extIntrs <= {$urandom(), $urandom()};
      io_pll0_lock <= $urandom_range(0,1);
      io_systemjtag_jtag_TCK <= $urandom_range(0,1);
      io_systemjtag_jtag_TMS <= $urandom_range(0,1);
      io_systemjtag_jtag_TDI <= $urandom_range(0,1);
      io_systemjtag_reset <= $urandom_range(0,1);
      io_systemjtag_mfr_id <= 11'($urandom);
      io_systemjtag_part_number <= 16'($urandom);
      io_systemjtag_version <= 4'($urandom);
      io_rtc_clock <= $urandom_range(0,1);
      io_cacheable_check_req_0_valid <= $urandom_range(0,1);
      io_cacheable_check_req_0_bits_addr <= {$urandom(), $urandom()};
      io_cacheable_check_req_0_bits_size <= 2'($urandom);
      io_cacheable_check_req_0_bits_cmd <= 3'($urandom);
      io_cacheable_check_req_1_valid <= $urandom_range(0,1);
      io_cacheable_check_req_1_bits_addr <= {$urandom(), $urandom()};
      io_cacheable_check_req_1_bits_size <= 2'($urandom);
      io_cacheable_check_req_1_bits_cmd <= 3'($urandom);
      io_riscv_rst_vec_0 <= {$urandom(), $urandom()};
      io_traceCoreInterface_0_fromEncoder_enable <= $urandom_range(0,1);
      io_traceCoreInterface_0_fromEncoder_stall <= $urandom_range(0,1);
    end
  end

  always @(*) io_clock = clk;
  always @(*) io_reset = rst;

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_peripheral_awvalid) && g_peripheral_awvalid !== i_peripheral_awvalid) begin errors++;
      if(!reported[0]) begin reported[0]=1; distinct_div++;
        $display("[DIV %0t] peripheral_awvalid g=%h i=%h", $time, g_peripheral_awvalid, i_peripheral_awvalid); end end
    if (!$isunknown(g_peripheral_awid) && g_peripheral_awid !== i_peripheral_awid) begin errors++;
      if(!reported[1]) begin reported[1]=1; distinct_div++;
        $display("[DIV %0t] peripheral_awid g=%h i=%h", $time, g_peripheral_awid, i_peripheral_awid); end end
    if (!$isunknown(g_peripheral_awaddr) && g_peripheral_awaddr !== i_peripheral_awaddr) begin errors++;
      if(!reported[2]) begin reported[2]=1; distinct_div++;
        $display("[DIV %0t] peripheral_awaddr g=%h i=%h", $time, g_peripheral_awaddr, i_peripheral_awaddr); end end
    if (!$isunknown(g_peripheral_awlen) && g_peripheral_awlen !== i_peripheral_awlen) begin errors++;
      if(!reported[3]) begin reported[3]=1; distinct_div++;
        $display("[DIV %0t] peripheral_awlen g=%h i=%h", $time, g_peripheral_awlen, i_peripheral_awlen); end end
    if (!$isunknown(g_peripheral_awsize) && g_peripheral_awsize !== i_peripheral_awsize) begin errors++;
      if(!reported[4]) begin reported[4]=1; distinct_div++;
        $display("[DIV %0t] peripheral_awsize g=%h i=%h", $time, g_peripheral_awsize, i_peripheral_awsize); end end
    if (!$isunknown(g_peripheral_awburst) && g_peripheral_awburst !== i_peripheral_awburst) begin errors++;
      if(!reported[5]) begin reported[5]=1; distinct_div++;
        $display("[DIV %0t] peripheral_awburst g=%h i=%h", $time, g_peripheral_awburst, i_peripheral_awburst); end end
    if (!$isunknown(g_peripheral_awlock) && g_peripheral_awlock !== i_peripheral_awlock) begin errors++;
      if(!reported[6]) begin reported[6]=1; distinct_div++;
        $display("[DIV %0t] peripheral_awlock g=%h i=%h", $time, g_peripheral_awlock, i_peripheral_awlock); end end
    if (!$isunknown(g_peripheral_awcache) && g_peripheral_awcache !== i_peripheral_awcache) begin errors++;
      if(!reported[7]) begin reported[7]=1; distinct_div++;
        $display("[DIV %0t] peripheral_awcache g=%h i=%h", $time, g_peripheral_awcache, i_peripheral_awcache); end end
    if (!$isunknown(g_peripheral_awprot) && g_peripheral_awprot !== i_peripheral_awprot) begin errors++;
      if(!reported[8]) begin reported[8]=1; distinct_div++;
        $display("[DIV %0t] peripheral_awprot g=%h i=%h", $time, g_peripheral_awprot, i_peripheral_awprot); end end
    if (!$isunknown(g_peripheral_awqos) && g_peripheral_awqos !== i_peripheral_awqos) begin errors++;
      if(!reported[9]) begin reported[9]=1; distinct_div++;
        $display("[DIV %0t] peripheral_awqos g=%h i=%h", $time, g_peripheral_awqos, i_peripheral_awqos); end end
    if (!$isunknown(g_peripheral_wvalid) && g_peripheral_wvalid !== i_peripheral_wvalid) begin errors++;
      if(!reported[10]) begin reported[10]=1; distinct_div++;
        $display("[DIV %0t] peripheral_wvalid g=%h i=%h", $time, g_peripheral_wvalid, i_peripheral_wvalid); end end
    if (!$isunknown(g_peripheral_wdata) && g_peripheral_wdata !== i_peripheral_wdata) begin errors++;
      if(!reported[11]) begin reported[11]=1; distinct_div++;
        $display("[DIV %0t] peripheral_wdata g=%h i=%h", $time, g_peripheral_wdata, i_peripheral_wdata); end end
    if (!$isunknown(g_peripheral_wstrb) && g_peripheral_wstrb !== i_peripheral_wstrb) begin errors++;
      if(!reported[12]) begin reported[12]=1; distinct_div++;
        $display("[DIV %0t] peripheral_wstrb g=%h i=%h", $time, g_peripheral_wstrb, i_peripheral_wstrb); end end
    if (!$isunknown(g_peripheral_wlast) && g_peripheral_wlast !== i_peripheral_wlast) begin errors++;
      if(!reported[13]) begin reported[13]=1; distinct_div++;
        $display("[DIV %0t] peripheral_wlast g=%h i=%h", $time, g_peripheral_wlast, i_peripheral_wlast); end end
    if (!$isunknown(g_peripheral_bready) && g_peripheral_bready !== i_peripheral_bready) begin errors++;
      if(!reported[14]) begin reported[14]=1; distinct_div++;
        $display("[DIV %0t] peripheral_bready g=%h i=%h", $time, g_peripheral_bready, i_peripheral_bready); end end
    if (!$isunknown(g_peripheral_arvalid) && g_peripheral_arvalid !== i_peripheral_arvalid) begin errors++;
      if(!reported[15]) begin reported[15]=1; distinct_div++;
        $display("[DIV %0t] peripheral_arvalid g=%h i=%h", $time, g_peripheral_arvalid, i_peripheral_arvalid); end end
    if (!$isunknown(g_peripheral_arid) && g_peripheral_arid !== i_peripheral_arid) begin errors++;
      if(!reported[16]) begin reported[16]=1; distinct_div++;
        $display("[DIV %0t] peripheral_arid g=%h i=%h", $time, g_peripheral_arid, i_peripheral_arid); end end
    if (!$isunknown(g_peripheral_araddr) && g_peripheral_araddr !== i_peripheral_araddr) begin errors++;
      if(!reported[17]) begin reported[17]=1; distinct_div++;
        $display("[DIV %0t] peripheral_araddr g=%h i=%h", $time, g_peripheral_araddr, i_peripheral_araddr); end end
    if (!$isunknown(g_peripheral_arlen) && g_peripheral_arlen !== i_peripheral_arlen) begin errors++;
      if(!reported[18]) begin reported[18]=1; distinct_div++;
        $display("[DIV %0t] peripheral_arlen g=%h i=%h", $time, g_peripheral_arlen, i_peripheral_arlen); end end
    if (!$isunknown(g_peripheral_arsize) && g_peripheral_arsize !== i_peripheral_arsize) begin errors++;
      if(!reported[19]) begin reported[19]=1; distinct_div++;
        $display("[DIV %0t] peripheral_arsize g=%h i=%h", $time, g_peripheral_arsize, i_peripheral_arsize); end end
    if (!$isunknown(g_peripheral_arburst) && g_peripheral_arburst !== i_peripheral_arburst) begin errors++;
      if(!reported[20]) begin reported[20]=1; distinct_div++;
        $display("[DIV %0t] peripheral_arburst g=%h i=%h", $time, g_peripheral_arburst, i_peripheral_arburst); end end
    if (!$isunknown(g_peripheral_arlock) && g_peripheral_arlock !== i_peripheral_arlock) begin errors++;
      if(!reported[21]) begin reported[21]=1; distinct_div++;
        $display("[DIV %0t] peripheral_arlock g=%h i=%h", $time, g_peripheral_arlock, i_peripheral_arlock); end end
    if (!$isunknown(g_peripheral_arcache) && g_peripheral_arcache !== i_peripheral_arcache) begin errors++;
      if(!reported[22]) begin reported[22]=1; distinct_div++;
        $display("[DIV %0t] peripheral_arcache g=%h i=%h", $time, g_peripheral_arcache, i_peripheral_arcache); end end
    if (!$isunknown(g_peripheral_arprot) && g_peripheral_arprot !== i_peripheral_arprot) begin errors++;
      if(!reported[23]) begin reported[23]=1; distinct_div++;
        $display("[DIV %0t] peripheral_arprot g=%h i=%h", $time, g_peripheral_arprot, i_peripheral_arprot); end end
    if (!$isunknown(g_peripheral_arqos) && g_peripheral_arqos !== i_peripheral_arqos) begin errors++;
      if(!reported[24]) begin reported[24]=1; distinct_div++;
        $display("[DIV %0t] peripheral_arqos g=%h i=%h", $time, g_peripheral_arqos, i_peripheral_arqos); end end
    if (!$isunknown(g_peripheral_rready) && g_peripheral_rready !== i_peripheral_rready) begin errors++;
      if(!reported[25]) begin reported[25]=1; distinct_div++;
        $display("[DIV %0t] peripheral_rready g=%h i=%h", $time, g_peripheral_rready, i_peripheral_rready); end end
    if (!$isunknown(g_memory_awvalid) && g_memory_awvalid !== i_memory_awvalid) begin errors++;
      if(!reported[26]) begin reported[26]=1; distinct_div++;
        $display("[DIV %0t] memory_awvalid g=%h i=%h", $time, g_memory_awvalid, i_memory_awvalid); end end
    if (!$isunknown(g_memory_awid) && g_memory_awid !== i_memory_awid) begin errors++;
      if(!reported[27]) begin reported[27]=1; distinct_div++;
        $display("[DIV %0t] memory_awid g=%h i=%h", $time, g_memory_awid, i_memory_awid); end end
    if (!$isunknown(g_memory_awaddr) && g_memory_awaddr !== i_memory_awaddr) begin errors++;
      if(!reported[28]) begin reported[28]=1; distinct_div++;
        $display("[DIV %0t] memory_awaddr g=%h i=%h", $time, g_memory_awaddr, i_memory_awaddr); end end
    if (!$isunknown(g_memory_awlen) && g_memory_awlen !== i_memory_awlen) begin errors++;
      if(!reported[29]) begin reported[29]=1; distinct_div++;
        $display("[DIV %0t] memory_awlen g=%h i=%h", $time, g_memory_awlen, i_memory_awlen); end end
    if (!$isunknown(g_memory_awsize) && g_memory_awsize !== i_memory_awsize) begin errors++;
      if(!reported[30]) begin reported[30]=1; distinct_div++;
        $display("[DIV %0t] memory_awsize g=%h i=%h", $time, g_memory_awsize, i_memory_awsize); end end
    if (!$isunknown(g_memory_awburst) && g_memory_awburst !== i_memory_awburst) begin errors++;
      if(!reported[31]) begin reported[31]=1; distinct_div++;
        $display("[DIV %0t] memory_awburst g=%h i=%h", $time, g_memory_awburst, i_memory_awburst); end end
    if (!$isunknown(g_memory_awlock) && g_memory_awlock !== i_memory_awlock) begin errors++;
      if(!reported[32]) begin reported[32]=1; distinct_div++;
        $display("[DIV %0t] memory_awlock g=%h i=%h", $time, g_memory_awlock, i_memory_awlock); end end
    if (!$isunknown(g_memory_awcache) && g_memory_awcache !== i_memory_awcache) begin errors++;
      if(!reported[33]) begin reported[33]=1; distinct_div++;
        $display("[DIV %0t] memory_awcache g=%h i=%h", $time, g_memory_awcache, i_memory_awcache); end end
    if (!$isunknown(g_memory_awprot) && g_memory_awprot !== i_memory_awprot) begin errors++;
      if(!reported[34]) begin reported[34]=1; distinct_div++;
        $display("[DIV %0t] memory_awprot g=%h i=%h", $time, g_memory_awprot, i_memory_awprot); end end
    if (!$isunknown(g_memory_awqos) && g_memory_awqos !== i_memory_awqos) begin errors++;
      if(!reported[35]) begin reported[35]=1; distinct_div++;
        $display("[DIV %0t] memory_awqos g=%h i=%h", $time, g_memory_awqos, i_memory_awqos); end end
    if (!$isunknown(g_memory_wvalid) && g_memory_wvalid !== i_memory_wvalid) begin errors++;
      if(!reported[36]) begin reported[36]=1; distinct_div++;
        $display("[DIV %0t] memory_wvalid g=%h i=%h", $time, g_memory_wvalid, i_memory_wvalid); end end
    if (!$isunknown(g_memory_wdata) && g_memory_wdata !== i_memory_wdata) begin errors++;
      if(!reported[37]) begin reported[37]=1; distinct_div++;
        $display("[DIV %0t] memory_wdata g=%h i=%h", $time, g_memory_wdata, i_memory_wdata); end end
    if (!$isunknown(g_memory_wstrb) && g_memory_wstrb !== i_memory_wstrb) begin errors++;
      if(!reported[38]) begin reported[38]=1; distinct_div++;
        $display("[DIV %0t] memory_wstrb g=%h i=%h", $time, g_memory_wstrb, i_memory_wstrb); end end
    if (!$isunknown(g_memory_wlast) && g_memory_wlast !== i_memory_wlast) begin errors++;
      if(!reported[39]) begin reported[39]=1; distinct_div++;
        $display("[DIV %0t] memory_wlast g=%h i=%h", $time, g_memory_wlast, i_memory_wlast); end end
    if (!$isunknown(g_memory_bready) && g_memory_bready !== i_memory_bready) begin errors++;
      if(!reported[40]) begin reported[40]=1; distinct_div++;
        $display("[DIV %0t] memory_bready g=%h i=%h", $time, g_memory_bready, i_memory_bready); end end
    if (!$isunknown(g_memory_arvalid) && g_memory_arvalid !== i_memory_arvalid) begin errors++;
      if(!reported[41]) begin reported[41]=1; distinct_div++;
        $display("[DIV %0t] memory_arvalid g=%h i=%h", $time, g_memory_arvalid, i_memory_arvalid); end end
    if (!$isunknown(g_memory_arid) && g_memory_arid !== i_memory_arid) begin errors++;
      if(!reported[42]) begin reported[42]=1; distinct_div++;
        $display("[DIV %0t] memory_arid g=%h i=%h", $time, g_memory_arid, i_memory_arid); end end
    if (!$isunknown(g_memory_araddr) && g_memory_araddr !== i_memory_araddr) begin errors++;
      if(!reported[43]) begin reported[43]=1; distinct_div++;
        $display("[DIV %0t] memory_araddr g=%h i=%h", $time, g_memory_araddr, i_memory_araddr); end end
    if (!$isunknown(g_memory_arlen) && g_memory_arlen !== i_memory_arlen) begin errors++;
      if(!reported[44]) begin reported[44]=1; distinct_div++;
        $display("[DIV %0t] memory_arlen g=%h i=%h", $time, g_memory_arlen, i_memory_arlen); end end
    if (!$isunknown(g_memory_arsize) && g_memory_arsize !== i_memory_arsize) begin errors++;
      if(!reported[45]) begin reported[45]=1; distinct_div++;
        $display("[DIV %0t] memory_arsize g=%h i=%h", $time, g_memory_arsize, i_memory_arsize); end end
    if (!$isunknown(g_memory_arburst) && g_memory_arburst !== i_memory_arburst) begin errors++;
      if(!reported[46]) begin reported[46]=1; distinct_div++;
        $display("[DIV %0t] memory_arburst g=%h i=%h", $time, g_memory_arburst, i_memory_arburst); end end
    if (!$isunknown(g_memory_arlock) && g_memory_arlock !== i_memory_arlock) begin errors++;
      if(!reported[47]) begin reported[47]=1; distinct_div++;
        $display("[DIV %0t] memory_arlock g=%h i=%h", $time, g_memory_arlock, i_memory_arlock); end end
    if (!$isunknown(g_memory_arcache) && g_memory_arcache !== i_memory_arcache) begin errors++;
      if(!reported[48]) begin reported[48]=1; distinct_div++;
        $display("[DIV %0t] memory_arcache g=%h i=%h", $time, g_memory_arcache, i_memory_arcache); end end
    if (!$isunknown(g_memory_arprot) && g_memory_arprot !== i_memory_arprot) begin errors++;
      if(!reported[49]) begin reported[49]=1; distinct_div++;
        $display("[DIV %0t] memory_arprot g=%h i=%h", $time, g_memory_arprot, i_memory_arprot); end end
    if (!$isunknown(g_memory_arqos) && g_memory_arqos !== i_memory_arqos) begin errors++;
      if(!reported[50]) begin reported[50]=1; distinct_div++;
        $display("[DIV %0t] memory_arqos g=%h i=%h", $time, g_memory_arqos, i_memory_arqos); end end
    if (!$isunknown(g_memory_rready) && g_memory_rready !== i_memory_rready) begin errors++;
      if(!reported[51]) begin reported[51]=1; distinct_div++;
        $display("[DIV %0t] memory_rready g=%h i=%h", $time, g_memory_rready, i_memory_rready); end end
    if (!$isunknown(g_io_pll0_ctrl_0) && g_io_pll0_ctrl_0 !== i_io_pll0_ctrl_0) begin errors++;
      if(!reported[52]) begin reported[52]=1; distinct_div++;
        $display("[DIV %0t] io_pll0_ctrl_0 g=%h i=%h", $time, g_io_pll0_ctrl_0, i_io_pll0_ctrl_0); end end
    if (!$isunknown(g_io_pll0_ctrl_1) && g_io_pll0_ctrl_1 !== i_io_pll0_ctrl_1) begin errors++;
      if(!reported[53]) begin reported[53]=1; distinct_div++;
        $display("[DIV %0t] io_pll0_ctrl_1 g=%h i=%h", $time, g_io_pll0_ctrl_1, i_io_pll0_ctrl_1); end end
    if (!$isunknown(g_io_pll0_ctrl_2) && g_io_pll0_ctrl_2 !== i_io_pll0_ctrl_2) begin errors++;
      if(!reported[54]) begin reported[54]=1; distinct_div++;
        $display("[DIV %0t] io_pll0_ctrl_2 g=%h i=%h", $time, g_io_pll0_ctrl_2, i_io_pll0_ctrl_2); end end
    if (!$isunknown(g_io_pll0_ctrl_3) && g_io_pll0_ctrl_3 !== i_io_pll0_ctrl_3) begin errors++;
      if(!reported[55]) begin reported[55]=1; distinct_div++;
        $display("[DIV %0t] io_pll0_ctrl_3 g=%h i=%h", $time, g_io_pll0_ctrl_3, i_io_pll0_ctrl_3); end end
    if (!$isunknown(g_io_pll0_ctrl_4) && g_io_pll0_ctrl_4 !== i_io_pll0_ctrl_4) begin errors++;
      if(!reported[56]) begin reported[56]=1; distinct_div++;
        $display("[DIV %0t] io_pll0_ctrl_4 g=%h i=%h", $time, g_io_pll0_ctrl_4, i_io_pll0_ctrl_4); end end
    if (!$isunknown(g_io_pll0_ctrl_5) && g_io_pll0_ctrl_5 !== i_io_pll0_ctrl_5) begin errors++;
      if(!reported[57]) begin reported[57]=1; distinct_div++;
        $display("[DIV %0t] io_pll0_ctrl_5 g=%h i=%h", $time, g_io_pll0_ctrl_5, i_io_pll0_ctrl_5); end end
    if (!$isunknown(g_io_systemjtag_jtag_TDO_data) && g_io_systemjtag_jtag_TDO_data !== i_io_systemjtag_jtag_TDO_data) begin errors++;
      if(!reported[58]) begin reported[58]=1; distinct_div++;
        $display("[DIV %0t] io_systemjtag_jtag_TDO_data g=%h i=%h", $time, g_io_systemjtag_jtag_TDO_data, i_io_systemjtag_jtag_TDO_data); end end
    if (!$isunknown(g_io_systemjtag_jtag_TDO_driven) && g_io_systemjtag_jtag_TDO_driven !== i_io_systemjtag_jtag_TDO_driven) begin errors++;
      if(!reported[59]) begin reported[59]=1; distinct_div++;
        $display("[DIV %0t] io_systemjtag_jtag_TDO_driven g=%h i=%h", $time, g_io_systemjtag_jtag_TDO_driven, i_io_systemjtag_jtag_TDO_driven); end end
    if (!$isunknown(g_io_debug_reset) && g_io_debug_reset !== i_io_debug_reset) begin errors++;
      if(!reported[60]) begin reported[60]=1; distinct_div++;
        $display("[DIV %0t] io_debug_reset g=%h i=%h", $time, g_io_debug_reset, i_io_debug_reset); end end
    if (!$isunknown(g_io_cacheable_check_resp_0_ld) && g_io_cacheable_check_resp_0_ld !== i_io_cacheable_check_resp_0_ld) begin errors++;
      if(!reported[61]) begin reported[61]=1; distinct_div++;
        $display("[DIV %0t] io_cacheable_check_resp_0_ld g=%h i=%h", $time, g_io_cacheable_check_resp_0_ld, i_io_cacheable_check_resp_0_ld); end end
    if (!$isunknown(g_io_cacheable_check_resp_0_st) && g_io_cacheable_check_resp_0_st !== i_io_cacheable_check_resp_0_st) begin errors++;
      if(!reported[62]) begin reported[62]=1; distinct_div++;
        $display("[DIV %0t] io_cacheable_check_resp_0_st g=%h i=%h", $time, g_io_cacheable_check_resp_0_st, i_io_cacheable_check_resp_0_st); end end
    if (!$isunknown(g_io_cacheable_check_resp_0_instr) && g_io_cacheable_check_resp_0_instr !== i_io_cacheable_check_resp_0_instr) begin errors++;
      if(!reported[63]) begin reported[63]=1; distinct_div++;
        $display("[DIV %0t] io_cacheable_check_resp_0_instr g=%h i=%h", $time, g_io_cacheable_check_resp_0_instr, i_io_cacheable_check_resp_0_instr); end end
    if (!$isunknown(g_io_cacheable_check_resp_0_mmio) && g_io_cacheable_check_resp_0_mmio !== i_io_cacheable_check_resp_0_mmio) begin errors++;
      if(!reported[64]) begin reported[64]=1; distinct_div++;
        $display("[DIV %0t] io_cacheable_check_resp_0_mmio g=%h i=%h", $time, g_io_cacheable_check_resp_0_mmio, i_io_cacheable_check_resp_0_mmio); end end
    if (!$isunknown(g_io_cacheable_check_resp_0_atomic) && g_io_cacheable_check_resp_0_atomic !== i_io_cacheable_check_resp_0_atomic) begin errors++;
      if(!reported[65]) begin reported[65]=1; distinct_div++;
        $display("[DIV %0t] io_cacheable_check_resp_0_atomic g=%h i=%h", $time, g_io_cacheable_check_resp_0_atomic, i_io_cacheable_check_resp_0_atomic); end end
    if (!$isunknown(g_io_cacheable_check_resp_1_ld) && g_io_cacheable_check_resp_1_ld !== i_io_cacheable_check_resp_1_ld) begin errors++;
      if(!reported[66]) begin reported[66]=1; distinct_div++;
        $display("[DIV %0t] io_cacheable_check_resp_1_ld g=%h i=%h", $time, g_io_cacheable_check_resp_1_ld, i_io_cacheable_check_resp_1_ld); end end
    if (!$isunknown(g_io_cacheable_check_resp_1_st) && g_io_cacheable_check_resp_1_st !== i_io_cacheable_check_resp_1_st) begin errors++;
      if(!reported[67]) begin reported[67]=1; distinct_div++;
        $display("[DIV %0t] io_cacheable_check_resp_1_st g=%h i=%h", $time, g_io_cacheable_check_resp_1_st, i_io_cacheable_check_resp_1_st); end end
    if (!$isunknown(g_io_cacheable_check_resp_1_instr) && g_io_cacheable_check_resp_1_instr !== i_io_cacheable_check_resp_1_instr) begin errors++;
      if(!reported[68]) begin reported[68]=1; distinct_div++;
        $display("[DIV %0t] io_cacheable_check_resp_1_instr g=%h i=%h", $time, g_io_cacheable_check_resp_1_instr, i_io_cacheable_check_resp_1_instr); end end
    if (!$isunknown(g_io_cacheable_check_resp_1_mmio) && g_io_cacheable_check_resp_1_mmio !== i_io_cacheable_check_resp_1_mmio) begin errors++;
      if(!reported[69]) begin reported[69]=1; distinct_div++;
        $display("[DIV %0t] io_cacheable_check_resp_1_mmio g=%h i=%h", $time, g_io_cacheable_check_resp_1_mmio, i_io_cacheable_check_resp_1_mmio); end end
    if (!$isunknown(g_io_cacheable_check_resp_1_atomic) && g_io_cacheable_check_resp_1_atomic !== i_io_cacheable_check_resp_1_atomic) begin errors++;
      if(!reported[70]) begin reported[70]=1; distinct_div++;
        $display("[DIV %0t] io_cacheable_check_resp_1_atomic g=%h i=%h", $time, g_io_cacheable_check_resp_1_atomic, i_io_cacheable_check_resp_1_atomic); end end
    if (!$isunknown(g_io_riscv_halt_0) && g_io_riscv_halt_0 !== i_io_riscv_halt_0) begin errors++;
      if(!reported[71]) begin reported[71]=1; distinct_div++;
        $display("[DIV %0t] io_riscv_halt_0 g=%h i=%h", $time, g_io_riscv_halt_0, i_io_riscv_halt_0); end end
    if (!$isunknown(g_io_riscv_critical_error_0) && g_io_riscv_critical_error_0 !== i_io_riscv_critical_error_0) begin errors++;
      if(!reported[72]) begin reported[72]=1; distinct_div++;
        $display("[DIV %0t] io_riscv_critical_error_0 g=%h i=%h", $time, g_io_riscv_critical_error_0, i_io_riscv_critical_error_0); end end
    if (!$isunknown(g_io_traceCoreInterface_0_toEncoder_cause) && g_io_traceCoreInterface_0_toEncoder_cause !== i_io_traceCoreInterface_0_toEncoder_cause) begin errors++;
      if(!reported[73]) begin reported[73]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_0_toEncoder_cause g=%h i=%h", $time, g_io_traceCoreInterface_0_toEncoder_cause, i_io_traceCoreInterface_0_toEncoder_cause); end end
    if (!$isunknown(g_io_traceCoreInterface_0_toEncoder_tval) && g_io_traceCoreInterface_0_toEncoder_tval !== i_io_traceCoreInterface_0_toEncoder_tval) begin errors++;
      if(!reported[74]) begin reported[74]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_0_toEncoder_tval g=%h i=%h", $time, g_io_traceCoreInterface_0_toEncoder_tval, i_io_traceCoreInterface_0_toEncoder_tval); end end
    if (!$isunknown(g_io_traceCoreInterface_0_toEncoder_priv) && g_io_traceCoreInterface_0_toEncoder_priv !== i_io_traceCoreInterface_0_toEncoder_priv) begin errors++;
      if(!reported[75]) begin reported[75]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_0_toEncoder_priv g=%h i=%h", $time, g_io_traceCoreInterface_0_toEncoder_priv, i_io_traceCoreInterface_0_toEncoder_priv); end end
    if (!$isunknown(g_io_traceCoreInterface_0_toEncoder_iaddr) && g_io_traceCoreInterface_0_toEncoder_iaddr !== i_io_traceCoreInterface_0_toEncoder_iaddr) begin errors++;
      if(!reported[76]) begin reported[76]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_0_toEncoder_iaddr g=%h i=%h", $time, g_io_traceCoreInterface_0_toEncoder_iaddr, i_io_traceCoreInterface_0_toEncoder_iaddr); end end
    if (!$isunknown(g_io_traceCoreInterface_0_toEncoder_itype) && g_io_traceCoreInterface_0_toEncoder_itype !== i_io_traceCoreInterface_0_toEncoder_itype) begin errors++;
      if(!reported[77]) begin reported[77]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_0_toEncoder_itype g=%h i=%h", $time, g_io_traceCoreInterface_0_toEncoder_itype, i_io_traceCoreInterface_0_toEncoder_itype); end end
    if (!$isunknown(g_io_traceCoreInterface_0_toEncoder_iretire) && g_io_traceCoreInterface_0_toEncoder_iretire !== i_io_traceCoreInterface_0_toEncoder_iretire) begin errors++;
      if(!reported[78]) begin reported[78]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_0_toEncoder_iretire g=%h i=%h", $time, g_io_traceCoreInterface_0_toEncoder_iretire, i_io_traceCoreInterface_0_toEncoder_iretire); end end
    if (!$isunknown(g_io_traceCoreInterface_0_toEncoder_ilastsize) && g_io_traceCoreInterface_0_toEncoder_ilastsize !== i_io_traceCoreInterface_0_toEncoder_ilastsize) begin errors++;
      if(!reported[79]) begin reported[79]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_0_toEncoder_ilastsize g=%h i=%h", $time, g_io_traceCoreInterface_0_toEncoder_ilastsize, i_io_traceCoreInterface_0_toEncoder_ilastsize); end end
  end

  initial begin
    if (!$value$plusargs("NCYCLES=%d", NCYCLES)) NCYCLES = 200000;
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("distinct_diverging_ports=%0d / %0d", distinct_div, 80);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
