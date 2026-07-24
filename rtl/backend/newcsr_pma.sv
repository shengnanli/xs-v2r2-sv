// NewCSR CSR-field primitives: PMA (Physical Memory Attribute) CSRs.
//
// Faithful, readable, parameterized reimplementation of the golden PMA CSR
// family (34 golden modules):
//
//   xs_pmacfg_slice   Pmacfg{0,2}Module : pure-comb 64-bit read slicer over the
//                       upstream-legalized 128-bit packed PMA config bus.
//                         Pmacfg0 : rdata = cfgRData[63:0]     (HI=0)
//                         Pmacfg2 : rdata = cfgRData[127:64]   (HI=1)
//                       (Mirrors the Pmpcfg slicer; WARL legalization is upstream.)
//
//   xs_pmaaddr        Pmaaddr{0..15}Module : pure-comb pass-through of the
//                       per-entry legalized PMA address read bus.
//                         rdata = addrRData_N
//
//   xs_pmacfg_entry   Pma{0..15}cfgModule : one PMA config entry register with
//                       the R/W/X/A[1:0]/ATOMIC/C/L fields. Async reset to the
//                       per-entry architectural default RESET_VAL[7:0], write on
//                       w_wen from w_wdata[7:0], read/regOut expose the raw regs.
//                       Field/bit layout (rdata & reset & w_wdata):
//                         [7]=L [6]=C [5]=ATOMIC [4:3]=A [2]=X [1]=W [0]=R
//                       The ONLY per-index difference is RESET_VAL (default PMA
//                       attributes for that entry), so it is a parameter.

// ---------------------------------------------------------------------------
// Pmacfg{0,2}Module: 64-bit read slice of the packed 128-bit PMA config bus.
// ---------------------------------------------------------------------------
module xs_pmacfg_slice #(
    parameter bit HI = 1'b0  // 0 -> cfgRData[63:0]; 1 -> cfgRData[127:64]
) (
    output [63:0]  rdata,
    input  [127:0] cfgRData
);
  assign rdata = HI ? cfgRData[127:64] : cfgRData[63:0];
endmodule

// ---------------------------------------------------------------------------
// Pmaaddr{0..15}Module: pure pass-through read of the per-entry address bus.
// ---------------------------------------------------------------------------
module xs_pmaaddr (
    output [63:0] rdata,
    input  [63:0] addr_rdata
);
  assign rdata = addr_rdata;
endmodule

// ---------------------------------------------------------------------------
// Pma{0..15}cfgModule: one PMA config-entry register (R/W/X/A/ATOMIC/C/L).
//   reset value = per-entry architectural default (RESET_VAL parameter).
// ---------------------------------------------------------------------------
module xs_pmacfg_entry #(
    parameter [7:0] RESET_VAL = 8'h00  // {L,C,ATOMIC,A[1:0],X,W,R}
) (
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

  reg       reg_R;
  reg       reg_W;
  reg       reg_X;
  reg [1:0] reg_A;
  reg       reg_ATOMIC;
  reg       reg_C;
  reg       reg_L;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_R      <= RESET_VAL[0];
      reg_W      <= RESET_VAL[1];
      reg_X      <= RESET_VAL[2];
      reg_A      <= RESET_VAL[4:3];
      reg_ATOMIC <= RESET_VAL[5];
      reg_C      <= RESET_VAL[6];
      reg_L      <= RESET_VAL[7];
    end
    else if (w_wen) begin
      reg_R      <= w_wdata[0];
      reg_W      <= w_wdata[1];
      reg_X      <= w_wdata[2];
      reg_A      <= w_wdata[4:3];
      reg_ATOMIC <= w_wdata[5];
      reg_C      <= w_wdata[6];
      reg_L      <= w_wdata[7];
    end
  end

  assign rdata         = {reg_L, reg_C, reg_ATOMIC, reg_A, reg_X, reg_W, reg_R};
  assign regOut_R      = reg_R;
  assign regOut_W      = reg_W;
  assign regOut_X      = reg_X;
  assign regOut_A      = reg_A;
  assign regOut_ATOMIC = reg_ATOMIC;
  assign regOut_C      = reg_C;
  assign regOut_L      = reg_L;

endmodule
