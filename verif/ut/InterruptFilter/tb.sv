// =============================================================================
// tb —— InterruptFilter UT：golden InterruptFilter (u_g) vs 可读核 InterruptFilter_xs (u_i)
//
// 被测件是两级流水 + 5 拍延迟的纯同步逻辑，没有握手、没有反压：每拍随机换一组
// 输入，隔一拍比全部 13 个输出。比较窗口在复位释放若干拍之后打开。
//
// 激励要点（光靠均匀随机打不到的地方）：
//   · 中断密度 p_one 在 {2,10,50,90} 之间轮换 —— 稀疏时能测出"只有一个候选"
//     和"一个都没有"，稠密时把 61 路优先级树压满。
//   · hvictl.IID 有相当概率取 12'h9（Candidate2/Candidate5 的分界值）。
//   · hstatus.VGEIN 有相当概率取 0（Candidate1/Candidate2 的分界值）。
//   · vstopei/mtopei/stopei 的 IPRIO 高 3 位有相当概率非零（greaterThan255 那一支）
//     和恰好为 0（isZero 那一支）。
//   · privState 只有 4 种组合，2 位随机就能全覆盖。
//   · reset 偶尔重新拉起，覆盖异步复位域。
// =============================================================================
`timescale 1ns/1ps
module tb;

  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0;

  logic clock = 0;
  logic reset = 1;
  always #5 clock = ~clock;

  // golden 输出为 X 时不判（流水未灌满 / 无复位寄存器尚未确定）。
  `define CK(g,i,nm) \
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \
      if (errors<=60) $display("[%0t] MISMATCH %s g=%h i=%h", $time, nm, g, i); end \
    checks++;

// BEGIN GENERATED(tb)
  // 本段由 gen.py 从 G1 golden 端口表现读现生成，勿手改。
  // 311 个端口全按 golden 原名声明；两个 DUT 用 .* 连输入，只把 13 个输出
  // 显式引到 g_/i_ 两组线上。

  logic [1:0]    io_in_privState_PRVM;
  logic          io_in_privState_V;
  logic          io_in_mstatusMIE;
  logic          io_in_sstatusSIE;
  logic          io_in_vsstatusSIE;
  logic          io_in_mip_SSIP;
  logic          io_in_mip_VSSIP;
  logic          io_in_mip_MSIP;
  logic          io_in_mip_STIP;
  logic          io_in_mip_VSTIP;
  logic          io_in_mip_MTIP;
  logic          io_in_mip_SEIP;
  logic          io_in_mip_VSEIP;
  logic          io_in_mip_MEIP;
  logic          io_in_mip_SGEIP;
  logic          io_in_mip_LCOFIP;
  logic          io_in_mie_SSIE;
  logic          io_in_mie_VSSIE;
  logic          io_in_mie_MSIE;
  logic          io_in_mie_STIE;
  logic          io_in_mie_VSTIE;
  logic          io_in_mie_MTIE;
  logic          io_in_mie_SEIE;
  logic          io_in_mie_VSEIE;
  logic          io_in_mie_MEIE;
  logic          io_in_mie_SGEIE;
  logic          io_in_mie_LCOFIE;
  logic          io_in_mideleg_SSI;
  logic          io_in_mideleg_STI;
  logic          io_in_mideleg_SEI;
  logic          io_in_mideleg_LCOFI;
  logic          io_in_sip_SSIP;
  logic          io_in_sip_STIP;
  logic          io_in_sip_SEIP;
  logic          io_in_sip_LCOFIP;
  logic          io_in_sip_LC14IP;
  logic          io_in_sip_LC15IP;
  logic          io_in_sip_LC16IP;
  logic          io_in_sip_LC17IP;
  logic          io_in_sip_LC18IP;
  logic          io_in_sip_LC19IP;
  logic          io_in_sip_LC20IP;
  logic          io_in_sip_LC21IP;
  logic          io_in_sip_LC22IP;
  logic          io_in_sip_LC23IP;
  logic          io_in_sip_LC24IP;
  logic          io_in_sip_LC25IP;
  logic          io_in_sip_LC26IP;
  logic          io_in_sip_LC27IP;
  logic          io_in_sip_LC28IP;
  logic          io_in_sip_LC29IP;
  logic          io_in_sip_LC30IP;
  logic          io_in_sip_LC31IP;
  logic          io_in_sip_LC32IP;
  logic          io_in_sip_LC33IP;
  logic          io_in_sip_LC34IP;
  logic          io_in_sip_LPRASEIP;
  logic          io_in_sip_LC36IP;
  logic          io_in_sip_LC37IP;
  logic          io_in_sip_LC38IP;
  logic          io_in_sip_LC39IP;
  logic          io_in_sip_LC40IP;
  logic          io_in_sip_LC41IP;
  logic          io_in_sip_LC42IP;
  logic          io_in_sip_HPRASEIP;
  logic          io_in_sip_LC44IP;
  logic          io_in_sip_LC45IP;
  logic          io_in_sip_LC46IP;
  logic          io_in_sip_LC47IP;
  logic          io_in_sip_LC48IP;
  logic          io_in_sip_LC49IP;
  logic          io_in_sip_LC50IP;
  logic          io_in_sip_LC51IP;
  logic          io_in_sip_LC52IP;
  logic          io_in_sip_LC53IP;
  logic          io_in_sip_LC54IP;
  logic          io_in_sip_LC55IP;
  logic          io_in_sip_LC56IP;
  logic          io_in_sip_LC57IP;
  logic          io_in_sip_LC58IP;
  logic          io_in_sip_LC59IP;
  logic          io_in_sip_LC60IP;
  logic          io_in_sip_LC61IP;
  logic          io_in_sip_LC62IP;
  logic          io_in_sip_LC63IP;
  logic          io_in_sie_SSIE;
  logic          io_in_sie_STIE;
  logic          io_in_sie_SEIE;
  logic          io_in_sie_LCOFIE;
  logic          io_in_sie_LC14IE;
  logic          io_in_sie_LC15IE;
  logic          io_in_sie_LC16IE;
  logic          io_in_sie_LC17IE;
  logic          io_in_sie_LC18IE;
  logic          io_in_sie_LC19IE;
  logic          io_in_sie_LC20IE;
  logic          io_in_sie_LC21IE;
  logic          io_in_sie_LC22IE;
  logic          io_in_sie_LC23IE;
  logic          io_in_sie_LC24IE;
  logic          io_in_sie_LC25IE;
  logic          io_in_sie_LC26IE;
  logic          io_in_sie_LC27IE;
  logic          io_in_sie_LC28IE;
  logic          io_in_sie_LC29IE;
  logic          io_in_sie_LC30IE;
  logic          io_in_sie_LC31IE;
  logic          io_in_sie_LC32IE;
  logic          io_in_sie_LC33IE;
  logic          io_in_sie_LC34IE;
  logic          io_in_sie_LPRASEIE;
  logic          io_in_sie_LC36IE;
  logic          io_in_sie_LC37IE;
  logic          io_in_sie_LC38IE;
  logic          io_in_sie_LC39IE;
  logic          io_in_sie_LC40IE;
  logic          io_in_sie_LC41IE;
  logic          io_in_sie_LC42IE;
  logic          io_in_sie_HPRASEIE;
  logic          io_in_sie_LC44IE;
  logic          io_in_sie_LC45IE;
  logic          io_in_sie_LC46IE;
  logic          io_in_sie_LC47IE;
  logic          io_in_sie_LC48IE;
  logic          io_in_sie_LC49IE;
  logic          io_in_sie_LC50IE;
  logic          io_in_sie_LC51IE;
  logic          io_in_sie_LC52IE;
  logic          io_in_sie_LC53IE;
  logic          io_in_sie_LC54IE;
  logic          io_in_sie_LC55IE;
  logic          io_in_sie_LC56IE;
  logic          io_in_sie_LC57IE;
  logic          io_in_sie_LC58IE;
  logic          io_in_sie_LC59IE;
  logic          io_in_sie_LC60IE;
  logic          io_in_sie_LC61IE;
  logic          io_in_sie_LC62IE;
  logic          io_in_sie_LC63IE;
  logic          io_in_hip_VSSIP;
  logic          io_in_hip_VSTIP;
  logic          io_in_hip_VSEIP;
  logic          io_in_hip_SGEIP;
  logic          io_in_hie_VSSIE;
  logic          io_in_hie_VSTIE;
  logic          io_in_hie_VSEIE;
  logic          io_in_hie_SGEIE;
  logic          io_in_hideleg_SSI;
  logic          io_in_hideleg_VSSI;
  logic          io_in_hideleg_MSI;
  logic          io_in_hideleg_STI;
  logic          io_in_hideleg_VSTI;
  logic          io_in_hideleg_MTI;
  logic          io_in_hideleg_SEI;
  logic          io_in_hideleg_VSEI;
  logic          io_in_hideleg_MEI;
  logic          io_in_hideleg_SGEI;
  logic          io_in_hideleg_LCOFI;
  logic          io_in_vsip_SSIP;
  logic          io_in_vsip_STIP;
  logic          io_in_vsip_SEIP;
  logic          io_in_vsip_LCOFIP;
  logic          io_in_vsip_LC14IP;
  logic          io_in_vsip_LC15IP;
  logic          io_in_vsip_LC16IP;
  logic          io_in_vsip_LC17IP;
  logic          io_in_vsip_LC18IP;
  logic          io_in_vsip_LC19IP;
  logic          io_in_vsip_LC20IP;
  logic          io_in_vsip_LC21IP;
  logic          io_in_vsip_LC22IP;
  logic          io_in_vsip_LC23IP;
  logic          io_in_vsip_LC24IP;
  logic          io_in_vsip_LC25IP;
  logic          io_in_vsip_LC26IP;
  logic          io_in_vsip_LC27IP;
  logic          io_in_vsip_LC28IP;
  logic          io_in_vsip_LC29IP;
  logic          io_in_vsip_LC30IP;
  logic          io_in_vsip_LC31IP;
  logic          io_in_vsip_LC32IP;
  logic          io_in_vsip_LC33IP;
  logic          io_in_vsip_LC34IP;
  logic          io_in_vsip_LPRASEIP;
  logic          io_in_vsip_LC36IP;
  logic          io_in_vsip_LC37IP;
  logic          io_in_vsip_LC38IP;
  logic          io_in_vsip_LC39IP;
  logic          io_in_vsip_LC40IP;
  logic          io_in_vsip_LC41IP;
  logic          io_in_vsip_LC42IP;
  logic          io_in_vsip_HPRASEIP;
  logic          io_in_vsip_LC44IP;
  logic          io_in_vsip_LC45IP;
  logic          io_in_vsip_LC46IP;
  logic          io_in_vsip_LC47IP;
  logic          io_in_vsip_LC48IP;
  logic          io_in_vsip_LC49IP;
  logic          io_in_vsip_LC50IP;
  logic          io_in_vsip_LC51IP;
  logic          io_in_vsip_LC52IP;
  logic          io_in_vsip_LC53IP;
  logic          io_in_vsip_LC54IP;
  logic          io_in_vsip_LC55IP;
  logic          io_in_vsip_LC56IP;
  logic          io_in_vsip_LC57IP;
  logic          io_in_vsip_LC58IP;
  logic          io_in_vsip_LC59IP;
  logic          io_in_vsip_LC60IP;
  logic          io_in_vsip_LC61IP;
  logic          io_in_vsip_LC62IP;
  logic          io_in_vsip_LC63IP;
  logic          io_in_vsie_SSIE;
  logic          io_in_vsie_STIE;
  logic          io_in_vsie_SEIE;
  logic          io_in_vsie_LCOFIE;
  logic          io_in_vsie_LC14IE;
  logic          io_in_vsie_LC15IE;
  logic          io_in_vsie_LC16IE;
  logic          io_in_vsie_LC17IE;
  logic          io_in_vsie_LC18IE;
  logic          io_in_vsie_LC19IE;
  logic          io_in_vsie_LC20IE;
  logic          io_in_vsie_LC21IE;
  logic          io_in_vsie_LC22IE;
  logic          io_in_vsie_LC23IE;
  logic          io_in_vsie_LC24IE;
  logic          io_in_vsie_LC25IE;
  logic          io_in_vsie_LC26IE;
  logic          io_in_vsie_LC27IE;
  logic          io_in_vsie_LC28IE;
  logic          io_in_vsie_LC29IE;
  logic          io_in_vsie_LC30IE;
  logic          io_in_vsie_LC31IE;
  logic          io_in_vsie_LC32IE;
  logic          io_in_vsie_LC33IE;
  logic          io_in_vsie_LC34IE;
  logic          io_in_vsie_LPRASEIE;
  logic          io_in_vsie_LC36IE;
  logic          io_in_vsie_LC37IE;
  logic          io_in_vsie_LC38IE;
  logic          io_in_vsie_LC39IE;
  logic          io_in_vsie_LC40IE;
  logic          io_in_vsie_LC41IE;
  logic          io_in_vsie_LC42IE;
  logic          io_in_vsie_HPRASEIE;
  logic          io_in_vsie_LC44IE;
  logic          io_in_vsie_LC45IE;
  logic          io_in_vsie_LC46IE;
  logic          io_in_vsie_LC47IE;
  logic          io_in_vsie_LC48IE;
  logic          io_in_vsie_LC49IE;
  logic          io_in_vsie_LC50IE;
  logic          io_in_vsie_LC51IE;
  logic          io_in_vsie_LC52IE;
  logic          io_in_vsie_LC53IE;
  logic          io_in_vsie_LC54IE;
  logic          io_in_vsie_LC55IE;
  logic          io_in_vsie_LC56IE;
  logic          io_in_vsie_LC57IE;
  logic          io_in_vsie_LC58IE;
  logic          io_in_vsie_LC59IE;
  logic          io_in_vsie_LC60IE;
  logic          io_in_vsie_LC61IE;
  logic          io_in_vsie_LC62IE;
  logic          io_in_vsie_LC63IE;
  logic          io_in_hvictl_VTI;
  logic [11:0]   io_in_hvictl_IID;
  logic          io_in_hvictl_DPR;
  logic          io_in_hvictl_IPRIOM;
  logic [7:0]    io_in_hvictl_IPRIO;
  logic [5:0]    io_in_hstatus_VGEIN;
  logic [10:0]   io_in_mtopei_IPRIO;
  logic [10:0]   io_in_stopei_IPRIO;
  logic [10:0]   io_in_vstopei_IID;
  logic [10:0]   io_in_vstopei_IPRIO;
  logic [7:0]    io_in_hviprio1_PrioSSI;
  logic [7:0]    io_in_hviprio1_PrioSTI;
  logic [7:0]    io_in_hviprio1_PrioCOI;
  logic [7:0]    io_in_hviprio1_Prio14;
  logic [7:0]    io_in_hviprio1_Prio15;
  logic [63:0]   io_in_hviprio2_ALL;
  logic          io_in_debugIntr;
  logic          io_in_debugMode;
  logic          io_in_dcsr_STEPIE;
  logic          io_in_dcsr_STEP;
  logic [511:0]  io_in_miprios;
  logic [511:0]  io_in_hsiprios;
  logic          io_in_nmi;
  logic [63:0]   io_in_nmiVec;
  logic          io_in_mnstatusNMIE;
  logic          io_in_platform_meip;
  logic          io_in_platform_seip;
  logic          io_in_fromAIA_seip;
  logic          io_in_mvienSEIE;
  logic          io_in_mvipSEIP;

  logic          g_io_out_debug, i_io_out_debug;
  logic          g_io_out_nmi, i_io_out_nmi;
  logic          g_io_out_interruptVec_valid, i_io_out_interruptVec_valid;
  logic [7:0]    g_io_out_interruptVec_bits, i_io_out_interruptVec_bits;
  logic [11:0]   g_io_out_mtopi_IID, i_io_out_mtopi_IID;
  logic [7:0]    g_io_out_mtopi_IPRIO, i_io_out_mtopi_IPRIO;
  logic [11:0]   g_io_out_stopi_IID, i_io_out_stopi_IID;
  logic [7:0]    g_io_out_stopi_IPRIO, i_io_out_stopi_IPRIO;
  logic [11:0]   g_io_out_vstopi_IID, i_io_out_vstopi_IID;
  logic [7:0]    g_io_out_vstopi_IPRIO, i_io_out_vstopi_IPRIO;
  logic          g_io_out_virtualInterruptIsHvictlInject, i_io_out_virtualInterruptIsHvictlInject;
  logic          g_io_out_irToHS, i_io_out_irToHS;
  logic          g_io_out_irToVS, i_io_out_irToVS;

  InterruptFilter u_g (.*,
    .io_out_debug(g_io_out_debug),
    .io_out_nmi(g_io_out_nmi),
    .io_out_interruptVec_valid(g_io_out_interruptVec_valid),
    .io_out_interruptVec_bits(g_io_out_interruptVec_bits),
    .io_out_mtopi_IID(g_io_out_mtopi_IID),
    .io_out_mtopi_IPRIO(g_io_out_mtopi_IPRIO),
    .io_out_stopi_IID(g_io_out_stopi_IID),
    .io_out_stopi_IPRIO(g_io_out_stopi_IPRIO),
    .io_out_vstopi_IID(g_io_out_vstopi_IID),
    .io_out_vstopi_IPRIO(g_io_out_vstopi_IPRIO),
    .io_out_virtualInterruptIsHvictlInject(g_io_out_virtualInterruptIsHvictlInject),
    .io_out_irToHS(g_io_out_irToHS),
    .io_out_irToVS(g_io_out_irToVS));

  InterruptFilter_xs u_i (.*,
    .io_out_debug(i_io_out_debug),
    .io_out_nmi(i_io_out_nmi),
    .io_out_interruptVec_valid(i_io_out_interruptVec_valid),
    .io_out_interruptVec_bits(i_io_out_interruptVec_bits),
    .io_out_mtopi_IID(i_io_out_mtopi_IID),
    .io_out_mtopi_IPRIO(i_io_out_mtopi_IPRIO),
    .io_out_stopi_IID(i_io_out_stopi_IID),
    .io_out_stopi_IPRIO(i_io_out_stopi_IPRIO),
    .io_out_vstopi_IID(i_io_out_vstopi_IID),
    .io_out_vstopi_IPRIO(i_io_out_vstopi_IPRIO),
    .io_out_virtualInterruptIsHvictlInject(i_io_out_virtualInterruptIsHvictlInject),
    .io_out_irToHS(i_io_out_irToHS),
    .io_out_irToVS(i_io_out_irToVS));

  // 通用随机激励：1 位端口按 p_one/100 的概率置 1（控制中断密度），
  // 多位端口全随机。感兴趣的字段由手写区的 drive() 事后改写。
  task automatic drive_all(input int unsigned p_one);
    begin
      io_in_privState_PRVM = $urandom;
      io_in_privState_V = ($urandom_range(0, 99) < p_one);
      io_in_mstatusMIE = ($urandom_range(0, 99) < p_one);
      io_in_sstatusSIE = ($urandom_range(0, 99) < p_one);
      io_in_vsstatusSIE = ($urandom_range(0, 99) < p_one);
      io_in_mip_SSIP = ($urandom_range(0, 99) < p_one);
      io_in_mip_VSSIP = ($urandom_range(0, 99) < p_one);
      io_in_mip_MSIP = ($urandom_range(0, 99) < p_one);
      io_in_mip_STIP = ($urandom_range(0, 99) < p_one);
      io_in_mip_VSTIP = ($urandom_range(0, 99) < p_one);
      io_in_mip_MTIP = ($urandom_range(0, 99) < p_one);
      io_in_mip_SEIP = ($urandom_range(0, 99) < p_one);
      io_in_mip_VSEIP = ($urandom_range(0, 99) < p_one);
      io_in_mip_MEIP = ($urandom_range(0, 99) < p_one);
      io_in_mip_SGEIP = ($urandom_range(0, 99) < p_one);
      io_in_mip_LCOFIP = ($urandom_range(0, 99) < p_one);
      io_in_mie_SSIE = ($urandom_range(0, 99) < p_one);
      io_in_mie_VSSIE = ($urandom_range(0, 99) < p_one);
      io_in_mie_MSIE = ($urandom_range(0, 99) < p_one);
      io_in_mie_STIE = ($urandom_range(0, 99) < p_one);
      io_in_mie_VSTIE = ($urandom_range(0, 99) < p_one);
      io_in_mie_MTIE = ($urandom_range(0, 99) < p_one);
      io_in_mie_SEIE = ($urandom_range(0, 99) < p_one);
      io_in_mie_VSEIE = ($urandom_range(0, 99) < p_one);
      io_in_mie_MEIE = ($urandom_range(0, 99) < p_one);
      io_in_mie_SGEIE = ($urandom_range(0, 99) < p_one);
      io_in_mie_LCOFIE = ($urandom_range(0, 99) < p_one);
      io_in_mideleg_SSI = ($urandom_range(0, 99) < p_one);
      io_in_mideleg_STI = ($urandom_range(0, 99) < p_one);
      io_in_mideleg_SEI = ($urandom_range(0, 99) < p_one);
      io_in_mideleg_LCOFI = ($urandom_range(0, 99) < p_one);
      io_in_sip_SSIP = ($urandom_range(0, 99) < p_one);
      io_in_sip_STIP = ($urandom_range(0, 99) < p_one);
      io_in_sip_SEIP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LCOFIP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC14IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC15IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC16IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC17IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC18IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC19IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC20IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC21IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC22IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC23IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC24IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC25IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC26IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC27IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC28IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC29IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC30IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC31IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC32IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC33IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC34IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LPRASEIP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC36IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC37IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC38IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC39IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC40IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC41IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC42IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_HPRASEIP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC44IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC45IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC46IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC47IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC48IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC49IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC50IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC51IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC52IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC53IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC54IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC55IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC56IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC57IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC58IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC59IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC60IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC61IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC62IP = ($urandom_range(0, 99) < p_one);
      io_in_sip_LC63IP = ($urandom_range(0, 99) < p_one);
      io_in_sie_SSIE = ($urandom_range(0, 99) < p_one);
      io_in_sie_STIE = ($urandom_range(0, 99) < p_one);
      io_in_sie_SEIE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LCOFIE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC14IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC15IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC16IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC17IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC18IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC19IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC20IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC21IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC22IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC23IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC24IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC25IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC26IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC27IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC28IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC29IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC30IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC31IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC32IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC33IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC34IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LPRASEIE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC36IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC37IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC38IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC39IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC40IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC41IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC42IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_HPRASEIE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC44IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC45IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC46IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC47IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC48IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC49IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC50IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC51IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC52IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC53IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC54IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC55IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC56IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC57IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC58IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC59IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC60IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC61IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC62IE = ($urandom_range(0, 99) < p_one);
      io_in_sie_LC63IE = ($urandom_range(0, 99) < p_one);
      io_in_hip_VSSIP = ($urandom_range(0, 99) < p_one);
      io_in_hip_VSTIP = ($urandom_range(0, 99) < p_one);
      io_in_hip_VSEIP = ($urandom_range(0, 99) < p_one);
      io_in_hip_SGEIP = ($urandom_range(0, 99) < p_one);
      io_in_hie_VSSIE = ($urandom_range(0, 99) < p_one);
      io_in_hie_VSTIE = ($urandom_range(0, 99) < p_one);
      io_in_hie_VSEIE = ($urandom_range(0, 99) < p_one);
      io_in_hie_SGEIE = ($urandom_range(0, 99) < p_one);
      io_in_hideleg_SSI = ($urandom_range(0, 99) < p_one);
      io_in_hideleg_VSSI = ($urandom_range(0, 99) < p_one);
      io_in_hideleg_MSI = ($urandom_range(0, 99) < p_one);
      io_in_hideleg_STI = ($urandom_range(0, 99) < p_one);
      io_in_hideleg_VSTI = ($urandom_range(0, 99) < p_one);
      io_in_hideleg_MTI = ($urandom_range(0, 99) < p_one);
      io_in_hideleg_SEI = ($urandom_range(0, 99) < p_one);
      io_in_hideleg_VSEI = ($urandom_range(0, 99) < p_one);
      io_in_hideleg_MEI = ($urandom_range(0, 99) < p_one);
      io_in_hideleg_SGEI = ($urandom_range(0, 99) < p_one);
      io_in_hideleg_LCOFI = ($urandom_range(0, 99) < p_one);
      io_in_vsip_SSIP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_STIP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_SEIP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LCOFIP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC14IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC15IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC16IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC17IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC18IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC19IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC20IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC21IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC22IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC23IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC24IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC25IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC26IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC27IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC28IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC29IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC30IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC31IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC32IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC33IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC34IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LPRASEIP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC36IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC37IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC38IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC39IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC40IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC41IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC42IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_HPRASEIP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC44IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC45IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC46IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC47IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC48IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC49IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC50IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC51IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC52IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC53IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC54IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC55IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC56IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC57IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC58IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC59IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC60IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC61IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC62IP = ($urandom_range(0, 99) < p_one);
      io_in_vsip_LC63IP = ($urandom_range(0, 99) < p_one);
      io_in_vsie_SSIE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_STIE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_SEIE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LCOFIE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC14IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC15IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC16IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC17IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC18IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC19IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC20IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC21IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC22IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC23IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC24IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC25IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC26IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC27IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC28IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC29IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC30IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC31IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC32IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC33IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC34IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LPRASEIE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC36IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC37IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC38IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC39IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC40IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC41IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC42IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_HPRASEIE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC44IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC45IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC46IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC47IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC48IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC49IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC50IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC51IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC52IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC53IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC54IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC55IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC56IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC57IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC58IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC59IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC60IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC61IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC62IE = ($urandom_range(0, 99) < p_one);
      io_in_vsie_LC63IE = ($urandom_range(0, 99) < p_one);
      io_in_hvictl_VTI = ($urandom_range(0, 99) < p_one);
      io_in_hvictl_IID = $urandom;
      io_in_hvictl_DPR = ($urandom_range(0, 99) < p_one);
      io_in_hvictl_IPRIOM = ($urandom_range(0, 99) < p_one);
      io_in_hvictl_IPRIO = $urandom;
      io_in_hstatus_VGEIN = $urandom;
      io_in_mtopei_IPRIO = $urandom;
      io_in_stopei_IPRIO = $urandom;
      io_in_vstopei_IID = $urandom;
      io_in_vstopei_IPRIO = $urandom;
      io_in_hviprio1_PrioSSI = $urandom;
      io_in_hviprio1_PrioSTI = $urandom;
      io_in_hviprio1_PrioCOI = $urandom;
      io_in_hviprio1_Prio14 = $urandom;
      io_in_hviprio1_Prio15 = $urandom;
      io_in_hviprio2_ALL = {$urandom, $urandom};
      io_in_debugIntr = ($urandom_range(0, 99) < p_one);
      io_in_debugMode = ($urandom_range(0, 99) < p_one);
      io_in_dcsr_STEPIE = ($urandom_range(0, 99) < p_one);
      io_in_dcsr_STEP = ($urandom_range(0, 99) < p_one);
      for (int k = 0; k < 512; k += 32) io_in_miprios[k +: 32] = $urandom;
      for (int k = 0; k < 512; k += 32) io_in_hsiprios[k +: 32] = $urandom;
      io_in_nmi = ($urandom_range(0, 99) < p_one);
      io_in_nmiVec = {$urandom, $urandom};
      io_in_mnstatusNMIE = ($urandom_range(0, 99) < p_one);
      io_in_platform_meip = ($urandom_range(0, 99) < p_one);
      io_in_platform_seip = ($urandom_range(0, 99) < p_one);
      io_in_fromAIA_seip = ($urandom_range(0, 99) < p_one);
      io_in_mvienSEIE = ($urandom_range(0, 99) < p_one);
      io_in_mvipSEIP = ($urandom_range(0, 99) < p_one);
    end
  endtask

  // 逐输出比对（golden 为 X 时不判，见 CONVENTIONS「不读没写过的寄存器」）
  task automatic check_all();
    begin
      `CK(g_io_out_debug, i_io_out_debug, "io_out_debug")
      `CK(g_io_out_nmi, i_io_out_nmi, "io_out_nmi")
      `CK(g_io_out_interruptVec_valid, i_io_out_interruptVec_valid, "io_out_interruptVec_valid")
      `CK(g_io_out_interruptVec_bits, i_io_out_interruptVec_bits, "io_out_interruptVec_bits")
      `CK(g_io_out_mtopi_IID, i_io_out_mtopi_IID, "io_out_mtopi_IID")
      `CK(g_io_out_mtopi_IPRIO, i_io_out_mtopi_IPRIO, "io_out_mtopi_IPRIO")
      `CK(g_io_out_stopi_IID, i_io_out_stopi_IID, "io_out_stopi_IID")
      `CK(g_io_out_stopi_IPRIO, i_io_out_stopi_IPRIO, "io_out_stopi_IPRIO")
      `CK(g_io_out_vstopi_IID, i_io_out_vstopi_IID, "io_out_vstopi_IID")
      `CK(g_io_out_vstopi_IPRIO, i_io_out_vstopi_IPRIO, "io_out_vstopi_IPRIO")
      `CK(g_io_out_virtualInterruptIsHvictlInject, i_io_out_virtualInterruptIsHvictlInject, "io_out_virtualInterruptIsHvictlInject")
      `CK(g_io_out_irToHS, i_io_out_irToHS, "io_out_irToHS")
      `CK(g_io_out_irToVS, i_io_out_irToVS, "io_out_irToVS")
    end
  endtask
// END GENERATED

  // ---- 手写激励：先铺一层通用随机，再改写几个"分界值"字段 -------------------
  task automatic drive(input int unsigned p_one);
    begin
      drive_all(p_one);
      // Candidate2/5 的分界：hvictl.IID == 9
      if ($urandom_range(0, 99) < 35) io_in_hvictl_IID = 12'h9;
      // Candidate1/2 的分界：hstatus.VGEIN == 0
      if ($urandom_range(0, 99) < 40) io_in_hstatus_VGEIN = 6'h0;
      // greaterThan255 / isZero 两支
      if ($urandom_range(0, 99) < 30) io_in_mtopei_IPRIO  = {3'h0, $urandom};
      if ($urandom_range(0, 99) < 30) io_in_stopei_IPRIO  = {3'h0, $urandom};
      if ($urandom_range(0, 99) < 30) io_in_vstopei_IPRIO = {3'h0, $urandom};
      if ($urandom_range(0, 99) < 12) io_in_mtopei_IPRIO  = 11'h0;
      if ($urandom_range(0, 99) < 12) io_in_stopei_IPRIO  = 11'h0;
      if ($urandom_range(0, 99) < 12) io_in_vstopei_IPRIO = 11'h0;
      // iprio 数组：稀疏时让大部分字节为 0（= 回退默认优先级）
      if ($urandom_range(0, 99) < 35) begin
        for (int b = 0; b < 64; b++) begin
          if ($urandom_range(0, 99) < 70) io_in_miprios [b*8 +: 8] = 8'h0;
          if ($urandom_range(0, 99) < 70) io_in_hsiprios[b*8 +: 8] = 8'h0;
        end
      end
      if ($urandom_range(0, 99) < 30) io_in_hviprio2_ALL = 64'h0;
    end
  endtask

  int unsigned dens [4] = '{2, 10, 50, 90};

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    drive(50);
    repeat (6) @(posedge clock);
    reset = 0;
    repeat (12) @(posedge clock);        // 等两级流水 + 5 拍 DelayN 灌满

    for (int unsigned c = 0; c < NCYCLES; c++) begin
      @(posedge clock);
      #1 check_all();
      drive(dens[$urandom_range(0, 3)]);
      // 偶发复位：覆盖异步复位域与复位后重新灌满的过程
      if ($urandom_range(0, 9999) < 5) begin
        reset = 1;
        repeat (2) @(posedge clock);
        #1 reset = 0;
      end
    end

    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else                              $display("TEST FAILED");
    $finish;
  end

endmodule
