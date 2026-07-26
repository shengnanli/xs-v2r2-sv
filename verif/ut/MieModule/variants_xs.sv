// (placeholder) The ie/ip batch is signed off via strict Formality (make fm-*),
// which does not compile this file. A full UT double-instantiation would require
// wiring 40+ alias/delegation ports per module; FM proves bit-exact equivalence
// against golden directly, so it is the authoritative signoff here. This stub
// exists only so the Makefile parses; `make compile`/`run` are not used for this
// target. See verif/signoff/aux_targets.tsv for the recorded FM verdicts.
module __mie_ip_batch_ut_placeholder; endmodule
