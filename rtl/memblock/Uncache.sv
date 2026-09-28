// =============================================================================
// Uncache.sv —— DCache 旁的非缓存（MMIO / NC）访存缓冲：LSQ 进，TileLink-UL 出，结果回 LSQ。
//
// 位置：MemBlock 里 LSQ（LoadQueueUncache / StoreQueue）与 L2/总线之间。凡是不能进
//   DCache 的访存（MMIO 设备寄存器、NC 非缓存内存）都经过这里，一次一个字（≤ 8 字节）。
// 结构：16 项缓冲（entries + states），每项记一笔请求的地址/数据/掩码与生命周期：
//     valid ──(发出 A 通道)──> inflight ──(收到 D 通道)──> waitReturn ──(交回 LSQ)──> 空闲
//   另有一位 waitSame：同一个 8 字节块上已有一笔在路上时，新来的这笔先挂着，
//   等前一笔的 D 回来再清掉，保证同块访问按序到达设备。
// 四条流水（每条单拍完成，本文件按此分节）：
//   e0 入队：与已有条目比块地址 —— 可合并（NC 写合并成连续对齐掩码）就合并，
//            冲突就拒收，否则分配空项；下一拍 idResp 告诉 LSQ 分到了哪一项。
//   q0 发出：可发的项里挑编号最小的，拼成 TileLink Get / PutPartialData。
//   D  响应：按 source=项号写回数据与错误位，解除同块等待。
//   r0 交回：waitReturn 的项里挑编号最小的交回 LSQ。
//   另有 f0/f1 两拍的 store→load 前递（3 条 load 流水），与关闭 outstanding 时的
//   单笔状态机 uState。
// 怪癖（照 golden 保留）：
//   · D 通道恒 ready，D 的写回在同一拍里压过 e0 的合并/分配写（Chisel 最后连接者赢）；
//   · 前递的候选掩码/数据寄存器三条 load 流水共用一份（f0 按条目是否为 store 更新）；
//   · f1 地址比较寄存器存满 48 位，但只读 [47:3]；条目 vaddr[2:0] 写了从不读 ——
//     两侧对称的死位，FM 走 vmucp（见 verif/fm_target_config/Uncache.tcl）。
// Chisel 源：src/main/scala/xiangshan/cache/dcache/Uncache.scala（UncacheImp）。
// golden 对照：G1-canonical/golden-rtl/Uncache.sv
// 本文件导航：package → xs_Uncache_core（§1 状态 §2 e0 §3 q0 §4 D §5 r0 §6 前递 §7 状态更新）
//   → 文末 GENERATED 区的 wrapper Uncache（scripts/gen_uncache.py 生成）。
// =============================================================================
package uncache_pkg;
  localparam int NUM_ENTRIES = 16;             // UncacheBufferSize
  localparam int IDX_W       = 4;              // log2(NUM_ENTRIES)
  localparam int PADDR_W     = 48;
  localparam int VADDR_W     = 50;
  localparam int LOAD_PIPES  = 3;              // LoadPipelineWidth：前递端口数
  localparam int BLOCK_OFF   = 3;              // 块 = 一个 8 字节字：addr >> 3 相同即同块

  localparam logic [4:0] M_XRD = 5'h0;         // MemoryOpConstants：读
  localparam logic [4:0] M_XWR = 5'h1;         // MemoryOpConstants：写

  localparam logic [3:0] TL_PUT_PARTIAL = 4'h1;  // TileLink A 通道 opcode
  localparam logic [3:0] TL_GET         = 4'h4;

  // 关闭 outstanding（io.enableOutstanding=0）时的单笔状态机：一次只放一笔在路上
  typedef enum logic [1:0] {
    S_IDLE        = 2'h0,
    S_INFLIGHT    = 2'h1,
    S_WAIT_RETURN = 2'h2
  } ustate_e;

  // LSQ → Uncache 的请求（UncacheWordReq 在 golden 里留下的字段）
  typedef struct packed {
    logic [4:0]         cmd;
    logic [PADDR_W-1:0] addr;
    logic [VADDR_W-1:0] vaddr;
    logic [63:0]        data;
    logic [7:0]         mask;
    logic [6:0]         id;             // LSQ 侧编号（mid）
    logic               nc;             // 1 = NC 内存，0 = MMIO
    logic               memBackTypeMM;  // 后端是主存（difftest 要同步 golden 内存）
  } lsq_req_t;

  // 入队后一拍回给 LSQ 的"你分到了第几项"
  typedef struct packed {
    logic [6:0]       mid;
    logic [IDX_W-1:0] sid;
    logic             is2lq;
    logic             nc;
  } id_resp_t;

  // 交回 LSQ 的结果
  typedef struct packed {
    logic [63:0]      data;
    logic [IDX_W-1:0] id;
    logic             nc;
    logic             is2lq;
    logic             denied;
    logic             corrupt;
  } lsq_resp_t;

  // 优先编码：最低的 1 的下标；全 0 时给 N-1（与 chisel PriorityEncoder 一致）
  function automatic logic [IDX_W-1:0] lowest_idx(input logic [NUM_ENTRIES-1:0] v);
    lowest_idx = IDX_W'(NUM_ENTRIES - 1);
    for (int i = NUM_ENTRIES - 1; i >= 0; i--)
      if (v[i]) lowest_idx = IDX_W'(i);
  endfunction

  function automatic logic [3:0] popcount8(input logic [7:0] m);
    popcount8 = '0;
    for (int j = 0; j < 8; j++) popcount8 = popcount8 + 4'(m[j]);
  endfunction

  // 合并后的掩码必须仍是"一个自然对齐的 1/2/4/8 字节块"才允许合并
  function automatic logic continue_and_align(input logic [7:0] m);
    continue_and_align = (popcount8(m) == 4'd1)
                       || m == 8'h03 || m == 8'h0C || m == 8'h30 || m == 8'hC0
                       || m == 8'h0F || m == 8'hF0 || m == 8'hFF;
  endfunction

  // TileLink Get 的字节掩码（edge.Get → maskGen）：地址所在的 2^lgSize 自然对齐块全 1
  function automatic logic [7:0] tl_get_mask(input logic [2:0] addr_lo, input logic [1:0] lg_size);
    logic [2:0] diff;
    for (int j = 0; j < 8; j++) begin
      diff = 3'(j) ^ addr_lo;
      tl_get_mask[j] = (diff >> lg_size) == 3'h0;
    end
  endfunction
endpackage

module xs_Uncache_core
  import uncache_pkg::*;
(
  input  logic                          clock,
  input  logic                          reset,
  // ---- TileLink A：发往总线
  input  logic                          a_ready,
  output logic                          a_valid,
  output logic [3:0]                    a_opcode,
  output logic [1:0]                    a_size,
  output logic [IDX_W-1:0]              a_source,
  output logic [PADDR_W-1:0]            a_address,
  output logic                          a_user_nc,
  output logic                          a_user_mm,
  output logic [7:0]                    a_mask,
  output logic [63:0]                   a_data,
  // ---- TileLink D：总线回来（恒 ready）
  input  logic                          d_valid,
  input  logic [IDX_W-1:0]              d_source,
  input  logic                          d_denied,
  input  logic [63:0]                   d_data,
  input  logic                          d_corrupt,
  // ---- 杂项
  input  logic [5:0]                    hart_id,
  input  logic                          enable_outstanding,
  input  logic                          flush_valid,
  output logic                          flush_empty,
  // ---- LSQ 请求 / idResp / 结果
  output logic                          req_ready,
  input  logic                          req_valid,
  input  lsq_req_t                      req,
  output logic                          id_resp_valid,
  output id_resp_t                      id_resp,
  input  logic                          resp_ready,
  output logic                          resp_valid,
  output lsq_resp_t                     resp,
  // ---- 前递：LOAD_PIPES 条 load 流水
  input  logic [LOAD_PIPES-1:0][VADDR_W-1:0] fwd_vaddr,
  input  logic [LOAD_PIPES-1:0][PADDR_W-1:0] fwd_paddr,
  input  logic [LOAD_PIPES-1:0]         fwd_valid,
  output logic [LOAD_PIPES-1:0][15:0]   fwd_mask,
  output logic [LOAD_PIPES-1:0][15:0][7:0] fwd_data,
  output logic [LOAD_PIPES-1:0]         fwd_match_invalid,
  // ---- WFI / 总线错误 / difftest
  input  logic                          wfi_req,
  output logic                          wfi_safe,
  output logic                          bus_error_valid,
  output logic [PADDR_W-1:0]            bus_error_addr,
  output logic [152:0]                  difftest_bore
);
  localparam int N = NUM_ENTRIES;

  // ===========================================================================
  // §1 状态。条目按字段各存一个数组（SoA）；生命周期四位各是一个 N 位向量。
  //    条目字段不复位（golden 同），生命周期/uState/noPending/drain 异步复位。
  // ===========================================================================
  logic [4:0]         entry_cmd     [N];
  logic [PADDR_W-1:0] entry_addr    [N];
  logic [VADDR_W-1:0] entry_vaddr   [N];   // 只读 [49:3]
  logic [63:0]        entry_data    [N];
  logic [7:0]         entry_mask    [N];
  logic               entry_nc      [N];
  logic               entry_mm      [N];   // memBackTypeMM
  logic               entry_denied  [N];   // D 通道带回的错误位
  logic               entry_corrupt [N];

  logic [N-1:0] st_valid;        // 本项占用
  logic [N-1:0] st_inflight;     // 已发 A、等 D
  logic [N-1:0] st_wait_same;    // 同块有前一笔在路上，先不发
  logic [N-1:0] st_wait_return;  // D 已回、等交回 LSQ
  logic [N-1:0] no_pending;      // 本项没有在路上的总线请求（WFI 判安全用），复位 1
  ustate_e      u_state;
  logic         do_uarch_drain;  // 前递 v/p 地址失配或 flush：先拒收，直到缓冲排空

  // 三条流水之间的握手（下面各节定义）
  logic             a_fire;      // A 通道本拍发出
  logic [IDX_W-1:0] q0_idx;      // 本拍要发的项
  logic             resp_fire;   // 本拍交回 LSQ
  logic [IDX_W-1:0] r0_idx;      // 本拍交回的项
  logic             empty;
  logic             f1_need_drain;

  function automatic logic same_block_p(input logic [PADDR_W-1:0] x, input logic [PADDR_W-1:0] y);
    same_block_p = x[PADDR_W-1:BLOCK_OFF] == y[PADDR_W-1:BLOCK_OFF];
  endfunction

  function automatic logic same_block_v(input logic [VADDR_W-1:0] x, input logic [VADDR_W-1:0] y);
    same_block_v = x[VADDR_W-1:BLOCK_OFF] == y[VADDR_W-1:BLOCK_OFF];
  endfunction

  // ===========================================================================
  // §2 e0 入队：对每个已占用项判三件事
  //   · 同块（按 paddr）却不能合并        → 拒收（rejectVec）
  //   · 同块、属性相同、掩码合并后仍对齐，且该项还没发出 → 合并进去（mergeVec）
  //   · 同块、可合并、但该项已发出/本拍正要发出      → 另分配一项并挂 waitSame
  //   "能否合并"（primary）：vaddr 同块、cmd 相同、两者都是 NC、memBackTypeMM 相同、
  //   合并掩码对齐，且该项此刻既不在收 D 也不在等交回（否则 LSQ 收不到唤醒）。
  // ===========================================================================
  logic [N-1:0] e0_reject_vec, e0_merge_vec, e0_alloc_wait_same_vec, e0_invalid_vec;

  always_comb begin
    for (int i = 0; i < N; i++) begin
      logic hit, merge_primary, merge_secondary;
      hit = req_valid & st_valid[i] & same_block_p(req.addr, entry_addr[i]);
      merge_primary = same_block_v(req.vaddr, entry_vaddr[i])
                    & (req.cmd == entry_cmd[i])
                    & req.nc & entry_nc[i]
                    & (req.memBackTypeMM == entry_mm[i])
                    & continue_and_align(req.mask | entry_mask[i])
                    & ~((d_valid & d_source == IDX_W'(i)) | (st_valid[i] & st_wait_return[i]));
      merge_secondary = st_valid[i] & ~st_inflight[i] & ~(a_fire & q0_idx == IDX_W'(i));
      e0_reject_vec[i]          = hit & ~merge_primary;
      e0_merge_vec[i]           = hit & merge_primary & merge_secondary;
      e0_alloc_wait_same_vec[i] = hit & merge_primary & ~merge_secondary;
      e0_invalid_vec[i]         = ~st_valid[i];
    end
  end

  logic             e0_can_merge, e0_can_alloc, e0_alloc_wait_same, e0_reject, e0_fire;
  logic [IDX_W-1:0] e0_merge_idx, e0_alloc_idx;

  assign e0_merge_idx       = lowest_idx(e0_merge_vec);
  assign e0_can_merge       = |e0_merge_vec;
  assign e0_alloc_idx       = lowest_idx(e0_invalid_vec);
  assign e0_can_alloc       = |e0_invalid_vec;
  assign e0_alloc_wait_same = |e0_alloc_wait_same_vec;
  assign e0_reject = do_uarch_drain | (~e0_can_merge & ~(|e0_invalid_vec)) | (|e0_reject_vec);
  assign req_ready = ~e0_reject;
  assign e0_fire   = req_valid & ~e0_reject;

  logic e0_do_merge, e0_do_alloc;   // 本拍实际走哪条路（合并优先）
  assign e0_do_merge = e0_fire & e0_can_merge;
  assign e0_do_alloc = e0_fire & ~e0_can_merge & e0_can_alloc;

  // 合并：新字节覆盖旧字节；地址低 3 位改成合并后掩码的最低有效字节
  logic [63:0] merge_data;
  logic [7:0]  merge_mask;
  logic [2:0]  merge_offset;
  always_comb begin
    merge_mask = req.mask | entry_mask[e0_merge_idx];
    for (int j = 0; j < 8; j++)
      merge_data[8*j +: 8] = req.mask[j] ? req.data[8*j +: 8] : entry_data[e0_merge_idx][8*j +: 8];
    merge_offset = 3'h7;
    for (int j = 7; j >= 0; j--)
      if (merge_mask[j]) merge_offset = 3'(j);
  end

  // e1：下一拍告诉 LSQ 分到了哪一项
  logic     id_resp_valid_q;
  id_resp_t id_resp_q;
  always_ff @(posedge clock) begin
    id_resp_valid_q <= e0_fire;
    if (e0_fire) begin
      id_resp_q.mid   <= req.id;
      id_resp_q.sid   <= e0_can_merge ? e0_merge_idx : e0_alloc_idx;
      id_resp_q.is2lq <= req.cmd != M_XWR;
      id_resp_q.nc    <= req.nc;
    end
  end
  assign id_resp_valid = id_resp_valid_q;
  assign id_resp       = id_resp_q;

  // ===========================================================================
  // §3 q0 发出：可发 = 占用且不在路上、不等同块、不等交回；关 outstanding 时还要
  //    单笔状态机空闲。挑编号最小的，拼 TileLink：写 = PutPartialData（带掩码数据），
  //    读 = Get（掩码按 lgSize 自然对齐）。lgSize 由掩码里 1 的个数得出。
  //    WFI 请求期间不发新的（a_valid 被压住，但状态照常可选）。
  // ===========================================================================
  logic [N-1:0] q0_can_sent_vec;
  logic         q0_can_sent, q0_is_store;
  logic [3:0]   q0_bytes;
  logic [1:0]   q0_lg_size;

  always_comb
    for (int i = 0; i < N; i++)
      q0_can_sent_vec[i] = (enable_outstanding | u_state == S_IDLE)
                         & st_valid[i] & ~st_inflight[i] & ~st_wait_same[i] & ~st_wait_return[i];

  assign q0_idx      = lowest_idx(q0_can_sent_vec);
  assign q0_can_sent = |q0_can_sent_vec;
  assign q0_is_store = entry_cmd[q0_idx] == M_XWR;
  assign q0_bytes    = popcount8(entry_mask[q0_idx]);
  assign q0_lg_size  = q0_bytes == 4'd1 ? 2'd0 :
                       q0_bytes == 4'd2 ? 2'd1 :
                       q0_bytes == 4'd4 ? 2'd2 : 2'd3;

  assign a_valid   = q0_can_sent & ~wfi_req;
  assign a_fire    = a_ready & a_valid;
  assign a_opcode  = q0_is_store ? TL_PUT_PARTIAL : TL_GET;
  assign a_size    = q0_lg_size;
  assign a_source  = q0_idx;
  assign a_address = entry_addr[q0_idx];
  assign a_user_nc = entry_nc[q0_idx];
  assign a_user_mm = entry_mm[q0_idx];
  assign a_mask    = q0_is_store ? entry_mask[q0_idx]
                                 : tl_get_mask(entry_addr[q0_idx][2:0], q0_lg_size);
  assign a_data    = q0_is_store ? entry_data[q0_idx] : 64'h0;

  // difftest（DiffUncacheMMStoreEvent）：后端是主存的 MMIO 写，发出时同步给 golden 内存。
  // 打包顺序 = {valid, addr(64), data(64), mask, coreid, index}
  logic difftest_valid;
  assign difftest_valid = a_fire & q0_is_store & entry_mm[q0_idx];
  assign difftest_bore  = {difftest_valid,
                           16'h0, entry_addr[q0_idx],
                           entry_data[q0_idx],
                           entry_mask[q0_idx],
                           2'h0, hart_id,
                           8'h0};

  // ===========================================================================
  // §4 D 响应：source 就是项号。写回读数据（仅读请求）与错误位；写请求出错报总线错误
  //    （地址对齐到 64 字节行）。同块等待的解除在 §7。
  // ===========================================================================
  assign bus_error_valid = d_valid & entry_cmd[d_source] == M_XWR & (d_denied | d_corrupt);
  assign bus_error_addr  = {entry_addr[d_source][PADDR_W-1:6], 6'h0};

  // ===========================================================================
  // §5 r0 交回 LSQ：等交回的项里挑编号最小的
  // ===========================================================================
  logic [N-1:0] r0_can_sent_vec;
  assign r0_can_sent_vec = st_valid & st_wait_return;
  assign r0_idx          = lowest_idx(r0_can_sent_vec);
  assign resp_valid      = |r0_can_sent_vec;
  assign resp_fire       = resp_ready & resp_valid;
  assign resp.data       = entry_data[r0_idx];
  assign resp.id         = r0_idx;
  assign resp.nc         = entry_nc[r0_idx];
  assign resp.is2lq      = entry_cmd[r0_idx] == M_XRD;
  assign resp.denied     = entry_denied[r0_idx];
  assign resp.corrupt    = entry_corrupt[r0_idx];

  assign empty       = ~(|st_valid);
  assign flush_empty = empty;

  // ===========================================================================
  // §6 前递给 load（每条 load 流水两拍）
  //   f0：按 vaddr 块匹配所有"是 store 的占用项"，分两类 ——
  //       fly  = 已发出或已回来（inflight | waitReturn），数据较旧；
  //       idle = 还没发、正挂着等同块（waitSame），数据较新。
  //   f1：用打一拍的匹配向量从候选寄存器里 Mux1H 出 fly / idle 两份，按字节 idle 覆盖 fly；
  //       按 paddr[3] 放到 16 字节前递窗口的高/低半。再用 paddr 重新比一遍块地址，
  //       与 f0 的 vaddr 结论不一致就报 matchInvalid（并触发 drain）。
  //   候选寄存器（mask/data）三条流水共用一份，按"该项是 store 且占用"每拍更新。
  // ===========================================================================
  logic [N-1:0] f0_valid_mask;     // 本项是占用的 store
  logic [N-1:0] fwd_old, fwd_new;  // isFwdOld / isFwdNew
  always_comb
    for (int w = 0; w < N; w++) begin
      f0_valid_mask[w] = entry_cmd[w] == M_XWR & st_valid[w];
      fwd_old[w]       = st_valid[w] & (st_inflight[w] | st_wait_return[w]);
      fwd_new[w]       = st_valid[w] & ~st_inflight[w] & ~st_wait_return[w] & st_wait_same[w];
    end

  logic [7:0]  f1_cand_mask [N];
  logic [63:0] f1_cand_data [N];
  always_ff @(posedge clock)
    for (int w = 0; w < N; w++)
      if (f0_valid_mask[w]) begin
        f1_cand_mask[w] <= entry_mask[w];
        f1_cand_data[w] <= entry_data[w];
      end

  logic [N-1:0] f0_vtag_match [LOAD_PIPES];
  logic [N-1:0] f0_fly_match  [LOAD_PIPES];
  logic [N-1:0] f0_idle_match [LOAD_PIPES];
  always_comb
    for (int p = 0; p < LOAD_PIPES; p++)
      for (int w = 0; w < N; w++) begin
        f0_vtag_match[p][w] = same_block_v(entry_vaddr[w], fwd_vaddr[p]);
        f0_fly_match[p][w]  = f0_vtag_match[p][w] & f0_valid_mask[w] & fwd_valid[p] & fwd_old[w];
        f0_idle_match[p][w] = f0_vtag_match[p][w] & f0_valid_mask[w] & fwd_valid[p] & fwd_new[w];
      end

  // f1 寄存器（每条流水一份；f1_fwd_valid 每拍打，其余只在 f0 valid 时锁存）
  logic [LOAD_PIPES-1:0] f1_fwd_valid;
  logic [N-1:0]          f1_fly_match    [LOAD_PIPES];
  logic [N-1:0]          f1_idle_match   [LOAD_PIPES];
  logic [PADDR_W-1:0]    f1_paddr        [LOAD_PIPES];   // 只读 [47:3]
  logic [PADDR_W-1:0]    f1_entry_addr   [LOAD_PIPES][N]; // 只读 [47:3]
  logic [N-1:0]          f1_vtag_match   [LOAD_PIPES];
  logic [N-1:0]          f1_valid_mask   [LOAD_PIPES];
  always_ff @(posedge clock)
    for (int p = 0; p < LOAD_PIPES; p++) begin
      f1_fwd_valid[p] <= fwd_valid[p];
      if (fwd_valid[p]) begin
        f1_fly_match[p]  <= f0_fly_match[p];
        f1_idle_match[p] <= f0_idle_match[p];
        f1_paddr[p]      <= fwd_paddr[p];
        for (int w = 0; w < N; w++)
          f1_entry_addr[p][w] <= entry_addr[w];
        f1_vtag_match[p] <= f0_vtag_match[p];
        f1_valid_mask[p] <= f0_valid_mask;
      end
    end

  logic [LOAD_PIPES-1:0] f1_mismatch;
  always_comb
    for (int p = 0; p < LOAD_PIPES; p++) begin
      logic [7:0]  fly_mask, idle_mask, sel_mask;
      logic [63:0] fly_data, idle_data, sel_data;
      logic [N-1:0] mismatch_vec;
      fly_mask = '0; fly_data = '0; idle_mask = '0; idle_data = '0;
      for (int w = 0; w < N; w++) begin     // Mux1H：按位或
        if (f1_fly_match[p][w])  begin fly_mask  |= f1_cand_mask[w]; fly_data  |= f1_cand_data[w]; end
        if (f1_idle_match[p][w]) begin idle_mask |= f1_cand_mask[w]; idle_data |= f1_cand_data[w]; end
      end
      sel_mask = idle_mask | fly_mask;      // 新（idle）按字节覆盖旧（fly）
      for (int j = 0; j < 8; j++)
        sel_data[8*j +: 8] = idle_mask[j] ? idle_data[8*j +: 8] : fly_data[8*j +: 8];
      fwd_mask[p] = (f1_paddr[p][3] ? {sel_mask, 8'h0} : {8'h0, sel_mask}) & {16{f1_fwd_valid[p]}};
      fwd_data[p] = f1_paddr[p][3] ? {sel_data, 64'h0} : {64'h0, sel_data};
      for (int w = 0; w < N; w++)
        mismatch_vec[w] = (f1_vtag_match[p][w] != same_block_p(f1_entry_addr[p][w], f1_paddr[p]))
                        & f1_valid_mask[p][w] & f1_fwd_valid[p];
      f1_mismatch[p] = |mismatch_vec;
    end
  assign fwd_match_invalid = f1_mismatch;
  assign f1_need_drain     = (|f1_mismatch) & ~empty;

  // ===========================================================================
  // §7 状态更新。同一拍多个事件落到同一项时，按 Chisel 的连接顺序后者覆盖前者：
  //    e0 分配/合并  <  q0 发出  <  D 响应  <  r0 交回。
  // ===========================================================================
  // 7a 条目字段（不复位）
  always_ff @(posedge clock)
    for (int i = 0; i < N; i++) begin
      if (e0_do_merge && e0_merge_idx == IDX_W'(i)) begin
        entry_data[i] <= merge_data;
        entry_mask[i] <= merge_mask;
        if (|merge_mask) begin
          entry_addr[i]  <= {entry_addr[i][PADDR_W-1:BLOCK_OFF], merge_offset};
          entry_vaddr[i] <= {entry_vaddr[i][VADDR_W-1:BLOCK_OFF], merge_offset};
        end
      end
      else if (e0_do_alloc && e0_alloc_idx == IDX_W'(i)) begin
        entry_cmd[i]   <= req.cmd;
        entry_addr[i]  <= req.addr;
        entry_vaddr[i] <= req.vaddr;
        entry_data[i]  <= req.data;
        entry_mask[i]  <= req.mask;
        entry_nc[i]    <= req.nc;
        entry_mm[i]    <= req.memBackTypeMM;
      end
      if (d_valid && d_source == IDX_W'(i)) begin
        if (entry_cmd[i] == M_XRD)
          entry_data[i] <= d_data;
        entry_denied[i]  <= d_denied;
        entry_corrupt[i] <= d_corrupt;
      end
    end

  // 7b 生命周期（异步复位）
  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      st_valid       <= '0;
      st_inflight    <= '0;
      st_wait_same   <= '0;
      st_wait_return <= '0;
      no_pending     <= '1;
    end
    else
      for (int i = 0; i < N; i++) begin
        // e0：分配占用；同块旧项已发出则挂等待
        if (e0_do_alloc && e0_alloc_idx == IDX_W'(i)) begin
          st_valid[i] <= 1'b1;
          if (e0_alloc_wait_same) st_wait_same[i] <= 1'b1;
        end
        // q0：发出的那项进 inflight；其余同块、未在等交回的占用项挂等待
        if (a_fire) begin
          if (q0_idx == IDX_W'(i)) begin
            st_inflight[i] <= 1'b1;
            no_pending[i]  <= 1'b0;
          end
          else if (st_valid[i] && !(st_valid[i] && st_wait_return[i])
                   && same_block_p(entry_addr[q0_idx], entry_addr[i]))
            st_wait_same[i] <= 1'b1;
        end
        // D：本项 inflight → waitReturn；解除同块其他项的等待
        if (d_valid) begin
          if (d_source == IDX_W'(i)) begin
            st_inflight[i]    <= 1'b0;
            st_wait_return[i] <= 1'b1;
            no_pending[i]     <= 1'b1;
          end
          else if (st_valid[i] && st_wait_same[i]
                   && same_block_p(entry_addr[d_source], entry_addr[i]))
            st_wait_same[i] <= 1'b0;
        end
        // r0：交回后整项清空
        if (resp_fire && r0_idx == IDX_W'(i)) begin
          st_valid[i]       <= 1'b0;
          st_inflight[i]    <= 1'b0;
          st_wait_same[i]   <= 1'b0;
          st_wait_return[i] <= 1'b0;
        end
      end

  // 7c uState / drain / WFI（异步复位）
  logic wfi_safe_q;
  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      u_state        <= S_IDLE;
      do_uarch_drain <= 1'b0;
      wfi_safe_q     <= 1'b0;
    end
    else begin
      case (u_state)
        S_IDLE:        if (a_fire)    u_state <= S_INFLIGHT;
        S_INFLIGHT:    if (d_valid)   u_state <= S_WAIT_RETURN;
        S_WAIT_RETURN: if (resp_fire) u_state <= S_IDLE;
        default: ;
      endcase
      do_uarch_drain <= (f1_need_drain | flush_valid) & ~empty;
      wfi_safe_q     <= (&no_pending) & wfi_req;
    end
  assign wfi_safe = wfi_safe_q;

endmodule

// BEGIN GENERATED(uncache_wrapper)
// wrapper：端口与 golden Uncache 逐位同名同序；只做扁平端口 ↔ 核 struct/数组的对位。
// 由 scripts/gen_uncache.py 生成，勿手改。
module Uncache
  import uncache_pkg::*;
(
  input          clock,
  input          reset,
  input          auto_client_out_a_ready,
  output         auto_client_out_a_valid,
  output [3:0]   auto_client_out_a_bits_opcode,
  output [1:0]   auto_client_out_a_bits_size,
  output [3:0]   auto_client_out_a_bits_source,
  output [47:0]  auto_client_out_a_bits_address,
  output         auto_client_out_a_bits_user_memPageType_NC,
  output         auto_client_out_a_bits_user_memBackType_MM,
  output [7:0]   auto_client_out_a_bits_mask,
  output [63:0]  auto_client_out_a_bits_data,
  input          auto_client_out_d_valid,
  input  [3:0]   auto_client_out_d_bits_source,
  input          auto_client_out_d_bits_denied,
  input  [63:0]  auto_client_out_d_bits_data,
  input          auto_client_out_d_bits_corrupt,
  input  [5:0]   io_hartId,
  input          io_enableOutstanding,
  input          io_flush_valid,
  output         io_flush_empty,
  output         io_lsq_req_ready,
  input          io_lsq_req_valid,
  input  [4:0]   io_lsq_req_bits_cmd,
  input  [47:0]  io_lsq_req_bits_addr,
  input  [49:0]  io_lsq_req_bits_vaddr,
  input  [63:0]  io_lsq_req_bits_data,
  input  [7:0]   io_lsq_req_bits_mask,
  input  [6:0]   io_lsq_req_bits_id,
  input          io_lsq_req_bits_nc,
  input          io_lsq_req_bits_memBackTypeMM,
  output         io_lsq_idResp_valid,
  output [6:0]   io_lsq_idResp_bits_mid,
  output [3:0]   io_lsq_idResp_bits_sid,
  output         io_lsq_idResp_bits_is2lq,
  output         io_lsq_idResp_bits_nc,
  input          io_lsq_resp_ready,
  output         io_lsq_resp_valid,
  output [63:0]  io_lsq_resp_bits_data,
  output [3:0]   io_lsq_resp_bits_id,
  output         io_lsq_resp_bits_nc,
  output         io_lsq_resp_bits_is2lq,
  output         io_lsq_resp_bits_denied,
  output         io_lsq_resp_bits_corrupt,
  input  [49:0]  io_forward_0_vaddr,
  input  [47:0]  io_forward_0_paddr,
  input          io_forward_0_valid,
  output         io_forward_0_forwardMask_0,
  output         io_forward_0_forwardMask_1,
  output         io_forward_0_forwardMask_2,
  output         io_forward_0_forwardMask_3,
  output         io_forward_0_forwardMask_4,
  output         io_forward_0_forwardMask_5,
  output         io_forward_0_forwardMask_6,
  output         io_forward_0_forwardMask_7,
  output         io_forward_0_forwardMask_8,
  output         io_forward_0_forwardMask_9,
  output         io_forward_0_forwardMask_10,
  output         io_forward_0_forwardMask_11,
  output         io_forward_0_forwardMask_12,
  output         io_forward_0_forwardMask_13,
  output         io_forward_0_forwardMask_14,
  output         io_forward_0_forwardMask_15,
  output [7:0]   io_forward_0_forwardData_0,
  output [7:0]   io_forward_0_forwardData_1,
  output [7:0]   io_forward_0_forwardData_2,
  output [7:0]   io_forward_0_forwardData_3,
  output [7:0]   io_forward_0_forwardData_4,
  output [7:0]   io_forward_0_forwardData_5,
  output [7:0]   io_forward_0_forwardData_6,
  output [7:0]   io_forward_0_forwardData_7,
  output [7:0]   io_forward_0_forwardData_8,
  output [7:0]   io_forward_0_forwardData_9,
  output [7:0]   io_forward_0_forwardData_10,
  output [7:0]   io_forward_0_forwardData_11,
  output [7:0]   io_forward_0_forwardData_12,
  output [7:0]   io_forward_0_forwardData_13,
  output [7:0]   io_forward_0_forwardData_14,
  output [7:0]   io_forward_0_forwardData_15,
  output         io_forward_0_matchInvalid,
  input  [49:0]  io_forward_1_vaddr,
  input  [47:0]  io_forward_1_paddr,
  input          io_forward_1_valid,
  output         io_forward_1_forwardMask_0,
  output         io_forward_1_forwardMask_1,
  output         io_forward_1_forwardMask_2,
  output         io_forward_1_forwardMask_3,
  output         io_forward_1_forwardMask_4,
  output         io_forward_1_forwardMask_5,
  output         io_forward_1_forwardMask_6,
  output         io_forward_1_forwardMask_7,
  output         io_forward_1_forwardMask_8,
  output         io_forward_1_forwardMask_9,
  output         io_forward_1_forwardMask_10,
  output         io_forward_1_forwardMask_11,
  output         io_forward_1_forwardMask_12,
  output         io_forward_1_forwardMask_13,
  output         io_forward_1_forwardMask_14,
  output         io_forward_1_forwardMask_15,
  output [7:0]   io_forward_1_forwardData_0,
  output [7:0]   io_forward_1_forwardData_1,
  output [7:0]   io_forward_1_forwardData_2,
  output [7:0]   io_forward_1_forwardData_3,
  output [7:0]   io_forward_1_forwardData_4,
  output [7:0]   io_forward_1_forwardData_5,
  output [7:0]   io_forward_1_forwardData_6,
  output [7:0]   io_forward_1_forwardData_7,
  output [7:0]   io_forward_1_forwardData_8,
  output [7:0]   io_forward_1_forwardData_9,
  output [7:0]   io_forward_1_forwardData_10,
  output [7:0]   io_forward_1_forwardData_11,
  output [7:0]   io_forward_1_forwardData_12,
  output [7:0]   io_forward_1_forwardData_13,
  output [7:0]   io_forward_1_forwardData_14,
  output [7:0]   io_forward_1_forwardData_15,
  output         io_forward_1_matchInvalid,
  input  [49:0]  io_forward_2_vaddr,
  input  [47:0]  io_forward_2_paddr,
  input          io_forward_2_valid,
  output         io_forward_2_forwardMask_0,
  output         io_forward_2_forwardMask_1,
  output         io_forward_2_forwardMask_2,
  output         io_forward_2_forwardMask_3,
  output         io_forward_2_forwardMask_4,
  output         io_forward_2_forwardMask_5,
  output         io_forward_2_forwardMask_6,
  output         io_forward_2_forwardMask_7,
  output         io_forward_2_forwardMask_8,
  output         io_forward_2_forwardMask_9,
  output         io_forward_2_forwardMask_10,
  output         io_forward_2_forwardMask_11,
  output         io_forward_2_forwardMask_12,
  output         io_forward_2_forwardMask_13,
  output         io_forward_2_forwardMask_14,
  output         io_forward_2_forwardMask_15,
  output [7:0]   io_forward_2_forwardData_0,
  output [7:0]   io_forward_2_forwardData_1,
  output [7:0]   io_forward_2_forwardData_2,
  output [7:0]   io_forward_2_forwardData_3,
  output [7:0]   io_forward_2_forwardData_4,
  output [7:0]   io_forward_2_forwardData_5,
  output [7:0]   io_forward_2_forwardData_6,
  output [7:0]   io_forward_2_forwardData_7,
  output [7:0]   io_forward_2_forwardData_8,
  output [7:0]   io_forward_2_forwardData_9,
  output [7:0]   io_forward_2_forwardData_10,
  output [7:0]   io_forward_2_forwardData_11,
  output [7:0]   io_forward_2_forwardData_12,
  output [7:0]   io_forward_2_forwardData_13,
  output [7:0]   io_forward_2_forwardData_14,
  output [7:0]   io_forward_2_forwardData_15,
  output         io_forward_2_matchInvalid,
  input          io_wfi_wfiReq,
  output         io_wfi_wfiSafe,
  output         io_busError_ecc_error_valid,
  output [47:0]  io_busError_ecc_error_bits,
  output [152:0] gatewayIn_packed_42_bore
);
  // ---- 核侧的 struct / 数组线
  lsq_req_t req;
  id_resp_t id_resp;
  lsq_resp_t resp;
  logic [LOAD_PIPES-1:0][VADDR_W-1:0] fwd_vaddr;
  logic [LOAD_PIPES-1:0][PADDR_W-1:0] fwd_paddr;
  logic [LOAD_PIPES-1:0] fwd_valid;
  logic [LOAD_PIPES-1:0][15:0] fwd_mask;
  logic [LOAD_PIPES-1:0][15:0][7:0] fwd_data;
  logic [LOAD_PIPES-1:0] fwd_match_invalid;

  // ---- 输入：golden 扁平端口 → 核
  assign req.cmd = io_lsq_req_bits_cmd;
  assign req.addr = io_lsq_req_bits_addr;
  assign req.vaddr = io_lsq_req_bits_vaddr;
  assign req.data = io_lsq_req_bits_data;
  assign req.mask = io_lsq_req_bits_mask;
  assign req.id = io_lsq_req_bits_id;
  assign req.nc = io_lsq_req_bits_nc;
  assign req.memBackTypeMM = io_lsq_req_bits_memBackTypeMM;
  assign fwd_vaddr[0] = io_forward_0_vaddr;
  assign fwd_paddr[0] = io_forward_0_paddr;
  assign fwd_valid[0] = io_forward_0_valid;
  assign fwd_vaddr[1] = io_forward_1_vaddr;
  assign fwd_paddr[1] = io_forward_1_paddr;
  assign fwd_valid[1] = io_forward_1_valid;
  assign fwd_vaddr[2] = io_forward_2_vaddr;
  assign fwd_paddr[2] = io_forward_2_paddr;
  assign fwd_valid[2] = io_forward_2_valid;

  // ---- 核例化
  xs_Uncache_core u_core (
    .clock                (clock),
    .reset                (reset),
    .a_ready              (auto_client_out_a_ready),
    .a_valid              (auto_client_out_a_valid),
    .a_opcode             (auto_client_out_a_bits_opcode),
    .a_size               (auto_client_out_a_bits_size),
    .a_source             (auto_client_out_a_bits_source),
    .a_address            (auto_client_out_a_bits_address),
    .a_user_nc            (auto_client_out_a_bits_user_memPageType_NC),
    .a_user_mm            (auto_client_out_a_bits_user_memBackType_MM),
    .a_mask               (auto_client_out_a_bits_mask),
    .a_data               (auto_client_out_a_bits_data),
    .d_valid              (auto_client_out_d_valid),
    .d_source             (auto_client_out_d_bits_source),
    .d_denied             (auto_client_out_d_bits_denied),
    .d_data               (auto_client_out_d_bits_data),
    .d_corrupt            (auto_client_out_d_bits_corrupt),
    .hart_id              (io_hartId),
    .enable_outstanding   (io_enableOutstanding),
    .flush_valid          (io_flush_valid),
    .flush_empty          (io_flush_empty),
    .req_ready            (io_lsq_req_ready),
    .req_valid            (io_lsq_req_valid),
    .req                  (req),
    .id_resp_valid        (io_lsq_idResp_valid),
    .id_resp              (id_resp),
    .resp_ready           (io_lsq_resp_ready),
    .resp_valid           (io_lsq_resp_valid),
    .resp                 (resp),
    .fwd_vaddr            (fwd_vaddr),
    .fwd_paddr            (fwd_paddr),
    .fwd_valid            (fwd_valid),
    .fwd_mask             (fwd_mask),
    .fwd_data             (fwd_data),
    .fwd_match_invalid    (fwd_match_invalid),
    .wfi_req              (io_wfi_wfiReq),
    .wfi_safe             (io_wfi_wfiSafe),
    .bus_error_valid      (io_busError_ecc_error_valid),
    .bus_error_addr       (io_busError_ecc_error_bits),
    .difftest_bore        (gatewayIn_packed_42_bore)
  );

  // ---- 输出：核 → golden 扁平端口
  assign io_lsq_idResp_bits_mid = id_resp.mid;
  assign io_lsq_idResp_bits_sid = id_resp.sid;
  assign io_lsq_idResp_bits_is2lq = id_resp.is2lq;
  assign io_lsq_idResp_bits_nc = id_resp.nc;
  assign io_lsq_resp_bits_data = resp.data;
  assign io_lsq_resp_bits_id = resp.id;
  assign io_lsq_resp_bits_nc = resp.nc;
  assign io_lsq_resp_bits_is2lq = resp.is2lq;
  assign io_lsq_resp_bits_denied = resp.denied;
  assign io_lsq_resp_bits_corrupt = resp.corrupt;
  assign io_forward_0_forwardMask_0 = fwd_mask[0][0];
  assign io_forward_0_forwardMask_1 = fwd_mask[0][1];
  assign io_forward_0_forwardMask_2 = fwd_mask[0][2];
  assign io_forward_0_forwardMask_3 = fwd_mask[0][3];
  assign io_forward_0_forwardMask_4 = fwd_mask[0][4];
  assign io_forward_0_forwardMask_5 = fwd_mask[0][5];
  assign io_forward_0_forwardMask_6 = fwd_mask[0][6];
  assign io_forward_0_forwardMask_7 = fwd_mask[0][7];
  assign io_forward_0_forwardMask_8 = fwd_mask[0][8];
  assign io_forward_0_forwardMask_9 = fwd_mask[0][9];
  assign io_forward_0_forwardMask_10 = fwd_mask[0][10];
  assign io_forward_0_forwardMask_11 = fwd_mask[0][11];
  assign io_forward_0_forwardMask_12 = fwd_mask[0][12];
  assign io_forward_0_forwardMask_13 = fwd_mask[0][13];
  assign io_forward_0_forwardMask_14 = fwd_mask[0][14];
  assign io_forward_0_forwardMask_15 = fwd_mask[0][15];
  assign io_forward_0_forwardData_0 = fwd_data[0][0];
  assign io_forward_0_forwardData_1 = fwd_data[0][1];
  assign io_forward_0_forwardData_2 = fwd_data[0][2];
  assign io_forward_0_forwardData_3 = fwd_data[0][3];
  assign io_forward_0_forwardData_4 = fwd_data[0][4];
  assign io_forward_0_forwardData_5 = fwd_data[0][5];
  assign io_forward_0_forwardData_6 = fwd_data[0][6];
  assign io_forward_0_forwardData_7 = fwd_data[0][7];
  assign io_forward_0_forwardData_8 = fwd_data[0][8];
  assign io_forward_0_forwardData_9 = fwd_data[0][9];
  assign io_forward_0_forwardData_10 = fwd_data[0][10];
  assign io_forward_0_forwardData_11 = fwd_data[0][11];
  assign io_forward_0_forwardData_12 = fwd_data[0][12];
  assign io_forward_0_forwardData_13 = fwd_data[0][13];
  assign io_forward_0_forwardData_14 = fwd_data[0][14];
  assign io_forward_0_forwardData_15 = fwd_data[0][15];
  assign io_forward_0_matchInvalid = fwd_match_invalid[0];
  assign io_forward_1_forwardMask_0 = fwd_mask[1][0];
  assign io_forward_1_forwardMask_1 = fwd_mask[1][1];
  assign io_forward_1_forwardMask_2 = fwd_mask[1][2];
  assign io_forward_1_forwardMask_3 = fwd_mask[1][3];
  assign io_forward_1_forwardMask_4 = fwd_mask[1][4];
  assign io_forward_1_forwardMask_5 = fwd_mask[1][5];
  assign io_forward_1_forwardMask_6 = fwd_mask[1][6];
  assign io_forward_1_forwardMask_7 = fwd_mask[1][7];
  assign io_forward_1_forwardMask_8 = fwd_mask[1][8];
  assign io_forward_1_forwardMask_9 = fwd_mask[1][9];
  assign io_forward_1_forwardMask_10 = fwd_mask[1][10];
  assign io_forward_1_forwardMask_11 = fwd_mask[1][11];
  assign io_forward_1_forwardMask_12 = fwd_mask[1][12];
  assign io_forward_1_forwardMask_13 = fwd_mask[1][13];
  assign io_forward_1_forwardMask_14 = fwd_mask[1][14];
  assign io_forward_1_forwardMask_15 = fwd_mask[1][15];
  assign io_forward_1_forwardData_0 = fwd_data[1][0];
  assign io_forward_1_forwardData_1 = fwd_data[1][1];
  assign io_forward_1_forwardData_2 = fwd_data[1][2];
  assign io_forward_1_forwardData_3 = fwd_data[1][3];
  assign io_forward_1_forwardData_4 = fwd_data[1][4];
  assign io_forward_1_forwardData_5 = fwd_data[1][5];
  assign io_forward_1_forwardData_6 = fwd_data[1][6];
  assign io_forward_1_forwardData_7 = fwd_data[1][7];
  assign io_forward_1_forwardData_8 = fwd_data[1][8];
  assign io_forward_1_forwardData_9 = fwd_data[1][9];
  assign io_forward_1_forwardData_10 = fwd_data[1][10];
  assign io_forward_1_forwardData_11 = fwd_data[1][11];
  assign io_forward_1_forwardData_12 = fwd_data[1][12];
  assign io_forward_1_forwardData_13 = fwd_data[1][13];
  assign io_forward_1_forwardData_14 = fwd_data[1][14];
  assign io_forward_1_forwardData_15 = fwd_data[1][15];
  assign io_forward_1_matchInvalid = fwd_match_invalid[1];
  assign io_forward_2_forwardMask_0 = fwd_mask[2][0];
  assign io_forward_2_forwardMask_1 = fwd_mask[2][1];
  assign io_forward_2_forwardMask_2 = fwd_mask[2][2];
  assign io_forward_2_forwardMask_3 = fwd_mask[2][3];
  assign io_forward_2_forwardMask_4 = fwd_mask[2][4];
  assign io_forward_2_forwardMask_5 = fwd_mask[2][5];
  assign io_forward_2_forwardMask_6 = fwd_mask[2][6];
  assign io_forward_2_forwardMask_7 = fwd_mask[2][7];
  assign io_forward_2_forwardMask_8 = fwd_mask[2][8];
  assign io_forward_2_forwardMask_9 = fwd_mask[2][9];
  assign io_forward_2_forwardMask_10 = fwd_mask[2][10];
  assign io_forward_2_forwardMask_11 = fwd_mask[2][11];
  assign io_forward_2_forwardMask_12 = fwd_mask[2][12];
  assign io_forward_2_forwardMask_13 = fwd_mask[2][13];
  assign io_forward_2_forwardMask_14 = fwd_mask[2][14];
  assign io_forward_2_forwardMask_15 = fwd_mask[2][15];
  assign io_forward_2_forwardData_0 = fwd_data[2][0];
  assign io_forward_2_forwardData_1 = fwd_data[2][1];
  assign io_forward_2_forwardData_2 = fwd_data[2][2];
  assign io_forward_2_forwardData_3 = fwd_data[2][3];
  assign io_forward_2_forwardData_4 = fwd_data[2][4];
  assign io_forward_2_forwardData_5 = fwd_data[2][5];
  assign io_forward_2_forwardData_6 = fwd_data[2][6];
  assign io_forward_2_forwardData_7 = fwd_data[2][7];
  assign io_forward_2_forwardData_8 = fwd_data[2][8];
  assign io_forward_2_forwardData_9 = fwd_data[2][9];
  assign io_forward_2_forwardData_10 = fwd_data[2][10];
  assign io_forward_2_forwardData_11 = fwd_data[2][11];
  assign io_forward_2_forwardData_12 = fwd_data[2][12];
  assign io_forward_2_forwardData_13 = fwd_data[2][13];
  assign io_forward_2_forwardData_14 = fwd_data[2][14];
  assign io_forward_2_forwardData_15 = fwd_data[2][15];
  assign io_forward_2_matchInvalid = fwd_match_invalid[2];
endmodule
// END GENERATED
