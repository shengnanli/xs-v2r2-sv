// =============================================================================
//  probequeue_pkg —— ProbeQueue（DCache 一致性 probe 请求队列）可读重写用类型/常量
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel）：
//      src/main/scala/xiangshan/cache/dcache/mainpipe/Probe.scala（class ProbeQueue）
//
//  ProbeQueue 处理来自 L2 的一致性 probe（TileLink B 通道）。当 L2 要降级/无效化 L1
//  里某条 cacheline（如别的核要写它）时，发 Probe 到 L1；本队列把每个 probe 收进一个
//  ProbeEntry，由 entry 经 DCache 主流水（MainPipe）执行降级，再把结果回给 L2。
//  队列有 nProbeEntries(=8) 个 entry。entry 的 3 态状态机（s_invalid/s_pipe_req/
//  s_wait_resp）封装在子模块 ProbeEntry（本工程当 golden 黑盒，UT/FM 两侧共用）。
//
//  本可读核 xs_ProbeQueue_core 重写「队列级」逻辑：
//    (1) probe 请求翻译：把 TLBundleB（source/opcode/address/param/data）翻译成内部
//        ProbeReq，重点是 vaddr 重建——L2 用 vaddr index 来 probe L1，但 probe 报文里
//        只带 paddr + 别名位（data[2:1]）；当存在 cache 别名（DCacheAboveIndexOffset >
//        DCacheTagOffset）时，要把别名位拼回 index 段。
//    (2) 分配：用「最低空闲下标优先」把 probe 分给一个空 ProbeEntry。
//    (3) 输出仲裁 + 延迟：8 个 entry 的 pipe_req 经固定优先 Arbiter8 汇聚（黑盒），再打
//        一拍（selected_req）后送主流水 io_pipe_req；其间用 lrsc/reservation-set 阻塞，
//        给地址比较一个独立周期改善时序。
//
//  详见 docs/memblock/ProbeQueue.md。
// =============================================================================
package probequeue_pkg;

  // ---- 固化参数（KunmingHu V2R2，见 xiangshan/Parameters.scala DCacheParameters）----
  localparam int N_PROBE     = 8;        // nProbeEntries
  localparam int IDX_BITS    = 3;        // $clog2(8)
  localparam int PADDR_BITS  = 48;
  localparam int VADDR_BITS  = 50;       // pipe_req vaddr 宽度
  localparam int ID_BITS     = 6;        // pipe_req id 宽度（高 3 位恒 0，低 3 位为 entry 下标）
  localparam int PARAM_BITS  = 2;        // probe param（TLPermissions.bdWidth = 2）
  localparam int BLK_OFFSET  = 6;        // cacheline 内偏移位数（getBlock 比较 addr[47:6]）

  // ---- TileLink B 通道 opcode（io_mem_probe_bits_opcode）----
  //  L1 收到的 B 通道目前只处理 Probe（=6，PutFullData…Probe 等其余在本设计里非法）。
  //  Scala 里有 assert(opcode === TLMessages.Probe)。本核据此把它定义成 enum 增强可读性。
  typedef enum logic [2:0] {
    TLB_PROBE = 3'd6
  } tl_b_opcode_e;

  // 判定 B 通道报文是否为 Probe（合法 probe 请求）。
  function automatic logic opcode_is_probe(input logic [2:0] op);
    opcode_is_probe = (tl_b_opcode_e'(op) == TLB_PROBE);
  endfunction

  // ---- 别名重建参数（DCache index 别名）----
  //  golden req_vaddr = {2'h0, addr[47:14], data[2:1], addr[11:0]}
  //  即 DCacheTagOffset = 12、DCacheAboveIndexOffset = 14、别名位 = data[2:1]（2 位）。
  localparam int TAG_OFFSET        = 12;
  localparam int ABOVE_IDX_OFFSET  = 14;
  localparam int ALIAS_BITS        = ABOVE_IDX_OFFSET - TAG_OFFSET;  // = 2

  // ---- 发往主流水的 probe 请求（MainPipeReq 的 probe 相关子集）----
  //  对应 Scala ProbeEntry 里 pipe_req := DontCare; pipe_req.probe := true; ...
  typedef struct packed {
    logic [PARAM_BITS-1:0] probe_param;
    logic                  probe_need_data;
    logic [VADDR_BITS-1:0] vaddr;
    logic [PADDR_BITS-1:0] addr;
    logic [ID_BITS-1:0]    id;
  } pipe_req_t;

  // ---------------------------------------------------------------------------
  //  纯函数：最低位优先编码下标（PriorityEncoder 等价）。
  //  用于在空闲 entry 里选最低下标分配 probe。
  // ---------------------------------------------------------------------------
  function automatic logic [IDX_BITS-1:0] prio_idx(input logic [N_PROBE-1:0] v);
    prio_idx = '0;
    for (int i = N_PROBE-1; i >= 0; i--)
      if (v[i]) prio_idx = IDX_BITS'(i);
  endfunction

  // ---------------------------------------------------------------------------
  //  纯函数：cacheline block 地址比较（去掉行内偏移低 BLK_OFFSET 位）。
  // ---------------------------------------------------------------------------
  function automatic logic same_block(input logic [PADDR_BITS-1:0] a,
                                       input logic [PADDR_BITS-1:0] b);
    same_block = (a[PADDR_BITS-1:BLK_OFFSET] == b[PADDR_BITS-1:BLK_OFFSET]);
  endfunction

endpackage
