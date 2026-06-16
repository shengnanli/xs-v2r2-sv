// =============================================================================
// xs_tlbsw_pkg —— TlbStorageWrapper 的替换策略（Tree-PLRU）类型与纯函数
//
// 对应 Chisel:
//   xiangshan.cache.mmu.TLBStorage.scala  class TlbStorageWrapper
//     （outReplace=false 分支：val re = ReplacementPolicy.fromString("plru", NWays)）
//   replacement 算法本体：rocket-chip util/Replacement.scala  class PseudoLRU
//
// 角色：TlbStorageWrapper 是 ITLB/DTLB 的“存储 + 替换”包装层。它本身几乎是透明路由：
//   把多端口读请求/响应、sfence、csr、refill 数据原样接到内层全相联存储 TLBFA。
//   它**唯一拥有的有状态逻辑**就是这里实现的 Tree-PLRU 替换器：
//     - 每拍收集各端口 TLBFA 反馈的 access.touch_ways（命中/刚 refill 的 way），
//       依次（foldLeft）更新 PLRU 树状态；
//     - 组合地从当前树状态算出 victim way（refillIdx），驱动 io_w_bits_wayIdx，
//       告诉 TLBFA 下次 refill 写哪一路。
//
// ------------------------------------------------------------------------------
// Tree-PLRU（伪 LRU 二叉树，见 Wikipedia Pseudo-LRU#Tree-PLRU）
//
//   n 路用 n-1 个状态位，每个内部节点 1 位，记录“左子树是否比右子树更老(更该被换)”。
//   - 查 victim：从根沿“指向更老子树”的方向下行，到叶子即得 way 编码（MSB→LSB）。
//   - 命中/refill 后更新：把被访问 way 路径上的每个节点翻成“指向另一侧”，即把刚访问
//     的子树标记为“更新(不该被换)”。
//
//   非 2 的幂拆分规则（与 rocket-chip 完全一致）：
//     right_nways = 1 << (log2Ceil(nways)-1)   // 右子树取最大的 2 的幂
//     left_nways  = nways - right_nways         // 左子树取剩余（可能更小、非平衡）
//   本配置 nways=48：root 把 48 拆成 left=16 / right=32。
//
//   状态位布局（与 rocket-chip extract 索引一致，子树 nways 个 way 用 nways-1 位）：
//     node_bit(本节点)   = state[nways-2]                 （子树状态的最高位）
//     left_subtree_state = state[nways-3 : right_nways-1] （紧邻其下，左子树 left-1 位）
//     right_subtree_state= state[right_nways-2 : 0]       （最低 right-1 位）
//
// 这里把 golden(firtool) 展平成几百行嵌套三元的 victim 选择 + 状态更新，收敛成两个
//   递归纯函数（plru_replace_way / plru_next_state）+ 一个多端口 foldLeft 包装。
//   nways 固定为 48，递归在综合期完全展开。
// =============================================================================
package xs_tlbsw_pkg;

  localparam int NWAYS    = 48;
  localparam int WAY_W    = 6;            // log2Up(NWAYS)
  localparam int PLRU_W   = NWAYS - 1;    // 47：PLRU 树状态位数

  // ---------------- 替换访问反馈 bundle（= TLBFA 的 io_access[i].touch_ways）----------------
  // 对应 Chisel 的 Valid[UInt]：valid=本拍该端口命中/刚 refill；way=对应的 way 编号。
  //   替换器据此（仅在 valid 时）把该 way 标记为“最近使用”，更新 PLRU 树。
  typedef struct packed {
    logic              valid;
    logic [WAY_W-1:0]  way;
  } tlb_access_t;

  // ---------------- PLRU 节点决策方向 ----------------
  // 每个内部节点的状态位语义：左子树是否比右子树更老（更该被替换）。下行选 victim 时
  //   据此决定走哪一侧；以 enum 表意，避免到处裸用 1'b1/1'b0。
  typedef enum logic {
    PLRU_GO_RIGHT = 1'b0,   // 本节点：右子树更老 → 下钻右侧（way 高位记 0）
    PLRU_GO_LEFT  = 1'b1    // 本节点：左子树更老 → 下钻左侧（way 高位记 1）
  } plru_dir_e;

  // log2Ceil（向上取整），用于 PLRU 子树拆分；nways<=64 足够。
  function automatic int xs_log2ceil(input int n);
    int r;
    r = 0;
    // 最小满足 2^r >= n 的 r
    while ((1 << r) < n) r++;
    return r;
  endfunction

  // ---------------------------------------------------------------------------
  // plru_replace_way —— 从树状态求 victim way（= PseudoLRU.get_replace_way）
  //
  // 递归处理一棵 tree_nways 路的子树。state_lo/state 用全宽 47 位总线 + 偏移传递：
  //   子树状态 = state_bus[state_lo +: (tree_nways-1)]，本节点位 = 子树状态最高位。
  // 返回 way 的“相对本子树”的编码（MSB 先确定，递归拼接 LSB）。
  // ---------------------------------------------------------------------------
  // 返回值是**右对齐**的 way 编码：宽度 = log2Ceil(tree_nways)，本节点位在该子树编码的
  //   最高位（bit log2Ceil(tree_nways)-1），递归把子树编码拼在其下。对应 rocket-chip 的
  //   Cat(node_bit, child_way)（Mux 把较窄的左子树编码零扩展到与右子树同宽）。
  function automatic logic [WAY_W-1:0] plru_replace_way(
      input logic [PLRU_W-1:0] state,
      input int                state_lo,   // 子树状态在 state 中的起始位
      input int                tree_nways);
    int right_nways, left_nways, node_pos;
    plru_dir_e node_dir;          // 本节点决策：左子树是否更老（→ 走左/右）
    logic [WAY_W-1:0] sub;
    if (tree_nways <= 1) begin
      return '0;                  // 空节点（非平衡树补位，0 位编码）
    end else if (tree_nways == 2) begin
      // 叶子：单个状态位直接作为最低位（宽度 1）
      return {{(WAY_W-1){1'b0}}, state[state_lo]};
    end else begin
      right_nways = 1 << (xs_log2ceil(tree_nways) - 1);
      left_nways  = tree_nways - right_nways;
      node_pos    = xs_log2ceil(tree_nways) - 1;   // 本节点位在 way 编码中的位置
      // 本节点状态位 = 子树状态最高位 = state[state_lo + (tree_nways-1) - 1]
      node_dir    = plru_dir_e'(state[state_lo + tree_nways - 2]);
      // 子树状态切片：左子树紧贴本节点位之下占 left_nways-1 位（lo=state_lo+right_nways-1），
      //   右子树占最低 right_nways-1 位（lo=state_lo）。
      if (node_dir == PLRU_GO_LEFT) begin
        // 左子树更老 → 下钻左侧（编码右对齐，宽度 log2Ceil(left_nways)≤node_pos）
        if (left_nways > 1)
          sub = plru_replace_way(state, state_lo + right_nways - 1, left_nways);
        else
          sub = '0;               // 左只有 1 路（非平衡叶），编码为 0
      end else begin
        // 右子树更老 → 下钻右侧（编码宽度恰为 node_pos）
        sub = plru_replace_way(state, state_lo, right_nways);
      end
      // 本节点位放到 node_pos，子树编码拼在其下（右对齐）
      return (logic'(node_dir == PLRU_GO_LEFT) << node_pos) | sub;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // plru_next_state —— 访问 touch_way 后的新树状态（= PseudoLRU.get_next_state）
  //
  // 沿 touch_way 指示的路径，把每个经过节点翻成“指向另一侧子树”（标记被访问侧为新），
  // 未经过的子树状态保持不变。touch_way 用全宽 WAY_W 传，按本层 log2 位取方向。
  // 返回**整棵 47 位**新状态（未涉及位原样保留），便于多端口 foldLeft 串联。
  // ---------------------------------------------------------------------------
  function automatic logic [PLRU_W-1:0] plru_next_state(
      input logic [PLRU_W-1:0] state,
      input logic [WAY_W-1:0]  touch_way,
      input int                state_lo,
      input int                tree_nways);
    int right_nways, left_nways, level_bit;
    logic set_left_older;
    logic [PLRU_W-1:0] ns;
    ns = state;
    if (tree_nways == 2) begin
      // 叶子：状态位 = !touch_way[0]（访问 way0 → 标记 way1 更老，反之亦然）
      ns[state_lo] = ~touch_way[0];
      return ns;
    end else if (tree_nways <= 1) begin
      return ns;                  // 空节点，不变
    end else begin
      right_nways = 1 << (xs_log2ceil(tree_nways) - 1);
      left_nways  = tree_nways - right_nways;
      level_bit   = xs_log2ceil(tree_nways) - 1;       // 本层在 touch_way 中的方向位
      set_left_older = ~touch_way[level_bit];          // 访问右侧→左变老；访问左侧→右变老
      // 本节点位置 = state_lo + tree_nways - 2
      ns[state_lo + tree_nways - 2] = set_left_older;
      if (set_left_older) begin
        // 访问的是右子树 → 仅递归更新右子树（左子树整体标记更老，不下钻）
        ns = plru_next_state(ns, touch_way, state_lo, right_nways);
      end else if (left_nways > 1) begin
        // 访问的是左子树 → 递归更新左子树（左有分支才下钻）
        ns = plru_next_state(ns, touch_way, state_lo + right_nways - 1, left_nways);
      end
      return ns;
    end
  endfunction

endpackage
