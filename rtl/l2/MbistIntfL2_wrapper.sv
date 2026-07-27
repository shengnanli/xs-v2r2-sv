// MbistIntfL2 —— 手写可读实现(TL2 shard, AUX signoff)。
//
// L2 顶层 MBIST(内建自测)接口: 把上游 mbist 控制器的一组信号原样转接到
// 下游流水级端口 toPipeline_0_*。纯组合直通, 无状态、无时钟/复位。
//   下行(控制/写): mbist_* -> toPipeline_0_*
//     array/all/req/writeen/be/addr/indata/readen/addr_rd
//   上行(应答/读): toPipeline_0_* -> mbist_*
//     ack / outdata
//
// golden MbistIntfL2 逐 assign 与本文件一一对应, 逐位等价。
module MbistIntfL2(
  output [5:0]   toPipeline_0_array,
  output         toPipeline_0_all,
  output         toPipeline_0_req,
  input          toPipeline_0_ack,
  output         toPipeline_0_writeen,
  output [7:0]   toPipeline_0_be,
  output [12:0]  toPipeline_0_addr,
  output [103:0] toPipeline_0_indata,
  output         toPipeline_0_readen,
  output [12:0]  toPipeline_0_addr_rd,
  input  [103:0] toPipeline_0_outdata,
  input  [5:0]   mbist_array,
  input          mbist_all,
  input          mbist_req,
  output         mbist_ack,
  input          mbist_writeen,
  input  [7:0]   mbist_be,
  input  [12:0]  mbist_addr,
  input  [103:0] mbist_indata,
  input          mbist_readen,
  input  [12:0]  mbist_addr_rd,
  output [103:0] mbist_outdata
);
  // 下行: 控制/写通道原样转接
  assign toPipeline_0_array   = mbist_array;
  assign toPipeline_0_all     = mbist_all;
  assign toPipeline_0_req     = mbist_req;
  assign toPipeline_0_writeen = mbist_writeen;
  assign toPipeline_0_be      = mbist_be;
  assign toPipeline_0_addr    = mbist_addr;
  assign toPipeline_0_indata  = mbist_indata;
  assign toPipeline_0_readen  = mbist_readen;
  assign toPipeline_0_addr_rd = mbist_addr_rd;
  // 上行: 应答/读回原样转接
  assign mbist_ack     = toPipeline_0_ack;
  assign mbist_outdata = toPipeline_0_outdata;
endmodule
