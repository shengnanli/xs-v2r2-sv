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
