// MemBlock MBIST interface bridge.
// Pipeline/control leaf: preserve the wider memory data lane and byte-enable mask
// while forwarding the same request/acknowledge handshake as the frontend bridge.
module MbistIntfMemBlk(
  output [6:0]   toPipeline_0_array,
  output         toPipeline_0_all,
  output         toPipeline_0_req,
  input          toPipeline_0_ack,
  output         toPipeline_0_writeen,
  output [1:0]   toPipeline_0_be,
  output [8:0]   toPipeline_0_addr,
  output [147:0] toPipeline_0_indata,
  output         toPipeline_0_readen,
  output [8:0]   toPipeline_0_addr_rd,
  input  [147:0] toPipeline_0_outdata,
  input  [6:0]   mbist_array,
  input          mbist_all,
  input          mbist_req,
  output         mbist_ack,
  input          mbist_writeen,
  input  [1:0]   mbist_be,
  input  [8:0]   mbist_addr,
  input  [147:0] mbist_indata,
  input          mbist_readen,
  input  [8:0]   mbist_addr_rd,
  output [147:0] mbist_outdata
);
  assign toPipeline_0_array = mbist_array;
  assign toPipeline_0_all = mbist_all;
  assign toPipeline_0_req = mbist_req;
  assign toPipeline_0_writeen = mbist_writeen;
  assign toPipeline_0_be = mbist_be;
  assign toPipeline_0_addr = mbist_addr;
  assign toPipeline_0_indata = mbist_indata;
  assign toPipeline_0_readen = mbist_readen;
  assign toPipeline_0_addr_rd = mbist_addr_rd;
  assign mbist_ack = toPipeline_0_ack;
  assign mbist_outdata = toPipeline_0_outdata;
endmodule
