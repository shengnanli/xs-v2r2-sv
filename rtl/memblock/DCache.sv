// ============================================================================
// xs_DCache_core —— L1 数据缓存内层集成/互联层（香山 V2R2 KunmingHu）
// ----------------------------------------------------------------------------
// 设计意图来源（人写 Chisel）：
//   src/main/scala/xiangshan/cache/dcache/DCacheWrapper.scala  class DCacheImp
//   替换器算法：rocket-chip util/Replacement.scala（SetAssocLRU + PseudoLRU(4)）
//
// 本层是 L1 DCache 的**集成核**：把 30+ 个功能子模块拼成完整 L1 DCache，
// 自身不含命中判定/流水算法（那些在 LoadPipe/StorePipe/MainPipe 等子模块里），
// 只做 **路由 / 仲裁 / 阵列读写分发 / MSHR 接线 / 一致性接线 / 替换算法 / 寄存输出**。
//
//   上游            子模块（黑盒）                        下游
//   ┌────────┐   ┌──────────────────────────────────┐
//   │load×3  │──▶│ ldu_0..2 (LoadPipe)               │
//   │sta×2   │──▶│ stu_0..1 (StorePipe)              │   meta/tag/data 阵列
//   │store   │──▶│ mainPipe (MainPipe)  ────读/写───▶│  metaArray/errorArray/
//   │atomics │──▶│                                   │  prefetchArray/accessArray/
//   └────────┘   │ missQueue ─ A/E ─▶ L2             │  tagArray/bankedDataArray
//                │ wb        ─ C ──▶ L2             │
//   L2 ─ B/D ──▶│ probeQueue                        │   各 Arbiter / Monitor /
//                │ bloomFilter/counterFilter         │   BloomFilter/CounterFilter/
//                └──────────────────────────────────┘   TreeArbiter/MissReadyGen/CtrlUnit
//
// 集成核里**真正可读重写**的设计逻辑（取代 golden 展平的 7000+ 行 always / 4000 wire）：
//   §A setplru 替换器：256 组 × 4 路 Tree-PLRU，4 个 touch 端口（ldu0/1/2/mainPipe）。
//      用 dcache_pkg 的 plru_* 纯函数 + genvar 表达；victim 仅供 mainPipe 查询。
//   §B perf 计数 2 级打拍：32 路统一 genvar。
// 其余为子模块互联 / TL-edge 拍数跟踪 / 错误聚合 / 原子&release 寄存等机械接线，
// 由 scripts/gen_dcache.py 从 golden 复刻进 dcache_*.svh（无 DCache 设计决策）。
//
// 子模块在 UT/FM 两侧均为黑盒（dcache_stub.sv），本核只验证集成层等价。
// ============================================================================
module xs_DCache_core
  import dcache_pkg::*;
(
  `include "dcache_ports.svh"
);

  // ==========================================================================
  // 0. 子模块输出网 / 中间互联网 / 机械寄存器声明（生成，纯接线）
  // ==========================================================================
  `include "dcache_regs.svh"   // 错误聚合 / 原子响应 / release / TL-edge 拍数等寄存器
  `include "dcache_nets.svh"   // 子模块输出网 + 中间组合网（含 error_valid 等，引用上面的 reg）

  // ==========================================================================
  // §A. setplru 替换器（256 组 × 4 路 Tree-PLRU）
  // --------------------------------------------------------------------------
  // 每组维护 3 bit Tree-PLRU 状态 state_vec[set]。
  //   * 查询（way）：MainPipe 需要替换某组时，按当前 PLRU 状态译出 victim way。
  //     golden 里 ldu/stu 的 replace_way.way 是死端口（不被消费），故只接 mainPipe。
  //   * 更新（touch/access）：每个命中/分配的流水级访问一组，把被访 way 标记为最近，
  //     翻转指向它的各级树节点。一拍内 4 个端口（ldu0/1/2/mainPipe）可能同时访问，
  //     对每组按端口顺序折叠（后者优先，与 Chisel foldLeft 一致），仅当该端口
  //     valid 且其 set 等于本组时生效。
  // 这正是 SetAssocLRU.access(sets, touch_ways) / way(set) 的可读实现。
  // ==========================================================================

  // 每组 3 bit PLRU 状态：复位清零（与 RegInit(0) 一致）
  plru_state_t state_vec [DCacheSets];

  // 4 个 touch 端口的 (valid, set, way)，顺序固定 ldu0/1/2/mainPipe
  logic     [REPL_TOUCH_PORTS-1:0]               touch_valid;
  logic     [REPL_TOUCH_PORTS-1:0][SET_IDX_W-1:0] touch_set;
  way_idx_t [REPL_TOUCH_PORTS-1:0]               touch_way;

  assign touch_valid = {_mainPipe_io_replace_access_valid,
                        _ldu_2_io_replace_access_valid,
                        _ldu_1_io_replace_access_valid,
                        _ldu_0_io_replace_access_valid};
  assign touch_set   = {_mainPipe_io_replace_access_bits_set,
                        _ldu_2_io_replace_access_bits_set,
                        _ldu_1_io_replace_access_bits_set,
                        _ldu_0_io_replace_access_bits_set};
  assign touch_way   = {_mainPipe_io_replace_access_bits_way,
                        _ldu_2_io_replace_access_bits_way,
                        _ldu_1_io_replace_access_bits_way,
                        _ldu_0_io_replace_access_bits_way};

  // 每组：聚合本组 touch 序列 + 折叠出 next state
  for (genvar s = 0; s < DCacheSets; s++) begin : g_replacer
    repl_touch_t set_touch [REPL_TOUCH_PORTS];
    logic        set_hit;   // 本组本拍是否有任意端口访问

    for (genvar p = 0; p < REPL_TOUCH_PORTS; p++) begin : g_touch
      assign set_touch[p].valid = touch_valid[p] & (touch_set[p] == s[SET_IDX_W-1:0]);
      assign set_touch[p].way   = touch_way[p];
    end
    assign set_hit = |{set_touch[3].valid, set_touch[2].valid,
                       set_touch[1].valid, set_touch[0].valid};

    // 与 golden 一致：state_vec 用异步复位（在 always @(posedge clk or posedge reset)
    // 块里），复位清零后按本组 touch 序列折叠更新。
    always_ff @(posedge clock or posedge reset) begin
      if (reset)        state_vec[s] <= '0;
      else if (set_hit) state_vec[s] <= plru_fold_touches(state_vec[s], set_touch);
    end
  end

  // MainPipe 的 victim 查询：取其 replace_way_set_bits 指定组的 PLRU 状态译 way。
  // （组索引可能在某些拍未驱动而为 X；用 mux 兜底避免 array[X] 恒 X 传播。）
  way_idx_t mainpipe_replace_way;
  assign mainpipe_replace_way =
      plru_replace_way(state_vec[_mainPipe_io_replace_way_set_bits]);

  // ==========================================================================
  // §B. perf 计数 2 级打拍（32 路）
  // --------------------------------------------------------------------------
  // 各子模块吐出的 perf 事件计数先汇聚成 perf_raw[]（生成的源映射），再统一打两拍
  // 对外输出，避免长扇出影响时序（与 DCacheWrapper/LsqWrapper perf 同一做法）。
  // ==========================================================================
  logic [PERF_W-1:0] perf_raw    [NUM_PERF_EVENTS];
  logic [PERF_W-1:0] perf_stage1 [NUM_PERF_EVENTS];
  logic [PERF_W-1:0] perf_stage2 [NUM_PERF_EVENTS];

  `include "dcache_perf_src.svh"  // assign perf_raw[i] = _<inst>_io_perf_k_value;

  for (genvar i = 0; i < NUM_PERF_EVENTS; i++) begin : g_perf
    always_ff @(posedge clock) begin
      perf_stage1[i] <= perf_raw[i];
      perf_stage2[i] <= perf_stage1[i];
    end
  end
  `include "dcache_perf_out.svh"  // assign io_perf_<i>_value = perf_stage2[i];

  // ==========================================================================
  // 1. 机械互联：寄存 always 块 + assign 别名 + 32 个子模块实例（生成）
  // ==========================================================================
  `include "dcache_glue_ff.svh"      // 错误聚合 / 原子响应 / release / TL-edge 拍数寄存
  `include "dcache_glue_assign.svh"  // 顶层 assign 互联别名
  `include "dcache_inst.svh"         // 32 个子模块实例

endmodule
