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

// =============================================================================
//  ProbeQueue —— DCache 一致性 probe 请求队列（可读核 xs_ProbeQueue_core）
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel）：
//      src/main/scala/xiangshan/cache/dcache/mainpipe/Probe.scala（class ProbeQueue）
//  golden（firtool 生成，仅 UT/FM 对照）：golden/chisel-rtl/ProbeQueue.sv（652 行）
//
//  本核重写「队列级」逻辑；每个 entry 的 3 态状态机封装在子模块 ProbeEntry（当 golden
//  黑盒），8 路 pipe_req 的固定优先仲裁封装在 Arbiter8_MainPipeReq（当 golden 黑盒）。
//  队列级逻辑分三部分：
//    (1) probe 翻译：把 TLBundleB 翻成内部 ProbeReq，重建 vaddr（别名位拼回 index）。
//    (2) 分配：最低空闲下标优先，把 probe 分给一个空 ProbeEntry。
//    (3) 仲裁 + 延迟：Arbiter8 汇聚 → 打一拍(selected_req) → lrsc/resv-set 阻塞 → io_pipe_req。
//
//  详见 docs/memblock/ProbeQueue.md。
// =============================================================================
import probequeue_pkg::*;


module xs_ProbeQueue_core (
  input  logic                  clock,
  input  logic                  reset,

  // ---- 上游：来自 L2 的 probe（TileLink B 通道）----
  output logic                  io_mem_probe_ready,
  input  logic                  io_mem_probe_valid,
  input  logic [2:0]            io_mem_probe_bits_opcode,
  input  logic [PARAM_BITS-1:0] io_mem_probe_bits_param,
  input  logic [PADDR_BITS-1:0] io_mem_probe_bits_address,
  input  logic [255:0]          io_mem_probe_bits_data,

  // ---- 下游：发往 DCache 主流水的 probe 请求 ----
  input  logic                  io_pipe_req_ready,
  output logic                  io_pipe_req_valid,
  output logic [PARAM_BITS-1:0] io_pipe_req_bits_probe_param,
  output logic                  io_pipe_req_bits_probe_need_data,
  output logic [VADDR_BITS-1:0] io_pipe_req_bits_vaddr,
  output logic [PADDR_BITS-1:0] io_pipe_req_bits_addr,
  output logic [ID_BITS-1:0]    io_pipe_req_bits_id,

  // ---- 旁路：LR/SC 锁定块 + reservation set 更新（用于阻塞 probe）----
  input  logic                  io_lrsc_locked_block_valid,
  input  logic [PADDR_BITS-1:0] io_lrsc_locked_block_bits,
  input  logic                  io_update_resv_set,

  // ---- perf（每路 2 拍打拍）----
  output logic [5:0]            io_perf_0_value,
  output logic [5:0]            io_perf_1_value,
  output logic [5:0]            io_perf_2_value,
  output logic [5:0]            io_perf_3_value,
  output logic [5:0]            io_perf_4_value
);

  // ===========================================================================
  //  (1) probe 请求翻译：TLBundleB → 内部 ProbeReq
  //  vaddr 重建：L2 用 vaddr index probe L1，但报文只带 paddr + 别名位（data[2:1]）。
  //  存在别名时（DCacheAboveIndexOffset > DCacheTagOffset），把别名位拼回 index 段：
  //      vaddr = {0, addr[高..ABOVE_IDX], alias(data[2:1]), addr[TAG..0]}
  //  needData = data[0]；param/addr 直传。
  // ===========================================================================
  // 合法性（仅供阅读/波形）：本设计只接受 Probe（B 通道 opcode==6）。
  logic probe_is_legal;
  assign probe_is_legal = opcode_is_probe(io_mem_probe_bits_opcode);

  logic [VADDR_BITS-1:0] req_vaddr;
  logic [ALIAS_BITS-1:0] alias_frag;
  assign alias_frag = io_mem_probe_bits_data[ALIAS_BITS:1];  // data[2:1]
  assign req_vaddr  = {{(VADDR_BITS-PADDR_BITS){1'b0}},                         // 高位补 0（dontcare）
                       io_mem_probe_bits_address[PADDR_BITS-1:ABOVE_IDX_OFFSET],// addr 高段
                       alias_frag,                                             // 别名位 → index
                       io_mem_probe_bits_address[TAG_OFFSET-1:0]};             // 低段（index & 偏移）

  // ===========================================================================
  //  (2) 分配：最低空闲 entry 优先
  // ===========================================================================
  logic [N_PROBE-1:0]   entry_req_ready;     // 每 entry：是否空闲可收
  logic                 allocate;
  logic [IDX_BITS-1:0]  alloc_idx;
  assign allocate  = |entry_req_ready;
  assign alloc_idx = prio_idx(entry_req_ready);
  assign io_mem_probe_ready = allocate;

  // entry 阵列接口线
  logic [N_PROBE-1:0]    entry_pipe_req_valid;
  logic [PARAM_BITS-1:0] entry_pipe_req_param   [N_PROBE];
  logic                  entry_pipe_req_needdata[N_PROBE];
  logic [VADDR_BITS-1:0] entry_pipe_req_vaddr   [N_PROBE];
  logic [PADDR_BITS-1:0] entry_pipe_req_addr    [N_PROBE];
  logic [ID_BITS-1:0]    entry_pipe_req_id      [N_PROBE];
  logic [N_PROBE-1:0]    entry_pipe_req_ready;   // 仲裁器回给每 entry 的 ready
  logic [N_PROBE-1:0]    entry_block_valid;
  logic [PADDR_BITS-1:0] entry_block_addr       [N_PROBE];

  // ===========================================================================
  //  (3) 仲裁 + 一拍延迟 + 阻塞
  // ===========================================================================
  // Arbiter8 黑盒输出
  logic                  arb_out_valid;
  logic                  arb_out_ready;
  logic [PARAM_BITS-1:0] arb_out_param;
  logic                  arb_out_needdata;
  logic [VADDR_BITS-1:0] arb_out_vaddr;
  logic [PADDR_BITS-1:0] arb_out_addr;
  logic [ID_BITS-1:0]    arb_out_id;

  // selected_req：把仲裁结果打一拍再送主流水（独立周期做地址比较，改善时序）
  logic                  selected_valid;
  logic [PARAM_BITS-1:0] selected_param;
  logic                  selected_needdata;
  logic [VADDR_BITS-1:0] selected_vaddr;
  logic [PADDR_BITS-1:0] selected_addr;
  logic [ID_BITS-1:0]    selected_id;
  logic                  resvset_block;

  logic pipe_req_fire;   // io_pipe_req.fire
  logic arb_fire;        // pipe_req_arb.io.out.fire

  // io_pipe_req.valid：已锁存一拍 且 未被 resv-set 阻塞
  assign io_pipe_req_valid = selected_valid && !resvset_block;
  assign pipe_req_fire     = io_pipe_req_ready && io_pipe_req_valid;
  // 仲裁器 out.ready：无锁存请求 或 锁存请求这拍 fire（腾出位置）
  assign arb_out_ready = !selected_valid || pipe_req_fire;
  assign arb_fire      = arb_out_ready && arb_out_valid;

  assign io_pipe_req_bits_probe_param     = selected_param;
  assign io_pipe_req_bits_probe_need_data = selected_needdata;
  assign io_pipe_req_bits_vaddr           = selected_vaddr;
  assign io_pipe_req_bits_addr            = selected_addr;
  assign io_pipe_req_bits_id              = selected_id;

  // selected_lrsc_blocked：本拍要送主流水的 probe 地址是否撞 LR/SC 锁定块。
  //  仲裁这拍 fire 时看仲裁出的 addr，否则看已锁存的 addr（且确有锁存）。
  logic selected_lrsc_blocked;
  always_comb begin
    if (arb_fire)
      selected_lrsc_blocked = io_lrsc_locked_block_valid &&
                              same_block(io_lrsc_locked_block_bits, arb_out_addr);
    else
      selected_lrsc_blocked = io_lrsc_locked_block_valid &&
                              same_block(io_lrsc_locked_block_bits, selected_addr) &&
                              selected_valid;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) selected_valid <= 1'b0;
    // 锁存：仲裁 fire 置位；fire 到主流水后清；否则保持。
    else       selected_valid <= arb_fire | (~pipe_req_fire & selected_valid);
  end

  always_ff @(posedge clock) begin
    if (arb_fire) begin
      selected_param    <= arb_out_param;
      selected_needdata <= arb_out_needdata;
      selected_vaddr    <= arb_out_vaddr;
      selected_addr     <= arb_out_addr;
      selected_id       <= arb_out_id;
    end
    // resvset_block：reservation set 更新 或 lrsc 撞块 → 下一拍阻塞所有 probe（独立周期）。
    resvset_block <= io_update_resv_set | selected_lrsc_blocked;
  end

  // ===========================================================================
  //  perf：pipe_req 计数 + 在途 entry 数分桶（各打 2 拍，与 golden 一致）
  // ===========================================================================
  logic [3:0] perf_valid_count;
  logic [3:0] perf_valid_count_r;
  logic       perf_req;
  assign perf_req = io_pipe_req_ready && io_pipe_req_valid;
  always_comb begin
    perf_valid_count = '0;
    for (int i = 0; i < N_PROBE; i++)
      perf_valid_count = perf_valid_count + 4'(entry_block_valid[i]);
  end
  logic perf0_r, perf0_r1, perf1_r, perf1_r1, perf2_r, perf2_r1;
  logic perf3_r, perf3_r1, perf4_r, perf4_r1;
  always_ff @(posedge clock) begin
    perf_valid_count_r <= perf_valid_count;
    perf0_r <= perf_req;                                                perf0_r1 <= perf0_r;
    perf1_r <= perf_valid_count_r < 4'd2;                               perf1_r1 <= perf1_r;
    perf2_r <= (perf_valid_count_r > 4'd2) && (perf_valid_count_r < 4'd5); perf2_r1 <= perf2_r;
    perf3_r <= (perf_valid_count_r > 4'd4) && (perf_valid_count_r < 4'd7); perf3_r1 <= perf3_r;
    perf4_r <= perf_valid_count_r > 4'd6;                               perf4_r1 <= perf4_r;
  end
  assign io_perf_0_value = {5'h0, perf0_r1};
  assign io_perf_1_value = {5'h0, perf1_r1};
  assign io_perf_2_value = {5'h0, perf2_r1};
  assign io_perf_3_value = {5'h0, perf3_r1};
  assign io_perf_4_value = {5'h0, perf4_r1};

  // ===========================================================================
  //  entry 阵列例化（ProbeEntry 黑盒）+ 仲裁器例化（Arbiter8_MainPipeReq 黑盒）
  //  entry.req.valid = (alloc_idx==i) & allocate & mem_probe.valid（唯一分配）
  //  entry.pipe_resp = io_pipe_req.fire 时，按 selected_id 低 3 位匹配回应。
  // ===========================================================================
  for (genvar i = 0; i < N_PROBE; i++) begin : g_entry
    ProbeEntry u_entry (
      .clock                            (clock),
      .reset                            (reset),
      .io_req_ready                     (entry_req_ready[i]),
      .io_req_valid                     ((alloc_idx == IDX_BITS'(i)) && allocate && io_mem_probe_valid),
      .io_req_bits_addr                 (io_mem_probe_bits_address),
      .io_req_bits_vaddr                (req_vaddr),
      .io_req_bits_param                (io_mem_probe_bits_param),
      .io_req_bits_needData             (io_mem_probe_bits_data[0]),
      .io_pipe_req_ready                (entry_pipe_req_ready[i]),
      .io_pipe_req_valid                (entry_pipe_req_valid[i]),
      .io_pipe_req_bits_probe_param     (entry_pipe_req_param[i]),
      .io_pipe_req_bits_probe_need_data (entry_pipe_req_needdata[i]),
      .io_pipe_req_bits_vaddr           (entry_pipe_req_vaddr[i]),
      .io_pipe_req_bits_addr            (entry_pipe_req_addr[i]),
      .io_pipe_req_bits_id              (entry_pipe_req_id[i]),
      .io_pipe_resp_valid               (pipe_req_fire),
      .io_pipe_resp_bits_id             (selected_id[IDX_BITS-1:0]),
      .io_lrsc_locked_block_valid       (io_lrsc_locked_block_valid),
      .io_lrsc_locked_block_bits        (io_lrsc_locked_block_bits),
      .io_id                            (IDX_BITS'(i)),
      .io_block_addr_valid              (entry_block_valid[i]),
      .io_block_addr_bits               (entry_block_addr[i])
    );
  end

  Arbiter8_MainPipeReq pipe_req_arb (
    .io_in_0_ready                (entry_pipe_req_ready[0]),
    .io_in_0_valid                (entry_pipe_req_valid[0]),
    .io_in_0_bits_probe_param     (entry_pipe_req_param[0]),
    .io_in_0_bits_probe_need_data (entry_pipe_req_needdata[0]),
    .io_in_0_bits_vaddr           (entry_pipe_req_vaddr[0]),
    .io_in_0_bits_addr            (entry_pipe_req_addr[0]),
    .io_in_0_bits_id              (entry_pipe_req_id[0]),
    .io_in_1_ready                (entry_pipe_req_ready[1]),
    .io_in_1_valid                (entry_pipe_req_valid[1]),
    .io_in_1_bits_probe_param     (entry_pipe_req_param[1]),
    .io_in_1_bits_probe_need_data (entry_pipe_req_needdata[1]),
    .io_in_1_bits_vaddr           (entry_pipe_req_vaddr[1]),
    .io_in_1_bits_addr            (entry_pipe_req_addr[1]),
    .io_in_1_bits_id              (entry_pipe_req_id[1]),
    .io_in_2_ready                (entry_pipe_req_ready[2]),
    .io_in_2_valid                (entry_pipe_req_valid[2]),
    .io_in_2_bits_probe_param     (entry_pipe_req_param[2]),
    .io_in_2_bits_probe_need_data (entry_pipe_req_needdata[2]),
    .io_in_2_bits_vaddr           (entry_pipe_req_vaddr[2]),
    .io_in_2_bits_addr            (entry_pipe_req_addr[2]),
    .io_in_2_bits_id              (entry_pipe_req_id[2]),
    .io_in_3_ready                (entry_pipe_req_ready[3]),
    .io_in_3_valid                (entry_pipe_req_valid[3]),
    .io_in_3_bits_probe_param     (entry_pipe_req_param[3]),
    .io_in_3_bits_probe_need_data (entry_pipe_req_needdata[3]),
    .io_in_3_bits_vaddr           (entry_pipe_req_vaddr[3]),
    .io_in_3_bits_addr            (entry_pipe_req_addr[3]),
    .io_in_3_bits_id              (entry_pipe_req_id[3]),
    .io_in_4_ready                (entry_pipe_req_ready[4]),
    .io_in_4_valid                (entry_pipe_req_valid[4]),
    .io_in_4_bits_probe_param     (entry_pipe_req_param[4]),
    .io_in_4_bits_probe_need_data (entry_pipe_req_needdata[4]),
    .io_in_4_bits_vaddr           (entry_pipe_req_vaddr[4]),
    .io_in_4_bits_addr            (entry_pipe_req_addr[4]),
    .io_in_4_bits_id              (entry_pipe_req_id[4]),
    .io_in_5_ready                (entry_pipe_req_ready[5]),
    .io_in_5_valid                (entry_pipe_req_valid[5]),
    .io_in_5_bits_probe_param     (entry_pipe_req_param[5]),
    .io_in_5_bits_probe_need_data (entry_pipe_req_needdata[5]),
    .io_in_5_bits_vaddr           (entry_pipe_req_vaddr[5]),
    .io_in_5_bits_addr            (entry_pipe_req_addr[5]),
    .io_in_5_bits_id              (entry_pipe_req_id[5]),
    .io_in_6_ready                (entry_pipe_req_ready[6]),
    .io_in_6_valid                (entry_pipe_req_valid[6]),
    .io_in_6_bits_probe_param     (entry_pipe_req_param[6]),
    .io_in_6_bits_probe_need_data (entry_pipe_req_needdata[6]),
    .io_in_6_bits_vaddr           (entry_pipe_req_vaddr[6]),
    .io_in_6_bits_addr            (entry_pipe_req_addr[6]),
    .io_in_6_bits_id              (entry_pipe_req_id[6]),
    .io_in_7_ready                (entry_pipe_req_ready[7]),
    .io_in_7_valid                (entry_pipe_req_valid[7]),
    .io_in_7_bits_probe_param     (entry_pipe_req_param[7]),
    .io_in_7_bits_probe_need_data (entry_pipe_req_needdata[7]),
    .io_in_7_bits_vaddr           (entry_pipe_req_vaddr[7]),
    .io_in_7_bits_addr            (entry_pipe_req_addr[7]),
    .io_in_7_bits_id              (entry_pipe_req_id[7]),
    .io_out_ready                 (arb_out_ready),
    .io_out_valid                 (arb_out_valid),
    .io_out_bits_probe_param      (arb_out_param),
    .io_out_bits_probe_need_data  (arb_out_needdata),
    .io_out_bits_vaddr            (arb_out_vaddr),
    .io_out_bits_addr             (arb_out_addr),
    .io_out_bits_id               (arb_out_id)
  );

endmodule

// 自动生成：scripts/gen_probequeue.py —— 勿手改

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module ProbeQueue(
  input  clock,
  input  reset,
  output io_mem_probe_ready,
  input  io_mem_probe_valid,
  input  [2:0] io_mem_probe_bits_opcode,
  input  [1:0] io_mem_probe_bits_param,
  input  [47:0] io_mem_probe_bits_address,
  input  [255:0] io_mem_probe_bits_data,
  input  io_pipe_req_ready,
  output io_pipe_req_valid,
  output [1:0] io_pipe_req_bits_probe_param,
  output io_pipe_req_bits_probe_need_data,
  output [49:0] io_pipe_req_bits_vaddr,
  output [47:0] io_pipe_req_bits_addr,
  output [5:0] io_pipe_req_bits_id,
  input  io_lrsc_locked_block_valid,
  input  [47:0] io_lrsc_locked_block_bits,
  input  io_update_resv_set,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value,
  output [5:0] io_perf_4_value
);
  xs_ProbeQueue_core u_core (
    .clock(clock),
    .reset(reset),
    .io_mem_probe_ready(io_mem_probe_ready),
    .io_mem_probe_valid(io_mem_probe_valid),
    .io_mem_probe_bits_opcode(io_mem_probe_bits_opcode),
    .io_mem_probe_bits_param(io_mem_probe_bits_param),
    .io_mem_probe_bits_address(io_mem_probe_bits_address),
    .io_mem_probe_bits_data(io_mem_probe_bits_data),
    .io_pipe_req_ready(io_pipe_req_ready),
    .io_pipe_req_valid(io_pipe_req_valid),
    .io_pipe_req_bits_probe_param(io_pipe_req_bits_probe_param),
    .io_pipe_req_bits_probe_need_data(io_pipe_req_bits_probe_need_data),
    .io_pipe_req_bits_vaddr(io_pipe_req_bits_vaddr),
    .io_pipe_req_bits_addr(io_pipe_req_bits_addr),
    .io_pipe_req_bits_id(io_pipe_req_bits_id),
    .io_lrsc_locked_block_valid(io_lrsc_locked_block_valid),
    .io_lrsc_locked_block_bits(io_lrsc_locked_block_bits),
    .io_update_resv_set(io_update_resv_set),
    .io_perf_0_value(io_perf_0_value),
    .io_perf_1_value(io_perf_1_value),
    .io_perf_2_value(io_perf_2_value),
    .io_perf_3_value(io_perf_3_value),
    .io_perf_4_value(io_perf_4_value)
  );
endmodule
