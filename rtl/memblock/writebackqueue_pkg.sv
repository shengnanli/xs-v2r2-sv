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
