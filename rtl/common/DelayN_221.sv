// =============================================================================
// DelayN_221 —— 固定级数的载荷打拍链（xs_DelayN_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   延迟级数 STAGES = 1；载荷宽度 = 261 位，分 21 个字段；
//   golden 模块体 = 261 个 reg 位（1 级 × 261 位），无复位 / 无使能 / 无子模块；
//   端口 43 个 = clock + 21 个 io_in_* + 21 个 io_out_*。
//   载荷字段：satp_mode=4b, satp_asid=16b, satp_ppn=44b, satp_changed=1b, vsatp_mode=4b …共 21 个字段，明细见端口表。
//   使用者：L2TLB —— 261 位 PTW 响应包打一拍。
//
// 结构：golden 同名端口表 -> 打包成一根 261 位扁平载荷 -> 设参例化
//   xs_DelayN_core（核体见 xs_DelayN_core.sv，打拍语义与不变式都在那里讲）
//   -> 拆包回 golden 的 io_out_* 端口。本层只做拼包/拆包。
//   PORT_BITS_IN/OUT 用 $bits(golden 端口拼接) 算出来传给核：任何一个端口的位宽
//   抄错，拼接总位数就变，time 0 直接 $fatal（本轮已发生 3 次位宽静默错事故）。
// 自动生成：verif/ut/DelayN/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayN_221(
  input         clock,
  input  [3:0]  io_in_satp_mode,
  input  [15:0] io_in_satp_asid,
  input  [43:0] io_in_satp_ppn,
  input         io_in_satp_changed,
  input  [3:0]  io_in_vsatp_mode,
  input  [15:0] io_in_vsatp_asid,
  input  [43:0] io_in_vsatp_ppn,
  input         io_in_vsatp_changed,
  input  [3:0]  io_in_hgatp_mode,
  input  [15:0] io_in_hgatp_vmid,
  input  [43:0] io_in_hgatp_ppn,
  input         io_in_hgatp_changed,
  input         io_in_mbmc_BME,
  input         io_in_mbmc_CMODE,
  input         io_in_mbmc_BCLEAR,
  input  [57:0] io_in_mbmc_BMA,
  input         io_in_priv_virt,
  input         io_in_priv_virt_changed,
  input         io_in_priv_debug,
  input         io_in_mPBMTE,
  input         io_in_hPBMTE,
  output [3:0]  io_out_satp_mode,
  output [15:0] io_out_satp_asid,
  output [43:0] io_out_satp_ppn,
  output        io_out_satp_changed,
  output [3:0]  io_out_vsatp_mode,
  output [15:0] io_out_vsatp_asid,
  output [43:0] io_out_vsatp_ppn,
  output        io_out_vsatp_changed,
  output [3:0]  io_out_hgatp_mode,
  output [15:0] io_out_hgatp_vmid,
  output [43:0] io_out_hgatp_ppn,
  output        io_out_hgatp_changed,
  output        io_out_mbmc_BME,
  output        io_out_mbmc_CMODE,
  output        io_out_mbmc_BCLEAR,
  output [57:0] io_out_mbmc_BMA,
  output        io_out_priv_virt,
  output        io_out_priv_virt_changed,
  output        io_out_priv_debug,
  output        io_out_mPBMTE,
  output        io_out_hPBMTE
);

  localparam int unsigned STAGES          = 1;
  localparam int unsigned GOLDEN_REG_BITS = 261;   // golden 里 reg 位数总和
  localparam int unsigned PAYLOAD_W       = GOLDEN_REG_BITS / STAGES;

  // 端口表事实：golden 全部输入 / 输出端口拼起来各有多少位（$bits 只认端口声明）
  localparam int unsigned PORT_BITS_IN = $bits(
    {io_in_satp_mode, io_in_satp_asid, io_in_satp_ppn, io_in_satp_changed,
     io_in_vsatp_mode, io_in_vsatp_asid, io_in_vsatp_ppn, io_in_vsatp_changed,
     io_in_hgatp_mode, io_in_hgatp_vmid, io_in_hgatp_ppn, io_in_hgatp_changed,
     io_in_mbmc_BME, io_in_mbmc_CMODE, io_in_mbmc_BCLEAR, io_in_mbmc_BMA, io_in_priv_virt,
     io_in_priv_virt_changed, io_in_priv_debug, io_in_mPBMTE, io_in_hPBMTE});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {io_out_satp_mode, io_out_satp_asid, io_out_satp_ppn, io_out_satp_changed,
     io_out_vsatp_mode, io_out_vsatp_asid, io_out_vsatp_ppn, io_out_vsatp_changed,
     io_out_hgatp_mode, io_out_hgatp_vmid, io_out_hgatp_ppn, io_out_hgatp_changed,
     io_out_mbmc_BME, io_out_mbmc_CMODE, io_out_mbmc_BCLEAR, io_out_mbmc_BMA,
     io_out_priv_virt, io_out_priv_virt_changed, io_out_priv_debug, io_out_mPBMTE,
     io_out_hPBMTE});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
    {io_in_satp_mode, io_in_satp_asid, io_in_satp_ppn, io_in_satp_changed,
     io_in_vsatp_mode, io_in_vsatp_asid, io_in_vsatp_ppn, io_in_vsatp_changed,
     io_in_hgatp_mode, io_in_hgatp_vmid, io_in_hgatp_ppn, io_in_hgatp_changed,
     io_in_mbmc_BME, io_in_mbmc_CMODE, io_in_mbmc_BCLEAR, io_in_mbmc_BMA, io_in_priv_virt,
     io_in_priv_virt_changed, io_in_priv_debug, io_in_mPBMTE, io_in_hPBMTE};

  xs_DelayN_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT),
    .GOLDEN_HAS_CLOCK(1)
  ) u_core (
    .clock(clock),
    .d_in (payload_in),
    .d_out(payload_out)
  );

  assign
    {io_out_satp_mode, io_out_satp_asid, io_out_satp_ppn, io_out_satp_changed,
     io_out_vsatp_mode, io_out_vsatp_asid, io_out_vsatp_ppn, io_out_vsatp_changed,
     io_out_hgatp_mode, io_out_hgatp_vmid, io_out_hgatp_ppn, io_out_hgatp_changed,
     io_out_mbmc_BME, io_out_mbmc_CMODE, io_out_mbmc_BCLEAR, io_out_mbmc_BMA,
     io_out_priv_virt, io_out_priv_virt_changed, io_out_priv_debug, io_out_mPBMTE,
     io_out_hPBMTE} = payload_out;

endmodule
