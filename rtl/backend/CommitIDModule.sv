// Commit provenance presented to the simulation-only printer.  Keeping
// these values explicit makes the otherwise output-less module independently
// testable without changing its integration port contract.
module xs_CommitIDModule_core (
  input  logic [5:0]  hart_id,
  output logic [5:0]  printer_hart_id,
  output logic [39:0] commit_id,
  output logic        dirty
);
  assign printer_hart_id = hart_id;
  assign commit_id = 40'hB36A1A2A57;
  assign dirty = 1'b1;
endmodule

module CommitIDModule (
  input logic [5:0] io_hartId
);
  logic [5:0]  printer_hart_id;
  logic [39:0] commit_id;
  logic        dirty;

  xs_CommitIDModule_core u_commit_id (
    .hart_id(io_hartId),
    .printer_hart_id(printer_hart_id),
    .commit_id(commit_id),
    .dirty(dirty)
  );

  PrintCommitIDModule printCommitIDMod (
    .hartID(printer_hart_id),
    .commitID(commit_id),
    .dirty(dirty)
  );
endmodule
