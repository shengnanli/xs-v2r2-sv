// 自动生成 xs-v2r2-sv/scripts/gen_sourceb.py —— 该脚本未移植到本轮(它按上一轮规范产出独立 _wrapper.sv)，本文件手工维护
// SourceB 双例化逐拍比对: golden SourceB vs 可读重写 SourceB_xs。
// 偏小 set/tag 域促成 grantStatus 同地址冲突, 覆盖 rdy 阻塞/解除路径。
`timescale 1ns/1ps
`define CHK(SIG) begin \
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
  bit clock = 0; bit reset; int errors = 0; int checks = 0;
  always #5 clock = ~clock;
  logic io_sourceB_ready;
  logic io_task_valid;
  logic [30:0] io_task_bits_tag;
  logic [8:0] io_task_bits_set;
  logic [2:0] io_task_bits_opcode;
  logic [1:0] io_task_bits_param;
  logic [1:0] io_task_bits_alias;
  logic io_grantStatus_0_valid;
  logic [8:0] io_grantStatus_0_set;
  logic [30:0] io_grantStatus_0_tag;
  logic io_grantStatus_1_valid;
  logic [8:0] io_grantStatus_1_set;
  logic [30:0] io_grantStatus_1_tag;
  logic io_grantStatus_2_valid;
  logic [8:0] io_grantStatus_2_set;
  logic [30:0] io_grantStatus_2_tag;
  logic io_grantStatus_3_valid;
  logic [8:0] io_grantStatus_3_set;
  logic [30:0] io_grantStatus_3_tag;
  logic io_grantStatus_4_valid;
  logic [8:0] io_grantStatus_4_set;
  logic [30:0] io_grantStatus_4_tag;
  logic io_grantStatus_5_valid;
  logic [8:0] io_grantStatus_5_set;
  logic [30:0] io_grantStatus_5_tag;
  logic io_grantStatus_6_valid;
  logic [8:0] io_grantStatus_6_set;
  logic [30:0] io_grantStatus_6_tag;
  logic io_grantStatus_7_valid;
  logic [8:0] io_grantStatus_7_set;
  logic [30:0] io_grantStatus_7_tag;
  logic io_grantStatus_8_valid;
  logic [8:0] io_grantStatus_8_set;
  logic [30:0] io_grantStatus_8_tag;
  logic io_grantStatus_9_valid;
  logic [8:0] io_grantStatus_9_set;
  logic [30:0] io_grantStatus_9_tag;
  logic io_grantStatus_10_valid;
  logic [8:0] io_grantStatus_10_set;
  logic [30:0] io_grantStatus_10_tag;
  logic io_grantStatus_11_valid;
  logic [8:0] io_grantStatus_11_set;
  logic [30:0] io_grantStatus_11_tag;
  logic io_grantStatus_12_valid;
  logic [8:0] io_grantStatus_12_set;
  logic [30:0] io_grantStatus_12_tag;
  logic io_grantStatus_13_valid;
  logic [8:0] io_grantStatus_13_set;
  logic [30:0] io_grantStatus_13_tag;
  logic io_grantStatus_14_valid;
  logic [8:0] io_grantStatus_14_set;
  logic [30:0] io_grantStatus_14_tag;
  logic io_grantStatus_15_valid;
  logic [8:0] io_grantStatus_15_set;
  logic [30:0] io_grantStatus_15_tag;
  wire g_io_sourceB_valid;
  wire i_io_sourceB_valid;
  wire [2:0] g_io_sourceB_bits_opcode;
  wire [2:0] i_io_sourceB_bits_opcode;
  wire [1:0] g_io_sourceB_bits_param;
  wire [1:0] i_io_sourceB_bits_param;
  wire [47:0] g_io_sourceB_bits_address;
  wire [47:0] i_io_sourceB_bits_address;
  wire [255:0] g_io_sourceB_bits_data;
  wire [255:0] i_io_sourceB_bits_data;
  wire g_io_task_ready;
  wire i_io_task_ready;


  // ---- 覆盖闸（防假绿）----------------------------------------------
  // errors=0 本身不是证据：激励若让 DUT 根本不动（握手永远握不上、状态机卡死），
  // 纯比对 tb 会给出一个漂亮的 0。所以另外统计"观测信号翻转过几个"与"握手成功
  // 几拍"，低于门限判 FAIL。门限取自标定跑（真实数字打折），不是自我实现。
  localparam int unsigned MIN_TOGGLED = 6;
  localparam int unsigned MIN_FIRES   = 50000;
  localparam int unsigned N_OBS       = 6;
  int     cov_toggled = 0;
  longint cov_fires = 0;
  logic p_g_io_sourceB_valid;
  bit tog_g_io_sourceB_valid;
  logic [2:0] p_g_io_sourceB_bits_opcode;
  bit tog_g_io_sourceB_bits_opcode;
  logic [1:0] p_g_io_sourceB_bits_param;
  bit tog_g_io_sourceB_bits_param;
  logic [47:0] p_g_io_sourceB_bits_address;
  bit tog_g_io_sourceB_bits_address;
  logic [255:0] p_g_io_sourceB_bits_data;
  bit tog_g_io_sourceB_bits_data;
  logic p_g_io_task_ready;
  bit tog_g_io_task_ready;
  task automatic sample_cov();
    if (g_io_sourceB_valid !== p_g_io_sourceB_valid) tog_g_io_sourceB_valid = 1'b1;
    p_g_io_sourceB_valid = g_io_sourceB_valid;
    if (g_io_sourceB_bits_opcode !== p_g_io_sourceB_bits_opcode) tog_g_io_sourceB_bits_opcode = 1'b1;
    p_g_io_sourceB_bits_opcode = g_io_sourceB_bits_opcode;
    if (g_io_sourceB_bits_param !== p_g_io_sourceB_bits_param) tog_g_io_sourceB_bits_param = 1'b1;
    p_g_io_sourceB_bits_param = g_io_sourceB_bits_param;
    if (g_io_sourceB_bits_address !== p_g_io_sourceB_bits_address) tog_g_io_sourceB_bits_address = 1'b1;
    p_g_io_sourceB_bits_address = g_io_sourceB_bits_address;
    if (g_io_sourceB_bits_data !== p_g_io_sourceB_bits_data) tog_g_io_sourceB_bits_data = 1'b1;
    p_g_io_sourceB_bits_data = g_io_sourceB_bits_data;
    if (g_io_task_ready !== p_g_io_task_ready) tog_g_io_task_ready = 1'b1;
    p_g_io_task_ready = g_io_task_ready;
    if ((io_task_valid && g_io_task_ready) || (io_sourceB_ready && g_io_sourceB_valid)) cov_fires++;
  endtask
  task automatic cov_report_and_gate();
    if (tog_g_io_sourceB_valid) cov_toggled++; else $display("COV: g_io_sourceB_valid never toggled");
    if (tog_g_io_sourceB_bits_opcode) cov_toggled++; else $display("COV: g_io_sourceB_bits_opcode never toggled");
    if (tog_g_io_sourceB_bits_param) cov_toggled++; else $display("COV: g_io_sourceB_bits_param never toggled");
    if (tog_g_io_sourceB_bits_address) cov_toggled++; else $display("COV: g_io_sourceB_bits_address never toggled");
    if (tog_g_io_sourceB_bits_data) cov_toggled++; else $display("COV: g_io_sourceB_bits_data never toggled");
    if (tog_g_io_task_ready) cov_toggled++; else $display("COV: g_io_task_ready never toggled");
    $display("COV SourceB: toggled=%0d/%0d fires=%0d", cov_toggled, N_OBS, cov_fires);
    if (cov_toggled < MIN_TOGGLED) begin
      $display("TEST FAILED (coverage: only %0d observed signals toggled, need >= %0d)", cov_toggled, MIN_TOGGLED); $fatal(1);
    end
    if (cov_fires < MIN_FIRES) begin
      $display("TEST FAILED (coverage: only %0d handshake fires, need >= %0d)", cov_fires, MIN_FIRES); $fatal(1);
    end
  endtask
  SourceB u_g (
    .clock(clock),
    .reset(reset),
    .io_sourceB_ready(io_sourceB_ready),
    .io_sourceB_valid(g_io_sourceB_valid),
    .io_sourceB_bits_opcode(g_io_sourceB_bits_opcode),
    .io_sourceB_bits_param(g_io_sourceB_bits_param),
    .io_sourceB_bits_address(g_io_sourceB_bits_address),
    .io_sourceB_bits_data(g_io_sourceB_bits_data),
    .io_task_ready(g_io_task_ready),
    .io_task_valid(io_task_valid),
    .io_task_bits_tag(io_task_bits_tag),
    .io_task_bits_set(io_task_bits_set),
    .io_task_bits_opcode(io_task_bits_opcode),
    .io_task_bits_param(io_task_bits_param),
    .io_task_bits_alias(io_task_bits_alias),
    .io_grantStatus_0_valid(io_grantStatus_0_valid),
    .io_grantStatus_0_set(io_grantStatus_0_set),
    .io_grantStatus_0_tag(io_grantStatus_0_tag),
    .io_grantStatus_1_valid(io_grantStatus_1_valid),
    .io_grantStatus_1_set(io_grantStatus_1_set),
    .io_grantStatus_1_tag(io_grantStatus_1_tag),
    .io_grantStatus_2_valid(io_grantStatus_2_valid),
    .io_grantStatus_2_set(io_grantStatus_2_set),
    .io_grantStatus_2_tag(io_grantStatus_2_tag),
    .io_grantStatus_3_valid(io_grantStatus_3_valid),
    .io_grantStatus_3_set(io_grantStatus_3_set),
    .io_grantStatus_3_tag(io_grantStatus_3_tag),
    .io_grantStatus_4_valid(io_grantStatus_4_valid),
    .io_grantStatus_4_set(io_grantStatus_4_set),
    .io_grantStatus_4_tag(io_grantStatus_4_tag),
    .io_grantStatus_5_valid(io_grantStatus_5_valid),
    .io_grantStatus_5_set(io_grantStatus_5_set),
    .io_grantStatus_5_tag(io_grantStatus_5_tag),
    .io_grantStatus_6_valid(io_grantStatus_6_valid),
    .io_grantStatus_6_set(io_grantStatus_6_set),
    .io_grantStatus_6_tag(io_grantStatus_6_tag),
    .io_grantStatus_7_valid(io_grantStatus_7_valid),
    .io_grantStatus_7_set(io_grantStatus_7_set),
    .io_grantStatus_7_tag(io_grantStatus_7_tag),
    .io_grantStatus_8_valid(io_grantStatus_8_valid),
    .io_grantStatus_8_set(io_grantStatus_8_set),
    .io_grantStatus_8_tag(io_grantStatus_8_tag),
    .io_grantStatus_9_valid(io_grantStatus_9_valid),
    .io_grantStatus_9_set(io_grantStatus_9_set),
    .io_grantStatus_9_tag(io_grantStatus_9_tag),
    .io_grantStatus_10_valid(io_grantStatus_10_valid),
    .io_grantStatus_10_set(io_grantStatus_10_set),
    .io_grantStatus_10_tag(io_grantStatus_10_tag),
    .io_grantStatus_11_valid(io_grantStatus_11_valid),
    .io_grantStatus_11_set(io_grantStatus_11_set),
    .io_grantStatus_11_tag(io_grantStatus_11_tag),
    .io_grantStatus_12_valid(io_grantStatus_12_valid),
    .io_grantStatus_12_set(io_grantStatus_12_set),
    .io_grantStatus_12_tag(io_grantStatus_12_tag),
    .io_grantStatus_13_valid(io_grantStatus_13_valid),
    .io_grantStatus_13_set(io_grantStatus_13_set),
    .io_grantStatus_13_tag(io_grantStatus_13_tag),
    .io_grantStatus_14_valid(io_grantStatus_14_valid),
    .io_grantStatus_14_set(io_grantStatus_14_set),
    .io_grantStatus_14_tag(io_grantStatus_14_tag),
    .io_grantStatus_15_valid(io_grantStatus_15_valid),
    .io_grantStatus_15_set(io_grantStatus_15_set),
    .io_grantStatus_15_tag(io_grantStatus_15_tag)
  );
  SourceB_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_sourceB_ready(io_sourceB_ready),
    .io_sourceB_valid(i_io_sourceB_valid),
    .io_sourceB_bits_opcode(i_io_sourceB_bits_opcode),
    .io_sourceB_bits_param(i_io_sourceB_bits_param),
    .io_sourceB_bits_address(i_io_sourceB_bits_address),
    .io_sourceB_bits_data(i_io_sourceB_bits_data),
    .io_task_ready(i_io_task_ready),
    .io_task_valid(io_task_valid),
    .io_task_bits_tag(io_task_bits_tag),
    .io_task_bits_set(io_task_bits_set),
    .io_task_bits_opcode(io_task_bits_opcode),
    .io_task_bits_param(io_task_bits_param),
    .io_task_bits_alias(io_task_bits_alias),
    .io_grantStatus_0_valid(io_grantStatus_0_valid),
    .io_grantStatus_0_set(io_grantStatus_0_set),
    .io_grantStatus_0_tag(io_grantStatus_0_tag),
    .io_grantStatus_1_valid(io_grantStatus_1_valid),
    .io_grantStatus_1_set(io_grantStatus_1_set),
    .io_grantStatus_1_tag(io_grantStatus_1_tag),
    .io_grantStatus_2_valid(io_grantStatus_2_valid),
    .io_grantStatus_2_set(io_grantStatus_2_set),
    .io_grantStatus_2_tag(io_grantStatus_2_tag),
    .io_grantStatus_3_valid(io_grantStatus_3_valid),
    .io_grantStatus_3_set(io_grantStatus_3_set),
    .io_grantStatus_3_tag(io_grantStatus_3_tag),
    .io_grantStatus_4_valid(io_grantStatus_4_valid),
    .io_grantStatus_4_set(io_grantStatus_4_set),
    .io_grantStatus_4_tag(io_grantStatus_4_tag),
    .io_grantStatus_5_valid(io_grantStatus_5_valid),
    .io_grantStatus_5_set(io_grantStatus_5_set),
    .io_grantStatus_5_tag(io_grantStatus_5_tag),
    .io_grantStatus_6_valid(io_grantStatus_6_valid),
    .io_grantStatus_6_set(io_grantStatus_6_set),
    .io_grantStatus_6_tag(io_grantStatus_6_tag),
    .io_grantStatus_7_valid(io_grantStatus_7_valid),
    .io_grantStatus_7_set(io_grantStatus_7_set),
    .io_grantStatus_7_tag(io_grantStatus_7_tag),
    .io_grantStatus_8_valid(io_grantStatus_8_valid),
    .io_grantStatus_8_set(io_grantStatus_8_set),
    .io_grantStatus_8_tag(io_grantStatus_8_tag),
    .io_grantStatus_9_valid(io_grantStatus_9_valid),
    .io_grantStatus_9_set(io_grantStatus_9_set),
    .io_grantStatus_9_tag(io_grantStatus_9_tag),
    .io_grantStatus_10_valid(io_grantStatus_10_valid),
    .io_grantStatus_10_set(io_grantStatus_10_set),
    .io_grantStatus_10_tag(io_grantStatus_10_tag),
    .io_grantStatus_11_valid(io_grantStatus_11_valid),
    .io_grantStatus_11_set(io_grantStatus_11_set),
    .io_grantStatus_11_tag(io_grantStatus_11_tag),
    .io_grantStatus_12_valid(io_grantStatus_12_valid),
    .io_grantStatus_12_set(io_grantStatus_12_set),
    .io_grantStatus_12_tag(io_grantStatus_12_tag),
    .io_grantStatus_13_valid(io_grantStatus_13_valid),
    .io_grantStatus_13_set(io_grantStatus_13_set),
    .io_grantStatus_13_tag(io_grantStatus_13_tag),
    .io_grantStatus_14_valid(io_grantStatus_14_valid),
    .io_grantStatus_14_set(io_grantStatus_14_set),
    .io_grantStatus_14_tag(io_grantStatus_14_tag),
    .io_grantStatus_15_valid(io_grantStatus_15_valid),
    .io_grantStatus_15_set(io_grantStatus_15_set),
    .io_grantStatus_15_tag(io_grantStatus_15_tag)
  );

  task automatic drive_random();
    io_sourceB_ready = ($urandom_range(0,2) != 0);
    io_task_valid = ($urandom_range(0,1) == 0);
    io_task_bits_tag = $urandom_range(0,3);
    io_task_bits_set = $urandom_range(0,3);
    io_task_bits_opcode = $urandom;
    io_task_bits_param = $urandom;
    io_task_bits_alias = $urandom;
    io_grantStatus_0_valid = ($urandom_range(0,1) == 0);
    io_grantStatus_0_set = $urandom_range(0,3);
    io_grantStatus_0_tag = $urandom_range(0,3);
    io_grantStatus_1_valid = ($urandom_range(0,1) == 0);
    io_grantStatus_1_set = $urandom_range(0,3);
    io_grantStatus_1_tag = $urandom_range(0,3);
    io_grantStatus_2_valid = ($urandom_range(0,1) == 0);
    io_grantStatus_2_set = $urandom_range(0,3);
    io_grantStatus_2_tag = $urandom_range(0,3);
    io_grantStatus_3_valid = ($urandom_range(0,1) == 0);
    io_grantStatus_3_set = $urandom_range(0,3);
    io_grantStatus_3_tag = $urandom_range(0,3);
    io_grantStatus_4_valid = ($urandom_range(0,1) == 0);
    io_grantStatus_4_set = $urandom_range(0,3);
    io_grantStatus_4_tag = $urandom_range(0,3);
    io_grantStatus_5_valid = ($urandom_range(0,1) == 0);
    io_grantStatus_5_set = $urandom_range(0,3);
    io_grantStatus_5_tag = $urandom_range(0,3);
    io_grantStatus_6_valid = ($urandom_range(0,1) == 0);
    io_grantStatus_6_set = $urandom_range(0,3);
    io_grantStatus_6_tag = $urandom_range(0,3);
    io_grantStatus_7_valid = ($urandom_range(0,1) == 0);
    io_grantStatus_7_set = $urandom_range(0,3);
    io_grantStatus_7_tag = $urandom_range(0,3);
    io_grantStatus_8_valid = ($urandom_range(0,1) == 0);
    io_grantStatus_8_set = $urandom_range(0,3);
    io_grantStatus_8_tag = $urandom_range(0,3);
    io_grantStatus_9_valid = ($urandom_range(0,1) == 0);
    io_grantStatus_9_set = $urandom_range(0,3);
    io_grantStatus_9_tag = $urandom_range(0,3);
    io_grantStatus_10_valid = ($urandom_range(0,1) == 0);
    io_grantStatus_10_set = $urandom_range(0,3);
    io_grantStatus_10_tag = $urandom_range(0,3);
    io_grantStatus_11_valid = ($urandom_range(0,1) == 0);
    io_grantStatus_11_set = $urandom_range(0,3);
    io_grantStatus_11_tag = $urandom_range(0,3);
    io_grantStatus_12_valid = ($urandom_range(0,1) == 0);
    io_grantStatus_12_set = $urandom_range(0,3);
    io_grantStatus_12_tag = $urandom_range(0,3);
    io_grantStatus_13_valid = ($urandom_range(0,1) == 0);
    io_grantStatus_13_set = $urandom_range(0,3);
    io_grantStatus_13_tag = $urandom_range(0,3);
    io_grantStatus_14_valid = ($urandom_range(0,1) == 0);
    io_grantStatus_14_set = $urandom_range(0,3);
    io_grantStatus_14_tag = $urandom_range(0,3);
    io_grantStatus_15_valid = ($urandom_range(0,1) == 0);
    io_grantStatus_15_set = $urandom_range(0,3);
    io_grantStatus_15_tag = $urandom_range(0,3);
  endtask

  task automatic check_outputs();
    `CHK(io_sourceB_valid)
    `CHK(io_sourceB_bits_opcode)
    `CHK(io_sourceB_bits_param)
    `CHK(io_sourceB_bits_address)
    `CHK(io_sourceB_bits_data)
    `CHK(io_task_ready)
  endtask

  int ierr = 0;
  `define IP(GP, IP) begin \
    if (!$isunknown(u_g.GP)) begin \
      if (u_g.GP !== u_i.u_core.IP) begin \
        ierr++; \
        if (ierr <= 40) $display("[%0t] IPROBE-DIFF g=%0h i=%0h", $time, u_g.GP, u_i.u_core.IP); \
      end \
    end \
  end
  task automatic check_internal();
    `IP(probes_0_valid,  probes_valid[0])
    `IP(probes_0_rdy,    probes_rdy[0])
    `IP(probes_0_waitG,  probes_waitG[0])
    `IP(probes_0_task_tag,    probes_tag[0])
    `IP(probes_0_task_set,    probes_set[0])
    `IP(probes_0_task_opcode, probes_opcode[0])
    `IP(probes_0_task_param,  probes_param[0])
    `IP(probes_0_task_alias,  probes_alias[0])
    `IP(probes_1_valid,  probes_valid[1])
    `IP(probes_1_rdy,    probes_rdy[1])
    `IP(probes_1_waitG,  probes_waitG[1])
    `IP(probes_1_task_tag,    probes_tag[1])
    `IP(probes_1_task_set,    probes_set[1])
    `IP(probes_1_task_opcode, probes_opcode[1])
    `IP(probes_1_task_param,  probes_param[1])
    `IP(probes_1_task_alias,  probes_alias[1])
    `IP(probes_2_valid,  probes_valid[2])
    `IP(probes_2_rdy,    probes_rdy[2])
    `IP(probes_2_waitG,  probes_waitG[2])
    `IP(probes_2_task_tag,    probes_tag[2])
    `IP(probes_2_task_set,    probes_set[2])
    `IP(probes_2_task_opcode, probes_opcode[2])
    `IP(probes_2_task_param,  probes_param[2])
    `IP(probes_2_task_alias,  probes_alias[2])
    `IP(probes_3_valid,  probes_valid[3])
    `IP(probes_3_rdy,    probes_rdy[3])
    `IP(probes_3_waitG,  probes_waitG[3])
    `IP(probes_3_task_tag,    probes_tag[3])
    `IP(probes_3_task_set,    probes_set[3])
    `IP(probes_3_task_opcode, probes_opcode[3])
    `IP(probes_3_task_param,  probes_param[3])
    `IP(probes_3_task_alias,  probes_alias[3])
  endtask

  initial begin
    // 全工程统一拍数开关（ut_common.mk 下发 +ncycles=<n>）
    void'($value$plusargs("ncycles=%d", NCYCLES));
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_sourceB_ready = '0;
    io_task_valid = '0;
    io_task_bits_tag = '0;
    io_task_bits_set = '0;
    io_task_bits_opcode = '0;
    io_task_bits_param = '0;
    io_task_bits_alias = '0;
    io_grantStatus_0_valid = '0;
    io_grantStatus_0_set = '0;
    io_grantStatus_0_tag = '0;
    io_grantStatus_1_valid = '0;
    io_grantStatus_1_set = '0;
    io_grantStatus_1_tag = '0;
    io_grantStatus_2_valid = '0;
    io_grantStatus_2_set = '0;
    io_grantStatus_2_tag = '0;
    io_grantStatus_3_valid = '0;
    io_grantStatus_3_set = '0;
    io_grantStatus_3_tag = '0;
    io_grantStatus_4_valid = '0;
    io_grantStatus_4_set = '0;
    io_grantStatus_4_tag = '0;
    io_grantStatus_5_valid = '0;
    io_grantStatus_5_set = '0;
    io_grantStatus_5_tag = '0;
    io_grantStatus_6_valid = '0;
    io_grantStatus_6_set = '0;
    io_grantStatus_6_tag = '0;
    io_grantStatus_7_valid = '0;
    io_grantStatus_7_set = '0;
    io_grantStatus_7_tag = '0;
    io_grantStatus_8_valid = '0;
    io_grantStatus_8_set = '0;
    io_grantStatus_8_tag = '0;
    io_grantStatus_9_valid = '0;
    io_grantStatus_9_set = '0;
    io_grantStatus_9_tag = '0;
    io_grantStatus_10_valid = '0;
    io_grantStatus_10_set = '0;
    io_grantStatus_10_tag = '0;
    io_grantStatus_11_valid = '0;
    io_grantStatus_11_set = '0;
    io_grantStatus_11_tag = '0;
    io_grantStatus_12_valid = '0;
    io_grantStatus_12_set = '0;
    io_grantStatus_12_tag = '0;
    io_grantStatus_13_valid = '0;
    io_grantStatus_13_set = '0;
    io_grantStatus_13_tag = '0;
    io_grantStatus_14_valid = '0;
    io_grantStatus_14_set = '0;
    io_grantStatus_14_tag = '0;
    io_grantStatus_15_valid = '0;
    io_grantStatus_15_set = '0;
    io_grantStatus_15_tag = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      check_internal();
      sample_cov();
      @(posedge clock);
    end
    cov_report_and_gate();
    $display("SourceB checks=%0d errors=%0d ierr=%0d", checks, errors, ierr);
    if (errors == 0 && ierr == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
