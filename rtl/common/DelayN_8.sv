// =============================================================================
// DelayN_8 —— 固定级数的载荷打拍链（xs_DelayN_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   延迟级数 STAGES = 2；载荷宽度 = 274 位，分 43 个字段；
//   golden 模块体 = 548 个 reg 位（2 级 × 274 位），无复位 / 无使能 / 无子模块；
//   端口 87 个 = clock + 43 个 io_in_* + 43 个 io_out_*。
//   载荷字段：pf_ctrl_l1I_pf_enable=1b, bp_ctrl_ubtb_enable=1b, bp_ctrl_btb_enable=1b, bp_ctrl_tage_enable=1b, bp_ctrl_sc_enable=1b …共 43 个字段，明细见端口表。
//   使用者：Frontend / MemBlock —— 自定义 CSR 分发包（含 trigger）打两拍。
//
// 结构：golden 同名端口表 -> 打包成一根 274 位扁平载荷 -> 设参例化
//   xs_DelayN_core（核体见 xs_DelayN_core.sv，打拍语义与不变式都在那里讲）
//   -> 拆包回 golden 的 io_out_* 端口。本层只做拼包/拆包。
//   PORT_BITS_IN/OUT 用 $bits(golden 端口拼接) 算出来传给核：任何一个端口的位宽
//   抄错，拼接总位数就变，time 0 直接 $fatal（本轮已发生 3 次位宽静默错事故）。
// 自动生成：verif/ut/DelayN/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayN_8(
  input         clock,
  input         io_in_pf_ctrl_l1I_pf_enable,
  input         io_in_bp_ctrl_ubtb_enable,
  input         io_in_bp_ctrl_btb_enable,
  input         io_in_bp_ctrl_tage_enable,
  input         io_in_bp_ctrl_sc_enable,
  input         io_in_bp_ctrl_ras_enable,
  input  [21:0] io_in_sbuffer_timeout,
  input         io_in_ldld_vio_check_enable,
  input         io_in_cache_error_enable,
  input         io_in_hd_misalign_st_enable,
  input         io_in_hd_misalign_ld_enable,
  input         io_in_distribute_csr_w_valid,
  input  [11:0] io_in_distribute_csr_w_bits_addr,
  input  [63:0] io_in_distribute_csr_w_bits_data,
  input         io_in_frontend_trigger_tUpdate_valid,
  input  [1:0]  io_in_frontend_trigger_tUpdate_bits_addr,
  input  [1:0]  io_in_frontend_trigger_tUpdate_bits_tdata_matchType,
  input         io_in_frontend_trigger_tUpdate_bits_tdata_select,
  input  [3:0]  io_in_frontend_trigger_tUpdate_bits_tdata_action,
  input         io_in_frontend_trigger_tUpdate_bits_tdata_chain,
  input  [63:0] io_in_frontend_trigger_tUpdate_bits_tdata_tdata2,
  input         io_in_frontend_trigger_tEnableVec_0,
  input         io_in_frontend_trigger_tEnableVec_1,
  input         io_in_frontend_trigger_tEnableVec_2,
  input         io_in_frontend_trigger_tEnableVec_3,
  input         io_in_frontend_trigger_debugMode,
  input         io_in_frontend_trigger_triggerCanRaiseBpExp,
  input         io_in_mem_trigger_tUpdate_valid,
  input  [1:0]  io_in_mem_trigger_tUpdate_bits_addr,
  input  [1:0]  io_in_mem_trigger_tUpdate_bits_tdata_matchType,
  input         io_in_mem_trigger_tUpdate_bits_tdata_select,
  input  [3:0]  io_in_mem_trigger_tUpdate_bits_tdata_action,
  input         io_in_mem_trigger_tUpdate_bits_tdata_chain,
  input         io_in_mem_trigger_tUpdate_bits_tdata_store,
  input         io_in_mem_trigger_tUpdate_bits_tdata_load,
  input  [63:0] io_in_mem_trigger_tUpdate_bits_tdata_tdata2,
  input         io_in_mem_trigger_tEnableVec_0,
  input         io_in_mem_trigger_tEnableVec_1,
  input         io_in_mem_trigger_tEnableVec_2,
  input         io_in_mem_trigger_tEnableVec_3,
  input         io_in_mem_trigger_debugMode,
  input         io_in_mem_trigger_triggerCanRaiseBpExp,
  input         io_in_fsIsOff,
  output        io_out_pf_ctrl_l1I_pf_enable,
  output        io_out_bp_ctrl_ubtb_enable,
  output        io_out_bp_ctrl_btb_enable,
  output        io_out_bp_ctrl_tage_enable,
  output        io_out_bp_ctrl_sc_enable,
  output        io_out_bp_ctrl_ras_enable,
  output [21:0] io_out_sbuffer_timeout,
  output        io_out_ldld_vio_check_enable,
  output        io_out_cache_error_enable,
  output        io_out_hd_misalign_st_enable,
  output        io_out_hd_misalign_ld_enable,
  output        io_out_distribute_csr_w_valid,
  output [11:0] io_out_distribute_csr_w_bits_addr,
  output [63:0] io_out_distribute_csr_w_bits_data,
  output        io_out_frontend_trigger_tUpdate_valid,
  output [1:0]  io_out_frontend_trigger_tUpdate_bits_addr,
  output [1:0]  io_out_frontend_trigger_tUpdate_bits_tdata_matchType,
  output        io_out_frontend_trigger_tUpdate_bits_tdata_select,
  output [3:0]  io_out_frontend_trigger_tUpdate_bits_tdata_action,
  output        io_out_frontend_trigger_tUpdate_bits_tdata_chain,
  output [63:0] io_out_frontend_trigger_tUpdate_bits_tdata_tdata2,
  output        io_out_frontend_trigger_tEnableVec_0,
  output        io_out_frontend_trigger_tEnableVec_1,
  output        io_out_frontend_trigger_tEnableVec_2,
  output        io_out_frontend_trigger_tEnableVec_3,
  output        io_out_frontend_trigger_debugMode,
  output        io_out_frontend_trigger_triggerCanRaiseBpExp,
  output        io_out_mem_trigger_tUpdate_valid,
  output [1:0]  io_out_mem_trigger_tUpdate_bits_addr,
  output [1:0]  io_out_mem_trigger_tUpdate_bits_tdata_matchType,
  output        io_out_mem_trigger_tUpdate_bits_tdata_select,
  output [3:0]  io_out_mem_trigger_tUpdate_bits_tdata_action,
  output        io_out_mem_trigger_tUpdate_bits_tdata_chain,
  output        io_out_mem_trigger_tUpdate_bits_tdata_store,
  output        io_out_mem_trigger_tUpdate_bits_tdata_load,
  output [63:0] io_out_mem_trigger_tUpdate_bits_tdata_tdata2,
  output        io_out_mem_trigger_tEnableVec_0,
  output        io_out_mem_trigger_tEnableVec_1,
  output        io_out_mem_trigger_tEnableVec_2,
  output        io_out_mem_trigger_tEnableVec_3,
  output        io_out_mem_trigger_debugMode,
  output        io_out_mem_trigger_triggerCanRaiseBpExp,
  output        io_out_fsIsOff
);

  localparam int unsigned STAGES          = 2;
  localparam int unsigned GOLDEN_REG_BITS = 548;   // golden 里 reg 位数总和
  localparam int unsigned PAYLOAD_W       = GOLDEN_REG_BITS / STAGES;

  // 端口表事实：golden 全部输入 / 输出端口拼起来各有多少位（$bits 只认端口声明）
  localparam int unsigned PORT_BITS_IN = $bits(
    {io_in_pf_ctrl_l1I_pf_enable, io_in_bp_ctrl_ubtb_enable, io_in_bp_ctrl_btb_enable,
     io_in_bp_ctrl_tage_enable, io_in_bp_ctrl_sc_enable, io_in_bp_ctrl_ras_enable,
     io_in_sbuffer_timeout, io_in_ldld_vio_check_enable, io_in_cache_error_enable,
     io_in_hd_misalign_st_enable, io_in_hd_misalign_ld_enable,
     io_in_distribute_csr_w_valid, io_in_distribute_csr_w_bits_addr,
     io_in_distribute_csr_w_bits_data, io_in_frontend_trigger_tUpdate_valid,
     io_in_frontend_trigger_tUpdate_bits_addr,
     io_in_frontend_trigger_tUpdate_bits_tdata_matchType,
     io_in_frontend_trigger_tUpdate_bits_tdata_select,
     io_in_frontend_trigger_tUpdate_bits_tdata_action,
     io_in_frontend_trigger_tUpdate_bits_tdata_chain,
     io_in_frontend_trigger_tUpdate_bits_tdata_tdata2,
     io_in_frontend_trigger_tEnableVec_0, io_in_frontend_trigger_tEnableVec_1,
     io_in_frontend_trigger_tEnableVec_2, io_in_frontend_trigger_tEnableVec_3,
     io_in_frontend_trigger_debugMode, io_in_frontend_trigger_triggerCanRaiseBpExp,
     io_in_mem_trigger_tUpdate_valid, io_in_mem_trigger_tUpdate_bits_addr,
     io_in_mem_trigger_tUpdate_bits_tdata_matchType,
     io_in_mem_trigger_tUpdate_bits_tdata_select,
     io_in_mem_trigger_tUpdate_bits_tdata_action,
     io_in_mem_trigger_tUpdate_bits_tdata_chain,
     io_in_mem_trigger_tUpdate_bits_tdata_store,
     io_in_mem_trigger_tUpdate_bits_tdata_load,
     io_in_mem_trigger_tUpdate_bits_tdata_tdata2, io_in_mem_trigger_tEnableVec_0,
     io_in_mem_trigger_tEnableVec_1, io_in_mem_trigger_tEnableVec_2,
     io_in_mem_trigger_tEnableVec_3, io_in_mem_trigger_debugMode,
     io_in_mem_trigger_triggerCanRaiseBpExp, io_in_fsIsOff});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {io_out_pf_ctrl_l1I_pf_enable, io_out_bp_ctrl_ubtb_enable, io_out_bp_ctrl_btb_enable,
     io_out_bp_ctrl_tage_enable, io_out_bp_ctrl_sc_enable, io_out_bp_ctrl_ras_enable,
     io_out_sbuffer_timeout, io_out_ldld_vio_check_enable, io_out_cache_error_enable,
     io_out_hd_misalign_st_enable, io_out_hd_misalign_ld_enable,
     io_out_distribute_csr_w_valid, io_out_distribute_csr_w_bits_addr,
     io_out_distribute_csr_w_bits_data, io_out_frontend_trigger_tUpdate_valid,
     io_out_frontend_trigger_tUpdate_bits_addr,
     io_out_frontend_trigger_tUpdate_bits_tdata_matchType,
     io_out_frontend_trigger_tUpdate_bits_tdata_select,
     io_out_frontend_trigger_tUpdate_bits_tdata_action,
     io_out_frontend_trigger_tUpdate_bits_tdata_chain,
     io_out_frontend_trigger_tUpdate_bits_tdata_tdata2,
     io_out_frontend_trigger_tEnableVec_0, io_out_frontend_trigger_tEnableVec_1,
     io_out_frontend_trigger_tEnableVec_2, io_out_frontend_trigger_tEnableVec_3,
     io_out_frontend_trigger_debugMode, io_out_frontend_trigger_triggerCanRaiseBpExp,
     io_out_mem_trigger_tUpdate_valid, io_out_mem_trigger_tUpdate_bits_addr,
     io_out_mem_trigger_tUpdate_bits_tdata_matchType,
     io_out_mem_trigger_tUpdate_bits_tdata_select,
     io_out_mem_trigger_tUpdate_bits_tdata_action,
     io_out_mem_trigger_tUpdate_bits_tdata_chain,
     io_out_mem_trigger_tUpdate_bits_tdata_store,
     io_out_mem_trigger_tUpdate_bits_tdata_load,
     io_out_mem_trigger_tUpdate_bits_tdata_tdata2, io_out_mem_trigger_tEnableVec_0,
     io_out_mem_trigger_tEnableVec_1, io_out_mem_trigger_tEnableVec_2,
     io_out_mem_trigger_tEnableVec_3, io_out_mem_trigger_debugMode,
     io_out_mem_trigger_triggerCanRaiseBpExp, io_out_fsIsOff});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
    {io_in_pf_ctrl_l1I_pf_enable, io_in_bp_ctrl_ubtb_enable, io_in_bp_ctrl_btb_enable,
     io_in_bp_ctrl_tage_enable, io_in_bp_ctrl_sc_enable, io_in_bp_ctrl_ras_enable,
     io_in_sbuffer_timeout, io_in_ldld_vio_check_enable, io_in_cache_error_enable,
     io_in_hd_misalign_st_enable, io_in_hd_misalign_ld_enable,
     io_in_distribute_csr_w_valid, io_in_distribute_csr_w_bits_addr,
     io_in_distribute_csr_w_bits_data, io_in_frontend_trigger_tUpdate_valid,
     io_in_frontend_trigger_tUpdate_bits_addr,
     io_in_frontend_trigger_tUpdate_bits_tdata_matchType,
     io_in_frontend_trigger_tUpdate_bits_tdata_select,
     io_in_frontend_trigger_tUpdate_bits_tdata_action,
     io_in_frontend_trigger_tUpdate_bits_tdata_chain,
     io_in_frontend_trigger_tUpdate_bits_tdata_tdata2,
     io_in_frontend_trigger_tEnableVec_0, io_in_frontend_trigger_tEnableVec_1,
     io_in_frontend_trigger_tEnableVec_2, io_in_frontend_trigger_tEnableVec_3,
     io_in_frontend_trigger_debugMode, io_in_frontend_trigger_triggerCanRaiseBpExp,
     io_in_mem_trigger_tUpdate_valid, io_in_mem_trigger_tUpdate_bits_addr,
     io_in_mem_trigger_tUpdate_bits_tdata_matchType,
     io_in_mem_trigger_tUpdate_bits_tdata_select,
     io_in_mem_trigger_tUpdate_bits_tdata_action,
     io_in_mem_trigger_tUpdate_bits_tdata_chain,
     io_in_mem_trigger_tUpdate_bits_tdata_store,
     io_in_mem_trigger_tUpdate_bits_tdata_load,
     io_in_mem_trigger_tUpdate_bits_tdata_tdata2, io_in_mem_trigger_tEnableVec_0,
     io_in_mem_trigger_tEnableVec_1, io_in_mem_trigger_tEnableVec_2,
     io_in_mem_trigger_tEnableVec_3, io_in_mem_trigger_debugMode,
     io_in_mem_trigger_triggerCanRaiseBpExp, io_in_fsIsOff};

  xs_DelayN_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT)
  ) u_core (
    .clock(clock),
    .d_in (payload_in),
    .d_out(payload_out)
  );

  assign
    {io_out_pf_ctrl_l1I_pf_enable, io_out_bp_ctrl_ubtb_enable, io_out_bp_ctrl_btb_enable,
     io_out_bp_ctrl_tage_enable, io_out_bp_ctrl_sc_enable, io_out_bp_ctrl_ras_enable,
     io_out_sbuffer_timeout, io_out_ldld_vio_check_enable, io_out_cache_error_enable,
     io_out_hd_misalign_st_enable, io_out_hd_misalign_ld_enable,
     io_out_distribute_csr_w_valid, io_out_distribute_csr_w_bits_addr,
     io_out_distribute_csr_w_bits_data, io_out_frontend_trigger_tUpdate_valid,
     io_out_frontend_trigger_tUpdate_bits_addr,
     io_out_frontend_trigger_tUpdate_bits_tdata_matchType,
     io_out_frontend_trigger_tUpdate_bits_tdata_select,
     io_out_frontend_trigger_tUpdate_bits_tdata_action,
     io_out_frontend_trigger_tUpdate_bits_tdata_chain,
     io_out_frontend_trigger_tUpdate_bits_tdata_tdata2,
     io_out_frontend_trigger_tEnableVec_0, io_out_frontend_trigger_tEnableVec_1,
     io_out_frontend_trigger_tEnableVec_2, io_out_frontend_trigger_tEnableVec_3,
     io_out_frontend_trigger_debugMode, io_out_frontend_trigger_triggerCanRaiseBpExp,
     io_out_mem_trigger_tUpdate_valid, io_out_mem_trigger_tUpdate_bits_addr,
     io_out_mem_trigger_tUpdate_bits_tdata_matchType,
     io_out_mem_trigger_tUpdate_bits_tdata_select,
     io_out_mem_trigger_tUpdate_bits_tdata_action,
     io_out_mem_trigger_tUpdate_bits_tdata_chain,
     io_out_mem_trigger_tUpdate_bits_tdata_store,
     io_out_mem_trigger_tUpdate_bits_tdata_load,
     io_out_mem_trigger_tUpdate_bits_tdata_tdata2, io_out_mem_trigger_tEnableVec_0,
     io_out_mem_trigger_tEnableVec_1, io_out_mem_trigger_tEnableVec_2,
     io_out_mem_trigger_tEnableVec_3, io_out_mem_trigger_debugMode,
     io_out_mem_trigger_triggerCanRaiseBpExp, io_out_fsIsOff} = payload_out;

endmodule
