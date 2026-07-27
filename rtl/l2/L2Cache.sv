// L2Cache —— 手写可读实现(TL2 shard 3, AUX signoff, REPLACEMENT 真逻辑)。
//
// ★ golden L2Cache.sv 不是 Slice/directory/data 的装配父, 而是 L2 顶层的 MBIST
//   (内建自测)分发级: 把上游一拍 mbist 请求锁存, 再"扩散"(spread)到 5 条下游
//   toNextPipeline_0..4。无任何子模块例化, 无黑盒, 纯可读逻辑(0 个 _GEN_/_T_)。
//
// 请求锁存(activated = mbist_all | (mbist_req & array∈[0,0x3D])):
//   golden 里 activated 的门控还要求 mbist_array 落在合法 array-id 集合 0..0x3D
//   (即 62 个 array id 的 OR)。等价写法: array <= 6'h3D。
//   - array/all/wen/ren 在 activated 时锁存;
//   - be/addr/dataIn/addrRd 仅在 activated 且(读或写)时锁存;
//   - reqReg 每拍跟随 mbist_req(用作 ack 门控)。
//
// bank(pipeline)选择 —— 按 arrayReg 落在哪个 id 区间选中对应下游流水:
//   selected   : arrayReg ∈ {0,1}                 -> pipeline0
//   selected_1 : arrayReg ∈ [0x02,0x10]           -> pipeline1
//   selected_2 : arrayReg ∈ [0x11,0x1F]           -> pipeline2
//   selected_3 : arrayReg ∈ [0x20,0x2E]           -> pipeline3
//   selected_4 : arrayReg ∈ [0x2F,0x3D]           -> pipeline4
//   doSpread_k = selected_k | allReg (all=1 时全部流水同时选中)。
//   未选中的流水 addr/addr_rd 强制 0, all/wen/ren 门控清零。
//   各流水 array/addr 端口位宽不同(见端口), 用 arrayReg/addrReg 的低位切片驱动。
//
// 读回合并(pipelineDataOutReg, 无 reset, activated 时更新):
//   只有被 array 选中的那条流水 outdata 有效, 其余取 0, 五路相或成 104 位;
//   pipeline0 仅 13 位有效(零扩到 104), 其余 104 位。
//
// mbist_ack = reqReg & (任一下游 ack)。 mbist_outdata = pipelineDataOutReg。
//
// 本文件定义可读核 xs_L2Cache_core。golden 同名扁平端口包装在
// rtl/l2/L2Cache_wrapper.sv(仅 FM impl 侧例化本核), UT 变体 L2Cache_xs 在 verif/ut 下。
module xs_L2Cache_core(
  input          clock,
  input          reset,
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
  output [103:0] mbist_outdata,
  // toNextPipeline_0: array 1 位, be 1 位, addr 9 位, indata 13 位, outdata 13 位
  output         toNextPipeline_0_array,
  output         toNextPipeline_0_all,
  output         toNextPipeline_0_req,
  input          toNextPipeline_0_ack,
  output         toNextPipeline_0_writeen,
  output         toNextPipeline_0_be,
  output [8:0]   toNextPipeline_0_addr,
  output [12:0]  toNextPipeline_0_indata,
  output         toNextPipeline_0_readen,
  output [8:0]   toNextPipeline_0_addr_rd,
  input  [12:0]  toNextPipeline_0_outdata,
  // toNextPipeline_1: array 5 位, be 8 位, addr 13 位, indata 104 位, outdata 104 位
  output [4:0]   toNextPipeline_1_array,
  output         toNextPipeline_1_all,
  output         toNextPipeline_1_req,
  input          toNextPipeline_1_ack,
  output         toNextPipeline_1_writeen,
  output [7:0]   toNextPipeline_1_be,
  output [12:0]  toNextPipeline_1_addr,
  output [103:0] toNextPipeline_1_indata,
  output         toNextPipeline_1_readen,
  output [12:0]  toNextPipeline_1_addr_rd,
  input  [103:0] toNextPipeline_1_outdata,
  // toNextPipeline_2: array 5 位
  output [4:0]   toNextPipeline_2_array,
  output         toNextPipeline_2_all,
  output         toNextPipeline_2_req,
  input          toNextPipeline_2_ack,
  output         toNextPipeline_2_writeen,
  output [7:0]   toNextPipeline_2_be,
  output [12:0]  toNextPipeline_2_addr,
  output [103:0] toNextPipeline_2_indata,
  output         toNextPipeline_2_readen,
  output [12:0]  toNextPipeline_2_addr_rd,
  input  [103:0] toNextPipeline_2_outdata,
  // toNextPipeline_3: array 6 位
  output [5:0]   toNextPipeline_3_array,
  output         toNextPipeline_3_all,
  output         toNextPipeline_3_req,
  input          toNextPipeline_3_ack,
  output         toNextPipeline_3_writeen,
  output [7:0]   toNextPipeline_3_be,
  output [12:0]  toNextPipeline_3_addr,
  output [103:0] toNextPipeline_3_indata,
  output         toNextPipeline_3_readen,
  output [12:0]  toNextPipeline_3_addr_rd,
  input  [103:0] toNextPipeline_3_outdata,
  // toNextPipeline_4: array 6 位
  output [5:0]   toNextPipeline_4_array,
  output         toNextPipeline_4_all,
  output         toNextPipeline_4_req,
  input          toNextPipeline_4_ack,
  output         toNextPipeline_4_writeen,
  output [7:0]   toNextPipeline_4_be,
  output [12:0]  toNextPipeline_4_addr,
  output [103:0] toNextPipeline_4_indata,
  output         toNextPipeline_4_readen,
  output [12:0]  toNextPipeline_4_addr_rd,
  input  [103:0] toNextPipeline_4_outdata
);

  // ---- activated: all 或 (req 且 array 落在 0..0x3D) ----
  // golden 用 62 项 OR 展开 mbist_array∈{0x00..0x3D}; 等价 mbist_array <= 6'h3D。
  wire activated = mbist_all | (mbist_req & (mbist_array <= 6'h3D));

  // ---- 锁存的 MBIST 控制/数据寄存器 ----
  reg  [5:0]   arrayReg;
  reg          reqReg;
  reg          allReg;
  reg          wenReg;
  reg  [7:0]   beReg;
  reg  [12:0]  addrReg;
  reg  [103:0] dataInReg;
  reg          renReg;
  reg  [12:0]  addrRdReg;
  reg  [103:0] pipelineDataOutReg;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      arrayReg  <= 6'h0;
      reqReg    <= 1'h0;
      allReg    <= 1'h0;
      wenReg    <= 1'h0;
      beReg     <= 8'h0;
      addrReg   <= 13'h0;
      dataInReg <= 104'h0;
      renReg    <= 1'h0;
      addrRdReg <= 13'h0;
    end
    else begin
      if (activated) begin
        arrayReg <= mbist_array;
        allReg   <= mbist_all;
        wenReg   <= mbist_writeen;
        renReg   <= mbist_readen;
      end
      reqReg <= mbist_req;
      if (activated & (mbist_readen | mbist_writeen)) begin
        beReg     <= mbist_be;
        addrReg   <= mbist_addr;
        dataInReg <= mbist_indata;
        addrRdReg <= mbist_addr_rd;
      end
    end
  end

  // ---- bank(pipeline)选择区间 ----
  wire selected   = (arrayReg == 6'h0) | (arrayReg == 6'h1);
  wire selected_1 = (arrayReg >= 6'h02) & (arrayReg <= 6'h10);
  wire selected_2 = (arrayReg >= 6'h11) & (arrayReg <= 6'h1F);
  wire selected_3 = (arrayReg >= 6'h20) & (arrayReg <= 6'h2E);
  wire selected_4 = (arrayReg >= 6'h2F) & (arrayReg <= 6'h3D);
  wire doSpread   = selected   | allReg;
  wire doSpread_1 = selected_1 | allReg;
  wire doSpread_2 = selected_2 | allReg;
  wire doSpread_3 = selected_3 | allReg;
  wire doSpread_4 = selected_4 | allReg;

  // ---- 读回合并(activated 时更新, 无 reset) ----
  always @(posedge clock) begin
    if (activated)
      pipelineDataOutReg <=
          {91'h0, (selected ? toNextPipeline_0_outdata : 13'h0)}
        | (selected_1 ? toNextPipeline_1_outdata : 104'h0)
        | (selected_2 ? toNextPipeline_2_outdata : 104'h0)
        | (selected_3 ? toNextPipeline_3_outdata : 104'h0)
        | (selected_4 ? toNextPipeline_4_outdata : 104'h0);
  end

  // ---- 输出 ----
  assign mbist_ack =
    reqReg & (toNextPipeline_0_ack | toNextPipeline_1_ack | toNextPipeline_2_ack
              | toNextPipeline_3_ack | toNextPipeline_4_ack);
  assign mbist_outdata = pipelineDataOutReg;

  // pipeline0: array 1 位 = doSpread & arrayReg[0]; addr 9 位; be 1 位
  assign toNextPipeline_0_array    = doSpread & arrayReg[0];
  assign toNextPipeline_0_all      = doSpread & allReg;
  assign toNextPipeline_0_req      = reqReg;
  assign toNextPipeline_0_writeen  = doSpread & wenReg;
  assign toNextPipeline_0_be       = beReg[0];
  assign toNextPipeline_0_addr     = doSpread ? addrReg[8:0] : 9'h0;
  assign toNextPipeline_0_indata   = dataInReg[12:0];
  assign toNextPipeline_0_readen   = doSpread & renReg;
  assign toNextPipeline_0_addr_rd  = doSpread ? addrRdReg[8:0] : 9'h0;

  // pipeline1: array 5 位
  assign toNextPipeline_1_array    = doSpread_1 ? arrayReg[4:0] : 5'h0;
  assign toNextPipeline_1_all      = doSpread_1 & allReg;
  assign toNextPipeline_1_req      = reqReg;
  assign toNextPipeline_1_writeen  = doSpread_1 & wenReg;
  assign toNextPipeline_1_be       = beReg;
  assign toNextPipeline_1_addr     = doSpread_1 ? addrReg : 13'h0;
  assign toNextPipeline_1_indata   = dataInReg;
  assign toNextPipeline_1_readen   = doSpread_1 & renReg;
  assign toNextPipeline_1_addr_rd  = doSpread_1 ? addrRdReg : 13'h0;

  // pipeline2: array 5 位
  assign toNextPipeline_2_array    = doSpread_2 ? arrayReg[4:0] : 5'h0;
  assign toNextPipeline_2_all      = doSpread_2 & allReg;
  assign toNextPipeline_2_req      = reqReg;
  assign toNextPipeline_2_writeen  = doSpread_2 & wenReg;
  assign toNextPipeline_2_be       = beReg;
  assign toNextPipeline_2_addr     = doSpread_2 ? addrReg : 13'h0;
  assign toNextPipeline_2_indata   = dataInReg;
  assign toNextPipeline_2_readen   = doSpread_2 & renReg;
  assign toNextPipeline_2_addr_rd  = doSpread_2 ? addrRdReg : 13'h0;

  // pipeline3: array 6 位
  assign toNextPipeline_3_array    = doSpread_3 ? arrayReg : 6'h0;
  assign toNextPipeline_3_all      = doSpread_3 & allReg;
  assign toNextPipeline_3_req      = reqReg;
  assign toNextPipeline_3_writeen  = doSpread_3 & wenReg;
  assign toNextPipeline_3_be       = beReg;
  assign toNextPipeline_3_addr     = doSpread_3 ? addrReg : 13'h0;
  assign toNextPipeline_3_indata   = dataInReg;
  assign toNextPipeline_3_readen   = doSpread_3 & renReg;
  assign toNextPipeline_3_addr_rd  = doSpread_3 ? addrRdReg : 13'h0;

  // pipeline4: array 6 位
  assign toNextPipeline_4_array    = doSpread_4 ? arrayReg : 6'h0;
  assign toNextPipeline_4_all      = doSpread_4 & allReg;
  assign toNextPipeline_4_req      = reqReg;
  assign toNextPipeline_4_writeen  = doSpread_4 & wenReg;
  assign toNextPipeline_4_be       = beReg;
  assign toNextPipeline_4_addr     = doSpread_4 ? addrReg : 13'h0;
  assign toNextPipeline_4_indata   = dataInReg;
  assign toNextPipeline_4_readen   = doSpread_4 & renReg;
  assign toNextPipeline_4_addr_rd  = doSpread_4 ? addrRdReg : 13'h0;

endmodule
