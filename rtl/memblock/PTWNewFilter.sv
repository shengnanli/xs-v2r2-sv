// =============================================================================
// xs_PTWNewFilter_core —— L1-TLB → L2-TLB(PTW) 请求过滤/合并顶层（可读重写）
//
// 对应 Chisel: src/main/scala/xiangshan/cache/mmu/Repeater.scala class PTWNewFilter
//
// 角色：dtlb 侧有 8 个 TLB miss 请求端口（load 4 个 [0..3] / store 2 个 [4..5] /
//   prefetch 2 个 [6..7]），按用途分成 3 个过滤组（load/store/prefetch），每组是一个
//   PTWFilterEntry（去重/合并同 vpn 的 miss + 缓冲），三组的 PTW 请求经 RRArbiterInit_10
//   轮转仲裁汇聚到唯一的 io_ptw_req_0 发往共享 L2 TLB。PTW 回来的 resp 广播给三组。
//
// 本核 = 顶层 glue（三组 PTWFilterEntry / 仲裁器 / DelayN_1 在外层 wrapper 里例化 golden，
//   两侧同源 elaborate，纯逻辑非黑盒）。本核实现：
//   1. ptwResp_* 整包寄存：PTW resp 到来时锁存（io_ptw_resp_valid 使能），供三组 + 顶层
//      resp 输出复用（省去每组各存一份）；
//   2. *_ptw_resp_valid_last_REG：三份 RegNext(io_ptw_resp_valid)（异步复位），各喂一组
//      过滤器的 ptw_resp_valid（resp 与数据错开 1 拍，数据用上面锁存版）；
//   3. io_hint_*_REG：从 load 组的 hint 接口寄存一拍后输出（供 L1 DCache miss hint）；
//   4. resp 路由：三组 refill 相或 → io_tlb_resp_valid / vector / rob_head_miss。
//
// 寄存器命名与 golden 逐一对齐，便于 FM 1:1 匹配。
// =============================================================================
module xs_PTWNewFilter_core (
  input  logic        clock,
  input  logic        reset,

  // ---- flush（外层 DelayN_1 产生）----
  input  logic        io_flush,

  // ---- PTW 回填（io_ptw_resp）----
  input  logic        io_ptw_resp_valid,
  input  logic [1:0]  io_ptw_resp_bits_s2xlate,
  input  logic [34:0] io_ptw_resp_bits_s1_entry_tag,
  input  logic [15:0] io_ptw_resp_bits_s1_entry_asid,
  input  logic [13:0] io_ptw_resp_bits_s1_entry_vmid,
  input  logic        io_ptw_resp_bits_s1_entry_n,
  input  logic [1:0]  io_ptw_resp_bits_s1_entry_pbmt,
  input  logic        io_ptw_resp_bits_s1_entry_perm_d,
  input  logic        io_ptw_resp_bits_s1_entry_perm_a,
  input  logic        io_ptw_resp_bits_s1_entry_perm_g,
  input  logic        io_ptw_resp_bits_s1_entry_perm_u,
  input  logic        io_ptw_resp_bits_s1_entry_perm_x,
  input  logic        io_ptw_resp_bits_s1_entry_perm_w,
  input  logic        io_ptw_resp_bits_s1_entry_perm_r,
  input  logic [1:0]  io_ptw_resp_bits_s1_entry_level,
  input  logic        io_ptw_resp_bits_s1_entry_v,
  input  logic [40:0] io_ptw_resp_bits_s1_entry_ppn,
  input  logic [2:0]  io_ptw_resp_bits_s1_addr_low,
  input  logic [2:0]  io_ptw_resp_bits_s1_ppn_low_0,
  input  logic [2:0]  io_ptw_resp_bits_s1_ppn_low_1,
  input  logic [2:0]  io_ptw_resp_bits_s1_ppn_low_2,
  input  logic [2:0]  io_ptw_resp_bits_s1_ppn_low_3,
  input  logic [2:0]  io_ptw_resp_bits_s1_ppn_low_4,
  input  logic [2:0]  io_ptw_resp_bits_s1_ppn_low_5,
  input  logic [2:0]  io_ptw_resp_bits_s1_ppn_low_6,
  input  logic [2:0]  io_ptw_resp_bits_s1_ppn_low_7,
  input  logic        io_ptw_resp_bits_s1_valididx_0,
  input  logic        io_ptw_resp_bits_s1_valididx_1,
  input  logic        io_ptw_resp_bits_s1_valididx_2,
  input  logic        io_ptw_resp_bits_s1_valididx_3,
  input  logic        io_ptw_resp_bits_s1_valididx_4,
  input  logic        io_ptw_resp_bits_s1_valididx_5,
  input  logic        io_ptw_resp_bits_s1_valididx_6,
  input  logic        io_ptw_resp_bits_s1_valididx_7,
  input  logic        io_ptw_resp_bits_s1_pteidx_0,
  input  logic        io_ptw_resp_bits_s1_pteidx_1,
  input  logic        io_ptw_resp_bits_s1_pteidx_2,
  input  logic        io_ptw_resp_bits_s1_pteidx_3,
  input  logic        io_ptw_resp_bits_s1_pteidx_4,
  input  logic        io_ptw_resp_bits_s1_pteidx_5,
  input  logic        io_ptw_resp_bits_s1_pteidx_6,
  input  logic        io_ptw_resp_bits_s1_pteidx_7,
  input  logic        io_ptw_resp_bits_s1_pf,
  input  logic        io_ptw_resp_bits_s1_af,
  input  logic [37:0] io_ptw_resp_bits_s2_entry_tag,
  input  logic [13:0] io_ptw_resp_bits_s2_entry_vmid,
  input  logic        io_ptw_resp_bits_s2_entry_n,
  input  logic [1:0]  io_ptw_resp_bits_s2_entry_pbmt,
  input  logic [37:0] io_ptw_resp_bits_s2_entry_ppn,
  input  logic        io_ptw_resp_bits_s2_entry_perm_d,
  input  logic        io_ptw_resp_bits_s2_entry_perm_a,
  input  logic        io_ptw_resp_bits_s2_entry_perm_g,
  input  logic        io_ptw_resp_bits_s2_entry_perm_u,
  input  logic        io_ptw_resp_bits_s2_entry_perm_x,
  input  logic        io_ptw_resp_bits_s2_entry_perm_w,
  input  logic        io_ptw_resp_bits_s2_entry_perm_r,
  input  logic [1:0]  io_ptw_resp_bits_s2_entry_level,
  input  logic        io_ptw_resp_bits_s2_gpf,
  input  logic        io_ptw_resp_bits_s2_gaf,

  // ---- 三组过滤器的 ptw_resp_valid（延迟 1 拍版, 核产生）----
  output logic        o_load_ptw_resp_valid_last,
  output logic        o_store_ptw_resp_valid_last,
  output logic        o_prefetch_ptw_resp_valid_last,

  // ---- 锁存的 ptwResp（核 → 三组过滤器共用的数据）----
  output logic [1:0]  o_ptwResp_s2xlate,
  output logic [34:0] o_ptwResp_s1_entry_tag,
  output logic [15:0] o_ptwResp_s1_entry_asid,
  output logic [13:0] o_ptwResp_s1_entry_vmid,
  output logic        o_ptwResp_s1_entry_n,
  output logic        o_ptwResp_s1_entry_perm_g,
  output logic [1:0]  o_ptwResp_s1_entry_level,
  output logic [2:0]  o_ptwResp_s1_addr_low,
  output logic        o_ptwResp_s1_valididx_0,
  output logic        o_ptwResp_s1_valididx_1,
  output logic        o_ptwResp_s1_valididx_2,
  output logic        o_ptwResp_s1_valididx_3,
  output logic        o_ptwResp_s1_valididx_4,
  output logic        o_ptwResp_s1_valididx_5,
  output logic        o_ptwResp_s1_valididx_6,
  output logic        o_ptwResp_s1_valididx_7,
  output logic [37:0] o_ptwResp_s2_entry_tag,
  output logic [13:0] o_ptwResp_s2_entry_vmid,
  output logic        o_ptwResp_s2_entry_n,
  output logic [1:0]  o_ptwResp_s2_entry_level,

  // ---- 三组过滤器 refill（→ resp 路由）----
  input  logic        i_load_refill,
  input  logic        i_store_refill,
  input  logic        i_prefetch_refill,

  // ---- 三组过滤器 rob_head_miss_in_tlb ----
  input  logic        i_load_rob_head_miss,
  input  logic        i_store_rob_head_miss,
  input  logic        i_prefetch_rob_head_miss,

  // ---- load 组的 hint 接口（核寄存一拍后输出）----
  input  logic [3:0]  i_hint_req_0_id,
  input  logic        i_hint_req_0_full,
  input  logic [3:0]  i_hint_req_1_id,
  input  logic        i_hint_req_1_full,
  input  logic [3:0]  i_hint_req_2_id,
  input  logic        i_hint_req_2_full,
  input  logic        i_hint_resp_valid,
  input  logic [3:0]  i_hint_resp_bits_id,
  input  logic        i_hint_resp_bits_replay_all,

  // ---- tlb resp 输出（顶层）----
  output logic        io_tlb_resp_valid,
  output logic [1:0]  io_tlb_resp_bits_data_s2xlate,
  output logic [34:0] io_tlb_resp_bits_data_s1_entry_tag,
  output logic [15:0] io_tlb_resp_bits_data_s1_entry_asid,
  output logic [13:0] io_tlb_resp_bits_data_s1_entry_vmid,
  output logic        io_tlb_resp_bits_data_s1_entry_n,
  output logic [1:0]  io_tlb_resp_bits_data_s1_entry_pbmt,
  output logic        io_tlb_resp_bits_data_s1_entry_perm_d,
  output logic        io_tlb_resp_bits_data_s1_entry_perm_a,
  output logic        io_tlb_resp_bits_data_s1_entry_perm_g,
  output logic        io_tlb_resp_bits_data_s1_entry_perm_u,
  output logic        io_tlb_resp_bits_data_s1_entry_perm_x,
  output logic        io_tlb_resp_bits_data_s1_entry_perm_w,
  output logic        io_tlb_resp_bits_data_s1_entry_perm_r,
  output logic [1:0]  io_tlb_resp_bits_data_s1_entry_level,
  output logic        io_tlb_resp_bits_data_s1_entry_v,
  output logic [40:0] io_tlb_resp_bits_data_s1_entry_ppn,
  output logic [2:0]  io_tlb_resp_bits_data_s1_addr_low,
  output logic [2:0]  io_tlb_resp_bits_data_s1_ppn_low_0,
  output logic [2:0]  io_tlb_resp_bits_data_s1_ppn_low_1,
  output logic [2:0]  io_tlb_resp_bits_data_s1_ppn_low_2,
  output logic [2:0]  io_tlb_resp_bits_data_s1_ppn_low_3,
  output logic [2:0]  io_tlb_resp_bits_data_s1_ppn_low_4,
  output logic [2:0]  io_tlb_resp_bits_data_s1_ppn_low_5,
  output logic [2:0]  io_tlb_resp_bits_data_s1_ppn_low_6,
  output logic [2:0]  io_tlb_resp_bits_data_s1_ppn_low_7,
  output logic        io_tlb_resp_bits_data_s1_valididx_0,
  output logic        io_tlb_resp_bits_data_s1_valididx_1,
  output logic        io_tlb_resp_bits_data_s1_valididx_2,
  output logic        io_tlb_resp_bits_data_s1_valididx_3,
  output logic        io_tlb_resp_bits_data_s1_valididx_4,
  output logic        io_tlb_resp_bits_data_s1_valididx_5,
  output logic        io_tlb_resp_bits_data_s1_valididx_6,
  output logic        io_tlb_resp_bits_data_s1_valididx_7,
  output logic        io_tlb_resp_bits_data_s1_pteidx_0,
  output logic        io_tlb_resp_bits_data_s1_pteidx_1,
  output logic        io_tlb_resp_bits_data_s1_pteidx_2,
  output logic        io_tlb_resp_bits_data_s1_pteidx_3,
  output logic        io_tlb_resp_bits_data_s1_pteidx_4,
  output logic        io_tlb_resp_bits_data_s1_pteidx_5,
  output logic        io_tlb_resp_bits_data_s1_pteidx_6,
  output logic        io_tlb_resp_bits_data_s1_pteidx_7,
  output logic        io_tlb_resp_bits_data_s1_pf,
  output logic        io_tlb_resp_bits_data_s1_af,
  output logic [37:0] io_tlb_resp_bits_data_s2_entry_tag,
  output logic [13:0] io_tlb_resp_bits_data_s2_entry_vmid,
  output logic        io_tlb_resp_bits_data_s2_entry_n,
  output logic [1:0]  io_tlb_resp_bits_data_s2_entry_pbmt,
  output logic [37:0] io_tlb_resp_bits_data_s2_entry_ppn,
  output logic        io_tlb_resp_bits_data_s2_entry_perm_d,
  output logic        io_tlb_resp_bits_data_s2_entry_perm_a,
  output logic        io_tlb_resp_bits_data_s2_entry_perm_g,
  output logic        io_tlb_resp_bits_data_s2_entry_perm_u,
  output logic        io_tlb_resp_bits_data_s2_entry_perm_x,
  output logic        io_tlb_resp_bits_data_s2_entry_perm_w,
  output logic        io_tlb_resp_bits_data_s2_entry_perm_r,
  output logic [1:0]  io_tlb_resp_bits_data_s2_entry_level,
  output logic        io_tlb_resp_bits_data_s2_gpf,
  output logic        io_tlb_resp_bits_data_s2_gaf,
  output logic        io_tlb_resp_bits_vector_0,
  output logic        io_tlb_resp_bits_vector_4,
  output logic        io_tlb_resp_bits_vector_6,

  // ---- hint 输出（顶层）----
  output logic [3:0]  io_hint_req_0_id,
  output logic        io_hint_req_0_full,
  output logic [3:0]  io_hint_req_1_id,
  output logic        io_hint_req_1_full,
  output logic [3:0]  io_hint_req_2_id,
  output logic        io_hint_req_2_full,
  output logic        io_hint_resp_valid,
  output logic [3:0]  io_hint_resp_bits_id,
  output logic        io_hint_resp_bits_replay_all,

  // ---- rob head miss 输出（顶层）----
  output logic        io_rob_head_miss_in_tlb
);

  // ---------------- ptwResp 整包寄存 ----------------
  logic [1:0]  ptwResp_s2xlate;
  logic [34:0] ptwResp_s1_entry_tag;
  logic [15:0] ptwResp_s1_entry_asid;
  logic [13:0] ptwResp_s1_entry_vmid;
  logic        ptwResp_s1_entry_n;
  logic [1:0]  ptwResp_s1_entry_pbmt;
  logic        ptwResp_s1_entry_perm_d, ptwResp_s1_entry_perm_a, ptwResp_s1_entry_perm_g;
  logic        ptwResp_s1_entry_perm_u, ptwResp_s1_entry_perm_x, ptwResp_s1_entry_perm_w, ptwResp_s1_entry_perm_r;
  logic [1:0]  ptwResp_s1_entry_level;
  logic        ptwResp_s1_entry_v;
  logic [40:0] ptwResp_s1_entry_ppn;
  logic [2:0]  ptwResp_s1_addr_low;
  logic [2:0]  ptwResp_s1_ppn_low_0, ptwResp_s1_ppn_low_1, ptwResp_s1_ppn_low_2, ptwResp_s1_ppn_low_3;
  logic [2:0]  ptwResp_s1_ppn_low_4, ptwResp_s1_ppn_low_5, ptwResp_s1_ppn_low_6, ptwResp_s1_ppn_low_7;
  logic        ptwResp_s1_valididx_0, ptwResp_s1_valididx_1, ptwResp_s1_valididx_2, ptwResp_s1_valididx_3;
  logic        ptwResp_s1_valididx_4, ptwResp_s1_valididx_5, ptwResp_s1_valididx_6, ptwResp_s1_valididx_7;
  logic        ptwResp_s1_pteidx_0, ptwResp_s1_pteidx_1, ptwResp_s1_pteidx_2, ptwResp_s1_pteidx_3;
  logic        ptwResp_s1_pteidx_4, ptwResp_s1_pteidx_5, ptwResp_s1_pteidx_6, ptwResp_s1_pteidx_7;
  logic        ptwResp_s1_pf, ptwResp_s1_af;
  logic [37:0] ptwResp_s2_entry_tag;
  logic [13:0] ptwResp_s2_entry_vmid;
  logic        ptwResp_s2_entry_n;
  logic [1:0]  ptwResp_s2_entry_pbmt;
  logic [37:0] ptwResp_s2_entry_ppn;
  logic        ptwResp_s2_entry_perm_d, ptwResp_s2_entry_perm_a, ptwResp_s2_entry_perm_g;
  logic        ptwResp_s2_entry_perm_u, ptwResp_s2_entry_perm_x, ptwResp_s2_entry_perm_w, ptwResp_s2_entry_perm_r;
  logic [1:0]  ptwResp_s2_entry_level;
  logic        ptwResp_s2_gpf, ptwResp_s2_gaf;

  // ---------------- *_last_REG（3 份 RegNext(io_ptw_resp_valid)，异步复位）----------------
  logic load_filter_0_ptw_resp_valid_last_REG;
  logic store_filter_0_ptw_resp_valid_last_REG;
  logic prefetch_filter_0_ptw_resp_valid_last_REG;

  // ---------------- hint 寄存 bank（从 load 组）----------------
  logic [3:0] io_hint_req_0_REG_id;
  logic       io_hint_req_0_REG_full;
  logic [3:0] io_hint_req_1_REG_id;
  logic       io_hint_req_1_REG_full;
  logic [3:0] io_hint_req_2_REG_id;
  logic       io_hint_req_2_REG_full;
  logic       io_hint_resp_valid_REG;
  logic [3:0] io_hint_resp_bits_r_id;
  logic       io_hint_resp_bits_r_replay_all;

  // ---------------- 时序：ptwResp 整包 + hint bank（无复位，条件使能）----------------
  always_ff @(posedge clock) begin
    if (io_ptw_resp_valid) begin
      ptwResp_s2xlate          <= io_ptw_resp_bits_s2xlate;
      ptwResp_s1_entry_tag     <= io_ptw_resp_bits_s1_entry_tag;
      ptwResp_s1_entry_asid    <= io_ptw_resp_bits_s1_entry_asid;
      ptwResp_s1_entry_vmid    <= io_ptw_resp_bits_s1_entry_vmid;
      ptwResp_s1_entry_n       <= io_ptw_resp_bits_s1_entry_n;
      ptwResp_s1_entry_pbmt    <= io_ptw_resp_bits_s1_entry_pbmt;
      ptwResp_s1_entry_perm_d  <= io_ptw_resp_bits_s1_entry_perm_d;
      ptwResp_s1_entry_perm_a  <= io_ptw_resp_bits_s1_entry_perm_a;
      ptwResp_s1_entry_perm_g  <= io_ptw_resp_bits_s1_entry_perm_g;
      ptwResp_s1_entry_perm_u  <= io_ptw_resp_bits_s1_entry_perm_u;
      ptwResp_s1_entry_perm_x  <= io_ptw_resp_bits_s1_entry_perm_x;
      ptwResp_s1_entry_perm_w  <= io_ptw_resp_bits_s1_entry_perm_w;
      ptwResp_s1_entry_perm_r  <= io_ptw_resp_bits_s1_entry_perm_r;
      ptwResp_s1_entry_level   <= io_ptw_resp_bits_s1_entry_level;
      ptwResp_s1_entry_v       <= io_ptw_resp_bits_s1_entry_v;
      ptwResp_s1_entry_ppn     <= io_ptw_resp_bits_s1_entry_ppn;
      ptwResp_s1_addr_low      <= io_ptw_resp_bits_s1_addr_low;
      ptwResp_s1_ppn_low_0     <= io_ptw_resp_bits_s1_ppn_low_0;
      ptwResp_s1_ppn_low_1     <= io_ptw_resp_bits_s1_ppn_low_1;
      ptwResp_s1_ppn_low_2     <= io_ptw_resp_bits_s1_ppn_low_2;
      ptwResp_s1_ppn_low_3     <= io_ptw_resp_bits_s1_ppn_low_3;
      ptwResp_s1_ppn_low_4     <= io_ptw_resp_bits_s1_ppn_low_4;
      ptwResp_s1_ppn_low_5     <= io_ptw_resp_bits_s1_ppn_low_5;
      ptwResp_s1_ppn_low_6     <= io_ptw_resp_bits_s1_ppn_low_6;
      ptwResp_s1_ppn_low_7     <= io_ptw_resp_bits_s1_ppn_low_7;
      ptwResp_s1_valididx_0    <= io_ptw_resp_bits_s1_valididx_0;
      ptwResp_s1_valididx_1    <= io_ptw_resp_bits_s1_valididx_1;
      ptwResp_s1_valididx_2    <= io_ptw_resp_bits_s1_valididx_2;
      ptwResp_s1_valididx_3    <= io_ptw_resp_bits_s1_valididx_3;
      ptwResp_s1_valididx_4    <= io_ptw_resp_bits_s1_valididx_4;
      ptwResp_s1_valididx_5    <= io_ptw_resp_bits_s1_valididx_5;
      ptwResp_s1_valididx_6    <= io_ptw_resp_bits_s1_valididx_6;
      ptwResp_s1_valididx_7    <= io_ptw_resp_bits_s1_valididx_7;
      ptwResp_s1_pteidx_0      <= io_ptw_resp_bits_s1_pteidx_0;
      ptwResp_s1_pteidx_1      <= io_ptw_resp_bits_s1_pteidx_1;
      ptwResp_s1_pteidx_2      <= io_ptw_resp_bits_s1_pteidx_2;
      ptwResp_s1_pteidx_3      <= io_ptw_resp_bits_s1_pteidx_3;
      ptwResp_s1_pteidx_4      <= io_ptw_resp_bits_s1_pteidx_4;
      ptwResp_s1_pteidx_5      <= io_ptw_resp_bits_s1_pteidx_5;
      ptwResp_s1_pteidx_6      <= io_ptw_resp_bits_s1_pteidx_6;
      ptwResp_s1_pteidx_7      <= io_ptw_resp_bits_s1_pteidx_7;
      ptwResp_s1_pf            <= io_ptw_resp_bits_s1_pf;
      ptwResp_s1_af            <= io_ptw_resp_bits_s1_af;
      ptwResp_s2_entry_tag     <= io_ptw_resp_bits_s2_entry_tag;
      ptwResp_s2_entry_vmid    <= io_ptw_resp_bits_s2_entry_vmid;
      ptwResp_s2_entry_n       <= io_ptw_resp_bits_s2_entry_n;
      ptwResp_s2_entry_pbmt    <= io_ptw_resp_bits_s2_entry_pbmt;
      ptwResp_s2_entry_ppn     <= io_ptw_resp_bits_s2_entry_ppn;
      ptwResp_s2_entry_perm_d  <= io_ptw_resp_bits_s2_entry_perm_d;
      ptwResp_s2_entry_perm_a  <= io_ptw_resp_bits_s2_entry_perm_a;
      ptwResp_s2_entry_perm_g  <= io_ptw_resp_bits_s2_entry_perm_g;
      ptwResp_s2_entry_perm_u  <= io_ptw_resp_bits_s2_entry_perm_u;
      ptwResp_s2_entry_perm_x  <= io_ptw_resp_bits_s2_entry_perm_x;
      ptwResp_s2_entry_perm_w  <= io_ptw_resp_bits_s2_entry_perm_w;
      ptwResp_s2_entry_perm_r  <= io_ptw_resp_bits_s2_entry_perm_r;
      ptwResp_s2_entry_level   <= io_ptw_resp_bits_s2_entry_level;
      ptwResp_s2_gpf           <= io_ptw_resp_bits_s2_gpf;
      ptwResp_s2_gaf           <= io_ptw_resp_bits_s2_gaf;
    end
    // hint bank：每拍从 load 组寄存（req 无条件，resp 数据仅 valid 时）
    io_hint_req_0_REG_id   <= i_hint_req_0_id;
    io_hint_req_0_REG_full <= i_hint_req_0_full;
    io_hint_req_1_REG_id   <= i_hint_req_1_id;
    io_hint_req_1_REG_full <= i_hint_req_1_full;
    io_hint_req_2_REG_id   <= i_hint_req_2_id;
    io_hint_req_2_REG_full <= i_hint_req_2_full;
    io_hint_resp_valid_REG <= i_hint_resp_valid;
    if (i_hint_resp_valid) begin
      io_hint_resp_bits_r_id         <= i_hint_resp_bits_id;
      io_hint_resp_bits_r_replay_all <= i_hint_resp_bits_replay_all;
    end
  end

  // ---------------- 时序：*_last_REG（异步复位）----------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      load_filter_0_ptw_resp_valid_last_REG     <= 1'b0;
      store_filter_0_ptw_resp_valid_last_REG    <= 1'b0;
      prefetch_filter_0_ptw_resp_valid_last_REG <= 1'b0;
    end else begin
      load_filter_0_ptw_resp_valid_last_REG     <= io_ptw_resp_valid;
      store_filter_0_ptw_resp_valid_last_REG    <= io_ptw_resp_valid;
      prefetch_filter_0_ptw_resp_valid_last_REG <= io_ptw_resp_valid;
    end
  end

  // ---------------- 输出：三组过滤器的 ptw_resp_valid + 共用锁存数据 ----------------
  assign o_load_ptw_resp_valid_last     = load_filter_0_ptw_resp_valid_last_REG;
  assign o_store_ptw_resp_valid_last    = store_filter_0_ptw_resp_valid_last_REG;
  assign o_prefetch_ptw_resp_valid_last = prefetch_filter_0_ptw_resp_valid_last_REG;

  assign o_ptwResp_s2xlate        = ptwResp_s2xlate;
  assign o_ptwResp_s1_entry_tag   = ptwResp_s1_entry_tag;
  assign o_ptwResp_s1_entry_asid  = ptwResp_s1_entry_asid;
  assign o_ptwResp_s1_entry_vmid  = ptwResp_s1_entry_vmid;
  assign o_ptwResp_s1_entry_n     = ptwResp_s1_entry_n;
  assign o_ptwResp_s1_entry_perm_g= ptwResp_s1_entry_perm_g;
  assign o_ptwResp_s1_entry_level = ptwResp_s1_entry_level;
  assign o_ptwResp_s1_addr_low    = ptwResp_s1_addr_low;
  assign o_ptwResp_s1_valididx_0  = ptwResp_s1_valididx_0;
  assign o_ptwResp_s1_valididx_1  = ptwResp_s1_valididx_1;
  assign o_ptwResp_s1_valididx_2  = ptwResp_s1_valididx_2;
  assign o_ptwResp_s1_valididx_3  = ptwResp_s1_valididx_3;
  assign o_ptwResp_s1_valididx_4  = ptwResp_s1_valididx_4;
  assign o_ptwResp_s1_valididx_5  = ptwResp_s1_valididx_5;
  assign o_ptwResp_s1_valididx_6  = ptwResp_s1_valididx_6;
  assign o_ptwResp_s1_valididx_7  = ptwResp_s1_valididx_7;
  assign o_ptwResp_s2_entry_tag   = ptwResp_s2_entry_tag;
  assign o_ptwResp_s2_entry_vmid  = ptwResp_s2_entry_vmid;
  assign o_ptwResp_s2_entry_n     = ptwResp_s2_entry_n;
  assign o_ptwResp_s2_entry_level = ptwResp_s2_entry_level;

  // ---------------- tlb resp 输出：三组 refill 相或 + 锁存数据 ----------------
  assign io_tlb_resp_valid = i_load_refill | i_store_refill | i_prefetch_refill;
  assign io_tlb_resp_bits_data_s2xlate         = ptwResp_s2xlate;
  assign io_tlb_resp_bits_data_s1_entry_tag    = ptwResp_s1_entry_tag;
  assign io_tlb_resp_bits_data_s1_entry_asid   = ptwResp_s1_entry_asid;
  assign io_tlb_resp_bits_data_s1_entry_vmid   = ptwResp_s1_entry_vmid;
  assign io_tlb_resp_bits_data_s1_entry_n      = ptwResp_s1_entry_n;
  assign io_tlb_resp_bits_data_s1_entry_pbmt   = ptwResp_s1_entry_pbmt;
  assign io_tlb_resp_bits_data_s1_entry_perm_d = ptwResp_s1_entry_perm_d;
  assign io_tlb_resp_bits_data_s1_entry_perm_a = ptwResp_s1_entry_perm_a;
  assign io_tlb_resp_bits_data_s1_entry_perm_g = ptwResp_s1_entry_perm_g;
  assign io_tlb_resp_bits_data_s1_entry_perm_u = ptwResp_s1_entry_perm_u;
  assign io_tlb_resp_bits_data_s1_entry_perm_x = ptwResp_s1_entry_perm_x;
  assign io_tlb_resp_bits_data_s1_entry_perm_w = ptwResp_s1_entry_perm_w;
  assign io_tlb_resp_bits_data_s1_entry_perm_r = ptwResp_s1_entry_perm_r;
  assign io_tlb_resp_bits_data_s1_entry_level  = ptwResp_s1_entry_level;
  assign io_tlb_resp_bits_data_s1_entry_v      = ptwResp_s1_entry_v;
  assign io_tlb_resp_bits_data_s1_entry_ppn    = ptwResp_s1_entry_ppn;
  assign io_tlb_resp_bits_data_s1_addr_low     = ptwResp_s1_addr_low;
  assign io_tlb_resp_bits_data_s1_ppn_low_0    = ptwResp_s1_ppn_low_0;
  assign io_tlb_resp_bits_data_s1_ppn_low_1    = ptwResp_s1_ppn_low_1;
  assign io_tlb_resp_bits_data_s1_ppn_low_2    = ptwResp_s1_ppn_low_2;
  assign io_tlb_resp_bits_data_s1_ppn_low_3    = ptwResp_s1_ppn_low_3;
  assign io_tlb_resp_bits_data_s1_ppn_low_4    = ptwResp_s1_ppn_low_4;
  assign io_tlb_resp_bits_data_s1_ppn_low_5    = ptwResp_s1_ppn_low_5;
  assign io_tlb_resp_bits_data_s1_ppn_low_6    = ptwResp_s1_ppn_low_6;
  assign io_tlb_resp_bits_data_s1_ppn_low_7    = ptwResp_s1_ppn_low_7;
  assign io_tlb_resp_bits_data_s1_valididx_0   = ptwResp_s1_valididx_0;
  assign io_tlb_resp_bits_data_s1_valididx_1   = ptwResp_s1_valididx_1;
  assign io_tlb_resp_bits_data_s1_valididx_2   = ptwResp_s1_valididx_2;
  assign io_tlb_resp_bits_data_s1_valididx_3   = ptwResp_s1_valididx_3;
  assign io_tlb_resp_bits_data_s1_valididx_4   = ptwResp_s1_valididx_4;
  assign io_tlb_resp_bits_data_s1_valididx_5   = ptwResp_s1_valididx_5;
  assign io_tlb_resp_bits_data_s1_valididx_6   = ptwResp_s1_valididx_6;
  assign io_tlb_resp_bits_data_s1_valididx_7   = ptwResp_s1_valididx_7;
  assign io_tlb_resp_bits_data_s1_pteidx_0     = ptwResp_s1_pteidx_0;
  assign io_tlb_resp_bits_data_s1_pteidx_1     = ptwResp_s1_pteidx_1;
  assign io_tlb_resp_bits_data_s1_pteidx_2     = ptwResp_s1_pteidx_2;
  assign io_tlb_resp_bits_data_s1_pteidx_3     = ptwResp_s1_pteidx_3;
  assign io_tlb_resp_bits_data_s1_pteidx_4     = ptwResp_s1_pteidx_4;
  assign io_tlb_resp_bits_data_s1_pteidx_5     = ptwResp_s1_pteidx_5;
  assign io_tlb_resp_bits_data_s1_pteidx_6     = ptwResp_s1_pteidx_6;
  assign io_tlb_resp_bits_data_s1_pteidx_7     = ptwResp_s1_pteidx_7;
  assign io_tlb_resp_bits_data_s1_pf           = ptwResp_s1_pf;
  assign io_tlb_resp_bits_data_s1_af           = ptwResp_s1_af;
  assign io_tlb_resp_bits_data_s2_entry_tag    = ptwResp_s2_entry_tag;
  assign io_tlb_resp_bits_data_s2_entry_vmid   = ptwResp_s2_entry_vmid;
  assign io_tlb_resp_bits_data_s2_entry_n      = ptwResp_s2_entry_n;
  assign io_tlb_resp_bits_data_s2_entry_pbmt   = ptwResp_s2_entry_pbmt;
  assign io_tlb_resp_bits_data_s2_entry_ppn    = ptwResp_s2_entry_ppn;
  assign io_tlb_resp_bits_data_s2_entry_perm_d = ptwResp_s2_entry_perm_d;
  assign io_tlb_resp_bits_data_s2_entry_perm_a = ptwResp_s2_entry_perm_a;
  assign io_tlb_resp_bits_data_s2_entry_perm_g = ptwResp_s2_entry_perm_g;
  assign io_tlb_resp_bits_data_s2_entry_perm_u = ptwResp_s2_entry_perm_u;
  assign io_tlb_resp_bits_data_s2_entry_perm_x = ptwResp_s2_entry_perm_x;
  assign io_tlb_resp_bits_data_s2_entry_perm_w = ptwResp_s2_entry_perm_w;
  assign io_tlb_resp_bits_data_s2_entry_perm_r = ptwResp_s2_entry_perm_r;
  assign io_tlb_resp_bits_data_s2_entry_level  = ptwResp_s2_entry_level;
  assign io_tlb_resp_bits_data_s2_gpf          = ptwResp_s2_gpf;
  assign io_tlb_resp_bits_data_s2_gaf          = ptwResp_s2_gaf;
  assign io_tlb_resp_bits_vector_0 = i_load_refill;
  assign io_tlb_resp_bits_vector_4 = i_store_refill;
  assign io_tlb_resp_bits_vector_6 = i_prefetch_refill;

  // ---------------- hint 输出（寄存版）----------------
  assign io_hint_req_0_id          = io_hint_req_0_REG_id;
  assign io_hint_req_0_full        = io_hint_req_0_REG_full;
  assign io_hint_req_1_id          = io_hint_req_1_REG_id;
  assign io_hint_req_1_full        = io_hint_req_1_REG_full;
  assign io_hint_req_2_id          = io_hint_req_2_REG_id;
  assign io_hint_req_2_full        = io_hint_req_2_REG_full;
  assign io_hint_resp_valid        = io_hint_resp_valid_REG;
  assign io_hint_resp_bits_id      = io_hint_resp_bits_r_id;
  assign io_hint_resp_bits_replay_all = io_hint_resp_bits_r_replay_all;

  // ---------------- rob head miss 相或 ----------------
  assign io_rob_head_miss_in_tlb = i_load_rob_head_miss | i_store_rob_head_miss | i_prefetch_rob_head_miss;

endmodule
