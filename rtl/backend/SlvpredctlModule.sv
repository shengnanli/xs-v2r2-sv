// SlvpredctlModule.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_SlvpredctlModule_core(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic [4:0]  regOut_LVPRED_TIMEOUT,
  output logic regOut_STORESET_NO_FAST_WAKEUP,
  output logic regOut_STORESET_WAIT_STORE,
  output logic regOut_NO_SPEC_LOAD,
  output logic regOut_LVPRED_DISABLE
);
logic [4:0] reg_LVPRED_TIMEOUT;
  logic       reg_STORESET_NO_FAST_WAKEUP;
  logic       reg_STORESET_WAIT_STORE;
  logic       reg_NO_SPEC_LOAD;
  logic       reg_LVPRED_DISABLE;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_LVPRED_TIMEOUT <= 5'h3;
      reg_STORESET_NO_FAST_WAKEUP <= 1'h0;
      reg_STORESET_WAIT_STORE <= 1'h0;
      reg_NO_SPEC_LOAD <= 1'h0;
      reg_LVPRED_DISABLE <= 1'h0;
    end
    else if (w_wen) begin
      reg_LVPRED_TIMEOUT <= w_wdata[8:4];
      reg_STORESET_NO_FAST_WAKEUP <= w_wdata[3];
      reg_STORESET_WAIT_STORE <= w_wdata[2];
      reg_NO_SPEC_LOAD <= w_wdata[1];
      reg_LVPRED_DISABLE <= w_wdata[0];
    end
  end // always @(posedge, posedge)
always_comb begin
    rdata = {55'h0,
     reg_LVPRED_TIMEOUT,
     reg_STORESET_NO_FAST_WAKEUP,
     reg_STORESET_WAIT_STORE,
     reg_NO_SPEC_LOAD,
     reg_LVPRED_DISABLE};
  end
  always_comb begin
    regOut_LVPRED_TIMEOUT = reg_LVPRED_TIMEOUT;
  end
  always_comb begin
    regOut_STORESET_NO_FAST_WAKEUP = reg_STORESET_NO_FAST_WAKEUP;
  end
  always_comb begin
    regOut_STORESET_WAIT_STORE = reg_STORESET_WAIT_STORE;
  end
  always_comb begin
    regOut_NO_SPEC_LOAD = reg_NO_SPEC_LOAD;
  end
  always_comb begin
    regOut_LVPRED_DISABLE = reg_LVPRED_DISABLE;
  end
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
  xs_SlvpredctlModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_LVPRED_TIMEOUT(regOut_LVPRED_TIMEOUT),
    .regOut_STORESET_NO_FAST_WAKEUP(regOut_STORESET_NO_FAST_WAKEUP),
    .regOut_STORESET_WAIT_STORE(regOut_STORESET_WAIT_STORE),
    .regOut_NO_SPEC_LOAD(regOut_NO_SPEC_LOAD),
    .regOut_LVPRED_DISABLE(regOut_LVPRED_DISABLE)
  );
endmodule
