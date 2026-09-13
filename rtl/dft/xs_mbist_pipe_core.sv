// xs_mbist_pipe_core.sv —— MBIST 分发树的**唯一**流水节点核（整个 MbistPipe* 家族共用）
//
// ============================================================================
//  一、MBIST 分发树在芯片里干什么
// ----------------------------------------------------------------------------
//  MBIST = Memory Built-In Self Test，内存自测试。流片后 SRAM 是芯片上最容易出
//  制造缺陷的部分，而 SRAM 阵列被埋在流水线深处，从芯片引脚根本走不到。于是 DFT
//  在每个 SRAM 旁边留一组"测试口"，再用一棵**分发树**把芯片边界上唯一的一条 MBIST
//  总线，一层层广播到几百个 SRAM 上去。
//
//  这棵树在香山里长这样（G1 实测，array 编号即下面的 MBIST array id）：
//
//      MbistIntf{Frontend,MemBlk,L2}      ← 树根，对接芯片级 MBIST 控制器
//              │
//      MbistPipeFrontend / MbistPipeMemBlk / L2Slice…   ← **中间节点**(node)
//              │      转发给下游 MbistPipe，不直接碰 SRAM
//              ├── MbistPipeIcacheTag      id 0x00..0x03
//              ├── MbistPipeIcacheDataWay0 id 0x04..0x0B
//              ├── …
//              └── MbistPipeIttage_4       id 0x52..0x53   ← **叶子节点**(leaf)
//                          │                                  直接驱动 SRAM 的 bore 口
//                       SRAM 阵列
//
//  一个 MbistPipeline 节点自己**不产生**测试图形，它只做三件事：
//    1. 把上游请求打一拍寄存（这就是名字里 "Pipe" 的由来——分发树可能跨半个芯片，
//       不打拍时序过不去）；
//    2. 按 array 编号把请求**铺开**(spread) 给命中的那个 child，其余 child 的
//       地址/读写使能钉零，免得误触发不该测的 SRAM；
//    3. 把 child 读回的数据**或归约**后送回上游。
//
// ============================================================================
//  二、array id 怎么编址
// ----------------------------------------------------------------------------
//  一棵子树内的每个 SRAM 端口分到一个连号的 array id。规则（G1 实测，24 个
//  MbistPipe* 全部满足，见 scripts/gen_mbist_pipe_family.py 的机器校验）：
//
//    * 每个 child 认领一段**连续**的 id 区间 [ID_LO, ID_LO+ID_CNT)；
//    * 同一节点的各 child 区间**首尾相接、无空洞、无重叠**，按 child 序号递增；
//    * 节点自己认领的就是这些区间的并集，也是一段连续区间；
//    * ★位宽是**算出来**的，不是取整的★：
//        ARRAY_W == $clog2(本节点最大 id + 1)
//      每个 child 往下发的 array 端口同理，按**该 child 自己**的最大 id 算：
//        CH_ARRAY_W[j] == $clog2(ID_LO[j]+ID_CNT[j]-1 + 1)
//      所以同一个节点里各 child 的 array 端口宽度会不一样（MbistPipeDCacheData
//      的 32 个 child 分别是 1/1/2/2/3/3/3/3/4×8/5×16 位）。这条是本家族最容易
//      写错的地方——firtool 按最小位宽生成，手写时想当然给一律 7 位就错了。
//
//  为什么每个 SRAM 都要挂一个：MBIST 控制器一次只能对一个 array 施加图形，靠
//  array id 选中；`all` 位是广播，用来同时对整棵子树做同一个操作（量产时省时间）。
//
// ============================================================================
//  三、bore 那套端口是什么
// ----------------------------------------------------------------------------
//  Chisel 侧用 `BoringUtils`（"钻孔"）把 SRAM 深处的测试口直接引到 MBIST 树上，
//  所以 golden 里 SRAM 一侧的端口名带 `bore`（如 boreChildrenBd_bore_array）。
//  节点这一侧对应的端口叫 `toSRAM_<j>_*`（叶子）或 `toNextPipeline_<j>_*`（中间
//  节点）。一根一根的含义：
//
//    array      选中哪个 array（下发的是**寄存后**的 arrayReg，不是当拍输入）
//    all        广播位
//    req / ack  请求 / 应答（本家族的 ack 就是 reqReg，纯计数握手，不会反压）
//    writeen    写使能        be        字节写选通（写掩码）
//    addr       写地址        indata    写数据
//    readen     读使能        addr_rd   读地址（双口 SRAM 读写地址分开）
//    outdata / rdata          读数据回程
//    selectedOH 叶子专有：告诉 SRAM 包装层"这次点到的是你的第几个 array"，
//               宽度 = 该 child 认领的 id 个数（见下）
//
// ============================================================================
//  四、本核实现的时序（与 G1 golden bug-for-bug 对齐）
// ----------------------------------------------------------------------------
//    activated = mbist_all | (mbist_req & (mbist_array ∈ 本节点 id 集合))
//    dataValid = activated & (mbist_readen | mbist_writeen)
//
//    异步复位寄存器组（golden: always @(posedge clock or posedge reset)）：
//      arrayReg/allReg/wenReg/renReg      仅 activated 时更新
//      reqReg                             **每拍**更新（RegNext，不看 activated）
//      beReg/addrReg/dataInReg/addrRdReg  仅 dataValid 时更新
//    注意 dataValid 用的是**当拍**的 mbist_readen/writeen，不是 renReg/wenReg。
//
//    每个 child j：
//      selected_j = (arrayReg ∈ [ID_LO[j], ID_LO[j]+ID_CNT[j]))
//      doSpread_j = selected_j | allReg
//      地址/使能只在 doSpread_j 时透传，否则钉 0；
//      wdata/wmask **不**门控（golden 直接透传 dataInReg/beReg，截宽即可）。
//
//    读数据回程：sramDataOut_j = selected_j ? zext(child_rdata_j) : 0，
//                再把所有 child **或**起来。叶子是组合直出，中间节点要再过一级
//                pipelineDataOutReg（**无复位**、写使能 = activated）。
//
//    叶子的 selectedOH（宽 ID_CNT[j]）：
//      {W{allReg}} | (reqReg ? one_hot(arrayReg - ID_LO[j]) : {W{1'b1}})
//    ——广播或空闲时全 1，正常请求时按命中位置给 one-hot。
//
//  IS_NODE 是叶子/中间节点的唯一开关，两者只差 5 处：
//    ①child array 端口是否受 doSpread 门控（叶子不门控）②mbist_ack 是否与
//    child ack 相与 ③读数据是否再打一拍 ④selectedOH 只有叶子有 ⑤all 只有
//    中间节点往下发。
// ============================================================================

module xs_mbist_pipe_core #(
  // 叶子(0) / 中间节点(1)
  parameter bit          IS_NODE = 1'b0,
  parameter int unsigned N_CHILD = 1,
  // 上游总线位宽
  parameter int unsigned ARRAY_W = 7,
  parameter int unsigned BE_W    = 1,
  parameter int unsigned ADDR_W  = 8,
  parameter int unsigned DATA_W  = 76,
  // 每个 child 认领的 id 区间 [ID_LO, ID_LO+ID_CNT)
  parameter int unsigned ID_LO  [N_CHILD] = '{default: 0},
  parameter int unsigned ID_CNT [N_CHILD] = '{default: 1},
  // selectedOH 的最大宽度 = max(ID_CNT)；各 child 只用低 ID_CNT[j] 位
  parameter int unsigned MAX_IDS = 1
)(
  input  logic                clock,
  input  logic                reset,

  // ---- 上游 MBIST 总线 ----
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

  // ---- 下游各 child（统一按上游最大位宽给，由各变体薄文件截到 child 实宽）----
  output logic [ARRAY_W-1:0]  ch_array      [N_CHILD],
  output logic                ch_all        [N_CHILD],  // 仅 IS_NODE
  output logic                ch_reqpulse   [N_CHILD],  // 叶子接 ack，节点接 req
  output logic                ch_writeen    [N_CHILD],
  output logic [BE_W-1:0]     ch_wmask      [N_CHILD],
  output logic [ADDR_W-1:0]   ch_addr       [N_CHILD],
  output logic [DATA_W-1:0]   ch_wdata      [N_CHILD],
  output logic                ch_readen     [N_CHILD],
  output logic [ADDR_W-1:0]   ch_addr_rd    [N_CHILD],
  output logic [MAX_IDS-1:0]  ch_selectedOH [N_CHILD],  // 仅 !IS_NODE
  input  logic [DATA_W-1:0]   ch_rdata      [N_CHILD],  // 薄文件已零扩展到 DATA_W
  input  logic                ch_ack        [N_CHILD]   // 仅 IS_NODE
);

  // --------------------------------------------------------------------------
  // 参数自检（**elaborate 期**，不是 time-0）：下面每条等式都是从 G1 golden 机器
  // 提取出来的家族不变量（见文件头 §二，判据由 scripts/gen_mbist_pipe_family.py
  // 每次生成时对 24 个 golden 重新核一遍）。参数表写错就编不过，不用等 UT/FM。
  // 反面用例见 verif/ut/MbistPipe/neg/ —— 那里每条都有一个必失败的例子。
  // --------------------------------------------------------------------------
  function automatic int unsigned f_max_id();
    int unsigned m;
    m = 0;
    for (int unsigned j = 0; j < N_CHILD; j++)
      if (ID_LO[j] + ID_CNT[j] - 1 > m) m = ID_LO[j] + ID_CNT[j] - 1;
    return m;
  endfunction
  function automatic int unsigned f_max_cnt();
    int unsigned m;
    m = 0;
    for (int unsigned j = 0; j < N_CHILD; j++)
      if (ID_CNT[j] > m) m = ID_CNT[j];
    return m;
  endfunction
  // 首尾相接性：返回第一个不接续的 child 序号，全部接续时返回 N_CHILD
  function automatic int unsigned f_first_gap();
    int unsigned nxt;
    nxt = ID_LO[0];
    for (int unsigned j = 0; j < N_CHILD; j++) begin
      if (ID_LO[j] != nxt) return j;
      nxt = ID_LO[j] + ID_CNT[j];
    end
    return N_CHILD;
  endfunction
  function automatic int unsigned f_first_empty();
    for (int unsigned j = 0; j < N_CHILD; j++)
      if (ID_CNT[j] == 0) return j;
    return N_CHILD;
  endfunction

  localparam int unsigned MAX_ID      = f_max_id();
  localparam int unsigned MAX_CNT     = f_max_cnt();
  localparam int unsigned FIRST_GAP   = f_first_gap();
  localparam int unsigned FIRST_EMPTY = f_first_empty();

  if (FIRST_EMPTY != N_CHILD)
    $fatal(1, "xs_mbist_pipe_core: child %0d 的 ID_CNT 为 0 —— 每个 child 至少要负责一个 array id",
           FIRST_EMPTY);
  if (FIRST_GAP != N_CHILD)
    $fatal(1, "xs_mbist_pipe_core: child %0d 的 ID_LO=0x%0h 与前序 child 不接续 —— 同一节点的 id 区间必须首尾相接、无空洞无重叠",
           FIRST_GAP, ID_LO[FIRST_GAP]);
  if (ARRAY_W != $clog2(MAX_ID + 1))
    $fatal(1, "xs_mbist_pipe_core: ARRAY_W=%0d，但最大 array id=0x%0h 要求 $clog2(0x%0h)=%0d —— golden 按最小位数生成，array 位数是由最大 id 求得的，不是拍脑袋写的",
           ARRAY_W, MAX_ID, MAX_ID + 1, $clog2(MAX_ID + 1));
  if (MAX_IDS != MAX_CNT)
    $fatal(1, "xs_mbist_pipe_core: MAX_IDS=%0d，但各 child 的 ID_CNT 最大值是 %0d —— selectedOH 位数 = 该 child 负责的 id 个数",
           MAX_IDS, MAX_CNT);
  if (DATA_W == 0 || ADDR_W == 0 || BE_W == 0)
    $fatal(1, "xs_mbist_pipe_core: DATA_W/ADDR_W/BE_W 不能为 0");

  // --------------------------------------------------------------------------
  // 输入寄存级
  // --------------------------------------------------------------------------
  logic                arrayHit;     // 本节点认领这个 array 编号吗
  logic                activated;    // 本拍吃下这个请求吗
  logic                dataValid;    // 本拍要锁存地址/数据吗

  logic [ARRAY_W-1:0]  arrayReg;
  logic                reqReg, allReg, wenReg, renReg;
  logic [BE_W-1:0]     beReg;
  logic [ADDR_W-1:0]   addrReg, addrRdReg;
  logic [DATA_W-1:0]   dataInReg;

  // 区间比较一律在 int 域做：ID_LO+ID_CNT 可能正好等于 2**ARRAY_W（例如
  // MbistPipeIcacheTag 的 id 0..3、ARRAY_W=2，上界 4），截成 ARRAY_W 位会回绕成 0，
  // 比较就恒假。这类"位宽刚好用满"的边界是本家族的常态，必须用更宽的域比。
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
      arrayReg  <= '0;
      reqReg    <= 1'b0;
      allReg    <= 1'b0;
      wenReg    <= 1'b0;
      renReg    <= 1'b0;
      beReg     <= '0;
      addrReg   <= '0;
      dataInReg <= '0;
      addrRdReg <= '0;
    end else begin
      if (activated) begin
        arrayReg <= mbist_array;
        allReg   <= mbist_all;
        wenReg   <= mbist_writeen;
        renReg   <= mbist_readen;
      end
      reqReg <= mbist_req;                  // 每拍都更新，与 activated 无关
      if (dataValid) begin
        beReg     <= mbist_be;
        addrReg   <= mbist_addr;
        dataInReg <= mbist_indata;
        addrRdReg <= mbist_addr_rd;
      end
    end
  end

  // --------------------------------------------------------------------------
  // 按 array 编号把请求铺开给命中的 child
  // --------------------------------------------------------------------------
  logic              selected [N_CHILD];
  logic              doSpread [N_CHILD];
  logic [DATA_W-1:0] childDataOut [N_CHILD];

  for (genvar j = 0; j < int'(N_CHILD); j++) begin : g_child
    localparam int unsigned LO  = ID_LO[j];
    localparam int unsigned CNT = ID_CNT[j];

    assign selected[j] = (int'(arrayReg) >= int'(LO)) && (int'(arrayReg) < int'(LO + CNT));
    assign doSpread[j] = selected[j] | allReg;

    // 读数据回程：没被选中的 child 贡献 0，上游再或起来
    assign childDataOut[j] = selected[j] ? ch_rdata[j] : '0;

    // 中间节点的 array 端口受 doSpread 门控，叶子的不受（golden 如此）
    assign ch_array[j]    = IS_NODE ? (doSpread[j] ? arrayReg : '0) : arrayReg;
    assign ch_all[j]      = doSpread[j] & allReg;   // 仅中间节点接出去
    assign ch_reqpulse[j] = reqReg;
    assign ch_writeen[j]  = doSpread[j] & wenReg;
    assign ch_readen[j]   = doSpread[j] & renReg;
    assign ch_addr[j]     = doSpread[j] ? addrReg   : '0;
    assign ch_addr_rd[j]  = doSpread[j] ? addrRdReg : '0;
    assign ch_wdata[j]    = dataInReg;   // 不门控，薄文件按 child 宽度截断
    assign ch_wmask[j]    = beReg;       // 同上

    // selectedOH（叶子专有）：广播或空闲时全 1，正常请求时给命中位置的 one-hot。
    // 薄文件只取低 ID_CNT[j] 位——那就是 golden 该端口的实宽。
    if (!IS_NODE) begin : g_selected_oh
      logic [MAX_IDS-1:0] oneHot;
      always_comb begin
        oneHot = '0;
        for (int unsigned k = 0; k < CNT; k++)
          if (int'(arrayReg) == int'(LO + k)) oneHot[k] = 1'b1;
      end
      assign ch_selectedOH[j] = {MAX_IDS{allReg}} | (reqReg ? oneHot : {MAX_IDS{1'b1}});
    end else begin : g_no_selected_oh
      assign ch_selectedOH[j] = '0;   // 中间节点没有这根线
    end
  end

  // --------------------------------------------------------------------------
  // 上游回程
  // --------------------------------------------------------------------------
  logic [DATA_W-1:0] dataOutReduced;

  always_comb begin
    dataOutReduced = '0;
    for (int unsigned j = 0; j < N_CHILD; j++)
      dataOutReduced |= childDataOut[j];
  end

  if (IS_NODE) begin : g_node_return
    // 中间节点：ack 要与下游 ack 相与；读数据再过一级寄存器——**无复位**，
    // 写使能 = activated（golden 就是 always @(posedge clock) if (activated)，
    // 没有 reset 分支，上电值是 X，这点照搬）。
    logic              anyChildAck;
    logic [DATA_W-1:0] pipelineDataOutReg;
    always_comb begin
      anyChildAck = 1'b0;
      for (int unsigned j = 0; j < N_CHILD; j++) anyChildAck |= ch_ack[j];
    end
    always_ff @(posedge clock)
      if (activated) pipelineDataOutReg <= dataOutReduced;
    assign mbist_ack     = reqReg & anyChildAck;
    assign mbist_outdata = pipelineDataOutReg;
  end else begin : g_leaf_return
    // 叶子：ack 就是 reqReg，读数据组合直出（没有 pipelineDataOutReg 这一级）
    assign mbist_ack     = reqReg;
    assign mbist_outdata = dataOutReduced;
  end

endmodule
