// =============================================================================
//  StorePipe —— DCache store 探测流水(可读重写, 从 Scala 设计意图实现)
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/cache/dcache/storepipe/StorePipe.scala
//  类型/参数包：rtl/memblock/storepipe_pkg.sv    学习文档：docs/memblock/StorePipe.md
//
//  ⚠️ 重要：本顶层配置(KunmingHu V2R2)下, golden StorePipe.sv 被 firtool 完全裁剪
//     成「只有 input io_lsu_req_valid、无任何输出/寄存器」的空壳(原因见 pkg 注释:
//     DCache 例化时其所有输出悬空 + EnableStorePrefetchAtIssue=false → 死代码消除)。
//     因此:
//       - 顶层 golden 同名模块 `StorePipe`(见 StorePipe_wrapper.sv)只暴露这唯一端口,
//         用于 FM 与 ST 对接(与 golden 逐端口一致)。
//       - 下面的 `xs_StorePipe_core` 是**完整三级流水的可读实现**(学习载体),
//         它体现 StorePipe 在「未裁剪」配置下的真实微架构, 不参与本配置的 FM
//         (本配置 golden 无对应逻辑)。这与 StorePfWrapper 的处理方式一致。
//
//  StorePipe 是与 LoadPipe 对称的「store 探测流水」: STA(store 地址)流水在 s1 拿到
//  paddr 后, 经它查 DCache 的 tag/meta 判断 store 是否命中; 缺失时(视配置)向 DCache
//  MissQueue 发一个 store 写预取请求(M_PFW), 命中时(可选)更新替换算法让该行多留。
//  它**不写数据**(store 数据走 StoreQueue→Sbuffer 通路)。
//
//  三级流水(与 Scala 一致):
//    s0  收 STA 请求 → 用 vaddr[13:6] 发 meta_read / tag_read
//    s1  收 meta/tag resp → 4 路 tag 比对 + onAccess 权限判定 → hit/miss
//    s2  hit: 更新 replacer(本配置 disable); miss: 发 store 写预取 MissReq;
//        回 STA resp(miss = ~hit)
// =============================================================================
module xs_StorePipe_core #(
  parameter int N_WAYS   = storepipe_pkg::N_WAYS,
  parameter int TAG_BITS = storepipe_pkg::TAG_BITS,
  // 本顶层 EnableStorePrefetchAtIssue=false: 仅「预取来源的 miss store」发 MissReq。
  parameter bit EN_STORE_PF_AT_ISSUE = 1'b0
)(
  input  logic        clock,
  input  logic        reset,

  // ---- STA 请求(io.lsu.req) ----
  input  logic        io_lsu_req_valid,
  input  logic [4:0]  io_lsu_req_bits_cmd,
  input  logic [49:0] io_lsu_req_bits_vaddr,
  input  logic [3:0]  io_lsu_req_bits_instrtype,
  output logic        io_lsu_req_ready,
  // s1 物理地址 / s1 kill(TLB miss/异常) / s2 kill(AF/MMIO) / 调试 pc
  input  logic [47:0] io_lsu_s1_paddr,
  input  logic        io_lsu_s1_kill,
  input  logic        io_lsu_s2_kill,
  input  logic [49:0] io_lsu_s2_pc,
  // ---- STA 响应(io.lsu.resp) ----
  output logic        io_lsu_resp_valid,
  output logic        io_lsu_resp_bits_miss,
  output logic        io_lsu_resp_bits_replay,
  output logic        io_lsu_resp_bits_tag_error,

  // ---- meta / tag 组读 ----
  input  logic                       io_meta_read_ready,
  output logic                       io_meta_read_valid,
  output logic [storepipe_pkg::IDX_BITS-1:0] io_meta_read_bits_idx,
  input  logic [1:0]                 io_meta_resp_coh_state [N_WAYS],
  input  logic                       io_tag_read_ready,
  output logic                       io_tag_read_valid,
  output logic [storepipe_pkg::IDX_BITS-1:0] io_tag_read_bits_idx,
  input  logic [42:0]                io_tag_resp [N_WAYS],

  // ---- 向 MissQueue 发 store 写预取请求 ----
  input  logic        io_miss_req_ready,
  output logic        io_miss_req_valid,
  output logic [4:0]  io_miss_req_bits_cmd,
  output logic [47:0] io_miss_req_bits_addr,
  output logic [49:0] io_miss_req_bits_vaddr,
  output logic [1:0]  io_miss_req_bits_req_coh_state,
  output logic        io_miss_req_bits_cancel
);
  import storepipe_pkg::*;

  // ===========================================================================
  //  S0 —— 发 meta / tag 组读
  // ===========================================================================
  wire s0_valid = io_lsu_req_valid;
  assign io_meta_read_valid    = s0_valid;
  assign io_meta_read_bits_idx = io_lsu_req_bits_vaddr[13:6];
  assign io_tag_read_valid     = s0_valid;
  assign io_tag_read_bits_idx  = io_lsu_req_bits_vaddr[13:6];
  // STA 请求 ready = meta/tag array 都可读。
  assign io_lsu_req_ready      = io_meta_read_ready & io_tag_read_ready;

  // s0 fire 锁存到 s1
  wire s0_fire = io_lsu_req_valid & io_lsu_req_ready;

  // ===========================================================================
  //  S1 —— tag 比对 + onAccess 权限判定 → hit/miss
  // ===========================================================================
  logic    s1_valid;
  s1_req_t s1_req;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) s1_valid <= 1'b0;
    else       s1_valid <= s0_fire;
  end
  always_ff @(posedge clock) begin
    if (s0_fire) begin
      s1_req.cmd       <= io_lsu_req_bits_cmd;
      s1_req.vaddr     <= io_lsu_req_bits_vaddr;
      s1_req.instrtype <= io_lsu_req_bits_instrtype;
    end
  end

  // 4 路并行 tag 比对: tag(低 36 位) == paddr[47:12] 且该路 coh 有效。
  logic [N_WAYS-1:0] s1_tag_match;
  genvar w;
  generate
    for (w = 0; w < N_WAYS; w++) begin : g_match
      assign s1_tag_match[w] =
          (io_tag_resp[w][TAG_BITS-1:0] == io_lsu_s1_paddr[47:12]) &
          (|io_meta_resp_coh_state[w]);
    end
  endgenerate
  wire s1_any_match = |s1_tag_match;

  // 命中路 coh 状态(独热 OR 选); 无命中 → Nothing(Fake Meta)。
  logic [1:0] s1_hit_coh;
  always_comb begin
    s1_hit_coh = 2'(COH_NOTHING);
    for (int i = 0; i < N_WAYS; i++)
      if (s1_tag_match[i]) s1_hit_coh = s1_hit_coh | io_meta_resp_coh_state[i];
  end

  // onAccess 权限判定(store 为写访问)。下面两个纯函数等价 ClientMetadata.onAccess
  // 在 store cmd 下的 (has_permission, new_hit_coh):
  //   store 需要独占(Trunk/Dirty); 当前 Trunk/Dirty 即有权限, 否则需升级。
  function automatic logic store_has_permission(input logic [1:0] coh);
    return (coh == 2'(COH_TRUNK)) || (coh == 2'(COH_DIRTY));
  endfunction
  function automatic logic [1:0] store_new_coh(input logic [1:0] coh);
    // 写访问后目标: Nothing/Branch → 需升 Trunk; Trunk → Trunk; Dirty → Dirty。
    return (coh == 2'(COH_DIRTY)) ? 2'(COH_DIRTY) : 2'(COH_TRUNK);
  endfunction

  wire       s1_has_perm    = store_has_permission(s1_hit_coh);
  wire [1:0] s1_new_hit_coh = store_new_coh(s1_hit_coh);
  // 命中 = 有权限 & coh 不需升级 & tag 命中。
  wire s1_hit = s1_has_perm & (s1_new_hit_coh == s1_hit_coh) & s1_any_match;

  // ===========================================================================
  //  S2 —— miss: 发 store 写预取 MissReq; 回 STA resp
  // ===========================================================================
  logic    s2_valid;
  s2_req_t s2_req;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) s2_valid <= 1'b0;
    else       s2_valid <= s1_valid & ~io_lsu_s1_kill;
  end
  always_ff @(posedge clock) begin
    if (s1_valid) begin
      s2_req.cmd         <= s1_req.cmd;
      s2_req.vaddr       <= s1_req.vaddr;
      s2_req.hit         <= s1_hit;
      s2_req.paddr       <= io_lsu_s1_paddr;
      s2_req.hit_coh     <= s1_hit_coh;
      s2_req.is_prefetch <= (s1_req.instrtype == PREFETCH_SOURCE);
    end
  end

  // 回 STA 响应: miss = ~hit。本配置 replay/tag_error 暂置 0(同 Scala)。
  assign io_lsu_resp_valid          = s2_valid;
  assign io_lsu_resp_bits_miss      = ~s2_req.hit;
  assign io_lsu_resp_bits_replay    = 1'b0;
  assign io_lsu_resp_bits_tag_error = 1'b0;

  // 发 store 写预取请求到 MissQueue:
  //   EN_STORE_PF_AT_ISSUE=1: 所有 miss store 都发; 否则仅「预取来源」的 miss store 发。
  wire s2_send_miss = EN_STORE_PF_AT_ISSUE ? (s2_valid & ~s2_req.hit)
                                           : (s2_valid & ~s2_req.hit & s2_req.is_prefetch);
  assign io_miss_req_valid          = s2_send_miss;
  assign io_miss_req_bits_cmd       = 5'h3;                 // M_PFW(写预取)
  assign io_miss_req_bits_addr      = {s2_req.paddr[47:6], 6'h0};
  assign io_miss_req_bits_vaddr     = s2_req.vaddr;
  assign io_miss_req_bits_req_coh_state = s2_req.hit_coh;
  assign io_miss_req_bits_cancel    = io_lsu_s2_kill;       // s2 AF/MMIO 取消

endmodule
