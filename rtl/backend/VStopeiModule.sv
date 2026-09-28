// Pack the virtual-supervisor top-external-interrupt identity and priority fields.
// The small semantic core makes the architectural transform explicit;
// the outer module preserves the generated RTL interface exactly.
module xs_VStopeiModule_core(
  input  logic [10:0] interrupt_id,
  input  logic [10:0] interrupt_priority,
  output logic [63:0] read_value
);
  assign read_value = {37'b0, interrupt_id, 5'b0, interrupt_priority};
endmodule

module VStopeiModule(
  output logic [63:0] rdata,
  output logic [10:0] regOut_IID,
  output logic [10:0] regOut_IPRIO,
  input  logic [10:0] aiaToCSR_vstopei_IID,
  input  logic [10:0] aiaToCSR_vstopei_IPRIO
);
  xs_VStopeiModule_core u_core (
    .interrupt_id(aiaToCSR_vstopei_IID),
    .interrupt_priority(aiaToCSR_vstopei_IPRIO),
    .read_value(rdata)
  );
  assign regOut_IID = aiaToCSR_vstopei_IID;
  assign regOut_IPRIO = aiaToCSR_vstopei_IPRIO;
endmodule
