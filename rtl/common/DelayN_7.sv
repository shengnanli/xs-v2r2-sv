// =============================================================================
// DelayN_7 —— 固定级数的载荷打拍链（xs_DelayN_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   延迟级数 STAGES = 2；载荷宽度 = 219 位，分 29 个字段；
//   golden 模块体 = 438 个 reg 位（2 级 × 219 位），无复位 / 无使能 / 无子模块；
//   端口 59 个 = clock + 29 个 io_in_* + 29 个 io_out_*。
//   载荷字段：satp_mode=4b, satp_asid=16b, satp_ppn=44b, satp_changed=1b, vsatp_mode=4b …共 29 个字段，明细见端口表。
//   使用者：Frontend / TLB 系列 —— satp/vsatp/hgatp/mbmc/priv/pmm 快照打两拍。
//
// 结构：golden 同名端口表 -> 打包成一根 219 位扁平载荷 -> 设参例化
//   xs_DelayN_core（核体见 xs_DelayN_core.sv，打拍语义与不变式都在那里讲）
//   -> 拆包回 golden 的 io_out_* 端口。本层只做拼包/拆包。
//   PORT_BITS_IN/OUT 用 $bits(golden 端口拼接) 算出来传给核：任何一个端口的位宽
//   抄错，拼接总位数就变，time 0 直接 $fatal（本轮已发生 3 次位宽静默错事故）。
// 自动生成：verif/ut/DelayN/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayN_7(
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
  input         io_in_priv_mxr,
  input         io_in_priv_sum,
  input         io_in_priv_vmxr,
  input         io_in_priv_vsum,
  input         io_in_priv_virt,
  input         io_in_priv_virt_changed,
  input         io_in_priv_spvp,
  input  [1:0]  io_in_priv_imode,
  input  [1:0]  io_in_priv_dmode,
  input         io_in_priv_debug,
  input  [1:0]  io_in_pmm_mseccfg,
  input  [1:0]  io_in_pmm_menvcfg,
  input  [1:0]  io_in_pmm_henvcfg,
  input  [1:0]  io_in_pmm_hstatus,
  input  [1:0]  io_in_pmm_senvcfg,
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
  output        io_out_priv_mxr,
  output        io_out_priv_sum,
  output        io_out_priv_vmxr,
  output        io_out_priv_vsum,
  output        io_out_priv_virt,
  output        io_out_priv_virt_changed,
  output        io_out_priv_spvp,
  output [1:0]  io_out_priv_imode,
  output [1:0]  io_out_priv_dmode,
  output        io_out_priv_debug,
  output [1:0]  io_out_pmm_mseccfg,
  output [1:0]  io_out_pmm_menvcfg,
  output [1:0]  io_out_pmm_henvcfg,
  output [1:0]  io_out_pmm_hstatus,
  output [1:0]  io_out_pmm_senvcfg
);

  localparam int unsigned STAGES          = 2;
  localparam int unsigned GOLDEN_REG_BITS = 438;   // golden 里 reg 位数总和
  localparam int unsigned PAYLOAD_W       = GOLDEN_REG_BITS / STAGES;

  // 端口表事实：golden 全部输入 / 输出端口拼起来各有多少位（$bits 只认端口声明）
  localparam int unsigned PORT_BITS_IN = $bits(
    {io_in_satp_mode, io_in_satp_asid, io_in_satp_ppn, io_in_satp_changed,
     io_in_vsatp_mode, io_in_vsatp_asid, io_in_vsatp_ppn, io_in_vsatp_changed,
     io_in_hgatp_mode, io_in_hgatp_vmid, io_in_hgatp_ppn, io_in_hgatp_changed,
     io_in_mbmc_BME, io_in_mbmc_CMODE, io_in_priv_mxr, io_in_priv_sum, io_in_priv_vmxr,
     io_in_priv_vsum, io_in_priv_virt, io_in_priv_virt_changed, io_in_priv_spvp,
     io_in_priv_imode, io_in_priv_dmode, io_in_priv_debug, io_in_pmm_mseccfg,
     io_in_pmm_menvcfg, io_in_pmm_henvcfg, io_in_pmm_hstatus, io_in_pmm_senvcfg});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {io_out_satp_mode, io_out_satp_asid, io_out_satp_ppn, io_out_satp_changed,
     io_out_vsatp_mode, io_out_vsatp_asid, io_out_vsatp_ppn, io_out_vsatp_changed,
     io_out_hgatp_mode, io_out_hgatp_vmid, io_out_hgatp_ppn, io_out_hgatp_changed,
     io_out_mbmc_BME, io_out_mbmc_CMODE, io_out_priv_mxr, io_out_priv_sum,
     io_out_priv_vmxr, io_out_priv_vsum, io_out_priv_virt, io_out_priv_virt_changed,
     io_out_priv_spvp, io_out_priv_imode, io_out_priv_dmode, io_out_priv_debug,
     io_out_pmm_mseccfg, io_out_pmm_menvcfg, io_out_pmm_henvcfg, io_out_pmm_hstatus,
     io_out_pmm_senvcfg});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
    {io_in_satp_mode, io_in_satp_asid, io_in_satp_ppn, io_in_satp_changed,
     io_in_vsatp_mode, io_in_vsatp_asid, io_in_vsatp_ppn, io_in_vsatp_changed,
     io_in_hgatp_mode, io_in_hgatp_vmid, io_in_hgatp_ppn, io_in_hgatp_changed,
     io_in_mbmc_BME, io_in_mbmc_CMODE, io_in_priv_mxr, io_in_priv_sum, io_in_priv_vmxr,
     io_in_priv_vsum, io_in_priv_virt, io_in_priv_virt_changed, io_in_priv_spvp,
     io_in_priv_imode, io_in_priv_dmode, io_in_priv_debug, io_in_pmm_mseccfg,
     io_in_pmm_menvcfg, io_in_pmm_henvcfg, io_in_pmm_hstatus, io_in_pmm_senvcfg};

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
    {io_out_satp_mode, io_out_satp_asid, io_out_satp_ppn, io_out_satp_changed,
     io_out_vsatp_mode, io_out_vsatp_asid, io_out_vsatp_ppn, io_out_vsatp_changed,
     io_out_hgatp_mode, io_out_hgatp_vmid, io_out_hgatp_ppn, io_out_hgatp_changed,
     io_out_mbmc_BME, io_out_mbmc_CMODE, io_out_priv_mxr, io_out_priv_sum,
     io_out_priv_vmxr, io_out_priv_vsum, io_out_priv_virt, io_out_priv_virt_changed,
     io_out_priv_spvp, io_out_priv_imode, io_out_priv_dmode, io_out_priv_debug,
     io_out_pmm_mseccfg, io_out_pmm_menvcfg, io_out_pmm_henvcfg, io_out_pmm_hstatus,
     io_out_pmm_senvcfg} = payload_out;

endmodule
