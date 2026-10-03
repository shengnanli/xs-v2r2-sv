// =============================================================================
// MbistIntfMemBlk —— MemBlock 的 MBIST 接口：把 MBIST 控制器的标准总线原样转给本块的 MBIST 分发流水
//
// 在哪一层：MemBlock 顶层（mem/MemBlock.scala `new MbistInterface(..., name = "MbistIntfMemBlk", pipelineNum = 1)`），
//   一侧 mbist_* 是对外的 MBIST 标准接口（MbitsStandardInterface），另一侧 toPipeline_0_* 接本块唯一的
//   MBIST 分发流水 MbistPipeMemBlk（再往下分到访存各块的 SRAM）。Scala 类：utility/mbist/MbistPipeline.scala `class MbistInterface`。
// 机制：pipelineNum = 1，只有一条下游流水，所以 Scala 里的"按 array 号命中哪条流水"恒为 true：
//   · 下行 9 根（array/all/req/writeen/be/addr/indata/readen/addr_rd）直接广播给流水；
//   · 上行 ack 与 outdata 用 Mux1H(hit, ...) 选，hit 恒真 = 直通。
//   纯连线，无状态、无时钟。总线形状：data 148 位、be 2 位、addr 9 位。
// golden 对照：G1-canonical/golden-rtl/MbistIntfMemBlk.sv
// =============================================================================
module MbistIntfMemBlk (
  output logic [6:0]   toPipeline_0_array,
  output logic         toPipeline_0_all,
  output logic         toPipeline_0_req,
  input  logic         toPipeline_0_ack,
  output logic         toPipeline_0_writeen,
  output logic [1:0]   toPipeline_0_be,
  output logic [8:0]   toPipeline_0_addr,
  output logic [147:0] toPipeline_0_indata,
  output logic         toPipeline_0_readen,
  output logic [8:0]   toPipeline_0_addr_rd,
  input  logic [147:0] toPipeline_0_outdata,
  input  logic [6:0]   mbist_array,
  input  logic         mbist_all,
  input  logic         mbist_req,
  output logic         mbist_ack,
  input  logic         mbist_writeen,
  input  logic [1:0]   mbist_be,
  input  logic [8:0]   mbist_addr,
  input  logic [147:0] mbist_indata,
  input  logic         mbist_readen,
  input  logic [8:0]   mbist_addr_rd,
  output logic [147:0] mbist_outdata
);

  // ---- 下行：MBIST 控制器 -> 分发流水（广播）----
  assign toPipeline_0_array   = mbist_array;
  assign toPipeline_0_all     = mbist_all;
  assign toPipeline_0_req     = mbist_req;
  assign toPipeline_0_writeen = mbist_writeen;
  assign toPipeline_0_be      = mbist_be;
  assign toPipeline_0_addr    = mbist_addr;
  assign toPipeline_0_indata  = mbist_indata;
  assign toPipeline_0_readen  = mbist_readen;
  assign toPipeline_0_addr_rd = mbist_addr_rd;

  // ---- 上行：分发流水 -> MBIST 控制器（只有一条流水，Mux1H 退化为直通）----
  assign mbist_ack     = toPipeline_0_ack;
  assign mbist_outdata = toPipeline_0_outdata;
endmodule
