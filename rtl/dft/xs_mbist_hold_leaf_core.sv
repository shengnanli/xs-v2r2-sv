// xs_mbist_hold_leaf_core.sv —— MBIST 分发树的 **extraHold 叶子**节点核（L2DataStorage* 用）
//
// 与 rtl/dft/xs_mbist_pipe_core.sv（MbistPipe* 家族 + L2Slice*）是同一个 Chisel 模块
// utility.mbist.MbistPipeline 的另一种单态化：它下面挂的 SRAM 声明了 extraHold=true
// （L2 数据阵列 sram_array_1p4096x137m137s1h**1**l**2**b —— 多周期 SRAM，读写要保持 2 拍）。
// 分发树是什么、array id 怎么编址、bore 口每根线的意思，全部讲在 xs_mbist_pipe_core.sv 文件头，
// 这里只写和它**不同**的地方：
//
//   1. 读/写使能不再是"activated 时锁存一次"的 renReg/wenReg，而是 2 位展宽寄存器：
//        activated & readen  -> renStretched <= 2'b11
//        否则只要还非 0     -> renStretched <= renStretched >> 1
//      送给 SRAM 的 re/we 用展宽寄存器的最低位，所以一次请求让 re/we 维持 2 拍。
//      （golden 里因此**没有** wenReg/renReg 这两个寄存器 —— 这里也不许有，否则多出比较点。）
//   2. 只有叶子形态（直接驱动 SRAM 的 toSRAM_<j> 口），没有中间节点形态。
//   其余（输入寄存级、按 id 区间铺开、selectedOH、读数据组合或归约、ack=reqReg）与叶子完全相同。

module xs_mbist_hold_leaf_core #(
  parameter int unsigned N_CHILD = 1,
  parameter int unsigned ARRAY_W = 4,
  parameter int unsigned BE_W    = 1,
  parameter int unsigned ADDR_W  = 13,
  parameter int unsigned DATA_W  = 137,
  parameter int unsigned ID_LO  [N_CHILD] = '{default: 0},
  parameter int unsigned ID_CNT [N_CHILD] = '{default: 1},
  parameter int unsigned MAX_IDS = 1
)(
  input  logic                clock,
  input  logic                reset,

  input  logic [ARRAY_W-1:0]  mbist_array,
  input  logic                mbist_all,
  input  logic                mbist_req,
  output logic                mbist_ack,
  input  logic                mbist_writeen,
  input  logic [BE_W-1:0]     mbist_be,
  input  logic [ADDR_W-1:0]   mbist_addr,
  input  logic [DATA_W-1:0]   mbist_indata,
  input  logic                mbist_readen,
  input  logic [ADDR_W-1:0]   mbist_addr_rd,
  output logic [DATA_W-1:0]   mbist_outdata,

  output logic [ARRAY_W-1:0]  ch_array      [N_CHILD],
  output logic                ch_ack        [N_CHILD],
  output logic                ch_writeen    [N_CHILD],
  output logic [BE_W-1:0]     ch_wmask      [N_CHILD],
  output logic [ADDR_W-1:0]   ch_addr       [N_CHILD],
  output logic [DATA_W-1:0]   ch_wdata      [N_CHILD],
  output logic                ch_readen     [N_CHILD],
  output logic [ADDR_W-1:0]   ch_addr_rd    [N_CHILD],
  output logic [MAX_IDS-1:0]  ch_selectedOH [N_CHILD],
  input  logic [DATA_W-1:0]   ch_rdata      [N_CHILD]
);

  localparam int unsigned HOLD_W = 2;   // 展宽拍数

  // --------------------------------------------------------------------------
  // 输入寄存级（除读写使能外与 xs_mbist_pipe_core 相同）
  // --------------------------------------------------------------------------
  logic                arrayHit, activated, dataValid;
  logic [ARRAY_W-1:0]  arrayReg;
  logic                reqReg, allReg;
  logic [BE_W-1:0]     beReg;
  logic [ADDR_W-1:0]   addrReg, addrRdReg;
  logic [DATA_W-1:0]   dataInReg;
  logic [HOLD_W-1:0]   wenStretched, renStretched;

  always_comb begin
    arrayHit = 1'b0;
    for (int unsigned j = 0; j < N_CHILD; j++)
      if (int'(mbist_array) >= int'(ID_LO[j]) &&
          int'(mbist_array) <  int'(ID_LO[j] + ID_CNT[j]))
        arrayHit = 1'b1;
  end

  assign activated = mbist_all | (mbist_req & arrayHit);
  assign dataValid = activated & (mbist_readen | mbist_writeen);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      arrayReg     <= '0;
      reqReg       <= 1'b0;
      allReg       <= 1'b0;
      beReg        <= '0;
      addrReg      <= '0;
      dataInReg    <= '0;
      addrRdReg    <= '0;
      wenStretched <= '0;
      renStretched <= '0;
    end else begin
      if (activated) begin
        arrayReg <= mbist_array;
        allReg   <= mbist_all;
      end
      reqReg <= mbist_req;
      if (dataValid) begin
        beReg     <= mbist_be;
        addrReg   <= mbist_addr;
        dataInReg <= mbist_indata;
        addrRdReg <= mbist_addr_rd;
      end
      // 读/写使能展宽：新请求置满，否则逐拍右移直到清零
      if (activated & mbist_writeen)
        wenStretched <= '1;
      else if (|wenStretched)
        wenStretched <= wenStretched >> 1;
      if (activated & mbist_readen)
        renStretched <= '1;
      else if (|renStretched)
        renStretched <= renStretched >> 1;
    end
  end

  // --------------------------------------------------------------------------
  // 按 array 编号铺开给各 SRAM child
  // --------------------------------------------------------------------------
  logic              selected     [N_CHILD];
  logic              doSpread     [N_CHILD];
  logic [DATA_W-1:0] childDataOut [N_CHILD];

  for (genvar j = 0; j < int'(N_CHILD); j++) begin : g_child
    localparam int unsigned LO  = ID_LO[j];
    localparam int unsigned CNT = ID_CNT[j];

    assign selected[j]     = (int'(arrayReg) >= int'(LO)) && (int'(arrayReg) < int'(LO + CNT));
    assign doSpread[j]     = selected[j] | allReg;
    assign childDataOut[j] = selected[j] ? ch_rdata[j] : '0;

    assign ch_array[j]   = arrayReg;                       // 叶子的 array 不门控
    assign ch_ack[j]     = reqReg;
    assign ch_writeen[j] = doSpread[j] & wenStretched[0];  // 展宽后的写使能
    assign ch_readen[j]  = doSpread[j] & renStretched[0];  // 展宽后的读使能
    assign ch_addr[j]    = doSpread[j] ? addrReg   : '0;
    assign ch_addr_rd[j] = doSpread[j] ? addrRdReg : '0;
    assign ch_wdata[j]   = dataInReg;
    assign ch_wmask[j]   = beReg;

    logic [MAX_IDS-1:0] oneHot;
    always_comb begin
      oneHot = '0;
      for (int unsigned k = 0; k < CNT; k++)
        if (int'(arrayReg) == int'(LO + k)) oneHot[k] = 1'b1;
    end
    assign ch_selectedOH[j] = {MAX_IDS{allReg}} | (reqReg ? oneHot : {MAX_IDS{1'b1}});
  end

  always_comb begin
    mbist_outdata = '0;
    for (int unsigned j = 0; j < N_CHILD; j++)
      mbist_outdata |= childDataOut[j];
  end
  assign mbist_ack = reqReg;

endmodule
