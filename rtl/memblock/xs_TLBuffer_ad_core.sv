// =============================================================================
// xs_TLBuffer_ad_core —— TileLink A/D 两通道时序缓冲（TLBuffer 家族的参数化核）
//
// 位置：SoC 互联上任意两级之间的"打拍站"。Diplomacy 在 TL 主从之间插 TLBuffer，
//       目的只有一个：把上一级的 ready/valid 组合路径切断，代价是一拍延迟。
// 机制：A（client -> manager 请求）与 D（manager -> client 应答）各串一个 2 拍
//       skid FIFO（golden 里是 Queue2_TLBundleA_<n> / Queue2_TLBundleD_<n>）。
//       本层不解码 opcode/param、不跨通道重排、不做任何流控决策——事务进什么样
//       出来就什么样，单通道严格保序。因此本核**没有状态**，连 clock/reset 都
//       不需要：全部时序在两个队列里，clock/reset 由变体薄文件直接接到队列上。
//
// 为什么要有这个核：TLBuffer 在 G1 里有一堆变体，彼此只差**位宽**与**队列型号**。
//       G0->G1 这一轮改的正是位宽（TL source id 加宽），而位宽差异在"去掉端口后
//       比较模块体"的机械判据下是**隐形**的。把所有位宽收进参数、再用载荷宽度
//       等式（见下）自检，就把"位宽写错但逻辑没错"这类静默错误变成 elaborate 报错。
//
// 载荷宽度自检：golden 的 Queue2 内部存储是行为模型 ram_2x<N>，N = 该通道全部
//       payload 位之和（不含 valid/ready）。变体把自己的 ram_2x<N> 的 N 作为
//       A_RAM_WIDTH / D_RAM_WIDTH 传进来，本核校验其等于各字段位宽之和。
//       source 少写 2 位 → 等式不成立 → 直接 $fatal，测不到也漏不过去。
//
// 端口命名：TL 侧沿用 golden 的 auto_* 扁平名（Formality 直接匹配）；
//       队列侧用 a_q_* / d_q_*，由变体薄文件接到具体型号的 Queue2 黑盒上。
// 不经过本核的字段：A 通道的 user（reqSource / memPageType_NC / memBackType_MM）
//       是随变体而异的不透明附带位，缓冲不解释它，由变体薄文件直接从端口接到
//       队列上；本核只在宽度等式里按 A_USER_W 计入它的位数。
// =============================================================================
module xs_TLBuffer_ad_core #(
  // ---- 随变体而异的位宽（G0->G1 改的就是 SOURCE_W）----
  parameter int unsigned A_SIZE_W   = 3,    // A 通道 size 位宽（log2 突发字节数的位数）
  parameter int unsigned D_SIZE_W   = 3,    // D 通道 size 位宽
  parameter int unsigned SOURCE_W   = 4,    // A/D 共用的 source id 位宽（TL 事务标签）
  parameter int unsigned ADDR_W     = 48,   // A 通道地址位宽
  parameter int unsigned MASK_W     = 32,   // A 通道字节写掩码位宽 = DATA_W/8
  parameter int unsigned DATA_W     = 256,  // A/D 共用的数据位宽
  parameter int unsigned D_SINK_W   = 10,   // D 通道 sink id 位宽（TL-C 才用得上）
  parameter int unsigned A_USER_W   = 5,    // A 通道 user 附带位总位数（0 = 本变体没有 user）
  // ---- golden Queue2 内 ram_2x<N> 的 N，仅用于载荷宽度自检 ----
  parameter int unsigned A_RAM_WIDTH = 356,
  parameter int unsigned D_RAM_WIDTH = 281,
  // ---- TL 规范固定、5 个变体完全一致的位宽 ----
  localparam int unsigned A_OPCODE_W = 4,
  localparam int unsigned A_PARAM_W  = 3,
  localparam int unsigned D_OPCODE_W = 4,
  localparam int unsigned D_PARAM_W  = 2,
  // ---- 载荷宽度等式：必须与 golden 队列的 ram 宽度逐位相等 ----
  localparam int unsigned A_PAYLOAD_W = A_OPCODE_W + A_PARAM_W + A_SIZE_W + SOURCE_W
                                      + ADDR_W + A_USER_W + MASK_W + DATA_W + 1,
  localparam int unsigned D_PAYLOAD_W = D_OPCODE_W + D_PARAM_W + D_SIZE_W + SOURCE_W
                                      + D_SINK_W + 1 + DATA_W + 1
)(
  // ===========================================================================
  // TL 侧（golden 扁平端口）
  // ===========================================================================
  // A：client 来的请求
  output logic                 auto_in_a_ready,
  input  logic                 auto_in_a_valid,
  input  logic [A_OPCODE_W-1:0] auto_in_a_bits_opcode,
  input  logic [A_PARAM_W-1:0] auto_in_a_bits_param,
  input  logic [A_SIZE_W-1:0]  auto_in_a_bits_size,
  input  logic [SOURCE_W-1:0]  auto_in_a_bits_source,
  input  logic [ADDR_W-1:0]    auto_in_a_bits_address,
  input  logic [MASK_W-1:0]    auto_in_a_bits_mask,
  input  logic [DATA_W-1:0]    auto_in_a_bits_data,
  input  logic                 auto_in_a_bits_corrupt,
  // A：送给 manager 的请求
  input  logic                 auto_out_a_ready,
  output logic                 auto_out_a_valid,
  output logic [A_OPCODE_W-1:0] auto_out_a_bits_opcode,
  output logic [A_PARAM_W-1:0] auto_out_a_bits_param,
  output logic [A_SIZE_W-1:0]  auto_out_a_bits_size,
  output logic [SOURCE_W-1:0]  auto_out_a_bits_source,
  output logic [ADDR_W-1:0]    auto_out_a_bits_address,
  output logic [MASK_W-1:0]    auto_out_a_bits_mask,
  output logic [DATA_W-1:0]    auto_out_a_bits_data,
  output logic                 auto_out_a_bits_corrupt,
  // D：manager 来的应答
  output logic                 auto_out_d_ready,
  input  logic                 auto_out_d_valid,
  input  logic [D_OPCODE_W-1:0] auto_out_d_bits_opcode,
  input  logic [D_PARAM_W-1:0] auto_out_d_bits_param,
  input  logic [D_SIZE_W-1:0]  auto_out_d_bits_size,
  input  logic [SOURCE_W-1:0]  auto_out_d_bits_source,
  input  logic [D_SINK_W-1:0]  auto_out_d_bits_sink,
  input  logic                 auto_out_d_bits_denied,
  input  logic [DATA_W-1:0]    auto_out_d_bits_data,
  input  logic                 auto_out_d_bits_corrupt,
  // D：还给 client 的应答
  input  logic                 auto_in_d_ready,
  output logic                 auto_in_d_valid,
  output logic [D_OPCODE_W-1:0] auto_in_d_bits_opcode,
  output logic [D_PARAM_W-1:0] auto_in_d_bits_param,
  output logic [D_SIZE_W-1:0]  auto_in_d_bits_size,
  output logic [SOURCE_W-1:0]  auto_in_d_bits_source,
  output logic [D_SINK_W-1:0]  auto_in_d_bits_sink,
  output logic                 auto_in_d_bits_denied,
  output logic [DATA_W-1:0]    auto_in_d_bits_data,
  output logic                 auto_in_d_bits_corrupt,

  // ===========================================================================
  // 队列侧（变体薄文件把这里接到 Queue2_TLBundleA_<n> / Queue2_TLBundleD_<n>）
  // ===========================================================================
  // A 队列 enq（写入端，来自 client）
  output logic                 a_q_enq_valid,
  input  logic                 a_q_enq_ready,
  output logic [A_OPCODE_W-1:0] a_q_enq_opcode,
  output logic [A_PARAM_W-1:0] a_q_enq_param,
  output logic [A_SIZE_W-1:0]  a_q_enq_size,
  output logic [SOURCE_W-1:0]  a_q_enq_source,
  output logic [ADDR_W-1:0]    a_q_enq_address,
  output logic [MASK_W-1:0]    a_q_enq_mask,
  output logic [DATA_W-1:0]    a_q_enq_data,
  output logic                 a_q_enq_corrupt,
  // A 队列 deq（读出端，送往 manager）
  input  logic                 a_q_deq_valid,
  output logic                 a_q_deq_ready,
  input  logic [A_OPCODE_W-1:0] a_q_deq_opcode,
  input  logic [A_PARAM_W-1:0] a_q_deq_param,
  input  logic [A_SIZE_W-1:0]  a_q_deq_size,
  input  logic [SOURCE_W-1:0]  a_q_deq_source,
  input  logic [ADDR_W-1:0]    a_q_deq_address,
  input  logic [MASK_W-1:0]    a_q_deq_mask,
  input  logic [DATA_W-1:0]    a_q_deq_data,
  input  logic                 a_q_deq_corrupt,
  // D 队列 enq（写入端，来自 manager）
  output logic                 d_q_enq_valid,
  input  logic                 d_q_enq_ready,
  output logic [D_OPCODE_W-1:0] d_q_enq_opcode,
  output logic [D_PARAM_W-1:0] d_q_enq_param,
  output logic [D_SIZE_W-1:0]  d_q_enq_size,
  output logic [SOURCE_W-1:0]  d_q_enq_source,
  output logic [D_SINK_W-1:0]  d_q_enq_sink,
  output logic                 d_q_enq_denied,
  output logic [DATA_W-1:0]    d_q_enq_data,
  output logic                 d_q_enq_corrupt,
  // D 队列 deq（读出端，送往 client）
  input  logic                 d_q_deq_valid,
  output logic                 d_q_deq_ready,
  input  logic [D_OPCODE_W-1:0] d_q_deq_opcode,
  input  logic [D_PARAM_W-1:0] d_q_deq_param,
  input  logic [D_SIZE_W-1:0]  d_q_deq_size,
  input  logic [SOURCE_W-1:0]  d_q_deq_source,
  input  logic [D_SINK_W-1:0]  d_q_deq_sink,
  input  logic                 d_q_deq_denied,
  input  logic [DATA_W-1:0]    d_q_deq_data,
  input  logic                 d_q_deq_corrupt
);

  // ---------------------------------------------------------------------------
  // 位宽自检：本核参数拼出来的载荷宽度，必须等于 golden 队列里 ram_2x<N> 的 N。
  // 这是 G0->G1 这一轮唯一的实质改动（source 加宽）的防呆闸：把 SOURCE_W 留在
  // 旧值上，逻辑一行都不会错、随机激励也未必打得到高位，但这里会立刻 $fatal。
  // ---------------------------------------------------------------------------
  initial begin
    if (A_PAYLOAD_W != A_RAM_WIDTH)
      $fatal(1, "xs_TLBuffer_ad_core: A 通道载荷 %0d 位 != golden ram_2x%0d（位宽参数写错了）",
             A_PAYLOAD_W, A_RAM_WIDTH);
    if (D_PAYLOAD_W != D_RAM_WIDTH)
      $fatal(1, "xs_TLBuffer_ad_core: D 通道载荷 %0d 位 != golden ram_2x%0d（位宽参数写错了）",
             D_PAYLOAD_W, D_RAM_WIDTH);
    if (MASK_W * 8 != DATA_W)
      $fatal(1, "xs_TLBuffer_ad_core: MASK_W=%0d 与 DATA_W=%0d 不是字节掩码关系",
             MASK_W, DATA_W);
  end

  // ---------------------------------------------------------------------------
  // A 通道：client -> [2 拍 skid FIFO] -> manager
  //   缓冲对事务内容零改动，只把背压沿队列向上游传（enq.ready 来自队列）。
  // ---------------------------------------------------------------------------
  assign a_q_enq_valid          = auto_in_a_valid;
  assign auto_in_a_ready        = a_q_enq_ready;
  assign a_q_enq_opcode         = auto_in_a_bits_opcode;
  assign a_q_enq_param          = auto_in_a_bits_param;
  assign a_q_enq_size           = auto_in_a_bits_size;
  assign a_q_enq_source         = auto_in_a_bits_source;
  assign a_q_enq_address        = auto_in_a_bits_address;
  assign a_q_enq_mask           = auto_in_a_bits_mask;
  assign a_q_enq_data           = auto_in_a_bits_data;
  assign a_q_enq_corrupt        = auto_in_a_bits_corrupt;

  assign auto_out_a_valid       = a_q_deq_valid;
  assign a_q_deq_ready          = auto_out_a_ready;
  assign auto_out_a_bits_opcode  = a_q_deq_opcode;
  assign auto_out_a_bits_param   = a_q_deq_param;
  assign auto_out_a_bits_size    = a_q_deq_size;
  assign auto_out_a_bits_source  = a_q_deq_source;
  assign auto_out_a_bits_address = a_q_deq_address;
  assign auto_out_a_bits_mask    = a_q_deq_mask;
  assign auto_out_a_bits_data    = a_q_deq_data;
  assign auto_out_a_bits_corrupt = a_q_deq_corrupt;

  // ---------------------------------------------------------------------------
  // D 通道：manager -> [2 拍 skid FIFO] -> client（方向与 A 相反，队列摆在 in 侧）
  // ---------------------------------------------------------------------------
  assign d_q_enq_valid          = auto_out_d_valid;
  assign auto_out_d_ready       = d_q_enq_ready;
  assign d_q_enq_opcode         = auto_out_d_bits_opcode;
  assign d_q_enq_param          = auto_out_d_bits_param;
  assign d_q_enq_size           = auto_out_d_bits_size;
  assign d_q_enq_source         = auto_out_d_bits_source;
  assign d_q_enq_sink           = auto_out_d_bits_sink;
  assign d_q_enq_denied         = auto_out_d_bits_denied;
  assign d_q_enq_data           = auto_out_d_bits_data;
  assign d_q_enq_corrupt        = auto_out_d_bits_corrupt;

  assign auto_in_d_valid        = d_q_deq_valid;
  assign d_q_deq_ready          = auto_in_d_ready;
  assign auto_in_d_bits_opcode  = d_q_deq_opcode;
  assign auto_in_d_bits_param   = d_q_deq_param;
  assign auto_in_d_bits_size    = d_q_deq_size;
  assign auto_in_d_bits_source  = d_q_deq_source;
  assign auto_in_d_bits_sink    = d_q_deq_sink;
  assign auto_in_d_bits_denied  = d_q_deq_denied;
  assign auto_in_d_bits_data    = d_q_deq_data;
  assign auto_in_d_bits_corrupt = d_q_deq_corrupt;

endmodule
