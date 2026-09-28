// =============================================================================
// Arbiter4_MainPipeReq —— DCache MainPipe 的 s0 请求仲裁器
//                         （xs_FixedPriorityArbiter_core 家族的一个变体）
//
// 位置：MainPipe s0。四个请求源抢同一条主流水，固定优先级（下标小的赢）：
//   第 0 路 probe   —— ProbeQueue 送来的 L2 probe（优先级最高：不能让 L2 等）
//   第 1 路 refill  —— MissQueue 回填（miss 数据到了，要在主流水里写 tag/meta/data）
//   第 2 路 store   —— Sbuffer 写整行（MainPipe 里已换算成 MainPipeReq）
//   第 3 路 atomic  —— AtomicsUnit 的 AMO/LR/SC
// 语义：lowest-index-wins、无锁定、纯组合（见 xs_FixedPriorityArbiter_core.sv）。
//
// 本变体的参数与规模（按 G1 golden 现读）：
//   入口数 NUM_IN = 4；载荷 WIDTH = 982 位 = MainPipeReq 在 golden 输出端口上保留下来的
//   20 个字段（见下面 main_pipe_req_t）；golden 端口 60 个；纯组合，无寄存器/子模块。
//
// ★常量字段★：每一路只带"它自己用得到"的字段端口，其余字段由 Scala 的 convert
//   函数/上游写成常量，firtool 把常量折进了仲裁器 —— golden 端口表里就没有这些端口。
//   这里在拼每一路载荷时把常量写回去（miss/probe 标志、source/cmd 编码、不用的数据清零），
//   核看到的仍是"每路一根等宽载荷"。常量逐个取自 golden 的输出三元链：
//     probe  路：probe=1，source=0，cmd=0，其余非 probe 字段 = 0
//     refill 路：miss=1，probe=0，store_data/store_mask = 0
//     store  路：source=1(STORE_SOURCE)，cmd=1(M_XWR)，word_idx/amo_* = 0，id 用端口
//     atomic 路：source=2(AMO_SOURCE)，id=0，store_data/mask = 0
//
// ★少一根 ready★：golden 没有 io_in_2_ready —— MainPipe 为了时序自己另算
//   store_req.ready（与仲裁并行做 set 冲突检查），仲裁器那根没人读，被 firtool 删掉。
//   所以核的 in_ready[1]（第 2 路）在这里悬空，端口数恒等式要把这一根加回去。
// =============================================================================

module Arbiter4_MainPipeReq(
  output         io_in_0_ready,
  input          io_in_0_valid,
  input  [1:0]   io_in_0_bits_probe_param,
  input          io_in_0_bits_probe_need_data,
  input  [49:0]  io_in_0_bits_vaddr,
  input  [47:0]  io_in_0_bits_addr,
  input  [5:0]   io_in_0_bits_id,
  output         io_in_1_ready,
  input          io_in_1_valid,
  input  [3:0]   io_in_1_bits_miss_id,
  input  [3:0]   io_in_1_bits_occupy_way,
  input          io_in_1_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_in_1_bits_source,
  input  [4:0]   io_in_1_bits_cmd,
  input  [49:0]  io_in_1_bits_vaddr,
  input  [47:0]  io_in_1_bits_addr,
  input  [2:0]   io_in_1_bits_word_idx,
  input  [127:0] io_in_1_bits_amo_data,
  input  [15:0]  io_in_1_bits_amo_mask,
  input  [127:0] io_in_1_bits_amo_cmp,
  input  [2:0]   io_in_1_bits_pf_source,
  input          io_in_1_bits_access,
  input  [5:0]   io_in_1_bits_id,
  input          io_in_2_valid,
  input  [49:0]  io_in_2_bits_vaddr,
  input  [47:0]  io_in_2_bits_addr,
  input  [511:0] io_in_2_bits_store_data,
  input  [63:0]  io_in_2_bits_store_mask,
  input  [5:0]   io_in_2_bits_id,
  output         io_in_3_ready,
  input          io_in_3_valid,
  input  [4:0]   io_in_3_bits_cmd,
  input  [49:0]  io_in_3_bits_vaddr,
  input  [47:0]  io_in_3_bits_addr,
  input  [2:0]   io_in_3_bits_word_idx,
  input  [127:0] io_in_3_bits_amo_data,
  input  [15:0]  io_in_3_bits_amo_mask,
  input  [127:0] io_in_3_bits_amo_cmp,
  input          io_out_ready,
  output         io_out_valid,
  output         io_out_bits_miss,
  output [3:0]   io_out_bits_miss_id,
  output [3:0]   io_out_bits_occupy_way,
  output         io_out_bits_miss_fail_cause_evict_btot,
  output         io_out_bits_probe,
  output [1:0]   io_out_bits_probe_param,
  output         io_out_bits_probe_need_data,
  output [3:0]   io_out_bits_source,
  output [4:0]   io_out_bits_cmd,
  output [49:0]  io_out_bits_vaddr,
  output [47:0]  io_out_bits_addr,
  output [511:0] io_out_bits_store_data,
  output [63:0]  io_out_bits_store_mask,
  output [2:0]   io_out_bits_word_idx,
  output [127:0] io_out_bits_amo_data,
  output [15:0]  io_out_bits_amo_mask,
  output [127:0] io_out_bits_amo_cmp,
  output [2:0]   io_out_bits_pf_source,
  output         io_out_bits_access,
  output [5:0]   io_out_bits_id
);

  // MainPipeReq 在仲裁器输出上保留下来的字段（顺序 = golden 输出端口顺序）
  typedef struct packed {
    logic         miss;                        // refill 请求（只有 refill 路为 1）
    logic [3:0]   miss_id;                     // 对应的 MissQueue 表项
    logic [3:0]   occupy_way;                  // BtoT 升权失败时指定要占的路
    logic         miss_fail_cause_evict_btot;  // 置 1 时替换路用 occupy_way
    logic         probe;                       // probe 请求（只有 probe 路为 1）
    logic [1:0]   probe_param;                 // TileLink probe 目标权限
    logic         probe_need_data;             // probe 要不要回数据
    logic [3:0]   source;                      // 请求来源编码（0 load/1 store/2 amo）
    logic [4:0]   cmd;                         // 内存命令 M_XRD/M_XWR/AMO...
    logic [49:0]  vaddr;                       // 取 set 下标用
    logic [47:0]  addr;                        // 物理地址（行对齐）
    logic [511:0] store_data;                  // store 整行数据
    logic [63:0]  store_mask;                  // store 字节掩码
    logic [2:0]   word_idx;                    // AMO 作用的 64 位字
    logic [127:0] amo_data;                    // AMO 操作数（CAS.Q 用满 128 位）
    logic [15:0]  amo_mask;                    // AMO 字节掩码
    logic [127:0] amo_cmp;                     // AMOCAS 的比较值
    logic [2:0]   pf_source;                   // 预取来源（refill 带过来）
    logic         access;                      // 该行是否被访问过（refill 带过来）
    logic [5:0]   id;                          // 请求 id（回给请求方）
  } main_pipe_req_t;

  localparam int unsigned NUM_IN = 4;
  localparam int unsigned WIDTH  = $bits(main_pipe_req_t);   // 982

  localparam logic [3:0] STORE_SOURCE = 4'd1;
  localparam logic [3:0] AMO_SOURCE   = 4'd2;
  localparam logic [4:0] M_XWR        = 5'd1;

  // golden 端口数恒等式：60 个现存端口 + 1 根被 DCE 的 io_in_2_ready
  localparam int unsigned GOLDEN_PORTS_PRESENT = 60;
  localparam int unsigned DCE_READY_PORTS      = 1;
  localparam int unsigned GOLDEN_BITS_PORTS    = 51;

  // ---- 每一路的载荷：有端口就用端口，没有就填该路的常量 ----
  main_pipe_req_t probe_way, refill_way, store_way, atomic_way;

  always_comb begin
    probe_way                 = '0;
    probe_way.probe           = 1'b1;
    probe_way.probe_param     = io_in_0_bits_probe_param;
    probe_way.probe_need_data = io_in_0_bits_probe_need_data;
    probe_way.vaddr           = io_in_0_bits_vaddr;
    probe_way.addr            = io_in_0_bits_addr;
    probe_way.id              = io_in_0_bits_id;
  end

  always_comb begin
    refill_way                            = '0;
    refill_way.miss                       = 1'b1;
    refill_way.miss_id                    = io_in_1_bits_miss_id;
    refill_way.occupy_way                 = io_in_1_bits_occupy_way;
    refill_way.miss_fail_cause_evict_btot = io_in_1_bits_miss_fail_cause_evict_btot;
    refill_way.source                     = io_in_1_bits_source;
    refill_way.cmd                        = io_in_1_bits_cmd;
    refill_way.vaddr                      = io_in_1_bits_vaddr;
    refill_way.addr                       = io_in_1_bits_addr;
    refill_way.word_idx                   = io_in_1_bits_word_idx;
    refill_way.amo_data                   = io_in_1_bits_amo_data;
    refill_way.amo_mask                   = io_in_1_bits_amo_mask;
    refill_way.amo_cmp                    = io_in_1_bits_amo_cmp;
    refill_way.pf_source                  = io_in_1_bits_pf_source;
    refill_way.access                     = io_in_1_bits_access;
    refill_way.id                         = io_in_1_bits_id;
  end

  always_comb begin
    store_way            = '0;
    store_way.source     = STORE_SOURCE;
    store_way.cmd        = M_XWR;
    store_way.vaddr      = io_in_2_bits_vaddr;
    store_way.addr       = io_in_2_bits_addr;
    store_way.store_data = io_in_2_bits_store_data;
    store_way.store_mask = io_in_2_bits_store_mask;
    store_way.id         = io_in_2_bits_id;
  end

  always_comb begin
    atomic_way          = '0;
    atomic_way.source   = AMO_SOURCE;
    atomic_way.cmd      = io_in_3_bits_cmd;
    atomic_way.vaddr    = io_in_3_bits_vaddr;
    atomic_way.addr     = io_in_3_bits_addr;
    atomic_way.word_idx = io_in_3_bits_word_idx;
    atomic_way.amo_data = io_in_3_bits_amo_data;
    atomic_way.amo_mask = io_in_3_bits_amo_mask;
    atomic_way.amo_cmp  = io_in_3_bits_amo_cmp;
  end

  // 核的约定：高位段 = 第 0 路（优先级最高）
  logic [NUM_IN*WIDTH-1:0] in_bits_flat;
  logic [NUM_IN-1:0]       in_valid_vec;
  logic [NUM_IN-1:0]       in_ready_vec;
  main_pipe_req_t          out_req;

  assign in_bits_flat = {probe_way, refill_way, store_way, atomic_way};
  assign in_valid_vec = {io_in_0_valid, io_in_1_valid, io_in_2_valid, io_in_3_valid};

  // in_ready_vec[1] 是第 2 路（store）的 ready：golden 无此端口，悬空不接
  assign io_in_0_ready = in_ready_vec[3];
  assign io_in_1_ready = in_ready_vec[2];
  assign io_in_3_ready = in_ready_vec[0];

  xs_FixedPriorityArbiter_core #(
    .WIDTH            (WIDTH),
    .NUM_IN           (NUM_IN),
    // 端口表事实：$bits 只认端口声明，输出端口位宽抄错这个常量立刻跟着变
    .PORT_BITS_OUT    ($bits({io_out_bits_miss, io_out_bits_miss_id, io_out_bits_occupy_way,
                              io_out_bits_miss_fail_cause_evict_btot, io_out_bits_probe,
                              io_out_bits_probe_param, io_out_bits_probe_need_data,
                              io_out_bits_source, io_out_bits_cmd, io_out_bits_vaddr,
                              io_out_bits_addr, io_out_bits_store_data, io_out_bits_store_mask,
                              io_out_bits_word_idx, io_out_bits_amo_data, io_out_bits_amo_mask,
                              io_out_bits_amo_cmp, io_out_bits_pf_source, io_out_bits_access,
                              io_out_bits_id})),
    // 末路（atomic）只有一部分字段有端口，其余填常量，按构造等于 WIDTH
    .PORT_BITS_LAST_IN($bits(atomic_way)),
    .GOLDEN_PORTS     (GOLDEN_PORTS_PRESENT + DCE_READY_PORTS),
    .GOLDEN_BITS_PORTS(GOLDEN_BITS_PORTS)
  ) u_core (
    .in_valid (in_valid_vec),
    .in_ready (in_ready_vec),
    .in_bits  (in_bits_flat),
    .out_ready(io_out_ready),
    .out_valid(io_out_valid),
    .out_bits (out_req)
  );

  assign io_out_bits_miss                       = out_req.miss;
  assign io_out_bits_miss_id                    = out_req.miss_id;
  assign io_out_bits_occupy_way                 = out_req.occupy_way;
  assign io_out_bits_miss_fail_cause_evict_btot = out_req.miss_fail_cause_evict_btot;
  assign io_out_bits_probe                      = out_req.probe;
  assign io_out_bits_probe_param                = out_req.probe_param;
  assign io_out_bits_probe_need_data            = out_req.probe_need_data;
  assign io_out_bits_source                     = out_req.source;
  assign io_out_bits_cmd                        = out_req.cmd;
  assign io_out_bits_vaddr                      = out_req.vaddr;
  assign io_out_bits_addr                       = out_req.addr;
  assign io_out_bits_store_data                 = out_req.store_data;
  assign io_out_bits_store_mask                 = out_req.store_mask;
  assign io_out_bits_word_idx                   = out_req.word_idx;
  assign io_out_bits_amo_data                   = out_req.amo_data;
  assign io_out_bits_amo_mask                   = out_req.amo_mask;
  assign io_out_bits_amo_cmp                    = out_req.amo_cmp;
  assign io_out_bits_pf_source                  = out_req.pf_source;
  assign io_out_bits_access                     = out_req.access;
  assign io_out_bits_id                         = out_req.id;

endmodule
