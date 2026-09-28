// =============================================================================
// TreeArbiter —— DCache 送 MissQueue 的 4 路 miss 请求仲裁器
//                 （xs_FixedPriorityArbiter_core 家族的一个变体，核未改）
//
// 位置：DCacheImp 的 missReqArb = TreeArbiter(new MissReq, MissReqPortCount=4)：
//   第 0 路 MainPipe  —— store/AMO 在主流水里 miss（带 AMO 操作数与整行 store 数据）
//   第 1..3 路 LoadPipe 0..2 —— load miss（只带地址与一致性信息）
//   （StorePipe 的 miss_req 在本配置下不接：StorePrefetchL1Enabled=false）
//   仲裁结果送 MissQueue.io.req；每一路的 ready 由本件给出（DCache 里再与
//   MissReadyGen 的逐口预算相与）。
//
// Scala 的写法是"二叉选择树"：selectTree 把 4 路对半分，左半有 valid 就取左半的
//   结果，否则取右半；每半里再"第一个 valid 就取它，否则取第二个"。
//   这棵树的结果恰好就是 lowest-index-wins：左半（下标小）永远优先，左半内部
//   下标小的优先；全都不 valid 时一路走"否则"分支落到最后一路（第 3 路）。
//   grant/ready 用的是 Chisel 标准 ArbiterCtrl（前缀或取反），与普通 Arbiter 相同。
//   ⇒ 语义与共享核 xs_FixedPriorityArbiter_core 逐位相同（含"无人请求时给末路载荷"），
//   这里直接复用核；"树"只是 Chisel 为时序选的实现形状（log 深度的 mux），不改变功能。
//
// ★载荷字段不齐，缺的字段填常量★（golden 端口表现读）：
//   第 0 路（MainPipe）没有 pf_source 端口 —— MainPipe 的 miss 不是预取，常量 0；
//   第 1..3 路（LoadPipe）没有 full_overwrite / word_idx / amo_* / id / store_* 端口
//   —— load miss 不带这些，常量 0。
//   这与 golden 的写法一致：golden 里这些输出是 "_GEN(第 0 路赢) ? 第 0 路字段 : 0"，
//   即其它路贡献 0；pf_source 是 "第 0 路赢 ? 0 : 其它路"。
//
// 规模：NUM_IN=4，WIDTH=976 位（MissReq 在 golden 输出端口上的 17 个字段）；
//   golden 端口 71 个（4×ready + 4×valid + out_ready + out_valid + 61 个 bits 端口）。
//   纯组合，无寄存器/子模块。io.chosen 在 golden 里无端口（Scala 注释也说"很慢别用"）。
// =============================================================================

module TreeArbiter(
  output         io_in_0_ready,
  input          io_in_0_valid,
  input  [3:0]   io_in_0_bits_source,
  input  [4:0]   io_in_0_bits_cmd,
  input  [47:0]  io_in_0_bits_addr,
  input  [49:0]  io_in_0_bits_vaddr,
  input          io_in_0_bits_full_overwrite,
  input  [2:0]   io_in_0_bits_word_idx,
  input  [127:0] io_in_0_bits_amo_data,
  input  [15:0]  io_in_0_bits_amo_mask,
  input  [127:0] io_in_0_bits_amo_cmp,
  input  [1:0]   io_in_0_bits_req_coh_state,
  input  [5:0]   io_in_0_bits_id,
  input          io_in_0_bits_isBtoT,
  input  [3:0]   io_in_0_bits_occupy_way,
  input          io_in_0_bits_cancel,
  input  [511:0] io_in_0_bits_store_data,
  input  [63:0]  io_in_0_bits_store_mask,
  output         io_in_1_ready,
  input          io_in_1_valid,
  input  [3:0]   io_in_1_bits_source,
  input  [2:0]   io_in_1_bits_pf_source,
  input  [4:0]   io_in_1_bits_cmd,
  input  [47:0]  io_in_1_bits_addr,
  input  [49:0]  io_in_1_bits_vaddr,
  input  [1:0]   io_in_1_bits_req_coh_state,
  input          io_in_1_bits_isBtoT,
  input  [3:0]   io_in_1_bits_occupy_way,
  input          io_in_1_bits_cancel,
  output         io_in_2_ready,
  input          io_in_2_valid,
  input  [3:0]   io_in_2_bits_source,
  input  [2:0]   io_in_2_bits_pf_source,
  input  [4:0]   io_in_2_bits_cmd,
  input  [47:0]  io_in_2_bits_addr,
  input  [49:0]  io_in_2_bits_vaddr,
  input  [1:0]   io_in_2_bits_req_coh_state,
  input          io_in_2_bits_isBtoT,
  input  [3:0]   io_in_2_bits_occupy_way,
  input          io_in_2_bits_cancel,
  output         io_in_3_ready,
  input          io_in_3_valid,
  input  [3:0]   io_in_3_bits_source,
  input  [2:0]   io_in_3_bits_pf_source,
  input  [4:0]   io_in_3_bits_cmd,
  input  [47:0]  io_in_3_bits_addr,
  input  [49:0]  io_in_3_bits_vaddr,
  input  [1:0]   io_in_3_bits_req_coh_state,
  input          io_in_3_bits_isBtoT,
  input  [3:0]   io_in_3_bits_occupy_way,
  input          io_in_3_bits_cancel,
  input          io_out_ready,
  output         io_out_valid,
  output [3:0]   io_out_bits_source,
  output [2:0]   io_out_bits_pf_source,
  output [4:0]   io_out_bits_cmd,
  output [47:0]  io_out_bits_addr,
  output [49:0]  io_out_bits_vaddr,
  output         io_out_bits_full_overwrite,
  output [2:0]   io_out_bits_word_idx,
  output [127:0] io_out_bits_amo_data,
  output [15:0]  io_out_bits_amo_mask,
  output [127:0] io_out_bits_amo_cmp,
  output [1:0]   io_out_bits_req_coh_state,
  output [5:0]   io_out_bits_id,
  output         io_out_bits_isBtoT,
  output [3:0]   io_out_bits_occupy_way,
  output         io_out_bits_cancel,
  output [511:0] io_out_bits_store_data,
  output [63:0]  io_out_bits_store_mask
);

  // MissReq 在仲裁器输出上保留下来的字段（顺序 = golden 输出端口顺序）
  typedef struct packed {
    logic [3:0]   source;          // 请求来源（load/store/amo/预取）
    logic [2:0]   pf_source;       // 预取来源编码（load 侧预取 miss 用）
    logic [4:0]   cmd;             // 内存命令 M_XRD/M_XWR/AMO...
    logic [47:0]  addr;            // 物理地址
    logic [49:0]  vaddr;           // 虚地址（MissQueue 取 set 下标/别名位）
    logic         full_overwrite;  // store 覆盖整行 → refill 不必等 L2 数据
    logic [2:0]   word_idx;        // AMO 作用的 64 位字
    logic [127:0] amo_data;        // AMO 操作数
    logic [15:0]  amo_mask;        // AMO 字节掩码
    logic [127:0] amo_cmp;         // AMOCAS 比较值
    logic [1:0]   req_coh_state;   // 请求时该行的一致性状态（决定 Acquire 的 grow 参数）
    logic [5:0]   id;              // 请求 id（MainPipe 回给 store/AMO）
    logic         isBtoT;          // Branch→Trunk 升权 miss
    logic [3:0]   occupy_way;      // 升权时占住的路
    logic         cancel;          // s2 被取消（MissQueue 据此撤销分配）
    logic [511:0] store_data;      // store 整行数据
    logic [63:0]  store_mask;      // store 字节掩码
  } miss_req_t;

  localparam int unsigned NUM_IN = 4;
  localparam int unsigned WIDTH  = $bits(miss_req_t);   // 976

  // golden 端口数恒等式：71 个端口 = 2*4 + 2 + 61 个 bits 端口
  localparam int unsigned GOLDEN_PORTS      = 71;
  localparam int unsigned GOLDEN_BITS_PORTS = 61;

  // ---- 第 0 路：MainPipe（没有 pf_source，填 0）----
  miss_req_t main_way;
  always_comb begin
    main_way                = '0;
    main_way.source         = io_in_0_bits_source;
    main_way.cmd            = io_in_0_bits_cmd;
    main_way.addr           = io_in_0_bits_addr;
    main_way.vaddr          = io_in_0_bits_vaddr;
    main_way.full_overwrite = io_in_0_bits_full_overwrite;
    main_way.word_idx       = io_in_0_bits_word_idx;
    main_way.amo_data       = io_in_0_bits_amo_data;
    main_way.amo_mask       = io_in_0_bits_amo_mask;
    main_way.amo_cmp        = io_in_0_bits_amo_cmp;
    main_way.req_coh_state  = io_in_0_bits_req_coh_state;
    main_way.id             = io_in_0_bits_id;
    main_way.isBtoT         = io_in_0_bits_isBtoT;
    main_way.occupy_way     = io_in_0_bits_occupy_way;
    main_way.cancel         = io_in_0_bits_cancel;
    main_way.store_data     = io_in_0_bits_store_data;
    main_way.store_mask     = io_in_0_bits_store_mask;
  end

  // ---- 第 1..3 路：LoadPipe 0..2（只带 load miss 的字段，其余填 0）----
  miss_req_t load_way [3];
  always_comb begin
    load_way[0]               = '0;
    load_way[0].source        = io_in_1_bits_source;
    load_way[0].pf_source     = io_in_1_bits_pf_source;
    load_way[0].cmd           = io_in_1_bits_cmd;
    load_way[0].addr          = io_in_1_bits_addr;
    load_way[0].vaddr         = io_in_1_bits_vaddr;
    load_way[0].req_coh_state = io_in_1_bits_req_coh_state;
    load_way[0].isBtoT        = io_in_1_bits_isBtoT;
    load_way[0].occupy_way    = io_in_1_bits_occupy_way;
    load_way[0].cancel        = io_in_1_bits_cancel;

    load_way[1]               = '0;
    load_way[1].source        = io_in_2_bits_source;
    load_way[1].pf_source     = io_in_2_bits_pf_source;
    load_way[1].cmd           = io_in_2_bits_cmd;
    load_way[1].addr          = io_in_2_bits_addr;
    load_way[1].vaddr         = io_in_2_bits_vaddr;
    load_way[1].req_coh_state = io_in_2_bits_req_coh_state;
    load_way[1].isBtoT        = io_in_2_bits_isBtoT;
    load_way[1].occupy_way    = io_in_2_bits_occupy_way;
    load_way[1].cancel        = io_in_2_bits_cancel;

    load_way[2]               = '0;
    load_way[2].source        = io_in_3_bits_source;
    load_way[2].pf_source     = io_in_3_bits_pf_source;
    load_way[2].cmd           = io_in_3_bits_cmd;
    load_way[2].addr          = io_in_3_bits_addr;
    load_way[2].vaddr         = io_in_3_bits_vaddr;
    load_way[2].req_coh_state = io_in_3_bits_req_coh_state;
    load_way[2].isBtoT        = io_in_3_bits_isBtoT;
    load_way[2].occupy_way    = io_in_3_bits_occupy_way;
    load_way[2].cancel        = io_in_3_bits_cancel;
  end

  // 核的约定：高位段 = 第 0 路（优先级最高）
  logic [NUM_IN*WIDTH-1:0] in_bits_flat;
  logic [NUM_IN-1:0]       in_valid_vec;
  logic [NUM_IN-1:0]       in_ready_vec;
  miss_req_t               out_req;

  assign in_bits_flat = {main_way, load_way[0], load_way[1], load_way[2]};
  assign in_valid_vec = {io_in_0_valid, io_in_1_valid, io_in_2_valid, io_in_3_valid};

  assign io_in_0_ready = in_ready_vec[3];
  assign io_in_1_ready = in_ready_vec[2];
  assign io_in_2_ready = in_ready_vec[1];
  assign io_in_3_ready = in_ready_vec[0];

  xs_FixedPriorityArbiter_core #(
    .WIDTH            (WIDTH),
    .NUM_IN           (NUM_IN),
    // 端口表事实：$bits 只认端口声明，输出端口位宽抄错这个常量立刻跟着变
    .PORT_BITS_OUT    ($bits({io_out_bits_source, io_out_bits_pf_source, io_out_bits_cmd,
                              io_out_bits_addr, io_out_bits_vaddr, io_out_bits_full_overwrite,
                              io_out_bits_word_idx, io_out_bits_amo_data, io_out_bits_amo_mask,
                              io_out_bits_amo_cmp, io_out_bits_req_coh_state, io_out_bits_id,
                              io_out_bits_isBtoT, io_out_bits_occupy_way, io_out_bits_cancel,
                              io_out_bits_store_data, io_out_bits_store_mask})),
    // 末路（LoadPipe 2）只有一部分字段有端口，其余填常量，按构造等于 WIDTH
    .PORT_BITS_LAST_IN($bits(load_way[2])),
    .GOLDEN_PORTS     (GOLDEN_PORTS),
    .GOLDEN_BITS_PORTS(GOLDEN_BITS_PORTS)
  ) u_core (
    .in_valid (in_valid_vec),
    .in_ready (in_ready_vec),
    .in_bits  (in_bits_flat),
    .out_ready(io_out_ready),
    .out_valid(io_out_valid),
    .out_bits (out_req)
  );

  assign io_out_bits_source         = out_req.source;
  assign io_out_bits_pf_source      = out_req.pf_source;
  assign io_out_bits_cmd            = out_req.cmd;
  assign io_out_bits_addr           = out_req.addr;
  assign io_out_bits_vaddr          = out_req.vaddr;
  assign io_out_bits_full_overwrite = out_req.full_overwrite;
  assign io_out_bits_word_idx       = out_req.word_idx;
  assign io_out_bits_amo_data       = out_req.amo_data;
  assign io_out_bits_amo_mask       = out_req.amo_mask;
  assign io_out_bits_amo_cmp        = out_req.amo_cmp;
  assign io_out_bits_req_coh_state  = out_req.req_coh_state;
  assign io_out_bits_id             = out_req.id;
  assign io_out_bits_isBtoT         = out_req.isBtoT;
  assign io_out_bits_occupy_way     = out_req.occupy_way;
  assign io_out_bits_cancel         = out_req.cancel;
  assign io_out_bits_store_data     = out_req.store_data;
  assign io_out_bits_store_mask     = out_req.store_mask;

endmodule
