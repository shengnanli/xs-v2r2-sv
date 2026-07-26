// NewCSR bespoke module: MedelegModule (machine exception delegation CSR).
//
// Faithful, readable reimplementation of the golden MedelegModule. medeleg is a
// bit-mask WARL register: each delegatable exception owns one architected bit,
// but the bit positions are the RISC-V exception codes so the word has holes
// (bits 11,14,16,17,+ high bits read as constant 0). Non-delegatable exceptions
// have no register bit. Transcribed bit-for-bit from golden; the write map and
// rdata packing must match exactly.
//
// Fields (bit position in the CSR word):
//   IAM=0  IAF=1  II=2  BP=3  LAM=4  LAF=5  SAM=6  SAF=7  UCALL=8  HSCALL=9
//   VSCALL=10  IPF=12  LPF=13  SPF=15  SWC=18  HWE=19  IGPF=20  LGPF=21
//   VI=22  SGPF=23.  All async-reset to 0.

module xs_medeleg (
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

  reg reg_EX_IAM, reg_EX_IAF, reg_EX_II, reg_EX_BP, reg_EX_LAM, reg_EX_LAF;
  reg reg_EX_SAM, reg_EX_SAF, reg_EX_UCALL, reg_EX_HSCALL, reg_EX_VSCALL;
  reg reg_EX_IPF, reg_EX_LPF, reg_EX_SPF, reg_EX_SWC, reg_EX_HWE;
  reg reg_EX_IGPF, reg_EX_LGPF, reg_EX_VI, reg_EX_SGPF;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_EX_IAM    <= 1'h0;
      reg_EX_IAF    <= 1'h0;
      reg_EX_II     <= 1'h0;
      reg_EX_BP     <= 1'h0;
      reg_EX_LAM    <= 1'h0;
      reg_EX_LAF    <= 1'h0;
      reg_EX_SAM    <= 1'h0;
      reg_EX_SAF    <= 1'h0;
      reg_EX_UCALL  <= 1'h0;
      reg_EX_HSCALL <= 1'h0;
      reg_EX_VSCALL <= 1'h0;
      reg_EX_IPF    <= 1'h0;
      reg_EX_LPF    <= 1'h0;
      reg_EX_SPF    <= 1'h0;
      reg_EX_SWC    <= 1'h0;
      reg_EX_HWE    <= 1'h0;
      reg_EX_IGPF   <= 1'h0;
      reg_EX_LGPF   <= 1'h0;
      reg_EX_VI     <= 1'h0;
      reg_EX_SGPF   <= 1'h0;
    end
    else if (w_wen) begin
      reg_EX_IAM    <= w_wdata[0];
      reg_EX_IAF    <= w_wdata[1];
      reg_EX_II     <= w_wdata[2];
      reg_EX_BP     <= w_wdata[3];
      reg_EX_LAM    <= w_wdata[4];
      reg_EX_LAF    <= w_wdata[5];
      reg_EX_SAM    <= w_wdata[6];
      reg_EX_SAF    <= w_wdata[7];
      reg_EX_UCALL  <= w_wdata[8];
      reg_EX_HSCALL <= w_wdata[9];
      reg_EX_VSCALL <= w_wdata[10];
      reg_EX_IPF    <= w_wdata[12];
      reg_EX_LPF    <= w_wdata[13];
      reg_EX_SPF    <= w_wdata[15];
      reg_EX_SWC    <= w_wdata[18];
      reg_EX_HWE    <= w_wdata[19];
      reg_EX_IGPF   <= w_wdata[20];
      reg_EX_LGPF   <= w_wdata[21];
      reg_EX_VI     <= w_wdata[22];
      reg_EX_SGPF   <= w_wdata[23];
    end
  end

  assign rdata =
    {40'h0,
     reg_EX_SGPF,
     reg_EX_VI,
     reg_EX_LGPF,
     reg_EX_IGPF,
     reg_EX_HWE,
     reg_EX_SWC,
     2'h0,
     reg_EX_SPF,
     1'h0,
     reg_EX_LPF,
     reg_EX_IPF,
     1'h0,
     reg_EX_VSCALL,
     reg_EX_HSCALL,
     reg_EX_UCALL,
     reg_EX_SAF,
     reg_EX_SAM,
     reg_EX_LAF,
     reg_EX_LAM,
     reg_EX_BP,
     reg_EX_II,
     reg_EX_IAF,
     reg_EX_IAM};

  assign regOut_EX_IAM    = reg_EX_IAM;
  assign regOut_EX_IAF    = reg_EX_IAF;
  assign regOut_EX_II     = reg_EX_II;
  assign regOut_EX_BP     = reg_EX_BP;
  assign regOut_EX_LAM    = reg_EX_LAM;
  assign regOut_EX_LAF    = reg_EX_LAF;
  assign regOut_EX_SAM    = reg_EX_SAM;
  assign regOut_EX_SAF    = reg_EX_SAF;
  assign regOut_EX_UCALL  = reg_EX_UCALL;
  assign regOut_EX_HSCALL = reg_EX_HSCALL;
  assign regOut_EX_VSCALL = reg_EX_VSCALL;
  assign regOut_EX_IPF    = reg_EX_IPF;
  assign regOut_EX_LPF    = reg_EX_LPF;
  assign regOut_EX_SPF    = reg_EX_SPF;
  assign regOut_EX_SWC    = reg_EX_SWC;
  assign regOut_EX_HWE    = reg_EX_HWE;
  assign regOut_EX_IGPF   = reg_EX_IGPF;
  assign regOut_EX_LGPF   = reg_EX_LGPF;
  assign regOut_EX_VI     = reg_EX_VI;
  assign regOut_EX_SGPF   = reg_EX_SGPF;

endmodule
