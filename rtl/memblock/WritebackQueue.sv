// =============================================================================
//  writebackqueue_pkg —— WritebackQueue（DCache 脏行写回队列）可读重写用类型/常量/纯函数
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel 源，非 firtool golden）：
//      src/main/scala/xiangshan/cache/dcache/mainpipe/WritebackQueue.scala
//
//  WritebackQueue 位于 DCache 与 L2（TileLink C 通道）之间。当 DCache 需要把一条
//  cacheline「逐出/降级」到 L2 时（自愿写回 voluntary Release，或被 L2 probe 命中后
//  回的 ProbeAck），主流水把请求送进本队列，由队列里的 WritebackEntry 状态机负责：
//      · 把整行数据（512b = blockBytes*8）按 beat（每 beat 256b）逐拍经 mem_release
//        （TLBundleC）发往 L2；refillCycles = blockBytes/beatBytes = 2 个 beat。
//      · 对自愿 Release 还要等 L2 回 ReleaseAck（mem_grant / TLBundleD）才算完成。
//  队列有 nReleaseEntries(=18) 个 entry。entry 的状态机（s_invalid/s_release_req/
//  s_release_resp）封装在子模块 WritebackEntry 内（本工程把它当 golden 黑盒，UT/FM
//  两侧共用）。本可读核 xs_WritebackQueue_core 重写的是「队列级」逻辑：
//      (1) 分配（alloc）：把新请求按「最低空闲下标优先」唯一地分配给一个空 entry；
//      (2) block 冲突：新请求 / miss 请求若地址撞上在途 entry，则阻塞（保证同 block 顺序）；
//      (3) 输出仲裁：用 TileLink 的 robin（轮转优先）仲裁把多个 entry 的 mem_release 汇聚
//          到单一 C 通道，并在「多 beat 突发」期间锁定授权给同一 entry（beatsLeft）。
//
//  ── 与上下游关系 ─────────────────────────────────────────────────────────
//      上游：io_req（来自 MainPipe 的写回请求，Decoupled）+ io_req_bits_data（整行数据）
//      下游：io_mem_release（→ L2 C 通道，多 beat 突发）/ io_mem_grant（← L2 D 通道 ack）
//      旁路：io_miss_req_conflict_check[5] / io_block_miss_req[5]
//            （MissQueue 侧 5 路探测：3*LoadPipe + 1*MainPipe + 1*missReqArb_out，
//             若某 miss 请求地址正被某 entry 写回 → 阻塞该 miss，避免读到旧数据）
// =============================================================================
package writebackqueue_pkg;

  // ---- 固化参数（KunmingHu V2R2 配置，见 xiangshan/Parameters.scala DCacheParameters）----
  localparam int NR_ENTRY      = 18;            // nReleaseEntries：写回 entry 数
  localparam int N_MISS        = 16;            // nMissEntries
  localparam int RELEASE_IDBASE= N_MISS + 1;    // releaseIdBase = 17：entry source 起始 id
  localparam int PADDR_BITS    = 48;            // 物理地址宽度
  localparam int BLOCK_BITS    = 512;           // 一条 cacheline 比特数（blockBytes*8）
  localparam int BEAT_BITS     = 256;           // 每个 TL C beat 的数据宽度
  localparam int REFILL_CYCLES = BLOCK_BITS / BEAT_BITS; // = 2 个 beat
  localparam int MISS_CHK      = 5;             // miss_req_conflict_check 路数（LoadPipe3+MainPipe1+arb1）
  localparam int SRC_BITS      = 6;             // mem_release source 宽度
  localparam int IDX_BITS      = 5;             // $clog2(18) 向上取整后用 5 位表示 entry 下标足够

  // ---- TileLink C 通道写回 opcode（mem_release_bits_opcode）----
  //  entry 黑盒输出 opcode = {1'b1, voluntary, hasData}，故只可能是下面 4 种：
  //    ProbeAck=4(100)     ：被动 probe 应答，无数据（行是 clean 或仅降级权限）
  //    ProbeAckData=5(101) ：被动 probe 应答，带脏数据
  //    Release=6(110)      ：主动写回（自愿逐出），无数据
  //    ReleaseData=7(111)  ：主动写回，带脏数据
  //  voluntary（=opcode[1]）区分「主动 Release」与「被动 ProbeAck」：仅前者需等 ReleaseAck。
  //  hasData（=opcode[0]）即 numBeats-1，决定 robin 仲裁锁定 1 个还是 2 个 beat。
  typedef enum logic [2:0] {
    TLC_PROBE_ACK      = 3'd4,
    TLC_PROBE_ACK_DATA = 3'd5,
    TLC_RELEASE        = 3'd6,
    TLC_RELEASE_DATA   = 3'd7
  } tl_c_opcode_e;

  // 该 opcode 是否为「主动自愿写回」（voluntary）——opcode[1] 为 1。仅这类需等 D 通道 ack。
  function automatic logic opcode_is_voluntary(input logic [2:0] op);
    opcode_is_voluntary = op[1];
  endfunction
  typedef struct packed {
    logic                  valid;
    logic [2:0]            opcode;
    logic [2:0]            param;
    logic [2:0]            size;     // 固定 lgSize = log2(blockBytes) = 6
    logic [SRC_BITS-1:0]   source;   // = entry id
    logic [PADDR_BITS-1:0] address;
    logic [BEAT_BITS-1:0]  data;     // 当前 beat 的数据
    logic                  corrupt;
  } tl_c_t;

  // ---- 写回请求（io_req_bits，对应 Scala WritebackReq 去掉 data 的控制字段）----
  typedef struct packed {
    logic [2:0]            param;
    logic                  voluntary;
    logic                  hasData;
    logic                  corrupt;
    logic                  dirty;
    logic [PADDR_BITS-1:0] addr;
  } wb_req_ctrl_t;

  // ---------------------------------------------------------------------------
  //  纯函数：最低位优先编码（PriorityEncoderOH 等价）——把第一个为 1 的位做成 one-hot。
  //  用于「分配新 entry 给最低空闲下标」与 robin 仲裁里的优先选择。
  // ---------------------------------------------------------------------------
  function automatic logic [NR_ENTRY-1:0] lowest_one_oh(input logic [NR_ENTRY-1:0] v);
    logic found;
    lowest_one_oh = '0;
    found = 1'b0;
    for (int i = 0; i < NR_ENTRY; i++) begin
      if (v[i] && !found) begin
        lowest_one_oh[i] = 1'b1;
        found            = 1'b1;
      end
    end
  endfunction

  // ---------------------------------------------------------------------------
  //  纯函数：「从高位向低位」填充 1（rightOR），但移位步长上限为 cap（部分填充）。
  //  对应 Rocket util.rightOR(x, width, cap)：stop=min(width,cap)，
  //  helper 用 s=1,2,4,… < stop 反复 x |= (x>>s)。结果：bit i = OR(x[ min(i+cap-1,width-1) : i ])
  //  （即仅向下传播至多 cap 个位置的 OR）。robin 仲裁用 cap=N 来「环绕」屏蔽。
  // ---------------------------------------------------------------------------
  function automatic logic [2*NR_ENTRY-1:0] right_or_cap(input logic [2*NR_ENTRY-1:0] x);
    logic [2*NR_ENTRY-1:0] r;
    int s;
    r = x;
    s = 1;
    while (s < NR_ENTRY) begin    // stop = min(2N, N) = N
      r = r | (r >> s);
      s = s + s;
    end
    right_or_cap = r;
  endfunction

  // 「从低位向高位」填充 1（leftOR）：bit i = OR(x[i:0])。用于轮转 mask 的更新。
  function automatic logic [NR_ENTRY-1:0] left_or(input logic [NR_ENTRY-1:0] x);
    logic [NR_ENTRY-1:0] r;
    r = x;
    for (int s = 1; s < NR_ENTRY; s = s + s) r = r | (r << s);
    left_or = r;
  endfunction

  // ---------------------------------------------------------------------------
  //  纯函数：TileLink roundRobin 策略——给定「各端 valid」与「轮转屏蔽 mask」，
  //  算出本拍每端的 ready（policy 返回值，N 位）。winner = ready & valid。
  //
  //  完全照搬 Rocket TLArbiter.roundRobin（Arbiter.scala:20）：
  //    filter  = Cat(valid & ~mask, valid)                       // 2N 位
  //    unready = (rightOR(filter, 2N, N) >> 1) | (mask << N)      // 2N 位
  //    readys  = ~((unready >> N) & unready[N-1:0])               // N 位
  //  其中 mask 是「上次赢家及其低位」的屏蔽（每次授权后用 leftOR(winner) 更新），
  //  使下一次仲裁跳过上次赢家、实现公平轮转。
  // ---------------------------------------------------------------------------
  function automatic logic [NR_ENTRY-1:0] robin_readys(
      input logic [NR_ENTRY-1:0] valid,
      input logic [NR_ENTRY-1:0] mask);
    logic [2*NR_ENTRY-1:0] filter;
    logic [2*NR_ENTRY-1:0] unready;
    filter  = {(valid & ~mask), valid};
    unready = (right_or_cap(filter) >> 1)
            | ({{NR_ENTRY{1'b0}}, mask} << NR_ENTRY);
    robin_readys = ~((unready >> NR_ENTRY) & unready[NR_ENTRY-1:0]);
  endfunction

endpackage

// =============================================================================
//  WritebackQueue —— DCache 脏行写回队列（可读核 xs_WritebackQueue_core）
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel）：
//      src/main/scala/xiangshan/cache/dcache/mainpipe/WritebackQueue.scala
//  golden（firtool 生成，仅 UT/FM 对照）：golden/chisel-rtl/WritebackQueue.sv（1757 行）
//
//  本核重写「队列级」逻辑；每个 entry 的 3 态写回状态机封装在子模块 WritebackEntry
//  里（本工程当 golden 黑盒，UT/FM 两侧共用 golden 的 WritebackEntry / WritebackEntry_15）。
//  队列级逻辑分三部分：
//    (1) 分配 alloc：把新写回请求唯一地分给「最低空闲下标」的 entry（primary_valid one-hot）；
//        若新请求地址撞上在途 entry（block_conflict）则不收，保证同 block 写回顺序。
//    (2) miss 冲突探测：5 路 miss 请求地址若撞上在途 entry → 置 block_miss_req（阻塞该 miss）。
//    (3) 输出仲裁 TLArbiter.robin：把 18 个 entry 的 mem_release 轮转汇聚到单一 TL C 通道，
//        多 beat 突发期间锁定授权给同一 entry。
//
//  详见 docs/memblock/WritebackQueue.md。
// =============================================================================
import writebackqueue_pkg::*;


module xs_WritebackQueue_core (
  input  logic                  clock,
  input  logic                  reset,

  // ---- 上游：写回请求（来自 MainPipe）----
  output logic                  io_req_ready,
  input  logic                  io_req_valid,
  input  logic [2:0]            io_req_bits_param,
  input  logic                  io_req_bits_voluntary,
  input  logic                  io_req_bits_hasData,
  input  logic                  io_req_bits_corrupt,
  input  logic                  io_req_bits_dirty,
  input  logic [PADDR_BITS-1:0] io_req_bits_addr,
  input  logic [BLOCK_BITS-1:0] io_req_bits_data,

  // ---- 下游：TL C 通道（写回 L2，多 beat 突发）----
  input  logic                  io_mem_release_ready,
  output logic                  io_mem_release_valid,
  output logic [2:0]            io_mem_release_bits_opcode,
  output logic [2:0]            io_mem_release_bits_param,
  output logic [2:0]            io_mem_release_bits_size,
  output logic [SRC_BITS-1:0]   io_mem_release_bits_source,
  output logic [PADDR_BITS-1:0] io_mem_release_bits_address,
  output logic [BEAT_BITS-1:0]  io_mem_release_bits_data,
  output logic                  io_mem_release_bits_corrupt,

  // ---- 下游：TL D 通道（L2 回 ReleaseAck）----
  input  logic                  io_mem_grant_valid,
  input  logic [SRC_BITS-1:0]   io_mem_grant_bits_source,

  // ---- 旁路：5 路 miss 请求地址冲突探测 ----
  input  logic                       io_miss_req_conflict_check_0_valid,
  input  logic [PADDR_BITS-1:0]      io_miss_req_conflict_check_0_bits,
  input  logic                       io_miss_req_conflict_check_1_valid,
  input  logic [PADDR_BITS-1:0]      io_miss_req_conflict_check_1_bits,
  input  logic                       io_miss_req_conflict_check_2_valid,
  input  logic [PADDR_BITS-1:0]      io_miss_req_conflict_check_2_bits,
  input  logic                       io_miss_req_conflict_check_3_valid,
  input  logic [PADDR_BITS-1:0]      io_miss_req_conflict_check_3_bits,
  input  logic                       io_miss_req_conflict_check_4_valid,
  input  logic [PADDR_BITS-1:0]      io_miss_req_conflict_check_4_bits,
  output logic                       io_block_miss_req_0,
  output logic                       io_block_miss_req_1,
  output logic                       io_block_miss_req_2,
  output logic                       io_block_miss_req_3,
  output logic                       io_block_miss_req_4,

  // ---- perf（每路 2 拍打拍）----
  output logic [5:0]            io_perf_0_value,
  output logic [5:0]            io_perf_1_value,
  output logic [5:0]            io_perf_2_value,
  output logic [5:0]            io_perf_3_value,
  output logic [5:0]            io_perf_4_value
);

  // ===========================================================================
  //  entry 阵列接口线（与黑盒 WritebackEntry 的端口逐项对接）
  //  下游用数组聚合 golden 展平的 _entries_<i>_io_*，便于 for/genvar 归约。
  // ===========================================================================
  logic                  entry_req_valid;                 // 所有 entry 共享：req.valid & !block_conflict
  logic [NR_ENTRY-1:0]   entry_primary_valid;             // 每 entry 的 primary_valid（one-hot 分配）
  logic [NR_ENTRY-1:0]   entry_primary_ready;             // 每 entry 输出：是否空闲可收
  logic [NR_ENTRY-1:0]   entry_mem_grant_valid;           // 每 entry 的 mem_grant.valid（按 source 匹配）
  logic [NR_ENTRY-1:0]   entry_mem_release_ready;         // 仲裁给每 entry 的 ready
  logic [NR_ENTRY-1:0]   entry_rel_valid;                 // 每 entry 输出：mem_release.valid（busy）
  logic [2:0]            entry_rel_opcode  [NR_ENTRY];
  logic [2:0]            entry_rel_param   [NR_ENTRY];
  logic [SRC_BITS-1:0]   entry_rel_source  [NR_ENTRY];
  logic [PADDR_BITS-1:0] entry_rel_address [NR_ENTRY];
  logic [BEAT_BITS-1:0]  entry_rel_data    [NR_ENTRY];
  logic                  entry_rel_corrupt [NR_ENTRY];
  logic [NR_ENTRY-1:0]   entry_block_valid;               // 每 entry 输出：block_addr.valid（state!=invalid）
  logic [PADDR_BITS-1:0] entry_block_addr  [NR_ENTRY];

  // ===========================================================================
  //  (1) 分配 alloc + block 冲突
  // ===========================================================================
  //  block_conflict：新请求地址撞上任一在途 entry → 这拍不分配（等它写完，保证顺序）。
  logic [NR_ENTRY-1:0] block_hit_req;
  logic                block_conflict;
  for (genvar i = 0; i < NR_ENTRY; i++) begin : g_block_req
    assign block_hit_req[i] = entry_block_valid[i] &&
                              (entry_block_addr[i] == io_req_bits_addr);
  end
  assign block_conflict = |block_hit_req;

  //  alloc：只要有空闲 entry（任一 primary_ready）就可分配。
  logic alloc;
  assign alloc = |entry_primary_ready;

  //  req_ready：有空位且不冲突。
  assign io_req_ready    = alloc && !block_conflict;
  assign entry_req_valid = io_req_valid && !block_conflict;

  //  primary_valid（分配 one-hot）：选「最低下标的空闲 entry」收这条请求。
  //  = 该 entry 空闲 且 比它低的 entry 都不空闲。lowest_one_oh 直接给出这个 one-hot。
  assign entry_primary_valid = lowest_one_oh(entry_primary_ready);

  // ===========================================================================
  //  (2) miss 请求冲突探测（5 路）
  //  某 miss 请求地址若正被某 entry 写回 → block 它（避免读到尚未写回 L2 的旧行）。
  // ===========================================================================
  logic [MISS_CHK-1:0]      miss_chk_valid;
  logic [PADDR_BITS-1:0]    miss_chk_bits [MISS_CHK];
  logic [MISS_CHK-1:0]      block_miss_req;
  assign miss_chk_valid = {io_miss_req_conflict_check_4_valid,
                           io_miss_req_conflict_check_3_valid,
                           io_miss_req_conflict_check_2_valid,
                           io_miss_req_conflict_check_1_valid,
                           io_miss_req_conflict_check_0_valid};
  assign miss_chk_bits[0] = io_miss_req_conflict_check_0_bits;
  assign miss_chk_bits[1] = io_miss_req_conflict_check_1_bits;
  assign miss_chk_bits[2] = io_miss_req_conflict_check_2_bits;
  assign miss_chk_bits[3] = io_miss_req_conflict_check_3_bits;
  assign miss_chk_bits[4] = io_miss_req_conflict_check_4_bits;

  for (genvar m = 0; m < MISS_CHK; m++) begin : g_miss_chk
    logic [NR_ENTRY-1:0] hit;
    for (genvar i = 0; i < NR_ENTRY; i++) begin : g_per_entry
      assign hit[i] = entry_block_valid[i] && (entry_block_addr[i] == miss_chk_bits[m]);
    end
    assign block_miss_req[m] = miss_chk_valid[m] && (|hit);
  end
  assign {io_block_miss_req_4, io_block_miss_req_3, io_block_miss_req_2,
          io_block_miss_req_1, io_block_miss_req_0} = block_miss_req;

  // ===========================================================================
  //  延迟一拍的整行数据（对应 Scala req_data = RegEnable(req.data, req.valid)）
  //  减少扇出：data 写进 entry 比控制字段晚一拍。
  // ===========================================================================
  logic [BLOCK_BITS-1:0] req_data_data;
  always_ff @(posedge clock) begin
    if (io_req_valid) req_data_data <= io_req_bits_data;
  end

  // ===========================================================================
  //  (3) 输出仲裁：TLArbiter.robin（轮转优先 + 多 beat 锁定）
  //  详见 writebackqueue_pkg::robin_readys。这里维护两个时序状态：
  //    arb_mask     ：轮转屏蔽（上次赢家及其低位），保证公平轮转。
  //    arb_state    ：突发期间锁定的赢家（one-hot），多 beat 期间 sink 一直选它。
  //    arb_beatsleft：剩余 beat 数（本配置 1 位，因 numBeats1 = refillCycles-1 = 1）。
  // ===========================================================================
  logic [NR_ENTRY-1:0] arb_mask;
  logic [NR_ENTRY-1:0] arb_state;
  logic                arb_beatsleft;     // idle = !arb_beatsleft

  logic                arb_idle;
  logic                arb_latch;         // idle & sink.ready：新赢家这拍夺取 sink
  logic [NR_ENTRY-1:0] arb_readys;        // policy 返回的 ready（idle 时使用）
  logic [NR_ENTRY-1:0] arb_winner;        // readys & valid：本拍真正赢家
  logic [NR_ENTRY-1:0] arb_muxstate;      // idle ? winner : state，用于选 sink.bits
  logic [NR_ENTRY-1:0] arb_allowed;       // idle ? readys : state，用于反压各 entry
  logic                arb_sink_fire;

  assign arb_idle   = !arb_beatsleft;
  assign arb_latch  = arb_idle && io_mem_release_ready;
  assign arb_readys = robin_readys(entry_rel_valid, arb_mask);
  assign arb_winner = arb_readys & entry_rel_valid;
  assign arb_muxstate = arb_idle ? arb_winner : arb_state;
  assign arb_allowed  = arb_idle ? arb_readys : arb_state;

  //  各 entry 的 mem_release.ready：被授权且 sink ready。
  assign entry_mem_release_ready = {NR_ENTRY{io_mem_release_ready}} & arb_allowed;

  //  sink.valid：idle 时只要有任一 valid；突发时只看锁定赢家(state)的 valid（Mux1H）。
  logic any_valid, locked_valid;
  assign any_valid    = |entry_rel_valid;
  always_comb begin
    locked_valid = 1'b0;
    for (int i = 0; i < NR_ENTRY; i++)
      if (arb_state[i]) locked_valid = locked_valid | entry_rel_valid[i];
  end
  assign io_mem_release_valid = arb_idle ? any_valid : locked_valid;
  assign arb_sink_fire        = io_mem_release_valid && io_mem_release_ready;

  //  sink.bits = Mux1H(muxState, entry payloads)：选中赢家的 release 字段。
  //  size 固定 = log2(blockBytes) = 6（一整行）。
  always_comb begin
    io_mem_release_bits_opcode  = '0;
    io_mem_release_bits_param   = '0;
    io_mem_release_bits_source  = '0;
    io_mem_release_bits_address = '0;
    io_mem_release_bits_data    = '0;
    io_mem_release_bits_corrupt = 1'b0;
    for (int i = 0; i < NR_ENTRY; i++) begin
      if (arb_muxstate[i]) begin
        io_mem_release_bits_opcode  = io_mem_release_bits_opcode  | entry_rel_opcode[i];
        io_mem_release_bits_param   = io_mem_release_bits_param   | entry_rel_param[i];
        io_mem_release_bits_source  = io_mem_release_bits_source  | entry_rel_source[i];
        io_mem_release_bits_address = io_mem_release_bits_address | entry_rel_address[i];
        io_mem_release_bits_data    = io_mem_release_bits_data    | entry_rel_data[i];
        io_mem_release_bits_corrupt = io_mem_release_bits_corrupt | entry_rel_corrupt[i];
      end
    end
  end
  assign io_mem_release_bits_size = (|arb_muxstate) ? 3'h6 : 3'h0;

  // 当前授权 entry 的写回类型（仅供阅读/波形，按 tl_c_opcode_e 解读 opcode）。
  // 自愿写回（Release/ReleaseData）发完后需等 D 通道 ReleaseAck，被动 ProbeAck 不等——
  // 这一区分由 entry 黑盒内部据 opcode[1]=voluntary 处理。
  tl_c_opcode_e        sink_opcode;
  logic                sink_is_voluntary;
  assign sink_opcode       = tl_c_opcode_e'(io_mem_release_bits_opcode);
  assign sink_is_voluntary = opcode_is_voluntary(io_mem_release_bits_opcode);

  //  本拍赢家的「初始 beat 数」：numBeats1 = hasData ? 1 : 0 = opcode[0]。
  logic init_beats;
  always_comb begin
    init_beats = 1'b0;
    for (int i = 0; i < NR_ENTRY; i++)
      if (arb_winner[i]) init_beats = init_beats | entry_rel_opcode[i][0];
  end

  //  时序更新：beatsLeft / state / mask（对应 Scala 的 RegInit + when）。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      arb_beatsleft <= 1'b0;
      arb_mask      <= {NR_ENTRY{1'b1}};   // 复位时全 1（不屏蔽任何端）
      arb_state     <= '0;
    end else begin
      // beatsLeft：夺取（latch）时载入 initBeats；否则随 sink.fire 递减。
      if (arb_latch) arb_beatsleft <= init_beats;
      else           arb_beatsleft <= arb_beatsleft - arb_sink_fire;
      // state：仅 idle 时锁存本拍赢家（突发期间保持不变）。
      if (arb_idle) arb_state <= arb_winner;
      // mask：每次成功授权（latch 且有 valid）后，屏蔽「赢家及其低位」实现轮转。
      if (arb_latch && any_valid) arb_mask <= left_or(arb_winner & entry_rel_valid);
    end
  end

  // ===========================================================================
  //  perf：req 计数 + 在途 entry 数分桶（各打 2 拍，与 golden 一致）
  // ===========================================================================
  logic [4:0] perf_valid_count;
  logic       perf_req;
  logic [4:0] perf_valid_count_r;
  assign perf_req = io_req_ready && io_req_valid;

  always_comb begin
    perf_valid_count = '0;
    for (int i = 0; i < NR_ENTRY; i++)
      perf_valid_count = perf_valid_count + 5'(entry_block_valid[i]);
  end

  logic perf0_r, perf0_r1, perf1_r, perf1_r1, perf2_r, perf2_r1;
  logic perf3_r, perf3_r1, perf4_r, perf4_r1;
  always_ff @(posedge clock) begin
    perf_valid_count_r <= perf_valid_count;
    perf0_r  <= perf_req;                                              perf0_r1 <= perf0_r;
    perf1_r  <= perf_valid_count_r < 5'd4;                             perf1_r1 <= perf1_r;
    perf2_r  <= (perf_valid_count_r > 5'd4) && (perf_valid_count_r < 5'd10);  perf2_r1 <= perf2_r;
    perf3_r  <= (perf_valid_count_r > 5'd9) && (perf_valid_count_r < 5'd14);  perf3_r1 <= perf3_r;
    perf4_r  <= perf_valid_count_r > 5'd13;                            perf4_r1 <= perf4_r;
  end
  assign io_perf_0_value = {5'h0, perf0_r1};
  assign io_perf_1_value = {5'h0, perf1_r1};
  assign io_perf_2_value = {5'h0, perf2_r1};
  assign io_perf_3_value = {5'h0, perf3_r1};
  assign io_perf_4_value = {5'h0, perf4_r1};

  // ===========================================================================
  //  entry 阵列例化（WritebackEntry 黑盒）。前 15 个用 5 位 id 版（WritebackEntry），
  //  后 3 个（下标 15/16/17，id 32/33/34 超出 5 位）用 6 位 id 版 WritebackEntry_15。
  //  entry id = i + releaseIdBase；mem_grant 按 source==id 路由到对应 entry。
  //  实例名 entries_<i> 与 golden 逐一对齐（扁平命名），使 FM 结构匹配直接配对每个
  //  entry 子模块内部寄存器（含 golden 自身的对称死位 req_dirty/remain_dup_0[1]）。
  // ===========================================================================
  assign entry_mem_grant_valid[0] =
      (io_mem_grant_bits_source == SRC_BITS'(17)) && io_mem_grant_valid;
  WritebackEntry entries_0 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (5'(17)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[0]),
    .io_mem_release_valid        (entry_rel_valid[0]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[0]),
    .io_mem_release_bits_param   (entry_rel_param[0]),
    .io_mem_release_bits_source  (entry_rel_source[0]),
    .io_mem_release_bits_address (entry_rel_address[0]),
    .io_mem_release_bits_data    (entry_rel_data[0]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[0]),
    .io_mem_grant_valid          (entry_mem_grant_valid[0]),
    .io_primary_valid            (entry_primary_valid[0]),
    .io_primary_ready            (entry_primary_ready[0]),
    .io_block_addr_valid         (entry_block_valid[0]),
    .io_block_addr_bits          (entry_block_addr[0])
  );
  assign entry_mem_grant_valid[1] =
      (io_mem_grant_bits_source == SRC_BITS'(18)) && io_mem_grant_valid;
  WritebackEntry entries_1 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (5'(18)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[1]),
    .io_mem_release_valid        (entry_rel_valid[1]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[1]),
    .io_mem_release_bits_param   (entry_rel_param[1]),
    .io_mem_release_bits_source  (entry_rel_source[1]),
    .io_mem_release_bits_address (entry_rel_address[1]),
    .io_mem_release_bits_data    (entry_rel_data[1]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[1]),
    .io_mem_grant_valid          (entry_mem_grant_valid[1]),
    .io_primary_valid            (entry_primary_valid[1]),
    .io_primary_ready            (entry_primary_ready[1]),
    .io_block_addr_valid         (entry_block_valid[1]),
    .io_block_addr_bits          (entry_block_addr[1])
  );
  assign entry_mem_grant_valid[2] =
      (io_mem_grant_bits_source == SRC_BITS'(19)) && io_mem_grant_valid;
  WritebackEntry entries_2 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (5'(19)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[2]),
    .io_mem_release_valid        (entry_rel_valid[2]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[2]),
    .io_mem_release_bits_param   (entry_rel_param[2]),
    .io_mem_release_bits_source  (entry_rel_source[2]),
    .io_mem_release_bits_address (entry_rel_address[2]),
    .io_mem_release_bits_data    (entry_rel_data[2]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[2]),
    .io_mem_grant_valid          (entry_mem_grant_valid[2]),
    .io_primary_valid            (entry_primary_valid[2]),
    .io_primary_ready            (entry_primary_ready[2]),
    .io_block_addr_valid         (entry_block_valid[2]),
    .io_block_addr_bits          (entry_block_addr[2])
  );
  assign entry_mem_grant_valid[3] =
      (io_mem_grant_bits_source == SRC_BITS'(20)) && io_mem_grant_valid;
  WritebackEntry entries_3 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (5'(20)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[3]),
    .io_mem_release_valid        (entry_rel_valid[3]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[3]),
    .io_mem_release_bits_param   (entry_rel_param[3]),
    .io_mem_release_bits_source  (entry_rel_source[3]),
    .io_mem_release_bits_address (entry_rel_address[3]),
    .io_mem_release_bits_data    (entry_rel_data[3]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[3]),
    .io_mem_grant_valid          (entry_mem_grant_valid[3]),
    .io_primary_valid            (entry_primary_valid[3]),
    .io_primary_ready            (entry_primary_ready[3]),
    .io_block_addr_valid         (entry_block_valid[3]),
    .io_block_addr_bits          (entry_block_addr[3])
  );
  assign entry_mem_grant_valid[4] =
      (io_mem_grant_bits_source == SRC_BITS'(21)) && io_mem_grant_valid;
  WritebackEntry entries_4 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (5'(21)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[4]),
    .io_mem_release_valid        (entry_rel_valid[4]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[4]),
    .io_mem_release_bits_param   (entry_rel_param[4]),
    .io_mem_release_bits_source  (entry_rel_source[4]),
    .io_mem_release_bits_address (entry_rel_address[4]),
    .io_mem_release_bits_data    (entry_rel_data[4]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[4]),
    .io_mem_grant_valid          (entry_mem_grant_valid[4]),
    .io_primary_valid            (entry_primary_valid[4]),
    .io_primary_ready            (entry_primary_ready[4]),
    .io_block_addr_valid         (entry_block_valid[4]),
    .io_block_addr_bits          (entry_block_addr[4])
  );
  assign entry_mem_grant_valid[5] =
      (io_mem_grant_bits_source == SRC_BITS'(22)) && io_mem_grant_valid;
  WritebackEntry entries_5 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (5'(22)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[5]),
    .io_mem_release_valid        (entry_rel_valid[5]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[5]),
    .io_mem_release_bits_param   (entry_rel_param[5]),
    .io_mem_release_bits_source  (entry_rel_source[5]),
    .io_mem_release_bits_address (entry_rel_address[5]),
    .io_mem_release_bits_data    (entry_rel_data[5]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[5]),
    .io_mem_grant_valid          (entry_mem_grant_valid[5]),
    .io_primary_valid            (entry_primary_valid[5]),
    .io_primary_ready            (entry_primary_ready[5]),
    .io_block_addr_valid         (entry_block_valid[5]),
    .io_block_addr_bits          (entry_block_addr[5])
  );
  assign entry_mem_grant_valid[6] =
      (io_mem_grant_bits_source == SRC_BITS'(23)) && io_mem_grant_valid;
  WritebackEntry entries_6 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (5'(23)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[6]),
    .io_mem_release_valid        (entry_rel_valid[6]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[6]),
    .io_mem_release_bits_param   (entry_rel_param[6]),
    .io_mem_release_bits_source  (entry_rel_source[6]),
    .io_mem_release_bits_address (entry_rel_address[6]),
    .io_mem_release_bits_data    (entry_rel_data[6]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[6]),
    .io_mem_grant_valid          (entry_mem_grant_valid[6]),
    .io_primary_valid            (entry_primary_valid[6]),
    .io_primary_ready            (entry_primary_ready[6]),
    .io_block_addr_valid         (entry_block_valid[6]),
    .io_block_addr_bits          (entry_block_addr[6])
  );
  assign entry_mem_grant_valid[7] =
      (io_mem_grant_bits_source == SRC_BITS'(24)) && io_mem_grant_valid;
  WritebackEntry entries_7 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (5'(24)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[7]),
    .io_mem_release_valid        (entry_rel_valid[7]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[7]),
    .io_mem_release_bits_param   (entry_rel_param[7]),
    .io_mem_release_bits_source  (entry_rel_source[7]),
    .io_mem_release_bits_address (entry_rel_address[7]),
    .io_mem_release_bits_data    (entry_rel_data[7]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[7]),
    .io_mem_grant_valid          (entry_mem_grant_valid[7]),
    .io_primary_valid            (entry_primary_valid[7]),
    .io_primary_ready            (entry_primary_ready[7]),
    .io_block_addr_valid         (entry_block_valid[7]),
    .io_block_addr_bits          (entry_block_addr[7])
  );
  assign entry_mem_grant_valid[8] =
      (io_mem_grant_bits_source == SRC_BITS'(25)) && io_mem_grant_valid;
  WritebackEntry entries_8 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (5'(25)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[8]),
    .io_mem_release_valid        (entry_rel_valid[8]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[8]),
    .io_mem_release_bits_param   (entry_rel_param[8]),
    .io_mem_release_bits_source  (entry_rel_source[8]),
    .io_mem_release_bits_address (entry_rel_address[8]),
    .io_mem_release_bits_data    (entry_rel_data[8]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[8]),
    .io_mem_grant_valid          (entry_mem_grant_valid[8]),
    .io_primary_valid            (entry_primary_valid[8]),
    .io_primary_ready            (entry_primary_ready[8]),
    .io_block_addr_valid         (entry_block_valid[8]),
    .io_block_addr_bits          (entry_block_addr[8])
  );
  assign entry_mem_grant_valid[9] =
      (io_mem_grant_bits_source == SRC_BITS'(26)) && io_mem_grant_valid;
  WritebackEntry entries_9 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (5'(26)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[9]),
    .io_mem_release_valid        (entry_rel_valid[9]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[9]),
    .io_mem_release_bits_param   (entry_rel_param[9]),
    .io_mem_release_bits_source  (entry_rel_source[9]),
    .io_mem_release_bits_address (entry_rel_address[9]),
    .io_mem_release_bits_data    (entry_rel_data[9]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[9]),
    .io_mem_grant_valid          (entry_mem_grant_valid[9]),
    .io_primary_valid            (entry_primary_valid[9]),
    .io_primary_ready            (entry_primary_ready[9]),
    .io_block_addr_valid         (entry_block_valid[9]),
    .io_block_addr_bits          (entry_block_addr[9])
  );
  assign entry_mem_grant_valid[10] =
      (io_mem_grant_bits_source == SRC_BITS'(27)) && io_mem_grant_valid;
  WritebackEntry entries_10 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (5'(27)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[10]),
    .io_mem_release_valid        (entry_rel_valid[10]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[10]),
    .io_mem_release_bits_param   (entry_rel_param[10]),
    .io_mem_release_bits_source  (entry_rel_source[10]),
    .io_mem_release_bits_address (entry_rel_address[10]),
    .io_mem_release_bits_data    (entry_rel_data[10]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[10]),
    .io_mem_grant_valid          (entry_mem_grant_valid[10]),
    .io_primary_valid            (entry_primary_valid[10]),
    .io_primary_ready            (entry_primary_ready[10]),
    .io_block_addr_valid         (entry_block_valid[10]),
    .io_block_addr_bits          (entry_block_addr[10])
  );
  assign entry_mem_grant_valid[11] =
      (io_mem_grant_bits_source == SRC_BITS'(28)) && io_mem_grant_valid;
  WritebackEntry entries_11 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (5'(28)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[11]),
    .io_mem_release_valid        (entry_rel_valid[11]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[11]),
    .io_mem_release_bits_param   (entry_rel_param[11]),
    .io_mem_release_bits_source  (entry_rel_source[11]),
    .io_mem_release_bits_address (entry_rel_address[11]),
    .io_mem_release_bits_data    (entry_rel_data[11]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[11]),
    .io_mem_grant_valid          (entry_mem_grant_valid[11]),
    .io_primary_valid            (entry_primary_valid[11]),
    .io_primary_ready            (entry_primary_ready[11]),
    .io_block_addr_valid         (entry_block_valid[11]),
    .io_block_addr_bits          (entry_block_addr[11])
  );
  assign entry_mem_grant_valid[12] =
      (io_mem_grant_bits_source == SRC_BITS'(29)) && io_mem_grant_valid;
  WritebackEntry entries_12 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (5'(29)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[12]),
    .io_mem_release_valid        (entry_rel_valid[12]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[12]),
    .io_mem_release_bits_param   (entry_rel_param[12]),
    .io_mem_release_bits_source  (entry_rel_source[12]),
    .io_mem_release_bits_address (entry_rel_address[12]),
    .io_mem_release_bits_data    (entry_rel_data[12]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[12]),
    .io_mem_grant_valid          (entry_mem_grant_valid[12]),
    .io_primary_valid            (entry_primary_valid[12]),
    .io_primary_ready            (entry_primary_ready[12]),
    .io_block_addr_valid         (entry_block_valid[12]),
    .io_block_addr_bits          (entry_block_addr[12])
  );
  assign entry_mem_grant_valid[13] =
      (io_mem_grant_bits_source == SRC_BITS'(30)) && io_mem_grant_valid;
  WritebackEntry entries_13 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (5'(30)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[13]),
    .io_mem_release_valid        (entry_rel_valid[13]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[13]),
    .io_mem_release_bits_param   (entry_rel_param[13]),
    .io_mem_release_bits_source  (entry_rel_source[13]),
    .io_mem_release_bits_address (entry_rel_address[13]),
    .io_mem_release_bits_data    (entry_rel_data[13]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[13]),
    .io_mem_grant_valid          (entry_mem_grant_valid[13]),
    .io_primary_valid            (entry_primary_valid[13]),
    .io_primary_ready            (entry_primary_ready[13]),
    .io_block_addr_valid         (entry_block_valid[13]),
    .io_block_addr_bits          (entry_block_addr[13])
  );
  assign entry_mem_grant_valid[14] =
      (io_mem_grant_bits_source == SRC_BITS'(31)) && io_mem_grant_valid;
  WritebackEntry entries_14 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (5'(31)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[14]),
    .io_mem_release_valid        (entry_rel_valid[14]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[14]),
    .io_mem_release_bits_param   (entry_rel_param[14]),
    .io_mem_release_bits_source  (entry_rel_source[14]),
    .io_mem_release_bits_address (entry_rel_address[14]),
    .io_mem_release_bits_data    (entry_rel_data[14]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[14]),
    .io_mem_grant_valid          (entry_mem_grant_valid[14]),
    .io_primary_valid            (entry_primary_valid[14]),
    .io_primary_ready            (entry_primary_ready[14]),
    .io_block_addr_valid         (entry_block_valid[14]),
    .io_block_addr_bits          (entry_block_addr[14])
  );
  assign entry_mem_grant_valid[15] =
      (io_mem_grant_bits_source == SRC_BITS'(32)) && io_mem_grant_valid;
  WritebackEntry_15 entries_15 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (6'(32)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[15]),
    .io_mem_release_valid        (entry_rel_valid[15]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[15]),
    .io_mem_release_bits_param   (entry_rel_param[15]),
    .io_mem_release_bits_source  (entry_rel_source[15]),
    .io_mem_release_bits_address (entry_rel_address[15]),
    .io_mem_release_bits_data    (entry_rel_data[15]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[15]),
    .io_mem_grant_valid          (entry_mem_grant_valid[15]),
    .io_primary_valid            (entry_primary_valid[15]),
    .io_primary_ready            (entry_primary_ready[15]),
    .io_block_addr_valid         (entry_block_valid[15]),
    .io_block_addr_bits          (entry_block_addr[15])
  );
  assign entry_mem_grant_valid[16] =
      (io_mem_grant_bits_source == SRC_BITS'(33)) && io_mem_grant_valid;
  WritebackEntry_15 entries_16 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (6'(33)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[16]),
    .io_mem_release_valid        (entry_rel_valid[16]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[16]),
    .io_mem_release_bits_param   (entry_rel_param[16]),
    .io_mem_release_bits_source  (entry_rel_source[16]),
    .io_mem_release_bits_address (entry_rel_address[16]),
    .io_mem_release_bits_data    (entry_rel_data[16]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[16]),
    .io_mem_grant_valid          (entry_mem_grant_valid[16]),
    .io_primary_valid            (entry_primary_valid[16]),
    .io_primary_ready            (entry_primary_ready[16]),
    .io_block_addr_valid         (entry_block_valid[16]),
    .io_block_addr_bits          (entry_block_addr[16])
  );
  assign entry_mem_grant_valid[17] =
      (io_mem_grant_bits_source == SRC_BITS'(34)) && io_mem_grant_valid;
  WritebackEntry_15 entries_17 (
    .clock                       (clock),
    .reset                       (reset),
    .io_id                       (6'(34)),
    .io_req_valid                (entry_req_valid),
    .io_req_bits_param           (io_req_bits_param),
    .io_req_bits_voluntary       (io_req_bits_voluntary),
    .io_req_bits_hasData         (io_req_bits_hasData),
    .io_req_bits_corrupt         (io_req_bits_corrupt),
    .io_req_bits_dirty           (io_req_bits_dirty),
    .io_req_bits_addr            (io_req_bits_addr),
    .io_req_data_data            (req_data_data),
    .io_mem_release_ready        (entry_mem_release_ready[17]),
    .io_mem_release_valid        (entry_rel_valid[17]),
    .io_mem_release_bits_opcode  (entry_rel_opcode[17]),
    .io_mem_release_bits_param   (entry_rel_param[17]),
    .io_mem_release_bits_source  (entry_rel_source[17]),
    .io_mem_release_bits_address (entry_rel_address[17]),
    .io_mem_release_bits_data    (entry_rel_data[17]),
    .io_mem_release_bits_corrupt (entry_rel_corrupt[17]),
    .io_mem_grant_valid          (entry_mem_grant_valid[17]),
    .io_primary_valid            (entry_primary_valid[17]),
    .io_primary_ready            (entry_primary_ready[17]),
    .io_block_addr_valid         (entry_block_valid[17]),
    .io_block_addr_bits          (entry_block_addr[17])
  );

endmodule

// 自动生成：scripts/gen_writebackqueue.py —— 勿手改

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module WritebackQueue(
  input  clock,
  input  reset,
  output io_req_ready,
  input  io_req_valid,
  input  [2:0] io_req_bits_param,
  input  io_req_bits_voluntary,
  input  io_req_bits_hasData,
  input  io_req_bits_corrupt,
  input  io_req_bits_dirty,
  input  [47:0] io_req_bits_addr,
  input  [511:0] io_req_bits_data,
  input  io_mem_release_ready,
  output io_mem_release_valid,
  output [2:0] io_mem_release_bits_opcode,
  output [2:0] io_mem_release_bits_param,
  output [2:0] io_mem_release_bits_size,
  output [5:0] io_mem_release_bits_source,
  output [47:0] io_mem_release_bits_address,
  output [255:0] io_mem_release_bits_data,
  output io_mem_release_bits_corrupt,
  input  io_mem_grant_valid,
  input  [5:0] io_mem_grant_bits_source,
  input  io_miss_req_conflict_check_0_valid,
  input  [47:0] io_miss_req_conflict_check_0_bits,
  input  io_miss_req_conflict_check_1_valid,
  input  [47:0] io_miss_req_conflict_check_1_bits,
  input  io_miss_req_conflict_check_2_valid,
  input  [47:0] io_miss_req_conflict_check_2_bits,
  input  io_miss_req_conflict_check_3_valid,
  input  [47:0] io_miss_req_conflict_check_3_bits,
  input  io_miss_req_conflict_check_4_valid,
  input  [47:0] io_miss_req_conflict_check_4_bits,
  output io_block_miss_req_0,
  output io_block_miss_req_1,
  output io_block_miss_req_2,
  output io_block_miss_req_3,
  output io_block_miss_req_4,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value,
  output [5:0] io_perf_4_value
);
  xs_WritebackQueue_core u_core (
    .clock(clock),
    .reset(reset),
    .io_req_ready(io_req_ready),
    .io_req_valid(io_req_valid),
    .io_req_bits_param(io_req_bits_param),
    .io_req_bits_voluntary(io_req_bits_voluntary),
    .io_req_bits_hasData(io_req_bits_hasData),
    .io_req_bits_corrupt(io_req_bits_corrupt),
    .io_req_bits_dirty(io_req_bits_dirty),
    .io_req_bits_addr(io_req_bits_addr),
    .io_req_bits_data(io_req_bits_data),
    .io_mem_release_ready(io_mem_release_ready),
    .io_mem_release_valid(io_mem_release_valid),
    .io_mem_release_bits_opcode(io_mem_release_bits_opcode),
    .io_mem_release_bits_param(io_mem_release_bits_param),
    .io_mem_release_bits_size(io_mem_release_bits_size),
    .io_mem_release_bits_source(io_mem_release_bits_source),
    .io_mem_release_bits_address(io_mem_release_bits_address),
    .io_mem_release_bits_data(io_mem_release_bits_data),
    .io_mem_release_bits_corrupt(io_mem_release_bits_corrupt),
    .io_mem_grant_valid(io_mem_grant_valid),
    .io_mem_grant_bits_source(io_mem_grant_bits_source),
    .io_miss_req_conflict_check_0_valid(io_miss_req_conflict_check_0_valid),
    .io_miss_req_conflict_check_0_bits(io_miss_req_conflict_check_0_bits),
    .io_miss_req_conflict_check_1_valid(io_miss_req_conflict_check_1_valid),
    .io_miss_req_conflict_check_1_bits(io_miss_req_conflict_check_1_bits),
    .io_miss_req_conflict_check_2_valid(io_miss_req_conflict_check_2_valid),
    .io_miss_req_conflict_check_2_bits(io_miss_req_conflict_check_2_bits),
    .io_miss_req_conflict_check_3_valid(io_miss_req_conflict_check_3_valid),
    .io_miss_req_conflict_check_3_bits(io_miss_req_conflict_check_3_bits),
    .io_miss_req_conflict_check_4_valid(io_miss_req_conflict_check_4_valid),
    .io_miss_req_conflict_check_4_bits(io_miss_req_conflict_check_4_bits),
    .io_block_miss_req_0(io_block_miss_req_0),
    .io_block_miss_req_1(io_block_miss_req_1),
    .io_block_miss_req_2(io_block_miss_req_2),
    .io_block_miss_req_3(io_block_miss_req_3),
    .io_block_miss_req_4(io_block_miss_req_4),
    .io_perf_0_value(io_perf_0_value),
    .io_perf_1_value(io_perf_1_value),
    .io_perf_2_value(io_perf_2_value),
    .io_perf_3_value(io_perf_3_value),
    .io_perf_4_value(io_perf_4_value)
  );
endmodule
