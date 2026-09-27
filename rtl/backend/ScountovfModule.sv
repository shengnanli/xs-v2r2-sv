// Expose counter-overflow bits allowed by the current privilege and virtualization mode.
// The small semantic core makes the architectural transform explicit;
// the outer module preserves the generated RTL interface exactly.
module ScountovfModule(
  output logic [31:0] rdata,
  input  logic [28:0] ofVec,
  input  logic [1:0]  privState_PRVM,
  input  logic        privState_V,
  input  logic [28:0] mcounteren_HPM,
  input  logic [28:0] hcounteren_HPM
);
  logic machine_mode;
  logic host_supervisor_mode;
  logic virtual_supervisor_mode;
  logic [28:0] visible_overflows;

  assign machine_mode = &privState_PRVM;
  assign host_supervisor_mode =
    (privState_PRVM == 2'b01) && !privState_V;
  assign virtual_supervisor_mode =
    (privState_PRVM == 2'b01) && privState_V;

  always_comb begin
    visible_overflows = 29'b0;
    if (machine_mode)
      visible_overflows = ofVec;
    else if (host_supervisor_mode)
      visible_overflows = mcounteren_HPM & ofVec;
    else if (virtual_supervisor_mode)
      visible_overflows = mcounteren_HPM & hcounteren_HPM & ofVec;
  end

  assign rdata = {visible_overflows, 3'b0};
endmodule
