// MipModule.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_MipModule_core(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic regOut_SSIP,
  output logic regOut_VSSIP,
  output logic regOut_MSIP,
  output logic regOut_STIP,
  output logic regOut_VSTIP,
  output logic regOut_MTIP,
  output logic regOut_SEIP,
  output logic regOut_VSEIP,
  output logic regOut_MEIP,
  output logic regOut_SGEIP,
  output logic regOut_LCOFIP,
  output logic rdataFields_SSIP,
  output logic rdataFields_VSSIP,
  output logic rdataFields_MSIP,
  output logic rdataFields_STIP,
  output logic rdataFields_VSTIP,
  output logic rdataFields_MTIP,
  output logic rdataFields_SEIP,
  output logic rdataFields_VSEIP,
  output logic rdataFields_MEIP,
  output logic rdataFields_SGEIP,
  output logic rdataFields_LCOFIP,
  input         mvip_SEIP,
  input         mvien_SEIE,
  input         hvip_VSSIP,
  input         hvip_VSTIP,
  input         hvip_VSEIP,
  input  [6:0]  hgeip_ip,
  input  [6:0]  hgeie_ie,
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
  output logic toMvip_SEIP_valid,
  output logic toMvip_SEIP_bits,
  output logic toHvip_VSSIP_valid,
  output logic toHvip_VSSIP_bits
);
logic [6:0]  hgeip_enabled;
  logic        meip_pending;
  logic        vseip_pending;
  logic        seip_fields;
  logic        vstip_pending;
  logic        stip_pending;
  logic         ssip_q;
  logic         stip_q;
  logic         lcofip_q;
  always_comb begin
    stip_pending = menvcfg_STCE ? platformIRP_STIP : stip_q;
  end
  always_comb begin
    vstip_pending = hvip_VSTIP | platformIRP_VSTIP;
  end
  logic seip_pending;
  always_comb begin
    seip_pending = ~mvien_SEIE & mvip_SEIP;
  end
  always_comb begin
    seip_fields = seip_pending | platformIRP_SEIP | aiaToCSR_seip;
  end
  logic [63:0] hgeip_selected;
  always_comb begin
    hgeip_selected = {56'h0, hgeip_ip, 1'h0} >> hstatusVGEIN;
  end
  always_comb begin
    vseip_pending = hvip_VSEIP | hgeip_selected[0];
  end
  always_comb begin
    meip_pending = platformIRP_MEIP | aiaToCSR_meip;
  end
  always_comb begin
    hgeip_enabled = hgeip_ip & hgeie_ie;
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      ssip_q <= 1'h0;
      stip_q <= 1'h0;
      lcofip_q <= 1'h0;
    end
    else begin
      if (fromMvip_SSIP_valid | fromSip_SSIP_valid)
        ssip_q <=
          fromMvip_SSIP_valid & fromMvip_SSIP_bits | fromSip_SSIP_valid
          & fromSip_SSIP_bits;
      else if (w_wen)
        ssip_q <= w_wdata[1];
      if ((w_wen | fromMvip_STIP_valid) & ~menvcfg_STCE)
        stip_q <= w_wen & w_wdata[5] | fromMvip_STIP_valid & fromMvip_STIP_bits;
      if (fromSip_LCOFIP_valid | fromVSip_LCOFIP_valid | w_wen)
        lcofip_q <=
          fromSip_LCOFIP_valid & fromSip_LCOFIP_bits | fromVSip_LCOFIP_valid
          & fromVSip_LCOFIP_bits | w_wen & w_wdata[13];
      else if (lcofiReq)
        lcofip_q <= lcofiReq;
    end
  end // always @(posedge, posedge)
always_comb begin
    rdata = {50'h0,
     lcofip_q,
     |hgeip_enabled,
     meip_pending,
     vseip_pending,
     seip_fields,
     1'h0,
     platformIRP_MTIP,
     vstip_pending,
     stip_pending,
     1'h0,
     platformIRP_MSIP,
     hvip_VSSIP,
     ssip_q,
     1'h0};
  end
  always_comb begin
    regOut_SSIP = ssip_q;
  end
  always_comb begin
    regOut_VSSIP = hvip_VSSIP;
  end
  always_comb begin
    regOut_MSIP = platformIRP_MSIP;
  end
  always_comb begin
    regOut_STIP = stip_pending;
  end
  always_comb begin
    regOut_VSTIP = vstip_pending;
  end
  always_comb begin
    regOut_MTIP = platformIRP_MTIP;
  end
  always_comb begin
    regOut_SEIP = seip_pending;
  end
  always_comb begin
    regOut_VSEIP = vseip_pending;
  end
  always_comb begin
    regOut_MEIP = meip_pending;
  end
  always_comb begin
    regOut_SGEIP = |hgeip_enabled;
  end
  always_comb begin
    regOut_LCOFIP = lcofip_q;
  end
  always_comb begin
    rdataFields_SSIP = ssip_q;
  end
  always_comb begin
    rdataFields_VSSIP = hvip_VSSIP;
  end
  always_comb begin
    rdataFields_MSIP = platformIRP_MSIP;
  end
  always_comb begin
    rdataFields_STIP = stip_pending;
  end
  always_comb begin
    rdataFields_VSTIP = vstip_pending;
  end
  always_comb begin
    rdataFields_MTIP = platformIRP_MTIP;
  end
  always_comb begin
    rdataFields_SEIP = seip_fields;
  end
  always_comb begin
    rdataFields_VSEIP = vseip_pending;
  end
  always_comb begin
    rdataFields_MEIP = meip_pending;
  end
  always_comb begin
    rdataFields_SGEIP = |hgeip_enabled;
  end
  always_comb begin
    rdataFields_LCOFIP = lcofip_q;
  end
  always_comb begin
    toMvip_SEIP_valid = w_wen & ~mvien_SEIE;
  end
  always_comb begin
    toMvip_SEIP_bits = w_wdata[9];
  end
  always_comb begin
    toHvip_VSSIP_valid = w_wen;
  end
  always_comb begin
    toHvip_VSSIP_bits = w_wdata[2];
  end
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
  input  [6:0]  hgeip_ip,
  input  [6:0]  hgeie_ie,
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
  xs_MipModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_SSIP(regOut_SSIP),
    .regOut_VSSIP(regOut_VSSIP),
    .regOut_MSIP(regOut_MSIP),
    .regOut_STIP(regOut_STIP),
    .regOut_VSTIP(regOut_VSTIP),
    .regOut_MTIP(regOut_MTIP),
    .regOut_SEIP(regOut_SEIP),
    .regOut_VSEIP(regOut_VSEIP),
    .regOut_MEIP(regOut_MEIP),
    .regOut_SGEIP(regOut_SGEIP),
    .regOut_LCOFIP(regOut_LCOFIP),
    .rdataFields_SSIP(rdataFields_SSIP),
    .rdataFields_VSSIP(rdataFields_VSSIP),
    .rdataFields_MSIP(rdataFields_MSIP),
    .rdataFields_STIP(rdataFields_STIP),
    .rdataFields_VSTIP(rdataFields_VSTIP),
    .rdataFields_MTIP(rdataFields_MTIP),
    .rdataFields_SEIP(rdataFields_SEIP),
    .rdataFields_VSEIP(rdataFields_VSEIP),
    .rdataFields_MEIP(rdataFields_MEIP),
    .rdataFields_SGEIP(rdataFields_SGEIP),
    .rdataFields_LCOFIP(rdataFields_LCOFIP),
    .mvip_SEIP(mvip_SEIP),
    .mvien_SEIE(mvien_SEIE),
    .hvip_VSSIP(hvip_VSSIP),
    .hvip_VSTIP(hvip_VSTIP),
    .hvip_VSEIP(hvip_VSEIP),
    .hgeip_ip(hgeip_ip),
    .hgeie_ie(hgeie_ie),
    .hstatusVGEIN(hstatusVGEIN),
    .platformIRP_MEIP(platformIRP_MEIP),
    .platformIRP_MTIP(platformIRP_MTIP),
    .platformIRP_MSIP(platformIRP_MSIP),
    .platformIRP_SEIP(platformIRP_SEIP),
    .platformIRP_STIP(platformIRP_STIP),
    .platformIRP_VSTIP(platformIRP_VSTIP),
    .menvcfg_STCE(menvcfg_STCE),
    .lcofiReq(lcofiReq),
    .aiaToCSR_meip(aiaToCSR_meip),
    .aiaToCSR_seip(aiaToCSR_seip),
    .fromMvip_SSIP_valid(fromMvip_SSIP_valid),
    .fromMvip_SSIP_bits(fromMvip_SSIP_bits),
    .fromMvip_STIP_valid(fromMvip_STIP_valid),
    .fromMvip_STIP_bits(fromMvip_STIP_bits),
    .fromSip_SSIP_valid(fromSip_SSIP_valid),
    .fromSip_SSIP_bits(fromSip_SSIP_bits),
    .fromSip_LCOFIP_valid(fromSip_LCOFIP_valid),
    .fromSip_LCOFIP_bits(fromSip_LCOFIP_bits),
    .fromVSip_LCOFIP_valid(fromVSip_LCOFIP_valid),
    .fromVSip_LCOFIP_bits(fromVSip_LCOFIP_bits),
    .toMvip_SEIP_valid(toMvip_SEIP_valid),
    .toMvip_SEIP_bits(toMvip_SEIP_bits),
    .toHvip_VSSIP_valid(toHvip_VSSIP_valid),
    .toHvip_VSSIP_bits(toHvip_VSSIP_bits)
  );
endmodule
