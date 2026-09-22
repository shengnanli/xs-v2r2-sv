// PTW.sv —— 页表走表器（Page Table Walker，L2TLB 里的 "fsm"）：处理 PtwCache 未命中的
// 高层级（l3/l2/l1）页表访问，一次只服务一个请求；走到最后一级（4KB 页表页）时把请求
// 交给 LLPTW 并行处理。H 扩展下每一级的客户机物理地址都要先经 HPTW 翻译（两阶段翻译）。
//
// 本文件含：xs_ptw_pkg（本模块私有类型）+ xs_PTW_core（可读重写核）+ PTW（golden 同名
// wrapper，419 端口透传）。PTE 位图与判定函数来自 rtl/mmu/mmu_common_pkg.sv。
// 对应 Chisel: xiangshan.cache.mmu.PTW（PageTableWalker.scala 第 99 行起）；
// 对照 golden = G1-canonical/golden-rtl/PTW.sv（2036 行，单变体；419 端口里 8 条 stage1
// 表项的输入/输出展开占了 300 多根）。
//
// 【它在 L2TLB 里的位置】
//   PtwCache 未命中 ─▶ 本模块（一次一个请求）──level 到 1 且非叶子──▶ LLPTW（多条目并行）
//                        │ 每级：PMP 检查 → 访存 → 判 PTE（叶子/故障/再下一级）
//                        │ 两阶段翻译：每级先把 GPA 交给 HPTW 翻成 HPA 再访存
//                        └──叶子/故障/onlyStage2──▶ io.resp（PtwMergeResp + HptwResp）
//
// 【入口有三种请求（互斥，优先级见 §5）】
//   · 普通走表（req_walk）：从 PtwCache 命中的最深一级往下走，level/af_level/gpf_level
//     由 l3Hit/l2Hit 与 satp.mode 决定；
//       - onlyStage2：vpn 就是 GPA，直接发"最后一次" HPTW 请求（s_last_hptw_req=0）；
//       - allStage：先把根页表 GPA 交给 HPTW（s_hptw_req=0，need_last_s2xlate=1）；
//       - noS2xlate / onlyStage1：直接 PMP 检查（s_pmp_check=0）。
//     GPA 高位越界（hgatp.mode 允许的位宽之外）在入口就判 gpf：first_gvpn_check_fail。
//   · stage1 命中（req_stage1）：PtwCache 已给出第一阶段结果（stage1 整条 PtwMergeResp
//     锁进寄存器），只欠最后一次 HPTW 翻译；HPTW 回来后 hptw_resp_stage2=1 即可回应。
//   · bitmap 跳转（req_jmp，G1 新增，s2xlate != onlyStage2 时才认）：PtwCache 已命中叶子
//     只欠 bitmap 检查；PTE 锁进 cache_pte_*，直接进 s_bitmap_check。
//
// 【一级的状态位序列（Chisel 惯用的 s_=已发 / w_=已等到 反相编码，1 表示"此步不需做"）】
//   [s2xlate: s_hptw_req=0 → hptw.req.fire → w_hptw_resp=0 → hptw.resp（无故障则 s_pmp_check=0）]
//   s_pmp_check=0 → sent_to_pmp → s_mem_req=0 → mem.req.fire → w_mem_resp=0 → mem.resp
//   [bitmap 使能：whether_need_bitmap_check → 叶子且无 pf → s_bitmap_check=0 → … → bitmap.resp]
//   → mem_addr_update=1 → 判定：level>=2 且非叶子无故障 → level-1，再来一级
//                              level==1 且非叶子 → io.llptw（交给 LLPTW）
//                              s2xlate 且 need_last_s2xlate → 最后一次 HPTW（翻叶子 GPA）
//                              否则 io.resp
//
// 【访存地址】l3addr/l2addr/l1addr = MakeAddr(本级页表基址, vpn 该级 9 位片)，基址取
//   "该级在 PtwCache 已命中则 req.ppn 否则刚读回的 pte.ppn"（Sv39 下 l2 基址就是 satp.ppn）；
//   按 af_level 选一条为 mem_addr；s2xlate 时用 HPTW 翻出的 hpaddr（hptw_resp.genPPNS2）。
//
// 【故障优先级（ptw_resp）】pf（pte_valid & pageFault）> guestFault > af（accessFault | ppn_af）；
//   resp_level：accessFault 用 af_level，guestFault 用 gpf_level，否则 level。
//   没真正访过存（pte_valid=0）时用 fake_pte（v=0，ppn 取请求带来的 ppn）告诉 L1 TLB 这是假 PTE。
//
// 【复位域（golden 实测）】
//   异步复位：level/af_level/gpf_level（3）、8 个 s_/w_ 状态位、mem_addr_update、bitmap 4 位、
//   idle、hptw_pageFault/hptw_accessFault、need_last_s2xlate、first_gvpn_check_fail、pte_valid、
//   accessFault、update_full_gvpn_mem_resp、两个 BoolStopWatch（mem_cycle）。
//   不复位：req_s2xlate、ppn、vpn、l3Hit/l2Hit、jmp_bitmap_check_r、cache_pte_*（无 rsw）、
//   stage1Hit、stage1 整条（8 表项 + pteidx + not_super）、hptw_resp_stage2、source、
//   hptw_resp 整条、full_gvpn_reg、cache_level、7 组 perf 两拍打拍。
//
// 【golden 的两个怪癖，照抄】
//   · perf 的 mem_cycle 用 BoolStopWatch，golden 里留了**两份**同样的寄存器：一份喂
//     io_perf_5，另一份（golden 名 r）只接到一根悬空探针 r_probe，谁也不读。impl 同样
//     保留两份（mem_cycle_watch / r），不多不少，与 golden 对称；无扇出的寄存器 FM 只能按名
//     配对，所以第二份沿用 golden 的名字 r（首跑实测：叫 mem_cycle_watch_probe 时两侧各 1 个 unmatched-unread）；
//     它是"两侧都有、都没人读"的 matched-unread 点，依据见 verif/fm_target_config/PTW.tcl。
//   · stage1 的输入没有 af 字段（父级喂进来的恒 0 被 firtool 消了端口），但输出 entry 有 af：
//     用 stage1 回应时 af 恒 0。
//
// 【本文件导航】（行号由分节注释量出；改动后请重新对一遍）
//   L76  package xs_ptw_pkg
//   L539  §1 全局控制与 CSR 选择
//   L570  §2 寄存器声明
//   L614  §3 当前 PTE / 故障判定
//   L655  §4 地址生成
//   L694  §5 事件与握手（注明 golden 的 _GEN_ 编号）
//   L780  §6 状态机（异步复位域）—— 按 Chisel 的 when 顺序转写，后写者赢
//   L921  §7 载荷寄存器（不复位域）
//   L1048  §8 响应装配
//   L1093  §9 输出
//   L1198  §10 perf：fsm_count / fsm_busy / fsm_idle / resp_blocked / mem_count / mem_cycle / mem_blocked
//   L1210  wrapper PTW（生成段）
package xs_ptw_pkg;
  // PtwMergeResp 一条表项（PTW 输出 / stage1 输入用同一形状；stage1 输入没有 af）
  typedef struct packed {
    logic d, a, g, u, x, w, r;
  } ptw_perm_t;

  typedef struct packed {
    logic [34:0] tag;      // vpn[37:3]（sector 内 3 位在 pteidx 里）
    logic [15:0] asid;
    logic [13:0] vmid;
    logic        n;
    logic [1:0]  pbmt;
    ptw_perm_t   perm;
    logic [1:0]  level;
    logic        v;
    logic [40:0] ppn;      // {ppn_high[7:0], ppn[35:3]}
    logic [2:0]  ppn_low;  // ppn[2:0]
    logic        pf;
    logic        cf;
  } s1_entry_t;

  // HptwResp：HPTW 回来的第二阶段翻译结果
  typedef struct packed {
    logic [37:0] entry_tag;
    logic [13:0] entry_vmid;
    logic        entry_n;
    logic [1:0]  entry_pbmt;
    logic [37:0] entry_ppn;
    ptw_perm_t   entry_perm;
    logic [1:0]  entry_level;
    logic        gpf;
    logic        gaf;
  } hptw_resp_t;
endpackage

module xs_PTW_core
  import xs_mmu_common_pkg::*;
  import xs_ptw_pkg::*;
(
  // BEGIN GENERATED(core_ports) —— 由 gen_mmu5.py 从 golden 端口表逐根抄出
  input  logic         clock,
  input  logic         reset,
  input  logic         io_sfence_valid,
  input  logic [3:0]   io_csr_satp_mode,
  input  logic [15:0]  io_csr_satp_asid,
  input  logic [43:0]  io_csr_satp_ppn,
  input  logic         io_csr_satp_changed,
  input  logic [3:0]   io_csr_vsatp_mode,
  input  logic [15:0]  io_csr_vsatp_asid,
  input  logic [43:0]  io_csr_vsatp_ppn,
  input  logic         io_csr_vsatp_changed,
  input  logic [3:0]   io_csr_hgatp_mode,
  input  logic [15:0]  io_csr_hgatp_vmid,
  input  logic         io_csr_hgatp_changed,
  input  logic         io_csr_mbmc_BME,
  input  logic         io_csr_mbmc_CMODE,
  input  logic         io_csr_priv_virt_changed,
  input  logic         io_csr_mPBMTE,
  input  logic         io_csr_hPBMTE,
  output logic         io_req_ready,
  input  logic         io_req_valid,
  input  logic [37:0]  io_req_bits_req_info_vpn,
  input  logic [1:0]   io_req_bits_req_info_s2xlate,
  input  logic [1:0]   io_req_bits_req_info_source,
  input  logic         io_req_bits_l3Hit,
  input  logic         io_req_bits_l2Hit,
  input  logic [43:0]  io_req_bits_ppn,
  input  logic         io_req_bits_stage1Hit,
  input  logic [34:0]  io_req_bits_stage1_entry_0_tag,
  input  logic [15:0]  io_req_bits_stage1_entry_0_asid,
  input  logic [13:0]  io_req_bits_stage1_entry_0_vmid,
  input  logic         io_req_bits_stage1_entry_0_n,
  input  logic [1:0]   io_req_bits_stage1_entry_0_pbmt,
  input  logic         io_req_bits_stage1_entry_0_perm_d,
  input  logic         io_req_bits_stage1_entry_0_perm_a,
  input  logic         io_req_bits_stage1_entry_0_perm_g,
  input  logic         io_req_bits_stage1_entry_0_perm_u,
  input  logic         io_req_bits_stage1_entry_0_perm_x,
  input  logic         io_req_bits_stage1_entry_0_perm_w,
  input  logic         io_req_bits_stage1_entry_0_perm_r,
  input  logic [1:0]   io_req_bits_stage1_entry_0_level,
  input  logic         io_req_bits_stage1_entry_0_v,
  input  logic [40:0]  io_req_bits_stage1_entry_0_ppn,
  input  logic [2:0]   io_req_bits_stage1_entry_0_ppn_low,
  input  logic         io_req_bits_stage1_entry_0_pf,
  input  logic         io_req_bits_stage1_entry_0_cf,
  input  logic [34:0]  io_req_bits_stage1_entry_1_tag,
  input  logic [15:0]  io_req_bits_stage1_entry_1_asid,
  input  logic [13:0]  io_req_bits_stage1_entry_1_vmid,
  input  logic         io_req_bits_stage1_entry_1_n,
  input  logic [1:0]   io_req_bits_stage1_entry_1_pbmt,
  input  logic         io_req_bits_stage1_entry_1_perm_d,
  input  logic         io_req_bits_stage1_entry_1_perm_a,
  input  logic         io_req_bits_stage1_entry_1_perm_g,
  input  logic         io_req_bits_stage1_entry_1_perm_u,
  input  logic         io_req_bits_stage1_entry_1_perm_x,
  input  logic         io_req_bits_stage1_entry_1_perm_w,
  input  logic         io_req_bits_stage1_entry_1_perm_r,
  input  logic [1:0]   io_req_bits_stage1_entry_1_level,
  input  logic         io_req_bits_stage1_entry_1_v,
  input  logic [40:0]  io_req_bits_stage1_entry_1_ppn,
  input  logic [2:0]   io_req_bits_stage1_entry_1_ppn_low,
  input  logic         io_req_bits_stage1_entry_1_pf,
  input  logic         io_req_bits_stage1_entry_1_cf,
  input  logic [34:0]  io_req_bits_stage1_entry_2_tag,
  input  logic [15:0]  io_req_bits_stage1_entry_2_asid,
  input  logic [13:0]  io_req_bits_stage1_entry_2_vmid,
  input  logic         io_req_bits_stage1_entry_2_n,
  input  logic [1:0]   io_req_bits_stage1_entry_2_pbmt,
  input  logic         io_req_bits_stage1_entry_2_perm_d,
  input  logic         io_req_bits_stage1_entry_2_perm_a,
  input  logic         io_req_bits_stage1_entry_2_perm_g,
  input  logic         io_req_bits_stage1_entry_2_perm_u,
  input  logic         io_req_bits_stage1_entry_2_perm_x,
  input  logic         io_req_bits_stage1_entry_2_perm_w,
  input  logic         io_req_bits_stage1_entry_2_perm_r,
  input  logic [1:0]   io_req_bits_stage1_entry_2_level,
  input  logic         io_req_bits_stage1_entry_2_v,
  input  logic [40:0]  io_req_bits_stage1_entry_2_ppn,
  input  logic [2:0]   io_req_bits_stage1_entry_2_ppn_low,
  input  logic         io_req_bits_stage1_entry_2_pf,
  input  logic         io_req_bits_stage1_entry_2_cf,
  input  logic [34:0]  io_req_bits_stage1_entry_3_tag,
  input  logic [15:0]  io_req_bits_stage1_entry_3_asid,
  input  logic [13:0]  io_req_bits_stage1_entry_3_vmid,
  input  logic         io_req_bits_stage1_entry_3_n,
  input  logic [1:0]   io_req_bits_stage1_entry_3_pbmt,
  input  logic         io_req_bits_stage1_entry_3_perm_d,
  input  logic         io_req_bits_stage1_entry_3_perm_a,
  input  logic         io_req_bits_stage1_entry_3_perm_g,
  input  logic         io_req_bits_stage1_entry_3_perm_u,
  input  logic         io_req_bits_stage1_entry_3_perm_x,
  input  logic         io_req_bits_stage1_entry_3_perm_w,
  input  logic         io_req_bits_stage1_entry_3_perm_r,
  input  logic [1:0]   io_req_bits_stage1_entry_3_level,
  input  logic         io_req_bits_stage1_entry_3_v,
  input  logic [40:0]  io_req_bits_stage1_entry_3_ppn,
  input  logic [2:0]   io_req_bits_stage1_entry_3_ppn_low,
  input  logic         io_req_bits_stage1_entry_3_pf,
  input  logic         io_req_bits_stage1_entry_3_cf,
  input  logic [34:0]  io_req_bits_stage1_entry_4_tag,
  input  logic [15:0]  io_req_bits_stage1_entry_4_asid,
  input  logic [13:0]  io_req_bits_stage1_entry_4_vmid,
  input  logic         io_req_bits_stage1_entry_4_n,
  input  logic [1:0]   io_req_bits_stage1_entry_4_pbmt,
  input  logic         io_req_bits_stage1_entry_4_perm_d,
  input  logic         io_req_bits_stage1_entry_4_perm_a,
  input  logic         io_req_bits_stage1_entry_4_perm_g,
  input  logic         io_req_bits_stage1_entry_4_perm_u,
  input  logic         io_req_bits_stage1_entry_4_perm_x,
  input  logic         io_req_bits_stage1_entry_4_perm_w,
  input  logic         io_req_bits_stage1_entry_4_perm_r,
  input  logic [1:0]   io_req_bits_stage1_entry_4_level,
  input  logic         io_req_bits_stage1_entry_4_v,
  input  logic [40:0]  io_req_bits_stage1_entry_4_ppn,
  input  logic [2:0]   io_req_bits_stage1_entry_4_ppn_low,
  input  logic         io_req_bits_stage1_entry_4_pf,
  input  logic         io_req_bits_stage1_entry_4_cf,
  input  logic [34:0]  io_req_bits_stage1_entry_5_tag,
  input  logic [15:0]  io_req_bits_stage1_entry_5_asid,
  input  logic [13:0]  io_req_bits_stage1_entry_5_vmid,
  input  logic         io_req_bits_stage1_entry_5_n,
  input  logic [1:0]   io_req_bits_stage1_entry_5_pbmt,
  input  logic         io_req_bits_stage1_entry_5_perm_d,
  input  logic         io_req_bits_stage1_entry_5_perm_a,
  input  logic         io_req_bits_stage1_entry_5_perm_g,
  input  logic         io_req_bits_stage1_entry_5_perm_u,
  input  logic         io_req_bits_stage1_entry_5_perm_x,
  input  logic         io_req_bits_stage1_entry_5_perm_w,
  input  logic         io_req_bits_stage1_entry_5_perm_r,
  input  logic [1:0]   io_req_bits_stage1_entry_5_level,
  input  logic         io_req_bits_stage1_entry_5_v,
  input  logic [40:0]  io_req_bits_stage1_entry_5_ppn,
  input  logic [2:0]   io_req_bits_stage1_entry_5_ppn_low,
  input  logic         io_req_bits_stage1_entry_5_pf,
  input  logic         io_req_bits_stage1_entry_5_cf,
  input  logic [34:0]  io_req_bits_stage1_entry_6_tag,
  input  logic [15:0]  io_req_bits_stage1_entry_6_asid,
  input  logic [13:0]  io_req_bits_stage1_entry_6_vmid,
  input  logic         io_req_bits_stage1_entry_6_n,
  input  logic [1:0]   io_req_bits_stage1_entry_6_pbmt,
  input  logic         io_req_bits_stage1_entry_6_perm_d,
  input  logic         io_req_bits_stage1_entry_6_perm_a,
  input  logic         io_req_bits_stage1_entry_6_perm_g,
  input  logic         io_req_bits_stage1_entry_6_perm_u,
  input  logic         io_req_bits_stage1_entry_6_perm_x,
  input  logic         io_req_bits_stage1_entry_6_perm_w,
  input  logic         io_req_bits_stage1_entry_6_perm_r,
  input  logic [1:0]   io_req_bits_stage1_entry_6_level,
  input  logic         io_req_bits_stage1_entry_6_v,
  input  logic [40:0]  io_req_bits_stage1_entry_6_ppn,
  input  logic [2:0]   io_req_bits_stage1_entry_6_ppn_low,
  input  logic         io_req_bits_stage1_entry_6_pf,
  input  logic         io_req_bits_stage1_entry_6_cf,
  input  logic [34:0]  io_req_bits_stage1_entry_7_tag,
  input  logic [15:0]  io_req_bits_stage1_entry_7_asid,
  input  logic [13:0]  io_req_bits_stage1_entry_7_vmid,
  input  logic         io_req_bits_stage1_entry_7_n,
  input  logic [1:0]   io_req_bits_stage1_entry_7_pbmt,
  input  logic         io_req_bits_stage1_entry_7_perm_d,
  input  logic         io_req_bits_stage1_entry_7_perm_a,
  input  logic         io_req_bits_stage1_entry_7_perm_g,
  input  logic         io_req_bits_stage1_entry_7_perm_u,
  input  logic         io_req_bits_stage1_entry_7_perm_x,
  input  logic         io_req_bits_stage1_entry_7_perm_w,
  input  logic         io_req_bits_stage1_entry_7_perm_r,
  input  logic [1:0]   io_req_bits_stage1_entry_7_level,
  input  logic         io_req_bits_stage1_entry_7_v,
  input  logic [40:0]  io_req_bits_stage1_entry_7_ppn,
  input  logic [2:0]   io_req_bits_stage1_entry_7_ppn_low,
  input  logic         io_req_bits_stage1_entry_7_pf,
  input  logic         io_req_bits_stage1_entry_7_cf,
  input  logic         io_req_bits_stage1_pteidx_0,
  input  logic         io_req_bits_stage1_pteidx_1,
  input  logic         io_req_bits_stage1_pteidx_2,
  input  logic         io_req_bits_stage1_pteidx_3,
  input  logic         io_req_bits_stage1_pteidx_4,
  input  logic         io_req_bits_stage1_pteidx_5,
  input  logic         io_req_bits_stage1_pteidx_6,
  input  logic         io_req_bits_stage1_pteidx_7,
  input  logic         io_req_bits_stage1_not_super,
  input  logic         io_req_bits_bitmapCheck_jmp_bitmap_check,
  input  logic [63:0]  io_req_bits_bitmapCheck_pte,
  input  logic [1:0]   io_req_bits_bitmapCheck_SPlevel,
  input  logic         io_resp_ready,
  output logic         io_resp_valid,
  output logic [1:0]   io_resp_bits_source,
  output logic [1:0]   io_resp_bits_s2xlate,
  output logic [34:0]  io_resp_bits_resp_entry_0_tag,
  output logic [15:0]  io_resp_bits_resp_entry_0_asid,
  output logic [13:0]  io_resp_bits_resp_entry_0_vmid,
  output logic         io_resp_bits_resp_entry_0_n,
  output logic [1:0]   io_resp_bits_resp_entry_0_pbmt,
  output logic         io_resp_bits_resp_entry_0_perm_d,
  output logic         io_resp_bits_resp_entry_0_perm_a,
  output logic         io_resp_bits_resp_entry_0_perm_g,
  output logic         io_resp_bits_resp_entry_0_perm_u,
  output logic         io_resp_bits_resp_entry_0_perm_x,
  output logic         io_resp_bits_resp_entry_0_perm_w,
  output logic         io_resp_bits_resp_entry_0_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_0_level,
  output logic         io_resp_bits_resp_entry_0_v,
  output logic [40:0]  io_resp_bits_resp_entry_0_ppn,
  output logic [2:0]   io_resp_bits_resp_entry_0_ppn_low,
  output logic         io_resp_bits_resp_entry_0_af,
  output logic         io_resp_bits_resp_entry_0_pf,
  output logic         io_resp_bits_resp_entry_0_cf,
  output logic [34:0]  io_resp_bits_resp_entry_1_tag,
  output logic [15:0]  io_resp_bits_resp_entry_1_asid,
  output logic [13:0]  io_resp_bits_resp_entry_1_vmid,
  output logic         io_resp_bits_resp_entry_1_n,
  output logic [1:0]   io_resp_bits_resp_entry_1_pbmt,
  output logic         io_resp_bits_resp_entry_1_perm_d,
  output logic         io_resp_bits_resp_entry_1_perm_a,
  output logic         io_resp_bits_resp_entry_1_perm_g,
  output logic         io_resp_bits_resp_entry_1_perm_u,
  output logic         io_resp_bits_resp_entry_1_perm_x,
  output logic         io_resp_bits_resp_entry_1_perm_w,
  output logic         io_resp_bits_resp_entry_1_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_1_level,
  output logic         io_resp_bits_resp_entry_1_v,
  output logic [40:0]  io_resp_bits_resp_entry_1_ppn,
  output logic [2:0]   io_resp_bits_resp_entry_1_ppn_low,
  output logic         io_resp_bits_resp_entry_1_af,
  output logic         io_resp_bits_resp_entry_1_pf,
  output logic         io_resp_bits_resp_entry_1_cf,
  output logic [34:0]  io_resp_bits_resp_entry_2_tag,
  output logic [15:0]  io_resp_bits_resp_entry_2_asid,
  output logic [13:0]  io_resp_bits_resp_entry_2_vmid,
  output logic         io_resp_bits_resp_entry_2_n,
  output logic [1:0]   io_resp_bits_resp_entry_2_pbmt,
  output logic         io_resp_bits_resp_entry_2_perm_d,
  output logic         io_resp_bits_resp_entry_2_perm_a,
  output logic         io_resp_bits_resp_entry_2_perm_g,
  output logic         io_resp_bits_resp_entry_2_perm_u,
  output logic         io_resp_bits_resp_entry_2_perm_x,
  output logic         io_resp_bits_resp_entry_2_perm_w,
  output logic         io_resp_bits_resp_entry_2_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_2_level,
  output logic         io_resp_bits_resp_entry_2_v,
  output logic [40:0]  io_resp_bits_resp_entry_2_ppn,
  output logic [2:0]   io_resp_bits_resp_entry_2_ppn_low,
  output logic         io_resp_bits_resp_entry_2_af,
  output logic         io_resp_bits_resp_entry_2_pf,
  output logic         io_resp_bits_resp_entry_2_cf,
  output logic [34:0]  io_resp_bits_resp_entry_3_tag,
  output logic [15:0]  io_resp_bits_resp_entry_3_asid,
  output logic [13:0]  io_resp_bits_resp_entry_3_vmid,
  output logic         io_resp_bits_resp_entry_3_n,
  output logic [1:0]   io_resp_bits_resp_entry_3_pbmt,
  output logic         io_resp_bits_resp_entry_3_perm_d,
  output logic         io_resp_bits_resp_entry_3_perm_a,
  output logic         io_resp_bits_resp_entry_3_perm_g,
  output logic         io_resp_bits_resp_entry_3_perm_u,
  output logic         io_resp_bits_resp_entry_3_perm_x,
  output logic         io_resp_bits_resp_entry_3_perm_w,
  output logic         io_resp_bits_resp_entry_3_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_3_level,
  output logic         io_resp_bits_resp_entry_3_v,
  output logic [40:0]  io_resp_bits_resp_entry_3_ppn,
  output logic [2:0]   io_resp_bits_resp_entry_3_ppn_low,
  output logic         io_resp_bits_resp_entry_3_af,
  output logic         io_resp_bits_resp_entry_3_pf,
  output logic         io_resp_bits_resp_entry_3_cf,
  output logic [34:0]  io_resp_bits_resp_entry_4_tag,
  output logic [15:0]  io_resp_bits_resp_entry_4_asid,
  output logic [13:0]  io_resp_bits_resp_entry_4_vmid,
  output logic         io_resp_bits_resp_entry_4_n,
  output logic [1:0]   io_resp_bits_resp_entry_4_pbmt,
  output logic         io_resp_bits_resp_entry_4_perm_d,
  output logic         io_resp_bits_resp_entry_4_perm_a,
  output logic         io_resp_bits_resp_entry_4_perm_g,
  output logic         io_resp_bits_resp_entry_4_perm_u,
  output logic         io_resp_bits_resp_entry_4_perm_x,
  output logic         io_resp_bits_resp_entry_4_perm_w,
  output logic         io_resp_bits_resp_entry_4_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_4_level,
  output logic         io_resp_bits_resp_entry_4_v,
  output logic [40:0]  io_resp_bits_resp_entry_4_ppn,
  output logic [2:0]   io_resp_bits_resp_entry_4_ppn_low,
  output logic         io_resp_bits_resp_entry_4_af,
  output logic         io_resp_bits_resp_entry_4_pf,
  output logic         io_resp_bits_resp_entry_4_cf,
  output logic [34:0]  io_resp_bits_resp_entry_5_tag,
  output logic [15:0]  io_resp_bits_resp_entry_5_asid,
  output logic [13:0]  io_resp_bits_resp_entry_5_vmid,
  output logic         io_resp_bits_resp_entry_5_n,
  output logic [1:0]   io_resp_bits_resp_entry_5_pbmt,
  output logic         io_resp_bits_resp_entry_5_perm_d,
  output logic         io_resp_bits_resp_entry_5_perm_a,
  output logic         io_resp_bits_resp_entry_5_perm_g,
  output logic         io_resp_bits_resp_entry_5_perm_u,
  output logic         io_resp_bits_resp_entry_5_perm_x,
  output logic         io_resp_bits_resp_entry_5_perm_w,
  output logic         io_resp_bits_resp_entry_5_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_5_level,
  output logic         io_resp_bits_resp_entry_5_v,
  output logic [40:0]  io_resp_bits_resp_entry_5_ppn,
  output logic [2:0]   io_resp_bits_resp_entry_5_ppn_low,
  output logic         io_resp_bits_resp_entry_5_af,
  output logic         io_resp_bits_resp_entry_5_pf,
  output logic         io_resp_bits_resp_entry_5_cf,
  output logic [34:0]  io_resp_bits_resp_entry_6_tag,
  output logic [15:0]  io_resp_bits_resp_entry_6_asid,
  output logic [13:0]  io_resp_bits_resp_entry_6_vmid,
  output logic         io_resp_bits_resp_entry_6_n,
  output logic [1:0]   io_resp_bits_resp_entry_6_pbmt,
  output logic         io_resp_bits_resp_entry_6_perm_d,
  output logic         io_resp_bits_resp_entry_6_perm_a,
  output logic         io_resp_bits_resp_entry_6_perm_g,
  output logic         io_resp_bits_resp_entry_6_perm_u,
  output logic         io_resp_bits_resp_entry_6_perm_x,
  output logic         io_resp_bits_resp_entry_6_perm_w,
  output logic         io_resp_bits_resp_entry_6_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_6_level,
  output logic         io_resp_bits_resp_entry_6_v,
  output logic [40:0]  io_resp_bits_resp_entry_6_ppn,
  output logic [2:0]   io_resp_bits_resp_entry_6_ppn_low,
  output logic         io_resp_bits_resp_entry_6_af,
  output logic         io_resp_bits_resp_entry_6_pf,
  output logic         io_resp_bits_resp_entry_6_cf,
  output logic [34:0]  io_resp_bits_resp_entry_7_tag,
  output logic [15:0]  io_resp_bits_resp_entry_7_asid,
  output logic [13:0]  io_resp_bits_resp_entry_7_vmid,
  output logic         io_resp_bits_resp_entry_7_n,
  output logic [1:0]   io_resp_bits_resp_entry_7_pbmt,
  output logic         io_resp_bits_resp_entry_7_perm_d,
  output logic         io_resp_bits_resp_entry_7_perm_a,
  output logic         io_resp_bits_resp_entry_7_perm_g,
  output logic         io_resp_bits_resp_entry_7_perm_u,
  output logic         io_resp_bits_resp_entry_7_perm_x,
  output logic         io_resp_bits_resp_entry_7_perm_w,
  output logic         io_resp_bits_resp_entry_7_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_7_level,
  output logic         io_resp_bits_resp_entry_7_v,
  output logic [40:0]  io_resp_bits_resp_entry_7_ppn,
  output logic [2:0]   io_resp_bits_resp_entry_7_ppn_low,
  output logic         io_resp_bits_resp_entry_7_af,
  output logic         io_resp_bits_resp_entry_7_pf,
  output logic         io_resp_bits_resp_entry_7_cf,
  output logic         io_resp_bits_resp_pteidx_0,
  output logic         io_resp_bits_resp_pteidx_1,
  output logic         io_resp_bits_resp_pteidx_2,
  output logic         io_resp_bits_resp_pteidx_3,
  output logic         io_resp_bits_resp_pteidx_4,
  output logic         io_resp_bits_resp_pteidx_5,
  output logic         io_resp_bits_resp_pteidx_6,
  output logic         io_resp_bits_resp_pteidx_7,
  output logic         io_resp_bits_resp_not_super,
  output logic [37:0]  io_resp_bits_h_resp_entry_tag,
  output logic [13:0]  io_resp_bits_h_resp_entry_vmid,
  output logic         io_resp_bits_h_resp_entry_n,
  output logic [1:0]   io_resp_bits_h_resp_entry_pbmt,
  output logic [37:0]  io_resp_bits_h_resp_entry_ppn,
  output logic         io_resp_bits_h_resp_entry_perm_d,
  output logic         io_resp_bits_h_resp_entry_perm_a,
  output logic         io_resp_bits_h_resp_entry_perm_g,
  output logic         io_resp_bits_h_resp_entry_perm_u,
  output logic         io_resp_bits_h_resp_entry_perm_x,
  output logic         io_resp_bits_h_resp_entry_perm_w,
  output logic         io_resp_bits_h_resp_entry_perm_r,
  output logic [1:0]   io_resp_bits_h_resp_entry_level,
  output logic         io_resp_bits_h_resp_gpf,
  output logic         io_resp_bits_h_resp_gaf,
  input  logic         io_llptw_ready,
  output logic         io_llptw_valid,
  output logic [37:0]  io_llptw_bits_req_info_vpn,
  output logic [1:0]   io_llptw_bits_req_info_s2xlate,
  output logic [1:0]   io_llptw_bits_req_info_source,
  input  logic         io_hptw_req_ready,
  output logic         io_hptw_req_valid,
  output logic [1:0]   io_hptw_req_bits_source,
  output logic [43:0]  io_hptw_req_bits_gvpn,
  input  logic         io_hptw_resp_valid,
  input  logic [37:0]  io_hptw_resp_bits_h_resp_entry_tag,
  input  logic [13:0]  io_hptw_resp_bits_h_resp_entry_vmid,
  input  logic         io_hptw_resp_bits_h_resp_entry_n,
  input  logic [1:0]   io_hptw_resp_bits_h_resp_entry_pbmt,
  input  logic [37:0]  io_hptw_resp_bits_h_resp_entry_ppn,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_d,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_a,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_g,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_u,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_x,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_w,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_r,
  input  logic [1:0]   io_hptw_resp_bits_h_resp_entry_level,
  input  logic         io_hptw_resp_bits_h_resp_gpf,
  input  logic         io_hptw_resp_bits_h_resp_gaf,
  input  logic         io_mem_req_ready,
  output logic         io_mem_req_valid,
  output logic [47:0]  io_mem_req_bits_addr,
  input  logic         io_mem_resp_valid,
  input  logic [63:0]  io_mem_resp_bits,
  input  logic         io_mem_mask,
  output logic [47:0]  io_pmp_req_bits_addr,
  input  logic         io_pmp_resp_ld,
  input  logic         io_pmp_resp_mmio,
  output logic [37:0]  io_refill_req_info_vpn,
  output logic [1:0]   io_refill_req_info_s2xlate,
  output logic [1:0]   io_refill_req_info_source,
  output logic [1:0]   io_refill_level,
  input  logic         io_bitmap_req_ready,
  output logic         io_bitmap_req_valid,
  output logic [35:0]  io_bitmap_req_bits_bmppn,
  output logic [37:0]  io_bitmap_req_bits_vpn,
  output logic [1:0]   io_bitmap_req_bits_level,
  output logic [1:0]   io_bitmap_req_bits_s2xlate,
  output logic         io_bitmap_req_bits_n,
  output logic         io_bitmap_resp_ready,
  input  logic         io_bitmap_resp_valid,
  input  logic         io_bitmap_resp_bits_cf,
  output logic [5:0]   io_perf_0_value,
  output logic [5:0]   io_perf_1_value,
  output logic [5:0]   io_perf_2_value,
  output logic [5:0]   io_perf_3_value,
  output logic [5:0]   io_perf_4_value,
  output logic [5:0]   io_perf_5_value,
  output logic [5:0]   io_perf_6_value
  // END GENERATED(core_ports)
);

  // ===========================================================================
  // §1 全局控制与 CSR 选择
  // ===========================================================================
  logic [1:0] req_s2xlate;      // 本次请求的两阶段翻译模式（不复位）
  logic       enableS2xlate, onlyS1xlate, onlyS2xlate, s2xlate;
  logic       bitmap_enable;
  logic       flush;
  assign enableS2xlate = (req_s2xlate != NO_S2XLATE);
  assign onlyS1xlate   = (req_s2xlate == ONLY_STAGE1);
  assign onlyS2xlate   = (req_s2xlate == ONLY_STAGE2);
  assign s2xlate       = enableS2xlate & ~onlyS1xlate;   // 需要 HPTW 参与
  assign bitmap_enable = io_csr_mbmc_BME & ~io_csr_mbmc_CMODE;
  assign flush = io_sfence_valid | io_csr_satp_changed | io_csr_vsatp_changed
               | io_csr_hgatp_changed | io_csr_priv_virt_changed;

  // 请求进来那一拍按请求的 s2xlate 选 satp/vsatp（current_*）；之后按锁住的 req_s2xlate 选
  logic        req_in_s2;            // |io_req_bits_req_info_s2xlate
  logic [43:0] current_satp_ppn;
  logic        current_is_sv48;      // golden _GEN_7
  logic [3:0]  satp_mode;
  logic [15:0] satp_asid;
  logic [43:0] satp_ppn;
  logic        s1Pbmte;
  assign req_in_s2        = |io_req_bits_req_info_s2xlate;
  assign current_satp_ppn = req_in_s2 ? io_csr_vsatp_ppn : io_csr_satp_ppn;
  assign current_is_sv48  = (req_in_s2 ? io_csr_vsatp_mode : io_csr_satp_mode) == MODE_SV48;
  assign satp_mode        = enableS2xlate ? io_csr_vsatp_mode : io_csr_satp_mode;
  assign satp_asid        = enableS2xlate ? io_csr_vsatp_asid : io_csr_satp_asid;
  assign satp_ppn         = enableS2xlate ? io_csr_vsatp_ppn  : io_csr_satp_ppn;
  assign s1Pbmte          = enableS2xlate ? io_csr_hPBMTE : io_csr_mPBMTE;

  // ===========================================================================
  // §2 寄存器声明
  // ===========================================================================
  // ---- 异步复位域 ----
  logic [1:0]  level;                     // 当前正在读的页表级（3 = Sv48 根级）
  logic [1:0]  af_level;                  // access fault 回报级 / 选访存地址
  logic [1:0]  gpf_level;                 // guest page fault 回报级
  logic        s_pmp_check, s_mem_req, s_llptw_req, w_mem_resp;
  logic        s_hptw_req, w_hptw_resp;   // 中间级 GPA → HPA
  logic        s_last_hptw_req, w_last_hptw_resp;   // 叶子 GPA → HPA（最后一次）
  logic        mem_addr_update;           // 本级 PTE 已到手，进入判定
  logic        s_bitmap_check, w_bitmap_resp, whether_need_bitmap_check, bitmap_checkfailed;
  logic        idle;
  logic        hptw_pageFault, hptw_accessFault;
  logic        need_last_s2xlate;         // allStage：走完 VS 阶段后还要翻一次叶子 GPA
  logic        first_gvpn_check_fail;     // 入口 GPA 高位越界
  logic        pte_valid;                 // 本次至少真正读回过一个 PTE（或 jmp 带来的）
  logic        accessFault;               // RegEnable(pmp.ld | pmp.mmio, 0, sent_to_pmp)
  logic        update_full_gvpn_mem_resp; // mem.resp 后一拍把 pte.getPPN 写进 full_gvpn_reg
  logic        mem_cycle_watch;           // BoolStopWatch(mem.req.fire, mem.resp.fire)，喂 perf_5
  logic        r;                         // golden 的第二份同样寄存器，无人读，照抄；★名字沿用 golden 的 r★：
                                          //   它没有扇出，FM 配不出签名，只能靠名字配对（改名不用 set_user_match）
  // ---- 不复位域 ----
  logic [43:0] ppn;                       // PtwCache 命中级给的 ppn / satp.ppn
  logic [37:0] vpn;                       // vpn，onlyStage2 时是 gvpn
  logic        l3Hit, l2Hit;
  logic        jmp_bitmap_check_r;
  logic        cache_pte_n;               // 跳转请求锁住的 PTE（★无 rsw★）
  logic [1:0]  cache_pte_pbmt;
  logic [6:0]  cache_pte_reserved;
  logic [7:0]  cache_pte_ppn_high;
  logic [35:0] cache_pte_ppn;
  pte_perm_t   cache_pte_perm;
  logic        stage1Hit;
  s1_entry_t   stage1_entry [SECTOR_N];   // stage1 整条 PtwMergeResp
  logic [SECTOR_N-1:0] stage1_pteidx;
  logic        stage1_not_super;
  logic        hptw_resp_stage2;          // stage1 路径：最后一次 HPTW 已回
  logic [1:0]  source;
  hptw_resp_t  hptw_resp;
  logic [43:0] full_gvpn_reg;
  logic [1:0]  cache_level;
  logic [6:0]  perf_r1, perf_r2;          // 7 个 perf 事件各两拍打拍

  // ===========================================================================
  // §3 当前 PTE / 故障判定
  // ===========================================================================
  pte_t mem_pte, pte;
  assign mem_pte = pte_t'(io_mem_resp_bits);
  always_comb begin
    pte = mem_pte;
    if (jmp_bitmap_check_r) begin
      pte.n        = cache_pte_n;
      pte.pbmt     = cache_pte_pbmt;
      pte.reserved = cache_pte_reserved;
      pte.ppn_high = cache_pte_ppn_high;
      pte.ppn      = cache_pte_ppn;
      pte.perm     = cache_pte_perm;
    end
  end

  logic pte_isAf;     // ppn 越界；bitmap 使能时 bitmap 检查失败也算
  logic ppn_af;       // 两阶段翻译里第一阶段的 ppn 是 GPA，不查越界（onlyStage1 除外）
  logic pageFault;
  logic find_pte;
  logic to_find_pte;  // level==1 且没找到叶子 → 交 LLPTW
  assign pte_isAf   = bitmap_enable ? (pte_is_af(pte) | bitmap_checkfailed) : pte_is_af(pte);
  assign ppn_af     = (~enableS2xlate | onlyS1xlate) & pte_isAf;
  assign pageFault  = pte_is_pf(pte, level, s1Pbmte);
  assign find_pte   = pte_is_leaf(pte) | ppn_af | pageFault;
  assign to_find_pte = (level == 2'd1) & ~find_pte;

  // 第一阶段结果的完整 ppn（44 位 = {ppn_high, ppn}）
  logic [43:0] full_gvpn_wire, full_gvpn;
  assign full_gvpn_wire = {pte.ppn_high, pte.ppn};
  assign full_gvpn      = update_full_gvpn_mem_resp ? full_gvpn_wire : full_gvpn_reg;

  // GPA 高位越界（走表中途）：hgatp 模式允许的 GPA 位宽之外非 0
  logic gvpn_gpf, guestFault;
  assign gvpn_gpf = (~(hptw_pageFault | hptw_accessFault | ((pageFault | ppn_af) & pte_valid))
                     & ((s2xlate & (io_csr_hgatp_mode == MODE_SV39)) ? (|full_gvpn[43:29])
                        : (s2xlate & (io_csr_hgatp_mode == MODE_SV48) & (|full_gvpn[43:38]))))
                  | first_gvpn_check_fail;
  assign guestFault = hptw_pageFault | hptw_accessFault | gvpn_gpf;

  // ===========================================================================
  // §4 地址生成
  // ===========================================================================
  logic [52:0] l3addr_pn, l2addr_pn, l1addr_pn, hptw_addr_pn;   // {页表基址 44, vpn 片 9}，<<3 才是字节地址
  logic [47:0] mem_addr;
  assign l3addr_pn = {satp_ppn, vpn[35:27]};
  assign l2addr_pn = (satp_mode == MODE_SV48) ? {l3Hit ? ppn : full_gvpn_wire, vpn[26:18]}
                                              : {satp_ppn, vpn[26:18]};
  assign l1addr_pn = {l2Hit ? ppn : full_gvpn_wire, vpn[17:9]};
  assign hptw_addr_pn = (af_level == 2'd3) ? l3addr_pn : (af_level == 2'd2) ? l2addr_pn : l1addr_pn;
  assign mem_addr  = {hptw_addr_pn[44:0], 3'h0};

  // 要交给 HPTW 翻译的客户机物理地址（56 位）：
  //   stage1Hit / onlyStage2：叶子 GPA = full_gvpn << 12
  //   最后一次翻译（~s_last_hptw_req）：按 level 把 pte.ppn 高位与 vpn 低位拼成叶子 GPA
  //   否则：下一级页表的 GPA（hptw_addr）
  logic [35:0] leaf_gpn_by_level;
  logic [55:0] gpaddr;
  assign leaf_gpn_by_level = (level == 2'd3) ? {pte.ppn[35:27], vpn[26:0]}
                           : (level == 2'd2) ? {pte.ppn[35:18], vpn[17:0]}
                           : (level == 2'd1) ? {pte.ppn[35:9],  vpn[8:0]}
                           :                   pte.ppn;
  assign gpaddr = (stage1Hit | onlyS2xlate) ? {full_gvpn, 12'h0}
                : s_last_hptw_req           ? {hptw_addr_pn, 3'h0}
                :                             {pte.ppn_high, leaf_gpn_by_level, 12'h0};

  // HPTW 翻译结果拼出的主机物理地址：hptw_resp.genPPNS2(gpaddr 的页号) + 页内偏移
  logic [37:0] hpa_pn;
  logic [47:0] hpaddr;
  assign hpa_pn = (hptw_resp.entry_level == 2'd3) ? {hptw_resp.entry_ppn[37:27], gpaddr[38:12]}
                : (hptw_resp.entry_level == 2'd2) ? {hptw_resp.entry_ppn[37:18], gpaddr[29:12]}
                : (hptw_resp.entry_level == 2'd1) ? {hptw_resp.entry_ppn[37:9],  gpaddr[20:12]}
                : hptw_resp.entry_n               ? {hptw_resp.entry_ppn[37:4],  gpaddr[15:12]}
                :                                   hptw_resp.entry_ppn;
  assign hpaddr = {hpa_pn[35:0], gpaddr[11:0]};

  logic [47:0] paddr_out;    // 送 PMP 与访存的物理地址
  assign paddr_out = s2xlate ? hpaddr : mem_addr;

  // ===========================================================================
  // §5 事件与握手（注明 golden 的 _GEN_ 编号）
  // ===========================================================================
  logic req_fire;            // idle & io_req_valid（perfEvents_0_2_probe）
  logic jmp_bitmap_check_w;  // 跳转请求（onlyStage2 不认）
  logic req_jmp;             // _GEN_2
  logic req_stage1;          // _GEN_3
  logic req_walk;            // _GEN_6
  logic io_resp_valid_0, resp_fire;                 // _GEN_5
  logic io_llptw_valid_0, llptw_fire;               // _GEN_50
  logic io_hptw_req_valid_0, hptw_req_fire;         // _GEN_35
  logic hptw_first_fire, hptw_last_fire;            // _GEN_36 / _GEN_39
  logic hptw_resp_take;                             // _GEN_12：中间级 HPTW 响应
  logic hptw_last_take, hptw_last_take_s1, hptw_last_take_walk;   // _GEN_13/14/15
  logic g_perm_fail, hptw_resp_fault;               // _GEN_37
  logic io_mem_req_valid_0, mem_req_fire;           // perfEvents_4_2_probe
  logic mem_resp_take;                              // _GEN_44
  logic need_bitmap_now;                            // _GEN_45
  logic bitmap_req_fire, bitmap_resp_fire;          // _GEN_47 / _GEN_48
  logic af_active, gf_active;                       // _GEN_41 / _GEN_42
  logic step_down_cond;                             // _GEN_17：level>=2 且非叶子无故障
  logic vs_finish, finish, sent_to_pmp;
  logic walk_s2_need_last;                          // _GEN_19：s2xlate & need_last_s2xlate
  logic any_fault;                                  // _GEN_52

  assign req_fire           = idle & io_req_valid;
  assign jmp_bitmap_check_w = io_req_bits_bitmapCheck_jmp_bitmap_check
                            & (io_req_bits_req_info_s2xlate != ONLY_STAGE2);
  assign req_jmp    = req_fire & jmp_bitmap_check_w;
  assign req_stage1 = req_fire & io_req_bits_stage1Hit & ~jmp_bitmap_check_w;
  assign req_walk   = req_fire & ~io_req_bits_stage1Hit & ~jmp_bitmap_check_w;

  assign io_resp_valid_0 = ~idle
      & (stage1Hit ? hptw_resp_stage2
                   : (mem_addr_update & ~need_last_s2xlate
                      & (guestFault | (w_mem_resp & find_pte) | (s_pmp_check & accessFault) | onlyS2xlate)));
  assign resp_fire = io_resp_ready & io_resp_valid_0;
  assign io_llptw_valid_0 = ~s_llptw_req & to_find_pte & ~accessFault & ~guestFault;
  assign llptw_fire = io_llptw_ready & io_llptw_valid_0;
  assign io_hptw_req_valid_0 = ~s_hptw_req | ~s_last_hptw_req;
  assign hptw_req_fire   = io_hptw_req_ready & io_hptw_req_valid_0;
  assign hptw_first_fire = hptw_req_fire & ~s_hptw_req;
  assign hptw_last_fire  = hptw_req_fire & ~s_last_hptw_req;
  assign hptw_resp_take  = io_hptw_resp_valid & ~w_hptw_resp;
  assign hptw_last_take  = io_hptw_resp_valid & ~w_last_hptw_resp;
  assign hptw_last_take_s1   = hptw_last_take & stage1Hit;
  assign hptw_last_take_walk = hptw_last_take & ~stage1Hit;
  // G 阶段中间级页表必须可读：不可读按 gpf 处理
  assign g_perm_fail     = ~io_hptw_resp_bits_h_resp_gaf & ~io_hptw_resp_bits_h_resp_entry_perm_r;
  assign hptw_resp_fault = g_perm_fail | io_hptw_resp_bits_h_resp_gpf | io_hptw_resp_bits_h_resp_gaf;
  assign io_mem_req_valid_0 = ~s_mem_req & ~io_mem_mask & ~accessFault & s_pmp_check;
  assign mem_req_fire     = io_mem_req_ready & io_mem_req_valid_0;
  assign mem_resp_take    = io_mem_resp_valid & ~w_mem_resp;
  assign need_bitmap_now  = bitmap_enable & (~enableS2xlate | onlyS1xlate) & pte_is_leaf(pte) & ~pageFault;
  assign bitmap_req_fire  = io_bitmap_req_ready & ~s_bitmap_check;
  assign bitmap_resp_fire = ~w_bitmap_resp & io_bitmap_resp_valid;
  assign af_active = accessFault & ~idle;
  assign gf_active = guestFault & ~idle;
  assign step_down_cond = level[1] & ~onlyS2xlate & ~(guestFault | find_pte | accessFault);
  assign vs_finish = mem_addr_update & step_down_cond & s2xlate;
  assign walk_s2_need_last = s2xlate & need_last_s2xlate;
  assign finish = mem_addr_update & ~step_down_cond
                & (io_llptw_valid_0 | (~walk_s2_need_last & io_resp_valid_0));
  assign any_fault = guestFault | accessFault | pageFault | ppn_af;
  assign sent_to_pmp = ~idle & (~s_pmp_check | mem_addr_update) & ~finish & ~vs_finish
                     & ~first_gvpn_check_fail & ~(find_pte & pte_valid);

  // 入口：普通走表的起始级与基址
  logic        req_hit_l3;            // _GEN_8：Sv48 下才承认 l3Hit
  logic        req_hit_upper;         // _GEN_9：l3 或 l2 已命中
  logic [1:0]  entry_level;           // _GEN_32
  logic [1:0]  entry_gpf_level;
  logic [43:0] gvpn_wire;             // 入口根级页表的 GPA 页号
  logic        check_gpa_high_fail_only_s2;   // onlyStage2：vpn 就是 GPA，Sv39x4 下只剩 41 位
  logic        check_gpa_high_fail_all;       // allStage：根页表 GPA 越界
  assign req_hit_l3    = current_is_sv48 & io_req_bits_l3Hit;
  assign req_hit_upper = req_hit_l3 | io_req_bits_l2Hit;
  assign entry_level   = io_req_bits_l2Hit ? 2'd1 : current_is_sv48 ? {1'b1, ~io_req_bits_l3Hit} : 2'd2;
  assign entry_gpf_level = current_is_sv48 ? (io_req_bits_l2Hit ? 2'd2 : {2{io_req_bits_l3Hit}})
                                           : {io_req_bits_l2Hit, 1'b0};
  assign gvpn_wire = req_hit_upper ? io_req_bits_ppn : current_satp_ppn;
  assign check_gpa_high_fail_only_s2 = (io_req_bits_req_info_s2xlate == ONLY_STAGE2)
                                     & (io_csr_hgatp_mode == MODE_SV39) & (|io_req_bits_req_info_vpn[37:29]);
  assign check_gpa_high_fail_all = (io_csr_hgatp_mode == MODE_SV39) ? (|gvpn_wire[43:29])
                                 : (io_csr_hgatp_mode == MODE_SV48) & (|gvpn_wire[43:38]);

  // ===========================================================================
  // §6 状态机（异步复位域）—— 按 Chisel 的 when 顺序转写，后写者赢
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      level <= 2'd3; af_level <= 2'd3; gpf_level <= 2'd3;
      s_pmp_check <= 1'b1; s_mem_req <= 1'b1; s_llptw_req <= 1'b1; w_mem_resp <= 1'b1;
      s_hptw_req <= 1'b1; w_hptw_resp <= 1'b1; s_last_hptw_req <= 1'b1; w_last_hptw_resp <= 1'b1;
      mem_addr_update <= 1'b0;
      s_bitmap_check <= 1'b1; w_bitmap_resp <= 1'b1;
      whether_need_bitmap_check <= 1'b0; bitmap_checkfailed <= 1'b0;
      idle <= 1'b1;
      hptw_pageFault <= 1'b0; hptw_accessFault <= 1'b0;
      need_last_s2xlate <= 1'b0; first_gvpn_check_fail <= 1'b0;
      pte_valid <= 1'b0; accessFault <= 1'b0; update_full_gvpn_mem_resp <= 1'b0;
      mem_cycle_watch <= 1'b0; r <= 1'b0;
    end else begin
      // accessFault 的基值：RegEnable(pmp.ld | pmp.mmio, sent_to_pmp)
      if (sent_to_pmp) accessFault <= io_pmp_resp_ld | io_pmp_resp_mmio;

      // ---- 入口 A：bitmap 跳转 ----
      if (req_jmp) begin
        idle <= 1'b0; s_bitmap_check <= 1'b0; need_last_s2xlate <= 1'b0;
        hptw_pageFault <= 1'b0; hptw_accessFault <= 1'b0;
        level <= io_req_bits_bitmapCheck_SPlevel;
        pte_valid <= 1'b1; accessFault <= 1'b0;
      end
      // ---- 入口 B：stage1 命中，只欠最后一次 HPTW ----
      if (req_stage1) begin
        idle <= 1'b0; s_last_hptw_req <= 1'b0; need_last_s2xlate <= 1'b0;
        hptw_pageFault <= 1'b0; hptw_accessFault <= 1'b0;
      end
      // ---- 入口 D：普通走表 ----
      if (req_walk) begin
        level <= entry_level; af_level <= entry_level; gpf_level <= entry_gpf_level;
        accessFault <= 1'b0; idle <= 1'b0;
        hptw_pageFault <= 1'b0; hptw_accessFault <= 1'b0; pte_valid <= 1'b0;
        if (io_req_bits_req_info_s2xlate == ONLY_STAGE2) begin
          need_last_s2xlate <= 1'b0;
          if (check_gpa_high_fail_only_s2) begin
            mem_addr_update <= 1'b1; first_gvpn_check_fail <= 1'b1;
          end else begin
            s_last_hptw_req <= 1'b0;
          end
        end else if (io_req_bits_req_info_s2xlate == ALL_STAGE) begin
          if (check_gpa_high_fail_all) begin
            mem_addr_update <= 1'b1; first_gvpn_check_fail <= 1'b1;
          end else begin
            need_last_s2xlate <= 1'b1; s_hptw_req <= 1'b0;
          end
        end else begin
          need_last_s2xlate <= 1'b0; s_pmp_check <= 1'b0;
        end
      end
      // ---- 中间级 HPTW 往返 ----
      if (hptw_first_fire) begin s_hptw_req <= 1'b1; w_hptw_resp <= 1'b0; end
      if (hptw_resp_take) begin
        w_hptw_resp <= 1'b1;
        hptw_pageFault   <= io_hptw_resp_bits_h_resp_gpf | g_perm_fail;
        hptw_accessFault <= io_hptw_resp_bits_h_resp_gaf;
        if (~hptw_resp_fault) s_pmp_check <= 1'b0;
        else begin mem_addr_update <= 1'b1; need_last_s2xlate <= 1'b0; end
      end
      // ---- 最后一次 HPTW 往返 ----
      if (hptw_last_fire) begin w_last_hptw_resp <= 1'b0; s_last_hptw_req <= 1'b1; end
      if (hptw_last_take_s1) begin w_last_hptw_resp <= 1'b1; end
      if (hptw_last_take_walk) begin
        hptw_pageFault <= io_hptw_resp_bits_h_resp_gpf; hptw_accessFault <= io_hptw_resp_bits_h_resp_gaf;
        w_last_hptw_resp <= 1'b1; mem_addr_update <= 1'b1;
      end
      // ---- PMP → 访存 ----
      if (sent_to_pmp & ~mem_addr_update) begin s_mem_req <= 1'b0; s_pmp_check <= 1'b1; end
      // ---- access fault / guest fault：一切在飞的步骤作废，直接进入判定 ----
      if (af_active | gf_active) begin
        s_pmp_check <= 1'b1; s_mem_req <= 1'b1; w_mem_resp <= 1'b1; s_llptw_req <= 1'b1;
        s_hptw_req <= 1'b1; w_hptw_resp <= 1'b1; s_last_hptw_req <= 1'b1; w_last_hptw_resp <= 1'b1;
        mem_addr_update <= 1'b1; need_last_s2xlate <= 1'b0;
        s_bitmap_check <= 1'b1; w_bitmap_resp <= 1'b1;
        whether_need_bitmap_check <= 1'b0; bitmap_checkfailed <= 1'b0;
      end
      if (mem_req_fire) begin s_mem_req <= 1'b1; w_mem_resp <= 1'b0; end
      if (mem_resp_take) begin
        w_mem_resp <= 1'b1;
        af_level  <= 2'(af_level - 2'd1);
        // Sv39 且本次第一次读回、又不是从 l2 命中起步 → gpf_level 一次减 2（跳过不存在的 l3 级）
        gpf_level <= ((satp_mode == MODE_SV39) & ~pte_valid & ~l2Hit) ? 2'(gpf_level - 2'd2) : 2'(gpf_level - 2'd1);
        pte_valid <= 1'b1; update_full_gvpn_mem_resp <= 1'b1;
        if (bitmap_enable) begin
          whether_need_bitmap_check <= 1'b1;
        end else begin
          s_llptw_req <= 1'b0; mem_addr_update <= 1'b1; whether_need_bitmap_check <= 1'b0;
        end
      end
      if (update_full_gvpn_mem_resp) update_full_gvpn_mem_resp <= 1'b0;
      // ---- bitmap 检查 ----
      if (whether_need_bitmap_check) begin
        if (need_bitmap_now) begin
          s_bitmap_check <= 1'b0; whether_need_bitmap_check <= 1'b0;
        end else begin
          mem_addr_update <= 1'b1; s_llptw_req <= 1'b0; whether_need_bitmap_check <= 1'b0;
        end
      end
      if (bitmap_req_fire)  begin s_bitmap_check <= 1'b1; w_bitmap_resp <= 1'b0; end
      if (bitmap_resp_fire) begin w_bitmap_resp <= 1'b1; mem_addr_update <= 1'b1; bitmap_checkfailed <= io_bitmap_resp_bits_cf; end
      // ---- 判定 ----
      if (mem_addr_update) begin
        if (step_down_cond) begin
          level <= 2'(level - 2'd1);
          if (s2xlate) s_hptw_req <= 1'b0; else s_mem_req <= 1'b0;
          s_llptw_req <= 1'b1; mem_addr_update <= 1'b0;
        end else if (io_llptw_valid_0) begin
          if (llptw_fire) begin
            idle <= 1'b1; s_llptw_req <= 1'b1; mem_addr_update <= 1'b0; need_last_s2xlate <= 1'b0;
          end
        end else if (walk_s2_need_last) begin
          need_last_s2xlate <= 1'b0;
          if (~any_fault) begin s_last_hptw_req <= 1'b0; mem_addr_update <= 1'b0; end
        end else if (io_resp_valid_0) begin
          if (resp_fire) begin
            idle <= 1'b1; s_llptw_req <= 1'b1; mem_addr_update <= 1'b0;
            accessFault <= 1'b0; first_gvpn_check_fail <= 1'b0; bitmap_checkfailed <= 1'b0;
          end
        end
      end
      // stage1 路径的回应（Chisel 里这条 when 写在入口 D 之前，但它只置 idle，
      // 而 D 与它互斥——resp.fire 要求 ~idle，D 要求 idle——顺序不影响结果）
      if (resp_fire & stage1Hit) idle <= 1'b1;
      // ---- flush ----
      if (flush) begin
        idle <= 1'b1; s_pmp_check <= 1'b1; s_mem_req <= 1'b1; s_llptw_req <= 1'b1; w_mem_resp <= 1'b1;
        accessFault <= 1'b0; mem_addr_update <= 1'b0; first_gvpn_check_fail <= 1'b0;
        s_hptw_req <= 1'b1; w_hptw_resp <= 1'b1; s_last_hptw_req <= 1'b1; w_last_hptw_resp <= 1'b1;
        s_bitmap_check <= 1'b1; w_bitmap_resp <= 1'b1;
        whether_need_bitmap_check <= 1'b0; bitmap_checkfailed <= 1'b0;
      end
      // ---- perf：mem.req.fire 起、mem.resp 止的秒表（golden 有两份同样的）----
      mem_cycle_watch       <= mem_req_fire | (~io_mem_resp_valid & mem_cycle_watch);
      r                     <= mem_req_fire | (~io_mem_resp_valid & r);
    end
  end

  // ===========================================================================
  // §7 载荷寄存器（不复位域）
  // ===========================================================================
  // stage1 输入打包成表项数组（8 条同形）
  s1_entry_t stage1_in [SECTOR_N];
  always_comb begin
    stage1_in[0] = '{tag: io_req_bits_stage1_entry_0_tag, asid: io_req_bits_stage1_entry_0_asid, vmid: io_req_bits_stage1_entry_0_vmid,
                     n: io_req_bits_stage1_entry_0_n, pbmt: io_req_bits_stage1_entry_0_pbmt,
                     perm: '{d: io_req_bits_stage1_entry_0_perm_d, a: io_req_bits_stage1_entry_0_perm_a, g: io_req_bits_stage1_entry_0_perm_g,
                             u: io_req_bits_stage1_entry_0_perm_u, x: io_req_bits_stage1_entry_0_perm_x, w: io_req_bits_stage1_entry_0_perm_w, r: io_req_bits_stage1_entry_0_perm_r},
                     level: io_req_bits_stage1_entry_0_level, v: io_req_bits_stage1_entry_0_v, ppn: io_req_bits_stage1_entry_0_ppn,
                     ppn_low: io_req_bits_stage1_entry_0_ppn_low, pf: io_req_bits_stage1_entry_0_pf, cf: io_req_bits_stage1_entry_0_cf};
    stage1_in[1] = '{tag: io_req_bits_stage1_entry_1_tag, asid: io_req_bits_stage1_entry_1_asid, vmid: io_req_bits_stage1_entry_1_vmid,
                     n: io_req_bits_stage1_entry_1_n, pbmt: io_req_bits_stage1_entry_1_pbmt,
                     perm: '{d: io_req_bits_stage1_entry_1_perm_d, a: io_req_bits_stage1_entry_1_perm_a, g: io_req_bits_stage1_entry_1_perm_g,
                             u: io_req_bits_stage1_entry_1_perm_u, x: io_req_bits_stage1_entry_1_perm_x, w: io_req_bits_stage1_entry_1_perm_w, r: io_req_bits_stage1_entry_1_perm_r},
                     level: io_req_bits_stage1_entry_1_level, v: io_req_bits_stage1_entry_1_v, ppn: io_req_bits_stage1_entry_1_ppn,
                     ppn_low: io_req_bits_stage1_entry_1_ppn_low, pf: io_req_bits_stage1_entry_1_pf, cf: io_req_bits_stage1_entry_1_cf};
    stage1_in[2] = '{tag: io_req_bits_stage1_entry_2_tag, asid: io_req_bits_stage1_entry_2_asid, vmid: io_req_bits_stage1_entry_2_vmid,
                     n: io_req_bits_stage1_entry_2_n, pbmt: io_req_bits_stage1_entry_2_pbmt,
                     perm: '{d: io_req_bits_stage1_entry_2_perm_d, a: io_req_bits_stage1_entry_2_perm_a, g: io_req_bits_stage1_entry_2_perm_g,
                             u: io_req_bits_stage1_entry_2_perm_u, x: io_req_bits_stage1_entry_2_perm_x, w: io_req_bits_stage1_entry_2_perm_w, r: io_req_bits_stage1_entry_2_perm_r},
                     level: io_req_bits_stage1_entry_2_level, v: io_req_bits_stage1_entry_2_v, ppn: io_req_bits_stage1_entry_2_ppn,
                     ppn_low: io_req_bits_stage1_entry_2_ppn_low, pf: io_req_bits_stage1_entry_2_pf, cf: io_req_bits_stage1_entry_2_cf};
    stage1_in[3] = '{tag: io_req_bits_stage1_entry_3_tag, asid: io_req_bits_stage1_entry_3_asid, vmid: io_req_bits_stage1_entry_3_vmid,
                     n: io_req_bits_stage1_entry_3_n, pbmt: io_req_bits_stage1_entry_3_pbmt,
                     perm: '{d: io_req_bits_stage1_entry_3_perm_d, a: io_req_bits_stage1_entry_3_perm_a, g: io_req_bits_stage1_entry_3_perm_g,
                             u: io_req_bits_stage1_entry_3_perm_u, x: io_req_bits_stage1_entry_3_perm_x, w: io_req_bits_stage1_entry_3_perm_w, r: io_req_bits_stage1_entry_3_perm_r},
                     level: io_req_bits_stage1_entry_3_level, v: io_req_bits_stage1_entry_3_v, ppn: io_req_bits_stage1_entry_3_ppn,
                     ppn_low: io_req_bits_stage1_entry_3_ppn_low, pf: io_req_bits_stage1_entry_3_pf, cf: io_req_bits_stage1_entry_3_cf};
    stage1_in[4] = '{tag: io_req_bits_stage1_entry_4_tag, asid: io_req_bits_stage1_entry_4_asid, vmid: io_req_bits_stage1_entry_4_vmid,
                     n: io_req_bits_stage1_entry_4_n, pbmt: io_req_bits_stage1_entry_4_pbmt,
                     perm: '{d: io_req_bits_stage1_entry_4_perm_d, a: io_req_bits_stage1_entry_4_perm_a, g: io_req_bits_stage1_entry_4_perm_g,
                             u: io_req_bits_stage1_entry_4_perm_u, x: io_req_bits_stage1_entry_4_perm_x, w: io_req_bits_stage1_entry_4_perm_w, r: io_req_bits_stage1_entry_4_perm_r},
                     level: io_req_bits_stage1_entry_4_level, v: io_req_bits_stage1_entry_4_v, ppn: io_req_bits_stage1_entry_4_ppn,
                     ppn_low: io_req_bits_stage1_entry_4_ppn_low, pf: io_req_bits_stage1_entry_4_pf, cf: io_req_bits_stage1_entry_4_cf};
    stage1_in[5] = '{tag: io_req_bits_stage1_entry_5_tag, asid: io_req_bits_stage1_entry_5_asid, vmid: io_req_bits_stage1_entry_5_vmid,
                     n: io_req_bits_stage1_entry_5_n, pbmt: io_req_bits_stage1_entry_5_pbmt,
                     perm: '{d: io_req_bits_stage1_entry_5_perm_d, a: io_req_bits_stage1_entry_5_perm_a, g: io_req_bits_stage1_entry_5_perm_g,
                             u: io_req_bits_stage1_entry_5_perm_u, x: io_req_bits_stage1_entry_5_perm_x, w: io_req_bits_stage1_entry_5_perm_w, r: io_req_bits_stage1_entry_5_perm_r},
                     level: io_req_bits_stage1_entry_5_level, v: io_req_bits_stage1_entry_5_v, ppn: io_req_bits_stage1_entry_5_ppn,
                     ppn_low: io_req_bits_stage1_entry_5_ppn_low, pf: io_req_bits_stage1_entry_5_pf, cf: io_req_bits_stage1_entry_5_cf};
    stage1_in[6] = '{tag: io_req_bits_stage1_entry_6_tag, asid: io_req_bits_stage1_entry_6_asid, vmid: io_req_bits_stage1_entry_6_vmid,
                     n: io_req_bits_stage1_entry_6_n, pbmt: io_req_bits_stage1_entry_6_pbmt,
                     perm: '{d: io_req_bits_stage1_entry_6_perm_d, a: io_req_bits_stage1_entry_6_perm_a, g: io_req_bits_stage1_entry_6_perm_g,
                             u: io_req_bits_stage1_entry_6_perm_u, x: io_req_bits_stage1_entry_6_perm_x, w: io_req_bits_stage1_entry_6_perm_w, r: io_req_bits_stage1_entry_6_perm_r},
                     level: io_req_bits_stage1_entry_6_level, v: io_req_bits_stage1_entry_6_v, ppn: io_req_bits_stage1_entry_6_ppn,
                     ppn_low: io_req_bits_stage1_entry_6_ppn_low, pf: io_req_bits_stage1_entry_6_pf, cf: io_req_bits_stage1_entry_6_cf};
    stage1_in[7] = '{tag: io_req_bits_stage1_entry_7_tag, asid: io_req_bits_stage1_entry_7_asid, vmid: io_req_bits_stage1_entry_7_vmid,
                     n: io_req_bits_stage1_entry_7_n, pbmt: io_req_bits_stage1_entry_7_pbmt,
                     perm: '{d: io_req_bits_stage1_entry_7_perm_d, a: io_req_bits_stage1_entry_7_perm_a, g: io_req_bits_stage1_entry_7_perm_g,
                             u: io_req_bits_stage1_entry_7_perm_u, x: io_req_bits_stage1_entry_7_perm_x, w: io_req_bits_stage1_entry_7_perm_w, r: io_req_bits_stage1_entry_7_perm_r},
                     level: io_req_bits_stage1_entry_7_level, v: io_req_bits_stage1_entry_7_v, ppn: io_req_bits_stage1_entry_7_ppn,
                     ppn_low: io_req_bits_stage1_entry_7_ppn_low, pf: io_req_bits_stage1_entry_7_pf, cf: io_req_bits_stage1_entry_7_cf};
  end

  // stage1.genPPN()：按 pteidx 选出那条表项，按它的 level 把 ppn 高位与 tag 低位拼成完整 ppn
  logic [SECTOR_N-1:0] s1_pteidx_in;
  logic [2:0]          s1_idx;          // OHToUInt(pteidx)
  s1_entry_t           s1_sel;
  logic [37:0]         s1_sel_tag;      // {entry.tag, idx}
  logic [43:0]         stage1_gen_ppn;
  assign s1_pteidx_in = {io_req_bits_stage1_pteidx_7, io_req_bits_stage1_pteidx_6, io_req_bits_stage1_pteidx_5, io_req_bits_stage1_pteidx_4,
                         io_req_bits_stage1_pteidx_3, io_req_bits_stage1_pteidx_2, io_req_bits_stage1_pteidx_1, io_req_bits_stage1_pteidx_0};
  assign s1_idx = {|s1_pteidx_in[7:4],
                   s1_pteidx_in[7] | s1_pteidx_in[6] | s1_pteidx_in[3] | s1_pteidx_in[2],
                   s1_pteidx_in[7] | s1_pteidx_in[5] | s1_pteidx_in[3] | s1_pteidx_in[1]};
  assign s1_sel     = stage1_in[s1_idx];
  assign s1_sel_tag = {s1_sel.tag, s1_idx};
  assign stage1_gen_ppn = (s1_sel.level == 2'd0) ? (s1_sel.n ? {s1_sel.ppn[40:1], s1_sel_tag[3:0]}
                                                             : {s1_sel.ppn, s1_sel.ppn_low})
                        : (s1_sel.level == 2'd1) ? {s1_sel.ppn[40:6],  s1_sel_tag[8:0]}
                        : (s1_sel.level == 2'd2) ? {s1_sel.ppn[40:15], s1_sel_tag[17:0]}
                        :                          {s1_sel.ppn[40:24], s1_sel_tag[26:0]};

  hptw_resp_t hptw_resp_in;
  assign hptw_resp_in = '{entry_tag: io_hptw_resp_bits_h_resp_entry_tag, entry_vmid: io_hptw_resp_bits_h_resp_entry_vmid,
                          entry_n: io_hptw_resp_bits_h_resp_entry_n, entry_pbmt: io_hptw_resp_bits_h_resp_entry_pbmt,
                          entry_ppn: io_hptw_resp_bits_h_resp_entry_ppn,
                          entry_perm: '{d: io_hptw_resp_bits_h_resp_entry_perm_d, a: io_hptw_resp_bits_h_resp_entry_perm_a,
                                        g: io_hptw_resp_bits_h_resp_entry_perm_g, u: io_hptw_resp_bits_h_resp_entry_perm_u,
                                        x: io_hptw_resp_bits_h_resp_entry_perm_x, w: io_hptw_resp_bits_h_resp_entry_perm_w,
                                        r: io_hptw_resp_bits_h_resp_entry_perm_r},
                          entry_level: io_hptw_resp_bits_h_resp_entry_level,
                          gpf: io_hptw_resp_bits_h_resp_gpf, gaf: io_hptw_resp_bits_h_resp_gaf};

  always_ff @(posedge clock) begin
    // 请求进来那一拍锁住的东西
    if (req_fire) begin
      jmp_bitmap_check_r <= jmp_bitmap_check_w;
      cache_pte_n        <= io_req_bits_bitmapCheck_pte[63];
      cache_pte_pbmt     <= io_req_bits_bitmapCheck_pte[62:61];
      cache_pte_reserved <= io_req_bits_bitmapCheck_pte[60:54];
      cache_pte_ppn_high <= io_req_bits_bitmapCheck_pte[53:46];
      cache_pte_ppn      <= io_req_bits_bitmapCheck_pte[45:10];
      cache_pte_perm     <= pte_perm_t'(io_req_bits_bitmapCheck_pte[7:0]);
      stage1Hit          <= io_req_bits_stage1Hit;
      for (int i = 0; i < SECTOR_N; i++) stage1_entry[i] <= stage1_in[i];
      stage1_pteidx      <= s1_pteidx_in;
      stage1_not_super   <= io_req_bits_stage1_not_super;
      source             <= io_req_bits_req_info_source;
      cache_level        <= io_req_bits_bitmapCheck_SPlevel;
    end
    if (req_jmp | req_stage1 | req_walk) req_s2xlate <= io_req_bits_req_info_s2xlate;
    if (req_jmp | req_walk)              vpn <= io_req_bits_req_info_vpn;
    if (req_walk) begin
      ppn   <= req_hit_upper ? io_req_bits_ppn : current_satp_ppn;
      l3Hit <= req_hit_l3;
      l2Hit <= io_req_bits_l2Hit;
    end
    // stage1 路径：最后一次 HPTW 回来 → 可以回应；新的 stage1 请求清掉
    hptw_resp_stage2 <= hptw_last_take_s1 | (~req_stage1 & hptw_resp_stage2);
    // HPTW 响应锁存（中间级 / 最后一次 walk / 最后一次 stage1 三处都写）；
    // 中间级把"不可读"也算作 gpf，最后一次原样锁
    if (hptw_last_take_walk | hptw_last_take_s1 | hptw_resp_take) hptw_resp <= hptw_resp_in;
    if (hptw_last_take)      hptw_resp.gpf <= io_hptw_resp_bits_h_resp_gpf;
    else if (hptw_resp_take) hptw_resp.gpf <= io_hptw_resp_bits_h_resp_gpf | g_perm_fail;
    // full_gvpn_reg：mem.resp 后一拍取 pte 的完整 ppn；入口按三种请求各取各的
    if (update_full_gvpn_mem_resp) full_gvpn_reg <= full_gvpn_wire;
    else if (req_walk)   full_gvpn_reg <= (io_req_bits_req_info_s2xlate == ONLY_STAGE2) ? {6'h0, io_req_bits_req_info_vpn} : 44'h0;
    else if (req_stage1) full_gvpn_reg <= stage1_gen_ppn;
    // perf 两拍打拍
    perf_r1 <= {io_mem_req_valid_0 & ~io_mem_req_ready, mem_cycle_watch, mem_req_fire,
                io_resp_valid_0 & ~io_resp_ready, idle, ~idle, req_fire};
    perf_r2 <= perf_r1;
  end

  // ===========================================================================
  // §8 响应装配
  // ===========================================================================
  // 没真正访过存时用 fake_pte：v=0 告诉 L1 TLB 这是假 PTE，ppn 取请求带来的 ppn
  logic        resp_pf, resp_af;
  logic [1:0]  resp_level;
  logic        use_stage1;          // 用 stage1 那条回应（golden _io_resp_bits_resp_T_4）
  s1_entry_t   ptw_resp_entry;      // 走表结果装成的一条表项（8 条相同）
  assign resp_pf    = pte_valid & pageFault;
  assign resp_af    = (accessFault | ppn_af) & ~(resp_pf | guestFault);
  assign resp_level = (accessFault & resp_af) ? af_level : guestFault ? gpf_level : level;
  assign use_stage1 = stage1Hit | ((l3Hit | l2Hit) & guestFault & ~pte_valid);
  always_comb begin
    ptw_resp_entry.tag     = vpn[37:3];
    ptw_resp_entry.asid    = satp_asid;
    ptw_resp_entry.vmid    = io_csr_hgatp_vmid[13:0];
    ptw_resp_entry.pbmt    = pte_valid ? pte.pbmt : 2'h0;
    ptw_resp_entry.perm.d  = pte_valid & pte.perm.d;
    ptw_resp_entry.perm.a  = pte_valid & pte.perm.a;
    ptw_resp_entry.perm.g  = pte_valid & pte.perm.g;
    ptw_resp_entry.perm.u  = pte_valid & pte.perm.u;
    ptw_resp_entry.perm.x  = pte_valid & pte.perm.x;
    ptw_resp_entry.perm.w  = pte_valid & pte.perm.w;
    ptw_resp_entry.perm.r  = pte_valid & pte.perm.r;
    ptw_resp_entry.level   = resp_level;
    ptw_resp_entry.v       = pte_valid & pte.perm.v;
    ptw_resp_entry.ppn     = pte_valid ? {pte.ppn_high, pte.ppn[35:3]} : {ppn[43:36], ppn[35:3]};
    ptw_resp_entry.ppn_low = pte_valid ? pte.ppn[2:0] : ppn[2:0];
    ptw_resp_entry.n       = pte_valid & pte.n & ((pte_valid ? pte.ppn[3:0] : ppn[3:0]) == 4'd8) & (resp_level == 2'd0);
    ptw_resp_entry.pf      = resp_pf;
    ptw_resp_entry.cf      = bitmap_checkfailed;
  end

  // 8 条输出表项：用 stage1 时逐条取 stage1_entry[i]，否则 8 条都是 ptw_resp_entry
  s1_entry_t resp_entry [SECTOR_N];
  logic      resp_entry_af;
  logic [SECTOR_N-1:0] resp_pteidx;
  always_comb begin
    for (int i = 0; i < SECTOR_N; i++) begin
      resp_entry[i]  = use_stage1 ? stage1_entry[i] : ptw_resp_entry;
      resp_pteidx[i] = use_stage1 ? stage1_pteidx[i] : (vpn[2:0] == 3'(i));
    end
  end
  assign resp_entry_af = ~use_stage1 & resp_af;   // stage1 那条没有 af 字段（父级喂的恒 0 被消了端口）

  // ===========================================================================
  // §9 输出
  // ===========================================================================
  assign io_req_ready       = idle;
  assign io_resp_valid      = io_resp_valid_0;
  assign io_resp_bits_source  = source;
  assign io_resp_bits_s2xlate = req_s2xlate;
  // 8 条同形，逐条从 resp_entry[i] 取
  assign io_resp_bits_resp_entry_0_tag = resp_entry[0].tag;  assign io_resp_bits_resp_entry_0_asid = resp_entry[0].asid;  assign io_resp_bits_resp_entry_0_vmid = resp_entry[0].vmid;
  assign io_resp_bits_resp_entry_0_n = resp_entry[0].n;  assign io_resp_bits_resp_entry_0_pbmt = resp_entry[0].pbmt;
  assign io_resp_bits_resp_entry_0_perm_d = resp_entry[0].perm.d;  assign io_resp_bits_resp_entry_0_perm_a = resp_entry[0].perm.a;  assign io_resp_bits_resp_entry_0_perm_g = resp_entry[0].perm.g;
  assign io_resp_bits_resp_entry_0_perm_u = resp_entry[0].perm.u;  assign io_resp_bits_resp_entry_0_perm_x = resp_entry[0].perm.x;  assign io_resp_bits_resp_entry_0_perm_w = resp_entry[0].perm.w;  assign io_resp_bits_resp_entry_0_perm_r = resp_entry[0].perm.r;
  assign io_resp_bits_resp_entry_0_level = resp_entry[0].level;  assign io_resp_bits_resp_entry_0_v = resp_entry[0].v;  assign io_resp_bits_resp_entry_0_ppn = resp_entry[0].ppn;
  assign io_resp_bits_resp_entry_0_ppn_low = resp_entry[0].ppn_low;  assign io_resp_bits_resp_entry_0_af = resp_entry_af;  assign io_resp_bits_resp_entry_0_pf = resp_entry[0].pf;  assign io_resp_bits_resp_entry_0_cf = resp_entry[0].cf;
  assign io_resp_bits_resp_entry_1_tag = resp_entry[1].tag;  assign io_resp_bits_resp_entry_1_asid = resp_entry[1].asid;  assign io_resp_bits_resp_entry_1_vmid = resp_entry[1].vmid;
  assign io_resp_bits_resp_entry_1_n = resp_entry[1].n;  assign io_resp_bits_resp_entry_1_pbmt = resp_entry[1].pbmt;
  assign io_resp_bits_resp_entry_1_perm_d = resp_entry[1].perm.d;  assign io_resp_bits_resp_entry_1_perm_a = resp_entry[1].perm.a;  assign io_resp_bits_resp_entry_1_perm_g = resp_entry[1].perm.g;
  assign io_resp_bits_resp_entry_1_perm_u = resp_entry[1].perm.u;  assign io_resp_bits_resp_entry_1_perm_x = resp_entry[1].perm.x;  assign io_resp_bits_resp_entry_1_perm_w = resp_entry[1].perm.w;  assign io_resp_bits_resp_entry_1_perm_r = resp_entry[1].perm.r;
  assign io_resp_bits_resp_entry_1_level = resp_entry[1].level;  assign io_resp_bits_resp_entry_1_v = resp_entry[1].v;  assign io_resp_bits_resp_entry_1_ppn = resp_entry[1].ppn;
  assign io_resp_bits_resp_entry_1_ppn_low = resp_entry[1].ppn_low;  assign io_resp_bits_resp_entry_1_af = resp_entry_af;  assign io_resp_bits_resp_entry_1_pf = resp_entry[1].pf;  assign io_resp_bits_resp_entry_1_cf = resp_entry[1].cf;
  assign io_resp_bits_resp_entry_2_tag = resp_entry[2].tag;  assign io_resp_bits_resp_entry_2_asid = resp_entry[2].asid;  assign io_resp_bits_resp_entry_2_vmid = resp_entry[2].vmid;
  assign io_resp_bits_resp_entry_2_n = resp_entry[2].n;  assign io_resp_bits_resp_entry_2_pbmt = resp_entry[2].pbmt;
  assign io_resp_bits_resp_entry_2_perm_d = resp_entry[2].perm.d;  assign io_resp_bits_resp_entry_2_perm_a = resp_entry[2].perm.a;  assign io_resp_bits_resp_entry_2_perm_g = resp_entry[2].perm.g;
  assign io_resp_bits_resp_entry_2_perm_u = resp_entry[2].perm.u;  assign io_resp_bits_resp_entry_2_perm_x = resp_entry[2].perm.x;  assign io_resp_bits_resp_entry_2_perm_w = resp_entry[2].perm.w;  assign io_resp_bits_resp_entry_2_perm_r = resp_entry[2].perm.r;
  assign io_resp_bits_resp_entry_2_level = resp_entry[2].level;  assign io_resp_bits_resp_entry_2_v = resp_entry[2].v;  assign io_resp_bits_resp_entry_2_ppn = resp_entry[2].ppn;
  assign io_resp_bits_resp_entry_2_ppn_low = resp_entry[2].ppn_low;  assign io_resp_bits_resp_entry_2_af = resp_entry_af;  assign io_resp_bits_resp_entry_2_pf = resp_entry[2].pf;  assign io_resp_bits_resp_entry_2_cf = resp_entry[2].cf;
  assign io_resp_bits_resp_entry_3_tag = resp_entry[3].tag;  assign io_resp_bits_resp_entry_3_asid = resp_entry[3].asid;  assign io_resp_bits_resp_entry_3_vmid = resp_entry[3].vmid;
  assign io_resp_bits_resp_entry_3_n = resp_entry[3].n;  assign io_resp_bits_resp_entry_3_pbmt = resp_entry[3].pbmt;
  assign io_resp_bits_resp_entry_3_perm_d = resp_entry[3].perm.d;  assign io_resp_bits_resp_entry_3_perm_a = resp_entry[3].perm.a;  assign io_resp_bits_resp_entry_3_perm_g = resp_entry[3].perm.g;
  assign io_resp_bits_resp_entry_3_perm_u = resp_entry[3].perm.u;  assign io_resp_bits_resp_entry_3_perm_x = resp_entry[3].perm.x;  assign io_resp_bits_resp_entry_3_perm_w = resp_entry[3].perm.w;  assign io_resp_bits_resp_entry_3_perm_r = resp_entry[3].perm.r;
  assign io_resp_bits_resp_entry_3_level = resp_entry[3].level;  assign io_resp_bits_resp_entry_3_v = resp_entry[3].v;  assign io_resp_bits_resp_entry_3_ppn = resp_entry[3].ppn;
  assign io_resp_bits_resp_entry_3_ppn_low = resp_entry[3].ppn_low;  assign io_resp_bits_resp_entry_3_af = resp_entry_af;  assign io_resp_bits_resp_entry_3_pf = resp_entry[3].pf;  assign io_resp_bits_resp_entry_3_cf = resp_entry[3].cf;
  assign io_resp_bits_resp_entry_4_tag = resp_entry[4].tag;  assign io_resp_bits_resp_entry_4_asid = resp_entry[4].asid;  assign io_resp_bits_resp_entry_4_vmid = resp_entry[4].vmid;
  assign io_resp_bits_resp_entry_4_n = resp_entry[4].n;  assign io_resp_bits_resp_entry_4_pbmt = resp_entry[4].pbmt;
  assign io_resp_bits_resp_entry_4_perm_d = resp_entry[4].perm.d;  assign io_resp_bits_resp_entry_4_perm_a = resp_entry[4].perm.a;  assign io_resp_bits_resp_entry_4_perm_g = resp_entry[4].perm.g;
  assign io_resp_bits_resp_entry_4_perm_u = resp_entry[4].perm.u;  assign io_resp_bits_resp_entry_4_perm_x = resp_entry[4].perm.x;  assign io_resp_bits_resp_entry_4_perm_w = resp_entry[4].perm.w;  assign io_resp_bits_resp_entry_4_perm_r = resp_entry[4].perm.r;
  assign io_resp_bits_resp_entry_4_level = resp_entry[4].level;  assign io_resp_bits_resp_entry_4_v = resp_entry[4].v;  assign io_resp_bits_resp_entry_4_ppn = resp_entry[4].ppn;
  assign io_resp_bits_resp_entry_4_ppn_low = resp_entry[4].ppn_low;  assign io_resp_bits_resp_entry_4_af = resp_entry_af;  assign io_resp_bits_resp_entry_4_pf = resp_entry[4].pf;  assign io_resp_bits_resp_entry_4_cf = resp_entry[4].cf;
  assign io_resp_bits_resp_entry_5_tag = resp_entry[5].tag;  assign io_resp_bits_resp_entry_5_asid = resp_entry[5].asid;  assign io_resp_bits_resp_entry_5_vmid = resp_entry[5].vmid;
  assign io_resp_bits_resp_entry_5_n = resp_entry[5].n;  assign io_resp_bits_resp_entry_5_pbmt = resp_entry[5].pbmt;
  assign io_resp_bits_resp_entry_5_perm_d = resp_entry[5].perm.d;  assign io_resp_bits_resp_entry_5_perm_a = resp_entry[5].perm.a;  assign io_resp_bits_resp_entry_5_perm_g = resp_entry[5].perm.g;
  assign io_resp_bits_resp_entry_5_perm_u = resp_entry[5].perm.u;  assign io_resp_bits_resp_entry_5_perm_x = resp_entry[5].perm.x;  assign io_resp_bits_resp_entry_5_perm_w = resp_entry[5].perm.w;  assign io_resp_bits_resp_entry_5_perm_r = resp_entry[5].perm.r;
  assign io_resp_bits_resp_entry_5_level = resp_entry[5].level;  assign io_resp_bits_resp_entry_5_v = resp_entry[5].v;  assign io_resp_bits_resp_entry_5_ppn = resp_entry[5].ppn;
  assign io_resp_bits_resp_entry_5_ppn_low = resp_entry[5].ppn_low;  assign io_resp_bits_resp_entry_5_af = resp_entry_af;  assign io_resp_bits_resp_entry_5_pf = resp_entry[5].pf;  assign io_resp_bits_resp_entry_5_cf = resp_entry[5].cf;
  assign io_resp_bits_resp_entry_6_tag = resp_entry[6].tag;  assign io_resp_bits_resp_entry_6_asid = resp_entry[6].asid;  assign io_resp_bits_resp_entry_6_vmid = resp_entry[6].vmid;
  assign io_resp_bits_resp_entry_6_n = resp_entry[6].n;  assign io_resp_bits_resp_entry_6_pbmt = resp_entry[6].pbmt;
  assign io_resp_bits_resp_entry_6_perm_d = resp_entry[6].perm.d;  assign io_resp_bits_resp_entry_6_perm_a = resp_entry[6].perm.a;  assign io_resp_bits_resp_entry_6_perm_g = resp_entry[6].perm.g;
  assign io_resp_bits_resp_entry_6_perm_u = resp_entry[6].perm.u;  assign io_resp_bits_resp_entry_6_perm_x = resp_entry[6].perm.x;  assign io_resp_bits_resp_entry_6_perm_w = resp_entry[6].perm.w;  assign io_resp_bits_resp_entry_6_perm_r = resp_entry[6].perm.r;
  assign io_resp_bits_resp_entry_6_level = resp_entry[6].level;  assign io_resp_bits_resp_entry_6_v = resp_entry[6].v;  assign io_resp_bits_resp_entry_6_ppn = resp_entry[6].ppn;
  assign io_resp_bits_resp_entry_6_ppn_low = resp_entry[6].ppn_low;  assign io_resp_bits_resp_entry_6_af = resp_entry_af;  assign io_resp_bits_resp_entry_6_pf = resp_entry[6].pf;  assign io_resp_bits_resp_entry_6_cf = resp_entry[6].cf;
  assign io_resp_bits_resp_entry_7_tag = resp_entry[7].tag;  assign io_resp_bits_resp_entry_7_asid = resp_entry[7].asid;  assign io_resp_bits_resp_entry_7_vmid = resp_entry[7].vmid;
  assign io_resp_bits_resp_entry_7_n = resp_entry[7].n;  assign io_resp_bits_resp_entry_7_pbmt = resp_entry[7].pbmt;
  assign io_resp_bits_resp_entry_7_perm_d = resp_entry[7].perm.d;  assign io_resp_bits_resp_entry_7_perm_a = resp_entry[7].perm.a;  assign io_resp_bits_resp_entry_7_perm_g = resp_entry[7].perm.g;
  assign io_resp_bits_resp_entry_7_perm_u = resp_entry[7].perm.u;  assign io_resp_bits_resp_entry_7_perm_x = resp_entry[7].perm.x;  assign io_resp_bits_resp_entry_7_perm_w = resp_entry[7].perm.w;  assign io_resp_bits_resp_entry_7_perm_r = resp_entry[7].perm.r;
  assign io_resp_bits_resp_entry_7_level = resp_entry[7].level;  assign io_resp_bits_resp_entry_7_v = resp_entry[7].v;  assign io_resp_bits_resp_entry_7_ppn = resp_entry[7].ppn;
  assign io_resp_bits_resp_entry_7_ppn_low = resp_entry[7].ppn_low;  assign io_resp_bits_resp_entry_7_af = resp_entry_af;  assign io_resp_bits_resp_entry_7_pf = resp_entry[7].pf;  assign io_resp_bits_resp_entry_7_cf = resp_entry[7].cf;
  assign io_resp_bits_resp_pteidx_0 = resp_pteidx[0];  assign io_resp_bits_resp_pteidx_1 = resp_pteidx[1];
  assign io_resp_bits_resp_pteidx_2 = resp_pteidx[2];  assign io_resp_bits_resp_pteidx_3 = resp_pteidx[3];
  assign io_resp_bits_resp_pteidx_4 = resp_pteidx[4];  assign io_resp_bits_resp_pteidx_5 = resp_pteidx[5];
  assign io_resp_bits_resp_pteidx_6 = resp_pteidx[6];  assign io_resp_bits_resp_pteidx_7 = resp_pteidx[7];
  assign io_resp_bits_resp_not_super = use_stage1 & stage1_not_super;

  // h_resp：GPA 高位越界时给一条 fake_h_resp（tag=gpaddr 页号，vmid=hgatp.vmid，gpf=1，其余 0）
  assign io_resp_bits_h_resp_entry_tag    = gvpn_gpf ? gpaddr[49:12] : hptw_resp.entry_tag;
  assign io_resp_bits_h_resp_entry_vmid   = gvpn_gpf ? io_csr_hgatp_vmid[13:0] : hptw_resp.entry_vmid;
  assign io_resp_bits_h_resp_entry_n      = ~gvpn_gpf & hptw_resp.entry_n;
  assign io_resp_bits_h_resp_entry_pbmt   = gvpn_gpf ? 2'h0 : hptw_resp.entry_pbmt;
  assign io_resp_bits_h_resp_entry_ppn    = gvpn_gpf ? 38'h0 : hptw_resp.entry_ppn;
  assign io_resp_bits_h_resp_entry_perm_d = ~gvpn_gpf & hptw_resp.entry_perm.d;
  assign io_resp_bits_h_resp_entry_perm_a = ~gvpn_gpf & hptw_resp.entry_perm.a;
  assign io_resp_bits_h_resp_entry_perm_g = ~gvpn_gpf & hptw_resp.entry_perm.g;
  assign io_resp_bits_h_resp_entry_perm_u = ~gvpn_gpf & hptw_resp.entry_perm.u;
  assign io_resp_bits_h_resp_entry_perm_x = ~gvpn_gpf & hptw_resp.entry_perm.x;
  assign io_resp_bits_h_resp_entry_perm_w = ~gvpn_gpf & hptw_resp.entry_perm.w;
  assign io_resp_bits_h_resp_entry_perm_r = ~gvpn_gpf & hptw_resp.entry_perm.r;
  assign io_resp_bits_h_resp_entry_level  = gvpn_gpf ? 2'h0 : hptw_resp.entry_level;
  assign io_resp_bits_h_resp_gpf          = gvpn_gpf | hptw_resp.gpf;
  assign io_resp_bits_h_resp_gaf          = ~gvpn_gpf & hptw_resp.gaf;

  assign io_llptw_valid                 = io_llptw_valid_0;
  assign io_llptw_bits_req_info_vpn     = vpn;
  assign io_llptw_bits_req_info_s2xlate = req_s2xlate;
  assign io_llptw_bits_req_info_source  = source;

  assign io_hptw_req_valid       = io_hptw_req_valid_0;
  assign io_hptw_req_bits_source = source;
  assign io_hptw_req_bits_gvpn   = gpaddr[55:12];

  assign io_mem_req_valid     = io_mem_req_valid_0;
  assign io_mem_req_bits_addr = paddr_out;
  assign io_pmp_req_bits_addr = paddr_out;

  assign io_refill_req_info_vpn     = vpn;
  assign io_refill_req_info_s2xlate = req_s2xlate;
  assign io_refill_req_info_source  = source;
  assign io_refill_level            = level;

  assign io_bitmap_req_valid        = ~s_bitmap_check;
  assign io_bitmap_req_bits_bmppn   = pte.ppn;
  assign io_bitmap_req_bits_vpn     = vpn;
  assign io_bitmap_req_bits_level   = jmp_bitmap_check_r ? cache_level : level;
  assign io_bitmap_req_bits_s2xlate = req_s2xlate;
  assign io_bitmap_req_bits_n       = pte.n;
  assign io_bitmap_resp_ready       = ~w_bitmap_resp;

  // ===========================================================================
  // §10 perf：fsm_count / fsm_busy / fsm_idle / resp_blocked / mem_count / mem_cycle / mem_blocked
  // ===========================================================================
  assign io_perf_0_value = {5'h0, perf_r2[0]};
  assign io_perf_1_value = {5'h0, perf_r2[1]};
  assign io_perf_2_value = {5'h0, perf_r2[2]};
  assign io_perf_3_value = {5'h0, perf_r2[3]};
  assign io_perf_4_value = {5'h0, perf_r2[4]};
  assign io_perf_5_value = {5'h0, perf_r2[5]};
  assign io_perf_6_value = {5'h0, perf_r2[6]};

endmodule

// BEGIN GENERATED(wrapper) —— 由 gen_mmu5.py 生成：PTW 的 golden 同名 wrapper，
// 端口与 G1 golden 逐位同名，纯透传到 xs_PTW_core（无任何逻辑）。
module PTW(
  input  logic         clock,
  input  logic         reset,
  input  logic         io_sfence_valid,
  input  logic [3:0]   io_csr_satp_mode,
  input  logic [15:0]  io_csr_satp_asid,
  input  logic [43:0]  io_csr_satp_ppn,
  input  logic         io_csr_satp_changed,
  input  logic [3:0]   io_csr_vsatp_mode,
  input  logic [15:0]  io_csr_vsatp_asid,
  input  logic [43:0]  io_csr_vsatp_ppn,
  input  logic         io_csr_vsatp_changed,
  input  logic [3:0]   io_csr_hgatp_mode,
  input  logic [15:0]  io_csr_hgatp_vmid,
  input  logic         io_csr_hgatp_changed,
  input  logic         io_csr_mbmc_BME,
  input  logic         io_csr_mbmc_CMODE,
  input  logic         io_csr_priv_virt_changed,
  input  logic         io_csr_mPBMTE,
  input  logic         io_csr_hPBMTE,
  output logic         io_req_ready,
  input  logic         io_req_valid,
  input  logic [37:0]  io_req_bits_req_info_vpn,
  input  logic [1:0]   io_req_bits_req_info_s2xlate,
  input  logic [1:0]   io_req_bits_req_info_source,
  input  logic         io_req_bits_l3Hit,
  input  logic         io_req_bits_l2Hit,
  input  logic [43:0]  io_req_bits_ppn,
  input  logic         io_req_bits_stage1Hit,
  input  logic [34:0]  io_req_bits_stage1_entry_0_tag,
  input  logic [15:0]  io_req_bits_stage1_entry_0_asid,
  input  logic [13:0]  io_req_bits_stage1_entry_0_vmid,
  input  logic         io_req_bits_stage1_entry_0_n,
  input  logic [1:0]   io_req_bits_stage1_entry_0_pbmt,
  input  logic         io_req_bits_stage1_entry_0_perm_d,
  input  logic         io_req_bits_stage1_entry_0_perm_a,
  input  logic         io_req_bits_stage1_entry_0_perm_g,
  input  logic         io_req_bits_stage1_entry_0_perm_u,
  input  logic         io_req_bits_stage1_entry_0_perm_x,
  input  logic         io_req_bits_stage1_entry_0_perm_w,
  input  logic         io_req_bits_stage1_entry_0_perm_r,
  input  logic [1:0]   io_req_bits_stage1_entry_0_level,
  input  logic         io_req_bits_stage1_entry_0_v,
  input  logic [40:0]  io_req_bits_stage1_entry_0_ppn,
  input  logic [2:0]   io_req_bits_stage1_entry_0_ppn_low,
  input  logic         io_req_bits_stage1_entry_0_pf,
  input  logic         io_req_bits_stage1_entry_0_cf,
  input  logic [34:0]  io_req_bits_stage1_entry_1_tag,
  input  logic [15:0]  io_req_bits_stage1_entry_1_asid,
  input  logic [13:0]  io_req_bits_stage1_entry_1_vmid,
  input  logic         io_req_bits_stage1_entry_1_n,
  input  logic [1:0]   io_req_bits_stage1_entry_1_pbmt,
  input  logic         io_req_bits_stage1_entry_1_perm_d,
  input  logic         io_req_bits_stage1_entry_1_perm_a,
  input  logic         io_req_bits_stage1_entry_1_perm_g,
  input  logic         io_req_bits_stage1_entry_1_perm_u,
  input  logic         io_req_bits_stage1_entry_1_perm_x,
  input  logic         io_req_bits_stage1_entry_1_perm_w,
  input  logic         io_req_bits_stage1_entry_1_perm_r,
  input  logic [1:0]   io_req_bits_stage1_entry_1_level,
  input  logic         io_req_bits_stage1_entry_1_v,
  input  logic [40:0]  io_req_bits_stage1_entry_1_ppn,
  input  logic [2:0]   io_req_bits_stage1_entry_1_ppn_low,
  input  logic         io_req_bits_stage1_entry_1_pf,
  input  logic         io_req_bits_stage1_entry_1_cf,
  input  logic [34:0]  io_req_bits_stage1_entry_2_tag,
  input  logic [15:0]  io_req_bits_stage1_entry_2_asid,
  input  logic [13:0]  io_req_bits_stage1_entry_2_vmid,
  input  logic         io_req_bits_stage1_entry_2_n,
  input  logic [1:0]   io_req_bits_stage1_entry_2_pbmt,
  input  logic         io_req_bits_stage1_entry_2_perm_d,
  input  logic         io_req_bits_stage1_entry_2_perm_a,
  input  logic         io_req_bits_stage1_entry_2_perm_g,
  input  logic         io_req_bits_stage1_entry_2_perm_u,
  input  logic         io_req_bits_stage1_entry_2_perm_x,
  input  logic         io_req_bits_stage1_entry_2_perm_w,
  input  logic         io_req_bits_stage1_entry_2_perm_r,
  input  logic [1:0]   io_req_bits_stage1_entry_2_level,
  input  logic         io_req_bits_stage1_entry_2_v,
  input  logic [40:0]  io_req_bits_stage1_entry_2_ppn,
  input  logic [2:0]   io_req_bits_stage1_entry_2_ppn_low,
  input  logic         io_req_bits_stage1_entry_2_pf,
  input  logic         io_req_bits_stage1_entry_2_cf,
  input  logic [34:0]  io_req_bits_stage1_entry_3_tag,
  input  logic [15:0]  io_req_bits_stage1_entry_3_asid,
  input  logic [13:0]  io_req_bits_stage1_entry_3_vmid,
  input  logic         io_req_bits_stage1_entry_3_n,
  input  logic [1:0]   io_req_bits_stage1_entry_3_pbmt,
  input  logic         io_req_bits_stage1_entry_3_perm_d,
  input  logic         io_req_bits_stage1_entry_3_perm_a,
  input  logic         io_req_bits_stage1_entry_3_perm_g,
  input  logic         io_req_bits_stage1_entry_3_perm_u,
  input  logic         io_req_bits_stage1_entry_3_perm_x,
  input  logic         io_req_bits_stage1_entry_3_perm_w,
  input  logic         io_req_bits_stage1_entry_3_perm_r,
  input  logic [1:0]   io_req_bits_stage1_entry_3_level,
  input  logic         io_req_bits_stage1_entry_3_v,
  input  logic [40:0]  io_req_bits_stage1_entry_3_ppn,
  input  logic [2:0]   io_req_bits_stage1_entry_3_ppn_low,
  input  logic         io_req_bits_stage1_entry_3_pf,
  input  logic         io_req_bits_stage1_entry_3_cf,
  input  logic [34:0]  io_req_bits_stage1_entry_4_tag,
  input  logic [15:0]  io_req_bits_stage1_entry_4_asid,
  input  logic [13:0]  io_req_bits_stage1_entry_4_vmid,
  input  logic         io_req_bits_stage1_entry_4_n,
  input  logic [1:0]   io_req_bits_stage1_entry_4_pbmt,
  input  logic         io_req_bits_stage1_entry_4_perm_d,
  input  logic         io_req_bits_stage1_entry_4_perm_a,
  input  logic         io_req_bits_stage1_entry_4_perm_g,
  input  logic         io_req_bits_stage1_entry_4_perm_u,
  input  logic         io_req_bits_stage1_entry_4_perm_x,
  input  logic         io_req_bits_stage1_entry_4_perm_w,
  input  logic         io_req_bits_stage1_entry_4_perm_r,
  input  logic [1:0]   io_req_bits_stage1_entry_4_level,
  input  logic         io_req_bits_stage1_entry_4_v,
  input  logic [40:0]  io_req_bits_stage1_entry_4_ppn,
  input  logic [2:0]   io_req_bits_stage1_entry_4_ppn_low,
  input  logic         io_req_bits_stage1_entry_4_pf,
  input  logic         io_req_bits_stage1_entry_4_cf,
  input  logic [34:0]  io_req_bits_stage1_entry_5_tag,
  input  logic [15:0]  io_req_bits_stage1_entry_5_asid,
  input  logic [13:0]  io_req_bits_stage1_entry_5_vmid,
  input  logic         io_req_bits_stage1_entry_5_n,
  input  logic [1:0]   io_req_bits_stage1_entry_5_pbmt,
  input  logic         io_req_bits_stage1_entry_5_perm_d,
  input  logic         io_req_bits_stage1_entry_5_perm_a,
  input  logic         io_req_bits_stage1_entry_5_perm_g,
  input  logic         io_req_bits_stage1_entry_5_perm_u,
  input  logic         io_req_bits_stage1_entry_5_perm_x,
  input  logic         io_req_bits_stage1_entry_5_perm_w,
  input  logic         io_req_bits_stage1_entry_5_perm_r,
  input  logic [1:0]   io_req_bits_stage1_entry_5_level,
  input  logic         io_req_bits_stage1_entry_5_v,
  input  logic [40:0]  io_req_bits_stage1_entry_5_ppn,
  input  logic [2:0]   io_req_bits_stage1_entry_5_ppn_low,
  input  logic         io_req_bits_stage1_entry_5_pf,
  input  logic         io_req_bits_stage1_entry_5_cf,
  input  logic [34:0]  io_req_bits_stage1_entry_6_tag,
  input  logic [15:0]  io_req_bits_stage1_entry_6_asid,
  input  logic [13:0]  io_req_bits_stage1_entry_6_vmid,
  input  logic         io_req_bits_stage1_entry_6_n,
  input  logic [1:0]   io_req_bits_stage1_entry_6_pbmt,
  input  logic         io_req_bits_stage1_entry_6_perm_d,
  input  logic         io_req_bits_stage1_entry_6_perm_a,
  input  logic         io_req_bits_stage1_entry_6_perm_g,
  input  logic         io_req_bits_stage1_entry_6_perm_u,
  input  logic         io_req_bits_stage1_entry_6_perm_x,
  input  logic         io_req_bits_stage1_entry_6_perm_w,
  input  logic         io_req_bits_stage1_entry_6_perm_r,
  input  logic [1:0]   io_req_bits_stage1_entry_6_level,
  input  logic         io_req_bits_stage1_entry_6_v,
  input  logic [40:0]  io_req_bits_stage1_entry_6_ppn,
  input  logic [2:0]   io_req_bits_stage1_entry_6_ppn_low,
  input  logic         io_req_bits_stage1_entry_6_pf,
  input  logic         io_req_bits_stage1_entry_6_cf,
  input  logic [34:0]  io_req_bits_stage1_entry_7_tag,
  input  logic [15:0]  io_req_bits_stage1_entry_7_asid,
  input  logic [13:0]  io_req_bits_stage1_entry_7_vmid,
  input  logic         io_req_bits_stage1_entry_7_n,
  input  logic [1:0]   io_req_bits_stage1_entry_7_pbmt,
  input  logic         io_req_bits_stage1_entry_7_perm_d,
  input  logic         io_req_bits_stage1_entry_7_perm_a,
  input  logic         io_req_bits_stage1_entry_7_perm_g,
  input  logic         io_req_bits_stage1_entry_7_perm_u,
  input  logic         io_req_bits_stage1_entry_7_perm_x,
  input  logic         io_req_bits_stage1_entry_7_perm_w,
  input  logic         io_req_bits_stage1_entry_7_perm_r,
  input  logic [1:0]   io_req_bits_stage1_entry_7_level,
  input  logic         io_req_bits_stage1_entry_7_v,
  input  logic [40:0]  io_req_bits_stage1_entry_7_ppn,
  input  logic [2:0]   io_req_bits_stage1_entry_7_ppn_low,
  input  logic         io_req_bits_stage1_entry_7_pf,
  input  logic         io_req_bits_stage1_entry_7_cf,
  input  logic         io_req_bits_stage1_pteidx_0,
  input  logic         io_req_bits_stage1_pteidx_1,
  input  logic         io_req_bits_stage1_pteidx_2,
  input  logic         io_req_bits_stage1_pteidx_3,
  input  logic         io_req_bits_stage1_pteidx_4,
  input  logic         io_req_bits_stage1_pteidx_5,
  input  logic         io_req_bits_stage1_pteidx_6,
  input  logic         io_req_bits_stage1_pteidx_7,
  input  logic         io_req_bits_stage1_not_super,
  input  logic         io_req_bits_bitmapCheck_jmp_bitmap_check,
  input  logic [63:0]  io_req_bits_bitmapCheck_pte,
  input  logic [1:0]   io_req_bits_bitmapCheck_SPlevel,
  input  logic         io_resp_ready,
  output logic         io_resp_valid,
  output logic [1:0]   io_resp_bits_source,
  output logic [1:0]   io_resp_bits_s2xlate,
  output logic [34:0]  io_resp_bits_resp_entry_0_tag,
  output logic [15:0]  io_resp_bits_resp_entry_0_asid,
  output logic [13:0]  io_resp_bits_resp_entry_0_vmid,
  output logic         io_resp_bits_resp_entry_0_n,
  output logic [1:0]   io_resp_bits_resp_entry_0_pbmt,
  output logic         io_resp_bits_resp_entry_0_perm_d,
  output logic         io_resp_bits_resp_entry_0_perm_a,
  output logic         io_resp_bits_resp_entry_0_perm_g,
  output logic         io_resp_bits_resp_entry_0_perm_u,
  output logic         io_resp_bits_resp_entry_0_perm_x,
  output logic         io_resp_bits_resp_entry_0_perm_w,
  output logic         io_resp_bits_resp_entry_0_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_0_level,
  output logic         io_resp_bits_resp_entry_0_v,
  output logic [40:0]  io_resp_bits_resp_entry_0_ppn,
  output logic [2:0]   io_resp_bits_resp_entry_0_ppn_low,
  output logic         io_resp_bits_resp_entry_0_af,
  output logic         io_resp_bits_resp_entry_0_pf,
  output logic         io_resp_bits_resp_entry_0_cf,
  output logic [34:0]  io_resp_bits_resp_entry_1_tag,
  output logic [15:0]  io_resp_bits_resp_entry_1_asid,
  output logic [13:0]  io_resp_bits_resp_entry_1_vmid,
  output logic         io_resp_bits_resp_entry_1_n,
  output logic [1:0]   io_resp_bits_resp_entry_1_pbmt,
  output logic         io_resp_bits_resp_entry_1_perm_d,
  output logic         io_resp_bits_resp_entry_1_perm_a,
  output logic         io_resp_bits_resp_entry_1_perm_g,
  output logic         io_resp_bits_resp_entry_1_perm_u,
  output logic         io_resp_bits_resp_entry_1_perm_x,
  output logic         io_resp_bits_resp_entry_1_perm_w,
  output logic         io_resp_bits_resp_entry_1_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_1_level,
  output logic         io_resp_bits_resp_entry_1_v,
  output logic [40:0]  io_resp_bits_resp_entry_1_ppn,
  output logic [2:0]   io_resp_bits_resp_entry_1_ppn_low,
  output logic         io_resp_bits_resp_entry_1_af,
  output logic         io_resp_bits_resp_entry_1_pf,
  output logic         io_resp_bits_resp_entry_1_cf,
  output logic [34:0]  io_resp_bits_resp_entry_2_tag,
  output logic [15:0]  io_resp_bits_resp_entry_2_asid,
  output logic [13:0]  io_resp_bits_resp_entry_2_vmid,
  output logic         io_resp_bits_resp_entry_2_n,
  output logic [1:0]   io_resp_bits_resp_entry_2_pbmt,
  output logic         io_resp_bits_resp_entry_2_perm_d,
  output logic         io_resp_bits_resp_entry_2_perm_a,
  output logic         io_resp_bits_resp_entry_2_perm_g,
  output logic         io_resp_bits_resp_entry_2_perm_u,
  output logic         io_resp_bits_resp_entry_2_perm_x,
  output logic         io_resp_bits_resp_entry_2_perm_w,
  output logic         io_resp_bits_resp_entry_2_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_2_level,
  output logic         io_resp_bits_resp_entry_2_v,
  output logic [40:0]  io_resp_bits_resp_entry_2_ppn,
  output logic [2:0]   io_resp_bits_resp_entry_2_ppn_low,
  output logic         io_resp_bits_resp_entry_2_af,
  output logic         io_resp_bits_resp_entry_2_pf,
  output logic         io_resp_bits_resp_entry_2_cf,
  output logic [34:0]  io_resp_bits_resp_entry_3_tag,
  output logic [15:0]  io_resp_bits_resp_entry_3_asid,
  output logic [13:0]  io_resp_bits_resp_entry_3_vmid,
  output logic         io_resp_bits_resp_entry_3_n,
  output logic [1:0]   io_resp_bits_resp_entry_3_pbmt,
  output logic         io_resp_bits_resp_entry_3_perm_d,
  output logic         io_resp_bits_resp_entry_3_perm_a,
  output logic         io_resp_bits_resp_entry_3_perm_g,
  output logic         io_resp_bits_resp_entry_3_perm_u,
  output logic         io_resp_bits_resp_entry_3_perm_x,
  output logic         io_resp_bits_resp_entry_3_perm_w,
  output logic         io_resp_bits_resp_entry_3_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_3_level,
  output logic         io_resp_bits_resp_entry_3_v,
  output logic [40:0]  io_resp_bits_resp_entry_3_ppn,
  output logic [2:0]   io_resp_bits_resp_entry_3_ppn_low,
  output logic         io_resp_bits_resp_entry_3_af,
  output logic         io_resp_bits_resp_entry_3_pf,
  output logic         io_resp_bits_resp_entry_3_cf,
  output logic [34:0]  io_resp_bits_resp_entry_4_tag,
  output logic [15:0]  io_resp_bits_resp_entry_4_asid,
  output logic [13:0]  io_resp_bits_resp_entry_4_vmid,
  output logic         io_resp_bits_resp_entry_4_n,
  output logic [1:0]   io_resp_bits_resp_entry_4_pbmt,
  output logic         io_resp_bits_resp_entry_4_perm_d,
  output logic         io_resp_bits_resp_entry_4_perm_a,
  output logic         io_resp_bits_resp_entry_4_perm_g,
  output logic         io_resp_bits_resp_entry_4_perm_u,
  output logic         io_resp_bits_resp_entry_4_perm_x,
  output logic         io_resp_bits_resp_entry_4_perm_w,
  output logic         io_resp_bits_resp_entry_4_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_4_level,
  output logic         io_resp_bits_resp_entry_4_v,
  output logic [40:0]  io_resp_bits_resp_entry_4_ppn,
  output logic [2:0]   io_resp_bits_resp_entry_4_ppn_low,
  output logic         io_resp_bits_resp_entry_4_af,
  output logic         io_resp_bits_resp_entry_4_pf,
  output logic         io_resp_bits_resp_entry_4_cf,
  output logic [34:0]  io_resp_bits_resp_entry_5_tag,
  output logic [15:0]  io_resp_bits_resp_entry_5_asid,
  output logic [13:0]  io_resp_bits_resp_entry_5_vmid,
  output logic         io_resp_bits_resp_entry_5_n,
  output logic [1:0]   io_resp_bits_resp_entry_5_pbmt,
  output logic         io_resp_bits_resp_entry_5_perm_d,
  output logic         io_resp_bits_resp_entry_5_perm_a,
  output logic         io_resp_bits_resp_entry_5_perm_g,
  output logic         io_resp_bits_resp_entry_5_perm_u,
  output logic         io_resp_bits_resp_entry_5_perm_x,
  output logic         io_resp_bits_resp_entry_5_perm_w,
  output logic         io_resp_bits_resp_entry_5_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_5_level,
  output logic         io_resp_bits_resp_entry_5_v,
  output logic [40:0]  io_resp_bits_resp_entry_5_ppn,
  output logic [2:0]   io_resp_bits_resp_entry_5_ppn_low,
  output logic         io_resp_bits_resp_entry_5_af,
  output logic         io_resp_bits_resp_entry_5_pf,
  output logic         io_resp_bits_resp_entry_5_cf,
  output logic [34:0]  io_resp_bits_resp_entry_6_tag,
  output logic [15:0]  io_resp_bits_resp_entry_6_asid,
  output logic [13:0]  io_resp_bits_resp_entry_6_vmid,
  output logic         io_resp_bits_resp_entry_6_n,
  output logic [1:0]   io_resp_bits_resp_entry_6_pbmt,
  output logic         io_resp_bits_resp_entry_6_perm_d,
  output logic         io_resp_bits_resp_entry_6_perm_a,
  output logic         io_resp_bits_resp_entry_6_perm_g,
  output logic         io_resp_bits_resp_entry_6_perm_u,
  output logic         io_resp_bits_resp_entry_6_perm_x,
  output logic         io_resp_bits_resp_entry_6_perm_w,
  output logic         io_resp_bits_resp_entry_6_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_6_level,
  output logic         io_resp_bits_resp_entry_6_v,
  output logic [40:0]  io_resp_bits_resp_entry_6_ppn,
  output logic [2:0]   io_resp_bits_resp_entry_6_ppn_low,
  output logic         io_resp_bits_resp_entry_6_af,
  output logic         io_resp_bits_resp_entry_6_pf,
  output logic         io_resp_bits_resp_entry_6_cf,
  output logic [34:0]  io_resp_bits_resp_entry_7_tag,
  output logic [15:0]  io_resp_bits_resp_entry_7_asid,
  output logic [13:0]  io_resp_bits_resp_entry_7_vmid,
  output logic         io_resp_bits_resp_entry_7_n,
  output logic [1:0]   io_resp_bits_resp_entry_7_pbmt,
  output logic         io_resp_bits_resp_entry_7_perm_d,
  output logic         io_resp_bits_resp_entry_7_perm_a,
  output logic         io_resp_bits_resp_entry_7_perm_g,
  output logic         io_resp_bits_resp_entry_7_perm_u,
  output logic         io_resp_bits_resp_entry_7_perm_x,
  output logic         io_resp_bits_resp_entry_7_perm_w,
  output logic         io_resp_bits_resp_entry_7_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_7_level,
  output logic         io_resp_bits_resp_entry_7_v,
  output logic [40:0]  io_resp_bits_resp_entry_7_ppn,
  output logic [2:0]   io_resp_bits_resp_entry_7_ppn_low,
  output logic         io_resp_bits_resp_entry_7_af,
  output logic         io_resp_bits_resp_entry_7_pf,
  output logic         io_resp_bits_resp_entry_7_cf,
  output logic         io_resp_bits_resp_pteidx_0,
  output logic         io_resp_bits_resp_pteidx_1,
  output logic         io_resp_bits_resp_pteidx_2,
  output logic         io_resp_bits_resp_pteidx_3,
  output logic         io_resp_bits_resp_pteidx_4,
  output logic         io_resp_bits_resp_pteidx_5,
  output logic         io_resp_bits_resp_pteidx_6,
  output logic         io_resp_bits_resp_pteidx_7,
  output logic         io_resp_bits_resp_not_super,
  output logic [37:0]  io_resp_bits_h_resp_entry_tag,
  output logic [13:0]  io_resp_bits_h_resp_entry_vmid,
  output logic         io_resp_bits_h_resp_entry_n,
  output logic [1:0]   io_resp_bits_h_resp_entry_pbmt,
  output logic [37:0]  io_resp_bits_h_resp_entry_ppn,
  output logic         io_resp_bits_h_resp_entry_perm_d,
  output logic         io_resp_bits_h_resp_entry_perm_a,
  output logic         io_resp_bits_h_resp_entry_perm_g,
  output logic         io_resp_bits_h_resp_entry_perm_u,
  output logic         io_resp_bits_h_resp_entry_perm_x,
  output logic         io_resp_bits_h_resp_entry_perm_w,
  output logic         io_resp_bits_h_resp_entry_perm_r,
  output logic [1:0]   io_resp_bits_h_resp_entry_level,
  output logic         io_resp_bits_h_resp_gpf,
  output logic         io_resp_bits_h_resp_gaf,
  input  logic         io_llptw_ready,
  output logic         io_llptw_valid,
  output logic [37:0]  io_llptw_bits_req_info_vpn,
  output logic [1:0]   io_llptw_bits_req_info_s2xlate,
  output logic [1:0]   io_llptw_bits_req_info_source,
  input  logic         io_hptw_req_ready,
  output logic         io_hptw_req_valid,
  output logic [1:0]   io_hptw_req_bits_source,
  output logic [43:0]  io_hptw_req_bits_gvpn,
  input  logic         io_hptw_resp_valid,
  input  logic [37:0]  io_hptw_resp_bits_h_resp_entry_tag,
  input  logic [13:0]  io_hptw_resp_bits_h_resp_entry_vmid,
  input  logic         io_hptw_resp_bits_h_resp_entry_n,
  input  logic [1:0]   io_hptw_resp_bits_h_resp_entry_pbmt,
  input  logic [37:0]  io_hptw_resp_bits_h_resp_entry_ppn,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_d,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_a,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_g,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_u,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_x,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_w,
  input  logic         io_hptw_resp_bits_h_resp_entry_perm_r,
  input  logic [1:0]   io_hptw_resp_bits_h_resp_entry_level,
  input  logic         io_hptw_resp_bits_h_resp_gpf,
  input  logic         io_hptw_resp_bits_h_resp_gaf,
  input  logic         io_mem_req_ready,
  output logic         io_mem_req_valid,
  output logic [47:0]  io_mem_req_bits_addr,
  input  logic         io_mem_resp_valid,
  input  logic [63:0]  io_mem_resp_bits,
  input  logic         io_mem_mask,
  output logic [47:0]  io_pmp_req_bits_addr,
  input  logic         io_pmp_resp_ld,
  input  logic         io_pmp_resp_mmio,
  output logic [37:0]  io_refill_req_info_vpn,
  output logic [1:0]   io_refill_req_info_s2xlate,
  output logic [1:0]   io_refill_req_info_source,
  output logic [1:0]   io_refill_level,
  input  logic         io_bitmap_req_ready,
  output logic         io_bitmap_req_valid,
  output logic [35:0]  io_bitmap_req_bits_bmppn,
  output logic [37:0]  io_bitmap_req_bits_vpn,
  output logic [1:0]   io_bitmap_req_bits_level,
  output logic [1:0]   io_bitmap_req_bits_s2xlate,
  output logic         io_bitmap_req_bits_n,
  output logic         io_bitmap_resp_ready,
  input  logic         io_bitmap_resp_valid,
  input  logic         io_bitmap_resp_bits_cf,
  output logic [5:0]   io_perf_0_value,
  output logic [5:0]   io_perf_1_value,
  output logic [5:0]   io_perf_2_value,
  output logic [5:0]   io_perf_3_value,
  output logic [5:0]   io_perf_4_value,
  output logic [5:0]   io_perf_5_value,
  output logic [5:0]   io_perf_6_value
);
  xs_PTW_core u_core (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_sfence_valid                          (io_sfence_valid),
    .io_csr_satp_mode                         (io_csr_satp_mode),
    .io_csr_satp_asid                         (io_csr_satp_asid),
    .io_csr_satp_ppn                          (io_csr_satp_ppn),
    .io_csr_satp_changed                      (io_csr_satp_changed),
    .io_csr_vsatp_mode                        (io_csr_vsatp_mode),
    .io_csr_vsatp_asid                        (io_csr_vsatp_asid),
    .io_csr_vsatp_ppn                         (io_csr_vsatp_ppn),
    .io_csr_vsatp_changed                     (io_csr_vsatp_changed),
    .io_csr_hgatp_mode                        (io_csr_hgatp_mode),
    .io_csr_hgatp_vmid                        (io_csr_hgatp_vmid),
    .io_csr_hgatp_changed                     (io_csr_hgatp_changed),
    .io_csr_mbmc_BME                          (io_csr_mbmc_BME),
    .io_csr_mbmc_CMODE                        (io_csr_mbmc_CMODE),
    .io_csr_priv_virt_changed                 (io_csr_priv_virt_changed),
    .io_csr_mPBMTE                            (io_csr_mPBMTE),
    .io_csr_hPBMTE                            (io_csr_hPBMTE),
    .io_req_ready                             (io_req_ready),
    .io_req_valid                             (io_req_valid),
    .io_req_bits_req_info_vpn                 (io_req_bits_req_info_vpn),
    .io_req_bits_req_info_s2xlate             (io_req_bits_req_info_s2xlate),
    .io_req_bits_req_info_source              (io_req_bits_req_info_source),
    .io_req_bits_l3Hit                        (io_req_bits_l3Hit),
    .io_req_bits_l2Hit                        (io_req_bits_l2Hit),
    .io_req_bits_ppn                          (io_req_bits_ppn),
    .io_req_bits_stage1Hit                    (io_req_bits_stage1Hit),
    .io_req_bits_stage1_entry_0_tag           (io_req_bits_stage1_entry_0_tag),
    .io_req_bits_stage1_entry_0_asid          (io_req_bits_stage1_entry_0_asid),
    .io_req_bits_stage1_entry_0_vmid          (io_req_bits_stage1_entry_0_vmid),
    .io_req_bits_stage1_entry_0_n             (io_req_bits_stage1_entry_0_n),
    .io_req_bits_stage1_entry_0_pbmt          (io_req_bits_stage1_entry_0_pbmt),
    .io_req_bits_stage1_entry_0_perm_d        (io_req_bits_stage1_entry_0_perm_d),
    .io_req_bits_stage1_entry_0_perm_a        (io_req_bits_stage1_entry_0_perm_a),
    .io_req_bits_stage1_entry_0_perm_g        (io_req_bits_stage1_entry_0_perm_g),
    .io_req_bits_stage1_entry_0_perm_u        (io_req_bits_stage1_entry_0_perm_u),
    .io_req_bits_stage1_entry_0_perm_x        (io_req_bits_stage1_entry_0_perm_x),
    .io_req_bits_stage1_entry_0_perm_w        (io_req_bits_stage1_entry_0_perm_w),
    .io_req_bits_stage1_entry_0_perm_r        (io_req_bits_stage1_entry_0_perm_r),
    .io_req_bits_stage1_entry_0_level         (io_req_bits_stage1_entry_0_level),
    .io_req_bits_stage1_entry_0_v             (io_req_bits_stage1_entry_0_v),
    .io_req_bits_stage1_entry_0_ppn           (io_req_bits_stage1_entry_0_ppn),
    .io_req_bits_stage1_entry_0_ppn_low       (io_req_bits_stage1_entry_0_ppn_low),
    .io_req_bits_stage1_entry_0_pf            (io_req_bits_stage1_entry_0_pf),
    .io_req_bits_stage1_entry_0_cf            (io_req_bits_stage1_entry_0_cf),
    .io_req_bits_stage1_entry_1_tag           (io_req_bits_stage1_entry_1_tag),
    .io_req_bits_stage1_entry_1_asid          (io_req_bits_stage1_entry_1_asid),
    .io_req_bits_stage1_entry_1_vmid          (io_req_bits_stage1_entry_1_vmid),
    .io_req_bits_stage1_entry_1_n             (io_req_bits_stage1_entry_1_n),
    .io_req_bits_stage1_entry_1_pbmt          (io_req_bits_stage1_entry_1_pbmt),
    .io_req_bits_stage1_entry_1_perm_d        (io_req_bits_stage1_entry_1_perm_d),
    .io_req_bits_stage1_entry_1_perm_a        (io_req_bits_stage1_entry_1_perm_a),
    .io_req_bits_stage1_entry_1_perm_g        (io_req_bits_stage1_entry_1_perm_g),
    .io_req_bits_stage1_entry_1_perm_u        (io_req_bits_stage1_entry_1_perm_u),
    .io_req_bits_stage1_entry_1_perm_x        (io_req_bits_stage1_entry_1_perm_x),
    .io_req_bits_stage1_entry_1_perm_w        (io_req_bits_stage1_entry_1_perm_w),
    .io_req_bits_stage1_entry_1_perm_r        (io_req_bits_stage1_entry_1_perm_r),
    .io_req_bits_stage1_entry_1_level         (io_req_bits_stage1_entry_1_level),
    .io_req_bits_stage1_entry_1_v             (io_req_bits_stage1_entry_1_v),
    .io_req_bits_stage1_entry_1_ppn           (io_req_bits_stage1_entry_1_ppn),
    .io_req_bits_stage1_entry_1_ppn_low       (io_req_bits_stage1_entry_1_ppn_low),
    .io_req_bits_stage1_entry_1_pf            (io_req_bits_stage1_entry_1_pf),
    .io_req_bits_stage1_entry_1_cf            (io_req_bits_stage1_entry_1_cf),
    .io_req_bits_stage1_entry_2_tag           (io_req_bits_stage1_entry_2_tag),
    .io_req_bits_stage1_entry_2_asid          (io_req_bits_stage1_entry_2_asid),
    .io_req_bits_stage1_entry_2_vmid          (io_req_bits_stage1_entry_2_vmid),
    .io_req_bits_stage1_entry_2_n             (io_req_bits_stage1_entry_2_n),
    .io_req_bits_stage1_entry_2_pbmt          (io_req_bits_stage1_entry_2_pbmt),
    .io_req_bits_stage1_entry_2_perm_d        (io_req_bits_stage1_entry_2_perm_d),
    .io_req_bits_stage1_entry_2_perm_a        (io_req_bits_stage1_entry_2_perm_a),
    .io_req_bits_stage1_entry_2_perm_g        (io_req_bits_stage1_entry_2_perm_g),
    .io_req_bits_stage1_entry_2_perm_u        (io_req_bits_stage1_entry_2_perm_u),
    .io_req_bits_stage1_entry_2_perm_x        (io_req_bits_stage1_entry_2_perm_x),
    .io_req_bits_stage1_entry_2_perm_w        (io_req_bits_stage1_entry_2_perm_w),
    .io_req_bits_stage1_entry_2_perm_r        (io_req_bits_stage1_entry_2_perm_r),
    .io_req_bits_stage1_entry_2_level         (io_req_bits_stage1_entry_2_level),
    .io_req_bits_stage1_entry_2_v             (io_req_bits_stage1_entry_2_v),
    .io_req_bits_stage1_entry_2_ppn           (io_req_bits_stage1_entry_2_ppn),
    .io_req_bits_stage1_entry_2_ppn_low       (io_req_bits_stage1_entry_2_ppn_low),
    .io_req_bits_stage1_entry_2_pf            (io_req_bits_stage1_entry_2_pf),
    .io_req_bits_stage1_entry_2_cf            (io_req_bits_stage1_entry_2_cf),
    .io_req_bits_stage1_entry_3_tag           (io_req_bits_stage1_entry_3_tag),
    .io_req_bits_stage1_entry_3_asid          (io_req_bits_stage1_entry_3_asid),
    .io_req_bits_stage1_entry_3_vmid          (io_req_bits_stage1_entry_3_vmid),
    .io_req_bits_stage1_entry_3_n             (io_req_bits_stage1_entry_3_n),
    .io_req_bits_stage1_entry_3_pbmt          (io_req_bits_stage1_entry_3_pbmt),
    .io_req_bits_stage1_entry_3_perm_d        (io_req_bits_stage1_entry_3_perm_d),
    .io_req_bits_stage1_entry_3_perm_a        (io_req_bits_stage1_entry_3_perm_a),
    .io_req_bits_stage1_entry_3_perm_g        (io_req_bits_stage1_entry_3_perm_g),
    .io_req_bits_stage1_entry_3_perm_u        (io_req_bits_stage1_entry_3_perm_u),
    .io_req_bits_stage1_entry_3_perm_x        (io_req_bits_stage1_entry_3_perm_x),
    .io_req_bits_stage1_entry_3_perm_w        (io_req_bits_stage1_entry_3_perm_w),
    .io_req_bits_stage1_entry_3_perm_r        (io_req_bits_stage1_entry_3_perm_r),
    .io_req_bits_stage1_entry_3_level         (io_req_bits_stage1_entry_3_level),
    .io_req_bits_stage1_entry_3_v             (io_req_bits_stage1_entry_3_v),
    .io_req_bits_stage1_entry_3_ppn           (io_req_bits_stage1_entry_3_ppn),
    .io_req_bits_stage1_entry_3_ppn_low       (io_req_bits_stage1_entry_3_ppn_low),
    .io_req_bits_stage1_entry_3_pf            (io_req_bits_stage1_entry_3_pf),
    .io_req_bits_stage1_entry_3_cf            (io_req_bits_stage1_entry_3_cf),
    .io_req_bits_stage1_entry_4_tag           (io_req_bits_stage1_entry_4_tag),
    .io_req_bits_stage1_entry_4_asid          (io_req_bits_stage1_entry_4_asid),
    .io_req_bits_stage1_entry_4_vmid          (io_req_bits_stage1_entry_4_vmid),
    .io_req_bits_stage1_entry_4_n             (io_req_bits_stage1_entry_4_n),
    .io_req_bits_stage1_entry_4_pbmt          (io_req_bits_stage1_entry_4_pbmt),
    .io_req_bits_stage1_entry_4_perm_d        (io_req_bits_stage1_entry_4_perm_d),
    .io_req_bits_stage1_entry_4_perm_a        (io_req_bits_stage1_entry_4_perm_a),
    .io_req_bits_stage1_entry_4_perm_g        (io_req_bits_stage1_entry_4_perm_g),
    .io_req_bits_stage1_entry_4_perm_u        (io_req_bits_stage1_entry_4_perm_u),
    .io_req_bits_stage1_entry_4_perm_x        (io_req_bits_stage1_entry_4_perm_x),
    .io_req_bits_stage1_entry_4_perm_w        (io_req_bits_stage1_entry_4_perm_w),
    .io_req_bits_stage1_entry_4_perm_r        (io_req_bits_stage1_entry_4_perm_r),
    .io_req_bits_stage1_entry_4_level         (io_req_bits_stage1_entry_4_level),
    .io_req_bits_stage1_entry_4_v             (io_req_bits_stage1_entry_4_v),
    .io_req_bits_stage1_entry_4_ppn           (io_req_bits_stage1_entry_4_ppn),
    .io_req_bits_stage1_entry_4_ppn_low       (io_req_bits_stage1_entry_4_ppn_low),
    .io_req_bits_stage1_entry_4_pf            (io_req_bits_stage1_entry_4_pf),
    .io_req_bits_stage1_entry_4_cf            (io_req_bits_stage1_entry_4_cf),
    .io_req_bits_stage1_entry_5_tag           (io_req_bits_stage1_entry_5_tag),
    .io_req_bits_stage1_entry_5_asid          (io_req_bits_stage1_entry_5_asid),
    .io_req_bits_stage1_entry_5_vmid          (io_req_bits_stage1_entry_5_vmid),
    .io_req_bits_stage1_entry_5_n             (io_req_bits_stage1_entry_5_n),
    .io_req_bits_stage1_entry_5_pbmt          (io_req_bits_stage1_entry_5_pbmt),
    .io_req_bits_stage1_entry_5_perm_d        (io_req_bits_stage1_entry_5_perm_d),
    .io_req_bits_stage1_entry_5_perm_a        (io_req_bits_stage1_entry_5_perm_a),
    .io_req_bits_stage1_entry_5_perm_g        (io_req_bits_stage1_entry_5_perm_g),
    .io_req_bits_stage1_entry_5_perm_u        (io_req_bits_stage1_entry_5_perm_u),
    .io_req_bits_stage1_entry_5_perm_x        (io_req_bits_stage1_entry_5_perm_x),
    .io_req_bits_stage1_entry_5_perm_w        (io_req_bits_stage1_entry_5_perm_w),
    .io_req_bits_stage1_entry_5_perm_r        (io_req_bits_stage1_entry_5_perm_r),
    .io_req_bits_stage1_entry_5_level         (io_req_bits_stage1_entry_5_level),
    .io_req_bits_stage1_entry_5_v             (io_req_bits_stage1_entry_5_v),
    .io_req_bits_stage1_entry_5_ppn           (io_req_bits_stage1_entry_5_ppn),
    .io_req_bits_stage1_entry_5_ppn_low       (io_req_bits_stage1_entry_5_ppn_low),
    .io_req_bits_stage1_entry_5_pf            (io_req_bits_stage1_entry_5_pf),
    .io_req_bits_stage1_entry_5_cf            (io_req_bits_stage1_entry_5_cf),
    .io_req_bits_stage1_entry_6_tag           (io_req_bits_stage1_entry_6_tag),
    .io_req_bits_stage1_entry_6_asid          (io_req_bits_stage1_entry_6_asid),
    .io_req_bits_stage1_entry_6_vmid          (io_req_bits_stage1_entry_6_vmid),
    .io_req_bits_stage1_entry_6_n             (io_req_bits_stage1_entry_6_n),
    .io_req_bits_stage1_entry_6_pbmt          (io_req_bits_stage1_entry_6_pbmt),
    .io_req_bits_stage1_entry_6_perm_d        (io_req_bits_stage1_entry_6_perm_d),
    .io_req_bits_stage1_entry_6_perm_a        (io_req_bits_stage1_entry_6_perm_a),
    .io_req_bits_stage1_entry_6_perm_g        (io_req_bits_stage1_entry_6_perm_g),
    .io_req_bits_stage1_entry_6_perm_u        (io_req_bits_stage1_entry_6_perm_u),
    .io_req_bits_stage1_entry_6_perm_x        (io_req_bits_stage1_entry_6_perm_x),
    .io_req_bits_stage1_entry_6_perm_w        (io_req_bits_stage1_entry_6_perm_w),
    .io_req_bits_stage1_entry_6_perm_r        (io_req_bits_stage1_entry_6_perm_r),
    .io_req_bits_stage1_entry_6_level         (io_req_bits_stage1_entry_6_level),
    .io_req_bits_stage1_entry_6_v             (io_req_bits_stage1_entry_6_v),
    .io_req_bits_stage1_entry_6_ppn           (io_req_bits_stage1_entry_6_ppn),
    .io_req_bits_stage1_entry_6_ppn_low       (io_req_bits_stage1_entry_6_ppn_low),
    .io_req_bits_stage1_entry_6_pf            (io_req_bits_stage1_entry_6_pf),
    .io_req_bits_stage1_entry_6_cf            (io_req_bits_stage1_entry_6_cf),
    .io_req_bits_stage1_entry_7_tag           (io_req_bits_stage1_entry_7_tag),
    .io_req_bits_stage1_entry_7_asid          (io_req_bits_stage1_entry_7_asid),
    .io_req_bits_stage1_entry_7_vmid          (io_req_bits_stage1_entry_7_vmid),
    .io_req_bits_stage1_entry_7_n             (io_req_bits_stage1_entry_7_n),
    .io_req_bits_stage1_entry_7_pbmt          (io_req_bits_stage1_entry_7_pbmt),
    .io_req_bits_stage1_entry_7_perm_d        (io_req_bits_stage1_entry_7_perm_d),
    .io_req_bits_stage1_entry_7_perm_a        (io_req_bits_stage1_entry_7_perm_a),
    .io_req_bits_stage1_entry_7_perm_g        (io_req_bits_stage1_entry_7_perm_g),
    .io_req_bits_stage1_entry_7_perm_u        (io_req_bits_stage1_entry_7_perm_u),
    .io_req_bits_stage1_entry_7_perm_x        (io_req_bits_stage1_entry_7_perm_x),
    .io_req_bits_stage1_entry_7_perm_w        (io_req_bits_stage1_entry_7_perm_w),
    .io_req_bits_stage1_entry_7_perm_r        (io_req_bits_stage1_entry_7_perm_r),
    .io_req_bits_stage1_entry_7_level         (io_req_bits_stage1_entry_7_level),
    .io_req_bits_stage1_entry_7_v             (io_req_bits_stage1_entry_7_v),
    .io_req_bits_stage1_entry_7_ppn           (io_req_bits_stage1_entry_7_ppn),
    .io_req_bits_stage1_entry_7_ppn_low       (io_req_bits_stage1_entry_7_ppn_low),
    .io_req_bits_stage1_entry_7_pf            (io_req_bits_stage1_entry_7_pf),
    .io_req_bits_stage1_entry_7_cf            (io_req_bits_stage1_entry_7_cf),
    .io_req_bits_stage1_pteidx_0              (io_req_bits_stage1_pteidx_0),
    .io_req_bits_stage1_pteidx_1              (io_req_bits_stage1_pteidx_1),
    .io_req_bits_stage1_pteidx_2              (io_req_bits_stage1_pteidx_2),
    .io_req_bits_stage1_pteidx_3              (io_req_bits_stage1_pteidx_3),
    .io_req_bits_stage1_pteidx_4              (io_req_bits_stage1_pteidx_4),
    .io_req_bits_stage1_pteidx_5              (io_req_bits_stage1_pteidx_5),
    .io_req_bits_stage1_pteidx_6              (io_req_bits_stage1_pteidx_6),
    .io_req_bits_stage1_pteidx_7              (io_req_bits_stage1_pteidx_7),
    .io_req_bits_stage1_not_super             (io_req_bits_stage1_not_super),
    .io_req_bits_bitmapCheck_jmp_bitmap_check (io_req_bits_bitmapCheck_jmp_bitmap_check),
    .io_req_bits_bitmapCheck_pte              (io_req_bits_bitmapCheck_pte),
    .io_req_bits_bitmapCheck_SPlevel          (io_req_bits_bitmapCheck_SPlevel),
    .io_resp_ready                            (io_resp_ready),
    .io_resp_valid                            (io_resp_valid),
    .io_resp_bits_source                      (io_resp_bits_source),
    .io_resp_bits_s2xlate                     (io_resp_bits_s2xlate),
    .io_resp_bits_resp_entry_0_tag            (io_resp_bits_resp_entry_0_tag),
    .io_resp_bits_resp_entry_0_asid           (io_resp_bits_resp_entry_0_asid),
    .io_resp_bits_resp_entry_0_vmid           (io_resp_bits_resp_entry_0_vmid),
    .io_resp_bits_resp_entry_0_n              (io_resp_bits_resp_entry_0_n),
    .io_resp_bits_resp_entry_0_pbmt           (io_resp_bits_resp_entry_0_pbmt),
    .io_resp_bits_resp_entry_0_perm_d         (io_resp_bits_resp_entry_0_perm_d),
    .io_resp_bits_resp_entry_0_perm_a         (io_resp_bits_resp_entry_0_perm_a),
    .io_resp_bits_resp_entry_0_perm_g         (io_resp_bits_resp_entry_0_perm_g),
    .io_resp_bits_resp_entry_0_perm_u         (io_resp_bits_resp_entry_0_perm_u),
    .io_resp_bits_resp_entry_0_perm_x         (io_resp_bits_resp_entry_0_perm_x),
    .io_resp_bits_resp_entry_0_perm_w         (io_resp_bits_resp_entry_0_perm_w),
    .io_resp_bits_resp_entry_0_perm_r         (io_resp_bits_resp_entry_0_perm_r),
    .io_resp_bits_resp_entry_0_level          (io_resp_bits_resp_entry_0_level),
    .io_resp_bits_resp_entry_0_v              (io_resp_bits_resp_entry_0_v),
    .io_resp_bits_resp_entry_0_ppn            (io_resp_bits_resp_entry_0_ppn),
    .io_resp_bits_resp_entry_0_ppn_low        (io_resp_bits_resp_entry_0_ppn_low),
    .io_resp_bits_resp_entry_0_af             (io_resp_bits_resp_entry_0_af),
    .io_resp_bits_resp_entry_0_pf             (io_resp_bits_resp_entry_0_pf),
    .io_resp_bits_resp_entry_0_cf             (io_resp_bits_resp_entry_0_cf),
    .io_resp_bits_resp_entry_1_tag            (io_resp_bits_resp_entry_1_tag),
    .io_resp_bits_resp_entry_1_asid           (io_resp_bits_resp_entry_1_asid),
    .io_resp_bits_resp_entry_1_vmid           (io_resp_bits_resp_entry_1_vmid),
    .io_resp_bits_resp_entry_1_n              (io_resp_bits_resp_entry_1_n),
    .io_resp_bits_resp_entry_1_pbmt           (io_resp_bits_resp_entry_1_pbmt),
    .io_resp_bits_resp_entry_1_perm_d         (io_resp_bits_resp_entry_1_perm_d),
    .io_resp_bits_resp_entry_1_perm_a         (io_resp_bits_resp_entry_1_perm_a),
    .io_resp_bits_resp_entry_1_perm_g         (io_resp_bits_resp_entry_1_perm_g),
    .io_resp_bits_resp_entry_1_perm_u         (io_resp_bits_resp_entry_1_perm_u),
    .io_resp_bits_resp_entry_1_perm_x         (io_resp_bits_resp_entry_1_perm_x),
    .io_resp_bits_resp_entry_1_perm_w         (io_resp_bits_resp_entry_1_perm_w),
    .io_resp_bits_resp_entry_1_perm_r         (io_resp_bits_resp_entry_1_perm_r),
    .io_resp_bits_resp_entry_1_level          (io_resp_bits_resp_entry_1_level),
    .io_resp_bits_resp_entry_1_v              (io_resp_bits_resp_entry_1_v),
    .io_resp_bits_resp_entry_1_ppn            (io_resp_bits_resp_entry_1_ppn),
    .io_resp_bits_resp_entry_1_ppn_low        (io_resp_bits_resp_entry_1_ppn_low),
    .io_resp_bits_resp_entry_1_af             (io_resp_bits_resp_entry_1_af),
    .io_resp_bits_resp_entry_1_pf             (io_resp_bits_resp_entry_1_pf),
    .io_resp_bits_resp_entry_1_cf             (io_resp_bits_resp_entry_1_cf),
    .io_resp_bits_resp_entry_2_tag            (io_resp_bits_resp_entry_2_tag),
    .io_resp_bits_resp_entry_2_asid           (io_resp_bits_resp_entry_2_asid),
    .io_resp_bits_resp_entry_2_vmid           (io_resp_bits_resp_entry_2_vmid),
    .io_resp_bits_resp_entry_2_n              (io_resp_bits_resp_entry_2_n),
    .io_resp_bits_resp_entry_2_pbmt           (io_resp_bits_resp_entry_2_pbmt),
    .io_resp_bits_resp_entry_2_perm_d         (io_resp_bits_resp_entry_2_perm_d),
    .io_resp_bits_resp_entry_2_perm_a         (io_resp_bits_resp_entry_2_perm_a),
    .io_resp_bits_resp_entry_2_perm_g         (io_resp_bits_resp_entry_2_perm_g),
    .io_resp_bits_resp_entry_2_perm_u         (io_resp_bits_resp_entry_2_perm_u),
    .io_resp_bits_resp_entry_2_perm_x         (io_resp_bits_resp_entry_2_perm_x),
    .io_resp_bits_resp_entry_2_perm_w         (io_resp_bits_resp_entry_2_perm_w),
    .io_resp_bits_resp_entry_2_perm_r         (io_resp_bits_resp_entry_2_perm_r),
    .io_resp_bits_resp_entry_2_level          (io_resp_bits_resp_entry_2_level),
    .io_resp_bits_resp_entry_2_v              (io_resp_bits_resp_entry_2_v),
    .io_resp_bits_resp_entry_2_ppn            (io_resp_bits_resp_entry_2_ppn),
    .io_resp_bits_resp_entry_2_ppn_low        (io_resp_bits_resp_entry_2_ppn_low),
    .io_resp_bits_resp_entry_2_af             (io_resp_bits_resp_entry_2_af),
    .io_resp_bits_resp_entry_2_pf             (io_resp_bits_resp_entry_2_pf),
    .io_resp_bits_resp_entry_2_cf             (io_resp_bits_resp_entry_2_cf),
    .io_resp_bits_resp_entry_3_tag            (io_resp_bits_resp_entry_3_tag),
    .io_resp_bits_resp_entry_3_asid           (io_resp_bits_resp_entry_3_asid),
    .io_resp_bits_resp_entry_3_vmid           (io_resp_bits_resp_entry_3_vmid),
    .io_resp_bits_resp_entry_3_n              (io_resp_bits_resp_entry_3_n),
    .io_resp_bits_resp_entry_3_pbmt           (io_resp_bits_resp_entry_3_pbmt),
    .io_resp_bits_resp_entry_3_perm_d         (io_resp_bits_resp_entry_3_perm_d),
    .io_resp_bits_resp_entry_3_perm_a         (io_resp_bits_resp_entry_3_perm_a),
    .io_resp_bits_resp_entry_3_perm_g         (io_resp_bits_resp_entry_3_perm_g),
    .io_resp_bits_resp_entry_3_perm_u         (io_resp_bits_resp_entry_3_perm_u),
    .io_resp_bits_resp_entry_3_perm_x         (io_resp_bits_resp_entry_3_perm_x),
    .io_resp_bits_resp_entry_3_perm_w         (io_resp_bits_resp_entry_3_perm_w),
    .io_resp_bits_resp_entry_3_perm_r         (io_resp_bits_resp_entry_3_perm_r),
    .io_resp_bits_resp_entry_3_level          (io_resp_bits_resp_entry_3_level),
    .io_resp_bits_resp_entry_3_v              (io_resp_bits_resp_entry_3_v),
    .io_resp_bits_resp_entry_3_ppn            (io_resp_bits_resp_entry_3_ppn),
    .io_resp_bits_resp_entry_3_ppn_low        (io_resp_bits_resp_entry_3_ppn_low),
    .io_resp_bits_resp_entry_3_af             (io_resp_bits_resp_entry_3_af),
    .io_resp_bits_resp_entry_3_pf             (io_resp_bits_resp_entry_3_pf),
    .io_resp_bits_resp_entry_3_cf             (io_resp_bits_resp_entry_3_cf),
    .io_resp_bits_resp_entry_4_tag            (io_resp_bits_resp_entry_4_tag),
    .io_resp_bits_resp_entry_4_asid           (io_resp_bits_resp_entry_4_asid),
    .io_resp_bits_resp_entry_4_vmid           (io_resp_bits_resp_entry_4_vmid),
    .io_resp_bits_resp_entry_4_n              (io_resp_bits_resp_entry_4_n),
    .io_resp_bits_resp_entry_4_pbmt           (io_resp_bits_resp_entry_4_pbmt),
    .io_resp_bits_resp_entry_4_perm_d         (io_resp_bits_resp_entry_4_perm_d),
    .io_resp_bits_resp_entry_4_perm_a         (io_resp_bits_resp_entry_4_perm_a),
    .io_resp_bits_resp_entry_4_perm_g         (io_resp_bits_resp_entry_4_perm_g),
    .io_resp_bits_resp_entry_4_perm_u         (io_resp_bits_resp_entry_4_perm_u),
    .io_resp_bits_resp_entry_4_perm_x         (io_resp_bits_resp_entry_4_perm_x),
    .io_resp_bits_resp_entry_4_perm_w         (io_resp_bits_resp_entry_4_perm_w),
    .io_resp_bits_resp_entry_4_perm_r         (io_resp_bits_resp_entry_4_perm_r),
    .io_resp_bits_resp_entry_4_level          (io_resp_bits_resp_entry_4_level),
    .io_resp_bits_resp_entry_4_v              (io_resp_bits_resp_entry_4_v),
    .io_resp_bits_resp_entry_4_ppn            (io_resp_bits_resp_entry_4_ppn),
    .io_resp_bits_resp_entry_4_ppn_low        (io_resp_bits_resp_entry_4_ppn_low),
    .io_resp_bits_resp_entry_4_af             (io_resp_bits_resp_entry_4_af),
    .io_resp_bits_resp_entry_4_pf             (io_resp_bits_resp_entry_4_pf),
    .io_resp_bits_resp_entry_4_cf             (io_resp_bits_resp_entry_4_cf),
    .io_resp_bits_resp_entry_5_tag            (io_resp_bits_resp_entry_5_tag),
    .io_resp_bits_resp_entry_5_asid           (io_resp_bits_resp_entry_5_asid),
    .io_resp_bits_resp_entry_5_vmid           (io_resp_bits_resp_entry_5_vmid),
    .io_resp_bits_resp_entry_5_n              (io_resp_bits_resp_entry_5_n),
    .io_resp_bits_resp_entry_5_pbmt           (io_resp_bits_resp_entry_5_pbmt),
    .io_resp_bits_resp_entry_5_perm_d         (io_resp_bits_resp_entry_5_perm_d),
    .io_resp_bits_resp_entry_5_perm_a         (io_resp_bits_resp_entry_5_perm_a),
    .io_resp_bits_resp_entry_5_perm_g         (io_resp_bits_resp_entry_5_perm_g),
    .io_resp_bits_resp_entry_5_perm_u         (io_resp_bits_resp_entry_5_perm_u),
    .io_resp_bits_resp_entry_5_perm_x         (io_resp_bits_resp_entry_5_perm_x),
    .io_resp_bits_resp_entry_5_perm_w         (io_resp_bits_resp_entry_5_perm_w),
    .io_resp_bits_resp_entry_5_perm_r         (io_resp_bits_resp_entry_5_perm_r),
    .io_resp_bits_resp_entry_5_level          (io_resp_bits_resp_entry_5_level),
    .io_resp_bits_resp_entry_5_v              (io_resp_bits_resp_entry_5_v),
    .io_resp_bits_resp_entry_5_ppn            (io_resp_bits_resp_entry_5_ppn),
    .io_resp_bits_resp_entry_5_ppn_low        (io_resp_bits_resp_entry_5_ppn_low),
    .io_resp_bits_resp_entry_5_af             (io_resp_bits_resp_entry_5_af),
    .io_resp_bits_resp_entry_5_pf             (io_resp_bits_resp_entry_5_pf),
    .io_resp_bits_resp_entry_5_cf             (io_resp_bits_resp_entry_5_cf),
    .io_resp_bits_resp_entry_6_tag            (io_resp_bits_resp_entry_6_tag),
    .io_resp_bits_resp_entry_6_asid           (io_resp_bits_resp_entry_6_asid),
    .io_resp_bits_resp_entry_6_vmid           (io_resp_bits_resp_entry_6_vmid),
    .io_resp_bits_resp_entry_6_n              (io_resp_bits_resp_entry_6_n),
    .io_resp_bits_resp_entry_6_pbmt           (io_resp_bits_resp_entry_6_pbmt),
    .io_resp_bits_resp_entry_6_perm_d         (io_resp_bits_resp_entry_6_perm_d),
    .io_resp_bits_resp_entry_6_perm_a         (io_resp_bits_resp_entry_6_perm_a),
    .io_resp_bits_resp_entry_6_perm_g         (io_resp_bits_resp_entry_6_perm_g),
    .io_resp_bits_resp_entry_6_perm_u         (io_resp_bits_resp_entry_6_perm_u),
    .io_resp_bits_resp_entry_6_perm_x         (io_resp_bits_resp_entry_6_perm_x),
    .io_resp_bits_resp_entry_6_perm_w         (io_resp_bits_resp_entry_6_perm_w),
    .io_resp_bits_resp_entry_6_perm_r         (io_resp_bits_resp_entry_6_perm_r),
    .io_resp_bits_resp_entry_6_level          (io_resp_bits_resp_entry_6_level),
    .io_resp_bits_resp_entry_6_v              (io_resp_bits_resp_entry_6_v),
    .io_resp_bits_resp_entry_6_ppn            (io_resp_bits_resp_entry_6_ppn),
    .io_resp_bits_resp_entry_6_ppn_low        (io_resp_bits_resp_entry_6_ppn_low),
    .io_resp_bits_resp_entry_6_af             (io_resp_bits_resp_entry_6_af),
    .io_resp_bits_resp_entry_6_pf             (io_resp_bits_resp_entry_6_pf),
    .io_resp_bits_resp_entry_6_cf             (io_resp_bits_resp_entry_6_cf),
    .io_resp_bits_resp_entry_7_tag            (io_resp_bits_resp_entry_7_tag),
    .io_resp_bits_resp_entry_7_asid           (io_resp_bits_resp_entry_7_asid),
    .io_resp_bits_resp_entry_7_vmid           (io_resp_bits_resp_entry_7_vmid),
    .io_resp_bits_resp_entry_7_n              (io_resp_bits_resp_entry_7_n),
    .io_resp_bits_resp_entry_7_pbmt           (io_resp_bits_resp_entry_7_pbmt),
    .io_resp_bits_resp_entry_7_perm_d         (io_resp_bits_resp_entry_7_perm_d),
    .io_resp_bits_resp_entry_7_perm_a         (io_resp_bits_resp_entry_7_perm_a),
    .io_resp_bits_resp_entry_7_perm_g         (io_resp_bits_resp_entry_7_perm_g),
    .io_resp_bits_resp_entry_7_perm_u         (io_resp_bits_resp_entry_7_perm_u),
    .io_resp_bits_resp_entry_7_perm_x         (io_resp_bits_resp_entry_7_perm_x),
    .io_resp_bits_resp_entry_7_perm_w         (io_resp_bits_resp_entry_7_perm_w),
    .io_resp_bits_resp_entry_7_perm_r         (io_resp_bits_resp_entry_7_perm_r),
    .io_resp_bits_resp_entry_7_level          (io_resp_bits_resp_entry_7_level),
    .io_resp_bits_resp_entry_7_v              (io_resp_bits_resp_entry_7_v),
    .io_resp_bits_resp_entry_7_ppn            (io_resp_bits_resp_entry_7_ppn),
    .io_resp_bits_resp_entry_7_ppn_low        (io_resp_bits_resp_entry_7_ppn_low),
    .io_resp_bits_resp_entry_7_af             (io_resp_bits_resp_entry_7_af),
    .io_resp_bits_resp_entry_7_pf             (io_resp_bits_resp_entry_7_pf),
    .io_resp_bits_resp_entry_7_cf             (io_resp_bits_resp_entry_7_cf),
    .io_resp_bits_resp_pteidx_0               (io_resp_bits_resp_pteidx_0),
    .io_resp_bits_resp_pteidx_1               (io_resp_bits_resp_pteidx_1),
    .io_resp_bits_resp_pteidx_2               (io_resp_bits_resp_pteidx_2),
    .io_resp_bits_resp_pteidx_3               (io_resp_bits_resp_pteidx_3),
    .io_resp_bits_resp_pteidx_4               (io_resp_bits_resp_pteidx_4),
    .io_resp_bits_resp_pteidx_5               (io_resp_bits_resp_pteidx_5),
    .io_resp_bits_resp_pteidx_6               (io_resp_bits_resp_pteidx_6),
    .io_resp_bits_resp_pteidx_7               (io_resp_bits_resp_pteidx_7),
    .io_resp_bits_resp_not_super              (io_resp_bits_resp_not_super),
    .io_resp_bits_h_resp_entry_tag            (io_resp_bits_h_resp_entry_tag),
    .io_resp_bits_h_resp_entry_vmid           (io_resp_bits_h_resp_entry_vmid),
    .io_resp_bits_h_resp_entry_n              (io_resp_bits_h_resp_entry_n),
    .io_resp_bits_h_resp_entry_pbmt           (io_resp_bits_h_resp_entry_pbmt),
    .io_resp_bits_h_resp_entry_ppn            (io_resp_bits_h_resp_entry_ppn),
    .io_resp_bits_h_resp_entry_perm_d         (io_resp_bits_h_resp_entry_perm_d),
    .io_resp_bits_h_resp_entry_perm_a         (io_resp_bits_h_resp_entry_perm_a),
    .io_resp_bits_h_resp_entry_perm_g         (io_resp_bits_h_resp_entry_perm_g),
    .io_resp_bits_h_resp_entry_perm_u         (io_resp_bits_h_resp_entry_perm_u),
    .io_resp_bits_h_resp_entry_perm_x         (io_resp_bits_h_resp_entry_perm_x),
    .io_resp_bits_h_resp_entry_perm_w         (io_resp_bits_h_resp_entry_perm_w),
    .io_resp_bits_h_resp_entry_perm_r         (io_resp_bits_h_resp_entry_perm_r),
    .io_resp_bits_h_resp_entry_level          (io_resp_bits_h_resp_entry_level),
    .io_resp_bits_h_resp_gpf                  (io_resp_bits_h_resp_gpf),
    .io_resp_bits_h_resp_gaf                  (io_resp_bits_h_resp_gaf),
    .io_llptw_ready                           (io_llptw_ready),
    .io_llptw_valid                           (io_llptw_valid),
    .io_llptw_bits_req_info_vpn               (io_llptw_bits_req_info_vpn),
    .io_llptw_bits_req_info_s2xlate           (io_llptw_bits_req_info_s2xlate),
    .io_llptw_bits_req_info_source            (io_llptw_bits_req_info_source),
    .io_hptw_req_ready                        (io_hptw_req_ready),
    .io_hptw_req_valid                        (io_hptw_req_valid),
    .io_hptw_req_bits_source                  (io_hptw_req_bits_source),
    .io_hptw_req_bits_gvpn                    (io_hptw_req_bits_gvpn),
    .io_hptw_resp_valid                       (io_hptw_resp_valid),
    .io_hptw_resp_bits_h_resp_entry_tag       (io_hptw_resp_bits_h_resp_entry_tag),
    .io_hptw_resp_bits_h_resp_entry_vmid      (io_hptw_resp_bits_h_resp_entry_vmid),
    .io_hptw_resp_bits_h_resp_entry_n         (io_hptw_resp_bits_h_resp_entry_n),
    .io_hptw_resp_bits_h_resp_entry_pbmt      (io_hptw_resp_bits_h_resp_entry_pbmt),
    .io_hptw_resp_bits_h_resp_entry_ppn       (io_hptw_resp_bits_h_resp_entry_ppn),
    .io_hptw_resp_bits_h_resp_entry_perm_d    (io_hptw_resp_bits_h_resp_entry_perm_d),
    .io_hptw_resp_bits_h_resp_entry_perm_a    (io_hptw_resp_bits_h_resp_entry_perm_a),
    .io_hptw_resp_bits_h_resp_entry_perm_g    (io_hptw_resp_bits_h_resp_entry_perm_g),
    .io_hptw_resp_bits_h_resp_entry_perm_u    (io_hptw_resp_bits_h_resp_entry_perm_u),
    .io_hptw_resp_bits_h_resp_entry_perm_x    (io_hptw_resp_bits_h_resp_entry_perm_x),
    .io_hptw_resp_bits_h_resp_entry_perm_w    (io_hptw_resp_bits_h_resp_entry_perm_w),
    .io_hptw_resp_bits_h_resp_entry_perm_r    (io_hptw_resp_bits_h_resp_entry_perm_r),
    .io_hptw_resp_bits_h_resp_entry_level     (io_hptw_resp_bits_h_resp_entry_level),
    .io_hptw_resp_bits_h_resp_gpf             (io_hptw_resp_bits_h_resp_gpf),
    .io_hptw_resp_bits_h_resp_gaf             (io_hptw_resp_bits_h_resp_gaf),
    .io_mem_req_ready                         (io_mem_req_ready),
    .io_mem_req_valid                         (io_mem_req_valid),
    .io_mem_req_bits_addr                     (io_mem_req_bits_addr),
    .io_mem_resp_valid                        (io_mem_resp_valid),
    .io_mem_resp_bits                         (io_mem_resp_bits),
    .io_mem_mask                              (io_mem_mask),
    .io_pmp_req_bits_addr                     (io_pmp_req_bits_addr),
    .io_pmp_resp_ld                           (io_pmp_resp_ld),
    .io_pmp_resp_mmio                         (io_pmp_resp_mmio),
    .io_refill_req_info_vpn                   (io_refill_req_info_vpn),
    .io_refill_req_info_s2xlate               (io_refill_req_info_s2xlate),
    .io_refill_req_info_source                (io_refill_req_info_source),
    .io_refill_level                          (io_refill_level),
    .io_bitmap_req_ready                      (io_bitmap_req_ready),
    .io_bitmap_req_valid                      (io_bitmap_req_valid),
    .io_bitmap_req_bits_bmppn                 (io_bitmap_req_bits_bmppn),
    .io_bitmap_req_bits_vpn                   (io_bitmap_req_bits_vpn),
    .io_bitmap_req_bits_level                 (io_bitmap_req_bits_level),
    .io_bitmap_req_bits_s2xlate               (io_bitmap_req_bits_s2xlate),
    .io_bitmap_req_bits_n                     (io_bitmap_req_bits_n),
    .io_bitmap_resp_ready                     (io_bitmap_resp_ready),
    .io_bitmap_resp_valid                     (io_bitmap_resp_valid),
    .io_bitmap_resp_bits_cf                   (io_bitmap_resp_bits_cf),
    .io_perf_0_value                          (io_perf_0_value),
    .io_perf_1_value                          (io_perf_1_value),
    .io_perf_2_value                          (io_perf_2_value),
    .io_perf_3_value                          (io_perf_3_value),
    .io_perf_4_value                          (io_perf_4_value),
    .io_perf_5_value                          (io_perf_5_value),
    .io_perf_6_value                          (io_perf_6_value)
  );
endmodule
// END GENERATED(wrapper)
