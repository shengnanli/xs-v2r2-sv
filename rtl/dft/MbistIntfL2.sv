// MbistIntfL2.sv — root of the L2 MBIST distribution tree (utility.mbist.MbistInterface, name "MbistIntfL2").
// Scala: utility/src/main/scala/utility/mbist/MbistPipeline.scala (class MbistInterface),
// placed by coupledL2/CoupledL2.scala:634 as `l2MbistIntf`.
// An MbistInterface connects the chip-level MBIST controller bus (`mbist_*`,
// MbitsStandardInterface) to one or more MbistPipeline subtrees
// (`toPipeline_<k>_*`).  With several subtrees it fans the request out to all
// of them and selects the read data / ack of the one whose array-id set
// contains mbist_array (Mux1H).  The L2 has exactly one subtree (the L2Cache
// pipeline node, see rtl/dft/L2Cache.sv), so the select is `true.B` and the
// whole module degenerates into wires:
//   down:  array/all/req/writeen/be/addr/indata/readen/addr_rd  -> toPipeline_0
//   up:    toPipeline_0 ack/outdata                             -> mbist_ack/outdata
// No registers, no reset.  (In the Chisel source `mbist := DontCare` until an
// MBIST controller is attached; that only affects the parent, not this module.)
module MbistIntfL2 (
  output [5:0]   toPipeline_0_array,
  output         toPipeline_0_all,
  output         toPipeline_0_req,
  input          toPipeline_0_ack,
  output         toPipeline_0_writeen,
  output [7:0]   toPipeline_0_be,
  output [12:0]  toPipeline_0_addr,
  output [136:0] toPipeline_0_indata,
  output         toPipeline_0_readen,
  output [12:0]  toPipeline_0_addr_rd,
  input  [136:0] toPipeline_0_outdata,
  input  [5:0]   mbist_array,
  input          mbist_all,
  input          mbist_req,
  output         mbist_ack,
  input          mbist_writeen,
  input  [7:0]   mbist_be,
  input  [12:0]  mbist_addr,
  input  [136:0] mbist_indata,
  input          mbist_readen,
  input  [12:0]  mbist_addr_rd,
  output [136:0] mbist_outdata
);
  // ---- request: broadcast to the single subtree --------------------------
  assign toPipeline_0_array   = mbist_array;
  assign toPipeline_0_all     = mbist_all;
  assign toPipeline_0_req     = mbist_req;
  assign toPipeline_0_writeen = mbist_writeen;
  assign toPipeline_0_be      = mbist_be;
  assign toPipeline_0_addr    = mbist_addr;
  assign toPipeline_0_indata  = mbist_indata;
  assign toPipeline_0_readen  = mbist_readen;
  assign toPipeline_0_addr_rd = mbist_addr_rd;

  // ---- response: Mux1H over one subtree whose hit is constant true --------
  assign mbist_ack     = toPipeline_0_ack;
  assign mbist_outdata = toPipeline_0_outdata;
endmodule
