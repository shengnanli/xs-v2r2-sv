// =============================================================================
//  L2Slice —— L2 Slice 层的 MBIST 流水分发节点 (可读重写核 xs_L2Slice_core)
// -----------------------------------------------------------------------------
//  utility.mbist.MbistPipeline 在 coupledL2 Slice 层的单态化实例。它有 2 个
//  "下游流水节点" child、没有直接挂的 SRAM：
//    toNextPipeline_0 -> L2Directory 子树，认领 array 2..8  (4 位 array 输出)
//    toNextPipeline_1 -> L2DataStorage 子树，认领 array 9..16(5 位 array 输出)
//  本节点把上游 MBIST 请求打一拍 (xs_mbist_pipe_ctrl)，再按 arrayReg 命中的
//  子树把请求铺开下发，并把两路读数据 OR 后寄存一拍回送 (mbist_outdata)。
//
//  公共行为见 mbist_pipe_pkg；本文件只写 Slice 特有的 2 路 pipeline 铺开。
//  pipeline child 的读数据是**寄存**的 (RegEnable(..., activated))，与挂 SRAM
//  的 Directory/DataStorage (组合 OR 回送) 不同。
//
//  端口位宽 (与 golden 一致)：mbist 侧 array=5b/be=8b/addr=13b/data=104b；
//  下发 child0 array=4b/be=8b/addr=10b/data=104b，child1 array=5b/be=1b/
//  addr=13b/data=69b。be/addr/data 下发时按 child 位宽截取低位。
// =============================================================================
module xs_L2Slice_core
  import mbist_pipe_pkg::*;
(
  input          clock,
  input          reset,

  // 上游 MBIST 总线
  input  [4:0]   mbist_array,
  input          mbist_all,
  input          mbist_req,
  output         mbist_ack,
  input          mbist_writeen,
  input  [7:0]   mbist_be,
  input  [12:0]  mbist_addr,
  input  [103:0] mbist_indata,
  input          mbist_readen,
  input  [12:0]  mbist_addr_rd,
  output [103:0] mbist_outdata,

  // 下游 child0：L2Directory 子树 (array 2..8)
  output [3:0]   toNextPipeline_0_array,
  output         toNextPipeline_0_all,
  output         toNextPipeline_0_req,
  input          toNextPipeline_0_ack,
  output         toNextPipeline_0_writeen,
  output [7:0]   toNextPipeline_0_be,
  output [9:0]   toNextPipeline_0_addr,
  output [103:0] toNextPipeline_0_indata,
  output         toNextPipeline_0_readen,
  output [9:0]   toNextPipeline_0_addr_rd,
  input  [103:0] toNextPipeline_0_outdata,

  // 下游 child1：L2DataStorage 子树 (array 9..16)
  output [4:0]   toNextPipeline_1_array,
  output         toNextPipeline_1_all,
  output         toNextPipeline_1_req,
  input          toNextPipeline_1_ack,
  output         toNextPipeline_1_writeen,
  output         toNextPipeline_1_be,
  output [12:0]  toNextPipeline_1_addr,
  output [68:0]  toNextPipeline_1_indata,
  output         toNextPipeline_1_readen,
  output [12:0]  toNextPipeline_1_addr_rd,
  input  [68:0]  toNextPipeline_1_outdata
);

  // ---------------------------------------------------------------------------
  //  array 命中：本节点认领 array 2..16，即两个子树 array 集合之并。
  // ---------------------------------------------------------------------------
  wire array_hit = (mbist_array >= 5'h2) & (mbist_array <= 5'h10);

  // ---------------------------------------------------------------------------
  //  公共输入寄存级 (无 extraHold)。
  // ---------------------------------------------------------------------------
  logic [4:0]   arrayReg;
  logic         reqReg, allReg, wenReg, renReg;
  logic [7:0]   beReg;
  logic [12:0]  addrReg, addrRdReg;
  logic [103:0] dataInReg;
  logic [1:0]   unused_wen_str, unused_ren_str;

  xs_mbist_pipe_ctrl #(
    .ARRAY_W(5), .BE_W(8), .ADDR_W(13), .DATA_W(104), .HAS_HOLD(0)
  ) u_ctrl (
    .clock(clock), .reset(reset),
    .mbist_all(mbist_all), .mbist_req(mbist_req),
    .mbist_writeen(mbist_writeen), .mbist_readen(mbist_readen),
    .mbist_array(mbist_array), .mbist_be(mbist_be),
    .mbist_addr(mbist_addr), .mbist_indata(mbist_indata),
    .mbist_addr_rd(mbist_addr_rd), .array_hit(array_hit),
    .arrayReg(arrayReg), .reqReg(reqReg), .allReg(allReg),
    .wenReg(wenReg), .renReg(renReg), .beReg(beReg),
    .addrReg(addrReg), .dataInReg(dataInReg), .addrRdReg(addrRdReg),
    .wenStretched(unused_wen_str), .renStretched(unused_ren_str)
  );

  // ---------------------------------------------------------------------------
  //  child 选中：child0 认领 array 2..8，child1 认领 array 9..16。
  // ---------------------------------------------------------------------------
  wire selected_0  = (arrayReg >= 5'h2) & (arrayReg <= 5'h8);   // L2Directory 子树
  wire selected_1  = (arrayReg >= 5'h9) & (arrayReg <= 5'h10);  // L2DataStorage 子树
  wire doSpread_0  = selected_0 | allReg;
  wire doSpread_1  = selected_1 | allReg;

  // ---------------------------------------------------------------------------
  //  pipeline child 读数据：寄存 (RegEnable(..., activated))。
  //  golden 用 activated 作使能；这里复用 ctrl 内同款门控条件。
  //  child1 数据宽 69 位，拼进 104 位低位 (高位补 0) 再与 child0 OR。
  // ---------------------------------------------------------------------------
  wire activated = mbist_all | (mbist_req & array_hit);
  logic [103:0] pipelineDataOutReg;
  always_ff @(posedge clock) begin
    if (activated)
      pipelineDataOutReg <=
        (selected_0 ? toNextPipeline_0_outdata : 104'h0)
        | {35'h0, (selected_1 ? toNextPipeline_1_outdata : 69'h0)};
  end

  // ---------------------------------------------------------------------------
  //  输出
  // ---------------------------------------------------------------------------
  assign mbist_ack     = reqReg & (toNextPipeline_0_ack | toNextPipeline_1_ack);
  assign mbist_outdata = pipelineDataOutReg;

  // child0 (L2Directory)：array 取低 4 位
  assign toNextPipeline_0_array    = doSpread_0 ? arrayReg[3:0] : 4'h0;
  assign toNextPipeline_0_all      = doSpread_0 & allReg;
  assign toNextPipeline_0_req      = reqReg;
  assign toNextPipeline_0_writeen  = doSpread_0 & wenReg;
  assign toNextPipeline_0_be       = beReg;
  assign toNextPipeline_0_addr     = doSpread_0 ? addrReg[9:0] : 10'h0;
  assign toNextPipeline_0_indata   = dataInReg;
  assign toNextPipeline_0_readen   = doSpread_0 & renReg;
  assign toNextPipeline_0_addr_rd  = doSpread_0 ? addrRdReg[9:0] : 10'h0;

  // child1 (L2DataStorage)：array 取全 5 位，be 仅 1 位，data 取低 69 位
  assign toNextPipeline_1_array    = doSpread_1 ? arrayReg : 5'h0;
  assign toNextPipeline_1_all      = doSpread_1 & allReg;
  assign toNextPipeline_1_req      = reqReg;
  assign toNextPipeline_1_writeen  = doSpread_1 & wenReg;
  assign toNextPipeline_1_be       = beReg[0];
  assign toNextPipeline_1_addr     = doSpread_1 ? addrReg : 13'h0;
  assign toNextPipeline_1_indata   = dataInReg[68:0];
  assign toNextPipeline_1_readen   = doSpread_1 & renReg;
  assign toNextPipeline_1_addr_rd  = doSpread_1 ? addrRdReg : 13'h0;

endmodule
