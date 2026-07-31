// =============================================================================
//  StorePipe —— DCache store 探测流水(可读重写, 对齐 canonical-derivative 官方 reference)
// -----------------------------------------------------------------------------
//  设计意图来源：XiangShan/src/main/scala/xiangshan/cache/dcache/storepipe/StorePipe.scala
//  官方 reference：G0-StorePipe-observable-v1(codex_0088 §3 批准的 canonical-derivative)
//  类型/参数包：rtl/memblock/storepipe_pkg.sv    学习文档：docs/memblock/StorePipe.md
//
//  ── 为什么有 derivative ─────────────────────────────────────────────────────
//  本顶层(KunmingHu V2R2, EnableStorePrefetchAtIssue=false)下, DCacheWrapper 把
//  StorePipe 的全部输出(resp/miss_req/meta_read/tag_read/replace/error)悬空,
//  只钉 miss_req.ready=false, 全芯片 firtool 跨层 DCE 把 golden StorePipe.sv 削成
//  5 行空壳(1 input/0 output/0 register)。codex_0088 §3 批准: 从同一冻结 G0
//  `SimTop.fir` 的 production pre-DCE StorePipe FIRRTL, 用锁定的 firtool-1.62.1 +
//  G0 flags(--lowering-options=explicitBitcast,disallowLocalVariables,...) STANDALONE
//  重 lower, 使原始完整 IO 成为顶层可观测端口, 得到 canonical-derivative StorePipe
//  (50 output leaves + 6 perf probes, 11 真实流水寄存器)。本可读核对齐该 derivative。
//
//  ── 可观测面(与 derivative 逐位比较)────────────────────────────────────────
//    36 output leaves(本核显式驱动, 真实源值) + 6 perf probes(见文件尾 XMR 语义)。
//  ── 14 UNSPECIFIED_BY_SOURCE(Chisel `io.miss_req.bits := DontCare` 未被覆写的字段
//     + `io.replace_access.bits := DontCare`)──────────────────────────────────
//    这些 leaf 的**源值**是 DontCare(未被 Chisel 赋任何确定值), firtool DCE 恰好把
//    它们常量传播成 0。按 codex_0088 §3 铁律: **不具体化为 0, 不 dont_verify**, 从
//    harness 比较面排除。本核把它们留作未驱动(`'x`), 忠实反映"源未指定"。
//    14 = miss_req{lqIdx_flag,lqIdx_value,full_overwrite,word_idx,amo_data,amo_mask,
//         amo_cmp,id,isBtoT,occupy_way,store_data,store_mask}(12)
//       + replace_access_bits{set,way}(2)。
//
//  ── 寄存器 = exactly 11, 无 shadow DFF, init-free(无 async reset)────────────
//    G0 flags(disallowLocalVariables)把 s0_fire/s1_tag_match_T_*/r_c_cat_T_*/_r_T/
//    _GEN_5/s1_hit_meta_coh_state 全 hoist 成模块级组合 wire——它们不是寄存器。
//    之前 StorePipe-redo 报的 24 shadow DFF 是**错误 bare-firtool flags** 的产物;
//    正确 pre-DCE 语义下不存在, 本核不加。derivative 的 11 reg 是 init-free
//    `always @(posedge clock)`(RegNext/RegEnable 无 reset), 本核照抄——若加 async
//    reset 会与 derivative 产生真实 reset-behaviour 失配。
//
//  ── 三级流水(与 Scala/derivative 一致)──────────────────────────────────────
//    s0  收 STA 请求 → 用 vaddr[13:6] 发 meta_read/tag_read(全 way_en=F)
//    s1  收 meta/tag resp → 4 路 tag 比对 + onAccess(growPermissions LUT) 权限判定
//    s2  双 RegNext(s1_valid, ~s1_kill) 门控; miss&is_prefetch 时发 M_PFW MissReq;
//        回 STA resp(miss = ~hit)。它不写数据(store 数据走 StoreQueue→Sbuffer)。
// =============================================================================
module xs_StorePipe_core #(
  parameter int N_WAYS   = storepipe_pkg::N_WAYS,
  parameter int TAG_BITS = storepipe_pkg::TAG_BITS,
  // 本顶层 EnableStorePrefetchAtIssue=false: 仅「预取来源的 miss store」发 MissReq。
  // derivative 是在 =false 下派生的, 故默认 0(对齐 production/derivative)。
  parameter bit EN_STORE_PF_AT_ISSUE = 1'b0
)(
  input  logic        clock,
  input  logic        reset,   // 端口保留以匹配 derivative; 11 reg init-free 不用它。

  // ---- s1/s2 侧带信息(io.lsu 的 Output 侧, 对本模块是 input)----
  input  logic [47:0] io_lsu_s1_paddr,   // s1 物理地址(命中判定)
  input  logic        io_lsu_s1_kill,    // s1 kill(TLB miss/异常)
  input  logic        io_lsu_s2_kill,    // s2 kill(AF/MMIO)
  input  logic [49:0] io_lsu_s2_pc,      // 调试 pc(透传到 miss_req.pc)

  // ---- STA 请求(io.lsu.req, Decoupled)----
  output logic        io_lsu_req_ready,
  input  logic        io_lsu_req_valid,
  input  logic [4:0]  io_lsu_req_bits_cmd,
  input  logic [49:0] io_lsu_req_bits_vaddr,
  input  logic [3:0]  io_lsu_req_bits_instrtype,

  // ---- STA 响应(io.lsu.resp, Flipped Decoupled)----
  input  logic        io_lsu_resp_ready,   // 未使用(resp.valid 不依赖它); 端口对齐
  output logic        io_lsu_resp_valid,
  output logic        io_lsu_resp_bits_miss,
  output logic        io_lsu_resp_bits_replay,
  output logic        io_lsu_resp_bits_tag_error,

  // ---- meta 组读 ----
  input  logic        io_meta_read_ready,
  output logic        io_meta_read_valid,
  output logic [7:0]  io_meta_read_bits_idx,
  output logic [3:0]  io_meta_read_bits_way_en,
  input  logic [1:0]  io_meta_resp_0_coh_state,
  input  logic [1:0]  io_meta_resp_1_coh_state,
  input  logic [1:0]  io_meta_resp_2_coh_state,
  input  logic [1:0]  io_meta_resp_3_coh_state,

  // ---- tag 组读 ----
  input  logic        io_tag_read_ready,
  output logic        io_tag_read_valid,
  output logic [7:0]  io_tag_read_bits_idx,
  output logic [3:0]  io_tag_read_bits_way_en,
  input  logic [42:0] io_tag_resp_0,
  input  logic [42:0] io_tag_resp_1,
  input  logic [42:0] io_tag_resp_2,
  input  logic [42:0] io_tag_resp_3,

  // ---- 向 MissQueue 发 store 写预取请求(io.miss_req, Decoupled MissReq)----
  input  logic        io_miss_req_ready,
  output logic        io_miss_req_valid,
  // -- 36 观测面内的 miss_req live/const 字段(真实源值)--
  output logic [3:0]  io_miss_req_bits_source,        // DCACHE_PREFETCH_SOURCE = 3
  output logic [2:0]  io_miss_req_bits_pf_source,     // L1_HW_PREFETCH_STORE = 4
  output logic [4:0]  io_miss_req_bits_cmd,           // M_PFW = 3
  output logic [47:0] io_miss_req_bits_addr,          // get_block_addr(s2_paddr)
  output logic [49:0] io_miss_req_bits_vaddr,         // s2_req.vaddr
  output logic [49:0] io_miss_req_bits_pc,            // io.lsu.s2_pc
  output logic [1:0]  io_miss_req_bits_req_coh_state, // s2_hit_coh
  output logic        io_miss_req_bits_cancel,        // io.lsu.s2_kill
  // -- 14 UNSPECIFIED_BY_SOURCE: Chisel `io.miss_req.bits := DontCare` 未覆写字段。
  //    源值未指定 → 留未驱动('x), 不置 0, 不 dont_verify, harness 排除。--
  output logic         io_miss_req_bits_lqIdx_flag,
  output logic [6:0]   io_miss_req_bits_lqIdx_value,
  output logic         io_miss_req_bits_full_overwrite,
  output logic [2:0]   io_miss_req_bits_word_idx,
  output logic [127:0] io_miss_req_bits_amo_data,
  output logic [15:0]  io_miss_req_bits_amo_mask,
  output logic [127:0] io_miss_req_bits_amo_cmp,
  output logic [5:0]   io_miss_req_bits_id,
  output logic         io_miss_req_bits_isBtoT,
  output logic [3:0]   io_miss_req_bits_occupy_way,
  output logic [511:0] io_miss_req_bits_store_data,
  output logic [63:0]  io_miss_req_bits_store_mask,

  // ---- replace_access(io.replace_access, ValidIO)----
  output logic        io_replace_access_valid,        // false.B(真实 const, 观测面内)
  // 14 UNSPECIFIED 内的 2 个: replace_access.bits := DontCare
  output logic [7:0]  io_replace_access_bits_set,
  output logic [1:0]  io_replace_access_bits_way,

  // ---- replace_way(io.replace_way, ReplacementWayReqIO)----
  output logic        io_replace_way_set_valid,       // false.B(观测面内)
  output logic [7:0]  io_replace_way_set_bits,        // get_idx(s1_req.vaddr)
  output logic [1:0]  io_replace_way_dmWay,           // get_direct_map_way(s1_req.vaddr)
  input  logic [1:0]  io_replace_way_way,             // 未使用(no more choose replace way)

  // ---- error(io.error, ValidIO L1CacheErrorInfo)----
  //  Chisel: io.error := 0.U.asTypeOf(...) → 显式全 0(真实源值, 观测面内 12 leaf)。
  output logic        io_error_valid,
  output logic        io_error_bits_source_tag,
  output logic        io_error_bits_source_data,
  output logic        io_error_bits_source_l2,
  output logic        io_error_bits_opType_fetch,
  output logic        io_error_bits_opType_load,
  output logic        io_error_bits_opType_store,
  output logic        io_error_bits_opType_probe,
  output logic        io_error_bits_opType_release,
  output logic        io_error_bits_opType_atom,
  output logic [47:0] io_error_bits_paddr,
  output logic        io_error_bits_report_to_beu
);
  import storepipe_pkg::*;

  // ===========================================================================
  //  S0 —— 发 meta / tag 组读(io.lsu.req.valid 直接驱 valid; ready = 两 array 都 ready)
  // ===========================================================================
  wire io_lsu_req_ready_0 = io_meta_read_ready & io_tag_read_ready;
  wire s0_fire = io_lsu_req_ready_0 & io_lsu_req_valid;

  assign io_lsu_req_ready         = io_lsu_req_ready_0;
  assign io_meta_read_valid       = io_lsu_req_valid;            // io.meta_read.valid := s0_valid
  assign io_meta_read_bits_idx    = io_lsu_req_bits_vaddr[13:6]; // get_idx
  assign io_meta_read_bits_way_en = 4'hF;                        // ~0.U(nWays.W)
  assign io_tag_read_valid        = io_lsu_req_valid;
  assign io_tag_read_bits_idx     = io_lsu_req_bits_vaddr[13:6];
  assign io_tag_read_bits_way_en  = 4'hF;

  // ===========================================================================
  //  S1 寄存(RegNext(s0_fire) / RegEnable(s0_req, s0_fire)) —— 4 个寄存器
  // ===========================================================================
  logic        s1_valid;
  logic [4:0]  s1_req_cmd;
  logic [49:0] s1_req_vaddr;
  logic [3:0]  s1_req_instrtype;

  // ---- s1 tag 比对: tag(低 36 位) == paddr[47:12] 且该 way coh 有效(组合)----
  wire s1_tag_match_0 = (io_tag_resp_0[TAG_BITS-1:0] == io_lsu_s1_paddr[47:12]) & (|io_meta_resp_0_coh_state);
  wire s1_tag_match_1 = (io_tag_resp_1[TAG_BITS-1:0] == io_lsu_s1_paddr[47:12]) & (|io_meta_resp_1_coh_state);
  wire s1_tag_match_2 = (io_tag_resp_2[TAG_BITS-1:0] == io_lsu_s1_paddr[47:12]) & (|io_meta_resp_2_coh_state);
  wire s1_tag_match_3 = (io_tag_resp_3[TAG_BITS-1:0] == io_lsu_s1_paddr[47:12]) & (|io_meta_resp_3_coh_state);
  wire [3:0] s1_tag_match = {s1_tag_match_3, s1_tag_match_2, s1_tag_match_1, s1_tag_match_0};
  wire       s1_any_match = |s1_tag_match;

  // 命中路 coh(Mux1H; 无命中 → onReset=Nothing=0)。
  wire [1:0] s1_hit_meta_coh_state = s1_any_match
      ? ((s1_tag_match_0 ? io_meta_resp_0_coh_state : 2'h0)
       | (s1_tag_match_1 ? io_meta_resp_1_coh_state : 2'h0)
       | (s1_tag_match_2 ? io_meta_resp_2_coh_state : 2'h0)
       | (s1_tag_match_3 ? io_meta_resp_3_coh_state : 2'h0))
      : 2'h0;

  // ── onAccess(store) 权限判定, 忠实复刻 golden Metadata.scala growPermissions LUT ──
  //  ClientMetadata.onAccess(cmd): growStarter(cmd) 编码写类(2 位 cat), 拼 hit_coh 成
  //  4 位索引 r_T, 查 _GEN_5(growPermissions.next) 得目标 coh; s1_hit = 该 cmd 命中该
  //  coh & 目标 coh == 当前 coh(无需升级) & tag 命中。下面逐位复刻 derivative 常量项
  //  (与 Consts.scala isWrite 掩码一致)。
  wire c29 = (s1_req_cmd == 5'h1);
  wire c30 = (s1_req_cmd == 5'h11);
  wire c32 = (s1_req_cmd == 5'h7);
  wire c34 = (s1_req_cmd == 5'h4);
  wire c35 = (s1_req_cmd == 5'h9);
  wire c36 = (s1_req_cmd == 5'hA);
  wire c37 = (s1_req_cmd == 5'hB);
  wire c41 = (s1_req_cmd == 5'h8);
  wire c42 = (s1_req_cmd == 5'hC);
  wire c43 = (s1_req_cmd == 5'hD);
  wire c44 = (s1_req_cmd == 5'hE);
  wire c45 = (s1_req_cmd == 5'hF);
  wire c51 = (s1_req_cmd == 5'h1A);
  wire c52 = (s1_req_cmd == 5'h1B);
  wire c54 = (s1_req_cmd == 5'h18);
  // growStarter 的 2 位分类(cat): 高位与低位共用一组"写类" cmd, 低位额外含 M_XRD 家族。
  wire r_cat_hi = c29 | c30 | c32 | c34 | c35 | c36 | c37 | c41 | c42 | c43
                | c44 | c45 | c51 | c52 | c54;
  wire r_cat_lo = r_cat_hi | (s1_req_cmd == 5'h3) | (s1_req_cmd == 5'h6);
  wire [3:0] r_T = {r_cat_hi, r_cat_lo, s1_hit_meta_coh_state};
  // _GEN_5 = growPermissions.next LUT(16 项 × 2 位), 索引 r_T:
  wire [1:0] r_T_27 = {1'h0, r_T == 4'hC};
  logic [1:0] gen5 [16];
  assign gen5[0]  = 2'h0; assign gen5[1]  = 2'h1; assign gen5[2]  = 2'h2; assign gen5[3]  = 2'h3;
  assign gen5[4]  = 2'h1; assign gen5[5]  = 2'h2; assign gen5[6]  = 2'h2; assign gen5[7]  = 2'h3;
  assign gen5[8]  = r_T_27; assign gen5[9]  = r_T_27; assign gen5[10] = r_T_27; assign gen5[11] = r_T_27;
  assign gen5[12] = r_T_27; assign gen5[13] = 2'h2; assign gen5[14] = 2'h3; assign gen5[15] = 2'h3;
  wire s1_hit =
      (r_T == 4'h3 | r_T == 4'h2 | r_T == 4'h1 | r_T == 4'h7 | r_T == 4'h6
       | (&r_T) | r_T == 4'hE)
    & (gen5[r_T] == s1_hit_meta_coh_state)
    & s1_any_match;

  // ===========================================================================
  //  S2 寄存 —— 双 RegNext: s2_valid = RegNext(s1_valid) & RegNext(~s1_kill)
  //  + RegEnable(s1_*, s1_valid) 一组。共 7 个寄存器。
  // ===========================================================================
  logic        s2_valid_REG;    // RegNext(s1_valid)
  logic        s2_valid_REG_1;  // RegNext(~io.lsu.s1_kill)
  wire         s2_valid = s2_valid_REG & s2_valid_REG_1;
  logic [49:0] s2_req_vaddr;     // RegEnable(s1_req.vaddr, s1_valid)
  logic        s2_hit;           // RegEnable(s1_hit, s1_valid)
  logic [47:0] s2_paddr;         // RegEnable(s1_paddr, s1_valid)
  logic [1:0]  s2_hit_coh_state; // RegEnable(s1_hit_coh, s1_valid)
  logic        s2_is_prefetch;   // RegEnable(instrtype==PREFETCH, s1_valid)

  // ── 11 真实流水寄存器: init-free `always @(posedge clock)`(无 async reset), 与
  //    derivative 逐字一致。RegNext ⇒ 每拍更新; RegEnable ⇒ 使能门控更新。──
  always @(posedge clock) begin
    // s1 组(RegNext(s0_fire) + RegEnable(s0_req, s0_fire))
    s1_valid <= s0_fire;
    if (s0_fire) begin
      s1_req_cmd       <= io_lsu_req_bits_cmd;
      s1_req_vaddr     <= io_lsu_req_bits_vaddr;
      s1_req_instrtype <= io_lsu_req_bits_instrtype;
    end
    // s2 门控组(两独立 RegNext)
    s2_valid_REG   <= s1_valid;
    s2_valid_REG_1 <= ~io_lsu_s1_kill;
    // s2 数据组(RegEnable(..., s1_valid))
    if (s1_valid) begin
      s2_req_vaddr     <= s1_req_vaddr;
      s2_hit           <= s1_hit;
      s2_paddr         <= io_lsu_s1_paddr;
      s2_hit_coh_state <= s1_hit_meta_coh_state;
      s2_is_prefetch   <= (s1_req_instrtype == PREFETCH_SOURCE);
    end
  end

  // ===========================================================================
  //  S2 输出 —— STA resp / MissReq / replace_way / error / replace_access
  // ===========================================================================
  // STA 响应(miss = ~hit; replay/tag_error TODO=0)
  assign io_lsu_resp_valid          = s2_valid;
  assign io_lsu_resp_bits_miss      = ~s2_hit;
  assign io_lsu_resp_bits_replay    = 1'h0;
  assign io_lsu_resp_bits_tag_error = 1'h0;

  // MissReq valid: EN=1 所有 miss store; EN=0(production/derivative) 仅预取来源 miss。
  wire io_miss_req_valid_0 = EN_STORE_PF_AT_ISSUE ? (s2_valid & ~s2_hit)
                                                  : (s2_valid & ~s2_hit & s2_is_prefetch);
  assign io_miss_req_valid          = io_miss_req_valid_0;
  // MissReq 已被 Chisel 显式覆写的字段(真实源值; 观测面内)
  assign io_miss_req_bits_source        = 4'h3;                    // DCACHE_PREFETCH_SOURCE
  assign io_miss_req_bits_pf_source     = 3'h4;                    // L1_HW_PREFETCH_STORE
  assign io_miss_req_bits_cmd           = 5'h3;                    // M_PFW
  assign io_miss_req_bits_addr          = {s2_paddr[47:6], 6'h0};  // get_block_addr
  assign io_miss_req_bits_vaddr         = s2_req_vaddr;
  assign io_miss_req_bits_pc            = io_lsu_s2_pc;
  assign io_miss_req_bits_req_coh_state = s2_hit_coh_state;
  assign io_miss_req_bits_cancel        = io_lsu_s2_kill;

  // ── 14 UNSPECIFIED_BY_SOURCE: `io.miss_req.bits := DontCare` 未覆写 12 字段 +
  //    `io.replace_access.bits := DontCare` 2 字段。源值未指定 → 留未驱动('x),
  //    不置 0, 不 dont_verify。harness 从比较面排除。 ──
  assign io_miss_req_bits_lqIdx_flag     = 1'bx;
  assign io_miss_req_bits_lqIdx_value    = 7'bx;
  assign io_miss_req_bits_full_overwrite = 1'bx;
  assign io_miss_req_bits_word_idx       = 3'bx;
  assign io_miss_req_bits_amo_data       = 128'bx;
  assign io_miss_req_bits_amo_mask       = 16'bx;
  assign io_miss_req_bits_amo_cmp        = 128'bx;
  assign io_miss_req_bits_id             = 6'bx;
  assign io_miss_req_bits_isBtoT         = 1'bx;
  assign io_miss_req_bits_occupy_way     = 4'bx;
  assign io_miss_req_bits_store_data     = 512'bx;
  assign io_miss_req_bits_store_mask     = 64'bx;
  assign io_replace_access_bits_set      = 8'bx;
  assign io_replace_access_bits_way      = 2'bx;

  // replace_access.valid := false.B(真实 const 0, 观测面内)
  assign io_replace_access_valid    = 1'h0;

  // replace_way: set.valid := false.B; set.bits := get_idx(s1_req.vaddr);
  //              dmWay := get_direct_map_way(s1_req.vaddr) = s1_req.vaddr[15:14]
  assign io_replace_way_set_valid   = 1'h0;
  assign io_replace_way_set_bits    = s1_req_vaddr[13:6];
  assign io_replace_way_dmWay       = s1_req_vaddr[15:14];

  // error := 0.U.asTypeOf(...) → 显式全 0(真实源值; 观测面内 12 leaf)
  assign io_error_valid               = 1'h0;
  assign io_error_bits_source_tag     = 1'h0;
  assign io_error_bits_source_data    = 1'h0;
  assign io_error_bits_source_l2      = 1'h0;
  assign io_error_bits_opType_fetch   = 1'h0;
  assign io_error_bits_opType_load    = 1'h0;
  assign io_error_bits_opType_store   = 1'h0;
  assign io_error_bits_opType_probe   = 1'h0;
  assign io_error_bits_opType_release = 1'h0;
  assign io_error_bits_opType_atom    = 1'h0;
  assign io_error_bits_paddr          = 48'h0;
  assign io_error_bits_report_to_beu  = 1'h0;

  // ===========================================================================
  //  6 perf probes(derivative XMR bind 宏 perfCnt_bore*)—— 本核暴露同名内部 wire,
  //  harness 可经层次探针比对(与 derivative _GEN/_GEN_0.._GEN_4 逐拍一致)。
  //  它们对 datapath 等价无关(perf-only), 若不比对亦无 bearing。
  // ===========================================================================
  wire perfCnt_s0_valid_not_ready           = io_lsu_req_valid & ~io_lsu_req_ready_0;                   // _GEN
  wire perfCnt_store_fire                    = s2_valid & ~io_lsu_s2_kill;                              // _GEN_0
  wire perfCnt_sta_hit                       = s2_valid & s2_hit & ~io_lsu_s2_kill;                     // _GEN_1
  wire perfCnt_sta_miss                      = s2_valid & ~s2_hit & ~io_lsu_s2_kill;                    // _GEN_2
  wire perfCnt_store_miss_prefetch_fire      = io_miss_req_ready & io_miss_req_valid_0 & ~io_lsu_s2_kill;   // _GEN_3
  wire perfCnt_store_miss_prefetch_not_fire  = io_miss_req_valid_0 & ~io_miss_req_ready & ~io_lsu_s2_kill;  // _GEN_4

endmodule
