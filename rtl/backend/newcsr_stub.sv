// 自动生成：scripts/gen_newcsr.py —— 勿手改

// NewCSR 子模块黑盒 stub（UT/FM 两侧共用，统一黑盒边界）。
// 端口块取自 golden NewCSR.sv 内联 module 定义。

module MStatusModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SIE,
  output        regOut_MIE,
  output        regOut_SPIE,
  output        regOut_MPIE,
  output        regOut_SPP,
  output [1:0]  regOut_VS,
  output [1:0]  regOut_MPP,
  output [1:0]  regOut_FS,
  output        regOut_MPRV,
  output        regOut_SUM,
  output        regOut_MXR,
  output        regOut_TVM,
  output        regOut_TW,
  output        regOut_TSR,
  output        regOut_SDT,
  output        regOut_GVA,
  output        regOut_MPV,
  output        regOut_MDT,
  input         trapToM_mstatus_valid,
  input         trapToM_mstatus_bits_MIE,
  input         trapToM_mstatus_bits_MPIE,
  input  [1:0]  trapToM_mstatus_bits_MPP,
  input         trapToM_mstatus_bits_GVA,
  input         trapToM_mstatus_bits_MPV,
  input         trapToM_mstatus_bits_MDT,
  input         trapToHS_mstatus_valid,
  input         trapToHS_mstatus_bits_SIE,
  input         trapToHS_mstatus_bits_SPIE,
  input         trapToHS_mstatus_bits_SPP,
  input         trapToHS_mstatus_bits_SDT,
  input         retFromD_mstatus_valid,
  input         retFromD_mstatus_bits_MPRV,
  input         retFromD_mstatus_bits_SDT,
  input         retFromD_mstatus_bits_MDT,
  input         retFromM_mstatus_valid,
  input         retFromM_mstatus_bits_MIE,
  input         retFromM_mstatus_bits_MPIE,
  input  [1:0]  retFromM_mstatus_bits_MPP,
  input         retFromM_mstatus_bits_MPRV,
  input         retFromM_mstatus_bits_SDT,
  input         retFromM_mstatus_bits_MPV,
  input         retFromM_mstatus_bits_MDT,
  input         retFromMN_mstatus_valid,
  input         retFromMN_mstatus_bits_MPRV,
  input         retFromMN_mstatus_bits_SDT,
  input         retFromMN_mstatus_bits_MDT,
  input         retFromS_mstatus_valid,
  input         retFromS_mstatus_bits_SIE,
  input         retFromS_mstatus_bits_SPIE,
  input         retFromS_mstatus_bits_SPP,
  input         retFromS_mstatus_bits_MPRV,
  input         retFromS_mstatus_bits_SDT,
  input         retFromS_mstatus_bits_MDT,
  input         robCommit_fsDirty,
  input         robCommit_vsDirty,
  input         writeFCSR,
  input         writeVCSR,
  input         menvcfg_DTE,
  output        sstatus_SIE,
  output        sstatus_SPIE,
  output        sstatus_SPP,
  output [1:0]  sstatus_VS,
  output [1:0]  sstatus_FS,
  output        sstatus_SUM,
  output        sstatus_MXR,
  output        sstatus_SDT,
  output        sstatus_SD,
  output [63:0] sstatusRdata,
  input         wAliasSstatus_wen,
  input  [63:0] wAliasSstatus_wdata
);
endmodule

module MedelegModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_EX_IAM,
  output        regOut_EX_IAF,
  output        regOut_EX_II,
  output        regOut_EX_BP,
  output        regOut_EX_LAM,
  output        regOut_EX_LAF,
  output        regOut_EX_SAM,
  output        regOut_EX_SAF,
  output        regOut_EX_UCALL,
  output        regOut_EX_HSCALL,
  output        regOut_EX_VSCALL,
  output        regOut_EX_IPF,
  output        regOut_EX_LPF,
  output        regOut_EX_SPF,
  output        regOut_EX_SWC,
  output        regOut_EX_HWE,
  output        regOut_EX_IGPF,
  output        regOut_EX_LGPF,
  output        regOut_EX_VI,
  output        regOut_EX_SGPF
);
endmodule

module MidelegModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSI,
  output        regOut_STI,
  output        regOut_SEI,
  output        regOut_LCOFI
);
endmodule

module MieModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSIE,
  output        regOut_VSSIE,
  output        regOut_MSIE,
  output        regOut_STIE,
  output        regOut_VSTIE,
  output        regOut_MTIE,
  output        regOut_SEIE,
  output        regOut_VSEIE,
  output        regOut_MEIE,
  output        regOut_SGEIE,
  output        regOut_LCOFIE,
  input         fromHie_VSSIE_valid,
  input         fromHie_VSSIE_bits,
  input         fromHie_VSTIE_valid,
  input         fromHie_VSTIE_bits,
  input         fromHie_VSEIE_valid,
  input         fromHie_VSEIE_bits,
  input         fromHie_SGEIE_valid,
  input         fromHie_SGEIE_bits,
  input         fromSie_SSIE_valid,
  input         fromSie_SSIE_bits,
  input         fromSie_STIE_valid,
  input         fromSie_STIE_bits,
  input         fromSie_SEIE_valid,
  input         fromSie_SEIE_bits,
  input         fromSie_LCOFIE_valid,
  input         fromSie_LCOFIE_bits,
  input         fromVSie_VSSIE_valid,
  input         fromVSie_VSSIE_bits,
  input         fromVSie_VSTIE_valid,
  input         fromVSie_VSTIE_bits,
  input         fromVSie_VSEIE_valid,
  input         fromVSie_VSEIE_bits,
  input         fromVSie_LCOFIE_valid,
  input         fromVSie_LCOFIE_bits
);
endmodule

module MtvecModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [1:0]  regOut_mode,
  output [61:0] regOut_addr
);
endmodule

module McounterenModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_CY,
  output        regOut_TM,
  output        regOut_IR,
  output [28:0] regOut_HPM
);
endmodule

module MvienModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSIE,
  output        regOut_SEIE,
  output        regOut_LC14IE,
  output        regOut_LC15IE,
  output        regOut_LC16IE,
  output        regOut_LC17IE,
  output        regOut_LC18IE,
  output        regOut_LC19IE,
  output        regOut_LC20IE,
  output        regOut_LC21IE,
  output        regOut_LC22IE,
  output        regOut_LC23IE,
  output        regOut_LC24IE,
  output        regOut_LC25IE,
  output        regOut_LC26IE,
  output        regOut_LC27IE,
  output        regOut_LC28IE,
  output        regOut_LC29IE,
  output        regOut_LC30IE,
  output        regOut_LC31IE,
  output        regOut_LC32IE,
  output        regOut_LC33IE,
  output        regOut_LC34IE,
  output        regOut_LPRASEIE,
  output        regOut_LC36IE,
  output        regOut_LC37IE,
  output        regOut_LC38IE,
  output        regOut_LC39IE,
  output        regOut_LC40IE,
  output        regOut_LC41IE,
  output        regOut_LC42IE,
  output        regOut_HPRASEIE,
  output        regOut_LC44IE,
  output        regOut_LC45IE,
  output        regOut_LC46IE,
  output        regOut_LC47IE,
  output        regOut_LC48IE,
  output        regOut_LC49IE,
  output        regOut_LC50IE,
  output        regOut_LC51IE,
  output        regOut_LC52IE,
  output        regOut_LC53IE,
  output        regOut_LC54IE,
  output        regOut_LC55IE,
  output        regOut_LC56IE,
  output        regOut_LC57IE,
  output        regOut_LC58IE,
  output        regOut_LC59IE,
  output        regOut_LC60IE,
  output        regOut_LC61IE,
  output        regOut_LC62IE,
  output        regOut_LC63IE
);
endmodule

module MvipModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSIP,
  output        regOut_STIP,
  output        regOut_SEIP,
  output        regOut_LCOFIP,
  output        regOut_LC14IP,
  output        regOut_LC15IP,
  output        regOut_LC16IP,
  output        regOut_LC17IP,
  output        regOut_LC18IP,
  output        regOut_LC19IP,
  output        regOut_LC20IP,
  output        regOut_LC21IP,
  output        regOut_LC22IP,
  output        regOut_LC23IP,
  output        regOut_LC24IP,
  output        regOut_LC25IP,
  output        regOut_LC26IP,
  output        regOut_LC27IP,
  output        regOut_LC28IP,
  output        regOut_LC29IP,
  output        regOut_LC30IP,
  output        regOut_LC31IP,
  output        regOut_LC32IP,
  output        regOut_LC33IP,
  output        regOut_LC34IP,
  output        regOut_LPRASEIP,
  output        regOut_LC36IP,
  output        regOut_LC37IP,
  output        regOut_LC38IP,
  output        regOut_LC39IP,
  output        regOut_LC40IP,
  output        regOut_LC41IP,
  output        regOut_LC42IP,
  output        regOut_HPRASEIP,
  output        regOut_LC44IP,
  output        regOut_LC45IP,
  output        regOut_LC46IP,
  output        regOut_LC47IP,
  output        regOut_LC48IP,
  output        regOut_LC49IP,
  output        regOut_LC50IP,
  output        regOut_LC51IP,
  output        regOut_LC52IP,
  output        regOut_LC53IP,
  output        regOut_LC54IP,
  output        regOut_LC55IP,
  output        regOut_LC56IP,
  output        regOut_LC57IP,
  output        regOut_LC58IP,
  output        regOut_LC59IP,
  output        regOut_LC60IP,
  output        regOut_LC61IP,
  output        regOut_LC62IP,
  output        regOut_LC63IP,
  input         mip_SSIP,
  input         mip_STIP,
  input         mvien_SSIE,
  input         menvcfg_STCE,
  output        toMip_SSIP_valid,
  output        toMip_SSIP_bits,
  output        toMip_STIP_valid,
  output        toMip_STIP_bits,
  input         fromMip_SEIP_valid,
  input         fromMip_SEIP_bits,
  input         fromSip_SSIP_valid,
  input         fromSip_SSIP_bits,
  input         fromSip_LCOFIP_valid,
  input         fromSip_LCOFIP_bits,
  input         fromSip_LC14IP_valid,
  input         fromSip_LC14IP_bits,
  input         fromSip_LC15IP_valid,
  input         fromSip_LC15IP_bits,
  input         fromSip_LC16IP_valid,
  input         fromSip_LC16IP_bits,
  input         fromSip_LC17IP_valid,
  input         fromSip_LC17IP_bits,
  input         fromSip_LC18IP_valid,
  input         fromSip_LC18IP_bits,
  input         fromSip_LC19IP_valid,
  input         fromSip_LC19IP_bits,
  input         fromSip_LC20IP_valid,
  input         fromSip_LC20IP_bits,
  input         fromSip_LC21IP_valid,
  input         fromSip_LC21IP_bits,
  input         fromSip_LC22IP_valid,
  input         fromSip_LC22IP_bits,
  input         fromSip_LC23IP_valid,
  input         fromSip_LC23IP_bits,
  input         fromSip_LC24IP_valid,
  input         fromSip_LC24IP_bits,
  input         fromSip_LC25IP_valid,
  input         fromSip_LC25IP_bits,
  input         fromSip_LC26IP_valid,
  input         fromSip_LC26IP_bits,
  input         fromSip_LC27IP_valid,
  input         fromSip_LC27IP_bits,
  input         fromSip_LC28IP_valid,
  input         fromSip_LC28IP_bits,
  input         fromSip_LC29IP_valid,
  input         fromSip_LC29IP_bits,
  input         fromSip_LC30IP_valid,
  input         fromSip_LC30IP_bits,
  input         fromSip_LC31IP_valid,
  input         fromSip_LC31IP_bits,
  input         fromSip_LC32IP_valid,
  input         fromSip_LC32IP_bits,
  input         fromSip_LC33IP_valid,
  input         fromSip_LC33IP_bits,
  input         fromSip_LC34IP_valid,
  input         fromSip_LC34IP_bits,
  input         fromSip_LPRASEIP_valid,
  input         fromSip_LPRASEIP_bits,
  input         fromSip_LC36IP_valid,
  input         fromSip_LC36IP_bits,
  input         fromSip_LC37IP_valid,
  input         fromSip_LC37IP_bits,
  input         fromSip_LC38IP_valid,
  input         fromSip_LC38IP_bits,
  input         fromSip_LC39IP_valid,
  input         fromSip_LC39IP_bits,
  input         fromSip_LC40IP_valid,
  input         fromSip_LC40IP_bits,
  input         fromSip_LC41IP_valid,
  input         fromSip_LC41IP_bits,
  input         fromSip_LC42IP_valid,
  input         fromSip_LC42IP_bits,
  input         fromSip_HPRASEIP_valid,
  input         fromSip_HPRASEIP_bits,
  input         fromSip_LC44IP_valid,
  input         fromSip_LC44IP_bits,
  input         fromSip_LC45IP_valid,
  input         fromSip_LC45IP_bits,
  input         fromSip_LC46IP_valid,
  input         fromSip_LC46IP_bits,
  input         fromSip_LC47IP_valid,
  input         fromSip_LC47IP_bits,
  input         fromSip_LC48IP_valid,
  input         fromSip_LC48IP_bits,
  input         fromSip_LC49IP_valid,
  input         fromSip_LC49IP_bits,
  input         fromSip_LC50IP_valid,
  input         fromSip_LC50IP_bits,
  input         fromSip_LC51IP_valid,
  input         fromSip_LC51IP_bits,
  input         fromSip_LC52IP_valid,
  input         fromSip_LC52IP_bits,
  input         fromSip_LC53IP_valid,
  input         fromSip_LC53IP_bits,
  input         fromSip_LC54IP_valid,
  input         fromSip_LC54IP_bits,
  input         fromSip_LC55IP_valid,
  input         fromSip_LC55IP_bits,
  input         fromSip_LC56IP_valid,
  input         fromSip_LC56IP_bits,
  input         fromSip_LC57IP_valid,
  input         fromSip_LC57IP_bits,
  input         fromSip_LC58IP_valid,
  input         fromSip_LC58IP_bits,
  input         fromSip_LC59IP_valid,
  input         fromSip_LC59IP_bits,
  input         fromSip_LC60IP_valid,
  input         fromSip_LC60IP_bits,
  input         fromSip_LC61IP_valid,
  input         fromSip_LC61IP_bits,
  input         fromSip_LC62IP_valid,
  input         fromSip_LC62IP_bits,
  input         fromSip_LC63IP_valid,
  input         fromSip_LC63IP_bits
);
endmodule

module MenvcfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_STCE,
  output        regOut_PBMTE,
  output        regOut_DTE,
  output [1:0]  regOut_PMM,
  output        regOut_CBZE,
  output        regOut_CBCFE,
  output [1:0]  regOut_CBIE
);
endmodule

module McountinhibitModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_CY,
  output        regOut_IR,
  output [28:0] regOut_HPM3
);
endmodule

module MhpmeventModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_OF,
  output        regOut_MINH,
  output        regOut_SINH,
  output        regOut_UINH,
  output        regOut_VSINH,
  output        regOut_VUINH,
  output [4:0]  regOut_OPTYPE2,
  output [4:0]  regOut_OPTYPE1,
  output [4:0]  regOut_OPTYPE0,
  output [9:0]  regOut_EVENT3,
  output [9:0]  regOut_EVENT2,
  output [9:0]  regOut_EVENT1,
  output [9:0]  regOut_EVENT0,
  input         ofFromPerfCnt
);
endmodule

module MscratchModule(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL
);
endmodule

module MepcModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [62:0] regOut_epc,
  input         trapToM_mepc_valid,
  input  [62:0] trapToM_mepc_bits_epc
);
endmodule

module McauseModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_Interrupt,
  output [62:0] regOut_ExceptionCode,
  input         trapToM_mcause_valid,
  input         trapToM_mcause_bits_Interrupt,
  input  [62:0] trapToM_mcause_bits_ExceptionCode
);
endmodule

module MtvalModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         trapToM_mtval_valid,
  input  [63:0] trapToM_mtval_bits_ALL
);
endmodule

module MipModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSIP,
  output        regOut_VSSIP,
  output        regOut_MSIP,
  output        regOut_STIP,
  output        regOut_VSTIP,
  output        regOut_MTIP,
  output        regOut_SEIP,
  output        regOut_VSEIP,
  output        regOut_MEIP,
  output        regOut_SGEIP,
  output        regOut_LCOFIP,
  output        rdataFields_SSIP,
  output        rdataFields_VSSIP,
  output        rdataFields_MSIP,
  output        rdataFields_STIP,
  output        rdataFields_VSTIP,
  output        rdataFields_MTIP,
  output        rdataFields_SEIP,
  output        rdataFields_VSEIP,
  output        rdataFields_MEIP,
  output        rdataFields_SGEIP,
  output        rdataFields_LCOFIP,
  input         mvip_SEIP,
  input         mvien_SEIE,
  input         hvip_VSSIP,
  input         hvip_VSTIP,
  input         hvip_VSEIP,
  input  [4:0]  hgeip_ip,
  input  [4:0]  hgeie_ie,
  input  [5:0]  hstatusVGEIN,
  input         platformIRP_MEIP,
  input         platformIRP_MTIP,
  input         platformIRP_MSIP,
  input         platformIRP_SEIP,
  input         platformIRP_STIP,
  input         platformIRP_VSTIP,
  input         menvcfg_STCE,
  input         lcofiReq,
  input         aiaToCSR_meip,
  input         aiaToCSR_seip,
  input         fromMvip_SSIP_valid,
  input         fromMvip_SSIP_bits,
  input         fromMvip_STIP_valid,
  input         fromMvip_STIP_bits,
  input         fromSip_SSIP_valid,
  input         fromSip_SSIP_bits,
  input         fromSip_LCOFIP_valid,
  input         fromSip_LCOFIP_bits,
  input         fromVSip_LCOFIP_valid,
  input         fromVSip_LCOFIP_bits,
  output        toMvip_SEIP_valid,
  output        toMvip_SEIP_bits,
  output        toHvip_VSSIP_valid,
  output        toHvip_VSSIP_bits
);
endmodule

module MtinstModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         trapToM_mtinst_valid,
  input  [63:0] trapToM_mtinst_bits_ALL
);
endmodule

module Mtval2Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         trapToM_mtval2_valid,
  input  [63:0] trapToM_mtval2_bits_ALL
);
endmodule

module MseccfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [1:0]  regOut_PMM
);
endmodule

module McycleModule(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY
);
endmodule

module MinstretModule(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_IR,
  input  [6:0]  robCommit_instNum_bits
);
endmodule

module Mhpmcounter3Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter4Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter5Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter6Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter7Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter8Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter9Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter10Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter11Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter12Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter13Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter14Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter15Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter16Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter17Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter18Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter19Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter20Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter21Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter22Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter23Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter24Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter25Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter26Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter27Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter28Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter29Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter30Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module Mhpmcounter31Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
endmodule

module MvendoridModule(

  output [63:0] rdata
);
endmodule

module MhartidModule(

  output [63:0] rdata,
  input  [5:0]  hartid
);
endmodule

module MconfigptrModule(

  output [63:0] rdata
);
endmodule

module Mstateen0Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SE0,
  output        regOut_ENVCFG,
  output        regOut_CSRIND,
  output        regOut_AIA,
  output        regOut_IMSIC,
  output        regOut_CONTEXT,
  output        regOut_C
);
endmodule

module Mstateen1Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SE
);
endmodule

module Mstateen2Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SE
);
endmodule

module Mstateen3Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SE
);
endmodule

module MnepcModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [62:0] regOut_epc,
  input         trapToMN_mnepc_valid,
  input  [62:0] trapToMN_mnepc_bits_epc
);
endmodule

module MncauseModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_Interrupt,
  output [62:0] regOut_ExceptionCode,
  input         trapToMN_mncause_valid,
  input         trapToMN_mncause_bits_Interrupt,
  input  [62:0] trapToMN_mncause_bits_ExceptionCode
);
endmodule

module MnstatusModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_NMIE,
  output        regOut_MNPV,
  output [1:0]  regOut_MNPP,
  input         trapToMN_mnstatus_valid,
  input         trapToMN_mnstatus_bits_NMIE,
  input         trapToMN_mnstatus_bits_MNPV,
  input  [1:0]  trapToMN_mnstatus_bits_MNPP,
  input         retFromMN_mnstatus_valid,
  input         retFromMN_mnstatus_bits_NMIE,
  input         retFromMN_mnstatus_bits_MNPV,
  input  [1:0]  retFromMN_mnstatus_bits_MNPP
);
endmodule

module MnscratchModule(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL
);
endmodule

module McontextModule(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [13:0] rdata,
  output [13:0] regOut_HCONTEXT,
  input         fromHcontext_valid,
  input  [13:0] fromHcontext_bits_HCONTEXT,
  output [13:0] toHcontext_HCONTEXT
);
endmodule

module SieModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSIE,
  output        regOut_STIE,
  output        regOut_SEIE,
  output        regOut_LCOFIE,
  output        regOut_LC14IE,
  output        regOut_LC15IE,
  output        regOut_LC16IE,
  output        regOut_LC17IE,
  output        regOut_LC18IE,
  output        regOut_LC19IE,
  output        regOut_LC20IE,
  output        regOut_LC21IE,
  output        regOut_LC22IE,
  output        regOut_LC23IE,
  output        regOut_LC24IE,
  output        regOut_LC25IE,
  output        regOut_LC26IE,
  output        regOut_LC27IE,
  output        regOut_LC28IE,
  output        regOut_LC29IE,
  output        regOut_LC30IE,
  output        regOut_LC31IE,
  output        regOut_LC32IE,
  output        regOut_LC33IE,
  output        regOut_LC34IE,
  output        regOut_LPRASEIE,
  output        regOut_LC36IE,
  output        regOut_LC37IE,
  output        regOut_LC38IE,
  output        regOut_LC39IE,
  output        regOut_LC40IE,
  output        regOut_LC41IE,
  output        regOut_LC42IE,
  output        regOut_HPRASEIE,
  output        regOut_LC44IE,
  output        regOut_LC45IE,
  output        regOut_LC46IE,
  output        regOut_LC47IE,
  output        regOut_LC48IE,
  output        regOut_LC49IE,
  output        regOut_LC50IE,
  output        regOut_LC51IE,
  output        regOut_LC52IE,
  output        regOut_LC53IE,
  output        regOut_LC54IE,
  output        regOut_LC55IE,
  output        regOut_LC56IE,
  output        regOut_LC57IE,
  output        regOut_LC58IE,
  output        regOut_LC59IE,
  output        regOut_LC60IE,
  output        regOut_LC61IE,
  output        regOut_LC62IE,
  output        regOut_LC63IE,
  input         mideleg_SSI,
  input         mideleg_STI,
  input         mideleg_SEI,
  input         mideleg_LCOFI,
  input         mie_SSIE,
  input         mie_VSSIE,
  input         mie_MSIE,
  input         mie_STIE,
  input         mie_VSTIE,
  input         mie_MTIE,
  input         mie_SEIE,
  input         mie_VSEIE,
  input         mie_MEIE,
  input         mie_SGEIE,
  input         mie_LCOFIE,
  input         mvien_SSIE,
  input         mvien_SEIE,
  input         mvien_LC14IE,
  input         mvien_LC15IE,
  input         mvien_LC16IE,
  input         mvien_LC17IE,
  input         mvien_LC18IE,
  input         mvien_LC19IE,
  input         mvien_LC20IE,
  input         mvien_LC21IE,
  input         mvien_LC22IE,
  input         mvien_LC23IE,
  input         mvien_LC24IE,
  input         mvien_LC25IE,
  input         mvien_LC26IE,
  input         mvien_LC27IE,
  input         mvien_LC28IE,
  input         mvien_LC29IE,
  input         mvien_LC30IE,
  input         mvien_LC31IE,
  input         mvien_LC32IE,
  input         mvien_LC33IE,
  input         mvien_LC34IE,
  input         mvien_LPRASEIE,
  input         mvien_LC36IE,
  input         mvien_LC37IE,
  input         mvien_LC38IE,
  input         mvien_LC39IE,
  input         mvien_LC40IE,
  input         mvien_LC41IE,
  input         mvien_LC42IE,
  input         mvien_HPRASEIE,
  input         mvien_LC44IE,
  input         mvien_LC45IE,
  input         mvien_LC46IE,
  input         mvien_LC47IE,
  input         mvien_LC48IE,
  input         mvien_LC49IE,
  input         mvien_LC50IE,
  input         mvien_LC51IE,
  input         mvien_LC52IE,
  input         mvien_LC53IE,
  input         mvien_LC54IE,
  input         mvien_LC55IE,
  input         mvien_LC56IE,
  input         mvien_LC57IE,
  input         mvien_LC58IE,
  input         mvien_LC59IE,
  input         mvien_LC60IE,
  input         mvien_LC61IE,
  input         mvien_LC62IE,
  input         mvien_LC63IE,
  output        toMie_SSIE_valid,
  output        toMie_SSIE_bits,
  output        toMie_STIE_valid,
  output        toMie_STIE_bits,
  output        toMie_SEIE_valid,
  output        toMie_SEIE_bits,
  output        toMie_LCOFIE_valid,
  output        toMie_LCOFIE_bits,
  input         fromVSie_VSSIE_valid,
  input         fromVSie_VSSIE_bits,
  input         fromVSie_VSTIE_valid,
  input         fromVSie_VSTIE_bits,
  input         fromVSie_VSEIE_valid,
  input         fromVSie_VSEIE_bits,
  input         fromVSie_LCOFIE_valid,
  input         fromVSie_LCOFIE_bits,
  input         fromVSie_LC14IE_valid,
  input         fromVSie_LC14IE_bits,
  input         fromVSie_LC15IE_valid,
  input         fromVSie_LC15IE_bits,
  input         fromVSie_LC16IE_valid,
  input         fromVSie_LC16IE_bits,
  input         fromVSie_LC17IE_valid,
  input         fromVSie_LC17IE_bits,
  input         fromVSie_LC18IE_valid,
  input         fromVSie_LC18IE_bits,
  input         fromVSie_LC19IE_valid,
  input         fromVSie_LC19IE_bits,
  input         fromVSie_LC20IE_valid,
  input         fromVSie_LC20IE_bits,
  input         fromVSie_LC21IE_valid,
  input         fromVSie_LC21IE_bits,
  input         fromVSie_LC22IE_valid,
  input         fromVSie_LC22IE_bits,
  input         fromVSie_LC23IE_valid,
  input         fromVSie_LC23IE_bits,
  input         fromVSie_LC24IE_valid,
  input         fromVSie_LC24IE_bits,
  input         fromVSie_LC25IE_valid,
  input         fromVSie_LC25IE_bits,
  input         fromVSie_LC26IE_valid,
  input         fromVSie_LC26IE_bits,
  input         fromVSie_LC27IE_valid,
  input         fromVSie_LC27IE_bits,
  input         fromVSie_LC28IE_valid,
  input         fromVSie_LC28IE_bits,
  input         fromVSie_LC29IE_valid,
  input         fromVSie_LC29IE_bits,
  input         fromVSie_LC30IE_valid,
  input         fromVSie_LC30IE_bits,
  input         fromVSie_LC31IE_valid,
  input         fromVSie_LC31IE_bits,
  input         fromVSie_LC32IE_valid,
  input         fromVSie_LC32IE_bits,
  input         fromVSie_LC33IE_valid,
  input         fromVSie_LC33IE_bits,
  input         fromVSie_LC34IE_valid,
  input         fromVSie_LC34IE_bits,
  input         fromVSie_LPRASEIE_valid,
  input         fromVSie_LPRASEIE_bits,
  input         fromVSie_LC36IE_valid,
  input         fromVSie_LC36IE_bits,
  input         fromVSie_LC37IE_valid,
  input         fromVSie_LC37IE_bits,
  input         fromVSie_LC38IE_valid,
  input         fromVSie_LC38IE_bits,
  input         fromVSie_LC39IE_valid,
  input         fromVSie_LC39IE_bits,
  input         fromVSie_LC40IE_valid,
  input         fromVSie_LC40IE_bits,
  input         fromVSie_LC41IE_valid,
  input         fromVSie_LC41IE_bits,
  input         fromVSie_LC42IE_valid,
  input         fromVSie_LC42IE_bits,
  input         fromVSie_HPRASEIE_valid,
  input         fromVSie_HPRASEIE_bits,
  input         fromVSie_LC44IE_valid,
  input         fromVSie_LC44IE_bits,
  input         fromVSie_LC45IE_valid,
  input         fromVSie_LC45IE_bits,
  input         fromVSie_LC46IE_valid,
  input         fromVSie_LC46IE_bits,
  input         fromVSie_LC47IE_valid,
  input         fromVSie_LC47IE_bits,
  input         fromVSie_LC48IE_valid,
  input         fromVSie_LC48IE_bits,
  input         fromVSie_LC49IE_valid,
  input         fromVSie_LC49IE_bits,
  input         fromVSie_LC50IE_valid,
  input         fromVSie_LC50IE_bits,
  input         fromVSie_LC51IE_valid,
  input         fromVSie_LC51IE_bits,
  input         fromVSie_LC52IE_valid,
  input         fromVSie_LC52IE_bits,
  input         fromVSie_LC53IE_valid,
  input         fromVSie_LC53IE_bits,
  input         fromVSie_LC54IE_valid,
  input         fromVSie_LC54IE_bits,
  input         fromVSie_LC55IE_valid,
  input         fromVSie_LC55IE_bits,
  input         fromVSie_LC56IE_valid,
  input         fromVSie_LC56IE_bits,
  input         fromVSie_LC57IE_valid,
  input         fromVSie_LC57IE_bits,
  input         fromVSie_LC58IE_valid,
  input         fromVSie_LC58IE_bits,
  input         fromVSie_LC59IE_valid,
  input         fromVSie_LC59IE_bits,
  input         fromVSie_LC60IE_valid,
  input         fromVSie_LC60IE_bits,
  input         fromVSie_LC61IE_valid,
  input         fromVSie_LC61IE_bits,
  input         fromVSie_LC62IE_valid,
  input         fromVSie_LC62IE_bits,
  input         fromVSie_LC63IE_valid,
  input         fromVSie_LC63IE_bits
);
endmodule

module StvecModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [1:0]  regOut_mode,
  output [61:0] regOut_addr
);
endmodule

module ScounterenModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_CY,
  output        regOut_TM,
  output        regOut_IR,
  output [28:0] regOut_HPM
);
endmodule

module SenvcfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [1:0]  regOut_PMM,
  output        regOut_CBZE,
  output        regOut_CBCFE,
  output [1:0]  regOut_CBIE
);
endmodule

module SscratchModule(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL
);
endmodule

module SepcModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [62:0] regOut_epc,
  input         trapToHS_sepc_valid,
  input  [62:0] trapToHS_sepc_bits_epc
);
endmodule

module ScauseModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_Interrupt,
  output [62:0] regOut_ExceptionCode,
  input         trapToHS_scause_valid,
  input         trapToHS_scause_bits_Interrupt,
  input  [62:0] trapToHS_scause_bits_ExceptionCode
);
endmodule

module StvalModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         trapToHS_stval_valid,
  input  [63:0] trapToHS_stval_bits_ALL
);
endmodule

module SipModule(

  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSIP,
  output        regOut_STIP,
  output        regOut_SEIP,
  output        regOut_LCOFIP,
  output        regOut_LC14IP,
  output        regOut_LC15IP,
  output        regOut_LC16IP,
  output        regOut_LC17IP,
  output        regOut_LC18IP,
  output        regOut_LC19IP,
  output        regOut_LC20IP,
  output        regOut_LC21IP,
  output        regOut_LC22IP,
  output        regOut_LC23IP,
  output        regOut_LC24IP,
  output        regOut_LC25IP,
  output        regOut_LC26IP,
  output        regOut_LC27IP,
  output        regOut_LC28IP,
  output        regOut_LC29IP,
  output        regOut_LC30IP,
  output        regOut_LC31IP,
  output        regOut_LC32IP,
  output        regOut_LC33IP,
  output        regOut_LC34IP,
  output        regOut_LPRASEIP,
  output        regOut_LC36IP,
  output        regOut_LC37IP,
  output        regOut_LC38IP,
  output        regOut_LC39IP,
  output        regOut_LC40IP,
  output        regOut_LC41IP,
  output        regOut_LC42IP,
  output        regOut_HPRASEIP,
  output        regOut_LC44IP,
  output        regOut_LC45IP,
  output        regOut_LC46IP,
  output        regOut_LC47IP,
  output        regOut_LC48IP,
  output        regOut_LC49IP,
  output        regOut_LC50IP,
  output        regOut_LC51IP,
  output        regOut_LC52IP,
  output        regOut_LC53IP,
  output        regOut_LC54IP,
  output        regOut_LC55IP,
  output        regOut_LC56IP,
  output        regOut_LC57IP,
  output        regOut_LC58IP,
  output        regOut_LC59IP,
  output        regOut_LC60IP,
  output        regOut_LC61IP,
  output        regOut_LC62IP,
  output        regOut_LC63IP,
  input         mideleg_SSI,
  input         mideleg_STI,
  input         mideleg_SEI,
  input         mideleg_LCOFI,
  input         mip_SSIP,
  input         mip_VSSIP,
  input         mip_MSIP,
  input         mip_STIP,
  input         mip_VSTIP,
  input         mip_MTIP,
  input         mip_SEIP,
  input         mip_VSEIP,
  input         mip_MEIP,
  input         mip_SGEIP,
  input         mip_LCOFIP,
  input         mip_LC14IP,
  input         mip_LC15IP,
  input         mip_LC16IP,
  input         mip_LC17IP,
  input         mip_LC18IP,
  input         mip_LC19IP,
  input         mip_LC20IP,
  input         mip_LC21IP,
  input         mip_LC22IP,
  input         mip_LC23IP,
  input         mip_LC24IP,
  input         mip_LC25IP,
  input         mip_LC26IP,
  input         mip_LC27IP,
  input         mip_LC28IP,
  input         mip_LC29IP,
  input         mip_LC30IP,
  input         mip_LC31IP,
  input         mip_LC32IP,
  input         mip_LC33IP,
  input         mip_LC34IP,
  input         mip_LPRASEIP,
  input         mip_LC36IP,
  input         mip_LC37IP,
  input         mip_LC38IP,
  input         mip_LC39IP,
  input         mip_LC40IP,
  input         mip_LC41IP,
  input         mip_LC42IP,
  input         mip_HPRASEIP,
  input         mip_LC44IP,
  input         mip_LC45IP,
  input         mip_LC46IP,
  input         mip_LC47IP,
  input         mip_LC48IP,
  input         mip_LC49IP,
  input         mip_LC50IP,
  input         mip_LC51IP,
  input         mip_LC52IP,
  input         mip_LC53IP,
  input         mip_LC54IP,
  input         mip_LC55IP,
  input         mip_LC56IP,
  input         mip_LC57IP,
  input         mip_LC58IP,
  input         mip_LC59IP,
  input         mip_LC60IP,
  input         mip_LC61IP,
  input         mip_LC62IP,
  input         mip_LC63IP,
  input         mvip_SSIP,
  input         mvip_STIP,
  input         mvip_SEIP,
  input         mvip_LCOFIP,
  input         mvip_LC14IP,
  input         mvip_LC15IP,
  input         mvip_LC16IP,
  input         mvip_LC17IP,
  input         mvip_LC18IP,
  input         mvip_LC19IP,
  input         mvip_LC20IP,
  input         mvip_LC21IP,
  input         mvip_LC22IP,
  input         mvip_LC23IP,
  input         mvip_LC24IP,
  input         mvip_LC25IP,
  input         mvip_LC26IP,
  input         mvip_LC27IP,
  input         mvip_LC28IP,
  input         mvip_LC29IP,
  input         mvip_LC30IP,
  input         mvip_LC31IP,
  input         mvip_LC32IP,
  input         mvip_LC33IP,
  input         mvip_LC34IP,
  input         mvip_LPRASEIP,
  input         mvip_LC36IP,
  input         mvip_LC37IP,
  input         mvip_LC38IP,
  input         mvip_LC39IP,
  input         mvip_LC40IP,
  input         mvip_LC41IP,
  input         mvip_LC42IP,
  input         mvip_HPRASEIP,
  input         mvip_LC44IP,
  input         mvip_LC45IP,
  input         mvip_LC46IP,
  input         mvip_LC47IP,
  input         mvip_LC48IP,
  input         mvip_LC49IP,
  input         mvip_LC50IP,
  input         mvip_LC51IP,
  input         mvip_LC52IP,
  input         mvip_LC53IP,
  input         mvip_LC54IP,
  input         mvip_LC55IP,
  input         mvip_LC56IP,
  input         mvip_LC57IP,
  input         mvip_LC58IP,
  input         mvip_LC59IP,
  input         mvip_LC60IP,
  input         mvip_LC61IP,
  input         mvip_LC62IP,
  input         mvip_LC63IP,
  input         mvien_SSIE,
  input         mvien_SEIE,
  input         mvien_LC14IE,
  input         mvien_LC15IE,
  input         mvien_LC16IE,
  input         mvien_LC17IE,
  input         mvien_LC18IE,
  input         mvien_LC19IE,
  input         mvien_LC20IE,
  input         mvien_LC21IE,
  input         mvien_LC22IE,
  input         mvien_LC23IE,
  input         mvien_LC24IE,
  input         mvien_LC25IE,
  input         mvien_LC26IE,
  input         mvien_LC27IE,
  input         mvien_LC28IE,
  input         mvien_LC29IE,
  input         mvien_LC30IE,
  input         mvien_LC31IE,
  input         mvien_LC32IE,
  input         mvien_LC33IE,
  input         mvien_LC34IE,
  input         mvien_LPRASEIE,
  input         mvien_LC36IE,
  input         mvien_LC37IE,
  input         mvien_LC38IE,
  input         mvien_LC39IE,
  input         mvien_LC40IE,
  input         mvien_LC41IE,
  input         mvien_LC42IE,
  input         mvien_HPRASEIE,
  input         mvien_LC44IE,
  input         mvien_LC45IE,
  input         mvien_LC46IE,
  input         mvien_LC47IE,
  input         mvien_LC48IE,
  input         mvien_LC49IE,
  input         mvien_LC50IE,
  input         mvien_LC51IE,
  input         mvien_LC52IE,
  input         mvien_LC53IE,
  input         mvien_LC54IE,
  input         mvien_LC55IE,
  input         mvien_LC56IE,
  input         mvien_LC57IE,
  input         mvien_LC58IE,
  input         mvien_LC59IE,
  input         mvien_LC60IE,
  input         mvien_LC61IE,
  input         mvien_LC62IE,
  input         mvien_LC63IE,
  output        toMip_SSIP_valid,
  output        toMip_SSIP_bits,
  output        toMip_LCOFIP_valid,
  output        toMip_LCOFIP_bits,
  output        toMvip_SSIP_valid,
  output        toMvip_SSIP_bits,
  output        toMvip_LCOFIP_valid,
  output        toMvip_LCOFIP_bits,
  output        toMvip_LC14IP_valid,
  output        toMvip_LC14IP_bits,
  output        toMvip_LC15IP_valid,
  output        toMvip_LC15IP_bits,
  output        toMvip_LC16IP_valid,
  output        toMvip_LC16IP_bits,
  output        toMvip_LC17IP_valid,
  output        toMvip_LC17IP_bits,
  output        toMvip_LC18IP_valid,
  output        toMvip_LC18IP_bits,
  output        toMvip_LC19IP_valid,
  output        toMvip_LC19IP_bits,
  output        toMvip_LC20IP_valid,
  output        toMvip_LC20IP_bits,
  output        toMvip_LC21IP_valid,
  output        toMvip_LC21IP_bits,
  output        toMvip_LC22IP_valid,
  output        toMvip_LC22IP_bits,
  output        toMvip_LC23IP_valid,
  output        toMvip_LC23IP_bits,
  output        toMvip_LC24IP_valid,
  output        toMvip_LC24IP_bits,
  output        toMvip_LC25IP_valid,
  output        toMvip_LC25IP_bits,
  output        toMvip_LC26IP_valid,
  output        toMvip_LC26IP_bits,
  output        toMvip_LC27IP_valid,
  output        toMvip_LC27IP_bits,
  output        toMvip_LC28IP_valid,
  output        toMvip_LC28IP_bits,
  output        toMvip_LC29IP_valid,
  output        toMvip_LC29IP_bits,
  output        toMvip_LC30IP_valid,
  output        toMvip_LC30IP_bits,
  output        toMvip_LC31IP_valid,
  output        toMvip_LC31IP_bits,
  output        toMvip_LC32IP_valid,
  output        toMvip_LC32IP_bits,
  output        toMvip_LC33IP_valid,
  output        toMvip_LC33IP_bits,
  output        toMvip_LC34IP_valid,
  output        toMvip_LC34IP_bits,
  output        toMvip_LPRASEIP_valid,
  output        toMvip_LPRASEIP_bits,
  output        toMvip_LC36IP_valid,
  output        toMvip_LC36IP_bits,
  output        toMvip_LC37IP_valid,
  output        toMvip_LC37IP_bits,
  output        toMvip_LC38IP_valid,
  output        toMvip_LC38IP_bits,
  output        toMvip_LC39IP_valid,
  output        toMvip_LC39IP_bits,
  output        toMvip_LC40IP_valid,
  output        toMvip_LC40IP_bits,
  output        toMvip_LC41IP_valid,
  output        toMvip_LC41IP_bits,
  output        toMvip_LC42IP_valid,
  output        toMvip_LC42IP_bits,
  output        toMvip_HPRASEIP_valid,
  output        toMvip_HPRASEIP_bits,
  output        toMvip_LC44IP_valid,
  output        toMvip_LC44IP_bits,
  output        toMvip_LC45IP_valid,
  output        toMvip_LC45IP_bits,
  output        toMvip_LC46IP_valid,
  output        toMvip_LC46IP_bits,
  output        toMvip_LC47IP_valid,
  output        toMvip_LC47IP_bits,
  output        toMvip_LC48IP_valid,
  output        toMvip_LC48IP_bits,
  output        toMvip_LC49IP_valid,
  output        toMvip_LC49IP_bits,
  output        toMvip_LC50IP_valid,
  output        toMvip_LC50IP_bits,
  output        toMvip_LC51IP_valid,
  output        toMvip_LC51IP_bits,
  output        toMvip_LC52IP_valid,
  output        toMvip_LC52IP_bits,
  output        toMvip_LC53IP_valid,
  output        toMvip_LC53IP_bits,
  output        toMvip_LC54IP_valid,
  output        toMvip_LC54IP_bits,
  output        toMvip_LC55IP_valid,
  output        toMvip_LC55IP_bits,
  output        toMvip_LC56IP_valid,
  output        toMvip_LC56IP_bits,
  output        toMvip_LC57IP_valid,
  output        toMvip_LC57IP_bits,
  output        toMvip_LC58IP_valid,
  output        toMvip_LC58IP_bits,
  output        toMvip_LC59IP_valid,
  output        toMvip_LC59IP_bits,
  output        toMvip_LC60IP_valid,
  output        toMvip_LC60IP_bits,
  output        toMvip_LC61IP_valid,
  output        toMvip_LC61IP_bits,
  output        toMvip_LC62IP_valid,
  output        toMvip_LC62IP_bits,
  output        toMvip_LC63IP_valid,
  output        toMvip_LC63IP_bits
);
endmodule

module StimecmpModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_stimecmp
);
endmodule

module SatpModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [3:0]  regOut_MODE,
  output [15:0] regOut_ASID,
  output [43:0] regOut_PPN
);
endmodule

module ScountovfModule(

  output [31:0] rdata,
  input  [28:0] ofVec,
  input  [1:0]  privState_PRVM,
  input         privState_V,
  input  [28:0] mcounteren_HPM,
  input  [28:0] hcounteren_HPM
);
endmodule

module Sstateen0Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [31:0] rdata,
  output        regOut_JVT,
  output        regOut_FCSR,
  output        regOut_C,
  input         fromMstateen0_SE0,
  input         fromMstateen0_ENVCFG,
  input         fromMstateen0_CSRIND,
  input         fromMstateen0_AIA,
  input         fromMstateen0_IMSIC,
  input         fromMstateen0_CONTEXT,
  input         fromMstateen0_C,
  input         fromHstateen0_JVT,
  input         fromHstateen0_FCSR,
  input         fromHstateen0_C,
  input         fromHstateen0_SE0,
  input         fromHstateen0_ENVCFG,
  input         fromHstateen0_CSRIND,
  input         fromHstateen0_AIA,
  input         fromHstateen0_IMSIC,
  input         fromHstateen0_CONTEXT,
  input         privState_V
);
endmodule

module Sstateen1Module(

  output [31:0] rdata,
  output [31:0] regOut_ALL
);
endmodule

module Sstateen2Module(

  output [31:0] rdata,
  output [31:0] regOut_ALL
);
endmodule

module Sstateen3Module(

  output [31:0] rdata,
  output [31:0] regOut_ALL
);
endmodule

module ScontextModule(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [31:0] rdata,
  output [31:0] regOut_ALL
);
endmodule

module HstatusModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_GVA,
  output        regOut_SPV,
  output        regOut_SPVP,
  output        regOut_HU,
  output [5:0]  regOut_VGEIN,
  output        regOut_VTVM,
  output        regOut_VTW,
  output        regOut_VTSR,
  output [1:0]  regOut_HUPMM,
  input         retFromS_hstatus_valid,
  input         retFromS_hstatus_bits_SPV,
  input         trapToHS_hstatus_valid,
  input         trapToHS_hstatus_bits_GVA,
  input         trapToHS_hstatus_bits_SPV,
  input         trapToHS_hstatus_bits_SPVP
);
endmodule

module HedelegModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_EX_IAM,
  output        regOut_EX_IAF,
  output        regOut_EX_II,
  output        regOut_EX_BP,
  output        regOut_EX_LAM,
  output        regOut_EX_LAF,
  output        regOut_EX_SAM,
  output        regOut_EX_SAF,
  output        regOut_EX_UCALL,
  output        regOut_EX_IPF,
  output        regOut_EX_LPF,
  output        regOut_EX_SPF,
  output        regOut_EX_SWC,
  output        regOut_EX_HWE
);
endmodule

module HidelegModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSI,
  output        regOut_VSSI,
  output        regOut_MSI,
  output        regOut_STI,
  output        regOut_VSTI,
  output        regOut_MTI,
  output        regOut_SEI,
  output        regOut_VSEI,
  output        regOut_MEI,
  output        regOut_SGEI,
  output        regOut_LCOFI,
  input         mideleg_SSI,
  input         mideleg_STI,
  input         mideleg_SEI,
  input         mideleg_LCOFI
);
endmodule

module HieModule(

  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_VSSIE,
  output        regOut_VSTIE,
  output        regOut_VSEIE,
  output        regOut_SGEIE,
  input         mie_VSSIE,
  input         mie_VSTIE,
  input         mie_VSEIE,
  input         mie_SGEIE,
  output        toMie_VSSIE_valid,
  output        toMie_VSSIE_bits,
  output        toMie_VSTIE_valid,
  output        toMie_VSTIE_bits,
  output        toMie_VSEIE_valid,
  output        toMie_VSEIE_bits,
  output        toMie_SGEIE_valid,
  output        toMie_SGEIE_bits
);
endmodule

module HtimedeltaModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL
);
endmodule

module HcounterenModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_CY,
  output        regOut_TM,
  output        regOut_IR,
  output [28:0] regOut_HPM
);
endmodule

module HgeieModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [4:0]  regOut_ie
);
endmodule

module HvienModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_LC14IE,
  output        regOut_LC15IE,
  output        regOut_LC16IE,
  output        regOut_LC17IE,
  output        regOut_LC18IE,
  output        regOut_LC19IE,
  output        regOut_LC20IE,
  output        regOut_LC21IE,
  output        regOut_LC22IE,
  output        regOut_LC23IE,
  output        regOut_LC24IE,
  output        regOut_LC25IE,
  output        regOut_LC26IE,
  output        regOut_LC27IE,
  output        regOut_LC28IE,
  output        regOut_LC29IE,
  output        regOut_LC30IE,
  output        regOut_LC31IE,
  output        regOut_LC32IE,
  output        regOut_LC33IE,
  output        regOut_LC34IE,
  output        regOut_LPRASEIE,
  output        regOut_LC36IE,
  output        regOut_LC37IE,
  output        regOut_LC38IE,
  output        regOut_LC39IE,
  output        regOut_LC40IE,
  output        regOut_LC41IE,
  output        regOut_LC42IE,
  output        regOut_HPRASEIE,
  output        regOut_LC44IE,
  output        regOut_LC45IE,
  output        regOut_LC46IE,
  output        regOut_LC47IE,
  output        regOut_LC48IE,
  output        regOut_LC49IE,
  output        regOut_LC50IE,
  output        regOut_LC51IE,
  output        regOut_LC52IE,
  output        regOut_LC53IE,
  output        regOut_LC54IE,
  output        regOut_LC55IE,
  output        regOut_LC56IE,
  output        regOut_LC57IE,
  output        regOut_LC58IE,
  output        regOut_LC59IE,
  output        regOut_LC60IE,
  output        regOut_LC61IE,
  output        regOut_LC62IE,
  output        regOut_LC63IE
);
endmodule

module HvictlModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_VTI,
  output [11:0] regOut_IID,
  output        regOut_DPR,
  output        regOut_IPRIOM,
  output [7:0]  regOut_IPRIO
);
endmodule

module HenvcfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_STCE,
  output        regOut_PBMTE,
  output        regOut_DTE,
  output [1:0]  regOut_PMM,
  output        regOut_CBZE,
  output        regOut_CBCFE,
  output [1:0]  regOut_CBIE,
  input         menvcfg_STCE,
  input         menvcfg_PBMTE,
  input         menvcfg_DTE
);
endmodule

module HtvalModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         trapToHS_htval_valid,
  input  [63:0] trapToHS_htval_bits_ALL
);
endmodule

module HipModule(

  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_VSSIP,
  output        regOut_VSTIP,
  output        regOut_VSEIP,
  output        regOut_SGEIP,
  input         mip_VSTIP,
  input         mip_VSEIP,
  input         mip_SGEIP,
  input         hvip_VSSIP,
  output        toHvip_VSSIP_valid,
  output        toHvip_VSSIP_bits
);
endmodule

module HvipModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_VSSIP,
  output        regOut_VSTIP,
  output        regOut_VSEIP,
  output        regOut_LCOFIP,
  output        regOut_LC14IP,
  output        regOut_LC15IP,
  output        regOut_LC16IP,
  output        regOut_LC17IP,
  output        regOut_LC18IP,
  output        regOut_LC19IP,
  output        regOut_LC20IP,
  output        regOut_LC21IP,
  output        regOut_LC22IP,
  output        regOut_LC23IP,
  output        regOut_LC24IP,
  output        regOut_LC25IP,
  output        regOut_LC26IP,
  output        regOut_LC27IP,
  output        regOut_LC28IP,
  output        regOut_LC29IP,
  output        regOut_LC30IP,
  output        regOut_LC31IP,
  output        regOut_LC32IP,
  output        regOut_LC33IP,
  output        regOut_LC34IP,
  output        regOut_LPRASEIP,
  output        regOut_LC36IP,
  output        regOut_LC37IP,
  output        regOut_LC38IP,
  output        regOut_LC39IP,
  output        regOut_LC40IP,
  output        regOut_LC41IP,
  output        regOut_LC42IP,
  output        regOut_HPRASEIP,
  output        regOut_LC44IP,
  output        regOut_LC45IP,
  output        regOut_LC46IP,
  output        regOut_LC47IP,
  output        regOut_LC48IP,
  output        regOut_LC49IP,
  output        regOut_LC50IP,
  output        regOut_LC51IP,
  output        regOut_LC52IP,
  output        regOut_LC53IP,
  output        regOut_LC54IP,
  output        regOut_LC55IP,
  output        regOut_LC56IP,
  output        regOut_LC57IP,
  output        regOut_LC58IP,
  output        regOut_LC59IP,
  output        regOut_LC60IP,
  output        regOut_LC61IP,
  output        regOut_LC62IP,
  output        regOut_LC63IP,
  input         fromMip_VSSIP_valid,
  input         fromMip_VSSIP_bits,
  input         fromHip_VSSIP_valid,
  input         fromHip_VSSIP_bits,
  input         fromVSip_VSSIP_valid,
  input         fromVSip_VSSIP_bits,
  input         fromVSip_LCOFIP_bits,
  input         fromVSip_LC14IP_valid,
  input         fromVSip_LC14IP_bits,
  input         fromVSip_LC15IP_valid,
  input         fromVSip_LC15IP_bits,
  input         fromVSip_LC16IP_valid,
  input         fromVSip_LC16IP_bits,
  input         fromVSip_LC17IP_valid,
  input         fromVSip_LC17IP_bits,
  input         fromVSip_LC18IP_valid,
  input         fromVSip_LC18IP_bits,
  input         fromVSip_LC19IP_valid,
  input         fromVSip_LC19IP_bits,
  input         fromVSip_LC20IP_valid,
  input         fromVSip_LC20IP_bits,
  input         fromVSip_LC21IP_valid,
  input         fromVSip_LC21IP_bits,
  input         fromVSip_LC22IP_valid,
  input         fromVSip_LC22IP_bits,
  input         fromVSip_LC23IP_valid,
  input         fromVSip_LC23IP_bits,
  input         fromVSip_LC24IP_valid,
  input         fromVSip_LC24IP_bits,
  input         fromVSip_LC25IP_valid,
  input         fromVSip_LC25IP_bits,
  input         fromVSip_LC26IP_valid,
  input         fromVSip_LC26IP_bits,
  input         fromVSip_LC27IP_valid,
  input         fromVSip_LC27IP_bits,
  input         fromVSip_LC28IP_valid,
  input         fromVSip_LC28IP_bits,
  input         fromVSip_LC29IP_valid,
  input         fromVSip_LC29IP_bits,
  input         fromVSip_LC30IP_valid,
  input         fromVSip_LC30IP_bits,
  input         fromVSip_LC31IP_valid,
  input         fromVSip_LC31IP_bits,
  input         fromVSip_LC32IP_valid,
  input         fromVSip_LC32IP_bits,
  input         fromVSip_LC33IP_valid,
  input         fromVSip_LC33IP_bits,
  input         fromVSip_LC34IP_valid,
  input         fromVSip_LC34IP_bits,
  input         fromVSip_LPRASEIP_valid,
  input         fromVSip_LPRASEIP_bits,
  input         fromVSip_LC36IP_valid,
  input         fromVSip_LC36IP_bits,
  input         fromVSip_LC37IP_valid,
  input         fromVSip_LC37IP_bits,
  input         fromVSip_LC38IP_valid,
  input         fromVSip_LC38IP_bits,
  input         fromVSip_LC39IP_valid,
  input         fromVSip_LC39IP_bits,
  input         fromVSip_LC40IP_valid,
  input         fromVSip_LC40IP_bits,
  input         fromVSip_LC41IP_valid,
  input         fromVSip_LC41IP_bits,
  input         fromVSip_LC42IP_valid,
  input         fromVSip_LC42IP_bits,
  input         fromVSip_HPRASEIP_valid,
  input         fromVSip_HPRASEIP_bits,
  input         fromVSip_LC44IP_valid,
  input         fromVSip_LC44IP_bits,
  input         fromVSip_LC45IP_valid,
  input         fromVSip_LC45IP_bits,
  input         fromVSip_LC46IP_valid,
  input         fromVSip_LC46IP_bits,
  input         fromVSip_LC47IP_valid,
  input         fromVSip_LC47IP_bits,
  input         fromVSip_LC48IP_valid,
  input         fromVSip_LC48IP_bits,
  input         fromVSip_LC49IP_valid,
  input         fromVSip_LC49IP_bits,
  input         fromVSip_LC50IP_valid,
  input         fromVSip_LC50IP_bits,
  input         fromVSip_LC51IP_valid,
  input         fromVSip_LC51IP_bits,
  input         fromVSip_LC52IP_valid,
  input         fromVSip_LC52IP_bits,
  input         fromVSip_LC53IP_valid,
  input         fromVSip_LC53IP_bits,
  input         fromVSip_LC54IP_valid,
  input         fromVSip_LC54IP_bits,
  input         fromVSip_LC55IP_valid,
  input         fromVSip_LC55IP_bits,
  input         fromVSip_LC56IP_valid,
  input         fromVSip_LC56IP_bits,
  input         fromVSip_LC57IP_valid,
  input         fromVSip_LC57IP_bits,
  input         fromVSip_LC58IP_valid,
  input         fromVSip_LC58IP_bits,
  input         fromVSip_LC59IP_valid,
  input         fromVSip_LC59IP_bits,
  input         fromVSip_LC60IP_valid,
  input         fromVSip_LC60IP_bits,
  input         fromVSip_LC61IP_valid,
  input         fromVSip_LC61IP_bits,
  input         fromVSip_LC62IP_valid,
  input         fromVSip_LC62IP_bits,
  input         fromVSip_LC63IP_valid,
  input         fromVSip_LC63IP_bits
);
endmodule

module Hviprio1Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [7:0]  regOut_PrioSSI,
  output [7:0]  regOut_PrioSTI,
  output [7:0]  regOut_PrioCOI,
  output [7:0]  regOut_Prio14,
  output [7:0]  regOut_Prio15
);
endmodule

module Hviprio2Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL
);
endmodule

module HtinstModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         trapToHS_htinst_valid,
  input  [63:0] trapToHS_htinst_bits_ALL
);
endmodule

module HgatpModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [3:0]  regOut_MODE,
  output [13:0] regOut_VMID,
  output [43:0] regOut_PPN
);
endmodule

module HgeipModule(

  output [63:0] rdata,
  output [4:0]  regOut_ip,
  input  [4:0]  aiaToCSR_vseip
);
endmodule

module Hstateen0Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_JVT,
  output        regOut_FCSR,
  output        regOut_C,
  output        regOut_SE0,
  output        regOut_ENVCFG,
  output        regOut_CSRIND,
  output        regOut_AIA,
  output        regOut_IMSIC,
  output        regOut_CONTEXT,
  input         fromMstateen0_SE0,
  input         fromMstateen0_ENVCFG,
  input         fromMstateen0_CSRIND,
  input         fromMstateen0_AIA,
  input         fromMstateen0_IMSIC,
  input         fromMstateen0_CONTEXT,
  input         fromMstateen0_C
);
endmodule

module Hstateen1Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SE,
  input         fromMstateen1_SE
);
endmodule

module Hstateen2Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SE,
  input         fromMstateen2_SE
);
endmodule

module Hstateen3Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SE,
  input         fromMstateen3_SE
);
endmodule

module HcontextModule(

  input         w_wen,
  input  [63:0] w_wdata,
  output [13:0] rdata,
  output [13:0] regOut_HCONTEXT,
  input  [13:0] fromMcontext_HCONTEXT,
  output        toMcontext_valid,
  output [13:0] toMcontext_bits_HCONTEXT
);
endmodule

module VSstatusModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SIE,
  output        regOut_SPIE,
  output        regOut_SPP,
  output [1:0]  regOut_VS,
  output [1:0]  regOut_FS,
  output        regOut_SUM,
  output        regOut_MXR,
  output        regOut_SDT,
  input         retFromS_vsstatus_valid,
  input         retFromS_vsstatus_bits_SIE,
  input         retFromS_vsstatus_bits_SPIE,
  input         retFromS_vsstatus_bits_SPP,
  input         retFromSSDT_vsstatus_valid,
  input         retFromM_vsstatus_valid,
  input         retFromM_vsstatus_bits_SDT,
  input         retFromMN_vsstatus_valid,
  input         retFromMN_vsstatus_bits_SDT,
  input         retFromD_vsstatus_valid,
  input         retFromD_vsstatus_bits_SDT,
  input         trapToVS_vsstatus_valid,
  input         trapToVS_vsstatus_bits_SIE,
  input         trapToVS_vsstatus_bits_SPIE,
  input         trapToVS_vsstatus_bits_SPP,
  input         trapToVS_vsstatus_bits_SDT,
  input         robCommit_fsDirty,
  input         robCommit_vsDirty,
  input         writeFCSR,
  input         writeVCSR,
  input         isVirtMode,
  input         menvcfg_DTE,
  input         henvcfg_DTE
);
endmodule

module VSieModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSIE,
  output        regOut_STIE,
  output        regOut_SEIE,
  output        regOut_LCOFIE,
  output        regOut_LC14IE,
  output        regOut_LC15IE,
  output        regOut_LC16IE,
  output        regOut_LC17IE,
  output        regOut_LC18IE,
  output        regOut_LC19IE,
  output        regOut_LC20IE,
  output        regOut_LC21IE,
  output        regOut_LC22IE,
  output        regOut_LC23IE,
  output        regOut_LC24IE,
  output        regOut_LC25IE,
  output        regOut_LC26IE,
  output        regOut_LC27IE,
  output        regOut_LC28IE,
  output        regOut_LC29IE,
  output        regOut_LC30IE,
  output        regOut_LC31IE,
  output        regOut_LC32IE,
  output        regOut_LC33IE,
  output        regOut_LC34IE,
  output        regOut_LPRASEIE,
  output        regOut_LC36IE,
  output        regOut_LC37IE,
  output        regOut_LC38IE,
  output        regOut_LC39IE,
  output        regOut_LC40IE,
  output        regOut_LC41IE,
  output        regOut_LC42IE,
  output        regOut_HPRASEIE,
  output        regOut_LC44IE,
  output        regOut_LC45IE,
  output        regOut_LC46IE,
  output        regOut_LC47IE,
  output        regOut_LC48IE,
  output        regOut_LC49IE,
  output        regOut_LC50IE,
  output        regOut_LC51IE,
  output        regOut_LC52IE,
  output        regOut_LC53IE,
  output        regOut_LC54IE,
  output        regOut_LC55IE,
  output        regOut_LC56IE,
  output        regOut_LC57IE,
  output        regOut_LC58IE,
  output        regOut_LC59IE,
  output        regOut_LC60IE,
  output        regOut_LC61IE,
  output        regOut_LC62IE,
  output        regOut_LC63IE,
  input         mideleg_SSI,
  input         mideleg_STI,
  input         mideleg_SEI,
  input         mideleg_LCOFI,
  input         mie_SSIE,
  input         mie_VSSIE,
  input         mie_MSIE,
  input         mie_STIE,
  input         mie_VSTIE,
  input         mie_MTIE,
  input         mie_SEIE,
  input         mie_VSEIE,
  input         mie_MEIE,
  input         mie_SGEIE,
  input         mie_LCOFIE,
  input         mvien_SSIE,
  input         mvien_SEIE,
  input         mvien_LC14IE,
  input         mvien_LC15IE,
  input         mvien_LC16IE,
  input         mvien_LC17IE,
  input         mvien_LC18IE,
  input         mvien_LC19IE,
  input         mvien_LC20IE,
  input         mvien_LC21IE,
  input         mvien_LC22IE,
  input         mvien_LC23IE,
  input         mvien_LC24IE,
  input         mvien_LC25IE,
  input         mvien_LC26IE,
  input         mvien_LC27IE,
  input         mvien_LC28IE,
  input         mvien_LC29IE,
  input         mvien_LC30IE,
  input         mvien_LC31IE,
  input         mvien_LC32IE,
  input         mvien_LC33IE,
  input         mvien_LC34IE,
  input         mvien_LPRASEIE,
  input         mvien_LC36IE,
  input         mvien_LC37IE,
  input         mvien_LC38IE,
  input         mvien_LC39IE,
  input         mvien_LC40IE,
  input         mvien_LC41IE,
  input         mvien_LC42IE,
  input         mvien_HPRASEIE,
  input         mvien_LC44IE,
  input         mvien_LC45IE,
  input         mvien_LC46IE,
  input         mvien_LC47IE,
  input         mvien_LC48IE,
  input         mvien_LC49IE,
  input         mvien_LC50IE,
  input         mvien_LC51IE,
  input         mvien_LC52IE,
  input         mvien_LC53IE,
  input         mvien_LC54IE,
  input         mvien_LC55IE,
  input         mvien_LC56IE,
  input         mvien_LC57IE,
  input         mvien_LC58IE,
  input         mvien_LC59IE,
  input         mvien_LC60IE,
  input         mvien_LC61IE,
  input         mvien_LC62IE,
  input         mvien_LC63IE,
  input         hideleg_SSI,
  input         hideleg_VSSI,
  input         hideleg_MSI,
  input         hideleg_STI,
  input         hideleg_VSTI,
  input         hideleg_MTI,
  input         hideleg_SEI,
  input         hideleg_VSEI,
  input         hideleg_MEI,
  input         hideleg_SGEI,
  input         hideleg_LCOFI,
  input         hvien_LC14IE,
  input         hvien_LC15IE,
  input         hvien_LC16IE,
  input         hvien_LC17IE,
  input         hvien_LC18IE,
  input         hvien_LC19IE,
  input         hvien_LC20IE,
  input         hvien_LC21IE,
  input         hvien_LC22IE,
  input         hvien_LC23IE,
  input         hvien_LC24IE,
  input         hvien_LC25IE,
  input         hvien_LC26IE,
  input         hvien_LC27IE,
  input         hvien_LC28IE,
  input         hvien_LC29IE,
  input         hvien_LC30IE,
  input         hvien_LC31IE,
  input         hvien_LC32IE,
  input         hvien_LC33IE,
  input         hvien_LC34IE,
  input         hvien_LPRASEIE,
  input         hvien_LC36IE,
  input         hvien_LC37IE,
  input         hvien_LC38IE,
  input         hvien_LC39IE,
  input         hvien_LC40IE,
  input         hvien_LC41IE,
  input         hvien_LC42IE,
  input         hvien_HPRASEIE,
  input         hvien_LC44IE,
  input         hvien_LC45IE,
  input         hvien_LC46IE,
  input         hvien_LC47IE,
  input         hvien_LC48IE,
  input         hvien_LC49IE,
  input         hvien_LC50IE,
  input         hvien_LC51IE,
  input         hvien_LC52IE,
  input         hvien_LC53IE,
  input         hvien_LC54IE,
  input         hvien_LC55IE,
  input         hvien_LC56IE,
  input         hvien_LC57IE,
  input         hvien_LC58IE,
  input         hvien_LC59IE,
  input         hvien_LC60IE,
  input         hvien_LC61IE,
  input         hvien_LC62IE,
  input         hvien_LC63IE,
  input         sie_SSIE,
  input         sie_STIE,
  input         sie_SEIE,
  input         sie_LCOFIE,
  input         sie_LC14IE,
  input         sie_LC15IE,
  input         sie_LC16IE,
  input         sie_LC17IE,
  input         sie_LC18IE,
  input         sie_LC19IE,
  input         sie_LC20IE,
  input         sie_LC21IE,
  input         sie_LC22IE,
  input         sie_LC23IE,
  input         sie_LC24IE,
  input         sie_LC25IE,
  input         sie_LC26IE,
  input         sie_LC27IE,
  input         sie_LC28IE,
  input         sie_LC29IE,
  input         sie_LC30IE,
  input         sie_LC31IE,
  input         sie_LC32IE,
  input         sie_LC33IE,
  input         sie_LC34IE,
  input         sie_LPRASEIE,
  input         sie_LC36IE,
  input         sie_LC37IE,
  input         sie_LC38IE,
  input         sie_LC39IE,
  input         sie_LC40IE,
  input         sie_LC41IE,
  input         sie_LC42IE,
  input         sie_HPRASEIE,
  input         sie_LC44IE,
  input         sie_LC45IE,
  input         sie_LC46IE,
  input         sie_LC47IE,
  input         sie_LC48IE,
  input         sie_LC49IE,
  input         sie_LC50IE,
  input         sie_LC51IE,
  input         sie_LC52IE,
  input         sie_LC53IE,
  input         sie_LC54IE,
  input         sie_LC55IE,
  input         sie_LC56IE,
  input         sie_LC57IE,
  input         sie_LC58IE,
  input         sie_LC59IE,
  input         sie_LC60IE,
  input         sie_LC61IE,
  input         sie_LC62IE,
  input         sie_LC63IE,
  output        toMie_VSSIE_valid,
  output        toMie_VSSIE_bits,
  output        toMie_VSTIE_valid,
  output        toMie_VSTIE_bits,
  output        toMie_VSEIE_valid,
  output        toMie_VSEIE_bits,
  output        toMie_LCOFIE_valid,
  output        toMie_LCOFIE_bits,
  output        toSie_VSSIE_valid,
  output        toSie_VSSIE_bits,
  output        toSie_VSTIE_valid,
  output        toSie_VSTIE_bits,
  output        toSie_VSEIE_valid,
  output        toSie_VSEIE_bits,
  output        toSie_LCOFIE_valid,
  output        toSie_LCOFIE_bits,
  output        toSie_LC14IE_valid,
  output        toSie_LC14IE_bits,
  output        toSie_LC15IE_valid,
  output        toSie_LC15IE_bits,
  output        toSie_LC16IE_valid,
  output        toSie_LC16IE_bits,
  output        toSie_LC17IE_valid,
  output        toSie_LC17IE_bits,
  output        toSie_LC18IE_valid,
  output        toSie_LC18IE_bits,
  output        toSie_LC19IE_valid,
  output        toSie_LC19IE_bits,
  output        toSie_LC20IE_valid,
  output        toSie_LC20IE_bits,
  output        toSie_LC21IE_valid,
  output        toSie_LC21IE_bits,
  output        toSie_LC22IE_valid,
  output        toSie_LC22IE_bits,
  output        toSie_LC23IE_valid,
  output        toSie_LC23IE_bits,
  output        toSie_LC24IE_valid,
  output        toSie_LC24IE_bits,
  output        toSie_LC25IE_valid,
  output        toSie_LC25IE_bits,
  output        toSie_LC26IE_valid,
  output        toSie_LC26IE_bits,
  output        toSie_LC27IE_valid,
  output        toSie_LC27IE_bits,
  output        toSie_LC28IE_valid,
  output        toSie_LC28IE_bits,
  output        toSie_LC29IE_valid,
  output        toSie_LC29IE_bits,
  output        toSie_LC30IE_valid,
  output        toSie_LC30IE_bits,
  output        toSie_LC31IE_valid,
  output        toSie_LC31IE_bits,
  output        toSie_LC32IE_valid,
  output        toSie_LC32IE_bits,
  output        toSie_LC33IE_valid,
  output        toSie_LC33IE_bits,
  output        toSie_LC34IE_valid,
  output        toSie_LC34IE_bits,
  output        toSie_LPRASEIE_valid,
  output        toSie_LPRASEIE_bits,
  output        toSie_LC36IE_valid,
  output        toSie_LC36IE_bits,
  output        toSie_LC37IE_valid,
  output        toSie_LC37IE_bits,
  output        toSie_LC38IE_valid,
  output        toSie_LC38IE_bits,
  output        toSie_LC39IE_valid,
  output        toSie_LC39IE_bits,
  output        toSie_LC40IE_valid,
  output        toSie_LC40IE_bits,
  output        toSie_LC41IE_valid,
  output        toSie_LC41IE_bits,
  output        toSie_LC42IE_valid,
  output        toSie_LC42IE_bits,
  output        toSie_HPRASEIE_valid,
  output        toSie_HPRASEIE_bits,
  output        toSie_LC44IE_valid,
  output        toSie_LC44IE_bits,
  output        toSie_LC45IE_valid,
  output        toSie_LC45IE_bits,
  output        toSie_LC46IE_valid,
  output        toSie_LC46IE_bits,
  output        toSie_LC47IE_valid,
  output        toSie_LC47IE_bits,
  output        toSie_LC48IE_valid,
  output        toSie_LC48IE_bits,
  output        toSie_LC49IE_valid,
  output        toSie_LC49IE_bits,
  output        toSie_LC50IE_valid,
  output        toSie_LC50IE_bits,
  output        toSie_LC51IE_valid,
  output        toSie_LC51IE_bits,
  output        toSie_LC52IE_valid,
  output        toSie_LC52IE_bits,
  output        toSie_LC53IE_valid,
  output        toSie_LC53IE_bits,
  output        toSie_LC54IE_valid,
  output        toSie_LC54IE_bits,
  output        toSie_LC55IE_valid,
  output        toSie_LC55IE_bits,
  output        toSie_LC56IE_valid,
  output        toSie_LC56IE_bits,
  output        toSie_LC57IE_valid,
  output        toSie_LC57IE_bits,
  output        toSie_LC58IE_valid,
  output        toSie_LC58IE_bits,
  output        toSie_LC59IE_valid,
  output        toSie_LC59IE_bits,
  output        toSie_LC60IE_valid,
  output        toSie_LC60IE_bits,
  output        toSie_LC61IE_valid,
  output        toSie_LC61IE_bits,
  output        toSie_LC62IE_valid,
  output        toSie_LC62IE_bits,
  output        toSie_LC63IE_valid,
  output        toSie_LC63IE_bits
);
endmodule

module VStvecModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [1:0]  regOut_mode,
  output [61:0] regOut_addr
);
endmodule

module VSscratchModule(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL
);
endmodule

module VSepcModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [62:0] regOut_epc,
  input         trapToVS_vsepc_valid,
  input  [62:0] trapToVS_vsepc_bits_epc
);
endmodule

module VScauseModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_Interrupt,
  output [62:0] regOut_ExceptionCode,
  input         trapToVS_vscause_valid,
  input         trapToVS_vscause_bits_Interrupt,
  input  [62:0] trapToVS_vscause_bits_ExceptionCode
);
endmodule

module VStvalModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         trapToVS_vstval_valid,
  input  [63:0] trapToVS_vstval_bits_ALL
);
endmodule

module VSipModule(

  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSIP,
  output        regOut_STIP,
  output        regOut_SEIP,
  output        regOut_LCOFIP,
  output        regOut_LC14IP,
  output        regOut_LC15IP,
  output        regOut_LC16IP,
  output        regOut_LC17IP,
  output        regOut_LC18IP,
  output        regOut_LC19IP,
  output        regOut_LC20IP,
  output        regOut_LC21IP,
  output        regOut_LC22IP,
  output        regOut_LC23IP,
  output        regOut_LC24IP,
  output        regOut_LC25IP,
  output        regOut_LC26IP,
  output        regOut_LC27IP,
  output        regOut_LC28IP,
  output        regOut_LC29IP,
  output        regOut_LC30IP,
  output        regOut_LC31IP,
  output        regOut_LC32IP,
  output        regOut_LC33IP,
  output        regOut_LC34IP,
  output        regOut_LPRASEIP,
  output        regOut_LC36IP,
  output        regOut_LC37IP,
  output        regOut_LC38IP,
  output        regOut_LC39IP,
  output        regOut_LC40IP,
  output        regOut_LC41IP,
  output        regOut_LC42IP,
  output        regOut_HPRASEIP,
  output        regOut_LC44IP,
  output        regOut_LC45IP,
  output        regOut_LC46IP,
  output        regOut_LC47IP,
  output        regOut_LC48IP,
  output        regOut_LC49IP,
  output        regOut_LC50IP,
  output        regOut_LC51IP,
  output        regOut_LC52IP,
  output        regOut_LC53IP,
  output        regOut_LC54IP,
  output        regOut_LC55IP,
  output        regOut_LC56IP,
  output        regOut_LC57IP,
  output        regOut_LC58IP,
  output        regOut_LC59IP,
  output        regOut_LC60IP,
  output        regOut_LC61IP,
  output        regOut_LC62IP,
  output        regOut_LC63IP,
  input         mideleg_SSI,
  input         mideleg_STI,
  input         mideleg_SEI,
  input         mideleg_LCOFI,
  input         mip_SSIP,
  input         mip_VSSIP,
  input         mip_MSIP,
  input         mip_STIP,
  input         mip_VSTIP,
  input         mip_MTIP,
  input         mip_SEIP,
  input         mip_VSEIP,
  input         mip_MEIP,
  input         mip_SGEIP,
  input         mip_LCOFIP,
  input         mip_LC14IP,
  input         mip_LC15IP,
  input         mip_LC16IP,
  input         mip_LC17IP,
  input         mip_LC18IP,
  input         mip_LC19IP,
  input         mip_LC20IP,
  input         mip_LC21IP,
  input         mip_LC22IP,
  input         mip_LC23IP,
  input         mip_LC24IP,
  input         mip_LC25IP,
  input         mip_LC26IP,
  input         mip_LC27IP,
  input         mip_LC28IP,
  input         mip_LC29IP,
  input         mip_LC30IP,
  input         mip_LC31IP,
  input         mip_LC32IP,
  input         mip_LC33IP,
  input         mip_LC34IP,
  input         mip_LPRASEIP,
  input         mip_LC36IP,
  input         mip_LC37IP,
  input         mip_LC38IP,
  input         mip_LC39IP,
  input         mip_LC40IP,
  input         mip_LC41IP,
  input         mip_LC42IP,
  input         mip_HPRASEIP,
  input         mip_LC44IP,
  input         mip_LC45IP,
  input         mip_LC46IP,
  input         mip_LC47IP,
  input         mip_LC48IP,
  input         mip_LC49IP,
  input         mip_LC50IP,
  input         mip_LC51IP,
  input         mip_LC52IP,
  input         mip_LC53IP,
  input         mip_LC54IP,
  input         mip_LC55IP,
  input         mip_LC56IP,
  input         mip_LC57IP,
  input         mip_LC58IP,
  input         mip_LC59IP,
  input         mip_LC60IP,
  input         mip_LC61IP,
  input         mip_LC62IP,
  input         mip_LC63IP,
  input         mvip_SSIP,
  input         mvip_STIP,
  input         mvip_SEIP,
  input         mvip_LCOFIP,
  input         mvip_LC14IP,
  input         mvip_LC15IP,
  input         mvip_LC16IP,
  input         mvip_LC17IP,
  input         mvip_LC18IP,
  input         mvip_LC19IP,
  input         mvip_LC20IP,
  input         mvip_LC21IP,
  input         mvip_LC22IP,
  input         mvip_LC23IP,
  input         mvip_LC24IP,
  input         mvip_LC25IP,
  input         mvip_LC26IP,
  input         mvip_LC27IP,
  input         mvip_LC28IP,
  input         mvip_LC29IP,
  input         mvip_LC30IP,
  input         mvip_LC31IP,
  input         mvip_LC32IP,
  input         mvip_LC33IP,
  input         mvip_LC34IP,
  input         mvip_LPRASEIP,
  input         mvip_LC36IP,
  input         mvip_LC37IP,
  input         mvip_LC38IP,
  input         mvip_LC39IP,
  input         mvip_LC40IP,
  input         mvip_LC41IP,
  input         mvip_LC42IP,
  input         mvip_HPRASEIP,
  input         mvip_LC44IP,
  input         mvip_LC45IP,
  input         mvip_LC46IP,
  input         mvip_LC47IP,
  input         mvip_LC48IP,
  input         mvip_LC49IP,
  input         mvip_LC50IP,
  input         mvip_LC51IP,
  input         mvip_LC52IP,
  input         mvip_LC53IP,
  input         mvip_LC54IP,
  input         mvip_LC55IP,
  input         mvip_LC56IP,
  input         mvip_LC57IP,
  input         mvip_LC58IP,
  input         mvip_LC59IP,
  input         mvip_LC60IP,
  input         mvip_LC61IP,
  input         mvip_LC62IP,
  input         mvip_LC63IP,
  input         mvien_SSIE,
  input         mvien_SEIE,
  input         mvien_LC14IE,
  input         mvien_LC15IE,
  input         mvien_LC16IE,
  input         mvien_LC17IE,
  input         mvien_LC18IE,
  input         mvien_LC19IE,
  input         mvien_LC20IE,
  input         mvien_LC21IE,
  input         mvien_LC22IE,
  input         mvien_LC23IE,
  input         mvien_LC24IE,
  input         mvien_LC25IE,
  input         mvien_LC26IE,
  input         mvien_LC27IE,
  input         mvien_LC28IE,
  input         mvien_LC29IE,
  input         mvien_LC30IE,
  input         mvien_LC31IE,
  input         mvien_LC32IE,
  input         mvien_LC33IE,
  input         mvien_LC34IE,
  input         mvien_LPRASEIE,
  input         mvien_LC36IE,
  input         mvien_LC37IE,
  input         mvien_LC38IE,
  input         mvien_LC39IE,
  input         mvien_LC40IE,
  input         mvien_LC41IE,
  input         mvien_LC42IE,
  input         mvien_HPRASEIE,
  input         mvien_LC44IE,
  input         mvien_LC45IE,
  input         mvien_LC46IE,
  input         mvien_LC47IE,
  input         mvien_LC48IE,
  input         mvien_LC49IE,
  input         mvien_LC50IE,
  input         mvien_LC51IE,
  input         mvien_LC52IE,
  input         mvien_LC53IE,
  input         mvien_LC54IE,
  input         mvien_LC55IE,
  input         mvien_LC56IE,
  input         mvien_LC57IE,
  input         mvien_LC58IE,
  input         mvien_LC59IE,
  input         mvien_LC60IE,
  input         mvien_LC61IE,
  input         mvien_LC62IE,
  input         mvien_LC63IE,
  input         hideleg_SSI,
  input         hideleg_VSSI,
  input         hideleg_MSI,
  input         hideleg_STI,
  input         hideleg_VSTI,
  input         hideleg_MTI,
  input         hideleg_SEI,
  input         hideleg_VSEI,
  input         hideleg_MEI,
  input         hideleg_SGEI,
  input         hideleg_LCOFI,
  input         hvien_LC14IE,
  input         hvien_LC15IE,
  input         hvien_LC16IE,
  input         hvien_LC17IE,
  input         hvien_LC18IE,
  input         hvien_LC19IE,
  input         hvien_LC20IE,
  input         hvien_LC21IE,
  input         hvien_LC22IE,
  input         hvien_LC23IE,
  input         hvien_LC24IE,
  input         hvien_LC25IE,
  input         hvien_LC26IE,
  input         hvien_LC27IE,
  input         hvien_LC28IE,
  input         hvien_LC29IE,
  input         hvien_LC30IE,
  input         hvien_LC31IE,
  input         hvien_LC32IE,
  input         hvien_LC33IE,
  input         hvien_LC34IE,
  input         hvien_LPRASEIE,
  input         hvien_LC36IE,
  input         hvien_LC37IE,
  input         hvien_LC38IE,
  input         hvien_LC39IE,
  input         hvien_LC40IE,
  input         hvien_LC41IE,
  input         hvien_LC42IE,
  input         hvien_HPRASEIE,
  input         hvien_LC44IE,
  input         hvien_LC45IE,
  input         hvien_LC46IE,
  input         hvien_LC47IE,
  input         hvien_LC48IE,
  input         hvien_LC49IE,
  input         hvien_LC50IE,
  input         hvien_LC51IE,
  input         hvien_LC52IE,
  input         hvien_LC53IE,
  input         hvien_LC54IE,
  input         hvien_LC55IE,
  input         hvien_LC56IE,
  input         hvien_LC57IE,
  input         hvien_LC58IE,
  input         hvien_LC59IE,
  input         hvien_LC60IE,
  input         hvien_LC61IE,
  input         hvien_LC62IE,
  input         hvien_LC63IE,
  input         hvip_VSSIP,
  input         hvip_VSTIP,
  input         hvip_VSEIP,
  input         hvip_LCOFIP,
  input         hvip_LC14IP,
  input         hvip_LC15IP,
  input         hvip_LC16IP,
  input         hvip_LC17IP,
  input         hvip_LC18IP,
  input         hvip_LC19IP,
  input         hvip_LC20IP,
  input         hvip_LC21IP,
  input         hvip_LC22IP,
  input         hvip_LC23IP,
  input         hvip_LC24IP,
  input         hvip_LC25IP,
  input         hvip_LC26IP,
  input         hvip_LC27IP,
  input         hvip_LC28IP,
  input         hvip_LC29IP,
  input         hvip_LC30IP,
  input         hvip_LC31IP,
  input         hvip_LC32IP,
  input         hvip_LC33IP,
  input         hvip_LC34IP,
  input         hvip_LPRASEIP,
  input         hvip_LC36IP,
  input         hvip_LC37IP,
  input         hvip_LC38IP,
  input         hvip_LC39IP,
  input         hvip_LC40IP,
  input         hvip_LC41IP,
  input         hvip_LC42IP,
  input         hvip_HPRASEIP,
  input         hvip_LC44IP,
  input         hvip_LC45IP,
  input         hvip_LC46IP,
  input         hvip_LC47IP,
  input         hvip_LC48IP,
  input         hvip_LC49IP,
  input         hvip_LC50IP,
  input         hvip_LC51IP,
  input         hvip_LC52IP,
  input         hvip_LC53IP,
  input         hvip_LC54IP,
  input         hvip_LC55IP,
  input         hvip_LC56IP,
  input         hvip_LC57IP,
  input         hvip_LC58IP,
  input         hvip_LC59IP,
  input         hvip_LC60IP,
  input         hvip_LC61IP,
  input         hvip_LC62IP,
  input         hvip_LC63IP,
  output        toMip_LCOFIP_valid,
  output        toMip_LCOFIP_bits,
  output        toHvip_VSSIP_valid,
  output        toHvip_VSSIP_bits,
  output        toHvip_LCOFIP_bits,
  output        toHvip_LC14IP_valid,
  output        toHvip_LC14IP_bits,
  output        toHvip_LC15IP_valid,
  output        toHvip_LC15IP_bits,
  output        toHvip_LC16IP_valid,
  output        toHvip_LC16IP_bits,
  output        toHvip_LC17IP_valid,
  output        toHvip_LC17IP_bits,
  output        toHvip_LC18IP_valid,
  output        toHvip_LC18IP_bits,
  output        toHvip_LC19IP_valid,
  output        toHvip_LC19IP_bits,
  output        toHvip_LC20IP_valid,
  output        toHvip_LC20IP_bits,
  output        toHvip_LC21IP_valid,
  output        toHvip_LC21IP_bits,
  output        toHvip_LC22IP_valid,
  output        toHvip_LC22IP_bits,
  output        toHvip_LC23IP_valid,
  output        toHvip_LC23IP_bits,
  output        toHvip_LC24IP_valid,
  output        toHvip_LC24IP_bits,
  output        toHvip_LC25IP_valid,
  output        toHvip_LC25IP_bits,
  output        toHvip_LC26IP_valid,
  output        toHvip_LC26IP_bits,
  output        toHvip_LC27IP_valid,
  output        toHvip_LC27IP_bits,
  output        toHvip_LC28IP_valid,
  output        toHvip_LC28IP_bits,
  output        toHvip_LC29IP_valid,
  output        toHvip_LC29IP_bits,
  output        toHvip_LC30IP_valid,
  output        toHvip_LC30IP_bits,
  output        toHvip_LC31IP_valid,
  output        toHvip_LC31IP_bits,
  output        toHvip_LC32IP_valid,
  output        toHvip_LC32IP_bits,
  output        toHvip_LC33IP_valid,
  output        toHvip_LC33IP_bits,
  output        toHvip_LC34IP_valid,
  output        toHvip_LC34IP_bits,
  output        toHvip_LPRASEIP_valid,
  output        toHvip_LPRASEIP_bits,
  output        toHvip_LC36IP_valid,
  output        toHvip_LC36IP_bits,
  output        toHvip_LC37IP_valid,
  output        toHvip_LC37IP_bits,
  output        toHvip_LC38IP_valid,
  output        toHvip_LC38IP_bits,
  output        toHvip_LC39IP_valid,
  output        toHvip_LC39IP_bits,
  output        toHvip_LC40IP_valid,
  output        toHvip_LC40IP_bits,
  output        toHvip_LC41IP_valid,
  output        toHvip_LC41IP_bits,
  output        toHvip_LC42IP_valid,
  output        toHvip_LC42IP_bits,
  output        toHvip_HPRASEIP_valid,
  output        toHvip_HPRASEIP_bits,
  output        toHvip_LC44IP_valid,
  output        toHvip_LC44IP_bits,
  output        toHvip_LC45IP_valid,
  output        toHvip_LC45IP_bits,
  output        toHvip_LC46IP_valid,
  output        toHvip_LC46IP_bits,
  output        toHvip_LC47IP_valid,
  output        toHvip_LC47IP_bits,
  output        toHvip_LC48IP_valid,
  output        toHvip_LC48IP_bits,
  output        toHvip_LC49IP_valid,
  output        toHvip_LC49IP_bits,
  output        toHvip_LC50IP_valid,
  output        toHvip_LC50IP_bits,
  output        toHvip_LC51IP_valid,
  output        toHvip_LC51IP_bits,
  output        toHvip_LC52IP_valid,
  output        toHvip_LC52IP_bits,
  output        toHvip_LC53IP_valid,
  output        toHvip_LC53IP_bits,
  output        toHvip_LC54IP_valid,
  output        toHvip_LC54IP_bits,
  output        toHvip_LC55IP_valid,
  output        toHvip_LC55IP_bits,
  output        toHvip_LC56IP_valid,
  output        toHvip_LC56IP_bits,
  output        toHvip_LC57IP_valid,
  output        toHvip_LC57IP_bits,
  output        toHvip_LC58IP_valid,
  output        toHvip_LC58IP_bits,
  output        toHvip_LC59IP_valid,
  output        toHvip_LC59IP_bits,
  output        toHvip_LC60IP_valid,
  output        toHvip_LC60IP_bits,
  output        toHvip_LC61IP_valid,
  output        toHvip_LC61IP_bits,
  output        toHvip_LC62IP_valid,
  output        toHvip_LC62IP_bits,
  output        toHvip_LC63IP_valid,
  output        toHvip_LC63IP_bits
);
endmodule

module VStimecmpModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_vstimecmp
);
endmodule

module VSatpModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [3:0]  regOut_MODE,
  output [15:0] regOut_ASID,
  output [43:0] regOut_PPN,
  input         v,
  input  [3:0]  hgatp_MODE
);
endmodule

module FcsrModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         robCommit_fflags_valid,
  input  [4:0]  robCommit_fflags_bits,
  input         wAliasFflags_wen,
  input  [63:0] wAliasFflags_wdata,
  input         wAliasFfm_wen,
  input  [63:0] wAliasFfm_wdata,
  output [4:0]  fflags,
  output [2:0]  frm,
  output [4:0]  fflagsRdata,
  output [2:0]  frmRdata
);
endmodule

module VstartModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [6:0]  regOut_vstart,
  input         robCommit_vsDirty,
  input         robCommit_vstart_valid,
  input  [6:0]  robCommit_vstart_bits
);
endmodule

module VcsrModule(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         robCommit_vxsat_valid,
  input         robCommit_vxsat_bits,
  input         wAliasVxsat_wen,
  input  [63:0] wAliasVxsat_wdata,
  input         wAliasVxrm_wen,
  input  [63:0] wAliasVxrm_wdata,
  output        vxsat,
  output [1:0]  vxrm
);
endmodule

module VtypeModule(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input         robCommit_vtype_valid,
  input         robCommit_vtype_bits_VILL,
  input         robCommit_vtype_bits_VMA,
  input         robCommit_vtype_bits_VTA,
  input  [2:0]  robCommit_vtype_bits_VSEW,
  input  [2:0]  robCommit_vtype_bits_VLMUL
);
endmodule

module cycleModule(

  input         clock,
  output [63:0] rdata,
  input  [63:0] mHPM_cycle,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module timeModule(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input         mHPM_time_valid,
  input  [63:0] mHPM_time_bits,
  input         v,
  input         nextV,
  input  [63:0] htimedelta,
  input         debugModeStopTime,
  output        updated,
  output [63:0] stime,
  output [63:0] vstime
);
endmodule

module instretModule(

  input         clock,
  output [63:0] rdata,
  input  [63:0] mHPM_instret,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter3Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_0,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter4Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_1,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter5Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_2,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter6Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_3,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter7Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_4,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter8Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_5,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter9Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_6,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter10Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_7,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter11Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_8,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter12Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_9,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter13Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_10,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter14Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_11,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter15Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_12,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter16Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_13,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter17Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_14,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter18Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_15,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter19Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_16,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter20Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_17,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter21Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_18,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter22Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_19,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter23Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_20,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter24Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_21,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter25Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_22,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter26Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_23,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter27Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_24,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter28Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_25,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter29Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_26,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter30Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_27,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module Hpmcounter31Module(

  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_28,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
endmodule

module MiselectModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [8:0]  regOut_ALL,
  output        inIMSICRange
);
endmodule

module MiregModule(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input  [63:0] iregRead_mireg
);
endmodule

module MtopeiModule(

  output [63:0] rdata,
  output [10:0] regOut_IID,
  output [10:0] regOut_IPRIO,
  input  [10:0] aiaToCSR_mtopei_IID,
  input  [10:0] aiaToCSR_mtopei_IPRIO
);
endmodule

module MtopiModule(

  output [63:0] rdata,
  input  [11:0] topIR_mtopi_IID,
  input  [7:0]  topIR_mtopi_IPRIO
);
endmodule

module SiselectModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [12:0] regOut_ALL,
  output        inIMSICRange
);
endmodule

module SiregModule(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input  [63:0] iregRead_sireg
);
endmodule

module StopeiModule(

  output [63:0] rdata,
  output [10:0] regOut_IID,
  output [10:0] regOut_IPRIO,
  input  [10:0] aiaToCSR_stopei_IID,
  input  [10:0] aiaToCSR_stopei_IPRIO
);
endmodule

module StopiModule(

  output [63:0] rdata,
  input  [11:0] topIR_stopi_IID,
  input  [7:0]  topIR_stopi_IPRIO
);
endmodule

module VSiselectModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [12:0] regOut_ALL,
  output        inIMSICRange
);
endmodule

module VSiregModule(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input  [63:0] iregRead_sireg
);
endmodule

module VStopeiModule(

  output [63:0] rdata,
  output [10:0] regOut_IID,
  output [10:0] regOut_IPRIO,
  input  [10:0] aiaToCSR_vstopei_IID,
  input  [10:0] aiaToCSR_vstopei_IPRIO
);
endmodule

module VStopiModule(

  output [63:0] rdata,
  input  [11:0] topIR_vstopi_IID,
  input  [7:0]  topIR_vstopi_IPRIO
);
endmodule

module Iprio0Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         mie_SSIE,
  input         mie_VSSIE,
  input         mie_MSIE,
  input         mie_STIE,
  input         mie_VSTIE,
  input         mie_MTIE,
  input         mie_SEIE,
  input         mie_VSEIE,
  input         mie_MEIE,
  input         mie_SGEIE,
  input         mie_LCOFIE
);
endmodule

module Iprio2Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         mie_SSIE,
  input         mie_VSSIE,
  input         mie_MSIE,
  input         mie_STIE,
  input         mie_VSTIE,
  input         mie_MTIE,
  input         mie_SEIE,
  input         mie_VSEIE,
  input         mie_MEIE,
  input         mie_SGEIE,
  input         mie_LCOFIE
);
endmodule

module Iprio4Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         mie_SSIE,
  input         mie_VSSIE,
  input         mie_MSIE,
  input         mie_STIE,
  input         mie_VSTIE,
  input         mie_MTIE,
  input         mie_SEIE,
  input         mie_VSEIE,
  input         mie_MEIE,
  input         mie_SGEIE,
  input         mie_LCOFIE
);
endmodule

module Iprio6Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         mie_SSIE,
  input         mie_VSSIE,
  input         mie_MSIE,
  input         mie_STIE,
  input         mie_VSTIE,
  input         mie_MTIE,
  input         mie_SEIE,
  input         mie_VSEIE,
  input         mie_MEIE,
  input         mie_SGEIE,
  input         mie_LCOFIE
);
endmodule

module Iprio8Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         mie_SSIE,
  input         mie_VSSIE,
  input         mie_MSIE,
  input         mie_STIE,
  input         mie_VSTIE,
  input         mie_MTIE,
  input         mie_SEIE,
  input         mie_VSEIE,
  input         mie_MEIE,
  input         mie_SGEIE,
  input         mie_LCOFIE
);
endmodule

module Iprio10Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         mie_SSIE,
  input         mie_VSSIE,
  input         mie_MSIE,
  input         mie_STIE,
  input         mie_VSTIE,
  input         mie_MTIE,
  input         mie_SEIE,
  input         mie_VSEIE,
  input         mie_MEIE,
  input         mie_SGEIE,
  input         mie_LCOFIE
);
endmodule

module Iprio12Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         mie_SSIE,
  input         mie_VSSIE,
  input         mie_MSIE,
  input         mie_STIE,
  input         mie_VSTIE,
  input         mie_MTIE,
  input         mie_SEIE,
  input         mie_VSEIE,
  input         mie_MEIE,
  input         mie_SGEIE,
  input         mie_LCOFIE
);
endmodule

module Iprio14Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         mie_SSIE,
  input         mie_VSSIE,
  input         mie_MSIE,
  input         mie_STIE,
  input         mie_VSTIE,
  input         mie_MTIE,
  input         mie_SEIE,
  input         mie_VSEIE,
  input         mie_MEIE,
  input         mie_SGEIE,
  input         mie_LCOFIE
);
endmodule

module Iprio0Module_1(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         sie_SSIE,
  input         sie_STIE,
  input         sie_SEIE,
  input         sie_LCOFIE,
  input         sie_LC14IE,
  input         sie_LC15IE,
  input         sie_LC16IE,
  input         sie_LC17IE,
  input         sie_LC18IE,
  input         sie_LC19IE,
  input         sie_LC20IE,
  input         sie_LC21IE,
  input         sie_LC22IE,
  input         sie_LC23IE,
  input         sie_LC24IE,
  input         sie_LC25IE,
  input         sie_LC26IE,
  input         sie_LC27IE,
  input         sie_LC28IE,
  input         sie_LC29IE,
  input         sie_LC30IE,
  input         sie_LC31IE,
  input         sie_LC32IE,
  input         sie_LC33IE,
  input         sie_LC34IE,
  input         sie_LPRASEIE,
  input         sie_LC36IE,
  input         sie_LC37IE,
  input         sie_LC38IE,
  input         sie_LC39IE,
  input         sie_LC40IE,
  input         sie_LC41IE,
  input         sie_LC42IE,
  input         sie_HPRASEIE,
  input         sie_LC44IE,
  input         sie_LC45IE,
  input         sie_LC46IE,
  input         sie_LC47IE,
  input         sie_LC48IE,
  input         sie_LC49IE,
  input         sie_LC50IE,
  input         sie_LC51IE,
  input         sie_LC52IE,
  input         sie_LC53IE,
  input         sie_LC54IE,
  input         sie_LC55IE,
  input         sie_LC56IE,
  input         sie_LC57IE,
  input         sie_LC58IE,
  input         sie_LC59IE,
  input         sie_LC60IE,
  input         sie_LC61IE,
  input         sie_LC62IE,
  input         sie_LC63IE
);
endmodule

module Iprio2Module_1(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         sie_SSIE,
  input         sie_STIE,
  input         sie_SEIE,
  input         sie_LCOFIE,
  input         sie_LC14IE,
  input         sie_LC15IE,
  input         sie_LC16IE,
  input         sie_LC17IE,
  input         sie_LC18IE,
  input         sie_LC19IE,
  input         sie_LC20IE,
  input         sie_LC21IE,
  input         sie_LC22IE,
  input         sie_LC23IE,
  input         sie_LC24IE,
  input         sie_LC25IE,
  input         sie_LC26IE,
  input         sie_LC27IE,
  input         sie_LC28IE,
  input         sie_LC29IE,
  input         sie_LC30IE,
  input         sie_LC31IE,
  input         sie_LC32IE,
  input         sie_LC33IE,
  input         sie_LC34IE,
  input         sie_LPRASEIE,
  input         sie_LC36IE,
  input         sie_LC37IE,
  input         sie_LC38IE,
  input         sie_LC39IE,
  input         sie_LC40IE,
  input         sie_LC41IE,
  input         sie_LC42IE,
  input         sie_HPRASEIE,
  input         sie_LC44IE,
  input         sie_LC45IE,
  input         sie_LC46IE,
  input         sie_LC47IE,
  input         sie_LC48IE,
  input         sie_LC49IE,
  input         sie_LC50IE,
  input         sie_LC51IE,
  input         sie_LC52IE,
  input         sie_LC53IE,
  input         sie_LC54IE,
  input         sie_LC55IE,
  input         sie_LC56IE,
  input         sie_LC57IE,
  input         sie_LC58IE,
  input         sie_LC59IE,
  input         sie_LC60IE,
  input         sie_LC61IE,
  input         sie_LC62IE,
  input         sie_LC63IE
);
endmodule

module Iprio4Module_1(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         sie_SSIE,
  input         sie_STIE,
  input         sie_SEIE,
  input         sie_LCOFIE,
  input         sie_LC14IE,
  input         sie_LC15IE,
  input         sie_LC16IE,
  input         sie_LC17IE,
  input         sie_LC18IE,
  input         sie_LC19IE,
  input         sie_LC20IE,
  input         sie_LC21IE,
  input         sie_LC22IE,
  input         sie_LC23IE,
  input         sie_LC24IE,
  input         sie_LC25IE,
  input         sie_LC26IE,
  input         sie_LC27IE,
  input         sie_LC28IE,
  input         sie_LC29IE,
  input         sie_LC30IE,
  input         sie_LC31IE,
  input         sie_LC32IE,
  input         sie_LC33IE,
  input         sie_LC34IE,
  input         sie_LPRASEIE,
  input         sie_LC36IE,
  input         sie_LC37IE,
  input         sie_LC38IE,
  input         sie_LC39IE,
  input         sie_LC40IE,
  input         sie_LC41IE,
  input         sie_LC42IE,
  input         sie_HPRASEIE,
  input         sie_LC44IE,
  input         sie_LC45IE,
  input         sie_LC46IE,
  input         sie_LC47IE,
  input         sie_LC48IE,
  input         sie_LC49IE,
  input         sie_LC50IE,
  input         sie_LC51IE,
  input         sie_LC52IE,
  input         sie_LC53IE,
  input         sie_LC54IE,
  input         sie_LC55IE,
  input         sie_LC56IE,
  input         sie_LC57IE,
  input         sie_LC58IE,
  input         sie_LC59IE,
  input         sie_LC60IE,
  input         sie_LC61IE,
  input         sie_LC62IE,
  input         sie_LC63IE
);
endmodule

module Iprio6Module_1(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         sie_SSIE,
  input         sie_STIE,
  input         sie_SEIE,
  input         sie_LCOFIE,
  input         sie_LC14IE,
  input         sie_LC15IE,
  input         sie_LC16IE,
  input         sie_LC17IE,
  input         sie_LC18IE,
  input         sie_LC19IE,
  input         sie_LC20IE,
  input         sie_LC21IE,
  input         sie_LC22IE,
  input         sie_LC23IE,
  input         sie_LC24IE,
  input         sie_LC25IE,
  input         sie_LC26IE,
  input         sie_LC27IE,
  input         sie_LC28IE,
  input         sie_LC29IE,
  input         sie_LC30IE,
  input         sie_LC31IE,
  input         sie_LC32IE,
  input         sie_LC33IE,
  input         sie_LC34IE,
  input         sie_LPRASEIE,
  input         sie_LC36IE,
  input         sie_LC37IE,
  input         sie_LC38IE,
  input         sie_LC39IE,
  input         sie_LC40IE,
  input         sie_LC41IE,
  input         sie_LC42IE,
  input         sie_HPRASEIE,
  input         sie_LC44IE,
  input         sie_LC45IE,
  input         sie_LC46IE,
  input         sie_LC47IE,
  input         sie_LC48IE,
  input         sie_LC49IE,
  input         sie_LC50IE,
  input         sie_LC51IE,
  input         sie_LC52IE,
  input         sie_LC53IE,
  input         sie_LC54IE,
  input         sie_LC55IE,
  input         sie_LC56IE,
  input         sie_LC57IE,
  input         sie_LC58IE,
  input         sie_LC59IE,
  input         sie_LC60IE,
  input         sie_LC61IE,
  input         sie_LC62IE,
  input         sie_LC63IE
);
endmodule

module Iprio8Module_1(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         sie_SSIE,
  input         sie_STIE,
  input         sie_SEIE,
  input         sie_LCOFIE,
  input         sie_LC14IE,
  input         sie_LC15IE,
  input         sie_LC16IE,
  input         sie_LC17IE,
  input         sie_LC18IE,
  input         sie_LC19IE,
  input         sie_LC20IE,
  input         sie_LC21IE,
  input         sie_LC22IE,
  input         sie_LC23IE,
  input         sie_LC24IE,
  input         sie_LC25IE,
  input         sie_LC26IE,
  input         sie_LC27IE,
  input         sie_LC28IE,
  input         sie_LC29IE,
  input         sie_LC30IE,
  input         sie_LC31IE,
  input         sie_LC32IE,
  input         sie_LC33IE,
  input         sie_LC34IE,
  input         sie_LPRASEIE,
  input         sie_LC36IE,
  input         sie_LC37IE,
  input         sie_LC38IE,
  input         sie_LC39IE,
  input         sie_LC40IE,
  input         sie_LC41IE,
  input         sie_LC42IE,
  input         sie_HPRASEIE,
  input         sie_LC44IE,
  input         sie_LC45IE,
  input         sie_LC46IE,
  input         sie_LC47IE,
  input         sie_LC48IE,
  input         sie_LC49IE,
  input         sie_LC50IE,
  input         sie_LC51IE,
  input         sie_LC52IE,
  input         sie_LC53IE,
  input         sie_LC54IE,
  input         sie_LC55IE,
  input         sie_LC56IE,
  input         sie_LC57IE,
  input         sie_LC58IE,
  input         sie_LC59IE,
  input         sie_LC60IE,
  input         sie_LC61IE,
  input         sie_LC62IE,
  input         sie_LC63IE
);
endmodule

module Iprio10Module_1(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         sie_SSIE,
  input         sie_STIE,
  input         sie_SEIE,
  input         sie_LCOFIE,
  input         sie_LC14IE,
  input         sie_LC15IE,
  input         sie_LC16IE,
  input         sie_LC17IE,
  input         sie_LC18IE,
  input         sie_LC19IE,
  input         sie_LC20IE,
  input         sie_LC21IE,
  input         sie_LC22IE,
  input         sie_LC23IE,
  input         sie_LC24IE,
  input         sie_LC25IE,
  input         sie_LC26IE,
  input         sie_LC27IE,
  input         sie_LC28IE,
  input         sie_LC29IE,
  input         sie_LC30IE,
  input         sie_LC31IE,
  input         sie_LC32IE,
  input         sie_LC33IE,
  input         sie_LC34IE,
  input         sie_LPRASEIE,
  input         sie_LC36IE,
  input         sie_LC37IE,
  input         sie_LC38IE,
  input         sie_LC39IE,
  input         sie_LC40IE,
  input         sie_LC41IE,
  input         sie_LC42IE,
  input         sie_HPRASEIE,
  input         sie_LC44IE,
  input         sie_LC45IE,
  input         sie_LC46IE,
  input         sie_LC47IE,
  input         sie_LC48IE,
  input         sie_LC49IE,
  input         sie_LC50IE,
  input         sie_LC51IE,
  input         sie_LC52IE,
  input         sie_LC53IE,
  input         sie_LC54IE,
  input         sie_LC55IE,
  input         sie_LC56IE,
  input         sie_LC57IE,
  input         sie_LC58IE,
  input         sie_LC59IE,
  input         sie_LC60IE,
  input         sie_LC61IE,
  input         sie_LC62IE,
  input         sie_LC63IE
);
endmodule

module Iprio12Module_1(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         sie_SSIE,
  input         sie_STIE,
  input         sie_SEIE,
  input         sie_LCOFIE,
  input         sie_LC14IE,
  input         sie_LC15IE,
  input         sie_LC16IE,
  input         sie_LC17IE,
  input         sie_LC18IE,
  input         sie_LC19IE,
  input         sie_LC20IE,
  input         sie_LC21IE,
  input         sie_LC22IE,
  input         sie_LC23IE,
  input         sie_LC24IE,
  input         sie_LC25IE,
  input         sie_LC26IE,
  input         sie_LC27IE,
  input         sie_LC28IE,
  input         sie_LC29IE,
  input         sie_LC30IE,
  input         sie_LC31IE,
  input         sie_LC32IE,
  input         sie_LC33IE,
  input         sie_LC34IE,
  input         sie_LPRASEIE,
  input         sie_LC36IE,
  input         sie_LC37IE,
  input         sie_LC38IE,
  input         sie_LC39IE,
  input         sie_LC40IE,
  input         sie_LC41IE,
  input         sie_LC42IE,
  input         sie_HPRASEIE,
  input         sie_LC44IE,
  input         sie_LC45IE,
  input         sie_LC46IE,
  input         sie_LC47IE,
  input         sie_LC48IE,
  input         sie_LC49IE,
  input         sie_LC50IE,
  input         sie_LC51IE,
  input         sie_LC52IE,
  input         sie_LC53IE,
  input         sie_LC54IE,
  input         sie_LC55IE,
  input         sie_LC56IE,
  input         sie_LC57IE,
  input         sie_LC58IE,
  input         sie_LC59IE,
  input         sie_LC60IE,
  input         sie_LC61IE,
  input         sie_LC62IE,
  input         sie_LC63IE
);
endmodule

module Iprio14Module_1(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         sie_SSIE,
  input         sie_STIE,
  input         sie_SEIE,
  input         sie_LCOFIE,
  input         sie_LC14IE,
  input         sie_LC15IE,
  input         sie_LC16IE,
  input         sie_LC17IE,
  input         sie_LC18IE,
  input         sie_LC19IE,
  input         sie_LC20IE,
  input         sie_LC21IE,
  input         sie_LC22IE,
  input         sie_LC23IE,
  input         sie_LC24IE,
  input         sie_LC25IE,
  input         sie_LC26IE,
  input         sie_LC27IE,
  input         sie_LC28IE,
  input         sie_LC29IE,
  input         sie_LC30IE,
  input         sie_LC31IE,
  input         sie_LC32IE,
  input         sie_LC33IE,
  input         sie_LC34IE,
  input         sie_LPRASEIE,
  input         sie_LC36IE,
  input         sie_LC37IE,
  input         sie_LC38IE,
  input         sie_LC39IE,
  input         sie_LC40IE,
  input         sie_LC41IE,
  input         sie_LC42IE,
  input         sie_HPRASEIE,
  input         sie_LC44IE,
  input         sie_LC45IE,
  input         sie_LC46IE,
  input         sie_LC47IE,
  input         sie_LC48IE,
  input         sie_LC49IE,
  input         sie_LC50IE,
  input         sie_LC51IE,
  input         sie_LC52IE,
  input         sie_LC53IE,
  input         sie_LC54IE,
  input         sie_LC55IE,
  input         sie_LC56IE,
  input         sie_LC57IE,
  input         sie_LC58IE,
  input         sie_LC59IE,
  input         sie_LC60IE,
  input         sie_LC61IE,
  input         sie_LC62IE,
  input         sie_LC63IE
);
endmodule

module Mireg2Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
endmodule

module Mireg3Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
endmodule

module Mireg4Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
endmodule

module Mireg5Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
endmodule

module Mireg6Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
endmodule

module Sireg2Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
endmodule

module Sireg3Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
endmodule

module Sireg4Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
endmodule

module Sireg5Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
endmodule

module Sireg6Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
endmodule

module VSireg2Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
endmodule

module VSireg3Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
endmodule

module VSireg4Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
endmodule

module VSireg5Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
endmodule

module VSireg6Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
endmodule

module TrapEntryDEventModule(

  input         valid,
  input  [49:0] in_trapPc,
  input  [1:0]  in_iMode_PRVM,
  input         in_iMode_V,
  input  [1:0]  in_privState_PRVM,
  input         in_privState_V,
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
  input         in_hasTrap,
  input         in_debugMode,
  input         in_hasDebugIntr,
  input         in_triggerEnterDebugMode,
  input         in_hasDebugEbreakException,
  input         in_hasSingleStep,
  input         in_breakPoint,
  input         in_criticalErrorStateEnterDebug,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_dcsr_valid,
  output [3:0]  out_dcsr_bits_DEBUGVER,
  output [2:0]  out_dcsr_bits_EXTCAUSE,
  output        out_dcsr_bits_CETRIG,
  output        out_dcsr_bits_EBREAKVS,
  output        out_dcsr_bits_EBREAKVU,
  output        out_dcsr_bits_EBREAKM,
  output        out_dcsr_bits_EBREAKS,
  output        out_dcsr_bits_EBREAKU,
  output        out_dcsr_bits_STEPIE,
  output        out_dcsr_bits_STOPCOUNT,
  output        out_dcsr_bits_STOPTIME,
  output [2:0]  out_dcsr_bits_CAUSE,
  output        out_dcsr_bits_V,
  output        out_dcsr_bits_MPRVEN,
  output        out_dcsr_bits_NMIP,
  output        out_dcsr_bits_STEP,
  output [1:0]  out_dcsr_bits_PRV,
  output        out_dpc_valid,
  output [62:0] out_dpc_bits_epc,
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF,
  output        out_debugMode_valid,
  output        out_debugMode_bits,
  output        out_debugIntrEnable_valid,
  output        out_debugIntrEnable_bits
);
endmodule

module TrapEntryMEventModule(

  input         valid,
  input         in_causeNO_Interrupt,
  input  [62:0] in_causeNO_ExceptionCode,
  input  [49:0] in_trapPc,
  input  [55:0] in_trapPcGPA,
  input         in_trapInst_valid,
  input  [31:0] in_trapInst_bits,
  input  [63:0] in_fetchMalTval,
  input         in_isCrossPageIPF,
  input         in_isHls,
  input         in_isFetchMalAddr,
  input         in_isFetchBkpt,
  input         in_trapIsForVSnonLeafPTE,
  input         in_hasDTExcp,
  input  [1:0]  in_iMode_PRVM,
  input         in_iMode_V,
  input         in_dMode_V,
  input  [1:0]  in_privState_PRVM,
  input         in_privState_V,
  input         in_mstatus_MIE,
  input  [63:0] in_pcFromXtvec,
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
  input  [63:0] in_memExceptionVAddr,
  input  [63:0] in_memExceptionGPAddr,
  input         in_memExceptionIsForVSnonLeafPTE,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_mstatus_valid,
  output        out_mstatus_bits_SIE,
  output        out_mstatus_bits_MIE,
  output        out_mstatus_bits_SPIE,
  output        out_mstatus_bits_UBE,
  output        out_mstatus_bits_MPIE,
  output        out_mstatus_bits_SPP,
  output [1:0]  out_mstatus_bits_VS,
  output [1:0]  out_mstatus_bits_MPP,
  output [1:0]  out_mstatus_bits_FS,
  output [1:0]  out_mstatus_bits_XS,
  output        out_mstatus_bits_MPRV,
  output        out_mstatus_bits_SUM,
  output        out_mstatus_bits_MXR,
  output        out_mstatus_bits_TVM,
  output        out_mstatus_bits_TW,
  output        out_mstatus_bits_TSR,
  output        out_mstatus_bits_SDT,
  output [1:0]  out_mstatus_bits_UXL,
  output [1:0]  out_mstatus_bits_SXL,
  output        out_mstatus_bits_SBE,
  output        out_mstatus_bits_MBE,
  output        out_mstatus_bits_GVA,
  output        out_mstatus_bits_MPV,
  output        out_mstatus_bits_MDT,
  output        out_mstatus_bits_SD,
  output        out_mepc_valid,
  output [62:0] out_mepc_bits_epc,
  output        out_mcause_valid,
  output        out_mcause_bits_Interrupt,
  output [62:0] out_mcause_bits_ExceptionCode,
  output        out_mtval_valid,
  output [63:0] out_mtval_bits_ALL,
  output        out_mtval2_valid,
  output [63:0] out_mtval2_bits_ALL,
  output        out_mtinst_valid,
  output [63:0] out_mtinst_bits_ALL,
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF
);
endmodule

module TrapEntryMNEventModule(

  input         valid,
  input         in_causeNO_Interrupt,
  input  [62:0] in_causeNO_ExceptionCode,
  input  [49:0] in_trapPc,
  input  [63:0] in_fetchMalTval,
  input         in_isFetchMalAddr,
  input  [1:0]  in_iMode_PRVM,
  input         in_iMode_V,
  input  [1:0]  in_privState_PRVM,
  input         in_privState_V,
  input  [63:0] in_pcFromXtvec,
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_mnstatus_valid,
  output        out_mnstatus_bits_NMIE,
  output        out_mnstatus_bits_MNPV,
  output        out_mnstatus_bits_MNPELP,
  output [1:0]  out_mnstatus_bits_MNPP,
  output        out_mnepc_valid,
  output [62:0] out_mnepc_bits_epc,
  output        out_mncause_valid,
  output        out_mncause_bits_Interrupt,
  output [62:0] out_mncause_bits_ExceptionCode,
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF
);
endmodule

module TrapEntryHSEventModule(

  input         valid,
  input         in_causeNO_Interrupt,
  input  [62:0] in_causeNO_ExceptionCode,
  input  [49:0] in_trapPc,
  input  [55:0] in_trapPcGPA,
  input         in_trapInst_valid,
  input  [31:0] in_trapInst_bits,
  input  [63:0] in_fetchMalTval,
  input         in_isCrossPageIPF,
  input         in_isHls,
  input         in_isFetchMalAddr,
  input         in_isFetchBkpt,
  input         in_trapIsForVSnonLeafPTE,
  input  [1:0]  in_iMode_PRVM,
  input         in_iMode_V,
  input         in_dMode_V,
  input  [1:0]  in_privState_PRVM,
  input         in_privState_V,
  input         in_hstatus_SPVP,
  input         in_sstatus_SIE,
  input         in_menvcfg_DTE,
  input  [63:0] in_pcFromXtvec,
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
  input  [63:0] in_memExceptionVAddr,
  input  [63:0] in_memExceptionGPAddr,
  input         in_memExceptionIsForVSnonLeafPTE,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_mstatus_valid,
  output        out_mstatus_bits_SIE,
  output        out_mstatus_bits_MIE,
  output        out_mstatus_bits_SPIE,
  output        out_mstatus_bits_UBE,
  output        out_mstatus_bits_MPIE,
  output        out_mstatus_bits_SPP,
  output [1:0]  out_mstatus_bits_VS,
  output [1:0]  out_mstatus_bits_MPP,
  output [1:0]  out_mstatus_bits_FS,
  output [1:0]  out_mstatus_bits_XS,
  output        out_mstatus_bits_MPRV,
  output        out_mstatus_bits_SUM,
  output        out_mstatus_bits_MXR,
  output        out_mstatus_bits_TVM,
  output        out_mstatus_bits_TW,
  output        out_mstatus_bits_TSR,
  output        out_mstatus_bits_SDT,
  output [1:0]  out_mstatus_bits_UXL,
  output [1:0]  out_mstatus_bits_SXL,
  output        out_mstatus_bits_SBE,
  output        out_mstatus_bits_MBE,
  output        out_mstatus_bits_GVA,
  output        out_mstatus_bits_MPV,
  output        out_mstatus_bits_MDT,
  output        out_mstatus_bits_SD,
  output        out_hstatus_valid,
  output        out_hstatus_bits_VSBE,
  output        out_hstatus_bits_GVA,
  output        out_hstatus_bits_SPV,
  output        out_hstatus_bits_SPVP,
  output        out_hstatus_bits_HU,
  output [5:0]  out_hstatus_bits_VGEIN,
  output        out_hstatus_bits_VTVM,
  output        out_hstatus_bits_VTW,
  output        out_hstatus_bits_VTSR,
  output [1:0]  out_hstatus_bits_VSXL,
  output [1:0]  out_hstatus_bits_HUPMM,
  output        out_sepc_valid,
  output [62:0] out_sepc_bits_epc,
  output        out_scause_valid,
  output        out_scause_bits_Interrupt,
  output [62:0] out_scause_bits_ExceptionCode,
  output        out_stval_valid,
  output [63:0] out_stval_bits_ALL,
  output        out_htval_valid,
  output [63:0] out_htval_bits_ALL,
  output        out_htinst_valid,
  output [63:0] out_htinst_bits_ALL,
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF
);
endmodule

module TrapEntryVSEventModule(

  input         clock,
  input         reset,
  input         valid,
  input         in_causeNO_Interrupt,
  input  [62:0] in_causeNO_ExceptionCode,
  input  [49:0] in_trapPc,
  input         in_trapInst_valid,
  input  [31:0] in_trapInst_bits,
  input  [63:0] in_fetchMalTval,
  input         in_isCrossPageIPF,
  input         in_isFetchMalAddr,
  input         in_isFetchBkpt,
  input  [1:0]  in_iMode_PRVM,
  input         in_iMode_V,
  input         in_dMode_V,
  input  [1:0]  in_privState_PRVM,
  input         in_privState_V,
  input         in_vsstatus_SIE,
  input         in_henvcfg_DTE,
  input  [63:0] in_pcFromXtvec,
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
  input  [63:0] in_memExceptionVAddr,
  input         in_virtualInterruptIsHvictlInject,
  input  [11:0] in_hvictlIID,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_vsstatus_valid,
  output        out_vsstatus_bits_SIE,
  output        out_vsstatus_bits_SPIE,
  output        out_vsstatus_bits_UBE,
  output        out_vsstatus_bits_SPP,
  output [1:0]  out_vsstatus_bits_VS,
  output [1:0]  out_vsstatus_bits_FS,
  output [1:0]  out_vsstatus_bits_XS,
  output        out_vsstatus_bits_SUM,
  output        out_vsstatus_bits_MXR,
  output        out_vsstatus_bits_SDT,
  output [1:0]  out_vsstatus_bits_UXL,
  output        out_vsstatus_bits_SD,
  output        out_vsepc_valid,
  output [62:0] out_vsepc_bits_epc,
  output        out_vscause_valid,
  output        out_vscause_bits_Interrupt,
  output [62:0] out_vscause_bits_ExceptionCode,
  output        out_vstval_valid,
  output [63:0] out_vstval_bits_ALL,
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF
);
endmodule

module MretEventModule(

  input         valid,
  input         in_mstatus_MPIE,
  input  [1:0]  in_mstatus_MPP,
  input         in_mstatus_MPRV,
  input         in_mstatus_SDT,
  input         in_mstatus_MPV,
  input         in_vsstatus_SDT,
  input  [62:0] in_mepc_epc,
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_mstatus_valid,
  output        out_mstatus_bits_SIE,
  output        out_mstatus_bits_MIE,
  output        out_mstatus_bits_SPIE,
  output        out_mstatus_bits_UBE,
  output        out_mstatus_bits_MPIE,
  output        out_mstatus_bits_SPP,
  output [1:0]  out_mstatus_bits_VS,
  output [1:0]  out_mstatus_bits_MPP,
  output [1:0]  out_mstatus_bits_FS,
  output [1:0]  out_mstatus_bits_XS,
  output        out_mstatus_bits_MPRV,
  output        out_mstatus_bits_SUM,
  output        out_mstatus_bits_MXR,
  output        out_mstatus_bits_TVM,
  output        out_mstatus_bits_TW,
  output        out_mstatus_bits_TSR,
  output        out_mstatus_bits_SDT,
  output [1:0]  out_mstatus_bits_UXL,
  output [1:0]  out_mstatus_bits_SXL,
  output        out_mstatus_bits_SBE,
  output        out_mstatus_bits_MBE,
  output        out_mstatus_bits_GVA,
  output        out_mstatus_bits_MPV,
  output        out_mstatus_bits_MDT,
  output        out_mstatus_bits_SD,
  output        out_vsstatus_valid,
  output        out_vsstatus_bits_SIE,
  output        out_vsstatus_bits_SPIE,
  output        out_vsstatus_bits_UBE,
  output        out_vsstatus_bits_SPP,
  output [1:0]  out_vsstatus_bits_VS,
  output [1:0]  out_vsstatus_bits_FS,
  output [1:0]  out_vsstatus_bits_XS,
  output        out_vsstatus_bits_SUM,
  output        out_vsstatus_bits_MXR,
  output        out_vsstatus_bits_SDT,
  output [1:0]  out_vsstatus_bits_UXL,
  output        out_vsstatus_bits_SD,
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF
);
endmodule

module MNretEventModule(

  input         valid,
  input         in_mnstatus_MNPV,
  input  [1:0]  in_mnstatus_MNPP,
  input         in_mstatus_MPRV,
  input         in_mstatus_SDT,
  input         in_mstatus_MDT,
  input  [62:0] in_mnepc_epc,
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
  input         in_vsstatus_SDT,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_mnstatus_valid,
  output        out_mnstatus_bits_NMIE,
  output        out_mnstatus_bits_MNPV,
  output        out_mnstatus_bits_MNPELP,
  output [1:0]  out_mnstatus_bits_MNPP,
  output        out_mstatus_valid,
  output        out_mstatus_bits_SIE,
  output        out_mstatus_bits_MIE,
  output        out_mstatus_bits_SPIE,
  output        out_mstatus_bits_UBE,
  output        out_mstatus_bits_MPIE,
  output        out_mstatus_bits_SPP,
  output [1:0]  out_mstatus_bits_VS,
  output [1:0]  out_mstatus_bits_MPP,
  output [1:0]  out_mstatus_bits_FS,
  output [1:0]  out_mstatus_bits_XS,
  output        out_mstatus_bits_MPRV,
  output        out_mstatus_bits_SUM,
  output        out_mstatus_bits_MXR,
  output        out_mstatus_bits_TVM,
  output        out_mstatus_bits_TW,
  output        out_mstatus_bits_TSR,
  output        out_mstatus_bits_SDT,
  output [1:0]  out_mstatus_bits_UXL,
  output [1:0]  out_mstatus_bits_SXL,
  output        out_mstatus_bits_SBE,
  output        out_mstatus_bits_MBE,
  output        out_mstatus_bits_GVA,
  output        out_mstatus_bits_MPV,
  output        out_mstatus_bits_MDT,
  output        out_mstatus_bits_SD,
  output        out_vsstatus_valid,
  output        out_vsstatus_bits_SIE,
  output        out_vsstatus_bits_SPIE,
  output        out_vsstatus_bits_UBE,
  output        out_vsstatus_bits_SPP,
  output [1:0]  out_vsstatus_bits_VS,
  output [1:0]  out_vsstatus_bits_FS,
  output [1:0]  out_vsstatus_bits_XS,
  output        out_vsstatus_bits_SUM,
  output        out_vsstatus_bits_MXR,
  output        out_vsstatus_bits_SDT,
  output [1:0]  out_vsstatus_bits_UXL,
  output        out_vsstatus_bits_SD,
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF
);
endmodule

module SretEventModule(

  input         valid,
  input  [1:0]  in_privState_PRVM,
  input         in_privState_V,
  input         in_mstatus_SPIE,
  input         in_mstatus_SPP,
  input         in_mstatus_SDT,
  input         in_mstatus_MDT,
  input         in_hstatus_SPV,
  input         in_vsstatus_SPIE,
  input         in_vsstatus_SPP,
  input  [62:0] in_sepc_epc,
  input  [62:0] in_vsepc_epc,
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_mstatus_valid,
  output        out_mstatus_bits_SIE,
  output        out_mstatus_bits_MIE,
  output        out_mstatus_bits_SPIE,
  output        out_mstatus_bits_UBE,
  output        out_mstatus_bits_MPIE,
  output        out_mstatus_bits_SPP,
  output [1:0]  out_mstatus_bits_VS,
  output [1:0]  out_mstatus_bits_MPP,
  output [1:0]  out_mstatus_bits_FS,
  output [1:0]  out_mstatus_bits_XS,
  output        out_mstatus_bits_MPRV,
  output        out_mstatus_bits_SUM,
  output        out_mstatus_bits_MXR,
  output        out_mstatus_bits_TVM,
  output        out_mstatus_bits_TW,
  output        out_mstatus_bits_TSR,
  output        out_mstatus_bits_SDT,
  output [1:0]  out_mstatus_bits_UXL,
  output [1:0]  out_mstatus_bits_SXL,
  output        out_mstatus_bits_SBE,
  output        out_mstatus_bits_MBE,
  output        out_mstatus_bits_GVA,
  output        out_mstatus_bits_MPV,
  output        out_mstatus_bits_MDT,
  output        out_mstatus_bits_SD,
  output        out_hstatus_valid,
  output        out_hstatus_bits_VSBE,
  output        out_hstatus_bits_GVA,
  output        out_hstatus_bits_SPV,
  output        out_hstatus_bits_SPVP,
  output        out_hstatus_bits_HU,
  output [5:0]  out_hstatus_bits_VGEIN,
  output        out_hstatus_bits_VTVM,
  output        out_hstatus_bits_VTW,
  output        out_hstatus_bits_VTSR,
  output [1:0]  out_hstatus_bits_VSXL,
  output [1:0]  out_hstatus_bits_HUPMM,
  output        out_vsstatus_valid,
  output        out_vsstatus_bits_SIE,
  output        out_vsstatus_bits_SPIE,
  output        out_vsstatus_bits_UBE,
  output        out_vsstatus_bits_SPP,
  output [1:0]  out_vsstatus_bits_VS,
  output [1:0]  out_vsstatus_bits_FS,
  output [1:0]  out_vsstatus_bits_XS,
  output        out_vsstatus_bits_SUM,
  output        out_vsstatus_bits_MXR,
  output        out_vsstatus_bits_SDT,
  output [1:0]  out_vsstatus_bits_UXL,
  output        out_vsstatus_bits_SD,
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF,
  output        outSDT_vsstatus_valid
);
endmodule

module DretEventModule(

  input         valid,
  input         in_dcsr_V,
  input  [1:0]  in_dcsr_PRV,
  input  [62:0] in_dpc_epc,
  input         in_mstatus_MPRV,
  input         in_mstatus_SDT,
  input         in_mstatus_MDT,
  input         in_vsstatus_SDT,
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_dcsr_valid,
  output [3:0]  out_dcsr_bits_DEBUGVER,
  output [2:0]  out_dcsr_bits_EXTCAUSE,
  output        out_dcsr_bits_CETRIG,
  output        out_dcsr_bits_EBREAKVS,
  output        out_dcsr_bits_EBREAKVU,
  output        out_dcsr_bits_EBREAKM,
  output        out_dcsr_bits_EBREAKS,
  output        out_dcsr_bits_EBREAKU,
  output        out_dcsr_bits_STEPIE,
  output        out_dcsr_bits_STOPCOUNT,
  output        out_dcsr_bits_STOPTIME,
  output [2:0]  out_dcsr_bits_CAUSE,
  output        out_dcsr_bits_V,
  output        out_dcsr_bits_MPRVEN,
  output        out_dcsr_bits_NMIP,
  output        out_dcsr_bits_STEP,
  output [1:0]  out_dcsr_bits_PRV,
  output        out_mstatus_valid,
  output        out_mstatus_bits_SIE,
  output        out_mstatus_bits_MIE,
  output        out_mstatus_bits_SPIE,
  output        out_mstatus_bits_UBE,
  output        out_mstatus_bits_MPIE,
  output        out_mstatus_bits_SPP,
  output [1:0]  out_mstatus_bits_VS,
  output [1:0]  out_mstatus_bits_MPP,
  output [1:0]  out_mstatus_bits_FS,
  output [1:0]  out_mstatus_bits_XS,
  output        out_mstatus_bits_MPRV,
  output        out_mstatus_bits_SUM,
  output        out_mstatus_bits_MXR,
  output        out_mstatus_bits_TVM,
  output        out_mstatus_bits_TW,
  output        out_mstatus_bits_TSR,
  output        out_mstatus_bits_SDT,
  output [1:0]  out_mstatus_bits_UXL,
  output [1:0]  out_mstatus_bits_SXL,
  output        out_mstatus_bits_SBE,
  output        out_mstatus_bits_MBE,
  output        out_mstatus_bits_GVA,
  output        out_mstatus_bits_MPV,
  output        out_mstatus_bits_MDT,
  output        out_mstatus_bits_SD,
  output        out_vsstatus_valid,
  output        out_vsstatus_bits_SIE,
  output        out_vsstatus_bits_SPIE,
  output        out_vsstatus_bits_UBE,
  output        out_vsstatus_bits_SPP,
  output [1:0]  out_vsstatus_bits_VS,
  output [1:0]  out_vsstatus_bits_FS,
  output [1:0]  out_vsstatus_bits_XS,
  output        out_vsstatus_bits_SUM,
  output        out_vsstatus_bits_MXR,
  output        out_vsstatus_bits_SDT,
  output [1:0]  out_vsstatus_bits_UXL,
  output        out_vsstatus_bits_SD,
  output        out_debugMode_valid,
  output        out_debugMode_bits,
  output        out_debugIntrEnable_valid,
  output        out_debugIntrEnable_bits,
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF
);
endmodule

module TselectModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [1:0]  rdata,
  output [1:0]  regOut_ALL
);
endmodule

module Tdata1Module(

  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input  [63:0] tdataRead_tdata1
);
endmodule

module Tdata2Module(

  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input  [63:0] tdataRead_tdata2
);
endmodule

module Trigger0_Tdata1Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         canWriteDmode,
  input         chainable
);
endmodule

module Trigger1_Tdata1Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         canWriteDmode,
  input         chainable
);
endmodule

module Trigger2_Tdata1Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         canWriteDmode,
  input         chainable
);
endmodule

module Trigger3_Tdata1Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         canWriteDmode,
  input         chainable
);
endmodule

module Trigger0_Tdata2Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata
);
endmodule

module Trigger1_Tdata2Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata
);
endmodule

module Trigger2_Tdata2Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata
);
endmodule

module Trigger3_Tdata2Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata
);
endmodule

module DcsrModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [31:0] rdata,
  output        regOut_CETRIG,
  output        regOut_EBREAKVS,
  output        regOut_EBREAKVU,
  output        regOut_EBREAKM,
  output        regOut_EBREAKS,
  output        regOut_EBREAKU,
  output        regOut_STEPIE,
  output        regOut_STOPCOUNT,
  output        regOut_STOPTIME,
  output [2:0]  regOut_CAUSE,
  output        regOut_V,
  output        regOut_MPRVEN,
  output        regOut_NMIP,
  output        regOut_STEP,
  output [1:0]  regOut_PRV,
  input         trapToD_dcsr_valid,
  input  [2:0]  trapToD_dcsr_bits_CAUSE,
  input         trapToD_dcsr_bits_V,
  input  [1:0]  trapToD_dcsr_bits_PRV,
  input         retFromD_dcsr_valid,
  input         retFromD_dcsr_bits_V,
  input  [1:0]  retFromD_dcsr_bits_PRV,
  input         nmip
);
endmodule

module DpcModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [62:0] regOut_epc,
  input         trapToD_dpc_valid,
  input  [62:0] trapToD_dpc_bits_epc
);
endmodule

module Dscratch0Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL
);
endmodule

module Dscratch1Module(

  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL
);
endmodule

module SbpctlModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_LOOP_ENABLE,
  output        regOut_RAS_ENABLE,
  output        regOut_SC_ENABLE,
  output        regOut_TAGE_ENABLE,
  output        regOut_BIM_ENABLE,
  output        regOut_BTB_ENABLE,
  output        regOut_UBTB_ENABLE
);
endmodule

module SpfctlModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_L2_PF_TP_ENABLE,
  output        regOut_L2_PF_VBOP_ENABLE,
  output        regOut_L2_PF_PBOP_ENABLE,
  output        regOut_L2_PF_RECV_ENABLE,
  output        regOut_L2_PF_STORE_ONLY,
  output        regOut_L1D_PF_ENABLE_STRIDE,
  output [5:0]  regOut_L1D_PF_ACTIVE_STRIDE,
  output [3:0]  regOut_L1D_PF_ACTIVE_THRESHOLD,
  output        regOut_L1D_PF_ENABLE_PHT,
  output        regOut_L1D_PF_ENABLE_AGT,
  output        regOut_L1D_PF_TRAIN_ON_HIT,
  output        regOut_L1D_PF_ENABLE,
  output        regOut_L2_PF_ENABLE,
  output        regOut_L1I_PF_ENABLE
);
endmodule

module SlvpredctlModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [4:0]  regOut_LVPRED_TIMEOUT,
  output        regOut_STORESET_NO_FAST_WAKEUP,
  output        regOut_STORESET_WAIT_STORE,
  output        regOut_NO_SPEC_LOAD,
  output        regOut_LVPRED_DISABLE
);
endmodule

module SmblockctlModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_HD_MISALIGN_LD_ENABLE,
  output        regOut_HD_MISALIGN_ST_ENABLE,
  output        regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE,
  output        regOut_CACHE_ERROR_ENABLE,
  output        regOut_SOFT_PREFETCH_ENABLE,
  output        regOut_LDLD_VIO_CHECK_ENABLE,
  output [3:0]  regOut_SBUFFER_THRESHOLD
);
endmodule

module SrnctlModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_WFI_ENABLE,
  output        regOut_FUSION_ENABLE
);
endmodule

module McorepwrModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_POWER_DOWN_ENABLE
);
endmodule

module MflushpwrModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_FLUSH_L2_ENABLE,
  output        regOut_L2_FLUSH_DONE,
  input         l2FlushDone
);
endmodule

module Pmpcfg0Module(

  output [63:0]  rdata,
  output [63:0]  regOut_ALL,
  input  [127:0] cfgRData
);
endmodule

module Pmpcfg2Module(

  output [63:0]  rdata,
  output [63:0]  regOut_ALL,
  input  [127:0] cfgRData
);
endmodule

module Pmp0cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
endmodule

module Pmp1cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
endmodule

module Pmp2cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
endmodule

module Pmp3cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
endmodule

module Pmp4cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
endmodule

module Pmp5cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
endmodule

module Pmp6cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
endmodule

module Pmp7cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
endmodule

module Pmp8cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
endmodule

module Pmp9cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
endmodule

module Pmp10cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
endmodule

module Pmp11cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
endmodule

module Pmp12cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
endmodule

module Pmp13cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
endmodule

module Pmp14cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
endmodule

module Pmp15cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
endmodule

module Pmpaddr0Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_0
);
endmodule

module Pmpaddr1Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_1
);
endmodule

module Pmpaddr2Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_2
);
endmodule

module Pmpaddr3Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_3
);
endmodule

module Pmpaddr4Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_4
);
endmodule

module Pmpaddr5Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_5
);
endmodule

module Pmpaddr6Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_6
);
endmodule

module Pmpaddr7Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_7
);
endmodule

module Pmpaddr8Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_8
);
endmodule

module Pmpaddr9Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_9
);
endmodule

module Pmpaddr10Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_10
);
endmodule

module Pmpaddr11Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_11
);
endmodule

module Pmpaddr12Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_12
);
endmodule

module Pmpaddr13Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_13
);
endmodule

module Pmpaddr14Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_14
);
endmodule

module Pmpaddr15Module(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_15
);
endmodule

module Pmacfg0Module(

  output [63:0]  rdata,
  input  [127:0] cfgRData
);
endmodule

module Pmacfg2Module(

  output [63:0]  rdata,
  input  [127:0] cfgRData
);
endmodule

module Pma0cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_ATOMIC,
  output        regOut_C,
  output        regOut_L
);
endmodule

module Pma1cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_ATOMIC,
  output        regOut_C,
  output        regOut_L
);
endmodule

module Pma2cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_ATOMIC,
  output        regOut_C,
  output        regOut_L
);
endmodule

module Pma3cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_ATOMIC,
  output        regOut_C,
  output        regOut_L
);
endmodule

module Pma4cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_ATOMIC,
  output        regOut_C,
  output        regOut_L
);
endmodule

module Pma5cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_ATOMIC,
  output        regOut_C,
  output        regOut_L
);
endmodule

module Pma6cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_ATOMIC,
  output        regOut_C,
  output        regOut_L
);
endmodule

module Pma7cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_ATOMIC,
  output        regOut_C,
  output        regOut_L
);
endmodule

module Pma8cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_ATOMIC,
  output        regOut_C,
  output        regOut_L
);
endmodule

module Pma9cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_ATOMIC,
  output        regOut_C,
  output        regOut_L
);
endmodule

module Pma10cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_ATOMIC,
  output        regOut_C,
  output        regOut_L
);
endmodule

module Pma11cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_ATOMIC,
  output        regOut_C,
  output        regOut_L
);
endmodule

module Pma12cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_ATOMIC,
  output        regOut_C,
  output        regOut_L
);
endmodule

module Pma13cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_ATOMIC,
  output        regOut_C,
  output        regOut_L
);
endmodule

module Pma14cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_ATOMIC,
  output        regOut_C,
  output        regOut_L
);
endmodule

module Pma15cfgModule(

  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_ATOMIC,
  output        regOut_C,
  output        regOut_L
);
endmodule

module Pmaaddr0Module(

  output [63:0] rdata,
  input  [63:0] addrRData_0
);
endmodule

module Pmaaddr1Module(

  output [63:0] rdata,
  input  [63:0] addrRData_1
);
endmodule

module Pmaaddr2Module(

  output [63:0] rdata,
  input  [63:0] addrRData_2
);
endmodule

module Pmaaddr3Module(

  output [63:0] rdata,
  input  [63:0] addrRData_3
);
endmodule

module Pmaaddr4Module(

  output [63:0] rdata,
  input  [63:0] addrRData_4
);
endmodule

module Pmaaddr5Module(

  output [63:0] rdata,
  input  [63:0] addrRData_5
);
endmodule

module Pmaaddr6Module(

  output [63:0] rdata,
  input  [63:0] addrRData_6
);
endmodule

module Pmaaddr7Module(

  output [63:0] rdata,
  input  [63:0] addrRData_7
);
endmodule

module Pmaaddr8Module(

  output [63:0] rdata,
  input  [63:0] addrRData_8
);
endmodule

module Pmaaddr9Module(

  output [63:0] rdata,
  input  [63:0] addrRData_9
);
endmodule

module Pmaaddr10Module(

  output [63:0] rdata,
  input  [63:0] addrRData_10
);
endmodule

module Pmaaddr11Module(

  output [63:0] rdata,
  input  [63:0] addrRData_11
);
endmodule

module Pmaaddr12Module(

  output [63:0] rdata,
  input  [63:0] addrRData_12
);
endmodule

module Pmaaddr13Module(

  output [63:0] rdata,
  input  [63:0] addrRData_13
);
endmodule

module Pmaaddr14Module(

  output [63:0] rdata,
  input  [63:0] addrRData_14
);
endmodule

module Pmaaddr15Module(

  output [63:0] rdata,
  input  [63:0] addrRData_15
);
endmodule

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
endmodule

module SstcInterruptGen(

  input         clock,
  input         reset,
  input         i_stime_valid,
  input  [63:0] i_stime_bits,
  input         i_vstime_valid,
  input  [63:0] i_vstime_bits,
  input         i_stimecmp_wen,
  input  [63:0] i_stimecmp_rdata,
  input         i_vstimecmp_wen,
  input  [63:0] i_vstimecmp_rdata,
  input         i_htimedeltaWen,
  input         i_menvcfg_wen,
  input         i_menvcfg_STCE,
  input         i_henvcfg_wen,
  input         i_henvcfg_STCE,
  output        o_STIP,
  output        o_VSTIP
);
endmodule

module CommitIDModule(

  input [5:0] io_hartId
);
endmodule

module InterruptFilter(

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
endmodule

module TrapHandleModule(

  input         io_in_trapInfo_valid,
  input  [63:0] io_in_trapInfo_bits_trapVec,
  input         io_in_trapInfo_bits_nmi,
  input  [7:0]  io_in_trapInfo_bits_intrVec,
  input         io_in_trapInfo_bits_isInterrupt,
  input         io_in_trapInfo_bits_singleStep,
  input         io_in_trapInfo_bits_irToHS,
  input         io_in_trapInfo_bits_irToVS,
  input  [1:0]  io_in_privState_PRVM,
  input         io_in_privState_V,
  input         io_in_mstatus_SDT,
  input         io_in_mstatus_MDT,
  input         io_in_vsstatus_SDT,
  input         io_in_mnstatus_NMIE,
  input         io_in_medeleg_EX_IAM,
  input         io_in_medeleg_EX_IAF,
  input         io_in_medeleg_EX_II,
  input         io_in_medeleg_EX_BP,
  input         io_in_medeleg_EX_LAM,
  input         io_in_medeleg_EX_LAF,
  input         io_in_medeleg_EX_SAM,
  input         io_in_medeleg_EX_SAF,
  input         io_in_medeleg_EX_UCALL,
  input         io_in_medeleg_EX_HSCALL,
  input         io_in_medeleg_EX_VSCALL,
  input         io_in_medeleg_EX_IPF,
  input         io_in_medeleg_EX_LPF,
  input         io_in_medeleg_EX_SPF,
  input         io_in_medeleg_EX_SWC,
  input         io_in_medeleg_EX_HWE,
  input         io_in_medeleg_EX_IGPF,
  input         io_in_medeleg_EX_LGPF,
  input         io_in_medeleg_EX_VI,
  input         io_in_medeleg_EX_SGPF,
  input         io_in_hedeleg_EX_IAM,
  input         io_in_hedeleg_EX_IAF,
  input         io_in_hedeleg_EX_II,
  input         io_in_hedeleg_EX_BP,
  input         io_in_hedeleg_EX_LAM,
  input         io_in_hedeleg_EX_LAF,
  input         io_in_hedeleg_EX_SAM,
  input         io_in_hedeleg_EX_SAF,
  input         io_in_hedeleg_EX_UCALL,
  input         io_in_hedeleg_EX_IPF,
  input         io_in_hedeleg_EX_LPF,
  input         io_in_hedeleg_EX_SPF,
  input         io_in_hedeleg_EX_SWC,
  input         io_in_hedeleg_EX_HWE,
  input  [1:0]  io_in_mtvec_mode,
  input  [61:0] io_in_mtvec_addr,
  input  [1:0]  io_in_stvec_mode,
  input  [61:0] io_in_stvec_addr,
  input  [1:0]  io_in_vstvec_mode,
  input  [61:0] io_in_vstvec_addr,
  output [1:0]  io_out_entryPrivState_PRVM,
  output        io_out_entryPrivState_V,
  output        io_out_causeNO_Interrupt,
  output [62:0] io_out_causeNO_ExceptionCode,
  output        io_out_dbltrpToMN,
  output        io_out_hasDTExcp,
  output [63:0] io_out_pcFromXtvec
);
endmodule

module PMPEntryHandleModule(

  input         io_in_wen,
  input         io_in_ren,
  input  [11:0] io_in_addr,
  input  [63:0] io_in_wdata,
  input         io_in_pmpCfg_0_R,
  input         io_in_pmpCfg_0_W,
  input         io_in_pmpCfg_0_X,
  input  [1:0]  io_in_pmpCfg_0_A,
  input         io_in_pmpCfg_0_L,
  input         io_in_pmpCfg_1_R,
  input         io_in_pmpCfg_1_W,
  input         io_in_pmpCfg_1_X,
  input  [1:0]  io_in_pmpCfg_1_A,
  input         io_in_pmpCfg_1_L,
  input         io_in_pmpCfg_2_R,
  input         io_in_pmpCfg_2_W,
  input         io_in_pmpCfg_2_X,
  input  [1:0]  io_in_pmpCfg_2_A,
  input         io_in_pmpCfg_2_L,
  input         io_in_pmpCfg_3_R,
  input         io_in_pmpCfg_3_W,
  input         io_in_pmpCfg_3_X,
  input  [1:0]  io_in_pmpCfg_3_A,
  input         io_in_pmpCfg_3_L,
  input         io_in_pmpCfg_4_R,
  input         io_in_pmpCfg_4_W,
  input         io_in_pmpCfg_4_X,
  input  [1:0]  io_in_pmpCfg_4_A,
  input         io_in_pmpCfg_4_L,
  input         io_in_pmpCfg_5_R,
  input         io_in_pmpCfg_5_W,
  input         io_in_pmpCfg_5_X,
  input  [1:0]  io_in_pmpCfg_5_A,
  input         io_in_pmpCfg_5_L,
  input         io_in_pmpCfg_6_R,
  input         io_in_pmpCfg_6_W,
  input         io_in_pmpCfg_6_X,
  input  [1:0]  io_in_pmpCfg_6_A,
  input         io_in_pmpCfg_6_L,
  input         io_in_pmpCfg_7_R,
  input         io_in_pmpCfg_7_W,
  input         io_in_pmpCfg_7_X,
  input  [1:0]  io_in_pmpCfg_7_A,
  input         io_in_pmpCfg_7_L,
  input         io_in_pmpCfg_8_R,
  input         io_in_pmpCfg_8_W,
  input         io_in_pmpCfg_8_X,
  input  [1:0]  io_in_pmpCfg_8_A,
  input         io_in_pmpCfg_8_L,
  input         io_in_pmpCfg_9_R,
  input         io_in_pmpCfg_9_W,
  input         io_in_pmpCfg_9_X,
  input  [1:0]  io_in_pmpCfg_9_A,
  input         io_in_pmpCfg_9_L,
  input         io_in_pmpCfg_10_R,
  input         io_in_pmpCfg_10_W,
  input         io_in_pmpCfg_10_X,
  input  [1:0]  io_in_pmpCfg_10_A,
  input         io_in_pmpCfg_10_L,
  input         io_in_pmpCfg_11_R,
  input         io_in_pmpCfg_11_W,
  input         io_in_pmpCfg_11_X,
  input  [1:0]  io_in_pmpCfg_11_A,
  input         io_in_pmpCfg_11_L,
  input         io_in_pmpCfg_12_R,
  input         io_in_pmpCfg_12_W,
  input         io_in_pmpCfg_12_X,
  input  [1:0]  io_in_pmpCfg_12_A,
  input         io_in_pmpCfg_12_L,
  input         io_in_pmpCfg_13_R,
  input         io_in_pmpCfg_13_W,
  input         io_in_pmpCfg_13_X,
  input  [1:0]  io_in_pmpCfg_13_A,
  input         io_in_pmpCfg_13_L,
  input         io_in_pmpCfg_14_R,
  input         io_in_pmpCfg_14_W,
  input         io_in_pmpCfg_14_X,
  input  [1:0]  io_in_pmpCfg_14_A,
  input         io_in_pmpCfg_14_L,
  input         io_in_pmpCfg_15_R,
  input         io_in_pmpCfg_15_W,
  input         io_in_pmpCfg_15_X,
  input  [1:0]  io_in_pmpCfg_15_A,
  input         io_in_pmpCfg_15_L,
  input  [45:0] io_in_pmpAddr_0_ADDRESS,
  input  [45:0] io_in_pmpAddr_1_ADDRESS,
  input  [45:0] io_in_pmpAddr_2_ADDRESS,
  input  [45:0] io_in_pmpAddr_3_ADDRESS,
  input  [45:0] io_in_pmpAddr_4_ADDRESS,
  input  [45:0] io_in_pmpAddr_5_ADDRESS,
  input  [45:0] io_in_pmpAddr_6_ADDRESS,
  input  [45:0] io_in_pmpAddr_7_ADDRESS,
  input  [45:0] io_in_pmpAddr_8_ADDRESS,
  input  [45:0] io_in_pmpAddr_9_ADDRESS,
  input  [45:0] io_in_pmpAddr_10_ADDRESS,
  input  [45:0] io_in_pmpAddr_11_ADDRESS,
  input  [45:0] io_in_pmpAddr_12_ADDRESS,
  input  [45:0] io_in_pmpAddr_13_ADDRESS,
  input  [45:0] io_in_pmpAddr_14_ADDRESS,
  input  [45:0] io_in_pmpAddr_15_ADDRESS,
  output [63:0] io_out_pmpCfgWData,
  output [63:0] io_out_pmpAddrRData_0,
  output [63:0] io_out_pmpAddrRData_1,
  output [63:0] io_out_pmpAddrRData_2,
  output [63:0] io_out_pmpAddrRData_3,
  output [63:0] io_out_pmpAddrRData_4,
  output [63:0] io_out_pmpAddrRData_5,
  output [63:0] io_out_pmpAddrRData_6,
  output [63:0] io_out_pmpAddrRData_7,
  output [63:0] io_out_pmpAddrRData_8,
  output [63:0] io_out_pmpAddrRData_9,
  output [63:0] io_out_pmpAddrRData_10,
  output [63:0] io_out_pmpAddrRData_11,
  output [63:0] io_out_pmpAddrRData_12,
  output [63:0] io_out_pmpAddrRData_13,
  output [63:0] io_out_pmpAddrRData_14,
  output [63:0] io_out_pmpAddrRData_15,
  output [63:0] io_out_pmpAddrWData_0,
  output [63:0] io_out_pmpAddrWData_1,
  output [63:0] io_out_pmpAddrWData_2,
  output [63:0] io_out_pmpAddrWData_3,
  output [63:0] io_out_pmpAddrWData_4,
  output [63:0] io_out_pmpAddrWData_5,
  output [63:0] io_out_pmpAddrWData_6,
  output [63:0] io_out_pmpAddrWData_7,
  output [63:0] io_out_pmpAddrWData_8,
  output [63:0] io_out_pmpAddrWData_9,
  output [63:0] io_out_pmpAddrWData_10,
  output [63:0] io_out_pmpAddrWData_11,
  output [63:0] io_out_pmpAddrWData_12,
  output [63:0] io_out_pmpAddrWData_13,
  output [63:0] io_out_pmpAddrWData_14,
  output [63:0] io_out_pmpAddrWData_15
);
endmodule

module PMAEntryHandleModule(

  input         clock,
  input         reset,
  input         io_in_wen,
  input         io_in_ren,
  input  [11:0] io_in_addr,
  input  [63:0] io_in_wdata,
  input         io_in_pmaCfg_0_R,
  input         io_in_pmaCfg_0_W,
  input         io_in_pmaCfg_0_X,
  input  [1:0]  io_in_pmaCfg_0_A,
  input         io_in_pmaCfg_0_L,
  input         io_in_pmaCfg_0_ATOMIC,
  input         io_in_pmaCfg_0_C,
  input         io_in_pmaCfg_1_R,
  input         io_in_pmaCfg_1_W,
  input         io_in_pmaCfg_1_X,
  input  [1:0]  io_in_pmaCfg_1_A,
  input         io_in_pmaCfg_1_L,
  input         io_in_pmaCfg_1_ATOMIC,
  input         io_in_pmaCfg_1_C,
  input         io_in_pmaCfg_2_R,
  input         io_in_pmaCfg_2_W,
  input         io_in_pmaCfg_2_X,
  input  [1:0]  io_in_pmaCfg_2_A,
  input         io_in_pmaCfg_2_L,
  input         io_in_pmaCfg_2_ATOMIC,
  input         io_in_pmaCfg_2_C,
  input         io_in_pmaCfg_3_R,
  input         io_in_pmaCfg_3_W,
  input         io_in_pmaCfg_3_X,
  input  [1:0]  io_in_pmaCfg_3_A,
  input         io_in_pmaCfg_3_L,
  input         io_in_pmaCfg_3_ATOMIC,
  input         io_in_pmaCfg_3_C,
  input         io_in_pmaCfg_4_R,
  input         io_in_pmaCfg_4_W,
  input         io_in_pmaCfg_4_X,
  input  [1:0]  io_in_pmaCfg_4_A,
  input         io_in_pmaCfg_4_L,
  input         io_in_pmaCfg_4_ATOMIC,
  input         io_in_pmaCfg_4_C,
  input         io_in_pmaCfg_5_R,
  input         io_in_pmaCfg_5_W,
  input         io_in_pmaCfg_5_X,
  input  [1:0]  io_in_pmaCfg_5_A,
  input         io_in_pmaCfg_5_L,
  input         io_in_pmaCfg_5_ATOMIC,
  input         io_in_pmaCfg_5_C,
  input         io_in_pmaCfg_6_R,
  input         io_in_pmaCfg_6_W,
  input         io_in_pmaCfg_6_X,
  input  [1:0]  io_in_pmaCfg_6_A,
  input         io_in_pmaCfg_6_L,
  input         io_in_pmaCfg_6_ATOMIC,
  input         io_in_pmaCfg_6_C,
  input         io_in_pmaCfg_7_R,
  input         io_in_pmaCfg_7_W,
  input         io_in_pmaCfg_7_X,
  input  [1:0]  io_in_pmaCfg_7_A,
  input         io_in_pmaCfg_7_L,
  input         io_in_pmaCfg_7_ATOMIC,
  input         io_in_pmaCfg_7_C,
  input         io_in_pmaCfg_8_R,
  input         io_in_pmaCfg_8_W,
  input         io_in_pmaCfg_8_X,
  input  [1:0]  io_in_pmaCfg_8_A,
  input         io_in_pmaCfg_8_L,
  input         io_in_pmaCfg_8_ATOMIC,
  input         io_in_pmaCfg_8_C,
  input         io_in_pmaCfg_9_R,
  input         io_in_pmaCfg_9_W,
  input         io_in_pmaCfg_9_X,
  input  [1:0]  io_in_pmaCfg_9_A,
  input         io_in_pmaCfg_9_L,
  input         io_in_pmaCfg_9_ATOMIC,
  input         io_in_pmaCfg_9_C,
  input         io_in_pmaCfg_10_R,
  input         io_in_pmaCfg_10_W,
  input         io_in_pmaCfg_10_X,
  input  [1:0]  io_in_pmaCfg_10_A,
  input         io_in_pmaCfg_10_L,
  input         io_in_pmaCfg_10_ATOMIC,
  input         io_in_pmaCfg_10_C,
  input         io_in_pmaCfg_11_R,
  input         io_in_pmaCfg_11_W,
  input         io_in_pmaCfg_11_X,
  input  [1:0]  io_in_pmaCfg_11_A,
  input         io_in_pmaCfg_11_L,
  input         io_in_pmaCfg_11_ATOMIC,
  input         io_in_pmaCfg_11_C,
  input         io_in_pmaCfg_12_R,
  input         io_in_pmaCfg_12_W,
  input         io_in_pmaCfg_12_X,
  input  [1:0]  io_in_pmaCfg_12_A,
  input         io_in_pmaCfg_12_L,
  input         io_in_pmaCfg_12_ATOMIC,
  input         io_in_pmaCfg_12_C,
  input         io_in_pmaCfg_13_R,
  input         io_in_pmaCfg_13_W,
  input         io_in_pmaCfg_13_X,
  input  [1:0]  io_in_pmaCfg_13_A,
  input         io_in_pmaCfg_13_L,
  input         io_in_pmaCfg_13_ATOMIC,
  input         io_in_pmaCfg_13_C,
  input         io_in_pmaCfg_14_R,
  input         io_in_pmaCfg_14_W,
  input         io_in_pmaCfg_14_X,
  input  [1:0]  io_in_pmaCfg_14_A,
  input         io_in_pmaCfg_14_L,
  input         io_in_pmaCfg_14_ATOMIC,
  input         io_in_pmaCfg_14_C,
  input         io_in_pmaCfg_15_R,
  input         io_in_pmaCfg_15_W,
  input         io_in_pmaCfg_15_X,
  input  [1:0]  io_in_pmaCfg_15_A,
  input         io_in_pmaCfg_15_L,
  input         io_in_pmaCfg_15_ATOMIC,
  input         io_in_pmaCfg_15_C,
  output [63:0] io_out_pmaCfgWdata,
  output [63:0] io_out_pmaAddrRData_0,
  output [63:0] io_out_pmaAddrRData_1,
  output [63:0] io_out_pmaAddrRData_2,
  output [63:0] io_out_pmaAddrRData_3,
  output [63:0] io_out_pmaAddrRData_4,
  output [63:0] io_out_pmaAddrRData_5,
  output [63:0] io_out_pmaAddrRData_6,
  output [63:0] io_out_pmaAddrRData_7,
  output [63:0] io_out_pmaAddrRData_8,
  output [63:0] io_out_pmaAddrRData_9,
  output [63:0] io_out_pmaAddrRData_10,
  output [63:0] io_out_pmaAddrRData_11,
  output [63:0] io_out_pmaAddrRData_12,
  output [63:0] io_out_pmaAddrRData_13,
  output [63:0] io_out_pmaAddrRData_14,
  output [63:0] io_out_pmaAddrRData_15
);
endmodule

module Debug(

  input         clock,
  input         io_in_trapInfo_valid,
  input  [63:0] io_in_trapInfo_bits_trapVec,
  input         io_in_trapInfo_bits_isDebugIntr,
  input         io_in_trapInfo_bits_isInterrupt,
  input         io_in_trapInfo_bits_singleStep,
  input  [3:0]  io_in_trapInfo_bits_trigger,
  input         io_in_trapInfo_bits_criticalErrorState,
  input  [1:0]  io_in_privState_PRVM,
  input         io_in_privState_V,
  input         io_in_debugMode,
  input         io_in_dcsr_CETRIG,
  input         io_in_dcsr_EBREAKVS,
  input         io_in_dcsr_EBREAKVU,
  input         io_in_dcsr_EBREAKM,
  input         io_in_dcsr_EBREAKS,
  input         io_in_dcsr_EBREAKU,
  input  [1:0]  io_in_tselect_ALL,
  input  [58:0] io_in_tdata1Selected_DATA,
  input  [63:0] io_in_tdata2Selected_ALL,
  input  [3:0]  io_in_tdata1Vec_0_TYPE,
  input  [58:0] io_in_tdata1Vec_0_DATA,
  input  [3:0]  io_in_tdata1Vec_1_TYPE,
  input  [58:0] io_in_tdata1Vec_1_DATA,
  input  [3:0]  io_in_tdata1Vec_2_TYPE,
  input  [58:0] io_in_tdata1Vec_2_DATA,
  input  [3:0]  io_in_tdata1Vec_3_TYPE,
  input  [58:0] io_in_tdata1Vec_3_DATA,
  input         io_in_triggerCanRaiseBpExp,
  input         io_in_tdata1Update,
  input         io_in_tdata2Update,
  input  [3:0]  io_in_tdata1Wdata_TYPE,
  input  [58:0] io_in_tdata1Wdata_DATA,
  output        io_out_triggerFrontendChange,
  output        io_out_newTriggerChainIsLegal,
  output        io_out_memTrigger_tUpdate_valid,
  output [1:0]  io_out_memTrigger_tUpdate_bits_addr,
  output [1:0]  io_out_memTrigger_tUpdate_bits_tdata_matchType,
  output        io_out_memTrigger_tUpdate_bits_tdata_select,
  output [3:0]  io_out_memTrigger_tUpdate_bits_tdata_action,
  output        io_out_memTrigger_tUpdate_bits_tdata_chain,
  output        io_out_memTrigger_tUpdate_bits_tdata_store,
  output        io_out_memTrigger_tUpdate_bits_tdata_load,
  output [63:0] io_out_memTrigger_tUpdate_bits_tdata_tdata2,
  output        io_out_memTrigger_tEnableVec_0,
  output        io_out_memTrigger_tEnableVec_1,
  output        io_out_memTrigger_tEnableVec_2,
  output        io_out_memTrigger_tEnableVec_3,
  output        io_out_memTrigger_debugMode,
  output        io_out_memTrigger_triggerCanRaiseBpExp,
  output        io_out_frontendTrigger_tUpdate_valid,
  output [1:0]  io_out_frontendTrigger_tUpdate_bits_addr,
  output [1:0]  io_out_frontendTrigger_tUpdate_bits_tdata_matchType,
  output        io_out_frontendTrigger_tUpdate_bits_tdata_select,
  output [3:0]  io_out_frontendTrigger_tUpdate_bits_tdata_action,
  output        io_out_frontendTrigger_tUpdate_bits_tdata_chain,
  output [63:0] io_out_frontendTrigger_tUpdate_bits_tdata_tdata2,
  output        io_out_frontendTrigger_tEnableVec_0,
  output        io_out_frontendTrigger_tEnableVec_1,
  output        io_out_frontendTrigger_tEnableVec_2,
  output        io_out_frontendTrigger_tEnableVec_3,
  output        io_out_frontendTrigger_debugMode,
  output        io_out_frontendTrigger_triggerCanRaiseBpExp,
  output        io_out_hasDebugTrap,
  output        io_out_hasDebugIntr,
  output        io_out_hasSingleStep,
  output        io_out_triggerEnterDebugMode,
  output        io_out_hasDebugEbreakException,
  output        io_out_breakPoint,
  output        io_out_criticalErrorStateEnterDebug
);
endmodule

module HPerfMonitor_1(

  input         clock,
  input  [63:0] io_hpm_event_0,
  input  [63:0] io_hpm_event_1,
  input  [63:0] io_hpm_event_2,
  input  [63:0] io_hpm_event_3,
  input  [63:0] io_hpm_event_4,
  input  [5:0]  io_events_sets_0_value,
  input  [5:0]  io_events_sets_1_value,
  input  [5:0]  io_events_sets_2_value,
  input  [5:0]  io_events_sets_3_value,
  input  [5:0]  io_events_sets_4_value,
  input  [5:0]  io_events_sets_5_value,
  input  [5:0]  io_events_sets_6_value,
  input  [5:0]  io_events_sets_7_value,
  input  [5:0]  io_events_sets_8_value,
  input  [5:0]  io_events_sets_9_value,
  input  [5:0]  io_events_sets_10_value,
  input  [5:0]  io_events_sets_11_value,
  input  [5:0]  io_events_sets_12_value,
  input  [5:0]  io_events_sets_13_value,
  input  [5:0]  io_events_sets_14_value,
  input  [5:0]  io_events_sets_15_value,
  input  [5:0]  io_events_sets_16_value,
  input  [5:0]  io_events_sets_17_value,
  input  [5:0]  io_events_sets_18_value,
  input  [5:0]  io_events_sets_19_value,
  input  [5:0]  io_events_sets_20_value,
  input  [5:0]  io_events_sets_21_value,
  input  [5:0]  io_events_sets_22_value,
  input  [5:0]  io_events_sets_23_value,
  input  [5:0]  io_events_sets_24_value,
  input  [5:0]  io_events_sets_25_value,
  input  [5:0]  io_events_sets_26_value,
  input  [5:0]  io_events_sets_27_value,
  input  [5:0]  io_events_sets_28_value,
  input  [5:0]  io_events_sets_29_value,
  input  [5:0]  io_events_sets_30_value,
  input  [5:0]  io_events_sets_31_value,
  input  [5:0]  io_events_sets_32_value,
  input  [5:0]  io_events_sets_33_value,
  input  [5:0]  io_events_sets_34_value,
  input  [5:0]  io_events_sets_35_value,
  input  [5:0]  io_events_sets_36_value,
  input  [5:0]  io_events_sets_37_value,
  input  [5:0]  io_events_sets_38_value,
  input  [5:0]  io_events_sets_39_value,
  input  [5:0]  io_events_sets_40_value,
  input  [5:0]  io_events_sets_41_value,
  input  [5:0]  io_events_sets_42_value,
  input  [5:0]  io_events_sets_43_value,
  input  [5:0]  io_events_sets_44_value,
  input  [5:0]  io_events_sets_45_value,
  input  [5:0]  io_events_sets_46_value,
  input  [5:0]  io_events_sets_47_value,
  output [5:0]  io_perf_0_value,
  output [5:0]  io_perf_1_value,
  output [5:0]  io_perf_2_value,
  output [5:0]  io_perf_3_value,
  output [5:0]  io_perf_4_value
);
endmodule

module DelayReg_11(

  input         clock,
  input         reset,
  input         i_valid,
  input  [31:0] i_interrupt,
  input  [31:0] i_exception,
  input  [63:0] i_exceptionPC,
  input         i_hasNMI,
  input         i_virtualInterruptIsHvictlInject,
  input         i_irToHS,
  input         i_irToVS,
  input  [7:0]  i_coreid,
  output        o_valid,
  output [31:0] o_interrupt,
  output [31:0] o_exception,
  output [63:0] o_exceptionPC,
  output        o_hasNMI,
  output        o_virtualInterruptIsHvictlInject,
  output        o_irToHS,
  output        o_irToVS,
  output [7:0]  o_coreid
);
endmodule

module DummyDPICWrapper_12(

  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [31:0] io_bits_interrupt,
  input [31:0] io_bits_exception,
  input [63:0] io_bits_exceptionPC,
  input        io_bits_hasNMI,
  input        io_bits_virtualInterruptIsHvictlInject,
  input        io_bits_irToHS,
  input        io_bits_irToVS,
  input [7:0]  io_bits_coreid
);
endmodule

module DelayReg_12(

  input        clock,
  input        reset,
  input        i_valid,
  input        i_criticalError,
  input  [7:0] i_coreid,
  output       o_valid,
  output       o_criticalError,
  output [7:0] o_coreid
);
endmodule

module DummyDPICWrapper_13(

  input       clock,
  input       io_valid,
  input       io_bits_valid,
  input       io_bits_criticalError,
  input [7:0] io_bits_coreid
);
endmodule

module DummyDPICWrapper_14(

  input        clock,
  input [63:0] io_bits_privilegeMode,
  input [63:0] io_bits_mstatus,
  input [63:0] io_bits_sstatus,
  input [63:0] io_bits_mepc,
  input [63:0] io_bits_sepc,
  input [63:0] io_bits_mtval,
  input [63:0] io_bits_stval,
  input [63:0] io_bits_mtvec,
  input [63:0] io_bits_stvec,
  input [63:0] io_bits_mcause,
  input [63:0] io_bits_scause,
  input [63:0] io_bits_satp,
  input [63:0] io_bits_mip,
  input [63:0] io_bits_mie,
  input [63:0] io_bits_mscratch,
  input [63:0] io_bits_sscratch,
  input [63:0] io_bits_mideleg,
  input [63:0] io_bits_medeleg,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_15(

  input        clock,
  input        io_bits_debugMode,
  input [63:0] io_bits_dcsr,
  input [63:0] io_bits_dpc,
  input [63:0] io_bits_dscratch0,
  input [63:0] io_bits_dscratch1,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_16(

  input        clock,
  input [63:0] io_bits_tselect,
  input [63:0] io_bits_tdata1,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_17(

  input        clock,
  input [63:0] io_bits_vstart,
  input [63:0] io_bits_vxsat,
  input [63:0] io_bits_vxrm,
  input [63:0] io_bits_vcsr,
  input [63:0] io_bits_vl,
  input [63:0] io_bits_vtype,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_18(

  input        clock,
  input [63:0] io_bits_fcsr,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_19(

  input        clock,
  input [63:0] io_bits_virtMode,
  input [63:0] io_bits_mtval2,
  input [63:0] io_bits_mtinst,
  input [63:0] io_bits_hstatus,
  input [63:0] io_bits_hideleg,
  input [63:0] io_bits_hedeleg,
  input [63:0] io_bits_hcounteren,
  input [63:0] io_bits_htval,
  input [63:0] io_bits_htinst,
  input [63:0] io_bits_hgatp,
  input [63:0] io_bits_vsstatus,
  input [63:0] io_bits_vstvec,
  input [63:0] io_bits_vsepc,
  input [63:0] io_bits_vscause,
  input [63:0] io_bits_vstval,
  input [63:0] io_bits_vsatp,
  input [63:0] io_bits_vsscratch,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_20(

  input       clock,
  input       io_valid,
  input       io_bits_valid,
  input       io_bits_platformIRPMeip,
  input       io_bits_platformIRPMtip,
  input       io_bits_platformIRPMsip,
  input       io_bits_platformIRPSeip,
  input       io_bits_platformIRPStip,
  input       io_bits_platformIRPVseip,
  input       io_bits_platformIRPVstip,
  input       io_bits_fromAIAMeip,
  input       io_bits_fromAIASeip,
  input       io_bits_localCounterOverflowInterruptReq,
  input [7:0] io_bits_coreid
);
endmodule

module DummyDPICWrapper_21(

  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [63:0] io_bits_mhpmeventOverflow,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_22(

  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [63:0] io_bits_mtopei,
  input [63:0] io_bits_stopei,
  input [63:0] io_bits_vstopei,
  input [63:0] io_bits_hgeip,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_23(

  input       clock,
  input       io_valid,
  input       io_bits_valid,
  input       io_bits_l2FlushDone,
  input [7:0] io_bits_coreid
);
endmodule
