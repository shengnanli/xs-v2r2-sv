// NewCSR bespoke module: HedelegModule (hypervisor exception delegation CSR).
//
// Faithful, readable reimplementation of the golden HedelegModule. hedeleg is a
// bit-mask WARL register that delegates a *subset* of the machine-delegatable
// exceptions down to VS-mode. It is medeleg's little sibling: same architected
// bit positions (= RISC-V exception codes, so the word has holes), but only the
// guest-relevant exceptions own a writable bit. Exceptions that only ever target
// HS/M (HSCALL=9, VSCALL=10, IGPF/LGPF/VI/SGPF=20..23) have no register bit and
// read as constant 0. Transcribed bit-for-bit from golden.
//
// Writable/registered fields (bit position in the CSR word):
//   IAM=0  IAF=1  II=2  BP=3  LAM=4  LAF=5  SAM=6  SAF=7  UCALL=8
//   IPF=12 LPF=13 SPF=15 SWC=18 HWE=19.  All async-reset to 0.

module xs_hedeleg (
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

  reg reg_EX_IAM, reg_EX_IAF, reg_EX_II, reg_EX_BP, reg_EX_LAM, reg_EX_LAF;
  reg reg_EX_SAM, reg_EX_SAF, reg_EX_UCALL, reg_EX_IPF, reg_EX_LPF;
  reg reg_EX_SPF, reg_EX_SWC, reg_EX_HWE;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_EX_IAM   <= 1'h0;
      reg_EX_IAF   <= 1'h0;
      reg_EX_II    <= 1'h0;
      reg_EX_BP    <= 1'h0;
      reg_EX_LAM   <= 1'h0;
      reg_EX_LAF   <= 1'h0;
      reg_EX_SAM   <= 1'h0;
      reg_EX_SAF   <= 1'h0;
      reg_EX_UCALL <= 1'h0;
      reg_EX_IPF   <= 1'h0;
      reg_EX_LPF   <= 1'h0;
      reg_EX_SPF   <= 1'h0;
      reg_EX_SWC   <= 1'h0;
      reg_EX_HWE   <= 1'h0;
    end
    else if (w_wen) begin
      reg_EX_IAM   <= w_wdata[0];
      reg_EX_IAF   <= w_wdata[1];
      reg_EX_II    <= w_wdata[2];
      reg_EX_BP    <= w_wdata[3];
      reg_EX_LAM   <= w_wdata[4];
      reg_EX_LAF   <= w_wdata[5];
      reg_EX_SAM   <= w_wdata[6];
      reg_EX_SAF   <= w_wdata[7];
      reg_EX_UCALL <= w_wdata[8];
      reg_EX_IPF   <= w_wdata[12];
      reg_EX_LPF   <= w_wdata[13];
      reg_EX_SPF   <= w_wdata[15];
      reg_EX_SWC   <= w_wdata[18];
      reg_EX_HWE   <= w_wdata[19];
    end
  end

  assign rdata =
    {44'h0,
     reg_EX_HWE,
     reg_EX_SWC,
     2'h0,
     reg_EX_SPF,
     1'h0,
     reg_EX_LPF,
     reg_EX_IPF,
     3'h0,
     reg_EX_UCALL,
     reg_EX_SAF,
     reg_EX_SAM,
     reg_EX_LAF,
     reg_EX_LAM,
     reg_EX_BP,
     reg_EX_II,
     reg_EX_IAF,
     reg_EX_IAM};

  assign regOut_EX_IAM   = reg_EX_IAM;
  assign regOut_EX_IAF   = reg_EX_IAF;
  assign regOut_EX_II    = reg_EX_II;
  assign regOut_EX_BP    = reg_EX_BP;
  assign regOut_EX_LAM   = reg_EX_LAM;
  assign regOut_EX_LAF   = reg_EX_LAF;
  assign regOut_EX_SAM   = reg_EX_SAM;
  assign regOut_EX_SAF   = reg_EX_SAF;
  assign regOut_EX_UCALL = reg_EX_UCALL;
  assign regOut_EX_IPF   = reg_EX_IPF;
  assign regOut_EX_LPF   = reg_EX_LPF;
  assign regOut_EX_SPF   = reg_EX_SPF;
  assign regOut_EX_SWC   = reg_EX_SWC;
  assign regOut_EX_HWE   = reg_EX_HWE;

endmodule
