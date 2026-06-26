// =============================================================================
//  L2Directory —— L2 Directory 层的 MBIST 流水分发节点 (核 xs_L2Directory_core)
// -----------------------------------------------------------------------------
//  utility.mbist.MbistPipeline 在 coupledL2 Directory 层的单态化实例。它有 7 个
//  直接挂载的 SRAM child (没有下游流水节点)，认领 array 2..8：
//      child0 (array 2) : addr10/data76/mask4   array 输出 2 位
//      child1 (array 3) : addr10/data76/mask4   array 输出 2 位
//      child2 (array 4) : addr10/data76/mask4   array 输出 3 位
//      child3 (array 5) : addr10/data76/mask4   array 输出 3 位
//      child4 (array 6) : addr10/data104/mask8  array 输出 3 位
//      child5 (array 7) : addr10/data16/mask1   array 输出 3 位
//      child6 (array 8) : addr10/data8/mask8    array 输出 4 位
//  非 extraHold：读/写使能直接用 renReg/wenReg。
//
//  公共行为见 mbist_pipe_pkg；本文件写 Directory 特有的 7 路 SRAM 铺开。
//  对 SRAM child：
//    selectedOH = allReg | ~reqReg | selectedVec  (req 低时强制全选 = 1 位全 1)
//    读数据 dout = selected ? rdata : 0，组合 OR 后直接回送 (不寄存)。
//  各 child 数据宽度不同，OR 时按 104 位零扩展求并 (Chisel UInt OR 语义)。
// =============================================================================
module xs_L2Directory_core
  import mbist_pipe_pkg::*;
(
  input          clock,
  input          reset,

  // 上游 MBIST 总线
  input  [3:0]   mbist_array,
  input          mbist_all,
  input          mbist_req,
  output         mbist_ack,
  input          mbist_writeen,
  input  [7:0]   mbist_be,
  input  [9:0]   mbist_addr,
  input  [103:0] mbist_indata,
  input          mbist_readen,
  input  [9:0]   mbist_addr_rd,
  output [103:0] mbist_outdata,

  // 7 路 SRAM child
  output [9:0]   toSRAM_0_addr,    output [9:0]   toSRAM_0_addr_rd,
  output [75:0]  toSRAM_0_wdata,   output [3:0]   toSRAM_0_wmask,
  output         toSRAM_0_re,      output         toSRAM_0_we,
  input  [75:0]  toSRAM_0_rdata,   output         toSRAM_0_ack,
  output         toSRAM_0_selectedOH, output [1:0] toSRAM_0_array,

  output [9:0]   toSRAM_1_addr,    output [9:0]   toSRAM_1_addr_rd,
  output [75:0]  toSRAM_1_wdata,   output [3:0]   toSRAM_1_wmask,
  output         toSRAM_1_re,      output         toSRAM_1_we,
  input  [75:0]  toSRAM_1_rdata,   output         toSRAM_1_ack,
  output         toSRAM_1_selectedOH, output [1:0] toSRAM_1_array,

  output [9:0]   toSRAM_2_addr,    output [9:0]   toSRAM_2_addr_rd,
  output [75:0]  toSRAM_2_wdata,   output [3:0]   toSRAM_2_wmask,
  output         toSRAM_2_re,      output         toSRAM_2_we,
  input  [75:0]  toSRAM_2_rdata,   output         toSRAM_2_ack,
  output         toSRAM_2_selectedOH, output [2:0] toSRAM_2_array,

  output [9:0]   toSRAM_3_addr,    output [9:0]   toSRAM_3_addr_rd,
  output [75:0]  toSRAM_3_wdata,   output [3:0]   toSRAM_3_wmask,
  output         toSRAM_3_re,      output         toSRAM_3_we,
  input  [75:0]  toSRAM_3_rdata,   output         toSRAM_3_ack,
  output         toSRAM_3_selectedOH, output [2:0] toSRAM_3_array,

  output [9:0]   toSRAM_4_addr,    output [9:0]   toSRAM_4_addr_rd,
  output [103:0] toSRAM_4_wdata,   output [7:0]   toSRAM_4_wmask,
  output         toSRAM_4_re,      output         toSRAM_4_we,
  input  [103:0] toSRAM_4_rdata,   output         toSRAM_4_ack,
  output         toSRAM_4_selectedOH, output [2:0] toSRAM_4_array,

  output [9:0]   toSRAM_5_addr,    output [9:0]   toSRAM_5_addr_rd,
  output [15:0]  toSRAM_5_wdata,   output         toSRAM_5_wmask,
  output         toSRAM_5_re,      output         toSRAM_5_we,
  input  [15:0]  toSRAM_5_rdata,   output         toSRAM_5_ack,
  output         toSRAM_5_selectedOH, output [2:0] toSRAM_5_array,

  output [9:0]   toSRAM_6_addr,    output [9:0]   toSRAM_6_addr_rd,
  output [7:0]   toSRAM_6_wdata,   output [7:0]   toSRAM_6_wmask,
  output         toSRAM_6_re,      output         toSRAM_6_we,
  input  [7:0]   toSRAM_6_rdata,   output         toSRAM_6_ack,
  output         toSRAM_6_selectedOH, output [3:0] toSRAM_6_array
);

  // array 命中：本节点认领 array 2..8
  wire array_hit = (mbist_array >= 4'h2) & (mbist_array <= 4'h8);

  // 公共输入寄存级 (无 extraHold)
  logic [3:0]   arrayReg;
  logic         reqReg, allReg, wenReg, renReg;
  logic [7:0]   beReg;
  logic [9:0]   addrReg, addrRdReg;
  logic [103:0] dataInReg;
  logic [1:0]   unused_wen_str, unused_ren_str;

  xs_mbist_pipe_ctrl #(
    .ARRAY_W(4), .BE_W(8), .ADDR_W(10), .DATA_W(104), .HAS_HOLD(0)
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

  // 每个 SRAM child 认领单一 array 编号 (2..8)
  wire sel_0 = (arrayReg == 4'h2);  wire spread_0 = sel_0 | allReg;
  wire sel_1 = (arrayReg == 4'h3);  wire spread_1 = sel_1 | allReg;
  wire sel_2 = (arrayReg == 4'h4);  wire spread_2 = sel_2 | allReg;
  wire sel_3 = (arrayReg == 4'h5);  wire spread_3 = sel_3 | allReg;
  wire sel_4 = (arrayReg == 4'h6);  wire spread_4 = sel_4 | allReg;
  wire sel_5 = (arrayReg == 4'h7);  wire spread_5 = sel_5 | allReg;
  wire sel_6 = (arrayReg == 4'h8);  wire spread_6 = sel_6 | allReg;

  // SRAM child 读数据 (组合)：selected 才取 rdata，否则 0
  wire [75:0]  dout_0 = sel_0 ? toSRAM_0_rdata : 76'h0;
  wire [75:0]  dout_1 = sel_1 ? toSRAM_1_rdata : 76'h0;
  wire [75:0]  dout_2 = sel_2 ? toSRAM_2_rdata : 76'h0;
  wire [75:0]  dout_3 = sel_3 ? toSRAM_3_rdata : 76'h0;
  wire [103:0] dout_4 = sel_4 ? toSRAM_4_rdata : 104'h0;
  wire [15:0]  dout_5 = sel_5 ? toSRAM_5_rdata : 16'h0;
  wire [7:0]   dout_6 = sel_6 ? toSRAM_6_rdata : 8'h0;

  // ---------------------------------------------------------------------------
  //  输出
  // ---------------------------------------------------------------------------
  assign mbist_ack = reqReg;

  // mbist.outdata = 各 child dout 按 104 位零扩展求 OR (Chisel UInt OR 语义)
  assign mbist_outdata =
      {28'h0, dout_0}
    | {28'h0, dout_1}
    | {28'h0, dout_2}
    | {28'h0, dout_3}
    | dout_4
    | {88'h0, dout_5}
    | {96'h0, dout_6};

  // selectedOH：广播 | req 低时强制 1 | 选中
  // child0 (array 2)
  assign toSRAM_0_addr       = spread_0 ? addrReg : 10'h0;
  assign toSRAM_0_addr_rd    = spread_0 ? addrRdReg : 10'h0;
  assign toSRAM_0_wdata      = dataInReg[75:0];
  assign toSRAM_0_wmask      = beReg[3:0];
  assign toSRAM_0_re         = spread_0 & renReg;
  assign toSRAM_0_we         = spread_0 & wenReg;
  assign toSRAM_0_ack        = reqReg;
  assign toSRAM_0_selectedOH = allReg | ~reqReg | sel_0;
  assign toSRAM_0_array      = arrayReg[1:0];
  // child1 (array 3)
  assign toSRAM_1_addr       = spread_1 ? addrReg : 10'h0;
  assign toSRAM_1_addr_rd    = spread_1 ? addrRdReg : 10'h0;
  assign toSRAM_1_wdata      = dataInReg[75:0];
  assign toSRAM_1_wmask      = beReg[3:0];
  assign toSRAM_1_re         = spread_1 & renReg;
  assign toSRAM_1_we         = spread_1 & wenReg;
  assign toSRAM_1_ack        = reqReg;
  assign toSRAM_1_selectedOH = allReg | ~reqReg | sel_1;
  assign toSRAM_1_array      = arrayReg[1:0];
  // child2 (array 4)
  assign toSRAM_2_addr       = spread_2 ? addrReg : 10'h0;
  assign toSRAM_2_addr_rd    = spread_2 ? addrRdReg : 10'h0;
  assign toSRAM_2_wdata      = dataInReg[75:0];
  assign toSRAM_2_wmask      = beReg[3:0];
  assign toSRAM_2_re         = spread_2 & renReg;
  assign toSRAM_2_we         = spread_2 & wenReg;
  assign toSRAM_2_ack        = reqReg;
  assign toSRAM_2_selectedOH = allReg | ~reqReg | sel_2;
  assign toSRAM_2_array      = arrayReg[2:0];
  // child3 (array 5)
  assign toSRAM_3_addr       = spread_3 ? addrReg : 10'h0;
  assign toSRAM_3_addr_rd    = spread_3 ? addrRdReg : 10'h0;
  assign toSRAM_3_wdata      = dataInReg[75:0];
  assign toSRAM_3_wmask      = beReg[3:0];
  assign toSRAM_3_re         = spread_3 & renReg;
  assign toSRAM_3_we         = spread_3 & wenReg;
  assign toSRAM_3_ack        = reqReg;
  assign toSRAM_3_selectedOH = allReg | ~reqReg | sel_3;
  assign toSRAM_3_array      = arrayReg[2:0];
  // child4 (array 6)
  assign toSRAM_4_addr       = spread_4 ? addrReg : 10'h0;
  assign toSRAM_4_addr_rd    = spread_4 ? addrRdReg : 10'h0;
  assign toSRAM_4_wdata      = dataInReg;
  assign toSRAM_4_wmask      = beReg;
  assign toSRAM_4_re         = spread_4 & renReg;
  assign toSRAM_4_we         = spread_4 & wenReg;
  assign toSRAM_4_ack        = reqReg;
  assign toSRAM_4_selectedOH = allReg | ~reqReg | sel_4;
  assign toSRAM_4_array      = arrayReg[2:0];
  // child5 (array 7)
  assign toSRAM_5_addr       = spread_5 ? addrReg : 10'h0;
  assign toSRAM_5_addr_rd    = spread_5 ? addrRdReg : 10'h0;
  assign toSRAM_5_wdata      = dataInReg[15:0];
  assign toSRAM_5_wmask      = beReg[0];
  assign toSRAM_5_re         = spread_5 & renReg;
  assign toSRAM_5_we         = spread_5 & wenReg;
  assign toSRAM_5_ack        = reqReg;
  assign toSRAM_5_selectedOH = allReg | ~reqReg | sel_5;
  assign toSRAM_5_array      = arrayReg[2:0];
  // child6 (array 8)
  assign toSRAM_6_addr       = spread_6 ? addrReg : 10'h0;
  assign toSRAM_6_addr_rd    = spread_6 ? addrRdReg : 10'h0;
  assign toSRAM_6_wdata      = dataInReg[7:0];
  assign toSRAM_6_wmask      = beReg;
  assign toSRAM_6_re         = spread_6 & renReg;
  assign toSRAM_6_we         = spread_6 & wenReg;
  assign toSRAM_6_ack        = reqReg;
  assign toSRAM_6_selectedOH = allReg | ~reqReg | sel_6;
  assign toSRAM_6_array      = arrayReg;

endmodule
