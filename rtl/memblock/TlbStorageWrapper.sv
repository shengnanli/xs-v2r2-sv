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

// =============================================================================
// xs_TlbStorageWrapper_core —— TLB 存储 + 替换 包装层（可读重写）
//
// 对应 Chisel: xiangshan.cache.mmu.TLBStorage.scala  class TlbStorageWrapper
//
// 在访存/取指流水中的位置：每个 TLB（ITLB / DTLB-load / DTLB-store）顶层 TLB.scala
//   例化一个 TlbStorageWrapper 作为它的“页表项缓存 + 替换器”。本模块对外暴露：
//     r.req/r.resp   ：ports 路并行查询（vpn → hit/ppn/perm/pbmt…）
//     w              ：refill 写（PTW 回填一条页表项）
//     sfence/csr     ：刷新与 CSR 现场
//   对内例化一个全相联存储 TLBFA（nWays=48），并自带一套 Tree-PLRU 替换器。
//
// ------------------------------------------------------------------------------
// 本层做的事情其实很少（绝大部分是透明路由）：
//   1) r.req / r.resp / sfence / csr / w.bits.data 原样接到内层 TLBFA —— 纯连线，
//      没有任何变换（Scala 里那一大段 rp.bits.xxx := p.bits.xxx 就是逐字段直连）。
//   2) **唯一的有状态逻辑 = Tree-PLRU 替换器**：
//      - 内层 TLBFA 每拍通过 io_access[i].touch_ways 反馈“本拍命中/刚 refill 的 way”；
//      - 替换器把各端口的 touch_ways 依次（foldLeft）喂进 PLRU 树，更新 47 位状态；
//      - 组合地从当前状态算出 victim way（refillIdx），驱动 TLBFA 的 io_w_bits_wayIdx。
//      （q.outReplace=false，故替换器在本层内部，不外引到 TLB 顶。）
//
// 替换算法细节见 xs_tlbsw_pkg（plru_replace_way / plru_next_state）。
//
// 内层 TLBFA：UT/FM 阶段按要求用 **golden TLBFA 黑盒**例化（同名模块 TLBFA / TLBFA_1），
//   因此本核只写“替换器 + wayIdx 选择”这一份真正属于 wrapper 的逻辑，存储/匹配由
//   黑盒 TLBFA 完成。读/响应/sfence/csr/wdata 端口全部直通到黑盒。
//
// 参数化覆盖两个 golden 变体（差别仅在查询/access 端口数）：
//   TlbStorageWrapper   : PORTS=3  NWAYS=48 （itlb）
//   TlbStorageWrapper_1 : PORTS=4  NWAYS=48 （dtlb）
// =============================================================================

module xs_TlbStorageWrapper_core import xs_tlbsw_pkg::*; #(
  parameter int PORTS = 3,
  parameter int WAYS  = NWAYS,          // 48
  parameter int WW    = WAY_W           // 6
)(
  input  logic                clock,
  input  logic                reset,

  // ---- 内层 TLBFA 反馈的替换访问信息（每端口 touch_ways，聚合成 Valid bundle）----
  // 平时：命中端口报告命中 way；refill 后一拍：所有端口报告刚写入的 way。
  input  tlb_access_t         io_access [PORTS],

  // ---- 替换器输出：下次 refill 的 victim way ----
  output logic [WW-1:0]       io_w_bits_wayIdx
);

  // =========================================================================
  // Tree-PLRU 替换器状态（n-1 = 47 位）。复位清 0（与 golden RegInit(0) 一致，
  //   异步复位对齐 golden posedge reset）。
  // =========================================================================
  // 命名与 golden 顶层一致（refill_idx_state_reg），便于 FM 跨层次配对。
  logic [PLRU_W-1:0] refill_idx_state_reg;

  // ---- 组合：把各端口 touch_ways 依次 foldLeft 进 PLRU，得到本拍“更新后状态” ----
  // 语义同 Scala：get_next_state(state, touch_ways) =
  //   touch_ways.foldLeft(state)((s,t) => t.valid ? get_next_state(s, t.bits) : s)
  // 端口顺序 0→1→…→PORTS-1 串联（与 golden 逐端口叠加的更新链一致）。
  logic [PLRU_W-1:0] plru_next;
  logic              any_touch;
  always_comb begin
    plru_next = refill_idx_state_reg;
    any_touch = 1'b0;
    for (int i = 0; i < PORTS; i++) begin
      if (io_access[i].valid) begin
        plru_next = plru_next_state(plru_next, io_access[i].way,
                                    /*state_lo*/0, /*tree_nways*/WAYS);
        any_touch = 1'b1;
      end
    end
  end

  // ---- 状态寄存：仅当有任一端口 touch 时才更新（同 Scala when(touch_ways.valid.orR)）----
  always_ff @(posedge clock or posedge reset) begin
    if (reset)          refill_idx_state_reg <= '0;
    else if (any_touch) refill_idx_state_reg <= plru_next;
  end

  // =========================================================================
  // 组合：从当前 PLRU 状态求 victim way → 驱动内层 TLBFA 的 refill wayIdx。
  //   （Scala: page.w_apply(wayIdx = re.way)；re.way = get_replace_way(state_reg)）
  // =========================================================================
  always_comb
    io_w_bits_wayIdx = plru_replace_way(refill_idx_state_reg, /*state_lo*/0, /*tree_nways*/WAYS);

endmodule

// 自动生成：scripts/gen_tlbstoragewrapper.py —— 勿手改
// TlbStorageWrapper golden 同名 / xs 变体包装：
//   例化 golden 黑盒 TLBFA 做存储匹配 + 可读 PLRU 核 xs_TlbStorageWrapper_core 做替换。
//   wayIdx 内部产生（PLRU），其余端口对 TLBFA 全透传。
// 自动生成：scripts/gen_tlbstoragewrapper.py —— 勿手改
// TlbStorageWrapper golden 同名 / xs 变体包装：
//   例化 golden 黑盒 TLBFA 做存储匹配 + 可读 PLRU 核 xs_TlbStorageWrapper_core 做替换。
//   wayIdx 内部产生（PLRU），其余端口对 TLBFA 全透传。

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module TlbStorageWrapper import xs_tlbsw_pkg::*; (
  input clock,
  input reset,
  input io_sfence_valid,
  input io_sfence_bits_rs1,
  input io_sfence_bits_rs2,
  input [49:0] io_sfence_bits_addr,
  input [15:0] io_sfence_bits_id,
  input io_sfence_bits_hv,
  input io_sfence_bits_hg,
  input [15:0] io_csr_satp_asid,
  input [15:0] io_csr_vsatp_asid,
  input [15:0] io_csr_hgatp_vmid,
  // Svbmt 位图内存(mbmc)现场: sfence 失效范围要看 BME/CMODE —— 见 TLBFA.sv 的
  //   `if (io_sfence_bits_rs1 | io_csr_priv_virt | io_csr_mbmc_BME & ~io_csr_mbmc_CMODE)`。
  //   本层不用它, 纯透传给内层 TLBFA。
  input io_csr_mbmc_BME,
  input io_csr_mbmc_CMODE,
  input io_csr_priv_virt,
  input io_r_req_0_valid,
  input [37:0] io_r_req_0_bits_vpn,
  input [1:0] io_r_req_0_bits_s2xlate,
  input io_r_req_1_valid,
  input [37:0] io_r_req_1_bits_vpn,
  input [1:0] io_r_req_1_bits_s2xlate,
  input io_r_req_2_valid,
  input [37:0] io_r_req_2_bits_vpn,
  input [1:0] io_r_req_2_bits_s2xlate,
  output io_r_resp_0_bits_hit,
  output [35:0] io_r_resp_0_bits_ppn_0,
  output [1:0] io_r_resp_0_bits_pbmt_0,
  output [1:0] io_r_resp_0_bits_g_pbmt_0,
  output io_r_resp_0_bits_perm_0_pf,
  output io_r_resp_0_bits_perm_0_af,
  output io_r_resp_0_bits_perm_0_v,
  output io_r_resp_0_bits_perm_0_a,
  output io_r_resp_0_bits_perm_0_u,
  output io_r_resp_0_bits_perm_0_x,
  output io_r_resp_0_bits_perm_0_w,
  output io_r_resp_0_bits_perm_0_r,
  output io_r_resp_0_bits_g_perm_0_pf,
  output io_r_resp_0_bits_g_perm_0_af,
  output io_r_resp_0_bits_g_perm_0_a,
  output io_r_resp_0_bits_g_perm_0_x,
  output [1:0] io_r_resp_0_bits_s2xlate_0,
  output io_r_resp_1_bits_hit,
  output [35:0] io_r_resp_1_bits_ppn_0,
  output [1:0] io_r_resp_1_bits_pbmt_0,
  output [1:0] io_r_resp_1_bits_g_pbmt_0,
  output io_r_resp_1_bits_perm_0_pf,
  output io_r_resp_1_bits_perm_0_af,
  output io_r_resp_1_bits_perm_0_v,
  output io_r_resp_1_bits_perm_0_a,
  output io_r_resp_1_bits_perm_0_u,
  output io_r_resp_1_bits_perm_0_x,
  output io_r_resp_1_bits_perm_0_w,
  output io_r_resp_1_bits_perm_0_r,
  output io_r_resp_1_bits_g_perm_0_pf,
  output io_r_resp_1_bits_g_perm_0_af,
  output io_r_resp_1_bits_g_perm_0_a,
  output io_r_resp_1_bits_g_perm_0_x,
  output [1:0] io_r_resp_1_bits_s2xlate_0,
  output io_r_resp_2_bits_hit,
  output [35:0] io_r_resp_2_bits_ppn_0,
  output [1:0] io_r_resp_2_bits_pbmt_0,
  output [1:0] io_r_resp_2_bits_g_pbmt_0,
  output io_r_resp_2_bits_perm_0_pf,
  output io_r_resp_2_bits_perm_0_af,
  output io_r_resp_2_bits_perm_0_v,
  output io_r_resp_2_bits_perm_0_a,
  output io_r_resp_2_bits_perm_0_u,
  output io_r_resp_2_bits_perm_0_x,
  output io_r_resp_2_bits_perm_0_w,
  output io_r_resp_2_bits_perm_0_r,
  output io_r_resp_2_bits_g_perm_0_pf,
  output io_r_resp_2_bits_g_perm_0_af,
  output io_r_resp_2_bits_g_perm_0_a,
  output io_r_resp_2_bits_g_perm_0_x,
  output [1:0] io_r_resp_2_bits_s2xlate_0,
  input io_w_valid,
  input [1:0] io_w_bits_data_s2xlate,
  input [34:0] io_w_bits_data_s1_entry_tag,
  input [15:0] io_w_bits_data_s1_entry_asid,
  input [13:0] io_w_bits_data_s1_entry_vmid,
  input io_w_bits_data_s1_entry_n,
  input [1:0] io_w_bits_data_s1_entry_pbmt,
  input io_w_bits_data_s1_entry_perm_d,
  input io_w_bits_data_s1_entry_perm_a,
  input io_w_bits_data_s1_entry_perm_g,
  input io_w_bits_data_s1_entry_perm_u,
  input io_w_bits_data_s1_entry_perm_x,
  input io_w_bits_data_s1_entry_perm_w,
  input io_w_bits_data_s1_entry_perm_r,
  input [1:0] io_w_bits_data_s1_entry_level,
  input io_w_bits_data_s1_entry_v,
  input [40:0] io_w_bits_data_s1_entry_ppn,
  input [2:0] io_w_bits_data_s1_ppn_low_0,
  input [2:0] io_w_bits_data_s1_ppn_low_1,
  input [2:0] io_w_bits_data_s1_ppn_low_2,
  input [2:0] io_w_bits_data_s1_ppn_low_3,
  input [2:0] io_w_bits_data_s1_ppn_low_4,
  input [2:0] io_w_bits_data_s1_ppn_low_5,
  input [2:0] io_w_bits_data_s1_ppn_low_6,
  input [2:0] io_w_bits_data_s1_ppn_low_7,
  input io_w_bits_data_s1_valididx_0,
  input io_w_bits_data_s1_valididx_1,
  input io_w_bits_data_s1_valididx_2,
  input io_w_bits_data_s1_valididx_3,
  input io_w_bits_data_s1_valididx_4,
  input io_w_bits_data_s1_valididx_5,
  input io_w_bits_data_s1_valididx_6,
  input io_w_bits_data_s1_valididx_7,
  input io_w_bits_data_s1_pteidx_0,
  input io_w_bits_data_s1_pteidx_1,
  input io_w_bits_data_s1_pteidx_2,
  input io_w_bits_data_s1_pteidx_3,
  input io_w_bits_data_s1_pteidx_4,
  input io_w_bits_data_s1_pteidx_5,
  input io_w_bits_data_s1_pteidx_6,
  input io_w_bits_data_s1_pteidx_7,
  input io_w_bits_data_s1_pf,
  input io_w_bits_data_s1_af,
  input [37:0] io_w_bits_data_s2_entry_tag,
  input [13:0] io_w_bits_data_s2_entry_vmid,
  input io_w_bits_data_s2_entry_n,
  input [1:0] io_w_bits_data_s2_entry_pbmt,
  input [37:0] io_w_bits_data_s2_entry_ppn,
  input io_w_bits_data_s2_entry_perm_d,
  input io_w_bits_data_s2_entry_perm_a,
  input io_w_bits_data_s2_entry_perm_g,
  input io_w_bits_data_s2_entry_perm_u,
  input io_w_bits_data_s2_entry_perm_x,
  input io_w_bits_data_s2_entry_perm_w,
  input io_w_bits_data_s2_entry_perm_r,
  input [1:0] io_w_bits_data_s2_entry_level,
  input io_w_bits_data_s2_gpf,
  input io_w_bits_data_s2_gaf
);

  logic        acc_valid [3];
  logic [5:0] acc_bits  [3];
  tlb_access_t access    [3];
  logic [5:0] refill_wayIdx;
  always_comb begin
    for (int i = 0; i < 3; i++) begin
      access[i].valid = acc_valid[i];
      access[i].way   = acc_bits[i];
    end
  end

  TLBFA page_itlb_storage_fa (
    .clock(clock),
    .reset(reset),
    .io_sfence_valid(io_sfence_valid),
    .io_sfence_bits_rs1(io_sfence_bits_rs1),
    .io_sfence_bits_rs2(io_sfence_bits_rs2),
    .io_sfence_bits_addr(io_sfence_bits_addr),
    .io_sfence_bits_id(io_sfence_bits_id),
    .io_sfence_bits_hv(io_sfence_bits_hv),
    .io_sfence_bits_hg(io_sfence_bits_hg),
    .io_csr_satp_asid(io_csr_satp_asid),
    .io_csr_vsatp_asid(io_csr_vsatp_asid),
    .io_csr_hgatp_vmid(io_csr_hgatp_vmid),
    .io_csr_mbmc_BME(io_csr_mbmc_BME),
    .io_csr_mbmc_CMODE(io_csr_mbmc_CMODE),
    .io_csr_priv_virt(io_csr_priv_virt),
    .io_r_req_0_valid(io_r_req_0_valid),
    .io_r_req_0_bits_vpn(io_r_req_0_bits_vpn),
    .io_r_req_0_bits_s2xlate(io_r_req_0_bits_s2xlate),
    .io_r_req_1_valid(io_r_req_1_valid),
    .io_r_req_1_bits_vpn(io_r_req_1_bits_vpn),
    .io_r_req_1_bits_s2xlate(io_r_req_1_bits_s2xlate),
    .io_r_req_2_valid(io_r_req_2_valid),
    .io_r_req_2_bits_vpn(io_r_req_2_bits_vpn),
    .io_r_req_2_bits_s2xlate(io_r_req_2_bits_s2xlate),
    .io_r_resp_0_bits_hit(io_r_resp_0_bits_hit),
    .io_r_resp_0_bits_ppn_0(io_r_resp_0_bits_ppn_0),
    .io_r_resp_0_bits_pbmt_0(io_r_resp_0_bits_pbmt_0),
    .io_r_resp_0_bits_g_pbmt_0(io_r_resp_0_bits_g_pbmt_0),
    .io_r_resp_0_bits_perm_0_pf(io_r_resp_0_bits_perm_0_pf),
    .io_r_resp_0_bits_perm_0_af(io_r_resp_0_bits_perm_0_af),
    .io_r_resp_0_bits_perm_0_v(io_r_resp_0_bits_perm_0_v),
    .io_r_resp_0_bits_perm_0_a(io_r_resp_0_bits_perm_0_a),
    .io_r_resp_0_bits_perm_0_u(io_r_resp_0_bits_perm_0_u),
    .io_r_resp_0_bits_perm_0_x(io_r_resp_0_bits_perm_0_x),
    .io_r_resp_0_bits_perm_0_w(io_r_resp_0_bits_perm_0_w),
    .io_r_resp_0_bits_perm_0_r(io_r_resp_0_bits_perm_0_r),
    .io_r_resp_0_bits_g_perm_0_pf(io_r_resp_0_bits_g_perm_0_pf),
    .io_r_resp_0_bits_g_perm_0_af(io_r_resp_0_bits_g_perm_0_af),
    .io_r_resp_0_bits_g_perm_0_a(io_r_resp_0_bits_g_perm_0_a),
    .io_r_resp_0_bits_g_perm_0_x(io_r_resp_0_bits_g_perm_0_x),
    .io_r_resp_0_bits_s2xlate_0(io_r_resp_0_bits_s2xlate_0),
    .io_r_resp_1_bits_hit(io_r_resp_1_bits_hit),
    .io_r_resp_1_bits_ppn_0(io_r_resp_1_bits_ppn_0),
    .io_r_resp_1_bits_pbmt_0(io_r_resp_1_bits_pbmt_0),
    .io_r_resp_1_bits_g_pbmt_0(io_r_resp_1_bits_g_pbmt_0),
    .io_r_resp_1_bits_perm_0_pf(io_r_resp_1_bits_perm_0_pf),
    .io_r_resp_1_bits_perm_0_af(io_r_resp_1_bits_perm_0_af),
    .io_r_resp_1_bits_perm_0_v(io_r_resp_1_bits_perm_0_v),
    .io_r_resp_1_bits_perm_0_a(io_r_resp_1_bits_perm_0_a),
    .io_r_resp_1_bits_perm_0_u(io_r_resp_1_bits_perm_0_u),
    .io_r_resp_1_bits_perm_0_x(io_r_resp_1_bits_perm_0_x),
    .io_r_resp_1_bits_perm_0_w(io_r_resp_1_bits_perm_0_w),
    .io_r_resp_1_bits_perm_0_r(io_r_resp_1_bits_perm_0_r),
    .io_r_resp_1_bits_g_perm_0_pf(io_r_resp_1_bits_g_perm_0_pf),
    .io_r_resp_1_bits_g_perm_0_af(io_r_resp_1_bits_g_perm_0_af),
    .io_r_resp_1_bits_g_perm_0_a(io_r_resp_1_bits_g_perm_0_a),
    .io_r_resp_1_bits_g_perm_0_x(io_r_resp_1_bits_g_perm_0_x),
    .io_r_resp_1_bits_s2xlate_0(io_r_resp_1_bits_s2xlate_0),
    .io_r_resp_2_bits_hit(io_r_resp_2_bits_hit),
    .io_r_resp_2_bits_ppn_0(io_r_resp_2_bits_ppn_0),
    .io_r_resp_2_bits_pbmt_0(io_r_resp_2_bits_pbmt_0),
    .io_r_resp_2_bits_g_pbmt_0(io_r_resp_2_bits_g_pbmt_0),
    .io_r_resp_2_bits_perm_0_pf(io_r_resp_2_bits_perm_0_pf),
    .io_r_resp_2_bits_perm_0_af(io_r_resp_2_bits_perm_0_af),
    .io_r_resp_2_bits_perm_0_v(io_r_resp_2_bits_perm_0_v),
    .io_r_resp_2_bits_perm_0_a(io_r_resp_2_bits_perm_0_a),
    .io_r_resp_2_bits_perm_0_u(io_r_resp_2_bits_perm_0_u),
    .io_r_resp_2_bits_perm_0_x(io_r_resp_2_bits_perm_0_x),
    .io_r_resp_2_bits_perm_0_w(io_r_resp_2_bits_perm_0_w),
    .io_r_resp_2_bits_perm_0_r(io_r_resp_2_bits_perm_0_r),
    .io_r_resp_2_bits_g_perm_0_pf(io_r_resp_2_bits_g_perm_0_pf),
    .io_r_resp_2_bits_g_perm_0_af(io_r_resp_2_bits_g_perm_0_af),
    .io_r_resp_2_bits_g_perm_0_a(io_r_resp_2_bits_g_perm_0_a),
    .io_r_resp_2_bits_g_perm_0_x(io_r_resp_2_bits_g_perm_0_x),
    .io_r_resp_2_bits_s2xlate_0(io_r_resp_2_bits_s2xlate_0),
    .io_w_valid(io_w_valid),
    .io_w_bits_wayIdx(refill_wayIdx),
    .io_w_bits_data_s2xlate(io_w_bits_data_s2xlate),
    .io_w_bits_data_s1_entry_tag(io_w_bits_data_s1_entry_tag),
    .io_w_bits_data_s1_entry_asid(io_w_bits_data_s1_entry_asid),
    .io_w_bits_data_s1_entry_vmid(io_w_bits_data_s1_entry_vmid),
    .io_w_bits_data_s1_entry_n(io_w_bits_data_s1_entry_n),
    .io_w_bits_data_s1_entry_pbmt(io_w_bits_data_s1_entry_pbmt),
    .io_w_bits_data_s1_entry_perm_d(io_w_bits_data_s1_entry_perm_d),
    .io_w_bits_data_s1_entry_perm_a(io_w_bits_data_s1_entry_perm_a),
    .io_w_bits_data_s1_entry_perm_g(io_w_bits_data_s1_entry_perm_g),
    .io_w_bits_data_s1_entry_perm_u(io_w_bits_data_s1_entry_perm_u),
    .io_w_bits_data_s1_entry_perm_x(io_w_bits_data_s1_entry_perm_x),
    .io_w_bits_data_s1_entry_perm_w(io_w_bits_data_s1_entry_perm_w),
    .io_w_bits_data_s1_entry_perm_r(io_w_bits_data_s1_entry_perm_r),
    .io_w_bits_data_s1_entry_level(io_w_bits_data_s1_entry_level),
    .io_w_bits_data_s1_entry_v(io_w_bits_data_s1_entry_v),
    .io_w_bits_data_s1_entry_ppn(io_w_bits_data_s1_entry_ppn),
    .io_w_bits_data_s1_ppn_low_0(io_w_bits_data_s1_ppn_low_0),
    .io_w_bits_data_s1_ppn_low_1(io_w_bits_data_s1_ppn_low_1),
    .io_w_bits_data_s1_ppn_low_2(io_w_bits_data_s1_ppn_low_2),
    .io_w_bits_data_s1_ppn_low_3(io_w_bits_data_s1_ppn_low_3),
    .io_w_bits_data_s1_ppn_low_4(io_w_bits_data_s1_ppn_low_4),
    .io_w_bits_data_s1_ppn_low_5(io_w_bits_data_s1_ppn_low_5),
    .io_w_bits_data_s1_ppn_low_6(io_w_bits_data_s1_ppn_low_6),
    .io_w_bits_data_s1_ppn_low_7(io_w_bits_data_s1_ppn_low_7),
    .io_w_bits_data_s1_valididx_0(io_w_bits_data_s1_valididx_0),
    .io_w_bits_data_s1_valididx_1(io_w_bits_data_s1_valididx_1),
    .io_w_bits_data_s1_valididx_2(io_w_bits_data_s1_valididx_2),
    .io_w_bits_data_s1_valididx_3(io_w_bits_data_s1_valididx_3),
    .io_w_bits_data_s1_valididx_4(io_w_bits_data_s1_valididx_4),
    .io_w_bits_data_s1_valididx_5(io_w_bits_data_s1_valididx_5),
    .io_w_bits_data_s1_valididx_6(io_w_bits_data_s1_valididx_6),
    .io_w_bits_data_s1_valididx_7(io_w_bits_data_s1_valididx_7),
    .io_w_bits_data_s1_pteidx_0(io_w_bits_data_s1_pteidx_0),
    .io_w_bits_data_s1_pteidx_1(io_w_bits_data_s1_pteidx_1),
    .io_w_bits_data_s1_pteidx_2(io_w_bits_data_s1_pteidx_2),
    .io_w_bits_data_s1_pteidx_3(io_w_bits_data_s1_pteidx_3),
    .io_w_bits_data_s1_pteidx_4(io_w_bits_data_s1_pteidx_4),
    .io_w_bits_data_s1_pteidx_5(io_w_bits_data_s1_pteidx_5),
    .io_w_bits_data_s1_pteidx_6(io_w_bits_data_s1_pteidx_6),
    .io_w_bits_data_s1_pteidx_7(io_w_bits_data_s1_pteidx_7),
    .io_w_bits_data_s1_pf(io_w_bits_data_s1_pf),
    .io_w_bits_data_s1_af(io_w_bits_data_s1_af),
    .io_w_bits_data_s2_entry_tag(io_w_bits_data_s2_entry_tag),
    .io_w_bits_data_s2_entry_vmid(io_w_bits_data_s2_entry_vmid),
    .io_w_bits_data_s2_entry_n(io_w_bits_data_s2_entry_n),
    .io_w_bits_data_s2_entry_pbmt(io_w_bits_data_s2_entry_pbmt),
    .io_w_bits_data_s2_entry_ppn(io_w_bits_data_s2_entry_ppn),
    .io_w_bits_data_s2_entry_perm_d(io_w_bits_data_s2_entry_perm_d),
    .io_w_bits_data_s2_entry_perm_a(io_w_bits_data_s2_entry_perm_a),
    .io_w_bits_data_s2_entry_perm_g(io_w_bits_data_s2_entry_perm_g),
    .io_w_bits_data_s2_entry_perm_u(io_w_bits_data_s2_entry_perm_u),
    .io_w_bits_data_s2_entry_perm_x(io_w_bits_data_s2_entry_perm_x),
    .io_w_bits_data_s2_entry_perm_w(io_w_bits_data_s2_entry_perm_w),
    .io_w_bits_data_s2_entry_perm_r(io_w_bits_data_s2_entry_perm_r),
    .io_w_bits_data_s2_entry_level(io_w_bits_data_s2_entry_level),
    .io_w_bits_data_s2_gpf(io_w_bits_data_s2_gpf),
    .io_w_bits_data_s2_gaf(io_w_bits_data_s2_gaf),
    .io_access_0_touch_ways_valid(acc_valid[0]),
    .io_access_0_touch_ways_bits(acc_bits[0]),
    .io_access_1_touch_ways_valid(acc_valid[1]),
    .io_access_1_touch_ways_bits(acc_bits[1]),
    .io_access_2_touch_ways_valid(acc_valid[2]),
    .io_access_2_touch_ways_bits(acc_bits[2])
  );

  xs_TlbStorageWrapper_core #(.PORTS(3), .WAYS(48), .WW(6)) u_core (
    .clock(clock), .reset(reset),
    .io_access(access),
    .io_w_bits_wayIdx(refill_wayIdx)
  );
endmodule
