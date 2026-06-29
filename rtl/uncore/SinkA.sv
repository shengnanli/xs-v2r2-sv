// =============================================================================
//  SinkA —— coupledL2 (tl2chi) TileLink A 通道接收器 可读重写核 (xs_SinkA_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/src/main/scala/coupledL2/SinkA.scala
//  把上层来的 TileLink A 请求 (Acquire/Get/Hint) 或 L2 预取请求 (PrefetchReq) 归一
//  成内部 TaskBundle, 交给 MainPipe。单态化 (firtool SinkA.sv):
//    prefetchOpt 使能 (有 io_prefetchReq) ; enableL2Flush 关闭 (无 CMO flush FSM)
//  => 本模块纯组合, 无寄存器、无 SRAM、无子模块。
//
//  仲裁: A 请求优先于预取。
//    io_task.valid = a.valid | prefetchReq.valid
//    a.ready       = task.ready
//    prefetch.ready= task.ready & ~a.valid     (A 占用时预取让路)
//  各 task 字段: a.valid 时取 A 请求, 否则取预取请求 (parseAddress 拆 tag/set/off)。
//
//  ===== 地址切分 (48-bit 物理地址) =====
//    tag = addr[47:17] (31b), set = addr[16:8] (9b), off = addr[5:0] (6b)
//  预取请求的 fullAddr = {tag(33b), set(9b), 6'b0}, 同样规则切分:
//    tag = ptag[32:2], set = {ptag[1:0], pset[8:2]}
// =============================================================================
module xs_SinkA_core (
  input  logic        clock,
  input  logic        reset,

  // ---- io.a (Flipped DecoupledIO TLBundleA, 上层 A 请求) ----
  output logic        io_a_ready,
  input  logic        io_a_valid,
  input  logic [3:0]  io_a_bits_opcode,
  input  logic [2:0]  io_a_bits_param,
  input  logic [2:0]  io_a_bits_size,
  input  logic [6:0]  io_a_bits_source,
  input  logic [47:0] io_a_bits_address,
  input  logic [4:0]  io_a_bits_user_reqSource,
  input  logic [1:0]  io_a_bits_user_alias,
  input  logic [43:0] io_a_bits_user_vaddr,
  input  logic        io_a_bits_user_needHint,
  input  logic        io_a_bits_echo_isKeyword,
  input  logic        io_a_bits_corrupt,

  // ---- io.prefetchReq (Flipped DecoupledIO PrefetchReq, L2 预取请求) ----
  output logic        io_prefetchReq_ready,
  input  logic        io_prefetchReq_valid,
  input  logic [32:0] io_prefetchReq_bits_tag,
  input  logic [8:0]  io_prefetchReq_bits_set,
  input  logic [43:0] io_prefetchReq_bits_vaddr,
  input  logic        io_prefetchReq_bits_needT,
  input  logic [6:0]  io_prefetchReq_bits_source,
  input  logic [4:0]  io_prefetchReq_bits_pfSource,

  // ---- io.task (DecoupledIO TaskBundle, 投向 MainPipe) ----
  input  logic        io_task_ready,
  output logic        io_task_valid,
  output logic [8:0]  io_task_bits_set,
  output logic [30:0] io_task_bits_tag,
  output logic [5:0]  io_task_bits_off,
  output logic [1:0]  io_task_bits_alias,
  output logic [43:0] io_task_bits_vaddr,
  output logic        io_task_bits_isKeyword,
  output logic [3:0]  io_task_bits_opcode,
  output logic [2:0]  io_task_bits_param,
  output logic [2:0]  io_task_bits_size,
  output logic [6:0]  io_task_bits_sourceId,
  output logic        io_task_bits_corrupt,
  output logic        io_task_bits_fromL2pft,
  output logic        io_task_bits_needHint,
  output logic [4:0]  io_task_bits_reqSource
);

  // 握手: A 请求与预取请求二选一 (A 优先)
  assign io_task_valid        = io_a_valid | io_prefetchReq_valid;
  assign io_a_ready           = io_task_ready;
  assign io_prefetchReq_ready = io_task_ready & ~io_a_valid;

  // opcode: A 请求用其原 opcode, 否则为预取 Hint(=4'h5)
  assign io_task_bits_opcode = io_a_valid ? io_a_bits_opcode : 4'h5;

  // 地址/字段: a.valid 时取 A 请求, 否则取预取请求
  assign io_task_bits_set =
      io_a_valid ? io_a_bits_address[16:8]
                 : {io_prefetchReq_bits_tag[1:0], io_prefetchReq_bits_set[8:2]};
  assign io_task_bits_tag =
      io_a_valid ? io_a_bits_address[47:17] : io_prefetchReq_bits_tag[32:2];
  assign io_task_bits_off      = io_a_valid ? io_a_bits_address[5:0] : 6'h0;
  assign io_task_bits_alias    = io_a_valid ? io_a_bits_user_alias : 2'h0;
  assign io_task_bits_vaddr    = io_a_valid ? io_a_bits_user_vaddr : io_prefetchReq_bits_vaddr;
  assign io_task_bits_isKeyword = io_a_valid & io_a_bits_echo_isKeyword;
  // 预取 param: needT → PREFETCH_WRITE(1), 否则 PREFETCH_READ(0)
  assign io_task_bits_param    = io_a_valid ? io_a_bits_param : {2'h0, io_prefetchReq_bits_needT};
  assign io_task_bits_size     = io_a_valid ? io_a_bits_size : 3'h6;   // 预取 size=offsetBits=6
  assign io_task_bits_sourceId = io_a_valid ? io_a_bits_source : io_prefetchReq_bits_source;
  assign io_task_bits_corrupt  = io_a_valid & io_a_bits_corrupt;
  // fromL2pft = 预取且 needAck (pfSource ∈ {8,9} 即 L2 预取源需回 ack)
  assign io_task_bits_fromL2pft =
      ~io_a_valid & ((io_prefetchReq_bits_pfSource == 5'h8) | (io_prefetchReq_bits_pfSource == 5'h9));
  assign io_task_bits_needHint = io_a_valid & io_a_bits_user_needHint;
  assign io_task_bits_reqSource = io_a_valid ? io_a_bits_user_reqSource : io_prefetchReq_bits_pfSource;

endmodule
