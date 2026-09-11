// =============================================================================
//  MBIST 流水分发节点 类型/常量包 (mbist_pipe_pkg)
// -----------------------------------------------------------------------------
//  L2Slice / L2Directory / L2DataStorage 三者本质上是**同一个** Chisel 模块
//  utility.mbist.MbistPipeline 的三个单态化实例，由香山 coupledL2 (L2 缓存) 的
//  Slice / Directory / DataStorage 三层在综合时自动插入，用于把芯片级 MBIST
//  (Memory Built-In Self Test，内存自测试) 总线请求**逐层分发**到一棵以 SRAM
//  为叶子的测试树。它们并不是 L2 的数据/目录功能逻辑，而是 SRAM 测试互联。
//
//  ---- MBIST 标准请求/响应总线 (MbitsStandardInterface / MbistBus) ----
//    array     : 本次请求的目标 array 编号 (一棵子树内 SRAM 从 0 起编号)
//    all       : 广播位，置 1 时对子树内**所有** array 同时操作 (不看 array 匹配)
//    req       : 请求有效
//    ack       : 响应 (= reqReg & 子流水 ack)
//    writeen   : 写使能
//    be        : 字节写选通 (byte-enable / write mask)
//    addr      : 写地址 (单口 SRAM 读写共用，双口另给 addr_rd)
//    indata    : 写数据
//    readen    : 读使能
//    addr_rd   : 读地址 (双口 SRAM 用)
//    outdata   : 读数据 (从子树 OR 归约上来)
//
//  ---- MbistPipeline 节点的统一行为 (utility/mbist/MbistPipeline.scala) ----
//    一个节点有若干 child，每个 child 是"下游流水节点"或"SRAM 节点"，并各自
//    认领一组 array 编号 (array_id)。节点把上游请求打一拍寄存，再按 arrayReg
//    匹配把请求**铺开** (spread) 给被选中的 child：
//
//      arrayHit  = (mbist.array ∈ 本节点所有 array_id)
//      activated = mbist.all | (mbist.req & arrayHit)        // 是否吃下本请求
//      dataValid = activated & (readen | writeen)            // 是否锁存数据/地址
//
//      arrayReg  = RegEnable(array,   activated)             // 寄存目标 array
//      allReg    = RegEnable(all,     activated)
//      wenReg    = RegEnable(writeen, activated)
//      renReg    = RegEnable(readen,  activated)
//      reqReg    = RegNext(req)                              // req 每拍都寄存
//      beReg/addrReg/dataInReg/addrRdReg = RegEnable(..., dataValid)
//
//      // 每个 child：
//      selected = (arrayReg ∈ child.array_id)
//      doSpread = selected | allReg                          // 广播或命中才下发
//      该 child 的 addr/addr_rd/re/we/all/... 仅在 doSpread 时透传，否则清零
//      selectedOH = Fill(allReg) | (reqReg ? selectedVec : 全 1)   // 选中 one-hot
//      读数据回程 = selected ? child.rdata : 0，再在节点处 OR 归约
//
//    对 extraHold=true 的 SRAM child，读/写使能改用 2 位"展宽寄存器"的低位：
//      activated&sig 时置 2'b11，否则每拍右移 (>>1)，使 re/we 维持 2 拍。
//
//  本包仅放公共常量；各变体的端口位宽/array 编号差异在各自模块内显式写出，
//  共用的"输入寄存器+控制门控"逻辑封装在 xs_mbist_pipe_ctrl。
// =============================================================================
package mbist_pipe_pkg;
  // MBIST array 广播判定中用到的"未选中即清零"约定无需额外常量；
  // 这里仅声明展宽寄存器宽度，供 extraHold SRAM 使用。
  localparam int MBIST_HOLD_W = 2;  // 读/写使能展宽寄存器位宽 (维持 2 拍)
endpackage

// =============================================================================
//  xs_mbist_pipe_ctrl —— MBIST 流水节点的公共"输入寄存级 + 门控"
// -----------------------------------------------------------------------------
//  L2Slice / L2Directory / L2DataStorage 共用的输入打拍逻辑 (见 mbist_pipe_pkg
//  的总说明)。把上游 MBIST 总线请求按 activated / dataValid 门控寄存一拍，
//  对外给出寄存后的控制/数据信号供各变体做 per-child 铺开。
//
//  纯寄存器叶子，无子模块、无 SRAM。参数为各字段位宽，arrayHit 由调用方按
//  本节点认领的 array 编号集合在外部算好后传入 (各变体 array 集合不同)。
// =============================================================================

module xs_mbist_pipe_ctrl
  import mbist_pipe_pkg::*;
#(
  parameter int ARRAY_W = 5,   // mbist_array 位宽
  parameter int BE_W    = 8,   // 字节选通位宽
  parameter int ADDR_W  = 13,  // 地址位宽
  parameter int DATA_W  = 104, // 数据位宽
  parameter bit HAS_HOLD = 0   // 是否生成读/写使能展宽寄存器 (extraHold SRAM)
)(
  input  logic               clock,
  input  logic               reset,

  // 上游 MBIST 请求 (组合输入)
  input  logic               mbist_all,
  input  logic               mbist_req,
  input  logic               mbist_writeen,
  input  logic               mbist_readen,
  input  logic [ARRAY_W-1:0] mbist_array,
  input  logic [BE_W-1:0]    mbist_be,
  input  logic [ADDR_W-1:0]  mbist_addr,
  input  logic [DATA_W-1:0]  mbist_indata,
  input  logic [ADDR_W-1:0]  mbist_addr_rd,

  // 本节点是否认领该 array 编号 (由调用方按 array 集合算出)
  input  logic               array_hit,

  // 寄存后的控制/数据 (供 per-child 铺开)
  output logic [ARRAY_W-1:0] arrayReg,
  output logic               reqReg,
  output logic               allReg,
  output logic               wenReg,
  output logic               renReg,
  output logic [BE_W-1:0]    beReg,
  output logic [ADDR_W-1:0]  addrReg,
  output logic [DATA_W-1:0]  dataInReg,
  output logic [ADDR_W-1:0]  addrRdReg,

  // extraHold 展宽使能 (HAS_HOLD=0 时恒 0)
  output logic [MBIST_HOLD_W-1:0] wenStretched,
  output logic [MBIST_HOLD_W-1:0] renStretched
);

  // 是否吃下本请求：广播位，或 (请求有效 & 命中本节点 array 集合)
  wire activated = mbist_all | (mbist_req & array_hit);
  // 是否锁存地址/数据 (只有读或写才需要)
  wire dataValid = activated & (mbist_readen | mbist_writeen);

  // ---- 带异步复位的寄存器组 (golden: posedge clock or posedge reset) ----
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      arrayReg  <= '0;
      reqReg    <= 1'b0;
      allReg    <= 1'b0;
      beReg     <= '0;
      addrReg   <= '0;
      dataInReg <= '0;
      addrRdReg <= '0;
    end else begin
      // activated 才更新目标 array / 广播
      if (activated) begin
        arrayReg <= mbist_array;
        allReg   <= mbist_all;
      end
      // req 每拍都寄存 (RegNext)
      reqReg <= mbist_req;
      // dataValid 才锁存数据/地址/字节选通
      if (dataValid) begin
        beReg     <= mbist_be;
        addrReg   <= mbist_addr;
        dataInReg <= mbist_indata;
        addrRdReg <= mbist_addr_rd;
      end
    end
  end

  // ---- wenReg/renReg：仅非 extraHold 变体存这两个寄存器 ----
  //  extraHold(HAS_HOLD=1)下读/写使能改用 wenStretched/renStretched，golden 单
  //  态化时未生成 wenReg/renReg → 这里同样按 HAS_HOLD gate 掉，避免 impl-only 死位。
  generate
    if (HAS_HOLD) begin : g_no_wenren
      assign wenReg = 1'b0;
      assign renReg = 1'b0;
    end else begin : g_wenren
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          wenReg <= 1'b0;
          renReg <= 1'b0;
        end else if (activated) begin
          // activated 才更新读/写使能
          wenReg <= mbist_writeen;
          renReg <= mbist_readen;
        end
      end
    end
  endgenerate

  // ---- extraHold：读/写使能展宽寄存器 (维持 MBIST_HOLD_W 拍) ----
  generate
    if (HAS_HOLD) begin : g_hold
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          wenStretched <= '0;
          renStretched <= '0;
        end else begin
          // activated&writeen 时置全 1，否则每拍右移补 0
          if (activated & mbist_writeen)
            wenStretched <= {MBIST_HOLD_W{1'b1}};
          else if (|wenStretched)
            wenStretched <= {1'b0, wenStretched[MBIST_HOLD_W-1:1]};

          if (activated & mbist_readen)
            renStretched <= {MBIST_HOLD_W{1'b1}};
          else if (|renStretched)
            renStretched <= {1'b0, renStretched[MBIST_HOLD_W-1:1]};
        end
      end
    end else begin : g_nohold
      assign wenStretched = '0;
      assign renStretched = '0;
    end
  endgenerate

endmodule

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

// 自动生成：scripts/gen_l2mbist.py —— 勿手改

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module L2Directory(
  input clock,
  input reset,
  input [3:0] mbist_array,
  input mbist_all,
  input mbist_req,
  output mbist_ack,
  input mbist_writeen,
  input [7:0] mbist_be,
  input [9:0] mbist_addr,
  input [103:0] mbist_indata,
  input mbist_readen,
  input [9:0] mbist_addr_rd,
  output [103:0] mbist_outdata,
  output [9:0] toSRAM_0_addr,
  output [9:0] toSRAM_0_addr_rd,
  output [75:0] toSRAM_0_wdata,
  output [3:0] toSRAM_0_wmask,
  output toSRAM_0_re,
  output toSRAM_0_we,
  input [75:0] toSRAM_0_rdata,
  output toSRAM_0_ack,
  output toSRAM_0_selectedOH,
  output [1:0] toSRAM_0_array,
  output [9:0] toSRAM_1_addr,
  output [9:0] toSRAM_1_addr_rd,
  output [75:0] toSRAM_1_wdata,
  output [3:0] toSRAM_1_wmask,
  output toSRAM_1_re,
  output toSRAM_1_we,
  input [75:0] toSRAM_1_rdata,
  output toSRAM_1_ack,
  output toSRAM_1_selectedOH,
  output [1:0] toSRAM_1_array,
  output [9:0] toSRAM_2_addr,
  output [9:0] toSRAM_2_addr_rd,
  output [75:0] toSRAM_2_wdata,
  output [3:0] toSRAM_2_wmask,
  output toSRAM_2_re,
  output toSRAM_2_we,
  input [75:0] toSRAM_2_rdata,
  output toSRAM_2_ack,
  output toSRAM_2_selectedOH,
  output [2:0] toSRAM_2_array,
  output [9:0] toSRAM_3_addr,
  output [9:0] toSRAM_3_addr_rd,
  output [75:0] toSRAM_3_wdata,
  output [3:0] toSRAM_3_wmask,
  output toSRAM_3_re,
  output toSRAM_3_we,
  input [75:0] toSRAM_3_rdata,
  output toSRAM_3_ack,
  output toSRAM_3_selectedOH,
  output [2:0] toSRAM_3_array,
  output [9:0] toSRAM_4_addr,
  output [9:0] toSRAM_4_addr_rd,
  output [103:0] toSRAM_4_wdata,
  output [7:0] toSRAM_4_wmask,
  output toSRAM_4_re,
  output toSRAM_4_we,
  input [103:0] toSRAM_4_rdata,
  output toSRAM_4_ack,
  output toSRAM_4_selectedOH,
  output [2:0] toSRAM_4_array,
  output [9:0] toSRAM_5_addr,
  output [9:0] toSRAM_5_addr_rd,
  output [15:0] toSRAM_5_wdata,
  output toSRAM_5_wmask,
  output toSRAM_5_re,
  output toSRAM_5_we,
  input [15:0] toSRAM_5_rdata,
  output toSRAM_5_ack,
  output toSRAM_5_selectedOH,
  output [2:0] toSRAM_5_array,
  output [9:0] toSRAM_6_addr,
  output [9:0] toSRAM_6_addr_rd,
  output [7:0] toSRAM_6_wdata,
  output [7:0] toSRAM_6_wmask,
  output toSRAM_6_re,
  output toSRAM_6_we,
  input [7:0] toSRAM_6_rdata,
  output toSRAM_6_ack,
  output toSRAM_6_selectedOH,
  output [3:0] toSRAM_6_array
);
  xs_L2Directory_core u_core (
    .clock(clock),
    .reset(reset),
    .mbist_array(mbist_array),
    .mbist_all(mbist_all),
    .mbist_req(mbist_req),
    .mbist_ack(mbist_ack),
    .mbist_writeen(mbist_writeen),
    .mbist_be(mbist_be),
    .mbist_addr(mbist_addr),
    .mbist_indata(mbist_indata),
    .mbist_readen(mbist_readen),
    .mbist_addr_rd(mbist_addr_rd),
    .mbist_outdata(mbist_outdata),
    .toSRAM_0_addr(toSRAM_0_addr),
    .toSRAM_0_addr_rd(toSRAM_0_addr_rd),
    .toSRAM_0_wdata(toSRAM_0_wdata),
    .toSRAM_0_wmask(toSRAM_0_wmask),
    .toSRAM_0_re(toSRAM_0_re),
    .toSRAM_0_we(toSRAM_0_we),
    .toSRAM_0_rdata(toSRAM_0_rdata),
    .toSRAM_0_ack(toSRAM_0_ack),
    .toSRAM_0_selectedOH(toSRAM_0_selectedOH),
    .toSRAM_0_array(toSRAM_0_array),
    .toSRAM_1_addr(toSRAM_1_addr),
    .toSRAM_1_addr_rd(toSRAM_1_addr_rd),
    .toSRAM_1_wdata(toSRAM_1_wdata),
    .toSRAM_1_wmask(toSRAM_1_wmask),
    .toSRAM_1_re(toSRAM_1_re),
    .toSRAM_1_we(toSRAM_1_we),
    .toSRAM_1_rdata(toSRAM_1_rdata),
    .toSRAM_1_ack(toSRAM_1_ack),
    .toSRAM_1_selectedOH(toSRAM_1_selectedOH),
    .toSRAM_1_array(toSRAM_1_array),
    .toSRAM_2_addr(toSRAM_2_addr),
    .toSRAM_2_addr_rd(toSRAM_2_addr_rd),
    .toSRAM_2_wdata(toSRAM_2_wdata),
    .toSRAM_2_wmask(toSRAM_2_wmask),
    .toSRAM_2_re(toSRAM_2_re),
    .toSRAM_2_we(toSRAM_2_we),
    .toSRAM_2_rdata(toSRAM_2_rdata),
    .toSRAM_2_ack(toSRAM_2_ack),
    .toSRAM_2_selectedOH(toSRAM_2_selectedOH),
    .toSRAM_2_array(toSRAM_2_array),
    .toSRAM_3_addr(toSRAM_3_addr),
    .toSRAM_3_addr_rd(toSRAM_3_addr_rd),
    .toSRAM_3_wdata(toSRAM_3_wdata),
    .toSRAM_3_wmask(toSRAM_3_wmask),
    .toSRAM_3_re(toSRAM_3_re),
    .toSRAM_3_we(toSRAM_3_we),
    .toSRAM_3_rdata(toSRAM_3_rdata),
    .toSRAM_3_ack(toSRAM_3_ack),
    .toSRAM_3_selectedOH(toSRAM_3_selectedOH),
    .toSRAM_3_array(toSRAM_3_array),
    .toSRAM_4_addr(toSRAM_4_addr),
    .toSRAM_4_addr_rd(toSRAM_4_addr_rd),
    .toSRAM_4_wdata(toSRAM_4_wdata),
    .toSRAM_4_wmask(toSRAM_4_wmask),
    .toSRAM_4_re(toSRAM_4_re),
    .toSRAM_4_we(toSRAM_4_we),
    .toSRAM_4_rdata(toSRAM_4_rdata),
    .toSRAM_4_ack(toSRAM_4_ack),
    .toSRAM_4_selectedOH(toSRAM_4_selectedOH),
    .toSRAM_4_array(toSRAM_4_array),
    .toSRAM_5_addr(toSRAM_5_addr),
    .toSRAM_5_addr_rd(toSRAM_5_addr_rd),
    .toSRAM_5_wdata(toSRAM_5_wdata),
    .toSRAM_5_wmask(toSRAM_5_wmask),
    .toSRAM_5_re(toSRAM_5_re),
    .toSRAM_5_we(toSRAM_5_we),
    .toSRAM_5_rdata(toSRAM_5_rdata),
    .toSRAM_5_ack(toSRAM_5_ack),
    .toSRAM_5_selectedOH(toSRAM_5_selectedOH),
    .toSRAM_5_array(toSRAM_5_array),
    .toSRAM_6_addr(toSRAM_6_addr),
    .toSRAM_6_addr_rd(toSRAM_6_addr_rd),
    .toSRAM_6_wdata(toSRAM_6_wdata),
    .toSRAM_6_wmask(toSRAM_6_wmask),
    .toSRAM_6_re(toSRAM_6_re),
    .toSRAM_6_we(toSRAM_6_we),
    .toSRAM_6_rdata(toSRAM_6_rdata),
    .toSRAM_6_ack(toSRAM_6_ack),
    .toSRAM_6_selectedOH(toSRAM_6_selectedOH),
    .toSRAM_6_array(toSRAM_6_array)
  );
endmodule
