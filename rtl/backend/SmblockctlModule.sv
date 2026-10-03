// SmblockctlModule.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_SmblockctlModule_core(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic [21:0] regOut_SBUFFER_TIMEOUT,
  output logic regOut_HD_MISALIGN_LD_ENABLE,
  output logic regOut_HD_MISALIGN_ST_ENABLE,
  output logic regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE,
  output logic regOut_CACHE_ERROR_ENABLE,
  output logic regOut_SOFT_PREFETCH_ENABLE,
  output logic regOut_LDLD_VIO_CHECK_ENABLE,
  output logic [3:0]  regOut_SBUFFER_THRESHOLD
);
logic [21:0] reg_SBUFFER_TIMEOUT;
  logic        reg_HD_MISALIGN_LD_ENABLE;
  logic        reg_HD_MISALIGN_ST_ENABLE;
  logic        reg_UNCACHE_WRITE_OUTSTANDING_ENABLE;
  logic        reg_CACHE_ERROR_ENABLE;
  logic        reg_SOFT_PREFETCH_ENABLE;
  logic        reg_LDLD_VIO_CHECK_ENABLE;
  logic [3:0]  reg_SBUFFER_THRESHOLD;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_SBUFFER_TIMEOUT <= 22'h100000;
      reg_HD_MISALIGN_LD_ENABLE <= 1'h1;
      reg_HD_MISALIGN_ST_ENABLE <= 1'h1;
      reg_UNCACHE_WRITE_OUTSTANDING_ENABLE <= 1'h0;
      reg_CACHE_ERROR_ENABLE <= 1'h1;
      reg_SOFT_PREFETCH_ENABLE <= 1'h1;
      reg_LDLD_VIO_CHECK_ENABLE <= 1'h1;
      reg_SBUFFER_THRESHOLD <= 4'h7;
    end
    else if (w_wen) begin
      reg_SBUFFER_TIMEOUT <= w_wdata[31:10];
      reg_HD_MISALIGN_LD_ENABLE <= w_wdata[9];
      reg_HD_MISALIGN_ST_ENABLE <= w_wdata[8];
      reg_UNCACHE_WRITE_OUTSTANDING_ENABLE <= w_wdata[7];
      reg_CACHE_ERROR_ENABLE <= w_wdata[6];
      reg_SOFT_PREFETCH_ENABLE <= w_wdata[5];
      reg_LDLD_VIO_CHECK_ENABLE <= w_wdata[4];
      reg_SBUFFER_THRESHOLD <= w_wdata[3:0];
    end
  end // always @(posedge, posedge)
always_comb begin
    rdata = {32'h0,
     reg_SBUFFER_TIMEOUT,
     reg_HD_MISALIGN_LD_ENABLE,
     reg_HD_MISALIGN_ST_ENABLE,
     reg_UNCACHE_WRITE_OUTSTANDING_ENABLE,
     reg_CACHE_ERROR_ENABLE,
     reg_SOFT_PREFETCH_ENABLE,
     reg_LDLD_VIO_CHECK_ENABLE,
     reg_SBUFFER_THRESHOLD};
  end
  always_comb begin
    regOut_SBUFFER_TIMEOUT = reg_SBUFFER_TIMEOUT;
  end
  always_comb begin
    regOut_HD_MISALIGN_LD_ENABLE = reg_HD_MISALIGN_LD_ENABLE;
  end
  always_comb begin
    regOut_HD_MISALIGN_ST_ENABLE = reg_HD_MISALIGN_ST_ENABLE;
  end
  always_comb begin
    regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE = reg_UNCACHE_WRITE_OUTSTANDING_ENABLE;
  end
  always_comb begin
    regOut_CACHE_ERROR_ENABLE = reg_CACHE_ERROR_ENABLE;
  end
  always_comb begin
    regOut_SOFT_PREFETCH_ENABLE = reg_SOFT_PREFETCH_ENABLE;
  end
  always_comb begin
    regOut_LDLD_VIO_CHECK_ENABLE = reg_LDLD_VIO_CHECK_ENABLE;
  end
  always_comb begin
    regOut_SBUFFER_THRESHOLD = reg_SBUFFER_THRESHOLD;
  end
endmodule

module SmblockctlModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [21:0] regOut_SBUFFER_TIMEOUT,
  output        regOut_HD_MISALIGN_LD_ENABLE,
  output        regOut_HD_MISALIGN_ST_ENABLE,
  output        regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE,
  output        regOut_CACHE_ERROR_ENABLE,
  output        regOut_SOFT_PREFETCH_ENABLE,
  output        regOut_LDLD_VIO_CHECK_ENABLE,
  output [3:0]  regOut_SBUFFER_THRESHOLD
);
  xs_SmblockctlModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_SBUFFER_TIMEOUT(regOut_SBUFFER_TIMEOUT),
    .regOut_HD_MISALIGN_LD_ENABLE(regOut_HD_MISALIGN_LD_ENABLE),
    .regOut_HD_MISALIGN_ST_ENABLE(regOut_HD_MISALIGN_ST_ENABLE),
    .regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE(regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE),
    .regOut_CACHE_ERROR_ENABLE(regOut_CACHE_ERROR_ENABLE),
    .regOut_SOFT_PREFETCH_ENABLE(regOut_SOFT_PREFETCH_ENABLE),
    .regOut_LDLD_VIO_CHECK_ENABLE(regOut_LDLD_VIO_CHECK_ENABLE),
    .regOut_SBUFFER_THRESHOLD(regOut_SBUFFER_THRESHOLD)
  );
endmodule
