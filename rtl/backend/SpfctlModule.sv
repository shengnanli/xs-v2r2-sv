// SpfctlModule.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_SpfctlModule_core(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic [9:0]  regOut_L2_PF_DELAY_LATENCY,
  output logic regOut_L2_PF_TP_ENABLE,
  output logic regOut_L2_PF_VBOP_ENABLE,
  output logic regOut_L2_PF_PBOP_ENABLE,
  output logic regOut_L2_PF_RECV_ENABLE,
  output logic regOut_L2_PF_STORE_ONLY,
  output logic regOut_L1D_PF_ENABLE_STRIDE,
  output logic [5:0]  regOut_L1D_PF_ACTIVE_STRIDE,
  output logic [3:0]  regOut_L1D_PF_ACTIVE_THRESHOLD,
  output logic regOut_L1D_PF_ENABLE_PHT,
  output logic regOut_L1D_PF_ENABLE_AGT,
  output logic regOut_L1D_PF_TRAIN_ON_HIT,
  output logic regOut_L1D_PF_ENABLE,
  output logic regOut_L2_PF_ENABLE,
  output logic regOut_L1I_PF_ENABLE
);
logic [9:0] l2_pf_delay_latency_q;
  logic       l2_pf_tp_enable_q;
  logic       l2_pf_vbop_enable_q;
  logic       l2_pf_pbop_enable_q;
  logic       l2_pf_recv_enable_q;
  logic       l2_pf_store_only_q;
  logic       l1d_pf_enable_stride_q;
  logic [5:0] l1d_pf_active_stride_q;
  logic [3:0] l1d_pf_active_threshold_q;
  logic       l1d_pf_enable_pht_q;
  logic       l1d_pf_enable_agt_q;
  logic       l1d_pf_train_on_hit_q;
  logic       l1d_pf_enable_q;
  logic       l2_pf_enable_q;
  logic       l1i_pf_enable_q;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      l2_pf_delay_latency_q <= 10'h0;
      l2_pf_tp_enable_q <= 1'h1;
      l2_pf_vbop_enable_q <= 1'h1;
      l2_pf_pbop_enable_q <= 1'h1;
      l2_pf_recv_enable_q <= 1'h1;
      l2_pf_store_only_q <= 1'h0;
      l1d_pf_enable_stride_q <= 1'h1;
      l1d_pf_active_stride_q <= 6'h1E;
      l1d_pf_active_threshold_q <= 4'hC;
      l1d_pf_enable_pht_q <= 1'h1;
      l1d_pf_enable_agt_q <= 1'h1;
      l1d_pf_train_on_hit_q <= 1'h0;
      l1d_pf_enable_q <= 1'h1;
      l2_pf_enable_q <= 1'h1;
      l1i_pf_enable_q <= 1'h1;
    end
    else if (w_wen) begin
      l2_pf_delay_latency_q <= w_wdata[31:22];
      l2_pf_tp_enable_q <= w_wdata[21];
      l2_pf_vbop_enable_q <= w_wdata[20];
      l2_pf_pbop_enable_q <= w_wdata[19];
      l2_pf_recv_enable_q <= w_wdata[18];
      l2_pf_store_only_q <= w_wdata[17];
      l1d_pf_enable_stride_q <= w_wdata[16];
      l1d_pf_active_stride_q <= w_wdata[15:10];
      l1d_pf_active_threshold_q <= w_wdata[9:6];
      l1d_pf_enable_pht_q <= w_wdata[5];
      l1d_pf_enable_agt_q <= w_wdata[4];
      l1d_pf_train_on_hit_q <= w_wdata[3];
      l1d_pf_enable_q <= w_wdata[2];
      l2_pf_enable_q <= w_wdata[1];
      l1i_pf_enable_q <= w_wdata[0];
    end
  end // always @(posedge, posedge)
always_comb begin
    rdata = {32'h0,
     l2_pf_delay_latency_q,
     l2_pf_tp_enable_q,
     l2_pf_vbop_enable_q,
     l2_pf_pbop_enable_q,
     l2_pf_recv_enable_q,
     l2_pf_store_only_q,
     l1d_pf_enable_stride_q,
     l1d_pf_active_stride_q,
     l1d_pf_active_threshold_q,
     l1d_pf_enable_pht_q,
     l1d_pf_enable_agt_q,
     l1d_pf_train_on_hit_q,
     l1d_pf_enable_q,
     l2_pf_enable_q,
     l1i_pf_enable_q};
  end
  always_comb begin
    regOut_L2_PF_DELAY_LATENCY = l2_pf_delay_latency_q;
  end
  always_comb begin
    regOut_L2_PF_TP_ENABLE = l2_pf_tp_enable_q;
  end
  always_comb begin
    regOut_L2_PF_VBOP_ENABLE = l2_pf_vbop_enable_q;
  end
  always_comb begin
    regOut_L2_PF_PBOP_ENABLE = l2_pf_pbop_enable_q;
  end
  always_comb begin
    regOut_L2_PF_RECV_ENABLE = l2_pf_recv_enable_q;
  end
  always_comb begin
    regOut_L2_PF_STORE_ONLY = l2_pf_store_only_q;
  end
  always_comb begin
    regOut_L1D_PF_ENABLE_STRIDE = l1d_pf_enable_stride_q;
  end
  always_comb begin
    regOut_L1D_PF_ACTIVE_STRIDE = l1d_pf_active_stride_q;
  end
  always_comb begin
    regOut_L1D_PF_ACTIVE_THRESHOLD = l1d_pf_active_threshold_q;
  end
  always_comb begin
    regOut_L1D_PF_ENABLE_PHT = l1d_pf_enable_pht_q;
  end
  always_comb begin
    regOut_L1D_PF_ENABLE_AGT = l1d_pf_enable_agt_q;
  end
  always_comb begin
    regOut_L1D_PF_TRAIN_ON_HIT = l1d_pf_train_on_hit_q;
  end
  always_comb begin
    regOut_L1D_PF_ENABLE = l1d_pf_enable_q;
  end
  always_comb begin
    regOut_L2_PF_ENABLE = l2_pf_enable_q;
  end
  always_comb begin
    regOut_L1I_PF_ENABLE = l1i_pf_enable_q;
  end
endmodule

module SpfctlModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [9:0]  regOut_L2_PF_DELAY_LATENCY,
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
  xs_SpfctlModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_L2_PF_DELAY_LATENCY(regOut_L2_PF_DELAY_LATENCY),
    .regOut_L2_PF_TP_ENABLE(regOut_L2_PF_TP_ENABLE),
    .regOut_L2_PF_VBOP_ENABLE(regOut_L2_PF_VBOP_ENABLE),
    .regOut_L2_PF_PBOP_ENABLE(regOut_L2_PF_PBOP_ENABLE),
    .regOut_L2_PF_RECV_ENABLE(regOut_L2_PF_RECV_ENABLE),
    .regOut_L2_PF_STORE_ONLY(regOut_L2_PF_STORE_ONLY),
    .regOut_L1D_PF_ENABLE_STRIDE(regOut_L1D_PF_ENABLE_STRIDE),
    .regOut_L1D_PF_ACTIVE_STRIDE(regOut_L1D_PF_ACTIVE_STRIDE),
    .regOut_L1D_PF_ACTIVE_THRESHOLD(regOut_L1D_PF_ACTIVE_THRESHOLD),
    .regOut_L1D_PF_ENABLE_PHT(regOut_L1D_PF_ENABLE_PHT),
    .regOut_L1D_PF_ENABLE_AGT(regOut_L1D_PF_ENABLE_AGT),
    .regOut_L1D_PF_TRAIN_ON_HIT(regOut_L1D_PF_TRAIN_ON_HIT),
    .regOut_L1D_PF_ENABLE(regOut_L1D_PF_ENABLE),
    .regOut_L2_PF_ENABLE(regOut_L2_PF_ENABLE),
    .regOut_L1I_PF_ENABLE(regOut_L1I_PF_ENABLE)
  );
endmodule
