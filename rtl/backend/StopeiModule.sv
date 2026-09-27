// Pack the supervisor top-external-interrupt identity and priority CSR fields.
// The small semantic core makes the architectural transform explicit;
// the outer module preserves the generated RTL interface exactly.
module xs_StopeiModule_core(
  input  logic [10:0] interrupt_id,
  input  logic [10:0] interrupt_priority,
  output logic [63:0] read_value
);
  assign read_value = {37'b0, interrupt_id, 5'b0, interrupt_priority};
endmodule

module StopeiModule(
  output logic [63:0] rdata,
  output logic [10:0] regOut_IID,
  output logic [10:0] regOut_IPRIO,
  input  logic [10:0] aiaToCSR_stopei_IID,
  input  logic [10:0] aiaToCSR_stopei_IPRIO
);
  xs_StopeiModule_core u_core (
    .interrupt_id(aiaToCSR_stopei_IID),
    .interrupt_priority(aiaToCSR_stopei_IPRIO),
    .read_value(rdata)
  );
  assign regOut_IID = aiaToCSR_stopei_IID;
  assign regOut_IPRIO = aiaToCSR_stopei_IPRIO;
endmodule
