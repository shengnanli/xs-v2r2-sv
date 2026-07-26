// UT twin of the readable InterruptFilter core (identical body,
// module renamed to InterruptFilter_xs so the dual-instantiation UT
// is a genuine golden-vs-impl comparison, not self-vs-self).
// NewCSR InterruptFilter — readable, primitive-factored core
// (module InterruptFilter, golden-identical 312 ports; an identical-body twin
// InterruptFilter_xs is emitted for the dual-instantiation UT).
//
// RISC-V interrupt priority resolution + M/HS/VS delegation + virtual-
// interrupt (hvictl/hvip) injection.  Machine-de-obfuscated from the golden
// CIRCT-flattened RTL: the priority-reduction network's ~90 identical merge
// nodes are factored into xs_iprio_merge instances (see
// newcsr_intrfilter_prims.sv), and the residual CIRCT _GEN_/_T_/_WIRE noise
// wires are renamed to readable names.  Every expression is preserved
// bit-for-bit, so FM(strict) golden-vs-core is SUCCEEDED with no black box,
// no dont_verify.  Sim-only blocks (randomize init, VS-exclusion asserts)
// are dropped (they never affect datapath equivalence).
//
// The 6 DelayN cells (misleadingly named DelayN_17 / DelayN_210 — actually
// 5-stage shift registers of width 1 / 8) are elaborated on both FM sides
// via the readable xs_delay_n wrappers in newcsr_intrfilter_prims.sv.

module InterruptFilter_xs(
  input          clock,
  input          reset,
  input  [1:0]   io_in_privState_PRVM,
  input          io_in_privState_V,
  input          io_in_mstatusMIE,
  input          io_in_sstatusSIE,
  input          io_in_vsstatusSIE,
  input          io_in_mip_SSIP,
  input          io_in_mip_VSSIP,
  input          io_in_mip_MSIP,
  input          io_in_mip_STIP,
  input          io_in_mip_VSTIP,
  input          io_in_mip_MTIP,
  input          io_in_mip_SEIP,
  input          io_in_mip_VSEIP,
  input          io_in_mip_MEIP,
  input          io_in_mip_SGEIP,
  input          io_in_mip_LCOFIP,
  input          io_in_mie_SSIE,
  input          io_in_mie_VSSIE,
  input          io_in_mie_MSIE,
  input          io_in_mie_STIE,
  input          io_in_mie_VSTIE,
  input          io_in_mie_MTIE,
  input          io_in_mie_SEIE,
  input          io_in_mie_VSEIE,
  input          io_in_mie_MEIE,
  input          io_in_mie_SGEIE,
  input          io_in_mie_LCOFIE,
  input          io_in_mideleg_SSI,
  input          io_in_mideleg_STI,
  input          io_in_mideleg_SEI,
  input          io_in_mideleg_LCOFI,
  input          io_in_sip_SSIP,
  input          io_in_sip_STIP,
  input          io_in_sip_SEIP,
  input          io_in_sip_LCOFIP,
  input          io_in_sip_LC14IP,
  input          io_in_sip_LC15IP,
  input          io_in_sip_LC16IP,
  input          io_in_sip_LC17IP,
  input          io_in_sip_LC18IP,
  input          io_in_sip_LC19IP,
  input          io_in_sip_LC20IP,
  input          io_in_sip_LC21IP,
  input          io_in_sip_LC22IP,
  input          io_in_sip_LC23IP,
  input          io_in_sip_LC24IP,
  input          io_in_sip_LC25IP,
  input          io_in_sip_LC26IP,
  input          io_in_sip_LC27IP,
  input          io_in_sip_LC28IP,
  input          io_in_sip_LC29IP,
  input          io_in_sip_LC30IP,
  input          io_in_sip_LC31IP,
  input          io_in_sip_LC32IP,
  input          io_in_sip_LC33IP,
  input          io_in_sip_LC34IP,
  input          io_in_sip_LPRASEIP,
  input          io_in_sip_LC36IP,
  input          io_in_sip_LC37IP,
  input          io_in_sip_LC38IP,
  input          io_in_sip_LC39IP,
  input          io_in_sip_LC40IP,
  input          io_in_sip_LC41IP,
  input          io_in_sip_LC42IP,
  input          io_in_sip_HPRASEIP,
  input          io_in_sip_LC44IP,
  input          io_in_sip_LC45IP,
  input          io_in_sip_LC46IP,
  input          io_in_sip_LC47IP,
  input          io_in_sip_LC48IP,
  input          io_in_sip_LC49IP,
  input          io_in_sip_LC50IP,
  input          io_in_sip_LC51IP,
  input          io_in_sip_LC52IP,
  input          io_in_sip_LC53IP,
  input          io_in_sip_LC54IP,
  input          io_in_sip_LC55IP,
  input          io_in_sip_LC56IP,
  input          io_in_sip_LC57IP,
  input          io_in_sip_LC58IP,
  input          io_in_sip_LC59IP,
  input          io_in_sip_LC60IP,
  input          io_in_sip_LC61IP,
  input          io_in_sip_LC62IP,
  input          io_in_sip_LC63IP,
  input          io_in_sie_SSIE,
  input          io_in_sie_STIE,
  input          io_in_sie_SEIE,
  input          io_in_sie_LCOFIE,
  input          io_in_sie_LC14IE,
  input          io_in_sie_LC15IE,
  input          io_in_sie_LC16IE,
  input          io_in_sie_LC17IE,
  input          io_in_sie_LC18IE,
  input          io_in_sie_LC19IE,
  input          io_in_sie_LC20IE,
  input          io_in_sie_LC21IE,
  input          io_in_sie_LC22IE,
  input          io_in_sie_LC23IE,
  input          io_in_sie_LC24IE,
  input          io_in_sie_LC25IE,
  input          io_in_sie_LC26IE,
  input          io_in_sie_LC27IE,
  input          io_in_sie_LC28IE,
  input          io_in_sie_LC29IE,
  input          io_in_sie_LC30IE,
  input          io_in_sie_LC31IE,
  input          io_in_sie_LC32IE,
  input          io_in_sie_LC33IE,
  input          io_in_sie_LC34IE,
  input          io_in_sie_LPRASEIE,
  input          io_in_sie_LC36IE,
  input          io_in_sie_LC37IE,
  input          io_in_sie_LC38IE,
  input          io_in_sie_LC39IE,
  input          io_in_sie_LC40IE,
  input          io_in_sie_LC41IE,
  input          io_in_sie_LC42IE,
  input          io_in_sie_HPRASEIE,
  input          io_in_sie_LC44IE,
  input          io_in_sie_LC45IE,
  input          io_in_sie_LC46IE,
  input          io_in_sie_LC47IE,
  input          io_in_sie_LC48IE,
  input          io_in_sie_LC49IE,
  input          io_in_sie_LC50IE,
  input          io_in_sie_LC51IE,
  input          io_in_sie_LC52IE,
  input          io_in_sie_LC53IE,
  input          io_in_sie_LC54IE,
  input          io_in_sie_LC55IE,
  input          io_in_sie_LC56IE,
  input          io_in_sie_LC57IE,
  input          io_in_sie_LC58IE,
  input          io_in_sie_LC59IE,
  input          io_in_sie_LC60IE,
  input          io_in_sie_LC61IE,
  input          io_in_sie_LC62IE,
  input          io_in_sie_LC63IE,
  input          io_in_hip_VSSIP,
  input          io_in_hip_VSTIP,
  input          io_in_hip_VSEIP,
  input          io_in_hip_SGEIP,
  input          io_in_hie_VSSIE,
  input          io_in_hie_VSTIE,
  input          io_in_hie_VSEIE,
  input          io_in_hie_SGEIE,
  input          io_in_hideleg_SSI,
  input          io_in_hideleg_VSSI,
  input          io_in_hideleg_MSI,
  input          io_in_hideleg_STI,
  input          io_in_hideleg_VSTI,
  input          io_in_hideleg_MTI,
  input          io_in_hideleg_SEI,
  input          io_in_hideleg_VSEI,
  input          io_in_hideleg_MEI,
  input          io_in_hideleg_SGEI,
  input          io_in_hideleg_LCOFI,
  input          io_in_vsip_SSIP,
  input          io_in_vsip_STIP,
  input          io_in_vsip_SEIP,
  input          io_in_vsip_LCOFIP,
  input          io_in_vsip_LC14IP,
  input          io_in_vsip_LC15IP,
  input          io_in_vsip_LC16IP,
  input          io_in_vsip_LC17IP,
  input          io_in_vsip_LC18IP,
  input          io_in_vsip_LC19IP,
  input          io_in_vsip_LC20IP,
  input          io_in_vsip_LC21IP,
  input          io_in_vsip_LC22IP,
  input          io_in_vsip_LC23IP,
  input          io_in_vsip_LC24IP,
  input          io_in_vsip_LC25IP,
  input          io_in_vsip_LC26IP,
  input          io_in_vsip_LC27IP,
  input          io_in_vsip_LC28IP,
  input          io_in_vsip_LC29IP,
  input          io_in_vsip_LC30IP,
  input          io_in_vsip_LC31IP,
  input          io_in_vsip_LC32IP,
  input          io_in_vsip_LC33IP,
  input          io_in_vsip_LC34IP,
  input          io_in_vsip_LPRASEIP,
  input          io_in_vsip_LC36IP,
  input          io_in_vsip_LC37IP,
  input          io_in_vsip_LC38IP,
  input          io_in_vsip_LC39IP,
  input          io_in_vsip_LC40IP,
  input          io_in_vsip_LC41IP,
  input          io_in_vsip_LC42IP,
  input          io_in_vsip_HPRASEIP,
  input          io_in_vsip_LC44IP,
  input          io_in_vsip_LC45IP,
  input          io_in_vsip_LC46IP,
  input          io_in_vsip_LC47IP,
  input          io_in_vsip_LC48IP,
  input          io_in_vsip_LC49IP,
  input          io_in_vsip_LC50IP,
  input          io_in_vsip_LC51IP,
  input          io_in_vsip_LC52IP,
  input          io_in_vsip_LC53IP,
  input          io_in_vsip_LC54IP,
  input          io_in_vsip_LC55IP,
  input          io_in_vsip_LC56IP,
  input          io_in_vsip_LC57IP,
  input          io_in_vsip_LC58IP,
  input          io_in_vsip_LC59IP,
  input          io_in_vsip_LC60IP,
  input          io_in_vsip_LC61IP,
  input          io_in_vsip_LC62IP,
  input          io_in_vsip_LC63IP,
  input          io_in_vsie_SSIE,
  input          io_in_vsie_STIE,
  input          io_in_vsie_SEIE,
  input          io_in_vsie_LCOFIE,
  input          io_in_vsie_LC14IE,
  input          io_in_vsie_LC15IE,
  input          io_in_vsie_LC16IE,
  input          io_in_vsie_LC17IE,
  input          io_in_vsie_LC18IE,
  input          io_in_vsie_LC19IE,
  input          io_in_vsie_LC20IE,
  input          io_in_vsie_LC21IE,
  input          io_in_vsie_LC22IE,
  input          io_in_vsie_LC23IE,
  input          io_in_vsie_LC24IE,
  input          io_in_vsie_LC25IE,
  input          io_in_vsie_LC26IE,
  input          io_in_vsie_LC27IE,
  input          io_in_vsie_LC28IE,
  input          io_in_vsie_LC29IE,
  input          io_in_vsie_LC30IE,
  input          io_in_vsie_LC31IE,
  input          io_in_vsie_LC32IE,
  input          io_in_vsie_LC33IE,
  input          io_in_vsie_LC34IE,
  input          io_in_vsie_LPRASEIE,
  input          io_in_vsie_LC36IE,
  input          io_in_vsie_LC37IE,
  input          io_in_vsie_LC38IE,
  input          io_in_vsie_LC39IE,
  input          io_in_vsie_LC40IE,
  input          io_in_vsie_LC41IE,
  input          io_in_vsie_LC42IE,
  input          io_in_vsie_HPRASEIE,
  input          io_in_vsie_LC44IE,
  input          io_in_vsie_LC45IE,
  input          io_in_vsie_LC46IE,
  input          io_in_vsie_LC47IE,
  input          io_in_vsie_LC48IE,
  input          io_in_vsie_LC49IE,
  input          io_in_vsie_LC50IE,
  input          io_in_vsie_LC51IE,
  input          io_in_vsie_LC52IE,
  input          io_in_vsie_LC53IE,
  input          io_in_vsie_LC54IE,
  input          io_in_vsie_LC55IE,
  input          io_in_vsie_LC56IE,
  input          io_in_vsie_LC57IE,
  input          io_in_vsie_LC58IE,
  input          io_in_vsie_LC59IE,
  input          io_in_vsie_LC60IE,
  input          io_in_vsie_LC61IE,
  input          io_in_vsie_LC62IE,
  input          io_in_vsie_LC63IE,
  input          io_in_hvictl_VTI,
  input  [11:0]  io_in_hvictl_IID,
  input          io_in_hvictl_DPR,
  input          io_in_hvictl_IPRIOM,
  input  [7:0]   io_in_hvictl_IPRIO,
  input  [5:0]   io_in_hstatus_VGEIN,
  input  [10:0]  io_in_mtopei_IPRIO,
  input  [10:0]  io_in_stopei_IPRIO,
  input  [10:0]  io_in_vstopei_IID,
  input  [10:0]  io_in_vstopei_IPRIO,
  input  [7:0]   io_in_hviprio1_PrioSSI,
  input  [7:0]   io_in_hviprio1_PrioSTI,
  input  [7:0]   io_in_hviprio1_PrioCOI,
  input  [7:0]   io_in_hviprio1_Prio14,
  input  [7:0]   io_in_hviprio1_Prio15,
  input  [63:0]  io_in_hviprio2_ALL,
  input          io_in_debugIntr,
  input          io_in_debugMode,
  input          io_in_dcsr_STEPIE,
  input          io_in_dcsr_STEP,
  input  [511:0] io_in_miprios,
  input  [511:0] io_in_hsiprios,
  input          io_in_nmi,
  input  [63:0]  io_in_nmiVec,
  input          io_in_mnstatusNMIE,
  input          io_in_platform_meip,
  input          io_in_platform_seip,
  input          io_in_fromAIA_meip,
  input          io_in_fromAIA_seip,
  output         io_out_debug,
  output         io_out_nmi,
  output         io_out_interruptVec_valid,
  output [7:0]   io_out_interruptVec_bits,
  output [11:0]  io_out_mtopi_IID,
  output [7:0]   io_out_mtopi_IPRIO,
  output [11:0]  io_out_stopi_IID,
  output [7:0]   io_out_stopi_IPRIO,
  output [11:0]  io_out_vstopi_IID,
  output [7:0]   io_out_vstopi_IPRIO,
  output         io_out_virtualInterruptIsHvictlInject,
  output         io_out_irToHS,
  output         io_out_irToVS
);

  wire [7:0]  iprioC1Tmp;
  wire        _delayedIRToVS_delay_io_out;
  wire        _delayedIRToHS_delay_io_out;
  wire        _delayedVIIsHvictlInjectReg_delay_io_out;
  wire        _delayedNMI_delay_io_out;
  wire        _delayedDebugIntr_delay_io_out;
  wire [7:0]  _delayedIntrVec_delay_io_out;
  wire        PrvmIsS = 1'h0;
  wire        hsIRVecTmp_v_PrvmIsM = 1'h0;
  wire        vsIRVecTmp_v_PrvmIsM = 1'h0;
  wire        vsIRVecTmp_isModeHS = 1'h0;
  wire        vsIRModeCond_v_PrvmIsM = 1'h0;
  wire        vsIRModeCond_isModeHS = 1'h0;
  wire        mIRVecTmp_v_PrvmIsM_1 = 1'h1;
  wire        PrvmIsS_2 = 1'h1;
  wire        PrvmIsS_3 = 1'h1;
  wire        PrvmIsS_4 = 1'h1;
  wire        platformValid = io_in_platform_meip | io_in_platform_seip;
  wire [63:0] hsip =
    {io_in_sip_LC63IP,
     io_in_sip_LC62IP,
     io_in_sip_LC61IP,
     io_in_sip_LC60IP,
     io_in_sip_LC59IP,
     io_in_sip_LC58IP,
     io_in_sip_LC57IP,
     io_in_sip_LC56IP,
     io_in_sip_LC55IP,
     io_in_sip_LC54IP,
     io_in_sip_LC53IP,
     io_in_sip_LC52IP,
     io_in_sip_LC51IP,
     io_in_sip_LC50IP,
     io_in_sip_LC49IP,
     io_in_sip_LC48IP,
     io_in_sip_LC47IP,
     io_in_sip_LC46IP,
     io_in_sip_LC45IP,
     io_in_sip_LC44IP,
     io_in_sip_HPRASEIP,
     io_in_sip_LC42IP,
     io_in_sip_LC41IP,
     io_in_sip_LC40IP,
     io_in_sip_LC39IP,
     io_in_sip_LC38IP,
     io_in_sip_LC37IP,
     io_in_sip_LC36IP,
     io_in_sip_LPRASEIP,
     io_in_sip_LC34IP,
     io_in_sip_LC33IP,
     io_in_sip_LC32IP,
     io_in_sip_LC31IP,
     io_in_sip_LC30IP,
     io_in_sip_LC29IP,
     io_in_sip_LC28IP,
     io_in_sip_LC27IP,
     io_in_sip_LC26IP,
     io_in_sip_LC25IP,
     io_in_sip_LC24IP,
     io_in_sip_LC23IP,
     io_in_sip_LC22IP,
     io_in_sip_LC21IP,
     io_in_sip_LC20IP,
     io_in_sip_LC19IP,
     io_in_sip_LC18IP,
     io_in_sip_LC17IP,
     io_in_sip_LC16IP,
     io_in_sip_LC15IP,
     io_in_sip_LC14IP,
     io_in_sip_LCOFIP,
     io_in_hip_SGEIP,
     1'h0,
     io_in_hip_VSEIP,
     io_in_sip_SEIP,
     2'h0,
     io_in_hip_VSTIP,
     io_in_sip_STIP,
     2'h0,
     io_in_hip_VSSIP,
     io_in_sip_SSIP,
     1'h0};
  wire [63:0] hsie =
    {io_in_sie_LC63IE,
     io_in_sie_LC62IE,
     io_in_sie_LC61IE,
     io_in_sie_LC60IE,
     io_in_sie_LC59IE,
     io_in_sie_LC58IE,
     io_in_sie_LC57IE,
     io_in_sie_LC56IE,
     io_in_sie_LC55IE,
     io_in_sie_LC54IE,
     io_in_sie_LC53IE,
     io_in_sie_LC52IE,
     io_in_sie_LC51IE,
     io_in_sie_LC50IE,
     io_in_sie_LC49IE,
     io_in_sie_LC48IE,
     io_in_sie_LC47IE,
     io_in_sie_LC46IE,
     io_in_sie_LC45IE,
     io_in_sie_LC44IE,
     io_in_sie_HPRASEIE,
     io_in_sie_LC42IE,
     io_in_sie_LC41IE,
     io_in_sie_LC40IE,
     io_in_sie_LC39IE,
     io_in_sie_LC38IE,
     io_in_sie_LC37IE,
     io_in_sie_LC36IE,
     io_in_sie_LPRASEIE,
     io_in_sie_LC34IE,
     io_in_sie_LC33IE,
     io_in_sie_LC32IE,
     io_in_sie_LC31IE,
     io_in_sie_LC30IE,
     io_in_sie_LC29IE,
     io_in_sie_LC28IE,
     io_in_sie_LC27IE,
     io_in_sie_LC26IE,
     io_in_sie_LC25IE,
     io_in_sie_LC24IE,
     io_in_sie_LC23IE,
     io_in_sie_LC22IE,
     io_in_sie_LC21IE,
     io_in_sie_LC20IE,
     io_in_sie_LC19IE,
     io_in_sie_LC18IE,
     io_in_sie_LC17IE,
     io_in_sie_LC16IE,
     io_in_sie_LC15IE,
     io_in_sie_LC14IE,
     io_in_sie_LCOFIE,
     io_in_hie_SGEIE,
     1'h0,
     io_in_hie_VSEIE,
     io_in_sie_SEIE,
     2'h0,
     io_in_hie_VSTIE,
     io_in_sie_STIE,
     2'h0,
     io_in_hie_VSSIE,
     io_in_sie_SSIE,
     1'h0};
  wire [12:0] mPendingMask =
    {io_in_mip_LCOFIP,
     io_in_mip_SGEIP,
     io_in_mip_MEIP,
     io_in_mip_VSEIP,
     io_in_mip_SEIP,
     1'h0,
     io_in_mip_MTIP,
     io_in_mip_VSTIP,
     io_in_mip_STIP,
     1'h0,
     io_in_mip_MSIP,
     io_in_mip_VSSIP,
     io_in_mip_SSIP}
    & {io_in_mie_LCOFIE,
       io_in_mie_SGEIE,
       io_in_mie_MEIE,
       io_in_mie_VSEIE,
       io_in_mie_SEIE,
       1'h0,
       io_in_mie_MTIE,
       io_in_mie_VSTIE,
       io_in_mie_STIE,
       1'h0,
       io_in_mie_MSIE,
       io_in_mie_VSSIE,
       io_in_mie_SSIE}
    & {~io_in_mideleg_LCOFI,
       3'h2,
       ~io_in_mideleg_SEI,
       3'h6,
       ~io_in_mideleg_STI,
       3'h6,
       ~io_in_mideleg_SSI};
  wire [6:0]  mPendingVec =
    {mPendingMask[12],
     mPendingMask[10],
     mPendingMask[8],
     mPendingMask[6],
     mPendingMask[4],
     mPendingMask[2],
     mPendingMask[0]};
  wire [63:0] hsPendingMask =
    hsip & hsie
    & {50'h3FFFFFFFFFFFF,
       ~io_in_hideleg_LCOFI,
       ~io_in_hideleg_SGEI,
       ~io_in_hideleg_MEI,
       ~io_in_hideleg_VSEI,
       ~io_in_hideleg_SEI,
       1'h1,
       ~io_in_hideleg_MTI,
       ~io_in_hideleg_VSTI,
       ~io_in_hideleg_STI,
       1'h1,
       ~io_in_hideleg_MSI,
       ~io_in_hideleg_VSSI,
       ~io_in_hideleg_SSI,
       1'h1};
  wire [62:0] vstopigather =
    {io_in_vsie_LC63IE,
     io_in_vsie_LC62IE,
     io_in_vsie_LC61IE,
     io_in_vsie_LC60IE,
     io_in_vsie_LC59IE,
     io_in_vsie_LC58IE,
     io_in_vsie_LC57IE,
     io_in_vsie_LC56IE,
     io_in_vsie_LC55IE,
     io_in_vsie_LC54IE,
     io_in_vsie_LC53IE,
     io_in_vsie_LC52IE,
     io_in_vsie_LC51IE,
     io_in_vsie_LC50IE,
     io_in_vsie_LC49IE,
     io_in_vsie_LC48IE,
     io_in_vsie_LC47IE,
     io_in_vsie_LC46IE,
     io_in_vsie_LC45IE,
     io_in_vsie_LC44IE,
     io_in_vsie_HPRASEIE,
     io_in_vsie_LC42IE,
     io_in_vsie_LC41IE,
     io_in_vsie_LC40IE,
     io_in_vsie_LC39IE,
     io_in_vsie_LC38IE,
     io_in_vsie_LC37IE,
     io_in_vsie_LC36IE,
     io_in_vsie_LPRASEIE,
     io_in_vsie_LC34IE,
     io_in_vsie_LC33IE,
     io_in_vsie_LC32IE,
     io_in_vsie_LC31IE,
     io_in_vsie_LC30IE,
     io_in_vsie_LC29IE,
     io_in_vsie_LC28IE,
     io_in_vsie_LC27IE,
     io_in_vsie_LC26IE,
     io_in_vsie_LC25IE,
     io_in_vsie_LC24IE,
     io_in_vsie_LC23IE,
     io_in_vsie_LC22IE,
     io_in_vsie_LC21IE,
     io_in_vsie_LC20IE,
     io_in_vsie_LC19IE,
     io_in_vsie_LC18IE,
     io_in_vsie_LC17IE,
     io_in_vsie_LC16IE,
     io_in_vsie_LC15IE,
     io_in_vsie_LC14IE,
     io_in_vsie_LCOFIE,
     3'h0,
     io_in_vsie_SEIE,
     3'h0,
     io_in_vsie_STIE,
     3'h0,
     io_in_vsie_SSIE}
    & {io_in_vsip_LC63IP,
       io_in_vsip_LC62IP,
       io_in_vsip_LC61IP,
       io_in_vsip_LC60IP,
       io_in_vsip_LC59IP,
       io_in_vsip_LC58IP,
       io_in_vsip_LC57IP,
       io_in_vsip_LC56IP,
       io_in_vsip_LC55IP,
       io_in_vsip_LC54IP,
       io_in_vsip_LC53IP,
       io_in_vsip_LC52IP,
       io_in_vsip_LC51IP,
       io_in_vsip_LC50IP,
       io_in_vsip_LC49IP,
       io_in_vsip_LC48IP,
       io_in_vsip_LC47IP,
       io_in_vsip_LC46IP,
       io_in_vsip_LC45IP,
       io_in_vsip_LC44IP,
       io_in_vsip_HPRASEIP,
       io_in_vsip_LC42IP,
       io_in_vsip_LC41IP,
       io_in_vsip_LC40IP,
       io_in_vsip_LC39IP,
       io_in_vsip_LC38IP,
       io_in_vsip_LC37IP,
       io_in_vsip_LC36IP,
       io_in_vsip_LPRASEIP,
       io_in_vsip_LC34IP,
       io_in_vsip_LC33IP,
       io_in_vsip_LC32IP,
       io_in_vsip_LC31IP,
       io_in_vsip_LC30IP,
       io_in_vsip_LC29IP,
       io_in_vsip_LC28IP,
       io_in_vsip_LC27IP,
       io_in_vsip_LC26IP,
       io_in_vsip_LC25IP,
       io_in_vsip_LC24IP,
       io_in_vsip_LC23IP,
       io_in_vsip_LC22IP,
       io_in_vsip_LC21IP,
       io_in_vsip_LC20IP,
       io_in_vsip_LC19IP,
       io_in_vsip_LC18IP,
       io_in_vsip_LC17IP,
       io_in_vsip_LC16IP,
       io_in_vsip_LC15IP,
       io_in_vsip_LC14IP,
       io_in_vsip_LCOFIP,
       7'h0,
       io_in_vsip_STIP,
       3'h0,
       io_in_vsip_SSIP};
  reg         flag;
  reg  [5:0]  mipriosReg_0_idx;
  reg         mipriosReg_0_enable;
  reg         mipriosReg_0_isZero;
  reg  [7:0]  mipriosReg_0_prioNum;
  reg  [5:0]  mipriosReg_1_idx;
  reg         mipriosReg_1_enable;
  reg         mipriosReg_1_isZero;
  reg  [7:0]  mipriosReg_1_prioNum;
  reg  [5:0]  mipriosReg_2_idx;
  reg         mipriosReg_2_enable;
  reg         mipriosReg_2_isZero;
  reg  [7:0]  mipriosReg_2_prioNum;
  reg  [5:0]  mipriosReg_3_idx;
  reg         mipriosReg_3_enable;
  reg         mipriosReg_3_isZero;
  reg         mipriosReg_3_greaterThan255;
  reg  [7:0]  mipriosReg_3_prioNum;
  reg  [5:0]  mipriosReg_4_idx;
  reg         mipriosReg_4_enable;
  reg         mipriosReg_4_isZero;
  reg  [7:0]  mipriosReg_4_prioNum;
  reg  [5:0]  mipriosReg_5_idx;
  reg         mipriosReg_5_enable;
  reg         mipriosReg_5_isZero;
  reg  [7:0]  mipriosReg_5_prioNum;
  reg  [5:0]  mipriosReg_6_idx;
  reg         mipriosReg_6_enable;
  reg         mipriosReg_6_isZero;
  reg  [7:0]  mipriosReg_6_prioNum;
  reg  [5:0]  mipriosReg_7_idx;
  reg         mipriosReg_7_enable;
  reg         mipriosReg_7_isZero;
  reg  [7:0]  mipriosReg_7_prioNum;
  reg  [5:0]  hsipriosReg_0_idx;
  reg         hsipriosReg_0_enable;
  reg         hsipriosReg_0_isZero;
  reg  [7:0]  hsipriosReg_0_prioNum;
  reg  [5:0]  hsipriosReg_1_idx;
  reg         hsipriosReg_1_enable;
  reg         hsipriosReg_1_isZero;
  reg  [7:0]  hsipriosReg_1_prioNum;
  reg  [5:0]  hsipriosReg_2_idx;
  reg         hsipriosReg_2_enable;
  reg         hsipriosReg_2_isZero;
  reg  [7:0]  hsipriosReg_2_prioNum;
  reg  [5:0]  hsipriosReg_3_idx;
  reg         hsipriosReg_3_enable;
  reg         hsipriosReg_3_isZero;
  reg         hsipriosReg_3_greaterThan255;
  reg  [7:0]  hsipriosReg_3_prioNum;
  reg  [5:0]  hsipriosReg_4_idx;
  reg         hsipriosReg_4_enable;
  reg         hsipriosReg_4_isZero;
  reg  [7:0]  hsipriosReg_4_prioNum;
  reg  [5:0]  hsipriosReg_5_idx;
  reg         hsipriosReg_5_enable;
  reg         hsipriosReg_5_isZero;
  reg  [7:0]  hsipriosReg_5_prioNum;
  reg  [5:0]  hsipriosReg_6_idx;
  reg         hsipriosReg_6_enable;
  reg         hsipriosReg_6_isZero;
  reg  [7:0]  hsipriosReg_6_prioNum;
  reg  [5:0]  hsipriosReg_7_idx;
  reg         hsipriosReg_7_enable;
  reg         hsipriosReg_7_isZero;
  reg  [7:0]  hsipriosReg_7_prioNum;
  reg  [5:0]  hvipriosReg_0_idx;
  reg         hvipriosReg_0_enable;
  reg         hvipriosReg_0_isZero;
  reg  [7:0]  hvipriosReg_0_prioNum;
  reg  [5:0]  hvipriosReg_1_idx;
  reg         hvipriosReg_1_enable;
  reg         hvipriosReg_1_isZero;
  reg  [7:0]  hvipriosReg_1_prioNum;
  reg  [5:0]  hvipriosReg_2_idx;
  reg         hvipriosReg_2_enable;
  reg         hvipriosReg_2_isZero;
  reg  [7:0]  hvipriosReg_2_prioNum;
  reg  [5:0]  hvipriosReg_3_idx;
  reg         hvipriosReg_3_enable;
  reg         hvipriosReg_3_isZero;
  reg  [7:0]  hvipriosReg_3_prioNum;
  reg  [5:0]  hvipriosReg_4_idx;
  reg         hvipriosReg_4_enable;
  reg         hvipriosReg_4_isZero;
  reg  [7:0]  hvipriosReg_4_prioNum;
  reg  [5:0]  hvipriosReg_5_idx;
  reg         hvipriosReg_5_enable;
  reg         hvipriosReg_5_isZero;
  reg  [7:0]  hvipriosReg_5_prioNum;
  reg  [5:0]  hvipriosReg_6_idx;
  reg         hvipriosReg_6_enable;
  reg         hvipriosReg_6_isZero;
  reg  [7:0]  hvipriosReg_6_prioNum;
  reg  [5:0]  hvipriosReg_7_idx;
  reg         hvipriosReg_7_enable;
  reg         hvipriosReg_7_isZero;

  // priority merge node: mipriosRegTmp_result_leftIprio_leftIprio
  wire [7:0] mipriosRegTmp_result_leftIprio_leftIprio_0_prioNum;
  wire       mipriosRegTmp_result_leftIprio_leftIprio_0_isZero;
  wire       mipriosRegTmp_result_leftIprio_leftIprio_0_enable;
  wire [5:0] mipriosRegTmp_result_leftIprio_leftIprio_0_idx;
  xs_iprio_merge #(.THRESH(6'h19)) mipriosRegTmp_result_leftIprio_leftIprio_node (
    .a_enable(mipriosReg_0_enable), .a_isZero(mipriosReg_0_isZero),
    .a_gt255(1'b0), .a_prio(mipriosReg_0_prioNum), .a_idx(mipriosReg_0_idx),
    .b_enable(mipriosReg_1_enable), .b_isZero(mipriosReg_1_isZero),
    .b_gt255(1'b0), .b_prio(mipriosReg_1_prioNum), .b_idx(mipriosReg_1_idx),
    .o_enable(mipriosRegTmp_result_leftIprio_leftIprio_0_enable), .o_isZero(mipriosRegTmp_result_leftIprio_leftIprio_0_isZero),
    .o_gt255(), .o_prio(mipriosRegTmp_result_leftIprio_leftIprio_0_prioNum), .o_idx(mipriosRegTmp_result_leftIprio_leftIprio_0_idx));

  // priority merge node: mipriosRegTmp_result_leftIprio_rightIprio
  wire [7:0] mipriosRegTmp_result_leftIprio_rightIprio_0_prioNum;
  wire       mipriosRegTmp_result_leftIprio_rightIprio_0_isZero;
  wire       mipriosRegTmp_result_leftIprio_rightIprio_0_enable;
  wire [5:0] mipriosRegTmp_result_leftIprio_rightIprio_0_idx;
  wire       mipriosRegTmp_result_leftIprio_rightIprio_0_greaterThan255;
  xs_iprio_merge #(.THRESH(6'h19)) mipriosRegTmp_result_leftIprio_rightIprio_node (
    .a_enable(mipriosReg_2_enable), .a_isZero(mipriosReg_2_isZero),
    .a_gt255(1'b0), .a_prio(mipriosReg_2_prioNum), .a_idx(mipriosReg_2_idx),
    .b_enable(mipriosReg_3_enable), .b_isZero(mipriosReg_3_isZero),
    .b_gt255(mipriosReg_3_greaterThan255), .b_prio(mipriosReg_3_prioNum), .b_idx(mipriosReg_3_idx),
    .o_enable(mipriosRegTmp_result_leftIprio_rightIprio_0_enable), .o_isZero(mipriosRegTmp_result_leftIprio_rightIprio_0_isZero),
    .o_gt255(mipriosRegTmp_result_leftIprio_rightIprio_0_greaterThan255), .o_prio(mipriosRegTmp_result_leftIprio_rightIprio_0_prioNum), .o_idx(mipriosRegTmp_result_leftIprio_rightIprio_0_idx));

  // priority merge node: mipriosRegTmp_result_leftIprio
  wire [7:0] mipriosRegTmp_result_leftIprio_0_prioNum;
  wire       mipriosRegTmp_result_leftIprio_0_isZero;
  wire       mipriosRegTmp_result_leftIprio_0_enable;
  wire [5:0] mipriosRegTmp_result_leftIprio_0_idx;
  wire       mipriosRegTmp_result_leftIprio_0_greaterThan255;
  xs_iprio_merge #(.THRESH(6'h19)) mipriosRegTmp_result_leftIprio_node (
    .a_enable(mipriosRegTmp_result_leftIprio_leftIprio_0_enable), .a_isZero(mipriosRegTmp_result_leftIprio_leftIprio_0_isZero),
    .a_gt255(1'b0), .a_prio(mipriosRegTmp_result_leftIprio_leftIprio_0_prioNum), .a_idx(mipriosRegTmp_result_leftIprio_leftIprio_0_idx),
    .b_enable(mipriosRegTmp_result_leftIprio_rightIprio_0_enable), .b_isZero(mipriosRegTmp_result_leftIprio_rightIprio_0_isZero),
    .b_gt255(mipriosRegTmp_result_leftIprio_rightIprio_0_greaterThan255), .b_prio(mipriosRegTmp_result_leftIprio_rightIprio_0_prioNum), .b_idx(mipriosRegTmp_result_leftIprio_rightIprio_0_idx),
    .o_enable(mipriosRegTmp_result_leftIprio_0_enable), .o_isZero(mipriosRegTmp_result_leftIprio_0_isZero),
    .o_gt255(mipriosRegTmp_result_leftIprio_0_greaterThan255), .o_prio(mipriosRegTmp_result_leftIprio_0_prioNum), .o_idx(mipriosRegTmp_result_leftIprio_0_idx));

  // priority merge node: mipriosRegTmp_result_rightIprio_leftIprio
  wire [7:0] mipriosRegTmp_result_rightIprio_leftIprio_0_prioNum;
  wire       mipriosRegTmp_result_rightIprio_leftIprio_0_isZero;
  wire       mipriosRegTmp_result_rightIprio_leftIprio_0_enable;
  wire [5:0] mipriosRegTmp_result_rightIprio_leftIprio_0_idx;
  xs_iprio_merge #(.THRESH(6'h19)) mipriosRegTmp_result_rightIprio_leftIprio_node (
    .a_enable(mipriosReg_4_enable), .a_isZero(mipriosReg_4_isZero),
    .a_gt255(1'b0), .a_prio(mipriosReg_4_prioNum), .a_idx(mipriosReg_4_idx),
    .b_enable(mipriosReg_5_enable), .b_isZero(mipriosReg_5_isZero),
    .b_gt255(1'b0), .b_prio(mipriosReg_5_prioNum), .b_idx(mipriosReg_5_idx),
    .o_enable(mipriosRegTmp_result_rightIprio_leftIprio_0_enable), .o_isZero(mipriosRegTmp_result_rightIprio_leftIprio_0_isZero),
    .o_gt255(), .o_prio(mipriosRegTmp_result_rightIprio_leftIprio_0_prioNum), .o_idx(mipriosRegTmp_result_rightIprio_leftIprio_0_idx));

  // priority merge node: mipriosRegTmp_result_rightIprio_rightIprio
  wire [7:0] mipriosRegTmp_result_rightIprio_rightIprio_0_prioNum;
  wire       mipriosRegTmp_result_rightIprio_rightIprio_0_isZero;
  wire       mipriosRegTmp_result_rightIprio_rightIprio_0_enable;
  wire [5:0] mipriosRegTmp_result_rightIprio_rightIprio_0_idx;
  xs_iprio_merge #(.THRESH(6'h19)) mipriosRegTmp_result_rightIprio_rightIprio_node (
    .a_enable(mipriosReg_6_enable), .a_isZero(mipriosReg_6_isZero),
    .a_gt255(1'b0), .a_prio(mipriosReg_6_prioNum), .a_idx(mipriosReg_6_idx),
    .b_enable(mipriosReg_7_enable), .b_isZero(mipriosReg_7_isZero),
    .b_gt255(1'b0), .b_prio(mipriosReg_7_prioNum), .b_idx(mipriosReg_7_idx),
    .o_enable(mipriosRegTmp_result_rightIprio_rightIprio_0_enable), .o_isZero(mipriosRegTmp_result_rightIprio_rightIprio_0_isZero),
    .o_gt255(), .o_prio(mipriosRegTmp_result_rightIprio_rightIprio_0_prioNum), .o_idx(mipriosRegTmp_result_rightIprio_rightIprio_0_idx));

  // priority merge node: mipriosRegTmp_result_rightIprio
  wire [7:0] mipriosRegTmp_result_rightIprio_0_prioNum;
  wire       mipriosRegTmp_result_rightIprio_0_isZero;
  wire       mipriosRegTmp_result_rightIprio_0_enable;
  wire [5:0] mipriosRegTmp_result_rightIprio_0_idx;
  xs_iprio_merge #(.THRESH(6'h19)) mipriosRegTmp_result_rightIprio_node (
    .a_enable(mipriosRegTmp_result_rightIprio_leftIprio_0_enable), .a_isZero(mipriosRegTmp_result_rightIprio_leftIprio_0_isZero),
    .a_gt255(1'b0), .a_prio(mipriosRegTmp_result_rightIprio_leftIprio_0_prioNum), .a_idx(mipriosRegTmp_result_rightIprio_leftIprio_0_idx),
    .b_enable(mipriosRegTmp_result_rightIprio_rightIprio_0_enable), .b_isZero(mipriosRegTmp_result_rightIprio_rightIprio_0_isZero),
    .b_gt255(1'b0), .b_prio(mipriosRegTmp_result_rightIprio_rightIprio_0_prioNum), .b_idx(mipriosRegTmp_result_rightIprio_rightIprio_0_idx),
    .o_enable(mipriosRegTmp_result_rightIprio_0_enable), .o_isZero(mipriosRegTmp_result_rightIprio_0_isZero),
    .o_gt255(), .o_prio(mipriosRegTmp_result_rightIprio_0_prioNum), .o_idx(mipriosRegTmp_result_rightIprio_0_idx));
  wire        mipriosRegTmp_result_sel_1 =
    mipriosRegTmp_result_leftIprio_0_enable & ~mipriosRegTmp_result_rightIprio_0_enable;
  wire        mipriosRegTmp_result_sel_3 =
    ~mipriosRegTmp_result_leftIprio_0_enable & mipriosRegTmp_result_rightIprio_0_enable;
  wire        mipriosRegTmp_result_sel_4 =
    mipriosRegTmp_result_leftIprio_0_enable & mipriosRegTmp_result_rightIprio_0_enable;
  wire        mipriosRegTmp_result_sel_5 =
    mipriosRegTmp_result_leftIprio_0_isZero & mipriosRegTmp_result_rightIprio_0_isZero;
  wire        mipriosRegTmp_result_sel_7 =
    mipriosRegTmp_result_leftIprio_0_isZero & ~mipriosRegTmp_result_rightIprio_0_isZero;
  wire        mipriosRegTmp_result_sel_8 =
    mipriosRegTmp_result_leftIprio_0_idx < 6'h19;
  wire        mipriosRegTmp_result_sel_11 =
    ~mipriosRegTmp_result_leftIprio_0_isZero & mipriosRegTmp_result_rightIprio_0_isZero;
  wire        mipriosRegTmp_result_sel_12 =
    mipriosRegTmp_result_rightIprio_0_idx < 6'h19;
  wire        mipriosRegTmp_result_sel_16 =
    ~mipriosRegTmp_result_leftIprio_0_isZero & ~mipriosRegTmp_result_rightIprio_0_isZero;
  wire        mipriosRegTmp_result_sel_24 =
    mipriosRegTmp_result_leftIprio_0_prioNum <= mipriosRegTmp_result_rightIprio_0_prioNum;
  wire        mipriosRegTmp_result_0_greaterThan255 =
    mipriosRegTmp_result_sel_1 & mipriosRegTmp_result_leftIprio_0_greaterThan255
    | mipriosRegTmp_result_sel_4
    & (mipriosRegTmp_result_sel_5
       & mipriosRegTmp_result_leftIprio_0_greaterThan255
       | mipriosRegTmp_result_sel_7 & mipriosRegTmp_result_sel_8
       & mipriosRegTmp_result_leftIprio_0_greaterThan255
       | mipriosRegTmp_result_sel_11 & ~mipriosRegTmp_result_sel_12
       & mipriosRegTmp_result_leftIprio_0_greaterThan255);
  wire        mipriosRegTmp_result_0_isZero =
    mipriosRegTmp_result_sel_1 & mipriosRegTmp_result_leftIprio_0_isZero
    | mipriosRegTmp_result_sel_3 & mipriosRegTmp_result_rightIprio_0_isZero
    | mipriosRegTmp_result_sel_4
    & (mipriosRegTmp_result_sel_5 & mipriosRegTmp_result_leftIprio_0_isZero
       | mipriosRegTmp_result_sel_7
       & (mipriosRegTmp_result_sel_8
            ? mipriosRegTmp_result_leftIprio_0_isZero
            : mipriosRegTmp_result_rightIprio_0_isZero)
       | mipriosRegTmp_result_sel_11
       & (mipriosRegTmp_result_sel_12
            ? mipriosRegTmp_result_rightIprio_0_isZero
            : mipriosRegTmp_result_leftIprio_0_isZero)
       | mipriosRegTmp_result_sel_16
       & (mipriosRegTmp_result_leftIprio_0_greaterThan255
          & mipriosRegTmp_result_rightIprio_0_isZero
          | ~mipriosRegTmp_result_leftIprio_0_greaterThan255
          & (mipriosRegTmp_result_sel_24
               ? mipriosRegTmp_result_leftIprio_0_isZero
               : mipriosRegTmp_result_rightIprio_0_isZero)));
  wire [5:0]  mipriosRegTmp_result_0_idx =
    (mipriosRegTmp_result_sel_1 ? mipriosRegTmp_result_leftIprio_0_idx : 6'h0)
    | (mipriosRegTmp_result_sel_3 ? mipriosRegTmp_result_rightIprio_0_idx : 6'h0)
    | (mipriosRegTmp_result_sel_4
         ? (mipriosRegTmp_result_sel_5
              ? mipriosRegTmp_result_leftIprio_0_idx
              : 6'h0)
           | (mipriosRegTmp_result_sel_7
                ? (mipriosRegTmp_result_sel_8
                     ? mipriosRegTmp_result_leftIprio_0_idx
                     : mipriosRegTmp_result_rightIprio_0_idx)
                : 6'h0)
           | (mipriosRegTmp_result_sel_11
                ? (mipriosRegTmp_result_sel_12
                     ? mipriosRegTmp_result_rightIprio_0_idx
                     : mipriosRegTmp_result_leftIprio_0_idx)
                : 6'h0)
           | (mipriosRegTmp_result_sel_16
                ? (mipriosRegTmp_result_leftIprio_0_greaterThan255
                     ? mipriosRegTmp_result_rightIprio_0_idx
                     : 6'h0)
                  | (mipriosRegTmp_result_leftIprio_0_greaterThan255
                       ? 6'h0
                       : mipriosRegTmp_result_sel_24
                           ? mipriosRegTmp_result_leftIprio_0_idx
                           : mipriosRegTmp_result_rightIprio_0_idx)
                : 6'h0)
         : 6'h0);

  // priority merge node: hsipriosRegTmp_result_leftIprio_leftIprio
  wire [7:0] hsipriosRegTmp_result_leftIprio_leftIprio_0_prioNum;
  wire       hsipriosRegTmp_result_leftIprio_leftIprio_0_isZero;
  wire       hsipriosRegTmp_result_leftIprio_leftIprio_0_enable;
  wire [5:0] hsipriosRegTmp_result_leftIprio_leftIprio_0_idx;
  xs_iprio_merge #(.THRESH(6'h1C)) hsipriosRegTmp_result_leftIprio_leftIprio_node (
    .a_enable(hsipriosReg_0_enable), .a_isZero(hsipriosReg_0_isZero),
    .a_gt255(1'b0), .a_prio(hsipriosReg_0_prioNum), .a_idx(hsipriosReg_0_idx),
    .b_enable(hsipriosReg_1_enable), .b_isZero(hsipriosReg_1_isZero),
    .b_gt255(1'b0), .b_prio(hsipriosReg_1_prioNum), .b_idx(hsipriosReg_1_idx),
    .o_enable(hsipriosRegTmp_result_leftIprio_leftIprio_0_enable), .o_isZero(hsipriosRegTmp_result_leftIprio_leftIprio_0_isZero),
    .o_gt255(), .o_prio(hsipriosRegTmp_result_leftIprio_leftIprio_0_prioNum), .o_idx(hsipriosRegTmp_result_leftIprio_leftIprio_0_idx));

  // priority merge node: hsipriosRegTmp_result_leftIprio_rightIprio
  wire [7:0] hsipriosRegTmp_result_leftIprio_rightIprio_0_prioNum;
  wire       hsipriosRegTmp_result_leftIprio_rightIprio_0_isZero;
  wire       hsipriosRegTmp_result_leftIprio_rightIprio_0_enable;
  wire [5:0] hsipriosRegTmp_result_leftIprio_rightIprio_0_idx;
  wire       hsipriosRegTmp_result_leftIprio_rightIprio_0_greaterThan255;
  xs_iprio_merge #(.THRESH(6'h1C)) hsipriosRegTmp_result_leftIprio_rightIprio_node (
    .a_enable(hsipriosReg_2_enable), .a_isZero(hsipriosReg_2_isZero),
    .a_gt255(1'b0), .a_prio(hsipriosReg_2_prioNum), .a_idx(hsipriosReg_2_idx),
    .b_enable(hsipriosReg_3_enable), .b_isZero(hsipriosReg_3_isZero),
    .b_gt255(hsipriosReg_3_greaterThan255), .b_prio(hsipriosReg_3_prioNum), .b_idx(hsipriosReg_3_idx),
    .o_enable(hsipriosRegTmp_result_leftIprio_rightIprio_0_enable), .o_isZero(hsipriosRegTmp_result_leftIprio_rightIprio_0_isZero),
    .o_gt255(hsipriosRegTmp_result_leftIprio_rightIprio_0_greaterThan255), .o_prio(hsipriosRegTmp_result_leftIprio_rightIprio_0_prioNum), .o_idx(hsipriosRegTmp_result_leftIprio_rightIprio_0_idx));

  // priority merge node: hsipriosRegTmp_result_leftIprio
  wire [7:0] hsipriosRegTmp_result_leftIprio_0_prioNum;
  wire       hsipriosRegTmp_result_leftIprio_0_isZero;
  wire       hsipriosRegTmp_result_leftIprio_0_enable;
  wire [5:0] hsipriosRegTmp_result_leftIprio_0_idx;
  wire       hsipriosRegTmp_result_leftIprio_0_greaterThan255;
  xs_iprio_merge #(.THRESH(6'h1C)) hsipriosRegTmp_result_leftIprio_node (
    .a_enable(hsipriosRegTmp_result_leftIprio_leftIprio_0_enable), .a_isZero(hsipriosRegTmp_result_leftIprio_leftIprio_0_isZero),
    .a_gt255(1'b0), .a_prio(hsipriosRegTmp_result_leftIprio_leftIprio_0_prioNum), .a_idx(hsipriosRegTmp_result_leftIprio_leftIprio_0_idx),
    .b_enable(hsipriosRegTmp_result_leftIprio_rightIprio_0_enable), .b_isZero(hsipriosRegTmp_result_leftIprio_rightIprio_0_isZero),
    .b_gt255(hsipriosRegTmp_result_leftIprio_rightIprio_0_greaterThan255), .b_prio(hsipriosRegTmp_result_leftIprio_rightIprio_0_prioNum), .b_idx(hsipriosRegTmp_result_leftIprio_rightIprio_0_idx),
    .o_enable(hsipriosRegTmp_result_leftIprio_0_enable), .o_isZero(hsipriosRegTmp_result_leftIprio_0_isZero),
    .o_gt255(hsipriosRegTmp_result_leftIprio_0_greaterThan255), .o_prio(hsipriosRegTmp_result_leftIprio_0_prioNum), .o_idx(hsipriosRegTmp_result_leftIprio_0_idx));

  // priority merge node: hsipriosRegTmp_result_rightIprio_leftIprio
  wire [7:0] hsipriosRegTmp_result_rightIprio_leftIprio_0_prioNum;
  wire       hsipriosRegTmp_result_rightIprio_leftIprio_0_isZero;
  wire       hsipriosRegTmp_result_rightIprio_leftIprio_0_enable;
  wire [5:0] hsipriosRegTmp_result_rightIprio_leftIprio_0_idx;
  xs_iprio_merge #(.THRESH(6'h1C)) hsipriosRegTmp_result_rightIprio_leftIprio_node (
    .a_enable(hsipriosReg_4_enable), .a_isZero(hsipriosReg_4_isZero),
    .a_gt255(1'b0), .a_prio(hsipriosReg_4_prioNum), .a_idx(hsipriosReg_4_idx),
    .b_enable(hsipriosReg_5_enable), .b_isZero(hsipriosReg_5_isZero),
    .b_gt255(1'b0), .b_prio(hsipriosReg_5_prioNum), .b_idx(hsipriosReg_5_idx),
    .o_enable(hsipriosRegTmp_result_rightIprio_leftIprio_0_enable), .o_isZero(hsipriosRegTmp_result_rightIprio_leftIprio_0_isZero),
    .o_gt255(), .o_prio(hsipriosRegTmp_result_rightIprio_leftIprio_0_prioNum), .o_idx(hsipriosRegTmp_result_rightIprio_leftIprio_0_idx));

  // priority merge node: hsipriosRegTmp_result_rightIprio_rightIprio
  wire [7:0] hsipriosRegTmp_result_rightIprio_rightIprio_0_prioNum;
  wire       hsipriosRegTmp_result_rightIprio_rightIprio_0_isZero;
  wire       hsipriosRegTmp_result_rightIprio_rightIprio_0_enable;
  wire [5:0] hsipriosRegTmp_result_rightIprio_rightIprio_0_idx;
  xs_iprio_merge #(.THRESH(6'h1C)) hsipriosRegTmp_result_rightIprio_rightIprio_node (
    .a_enable(hsipriosReg_6_enable), .a_isZero(hsipriosReg_6_isZero),
    .a_gt255(1'b0), .a_prio(hsipriosReg_6_prioNum), .a_idx(hsipriosReg_6_idx),
    .b_enable(hsipriosReg_7_enable), .b_isZero(hsipriosReg_7_isZero),
    .b_gt255(1'b0), .b_prio(hsipriosReg_7_prioNum), .b_idx(hsipriosReg_7_idx),
    .o_enable(hsipriosRegTmp_result_rightIprio_rightIprio_0_enable), .o_isZero(hsipriosRegTmp_result_rightIprio_rightIprio_0_isZero),
    .o_gt255(), .o_prio(hsipriosRegTmp_result_rightIprio_rightIprio_0_prioNum), .o_idx(hsipriosRegTmp_result_rightIprio_rightIprio_0_idx));

  // priority merge node: hsipriosRegTmp_result_rightIprio
  wire [7:0] hsipriosRegTmp_result_rightIprio_0_prioNum;
  wire       hsipriosRegTmp_result_rightIprio_0_isZero;
  wire       hsipriosRegTmp_result_rightIprio_0_enable;
  wire [5:0] hsipriosRegTmp_result_rightIprio_0_idx;
  xs_iprio_merge #(.THRESH(6'h1C)) hsipriosRegTmp_result_rightIprio_node (
    .a_enable(hsipriosRegTmp_result_rightIprio_leftIprio_0_enable), .a_isZero(hsipriosRegTmp_result_rightIprio_leftIprio_0_isZero),
    .a_gt255(1'b0), .a_prio(hsipriosRegTmp_result_rightIprio_leftIprio_0_prioNum), .a_idx(hsipriosRegTmp_result_rightIprio_leftIprio_0_idx),
    .b_enable(hsipriosRegTmp_result_rightIprio_rightIprio_0_enable), .b_isZero(hsipriosRegTmp_result_rightIprio_rightIprio_0_isZero),
    .b_gt255(1'b0), .b_prio(hsipriosRegTmp_result_rightIprio_rightIprio_0_prioNum), .b_idx(hsipriosRegTmp_result_rightIprio_rightIprio_0_idx),
    .o_enable(hsipriosRegTmp_result_rightIprio_0_enable), .o_isZero(hsipriosRegTmp_result_rightIprio_0_isZero),
    .o_gt255(), .o_prio(hsipriosRegTmp_result_rightIprio_0_prioNum), .o_idx(hsipriosRegTmp_result_rightIprio_0_idx));
  wire        hsipriosRegTmp_result_sel_1 =
    hsipriosRegTmp_result_leftIprio_0_enable & ~hsipriosRegTmp_result_rightIprio_0_enable;
  wire        hsipriosRegTmp_result_sel_3 =
    ~hsipriosRegTmp_result_leftIprio_0_enable & hsipriosRegTmp_result_rightIprio_0_enable;
  wire        hsipriosRegTmp_result_sel_4 =
    hsipriosRegTmp_result_leftIprio_0_enable & hsipriosRegTmp_result_rightIprio_0_enable;
  wire        hsipriosRegTmp_result_sel_5 =
    hsipriosRegTmp_result_leftIprio_0_isZero & hsipriosRegTmp_result_rightIprio_0_isZero;
  wire        hsipriosRegTmp_result_sel_7 =
    hsipriosRegTmp_result_leftIprio_0_isZero & ~hsipriosRegTmp_result_rightIprio_0_isZero;
  wire        hsipriosRegTmp_result_sel_8 =
    hsipriosRegTmp_result_leftIprio_0_idx < 6'h1C;
  wire        hsipriosRegTmp_result_sel_11 =
    ~hsipriosRegTmp_result_leftIprio_0_isZero & hsipriosRegTmp_result_rightIprio_0_isZero;
  wire        hsipriosRegTmp_result_sel_12 =
    hsipriosRegTmp_result_rightIprio_0_idx < 6'h1C;
  wire        hsipriosRegTmp_result_sel_16 =
    ~hsipriosRegTmp_result_leftIprio_0_isZero
    & ~hsipriosRegTmp_result_rightIprio_0_isZero;
  wire        hsipriosRegTmp_result_sel_24 =
    hsipriosRegTmp_result_leftIprio_0_prioNum <= hsipriosRegTmp_result_rightIprio_0_prioNum;
  wire        hsipriosRegTmp_result_0_greaterThan255 =
    hsipriosRegTmp_result_sel_1 & hsipriosRegTmp_result_leftIprio_0_greaterThan255
    | hsipriosRegTmp_result_sel_4
    & (hsipriosRegTmp_result_sel_5
       & hsipriosRegTmp_result_leftIprio_0_greaterThan255
       | hsipriosRegTmp_result_sel_7 & hsipriosRegTmp_result_sel_8
       & hsipriosRegTmp_result_leftIprio_0_greaterThan255
       | hsipriosRegTmp_result_sel_11 & ~hsipriosRegTmp_result_sel_12
       & hsipriosRegTmp_result_leftIprio_0_greaterThan255);
  wire        hsipriosRegTmp_result_0_isZero =
    hsipriosRegTmp_result_sel_1 & hsipriosRegTmp_result_leftIprio_0_isZero
    | hsipriosRegTmp_result_sel_3 & hsipriosRegTmp_result_rightIprio_0_isZero
    | hsipriosRegTmp_result_sel_4
    & (hsipriosRegTmp_result_sel_5 & hsipriosRegTmp_result_leftIprio_0_isZero
       | hsipriosRegTmp_result_sel_7
       & (hsipriosRegTmp_result_sel_8
            ? hsipriosRegTmp_result_leftIprio_0_isZero
            : hsipriosRegTmp_result_rightIprio_0_isZero)
       | hsipriosRegTmp_result_sel_11
       & (hsipriosRegTmp_result_sel_12
            ? hsipriosRegTmp_result_rightIprio_0_isZero
            : hsipriosRegTmp_result_leftIprio_0_isZero)
       | hsipriosRegTmp_result_sel_16
       & (hsipriosRegTmp_result_leftIprio_0_greaterThan255
          & hsipriosRegTmp_result_rightIprio_0_isZero
          | ~hsipriosRegTmp_result_leftIprio_0_greaterThan255
          & (hsipriosRegTmp_result_sel_24
               ? hsipriosRegTmp_result_leftIprio_0_isZero
               : hsipriosRegTmp_result_rightIprio_0_isZero)));
  wire [5:0]  hsipriosRegTmp_result_0_idx =
    (hsipriosRegTmp_result_sel_1 ? hsipriosRegTmp_result_leftIprio_0_idx : 6'h0)
    | (hsipriosRegTmp_result_sel_3
         ? hsipriosRegTmp_result_rightIprio_0_idx
         : 6'h0)
    | (hsipriosRegTmp_result_sel_4
         ? (hsipriosRegTmp_result_sel_5
              ? hsipriosRegTmp_result_leftIprio_0_idx
              : 6'h0)
           | (hsipriosRegTmp_result_sel_7
                ? (hsipriosRegTmp_result_sel_8
                     ? hsipriosRegTmp_result_leftIprio_0_idx
                     : hsipriosRegTmp_result_rightIprio_0_idx)
                : 6'h0)
           | (hsipriosRegTmp_result_sel_11
                ? (hsipriosRegTmp_result_sel_12
                     ? hsipriosRegTmp_result_rightIprio_0_idx
                     : hsipriosRegTmp_result_leftIprio_0_idx)
                : 6'h0)
           | (hsipriosRegTmp_result_sel_16
                ? (hsipriosRegTmp_result_leftIprio_0_greaterThan255
                     ? hsipriosRegTmp_result_rightIprio_0_idx
                     : 6'h0)
                  | (hsipriosRegTmp_result_leftIprio_0_greaterThan255
                       ? 6'h0
                       : hsipriosRegTmp_result_sel_24
                           ? hsipriosRegTmp_result_leftIprio_0_idx
                           : hsipriosRegTmp_result_rightIprio_0_idx)
                : 6'h0)
         : 6'h0);

  // priority merge node: hvipriosRegTmp_result_leftIprio_leftIprio
  wire [7:0] hvipriosRegTmp_result_leftIprio_leftIprio_0_prioNum;
  wire       hvipriosRegTmp_result_leftIprio_leftIprio_0_isZero;
  wire       hvipriosRegTmp_result_leftIprio_leftIprio_0_enable;
  wire [5:0] hvipriosRegTmp_result_leftIprio_leftIprio_0_idx;
  xs_iprio_merge #(.THRESH(6'h20)) hvipriosRegTmp_result_leftIprio_leftIprio_node (
    .a_enable(hvipriosReg_0_enable), .a_isZero(hvipriosReg_0_isZero),
    .a_gt255(1'b0), .a_prio(hvipriosReg_0_prioNum), .a_idx(hvipriosReg_0_idx),
    .b_enable(hvipriosReg_1_enable), .b_isZero(hvipriosReg_1_isZero),
    .b_gt255(1'b0), .b_prio(hvipriosReg_1_prioNum), .b_idx(hvipriosReg_1_idx),
    .o_enable(hvipriosRegTmp_result_leftIprio_leftIprio_0_enable), .o_isZero(hvipriosRegTmp_result_leftIprio_leftIprio_0_isZero),
    .o_gt255(), .o_prio(hvipriosRegTmp_result_leftIprio_leftIprio_0_prioNum), .o_idx(hvipriosRegTmp_result_leftIprio_leftIprio_0_idx));

  // priority merge node: hvipriosRegTmp_result_leftIprio_rightIprio
  wire [7:0] hvipriosRegTmp_result_leftIprio_rightIprio_0_prioNum;
  wire       hvipriosRegTmp_result_leftIprio_rightIprio_0_isZero;
  wire       hvipriosRegTmp_result_leftIprio_rightIprio_0_enable;
  wire [5:0] hvipriosRegTmp_result_leftIprio_rightIprio_0_idx;
  xs_iprio_merge #(.THRESH(6'h20)) hvipriosRegTmp_result_leftIprio_rightIprio_node (
    .a_enable(hvipriosReg_2_enable), .a_isZero(hvipriosReg_2_isZero),
    .a_gt255(1'b0), .a_prio(hvipriosReg_2_prioNum), .a_idx(hvipriosReg_2_idx),
    .b_enable(hvipriosReg_3_enable), .b_isZero(hvipriosReg_3_isZero),
    .b_gt255(1'b0), .b_prio(hvipriosReg_3_prioNum), .b_idx(hvipriosReg_3_idx),
    .o_enable(hvipriosRegTmp_result_leftIprio_rightIprio_0_enable), .o_isZero(hvipriosRegTmp_result_leftIprio_rightIprio_0_isZero),
    .o_gt255(), .o_prio(hvipriosRegTmp_result_leftIprio_rightIprio_0_prioNum), .o_idx(hvipriosRegTmp_result_leftIprio_rightIprio_0_idx));

  // priority merge node: hvipriosRegTmp_result_leftIprio
  wire [7:0] hvipriosRegTmp_result_leftIprio_0_prioNum;
  wire       hvipriosRegTmp_result_leftIprio_0_isZero;
  wire       hvipriosRegTmp_result_leftIprio_0_enable;
  wire [5:0] hvipriosRegTmp_result_leftIprio_0_idx;
  xs_iprio_merge #(.THRESH(6'h20)) hvipriosRegTmp_result_leftIprio_node (
    .a_enable(hvipriosRegTmp_result_leftIprio_leftIprio_0_enable), .a_isZero(hvipriosRegTmp_result_leftIprio_leftIprio_0_isZero),
    .a_gt255(1'b0), .a_prio(hvipriosRegTmp_result_leftIprio_leftIprio_0_prioNum), .a_idx(hvipriosRegTmp_result_leftIprio_leftIprio_0_idx),
    .b_enable(hvipriosRegTmp_result_leftIprio_rightIprio_0_enable), .b_isZero(hvipriosRegTmp_result_leftIprio_rightIprio_0_isZero),
    .b_gt255(1'b0), .b_prio(hvipriosRegTmp_result_leftIprio_rightIprio_0_prioNum), .b_idx(hvipriosRegTmp_result_leftIprio_rightIprio_0_idx),
    .o_enable(hvipriosRegTmp_result_leftIprio_0_enable), .o_isZero(hvipriosRegTmp_result_leftIprio_0_isZero),
    .o_gt255(), .o_prio(hvipriosRegTmp_result_leftIprio_0_prioNum), .o_idx(hvipriosRegTmp_result_leftIprio_0_idx));

  // priority merge node: hvipriosRegTmp_result_rightIprio_leftIprio
  wire [7:0] hvipriosRegTmp_result_rightIprio_leftIprio_0_prioNum;
  wire       hvipriosRegTmp_result_rightIprio_leftIprio_0_isZero;
  wire       hvipriosRegTmp_result_rightIprio_leftIprio_0_enable;
  wire [5:0] hvipriosRegTmp_result_rightIprio_leftIprio_0_idx;
  xs_iprio_merge #(.THRESH(6'h20)) hvipriosRegTmp_result_rightIprio_leftIprio_node (
    .a_enable(hvipriosReg_4_enable), .a_isZero(hvipriosReg_4_isZero),
    .a_gt255(1'b0), .a_prio(hvipriosReg_4_prioNum), .a_idx(hvipriosReg_4_idx),
    .b_enable(hvipriosReg_5_enable), .b_isZero(hvipriosReg_5_isZero),
    .b_gt255(1'b0), .b_prio(hvipriosReg_5_prioNum), .b_idx(hvipriosReg_5_idx),
    .o_enable(hvipriosRegTmp_result_rightIprio_leftIprio_0_enable), .o_isZero(hvipriosRegTmp_result_rightIprio_leftIprio_0_isZero),
    .o_gt255(), .o_prio(hvipriosRegTmp_result_rightIprio_leftIprio_0_prioNum), .o_idx(hvipriosRegTmp_result_rightIprio_leftIprio_0_idx));

  // priority merge node: hvipriosRegTmp_result_rightIprio_rightIprio
  wire [7:0] hvipriosRegTmp_result_rightIprio_rightIprio_0_prioNum;
  wire       hvipriosRegTmp_result_rightIprio_rightIprio_0_isZero;
  wire       hvipriosRegTmp_result_rightIprio_rightIprio_0_enable;
  wire [5:0] hvipriosRegTmp_result_rightIprio_rightIprio_0_idx;
  xs_iprio_merge #(.THRESH(6'h20)) hvipriosRegTmp_result_rightIprio_rightIprio_node (
    .a_enable(hvipriosReg_6_enable), .a_isZero(hvipriosReg_6_isZero),
    .a_gt255(1'b0), .a_prio(hvipriosReg_6_prioNum), .a_idx(hvipriosReg_6_idx),
    .b_enable(hvipriosReg_7_enable), .b_isZero(hvipriosReg_7_isZero),
    .b_gt255(1'b0), .b_prio(8'h0), .b_idx(hvipriosReg_7_idx),
    .o_enable(hvipriosRegTmp_result_rightIprio_rightIprio_0_enable), .o_isZero(hvipriosRegTmp_result_rightIprio_rightIprio_0_isZero),
    .o_gt255(), .o_prio(hvipriosRegTmp_result_rightIprio_rightIprio_0_prioNum), .o_idx(hvipriosRegTmp_result_rightIprio_rightIprio_0_idx));

  // priority merge node: hvipriosRegTmp_result_rightIprio
  wire [7:0] hvipriosRegTmp_result_rightIprio_0_prioNum;
  wire       hvipriosRegTmp_result_rightIprio_0_isZero;
  wire       hvipriosRegTmp_result_rightIprio_0_enable;
  wire [5:0] hvipriosRegTmp_result_rightIprio_0_idx;
  xs_iprio_merge #(.THRESH(6'h20)) hvipriosRegTmp_result_rightIprio_node (
    .a_enable(hvipriosRegTmp_result_rightIprio_leftIprio_0_enable), .a_isZero(hvipriosRegTmp_result_rightIprio_leftIprio_0_isZero),
    .a_gt255(1'b0), .a_prio(hvipriosRegTmp_result_rightIprio_leftIprio_0_prioNum), .a_idx(hvipriosRegTmp_result_rightIprio_leftIprio_0_idx),
    .b_enable(hvipriosRegTmp_result_rightIprio_rightIprio_0_enable), .b_isZero(hvipriosRegTmp_result_rightIprio_rightIprio_0_isZero),
    .b_gt255(1'b0), .b_prio(hvipriosRegTmp_result_rightIprio_rightIprio_0_prioNum), .b_idx(hvipriosRegTmp_result_rightIprio_rightIprio_0_idx),
    .o_enable(hvipriosRegTmp_result_rightIprio_0_enable), .o_isZero(hvipriosRegTmp_result_rightIprio_0_isZero),
    .o_gt255(), .o_prio(hvipriosRegTmp_result_rightIprio_0_prioNum), .o_idx(hvipriosRegTmp_result_rightIprio_0_idx));

  // priority merge node: hvipriosRegTmp_result
  wire [7:0] hvipriosRegTmp_result_0_prioNum;
  wire       hvipriosRegTmp_result_0_isZero;
  wire       hvipriosRegTmp_result_0_enable;
  wire [5:0] hvipriosRegTmp_result_0_idx;
  xs_iprio_merge #(.THRESH(6'h20)) hvipriosRegTmp_result_node (
    .a_enable(hvipriosRegTmp_result_leftIprio_0_enable), .a_isZero(hvipriosRegTmp_result_leftIprio_0_isZero),
    .a_gt255(1'b0), .a_prio(hvipriosRegTmp_result_leftIprio_0_prioNum), .a_idx(hvipriosRegTmp_result_leftIprio_0_idx),
    .b_enable(hvipriosRegTmp_result_rightIprio_0_enable), .b_isZero(hvipriosRegTmp_result_rightIprio_0_isZero),
    .b_gt255(1'b0), .b_prio(hvipriosRegTmp_result_rightIprio_0_prioNum), .b_idx(hvipriosRegTmp_result_rightIprio_0_idx),
    .o_enable(hvipriosRegTmp_result_0_enable), .o_isZero(hvipriosRegTmp_result_0_isZero),
    .o_gt255(), .o_prio(hvipriosRegTmp_result_0_prioNum), .o_idx(hvipriosRegTmp_result_0_idx));
  wire        mIidDec_1 = mipriosRegTmp_result_0_idx == 6'h0;
  wire [5:0]  mIidDec_125 =
    {mIidDec_1,
     {5{mIidDec_1}} | {5{mipriosRegTmp_result_0_idx == 6'h1}}}
    | (mipriosRegTmp_result_0_idx == 6'h2 ? 6'h3E : 6'h0)
    | (mipriosRegTmp_result_0_idx == 6'h3 ? 6'h3D : 6'h0);
  wire [5:0]  mIidDec_128 =
    {mIidDec_125[5],
     mIidDec_125[4:0] | (mipriosRegTmp_result_0_idx == 6'h4 ? 5'h1E : 5'h0)}
    | (mipriosRegTmp_result_0_idx == 6'h5 ? 6'h3C : 6'h0)
    | (mipriosRegTmp_result_0_idx == 6'h6 ? 6'h2F : 6'h0);
  wire [5:0]  mIidDec_131 =
    {mIidDec_128[5],
     mIidDec_128[4:0] | (mipriosRegTmp_result_0_idx == 6'h7 ? 5'h17 : 5'h0)}
    | (mipriosRegTmp_result_0_idx == 6'h8 ? 6'h2E : 6'h0)
    | (mipriosRegTmp_result_0_idx == 6'h9 ? 6'h2D : 6'h0);
  wire [5:0]  mIidDec_134 =
    {mIidDec_131[5],
     mIidDec_131[4:0] | (mipriosRegTmp_result_0_idx == 6'hA ? 5'h16 : 5'h0)}
    | (mipriosRegTmp_result_0_idx == 6'hB ? 6'h2C : 6'h0)
    | (mipriosRegTmp_result_0_idx == 6'hC ? 6'h2B : 6'h0);
  wire [5:0]  mIidDec_137 =
    {mIidDec_134[5],
     mIidDec_134[4:0] | (mipriosRegTmp_result_0_idx == 6'hD ? 5'h15 : 5'h0)}
    | (mipriosRegTmp_result_0_idx == 6'hE ? 6'h2A : 6'h0)
    | (mipriosRegTmp_result_0_idx == 6'hF ? 6'h29 : 6'h0);
  wire [5:0]  mIidDec_140 =
    {mIidDec_137[5],
     mIidDec_137[4:0] | (mipriosRegTmp_result_0_idx == 6'h10 ? 5'h14 : 5'h0)}
    | (mipriosRegTmp_result_0_idx == 6'h11 ? 6'h28 : 6'h0)
    | (mipriosRegTmp_result_0_idx == 6'h12 ? 6'h3B : 6'h0);
  wire [5:0]  mIidDec_143 =
    {mIidDec_140[5],
     mIidDec_140[4:0] | (mipriosRegTmp_result_0_idx == 6'h13 ? 5'h1D : 5'h0)}
    | (mipriosRegTmp_result_0_idx == 6'h14 ? 6'h3A : 6'h0)
    | (mipriosRegTmp_result_0_idx == 6'h15 ? 6'h39 : 6'h0);
  wire [5:0]  mIidDec_145 =
    {mIidDec_143[5],
     mIidDec_143[4:0] | (mipriosRegTmp_result_0_idx == 6'h16 ? 5'h1C : 5'h0)}
    | (mipriosRegTmp_result_0_idx == 6'h17 ? 6'h38 : 6'h0);
  wire [3:0]  gGen_1 =
    mIidDec_145[3:0] | (mipriosRegTmp_result_0_idx == 6'h18 ? 4'hB : 4'h0);
  wire [3:0]  gGen_2 =
    {gGen_1[3],
     {gGen_1[2], gGen_1[1:0] | {2{mipriosRegTmp_result_0_idx == 6'h19}}}
       | {3{mipriosRegTmp_result_0_idx == 6'h1A}}}
    | (mipriosRegTmp_result_0_idx == 6'h1B ? 4'h9 : 4'h0);
  wire [3:0]  gGen_3 =
    {gGen_2[3],
     {gGen_2[2:1], gGen_2[0] | mipriosRegTmp_result_0_idx == 6'h1C}
       | (mipriosRegTmp_result_0_idx == 6'h1D ? 3'h5 : 3'h0)}
    | (mipriosRegTmp_result_0_idx == 6'h1E ? 4'hC : 4'h0)
    | (mipriosRegTmp_result_0_idx == 6'h1F ? 4'hA : 4'h0);
  wire [5:0]  mIidDec_159 =
    {mIidDec_145[5:4],
     {gGen_3[3],
      {gGen_3[2], gGen_3[1:0] | {mipriosRegTmp_result_0_idx == 6'h20, 1'h0}}
        | (mipriosRegTmp_result_0_idx == 6'h21 ? 3'h6 : 3'h0)}
       | (mipriosRegTmp_result_0_idx == 6'h22 ? 4'hD : 4'h0)
       | (mipriosRegTmp_result_0_idx == 6'h23 ? 4'hE : 4'h0)
       | {4{mipriosRegTmp_result_0_idx == 6'h24}}}
    | (mipriosRegTmp_result_0_idx == 6'h25 ? 6'h37 : 6'h0);
  wire [5:0]  mIidDec_162 =
    {mIidDec_159[5],
     mIidDec_159[4:0] | (mipriosRegTmp_result_0_idx == 6'h26 ? 5'h1B : 5'h0)}
    | (mipriosRegTmp_result_0_idx == 6'h27 ? 6'h36 : 6'h0)
    | (mipriosRegTmp_result_0_idx == 6'h28 ? 6'h35 : 6'h0);
  wire [5:0]  mIidDec_165 =
    {mIidDec_162[5],
     mIidDec_162[4:0] | (mipriosRegTmp_result_0_idx == 6'h29 ? 5'h1A : 5'h0)}
    | (mipriosRegTmp_result_0_idx == 6'h2A ? 6'h34 : 6'h0)
    | (mipriosRegTmp_result_0_idx == 6'h2B ? 6'h27 : 6'h0);
  wire [5:0]  mIidDec_168 =
    {mIidDec_165[5],
     mIidDec_165[4:0] | (mipriosRegTmp_result_0_idx == 6'h2C ? 5'h13 : 5'h0)}
    | (mipriosRegTmp_result_0_idx == 6'h2D ? 6'h26 : 6'h0)
    | (mipriosRegTmp_result_0_idx == 6'h2E ? 6'h25 : 6'h0);
  wire [5:0]  mIidDec_171 =
    {mIidDec_168[5],
     mIidDec_168[4:0] | (mipriosRegTmp_result_0_idx == 6'h2F ? 5'h12 : 5'h0)}
    | (mipriosRegTmp_result_0_idx == 6'h30 ? 6'h24 : 6'h0)
    | (mipriosRegTmp_result_0_idx == 6'h31 ? 6'h23 : 6'h0);
  wire [5:0]  mIidDec_174 =
    {mIidDec_171[5],
     mIidDec_171[4:0] | (mipriosRegTmp_result_0_idx == 6'h32 ? 5'h11 : 5'h0)}
    | (mipriosRegTmp_result_0_idx == 6'h33 ? 6'h22 : 6'h0)
    | (mipriosRegTmp_result_0_idx == 6'h34 ? 6'h21 : 6'h0);
  wire [5:0]  mIidDec_177 =
    {mIidDec_174[5] | mipriosRegTmp_result_0_idx == 6'h36,
     mIidDec_174[4:0] | {mipriosRegTmp_result_0_idx == 6'h35, 4'h0}}
    | (mipriosRegTmp_result_0_idx == 6'h37 ? 6'h33 : 6'h0);
  wire [5:0]  mIidDec_180 =
    {mIidDec_177[5],
     mIidDec_177[4:0] | (mipriosRegTmp_result_0_idx == 6'h38 ? 5'h19 : 5'h0)}
    | (mipriosRegTmp_result_0_idx == 6'h39 ? 6'h32 : 6'h0)
    | (mipriosRegTmp_result_0_idx == 6'h3A ? 6'h31 : 6'h0);
  wire        hsIidDec_1 = hsipriosRegTmp_result_0_idx == 6'h0;
  wire [5:0]  hsIidDec_125 =
    {hsIidDec_1,
     {5{hsIidDec_1}} | {5{hsipriosRegTmp_result_0_idx == 6'h1}}}
    | (hsipriosRegTmp_result_0_idx == 6'h2 ? 6'h3E : 6'h0)
    | (hsipriosRegTmp_result_0_idx == 6'h3 ? 6'h3D : 6'h0);
  wire [5:0]  hsIidDec_128 =
    {hsIidDec_125[5],
     hsIidDec_125[4:0] | (hsipriosRegTmp_result_0_idx == 6'h4 ? 5'h1E : 5'h0)}
    | (hsipriosRegTmp_result_0_idx == 6'h5 ? 6'h3C : 6'h0)
    | (hsipriosRegTmp_result_0_idx == 6'h6 ? 6'h2F : 6'h0);
  wire [5:0]  hsIidDec_131 =
    {hsIidDec_128[5],
     hsIidDec_128[4:0] | (hsipriosRegTmp_result_0_idx == 6'h7 ? 5'h17 : 5'h0)}
    | (hsipriosRegTmp_result_0_idx == 6'h8 ? 6'h2E : 6'h0)
    | (hsipriosRegTmp_result_0_idx == 6'h9 ? 6'h2D : 6'h0);
  wire [5:0]  hsIidDec_134 =
    {hsIidDec_131[5],
     hsIidDec_131[4:0] | (hsipriosRegTmp_result_0_idx == 6'hA ? 5'h16 : 5'h0)}
    | (hsipriosRegTmp_result_0_idx == 6'hB ? 6'h2C : 6'h0)
    | (hsipriosRegTmp_result_0_idx == 6'hC ? 6'h2B : 6'h0);
  wire [5:0]  hsIidDec_137 =
    {hsIidDec_134[5],
     hsIidDec_134[4:0] | (hsipriosRegTmp_result_0_idx == 6'hD ? 5'h15 : 5'h0)}
    | (hsipriosRegTmp_result_0_idx == 6'hE ? 6'h2A : 6'h0)
    | (hsipriosRegTmp_result_0_idx == 6'hF ? 6'h29 : 6'h0);
  wire [5:0]  hsIidDec_140 =
    {hsIidDec_137[5],
     hsIidDec_137[4:0] | (hsipriosRegTmp_result_0_idx == 6'h10 ? 5'h14 : 5'h0)}
    | (hsipriosRegTmp_result_0_idx == 6'h11 ? 6'h28 : 6'h0)
    | (hsipriosRegTmp_result_0_idx == 6'h12 ? 6'h3B : 6'h0);
  wire [5:0]  hsIidDec_143 =
    {hsIidDec_140[5],
     hsIidDec_140[4:0] | (hsipriosRegTmp_result_0_idx == 6'h13 ? 5'h1D : 5'h0)}
    | (hsipriosRegTmp_result_0_idx == 6'h14 ? 6'h3A : 6'h0)
    | (hsipriosRegTmp_result_0_idx == 6'h15 ? 6'h39 : 6'h0);
  wire [5:0]  hsIidDec_145 =
    {hsIidDec_143[5],
     hsIidDec_143[4:0] | (hsipriosRegTmp_result_0_idx == 6'h16 ? 5'h1C : 5'h0)}
    | (hsipriosRegTmp_result_0_idx == 6'h17 ? 6'h38 : 6'h0);
  wire [3:0]  gGen_4 =
    hsIidDec_145[3:0] | (hsipriosRegTmp_result_0_idx == 6'h18 ? 4'hB : 4'h0);
  wire [3:0]  gGen_5 =
    {gGen_4[3],
     {gGen_4[2], gGen_4[1:0] | {2{hsipriosRegTmp_result_0_idx == 6'h19}}}
       | {3{hsipriosRegTmp_result_0_idx == 6'h1A}}}
    | (hsipriosRegTmp_result_0_idx == 6'h1B ? 4'h9 : 4'h0);
  wire [3:0]  gGen_6 =
    {gGen_5[3],
     {gGen_5[2:1], gGen_5[0] | hsipriosRegTmp_result_0_idx == 6'h1C}
       | (hsipriosRegTmp_result_0_idx == 6'h1D ? 3'h5 : 3'h0)}
    | (hsipriosRegTmp_result_0_idx == 6'h1E ? 4'hC : 4'h0)
    | (hsipriosRegTmp_result_0_idx == 6'h1F ? 4'hA : 4'h0);
  wire [5:0]  hsIidDec_159 =
    {hsIidDec_145[5:4],
     {gGen_6[3],
      {gGen_6[2], gGen_6[1:0] | {hsipriosRegTmp_result_0_idx == 6'h20, 1'h0}}
        | (hsipriosRegTmp_result_0_idx == 6'h21 ? 3'h6 : 3'h0)}
       | (hsipriosRegTmp_result_0_idx == 6'h22 ? 4'hD : 4'h0)
       | (hsipriosRegTmp_result_0_idx == 6'h23 ? 4'hE : 4'h0)
       | {4{hsipriosRegTmp_result_0_idx == 6'h24}}}
    | (hsipriosRegTmp_result_0_idx == 6'h25 ? 6'h37 : 6'h0);
  wire [5:0]  hsIidDec_162 =
    {hsIidDec_159[5],
     hsIidDec_159[4:0] | (hsipriosRegTmp_result_0_idx == 6'h26 ? 5'h1B : 5'h0)}
    | (hsipriosRegTmp_result_0_idx == 6'h27 ? 6'h36 : 6'h0)
    | (hsipriosRegTmp_result_0_idx == 6'h28 ? 6'h35 : 6'h0);
  wire [5:0]  hsIidDec_165 =
    {hsIidDec_162[5],
     hsIidDec_162[4:0] | (hsipriosRegTmp_result_0_idx == 6'h29 ? 5'h1A : 5'h0)}
    | (hsipriosRegTmp_result_0_idx == 6'h2A ? 6'h34 : 6'h0)
    | (hsipriosRegTmp_result_0_idx == 6'h2B ? 6'h27 : 6'h0);
  wire [5:0]  hsIidDec_168 =
    {hsIidDec_165[5],
     hsIidDec_165[4:0] | (hsipriosRegTmp_result_0_idx == 6'h2C ? 5'h13 : 5'h0)}
    | (hsipriosRegTmp_result_0_idx == 6'h2D ? 6'h26 : 6'h0)
    | (hsipriosRegTmp_result_0_idx == 6'h2E ? 6'h25 : 6'h0);
  wire [5:0]  hsIidDec_171 =
    {hsIidDec_168[5],
     hsIidDec_168[4:0] | (hsipriosRegTmp_result_0_idx == 6'h2F ? 5'h12 : 5'h0)}
    | (hsipriosRegTmp_result_0_idx == 6'h30 ? 6'h24 : 6'h0)
    | (hsipriosRegTmp_result_0_idx == 6'h31 ? 6'h23 : 6'h0);
  wire [5:0]  hsIidDec_174 =
    {hsIidDec_171[5],
     hsIidDec_171[4:0] | (hsipriosRegTmp_result_0_idx == 6'h32 ? 5'h11 : 5'h0)}
    | (hsipriosRegTmp_result_0_idx == 6'h33 ? 6'h22 : 6'h0)
    | (hsipriosRegTmp_result_0_idx == 6'h34 ? 6'h21 : 6'h0);
  wire [5:0]  hsIidDec_177 =
    {hsIidDec_174[5] | hsipriosRegTmp_result_0_idx == 6'h36,
     hsIidDec_174[4:0] | {hsipriosRegTmp_result_0_idx == 6'h35, 4'h0}}
    | (hsipriosRegTmp_result_0_idx == 6'h37 ? 6'h33 : 6'h0);
  wire [5:0]  hsIidDec_180 =
    {hsIidDec_177[5],
     hsIidDec_177[4:0] | (hsipriosRegTmp_result_0_idx == 6'h38 ? 5'h19 : 5'h0)}
    | (hsipriosRegTmp_result_0_idx == 6'h39 ? 6'h32 : 6'h0)
    | (hsipriosRegTmp_result_0_idx == 6'h3A ? 6'h31 : 6'h0);
  wire [5:0]  hsIidNum =
    {hsIidDec_180[5],
     hsIidDec_180[4:0] | (hsipriosRegTmp_result_0_idx == 6'h3B ? 5'h18 : 5'h0)}
    | (hsipriosRegTmp_result_0_idx == 6'h3C ? 6'h30 : 6'h0);
  wire        vsIidDec_1 = hvipriosRegTmp_result_0_idx == 6'h0;
  wire [5:0]  vsIidDec_125 =
    {vsIidDec_1,
     {5{vsIidDec_1}} | {5{hvipriosRegTmp_result_0_idx == 6'h1}}}
    | (hvipriosRegTmp_result_0_idx == 6'h2 ? 6'h3E : 6'h0)
    | (hvipriosRegTmp_result_0_idx == 6'h3 ? 6'h3D : 6'h0);
  wire [5:0]  vsIidDec_128 =
    {vsIidDec_125[5],
     vsIidDec_125[4:0] | (hvipriosRegTmp_result_0_idx == 6'h4 ? 5'h1E : 5'h0)}
    | (hvipriosRegTmp_result_0_idx == 6'h5 ? 6'h3C : 6'h0)
    | (hvipriosRegTmp_result_0_idx == 6'h6 ? 6'h2F : 6'h0);
  wire [5:0]  vsIidDec_131 =
    {vsIidDec_128[5],
     vsIidDec_128[4:0] | (hvipriosRegTmp_result_0_idx == 6'h7 ? 5'h17 : 5'h0)}
    | (hvipriosRegTmp_result_0_idx == 6'h8 ? 6'h2E : 6'h0)
    | (hvipriosRegTmp_result_0_idx == 6'h9 ? 6'h2D : 6'h0);
  wire [5:0]  vsIidDec_134 =
    {vsIidDec_131[5],
     vsIidDec_131[4:0] | (hvipriosRegTmp_result_0_idx == 6'hA ? 5'h16 : 5'h0)}
    | (hvipriosRegTmp_result_0_idx == 6'hB ? 6'h2C : 6'h0)
    | (hvipriosRegTmp_result_0_idx == 6'hC ? 6'h2B : 6'h0);
  wire [5:0]  vsIidDec_137 =
    {vsIidDec_134[5],
     vsIidDec_134[4:0] | (hvipriosRegTmp_result_0_idx == 6'hD ? 5'h15 : 5'h0)}
    | (hvipriosRegTmp_result_0_idx == 6'hE ? 6'h2A : 6'h0)
    | (hvipriosRegTmp_result_0_idx == 6'hF ? 6'h29 : 6'h0);
  wire [5:0]  vsIidDec_140 =
    {vsIidDec_137[5],
     vsIidDec_137[4:0] | (hvipriosRegTmp_result_0_idx == 6'h10 ? 5'h14 : 5'h0)}
    | (hvipriosRegTmp_result_0_idx == 6'h11 ? 6'h28 : 6'h0)
    | (hvipriosRegTmp_result_0_idx == 6'h12 ? 6'h3B : 6'h0);
  wire [5:0]  vsIidDec_143 =
    {vsIidDec_140[5],
     vsIidDec_140[4:0] | (hvipriosRegTmp_result_0_idx == 6'h13 ? 5'h1D : 5'h0)}
    | (hvipriosRegTmp_result_0_idx == 6'h14 ? 6'h3A : 6'h0)
    | (hvipriosRegTmp_result_0_idx == 6'h15 ? 6'h39 : 6'h0);
  wire [5:0]  vsIidDec_145 =
    {vsIidDec_143[5],
     vsIidDec_143[4:0] | (hvipriosRegTmp_result_0_idx == 6'h16 ? 5'h1C : 5'h0)}
    | (hvipriosRegTmp_result_0_idx == 6'h17 ? 6'h38 : 6'h0);
  wire [3:0]  gGen_7 =
    vsIidDec_145[3:0] | (hvipriosRegTmp_result_0_idx == 6'h18 ? 4'hB : 4'h0);
  wire [3:0]  gGen_8 =
    {gGen_7[3],
     {gGen_7[2], gGen_7[1:0] | {2{hvipriosRegTmp_result_0_idx == 6'h19}}}
       | {3{hvipriosRegTmp_result_0_idx == 6'h1A}}}
    | (hvipriosRegTmp_result_0_idx == 6'h1B ? 4'h9 : 4'h0);
  wire [3:0]  gGen_9 =
    {gGen_8[3],
     {gGen_8[2:1], gGen_8[0] | hvipriosRegTmp_result_0_idx == 6'h1C}
       | (hvipriosRegTmp_result_0_idx == 6'h1D ? 3'h5 : 3'h0)}
    | (hvipriosRegTmp_result_0_idx == 6'h1E ? 4'hC : 4'h0)
    | (hvipriosRegTmp_result_0_idx == 6'h1F ? 4'hA : 4'h0);
  wire [5:0]  vsIidDec_159 =
    {vsIidDec_145[5:4],
     {gGen_9[3],
      {gGen_9[2], gGen_9[1:0] | {hvipriosRegTmp_result_0_idx == 6'h20, 1'h0}}
        | (hvipriosRegTmp_result_0_idx == 6'h21 ? 3'h6 : 3'h0)}
       | (hvipriosRegTmp_result_0_idx == 6'h22 ? 4'hD : 4'h0)
       | (hvipriosRegTmp_result_0_idx == 6'h23 ? 4'hE : 4'h0)
       | {4{hvipriosRegTmp_result_0_idx == 6'h24}}}
    | (hvipriosRegTmp_result_0_idx == 6'h25 ? 6'h37 : 6'h0);
  wire [5:0]  vsIidDec_162 =
    {vsIidDec_159[5],
     vsIidDec_159[4:0] | (hvipriosRegTmp_result_0_idx == 6'h26 ? 5'h1B : 5'h0)}
    | (hvipriosRegTmp_result_0_idx == 6'h27 ? 6'h36 : 6'h0)
    | (hvipriosRegTmp_result_0_idx == 6'h28 ? 6'h35 : 6'h0);
  wire [5:0]  vsIidDec_165 =
    {vsIidDec_162[5],
     vsIidDec_162[4:0] | (hvipriosRegTmp_result_0_idx == 6'h29 ? 5'h1A : 5'h0)}
    | (hvipriosRegTmp_result_0_idx == 6'h2A ? 6'h34 : 6'h0)
    | (hvipriosRegTmp_result_0_idx == 6'h2B ? 6'h27 : 6'h0);
  wire [5:0]  vsIidDec_168 =
    {vsIidDec_165[5],
     vsIidDec_165[4:0] | (hvipriosRegTmp_result_0_idx == 6'h2C ? 5'h13 : 5'h0)}
    | (hvipriosRegTmp_result_0_idx == 6'h2D ? 6'h26 : 6'h0)
    | (hvipriosRegTmp_result_0_idx == 6'h2E ? 6'h25 : 6'h0);
  wire [5:0]  vsIidDec_171 =
    {vsIidDec_168[5],
     vsIidDec_168[4:0] | (hvipriosRegTmp_result_0_idx == 6'h2F ? 5'h12 : 5'h0)}
    | (hvipriosRegTmp_result_0_idx == 6'h30 ? 6'h24 : 6'h0)
    | (hvipriosRegTmp_result_0_idx == 6'h31 ? 6'h23 : 6'h0);
  wire [5:0]  vsIidDec_174 =
    {vsIidDec_171[5],
     vsIidDec_171[4:0] | (hvipriosRegTmp_result_0_idx == 6'h32 ? 5'h11 : 5'h0)}
    | (hvipriosRegTmp_result_0_idx == 6'h33 ? 6'h22 : 6'h0)
    | (hvipriosRegTmp_result_0_idx == 6'h34 ? 6'h21 : 6'h0);
  wire [5:0]  vsIidDec_177 =
    {vsIidDec_174[5] | hvipriosRegTmp_result_0_idx == 6'h36,
     vsIidDec_174[4:0] | {hvipriosRegTmp_result_0_idx == 6'h35, 4'h0}}
    | (hvipriosRegTmp_result_0_idx == 6'h37 ? 6'h33 : 6'h0);
  wire [5:0]  vsIidDec_180 =
    {vsIidDec_177[5],
     vsIidDec_177[4:0] | (hvipriosRegTmp_result_0_idx == 6'h38 ? 5'h19 : 5'h0)}
    | (hvipriosRegTmp_result_0_idx == 6'h39 ? 6'h32 : 6'h0)
    | (hvipriosRegTmp_result_0_idx == 6'h3A ? 6'h31 : 6'h0);
  wire [11:0] mtopiIidWire =
    {6'h0,
     (|mPendingVec)
       ? {mIidDec_180[5],
          mIidDec_180[4:0]
            | (mipriosRegTmp_result_0_idx == 6'h3B ? 5'h18 : 5'h0)}
         | (mipriosRegTmp_result_0_idx == 6'h3C ? 6'h30 : 6'h0)
       : 6'h0};
  wire [11:0] stopiIidWire = {6'h0, (|hsPendingMask) ? hsIidNum : 6'h0};
  wire        Candidate1 =
    io_in_vsip_SEIP & io_in_vsie_SEIE & (|io_in_hstatus_VGEIN)
    & (|{io_in_vstopei_IID, io_in_vstopei_IPRIO});
  wire        Candidate2 =
    io_in_vsip_SEIP & io_in_vsie_SEIE & io_in_hstatus_VGEIN == 6'h0
    & io_in_hvictl_IID == 12'h9 & (|io_in_hvictl_IPRIO);
  wire        Candidate3 = io_in_vsip_SEIP & io_in_vsie_SEIE & ~Candidate1 & ~Candidate2;
  wire        Candidate4 =
    ~io_in_hvictl_VTI & (|{vstopigather[62:12], vstopigather[4], vstopigather[0]});
  wire        Candidate5 = io_in_hvictl_VTI & io_in_hvictl_IID != 12'h9;
  wire        CandidateNoValid =
    ~Candidate1 & ~Candidate2 & ~Candidate3 & ~Candidate4 & ~Candidate5;
  wire        Candidate123 = Candidate1 | Candidate2 | Candidate3;
  wire        Candidate45 = Candidate4 | Candidate5;
  wire        onlyC4Enable = Candidate4 & ~Candidate123;
  wire        onlyC5Enable = Candidate5 & ~Candidate123;
  wire        C1C4Enable = Candidate1 & Candidate4;
  wire        C1C5Enable = Candidate1 & Candidate5;
  wire        C2C4Enable = Candidate2 & Candidate4;
  wire        C3C4Enable = Candidate3 & Candidate4;
  wire        C3C5Enable = Candidate3 & Candidate5;
  wire [11:0] iidOnlyC4 =
    {6'h0,
     {vsIidDec_180[5],
      vsIidDec_180[4:0] | (hvipriosRegTmp_result_0_idx == 6'h3B ? 5'h18 : 5'h0)}
       | (hvipriosRegTmp_result_0_idx == 6'h3C ? 6'h30 : 6'h0)};
  wire [11:0] iidC4Idx = {6'h0, hvipriosRegTmp_result_0_idx};
  wire        C4IsZero = hvipriosRegTmp_result_0_prioNum == 8'h0;
  wire        C2C5IsZero = io_in_hvictl_IPRIO == 8'h0;
  wire        C4HighVSEI = iidC4Idx < 12'h1F;
  wire        SEIHighC4 = iidC4Idx > 12'h1B;
  wire [7:0]  iprioOnlyC1 = (|(io_in_vstopei_IPRIO[10:8])) ? 8'hFF : iprioC1Tmp;
  wire [10:0] iprioC2C5 = {3'h0, io_in_hvictl_IPRIO};
  wire [10:0] iprioC4 = {3'h0, hvipriosRegTmp_result_0_prioNum};
  assign iprioC1Tmp = io_in_vstopei_IPRIO[7:0];
  wire [7:0]  iprioC4Tmp =
    C4IsZero ? (C4HighVSEI ? 8'h0 : 8'hFF) : hvipriosRegTmp_result_0_prioNum;
  wire [7:0]  iprioC3C5Tmp = C2C5IsZero ? {8{io_in_hvictl_DPR}} : io_in_hvictl_IPRIO;
  wire        vstopeiLtC4 = io_in_vstopei_IPRIO < iprioC4;
  wire        vstopeiEqC4 = io_in_vstopei_IPRIO == iprioC4;
  wire        vstopeiLtC2C5 = io_in_vstopei_IPRIO < iprioC2C5;
  wire        vstopeiEqC2C5 = io_in_vstopei_IPRIO == iprioC2C5;
  wire        hvictlLtC4 = io_in_hvictl_IPRIO < hvipriosRegTmp_result_0_prioNum;
  wire        hvictlEqC4 = io_in_hvictl_IPRIO == hvipriosRegTmp_result_0_prioNum;
  wire [11:0] vsInjectedIID =
    (Candidate123 & ~Candidate45 ? 12'h9 : 12'h0) | (onlyC4Enable ? iidOnlyC4 : 12'h0)
    | (onlyC5Enable ? io_in_hvictl_IID : 12'h0)
    | (C1C4Enable
         ? (C4IsZero
              ? (C4HighVSEI ? iidOnlyC4 : 12'h9)
              : vstopeiLtC4 | vstopeiEqC4 & SEIHighC4 ? 12'h9 : iidOnlyC4)
         : 12'h0)
    | (C1C5Enable
         ? ((C2C5IsZero ? io_in_hvictl_DPR : vstopeiLtC2C5 | vstopeiEqC2C5 & io_in_hvictl_DPR)
              ? 12'h9
              : io_in_hvictl_IID)
         : 12'h0)
    | (C2C4Enable
         ? (C4IsZero
              ? (C4HighVSEI ? iidOnlyC4 : 12'h9)
              : hvictlLtC4 | hvictlEqC4 & SEIHighC4 ? 12'h9 : iidOnlyC4)
         : 12'h0) | (C3C4Enable ? (~C4IsZero | C4HighVSEI ? iidOnlyC4 : 12'h9) : 12'h0)
    | (C3C5Enable ? (~C2C5IsZero | io_in_hvictl_DPR ? io_in_hvictl_IID : 12'h9) : 12'h0);
  wire        mIRVecTmp_v_PrvmIsM = &io_in_privState_PRVM;
  wire        mIRVecTmp_isModeM = mIRVecTmp_v_PrvmIsM;
  wire        mIRVecTmp_isModeM_1 = mIRVecTmp_v_PrvmIsM_1;
  wire        mIRVecTmp_isModeHS = PrvmIsS;
  wire [11:0] mIRVecTmp =
    mIRVecTmp_isModeM & io_in_mstatusMIE | io_in_privState_V
    & (mIRVecTmp_isModeM_1 | mIRVecTmp_isModeHS) | ~io_in_privState_V
    & io_in_privState_PRVM != 2'h3
      ? mtopiIidWire
      : 12'h0;
  wire        PrvmIsS_1 = io_in_privState_PRVM == 2'h1;
  wire        hsIRVecTmp_isModeHS = ~io_in_privState_V & PrvmIsS_1;
  wire        hsIRVecTmp_isModeM = hsIRVecTmp_v_PrvmIsM;
  wire        hsIRVecTmp_isModeHS_1 = PrvmIsS_2;
  wire        hsModeCanTake =
    hsIRVecTmp_isModeHS & io_in_sstatusSIE | io_in_privState_V
    & (hsIRVecTmp_isModeM | hsIRVecTmp_isModeHS_1) | ~io_in_privState_V
    & io_in_privState_PRVM == 2'h0;
  wire [5:0]  hsIRVecTmp = hsModeCanTake & (|hsPendingMask) ? hsIidNum : 6'h0;
  wire        vsIRVecTmp_isModeVS = io_in_privState_V & PrvmIsS_1;
  wire        vsIRModeCond = vsIRVecTmp_isModeVS & io_in_vsstatusSIE;
  wire        vsIRVecTmp_isModeM = vsIRVecTmp_v_PrvmIsM;
  wire [11:0] vsIRVecTmp =
    ~(vsIRModeCond | io_in_privState_V & (vsIRVecTmp_isModeM | vsIRVecTmp_isModeHS)
      | io_in_privState_V & io_in_privState_PRVM == 2'h0) | CandidateNoValid
      ? 12'h0
      : vsInjectedIID;
  wire        irToVS_pre = mIRVecTmp == 12'h0;
  wire        irToHS = irToVS_pre & (|hsIRVecTmp);
  wire        irToVS = irToVS_pre & ~(|hsIRVecTmp) & (|vsIRVecTmp);
  wire [11:0] hsIRVec = irToHS & hsModeCanTake ? stopiIidWire : 12'h0;
  wire [63:0] vsIRVec = irToVS ? 64'h1 << vsIRVecTmp[5:0] : 64'h0;
  wire [30:0] vsMapHostRdx_1 =
    vsIRVec[63:33]
    | {vsIRVec[31:11],
       vsIRVec[9],
       1'h0,
       vsIRVec[8:7],
       vsIRVec[5],
       1'h0,
       vsIRVec[4:3],
       vsIRVec[1],
       1'h0};
  wire [14:0] vsMapHostRdx_3 =
    vsMapHostRdx_1[30:16] | vsMapHostRdx_1[14:0];
  wire [6:0]  vsMapHostRdx_5 = vsMapHostRdx_3[14:8] | vsMapHostRdx_3[6:0];
  wire [2:0]  vsMapHostRdx_7 = vsMapHostRdx_5[6:4] | vsMapHostRdx_5[2:0];
  wire [5:0]  vsMapHostIRVec =
    {|(vsIRVec[63:32]),
     |(vsMapHostRdx_1[30:15]),
     |(vsMapHostRdx_3[14:7]),
     |(vsMapHostRdx_5[6:3]),
     |(vsMapHostRdx_7[2:1]),
     vsMapHostRdx_7[2] | vsMapHostRdx_7[0]};
  wire        nmiVecTmp_43 = io_in_nmiVec[43];
  wire        nmiVecTmp_31 = ~nmiVecTmp_43 & io_in_nmiVec[31];
  wire        vsIRModeCond_isModeM = vsIRModeCond_v_PrvmIsM;
  reg  [7:0]  intrVecReg;
  reg         debugIntrReg;
  reg         nmiReg;
  reg         viIsHvictlInjectReg;
  reg         irToHSReg;
  reg         irToVSReg;
  wire        disableDebugIntr = io_in_debugMode | io_in_dcsr_STEP & ~io_in_dcsr_STEPIE;
  wire [7:0]  normalIntrVec_hi = mIRVecTmp[7:0] | hsIRVec[7:0];
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      flag <= 1'h0;
      intrVecReg <= 8'h0;
      debugIntrReg <= 1'h0;
      nmiReg <= 1'h0;
      viIsHvictlInjectReg <= 1'h0;
      irToHSReg <= 1'h0;
      irToVSReg <= 1'h0;
    end
    else begin
      flag <= platformValid | ~(io_in_fromAIA_meip | io_in_fromAIA_seip) & flag;
      intrVecReg <=
        disableDebugIntr | ~io_in_mnstatusNMIE
          ? 8'h0
          : io_in_nmi
              ? {2'h0,
                 nmiVecTmp_43,
                 nmiVecTmp_31,
                 |{nmiVecTmp_31, nmiVecTmp_43},
                 nmiVecTmp_31,
                 {2{nmiVecTmp_31 | nmiVecTmp_43}}}
              : {normalIntrVec_hi[7:6], normalIntrVec_hi[5:0] | vsMapHostIRVec};
      debugIntrReg <= io_in_debugIntr & ~disableDebugIntr;
      nmiReg <= io_in_nmi;
      viIsHvictlInjectReg <=
        (vsIRModeCond | io_in_privState_V
         & (vsIRModeCond_isModeM | vsIRModeCond_isModeHS) | io_in_privState_V
         & io_in_privState_PRVM == 2'h0)
        & (onlyC5Enable | C3C5Enable | C1C5Enable
           & (io_in_vstopei_IPRIO == iprioC2C5 & ~io_in_hvictl_DPR
              | io_in_vstopei_IPRIO > iprioC2C5)) & io_in_mnstatusNMIE;
      irToHSReg <= irToHS;
      irToVSReg <= irToVS;
    end
  end // always @(posedge, posedge)
  wire        mSortEn_3_0 = io_in_mip_MEIP & io_in_mie_MEIE;
  wire        mipriosSort_24_isZero =
    mSortEn_3_0 & (platformValid | flag);
  wire        mipriosSort_24_greaterThan255 =
    mSortEn_3_0 & (|(io_in_mtopei_IPRIO[10:8]));
  wire [7:0]  mipriosSort_24_prioNum =
    mSortEn_3_0 ? io_in_mtopei_IPRIO[7:0] : 8'h0;
  wire        mSortEn_3_1 = io_in_mip_MSIP & io_in_mie_MSIE;
  wire        mipriosSort_25_isZero =
    mSortEn_3_1 & io_in_miprios[31:24] == 8'h0;
  wire [7:0]  mipriosSort_25_prioNum =
    mSortEn_3_1 ? io_in_miprios[31:24] : 8'h0;
  wire        mSortEn_3_2 = io_in_mip_MTIP & io_in_mie_MTIE;
  wire        mipriosSort_26_isZero =
    mSortEn_3_2 & io_in_miprios[63:56] == 8'h0;
  wire [7:0]  mipriosSort_26_prioNum =
    mSortEn_3_2 ? io_in_miprios[63:56] : 8'h0;
  wire        mipriosSort_27_enable =
    io_in_mip_SEIP & io_in_mie_SEIE & ~io_in_mideleg_SEI;
  wire        mipriosSort_27_isZero =
    mipriosSort_27_enable & io_in_miprios[79:72] == 8'h0;
  wire [7:0]  mipriosSort_27_prioNum =
    mipriosSort_27_enable ? io_in_miprios[79:72] : 8'h0;
  wire        mipriosSort_28_enable =
    io_in_mip_SSIP & io_in_mie_SSIE & ~io_in_mideleg_SSI;
  wire        mipriosSort_28_isZero = mipriosSort_28_enable & io_in_miprios[15:8] == 8'h0;
  wire [7:0]  mipriosSort_28_prioNum = mipriosSort_28_enable ? io_in_miprios[15:8] : 8'h0;
  wire        mipriosSort_29_enable =
    io_in_mip_STIP & io_in_mie_STIE & ~io_in_mideleg_STI;
  wire        mipriosSort_29_isZero =
    mipriosSort_29_enable & io_in_miprios[47:40] == 8'h0;
  wire [7:0]  mipriosSort_29_prioNum =
    mipriosSort_29_enable ? io_in_miprios[47:40] : 8'h0;
  wire        mipriosSort_34_enable =
    io_in_mip_LCOFIP & io_in_mie_LCOFIE & ~io_in_mideleg_LCOFI;
  wire        hsSortEn_0 = hsip[63] & hsie[63];
  wire        hsipriosSort_0_isZero =
    hsSortEn_0 & io_in_hsiprios[511:504] == 8'h0;
  wire [7:0]  hsipriosSort_0_prioNum =
    hsSortEn_0 ? io_in_hsiprios[511:504] : 8'h0;
  wire        hsSortEn_1 = hsip[31] & hsie[31];
  wire        hsipriosSort_1_isZero =
    hsSortEn_1 & io_in_hsiprios[255:248] == 8'h0;
  wire [7:0]  hsipriosSort_1_prioNum =
    hsSortEn_1 ? io_in_hsiprios[255:248] : 8'h0;
  wire        hsSortEn_2 = hsip[62] & hsie[62];
  wire        hsipriosSort_2_isZero =
    hsSortEn_2 & io_in_hsiprios[503:496] == 8'h0;
  wire [7:0]  hsipriosSort_2_prioNum =
    hsSortEn_2 ? io_in_hsiprios[503:496] : 8'h0;
  wire        hsSortEn_3 = hsip[61] & hsie[61];
  wire        hsipriosSort_3_isZero =
    hsSortEn_3 & io_in_hsiprios[495:488] == 8'h0;
  wire [7:0]  hsipriosSort_3_prioNum =
    hsSortEn_3 ? io_in_hsiprios[495:488] : 8'h0;
  wire        hsSortEn_4 = hsip[30] & hsie[30];
  wire        hsipriosSort_4_isZero =
    hsSortEn_4 & io_in_hsiprios[247:240] == 8'h0;
  wire [7:0]  hsipriosSort_4_prioNum =
    hsSortEn_4 ? io_in_hsiprios[247:240] : 8'h0;
  wire        hsSortEn_5 = hsip[60] & hsie[60];
  wire        hsipriosSort_5_isZero =
    hsSortEn_5 & io_in_hsiprios[487:480] == 8'h0;
  wire [7:0]  hsipriosSort_5_prioNum =
    hsSortEn_5 ? io_in_hsiprios[487:480] : 8'h0;
  wire        hsSortEn_6 = hsip[47] & hsie[47];
  wire        hsipriosSort_6_isZero =
    hsSortEn_6 & io_in_hsiprios[383:376] == 8'h0;
  wire [7:0]  hsipriosSort_6_prioNum =
    hsSortEn_6 ? io_in_hsiprios[383:376] : 8'h0;
  wire        hsSortEn_7 = hsip[23] & hsie[23];
  wire        hsipriosSort_7_isZero =
    hsSortEn_7 & io_in_hsiprios[191:184] == 8'h0;
  wire [7:0]  hsipriosSort_7_prioNum =
    hsSortEn_7 ? io_in_hsiprios[191:184] : 8'h0;
  wire        hsSortEn_1_0 = hsip[46] & hsie[46];
  wire        hsipriosSort_8_isZero =
    hsSortEn_1_0 & io_in_hsiprios[375:368] == 8'h0;
  wire [7:0]  hsipriosSort_8_prioNum =
    hsSortEn_1_0 ? io_in_hsiprios[375:368] : 8'h0;
  wire        hsSortEn_1_1 = hsip[45] & hsie[45];
  wire        hsipriosSort_9_isZero =
    hsSortEn_1_1 & io_in_hsiprios[367:360] == 8'h0;
  wire [7:0]  hsipriosSort_9_prioNum =
    hsSortEn_1_1 ? io_in_hsiprios[367:360] : 8'h0;
  wire        hsSortEn_1_2 = hsip[22] & hsie[22];
  wire        hsipriosSort_10_isZero =
    hsSortEn_1_2 & io_in_hsiprios[183:176] == 8'h0;
  wire [7:0]  hsipriosSort_10_prioNum =
    hsSortEn_1_2 ? io_in_hsiprios[183:176] : 8'h0;
  wire        hsSortEn_1_3 = hsip[44] & hsie[44];
  wire        hsipriosSort_11_isZero =
    hsSortEn_1_3 & io_in_hsiprios[359:352] == 8'h0;
  wire [7:0]  hsipriosSort_11_prioNum =
    hsSortEn_1_3 ? io_in_hsiprios[359:352] : 8'h0;
  wire        hsSortEn_1_4 = hsip[43] & hsie[43];
  wire        hsipriosSort_12_isZero =
    hsSortEn_1_4 & io_in_hsiprios[351:344] == 8'h0;
  wire [7:0]  hsipriosSort_12_prioNum =
    hsSortEn_1_4 ? io_in_hsiprios[351:344] : 8'h0;
  wire        hsSortEn_1_5 = hsip[21] & hsie[21];
  wire        hsipriosSort_13_isZero =
    hsSortEn_1_5 & io_in_hsiprios[175:168] == 8'h0;
  wire [7:0]  hsipriosSort_13_prioNum =
    hsSortEn_1_5 ? io_in_hsiprios[175:168] : 8'h0;
  wire        hsSortEn_1_6 = hsip[42] & hsie[42];
  wire        hsipriosSort_14_isZero =
    hsSortEn_1_6 & io_in_hsiprios[343:336] == 8'h0;
  wire [7:0]  hsipriosSort_14_prioNum =
    hsSortEn_1_6 ? io_in_hsiprios[343:336] : 8'h0;
  wire        hsSortEn_1_7 = hsip[41] & hsie[41];
  wire        hsipriosSort_15_isZero =
    hsSortEn_1_7 & io_in_hsiprios[335:328] == 8'h0;
  wire [7:0]  hsipriosSort_15_prioNum =
    hsSortEn_1_7 ? io_in_hsiprios[335:328] : 8'h0;
  wire        hsSortEn_2_0 = hsip[20] & hsie[20];
  wire        hsipriosSort_16_isZero =
    hsSortEn_2_0 & io_in_hsiprios[167:160] == 8'h0;
  wire [7:0]  hsipriosSort_16_prioNum =
    hsSortEn_2_0 ? io_in_hsiprios[167:160] : 8'h0;
  wire        hsSortEn_2_1 = hsip[40] & hsie[40];
  wire        hsipriosSort_17_isZero =
    hsSortEn_2_1 & io_in_hsiprios[327:320] == 8'h0;
  wire [7:0]  hsipriosSort_17_prioNum =
    hsSortEn_2_1 ? io_in_hsiprios[327:320] : 8'h0;
  wire        hsSortEn_2_2 = hsip[59] & hsie[59];
  wire        hsipriosSort_18_isZero =
    hsSortEn_2_2 & io_in_hsiprios[479:472] == 8'h0;
  wire [7:0]  hsipriosSort_18_prioNum =
    hsSortEn_2_2 ? io_in_hsiprios[479:472] : 8'h0;
  wire        hsSortEn_2_3 = hsip[29] & hsie[29];
  wire        hsipriosSort_19_isZero =
    hsSortEn_2_3 & io_in_hsiprios[239:232] == 8'h0;
  wire [7:0]  hsipriosSort_19_prioNum =
    hsSortEn_2_3 ? io_in_hsiprios[239:232] : 8'h0;
  wire        hsSortEn_2_4 = hsip[58] & hsie[58];
  wire        hsipriosSort_20_isZero =
    hsSortEn_2_4 & io_in_hsiprios[471:464] == 8'h0;
  wire [7:0]  hsipriosSort_20_prioNum =
    hsSortEn_2_4 ? io_in_hsiprios[471:464] : 8'h0;
  wire        hsSortEn_2_5 = hsip[57] & hsie[57];
  wire        hsipriosSort_21_isZero =
    hsSortEn_2_5 & io_in_hsiprios[463:456] == 8'h0;
  wire [7:0]  hsipriosSort_21_prioNum =
    hsSortEn_2_5 ? io_in_hsiprios[463:456] : 8'h0;
  wire        hsSortEn_2_6 = hsip[28] & hsie[28];
  wire        hsipriosSort_22_isZero =
    hsSortEn_2_6 & io_in_hsiprios[231:224] == 8'h0;
  wire [7:0]  hsipriosSort_22_prioNum =
    hsSortEn_2_6 ? io_in_hsiprios[231:224] : 8'h0;
  wire        hsSortEn_2_7 = hsip[56] & hsie[56];
  wire        hsipriosSort_23_isZero =
    hsSortEn_2_7 & io_in_hsiprios[455:448] == 8'h0;
  wire [7:0]  hsipriosSort_23_prioNum =
    hsSortEn_2_7 ? io_in_hsiprios[455:448] : 8'h0;
  wire        hsipriosSort_24_enable = hsip[11] & hsie[11] & ~io_in_hideleg_MEI;
  wire        hsipriosSort_24_isZero =
    hsipriosSort_24_enable & io_in_hsiprios[95:88] == 8'h0;
  wire [7:0]  hsipriosSort_24_prioNum =
    hsipriosSort_24_enable ? io_in_hsiprios[95:88] : 8'h0;
  wire        hsipriosSort_25_enable = hsip[3] & hsie[3] & ~io_in_hideleg_MSI;
  wire        hsipriosSort_25_isZero =
    hsipriosSort_25_enable & io_in_hsiprios[31:24] == 8'h0;
  wire [7:0]  hsipriosSort_25_prioNum =
    hsipriosSort_25_enable ? io_in_hsiprios[31:24] : 8'h0;
  wire        hsipriosSort_26_enable = hsip[7] & hsie[7] & ~io_in_hideleg_MTI;
  wire        hsipriosSort_26_isZero =
    hsipriosSort_26_enable & io_in_hsiprios[63:56] == 8'h0;
  wire [7:0]  hsipriosSort_26_prioNum =
    hsipriosSort_26_enable ? io_in_hsiprios[63:56] : 8'h0;
  wire        hsipriosSort_27_enable = hsip[9] & hsie[9] & ~io_in_hideleg_SEI;
  wire        hsipriosSort_27_isZero = hsipriosSort_27_enable & (platformValid | flag);
  wire        hsipriosSort_27_greaterThan255 =
    hsipriosSort_27_enable & (|(io_in_stopei_IPRIO[10:8]));
  wire [7:0]  hsipriosSort_27_prioNum =
    hsipriosSort_27_enable ? io_in_stopei_IPRIO[7:0] : 8'h0;
  wire        hsipriosSort_28_enable = hsip[1] & hsie[1] & ~io_in_hideleg_SSI;
  wire        hsipriosSort_28_isZero =
    hsipriosSort_28_enable & io_in_hsiprios[15:8] == 8'h0;
  wire [7:0]  hsipriosSort_28_prioNum =
    hsipriosSort_28_enable ? io_in_hsiprios[15:8] : 8'h0;
  wire        hsipriosSort_29_enable = hsip[5] & hsie[5] & ~io_in_hideleg_STI;
  wire        hsipriosSort_29_isZero =
    hsipriosSort_29_enable & io_in_hsiprios[47:40] == 8'h0;
  wire [7:0]  hsipriosSort_29_prioNum =
    hsipriosSort_29_enable ? io_in_hsiprios[47:40] : 8'h0;
  wire        hsipriosSort_30_enable = hsip[12] & hsie[12] & ~io_in_hideleg_SGEI;
  wire        hsipriosSort_30_isZero =
    hsipriosSort_30_enable & io_in_hsiprios[103:96] == 8'h0;
  wire [7:0]  hsipriosSort_30_prioNum =
    hsipriosSort_30_enable ? io_in_hsiprios[103:96] : 8'h0;
  wire        hsipriosSort_31_enable = hsip[10] & hsie[10] & ~io_in_hideleg_VSEI;
  wire        hsipriosSort_31_isZero =
    hsipriosSort_31_enable & io_in_hsiprios[87:80] == 8'h0;
  wire [7:0]  hsipriosSort_31_prioNum =
    hsipriosSort_31_enable ? io_in_hsiprios[87:80] : 8'h0;
  wire        hsipriosSort_32_enable = hsip[2] & hsie[2] & ~io_in_hideleg_VSSI;
  wire        hsipriosSort_32_isZero =
    hsipriosSort_32_enable & io_in_hsiprios[23:16] == 8'h0;
  wire [7:0]  hsipriosSort_32_prioNum =
    hsipriosSort_32_enable ? io_in_hsiprios[23:16] : 8'h0;
  wire        hsipriosSort_33_enable = hsip[6] & hsie[6] & ~io_in_hideleg_VSTI;
  wire        hsipriosSort_33_isZero =
    hsipriosSort_33_enable & io_in_hsiprios[55:48] == 8'h0;
  wire [7:0]  hsipriosSort_33_prioNum =
    hsipriosSort_33_enable ? io_in_hsiprios[55:48] : 8'h0;
  wire        hsipriosSort_34_enable = hsip[13] & hsie[13] & ~io_in_hideleg_LCOFI;
  wire        hsipriosSort_34_isZero =
    hsipriosSort_34_enable & io_in_hsiprios[111:104] == 8'h0;
  wire [7:0]  hsipriosSort_34_prioNum =
    hsipriosSort_34_enable ? io_in_hsiprios[111:104] : 8'h0;
  wire        hsSortEn_4_3 = hsip[14] & hsie[14];
  wire        hsipriosSort_35_isZero =
    hsSortEn_4_3 & io_in_hsiprios[119:112] == 8'h0;
  wire [7:0]  hsipriosSort_35_prioNum =
    hsSortEn_4_3 ? io_in_hsiprios[119:112] : 8'h0;
  wire        hsSortEn_4_4 = hsip[15] & hsie[15];
  wire        hsipriosSort_36_isZero =
    hsSortEn_4_4 & io_in_hsiprios[127:120] == 8'h0;
  wire [7:0]  hsipriosSort_36_prioNum =
    hsSortEn_4_4 ? io_in_hsiprios[127:120] : 8'h0;
  wire        hsSortEn_4_5 = hsip[55] & hsie[55];
  wire        hsipriosSort_37_isZero =
    hsSortEn_4_5 & io_in_hsiprios[447:440] == 8'h0;
  wire [7:0]  hsipriosSort_37_prioNum =
    hsSortEn_4_5 ? io_in_hsiprios[447:440] : 8'h0;
  wire        hsSortEn_4_6 = hsip[27] & hsie[27];
  wire        hsipriosSort_38_isZero =
    hsSortEn_4_6 & io_in_hsiprios[223:216] == 8'h0;
  wire [7:0]  hsipriosSort_38_prioNum =
    hsSortEn_4_6 ? io_in_hsiprios[223:216] : 8'h0;
  wire        hsSortEn_4_7 = hsip[54] & hsie[54];
  wire        hsipriosSort_39_isZero =
    hsSortEn_4_7 & io_in_hsiprios[439:432] == 8'h0;
  wire [7:0]  hsipriosSort_39_prioNum =
    hsSortEn_4_7 ? io_in_hsiprios[439:432] : 8'h0;
  wire        hsSortEn_5_0 = hsip[53] & hsie[53];
  wire        hsipriosSort_40_isZero =
    hsSortEn_5_0 & io_in_hsiprios[431:424] == 8'h0;
  wire [7:0]  hsipriosSort_40_prioNum =
    hsSortEn_5_0 ? io_in_hsiprios[431:424] : 8'h0;
  wire        hsSortEn_5_1 = hsip[26] & hsie[26];
  wire        hsipriosSort_41_isZero =
    hsSortEn_5_1 & io_in_hsiprios[215:208] == 8'h0;
  wire [7:0]  hsipriosSort_41_prioNum =
    hsSortEn_5_1 ? io_in_hsiprios[215:208] : 8'h0;
  wire        hsSortEn_5_2 = hsip[52] & hsie[52];
  wire        hsipriosSort_42_isZero =
    hsSortEn_5_2 & io_in_hsiprios[423:416] == 8'h0;
  wire [7:0]  hsipriosSort_42_prioNum =
    hsSortEn_5_2 ? io_in_hsiprios[423:416] : 8'h0;
  wire        hsSortEn_5_3 = hsip[39] & hsie[39];
  wire        hsipriosSort_43_isZero =
    hsSortEn_5_3 & io_in_hsiprios[319:312] == 8'h0;
  wire [7:0]  hsipriosSort_43_prioNum =
    hsSortEn_5_3 ? io_in_hsiprios[319:312] : 8'h0;
  wire        hsSortEn_5_4 = hsip[19] & hsie[19];
  wire        hsipriosSort_44_isZero =
    hsSortEn_5_4 & io_in_hsiprios[159:152] == 8'h0;
  wire [7:0]  hsipriosSort_44_prioNum =
    hsSortEn_5_4 ? io_in_hsiprios[159:152] : 8'h0;
  wire        hsSortEn_5_5 = hsip[38] & hsie[38];
  wire        hsipriosSort_45_isZero =
    hsSortEn_5_5 & io_in_hsiprios[311:304] == 8'h0;
  wire [7:0]  hsipriosSort_45_prioNum =
    hsSortEn_5_5 ? io_in_hsiprios[311:304] : 8'h0;
  wire        hsSortEn_5_6 = hsip[37] & hsie[37];
  wire        hsipriosSort_46_isZero =
    hsSortEn_5_6 & io_in_hsiprios[303:296] == 8'h0;
  wire [7:0]  hsipriosSort_46_prioNum =
    hsSortEn_5_6 ? io_in_hsiprios[303:296] : 8'h0;
  wire        hsSortEn_5_7 = hsip[18] & hsie[18];
  wire        hsipriosSort_47_isZero =
    hsSortEn_5_7 & io_in_hsiprios[151:144] == 8'h0;
  wire [7:0]  hsipriosSort_47_prioNum =
    hsSortEn_5_7 ? io_in_hsiprios[151:144] : 8'h0;
  wire        hsSortEn_6_0 = hsip[36] & hsie[36];
  wire        hsipriosSort_48_isZero =
    hsSortEn_6_0 & io_in_hsiprios[295:288] == 8'h0;
  wire [7:0]  hsipriosSort_48_prioNum =
    hsSortEn_6_0 ? io_in_hsiprios[295:288] : 8'h0;
  wire        hsSortEn_6_1 = hsip[35] & hsie[35];
  wire        hsipriosSort_49_isZero =
    hsSortEn_6_1 & io_in_hsiprios[287:280] == 8'h0;
  wire [7:0]  hsipriosSort_49_prioNum =
    hsSortEn_6_1 ? io_in_hsiprios[287:280] : 8'h0;
  wire        hsSortEn_6_2 = hsip[17] & hsie[17];
  wire        hsipriosSort_50_isZero =
    hsSortEn_6_2 & io_in_hsiprios[143:136] == 8'h0;
  wire [7:0]  hsipriosSort_50_prioNum =
    hsSortEn_6_2 ? io_in_hsiprios[143:136] : 8'h0;
  wire        hsSortEn_6_3 = hsip[34] & hsie[34];
  wire        hsipriosSort_51_isZero =
    hsSortEn_6_3 & io_in_hsiprios[279:272] == 8'h0;
  wire [7:0]  hsipriosSort_51_prioNum =
    hsSortEn_6_3 ? io_in_hsiprios[279:272] : 8'h0;
  wire        hsSortEn_6_4 = hsip[33] & hsie[33];
  wire        hsipriosSort_52_isZero =
    hsSortEn_6_4 & io_in_hsiprios[271:264] == 8'h0;
  wire [7:0]  hsipriosSort_52_prioNum =
    hsSortEn_6_4 ? io_in_hsiprios[271:264] : 8'h0;
  wire        hsSortEn_6_5 = hsip[16] & hsie[16];
  wire        hsipriosSort_53_isZero =
    hsSortEn_6_5 & io_in_hsiprios[135:128] == 8'h0;
  wire [7:0]  hsipriosSort_53_prioNum =
    hsSortEn_6_5 ? io_in_hsiprios[135:128] : 8'h0;
  wire        hsSortEn_6_6 = hsip[32] & hsie[32];
  wire        hsipriosSort_54_isZero =
    hsSortEn_6_6 & io_in_hsiprios[263:256] == 8'h0;
  wire [7:0]  hsipriosSort_54_prioNum =
    hsSortEn_6_6 ? io_in_hsiprios[263:256] : 8'h0;
  wire        hsSortEn_6_7 = hsip[51] & hsie[51];
  wire        hsipriosSort_55_isZero =
    hsSortEn_6_7 & io_in_hsiprios[415:408] == 8'h0;
  wire [7:0]  hsipriosSort_55_prioNum =
    hsSortEn_6_7 ? io_in_hsiprios[415:408] : 8'h0;
  wire        hsSortEn_7_0 = hsip[25] & hsie[25];
  wire        hsipriosSort_56_isZero =
    hsSortEn_7_0 & io_in_hsiprios[207:200] == 8'h0;
  wire [7:0]  hsipriosSort_56_prioNum =
    hsSortEn_7_0 ? io_in_hsiprios[207:200] : 8'h0;
  wire        hsSortEn_7_1 = hsip[50] & hsie[50];
  wire        hsipriosSort_57_isZero =
    hsSortEn_7_1 & io_in_hsiprios[407:400] == 8'h0;
  wire [7:0]  hsipriosSort_57_prioNum =
    hsSortEn_7_1 ? io_in_hsiprios[407:400] : 8'h0;
  wire        hsSortEn_7_2 = hsip[49] & hsie[49];
  wire        hsipriosSort_58_isZero =
    hsSortEn_7_2 & io_in_hsiprios[399:392] == 8'h0;
  wire [7:0]  hsipriosSort_58_prioNum =
    hsSortEn_7_2 ? io_in_hsiprios[399:392] : 8'h0;
  wire        hsSortEn_7_3 = hsip[24] & hsie[24];
  wire        hsipriosSort_59_isZero =
    hsSortEn_7_3 & io_in_hsiprios[199:192] == 8'h0;
  wire [7:0]  hsipriosSort_59_prioNum =
    hsSortEn_7_3 ? io_in_hsiprios[199:192] : 8'h0;
  wire        ipriosTmp_result_rightIprio_15_0_enable = hsip[48] & hsie[48];
  wire        hvipriosSort_0_isZero = io_in_vsip_LC63IP & io_in_vsie_LC63IE;
  wire        hvipriosSort_1_isZero = io_in_vsip_LC31IP & io_in_vsie_LC31IE;
  wire        hvipriosSort_2_isZero = io_in_vsip_LC62IP & io_in_vsie_LC62IE;
  wire        hvipriosSort_3_isZero = io_in_vsip_LC61IP & io_in_vsie_LC61IE;
  wire        hvipriosSort_4_isZero = io_in_vsip_LC30IP & io_in_vsie_LC30IE;
  wire        hvipriosSort_5_isZero = io_in_vsip_LC60IP & io_in_vsie_LC60IE;
  wire        hvipriosSort_6_isZero = io_in_vsip_LC47IP & io_in_vsie_LC47IE;
  wire        hvipriosSort_7_enable = io_in_vsip_LC23IP & io_in_vsie_LC23IE;
  wire        hvipriosSort_8_isZero = io_in_vsip_LC46IP & io_in_vsie_LC46IE;
  wire        hvipriosSort_9_isZero = io_in_vsip_LC45IP & io_in_vsie_LC45IE;
  wire        hvipriosSort_10_enable = io_in_vsip_LC22IP & io_in_vsie_LC22IE;
  wire        hvipriosSort_11_isZero = io_in_vsip_LC44IP & io_in_vsie_LC44IE;
  wire        hvipriosSort_12_isZero = io_in_vsip_HPRASEIP & io_in_vsie_HPRASEIE;
  wire        hvipriosSort_13_enable = io_in_vsip_LC21IP & io_in_vsie_LC21IE;
  wire        hvipriosSort_14_isZero = io_in_vsip_LC42IP & io_in_vsie_LC42IE;
  wire        hvipriosSort_15_isZero = io_in_vsip_LC41IP & io_in_vsie_LC41IE;
  wire        hvipriosSort_16_enable = io_in_vsip_LC20IP & io_in_vsie_LC20IE;
  wire        hvipriosSort_17_isZero = io_in_vsip_LC40IP & io_in_vsie_LC40IE;
  wire        hvipriosSort_18_isZero = io_in_vsip_LC59IP & io_in_vsie_LC59IE;
  wire        hvipriosSort_19_isZero = io_in_vsip_LC29IP & io_in_vsie_LC29IE;
  wire        hvipriosSort_20_isZero = io_in_vsip_LC58IP & io_in_vsie_LC58IE;
  wire        hvipriosSort_21_isZero = io_in_vsip_LC57IP & io_in_vsie_LC57IE;
  wire        hvipriosSort_22_isZero = io_in_vsip_LC28IP & io_in_vsie_LC28IE;
  wire        hvipriosSort_23_isZero = io_in_vsip_LC56IP & io_in_vsie_LC56IE;
  wire        hvipriosSort_28_enable = io_in_vsip_SSIP & io_in_vsie_SSIE;
  wire        hvipriosSort_29_enable = io_in_vsip_STIP & io_in_vsie_STIE;
  wire        hvipriosSort_34_enable = io_in_vsip_LCOFIP & io_in_vsie_LCOFIE;
  wire        hvipriosSort_35_enable = io_in_vsip_LC14IP & io_in_vsie_LC14IE;
  wire        hvipriosSort_36_enable = io_in_vsip_LC15IP & io_in_vsie_LC15IE;
  wire        hvipriosSort_37_isZero = io_in_vsip_LC55IP & io_in_vsie_LC55IE;
  wire        hvipriosSort_38_isZero = io_in_vsip_LC27IP & io_in_vsie_LC27IE;
  wire        hvipriosSort_39_isZero = io_in_vsip_LC54IP & io_in_vsie_LC54IE;
  wire        hvipriosSort_40_isZero = io_in_vsip_LC53IP & io_in_vsie_LC53IE;
  wire        hvipriosSort_41_isZero = io_in_vsip_LC26IP & io_in_vsie_LC26IE;
  wire        hvipriosSort_42_isZero = io_in_vsip_LC52IP & io_in_vsie_LC52IE;
  wire        hvipriosSort_43_isZero = io_in_vsip_LC39IP & io_in_vsie_LC39IE;
  wire        hvipriosSort_44_enable = io_in_vsip_LC19IP & io_in_vsie_LC19IE;
  wire        hvipriosSort_45_isZero = io_in_vsip_LC38IP & io_in_vsie_LC38IE;
  wire        hvipriosSort_46_isZero = io_in_vsip_LC37IP & io_in_vsie_LC37IE;
  wire        hvipriosSort_47_enable = io_in_vsip_LC18IP & io_in_vsie_LC18IE;
  wire        hvipriosSort_48_isZero = io_in_vsip_LC36IP & io_in_vsie_LC36IE;
  wire        hvipriosSort_49_isZero = io_in_vsip_LPRASEIP & io_in_vsie_LPRASEIE;
  wire        hvipriosSort_50_enable = io_in_vsip_LC17IP & io_in_vsie_LC17IE;
  wire        hvipriosSort_51_isZero = io_in_vsip_LC34IP & io_in_vsie_LC34IE;
  wire        hvipriosSort_52_isZero = io_in_vsip_LC33IP & io_in_vsie_LC33IE;
  wire        hvipriosSort_53_enable = io_in_vsip_LC16IP & io_in_vsie_LC16IE;
  wire        hvipriosSort_54_isZero = io_in_vsip_LC32IP & io_in_vsie_LC32IE;
  wire        hvipriosSort_55_isZero = io_in_vsip_LC51IP & io_in_vsie_LC51IE;
  wire        hvipriosSort_56_isZero = io_in_vsip_LC25IP & io_in_vsie_LC25IE;
  wire        hvipriosSort_57_isZero = io_in_vsip_LC50IP & io_in_vsie_LC50IE;
  wire        hvipriosSort_58_isZero = io_in_vsip_LC49IP & io_in_vsie_LC49IE;
  wire        hvipriosSort_59_isZero = io_in_vsip_LC24IP & io_in_vsie_LC24IE;
  wire        hvipriosSort_60_isZero = io_in_vsip_LC48IP & io_in_vsie_LC48IE;
  wire        hvipriosSort_28_isZero =
    hvipriosSort_28_enable ? io_in_hviprio1_PrioSSI == 8'h0 : hvipriosSort_28_enable;
  wire [7:0]  hvipriosSort_28_prioNum =
    hvipriosSort_28_enable ? io_in_hviprio1_PrioSSI : 8'h0;
  wire        hvipriosSort_29_isZero =
    hvipriosSort_29_enable ? io_in_hviprio1_PrioSTI == 8'h0 : hvipriosSort_29_enable;
  wire [7:0]  hvipriosSort_29_prioNum =
    hvipriosSort_29_enable ? io_in_hviprio1_PrioSTI : 8'h0;
  wire        hvipriosSort_34_isZero =
    hvipriosSort_34_enable ? io_in_hviprio1_PrioCOI == 8'h0 : hvipriosSort_34_enable;
  wire [7:0]  hvipriosSort_34_prioNum =
    hvipriosSort_34_enable ? io_in_hviprio1_PrioCOI : 8'h0;
  wire        hvipriosSort_35_isZero =
    hvipriosSort_35_enable ? io_in_hviprio1_Prio14 == 8'h0 : hvipriosSort_35_enable;
  wire [7:0]  hvipriosSort_35_prioNum =
    hvipriosSort_35_enable ? io_in_hviprio1_Prio14 : 8'h0;
  wire        hvipriosSort_36_isZero =
    hvipriosSort_36_enable ? io_in_hviprio1_Prio15 == 8'h0 : hvipriosSort_36_enable;
  wire        hvipriosSort_53_isZero =
    hvipriosSort_53_enable ? io_in_hviprio2_ALL[7:0] == 8'h0 : hvipriosSort_53_enable;
  wire        hvipriosSort_50_isZero =
    hvipriosSort_50_enable ? io_in_hviprio2_ALL[15:8] == 8'h0 : hvipriosSort_50_enable;
  wire        hvipriosSort_47_isZero =
    hvipriosSort_47_enable ? io_in_hviprio2_ALL[23:16] == 8'h0 : hvipriosSort_47_enable;
  wire        hvipriosSort_44_isZero =
    hvipriosSort_44_enable ? io_in_hviprio2_ALL[31:24] == 8'h0 : hvipriosSort_44_enable;
  wire        hvipriosSort_16_isZero =
    hvipriosSort_16_enable ? io_in_hviprio2_ALL[39:32] == 8'h0 : hvipriosSort_16_enable;
  wire        hvipriosSort_13_isZero =
    hvipriosSort_13_enable ? io_in_hviprio2_ALL[47:40] == 8'h0 : hvipriosSort_13_enable;
  wire        hvipriosSort_10_isZero =
    hvipriosSort_10_enable ? io_in_hviprio2_ALL[55:48] == 8'h0 : hvipriosSort_10_enable;
  wire        hvipriosSort_7_isZero =
    hvipriosSort_7_enable ? io_in_hviprio2_ALL[63:56] == 8'h0 : hvipriosSort_7_enable;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_334 =
    mSortEn_3_0 & ~mSortEn_3_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_336 =
    ~mSortEn_3_0 & mSortEn_3_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_337 =
    mSortEn_3_0 & mSortEn_3_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_338 =
    mipriosSort_24_isZero & mipriosSort_25_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_340 =
    mipriosSort_24_isZero & ~mipriosSort_25_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_344 =
    ~mipriosSort_24_isZero & mipriosSort_25_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_349 =
    ~mipriosSort_24_isZero & ~mipriosSort_25_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_357 =
    mipriosSort_24_prioNum <= mipriosSort_25_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_leftIprio_3_0_prioNum =
    (ipriosTmp_result_leftIprio_leftIprio_sel_334
     & mSortEn_3_0
       ? io_in_mtopei_IPRIO[7:0]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_336
       & mSortEn_3_1
         ? io_in_miprios[31:24]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_337
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_338
            & mSortEn_3_0
            | ipriosTmp_result_leftIprio_leftIprio_sel_340
            & mSortEn_3_0
            | ipriosTmp_result_leftIprio_leftIprio_sel_344
            & mSortEn_3_0
              ? io_in_mtopei_IPRIO[7:0]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_349
                ? (mipriosSort_24_greaterThan255 & mSortEn_3_1
                     ? io_in_miprios[31:24]
                     : 8'h0)
                  | (mipriosSort_24_greaterThan255
                       ? 8'h0
                       : ipriosTmp_result_leftIprio_leftIprio_sel_357
                           ? mipriosSort_24_prioNum
                           : mipriosSort_25_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_leftIprio_3_0_greaterThan255 =
    ipriosTmp_result_leftIprio_leftIprio_sel_334 & mipriosSort_24_greaterThan255
    | ipriosTmp_result_leftIprio_leftIprio_sel_337
    & (ipriosTmp_result_leftIprio_leftIprio_sel_338
       & mipriosSort_24_greaterThan255
       | ipriosTmp_result_leftIprio_leftIprio_sel_340
       & mipriosSort_24_greaterThan255
       | ipriosTmp_result_leftIprio_leftIprio_sel_344
       & mipriosSort_24_greaterThan255);
  wire        ipriosTmp_result_leftIprio_leftIprio_3_0_isZero =
    ipriosTmp_result_leftIprio_leftIprio_sel_334 & mipriosSort_24_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_336 & mipriosSort_25_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_337
    & (ipriosTmp_result_leftIprio_leftIprio_sel_338 & mipriosSort_24_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_340 & mipriosSort_24_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_344 & mipriosSort_24_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_349
       & (mipriosSort_24_greaterThan255 & mipriosSort_25_isZero
          | ~mipriosSort_24_greaterThan255
          & (ipriosTmp_result_leftIprio_leftIprio_sel_357
               ? mipriosSort_24_isZero
               : mipriosSort_25_isZero)));
  wire        ipriosTmp_result_leftIprio_leftIprio_3_0_enable =
    ipriosTmp_result_leftIprio_leftIprio_sel_334 & mSortEn_3_0
    | ipriosTmp_result_leftIprio_leftIprio_sel_336
    & mSortEn_3_1
    | ipriosTmp_result_leftIprio_leftIprio_sel_337
    & (ipriosTmp_result_leftIprio_leftIprio_sel_338
       & mSortEn_3_0
       | ipriosTmp_result_leftIprio_leftIprio_sel_340
       & mSortEn_3_0
       | ipriosTmp_result_leftIprio_leftIprio_sel_344
       & mSortEn_3_0
       | ipriosTmp_result_leftIprio_leftIprio_sel_349
       & (mipriosSort_24_greaterThan255 & mSortEn_3_1
          | ~mipriosSort_24_greaterThan255
          & (ipriosTmp_result_leftIprio_leftIprio_sel_357
               ? mSortEn_3_0
               : mSortEn_3_1)));
  wire [5:0]  ipriosTmp_result_leftIprio_leftIprio_3_0_idx =
    (ipriosTmp_result_leftIprio_leftIprio_sel_334 ? 6'h18 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_336 ? 6'h19 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_337
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_338
            | ipriosTmp_result_leftIprio_leftIprio_sel_340
            | ipriosTmp_result_leftIprio_leftIprio_sel_344
              ? 6'h18
              : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_349
                ? (mipriosSort_24_greaterThan255 ? 6'h19 : 6'h0)
                  | (mipriosSort_24_greaterThan255
                       ? 6'h0
                       : {5'hC, ~ipriosTmp_result_leftIprio_leftIprio_sel_357})
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_334 =
    mSortEn_3_2 & ~mipriosSort_27_enable;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_336 =
    ~mSortEn_3_2 & mipriosSort_27_enable;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_337 =
    mSortEn_3_2 & mipriosSort_27_enable;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_338 =
    mipriosSort_26_isZero & mipriosSort_27_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_340 =
    mipriosSort_26_isZero & ~mipriosSort_27_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_344 =
    ~mipriosSort_26_isZero & mipriosSort_27_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_349 =
    ~mipriosSort_26_isZero & ~mipriosSort_27_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_357 =
    mipriosSort_26_prioNum <= mipriosSort_27_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_rightIprio_3_0_prioNum =
    (ipriosTmp_result_leftIprio_rightIprio_sel_334
     & mSortEn_3_2
       ? io_in_miprios[63:56]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_336 & mipriosSort_27_enable
         ? io_in_miprios[79:72]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_337
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_338
            & mSortEn_3_2
              ? io_in_miprios[63:56]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_340
              & mipriosSort_27_enable
                ? io_in_miprios[79:72]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_344
              & mSortEn_3_2
                ? io_in_miprios[63:56]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_349
                ? (ipriosTmp_result_leftIprio_rightIprio_sel_357
                     ? mipriosSort_26_prioNum
                     : mipriosSort_27_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_3_0_isZero =
    ipriosTmp_result_leftIprio_rightIprio_sel_334 & mipriosSort_26_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_336 & mipriosSort_27_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_337
    & (ipriosTmp_result_leftIprio_rightIprio_sel_338 & mipriosSort_26_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_340 & mipriosSort_27_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_344 & mipriosSort_26_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_349
       & (ipriosTmp_result_leftIprio_rightIprio_sel_357
            ? mipriosSort_26_isZero
            : mipriosSort_27_isZero));
  wire        ipriosTmp_result_leftIprio_rightIprio_3_0_enable =
    ipriosTmp_result_leftIprio_rightIprio_sel_334
    & mSortEn_3_2
    | ipriosTmp_result_leftIprio_rightIprio_sel_336 & mipriosSort_27_enable
    | ipriosTmp_result_leftIprio_rightIprio_sel_337
    & (ipriosTmp_result_leftIprio_rightIprio_sel_338
       & mSortEn_3_2
       | ipriosTmp_result_leftIprio_rightIprio_sel_340 & mipriosSort_27_enable
       | ipriosTmp_result_leftIprio_rightIprio_sel_344
       & mSortEn_3_2
       | ipriosTmp_result_leftIprio_rightIprio_sel_349
       & (ipriosTmp_result_leftIprio_rightIprio_sel_357
            ? mSortEn_3_2
            : mipriosSort_27_enable));
  wire [5:0]  ipriosTmp_result_leftIprio_rightIprio_3_0_idx =
    (ipriosTmp_result_leftIprio_rightIprio_sel_334 ? 6'h1A : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_336 ? 6'h1B : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_337
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_338 ? 6'h1A : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_340 ? 6'h1B : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_344 ? 6'h1A : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_349
                ? {5'hD, ~ipriosTmp_result_leftIprio_rightIprio_sel_357}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_sel_334 =
    ipriosTmp_result_leftIprio_leftIprio_3_0_enable
    & ~ipriosTmp_result_leftIprio_rightIprio_3_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_336 =
    ~ipriosTmp_result_leftIprio_leftIprio_3_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_3_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_337 =
    ipriosTmp_result_leftIprio_leftIprio_3_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_3_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_338 =
    ipriosTmp_result_leftIprio_leftIprio_3_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_3_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_340 =
    ipriosTmp_result_leftIprio_leftIprio_3_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_3_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_341 =
    ipriosTmp_result_leftIprio_leftIprio_3_0_idx < 6'h19;
  wire        ipriosTmp_result_leftIprio_sel_344 =
    ~ipriosTmp_result_leftIprio_leftIprio_3_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_3_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_345 =
    ipriosTmp_result_leftIprio_rightIprio_3_0_idx < 6'h19;
  wire        ipriosTmp_result_leftIprio_sel_349 =
    ~ipriosTmp_result_leftIprio_leftIprio_3_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_3_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_357 =
    ipriosTmp_result_leftIprio_leftIprio_3_0_prioNum <= ipriosTmp_result_leftIprio_rightIprio_3_0_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_3_0_prioNum =
    (ipriosTmp_result_leftIprio_sel_334
       ? ipriosTmp_result_leftIprio_leftIprio_3_0_prioNum
       : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_336
         ? ipriosTmp_result_leftIprio_rightIprio_3_0_prioNum
         : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_337
         ? (ipriosTmp_result_leftIprio_sel_338
              ? ipriosTmp_result_leftIprio_leftIprio_3_0_prioNum
              : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_340
                ? (ipriosTmp_result_leftIprio_sel_341
                     ? ipriosTmp_result_leftIprio_leftIprio_3_0_prioNum
                     : ipriosTmp_result_leftIprio_rightIprio_3_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_344
                ? (ipriosTmp_result_leftIprio_sel_345
                     ? ipriosTmp_result_leftIprio_rightIprio_3_0_prioNum
                     : ipriosTmp_result_leftIprio_leftIprio_3_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_349
                ? (ipriosTmp_result_leftIprio_leftIprio_3_0_greaterThan255
                     ? ipriosTmp_result_leftIprio_rightIprio_3_0_prioNum
                     : 8'h0)
                  | (ipriosTmp_result_leftIprio_leftIprio_3_0_greaterThan255
                       ? 8'h0
                       : ipriosTmp_result_leftIprio_sel_357
                           ? ipriosTmp_result_leftIprio_leftIprio_3_0_prioNum
                           : ipriosTmp_result_leftIprio_rightIprio_3_0_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_3_0_greaterThan255 =
    ipriosTmp_result_leftIprio_sel_334
    & ipriosTmp_result_leftIprio_leftIprio_3_0_greaterThan255
    | ipriosTmp_result_leftIprio_sel_337
    & (ipriosTmp_result_leftIprio_sel_338
       & ipriosTmp_result_leftIprio_leftIprio_3_0_greaterThan255
       | ipriosTmp_result_leftIprio_sel_340
       & ipriosTmp_result_leftIprio_sel_341
       & ipriosTmp_result_leftIprio_leftIprio_3_0_greaterThan255
       | ipriosTmp_result_leftIprio_sel_344
       & ~ipriosTmp_result_leftIprio_sel_345
       & ipriosTmp_result_leftIprio_leftIprio_3_0_greaterThan255);
  wire        ipriosTmp_result_leftIprio_3_0_isZero =
    ipriosTmp_result_leftIprio_sel_334
    & ipriosTmp_result_leftIprio_leftIprio_3_0_isZero
    | ipriosTmp_result_leftIprio_sel_336
    & ipriosTmp_result_leftIprio_rightIprio_3_0_isZero
    | ipriosTmp_result_leftIprio_sel_337
    & (ipriosTmp_result_leftIprio_sel_338
       & ipriosTmp_result_leftIprio_leftIprio_3_0_isZero
       | ipriosTmp_result_leftIprio_sel_340
       & (ipriosTmp_result_leftIprio_sel_341
            ? ipriosTmp_result_leftIprio_leftIprio_3_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_3_0_isZero)
       | ipriosTmp_result_leftIprio_sel_344
       & (ipriosTmp_result_leftIprio_sel_345
            ? ipriosTmp_result_leftIprio_rightIprio_3_0_isZero
            : ipriosTmp_result_leftIprio_leftIprio_3_0_isZero)
       | ipriosTmp_result_leftIprio_sel_349
       & (ipriosTmp_result_leftIprio_leftIprio_3_0_greaterThan255
          & ipriosTmp_result_leftIprio_rightIprio_3_0_isZero
          | ~ipriosTmp_result_leftIprio_leftIprio_3_0_greaterThan255
          & (ipriosTmp_result_leftIprio_sel_357
               ? ipriosTmp_result_leftIprio_leftIprio_3_0_isZero
               : ipriosTmp_result_leftIprio_rightIprio_3_0_isZero)));
  wire        ipriosTmp_result_leftIprio_3_0_enable =
    ipriosTmp_result_leftIprio_sel_334
    & ipriosTmp_result_leftIprio_leftIprio_3_0_enable
    | ipriosTmp_result_leftIprio_sel_336
    & ipriosTmp_result_leftIprio_rightIprio_3_0_enable
    | ipriosTmp_result_leftIprio_sel_337
    & (ipriosTmp_result_leftIprio_sel_338
       & ipriosTmp_result_leftIprio_leftIprio_3_0_enable
       | ipriosTmp_result_leftIprio_sel_340
       & (ipriosTmp_result_leftIprio_sel_341
            ? ipriosTmp_result_leftIprio_leftIprio_3_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_3_0_enable)
       | ipriosTmp_result_leftIprio_sel_344
       & (ipriosTmp_result_leftIprio_sel_345
            ? ipriosTmp_result_leftIprio_rightIprio_3_0_enable
            : ipriosTmp_result_leftIprio_leftIprio_3_0_enable)
       | ipriosTmp_result_leftIprio_sel_349
       & (ipriosTmp_result_leftIprio_leftIprio_3_0_greaterThan255
          & ipriosTmp_result_leftIprio_rightIprio_3_0_enable
          | ~ipriosTmp_result_leftIprio_leftIprio_3_0_greaterThan255
          & (ipriosTmp_result_leftIprio_sel_357
               ? ipriosTmp_result_leftIprio_leftIprio_3_0_enable
               : ipriosTmp_result_leftIprio_rightIprio_3_0_enable)));
  wire [5:0]  ipriosTmp_result_leftIprio_3_0_idx =
    (ipriosTmp_result_leftIprio_sel_334
       ? ipriosTmp_result_leftIprio_leftIprio_3_0_idx
       : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_336
         ? ipriosTmp_result_leftIprio_rightIprio_3_0_idx
         : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_337
         ? (ipriosTmp_result_leftIprio_sel_338
              ? ipriosTmp_result_leftIprio_leftIprio_3_0_idx
              : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_340
                ? (ipriosTmp_result_leftIprio_sel_341
                     ? ipriosTmp_result_leftIprio_leftIprio_3_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_3_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_344
                ? (ipriosTmp_result_leftIprio_sel_345
                     ? ipriosTmp_result_leftIprio_rightIprio_3_0_idx
                     : ipriosTmp_result_leftIprio_leftIprio_3_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_349
                ? (ipriosTmp_result_leftIprio_leftIprio_3_0_greaterThan255
                     ? ipriosTmp_result_leftIprio_rightIprio_3_0_idx
                     : 6'h0)
                  | (ipriosTmp_result_leftIprio_leftIprio_3_0_greaterThan255
                       ? 6'h0
                       : ipriosTmp_result_leftIprio_sel_357
                           ? ipriosTmp_result_leftIprio_leftIprio_3_0_idx
                           : ipriosTmp_result_leftIprio_rightIprio_3_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_334 =
    mipriosSort_28_enable & ~mipriosSort_29_enable;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_336 =
    ~mipriosSort_28_enable & mipriosSort_29_enable;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_337 =
    mipriosSort_28_enable & mipriosSort_29_enable;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_338 =
    mipriosSort_28_isZero & mipriosSort_29_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_340 =
    mipriosSort_28_isZero & ~mipriosSort_29_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_344 =
    ~mipriosSort_28_isZero & mipriosSort_29_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_349 =
    ~mipriosSort_28_isZero & ~mipriosSort_29_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_357 =
    mipriosSort_28_prioNum <= mipriosSort_29_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_leftIprio_3_0_prioNum =
    (ipriosTmp_result_rightIprio_leftIprio_sel_334 & mipriosSort_28_enable
       ? io_in_miprios[15:8]
       : 8'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_336 & mipriosSort_29_enable
         ? io_in_miprios[47:40]
         : 8'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_337
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_338 & mipriosSort_28_enable
              ? io_in_miprios[15:8]
              : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_340
              & mipriosSort_29_enable
                ? io_in_miprios[47:40]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_344
              & mipriosSort_28_enable
                ? io_in_miprios[15:8]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_349
                ? (ipriosTmp_result_rightIprio_leftIprio_sel_357
                     ? mipriosSort_28_prioNum
                     : mipriosSort_29_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_3_0_enable =
    ipriosTmp_result_rightIprio_leftIprio_sel_334 & mipriosSort_28_enable
    | ipriosTmp_result_rightIprio_leftIprio_sel_336 & mipriosSort_29_enable
    | ipriosTmp_result_rightIprio_leftIprio_sel_337
    & (ipriosTmp_result_rightIprio_leftIprio_sel_338 & mipriosSort_28_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_340 & mipriosSort_29_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_344 & mipriosSort_28_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_349
       & (ipriosTmp_result_rightIprio_leftIprio_sel_357
            ? mipriosSort_28_enable
            : mipriosSort_29_enable));
  wire [5:0]  ipriosTmp_result_rightIprio_leftIprio_3_0_idx =
    (ipriosTmp_result_rightIprio_leftIprio_sel_334 ? 6'h1C : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_336 ? 6'h1D : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_337
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_338 ? 6'h1C : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_340 ? 6'h1D : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_344 ? 6'h1C : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_349
                ? {5'hE, ~ipriosTmp_result_rightIprio_leftIprio_sel_357}
                : 6'h0)
         : 6'h0);
  wire [7:0]  ipriosTmp_result_rightIprio_3_0_prioNum =
    ipriosTmp_result_rightIprio_3_0_enable
      ? ipriosTmp_result_rightIprio_leftIprio_3_0_prioNum
      : 8'h0;
  wire        ipriosTmp_result_rightIprio_3_0_isZero =
    ipriosTmp_result_rightIprio_3_0_enable
    & (ipriosTmp_result_rightIprio_leftIprio_sel_334 & mipriosSort_28_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_336 & mipriosSort_29_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_337
       & (ipriosTmp_result_rightIprio_leftIprio_sel_338 & mipriosSort_28_isZero
          | ipriosTmp_result_rightIprio_leftIprio_sel_340 & mipriosSort_29_isZero
          | ipriosTmp_result_rightIprio_leftIprio_sel_344 & mipriosSort_28_isZero
          | ipriosTmp_result_rightIprio_leftIprio_sel_349
          & (ipriosTmp_result_rightIprio_leftIprio_sel_357
               ? mipriosSort_28_isZero
               : mipriosSort_29_isZero)));
  wire [5:0]  ipriosTmp_result_rightIprio_3_0_idx =
    ipriosTmp_result_rightIprio_3_0_enable
      ? ipriosTmp_result_rightIprio_leftIprio_3_0_idx
      : 6'h0;
  wire        ipriosTmp_result_sel_334 =
    ipriosTmp_result_leftIprio_3_0_enable & ~ipriosTmp_result_rightIprio_3_0_enable;
  wire        ipriosTmp_result_sel_336 =
    ~ipriosTmp_result_leftIprio_3_0_enable & ipriosTmp_result_rightIprio_3_0_enable;
  wire        ipriosTmp_result_sel_337 =
    ipriosTmp_result_leftIprio_3_0_enable & ipriosTmp_result_rightIprio_3_0_enable;
  wire        ipriosTmp_result_sel_338 =
    ipriosTmp_result_leftIprio_3_0_isZero & ipriosTmp_result_rightIprio_3_0_isZero;
  wire        ipriosTmp_result_sel_340 =
    ipriosTmp_result_leftIprio_3_0_isZero & ~ipriosTmp_result_rightIprio_3_0_isZero;
  wire        ipriosTmp_result_sel_341 =
    ipriosTmp_result_leftIprio_3_0_idx < 6'h19;
  wire        ipriosTmp_result_sel_344 =
    ~ipriosTmp_result_leftIprio_3_0_isZero & ipriosTmp_result_rightIprio_3_0_isZero;
  wire        ipriosTmp_result_sel_345 =
    ipriosTmp_result_rightIprio_3_0_idx < 6'h19;
  wire        ipriosTmp_result_sel_349 =
    ~ipriosTmp_result_leftIprio_3_0_isZero & ~ipriosTmp_result_rightIprio_3_0_isZero;
  wire        ipriosTmp_result_sel_357 =
    ipriosTmp_result_leftIprio_3_0_prioNum <= ipriosTmp_result_rightIprio_3_0_prioNum;
  wire        gGen_22 =
    ipriosTmp_result_leftIprio_3_0_greaterThan255
    & ipriosTmp_result_rightIprio_3_0_enable;
  wire        gGen_23 =
    ipriosTmp_result_sel_336 & ipriosTmp_result_rightIprio_3_0_enable;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_889 =
    hsSortEn_0 & ~hsSortEn_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_891 =
    ~hsSortEn_0 & hsSortEn_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_892 =
    hsSortEn_0 & hsSortEn_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_893 =
    hsipriosSort_0_isZero & hsipriosSort_1_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_895 =
    hsipriosSort_0_isZero & ~hsipriosSort_1_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_899 =
    ~hsipriosSort_0_isZero & hsipriosSort_1_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_904 =
    ~hsipriosSort_0_isZero & ~hsipriosSort_1_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_912 =
    hsipriosSort_0_prioNum <= hsipriosSort_1_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_leftIprio_8_0_prioNum =
    (ipriosTmp_result_leftIprio_leftIprio_sel_889 & hsSortEn_0
       ? io_in_hsiprios[511:504]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_891
       & hsSortEn_1
         ? io_in_hsiprios[255:248]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_892
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_893
            & hsSortEn_0
            | ipriosTmp_result_leftIprio_leftIprio_sel_895
            & hsSortEn_0
              ? io_in_hsiprios[511:504]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_899
              & hsSortEn_1
                ? io_in_hsiprios[255:248]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_904
                ? (ipriosTmp_result_leftIprio_leftIprio_sel_912
                     ? hsipriosSort_0_prioNum
                     : hsipriosSort_1_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_leftIprio_8_0_isZero =
    ipriosTmp_result_leftIprio_leftIprio_sel_889 & hsipriosSort_0_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_891 & hsipriosSort_1_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_892
    & (ipriosTmp_result_leftIprio_leftIprio_sel_893 & hsipriosSort_0_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_895 & hsipriosSort_0_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_899 & hsipriosSort_1_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_904
       & (ipriosTmp_result_leftIprio_leftIprio_sel_912
            ? hsipriosSort_0_isZero
            : hsipriosSort_1_isZero));
  wire        ipriosTmp_result_leftIprio_leftIprio_8_0_enable =
    ipriosTmp_result_leftIprio_leftIprio_sel_889 & hsSortEn_0
    | ipriosTmp_result_leftIprio_leftIprio_sel_891
    & hsSortEn_1
    | ipriosTmp_result_leftIprio_leftIprio_sel_892
    & (ipriosTmp_result_leftIprio_leftIprio_sel_893
       & hsSortEn_0
       | ipriosTmp_result_leftIprio_leftIprio_sel_895
       & hsSortEn_0
       | ipriosTmp_result_leftIprio_leftIprio_sel_899
       & hsSortEn_1
       | ipriosTmp_result_leftIprio_leftIprio_sel_904
       & (ipriosTmp_result_leftIprio_leftIprio_sel_912
            ? hsSortEn_0
            : hsSortEn_1));
  wire [5:0]  ipriosTmp_result_leftIprio_leftIprio_8_0_idx =
    {5'h0, ipriosTmp_result_leftIprio_leftIprio_sel_891}
    | (ipriosTmp_result_leftIprio_leftIprio_sel_892
         ? {5'h0, ipriosTmp_result_leftIprio_leftIprio_sel_899}
           | (ipriosTmp_result_leftIprio_leftIprio_sel_904
                ? {5'h0, ~ipriosTmp_result_leftIprio_leftIprio_sel_912}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_889 =
    hsSortEn_2 & ~hsSortEn_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_891 =
    ~hsSortEn_2 & hsSortEn_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_892 =
    hsSortEn_2 & hsSortEn_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_893 =
    hsipriosSort_2_isZero & hsipriosSort_3_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_895 =
    hsipriosSort_2_isZero & ~hsipriosSort_3_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_899 =
    ~hsipriosSort_2_isZero & hsipriosSort_3_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_904 =
    ~hsipriosSort_2_isZero & ~hsipriosSort_3_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_912 =
    hsipriosSort_2_prioNum <= hsipriosSort_3_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_rightIprio_8_0_prioNum =
    (ipriosTmp_result_leftIprio_rightIprio_sel_889
     & hsSortEn_2
       ? io_in_hsiprios[503:496]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_891
       & hsSortEn_3
         ? io_in_hsiprios[495:488]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_892
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_893
            & hsSortEn_2
            | ipriosTmp_result_leftIprio_rightIprio_sel_895
            & hsSortEn_2
              ? io_in_hsiprios[503:496]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_899
              & hsSortEn_3
                ? io_in_hsiprios[495:488]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_904
                ? (ipriosTmp_result_leftIprio_rightIprio_sel_912
                     ? hsipriosSort_2_prioNum
                     : hsipriosSort_3_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_8_0_isZero =
    ipriosTmp_result_leftIprio_rightIprio_sel_889 & hsipriosSort_2_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_891 & hsipriosSort_3_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_892
    & (ipriosTmp_result_leftIprio_rightIprio_sel_893 & hsipriosSort_2_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_895 & hsipriosSort_2_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_899 & hsipriosSort_3_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_904
       & (ipriosTmp_result_leftIprio_rightIprio_sel_912
            ? hsipriosSort_2_isZero
            : hsipriosSort_3_isZero));
  wire        ipriosTmp_result_leftIprio_rightIprio_8_0_enable =
    ipriosTmp_result_leftIprio_rightIprio_sel_889 & hsSortEn_2
    | ipriosTmp_result_leftIprio_rightIprio_sel_891
    & hsSortEn_3
    | ipriosTmp_result_leftIprio_rightIprio_sel_892
    & (ipriosTmp_result_leftIprio_rightIprio_sel_893
       & hsSortEn_2
       | ipriosTmp_result_leftIprio_rightIprio_sel_895
       & hsSortEn_2
       | ipriosTmp_result_leftIprio_rightIprio_sel_899
       & hsSortEn_3
       | ipriosTmp_result_leftIprio_rightIprio_sel_904
       & (ipriosTmp_result_leftIprio_rightIprio_sel_912
            ? hsSortEn_2
            : hsSortEn_3));
  wire [5:0]  ipriosTmp_result_leftIprio_rightIprio_8_0_idx =
    {4'h0, ipriosTmp_result_leftIprio_rightIprio_sel_889, 1'h0}
    | (ipriosTmp_result_leftIprio_rightIprio_sel_891 ? 6'h3 : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_892
         ? {4'h0,
            ipriosTmp_result_leftIprio_rightIprio_sel_893
              | ipriosTmp_result_leftIprio_rightIprio_sel_895,
            1'h0} | (ipriosTmp_result_leftIprio_rightIprio_sel_899 ? 6'h3 : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_904
                ? {5'h1, ~ipriosTmp_result_leftIprio_rightIprio_sel_912}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_sel_889 =
    ipriosTmp_result_leftIprio_leftIprio_8_0_enable
    & ~ipriosTmp_result_leftIprio_rightIprio_8_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_891 =
    ~ipriosTmp_result_leftIprio_leftIprio_8_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_8_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_892 =
    ipriosTmp_result_leftIprio_leftIprio_8_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_8_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_893 =
    ipriosTmp_result_leftIprio_leftIprio_8_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_8_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_895 =
    ipriosTmp_result_leftIprio_leftIprio_8_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_8_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_896 =
    ipriosTmp_result_leftIprio_leftIprio_8_0_idx < 6'h1C;
  wire        ipriosTmp_result_leftIprio_sel_899 =
    ~ipriosTmp_result_leftIprio_leftIprio_8_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_8_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_900 =
    ipriosTmp_result_leftIprio_rightIprio_8_0_idx < 6'h1C;
  wire        ipriosTmp_result_leftIprio_sel_904 =
    ~ipriosTmp_result_leftIprio_leftIprio_8_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_8_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_912 =
    ipriosTmp_result_leftIprio_leftIprio_8_0_prioNum <= ipriosTmp_result_leftIprio_rightIprio_8_0_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_8_0_prioNum =
    (ipriosTmp_result_leftIprio_sel_889
       ? ipriosTmp_result_leftIprio_leftIprio_8_0_prioNum
       : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_891
         ? ipriosTmp_result_leftIprio_rightIprio_8_0_prioNum
         : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_892
         ? (ipriosTmp_result_leftIprio_sel_893
              ? ipriosTmp_result_leftIprio_leftIprio_8_0_prioNum
              : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_895
                ? (ipriosTmp_result_leftIprio_sel_896
                     ? ipriosTmp_result_leftIprio_leftIprio_8_0_prioNum
                     : ipriosTmp_result_leftIprio_rightIprio_8_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_899
                ? (ipriosTmp_result_leftIprio_sel_900
                     ? ipriosTmp_result_leftIprio_rightIprio_8_0_prioNum
                     : ipriosTmp_result_leftIprio_leftIprio_8_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_904
                ? (ipriosTmp_result_leftIprio_sel_912
                     ? ipriosTmp_result_leftIprio_leftIprio_8_0_prioNum
                     : ipriosTmp_result_leftIprio_rightIprio_8_0_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_8_0_isZero =
    ipriosTmp_result_leftIprio_sel_889
    & ipriosTmp_result_leftIprio_leftIprio_8_0_isZero
    | ipriosTmp_result_leftIprio_sel_891
    & ipriosTmp_result_leftIprio_rightIprio_8_0_isZero
    | ipriosTmp_result_leftIprio_sel_892
    & (ipriosTmp_result_leftIprio_sel_893
       & ipriosTmp_result_leftIprio_leftIprio_8_0_isZero
       | ipriosTmp_result_leftIprio_sel_895
       & (ipriosTmp_result_leftIprio_sel_896
            ? ipriosTmp_result_leftIprio_leftIprio_8_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_8_0_isZero)
       | ipriosTmp_result_leftIprio_sel_899
       & (ipriosTmp_result_leftIprio_sel_900
            ? ipriosTmp_result_leftIprio_rightIprio_8_0_isZero
            : ipriosTmp_result_leftIprio_leftIprio_8_0_isZero)
       | ipriosTmp_result_leftIprio_sel_904
       & (ipriosTmp_result_leftIprio_sel_912
            ? ipriosTmp_result_leftIprio_leftIprio_8_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_8_0_isZero));
  wire        ipriosTmp_result_leftIprio_8_0_enable =
    ipriosTmp_result_leftIprio_sel_889
    & ipriosTmp_result_leftIprio_leftIprio_8_0_enable
    | ipriosTmp_result_leftIprio_sel_891
    & ipriosTmp_result_leftIprio_rightIprio_8_0_enable
    | ipriosTmp_result_leftIprio_sel_892
    & (ipriosTmp_result_leftIprio_sel_893
       & ipriosTmp_result_leftIprio_leftIprio_8_0_enable
       | ipriosTmp_result_leftIprio_sel_895
       & (ipriosTmp_result_leftIprio_sel_896
            ? ipriosTmp_result_leftIprio_leftIprio_8_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_8_0_enable)
       | ipriosTmp_result_leftIprio_sel_899
       & (ipriosTmp_result_leftIprio_sel_900
            ? ipriosTmp_result_leftIprio_rightIprio_8_0_enable
            : ipriosTmp_result_leftIprio_leftIprio_8_0_enable)
       | ipriosTmp_result_leftIprio_sel_904
       & (ipriosTmp_result_leftIprio_sel_912
            ? ipriosTmp_result_leftIprio_leftIprio_8_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_8_0_enable));
  wire [5:0]  ipriosTmp_result_leftIprio_8_0_idx =
    (ipriosTmp_result_leftIprio_sel_889
       ? ipriosTmp_result_leftIprio_leftIprio_8_0_idx
       : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_891
         ? ipriosTmp_result_leftIprio_rightIprio_8_0_idx
         : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_892
         ? (ipriosTmp_result_leftIprio_sel_893
              ? ipriosTmp_result_leftIprio_leftIprio_8_0_idx
              : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_895
                ? (ipriosTmp_result_leftIprio_sel_896
                     ? ipriosTmp_result_leftIprio_leftIprio_8_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_8_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_899
                ? (ipriosTmp_result_leftIprio_sel_900
                     ? ipriosTmp_result_leftIprio_rightIprio_8_0_idx
                     : ipriosTmp_result_leftIprio_leftIprio_8_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_904
                ? (ipriosTmp_result_leftIprio_sel_912
                     ? ipriosTmp_result_leftIprio_leftIprio_8_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_8_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_889 =
    hsSortEn_4 & ~hsSortEn_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_891 =
    ~hsSortEn_4 & hsSortEn_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_892 =
    hsSortEn_4 & hsSortEn_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_893 =
    hsipriosSort_4_isZero & hsipriosSort_5_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_895 =
    hsipriosSort_4_isZero & ~hsipriosSort_5_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_899 =
    ~hsipriosSort_4_isZero & hsipriosSort_5_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_904 =
    ~hsipriosSort_4_isZero & ~hsipriosSort_5_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_912 =
    hsipriosSort_4_prioNum <= hsipriosSort_5_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_leftIprio_8_0_prioNum =
    (ipriosTmp_result_rightIprio_leftIprio_sel_889
     & hsSortEn_4
       ? io_in_hsiprios[247:240]
       : 8'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_891
       & hsSortEn_5
         ? io_in_hsiprios[487:480]
         : 8'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_892
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_893
            & hsSortEn_4
            | ipriosTmp_result_rightIprio_leftIprio_sel_895
            & hsSortEn_4
              ? io_in_hsiprios[247:240]
              : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_899
              & hsSortEn_5
                ? io_in_hsiprios[487:480]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_904
                ? (ipriosTmp_result_rightIprio_leftIprio_sel_912
                     ? hsipriosSort_4_prioNum
                     : hsipriosSort_5_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_8_0_isZero =
    ipriosTmp_result_rightIprio_leftIprio_sel_889 & hsipriosSort_4_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_891 & hsipriosSort_5_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_892
    & (ipriosTmp_result_rightIprio_leftIprio_sel_893 & hsipriosSort_4_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_895 & hsipriosSort_4_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_899 & hsipriosSort_5_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_904
       & (ipriosTmp_result_rightIprio_leftIprio_sel_912
            ? hsipriosSort_4_isZero
            : hsipriosSort_5_isZero));
  wire        ipriosTmp_result_rightIprio_leftIprio_8_0_enable =
    ipriosTmp_result_rightIprio_leftIprio_sel_889 & hsSortEn_4
    | ipriosTmp_result_rightIprio_leftIprio_sel_891
    & hsSortEn_5
    | ipriosTmp_result_rightIprio_leftIprio_sel_892
    & (ipriosTmp_result_rightIprio_leftIprio_sel_893
       & hsSortEn_4
       | ipriosTmp_result_rightIprio_leftIprio_sel_895
       & hsSortEn_4
       | ipriosTmp_result_rightIprio_leftIprio_sel_899
       & hsSortEn_5
       | ipriosTmp_result_rightIprio_leftIprio_sel_904
       & (ipriosTmp_result_rightIprio_leftIprio_sel_912
            ? hsSortEn_4
            : hsSortEn_5));
  wire [5:0]  ipriosTmp_result_rightIprio_leftIprio_8_0_idx =
    {3'h0, ipriosTmp_result_rightIprio_leftIprio_sel_889, 2'h0}
    | (ipriosTmp_result_rightIprio_leftIprio_sel_891 ? 6'h5 : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_892
         ? {3'h0,
            ipriosTmp_result_rightIprio_leftIprio_sel_893
              | ipriosTmp_result_rightIprio_leftIprio_sel_895,
            2'h0} | (ipriosTmp_result_rightIprio_leftIprio_sel_899 ? 6'h5 : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_904
                ? {5'h2, ~ipriosTmp_result_rightIprio_leftIprio_sel_912}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_889 =
    hsSortEn_6 & ~hsSortEn_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_891 =
    ~hsSortEn_6 & hsSortEn_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_892 =
    hsSortEn_6 & hsSortEn_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_893 =
    hsipriosSort_6_isZero & hsipriosSort_7_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_895 =
    hsipriosSort_6_isZero & ~hsipriosSort_7_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_899 =
    ~hsipriosSort_6_isZero & hsipriosSort_7_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_904 =
    ~hsipriosSort_6_isZero & ~hsipriosSort_7_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_912 =
    hsipriosSort_6_prioNum <= hsipriosSort_7_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_rightIprio_8_0_prioNum =
    (ipriosTmp_result_rightIprio_rightIprio_sel_889
     & hsSortEn_6
       ? io_in_hsiprios[383:376]
       : 8'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_891
       & hsSortEn_7
         ? io_in_hsiprios[191:184]
         : 8'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_892
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_893
            & hsSortEn_6
            | ipriosTmp_result_rightIprio_rightIprio_sel_895
            & hsSortEn_6
              ? io_in_hsiprios[383:376]
              : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_899
              & hsSortEn_7
                ? io_in_hsiprios[191:184]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_904
                ? (ipriosTmp_result_rightIprio_rightIprio_sel_912
                     ? hsipriosSort_6_prioNum
                     : hsipriosSort_7_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_8_0_isZero =
    ipriosTmp_result_rightIprio_rightIprio_sel_889 & hsipriosSort_6_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_891 & hsipriosSort_7_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_892
    & (ipriosTmp_result_rightIprio_rightIprio_sel_893 & hsipriosSort_6_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_895 & hsipriosSort_6_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_899 & hsipriosSort_7_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_904
       & (ipriosTmp_result_rightIprio_rightIprio_sel_912
            ? hsipriosSort_6_isZero
            : hsipriosSort_7_isZero));
  wire        ipriosTmp_result_rightIprio_rightIprio_8_0_enable =
    ipriosTmp_result_rightIprio_rightIprio_sel_889
    & hsSortEn_6
    | ipriosTmp_result_rightIprio_rightIprio_sel_891
    & hsSortEn_7
    | ipriosTmp_result_rightIprio_rightIprio_sel_892
    & (ipriosTmp_result_rightIprio_rightIprio_sel_893
       & hsSortEn_6
       | ipriosTmp_result_rightIprio_rightIprio_sel_895
       & hsSortEn_6
       | ipriosTmp_result_rightIprio_rightIprio_sel_899
       & hsSortEn_7
       | ipriosTmp_result_rightIprio_rightIprio_sel_904
       & (ipriosTmp_result_rightIprio_rightIprio_sel_912
            ? hsSortEn_6
            : hsSortEn_7));
  wire [5:0]  ipriosTmp_result_rightIprio_rightIprio_8_0_idx =
    (ipriosTmp_result_rightIprio_rightIprio_sel_889 ? 6'h6 : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_891 ? 6'h7 : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_892
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_893
            | ipriosTmp_result_rightIprio_rightIprio_sel_895
              ? 6'h6
              : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_899 ? 6'h7 : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_904
                ? {5'h3, ~ipriosTmp_result_rightIprio_rightIprio_sel_912}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_sel_889 =
    ipriosTmp_result_rightIprio_leftIprio_8_0_enable
    & ~ipriosTmp_result_rightIprio_rightIprio_8_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_891 =
    ~ipriosTmp_result_rightIprio_leftIprio_8_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_8_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_892 =
    ipriosTmp_result_rightIprio_leftIprio_8_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_8_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_893 =
    ipriosTmp_result_rightIprio_leftIprio_8_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_8_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_895 =
    ipriosTmp_result_rightIprio_leftIprio_8_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_8_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_896 =
    ipriosTmp_result_rightIprio_leftIprio_8_0_idx < 6'h1C;
  wire        ipriosTmp_result_rightIprio_sel_899 =
    ~ipriosTmp_result_rightIprio_leftIprio_8_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_8_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_900 =
    ipriosTmp_result_rightIprio_rightIprio_8_0_idx < 6'h1C;
  wire        ipriosTmp_result_rightIprio_sel_904 =
    ~ipriosTmp_result_rightIprio_leftIprio_8_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_8_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_912 =
    ipriosTmp_result_rightIprio_leftIprio_8_0_prioNum <= ipriosTmp_result_rightIprio_rightIprio_8_0_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_8_0_prioNum =
    (ipriosTmp_result_rightIprio_sel_889
       ? ipriosTmp_result_rightIprio_leftIprio_8_0_prioNum
       : 8'h0)
    | (ipriosTmp_result_rightIprio_sel_891
         ? ipriosTmp_result_rightIprio_rightIprio_8_0_prioNum
         : 8'h0)
    | (ipriosTmp_result_rightIprio_sel_892
         ? (ipriosTmp_result_rightIprio_sel_893
              ? ipriosTmp_result_rightIprio_leftIprio_8_0_prioNum
              : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_895
                ? (ipriosTmp_result_rightIprio_sel_896
                     ? ipriosTmp_result_rightIprio_leftIprio_8_0_prioNum
                     : ipriosTmp_result_rightIprio_rightIprio_8_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_899
                ? (ipriosTmp_result_rightIprio_sel_900
                     ? ipriosTmp_result_rightIprio_rightIprio_8_0_prioNum
                     : ipriosTmp_result_rightIprio_leftIprio_8_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_904
                ? (ipriosTmp_result_rightIprio_sel_912
                     ? ipriosTmp_result_rightIprio_leftIprio_8_0_prioNum
                     : ipriosTmp_result_rightIprio_rightIprio_8_0_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_8_0_isZero =
    ipriosTmp_result_rightIprio_sel_889
    & ipriosTmp_result_rightIprio_leftIprio_8_0_isZero
    | ipriosTmp_result_rightIprio_sel_891
    & ipriosTmp_result_rightIprio_rightIprio_8_0_isZero
    | ipriosTmp_result_rightIprio_sel_892
    & (ipriosTmp_result_rightIprio_sel_893
       & ipriosTmp_result_rightIprio_leftIprio_8_0_isZero
       | ipriosTmp_result_rightIprio_sel_895
       & (ipriosTmp_result_rightIprio_sel_896
            ? ipriosTmp_result_rightIprio_leftIprio_8_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_8_0_isZero)
       | ipriosTmp_result_rightIprio_sel_899
       & (ipriosTmp_result_rightIprio_sel_900
            ? ipriosTmp_result_rightIprio_rightIprio_8_0_isZero
            : ipriosTmp_result_rightIprio_leftIprio_8_0_isZero)
       | ipriosTmp_result_rightIprio_sel_904
       & (ipriosTmp_result_rightIprio_sel_912
            ? ipriosTmp_result_rightIprio_leftIprio_8_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_8_0_isZero));
  wire        ipriosTmp_result_rightIprio_8_0_enable =
    ipriosTmp_result_rightIprio_sel_889
    & ipriosTmp_result_rightIprio_leftIprio_8_0_enable
    | ipriosTmp_result_rightIprio_sel_891
    & ipriosTmp_result_rightIprio_rightIprio_8_0_enable
    | ipriosTmp_result_rightIprio_sel_892
    & (ipriosTmp_result_rightIprio_sel_893
       & ipriosTmp_result_rightIprio_leftIprio_8_0_enable
       | ipriosTmp_result_rightIprio_sel_895
       & (ipriosTmp_result_rightIprio_sel_896
            ? ipriosTmp_result_rightIprio_leftIprio_8_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_8_0_enable)
       | ipriosTmp_result_rightIprio_sel_899
       & (ipriosTmp_result_rightIprio_sel_900
            ? ipriosTmp_result_rightIprio_rightIprio_8_0_enable
            : ipriosTmp_result_rightIprio_leftIprio_8_0_enable)
       | ipriosTmp_result_rightIprio_sel_904
       & (ipriosTmp_result_rightIprio_sel_912
            ? ipriosTmp_result_rightIprio_leftIprio_8_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_8_0_enable));
  wire [5:0]  ipriosTmp_result_rightIprio_8_0_idx =
    (ipriosTmp_result_rightIprio_sel_889
       ? ipriosTmp_result_rightIprio_leftIprio_8_0_idx
       : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_891
         ? ipriosTmp_result_rightIprio_rightIprio_8_0_idx
         : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_892
         ? (ipriosTmp_result_rightIprio_sel_893
              ? ipriosTmp_result_rightIprio_leftIprio_8_0_idx
              : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_895
                ? (ipriosTmp_result_rightIprio_sel_896
                     ? ipriosTmp_result_rightIprio_leftIprio_8_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_8_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_899
                ? (ipriosTmp_result_rightIprio_sel_900
                     ? ipriosTmp_result_rightIprio_rightIprio_8_0_idx
                     : ipriosTmp_result_rightIprio_leftIprio_8_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_904
                ? (ipriosTmp_result_rightIprio_sel_912
                     ? ipriosTmp_result_rightIprio_leftIprio_8_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_8_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_sel_889 =
    ipriosTmp_result_leftIprio_8_0_enable & ~ipriosTmp_result_rightIprio_8_0_enable;
  wire        ipriosTmp_result_sel_891 =
    ~ipriosTmp_result_leftIprio_8_0_enable & ipriosTmp_result_rightIprio_8_0_enable;
  wire        ipriosTmp_result_sel_892 =
    ipriosTmp_result_leftIprio_8_0_enable & ipriosTmp_result_rightIprio_8_0_enable;
  wire        ipriosTmp_result_sel_893 =
    ipriosTmp_result_leftIprio_8_0_isZero & ipriosTmp_result_rightIprio_8_0_isZero;
  wire        ipriosTmp_result_sel_895 =
    ipriosTmp_result_leftIprio_8_0_isZero & ~ipriosTmp_result_rightIprio_8_0_isZero;
  wire        ipriosTmp_result_sel_896 =
    ipriosTmp_result_leftIprio_8_0_idx < 6'h1C;
  wire        ipriosTmp_result_sel_899 =
    ~ipriosTmp_result_leftIprio_8_0_isZero & ipriosTmp_result_rightIprio_8_0_isZero;
  wire        ipriosTmp_result_sel_900 =
    ipriosTmp_result_rightIprio_8_0_idx < 6'h1C;
  wire        ipriosTmp_result_sel_904 =
    ~ipriosTmp_result_leftIprio_8_0_isZero & ~ipriosTmp_result_rightIprio_8_0_isZero;
  wire        ipriosTmp_result_sel_912 =
    ipriosTmp_result_leftIprio_8_0_prioNum <= ipriosTmp_result_rightIprio_8_0_prioNum;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1000 =
    hsSortEn_1_0 & ~hsSortEn_1_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1002 =
    ~hsSortEn_1_0 & hsSortEn_1_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1003 =
    hsSortEn_1_0 & hsSortEn_1_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1004 =
    hsipriosSort_8_isZero & hsipriosSort_9_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1006 =
    hsipriosSort_8_isZero & ~hsipriosSort_9_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1010 =
    ~hsipriosSort_8_isZero & hsipriosSort_9_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1015 =
    ~hsipriosSort_8_isZero & ~hsipriosSort_9_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1023 =
    hsipriosSort_8_prioNum <= hsipriosSort_9_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_leftIprio_9_0_prioNum =
    (ipriosTmp_result_leftIprio_leftIprio_sel_1000
     & hsSortEn_1_0
       ? io_in_hsiprios[375:368]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1002
       & hsSortEn_1_1
         ? io_in_hsiprios[367:360]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1003
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_1004
            & hsSortEn_1_0
            | ipriosTmp_result_leftIprio_leftIprio_sel_1006
            & hsSortEn_1_0
              ? io_in_hsiprios[375:368]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1010
              & hsSortEn_1_1
                ? io_in_hsiprios[367:360]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1015
                ? (ipriosTmp_result_leftIprio_leftIprio_sel_1023
                     ? hsipriosSort_8_prioNum
                     : hsipriosSort_9_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_leftIprio_9_0_isZero =
    ipriosTmp_result_leftIprio_leftIprio_sel_1000 & hsipriosSort_8_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1002 & hsipriosSort_9_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1003
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1004 & hsipriosSort_8_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1006 & hsipriosSort_8_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1010 & hsipriosSort_9_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1015
       & (ipriosTmp_result_leftIprio_leftIprio_sel_1023
            ? hsipriosSort_8_isZero
            : hsipriosSort_9_isZero));
  wire        ipriosTmp_result_leftIprio_leftIprio_9_0_enable =
    ipriosTmp_result_leftIprio_leftIprio_sel_1000
    & hsSortEn_1_0
    | ipriosTmp_result_leftIprio_leftIprio_sel_1002
    & hsSortEn_1_1
    | ipriosTmp_result_leftIprio_leftIprio_sel_1003
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1004
       & hsSortEn_1_0
       | ipriosTmp_result_leftIprio_leftIprio_sel_1006
       & hsSortEn_1_0
       | ipriosTmp_result_leftIprio_leftIprio_sel_1010
       & hsSortEn_1_1
       | ipriosTmp_result_leftIprio_leftIprio_sel_1015
       & (ipriosTmp_result_leftIprio_leftIprio_sel_1023
            ? hsSortEn_1_0
            : hsSortEn_1_1));
  wire [5:0]  ipriosTmp_result_leftIprio_leftIprio_9_0_idx =
    {2'h0, ipriosTmp_result_leftIprio_leftIprio_sel_1000, 3'h0}
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1002 ? 6'h9 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1003
         ? {2'h0,
            ipriosTmp_result_leftIprio_leftIprio_sel_1004
              | ipriosTmp_result_leftIprio_leftIprio_sel_1006,
            3'h0} | (ipriosTmp_result_leftIprio_leftIprio_sel_1010 ? 6'h9 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1015
                ? {5'h4, ~ipriosTmp_result_leftIprio_leftIprio_sel_1023}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1000 =
    hsSortEn_1_2 & ~hsSortEn_1_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1002 =
    ~hsSortEn_1_2 & hsSortEn_1_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1003 =
    hsSortEn_1_2 & hsSortEn_1_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1004 =
    hsipriosSort_10_isZero & hsipriosSort_11_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1006 =
    hsipriosSort_10_isZero & ~hsipriosSort_11_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1010 =
    ~hsipriosSort_10_isZero & hsipriosSort_11_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1015 =
    ~hsipriosSort_10_isZero & ~hsipriosSort_11_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1023 =
    hsipriosSort_10_prioNum <= hsipriosSort_11_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_rightIprio_9_0_prioNum =
    (ipriosTmp_result_leftIprio_rightIprio_sel_1000
     & hsSortEn_1_2
       ? io_in_hsiprios[183:176]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1002
       & hsSortEn_1_3
         ? io_in_hsiprios[359:352]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1003
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_1004
            & hsSortEn_1_2
            | ipriosTmp_result_leftIprio_rightIprio_sel_1006
            & hsSortEn_1_2
              ? io_in_hsiprios[183:176]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1010
              & hsSortEn_1_3
                ? io_in_hsiprios[359:352]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1015
                ? (ipriosTmp_result_leftIprio_rightIprio_sel_1023
                     ? hsipriosSort_10_prioNum
                     : hsipriosSort_11_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_9_0_isZero =
    ipriosTmp_result_leftIprio_rightIprio_sel_1000 & hsipriosSort_10_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1002 & hsipriosSort_11_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1003
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1004 & hsipriosSort_10_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1006 & hsipriosSort_10_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1010 & hsipriosSort_11_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1015
       & (ipriosTmp_result_leftIprio_rightIprio_sel_1023
            ? hsipriosSort_10_isZero
            : hsipriosSort_11_isZero));
  wire        ipriosTmp_result_leftIprio_rightIprio_9_0_enable =
    ipriosTmp_result_leftIprio_rightIprio_sel_1000
    & hsSortEn_1_2
    | ipriosTmp_result_leftIprio_rightIprio_sel_1002
    & hsSortEn_1_3
    | ipriosTmp_result_leftIprio_rightIprio_sel_1003
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1004
       & hsSortEn_1_2
       | ipriosTmp_result_leftIprio_rightIprio_sel_1006
       & hsSortEn_1_2
       | ipriosTmp_result_leftIprio_rightIprio_sel_1010
       & hsSortEn_1_3
       | ipriosTmp_result_leftIprio_rightIprio_sel_1015
       & (ipriosTmp_result_leftIprio_rightIprio_sel_1023
            ? hsSortEn_1_2
            : hsSortEn_1_3));
  wire [5:0]  ipriosTmp_result_leftIprio_rightIprio_9_0_idx =
    (ipriosTmp_result_leftIprio_rightIprio_sel_1000 ? 6'hA : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1002 ? 6'hB : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1003
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_1004
            | ipriosTmp_result_leftIprio_rightIprio_sel_1006
              ? 6'hA
              : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1010 ? 6'hB : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1015
                ? {5'h5, ~ipriosTmp_result_leftIprio_rightIprio_sel_1023}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_sel_1000 =
    ipriosTmp_result_leftIprio_leftIprio_9_0_enable
    & ~ipriosTmp_result_leftIprio_rightIprio_9_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1002 =
    ~ipriosTmp_result_leftIprio_leftIprio_9_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_9_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1003 =
    ipriosTmp_result_leftIprio_leftIprio_9_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_9_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1004 =
    ipriosTmp_result_leftIprio_leftIprio_9_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_9_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1006 =
    ipriosTmp_result_leftIprio_leftIprio_9_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_9_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1007 =
    ipriosTmp_result_leftIprio_leftIprio_9_0_idx < 6'h1C;
  wire        ipriosTmp_result_leftIprio_sel_1010 =
    ~ipriosTmp_result_leftIprio_leftIprio_9_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_9_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1011 =
    ipriosTmp_result_leftIprio_rightIprio_9_0_idx < 6'h1C;
  wire        ipriosTmp_result_leftIprio_sel_1015 =
    ~ipriosTmp_result_leftIprio_leftIprio_9_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_9_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1023 =
    ipriosTmp_result_leftIprio_leftIprio_9_0_prioNum <= ipriosTmp_result_leftIprio_rightIprio_9_0_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_9_0_prioNum =
    (ipriosTmp_result_leftIprio_sel_1000
       ? ipriosTmp_result_leftIprio_leftIprio_9_0_prioNum
       : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_1002
         ? ipriosTmp_result_leftIprio_rightIprio_9_0_prioNum
         : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_1003
         ? (ipriosTmp_result_leftIprio_sel_1004
              ? ipriosTmp_result_leftIprio_leftIprio_9_0_prioNum
              : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1006
                ? (ipriosTmp_result_leftIprio_sel_1007
                     ? ipriosTmp_result_leftIprio_leftIprio_9_0_prioNum
                     : ipriosTmp_result_leftIprio_rightIprio_9_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1010
                ? (ipriosTmp_result_leftIprio_sel_1011
                     ? ipriosTmp_result_leftIprio_rightIprio_9_0_prioNum
                     : ipriosTmp_result_leftIprio_leftIprio_9_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1015
                ? (ipriosTmp_result_leftIprio_sel_1023
                     ? ipriosTmp_result_leftIprio_leftIprio_9_0_prioNum
                     : ipriosTmp_result_leftIprio_rightIprio_9_0_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_9_0_isZero =
    ipriosTmp_result_leftIprio_sel_1000
    & ipriosTmp_result_leftIprio_leftIprio_9_0_isZero
    | ipriosTmp_result_leftIprio_sel_1002
    & ipriosTmp_result_leftIprio_rightIprio_9_0_isZero
    | ipriosTmp_result_leftIprio_sel_1003
    & (ipriosTmp_result_leftIprio_sel_1004
       & ipriosTmp_result_leftIprio_leftIprio_9_0_isZero
       | ipriosTmp_result_leftIprio_sel_1006
       & (ipriosTmp_result_leftIprio_sel_1007
            ? ipriosTmp_result_leftIprio_leftIprio_9_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_9_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1010
       & (ipriosTmp_result_leftIprio_sel_1011
            ? ipriosTmp_result_leftIprio_rightIprio_9_0_isZero
            : ipriosTmp_result_leftIprio_leftIprio_9_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1015
       & (ipriosTmp_result_leftIprio_sel_1023
            ? ipriosTmp_result_leftIprio_leftIprio_9_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_9_0_isZero));
  wire        ipriosTmp_result_leftIprio_9_0_enable =
    ipriosTmp_result_leftIprio_sel_1000
    & ipriosTmp_result_leftIprio_leftIprio_9_0_enable
    | ipriosTmp_result_leftIprio_sel_1002
    & ipriosTmp_result_leftIprio_rightIprio_9_0_enable
    | ipriosTmp_result_leftIprio_sel_1003
    & (ipriosTmp_result_leftIprio_sel_1004
       & ipriosTmp_result_leftIprio_leftIprio_9_0_enable
       | ipriosTmp_result_leftIprio_sel_1006
       & (ipriosTmp_result_leftIprio_sel_1007
            ? ipriosTmp_result_leftIprio_leftIprio_9_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_9_0_enable)
       | ipriosTmp_result_leftIprio_sel_1010
       & (ipriosTmp_result_leftIprio_sel_1011
            ? ipriosTmp_result_leftIprio_rightIprio_9_0_enable
            : ipriosTmp_result_leftIprio_leftIprio_9_0_enable)
       | ipriosTmp_result_leftIprio_sel_1015
       & (ipriosTmp_result_leftIprio_sel_1023
            ? ipriosTmp_result_leftIprio_leftIprio_9_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_9_0_enable));
  wire [5:0]  ipriosTmp_result_leftIprio_9_0_idx =
    (ipriosTmp_result_leftIprio_sel_1000
       ? ipriosTmp_result_leftIprio_leftIprio_9_0_idx
       : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1002
         ? ipriosTmp_result_leftIprio_rightIprio_9_0_idx
         : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1003
         ? (ipriosTmp_result_leftIprio_sel_1004
              ? ipriosTmp_result_leftIprio_leftIprio_9_0_idx
              : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1006
                ? (ipriosTmp_result_leftIprio_sel_1007
                     ? ipriosTmp_result_leftIprio_leftIprio_9_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_9_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1010
                ? (ipriosTmp_result_leftIprio_sel_1011
                     ? ipriosTmp_result_leftIprio_rightIprio_9_0_idx
                     : ipriosTmp_result_leftIprio_leftIprio_9_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1015
                ? (ipriosTmp_result_leftIprio_sel_1023
                     ? ipriosTmp_result_leftIprio_leftIprio_9_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_9_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1000 =
    hsSortEn_1_4 & ~hsSortEn_1_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1002 =
    ~hsSortEn_1_4 & hsSortEn_1_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1003 =
    hsSortEn_1_4 & hsSortEn_1_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1004 =
    hsipriosSort_12_isZero & hsipriosSort_13_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1006 =
    hsipriosSort_12_isZero & ~hsipriosSort_13_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1010 =
    ~hsipriosSort_12_isZero & hsipriosSort_13_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1015 =
    ~hsipriosSort_12_isZero & ~hsipriosSort_13_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1023 =
    hsipriosSort_12_prioNum <= hsipriosSort_13_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_leftIprio_9_0_prioNum =
    (ipriosTmp_result_rightIprio_leftIprio_sel_1000
     & hsSortEn_1_4
       ? io_in_hsiprios[351:344]
       : 8'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1002
       & hsSortEn_1_5
         ? io_in_hsiprios[175:168]
         : 8'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1003
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_1004
            & hsSortEn_1_4
            | ipriosTmp_result_rightIprio_leftIprio_sel_1006
            & hsSortEn_1_4
              ? io_in_hsiprios[351:344]
              : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1010
              & hsSortEn_1_5
                ? io_in_hsiprios[175:168]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1015
                ? (ipriosTmp_result_rightIprio_leftIprio_sel_1023
                     ? hsipriosSort_12_prioNum
                     : hsipriosSort_13_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_9_0_isZero =
    ipriosTmp_result_rightIprio_leftIprio_sel_1000 & hsipriosSort_12_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1002 & hsipriosSort_13_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1003
    & (ipriosTmp_result_rightIprio_leftIprio_sel_1004 & hsipriosSort_12_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1006 & hsipriosSort_12_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1010 & hsipriosSort_13_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1015
       & (ipriosTmp_result_rightIprio_leftIprio_sel_1023
            ? hsipriosSort_12_isZero
            : hsipriosSort_13_isZero));
  wire        ipriosTmp_result_rightIprio_leftIprio_9_0_enable =
    ipriosTmp_result_rightIprio_leftIprio_sel_1000
    & hsSortEn_1_4
    | ipriosTmp_result_rightIprio_leftIprio_sel_1002
    & hsSortEn_1_5
    | ipriosTmp_result_rightIprio_leftIprio_sel_1003
    & (ipriosTmp_result_rightIprio_leftIprio_sel_1004
       & hsSortEn_1_4
       | ipriosTmp_result_rightIprio_leftIprio_sel_1006
       & hsSortEn_1_4
       | ipriosTmp_result_rightIprio_leftIprio_sel_1010
       & hsSortEn_1_5
       | ipriosTmp_result_rightIprio_leftIprio_sel_1015
       & (ipriosTmp_result_rightIprio_leftIprio_sel_1023
            ? hsSortEn_1_4
            : hsSortEn_1_5));
  wire [5:0]  ipriosTmp_result_rightIprio_leftIprio_9_0_idx =
    (ipriosTmp_result_rightIprio_leftIprio_sel_1000 ? 6'hC : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1002 ? 6'hD : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1003
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_1004
            | ipriosTmp_result_rightIprio_leftIprio_sel_1006
              ? 6'hC
              : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1010 ? 6'hD : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1015
                ? {5'h6, ~ipriosTmp_result_rightIprio_leftIprio_sel_1023}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1000 =
    hsSortEn_1_6 & ~hsSortEn_1_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1002 =
    ~hsSortEn_1_6 & hsSortEn_1_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1003 =
    hsSortEn_1_6 & hsSortEn_1_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1004 =
    hsipriosSort_14_isZero & hsipriosSort_15_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1006 =
    hsipriosSort_14_isZero & ~hsipriosSort_15_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1010 =
    ~hsipriosSort_14_isZero & hsipriosSort_15_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1015 =
    ~hsipriosSort_14_isZero & ~hsipriosSort_15_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1023 =
    hsipriosSort_14_prioNum <= hsipriosSort_15_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_rightIprio_9_0_prioNum =
    (ipriosTmp_result_rightIprio_rightIprio_sel_1000
     & hsSortEn_1_6
       ? io_in_hsiprios[343:336]
       : 8'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1002
       & hsSortEn_1_7
         ? io_in_hsiprios[335:328]
         : 8'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1003
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_1004
            & hsSortEn_1_6
            | ipriosTmp_result_rightIprio_rightIprio_sel_1006
            & hsSortEn_1_6
              ? io_in_hsiprios[343:336]
              : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1010
              & hsSortEn_1_7
                ? io_in_hsiprios[335:328]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1015
                ? (ipriosTmp_result_rightIprio_rightIprio_sel_1023
                     ? hsipriosSort_14_prioNum
                     : hsipriosSort_15_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_9_0_isZero =
    ipriosTmp_result_rightIprio_rightIprio_sel_1000 & hsipriosSort_14_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1002 & hsipriosSort_15_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1003
    & (ipriosTmp_result_rightIprio_rightIprio_sel_1004 & hsipriosSort_14_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1006 & hsipriosSort_14_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1010 & hsipriosSort_15_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1015
       & (ipriosTmp_result_rightIprio_rightIprio_sel_1023
            ? hsipriosSort_14_isZero
            : hsipriosSort_15_isZero));
  wire        ipriosTmp_result_rightIprio_rightIprio_9_0_enable =
    ipriosTmp_result_rightIprio_rightIprio_sel_1000
    & hsSortEn_1_6
    | ipriosTmp_result_rightIprio_rightIprio_sel_1002
    & hsSortEn_1_7
    | ipriosTmp_result_rightIprio_rightIprio_sel_1003
    & (ipriosTmp_result_rightIprio_rightIprio_sel_1004
       & hsSortEn_1_6
       | ipriosTmp_result_rightIprio_rightIprio_sel_1006
       & hsSortEn_1_6
       | ipriosTmp_result_rightIprio_rightIprio_sel_1010
       & hsSortEn_1_7
       | ipriosTmp_result_rightIprio_rightIprio_sel_1015
       & (ipriosTmp_result_rightIprio_rightIprio_sel_1023
            ? hsSortEn_1_6
            : hsSortEn_1_7));
  wire [5:0]  ipriosTmp_result_rightIprio_rightIprio_9_0_idx =
    (ipriosTmp_result_rightIprio_rightIprio_sel_1000 ? 6'hE : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1002 ? 6'hF : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1003
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_1004
            | ipriosTmp_result_rightIprio_rightIprio_sel_1006
              ? 6'hE
              : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1010 ? 6'hF : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1015
                ? {5'h7, ~ipriosTmp_result_rightIprio_rightIprio_sel_1023}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_sel_1000 =
    ipriosTmp_result_rightIprio_leftIprio_9_0_enable
    & ~ipriosTmp_result_rightIprio_rightIprio_9_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1002 =
    ~ipriosTmp_result_rightIprio_leftIprio_9_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_9_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1003 =
    ipriosTmp_result_rightIprio_leftIprio_9_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_9_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1004 =
    ipriosTmp_result_rightIprio_leftIprio_9_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_9_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1006 =
    ipriosTmp_result_rightIprio_leftIprio_9_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_9_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1007 =
    ipriosTmp_result_rightIprio_leftIprio_9_0_idx < 6'h1C;
  wire        ipriosTmp_result_rightIprio_sel_1010 =
    ~ipriosTmp_result_rightIprio_leftIprio_9_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_9_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1011 =
    ipriosTmp_result_rightIprio_rightIprio_9_0_idx < 6'h1C;
  wire        ipriosTmp_result_rightIprio_sel_1015 =
    ~ipriosTmp_result_rightIprio_leftIprio_9_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_9_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1023 =
    ipriosTmp_result_rightIprio_leftIprio_9_0_prioNum <= ipriosTmp_result_rightIprio_rightIprio_9_0_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_9_0_prioNum =
    (ipriosTmp_result_rightIprio_sel_1000
       ? ipriosTmp_result_rightIprio_leftIprio_9_0_prioNum
       : 8'h0)
    | (ipriosTmp_result_rightIprio_sel_1002
         ? ipriosTmp_result_rightIprio_rightIprio_9_0_prioNum
         : 8'h0)
    | (ipriosTmp_result_rightIprio_sel_1003
         ? (ipriosTmp_result_rightIprio_sel_1004
              ? ipriosTmp_result_rightIprio_leftIprio_9_0_prioNum
              : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1006
                ? (ipriosTmp_result_rightIprio_sel_1007
                     ? ipriosTmp_result_rightIprio_leftIprio_9_0_prioNum
                     : ipriosTmp_result_rightIprio_rightIprio_9_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1010
                ? (ipriosTmp_result_rightIprio_sel_1011
                     ? ipriosTmp_result_rightIprio_rightIprio_9_0_prioNum
                     : ipriosTmp_result_rightIprio_leftIprio_9_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1015
                ? (ipriosTmp_result_rightIprio_sel_1023
                     ? ipriosTmp_result_rightIprio_leftIprio_9_0_prioNum
                     : ipriosTmp_result_rightIprio_rightIprio_9_0_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_9_0_isZero =
    ipriosTmp_result_rightIprio_sel_1000
    & ipriosTmp_result_rightIprio_leftIprio_9_0_isZero
    | ipriosTmp_result_rightIprio_sel_1002
    & ipriosTmp_result_rightIprio_rightIprio_9_0_isZero
    | ipriosTmp_result_rightIprio_sel_1003
    & (ipriosTmp_result_rightIprio_sel_1004
       & ipriosTmp_result_rightIprio_leftIprio_9_0_isZero
       | ipriosTmp_result_rightIprio_sel_1006
       & (ipriosTmp_result_rightIprio_sel_1007
            ? ipriosTmp_result_rightIprio_leftIprio_9_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_9_0_isZero)
       | ipriosTmp_result_rightIprio_sel_1010
       & (ipriosTmp_result_rightIprio_sel_1011
            ? ipriosTmp_result_rightIprio_rightIprio_9_0_isZero
            : ipriosTmp_result_rightIprio_leftIprio_9_0_isZero)
       | ipriosTmp_result_rightIprio_sel_1015
       & (ipriosTmp_result_rightIprio_sel_1023
            ? ipriosTmp_result_rightIprio_leftIprio_9_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_9_0_isZero));
  wire        ipriosTmp_result_rightIprio_9_0_enable =
    ipriosTmp_result_rightIprio_sel_1000
    & ipriosTmp_result_rightIprio_leftIprio_9_0_enable
    | ipriosTmp_result_rightIprio_sel_1002
    & ipriosTmp_result_rightIprio_rightIprio_9_0_enable
    | ipriosTmp_result_rightIprio_sel_1003
    & (ipriosTmp_result_rightIprio_sel_1004
       & ipriosTmp_result_rightIprio_leftIprio_9_0_enable
       | ipriosTmp_result_rightIprio_sel_1006
       & (ipriosTmp_result_rightIprio_sel_1007
            ? ipriosTmp_result_rightIprio_leftIprio_9_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_9_0_enable)
       | ipriosTmp_result_rightIprio_sel_1010
       & (ipriosTmp_result_rightIprio_sel_1011
            ? ipriosTmp_result_rightIprio_rightIprio_9_0_enable
            : ipriosTmp_result_rightIprio_leftIprio_9_0_enable)
       | ipriosTmp_result_rightIprio_sel_1015
       & (ipriosTmp_result_rightIprio_sel_1023
            ? ipriosTmp_result_rightIprio_leftIprio_9_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_9_0_enable));
  wire [5:0]  ipriosTmp_result_rightIprio_9_0_idx =
    (ipriosTmp_result_rightIprio_sel_1000
       ? ipriosTmp_result_rightIprio_leftIprio_9_0_idx
       : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_1002
         ? ipriosTmp_result_rightIprio_rightIprio_9_0_idx
         : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_1003
         ? (ipriosTmp_result_rightIprio_sel_1004
              ? ipriosTmp_result_rightIprio_leftIprio_9_0_idx
              : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1006
                ? (ipriosTmp_result_rightIprio_sel_1007
                     ? ipriosTmp_result_rightIprio_leftIprio_9_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_9_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1010
                ? (ipriosTmp_result_rightIprio_sel_1011
                     ? ipriosTmp_result_rightIprio_rightIprio_9_0_idx
                     : ipriosTmp_result_rightIprio_leftIprio_9_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1015
                ? (ipriosTmp_result_rightIprio_sel_1023
                     ? ipriosTmp_result_rightIprio_leftIprio_9_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_9_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_sel_1000 =
    ipriosTmp_result_leftIprio_9_0_enable & ~ipriosTmp_result_rightIprio_9_0_enable;
  wire        ipriosTmp_result_sel_1002 =
    ~ipriosTmp_result_leftIprio_9_0_enable & ipriosTmp_result_rightIprio_9_0_enable;
  wire        ipriosTmp_result_sel_1003 =
    ipriosTmp_result_leftIprio_9_0_enable & ipriosTmp_result_rightIprio_9_0_enable;
  wire        ipriosTmp_result_sel_1004 =
    ipriosTmp_result_leftIprio_9_0_isZero & ipriosTmp_result_rightIprio_9_0_isZero;
  wire        ipriosTmp_result_sel_1006 =
    ipriosTmp_result_leftIprio_9_0_isZero & ~ipriosTmp_result_rightIprio_9_0_isZero;
  wire        ipriosTmp_result_sel_1007 =
    ipriosTmp_result_leftIprio_9_0_idx < 6'h1C;
  wire        ipriosTmp_result_sel_1010 =
    ~ipriosTmp_result_leftIprio_9_0_isZero & ipriosTmp_result_rightIprio_9_0_isZero;
  wire        ipriosTmp_result_sel_1011 =
    ipriosTmp_result_rightIprio_9_0_idx < 6'h1C;
  wire        ipriosTmp_result_sel_1015 =
    ~ipriosTmp_result_leftIprio_9_0_isZero & ~ipriosTmp_result_rightIprio_9_0_isZero;
  wire        ipriosTmp_result_sel_1023 =
    ipriosTmp_result_leftIprio_9_0_prioNum <= ipriosTmp_result_rightIprio_9_0_prioNum;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1111 =
    hsSortEn_2_0 & ~hsSortEn_2_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1113 =
    ~hsSortEn_2_0 & hsSortEn_2_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1114 =
    hsSortEn_2_0 & hsSortEn_2_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1115 =
    hsipriosSort_16_isZero & hsipriosSort_17_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1117 =
    hsipriosSort_16_isZero & ~hsipriosSort_17_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1121 =
    ~hsipriosSort_16_isZero & hsipriosSort_17_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1126 =
    ~hsipriosSort_16_isZero & ~hsipriosSort_17_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1134 =
    hsipriosSort_16_prioNum <= hsipriosSort_17_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_leftIprio_10_0_prioNum =
    (ipriosTmp_result_leftIprio_leftIprio_sel_1111
     & hsSortEn_2_0
       ? io_in_hsiprios[167:160]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1113
       & hsSortEn_2_1
         ? io_in_hsiprios[327:320]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1114
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_1115
            & hsSortEn_2_0
            | ipriosTmp_result_leftIprio_leftIprio_sel_1117
            & hsSortEn_2_0
              ? io_in_hsiprios[167:160]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1121
              & hsSortEn_2_1
                ? io_in_hsiprios[327:320]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1126
                ? (ipriosTmp_result_leftIprio_leftIprio_sel_1134
                     ? hsipriosSort_16_prioNum
                     : hsipriosSort_17_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_leftIprio_10_0_isZero =
    ipriosTmp_result_leftIprio_leftIprio_sel_1111 & hsipriosSort_16_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1113 & hsipriosSort_17_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1114
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1115 & hsipriosSort_16_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1117 & hsipriosSort_16_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1121 & hsipriosSort_17_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1126
       & (ipriosTmp_result_leftIprio_leftIprio_sel_1134
            ? hsipriosSort_16_isZero
            : hsipriosSort_17_isZero));
  wire        ipriosTmp_result_leftIprio_leftIprio_10_0_enable =
    ipriosTmp_result_leftIprio_leftIprio_sel_1111
    & hsSortEn_2_0
    | ipriosTmp_result_leftIprio_leftIprio_sel_1113
    & hsSortEn_2_1
    | ipriosTmp_result_leftIprio_leftIprio_sel_1114
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1115
       & hsSortEn_2_0
       | ipriosTmp_result_leftIprio_leftIprio_sel_1117
       & hsSortEn_2_0
       | ipriosTmp_result_leftIprio_leftIprio_sel_1121
       & hsSortEn_2_1
       | ipriosTmp_result_leftIprio_leftIprio_sel_1126
       & (ipriosTmp_result_leftIprio_leftIprio_sel_1134
            ? hsSortEn_2_0
            : hsSortEn_2_1));
  wire [5:0]  ipriosTmp_result_leftIprio_leftIprio_10_0_idx =
    {1'h0, ipriosTmp_result_leftIprio_leftIprio_sel_1111, 4'h0}
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1113 ? 6'h11 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1114
         ? {1'h0,
            ipriosTmp_result_leftIprio_leftIprio_sel_1115
              | ipriosTmp_result_leftIprio_leftIprio_sel_1117,
            4'h0} | (ipriosTmp_result_leftIprio_leftIprio_sel_1121 ? 6'h11 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1126
                ? {5'h8, ~ipriosTmp_result_leftIprio_leftIprio_sel_1134}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1111 =
    hsSortEn_2_2 & ~hsSortEn_2_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1113 =
    ~hsSortEn_2_2 & hsSortEn_2_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1114 =
    hsSortEn_2_2 & hsSortEn_2_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1115 =
    hsipriosSort_18_isZero & hsipriosSort_19_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1117 =
    hsipriosSort_18_isZero & ~hsipriosSort_19_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1121 =
    ~hsipriosSort_18_isZero & hsipriosSort_19_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1126 =
    ~hsipriosSort_18_isZero & ~hsipriosSort_19_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1134 =
    hsipriosSort_18_prioNum <= hsipriosSort_19_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_rightIprio_10_0_prioNum =
    (ipriosTmp_result_leftIprio_rightIprio_sel_1111
     & hsSortEn_2_2
       ? io_in_hsiprios[479:472]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1113
       & hsSortEn_2_3
         ? io_in_hsiprios[239:232]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1114
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_1115
            & hsSortEn_2_2
            | ipriosTmp_result_leftIprio_rightIprio_sel_1117
            & hsSortEn_2_2
              ? io_in_hsiprios[479:472]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1121
              & hsSortEn_2_3
                ? io_in_hsiprios[239:232]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1126
                ? (ipriosTmp_result_leftIprio_rightIprio_sel_1134
                     ? hsipriosSort_18_prioNum
                     : hsipriosSort_19_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_10_0_isZero =
    ipriosTmp_result_leftIprio_rightIprio_sel_1111 & hsipriosSort_18_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1113 & hsipriosSort_19_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1114
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1115 & hsipriosSort_18_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1117 & hsipriosSort_18_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1121 & hsipriosSort_19_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1126
       & (ipriosTmp_result_leftIprio_rightIprio_sel_1134
            ? hsipriosSort_18_isZero
            : hsipriosSort_19_isZero));
  wire        ipriosTmp_result_leftIprio_rightIprio_10_0_enable =
    ipriosTmp_result_leftIprio_rightIprio_sel_1111
    & hsSortEn_2_2
    | ipriosTmp_result_leftIprio_rightIprio_sel_1113
    & hsSortEn_2_3
    | ipriosTmp_result_leftIprio_rightIprio_sel_1114
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1115
       & hsSortEn_2_2
       | ipriosTmp_result_leftIprio_rightIprio_sel_1117
       & hsSortEn_2_2
       | ipriosTmp_result_leftIprio_rightIprio_sel_1121
       & hsSortEn_2_3
       | ipriosTmp_result_leftIprio_rightIprio_sel_1126
       & (ipriosTmp_result_leftIprio_rightIprio_sel_1134
            ? hsSortEn_2_2
            : hsSortEn_2_3));
  wire [5:0]  ipriosTmp_result_leftIprio_rightIprio_10_0_idx =
    (ipriosTmp_result_leftIprio_rightIprio_sel_1111 ? 6'h12 : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1113 ? 6'h13 : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1114
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_1115
            | ipriosTmp_result_leftIprio_rightIprio_sel_1117
              ? 6'h12
              : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1121 ? 6'h13 : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1126
                ? {5'h9, ~ipriosTmp_result_leftIprio_rightIprio_sel_1134}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_sel_1111 =
    ipriosTmp_result_leftIprio_leftIprio_10_0_enable
    & ~ipriosTmp_result_leftIprio_rightIprio_10_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1113 =
    ~ipriosTmp_result_leftIprio_leftIprio_10_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_10_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1114 =
    ipriosTmp_result_leftIprio_leftIprio_10_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_10_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1115 =
    ipriosTmp_result_leftIprio_leftIprio_10_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_10_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1117 =
    ipriosTmp_result_leftIprio_leftIprio_10_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_10_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1118 =
    ipriosTmp_result_leftIprio_leftIprio_10_0_idx < 6'h1C;
  wire        ipriosTmp_result_leftIprio_sel_1121 =
    ~ipriosTmp_result_leftIprio_leftIprio_10_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_10_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1122 =
    ipriosTmp_result_leftIprio_rightIprio_10_0_idx < 6'h1C;
  wire        ipriosTmp_result_leftIprio_sel_1126 =
    ~ipriosTmp_result_leftIprio_leftIprio_10_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_10_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1134 =
    ipriosTmp_result_leftIprio_leftIprio_10_0_prioNum <= ipriosTmp_result_leftIprio_rightIprio_10_0_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_10_0_prioNum =
    (ipriosTmp_result_leftIprio_sel_1111
       ? ipriosTmp_result_leftIprio_leftIprio_10_0_prioNum
       : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_1113
         ? ipriosTmp_result_leftIprio_rightIprio_10_0_prioNum
         : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_1114
         ? (ipriosTmp_result_leftIprio_sel_1115
              ? ipriosTmp_result_leftIprio_leftIprio_10_0_prioNum
              : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1117
                ? (ipriosTmp_result_leftIprio_sel_1118
                     ? ipriosTmp_result_leftIprio_leftIprio_10_0_prioNum
                     : ipriosTmp_result_leftIprio_rightIprio_10_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1121
                ? (ipriosTmp_result_leftIprio_sel_1122
                     ? ipriosTmp_result_leftIprio_rightIprio_10_0_prioNum
                     : ipriosTmp_result_leftIprio_leftIprio_10_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1126
                ? (ipriosTmp_result_leftIprio_sel_1134
                     ? ipriosTmp_result_leftIprio_leftIprio_10_0_prioNum
                     : ipriosTmp_result_leftIprio_rightIprio_10_0_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_10_0_isZero =
    ipriosTmp_result_leftIprio_sel_1111
    & ipriosTmp_result_leftIprio_leftIprio_10_0_isZero
    | ipriosTmp_result_leftIprio_sel_1113
    & ipriosTmp_result_leftIprio_rightIprio_10_0_isZero
    | ipriosTmp_result_leftIprio_sel_1114
    & (ipriosTmp_result_leftIprio_sel_1115
       & ipriosTmp_result_leftIprio_leftIprio_10_0_isZero
       | ipriosTmp_result_leftIprio_sel_1117
       & (ipriosTmp_result_leftIprio_sel_1118
            ? ipriosTmp_result_leftIprio_leftIprio_10_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_10_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1121
       & (ipriosTmp_result_leftIprio_sel_1122
            ? ipriosTmp_result_leftIprio_rightIprio_10_0_isZero
            : ipriosTmp_result_leftIprio_leftIprio_10_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1126
       & (ipriosTmp_result_leftIprio_sel_1134
            ? ipriosTmp_result_leftIprio_leftIprio_10_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_10_0_isZero));
  wire        ipriosTmp_result_leftIprio_10_0_enable =
    ipriosTmp_result_leftIprio_sel_1111
    & ipriosTmp_result_leftIprio_leftIprio_10_0_enable
    | ipriosTmp_result_leftIprio_sel_1113
    & ipriosTmp_result_leftIprio_rightIprio_10_0_enable
    | ipriosTmp_result_leftIprio_sel_1114
    & (ipriosTmp_result_leftIprio_sel_1115
       & ipriosTmp_result_leftIprio_leftIprio_10_0_enable
       | ipriosTmp_result_leftIprio_sel_1117
       & (ipriosTmp_result_leftIprio_sel_1118
            ? ipriosTmp_result_leftIprio_leftIprio_10_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_10_0_enable)
       | ipriosTmp_result_leftIprio_sel_1121
       & (ipriosTmp_result_leftIprio_sel_1122
            ? ipriosTmp_result_leftIprio_rightIprio_10_0_enable
            : ipriosTmp_result_leftIprio_leftIprio_10_0_enable)
       | ipriosTmp_result_leftIprio_sel_1126
       & (ipriosTmp_result_leftIprio_sel_1134
            ? ipriosTmp_result_leftIprio_leftIprio_10_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_10_0_enable));
  wire [5:0]  ipriosTmp_result_leftIprio_10_0_idx =
    (ipriosTmp_result_leftIprio_sel_1111
       ? ipriosTmp_result_leftIprio_leftIprio_10_0_idx
       : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1113
         ? ipriosTmp_result_leftIprio_rightIprio_10_0_idx
         : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1114
         ? (ipriosTmp_result_leftIprio_sel_1115
              ? ipriosTmp_result_leftIprio_leftIprio_10_0_idx
              : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1117
                ? (ipriosTmp_result_leftIprio_sel_1118
                     ? ipriosTmp_result_leftIprio_leftIprio_10_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_10_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1121
                ? (ipriosTmp_result_leftIprio_sel_1122
                     ? ipriosTmp_result_leftIprio_rightIprio_10_0_idx
                     : ipriosTmp_result_leftIprio_leftIprio_10_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1126
                ? (ipriosTmp_result_leftIprio_sel_1134
                     ? ipriosTmp_result_leftIprio_leftIprio_10_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_10_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1111 =
    hsSortEn_2_4 & ~hsSortEn_2_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1113 =
    ~hsSortEn_2_4 & hsSortEn_2_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1114 =
    hsSortEn_2_4 & hsSortEn_2_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1115 =
    hsipriosSort_20_isZero & hsipriosSort_21_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1117 =
    hsipriosSort_20_isZero & ~hsipriosSort_21_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1121 =
    ~hsipriosSort_20_isZero & hsipriosSort_21_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1126 =
    ~hsipriosSort_20_isZero & ~hsipriosSort_21_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1134 =
    hsipriosSort_20_prioNum <= hsipriosSort_21_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_leftIprio_10_0_prioNum =
    (ipriosTmp_result_rightIprio_leftIprio_sel_1111
     & hsSortEn_2_4
       ? io_in_hsiprios[471:464]
       : 8'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1113
       & hsSortEn_2_5
         ? io_in_hsiprios[463:456]
         : 8'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1114
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_1115
            & hsSortEn_2_4
            | ipriosTmp_result_rightIprio_leftIprio_sel_1117
            & hsSortEn_2_4
              ? io_in_hsiprios[471:464]
              : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1121
              & hsSortEn_2_5
                ? io_in_hsiprios[463:456]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1126
                ? (ipriosTmp_result_rightIprio_leftIprio_sel_1134
                     ? hsipriosSort_20_prioNum
                     : hsipriosSort_21_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_10_0_isZero =
    ipriosTmp_result_rightIprio_leftIprio_sel_1111 & hsipriosSort_20_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1113 & hsipriosSort_21_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1114
    & (ipriosTmp_result_rightIprio_leftIprio_sel_1115 & hsipriosSort_20_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1117 & hsipriosSort_20_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1121 & hsipriosSort_21_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1126
       & (ipriosTmp_result_rightIprio_leftIprio_sel_1134
            ? hsipriosSort_20_isZero
            : hsipriosSort_21_isZero));
  wire        ipriosTmp_result_rightIprio_leftIprio_10_0_enable =
    ipriosTmp_result_rightIprio_leftIprio_sel_1111
    & hsSortEn_2_4
    | ipriosTmp_result_rightIprio_leftIprio_sel_1113
    & hsSortEn_2_5
    | ipriosTmp_result_rightIprio_leftIprio_sel_1114
    & (ipriosTmp_result_rightIprio_leftIprio_sel_1115
       & hsSortEn_2_4
       | ipriosTmp_result_rightIprio_leftIprio_sel_1117
       & hsSortEn_2_4
       | ipriosTmp_result_rightIprio_leftIprio_sel_1121
       & hsSortEn_2_5
       | ipriosTmp_result_rightIprio_leftIprio_sel_1126
       & (ipriosTmp_result_rightIprio_leftIprio_sel_1134
            ? hsSortEn_2_4
            : hsSortEn_2_5));
  wire [5:0]  ipriosTmp_result_rightIprio_leftIprio_10_0_idx =
    (ipriosTmp_result_rightIprio_leftIprio_sel_1111 ? 6'h14 : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1113 ? 6'h15 : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1114
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_1115
            | ipriosTmp_result_rightIprio_leftIprio_sel_1117
              ? 6'h14
              : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1121 ? 6'h15 : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1126
                ? {5'hA, ~ipriosTmp_result_rightIprio_leftIprio_sel_1134}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1111 =
    hsSortEn_2_6 & ~hsSortEn_2_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1113 =
    ~hsSortEn_2_6 & hsSortEn_2_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1114 =
    hsSortEn_2_6 & hsSortEn_2_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1115 =
    hsipriosSort_22_isZero & hsipriosSort_23_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1117 =
    hsipriosSort_22_isZero & ~hsipriosSort_23_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1121 =
    ~hsipriosSort_22_isZero & hsipriosSort_23_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1126 =
    ~hsipriosSort_22_isZero & ~hsipriosSort_23_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1134 =
    hsipriosSort_22_prioNum <= hsipriosSort_23_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_rightIprio_10_0_prioNum =
    (ipriosTmp_result_rightIprio_rightIprio_sel_1111
     & hsSortEn_2_6
       ? io_in_hsiprios[231:224]
       : 8'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1113
       & hsSortEn_2_7
         ? io_in_hsiprios[455:448]
         : 8'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1114
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_1115
            & hsSortEn_2_6
            | ipriosTmp_result_rightIprio_rightIprio_sel_1117
            & hsSortEn_2_6
              ? io_in_hsiprios[231:224]
              : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1121
              & hsSortEn_2_7
                ? io_in_hsiprios[455:448]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1126
                ? (ipriosTmp_result_rightIprio_rightIprio_sel_1134
                     ? hsipriosSort_22_prioNum
                     : hsipriosSort_23_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_10_0_isZero =
    ipriosTmp_result_rightIprio_rightIprio_sel_1111 & hsipriosSort_22_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1113 & hsipriosSort_23_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1114
    & (ipriosTmp_result_rightIprio_rightIprio_sel_1115 & hsipriosSort_22_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1117 & hsipriosSort_22_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1121 & hsipriosSort_23_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1126
       & (ipriosTmp_result_rightIprio_rightIprio_sel_1134
            ? hsipriosSort_22_isZero
            : hsipriosSort_23_isZero));
  wire        ipriosTmp_result_rightIprio_rightIprio_10_0_enable =
    ipriosTmp_result_rightIprio_rightIprio_sel_1111
    & hsSortEn_2_6
    | ipriosTmp_result_rightIprio_rightIprio_sel_1113
    & hsSortEn_2_7
    | ipriosTmp_result_rightIprio_rightIprio_sel_1114
    & (ipriosTmp_result_rightIprio_rightIprio_sel_1115
       & hsSortEn_2_6
       | ipriosTmp_result_rightIprio_rightIprio_sel_1117
       & hsSortEn_2_6
       | ipriosTmp_result_rightIprio_rightIprio_sel_1121
       & hsSortEn_2_7
       | ipriosTmp_result_rightIprio_rightIprio_sel_1126
       & (ipriosTmp_result_rightIprio_rightIprio_sel_1134
            ? hsSortEn_2_6
            : hsSortEn_2_7));
  wire [5:0]  ipriosTmp_result_rightIprio_rightIprio_10_0_idx =
    (ipriosTmp_result_rightIprio_rightIprio_sel_1111 ? 6'h16 : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1113 ? 6'h17 : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1114
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_1115
            | ipriosTmp_result_rightIprio_rightIprio_sel_1117
              ? 6'h16
              : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1121 ? 6'h17 : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1126
                ? {5'hB, ~ipriosTmp_result_rightIprio_rightIprio_sel_1134}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_sel_1111 =
    ipriosTmp_result_rightIprio_leftIprio_10_0_enable
    & ~ipriosTmp_result_rightIprio_rightIprio_10_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1113 =
    ~ipriosTmp_result_rightIprio_leftIprio_10_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_10_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1114 =
    ipriosTmp_result_rightIprio_leftIprio_10_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_10_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1115 =
    ipriosTmp_result_rightIprio_leftIprio_10_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_10_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1117 =
    ipriosTmp_result_rightIprio_leftIprio_10_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_10_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1118 =
    ipriosTmp_result_rightIprio_leftIprio_10_0_idx < 6'h1C;
  wire        ipriosTmp_result_rightIprio_sel_1121 =
    ~ipriosTmp_result_rightIprio_leftIprio_10_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_10_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1122 =
    ipriosTmp_result_rightIprio_rightIprio_10_0_idx < 6'h1C;
  wire        ipriosTmp_result_rightIprio_sel_1126 =
    ~ipriosTmp_result_rightIprio_leftIprio_10_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_10_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1134 =
    ipriosTmp_result_rightIprio_leftIprio_10_0_prioNum <= ipriosTmp_result_rightIprio_rightIprio_10_0_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_10_0_prioNum =
    (ipriosTmp_result_rightIprio_sel_1111
       ? ipriosTmp_result_rightIprio_leftIprio_10_0_prioNum
       : 8'h0)
    | (ipriosTmp_result_rightIprio_sel_1113
         ? ipriosTmp_result_rightIprio_rightIprio_10_0_prioNum
         : 8'h0)
    | (ipriosTmp_result_rightIprio_sel_1114
         ? (ipriosTmp_result_rightIprio_sel_1115
              ? ipriosTmp_result_rightIprio_leftIprio_10_0_prioNum
              : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1117
                ? (ipriosTmp_result_rightIprio_sel_1118
                     ? ipriosTmp_result_rightIprio_leftIprio_10_0_prioNum
                     : ipriosTmp_result_rightIprio_rightIprio_10_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1121
                ? (ipriosTmp_result_rightIprio_sel_1122
                     ? ipriosTmp_result_rightIprio_rightIprio_10_0_prioNum
                     : ipriosTmp_result_rightIprio_leftIprio_10_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1126
                ? (ipriosTmp_result_rightIprio_sel_1134
                     ? ipriosTmp_result_rightIprio_leftIprio_10_0_prioNum
                     : ipriosTmp_result_rightIprio_rightIprio_10_0_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_10_0_isZero =
    ipriosTmp_result_rightIprio_sel_1111
    & ipriosTmp_result_rightIprio_leftIprio_10_0_isZero
    | ipriosTmp_result_rightIprio_sel_1113
    & ipriosTmp_result_rightIprio_rightIprio_10_0_isZero
    | ipriosTmp_result_rightIprio_sel_1114
    & (ipriosTmp_result_rightIprio_sel_1115
       & ipriosTmp_result_rightIprio_leftIprio_10_0_isZero
       | ipriosTmp_result_rightIprio_sel_1117
       & (ipriosTmp_result_rightIprio_sel_1118
            ? ipriosTmp_result_rightIprio_leftIprio_10_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_10_0_isZero)
       | ipriosTmp_result_rightIprio_sel_1121
       & (ipriosTmp_result_rightIprio_sel_1122
            ? ipriosTmp_result_rightIprio_rightIprio_10_0_isZero
            : ipriosTmp_result_rightIprio_leftIprio_10_0_isZero)
       | ipriosTmp_result_rightIprio_sel_1126
       & (ipriosTmp_result_rightIprio_sel_1134
            ? ipriosTmp_result_rightIprio_leftIprio_10_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_10_0_isZero));
  wire        ipriosTmp_result_rightIprio_10_0_enable =
    ipriosTmp_result_rightIprio_sel_1111
    & ipriosTmp_result_rightIprio_leftIprio_10_0_enable
    | ipriosTmp_result_rightIprio_sel_1113
    & ipriosTmp_result_rightIprio_rightIprio_10_0_enable
    | ipriosTmp_result_rightIprio_sel_1114
    & (ipriosTmp_result_rightIprio_sel_1115
       & ipriosTmp_result_rightIprio_leftIprio_10_0_enable
       | ipriosTmp_result_rightIprio_sel_1117
       & (ipriosTmp_result_rightIprio_sel_1118
            ? ipriosTmp_result_rightIprio_leftIprio_10_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_10_0_enable)
       | ipriosTmp_result_rightIprio_sel_1121
       & (ipriosTmp_result_rightIprio_sel_1122
            ? ipriosTmp_result_rightIprio_rightIprio_10_0_enable
            : ipriosTmp_result_rightIprio_leftIprio_10_0_enable)
       | ipriosTmp_result_rightIprio_sel_1126
       & (ipriosTmp_result_rightIprio_sel_1134
            ? ipriosTmp_result_rightIprio_leftIprio_10_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_10_0_enable));
  wire [5:0]  ipriosTmp_result_rightIprio_10_0_idx =
    (ipriosTmp_result_rightIprio_sel_1111
       ? ipriosTmp_result_rightIprio_leftIprio_10_0_idx
       : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_1113
         ? ipriosTmp_result_rightIprio_rightIprio_10_0_idx
         : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_1114
         ? (ipriosTmp_result_rightIprio_sel_1115
              ? ipriosTmp_result_rightIprio_leftIprio_10_0_idx
              : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1117
                ? (ipriosTmp_result_rightIprio_sel_1118
                     ? ipriosTmp_result_rightIprio_leftIprio_10_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_10_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1121
                ? (ipriosTmp_result_rightIprio_sel_1122
                     ? ipriosTmp_result_rightIprio_rightIprio_10_0_idx
                     : ipriosTmp_result_rightIprio_leftIprio_10_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1126
                ? (ipriosTmp_result_rightIprio_sel_1134
                     ? ipriosTmp_result_rightIprio_leftIprio_10_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_10_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_sel_1111 =
    ipriosTmp_result_leftIprio_10_0_enable & ~ipriosTmp_result_rightIprio_10_0_enable;
  wire        ipriosTmp_result_sel_1113 =
    ~ipriosTmp_result_leftIprio_10_0_enable & ipriosTmp_result_rightIprio_10_0_enable;
  wire        ipriosTmp_result_sel_1114 =
    ipriosTmp_result_leftIprio_10_0_enable & ipriosTmp_result_rightIprio_10_0_enable;
  wire        ipriosTmp_result_sel_1115 =
    ipriosTmp_result_leftIprio_10_0_isZero & ipriosTmp_result_rightIprio_10_0_isZero;
  wire        ipriosTmp_result_sel_1117 =
    ipriosTmp_result_leftIprio_10_0_isZero & ~ipriosTmp_result_rightIprio_10_0_isZero;
  wire        ipriosTmp_result_sel_1118 =
    ipriosTmp_result_leftIprio_10_0_idx < 6'h1C;
  wire        ipriosTmp_result_sel_1121 =
    ~ipriosTmp_result_leftIprio_10_0_isZero & ipriosTmp_result_rightIprio_10_0_isZero;
  wire        ipriosTmp_result_sel_1122 =
    ipriosTmp_result_rightIprio_10_0_idx < 6'h1C;
  wire        ipriosTmp_result_sel_1126 =
    ~ipriosTmp_result_leftIprio_10_0_isZero & ~ipriosTmp_result_rightIprio_10_0_isZero;
  wire        ipriosTmp_result_sel_1134 =
    ipriosTmp_result_leftIprio_10_0_prioNum <= ipriosTmp_result_rightIprio_10_0_prioNum;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1222 =
    hsipriosSort_24_enable & ~hsipriosSort_25_enable;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1224 =
    ~hsipriosSort_24_enable & hsipriosSort_25_enable;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1225 =
    hsipriosSort_24_enable & hsipriosSort_25_enable;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1226 =
    hsipriosSort_24_isZero & hsipriosSort_25_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1228 =
    hsipriosSort_24_isZero & ~hsipriosSort_25_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1232 =
    ~hsipriosSort_24_isZero & hsipriosSort_25_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1237 =
    ~hsipriosSort_24_isZero & ~hsipriosSort_25_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1245 =
    hsipriosSort_24_prioNum <= hsipriosSort_25_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_leftIprio_11_0_prioNum =
    (ipriosTmp_result_leftIprio_leftIprio_sel_1222 & hsipriosSort_24_enable
       ? io_in_hsiprios[95:88]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1224 & hsipriosSort_25_enable
         ? io_in_hsiprios[31:24]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1225
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_1226 & hsipriosSort_24_enable
            | ipriosTmp_result_leftIprio_leftIprio_sel_1228
            & hsipriosSort_24_enable
              ? io_in_hsiprios[95:88]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1232
              & hsipriosSort_25_enable
                ? io_in_hsiprios[31:24]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1237
                ? (ipriosTmp_result_leftIprio_leftIprio_sel_1245
                     ? hsipriosSort_24_prioNum
                     : hsipriosSort_25_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_leftIprio_11_0_isZero =
    ipriosTmp_result_leftIprio_leftIprio_sel_1222 & hsipriosSort_24_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1224 & hsipriosSort_25_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1225
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1226 & hsipriosSort_24_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1228 & hsipriosSort_24_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1232 & hsipriosSort_25_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1237
       & (ipriosTmp_result_leftIprio_leftIprio_sel_1245
            ? hsipriosSort_24_isZero
            : hsipriosSort_25_isZero));
  wire        ipriosTmp_result_leftIprio_leftIprio_11_0_enable =
    ipriosTmp_result_leftIprio_leftIprio_sel_1222 & hsipriosSort_24_enable
    | ipriosTmp_result_leftIprio_leftIprio_sel_1224 & hsipriosSort_25_enable
    | ipriosTmp_result_leftIprio_leftIprio_sel_1225
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1226 & hsipriosSort_24_enable
       | ipriosTmp_result_leftIprio_leftIprio_sel_1228 & hsipriosSort_24_enable
       | ipriosTmp_result_leftIprio_leftIprio_sel_1232 & hsipriosSort_25_enable
       | ipriosTmp_result_leftIprio_leftIprio_sel_1237
       & (ipriosTmp_result_leftIprio_leftIprio_sel_1245
            ? hsipriosSort_24_enable
            : hsipriosSort_25_enable));
  wire [5:0]  ipriosTmp_result_leftIprio_leftIprio_11_0_idx =
    (ipriosTmp_result_leftIprio_leftIprio_sel_1222 ? 6'h18 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1224 ? 6'h19 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1225
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_1226
            | ipriosTmp_result_leftIprio_leftIprio_sel_1228
              ? 6'h18
              : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1232 ? 6'h19 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1237
                ? {5'hC, ~ipriosTmp_result_leftIprio_leftIprio_sel_1245}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1222 =
    hsipriosSort_26_enable & ~hsipriosSort_27_enable;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1224 =
    ~hsipriosSort_26_enable & hsipriosSort_27_enable;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1225 =
    hsipriosSort_26_enable & hsipriosSort_27_enable;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1226 =
    hsipriosSort_26_isZero & hsipriosSort_27_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1228 =
    hsipriosSort_26_isZero & ~hsipriosSort_27_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1232 =
    ~hsipriosSort_26_isZero & hsipriosSort_27_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1237 =
    ~hsipriosSort_26_isZero & ~hsipriosSort_27_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1245 =
    hsipriosSort_26_prioNum <= hsipriosSort_27_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_rightIprio_11_0_prioNum =
    (ipriosTmp_result_leftIprio_rightIprio_sel_1222 & hsipriosSort_26_enable
       ? io_in_hsiprios[63:56]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1224 & hsipriosSort_27_enable
         ? io_in_stopei_IPRIO[7:0]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1225
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_1226
            & hsipriosSort_26_enable
            | ipriosTmp_result_leftIprio_rightIprio_sel_1228
            & hsipriosSort_26_enable
              ? io_in_hsiprios[63:56]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1232
              & hsipriosSort_27_enable
                ? io_in_stopei_IPRIO[7:0]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1237
                ? (hsipriosSort_27_greaterThan255 & hsipriosSort_26_enable
                     ? io_in_hsiprios[63:56]
                     : 8'h0)
                  | (hsipriosSort_27_greaterThan255
                       ? 8'h0
                       : ipriosTmp_result_leftIprio_rightIprio_sel_1245
                           ? hsipriosSort_26_prioNum
                           : hsipriosSort_27_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_11_0_greaterThan255 =
    ipriosTmp_result_leftIprio_rightIprio_sel_1224
    & hsipriosSort_27_greaterThan255
    | ipriosTmp_result_leftIprio_rightIprio_sel_1225
    & ipriosTmp_result_leftIprio_rightIprio_sel_1232
    & hsipriosSort_27_greaterThan255;
  wire        ipriosTmp_result_leftIprio_rightIprio_11_0_isZero =
    ipriosTmp_result_leftIprio_rightIprio_sel_1222 & hsipriosSort_26_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1224 & hsipriosSort_27_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1225
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1226 & hsipriosSort_26_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1228 & hsipriosSort_26_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1232 & hsipriosSort_27_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1237
       & (hsipriosSort_27_greaterThan255 & hsipriosSort_26_isZero
          | ~hsipriosSort_27_greaterThan255
          & (ipriosTmp_result_leftIprio_rightIprio_sel_1245
               ? hsipriosSort_26_isZero
               : hsipriosSort_27_isZero)));
  wire        ipriosTmp_result_leftIprio_rightIprio_11_0_enable =
    ipriosTmp_result_leftIprio_rightIprio_sel_1222 & hsipriosSort_26_enable
    | ipriosTmp_result_leftIprio_rightIprio_sel_1224 & hsipriosSort_27_enable
    | ipriosTmp_result_leftIprio_rightIprio_sel_1225
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1226 & hsipriosSort_26_enable
       | ipriosTmp_result_leftIprio_rightIprio_sel_1228 & hsipriosSort_26_enable
       | ipriosTmp_result_leftIprio_rightIprio_sel_1232 & hsipriosSort_27_enable
       | ipriosTmp_result_leftIprio_rightIprio_sel_1237
       & (hsipriosSort_27_greaterThan255 & hsipriosSort_26_enable
          | ~hsipriosSort_27_greaterThan255
          & (ipriosTmp_result_leftIprio_rightIprio_sel_1245
               ? hsipriosSort_26_enable
               : hsipriosSort_27_enable)));
  wire [5:0]  ipriosTmp_result_leftIprio_rightIprio_11_0_idx =
    (ipriosTmp_result_leftIprio_rightIprio_sel_1222 ? 6'h1A : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1224 ? 6'h1B : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1225
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_1226
            | ipriosTmp_result_leftIprio_rightIprio_sel_1228
              ? 6'h1A
              : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1232 ? 6'h1B : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1237
                ? (hsipriosSort_27_greaterThan255 ? 6'h1A : 6'h0)
                  | (hsipriosSort_27_greaterThan255
                       ? 6'h0
                       : {5'hD, ~ipriosTmp_result_leftIprio_rightIprio_sel_1245})
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_sel_1222 =
    ipriosTmp_result_leftIprio_leftIprio_11_0_enable
    & ~ipriosTmp_result_leftIprio_rightIprio_11_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1224 =
    ~ipriosTmp_result_leftIprio_leftIprio_11_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_11_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1225 =
    ipriosTmp_result_leftIprio_leftIprio_11_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_11_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1226 =
    ipriosTmp_result_leftIprio_leftIprio_11_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_11_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1228 =
    ipriosTmp_result_leftIprio_leftIprio_11_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_11_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1229 =
    ipriosTmp_result_leftIprio_leftIprio_11_0_idx < 6'h1C;
  wire        ipriosTmp_result_leftIprio_sel_1232 =
    ~ipriosTmp_result_leftIprio_leftIprio_11_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_11_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1233 =
    ipriosTmp_result_leftIprio_rightIprio_11_0_idx < 6'h1C;
  wire        ipriosTmp_result_leftIprio_sel_1237 =
    ~ipriosTmp_result_leftIprio_leftIprio_11_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_11_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1245 =
    ipriosTmp_result_leftIprio_leftIprio_11_0_prioNum <= ipriosTmp_result_leftIprio_rightIprio_11_0_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_11_0_prioNum =
    (ipriosTmp_result_leftIprio_sel_1222
       ? ipriosTmp_result_leftIprio_leftIprio_11_0_prioNum
       : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_1224
         ? ipriosTmp_result_leftIprio_rightIprio_11_0_prioNum
         : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_1225
         ? (ipriosTmp_result_leftIprio_sel_1226
              ? ipriosTmp_result_leftIprio_leftIprio_11_0_prioNum
              : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1228
                ? (ipriosTmp_result_leftIprio_sel_1229
                     ? ipriosTmp_result_leftIprio_leftIprio_11_0_prioNum
                     : ipriosTmp_result_leftIprio_rightIprio_11_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1232
                ? (ipriosTmp_result_leftIprio_sel_1233
                     ? ipriosTmp_result_leftIprio_rightIprio_11_0_prioNum
                     : ipriosTmp_result_leftIprio_leftIprio_11_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1237
                ? (ipriosTmp_result_leftIprio_rightIprio_11_0_greaterThan255
                     ? ipriosTmp_result_leftIprio_leftIprio_11_0_prioNum
                     : 8'h0)
                  | (ipriosTmp_result_leftIprio_rightIprio_11_0_greaterThan255
                       ? 8'h0
                       : ipriosTmp_result_leftIprio_sel_1245
                           ? ipriosTmp_result_leftIprio_leftIprio_11_0_prioNum
                           : ipriosTmp_result_leftIprio_rightIprio_11_0_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_11_0_greaterThan255 =
    ipriosTmp_result_leftIprio_sel_1224
    & ipriosTmp_result_leftIprio_rightIprio_11_0_greaterThan255
    | ipriosTmp_result_leftIprio_sel_1225
    & (ipriosTmp_result_leftIprio_sel_1228
       & ~ipriosTmp_result_leftIprio_sel_1229
       & ipriosTmp_result_leftIprio_rightIprio_11_0_greaterThan255
       | ipriosTmp_result_leftIprio_sel_1232
       & ipriosTmp_result_leftIprio_sel_1233
       & ipriosTmp_result_leftIprio_rightIprio_11_0_greaterThan255);
  wire        ipriosTmp_result_leftIprio_11_0_isZero =
    ipriosTmp_result_leftIprio_sel_1222
    & ipriosTmp_result_leftIprio_leftIprio_11_0_isZero
    | ipriosTmp_result_leftIprio_sel_1224
    & ipriosTmp_result_leftIprio_rightIprio_11_0_isZero
    | ipriosTmp_result_leftIprio_sel_1225
    & (ipriosTmp_result_leftIprio_sel_1226
       & ipriosTmp_result_leftIprio_leftIprio_11_0_isZero
       | ipriosTmp_result_leftIprio_sel_1228
       & (ipriosTmp_result_leftIprio_sel_1229
            ? ipriosTmp_result_leftIprio_leftIprio_11_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_11_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1232
       & (ipriosTmp_result_leftIprio_sel_1233
            ? ipriosTmp_result_leftIprio_rightIprio_11_0_isZero
            : ipriosTmp_result_leftIprio_leftIprio_11_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1237
       & (ipriosTmp_result_leftIprio_rightIprio_11_0_greaterThan255
          & ipriosTmp_result_leftIprio_leftIprio_11_0_isZero
          | ~ipriosTmp_result_leftIprio_rightIprio_11_0_greaterThan255
          & (ipriosTmp_result_leftIprio_sel_1245
               ? ipriosTmp_result_leftIprio_leftIprio_11_0_isZero
               : ipriosTmp_result_leftIprio_rightIprio_11_0_isZero)));
  wire        ipriosTmp_result_leftIprio_11_0_enable =
    ipriosTmp_result_leftIprio_sel_1222
    & ipriosTmp_result_leftIprio_leftIprio_11_0_enable
    | ipriosTmp_result_leftIprio_sel_1224
    & ipriosTmp_result_leftIprio_rightIprio_11_0_enable
    | ipriosTmp_result_leftIprio_sel_1225
    & (ipriosTmp_result_leftIprio_sel_1226
       & ipriosTmp_result_leftIprio_leftIprio_11_0_enable
       | ipriosTmp_result_leftIprio_sel_1228
       & (ipriosTmp_result_leftIprio_sel_1229
            ? ipriosTmp_result_leftIprio_leftIprio_11_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_11_0_enable)
       | ipriosTmp_result_leftIprio_sel_1232
       & (ipriosTmp_result_leftIprio_sel_1233
            ? ipriosTmp_result_leftIprio_rightIprio_11_0_enable
            : ipriosTmp_result_leftIprio_leftIprio_11_0_enable)
       | ipriosTmp_result_leftIprio_sel_1237
       & (ipriosTmp_result_leftIprio_rightIprio_11_0_greaterThan255
          & ipriosTmp_result_leftIprio_leftIprio_11_0_enable
          | ~ipriosTmp_result_leftIprio_rightIprio_11_0_greaterThan255
          & (ipriosTmp_result_leftIprio_sel_1245
               ? ipriosTmp_result_leftIprio_leftIprio_11_0_enable
               : ipriosTmp_result_leftIprio_rightIprio_11_0_enable)));
  wire [5:0]  ipriosTmp_result_leftIprio_11_0_idx =
    (ipriosTmp_result_leftIprio_sel_1222
       ? ipriosTmp_result_leftIprio_leftIprio_11_0_idx
       : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1224
         ? ipriosTmp_result_leftIprio_rightIprio_11_0_idx
         : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1225
         ? (ipriosTmp_result_leftIprio_sel_1226
              ? ipriosTmp_result_leftIprio_leftIprio_11_0_idx
              : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1228
                ? (ipriosTmp_result_leftIprio_sel_1229
                     ? ipriosTmp_result_leftIprio_leftIprio_11_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_11_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1232
                ? (ipriosTmp_result_leftIprio_sel_1233
                     ? ipriosTmp_result_leftIprio_rightIprio_11_0_idx
                     : ipriosTmp_result_leftIprio_leftIprio_11_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1237
                ? (ipriosTmp_result_leftIprio_rightIprio_11_0_greaterThan255
                     ? ipriosTmp_result_leftIprio_leftIprio_11_0_idx
                     : 6'h0)
                  | (ipriosTmp_result_leftIprio_rightIprio_11_0_greaterThan255
                       ? 6'h0
                       : ipriosTmp_result_leftIprio_sel_1245
                           ? ipriosTmp_result_leftIprio_leftIprio_11_0_idx
                           : ipriosTmp_result_leftIprio_rightIprio_11_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1222 =
    hsipriosSort_28_enable & ~hsipriosSort_29_enable;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1224 =
    ~hsipriosSort_28_enable & hsipriosSort_29_enable;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1225 =
    hsipriosSort_28_enable & hsipriosSort_29_enable;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1226 =
    hsipriosSort_28_isZero & hsipriosSort_29_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1228 =
    hsipriosSort_28_isZero & ~hsipriosSort_29_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1232 =
    ~hsipriosSort_28_isZero & hsipriosSort_29_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1237 =
    ~hsipriosSort_28_isZero & ~hsipriosSort_29_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1245 =
    hsipriosSort_28_prioNum <= hsipriosSort_29_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_leftIprio_11_0_prioNum =
    (ipriosTmp_result_rightIprio_leftIprio_sel_1222 & hsipriosSort_28_enable
       ? io_in_hsiprios[15:8]
       : 8'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1224 & hsipriosSort_29_enable
         ? io_in_hsiprios[47:40]
         : 8'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1225
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_1226
            & hsipriosSort_28_enable
              ? io_in_hsiprios[15:8]
              : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1228
              & hsipriosSort_29_enable
                ? io_in_hsiprios[47:40]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1232
              & hsipriosSort_28_enable
                ? io_in_hsiprios[15:8]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1237
                ? (ipriosTmp_result_rightIprio_leftIprio_sel_1245
                     ? hsipriosSort_28_prioNum
                     : hsipriosSort_29_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_11_0_isZero =
    ipriosTmp_result_rightIprio_leftIprio_sel_1222 & hsipriosSort_28_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1224 & hsipriosSort_29_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1225
    & (ipriosTmp_result_rightIprio_leftIprio_sel_1226 & hsipriosSort_28_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1228 & hsipriosSort_29_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1232 & hsipriosSort_28_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1237
       & (ipriosTmp_result_rightIprio_leftIprio_sel_1245
            ? hsipriosSort_28_isZero
            : hsipriosSort_29_isZero));
  wire        ipriosTmp_result_rightIprio_leftIprio_11_0_enable =
    ipriosTmp_result_rightIprio_leftIprio_sel_1222 & hsipriosSort_28_enable
    | ipriosTmp_result_rightIprio_leftIprio_sel_1224 & hsipriosSort_29_enable
    | ipriosTmp_result_rightIprio_leftIprio_sel_1225
    & (ipriosTmp_result_rightIprio_leftIprio_sel_1226 & hsipriosSort_28_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_1228 & hsipriosSort_29_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_1232 & hsipriosSort_28_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_1237
       & (ipriosTmp_result_rightIprio_leftIprio_sel_1245
            ? hsipriosSort_28_enable
            : hsipriosSort_29_enable));
  wire [5:0]  ipriosTmp_result_rightIprio_leftIprio_11_0_idx =
    (ipriosTmp_result_rightIprio_leftIprio_sel_1222 ? 6'h1C : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1224 ? 6'h1D : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1225
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_1226 ? 6'h1C : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1228 ? 6'h1D : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1232 ? 6'h1C : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1237
                ? {5'hE, ~ipriosTmp_result_rightIprio_leftIprio_sel_1245}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1222 =
    hsipriosSort_30_enable & ~hsipriosSort_31_enable;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1224 =
    ~hsipriosSort_30_enable & hsipriosSort_31_enable;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1225 =
    hsipriosSort_30_enable & hsipriosSort_31_enable;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1226 =
    hsipriosSort_30_isZero & hsipriosSort_31_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1228 =
    hsipriosSort_30_isZero & ~hsipriosSort_31_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1232 =
    ~hsipriosSort_30_isZero & hsipriosSort_31_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1237 =
    ~hsipriosSort_30_isZero & ~hsipriosSort_31_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1245 =
    hsipriosSort_30_prioNum <= hsipriosSort_31_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_rightIprio_11_0_prioNum =
    (ipriosTmp_result_rightIprio_rightIprio_sel_1222 & hsipriosSort_30_enable
       ? io_in_hsiprios[103:96]
       : 8'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1224 & hsipriosSort_31_enable
         ? io_in_hsiprios[87:80]
         : 8'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1225
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_1226
            & hsipriosSort_30_enable
              ? io_in_hsiprios[103:96]
              : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1228
              & hsipriosSort_31_enable
                ? io_in_hsiprios[87:80]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1232
              & hsipriosSort_30_enable
                ? io_in_hsiprios[103:96]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1237
                ? (ipriosTmp_result_rightIprio_rightIprio_sel_1245
                     ? hsipriosSort_30_prioNum
                     : hsipriosSort_31_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_11_0_isZero =
    ipriosTmp_result_rightIprio_rightIprio_sel_1222 & hsipriosSort_30_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1224 & hsipriosSort_31_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1225
    & (ipriosTmp_result_rightIprio_rightIprio_sel_1226 & hsipriosSort_30_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1228 & hsipriosSort_31_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1232 & hsipriosSort_30_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1237
       & (ipriosTmp_result_rightIprio_rightIprio_sel_1245
            ? hsipriosSort_30_isZero
            : hsipriosSort_31_isZero));
  wire        ipriosTmp_result_rightIprio_rightIprio_11_0_enable =
    ipriosTmp_result_rightIprio_rightIprio_sel_1222 & hsipriosSort_30_enable
    | ipriosTmp_result_rightIprio_rightIprio_sel_1224 & hsipriosSort_31_enable
    | ipriosTmp_result_rightIprio_rightIprio_sel_1225
    & (ipriosTmp_result_rightIprio_rightIprio_sel_1226 & hsipriosSort_30_enable
       | ipriosTmp_result_rightIprio_rightIprio_sel_1228 & hsipriosSort_31_enable
       | ipriosTmp_result_rightIprio_rightIprio_sel_1232 & hsipriosSort_30_enable
       | ipriosTmp_result_rightIprio_rightIprio_sel_1237
       & (ipriosTmp_result_rightIprio_rightIprio_sel_1245
            ? hsipriosSort_30_enable
            : hsipriosSort_31_enable));
  wire [5:0]  ipriosTmp_result_rightIprio_rightIprio_11_0_idx =
    (ipriosTmp_result_rightIprio_rightIprio_sel_1222 ? 6'h1E : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1224 ? 6'h1F : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1225
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_1226 ? 6'h1E : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1228 ? 6'h1F : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1232 ? 6'h1E : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1237
                ? {5'hF, ~ipriosTmp_result_rightIprio_rightIprio_sel_1245}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_sel_1222 =
    ipriosTmp_result_rightIprio_leftIprio_11_0_enable
    & ~ipriosTmp_result_rightIprio_rightIprio_11_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1224 =
    ~ipriosTmp_result_rightIprio_leftIprio_11_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_11_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1225 =
    ipriosTmp_result_rightIprio_leftIprio_11_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_11_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1226 =
    ipriosTmp_result_rightIprio_leftIprio_11_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_11_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1228 =
    ipriosTmp_result_rightIprio_leftIprio_11_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_11_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1229 =
    ipriosTmp_result_rightIprio_leftIprio_11_0_idx < 6'h1C;
  wire        ipriosTmp_result_rightIprio_sel_1232 =
    ~ipriosTmp_result_rightIprio_leftIprio_11_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_11_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1233 =
    ipriosTmp_result_rightIprio_rightIprio_11_0_idx < 6'h1C;
  wire        ipriosTmp_result_rightIprio_sel_1237 =
    ~ipriosTmp_result_rightIprio_leftIprio_11_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_11_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1245 =
    ipriosTmp_result_rightIprio_leftIprio_11_0_prioNum <= ipriosTmp_result_rightIprio_rightIprio_11_0_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_11_0_prioNum =
    (ipriosTmp_result_rightIprio_sel_1222
       ? ipriosTmp_result_rightIprio_leftIprio_11_0_prioNum
       : 8'h0)
    | (ipriosTmp_result_rightIprio_sel_1224
         ? ipriosTmp_result_rightIprio_rightIprio_11_0_prioNum
         : 8'h0)
    | (ipriosTmp_result_rightIprio_sel_1225
         ? (ipriosTmp_result_rightIprio_sel_1226
              ? ipriosTmp_result_rightIprio_leftIprio_11_0_prioNum
              : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1228
                ? (ipriosTmp_result_rightIprio_sel_1229
                     ? ipriosTmp_result_rightIprio_leftIprio_11_0_prioNum
                     : ipriosTmp_result_rightIprio_rightIprio_11_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1232
                ? (ipriosTmp_result_rightIprio_sel_1233
                     ? ipriosTmp_result_rightIprio_rightIprio_11_0_prioNum
                     : ipriosTmp_result_rightIprio_leftIprio_11_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1237
                ? (ipriosTmp_result_rightIprio_sel_1245
                     ? ipriosTmp_result_rightIprio_leftIprio_11_0_prioNum
                     : ipriosTmp_result_rightIprio_rightIprio_11_0_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_11_0_isZero =
    ipriosTmp_result_rightIprio_sel_1222
    & ipriosTmp_result_rightIprio_leftIprio_11_0_isZero
    | ipriosTmp_result_rightIprio_sel_1224
    & ipriosTmp_result_rightIprio_rightIprio_11_0_isZero
    | ipriosTmp_result_rightIprio_sel_1225
    & (ipriosTmp_result_rightIprio_sel_1226
       & ipriosTmp_result_rightIprio_leftIprio_11_0_isZero
       | ipriosTmp_result_rightIprio_sel_1228
       & (ipriosTmp_result_rightIprio_sel_1229
            ? ipriosTmp_result_rightIprio_leftIprio_11_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_11_0_isZero)
       | ipriosTmp_result_rightIprio_sel_1232
       & (ipriosTmp_result_rightIprio_sel_1233
            ? ipriosTmp_result_rightIprio_rightIprio_11_0_isZero
            : ipriosTmp_result_rightIprio_leftIprio_11_0_isZero)
       | ipriosTmp_result_rightIprio_sel_1237
       & (ipriosTmp_result_rightIprio_sel_1245
            ? ipriosTmp_result_rightIprio_leftIprio_11_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_11_0_isZero));
  wire        ipriosTmp_result_rightIprio_11_0_enable =
    ipriosTmp_result_rightIprio_sel_1222
    & ipriosTmp_result_rightIprio_leftIprio_11_0_enable
    | ipriosTmp_result_rightIprio_sel_1224
    & ipriosTmp_result_rightIprio_rightIprio_11_0_enable
    | ipriosTmp_result_rightIprio_sel_1225
    & (ipriosTmp_result_rightIprio_sel_1226
       & ipriosTmp_result_rightIprio_leftIprio_11_0_enable
       | ipriosTmp_result_rightIprio_sel_1228
       & (ipriosTmp_result_rightIprio_sel_1229
            ? ipriosTmp_result_rightIprio_leftIprio_11_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_11_0_enable)
       | ipriosTmp_result_rightIprio_sel_1232
       & (ipriosTmp_result_rightIprio_sel_1233
            ? ipriosTmp_result_rightIprio_rightIprio_11_0_enable
            : ipriosTmp_result_rightIprio_leftIprio_11_0_enable)
       | ipriosTmp_result_rightIprio_sel_1237
       & (ipriosTmp_result_rightIprio_sel_1245
            ? ipriosTmp_result_rightIprio_leftIprio_11_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_11_0_enable));
  wire [5:0]  ipriosTmp_result_rightIprio_11_0_idx =
    (ipriosTmp_result_rightIprio_sel_1222
       ? ipriosTmp_result_rightIprio_leftIprio_11_0_idx
       : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_1224
         ? ipriosTmp_result_rightIprio_rightIprio_11_0_idx
         : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_1225
         ? (ipriosTmp_result_rightIprio_sel_1226
              ? ipriosTmp_result_rightIprio_leftIprio_11_0_idx
              : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1228
                ? (ipriosTmp_result_rightIprio_sel_1229
                     ? ipriosTmp_result_rightIprio_leftIprio_11_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_11_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1232
                ? (ipriosTmp_result_rightIprio_sel_1233
                     ? ipriosTmp_result_rightIprio_rightIprio_11_0_idx
                     : ipriosTmp_result_rightIprio_leftIprio_11_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1237
                ? (ipriosTmp_result_rightIprio_sel_1245
                     ? ipriosTmp_result_rightIprio_leftIprio_11_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_11_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_sel_1222 =
    ipriosTmp_result_leftIprio_11_0_enable & ~ipriosTmp_result_rightIprio_11_0_enable;
  wire        ipriosTmp_result_sel_1224 =
    ~ipriosTmp_result_leftIprio_11_0_enable & ipriosTmp_result_rightIprio_11_0_enable;
  wire        ipriosTmp_result_sel_1225 =
    ipriosTmp_result_leftIprio_11_0_enable & ipriosTmp_result_rightIprio_11_0_enable;
  wire        ipriosTmp_result_sel_1226 =
    ipriosTmp_result_leftIprio_11_0_isZero & ipriosTmp_result_rightIprio_11_0_isZero;
  wire        ipriosTmp_result_sel_1228 =
    ipriosTmp_result_leftIprio_11_0_isZero & ~ipriosTmp_result_rightIprio_11_0_isZero;
  wire        ipriosTmp_result_sel_1229 =
    ipriosTmp_result_leftIprio_11_0_idx < 6'h1C;
  wire        ipriosTmp_result_sel_1232 =
    ~ipriosTmp_result_leftIprio_11_0_isZero & ipriosTmp_result_rightIprio_11_0_isZero;
  wire        ipriosTmp_result_sel_1233 =
    ipriosTmp_result_rightIprio_11_0_idx < 6'h1C;
  wire        ipriosTmp_result_sel_1237 =
    ~ipriosTmp_result_leftIprio_11_0_isZero & ~ipriosTmp_result_rightIprio_11_0_isZero;
  wire        ipriosTmp_result_sel_1245 =
    ipriosTmp_result_leftIprio_11_0_prioNum <= ipriosTmp_result_rightIprio_11_0_prioNum;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1333 =
    hsipriosSort_32_enable & ~hsipriosSort_33_enable;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1335 =
    ~hsipriosSort_32_enable & hsipriosSort_33_enable;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1336 =
    hsipriosSort_32_enable & hsipriosSort_33_enable;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1337 =
    hsipriosSort_32_isZero & hsipriosSort_33_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1339 =
    hsipriosSort_32_isZero & ~hsipriosSort_33_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1343 =
    ~hsipriosSort_32_isZero & hsipriosSort_33_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1348 =
    ~hsipriosSort_32_isZero & ~hsipriosSort_33_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1356 =
    hsipriosSort_32_prioNum <= hsipriosSort_33_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_leftIprio_12_0_prioNum =
    (ipriosTmp_result_leftIprio_leftIprio_sel_1333 & hsipriosSort_32_enable
       ? io_in_hsiprios[23:16]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1335 & hsipriosSort_33_enable
         ? io_in_hsiprios[55:48]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1336
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_1337 & hsipriosSort_32_enable
              ? io_in_hsiprios[23:16]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1339
              & hsipriosSort_33_enable
                ? io_in_hsiprios[55:48]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1343
              & hsipriosSort_32_enable
                ? io_in_hsiprios[23:16]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1348
                ? (ipriosTmp_result_leftIprio_leftIprio_sel_1356
                     ? hsipriosSort_32_prioNum
                     : hsipriosSort_33_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_leftIprio_12_0_isZero =
    ipriosTmp_result_leftIprio_leftIprio_sel_1333 & hsipriosSort_32_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1335 & hsipriosSort_33_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1336
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1337 & hsipriosSort_32_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1339 & hsipriosSort_33_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1343 & hsipriosSort_32_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1348
       & (ipriosTmp_result_leftIprio_leftIprio_sel_1356
            ? hsipriosSort_32_isZero
            : hsipriosSort_33_isZero));
  wire        ipriosTmp_result_leftIprio_leftIprio_12_0_enable =
    ipriosTmp_result_leftIprio_leftIprio_sel_1333 & hsipriosSort_32_enable
    | ipriosTmp_result_leftIprio_leftIprio_sel_1335 & hsipriosSort_33_enable
    | ipriosTmp_result_leftIprio_leftIprio_sel_1336
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1337 & hsipriosSort_32_enable
       | ipriosTmp_result_leftIprio_leftIprio_sel_1339 & hsipriosSort_33_enable
       | ipriosTmp_result_leftIprio_leftIprio_sel_1343 & hsipriosSort_32_enable
       | ipriosTmp_result_leftIprio_leftIprio_sel_1348
       & (ipriosTmp_result_leftIprio_leftIprio_sel_1356
            ? hsipriosSort_32_enable
            : hsipriosSort_33_enable));
  wire [5:0]  ipriosTmp_result_leftIprio_leftIprio_12_0_idx =
    {ipriosTmp_result_leftIprio_leftIprio_sel_1333, 5'h0}
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1335 ? 6'h21 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1336
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_1339 ? 6'h21 : 6'h0)
           | {ipriosTmp_result_leftIprio_leftIprio_sel_1337
                | ipriosTmp_result_leftIprio_leftIprio_sel_1343,
              5'h0}
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1348
                ? {5'h10, ~ipriosTmp_result_leftIprio_leftIprio_sel_1356}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1333 =
    hsipriosSort_34_enable & ~hsSortEn_4_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1335 =
    ~hsipriosSort_34_enable & hsSortEn_4_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1336 =
    hsipriosSort_34_enable & hsSortEn_4_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1337 =
    hsipriosSort_34_isZero & hsipriosSort_35_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1339 =
    hsipriosSort_34_isZero & ~hsipriosSort_35_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1343 =
    ~hsipriosSort_34_isZero & hsipriosSort_35_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1348 =
    ~hsipriosSort_34_isZero & ~hsipriosSort_35_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1356 =
    hsipriosSort_34_prioNum <= hsipriosSort_35_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_rightIprio_12_0_prioNum =
    (ipriosTmp_result_leftIprio_rightIprio_sel_1333 & hsipriosSort_34_enable
       ? io_in_hsiprios[111:104]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1335
       & hsSortEn_4_3
         ? io_in_hsiprios[119:112]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1336
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_1337
            & hsipriosSort_34_enable
              ? io_in_hsiprios[111:104]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1339
              & hsSortEn_4_3
                ? io_in_hsiprios[119:112]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1343
              & hsipriosSort_34_enable
                ? io_in_hsiprios[111:104]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1348
                ? (ipriosTmp_result_leftIprio_rightIprio_sel_1356
                     ? hsipriosSort_34_prioNum
                     : hsipriosSort_35_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_12_0_isZero =
    ipriosTmp_result_leftIprio_rightIprio_sel_1333 & hsipriosSort_34_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1335 & hsipriosSort_35_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1336
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1337 & hsipriosSort_34_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1339 & hsipriosSort_35_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1343 & hsipriosSort_34_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1348
       & (ipriosTmp_result_leftIprio_rightIprio_sel_1356
            ? hsipriosSort_34_isZero
            : hsipriosSort_35_isZero));
  wire        ipriosTmp_result_leftIprio_rightIprio_12_0_enable =
    ipriosTmp_result_leftIprio_rightIprio_sel_1333 & hsipriosSort_34_enable
    | ipriosTmp_result_leftIprio_rightIprio_sel_1335
    & hsSortEn_4_3
    | ipriosTmp_result_leftIprio_rightIprio_sel_1336
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1337 & hsipriosSort_34_enable
       | ipriosTmp_result_leftIprio_rightIprio_sel_1339
       & hsSortEn_4_3
       | ipriosTmp_result_leftIprio_rightIprio_sel_1343 & hsipriosSort_34_enable
       | ipriosTmp_result_leftIprio_rightIprio_sel_1348
       & (ipriosTmp_result_leftIprio_rightIprio_sel_1356
            ? hsipriosSort_34_enable
            : hsSortEn_4_3));
  wire [5:0]  ipriosTmp_result_leftIprio_rightIprio_12_0_idx =
    (ipriosTmp_result_leftIprio_rightIprio_sel_1333 ? 6'h22 : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1335 ? 6'h23 : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1336
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_1337 ? 6'h22 : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1339 ? 6'h23 : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1343 ? 6'h22 : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1348
                ? {5'h11, ~ipriosTmp_result_leftIprio_rightIprio_sel_1356}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_sel_1333 =
    ipriosTmp_result_leftIprio_leftIprio_12_0_enable
    & ~ipriosTmp_result_leftIprio_rightIprio_12_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1335 =
    ~ipriosTmp_result_leftIprio_leftIprio_12_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_12_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1336 =
    ipriosTmp_result_leftIprio_leftIprio_12_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_12_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1337 =
    ipriosTmp_result_leftIprio_leftIprio_12_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_12_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1339 =
    ipriosTmp_result_leftIprio_leftIprio_12_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_12_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1340 =
    ipriosTmp_result_leftIprio_leftIprio_12_0_idx < 6'h1C;
  wire        ipriosTmp_result_leftIprio_sel_1343 =
    ~ipriosTmp_result_leftIprio_leftIprio_12_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_12_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1344 =
    ipriosTmp_result_leftIprio_rightIprio_12_0_idx < 6'h1C;
  wire        ipriosTmp_result_leftIprio_sel_1348 =
    ~ipriosTmp_result_leftIprio_leftIprio_12_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_12_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1356 =
    ipriosTmp_result_leftIprio_leftIprio_12_0_prioNum <= ipriosTmp_result_leftIprio_rightIprio_12_0_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_12_0_prioNum =
    (ipriosTmp_result_leftIprio_sel_1333
       ? ipriosTmp_result_leftIprio_leftIprio_12_0_prioNum
       : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_1335
         ? ipriosTmp_result_leftIprio_rightIprio_12_0_prioNum
         : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_1336
         ? (ipriosTmp_result_leftIprio_sel_1337
              ? ipriosTmp_result_leftIprio_leftIprio_12_0_prioNum
              : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1339
                ? (ipriosTmp_result_leftIprio_sel_1340
                     ? ipriosTmp_result_leftIprio_leftIprio_12_0_prioNum
                     : ipriosTmp_result_leftIprio_rightIprio_12_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1343
                ? (ipriosTmp_result_leftIprio_sel_1344
                     ? ipriosTmp_result_leftIprio_rightIprio_12_0_prioNum
                     : ipriosTmp_result_leftIprio_leftIprio_12_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1348
                ? (ipriosTmp_result_leftIprio_sel_1356
                     ? ipriosTmp_result_leftIprio_leftIprio_12_0_prioNum
                     : ipriosTmp_result_leftIprio_rightIprio_12_0_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_12_0_isZero =
    ipriosTmp_result_leftIprio_sel_1333
    & ipriosTmp_result_leftIprio_leftIprio_12_0_isZero
    | ipriosTmp_result_leftIprio_sel_1335
    & ipriosTmp_result_leftIprio_rightIprio_12_0_isZero
    | ipriosTmp_result_leftIprio_sel_1336
    & (ipriosTmp_result_leftIprio_sel_1337
       & ipriosTmp_result_leftIprio_leftIprio_12_0_isZero
       | ipriosTmp_result_leftIprio_sel_1339
       & (ipriosTmp_result_leftIprio_sel_1340
            ? ipriosTmp_result_leftIprio_leftIprio_12_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_12_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1343
       & (ipriosTmp_result_leftIprio_sel_1344
            ? ipriosTmp_result_leftIprio_rightIprio_12_0_isZero
            : ipriosTmp_result_leftIprio_leftIprio_12_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1348
       & (ipriosTmp_result_leftIprio_sel_1356
            ? ipriosTmp_result_leftIprio_leftIprio_12_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_12_0_isZero));
  wire        ipriosTmp_result_leftIprio_12_0_enable =
    ipriosTmp_result_leftIprio_sel_1333
    & ipriosTmp_result_leftIprio_leftIprio_12_0_enable
    | ipriosTmp_result_leftIprio_sel_1335
    & ipriosTmp_result_leftIprio_rightIprio_12_0_enable
    | ipriosTmp_result_leftIprio_sel_1336
    & (ipriosTmp_result_leftIprio_sel_1337
       & ipriosTmp_result_leftIprio_leftIprio_12_0_enable
       | ipriosTmp_result_leftIprio_sel_1339
       & (ipriosTmp_result_leftIprio_sel_1340
            ? ipriosTmp_result_leftIprio_leftIprio_12_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_12_0_enable)
       | ipriosTmp_result_leftIprio_sel_1343
       & (ipriosTmp_result_leftIprio_sel_1344
            ? ipriosTmp_result_leftIprio_rightIprio_12_0_enable
            : ipriosTmp_result_leftIprio_leftIprio_12_0_enable)
       | ipriosTmp_result_leftIprio_sel_1348
       & (ipriosTmp_result_leftIprio_sel_1356
            ? ipriosTmp_result_leftIprio_leftIprio_12_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_12_0_enable));
  wire [5:0]  ipriosTmp_result_leftIprio_12_0_idx =
    (ipriosTmp_result_leftIprio_sel_1333
       ? ipriosTmp_result_leftIprio_leftIprio_12_0_idx
       : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1335
         ? ipriosTmp_result_leftIprio_rightIprio_12_0_idx
         : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1336
         ? (ipriosTmp_result_leftIprio_sel_1337
              ? ipriosTmp_result_leftIprio_leftIprio_12_0_idx
              : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1339
                ? (ipriosTmp_result_leftIprio_sel_1340
                     ? ipriosTmp_result_leftIprio_leftIprio_12_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_12_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1343
                ? (ipriosTmp_result_leftIprio_sel_1344
                     ? ipriosTmp_result_leftIprio_rightIprio_12_0_idx
                     : ipriosTmp_result_leftIprio_leftIprio_12_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1348
                ? (ipriosTmp_result_leftIprio_sel_1356
                     ? ipriosTmp_result_leftIprio_leftIprio_12_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_12_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1333 =
    hsSortEn_4_4 & ~hsSortEn_4_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1335 =
    ~hsSortEn_4_4 & hsSortEn_4_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1336 =
    hsSortEn_4_4 & hsSortEn_4_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1337 =
    hsipriosSort_36_isZero & hsipriosSort_37_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1339 =
    hsipriosSort_36_isZero & ~hsipriosSort_37_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1343 =
    ~hsipriosSort_36_isZero & hsipriosSort_37_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1348 =
    ~hsipriosSort_36_isZero & ~hsipriosSort_37_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1356 =
    hsipriosSort_36_prioNum <= hsipriosSort_37_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_leftIprio_12_0_prioNum =
    (ipriosTmp_result_rightIprio_leftIprio_sel_1333
     & hsSortEn_4_4
       ? io_in_hsiprios[127:120]
       : 8'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1335
       & hsSortEn_4_5
         ? io_in_hsiprios[447:440]
         : 8'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1336
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_1337
            & hsSortEn_4_4
              ? io_in_hsiprios[127:120]
              : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1339
              & hsSortEn_4_5
                ? io_in_hsiprios[447:440]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1343
              & hsSortEn_4_4
                ? io_in_hsiprios[127:120]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1348
                ? (ipriosTmp_result_rightIprio_leftIprio_sel_1356
                     ? hsipriosSort_36_prioNum
                     : hsipriosSort_37_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_12_0_isZero =
    ipriosTmp_result_rightIprio_leftIprio_sel_1333 & hsipriosSort_36_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1335 & hsipriosSort_37_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1336
    & (ipriosTmp_result_rightIprio_leftIprio_sel_1337 & hsipriosSort_36_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1339 & hsipriosSort_37_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1343 & hsipriosSort_36_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1348
       & (ipriosTmp_result_rightIprio_leftIprio_sel_1356
            ? hsipriosSort_36_isZero
            : hsipriosSort_37_isZero));
  wire        ipriosTmp_result_rightIprio_leftIprio_12_0_enable =
    ipriosTmp_result_rightIprio_leftIprio_sel_1333
    & hsSortEn_4_4
    | ipriosTmp_result_rightIprio_leftIprio_sel_1335
    & hsSortEn_4_5
    | ipriosTmp_result_rightIprio_leftIprio_sel_1336
    & (ipriosTmp_result_rightIprio_leftIprio_sel_1337
       & hsSortEn_4_4
       | ipriosTmp_result_rightIprio_leftIprio_sel_1339
       & hsSortEn_4_5
       | ipriosTmp_result_rightIprio_leftIprio_sel_1343
       & hsSortEn_4_4
       | ipriosTmp_result_rightIprio_leftIprio_sel_1348
       & (ipriosTmp_result_rightIprio_leftIprio_sel_1356
            ? hsSortEn_4_4
            : hsSortEn_4_5));
  wire [5:0]  ipriosTmp_result_rightIprio_leftIprio_12_0_idx =
    (ipriosTmp_result_rightIprio_leftIprio_sel_1333 ? 6'h24 : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1335 ? 6'h25 : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1336
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_1337 ? 6'h24 : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1339 ? 6'h25 : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1343 ? 6'h24 : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1348
                ? {5'h12, ~ipriosTmp_result_rightIprio_leftIprio_sel_1356}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1333 =
    hsSortEn_4_6 & ~hsSortEn_4_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1335 =
    ~hsSortEn_4_6 & hsSortEn_4_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1336 =
    hsSortEn_4_6 & hsSortEn_4_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1337 =
    hsipriosSort_38_isZero & hsipriosSort_39_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1339 =
    hsipriosSort_38_isZero & ~hsipriosSort_39_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1343 =
    ~hsipriosSort_38_isZero & hsipriosSort_39_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1348 =
    ~hsipriosSort_38_isZero & ~hsipriosSort_39_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1356 =
    hsipriosSort_38_prioNum <= hsipriosSort_39_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_rightIprio_12_0_prioNum =
    (ipriosTmp_result_rightIprio_rightIprio_sel_1333
     & hsSortEn_4_6
       ? io_in_hsiprios[223:216]
       : 8'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1335
       & hsSortEn_4_7
         ? io_in_hsiprios[439:432]
         : 8'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1336
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_1337
            & hsSortEn_4_6
              ? io_in_hsiprios[223:216]
              : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1339
              & hsSortEn_4_7
                ? io_in_hsiprios[439:432]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1343
              & hsSortEn_4_6
                ? io_in_hsiprios[223:216]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1348
                ? (ipriosTmp_result_rightIprio_rightIprio_sel_1356
                     ? hsipriosSort_38_prioNum
                     : hsipriosSort_39_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_12_0_isZero =
    ipriosTmp_result_rightIprio_rightIprio_sel_1333 & hsipriosSort_38_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1335 & hsipriosSort_39_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1336
    & (ipriosTmp_result_rightIprio_rightIprio_sel_1337 & hsipriosSort_38_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1339 & hsipriosSort_39_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1343 & hsipriosSort_38_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1348
       & (ipriosTmp_result_rightIprio_rightIprio_sel_1356
            ? hsipriosSort_38_isZero
            : hsipriosSort_39_isZero));
  wire        ipriosTmp_result_rightIprio_rightIprio_12_0_enable =
    ipriosTmp_result_rightIprio_rightIprio_sel_1333
    & hsSortEn_4_6
    | ipriosTmp_result_rightIprio_rightIprio_sel_1335
    & hsSortEn_4_7
    | ipriosTmp_result_rightIprio_rightIprio_sel_1336
    & (ipriosTmp_result_rightIprio_rightIprio_sel_1337
       & hsSortEn_4_6
       | ipriosTmp_result_rightIprio_rightIprio_sel_1339
       & hsSortEn_4_7
       | ipriosTmp_result_rightIprio_rightIprio_sel_1343
       & hsSortEn_4_6
       | ipriosTmp_result_rightIprio_rightIprio_sel_1348
       & (ipriosTmp_result_rightIprio_rightIprio_sel_1356
            ? hsSortEn_4_6
            : hsSortEn_4_7));
  wire [5:0]  ipriosTmp_result_rightIprio_rightIprio_12_0_idx =
    (ipriosTmp_result_rightIprio_rightIprio_sel_1333 ? 6'h26 : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1335 ? 6'h27 : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1336
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_1337 ? 6'h26 : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1339 ? 6'h27 : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1343 ? 6'h26 : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1348
                ? {5'h13, ~ipriosTmp_result_rightIprio_rightIprio_sel_1356}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_sel_1333 =
    ipriosTmp_result_rightIprio_leftIprio_12_0_enable
    & ~ipriosTmp_result_rightIprio_rightIprio_12_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1335 =
    ~ipriosTmp_result_rightIprio_leftIprio_12_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_12_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1336 =
    ipriosTmp_result_rightIprio_leftIprio_12_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_12_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1337 =
    ipriosTmp_result_rightIprio_leftIprio_12_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_12_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1339 =
    ipriosTmp_result_rightIprio_leftIprio_12_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_12_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1340 =
    ipriosTmp_result_rightIprio_leftIprio_12_0_idx < 6'h1C;
  wire        ipriosTmp_result_rightIprio_sel_1343 =
    ~ipriosTmp_result_rightIprio_leftIprio_12_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_12_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1344 =
    ipriosTmp_result_rightIprio_rightIprio_12_0_idx < 6'h1C;
  wire        ipriosTmp_result_rightIprio_sel_1348 =
    ~ipriosTmp_result_rightIprio_leftIprio_12_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_12_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1356 =
    ipriosTmp_result_rightIprio_leftIprio_12_0_prioNum <= ipriosTmp_result_rightIprio_rightIprio_12_0_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_12_0_prioNum =
    (ipriosTmp_result_rightIprio_sel_1333
       ? ipriosTmp_result_rightIprio_leftIprio_12_0_prioNum
       : 8'h0)
    | (ipriosTmp_result_rightIprio_sel_1335
         ? ipriosTmp_result_rightIprio_rightIprio_12_0_prioNum
         : 8'h0)
    | (ipriosTmp_result_rightIprio_sel_1336
         ? (ipriosTmp_result_rightIprio_sel_1337
              ? ipriosTmp_result_rightIprio_leftIprio_12_0_prioNum
              : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1339
                ? (ipriosTmp_result_rightIprio_sel_1340
                     ? ipriosTmp_result_rightIprio_leftIprio_12_0_prioNum
                     : ipriosTmp_result_rightIprio_rightIprio_12_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1343
                ? (ipriosTmp_result_rightIprio_sel_1344
                     ? ipriosTmp_result_rightIprio_rightIprio_12_0_prioNum
                     : ipriosTmp_result_rightIprio_leftIprio_12_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1348
                ? (ipriosTmp_result_rightIprio_sel_1356
                     ? ipriosTmp_result_rightIprio_leftIprio_12_0_prioNum
                     : ipriosTmp_result_rightIprio_rightIprio_12_0_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_12_0_isZero =
    ipriosTmp_result_rightIprio_sel_1333
    & ipriosTmp_result_rightIprio_leftIprio_12_0_isZero
    | ipriosTmp_result_rightIprio_sel_1335
    & ipriosTmp_result_rightIprio_rightIprio_12_0_isZero
    | ipriosTmp_result_rightIprio_sel_1336
    & (ipriosTmp_result_rightIprio_sel_1337
       & ipriosTmp_result_rightIprio_leftIprio_12_0_isZero
       | ipriosTmp_result_rightIprio_sel_1339
       & (ipriosTmp_result_rightIprio_sel_1340
            ? ipriosTmp_result_rightIprio_leftIprio_12_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_12_0_isZero)
       | ipriosTmp_result_rightIprio_sel_1343
       & (ipriosTmp_result_rightIprio_sel_1344
            ? ipriosTmp_result_rightIprio_rightIprio_12_0_isZero
            : ipriosTmp_result_rightIprio_leftIprio_12_0_isZero)
       | ipriosTmp_result_rightIprio_sel_1348
       & (ipriosTmp_result_rightIprio_sel_1356
            ? ipriosTmp_result_rightIprio_leftIprio_12_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_12_0_isZero));
  wire        ipriosTmp_result_rightIprio_12_0_enable =
    ipriosTmp_result_rightIprio_sel_1333
    & ipriosTmp_result_rightIprio_leftIprio_12_0_enable
    | ipriosTmp_result_rightIprio_sel_1335
    & ipriosTmp_result_rightIprio_rightIprio_12_0_enable
    | ipriosTmp_result_rightIprio_sel_1336
    & (ipriosTmp_result_rightIprio_sel_1337
       & ipriosTmp_result_rightIprio_leftIprio_12_0_enable
       | ipriosTmp_result_rightIprio_sel_1339
       & (ipriosTmp_result_rightIprio_sel_1340
            ? ipriosTmp_result_rightIprio_leftIprio_12_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_12_0_enable)
       | ipriosTmp_result_rightIprio_sel_1343
       & (ipriosTmp_result_rightIprio_sel_1344
            ? ipriosTmp_result_rightIprio_rightIprio_12_0_enable
            : ipriosTmp_result_rightIprio_leftIprio_12_0_enable)
       | ipriosTmp_result_rightIprio_sel_1348
       & (ipriosTmp_result_rightIprio_sel_1356
            ? ipriosTmp_result_rightIprio_leftIprio_12_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_12_0_enable));
  wire [5:0]  ipriosTmp_result_rightIprio_12_0_idx =
    (ipriosTmp_result_rightIprio_sel_1333
       ? ipriosTmp_result_rightIprio_leftIprio_12_0_idx
       : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_1335
         ? ipriosTmp_result_rightIprio_rightIprio_12_0_idx
         : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_1336
         ? (ipriosTmp_result_rightIprio_sel_1337
              ? ipriosTmp_result_rightIprio_leftIprio_12_0_idx
              : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1339
                ? (ipriosTmp_result_rightIprio_sel_1340
                     ? ipriosTmp_result_rightIprio_leftIprio_12_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_12_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1343
                ? (ipriosTmp_result_rightIprio_sel_1344
                     ? ipriosTmp_result_rightIprio_rightIprio_12_0_idx
                     : ipriosTmp_result_rightIprio_leftIprio_12_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1348
                ? (ipriosTmp_result_rightIprio_sel_1356
                     ? ipriosTmp_result_rightIprio_leftIprio_12_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_12_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_sel_1333 =
    ipriosTmp_result_leftIprio_12_0_enable & ~ipriosTmp_result_rightIprio_12_0_enable;
  wire        ipriosTmp_result_sel_1335 =
    ~ipriosTmp_result_leftIprio_12_0_enable & ipriosTmp_result_rightIprio_12_0_enable;
  wire        ipriosTmp_result_sel_1336 =
    ipriosTmp_result_leftIprio_12_0_enable & ipriosTmp_result_rightIprio_12_0_enable;
  wire        ipriosTmp_result_sel_1337 =
    ipriosTmp_result_leftIprio_12_0_isZero & ipriosTmp_result_rightIprio_12_0_isZero;
  wire        ipriosTmp_result_sel_1339 =
    ipriosTmp_result_leftIprio_12_0_isZero & ~ipriosTmp_result_rightIprio_12_0_isZero;
  wire        ipriosTmp_result_sel_1340 =
    ipriosTmp_result_leftIprio_12_0_idx < 6'h1C;
  wire        ipriosTmp_result_sel_1343 =
    ~ipriosTmp_result_leftIprio_12_0_isZero & ipriosTmp_result_rightIprio_12_0_isZero;
  wire        ipriosTmp_result_sel_1344 =
    ipriosTmp_result_rightIprio_12_0_idx < 6'h1C;
  wire        ipriosTmp_result_sel_1348 =
    ~ipriosTmp_result_leftIprio_12_0_isZero & ~ipriosTmp_result_rightIprio_12_0_isZero;
  wire        ipriosTmp_result_sel_1356 =
    ipriosTmp_result_leftIprio_12_0_prioNum <= ipriosTmp_result_rightIprio_12_0_prioNum;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1444 =
    hsSortEn_5_0 & ~hsSortEn_5_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1446 =
    ~hsSortEn_5_0 & hsSortEn_5_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1447 =
    hsSortEn_5_0 & hsSortEn_5_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1448 =
    hsipriosSort_40_isZero & hsipriosSort_41_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1450 =
    hsipriosSort_40_isZero & ~hsipriosSort_41_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1454 =
    ~hsipriosSort_40_isZero & hsipriosSort_41_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1459 =
    ~hsipriosSort_40_isZero & ~hsipriosSort_41_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1467 =
    hsipriosSort_40_prioNum <= hsipriosSort_41_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_leftIprio_13_0_prioNum =
    (ipriosTmp_result_leftIprio_leftIprio_sel_1444
     & hsSortEn_5_0
       ? io_in_hsiprios[431:424]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1446
       & hsSortEn_5_1
         ? io_in_hsiprios[215:208]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1447
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_1448
            & hsSortEn_5_0
              ? io_in_hsiprios[431:424]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1450
              & hsSortEn_5_1
                ? io_in_hsiprios[215:208]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1454
              & hsSortEn_5_0
                ? io_in_hsiprios[431:424]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1459
                ? (ipriosTmp_result_leftIprio_leftIprio_sel_1467
                     ? hsipriosSort_40_prioNum
                     : hsipriosSort_41_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_leftIprio_13_0_isZero =
    ipriosTmp_result_leftIprio_leftIprio_sel_1444 & hsipriosSort_40_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1446 & hsipriosSort_41_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1447
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1448 & hsipriosSort_40_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1450 & hsipriosSort_41_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1454 & hsipriosSort_40_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1459
       & (ipriosTmp_result_leftIprio_leftIprio_sel_1467
            ? hsipriosSort_40_isZero
            : hsipriosSort_41_isZero));
  wire        ipriosTmp_result_leftIprio_leftIprio_13_0_enable =
    ipriosTmp_result_leftIprio_leftIprio_sel_1444
    & hsSortEn_5_0
    | ipriosTmp_result_leftIprio_leftIprio_sel_1446
    & hsSortEn_5_1
    | ipriosTmp_result_leftIprio_leftIprio_sel_1447
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1448
       & hsSortEn_5_0
       | ipriosTmp_result_leftIprio_leftIprio_sel_1450
       & hsSortEn_5_1
       | ipriosTmp_result_leftIprio_leftIprio_sel_1454
       & hsSortEn_5_0
       | ipriosTmp_result_leftIprio_leftIprio_sel_1459
       & (ipriosTmp_result_leftIprio_leftIprio_sel_1467
            ? hsSortEn_5_0
            : hsSortEn_5_1));
  wire [5:0]  ipriosTmp_result_leftIprio_leftIprio_13_0_idx =
    (ipriosTmp_result_leftIprio_leftIprio_sel_1444 ? 6'h28 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1446 ? 6'h29 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1447
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_1448 ? 6'h28 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1450 ? 6'h29 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1454 ? 6'h28 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1459
                ? {5'h14, ~ipriosTmp_result_leftIprio_leftIprio_sel_1467}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1444 =
    hsSortEn_5_2 & ~hsSortEn_5_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1446 =
    ~hsSortEn_5_2 & hsSortEn_5_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1447 =
    hsSortEn_5_2 & hsSortEn_5_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1448 =
    hsipriosSort_42_isZero & hsipriosSort_43_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1450 =
    hsipriosSort_42_isZero & ~hsipriosSort_43_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1454 =
    ~hsipriosSort_42_isZero & hsipriosSort_43_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1459 =
    ~hsipriosSort_42_isZero & ~hsipriosSort_43_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1467 =
    hsipriosSort_42_prioNum <= hsipriosSort_43_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_rightIprio_13_0_prioNum =
    (ipriosTmp_result_leftIprio_rightIprio_sel_1444
     & hsSortEn_5_2
       ? io_in_hsiprios[423:416]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1446
       & hsSortEn_5_3
         ? io_in_hsiprios[319:312]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1447
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_1448
            & hsSortEn_5_2
              ? io_in_hsiprios[423:416]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1450
              & hsSortEn_5_3
                ? io_in_hsiprios[319:312]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1454
              & hsSortEn_5_2
                ? io_in_hsiprios[423:416]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1459
                ? (ipriosTmp_result_leftIprio_rightIprio_sel_1467
                     ? hsipriosSort_42_prioNum
                     : hsipriosSort_43_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_13_0_isZero =
    ipriosTmp_result_leftIprio_rightIprio_sel_1444 & hsipriosSort_42_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1446 & hsipriosSort_43_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1447
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1448 & hsipriosSort_42_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1450 & hsipriosSort_43_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1454 & hsipriosSort_42_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1459
       & (ipriosTmp_result_leftIprio_rightIprio_sel_1467
            ? hsipriosSort_42_isZero
            : hsipriosSort_43_isZero));
  wire        ipriosTmp_result_leftIprio_rightIprio_13_0_enable =
    ipriosTmp_result_leftIprio_rightIprio_sel_1444
    & hsSortEn_5_2
    | ipriosTmp_result_leftIprio_rightIprio_sel_1446
    & hsSortEn_5_3
    | ipriosTmp_result_leftIprio_rightIprio_sel_1447
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1448
       & hsSortEn_5_2
       | ipriosTmp_result_leftIprio_rightIprio_sel_1450
       & hsSortEn_5_3
       | ipriosTmp_result_leftIprio_rightIprio_sel_1454
       & hsSortEn_5_2
       | ipriosTmp_result_leftIprio_rightIprio_sel_1459
       & (ipriosTmp_result_leftIprio_rightIprio_sel_1467
            ? hsSortEn_5_2
            : hsSortEn_5_3));
  wire [5:0]  ipriosTmp_result_leftIprio_rightIprio_13_0_idx =
    (ipriosTmp_result_leftIprio_rightIprio_sel_1444 ? 6'h2A : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1446 ? 6'h2B : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1447
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_1448 ? 6'h2A : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1450 ? 6'h2B : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1454 ? 6'h2A : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1459
                ? {5'h15, ~ipriosTmp_result_leftIprio_rightIprio_sel_1467}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_sel_1444 =
    ipriosTmp_result_leftIprio_leftIprio_13_0_enable
    & ~ipriosTmp_result_leftIprio_rightIprio_13_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1446 =
    ~ipriosTmp_result_leftIprio_leftIprio_13_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_13_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1447 =
    ipriosTmp_result_leftIprio_leftIprio_13_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_13_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1448 =
    ipriosTmp_result_leftIprio_leftIprio_13_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_13_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1450 =
    ipriosTmp_result_leftIprio_leftIprio_13_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_13_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1451 =
    ipriosTmp_result_leftIprio_leftIprio_13_0_idx < 6'h1C;
  wire        ipriosTmp_result_leftIprio_sel_1454 =
    ~ipriosTmp_result_leftIprio_leftIprio_13_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_13_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1455 =
    ipriosTmp_result_leftIprio_rightIprio_13_0_idx < 6'h1C;
  wire        ipriosTmp_result_leftIprio_sel_1459 =
    ~ipriosTmp_result_leftIprio_leftIprio_13_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_13_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1467 =
    ipriosTmp_result_leftIprio_leftIprio_13_0_prioNum <= ipriosTmp_result_leftIprio_rightIprio_13_0_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_13_0_prioNum =
    (ipriosTmp_result_leftIprio_sel_1444
       ? ipriosTmp_result_leftIprio_leftIprio_13_0_prioNum
       : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_1446
         ? ipriosTmp_result_leftIprio_rightIprio_13_0_prioNum
         : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_1447
         ? (ipriosTmp_result_leftIprio_sel_1448
              ? ipriosTmp_result_leftIprio_leftIprio_13_0_prioNum
              : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1450
                ? (ipriosTmp_result_leftIprio_sel_1451
                     ? ipriosTmp_result_leftIprio_leftIprio_13_0_prioNum
                     : ipriosTmp_result_leftIprio_rightIprio_13_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1454
                ? (ipriosTmp_result_leftIprio_sel_1455
                     ? ipriosTmp_result_leftIprio_rightIprio_13_0_prioNum
                     : ipriosTmp_result_leftIprio_leftIprio_13_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1459
                ? (ipriosTmp_result_leftIprio_sel_1467
                     ? ipriosTmp_result_leftIprio_leftIprio_13_0_prioNum
                     : ipriosTmp_result_leftIprio_rightIprio_13_0_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_13_0_isZero =
    ipriosTmp_result_leftIprio_sel_1444
    & ipriosTmp_result_leftIprio_leftIprio_13_0_isZero
    | ipriosTmp_result_leftIprio_sel_1446
    & ipriosTmp_result_leftIprio_rightIprio_13_0_isZero
    | ipriosTmp_result_leftIprio_sel_1447
    & (ipriosTmp_result_leftIprio_sel_1448
       & ipriosTmp_result_leftIprio_leftIprio_13_0_isZero
       | ipriosTmp_result_leftIprio_sel_1450
       & (ipriosTmp_result_leftIprio_sel_1451
            ? ipriosTmp_result_leftIprio_leftIprio_13_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_13_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1454
       & (ipriosTmp_result_leftIprio_sel_1455
            ? ipriosTmp_result_leftIprio_rightIprio_13_0_isZero
            : ipriosTmp_result_leftIprio_leftIprio_13_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1459
       & (ipriosTmp_result_leftIprio_sel_1467
            ? ipriosTmp_result_leftIprio_leftIprio_13_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_13_0_isZero));
  wire        ipriosTmp_result_leftIprio_13_0_enable =
    ipriosTmp_result_leftIprio_sel_1444
    & ipriosTmp_result_leftIprio_leftIprio_13_0_enable
    | ipriosTmp_result_leftIprio_sel_1446
    & ipriosTmp_result_leftIprio_rightIprio_13_0_enable
    | ipriosTmp_result_leftIprio_sel_1447
    & (ipriosTmp_result_leftIprio_sel_1448
       & ipriosTmp_result_leftIprio_leftIprio_13_0_enable
       | ipriosTmp_result_leftIprio_sel_1450
       & (ipriosTmp_result_leftIprio_sel_1451
            ? ipriosTmp_result_leftIprio_leftIprio_13_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_13_0_enable)
       | ipriosTmp_result_leftIprio_sel_1454
       & (ipriosTmp_result_leftIprio_sel_1455
            ? ipriosTmp_result_leftIprio_rightIprio_13_0_enable
            : ipriosTmp_result_leftIprio_leftIprio_13_0_enable)
       | ipriosTmp_result_leftIprio_sel_1459
       & (ipriosTmp_result_leftIprio_sel_1467
            ? ipriosTmp_result_leftIprio_leftIprio_13_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_13_0_enable));
  wire [5:0]  ipriosTmp_result_leftIprio_13_0_idx =
    (ipriosTmp_result_leftIprio_sel_1444
       ? ipriosTmp_result_leftIprio_leftIprio_13_0_idx
       : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1446
         ? ipriosTmp_result_leftIprio_rightIprio_13_0_idx
         : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1447
         ? (ipriosTmp_result_leftIprio_sel_1448
              ? ipriosTmp_result_leftIprio_leftIprio_13_0_idx
              : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1450
                ? (ipriosTmp_result_leftIprio_sel_1451
                     ? ipriosTmp_result_leftIprio_leftIprio_13_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_13_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1454
                ? (ipriosTmp_result_leftIprio_sel_1455
                     ? ipriosTmp_result_leftIprio_rightIprio_13_0_idx
                     : ipriosTmp_result_leftIprio_leftIprio_13_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1459
                ? (ipriosTmp_result_leftIprio_sel_1467
                     ? ipriosTmp_result_leftIprio_leftIprio_13_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_13_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1444 =
    hsSortEn_5_4 & ~hsSortEn_5_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1446 =
    ~hsSortEn_5_4 & hsSortEn_5_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1447 =
    hsSortEn_5_4 & hsSortEn_5_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1448 =
    hsipriosSort_44_isZero & hsipriosSort_45_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1450 =
    hsipriosSort_44_isZero & ~hsipriosSort_45_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1454 =
    ~hsipriosSort_44_isZero & hsipriosSort_45_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1459 =
    ~hsipriosSort_44_isZero & ~hsipriosSort_45_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1467 =
    hsipriosSort_44_prioNum <= hsipriosSort_45_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_leftIprio_13_0_prioNum =
    (ipriosTmp_result_rightIprio_leftIprio_sel_1444
     & hsSortEn_5_4
       ? io_in_hsiprios[159:152]
       : 8'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1446
       & hsSortEn_5_5
         ? io_in_hsiprios[311:304]
         : 8'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1447
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_1448
            & hsSortEn_5_4
              ? io_in_hsiprios[159:152]
              : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1450
              & hsSortEn_5_5
                ? io_in_hsiprios[311:304]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1454
              & hsSortEn_5_4
                ? io_in_hsiprios[159:152]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1459
                ? (ipriosTmp_result_rightIprio_leftIprio_sel_1467
                     ? hsipriosSort_44_prioNum
                     : hsipriosSort_45_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_13_0_isZero =
    ipriosTmp_result_rightIprio_leftIprio_sel_1444 & hsipriosSort_44_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1446 & hsipriosSort_45_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1447
    & (ipriosTmp_result_rightIprio_leftIprio_sel_1448 & hsipriosSort_44_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1450 & hsipriosSort_45_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1454 & hsipriosSort_44_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1459
       & (ipriosTmp_result_rightIprio_leftIprio_sel_1467
            ? hsipriosSort_44_isZero
            : hsipriosSort_45_isZero));
  wire        ipriosTmp_result_rightIprio_leftIprio_13_0_enable =
    ipriosTmp_result_rightIprio_leftIprio_sel_1444
    & hsSortEn_5_4
    | ipriosTmp_result_rightIprio_leftIprio_sel_1446
    & hsSortEn_5_5
    | ipriosTmp_result_rightIprio_leftIprio_sel_1447
    & (ipriosTmp_result_rightIprio_leftIprio_sel_1448
       & hsSortEn_5_4
       | ipriosTmp_result_rightIprio_leftIprio_sel_1450
       & hsSortEn_5_5
       | ipriosTmp_result_rightIprio_leftIprio_sel_1454
       & hsSortEn_5_4
       | ipriosTmp_result_rightIprio_leftIprio_sel_1459
       & (ipriosTmp_result_rightIprio_leftIprio_sel_1467
            ? hsSortEn_5_4
            : hsSortEn_5_5));
  wire [5:0]  ipriosTmp_result_rightIprio_leftIprio_13_0_idx =
    (ipriosTmp_result_rightIprio_leftIprio_sel_1444 ? 6'h2C : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1446 ? 6'h2D : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1447
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_1448 ? 6'h2C : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1450 ? 6'h2D : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1454 ? 6'h2C : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1459
                ? {5'h16, ~ipriosTmp_result_rightIprio_leftIprio_sel_1467}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1444 =
    hsSortEn_5_6 & ~hsSortEn_5_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1446 =
    ~hsSortEn_5_6 & hsSortEn_5_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1447 =
    hsSortEn_5_6 & hsSortEn_5_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1448 =
    hsipriosSort_46_isZero & hsipriosSort_47_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1450 =
    hsipriosSort_46_isZero & ~hsipriosSort_47_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1454 =
    ~hsipriosSort_46_isZero & hsipriosSort_47_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1459 =
    ~hsipriosSort_46_isZero & ~hsipriosSort_47_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1467 =
    hsipriosSort_46_prioNum <= hsipriosSort_47_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_rightIprio_13_0_prioNum =
    (ipriosTmp_result_rightIprio_rightIprio_sel_1444
     & hsSortEn_5_6
       ? io_in_hsiprios[303:296]
       : 8'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1446
       & hsSortEn_5_7
         ? io_in_hsiprios[151:144]
         : 8'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1447
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_1448
            & hsSortEn_5_6
              ? io_in_hsiprios[303:296]
              : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1450
              & hsSortEn_5_7
                ? io_in_hsiprios[151:144]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1454
              & hsSortEn_5_6
                ? io_in_hsiprios[303:296]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1459
                ? (ipriosTmp_result_rightIprio_rightIprio_sel_1467
                     ? hsipriosSort_46_prioNum
                     : hsipriosSort_47_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_13_0_isZero =
    ipriosTmp_result_rightIprio_rightIprio_sel_1444 & hsipriosSort_46_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1446 & hsipriosSort_47_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1447
    & (ipriosTmp_result_rightIprio_rightIprio_sel_1448 & hsipriosSort_46_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1450 & hsipriosSort_47_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1454 & hsipriosSort_46_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1459
       & (ipriosTmp_result_rightIprio_rightIprio_sel_1467
            ? hsipriosSort_46_isZero
            : hsipriosSort_47_isZero));
  wire        ipriosTmp_result_rightIprio_rightIprio_13_0_enable =
    ipriosTmp_result_rightIprio_rightIprio_sel_1444
    & hsSortEn_5_6
    | ipriosTmp_result_rightIprio_rightIprio_sel_1446
    & hsSortEn_5_7
    | ipriosTmp_result_rightIprio_rightIprio_sel_1447
    & (ipriosTmp_result_rightIprio_rightIprio_sel_1448
       & hsSortEn_5_6
       | ipriosTmp_result_rightIprio_rightIprio_sel_1450
       & hsSortEn_5_7
       | ipriosTmp_result_rightIprio_rightIprio_sel_1454
       & hsSortEn_5_6
       | ipriosTmp_result_rightIprio_rightIprio_sel_1459
       & (ipriosTmp_result_rightIprio_rightIprio_sel_1467
            ? hsSortEn_5_6
            : hsSortEn_5_7));
  wire [5:0]  ipriosTmp_result_rightIprio_rightIprio_13_0_idx =
    (ipriosTmp_result_rightIprio_rightIprio_sel_1444 ? 6'h2E : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1446 ? 6'h2F : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1447
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_1448 ? 6'h2E : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1450 ? 6'h2F : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1454 ? 6'h2E : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1459
                ? {5'h17, ~ipriosTmp_result_rightIprio_rightIprio_sel_1467}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_sel_1444 =
    ipriosTmp_result_rightIprio_leftIprio_13_0_enable
    & ~ipriosTmp_result_rightIprio_rightIprio_13_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1446 =
    ~ipriosTmp_result_rightIprio_leftIprio_13_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_13_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1447 =
    ipriosTmp_result_rightIprio_leftIprio_13_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_13_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1448 =
    ipriosTmp_result_rightIprio_leftIprio_13_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_13_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1450 =
    ipriosTmp_result_rightIprio_leftIprio_13_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_13_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1451 =
    ipriosTmp_result_rightIprio_leftIprio_13_0_idx < 6'h1C;
  wire        ipriosTmp_result_rightIprio_sel_1454 =
    ~ipriosTmp_result_rightIprio_leftIprio_13_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_13_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1455 =
    ipriosTmp_result_rightIprio_rightIprio_13_0_idx < 6'h1C;
  wire        ipriosTmp_result_rightIprio_sel_1459 =
    ~ipriosTmp_result_rightIprio_leftIprio_13_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_13_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1467 =
    ipriosTmp_result_rightIprio_leftIprio_13_0_prioNum <= ipriosTmp_result_rightIprio_rightIprio_13_0_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_13_0_prioNum =
    (ipriosTmp_result_rightIprio_sel_1444
       ? ipriosTmp_result_rightIprio_leftIprio_13_0_prioNum
       : 8'h0)
    | (ipriosTmp_result_rightIprio_sel_1446
         ? ipriosTmp_result_rightIprio_rightIprio_13_0_prioNum
         : 8'h0)
    | (ipriosTmp_result_rightIprio_sel_1447
         ? (ipriosTmp_result_rightIprio_sel_1448
              ? ipriosTmp_result_rightIprio_leftIprio_13_0_prioNum
              : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1450
                ? (ipriosTmp_result_rightIprio_sel_1451
                     ? ipriosTmp_result_rightIprio_leftIprio_13_0_prioNum
                     : ipriosTmp_result_rightIprio_rightIprio_13_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1454
                ? (ipriosTmp_result_rightIprio_sel_1455
                     ? ipriosTmp_result_rightIprio_rightIprio_13_0_prioNum
                     : ipriosTmp_result_rightIprio_leftIprio_13_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1459
                ? (ipriosTmp_result_rightIprio_sel_1467
                     ? ipriosTmp_result_rightIprio_leftIprio_13_0_prioNum
                     : ipriosTmp_result_rightIprio_rightIprio_13_0_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_13_0_isZero =
    ipriosTmp_result_rightIprio_sel_1444
    & ipriosTmp_result_rightIprio_leftIprio_13_0_isZero
    | ipriosTmp_result_rightIprio_sel_1446
    & ipriosTmp_result_rightIprio_rightIprio_13_0_isZero
    | ipriosTmp_result_rightIprio_sel_1447
    & (ipriosTmp_result_rightIprio_sel_1448
       & ipriosTmp_result_rightIprio_leftIprio_13_0_isZero
       | ipriosTmp_result_rightIprio_sel_1450
       & (ipriosTmp_result_rightIprio_sel_1451
            ? ipriosTmp_result_rightIprio_leftIprio_13_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_13_0_isZero)
       | ipriosTmp_result_rightIprio_sel_1454
       & (ipriosTmp_result_rightIprio_sel_1455
            ? ipriosTmp_result_rightIprio_rightIprio_13_0_isZero
            : ipriosTmp_result_rightIprio_leftIprio_13_0_isZero)
       | ipriosTmp_result_rightIprio_sel_1459
       & (ipriosTmp_result_rightIprio_sel_1467
            ? ipriosTmp_result_rightIprio_leftIprio_13_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_13_0_isZero));
  wire        ipriosTmp_result_rightIprio_13_0_enable =
    ipriosTmp_result_rightIprio_sel_1444
    & ipriosTmp_result_rightIprio_leftIprio_13_0_enable
    | ipriosTmp_result_rightIprio_sel_1446
    & ipriosTmp_result_rightIprio_rightIprio_13_0_enable
    | ipriosTmp_result_rightIprio_sel_1447
    & (ipriosTmp_result_rightIprio_sel_1448
       & ipriosTmp_result_rightIprio_leftIprio_13_0_enable
       | ipriosTmp_result_rightIprio_sel_1450
       & (ipriosTmp_result_rightIprio_sel_1451
            ? ipriosTmp_result_rightIprio_leftIprio_13_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_13_0_enable)
       | ipriosTmp_result_rightIprio_sel_1454
       & (ipriosTmp_result_rightIprio_sel_1455
            ? ipriosTmp_result_rightIprio_rightIprio_13_0_enable
            : ipriosTmp_result_rightIprio_leftIprio_13_0_enable)
       | ipriosTmp_result_rightIprio_sel_1459
       & (ipriosTmp_result_rightIprio_sel_1467
            ? ipriosTmp_result_rightIprio_leftIprio_13_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_13_0_enable));
  wire [5:0]  ipriosTmp_result_rightIprio_13_0_idx =
    (ipriosTmp_result_rightIprio_sel_1444
       ? ipriosTmp_result_rightIprio_leftIprio_13_0_idx
       : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_1446
         ? ipriosTmp_result_rightIprio_rightIprio_13_0_idx
         : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_1447
         ? (ipriosTmp_result_rightIprio_sel_1448
              ? ipriosTmp_result_rightIprio_leftIprio_13_0_idx
              : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1450
                ? (ipriosTmp_result_rightIprio_sel_1451
                     ? ipriosTmp_result_rightIprio_leftIprio_13_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_13_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1454
                ? (ipriosTmp_result_rightIprio_sel_1455
                     ? ipriosTmp_result_rightIprio_rightIprio_13_0_idx
                     : ipriosTmp_result_rightIprio_leftIprio_13_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1459
                ? (ipriosTmp_result_rightIprio_sel_1467
                     ? ipriosTmp_result_rightIprio_leftIprio_13_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_13_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_sel_1444 =
    ipriosTmp_result_leftIprio_13_0_enable & ~ipriosTmp_result_rightIprio_13_0_enable;
  wire        ipriosTmp_result_sel_1446 =
    ~ipriosTmp_result_leftIprio_13_0_enable & ipriosTmp_result_rightIprio_13_0_enable;
  wire        ipriosTmp_result_sel_1447 =
    ipriosTmp_result_leftIprio_13_0_enable & ipriosTmp_result_rightIprio_13_0_enable;
  wire        ipriosTmp_result_sel_1448 =
    ipriosTmp_result_leftIprio_13_0_isZero & ipriosTmp_result_rightIprio_13_0_isZero;
  wire        ipriosTmp_result_sel_1450 =
    ipriosTmp_result_leftIprio_13_0_isZero & ~ipriosTmp_result_rightIprio_13_0_isZero;
  wire        ipriosTmp_result_sel_1451 =
    ipriosTmp_result_leftIprio_13_0_idx < 6'h1C;
  wire        ipriosTmp_result_sel_1454 =
    ~ipriosTmp_result_leftIprio_13_0_isZero & ipriosTmp_result_rightIprio_13_0_isZero;
  wire        ipriosTmp_result_sel_1455 =
    ipriosTmp_result_rightIprio_13_0_idx < 6'h1C;
  wire        ipriosTmp_result_sel_1459 =
    ~ipriosTmp_result_leftIprio_13_0_isZero & ~ipriosTmp_result_rightIprio_13_0_isZero;
  wire        ipriosTmp_result_sel_1467 =
    ipriosTmp_result_leftIprio_13_0_prioNum <= ipriosTmp_result_rightIprio_13_0_prioNum;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1555 =
    hsSortEn_6_0 & ~hsSortEn_6_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1557 =
    ~hsSortEn_6_0 & hsSortEn_6_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1558 =
    hsSortEn_6_0 & hsSortEn_6_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1559 =
    hsipriosSort_48_isZero & hsipriosSort_49_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1561 =
    hsipriosSort_48_isZero & ~hsipriosSort_49_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1565 =
    ~hsipriosSort_48_isZero & hsipriosSort_49_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1570 =
    ~hsipriosSort_48_isZero & ~hsipriosSort_49_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1578 =
    hsipriosSort_48_prioNum <= hsipriosSort_49_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_leftIprio_14_0_prioNum =
    (ipriosTmp_result_leftIprio_leftIprio_sel_1555
     & hsSortEn_6_0
       ? io_in_hsiprios[295:288]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1557
       & hsSortEn_6_1
         ? io_in_hsiprios[287:280]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1558
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_1559
            & hsSortEn_6_0
              ? io_in_hsiprios[295:288]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1561
              & hsSortEn_6_1
                ? io_in_hsiprios[287:280]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1565
              & hsSortEn_6_0
                ? io_in_hsiprios[295:288]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1570
                ? (ipriosTmp_result_leftIprio_leftIprio_sel_1578
                     ? hsipriosSort_48_prioNum
                     : hsipriosSort_49_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_leftIprio_14_0_isZero =
    ipriosTmp_result_leftIprio_leftIprio_sel_1555 & hsipriosSort_48_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1557 & hsipriosSort_49_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1558
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1559 & hsipriosSort_48_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1561 & hsipriosSort_49_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1565 & hsipriosSort_48_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1570
       & (ipriosTmp_result_leftIprio_leftIprio_sel_1578
            ? hsipriosSort_48_isZero
            : hsipriosSort_49_isZero));
  wire        ipriosTmp_result_leftIprio_leftIprio_14_0_enable =
    ipriosTmp_result_leftIprio_leftIprio_sel_1555
    & hsSortEn_6_0
    | ipriosTmp_result_leftIprio_leftIprio_sel_1557
    & hsSortEn_6_1
    | ipriosTmp_result_leftIprio_leftIprio_sel_1558
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1559
       & hsSortEn_6_0
       | ipriosTmp_result_leftIprio_leftIprio_sel_1561
       & hsSortEn_6_1
       | ipriosTmp_result_leftIprio_leftIprio_sel_1565
       & hsSortEn_6_0
       | ipriosTmp_result_leftIprio_leftIprio_sel_1570
       & (ipriosTmp_result_leftIprio_leftIprio_sel_1578
            ? hsSortEn_6_0
            : hsSortEn_6_1));
  wire [5:0]  ipriosTmp_result_leftIprio_leftIprio_14_0_idx =
    (ipriosTmp_result_leftIprio_leftIprio_sel_1555 ? 6'h30 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1557 ? 6'h31 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1558
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_1559 ? 6'h30 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1561 ? 6'h31 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1565 ? 6'h30 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1570
                ? {5'h18, ~ipriosTmp_result_leftIprio_leftIprio_sel_1578}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1555 =
    hsSortEn_6_2 & ~hsSortEn_6_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1557 =
    ~hsSortEn_6_2 & hsSortEn_6_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1558 =
    hsSortEn_6_2 & hsSortEn_6_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1559 =
    hsipriosSort_50_isZero & hsipriosSort_51_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1561 =
    hsipriosSort_50_isZero & ~hsipriosSort_51_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1565 =
    ~hsipriosSort_50_isZero & hsipriosSort_51_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1570 =
    ~hsipriosSort_50_isZero & ~hsipriosSort_51_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1578 =
    hsipriosSort_50_prioNum <= hsipriosSort_51_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_rightIprio_14_0_prioNum =
    (ipriosTmp_result_leftIprio_rightIprio_sel_1555
     & hsSortEn_6_2
       ? io_in_hsiprios[143:136]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1557
       & hsSortEn_6_3
         ? io_in_hsiprios[279:272]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1558
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_1559
            & hsSortEn_6_2
              ? io_in_hsiprios[143:136]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1561
              & hsSortEn_6_3
                ? io_in_hsiprios[279:272]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1565
              & hsSortEn_6_2
                ? io_in_hsiprios[143:136]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1570
                ? (ipriosTmp_result_leftIprio_rightIprio_sel_1578
                     ? hsipriosSort_50_prioNum
                     : hsipriosSort_51_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_14_0_isZero =
    ipriosTmp_result_leftIprio_rightIprio_sel_1555 & hsipriosSort_50_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1557 & hsipriosSort_51_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1558
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1559 & hsipriosSort_50_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1561 & hsipriosSort_51_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1565 & hsipriosSort_50_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1570
       & (ipriosTmp_result_leftIprio_rightIprio_sel_1578
            ? hsipriosSort_50_isZero
            : hsipriosSort_51_isZero));
  wire        ipriosTmp_result_leftIprio_rightIprio_14_0_enable =
    ipriosTmp_result_leftIprio_rightIprio_sel_1555
    & hsSortEn_6_2
    | ipriosTmp_result_leftIprio_rightIprio_sel_1557
    & hsSortEn_6_3
    | ipriosTmp_result_leftIprio_rightIprio_sel_1558
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1559
       & hsSortEn_6_2
       | ipriosTmp_result_leftIprio_rightIprio_sel_1561
       & hsSortEn_6_3
       | ipriosTmp_result_leftIprio_rightIprio_sel_1565
       & hsSortEn_6_2
       | ipriosTmp_result_leftIprio_rightIprio_sel_1570
       & (ipriosTmp_result_leftIprio_rightIprio_sel_1578
            ? hsSortEn_6_2
            : hsSortEn_6_3));
  wire [5:0]  ipriosTmp_result_leftIprio_rightIprio_14_0_idx =
    (ipriosTmp_result_leftIprio_rightIprio_sel_1555 ? 6'h32 : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1557 ? 6'h33 : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1558
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_1559 ? 6'h32 : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1561 ? 6'h33 : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1565 ? 6'h32 : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1570
                ? {5'h19, ~ipriosTmp_result_leftIprio_rightIprio_sel_1578}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_sel_1555 =
    ipriosTmp_result_leftIprio_leftIprio_14_0_enable
    & ~ipriosTmp_result_leftIprio_rightIprio_14_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1557 =
    ~ipriosTmp_result_leftIprio_leftIprio_14_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_14_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1558 =
    ipriosTmp_result_leftIprio_leftIprio_14_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_14_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1559 =
    ipriosTmp_result_leftIprio_leftIprio_14_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_14_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1561 =
    ipriosTmp_result_leftIprio_leftIprio_14_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_14_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1562 =
    ipriosTmp_result_leftIprio_leftIprio_14_0_idx < 6'h1C;
  wire        ipriosTmp_result_leftIprio_sel_1565 =
    ~ipriosTmp_result_leftIprio_leftIprio_14_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_14_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1566 =
    ipriosTmp_result_leftIprio_rightIprio_14_0_idx < 6'h1C;
  wire        ipriosTmp_result_leftIprio_sel_1570 =
    ~ipriosTmp_result_leftIprio_leftIprio_14_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_14_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1578 =
    ipriosTmp_result_leftIprio_leftIprio_14_0_prioNum <= ipriosTmp_result_leftIprio_rightIprio_14_0_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_14_0_prioNum =
    (ipriosTmp_result_leftIprio_sel_1555
       ? ipriosTmp_result_leftIprio_leftIprio_14_0_prioNum
       : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_1557
         ? ipriosTmp_result_leftIprio_rightIprio_14_0_prioNum
         : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_1558
         ? (ipriosTmp_result_leftIprio_sel_1559
              ? ipriosTmp_result_leftIprio_leftIprio_14_0_prioNum
              : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1561
                ? (ipriosTmp_result_leftIprio_sel_1562
                     ? ipriosTmp_result_leftIprio_leftIprio_14_0_prioNum
                     : ipriosTmp_result_leftIprio_rightIprio_14_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1565
                ? (ipriosTmp_result_leftIprio_sel_1566
                     ? ipriosTmp_result_leftIprio_rightIprio_14_0_prioNum
                     : ipriosTmp_result_leftIprio_leftIprio_14_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1570
                ? (ipriosTmp_result_leftIprio_sel_1578
                     ? ipriosTmp_result_leftIprio_leftIprio_14_0_prioNum
                     : ipriosTmp_result_leftIprio_rightIprio_14_0_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_14_0_isZero =
    ipriosTmp_result_leftIprio_sel_1555
    & ipriosTmp_result_leftIprio_leftIprio_14_0_isZero
    | ipriosTmp_result_leftIprio_sel_1557
    & ipriosTmp_result_leftIprio_rightIprio_14_0_isZero
    | ipriosTmp_result_leftIprio_sel_1558
    & (ipriosTmp_result_leftIprio_sel_1559
       & ipriosTmp_result_leftIprio_leftIprio_14_0_isZero
       | ipriosTmp_result_leftIprio_sel_1561
       & (ipriosTmp_result_leftIprio_sel_1562
            ? ipriosTmp_result_leftIprio_leftIprio_14_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_14_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1565
       & (ipriosTmp_result_leftIprio_sel_1566
            ? ipriosTmp_result_leftIprio_rightIprio_14_0_isZero
            : ipriosTmp_result_leftIprio_leftIprio_14_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1570
       & (ipriosTmp_result_leftIprio_sel_1578
            ? ipriosTmp_result_leftIprio_leftIprio_14_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_14_0_isZero));
  wire        ipriosTmp_result_leftIprio_14_0_enable =
    ipriosTmp_result_leftIprio_sel_1555
    & ipriosTmp_result_leftIprio_leftIprio_14_0_enable
    | ipriosTmp_result_leftIprio_sel_1557
    & ipriosTmp_result_leftIprio_rightIprio_14_0_enable
    | ipriosTmp_result_leftIprio_sel_1558
    & (ipriosTmp_result_leftIprio_sel_1559
       & ipriosTmp_result_leftIprio_leftIprio_14_0_enable
       | ipriosTmp_result_leftIprio_sel_1561
       & (ipriosTmp_result_leftIprio_sel_1562
            ? ipriosTmp_result_leftIprio_leftIprio_14_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_14_0_enable)
       | ipriosTmp_result_leftIprio_sel_1565
       & (ipriosTmp_result_leftIprio_sel_1566
            ? ipriosTmp_result_leftIprio_rightIprio_14_0_enable
            : ipriosTmp_result_leftIprio_leftIprio_14_0_enable)
       | ipriosTmp_result_leftIprio_sel_1570
       & (ipriosTmp_result_leftIprio_sel_1578
            ? ipriosTmp_result_leftIprio_leftIprio_14_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_14_0_enable));
  wire [5:0]  ipriosTmp_result_leftIprio_14_0_idx =
    (ipriosTmp_result_leftIprio_sel_1555
       ? ipriosTmp_result_leftIprio_leftIprio_14_0_idx
       : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1557
         ? ipriosTmp_result_leftIprio_rightIprio_14_0_idx
         : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1558
         ? (ipriosTmp_result_leftIprio_sel_1559
              ? ipriosTmp_result_leftIprio_leftIprio_14_0_idx
              : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1561
                ? (ipriosTmp_result_leftIprio_sel_1562
                     ? ipriosTmp_result_leftIprio_leftIprio_14_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_14_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1565
                ? (ipriosTmp_result_leftIprio_sel_1566
                     ? ipriosTmp_result_leftIprio_rightIprio_14_0_idx
                     : ipriosTmp_result_leftIprio_leftIprio_14_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1570
                ? (ipriosTmp_result_leftIprio_sel_1578
                     ? ipriosTmp_result_leftIprio_leftIprio_14_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_14_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1555 =
    hsSortEn_6_4 & ~hsSortEn_6_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1557 =
    ~hsSortEn_6_4 & hsSortEn_6_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1558 =
    hsSortEn_6_4 & hsSortEn_6_5;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1559 =
    hsipriosSort_52_isZero & hsipriosSort_53_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1561 =
    hsipriosSort_52_isZero & ~hsipriosSort_53_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1565 =
    ~hsipriosSort_52_isZero & hsipriosSort_53_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1570 =
    ~hsipriosSort_52_isZero & ~hsipriosSort_53_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1578 =
    hsipriosSort_52_prioNum <= hsipriosSort_53_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_leftIprio_14_0_prioNum =
    (ipriosTmp_result_rightIprio_leftIprio_sel_1555
     & hsSortEn_6_4
       ? io_in_hsiprios[271:264]
       : 8'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1557
       & hsSortEn_6_5
         ? io_in_hsiprios[135:128]
         : 8'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1558
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_1559
            & hsSortEn_6_4
              ? io_in_hsiprios[271:264]
              : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1561
              & hsSortEn_6_5
                ? io_in_hsiprios[135:128]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1565
              & hsSortEn_6_4
                ? io_in_hsiprios[271:264]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1570
                ? (ipriosTmp_result_rightIprio_leftIprio_sel_1578
                     ? hsipriosSort_52_prioNum
                     : hsipriosSort_53_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_14_0_isZero =
    ipriosTmp_result_rightIprio_leftIprio_sel_1555 & hsipriosSort_52_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1557 & hsipriosSort_53_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1558
    & (ipriosTmp_result_rightIprio_leftIprio_sel_1559 & hsipriosSort_52_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1561 & hsipriosSort_53_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1565 & hsipriosSort_52_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1570
       & (ipriosTmp_result_rightIprio_leftIprio_sel_1578
            ? hsipriosSort_52_isZero
            : hsipriosSort_53_isZero));
  wire        ipriosTmp_result_rightIprio_leftIprio_14_0_enable =
    ipriosTmp_result_rightIprio_leftIprio_sel_1555
    & hsSortEn_6_4
    | ipriosTmp_result_rightIprio_leftIprio_sel_1557
    & hsSortEn_6_5
    | ipriosTmp_result_rightIprio_leftIprio_sel_1558
    & (ipriosTmp_result_rightIprio_leftIprio_sel_1559
       & hsSortEn_6_4
       | ipriosTmp_result_rightIprio_leftIprio_sel_1561
       & hsSortEn_6_5
       | ipriosTmp_result_rightIprio_leftIprio_sel_1565
       & hsSortEn_6_4
       | ipriosTmp_result_rightIprio_leftIprio_sel_1570
       & (ipriosTmp_result_rightIprio_leftIprio_sel_1578
            ? hsSortEn_6_4
            : hsSortEn_6_5));
  wire [5:0]  ipriosTmp_result_rightIprio_leftIprio_14_0_idx =
    (ipriosTmp_result_rightIprio_leftIprio_sel_1555 ? 6'h34 : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1557 ? 6'h35 : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1558
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_1559 ? 6'h34 : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1561 ? 6'h35 : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1565 ? 6'h34 : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1570
                ? {5'h1A, ~ipriosTmp_result_rightIprio_leftIprio_sel_1578}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1555 =
    hsSortEn_6_6 & ~hsSortEn_6_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1557 =
    ~hsSortEn_6_6 & hsSortEn_6_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1558 =
    hsSortEn_6_6 & hsSortEn_6_7;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1559 =
    hsipriosSort_54_isZero & hsipriosSort_55_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1561 =
    hsipriosSort_54_isZero & ~hsipriosSort_55_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1565 =
    ~hsipriosSort_54_isZero & hsipriosSort_55_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1570 =
    ~hsipriosSort_54_isZero & ~hsipriosSort_55_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1578 =
    hsipriosSort_54_prioNum <= hsipriosSort_55_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_rightIprio_14_0_prioNum =
    (ipriosTmp_result_rightIprio_rightIprio_sel_1555
     & hsSortEn_6_6
       ? io_in_hsiprios[263:256]
       : 8'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1557
       & hsSortEn_6_7
         ? io_in_hsiprios[415:408]
         : 8'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1558
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_1559
            & hsSortEn_6_6
              ? io_in_hsiprios[263:256]
              : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1561
              & hsSortEn_6_7
                ? io_in_hsiprios[415:408]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1565
              & hsSortEn_6_6
                ? io_in_hsiprios[263:256]
                : 8'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1570
                ? (ipriosTmp_result_rightIprio_rightIprio_sel_1578
                     ? hsipriosSort_54_prioNum
                     : hsipriosSort_55_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_14_0_isZero =
    ipriosTmp_result_rightIprio_rightIprio_sel_1555 & hsipriosSort_54_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1557 & hsipriosSort_55_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1558
    & (ipriosTmp_result_rightIprio_rightIprio_sel_1559 & hsipriosSort_54_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1561 & hsipriosSort_55_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1565 & hsipriosSort_54_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1570
       & (ipriosTmp_result_rightIprio_rightIprio_sel_1578
            ? hsipriosSort_54_isZero
            : hsipriosSort_55_isZero));
  wire        ipriosTmp_result_rightIprio_rightIprio_14_0_enable =
    ipriosTmp_result_rightIprio_rightIprio_sel_1555
    & hsSortEn_6_6
    | ipriosTmp_result_rightIprio_rightIprio_sel_1557
    & hsSortEn_6_7
    | ipriosTmp_result_rightIprio_rightIprio_sel_1558
    & (ipriosTmp_result_rightIprio_rightIprio_sel_1559
       & hsSortEn_6_6
       | ipriosTmp_result_rightIprio_rightIprio_sel_1561
       & hsSortEn_6_7
       | ipriosTmp_result_rightIprio_rightIprio_sel_1565
       & hsSortEn_6_6
       | ipriosTmp_result_rightIprio_rightIprio_sel_1570
       & (ipriosTmp_result_rightIprio_rightIprio_sel_1578
            ? hsSortEn_6_6
            : hsSortEn_6_7));
  wire [5:0]  ipriosTmp_result_rightIprio_rightIprio_14_0_idx =
    (ipriosTmp_result_rightIprio_rightIprio_sel_1555 ? 6'h36 : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1557 ? 6'h37 : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1558
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_1559 ? 6'h36 : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1561 ? 6'h37 : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1565 ? 6'h36 : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1570
                ? {5'h1B, ~ipriosTmp_result_rightIprio_rightIprio_sel_1578}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_sel_1555 =
    ipriosTmp_result_rightIprio_leftIprio_14_0_enable
    & ~ipriosTmp_result_rightIprio_rightIprio_14_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1557 =
    ~ipriosTmp_result_rightIprio_leftIprio_14_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_14_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1558 =
    ipriosTmp_result_rightIprio_leftIprio_14_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_14_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1559 =
    ipriosTmp_result_rightIprio_leftIprio_14_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_14_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1561 =
    ipriosTmp_result_rightIprio_leftIprio_14_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_14_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1562 =
    ipriosTmp_result_rightIprio_leftIprio_14_0_idx < 6'h1C;
  wire        ipriosTmp_result_rightIprio_sel_1565 =
    ~ipriosTmp_result_rightIprio_leftIprio_14_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_14_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1566 =
    ipriosTmp_result_rightIprio_rightIprio_14_0_idx < 6'h1C;
  wire        ipriosTmp_result_rightIprio_sel_1570 =
    ~ipriosTmp_result_rightIprio_leftIprio_14_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_14_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1578 =
    ipriosTmp_result_rightIprio_leftIprio_14_0_prioNum <= ipriosTmp_result_rightIprio_rightIprio_14_0_prioNum;
  wire [7:0]  ipriosTmp_result_rightIprio_14_0_prioNum =
    (ipriosTmp_result_rightIprio_sel_1555
       ? ipriosTmp_result_rightIprio_leftIprio_14_0_prioNum
       : 8'h0)
    | (ipriosTmp_result_rightIprio_sel_1557
         ? ipriosTmp_result_rightIprio_rightIprio_14_0_prioNum
         : 8'h0)
    | (ipriosTmp_result_rightIprio_sel_1558
         ? (ipriosTmp_result_rightIprio_sel_1559
              ? ipriosTmp_result_rightIprio_leftIprio_14_0_prioNum
              : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1561
                ? (ipriosTmp_result_rightIprio_sel_1562
                     ? ipriosTmp_result_rightIprio_leftIprio_14_0_prioNum
                     : ipriosTmp_result_rightIprio_rightIprio_14_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1565
                ? (ipriosTmp_result_rightIprio_sel_1566
                     ? ipriosTmp_result_rightIprio_rightIprio_14_0_prioNum
                     : ipriosTmp_result_rightIprio_leftIprio_14_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_rightIprio_sel_1570
                ? (ipriosTmp_result_rightIprio_sel_1578
                     ? ipriosTmp_result_rightIprio_leftIprio_14_0_prioNum
                     : ipriosTmp_result_rightIprio_rightIprio_14_0_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_rightIprio_14_0_isZero =
    ipriosTmp_result_rightIprio_sel_1555
    & ipriosTmp_result_rightIprio_leftIprio_14_0_isZero
    | ipriosTmp_result_rightIprio_sel_1557
    & ipriosTmp_result_rightIprio_rightIprio_14_0_isZero
    | ipriosTmp_result_rightIprio_sel_1558
    & (ipriosTmp_result_rightIprio_sel_1559
       & ipriosTmp_result_rightIprio_leftIprio_14_0_isZero
       | ipriosTmp_result_rightIprio_sel_1561
       & (ipriosTmp_result_rightIprio_sel_1562
            ? ipriosTmp_result_rightIprio_leftIprio_14_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_14_0_isZero)
       | ipriosTmp_result_rightIprio_sel_1565
       & (ipriosTmp_result_rightIprio_sel_1566
            ? ipriosTmp_result_rightIprio_rightIprio_14_0_isZero
            : ipriosTmp_result_rightIprio_leftIprio_14_0_isZero)
       | ipriosTmp_result_rightIprio_sel_1570
       & (ipriosTmp_result_rightIprio_sel_1578
            ? ipriosTmp_result_rightIprio_leftIprio_14_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_14_0_isZero));
  wire        ipriosTmp_result_rightIprio_14_0_enable =
    ipriosTmp_result_rightIprio_sel_1555
    & ipriosTmp_result_rightIprio_leftIprio_14_0_enable
    | ipriosTmp_result_rightIprio_sel_1557
    & ipriosTmp_result_rightIprio_rightIprio_14_0_enable
    | ipriosTmp_result_rightIprio_sel_1558
    & (ipriosTmp_result_rightIprio_sel_1559
       & ipriosTmp_result_rightIprio_leftIprio_14_0_enable
       | ipriosTmp_result_rightIprio_sel_1561
       & (ipriosTmp_result_rightIprio_sel_1562
            ? ipriosTmp_result_rightIprio_leftIprio_14_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_14_0_enable)
       | ipriosTmp_result_rightIprio_sel_1565
       & (ipriosTmp_result_rightIprio_sel_1566
            ? ipriosTmp_result_rightIprio_rightIprio_14_0_enable
            : ipriosTmp_result_rightIprio_leftIprio_14_0_enable)
       | ipriosTmp_result_rightIprio_sel_1570
       & (ipriosTmp_result_rightIprio_sel_1578
            ? ipriosTmp_result_rightIprio_leftIprio_14_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_14_0_enable));
  wire [5:0]  ipriosTmp_result_rightIprio_14_0_idx =
    (ipriosTmp_result_rightIprio_sel_1555
       ? ipriosTmp_result_rightIprio_leftIprio_14_0_idx
       : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_1557
         ? ipriosTmp_result_rightIprio_rightIprio_14_0_idx
         : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_1558
         ? (ipriosTmp_result_rightIprio_sel_1559
              ? ipriosTmp_result_rightIprio_leftIprio_14_0_idx
              : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1561
                ? (ipriosTmp_result_rightIprio_sel_1562
                     ? ipriosTmp_result_rightIprio_leftIprio_14_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_14_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1565
                ? (ipriosTmp_result_rightIprio_sel_1566
                     ? ipriosTmp_result_rightIprio_rightIprio_14_0_idx
                     : ipriosTmp_result_rightIprio_leftIprio_14_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1570
                ? (ipriosTmp_result_rightIprio_sel_1578
                     ? ipriosTmp_result_rightIprio_leftIprio_14_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_14_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_sel_1555 =
    ipriosTmp_result_leftIprio_14_0_enable & ~ipriosTmp_result_rightIprio_14_0_enable;
  wire        ipriosTmp_result_sel_1557 =
    ~ipriosTmp_result_leftIprio_14_0_enable & ipriosTmp_result_rightIprio_14_0_enable;
  wire        ipriosTmp_result_sel_1558 =
    ipriosTmp_result_leftIprio_14_0_enable & ipriosTmp_result_rightIprio_14_0_enable;
  wire        ipriosTmp_result_sel_1559 =
    ipriosTmp_result_leftIprio_14_0_isZero & ipriosTmp_result_rightIprio_14_0_isZero;
  wire        ipriosTmp_result_sel_1561 =
    ipriosTmp_result_leftIprio_14_0_isZero & ~ipriosTmp_result_rightIprio_14_0_isZero;
  wire        ipriosTmp_result_sel_1562 =
    ipriosTmp_result_leftIprio_14_0_idx < 6'h1C;
  wire        ipriosTmp_result_sel_1565 =
    ~ipriosTmp_result_leftIprio_14_0_isZero & ipriosTmp_result_rightIprio_14_0_isZero;
  wire        ipriosTmp_result_sel_1566 =
    ipriosTmp_result_rightIprio_14_0_idx < 6'h1C;
  wire        ipriosTmp_result_sel_1570 =
    ~ipriosTmp_result_leftIprio_14_0_isZero & ~ipriosTmp_result_rightIprio_14_0_isZero;
  wire        ipriosTmp_result_sel_1578 =
    ipriosTmp_result_leftIprio_14_0_prioNum <= ipriosTmp_result_rightIprio_14_0_prioNum;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1666 =
    hsSortEn_7_0 & ~hsSortEn_7_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1668 =
    ~hsSortEn_7_0 & hsSortEn_7_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1669 =
    hsSortEn_7_0 & hsSortEn_7_1;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1670 =
    hsipriosSort_56_isZero & hsipriosSort_57_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1672 =
    hsipriosSort_56_isZero & ~hsipriosSort_57_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1676 =
    ~hsipriosSort_56_isZero & hsipriosSort_57_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1681 =
    ~hsipriosSort_56_isZero & ~hsipriosSort_57_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1689 =
    hsipriosSort_56_prioNum <= hsipriosSort_57_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_leftIprio_15_0_prioNum =
    (ipriosTmp_result_leftIprio_leftIprio_sel_1666
     & hsSortEn_7_0
       ? io_in_hsiprios[207:200]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1668
       & hsSortEn_7_1
         ? io_in_hsiprios[407:400]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1669
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_1670
            & hsSortEn_7_0
              ? io_in_hsiprios[207:200]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1672
              & hsSortEn_7_1
                ? io_in_hsiprios[407:400]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1676
              & hsSortEn_7_0
                ? io_in_hsiprios[207:200]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1681
                ? (ipriosTmp_result_leftIprio_leftIprio_sel_1689
                     ? hsipriosSort_56_prioNum
                     : hsipriosSort_57_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_leftIprio_15_0_isZero =
    ipriosTmp_result_leftIprio_leftIprio_sel_1666 & hsipriosSort_56_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1668 & hsipriosSort_57_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1669
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1670 & hsipriosSort_56_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1672 & hsipriosSort_57_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1676 & hsipriosSort_56_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1681
       & (ipriosTmp_result_leftIprio_leftIprio_sel_1689
            ? hsipriosSort_56_isZero
            : hsipriosSort_57_isZero));
  wire        ipriosTmp_result_leftIprio_leftIprio_15_0_enable =
    ipriosTmp_result_leftIprio_leftIprio_sel_1666
    & hsSortEn_7_0
    | ipriosTmp_result_leftIprio_leftIprio_sel_1668
    & hsSortEn_7_1
    | ipriosTmp_result_leftIprio_leftIprio_sel_1669
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1670
       & hsSortEn_7_0
       | ipriosTmp_result_leftIprio_leftIprio_sel_1672
       & hsSortEn_7_1
       | ipriosTmp_result_leftIprio_leftIprio_sel_1676
       & hsSortEn_7_0
       | ipriosTmp_result_leftIprio_leftIprio_sel_1681
       & (ipriosTmp_result_leftIprio_leftIprio_sel_1689
            ? hsSortEn_7_0
            : hsSortEn_7_1));
  wire [5:0]  ipriosTmp_result_leftIprio_leftIprio_15_0_idx =
    (ipriosTmp_result_leftIprio_leftIprio_sel_1666 ? 6'h38 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1668 ? 6'h39 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1669
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_1670 ? 6'h38 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1672 ? 6'h39 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1676 ? 6'h38 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_1681
                ? {5'h1C, ~ipriosTmp_result_leftIprio_leftIprio_sel_1689}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1666 =
    hsSortEn_7_2 & ~hsSortEn_7_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1668 =
    ~hsSortEn_7_2 & hsSortEn_7_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1669 =
    hsSortEn_7_2 & hsSortEn_7_3;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1670 =
    hsipriosSort_58_isZero & hsipriosSort_59_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1672 =
    hsipriosSort_58_isZero & ~hsipriosSort_59_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1676 =
    ~hsipriosSort_58_isZero & hsipriosSort_59_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1681 =
    ~hsipriosSort_58_isZero & ~hsipriosSort_59_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1689 =
    hsipriosSort_58_prioNum <= hsipriosSort_59_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_rightIprio_15_0_prioNum =
    (ipriosTmp_result_leftIprio_rightIprio_sel_1666
     & hsSortEn_7_2
       ? io_in_hsiprios[399:392]
       : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1668
       & hsSortEn_7_3
         ? io_in_hsiprios[199:192]
         : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1669
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_1670
            & hsSortEn_7_2
              ? io_in_hsiprios[399:392]
              : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1672
              & hsSortEn_7_3
                ? io_in_hsiprios[199:192]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1676
              & hsSortEn_7_2
                ? io_in_hsiprios[399:392]
                : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1681
                ? (ipriosTmp_result_leftIprio_rightIprio_sel_1689
                     ? hsipriosSort_58_prioNum
                     : hsipriosSort_59_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_15_0_isZero =
    ipriosTmp_result_leftIprio_rightIprio_sel_1666 & hsipriosSort_58_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1668 & hsipriosSort_59_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1669
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1670 & hsipriosSort_58_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1672 & hsipriosSort_59_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1676 & hsipriosSort_58_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1681
       & (ipriosTmp_result_leftIprio_rightIprio_sel_1689
            ? hsipriosSort_58_isZero
            : hsipriosSort_59_isZero));
  wire        ipriosTmp_result_leftIprio_rightIprio_15_0_enable =
    ipriosTmp_result_leftIprio_rightIprio_sel_1666
    & hsSortEn_7_2
    | ipriosTmp_result_leftIprio_rightIprio_sel_1668
    & hsSortEn_7_3
    | ipriosTmp_result_leftIprio_rightIprio_sel_1669
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1670
       & hsSortEn_7_2
       | ipriosTmp_result_leftIprio_rightIprio_sel_1672
       & hsSortEn_7_3
       | ipriosTmp_result_leftIprio_rightIprio_sel_1676
       & hsSortEn_7_2
       | ipriosTmp_result_leftIprio_rightIprio_sel_1681
       & (ipriosTmp_result_leftIprio_rightIprio_sel_1689
            ? hsSortEn_7_2
            : hsSortEn_7_3));
  wire [5:0]  ipriosTmp_result_leftIprio_rightIprio_15_0_idx =
    (ipriosTmp_result_leftIprio_rightIprio_sel_1666 ? 6'h3A : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1668 ? 6'h3B : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1669
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_1670 ? 6'h3A : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1672 ? 6'h3B : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1676 ? 6'h3A : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1681
                ? {5'h1D, ~ipriosTmp_result_leftIprio_rightIprio_sel_1689}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_sel_1666 =
    ipriosTmp_result_leftIprio_leftIprio_15_0_enable
    & ~ipriosTmp_result_leftIprio_rightIprio_15_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1668 =
    ~ipriosTmp_result_leftIprio_leftIprio_15_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_15_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1669 =
    ipriosTmp_result_leftIprio_leftIprio_15_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_15_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1670 =
    ipriosTmp_result_leftIprio_leftIprio_15_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_15_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1672 =
    ipriosTmp_result_leftIprio_leftIprio_15_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_15_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1673 =
    ipriosTmp_result_leftIprio_leftIprio_15_0_idx < 6'h1C;
  wire        ipriosTmp_result_leftIprio_sel_1676 =
    ~ipriosTmp_result_leftIprio_leftIprio_15_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_15_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1677 =
    ipriosTmp_result_leftIprio_rightIprio_15_0_idx < 6'h1C;
  wire        ipriosTmp_result_leftIprio_sel_1681 =
    ~ipriosTmp_result_leftIprio_leftIprio_15_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_15_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1689 =
    ipriosTmp_result_leftIprio_leftIprio_15_0_prioNum <= ipriosTmp_result_leftIprio_rightIprio_15_0_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_15_0_prioNum =
    (ipriosTmp_result_leftIprio_sel_1666
       ? ipriosTmp_result_leftIprio_leftIprio_15_0_prioNum
       : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_1668
         ? ipriosTmp_result_leftIprio_rightIprio_15_0_prioNum
         : 8'h0)
    | (ipriosTmp_result_leftIprio_sel_1669
         ? (ipriosTmp_result_leftIprio_sel_1670
              ? ipriosTmp_result_leftIprio_leftIprio_15_0_prioNum
              : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1672
                ? (ipriosTmp_result_leftIprio_sel_1673
                     ? ipriosTmp_result_leftIprio_leftIprio_15_0_prioNum
                     : ipriosTmp_result_leftIprio_rightIprio_15_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1676
                ? (ipriosTmp_result_leftIprio_sel_1677
                     ? ipriosTmp_result_leftIprio_rightIprio_15_0_prioNum
                     : ipriosTmp_result_leftIprio_leftIprio_15_0_prioNum)
                : 8'h0)
           | (ipriosTmp_result_leftIprio_sel_1681
                ? (ipriosTmp_result_leftIprio_sel_1689
                     ? ipriosTmp_result_leftIprio_leftIprio_15_0_prioNum
                     : ipriosTmp_result_leftIprio_rightIprio_15_0_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_15_0_isZero =
    ipriosTmp_result_leftIprio_sel_1666
    & ipriosTmp_result_leftIprio_leftIprio_15_0_isZero
    | ipriosTmp_result_leftIprio_sel_1668
    & ipriosTmp_result_leftIprio_rightIprio_15_0_isZero
    | ipriosTmp_result_leftIprio_sel_1669
    & (ipriosTmp_result_leftIprio_sel_1670
       & ipriosTmp_result_leftIprio_leftIprio_15_0_isZero
       | ipriosTmp_result_leftIprio_sel_1672
       & (ipriosTmp_result_leftIprio_sel_1673
            ? ipriosTmp_result_leftIprio_leftIprio_15_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_15_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1676
       & (ipriosTmp_result_leftIprio_sel_1677
            ? ipriosTmp_result_leftIprio_rightIprio_15_0_isZero
            : ipriosTmp_result_leftIprio_leftIprio_15_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1681
       & (ipriosTmp_result_leftIprio_sel_1689
            ? ipriosTmp_result_leftIprio_leftIprio_15_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_15_0_isZero));
  wire        ipriosTmp_result_leftIprio_15_0_enable =
    ipriosTmp_result_leftIprio_sel_1666
    & ipriosTmp_result_leftIprio_leftIprio_15_0_enable
    | ipriosTmp_result_leftIprio_sel_1668
    & ipriosTmp_result_leftIprio_rightIprio_15_0_enable
    | ipriosTmp_result_leftIprio_sel_1669
    & (ipriosTmp_result_leftIprio_sel_1670
       & ipriosTmp_result_leftIprio_leftIprio_15_0_enable
       | ipriosTmp_result_leftIprio_sel_1672
       & (ipriosTmp_result_leftIprio_sel_1673
            ? ipriosTmp_result_leftIprio_leftIprio_15_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_15_0_enable)
       | ipriosTmp_result_leftIprio_sel_1676
       & (ipriosTmp_result_leftIprio_sel_1677
            ? ipriosTmp_result_leftIprio_rightIprio_15_0_enable
            : ipriosTmp_result_leftIprio_leftIprio_15_0_enable)
       | ipriosTmp_result_leftIprio_sel_1681
       & (ipriosTmp_result_leftIprio_sel_1689
            ? ipriosTmp_result_leftIprio_leftIprio_15_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_15_0_enable));
  wire [5:0]  ipriosTmp_result_leftIprio_15_0_idx =
    (ipriosTmp_result_leftIprio_sel_1666
       ? ipriosTmp_result_leftIprio_leftIprio_15_0_idx
       : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1668
         ? ipriosTmp_result_leftIprio_rightIprio_15_0_idx
         : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1669
         ? (ipriosTmp_result_leftIprio_sel_1670
              ? ipriosTmp_result_leftIprio_leftIprio_15_0_idx
              : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1672
                ? (ipriosTmp_result_leftIprio_sel_1673
                     ? ipriosTmp_result_leftIprio_leftIprio_15_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_15_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1676
                ? (ipriosTmp_result_leftIprio_sel_1677
                     ? ipriosTmp_result_leftIprio_rightIprio_15_0_idx
                     : ipriosTmp_result_leftIprio_leftIprio_15_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1681
                ? (ipriosTmp_result_leftIprio_sel_1689
                     ? ipriosTmp_result_leftIprio_leftIprio_15_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_15_0_idx)
                : 6'h0)
         : 6'h0);
  wire [7:0]  ipriosTmp_result_rightIprio_15_0_prioNum =
    ipriosTmp_result_rightIprio_15_0_enable ? io_in_hsiprios[391:384] : 8'h0;
  wire        ipriosTmp_result_rightIprio_15_0_isZero =
    ipriosTmp_result_rightIprio_15_0_enable & io_in_hsiprios[391:384] == 8'h0;
  wire [5:0]  ipriosTmp_result_rightIprio_15_0_idx =
    ipriosTmp_result_rightIprio_15_0_enable ? 6'h3C : 6'h0;
  wire        ipriosTmp_result_sel_1666 =
    ipriosTmp_result_leftIprio_15_0_enable & ~ipriosTmp_result_rightIprio_15_0_enable;
  wire        ipriosTmp_result_sel_1668 =
    ~ipriosTmp_result_leftIprio_15_0_enable & ipriosTmp_result_rightIprio_15_0_enable;
  wire        ipriosTmp_result_sel_1669 =
    ipriosTmp_result_leftIprio_15_0_enable & ipriosTmp_result_rightIprio_15_0_enable;
  wire        ipriosTmp_result_sel_1670 =
    ipriosTmp_result_leftIprio_15_0_isZero & ipriosTmp_result_rightIprio_15_0_isZero;
  wire        ipriosTmp_result_sel_1672 =
    ipriosTmp_result_leftIprio_15_0_isZero & ~ipriosTmp_result_rightIprio_15_0_isZero;
  wire        ipriosTmp_result_sel_1673 =
    ipriosTmp_result_leftIprio_15_0_idx < 6'h1C;
  wire        ipriosTmp_result_sel_1676 =
    ~ipriosTmp_result_leftIprio_15_0_isZero & ipriosTmp_result_rightIprio_15_0_isZero;
  wire        ipriosTmp_result_sel_1677 =
    ipriosTmp_result_rightIprio_15_0_idx < 6'h1C;
  wire        ipriosTmp_result_sel_1681 =
    ~ipriosTmp_result_leftIprio_15_0_isZero & ~ipriosTmp_result_rightIprio_15_0_isZero;
  wire        ipriosTmp_result_sel_1689 =
    ipriosTmp_result_leftIprio_15_0_prioNum <= ipriosTmp_result_rightIprio_15_0_prioNum;
  wire        gGen_24 =
    ipriosTmp_result_sel_1668 & ipriosTmp_result_rightIprio_15_0_enable;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1777 =
    hvipriosSort_0_isZero & ~hvipriosSort_1_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1779 =
    ~hvipriosSort_0_isZero & hvipriosSort_1_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1780 =
    hvipriosSort_0_isZero & hvipriosSort_1_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1781 =
    hvipriosSort_0_isZero & hvipriosSort_1_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1783 =
    hvipriosSort_0_isZero & ~hvipriosSort_1_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1787 =
    ~hvipriosSort_0_isZero & hvipriosSort_1_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1792 =
    ~hvipriosSort_0_isZero & ~hvipriosSort_1_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_16_0_isZero =
    ipriosTmp_result_leftIprio_leftIprio_sel_1777 & hvipriosSort_0_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1779 & hvipriosSort_1_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1780
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1781 & hvipriosSort_0_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1783 & hvipriosSort_0_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1787 & hvipriosSort_1_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1792 & hvipriosSort_0_isZero);
  wire        ipriosTmp_result_leftIprio_leftIprio_16_0_enable =
    ipriosTmp_result_leftIprio_leftIprio_sel_1777 & hvipriosSort_0_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1779 & hvipriosSort_1_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1780
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1781 & hvipriosSort_0_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1783 & hvipriosSort_0_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1787 & hvipriosSort_1_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1792 & hvipriosSort_0_isZero);
  wire [5:0]  ipriosTmp_result_leftIprio_leftIprio_16_0_idx =
    {5'h0, ipriosTmp_result_leftIprio_leftIprio_sel_1779}
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1780
         ? {5'h0, ipriosTmp_result_leftIprio_leftIprio_sel_1787}
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1777 =
    hvipriosSort_2_isZero & ~hvipriosSort_3_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1779 =
    ~hvipriosSort_2_isZero & hvipriosSort_3_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1780 =
    hvipriosSort_2_isZero & hvipriosSort_3_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1781 =
    hvipriosSort_2_isZero & hvipriosSort_3_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1783 =
    hvipriosSort_2_isZero & ~hvipriosSort_3_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1787 =
    ~hvipriosSort_2_isZero & hvipriosSort_3_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1792 =
    ~hvipriosSort_2_isZero & ~hvipriosSort_3_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_16_0_isZero =
    ipriosTmp_result_leftIprio_rightIprio_sel_1777 & hvipriosSort_2_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1779 & hvipriosSort_3_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1780
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1781 & hvipriosSort_2_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1783 & hvipriosSort_2_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1787 & hvipriosSort_3_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1792 & hvipriosSort_2_isZero);
  wire        ipriosTmp_result_leftIprio_rightIprio_16_0_enable =
    ipriosTmp_result_leftIprio_rightIprio_sel_1777 & hvipriosSort_2_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1779 & hvipriosSort_3_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1780
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1781 & hvipriosSort_2_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1783 & hvipriosSort_2_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1787 & hvipriosSort_3_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1792 & hvipriosSort_2_isZero);
  wire [5:0]  ipriosTmp_result_leftIprio_rightIprio_16_0_idx =
    {4'h0, ipriosTmp_result_leftIprio_rightIprio_sel_1777, 1'h0}
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1779 ? 6'h3 : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1780
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_1787 ? 6'h3 : 6'h0)
           | {4'h0,
              ipriosTmp_result_leftIprio_rightIprio_sel_1781
                | ipriosTmp_result_leftIprio_rightIprio_sel_1783
                | ipriosTmp_result_leftIprio_rightIprio_sel_1792,
              1'h0}
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_sel_1777 =
    ipriosTmp_result_leftIprio_leftIprio_16_0_enable
    & ~ipriosTmp_result_leftIprio_rightIprio_16_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1779 =
    ~ipriosTmp_result_leftIprio_leftIprio_16_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_16_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1780 =
    ipriosTmp_result_leftIprio_leftIprio_16_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_16_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1781 =
    ipriosTmp_result_leftIprio_leftIprio_16_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_16_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1783 =
    ipriosTmp_result_leftIprio_leftIprio_16_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_16_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1787 =
    ~ipriosTmp_result_leftIprio_leftIprio_16_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_16_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1792 =
    ~ipriosTmp_result_leftIprio_leftIprio_16_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_16_0_isZero;
  wire        ipriosTmp_result_leftIprio_16_0_isZero =
    ipriosTmp_result_leftIprio_sel_1777
    & ipriosTmp_result_leftIprio_leftIprio_16_0_isZero
    | ipriosTmp_result_leftIprio_sel_1779
    & ipriosTmp_result_leftIprio_rightIprio_16_0_isZero
    | ipriosTmp_result_leftIprio_sel_1780
    & (ipriosTmp_result_leftIprio_sel_1781
       & ipriosTmp_result_leftIprio_leftIprio_16_0_isZero
       | ipriosTmp_result_leftIprio_sel_1783
       & (ipriosTmp_result_leftIprio_leftIprio_16_0_idx[5]
            ? ipriosTmp_result_leftIprio_rightIprio_16_0_isZero
            : ipriosTmp_result_leftIprio_leftIprio_16_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1787
       & (ipriosTmp_result_leftIprio_rightIprio_16_0_idx[5]
            ? ipriosTmp_result_leftIprio_leftIprio_16_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_16_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1792
       & ipriosTmp_result_leftIprio_leftIprio_16_0_isZero);
  wire        ipriosTmp_result_leftIprio_16_0_enable =
    ipriosTmp_result_leftIprio_sel_1777
    & ipriosTmp_result_leftIprio_leftIprio_16_0_enable
    | ipriosTmp_result_leftIprio_sel_1779
    & ipriosTmp_result_leftIprio_rightIprio_16_0_enable
    | ipriosTmp_result_leftIprio_sel_1780
    & (ipriosTmp_result_leftIprio_sel_1781
       & ipriosTmp_result_leftIprio_leftIprio_16_0_enable
       | ipriosTmp_result_leftIprio_sel_1783
       & (ipriosTmp_result_leftIprio_leftIprio_16_0_idx[5]
            ? ipriosTmp_result_leftIprio_rightIprio_16_0_enable
            : ipriosTmp_result_leftIprio_leftIprio_16_0_enable)
       | ipriosTmp_result_leftIprio_sel_1787
       & (ipriosTmp_result_leftIprio_rightIprio_16_0_idx[5]
            ? ipriosTmp_result_leftIprio_leftIprio_16_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_16_0_enable)
       | ipriosTmp_result_leftIprio_sel_1792
       & ipriosTmp_result_leftIprio_leftIprio_16_0_enable);
  wire [5:0]  ipriosTmp_result_leftIprio_16_0_idx =
    (ipriosTmp_result_leftIprio_sel_1777
       ? ipriosTmp_result_leftIprio_leftIprio_16_0_idx
       : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1779
         ? ipriosTmp_result_leftIprio_rightIprio_16_0_idx
         : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1780
         ? (ipriosTmp_result_leftIprio_sel_1781
              ? ipriosTmp_result_leftIprio_leftIprio_16_0_idx
              : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1783
                ? (ipriosTmp_result_leftIprio_leftIprio_16_0_idx[5]
                     ? ipriosTmp_result_leftIprio_rightIprio_16_0_idx
                     : ipriosTmp_result_leftIprio_leftIprio_16_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1787
                ? (ipriosTmp_result_leftIprio_rightIprio_16_0_idx[5]
                     ? ipriosTmp_result_leftIprio_leftIprio_16_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_16_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1792
                ? ipriosTmp_result_leftIprio_leftIprio_16_0_idx
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1777 =
    hvipriosSort_4_isZero & ~hvipriosSort_5_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1779 =
    ~hvipriosSort_4_isZero & hvipriosSort_5_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1780 =
    hvipriosSort_4_isZero & hvipriosSort_5_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1781 =
    hvipriosSort_4_isZero & hvipriosSort_5_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1783 =
    hvipriosSort_4_isZero & ~hvipriosSort_5_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1787 =
    ~hvipriosSort_4_isZero & hvipriosSort_5_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1792 =
    ~hvipriosSort_4_isZero & ~hvipriosSort_5_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_16_0_isZero =
    ipriosTmp_result_rightIprio_leftIprio_sel_1777 & hvipriosSort_4_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1779 & hvipriosSort_5_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1780
    & (ipriosTmp_result_rightIprio_leftIprio_sel_1781 & hvipriosSort_4_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1783 & hvipriosSort_4_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1787 & hvipriosSort_5_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1792 & hvipriosSort_4_isZero);
  wire        ipriosTmp_result_rightIprio_leftIprio_16_0_enable =
    ipriosTmp_result_rightIprio_leftIprio_sel_1777 & hvipriosSort_4_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1779 & hvipriosSort_5_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1780
    & (ipriosTmp_result_rightIprio_leftIprio_sel_1781 & hvipriosSort_4_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1783 & hvipriosSort_4_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1787 & hvipriosSort_5_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1792 & hvipriosSort_4_isZero);
  wire [5:0]  ipriosTmp_result_rightIprio_leftIprio_16_0_idx =
    {3'h0, ipriosTmp_result_rightIprio_leftIprio_sel_1777, 2'h0}
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1779 ? 6'h5 : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1780
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_1787 ? 6'h5 : 6'h0)
           | {3'h0,
              ipriosTmp_result_rightIprio_leftIprio_sel_1781
                | ipriosTmp_result_rightIprio_leftIprio_sel_1783
                | ipriosTmp_result_rightIprio_leftIprio_sel_1792,
              2'h0}
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1777 =
    hvipriosSort_6_isZero & ~hvipriosSort_7_enable;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1779 =
    ~hvipriosSort_6_isZero & hvipriosSort_7_enable;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1780 =
    hvipriosSort_6_isZero & hvipriosSort_7_enable;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1781 =
    hvipriosSort_6_isZero & hvipriosSort_7_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1783 =
    hvipriosSort_6_isZero & ~hvipriosSort_7_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1787 =
    ~hvipriosSort_6_isZero & hvipriosSort_7_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1792 =
    ~hvipriosSort_6_isZero & ~hvipriosSort_7_isZero;
  wire        gGen_25 =
    ipriosTmp_result_rightIprio_rightIprio_sel_1779 & hvipriosSort_7_enable
    | ipriosTmp_result_rightIprio_rightIprio_sel_1780
    & ipriosTmp_result_rightIprio_rightIprio_sel_1787 & hvipriosSort_7_enable;
  wire        ipriosTmp_result_rightIprio_rightIprio_16_0_isZero =
    ipriosTmp_result_rightIprio_rightIprio_sel_1777 & hvipriosSort_6_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1779 & hvipriosSort_7_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1780
    & (ipriosTmp_result_rightIprio_rightIprio_sel_1781 & hvipriosSort_6_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1783 & hvipriosSort_6_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1787 & hvipriosSort_7_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1792 & hvipriosSort_6_isZero);
  wire        ipriosTmp_result_rightIprio_rightIprio_16_0_enable =
    ipriosTmp_result_rightIprio_rightIprio_sel_1777 & hvipriosSort_6_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1779 & hvipriosSort_7_enable
    | ipriosTmp_result_rightIprio_rightIprio_sel_1780
    & (ipriosTmp_result_rightIprio_rightIprio_sel_1781 & hvipriosSort_6_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1783 & hvipriosSort_6_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1787 & hvipriosSort_7_enable
       | ipriosTmp_result_rightIprio_rightIprio_sel_1792 & hvipriosSort_6_isZero);
  wire [5:0]  ipriosTmp_result_rightIprio_rightIprio_16_0_idx =
    (ipriosTmp_result_rightIprio_rightIprio_sel_1777 ? 6'h6 : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1779 ? 6'h7 : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1780
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_1781
            | ipriosTmp_result_rightIprio_rightIprio_sel_1783
              ? 6'h6
              : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1787 ? 6'h7 : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1792 ? 6'h6 : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_sel_1777 =
    ipriosTmp_result_rightIprio_leftIprio_16_0_enable
    & ~ipriosTmp_result_rightIprio_rightIprio_16_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1779 =
    ~ipriosTmp_result_rightIprio_leftIprio_16_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_16_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1780 =
    ipriosTmp_result_rightIprio_leftIprio_16_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_16_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1781 =
    ipriosTmp_result_rightIprio_leftIprio_16_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_16_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1783 =
    ipriosTmp_result_rightIprio_leftIprio_16_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_16_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1787 =
    ~ipriosTmp_result_rightIprio_leftIprio_16_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_16_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1792 =
    ~ipriosTmp_result_rightIprio_leftIprio_16_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_16_0_isZero;
  wire        gGen_26 =
    ipriosTmp_result_rightIprio_sel_1779 & gGen_25
    | ipriosTmp_result_rightIprio_sel_1780
    & (ipriosTmp_result_rightIprio_sel_1783
       & ipriosTmp_result_rightIprio_leftIprio_16_0_idx[5] & gGen_25
       | ipriosTmp_result_rightIprio_sel_1787
       & ~(ipriosTmp_result_rightIprio_rightIprio_16_0_idx[5]) & gGen_25);
  wire        ipriosTmp_result_rightIprio_16_0_isZero =
    ipriosTmp_result_rightIprio_sel_1777
    & ipriosTmp_result_rightIprio_leftIprio_16_0_isZero
    | ipriosTmp_result_rightIprio_sel_1779
    & ipriosTmp_result_rightIprio_rightIprio_16_0_isZero
    | ipriosTmp_result_rightIprio_sel_1780
    & (ipriosTmp_result_rightIprio_sel_1781
       & ipriosTmp_result_rightIprio_leftIprio_16_0_isZero
       | ipriosTmp_result_rightIprio_sel_1783
       & (ipriosTmp_result_rightIprio_leftIprio_16_0_idx[5]
            ? ipriosTmp_result_rightIprio_rightIprio_16_0_isZero
            : ipriosTmp_result_rightIprio_leftIprio_16_0_isZero)
       | ipriosTmp_result_rightIprio_sel_1787
       & (ipriosTmp_result_rightIprio_rightIprio_16_0_idx[5]
            ? ipriosTmp_result_rightIprio_leftIprio_16_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_16_0_isZero)
       | ipriosTmp_result_rightIprio_sel_1792
       & ipriosTmp_result_rightIprio_leftIprio_16_0_isZero);
  wire        ipriosTmp_result_rightIprio_16_0_enable =
    ipriosTmp_result_rightIprio_sel_1777
    & ipriosTmp_result_rightIprio_leftIprio_16_0_enable
    | ipriosTmp_result_rightIprio_sel_1779
    & ipriosTmp_result_rightIprio_rightIprio_16_0_enable
    | ipriosTmp_result_rightIprio_sel_1780
    & (ipriosTmp_result_rightIprio_sel_1781
       & ipriosTmp_result_rightIprio_leftIprio_16_0_enable
       | ipriosTmp_result_rightIprio_sel_1783
       & (ipriosTmp_result_rightIprio_leftIprio_16_0_idx[5]
            ? ipriosTmp_result_rightIprio_rightIprio_16_0_enable
            : ipriosTmp_result_rightIprio_leftIprio_16_0_enable)
       | ipriosTmp_result_rightIprio_sel_1787
       & (ipriosTmp_result_rightIprio_rightIprio_16_0_idx[5]
            ? ipriosTmp_result_rightIprio_leftIprio_16_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_16_0_enable)
       | ipriosTmp_result_rightIprio_sel_1792
       & ipriosTmp_result_rightIprio_leftIprio_16_0_enable);
  wire [5:0]  ipriosTmp_result_rightIprio_16_0_idx =
    (ipriosTmp_result_rightIprio_sel_1777
       ? ipriosTmp_result_rightIprio_leftIprio_16_0_idx
       : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_1779
         ? ipriosTmp_result_rightIprio_rightIprio_16_0_idx
         : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_1780
         ? (ipriosTmp_result_rightIprio_sel_1781
              ? ipriosTmp_result_rightIprio_leftIprio_16_0_idx
              : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1783
                ? (ipriosTmp_result_rightIprio_leftIprio_16_0_idx[5]
                     ? ipriosTmp_result_rightIprio_rightIprio_16_0_idx
                     : ipriosTmp_result_rightIprio_leftIprio_16_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1787
                ? (ipriosTmp_result_rightIprio_rightIprio_16_0_idx[5]
                     ? ipriosTmp_result_rightIprio_leftIprio_16_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_16_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1792
                ? ipriosTmp_result_rightIprio_leftIprio_16_0_idx
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_sel_1777 =
    ipriosTmp_result_leftIprio_16_0_enable & ~ipriosTmp_result_rightIprio_16_0_enable;
  wire        ipriosTmp_result_sel_1779 =
    ~ipriosTmp_result_leftIprio_16_0_enable & ipriosTmp_result_rightIprio_16_0_enable;
  wire        ipriosTmp_result_sel_1780 =
    ipriosTmp_result_leftIprio_16_0_enable & ipriosTmp_result_rightIprio_16_0_enable;
  wire        ipriosTmp_result_sel_1781 =
    ipriosTmp_result_leftIprio_16_0_isZero & ipriosTmp_result_rightIprio_16_0_isZero;
  wire        ipriosTmp_result_sel_1783 =
    ipriosTmp_result_leftIprio_16_0_isZero & ~ipriosTmp_result_rightIprio_16_0_isZero;
  wire        ipriosTmp_result_sel_1787 =
    ~ipriosTmp_result_leftIprio_16_0_isZero & ipriosTmp_result_rightIprio_16_0_isZero;
  wire        ipriosTmp_result_sel_1792 =
    ~ipriosTmp_result_leftIprio_16_0_isZero & ~ipriosTmp_result_rightIprio_16_0_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1888 =
    hvipriosSort_8_isZero & ~hvipriosSort_9_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1890 =
    ~hvipriosSort_8_isZero & hvipriosSort_9_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1891 =
    hvipriosSort_8_isZero & hvipriosSort_9_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1892 =
    hvipriosSort_8_isZero & hvipriosSort_9_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1894 =
    hvipriosSort_8_isZero & ~hvipriosSort_9_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1898 =
    ~hvipriosSort_8_isZero & hvipriosSort_9_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1903 =
    ~hvipriosSort_8_isZero & ~hvipriosSort_9_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_17_0_isZero =
    ipriosTmp_result_leftIprio_leftIprio_sel_1888 & hvipriosSort_8_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1890 & hvipriosSort_9_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1891
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1892 & hvipriosSort_8_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1894 & hvipriosSort_8_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1898 & hvipriosSort_9_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1903 & hvipriosSort_8_isZero);
  wire        ipriosTmp_result_leftIprio_leftIprio_17_0_enable =
    ipriosTmp_result_leftIprio_leftIprio_sel_1888 & hvipriosSort_8_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1890 & hvipriosSort_9_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_1891
    & (ipriosTmp_result_leftIprio_leftIprio_sel_1892 & hvipriosSort_8_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1894 & hvipriosSort_8_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1898 & hvipriosSort_9_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_1903 & hvipriosSort_8_isZero);
  wire [5:0]  ipriosTmp_result_leftIprio_leftIprio_17_0_idx =
    {2'h0, ipriosTmp_result_leftIprio_leftIprio_sel_1888, 3'h0}
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1890 ? 6'h9 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_1891
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_1898 ? 6'h9 : 6'h0)
           | {2'h0,
              ipriosTmp_result_leftIprio_leftIprio_sel_1892
                | ipriosTmp_result_leftIprio_leftIprio_sel_1894
                | ipriosTmp_result_leftIprio_leftIprio_sel_1903,
              3'h0}
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1888 =
    hvipriosSort_10_enable & ~hvipriosSort_11_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1890 =
    ~hvipriosSort_10_enable & hvipriosSort_11_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1891 =
    hvipriosSort_10_enable & hvipriosSort_11_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1892 =
    hvipriosSort_10_isZero & hvipriosSort_11_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1894 =
    hvipriosSort_10_isZero & ~hvipriosSort_11_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1898 =
    ~hvipriosSort_10_isZero & hvipriosSort_11_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1903 =
    ~hvipriosSort_10_isZero & ~hvipriosSort_11_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1911 =
    (hvipriosSort_10_enable ? io_in_hviprio2_ALL[55:48] : 8'h0) == 8'h0;
  wire        gGen_27 =
    ipriosTmp_result_leftIprio_rightIprio_sel_1888 & hvipriosSort_10_enable
    | ipriosTmp_result_leftIprio_rightIprio_sel_1891
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1892 & hvipriosSort_10_enable
       | ipriosTmp_result_leftIprio_rightIprio_sel_1894 & hvipriosSort_10_enable
       | ipriosTmp_result_leftIprio_rightIprio_sel_1903
       & ipriosTmp_result_leftIprio_rightIprio_sel_1911 & hvipriosSort_10_enable);
  wire        ipriosTmp_result_leftIprio_rightIprio_17_0_isZero =
    ipriosTmp_result_leftIprio_rightIprio_sel_1888 & hvipriosSort_10_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1890 & hvipriosSort_11_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1891
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1892 & hvipriosSort_10_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1894 & hvipriosSort_10_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1898 & hvipriosSort_11_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1903
       & (ipriosTmp_result_leftIprio_rightIprio_sel_1911
            ? hvipriosSort_10_isZero
            : hvipriosSort_11_isZero));
  wire        ipriosTmp_result_leftIprio_rightIprio_17_0_enable =
    ipriosTmp_result_leftIprio_rightIprio_sel_1888 & hvipriosSort_10_enable
    | ipriosTmp_result_leftIprio_rightIprio_sel_1890 & hvipriosSort_11_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_1891
    & (ipriosTmp_result_leftIprio_rightIprio_sel_1892 & hvipriosSort_10_enable
       | ipriosTmp_result_leftIprio_rightIprio_sel_1894 & hvipriosSort_10_enable
       | ipriosTmp_result_leftIprio_rightIprio_sel_1898 & hvipriosSort_11_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_1903
       & (ipriosTmp_result_leftIprio_rightIprio_sel_1911
            ? hvipriosSort_10_enable
            : hvipriosSort_11_isZero));
  wire [5:0]  ipriosTmp_result_leftIprio_rightIprio_17_0_idx =
    (ipriosTmp_result_leftIprio_rightIprio_sel_1888 ? 6'hA : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1890 ? 6'hB : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_1891
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_1892
            | ipriosTmp_result_leftIprio_rightIprio_sel_1894
              ? 6'hA
              : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1898 ? 6'hB : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_1903
                ? {5'h5, ~ipriosTmp_result_leftIprio_rightIprio_sel_1911}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_sel_1888 =
    ipriosTmp_result_leftIprio_leftIprio_17_0_enable
    & ~ipriosTmp_result_leftIprio_rightIprio_17_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1890 =
    ~ipriosTmp_result_leftIprio_leftIprio_17_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_17_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1891 =
    ipriosTmp_result_leftIprio_leftIprio_17_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_17_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_1892 =
    ipriosTmp_result_leftIprio_leftIprio_17_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_17_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1894 =
    ipriosTmp_result_leftIprio_leftIprio_17_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_17_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1898 =
    ~ipriosTmp_result_leftIprio_leftIprio_17_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_17_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_1903 =
    ~ipriosTmp_result_leftIprio_leftIprio_17_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_17_0_isZero;
  wire        gGen_28 =
    ipriosTmp_result_leftIprio_sel_1890 & gGen_27
    | ipriosTmp_result_leftIprio_sel_1891
    & (ipriosTmp_result_leftIprio_sel_1894
       & ipriosTmp_result_leftIprio_leftIprio_17_0_idx[5] & gGen_27
       | ipriosTmp_result_leftIprio_sel_1898
       & ~(ipriosTmp_result_leftIprio_rightIprio_17_0_idx[5]) & gGen_27);
  wire [7:0]  ipriosTmp_result_leftIprio_17_0_prioNum =
    gGen_28 ? io_in_hviprio2_ALL[55:48] : 8'h0;
  wire        ipriosTmp_result_leftIprio_17_0_isZero =
    ipriosTmp_result_leftIprio_sel_1888
    & ipriosTmp_result_leftIprio_leftIprio_17_0_isZero
    | ipriosTmp_result_leftIprio_sel_1890
    & ipriosTmp_result_leftIprio_rightIprio_17_0_isZero
    | ipriosTmp_result_leftIprio_sel_1891
    & (ipriosTmp_result_leftIprio_sel_1892
       & ipriosTmp_result_leftIprio_leftIprio_17_0_isZero
       | ipriosTmp_result_leftIprio_sel_1894
       & (ipriosTmp_result_leftIprio_leftIprio_17_0_idx[5]
            ? ipriosTmp_result_leftIprio_rightIprio_17_0_isZero
            : ipriosTmp_result_leftIprio_leftIprio_17_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1898
       & (ipriosTmp_result_leftIprio_rightIprio_17_0_idx[5]
            ? ipriosTmp_result_leftIprio_leftIprio_17_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_17_0_isZero)
       | ipriosTmp_result_leftIprio_sel_1903
       & ipriosTmp_result_leftIprio_leftIprio_17_0_isZero);
  wire        ipriosTmp_result_leftIprio_17_0_enable =
    ipriosTmp_result_leftIprio_sel_1888
    & ipriosTmp_result_leftIprio_leftIprio_17_0_enable
    | ipriosTmp_result_leftIprio_sel_1890
    & ipriosTmp_result_leftIprio_rightIprio_17_0_enable
    | ipriosTmp_result_leftIprio_sel_1891
    & (ipriosTmp_result_leftIprio_sel_1892
       & ipriosTmp_result_leftIprio_leftIprio_17_0_enable
       | ipriosTmp_result_leftIprio_sel_1894
       & (ipriosTmp_result_leftIprio_leftIprio_17_0_idx[5]
            ? ipriosTmp_result_leftIprio_rightIprio_17_0_enable
            : ipriosTmp_result_leftIprio_leftIprio_17_0_enable)
       | ipriosTmp_result_leftIprio_sel_1898
       & (ipriosTmp_result_leftIprio_rightIprio_17_0_idx[5]
            ? ipriosTmp_result_leftIprio_leftIprio_17_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_17_0_enable)
       | ipriosTmp_result_leftIprio_sel_1903
       & ipriosTmp_result_leftIprio_leftIprio_17_0_enable);
  wire [5:0]  ipriosTmp_result_leftIprio_17_0_idx =
    (ipriosTmp_result_leftIprio_sel_1888
       ? ipriosTmp_result_leftIprio_leftIprio_17_0_idx
       : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1890
         ? ipriosTmp_result_leftIprio_rightIprio_17_0_idx
         : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_1891
         ? (ipriosTmp_result_leftIprio_sel_1892
              ? ipriosTmp_result_leftIprio_leftIprio_17_0_idx
              : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1894
                ? (ipriosTmp_result_leftIprio_leftIprio_17_0_idx[5]
                     ? ipriosTmp_result_leftIprio_rightIprio_17_0_idx
                     : ipriosTmp_result_leftIprio_leftIprio_17_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1898
                ? (ipriosTmp_result_leftIprio_rightIprio_17_0_idx[5]
                     ? ipriosTmp_result_leftIprio_leftIprio_17_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_17_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_1903
                ? ipriosTmp_result_leftIprio_leftIprio_17_0_idx
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1888 =
    hvipriosSort_12_isZero & ~hvipriosSort_13_enable;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1890 =
    ~hvipriosSort_12_isZero & hvipriosSort_13_enable;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1891 =
    hvipriosSort_12_isZero & hvipriosSort_13_enable;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1892 =
    hvipriosSort_12_isZero & hvipriosSort_13_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1894 =
    hvipriosSort_12_isZero & ~hvipriosSort_13_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1898 =
    ~hvipriosSort_12_isZero & hvipriosSort_13_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1903 =
    ~hvipriosSort_12_isZero & ~hvipriosSort_13_isZero;
  wire        gGen_29 =
    ipriosTmp_result_rightIprio_leftIprio_sel_1890 & hvipriosSort_13_enable
    | ipriosTmp_result_rightIprio_leftIprio_sel_1891
    & ipriosTmp_result_rightIprio_leftIprio_sel_1898 & hvipriosSort_13_enable;
  wire        ipriosTmp_result_rightIprio_leftIprio_17_0_isZero =
    ipriosTmp_result_rightIprio_leftIprio_sel_1888 & hvipriosSort_12_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1890 & hvipriosSort_13_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1891
    & (ipriosTmp_result_rightIprio_leftIprio_sel_1892 & hvipriosSort_12_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1894 & hvipriosSort_12_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1898 & hvipriosSort_13_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1903 & hvipriosSort_12_isZero);
  wire        ipriosTmp_result_rightIprio_leftIprio_17_0_enable =
    ipriosTmp_result_rightIprio_leftIprio_sel_1888 & hvipriosSort_12_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_1890 & hvipriosSort_13_enable
    | ipriosTmp_result_rightIprio_leftIprio_sel_1891
    & (ipriosTmp_result_rightIprio_leftIprio_sel_1892 & hvipriosSort_12_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1894 & hvipriosSort_12_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_1898 & hvipriosSort_13_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_1903 & hvipriosSort_12_isZero);
  wire [5:0]  ipriosTmp_result_rightIprio_leftIprio_17_0_idx =
    (ipriosTmp_result_rightIprio_leftIprio_sel_1888 ? 6'hC : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1890 ? 6'hD : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_1891
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_1892
            | ipriosTmp_result_rightIprio_leftIprio_sel_1894
              ? 6'hC
              : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1898 ? 6'hD : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_1903 ? 6'hC : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1888 =
    hvipriosSort_14_isZero & ~hvipriosSort_15_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1890 =
    ~hvipriosSort_14_isZero & hvipriosSort_15_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1891 =
    hvipriosSort_14_isZero & hvipriosSort_15_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1892 =
    hvipriosSort_14_isZero & hvipriosSort_15_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1894 =
    hvipriosSort_14_isZero & ~hvipriosSort_15_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1898 =
    ~hvipriosSort_14_isZero & hvipriosSort_15_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1903 =
    ~hvipriosSort_14_isZero & ~hvipriosSort_15_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_17_0_isZero =
    ipriosTmp_result_rightIprio_rightIprio_sel_1888 & hvipriosSort_14_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1890 & hvipriosSort_15_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1891
    & (ipriosTmp_result_rightIprio_rightIprio_sel_1892 & hvipriosSort_14_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1894 & hvipriosSort_14_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1898 & hvipriosSort_15_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1903
       & hvipriosSort_14_isZero);
  wire        ipriosTmp_result_rightIprio_rightIprio_17_0_enable =
    ipriosTmp_result_rightIprio_rightIprio_sel_1888 & hvipriosSort_14_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1890 & hvipriosSort_15_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_1891
    & (ipriosTmp_result_rightIprio_rightIprio_sel_1892 & hvipriosSort_14_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1894 & hvipriosSort_14_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1898 & hvipriosSort_15_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_1903
       & hvipriosSort_14_isZero);
  wire [5:0]  ipriosTmp_result_rightIprio_rightIprio_17_0_idx =
    (ipriosTmp_result_rightIprio_rightIprio_sel_1888 ? 6'hE : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1890 ? 6'hF : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_1891
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_1892
            | ipriosTmp_result_rightIprio_rightIprio_sel_1894
              ? 6'hE
              : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1898 ? 6'hF : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_1903 ? 6'hE : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_sel_1888 =
    ipriosTmp_result_rightIprio_leftIprio_17_0_enable
    & ~ipriosTmp_result_rightIprio_rightIprio_17_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1890 =
    ~ipriosTmp_result_rightIprio_leftIprio_17_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_17_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1891 =
    ipriosTmp_result_rightIprio_leftIprio_17_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_17_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_1892 =
    ipriosTmp_result_rightIprio_leftIprio_17_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_17_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1894 =
    ipriosTmp_result_rightIprio_leftIprio_17_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_17_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1898 =
    ~ipriosTmp_result_rightIprio_leftIprio_17_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_17_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1903 =
    ~ipriosTmp_result_rightIprio_leftIprio_17_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_17_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_1911 =
    (gGen_29 ? io_in_hviprio2_ALL[47:40] : 8'h0) == 8'h0;
  wire        gGen_30 =
    ipriosTmp_result_rightIprio_sel_1888 & gGen_29
    | ipriosTmp_result_rightIprio_sel_1891
    & (ipriosTmp_result_rightIprio_sel_1892 & gGen_29
       | ipriosTmp_result_rightIprio_sel_1894
       & ~(ipriosTmp_result_rightIprio_leftIprio_17_0_idx[5]) & gGen_29
       | ipriosTmp_result_rightIprio_sel_1898
       & ipriosTmp_result_rightIprio_rightIprio_17_0_idx[5] & gGen_29
       | ipriosTmp_result_rightIprio_sel_1903
       & ipriosTmp_result_rightIprio_sel_1911 & gGen_29);
  wire [7:0]  ipriosTmp_result_rightIprio_17_0_prioNum =
    gGen_30 ? io_in_hviprio2_ALL[47:40] : 8'h0;
  wire        ipriosTmp_result_rightIprio_17_0_isZero =
    ipriosTmp_result_rightIprio_sel_1888
    & ipriosTmp_result_rightIprio_leftIprio_17_0_isZero
    | ipriosTmp_result_rightIprio_sel_1890
    & ipriosTmp_result_rightIprio_rightIprio_17_0_isZero
    | ipriosTmp_result_rightIprio_sel_1891
    & (ipriosTmp_result_rightIprio_sel_1892
       & ipriosTmp_result_rightIprio_leftIprio_17_0_isZero
       | ipriosTmp_result_rightIprio_sel_1894
       & (ipriosTmp_result_rightIprio_leftIprio_17_0_idx[5]
            ? ipriosTmp_result_rightIprio_rightIprio_17_0_isZero
            : ipriosTmp_result_rightIprio_leftIprio_17_0_isZero)
       | ipriosTmp_result_rightIprio_sel_1898
       & (ipriosTmp_result_rightIprio_rightIprio_17_0_idx[5]
            ? ipriosTmp_result_rightIprio_leftIprio_17_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_17_0_isZero)
       | ipriosTmp_result_rightIprio_sel_1903
       & (ipriosTmp_result_rightIprio_sel_1911
            ? ipriosTmp_result_rightIprio_leftIprio_17_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_17_0_isZero));
  wire        ipriosTmp_result_rightIprio_17_0_enable =
    ipriosTmp_result_rightIprio_sel_1888
    & ipriosTmp_result_rightIprio_leftIprio_17_0_enable
    | ipriosTmp_result_rightIprio_sel_1890
    & ipriosTmp_result_rightIprio_rightIprio_17_0_enable
    | ipriosTmp_result_rightIprio_sel_1891
    & (ipriosTmp_result_rightIprio_sel_1892
       & ipriosTmp_result_rightIprio_leftIprio_17_0_enable
       | ipriosTmp_result_rightIprio_sel_1894
       & (ipriosTmp_result_rightIprio_leftIprio_17_0_idx[5]
            ? ipriosTmp_result_rightIprio_rightIprio_17_0_enable
            : ipriosTmp_result_rightIprio_leftIprio_17_0_enable)
       | ipriosTmp_result_rightIprio_sel_1898
       & (ipriosTmp_result_rightIprio_rightIprio_17_0_idx[5]
            ? ipriosTmp_result_rightIprio_leftIprio_17_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_17_0_enable)
       | ipriosTmp_result_rightIprio_sel_1903
       & (ipriosTmp_result_rightIprio_sel_1911
            ? ipriosTmp_result_rightIprio_leftIprio_17_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_17_0_enable));
  wire [5:0]  ipriosTmp_result_rightIprio_17_0_idx =
    (ipriosTmp_result_rightIprio_sel_1888
       ? ipriosTmp_result_rightIprio_leftIprio_17_0_idx
       : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_1890
         ? ipriosTmp_result_rightIprio_rightIprio_17_0_idx
         : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_1891
         ? (ipriosTmp_result_rightIprio_sel_1892
              ? ipriosTmp_result_rightIprio_leftIprio_17_0_idx
              : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1894
                ? (ipriosTmp_result_rightIprio_leftIprio_17_0_idx[5]
                     ? ipriosTmp_result_rightIprio_rightIprio_17_0_idx
                     : ipriosTmp_result_rightIprio_leftIprio_17_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1898
                ? (ipriosTmp_result_rightIprio_rightIprio_17_0_idx[5]
                     ? ipriosTmp_result_rightIprio_leftIprio_17_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_17_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_1903
                ? (ipriosTmp_result_rightIprio_sel_1911
                     ? ipriosTmp_result_rightIprio_leftIprio_17_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_17_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_sel_1888 =
    ipriosTmp_result_leftIprio_17_0_enable & ~ipriosTmp_result_rightIprio_17_0_enable;
  wire        ipriosTmp_result_sel_1890 =
    ~ipriosTmp_result_leftIprio_17_0_enable & ipriosTmp_result_rightIprio_17_0_enable;
  wire        ipriosTmp_result_sel_1891 =
    ipriosTmp_result_leftIprio_17_0_enable & ipriosTmp_result_rightIprio_17_0_enable;
  wire        ipriosTmp_result_sel_1892 =
    ipriosTmp_result_leftIprio_17_0_isZero & ipriosTmp_result_rightIprio_17_0_isZero;
  wire        ipriosTmp_result_sel_1894 =
    ipriosTmp_result_leftIprio_17_0_isZero & ~ipriosTmp_result_rightIprio_17_0_isZero;
  wire        ipriosTmp_result_sel_1898 =
    ~ipriosTmp_result_leftIprio_17_0_isZero & ipriosTmp_result_rightIprio_17_0_isZero;
  wire        ipriosTmp_result_sel_1903 =
    ~ipriosTmp_result_leftIprio_17_0_isZero & ~ipriosTmp_result_rightIprio_17_0_isZero;
  wire        ipriosTmp_result_sel_1911 =
    ipriosTmp_result_leftIprio_17_0_prioNum <= ipriosTmp_result_rightIprio_17_0_prioNum;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_1999 =
    hvipriosSort_16_enable & ~hvipriosSort_17_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2001 =
    ~hvipriosSort_16_enable & hvipriosSort_17_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2002 =
    hvipriosSort_16_enable & hvipriosSort_17_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2003 =
    hvipriosSort_16_isZero & hvipriosSort_17_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2005 =
    hvipriosSort_16_isZero & ~hvipriosSort_17_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2009 =
    ~hvipriosSort_16_isZero & hvipriosSort_17_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2014 =
    ~hvipriosSort_16_isZero & ~hvipriosSort_17_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2022 =
    (hvipriosSort_16_enable ? io_in_hviprio2_ALL[39:32] : 8'h0) == 8'h0;
  wire        gGen_31 =
    ipriosTmp_result_leftIprio_leftIprio_sel_1999 & hvipriosSort_16_enable
    | ipriosTmp_result_leftIprio_leftIprio_sel_2002
    & (ipriosTmp_result_leftIprio_leftIprio_sel_2003 & hvipriosSort_16_enable
       | ipriosTmp_result_leftIprio_leftIprio_sel_2005 & hvipriosSort_16_enable
       | ipriosTmp_result_leftIprio_leftIprio_sel_2014
       & ipriosTmp_result_leftIprio_leftIprio_sel_2022 & hvipriosSort_16_enable);
  wire        ipriosTmp_result_leftIprio_leftIprio_18_0_isZero =
    ipriosTmp_result_leftIprio_leftIprio_sel_1999 & hvipriosSort_16_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_2001 & hvipriosSort_17_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_2002
    & (ipriosTmp_result_leftIprio_leftIprio_sel_2003 & hvipriosSort_16_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2005 & hvipriosSort_16_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2009 & hvipriosSort_17_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2014
       & (ipriosTmp_result_leftIprio_leftIprio_sel_2022
            ? hvipriosSort_16_isZero
            : hvipriosSort_17_isZero));
  wire        ipriosTmp_result_leftIprio_leftIprio_18_0_enable =
    ipriosTmp_result_leftIprio_leftIprio_sel_1999 & hvipriosSort_16_enable
    | ipriosTmp_result_leftIprio_leftIprio_sel_2001 & hvipriosSort_17_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_2002
    & (ipriosTmp_result_leftIprio_leftIprio_sel_2003 & hvipriosSort_16_enable
       | ipriosTmp_result_leftIprio_leftIprio_sel_2005 & hvipriosSort_16_enable
       | ipriosTmp_result_leftIprio_leftIprio_sel_2009 & hvipriosSort_17_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2014
       & (ipriosTmp_result_leftIprio_leftIprio_sel_2022
            ? hvipriosSort_16_enable
            : hvipriosSort_17_isZero));
  wire [5:0]  ipriosTmp_result_leftIprio_leftIprio_18_0_idx =
    {1'h0, ipriosTmp_result_leftIprio_leftIprio_sel_1999, 4'h0}
    | (ipriosTmp_result_leftIprio_leftIprio_sel_2001 ? 6'h11 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_2002
         ? {1'h0,
            ipriosTmp_result_leftIprio_leftIprio_sel_2003
              | ipriosTmp_result_leftIprio_leftIprio_sel_2005,
            4'h0} | (ipriosTmp_result_leftIprio_leftIprio_sel_2009 ? 6'h11 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_2014
                ? {5'h8, ~ipriosTmp_result_leftIprio_leftIprio_sel_2022}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_1999 =
    hvipriosSort_18_isZero & ~hvipriosSort_19_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2001 =
    ~hvipriosSort_18_isZero & hvipriosSort_19_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2002 =
    hvipriosSort_18_isZero & hvipriosSort_19_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2003 =
    hvipriosSort_18_isZero & hvipriosSort_19_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2005 =
    hvipriosSort_18_isZero & ~hvipriosSort_19_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2009 =
    ~hvipriosSort_18_isZero & hvipriosSort_19_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2014 =
    ~hvipriosSort_18_isZero & ~hvipriosSort_19_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_18_0_isZero =
    ipriosTmp_result_leftIprio_rightIprio_sel_1999 & hvipriosSort_18_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_2001 & hvipriosSort_19_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_2002
    & (ipriosTmp_result_leftIprio_rightIprio_sel_2003 & hvipriosSort_18_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2005 & hvipriosSort_18_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2009 & hvipriosSort_19_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2014 & hvipriosSort_18_isZero);
  wire        ipriosTmp_result_leftIprio_rightIprio_18_0_enable =
    ipriosTmp_result_leftIprio_rightIprio_sel_1999 & hvipriosSort_18_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_2001 & hvipriosSort_19_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_2002
    & (ipriosTmp_result_leftIprio_rightIprio_sel_2003 & hvipriosSort_18_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2005 & hvipriosSort_18_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2009 & hvipriosSort_19_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2014 & hvipriosSort_18_isZero);
  wire [5:0]  ipriosTmp_result_leftIprio_rightIprio_18_0_idx =
    (ipriosTmp_result_leftIprio_rightIprio_sel_1999 ? 6'h12 : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_2001 ? 6'h13 : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_2002
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_2003
            | ipriosTmp_result_leftIprio_rightIprio_sel_2005
              ? 6'h12
              : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_2009 ? 6'h13 : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_2014 ? 6'h12 : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_sel_1999 =
    ipriosTmp_result_leftIprio_leftIprio_18_0_enable
    & ~ipriosTmp_result_leftIprio_rightIprio_18_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_2001 =
    ~ipriosTmp_result_leftIprio_leftIprio_18_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_18_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_2002 =
    ipriosTmp_result_leftIprio_leftIprio_18_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_18_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_2003 =
    ipriosTmp_result_leftIprio_leftIprio_18_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_18_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_2005 =
    ipriosTmp_result_leftIprio_leftIprio_18_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_18_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_2009 =
    ~ipriosTmp_result_leftIprio_leftIprio_18_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_18_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_2014 =
    ~ipriosTmp_result_leftIprio_leftIprio_18_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_18_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_2022 =
    (gGen_31 ? io_in_hviprio2_ALL[39:32] : 8'h0) == 8'h0;
  wire        gGen_32 =
    ipriosTmp_result_leftIprio_sel_1999 & gGen_31
    | ipriosTmp_result_leftIprio_sel_2002
    & (ipriosTmp_result_leftIprio_sel_2003 & gGen_31
       | ipriosTmp_result_leftIprio_sel_2005
       & ~(ipriosTmp_result_leftIprio_leftIprio_18_0_idx[5]) & gGen_31
       | ipriosTmp_result_leftIprio_sel_2009
       & ipriosTmp_result_leftIprio_rightIprio_18_0_idx[5] & gGen_31
       | ipriosTmp_result_leftIprio_sel_2014
       & ipriosTmp_result_leftIprio_sel_2022 & gGen_31);
  wire        ipriosTmp_result_leftIprio_18_0_isZero =
    ipriosTmp_result_leftIprio_sel_1999
    & ipriosTmp_result_leftIprio_leftIprio_18_0_isZero
    | ipriosTmp_result_leftIprio_sel_2001
    & ipriosTmp_result_leftIprio_rightIprio_18_0_isZero
    | ipriosTmp_result_leftIprio_sel_2002
    & (ipriosTmp_result_leftIprio_sel_2003
       & ipriosTmp_result_leftIprio_leftIprio_18_0_isZero
       | ipriosTmp_result_leftIprio_sel_2005
       & (ipriosTmp_result_leftIprio_leftIprio_18_0_idx[5]
            ? ipriosTmp_result_leftIprio_rightIprio_18_0_isZero
            : ipriosTmp_result_leftIprio_leftIprio_18_0_isZero)
       | ipriosTmp_result_leftIprio_sel_2009
       & (ipriosTmp_result_leftIprio_rightIprio_18_0_idx[5]
            ? ipriosTmp_result_leftIprio_leftIprio_18_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_18_0_isZero)
       | ipriosTmp_result_leftIprio_sel_2014
       & (ipriosTmp_result_leftIprio_sel_2022
            ? ipriosTmp_result_leftIprio_leftIprio_18_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_18_0_isZero));
  wire        ipriosTmp_result_leftIprio_18_0_enable =
    ipriosTmp_result_leftIprio_sel_1999
    & ipriosTmp_result_leftIprio_leftIprio_18_0_enable
    | ipriosTmp_result_leftIprio_sel_2001
    & ipriosTmp_result_leftIprio_rightIprio_18_0_enable
    | ipriosTmp_result_leftIprio_sel_2002
    & (ipriosTmp_result_leftIprio_sel_2003
       & ipriosTmp_result_leftIprio_leftIprio_18_0_enable
       | ipriosTmp_result_leftIprio_sel_2005
       & (ipriosTmp_result_leftIprio_leftIprio_18_0_idx[5]
            ? ipriosTmp_result_leftIprio_rightIprio_18_0_enable
            : ipriosTmp_result_leftIprio_leftIprio_18_0_enable)
       | ipriosTmp_result_leftIprio_sel_2009
       & (ipriosTmp_result_leftIprio_rightIprio_18_0_idx[5]
            ? ipriosTmp_result_leftIprio_leftIprio_18_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_18_0_enable)
       | ipriosTmp_result_leftIprio_sel_2014
       & (ipriosTmp_result_leftIprio_sel_2022
            ? ipriosTmp_result_leftIprio_leftIprio_18_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_18_0_enable));
  wire [5:0]  ipriosTmp_result_leftIprio_18_0_idx =
    (ipriosTmp_result_leftIprio_sel_1999
       ? ipriosTmp_result_leftIprio_leftIprio_18_0_idx
       : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_2001
         ? ipriosTmp_result_leftIprio_rightIprio_18_0_idx
         : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_2002
         ? (ipriosTmp_result_leftIprio_sel_2003
              ? ipriosTmp_result_leftIprio_leftIprio_18_0_idx
              : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_2005
                ? (ipriosTmp_result_leftIprio_leftIprio_18_0_idx[5]
                     ? ipriosTmp_result_leftIprio_rightIprio_18_0_idx
                     : ipriosTmp_result_leftIprio_leftIprio_18_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_2009
                ? (ipriosTmp_result_leftIprio_rightIprio_18_0_idx[5]
                     ? ipriosTmp_result_leftIprio_leftIprio_18_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_18_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_2014
                ? (ipriosTmp_result_leftIprio_sel_2022
                     ? ipriosTmp_result_leftIprio_leftIprio_18_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_18_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_1999 =
    hvipriosSort_20_isZero & ~hvipriosSort_21_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2001 =
    ~hvipriosSort_20_isZero & hvipriosSort_21_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2002 =
    hvipriosSort_20_isZero & hvipriosSort_21_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2003 =
    hvipriosSort_20_isZero & hvipriosSort_21_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2005 =
    hvipriosSort_20_isZero & ~hvipriosSort_21_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2009 =
    ~hvipriosSort_20_isZero & hvipriosSort_21_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2014 =
    ~hvipriosSort_20_isZero & ~hvipriosSort_21_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_18_0_isZero =
    ipriosTmp_result_rightIprio_leftIprio_sel_1999 & hvipriosSort_20_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_2001 & hvipriosSort_21_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_2002
    & (ipriosTmp_result_rightIprio_leftIprio_sel_2003 & hvipriosSort_20_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2005 & hvipriosSort_20_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2009 & hvipriosSort_21_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2014 & hvipriosSort_20_isZero);
  wire        ipriosTmp_result_rightIprio_leftIprio_18_0_enable =
    ipriosTmp_result_rightIprio_leftIprio_sel_1999 & hvipriosSort_20_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_2001 & hvipriosSort_21_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_2002
    & (ipriosTmp_result_rightIprio_leftIprio_sel_2003 & hvipriosSort_20_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2005 & hvipriosSort_20_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2009 & hvipriosSort_21_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2014 & hvipriosSort_20_isZero);
  wire [5:0]  ipriosTmp_result_rightIprio_leftIprio_18_0_idx =
    (ipriosTmp_result_rightIprio_leftIprio_sel_1999 ? 6'h14 : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_2001 ? 6'h15 : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_2002
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_2003
            | ipriosTmp_result_rightIprio_leftIprio_sel_2005
              ? 6'h14
              : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_2009 ? 6'h15 : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_2014 ? 6'h14 : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_1999 =
    hvipriosSort_22_isZero & ~hvipriosSort_23_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2001 =
    ~hvipriosSort_22_isZero & hvipriosSort_23_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2002 =
    hvipriosSort_22_isZero & hvipriosSort_23_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2003 =
    hvipriosSort_22_isZero & hvipriosSort_23_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2005 =
    hvipriosSort_22_isZero & ~hvipriosSort_23_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2009 =
    ~hvipriosSort_22_isZero & hvipriosSort_23_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2014 =
    ~hvipriosSort_22_isZero & ~hvipriosSort_23_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_18_0_isZero =
    ipriosTmp_result_rightIprio_rightIprio_sel_1999 & hvipriosSort_22_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_2001 & hvipriosSort_23_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_2002
    & (ipriosTmp_result_rightIprio_rightIprio_sel_2003 & hvipriosSort_22_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2005 & hvipriosSort_22_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2009 & hvipriosSort_23_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2014
       & hvipriosSort_22_isZero);
  wire        ipriosTmp_result_rightIprio_rightIprio_18_0_enable =
    ipriosTmp_result_rightIprio_rightIprio_sel_1999 & hvipriosSort_22_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_2001 & hvipriosSort_23_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_2002
    & (ipriosTmp_result_rightIprio_rightIprio_sel_2003 & hvipriosSort_22_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2005 & hvipriosSort_22_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2009 & hvipriosSort_23_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2014
       & hvipriosSort_22_isZero);
  wire [5:0]  ipriosTmp_result_rightIprio_rightIprio_18_0_idx =
    (ipriosTmp_result_rightIprio_rightIprio_sel_1999 ? 6'h16 : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_2001 ? 6'h17 : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_2002
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_2003
            | ipriosTmp_result_rightIprio_rightIprio_sel_2005
              ? 6'h16
              : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_2009 ? 6'h17 : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_2014 ? 6'h16 : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_sel_1999 =
    ipriosTmp_result_rightIprio_leftIprio_18_0_enable
    & ~ipriosTmp_result_rightIprio_rightIprio_18_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_2001 =
    ~ipriosTmp_result_rightIprio_leftIprio_18_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_18_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_2002 =
    ipriosTmp_result_rightIprio_leftIprio_18_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_18_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_2003 =
    ipriosTmp_result_rightIprio_leftIprio_18_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_18_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_2005 =
    ipriosTmp_result_rightIprio_leftIprio_18_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_18_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_2009 =
    ~ipriosTmp_result_rightIprio_leftIprio_18_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_18_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_2014 =
    ~ipriosTmp_result_rightIprio_leftIprio_18_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_18_0_isZero;
  wire        ipriosTmp_result_rightIprio_18_0_isZero =
    ipriosTmp_result_rightIprio_sel_1999
    & ipriosTmp_result_rightIprio_leftIprio_18_0_isZero
    | ipriosTmp_result_rightIprio_sel_2001
    & ipriosTmp_result_rightIprio_rightIprio_18_0_isZero
    | ipriosTmp_result_rightIprio_sel_2002
    & (ipriosTmp_result_rightIprio_sel_2003
       & ipriosTmp_result_rightIprio_leftIprio_18_0_isZero
       | ipriosTmp_result_rightIprio_sel_2005
       & (ipriosTmp_result_rightIprio_leftIprio_18_0_idx[5]
            ? ipriosTmp_result_rightIprio_rightIprio_18_0_isZero
            : ipriosTmp_result_rightIprio_leftIprio_18_0_isZero)
       | ipriosTmp_result_rightIprio_sel_2009
       & (ipriosTmp_result_rightIprio_rightIprio_18_0_idx[5]
            ? ipriosTmp_result_rightIprio_leftIprio_18_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_18_0_isZero)
       | ipriosTmp_result_rightIprio_sel_2014
       & ipriosTmp_result_rightIprio_leftIprio_18_0_isZero);
  wire        ipriosTmp_result_rightIprio_18_0_enable =
    ipriosTmp_result_rightIprio_sel_1999
    & ipriosTmp_result_rightIprio_leftIprio_18_0_enable
    | ipriosTmp_result_rightIprio_sel_2001
    & ipriosTmp_result_rightIprio_rightIprio_18_0_enable
    | ipriosTmp_result_rightIprio_sel_2002
    & (ipriosTmp_result_rightIprio_sel_2003
       & ipriosTmp_result_rightIprio_leftIprio_18_0_enable
       | ipriosTmp_result_rightIprio_sel_2005
       & (ipriosTmp_result_rightIprio_leftIprio_18_0_idx[5]
            ? ipriosTmp_result_rightIprio_rightIprio_18_0_enable
            : ipriosTmp_result_rightIprio_leftIprio_18_0_enable)
       | ipriosTmp_result_rightIprio_sel_2009
       & (ipriosTmp_result_rightIprio_rightIprio_18_0_idx[5]
            ? ipriosTmp_result_rightIprio_leftIprio_18_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_18_0_enable)
       | ipriosTmp_result_rightIprio_sel_2014
       & ipriosTmp_result_rightIprio_leftIprio_18_0_enable);
  wire [5:0]  ipriosTmp_result_rightIprio_18_0_idx =
    (ipriosTmp_result_rightIprio_sel_1999
       ? ipriosTmp_result_rightIprio_leftIprio_18_0_idx
       : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_2001
         ? ipriosTmp_result_rightIprio_rightIprio_18_0_idx
         : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_2002
         ? (ipriosTmp_result_rightIprio_sel_2003
              ? ipriosTmp_result_rightIprio_leftIprio_18_0_idx
              : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_2005
                ? (ipriosTmp_result_rightIprio_leftIprio_18_0_idx[5]
                     ? ipriosTmp_result_rightIprio_rightIprio_18_0_idx
                     : ipriosTmp_result_rightIprio_leftIprio_18_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_2009
                ? (ipriosTmp_result_rightIprio_rightIprio_18_0_idx[5]
                     ? ipriosTmp_result_rightIprio_leftIprio_18_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_18_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_2014
                ? ipriosTmp_result_rightIprio_leftIprio_18_0_idx
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_sel_1999 =
    ipriosTmp_result_leftIprio_18_0_enable & ~ipriosTmp_result_rightIprio_18_0_enable;
  wire        ipriosTmp_result_sel_2001 =
    ~ipriosTmp_result_leftIprio_18_0_enable & ipriosTmp_result_rightIprio_18_0_enable;
  wire        ipriosTmp_result_sel_2002 =
    ipriosTmp_result_leftIprio_18_0_enable & ipriosTmp_result_rightIprio_18_0_enable;
  wire        ipriosTmp_result_sel_2003 =
    ipriosTmp_result_leftIprio_18_0_isZero & ipriosTmp_result_rightIprio_18_0_isZero;
  wire        ipriosTmp_result_sel_2005 =
    ipriosTmp_result_leftIprio_18_0_isZero & ~ipriosTmp_result_rightIprio_18_0_isZero;
  wire        ipriosTmp_result_sel_2009 =
    ~ipriosTmp_result_leftIprio_18_0_isZero & ipriosTmp_result_rightIprio_18_0_isZero;
  wire        ipriosTmp_result_sel_2014 =
    ~ipriosTmp_result_leftIprio_18_0_isZero & ~ipriosTmp_result_rightIprio_18_0_isZero;
  wire        ipriosTmp_result_sel_2022 =
    (gGen_32 ? io_in_hviprio2_ALL[39:32] : 8'h0) == 8'h0;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2110 =
    hvipriosSort_28_enable & ~hvipriosSort_29_enable;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2112 =
    ~hvipriosSort_28_enable & hvipriosSort_29_enable;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2113 =
    hvipriosSort_28_enable & hvipriosSort_29_enable;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2114 =
    hvipriosSort_28_isZero & hvipriosSort_29_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2116 =
    hvipriosSort_28_isZero & ~hvipriosSort_29_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2120 =
    ~hvipriosSort_28_isZero & hvipriosSort_29_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2125 =
    ~hvipriosSort_28_isZero & ~hvipriosSort_29_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2133 =
    hvipriosSort_28_prioNum <= hvipriosSort_29_prioNum;
  wire        ipriosTmp_result_19_0_enable =
    ipriosTmp_result_rightIprio_leftIprio_sel_2110 & hvipriosSort_28_enable
    | ipriosTmp_result_rightIprio_leftIprio_sel_2112 & hvipriosSort_29_enable
    | ipriosTmp_result_rightIprio_leftIprio_sel_2113
    & (ipriosTmp_result_rightIprio_leftIprio_sel_2114 & hvipriosSort_28_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_2116 & hvipriosSort_28_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_2120 & hvipriosSort_29_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_2125
       & (ipriosTmp_result_rightIprio_leftIprio_sel_2133
            ? hvipriosSort_28_enable
            : hvipriosSort_29_enable));
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2221 =
    hvipriosSort_34_enable & ~hvipriosSort_35_enable;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2223 =
    ~hvipriosSort_34_enable & hvipriosSort_35_enable;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2224 =
    hvipriosSort_34_enable & hvipriosSort_35_enable;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2225 =
    hvipriosSort_34_isZero & hvipriosSort_35_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2227 =
    hvipriosSort_34_isZero & ~hvipriosSort_35_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2231 =
    ~hvipriosSort_34_isZero & hvipriosSort_35_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2236 =
    ~hvipriosSort_34_isZero & ~hvipriosSort_35_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2244 =
    hvipriosSort_34_prioNum <= hvipriosSort_35_prioNum;
  wire [7:0]  ipriosTmp_result_leftIprio_rightIprio_20_0_prioNum =
    (ipriosTmp_result_leftIprio_rightIprio_sel_2221 & hvipriosSort_34_enable
       ? io_in_hviprio1_PrioCOI
       : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_2223 & hvipriosSort_35_enable
         ? io_in_hviprio1_Prio14
         : 8'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_2224
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_2225
            & hvipriosSort_34_enable
              ? io_in_hviprio1_PrioCOI
              : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_2227
              & hvipriosSort_35_enable
                ? io_in_hviprio1_Prio14
                : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_2231
              & hvipriosSort_34_enable
                ? io_in_hviprio1_PrioCOI
                : 8'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_2236
                ? (ipriosTmp_result_leftIprio_rightIprio_sel_2244
                     ? hvipriosSort_34_prioNum
                     : hvipriosSort_35_prioNum)
                : 8'h0)
         : 8'h0);
  wire        ipriosTmp_result_leftIprio_20_0_enable =
    ipriosTmp_result_leftIprio_rightIprio_sel_2221 & hvipriosSort_34_enable
    | ipriosTmp_result_leftIprio_rightIprio_sel_2223 & hvipriosSort_35_enable
    | ipriosTmp_result_leftIprio_rightIprio_sel_2224
    & (ipriosTmp_result_leftIprio_rightIprio_sel_2225 & hvipriosSort_34_enable
       | ipriosTmp_result_leftIprio_rightIprio_sel_2227 & hvipriosSort_35_enable
       | ipriosTmp_result_leftIprio_rightIprio_sel_2231 & hvipriosSort_34_enable
       | ipriosTmp_result_leftIprio_rightIprio_sel_2236
       & (ipriosTmp_result_leftIprio_rightIprio_sel_2244
            ? hvipriosSort_34_enable
            : hvipriosSort_35_enable));
  wire [5:0]  ipriosTmp_result_leftIprio_rightIprio_20_0_idx =
    (ipriosTmp_result_leftIprio_rightIprio_sel_2221 ? 6'h22 : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_2223 ? 6'h23 : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_2224
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_2225 ? 6'h22 : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_2227 ? 6'h23 : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_2231 ? 6'h22 : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_2236
                ? {5'h11, ~ipriosTmp_result_leftIprio_rightIprio_sel_2244}
                : 6'h0)
         : 6'h0);
  wire [7:0]  ipriosTmp_result_leftIprio_20_0_prioNum =
    ipriosTmp_result_leftIprio_20_0_enable
      ? ipriosTmp_result_leftIprio_rightIprio_20_0_prioNum
      : 8'h0;
  wire        ipriosTmp_result_leftIprio_20_0_isZero =
    ipriosTmp_result_leftIprio_20_0_enable
    & (ipriosTmp_result_leftIprio_rightIprio_sel_2221 & hvipriosSort_34_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2223 & hvipriosSort_35_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2224
       & (ipriosTmp_result_leftIprio_rightIprio_sel_2225 & hvipriosSort_34_isZero
          | ipriosTmp_result_leftIprio_rightIprio_sel_2227
          & hvipriosSort_35_isZero
          | ipriosTmp_result_leftIprio_rightIprio_sel_2231
          & hvipriosSort_34_isZero
          | ipriosTmp_result_leftIprio_rightIprio_sel_2236
          & (ipriosTmp_result_leftIprio_rightIprio_sel_2244
               ? hvipriosSort_34_isZero
               : hvipriosSort_35_isZero)));
  wire [5:0]  ipriosTmp_result_leftIprio_20_0_idx =
    ipriosTmp_result_leftIprio_20_0_enable
      ? ipriosTmp_result_leftIprio_rightIprio_20_0_idx
      : 6'h0;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2221 =
    hvipriosSort_36_enable & ~hvipriosSort_37_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2223 =
    ~hvipriosSort_36_enable & hvipriosSort_37_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2224 =
    hvipriosSort_36_enable & hvipriosSort_37_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2225 =
    hvipriosSort_36_isZero & hvipriosSort_37_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2227 =
    hvipriosSort_36_isZero & ~hvipriosSort_37_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2231 =
    ~hvipriosSort_36_isZero & hvipriosSort_37_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2236 =
    ~hvipriosSort_36_isZero & ~hvipriosSort_37_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2244 =
    (hvipriosSort_36_enable ? io_in_hviprio1_Prio15 : 8'h0) == 8'h0;
  wire        gGen_33 =
    ipriosTmp_result_rightIprio_leftIprio_sel_2221 & hvipriosSort_36_enable
    | ipriosTmp_result_rightIprio_leftIprio_sel_2224
    & (ipriosTmp_result_rightIprio_leftIprio_sel_2225 & hvipriosSort_36_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_2231 & hvipriosSort_36_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_2236
       & ipriosTmp_result_rightIprio_leftIprio_sel_2244 & hvipriosSort_36_enable);
  wire        ipriosTmp_result_rightIprio_leftIprio_20_0_isZero =
    ipriosTmp_result_rightIprio_leftIprio_sel_2221 & hvipriosSort_36_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_2223 & hvipriosSort_37_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_2224
    & (ipriosTmp_result_rightIprio_leftIprio_sel_2225 & hvipriosSort_36_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2227 & hvipriosSort_37_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2231 & hvipriosSort_36_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2236
       & (ipriosTmp_result_rightIprio_leftIprio_sel_2244
            ? hvipriosSort_36_isZero
            : hvipriosSort_37_isZero));
  wire        ipriosTmp_result_rightIprio_leftIprio_20_0_enable =
    ipriosTmp_result_rightIprio_leftIprio_sel_2221 & hvipriosSort_36_enable
    | ipriosTmp_result_rightIprio_leftIprio_sel_2223 & hvipriosSort_37_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_2224
    & (ipriosTmp_result_rightIprio_leftIprio_sel_2225 & hvipriosSort_36_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_2227 & hvipriosSort_37_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2231 & hvipriosSort_36_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_2236
       & (ipriosTmp_result_rightIprio_leftIprio_sel_2244
            ? hvipriosSort_36_enable
            : hvipriosSort_37_isZero));
  wire [5:0]  ipriosTmp_result_rightIprio_leftIprio_20_0_idx =
    (ipriosTmp_result_rightIprio_leftIprio_sel_2221 ? 6'h24 : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_2223 ? 6'h25 : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_2224
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_2225 ? 6'h24 : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_2227 ? 6'h25 : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_2231 ? 6'h24 : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_2236
                ? {5'h12, ~ipriosTmp_result_rightIprio_leftIprio_sel_2244}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2221 =
    hvipriosSort_38_isZero & ~hvipriosSort_39_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2223 =
    ~hvipriosSort_38_isZero & hvipriosSort_39_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2224 =
    hvipriosSort_38_isZero & hvipriosSort_39_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2225 =
    hvipriosSort_38_isZero & hvipriosSort_39_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2227 =
    hvipriosSort_38_isZero & ~hvipriosSort_39_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2231 =
    ~hvipriosSort_38_isZero & hvipriosSort_39_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2236 =
    ~hvipriosSort_38_isZero & ~hvipriosSort_39_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_20_0_isZero =
    ipriosTmp_result_rightIprio_rightIprio_sel_2221 & hvipriosSort_38_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_2223 & hvipriosSort_39_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_2224
    & (ipriosTmp_result_rightIprio_rightIprio_sel_2225 & hvipriosSort_38_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2227 & hvipriosSort_39_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2231 & hvipriosSort_38_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2236
       & hvipriosSort_38_isZero);
  wire        ipriosTmp_result_rightIprio_rightIprio_20_0_enable =
    ipriosTmp_result_rightIprio_rightIprio_sel_2221 & hvipriosSort_38_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_2223 & hvipriosSort_39_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_2224
    & (ipriosTmp_result_rightIprio_rightIprio_sel_2225 & hvipriosSort_38_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2227 & hvipriosSort_39_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2231 & hvipriosSort_38_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2236
       & hvipriosSort_38_isZero);
  wire [5:0]  ipriosTmp_result_rightIprio_rightIprio_20_0_idx =
    (ipriosTmp_result_rightIprio_rightIprio_sel_2221 ? 6'h26 : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_2223 ? 6'h27 : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_2224
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_2225 ? 6'h26 : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_2227 ? 6'h27 : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_2231 ? 6'h26 : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_2236 ? 6'h26 : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_sel_2221 =
    ipriosTmp_result_rightIprio_leftIprio_20_0_enable
    & ~ipriosTmp_result_rightIprio_rightIprio_20_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_2223 =
    ~ipriosTmp_result_rightIprio_leftIprio_20_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_20_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_2224 =
    ipriosTmp_result_rightIprio_leftIprio_20_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_20_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_2225 =
    ipriosTmp_result_rightIprio_leftIprio_20_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_20_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_2227 =
    ipriosTmp_result_rightIprio_leftIprio_20_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_20_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_2231 =
    ~ipriosTmp_result_rightIprio_leftIprio_20_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_20_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_2236 =
    ~ipriosTmp_result_rightIprio_leftIprio_20_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_20_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_2244 =
    (gGen_33 ? io_in_hviprio1_Prio15 : 8'h0) == 8'h0;
  wire        gGen_34 =
    ipriosTmp_result_rightIprio_sel_2221 & gGen_33
    | ipriosTmp_result_rightIprio_sel_2224
    & (ipriosTmp_result_rightIprio_sel_2225 & gGen_33
       | ipriosTmp_result_rightIprio_sel_2227
       & ~(ipriosTmp_result_rightIprio_leftIprio_20_0_idx[5]) & gGen_33
       | ipriosTmp_result_rightIprio_sel_2231
       & ipriosTmp_result_rightIprio_rightIprio_20_0_idx[5] & gGen_33
       | ipriosTmp_result_rightIprio_sel_2236
       & ipriosTmp_result_rightIprio_sel_2244 & gGen_33);
  wire [7:0]  ipriosTmp_result_rightIprio_20_0_prioNum =
    gGen_34 ? io_in_hviprio1_Prio15 : 8'h0;
  wire        ipriosTmp_result_rightIprio_20_0_isZero =
    ipriosTmp_result_rightIprio_sel_2221
    & ipriosTmp_result_rightIprio_leftIprio_20_0_isZero
    | ipriosTmp_result_rightIprio_sel_2223
    & ipriosTmp_result_rightIprio_rightIprio_20_0_isZero
    | ipriosTmp_result_rightIprio_sel_2224
    & (ipriosTmp_result_rightIprio_sel_2225
       & ipriosTmp_result_rightIprio_leftIprio_20_0_isZero
       | ipriosTmp_result_rightIprio_sel_2227
       & (ipriosTmp_result_rightIprio_leftIprio_20_0_idx[5]
            ? ipriosTmp_result_rightIprio_rightIprio_20_0_isZero
            : ipriosTmp_result_rightIprio_leftIprio_20_0_isZero)
       | ipriosTmp_result_rightIprio_sel_2231
       & (ipriosTmp_result_rightIprio_rightIprio_20_0_idx[5]
            ? ipriosTmp_result_rightIprio_leftIprio_20_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_20_0_isZero)
       | ipriosTmp_result_rightIprio_sel_2236
       & (ipriosTmp_result_rightIprio_sel_2244
            ? ipriosTmp_result_rightIprio_leftIprio_20_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_20_0_isZero));
  wire        ipriosTmp_result_rightIprio_20_0_enable =
    ipriosTmp_result_rightIprio_sel_2221
    & ipriosTmp_result_rightIprio_leftIprio_20_0_enable
    | ipriosTmp_result_rightIprio_sel_2223
    & ipriosTmp_result_rightIprio_rightIprio_20_0_enable
    | ipriosTmp_result_rightIprio_sel_2224
    & (ipriosTmp_result_rightIprio_sel_2225
       & ipriosTmp_result_rightIprio_leftIprio_20_0_enable
       | ipriosTmp_result_rightIprio_sel_2227
       & (ipriosTmp_result_rightIprio_leftIprio_20_0_idx[5]
            ? ipriosTmp_result_rightIprio_rightIprio_20_0_enable
            : ipriosTmp_result_rightIprio_leftIprio_20_0_enable)
       | ipriosTmp_result_rightIprio_sel_2231
       & (ipriosTmp_result_rightIprio_rightIprio_20_0_idx[5]
            ? ipriosTmp_result_rightIprio_leftIprio_20_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_20_0_enable)
       | ipriosTmp_result_rightIprio_sel_2236
       & (ipriosTmp_result_rightIprio_sel_2244
            ? ipriosTmp_result_rightIprio_leftIprio_20_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_20_0_enable));
  wire [5:0]  ipriosTmp_result_rightIprio_20_0_idx =
    (ipriosTmp_result_rightIprio_sel_2221
       ? ipriosTmp_result_rightIprio_leftIprio_20_0_idx
       : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_2223
         ? ipriosTmp_result_rightIprio_rightIprio_20_0_idx
         : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_2224
         ? (ipriosTmp_result_rightIprio_sel_2225
              ? ipriosTmp_result_rightIprio_leftIprio_20_0_idx
              : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_2227
                ? (ipriosTmp_result_rightIprio_leftIprio_20_0_idx[5]
                     ? ipriosTmp_result_rightIprio_rightIprio_20_0_idx
                     : ipriosTmp_result_rightIprio_leftIprio_20_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_2231
                ? (ipriosTmp_result_rightIprio_rightIprio_20_0_idx[5]
                     ? ipriosTmp_result_rightIprio_leftIprio_20_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_20_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_2236
                ? (ipriosTmp_result_rightIprio_sel_2244
                     ? ipriosTmp_result_rightIprio_leftIprio_20_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_20_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_sel_2221 =
    ipriosTmp_result_leftIprio_20_0_enable & ~ipriosTmp_result_rightIprio_20_0_enable;
  wire        ipriosTmp_result_sel_2223 =
    ~ipriosTmp_result_leftIprio_20_0_enable & ipriosTmp_result_rightIprio_20_0_enable;
  wire        ipriosTmp_result_sel_2224 =
    ipriosTmp_result_leftIprio_20_0_enable & ipriosTmp_result_rightIprio_20_0_enable;
  wire        ipriosTmp_result_sel_2225 =
    ipriosTmp_result_leftIprio_20_0_isZero & ipriosTmp_result_rightIprio_20_0_isZero;
  wire        ipriosTmp_result_sel_2227 =
    ipriosTmp_result_leftIprio_20_0_isZero & ~ipriosTmp_result_rightIprio_20_0_isZero;
  wire        ipriosTmp_result_sel_2231 =
    ~ipriosTmp_result_leftIprio_20_0_isZero & ipriosTmp_result_rightIprio_20_0_isZero;
  wire        ipriosTmp_result_sel_2236 =
    ~ipriosTmp_result_leftIprio_20_0_isZero & ~ipriosTmp_result_rightIprio_20_0_isZero;
  wire        ipriosTmp_result_sel_2244 =
    ipriosTmp_result_leftIprio_20_0_prioNum <= ipriosTmp_result_rightIprio_20_0_prioNum;
  wire        gGen_35 =
    ipriosTmp_result_sel_2225 & ipriosTmp_result_leftIprio_20_0_enable;
  wire        gGen_36 =
    ipriosTmp_result_sel_2221 & ipriosTmp_result_leftIprio_20_0_enable;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2332 =
    hvipriosSort_40_isZero & ~hvipriosSort_41_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2334 =
    ~hvipriosSort_40_isZero & hvipriosSort_41_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2335 =
    hvipriosSort_40_isZero & hvipriosSort_41_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2336 =
    hvipriosSort_40_isZero & hvipriosSort_41_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2338 =
    hvipriosSort_40_isZero & ~hvipriosSort_41_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2342 =
    ~hvipriosSort_40_isZero & hvipriosSort_41_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2347 =
    ~hvipriosSort_40_isZero & ~hvipriosSort_41_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_21_0_isZero =
    ipriosTmp_result_leftIprio_leftIprio_sel_2332 & hvipriosSort_40_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_2334 & hvipriosSort_41_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_2335
    & (ipriosTmp_result_leftIprio_leftIprio_sel_2336 & hvipriosSort_40_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2338 & hvipriosSort_41_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2342 & hvipriosSort_40_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2347 & hvipriosSort_40_isZero);
  wire        ipriosTmp_result_leftIprio_leftIprio_21_0_enable =
    ipriosTmp_result_leftIprio_leftIprio_sel_2332 & hvipriosSort_40_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_2334 & hvipriosSort_41_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_2335
    & (ipriosTmp_result_leftIprio_leftIprio_sel_2336 & hvipriosSort_40_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2338 & hvipriosSort_41_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2342 & hvipriosSort_40_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2347 & hvipriosSort_40_isZero);
  wire [5:0]  ipriosTmp_result_leftIprio_leftIprio_21_0_idx =
    (ipriosTmp_result_leftIprio_leftIprio_sel_2332 ? 6'h28 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_2334 ? 6'h29 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_2335
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_2336 ? 6'h28 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_2338 ? 6'h29 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_2342 ? 6'h28 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_2347 ? 6'h28 : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2332 =
    hvipriosSort_42_isZero & ~hvipriosSort_43_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2334 =
    ~hvipriosSort_42_isZero & hvipriosSort_43_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2335 =
    hvipriosSort_42_isZero & hvipriosSort_43_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2336 =
    hvipriosSort_42_isZero & hvipriosSort_43_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2338 =
    hvipriosSort_42_isZero & ~hvipriosSort_43_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2342 =
    ~hvipriosSort_42_isZero & hvipriosSort_43_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2347 =
    ~hvipriosSort_42_isZero & ~hvipriosSort_43_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_21_0_isZero =
    ipriosTmp_result_leftIprio_rightIprio_sel_2332 & hvipriosSort_42_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_2334 & hvipriosSort_43_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_2335
    & (ipriosTmp_result_leftIprio_rightIprio_sel_2336 & hvipriosSort_42_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2338 & hvipriosSort_43_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2342 & hvipriosSort_42_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2347 & hvipriosSort_42_isZero);
  wire        ipriosTmp_result_leftIprio_rightIprio_21_0_enable =
    ipriosTmp_result_leftIprio_rightIprio_sel_2332 & hvipriosSort_42_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_2334 & hvipriosSort_43_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_2335
    & (ipriosTmp_result_leftIprio_rightIprio_sel_2336 & hvipriosSort_42_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2338 & hvipriosSort_43_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2342 & hvipriosSort_42_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2347 & hvipriosSort_42_isZero);
  wire [5:0]  ipriosTmp_result_leftIprio_rightIprio_21_0_idx =
    (ipriosTmp_result_leftIprio_rightIprio_sel_2332 ? 6'h2A : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_2334 ? 6'h2B : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_2335
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_2336 ? 6'h2A : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_2338 ? 6'h2B : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_2342 ? 6'h2A : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_2347 ? 6'h2A : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_sel_2332 =
    ipriosTmp_result_leftIprio_leftIprio_21_0_enable
    & ~ipriosTmp_result_leftIprio_rightIprio_21_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_2334 =
    ~ipriosTmp_result_leftIprio_leftIprio_21_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_21_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_2335 =
    ipriosTmp_result_leftIprio_leftIprio_21_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_21_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_2336 =
    ipriosTmp_result_leftIprio_leftIprio_21_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_21_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_2338 =
    ipriosTmp_result_leftIprio_leftIprio_21_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_21_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_2342 =
    ~ipriosTmp_result_leftIprio_leftIprio_21_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_21_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_2347 =
    ~ipriosTmp_result_leftIprio_leftIprio_21_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_21_0_isZero;
  wire        ipriosTmp_result_leftIprio_21_0_isZero =
    ipriosTmp_result_leftIprio_sel_2332
    & ipriosTmp_result_leftIprio_leftIprio_21_0_isZero
    | ipriosTmp_result_leftIprio_sel_2334
    & ipriosTmp_result_leftIprio_rightIprio_21_0_isZero
    | ipriosTmp_result_leftIprio_sel_2335
    & (ipriosTmp_result_leftIprio_sel_2336
       & ipriosTmp_result_leftIprio_leftIprio_21_0_isZero
       | ipriosTmp_result_leftIprio_sel_2338
       & (ipriosTmp_result_leftIprio_leftIprio_21_0_idx[5]
            ? ipriosTmp_result_leftIprio_rightIprio_21_0_isZero
            : ipriosTmp_result_leftIprio_leftIprio_21_0_isZero)
       | ipriosTmp_result_leftIprio_sel_2342
       & (ipriosTmp_result_leftIprio_rightIprio_21_0_idx[5]
            ? ipriosTmp_result_leftIprio_leftIprio_21_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_21_0_isZero)
       | ipriosTmp_result_leftIprio_sel_2347
       & ipriosTmp_result_leftIprio_leftIprio_21_0_isZero);
  wire        ipriosTmp_result_leftIprio_21_0_enable =
    ipriosTmp_result_leftIprio_sel_2332
    & ipriosTmp_result_leftIprio_leftIprio_21_0_enable
    | ipriosTmp_result_leftIprio_sel_2334
    & ipriosTmp_result_leftIprio_rightIprio_21_0_enable
    | ipriosTmp_result_leftIprio_sel_2335
    & (ipriosTmp_result_leftIprio_sel_2336
       & ipriosTmp_result_leftIprio_leftIprio_21_0_enable
       | ipriosTmp_result_leftIprio_sel_2338
       & (ipriosTmp_result_leftIprio_leftIprio_21_0_idx[5]
            ? ipriosTmp_result_leftIprio_rightIprio_21_0_enable
            : ipriosTmp_result_leftIprio_leftIprio_21_0_enable)
       | ipriosTmp_result_leftIprio_sel_2342
       & (ipriosTmp_result_leftIprio_rightIprio_21_0_idx[5]
            ? ipriosTmp_result_leftIprio_leftIprio_21_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_21_0_enable)
       | ipriosTmp_result_leftIprio_sel_2347
       & ipriosTmp_result_leftIprio_leftIprio_21_0_enable);
  wire [5:0]  ipriosTmp_result_leftIprio_21_0_idx =
    (ipriosTmp_result_leftIprio_sel_2332
       ? ipriosTmp_result_leftIprio_leftIprio_21_0_idx
       : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_2334
         ? ipriosTmp_result_leftIprio_rightIprio_21_0_idx
         : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_2335
         ? (ipriosTmp_result_leftIprio_sel_2336
              ? ipriosTmp_result_leftIprio_leftIprio_21_0_idx
              : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_2338
                ? (ipriosTmp_result_leftIprio_leftIprio_21_0_idx[5]
                     ? ipriosTmp_result_leftIprio_rightIprio_21_0_idx
                     : ipriosTmp_result_leftIprio_leftIprio_21_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_2342
                ? (ipriosTmp_result_leftIprio_rightIprio_21_0_idx[5]
                     ? ipriosTmp_result_leftIprio_leftIprio_21_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_21_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_2347
                ? ipriosTmp_result_leftIprio_leftIprio_21_0_idx
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2332 =
    hvipriosSort_44_enable & ~hvipriosSort_45_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2334 =
    ~hvipriosSort_44_enable & hvipriosSort_45_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2335 =
    hvipriosSort_44_enable & hvipriosSort_45_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2336 =
    hvipriosSort_44_isZero & hvipriosSort_45_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2338 =
    hvipriosSort_44_isZero & ~hvipriosSort_45_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2342 =
    ~hvipriosSort_44_isZero & hvipriosSort_45_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2347 =
    ~hvipriosSort_44_isZero & ~hvipriosSort_45_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2355 =
    (hvipriosSort_44_enable ? io_in_hviprio2_ALL[31:24] : 8'h0) == 8'h0;
  wire        gGen_37 =
    ipriosTmp_result_rightIprio_leftIprio_sel_2332 & hvipriosSort_44_enable
    | ipriosTmp_result_rightIprio_leftIprio_sel_2335
    & (ipriosTmp_result_rightIprio_leftIprio_sel_2336 & hvipriosSort_44_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_2342 & hvipriosSort_44_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_2347
       & ipriosTmp_result_rightIprio_leftIprio_sel_2355 & hvipriosSort_44_enable);
  wire [7:0]  ipriosTmp_result_rightIprio_leftIprio_21_0_prioNum =
    gGen_37 ? io_in_hviprio2_ALL[31:24] : 8'h0;
  wire        ipriosTmp_result_rightIprio_leftIprio_21_0_isZero =
    ipriosTmp_result_rightIprio_leftIprio_sel_2332 & hvipriosSort_44_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_2334 & hvipriosSort_45_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_2335
    & (ipriosTmp_result_rightIprio_leftIprio_sel_2336 & hvipriosSort_44_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2338 & hvipriosSort_45_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2342 & hvipriosSort_44_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2347
       & (ipriosTmp_result_rightIprio_leftIprio_sel_2355
            ? hvipriosSort_44_isZero
            : hvipriosSort_45_isZero));
  wire        ipriosTmp_result_rightIprio_leftIprio_21_0_enable =
    ipriosTmp_result_rightIprio_leftIprio_sel_2332 & hvipriosSort_44_enable
    | ipriosTmp_result_rightIprio_leftIprio_sel_2334 & hvipriosSort_45_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_2335
    & (ipriosTmp_result_rightIprio_leftIprio_sel_2336 & hvipriosSort_44_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_2338 & hvipriosSort_45_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2342 & hvipriosSort_44_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_2347
       & (ipriosTmp_result_rightIprio_leftIprio_sel_2355
            ? hvipriosSort_44_enable
            : hvipriosSort_45_isZero));
  wire [5:0]  ipriosTmp_result_rightIprio_leftIprio_21_0_idx =
    (ipriosTmp_result_rightIprio_leftIprio_sel_2332 ? 6'h2C : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_2334 ? 6'h2D : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_2335
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_2336 ? 6'h2C : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_2338 ? 6'h2D : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_2342 ? 6'h2C : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_2347
                ? {5'h16, ~ipriosTmp_result_rightIprio_leftIprio_sel_2355}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2332 =
    hvipriosSort_46_isZero & ~hvipriosSort_47_enable;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2334 =
    ~hvipriosSort_46_isZero & hvipriosSort_47_enable;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2335 =
    hvipriosSort_46_isZero & hvipriosSort_47_enable;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2336 =
    hvipriosSort_46_isZero & hvipriosSort_47_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2338 =
    hvipriosSort_46_isZero & ~hvipriosSort_47_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2342 =
    ~hvipriosSort_46_isZero & hvipriosSort_47_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2347 =
    ~hvipriosSort_46_isZero & ~hvipriosSort_47_isZero;
  wire        gGen_38 =
    ipriosTmp_result_rightIprio_rightIprio_sel_2334 & hvipriosSort_47_enable
    | ipriosTmp_result_rightIprio_rightIprio_sel_2335
    & ipriosTmp_result_rightIprio_rightIprio_sel_2338 & hvipriosSort_47_enable;
  wire [7:0]  ipriosTmp_result_rightIprio_rightIprio_21_0_prioNum =
    gGen_38 ? io_in_hviprio2_ALL[23:16] : 8'h0;
  wire        ipriosTmp_result_rightIprio_rightIprio_21_0_isZero =
    ipriosTmp_result_rightIprio_rightIprio_sel_2332 & hvipriosSort_46_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_2334 & hvipriosSort_47_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_2335
    & (ipriosTmp_result_rightIprio_rightIprio_sel_2336 & hvipriosSort_46_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2338 & hvipriosSort_47_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2342 & hvipriosSort_46_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2347
       & hvipriosSort_46_isZero);
  wire        ipriosTmp_result_rightIprio_rightIprio_21_0_enable =
    ipriosTmp_result_rightIprio_rightIprio_sel_2332 & hvipriosSort_46_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_2334 & hvipriosSort_47_enable
    | ipriosTmp_result_rightIprio_rightIprio_sel_2335
    & (ipriosTmp_result_rightIprio_rightIprio_sel_2336 & hvipriosSort_46_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2338 & hvipriosSort_47_enable
       | ipriosTmp_result_rightIprio_rightIprio_sel_2342 & hvipriosSort_46_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2347
       & hvipriosSort_46_isZero);
  wire [5:0]  ipriosTmp_result_rightIprio_rightIprio_21_0_idx =
    (ipriosTmp_result_rightIprio_rightIprio_sel_2332 ? 6'h2E : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_2334 ? 6'h2F : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_2335
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_2336 ? 6'h2E : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_2338 ? 6'h2F : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_2342 ? 6'h2E : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_2347 ? 6'h2E : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_sel_2332 =
    ipriosTmp_result_rightIprio_leftIprio_21_0_enable
    & ~ipriosTmp_result_rightIprio_rightIprio_21_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_2334 =
    ~ipriosTmp_result_rightIprio_leftIprio_21_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_21_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_2335 =
    ipriosTmp_result_rightIprio_leftIprio_21_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_21_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_2336 =
    ipriosTmp_result_rightIprio_leftIprio_21_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_21_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_2338 =
    ipriosTmp_result_rightIprio_leftIprio_21_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_21_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_2342 =
    ~ipriosTmp_result_rightIprio_leftIprio_21_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_21_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_2347 =
    ~ipriosTmp_result_rightIprio_leftIprio_21_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_21_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_2355 =
    ipriosTmp_result_rightIprio_leftIprio_21_0_prioNum <= ipriosTmp_result_rightIprio_rightIprio_21_0_prioNum;
  wire        ipriosTmp_result_rightIprio_21_0_isZero =
    ipriosTmp_result_rightIprio_sel_2332
    & ipriosTmp_result_rightIprio_leftIprio_21_0_isZero
    | ipriosTmp_result_rightIprio_sel_2334
    & ipriosTmp_result_rightIprio_rightIprio_21_0_isZero
    | ipriosTmp_result_rightIprio_sel_2335
    & (ipriosTmp_result_rightIprio_sel_2336
       & ipriosTmp_result_rightIprio_leftIprio_21_0_isZero
       | ipriosTmp_result_rightIprio_sel_2338
       & (ipriosTmp_result_rightIprio_leftIprio_21_0_idx[5]
            ? ipriosTmp_result_rightIprio_rightIprio_21_0_isZero
            : ipriosTmp_result_rightIprio_leftIprio_21_0_isZero)
       | ipriosTmp_result_rightIprio_sel_2342
       & (ipriosTmp_result_rightIprio_rightIprio_21_0_idx[5]
            ? ipriosTmp_result_rightIprio_leftIprio_21_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_21_0_isZero)
       | ipriosTmp_result_rightIprio_sel_2347
       & (ipriosTmp_result_rightIprio_sel_2355
            ? ipriosTmp_result_rightIprio_leftIprio_21_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_21_0_isZero));
  wire        ipriosTmp_result_rightIprio_21_0_enable =
    ipriosTmp_result_rightIprio_sel_2332
    & ipriosTmp_result_rightIprio_leftIprio_21_0_enable
    | ipriosTmp_result_rightIprio_sel_2334
    & ipriosTmp_result_rightIprio_rightIprio_21_0_enable
    | ipriosTmp_result_rightIprio_sel_2335
    & (ipriosTmp_result_rightIprio_sel_2336
       & ipriosTmp_result_rightIprio_leftIprio_21_0_enable
       | ipriosTmp_result_rightIprio_sel_2338
       & (ipriosTmp_result_rightIprio_leftIprio_21_0_idx[5]
            ? ipriosTmp_result_rightIprio_rightIprio_21_0_enable
            : ipriosTmp_result_rightIprio_leftIprio_21_0_enable)
       | ipriosTmp_result_rightIprio_sel_2342
       & (ipriosTmp_result_rightIprio_rightIprio_21_0_idx[5]
            ? ipriosTmp_result_rightIprio_leftIprio_21_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_21_0_enable)
       | ipriosTmp_result_rightIprio_sel_2347
       & (ipriosTmp_result_rightIprio_sel_2355
            ? ipriosTmp_result_rightIprio_leftIprio_21_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_21_0_enable));
  wire [5:0]  ipriosTmp_result_rightIprio_21_0_idx =
    (ipriosTmp_result_rightIprio_sel_2332
       ? ipriosTmp_result_rightIprio_leftIprio_21_0_idx
       : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_2334
         ? ipriosTmp_result_rightIprio_rightIprio_21_0_idx
         : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_2335
         ? (ipriosTmp_result_rightIprio_sel_2336
              ? ipriosTmp_result_rightIprio_leftIprio_21_0_idx
              : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_2338
                ? (ipriosTmp_result_rightIprio_leftIprio_21_0_idx[5]
                     ? ipriosTmp_result_rightIprio_rightIprio_21_0_idx
                     : ipriosTmp_result_rightIprio_leftIprio_21_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_2342
                ? (ipriosTmp_result_rightIprio_rightIprio_21_0_idx[5]
                     ? ipriosTmp_result_rightIprio_leftIprio_21_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_21_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_2347
                ? (ipriosTmp_result_rightIprio_sel_2355
                     ? ipriosTmp_result_rightIprio_leftIprio_21_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_21_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_sel_2332 =
    ipriosTmp_result_leftIprio_21_0_enable & ~ipriosTmp_result_rightIprio_21_0_enable;
  wire        ipriosTmp_result_sel_2334 =
    ~ipriosTmp_result_leftIprio_21_0_enable & ipriosTmp_result_rightIprio_21_0_enable;
  wire        ipriosTmp_result_sel_2335 =
    ipriosTmp_result_leftIprio_21_0_enable & ipriosTmp_result_rightIprio_21_0_enable;
  wire        ipriosTmp_result_sel_2336 =
    ipriosTmp_result_leftIprio_21_0_isZero & ipriosTmp_result_rightIprio_21_0_isZero;
  wire        ipriosTmp_result_sel_2338 =
    ipriosTmp_result_leftIprio_21_0_isZero & ~ipriosTmp_result_rightIprio_21_0_isZero;
  wire        ipriosTmp_result_sel_2342 =
    ~ipriosTmp_result_leftIprio_21_0_isZero & ipriosTmp_result_rightIprio_21_0_isZero;
  wire        ipriosTmp_result_sel_2347 =
    ~ipriosTmp_result_leftIprio_21_0_isZero & ~ipriosTmp_result_rightIprio_21_0_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2443 =
    hvipriosSort_48_isZero & ~hvipriosSort_49_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2445 =
    ~hvipriosSort_48_isZero & hvipriosSort_49_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2446 =
    hvipriosSort_48_isZero & hvipriosSort_49_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2447 =
    hvipriosSort_48_isZero & hvipriosSort_49_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2449 =
    hvipriosSort_48_isZero & ~hvipriosSort_49_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2453 =
    ~hvipriosSort_48_isZero & hvipriosSort_49_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2458 =
    ~hvipriosSort_48_isZero & ~hvipriosSort_49_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_22_0_isZero =
    ipriosTmp_result_leftIprio_leftIprio_sel_2443 & hvipriosSort_48_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_2445 & hvipriosSort_49_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_2446
    & (ipriosTmp_result_leftIprio_leftIprio_sel_2447 & hvipriosSort_48_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2449 & hvipriosSort_49_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2453 & hvipriosSort_48_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2458 & hvipriosSort_48_isZero);
  wire        ipriosTmp_result_leftIprio_leftIprio_22_0_enable =
    ipriosTmp_result_leftIprio_leftIprio_sel_2443 & hvipriosSort_48_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_2445 & hvipriosSort_49_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_2446
    & (ipriosTmp_result_leftIprio_leftIprio_sel_2447 & hvipriosSort_48_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2449 & hvipriosSort_49_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2453 & hvipriosSort_48_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2458 & hvipriosSort_48_isZero);
  wire [5:0]  ipriosTmp_result_leftIprio_leftIprio_22_0_idx =
    (ipriosTmp_result_leftIprio_leftIprio_sel_2443 ? 6'h30 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_2445 ? 6'h31 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_2446
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_2447 ? 6'h30 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_2449 ? 6'h31 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_2453 ? 6'h30 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_2458 ? 6'h30 : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2443 =
    hvipriosSort_50_enable & ~hvipriosSort_51_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2445 =
    ~hvipriosSort_50_enable & hvipriosSort_51_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2446 =
    hvipriosSort_50_enable & hvipriosSort_51_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2447 =
    hvipriosSort_50_isZero & hvipriosSort_51_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2449 =
    hvipriosSort_50_isZero & ~hvipriosSort_51_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2453 =
    ~hvipriosSort_50_isZero & hvipriosSort_51_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2458 =
    ~hvipriosSort_50_isZero & ~hvipriosSort_51_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2466 =
    (hvipriosSort_50_enable ? io_in_hviprio2_ALL[15:8] : 8'h0) == 8'h0;
  wire        gGen_39 =
    ipriosTmp_result_leftIprio_rightIprio_sel_2443 & hvipriosSort_50_enable
    | ipriosTmp_result_leftIprio_rightIprio_sel_2446
    & (ipriosTmp_result_leftIprio_rightIprio_sel_2447 & hvipriosSort_50_enable
       | ipriosTmp_result_leftIprio_rightIprio_sel_2453 & hvipriosSort_50_enable
       | ipriosTmp_result_leftIprio_rightIprio_sel_2458
       & ipriosTmp_result_leftIprio_rightIprio_sel_2466 & hvipriosSort_50_enable);
  wire        ipriosTmp_result_leftIprio_rightIprio_22_0_isZero =
    ipriosTmp_result_leftIprio_rightIprio_sel_2443 & hvipriosSort_50_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_2445 & hvipriosSort_51_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_2446
    & (ipriosTmp_result_leftIprio_rightIprio_sel_2447 & hvipriosSort_50_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2449 & hvipriosSort_51_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2453 & hvipriosSort_50_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2458
       & (ipriosTmp_result_leftIprio_rightIprio_sel_2466
            ? hvipriosSort_50_isZero
            : hvipriosSort_51_isZero));
  wire        ipriosTmp_result_leftIprio_rightIprio_22_0_enable =
    ipriosTmp_result_leftIprio_rightIprio_sel_2443 & hvipriosSort_50_enable
    | ipriosTmp_result_leftIprio_rightIprio_sel_2445 & hvipriosSort_51_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_2446
    & (ipriosTmp_result_leftIprio_rightIprio_sel_2447 & hvipriosSort_50_enable
       | ipriosTmp_result_leftIprio_rightIprio_sel_2449 & hvipriosSort_51_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2453 & hvipriosSort_50_enable
       | ipriosTmp_result_leftIprio_rightIprio_sel_2458
       & (ipriosTmp_result_leftIprio_rightIprio_sel_2466
            ? hvipriosSort_50_enable
            : hvipriosSort_51_isZero));
  wire [5:0]  ipriosTmp_result_leftIprio_rightIprio_22_0_idx =
    (ipriosTmp_result_leftIprio_rightIprio_sel_2443 ? 6'h32 : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_2445 ? 6'h33 : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_2446
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_2447 ? 6'h32 : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_2449 ? 6'h33 : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_2453 ? 6'h32 : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_2458
                ? {5'h19, ~ipriosTmp_result_leftIprio_rightIprio_sel_2466}
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_sel_2443 =
    ipriosTmp_result_leftIprio_leftIprio_22_0_enable
    & ~ipriosTmp_result_leftIprio_rightIprio_22_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_2445 =
    ~ipriosTmp_result_leftIprio_leftIprio_22_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_22_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_2446 =
    ipriosTmp_result_leftIprio_leftIprio_22_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_22_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_2447 =
    ipriosTmp_result_leftIprio_leftIprio_22_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_22_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_2449 =
    ipriosTmp_result_leftIprio_leftIprio_22_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_22_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_2453 =
    ~ipriosTmp_result_leftIprio_leftIprio_22_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_22_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_2458 =
    ~ipriosTmp_result_leftIprio_leftIprio_22_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_22_0_isZero;
  wire        gGen_40 =
    ipriosTmp_result_leftIprio_sel_2445 & gGen_39
    | ipriosTmp_result_leftIprio_sel_2446
    & (ipriosTmp_result_leftIprio_sel_2449
       & ipriosTmp_result_leftIprio_leftIprio_22_0_idx[5] & gGen_39
       | ipriosTmp_result_leftIprio_sel_2453
       & ~(ipriosTmp_result_leftIprio_rightIprio_22_0_idx[5]) & gGen_39);
  wire [7:0]  ipriosTmp_result_leftIprio_22_0_prioNum =
    gGen_40 ? io_in_hviprio2_ALL[15:8] : 8'h0;
  wire        ipriosTmp_result_leftIprio_22_0_isZero =
    ipriosTmp_result_leftIprio_sel_2443
    & ipriosTmp_result_leftIprio_leftIprio_22_0_isZero
    | ipriosTmp_result_leftIprio_sel_2445
    & ipriosTmp_result_leftIprio_rightIprio_22_0_isZero
    | ipriosTmp_result_leftIprio_sel_2446
    & (ipriosTmp_result_leftIprio_sel_2447
       & ipriosTmp_result_leftIprio_leftIprio_22_0_isZero
       | ipriosTmp_result_leftIprio_sel_2449
       & (ipriosTmp_result_leftIprio_leftIprio_22_0_idx[5]
            ? ipriosTmp_result_leftIprio_rightIprio_22_0_isZero
            : ipriosTmp_result_leftIprio_leftIprio_22_0_isZero)
       | ipriosTmp_result_leftIprio_sel_2453
       & (ipriosTmp_result_leftIprio_rightIprio_22_0_idx[5]
            ? ipriosTmp_result_leftIprio_leftIprio_22_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_22_0_isZero)
       | ipriosTmp_result_leftIprio_sel_2458
       & ipriosTmp_result_leftIprio_leftIprio_22_0_isZero);
  wire        ipriosTmp_result_leftIprio_22_0_enable =
    ipriosTmp_result_leftIprio_sel_2443
    & ipriosTmp_result_leftIprio_leftIprio_22_0_enable
    | ipriosTmp_result_leftIprio_sel_2445
    & ipriosTmp_result_leftIprio_rightIprio_22_0_enable
    | ipriosTmp_result_leftIprio_sel_2446
    & (ipriosTmp_result_leftIprio_sel_2447
       & ipriosTmp_result_leftIprio_leftIprio_22_0_enable
       | ipriosTmp_result_leftIprio_sel_2449
       & (ipriosTmp_result_leftIprio_leftIprio_22_0_idx[5]
            ? ipriosTmp_result_leftIprio_rightIprio_22_0_enable
            : ipriosTmp_result_leftIprio_leftIprio_22_0_enable)
       | ipriosTmp_result_leftIprio_sel_2453
       & (ipriosTmp_result_leftIprio_rightIprio_22_0_idx[5]
            ? ipriosTmp_result_leftIprio_leftIprio_22_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_22_0_enable)
       | ipriosTmp_result_leftIprio_sel_2458
       & ipriosTmp_result_leftIprio_leftIprio_22_0_enable);
  wire [5:0]  ipriosTmp_result_leftIprio_22_0_idx =
    (ipriosTmp_result_leftIprio_sel_2443
       ? ipriosTmp_result_leftIprio_leftIprio_22_0_idx
       : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_2445
         ? ipriosTmp_result_leftIprio_rightIprio_22_0_idx
         : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_2446
         ? (ipriosTmp_result_leftIprio_sel_2447
              ? ipriosTmp_result_leftIprio_leftIprio_22_0_idx
              : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_2449
                ? (ipriosTmp_result_leftIprio_leftIprio_22_0_idx[5]
                     ? ipriosTmp_result_leftIprio_rightIprio_22_0_idx
                     : ipriosTmp_result_leftIprio_leftIprio_22_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_2453
                ? (ipriosTmp_result_leftIprio_rightIprio_22_0_idx[5]
                     ? ipriosTmp_result_leftIprio_leftIprio_22_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_22_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_2458
                ? ipriosTmp_result_leftIprio_leftIprio_22_0_idx
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2443 =
    hvipriosSort_52_isZero & ~hvipriosSort_53_enable;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2445 =
    ~hvipriosSort_52_isZero & hvipriosSort_53_enable;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2446 =
    hvipriosSort_52_isZero & hvipriosSort_53_enable;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2447 =
    hvipriosSort_52_isZero & hvipriosSort_53_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2449 =
    hvipriosSort_52_isZero & ~hvipriosSort_53_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2453 =
    ~hvipriosSort_52_isZero & hvipriosSort_53_isZero;
  wire        ipriosTmp_result_rightIprio_leftIprio_sel_2458 =
    ~hvipriosSort_52_isZero & ~hvipriosSort_53_isZero;
  wire        gGen_41 =
    ipriosTmp_result_rightIprio_leftIprio_sel_2445 & hvipriosSort_53_enable
    | ipriosTmp_result_rightIprio_leftIprio_sel_2446
    & ipriosTmp_result_rightIprio_leftIprio_sel_2449 & hvipriosSort_53_enable;
  wire        ipriosTmp_result_rightIprio_leftIprio_22_0_isZero =
    ipriosTmp_result_rightIprio_leftIprio_sel_2443 & hvipriosSort_52_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_2445 & hvipriosSort_53_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_2446
    & (ipriosTmp_result_rightIprio_leftIprio_sel_2447 & hvipriosSort_52_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2449 & hvipriosSort_53_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2453 & hvipriosSort_52_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2458 & hvipriosSort_52_isZero);
  wire        ipriosTmp_result_rightIprio_leftIprio_22_0_enable =
    ipriosTmp_result_rightIprio_leftIprio_sel_2443 & hvipriosSort_52_isZero
    | ipriosTmp_result_rightIprio_leftIprio_sel_2445 & hvipriosSort_53_enable
    | ipriosTmp_result_rightIprio_leftIprio_sel_2446
    & (ipriosTmp_result_rightIprio_leftIprio_sel_2447 & hvipriosSort_52_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2449 & hvipriosSort_53_enable
       | ipriosTmp_result_rightIprio_leftIprio_sel_2453 & hvipriosSort_52_isZero
       | ipriosTmp_result_rightIprio_leftIprio_sel_2458 & hvipriosSort_52_isZero);
  wire [5:0]  ipriosTmp_result_rightIprio_leftIprio_22_0_idx =
    (ipriosTmp_result_rightIprio_leftIprio_sel_2443 ? 6'h34 : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_2445 ? 6'h35 : 6'h0)
    | (ipriosTmp_result_rightIprio_leftIprio_sel_2446
         ? (ipriosTmp_result_rightIprio_leftIprio_sel_2447 ? 6'h34 : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_2449 ? 6'h35 : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_2453 ? 6'h34 : 6'h0)
           | (ipriosTmp_result_rightIprio_leftIprio_sel_2458 ? 6'h34 : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2443 =
    hvipriosSort_54_isZero & ~hvipriosSort_55_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2445 =
    ~hvipriosSort_54_isZero & hvipriosSort_55_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2446 =
    hvipriosSort_54_isZero & hvipriosSort_55_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2447 =
    hvipriosSort_54_isZero & hvipriosSort_55_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2449 =
    hvipriosSort_54_isZero & ~hvipriosSort_55_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2453 =
    ~hvipriosSort_54_isZero & hvipriosSort_55_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_sel_2458 =
    ~hvipriosSort_54_isZero & ~hvipriosSort_55_isZero;
  wire        ipriosTmp_result_rightIprio_rightIprio_22_0_isZero =
    ipriosTmp_result_rightIprio_rightIprio_sel_2443 & hvipriosSort_54_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_2445 & hvipriosSort_55_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_2446
    & (ipriosTmp_result_rightIprio_rightIprio_sel_2447 & hvipriosSort_54_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2449 & hvipriosSort_55_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2453 & hvipriosSort_54_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2458
       & hvipriosSort_54_isZero);
  wire        ipriosTmp_result_rightIprio_rightIprio_22_0_enable =
    ipriosTmp_result_rightIprio_rightIprio_sel_2443 & hvipriosSort_54_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_2445 & hvipriosSort_55_isZero
    | ipriosTmp_result_rightIprio_rightIprio_sel_2446
    & (ipriosTmp_result_rightIprio_rightIprio_sel_2447 & hvipriosSort_54_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2449 & hvipriosSort_55_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2453 & hvipriosSort_54_isZero
       | ipriosTmp_result_rightIprio_rightIprio_sel_2458
       & hvipriosSort_54_isZero);
  wire [5:0]  ipriosTmp_result_rightIprio_rightIprio_22_0_idx =
    (ipriosTmp_result_rightIprio_rightIprio_sel_2443 ? 6'h36 : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_2445 ? 6'h37 : 6'h0)
    | (ipriosTmp_result_rightIprio_rightIprio_sel_2446
         ? (ipriosTmp_result_rightIprio_rightIprio_sel_2447 ? 6'h36 : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_2449 ? 6'h37 : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_2453 ? 6'h36 : 6'h0)
           | (ipriosTmp_result_rightIprio_rightIprio_sel_2458 ? 6'h36 : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_rightIprio_sel_2443 =
    ipriosTmp_result_rightIprio_leftIprio_22_0_enable
    & ~ipriosTmp_result_rightIprio_rightIprio_22_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_2445 =
    ~ipriosTmp_result_rightIprio_leftIprio_22_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_22_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_2446 =
    ipriosTmp_result_rightIprio_leftIprio_22_0_enable
    & ipriosTmp_result_rightIprio_rightIprio_22_0_enable;
  wire        ipriosTmp_result_rightIprio_sel_2447 =
    ipriosTmp_result_rightIprio_leftIprio_22_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_22_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_2449 =
    ipriosTmp_result_rightIprio_leftIprio_22_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_22_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_2453 =
    ~ipriosTmp_result_rightIprio_leftIprio_22_0_isZero
    & ipriosTmp_result_rightIprio_rightIprio_22_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_2458 =
    ~ipriosTmp_result_rightIprio_leftIprio_22_0_isZero
    & ~ipriosTmp_result_rightIprio_rightIprio_22_0_isZero;
  wire        ipriosTmp_result_rightIprio_sel_2466 =
    (gGen_41 ? io_in_hviprio2_ALL[7:0] : 8'h0) == 8'h0;
  wire        gGen_42 =
    ipriosTmp_result_rightIprio_sel_2443 & gGen_41
    | ipriosTmp_result_rightIprio_sel_2446
    & (ipriosTmp_result_rightIprio_sel_2447 & gGen_41
       | ipriosTmp_result_rightIprio_sel_2449
       & ~(ipriosTmp_result_rightIprio_leftIprio_22_0_idx[5]) & gGen_41
       | ipriosTmp_result_rightIprio_sel_2453
       & ipriosTmp_result_rightIprio_rightIprio_22_0_idx[5] & gGen_41
       | ipriosTmp_result_rightIprio_sel_2458
       & ipriosTmp_result_rightIprio_sel_2466 & gGen_41);
  wire [7:0]  ipriosTmp_result_rightIprio_22_0_prioNum =
    gGen_42 ? io_in_hviprio2_ALL[7:0] : 8'h0;
  wire        ipriosTmp_result_rightIprio_22_0_isZero =
    ipriosTmp_result_rightIprio_sel_2443
    & ipriosTmp_result_rightIprio_leftIprio_22_0_isZero
    | ipriosTmp_result_rightIprio_sel_2445
    & ipriosTmp_result_rightIprio_rightIprio_22_0_isZero
    | ipriosTmp_result_rightIprio_sel_2446
    & (ipriosTmp_result_rightIprio_sel_2447
       & ipriosTmp_result_rightIprio_leftIprio_22_0_isZero
       | ipriosTmp_result_rightIprio_sel_2449
       & (ipriosTmp_result_rightIprio_leftIprio_22_0_idx[5]
            ? ipriosTmp_result_rightIprio_rightIprio_22_0_isZero
            : ipriosTmp_result_rightIprio_leftIprio_22_0_isZero)
       | ipriosTmp_result_rightIprio_sel_2453
       & (ipriosTmp_result_rightIprio_rightIprio_22_0_idx[5]
            ? ipriosTmp_result_rightIprio_leftIprio_22_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_22_0_isZero)
       | ipriosTmp_result_rightIprio_sel_2458
       & (ipriosTmp_result_rightIprio_sel_2466
            ? ipriosTmp_result_rightIprio_leftIprio_22_0_isZero
            : ipriosTmp_result_rightIprio_rightIprio_22_0_isZero));
  wire        ipriosTmp_result_rightIprio_22_0_enable =
    ipriosTmp_result_rightIprio_sel_2443
    & ipriosTmp_result_rightIprio_leftIprio_22_0_enable
    | ipriosTmp_result_rightIprio_sel_2445
    & ipriosTmp_result_rightIprio_rightIprio_22_0_enable
    | ipriosTmp_result_rightIprio_sel_2446
    & (ipriosTmp_result_rightIprio_sel_2447
       & ipriosTmp_result_rightIprio_leftIprio_22_0_enable
       | ipriosTmp_result_rightIprio_sel_2449
       & (ipriosTmp_result_rightIprio_leftIprio_22_0_idx[5]
            ? ipriosTmp_result_rightIprio_rightIprio_22_0_enable
            : ipriosTmp_result_rightIprio_leftIprio_22_0_enable)
       | ipriosTmp_result_rightIprio_sel_2453
       & (ipriosTmp_result_rightIprio_rightIprio_22_0_idx[5]
            ? ipriosTmp_result_rightIprio_leftIprio_22_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_22_0_enable)
       | ipriosTmp_result_rightIprio_sel_2458
       & (ipriosTmp_result_rightIprio_sel_2466
            ? ipriosTmp_result_rightIprio_leftIprio_22_0_enable
            : ipriosTmp_result_rightIprio_rightIprio_22_0_enable));
  wire [5:0]  ipriosTmp_result_rightIprio_22_0_idx =
    (ipriosTmp_result_rightIprio_sel_2443
       ? ipriosTmp_result_rightIprio_leftIprio_22_0_idx
       : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_2445
         ? ipriosTmp_result_rightIprio_rightIprio_22_0_idx
         : 6'h0)
    | (ipriosTmp_result_rightIprio_sel_2446
         ? (ipriosTmp_result_rightIprio_sel_2447
              ? ipriosTmp_result_rightIprio_leftIprio_22_0_idx
              : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_2449
                ? (ipriosTmp_result_rightIprio_leftIprio_22_0_idx[5]
                     ? ipriosTmp_result_rightIprio_rightIprio_22_0_idx
                     : ipriosTmp_result_rightIprio_leftIprio_22_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_2453
                ? (ipriosTmp_result_rightIprio_rightIprio_22_0_idx[5]
                     ? ipriosTmp_result_rightIprio_leftIprio_22_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_22_0_idx)
                : 6'h0)
           | (ipriosTmp_result_rightIprio_sel_2458
                ? (ipriosTmp_result_rightIprio_sel_2466
                     ? ipriosTmp_result_rightIprio_leftIprio_22_0_idx
                     : ipriosTmp_result_rightIprio_rightIprio_22_0_idx)
                : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_sel_2443 =
    ipriosTmp_result_leftIprio_22_0_enable & ~ipriosTmp_result_rightIprio_22_0_enable;
  wire        ipriosTmp_result_sel_2445 =
    ~ipriosTmp_result_leftIprio_22_0_enable & ipriosTmp_result_rightIprio_22_0_enable;
  wire        ipriosTmp_result_sel_2446 =
    ipriosTmp_result_leftIprio_22_0_enable & ipriosTmp_result_rightIprio_22_0_enable;
  wire        ipriosTmp_result_sel_2447 =
    ipriosTmp_result_leftIprio_22_0_isZero & ipriosTmp_result_rightIprio_22_0_isZero;
  wire        ipriosTmp_result_sel_2449 =
    ipriosTmp_result_leftIprio_22_0_isZero & ~ipriosTmp_result_rightIprio_22_0_isZero;
  wire        ipriosTmp_result_sel_2453 =
    ~ipriosTmp_result_leftIprio_22_0_isZero & ipriosTmp_result_rightIprio_22_0_isZero;
  wire        ipriosTmp_result_sel_2458 =
    ~ipriosTmp_result_leftIprio_22_0_isZero & ~ipriosTmp_result_rightIprio_22_0_isZero;
  wire        ipriosTmp_result_sel_2466 =
    ipriosTmp_result_leftIprio_22_0_prioNum <= ipriosTmp_result_rightIprio_22_0_prioNum;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2554 =
    hvipriosSort_56_isZero & ~hvipriosSort_57_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2556 =
    ~hvipriosSort_56_isZero & hvipriosSort_57_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2557 =
    hvipriosSort_56_isZero & hvipriosSort_57_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2558 =
    hvipriosSort_56_isZero & hvipriosSort_57_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2560 =
    hvipriosSort_56_isZero & ~hvipriosSort_57_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2564 =
    ~hvipriosSort_56_isZero & hvipriosSort_57_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_sel_2569 =
    ~hvipriosSort_56_isZero & ~hvipriosSort_57_isZero;
  wire        ipriosTmp_result_leftIprio_leftIprio_23_0_isZero =
    ipriosTmp_result_leftIprio_leftIprio_sel_2554 & hvipriosSort_56_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_2556 & hvipriosSort_57_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_2557
    & (ipriosTmp_result_leftIprio_leftIprio_sel_2558 & hvipriosSort_56_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2560 & hvipriosSort_57_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2564 & hvipriosSort_56_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2569 & hvipriosSort_56_isZero);
  wire        ipriosTmp_result_leftIprio_leftIprio_23_0_enable =
    ipriosTmp_result_leftIprio_leftIprio_sel_2554 & hvipriosSort_56_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_2556 & hvipriosSort_57_isZero
    | ipriosTmp_result_leftIprio_leftIprio_sel_2557
    & (ipriosTmp_result_leftIprio_leftIprio_sel_2558 & hvipriosSort_56_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2560 & hvipriosSort_57_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2564 & hvipriosSort_56_isZero
       | ipriosTmp_result_leftIprio_leftIprio_sel_2569 & hvipriosSort_56_isZero);
  wire [5:0]  ipriosTmp_result_leftIprio_leftIprio_23_0_idx =
    (ipriosTmp_result_leftIprio_leftIprio_sel_2554 ? 6'h38 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_2556 ? 6'h39 : 6'h0)
    | (ipriosTmp_result_leftIprio_leftIprio_sel_2557
         ? (ipriosTmp_result_leftIprio_leftIprio_sel_2558 ? 6'h38 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_2560 ? 6'h39 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_2564 ? 6'h38 : 6'h0)
           | (ipriosTmp_result_leftIprio_leftIprio_sel_2569 ? 6'h38 : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2554 =
    hvipriosSort_58_isZero & ~hvipriosSort_59_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2556 =
    ~hvipriosSort_58_isZero & hvipriosSort_59_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2557 =
    hvipriosSort_58_isZero & hvipriosSort_59_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2558 =
    hvipriosSort_58_isZero & hvipriosSort_59_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2560 =
    hvipriosSort_58_isZero & ~hvipriosSort_59_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2564 =
    ~hvipriosSort_58_isZero & hvipriosSort_59_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_sel_2569 =
    ~hvipriosSort_58_isZero & ~hvipriosSort_59_isZero;
  wire        ipriosTmp_result_leftIprio_rightIprio_23_0_isZero =
    ipriosTmp_result_leftIprio_rightIprio_sel_2554 & hvipriosSort_58_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_2556 & hvipriosSort_59_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_2557
    & (ipriosTmp_result_leftIprio_rightIprio_sel_2558 & hvipriosSort_58_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2560 & hvipriosSort_59_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2564 & hvipriosSort_58_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2569 & hvipriosSort_58_isZero);
  wire        ipriosTmp_result_leftIprio_rightIprio_23_0_enable =
    ipriosTmp_result_leftIprio_rightIprio_sel_2554 & hvipriosSort_58_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_2556 & hvipriosSort_59_isZero
    | ipriosTmp_result_leftIprio_rightIprio_sel_2557
    & (ipriosTmp_result_leftIprio_rightIprio_sel_2558 & hvipriosSort_58_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2560 & hvipriosSort_59_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2564 & hvipriosSort_58_isZero
       | ipriosTmp_result_leftIprio_rightIprio_sel_2569 & hvipriosSort_58_isZero);
  wire [5:0]  ipriosTmp_result_leftIprio_rightIprio_23_0_idx =
    (ipriosTmp_result_leftIprio_rightIprio_sel_2554 ? 6'h3A : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_2556 ? 6'h3B : 6'h0)
    | (ipriosTmp_result_leftIprio_rightIprio_sel_2557
         ? (ipriosTmp_result_leftIprio_rightIprio_sel_2558 ? 6'h3A : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_2560 ? 6'h3B : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_2564 ? 6'h3A : 6'h0)
           | (ipriosTmp_result_leftIprio_rightIprio_sel_2569 ? 6'h3A : 6'h0)
         : 6'h0);
  wire        ipriosTmp_result_leftIprio_sel_2554 =
    ipriosTmp_result_leftIprio_leftIprio_23_0_enable
    & ~ipriosTmp_result_leftIprio_rightIprio_23_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_2556 =
    ~ipriosTmp_result_leftIprio_leftIprio_23_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_23_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_2557 =
    ipriosTmp_result_leftIprio_leftIprio_23_0_enable
    & ipriosTmp_result_leftIprio_rightIprio_23_0_enable;
  wire        ipriosTmp_result_leftIprio_sel_2558 =
    ipriosTmp_result_leftIprio_leftIprio_23_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_23_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_2560 =
    ipriosTmp_result_leftIprio_leftIprio_23_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_23_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_2564 =
    ~ipriosTmp_result_leftIprio_leftIprio_23_0_isZero
    & ipriosTmp_result_leftIprio_rightIprio_23_0_isZero;
  wire        ipriosTmp_result_leftIprio_sel_2569 =
    ~ipriosTmp_result_leftIprio_leftIprio_23_0_isZero
    & ~ipriosTmp_result_leftIprio_rightIprio_23_0_isZero;
  wire        ipriosTmp_result_leftIprio_23_0_isZero =
    ipriosTmp_result_leftIprio_sel_2554
    & ipriosTmp_result_leftIprio_leftIprio_23_0_isZero
    | ipriosTmp_result_leftIprio_sel_2556
    & ipriosTmp_result_leftIprio_rightIprio_23_0_isZero
    | ipriosTmp_result_leftIprio_sel_2557
    & (ipriosTmp_result_leftIprio_sel_2558
       & ipriosTmp_result_leftIprio_leftIprio_23_0_isZero
       | ipriosTmp_result_leftIprio_sel_2560
       & (ipriosTmp_result_leftIprio_leftIprio_23_0_idx[5]
            ? ipriosTmp_result_leftIprio_rightIprio_23_0_isZero
            : ipriosTmp_result_leftIprio_leftIprio_23_0_isZero)
       | ipriosTmp_result_leftIprio_sel_2564
       & (ipriosTmp_result_leftIprio_rightIprio_23_0_idx[5]
            ? ipriosTmp_result_leftIprio_leftIprio_23_0_isZero
            : ipriosTmp_result_leftIprio_rightIprio_23_0_isZero)
       | ipriosTmp_result_leftIprio_sel_2569
       & ipriosTmp_result_leftIprio_leftIprio_23_0_isZero);
  wire        ipriosTmp_result_leftIprio_23_0_enable =
    ipriosTmp_result_leftIprio_sel_2554
    & ipriosTmp_result_leftIprio_leftIprio_23_0_enable
    | ipriosTmp_result_leftIprio_sel_2556
    & ipriosTmp_result_leftIprio_rightIprio_23_0_enable
    | ipriosTmp_result_leftIprio_sel_2557
    & (ipriosTmp_result_leftIprio_sel_2558
       & ipriosTmp_result_leftIprio_leftIprio_23_0_enable
       | ipriosTmp_result_leftIprio_sel_2560
       & (ipriosTmp_result_leftIprio_leftIprio_23_0_idx[5]
            ? ipriosTmp_result_leftIprio_rightIprio_23_0_enable
            : ipriosTmp_result_leftIprio_leftIprio_23_0_enable)
       | ipriosTmp_result_leftIprio_sel_2564
       & (ipriosTmp_result_leftIprio_rightIprio_23_0_idx[5]
            ? ipriosTmp_result_leftIprio_leftIprio_23_0_enable
            : ipriosTmp_result_leftIprio_rightIprio_23_0_enable)
       | ipriosTmp_result_leftIprio_sel_2569
       & ipriosTmp_result_leftIprio_leftIprio_23_0_enable);
  wire [5:0]  ipriosTmp_result_leftIprio_23_0_idx =
    (ipriosTmp_result_leftIprio_sel_2554
       ? ipriosTmp_result_leftIprio_leftIprio_23_0_idx
       : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_2556
         ? ipriosTmp_result_leftIprio_rightIprio_23_0_idx
         : 6'h0)
    | (ipriosTmp_result_leftIprio_sel_2557
         ? (ipriosTmp_result_leftIprio_sel_2558
              ? ipriosTmp_result_leftIprio_leftIprio_23_0_idx
              : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_2560
                ? (ipriosTmp_result_leftIprio_leftIprio_23_0_idx[5]
                     ? ipriosTmp_result_leftIprio_rightIprio_23_0_idx
                     : ipriosTmp_result_leftIprio_leftIprio_23_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_2564
                ? (ipriosTmp_result_leftIprio_rightIprio_23_0_idx[5]
                     ? ipriosTmp_result_leftIprio_leftIprio_23_0_idx
                     : ipriosTmp_result_leftIprio_rightIprio_23_0_idx)
                : 6'h0)
           | (ipriosTmp_result_leftIprio_sel_2569
                ? ipriosTmp_result_leftIprio_leftIprio_23_0_idx
                : 6'h0)
         : 6'h0);
  wire [5:0]  ipriosTmp_result_rightIprio_23_0_idx =
    hvipriosSort_60_isZero ? 6'h3C : 6'h0;
  wire        ipriosTmp_result_sel_2554 =
    ipriosTmp_result_leftIprio_23_0_enable & ~hvipriosSort_60_isZero;
  wire        ipriosTmp_result_sel_2556 =
    ~ipriosTmp_result_leftIprio_23_0_enable & hvipriosSort_60_isZero;
  wire        ipriosTmp_result_sel_2557 =
    ipriosTmp_result_leftIprio_23_0_enable & hvipriosSort_60_isZero;
  wire        ipriosTmp_result_sel_2558 =
    ipriosTmp_result_leftIprio_23_0_isZero & hvipriosSort_60_isZero;
  wire        ipriosTmp_result_sel_2560 =
    ipriosTmp_result_leftIprio_23_0_isZero & ~hvipriosSort_60_isZero;
  wire        ipriosTmp_result_sel_2564 =
    ~ipriosTmp_result_leftIprio_23_0_isZero & hvipriosSort_60_isZero;
  wire        ipriosTmp_result_sel_2569 =
    ~ipriosTmp_result_leftIprio_23_0_isZero & ~hvipriosSort_60_isZero;
  always @(posedge clock) begin
    mipriosReg_0_idx <= 6'h0;
    mipriosReg_0_enable <= 1'h0;
    mipriosReg_0_isZero <= 1'h0;
    mipriosReg_0_prioNum <= 8'h0;
    mipriosReg_1_idx <= 6'h0;
    mipriosReg_1_enable <= 1'h0;
    mipriosReg_1_isZero <= 1'h0;
    mipriosReg_1_prioNum <= 8'h0;
    mipriosReg_2_idx <= 6'h0;
    mipriosReg_2_enable <= 1'h0;
    mipriosReg_2_isZero <= 1'h0;
    mipriosReg_2_prioNum <= 8'h0;
    mipriosReg_3_idx <=
      (ipriosTmp_result_sel_334 ? ipriosTmp_result_leftIprio_3_0_idx : 6'h0)
      | (gGen_23 ? ipriosTmp_result_rightIprio_leftIprio_3_0_idx : 6'h0)
      | (ipriosTmp_result_sel_337
           ? (ipriosTmp_result_sel_338
                ? ipriosTmp_result_leftIprio_3_0_idx
                : 6'h0)
             | (ipriosTmp_result_sel_340
                  ? (ipriosTmp_result_sel_341
                       ? ipriosTmp_result_leftIprio_3_0_idx
                       : ipriosTmp_result_rightIprio_3_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_344
                  ? (ipriosTmp_result_sel_345
                       ? ipriosTmp_result_rightIprio_3_0_idx
                       : ipriosTmp_result_leftIprio_3_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_349
                  ? (gGen_22 ? ipriosTmp_result_rightIprio_leftIprio_3_0_idx : 6'h0)
                    | (ipriosTmp_result_leftIprio_3_0_greaterThan255
                         ? 6'h0
                         : ipriosTmp_result_sel_357
                             ? ipriosTmp_result_leftIprio_3_0_idx
                             : ipriosTmp_result_rightIprio_3_0_idx)
                  : 6'h0)
           : 6'h0);
    mipriosReg_3_enable <=
      ipriosTmp_result_sel_334 & ipriosTmp_result_leftIprio_3_0_enable
      | ipriosTmp_result_sel_336 & ipriosTmp_result_rightIprio_3_0_enable
      | ipriosTmp_result_sel_337
      & (ipriosTmp_result_sel_338 & ipriosTmp_result_leftIprio_3_0_enable
         | ipriosTmp_result_sel_340
         & (ipriosTmp_result_sel_341
              ? ipriosTmp_result_leftIprio_3_0_enable
              : ipriosTmp_result_rightIprio_3_0_enable) | ipriosTmp_result_sel_344
         & (ipriosTmp_result_sel_345
              ? ipriosTmp_result_rightIprio_3_0_enable
              : ipriosTmp_result_leftIprio_3_0_enable) | ipriosTmp_result_sel_349
         & (ipriosTmp_result_leftIprio_3_0_greaterThan255
            & ipriosTmp_result_rightIprio_3_0_enable
            | ~ipriosTmp_result_leftIprio_3_0_greaterThan255
            & (ipriosTmp_result_sel_357
                 ? ipriosTmp_result_leftIprio_3_0_enable
                 : ipriosTmp_result_rightIprio_3_0_enable)));
    mipriosReg_3_isZero <=
      ipriosTmp_result_sel_334 & ipriosTmp_result_leftIprio_3_0_isZero
      | ipriosTmp_result_sel_336 & ipriosTmp_result_rightIprio_3_0_isZero
      | ipriosTmp_result_sel_337
      & (ipriosTmp_result_sel_338 & ipriosTmp_result_leftIprio_3_0_isZero
         | ipriosTmp_result_sel_340
         & (ipriosTmp_result_sel_341
              ? ipriosTmp_result_leftIprio_3_0_isZero
              : ipriosTmp_result_rightIprio_3_0_isZero) | ipriosTmp_result_sel_344
         & (ipriosTmp_result_sel_345
              ? ipriosTmp_result_rightIprio_3_0_isZero
              : ipriosTmp_result_leftIprio_3_0_isZero) | ipriosTmp_result_sel_349
         & (ipriosTmp_result_leftIprio_3_0_greaterThan255
            & ipriosTmp_result_rightIprio_3_0_isZero
            | ~ipriosTmp_result_leftIprio_3_0_greaterThan255
            & (ipriosTmp_result_sel_357
                 ? ipriosTmp_result_leftIprio_3_0_isZero
                 : ipriosTmp_result_rightIprio_3_0_isZero)));
    mipriosReg_3_greaterThan255 <=
      ipriosTmp_result_sel_334 & ipriosTmp_result_leftIprio_3_0_greaterThan255
      | ipriosTmp_result_sel_337
      & (ipriosTmp_result_sel_338 & ipriosTmp_result_leftIprio_3_0_greaterThan255
         | ipriosTmp_result_sel_340 & ipriosTmp_result_sel_341
         & ipriosTmp_result_leftIprio_3_0_greaterThan255
         | ipriosTmp_result_sel_344 & ~ipriosTmp_result_sel_345
         & ipriosTmp_result_leftIprio_3_0_greaterThan255);
    mipriosReg_3_prioNum <=
      (ipriosTmp_result_sel_334 ? ipriosTmp_result_leftIprio_3_0_prioNum : 8'h0)
      | (gGen_23 ? ipriosTmp_result_rightIprio_leftIprio_3_0_prioNum : 8'h0)
      | (ipriosTmp_result_sel_337
           ? (ipriosTmp_result_sel_338
                ? ipriosTmp_result_leftIprio_3_0_prioNum
                : 8'h0)
             | (ipriosTmp_result_sel_340
                  ? (ipriosTmp_result_sel_341
                       ? ipriosTmp_result_leftIprio_3_0_prioNum
                       : ipriosTmp_result_rightIprio_3_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_344
                  ? (ipriosTmp_result_sel_345
                       ? ipriosTmp_result_rightIprio_3_0_prioNum
                       : ipriosTmp_result_leftIprio_3_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_349
                  ? (gGen_22 ? ipriosTmp_result_rightIprio_leftIprio_3_0_prioNum : 8'h0)
                    | (ipriosTmp_result_leftIprio_3_0_greaterThan255
                         ? 8'h0
                         : ipriosTmp_result_sel_357
                             ? ipriosTmp_result_leftIprio_3_0_prioNum
                             : ipriosTmp_result_rightIprio_3_0_prioNum)
                  : 8'h0)
           : 8'h0);
    mipriosReg_4_idx <= mipriosSort_34_enable ? 6'h22 : 6'h0;
    mipriosReg_4_enable <= mipriosSort_34_enable;
    mipriosReg_4_isZero <= mipriosSort_34_enable & io_in_miprios[111:104] == 8'h0;
    mipriosReg_4_prioNum <= mipriosSort_34_enable ? io_in_miprios[111:104] : 8'h0;
    mipriosReg_5_idx <= 6'h0;
    mipriosReg_5_enable <= 1'h0;
    mipriosReg_5_isZero <= 1'h0;
    mipriosReg_5_prioNum <= 8'h0;
    mipriosReg_6_idx <= 6'h0;
    mipriosReg_6_enable <= 1'h0;
    mipriosReg_6_isZero <= 1'h0;
    mipriosReg_6_prioNum <= 8'h0;
    mipriosReg_7_idx <= 6'h0;
    mipriosReg_7_enable <= 1'h0;
    mipriosReg_7_isZero <= 1'h0;
    mipriosReg_7_prioNum <= 8'h0;
    hsipriosReg_0_idx <=
      (ipriosTmp_result_sel_889 ? ipriosTmp_result_leftIprio_8_0_idx : 6'h0)
      | (ipriosTmp_result_sel_891 ? ipriosTmp_result_rightIprio_8_0_idx : 6'h0)
      | (ipriosTmp_result_sel_892
           ? (ipriosTmp_result_sel_893
                ? ipriosTmp_result_leftIprio_8_0_idx
                : 6'h0)
             | (ipriosTmp_result_sel_895
                  ? (ipriosTmp_result_sel_896
                       ? ipriosTmp_result_leftIprio_8_0_idx
                       : ipriosTmp_result_rightIprio_8_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_899
                  ? (ipriosTmp_result_sel_900
                       ? ipriosTmp_result_rightIprio_8_0_idx
                       : ipriosTmp_result_leftIprio_8_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_904
                  ? (ipriosTmp_result_sel_912
                       ? ipriosTmp_result_leftIprio_8_0_idx
                       : ipriosTmp_result_rightIprio_8_0_idx)
                  : 6'h0)
           : 6'h0);
    hsipriosReg_0_enable <=
      ipriosTmp_result_sel_889 & ipriosTmp_result_leftIprio_8_0_enable
      | ipriosTmp_result_sel_891 & ipriosTmp_result_rightIprio_8_0_enable
      | ipriosTmp_result_sel_892
      & (ipriosTmp_result_sel_893 & ipriosTmp_result_leftIprio_8_0_enable
         | ipriosTmp_result_sel_895
         & (ipriosTmp_result_sel_896
              ? ipriosTmp_result_leftIprio_8_0_enable
              : ipriosTmp_result_rightIprio_8_0_enable) | ipriosTmp_result_sel_899
         & (ipriosTmp_result_sel_900
              ? ipriosTmp_result_rightIprio_8_0_enable
              : ipriosTmp_result_leftIprio_8_0_enable) | ipriosTmp_result_sel_904
         & (ipriosTmp_result_sel_912
              ? ipriosTmp_result_leftIprio_8_0_enable
              : ipriosTmp_result_rightIprio_8_0_enable));
    hsipriosReg_0_isZero <=
      ipriosTmp_result_sel_889 & ipriosTmp_result_leftIprio_8_0_isZero
      | ipriosTmp_result_sel_891 & ipriosTmp_result_rightIprio_8_0_isZero
      | ipriosTmp_result_sel_892
      & (ipriosTmp_result_sel_893 & ipriosTmp_result_leftIprio_8_0_isZero
         | ipriosTmp_result_sel_895
         & (ipriosTmp_result_sel_896
              ? ipriosTmp_result_leftIprio_8_0_isZero
              : ipriosTmp_result_rightIprio_8_0_isZero) | ipriosTmp_result_sel_899
         & (ipriosTmp_result_sel_900
              ? ipriosTmp_result_rightIprio_8_0_isZero
              : ipriosTmp_result_leftIprio_8_0_isZero) | ipriosTmp_result_sel_904
         & (ipriosTmp_result_sel_912
              ? ipriosTmp_result_leftIprio_8_0_isZero
              : ipriosTmp_result_rightIprio_8_0_isZero));
    hsipriosReg_0_prioNum <=
      (ipriosTmp_result_sel_889 ? ipriosTmp_result_leftIprio_8_0_prioNum : 8'h0)
      | (ipriosTmp_result_sel_891
           ? ipriosTmp_result_rightIprio_8_0_prioNum
           : 8'h0)
      | (ipriosTmp_result_sel_892
           ? (ipriosTmp_result_sel_893
                ? ipriosTmp_result_leftIprio_8_0_prioNum
                : 8'h0)
             | (ipriosTmp_result_sel_895
                  ? (ipriosTmp_result_sel_896
                       ? ipriosTmp_result_leftIprio_8_0_prioNum
                       : ipriosTmp_result_rightIprio_8_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_899
                  ? (ipriosTmp_result_sel_900
                       ? ipriosTmp_result_rightIprio_8_0_prioNum
                       : ipriosTmp_result_leftIprio_8_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_904
                  ? (ipriosTmp_result_sel_912
                       ? ipriosTmp_result_leftIprio_8_0_prioNum
                       : ipriosTmp_result_rightIprio_8_0_prioNum)
                  : 8'h0)
           : 8'h0);
    hsipriosReg_1_idx <=
      (ipriosTmp_result_sel_1000 ? ipriosTmp_result_leftIprio_9_0_idx : 6'h0)
      | (ipriosTmp_result_sel_1002 ? ipriosTmp_result_rightIprio_9_0_idx : 6'h0)
      | (ipriosTmp_result_sel_1003
           ? (ipriosTmp_result_sel_1004
                ? ipriosTmp_result_leftIprio_9_0_idx
                : 6'h0)
             | (ipriosTmp_result_sel_1006
                  ? (ipriosTmp_result_sel_1007
                       ? ipriosTmp_result_leftIprio_9_0_idx
                       : ipriosTmp_result_rightIprio_9_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1010
                  ? (ipriosTmp_result_sel_1011
                       ? ipriosTmp_result_rightIprio_9_0_idx
                       : ipriosTmp_result_leftIprio_9_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1015
                  ? (ipriosTmp_result_sel_1023
                       ? ipriosTmp_result_leftIprio_9_0_idx
                       : ipriosTmp_result_rightIprio_9_0_idx)
                  : 6'h0)
           : 6'h0);
    hsipriosReg_1_enable <=
      ipriosTmp_result_sel_1000 & ipriosTmp_result_leftIprio_9_0_enable
      | ipriosTmp_result_sel_1002 & ipriosTmp_result_rightIprio_9_0_enable
      | ipriosTmp_result_sel_1003
      & (ipriosTmp_result_sel_1004 & ipriosTmp_result_leftIprio_9_0_enable
         | ipriosTmp_result_sel_1006
         & (ipriosTmp_result_sel_1007
              ? ipriosTmp_result_leftIprio_9_0_enable
              : ipriosTmp_result_rightIprio_9_0_enable)
         | ipriosTmp_result_sel_1010
         & (ipriosTmp_result_sel_1011
              ? ipriosTmp_result_rightIprio_9_0_enable
              : ipriosTmp_result_leftIprio_9_0_enable) | ipriosTmp_result_sel_1015
         & (ipriosTmp_result_sel_1023
              ? ipriosTmp_result_leftIprio_9_0_enable
              : ipriosTmp_result_rightIprio_9_0_enable));
    hsipriosReg_1_isZero <=
      ipriosTmp_result_sel_1000 & ipriosTmp_result_leftIprio_9_0_isZero
      | ipriosTmp_result_sel_1002 & ipriosTmp_result_rightIprio_9_0_isZero
      | ipriosTmp_result_sel_1003
      & (ipriosTmp_result_sel_1004 & ipriosTmp_result_leftIprio_9_0_isZero
         | ipriosTmp_result_sel_1006
         & (ipriosTmp_result_sel_1007
              ? ipriosTmp_result_leftIprio_9_0_isZero
              : ipriosTmp_result_rightIprio_9_0_isZero)
         | ipriosTmp_result_sel_1010
         & (ipriosTmp_result_sel_1011
              ? ipriosTmp_result_rightIprio_9_0_isZero
              : ipriosTmp_result_leftIprio_9_0_isZero) | ipriosTmp_result_sel_1015
         & (ipriosTmp_result_sel_1023
              ? ipriosTmp_result_leftIprio_9_0_isZero
              : ipriosTmp_result_rightIprio_9_0_isZero));
    hsipriosReg_1_prioNum <=
      (ipriosTmp_result_sel_1000 ? ipriosTmp_result_leftIprio_9_0_prioNum : 8'h0)
      | (ipriosTmp_result_sel_1002
           ? ipriosTmp_result_rightIprio_9_0_prioNum
           : 8'h0)
      | (ipriosTmp_result_sel_1003
           ? (ipriosTmp_result_sel_1004
                ? ipriosTmp_result_leftIprio_9_0_prioNum
                : 8'h0)
             | (ipriosTmp_result_sel_1006
                  ? (ipriosTmp_result_sel_1007
                       ? ipriosTmp_result_leftIprio_9_0_prioNum
                       : ipriosTmp_result_rightIprio_9_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_1010
                  ? (ipriosTmp_result_sel_1011
                       ? ipriosTmp_result_rightIprio_9_0_prioNum
                       : ipriosTmp_result_leftIprio_9_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_1015
                  ? (ipriosTmp_result_sel_1023
                       ? ipriosTmp_result_leftIprio_9_0_prioNum
                       : ipriosTmp_result_rightIprio_9_0_prioNum)
                  : 8'h0)
           : 8'h0);
    hsipriosReg_2_idx <=
      (ipriosTmp_result_sel_1111 ? ipriosTmp_result_leftIprio_10_0_idx : 6'h0)
      | (ipriosTmp_result_sel_1113 ? ipriosTmp_result_rightIprio_10_0_idx : 6'h0)
      | (ipriosTmp_result_sel_1114
           ? (ipriosTmp_result_sel_1115
                ? ipriosTmp_result_leftIprio_10_0_idx
                : 6'h0)
             | (ipriosTmp_result_sel_1117
                  ? (ipriosTmp_result_sel_1118
                       ? ipriosTmp_result_leftIprio_10_0_idx
                       : ipriosTmp_result_rightIprio_10_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1121
                  ? (ipriosTmp_result_sel_1122
                       ? ipriosTmp_result_rightIprio_10_0_idx
                       : ipriosTmp_result_leftIprio_10_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1126
                  ? (ipriosTmp_result_sel_1134
                       ? ipriosTmp_result_leftIprio_10_0_idx
                       : ipriosTmp_result_rightIprio_10_0_idx)
                  : 6'h0)
           : 6'h0);
    hsipriosReg_2_enable <=
      ipriosTmp_result_sel_1111 & ipriosTmp_result_leftIprio_10_0_enable
      | ipriosTmp_result_sel_1113 & ipriosTmp_result_rightIprio_10_0_enable
      | ipriosTmp_result_sel_1114
      & (ipriosTmp_result_sel_1115 & ipriosTmp_result_leftIprio_10_0_enable
         | ipriosTmp_result_sel_1117
         & (ipriosTmp_result_sel_1118
              ? ipriosTmp_result_leftIprio_10_0_enable
              : ipriosTmp_result_rightIprio_10_0_enable)
         | ipriosTmp_result_sel_1121
         & (ipriosTmp_result_sel_1122
              ? ipriosTmp_result_rightIprio_10_0_enable
              : ipriosTmp_result_leftIprio_10_0_enable)
         | ipriosTmp_result_sel_1126
         & (ipriosTmp_result_sel_1134
              ? ipriosTmp_result_leftIprio_10_0_enable
              : ipriosTmp_result_rightIprio_10_0_enable));
    hsipriosReg_2_isZero <=
      ipriosTmp_result_sel_1111 & ipriosTmp_result_leftIprio_10_0_isZero
      | ipriosTmp_result_sel_1113 & ipriosTmp_result_rightIprio_10_0_isZero
      | ipriosTmp_result_sel_1114
      & (ipriosTmp_result_sel_1115 & ipriosTmp_result_leftIprio_10_0_isZero
         | ipriosTmp_result_sel_1117
         & (ipriosTmp_result_sel_1118
              ? ipriosTmp_result_leftIprio_10_0_isZero
              : ipriosTmp_result_rightIprio_10_0_isZero)
         | ipriosTmp_result_sel_1121
         & (ipriosTmp_result_sel_1122
              ? ipriosTmp_result_rightIprio_10_0_isZero
              : ipriosTmp_result_leftIprio_10_0_isZero)
         | ipriosTmp_result_sel_1126
         & (ipriosTmp_result_sel_1134
              ? ipriosTmp_result_leftIprio_10_0_isZero
              : ipriosTmp_result_rightIprio_10_0_isZero));
    hsipriosReg_2_prioNum <=
      (ipriosTmp_result_sel_1111 ? ipriosTmp_result_leftIprio_10_0_prioNum : 8'h0)
      | (ipriosTmp_result_sel_1113
           ? ipriosTmp_result_rightIprio_10_0_prioNum
           : 8'h0)
      | (ipriosTmp_result_sel_1114
           ? (ipriosTmp_result_sel_1115
                ? ipriosTmp_result_leftIprio_10_0_prioNum
                : 8'h0)
             | (ipriosTmp_result_sel_1117
                  ? (ipriosTmp_result_sel_1118
                       ? ipriosTmp_result_leftIprio_10_0_prioNum
                       : ipriosTmp_result_rightIprio_10_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_1121
                  ? (ipriosTmp_result_sel_1122
                       ? ipriosTmp_result_rightIprio_10_0_prioNum
                       : ipriosTmp_result_leftIprio_10_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_1126
                  ? (ipriosTmp_result_sel_1134
                       ? ipriosTmp_result_leftIprio_10_0_prioNum
                       : ipriosTmp_result_rightIprio_10_0_prioNum)
                  : 8'h0)
           : 8'h0);
    hsipriosReg_3_idx <=
      (ipriosTmp_result_sel_1222 ? ipriosTmp_result_leftIprio_11_0_idx : 6'h0)
      | (ipriosTmp_result_sel_1224 ? ipriosTmp_result_rightIprio_11_0_idx : 6'h0)
      | (ipriosTmp_result_sel_1225
           ? (ipriosTmp_result_sel_1226
                ? ipriosTmp_result_leftIprio_11_0_idx
                : 6'h0)
             | (ipriosTmp_result_sel_1228
                  ? (ipriosTmp_result_sel_1229
                       ? ipriosTmp_result_leftIprio_11_0_idx
                       : ipriosTmp_result_rightIprio_11_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1232
                  ? (ipriosTmp_result_sel_1233
                       ? ipriosTmp_result_rightIprio_11_0_idx
                       : ipriosTmp_result_leftIprio_11_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1237
                  ? (ipriosTmp_result_leftIprio_11_0_greaterThan255
                       ? ipriosTmp_result_rightIprio_11_0_idx
                       : 6'h0)
                    | (ipriosTmp_result_leftIprio_11_0_greaterThan255
                         ? 6'h0
                         : ipriosTmp_result_sel_1245
                             ? ipriosTmp_result_leftIprio_11_0_idx
                             : ipriosTmp_result_rightIprio_11_0_idx)
                  : 6'h0)
           : 6'h0);
    hsipriosReg_3_enable <=
      ipriosTmp_result_sel_1222 & ipriosTmp_result_leftIprio_11_0_enable
      | ipriosTmp_result_sel_1224 & ipriosTmp_result_rightIprio_11_0_enable
      | ipriosTmp_result_sel_1225
      & (ipriosTmp_result_sel_1226 & ipriosTmp_result_leftIprio_11_0_enable
         | ipriosTmp_result_sel_1228
         & (ipriosTmp_result_sel_1229
              ? ipriosTmp_result_leftIprio_11_0_enable
              : ipriosTmp_result_rightIprio_11_0_enable)
         | ipriosTmp_result_sel_1232
         & (ipriosTmp_result_sel_1233
              ? ipriosTmp_result_rightIprio_11_0_enable
              : ipriosTmp_result_leftIprio_11_0_enable)
         | ipriosTmp_result_sel_1237
         & (ipriosTmp_result_leftIprio_11_0_greaterThan255
            & ipriosTmp_result_rightIprio_11_0_enable
            | ~ipriosTmp_result_leftIprio_11_0_greaterThan255
            & (ipriosTmp_result_sel_1245
                 ? ipriosTmp_result_leftIprio_11_0_enable
                 : ipriosTmp_result_rightIprio_11_0_enable)));
    hsipriosReg_3_isZero <=
      ipriosTmp_result_sel_1222 & ipriosTmp_result_leftIprio_11_0_isZero
      | ipriosTmp_result_sel_1224 & ipriosTmp_result_rightIprio_11_0_isZero
      | ipriosTmp_result_sel_1225
      & (ipriosTmp_result_sel_1226 & ipriosTmp_result_leftIprio_11_0_isZero
         | ipriosTmp_result_sel_1228
         & (ipriosTmp_result_sel_1229
              ? ipriosTmp_result_leftIprio_11_0_isZero
              : ipriosTmp_result_rightIprio_11_0_isZero)
         | ipriosTmp_result_sel_1232
         & (ipriosTmp_result_sel_1233
              ? ipriosTmp_result_rightIprio_11_0_isZero
              : ipriosTmp_result_leftIprio_11_0_isZero)
         | ipriosTmp_result_sel_1237
         & (ipriosTmp_result_leftIprio_11_0_greaterThan255
            & ipriosTmp_result_rightIprio_11_0_isZero
            | ~ipriosTmp_result_leftIprio_11_0_greaterThan255
            & (ipriosTmp_result_sel_1245
                 ? ipriosTmp_result_leftIprio_11_0_isZero
                 : ipriosTmp_result_rightIprio_11_0_isZero)));
    hsipriosReg_3_greaterThan255 <=
      ipriosTmp_result_sel_1222 & ipriosTmp_result_leftIprio_11_0_greaterThan255
      | ipriosTmp_result_sel_1225
      & (ipriosTmp_result_sel_1226
         & ipriosTmp_result_leftIprio_11_0_greaterThan255
         | ipriosTmp_result_sel_1228 & ipriosTmp_result_sel_1229
         & ipriosTmp_result_leftIprio_11_0_greaterThan255
         | ipriosTmp_result_sel_1232 & ~ipriosTmp_result_sel_1233
         & ipriosTmp_result_leftIprio_11_0_greaterThan255);
    hsipriosReg_3_prioNum <=
      (ipriosTmp_result_sel_1222 ? ipriosTmp_result_leftIprio_11_0_prioNum : 8'h0)
      | (ipriosTmp_result_sel_1224
           ? ipriosTmp_result_rightIprio_11_0_prioNum
           : 8'h0)
      | (ipriosTmp_result_sel_1225
           ? (ipriosTmp_result_sel_1226
                ? ipriosTmp_result_leftIprio_11_0_prioNum
                : 8'h0)
             | (ipriosTmp_result_sel_1228
                  ? (ipriosTmp_result_sel_1229
                       ? ipriosTmp_result_leftIprio_11_0_prioNum
                       : ipriosTmp_result_rightIprio_11_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_1232
                  ? (ipriosTmp_result_sel_1233
                       ? ipriosTmp_result_rightIprio_11_0_prioNum
                       : ipriosTmp_result_leftIprio_11_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_1237
                  ? (ipriosTmp_result_leftIprio_11_0_greaterThan255
                       ? ipriosTmp_result_rightIprio_11_0_prioNum
                       : 8'h0)
                    | (ipriosTmp_result_leftIprio_11_0_greaterThan255
                         ? 8'h0
                         : ipriosTmp_result_sel_1245
                             ? ipriosTmp_result_leftIprio_11_0_prioNum
                             : ipriosTmp_result_rightIprio_11_0_prioNum)
                  : 8'h0)
           : 8'h0);
    hsipriosReg_4_idx <=
      (ipriosTmp_result_sel_1333 ? ipriosTmp_result_leftIprio_12_0_idx : 6'h0)
      | (ipriosTmp_result_sel_1335 ? ipriosTmp_result_rightIprio_12_0_idx : 6'h0)
      | (ipriosTmp_result_sel_1336
           ? (ipriosTmp_result_sel_1337
                ? ipriosTmp_result_leftIprio_12_0_idx
                : 6'h0)
             | (ipriosTmp_result_sel_1339
                  ? (ipriosTmp_result_sel_1340
                       ? ipriosTmp_result_leftIprio_12_0_idx
                       : ipriosTmp_result_rightIprio_12_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1343
                  ? (ipriosTmp_result_sel_1344
                       ? ipriosTmp_result_rightIprio_12_0_idx
                       : ipriosTmp_result_leftIprio_12_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1348
                  ? (ipriosTmp_result_sel_1356
                       ? ipriosTmp_result_leftIprio_12_0_idx
                       : ipriosTmp_result_rightIprio_12_0_idx)
                  : 6'h0)
           : 6'h0);
    hsipriosReg_4_enable <=
      ipriosTmp_result_sel_1333 & ipriosTmp_result_leftIprio_12_0_enable
      | ipriosTmp_result_sel_1335 & ipriosTmp_result_rightIprio_12_0_enable
      | ipriosTmp_result_sel_1336
      & (ipriosTmp_result_sel_1337 & ipriosTmp_result_leftIprio_12_0_enable
         | ipriosTmp_result_sel_1339
         & (ipriosTmp_result_sel_1340
              ? ipriosTmp_result_leftIprio_12_0_enable
              : ipriosTmp_result_rightIprio_12_0_enable)
         | ipriosTmp_result_sel_1343
         & (ipriosTmp_result_sel_1344
              ? ipriosTmp_result_rightIprio_12_0_enable
              : ipriosTmp_result_leftIprio_12_0_enable)
         | ipriosTmp_result_sel_1348
         & (ipriosTmp_result_sel_1356
              ? ipriosTmp_result_leftIprio_12_0_enable
              : ipriosTmp_result_rightIprio_12_0_enable));
    hsipriosReg_4_isZero <=
      ipriosTmp_result_sel_1333 & ipriosTmp_result_leftIprio_12_0_isZero
      | ipriosTmp_result_sel_1335 & ipriosTmp_result_rightIprio_12_0_isZero
      | ipriosTmp_result_sel_1336
      & (ipriosTmp_result_sel_1337 & ipriosTmp_result_leftIprio_12_0_isZero
         | ipriosTmp_result_sel_1339
         & (ipriosTmp_result_sel_1340
              ? ipriosTmp_result_leftIprio_12_0_isZero
              : ipriosTmp_result_rightIprio_12_0_isZero)
         | ipriosTmp_result_sel_1343
         & (ipriosTmp_result_sel_1344
              ? ipriosTmp_result_rightIprio_12_0_isZero
              : ipriosTmp_result_leftIprio_12_0_isZero)
         | ipriosTmp_result_sel_1348
         & (ipriosTmp_result_sel_1356
              ? ipriosTmp_result_leftIprio_12_0_isZero
              : ipriosTmp_result_rightIprio_12_0_isZero));
    hsipriosReg_4_prioNum <=
      (ipriosTmp_result_sel_1333 ? ipriosTmp_result_leftIprio_12_0_prioNum : 8'h0)
      | (ipriosTmp_result_sel_1335
           ? ipriosTmp_result_rightIprio_12_0_prioNum
           : 8'h0)
      | (ipriosTmp_result_sel_1336
           ? (ipriosTmp_result_sel_1337
                ? ipriosTmp_result_leftIprio_12_0_prioNum
                : 8'h0)
             | (ipriosTmp_result_sel_1339
                  ? (ipriosTmp_result_sel_1340
                       ? ipriosTmp_result_leftIprio_12_0_prioNum
                       : ipriosTmp_result_rightIprio_12_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_1343
                  ? (ipriosTmp_result_sel_1344
                       ? ipriosTmp_result_rightIprio_12_0_prioNum
                       : ipriosTmp_result_leftIprio_12_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_1348
                  ? (ipriosTmp_result_sel_1356
                       ? ipriosTmp_result_leftIprio_12_0_prioNum
                       : ipriosTmp_result_rightIprio_12_0_prioNum)
                  : 8'h0)
           : 8'h0);
    hsipriosReg_5_idx <=
      (ipriosTmp_result_sel_1444 ? ipriosTmp_result_leftIprio_13_0_idx : 6'h0)
      | (ipriosTmp_result_sel_1446 ? ipriosTmp_result_rightIprio_13_0_idx : 6'h0)
      | (ipriosTmp_result_sel_1447
           ? (ipriosTmp_result_sel_1448
                ? ipriosTmp_result_leftIprio_13_0_idx
                : 6'h0)
             | (ipriosTmp_result_sel_1450
                  ? (ipriosTmp_result_sel_1451
                       ? ipriosTmp_result_leftIprio_13_0_idx
                       : ipriosTmp_result_rightIprio_13_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1454
                  ? (ipriosTmp_result_sel_1455
                       ? ipriosTmp_result_rightIprio_13_0_idx
                       : ipriosTmp_result_leftIprio_13_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1459
                  ? (ipriosTmp_result_sel_1467
                       ? ipriosTmp_result_leftIprio_13_0_idx
                       : ipriosTmp_result_rightIprio_13_0_idx)
                  : 6'h0)
           : 6'h0);
    hsipriosReg_5_enable <=
      ipriosTmp_result_sel_1444 & ipriosTmp_result_leftIprio_13_0_enable
      | ipriosTmp_result_sel_1446 & ipriosTmp_result_rightIprio_13_0_enable
      | ipriosTmp_result_sel_1447
      & (ipriosTmp_result_sel_1448 & ipriosTmp_result_leftIprio_13_0_enable
         | ipriosTmp_result_sel_1450
         & (ipriosTmp_result_sel_1451
              ? ipriosTmp_result_leftIprio_13_0_enable
              : ipriosTmp_result_rightIprio_13_0_enable)
         | ipriosTmp_result_sel_1454
         & (ipriosTmp_result_sel_1455
              ? ipriosTmp_result_rightIprio_13_0_enable
              : ipriosTmp_result_leftIprio_13_0_enable)
         | ipriosTmp_result_sel_1459
         & (ipriosTmp_result_sel_1467
              ? ipriosTmp_result_leftIprio_13_0_enable
              : ipriosTmp_result_rightIprio_13_0_enable));
    hsipriosReg_5_isZero <=
      ipriosTmp_result_sel_1444 & ipriosTmp_result_leftIprio_13_0_isZero
      | ipriosTmp_result_sel_1446 & ipriosTmp_result_rightIprio_13_0_isZero
      | ipriosTmp_result_sel_1447
      & (ipriosTmp_result_sel_1448 & ipriosTmp_result_leftIprio_13_0_isZero
         | ipriosTmp_result_sel_1450
         & (ipriosTmp_result_sel_1451
              ? ipriosTmp_result_leftIprio_13_0_isZero
              : ipriosTmp_result_rightIprio_13_0_isZero)
         | ipriosTmp_result_sel_1454
         & (ipriosTmp_result_sel_1455
              ? ipriosTmp_result_rightIprio_13_0_isZero
              : ipriosTmp_result_leftIprio_13_0_isZero)
         | ipriosTmp_result_sel_1459
         & (ipriosTmp_result_sel_1467
              ? ipriosTmp_result_leftIprio_13_0_isZero
              : ipriosTmp_result_rightIprio_13_0_isZero));
    hsipriosReg_5_prioNum <=
      (ipriosTmp_result_sel_1444 ? ipriosTmp_result_leftIprio_13_0_prioNum : 8'h0)
      | (ipriosTmp_result_sel_1446
           ? ipriosTmp_result_rightIprio_13_0_prioNum
           : 8'h0)
      | (ipriosTmp_result_sel_1447
           ? (ipriosTmp_result_sel_1448
                ? ipriosTmp_result_leftIprio_13_0_prioNum
                : 8'h0)
             | (ipriosTmp_result_sel_1450
                  ? (ipriosTmp_result_sel_1451
                       ? ipriosTmp_result_leftIprio_13_0_prioNum
                       : ipriosTmp_result_rightIprio_13_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_1454
                  ? (ipriosTmp_result_sel_1455
                       ? ipriosTmp_result_rightIprio_13_0_prioNum
                       : ipriosTmp_result_leftIprio_13_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_1459
                  ? (ipriosTmp_result_sel_1467
                       ? ipriosTmp_result_leftIprio_13_0_prioNum
                       : ipriosTmp_result_rightIprio_13_0_prioNum)
                  : 8'h0)
           : 8'h0);
    hsipriosReg_6_idx <=
      (ipriosTmp_result_sel_1555 ? ipriosTmp_result_leftIprio_14_0_idx : 6'h0)
      | (ipriosTmp_result_sel_1557 ? ipriosTmp_result_rightIprio_14_0_idx : 6'h0)
      | (ipriosTmp_result_sel_1558
           ? (ipriosTmp_result_sel_1559
                ? ipriosTmp_result_leftIprio_14_0_idx
                : 6'h0)
             | (ipriosTmp_result_sel_1561
                  ? (ipriosTmp_result_sel_1562
                       ? ipriosTmp_result_leftIprio_14_0_idx
                       : ipriosTmp_result_rightIprio_14_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1565
                  ? (ipriosTmp_result_sel_1566
                       ? ipriosTmp_result_rightIprio_14_0_idx
                       : ipriosTmp_result_leftIprio_14_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1570
                  ? (ipriosTmp_result_sel_1578
                       ? ipriosTmp_result_leftIprio_14_0_idx
                       : ipriosTmp_result_rightIprio_14_0_idx)
                  : 6'h0)
           : 6'h0);
    hsipriosReg_6_enable <=
      ipriosTmp_result_sel_1555 & ipriosTmp_result_leftIprio_14_0_enable
      | ipriosTmp_result_sel_1557 & ipriosTmp_result_rightIprio_14_0_enable
      | ipriosTmp_result_sel_1558
      & (ipriosTmp_result_sel_1559 & ipriosTmp_result_leftIprio_14_0_enable
         | ipriosTmp_result_sel_1561
         & (ipriosTmp_result_sel_1562
              ? ipriosTmp_result_leftIprio_14_0_enable
              : ipriosTmp_result_rightIprio_14_0_enable)
         | ipriosTmp_result_sel_1565
         & (ipriosTmp_result_sel_1566
              ? ipriosTmp_result_rightIprio_14_0_enable
              : ipriosTmp_result_leftIprio_14_0_enable)
         | ipriosTmp_result_sel_1570
         & (ipriosTmp_result_sel_1578
              ? ipriosTmp_result_leftIprio_14_0_enable
              : ipriosTmp_result_rightIprio_14_0_enable));
    hsipriosReg_6_isZero <=
      ipriosTmp_result_sel_1555 & ipriosTmp_result_leftIprio_14_0_isZero
      | ipriosTmp_result_sel_1557 & ipriosTmp_result_rightIprio_14_0_isZero
      | ipriosTmp_result_sel_1558
      & (ipriosTmp_result_sel_1559 & ipriosTmp_result_leftIprio_14_0_isZero
         | ipriosTmp_result_sel_1561
         & (ipriosTmp_result_sel_1562
              ? ipriosTmp_result_leftIprio_14_0_isZero
              : ipriosTmp_result_rightIprio_14_0_isZero)
         | ipriosTmp_result_sel_1565
         & (ipriosTmp_result_sel_1566
              ? ipriosTmp_result_rightIprio_14_0_isZero
              : ipriosTmp_result_leftIprio_14_0_isZero)
         | ipriosTmp_result_sel_1570
         & (ipriosTmp_result_sel_1578
              ? ipriosTmp_result_leftIprio_14_0_isZero
              : ipriosTmp_result_rightIprio_14_0_isZero));
    hsipriosReg_6_prioNum <=
      (ipriosTmp_result_sel_1555 ? ipriosTmp_result_leftIprio_14_0_prioNum : 8'h0)
      | (ipriosTmp_result_sel_1557
           ? ipriosTmp_result_rightIprio_14_0_prioNum
           : 8'h0)
      | (ipriosTmp_result_sel_1558
           ? (ipriosTmp_result_sel_1559
                ? ipriosTmp_result_leftIprio_14_0_prioNum
                : 8'h0)
             | (ipriosTmp_result_sel_1561
                  ? (ipriosTmp_result_sel_1562
                       ? ipriosTmp_result_leftIprio_14_0_prioNum
                       : ipriosTmp_result_rightIprio_14_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_1565
                  ? (ipriosTmp_result_sel_1566
                       ? ipriosTmp_result_rightIprio_14_0_prioNum
                       : ipriosTmp_result_leftIprio_14_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_1570
                  ? (ipriosTmp_result_sel_1578
                       ? ipriosTmp_result_leftIprio_14_0_prioNum
                       : ipriosTmp_result_rightIprio_14_0_prioNum)
                  : 8'h0)
           : 8'h0);
    hsipriosReg_7_idx <=
      (ipriosTmp_result_sel_1666 ? ipriosTmp_result_leftIprio_15_0_idx : 6'h0)
      | (gGen_24 ? 6'h3C : 6'h0)
      | (ipriosTmp_result_sel_1669
           ? (ipriosTmp_result_sel_1670
                ? ipriosTmp_result_leftIprio_15_0_idx
                : 6'h0)
             | (ipriosTmp_result_sel_1672
                  ? (ipriosTmp_result_sel_1673
                       ? ipriosTmp_result_leftIprio_15_0_idx
                       : ipriosTmp_result_rightIprio_15_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1676
                  ? (ipriosTmp_result_sel_1677
                       ? ipriosTmp_result_rightIprio_15_0_idx
                       : ipriosTmp_result_leftIprio_15_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1681
                  ? (ipriosTmp_result_sel_1689
                       ? ipriosTmp_result_leftIprio_15_0_idx
                       : ipriosTmp_result_rightIprio_15_0_idx)
                  : 6'h0)
           : 6'h0);
    hsipriosReg_7_enable <=
      ipriosTmp_result_sel_1666 & ipriosTmp_result_leftIprio_15_0_enable
      | ipriosTmp_result_sel_1668 & ipriosTmp_result_rightIprio_15_0_enable
      | ipriosTmp_result_sel_1669
      & (ipriosTmp_result_sel_1670 & ipriosTmp_result_leftIprio_15_0_enable
         | ipriosTmp_result_sel_1672
         & (ipriosTmp_result_sel_1673
              ? ipriosTmp_result_leftIprio_15_0_enable
              : ipriosTmp_result_rightIprio_15_0_enable)
         | ipriosTmp_result_sel_1676
         & (ipriosTmp_result_sel_1677
              ? ipriosTmp_result_rightIprio_15_0_enable
              : ipriosTmp_result_leftIprio_15_0_enable)
         | ipriosTmp_result_sel_1681
         & (ipriosTmp_result_sel_1689
              ? ipriosTmp_result_leftIprio_15_0_enable
              : ipriosTmp_result_rightIprio_15_0_enable));
    hsipriosReg_7_isZero <=
      ipriosTmp_result_sel_1666 & ipriosTmp_result_leftIprio_15_0_isZero
      | ipriosTmp_result_sel_1668 & ipriosTmp_result_rightIprio_15_0_isZero
      | ipriosTmp_result_sel_1669
      & (ipriosTmp_result_sel_1670 & ipriosTmp_result_leftIprio_15_0_isZero
         | ipriosTmp_result_sel_1672
         & (ipriosTmp_result_sel_1673
              ? ipriosTmp_result_leftIprio_15_0_isZero
              : ipriosTmp_result_rightIprio_15_0_isZero)
         | ipriosTmp_result_sel_1676
         & (ipriosTmp_result_sel_1677
              ? ipriosTmp_result_rightIprio_15_0_isZero
              : ipriosTmp_result_leftIprio_15_0_isZero)
         | ipriosTmp_result_sel_1681
         & (ipriosTmp_result_sel_1689
              ? ipriosTmp_result_leftIprio_15_0_isZero
              : ipriosTmp_result_rightIprio_15_0_isZero));
    hsipriosReg_7_prioNum <=
      (ipriosTmp_result_sel_1666 ? ipriosTmp_result_leftIprio_15_0_prioNum : 8'h0)
      | (gGen_24 ? io_in_hsiprios[391:384] : 8'h0)
      | (ipriosTmp_result_sel_1669
           ? (ipriosTmp_result_sel_1670
                ? ipriosTmp_result_leftIprio_15_0_prioNum
                : 8'h0)
             | (ipriosTmp_result_sel_1672
                  ? (ipriosTmp_result_sel_1673
                       ? ipriosTmp_result_leftIprio_15_0_prioNum
                       : ipriosTmp_result_rightIprio_15_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_1676
                  ? (ipriosTmp_result_sel_1677
                       ? ipriosTmp_result_rightIprio_15_0_prioNum
                       : ipriosTmp_result_leftIprio_15_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_1681
                  ? (ipriosTmp_result_sel_1689
                       ? ipriosTmp_result_leftIprio_15_0_prioNum
                       : ipriosTmp_result_rightIprio_15_0_prioNum)
                  : 8'h0)
           : 8'h0);
    hvipriosReg_0_idx <=
      (ipriosTmp_result_sel_1777 ? ipriosTmp_result_leftIprio_16_0_idx : 6'h0)
      | (ipriosTmp_result_sel_1779 ? ipriosTmp_result_rightIprio_16_0_idx : 6'h0)
      | (ipriosTmp_result_sel_1780
           ? (ipriosTmp_result_sel_1781
                ? ipriosTmp_result_leftIprio_16_0_idx
                : 6'h0)
             | (ipriosTmp_result_sel_1783
                  ? (ipriosTmp_result_leftIprio_16_0_idx[5]
                       ? ipriosTmp_result_rightIprio_16_0_idx
                       : ipriosTmp_result_leftIprio_16_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1787
                  ? (ipriosTmp_result_rightIprio_16_0_idx[5]
                       ? ipriosTmp_result_leftIprio_16_0_idx
                       : ipriosTmp_result_rightIprio_16_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1792
                  ? ipriosTmp_result_leftIprio_16_0_idx
                  : 6'h0)
           : 6'h0);
    hvipriosReg_0_enable <=
      ipriosTmp_result_sel_1777 & ipriosTmp_result_leftIprio_16_0_enable
      | ipriosTmp_result_sel_1779 & ipriosTmp_result_rightIprio_16_0_enable
      | ipriosTmp_result_sel_1780
      & (ipriosTmp_result_sel_1781 & ipriosTmp_result_leftIprio_16_0_enable
         | ipriosTmp_result_sel_1783
         & (ipriosTmp_result_leftIprio_16_0_idx[5]
              ? ipriosTmp_result_rightIprio_16_0_enable
              : ipriosTmp_result_leftIprio_16_0_enable)
         | ipriosTmp_result_sel_1787
         & (ipriosTmp_result_rightIprio_16_0_idx[5]
              ? ipriosTmp_result_leftIprio_16_0_enable
              : ipriosTmp_result_rightIprio_16_0_enable)
         | ipriosTmp_result_sel_1792 & ipriosTmp_result_leftIprio_16_0_enable);
    hvipriosReg_0_isZero <=
      ipriosTmp_result_sel_1777 & ipriosTmp_result_leftIprio_16_0_isZero
      | ipriosTmp_result_sel_1779 & ipriosTmp_result_rightIprio_16_0_isZero
      | ipriosTmp_result_sel_1780
      & (ipriosTmp_result_sel_1781 & ipriosTmp_result_leftIprio_16_0_isZero
         | ipriosTmp_result_sel_1783
         & (ipriosTmp_result_leftIprio_16_0_idx[5]
              ? ipriosTmp_result_rightIprio_16_0_isZero
              : ipriosTmp_result_leftIprio_16_0_isZero)
         | ipriosTmp_result_sel_1787
         & (ipriosTmp_result_rightIprio_16_0_idx[5]
              ? ipriosTmp_result_leftIprio_16_0_isZero
              : ipriosTmp_result_rightIprio_16_0_isZero)
         | ipriosTmp_result_sel_1792 & ipriosTmp_result_leftIprio_16_0_isZero);
    hvipriosReg_0_prioNum <=
      ipriosTmp_result_sel_1779 & gGen_26 | ipriosTmp_result_sel_1780
      & (ipriosTmp_result_sel_1783 & ipriosTmp_result_leftIprio_16_0_idx[5]
         & gGen_26 | ipriosTmp_result_sel_1787
         & ~(ipriosTmp_result_rightIprio_16_0_idx[5]) & gGen_26)
        ? io_in_hviprio2_ALL[63:56]
        : 8'h0;
    hvipriosReg_1_idx <=
      (ipriosTmp_result_sel_1888 ? ipriosTmp_result_leftIprio_17_0_idx : 6'h0)
      | (ipriosTmp_result_sel_1890 ? ipriosTmp_result_rightIprio_17_0_idx : 6'h0)
      | (ipriosTmp_result_sel_1891
           ? (ipriosTmp_result_sel_1892
                ? ipriosTmp_result_leftIprio_17_0_idx
                : 6'h0)
             | (ipriosTmp_result_sel_1894
                  ? (ipriosTmp_result_leftIprio_17_0_idx[5]
                       ? ipriosTmp_result_rightIprio_17_0_idx
                       : ipriosTmp_result_leftIprio_17_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1898
                  ? (ipriosTmp_result_rightIprio_17_0_idx[5]
                       ? ipriosTmp_result_leftIprio_17_0_idx
                       : ipriosTmp_result_rightIprio_17_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_1903
                  ? (ipriosTmp_result_sel_1911
                       ? ipriosTmp_result_leftIprio_17_0_idx
                       : ipriosTmp_result_rightIprio_17_0_idx)
                  : 6'h0)
           : 6'h0);
    hvipriosReg_1_enable <=
      ipriosTmp_result_sel_1888 & ipriosTmp_result_leftIprio_17_0_enable
      | ipriosTmp_result_sel_1890 & ipriosTmp_result_rightIprio_17_0_enable
      | ipriosTmp_result_sel_1891
      & (ipriosTmp_result_sel_1892 & ipriosTmp_result_leftIprio_17_0_enable
         | ipriosTmp_result_sel_1894
         & (ipriosTmp_result_leftIprio_17_0_idx[5]
              ? ipriosTmp_result_rightIprio_17_0_enable
              : ipriosTmp_result_leftIprio_17_0_enable)
         | ipriosTmp_result_sel_1898
         & (ipriosTmp_result_rightIprio_17_0_idx[5]
              ? ipriosTmp_result_leftIprio_17_0_enable
              : ipriosTmp_result_rightIprio_17_0_enable)
         | ipriosTmp_result_sel_1903
         & (ipriosTmp_result_sel_1911
              ? ipriosTmp_result_leftIprio_17_0_enable
              : ipriosTmp_result_rightIprio_17_0_enable));
    hvipriosReg_1_isZero <=
      ipriosTmp_result_sel_1888 & ipriosTmp_result_leftIprio_17_0_isZero
      | ipriosTmp_result_sel_1890 & ipriosTmp_result_rightIprio_17_0_isZero
      | ipriosTmp_result_sel_1891
      & (ipriosTmp_result_sel_1892 & ipriosTmp_result_leftIprio_17_0_isZero
         | ipriosTmp_result_sel_1894
         & (ipriosTmp_result_leftIprio_17_0_idx[5]
              ? ipriosTmp_result_rightIprio_17_0_isZero
              : ipriosTmp_result_leftIprio_17_0_isZero)
         | ipriosTmp_result_sel_1898
         & (ipriosTmp_result_rightIprio_17_0_idx[5]
              ? ipriosTmp_result_leftIprio_17_0_isZero
              : ipriosTmp_result_rightIprio_17_0_isZero)
         | ipriosTmp_result_sel_1903
         & (ipriosTmp_result_sel_1911
              ? ipriosTmp_result_leftIprio_17_0_isZero
              : ipriosTmp_result_rightIprio_17_0_isZero));
    hvipriosReg_1_prioNum <=
      (ipriosTmp_result_sel_1888 & gGen_28 ? io_in_hviprio2_ALL[55:48] : 8'h0)
      | (ipriosTmp_result_sel_1890 & gGen_30 ? io_in_hviprio2_ALL[47:40] : 8'h0)
      | (ipriosTmp_result_sel_1891
           ? (ipriosTmp_result_sel_1892 & gGen_28
                ? io_in_hviprio2_ALL[55:48]
                : 8'h0)
             | (ipriosTmp_result_sel_1894
                  ? (ipriosTmp_result_leftIprio_17_0_idx[5]
                       ? ipriosTmp_result_rightIprio_17_0_prioNum
                       : ipriosTmp_result_leftIprio_17_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_1898
                  ? (ipriosTmp_result_rightIprio_17_0_idx[5]
                       ? ipriosTmp_result_leftIprio_17_0_prioNum
                       : ipriosTmp_result_rightIprio_17_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_1903
                  ? (ipriosTmp_result_sel_1911
                       ? ipriosTmp_result_leftIprio_17_0_prioNum
                       : ipriosTmp_result_rightIprio_17_0_prioNum)
                  : 8'h0)
           : 8'h0);
    hvipriosReg_2_idx <=
      (ipriosTmp_result_sel_1999 ? ipriosTmp_result_leftIprio_18_0_idx : 6'h0)
      | (ipriosTmp_result_sel_2001 ? ipriosTmp_result_rightIprio_18_0_idx : 6'h0)
      | (ipriosTmp_result_sel_2002
           ? (ipriosTmp_result_sel_2003
                ? ipriosTmp_result_leftIprio_18_0_idx
                : 6'h0)
             | (ipriosTmp_result_sel_2005
                  ? (ipriosTmp_result_leftIprio_18_0_idx[5]
                       ? ipriosTmp_result_rightIprio_18_0_idx
                       : ipriosTmp_result_leftIprio_18_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_2009
                  ? (ipriosTmp_result_rightIprio_18_0_idx[5]
                       ? ipriosTmp_result_leftIprio_18_0_idx
                       : ipriosTmp_result_rightIprio_18_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_2014
                  ? (ipriosTmp_result_sel_2022
                       ? ipriosTmp_result_leftIprio_18_0_idx
                       : ipriosTmp_result_rightIprio_18_0_idx)
                  : 6'h0)
           : 6'h0);
    hvipriosReg_2_enable <=
      ipriosTmp_result_sel_1999 & ipriosTmp_result_leftIprio_18_0_enable
      | ipriosTmp_result_sel_2001 & ipriosTmp_result_rightIprio_18_0_enable
      | ipriosTmp_result_sel_2002
      & (ipriosTmp_result_sel_2003 & ipriosTmp_result_leftIprio_18_0_enable
         | ipriosTmp_result_sel_2005
         & (ipriosTmp_result_leftIprio_18_0_idx[5]
              ? ipriosTmp_result_rightIprio_18_0_enable
              : ipriosTmp_result_leftIprio_18_0_enable)
         | ipriosTmp_result_sel_2009
         & (ipriosTmp_result_rightIprio_18_0_idx[5]
              ? ipriosTmp_result_leftIprio_18_0_enable
              : ipriosTmp_result_rightIprio_18_0_enable)
         | ipriosTmp_result_sel_2014
         & (ipriosTmp_result_sel_2022
              ? ipriosTmp_result_leftIprio_18_0_enable
              : ipriosTmp_result_rightIprio_18_0_enable));
    hvipriosReg_2_isZero <=
      ipriosTmp_result_sel_1999 & ipriosTmp_result_leftIprio_18_0_isZero
      | ipriosTmp_result_sel_2001 & ipriosTmp_result_rightIprio_18_0_isZero
      | ipriosTmp_result_sel_2002
      & (ipriosTmp_result_sel_2003 & ipriosTmp_result_leftIprio_18_0_isZero
         | ipriosTmp_result_sel_2005
         & (ipriosTmp_result_leftIprio_18_0_idx[5]
              ? ipriosTmp_result_rightIprio_18_0_isZero
              : ipriosTmp_result_leftIprio_18_0_isZero)
         | ipriosTmp_result_sel_2009
         & (ipriosTmp_result_rightIprio_18_0_idx[5]
              ? ipriosTmp_result_leftIprio_18_0_isZero
              : ipriosTmp_result_rightIprio_18_0_isZero)
         | ipriosTmp_result_sel_2014
         & (ipriosTmp_result_sel_2022
              ? ipriosTmp_result_leftIprio_18_0_isZero
              : ipriosTmp_result_rightIprio_18_0_isZero));
    hvipriosReg_2_prioNum <=
      ipriosTmp_result_sel_1999 & gGen_32 | ipriosTmp_result_sel_2002
      & (ipriosTmp_result_sel_2003 & gGen_32 | ipriosTmp_result_sel_2005
         & ~(ipriosTmp_result_leftIprio_18_0_idx[5]) & gGen_32
         | ipriosTmp_result_sel_2009 & ipriosTmp_result_rightIprio_18_0_idx[5]
         & gGen_32 | ipriosTmp_result_sel_2014 & ipriosTmp_result_sel_2022
         & gGen_32)
        ? io_in_hviprio2_ALL[39:32]
        : 8'h0;
    hvipriosReg_3_idx <=
      ipriosTmp_result_19_0_enable
        ? (ipriosTmp_result_rightIprio_leftIprio_sel_2110 ? 6'h1C : 6'h0)
          | (ipriosTmp_result_rightIprio_leftIprio_sel_2112 ? 6'h1D : 6'h0)
          | (ipriosTmp_result_rightIprio_leftIprio_sel_2113
               ? (ipriosTmp_result_rightIprio_leftIprio_sel_2114
                  | ipriosTmp_result_rightIprio_leftIprio_sel_2116
                    ? 6'h1C
                    : 6'h0)
                 | (ipriosTmp_result_rightIprio_leftIprio_sel_2120 ? 6'h1D : 6'h0)
                 | (ipriosTmp_result_rightIprio_leftIprio_sel_2125
                      ? {5'hE, ~ipriosTmp_result_rightIprio_leftIprio_sel_2133}
                      : 6'h0)
               : 6'h0)
        : 6'h0;
    hvipriosReg_3_enable <= ipriosTmp_result_19_0_enable;
    hvipriosReg_3_isZero <=
      ipriosTmp_result_19_0_enable
      & (ipriosTmp_result_rightIprio_leftIprio_sel_2110 & hvipriosSort_28_isZero
         | ipriosTmp_result_rightIprio_leftIprio_sel_2112 & hvipriosSort_29_isZero
         | ipriosTmp_result_rightIprio_leftIprio_sel_2113
         & (ipriosTmp_result_rightIprio_leftIprio_sel_2114
            & hvipriosSort_28_isZero
            | ipriosTmp_result_rightIprio_leftIprio_sel_2116
            & hvipriosSort_28_isZero
            | ipriosTmp_result_rightIprio_leftIprio_sel_2120
            & hvipriosSort_29_isZero
            | ipriosTmp_result_rightIprio_leftIprio_sel_2125
            & (ipriosTmp_result_rightIprio_leftIprio_sel_2133
                 ? hvipriosSort_28_isZero
                 : hvipriosSort_29_isZero)));
    hvipriosReg_3_prioNum <=
      ipriosTmp_result_19_0_enable
        ? (ipriosTmp_result_rightIprio_leftIprio_sel_2110 & hvipriosSort_28_enable
             ? io_in_hviprio1_PrioSSI
             : 8'h0)
          | (ipriosTmp_result_rightIprio_leftIprio_sel_2112
             & hvipriosSort_29_enable
               ? io_in_hviprio1_PrioSTI
               : 8'h0)
          | (ipriosTmp_result_rightIprio_leftIprio_sel_2113
               ? (ipriosTmp_result_rightIprio_leftIprio_sel_2114
                  & hvipriosSort_28_enable
                  | ipriosTmp_result_rightIprio_leftIprio_sel_2116
                  & hvipriosSort_28_enable
                    ? io_in_hviprio1_PrioSSI
                    : 8'h0)
                 | (ipriosTmp_result_rightIprio_leftIprio_sel_2120
                    & hvipriosSort_29_enable
                      ? io_in_hviprio1_PrioSTI
                      : 8'h0)
                 | (ipriosTmp_result_rightIprio_leftIprio_sel_2125
                      ? (ipriosTmp_result_rightIprio_leftIprio_sel_2133
                           ? hvipriosSort_28_prioNum
                           : hvipriosSort_29_prioNum)
                      : 8'h0)
               : 8'h0)
        : 8'h0;
    hvipriosReg_4_idx <=
      (gGen_36 ? ipriosTmp_result_leftIprio_rightIprio_20_0_idx : 6'h0)
      | (ipriosTmp_result_sel_2223 ? ipriosTmp_result_rightIprio_20_0_idx : 6'h0)
      | (ipriosTmp_result_sel_2224
           ? (gGen_35 ? ipriosTmp_result_leftIprio_rightIprio_20_0_idx : 6'h0)
             | (ipriosTmp_result_sel_2227
                  ? (ipriosTmp_result_leftIprio_20_0_idx[5]
                       ? ipriosTmp_result_rightIprio_20_0_idx
                       : ipriosTmp_result_leftIprio_20_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_2231
                  ? (ipriosTmp_result_rightIprio_20_0_idx[5]
                       ? ipriosTmp_result_leftIprio_20_0_idx
                       : ipriosTmp_result_rightIprio_20_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_2236
                  ? (ipriosTmp_result_sel_2244
                       ? ipriosTmp_result_leftIprio_20_0_idx
                       : ipriosTmp_result_rightIprio_20_0_idx)
                  : 6'h0)
           : 6'h0);
    hvipriosReg_4_enable <=
      ipriosTmp_result_sel_2221 & ipriosTmp_result_leftIprio_20_0_enable
      | ipriosTmp_result_sel_2223 & ipriosTmp_result_rightIprio_20_0_enable
      | ipriosTmp_result_sel_2224
      & (ipriosTmp_result_sel_2225 & ipriosTmp_result_leftIprio_20_0_enable
         | ipriosTmp_result_sel_2227
         & (ipriosTmp_result_leftIprio_20_0_idx[5]
              ? ipriosTmp_result_rightIprio_20_0_enable
              : ipriosTmp_result_leftIprio_20_0_enable)
         | ipriosTmp_result_sel_2231
         & (ipriosTmp_result_rightIprio_20_0_idx[5]
              ? ipriosTmp_result_leftIprio_20_0_enable
              : ipriosTmp_result_rightIprio_20_0_enable)
         | ipriosTmp_result_sel_2236
         & (ipriosTmp_result_sel_2244
              ? ipriosTmp_result_leftIprio_20_0_enable
              : ipriosTmp_result_rightIprio_20_0_enable));
    hvipriosReg_4_isZero <=
      ipriosTmp_result_sel_2221 & ipriosTmp_result_leftIprio_20_0_isZero
      | ipriosTmp_result_sel_2223 & ipriosTmp_result_rightIprio_20_0_isZero
      | ipriosTmp_result_sel_2224
      & (ipriosTmp_result_sel_2225 & ipriosTmp_result_leftIprio_20_0_isZero
         | ipriosTmp_result_sel_2227
         & (ipriosTmp_result_leftIprio_20_0_idx[5]
              ? ipriosTmp_result_rightIprio_20_0_isZero
              : ipriosTmp_result_leftIprio_20_0_isZero)
         | ipriosTmp_result_sel_2231
         & (ipriosTmp_result_rightIprio_20_0_idx[5]
              ? ipriosTmp_result_leftIprio_20_0_isZero
              : ipriosTmp_result_rightIprio_20_0_isZero)
         | ipriosTmp_result_sel_2236
         & (ipriosTmp_result_sel_2244
              ? ipriosTmp_result_leftIprio_20_0_isZero
              : ipriosTmp_result_rightIprio_20_0_isZero));
    hvipriosReg_4_prioNum <=
      (gGen_36 ? ipriosTmp_result_leftIprio_rightIprio_20_0_prioNum : 8'h0)
      | (ipriosTmp_result_sel_2223 & gGen_34 ? io_in_hviprio1_Prio15 : 8'h0)
      | (ipriosTmp_result_sel_2224
           ? (gGen_35 ? ipriosTmp_result_leftIprio_rightIprio_20_0_prioNum : 8'h0)
             | (ipriosTmp_result_sel_2227
                  ? (ipriosTmp_result_leftIprio_20_0_idx[5]
                       ? ipriosTmp_result_rightIprio_20_0_prioNum
                       : ipriosTmp_result_leftIprio_20_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_2231
                  ? (ipriosTmp_result_rightIprio_20_0_idx[5]
                       ? ipriosTmp_result_leftIprio_20_0_prioNum
                       : ipriosTmp_result_rightIprio_20_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_2236
                  ? (ipriosTmp_result_sel_2244
                       ? ipriosTmp_result_leftIprio_20_0_prioNum
                       : ipriosTmp_result_rightIprio_20_0_prioNum)
                  : 8'h0)
           : 8'h0);
    hvipriosReg_5_idx <=
      (ipriosTmp_result_sel_2332 ? ipriosTmp_result_leftIprio_21_0_idx : 6'h0)
      | (ipriosTmp_result_sel_2334 ? ipriosTmp_result_rightIprio_21_0_idx : 6'h0)
      | (ipriosTmp_result_sel_2335
           ? (ipriosTmp_result_sel_2336
                ? ipriosTmp_result_leftIprio_21_0_idx
                : 6'h0)
             | (ipriosTmp_result_sel_2338
                  ? (ipriosTmp_result_leftIprio_21_0_idx[5]
                       ? ipriosTmp_result_rightIprio_21_0_idx
                       : ipriosTmp_result_leftIprio_21_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_2342
                  ? (ipriosTmp_result_rightIprio_21_0_idx[5]
                       ? ipriosTmp_result_leftIprio_21_0_idx
                       : ipriosTmp_result_rightIprio_21_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_2347
                  ? ipriosTmp_result_leftIprio_21_0_idx
                  : 6'h0)
           : 6'h0);
    hvipriosReg_5_enable <=
      ipriosTmp_result_sel_2332 & ipriosTmp_result_leftIprio_21_0_enable
      | ipriosTmp_result_sel_2334 & ipriosTmp_result_rightIprio_21_0_enable
      | ipriosTmp_result_sel_2335
      & (ipriosTmp_result_sel_2336 & ipriosTmp_result_leftIprio_21_0_enable
         | ipriosTmp_result_sel_2338
         & (ipriosTmp_result_leftIprio_21_0_idx[5]
              ? ipriosTmp_result_rightIprio_21_0_enable
              : ipriosTmp_result_leftIprio_21_0_enable)
         | ipriosTmp_result_sel_2342
         & (ipriosTmp_result_rightIprio_21_0_idx[5]
              ? ipriosTmp_result_leftIprio_21_0_enable
              : ipriosTmp_result_rightIprio_21_0_enable)
         | ipriosTmp_result_sel_2347 & ipriosTmp_result_leftIprio_21_0_enable);
    hvipriosReg_5_isZero <=
      ipriosTmp_result_sel_2332 & ipriosTmp_result_leftIprio_21_0_isZero
      | ipriosTmp_result_sel_2334 & ipriosTmp_result_rightIprio_21_0_isZero
      | ipriosTmp_result_sel_2335
      & (ipriosTmp_result_sel_2336 & ipriosTmp_result_leftIprio_21_0_isZero
         | ipriosTmp_result_sel_2338
         & (ipriosTmp_result_leftIprio_21_0_idx[5]
              ? ipriosTmp_result_rightIprio_21_0_isZero
              : ipriosTmp_result_leftIprio_21_0_isZero)
         | ipriosTmp_result_sel_2342
         & (ipriosTmp_result_rightIprio_21_0_idx[5]
              ? ipriosTmp_result_leftIprio_21_0_isZero
              : ipriosTmp_result_rightIprio_21_0_isZero)
         | ipriosTmp_result_sel_2347 & ipriosTmp_result_leftIprio_21_0_isZero);
    hvipriosReg_5_prioNum <=
      ipriosTmp_result_sel_2334 | ipriosTmp_result_sel_2335
      & (ipriosTmp_result_sel_2338 & ipriosTmp_result_leftIprio_21_0_idx[5]
         | ipriosTmp_result_sel_2342 & ~(ipriosTmp_result_rightIprio_21_0_idx[5]))
        ? (ipriosTmp_result_rightIprio_sel_2332 & gGen_37
             ? io_in_hviprio2_ALL[31:24]
             : 8'h0)
          | (ipriosTmp_result_rightIprio_sel_2334 & gGen_38
               ? io_in_hviprio2_ALL[23:16]
               : 8'h0)
          | (ipriosTmp_result_rightIprio_sel_2335
               ? (ipriosTmp_result_rightIprio_sel_2336 & gGen_37
                    ? io_in_hviprio2_ALL[31:24]
                    : 8'h0)
                 | (ipriosTmp_result_rightIprio_sel_2338
                      ? (ipriosTmp_result_rightIprio_leftIprio_21_0_idx[5]
                           ? ipriosTmp_result_rightIprio_rightIprio_21_0_prioNum
                           : ipriosTmp_result_rightIprio_leftIprio_21_0_prioNum)
                      : 8'h0)
                 | (ipriosTmp_result_rightIprio_sel_2342
                      ? (ipriosTmp_result_rightIprio_rightIprio_21_0_idx[5]
                           ? ipriosTmp_result_rightIprio_leftIprio_21_0_prioNum
                           : ipriosTmp_result_rightIprio_rightIprio_21_0_prioNum)
                      : 8'h0)
                 | (ipriosTmp_result_rightIprio_sel_2347
                      ? (ipriosTmp_result_rightIprio_sel_2355
                           ? ipriosTmp_result_rightIprio_leftIprio_21_0_prioNum
                           : ipriosTmp_result_rightIprio_rightIprio_21_0_prioNum)
                      : 8'h0)
               : 8'h0)
        : 8'h0;
    hvipriosReg_6_idx <=
      (ipriosTmp_result_sel_2443 ? ipriosTmp_result_leftIprio_22_0_idx : 6'h0)
      | (ipriosTmp_result_sel_2445 ? ipriosTmp_result_rightIprio_22_0_idx : 6'h0)
      | (ipriosTmp_result_sel_2446
           ? (ipriosTmp_result_sel_2447
                ? ipriosTmp_result_leftIprio_22_0_idx
                : 6'h0)
             | (ipriosTmp_result_sel_2449
                  ? (ipriosTmp_result_leftIprio_22_0_idx[5]
                       ? ipriosTmp_result_rightIprio_22_0_idx
                       : ipriosTmp_result_leftIprio_22_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_2453
                  ? (ipriosTmp_result_rightIprio_22_0_idx[5]
                       ? ipriosTmp_result_leftIprio_22_0_idx
                       : ipriosTmp_result_rightIprio_22_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_2458
                  ? (ipriosTmp_result_sel_2466
                       ? ipriosTmp_result_leftIprio_22_0_idx
                       : ipriosTmp_result_rightIprio_22_0_idx)
                  : 6'h0)
           : 6'h0);
    hvipriosReg_6_enable <=
      ipriosTmp_result_sel_2443 & ipriosTmp_result_leftIprio_22_0_enable
      | ipriosTmp_result_sel_2445 & ipriosTmp_result_rightIprio_22_0_enable
      | ipriosTmp_result_sel_2446
      & (ipriosTmp_result_sel_2447 & ipriosTmp_result_leftIprio_22_0_enable
         | ipriosTmp_result_sel_2449
         & (ipriosTmp_result_leftIprio_22_0_idx[5]
              ? ipriosTmp_result_rightIprio_22_0_enable
              : ipriosTmp_result_leftIprio_22_0_enable)
         | ipriosTmp_result_sel_2453
         & (ipriosTmp_result_rightIprio_22_0_idx[5]
              ? ipriosTmp_result_leftIprio_22_0_enable
              : ipriosTmp_result_rightIprio_22_0_enable)
         | ipriosTmp_result_sel_2458
         & (ipriosTmp_result_sel_2466
              ? ipriosTmp_result_leftIprio_22_0_enable
              : ipriosTmp_result_rightIprio_22_0_enable));
    hvipriosReg_6_isZero <=
      ipriosTmp_result_sel_2443 & ipriosTmp_result_leftIprio_22_0_isZero
      | ipriosTmp_result_sel_2445 & ipriosTmp_result_rightIprio_22_0_isZero
      | ipriosTmp_result_sel_2446
      & (ipriosTmp_result_sel_2447 & ipriosTmp_result_leftIprio_22_0_isZero
         | ipriosTmp_result_sel_2449
         & (ipriosTmp_result_leftIprio_22_0_idx[5]
              ? ipriosTmp_result_rightIprio_22_0_isZero
              : ipriosTmp_result_leftIprio_22_0_isZero)
         | ipriosTmp_result_sel_2453
         & (ipriosTmp_result_rightIprio_22_0_idx[5]
              ? ipriosTmp_result_leftIprio_22_0_isZero
              : ipriosTmp_result_rightIprio_22_0_isZero)
         | ipriosTmp_result_sel_2458
         & (ipriosTmp_result_sel_2466
              ? ipriosTmp_result_leftIprio_22_0_isZero
              : ipriosTmp_result_rightIprio_22_0_isZero));
    hvipriosReg_6_prioNum <=
      (ipriosTmp_result_sel_2443 & gGen_40 ? io_in_hviprio2_ALL[15:8] : 8'h0)
      | (ipriosTmp_result_sel_2445 & gGen_42 ? io_in_hviprio2_ALL[7:0] : 8'h0)
      | (ipriosTmp_result_sel_2446
           ? (ipriosTmp_result_sel_2447 & gGen_40
                ? io_in_hviprio2_ALL[15:8]
                : 8'h0)
             | (ipriosTmp_result_sel_2449
                  ? (ipriosTmp_result_leftIprio_22_0_idx[5]
                       ? ipriosTmp_result_rightIprio_22_0_prioNum
                       : ipriosTmp_result_leftIprio_22_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_2453
                  ? (ipriosTmp_result_rightIprio_22_0_idx[5]
                       ? ipriosTmp_result_leftIprio_22_0_prioNum
                       : ipriosTmp_result_rightIprio_22_0_prioNum)
                  : 8'h0)
             | (ipriosTmp_result_sel_2458
                  ? (ipriosTmp_result_sel_2466
                       ? ipriosTmp_result_leftIprio_22_0_prioNum
                       : ipriosTmp_result_rightIprio_22_0_prioNum)
                  : 8'h0)
           : 8'h0);
    hvipriosReg_7_idx <=
      (ipriosTmp_result_sel_2554 ? ipriosTmp_result_leftIprio_23_0_idx : 6'h0)
      | (ipriosTmp_result_sel_2556 & hvipriosSort_60_isZero ? 6'h3C : 6'h0)
      | (ipriosTmp_result_sel_2557
           ? (ipriosTmp_result_sel_2558
                ? ipriosTmp_result_leftIprio_23_0_idx
                : 6'h0)
             | (ipriosTmp_result_sel_2560
                  ? (ipriosTmp_result_leftIprio_23_0_idx[5]
                       ? ipriosTmp_result_rightIprio_23_0_idx
                       : ipriosTmp_result_leftIprio_23_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_2564
                  ? (ipriosTmp_result_rightIprio_23_0_idx[5]
                       ? ipriosTmp_result_leftIprio_23_0_idx
                       : ipriosTmp_result_rightIprio_23_0_idx)
                  : 6'h0)
             | (ipriosTmp_result_sel_2569
                  ? ipriosTmp_result_leftIprio_23_0_idx
                  : 6'h0)
           : 6'h0);
    hvipriosReg_7_enable <=
      ipriosTmp_result_sel_2554 & ipriosTmp_result_leftIprio_23_0_enable
      | ipriosTmp_result_sel_2556 & hvipriosSort_60_isZero
      | ipriosTmp_result_sel_2557
      & (ipriosTmp_result_sel_2558 & ipriosTmp_result_leftIprio_23_0_enable
         | ipriosTmp_result_sel_2560
         & (ipriosTmp_result_leftIprio_23_0_idx[5]
              ? hvipriosSort_60_isZero
              : ipriosTmp_result_leftIprio_23_0_enable)
         | ipriosTmp_result_sel_2564
         & (ipriosTmp_result_rightIprio_23_0_idx[5]
              ? ipriosTmp_result_leftIprio_23_0_enable
              : hvipriosSort_60_isZero) | ipriosTmp_result_sel_2569
         & ipriosTmp_result_leftIprio_23_0_enable);
    hvipriosReg_7_isZero <=
      ipriosTmp_result_sel_2554 & ipriosTmp_result_leftIprio_23_0_isZero
      | ipriosTmp_result_sel_2556 & hvipriosSort_60_isZero
      | ipriosTmp_result_sel_2557
      & (ipriosTmp_result_sel_2558 & ipriosTmp_result_leftIprio_23_0_isZero
         | ipriosTmp_result_sel_2560
         & (ipriosTmp_result_leftIprio_23_0_idx[5]
              ? hvipriosSort_60_isZero
              : ipriosTmp_result_leftIprio_23_0_isZero)
         | ipriosTmp_result_sel_2564
         & (ipriosTmp_result_rightIprio_23_0_idx[5]
              ? ipriosTmp_result_leftIprio_23_0_isZero
              : hvipriosSort_60_isZero) | ipriosTmp_result_sel_2569
         & ipriosTmp_result_leftIprio_23_0_isZero);
  end // always @(posedge)
  DelayN_210 delayedIntrVec_delay (
    .clock  (clock),
    .io_in  (intrVecReg),
    .io_out (_delayedIntrVec_delay_io_out)
  );
  DelayN_17 delayedDebugIntr_delay (
    .clock  (clock),
    .io_in  (debugIntrReg),
    .io_out (_delayedDebugIntr_delay_io_out)
  );
  DelayN_17 delayedNMI_delay (
    .clock  (clock),
    .io_in  (nmiReg),
    .io_out (_delayedNMI_delay_io_out)
  );
  DelayN_17 delayedVIIsHvictlInjectReg_delay (
    .clock  (clock),
    .io_in  (viIsHvictlInjectReg),
    .io_out (_delayedVIIsHvictlInjectReg_delay_io_out)
  );
  DelayN_17 delayedIRToHS_delay (
    .clock  (clock),
    .io_in  (irToHSReg),
    .io_out (_delayedIRToHS_delay_io_out)
  );
  DelayN_17 delayedIRToVS_delay (
    .clock  (clock),
    .io_in  (irToVSReg),
    .io_out (_delayedIRToVS_delay_io_out)
  );
  assign io_out_debug = _delayedDebugIntr_delay_io_out;
  assign io_out_nmi = _delayedNMI_delay_io_out;
  assign io_out_interruptVec_valid =
    (|_delayedIntrVec_delay_io_out) | _delayedDebugIntr_delay_io_out
    | _delayedVIIsHvictlInjectReg_delay_io_out;
  assign io_out_interruptVec_bits = _delayedIntrVec_delay_io_out;
  assign io_out_mtopi_IID = mtopiIidWire;
  assign io_out_mtopi_IPRIO =
    (|mPendingVec)
      ? (mipriosRegTmp_result_0_isZero | mipriosRegTmp_result_0_greaterThan255
           ? 8'h0
           : (mipriosRegTmp_result_sel_1
                ? mipriosRegTmp_result_leftIprio_0_prioNum
                : 8'h0)
             | (mipriosRegTmp_result_sel_3
                  ? mipriosRegTmp_result_rightIprio_0_prioNum
                  : 8'h0)
             | (mipriosRegTmp_result_sel_4
                  ? (mipriosRegTmp_result_sel_5
                       ? mipriosRegTmp_result_leftIprio_0_prioNum
                       : 8'h0)
                    | (mipriosRegTmp_result_sel_7
                         ? (mipriosRegTmp_result_sel_8
                              ? mipriosRegTmp_result_leftIprio_0_prioNum
                              : mipriosRegTmp_result_rightIprio_0_prioNum)
                         : 8'h0)
                    | (mipriosRegTmp_result_sel_11
                         ? (mipriosRegTmp_result_sel_12
                              ? mipriosRegTmp_result_rightIprio_0_prioNum
                              : mipriosRegTmp_result_leftIprio_0_prioNum)
                         : 8'h0)
                    | (mipriosRegTmp_result_sel_16
                         ? (mipriosRegTmp_result_leftIprio_0_greaterThan255
                              ? mipriosRegTmp_result_rightIprio_0_prioNum
                              : 8'h0)
                           | (mipriosRegTmp_result_leftIprio_0_greaterThan255
                                ? 8'h0
                                : mipriosRegTmp_result_sel_24
                                    ? mipriosRegTmp_result_leftIprio_0_prioNum
                                    : mipriosRegTmp_result_rightIprio_0_prioNum)
                         : 8'h0)
                  : 8'h0))
        | {8{mipriosRegTmp_result_0_greaterThan255 | mipriosRegTmp_result_0_isZero
               & mipriosRegTmp_result_0_idx > 6'h18}}
      : 8'h0;
  assign io_out_stopi_IID = stopiIidWire;
  assign io_out_stopi_IPRIO =
    (|hsPendingMask)
      ? (hsipriosRegTmp_result_0_isZero | hsipriosRegTmp_result_0_greaterThan255
           ? 8'h0
           : (hsipriosRegTmp_result_sel_1
                ? hsipriosRegTmp_result_leftIprio_0_prioNum
                : 8'h0)
             | (hsipriosRegTmp_result_sel_3
                  ? hsipriosRegTmp_result_rightIprio_0_prioNum
                  : 8'h0)
             | (hsipriosRegTmp_result_sel_4
                  ? (hsipriosRegTmp_result_sel_5
                       ? hsipriosRegTmp_result_leftIprio_0_prioNum
                       : 8'h0)
                    | (hsipriosRegTmp_result_sel_7
                         ? (hsipriosRegTmp_result_sel_8
                              ? hsipriosRegTmp_result_leftIprio_0_prioNum
                              : hsipriosRegTmp_result_rightIprio_0_prioNum)
                         : 8'h0)
                    | (hsipriosRegTmp_result_sel_11
                         ? (hsipriosRegTmp_result_sel_12
                              ? hsipriosRegTmp_result_rightIprio_0_prioNum
                              : hsipriosRegTmp_result_leftIprio_0_prioNum)
                         : 8'h0)
                    | (hsipriosRegTmp_result_sel_16
                         ? (hsipriosRegTmp_result_leftIprio_0_greaterThan255
                              ? hsipriosRegTmp_result_rightIprio_0_prioNum
                              : 8'h0)
                           | (hsipriosRegTmp_result_leftIprio_0_greaterThan255
                                ? 8'h0
                                : hsipriosRegTmp_result_sel_24
                                    ? hsipriosRegTmp_result_leftIprio_0_prioNum
                                    : hsipriosRegTmp_result_rightIprio_0_prioNum)
                         : 8'h0)
                  : 8'h0))
        | {8{hsipriosRegTmp_result_0_greaterThan255 | hsipriosRegTmp_result_0_isZero
               & hsipriosRegTmp_result_0_idx > 6'h1B}}
      : 8'h0;
  assign io_out_vstopi_IID = CandidateNoValid ? 12'h0 : vsInjectedIID;
  assign io_out_vstopi_IPRIO =
    CandidateNoValid
      ? 8'h0
      : io_in_hvictl_IPRIOM
          ? (Candidate1 & ~Candidate45 ? iprioOnlyC1 : 8'h0)
            | (Candidate2 & ~Candidate45 ? io_in_hvictl_IPRIO : 8'h0)
            | {8{Candidate3 & ~Candidate123}} | (onlyC4Enable ? iprioC4Tmp : 8'h0)
            | (onlyC5Enable ? iprioC3C5Tmp : 8'h0)
            | (C1C4Enable
                 ? (C4IsZero
                      ? (C4HighVSEI ? 8'h0 : iprioOnlyC1)
                      : vstopeiLtC4 | vstopeiEqC4 & SEIHighC4
                          ? iprioC1Tmp
                          : hvipriosRegTmp_result_0_prioNum)
                 : 8'h0)
            | (C1C5Enable
                 ? (C2C5IsZero
                      ? (io_in_hvictl_DPR ? iprioOnlyC1 : 8'h0)
                      : vstopeiLtC2C5
                          ? iprioC1Tmp
                          : vstopeiEqC2C5
                              ? (io_in_hvictl_DPR ? iprioC1Tmp : io_in_hvictl_IPRIO)
                              : iprioC3C5Tmp)
                 : 8'h0)
            | (C2C4Enable
                 ? (C4IsZero
                      ? (C4HighVSEI ? 8'h0 : io_in_hvictl_IPRIO)
                      : hvictlLtC4 | hvictlEqC4 & SEIHighC4
                          ? io_in_hvictl_IPRIO
                          : hvipriosRegTmp_result_0_prioNum)
                 : 8'h0) | (C3C4Enable ? iprioC4Tmp : 8'h0)
            | (C3C5Enable ? iprioC3C5Tmp : 8'h0)
          : 8'h1;
  assign io_out_virtualInterruptIsHvictlInject =
    _delayedVIIsHvictlInjectReg_delay_io_out & ~_delayedNMI_delay_io_out;
  assign io_out_irToHS = _delayedIRToHS_delay_io_out & ~_delayedNMI_delay_io_out;
  assign io_out_irToVS = _delayedIRToVS_delay_io_out & ~_delayedNMI_delay_io_out;
endmodule
