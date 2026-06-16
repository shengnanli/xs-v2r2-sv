// ============================================================================
// dcache_pkg —— L1 DCache 顶层集成（xs_DCache_core）的公共参数 / 类型 / 函数
// ----------------------------------------------------------------------------
// 设计意图来源（人写 Chisel）：
//   src/main/scala/xiangshan/cache/dcache/DCacheWrapper.scala  class DCacheImp
//   replacer 算法：rocket-chip util/Replacement.scala
//     ReplacementPolicy.fromString("setplru", nWays=4, nSets=256)
//       => SetAssocLRU(256, 4, "plru") —— 每组一棵 4 路 Tree-PLRU，组间独立
//
// 本包仅承载 DCache **集成层**自身的可读逻辑所需的参数与纯函数：
//   * 固化的本配置参数（KunmingHu V2R2）：3 路 load / 2 路 store / 4 way / 256 set ...
//   * setplru 替换器的 PLRU 译码 / 更新纯函数（way 查询、touch 更新）
//   * 集成层用到的若干小 enum（TileLink D 通道路由、错误聚合等）
//
// 注意：DCache 集成层把 30+ 个子模块（LoadPipe/StorePipe/MainPipe/MissQueue/
// WritebackQueue/ProbeQueue/各阵列/各 Arbiter/Monitor/CtrlUnit/BloomFilter/
// CounterFilter/TreeArbiter/MissReadyGen）拼起来；这些子模块在 UT/FM 两侧均为
// **黑盒**。本层只做路由 / 仲裁 / 寄存 / 替换算法等 glue 逻辑。
// ============================================================================
package dcache_pkg;

  // --------------------------------------------------------------------------
  // 固化参数（本配置 KunmingHu V2R2）
  // --------------------------------------------------------------------------
  localparam int LoadPipelineWidth  = 3;   // ldu_0..2
  localparam int StorePipelineWidth = 2;   // stu_0..1
  localparam int DCacheBanks        = 8;   // 8 bank（data array 写复制 8 份）
  localparam int DCacheWays         = 4;   // 4 way（way_en 4 bit, way idx 2 bit）
  localparam int DCacheSets         = 256; // 256 set（set idx 8 bit）

  // setplru 替换器：4 路 Tree-PLRU，每组 3 bit 状态（nBits = nWays-1）
  localparam int PLRU_NWAYS  = DCacheWays;          // 4
  localparam int PLRU_BITS   = PLRU_NWAYS - 1;      // 3
  localparam int PLRU_WAY_W  = 2;                   // log2(4)
  localparam int SET_IDX_W   = 8;                   // log2(256)

  // 替换器 touch（access）端口数：本配置实际接入的是 ldu_0..2 + mainPipe = 4
  // （Scala 里 stu 也在 replAccessReqs 列表中，但 StorePipe 在本配置未驱动 replace_access，
  //   firtool 把它们消解为常量；故 state_vec 更新只折叠这 4 个端口，顺序 ldu0/1/2/mainPipe。）
  localparam int REPL_TOUCH_PORTS = LoadPipelineWidth + 1; // 4

  // perf 事件数 / 单值位宽（与 DCacheWrapper 一致）
  localparam int NUM_PERF_EVENTS = 32;
  localparam int PERF_W          = 6;

  // --------------------------------------------------------------------------
  // 4 路 Tree-PLRU 状态（3 bit）含义（见 rocket-chip PseudoLRU 注释）
  //   state[2] : ways {3,2} 比 ways {1,0} 更老（更该被替换）
  //   state[1] : way 3 比 way 2 更老
  //   state[0] : way 1 比 way 0 更老
  // way 编码 2 bit：way[1] 选左右子树（1=高半 {3,2}），way[0] 选子树内单路。
  // --------------------------------------------------------------------------
  typedef logic [PLRU_BITS-1:0]  plru_state_t;   // 单组 PLRU 状态
  typedef logic [PLRU_WAY_W-1:0] way_idx_t;       // way 编码

  // 一个 touch（替换访问）请求：valid + 命中/分配的 way
  typedef struct packed {
    logic     valid;
    way_idx_t way;
  } repl_touch_t;

  // ------------------------------------------------------------------------
  // PLRU 查询：由当前组状态译出“最该替换”的 way（victim）。
  //   way[1] = state[2]                       （先看高半还是低半子树更老）
  //   way[0] = state[2] ? state[1] : state[0] （再看选中子树内哪一路更老）
  // 直接对应 get_replace_way(state, 4) 的递归展开。
  // ------------------------------------------------------------------------
  function automatic way_idx_t plru_replace_way(input plru_state_t s);
    plru_replace_way = {s[2], s[2] ? s[1] : s[0]};
  endfunction

  // ------------------------------------------------------------------------
  // PLRU 单次 touch 更新：访问了 way 后，把该 way 标记为“最近使用”，即把指向它的
  // 各级树节点位翻向另一侧。对应 get_next_state(state, way, 4) 的递归展开。
  //   位含义：state[2]=高半{3,2}比低半{1,0}更老；state[1]=way3 比 way2 更老（高半叶）；
  //           state[0]=way1 比 way0 更老（低半叶）。way[1]=1 选高半子树。
  //   本节点：访问哪半，则把“另一半更老”记下 -> 新 state[2] = ~way[1]。
  //   叶子：只更新被访问那半子树的叶位 = ~way[0]；另一半叶位保持。
  //     访问高半(way[1]=1)：更新 state[1]（=~way[0]），state[0] 保持。
  //     访问低半(way[1]=0)：更新 state[0]（=~way[0]），state[1] 保持。
  // （注：与 golden _state_vec_*_T_3/_T_7 逐位一致。）
  // ------------------------------------------------------------------------
  function automatic plru_state_t plru_next_state(input plru_state_t s,
                                                  input way_idx_t   way);
    plru_state_t n;
    n[2] = ~way[1];                            // 本节点：另一半变“更老”
    n[1] = (way[1] == 1'b1) ? ~way[0] : s[1];  // 高半叶：仅访问高半时更新
    n[0] = (way[1] == 1'b0) ? ~way[0] : s[0];  // 低半叶：仅访问低半时更新
    return n;
  endfunction

  // ------------------------------------------------------------------------
  // 多端口 touch 折叠：一拍内多个流水级可能访问同一组（同一 set），按端口顺序
  // 依次 fold（后者覆盖前者，与 Chisel foldLeft 的优先级一致）。仅对“valid 且
  // 命中本 set”的端口生效。
  //   对应 SetAssocLRU.access(sets, touch_ways)：每组聚合本组的 touch 序列，
  //   再 get_next_state(state, Seq) = foldLeft(Mux(valid, next, prev))。
  // 这里 touch[i].valid 已在外部与“set 匹配”相与。
  // ------------------------------------------------------------------------
  function automatic plru_state_t plru_fold_touches
      (input plru_state_t s, input repl_touch_t touch [REPL_TOUCH_PORTS]);
    plru_state_t acc;
    acc = s;
    for (int i = 0; i < REPL_TOUCH_PORTS; i++) begin
      if (touch[i].valid) acc = plru_next_state(acc, touch[i].way);
    end
    return acc;
  endfunction

endpackage
