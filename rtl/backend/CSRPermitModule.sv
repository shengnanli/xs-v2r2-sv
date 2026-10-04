// CSRPermitModule —— CSR 访问 / xRET 指令的权限汇总
// 设计意图：src/main/scala/xiangshan/backend/fu/NewCSR/CSRPermitModule.scala（class CSRPermitModule，父 NewCSR）
//
// 结构：6 个权限子模块各管一类规则，本模块只做汇总（纯组合，无寄存器）：
//   xRetPermitMod          mnret/mret/sret/dret 是否合法（及其 EX_II/EX_VI）
//   mLevelPermitMod        M 级规则（mstateen、mcounteren、FS/VS Off、TVM ...）→ EX_II；
//                          另给出"写 fcsr/vcsr 是否合法"
//   sLevelPermitMod        S 级规则（scounteren、sstateen0.C）→ EX_II
//   privilegePermitMod     CSR 地址编码的特权级 / 只读位 / debug CSR → EX_II、EX_VI
//   virtualLevelPermitMod  H 扩展虚拟化规则 → EX_II、EX_VI
//   indirectCSRPermitMod   间接 CSR（*ireg 经 *iselect 选中）→ EX_II、EX_VI
//
// 汇总规则（照 Scala）：
//   * "直接"权限（前 5 类）只要有一条报异常，就不再看间接 CSR 的结果——间接检查的前提是
//     这条 CSR 访问本身合法（directPermit_illegal 为假）。
//   * 只有真正发生 CSR 访问（ren|wen）时，CSR 访问类异常才生效；xRET 的异常与 CSR 访问无关。
//   * EX_II（非法指令）优先于 EX_VI（虚拟指令）：两者同时成立时只报 EX_II。
//   * hasLegalWen = 有写且没有任何异常。
module CSRPermitModule(
  input         io_in_csrAccess_ren,
  input         io_in_csrAccess_wen,
  input  [11:0] io_in_csrAccess_addr,
  input  [1:0]  io_in_privState_PRVM,
  input         io_in_privState_V,
  input         io_in_debugMode,
  input         io_in_xRet_mnret,
  input         io_in_xRet_mret,
  input         io_in_xRet_sret,
  input         io_in_xRet_dret,
  input         io_in_status_tsr,
  input         io_in_status_vtsr,
  input         io_in_status_tvm,
  input         io_in_status_vtvm,
  input  [5:0]  io_in_status_vgein,
  input         io_in_status_mstatusFSOff,
  input         io_in_status_vsstatusFSOff,
  input         io_in_status_mstatusVSOff,
  input         io_in_status_vsstatusVSOff,
  input  [31:0] io_in_xcounteren_mcounteren,
  input  [31:0] io_in_xcounteren_hcounteren,
  input  [31:0] io_in_xcounteren_scounteren,
  input  [63:0] io_in_xenvcfg_menvcfg,
  input  [63:0] io_in_xenvcfg_henvcfg,
  input         io_in_xstateen_mstateen0_SE0,
  input         io_in_xstateen_mstateen0_ENVCFG,
  input         io_in_xstateen_mstateen0_CSRIND,
  input         io_in_xstateen_mstateen0_AIA,
  input         io_in_xstateen_mstateen0_IMSIC,
  input         io_in_xstateen_mstateen0_CONTEXT,
  input         io_in_xstateen_mstateen0_C,
  input         io_in_xstateen_mstateen1_SE,
  input         io_in_xstateen_mstateen2_SE,
  input         io_in_xstateen_mstateen3_SE,
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
  input  [63:0] io_in_aia_miselect,
  input  [63:0] io_in_aia_siselect,
  input  [63:0] io_in_aia_vsiselect,
  input         io_in_aia_mvienSEIE,
  input         io_in_aia_hvictlVTI,
  output        io_out_hasLegalWen,
  output        io_out_hasLegalMNret,
  output        io_out_hasLegalMret,
  output        io_out_hasLegalSret,
  output        io_out_hasLegalDret,
  output        io_out_hasLegalWriteFcsr,
  output        io_out_hasLegalWriteVcsr,
  output        io_out_EX_II,
  output        io_out_EX_VI
);

  // ---- 子模块输出 ----
  wire xret_EX_II, xret_EX_VI;
  wire mlevel_EX_II, slevel_EX_II;
  wire priv_EX_II, priv_EX_VI;
  wire vlevel_EX_II, vlevel_EX_VI;
  wire indirect_EX_II, indirect_EX_VI;

  // ---- 汇总 ----
  wire csr_access = io_in_csrAccess_ren | io_in_csrAccess_wen;

  // 任一"直接"规则报异常（无论 II 还是 VI）
  wire direct_illegal = mlevel_EX_II | slevel_EX_II | priv_EX_II | priv_EX_VI
                      | vlevel_EX_II | vlevel_EX_VI;

  wire csr_access_EX_II = csr_access & (mlevel_EX_II | slevel_EX_II | priv_EX_II | vlevel_EX_II
                                        | ~direct_illegal & indirect_EX_II);
  wire csr_access_EX_VI = csr_access & (priv_EX_VI | vlevel_EX_VI
                                        | ~direct_illegal & indirect_EX_VI);

  wire ex_ii = csr_access_EX_II | xret_EX_II;
  wire ex_vi = ~ex_ii & (csr_access_EX_VI | xret_EX_VI);

  assign io_out_EX_II       = ex_ii;
  assign io_out_EX_VI       = ex_vi;
  assign io_out_hasLegalWen = io_in_csrAccess_wen & ~(ex_ii | ex_vi);

  // ---- 子模块例化（实例名同 golden；连线是端口直连） ----
  XRetPermitModule xRetPermitMod (
    .io_in_privState_PRVM (io_in_privState_PRVM),
    .io_in_privState_V    (io_in_privState_V),
    .io_in_debugMode      (io_in_debugMode),
    .io_in_xRet_mnret     (io_in_xRet_mnret),
    .io_in_xRet_mret      (io_in_xRet_mret),
    .io_in_xRet_sret      (io_in_xRet_sret),
    .io_in_xRet_dret      (io_in_xRet_dret),
    .io_in_status_tsr     (io_in_status_tsr),
    .io_in_status_vtsr    (io_in_status_vtsr),
    .io_out_Xret_EX_II    (xret_EX_II),
    .io_out_Xret_EX_VI    (xret_EX_VI),
    .io_out_hasLegalMNret (io_out_hasLegalMNret),
    .io_out_hasLegalMret  (io_out_hasLegalMret),
    .io_out_hasLegalSret  (io_out_hasLegalSret),
    .io_out_hasLegalDret  (io_out_hasLegalDret)
  );
  MLevelPermitModule mLevelPermitMod (
    .io_in_csrAccess_wen              (io_in_csrAccess_wen),
    .io_in_csrAccess_addr             (io_in_csrAccess_addr),
    .io_in_privState_PRVM             (io_in_privState_PRVM),
    .io_in_privState_V                (io_in_privState_V),
    .io_in_status_tvm                 (io_in_status_tvm),
    .io_in_status_mstatusFSOff        (io_in_status_mstatusFSOff),
    .io_in_status_vsstatusFSOff       (io_in_status_vsstatusFSOff),
    .io_in_status_mstatusVSOff        (io_in_status_mstatusVSOff),
    .io_in_status_vsstatusVSOff       (io_in_status_vsstatusVSOff),
    .io_in_xcounteren_mcounteren      (io_in_xcounteren_mcounteren),
    .io_in_xenvcfg_menvcfg            (io_in_xenvcfg_menvcfg),
    .io_in_xstateen_mstateen0_SE0     (io_in_xstateen_mstateen0_SE0),
    .io_in_xstateen_mstateen0_ENVCFG  (io_in_xstateen_mstateen0_ENVCFG),
    .io_in_xstateen_mstateen0_CSRIND  (io_in_xstateen_mstateen0_CSRIND),
    .io_in_xstateen_mstateen0_AIA     (io_in_xstateen_mstateen0_AIA),
    .io_in_xstateen_mstateen0_IMSIC   (io_in_xstateen_mstateen0_IMSIC),
    .io_in_xstateen_mstateen0_CONTEXT (io_in_xstateen_mstateen0_CONTEXT),
    .io_in_xstateen_mstateen0_C       (io_in_xstateen_mstateen0_C),
    .io_in_xstateen_mstateen1_SE      (io_in_xstateen_mstateen1_SE),
    .io_in_xstateen_mstateen2_SE      (io_in_xstateen_mstateen2_SE),
    .io_in_xstateen_mstateen3_SE      (io_in_xstateen_mstateen3_SE),
    .io_in_aia_mvienSEIE              (io_in_aia_mvienSEIE),
    .io_out_mLevelPermit_EX_II        (mlevel_EX_II),
    .io_out_hasLegalWriteFcsr         (io_out_hasLegalWriteFcsr),
    .io_out_hasLegalWriteVcsr         (io_out_hasLegalWriteVcsr)
  );
  SLevelPermitModule sLevelPermitMod (
    .io_in_csrAccess_addr        (io_in_csrAccess_addr),
    .io_in_privState_PRVM        (io_in_privState_PRVM),
    .io_in_privState_V           (io_in_privState_V),
    .io_in_xcounteren_scounteren (io_in_xcounteren_scounteren),
    .io_in_xstateen_sstateen0_C  (io_in_xstateen_sstateen0_C),
    .io_out_sLevelPermit_EX_II   (slevel_EX_II)
  );
  PrivilegePermitModule privilegePermitMod (
    .io_in_csrAccess_addr   (io_in_csrAccess_addr),
    .io_in_privState_PRVM   (io_in_privState_PRVM),
    .io_in_privState_V      (io_in_privState_V),
    .io_in_debugMode        (io_in_debugMode),
    .io_out_privilege_EX_II (priv_EX_II),
    .io_out_privilege_EX_VI (priv_EX_VI)
  );
  VirtualLevelPermitModule virtualLevelPermitMod (
    .io_in_csrAccess_wen              (io_in_csrAccess_wen),
    .io_in_csrAccess_addr             (io_in_csrAccess_addr),
    .io_in_privState_PRVM             (io_in_privState_PRVM),
    .io_in_privState_V                (io_in_privState_V),
    .io_in_status_vtvm                (io_in_status_vtvm),
    .io_in_status_vgein               (io_in_status_vgein),
    .io_in_xcounteren_hcounteren      (io_in_xcounteren_hcounteren),
    .io_in_xcounteren_scounteren      (io_in_xcounteren_scounteren),
    .io_in_xenvcfg_henvcfg            (io_in_xenvcfg_henvcfg),
    .io_in_xstateen_hstateen0_C       (io_in_xstateen_hstateen0_C),
    .io_in_xstateen_hstateen0_SE0     (io_in_xstateen_hstateen0_SE0),
    .io_in_xstateen_hstateen0_ENVCFG  (io_in_xstateen_hstateen0_ENVCFG),
    .io_in_xstateen_hstateen0_CSRIND  (io_in_xstateen_hstateen0_CSRIND),
    .io_in_xstateen_hstateen0_AIA     (io_in_xstateen_hstateen0_AIA),
    .io_in_xstateen_hstateen0_IMSIC   (io_in_xstateen_hstateen0_IMSIC),
    .io_in_xstateen_hstateen0_CONTEXT (io_in_xstateen_hstateen0_CONTEXT),
    .io_in_xstateen_hstateen1_SE      (io_in_xstateen_hstateen1_SE),
    .io_in_xstateen_hstateen2_SE      (io_in_xstateen_hstateen2_SE),
    .io_in_xstateen_hstateen3_SE      (io_in_xstateen_hstateen3_SE),
    .io_in_xstateen_sstateen0_C       (io_in_xstateen_sstateen0_C),
    .io_in_aia_hvictlVTI              (io_in_aia_hvictlVTI),
    .io_out_virtualLevelPermit_EX_II (vlevel_EX_II),
    .io_out_virtualLevelPermit_EX_VI (vlevel_EX_VI)
  );
  IndirectCSRPermitModule indirectCSRPermitMod (
    .io_in_csrAccess_addr           (io_in_csrAccess_addr),
    .io_in_privState_PRVM           (io_in_privState_PRVM),
    .io_in_privState_V              (io_in_privState_V),
    .io_in_aia_miselect             (io_in_aia_miselect),
    .io_in_aia_siselect             (io_in_aia_siselect),
    .io_in_aia_vsiselect            (io_in_aia_vsiselect),
    .io_in_aia_mvienSEIE            (io_in_aia_mvienSEIE),
    .io_in_xstateen_mstateen0_AIA   (io_in_xstateen_mstateen0_AIA),
    .io_in_xstateen_mstateen0_IMSIC (io_in_xstateen_mstateen0_IMSIC),
    .io_in_xstateen_hstateen0_IMSIC (io_in_xstateen_hstateen0_IMSIC),
    .io_out_indirectCSR_EX_II       (indirect_EX_II),
    .io_out_indirectCSR_EX_VI       (indirect_EX_VI)
  );

endmodule
