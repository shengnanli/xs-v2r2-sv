// 自动生成：scripts/gen_debugmodule.py —— 勿手改
// DebugModule 双时钟双例化逐拍比对: golden DebugModule vs 可读重写 DebugModule_xs。
// 两侧共用真实子模块 (TLDebugModule + DebugTransportModuleJTAG + 31 个依赖)。
// 双时钟: clock 主域 (io_clock/io_debugIO_clock) + tck 域 (JTAG/DMI)。
// 被测的本层逻辑 = hartIsInReset 同步寄存器 + DMI/总线连线; 连线/打拍若有误,
// 子模块收到不同输入 -> 输出发散 -> 逐拍比对捕获。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;   // 主域时钟 (io_clock = io_debugIO_clock)
  bit tck   = 0;   // JTAG/DMI 时钟 (与主域异步)
  bit mrst, drst, jrst;  // 主复位 / debug 复位 / jtag(DMI) 复位
  int errors = 0;
  int checks = 0;
  always #5  clock = ~clock;   // 100MHz
  always #17 tck   = ~tck;     // ~29MHz, 与主域错相异步

  logic auto_debug_dmInner_dmInner_sb2tlOpt_out_a_ready;
  logic auto_debug_dmInner_dmInner_sb2tlOpt_out_d_valid;
  logic [3:0] auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_opcode;
  logic [1:0] auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_param;
  logic [2:0] auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_size;
  logic auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_sink;
  logic auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_denied;
  logic [63:0] auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_data;
  logic auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_corrupt;
  logic auto_debug_dmInner_dmInner_tl_in_a_valid;
  logic [3:0] auto_debug_dmInner_dmInner_tl_in_a_bits_opcode;
  logic [1:0] auto_debug_dmInner_dmInner_tl_in_a_bits_size;
  logic [14:0] auto_debug_dmInner_dmInner_tl_in_a_bits_source;
  logic [29:0] auto_debug_dmInner_dmInner_tl_in_a_bits_address;
  logic [7:0] auto_debug_dmInner_dmInner_tl_in_a_bits_mask;
  logic [63:0] auto_debug_dmInner_dmInner_tl_in_a_bits_data;
  logic auto_debug_dmInner_dmInner_tl_in_d_ready;
  logic io_resetCtrl_hartIsInReset_0;
  logic io_debugIO_dmactiveAck;
  logic io_debugIO_systemjtag_jtag_TMS;
  logic io_debugIO_systemjtag_jtag_TDI;
  logic [10:0] io_debugIO_systemjtag_mfr_id;
  logic [15:0] io_debugIO_systemjtag_part_number;
  logic [3:0] io_debugIO_systemjtag_version;
  wire g_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_valid;
  wire i_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_valid;
  wire [3:0] g_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_opcode;
  wire [3:0] i_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_opcode;
  wire [2:0] g_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_size;
  wire [2:0] i_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_size;
  wire [48:0] g_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_address;
  wire [48:0] i_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_address;
  wire [7:0] g_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_mask;
  wire [7:0] i_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_mask;
  wire [63:0] g_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_data;
  wire [63:0] i_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_data;
  wire g_auto_debug_dmInner_dmInner_sb2tlOpt_out_d_ready;
  wire i_auto_debug_dmInner_dmInner_sb2tlOpt_out_d_ready;
  wire g_auto_debug_dmInner_dmInner_tl_in_a_ready;
  wire i_auto_debug_dmInner_dmInner_tl_in_a_ready;
  wire g_auto_debug_dmInner_dmInner_tl_in_d_valid;
  wire i_auto_debug_dmInner_dmInner_tl_in_d_valid;
  wire [3:0] g_auto_debug_dmInner_dmInner_tl_in_d_bits_opcode;
  wire [3:0] i_auto_debug_dmInner_dmInner_tl_in_d_bits_opcode;
  wire [1:0] g_auto_debug_dmInner_dmInner_tl_in_d_bits_size;
  wire [1:0] i_auto_debug_dmInner_dmInner_tl_in_d_bits_size;
  wire [14:0] g_auto_debug_dmInner_dmInner_tl_in_d_bits_source;
  wire [14:0] i_auto_debug_dmInner_dmInner_tl_in_d_bits_source;
  wire [63:0] g_auto_debug_dmInner_dmInner_tl_in_d_bits_data;
  wire [63:0] i_auto_debug_dmInner_dmInner_tl_in_d_bits_data;
  wire g_auto_debug_dmOuter_dmOuter_int_out_0;
  wire i_auto_debug_dmOuter_dmOuter_int_out_0;
  wire g_io_resetCtrl_hartResetReq_0;
  wire i_io_resetCtrl_hartResetReq_0;
  wire g_io_debugIO_systemjtag_jtag_TDO_data;
  wire i_io_debugIO_systemjtag_jtag_TDO_data;
  wire g_io_debugIO_systemjtag_jtag_TDO_driven;
  wire i_io_debugIO_systemjtag_jtag_TDO_driven;
  wire g_io_debugIO_ndreset;
  wire i_io_debugIO_ndreset;
  wire g_io_debugIO_dmactive;
  wire i_io_debugIO_dmactive;

  DebugModule u_g (
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_ready(auto_debug_dmInner_dmInner_sb2tlOpt_out_a_ready),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_valid(g_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_valid),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_opcode(g_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_opcode),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_size(g_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_size),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_address(g_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_address),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_mask(g_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_mask),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_data(g_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_data),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_ready(g_auto_debug_dmInner_dmInner_sb2tlOpt_out_d_ready),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_valid(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_valid),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_opcode(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_opcode),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_param(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_param),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_size(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_size),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_sink(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_sink),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_denied(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_denied),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_data(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_data),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_corrupt(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_corrupt),
    .auto_debug_dmInner_dmInner_tl_in_a_ready(g_auto_debug_dmInner_dmInner_tl_in_a_ready),
    .auto_debug_dmInner_dmInner_tl_in_a_valid(auto_debug_dmInner_dmInner_tl_in_a_valid),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_opcode(auto_debug_dmInner_dmInner_tl_in_a_bits_opcode),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_size(auto_debug_dmInner_dmInner_tl_in_a_bits_size),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_source(auto_debug_dmInner_dmInner_tl_in_a_bits_source),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_address(auto_debug_dmInner_dmInner_tl_in_a_bits_address),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_mask(auto_debug_dmInner_dmInner_tl_in_a_bits_mask),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_data(auto_debug_dmInner_dmInner_tl_in_a_bits_data),
    .auto_debug_dmInner_dmInner_tl_in_d_ready(auto_debug_dmInner_dmInner_tl_in_d_ready),
    .auto_debug_dmInner_dmInner_tl_in_d_valid(g_auto_debug_dmInner_dmInner_tl_in_d_valid),
    .auto_debug_dmInner_dmInner_tl_in_d_bits_opcode(g_auto_debug_dmInner_dmInner_tl_in_d_bits_opcode),
    .auto_debug_dmInner_dmInner_tl_in_d_bits_size(g_auto_debug_dmInner_dmInner_tl_in_d_bits_size),
    .auto_debug_dmInner_dmInner_tl_in_d_bits_source(g_auto_debug_dmInner_dmInner_tl_in_d_bits_source),
    .auto_debug_dmInner_dmInner_tl_in_d_bits_data(g_auto_debug_dmInner_dmInner_tl_in_d_bits_data),
    .auto_debug_dmOuter_dmOuter_int_out_0(g_auto_debug_dmOuter_dmOuter_int_out_0),
    .io_resetCtrl_hartResetReq_0(g_io_resetCtrl_hartResetReq_0),
    .io_resetCtrl_hartIsInReset_0(io_resetCtrl_hartIsInReset_0),
    .io_debugIO_clock(clock),
    .io_debugIO_reset(drst),
    .io_debugIO_systemjtag_jtag_TCK(tck),
    .io_debugIO_systemjtag_jtag_TMS(io_debugIO_systemjtag_jtag_TMS),
    .io_debugIO_systemjtag_jtag_TDI(io_debugIO_systemjtag_jtag_TDI),
    .io_debugIO_systemjtag_jtag_TDO_data(g_io_debugIO_systemjtag_jtag_TDO_data),
    .io_debugIO_systemjtag_jtag_TDO_driven(g_io_debugIO_systemjtag_jtag_TDO_driven),
    .io_debugIO_systemjtag_reset(jrst),
    .io_debugIO_systemjtag_mfr_id(io_debugIO_systemjtag_mfr_id),
    .io_debugIO_systemjtag_part_number(io_debugIO_systemjtag_part_number),
    .io_debugIO_systemjtag_version(io_debugIO_systemjtag_version),
    .io_debugIO_ndreset(g_io_debugIO_ndreset),
    .io_debugIO_dmactive(g_io_debugIO_dmactive),
    .io_debugIO_dmactiveAck(io_debugIO_dmactiveAck),
    .io_clock(clock),
    .io_reset(mrst)
  );

  DebugModule_xs u_i (
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_ready(auto_debug_dmInner_dmInner_sb2tlOpt_out_a_ready),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_valid(i_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_valid),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_opcode(i_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_opcode),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_size(i_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_size),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_address(i_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_address),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_mask(i_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_mask),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_data(i_auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_data),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_ready(i_auto_debug_dmInner_dmInner_sb2tlOpt_out_d_ready),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_valid(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_valid),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_opcode(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_opcode),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_param(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_param),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_size(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_size),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_sink(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_sink),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_denied(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_denied),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_data(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_data),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_corrupt(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_corrupt),
    .auto_debug_dmInner_dmInner_tl_in_a_ready(i_auto_debug_dmInner_dmInner_tl_in_a_ready),
    .auto_debug_dmInner_dmInner_tl_in_a_valid(auto_debug_dmInner_dmInner_tl_in_a_valid),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_opcode(auto_debug_dmInner_dmInner_tl_in_a_bits_opcode),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_size(auto_debug_dmInner_dmInner_tl_in_a_bits_size),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_source(auto_debug_dmInner_dmInner_tl_in_a_bits_source),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_address(auto_debug_dmInner_dmInner_tl_in_a_bits_address),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_mask(auto_debug_dmInner_dmInner_tl_in_a_bits_mask),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_data(auto_debug_dmInner_dmInner_tl_in_a_bits_data),
    .auto_debug_dmInner_dmInner_tl_in_d_ready(auto_debug_dmInner_dmInner_tl_in_d_ready),
    .auto_debug_dmInner_dmInner_tl_in_d_valid(i_auto_debug_dmInner_dmInner_tl_in_d_valid),
    .auto_debug_dmInner_dmInner_tl_in_d_bits_opcode(i_auto_debug_dmInner_dmInner_tl_in_d_bits_opcode),
    .auto_debug_dmInner_dmInner_tl_in_d_bits_size(i_auto_debug_dmInner_dmInner_tl_in_d_bits_size),
    .auto_debug_dmInner_dmInner_tl_in_d_bits_source(i_auto_debug_dmInner_dmInner_tl_in_d_bits_source),
    .auto_debug_dmInner_dmInner_tl_in_d_bits_data(i_auto_debug_dmInner_dmInner_tl_in_d_bits_data),
    .auto_debug_dmOuter_dmOuter_int_out_0(i_auto_debug_dmOuter_dmOuter_int_out_0),
    .io_resetCtrl_hartResetReq_0(i_io_resetCtrl_hartResetReq_0),
    .io_resetCtrl_hartIsInReset_0(io_resetCtrl_hartIsInReset_0),
    .io_debugIO_clock(clock),
    .io_debugIO_reset(drst),
    .io_debugIO_systemjtag_jtag_TCK(tck),
    .io_debugIO_systemjtag_jtag_TMS(io_debugIO_systemjtag_jtag_TMS),
    .io_debugIO_systemjtag_jtag_TDI(io_debugIO_systemjtag_jtag_TDI),
    .io_debugIO_systemjtag_jtag_TDO_data(i_io_debugIO_systemjtag_jtag_TDO_data),
    .io_debugIO_systemjtag_jtag_TDO_driven(i_io_debugIO_systemjtag_jtag_TDO_driven),
    .io_debugIO_systemjtag_reset(jrst),
    .io_debugIO_systemjtag_mfr_id(io_debugIO_systemjtag_mfr_id),
    .io_debugIO_systemjtag_part_number(io_debugIO_systemjtag_part_number),
    .io_debugIO_systemjtag_version(io_debugIO_systemjtag_version),
    .io_debugIO_ndreset(i_io_debugIO_ndreset),
    .io_debugIO_dmactive(i_io_debugIO_dmactive),
    .io_debugIO_dmactiveAck(io_debugIO_dmactiveAck),
    .io_clock(clock),
    .io_reset(mrst)
  );

  task automatic drive_main_inputs();
    auto_debug_dmInner_dmInner_sb2tlOpt_out_a_ready <= $urandom_range(0, 1);
    auto_debug_dmInner_dmInner_sb2tlOpt_out_d_valid <= $urandom_range(0, 1);
    auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_opcode <= 4'({$urandom});
    auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_param <= 2'({$urandom});
    auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_size <= 3'({$urandom});
    auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_sink <= $urandom_range(0, 1);
    auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_denied <= $urandom_range(0, 1);
    auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_data <= 64'({$urandom, $urandom});
    auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_corrupt <= $urandom_range(0, 1);
    auto_debug_dmInner_dmInner_tl_in_a_valid <= $urandom_range(0, 1);
    auto_debug_dmInner_dmInner_tl_in_a_bits_opcode <= 4'({$urandom});
    auto_debug_dmInner_dmInner_tl_in_a_bits_size <= 2'({$urandom});
    auto_debug_dmInner_dmInner_tl_in_a_bits_source <= 15'({$urandom});
    auto_debug_dmInner_dmInner_tl_in_a_bits_address <= 30'({$urandom});
    auto_debug_dmInner_dmInner_tl_in_a_bits_mask <= 8'({$urandom});
    auto_debug_dmInner_dmInner_tl_in_a_bits_data <= 64'({$urandom, $urandom});
    auto_debug_dmInner_dmInner_tl_in_d_ready <= $urandom_range(0, 1);
    io_resetCtrl_hartIsInReset_0 <= $urandom_range(0, 1);
    io_debugIO_dmactiveAck <= $urandom_range(0, 1);
  endtask

  task automatic drive_tck_inputs();
    io_debugIO_systemjtag_jtag_TMS <= $urandom_range(0, 1);
    io_debugIO_systemjtag_jtag_TDI <= $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(auto_debug_dmInner_dmInner_sb2tlOpt_out_a_valid)
    `CHECK(auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_opcode)
    `CHECK(auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_size)
    `CHECK(auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_address)
    `CHECK(auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_mask)
    `CHECK(auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_data)
    `CHECK(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_ready)
    `CHECK(auto_debug_dmInner_dmInner_tl_in_a_ready)
    `CHECK(auto_debug_dmInner_dmInner_tl_in_d_valid)
    `CHECK(auto_debug_dmInner_dmInner_tl_in_d_bits_opcode)
    `CHECK(auto_debug_dmInner_dmInner_tl_in_d_bits_size)
    `CHECK(auto_debug_dmInner_dmInner_tl_in_d_bits_source)
    `CHECK(auto_debug_dmInner_dmInner_tl_in_d_bits_data)
    `CHECK(auto_debug_dmOuter_dmOuter_int_out_0)
    `CHECK(io_resetCtrl_hartResetReq_0)
    `CHECK(io_debugIO_systemjtag_jtag_TDO_data)
    `CHECK(io_debugIO_systemjtag_jtag_TDO_driven)
    `CHECK(io_debugIO_ndreset)
    `CHECK(io_debugIO_dmactive)
  endtask

  always @(negedge tck) if (!jrst) drive_tck_inputs();

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    // IDCODE 常量
    io_debugIO_systemjtag_mfr_id = 11'h536;
    io_debugIO_systemjtag_part_number = 16'h1234;
    io_debugIO_systemjtag_version = 4'h1;
    // 全部输入清零, 三组复位拉高
    auto_debug_dmInner_dmInner_sb2tlOpt_out_a_ready = '0;
    auto_debug_dmInner_dmInner_sb2tlOpt_out_d_valid = '0;
    auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_opcode = '0;
    auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_param = '0;
    auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_size = '0;
    auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_sink = '0;
    auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_denied = '0;
    auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_data = '0;
    auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_corrupt = '0;
    auto_debug_dmInner_dmInner_tl_in_a_valid = '0;
    auto_debug_dmInner_dmInner_tl_in_a_bits_opcode = '0;
    auto_debug_dmInner_dmInner_tl_in_a_bits_size = '0;
    auto_debug_dmInner_dmInner_tl_in_a_bits_source = '0;
    auto_debug_dmInner_dmInner_tl_in_a_bits_address = '0;
    auto_debug_dmInner_dmInner_tl_in_a_bits_mask = '0;
    auto_debug_dmInner_dmInner_tl_in_a_bits_data = '0;
    auto_debug_dmInner_dmInner_tl_in_d_ready = '0;
    io_resetCtrl_hartIsInReset_0 = '0;
    io_debugIO_dmactiveAck = '0;
    io_debugIO_systemjtag_jtag_TMS = '0;
    io_debugIO_systemjtag_jtag_TDI = '0;
    mrst = 1'b1; drst = 1'b1; jrst = 1'b1;
    repeat (8) @(posedge clock);
    repeat (4) @(posedge tck);   // 让 TCK 域复位充分
    mrst = 1'b0; drst = 1'b0; jrst = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_main_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("DebugModule checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
