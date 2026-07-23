// =============================================================================
// xs_PtwCache_core —— L2TLB 页表 Cache（可读 SystemVerilog 重写）
//
// 设计意图来自 PageTableCache.scala class PtwCache（不是 firtool golden 转写）。
// 角色与微架构见 docs/memblock/PtwCache.md（权威 spec）。一句话：
//   缓存四级页表（L3/L2 全相联寄存器堆、L1/L0 组相联 SRAM、SP 超级页全相联），
//   三级流水（Req→Delay→Check→Resp）并行比较各级 tag 命中；命中即给最终翻译或告诉
//   walker 从哪一级接着走；miss 由 walker 走完后 refill 回来；sfence/hfence 无效化。
//
// 控制逻辑按节拆分到 svh：
//   ptwcache_query.svh  —— 各级 tag/asid/vmid 命中匹配（含三级流水相位对齐）
//   ptwcache_resp.svh   —— stageResp 输出汇总（hit/toFsm/toHptw/stage1/bypassed）
//   ptwcache_refill.svh —— refill 写入各级 + replaceWrapper/PLRU victim 选择
//   ptwcache_sfence.svh —— sfence / hfence-v / hfence-g 无效化向量
//
// 本配置：EnableSv48=true（4 级 + SP）、HasBitmapCheck=false、enablePTWECC=false。
//
// 存储/DFT 黑盒由 wrapper 直连 golden 实例：本核只暴露 L1/L0 SRAM 的读写接口端口
// （setIdx/读出行/写数据/waymask），不含 SRAM 宏与 bore 时钟门控旁带。
// =============================================================================
module xs_PtwCache_core
  import xs_ptwcache_pkg::*;
(
  input  logic        clock,
  input  logic        reset,

  // CSR（mPBMTE/hPBMTE 决定 pbmt 合法性；三份 dup 的 satp/vsatp/hgatp/priv 供各流水级用）
  input  logic        csr_mPBMTE,
  input  logic        csr_hPBMTE,
  input  logic [2:0][ASID_W-1:0] csr_satp_asid,
  input  logic [2:0]             csr_satp_changed,
  input  logic [2:0][ASID_W-1:0] csr_vsatp_asid,
  input  logic [2:0]             csr_vsatp_changed,
  input  logic [2:0][3:0]        csr_hgatp_mode,
  input  logic [2:0][ASID_W-1:0] csr_hgatp_vmid,
  input  logic [2:0]             csr_hgatp_changed,
  input  logic [2:0]             csr_priv_virt,

  // req：来自 L2TLB 顶层的 cache 查询
  output logic        req_ready,
  input  logic        req_valid,
  input  req_info_t   req_info,
  input  logic        req_isFirst,
  input  logic        req_isHptwReq,
  input  logic [2:0]  req_hptwId,

  // resp：cache 查询结果
  input  logic        resp_ready,
  output logic        resp_valid,
  output ptwcache_resp_t resp_bits,

  // refill：walker 取回 PTE 后写入
  input  logic        refill_valid,
  input  logic [BLOCK_BITS-1:0] refill_ptes,
  input  logic        refill_levelOH_sp,
  input  logic        refill_levelOH_l0,
  input  logic        refill_levelOH_l1,
  input  logic        refill_levelOH_l2,
  input  logic        refill_levelOH_l3,
  input  req_info_t   refill_req_info_dup_0,
  input  req_info_t   refill_req_info_dup_1,
  input  req_info_t   refill_req_info_dup_2,
  input  logic [1:0]  refill_level_dup_0,
  input  logic [1:0]  refill_level_dup_2,
  input  logic [63:0] refill_sel_pte_dup_0,
  input  logic [63:0] refill_sel_pte_dup_2,

  // sfence / hfence（四份 dup；dup0 带完整 bits，dup1/2 仅 valid + 部分 bits）
  input  sfence_bits_t sfence_dup_0,
  input  logic         sfence_dup_1_valid,
  input  logic [15:0]  sfence_dup_1_id,
  input  logic         sfence_dup_2_valid,
  input  logic         sfence_dup_2_rs1,
  input  logic         sfence_dup_2_rs2,
  input  logic [15:0]  sfence_dup_2_id,

  // ---- L1 SRAM（8 set × 2 way）读写口，黑盒在 wrapper 例化 ----
  output logic                l1_r_req_valid,
  output logic [L1_SET_IDX_W-1:0] l1_r_req_setIdx,
  input  l1_sram_entry_t      l1_r_resp_data [L1_WAYS],
  output logic                l1_w_req_valid,
  output logic [L1_SET_IDX_W-1:0] l1_w_req_setIdx,
  output l1_sram_entry_t      l1_w_req_data,        // 两 way 数据相同，wrapper 广播
  output logic [L1_WAYS-1:0]  l1_w_req_waymask,

  // ---- L0 SRAM（32 set × 4 way）读写口 ----
  output logic                l0_r_req_valid,
  output logic [L0_SET_IDX_W-1:0] l0_r_req_setIdx,
  input  l0_sram_entry_t      l0_r_resp_data [L0_WAYS],
  output logic                l0_w_req_valid,
  output logic [L0_SET_IDX_W-1:0] l0_w_req_setIdx,
  output l0_sram_entry_t      l0_w_req_data,
  output logic [L0_WAYS-1:0]  l0_w_req_waymask,

  // SRAM 时钟门控使能（wrapper 用它驱动 ClockGate → l*_masked_clock）
  output logic        l0_clock_en,
  output logic        l1_clock_en,

  // 8 个 perf 计数（access/l3~sp hit 等的事件脉冲；本核只产生事件，计数在外）
  output logic [7:0][5:0] perf
);

  genvar gi;

  // ---------------------------------------------------------------------------
  // flush（sfence / satp/vsatp/hgatp changed）—— 三份 dup 各自的冲刷信号
  // ---------------------------------------------------------------------------
  logic [2:0] flush_dup;
  assign flush_dup[0] = sfence_dup_0.valid || csr_satp_changed[0] || csr_vsatp_changed[0] || csr_hgatp_changed[0];
  assign flush_dup[1] = sfence_dup_1_valid || csr_satp_changed[1] || csr_vsatp_changed[1] || csr_hgatp_changed[1];
  assign flush_dup[2] = sfence_dup_2_valid || csr_satp_changed[2] || csr_vsatp_changed[2] || csr_hgatp_changed[2];
  wire flush = flush_dup[0];

  // 单口 SRAM：refill 写时拒收新 req
  wire rwHazard = refill_valid;

  // ===========================================================================
  // 三级流水握手（PipelineConnect + InsideStageConnect）
  //   stageReq → stageDelay[0]/[1] → stageCheck[0]/[1] → stageResp
  // 每个 stage 携带 PtwCacheReq（req_info/isFirst/isHptwReq/hptwId/bypassed[4]）。
  // ===========================================================================
  // 注：bypassed（EnableSv48 4 位 l0/l1/l2/l3）不放进流水 payload 结构——
  // 入口恒 0、stageDelay[0] 载荷寄存器 golden 已折叠消去（写而不读的常 0 死寄存器）。
  // bypassed 只在需要处单独维护：stageCheck0/stageResp 各一个真寄存器 + delay1/check1 组合。
  typedef struct packed {
    req_info_t  req_info;
    logic       isFirst;
    logic       isHptwReq;
    logic [2:0] hptwId;
  } stage_payload_t;

  logic [3:0] stageCheck0_bypassed, stageResp_bypassed;   // 唯二 bypassed 流水寄存器
  logic [3:0] stageDelay1_bypassed, stageCheck1_bypassed;  // 组合累积

  stage_payload_t stageReq_bits;
  assign stageReq_bits.req_info  = req_info;
  assign stageReq_bits.isFirst   = req_isFirst;
  assign stageReq_bits.isHptwReq = req_isHptwReq;
  assign stageReq_bits.hptwId    = req_hptwId;

  logic stageReq_valid, stageReq_ready;
  assign stageReq_valid = req_valid;
  assign req_ready = stageReq_ready;
  wire stageReq_fire = stageReq_valid && stageReq_ready;

  // stage valid/ready/bits
  logic [1:0] stageDelay_valid, stageDelay_ready;
  stage_payload_t stageDelay_bits [2];
  logic [1:0] stageCheck_valid, stageCheck_ready;
  stage_payload_t stageCheck_bits [2];
  logic stageResp_valid_r, stageResp_ready;
  stage_payload_t stageResp_bits;

  // 单拍 fire 脉冲：用于锁存 SRAM 读出 / PLRU access / ecc-flush 时机
  logic stageDelay_valid_1cycle;       // = OneCycleValid(stageReq.fire)
  logic stageCheck_valid_1cycle;       // = OneCycleValid(stageDelay[1].fire)

  wire stageDelay0_fire = stageDelay_valid[0] && stageDelay_ready[0];
  wire stageDelay1_fire = stageDelay_valid[1] && stageDelay_ready[1];
  wire stageCheck0_fire = stageCheck_valid[0] && stageCheck_ready[0];
  wire stageCheck1_fire = stageCheck_valid[1] && stageCheck_ready[1];
  wire stageResp_fire   = stageResp_valid_r && resp_ready;

  // refill_bypass 前置：refill 正写一条与查询同 vpn/level 的项 -> 本拍 miss 但马上有
  // 在 query 段定义 refill_bypass_*; InsideStageConnect 用到，故先声明 wire 函数式信号。
  logic refill_bypass_l0_in, refill_bypass_l1_in, refill_bypass_l2_in, refill_bypass_l3_in;

  // PipelineConnect: stageReq -> stageDelay[0]（blockIn=rwHazard, flush）
  `include "ptwcache_pipe.svh"

  // ===========================================================================
  // 五个缓存阵列的存储寄存器（L1/L0 的 data 在 SRAM 黑盒里，这里只存 v/g/h/asid/vmid/vpn）
  // ===========================================================================
  // L3：16 项全相联（窄结构 l3_entry_t：11b tag，无 pbmt/v 死字段）
  l3_entry_t l3 [L3_SIZE];
  logic [L3_SIZE-1:0] l3v, l3g;
  logic [1:0] l3h [L3_SIZE];
  // L2：16 项全相联
  nonleaf_entry_t l2 [L2_SIZE];
  logic [L2_SIZE-1:0] l2v, l2g;
  logic [1:0] l2h [L2_SIZE];
  // L1：8 set × 2 way（data 在 SRAM）
  logic [L1_SETS*L1_WAYS-1:0] l1v, l1g;
  logic [1:0]            l1h     [L1_SETS][L1_WAYS];
  logic [HASH_ASID_W-1:0] l1asids [L1_SETS][L1_WAYS];
  logic [HASH_ASID_W-1:0] l1vmids [L1_SETS][L1_WAYS];
  // L0：32 set × 4 way（data 在 SRAM）
  logic [L0_SETS*L0_WAYS-1:0] l0v, l0g;
  logic [1:0]            l0h     [L0_SETS][L0_WAYS];
  logic [HASH_ASID_W-1:0] l0asids [L0_SETS][L0_WAYS];
  logic [HASH_ASID_W-1:0] l0vmids [L0_SETS][L0_WAYS];
  logic [HASH_VPN_W-1:0]  l0vpns  [L0_SETS][L0_WAYS];
  // SP：16 项全相联超级页
  sp_entry_t sp [SP_SIZE];
  logic [SP_SIZE-1:0] spv, spg;
  logic [1:0] sph [SP_SIZE];

  // PLRU 替换状态
  logic [14:0] l3replace, l2replace, spreplace;       // 16 路树
  logic        l1replace [L1_SETS];                   // 2 路树（每 set 1 bit）
  logic [2:0]  l0replace [L0_SETS];                   // 4 路树（每 set 3 bit）

  // ===========================================================================
  // 查询关键量（vpn_search / h_search）
  // ===========================================================================
  wire [VPN_W-1:0] vpn_search = stageReq_bits.req_info.vpn;
  wire [1:0] h_search = change_h(stageReq_bits.req_info.s2xlate);

  // 命中结果（check_res：stageCheck 算出；resp_res：寄存到 stageResp 用）
  pagecache_resp_t check_res;
  pagecache_resp_t resp_res;

  // sfence 清除掩码（在 sfence.svh 组合赋值，refill.svh 的 valid 更新读取）
  logic [L3_SIZE-1:0]         l3v_sfence_clr;
  logic [L2_SIZE-1:0]         l2v_sfence_clr;
  logic [L1_SETS*L1_WAYS-1:0] l1v_sfence_clr;
  logic [L0_SETS*L0_WAYS-1:0] l0v_sfence_clr;
  logic [SP_SIZE-1:0]         spv_sfence_clr;

  // L1/L0 SRAM 读请求：stageReq.fire 时发起，setIdx 用本拍 vpn
  assign l1_r_req_valid   = stageReq_fire;
  assign l1_r_req_setIdx  = l1_set_idx(vpn_search);
  assign l0_r_req_valid   = stageReq_fire;
  assign l0_r_req_setIdx  = l0_set_idx(vpn_search);

  // ---- 各级命中匹配（含三级流水相位对齐）----
  `include "ptwcache_query.svh"

  // ---- stageResp 输出汇总 ----
  `include "ptwcache_resp.svh"

  // ---- refill 写入 + PLRU ----
  `include "ptwcache_refill.svh"

  // ---- sfence / hfence 无效化 ----
  `include "ptwcache_sfence.svh"

endmodule
