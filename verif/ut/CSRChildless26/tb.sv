// Aggregate differential UT: G1 golden versus generated childless wrappers.
`timescale 1ns/1ps
module tb;
  logic clock = 1'b0;
  logic reset = 1'b1;
  integer errors = 0;
  integer cycle = 0;
  integer ncycles = 200000;
  always #1 clock = ~clock;
  initial void'($value$plusargs("ncycles=%d", ncycles));

  // Mgtu
  logic [127:0] Mgtu_io_in_vd;
  logic [7:0]   Mgtu_io_in_vl;
  logic [127:0] Mgtu_io_out_vd;
  logic [127:0] Mgtu_g_io_out_vd;
  logic [127:0] Mgtu_i_io_out_vd;
  Mgtu u_Mgtu_g (
    .io_in_vd(Mgtu_io_in_vd),
    .io_in_vl(Mgtu_io_in_vl),
    .io_out_vd(Mgtu_g_io_out_vd)
  );
  Mgtu_xs u_Mgtu_i (
    .io_in_vd(Mgtu_io_in_vd),
    .io_in_vl(Mgtu_io_in_vl),
    .io_out_vd(Mgtu_i_io_out_vd)
  );

  // MidelegModule
  logic MidelegModule_w_wen;
  logic [63:0] MidelegModule_w_wdata;
  logic [63:0] MidelegModule_rdata;
  logic MidelegModule_regOut_SSI;
  logic MidelegModule_regOut_STI;
  logic MidelegModule_regOut_SEI;
  logic MidelegModule_regOut_LCOFI;
  logic [63:0] MidelegModule_g_rdata;
  logic [63:0] MidelegModule_i_rdata;
  logic MidelegModule_g_regOut_SSI;
  logic MidelegModule_i_regOut_SSI;
  logic MidelegModule_g_regOut_STI;
  logic MidelegModule_i_regOut_STI;
  logic MidelegModule_g_regOut_SEI;
  logic MidelegModule_i_regOut_SEI;
  logic MidelegModule_g_regOut_LCOFI;
  logic MidelegModule_i_regOut_LCOFI;
  MidelegModule u_MidelegModule_g (
    .clock(clock),
    .reset(reset),
    .w_wen(MidelegModule_w_wen),
    .w_wdata(MidelegModule_w_wdata),
    .rdata(MidelegModule_g_rdata),
    .regOut_SSI(MidelegModule_g_regOut_SSI),
    .regOut_STI(MidelegModule_g_regOut_STI),
    .regOut_SEI(MidelegModule_g_regOut_SEI),
    .regOut_LCOFI(MidelegModule_g_regOut_LCOFI)
  );
  MidelegModule_xs u_MidelegModule_i (
    .clock(clock),
    .reset(reset),
    .w_wen(MidelegModule_w_wen),
    .w_wdata(MidelegModule_w_wdata),
    .rdata(MidelegModule_i_rdata),
    .regOut_SSI(MidelegModule_i_regOut_SSI),
    .regOut_STI(MidelegModule_i_regOut_STI),
    .regOut_SEI(MidelegModule_i_regOut_SEI),
    .regOut_LCOFI(MidelegModule_i_regOut_LCOFI)
  );

  // MipModule
  logic MipModule_w_wen;
  logic [63:0] MipModule_w_wdata;
  logic [63:0] MipModule_rdata;
  logic MipModule_regOut_SSIP;
  logic MipModule_regOut_VSSIP;
  logic MipModule_regOut_MSIP;
  logic MipModule_regOut_STIP;
  logic MipModule_regOut_VSTIP;
  logic MipModule_regOut_MTIP;
  logic MipModule_regOut_SEIP;
  logic MipModule_regOut_VSEIP;
  logic MipModule_regOut_MEIP;
  logic MipModule_regOut_SGEIP;
  logic MipModule_regOut_LCOFIP;
  logic MipModule_rdataFields_SSIP;
  logic MipModule_rdataFields_VSSIP;
  logic MipModule_rdataFields_MSIP;
  logic MipModule_rdataFields_STIP;
  logic MipModule_rdataFields_VSTIP;
  logic MipModule_rdataFields_MTIP;
  logic MipModule_rdataFields_SEIP;
  logic MipModule_rdataFields_VSEIP;
  logic MipModule_rdataFields_MEIP;
  logic MipModule_rdataFields_SGEIP;
  logic MipModule_rdataFields_LCOFIP;
  logic MipModule_mvip_SEIP;
  logic MipModule_mvien_SEIE;
  logic MipModule_hvip_VSSIP;
  logic MipModule_hvip_VSTIP;
  logic MipModule_hvip_VSEIP;
  logic [6:0]  MipModule_hgeip_ip;
  logic [6:0]  MipModule_hgeie_ie;
  logic [5:0]  MipModule_hstatusVGEIN;
  logic MipModule_platformIRP_MEIP;
  logic MipModule_platformIRP_MTIP;
  logic MipModule_platformIRP_MSIP;
  logic MipModule_platformIRP_SEIP;
  logic MipModule_platformIRP_STIP;
  logic MipModule_platformIRP_VSTIP;
  logic MipModule_menvcfg_STCE;
  logic MipModule_lcofiReq;
  logic MipModule_aiaToCSR_meip;
  logic MipModule_aiaToCSR_seip;
  logic MipModule_fromMvip_SSIP_valid;
  logic MipModule_fromMvip_SSIP_bits;
  logic MipModule_fromMvip_STIP_valid;
  logic MipModule_fromMvip_STIP_bits;
  logic MipModule_fromSip_SSIP_valid;
  logic MipModule_fromSip_SSIP_bits;
  logic MipModule_fromSip_LCOFIP_valid;
  logic MipModule_fromSip_LCOFIP_bits;
  logic MipModule_fromVSip_LCOFIP_valid;
  logic MipModule_fromVSip_LCOFIP_bits;
  logic MipModule_toMvip_SEIP_valid;
  logic MipModule_toMvip_SEIP_bits;
  logic MipModule_toHvip_VSSIP_valid;
  logic MipModule_toHvip_VSSIP_bits;
  logic [63:0] MipModule_g_rdata;
  logic [63:0] MipModule_i_rdata;
  logic MipModule_g_regOut_SSIP;
  logic MipModule_i_regOut_SSIP;
  logic MipModule_g_regOut_VSSIP;
  logic MipModule_i_regOut_VSSIP;
  logic MipModule_g_regOut_MSIP;
  logic MipModule_i_regOut_MSIP;
  logic MipModule_g_regOut_STIP;
  logic MipModule_i_regOut_STIP;
  logic MipModule_g_regOut_VSTIP;
  logic MipModule_i_regOut_VSTIP;
  logic MipModule_g_regOut_MTIP;
  logic MipModule_i_regOut_MTIP;
  logic MipModule_g_regOut_SEIP;
  logic MipModule_i_regOut_SEIP;
  logic MipModule_g_regOut_VSEIP;
  logic MipModule_i_regOut_VSEIP;
  logic MipModule_g_regOut_MEIP;
  logic MipModule_i_regOut_MEIP;
  logic MipModule_g_regOut_SGEIP;
  logic MipModule_i_regOut_SGEIP;
  logic MipModule_g_regOut_LCOFIP;
  logic MipModule_i_regOut_LCOFIP;
  logic MipModule_g_rdataFields_SSIP;
  logic MipModule_i_rdataFields_SSIP;
  logic MipModule_g_rdataFields_VSSIP;
  logic MipModule_i_rdataFields_VSSIP;
  logic MipModule_g_rdataFields_MSIP;
  logic MipModule_i_rdataFields_MSIP;
  logic MipModule_g_rdataFields_STIP;
  logic MipModule_i_rdataFields_STIP;
  logic MipModule_g_rdataFields_VSTIP;
  logic MipModule_i_rdataFields_VSTIP;
  logic MipModule_g_rdataFields_MTIP;
  logic MipModule_i_rdataFields_MTIP;
  logic MipModule_g_rdataFields_SEIP;
  logic MipModule_i_rdataFields_SEIP;
  logic MipModule_g_rdataFields_VSEIP;
  logic MipModule_i_rdataFields_VSEIP;
  logic MipModule_g_rdataFields_MEIP;
  logic MipModule_i_rdataFields_MEIP;
  logic MipModule_g_rdataFields_SGEIP;
  logic MipModule_i_rdataFields_SGEIP;
  logic MipModule_g_rdataFields_LCOFIP;
  logic MipModule_i_rdataFields_LCOFIP;
  logic MipModule_g_toMvip_SEIP_valid;
  logic MipModule_i_toMvip_SEIP_valid;
  logic MipModule_g_toMvip_SEIP_bits;
  logic MipModule_i_toMvip_SEIP_bits;
  logic MipModule_g_toHvip_VSSIP_valid;
  logic MipModule_i_toHvip_VSSIP_valid;
  logic MipModule_g_toHvip_VSSIP_bits;
  logic MipModule_i_toHvip_VSSIP_bits;
  MipModule u_MipModule_g (
    .clock(clock),
    .reset(reset),
    .w_wen(MipModule_w_wen),
    .w_wdata(MipModule_w_wdata),
    .rdata(MipModule_g_rdata),
    .regOut_SSIP(MipModule_g_regOut_SSIP),
    .regOut_VSSIP(MipModule_g_regOut_VSSIP),
    .regOut_MSIP(MipModule_g_regOut_MSIP),
    .regOut_STIP(MipModule_g_regOut_STIP),
    .regOut_VSTIP(MipModule_g_regOut_VSTIP),
    .regOut_MTIP(MipModule_g_regOut_MTIP),
    .regOut_SEIP(MipModule_g_regOut_SEIP),
    .regOut_VSEIP(MipModule_g_regOut_VSEIP),
    .regOut_MEIP(MipModule_g_regOut_MEIP),
    .regOut_SGEIP(MipModule_g_regOut_SGEIP),
    .regOut_LCOFIP(MipModule_g_regOut_LCOFIP),
    .rdataFields_SSIP(MipModule_g_rdataFields_SSIP),
    .rdataFields_VSSIP(MipModule_g_rdataFields_VSSIP),
    .rdataFields_MSIP(MipModule_g_rdataFields_MSIP),
    .rdataFields_STIP(MipModule_g_rdataFields_STIP),
    .rdataFields_VSTIP(MipModule_g_rdataFields_VSTIP),
    .rdataFields_MTIP(MipModule_g_rdataFields_MTIP),
    .rdataFields_SEIP(MipModule_g_rdataFields_SEIP),
    .rdataFields_VSEIP(MipModule_g_rdataFields_VSEIP),
    .rdataFields_MEIP(MipModule_g_rdataFields_MEIP),
    .rdataFields_SGEIP(MipModule_g_rdataFields_SGEIP),
    .rdataFields_LCOFIP(MipModule_g_rdataFields_LCOFIP),
    .mvip_SEIP(MipModule_mvip_SEIP),
    .mvien_SEIE(MipModule_mvien_SEIE),
    .hvip_VSSIP(MipModule_hvip_VSSIP),
    .hvip_VSTIP(MipModule_hvip_VSTIP),
    .hvip_VSEIP(MipModule_hvip_VSEIP),
    .hgeip_ip(MipModule_hgeip_ip),
    .hgeie_ie(MipModule_hgeie_ie),
    .hstatusVGEIN(MipModule_hstatusVGEIN),
    .platformIRP_MEIP(MipModule_platformIRP_MEIP),
    .platformIRP_MTIP(MipModule_platformIRP_MTIP),
    .platformIRP_MSIP(MipModule_platformIRP_MSIP),
    .platformIRP_SEIP(MipModule_platformIRP_SEIP),
    .platformIRP_STIP(MipModule_platformIRP_STIP),
    .platformIRP_VSTIP(MipModule_platformIRP_VSTIP),
    .menvcfg_STCE(MipModule_menvcfg_STCE),
    .lcofiReq(MipModule_lcofiReq),
    .aiaToCSR_meip(MipModule_aiaToCSR_meip),
    .aiaToCSR_seip(MipModule_aiaToCSR_seip),
    .fromMvip_SSIP_valid(MipModule_fromMvip_SSIP_valid),
    .fromMvip_SSIP_bits(MipModule_fromMvip_SSIP_bits),
    .fromMvip_STIP_valid(MipModule_fromMvip_STIP_valid),
    .fromMvip_STIP_bits(MipModule_fromMvip_STIP_bits),
    .fromSip_SSIP_valid(MipModule_fromSip_SSIP_valid),
    .fromSip_SSIP_bits(MipModule_fromSip_SSIP_bits),
    .fromSip_LCOFIP_valid(MipModule_fromSip_LCOFIP_valid),
    .fromSip_LCOFIP_bits(MipModule_fromSip_LCOFIP_bits),
    .fromVSip_LCOFIP_valid(MipModule_fromVSip_LCOFIP_valid),
    .fromVSip_LCOFIP_bits(MipModule_fromVSip_LCOFIP_bits),
    .toMvip_SEIP_valid(MipModule_g_toMvip_SEIP_valid),
    .toMvip_SEIP_bits(MipModule_g_toMvip_SEIP_bits),
    .toHvip_VSSIP_valid(MipModule_g_toHvip_VSSIP_valid),
    .toHvip_VSSIP_bits(MipModule_g_toHvip_VSSIP_bits)
  );
  MipModule_xs u_MipModule_i (
    .clock(clock),
    .reset(reset),
    .w_wen(MipModule_w_wen),
    .w_wdata(MipModule_w_wdata),
    .rdata(MipModule_i_rdata),
    .regOut_SSIP(MipModule_i_regOut_SSIP),
    .regOut_VSSIP(MipModule_i_regOut_VSSIP),
    .regOut_MSIP(MipModule_i_regOut_MSIP),
    .regOut_STIP(MipModule_i_regOut_STIP),
    .regOut_VSTIP(MipModule_i_regOut_VSTIP),
    .regOut_MTIP(MipModule_i_regOut_MTIP),
    .regOut_SEIP(MipModule_i_regOut_SEIP),
    .regOut_VSEIP(MipModule_i_regOut_VSEIP),
    .regOut_MEIP(MipModule_i_regOut_MEIP),
    .regOut_SGEIP(MipModule_i_regOut_SGEIP),
    .regOut_LCOFIP(MipModule_i_regOut_LCOFIP),
    .rdataFields_SSIP(MipModule_i_rdataFields_SSIP),
    .rdataFields_VSSIP(MipModule_i_rdataFields_VSSIP),
    .rdataFields_MSIP(MipModule_i_rdataFields_MSIP),
    .rdataFields_STIP(MipModule_i_rdataFields_STIP),
    .rdataFields_VSTIP(MipModule_i_rdataFields_VSTIP),
    .rdataFields_MTIP(MipModule_i_rdataFields_MTIP),
    .rdataFields_SEIP(MipModule_i_rdataFields_SEIP),
    .rdataFields_VSEIP(MipModule_i_rdataFields_VSEIP),
    .rdataFields_MEIP(MipModule_i_rdataFields_MEIP),
    .rdataFields_SGEIP(MipModule_i_rdataFields_SGEIP),
    .rdataFields_LCOFIP(MipModule_i_rdataFields_LCOFIP),
    .mvip_SEIP(MipModule_mvip_SEIP),
    .mvien_SEIE(MipModule_mvien_SEIE),
    .hvip_VSSIP(MipModule_hvip_VSSIP),
    .hvip_VSTIP(MipModule_hvip_VSTIP),
    .hvip_VSEIP(MipModule_hvip_VSEIP),
    .hgeip_ip(MipModule_hgeip_ip),
    .hgeie_ie(MipModule_hgeie_ie),
    .hstatusVGEIN(MipModule_hstatusVGEIN),
    .platformIRP_MEIP(MipModule_platformIRP_MEIP),
    .platformIRP_MTIP(MipModule_platformIRP_MTIP),
    .platformIRP_MSIP(MipModule_platformIRP_MSIP),
    .platformIRP_SEIP(MipModule_platformIRP_SEIP),
    .platformIRP_STIP(MipModule_platformIRP_STIP),
    .platformIRP_VSTIP(MipModule_platformIRP_VSTIP),
    .menvcfg_STCE(MipModule_menvcfg_STCE),
    .lcofiReq(MipModule_lcofiReq),
    .aiaToCSR_meip(MipModule_aiaToCSR_meip),
    .aiaToCSR_seip(MipModule_aiaToCSR_seip),
    .fromMvip_SSIP_valid(MipModule_fromMvip_SSIP_valid),
    .fromMvip_SSIP_bits(MipModule_fromMvip_SSIP_bits),
    .fromMvip_STIP_valid(MipModule_fromMvip_STIP_valid),
    .fromMvip_STIP_bits(MipModule_fromMvip_STIP_bits),
    .fromSip_SSIP_valid(MipModule_fromSip_SSIP_valid),
    .fromSip_SSIP_bits(MipModule_fromSip_SSIP_bits),
    .fromSip_LCOFIP_valid(MipModule_fromSip_LCOFIP_valid),
    .fromSip_LCOFIP_bits(MipModule_fromSip_LCOFIP_bits),
    .fromVSip_LCOFIP_valid(MipModule_fromVSip_LCOFIP_valid),
    .fromVSip_LCOFIP_bits(MipModule_fromVSip_LCOFIP_bits),
    .toMvip_SEIP_valid(MipModule_i_toMvip_SEIP_valid),
    .toMvip_SEIP_bits(MipModule_i_toMvip_SEIP_bits),
    .toHvip_VSSIP_valid(MipModule_i_toHvip_VSSIP_valid),
    .toHvip_VSSIP_bits(MipModule_i_toHvip_VSSIP_bits)
  );

  // MiselectModule
  logic MiselectModule_w_wen;
  logic [63:0] MiselectModule_w_wdata;
  logic [63:0] MiselectModule_rdata;
  logic [8:0]  MiselectModule_regOut_ALL;
  logic MiselectModule_inIMSICRange;
  logic [63:0] MiselectModule_g_rdata;
  logic [63:0] MiselectModule_i_rdata;
  logic [8:0]  MiselectModule_g_regOut_ALL;
  logic [8:0]  MiselectModule_i_regOut_ALL;
  logic MiselectModule_g_inIMSICRange;
  logic MiselectModule_i_inIMSICRange;
  MiselectModule u_MiselectModule_g (
    .clock(clock),
    .reset(reset),
    .w_wen(MiselectModule_w_wen),
    .w_wdata(MiselectModule_w_wdata),
    .rdata(MiselectModule_g_rdata),
    .regOut_ALL(MiselectModule_g_regOut_ALL),
    .inIMSICRange(MiselectModule_g_inIMSICRange)
  );
  MiselectModule_xs u_MiselectModule_i (
    .clock(clock),
    .reset(reset),
    .w_wen(MiselectModule_w_wen),
    .w_wdata(MiselectModule_w_wdata),
    .rdata(MiselectModule_i_rdata),
    .regOut_ALL(MiselectModule_i_regOut_ALL),
    .inIMSICRange(MiselectModule_i_inIMSICRange)
  );

  // MnstatusModule
  logic MnstatusModule_w_wen;
  logic [63:0] MnstatusModule_w_wdata;
  logic [63:0] MnstatusModule_rdata;
  logic MnstatusModule_regOut_NMIE;
  logic MnstatusModule_regOut_MNPV;
  logic [1:0]  MnstatusModule_regOut_MNPP;
  logic MnstatusModule_trapToMN_mnstatus_valid;
  logic MnstatusModule_trapToMN_mnstatus_bits_NMIE;
  logic MnstatusModule_trapToMN_mnstatus_bits_MNPV;
  logic [1:0]  MnstatusModule_trapToMN_mnstatus_bits_MNPP;
  logic MnstatusModule_retFromMN_mnstatus_valid;
  logic MnstatusModule_retFromMN_mnstatus_bits_NMIE;
  logic [63:0] MnstatusModule_g_rdata;
  logic [63:0] MnstatusModule_i_rdata;
  logic MnstatusModule_g_regOut_NMIE;
  logic MnstatusModule_i_regOut_NMIE;
  logic MnstatusModule_g_regOut_MNPV;
  logic MnstatusModule_i_regOut_MNPV;
  logic [1:0]  MnstatusModule_g_regOut_MNPP;
  logic [1:0]  MnstatusModule_i_regOut_MNPP;
  MnstatusModule u_MnstatusModule_g (
    .clock(clock),
    .reset(reset),
    .w_wen(MnstatusModule_w_wen),
    .w_wdata(MnstatusModule_w_wdata),
    .rdata(MnstatusModule_g_rdata),
    .regOut_NMIE(MnstatusModule_g_regOut_NMIE),
    .regOut_MNPV(MnstatusModule_g_regOut_MNPV),
    .regOut_MNPP(MnstatusModule_g_regOut_MNPP),
    .trapToMN_mnstatus_valid(MnstatusModule_trapToMN_mnstatus_valid),
    .trapToMN_mnstatus_bits_NMIE(MnstatusModule_trapToMN_mnstatus_bits_NMIE),
    .trapToMN_mnstatus_bits_MNPV(MnstatusModule_trapToMN_mnstatus_bits_MNPV),
    .trapToMN_mnstatus_bits_MNPP(MnstatusModule_trapToMN_mnstatus_bits_MNPP),
    .retFromMN_mnstatus_valid(MnstatusModule_retFromMN_mnstatus_valid),
    .retFromMN_mnstatus_bits_NMIE(MnstatusModule_retFromMN_mnstatus_bits_NMIE)
  );
  MnstatusModule_xs u_MnstatusModule_i (
    .clock(clock),
    .reset(reset),
    .w_wen(MnstatusModule_w_wen),
    .w_wdata(MnstatusModule_w_wdata),
    .rdata(MnstatusModule_i_rdata),
    .regOut_NMIE(MnstatusModule_i_regOut_NMIE),
    .regOut_MNPV(MnstatusModule_i_regOut_MNPV),
    .regOut_MNPP(MnstatusModule_i_regOut_MNPP),
    .trapToMN_mnstatus_valid(MnstatusModule_trapToMN_mnstatus_valid),
    .trapToMN_mnstatus_bits_NMIE(MnstatusModule_trapToMN_mnstatus_bits_NMIE),
    .trapToMN_mnstatus_bits_MNPV(MnstatusModule_trapToMN_mnstatus_bits_MNPV),
    .trapToMN_mnstatus_bits_MNPP(MnstatusModule_trapToMN_mnstatus_bits_MNPP),
    .retFromMN_mnstatus_valid(MnstatusModule_retFromMN_mnstatus_valid),
    .retFromMN_mnstatus_bits_NMIE(MnstatusModule_retFromMN_mnstatus_bits_NMIE)
  );

  // MretEventModule
  logic MretEventModule_valid;
  logic MretEventModule_in_mstatus_MPIE;
  logic [1:0]  MretEventModule_in_mstatus_MPP;
  logic MretEventModule_in_mstatus_MPRV;
  logic MretEventModule_in_mstatus_SDT;
  logic MretEventModule_in_mstatus_MPV;
  logic MretEventModule_in_vsstatus_SDT;
  logic [62:0] MretEventModule_in_mepc_epc;
  logic [3:0]  MretEventModule_in_satp_MODE;
  logic [3:0]  MretEventModule_in_vsatp_MODE;
  logic [3:0]  MretEventModule_in_hgatp_MODE;
  logic MretEventModule_out_privState_valid;
  logic [1:0]  MretEventModule_out_privState_bits_PRVM;
  logic MretEventModule_out_privState_bits_V;
  logic MretEventModule_out_mstatus_valid;
  logic MretEventModule_out_mstatus_bits_SIE;
  logic MretEventModule_out_mstatus_bits_MIE;
  logic MretEventModule_out_mstatus_bits_SPIE;
  logic MretEventModule_out_mstatus_bits_UBE;
  logic MretEventModule_out_mstatus_bits_MPIE;
  logic MretEventModule_out_mstatus_bits_SPP;
  logic [1:0]  MretEventModule_out_mstatus_bits_VS;
  logic [1:0]  MretEventModule_out_mstatus_bits_MPP;
  logic [1:0]  MretEventModule_out_mstatus_bits_FS;
  logic [1:0]  MretEventModule_out_mstatus_bits_XS;
  logic MretEventModule_out_mstatus_bits_MPRV;
  logic MretEventModule_out_mstatus_bits_SUM;
  logic MretEventModule_out_mstatus_bits_MXR;
  logic MretEventModule_out_mstatus_bits_TVM;
  logic MretEventModule_out_mstatus_bits_TW;
  logic MretEventModule_out_mstatus_bits_TSR;
  logic MretEventModule_out_mstatus_bits_SDT;
  logic [1:0]  MretEventModule_out_mstatus_bits_UXL;
  logic [1:0]  MretEventModule_out_mstatus_bits_SXL;
  logic MretEventModule_out_mstatus_bits_SBE;
  logic MretEventModule_out_mstatus_bits_MBE;
  logic MretEventModule_out_mstatus_bits_GVA;
  logic MretEventModule_out_mstatus_bits_MPV;
  logic MretEventModule_out_mstatus_bits_MDT;
  logic MretEventModule_out_mstatus_bits_SD;
  logic MretEventModule_out_vsstatus_valid;
  logic MretEventModule_out_vsstatus_bits_SIE;
  logic MretEventModule_out_vsstatus_bits_SPIE;
  logic MretEventModule_out_vsstatus_bits_UBE;
  logic MretEventModule_out_vsstatus_bits_SPP;
  logic [1:0]  MretEventModule_out_vsstatus_bits_VS;
  logic [1:0]  MretEventModule_out_vsstatus_bits_FS;
  logic [1:0]  MretEventModule_out_vsstatus_bits_XS;
  logic MretEventModule_out_vsstatus_bits_SUM;
  logic MretEventModule_out_vsstatus_bits_MXR;
  logic MretEventModule_out_vsstatus_bits_SDT;
  logic [1:0]  MretEventModule_out_vsstatus_bits_UXL;
  logic MretEventModule_out_vsstatus_bits_SD;
  logic MretEventModule_out_targetPc_valid;
  logic [63:0] MretEventModule_out_targetPc_bits_pc;
  logic MretEventModule_out_targetPc_bits_raiseIPF;
  logic MretEventModule_out_targetPc_bits_raiseIAF;
  logic MretEventModule_out_targetPc_bits_raiseIGPF;
  logic MretEventModule_g_out_privState_valid;
  logic MretEventModule_i_out_privState_valid;
  logic [1:0]  MretEventModule_g_out_privState_bits_PRVM;
  logic [1:0]  MretEventModule_i_out_privState_bits_PRVM;
  logic MretEventModule_g_out_privState_bits_V;
  logic MretEventModule_i_out_privState_bits_V;
  logic MretEventModule_g_out_mstatus_valid;
  logic MretEventModule_i_out_mstatus_valid;
  logic MretEventModule_g_out_mstatus_bits_SIE;
  logic MretEventModule_i_out_mstatus_bits_SIE;
  logic MretEventModule_g_out_mstatus_bits_MIE;
  logic MretEventModule_i_out_mstatus_bits_MIE;
  logic MretEventModule_g_out_mstatus_bits_SPIE;
  logic MretEventModule_i_out_mstatus_bits_SPIE;
  logic MretEventModule_g_out_mstatus_bits_UBE;
  logic MretEventModule_i_out_mstatus_bits_UBE;
  logic MretEventModule_g_out_mstatus_bits_MPIE;
  logic MretEventModule_i_out_mstatus_bits_MPIE;
  logic MretEventModule_g_out_mstatus_bits_SPP;
  logic MretEventModule_i_out_mstatus_bits_SPP;
  logic [1:0]  MretEventModule_g_out_mstatus_bits_VS;
  logic [1:0]  MretEventModule_i_out_mstatus_bits_VS;
  logic [1:0]  MretEventModule_g_out_mstatus_bits_MPP;
  logic [1:0]  MretEventModule_i_out_mstatus_bits_MPP;
  logic [1:0]  MretEventModule_g_out_mstatus_bits_FS;
  logic [1:0]  MretEventModule_i_out_mstatus_bits_FS;
  logic [1:0]  MretEventModule_g_out_mstatus_bits_XS;
  logic [1:0]  MretEventModule_i_out_mstatus_bits_XS;
  logic MretEventModule_g_out_mstatus_bits_MPRV;
  logic MretEventModule_i_out_mstatus_bits_MPRV;
  logic MretEventModule_g_out_mstatus_bits_SUM;
  logic MretEventModule_i_out_mstatus_bits_SUM;
  logic MretEventModule_g_out_mstatus_bits_MXR;
  logic MretEventModule_i_out_mstatus_bits_MXR;
  logic MretEventModule_g_out_mstatus_bits_TVM;
  logic MretEventModule_i_out_mstatus_bits_TVM;
  logic MretEventModule_g_out_mstatus_bits_TW;
  logic MretEventModule_i_out_mstatus_bits_TW;
  logic MretEventModule_g_out_mstatus_bits_TSR;
  logic MretEventModule_i_out_mstatus_bits_TSR;
  logic MretEventModule_g_out_mstatus_bits_SDT;
  logic MretEventModule_i_out_mstatus_bits_SDT;
  logic [1:0]  MretEventModule_g_out_mstatus_bits_UXL;
  logic [1:0]  MretEventModule_i_out_mstatus_bits_UXL;
  logic [1:0]  MretEventModule_g_out_mstatus_bits_SXL;
  logic [1:0]  MretEventModule_i_out_mstatus_bits_SXL;
  logic MretEventModule_g_out_mstatus_bits_SBE;
  logic MretEventModule_i_out_mstatus_bits_SBE;
  logic MretEventModule_g_out_mstatus_bits_MBE;
  logic MretEventModule_i_out_mstatus_bits_MBE;
  logic MretEventModule_g_out_mstatus_bits_GVA;
  logic MretEventModule_i_out_mstatus_bits_GVA;
  logic MretEventModule_g_out_mstatus_bits_MPV;
  logic MretEventModule_i_out_mstatus_bits_MPV;
  logic MretEventModule_g_out_mstatus_bits_MDT;
  logic MretEventModule_i_out_mstatus_bits_MDT;
  logic MretEventModule_g_out_mstatus_bits_SD;
  logic MretEventModule_i_out_mstatus_bits_SD;
  logic MretEventModule_g_out_vsstatus_valid;
  logic MretEventModule_i_out_vsstatus_valid;
  logic MretEventModule_g_out_vsstatus_bits_SIE;
  logic MretEventModule_i_out_vsstatus_bits_SIE;
  logic MretEventModule_g_out_vsstatus_bits_SPIE;
  logic MretEventModule_i_out_vsstatus_bits_SPIE;
  logic MretEventModule_g_out_vsstatus_bits_UBE;
  logic MretEventModule_i_out_vsstatus_bits_UBE;
  logic MretEventModule_g_out_vsstatus_bits_SPP;
  logic MretEventModule_i_out_vsstatus_bits_SPP;
  logic [1:0]  MretEventModule_g_out_vsstatus_bits_VS;
  logic [1:0]  MretEventModule_i_out_vsstatus_bits_VS;
  logic [1:0]  MretEventModule_g_out_vsstatus_bits_FS;
  logic [1:0]  MretEventModule_i_out_vsstatus_bits_FS;
  logic [1:0]  MretEventModule_g_out_vsstatus_bits_XS;
  logic [1:0]  MretEventModule_i_out_vsstatus_bits_XS;
  logic MretEventModule_g_out_vsstatus_bits_SUM;
  logic MretEventModule_i_out_vsstatus_bits_SUM;
  logic MretEventModule_g_out_vsstatus_bits_MXR;
  logic MretEventModule_i_out_vsstatus_bits_MXR;
  logic MretEventModule_g_out_vsstatus_bits_SDT;
  logic MretEventModule_i_out_vsstatus_bits_SDT;
  logic [1:0]  MretEventModule_g_out_vsstatus_bits_UXL;
  logic [1:0]  MretEventModule_i_out_vsstatus_bits_UXL;
  logic MretEventModule_g_out_vsstatus_bits_SD;
  logic MretEventModule_i_out_vsstatus_bits_SD;
  logic MretEventModule_g_out_targetPc_valid;
  logic MretEventModule_i_out_targetPc_valid;
  logic [63:0] MretEventModule_g_out_targetPc_bits_pc;
  logic [63:0] MretEventModule_i_out_targetPc_bits_pc;
  logic MretEventModule_g_out_targetPc_bits_raiseIPF;
  logic MretEventModule_i_out_targetPc_bits_raiseIPF;
  logic MretEventModule_g_out_targetPc_bits_raiseIAF;
  logic MretEventModule_i_out_targetPc_bits_raiseIAF;
  logic MretEventModule_g_out_targetPc_bits_raiseIGPF;
  logic MretEventModule_i_out_targetPc_bits_raiseIGPF;
  MretEventModule u_MretEventModule_g (
    .valid(MretEventModule_valid),
    .in_mstatus_MPIE(MretEventModule_in_mstatus_MPIE),
    .in_mstatus_MPP(MretEventModule_in_mstatus_MPP),
    .in_mstatus_MPRV(MretEventModule_in_mstatus_MPRV),
    .in_mstatus_SDT(MretEventModule_in_mstatus_SDT),
    .in_mstatus_MPV(MretEventModule_in_mstatus_MPV),
    .in_vsstatus_SDT(MretEventModule_in_vsstatus_SDT),
    .in_mepc_epc(MretEventModule_in_mepc_epc),
    .in_satp_MODE(MretEventModule_in_satp_MODE),
    .in_vsatp_MODE(MretEventModule_in_vsatp_MODE),
    .in_hgatp_MODE(MretEventModule_in_hgatp_MODE),
    .out_privState_valid(MretEventModule_g_out_privState_valid),
    .out_privState_bits_PRVM(MretEventModule_g_out_privState_bits_PRVM),
    .out_privState_bits_V(MretEventModule_g_out_privState_bits_V),
    .out_mstatus_valid(MretEventModule_g_out_mstatus_valid),
    .out_mstatus_bits_SIE(MretEventModule_g_out_mstatus_bits_SIE),
    .out_mstatus_bits_MIE(MretEventModule_g_out_mstatus_bits_MIE),
    .out_mstatus_bits_SPIE(MretEventModule_g_out_mstatus_bits_SPIE),
    .out_mstatus_bits_UBE(MretEventModule_g_out_mstatus_bits_UBE),
    .out_mstatus_bits_MPIE(MretEventModule_g_out_mstatus_bits_MPIE),
    .out_mstatus_bits_SPP(MretEventModule_g_out_mstatus_bits_SPP),
    .out_mstatus_bits_VS(MretEventModule_g_out_mstatus_bits_VS),
    .out_mstatus_bits_MPP(MretEventModule_g_out_mstatus_bits_MPP),
    .out_mstatus_bits_FS(MretEventModule_g_out_mstatus_bits_FS),
    .out_mstatus_bits_XS(MretEventModule_g_out_mstatus_bits_XS),
    .out_mstatus_bits_MPRV(MretEventModule_g_out_mstatus_bits_MPRV),
    .out_mstatus_bits_SUM(MretEventModule_g_out_mstatus_bits_SUM),
    .out_mstatus_bits_MXR(MretEventModule_g_out_mstatus_bits_MXR),
    .out_mstatus_bits_TVM(MretEventModule_g_out_mstatus_bits_TVM),
    .out_mstatus_bits_TW(MretEventModule_g_out_mstatus_bits_TW),
    .out_mstatus_bits_TSR(MretEventModule_g_out_mstatus_bits_TSR),
    .out_mstatus_bits_SDT(MretEventModule_g_out_mstatus_bits_SDT),
    .out_mstatus_bits_UXL(MretEventModule_g_out_mstatus_bits_UXL),
    .out_mstatus_bits_SXL(MretEventModule_g_out_mstatus_bits_SXL),
    .out_mstatus_bits_SBE(MretEventModule_g_out_mstatus_bits_SBE),
    .out_mstatus_bits_MBE(MretEventModule_g_out_mstatus_bits_MBE),
    .out_mstatus_bits_GVA(MretEventModule_g_out_mstatus_bits_GVA),
    .out_mstatus_bits_MPV(MretEventModule_g_out_mstatus_bits_MPV),
    .out_mstatus_bits_MDT(MretEventModule_g_out_mstatus_bits_MDT),
    .out_mstatus_bits_SD(MretEventModule_g_out_mstatus_bits_SD),
    .out_vsstatus_valid(MretEventModule_g_out_vsstatus_valid),
    .out_vsstatus_bits_SIE(MretEventModule_g_out_vsstatus_bits_SIE),
    .out_vsstatus_bits_SPIE(MretEventModule_g_out_vsstatus_bits_SPIE),
    .out_vsstatus_bits_UBE(MretEventModule_g_out_vsstatus_bits_UBE),
    .out_vsstatus_bits_SPP(MretEventModule_g_out_vsstatus_bits_SPP),
    .out_vsstatus_bits_VS(MretEventModule_g_out_vsstatus_bits_VS),
    .out_vsstatus_bits_FS(MretEventModule_g_out_vsstatus_bits_FS),
    .out_vsstatus_bits_XS(MretEventModule_g_out_vsstatus_bits_XS),
    .out_vsstatus_bits_SUM(MretEventModule_g_out_vsstatus_bits_SUM),
    .out_vsstatus_bits_MXR(MretEventModule_g_out_vsstatus_bits_MXR),
    .out_vsstatus_bits_SDT(MretEventModule_g_out_vsstatus_bits_SDT),
    .out_vsstatus_bits_UXL(MretEventModule_g_out_vsstatus_bits_UXL),
    .out_vsstatus_bits_SD(MretEventModule_g_out_vsstatus_bits_SD),
    .out_targetPc_valid(MretEventModule_g_out_targetPc_valid),
    .out_targetPc_bits_pc(MretEventModule_g_out_targetPc_bits_pc),
    .out_targetPc_bits_raiseIPF(MretEventModule_g_out_targetPc_bits_raiseIPF),
    .out_targetPc_bits_raiseIAF(MretEventModule_g_out_targetPc_bits_raiseIAF),
    .out_targetPc_bits_raiseIGPF(MretEventModule_g_out_targetPc_bits_raiseIGPF)
  );
  MretEventModule_xs u_MretEventModule_i (
    .valid(MretEventModule_valid),
    .in_mstatus_MPIE(MretEventModule_in_mstatus_MPIE),
    .in_mstatus_MPP(MretEventModule_in_mstatus_MPP),
    .in_mstatus_MPRV(MretEventModule_in_mstatus_MPRV),
    .in_mstatus_SDT(MretEventModule_in_mstatus_SDT),
    .in_mstatus_MPV(MretEventModule_in_mstatus_MPV),
    .in_vsstatus_SDT(MretEventModule_in_vsstatus_SDT),
    .in_mepc_epc(MretEventModule_in_mepc_epc),
    .in_satp_MODE(MretEventModule_in_satp_MODE),
    .in_vsatp_MODE(MretEventModule_in_vsatp_MODE),
    .in_hgatp_MODE(MretEventModule_in_hgatp_MODE),
    .out_privState_valid(MretEventModule_i_out_privState_valid),
    .out_privState_bits_PRVM(MretEventModule_i_out_privState_bits_PRVM),
    .out_privState_bits_V(MretEventModule_i_out_privState_bits_V),
    .out_mstatus_valid(MretEventModule_i_out_mstatus_valid),
    .out_mstatus_bits_SIE(MretEventModule_i_out_mstatus_bits_SIE),
    .out_mstatus_bits_MIE(MretEventModule_i_out_mstatus_bits_MIE),
    .out_mstatus_bits_SPIE(MretEventModule_i_out_mstatus_bits_SPIE),
    .out_mstatus_bits_UBE(MretEventModule_i_out_mstatus_bits_UBE),
    .out_mstatus_bits_MPIE(MretEventModule_i_out_mstatus_bits_MPIE),
    .out_mstatus_bits_SPP(MretEventModule_i_out_mstatus_bits_SPP),
    .out_mstatus_bits_VS(MretEventModule_i_out_mstatus_bits_VS),
    .out_mstatus_bits_MPP(MretEventModule_i_out_mstatus_bits_MPP),
    .out_mstatus_bits_FS(MretEventModule_i_out_mstatus_bits_FS),
    .out_mstatus_bits_XS(MretEventModule_i_out_mstatus_bits_XS),
    .out_mstatus_bits_MPRV(MretEventModule_i_out_mstatus_bits_MPRV),
    .out_mstatus_bits_SUM(MretEventModule_i_out_mstatus_bits_SUM),
    .out_mstatus_bits_MXR(MretEventModule_i_out_mstatus_bits_MXR),
    .out_mstatus_bits_TVM(MretEventModule_i_out_mstatus_bits_TVM),
    .out_mstatus_bits_TW(MretEventModule_i_out_mstatus_bits_TW),
    .out_mstatus_bits_TSR(MretEventModule_i_out_mstatus_bits_TSR),
    .out_mstatus_bits_SDT(MretEventModule_i_out_mstatus_bits_SDT),
    .out_mstatus_bits_UXL(MretEventModule_i_out_mstatus_bits_UXL),
    .out_mstatus_bits_SXL(MretEventModule_i_out_mstatus_bits_SXL),
    .out_mstatus_bits_SBE(MretEventModule_i_out_mstatus_bits_SBE),
    .out_mstatus_bits_MBE(MretEventModule_i_out_mstatus_bits_MBE),
    .out_mstatus_bits_GVA(MretEventModule_i_out_mstatus_bits_GVA),
    .out_mstatus_bits_MPV(MretEventModule_i_out_mstatus_bits_MPV),
    .out_mstatus_bits_MDT(MretEventModule_i_out_mstatus_bits_MDT),
    .out_mstatus_bits_SD(MretEventModule_i_out_mstatus_bits_SD),
    .out_vsstatus_valid(MretEventModule_i_out_vsstatus_valid),
    .out_vsstatus_bits_SIE(MretEventModule_i_out_vsstatus_bits_SIE),
    .out_vsstatus_bits_SPIE(MretEventModule_i_out_vsstatus_bits_SPIE),
    .out_vsstatus_bits_UBE(MretEventModule_i_out_vsstatus_bits_UBE),
    .out_vsstatus_bits_SPP(MretEventModule_i_out_vsstatus_bits_SPP),
    .out_vsstatus_bits_VS(MretEventModule_i_out_vsstatus_bits_VS),
    .out_vsstatus_bits_FS(MretEventModule_i_out_vsstatus_bits_FS),
    .out_vsstatus_bits_XS(MretEventModule_i_out_vsstatus_bits_XS),
    .out_vsstatus_bits_SUM(MretEventModule_i_out_vsstatus_bits_SUM),
    .out_vsstatus_bits_MXR(MretEventModule_i_out_vsstatus_bits_MXR),
    .out_vsstatus_bits_SDT(MretEventModule_i_out_vsstatus_bits_SDT),
    .out_vsstatus_bits_UXL(MretEventModule_i_out_vsstatus_bits_UXL),
    .out_vsstatus_bits_SD(MretEventModule_i_out_vsstatus_bits_SD),
    .out_targetPc_valid(MretEventModule_i_out_targetPc_valid),
    .out_targetPc_bits_pc(MretEventModule_i_out_targetPc_bits_pc),
    .out_targetPc_bits_raiseIPF(MretEventModule_i_out_targetPc_bits_raiseIPF),
    .out_targetPc_bits_raiseIAF(MretEventModule_i_out_targetPc_bits_raiseIAF),
    .out_targetPc_bits_raiseIGPF(MretEventModule_i_out_targetPc_bits_raiseIGPF)
  );

  // MseccfgModule
  logic MseccfgModule_w_wen;
  logic [63:0] MseccfgModule_w_wdata;
  logic [63:0] MseccfgModule_rdata;
  logic [1:0]  MseccfgModule_regOut_PMM;
  logic [63:0] MseccfgModule_g_rdata;
  logic [63:0] MseccfgModule_i_rdata;
  logic [1:0]  MseccfgModule_g_regOut_PMM;
  logic [1:0]  MseccfgModule_i_regOut_PMM;
  MseccfgModule u_MseccfgModule_g (
    .clock(clock),
    .reset(reset),
    .w_wen(MseccfgModule_w_wen),
    .w_wdata(MseccfgModule_w_wdata),
    .rdata(MseccfgModule_g_rdata),
    .regOut_PMM(MseccfgModule_g_regOut_PMM)
  );
  MseccfgModule_xs u_MseccfgModule_i (
    .clock(clock),
    .reset(reset),
    .w_wen(MseccfgModule_w_wen),
    .w_wdata(MseccfgModule_w_wdata),
    .rdata(MseccfgModule_i_rdata),
    .regOut_PMM(MseccfgModule_i_regOut_PMM)
  );

  // Mstateen0Module
  logic Mstateen0Module_w_wen;
  logic [63:0] Mstateen0Module_w_wdata;
  logic [63:0] Mstateen0Module_rdata;
  logic Mstateen0Module_regOut_SE0;
  logic Mstateen0Module_regOut_ENVCFG;
  logic Mstateen0Module_regOut_CSRIND;
  logic Mstateen0Module_regOut_AIA;
  logic Mstateen0Module_regOut_IMSIC;
  logic Mstateen0Module_regOut_CONTEXT;
  logic Mstateen0Module_regOut_C;
  logic [63:0] Mstateen0Module_g_rdata;
  logic [63:0] Mstateen0Module_i_rdata;
  logic Mstateen0Module_g_regOut_SE0;
  logic Mstateen0Module_i_regOut_SE0;
  logic Mstateen0Module_g_regOut_ENVCFG;
  logic Mstateen0Module_i_regOut_ENVCFG;
  logic Mstateen0Module_g_regOut_CSRIND;
  logic Mstateen0Module_i_regOut_CSRIND;
  logic Mstateen0Module_g_regOut_AIA;
  logic Mstateen0Module_i_regOut_AIA;
  logic Mstateen0Module_g_regOut_IMSIC;
  logic Mstateen0Module_i_regOut_IMSIC;
  logic Mstateen0Module_g_regOut_CONTEXT;
  logic Mstateen0Module_i_regOut_CONTEXT;
  logic Mstateen0Module_g_regOut_C;
  logic Mstateen0Module_i_regOut_C;
  Mstateen0Module u_Mstateen0Module_g (
    .clock(clock),
    .reset(reset),
    .w_wen(Mstateen0Module_w_wen),
    .w_wdata(Mstateen0Module_w_wdata),
    .rdata(Mstateen0Module_g_rdata),
    .regOut_SE0(Mstateen0Module_g_regOut_SE0),
    .regOut_ENVCFG(Mstateen0Module_g_regOut_ENVCFG),
    .regOut_CSRIND(Mstateen0Module_g_regOut_CSRIND),
    .regOut_AIA(Mstateen0Module_g_regOut_AIA),
    .regOut_IMSIC(Mstateen0Module_g_regOut_IMSIC),
    .regOut_CONTEXT(Mstateen0Module_g_regOut_CONTEXT),
    .regOut_C(Mstateen0Module_g_regOut_C)
  );
  Mstateen0Module_xs u_Mstateen0Module_i (
    .clock(clock),
    .reset(reset),
    .w_wen(Mstateen0Module_w_wen),
    .w_wdata(Mstateen0Module_w_wdata),
    .rdata(Mstateen0Module_i_rdata),
    .regOut_SE0(Mstateen0Module_i_regOut_SE0),
    .regOut_ENVCFG(Mstateen0Module_i_regOut_ENVCFG),
    .regOut_CSRIND(Mstateen0Module_i_regOut_CSRIND),
    .regOut_AIA(Mstateen0Module_i_regOut_AIA),
    .regOut_IMSIC(Mstateen0Module_i_regOut_IMSIC),
    .regOut_CONTEXT(Mstateen0Module_i_regOut_CONTEXT),
    .regOut_C(Mstateen0Module_i_regOut_C)
  );

  // Mstateen1Module
  logic Mstateen1Module_w_wen;
  logic [63:0] Mstateen1Module_w_wdata;
  logic [63:0] Mstateen1Module_rdata;
  logic Mstateen1Module_regOut_SE;
  logic [63:0] Mstateen1Module_g_rdata;
  logic [63:0] Mstateen1Module_i_rdata;
  logic Mstateen1Module_g_regOut_SE;
  logic Mstateen1Module_i_regOut_SE;
  Mstateen1Module u_Mstateen1Module_g (
    .clock(clock),
    .reset(reset),
    .w_wen(Mstateen1Module_w_wen),
    .w_wdata(Mstateen1Module_w_wdata),
    .rdata(Mstateen1Module_g_rdata),
    .regOut_SE(Mstateen1Module_g_regOut_SE)
  );
  Mstateen1Module_xs u_Mstateen1Module_i (
    .clock(clock),
    .reset(reset),
    .w_wen(Mstateen1Module_w_wen),
    .w_wdata(Mstateen1Module_w_wdata),
    .rdata(Mstateen1Module_i_rdata),
    .regOut_SE(Mstateen1Module_i_regOut_SE)
  );

  // Mstateen2Module
  logic Mstateen2Module_w_wen;
  logic [63:0] Mstateen2Module_w_wdata;
  logic [63:0] Mstateen2Module_rdata;
  logic Mstateen2Module_regOut_SE;
  logic [63:0] Mstateen2Module_g_rdata;
  logic [63:0] Mstateen2Module_i_rdata;
  logic Mstateen2Module_g_regOut_SE;
  logic Mstateen2Module_i_regOut_SE;
  Mstateen2Module u_Mstateen2Module_g (
    .clock(clock),
    .reset(reset),
    .w_wen(Mstateen2Module_w_wen),
    .w_wdata(Mstateen2Module_w_wdata),
    .rdata(Mstateen2Module_g_rdata),
    .regOut_SE(Mstateen2Module_g_regOut_SE)
  );
  Mstateen2Module_xs u_Mstateen2Module_i (
    .clock(clock),
    .reset(reset),
    .w_wen(Mstateen2Module_w_wen),
    .w_wdata(Mstateen2Module_w_wdata),
    .rdata(Mstateen2Module_i_rdata),
    .regOut_SE(Mstateen2Module_i_regOut_SE)
  );

  // Mstateen3Module
  logic Mstateen3Module_w_wen;
  logic [63:0] Mstateen3Module_w_wdata;
  logic [63:0] Mstateen3Module_rdata;
  logic Mstateen3Module_regOut_SE;
  logic [63:0] Mstateen3Module_g_rdata;
  logic [63:0] Mstateen3Module_i_rdata;
  logic Mstateen3Module_g_regOut_SE;
  logic Mstateen3Module_i_regOut_SE;
  Mstateen3Module u_Mstateen3Module_g (
    .clock(clock),
    .reset(reset),
    .w_wen(Mstateen3Module_w_wen),
    .w_wdata(Mstateen3Module_w_wdata),
    .rdata(Mstateen3Module_g_rdata),
    .regOut_SE(Mstateen3Module_g_regOut_SE)
  );
  Mstateen3Module_xs u_Mstateen3Module_i (
    .clock(clock),
    .reset(reset),
    .w_wen(Mstateen3Module_w_wen),
    .w_wdata(Mstateen3Module_w_wdata),
    .rdata(Mstateen3Module_i_rdata),
    .regOut_SE(Mstateen3Module_i_regOut_SE)
  );

  // MtinstModule
  logic MtinstModule_w_wen;
  logic [63:0] MtinstModule_w_wdata;
  logic [63:0] MtinstModule_rdata;
  logic [63:0] MtinstModule_regOut_ALL;
  logic MtinstModule_trapToM_mtinst_valid;
  logic [63:0] MtinstModule_trapToM_mtinst_bits_ALL;
  logic [63:0] MtinstModule_g_rdata;
  logic [63:0] MtinstModule_i_rdata;
  logic [63:0] MtinstModule_g_regOut_ALL;
  logic [63:0] MtinstModule_i_regOut_ALL;
  MtinstModule u_MtinstModule_g (
    .clock(clock),
    .reset(reset),
    .w_wen(MtinstModule_w_wen),
    .w_wdata(MtinstModule_w_wdata),
    .rdata(MtinstModule_g_rdata),
    .regOut_ALL(MtinstModule_g_regOut_ALL),
    .trapToM_mtinst_valid(MtinstModule_trapToM_mtinst_valid),
    .trapToM_mtinst_bits_ALL(MtinstModule_trapToM_mtinst_bits_ALL)
  );
  MtinstModule_xs u_MtinstModule_i (
    .clock(clock),
    .reset(reset),
    .w_wen(MtinstModule_w_wen),
    .w_wdata(MtinstModule_w_wdata),
    .rdata(MtinstModule_i_rdata),
    .regOut_ALL(MtinstModule_i_regOut_ALL),
    .trapToM_mtinst_valid(MtinstModule_trapToM_mtinst_valid),
    .trapToM_mtinst_bits_ALL(MtinstModule_trapToM_mtinst_bits_ALL)
  );

  // SatpModule
  logic SatpModule_w_wen;
  logic [63:0] SatpModule_w_wdata;
  logic [63:0] SatpModule_rdata;
  logic [3:0]  SatpModule_regOut_MODE;
  logic [15:0] SatpModule_regOut_ASID;
  logic [43:0] SatpModule_regOut_PPN;
  logic [63:0] SatpModule_g_rdata;
  logic [63:0] SatpModule_i_rdata;
  logic [3:0]  SatpModule_g_regOut_MODE;
  logic [3:0]  SatpModule_i_regOut_MODE;
  logic [15:0] SatpModule_g_regOut_ASID;
  logic [15:0] SatpModule_i_regOut_ASID;
  logic [43:0] SatpModule_g_regOut_PPN;
  logic [43:0] SatpModule_i_regOut_PPN;
  SatpModule u_SatpModule_g (
    .clock(clock),
    .reset(reset),
    .w_wen(SatpModule_w_wen),
    .w_wdata(SatpModule_w_wdata),
    .rdata(SatpModule_g_rdata),
    .regOut_MODE(SatpModule_g_regOut_MODE),
    .regOut_ASID(SatpModule_g_regOut_ASID),
    .regOut_PPN(SatpModule_g_regOut_PPN)
  );
  SatpModule_xs u_SatpModule_i (
    .clock(clock),
    .reset(reset),
    .w_wen(SatpModule_w_wen),
    .w_wdata(SatpModule_w_wdata),
    .rdata(SatpModule_i_rdata),
    .regOut_MODE(SatpModule_i_regOut_MODE),
    .regOut_ASID(SatpModule_i_regOut_ASID),
    .regOut_PPN(SatpModule_i_regOut_PPN)
  );

  // SbpctlModule
  logic SbpctlModule_w_wen;
  logic [63:0] SbpctlModule_w_wdata;
  logic [63:0] SbpctlModule_rdata;
  logic SbpctlModule_regOut_LOOP_ENABLE;
  logic SbpctlModule_regOut_RAS_ENABLE;
  logic SbpctlModule_regOut_SC_ENABLE;
  logic SbpctlModule_regOut_TAGE_ENABLE;
  logic SbpctlModule_regOut_BIM_ENABLE;
  logic SbpctlModule_regOut_BTB_ENABLE;
  logic SbpctlModule_regOut_UBTB_ENABLE;
  logic [63:0] SbpctlModule_g_rdata;
  logic [63:0] SbpctlModule_i_rdata;
  logic SbpctlModule_g_regOut_LOOP_ENABLE;
  logic SbpctlModule_i_regOut_LOOP_ENABLE;
  logic SbpctlModule_g_regOut_RAS_ENABLE;
  logic SbpctlModule_i_regOut_RAS_ENABLE;
  logic SbpctlModule_g_regOut_SC_ENABLE;
  logic SbpctlModule_i_regOut_SC_ENABLE;
  logic SbpctlModule_g_regOut_TAGE_ENABLE;
  logic SbpctlModule_i_regOut_TAGE_ENABLE;
  logic SbpctlModule_g_regOut_BIM_ENABLE;
  logic SbpctlModule_i_regOut_BIM_ENABLE;
  logic SbpctlModule_g_regOut_BTB_ENABLE;
  logic SbpctlModule_i_regOut_BTB_ENABLE;
  logic SbpctlModule_g_regOut_UBTB_ENABLE;
  logic SbpctlModule_i_regOut_UBTB_ENABLE;
  SbpctlModule u_SbpctlModule_g (
    .clock(clock),
    .reset(reset),
    .w_wen(SbpctlModule_w_wen),
    .w_wdata(SbpctlModule_w_wdata),
    .rdata(SbpctlModule_g_rdata),
    .regOut_LOOP_ENABLE(SbpctlModule_g_regOut_LOOP_ENABLE),
    .regOut_RAS_ENABLE(SbpctlModule_g_regOut_RAS_ENABLE),
    .regOut_SC_ENABLE(SbpctlModule_g_regOut_SC_ENABLE),
    .regOut_TAGE_ENABLE(SbpctlModule_g_regOut_TAGE_ENABLE),
    .regOut_BIM_ENABLE(SbpctlModule_g_regOut_BIM_ENABLE),
    .regOut_BTB_ENABLE(SbpctlModule_g_regOut_BTB_ENABLE),
    .regOut_UBTB_ENABLE(SbpctlModule_g_regOut_UBTB_ENABLE)
  );
  SbpctlModule_xs u_SbpctlModule_i (
    .clock(clock),
    .reset(reset),
    .w_wen(SbpctlModule_w_wen),
    .w_wdata(SbpctlModule_w_wdata),
    .rdata(SbpctlModule_i_rdata),
    .regOut_LOOP_ENABLE(SbpctlModule_i_regOut_LOOP_ENABLE),
    .regOut_RAS_ENABLE(SbpctlModule_i_regOut_RAS_ENABLE),
    .regOut_SC_ENABLE(SbpctlModule_i_regOut_SC_ENABLE),
    .regOut_TAGE_ENABLE(SbpctlModule_i_regOut_TAGE_ENABLE),
    .regOut_BIM_ENABLE(SbpctlModule_i_regOut_BIM_ENABLE),
    .regOut_BTB_ENABLE(SbpctlModule_i_regOut_BTB_ENABLE),
    .regOut_UBTB_ENABLE(SbpctlModule_i_regOut_UBTB_ENABLE)
  );

  // ScounterenModule
  logic ScounterenModule_w_wen;
  logic [63:0] ScounterenModule_w_wdata;
  logic [63:0] ScounterenModule_rdata;
  logic ScounterenModule_regOut_CY;
  logic ScounterenModule_regOut_TM;
  logic ScounterenModule_regOut_IR;
  logic [28:0] ScounterenModule_regOut_HPM;
  logic [63:0] ScounterenModule_g_rdata;
  logic [63:0] ScounterenModule_i_rdata;
  logic ScounterenModule_g_regOut_CY;
  logic ScounterenModule_i_regOut_CY;
  logic ScounterenModule_g_regOut_TM;
  logic ScounterenModule_i_regOut_TM;
  logic ScounterenModule_g_regOut_IR;
  logic ScounterenModule_i_regOut_IR;
  logic [28:0] ScounterenModule_g_regOut_HPM;
  logic [28:0] ScounterenModule_i_regOut_HPM;
  ScounterenModule u_ScounterenModule_g (
    .clock(clock),
    .reset(reset),
    .w_wen(ScounterenModule_w_wen),
    .w_wdata(ScounterenModule_w_wdata),
    .rdata(ScounterenModule_g_rdata),
    .regOut_CY(ScounterenModule_g_regOut_CY),
    .regOut_TM(ScounterenModule_g_regOut_TM),
    .regOut_IR(ScounterenModule_g_regOut_IR),
    .regOut_HPM(ScounterenModule_g_regOut_HPM)
  );
  ScounterenModule_xs u_ScounterenModule_i (
    .clock(clock),
    .reset(reset),
    .w_wen(ScounterenModule_w_wen),
    .w_wdata(ScounterenModule_w_wdata),
    .rdata(ScounterenModule_i_rdata),
    .regOut_CY(ScounterenModule_i_regOut_CY),
    .regOut_TM(ScounterenModule_i_regOut_TM),
    .regOut_IR(ScounterenModule_i_regOut_IR),
    .regOut_HPM(ScounterenModule_i_regOut_HPM)
  );

  // SenvcfgModule
  logic SenvcfgModule_w_wen;
  logic [63:0] SenvcfgModule_w_wdata;
  logic [63:0] SenvcfgModule_rdata;
  logic [1:0]  SenvcfgModule_regOut_PMM;
  logic SenvcfgModule_regOut_CBZE;
  logic SenvcfgModule_regOut_CBCFE;
  logic [1:0]  SenvcfgModule_regOut_CBIE;
  logic [63:0] SenvcfgModule_g_rdata;
  logic [63:0] SenvcfgModule_i_rdata;
  logic [1:0]  SenvcfgModule_g_regOut_PMM;
  logic [1:0]  SenvcfgModule_i_regOut_PMM;
  logic SenvcfgModule_g_regOut_CBZE;
  logic SenvcfgModule_i_regOut_CBZE;
  logic SenvcfgModule_g_regOut_CBCFE;
  logic SenvcfgModule_i_regOut_CBCFE;
  logic [1:0]  SenvcfgModule_g_regOut_CBIE;
  logic [1:0]  SenvcfgModule_i_regOut_CBIE;
  SenvcfgModule u_SenvcfgModule_g (
    .clock(clock),
    .reset(reset),
    .w_wen(SenvcfgModule_w_wen),
    .w_wdata(SenvcfgModule_w_wdata),
    .rdata(SenvcfgModule_g_rdata),
    .regOut_PMM(SenvcfgModule_g_regOut_PMM),
    .regOut_CBZE(SenvcfgModule_g_regOut_CBZE),
    .regOut_CBCFE(SenvcfgModule_g_regOut_CBCFE),
    .regOut_CBIE(SenvcfgModule_g_regOut_CBIE)
  );
  SenvcfgModule_xs u_SenvcfgModule_i (
    .clock(clock),
    .reset(reset),
    .w_wen(SenvcfgModule_w_wen),
    .w_wdata(SenvcfgModule_w_wdata),
    .rdata(SenvcfgModule_i_rdata),
    .regOut_PMM(SenvcfgModule_i_regOut_PMM),
    .regOut_CBZE(SenvcfgModule_i_regOut_CBZE),
    .regOut_CBCFE(SenvcfgModule_i_regOut_CBCFE),
    .regOut_CBIE(SenvcfgModule_i_regOut_CBIE)
  );

  // SiselectModule
  logic SiselectModule_w_wen;
  logic [63:0] SiselectModule_w_wdata;
  logic [63:0] SiselectModule_rdata;
  logic [12:0] SiselectModule_regOut_ALL;
  logic SiselectModule_inIMSICRange;
  logic [63:0] SiselectModule_g_rdata;
  logic [63:0] SiselectModule_i_rdata;
  logic [12:0] SiselectModule_g_regOut_ALL;
  logic [12:0] SiselectModule_i_regOut_ALL;
  logic SiselectModule_g_inIMSICRange;
  logic SiselectModule_i_inIMSICRange;
  SiselectModule u_SiselectModule_g (
    .clock(clock),
    .reset(reset),
    .w_wen(SiselectModule_w_wen),
    .w_wdata(SiselectModule_w_wdata),
    .rdata(SiselectModule_g_rdata),
    .regOut_ALL(SiselectModule_g_regOut_ALL),
    .inIMSICRange(SiselectModule_g_inIMSICRange)
  );
  SiselectModule_xs u_SiselectModule_i (
    .clock(clock),
    .reset(reset),
    .w_wen(SiselectModule_w_wen),
    .w_wdata(SiselectModule_w_wdata),
    .rdata(SiselectModule_i_rdata),
    .regOut_ALL(SiselectModule_i_regOut_ALL),
    .inIMSICRange(SiselectModule_i_inIMSICRange)
  );

  // SlvpredctlModule
  logic SlvpredctlModule_w_wen;
  logic [63:0] SlvpredctlModule_w_wdata;
  logic [63:0] SlvpredctlModule_rdata;
  logic [4:0]  SlvpredctlModule_regOut_LVPRED_TIMEOUT;
  logic SlvpredctlModule_regOut_STORESET_NO_FAST_WAKEUP;
  logic SlvpredctlModule_regOut_STORESET_WAIT_STORE;
  logic SlvpredctlModule_regOut_NO_SPEC_LOAD;
  logic SlvpredctlModule_regOut_LVPRED_DISABLE;
  logic [63:0] SlvpredctlModule_g_rdata;
  logic [63:0] SlvpredctlModule_i_rdata;
  logic [4:0]  SlvpredctlModule_g_regOut_LVPRED_TIMEOUT;
  logic [4:0]  SlvpredctlModule_i_regOut_LVPRED_TIMEOUT;
  logic SlvpredctlModule_g_regOut_STORESET_NO_FAST_WAKEUP;
  logic SlvpredctlModule_i_regOut_STORESET_NO_FAST_WAKEUP;
  logic SlvpredctlModule_g_regOut_STORESET_WAIT_STORE;
  logic SlvpredctlModule_i_regOut_STORESET_WAIT_STORE;
  logic SlvpredctlModule_g_regOut_NO_SPEC_LOAD;
  logic SlvpredctlModule_i_regOut_NO_SPEC_LOAD;
  logic SlvpredctlModule_g_regOut_LVPRED_DISABLE;
  logic SlvpredctlModule_i_regOut_LVPRED_DISABLE;
  SlvpredctlModule u_SlvpredctlModule_g (
    .clock(clock),
    .reset(reset),
    .w_wen(SlvpredctlModule_w_wen),
    .w_wdata(SlvpredctlModule_w_wdata),
    .rdata(SlvpredctlModule_g_rdata),
    .regOut_LVPRED_TIMEOUT(SlvpredctlModule_g_regOut_LVPRED_TIMEOUT),
    .regOut_STORESET_NO_FAST_WAKEUP(SlvpredctlModule_g_regOut_STORESET_NO_FAST_WAKEUP),
    .regOut_STORESET_WAIT_STORE(SlvpredctlModule_g_regOut_STORESET_WAIT_STORE),
    .regOut_NO_SPEC_LOAD(SlvpredctlModule_g_regOut_NO_SPEC_LOAD),
    .regOut_LVPRED_DISABLE(SlvpredctlModule_g_regOut_LVPRED_DISABLE)
  );
  SlvpredctlModule_xs u_SlvpredctlModule_i (
    .clock(clock),
    .reset(reset),
    .w_wen(SlvpredctlModule_w_wen),
    .w_wdata(SlvpredctlModule_w_wdata),
    .rdata(SlvpredctlModule_i_rdata),
    .regOut_LVPRED_TIMEOUT(SlvpredctlModule_i_regOut_LVPRED_TIMEOUT),
    .regOut_STORESET_NO_FAST_WAKEUP(SlvpredctlModule_i_regOut_STORESET_NO_FAST_WAKEUP),
    .regOut_STORESET_WAIT_STORE(SlvpredctlModule_i_regOut_STORESET_WAIT_STORE),
    .regOut_NO_SPEC_LOAD(SlvpredctlModule_i_regOut_NO_SPEC_LOAD),
    .regOut_LVPRED_DISABLE(SlvpredctlModule_i_regOut_LVPRED_DISABLE)
  );

  // SmblockctlModule
  logic SmblockctlModule_w_wen;
  logic [63:0] SmblockctlModule_w_wdata;
  logic [63:0] SmblockctlModule_rdata;
  logic [21:0] SmblockctlModule_regOut_SBUFFER_TIMEOUT;
  logic SmblockctlModule_regOut_HD_MISALIGN_LD_ENABLE;
  logic SmblockctlModule_regOut_HD_MISALIGN_ST_ENABLE;
  logic SmblockctlModule_regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE;
  logic SmblockctlModule_regOut_CACHE_ERROR_ENABLE;
  logic SmblockctlModule_regOut_SOFT_PREFETCH_ENABLE;
  logic SmblockctlModule_regOut_LDLD_VIO_CHECK_ENABLE;
  logic [3:0]  SmblockctlModule_regOut_SBUFFER_THRESHOLD;
  logic [63:0] SmblockctlModule_g_rdata;
  logic [63:0] SmblockctlModule_i_rdata;
  logic [21:0] SmblockctlModule_g_regOut_SBUFFER_TIMEOUT;
  logic [21:0] SmblockctlModule_i_regOut_SBUFFER_TIMEOUT;
  logic SmblockctlModule_g_regOut_HD_MISALIGN_LD_ENABLE;
  logic SmblockctlModule_i_regOut_HD_MISALIGN_LD_ENABLE;
  logic SmblockctlModule_g_regOut_HD_MISALIGN_ST_ENABLE;
  logic SmblockctlModule_i_regOut_HD_MISALIGN_ST_ENABLE;
  logic SmblockctlModule_g_regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE;
  logic SmblockctlModule_i_regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE;
  logic SmblockctlModule_g_regOut_CACHE_ERROR_ENABLE;
  logic SmblockctlModule_i_regOut_CACHE_ERROR_ENABLE;
  logic SmblockctlModule_g_regOut_SOFT_PREFETCH_ENABLE;
  logic SmblockctlModule_i_regOut_SOFT_PREFETCH_ENABLE;
  logic SmblockctlModule_g_regOut_LDLD_VIO_CHECK_ENABLE;
  logic SmblockctlModule_i_regOut_LDLD_VIO_CHECK_ENABLE;
  logic [3:0]  SmblockctlModule_g_regOut_SBUFFER_THRESHOLD;
  logic [3:0]  SmblockctlModule_i_regOut_SBUFFER_THRESHOLD;
  SmblockctlModule u_SmblockctlModule_g (
    .clock(clock),
    .reset(reset),
    .w_wen(SmblockctlModule_w_wen),
    .w_wdata(SmblockctlModule_w_wdata),
    .rdata(SmblockctlModule_g_rdata),
    .regOut_SBUFFER_TIMEOUT(SmblockctlModule_g_regOut_SBUFFER_TIMEOUT),
    .regOut_HD_MISALIGN_LD_ENABLE(SmblockctlModule_g_regOut_HD_MISALIGN_LD_ENABLE),
    .regOut_HD_MISALIGN_ST_ENABLE(SmblockctlModule_g_regOut_HD_MISALIGN_ST_ENABLE),
    .regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE(SmblockctlModule_g_regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE),
    .regOut_CACHE_ERROR_ENABLE(SmblockctlModule_g_regOut_CACHE_ERROR_ENABLE),
    .regOut_SOFT_PREFETCH_ENABLE(SmblockctlModule_g_regOut_SOFT_PREFETCH_ENABLE),
    .regOut_LDLD_VIO_CHECK_ENABLE(SmblockctlModule_g_regOut_LDLD_VIO_CHECK_ENABLE),
    .regOut_SBUFFER_THRESHOLD(SmblockctlModule_g_regOut_SBUFFER_THRESHOLD)
  );
  SmblockctlModule_xs u_SmblockctlModule_i (
    .clock(clock),
    .reset(reset),
    .w_wen(SmblockctlModule_w_wen),
    .w_wdata(SmblockctlModule_w_wdata),
    .rdata(SmblockctlModule_i_rdata),
    .regOut_SBUFFER_TIMEOUT(SmblockctlModule_i_regOut_SBUFFER_TIMEOUT),
    .regOut_HD_MISALIGN_LD_ENABLE(SmblockctlModule_i_regOut_HD_MISALIGN_LD_ENABLE),
    .regOut_HD_MISALIGN_ST_ENABLE(SmblockctlModule_i_regOut_HD_MISALIGN_ST_ENABLE),
    .regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE(SmblockctlModule_i_regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE),
    .regOut_CACHE_ERROR_ENABLE(SmblockctlModule_i_regOut_CACHE_ERROR_ENABLE),
    .regOut_SOFT_PREFETCH_ENABLE(SmblockctlModule_i_regOut_SOFT_PREFETCH_ENABLE),
    .regOut_LDLD_VIO_CHECK_ENABLE(SmblockctlModule_i_regOut_LDLD_VIO_CHECK_ENABLE),
    .regOut_SBUFFER_THRESHOLD(SmblockctlModule_i_regOut_SBUFFER_THRESHOLD)
  );

  // SpfctlModule
  logic SpfctlModule_w_wen;
  logic [63:0] SpfctlModule_w_wdata;
  logic [63:0] SpfctlModule_rdata;
  logic [9:0]  SpfctlModule_regOut_L2_PF_DELAY_LATENCY;
  logic SpfctlModule_regOut_L2_PF_TP_ENABLE;
  logic SpfctlModule_regOut_L2_PF_VBOP_ENABLE;
  logic SpfctlModule_regOut_L2_PF_PBOP_ENABLE;
  logic SpfctlModule_regOut_L2_PF_RECV_ENABLE;
  logic SpfctlModule_regOut_L2_PF_STORE_ONLY;
  logic SpfctlModule_regOut_L1D_PF_ENABLE_STRIDE;
  logic [5:0]  SpfctlModule_regOut_L1D_PF_ACTIVE_STRIDE;
  logic [3:0]  SpfctlModule_regOut_L1D_PF_ACTIVE_THRESHOLD;
  logic SpfctlModule_regOut_L1D_PF_ENABLE_PHT;
  logic SpfctlModule_regOut_L1D_PF_ENABLE_AGT;
  logic SpfctlModule_regOut_L1D_PF_TRAIN_ON_HIT;
  logic SpfctlModule_regOut_L1D_PF_ENABLE;
  logic SpfctlModule_regOut_L2_PF_ENABLE;
  logic SpfctlModule_regOut_L1I_PF_ENABLE;
  logic [63:0] SpfctlModule_g_rdata;
  logic [63:0] SpfctlModule_i_rdata;
  logic [9:0]  SpfctlModule_g_regOut_L2_PF_DELAY_LATENCY;
  logic [9:0]  SpfctlModule_i_regOut_L2_PF_DELAY_LATENCY;
  logic SpfctlModule_g_regOut_L2_PF_TP_ENABLE;
  logic SpfctlModule_i_regOut_L2_PF_TP_ENABLE;
  logic SpfctlModule_g_regOut_L2_PF_VBOP_ENABLE;
  logic SpfctlModule_i_regOut_L2_PF_VBOP_ENABLE;
  logic SpfctlModule_g_regOut_L2_PF_PBOP_ENABLE;
  logic SpfctlModule_i_regOut_L2_PF_PBOP_ENABLE;
  logic SpfctlModule_g_regOut_L2_PF_RECV_ENABLE;
  logic SpfctlModule_i_regOut_L2_PF_RECV_ENABLE;
  logic SpfctlModule_g_regOut_L2_PF_STORE_ONLY;
  logic SpfctlModule_i_regOut_L2_PF_STORE_ONLY;
  logic SpfctlModule_g_regOut_L1D_PF_ENABLE_STRIDE;
  logic SpfctlModule_i_regOut_L1D_PF_ENABLE_STRIDE;
  logic [5:0]  SpfctlModule_g_regOut_L1D_PF_ACTIVE_STRIDE;
  logic [5:0]  SpfctlModule_i_regOut_L1D_PF_ACTIVE_STRIDE;
  logic [3:0]  SpfctlModule_g_regOut_L1D_PF_ACTIVE_THRESHOLD;
  logic [3:0]  SpfctlModule_i_regOut_L1D_PF_ACTIVE_THRESHOLD;
  logic SpfctlModule_g_regOut_L1D_PF_ENABLE_PHT;
  logic SpfctlModule_i_regOut_L1D_PF_ENABLE_PHT;
  logic SpfctlModule_g_regOut_L1D_PF_ENABLE_AGT;
  logic SpfctlModule_i_regOut_L1D_PF_ENABLE_AGT;
  logic SpfctlModule_g_regOut_L1D_PF_TRAIN_ON_HIT;
  logic SpfctlModule_i_regOut_L1D_PF_TRAIN_ON_HIT;
  logic SpfctlModule_g_regOut_L1D_PF_ENABLE;
  logic SpfctlModule_i_regOut_L1D_PF_ENABLE;
  logic SpfctlModule_g_regOut_L2_PF_ENABLE;
  logic SpfctlModule_i_regOut_L2_PF_ENABLE;
  logic SpfctlModule_g_regOut_L1I_PF_ENABLE;
  logic SpfctlModule_i_regOut_L1I_PF_ENABLE;
  SpfctlModule u_SpfctlModule_g (
    .clock(clock),
    .reset(reset),
    .w_wen(SpfctlModule_w_wen),
    .w_wdata(SpfctlModule_w_wdata),
    .rdata(SpfctlModule_g_rdata),
    .regOut_L2_PF_DELAY_LATENCY(SpfctlModule_g_regOut_L2_PF_DELAY_LATENCY),
    .regOut_L2_PF_TP_ENABLE(SpfctlModule_g_regOut_L2_PF_TP_ENABLE),
    .regOut_L2_PF_VBOP_ENABLE(SpfctlModule_g_regOut_L2_PF_VBOP_ENABLE),
    .regOut_L2_PF_PBOP_ENABLE(SpfctlModule_g_regOut_L2_PF_PBOP_ENABLE),
    .regOut_L2_PF_RECV_ENABLE(SpfctlModule_g_regOut_L2_PF_RECV_ENABLE),
    .regOut_L2_PF_STORE_ONLY(SpfctlModule_g_regOut_L2_PF_STORE_ONLY),
    .regOut_L1D_PF_ENABLE_STRIDE(SpfctlModule_g_regOut_L1D_PF_ENABLE_STRIDE),
    .regOut_L1D_PF_ACTIVE_STRIDE(SpfctlModule_g_regOut_L1D_PF_ACTIVE_STRIDE),
    .regOut_L1D_PF_ACTIVE_THRESHOLD(SpfctlModule_g_regOut_L1D_PF_ACTIVE_THRESHOLD),
    .regOut_L1D_PF_ENABLE_PHT(SpfctlModule_g_regOut_L1D_PF_ENABLE_PHT),
    .regOut_L1D_PF_ENABLE_AGT(SpfctlModule_g_regOut_L1D_PF_ENABLE_AGT),
    .regOut_L1D_PF_TRAIN_ON_HIT(SpfctlModule_g_regOut_L1D_PF_TRAIN_ON_HIT),
    .regOut_L1D_PF_ENABLE(SpfctlModule_g_regOut_L1D_PF_ENABLE),
    .regOut_L2_PF_ENABLE(SpfctlModule_g_regOut_L2_PF_ENABLE),
    .regOut_L1I_PF_ENABLE(SpfctlModule_g_regOut_L1I_PF_ENABLE)
  );
  SpfctlModule_xs u_SpfctlModule_i (
    .clock(clock),
    .reset(reset),
    .w_wen(SpfctlModule_w_wen),
    .w_wdata(SpfctlModule_w_wdata),
    .rdata(SpfctlModule_i_rdata),
    .regOut_L2_PF_DELAY_LATENCY(SpfctlModule_i_regOut_L2_PF_DELAY_LATENCY),
    .regOut_L2_PF_TP_ENABLE(SpfctlModule_i_regOut_L2_PF_TP_ENABLE),
    .regOut_L2_PF_VBOP_ENABLE(SpfctlModule_i_regOut_L2_PF_VBOP_ENABLE),
    .regOut_L2_PF_PBOP_ENABLE(SpfctlModule_i_regOut_L2_PF_PBOP_ENABLE),
    .regOut_L2_PF_RECV_ENABLE(SpfctlModule_i_regOut_L2_PF_RECV_ENABLE),
    .regOut_L2_PF_STORE_ONLY(SpfctlModule_i_regOut_L2_PF_STORE_ONLY),
    .regOut_L1D_PF_ENABLE_STRIDE(SpfctlModule_i_regOut_L1D_PF_ENABLE_STRIDE),
    .regOut_L1D_PF_ACTIVE_STRIDE(SpfctlModule_i_regOut_L1D_PF_ACTIVE_STRIDE),
    .regOut_L1D_PF_ACTIVE_THRESHOLD(SpfctlModule_i_regOut_L1D_PF_ACTIVE_THRESHOLD),
    .regOut_L1D_PF_ENABLE_PHT(SpfctlModule_i_regOut_L1D_PF_ENABLE_PHT),
    .regOut_L1D_PF_ENABLE_AGT(SpfctlModule_i_regOut_L1D_PF_ENABLE_AGT),
    .regOut_L1D_PF_TRAIN_ON_HIT(SpfctlModule_i_regOut_L1D_PF_TRAIN_ON_HIT),
    .regOut_L1D_PF_ENABLE(SpfctlModule_i_regOut_L1D_PF_ENABLE),
    .regOut_L2_PF_ENABLE(SpfctlModule_i_regOut_L2_PF_ENABLE),
    .regOut_L1I_PF_ENABLE(SpfctlModule_i_regOut_L1I_PF_ENABLE)
  );

  // SretEventModule
  logic SretEventModule_valid;
  logic [1:0]  SretEventModule_in_privState_PRVM;
  logic SretEventModule_in_privState_V;
  logic SretEventModule_in_mstatus_SPIE;
  logic SretEventModule_in_mstatus_SPP;
  logic SretEventModule_in_mstatus_SDT;
  logic SretEventModule_in_mstatus_MDT;
  logic SretEventModule_in_hstatus_SPV;
  logic SretEventModule_in_vsstatus_SPIE;
  logic SretEventModule_in_vsstatus_SPP;
  logic [62:0] SretEventModule_in_sepc_epc;
  logic [62:0] SretEventModule_in_vsepc_epc;
  logic [3:0]  SretEventModule_in_satp_MODE;
  logic [3:0]  SretEventModule_in_vsatp_MODE;
  logic [3:0]  SretEventModule_in_hgatp_MODE;
  logic SretEventModule_out_privState_valid;
  logic [1:0]  SretEventModule_out_privState_bits_PRVM;
  logic SretEventModule_out_privState_bits_V;
  logic SretEventModule_out_mstatus_valid;
  logic SretEventModule_out_mstatus_bits_SIE;
  logic SretEventModule_out_mstatus_bits_MIE;
  logic SretEventModule_out_mstatus_bits_SPIE;
  logic SretEventModule_out_mstatus_bits_UBE;
  logic SretEventModule_out_mstatus_bits_MPIE;
  logic SretEventModule_out_mstatus_bits_SPP;
  logic [1:0]  SretEventModule_out_mstatus_bits_VS;
  logic [1:0]  SretEventModule_out_mstatus_bits_MPP;
  logic [1:0]  SretEventModule_out_mstatus_bits_FS;
  logic [1:0]  SretEventModule_out_mstatus_bits_XS;
  logic SretEventModule_out_mstatus_bits_MPRV;
  logic SretEventModule_out_mstatus_bits_SUM;
  logic SretEventModule_out_mstatus_bits_MXR;
  logic SretEventModule_out_mstatus_bits_TVM;
  logic SretEventModule_out_mstatus_bits_TW;
  logic SretEventModule_out_mstatus_bits_TSR;
  logic SretEventModule_out_mstatus_bits_SDT;
  logic [1:0]  SretEventModule_out_mstatus_bits_UXL;
  logic [1:0]  SretEventModule_out_mstatus_bits_SXL;
  logic SretEventModule_out_mstatus_bits_SBE;
  logic SretEventModule_out_mstatus_bits_MBE;
  logic SretEventModule_out_mstatus_bits_GVA;
  logic SretEventModule_out_mstatus_bits_MPV;
  logic SretEventModule_out_mstatus_bits_MDT;
  logic SretEventModule_out_mstatus_bits_SD;
  logic SretEventModule_out_hstatus_valid;
  logic SretEventModule_out_hstatus_bits_VSBE;
  logic SretEventModule_out_hstatus_bits_GVA;
  logic SretEventModule_out_hstatus_bits_SPV;
  logic SretEventModule_out_hstatus_bits_SPVP;
  logic SretEventModule_out_hstatus_bits_HU;
  logic [5:0]  SretEventModule_out_hstatus_bits_VGEIN;
  logic SretEventModule_out_hstatus_bits_VTVM;
  logic SretEventModule_out_hstatus_bits_VTW;
  logic SretEventModule_out_hstatus_bits_VTSR;
  logic [1:0]  SretEventModule_out_hstatus_bits_VSXL;
  logic [1:0]  SretEventModule_out_hstatus_bits_HUPMM;
  logic SretEventModule_out_vsstatus_valid;
  logic SretEventModule_out_vsstatus_bits_SIE;
  logic SretEventModule_out_vsstatus_bits_SPIE;
  logic SretEventModule_out_vsstatus_bits_UBE;
  logic SretEventModule_out_vsstatus_bits_SPP;
  logic [1:0]  SretEventModule_out_vsstatus_bits_VS;
  logic [1:0]  SretEventModule_out_vsstatus_bits_FS;
  logic [1:0]  SretEventModule_out_vsstatus_bits_XS;
  logic SretEventModule_out_vsstatus_bits_SUM;
  logic SretEventModule_out_vsstatus_bits_MXR;
  logic SretEventModule_out_vsstatus_bits_SDT;
  logic [1:0]  SretEventModule_out_vsstatus_bits_UXL;
  logic SretEventModule_out_vsstatus_bits_SD;
  logic SretEventModule_out_targetPc_valid;
  logic [63:0] SretEventModule_out_targetPc_bits_pc;
  logic SretEventModule_out_targetPc_bits_raiseIPF;
  logic SretEventModule_out_targetPc_bits_raiseIAF;
  logic SretEventModule_out_targetPc_bits_raiseIGPF;
  logic SretEventModule_outSDT_vsstatus_valid;
  logic SretEventModule_g_out_privState_valid;
  logic SretEventModule_i_out_privState_valid;
  logic [1:0]  SretEventModule_g_out_privState_bits_PRVM;
  logic [1:0]  SretEventModule_i_out_privState_bits_PRVM;
  logic SretEventModule_g_out_privState_bits_V;
  logic SretEventModule_i_out_privState_bits_V;
  logic SretEventModule_g_out_mstatus_valid;
  logic SretEventModule_i_out_mstatus_valid;
  logic SretEventModule_g_out_mstatus_bits_SIE;
  logic SretEventModule_i_out_mstatus_bits_SIE;
  logic SretEventModule_g_out_mstatus_bits_MIE;
  logic SretEventModule_i_out_mstatus_bits_MIE;
  logic SretEventModule_g_out_mstatus_bits_SPIE;
  logic SretEventModule_i_out_mstatus_bits_SPIE;
  logic SretEventModule_g_out_mstatus_bits_UBE;
  logic SretEventModule_i_out_mstatus_bits_UBE;
  logic SretEventModule_g_out_mstatus_bits_MPIE;
  logic SretEventModule_i_out_mstatus_bits_MPIE;
  logic SretEventModule_g_out_mstatus_bits_SPP;
  logic SretEventModule_i_out_mstatus_bits_SPP;
  logic [1:0]  SretEventModule_g_out_mstatus_bits_VS;
  logic [1:0]  SretEventModule_i_out_mstatus_bits_VS;
  logic [1:0]  SretEventModule_g_out_mstatus_bits_MPP;
  logic [1:0]  SretEventModule_i_out_mstatus_bits_MPP;
  logic [1:0]  SretEventModule_g_out_mstatus_bits_FS;
  logic [1:0]  SretEventModule_i_out_mstatus_bits_FS;
  logic [1:0]  SretEventModule_g_out_mstatus_bits_XS;
  logic [1:0]  SretEventModule_i_out_mstatus_bits_XS;
  logic SretEventModule_g_out_mstatus_bits_MPRV;
  logic SretEventModule_i_out_mstatus_bits_MPRV;
  logic SretEventModule_g_out_mstatus_bits_SUM;
  logic SretEventModule_i_out_mstatus_bits_SUM;
  logic SretEventModule_g_out_mstatus_bits_MXR;
  logic SretEventModule_i_out_mstatus_bits_MXR;
  logic SretEventModule_g_out_mstatus_bits_TVM;
  logic SretEventModule_i_out_mstatus_bits_TVM;
  logic SretEventModule_g_out_mstatus_bits_TW;
  logic SretEventModule_i_out_mstatus_bits_TW;
  logic SretEventModule_g_out_mstatus_bits_TSR;
  logic SretEventModule_i_out_mstatus_bits_TSR;
  logic SretEventModule_g_out_mstatus_bits_SDT;
  logic SretEventModule_i_out_mstatus_bits_SDT;
  logic [1:0]  SretEventModule_g_out_mstatus_bits_UXL;
  logic [1:0]  SretEventModule_i_out_mstatus_bits_UXL;
  logic [1:0]  SretEventModule_g_out_mstatus_bits_SXL;
  logic [1:0]  SretEventModule_i_out_mstatus_bits_SXL;
  logic SretEventModule_g_out_mstatus_bits_SBE;
  logic SretEventModule_i_out_mstatus_bits_SBE;
  logic SretEventModule_g_out_mstatus_bits_MBE;
  logic SretEventModule_i_out_mstatus_bits_MBE;
  logic SretEventModule_g_out_mstatus_bits_GVA;
  logic SretEventModule_i_out_mstatus_bits_GVA;
  logic SretEventModule_g_out_mstatus_bits_MPV;
  logic SretEventModule_i_out_mstatus_bits_MPV;
  logic SretEventModule_g_out_mstatus_bits_MDT;
  logic SretEventModule_i_out_mstatus_bits_MDT;
  logic SretEventModule_g_out_mstatus_bits_SD;
  logic SretEventModule_i_out_mstatus_bits_SD;
  logic SretEventModule_g_out_hstatus_valid;
  logic SretEventModule_i_out_hstatus_valid;
  logic SretEventModule_g_out_hstatus_bits_VSBE;
  logic SretEventModule_i_out_hstatus_bits_VSBE;
  logic SretEventModule_g_out_hstatus_bits_GVA;
  logic SretEventModule_i_out_hstatus_bits_GVA;
  logic SretEventModule_g_out_hstatus_bits_SPV;
  logic SretEventModule_i_out_hstatus_bits_SPV;
  logic SretEventModule_g_out_hstatus_bits_SPVP;
  logic SretEventModule_i_out_hstatus_bits_SPVP;
  logic SretEventModule_g_out_hstatus_bits_HU;
  logic SretEventModule_i_out_hstatus_bits_HU;
  logic [5:0]  SretEventModule_g_out_hstatus_bits_VGEIN;
  logic [5:0]  SretEventModule_i_out_hstatus_bits_VGEIN;
  logic SretEventModule_g_out_hstatus_bits_VTVM;
  logic SretEventModule_i_out_hstatus_bits_VTVM;
  logic SretEventModule_g_out_hstatus_bits_VTW;
  logic SretEventModule_i_out_hstatus_bits_VTW;
  logic SretEventModule_g_out_hstatus_bits_VTSR;
  logic SretEventModule_i_out_hstatus_bits_VTSR;
  logic [1:0]  SretEventModule_g_out_hstatus_bits_VSXL;
  logic [1:0]  SretEventModule_i_out_hstatus_bits_VSXL;
  logic [1:0]  SretEventModule_g_out_hstatus_bits_HUPMM;
  logic [1:0]  SretEventModule_i_out_hstatus_bits_HUPMM;
  logic SretEventModule_g_out_vsstatus_valid;
  logic SretEventModule_i_out_vsstatus_valid;
  logic SretEventModule_g_out_vsstatus_bits_SIE;
  logic SretEventModule_i_out_vsstatus_bits_SIE;
  logic SretEventModule_g_out_vsstatus_bits_SPIE;
  logic SretEventModule_i_out_vsstatus_bits_SPIE;
  logic SretEventModule_g_out_vsstatus_bits_UBE;
  logic SretEventModule_i_out_vsstatus_bits_UBE;
  logic SretEventModule_g_out_vsstatus_bits_SPP;
  logic SretEventModule_i_out_vsstatus_bits_SPP;
  logic [1:0]  SretEventModule_g_out_vsstatus_bits_VS;
  logic [1:0]  SretEventModule_i_out_vsstatus_bits_VS;
  logic [1:0]  SretEventModule_g_out_vsstatus_bits_FS;
  logic [1:0]  SretEventModule_i_out_vsstatus_bits_FS;
  logic [1:0]  SretEventModule_g_out_vsstatus_bits_XS;
  logic [1:0]  SretEventModule_i_out_vsstatus_bits_XS;
  logic SretEventModule_g_out_vsstatus_bits_SUM;
  logic SretEventModule_i_out_vsstatus_bits_SUM;
  logic SretEventModule_g_out_vsstatus_bits_MXR;
  logic SretEventModule_i_out_vsstatus_bits_MXR;
  logic SretEventModule_g_out_vsstatus_bits_SDT;
  logic SretEventModule_i_out_vsstatus_bits_SDT;
  logic [1:0]  SretEventModule_g_out_vsstatus_bits_UXL;
  logic [1:0]  SretEventModule_i_out_vsstatus_bits_UXL;
  logic SretEventModule_g_out_vsstatus_bits_SD;
  logic SretEventModule_i_out_vsstatus_bits_SD;
  logic SretEventModule_g_out_targetPc_valid;
  logic SretEventModule_i_out_targetPc_valid;
  logic [63:0] SretEventModule_g_out_targetPc_bits_pc;
  logic [63:0] SretEventModule_i_out_targetPc_bits_pc;
  logic SretEventModule_g_out_targetPc_bits_raiseIPF;
  logic SretEventModule_i_out_targetPc_bits_raiseIPF;
  logic SretEventModule_g_out_targetPc_bits_raiseIAF;
  logic SretEventModule_i_out_targetPc_bits_raiseIAF;
  logic SretEventModule_g_out_targetPc_bits_raiseIGPF;
  logic SretEventModule_i_out_targetPc_bits_raiseIGPF;
  logic SretEventModule_g_outSDT_vsstatus_valid;
  logic SretEventModule_i_outSDT_vsstatus_valid;
  SretEventModule u_SretEventModule_g (
    .valid(SretEventModule_valid),
    .in_privState_PRVM(SretEventModule_in_privState_PRVM),
    .in_privState_V(SretEventModule_in_privState_V),
    .in_mstatus_SPIE(SretEventModule_in_mstatus_SPIE),
    .in_mstatus_SPP(SretEventModule_in_mstatus_SPP),
    .in_mstatus_SDT(SretEventModule_in_mstatus_SDT),
    .in_mstatus_MDT(SretEventModule_in_mstatus_MDT),
    .in_hstatus_SPV(SretEventModule_in_hstatus_SPV),
    .in_vsstatus_SPIE(SretEventModule_in_vsstatus_SPIE),
    .in_vsstatus_SPP(SretEventModule_in_vsstatus_SPP),
    .in_sepc_epc(SretEventModule_in_sepc_epc),
    .in_vsepc_epc(SretEventModule_in_vsepc_epc),
    .in_satp_MODE(SretEventModule_in_satp_MODE),
    .in_vsatp_MODE(SretEventModule_in_vsatp_MODE),
    .in_hgatp_MODE(SretEventModule_in_hgatp_MODE),
    .out_privState_valid(SretEventModule_g_out_privState_valid),
    .out_privState_bits_PRVM(SretEventModule_g_out_privState_bits_PRVM),
    .out_privState_bits_V(SretEventModule_g_out_privState_bits_V),
    .out_mstatus_valid(SretEventModule_g_out_mstatus_valid),
    .out_mstatus_bits_SIE(SretEventModule_g_out_mstatus_bits_SIE),
    .out_mstatus_bits_MIE(SretEventModule_g_out_mstatus_bits_MIE),
    .out_mstatus_bits_SPIE(SretEventModule_g_out_mstatus_bits_SPIE),
    .out_mstatus_bits_UBE(SretEventModule_g_out_mstatus_bits_UBE),
    .out_mstatus_bits_MPIE(SretEventModule_g_out_mstatus_bits_MPIE),
    .out_mstatus_bits_SPP(SretEventModule_g_out_mstatus_bits_SPP),
    .out_mstatus_bits_VS(SretEventModule_g_out_mstatus_bits_VS),
    .out_mstatus_bits_MPP(SretEventModule_g_out_mstatus_bits_MPP),
    .out_mstatus_bits_FS(SretEventModule_g_out_mstatus_bits_FS),
    .out_mstatus_bits_XS(SretEventModule_g_out_mstatus_bits_XS),
    .out_mstatus_bits_MPRV(SretEventModule_g_out_mstatus_bits_MPRV),
    .out_mstatus_bits_SUM(SretEventModule_g_out_mstatus_bits_SUM),
    .out_mstatus_bits_MXR(SretEventModule_g_out_mstatus_bits_MXR),
    .out_mstatus_bits_TVM(SretEventModule_g_out_mstatus_bits_TVM),
    .out_mstatus_bits_TW(SretEventModule_g_out_mstatus_bits_TW),
    .out_mstatus_bits_TSR(SretEventModule_g_out_mstatus_bits_TSR),
    .out_mstatus_bits_SDT(SretEventModule_g_out_mstatus_bits_SDT),
    .out_mstatus_bits_UXL(SretEventModule_g_out_mstatus_bits_UXL),
    .out_mstatus_bits_SXL(SretEventModule_g_out_mstatus_bits_SXL),
    .out_mstatus_bits_SBE(SretEventModule_g_out_mstatus_bits_SBE),
    .out_mstatus_bits_MBE(SretEventModule_g_out_mstatus_bits_MBE),
    .out_mstatus_bits_GVA(SretEventModule_g_out_mstatus_bits_GVA),
    .out_mstatus_bits_MPV(SretEventModule_g_out_mstatus_bits_MPV),
    .out_mstatus_bits_MDT(SretEventModule_g_out_mstatus_bits_MDT),
    .out_mstatus_bits_SD(SretEventModule_g_out_mstatus_bits_SD),
    .out_hstatus_valid(SretEventModule_g_out_hstatus_valid),
    .out_hstatus_bits_VSBE(SretEventModule_g_out_hstatus_bits_VSBE),
    .out_hstatus_bits_GVA(SretEventModule_g_out_hstatus_bits_GVA),
    .out_hstatus_bits_SPV(SretEventModule_g_out_hstatus_bits_SPV),
    .out_hstatus_bits_SPVP(SretEventModule_g_out_hstatus_bits_SPVP),
    .out_hstatus_bits_HU(SretEventModule_g_out_hstatus_bits_HU),
    .out_hstatus_bits_VGEIN(SretEventModule_g_out_hstatus_bits_VGEIN),
    .out_hstatus_bits_VTVM(SretEventModule_g_out_hstatus_bits_VTVM),
    .out_hstatus_bits_VTW(SretEventModule_g_out_hstatus_bits_VTW),
    .out_hstatus_bits_VTSR(SretEventModule_g_out_hstatus_bits_VTSR),
    .out_hstatus_bits_VSXL(SretEventModule_g_out_hstatus_bits_VSXL),
    .out_hstatus_bits_HUPMM(SretEventModule_g_out_hstatus_bits_HUPMM),
    .out_vsstatus_valid(SretEventModule_g_out_vsstatus_valid),
    .out_vsstatus_bits_SIE(SretEventModule_g_out_vsstatus_bits_SIE),
    .out_vsstatus_bits_SPIE(SretEventModule_g_out_vsstatus_bits_SPIE),
    .out_vsstatus_bits_UBE(SretEventModule_g_out_vsstatus_bits_UBE),
    .out_vsstatus_bits_SPP(SretEventModule_g_out_vsstatus_bits_SPP),
    .out_vsstatus_bits_VS(SretEventModule_g_out_vsstatus_bits_VS),
    .out_vsstatus_bits_FS(SretEventModule_g_out_vsstatus_bits_FS),
    .out_vsstatus_bits_XS(SretEventModule_g_out_vsstatus_bits_XS),
    .out_vsstatus_bits_SUM(SretEventModule_g_out_vsstatus_bits_SUM),
    .out_vsstatus_bits_MXR(SretEventModule_g_out_vsstatus_bits_MXR),
    .out_vsstatus_bits_SDT(SretEventModule_g_out_vsstatus_bits_SDT),
    .out_vsstatus_bits_UXL(SretEventModule_g_out_vsstatus_bits_UXL),
    .out_vsstatus_bits_SD(SretEventModule_g_out_vsstatus_bits_SD),
    .out_targetPc_valid(SretEventModule_g_out_targetPc_valid),
    .out_targetPc_bits_pc(SretEventModule_g_out_targetPc_bits_pc),
    .out_targetPc_bits_raiseIPF(SretEventModule_g_out_targetPc_bits_raiseIPF),
    .out_targetPc_bits_raiseIAF(SretEventModule_g_out_targetPc_bits_raiseIAF),
    .out_targetPc_bits_raiseIGPF(SretEventModule_g_out_targetPc_bits_raiseIGPF),
    .outSDT_vsstatus_valid(SretEventModule_g_outSDT_vsstatus_valid)
  );
  SretEventModule_xs u_SretEventModule_i (
    .valid(SretEventModule_valid),
    .in_privState_PRVM(SretEventModule_in_privState_PRVM),
    .in_privState_V(SretEventModule_in_privState_V),
    .in_mstatus_SPIE(SretEventModule_in_mstatus_SPIE),
    .in_mstatus_SPP(SretEventModule_in_mstatus_SPP),
    .in_mstatus_SDT(SretEventModule_in_mstatus_SDT),
    .in_mstatus_MDT(SretEventModule_in_mstatus_MDT),
    .in_hstatus_SPV(SretEventModule_in_hstatus_SPV),
    .in_vsstatus_SPIE(SretEventModule_in_vsstatus_SPIE),
    .in_vsstatus_SPP(SretEventModule_in_vsstatus_SPP),
    .in_sepc_epc(SretEventModule_in_sepc_epc),
    .in_vsepc_epc(SretEventModule_in_vsepc_epc),
    .in_satp_MODE(SretEventModule_in_satp_MODE),
    .in_vsatp_MODE(SretEventModule_in_vsatp_MODE),
    .in_hgatp_MODE(SretEventModule_in_hgatp_MODE),
    .out_privState_valid(SretEventModule_i_out_privState_valid),
    .out_privState_bits_PRVM(SretEventModule_i_out_privState_bits_PRVM),
    .out_privState_bits_V(SretEventModule_i_out_privState_bits_V),
    .out_mstatus_valid(SretEventModule_i_out_mstatus_valid),
    .out_mstatus_bits_SIE(SretEventModule_i_out_mstatus_bits_SIE),
    .out_mstatus_bits_MIE(SretEventModule_i_out_mstatus_bits_MIE),
    .out_mstatus_bits_SPIE(SretEventModule_i_out_mstatus_bits_SPIE),
    .out_mstatus_bits_UBE(SretEventModule_i_out_mstatus_bits_UBE),
    .out_mstatus_bits_MPIE(SretEventModule_i_out_mstatus_bits_MPIE),
    .out_mstatus_bits_SPP(SretEventModule_i_out_mstatus_bits_SPP),
    .out_mstatus_bits_VS(SretEventModule_i_out_mstatus_bits_VS),
    .out_mstatus_bits_MPP(SretEventModule_i_out_mstatus_bits_MPP),
    .out_mstatus_bits_FS(SretEventModule_i_out_mstatus_bits_FS),
    .out_mstatus_bits_XS(SretEventModule_i_out_mstatus_bits_XS),
    .out_mstatus_bits_MPRV(SretEventModule_i_out_mstatus_bits_MPRV),
    .out_mstatus_bits_SUM(SretEventModule_i_out_mstatus_bits_SUM),
    .out_mstatus_bits_MXR(SretEventModule_i_out_mstatus_bits_MXR),
    .out_mstatus_bits_TVM(SretEventModule_i_out_mstatus_bits_TVM),
    .out_mstatus_bits_TW(SretEventModule_i_out_mstatus_bits_TW),
    .out_mstatus_bits_TSR(SretEventModule_i_out_mstatus_bits_TSR),
    .out_mstatus_bits_SDT(SretEventModule_i_out_mstatus_bits_SDT),
    .out_mstatus_bits_UXL(SretEventModule_i_out_mstatus_bits_UXL),
    .out_mstatus_bits_SXL(SretEventModule_i_out_mstatus_bits_SXL),
    .out_mstatus_bits_SBE(SretEventModule_i_out_mstatus_bits_SBE),
    .out_mstatus_bits_MBE(SretEventModule_i_out_mstatus_bits_MBE),
    .out_mstatus_bits_GVA(SretEventModule_i_out_mstatus_bits_GVA),
    .out_mstatus_bits_MPV(SretEventModule_i_out_mstatus_bits_MPV),
    .out_mstatus_bits_MDT(SretEventModule_i_out_mstatus_bits_MDT),
    .out_mstatus_bits_SD(SretEventModule_i_out_mstatus_bits_SD),
    .out_hstatus_valid(SretEventModule_i_out_hstatus_valid),
    .out_hstatus_bits_VSBE(SretEventModule_i_out_hstatus_bits_VSBE),
    .out_hstatus_bits_GVA(SretEventModule_i_out_hstatus_bits_GVA),
    .out_hstatus_bits_SPV(SretEventModule_i_out_hstatus_bits_SPV),
    .out_hstatus_bits_SPVP(SretEventModule_i_out_hstatus_bits_SPVP),
    .out_hstatus_bits_HU(SretEventModule_i_out_hstatus_bits_HU),
    .out_hstatus_bits_VGEIN(SretEventModule_i_out_hstatus_bits_VGEIN),
    .out_hstatus_bits_VTVM(SretEventModule_i_out_hstatus_bits_VTVM),
    .out_hstatus_bits_VTW(SretEventModule_i_out_hstatus_bits_VTW),
    .out_hstatus_bits_VTSR(SretEventModule_i_out_hstatus_bits_VTSR),
    .out_hstatus_bits_VSXL(SretEventModule_i_out_hstatus_bits_VSXL),
    .out_hstatus_bits_HUPMM(SretEventModule_i_out_hstatus_bits_HUPMM),
    .out_vsstatus_valid(SretEventModule_i_out_vsstatus_valid),
    .out_vsstatus_bits_SIE(SretEventModule_i_out_vsstatus_bits_SIE),
    .out_vsstatus_bits_SPIE(SretEventModule_i_out_vsstatus_bits_SPIE),
    .out_vsstatus_bits_UBE(SretEventModule_i_out_vsstatus_bits_UBE),
    .out_vsstatus_bits_SPP(SretEventModule_i_out_vsstatus_bits_SPP),
    .out_vsstatus_bits_VS(SretEventModule_i_out_vsstatus_bits_VS),
    .out_vsstatus_bits_FS(SretEventModule_i_out_vsstatus_bits_FS),
    .out_vsstatus_bits_XS(SretEventModule_i_out_vsstatus_bits_XS),
    .out_vsstatus_bits_SUM(SretEventModule_i_out_vsstatus_bits_SUM),
    .out_vsstatus_bits_MXR(SretEventModule_i_out_vsstatus_bits_MXR),
    .out_vsstatus_bits_SDT(SretEventModule_i_out_vsstatus_bits_SDT),
    .out_vsstatus_bits_UXL(SretEventModule_i_out_vsstatus_bits_UXL),
    .out_vsstatus_bits_SD(SretEventModule_i_out_vsstatus_bits_SD),
    .out_targetPc_valid(SretEventModule_i_out_targetPc_valid),
    .out_targetPc_bits_pc(SretEventModule_i_out_targetPc_bits_pc),
    .out_targetPc_bits_raiseIPF(SretEventModule_i_out_targetPc_bits_raiseIPF),
    .out_targetPc_bits_raiseIAF(SretEventModule_i_out_targetPc_bits_raiseIAF),
    .out_targetPc_bits_raiseIGPF(SretEventModule_i_out_targetPc_bits_raiseIGPF),
    .outSDT_vsstatus_valid(SretEventModule_i_outSDT_vsstatus_valid)
  );

  // SrnctlModule
  logic SrnctlModule_w_wen;
  logic [63:0] SrnctlModule_w_wdata;
  logic [63:0] SrnctlModule_rdata;
  logic SrnctlModule_regOut_WFI_ENABLE;
  logic SrnctlModule_regOut_FUSION_ENABLE;
  logic [63:0] SrnctlModule_g_rdata;
  logic [63:0] SrnctlModule_i_rdata;
  logic SrnctlModule_g_regOut_WFI_ENABLE;
  logic SrnctlModule_i_regOut_WFI_ENABLE;
  logic SrnctlModule_g_regOut_FUSION_ENABLE;
  logic SrnctlModule_i_regOut_FUSION_ENABLE;
  SrnctlModule u_SrnctlModule_g (
    .clock(clock),
    .reset(reset),
    .w_wen(SrnctlModule_w_wen),
    .w_wdata(SrnctlModule_w_wdata),
    .rdata(SrnctlModule_g_rdata),
    .regOut_WFI_ENABLE(SrnctlModule_g_regOut_WFI_ENABLE),
    .regOut_FUSION_ENABLE(SrnctlModule_g_regOut_FUSION_ENABLE)
  );
  SrnctlModule_xs u_SrnctlModule_i (
    .clock(clock),
    .reset(reset),
    .w_wen(SrnctlModule_w_wen),
    .w_wdata(SrnctlModule_w_wdata),
    .rdata(SrnctlModule_i_rdata),
    .regOut_WFI_ENABLE(SrnctlModule_i_regOut_WFI_ENABLE),
    .regOut_FUSION_ENABLE(SrnctlModule_i_regOut_FUSION_ENABLE)
  );

  // Sstateen0Module
  logic Sstateen0Module_w_wen;
  logic [63:0] Sstateen0Module_w_wdata;
  logic [31:0] Sstateen0Module_rdata;
  logic Sstateen0Module_regOut_JVT;
  logic Sstateen0Module_regOut_FCSR;
  logic Sstateen0Module_regOut_C;
  logic Sstateen0Module_fromMstateen0_SE0;
  logic Sstateen0Module_fromMstateen0_ENVCFG;
  logic Sstateen0Module_fromMstateen0_CSRIND;
  logic Sstateen0Module_fromMstateen0_AIA;
  logic Sstateen0Module_fromMstateen0_IMSIC;
  logic Sstateen0Module_fromMstateen0_CONTEXT;
  logic Sstateen0Module_fromMstateen0_C;
  logic Sstateen0Module_fromHstateen0_JVT;
  logic Sstateen0Module_fromHstateen0_FCSR;
  logic Sstateen0Module_fromHstateen0_C;
  logic Sstateen0Module_fromHstateen0_SE0;
  logic Sstateen0Module_fromHstateen0_ENVCFG;
  logic Sstateen0Module_fromHstateen0_CSRIND;
  logic Sstateen0Module_fromHstateen0_AIA;
  logic Sstateen0Module_fromHstateen0_IMSIC;
  logic Sstateen0Module_fromHstateen0_CONTEXT;
  logic Sstateen0Module_privState_V;
  logic [31:0] Sstateen0Module_g_rdata;
  logic [31:0] Sstateen0Module_i_rdata;
  logic Sstateen0Module_g_regOut_JVT;
  logic Sstateen0Module_i_regOut_JVT;
  logic Sstateen0Module_g_regOut_FCSR;
  logic Sstateen0Module_i_regOut_FCSR;
  logic Sstateen0Module_g_regOut_C;
  logic Sstateen0Module_i_regOut_C;
  Sstateen0Module u_Sstateen0Module_g (
    .clock(clock),
    .reset(reset),
    .w_wen(Sstateen0Module_w_wen),
    .w_wdata(Sstateen0Module_w_wdata),
    .rdata(Sstateen0Module_g_rdata),
    .regOut_JVT(Sstateen0Module_g_regOut_JVT),
    .regOut_FCSR(Sstateen0Module_g_regOut_FCSR),
    .regOut_C(Sstateen0Module_g_regOut_C),
    .fromMstateen0_SE0(Sstateen0Module_fromMstateen0_SE0),
    .fromMstateen0_ENVCFG(Sstateen0Module_fromMstateen0_ENVCFG),
    .fromMstateen0_CSRIND(Sstateen0Module_fromMstateen0_CSRIND),
    .fromMstateen0_AIA(Sstateen0Module_fromMstateen0_AIA),
    .fromMstateen0_IMSIC(Sstateen0Module_fromMstateen0_IMSIC),
    .fromMstateen0_CONTEXT(Sstateen0Module_fromMstateen0_CONTEXT),
    .fromMstateen0_C(Sstateen0Module_fromMstateen0_C),
    .fromHstateen0_JVT(Sstateen0Module_fromHstateen0_JVT),
    .fromHstateen0_FCSR(Sstateen0Module_fromHstateen0_FCSR),
    .fromHstateen0_C(Sstateen0Module_fromHstateen0_C),
    .fromHstateen0_SE0(Sstateen0Module_fromHstateen0_SE0),
    .fromHstateen0_ENVCFG(Sstateen0Module_fromHstateen0_ENVCFG),
    .fromHstateen0_CSRIND(Sstateen0Module_fromHstateen0_CSRIND),
    .fromHstateen0_AIA(Sstateen0Module_fromHstateen0_AIA),
    .fromHstateen0_IMSIC(Sstateen0Module_fromHstateen0_IMSIC),
    .fromHstateen0_CONTEXT(Sstateen0Module_fromHstateen0_CONTEXT),
    .privState_V(Sstateen0Module_privState_V)
  );
  Sstateen0Module_xs u_Sstateen0Module_i (
    .clock(clock),
    .reset(reset),
    .w_wen(Sstateen0Module_w_wen),
    .w_wdata(Sstateen0Module_w_wdata),
    .rdata(Sstateen0Module_i_rdata),
    .regOut_JVT(Sstateen0Module_i_regOut_JVT),
    .regOut_FCSR(Sstateen0Module_i_regOut_FCSR),
    .regOut_C(Sstateen0Module_i_regOut_C),
    .fromMstateen0_SE0(Sstateen0Module_fromMstateen0_SE0),
    .fromMstateen0_ENVCFG(Sstateen0Module_fromMstateen0_ENVCFG),
    .fromMstateen0_CSRIND(Sstateen0Module_fromMstateen0_CSRIND),
    .fromMstateen0_AIA(Sstateen0Module_fromMstateen0_AIA),
    .fromMstateen0_IMSIC(Sstateen0Module_fromMstateen0_IMSIC),
    .fromMstateen0_CONTEXT(Sstateen0Module_fromMstateen0_CONTEXT),
    .fromMstateen0_C(Sstateen0Module_fromMstateen0_C),
    .fromHstateen0_JVT(Sstateen0Module_fromHstateen0_JVT),
    .fromHstateen0_FCSR(Sstateen0Module_fromHstateen0_FCSR),
    .fromHstateen0_C(Sstateen0Module_fromHstateen0_C),
    .fromHstateen0_SE0(Sstateen0Module_fromHstateen0_SE0),
    .fromHstateen0_ENVCFG(Sstateen0Module_fromHstateen0_ENVCFG),
    .fromHstateen0_CSRIND(Sstateen0Module_fromHstateen0_CSRIND),
    .fromHstateen0_AIA(Sstateen0Module_fromHstateen0_AIA),
    .fromHstateen0_IMSIC(Sstateen0Module_fromHstateen0_IMSIC),
    .fromHstateen0_CONTEXT(Sstateen0Module_fromHstateen0_CONTEXT),
    .privState_V(Sstateen0Module_privState_V)
  );

  // StimecmpModule
  logic StimecmpModule_w_wen;
  logic [63:0] StimecmpModule_w_wdata;
  logic [63:0] StimecmpModule_rdata;
  logic [63:0] StimecmpModule_regOut_stimecmp;
  logic [63:0] StimecmpModule_g_rdata;
  logic [63:0] StimecmpModule_i_rdata;
  logic [63:0] StimecmpModule_g_regOut_stimecmp;
  logic [63:0] StimecmpModule_i_regOut_stimecmp;
  StimecmpModule u_StimecmpModule_g (
    .clock(clock),
    .reset(reset),
    .w_wen(StimecmpModule_w_wen),
    .w_wdata(StimecmpModule_w_wdata),
    .rdata(StimecmpModule_g_rdata),
    .regOut_stimecmp(StimecmpModule_g_regOut_stimecmp)
  );
  StimecmpModule_xs u_StimecmpModule_i (
    .clock(clock),
    .reset(reset),
    .w_wen(StimecmpModule_w_wen),
    .w_wdata(StimecmpModule_w_wdata),
    .rdata(StimecmpModule_i_rdata),
    .regOut_stimecmp(StimecmpModule_i_regOut_stimecmp)
  );

  // TrapInstMod
  logic TrapInstMod_io_fromDecode_trapInstInfo_valid;
  logic [31:0] TrapInstMod_io_fromDecode_trapInstInfo_bits_instr;
  logic TrapInstMod_io_fromDecode_trapInstInfo_bits_ftqPtr_flag;
  logic [5:0]  TrapInstMod_io_fromDecode_trapInstInfo_bits_ftqPtr_value;
  logic [3:0]  TrapInstMod_io_fromDecode_trapInstInfo_bits_ftqOffset;
  logic TrapInstMod_io_fromRob_flush_valid;
  logic TrapInstMod_io_fromRob_flush_bits_ftqPtr_flag;
  logic [5:0]  TrapInstMod_io_fromRob_flush_bits_ftqPtr_value;
  logic [3:0]  TrapInstMod_io_fromRob_flush_bits_ftqOffset;
  logic TrapInstMod_io_fromRob_isInterrupt_valid;
  logic TrapInstMod_io_fromRob_isInterrupt_bits;
  logic TrapInstMod_io_faultCsrUop_valid;
  logic [8:0]  TrapInstMod_io_faultCsrUop_bits_fuOpType;
  logic [21:0] TrapInstMod_io_faultCsrUop_bits_imm;
  logic TrapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_flag;
  logic [5:0]  TrapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_value;
  logic [3:0]  TrapInstMod_io_faultCsrUop_bits_ftqInfo_ftqOffset;
  logic TrapInstMod_io_readClear;
  logic TrapInstMod_io_currentTrapInst_valid;
  logic [31:0] TrapInstMod_io_currentTrapInst_bits;
  logic TrapInstMod_g_io_currentTrapInst_valid;
  logic TrapInstMod_i_io_currentTrapInst_valid;
  logic [31:0] TrapInstMod_g_io_currentTrapInst_bits;
  logic [31:0] TrapInstMod_i_io_currentTrapInst_bits;
  TrapInstMod u_TrapInstMod_g (
    .clock(clock),
    .reset(reset),
    .io_fromDecode_trapInstInfo_valid(TrapInstMod_io_fromDecode_trapInstInfo_valid),
    .io_fromDecode_trapInstInfo_bits_instr(TrapInstMod_io_fromDecode_trapInstInfo_bits_instr),
    .io_fromDecode_trapInstInfo_bits_ftqPtr_flag(TrapInstMod_io_fromDecode_trapInstInfo_bits_ftqPtr_flag),
    .io_fromDecode_trapInstInfo_bits_ftqPtr_value(TrapInstMod_io_fromDecode_trapInstInfo_bits_ftqPtr_value),
    .io_fromDecode_trapInstInfo_bits_ftqOffset(TrapInstMod_io_fromDecode_trapInstInfo_bits_ftqOffset),
    .io_fromRob_flush_valid(TrapInstMod_io_fromRob_flush_valid),
    .io_fromRob_flush_bits_ftqPtr_flag(TrapInstMod_io_fromRob_flush_bits_ftqPtr_flag),
    .io_fromRob_flush_bits_ftqPtr_value(TrapInstMod_io_fromRob_flush_bits_ftqPtr_value),
    .io_fromRob_flush_bits_ftqOffset(TrapInstMod_io_fromRob_flush_bits_ftqOffset),
    .io_fromRob_isInterrupt_valid(TrapInstMod_io_fromRob_isInterrupt_valid),
    .io_fromRob_isInterrupt_bits(TrapInstMod_io_fromRob_isInterrupt_bits),
    .io_faultCsrUop_valid(TrapInstMod_io_faultCsrUop_valid),
    .io_faultCsrUop_bits_fuOpType(TrapInstMod_io_faultCsrUop_bits_fuOpType),
    .io_faultCsrUop_bits_imm(TrapInstMod_io_faultCsrUop_bits_imm),
    .io_faultCsrUop_bits_ftqInfo_ftqPtr_flag(TrapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_flag),
    .io_faultCsrUop_bits_ftqInfo_ftqPtr_value(TrapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_value),
    .io_faultCsrUop_bits_ftqInfo_ftqOffset(TrapInstMod_io_faultCsrUop_bits_ftqInfo_ftqOffset),
    .io_readClear(TrapInstMod_io_readClear),
    .io_currentTrapInst_valid(TrapInstMod_g_io_currentTrapInst_valid),
    .io_currentTrapInst_bits(TrapInstMod_g_io_currentTrapInst_bits)
  );
  TrapInstMod_xs u_TrapInstMod_i (
    .clock(clock),
    .reset(reset),
    .io_fromDecode_trapInstInfo_valid(TrapInstMod_io_fromDecode_trapInstInfo_valid),
    .io_fromDecode_trapInstInfo_bits_instr(TrapInstMod_io_fromDecode_trapInstInfo_bits_instr),
    .io_fromDecode_trapInstInfo_bits_ftqPtr_flag(TrapInstMod_io_fromDecode_trapInstInfo_bits_ftqPtr_flag),
    .io_fromDecode_trapInstInfo_bits_ftqPtr_value(TrapInstMod_io_fromDecode_trapInstInfo_bits_ftqPtr_value),
    .io_fromDecode_trapInstInfo_bits_ftqOffset(TrapInstMod_io_fromDecode_trapInstInfo_bits_ftqOffset),
    .io_fromRob_flush_valid(TrapInstMod_io_fromRob_flush_valid),
    .io_fromRob_flush_bits_ftqPtr_flag(TrapInstMod_io_fromRob_flush_bits_ftqPtr_flag),
    .io_fromRob_flush_bits_ftqPtr_value(TrapInstMod_io_fromRob_flush_bits_ftqPtr_value),
    .io_fromRob_flush_bits_ftqOffset(TrapInstMod_io_fromRob_flush_bits_ftqOffset),
    .io_fromRob_isInterrupt_valid(TrapInstMod_io_fromRob_isInterrupt_valid),
    .io_fromRob_isInterrupt_bits(TrapInstMod_io_fromRob_isInterrupt_bits),
    .io_faultCsrUop_valid(TrapInstMod_io_faultCsrUop_valid),
    .io_faultCsrUop_bits_fuOpType(TrapInstMod_io_faultCsrUop_bits_fuOpType),
    .io_faultCsrUop_bits_imm(TrapInstMod_io_faultCsrUop_bits_imm),
    .io_faultCsrUop_bits_ftqInfo_ftqPtr_flag(TrapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_flag),
    .io_faultCsrUop_bits_ftqInfo_ftqPtr_value(TrapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_value),
    .io_faultCsrUop_bits_ftqInfo_ftqOffset(TrapInstMod_io_faultCsrUop_bits_ftqInfo_ftqOffset),
    .io_readClear(TrapInstMod_io_readClear),
    .io_currentTrapInst_valid(TrapInstMod_i_io_currentTrapInst_valid),
    .io_currentTrapInst_bits(TrapInstMod_i_io_currentTrapInst_bits)
  );

  // TrapTvalMod
  logic TrapTvalMod_io_fromCtrlBlock_flush_valid;
  logic TrapTvalMod_io_fromCtrlBlock_flush_bits_robIdx_flag;
  logic [7:0]  TrapTvalMod_io_fromCtrlBlock_flush_bits_robIdx_value;
  logic TrapTvalMod_io_fromCtrlBlock_flush_bits_cfiUpdate_backendIGPF;
  logic TrapTvalMod_io_fromCtrlBlock_flush_bits_cfiUpdate_backendIPF;
  logic TrapTvalMod_io_fromCtrlBlock_flush_bits_cfiUpdate_backendIAF;
  logic [63:0] TrapTvalMod_io_fromCtrlBlock_flush_bits_fullTarget;
  logic TrapTvalMod_io_fromCtrlBlock_robDeqPtr_flag;
  logic [7:0]  TrapTvalMod_io_fromCtrlBlock_robDeqPtr_value;
  logic TrapTvalMod_io_targetPc_valid;
  logic [63:0] TrapTvalMod_io_targetPc_bits_pc;
  logic TrapTvalMod_io_targetPc_bits_raiseIPF;
  logic TrapTvalMod_io_targetPc_bits_raiseIAF;
  logic TrapTvalMod_io_targetPc_bits_raiseIGPF;
  logic TrapTvalMod_io_clear;
  logic [63:0] TrapTvalMod_io_tval;
  logic [63:0] TrapTvalMod_g_io_tval;
  logic [63:0] TrapTvalMod_i_io_tval;
  TrapTvalMod u_TrapTvalMod_g (
    .clock(clock),
    .reset(reset),
    .io_fromCtrlBlock_flush_valid(TrapTvalMod_io_fromCtrlBlock_flush_valid),
    .io_fromCtrlBlock_flush_bits_robIdx_flag(TrapTvalMod_io_fromCtrlBlock_flush_bits_robIdx_flag),
    .io_fromCtrlBlock_flush_bits_robIdx_value(TrapTvalMod_io_fromCtrlBlock_flush_bits_robIdx_value),
    .io_fromCtrlBlock_flush_bits_cfiUpdate_backendIGPF(TrapTvalMod_io_fromCtrlBlock_flush_bits_cfiUpdate_backendIGPF),
    .io_fromCtrlBlock_flush_bits_cfiUpdate_backendIPF(TrapTvalMod_io_fromCtrlBlock_flush_bits_cfiUpdate_backendIPF),
    .io_fromCtrlBlock_flush_bits_cfiUpdate_backendIAF(TrapTvalMod_io_fromCtrlBlock_flush_bits_cfiUpdate_backendIAF),
    .io_fromCtrlBlock_flush_bits_fullTarget(TrapTvalMod_io_fromCtrlBlock_flush_bits_fullTarget),
    .io_fromCtrlBlock_robDeqPtr_flag(TrapTvalMod_io_fromCtrlBlock_robDeqPtr_flag),
    .io_fromCtrlBlock_robDeqPtr_value(TrapTvalMod_io_fromCtrlBlock_robDeqPtr_value),
    .io_targetPc_valid(TrapTvalMod_io_targetPc_valid),
    .io_targetPc_bits_pc(TrapTvalMod_io_targetPc_bits_pc),
    .io_targetPc_bits_raiseIPF(TrapTvalMod_io_targetPc_bits_raiseIPF),
    .io_targetPc_bits_raiseIAF(TrapTvalMod_io_targetPc_bits_raiseIAF),
    .io_targetPc_bits_raiseIGPF(TrapTvalMod_io_targetPc_bits_raiseIGPF),
    .io_clear(TrapTvalMod_io_clear),
    .io_tval(TrapTvalMod_g_io_tval)
  );
  TrapTvalMod_xs u_TrapTvalMod_i (
    .clock(clock),
    .reset(reset),
    .io_fromCtrlBlock_flush_valid(TrapTvalMod_io_fromCtrlBlock_flush_valid),
    .io_fromCtrlBlock_flush_bits_robIdx_flag(TrapTvalMod_io_fromCtrlBlock_flush_bits_robIdx_flag),
    .io_fromCtrlBlock_flush_bits_robIdx_value(TrapTvalMod_io_fromCtrlBlock_flush_bits_robIdx_value),
    .io_fromCtrlBlock_flush_bits_cfiUpdate_backendIGPF(TrapTvalMod_io_fromCtrlBlock_flush_bits_cfiUpdate_backendIGPF),
    .io_fromCtrlBlock_flush_bits_cfiUpdate_backendIPF(TrapTvalMod_io_fromCtrlBlock_flush_bits_cfiUpdate_backendIPF),
    .io_fromCtrlBlock_flush_bits_cfiUpdate_backendIAF(TrapTvalMod_io_fromCtrlBlock_flush_bits_cfiUpdate_backendIAF),
    .io_fromCtrlBlock_flush_bits_fullTarget(TrapTvalMod_io_fromCtrlBlock_flush_bits_fullTarget),
    .io_fromCtrlBlock_robDeqPtr_flag(TrapTvalMod_io_fromCtrlBlock_robDeqPtr_flag),
    .io_fromCtrlBlock_robDeqPtr_value(TrapTvalMod_io_fromCtrlBlock_robDeqPtr_value),
    .io_targetPc_valid(TrapTvalMod_io_targetPc_valid),
    .io_targetPc_bits_pc(TrapTvalMod_io_targetPc_bits_pc),
    .io_targetPc_bits_raiseIPF(TrapTvalMod_io_targetPc_bits_raiseIPF),
    .io_targetPc_bits_raiseIAF(TrapTvalMod_io_targetPc_bits_raiseIAF),
    .io_targetPc_bits_raiseIGPF(TrapTvalMod_io_targetPc_bits_raiseIGPF),
    .io_clear(TrapTvalMod_io_clear),
    .io_tval(TrapTvalMod_i_io_tval)
  );

  initial begin
    repeat (3) @(posedge clock);
    reset <= 1'b0;
    for (cycle = 0; cycle < ncycles; cycle = cycle + 1) begin
      Mgtu_io_in_vd <= {$urandom, $urandom};
      Mgtu_io_in_vl <= {$urandom, $urandom};
      MidelegModule_w_wen <= {$urandom, $urandom};
      MidelegModule_w_wdata <= {$urandom, $urandom};
      MipModule_w_wen <= {$urandom, $urandom};
      MipModule_w_wdata <= {$urandom, $urandom};
      MipModule_mvip_SEIP <= {$urandom, $urandom};
      MipModule_mvien_SEIE <= {$urandom, $urandom};
      MipModule_hvip_VSSIP <= {$urandom, $urandom};
      MipModule_hvip_VSTIP <= {$urandom, $urandom};
      MipModule_hvip_VSEIP <= {$urandom, $urandom};
      MipModule_hgeip_ip <= {$urandom, $urandom};
      MipModule_hgeie_ie <= {$urandom, $urandom};
      MipModule_hstatusVGEIN <= {$urandom, $urandom};
      MipModule_platformIRP_MEIP <= {$urandom, $urandom};
      MipModule_platformIRP_MTIP <= {$urandom, $urandom};
      MipModule_platformIRP_MSIP <= {$urandom, $urandom};
      MipModule_platformIRP_SEIP <= {$urandom, $urandom};
      MipModule_platformIRP_STIP <= {$urandom, $urandom};
      MipModule_platformIRP_VSTIP <= {$urandom, $urandom};
      MipModule_menvcfg_STCE <= {$urandom, $urandom};
      MipModule_lcofiReq <= {$urandom, $urandom};
      MipModule_aiaToCSR_meip <= {$urandom, $urandom};
      MipModule_aiaToCSR_seip <= {$urandom, $urandom};
      MipModule_fromMvip_SSIP_valid <= {$urandom, $urandom};
      MipModule_fromMvip_SSIP_bits <= {$urandom, $urandom};
      MipModule_fromMvip_STIP_valid <= {$urandom, $urandom};
      MipModule_fromMvip_STIP_bits <= {$urandom, $urandom};
      MipModule_fromSip_SSIP_valid <= {$urandom, $urandom};
      MipModule_fromSip_SSIP_bits <= {$urandom, $urandom};
      MipModule_fromSip_LCOFIP_valid <= {$urandom, $urandom};
      MipModule_fromSip_LCOFIP_bits <= {$urandom, $urandom};
      MipModule_fromVSip_LCOFIP_valid <= {$urandom, $urandom};
      MipModule_fromVSip_LCOFIP_bits <= {$urandom, $urandom};
      MiselectModule_w_wen <= {$urandom, $urandom};
      MiselectModule_w_wdata <= {$urandom, $urandom};
      MnstatusModule_w_wen <= {$urandom, $urandom};
      MnstatusModule_w_wdata <= {$urandom, $urandom};
      MnstatusModule_trapToMN_mnstatus_valid <= {$urandom, $urandom};
      MnstatusModule_trapToMN_mnstatus_bits_NMIE <= {$urandom, $urandom};
      MnstatusModule_trapToMN_mnstatus_bits_MNPV <= {$urandom, $urandom};
      MnstatusModule_trapToMN_mnstatus_bits_MNPP <= {$urandom, $urandom};
      MnstatusModule_retFromMN_mnstatus_valid <= {$urandom, $urandom};
      MnstatusModule_retFromMN_mnstatus_bits_NMIE <= {$urandom, $urandom};
      MretEventModule_valid <= {$urandom, $urandom};
      MretEventModule_in_mstatus_MPIE <= {$urandom, $urandom};
      MretEventModule_in_mstatus_MPP <= {$urandom, $urandom};
      MretEventModule_in_mstatus_MPRV <= {$urandom, $urandom};
      MretEventModule_in_mstatus_SDT <= {$urandom, $urandom};
      MretEventModule_in_mstatus_MPV <= {$urandom, $urandom};
      MretEventModule_in_vsstatus_SDT <= {$urandom, $urandom};
      MretEventModule_in_mepc_epc <= {$urandom, $urandom};
      MretEventModule_in_satp_MODE <= {$urandom, $urandom};
      MretEventModule_in_vsatp_MODE <= {$urandom, $urandom};
      MretEventModule_in_hgatp_MODE <= {$urandom, $urandom};
      MseccfgModule_w_wen <= {$urandom, $urandom};
      MseccfgModule_w_wdata <= {$urandom, $urandom};
      Mstateen0Module_w_wen <= {$urandom, $urandom};
      Mstateen0Module_w_wdata <= {$urandom, $urandom};
      Mstateen1Module_w_wen <= {$urandom, $urandom};
      Mstateen1Module_w_wdata <= {$urandom, $urandom};
      Mstateen2Module_w_wen <= {$urandom, $urandom};
      Mstateen2Module_w_wdata <= {$urandom, $urandom};
      Mstateen3Module_w_wen <= {$urandom, $urandom};
      Mstateen3Module_w_wdata <= {$urandom, $urandom};
      MtinstModule_w_wen <= {$urandom, $urandom};
      MtinstModule_w_wdata <= {$urandom, $urandom};
      MtinstModule_trapToM_mtinst_valid <= {$urandom, $urandom};
      MtinstModule_trapToM_mtinst_bits_ALL <= {$urandom, $urandom};
      SatpModule_w_wen <= {$urandom, $urandom};
      SatpModule_w_wdata <= {$urandom, $urandom};
      SbpctlModule_w_wen <= {$urandom, $urandom};
      SbpctlModule_w_wdata <= {$urandom, $urandom};
      ScounterenModule_w_wen <= {$urandom, $urandom};
      ScounterenModule_w_wdata <= {$urandom, $urandom};
      SenvcfgModule_w_wen <= {$urandom, $urandom};
      SenvcfgModule_w_wdata <= {$urandom, $urandom};
      SiselectModule_w_wen <= {$urandom, $urandom};
      SiselectModule_w_wdata <= {$urandom, $urandom};
      SlvpredctlModule_w_wen <= {$urandom, $urandom};
      SlvpredctlModule_w_wdata <= {$urandom, $urandom};
      SmblockctlModule_w_wen <= {$urandom, $urandom};
      SmblockctlModule_w_wdata <= {$urandom, $urandom};
      SpfctlModule_w_wen <= {$urandom, $urandom};
      SpfctlModule_w_wdata <= {$urandom, $urandom};
      SretEventModule_valid <= {$urandom, $urandom};
      SretEventModule_in_privState_PRVM <= {$urandom, $urandom};
      SretEventModule_in_privState_V <= {$urandom, $urandom};
      SretEventModule_in_mstatus_SPIE <= {$urandom, $urandom};
      SretEventModule_in_mstatus_SPP <= {$urandom, $urandom};
      SretEventModule_in_mstatus_SDT <= {$urandom, $urandom};
      SretEventModule_in_mstatus_MDT <= {$urandom, $urandom};
      SretEventModule_in_hstatus_SPV <= {$urandom, $urandom};
      SretEventModule_in_vsstatus_SPIE <= {$urandom, $urandom};
      SretEventModule_in_vsstatus_SPP <= {$urandom, $urandom};
      SretEventModule_in_sepc_epc <= {$urandom, $urandom};
      SretEventModule_in_vsepc_epc <= {$urandom, $urandom};
      SretEventModule_in_satp_MODE <= {$urandom, $urandom};
      SretEventModule_in_vsatp_MODE <= {$urandom, $urandom};
      SretEventModule_in_hgatp_MODE <= {$urandom, $urandom};
      SrnctlModule_w_wen <= {$urandom, $urandom};
      SrnctlModule_w_wdata <= {$urandom, $urandom};
      Sstateen0Module_w_wen <= {$urandom, $urandom};
      Sstateen0Module_w_wdata <= {$urandom, $urandom};
      Sstateen0Module_fromMstateen0_SE0 <= {$urandom, $urandom};
      Sstateen0Module_fromMstateen0_ENVCFG <= {$urandom, $urandom};
      Sstateen0Module_fromMstateen0_CSRIND <= {$urandom, $urandom};
      Sstateen0Module_fromMstateen0_AIA <= {$urandom, $urandom};
      Sstateen0Module_fromMstateen0_IMSIC <= {$urandom, $urandom};
      Sstateen0Module_fromMstateen0_CONTEXT <= {$urandom, $urandom};
      Sstateen0Module_fromMstateen0_C <= {$urandom, $urandom};
      Sstateen0Module_fromHstateen0_JVT <= {$urandom, $urandom};
      Sstateen0Module_fromHstateen0_FCSR <= {$urandom, $urandom};
      Sstateen0Module_fromHstateen0_C <= {$urandom, $urandom};
      Sstateen0Module_fromHstateen0_SE0 <= {$urandom, $urandom};
      Sstateen0Module_fromHstateen0_ENVCFG <= {$urandom, $urandom};
      Sstateen0Module_fromHstateen0_CSRIND <= {$urandom, $urandom};
      Sstateen0Module_fromHstateen0_AIA <= {$urandom, $urandom};
      Sstateen0Module_fromHstateen0_IMSIC <= {$urandom, $urandom};
      Sstateen0Module_fromHstateen0_CONTEXT <= {$urandom, $urandom};
      Sstateen0Module_privState_V <= {$urandom, $urandom};
      StimecmpModule_w_wen <= {$urandom, $urandom};
      StimecmpModule_w_wdata <= {$urandom, $urandom};
      TrapInstMod_io_fromDecode_trapInstInfo_valid <= {$urandom, $urandom};
      TrapInstMod_io_fromDecode_trapInstInfo_bits_instr <= {$urandom, $urandom};
      TrapInstMod_io_fromDecode_trapInstInfo_bits_ftqPtr_flag <= {$urandom, $urandom};
      TrapInstMod_io_fromDecode_trapInstInfo_bits_ftqPtr_value <= {$urandom, $urandom};
      TrapInstMod_io_fromDecode_trapInstInfo_bits_ftqOffset <= {$urandom, $urandom};
      TrapInstMod_io_fromRob_flush_valid <= {$urandom, $urandom};
      TrapInstMod_io_fromRob_flush_bits_ftqPtr_flag <= {$urandom, $urandom};
      TrapInstMod_io_fromRob_flush_bits_ftqPtr_value <= {$urandom, $urandom};
      TrapInstMod_io_fromRob_flush_bits_ftqOffset <= {$urandom, $urandom};
      TrapInstMod_io_fromRob_isInterrupt_valid <= {$urandom, $urandom};
      TrapInstMod_io_fromRob_isInterrupt_bits <= {$urandom, $urandom};
      TrapInstMod_io_faultCsrUop_valid <= {$urandom, $urandom};
      TrapInstMod_io_faultCsrUop_bits_fuOpType <= {$urandom, $urandom};
      TrapInstMod_io_faultCsrUop_bits_imm <= {$urandom, $urandom};
      TrapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_flag <= {$urandom, $urandom};
      TrapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_value <= {$urandom, $urandom};
      TrapInstMod_io_faultCsrUop_bits_ftqInfo_ftqOffset <= {$urandom, $urandom};
      TrapInstMod_io_readClear <= {$urandom, $urandom};
      TrapTvalMod_io_fromCtrlBlock_flush_valid <= {$urandom, $urandom};
      TrapTvalMod_io_fromCtrlBlock_flush_bits_robIdx_flag <= {$urandom, $urandom};
      TrapTvalMod_io_fromCtrlBlock_flush_bits_robIdx_value <= {$urandom, $urandom};
      TrapTvalMod_io_fromCtrlBlock_flush_bits_cfiUpdate_backendIGPF <= {$urandom, $urandom};
      TrapTvalMod_io_fromCtrlBlock_flush_bits_cfiUpdate_backendIPF <= {$urandom, $urandom};
      TrapTvalMod_io_fromCtrlBlock_flush_bits_cfiUpdate_backendIAF <= {$urandom, $urandom};
      TrapTvalMod_io_fromCtrlBlock_flush_bits_fullTarget <= {$urandom, $urandom};
      TrapTvalMod_io_fromCtrlBlock_robDeqPtr_flag <= {$urandom, $urandom};
      TrapTvalMod_io_fromCtrlBlock_robDeqPtr_value <= {$urandom, $urandom};
      TrapTvalMod_io_targetPc_valid <= {$urandom, $urandom};
      TrapTvalMod_io_targetPc_bits_pc <= {$urandom, $urandom};
      TrapTvalMod_io_targetPc_bits_raiseIPF <= {$urandom, $urandom};
      TrapTvalMod_io_targetPc_bits_raiseIAF <= {$urandom, $urandom};
      TrapTvalMod_io_targetPc_bits_raiseIGPF <= {$urandom, $urandom};
      TrapTvalMod_io_clear <= {$urandom, $urandom};
      @(negedge clock);
      if (!reset) begin
    if (Mgtu_g_io_out_vd !== Mgtu_i_io_out_vd) begin
      $display("MISMATCH Mgtu.io_out_vd cycle=%0d g=%h i=%h", cycle, Mgtu_g_io_out_vd, Mgtu_i_io_out_vd);
      errors = errors + 1;
    end
    if (MidelegModule_g_rdata !== MidelegModule_i_rdata) begin
      $display("MISMATCH MidelegModule.rdata cycle=%0d g=%h i=%h", cycle, MidelegModule_g_rdata, MidelegModule_i_rdata);
      errors = errors + 1;
    end
    if (MidelegModule_g_regOut_SSI !== MidelegModule_i_regOut_SSI) begin
      $display("MISMATCH MidelegModule.regOut_SSI cycle=%0d g=%h i=%h", cycle, MidelegModule_g_regOut_SSI, MidelegModule_i_regOut_SSI);
      errors = errors + 1;
    end
    if (MidelegModule_g_regOut_STI !== MidelegModule_i_regOut_STI) begin
      $display("MISMATCH MidelegModule.regOut_STI cycle=%0d g=%h i=%h", cycle, MidelegModule_g_regOut_STI, MidelegModule_i_regOut_STI);
      errors = errors + 1;
    end
    if (MidelegModule_g_regOut_SEI !== MidelegModule_i_regOut_SEI) begin
      $display("MISMATCH MidelegModule.regOut_SEI cycle=%0d g=%h i=%h", cycle, MidelegModule_g_regOut_SEI, MidelegModule_i_regOut_SEI);
      errors = errors + 1;
    end
    if (MidelegModule_g_regOut_LCOFI !== MidelegModule_i_regOut_LCOFI) begin
      $display("MISMATCH MidelegModule.regOut_LCOFI cycle=%0d g=%h i=%h", cycle, MidelegModule_g_regOut_LCOFI, MidelegModule_i_regOut_LCOFI);
      errors = errors + 1;
    end
    if (MipModule_g_rdata !== MipModule_i_rdata) begin
      $display("MISMATCH MipModule.rdata cycle=%0d g=%h i=%h", cycle, MipModule_g_rdata, MipModule_i_rdata);
      errors = errors + 1;
    end
    if (MipModule_g_regOut_SSIP !== MipModule_i_regOut_SSIP) begin
      $display("MISMATCH MipModule.regOut_SSIP cycle=%0d g=%h i=%h", cycle, MipModule_g_regOut_SSIP, MipModule_i_regOut_SSIP);
      errors = errors + 1;
    end
    if (MipModule_g_regOut_VSSIP !== MipModule_i_regOut_VSSIP) begin
      $display("MISMATCH MipModule.regOut_VSSIP cycle=%0d g=%h i=%h", cycle, MipModule_g_regOut_VSSIP, MipModule_i_regOut_VSSIP);
      errors = errors + 1;
    end
    if (MipModule_g_regOut_MSIP !== MipModule_i_regOut_MSIP) begin
      $display("MISMATCH MipModule.regOut_MSIP cycle=%0d g=%h i=%h", cycle, MipModule_g_regOut_MSIP, MipModule_i_regOut_MSIP);
      errors = errors + 1;
    end
    if (MipModule_g_regOut_STIP !== MipModule_i_regOut_STIP) begin
      $display("MISMATCH MipModule.regOut_STIP cycle=%0d g=%h i=%h", cycle, MipModule_g_regOut_STIP, MipModule_i_regOut_STIP);
      errors = errors + 1;
    end
    if (MipModule_g_regOut_VSTIP !== MipModule_i_regOut_VSTIP) begin
      $display("MISMATCH MipModule.regOut_VSTIP cycle=%0d g=%h i=%h", cycle, MipModule_g_regOut_VSTIP, MipModule_i_regOut_VSTIP);
      errors = errors + 1;
    end
    if (MipModule_g_regOut_MTIP !== MipModule_i_regOut_MTIP) begin
      $display("MISMATCH MipModule.regOut_MTIP cycle=%0d g=%h i=%h", cycle, MipModule_g_regOut_MTIP, MipModule_i_regOut_MTIP);
      errors = errors + 1;
    end
    if (MipModule_g_regOut_SEIP !== MipModule_i_regOut_SEIP) begin
      $display("MISMATCH MipModule.regOut_SEIP cycle=%0d g=%h i=%h", cycle, MipModule_g_regOut_SEIP, MipModule_i_regOut_SEIP);
      errors = errors + 1;
    end
    if (MipModule_g_regOut_VSEIP !== MipModule_i_regOut_VSEIP) begin
      $display("MISMATCH MipModule.regOut_VSEIP cycle=%0d g=%h i=%h", cycle, MipModule_g_regOut_VSEIP, MipModule_i_regOut_VSEIP);
      errors = errors + 1;
    end
    if (MipModule_g_regOut_MEIP !== MipModule_i_regOut_MEIP) begin
      $display("MISMATCH MipModule.regOut_MEIP cycle=%0d g=%h i=%h", cycle, MipModule_g_regOut_MEIP, MipModule_i_regOut_MEIP);
      errors = errors + 1;
    end
    if (MipModule_g_regOut_SGEIP !== MipModule_i_regOut_SGEIP) begin
      $display("MISMATCH MipModule.regOut_SGEIP cycle=%0d g=%h i=%h", cycle, MipModule_g_regOut_SGEIP, MipModule_i_regOut_SGEIP);
      errors = errors + 1;
    end
    if (MipModule_g_regOut_LCOFIP !== MipModule_i_regOut_LCOFIP) begin
      $display("MISMATCH MipModule.regOut_LCOFIP cycle=%0d g=%h i=%h", cycle, MipModule_g_regOut_LCOFIP, MipModule_i_regOut_LCOFIP);
      errors = errors + 1;
    end
    if (MipModule_g_rdataFields_SSIP !== MipModule_i_rdataFields_SSIP) begin
      $display("MISMATCH MipModule.rdataFields_SSIP cycle=%0d g=%h i=%h", cycle, MipModule_g_rdataFields_SSIP, MipModule_i_rdataFields_SSIP);
      errors = errors + 1;
    end
    if (MipModule_g_rdataFields_VSSIP !== MipModule_i_rdataFields_VSSIP) begin
      $display("MISMATCH MipModule.rdataFields_VSSIP cycle=%0d g=%h i=%h", cycle, MipModule_g_rdataFields_VSSIP, MipModule_i_rdataFields_VSSIP);
      errors = errors + 1;
    end
    if (MipModule_g_rdataFields_MSIP !== MipModule_i_rdataFields_MSIP) begin
      $display("MISMATCH MipModule.rdataFields_MSIP cycle=%0d g=%h i=%h", cycle, MipModule_g_rdataFields_MSIP, MipModule_i_rdataFields_MSIP);
      errors = errors + 1;
    end
    if (MipModule_g_rdataFields_STIP !== MipModule_i_rdataFields_STIP) begin
      $display("MISMATCH MipModule.rdataFields_STIP cycle=%0d g=%h i=%h", cycle, MipModule_g_rdataFields_STIP, MipModule_i_rdataFields_STIP);
      errors = errors + 1;
    end
    if (MipModule_g_rdataFields_VSTIP !== MipModule_i_rdataFields_VSTIP) begin
      $display("MISMATCH MipModule.rdataFields_VSTIP cycle=%0d g=%h i=%h", cycle, MipModule_g_rdataFields_VSTIP, MipModule_i_rdataFields_VSTIP);
      errors = errors + 1;
    end
    if (MipModule_g_rdataFields_MTIP !== MipModule_i_rdataFields_MTIP) begin
      $display("MISMATCH MipModule.rdataFields_MTIP cycle=%0d g=%h i=%h", cycle, MipModule_g_rdataFields_MTIP, MipModule_i_rdataFields_MTIP);
      errors = errors + 1;
    end
    if (MipModule_g_rdataFields_SEIP !== MipModule_i_rdataFields_SEIP) begin
      $display("MISMATCH MipModule.rdataFields_SEIP cycle=%0d g=%h i=%h", cycle, MipModule_g_rdataFields_SEIP, MipModule_i_rdataFields_SEIP);
      errors = errors + 1;
    end
    if (MipModule_g_rdataFields_VSEIP !== MipModule_i_rdataFields_VSEIP) begin
      $display("MISMATCH MipModule.rdataFields_VSEIP cycle=%0d g=%h i=%h", cycle, MipModule_g_rdataFields_VSEIP, MipModule_i_rdataFields_VSEIP);
      errors = errors + 1;
    end
    if (MipModule_g_rdataFields_MEIP !== MipModule_i_rdataFields_MEIP) begin
      $display("MISMATCH MipModule.rdataFields_MEIP cycle=%0d g=%h i=%h", cycle, MipModule_g_rdataFields_MEIP, MipModule_i_rdataFields_MEIP);
      errors = errors + 1;
    end
    if (MipModule_g_rdataFields_SGEIP !== MipModule_i_rdataFields_SGEIP) begin
      $display("MISMATCH MipModule.rdataFields_SGEIP cycle=%0d g=%h i=%h", cycle, MipModule_g_rdataFields_SGEIP, MipModule_i_rdataFields_SGEIP);
      errors = errors + 1;
    end
    if (MipModule_g_rdataFields_LCOFIP !== MipModule_i_rdataFields_LCOFIP) begin
      $display("MISMATCH MipModule.rdataFields_LCOFIP cycle=%0d g=%h i=%h", cycle, MipModule_g_rdataFields_LCOFIP, MipModule_i_rdataFields_LCOFIP);
      errors = errors + 1;
    end
    if (MipModule_g_toMvip_SEIP_valid !== MipModule_i_toMvip_SEIP_valid) begin
      $display("MISMATCH MipModule.toMvip_SEIP_valid cycle=%0d g=%h i=%h", cycle, MipModule_g_toMvip_SEIP_valid, MipModule_i_toMvip_SEIP_valid);
      errors = errors + 1;
    end
    if (MipModule_g_toMvip_SEIP_bits !== MipModule_i_toMvip_SEIP_bits) begin
      $display("MISMATCH MipModule.toMvip_SEIP_bits cycle=%0d g=%h i=%h", cycle, MipModule_g_toMvip_SEIP_bits, MipModule_i_toMvip_SEIP_bits);
      errors = errors + 1;
    end
    if (MipModule_g_toHvip_VSSIP_valid !== MipModule_i_toHvip_VSSIP_valid) begin
      $display("MISMATCH MipModule.toHvip_VSSIP_valid cycle=%0d g=%h i=%h", cycle, MipModule_g_toHvip_VSSIP_valid, MipModule_i_toHvip_VSSIP_valid);
      errors = errors + 1;
    end
    if (MipModule_g_toHvip_VSSIP_bits !== MipModule_i_toHvip_VSSIP_bits) begin
      $display("MISMATCH MipModule.toHvip_VSSIP_bits cycle=%0d g=%h i=%h", cycle, MipModule_g_toHvip_VSSIP_bits, MipModule_i_toHvip_VSSIP_bits);
      errors = errors + 1;
    end
    if (MiselectModule_g_rdata !== MiselectModule_i_rdata) begin
      $display("MISMATCH MiselectModule.rdata cycle=%0d g=%h i=%h", cycle, MiselectModule_g_rdata, MiselectModule_i_rdata);
      errors = errors + 1;
    end
    if (MiselectModule_g_regOut_ALL !== MiselectModule_i_regOut_ALL) begin
      $display("MISMATCH MiselectModule.regOut_ALL cycle=%0d g=%h i=%h", cycle, MiselectModule_g_regOut_ALL, MiselectModule_i_regOut_ALL);
      errors = errors + 1;
    end
    if (MiselectModule_g_inIMSICRange !== MiselectModule_i_inIMSICRange) begin
      $display("MISMATCH MiselectModule.inIMSICRange cycle=%0d g=%h i=%h", cycle, MiselectModule_g_inIMSICRange, MiselectModule_i_inIMSICRange);
      errors = errors + 1;
    end
    if (MnstatusModule_g_rdata !== MnstatusModule_i_rdata) begin
      $display("MISMATCH MnstatusModule.rdata cycle=%0d g=%h i=%h", cycle, MnstatusModule_g_rdata, MnstatusModule_i_rdata);
      errors = errors + 1;
    end
    if (MnstatusModule_g_regOut_NMIE !== MnstatusModule_i_regOut_NMIE) begin
      $display("MISMATCH MnstatusModule.regOut_NMIE cycle=%0d g=%h i=%h", cycle, MnstatusModule_g_regOut_NMIE, MnstatusModule_i_regOut_NMIE);
      errors = errors + 1;
    end
    if (MnstatusModule_g_regOut_MNPV !== MnstatusModule_i_regOut_MNPV) begin
      $display("MISMATCH MnstatusModule.regOut_MNPV cycle=%0d g=%h i=%h", cycle, MnstatusModule_g_regOut_MNPV, MnstatusModule_i_regOut_MNPV);
      errors = errors + 1;
    end
    if (MnstatusModule_g_regOut_MNPP !== MnstatusModule_i_regOut_MNPP) begin
      $display("MISMATCH MnstatusModule.regOut_MNPP cycle=%0d g=%h i=%h", cycle, MnstatusModule_g_regOut_MNPP, MnstatusModule_i_regOut_MNPP);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_privState_valid !== MretEventModule_i_out_privState_valid) begin
      $display("MISMATCH MretEventModule.out_privState_valid cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_privState_valid, MretEventModule_i_out_privState_valid);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_privState_bits_PRVM !== MretEventModule_i_out_privState_bits_PRVM) begin
      $display("MISMATCH MretEventModule.out_privState_bits_PRVM cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_privState_bits_PRVM, MretEventModule_i_out_privState_bits_PRVM);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_privState_bits_V !== MretEventModule_i_out_privState_bits_V) begin
      $display("MISMATCH MretEventModule.out_privState_bits_V cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_privState_bits_V, MretEventModule_i_out_privState_bits_V);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_valid !== MretEventModule_i_out_mstatus_valid) begin
      $display("MISMATCH MretEventModule.out_mstatus_valid cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_valid, MretEventModule_i_out_mstatus_valid);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_SIE !== MretEventModule_i_out_mstatus_bits_SIE) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_SIE cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_SIE, MretEventModule_i_out_mstatus_bits_SIE);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_MIE !== MretEventModule_i_out_mstatus_bits_MIE) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_MIE cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_MIE, MretEventModule_i_out_mstatus_bits_MIE);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_SPIE !== MretEventModule_i_out_mstatus_bits_SPIE) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_SPIE cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_SPIE, MretEventModule_i_out_mstatus_bits_SPIE);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_UBE !== MretEventModule_i_out_mstatus_bits_UBE) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_UBE cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_UBE, MretEventModule_i_out_mstatus_bits_UBE);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_MPIE !== MretEventModule_i_out_mstatus_bits_MPIE) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_MPIE cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_MPIE, MretEventModule_i_out_mstatus_bits_MPIE);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_SPP !== MretEventModule_i_out_mstatus_bits_SPP) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_SPP cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_SPP, MretEventModule_i_out_mstatus_bits_SPP);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_VS !== MretEventModule_i_out_mstatus_bits_VS) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_VS cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_VS, MretEventModule_i_out_mstatus_bits_VS);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_MPP !== MretEventModule_i_out_mstatus_bits_MPP) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_MPP cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_MPP, MretEventModule_i_out_mstatus_bits_MPP);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_FS !== MretEventModule_i_out_mstatus_bits_FS) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_FS cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_FS, MretEventModule_i_out_mstatus_bits_FS);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_XS !== MretEventModule_i_out_mstatus_bits_XS) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_XS cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_XS, MretEventModule_i_out_mstatus_bits_XS);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_MPRV !== MretEventModule_i_out_mstatus_bits_MPRV) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_MPRV cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_MPRV, MretEventModule_i_out_mstatus_bits_MPRV);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_SUM !== MretEventModule_i_out_mstatus_bits_SUM) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_SUM cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_SUM, MretEventModule_i_out_mstatus_bits_SUM);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_MXR !== MretEventModule_i_out_mstatus_bits_MXR) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_MXR cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_MXR, MretEventModule_i_out_mstatus_bits_MXR);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_TVM !== MretEventModule_i_out_mstatus_bits_TVM) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_TVM cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_TVM, MretEventModule_i_out_mstatus_bits_TVM);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_TW !== MretEventModule_i_out_mstatus_bits_TW) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_TW cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_TW, MretEventModule_i_out_mstatus_bits_TW);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_TSR !== MretEventModule_i_out_mstatus_bits_TSR) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_TSR cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_TSR, MretEventModule_i_out_mstatus_bits_TSR);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_SDT !== MretEventModule_i_out_mstatus_bits_SDT) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_SDT cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_SDT, MretEventModule_i_out_mstatus_bits_SDT);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_UXL !== MretEventModule_i_out_mstatus_bits_UXL) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_UXL cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_UXL, MretEventModule_i_out_mstatus_bits_UXL);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_SXL !== MretEventModule_i_out_mstatus_bits_SXL) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_SXL cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_SXL, MretEventModule_i_out_mstatus_bits_SXL);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_SBE !== MretEventModule_i_out_mstatus_bits_SBE) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_SBE cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_SBE, MretEventModule_i_out_mstatus_bits_SBE);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_MBE !== MretEventModule_i_out_mstatus_bits_MBE) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_MBE cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_MBE, MretEventModule_i_out_mstatus_bits_MBE);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_GVA !== MretEventModule_i_out_mstatus_bits_GVA) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_GVA cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_GVA, MretEventModule_i_out_mstatus_bits_GVA);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_MPV !== MretEventModule_i_out_mstatus_bits_MPV) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_MPV cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_MPV, MretEventModule_i_out_mstatus_bits_MPV);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_MDT !== MretEventModule_i_out_mstatus_bits_MDT) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_MDT cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_MDT, MretEventModule_i_out_mstatus_bits_MDT);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_mstatus_bits_SD !== MretEventModule_i_out_mstatus_bits_SD) begin
      $display("MISMATCH MretEventModule.out_mstatus_bits_SD cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_mstatus_bits_SD, MretEventModule_i_out_mstatus_bits_SD);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_vsstatus_valid !== MretEventModule_i_out_vsstatus_valid) begin
      $display("MISMATCH MretEventModule.out_vsstatus_valid cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_vsstatus_valid, MretEventModule_i_out_vsstatus_valid);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_vsstatus_bits_SIE !== MretEventModule_i_out_vsstatus_bits_SIE) begin
      $display("MISMATCH MretEventModule.out_vsstatus_bits_SIE cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_vsstatus_bits_SIE, MretEventModule_i_out_vsstatus_bits_SIE);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_vsstatus_bits_SPIE !== MretEventModule_i_out_vsstatus_bits_SPIE) begin
      $display("MISMATCH MretEventModule.out_vsstatus_bits_SPIE cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_vsstatus_bits_SPIE, MretEventModule_i_out_vsstatus_bits_SPIE);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_vsstatus_bits_UBE !== MretEventModule_i_out_vsstatus_bits_UBE) begin
      $display("MISMATCH MretEventModule.out_vsstatus_bits_UBE cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_vsstatus_bits_UBE, MretEventModule_i_out_vsstatus_bits_UBE);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_vsstatus_bits_SPP !== MretEventModule_i_out_vsstatus_bits_SPP) begin
      $display("MISMATCH MretEventModule.out_vsstatus_bits_SPP cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_vsstatus_bits_SPP, MretEventModule_i_out_vsstatus_bits_SPP);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_vsstatus_bits_VS !== MretEventModule_i_out_vsstatus_bits_VS) begin
      $display("MISMATCH MretEventModule.out_vsstatus_bits_VS cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_vsstatus_bits_VS, MretEventModule_i_out_vsstatus_bits_VS);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_vsstatus_bits_FS !== MretEventModule_i_out_vsstatus_bits_FS) begin
      $display("MISMATCH MretEventModule.out_vsstatus_bits_FS cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_vsstatus_bits_FS, MretEventModule_i_out_vsstatus_bits_FS);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_vsstatus_bits_XS !== MretEventModule_i_out_vsstatus_bits_XS) begin
      $display("MISMATCH MretEventModule.out_vsstatus_bits_XS cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_vsstatus_bits_XS, MretEventModule_i_out_vsstatus_bits_XS);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_vsstatus_bits_SUM !== MretEventModule_i_out_vsstatus_bits_SUM) begin
      $display("MISMATCH MretEventModule.out_vsstatus_bits_SUM cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_vsstatus_bits_SUM, MretEventModule_i_out_vsstatus_bits_SUM);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_vsstatus_bits_MXR !== MretEventModule_i_out_vsstatus_bits_MXR) begin
      $display("MISMATCH MretEventModule.out_vsstatus_bits_MXR cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_vsstatus_bits_MXR, MretEventModule_i_out_vsstatus_bits_MXR);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_vsstatus_bits_SDT !== MretEventModule_i_out_vsstatus_bits_SDT) begin
      $display("MISMATCH MretEventModule.out_vsstatus_bits_SDT cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_vsstatus_bits_SDT, MretEventModule_i_out_vsstatus_bits_SDT);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_vsstatus_bits_UXL !== MretEventModule_i_out_vsstatus_bits_UXL) begin
      $display("MISMATCH MretEventModule.out_vsstatus_bits_UXL cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_vsstatus_bits_UXL, MretEventModule_i_out_vsstatus_bits_UXL);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_vsstatus_bits_SD !== MretEventModule_i_out_vsstatus_bits_SD) begin
      $display("MISMATCH MretEventModule.out_vsstatus_bits_SD cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_vsstatus_bits_SD, MretEventModule_i_out_vsstatus_bits_SD);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_targetPc_valid !== MretEventModule_i_out_targetPc_valid) begin
      $display("MISMATCH MretEventModule.out_targetPc_valid cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_targetPc_valid, MretEventModule_i_out_targetPc_valid);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_targetPc_bits_pc !== MretEventModule_i_out_targetPc_bits_pc) begin
      $display("MISMATCH MretEventModule.out_targetPc_bits_pc cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_targetPc_bits_pc, MretEventModule_i_out_targetPc_bits_pc);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_targetPc_bits_raiseIPF !== MretEventModule_i_out_targetPc_bits_raiseIPF) begin
      $display("MISMATCH MretEventModule.out_targetPc_bits_raiseIPF cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_targetPc_bits_raiseIPF, MretEventModule_i_out_targetPc_bits_raiseIPF);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_targetPc_bits_raiseIAF !== MretEventModule_i_out_targetPc_bits_raiseIAF) begin
      $display("MISMATCH MretEventModule.out_targetPc_bits_raiseIAF cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_targetPc_bits_raiseIAF, MretEventModule_i_out_targetPc_bits_raiseIAF);
      errors = errors + 1;
    end
    if (MretEventModule_g_out_targetPc_bits_raiseIGPF !== MretEventModule_i_out_targetPc_bits_raiseIGPF) begin
      $display("MISMATCH MretEventModule.out_targetPc_bits_raiseIGPF cycle=%0d g=%h i=%h", cycle, MretEventModule_g_out_targetPc_bits_raiseIGPF, MretEventModule_i_out_targetPc_bits_raiseIGPF);
      errors = errors + 1;
    end
    if (MseccfgModule_g_rdata !== MseccfgModule_i_rdata) begin
      $display("MISMATCH MseccfgModule.rdata cycle=%0d g=%h i=%h", cycle, MseccfgModule_g_rdata, MseccfgModule_i_rdata);
      errors = errors + 1;
    end
    if (MseccfgModule_g_regOut_PMM !== MseccfgModule_i_regOut_PMM) begin
      $display("MISMATCH MseccfgModule.regOut_PMM cycle=%0d g=%h i=%h", cycle, MseccfgModule_g_regOut_PMM, MseccfgModule_i_regOut_PMM);
      errors = errors + 1;
    end
    if (Mstateen0Module_g_rdata !== Mstateen0Module_i_rdata) begin
      $display("MISMATCH Mstateen0Module.rdata cycle=%0d g=%h i=%h", cycle, Mstateen0Module_g_rdata, Mstateen0Module_i_rdata);
      errors = errors + 1;
    end
    if (Mstateen0Module_g_regOut_SE0 !== Mstateen0Module_i_regOut_SE0) begin
      $display("MISMATCH Mstateen0Module.regOut_SE0 cycle=%0d g=%h i=%h", cycle, Mstateen0Module_g_regOut_SE0, Mstateen0Module_i_regOut_SE0);
      errors = errors + 1;
    end
    if (Mstateen0Module_g_regOut_ENVCFG !== Mstateen0Module_i_regOut_ENVCFG) begin
      $display("MISMATCH Mstateen0Module.regOut_ENVCFG cycle=%0d g=%h i=%h", cycle, Mstateen0Module_g_regOut_ENVCFG, Mstateen0Module_i_regOut_ENVCFG);
      errors = errors + 1;
    end
    if (Mstateen0Module_g_regOut_CSRIND !== Mstateen0Module_i_regOut_CSRIND) begin
      $display("MISMATCH Mstateen0Module.regOut_CSRIND cycle=%0d g=%h i=%h", cycle, Mstateen0Module_g_regOut_CSRIND, Mstateen0Module_i_regOut_CSRIND);
      errors = errors + 1;
    end
    if (Mstateen0Module_g_regOut_AIA !== Mstateen0Module_i_regOut_AIA) begin
      $display("MISMATCH Mstateen0Module.regOut_AIA cycle=%0d g=%h i=%h", cycle, Mstateen0Module_g_regOut_AIA, Mstateen0Module_i_regOut_AIA);
      errors = errors + 1;
    end
    if (Mstateen0Module_g_regOut_IMSIC !== Mstateen0Module_i_regOut_IMSIC) begin
      $display("MISMATCH Mstateen0Module.regOut_IMSIC cycle=%0d g=%h i=%h", cycle, Mstateen0Module_g_regOut_IMSIC, Mstateen0Module_i_regOut_IMSIC);
      errors = errors + 1;
    end
    if (Mstateen0Module_g_regOut_CONTEXT !== Mstateen0Module_i_regOut_CONTEXT) begin
      $display("MISMATCH Mstateen0Module.regOut_CONTEXT cycle=%0d g=%h i=%h", cycle, Mstateen0Module_g_regOut_CONTEXT, Mstateen0Module_i_regOut_CONTEXT);
      errors = errors + 1;
    end
    if (Mstateen0Module_g_regOut_C !== Mstateen0Module_i_regOut_C) begin
      $display("MISMATCH Mstateen0Module.regOut_C cycle=%0d g=%h i=%h", cycle, Mstateen0Module_g_regOut_C, Mstateen0Module_i_regOut_C);
      errors = errors + 1;
    end
    if (Mstateen1Module_g_rdata !== Mstateen1Module_i_rdata) begin
      $display("MISMATCH Mstateen1Module.rdata cycle=%0d g=%h i=%h", cycle, Mstateen1Module_g_rdata, Mstateen1Module_i_rdata);
      errors = errors + 1;
    end
    if (Mstateen1Module_g_regOut_SE !== Mstateen1Module_i_regOut_SE) begin
      $display("MISMATCH Mstateen1Module.regOut_SE cycle=%0d g=%h i=%h", cycle, Mstateen1Module_g_regOut_SE, Mstateen1Module_i_regOut_SE);
      errors = errors + 1;
    end
    if (Mstateen2Module_g_rdata !== Mstateen2Module_i_rdata) begin
      $display("MISMATCH Mstateen2Module.rdata cycle=%0d g=%h i=%h", cycle, Mstateen2Module_g_rdata, Mstateen2Module_i_rdata);
      errors = errors + 1;
    end
    if (Mstateen2Module_g_regOut_SE !== Mstateen2Module_i_regOut_SE) begin
      $display("MISMATCH Mstateen2Module.regOut_SE cycle=%0d g=%h i=%h", cycle, Mstateen2Module_g_regOut_SE, Mstateen2Module_i_regOut_SE);
      errors = errors + 1;
    end
    if (Mstateen3Module_g_rdata !== Mstateen3Module_i_rdata) begin
      $display("MISMATCH Mstateen3Module.rdata cycle=%0d g=%h i=%h", cycle, Mstateen3Module_g_rdata, Mstateen3Module_i_rdata);
      errors = errors + 1;
    end
    if (Mstateen3Module_g_regOut_SE !== Mstateen3Module_i_regOut_SE) begin
      $display("MISMATCH Mstateen3Module.regOut_SE cycle=%0d g=%h i=%h", cycle, Mstateen3Module_g_regOut_SE, Mstateen3Module_i_regOut_SE);
      errors = errors + 1;
    end
    if (MtinstModule_g_rdata !== MtinstModule_i_rdata) begin
      $display("MISMATCH MtinstModule.rdata cycle=%0d g=%h i=%h", cycle, MtinstModule_g_rdata, MtinstModule_i_rdata);
      errors = errors + 1;
    end
    if (MtinstModule_g_regOut_ALL !== MtinstModule_i_regOut_ALL) begin
      $display("MISMATCH MtinstModule.regOut_ALL cycle=%0d g=%h i=%h", cycle, MtinstModule_g_regOut_ALL, MtinstModule_i_regOut_ALL);
      errors = errors + 1;
    end
    if (SatpModule_g_rdata !== SatpModule_i_rdata) begin
      $display("MISMATCH SatpModule.rdata cycle=%0d g=%h i=%h", cycle, SatpModule_g_rdata, SatpModule_i_rdata);
      errors = errors + 1;
    end
    if (SatpModule_g_regOut_MODE !== SatpModule_i_regOut_MODE) begin
      $display("MISMATCH SatpModule.regOut_MODE cycle=%0d g=%h i=%h", cycle, SatpModule_g_regOut_MODE, SatpModule_i_regOut_MODE);
      errors = errors + 1;
    end
    if (SatpModule_g_regOut_ASID !== SatpModule_i_regOut_ASID) begin
      $display("MISMATCH SatpModule.regOut_ASID cycle=%0d g=%h i=%h", cycle, SatpModule_g_regOut_ASID, SatpModule_i_regOut_ASID);
      errors = errors + 1;
    end
    if (SatpModule_g_regOut_PPN !== SatpModule_i_regOut_PPN) begin
      $display("MISMATCH SatpModule.regOut_PPN cycle=%0d g=%h i=%h", cycle, SatpModule_g_regOut_PPN, SatpModule_i_regOut_PPN);
      errors = errors + 1;
    end
    if (SbpctlModule_g_rdata !== SbpctlModule_i_rdata) begin
      $display("MISMATCH SbpctlModule.rdata cycle=%0d g=%h i=%h", cycle, SbpctlModule_g_rdata, SbpctlModule_i_rdata);
      errors = errors + 1;
    end
    if (SbpctlModule_g_regOut_LOOP_ENABLE !== SbpctlModule_i_regOut_LOOP_ENABLE) begin
      $display("MISMATCH SbpctlModule.regOut_LOOP_ENABLE cycle=%0d g=%h i=%h", cycle, SbpctlModule_g_regOut_LOOP_ENABLE, SbpctlModule_i_regOut_LOOP_ENABLE);
      errors = errors + 1;
    end
    if (SbpctlModule_g_regOut_RAS_ENABLE !== SbpctlModule_i_regOut_RAS_ENABLE) begin
      $display("MISMATCH SbpctlModule.regOut_RAS_ENABLE cycle=%0d g=%h i=%h", cycle, SbpctlModule_g_regOut_RAS_ENABLE, SbpctlModule_i_regOut_RAS_ENABLE);
      errors = errors + 1;
    end
    if (SbpctlModule_g_regOut_SC_ENABLE !== SbpctlModule_i_regOut_SC_ENABLE) begin
      $display("MISMATCH SbpctlModule.regOut_SC_ENABLE cycle=%0d g=%h i=%h", cycle, SbpctlModule_g_regOut_SC_ENABLE, SbpctlModule_i_regOut_SC_ENABLE);
      errors = errors + 1;
    end
    if (SbpctlModule_g_regOut_TAGE_ENABLE !== SbpctlModule_i_regOut_TAGE_ENABLE) begin
      $display("MISMATCH SbpctlModule.regOut_TAGE_ENABLE cycle=%0d g=%h i=%h", cycle, SbpctlModule_g_regOut_TAGE_ENABLE, SbpctlModule_i_regOut_TAGE_ENABLE);
      errors = errors + 1;
    end
    if (SbpctlModule_g_regOut_BIM_ENABLE !== SbpctlModule_i_regOut_BIM_ENABLE) begin
      $display("MISMATCH SbpctlModule.regOut_BIM_ENABLE cycle=%0d g=%h i=%h", cycle, SbpctlModule_g_regOut_BIM_ENABLE, SbpctlModule_i_regOut_BIM_ENABLE);
      errors = errors + 1;
    end
    if (SbpctlModule_g_regOut_BTB_ENABLE !== SbpctlModule_i_regOut_BTB_ENABLE) begin
      $display("MISMATCH SbpctlModule.regOut_BTB_ENABLE cycle=%0d g=%h i=%h", cycle, SbpctlModule_g_regOut_BTB_ENABLE, SbpctlModule_i_regOut_BTB_ENABLE);
      errors = errors + 1;
    end
    if (SbpctlModule_g_regOut_UBTB_ENABLE !== SbpctlModule_i_regOut_UBTB_ENABLE) begin
      $display("MISMATCH SbpctlModule.regOut_UBTB_ENABLE cycle=%0d g=%h i=%h", cycle, SbpctlModule_g_regOut_UBTB_ENABLE, SbpctlModule_i_regOut_UBTB_ENABLE);
      errors = errors + 1;
    end
    if (ScounterenModule_g_rdata !== ScounterenModule_i_rdata) begin
      $display("MISMATCH ScounterenModule.rdata cycle=%0d g=%h i=%h", cycle, ScounterenModule_g_rdata, ScounterenModule_i_rdata);
      errors = errors + 1;
    end
    if (ScounterenModule_g_regOut_CY !== ScounterenModule_i_regOut_CY) begin
      $display("MISMATCH ScounterenModule.regOut_CY cycle=%0d g=%h i=%h", cycle, ScounterenModule_g_regOut_CY, ScounterenModule_i_regOut_CY);
      errors = errors + 1;
    end
    if (ScounterenModule_g_regOut_TM !== ScounterenModule_i_regOut_TM) begin
      $display("MISMATCH ScounterenModule.regOut_TM cycle=%0d g=%h i=%h", cycle, ScounterenModule_g_regOut_TM, ScounterenModule_i_regOut_TM);
      errors = errors + 1;
    end
    if (ScounterenModule_g_regOut_IR !== ScounterenModule_i_regOut_IR) begin
      $display("MISMATCH ScounterenModule.regOut_IR cycle=%0d g=%h i=%h", cycle, ScounterenModule_g_regOut_IR, ScounterenModule_i_regOut_IR);
      errors = errors + 1;
    end
    if (ScounterenModule_g_regOut_HPM !== ScounterenModule_i_regOut_HPM) begin
      $display("MISMATCH ScounterenModule.regOut_HPM cycle=%0d g=%h i=%h", cycle, ScounterenModule_g_regOut_HPM, ScounterenModule_i_regOut_HPM);
      errors = errors + 1;
    end
    if (SenvcfgModule_g_rdata !== SenvcfgModule_i_rdata) begin
      $display("MISMATCH SenvcfgModule.rdata cycle=%0d g=%h i=%h", cycle, SenvcfgModule_g_rdata, SenvcfgModule_i_rdata);
      errors = errors + 1;
    end
    if (SenvcfgModule_g_regOut_PMM !== SenvcfgModule_i_regOut_PMM) begin
      $display("MISMATCH SenvcfgModule.regOut_PMM cycle=%0d g=%h i=%h", cycle, SenvcfgModule_g_regOut_PMM, SenvcfgModule_i_regOut_PMM);
      errors = errors + 1;
    end
    if (SenvcfgModule_g_regOut_CBZE !== SenvcfgModule_i_regOut_CBZE) begin
      $display("MISMATCH SenvcfgModule.regOut_CBZE cycle=%0d g=%h i=%h", cycle, SenvcfgModule_g_regOut_CBZE, SenvcfgModule_i_regOut_CBZE);
      errors = errors + 1;
    end
    if (SenvcfgModule_g_regOut_CBCFE !== SenvcfgModule_i_regOut_CBCFE) begin
      $display("MISMATCH SenvcfgModule.regOut_CBCFE cycle=%0d g=%h i=%h", cycle, SenvcfgModule_g_regOut_CBCFE, SenvcfgModule_i_regOut_CBCFE);
      errors = errors + 1;
    end
    if (SenvcfgModule_g_regOut_CBIE !== SenvcfgModule_i_regOut_CBIE) begin
      $display("MISMATCH SenvcfgModule.regOut_CBIE cycle=%0d g=%h i=%h", cycle, SenvcfgModule_g_regOut_CBIE, SenvcfgModule_i_regOut_CBIE);
      errors = errors + 1;
    end
    if (SiselectModule_g_rdata !== SiselectModule_i_rdata) begin
      $display("MISMATCH SiselectModule.rdata cycle=%0d g=%h i=%h", cycle, SiselectModule_g_rdata, SiselectModule_i_rdata);
      errors = errors + 1;
    end
    if (SiselectModule_g_regOut_ALL !== SiselectModule_i_regOut_ALL) begin
      $display("MISMATCH SiselectModule.regOut_ALL cycle=%0d g=%h i=%h", cycle, SiselectModule_g_regOut_ALL, SiselectModule_i_regOut_ALL);
      errors = errors + 1;
    end
    if (SiselectModule_g_inIMSICRange !== SiselectModule_i_inIMSICRange) begin
      $display("MISMATCH SiselectModule.inIMSICRange cycle=%0d g=%h i=%h", cycle, SiselectModule_g_inIMSICRange, SiselectModule_i_inIMSICRange);
      errors = errors + 1;
    end
    if (SlvpredctlModule_g_rdata !== SlvpredctlModule_i_rdata) begin
      $display("MISMATCH SlvpredctlModule.rdata cycle=%0d g=%h i=%h", cycle, SlvpredctlModule_g_rdata, SlvpredctlModule_i_rdata);
      errors = errors + 1;
    end
    if (SlvpredctlModule_g_regOut_LVPRED_TIMEOUT !== SlvpredctlModule_i_regOut_LVPRED_TIMEOUT) begin
      $display("MISMATCH SlvpredctlModule.regOut_LVPRED_TIMEOUT cycle=%0d g=%h i=%h", cycle, SlvpredctlModule_g_regOut_LVPRED_TIMEOUT, SlvpredctlModule_i_regOut_LVPRED_TIMEOUT);
      errors = errors + 1;
    end
    if (SlvpredctlModule_g_regOut_STORESET_NO_FAST_WAKEUP !== SlvpredctlModule_i_regOut_STORESET_NO_FAST_WAKEUP) begin
      $display("MISMATCH SlvpredctlModule.regOut_STORESET_NO_FAST_WAKEUP cycle=%0d g=%h i=%h", cycle, SlvpredctlModule_g_regOut_STORESET_NO_FAST_WAKEUP, SlvpredctlModule_i_regOut_STORESET_NO_FAST_WAKEUP);
      errors = errors + 1;
    end
    if (SlvpredctlModule_g_regOut_STORESET_WAIT_STORE !== SlvpredctlModule_i_regOut_STORESET_WAIT_STORE) begin
      $display("MISMATCH SlvpredctlModule.regOut_STORESET_WAIT_STORE cycle=%0d g=%h i=%h", cycle, SlvpredctlModule_g_regOut_STORESET_WAIT_STORE, SlvpredctlModule_i_regOut_STORESET_WAIT_STORE);
      errors = errors + 1;
    end
    if (SlvpredctlModule_g_regOut_NO_SPEC_LOAD !== SlvpredctlModule_i_regOut_NO_SPEC_LOAD) begin
      $display("MISMATCH SlvpredctlModule.regOut_NO_SPEC_LOAD cycle=%0d g=%h i=%h", cycle, SlvpredctlModule_g_regOut_NO_SPEC_LOAD, SlvpredctlModule_i_regOut_NO_SPEC_LOAD);
      errors = errors + 1;
    end
    if (SlvpredctlModule_g_regOut_LVPRED_DISABLE !== SlvpredctlModule_i_regOut_LVPRED_DISABLE) begin
      $display("MISMATCH SlvpredctlModule.regOut_LVPRED_DISABLE cycle=%0d g=%h i=%h", cycle, SlvpredctlModule_g_regOut_LVPRED_DISABLE, SlvpredctlModule_i_regOut_LVPRED_DISABLE);
      errors = errors + 1;
    end
    if (SmblockctlModule_g_rdata !== SmblockctlModule_i_rdata) begin
      $display("MISMATCH SmblockctlModule.rdata cycle=%0d g=%h i=%h", cycle, SmblockctlModule_g_rdata, SmblockctlModule_i_rdata);
      errors = errors + 1;
    end
    if (SmblockctlModule_g_regOut_SBUFFER_TIMEOUT !== SmblockctlModule_i_regOut_SBUFFER_TIMEOUT) begin
      $display("MISMATCH SmblockctlModule.regOut_SBUFFER_TIMEOUT cycle=%0d g=%h i=%h", cycle, SmblockctlModule_g_regOut_SBUFFER_TIMEOUT, SmblockctlModule_i_regOut_SBUFFER_TIMEOUT);
      errors = errors + 1;
    end
    if (SmblockctlModule_g_regOut_HD_MISALIGN_LD_ENABLE !== SmblockctlModule_i_regOut_HD_MISALIGN_LD_ENABLE) begin
      $display("MISMATCH SmblockctlModule.regOut_HD_MISALIGN_LD_ENABLE cycle=%0d g=%h i=%h", cycle, SmblockctlModule_g_regOut_HD_MISALIGN_LD_ENABLE, SmblockctlModule_i_regOut_HD_MISALIGN_LD_ENABLE);
      errors = errors + 1;
    end
    if (SmblockctlModule_g_regOut_HD_MISALIGN_ST_ENABLE !== SmblockctlModule_i_regOut_HD_MISALIGN_ST_ENABLE) begin
      $display("MISMATCH SmblockctlModule.regOut_HD_MISALIGN_ST_ENABLE cycle=%0d g=%h i=%h", cycle, SmblockctlModule_g_regOut_HD_MISALIGN_ST_ENABLE, SmblockctlModule_i_regOut_HD_MISALIGN_ST_ENABLE);
      errors = errors + 1;
    end
    if (SmblockctlModule_g_regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE !== SmblockctlModule_i_regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE) begin
      $display("MISMATCH SmblockctlModule.regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE cycle=%0d g=%h i=%h", cycle, SmblockctlModule_g_regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE, SmblockctlModule_i_regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE);
      errors = errors + 1;
    end
    if (SmblockctlModule_g_regOut_CACHE_ERROR_ENABLE !== SmblockctlModule_i_regOut_CACHE_ERROR_ENABLE) begin
      $display("MISMATCH SmblockctlModule.regOut_CACHE_ERROR_ENABLE cycle=%0d g=%h i=%h", cycle, SmblockctlModule_g_regOut_CACHE_ERROR_ENABLE, SmblockctlModule_i_regOut_CACHE_ERROR_ENABLE);
      errors = errors + 1;
    end
    if (SmblockctlModule_g_regOut_SOFT_PREFETCH_ENABLE !== SmblockctlModule_i_regOut_SOFT_PREFETCH_ENABLE) begin
      $display("MISMATCH SmblockctlModule.regOut_SOFT_PREFETCH_ENABLE cycle=%0d g=%h i=%h", cycle, SmblockctlModule_g_regOut_SOFT_PREFETCH_ENABLE, SmblockctlModule_i_regOut_SOFT_PREFETCH_ENABLE);
      errors = errors + 1;
    end
    if (SmblockctlModule_g_regOut_LDLD_VIO_CHECK_ENABLE !== SmblockctlModule_i_regOut_LDLD_VIO_CHECK_ENABLE) begin
      $display("MISMATCH SmblockctlModule.regOut_LDLD_VIO_CHECK_ENABLE cycle=%0d g=%h i=%h", cycle, SmblockctlModule_g_regOut_LDLD_VIO_CHECK_ENABLE, SmblockctlModule_i_regOut_LDLD_VIO_CHECK_ENABLE);
      errors = errors + 1;
    end
    if (SmblockctlModule_g_regOut_SBUFFER_THRESHOLD !== SmblockctlModule_i_regOut_SBUFFER_THRESHOLD) begin
      $display("MISMATCH SmblockctlModule.regOut_SBUFFER_THRESHOLD cycle=%0d g=%h i=%h", cycle, SmblockctlModule_g_regOut_SBUFFER_THRESHOLD, SmblockctlModule_i_regOut_SBUFFER_THRESHOLD);
      errors = errors + 1;
    end
    if (SpfctlModule_g_rdata !== SpfctlModule_i_rdata) begin
      $display("MISMATCH SpfctlModule.rdata cycle=%0d g=%h i=%h", cycle, SpfctlModule_g_rdata, SpfctlModule_i_rdata);
      errors = errors + 1;
    end
    if (SpfctlModule_g_regOut_L2_PF_DELAY_LATENCY !== SpfctlModule_i_regOut_L2_PF_DELAY_LATENCY) begin
      $display("MISMATCH SpfctlModule.regOut_L2_PF_DELAY_LATENCY cycle=%0d g=%h i=%h", cycle, SpfctlModule_g_regOut_L2_PF_DELAY_LATENCY, SpfctlModule_i_regOut_L2_PF_DELAY_LATENCY);
      errors = errors + 1;
    end
    if (SpfctlModule_g_regOut_L2_PF_TP_ENABLE !== SpfctlModule_i_regOut_L2_PF_TP_ENABLE) begin
      $display("MISMATCH SpfctlModule.regOut_L2_PF_TP_ENABLE cycle=%0d g=%h i=%h", cycle, SpfctlModule_g_regOut_L2_PF_TP_ENABLE, SpfctlModule_i_regOut_L2_PF_TP_ENABLE);
      errors = errors + 1;
    end
    if (SpfctlModule_g_regOut_L2_PF_VBOP_ENABLE !== SpfctlModule_i_regOut_L2_PF_VBOP_ENABLE) begin
      $display("MISMATCH SpfctlModule.regOut_L2_PF_VBOP_ENABLE cycle=%0d g=%h i=%h", cycle, SpfctlModule_g_regOut_L2_PF_VBOP_ENABLE, SpfctlModule_i_regOut_L2_PF_VBOP_ENABLE);
      errors = errors + 1;
    end
    if (SpfctlModule_g_regOut_L2_PF_PBOP_ENABLE !== SpfctlModule_i_regOut_L2_PF_PBOP_ENABLE) begin
      $display("MISMATCH SpfctlModule.regOut_L2_PF_PBOP_ENABLE cycle=%0d g=%h i=%h", cycle, SpfctlModule_g_regOut_L2_PF_PBOP_ENABLE, SpfctlModule_i_regOut_L2_PF_PBOP_ENABLE);
      errors = errors + 1;
    end
    if (SpfctlModule_g_regOut_L2_PF_RECV_ENABLE !== SpfctlModule_i_regOut_L2_PF_RECV_ENABLE) begin
      $display("MISMATCH SpfctlModule.regOut_L2_PF_RECV_ENABLE cycle=%0d g=%h i=%h", cycle, SpfctlModule_g_regOut_L2_PF_RECV_ENABLE, SpfctlModule_i_regOut_L2_PF_RECV_ENABLE);
      errors = errors + 1;
    end
    if (SpfctlModule_g_regOut_L2_PF_STORE_ONLY !== SpfctlModule_i_regOut_L2_PF_STORE_ONLY) begin
      $display("MISMATCH SpfctlModule.regOut_L2_PF_STORE_ONLY cycle=%0d g=%h i=%h", cycle, SpfctlModule_g_regOut_L2_PF_STORE_ONLY, SpfctlModule_i_regOut_L2_PF_STORE_ONLY);
      errors = errors + 1;
    end
    if (SpfctlModule_g_regOut_L1D_PF_ENABLE_STRIDE !== SpfctlModule_i_regOut_L1D_PF_ENABLE_STRIDE) begin
      $display("MISMATCH SpfctlModule.regOut_L1D_PF_ENABLE_STRIDE cycle=%0d g=%h i=%h", cycle, SpfctlModule_g_regOut_L1D_PF_ENABLE_STRIDE, SpfctlModule_i_regOut_L1D_PF_ENABLE_STRIDE);
      errors = errors + 1;
    end
    if (SpfctlModule_g_regOut_L1D_PF_ACTIVE_STRIDE !== SpfctlModule_i_regOut_L1D_PF_ACTIVE_STRIDE) begin
      $display("MISMATCH SpfctlModule.regOut_L1D_PF_ACTIVE_STRIDE cycle=%0d g=%h i=%h", cycle, SpfctlModule_g_regOut_L1D_PF_ACTIVE_STRIDE, SpfctlModule_i_regOut_L1D_PF_ACTIVE_STRIDE);
      errors = errors + 1;
    end
    if (SpfctlModule_g_regOut_L1D_PF_ACTIVE_THRESHOLD !== SpfctlModule_i_regOut_L1D_PF_ACTIVE_THRESHOLD) begin
      $display("MISMATCH SpfctlModule.regOut_L1D_PF_ACTIVE_THRESHOLD cycle=%0d g=%h i=%h", cycle, SpfctlModule_g_regOut_L1D_PF_ACTIVE_THRESHOLD, SpfctlModule_i_regOut_L1D_PF_ACTIVE_THRESHOLD);
      errors = errors + 1;
    end
    if (SpfctlModule_g_regOut_L1D_PF_ENABLE_PHT !== SpfctlModule_i_regOut_L1D_PF_ENABLE_PHT) begin
      $display("MISMATCH SpfctlModule.regOut_L1D_PF_ENABLE_PHT cycle=%0d g=%h i=%h", cycle, SpfctlModule_g_regOut_L1D_PF_ENABLE_PHT, SpfctlModule_i_regOut_L1D_PF_ENABLE_PHT);
      errors = errors + 1;
    end
    if (SpfctlModule_g_regOut_L1D_PF_ENABLE_AGT !== SpfctlModule_i_regOut_L1D_PF_ENABLE_AGT) begin
      $display("MISMATCH SpfctlModule.regOut_L1D_PF_ENABLE_AGT cycle=%0d g=%h i=%h", cycle, SpfctlModule_g_regOut_L1D_PF_ENABLE_AGT, SpfctlModule_i_regOut_L1D_PF_ENABLE_AGT);
      errors = errors + 1;
    end
    if (SpfctlModule_g_regOut_L1D_PF_TRAIN_ON_HIT !== SpfctlModule_i_regOut_L1D_PF_TRAIN_ON_HIT) begin
      $display("MISMATCH SpfctlModule.regOut_L1D_PF_TRAIN_ON_HIT cycle=%0d g=%h i=%h", cycle, SpfctlModule_g_regOut_L1D_PF_TRAIN_ON_HIT, SpfctlModule_i_regOut_L1D_PF_TRAIN_ON_HIT);
      errors = errors + 1;
    end
    if (SpfctlModule_g_regOut_L1D_PF_ENABLE !== SpfctlModule_i_regOut_L1D_PF_ENABLE) begin
      $display("MISMATCH SpfctlModule.regOut_L1D_PF_ENABLE cycle=%0d g=%h i=%h", cycle, SpfctlModule_g_regOut_L1D_PF_ENABLE, SpfctlModule_i_regOut_L1D_PF_ENABLE);
      errors = errors + 1;
    end
    if (SpfctlModule_g_regOut_L2_PF_ENABLE !== SpfctlModule_i_regOut_L2_PF_ENABLE) begin
      $display("MISMATCH SpfctlModule.regOut_L2_PF_ENABLE cycle=%0d g=%h i=%h", cycle, SpfctlModule_g_regOut_L2_PF_ENABLE, SpfctlModule_i_regOut_L2_PF_ENABLE);
      errors = errors + 1;
    end
    if (SpfctlModule_g_regOut_L1I_PF_ENABLE !== SpfctlModule_i_regOut_L1I_PF_ENABLE) begin
      $display("MISMATCH SpfctlModule.regOut_L1I_PF_ENABLE cycle=%0d g=%h i=%h", cycle, SpfctlModule_g_regOut_L1I_PF_ENABLE, SpfctlModule_i_regOut_L1I_PF_ENABLE);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_privState_valid !== SretEventModule_i_out_privState_valid) begin
      $display("MISMATCH SretEventModule.out_privState_valid cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_privState_valid, SretEventModule_i_out_privState_valid);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_privState_bits_PRVM !== SretEventModule_i_out_privState_bits_PRVM) begin
      $display("MISMATCH SretEventModule.out_privState_bits_PRVM cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_privState_bits_PRVM, SretEventModule_i_out_privState_bits_PRVM);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_privState_bits_V !== SretEventModule_i_out_privState_bits_V) begin
      $display("MISMATCH SretEventModule.out_privState_bits_V cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_privState_bits_V, SretEventModule_i_out_privState_bits_V);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_valid !== SretEventModule_i_out_mstatus_valid) begin
      $display("MISMATCH SretEventModule.out_mstatus_valid cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_valid, SretEventModule_i_out_mstatus_valid);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_SIE !== SretEventModule_i_out_mstatus_bits_SIE) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_SIE cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_SIE, SretEventModule_i_out_mstatus_bits_SIE);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_MIE !== SretEventModule_i_out_mstatus_bits_MIE) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_MIE cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_MIE, SretEventModule_i_out_mstatus_bits_MIE);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_SPIE !== SretEventModule_i_out_mstatus_bits_SPIE) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_SPIE cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_SPIE, SretEventModule_i_out_mstatus_bits_SPIE);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_UBE !== SretEventModule_i_out_mstatus_bits_UBE) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_UBE cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_UBE, SretEventModule_i_out_mstatus_bits_UBE);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_MPIE !== SretEventModule_i_out_mstatus_bits_MPIE) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_MPIE cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_MPIE, SretEventModule_i_out_mstatus_bits_MPIE);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_SPP !== SretEventModule_i_out_mstatus_bits_SPP) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_SPP cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_SPP, SretEventModule_i_out_mstatus_bits_SPP);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_VS !== SretEventModule_i_out_mstatus_bits_VS) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_VS cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_VS, SretEventModule_i_out_mstatus_bits_VS);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_MPP !== SretEventModule_i_out_mstatus_bits_MPP) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_MPP cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_MPP, SretEventModule_i_out_mstatus_bits_MPP);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_FS !== SretEventModule_i_out_mstatus_bits_FS) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_FS cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_FS, SretEventModule_i_out_mstatus_bits_FS);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_XS !== SretEventModule_i_out_mstatus_bits_XS) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_XS cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_XS, SretEventModule_i_out_mstatus_bits_XS);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_MPRV !== SretEventModule_i_out_mstatus_bits_MPRV) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_MPRV cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_MPRV, SretEventModule_i_out_mstatus_bits_MPRV);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_SUM !== SretEventModule_i_out_mstatus_bits_SUM) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_SUM cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_SUM, SretEventModule_i_out_mstatus_bits_SUM);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_MXR !== SretEventModule_i_out_mstatus_bits_MXR) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_MXR cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_MXR, SretEventModule_i_out_mstatus_bits_MXR);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_TVM !== SretEventModule_i_out_mstatus_bits_TVM) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_TVM cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_TVM, SretEventModule_i_out_mstatus_bits_TVM);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_TW !== SretEventModule_i_out_mstatus_bits_TW) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_TW cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_TW, SretEventModule_i_out_mstatus_bits_TW);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_TSR !== SretEventModule_i_out_mstatus_bits_TSR) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_TSR cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_TSR, SretEventModule_i_out_mstatus_bits_TSR);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_SDT !== SretEventModule_i_out_mstatus_bits_SDT) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_SDT cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_SDT, SretEventModule_i_out_mstatus_bits_SDT);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_UXL !== SretEventModule_i_out_mstatus_bits_UXL) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_UXL cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_UXL, SretEventModule_i_out_mstatus_bits_UXL);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_SXL !== SretEventModule_i_out_mstatus_bits_SXL) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_SXL cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_SXL, SretEventModule_i_out_mstatus_bits_SXL);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_SBE !== SretEventModule_i_out_mstatus_bits_SBE) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_SBE cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_SBE, SretEventModule_i_out_mstatus_bits_SBE);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_MBE !== SretEventModule_i_out_mstatus_bits_MBE) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_MBE cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_MBE, SretEventModule_i_out_mstatus_bits_MBE);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_GVA !== SretEventModule_i_out_mstatus_bits_GVA) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_GVA cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_GVA, SretEventModule_i_out_mstatus_bits_GVA);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_MPV !== SretEventModule_i_out_mstatus_bits_MPV) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_MPV cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_MPV, SretEventModule_i_out_mstatus_bits_MPV);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_MDT !== SretEventModule_i_out_mstatus_bits_MDT) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_MDT cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_MDT, SretEventModule_i_out_mstatus_bits_MDT);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_mstatus_bits_SD !== SretEventModule_i_out_mstatus_bits_SD) begin
      $display("MISMATCH SretEventModule.out_mstatus_bits_SD cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_mstatus_bits_SD, SretEventModule_i_out_mstatus_bits_SD);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_hstatus_valid !== SretEventModule_i_out_hstatus_valid) begin
      $display("MISMATCH SretEventModule.out_hstatus_valid cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_hstatus_valid, SretEventModule_i_out_hstatus_valid);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_hstatus_bits_VSBE !== SretEventModule_i_out_hstatus_bits_VSBE) begin
      $display("MISMATCH SretEventModule.out_hstatus_bits_VSBE cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_hstatus_bits_VSBE, SretEventModule_i_out_hstatus_bits_VSBE);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_hstatus_bits_GVA !== SretEventModule_i_out_hstatus_bits_GVA) begin
      $display("MISMATCH SretEventModule.out_hstatus_bits_GVA cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_hstatus_bits_GVA, SretEventModule_i_out_hstatus_bits_GVA);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_hstatus_bits_SPV !== SretEventModule_i_out_hstatus_bits_SPV) begin
      $display("MISMATCH SretEventModule.out_hstatus_bits_SPV cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_hstatus_bits_SPV, SretEventModule_i_out_hstatus_bits_SPV);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_hstatus_bits_SPVP !== SretEventModule_i_out_hstatus_bits_SPVP) begin
      $display("MISMATCH SretEventModule.out_hstatus_bits_SPVP cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_hstatus_bits_SPVP, SretEventModule_i_out_hstatus_bits_SPVP);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_hstatus_bits_HU !== SretEventModule_i_out_hstatus_bits_HU) begin
      $display("MISMATCH SretEventModule.out_hstatus_bits_HU cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_hstatus_bits_HU, SretEventModule_i_out_hstatus_bits_HU);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_hstatus_bits_VGEIN !== SretEventModule_i_out_hstatus_bits_VGEIN) begin
      $display("MISMATCH SretEventModule.out_hstatus_bits_VGEIN cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_hstatus_bits_VGEIN, SretEventModule_i_out_hstatus_bits_VGEIN);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_hstatus_bits_VTVM !== SretEventModule_i_out_hstatus_bits_VTVM) begin
      $display("MISMATCH SretEventModule.out_hstatus_bits_VTVM cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_hstatus_bits_VTVM, SretEventModule_i_out_hstatus_bits_VTVM);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_hstatus_bits_VTW !== SretEventModule_i_out_hstatus_bits_VTW) begin
      $display("MISMATCH SretEventModule.out_hstatus_bits_VTW cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_hstatus_bits_VTW, SretEventModule_i_out_hstatus_bits_VTW);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_hstatus_bits_VTSR !== SretEventModule_i_out_hstatus_bits_VTSR) begin
      $display("MISMATCH SretEventModule.out_hstatus_bits_VTSR cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_hstatus_bits_VTSR, SretEventModule_i_out_hstatus_bits_VTSR);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_hstatus_bits_VSXL !== SretEventModule_i_out_hstatus_bits_VSXL) begin
      $display("MISMATCH SretEventModule.out_hstatus_bits_VSXL cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_hstatus_bits_VSXL, SretEventModule_i_out_hstatus_bits_VSXL);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_hstatus_bits_HUPMM !== SretEventModule_i_out_hstatus_bits_HUPMM) begin
      $display("MISMATCH SretEventModule.out_hstatus_bits_HUPMM cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_hstatus_bits_HUPMM, SretEventModule_i_out_hstatus_bits_HUPMM);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_vsstatus_valid !== SretEventModule_i_out_vsstatus_valid) begin
      $display("MISMATCH SretEventModule.out_vsstatus_valid cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_vsstatus_valid, SretEventModule_i_out_vsstatus_valid);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_vsstatus_bits_SIE !== SretEventModule_i_out_vsstatus_bits_SIE) begin
      $display("MISMATCH SretEventModule.out_vsstatus_bits_SIE cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_vsstatus_bits_SIE, SretEventModule_i_out_vsstatus_bits_SIE);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_vsstatus_bits_SPIE !== SretEventModule_i_out_vsstatus_bits_SPIE) begin
      $display("MISMATCH SretEventModule.out_vsstatus_bits_SPIE cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_vsstatus_bits_SPIE, SretEventModule_i_out_vsstatus_bits_SPIE);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_vsstatus_bits_UBE !== SretEventModule_i_out_vsstatus_bits_UBE) begin
      $display("MISMATCH SretEventModule.out_vsstatus_bits_UBE cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_vsstatus_bits_UBE, SretEventModule_i_out_vsstatus_bits_UBE);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_vsstatus_bits_SPP !== SretEventModule_i_out_vsstatus_bits_SPP) begin
      $display("MISMATCH SretEventModule.out_vsstatus_bits_SPP cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_vsstatus_bits_SPP, SretEventModule_i_out_vsstatus_bits_SPP);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_vsstatus_bits_VS !== SretEventModule_i_out_vsstatus_bits_VS) begin
      $display("MISMATCH SretEventModule.out_vsstatus_bits_VS cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_vsstatus_bits_VS, SretEventModule_i_out_vsstatus_bits_VS);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_vsstatus_bits_FS !== SretEventModule_i_out_vsstatus_bits_FS) begin
      $display("MISMATCH SretEventModule.out_vsstatus_bits_FS cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_vsstatus_bits_FS, SretEventModule_i_out_vsstatus_bits_FS);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_vsstatus_bits_XS !== SretEventModule_i_out_vsstatus_bits_XS) begin
      $display("MISMATCH SretEventModule.out_vsstatus_bits_XS cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_vsstatus_bits_XS, SretEventModule_i_out_vsstatus_bits_XS);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_vsstatus_bits_SUM !== SretEventModule_i_out_vsstatus_bits_SUM) begin
      $display("MISMATCH SretEventModule.out_vsstatus_bits_SUM cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_vsstatus_bits_SUM, SretEventModule_i_out_vsstatus_bits_SUM);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_vsstatus_bits_MXR !== SretEventModule_i_out_vsstatus_bits_MXR) begin
      $display("MISMATCH SretEventModule.out_vsstatus_bits_MXR cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_vsstatus_bits_MXR, SretEventModule_i_out_vsstatus_bits_MXR);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_vsstatus_bits_SDT !== SretEventModule_i_out_vsstatus_bits_SDT) begin
      $display("MISMATCH SretEventModule.out_vsstatus_bits_SDT cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_vsstatus_bits_SDT, SretEventModule_i_out_vsstatus_bits_SDT);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_vsstatus_bits_UXL !== SretEventModule_i_out_vsstatus_bits_UXL) begin
      $display("MISMATCH SretEventModule.out_vsstatus_bits_UXL cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_vsstatus_bits_UXL, SretEventModule_i_out_vsstatus_bits_UXL);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_vsstatus_bits_SD !== SretEventModule_i_out_vsstatus_bits_SD) begin
      $display("MISMATCH SretEventModule.out_vsstatus_bits_SD cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_vsstatus_bits_SD, SretEventModule_i_out_vsstatus_bits_SD);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_targetPc_valid !== SretEventModule_i_out_targetPc_valid) begin
      $display("MISMATCH SretEventModule.out_targetPc_valid cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_targetPc_valid, SretEventModule_i_out_targetPc_valid);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_targetPc_bits_pc !== SretEventModule_i_out_targetPc_bits_pc) begin
      $display("MISMATCH SretEventModule.out_targetPc_bits_pc cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_targetPc_bits_pc, SretEventModule_i_out_targetPc_bits_pc);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_targetPc_bits_raiseIPF !== SretEventModule_i_out_targetPc_bits_raiseIPF) begin
      $display("MISMATCH SretEventModule.out_targetPc_bits_raiseIPF cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_targetPc_bits_raiseIPF, SretEventModule_i_out_targetPc_bits_raiseIPF);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_targetPc_bits_raiseIAF !== SretEventModule_i_out_targetPc_bits_raiseIAF) begin
      $display("MISMATCH SretEventModule.out_targetPc_bits_raiseIAF cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_targetPc_bits_raiseIAF, SretEventModule_i_out_targetPc_bits_raiseIAF);
      errors = errors + 1;
    end
    if (SretEventModule_g_out_targetPc_bits_raiseIGPF !== SretEventModule_i_out_targetPc_bits_raiseIGPF) begin
      $display("MISMATCH SretEventModule.out_targetPc_bits_raiseIGPF cycle=%0d g=%h i=%h", cycle, SretEventModule_g_out_targetPc_bits_raiseIGPF, SretEventModule_i_out_targetPc_bits_raiseIGPF);
      errors = errors + 1;
    end
    if (SretEventModule_g_outSDT_vsstatus_valid !== SretEventModule_i_outSDT_vsstatus_valid) begin
      $display("MISMATCH SretEventModule.outSDT_vsstatus_valid cycle=%0d g=%h i=%h", cycle, SretEventModule_g_outSDT_vsstatus_valid, SretEventModule_i_outSDT_vsstatus_valid);
      errors = errors + 1;
    end
    if (SrnctlModule_g_rdata !== SrnctlModule_i_rdata) begin
      $display("MISMATCH SrnctlModule.rdata cycle=%0d g=%h i=%h", cycle, SrnctlModule_g_rdata, SrnctlModule_i_rdata);
      errors = errors + 1;
    end
    if (SrnctlModule_g_regOut_WFI_ENABLE !== SrnctlModule_i_regOut_WFI_ENABLE) begin
      $display("MISMATCH SrnctlModule.regOut_WFI_ENABLE cycle=%0d g=%h i=%h", cycle, SrnctlModule_g_regOut_WFI_ENABLE, SrnctlModule_i_regOut_WFI_ENABLE);
      errors = errors + 1;
    end
    if (SrnctlModule_g_regOut_FUSION_ENABLE !== SrnctlModule_i_regOut_FUSION_ENABLE) begin
      $display("MISMATCH SrnctlModule.regOut_FUSION_ENABLE cycle=%0d g=%h i=%h", cycle, SrnctlModule_g_regOut_FUSION_ENABLE, SrnctlModule_i_regOut_FUSION_ENABLE);
      errors = errors + 1;
    end
    if (Sstateen0Module_g_rdata !== Sstateen0Module_i_rdata) begin
      $display("MISMATCH Sstateen0Module.rdata cycle=%0d g=%h i=%h", cycle, Sstateen0Module_g_rdata, Sstateen0Module_i_rdata);
      errors = errors + 1;
    end
    if (Sstateen0Module_g_regOut_JVT !== Sstateen0Module_i_regOut_JVT) begin
      $display("MISMATCH Sstateen0Module.regOut_JVT cycle=%0d g=%h i=%h", cycle, Sstateen0Module_g_regOut_JVT, Sstateen0Module_i_regOut_JVT);
      errors = errors + 1;
    end
    if (Sstateen0Module_g_regOut_FCSR !== Sstateen0Module_i_regOut_FCSR) begin
      $display("MISMATCH Sstateen0Module.regOut_FCSR cycle=%0d g=%h i=%h", cycle, Sstateen0Module_g_regOut_FCSR, Sstateen0Module_i_regOut_FCSR);
      errors = errors + 1;
    end
    if (Sstateen0Module_g_regOut_C !== Sstateen0Module_i_regOut_C) begin
      $display("MISMATCH Sstateen0Module.regOut_C cycle=%0d g=%h i=%h", cycle, Sstateen0Module_g_regOut_C, Sstateen0Module_i_regOut_C);
      errors = errors + 1;
    end
    if (StimecmpModule_g_rdata !== StimecmpModule_i_rdata) begin
      $display("MISMATCH StimecmpModule.rdata cycle=%0d g=%h i=%h", cycle, StimecmpModule_g_rdata, StimecmpModule_i_rdata);
      errors = errors + 1;
    end
    if (StimecmpModule_g_regOut_stimecmp !== StimecmpModule_i_regOut_stimecmp) begin
      $display("MISMATCH StimecmpModule.regOut_stimecmp cycle=%0d g=%h i=%h", cycle, StimecmpModule_g_regOut_stimecmp, StimecmpModule_i_regOut_stimecmp);
      errors = errors + 1;
    end
    if (TrapInstMod_g_io_currentTrapInst_valid !== TrapInstMod_i_io_currentTrapInst_valid) begin
      $display("MISMATCH TrapInstMod.io_currentTrapInst_valid cycle=%0d g=%h i=%h", cycle, TrapInstMod_g_io_currentTrapInst_valid, TrapInstMod_i_io_currentTrapInst_valid);
      errors = errors + 1;
    end
    if (TrapInstMod_g_io_currentTrapInst_bits !== TrapInstMod_i_io_currentTrapInst_bits) begin
      $display("MISMATCH TrapInstMod.io_currentTrapInst_bits cycle=%0d g=%h i=%h", cycle, TrapInstMod_g_io_currentTrapInst_bits, TrapInstMod_i_io_currentTrapInst_bits);
      errors = errors + 1;
    end
    if (TrapTvalMod_g_io_tval !== TrapTvalMod_i_io_tval) begin
      $display("MISMATCH TrapTvalMod.io_tval cycle=%0d g=%h i=%h", cycle, TrapTvalMod_g_io_tval, TrapTvalMod_i_io_tval);
      errors = errors + 1;
    end
      end
      if (errors > 20) $fatal(1, "too many mismatches");
    end
    if (errors == 0) $display("TEST PASSED cycles=%0d", ncycles);
    else $fatal(1, "TEST FAILED errors=%0d", errors);
    $finish;
  end
endmodule
