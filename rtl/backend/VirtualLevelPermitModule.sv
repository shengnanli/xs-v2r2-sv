// VirtualLevelPermitModule —— 虚拟化（H 扩展）相关的 CSR 访问权限检查
// 设计意图：src/main/scala/xiangshan/backend/fu/NewCSR/CSRPermitModule.scala
//           class VirtualLevelPermitModule（父：CSRPermitModule）
//
// 纯组合。给出两类异常：
//   EX_II（非法指令）：只有一条 —— M/HS 态访问 vstopei，但 hstatus.VGEIN 不指向有效
//                     guest 中断文件（VGEIN==0 或 >geilen；本配置 IMSICParams.geilen=7，
//                     所以 ">7" 等价于 "VGEIN[5:3]!=0"）。
//   EX_VI（虚拟指令）：VS/VU 态下按 H 扩展规定该陷到 HS 的访问，逐条列在下面，每条对应 Scala
//                     一个 *_EX_VI 变量。
// 细节：
//   * HPM 计数器窗口是 [cycle 0xC00, hpmcounter31 0xC1F]，下标取 addr[4:0]。
//   * Sscsrind 窗口 [0x150,0x157] 但 0x154 不在内（Ireg.isInSCsrInd 排除 sireg 空位）。
module VirtualLevelPermitModule(
  input         io_in_csrAccess_wen,
  input  [11:0] io_in_csrAccess_addr,
  input  [1:0]  io_in_privState_PRVM,
  input         io_in_privState_V,
  input         io_in_status_vtvm,
  input  [5:0]  io_in_status_vgein,
  input  [31:0] io_in_xcounteren_hcounteren,
  input  [31:0] io_in_xcounteren_scounteren,
  input  [63:0] io_in_xenvcfg_henvcfg,
  input         io_in_xstateen_hstateen0_C,
  input         io_in_xstateen_hstateen0_SE0,
  input         io_in_xstateen_hstateen0_ENVCFG,
  input         io_in_xstateen_hstateen0_CSRIND,
  input         io_in_xstateen_hstateen0_AIA,
  input         io_in_xstateen_hstateen0_IMSIC,
  input         io_in_xstateen_hstateen0_CONTEXT,
  input         io_in_xstateen_hstateen1_SE,
  input         io_in_xstateen_hstateen2_SE,
  input         io_in_xstateen_hstateen3_SE,
  input         io_in_xstateen_sstateen0_C,
  input         io_in_aia_hvictlVTI,
  output        io_out_virtualLevelPermit_EX_II,
  output        io_out_virtualLevelPermit_EX_VI
);

  // ---- 特权态解码 ----
  wire [11:0] addr     = io_in_csrAccess_addr;
  wire        virt     = io_in_privState_V;
  wire        mode_m   = io_in_privState_PRVM == 2'h3;
  wire        mode_hs  = ~virt & io_in_privState_PRVM == 2'h1;
  wire        mode_vs  = virt & io_in_privState_PRVM == 2'h1;
  wire        mode_vu  = virt & io_in_privState_PRVM == 2'h0;

  // hstatus.VGEIN 没有指向有效 guest 中断文件（见文件头怪癖）
  wire        vgein_invalid = io_in_status_vgein == 6'h0 | (|io_in_status_vgein[5:3]);

  // ---- 非法指令：M/HS 访问 vstopei(0x25C) 但 VGEIN 无效 ----
  wire rwVStopei_EX_II = (mode_m | mode_hs) & addr == 12'h25C & vgein_invalid;

  // ---- 虚拟指令：VS 态的 S 级 CSR 特殊规则 ----
  // satp(0x180)：hstatus.VTVM=1 时 VS 访问 satp 陷入
  wire rwSatp_EX_VI     = mode_vs & io_in_status_vtvm & addr == 12'h180;
  // stopei(0x15C)：VGEIN 无效时 VS 访问陷入
  wire csrIsStopei      = addr == 12'h15C;
  wire rwStopei_EX_VI   = mode_vs & csrIsStopei & vgein_invalid;
  // sip(0x144)/sie(0x104)：hvictl.VTI=1 时 VS 访问陷入
  wire rwSip_Sie_EX_VI  = mode_vs & io_in_aia_hvictlVTI & (addr == 12'h144 | addr == 12'h104);
  // stimecmp(0x14D)：hcounteren.TM=0 或 henvcfg.STCE=0，或 VTI=1 时写，均陷入
  wire rwStimecmp_EX_VI = mode_vs & addr == 12'h14D
                        & (~io_in_xcounteren_hcounteren[1] | ~io_in_xenvcfg_henvcfg[63]
                           | io_in_csrAccess_wen & io_in_aia_hvictlVTI);

  // ---- 虚拟指令：HPM 计数器 [0xC00,0xC1F] 受 hcounteren/scounteren 控制 ----
  wire        csrIsHPM     = addr > 12'hBFF & addr < 12'hC20;
  wire [4:0]  counter_idx  = addr[4:0];
  wire        h_counter_en = io_in_xcounteren_hcounteren[counter_idx];
  wire        s_counter_en = io_in_xcounteren_scounteren[counter_idx];
  wire accessHPM_EX_VI = csrIsHPM & (mode_vs & ~h_counter_en
                                     | mode_vu & (~h_counter_en | ~s_counter_en));

  // ---- 虚拟指令：Smstateen —— hstateen 某位为 0 时 V=1 访问对应 CSR 陷入 ----
  // sstateen0..3 (0x10C..0x10F) 各自受 hstateenN.SE（hstateen0 为 SE0）控制
  wire accessStateen_EX_VI = virt & (addr == 12'h10C & ~io_in_xstateen_hstateen0_SE0
                                    | addr == 12'h10D & ~io_in_xstateen_hstateen1_SE
                                    | addr == 12'h10E & ~io_in_xstateen_hstateen2_SE
                                    | addr == 12'h10F & ~io_in_xstateen_hstateen3_SE);
  // senvcfg(0x10A) ← hstateen0.ENVCFG
  wire accessEnvcfg_EX_VI  = virt & addr == 12'h10A & ~io_in_xstateen_hstateen0_ENVCFG;
  // siselect/sireg* [0x150,0x157] 除 0x154 ← hstateen0.CSRIND
  wire csrIsSi             = addr > 12'h14F & addr < 12'h158 & addr != 12'h154;
  wire accessIND_EX_VI     = virt & csrIsSi & ~io_in_xstateen_hstateen0_CSRIND;
  // stopi(0xDB0) ← hstateen0.AIA
  wire accessAIA_EX_VI     = virt & addr == 12'hDB0 & ~io_in_xstateen_hstateen0_AIA;
  // stopei(0x15C) ← hstateen0.IMSIC
  wire accessTopie_EX_VI   = virt & csrIsStopei & ~io_in_xstateen_hstateen0_IMSIC;
  // scontext(0x5A8) ← hstateen0.CONTEXT
  wire accessContext_EX_VI = virt & addr == 12'h5A8 & ~io_in_xstateen_hstateen0_CONTEXT;
  // 自定义 CSR：S 级 [0x5C0..0x5FF]/[0x9C0..]/[0xDC0..]，U 级 [0x800..0x8FF]/[0xCC0..0xCFF]
  wire csrIsSCustom = (|addr[11:10]) & addr[9:8] == 2'h1 & (&addr[7:6]);
  wire csrIsUCustom = addr[11:8] == 4'h8 | addr[11:6] == 6'h33;
  wire accessCustom_EX_VI = (csrIsSCustom | csrIsUCustom) & virt & ~io_in_xstateen_hstateen0_C
                          | csrIsUCustom & mode_vu & io_in_xstateen_hstateen0_C
                            & ~io_in_xstateen_sstateen0_C;

  // ---- 汇总 ----
  assign io_out_virtualLevelPermit_EX_II = rwVStopei_EX_II;
  assign io_out_virtualLevelPermit_EX_VI =
      rwSatp_EX_VI | rwStopei_EX_VI | rwSip_Sie_EX_VI | rwStimecmp_EX_VI | accessHPM_EX_VI
    | accessStateen_EX_VI | accessEnvcfg_EX_VI | accessIND_EX_VI | accessAIA_EX_VI
    | accessTopie_EX_VI | accessContext_EX_VI | accessCustom_EX_VI;

endmodule
