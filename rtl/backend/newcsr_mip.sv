// NewCSR bespoke module: MipModule (machine interrupt-pending CSR aggregator).
//
// Faithful, readable reimplementation of the golden MipModule. Unlike the
// regular CSR-field families, mip is a control aggregator: most of its bits are
// not architected registers but live wires assembled from external interrupt
// sources (platform IRP, AIA, hypervisor virtual interrupts, hgeip masking).
// Only three bits carry state: SSIP, STIP, LCOFIP. Everything below is
// transcribed bit-for-bit from golden; comments name the RISC-V semantics.
//
// State (async-reset-0) with source-arbitrated writes:
//   reg_SSIP  : supervisor soft IP. Written from the mvip/sip delegation
//               channels when either is valid, else from a direct CSR write.
//   reg_STIP  : supervisor timer IP. Only writable while Sstc (menvcfg.STCE) is
//               OFF; combines CSR write and the mvip channel.
//   reg_LCOFIP: local counter-overflow IP. Written from sip/vsip channels or a
//               CSR write; a bare lcofiReq pulse sets it when no write occurs.
//
// Combinational (live) fields:
//   STIP read : Sstc ON -> platform IRP timer; else the SSIP-style register.
//   VSTIP     : hvip.VSTIP | platform VS-timer.
//   SEIP reg  : ~mvien.SEIE & mvip.SEIP  (only architected here when not
//               delegated to mvien).
//   SEIP rdata: adds platform SEIP and AIA seip on top of the reg view.
//   VSEIP     : hvip.VSEIP | (hgeip >> hstatusVGEIN)[0]  (selected guest ext IP).
//   MEIP      : platform MEIP | AIA meip.
//   SGEIP     : OR-reduce of (hgeip & hgeie)  (any enabled guest ext IP).

module xs_mip (
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

  reg         reg_SSIP;
  reg         reg_STIP;
  reg         reg_LCOFIP;

  // ---- live (combinational) field views ----
  wire        STIP_view  = menvcfg_STCE ? platformIRP_STIP : reg_STIP;
  wire        VSTIP_view = hvip_VSTIP | platformIRP_VSTIP;
  wire        SEIP_reg   = ~mvien_SEIE & mvip_SEIP;
  wire        SEIP_rdata = SEIP_reg | platformIRP_SEIP | aiaToCSR_seip;
  // Select the guest-external IP addressed by hstatusVGEIN out of hgeip. Golden
  // packs {58'h0, hgeip[4:0], 1'h0} and right-shifts by VGEIN; bit0 is the pick.
  wire [63:0] vgein_sh   = {58'h0, hgeip_ip, 1'h0} >> hstatusVGEIN;
  wire        VSEIP_view = hvip_VSEIP | vgein_sh[0];
  wire        MEIP_view  = platformIRP_MEIP | aiaToCSR_meip;
  wire [4:0]  sgeip_vec  = hgeip_ip & hgeie_ie;   // enabled guest ext IPs
  wire        SGEIP_view = |sgeip_vec;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_SSIP   <= 1'h0;
      reg_STIP   <= 1'h0;
      reg_LCOFIP <= 1'h0;
    end
    else begin
      // SSIP: delegation channels win over a direct CSR write.
      if (fromMvip_SSIP_valid | fromSip_SSIP_valid)
        reg_SSIP <= (fromMvip_SSIP_valid & fromMvip_SSIP_bits)
                  | (fromSip_SSIP_valid  & fromSip_SSIP_bits);
      else if (w_wen)
        reg_SSIP <= w_wdata[1];

      // STIP: only mutable while Sstc is off; OR of CSR write and mvip channel.
      if ((w_wen | fromMvip_STIP_valid) & ~menvcfg_STCE)
        reg_STIP <= (w_wen & w_wdata[5])
                  | (fromMvip_STIP_valid & fromMvip_STIP_bits);

      // LCOFIP: sip/vsip channels or CSR write; bare lcofiReq sets otherwise.
      if (fromSip_LCOFIP_valid | fromVSip_LCOFIP_valid | w_wen)
        reg_LCOFIP <= (fromSip_LCOFIP_valid  & fromSip_LCOFIP_bits)
                    | (fromVSip_LCOFIP_valid & fromVSip_LCOFIP_bits)
                    | (w_wen & w_wdata[13]);
      else if (lcofiReq)
        reg_LCOFIP <= lcofiReq;
    end
  end

  // Read view: packed mip register (unimplemented lanes read as 0).
  assign rdata =
    {50'h0,
     reg_LCOFIP,     // [13]
     SGEIP_view,     // [12]
     MEIP_view,      // [11]
     VSEIP_view,     // [10]
     SEIP_rdata,     // [9]
     1'h0,           // [8]
     platformIRP_MTIP, // [7]
     VSTIP_view,     // [6]
     STIP_view,      // [5]
     1'h0,           // [4]
     platformIRP_MSIP, // [3]
     hvip_VSSIP,     // [2]
     reg_SSIP,       // [1]
     1'h0};          // [0]

  assign regOut_SSIP   = reg_SSIP;
  assign regOut_VSSIP  = hvip_VSSIP;
  assign regOut_MSIP   = platformIRP_MSIP;
  assign regOut_STIP   = STIP_view;
  assign regOut_VSTIP  = VSTIP_view;
  assign regOut_MTIP   = platformIRP_MTIP;
  assign regOut_SEIP   = SEIP_reg;
  assign regOut_VSEIP  = VSEIP_view;
  assign regOut_MEIP   = MEIP_view;
  assign regOut_SGEIP  = SGEIP_view;
  assign regOut_LCOFIP = reg_LCOFIP;

  assign rdataFields_SSIP   = reg_SSIP;
  assign rdataFields_VSSIP  = hvip_VSSIP;
  assign rdataFields_MSIP   = platformIRP_MSIP;
  assign rdataFields_STIP   = STIP_view;
  assign rdataFields_VSTIP  = VSTIP_view;
  assign rdataFields_MTIP   = platformIRP_MTIP;
  assign rdataFields_SEIP   = SEIP_rdata;
  assign rdataFields_VSEIP  = VSEIP_view;
  assign rdataFields_MEIP   = MEIP_view;
  assign rdataFields_SGEIP  = SGEIP_view;
  assign rdataFields_LCOFIP = reg_LCOFIP;

  // Outbound delegation writebacks (CSR write forwarded to mvip / hvip).
  assign toMvip_SEIP_valid  = w_wen & ~mvien_SEIE;
  assign toMvip_SEIP_bits   = w_wdata[9];
  assign toHvip_VSSIP_valid = w_wen;
  assign toHvip_VSSIP_bits  = w_wdata[2];

endmodule
