// NewCSR CSR-field primitives: Trigger (Sdtrig) tdata1/tdata2 CSRs.
//
// Faithful, readable reimplementation of the golden trigger CSR family
// (10 golden modules):
//
//   xs_tdata_read       Tdata{1,2}Module : pure-comb read of the currently
//                         selected trigger's tdata via tdataRead_tdataN. Both
//                         rdata and regOut_ALL echo the same bus.
//                           rdata = regOut_ALL = tdata_read
//
//   xs_trigger_tdata1   Trigger{0..3}_Tdata1Module : per-trigger tdata1 (the
//                         mcontrol6 trigger control word) with its WARL write
//                         legalization. All four golden instances are byte-
//                         identical, so one primitive covers them. Transcribed
//                         bit-for-bit from golden:
//                           * TYPE is reset to 4'hF (disabled) and is only set
//                             to the written type when the write selects the
//                             mcontrol6 type (w_wdata[63:60]==6). Note golden
//                             has a redundant `else if (w_wen & _GEN)` arm that
//                             re-drives reg_TYPE with the same value the main
//                             w_wen arm already assigned — we keep it verbatim.
//                           * DMODE = w_wdata[59] & canWriteDmode.
//                           * DATA is legalized (match/chain/action/size WARL)
//                             only for a type-6 write, else cleared to 0.
//
//   xs_trigger_tdata2   Trigger{0..3}_Tdata2Module : per-trigger tdata2 (match
//                         value). Plain 64-bit register, NO reset (golden uses
//                         `always @(posedge clock)` only), write on w_wen.
//                         All four golden instances are byte-identical.

// ---------------------------------------------------------------------------
// Tdata{1,2}Module: pure-comb read of the selected trigger's tdata bus.
// ---------------------------------------------------------------------------
module xs_tdata_read (
    output [63:0] rdata,
    output [63:0] regOut_ALL,
    input  [63:0] tdata_read
);
  assign rdata      = tdata_read;
  assign regOut_ALL = tdata_read;
endmodule

// ---------------------------------------------------------------------------
// Trigger{0..3}_Tdata1Module: mcontrol6 trigger control word + WARL write.
// ---------------------------------------------------------------------------
module xs_trigger_tdata1 (
    input         clock,
    input         reset,
    input         w_wen,
    input  [63:0] w_wdata,
    output [63:0] rdata,
    input         canWriteDmode,
    input         chainable
);

  reg  [3:0]  reg_TYPE;
  reg         reg_DMODE;
  reg  [58:0] reg_DATA;

  wire        dmode = w_wdata[59] & canWriteDmode;
  wire        is_mc6 = w_wdata[63:60] == 4'h6;  // written type selects mcontrol6

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_TYPE  <= 4'hF;
      reg_DMODE <= 1'h0;
      reg_DATA  <= 59'h0;
    end
    else if (w_wen) begin
      reg_TYPE  <= is_mc6 ? w_wdata[63:60] : 4'hF;
      reg_DMODE <= dmode;
      reg_DATA  <=
        is_mc6
          ? {34'h0,
             w_wdata[24:23],                              // sizehi/sizelo hi bits
             7'h0,
             (w_wdata[15:12] == 4'h0 |                    // action WARL
              (w_wdata[15:12] == 4'h1 & dmode))
                ? w_wdata[15:12] : 4'h0,
             w_wdata[11] & chainable,                     // chain (only if allowed)
             ({w_wdata[10:7] == 4'h3,                     // match WARL: {equal,>=,<}
               w_wdata[10:7] == 4'h2,
               w_wdata[10:7] == 4'h0} == 3'h0)
                ? 4'h0 : w_wdata[10:7],
             w_wdata[6],                                  // m (machine-mode enable)
             1'h0,
             w_wdata[4:0]}                                // u/s/exec/store/load
          : 59'h0;
    end
    else if (w_wen & is_mc6)
      reg_TYPE <= w_wdata[63:60];  // verbatim redundant golden arm (never taken)
  end

  assign rdata = {reg_TYPE, reg_DMODE, reg_DATA};

endmodule

// ---------------------------------------------------------------------------
// Trigger{0..3}_Tdata2Module: plain 64-bit match register, NO reset.
// ---------------------------------------------------------------------------
module xs_trigger_tdata2 (
    input         clock,
    input         w_wen,
    input  [63:0] w_wdata,
    output [63:0] rdata
);

  reg [63:0] reg_ALL;

  always @(posedge clock) begin
    if (w_wen)
      reg_ALL <= w_wdata;
  end

  assign rdata = reg_ALL;

endmodule
