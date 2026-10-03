// Pack the machine top-external-interrupt identity and priority CSR fields.
// The small semantic core makes the architectural transform explicit;
// the outer module preserves the generated RTL interface exactly.
module xs_MtopeiModule_core (
  input  logic [10:0] interrupt_id,
  input  logic [10:0] interrupt_priority,
  output logic [63:0] read_value
);
  assign read_value = {37'b0, interrupt_id, 5'b0, interrupt_priority};
endmodule

module MtopeiModule (
  output logic [63:0] rdata,
  output logic [10:0] regOut_IID,
  output logic [10:0] regOut_IPRIO,
  input  logic [10:0] aiaToCSR_mtopei_IID,
  input  logic [10:0] aiaToCSR_mtopei_IPRIO
);
  xs_MtopeiModule_core u_core (
    .interrupt_id(aiaToCSR_mtopei_IID),
    .interrupt_priority(aiaToCSR_mtopei_IPRIO),
    .read_value(rdata)
  );
  assign regOut_IID = aiaToCSR_mtopei_IID;
  assign regOut_IPRIO = aiaToCSR_mtopei_IPRIO;
endmodule
