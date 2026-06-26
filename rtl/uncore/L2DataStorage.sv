// =============================================================================
//  L2DataStorage —— L2 DataStorage 层的 MBIST 流水分发节点 (核 xs_L2DataStorage_core)
// -----------------------------------------------------------------------------
//  utility.mbist.MbistPipeline 在 coupledL2 DataStorage 层的单态化实例。它有 8 个
//  直接挂载的 SRAM child (没有下游流水节点)，认领 array 9..16，且全部是
//  extraHold (读/写使能用 2 位展宽寄存器的低位 renStretched[0]/wenStretched[0])：
//      child0 (array 9 ) ... child7 (array 16)
//      每个 child 同构：addr13/data69/mask1；array 输出 child0..6 为 4 位、
//      child7 为 5 位 (全 arrayReg)。
//
//  公共行为见 mbist_pipe_pkg；本文件写 DataStorage 特有的 8 路 SRAM 铺开。
//  outdata = 各 child dout (= selected ? rdata : 0) 的组合 OR (同宽 69 位)。
// =============================================================================
module xs_L2DataStorage_core
  import mbist_pipe_pkg::*;
(
  input         clock,
  input         reset,

  // 上游 MBIST 总线
  input  [4:0]  mbist_array,
  input         mbist_all,
  input         mbist_req,
  output        mbist_ack,
  input         mbist_writeen,
  input         mbist_be,
  input  [12:0] mbist_addr,
  input  [68:0] mbist_indata,
  input         mbist_readen,
  input  [12:0] mbist_addr_rd,
  output [68:0] mbist_outdata,

  // 8 路 SRAM child (同构 addr13/data69/mask1)
  output [12:0] toSRAM_0_addr, output [12:0] toSRAM_0_addr_rd,
  output [68:0] toSRAM_0_wdata, output toSRAM_0_wmask,
  output toSRAM_0_re, output toSRAM_0_we, input [68:0] toSRAM_0_rdata,
  output toSRAM_0_ack, output toSRAM_0_selectedOH, output [3:0] toSRAM_0_array,

  output [12:0] toSRAM_1_addr, output [12:0] toSRAM_1_addr_rd,
  output [68:0] toSRAM_1_wdata, output toSRAM_1_wmask,
  output toSRAM_1_re, output toSRAM_1_we, input [68:0] toSRAM_1_rdata,
  output toSRAM_1_ack, output toSRAM_1_selectedOH, output [3:0] toSRAM_1_array,

  output [12:0] toSRAM_2_addr, output [12:0] toSRAM_2_addr_rd,
  output [68:0] toSRAM_2_wdata, output toSRAM_2_wmask,
  output toSRAM_2_re, output toSRAM_2_we, input [68:0] toSRAM_2_rdata,
  output toSRAM_2_ack, output toSRAM_2_selectedOH, output [3:0] toSRAM_2_array,

  output [12:0] toSRAM_3_addr, output [12:0] toSRAM_3_addr_rd,
  output [68:0] toSRAM_3_wdata, output toSRAM_3_wmask,
  output toSRAM_3_re, output toSRAM_3_we, input [68:0] toSRAM_3_rdata,
  output toSRAM_3_ack, output toSRAM_3_selectedOH, output [3:0] toSRAM_3_array,

  output [12:0] toSRAM_4_addr, output [12:0] toSRAM_4_addr_rd,
  output [68:0] toSRAM_4_wdata, output toSRAM_4_wmask,
  output toSRAM_4_re, output toSRAM_4_we, input [68:0] toSRAM_4_rdata,
  output toSRAM_4_ack, output toSRAM_4_selectedOH, output [3:0] toSRAM_4_array,

  output [12:0] toSRAM_5_addr, output [12:0] toSRAM_5_addr_rd,
  output [68:0] toSRAM_5_wdata, output toSRAM_5_wmask,
  output toSRAM_5_re, output toSRAM_5_we, input [68:0] toSRAM_5_rdata,
  output toSRAM_5_ack, output toSRAM_5_selectedOH, output [3:0] toSRAM_5_array,

  output [12:0] toSRAM_6_addr, output [12:0] toSRAM_6_addr_rd,
  output [68:0] toSRAM_6_wdata, output toSRAM_6_wmask,
  output toSRAM_6_re, output toSRAM_6_we, input [68:0] toSRAM_6_rdata,
  output toSRAM_6_ack, output toSRAM_6_selectedOH, output [3:0] toSRAM_6_array,

  output [12:0] toSRAM_7_addr, output [12:0] toSRAM_7_addr_rd,
  output [68:0] toSRAM_7_wdata, output toSRAM_7_wmask,
  output toSRAM_7_re, output toSRAM_7_we, input [68:0] toSRAM_7_rdata,
  output toSRAM_7_ack, output toSRAM_7_selectedOH, output [4:0] toSRAM_7_array
);

  // array 命中：本节点认领 array 9..16
  wire array_hit = (mbist_array >= 5'h9) & (mbist_array <= 5'h10);

  // 公共输入寄存级 (extraHold)
  logic [4:0]  arrayReg;
  logic        reqReg, allReg, wenReg, renReg;
  logic        beReg;
  logic [12:0] addrReg, addrRdReg;
  logic [68:0] dataInReg;
  logic [1:0]  wenStretched, renStretched;

  // BE_W=1、DATA_W=69；wenReg/renReg 在 extraHold 下不直接用，但 ctrl 仍寄存。
  logic        unused_wen, unused_ren;
  xs_mbist_pipe_ctrl #(
    .ARRAY_W(5), .BE_W(1), .ADDR_W(13), .DATA_W(69), .HAS_HOLD(1)
  ) u_ctrl (
    .clock(clock), .reset(reset),
    .mbist_all(mbist_all), .mbist_req(mbist_req),
    .mbist_writeen(mbist_writeen), .mbist_readen(mbist_readen),
    .mbist_array(mbist_array), .mbist_be(mbist_be),
    .mbist_addr(mbist_addr), .mbist_indata(mbist_indata),
    .mbist_addr_rd(mbist_addr_rd), .array_hit(array_hit),
    .arrayReg(arrayReg), .reqReg(reqReg), .allReg(allReg),
    .wenReg(unused_wen), .renReg(unused_ren), .beReg(beReg),
    .addrReg(addrReg), .dataInReg(dataInReg), .addrRdReg(addrRdReg),
    .wenStretched(wenStretched), .renStretched(renStretched)
  );

  // extraHold：读/写使能取展宽寄存器低位
  wire we_hold = wenStretched[0];
  wire re_hold = renStretched[0];

  // 每个 SRAM child 认领单一 array 编号 (9..16)
  wire sel_0 = (arrayReg == 5'h9);  wire spread_0 = sel_0 | allReg;
  wire sel_1 = (arrayReg == 5'hA);  wire spread_1 = sel_1 | allReg;
  wire sel_2 = (arrayReg == 5'hB);  wire spread_2 = sel_2 | allReg;
  wire sel_3 = (arrayReg == 5'hC);  wire spread_3 = sel_3 | allReg;
  wire sel_4 = (arrayReg == 5'hD);  wire spread_4 = sel_4 | allReg;
  wire sel_5 = (arrayReg == 5'hE);  wire spread_5 = sel_5 | allReg;
  wire sel_6 = (arrayReg == 5'hF);  wire spread_6 = sel_6 | allReg;
  wire sel_7 = (arrayReg == 5'h10); wire spread_7 = sel_7 | allReg;

  // 输出
  assign mbist_ack = reqReg;
  assign mbist_outdata =
      (sel_0 ? toSRAM_0_rdata : 69'h0)
    | (sel_1 ? toSRAM_1_rdata : 69'h0)
    | (sel_2 ? toSRAM_2_rdata : 69'h0)
    | (sel_3 ? toSRAM_3_rdata : 69'h0)
    | (sel_4 ? toSRAM_4_rdata : 69'h0)
    | (sel_5 ? toSRAM_5_rdata : 69'h0)
    | (sel_6 ? toSRAM_6_rdata : 69'h0)
    | (sel_7 ? toSRAM_7_rdata : 69'h0);

  // child0 (array 9)
  assign toSRAM_0_addr=spread_0?addrReg:13'h0;  assign toSRAM_0_addr_rd=spread_0?addrRdReg:13'h0;
  assign toSRAM_0_wdata=dataInReg;              assign toSRAM_0_wmask=beReg;
  assign toSRAM_0_re=spread_0&re_hold;          assign toSRAM_0_we=spread_0&we_hold;
  assign toSRAM_0_ack=reqReg;                   assign toSRAM_0_selectedOH=allReg|~reqReg|sel_0;
  assign toSRAM_0_array=arrayReg[3:0];
  // child1 (array 10)
  assign toSRAM_1_addr=spread_1?addrReg:13'h0;  assign toSRAM_1_addr_rd=spread_1?addrRdReg:13'h0;
  assign toSRAM_1_wdata=dataInReg;              assign toSRAM_1_wmask=beReg;
  assign toSRAM_1_re=spread_1&re_hold;          assign toSRAM_1_we=spread_1&we_hold;
  assign toSRAM_1_ack=reqReg;                   assign toSRAM_1_selectedOH=allReg|~reqReg|sel_1;
  assign toSRAM_1_array=arrayReg[3:0];
  // child2 (array 11)
  assign toSRAM_2_addr=spread_2?addrReg:13'h0;  assign toSRAM_2_addr_rd=spread_2?addrRdReg:13'h0;
  assign toSRAM_2_wdata=dataInReg;              assign toSRAM_2_wmask=beReg;
  assign toSRAM_2_re=spread_2&re_hold;          assign toSRAM_2_we=spread_2&we_hold;
  assign toSRAM_2_ack=reqReg;                   assign toSRAM_2_selectedOH=allReg|~reqReg|sel_2;
  assign toSRAM_2_array=arrayReg[3:0];
  // child3 (array 12)
  assign toSRAM_3_addr=spread_3?addrReg:13'h0;  assign toSRAM_3_addr_rd=spread_3?addrRdReg:13'h0;
  assign toSRAM_3_wdata=dataInReg;              assign toSRAM_3_wmask=beReg;
  assign toSRAM_3_re=spread_3&re_hold;          assign toSRAM_3_we=spread_3&we_hold;
  assign toSRAM_3_ack=reqReg;                   assign toSRAM_3_selectedOH=allReg|~reqReg|sel_3;
  assign toSRAM_3_array=arrayReg[3:0];
  // child4 (array 13)
  assign toSRAM_4_addr=spread_4?addrReg:13'h0;  assign toSRAM_4_addr_rd=spread_4?addrRdReg:13'h0;
  assign toSRAM_4_wdata=dataInReg;              assign toSRAM_4_wmask=beReg;
  assign toSRAM_4_re=spread_4&re_hold;          assign toSRAM_4_we=spread_4&we_hold;
  assign toSRAM_4_ack=reqReg;                   assign toSRAM_4_selectedOH=allReg|~reqReg|sel_4;
  assign toSRAM_4_array=arrayReg[3:0];
  // child5 (array 14)
  assign toSRAM_5_addr=spread_5?addrReg:13'h0;  assign toSRAM_5_addr_rd=spread_5?addrRdReg:13'h0;
  assign toSRAM_5_wdata=dataInReg;              assign toSRAM_5_wmask=beReg;
  assign toSRAM_5_re=spread_5&re_hold;          assign toSRAM_5_we=spread_5&we_hold;
  assign toSRAM_5_ack=reqReg;                   assign toSRAM_5_selectedOH=allReg|~reqReg|sel_5;
  assign toSRAM_5_array=arrayReg[3:0];
  // child6 (array 15)
  assign toSRAM_6_addr=spread_6?addrReg:13'h0;  assign toSRAM_6_addr_rd=spread_6?addrRdReg:13'h0;
  assign toSRAM_6_wdata=dataInReg;              assign toSRAM_6_wmask=beReg;
  assign toSRAM_6_re=spread_6&re_hold;          assign toSRAM_6_we=spread_6&we_hold;
  assign toSRAM_6_ack=reqReg;                   assign toSRAM_6_selectedOH=allReg|~reqReg|sel_6;
  assign toSRAM_6_array=arrayReg[3:0];
  // child7 (array 16)：array 输出取全 5 位
  assign toSRAM_7_addr=spread_7?addrReg:13'h0;  assign toSRAM_7_addr_rd=spread_7?addrRdReg:13'h0;
  assign toSRAM_7_wdata=dataInReg;              assign toSRAM_7_wmask=beReg;
  assign toSRAM_7_re=spread_7&re_hold;          assign toSRAM_7_we=spread_7&we_hold;
  assign toSRAM_7_ack=reqReg;                   assign toSRAM_7_selectedOH=allReg|~reqReg|sel_7;
  assign toSRAM_7_array=arrayReg;

endmodule
