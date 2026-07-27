// =============================================================================
//  L2SliceN —— L2Slice 变体族共用的参数化可读核 (xs_L2SliceN_core)
// -----------------------------------------------------------------------------
//  utility.mbist.MbistPipeline 在 coupledL2 Slice 层的单态化实例, 每个 L2 slice
//  自动插入一个。golden 有 4 个单态化: L2Slice(基址 array 2)/L2Slice_1(基址
//  0x11)/L2Slice_2(基址 0x20)/L2Slice_3(基址 0x2F)。它们除了
//    - mbist_array / child array 端口位宽 (5 位 或 6 位)
//    - 本节点认领的 array 编号基址 BASE
//  以外, 逻辑与已签核绿的 xs_L2Slice_core **完全相同**:
//    child0 -> L2Directory 子树, 认领 [BASE   .. BASE+6] (7 个 array)
//    child1 -> L2DataStorage 子树, 认领 [BASE+7 .. BASE+14] (8 个 array)
//    本节点 arrayHit = [BASE .. BASE+14] (两子树并集)
//
//  与基址 core 一样: 上游请求打一拍 (xs_mbist_pipe_ctrl), 按 arrayReg 命中的子树
//  铺开下发, 两路读数据 OR 后寄存一拍回送 (pipelineDataOutReg, RegEnable(activated))。
//  child1 数据宽 69 位, 拼进 104 位低位 (高位补 0) 再与 child0 OR。
//
//  说明 firtool 对 L2Slice_1 的编码差异: 其 child1 第 8 个 array 编号 BASE+14 = 0x1F
//  (= 5 位全 1), firtool 把 `arrayReg == 5'h1F` 写成 `(&arrayReg)`; 语义等价, 本核用
//  统一的 (arrayReg == BASE+14) 表达, FM 逐位归约后一致。
// =============================================================================
module xs_L2SliceN_core
  import mbist_pipe_pkg::*;
#(
  parameter int ARRAY_W     = 5,   // mbist_array 位宽 (5 或 6)
  parameter int CH0_ARRAY_W = 4,   // child0 array 位宽
  parameter int CH1_ARRAY_W = 5,   // child1 array 位宽
  parameter int BASE        = 2    // 本节点认领的最小 array 编号
)(
  input          clock,
  input          reset,

  // 上游 MBIST 总线
  input  [ARRAY_W-1:0] mbist_array,
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

  // 下游 child0：L2Directory 子树 (array BASE..BASE+6)
  output [CH0_ARRAY_W-1:0] toNextPipeline_0_array,
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

  // 下游 child1：L2DataStorage 子树 (array BASE+7..BASE+14)
  output [CH1_ARRAY_W-1:0] toNextPipeline_1_array,
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

  // child0 认领 [BASE .. BASE+6], child1 认领 [BASE+7 .. BASE+14]。
  localparam [ARRAY_W-1:0] CH0_LO = ARRAY_W'(BASE);
  localparam [ARRAY_W-1:0] CH0_HI = ARRAY_W'(BASE + 6);
  localparam [ARRAY_W-1:0] CH1_LO = ARRAY_W'(BASE + 7);
  localparam [ARRAY_W-1:0] CH1_HI = ARRAY_W'(BASE + 14);

  // ---------------------------------------------------------------------------
  //  array 命中：本节点认领两个子树 array 集合之并 = [BASE .. BASE+14]。
  // ---------------------------------------------------------------------------
  wire array_hit = (mbist_array >= CH0_LO) & (mbist_array <= CH1_HI);

  // ---------------------------------------------------------------------------
  //  公共输入寄存级 (无 extraHold)。
  // ---------------------------------------------------------------------------
  logic [ARRAY_W-1:0] arrayReg;
  logic         reqReg, allReg, wenReg, renReg;
  logic [7:0]   beReg;
  logic [12:0]  addrReg, addrRdReg;
  logic [103:0] dataInReg;
  logic [1:0]   unused_wen_str, unused_ren_str;

  xs_mbist_pipe_ctrl #(
    .ARRAY_W(ARRAY_W), .BE_W(8), .ADDR_W(13), .DATA_W(104), .HAS_HOLD(0)
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
  //  child 选中：child0 认领 [BASE..BASE+6], child1 认领 [BASE+7..BASE+14]。
  // ---------------------------------------------------------------------------
  wire selected_0  = (arrayReg >= CH0_LO) & (arrayReg <= CH0_HI);   // L2Directory 子树
  wire selected_1  = (arrayReg >= CH1_LO) & (arrayReg <= CH1_HI);   // L2DataStorage 子树
  wire doSpread_0  = selected_0 | allReg;
  wire doSpread_1  = selected_1 | allReg;

  // ---------------------------------------------------------------------------
  //  pipeline child 读数据：寄存 (RegEnable(..., activated))。
  //  child1 数据宽 69 位, 拼进 104 位低位 (高位补 0) 再与 child0 OR。
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

  // child0 (L2Directory)：array 取低 CH0_ARRAY_W 位
  assign toNextPipeline_0_array    = doSpread_0 ? arrayReg[CH0_ARRAY_W-1:0] : '0;
  assign toNextPipeline_0_all      = doSpread_0 & allReg;
  assign toNextPipeline_0_req      = reqReg;
  assign toNextPipeline_0_writeen  = doSpread_0 & wenReg;
  assign toNextPipeline_0_be       = beReg;
  assign toNextPipeline_0_addr     = doSpread_0 ? addrReg[9:0] : 10'h0;
  assign toNextPipeline_0_indata   = dataInReg;
  assign toNextPipeline_0_readen   = doSpread_0 & renReg;
  assign toNextPipeline_0_addr_rd  = doSpread_0 ? addrRdReg[9:0] : 10'h0;

  // child1 (L2DataStorage)：array 取全 CH1_ARRAY_W 位, be 仅 1 位, data 取低 69 位
  assign toNextPipeline_1_array    = doSpread_1 ? arrayReg[CH1_ARRAY_W-1:0] : '0;
  assign toNextPipeline_1_all      = doSpread_1 & allReg;
  assign toNextPipeline_1_req      = reqReg;
  assign toNextPipeline_1_writeen  = doSpread_1 & wenReg;
  assign toNextPipeline_1_be       = beReg[0];
  assign toNextPipeline_1_addr     = doSpread_1 ? addrReg : 13'h0;
  assign toNextPipeline_1_indata   = dataInReg[68:0];
  assign toNextPipeline_1_readen   = doSpread_1 & renReg;
  assign toNextPipeline_1_addr_rd  = doSpread_1 ? addrRdReg : 13'h0;

endmodule
