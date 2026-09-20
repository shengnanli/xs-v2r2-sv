// PtwCache.sv —— L2 TLB 页表缓存（Page Table Cache）：把已走过的页表项缓存下来，
// 让下一次同前缀的地址翻译少走几级 memory walk。
//
// 本文件含：xs_ptwcache_pkg（几何与类型）+ xs_PtwCache_core（可读重写核）+
// PtwCache（golden 同名 wrapper，455 端口透传）。
// 对应 Chisel: xiangshan.cache.mmu.PtwCache（PageTableCache.scala）；
// 对照 golden = G1-canonical/golden-rtl/PtwCache.sv（45,308 行，单变体）。
//
// ★★★ 本文件当前是【考古骨架】，不是完成的重写 ★★★
//   已按 golden 逐根量出并写成功能 RTL 的部分，见下面「已追清」各节；
//   尚未追清方程、当前以占位输出顶着的部分，集中列在「未追清清单」一节。
//   任何人在「未追清清单」清空之前引用本文件的输出，都会拿到错值。
//
// 【它在 MMU 里的位置】
//   TLB miss ─▶ L2TLB(ptw) ─▶ PtwCache ──命中──▶ 直接回填 TLB
//                              │
//                              └─未命中/部分命中─▶ PTW/LLPTW/HPTW 真正走内存
//                                                        │
//                                     io.refill ◀────────┘（把走回来的 PTE 写进本缓存）
//
// 【五级存储（golden 实测几何，不是从 Chisel 抄的）】
//   级  载体              组×路   条目内容                          有效位
//   l3  寄存器阵列  16 项全相联  tag=vpn[37:27]      asid vmid ppn[37:0] prefetch      l3v[15:0]
//   l2  寄存器阵列  16 项全相联  tag=vpn[37:18]      asid vmid pbmt ppn[37:0] prefetch l2v[15:0]      
//   l1  SplittedSRAM_1  4组×2路  tag=vpn[37:14]      组=vpn[13:12] 组内 8 项=vpn[11:9] l1v[7:0]
//   l0  SplittedSRAM_2 64组×4路  tag=vpn[37:9]       组=vpn[8:3]   组内 8 项=vpn[2:0]  l0v[255:0]
//   sp  寄存器阵列  16 项全相联  tag=vpn[37:0] 全宽   + perm/level/n（大页 superpage）  spv[15:0]
//   l1 每项装 8 个 PDE（共享同一张 512 项页表页），l0 每项装 8 个 PTE —— 这就是
//   io.refill.bits.ptes 为什么是 512 位（8×64）。
//   l1/l0 的 tag/asid/vmid 在 SRAM 里，但**另有一份影子寄存器**（l1asids/l1vmids/l1h、
//   l0vpns/l0asids/l0vmids/l0h）留在核内 —— sfence 要按 asid/vmid/vpn 逐条比对失效，
//   而 SRAM 一拍只能读一组，所以比对用的副本必须是 flop。照抄这份冗余，别合并。
//
// 【四级流水（golden 实测，PipelineConnect 链）】
//   stageReq(组合) ─▶ stageDelay(valid)  ─▶ stageCheck(valid_1) ─▶ stageResp(valid_2)
//       发 SRAM 读        SRAM 数据回来       算命中向量            装配 io.resp
//   ready 反压：stageResp_ready = ~valid_2 | io_resp_ready
//              stageCheck_0_ready = ~valid_1 | stageResp_ready
//              stageDelay_0_ready = ~valid   | stageCheck_0_ready
//              stageReq_ready     = stageDelay_0_ready & ~(io_refill_valid | wakeupHarzad)
//   ★最后一条是本模块的入口节流：refill 和 bitmap wakeup 都要占用 SRAM 端口，
//    所以它们有效的那一拍新请求不许进来。★
//
// 【三份 dup 各归谁 —— 照抄，绝不合并】
//   golden 把 sfence/csr/refill 的关键字段复制成 dup_0/1/2 三份做扇出切割，
//   而三份的**消费者是分开的**（实测引用计数 777/9/75，各自喂不同的级）：
//     dup_0 ─▶ l0 与 sp（也门控 l0 的 ClockGate）
//     dup_1 ─▶ l1     （也门控 l1 的 ClockGate；sfence_dup_1 只带 valid+id）
//     dup_2 ─▶ l2 与 l3
//   io_refill_bits_level/sel_pte 只有 dup_0 与 dup_2 两份（dup_1 在 golden 端口表里
//   根本不存在，被 firtool 裁掉了）。把三份写成一份 = Predictor 那 504 个 FM 失配点。
//
// 【复位域 —— golden 实测，别照直觉全复位】
//   golden 只有**一个** always @(posedge clock or posedge reset)（异步高有效复位），
//   带复位的寄存器 2143 个；另有一个 always @(posedge clock)，**完全不带复位**的
//   寄存器 2749 个。两组零交集。分界线是：
//     复位：各级 valid 位向量（l3v/l2v/l1v/l0v/spv）、l0BitmapReg(2048)、
//           替换状态（state_reg×3 / state_vec×68）、流水 valid、bypass valid、wakeup valid
//     不复位：★全部 tag/asid/vmid/ppn/perm 载荷★、★global 位向量 l3g/l2g/l1g/l0g/spg★、
//           影子元数据（l0h/l0vpns/l0asids/l0vmids/l1h/…）、全部流水载荷、SRAM 回读寄存器
//   ★g 向量不复位而 v 向量复位★是最容易写错的一处：两者都是同宽位向量，看起来该一起复位。
//
// 【子模块（本文件当黑盒例化）】
//   SplittedSRAM_1  l1         —— l1 级 SRAM（4 组 2 路）。★本仓尚无可读实现★
//   SplittedSRAM_2  l0         —— l0 级 SRAM（64 组 4 路，内含 16 个 SRAMTemplate）。★本仓尚无可读实现★
//   MbistPipePtwL1  mbistPlL1  —— MBIST 分发，已在 rtl/dft/MbistPipePtwL1.sv 重写
//   MbistPipePtwL0  mbistPlL0  —— MBIST 分发，已在 rtl/dft/MbistPipePtwL0.sv 重写
//   ClockGate ×2               —— l0/l1 SRAM 的时钟门控，golden 复用件
//
// 【golden 45,308 行里有多少是真逻辑】
//   （实测行计数，供排期用，不是借口）
//   7,125 行 = firtool 的 initial/RANDOM 初始化样板，可读重写完全不产生；
//   14,336 行提及 l0BitmapReg（一个 64×4×8 的 flop 阵列被展平成 2048 个标量）；
//   6,364 行提及 l0h/l0vpns/l0asids/l0vmids（四个 64×4 影子阵列同样被展平）；
//   合计约 61% 是阵列展平样板。真正需要逐条追方程的distinct 逻辑约 1 万行量级。
//
// 【差分 UT 方案（还没实现，先把判据钉下来）】
//   形态照 verif/ut/L2TlbMissQueue：tb 里同时例化 golden PtwCache 与本核的派生副本
//   PtwCache_xs，同拍同激励，逐拍比 455 根端口里的全部 236 个输出。
//   seed 1/7/42，每 seed ≥200k 拍，errors=0。
//   ★本模块有三处必须专门设计激励，否则 errors=0 没有意义★：
//     1. 不复位寄存器占 2749/4892。`+vcs+initreg+random` 与 `+vcs+initreg+0` 两轮都要跑；
//        两轮结果必须都 errors=0，且两轮的失配**位置**若不同，说明有 X 依赖。
//     2. 带 SRAM 阵列：Predictor 那一轮实测 array_*_ext.v 在 `+define+SYNTHESIS` 下
//        完全不初始化，两侧 X 传播范围不同，报了 18 万个启动期假失配。本模块 l0 下挂
//        16 个 SRAMTemplate，撞到大批启动期失配时**先查这个，别改 RTL**。
//     3. 三份 dup 必须**分别**驱动成不同值。若 tb 把 dup_0/1/2 绑成同一根线，
//        「三份合并成一份」这个错误形态在 UT 里按构造测不出来——Predictor 就是这么漏的。
//   判别力 mutant（不进库，只用来证明 UT 会响）候选：
//     M1 把 flush_dup_1 换成 flush_dup_0（dup 归属写错）；
//     M2 把 l0g 也放进复位块（复位域写错）；
//     M3 把 stageReq_ready 里的 `~(rw_harzad|wakeup_harzad)` 去掉（入口节流丢失）；
//     M4 把 l3 回填时污染 l2 PLRU 的那条「golden 真 bug」改成"正确"接线。
//   ★M4 特别重要★：它是唯一能证明我们**照抄了 golden 的 bug** 而不是照抄了直觉的实验。
//
// 【已追清 / 未追清 —— 当前边界】
//   已追清并写成 RTL：四级流水握手与入口节流、三份 dup 的 flush 与归属、
//     复位域划分、两个 ClockGate 的开门条件、l1/l0 的 SRAM 读地址与读使能、
//     l1/l0 的**全部写数据**（§6.1 的 10 个 PTE 谓词 + §6.2 的逐项 vs/onlypf/
//     perms/ppn/pbmt/prefetch）、全部 MBIST/DFT 透传拓扑、
//     ★五级替换策略与受害者选择（§7：PseudoLRU 取路/更新 + replaceWrapper，
//     含 golden 那个"l3 回填污染 l2 PLRU"的真 bug）★、
//     ★各级回填使能与回填侧状态更新（§9/§11：l3/l2/sp 表项载荷、
//     l3v..spv 的置位、l3g..spg、五级 h、l1/l0 的 XORFold 影子哈希）★。
//   上述两段有 verif/study/PtwCache_refill 的定向差分对照钉住：双例化比
//     430 根 SRAM 写端口 + 1615 根核内回填侧状态，3 seed × 200k 拍，errors=0；
//     注入 4 个 mutant（含"把 golden 真 bug 修好"）全部被抓到，详见该目录 tb.sv 头注释。
//   未追清（骨架里以显式钉 0 顶着，见 §8）：
//     · 各级 hitVec 与命中数据选择、命中侧的 PLRU access（plru_l3 目前**没有任何写者**）；
//     · sfence/hfence 失效掩码（三种 rs1/rs2 组合 × 三种 fence 类型）；
//     · l1/l0 的 ecc flush；
//     · bitmap 检查（l0_bitmap 的写）与 wakeup 回写；
//     · io.resp 的 220 根载荷输出；
//     · 8 个 perf 计数器。
//   ★也就是说：当前这份核只在"从不发请求、从不发 sfence、从不 ecc 出错"的激励下
//    与 golden 同态。任何人在上面那张清单清空之前引用它的输出，都会拿到错值。★
// 本文件导航（共 4554 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L43    它在 MMU 里的位置
//   L50    五级存储
//   L63    四级流水
//   L73    三份 dup 各归谁 —— 照抄，绝不合并
//   L82    复位域 —— golden 实测，别照直觉全复位
//   L92    子模块
//   L99    golden 45,308 行里有多少是真逻辑
//   L106   差分 UT 方案
//   L125   已追清 / 未追清 —— 当前边界
//   L148   xs_ptwcache_pkg —— 几何、类型与编码
//   L686   §1 四级流水与反压
//   L731   §2 三份 dup 的归属与 flush
//   L762   §3 存储声明
//   L803   §4 复位域
//   L814   §5 时钟门控与 SRAM 端口仲裁
//   L847   §6 各级 refill 使能
//   L857   §7 替换策略状态
//   L876   §6.1 PTE 谓词
//   L990   §6.2 回填写数据
//   L1084  §7.1 PseudoLRU —— 位布局与两个方程
//   L1141  §7.2 replaceWrapper —— 「有空位先填空位，满了才问 PLRU」
//   L1170  §7.3 受害者选择
//   L1213  §9 各级回填使能与回填载荷
//   L1284  §9.1 XORFold —— 影子元数据存的是折叠哈希，不是原值
//   L1298  §11 时序：两个 always_ff，复位域划分照抄 golden
//   L1428  §8 未追清清单 —— ★占位信号，当前值无意义★
//   L2269  §9 子模块例化
//

// =============================================================================
// xs_ptwcache_pkg —— 几何、类型与编码（全部从 G1 golden 逐根量出）
// =============================================================================
package xs_ptwcache_pkg;

  // ---- 地址与标识宽度（KunminghuV2Config: EnableSv48=1, HasHExtension=1）----
  localparam int VPN_W      = 38;  // vpnLen = gvpnLen（Sv48x4 的 G 阶段最宽）
  localparam int PPN_W      = 38;
  localparam int ASID_W     = 16;
  localparam int VMID_W     = 14;  // ★golden 实测 14 位，不是 hgatp_vmid 的 16 位★
  localparam int SOURCE_W   = 2;
  localparam int HPTWID_W   = 3;
  localparam int SECTOR_N   = 8;   // tlbcontiguous：一条 l1/l0 表项装 8 个相邻 PTE
  localparam int PTE_W_BITS = 64;  // 一个 PTE 的位宽
  localparam int LINE_W     = SECTOR_N * PTE_W_BITS;  // 512 = io_refill_bits_ptes 宽度

  // ---- 五级几何（golden 实测：见文件头表）----
  localparam int L3_N       = 16;  localparam int L3_TAG_W = 11;  // vpn[37:27]
  localparam int L2_N       = 16;  localparam int L2_TAG_W = 20;  // vpn[37:18]
  localparam int L1_SETS    = 4;   localparam int L1_WAYS  = 2;   localparam int L1_TAG_W = 24; // vpn[37:14]
  localparam int L0_SETS    = 64;  localparam int L0_WAYS  = 4;   localparam int L0_TAG_W = 29; // vpn[37:9]
  localparam int SP_N       = 16;  localparam int SP_TAG_W = VPN_W;

  // ---- 两阶段翻译标记 h（每条表项都带，用来区分 VS 级 / G 级共存的条目）----
  //  Chisel: noS2xlate=0, allStage=3, onlyStage1=1, onlyStage2=2
  //  查找时 allStage 用 onlyStage1 去比（h_search），回填时 refill_h 同理折叠。
  localparam logic [1:0] H_NO_S2XLATE  = 2'd0;
  localparam logic [1:0] H_ONLY_STAGE1 = 2'd1;
  localparam logic [1:0] H_ONLY_STAGE2 = 2'd2;
  localparam logic [1:0] H_ALL_STAGE   = 2'd3;

  // ---- 影子元数据的折叠宽度（sfence 比对用的是 XORFold 哈希，不是原值）----
  //  代价是 sfence 会**保守多刷**（哈希撞了就多刷几条），这是 golden 的设计选择，
  //  不是缺陷；重写必须照抄同一个折叠函数，否则刷的条目集合会不一样。
  localparam int HASH_ASID_W = 3;
  localparam int HASH_VMID_W = 3;
  localparam int HASH_VPN_W  = 6;

  // l3 表项（寄存器阵列，16 项全相联，无 pbmt）
  typedef struct packed {
    logic [L3_TAG_W-1:0] tag;
    logic [ASID_W-1:0]   asid;
    logic [VMID_W-1:0]   vmid;
    logic [PPN_W-1:0]    ppn;
    logic                prefetch;
  } l3_entry_t;

  // l2 表项（寄存器阵列，16 项全相联，比 l3 多一个 pbmt）
  typedef struct packed {
    logic [L2_TAG_W-1:0] tag;
    logic [ASID_W-1:0]   asid;
    logic [VMID_W-1:0]   vmid;
    logic [1:0]          pbmt;
    logic [PPN_W-1:0]    ppn;
    logic                prefetch;
  } l2_entry_t;

  // RISC-V 页表项权限位
  typedef struct packed {
    logic d, a, g, u, x, w, r;
  } pte_perm_t;

  // sp（superpage）表项：大页/Svnapot，带完整权限与 level
  typedef struct packed {
    logic [SP_TAG_W-1:0] tag;
    logic [ASID_W-1:0]   asid;
    logic [VMID_W-1:0]   vmid;
    logic                n;        // Svnapot
    logic [1:0]          pbmt;
    logic [PPN_W-1:0]    ppn;
    pte_perm_t           perm;
    logic [1:0]          level;
    logic                prefetch;
    logic                v;        // ★注意：sp 条目自带 v 字段，与 spv 位向量是两回事★
  } sp_entry_t;

endpackage

module xs_PtwCache_core(
  input  logic         clock,
  input  logic         reset,
  input  logic         io_csr_mPBMTE,
  input  logic         io_csr_hPBMTE,
  output logic         io_req_ready,
  input  logic         io_req_valid,
  input  logic [37:0]  io_req_bits_req_info_vpn,
  input  logic [1:0]   io_req_bits_req_info_s2xlate,
  input  logic [1:0]   io_req_bits_req_info_source,
  input  logic         io_req_bits_isFirst,
  input  logic         io_req_bits_isHptwReq,
  input  logic [2:0]   io_req_bits_hptwId,
  input  logic         io_resp_ready,
  output logic         io_resp_valid,
  output logic [37:0]  io_resp_bits_req_info_vpn,
  output logic [1:0]   io_resp_bits_req_info_s2xlate,
  output logic [1:0]   io_resp_bits_req_info_source,
  output logic         io_resp_bits_isFirst,
  output logic         io_resp_bits_hit,
  output logic         io_resp_bits_prefetch,
  output logic         io_resp_bits_bypassed,
  output logic         io_resp_bits_toFsm_l3Hit,
  output logic         io_resp_bits_toFsm_l2Hit,
  output logic         io_resp_bits_toFsm_l1Hit,
  output logic [37:0]  io_resp_bits_toFsm_ppn,
  output logic         io_resp_bits_toFsm_stage1Hit,
  output logic         io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check,
  output logic         io_resp_bits_toFsm_bitmapCheck_toLLPTW,
  output logic [3:0]   io_resp_bits_toFsm_bitmapCheck_hitway,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_pte,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_ptes_0,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_ptes_1,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_ptes_2,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_ptes_3,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_ptes_4,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_ptes_5,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_ptes_6,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_ptes_7,
  output logic         io_resp_bits_toFsm_bitmapCheck_cfs_0,
  output logic         io_resp_bits_toFsm_bitmapCheck_cfs_1,
  output logic         io_resp_bits_toFsm_bitmapCheck_cfs_2,
  output logic         io_resp_bits_toFsm_bitmapCheck_cfs_3,
  output logic         io_resp_bits_toFsm_bitmapCheck_cfs_4,
  output logic         io_resp_bits_toFsm_bitmapCheck_cfs_5,
  output logic         io_resp_bits_toFsm_bitmapCheck_cfs_6,
  output logic         io_resp_bits_toFsm_bitmapCheck_cfs_7,
  output logic [1:0]   io_resp_bits_toFsm_bitmapCheck_SPlevel,
  output logic [34:0]  io_resp_bits_stage1_entry_0_tag,
  output logic [15:0]  io_resp_bits_stage1_entry_0_asid,
  output logic [13:0]  io_resp_bits_stage1_entry_0_vmid,
  output logic         io_resp_bits_stage1_entry_0_n,
  output logic [1:0]   io_resp_bits_stage1_entry_0_pbmt,
  output logic         io_resp_bits_stage1_entry_0_perm_d,
  output logic         io_resp_bits_stage1_entry_0_perm_a,
  output logic         io_resp_bits_stage1_entry_0_perm_g,
  output logic         io_resp_bits_stage1_entry_0_perm_u,
  output logic         io_resp_bits_stage1_entry_0_perm_x,
  output logic         io_resp_bits_stage1_entry_0_perm_w,
  output logic         io_resp_bits_stage1_entry_0_perm_r,
  output logic [1:0]   io_resp_bits_stage1_entry_0_level,
  output logic         io_resp_bits_stage1_entry_0_v,
  output logic [40:0]  io_resp_bits_stage1_entry_0_ppn,
  output logic [2:0]   io_resp_bits_stage1_entry_0_ppn_low,
  output logic         io_resp_bits_stage1_entry_0_pf,
  output logic         io_resp_bits_stage1_entry_0_cf,
  output logic [34:0]  io_resp_bits_stage1_entry_1_tag,
  output logic [15:0]  io_resp_bits_stage1_entry_1_asid,
  output logic [13:0]  io_resp_bits_stage1_entry_1_vmid,
  output logic         io_resp_bits_stage1_entry_1_n,
  output logic [1:0]   io_resp_bits_stage1_entry_1_pbmt,
  output logic         io_resp_bits_stage1_entry_1_perm_d,
  output logic         io_resp_bits_stage1_entry_1_perm_a,
  output logic         io_resp_bits_stage1_entry_1_perm_g,
  output logic         io_resp_bits_stage1_entry_1_perm_u,
  output logic         io_resp_bits_stage1_entry_1_perm_x,
  output logic         io_resp_bits_stage1_entry_1_perm_w,
  output logic         io_resp_bits_stage1_entry_1_perm_r,
  output logic [1:0]   io_resp_bits_stage1_entry_1_level,
  output logic         io_resp_bits_stage1_entry_1_v,
  output logic [40:0]  io_resp_bits_stage1_entry_1_ppn,
  output logic [2:0]   io_resp_bits_stage1_entry_1_ppn_low,
  output logic         io_resp_bits_stage1_entry_1_pf,
  output logic         io_resp_bits_stage1_entry_1_cf,
  output logic [34:0]  io_resp_bits_stage1_entry_2_tag,
  output logic [15:0]  io_resp_bits_stage1_entry_2_asid,
  output logic [13:0]  io_resp_bits_stage1_entry_2_vmid,
  output logic         io_resp_bits_stage1_entry_2_n,
  output logic [1:0]   io_resp_bits_stage1_entry_2_pbmt,
  output logic         io_resp_bits_stage1_entry_2_perm_d,
  output logic         io_resp_bits_stage1_entry_2_perm_a,
  output logic         io_resp_bits_stage1_entry_2_perm_g,
  output logic         io_resp_bits_stage1_entry_2_perm_u,
  output logic         io_resp_bits_stage1_entry_2_perm_x,
  output logic         io_resp_bits_stage1_entry_2_perm_w,
  output logic         io_resp_bits_stage1_entry_2_perm_r,
  output logic [1:0]   io_resp_bits_stage1_entry_2_level,
  output logic         io_resp_bits_stage1_entry_2_v,
  output logic [40:0]  io_resp_bits_stage1_entry_2_ppn,
  output logic [2:0]   io_resp_bits_stage1_entry_2_ppn_low,
  output logic         io_resp_bits_stage1_entry_2_pf,
  output logic         io_resp_bits_stage1_entry_2_cf,
  output logic [34:0]  io_resp_bits_stage1_entry_3_tag,
  output logic [15:0]  io_resp_bits_stage1_entry_3_asid,
  output logic [13:0]  io_resp_bits_stage1_entry_3_vmid,
  output logic         io_resp_bits_stage1_entry_3_n,
  output logic [1:0]   io_resp_bits_stage1_entry_3_pbmt,
  output logic         io_resp_bits_stage1_entry_3_perm_d,
  output logic         io_resp_bits_stage1_entry_3_perm_a,
  output logic         io_resp_bits_stage1_entry_3_perm_g,
  output logic         io_resp_bits_stage1_entry_3_perm_u,
  output logic         io_resp_bits_stage1_entry_3_perm_x,
  output logic         io_resp_bits_stage1_entry_3_perm_w,
  output logic         io_resp_bits_stage1_entry_3_perm_r,
  output logic [1:0]   io_resp_bits_stage1_entry_3_level,
  output logic         io_resp_bits_stage1_entry_3_v,
  output logic [40:0]  io_resp_bits_stage1_entry_3_ppn,
  output logic [2:0]   io_resp_bits_stage1_entry_3_ppn_low,
  output logic         io_resp_bits_stage1_entry_3_pf,
  output logic         io_resp_bits_stage1_entry_3_cf,
  output logic [34:0]  io_resp_bits_stage1_entry_4_tag,
  output logic [15:0]  io_resp_bits_stage1_entry_4_asid,
  output logic [13:0]  io_resp_bits_stage1_entry_4_vmid,
  output logic         io_resp_bits_stage1_entry_4_n,
  output logic [1:0]   io_resp_bits_stage1_entry_4_pbmt,
  output logic         io_resp_bits_stage1_entry_4_perm_d,
  output logic         io_resp_bits_stage1_entry_4_perm_a,
  output logic         io_resp_bits_stage1_entry_4_perm_g,
  output logic         io_resp_bits_stage1_entry_4_perm_u,
  output logic         io_resp_bits_stage1_entry_4_perm_x,
  output logic         io_resp_bits_stage1_entry_4_perm_w,
  output logic         io_resp_bits_stage1_entry_4_perm_r,
  output logic [1:0]   io_resp_bits_stage1_entry_4_level,
  output logic         io_resp_bits_stage1_entry_4_v,
  output logic [40:0]  io_resp_bits_stage1_entry_4_ppn,
  output logic [2:0]   io_resp_bits_stage1_entry_4_ppn_low,
  output logic         io_resp_bits_stage1_entry_4_pf,
  output logic         io_resp_bits_stage1_entry_4_cf,
  output logic [34:0]  io_resp_bits_stage1_entry_5_tag,
  output logic [15:0]  io_resp_bits_stage1_entry_5_asid,
  output logic [13:0]  io_resp_bits_stage1_entry_5_vmid,
  output logic         io_resp_bits_stage1_entry_5_n,
  output logic [1:0]   io_resp_bits_stage1_entry_5_pbmt,
  output logic         io_resp_bits_stage1_entry_5_perm_d,
  output logic         io_resp_bits_stage1_entry_5_perm_a,
  output logic         io_resp_bits_stage1_entry_5_perm_g,
  output logic         io_resp_bits_stage1_entry_5_perm_u,
  output logic         io_resp_bits_stage1_entry_5_perm_x,
  output logic         io_resp_bits_stage1_entry_5_perm_w,
  output logic         io_resp_bits_stage1_entry_5_perm_r,
  output logic [1:0]   io_resp_bits_stage1_entry_5_level,
  output logic         io_resp_bits_stage1_entry_5_v,
  output logic [40:0]  io_resp_bits_stage1_entry_5_ppn,
  output logic [2:0]   io_resp_bits_stage1_entry_5_ppn_low,
  output logic         io_resp_bits_stage1_entry_5_pf,
  output logic         io_resp_bits_stage1_entry_5_cf,
  output logic [34:0]  io_resp_bits_stage1_entry_6_tag,
  output logic [15:0]  io_resp_bits_stage1_entry_6_asid,
  output logic [13:0]  io_resp_bits_stage1_entry_6_vmid,
  output logic         io_resp_bits_stage1_entry_6_n,
  output logic [1:0]   io_resp_bits_stage1_entry_6_pbmt,
  output logic         io_resp_bits_stage1_entry_6_perm_d,
  output logic         io_resp_bits_stage1_entry_6_perm_a,
  output logic         io_resp_bits_stage1_entry_6_perm_g,
  output logic         io_resp_bits_stage1_entry_6_perm_u,
  output logic         io_resp_bits_stage1_entry_6_perm_x,
  output logic         io_resp_bits_stage1_entry_6_perm_w,
  output logic         io_resp_bits_stage1_entry_6_perm_r,
  output logic [1:0]   io_resp_bits_stage1_entry_6_level,
  output logic         io_resp_bits_stage1_entry_6_v,
  output logic [40:0]  io_resp_bits_stage1_entry_6_ppn,
  output logic [2:0]   io_resp_bits_stage1_entry_6_ppn_low,
  output logic         io_resp_bits_stage1_entry_6_pf,
  output logic         io_resp_bits_stage1_entry_6_cf,
  output logic [34:0]  io_resp_bits_stage1_entry_7_tag,
  output logic [15:0]  io_resp_bits_stage1_entry_7_asid,
  output logic [13:0]  io_resp_bits_stage1_entry_7_vmid,
  output logic         io_resp_bits_stage1_entry_7_n,
  output logic [1:0]   io_resp_bits_stage1_entry_7_pbmt,
  output logic         io_resp_bits_stage1_entry_7_perm_d,
  output logic         io_resp_bits_stage1_entry_7_perm_a,
  output logic         io_resp_bits_stage1_entry_7_perm_g,
  output logic         io_resp_bits_stage1_entry_7_perm_u,
  output logic         io_resp_bits_stage1_entry_7_perm_x,
  output logic         io_resp_bits_stage1_entry_7_perm_w,
  output logic         io_resp_bits_stage1_entry_7_perm_r,
  output logic [1:0]   io_resp_bits_stage1_entry_7_level,
  output logic         io_resp_bits_stage1_entry_7_v,
  output logic [40:0]  io_resp_bits_stage1_entry_7_ppn,
  output logic [2:0]   io_resp_bits_stage1_entry_7_ppn_low,
  output logic         io_resp_bits_stage1_entry_7_pf,
  output logic         io_resp_bits_stage1_entry_7_cf,
  output logic         io_resp_bits_stage1_pteidx_0,
  output logic         io_resp_bits_stage1_pteidx_1,
  output logic         io_resp_bits_stage1_pteidx_2,
  output logic         io_resp_bits_stage1_pteidx_3,
  output logic         io_resp_bits_stage1_pteidx_4,
  output logic         io_resp_bits_stage1_pteidx_5,
  output logic         io_resp_bits_stage1_pteidx_6,
  output logic         io_resp_bits_stage1_pteidx_7,
  output logic         io_resp_bits_stage1_not_super,
  output logic         io_resp_bits_isHptwReq,
  output logic         io_resp_bits_toHptw_l3Hit,
  output logic         io_resp_bits_toHptw_l2Hit,
  output logic         io_resp_bits_toHptw_l1Hit,
  output logic [35:0]  io_resp_bits_toHptw_ppn,
  output logic [2:0]   io_resp_bits_toHptw_id,
  output logic [37:0]  io_resp_bits_toHptw_resp_entry_tag,
  output logic [13:0]  io_resp_bits_toHptw_resp_entry_vmid,
  output logic         io_resp_bits_toHptw_resp_entry_n,
  output logic [1:0]   io_resp_bits_toHptw_resp_entry_pbmt,
  output logic [37:0]  io_resp_bits_toHptw_resp_entry_ppn,
  output logic         io_resp_bits_toHptw_resp_entry_perm_d,
  output logic         io_resp_bits_toHptw_resp_entry_perm_a,
  output logic         io_resp_bits_toHptw_resp_entry_perm_g,
  output logic         io_resp_bits_toHptw_resp_entry_perm_u,
  output logic         io_resp_bits_toHptw_resp_entry_perm_x,
  output logic         io_resp_bits_toHptw_resp_entry_perm_w,
  output logic         io_resp_bits_toHptw_resp_entry_perm_r,
  output logic [1:0]   io_resp_bits_toHptw_resp_entry_level,
  output logic         io_resp_bits_toHptw_resp_gpf,
  output logic         io_resp_bits_toHptw_bypassed,
  output logic         io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check,
  output logic [3:0]   io_resp_bits_toHptw_bitmapCheck_hitway,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_pte,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_ptes_0,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_ptes_1,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_ptes_2,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_ptes_3,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_ptes_4,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_ptes_5,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_ptes_6,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_ptes_7,
  output logic         io_resp_bits_toHptw_bitmapCheck_fromSP,
  output logic [1:0]   io_resp_bits_toHptw_bitmapCheck_SPlevel,
  input  logic         io_refill_valid,
  input  logic [511:0] io_refill_bits_ptes,
  input  logic         io_refill_bits_levelOH_sp,
  input  logic         io_refill_bits_levelOH_l0,
  input  logic         io_refill_bits_levelOH_l1,
  input  logic         io_refill_bits_levelOH_l2,
  input  logic         io_refill_bits_levelOH_l3,
  input  logic [37:0]  io_refill_bits_req_info_dup_0_vpn,
  input  logic [1:0]   io_refill_bits_req_info_dup_0_s2xlate,
  input  logic [1:0]   io_refill_bits_req_info_dup_0_source,
  input  logic [37:0]  io_refill_bits_req_info_dup_1_vpn,
  input  logic [1:0]   io_refill_bits_req_info_dup_1_s2xlate,
  input  logic [1:0]   io_refill_bits_req_info_dup_1_source,
  input  logic [37:0]  io_refill_bits_req_info_dup_2_vpn,
  input  logic [1:0]   io_refill_bits_req_info_dup_2_s2xlate,
  input  logic [1:0]   io_refill_bits_req_info_dup_2_source,
  input  logic [1:0]   io_refill_bits_level_dup_0,
  input  logic [1:0]   io_refill_bits_level_dup_2,
  input  logic [63:0]  io_refill_bits_sel_pte_dup_0,
  input  logic [63:0]  io_refill_bits_sel_pte_dup_2,
  output logic [3:0]   io_l0_way_info,
  input  logic         io_sfence_dup_0_valid,
  input  logic         io_sfence_dup_0_bits_rs1,
  input  logic         io_sfence_dup_0_bits_rs2,
  input  logic [49:0]  io_sfence_dup_0_bits_addr,
  input  logic [15:0]  io_sfence_dup_0_bits_id,
  input  logic         io_sfence_dup_0_bits_hv,
  input  logic         io_sfence_dup_0_bits_hg,
  input  logic         io_sfence_dup_1_valid,
  input  logic [15:0]  io_sfence_dup_1_bits_id,
  input  logic         io_sfence_dup_2_valid,
  input  logic         io_sfence_dup_2_bits_rs1,
  input  logic         io_sfence_dup_2_bits_rs2,
  input  logic [15:0]  io_sfence_dup_2_bits_id,
  input  logic [15:0]  io_csr_dup_0_satp_asid,
  input  logic         io_csr_dup_0_satp_changed,
  input  logic [15:0]  io_csr_dup_0_vsatp_asid,
  input  logic         io_csr_dup_0_vsatp_changed,
  input  logic [3:0]   io_csr_dup_0_hgatp_mode,
  input  logic [15:0]  io_csr_dup_0_hgatp_vmid,
  input  logic         io_csr_dup_0_hgatp_changed,
  input  logic         io_csr_dup_0_mbmc_BME,
  input  logic         io_csr_dup_0_mbmc_CMODE,
  input  logic         io_csr_dup_0_priv_virt,
  input  logic         io_csr_dup_0_priv_virt_changed,
  input  logic [15:0]  io_csr_dup_1_satp_asid,
  input  logic         io_csr_dup_1_satp_changed,
  input  logic [15:0]  io_csr_dup_1_vsatp_asid,
  input  logic         io_csr_dup_1_vsatp_changed,
  input  logic [3:0]   io_csr_dup_1_hgatp_mode,
  input  logic [15:0]  io_csr_dup_1_hgatp_vmid,
  input  logic         io_csr_dup_1_hgatp_changed,
  input  logic         io_csr_dup_1_priv_virt,
  input  logic         io_csr_dup_1_priv_virt_changed,
  input  logic [15:0]  io_csr_dup_2_satp_asid,
  input  logic         io_csr_dup_2_satp_changed,
  input  logic [15:0]  io_csr_dup_2_vsatp_asid,
  input  logic         io_csr_dup_2_vsatp_changed,
  input  logic [3:0]   io_csr_dup_2_hgatp_mode,
  input  logic [15:0]  io_csr_dup_2_hgatp_vmid,
  input  logic         io_csr_dup_2_hgatp_changed,
  input  logic         io_csr_dup_2_priv_virt,
  input  logic         io_csr_dup_2_priv_virt_changed,
  output logic         io_bitmap_wakeup_ready,
  input  logic         io_bitmap_wakeup_valid,
  input  logic [5:0]   io_bitmap_wakeup_bits_setIndex,
  input  logic [37:0]  io_bitmap_wakeup_bits_tag,
  input  logic [3:0]   io_bitmap_wakeup_bits_way_info,
  input  logic [2:0]   io_bitmap_wakeup_bits_pte_index,
  input  logic         io_bitmap_wakeup_bits_check_success,
  input  logic [1:0]   io_bitmap_wakeup_bits_s2xlate,
  output logic [5:0]   io_perf_0_value,
  output logic [5:0]   io_perf_1_value,
  output logic [5:0]   io_perf_2_value,
  output logic [5:0]   io_perf_3_value,
  output logic [5:0]   io_perf_4_value,
  output logic [5:0]   io_perf_5_value,
  output logic [5:0]   io_perf_6_value,
  output logic [5:0]   io_perf_7_value,
  input  logic [5:0]   boreChildrenBd_bore_array,
  input  logic         boreChildrenBd_bore_all,
  input  logic         boreChildrenBd_bore_req,
  output logic         boreChildrenBd_bore_ack,
  input  logic         boreChildrenBd_bore_writeen,
  input  logic         boreChildrenBd_bore_be,
  input  logic [2:0]   boreChildrenBd_bore_addr,
  input  logic [130:0] boreChildrenBd_bore_indata,
  input  logic         boreChildrenBd_bore_readen,
  input  logic [2:0]   boreChildrenBd_bore_addr_rd,
  output logic [130:0] boreChildrenBd_bore_outdata,
  input  logic [6:0]   boreChildrenBd_bore_1_array,
  input  logic         boreChildrenBd_bore_1_all,
  input  logic         boreChildrenBd_bore_1_req,
  output logic         boreChildrenBd_bore_1_ack,
  input  logic         boreChildrenBd_bore_1_writeen,
  input  logic [1:0]   boreChildrenBd_bore_1_be,
  input  logic [6:0]   boreChildrenBd_bore_1_addr,
  input  logic [113:0] boreChildrenBd_bore_1_indata,
  input  logic         boreChildrenBd_bore_1_readen,
  input  logic [6:0]   boreChildrenBd_bore_1_addr_rd,
  output logic [113:0] boreChildrenBd_bore_1_outdata,
  input  logic         sigFromSrams_bore_ram_hold,
  input  logic         sigFromSrams_bore_ram_bypass,
  input  logic         sigFromSrams_bore_ram_bp_clken,
  input  logic         sigFromSrams_bore_ram_aux_clk,
  input  logic         sigFromSrams_bore_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_ram_mcp_hold,
  input  logic         sigFromSrams_bore_cgen,
  input  logic         sigFromSrams_bore_1_ram_hold,
  input  logic         sigFromSrams_bore_1_ram_bypass,
  input  logic         sigFromSrams_bore_1_ram_bp_clken,
  input  logic         sigFromSrams_bore_1_ram_aux_clk,
  input  logic         sigFromSrams_bore_1_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_1_ram_mcp_hold,
  input  logic         sigFromSrams_bore_1_cgen,
  input  logic         sigFromSrams_bore_2_ram_hold,
  input  logic         sigFromSrams_bore_2_ram_bypass,
  input  logic         sigFromSrams_bore_2_ram_bp_clken,
  input  logic         sigFromSrams_bore_2_ram_aux_clk,
  input  logic         sigFromSrams_bore_2_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_2_ram_mcp_hold,
  input  logic         sigFromSrams_bore_2_cgen,
  input  logic         sigFromSrams_bore_3_ram_hold,
  input  logic         sigFromSrams_bore_3_ram_bypass,
  input  logic         sigFromSrams_bore_3_ram_bp_clken,
  input  logic         sigFromSrams_bore_3_ram_aux_clk,
  input  logic         sigFromSrams_bore_3_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_3_ram_mcp_hold,
  input  logic         sigFromSrams_bore_3_cgen,
  input  logic         sigFromSrams_bore_4_ram_hold,
  input  logic         sigFromSrams_bore_4_ram_bypass,
  input  logic         sigFromSrams_bore_4_ram_bp_clken,
  input  logic         sigFromSrams_bore_4_ram_aux_clk,
  input  logic         sigFromSrams_bore_4_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_4_ram_mcp_hold,
  input  logic         sigFromSrams_bore_4_cgen,
  input  logic         sigFromSrams_bore_5_ram_hold,
  input  logic         sigFromSrams_bore_5_ram_bypass,
  input  logic         sigFromSrams_bore_5_ram_bp_clken,
  input  logic         sigFromSrams_bore_5_ram_aux_clk,
  input  logic         sigFromSrams_bore_5_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_5_ram_mcp_hold,
  input  logic         sigFromSrams_bore_5_cgen,
  input  logic         sigFromSrams_bore_6_ram_hold,
  input  logic         sigFromSrams_bore_6_ram_bypass,
  input  logic         sigFromSrams_bore_6_ram_bp_clken,
  input  logic         sigFromSrams_bore_6_ram_aux_clk,
  input  logic         sigFromSrams_bore_6_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_6_ram_mcp_hold,
  input  logic         sigFromSrams_bore_6_cgen,
  input  logic         sigFromSrams_bore_7_ram_hold,
  input  logic         sigFromSrams_bore_7_ram_bypass,
  input  logic         sigFromSrams_bore_7_ram_bp_clken,
  input  logic         sigFromSrams_bore_7_ram_aux_clk,
  input  logic         sigFromSrams_bore_7_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_7_ram_mcp_hold,
  input  logic         sigFromSrams_bore_7_cgen,
  input  logic         sigFromSrams_bore_8_ram_hold,
  input  logic         sigFromSrams_bore_8_ram_bypass,
  input  logic         sigFromSrams_bore_8_ram_bp_clken,
  input  logic         sigFromSrams_bore_8_ram_aux_clk,
  input  logic         sigFromSrams_bore_8_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_8_ram_mcp_hold,
  input  logic         sigFromSrams_bore_8_cgen,
  input  logic         sigFromSrams_bore_9_ram_hold,
  input  logic         sigFromSrams_bore_9_ram_bypass,
  input  logic         sigFromSrams_bore_9_ram_bp_clken,
  input  logic         sigFromSrams_bore_9_ram_aux_clk,
  input  logic         sigFromSrams_bore_9_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_9_ram_mcp_hold,
  input  logic         sigFromSrams_bore_9_cgen,
  input  logic         sigFromSrams_bore_10_ram_hold,
  input  logic         sigFromSrams_bore_10_ram_bypass,
  input  logic         sigFromSrams_bore_10_ram_bp_clken,
  input  logic         sigFromSrams_bore_10_ram_aux_clk,
  input  logic         sigFromSrams_bore_10_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_10_ram_mcp_hold,
  input  logic         sigFromSrams_bore_10_cgen,
  input  logic         sigFromSrams_bore_11_ram_hold,
  input  logic         sigFromSrams_bore_11_ram_bypass,
  input  logic         sigFromSrams_bore_11_ram_bp_clken,
  input  logic         sigFromSrams_bore_11_ram_aux_clk,
  input  logic         sigFromSrams_bore_11_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_11_ram_mcp_hold,
  input  logic         sigFromSrams_bore_11_cgen,
  input  logic         sigFromSrams_bore_12_ram_hold,
  input  logic         sigFromSrams_bore_12_ram_bypass,
  input  logic         sigFromSrams_bore_12_ram_bp_clken,
  input  logic         sigFromSrams_bore_12_ram_aux_clk,
  input  logic         sigFromSrams_bore_12_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_12_ram_mcp_hold,
  input  logic         sigFromSrams_bore_12_cgen,
  input  logic         sigFromSrams_bore_13_ram_hold,
  input  logic         sigFromSrams_bore_13_ram_bypass,
  input  logic         sigFromSrams_bore_13_ram_bp_clken,
  input  logic         sigFromSrams_bore_13_ram_aux_clk,
  input  logic         sigFromSrams_bore_13_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_13_ram_mcp_hold,
  input  logic         sigFromSrams_bore_13_cgen,
  input  logic         sigFromSrams_bore_14_ram_hold,
  input  logic         sigFromSrams_bore_14_ram_bypass,
  input  logic         sigFromSrams_bore_14_ram_bp_clken,
  input  logic         sigFromSrams_bore_14_ram_aux_clk,
  input  logic         sigFromSrams_bore_14_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_14_ram_mcp_hold,
  input  logic         sigFromSrams_bore_14_cgen,
  input  logic         sigFromSrams_bore_15_ram_hold,
  input  logic         sigFromSrams_bore_15_ram_bypass,
  input  logic         sigFromSrams_bore_15_ram_bp_clken,
  input  logic         sigFromSrams_bore_15_ram_aux_clk,
  input  logic         sigFromSrams_bore_15_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_15_ram_mcp_hold,
  input  logic         sigFromSrams_bore_15_cgen,
  input  logic         sigFromSrams_bore_16_ram_hold,
  input  logic         sigFromSrams_bore_16_ram_bypass,
  input  logic         sigFromSrams_bore_16_ram_bp_clken,
  input  logic         sigFromSrams_bore_16_ram_aux_clk,
  input  logic         sigFromSrams_bore_16_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_16_ram_mcp_hold,
  input  logic         sigFromSrams_bore_16_cgen,
  input  logic         cg_bore_cgen
);

  import xs_ptwcache_pkg::*;

  // ---------------------------------------------------------------------------
  // §1 四级流水与反压（已追清：golden PtwCache.sv:3085-3125, 44764-44765）
  //
  //   stageReq(组合) → stageDelay(valid) → stageCheck(valid_1) → stageResp(valid_2)
  // 每一级就是一个 PipelineConnect：下一级空或下下级能收，本级就 ready。
  logic valid_delay, valid_check, valid_resp;

  logic stage_req_ready, stage_delay_ready, stage_check_ready, stage_resp_ready;

  // refill 与 bitmap wakeup 都要抢 SRAM 的那一个读端口（sramSinglePort=true），
  // 所以它们有效的那一拍，入口直接不收新请求——这是本模块唯一的入口节流。
  logic rw_harzad;    // 名字沿用 golden/Chisel 的拼写（rwHarzad），便于对照
  logic wakeup_harzad;
  logic wakeup_blocked;

  assign rw_harzad      = io_refill_valid;
  // refill 抢赢 wakeup：两者同拍有效时 wakeup 不被接受（golden:5909/45294）。
  // ★按 golden 的表达式形状照抄，不化简成 `valid & ~refill`★：值恒等不等于
  // 可证等价，合并过的形状在 FM 上要多绕一圈。
  assign wakeup_blocked = io_bitmap_wakeup_valid & io_refill_valid;
  assign io_bitmap_wakeup_ready = ~wakeup_blocked;
  assign wakeup_harzad  = ~wakeup_blocked & io_bitmap_wakeup_valid;

  assign stage_resp_ready  = ~valid_resp  | io_resp_ready;
  assign stage_check_ready = ~valid_check | stage_resp_ready;
  assign stage_delay_ready = ~valid_delay | stage_check_ready;
  assign stage_req_ready   = stage_delay_ready & ~(rw_harzad | wakeup_harzad);

  logic left_fire_req;    // stageReq   → stageDelay
  logic left_fire_delay;  // stageDelay → stageCheck
  logic left_fire_check;  // stageCheck → stageResp
  assign left_fire_req   = io_req_valid & stage_delay_ready & ~(rw_harzad | wakeup_harzad);
  assign left_fire_delay = valid_delay  & stage_check_ready;
  assign left_fire_check = valid_check  & stage_resp_ready;

  // SRAM 读请求发出的那一拍（golden `_s2x_info_T_1`）。它与 left_fire_req 展开后
  // 是同一个值（stageReq_ready 本身就含 stage_delay_ready 与那两个 harzad），
  // golden 仍保留两个名字；★这里照抄两份而不合并★——"值恒等"不等于"可证等价"，
  // 合并过的形状在 FM 上要多绕一圈。
  logic sram_read_fire;
  assign sram_read_fire = stage_req_ready & io_req_valid;

  assign io_req_ready  = stage_req_ready;
  assign io_resp_valid = valid_resp;

  // ---------------------------------------------------------------------------
  // §2 三份 dup 的归属与 flush（已追清：golden:3069-3078, 6647/6785/6831/7418/8289）
  //
  //   flush_dup_N = sfence_dup_N.valid | csr_dup_N.{satp,vsatp,hgatp}_changed
  //                 | csr_dup_N.priv_virt_changed
  // ★三份必须各写各的，禁止合并★：golden 里 dup_0 管 l0/sp、dup_1 管 l1、
  // dup_2 管 l2/l3，连时钟门控都分开（见 §5）。Predictor 那一轮把一份共用信号
  // 写成单份，UT 全绿而 FM 炸出 504 个失配点——同一个形态。
  logic flush_dup_0, flush_dup_1, flush_dup_2;

  assign flush_dup_0 = io_sfence_dup_0_valid | io_csr_dup_0_satp_changed
                     | io_csr_dup_0_vsatp_changed | io_csr_dup_0_hgatp_changed
                     | io_csr_dup_0_priv_virt_changed;
  assign flush_dup_1 = io_sfence_dup_1_valid | io_csr_dup_1_satp_changed
                     | io_csr_dup_1_vsatp_changed | io_csr_dup_1_hgatp_changed
                     | io_csr_dup_1_priv_virt_changed;
  assign flush_dup_2 = io_sfence_dup_2_valid | io_csr_dup_2_satp_changed
                     | io_csr_dup_2_vsatp_changed | io_csr_dup_2_hgatp_changed
                     | io_csr_dup_2_priv_virt_changed;

  // bitmap 检查总开关：BME=1 且 CMODE=0（golden:3066）
  logic bitmap_enable;
  assign bitmap_enable = io_csr_dup_0_mbmc_BME & ~io_csr_dup_0_mbmc_CMODE;

  // 查找时把 allStage 折成 onlyStage1（golden `h_search`，:27249-27252）
  logic [1:0] h_search;
  assign h_search = (io_req_bits_req_info_s2xlate == H_ONLY_STAGE2)
                  ? H_ONLY_STAGE2
                  : {1'b0, (io_req_bits_req_info_s2xlate == H_ONLY_STAGE1)
                           | (&io_req_bits_req_info_s2xlate)};

  // ---------------------------------------------------------------------------
  // §3 存储声明（结构已追清，更新方程见 §8 未追清清单）
  //
  // 寄存器阵列三级：l3 / l2 / sp。l1 / l0 的数据在 SRAM 里，只有元数据留在核内。
  l3_entry_t [L3_N-1:0] l3_entry;
  l2_entry_t [L2_N-1:0] l2_entry;
  sp_entry_t [SP_N-1:0] sp_entry;

  // 有效位向量（★带复位★）与 global 位向量（★不带复位★）—— 见 §4。
  logic [L3_N-1:0]            l3v;
  logic [L2_N-1:0]            l2v;
  logic [L1_SETS*L1_WAYS-1:0] l1v;
  logic [L0_SETS*L0_WAYS-1:0] l0v;
  logic [SP_N-1:0]            spv;

  logic [L3_N-1:0]            l3g;
  logic [L2_N-1:0]            l2g;
  logic [L1_SETS*L1_WAYS-1:0] l1g;
  logic [L0_SETS*L0_WAYS-1:0] l0g;
  logic [SP_N-1:0]            spg;

  // 每条表项的两阶段标记 h（不复位）
  logic [1:0] l3h [L3_N];
  logic [1:0] l2h [L2_N];
  logic [1:0] l1h [L1_SETS][L1_WAYS];
  logic [1:0] l0h [L0_SETS][L0_WAYS];
  logic [1:0] sph [SP_N];

  // l1/l0 的影子元数据：SRAM 一拍只能读一组，而 sfence 要对**全阵列**逐条比对，
  // 所以比对用的 asid/vmid/vpn 另有一份 flop 副本，且存的是 XORFold 折叠值。
  // ★照抄这份冗余，不要"优化"成直接读 SRAM★。
  logic [HASH_ASID_W-1:0] l1asids [L1_SETS][L1_WAYS];
  logic [HASH_VMID_W-1:0] l1vmids [L1_SETS][L1_WAYS];
  logic [HASH_ASID_W-1:0] l0asids [L0_SETS][L0_WAYS];
  logic [HASH_VMID_W-1:0] l0vmids [L0_SETS][L0_WAYS];
  logic [HASH_VPN_W-1:0]  l0vpns  [L0_SETS][L0_WAYS];

  // 每个 l0 PTE 槽一位「bitmap 已检查通过」标记（★带复位★）。
  // golden 把它展平成 2048 个标量寄存器，占了整份 golden 三成行数。
  logic [SECTOR_N-1:0] l0_bitmap [L0_SETS][L0_WAYS];

  // ---------------------------------------------------------------------------
  // §4 复位域（已追清：golden 只有一个 always@(posedge clock or posedge reset)）
  //
  // golden 实测：2143 个寄存器带**异步高有效**复位，2749 个**完全不复位**，两组零交集。
  //   带复位：l3v/l2v/l1v/l0v/spv、l0_bitmap、替换状态、各级流水 valid、bypass valid
  //   不复位：全部 tag/asid/vmid/ppn/perm 载荷、★l3g/l2g/l1g/l0g/spg★、
  //           l0h/l0vpns/l0asids/l0vmids/l1h/... 影子元数据、全部流水载荷
  // ★把 g 向量也复位掉是真 bug，而 elaborate 与 lint 都不会报★。
  // ★本文件的两个 always_ff（复位域 / 非复位域）统一写在 §11，不在这儿——
  //  l3v/l2v/l1v/l0v/spv 既被复位也被回填/sfence 改写，必须在同一个 always_ff 里。★

  // ---------------------------------------------------------------------------
  // §5 时钟门控与 SRAM 端口仲裁（已追清：golden:44750-44763, 43250/43557）
  //
  // l0 与 l1 各挂一个 ClockGate，开门条件**分别**用 flush_dup_0 / flush_dup_1：
  //   l0.CK 开 = wakeup | 读请求 | (~flush_dup_0 & levelOH.l0) | mbist l0 请求
  //   l1.CK 开 =          读请求 | (~flush_dup_1 & levelOH.l1) | mbist l1 请求
  logic te_cgen;
  assign te_cgen = cg_bore_cgen;

  logic l0_clk, l1_clk;
  logic l0_cg_en, l1_cg_en;
  assign l0_cg_en = wakeup_harzad | sram_read_fire
                  | (~flush_dup_0 & io_refill_bits_levelOH_l0) | boreChildrenBd_bore_1_req;
  assign l1_cg_en = sram_read_fire
                  | (~flush_dup_1 & io_refill_bits_levelOH_l1) | boreChildrenBd_bore_req;

  // ★实例名沿用 golden（ClockGate / ClockGate_1），不改成更好听的名字★：
  // 本层次有**两个**同类型实例，docs/hier_rebind_map.tsv 只能靠实例名把 golden 路径
  // 映到重写件路径（scripts/hier_map.py 的 auto_deeper 规则）。改名会让这两行变成
  // UNRESOLVED —— 而 UNRESOLVED 的后果是 DFT/perf 探针**静默探到空**，不会报错。
  ClockGate ClockGate   (.TE(te_cgen), .E(l0_cg_en), .CK(clock), .Q(l0_clk));
  ClockGate ClockGate_1 (.TE(te_cgen), .E(l1_cg_en), .CK(clock), .Q(l1_clk));

  // SRAM 读口：l1 只服务正常请求；l0 还要让 bitmap wakeup 插队回读。
  logic                l1_r_valid, l0_r_valid;
  logic [1:0]          l1_r_set;
  logic [5:0]          l0_r_set;
  assign l1_r_valid = sram_read_fire;
  assign l1_r_set   = io_req_bits_req_info_vpn[13:12];
  assign l0_r_valid = wakeup_harzad | sram_read_fire;
  assign l0_r_set   = wakeup_harzad ? io_bitmap_wakeup_bits_tag[8:3]
                                    : io_req_bits_req_info_vpn[8:3];

  // ---------------------------------------------------------------------------
  // §6 各级 refill 使能（l1 已追清；其余只追清了 dup 归属与形状）
  //
  // l1 是唯一一条没有 leaf/canRefill 过滤的：只要这一拍 levelOH 指向 l1 且没被冲刷。
  logic l1_refill;
  assign l1_refill = ~flush_dup_1 & io_refill_bits_levelOH_l1;

  // l3/l2 用 dup_2、l0/sp 用 dup_0，且各自带 leaf / canRefill / napot 过滤——
  // 这些过滤项的完整方程还没追清（见 §8），暂不在此下定义。

  // ---------------------------------------------------------------------------
  // §7 替换策略状态（拓扑已追清，PLRU 方程未追清）
  //
  //   l3/l2/sp : PseudoLRU(16)  → 各一个 15 位 state_reg
  //   l1       : SetAssocLRU(4 组 2 路) → 每组 1 位
  //   l0       : SetAssocLRU(64 组 4 路) → 每组 3 位
  //
  // ★golden 自带一个真 bug，必须照抄（bug-for-bug）★：
  //   Chisel PageTableCache.scala:908 在 `when (l3Refill)` 里访问的是 **ptwl2replace**
  //   而不是 ptwl3replace。golden 展开后可验证：
  //     - l3 的 PLRU（state_reg）  只有**一个**写者：l3 命中（PtwCache.sv:26779）
  //     - l2 的 PLRU（state_reg_1）有**三个**写者，优先级 l2Refill > l3Refill > l2命中
  //       （PtwCache.sv:26808 / 26837 / 26866），其中 l3Refill 那一支用的是 l3_refillIdx
  //   也就是说：l3 回填不更新 l3 的 PLRU，反而污染 l2 的 PLRU。
  //   影响只在性能（选错受害者），不影响功能正确性。重写必须复现，不许"修好"。
  logic [14:0] plru_l3, plru_l2, plru_sp;
  logic        plru_l1 [L1_SETS];
  logic [2:0]  plru_l0 [L0_SETS];

  // ---------------------------------------------------------------------------
  // §6.1 PTE 谓词（对照 Chisel PteBundle 的 isLeaf/isPf/isGpf/canRefill/…）
  //
  //  PTE 位布局（PteBundle 声明顺序 = MSB→LSB，KunminghuV2 下 PAddrBits=48）：
  //    [63]     n         Svnapot
  //    [62:61]  pbmt
  //    [60:54]  reserved  ★非零即 page fault★
  //    [53:46]  ppn_high  ★超出 ppnLen 的高位，非零即 access fault★
  //    [45:10]  ppn
  //    [9:8]    rsw
  //    [7:0]    perm = {d, a, g, u, x, w, r, v}
  //  getPPN() = Cat(ppn_high, ppn) 截到 gvpnLen=38 位 ⇒ 就是 pte[47:10]。
  //
  //  这几个谓词在 golden 里被 firtool 按每个 PTE、每个 s2xlate 取值各展开一遍
  //  （仅 l1 的 8 个 vs 位就占了约 500 行）。这里写成函数，调用点把 level 传成常量。
  localparam int PTE_V = 0, PTE_R = 1, PTE_W = 2, PTE_X = 3;
  localparam int PTE_U = 4, PTE_G = 5, PTE_A = 6, PTE_D = 7, PTE_N = 63;

  function automatic logic pte_is_leaf(input logic [PTE_W_BITS-1:0] p);
    return (p[PTE_R] | p[PTE_X] | p[PTE_W]) & p[PTE_V];
  endfunction

  // isNext：指向下一级页表的非叶子项
  function automatic logic pte_is_next(input logic [PTE_W_BITS-1:0] p);
    return ~(p[PTE_R] | p[PTE_X] | p[PTE_W]) & p[PTE_V];
  endfunction

  // 大页的 ppn 低位必须对齐到该级页大小；level 0 是 4KB 叶子，恒对齐。
  function automatic logic pte_unaligned(input logic [PTE_W_BITS-1:0] p,
                                         input logic [1:0]            level);
    logic aligned;
    aligned = (level == 2'd0)
            | ((level == 2'd1) & (p[18:10] == 9'd0))
            | ((level == 2'd2) & (p[27:10] == 18'd0))
            | ((level == 2'd3) & (p[36:10] == 27'd0));
    return pte_is_leaf(p) & ~aligned;
  endfunction

  function automatic logic pte_is_af(input logic [PTE_W_BITS-1:0] p);
    return (|p[53:46]) & p[PTE_V];
  endfunction

  // 两阶段翻译下，stage-1 的 PTE 指出的 GPA 若超出 hgatp 模式的 GPA 位宽 ⇒ guest page fault
  function automatic logic pte_is_stage1_gpf(input logic [PTE_W_BITS-1:0] p,
                                             input logic [3:0]            mode);
    logic [14:0] hi;
    hi = (mode == 4'h8) ? p[53:39]              // Sv39x4: GPAddrBits=41 ⇒ 右移 29 位
       : (mode == 4'h9) ? {9'h0, p[53:48]}      // Sv48x4: GPAddrBits=50 ⇒ 右移 38 位
       :                  15'h0;
    return (|hi) & p[PTE_V];
  endfunction

  // ★if/else-if 链就是 Chisel 的 when/elsewhen 优先级链，不要改写成一串或★
  function automatic logic pte_is_pf(input logic [PTE_W_BITS-1:0] p,
                                     input logic [1:0]            level,
                                     input logic                  pbmte);
    if (|p[60:54])                                 return 1'b1;
    else if ((&p[62:61]) | (~pbmte & (|p[62:61]))) return 1'b1;
    else if (pte_is_next(p))
      return p[PTE_U] | p[PTE_A] | p[PTE_D] | p[PTE_N] | (|p[62:61]);
    else if (~p[PTE_V] | (~p[PTE_R] & p[PTE_W]))   return 1'b1;
    // 只支持 64KB napot（ppn[3:0]==4'b1000），且 napot 只能出现在叶子级。
    // ★`| (level != 0)` 这一项在 level>0 时其实是冗余的★：ppn[3:0]==8 蕴含
    // ppn[8:0]!=0，于是下一条 unaligned(level) 对同一批输入也会给 1。实测：
    // 把这一项删掉，20000 拍 × 430 根写端口的定向对照 errors 仍是 0（见
    // verif/study/PtwCache_refill）。**仍然照抄不删** —— 值恒等不等于可证等价，
    // 而且它直接对应 Chisel 的那条 elsewhen，删了就对不上意图了。
    else if (p[PTE_N] & ((p[13:10] != 4'h8) | (level != 2'd0))) return 1'b1;
    else                                           return pte_unaligned(p, level);
  endfunction

  // G 阶段对 VS 阶段而言是 LOAD，只查 A 位；D 位留给 L1 TLB 查。
  function automatic logic pte_is_gpf(input logic [PTE_W_BITS-1:0] p,
                                      input logic [1:0]            level,
                                      input logic                  pbmte);
    if (|p[60:54])                                 return 1'b1;
    else if ((&p[62:61]) | (~pbmte & (|p[62:61]))) return 1'b1;
    else if (pte_is_next(p))
      return p[PTE_U] | p[PTE_A] | p[PTE_D] | p[PTE_N] | (|p[62:61]);
    else if (~p[PTE_V] | (~p[PTE_R] & p[PTE_W]))   return 1'b1;
    else if (~p[PTE_U])                            return 1'b1;
    else if (p[PTE_N] & (p[13:10] != 4'h8))        return 1'b1;
    else if (pte_unaligned(p, level))              return 1'b1;
    else if (~p[PTE_A])                            return 1'b1;
    else                                           return 1'b0;
  endfunction

  function automatic logic pte_is_napot(input logic [PTE_W_BITS-1:0] p,
                                        input logic [1:0]            level);
    return pte_is_leaf(p) & p[PTE_N] & (p[13:10] == 4'h8) & (level == 2'd0);
  endfunction

  // 能不能进缓存：四种翻译模式各查各的错
  function automatic logic pte_can_refill(input logic [PTE_W_BITS-1:0] p,
                                          input logic [1:0]            level,
                                          input logic [1:0]            s2xlate,
                                          input logic                  pbmte,
                                          input logic [3:0]            mode);
    case (s2xlate)
      H_ALL_STAGE:   return ~pte_is_stage1_gpf(p, mode) & ~pte_is_pf(p, level, pbmte);
      H_ONLY_STAGE2: return ~pte_is_af(p)               & ~pte_is_gpf(p, level, pbmte);
      default:       return ~pte_is_af(p)               & ~pte_is_pf(p, level, pbmte);
    endcase
  endfunction

  // onlyPf：非虚拟化场景下"只是 page fault、不是 access fault"的叶子——
  // 这种项也进缓存（存 onlypf 位），下次命中直接回 pf，不必再走一遍内存。
  function automatic logic pte_only_pf(input logic [PTE_W_BITS-1:0] p,
                                       input logic [1:0]            level,
                                       input logic [1:0]            s2xlate,
                                       input logic                  pbmte);
    return (s2xlate == H_NO_S2XLATE) & pte_is_pf(p, level, pbmte) & ~pte_is_af(p);
  endfunction

  // ---------------------------------------------------------------------------
  // §6.2 回填写数据（已追清：golden:6548/6910/7418/7497/43311-43380/43931-44300）
  //
  //  io.refill.bits.ptes 是从内存取回来的一整行 512 位 = 8 个相邻 PTE。
  //  l1 与 l0 各把这一整行写进一条表项（组内 8 项），所以写数据是"整行 + 逐项有效位"。
  //  ★pbmte 只有一份，用的是 dup_0★——即使在 l1（dup_1）的 canRefill 里也是它。
  //  golden 就是这么混用的，照抄，别"顺手改成 dup_1"。
  logic [PTE_W_BITS-1:0] refill_pte [SECTOR_N];
  logic                  pbmte;
  logic                  l1_w_prefetch, l0_w_prefetch;
  logic                  l0_refill;

  assign pbmte = ((io_refill_bits_req_info_dup_0_s2xlate == H_ONLY_STAGE1)
                  | (&io_refill_bits_req_info_dup_0_s2xlate))
               ? io_csr_hPBMTE : io_csr_mPBMTE;

  for (genvar i = 0; i < SECTOR_N; i++) begin : g_refill_pte
    assign refill_pte[i] = io_refill_bits_ptes[PTE_W_BITS*i +: PTE_W_BITS];
  end

  // prefetch 位：请求来源 == 2 即预取（bSourceWidth 的 prefetchID）。每级用自己那份 dup。
  assign l1_w_prefetch = (io_refill_bits_req_info_dup_1_source == 2'd2);
  assign l0_w_prefetch = (io_refill_bits_req_info_dup_0_source == 2'd2);

  // l1（level=1，存 PDE）：某一项有效 ⇔ 能回填 且 **不是**叶子。
  logic [SECTOR_N-1:0] l1_w_vs;
  for (genvar i = 0; i < SECTOR_N; i++) begin : g_l1_wdata
    assign l1_w_vs[i] =
        pte_can_refill(refill_pte[i], 2'd1,
                       io_refill_bits_req_info_dup_1_s2xlate, pbmte,
                       io_csr_dup_1_hgatp_mode)
      & ~pte_is_leaf(refill_pte[i]);
  end

  // l0（level=0，存 PTE）：某一项有效 ⇔（能回填 且 **是**叶子）或 onlyPf；
  // 但整行里若有 napot 项就把该项拒掉（napot 归 sp 存，见 spRefill）。
  logic      [SECTOR_N-1:0] l0_w_vs;
  logic      [SECTOR_N-1:0] l0_w_onlypf;
  pte_perm_t                l0_w_perms [SECTOR_N];

  for (genvar i = 0; i < SECTOR_N; i++) begin : g_l0_wdata
    logic only_pf, deny_napot;
    assign only_pf    = pte_only_pf(refill_pte[i], 2'd0,
                                    io_refill_bits_req_info_dup_0_s2xlate, pbmte);
    assign deny_napot = pte_is_napot(refill_pte[i], 2'd0);

    assign l0_w_vs[i] =
        (  pte_can_refill(refill_pte[i], 2'd0,
                          io_refill_bits_req_info_dup_0_s2xlate, pbmte,
                          io_csr_dup_0_hgatp_mode) & pte_is_leaf(refill_pte[i])
         | only_pf) & ~deny_napot;
    assign l0_w_onlypf[i] = only_pf & ~deny_napot;

    // G 位：onlyStage2（G 阶段）的表项不带 global 语义，写进去恒 0。
    assign l0_w_perms[i].d = refill_pte[i][PTE_D];
    assign l0_w_perms[i].a = refill_pte[i][PTE_A];
    assign l0_w_perms[i].g = (io_refill_bits_req_info_dup_0_s2xlate != H_ONLY_STAGE2)
                           & refill_pte[i][PTE_G];
    assign l0_w_perms[i].u = refill_pte[i][PTE_U];
    assign l0_w_perms[i].x = refill_pte[i][PTE_X];
    assign l0_w_perms[i].w = refill_pte[i][PTE_W];
    assign l0_w_perms[i].r = refill_pte[i][PTE_R];
  end

  // l0 回填使能：napot 的叶子不进 l0（它走 sp），其余只看 flush 与 levelOH。
  // 判 napot 用的是走回来的**被选中那一个** PTE（sel_pte），不是整行。
  assign l0_refill = ~flush_dup_0 & io_refill_bits_levelOH_l0
                   & ~pte_is_napot(io_refill_bits_sel_pte_dup_0,
                                   io_refill_bits_level_dup_0);


  // ---- 写端口里**已追清**的部分（golden:6839 / 7497 / 43311-43313 / 43931-43935）----
  //  dup 归属再强调一次：l1 写用 dup_1，l0 写用 dup_0。写反了 UT 多半测不出来。
  logic [1:0]  l1_w_set;
  logic [23:0] l1_w_tag;
  logic [15:0] l1_w_asid;
  logic [13:0] l1_w_vmid;
  logic [5:0]  l0_w_set;
  logic [28:0] l0_w_tag;
  logic [15:0] l0_w_asid;
  logic [13:0] l0_w_vmid;

  assign l1_w_set  = io_refill_bits_req_info_dup_1_vpn[13:12];
  assign l1_w_tag  = io_refill_bits_req_info_dup_1_vpn[37:14];
  assign l1_w_vmid = io_csr_dup_1_hgatp_vmid[13:0];
  assign l1_w_asid = (|io_refill_bits_req_info_dup_1_s2xlate)
                   ? io_csr_dup_1_vsatp_asid : io_csr_dup_1_satp_asid;

  assign l0_w_set  = io_refill_bits_req_info_dup_0_vpn[8:3];
  assign l0_w_tag  = io_refill_bits_req_info_dup_0_vpn[37:9];
  assign l0_w_vmid = io_csr_dup_0_hgatp_vmid[13:0];
  assign l0_w_asid = (|io_refill_bits_req_info_dup_0_s2xlate)
                   ? io_csr_dup_0_vsatp_asid : io_csr_dup_0_satp_asid;

  // ---------------------------------------------------------------------------
  // §7.1 PseudoLRU —— 位布局与两个方程（已追清）
  //
  //  rocket-chip `PseudoLRU(n)` 用 n-1 位状态表示一棵满二叉树。**位序容易读反**，
  //  这里按 golden 实测把约定钉死（G1 PtwCache.sv:6657 取路 / 26808 更新）：
  //
  //    · 一棵覆盖 bits[hi:lo] 的子树，**根在最高位 hi**；
  //    · 根为 1 ⇒ "上半边(索引大的那半)更旧" ⇒ 取路时往**上半边**走，
  //      而上半边的状态位是 bits[hi-1 : lo+(sz-1)/2]（紧挨着根的那一段），
  //      下半边是 bits[lo+(sz-1)/2-1 : lo]。
  //    · 访问某一路后，路径上每个节点都被置成**指向另一边**（root <= ~idx[lvl]），
  //      且只有被走到的那一侧子树继续递归，另一侧原样保留。
  //
  //  16 路展开后就是 golden 那一串嵌套三目：bit14 是根，bits[13:7] 是上半(way 8-15)，
  //  bits[6:0] 是下半(way 0-7)；4 路是 bit2 根 / bit1 上半 / bit0 下半；
  //  2 路只有一位，取路 = 该位，访问后 = ~way。
  //
  //  ★不要把这两个函数"优化"成查表★：它们的形状就是 golden 的形状，
  //  改形状不影响仿真却会让 FM 多绕一圈。
  function automatic logic [3:0] plru16_way(input logic [14:0] s);
    int lo, sz, root;
    logic [3:0] w;
    lo = 0; sz = 15;
    for (int lvl = 3; lvl >= 0; lvl--) begin
      root   = lo + sz - 1;
      w[lvl] = s[root];
      sz     = (sz - 1) / 2;
      if (s[root]) lo = lo + sz;     // 走上半边；下半边 lo 不动
    end
    return w;
  endfunction

  function automatic logic [14:0] plru16_access(input logic [14:0] s,
                                                input logic [3:0]  idx);
    logic [14:0] n;
    int lo, sz, root;
    n = s; lo = 0; sz = 15;
    for (int lvl = 3; lvl >= 0; lvl--) begin
      root    = lo + sz - 1;
      n[root] = ~idx[lvl];
      sz      = (sz - 1) / 2;
      if (idx[lvl]) lo = lo + sz;
    end
    return n;
  endfunction

  function automatic logic [1:0] plru4_way(input logic [2:0] s);
    return {s[2], s[2] ? s[1] : s[0]};
  endfunction

  function automatic logic [2:0] plru4_access(input logic [2:0] s,
                                              input logic [1:0] way);
    return {~way[1],
            way[1] ? ~way[0] : s[1],
            way[1] ? s[0]    : ~way[0]};
  endfunction

  // ---------------------------------------------------------------------------
  // §7.2 replaceWrapper —— 「有空位先填空位，满了才问 PLRU」（已追清）
  //
  //  Chisel MMUConst.replaceWrapper(v, lru) = Mux(&v, lru, PriorityEncoder(~v))。
  //  golden 把 PriorityEncoder 展成了一棵"哪个子块有空位"的树（:6652-6675），
  //  值与最低无效位下标相同。这里写成朴素的优先查找，可读性优先。
  //  ★注意 l3/l2 用 16 项全局向量，l1/l0 用的是**本组**的那几位★。
  function automatic logic [3:0] replace_wrapper16(input logic [15:0] v,
                                                   input logic [3:0]  lru);
    if (&v) return lru;
    for (int i = 0; i < 16; i++)
      if (!v[i]) return i[3:0];
    return lru;                       // 到不了：&v 已在上面拦掉
  endfunction

  function automatic logic replace_wrapper_l1(input logic [1:0] v,
                                              input logic       lru);
    if (&v) return lru;
    return v[0];                      // v[0]=1 ⇒ 空的是 way1；否则 way0
  endfunction

  function automatic logic [1:0] replace_wrapper_l0(input logic [3:0] v,
                                                    input logic [1:0] lru);
    if (&v) return lru;
    for (int i = 0; i < 4; i++)
      if (!v[i]) return i[1:0];
    return lru;
  endfunction

  // ---------------------------------------------------------------------------
  // §7.3 受害者选择（已追清：golden:6657 / 6795 / 6835 / 7490 / 8329）
  //
  //  l3/l2/l0/l1 走 replaceWrapper（空位优先）；★sp 例外，直接用 PLRU★——
  //  Chisel 那行就是 `spreplace.way`，没套 replaceWrapper（PageTableCache.scala
  //  写着 "TODO: may be LRU"）。照抄，别顺手补上。
  logic [3:0] l3_refill_idx, l2_refill_idx, sp_refill_idx;
  logic       l1_victim_way;
  logic [1:0] l0_victim_way;
  logic [1:0] l1_w_set_v;      // 本组的 2 个 valid 位
  logic [3:0] l0_w_set_v;      // 本组的 4 个 valid 位

  assign l3_refill_idx = replace_wrapper16(l3v, plru16_way(plru_l3));
  assign l2_refill_idx = replace_wrapper16(l2v, plru16_way(plru_l2));
  assign sp_refill_idx = plru16_way(plru_sp);

  assign l1_w_set_v    = l1v[2*l1_w_set +: 2];
  assign l0_w_set_v    = l0v[4*l0_w_set +: 4];
  assign l1_victim_way = replace_wrapper_l1(l1_w_set_v, plru_l1[l1_w_set]);
  assign l0_victim_way = replace_wrapper_l0(l0_w_set_v, plru4_way(plru_l0[l0_w_set]));

  // SRAM 写掩码（golden:43369 / 44301）—— §8 占位表里的两根从这里毕业。
  logic [1:0] l1_w_waymask;
  logic [3:0] l0_w_waymask;
  assign l1_w_waymask = 2'h1 << l1_victim_way;
  assign l0_w_waymask = 4'h1 << l0_victim_way;

  // 整个 l1v/l0v 里被这次回填点中的那一位（golden l1_rfvOH / l0_rfvOH）。
  logic [L1_SETS*L1_WAYS-1:0] l1_rfv_oh;
  logic [L0_SETS*L0_WAYS-1:0] l0_rfv_oh;
  logic [L3_N-1:0]            l3_rf_oh;
  logic [L2_N-1:0]            l2_rf_oh;
  logic [SP_N-1:0]            sp_rf_oh;

  assign l1_rfv_oh = {{(L1_SETS*L1_WAYS-1){1'b0}}, 1'b1} << {l1_w_set, l1_victim_way};
  assign l0_rfv_oh = {{(L0_SETS*L0_WAYS-1){1'b0}}, 1'b1} << {l0_w_set, l0_victim_way};
  assign l3_rf_oh  = {{(L3_N-1){1'b0}}, 1'b1} << l3_refill_idx;
  assign l2_rf_oh  = {{(L2_N-1){1'b0}}, 1'b1} << l2_refill_idx;
  assign sp_rf_oh  = {{(SP_N-1){1'b0}}, 1'b1} << sp_refill_idx;

  // l0 的受害者路号要送出去：bitmap 迟到唤醒时靠它找回写的是哪一路（golden:44301）。
  assign io_l0_way_info = l0_w_waymask;

  // ---------------------------------------------------------------------------
  // §9 各级回填使能与回填载荷（已追清：golden:6647 / 6785 / 7418 / 8289）
  //
  //  五级各有各的门控，且**各用各的 dup**：l3/l2 看 dup_2，l1 看 dup_1，l0/sp 看 dup_0。
  //  过滤条件的语义：
  //    l3/l2 存的是**非叶子** PDE  ⇒ 要求 ~isLeaf 且 canRefill；
  //    l1    没有任何过滤          ⇒ 只看 flush 与 levelOH（整行里逐项自己带 vs 位）；
  //    l0    存 4KB 叶子           ⇒ 把 napot 的那一条踢给 sp；
  //    sp    存大页/napot          ⇒ levelOH.sp，或 levelOH.l0 但选中的 PTE 是 napot；
  //          载荷有效性用 (isLeaf & canRefill) | onlyPf。
  logic l3_refill, l2_refill, sp_refill;

  assign l3_refill = ~flush_dup_2 & io_refill_bits_levelOH_l3
                   & ~pte_is_leaf(io_refill_bits_sel_pte_dup_2)
                   & pte_can_refill(io_refill_bits_sel_pte_dup_2,
                                    io_refill_bits_level_dup_2,
                                    io_refill_bits_req_info_dup_2_s2xlate,
                                    pbmte, io_csr_dup_2_hgatp_mode);

  assign l2_refill = ~flush_dup_2 & io_refill_bits_levelOH_l2
                   & ~pte_is_leaf(io_refill_bits_sel_pte_dup_2)
                   & pte_can_refill(io_refill_bits_sel_pte_dup_2,
                                    io_refill_bits_level_dup_2,
                                    io_refill_bits_req_info_dup_2_s2xlate,
                                    pbmte, io_csr_dup_2_hgatp_mode);

  logic sp_from_l0_napot, sp_payload_ok, sp_only_pf;
  assign sp_from_l0_napot = io_refill_bits_levelOH_l0
                          & pte_is_napot(io_refill_bits_sel_pte_dup_0,
                                         io_refill_bits_level_dup_0);
  assign sp_only_pf       = pte_only_pf(io_refill_bits_sel_pte_dup_0,
                                        io_refill_bits_level_dup_0,
                                        io_refill_bits_req_info_dup_0_s2xlate, pbmte);
  assign sp_payload_ok    = (pte_is_leaf(io_refill_bits_sel_pte_dup_0)
                             & pte_can_refill(io_refill_bits_sel_pte_dup_0,
                                              io_refill_bits_level_dup_0,
                                              io_refill_bits_req_info_dup_0_s2xlate,
                                              pbmte, io_csr_dup_0_hgatp_mode))
                          | sp_only_pf;
  assign sp_refill = ~flush_dup_0
                   & (io_refill_bits_levelOH_sp | sp_from_l0_napot)
                   & sp_payload_ok;

  // 回填时把 allStage 折成 onlyStage1（与查找侧的 h_search 同一个折法），每 dup 一份。
  logic [1:0] refill_h_0, refill_h_1, refill_h_2;
  assign refill_h_0 = (&io_refill_bits_req_info_dup_0_s2xlate)
                    ? H_ONLY_STAGE1 : io_refill_bits_req_info_dup_0_s2xlate;
  assign refill_h_1 = (&io_refill_bits_req_info_dup_1_s2xlate)
                    ? H_ONLY_STAGE1 : io_refill_bits_req_info_dup_1_s2xlate;
  assign refill_h_2 = (&io_refill_bits_req_info_dup_2_s2xlate)
                    ? H_ONLY_STAGE1 : io_refill_bits_req_info_dup_2_s2xlate;

  logic refill_prefetch_0, refill_prefetch_2;
  assign refill_prefetch_0 = (io_refill_bits_req_info_dup_0_source == 2'd2);
  assign refill_prefetch_2 = (io_refill_bits_req_info_dup_2_source == 2'd2);

  // l3/l2 用 dup_2 的 asid，sp 用 dup_0 的（l1/l0 的在 §6 已有）。
  logic [ASID_W-1:0] l23_w_asid, sp_w_asid;
  assign l23_w_asid = (|io_refill_bits_req_info_dup_2_s2xlate)
                    ? io_csr_dup_2_vsatp_asid : io_csr_dup_2_satp_asid;
  assign sp_w_asid  = (|io_refill_bits_req_info_dup_0_s2xlate)
                    ? io_csr_dup_0_vsatp_asid : io_csr_dup_0_satp_asid;

  // 整行 8 个 PTE 的 g 位全为 1，这条 l1/l0 表项才算 global（golden:31541-31550）。
  logic refill_line_all_g;
  always_comb begin
    refill_line_all_g = 1'b1;
    for (int i = 0; i < SECTOR_N; i++)
      refill_line_all_g &= refill_pte[i][PTE_G];
  end

  // ---------------------------------------------------------------------------
  // §9.1 XORFold —— 影子元数据存的是折叠哈希，不是原值（已追清：golden:30522/30538）
  //
  //  XORFold(x, w)：把 x 按 w 位一段切开，逐段异或；最后不足一段的高位零扩展。
  //  代价是 sfence 会保守多刷（哈希撞了就多刷几条），这是 golden 的设计选择。
  function automatic logic [HASH_ASID_W-1:0] xorfold3(input logic [15:0] x);
    return x[2:0] ^ x[5:3] ^ x[8:6] ^ x[11:9] ^ x[14:12] ^ {2'h0, x[15]};
  endfunction

  function automatic logic [HASH_VPN_W-1:0] xorfold6_tag(input logic [L0_TAG_W-1:0] t);
    // t = vpn[37:9]（29 位）：5 段 6 位，最后一段只有 5 位。
    return t[5:0] ^ t[11:6] ^ t[17:12] ^ t[23:18] ^ {1'h0, t[28:24]};
  endfunction

  // ---------------------------------------------------------------------------
  // §11 时序：两个 always_ff，复位域划分照抄 golden（见 §4 的说明）
  //
  //  ★这一版只追清了**回填侧**的状态更新★：sfence/hfence 的失效掩码、
  //  ecc flush、l0_bitmap 的写，都还没追清，见 §8。
  //  所以当前这份核只在"从不发 sfence、从不 ecc 出错"的激励下与 golden 同态。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      l3v <= '0;  l2v <= '0;  l1v <= '0;  l0v <= '0;  spv <= '0;
      valid_delay <= 1'b0;  valid_check <= 1'b0;  valid_resp <= 1'b0;
      plru_l3 <= '0;  plru_l2 <= '0;  plru_sp <= '0;
      for (int s = 0; s < L1_SETS; s++) plru_l1[s] <= 1'b0;
      for (int s = 0; s < L0_SETS; s++) plru_l0[s] <= '0;
      for (int s = 0; s < L0_SETS; s++)
        for (int w = 0; w < L0_WAYS; w++)
          l0_bitmap[s][w] <= '0;
    end
    else begin
      // PipelineConnect 的 valid 推进。★形状必须照抄：不是「下级 ready 时才更新」，
      // 而是**每拍无条件赋值**，取值 = ~flush_dup_0 & (本级 fire | 下级没收走就保持)。★
      // 这两种写法在下级 ready 时同值，但在 ~ready 且 flush 的那一拍**不同**：
      // golden 会把 valid 清掉，"有条件更新"的写法不会。
      // 三级 valid 全部只看 flush_dup_0（不是各看各的 dup）——这一点与回填相反。
      valid_delay <= ~flush_dup_0 & (left_fire_req   | ~stage_check_ready & valid_delay);
      valid_check <= ~flush_dup_0 & (left_fire_delay | ~stage_resp_ready  & valid_check);
      valid_resp  <= ~flush_dup_0 & (left_fire_check | ~io_resp_ready     & valid_resp);

      // 有效位：回填把被选中的那一位置 1。★sfence 的清零支路未追清（§8）★
      if (l3_refill) l3v <= l3v | l3_rf_oh;
      if (l2_refill) l2v <= l2v | l2_rf_oh;
      if (l1_refill) l1v <= l1v | l1_rfv_oh;
      if (l0_refill) l0v <= l0v | l0_rfv_oh;
      if (sp_refill) spv <= spv | sp_rf_oh;

      // 替换状态。★这里就是 §7 记的那个 golden 真 bug 的落点★：
      //   plru_l3 只有"l3 命中"一个写者（未追清，见 §8）；
      //   plru_l2 有三个写者，优先级 l2 回填 > **l3 回填** > l2 命中。
      // l3 回填喂给 plru_l2 的是 l3_refill_idx —— 照抄，不许"修好"。
      if (l2_refill)      plru_l2 <= plru16_access(plru_l2, l2_refill_idx);
      else if (l3_refill) plru_l2 <= plru16_access(plru_l2, l3_refill_idx);

      if (sp_refill) plru_sp <= plru16_access(plru_sp, sp_refill_idx);

      if (l1_refill) plru_l1[l1_w_set] <= ~l1_victim_way;
      if (l0_refill) plru_l0[l0_w_set] <= plru4_access(plru_l0[l0_w_set], l0_victim_way);
    end
  end

  // ---- 非复位域：全部载荷与影子元数据（golden 的第二个 always，:30763）----
  always_ff @(posedge clock) begin
    // l3 表项（无 pbmt —— l3 级 PDE 不带 pbmt）
    if (l3_refill) begin
      l3_entry[l3_refill_idx].tag      <= io_refill_bits_req_info_dup_2_vpn[37:27];
      l3_entry[l3_refill_idx].asid     <= l23_w_asid;
      l3_entry[l3_refill_idx].vmid     <= io_csr_dup_2_hgatp_vmid[13:0];
      l3_entry[l3_refill_idx].ppn      <= io_refill_bits_sel_pte_dup_2[47:10];
      l3_entry[l3_refill_idx].prefetch <= refill_prefetch_2;
      l3h[l3_refill_idx]               <= refill_h_2;
      // g 位：G 阶段（onlyStage2）的 PTE 其 g 位硬件要忽略，写 0。
      l3g <= (l3g & ~l3_rf_oh)
           | ((io_refill_bits_sel_pte_dup_2[PTE_G]
               & (io_refill_bits_req_info_dup_2_s2xlate != H_ONLY_STAGE2))
              ? l3_rf_oh : '0);
    end

    if (l2_refill) begin
      l2_entry[l2_refill_idx].tag      <= io_refill_bits_req_info_dup_2_vpn[37:18];
      l2_entry[l2_refill_idx].asid     <= l23_w_asid;
      l2_entry[l2_refill_idx].vmid     <= io_csr_dup_2_hgatp_vmid[13:0];
      l2_entry[l2_refill_idx].pbmt     <= io_refill_bits_sel_pte_dup_2[62:61];
      l2_entry[l2_refill_idx].ppn      <= io_refill_bits_sel_pte_dup_2[47:10];
      l2_entry[l2_refill_idx].prefetch <= refill_prefetch_2;
      l2h[l2_refill_idx]               <= refill_h_2;
      l2g <= (l2g & ~l2_rf_oh)
           | ((io_refill_bits_sel_pte_dup_2[PTE_G]
               & (io_refill_bits_req_info_dup_2_s2xlate != H_ONLY_STAGE2))
              ? l2_rf_oh : '0);
    end

    // sp 表项：大页/napot，带完整 perm、level 与 v。
    // ★v 字段 = ~onlyPf★：onlyPf 的条目也进 sp，但存的是"这条注定 pf"，v=0。
    if (sp_refill) begin
      sp_entry[sp_refill_idx].tag      <= io_refill_bits_req_info_dup_0_vpn;
      sp_entry[sp_refill_idx].asid     <= sp_w_asid;
      sp_entry[sp_refill_idx].vmid     <= io_csr_dup_0_hgatp_vmid[13:0];
      sp_entry[sp_refill_idx].n        <= io_refill_bits_sel_pte_dup_0[PTE_N];
      sp_entry[sp_refill_idx].pbmt     <= io_refill_bits_sel_pte_dup_0[62:61];
      sp_entry[sp_refill_idx].ppn      <= io_refill_bits_sel_pte_dup_0[47:10];
      sp_entry[sp_refill_idx].perm.d   <= io_refill_bits_sel_pte_dup_0[PTE_D];
      sp_entry[sp_refill_idx].perm.a   <= io_refill_bits_sel_pte_dup_0[PTE_A];
      sp_entry[sp_refill_idx].perm.g   <= io_refill_bits_sel_pte_dup_0[PTE_G]
                                        & (io_refill_bits_req_info_dup_0_s2xlate
                                           != H_ONLY_STAGE2);
      sp_entry[sp_refill_idx].perm.u   <= io_refill_bits_sel_pte_dup_0[PTE_U];
      sp_entry[sp_refill_idx].perm.x   <= io_refill_bits_sel_pte_dup_0[PTE_X];
      sp_entry[sp_refill_idx].perm.w   <= io_refill_bits_sel_pte_dup_0[PTE_W];
      sp_entry[sp_refill_idx].perm.r   <= io_refill_bits_sel_pte_dup_0[PTE_R];
      sp_entry[sp_refill_idx].level    <= io_refill_bits_level_dup_0;
      sp_entry[sp_refill_idx].prefetch <= refill_prefetch_0;
      sp_entry[sp_refill_idx].v        <= ~sp_only_pf;
      sph[sp_refill_idx]               <= refill_h_0;
      spg <= (spg & ~sp_rf_oh)
           | ((io_refill_bits_sel_pte_dup_0[PTE_G]
               & (io_refill_bits_req_info_dup_0_s2xlate != H_ONLY_STAGE2))
              ? sp_rf_oh : '0);
    end

    // l1/l0：载荷在 SRAM 里（写端口见 §6.2），核内只留 g / h / 影子哈希。
    if (l1_refill) begin
      l1g <= (l1g & ~l1_rfv_oh)
           | ((refill_line_all_g
               & (io_refill_bits_req_info_dup_1_s2xlate != H_ONLY_STAGE2))
              ? l1_rfv_oh : '0);
      l1h    [l1_w_set][l1_victim_way] <= refill_h_1;
      l1asids[l1_w_set][l1_victim_way] <= xorfold3(l1_w_asid);
      l1vmids[l1_w_set][l1_victim_way] <= xorfold3(io_csr_dup_1_hgatp_vmid);
    end

    if (l0_refill) begin
      l0g <= (l0g & ~l0_rfv_oh)
           | ((refill_line_all_g
               & (io_refill_bits_req_info_dup_0_s2xlate != H_ONLY_STAGE2))
              ? l0_rfv_oh : '0);
      l0h    [l0_w_set][l0_victim_way] <= refill_h_0;
      l0asids[l0_w_set][l0_victim_way] <= xorfold3(l0_w_asid);
      l0vmids[l0_w_set][l0_victim_way] <= xorfold3(io_csr_dup_0_hgatp_vmid);
      l0vpns [l0_w_set][l0_victim_way] <= xorfold6_tag(l0_w_tag);
    end
  end

  // ---------------------------------------------------------------------------
  // §8 未追清清单 —— ★占位信号，当前值无意义★
  //
  // 下面每一根都还没有从 golden 逐条追出方程。它们现在被恒定值顶着，
  // 只为让本骨架能 elaborate；任何人引用它们都会拿到错值。
  // 回填写数据（§6.1/§6.2）、替换策略与受害者选择（§7）、回填侧状态更新
  // （§9/§11）已从本表毕业，各有 verif/study/PtwCache_refill 的定向差分
  // 对照钉住。剩下的追清顺序：各级 hitVec -> sfence/hfence 失效 ->
  // ecc flush -> l0_bitmap 与 wakeup -> 响应装配 -> perf。



  // SRAM 读回数据（命中判定在 §8，尚未追清）
  logic [15:0]     l0_rdata_0_asid;
  logic            l0_rdata_0_onlypf_0;
  logic            l0_rdata_0_onlypf_1;
  logic            l0_rdata_0_onlypf_2;
  logic            l0_rdata_0_onlypf_3;
  logic            l0_rdata_0_onlypf_4;
  logic            l0_rdata_0_onlypf_5;
  logic            l0_rdata_0_onlypf_6;
  logic            l0_rdata_0_onlypf_7;
  logic [1:0]      l0_rdata_0_pbmts_0;
  logic [1:0]      l0_rdata_0_pbmts_1;
  logic [1:0]      l0_rdata_0_pbmts_2;
  logic [1:0]      l0_rdata_0_pbmts_3;
  logic [1:0]      l0_rdata_0_pbmts_4;
  logic [1:0]      l0_rdata_0_pbmts_5;
  logic [1:0]      l0_rdata_0_pbmts_6;
  logic [1:0]      l0_rdata_0_pbmts_7;
  logic            l0_rdata_0_perms_0_a;
  logic            l0_rdata_0_perms_0_d;
  logic            l0_rdata_0_perms_0_g;
  logic            l0_rdata_0_perms_0_r;
  logic            l0_rdata_0_perms_0_u;
  logic            l0_rdata_0_perms_0_w;
  logic            l0_rdata_0_perms_0_x;
  logic            l0_rdata_0_perms_1_a;
  logic            l0_rdata_0_perms_1_d;
  logic            l0_rdata_0_perms_1_g;
  logic            l0_rdata_0_perms_1_r;
  logic            l0_rdata_0_perms_1_u;
  logic            l0_rdata_0_perms_1_w;
  logic            l0_rdata_0_perms_1_x;
  logic            l0_rdata_0_perms_2_a;
  logic            l0_rdata_0_perms_2_d;
  logic            l0_rdata_0_perms_2_g;
  logic            l0_rdata_0_perms_2_r;
  logic            l0_rdata_0_perms_2_u;
  logic            l0_rdata_0_perms_2_w;
  logic            l0_rdata_0_perms_2_x;
  logic            l0_rdata_0_perms_3_a;
  logic            l0_rdata_0_perms_3_d;
  logic            l0_rdata_0_perms_3_g;
  logic            l0_rdata_0_perms_3_r;
  logic            l0_rdata_0_perms_3_u;
  logic            l0_rdata_0_perms_3_w;
  logic            l0_rdata_0_perms_3_x;
  logic            l0_rdata_0_perms_4_a;
  logic            l0_rdata_0_perms_4_d;
  logic            l0_rdata_0_perms_4_g;
  logic            l0_rdata_0_perms_4_r;
  logic            l0_rdata_0_perms_4_u;
  logic            l0_rdata_0_perms_4_w;
  logic            l0_rdata_0_perms_4_x;
  logic            l0_rdata_0_perms_5_a;
  logic            l0_rdata_0_perms_5_d;
  logic            l0_rdata_0_perms_5_g;
  logic            l0_rdata_0_perms_5_r;
  logic            l0_rdata_0_perms_5_u;
  logic            l0_rdata_0_perms_5_w;
  logic            l0_rdata_0_perms_5_x;
  logic            l0_rdata_0_perms_6_a;
  logic            l0_rdata_0_perms_6_d;
  logic            l0_rdata_0_perms_6_g;
  logic            l0_rdata_0_perms_6_r;
  logic            l0_rdata_0_perms_6_u;
  logic            l0_rdata_0_perms_6_w;
  logic            l0_rdata_0_perms_6_x;
  logic            l0_rdata_0_perms_7_a;
  logic            l0_rdata_0_perms_7_d;
  logic            l0_rdata_0_perms_7_g;
  logic            l0_rdata_0_perms_7_r;
  logic            l0_rdata_0_perms_7_u;
  logic            l0_rdata_0_perms_7_w;
  logic            l0_rdata_0_perms_7_x;
  logic [37:0]     l0_rdata_0_ppns_0;
  logic [37:0]     l0_rdata_0_ppns_1;
  logic [37:0]     l0_rdata_0_ppns_2;
  logic [37:0]     l0_rdata_0_ppns_3;
  logic [37:0]     l0_rdata_0_ppns_4;
  logic [37:0]     l0_rdata_0_ppns_5;
  logic [37:0]     l0_rdata_0_ppns_6;
  logic [37:0]     l0_rdata_0_ppns_7;
  logic            l0_rdata_0_prefetch;
  logic [28:0]     l0_rdata_0_tag;
  logic [13:0]     l0_rdata_0_vmid;
  logic            l0_rdata_0_vs_0;
  logic            l0_rdata_0_vs_1;
  logic            l0_rdata_0_vs_2;
  logic            l0_rdata_0_vs_3;
  logic            l0_rdata_0_vs_4;
  logic            l0_rdata_0_vs_5;
  logic            l0_rdata_0_vs_6;
  logic            l0_rdata_0_vs_7;
  logic [15:0]     l0_rdata_1_asid;
  logic            l0_rdata_1_onlypf_0;
  logic            l0_rdata_1_onlypf_1;
  logic            l0_rdata_1_onlypf_2;
  logic            l0_rdata_1_onlypf_3;
  logic            l0_rdata_1_onlypf_4;
  logic            l0_rdata_1_onlypf_5;
  logic            l0_rdata_1_onlypf_6;
  logic            l0_rdata_1_onlypf_7;
  logic [1:0]      l0_rdata_1_pbmts_0;
  logic [1:0]      l0_rdata_1_pbmts_1;
  logic [1:0]      l0_rdata_1_pbmts_2;
  logic [1:0]      l0_rdata_1_pbmts_3;
  logic [1:0]      l0_rdata_1_pbmts_4;
  logic [1:0]      l0_rdata_1_pbmts_5;
  logic [1:0]      l0_rdata_1_pbmts_6;
  logic [1:0]      l0_rdata_1_pbmts_7;
  logic            l0_rdata_1_perms_0_a;
  logic            l0_rdata_1_perms_0_d;
  logic            l0_rdata_1_perms_0_g;
  logic            l0_rdata_1_perms_0_r;
  logic            l0_rdata_1_perms_0_u;
  logic            l0_rdata_1_perms_0_w;
  logic            l0_rdata_1_perms_0_x;
  logic            l0_rdata_1_perms_1_a;
  logic            l0_rdata_1_perms_1_d;
  logic            l0_rdata_1_perms_1_g;
  logic            l0_rdata_1_perms_1_r;
  logic            l0_rdata_1_perms_1_u;
  logic            l0_rdata_1_perms_1_w;
  logic            l0_rdata_1_perms_1_x;
  logic            l0_rdata_1_perms_2_a;
  logic            l0_rdata_1_perms_2_d;
  logic            l0_rdata_1_perms_2_g;
  logic            l0_rdata_1_perms_2_r;
  logic            l0_rdata_1_perms_2_u;
  logic            l0_rdata_1_perms_2_w;
  logic            l0_rdata_1_perms_2_x;
  logic            l0_rdata_1_perms_3_a;
  logic            l0_rdata_1_perms_3_d;
  logic            l0_rdata_1_perms_3_g;
  logic            l0_rdata_1_perms_3_r;
  logic            l0_rdata_1_perms_3_u;
  logic            l0_rdata_1_perms_3_w;
  logic            l0_rdata_1_perms_3_x;
  logic            l0_rdata_1_perms_4_a;
  logic            l0_rdata_1_perms_4_d;
  logic            l0_rdata_1_perms_4_g;
  logic            l0_rdata_1_perms_4_r;
  logic            l0_rdata_1_perms_4_u;
  logic            l0_rdata_1_perms_4_w;
  logic            l0_rdata_1_perms_4_x;
  logic            l0_rdata_1_perms_5_a;
  logic            l0_rdata_1_perms_5_d;
  logic            l0_rdata_1_perms_5_g;
  logic            l0_rdata_1_perms_5_r;
  logic            l0_rdata_1_perms_5_u;
  logic            l0_rdata_1_perms_5_w;
  logic            l0_rdata_1_perms_5_x;
  logic            l0_rdata_1_perms_6_a;
  logic            l0_rdata_1_perms_6_d;
  logic            l0_rdata_1_perms_6_g;
  logic            l0_rdata_1_perms_6_r;
  logic            l0_rdata_1_perms_6_u;
  logic            l0_rdata_1_perms_6_w;
  logic            l0_rdata_1_perms_6_x;
  logic            l0_rdata_1_perms_7_a;
  logic            l0_rdata_1_perms_7_d;
  logic            l0_rdata_1_perms_7_g;
  logic            l0_rdata_1_perms_7_r;
  logic            l0_rdata_1_perms_7_u;
  logic            l0_rdata_1_perms_7_w;
  logic            l0_rdata_1_perms_7_x;
  logic [37:0]     l0_rdata_1_ppns_0;
  logic [37:0]     l0_rdata_1_ppns_1;
  logic [37:0]     l0_rdata_1_ppns_2;
  logic [37:0]     l0_rdata_1_ppns_3;
  logic [37:0]     l0_rdata_1_ppns_4;
  logic [37:0]     l0_rdata_1_ppns_5;
  logic [37:0]     l0_rdata_1_ppns_6;
  logic [37:0]     l0_rdata_1_ppns_7;
  logic            l0_rdata_1_prefetch;
  logic [28:0]     l0_rdata_1_tag;
  logic [13:0]     l0_rdata_1_vmid;
  logic            l0_rdata_1_vs_0;
  logic            l0_rdata_1_vs_1;
  logic            l0_rdata_1_vs_2;
  logic            l0_rdata_1_vs_3;
  logic            l0_rdata_1_vs_4;
  logic            l0_rdata_1_vs_5;
  logic            l0_rdata_1_vs_6;
  logic            l0_rdata_1_vs_7;
  logic [15:0]     l0_rdata_2_asid;
  logic            l0_rdata_2_onlypf_0;
  logic            l0_rdata_2_onlypf_1;
  logic            l0_rdata_2_onlypf_2;
  logic            l0_rdata_2_onlypf_3;
  logic            l0_rdata_2_onlypf_4;
  logic            l0_rdata_2_onlypf_5;
  logic            l0_rdata_2_onlypf_6;
  logic            l0_rdata_2_onlypf_7;
  logic [1:0]      l0_rdata_2_pbmts_0;
  logic [1:0]      l0_rdata_2_pbmts_1;
  logic [1:0]      l0_rdata_2_pbmts_2;
  logic [1:0]      l0_rdata_2_pbmts_3;
  logic [1:0]      l0_rdata_2_pbmts_4;
  logic [1:0]      l0_rdata_2_pbmts_5;
  logic [1:0]      l0_rdata_2_pbmts_6;
  logic [1:0]      l0_rdata_2_pbmts_7;
  logic            l0_rdata_2_perms_0_a;
  logic            l0_rdata_2_perms_0_d;
  logic            l0_rdata_2_perms_0_g;
  logic            l0_rdata_2_perms_0_r;
  logic            l0_rdata_2_perms_0_u;
  logic            l0_rdata_2_perms_0_w;
  logic            l0_rdata_2_perms_0_x;
  logic            l0_rdata_2_perms_1_a;
  logic            l0_rdata_2_perms_1_d;
  logic            l0_rdata_2_perms_1_g;
  logic            l0_rdata_2_perms_1_r;
  logic            l0_rdata_2_perms_1_u;
  logic            l0_rdata_2_perms_1_w;
  logic            l0_rdata_2_perms_1_x;
  logic            l0_rdata_2_perms_2_a;
  logic            l0_rdata_2_perms_2_d;
  logic            l0_rdata_2_perms_2_g;
  logic            l0_rdata_2_perms_2_r;
  logic            l0_rdata_2_perms_2_u;
  logic            l0_rdata_2_perms_2_w;
  logic            l0_rdata_2_perms_2_x;
  logic            l0_rdata_2_perms_3_a;
  logic            l0_rdata_2_perms_3_d;
  logic            l0_rdata_2_perms_3_g;
  logic            l0_rdata_2_perms_3_r;
  logic            l0_rdata_2_perms_3_u;
  logic            l0_rdata_2_perms_3_w;
  logic            l0_rdata_2_perms_3_x;
  logic            l0_rdata_2_perms_4_a;
  logic            l0_rdata_2_perms_4_d;
  logic            l0_rdata_2_perms_4_g;
  logic            l0_rdata_2_perms_4_r;
  logic            l0_rdata_2_perms_4_u;
  logic            l0_rdata_2_perms_4_w;
  logic            l0_rdata_2_perms_4_x;
  logic            l0_rdata_2_perms_5_a;
  logic            l0_rdata_2_perms_5_d;
  logic            l0_rdata_2_perms_5_g;
  logic            l0_rdata_2_perms_5_r;
  logic            l0_rdata_2_perms_5_u;
  logic            l0_rdata_2_perms_5_w;
  logic            l0_rdata_2_perms_5_x;
  logic            l0_rdata_2_perms_6_a;
  logic            l0_rdata_2_perms_6_d;
  logic            l0_rdata_2_perms_6_g;
  logic            l0_rdata_2_perms_6_r;
  logic            l0_rdata_2_perms_6_u;
  logic            l0_rdata_2_perms_6_w;
  logic            l0_rdata_2_perms_6_x;
  logic            l0_rdata_2_perms_7_a;
  logic            l0_rdata_2_perms_7_d;
  logic            l0_rdata_2_perms_7_g;
  logic            l0_rdata_2_perms_7_r;
  logic            l0_rdata_2_perms_7_u;
  logic            l0_rdata_2_perms_7_w;
  logic            l0_rdata_2_perms_7_x;
  logic [37:0]     l0_rdata_2_ppns_0;
  logic [37:0]     l0_rdata_2_ppns_1;
  logic [37:0]     l0_rdata_2_ppns_2;
  logic [37:0]     l0_rdata_2_ppns_3;
  logic [37:0]     l0_rdata_2_ppns_4;
  logic [37:0]     l0_rdata_2_ppns_5;
  logic [37:0]     l0_rdata_2_ppns_6;
  logic [37:0]     l0_rdata_2_ppns_7;
  logic            l0_rdata_2_prefetch;
  logic [28:0]     l0_rdata_2_tag;
  logic [13:0]     l0_rdata_2_vmid;
  logic            l0_rdata_2_vs_0;
  logic            l0_rdata_2_vs_1;
  logic            l0_rdata_2_vs_2;
  logic            l0_rdata_2_vs_3;
  logic            l0_rdata_2_vs_4;
  logic            l0_rdata_2_vs_5;
  logic            l0_rdata_2_vs_6;
  logic            l0_rdata_2_vs_7;
  logic [15:0]     l0_rdata_3_asid;
  logic            l0_rdata_3_onlypf_0;
  logic            l0_rdata_3_onlypf_1;
  logic            l0_rdata_3_onlypf_2;
  logic            l0_rdata_3_onlypf_3;
  logic            l0_rdata_3_onlypf_4;
  logic            l0_rdata_3_onlypf_5;
  logic            l0_rdata_3_onlypf_6;
  logic            l0_rdata_3_onlypf_7;
  logic [1:0]      l0_rdata_3_pbmts_0;
  logic [1:0]      l0_rdata_3_pbmts_1;
  logic [1:0]      l0_rdata_3_pbmts_2;
  logic [1:0]      l0_rdata_3_pbmts_3;
  logic [1:0]      l0_rdata_3_pbmts_4;
  logic [1:0]      l0_rdata_3_pbmts_5;
  logic [1:0]      l0_rdata_3_pbmts_6;
  logic [1:0]      l0_rdata_3_pbmts_7;
  logic            l0_rdata_3_perms_0_a;
  logic            l0_rdata_3_perms_0_d;
  logic            l0_rdata_3_perms_0_g;
  logic            l0_rdata_3_perms_0_r;
  logic            l0_rdata_3_perms_0_u;
  logic            l0_rdata_3_perms_0_w;
  logic            l0_rdata_3_perms_0_x;
  logic            l0_rdata_3_perms_1_a;
  logic            l0_rdata_3_perms_1_d;
  logic            l0_rdata_3_perms_1_g;
  logic            l0_rdata_3_perms_1_r;
  logic            l0_rdata_3_perms_1_u;
  logic            l0_rdata_3_perms_1_w;
  logic            l0_rdata_3_perms_1_x;
  logic            l0_rdata_3_perms_2_a;
  logic            l0_rdata_3_perms_2_d;
  logic            l0_rdata_3_perms_2_g;
  logic            l0_rdata_3_perms_2_r;
  logic            l0_rdata_3_perms_2_u;
  logic            l0_rdata_3_perms_2_w;
  logic            l0_rdata_3_perms_2_x;
  logic            l0_rdata_3_perms_3_a;
  logic            l0_rdata_3_perms_3_d;
  logic            l0_rdata_3_perms_3_g;
  logic            l0_rdata_3_perms_3_r;
  logic            l0_rdata_3_perms_3_u;
  logic            l0_rdata_3_perms_3_w;
  logic            l0_rdata_3_perms_3_x;
  logic            l0_rdata_3_perms_4_a;
  logic            l0_rdata_3_perms_4_d;
  logic            l0_rdata_3_perms_4_g;
  logic            l0_rdata_3_perms_4_r;
  logic            l0_rdata_3_perms_4_u;
  logic            l0_rdata_3_perms_4_w;
  logic            l0_rdata_3_perms_4_x;
  logic            l0_rdata_3_perms_5_a;
  logic            l0_rdata_3_perms_5_d;
  logic            l0_rdata_3_perms_5_g;
  logic            l0_rdata_3_perms_5_r;
  logic            l0_rdata_3_perms_5_u;
  logic            l0_rdata_3_perms_5_w;
  logic            l0_rdata_3_perms_5_x;
  logic            l0_rdata_3_perms_6_a;
  logic            l0_rdata_3_perms_6_d;
  logic            l0_rdata_3_perms_6_g;
  logic            l0_rdata_3_perms_6_r;
  logic            l0_rdata_3_perms_6_u;
  logic            l0_rdata_3_perms_6_w;
  logic            l0_rdata_3_perms_6_x;
  logic            l0_rdata_3_perms_7_a;
  logic            l0_rdata_3_perms_7_d;
  logic            l0_rdata_3_perms_7_g;
  logic            l0_rdata_3_perms_7_r;
  logic            l0_rdata_3_perms_7_u;
  logic            l0_rdata_3_perms_7_w;
  logic            l0_rdata_3_perms_7_x;
  logic [37:0]     l0_rdata_3_ppns_0;
  logic [37:0]     l0_rdata_3_ppns_1;
  logic [37:0]     l0_rdata_3_ppns_2;
  logic [37:0]     l0_rdata_3_ppns_3;
  logic [37:0]     l0_rdata_3_ppns_4;
  logic [37:0]     l0_rdata_3_ppns_5;
  logic [37:0]     l0_rdata_3_ppns_6;
  logic [37:0]     l0_rdata_3_ppns_7;
  logic            l0_rdata_3_prefetch;
  logic [28:0]     l0_rdata_3_tag;
  logic [13:0]     l0_rdata_3_vmid;
  logic            l0_rdata_3_vs_0;
  logic            l0_rdata_3_vs_1;
  logic            l0_rdata_3_vs_2;
  logic            l0_rdata_3_vs_3;
  logic            l0_rdata_3_vs_4;
  logic            l0_rdata_3_vs_5;
  logic            l0_rdata_3_vs_6;
  logic            l0_rdata_3_vs_7;
  logic [15:0]     l1_rdata_0_asid;
  logic [1:0]      l1_rdata_0_pbmts_0;
  logic [1:0]      l1_rdata_0_pbmts_1;
  logic [1:0]      l1_rdata_0_pbmts_2;
  logic [1:0]      l1_rdata_0_pbmts_3;
  logic [1:0]      l1_rdata_0_pbmts_4;
  logic [1:0]      l1_rdata_0_pbmts_5;
  logic [1:0]      l1_rdata_0_pbmts_6;
  logic [1:0]      l1_rdata_0_pbmts_7;
  logic [37:0]     l1_rdata_0_ppns_0;
  logic [37:0]     l1_rdata_0_ppns_1;
  logic [37:0]     l1_rdata_0_ppns_2;
  logic [37:0]     l1_rdata_0_ppns_3;
  logic [37:0]     l1_rdata_0_ppns_4;
  logic [37:0]     l1_rdata_0_ppns_5;
  logic [37:0]     l1_rdata_0_ppns_6;
  logic [37:0]     l1_rdata_0_ppns_7;
  logic            l1_rdata_0_prefetch;
  logic [23:0]     l1_rdata_0_tag;
  logic [13:0]     l1_rdata_0_vmid;
  logic            l1_rdata_0_vs_0;
  logic            l1_rdata_0_vs_1;
  logic            l1_rdata_0_vs_2;
  logic            l1_rdata_0_vs_3;
  logic            l1_rdata_0_vs_4;
  logic            l1_rdata_0_vs_5;
  logic            l1_rdata_0_vs_6;
  logic            l1_rdata_0_vs_7;
  logic [15:0]     l1_rdata_1_asid;
  logic [1:0]      l1_rdata_1_pbmts_0;
  logic [1:0]      l1_rdata_1_pbmts_1;
  logic [1:0]      l1_rdata_1_pbmts_2;
  logic [1:0]      l1_rdata_1_pbmts_3;
  logic [1:0]      l1_rdata_1_pbmts_4;
  logic [1:0]      l1_rdata_1_pbmts_5;
  logic [1:0]      l1_rdata_1_pbmts_6;
  logic [1:0]      l1_rdata_1_pbmts_7;
  logic [37:0]     l1_rdata_1_ppns_0;
  logic [37:0]     l1_rdata_1_ppns_1;
  logic [37:0]     l1_rdata_1_ppns_2;
  logic [37:0]     l1_rdata_1_ppns_3;
  logic [37:0]     l1_rdata_1_ppns_4;
  logic [37:0]     l1_rdata_1_ppns_5;
  logic [37:0]     l1_rdata_1_ppns_6;
  logic [37:0]     l1_rdata_1_ppns_7;
  logic            l1_rdata_1_prefetch;
  logic [23:0]     l1_rdata_1_tag;
  logic [13:0]     l1_rdata_1_vmid;
  logic            l1_rdata_1_vs_0;
  logic            l1_rdata_1_vs_1;
  logic            l1_rdata_1_vs_2;
  logic            l1_rdata_1_vs_3;
  logic            l1_rdata_1_vs_4;
  logic            l1_rdata_1_vs_5;
  logic            l1_rdata_1_vs_6;
  logic            l1_rdata_1_vs_7;

  // MBIST 分发级到 SRAM 的线束（宽度逐根抄自 golden）
  logic            childBd_re;
  logic            childBd_we;
  logic            childBd_ack;
  logic            childBd_1_re;
  logic            childBd_1_we;
  logic            childBd_2_re;
  logic            childBd_2_we;
  logic            childBd_3_re;
  logic            childBd_3_we;
  logic            childBd_4_re;
  logic            childBd_4_we;
  logic            childBd_5_re;
  logic            childBd_5_we;
  logic            childBd_6_re;
  logic            childBd_6_we;
  logic            childBd_7_re;
  logic            childBd_7_we;
  logic            childBd_8_re;
  logic            childBd_8_we;
  logic            childBd_9_re;
  logic            childBd_9_we;
  logic [2:0]      childBd_addr;
  logic            childBd_10_re;
  logic            childBd_10_we;
  logic            childBd_11_re;
  logic            childBd_11_we;
  logic            childBd_12_re;
  logic            childBd_12_we;
  logic            childBd_13_re;
  logic            childBd_13_we;
  logic            childBd_14_re;
  logic            childBd_14_we;
  logic            childBd_15_re;
  logic            childBd_15_we;
  logic            childBd_16_re;
  logic            childBd_16_we;
  logic            childBd_1_ack;
  logic            childBd_2_ack;
  logic            childBd_3_ack;
  logic            childBd_4_ack;
  logic            childBd_5_ack;
  logic            childBd_6_ack;
  logic            childBd_7_ack;
  logic            childBd_8_ack;
  logic            childBd_9_ack;
  logic [5:0]      childBd_array;
  logic [130:0]    childBd_rdata;
  logic [130:0]    childBd_wdata;
  logic            childBd_wmask;
  logic            childBd_10_ack;
  logic            childBd_11_ack;
  logic            childBd_12_ack;
  logic            childBd_13_ack;
  logic            childBd_14_ack;
  logic            childBd_15_ack;
  logic            childBd_16_ack;
  logic [6:0]      childBd_1_addr;
  logic [6:0]      childBd_2_addr;
  logic [6:0]      childBd_3_addr;
  logic [6:0]      childBd_4_addr;
  logic [6:0]      childBd_5_addr;
  logic [6:0]      childBd_6_addr;
  logic [6:0]      childBd_7_addr;
  logic [6:0]      childBd_8_addr;
  logic [6:0]      childBd_9_addr;
  logic [6:0]      childBd_10_addr;
  logic [6:0]      childBd_11_addr;
  logic [6:0]      childBd_12_addr;
  logic [6:0]      childBd_13_addr;
  logic [6:0]      childBd_14_addr;
  logic [6:0]      childBd_15_addr;
  logic [6:0]      childBd_16_addr;
  logic [5:0]      childBd_1_array;
  logic [113:0]    childBd_1_rdata;
  logic [113:0]    childBd_1_wdata;
  logic [1:0]      childBd_1_wmask;
  logic [5:0]      childBd_2_array;
  logic [113:0]    childBd_2_rdata;
  logic [113:0]    childBd_2_wdata;
  logic [1:0]      childBd_2_wmask;
  logic [5:0]      childBd_3_array;
  logic [113:0]    childBd_3_rdata;
  logic [113:0]    childBd_3_wdata;
  logic [1:0]      childBd_3_wmask;
  logic [5:0]      childBd_4_array;
  logic [113:0]    childBd_4_rdata;
  logic [113:0]    childBd_4_wdata;
  logic [1:0]      childBd_4_wmask;
  logic [5:0]      childBd_5_array;
  logic [113:0]    childBd_5_rdata;
  logic [113:0]    childBd_5_wdata;
  logic [1:0]      childBd_5_wmask;
  logic [5:0]      childBd_6_array;
  logic [113:0]    childBd_6_rdata;
  logic [113:0]    childBd_6_wdata;
  logic [1:0]      childBd_6_wmask;
  logic [5:0]      childBd_7_array;
  logic [113:0]    childBd_7_rdata;
  logic [113:0]    childBd_7_wdata;
  logic [1:0]      childBd_7_wmask;
  logic [5:0]      childBd_8_array;
  logic [113:0]    childBd_8_rdata;
  logic [113:0]    childBd_8_wdata;
  logic [1:0]      childBd_8_wmask;
  logic [5:0]      childBd_9_array;
  logic [113:0]    childBd_9_rdata;
  logic [113:0]    childBd_9_wdata;
  logic [1:0]      childBd_9_wmask;
  logic [2:0]      childBd_addr_rd;
  logic [5:0]      childBd_10_array;
  logic [113:0]    childBd_10_rdata;
  logic [113:0]    childBd_10_wdata;
  logic [1:0]      childBd_10_wmask;
  logic [5:0]      childBd_11_array;
  logic [113:0]    childBd_11_rdata;
  logic [113:0]    childBd_11_wdata;
  logic [1:0]      childBd_11_wmask;
  logic [5:0]      childBd_12_array;
  logic [113:0]    childBd_12_rdata;
  logic [113:0]    childBd_12_wdata;
  logic [1:0]      childBd_12_wmask;
  logic [5:0]      childBd_13_array;
  logic [113:0]    childBd_13_rdata;
  logic [113:0]    childBd_13_wdata;
  logic [1:0]      childBd_13_wmask;
  logic [5:0]      childBd_14_array;
  logic [113:0]    childBd_14_rdata;
  logic [113:0]    childBd_14_wdata;
  logic [1:0]      childBd_14_wmask;
  logic [6:0]      childBd_15_array;
  logic [113:0]    childBd_15_rdata;
  logic [113:0]    childBd_15_wdata;
  logic [1:0]      childBd_15_wmask;
  logic [6:0]      childBd_16_array;
  logic [113:0]    childBd_16_rdata;
  logic [113:0]    childBd_16_wdata;
  logic [1:0]      childBd_16_wmask;
  logic [6:0]      childBd_1_addr_rd;
  logic [6:0]      childBd_2_addr_rd;
  logic [6:0]      childBd_3_addr_rd;
  logic [6:0]      childBd_4_addr_rd;
  logic [6:0]      childBd_5_addr_rd;
  logic [6:0]      childBd_6_addr_rd;
  logic [6:0]      childBd_7_addr_rd;
  logic [6:0]      childBd_8_addr_rd;
  logic [6:0]      childBd_9_addr_rd;
  logic [6:0]      childBd_10_addr_rd;
  logic [6:0]      childBd_11_addr_rd;
  logic [6:0]      childBd_12_addr_rd;
  logic [6:0]      childBd_13_addr_rd;
  logic [6:0]      childBd_14_addr_rd;
  logic [6:0]      childBd_15_addr_rd;
  logic [6:0]      childBd_16_addr_rd;
  logic [5:0]      childBd_selectedOH;
  logic            childBd_1_selectedOH;
  logic            childBd_2_selectedOH;
  logic            childBd_3_selectedOH;
  logic            childBd_4_selectedOH;
  logic            childBd_5_selectedOH;
  logic            childBd_6_selectedOH;
  logic            childBd_7_selectedOH;
  logic            childBd_8_selectedOH;
  logic            childBd_9_selectedOH;
  logic            childBd_10_selectedOH;
  logic            childBd_11_selectedOH;
  logic            childBd_12_selectedOH;
  logic            childBd_13_selectedOH;
  logic            childBd_14_selectedOH;
  logic            childBd_15_selectedOH;
  logic            childBd_16_selectedOH;

  // ★以下 228 个输出还没有真实驱动★——命中判定、响应装配、perf 计数
  // 都还没追清（见 §8）。钉 0 只为让骨架能 elaborate，不是它们的正确值。
  assign io_resp_bits_req_info_vpn = '0;
  assign io_resp_bits_req_info_s2xlate = '0;
  assign io_resp_bits_req_info_source = '0;
  assign io_resp_bits_isFirst = '0;
  assign io_resp_bits_hit = '0;
  assign io_resp_bits_prefetch = '0;
  assign io_resp_bits_bypassed = '0;
  assign io_resp_bits_toFsm_l3Hit = '0;
  assign io_resp_bits_toFsm_l2Hit = '0;
  assign io_resp_bits_toFsm_l1Hit = '0;
  assign io_resp_bits_toFsm_ppn = '0;
  assign io_resp_bits_toFsm_stage1Hit = '0;
  assign io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check = '0;
  assign io_resp_bits_toFsm_bitmapCheck_toLLPTW = '0;
  assign io_resp_bits_toFsm_bitmapCheck_hitway = '0;
  assign io_resp_bits_toFsm_bitmapCheck_pte = '0;
  assign io_resp_bits_toFsm_bitmapCheck_ptes_0 = '0;
  assign io_resp_bits_toFsm_bitmapCheck_ptes_1 = '0;
  assign io_resp_bits_toFsm_bitmapCheck_ptes_2 = '0;
  assign io_resp_bits_toFsm_bitmapCheck_ptes_3 = '0;
  assign io_resp_bits_toFsm_bitmapCheck_ptes_4 = '0;
  assign io_resp_bits_toFsm_bitmapCheck_ptes_5 = '0;
  assign io_resp_bits_toFsm_bitmapCheck_ptes_6 = '0;
  assign io_resp_bits_toFsm_bitmapCheck_ptes_7 = '0;
  assign io_resp_bits_toFsm_bitmapCheck_cfs_0 = '0;
  assign io_resp_bits_toFsm_bitmapCheck_cfs_1 = '0;
  assign io_resp_bits_toFsm_bitmapCheck_cfs_2 = '0;
  assign io_resp_bits_toFsm_bitmapCheck_cfs_3 = '0;
  assign io_resp_bits_toFsm_bitmapCheck_cfs_4 = '0;
  assign io_resp_bits_toFsm_bitmapCheck_cfs_5 = '0;
  assign io_resp_bits_toFsm_bitmapCheck_cfs_6 = '0;
  assign io_resp_bits_toFsm_bitmapCheck_cfs_7 = '0;
  assign io_resp_bits_toFsm_bitmapCheck_SPlevel = '0;
  assign io_resp_bits_stage1_entry_0_tag = '0;
  assign io_resp_bits_stage1_entry_0_asid = '0;
  assign io_resp_bits_stage1_entry_0_vmid = '0;
  assign io_resp_bits_stage1_entry_0_n = '0;
  assign io_resp_bits_stage1_entry_0_pbmt = '0;
  assign io_resp_bits_stage1_entry_0_perm_d = '0;
  assign io_resp_bits_stage1_entry_0_perm_a = '0;
  assign io_resp_bits_stage1_entry_0_perm_g = '0;
  assign io_resp_bits_stage1_entry_0_perm_u = '0;
  assign io_resp_bits_stage1_entry_0_perm_x = '0;
  assign io_resp_bits_stage1_entry_0_perm_w = '0;
  assign io_resp_bits_stage1_entry_0_perm_r = '0;
  assign io_resp_bits_stage1_entry_0_level = '0;
  assign io_resp_bits_stage1_entry_0_v = '0;
  assign io_resp_bits_stage1_entry_0_ppn = '0;
  assign io_resp_bits_stage1_entry_0_ppn_low = '0;
  assign io_resp_bits_stage1_entry_0_pf = '0;
  assign io_resp_bits_stage1_entry_0_cf = '0;
  assign io_resp_bits_stage1_entry_1_tag = '0;
  assign io_resp_bits_stage1_entry_1_asid = '0;
  assign io_resp_bits_stage1_entry_1_vmid = '0;
  assign io_resp_bits_stage1_entry_1_n = '0;
  assign io_resp_bits_stage1_entry_1_pbmt = '0;
  assign io_resp_bits_stage1_entry_1_perm_d = '0;
  assign io_resp_bits_stage1_entry_1_perm_a = '0;
  assign io_resp_bits_stage1_entry_1_perm_g = '0;
  assign io_resp_bits_stage1_entry_1_perm_u = '0;
  assign io_resp_bits_stage1_entry_1_perm_x = '0;
  assign io_resp_bits_stage1_entry_1_perm_w = '0;
  assign io_resp_bits_stage1_entry_1_perm_r = '0;
  assign io_resp_bits_stage1_entry_1_level = '0;
  assign io_resp_bits_stage1_entry_1_v = '0;
  assign io_resp_bits_stage1_entry_1_ppn = '0;
  assign io_resp_bits_stage1_entry_1_ppn_low = '0;
  assign io_resp_bits_stage1_entry_1_pf = '0;
  assign io_resp_bits_stage1_entry_1_cf = '0;
  assign io_resp_bits_stage1_entry_2_tag = '0;
  assign io_resp_bits_stage1_entry_2_asid = '0;
  assign io_resp_bits_stage1_entry_2_vmid = '0;
  assign io_resp_bits_stage1_entry_2_n = '0;
  assign io_resp_bits_stage1_entry_2_pbmt = '0;
  assign io_resp_bits_stage1_entry_2_perm_d = '0;
  assign io_resp_bits_stage1_entry_2_perm_a = '0;
  assign io_resp_bits_stage1_entry_2_perm_g = '0;
  assign io_resp_bits_stage1_entry_2_perm_u = '0;
  assign io_resp_bits_stage1_entry_2_perm_x = '0;
  assign io_resp_bits_stage1_entry_2_perm_w = '0;
  assign io_resp_bits_stage1_entry_2_perm_r = '0;
  assign io_resp_bits_stage1_entry_2_level = '0;
  assign io_resp_bits_stage1_entry_2_v = '0;
  assign io_resp_bits_stage1_entry_2_ppn = '0;
  assign io_resp_bits_stage1_entry_2_ppn_low = '0;
  assign io_resp_bits_stage1_entry_2_pf = '0;
  assign io_resp_bits_stage1_entry_2_cf = '0;
  assign io_resp_bits_stage1_entry_3_tag = '0;
  assign io_resp_bits_stage1_entry_3_asid = '0;
  assign io_resp_bits_stage1_entry_3_vmid = '0;
  assign io_resp_bits_stage1_entry_3_n = '0;
  assign io_resp_bits_stage1_entry_3_pbmt = '0;
  assign io_resp_bits_stage1_entry_3_perm_d = '0;
  assign io_resp_bits_stage1_entry_3_perm_a = '0;
  assign io_resp_bits_stage1_entry_3_perm_g = '0;
  assign io_resp_bits_stage1_entry_3_perm_u = '0;
  assign io_resp_bits_stage1_entry_3_perm_x = '0;
  assign io_resp_bits_stage1_entry_3_perm_w = '0;
  assign io_resp_bits_stage1_entry_3_perm_r = '0;
  assign io_resp_bits_stage1_entry_3_level = '0;
  assign io_resp_bits_stage1_entry_3_v = '0;
  assign io_resp_bits_stage1_entry_3_ppn = '0;
  assign io_resp_bits_stage1_entry_3_ppn_low = '0;
  assign io_resp_bits_stage1_entry_3_pf = '0;
  assign io_resp_bits_stage1_entry_3_cf = '0;
  assign io_resp_bits_stage1_entry_4_tag = '0;
  assign io_resp_bits_stage1_entry_4_asid = '0;
  assign io_resp_bits_stage1_entry_4_vmid = '0;
  assign io_resp_bits_stage1_entry_4_n = '0;
  assign io_resp_bits_stage1_entry_4_pbmt = '0;
  assign io_resp_bits_stage1_entry_4_perm_d = '0;
  assign io_resp_bits_stage1_entry_4_perm_a = '0;
  assign io_resp_bits_stage1_entry_4_perm_g = '0;
  assign io_resp_bits_stage1_entry_4_perm_u = '0;
  assign io_resp_bits_stage1_entry_4_perm_x = '0;
  assign io_resp_bits_stage1_entry_4_perm_w = '0;
  assign io_resp_bits_stage1_entry_4_perm_r = '0;
  assign io_resp_bits_stage1_entry_4_level = '0;
  assign io_resp_bits_stage1_entry_4_v = '0;
  assign io_resp_bits_stage1_entry_4_ppn = '0;
  assign io_resp_bits_stage1_entry_4_ppn_low = '0;
  assign io_resp_bits_stage1_entry_4_pf = '0;
  assign io_resp_bits_stage1_entry_4_cf = '0;
  assign io_resp_bits_stage1_entry_5_tag = '0;
  assign io_resp_bits_stage1_entry_5_asid = '0;
  assign io_resp_bits_stage1_entry_5_vmid = '0;
  assign io_resp_bits_stage1_entry_5_n = '0;
  assign io_resp_bits_stage1_entry_5_pbmt = '0;
  assign io_resp_bits_stage1_entry_5_perm_d = '0;
  assign io_resp_bits_stage1_entry_5_perm_a = '0;
  assign io_resp_bits_stage1_entry_5_perm_g = '0;
  assign io_resp_bits_stage1_entry_5_perm_u = '0;
  assign io_resp_bits_stage1_entry_5_perm_x = '0;
  assign io_resp_bits_stage1_entry_5_perm_w = '0;
  assign io_resp_bits_stage1_entry_5_perm_r = '0;
  assign io_resp_bits_stage1_entry_5_level = '0;
  assign io_resp_bits_stage1_entry_5_v = '0;
  assign io_resp_bits_stage1_entry_5_ppn = '0;
  assign io_resp_bits_stage1_entry_5_ppn_low = '0;
  assign io_resp_bits_stage1_entry_5_pf = '0;
  assign io_resp_bits_stage1_entry_5_cf = '0;
  assign io_resp_bits_stage1_entry_6_tag = '0;
  assign io_resp_bits_stage1_entry_6_asid = '0;
  assign io_resp_bits_stage1_entry_6_vmid = '0;
  assign io_resp_bits_stage1_entry_6_n = '0;
  assign io_resp_bits_stage1_entry_6_pbmt = '0;
  assign io_resp_bits_stage1_entry_6_perm_d = '0;
  assign io_resp_bits_stage1_entry_6_perm_a = '0;
  assign io_resp_bits_stage1_entry_6_perm_g = '0;
  assign io_resp_bits_stage1_entry_6_perm_u = '0;
  assign io_resp_bits_stage1_entry_6_perm_x = '0;
  assign io_resp_bits_stage1_entry_6_perm_w = '0;
  assign io_resp_bits_stage1_entry_6_perm_r = '0;
  assign io_resp_bits_stage1_entry_6_level = '0;
  assign io_resp_bits_stage1_entry_6_v = '0;
  assign io_resp_bits_stage1_entry_6_ppn = '0;
  assign io_resp_bits_stage1_entry_6_ppn_low = '0;
  assign io_resp_bits_stage1_entry_6_pf = '0;
  assign io_resp_bits_stage1_entry_6_cf = '0;
  assign io_resp_bits_stage1_entry_7_tag = '0;
  assign io_resp_bits_stage1_entry_7_asid = '0;
  assign io_resp_bits_stage1_entry_7_vmid = '0;
  assign io_resp_bits_stage1_entry_7_n = '0;
  assign io_resp_bits_stage1_entry_7_pbmt = '0;
  assign io_resp_bits_stage1_entry_7_perm_d = '0;
  assign io_resp_bits_stage1_entry_7_perm_a = '0;
  assign io_resp_bits_stage1_entry_7_perm_g = '0;
  assign io_resp_bits_stage1_entry_7_perm_u = '0;
  assign io_resp_bits_stage1_entry_7_perm_x = '0;
  assign io_resp_bits_stage1_entry_7_perm_w = '0;
  assign io_resp_bits_stage1_entry_7_perm_r = '0;
  assign io_resp_bits_stage1_entry_7_level = '0;
  assign io_resp_bits_stage1_entry_7_v = '0;
  assign io_resp_bits_stage1_entry_7_ppn = '0;
  assign io_resp_bits_stage1_entry_7_ppn_low = '0;
  assign io_resp_bits_stage1_entry_7_pf = '0;
  assign io_resp_bits_stage1_entry_7_cf = '0;
  assign io_resp_bits_stage1_pteidx_0 = '0;
  assign io_resp_bits_stage1_pteidx_1 = '0;
  assign io_resp_bits_stage1_pteidx_2 = '0;
  assign io_resp_bits_stage1_pteidx_3 = '0;
  assign io_resp_bits_stage1_pteidx_4 = '0;
  assign io_resp_bits_stage1_pteidx_5 = '0;
  assign io_resp_bits_stage1_pteidx_6 = '0;
  assign io_resp_bits_stage1_pteidx_7 = '0;
  assign io_resp_bits_stage1_not_super = '0;
  assign io_resp_bits_isHptwReq = '0;
  assign io_resp_bits_toHptw_l3Hit = '0;
  assign io_resp_bits_toHptw_l2Hit = '0;
  assign io_resp_bits_toHptw_l1Hit = '0;
  assign io_resp_bits_toHptw_ppn = '0;
  assign io_resp_bits_toHptw_id = '0;
  assign io_resp_bits_toHptw_resp_entry_tag = '0;
  assign io_resp_bits_toHptw_resp_entry_vmid = '0;
  assign io_resp_bits_toHptw_resp_entry_n = '0;
  assign io_resp_bits_toHptw_resp_entry_pbmt = '0;
  assign io_resp_bits_toHptw_resp_entry_ppn = '0;
  assign io_resp_bits_toHptw_resp_entry_perm_d = '0;
  assign io_resp_bits_toHptw_resp_entry_perm_a = '0;
  assign io_resp_bits_toHptw_resp_entry_perm_g = '0;
  assign io_resp_bits_toHptw_resp_entry_perm_u = '0;
  assign io_resp_bits_toHptw_resp_entry_perm_x = '0;
  assign io_resp_bits_toHptw_resp_entry_perm_w = '0;
  assign io_resp_bits_toHptw_resp_entry_perm_r = '0;
  assign io_resp_bits_toHptw_resp_entry_level = '0;
  assign io_resp_bits_toHptw_resp_gpf = '0;
  assign io_resp_bits_toHptw_bypassed = '0;
  assign io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check = '0;
  assign io_resp_bits_toHptw_bitmapCheck_hitway = '0;
  assign io_resp_bits_toHptw_bitmapCheck_pte = '0;
  assign io_resp_bits_toHptw_bitmapCheck_ptes_0 = '0;
  assign io_resp_bits_toHptw_bitmapCheck_ptes_1 = '0;
  assign io_resp_bits_toHptw_bitmapCheck_ptes_2 = '0;
  assign io_resp_bits_toHptw_bitmapCheck_ptes_3 = '0;
  assign io_resp_bits_toHptw_bitmapCheck_ptes_4 = '0;
  assign io_resp_bits_toHptw_bitmapCheck_ptes_5 = '0;
  assign io_resp_bits_toHptw_bitmapCheck_ptes_6 = '0;
  assign io_resp_bits_toHptw_bitmapCheck_ptes_7 = '0;
  assign io_resp_bits_toHptw_bitmapCheck_fromSP = '0;
  assign io_resp_bits_toHptw_bitmapCheck_SPlevel = '0;
  assign io_perf_0_value = '0;
  assign io_perf_1_value = '0;
  assign io_perf_2_value = '0;
  assign io_perf_3_value = '0;
  assign io_perf_4_value = '0;
  assign io_perf_5_value = '0;
  assign io_perf_6_value = '0;
  assign io_perf_7_value = '0;

  // ---------------------------------------------------------------------------
  // §9 子模块例化（连线拓扑逐根抄自 golden，见 gen_ptwcache.py）
  //
  // l1 级 SRAM：4 组 2 路，每条表项 8 个 PDE。本仓尚无 SplittedSRAM_1 可读实现。
  SplittedSRAM_1 u_l1_sram (
    .clock                                 (l1_clk),
    .reset                                 (reset),
    .io_r_req_valid                        (l1_r_valid),
    .io_r_req_bits_setIdx                  (l1_r_set),
    .io_r_resp_data_0_entries_tag          (l1_rdata_0_tag),
    .io_r_resp_data_0_entries_asid         (l1_rdata_0_asid),
    .io_r_resp_data_0_entries_vmid         (l1_rdata_0_vmid),
    .io_r_resp_data_0_entries_pbmts_0      (l1_rdata_0_pbmts_0),
    .io_r_resp_data_0_entries_pbmts_1      (l1_rdata_0_pbmts_1),
    .io_r_resp_data_0_entries_pbmts_2      (l1_rdata_0_pbmts_2),
    .io_r_resp_data_0_entries_pbmts_3      (l1_rdata_0_pbmts_3),
    .io_r_resp_data_0_entries_pbmts_4      (l1_rdata_0_pbmts_4),
    .io_r_resp_data_0_entries_pbmts_5      (l1_rdata_0_pbmts_5),
    .io_r_resp_data_0_entries_pbmts_6      (l1_rdata_0_pbmts_6),
    .io_r_resp_data_0_entries_pbmts_7      (l1_rdata_0_pbmts_7),
    .io_r_resp_data_0_entries_ppns_0       (l1_rdata_0_ppns_0),
    .io_r_resp_data_0_entries_ppns_1       (l1_rdata_0_ppns_1),
    .io_r_resp_data_0_entries_ppns_2       (l1_rdata_0_ppns_2),
    .io_r_resp_data_0_entries_ppns_3       (l1_rdata_0_ppns_3),
    .io_r_resp_data_0_entries_ppns_4       (l1_rdata_0_ppns_4),
    .io_r_resp_data_0_entries_ppns_5       (l1_rdata_0_ppns_5),
    .io_r_resp_data_0_entries_ppns_6       (l1_rdata_0_ppns_6),
    .io_r_resp_data_0_entries_ppns_7       (l1_rdata_0_ppns_7),
    .io_r_resp_data_0_entries_vs_0         (l1_rdata_0_vs_0),
    .io_r_resp_data_0_entries_vs_1         (l1_rdata_0_vs_1),
    .io_r_resp_data_0_entries_vs_2         (l1_rdata_0_vs_2),
    .io_r_resp_data_0_entries_vs_3         (l1_rdata_0_vs_3),
    .io_r_resp_data_0_entries_vs_4         (l1_rdata_0_vs_4),
    .io_r_resp_data_0_entries_vs_5         (l1_rdata_0_vs_5),
    .io_r_resp_data_0_entries_vs_6         (l1_rdata_0_vs_6),
    .io_r_resp_data_0_entries_vs_7         (l1_rdata_0_vs_7),
    .io_r_resp_data_0_entries_prefetch     (l1_rdata_0_prefetch),
    .io_r_resp_data_1_entries_tag          (l1_rdata_1_tag),
    .io_r_resp_data_1_entries_asid         (l1_rdata_1_asid),
    .io_r_resp_data_1_entries_vmid         (l1_rdata_1_vmid),
    .io_r_resp_data_1_entries_pbmts_0      (l1_rdata_1_pbmts_0),
    .io_r_resp_data_1_entries_pbmts_1      (l1_rdata_1_pbmts_1),
    .io_r_resp_data_1_entries_pbmts_2      (l1_rdata_1_pbmts_2),
    .io_r_resp_data_1_entries_pbmts_3      (l1_rdata_1_pbmts_3),
    .io_r_resp_data_1_entries_pbmts_4      (l1_rdata_1_pbmts_4),
    .io_r_resp_data_1_entries_pbmts_5      (l1_rdata_1_pbmts_5),
    .io_r_resp_data_1_entries_pbmts_6      (l1_rdata_1_pbmts_6),
    .io_r_resp_data_1_entries_pbmts_7      (l1_rdata_1_pbmts_7),
    .io_r_resp_data_1_entries_ppns_0       (l1_rdata_1_ppns_0),
    .io_r_resp_data_1_entries_ppns_1       (l1_rdata_1_ppns_1),
    .io_r_resp_data_1_entries_ppns_2       (l1_rdata_1_ppns_2),
    .io_r_resp_data_1_entries_ppns_3       (l1_rdata_1_ppns_3),
    .io_r_resp_data_1_entries_ppns_4       (l1_rdata_1_ppns_4),
    .io_r_resp_data_1_entries_ppns_5       (l1_rdata_1_ppns_5),
    .io_r_resp_data_1_entries_ppns_6       (l1_rdata_1_ppns_6),
    .io_r_resp_data_1_entries_ppns_7       (l1_rdata_1_ppns_7),
    .io_r_resp_data_1_entries_vs_0         (l1_rdata_1_vs_0),
    .io_r_resp_data_1_entries_vs_1         (l1_rdata_1_vs_1),
    .io_r_resp_data_1_entries_vs_2         (l1_rdata_1_vs_2),
    .io_r_resp_data_1_entries_vs_3         (l1_rdata_1_vs_3),
    .io_r_resp_data_1_entries_vs_4         (l1_rdata_1_vs_4),
    .io_r_resp_data_1_entries_vs_5         (l1_rdata_1_vs_5),
    .io_r_resp_data_1_entries_vs_6         (l1_rdata_1_vs_6),
    .io_r_resp_data_1_entries_vs_7         (l1_rdata_1_vs_7),
    .io_r_resp_data_1_entries_prefetch     (l1_rdata_1_prefetch),
    .io_w_req_valid                        (l1_refill),
    .io_w_req_bits_setIdx                  (l1_w_set),
    .io_w_req_bits_data_0_entries_tag      (l1_w_tag),
    .io_w_req_bits_data_0_entries_asid     (l1_w_asid),
    .io_w_req_bits_data_0_entries_vmid     (l1_w_vmid),
    .io_w_req_bits_data_0_entries_pbmts_0  (refill_pte[0][62:61]),
    .io_w_req_bits_data_0_entries_pbmts_1  (refill_pte[1][62:61]),
    .io_w_req_bits_data_0_entries_pbmts_2  (refill_pte[2][62:61]),
    .io_w_req_bits_data_0_entries_pbmts_3  (refill_pte[3][62:61]),
    .io_w_req_bits_data_0_entries_pbmts_4  (refill_pte[4][62:61]),
    .io_w_req_bits_data_0_entries_pbmts_5  (refill_pte[5][62:61]),
    .io_w_req_bits_data_0_entries_pbmts_6  (refill_pte[6][62:61]),
    .io_w_req_bits_data_0_entries_pbmts_7  (refill_pte[7][62:61]),
    .io_w_req_bits_data_0_entries_ppns_0   (refill_pte[0][47:10]),
    .io_w_req_bits_data_0_entries_ppns_1   (refill_pte[1][47:10]),
    .io_w_req_bits_data_0_entries_ppns_2   (refill_pte[2][47:10]),
    .io_w_req_bits_data_0_entries_ppns_3   (refill_pte[3][47:10]),
    .io_w_req_bits_data_0_entries_ppns_4   (refill_pte[4][47:10]),
    .io_w_req_bits_data_0_entries_ppns_5   (refill_pte[5][47:10]),
    .io_w_req_bits_data_0_entries_ppns_6   (refill_pte[6][47:10]),
    .io_w_req_bits_data_0_entries_ppns_7   (refill_pte[7][47:10]),
    .io_w_req_bits_data_0_entries_vs_0     (l1_w_vs[0]),
    .io_w_req_bits_data_0_entries_vs_1     (l1_w_vs[1]),
    .io_w_req_bits_data_0_entries_vs_2     (l1_w_vs[2]),
    .io_w_req_bits_data_0_entries_vs_3     (l1_w_vs[3]),
    .io_w_req_bits_data_0_entries_vs_4     (l1_w_vs[4]),
    .io_w_req_bits_data_0_entries_vs_5     (l1_w_vs[5]),
    .io_w_req_bits_data_0_entries_vs_6     (l1_w_vs[6]),
    .io_w_req_bits_data_0_entries_vs_7     (l1_w_vs[7]),
    .io_w_req_bits_data_0_entries_prefetch (l1_w_prefetch),
    .io_w_req_bits_data_1_entries_tag      (l1_w_tag),
    .io_w_req_bits_data_1_entries_asid     (l1_w_asid),
    .io_w_req_bits_data_1_entries_vmid     (l1_w_vmid),
    .io_w_req_bits_data_1_entries_pbmts_0  (refill_pte[0][62:61]),
    .io_w_req_bits_data_1_entries_pbmts_1  (refill_pte[1][62:61]),
    .io_w_req_bits_data_1_entries_pbmts_2  (refill_pte[2][62:61]),
    .io_w_req_bits_data_1_entries_pbmts_3  (refill_pte[3][62:61]),
    .io_w_req_bits_data_1_entries_pbmts_4  (refill_pte[4][62:61]),
    .io_w_req_bits_data_1_entries_pbmts_5  (refill_pte[5][62:61]),
    .io_w_req_bits_data_1_entries_pbmts_6  (refill_pte[6][62:61]),
    .io_w_req_bits_data_1_entries_pbmts_7  (refill_pte[7][62:61]),
    .io_w_req_bits_data_1_entries_ppns_0   (refill_pte[0][47:10]),
    .io_w_req_bits_data_1_entries_ppns_1   (refill_pte[1][47:10]),
    .io_w_req_bits_data_1_entries_ppns_2   (refill_pte[2][47:10]),
    .io_w_req_bits_data_1_entries_ppns_3   (refill_pte[3][47:10]),
    .io_w_req_bits_data_1_entries_ppns_4   (refill_pte[4][47:10]),
    .io_w_req_bits_data_1_entries_ppns_5   (refill_pte[5][47:10]),
    .io_w_req_bits_data_1_entries_ppns_6   (refill_pte[6][47:10]),
    .io_w_req_bits_data_1_entries_ppns_7   (refill_pte[7][47:10]),
    .io_w_req_bits_data_1_entries_vs_0     (l1_w_vs[0]),
    .io_w_req_bits_data_1_entries_vs_1     (l1_w_vs[1]),
    .io_w_req_bits_data_1_entries_vs_2     (l1_w_vs[2]),
    .io_w_req_bits_data_1_entries_vs_3     (l1_w_vs[3]),
    .io_w_req_bits_data_1_entries_vs_4     (l1_w_vs[4]),
    .io_w_req_bits_data_1_entries_vs_5     (l1_w_vs[5]),
    .io_w_req_bits_data_1_entries_vs_6     (l1_w_vs[6]),
    .io_w_req_bits_data_1_entries_vs_7     (l1_w_vs[7]),
    .io_w_req_bits_data_1_entries_prefetch (l1_w_prefetch),
    .io_w_req_bits_waymask                 (l1_w_waymask),
    .boreChildrenBd_bore_addr              (childBd_addr),
    .boreChildrenBd_bore_addr_rd           (childBd_addr_rd),
    .boreChildrenBd_bore_wdata             (childBd_wdata),
    .boreChildrenBd_bore_wmask             (childBd_wmask),
    .boreChildrenBd_bore_re                (childBd_re),
    .boreChildrenBd_bore_we                (childBd_we),
    .boreChildrenBd_bore_rdata             (childBd_rdata),
    .boreChildrenBd_bore_ack               (childBd_ack),
    .boreChildrenBd_bore_selectedOH        (childBd_selectedOH),
    .boreChildrenBd_bore_array             (childBd_array),
    .sigFromSrams_bore_ram_hold            (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass          (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken        (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk         (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp        (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold        (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen                (sigFromSrams_bore_cgen)
  );

  // l1 级 MBIST 分发（可读实现在 rtl/dft/MbistPipePtwL1.sv）
  MbistPipePtwL1 u_mbist_l1 (
    .clock               (clock),
    .reset               (reset),
    .mbist_array         (boreChildrenBd_bore_array),
    .mbist_all           (boreChildrenBd_bore_all),
    .mbist_req           (boreChildrenBd_bore_req),
    .mbist_ack           (boreChildrenBd_bore_ack),
    .mbist_writeen       (boreChildrenBd_bore_writeen),
    .mbist_be            (boreChildrenBd_bore_be),
    .mbist_addr          (boreChildrenBd_bore_addr),
    .mbist_indata        (boreChildrenBd_bore_indata),
    .mbist_readen        (boreChildrenBd_bore_readen),
    .mbist_addr_rd       (boreChildrenBd_bore_addr_rd),
    .mbist_outdata       (boreChildrenBd_bore_outdata),
    .toSRAM_0_addr       (childBd_addr),
    .toSRAM_0_addr_rd    (childBd_addr_rd),
    .toSRAM_0_wdata      (childBd_wdata),
    .toSRAM_0_wmask      (childBd_wmask),
    .toSRAM_0_re         (childBd_re),
    .toSRAM_0_we         (childBd_we),
    .toSRAM_0_rdata      (childBd_rdata),
    .toSRAM_0_ack        (childBd_ack),
    .toSRAM_0_selectedOH (childBd_selectedOH),
    .toSRAM_0_array      (childBd_array)
  );

  // l0 级 SRAM：64 组 4 路，每条表项 8 个 PTE。本仓尚无 SplittedSRAM_2 可读实现。
  SplittedSRAM_2 u_l0_sram (
    .clock                                  (l0_clk),
    .reset                                  (reset),
    .io_r_req_valid                         (l0_r_valid),
    .io_r_req_bits_setIdx                   (l0_r_set),
    .io_r_resp_data_0_entries_tag           (l0_rdata_0_tag),
    .io_r_resp_data_0_entries_asid          (l0_rdata_0_asid),
    .io_r_resp_data_0_entries_vmid          (l0_rdata_0_vmid),
    .io_r_resp_data_0_entries_pbmts_0       (l0_rdata_0_pbmts_0),
    .io_r_resp_data_0_entries_pbmts_1       (l0_rdata_0_pbmts_1),
    .io_r_resp_data_0_entries_pbmts_2       (l0_rdata_0_pbmts_2),
    .io_r_resp_data_0_entries_pbmts_3       (l0_rdata_0_pbmts_3),
    .io_r_resp_data_0_entries_pbmts_4       (l0_rdata_0_pbmts_4),
    .io_r_resp_data_0_entries_pbmts_5       (l0_rdata_0_pbmts_5),
    .io_r_resp_data_0_entries_pbmts_6       (l0_rdata_0_pbmts_6),
    .io_r_resp_data_0_entries_pbmts_7       (l0_rdata_0_pbmts_7),
    .io_r_resp_data_0_entries_ppns_0        (l0_rdata_0_ppns_0),
    .io_r_resp_data_0_entries_ppns_1        (l0_rdata_0_ppns_1),
    .io_r_resp_data_0_entries_ppns_2        (l0_rdata_0_ppns_2),
    .io_r_resp_data_0_entries_ppns_3        (l0_rdata_0_ppns_3),
    .io_r_resp_data_0_entries_ppns_4        (l0_rdata_0_ppns_4),
    .io_r_resp_data_0_entries_ppns_5        (l0_rdata_0_ppns_5),
    .io_r_resp_data_0_entries_ppns_6        (l0_rdata_0_ppns_6),
    .io_r_resp_data_0_entries_ppns_7        (l0_rdata_0_ppns_7),
    .io_r_resp_data_0_entries_vs_0          (l0_rdata_0_vs_0),
    .io_r_resp_data_0_entries_vs_1          (l0_rdata_0_vs_1),
    .io_r_resp_data_0_entries_vs_2          (l0_rdata_0_vs_2),
    .io_r_resp_data_0_entries_vs_3          (l0_rdata_0_vs_3),
    .io_r_resp_data_0_entries_vs_4          (l0_rdata_0_vs_4),
    .io_r_resp_data_0_entries_vs_5          (l0_rdata_0_vs_5),
    .io_r_resp_data_0_entries_vs_6          (l0_rdata_0_vs_6),
    .io_r_resp_data_0_entries_vs_7          (l0_rdata_0_vs_7),
    .io_r_resp_data_0_entries_onlypf_0      (l0_rdata_0_onlypf_0),
    .io_r_resp_data_0_entries_onlypf_1      (l0_rdata_0_onlypf_1),
    .io_r_resp_data_0_entries_onlypf_2      (l0_rdata_0_onlypf_2),
    .io_r_resp_data_0_entries_onlypf_3      (l0_rdata_0_onlypf_3),
    .io_r_resp_data_0_entries_onlypf_4      (l0_rdata_0_onlypf_4),
    .io_r_resp_data_0_entries_onlypf_5      (l0_rdata_0_onlypf_5),
    .io_r_resp_data_0_entries_onlypf_6      (l0_rdata_0_onlypf_6),
    .io_r_resp_data_0_entries_onlypf_7      (l0_rdata_0_onlypf_7),
    .io_r_resp_data_0_entries_perms_0_d     (l0_rdata_0_perms_0_d),
    .io_r_resp_data_0_entries_perms_0_a     (l0_rdata_0_perms_0_a),
    .io_r_resp_data_0_entries_perms_0_g     (l0_rdata_0_perms_0_g),
    .io_r_resp_data_0_entries_perms_0_u     (l0_rdata_0_perms_0_u),
    .io_r_resp_data_0_entries_perms_0_x     (l0_rdata_0_perms_0_x),
    .io_r_resp_data_0_entries_perms_0_w     (l0_rdata_0_perms_0_w),
    .io_r_resp_data_0_entries_perms_0_r     (l0_rdata_0_perms_0_r),
    .io_r_resp_data_0_entries_perms_1_d     (l0_rdata_0_perms_1_d),
    .io_r_resp_data_0_entries_perms_1_a     (l0_rdata_0_perms_1_a),
    .io_r_resp_data_0_entries_perms_1_g     (l0_rdata_0_perms_1_g),
    .io_r_resp_data_0_entries_perms_1_u     (l0_rdata_0_perms_1_u),
    .io_r_resp_data_0_entries_perms_1_x     (l0_rdata_0_perms_1_x),
    .io_r_resp_data_0_entries_perms_1_w     (l0_rdata_0_perms_1_w),
    .io_r_resp_data_0_entries_perms_1_r     (l0_rdata_0_perms_1_r),
    .io_r_resp_data_0_entries_perms_2_d     (l0_rdata_0_perms_2_d),
    .io_r_resp_data_0_entries_perms_2_a     (l0_rdata_0_perms_2_a),
    .io_r_resp_data_0_entries_perms_2_g     (l0_rdata_0_perms_2_g),
    .io_r_resp_data_0_entries_perms_2_u     (l0_rdata_0_perms_2_u),
    .io_r_resp_data_0_entries_perms_2_x     (l0_rdata_0_perms_2_x),
    .io_r_resp_data_0_entries_perms_2_w     (l0_rdata_0_perms_2_w),
    .io_r_resp_data_0_entries_perms_2_r     (l0_rdata_0_perms_2_r),
    .io_r_resp_data_0_entries_perms_3_d     (l0_rdata_0_perms_3_d),
    .io_r_resp_data_0_entries_perms_3_a     (l0_rdata_0_perms_3_a),
    .io_r_resp_data_0_entries_perms_3_g     (l0_rdata_0_perms_3_g),
    .io_r_resp_data_0_entries_perms_3_u     (l0_rdata_0_perms_3_u),
    .io_r_resp_data_0_entries_perms_3_x     (l0_rdata_0_perms_3_x),
    .io_r_resp_data_0_entries_perms_3_w     (l0_rdata_0_perms_3_w),
    .io_r_resp_data_0_entries_perms_3_r     (l0_rdata_0_perms_3_r),
    .io_r_resp_data_0_entries_perms_4_d     (l0_rdata_0_perms_4_d),
    .io_r_resp_data_0_entries_perms_4_a     (l0_rdata_0_perms_4_a),
    .io_r_resp_data_0_entries_perms_4_g     (l0_rdata_0_perms_4_g),
    .io_r_resp_data_0_entries_perms_4_u     (l0_rdata_0_perms_4_u),
    .io_r_resp_data_0_entries_perms_4_x     (l0_rdata_0_perms_4_x),
    .io_r_resp_data_0_entries_perms_4_w     (l0_rdata_0_perms_4_w),
    .io_r_resp_data_0_entries_perms_4_r     (l0_rdata_0_perms_4_r),
    .io_r_resp_data_0_entries_perms_5_d     (l0_rdata_0_perms_5_d),
    .io_r_resp_data_0_entries_perms_5_a     (l0_rdata_0_perms_5_a),
    .io_r_resp_data_0_entries_perms_5_g     (l0_rdata_0_perms_5_g),
    .io_r_resp_data_0_entries_perms_5_u     (l0_rdata_0_perms_5_u),
    .io_r_resp_data_0_entries_perms_5_x     (l0_rdata_0_perms_5_x),
    .io_r_resp_data_0_entries_perms_5_w     (l0_rdata_0_perms_5_w),
    .io_r_resp_data_0_entries_perms_5_r     (l0_rdata_0_perms_5_r),
    .io_r_resp_data_0_entries_perms_6_d     (l0_rdata_0_perms_6_d),
    .io_r_resp_data_0_entries_perms_6_a     (l0_rdata_0_perms_6_a),
    .io_r_resp_data_0_entries_perms_6_g     (l0_rdata_0_perms_6_g),
    .io_r_resp_data_0_entries_perms_6_u     (l0_rdata_0_perms_6_u),
    .io_r_resp_data_0_entries_perms_6_x     (l0_rdata_0_perms_6_x),
    .io_r_resp_data_0_entries_perms_6_w     (l0_rdata_0_perms_6_w),
    .io_r_resp_data_0_entries_perms_6_r     (l0_rdata_0_perms_6_r),
    .io_r_resp_data_0_entries_perms_7_d     (l0_rdata_0_perms_7_d),
    .io_r_resp_data_0_entries_perms_7_a     (l0_rdata_0_perms_7_a),
    .io_r_resp_data_0_entries_perms_7_g     (l0_rdata_0_perms_7_g),
    .io_r_resp_data_0_entries_perms_7_u     (l0_rdata_0_perms_7_u),
    .io_r_resp_data_0_entries_perms_7_x     (l0_rdata_0_perms_7_x),
    .io_r_resp_data_0_entries_perms_7_w     (l0_rdata_0_perms_7_w),
    .io_r_resp_data_0_entries_perms_7_r     (l0_rdata_0_perms_7_r),
    .io_r_resp_data_0_entries_prefetch      (l0_rdata_0_prefetch),
    .io_r_resp_data_1_entries_tag           (l0_rdata_1_tag),
    .io_r_resp_data_1_entries_asid          (l0_rdata_1_asid),
    .io_r_resp_data_1_entries_vmid          (l0_rdata_1_vmid),
    .io_r_resp_data_1_entries_pbmts_0       (l0_rdata_1_pbmts_0),
    .io_r_resp_data_1_entries_pbmts_1       (l0_rdata_1_pbmts_1),
    .io_r_resp_data_1_entries_pbmts_2       (l0_rdata_1_pbmts_2),
    .io_r_resp_data_1_entries_pbmts_3       (l0_rdata_1_pbmts_3),
    .io_r_resp_data_1_entries_pbmts_4       (l0_rdata_1_pbmts_4),
    .io_r_resp_data_1_entries_pbmts_5       (l0_rdata_1_pbmts_5),
    .io_r_resp_data_1_entries_pbmts_6       (l0_rdata_1_pbmts_6),
    .io_r_resp_data_1_entries_pbmts_7       (l0_rdata_1_pbmts_7),
    .io_r_resp_data_1_entries_ppns_0        (l0_rdata_1_ppns_0),
    .io_r_resp_data_1_entries_ppns_1        (l0_rdata_1_ppns_1),
    .io_r_resp_data_1_entries_ppns_2        (l0_rdata_1_ppns_2),
    .io_r_resp_data_1_entries_ppns_3        (l0_rdata_1_ppns_3),
    .io_r_resp_data_1_entries_ppns_4        (l0_rdata_1_ppns_4),
    .io_r_resp_data_1_entries_ppns_5        (l0_rdata_1_ppns_5),
    .io_r_resp_data_1_entries_ppns_6        (l0_rdata_1_ppns_6),
    .io_r_resp_data_1_entries_ppns_7        (l0_rdata_1_ppns_7),
    .io_r_resp_data_1_entries_vs_0          (l0_rdata_1_vs_0),
    .io_r_resp_data_1_entries_vs_1          (l0_rdata_1_vs_1),
    .io_r_resp_data_1_entries_vs_2          (l0_rdata_1_vs_2),
    .io_r_resp_data_1_entries_vs_3          (l0_rdata_1_vs_3),
    .io_r_resp_data_1_entries_vs_4          (l0_rdata_1_vs_4),
    .io_r_resp_data_1_entries_vs_5          (l0_rdata_1_vs_5),
    .io_r_resp_data_1_entries_vs_6          (l0_rdata_1_vs_6),
    .io_r_resp_data_1_entries_vs_7          (l0_rdata_1_vs_7),
    .io_r_resp_data_1_entries_onlypf_0      (l0_rdata_1_onlypf_0),
    .io_r_resp_data_1_entries_onlypf_1      (l0_rdata_1_onlypf_1),
    .io_r_resp_data_1_entries_onlypf_2      (l0_rdata_1_onlypf_2),
    .io_r_resp_data_1_entries_onlypf_3      (l0_rdata_1_onlypf_3),
    .io_r_resp_data_1_entries_onlypf_4      (l0_rdata_1_onlypf_4),
    .io_r_resp_data_1_entries_onlypf_5      (l0_rdata_1_onlypf_5),
    .io_r_resp_data_1_entries_onlypf_6      (l0_rdata_1_onlypf_6),
    .io_r_resp_data_1_entries_onlypf_7      (l0_rdata_1_onlypf_7),
    .io_r_resp_data_1_entries_perms_0_d     (l0_rdata_1_perms_0_d),
    .io_r_resp_data_1_entries_perms_0_a     (l0_rdata_1_perms_0_a),
    .io_r_resp_data_1_entries_perms_0_g     (l0_rdata_1_perms_0_g),
    .io_r_resp_data_1_entries_perms_0_u     (l0_rdata_1_perms_0_u),
    .io_r_resp_data_1_entries_perms_0_x     (l0_rdata_1_perms_0_x),
    .io_r_resp_data_1_entries_perms_0_w     (l0_rdata_1_perms_0_w),
    .io_r_resp_data_1_entries_perms_0_r     (l0_rdata_1_perms_0_r),
    .io_r_resp_data_1_entries_perms_1_d     (l0_rdata_1_perms_1_d),
    .io_r_resp_data_1_entries_perms_1_a     (l0_rdata_1_perms_1_a),
    .io_r_resp_data_1_entries_perms_1_g     (l0_rdata_1_perms_1_g),
    .io_r_resp_data_1_entries_perms_1_u     (l0_rdata_1_perms_1_u),
    .io_r_resp_data_1_entries_perms_1_x     (l0_rdata_1_perms_1_x),
    .io_r_resp_data_1_entries_perms_1_w     (l0_rdata_1_perms_1_w),
    .io_r_resp_data_1_entries_perms_1_r     (l0_rdata_1_perms_1_r),
    .io_r_resp_data_1_entries_perms_2_d     (l0_rdata_1_perms_2_d),
    .io_r_resp_data_1_entries_perms_2_a     (l0_rdata_1_perms_2_a),
    .io_r_resp_data_1_entries_perms_2_g     (l0_rdata_1_perms_2_g),
    .io_r_resp_data_1_entries_perms_2_u     (l0_rdata_1_perms_2_u),
    .io_r_resp_data_1_entries_perms_2_x     (l0_rdata_1_perms_2_x),
    .io_r_resp_data_1_entries_perms_2_w     (l0_rdata_1_perms_2_w),
    .io_r_resp_data_1_entries_perms_2_r     (l0_rdata_1_perms_2_r),
    .io_r_resp_data_1_entries_perms_3_d     (l0_rdata_1_perms_3_d),
    .io_r_resp_data_1_entries_perms_3_a     (l0_rdata_1_perms_3_a),
    .io_r_resp_data_1_entries_perms_3_g     (l0_rdata_1_perms_3_g),
    .io_r_resp_data_1_entries_perms_3_u     (l0_rdata_1_perms_3_u),
    .io_r_resp_data_1_entries_perms_3_x     (l0_rdata_1_perms_3_x),
    .io_r_resp_data_1_entries_perms_3_w     (l0_rdata_1_perms_3_w),
    .io_r_resp_data_1_entries_perms_3_r     (l0_rdata_1_perms_3_r),
    .io_r_resp_data_1_entries_perms_4_d     (l0_rdata_1_perms_4_d),
    .io_r_resp_data_1_entries_perms_4_a     (l0_rdata_1_perms_4_a),
    .io_r_resp_data_1_entries_perms_4_g     (l0_rdata_1_perms_4_g),
    .io_r_resp_data_1_entries_perms_4_u     (l0_rdata_1_perms_4_u),
    .io_r_resp_data_1_entries_perms_4_x     (l0_rdata_1_perms_4_x),
    .io_r_resp_data_1_entries_perms_4_w     (l0_rdata_1_perms_4_w),
    .io_r_resp_data_1_entries_perms_4_r     (l0_rdata_1_perms_4_r),
    .io_r_resp_data_1_entries_perms_5_d     (l0_rdata_1_perms_5_d),
    .io_r_resp_data_1_entries_perms_5_a     (l0_rdata_1_perms_5_a),
    .io_r_resp_data_1_entries_perms_5_g     (l0_rdata_1_perms_5_g),
    .io_r_resp_data_1_entries_perms_5_u     (l0_rdata_1_perms_5_u),
    .io_r_resp_data_1_entries_perms_5_x     (l0_rdata_1_perms_5_x),
    .io_r_resp_data_1_entries_perms_5_w     (l0_rdata_1_perms_5_w),
    .io_r_resp_data_1_entries_perms_5_r     (l0_rdata_1_perms_5_r),
    .io_r_resp_data_1_entries_perms_6_d     (l0_rdata_1_perms_6_d),
    .io_r_resp_data_1_entries_perms_6_a     (l0_rdata_1_perms_6_a),
    .io_r_resp_data_1_entries_perms_6_g     (l0_rdata_1_perms_6_g),
    .io_r_resp_data_1_entries_perms_6_u     (l0_rdata_1_perms_6_u),
    .io_r_resp_data_1_entries_perms_6_x     (l0_rdata_1_perms_6_x),
    .io_r_resp_data_1_entries_perms_6_w     (l0_rdata_1_perms_6_w),
    .io_r_resp_data_1_entries_perms_6_r     (l0_rdata_1_perms_6_r),
    .io_r_resp_data_1_entries_perms_7_d     (l0_rdata_1_perms_7_d),
    .io_r_resp_data_1_entries_perms_7_a     (l0_rdata_1_perms_7_a),
    .io_r_resp_data_1_entries_perms_7_g     (l0_rdata_1_perms_7_g),
    .io_r_resp_data_1_entries_perms_7_u     (l0_rdata_1_perms_7_u),
    .io_r_resp_data_1_entries_perms_7_x     (l0_rdata_1_perms_7_x),
    .io_r_resp_data_1_entries_perms_7_w     (l0_rdata_1_perms_7_w),
    .io_r_resp_data_1_entries_perms_7_r     (l0_rdata_1_perms_7_r),
    .io_r_resp_data_1_entries_prefetch      (l0_rdata_1_prefetch),
    .io_r_resp_data_2_entries_tag           (l0_rdata_2_tag),
    .io_r_resp_data_2_entries_asid          (l0_rdata_2_asid),
    .io_r_resp_data_2_entries_vmid          (l0_rdata_2_vmid),
    .io_r_resp_data_2_entries_pbmts_0       (l0_rdata_2_pbmts_0),
    .io_r_resp_data_2_entries_pbmts_1       (l0_rdata_2_pbmts_1),
    .io_r_resp_data_2_entries_pbmts_2       (l0_rdata_2_pbmts_2),
    .io_r_resp_data_2_entries_pbmts_3       (l0_rdata_2_pbmts_3),
    .io_r_resp_data_2_entries_pbmts_4       (l0_rdata_2_pbmts_4),
    .io_r_resp_data_2_entries_pbmts_5       (l0_rdata_2_pbmts_5),
    .io_r_resp_data_2_entries_pbmts_6       (l0_rdata_2_pbmts_6),
    .io_r_resp_data_2_entries_pbmts_7       (l0_rdata_2_pbmts_7),
    .io_r_resp_data_2_entries_ppns_0        (l0_rdata_2_ppns_0),
    .io_r_resp_data_2_entries_ppns_1        (l0_rdata_2_ppns_1),
    .io_r_resp_data_2_entries_ppns_2        (l0_rdata_2_ppns_2),
    .io_r_resp_data_2_entries_ppns_3        (l0_rdata_2_ppns_3),
    .io_r_resp_data_2_entries_ppns_4        (l0_rdata_2_ppns_4),
    .io_r_resp_data_2_entries_ppns_5        (l0_rdata_2_ppns_5),
    .io_r_resp_data_2_entries_ppns_6        (l0_rdata_2_ppns_6),
    .io_r_resp_data_2_entries_ppns_7        (l0_rdata_2_ppns_7),
    .io_r_resp_data_2_entries_vs_0          (l0_rdata_2_vs_0),
    .io_r_resp_data_2_entries_vs_1          (l0_rdata_2_vs_1),
    .io_r_resp_data_2_entries_vs_2          (l0_rdata_2_vs_2),
    .io_r_resp_data_2_entries_vs_3          (l0_rdata_2_vs_3),
    .io_r_resp_data_2_entries_vs_4          (l0_rdata_2_vs_4),
    .io_r_resp_data_2_entries_vs_5          (l0_rdata_2_vs_5),
    .io_r_resp_data_2_entries_vs_6          (l0_rdata_2_vs_6),
    .io_r_resp_data_2_entries_vs_7          (l0_rdata_2_vs_7),
    .io_r_resp_data_2_entries_onlypf_0      (l0_rdata_2_onlypf_0),
    .io_r_resp_data_2_entries_onlypf_1      (l0_rdata_2_onlypf_1),
    .io_r_resp_data_2_entries_onlypf_2      (l0_rdata_2_onlypf_2),
    .io_r_resp_data_2_entries_onlypf_3      (l0_rdata_2_onlypf_3),
    .io_r_resp_data_2_entries_onlypf_4      (l0_rdata_2_onlypf_4),
    .io_r_resp_data_2_entries_onlypf_5      (l0_rdata_2_onlypf_5),
    .io_r_resp_data_2_entries_onlypf_6      (l0_rdata_2_onlypf_6),
    .io_r_resp_data_2_entries_onlypf_7      (l0_rdata_2_onlypf_7),
    .io_r_resp_data_2_entries_perms_0_d     (l0_rdata_2_perms_0_d),
    .io_r_resp_data_2_entries_perms_0_a     (l0_rdata_2_perms_0_a),
    .io_r_resp_data_2_entries_perms_0_g     (l0_rdata_2_perms_0_g),
    .io_r_resp_data_2_entries_perms_0_u     (l0_rdata_2_perms_0_u),
    .io_r_resp_data_2_entries_perms_0_x     (l0_rdata_2_perms_0_x),
    .io_r_resp_data_2_entries_perms_0_w     (l0_rdata_2_perms_0_w),
    .io_r_resp_data_2_entries_perms_0_r     (l0_rdata_2_perms_0_r),
    .io_r_resp_data_2_entries_perms_1_d     (l0_rdata_2_perms_1_d),
    .io_r_resp_data_2_entries_perms_1_a     (l0_rdata_2_perms_1_a),
    .io_r_resp_data_2_entries_perms_1_g     (l0_rdata_2_perms_1_g),
    .io_r_resp_data_2_entries_perms_1_u     (l0_rdata_2_perms_1_u),
    .io_r_resp_data_2_entries_perms_1_x     (l0_rdata_2_perms_1_x),
    .io_r_resp_data_2_entries_perms_1_w     (l0_rdata_2_perms_1_w),
    .io_r_resp_data_2_entries_perms_1_r     (l0_rdata_2_perms_1_r),
    .io_r_resp_data_2_entries_perms_2_d     (l0_rdata_2_perms_2_d),
    .io_r_resp_data_2_entries_perms_2_a     (l0_rdata_2_perms_2_a),
    .io_r_resp_data_2_entries_perms_2_g     (l0_rdata_2_perms_2_g),
    .io_r_resp_data_2_entries_perms_2_u     (l0_rdata_2_perms_2_u),
    .io_r_resp_data_2_entries_perms_2_x     (l0_rdata_2_perms_2_x),
    .io_r_resp_data_2_entries_perms_2_w     (l0_rdata_2_perms_2_w),
    .io_r_resp_data_2_entries_perms_2_r     (l0_rdata_2_perms_2_r),
    .io_r_resp_data_2_entries_perms_3_d     (l0_rdata_2_perms_3_d),
    .io_r_resp_data_2_entries_perms_3_a     (l0_rdata_2_perms_3_a),
    .io_r_resp_data_2_entries_perms_3_g     (l0_rdata_2_perms_3_g),
    .io_r_resp_data_2_entries_perms_3_u     (l0_rdata_2_perms_3_u),
    .io_r_resp_data_2_entries_perms_3_x     (l0_rdata_2_perms_3_x),
    .io_r_resp_data_2_entries_perms_3_w     (l0_rdata_2_perms_3_w),
    .io_r_resp_data_2_entries_perms_3_r     (l0_rdata_2_perms_3_r),
    .io_r_resp_data_2_entries_perms_4_d     (l0_rdata_2_perms_4_d),
    .io_r_resp_data_2_entries_perms_4_a     (l0_rdata_2_perms_4_a),
    .io_r_resp_data_2_entries_perms_4_g     (l0_rdata_2_perms_4_g),
    .io_r_resp_data_2_entries_perms_4_u     (l0_rdata_2_perms_4_u),
    .io_r_resp_data_2_entries_perms_4_x     (l0_rdata_2_perms_4_x),
    .io_r_resp_data_2_entries_perms_4_w     (l0_rdata_2_perms_4_w),
    .io_r_resp_data_2_entries_perms_4_r     (l0_rdata_2_perms_4_r),
    .io_r_resp_data_2_entries_perms_5_d     (l0_rdata_2_perms_5_d),
    .io_r_resp_data_2_entries_perms_5_a     (l0_rdata_2_perms_5_a),
    .io_r_resp_data_2_entries_perms_5_g     (l0_rdata_2_perms_5_g),
    .io_r_resp_data_2_entries_perms_5_u     (l0_rdata_2_perms_5_u),
    .io_r_resp_data_2_entries_perms_5_x     (l0_rdata_2_perms_5_x),
    .io_r_resp_data_2_entries_perms_5_w     (l0_rdata_2_perms_5_w),
    .io_r_resp_data_2_entries_perms_5_r     (l0_rdata_2_perms_5_r),
    .io_r_resp_data_2_entries_perms_6_d     (l0_rdata_2_perms_6_d),
    .io_r_resp_data_2_entries_perms_6_a     (l0_rdata_2_perms_6_a),
    .io_r_resp_data_2_entries_perms_6_g     (l0_rdata_2_perms_6_g),
    .io_r_resp_data_2_entries_perms_6_u     (l0_rdata_2_perms_6_u),
    .io_r_resp_data_2_entries_perms_6_x     (l0_rdata_2_perms_6_x),
    .io_r_resp_data_2_entries_perms_6_w     (l0_rdata_2_perms_6_w),
    .io_r_resp_data_2_entries_perms_6_r     (l0_rdata_2_perms_6_r),
    .io_r_resp_data_2_entries_perms_7_d     (l0_rdata_2_perms_7_d),
    .io_r_resp_data_2_entries_perms_7_a     (l0_rdata_2_perms_7_a),
    .io_r_resp_data_2_entries_perms_7_g     (l0_rdata_2_perms_7_g),
    .io_r_resp_data_2_entries_perms_7_u     (l0_rdata_2_perms_7_u),
    .io_r_resp_data_2_entries_perms_7_x     (l0_rdata_2_perms_7_x),
    .io_r_resp_data_2_entries_perms_7_w     (l0_rdata_2_perms_7_w),
    .io_r_resp_data_2_entries_perms_7_r     (l0_rdata_2_perms_7_r),
    .io_r_resp_data_2_entries_prefetch      (l0_rdata_2_prefetch),
    .io_r_resp_data_3_entries_tag           (l0_rdata_3_tag),
    .io_r_resp_data_3_entries_asid          (l0_rdata_3_asid),
    .io_r_resp_data_3_entries_vmid          (l0_rdata_3_vmid),
    .io_r_resp_data_3_entries_pbmts_0       (l0_rdata_3_pbmts_0),
    .io_r_resp_data_3_entries_pbmts_1       (l0_rdata_3_pbmts_1),
    .io_r_resp_data_3_entries_pbmts_2       (l0_rdata_3_pbmts_2),
    .io_r_resp_data_3_entries_pbmts_3       (l0_rdata_3_pbmts_3),
    .io_r_resp_data_3_entries_pbmts_4       (l0_rdata_3_pbmts_4),
    .io_r_resp_data_3_entries_pbmts_5       (l0_rdata_3_pbmts_5),
    .io_r_resp_data_3_entries_pbmts_6       (l0_rdata_3_pbmts_6),
    .io_r_resp_data_3_entries_pbmts_7       (l0_rdata_3_pbmts_7),
    .io_r_resp_data_3_entries_ppns_0        (l0_rdata_3_ppns_0),
    .io_r_resp_data_3_entries_ppns_1        (l0_rdata_3_ppns_1),
    .io_r_resp_data_3_entries_ppns_2        (l0_rdata_3_ppns_2),
    .io_r_resp_data_3_entries_ppns_3        (l0_rdata_3_ppns_3),
    .io_r_resp_data_3_entries_ppns_4        (l0_rdata_3_ppns_4),
    .io_r_resp_data_3_entries_ppns_5        (l0_rdata_3_ppns_5),
    .io_r_resp_data_3_entries_ppns_6        (l0_rdata_3_ppns_6),
    .io_r_resp_data_3_entries_ppns_7        (l0_rdata_3_ppns_7),
    .io_r_resp_data_3_entries_vs_0          (l0_rdata_3_vs_0),
    .io_r_resp_data_3_entries_vs_1          (l0_rdata_3_vs_1),
    .io_r_resp_data_3_entries_vs_2          (l0_rdata_3_vs_2),
    .io_r_resp_data_3_entries_vs_3          (l0_rdata_3_vs_3),
    .io_r_resp_data_3_entries_vs_4          (l0_rdata_3_vs_4),
    .io_r_resp_data_3_entries_vs_5          (l0_rdata_3_vs_5),
    .io_r_resp_data_3_entries_vs_6          (l0_rdata_3_vs_6),
    .io_r_resp_data_3_entries_vs_7          (l0_rdata_3_vs_7),
    .io_r_resp_data_3_entries_onlypf_0      (l0_rdata_3_onlypf_0),
    .io_r_resp_data_3_entries_onlypf_1      (l0_rdata_3_onlypf_1),
    .io_r_resp_data_3_entries_onlypf_2      (l0_rdata_3_onlypf_2),
    .io_r_resp_data_3_entries_onlypf_3      (l0_rdata_3_onlypf_3),
    .io_r_resp_data_3_entries_onlypf_4      (l0_rdata_3_onlypf_4),
    .io_r_resp_data_3_entries_onlypf_5      (l0_rdata_3_onlypf_5),
    .io_r_resp_data_3_entries_onlypf_6      (l0_rdata_3_onlypf_6),
    .io_r_resp_data_3_entries_onlypf_7      (l0_rdata_3_onlypf_7),
    .io_r_resp_data_3_entries_perms_0_d     (l0_rdata_3_perms_0_d),
    .io_r_resp_data_3_entries_perms_0_a     (l0_rdata_3_perms_0_a),
    .io_r_resp_data_3_entries_perms_0_g     (l0_rdata_3_perms_0_g),
    .io_r_resp_data_3_entries_perms_0_u     (l0_rdata_3_perms_0_u),
    .io_r_resp_data_3_entries_perms_0_x     (l0_rdata_3_perms_0_x),
    .io_r_resp_data_3_entries_perms_0_w     (l0_rdata_3_perms_0_w),
    .io_r_resp_data_3_entries_perms_0_r     (l0_rdata_3_perms_0_r),
    .io_r_resp_data_3_entries_perms_1_d     (l0_rdata_3_perms_1_d),
    .io_r_resp_data_3_entries_perms_1_a     (l0_rdata_3_perms_1_a),
    .io_r_resp_data_3_entries_perms_1_g     (l0_rdata_3_perms_1_g),
    .io_r_resp_data_3_entries_perms_1_u     (l0_rdata_3_perms_1_u),
    .io_r_resp_data_3_entries_perms_1_x     (l0_rdata_3_perms_1_x),
    .io_r_resp_data_3_entries_perms_1_w     (l0_rdata_3_perms_1_w),
    .io_r_resp_data_3_entries_perms_1_r     (l0_rdata_3_perms_1_r),
    .io_r_resp_data_3_entries_perms_2_d     (l0_rdata_3_perms_2_d),
    .io_r_resp_data_3_entries_perms_2_a     (l0_rdata_3_perms_2_a),
    .io_r_resp_data_3_entries_perms_2_g     (l0_rdata_3_perms_2_g),
    .io_r_resp_data_3_entries_perms_2_u     (l0_rdata_3_perms_2_u),
    .io_r_resp_data_3_entries_perms_2_x     (l0_rdata_3_perms_2_x),
    .io_r_resp_data_3_entries_perms_2_w     (l0_rdata_3_perms_2_w),
    .io_r_resp_data_3_entries_perms_2_r     (l0_rdata_3_perms_2_r),
    .io_r_resp_data_3_entries_perms_3_d     (l0_rdata_3_perms_3_d),
    .io_r_resp_data_3_entries_perms_3_a     (l0_rdata_3_perms_3_a),
    .io_r_resp_data_3_entries_perms_3_g     (l0_rdata_3_perms_3_g),
    .io_r_resp_data_3_entries_perms_3_u     (l0_rdata_3_perms_3_u),
    .io_r_resp_data_3_entries_perms_3_x     (l0_rdata_3_perms_3_x),
    .io_r_resp_data_3_entries_perms_3_w     (l0_rdata_3_perms_3_w),
    .io_r_resp_data_3_entries_perms_3_r     (l0_rdata_3_perms_3_r),
    .io_r_resp_data_3_entries_perms_4_d     (l0_rdata_3_perms_4_d),
    .io_r_resp_data_3_entries_perms_4_a     (l0_rdata_3_perms_4_a),
    .io_r_resp_data_3_entries_perms_4_g     (l0_rdata_3_perms_4_g),
    .io_r_resp_data_3_entries_perms_4_u     (l0_rdata_3_perms_4_u),
    .io_r_resp_data_3_entries_perms_4_x     (l0_rdata_3_perms_4_x),
    .io_r_resp_data_3_entries_perms_4_w     (l0_rdata_3_perms_4_w),
    .io_r_resp_data_3_entries_perms_4_r     (l0_rdata_3_perms_4_r),
    .io_r_resp_data_3_entries_perms_5_d     (l0_rdata_3_perms_5_d),
    .io_r_resp_data_3_entries_perms_5_a     (l0_rdata_3_perms_5_a),
    .io_r_resp_data_3_entries_perms_5_g     (l0_rdata_3_perms_5_g),
    .io_r_resp_data_3_entries_perms_5_u     (l0_rdata_3_perms_5_u),
    .io_r_resp_data_3_entries_perms_5_x     (l0_rdata_3_perms_5_x),
    .io_r_resp_data_3_entries_perms_5_w     (l0_rdata_3_perms_5_w),
    .io_r_resp_data_3_entries_perms_5_r     (l0_rdata_3_perms_5_r),
    .io_r_resp_data_3_entries_perms_6_d     (l0_rdata_3_perms_6_d),
    .io_r_resp_data_3_entries_perms_6_a     (l0_rdata_3_perms_6_a),
    .io_r_resp_data_3_entries_perms_6_g     (l0_rdata_3_perms_6_g),
    .io_r_resp_data_3_entries_perms_6_u     (l0_rdata_3_perms_6_u),
    .io_r_resp_data_3_entries_perms_6_x     (l0_rdata_3_perms_6_x),
    .io_r_resp_data_3_entries_perms_6_w     (l0_rdata_3_perms_6_w),
    .io_r_resp_data_3_entries_perms_6_r     (l0_rdata_3_perms_6_r),
    .io_r_resp_data_3_entries_perms_7_d     (l0_rdata_3_perms_7_d),
    .io_r_resp_data_3_entries_perms_7_a     (l0_rdata_3_perms_7_a),
    .io_r_resp_data_3_entries_perms_7_g     (l0_rdata_3_perms_7_g),
    .io_r_resp_data_3_entries_perms_7_u     (l0_rdata_3_perms_7_u),
    .io_r_resp_data_3_entries_perms_7_x     (l0_rdata_3_perms_7_x),
    .io_r_resp_data_3_entries_perms_7_w     (l0_rdata_3_perms_7_w),
    .io_r_resp_data_3_entries_perms_7_r     (l0_rdata_3_perms_7_r),
    .io_r_resp_data_3_entries_prefetch      (l0_rdata_3_prefetch),
    .io_w_req_valid                         (l0_refill),
    .io_w_req_bits_setIdx                   (l0_w_set),
    .io_w_req_bits_data_0_entries_tag       (l0_w_tag),
    .io_w_req_bits_data_0_entries_asid      (l0_w_asid),
    .io_w_req_bits_data_0_entries_vmid      (l0_w_vmid),
    .io_w_req_bits_data_0_entries_pbmts_0   (refill_pte[0][62:61]),
    .io_w_req_bits_data_0_entries_pbmts_1   (refill_pte[1][62:61]),
    .io_w_req_bits_data_0_entries_pbmts_2   (refill_pte[2][62:61]),
    .io_w_req_bits_data_0_entries_pbmts_3   (refill_pte[3][62:61]),
    .io_w_req_bits_data_0_entries_pbmts_4   (refill_pte[4][62:61]),
    .io_w_req_bits_data_0_entries_pbmts_5   (refill_pte[5][62:61]),
    .io_w_req_bits_data_0_entries_pbmts_6   (refill_pte[6][62:61]),
    .io_w_req_bits_data_0_entries_pbmts_7   (refill_pte[7][62:61]),
    .io_w_req_bits_data_0_entries_ppns_0    (refill_pte[0][47:10]),
    .io_w_req_bits_data_0_entries_ppns_1    (refill_pte[1][47:10]),
    .io_w_req_bits_data_0_entries_ppns_2    (refill_pte[2][47:10]),
    .io_w_req_bits_data_0_entries_ppns_3    (refill_pte[3][47:10]),
    .io_w_req_bits_data_0_entries_ppns_4    (refill_pte[4][47:10]),
    .io_w_req_bits_data_0_entries_ppns_5    (refill_pte[5][47:10]),
    .io_w_req_bits_data_0_entries_ppns_6    (refill_pte[6][47:10]),
    .io_w_req_bits_data_0_entries_ppns_7    (refill_pte[7][47:10]),
    .io_w_req_bits_data_0_entries_vs_0      (l0_w_vs[0]),
    .io_w_req_bits_data_0_entries_vs_1      (l0_w_vs[1]),
    .io_w_req_bits_data_0_entries_vs_2      (l0_w_vs[2]),
    .io_w_req_bits_data_0_entries_vs_3      (l0_w_vs[3]),
    .io_w_req_bits_data_0_entries_vs_4      (l0_w_vs[4]),
    .io_w_req_bits_data_0_entries_vs_5      (l0_w_vs[5]),
    .io_w_req_bits_data_0_entries_vs_6      (l0_w_vs[6]),
    .io_w_req_bits_data_0_entries_vs_7      (l0_w_vs[7]),
    .io_w_req_bits_data_0_entries_onlypf_0  (l0_w_onlypf[0]),
    .io_w_req_bits_data_0_entries_onlypf_1  (l0_w_onlypf[1]),
    .io_w_req_bits_data_0_entries_onlypf_2  (l0_w_onlypf[2]),
    .io_w_req_bits_data_0_entries_onlypf_3  (l0_w_onlypf[3]),
    .io_w_req_bits_data_0_entries_onlypf_4  (l0_w_onlypf[4]),
    .io_w_req_bits_data_0_entries_onlypf_5  (l0_w_onlypf[5]),
    .io_w_req_bits_data_0_entries_onlypf_6  (l0_w_onlypf[6]),
    .io_w_req_bits_data_0_entries_onlypf_7  (l0_w_onlypf[7]),
    .io_w_req_bits_data_0_entries_perms_0_d (l0_w_perms[0].d),
    .io_w_req_bits_data_0_entries_perms_0_a (l0_w_perms[0].a),
    .io_w_req_bits_data_0_entries_perms_0_g (l0_w_perms[0].g),
    .io_w_req_bits_data_0_entries_perms_0_u (l0_w_perms[0].u),
    .io_w_req_bits_data_0_entries_perms_0_x (l0_w_perms[0].x),
    .io_w_req_bits_data_0_entries_perms_0_w (l0_w_perms[0].w),
    .io_w_req_bits_data_0_entries_perms_0_r (l0_w_perms[0].r),
    .io_w_req_bits_data_0_entries_perms_1_d (l0_w_perms[1].d),
    .io_w_req_bits_data_0_entries_perms_1_a (l0_w_perms[1].a),
    .io_w_req_bits_data_0_entries_perms_1_g (l0_w_perms[1].g),
    .io_w_req_bits_data_0_entries_perms_1_u (l0_w_perms[1].u),
    .io_w_req_bits_data_0_entries_perms_1_x (l0_w_perms[1].x),
    .io_w_req_bits_data_0_entries_perms_1_w (l0_w_perms[1].w),
    .io_w_req_bits_data_0_entries_perms_1_r (l0_w_perms[1].r),
    .io_w_req_bits_data_0_entries_perms_2_d (l0_w_perms[2].d),
    .io_w_req_bits_data_0_entries_perms_2_a (l0_w_perms[2].a),
    .io_w_req_bits_data_0_entries_perms_2_g (l0_w_perms[2].g),
    .io_w_req_bits_data_0_entries_perms_2_u (l0_w_perms[2].u),
    .io_w_req_bits_data_0_entries_perms_2_x (l0_w_perms[2].x),
    .io_w_req_bits_data_0_entries_perms_2_w (l0_w_perms[2].w),
    .io_w_req_bits_data_0_entries_perms_2_r (l0_w_perms[2].r),
    .io_w_req_bits_data_0_entries_perms_3_d (l0_w_perms[3].d),
    .io_w_req_bits_data_0_entries_perms_3_a (l0_w_perms[3].a),
    .io_w_req_bits_data_0_entries_perms_3_g (l0_w_perms[3].g),
    .io_w_req_bits_data_0_entries_perms_3_u (l0_w_perms[3].u),
    .io_w_req_bits_data_0_entries_perms_3_x (l0_w_perms[3].x),
    .io_w_req_bits_data_0_entries_perms_3_w (l0_w_perms[3].w),
    .io_w_req_bits_data_0_entries_perms_3_r (l0_w_perms[3].r),
    .io_w_req_bits_data_0_entries_perms_4_d (l0_w_perms[4].d),
    .io_w_req_bits_data_0_entries_perms_4_a (l0_w_perms[4].a),
    .io_w_req_bits_data_0_entries_perms_4_g (l0_w_perms[4].g),
    .io_w_req_bits_data_0_entries_perms_4_u (l0_w_perms[4].u),
    .io_w_req_bits_data_0_entries_perms_4_x (l0_w_perms[4].x),
    .io_w_req_bits_data_0_entries_perms_4_w (l0_w_perms[4].w),
    .io_w_req_bits_data_0_entries_perms_4_r (l0_w_perms[4].r),
    .io_w_req_bits_data_0_entries_perms_5_d (l0_w_perms[5].d),
    .io_w_req_bits_data_0_entries_perms_5_a (l0_w_perms[5].a),
    .io_w_req_bits_data_0_entries_perms_5_g (l0_w_perms[5].g),
    .io_w_req_bits_data_0_entries_perms_5_u (l0_w_perms[5].u),
    .io_w_req_bits_data_0_entries_perms_5_x (l0_w_perms[5].x),
    .io_w_req_bits_data_0_entries_perms_5_w (l0_w_perms[5].w),
    .io_w_req_bits_data_0_entries_perms_5_r (l0_w_perms[5].r),
    .io_w_req_bits_data_0_entries_perms_6_d (l0_w_perms[6].d),
    .io_w_req_bits_data_0_entries_perms_6_a (l0_w_perms[6].a),
    .io_w_req_bits_data_0_entries_perms_6_g (l0_w_perms[6].g),
    .io_w_req_bits_data_0_entries_perms_6_u (l0_w_perms[6].u),
    .io_w_req_bits_data_0_entries_perms_6_x (l0_w_perms[6].x),
    .io_w_req_bits_data_0_entries_perms_6_w (l0_w_perms[6].w),
    .io_w_req_bits_data_0_entries_perms_6_r (l0_w_perms[6].r),
    .io_w_req_bits_data_0_entries_perms_7_d (l0_w_perms[7].d),
    .io_w_req_bits_data_0_entries_perms_7_a (l0_w_perms[7].a),
    .io_w_req_bits_data_0_entries_perms_7_g (l0_w_perms[7].g),
    .io_w_req_bits_data_0_entries_perms_7_u (l0_w_perms[7].u),
    .io_w_req_bits_data_0_entries_perms_7_x (l0_w_perms[7].x),
    .io_w_req_bits_data_0_entries_perms_7_w (l0_w_perms[7].w),
    .io_w_req_bits_data_0_entries_perms_7_r (l0_w_perms[7].r),
    .io_w_req_bits_data_0_entries_prefetch  (l0_w_prefetch),
    .io_w_req_bits_data_1_entries_tag       (l0_w_tag),
    .io_w_req_bits_data_1_entries_asid      (l0_w_asid),
    .io_w_req_bits_data_1_entries_vmid      (l0_w_vmid),
    .io_w_req_bits_data_1_entries_pbmts_0   (refill_pte[0][62:61]),
    .io_w_req_bits_data_1_entries_pbmts_1   (refill_pte[1][62:61]),
    .io_w_req_bits_data_1_entries_pbmts_2   (refill_pte[2][62:61]),
    .io_w_req_bits_data_1_entries_pbmts_3   (refill_pte[3][62:61]),
    .io_w_req_bits_data_1_entries_pbmts_4   (refill_pte[4][62:61]),
    .io_w_req_bits_data_1_entries_pbmts_5   (refill_pte[5][62:61]),
    .io_w_req_bits_data_1_entries_pbmts_6   (refill_pte[6][62:61]),
    .io_w_req_bits_data_1_entries_pbmts_7   (refill_pte[7][62:61]),
    .io_w_req_bits_data_1_entries_ppns_0    (refill_pte[0][47:10]),
    .io_w_req_bits_data_1_entries_ppns_1    (refill_pte[1][47:10]),
    .io_w_req_bits_data_1_entries_ppns_2    (refill_pte[2][47:10]),
    .io_w_req_bits_data_1_entries_ppns_3    (refill_pte[3][47:10]),
    .io_w_req_bits_data_1_entries_ppns_4    (refill_pte[4][47:10]),
    .io_w_req_bits_data_1_entries_ppns_5    (refill_pte[5][47:10]),
    .io_w_req_bits_data_1_entries_ppns_6    (refill_pte[6][47:10]),
    .io_w_req_bits_data_1_entries_ppns_7    (refill_pte[7][47:10]),
    .io_w_req_bits_data_1_entries_vs_0      (l0_w_vs[0]),
    .io_w_req_bits_data_1_entries_vs_1      (l0_w_vs[1]),
    .io_w_req_bits_data_1_entries_vs_2      (l0_w_vs[2]),
    .io_w_req_bits_data_1_entries_vs_3      (l0_w_vs[3]),
    .io_w_req_bits_data_1_entries_vs_4      (l0_w_vs[4]),
    .io_w_req_bits_data_1_entries_vs_5      (l0_w_vs[5]),
    .io_w_req_bits_data_1_entries_vs_6      (l0_w_vs[6]),
    .io_w_req_bits_data_1_entries_vs_7      (l0_w_vs[7]),
    .io_w_req_bits_data_1_entries_onlypf_0  (l0_w_onlypf[0]),
    .io_w_req_bits_data_1_entries_onlypf_1  (l0_w_onlypf[1]),
    .io_w_req_bits_data_1_entries_onlypf_2  (l0_w_onlypf[2]),
    .io_w_req_bits_data_1_entries_onlypf_3  (l0_w_onlypf[3]),
    .io_w_req_bits_data_1_entries_onlypf_4  (l0_w_onlypf[4]),
    .io_w_req_bits_data_1_entries_onlypf_5  (l0_w_onlypf[5]),
    .io_w_req_bits_data_1_entries_onlypf_6  (l0_w_onlypf[6]),
    .io_w_req_bits_data_1_entries_onlypf_7  (l0_w_onlypf[7]),
    .io_w_req_bits_data_1_entries_perms_0_d (l0_w_perms[0].d),
    .io_w_req_bits_data_1_entries_perms_0_a (l0_w_perms[0].a),
    .io_w_req_bits_data_1_entries_perms_0_g (l0_w_perms[0].g),
    .io_w_req_bits_data_1_entries_perms_0_u (l0_w_perms[0].u),
    .io_w_req_bits_data_1_entries_perms_0_x (l0_w_perms[0].x),
    .io_w_req_bits_data_1_entries_perms_0_w (l0_w_perms[0].w),
    .io_w_req_bits_data_1_entries_perms_0_r (l0_w_perms[0].r),
    .io_w_req_bits_data_1_entries_perms_1_d (l0_w_perms[1].d),
    .io_w_req_bits_data_1_entries_perms_1_a (l0_w_perms[1].a),
    .io_w_req_bits_data_1_entries_perms_1_g (l0_w_perms[1].g),
    .io_w_req_bits_data_1_entries_perms_1_u (l0_w_perms[1].u),
    .io_w_req_bits_data_1_entries_perms_1_x (l0_w_perms[1].x),
    .io_w_req_bits_data_1_entries_perms_1_w (l0_w_perms[1].w),
    .io_w_req_bits_data_1_entries_perms_1_r (l0_w_perms[1].r),
    .io_w_req_bits_data_1_entries_perms_2_d (l0_w_perms[2].d),
    .io_w_req_bits_data_1_entries_perms_2_a (l0_w_perms[2].a),
    .io_w_req_bits_data_1_entries_perms_2_g (l0_w_perms[2].g),
    .io_w_req_bits_data_1_entries_perms_2_u (l0_w_perms[2].u),
    .io_w_req_bits_data_1_entries_perms_2_x (l0_w_perms[2].x),
    .io_w_req_bits_data_1_entries_perms_2_w (l0_w_perms[2].w),
    .io_w_req_bits_data_1_entries_perms_2_r (l0_w_perms[2].r),
    .io_w_req_bits_data_1_entries_perms_3_d (l0_w_perms[3].d),
    .io_w_req_bits_data_1_entries_perms_3_a (l0_w_perms[3].a),
    .io_w_req_bits_data_1_entries_perms_3_g (l0_w_perms[3].g),
    .io_w_req_bits_data_1_entries_perms_3_u (l0_w_perms[3].u),
    .io_w_req_bits_data_1_entries_perms_3_x (l0_w_perms[3].x),
    .io_w_req_bits_data_1_entries_perms_3_w (l0_w_perms[3].w),
    .io_w_req_bits_data_1_entries_perms_3_r (l0_w_perms[3].r),
    .io_w_req_bits_data_1_entries_perms_4_d (l0_w_perms[4].d),
    .io_w_req_bits_data_1_entries_perms_4_a (l0_w_perms[4].a),
    .io_w_req_bits_data_1_entries_perms_4_g (l0_w_perms[4].g),
    .io_w_req_bits_data_1_entries_perms_4_u (l0_w_perms[4].u),
    .io_w_req_bits_data_1_entries_perms_4_x (l0_w_perms[4].x),
    .io_w_req_bits_data_1_entries_perms_4_w (l0_w_perms[4].w),
    .io_w_req_bits_data_1_entries_perms_4_r (l0_w_perms[4].r),
    .io_w_req_bits_data_1_entries_perms_5_d (l0_w_perms[5].d),
    .io_w_req_bits_data_1_entries_perms_5_a (l0_w_perms[5].a),
    .io_w_req_bits_data_1_entries_perms_5_g (l0_w_perms[5].g),
    .io_w_req_bits_data_1_entries_perms_5_u (l0_w_perms[5].u),
    .io_w_req_bits_data_1_entries_perms_5_x (l0_w_perms[5].x),
    .io_w_req_bits_data_1_entries_perms_5_w (l0_w_perms[5].w),
    .io_w_req_bits_data_1_entries_perms_5_r (l0_w_perms[5].r),
    .io_w_req_bits_data_1_entries_perms_6_d (l0_w_perms[6].d),
    .io_w_req_bits_data_1_entries_perms_6_a (l0_w_perms[6].a),
    .io_w_req_bits_data_1_entries_perms_6_g (l0_w_perms[6].g),
    .io_w_req_bits_data_1_entries_perms_6_u (l0_w_perms[6].u),
    .io_w_req_bits_data_1_entries_perms_6_x (l0_w_perms[6].x),
    .io_w_req_bits_data_1_entries_perms_6_w (l0_w_perms[6].w),
    .io_w_req_bits_data_1_entries_perms_6_r (l0_w_perms[6].r),
    .io_w_req_bits_data_1_entries_perms_7_d (l0_w_perms[7].d),
    .io_w_req_bits_data_1_entries_perms_7_a (l0_w_perms[7].a),
    .io_w_req_bits_data_1_entries_perms_7_g (l0_w_perms[7].g),
    .io_w_req_bits_data_1_entries_perms_7_u (l0_w_perms[7].u),
    .io_w_req_bits_data_1_entries_perms_7_x (l0_w_perms[7].x),
    .io_w_req_bits_data_1_entries_perms_7_w (l0_w_perms[7].w),
    .io_w_req_bits_data_1_entries_perms_7_r (l0_w_perms[7].r),
    .io_w_req_bits_data_1_entries_prefetch  (l0_w_prefetch),
    .io_w_req_bits_data_2_entries_tag       (l0_w_tag),
    .io_w_req_bits_data_2_entries_asid      (l0_w_asid),
    .io_w_req_bits_data_2_entries_vmid      (l0_w_vmid),
    .io_w_req_bits_data_2_entries_pbmts_0   (refill_pte[0][62:61]),
    .io_w_req_bits_data_2_entries_pbmts_1   (refill_pte[1][62:61]),
    .io_w_req_bits_data_2_entries_pbmts_2   (refill_pte[2][62:61]),
    .io_w_req_bits_data_2_entries_pbmts_3   (refill_pte[3][62:61]),
    .io_w_req_bits_data_2_entries_pbmts_4   (refill_pte[4][62:61]),
    .io_w_req_bits_data_2_entries_pbmts_5   (refill_pte[5][62:61]),
    .io_w_req_bits_data_2_entries_pbmts_6   (refill_pte[6][62:61]),
    .io_w_req_bits_data_2_entries_pbmts_7   (refill_pte[7][62:61]),
    .io_w_req_bits_data_2_entries_ppns_0    (refill_pte[0][47:10]),
    .io_w_req_bits_data_2_entries_ppns_1    (refill_pte[1][47:10]),
    .io_w_req_bits_data_2_entries_ppns_2    (refill_pte[2][47:10]),
    .io_w_req_bits_data_2_entries_ppns_3    (refill_pte[3][47:10]),
    .io_w_req_bits_data_2_entries_ppns_4    (refill_pte[4][47:10]),
    .io_w_req_bits_data_2_entries_ppns_5    (refill_pte[5][47:10]),
    .io_w_req_bits_data_2_entries_ppns_6    (refill_pte[6][47:10]),
    .io_w_req_bits_data_2_entries_ppns_7    (refill_pte[7][47:10]),
    .io_w_req_bits_data_2_entries_vs_0      (l0_w_vs[0]),
    .io_w_req_bits_data_2_entries_vs_1      (l0_w_vs[1]),
    .io_w_req_bits_data_2_entries_vs_2      (l0_w_vs[2]),
    .io_w_req_bits_data_2_entries_vs_3      (l0_w_vs[3]),
    .io_w_req_bits_data_2_entries_vs_4      (l0_w_vs[4]),
    .io_w_req_bits_data_2_entries_vs_5      (l0_w_vs[5]),
    .io_w_req_bits_data_2_entries_vs_6      (l0_w_vs[6]),
    .io_w_req_bits_data_2_entries_vs_7      (l0_w_vs[7]),
    .io_w_req_bits_data_2_entries_onlypf_0  (l0_w_onlypf[0]),
    .io_w_req_bits_data_2_entries_onlypf_1  (l0_w_onlypf[1]),
    .io_w_req_bits_data_2_entries_onlypf_2  (l0_w_onlypf[2]),
    .io_w_req_bits_data_2_entries_onlypf_3  (l0_w_onlypf[3]),
    .io_w_req_bits_data_2_entries_onlypf_4  (l0_w_onlypf[4]),
    .io_w_req_bits_data_2_entries_onlypf_5  (l0_w_onlypf[5]),
    .io_w_req_bits_data_2_entries_onlypf_6  (l0_w_onlypf[6]),
    .io_w_req_bits_data_2_entries_onlypf_7  (l0_w_onlypf[7]),
    .io_w_req_bits_data_2_entries_perms_0_d (l0_w_perms[0].d),
    .io_w_req_bits_data_2_entries_perms_0_a (l0_w_perms[0].a),
    .io_w_req_bits_data_2_entries_perms_0_g (l0_w_perms[0].g),
    .io_w_req_bits_data_2_entries_perms_0_u (l0_w_perms[0].u),
    .io_w_req_bits_data_2_entries_perms_0_x (l0_w_perms[0].x),
    .io_w_req_bits_data_2_entries_perms_0_w (l0_w_perms[0].w),
    .io_w_req_bits_data_2_entries_perms_0_r (l0_w_perms[0].r),
    .io_w_req_bits_data_2_entries_perms_1_d (l0_w_perms[1].d),
    .io_w_req_bits_data_2_entries_perms_1_a (l0_w_perms[1].a),
    .io_w_req_bits_data_2_entries_perms_1_g (l0_w_perms[1].g),
    .io_w_req_bits_data_2_entries_perms_1_u (l0_w_perms[1].u),
    .io_w_req_bits_data_2_entries_perms_1_x (l0_w_perms[1].x),
    .io_w_req_bits_data_2_entries_perms_1_w (l0_w_perms[1].w),
    .io_w_req_bits_data_2_entries_perms_1_r (l0_w_perms[1].r),
    .io_w_req_bits_data_2_entries_perms_2_d (l0_w_perms[2].d),
    .io_w_req_bits_data_2_entries_perms_2_a (l0_w_perms[2].a),
    .io_w_req_bits_data_2_entries_perms_2_g (l0_w_perms[2].g),
    .io_w_req_bits_data_2_entries_perms_2_u (l0_w_perms[2].u),
    .io_w_req_bits_data_2_entries_perms_2_x (l0_w_perms[2].x),
    .io_w_req_bits_data_2_entries_perms_2_w (l0_w_perms[2].w),
    .io_w_req_bits_data_2_entries_perms_2_r (l0_w_perms[2].r),
    .io_w_req_bits_data_2_entries_perms_3_d (l0_w_perms[3].d),
    .io_w_req_bits_data_2_entries_perms_3_a (l0_w_perms[3].a),
    .io_w_req_bits_data_2_entries_perms_3_g (l0_w_perms[3].g),
    .io_w_req_bits_data_2_entries_perms_3_u (l0_w_perms[3].u),
    .io_w_req_bits_data_2_entries_perms_3_x (l0_w_perms[3].x),
    .io_w_req_bits_data_2_entries_perms_3_w (l0_w_perms[3].w),
    .io_w_req_bits_data_2_entries_perms_3_r (l0_w_perms[3].r),
    .io_w_req_bits_data_2_entries_perms_4_d (l0_w_perms[4].d),
    .io_w_req_bits_data_2_entries_perms_4_a (l0_w_perms[4].a),
    .io_w_req_bits_data_2_entries_perms_4_g (l0_w_perms[4].g),
    .io_w_req_bits_data_2_entries_perms_4_u (l0_w_perms[4].u),
    .io_w_req_bits_data_2_entries_perms_4_x (l0_w_perms[4].x),
    .io_w_req_bits_data_2_entries_perms_4_w (l0_w_perms[4].w),
    .io_w_req_bits_data_2_entries_perms_4_r (l0_w_perms[4].r),
    .io_w_req_bits_data_2_entries_perms_5_d (l0_w_perms[5].d),
    .io_w_req_bits_data_2_entries_perms_5_a (l0_w_perms[5].a),
    .io_w_req_bits_data_2_entries_perms_5_g (l0_w_perms[5].g),
    .io_w_req_bits_data_2_entries_perms_5_u (l0_w_perms[5].u),
    .io_w_req_bits_data_2_entries_perms_5_x (l0_w_perms[5].x),
    .io_w_req_bits_data_2_entries_perms_5_w (l0_w_perms[5].w),
    .io_w_req_bits_data_2_entries_perms_5_r (l0_w_perms[5].r),
    .io_w_req_bits_data_2_entries_perms_6_d (l0_w_perms[6].d),
    .io_w_req_bits_data_2_entries_perms_6_a (l0_w_perms[6].a),
    .io_w_req_bits_data_2_entries_perms_6_g (l0_w_perms[6].g),
    .io_w_req_bits_data_2_entries_perms_6_u (l0_w_perms[6].u),
    .io_w_req_bits_data_2_entries_perms_6_x (l0_w_perms[6].x),
    .io_w_req_bits_data_2_entries_perms_6_w (l0_w_perms[6].w),
    .io_w_req_bits_data_2_entries_perms_6_r (l0_w_perms[6].r),
    .io_w_req_bits_data_2_entries_perms_7_d (l0_w_perms[7].d),
    .io_w_req_bits_data_2_entries_perms_7_a (l0_w_perms[7].a),
    .io_w_req_bits_data_2_entries_perms_7_g (l0_w_perms[7].g),
    .io_w_req_bits_data_2_entries_perms_7_u (l0_w_perms[7].u),
    .io_w_req_bits_data_2_entries_perms_7_x (l0_w_perms[7].x),
    .io_w_req_bits_data_2_entries_perms_7_w (l0_w_perms[7].w),
    .io_w_req_bits_data_2_entries_perms_7_r (l0_w_perms[7].r),
    .io_w_req_bits_data_2_entries_prefetch  (l0_w_prefetch),
    .io_w_req_bits_data_3_entries_tag       (l0_w_tag),
    .io_w_req_bits_data_3_entries_asid      (l0_w_asid),
    .io_w_req_bits_data_3_entries_vmid      (l0_w_vmid),
    .io_w_req_bits_data_3_entries_pbmts_0   (refill_pte[0][62:61]),
    .io_w_req_bits_data_3_entries_pbmts_1   (refill_pte[1][62:61]),
    .io_w_req_bits_data_3_entries_pbmts_2   (refill_pte[2][62:61]),
    .io_w_req_bits_data_3_entries_pbmts_3   (refill_pte[3][62:61]),
    .io_w_req_bits_data_3_entries_pbmts_4   (refill_pte[4][62:61]),
    .io_w_req_bits_data_3_entries_pbmts_5   (refill_pte[5][62:61]),
    .io_w_req_bits_data_3_entries_pbmts_6   (refill_pte[6][62:61]),
    .io_w_req_bits_data_3_entries_pbmts_7   (refill_pte[7][62:61]),
    .io_w_req_bits_data_3_entries_ppns_0    (refill_pte[0][47:10]),
    .io_w_req_bits_data_3_entries_ppns_1    (refill_pte[1][47:10]),
    .io_w_req_bits_data_3_entries_ppns_2    (refill_pte[2][47:10]),
    .io_w_req_bits_data_3_entries_ppns_3    (refill_pte[3][47:10]),
    .io_w_req_bits_data_3_entries_ppns_4    (refill_pte[4][47:10]),
    .io_w_req_bits_data_3_entries_ppns_5    (refill_pte[5][47:10]),
    .io_w_req_bits_data_3_entries_ppns_6    (refill_pte[6][47:10]),
    .io_w_req_bits_data_3_entries_ppns_7    (refill_pte[7][47:10]),
    .io_w_req_bits_data_3_entries_vs_0      (l0_w_vs[0]),
    .io_w_req_bits_data_3_entries_vs_1      (l0_w_vs[1]),
    .io_w_req_bits_data_3_entries_vs_2      (l0_w_vs[2]),
    .io_w_req_bits_data_3_entries_vs_3      (l0_w_vs[3]),
    .io_w_req_bits_data_3_entries_vs_4      (l0_w_vs[4]),
    .io_w_req_bits_data_3_entries_vs_5      (l0_w_vs[5]),
    .io_w_req_bits_data_3_entries_vs_6      (l0_w_vs[6]),
    .io_w_req_bits_data_3_entries_vs_7      (l0_w_vs[7]),
    .io_w_req_bits_data_3_entries_onlypf_0  (l0_w_onlypf[0]),
    .io_w_req_bits_data_3_entries_onlypf_1  (l0_w_onlypf[1]),
    .io_w_req_bits_data_3_entries_onlypf_2  (l0_w_onlypf[2]),
    .io_w_req_bits_data_3_entries_onlypf_3  (l0_w_onlypf[3]),
    .io_w_req_bits_data_3_entries_onlypf_4  (l0_w_onlypf[4]),
    .io_w_req_bits_data_3_entries_onlypf_5  (l0_w_onlypf[5]),
    .io_w_req_bits_data_3_entries_onlypf_6  (l0_w_onlypf[6]),
    .io_w_req_bits_data_3_entries_onlypf_7  (l0_w_onlypf[7]),
    .io_w_req_bits_data_3_entries_perms_0_d (l0_w_perms[0].d),
    .io_w_req_bits_data_3_entries_perms_0_a (l0_w_perms[0].a),
    .io_w_req_bits_data_3_entries_perms_0_g (l0_w_perms[0].g),
    .io_w_req_bits_data_3_entries_perms_0_u (l0_w_perms[0].u),
    .io_w_req_bits_data_3_entries_perms_0_x (l0_w_perms[0].x),
    .io_w_req_bits_data_3_entries_perms_0_w (l0_w_perms[0].w),
    .io_w_req_bits_data_3_entries_perms_0_r (l0_w_perms[0].r),
    .io_w_req_bits_data_3_entries_perms_1_d (l0_w_perms[1].d),
    .io_w_req_bits_data_3_entries_perms_1_a (l0_w_perms[1].a),
    .io_w_req_bits_data_3_entries_perms_1_g (l0_w_perms[1].g),
    .io_w_req_bits_data_3_entries_perms_1_u (l0_w_perms[1].u),
    .io_w_req_bits_data_3_entries_perms_1_x (l0_w_perms[1].x),
    .io_w_req_bits_data_3_entries_perms_1_w (l0_w_perms[1].w),
    .io_w_req_bits_data_3_entries_perms_1_r (l0_w_perms[1].r),
    .io_w_req_bits_data_3_entries_perms_2_d (l0_w_perms[2].d),
    .io_w_req_bits_data_3_entries_perms_2_a (l0_w_perms[2].a),
    .io_w_req_bits_data_3_entries_perms_2_g (l0_w_perms[2].g),
    .io_w_req_bits_data_3_entries_perms_2_u (l0_w_perms[2].u),
    .io_w_req_bits_data_3_entries_perms_2_x (l0_w_perms[2].x),
    .io_w_req_bits_data_3_entries_perms_2_w (l0_w_perms[2].w),
    .io_w_req_bits_data_3_entries_perms_2_r (l0_w_perms[2].r),
    .io_w_req_bits_data_3_entries_perms_3_d (l0_w_perms[3].d),
    .io_w_req_bits_data_3_entries_perms_3_a (l0_w_perms[3].a),
    .io_w_req_bits_data_3_entries_perms_3_g (l0_w_perms[3].g),
    .io_w_req_bits_data_3_entries_perms_3_u (l0_w_perms[3].u),
    .io_w_req_bits_data_3_entries_perms_3_x (l0_w_perms[3].x),
    .io_w_req_bits_data_3_entries_perms_3_w (l0_w_perms[3].w),
    .io_w_req_bits_data_3_entries_perms_3_r (l0_w_perms[3].r),
    .io_w_req_bits_data_3_entries_perms_4_d (l0_w_perms[4].d),
    .io_w_req_bits_data_3_entries_perms_4_a (l0_w_perms[4].a),
    .io_w_req_bits_data_3_entries_perms_4_g (l0_w_perms[4].g),
    .io_w_req_bits_data_3_entries_perms_4_u (l0_w_perms[4].u),
    .io_w_req_bits_data_3_entries_perms_4_x (l0_w_perms[4].x),
    .io_w_req_bits_data_3_entries_perms_4_w (l0_w_perms[4].w),
    .io_w_req_bits_data_3_entries_perms_4_r (l0_w_perms[4].r),
    .io_w_req_bits_data_3_entries_perms_5_d (l0_w_perms[5].d),
    .io_w_req_bits_data_3_entries_perms_5_a (l0_w_perms[5].a),
    .io_w_req_bits_data_3_entries_perms_5_g (l0_w_perms[5].g),
    .io_w_req_bits_data_3_entries_perms_5_u (l0_w_perms[5].u),
    .io_w_req_bits_data_3_entries_perms_5_x (l0_w_perms[5].x),
    .io_w_req_bits_data_3_entries_perms_5_w (l0_w_perms[5].w),
    .io_w_req_bits_data_3_entries_perms_5_r (l0_w_perms[5].r),
    .io_w_req_bits_data_3_entries_perms_6_d (l0_w_perms[6].d),
    .io_w_req_bits_data_3_entries_perms_6_a (l0_w_perms[6].a),
    .io_w_req_bits_data_3_entries_perms_6_g (l0_w_perms[6].g),
    .io_w_req_bits_data_3_entries_perms_6_u (l0_w_perms[6].u),
    .io_w_req_bits_data_3_entries_perms_6_x (l0_w_perms[6].x),
    .io_w_req_bits_data_3_entries_perms_6_w (l0_w_perms[6].w),
    .io_w_req_bits_data_3_entries_perms_6_r (l0_w_perms[6].r),
    .io_w_req_bits_data_3_entries_perms_7_d (l0_w_perms[7].d),
    .io_w_req_bits_data_3_entries_perms_7_a (l0_w_perms[7].a),
    .io_w_req_bits_data_3_entries_perms_7_g (l0_w_perms[7].g),
    .io_w_req_bits_data_3_entries_perms_7_u (l0_w_perms[7].u),
    .io_w_req_bits_data_3_entries_perms_7_x (l0_w_perms[7].x),
    .io_w_req_bits_data_3_entries_perms_7_w (l0_w_perms[7].w),
    .io_w_req_bits_data_3_entries_perms_7_r (l0_w_perms[7].r),
    .io_w_req_bits_data_3_entries_prefetch  (l0_w_prefetch),
    .io_w_req_bits_waymask                  (l0_w_waymask),
    .boreChildrenBd_bore_addr               (childBd_1_addr),
    .boreChildrenBd_bore_addr_rd            (childBd_1_addr_rd),
    .boreChildrenBd_bore_wdata              (childBd_1_wdata),
    .boreChildrenBd_bore_wmask              (childBd_1_wmask),
    .boreChildrenBd_bore_re                 (childBd_1_re),
    .boreChildrenBd_bore_we                 (childBd_1_we),
    .boreChildrenBd_bore_rdata              (childBd_1_rdata),
    .boreChildrenBd_bore_ack                (childBd_1_ack),
    .boreChildrenBd_bore_selectedOH         (childBd_1_selectedOH),
    .boreChildrenBd_bore_array              (childBd_1_array),
    .boreChildrenBd_bore_1_addr             (childBd_2_addr),
    .boreChildrenBd_bore_1_addr_rd          (childBd_2_addr_rd),
    .boreChildrenBd_bore_1_wdata            (childBd_2_wdata),
    .boreChildrenBd_bore_1_wmask            (childBd_2_wmask),
    .boreChildrenBd_bore_1_re               (childBd_2_re),
    .boreChildrenBd_bore_1_we               (childBd_2_we),
    .boreChildrenBd_bore_1_rdata            (childBd_2_rdata),
    .boreChildrenBd_bore_1_ack              (childBd_2_ack),
    .boreChildrenBd_bore_1_selectedOH       (childBd_2_selectedOH),
    .boreChildrenBd_bore_1_array            (childBd_2_array),
    .boreChildrenBd_bore_2_addr             (childBd_3_addr),
    .boreChildrenBd_bore_2_addr_rd          (childBd_3_addr_rd),
    .boreChildrenBd_bore_2_wdata            (childBd_3_wdata),
    .boreChildrenBd_bore_2_wmask            (childBd_3_wmask),
    .boreChildrenBd_bore_2_re               (childBd_3_re),
    .boreChildrenBd_bore_2_we               (childBd_3_we),
    .boreChildrenBd_bore_2_rdata            (childBd_3_rdata),
    .boreChildrenBd_bore_2_ack              (childBd_3_ack),
    .boreChildrenBd_bore_2_selectedOH       (childBd_3_selectedOH),
    .boreChildrenBd_bore_2_array            (childBd_3_array),
    .boreChildrenBd_bore_3_addr             (childBd_4_addr),
    .boreChildrenBd_bore_3_addr_rd          (childBd_4_addr_rd),
    .boreChildrenBd_bore_3_wdata            (childBd_4_wdata),
    .boreChildrenBd_bore_3_wmask            (childBd_4_wmask),
    .boreChildrenBd_bore_3_re               (childBd_4_re),
    .boreChildrenBd_bore_3_we               (childBd_4_we),
    .boreChildrenBd_bore_3_rdata            (childBd_4_rdata),
    .boreChildrenBd_bore_3_ack              (childBd_4_ack),
    .boreChildrenBd_bore_3_selectedOH       (childBd_4_selectedOH),
    .boreChildrenBd_bore_3_array            (childBd_4_array),
    .boreChildrenBd_bore_4_addr             (childBd_5_addr),
    .boreChildrenBd_bore_4_addr_rd          (childBd_5_addr_rd),
    .boreChildrenBd_bore_4_wdata            (childBd_5_wdata),
    .boreChildrenBd_bore_4_wmask            (childBd_5_wmask),
    .boreChildrenBd_bore_4_re               (childBd_5_re),
    .boreChildrenBd_bore_4_we               (childBd_5_we),
    .boreChildrenBd_bore_4_rdata            (childBd_5_rdata),
    .boreChildrenBd_bore_4_ack              (childBd_5_ack),
    .boreChildrenBd_bore_4_selectedOH       (childBd_5_selectedOH),
    .boreChildrenBd_bore_4_array            (childBd_5_array),
    .boreChildrenBd_bore_5_addr             (childBd_6_addr),
    .boreChildrenBd_bore_5_addr_rd          (childBd_6_addr_rd),
    .boreChildrenBd_bore_5_wdata            (childBd_6_wdata),
    .boreChildrenBd_bore_5_wmask            (childBd_6_wmask),
    .boreChildrenBd_bore_5_re               (childBd_6_re),
    .boreChildrenBd_bore_5_we               (childBd_6_we),
    .boreChildrenBd_bore_5_rdata            (childBd_6_rdata),
    .boreChildrenBd_bore_5_ack              (childBd_6_ack),
    .boreChildrenBd_bore_5_selectedOH       (childBd_6_selectedOH),
    .boreChildrenBd_bore_5_array            (childBd_6_array),
    .boreChildrenBd_bore_6_addr             (childBd_7_addr),
    .boreChildrenBd_bore_6_addr_rd          (childBd_7_addr_rd),
    .boreChildrenBd_bore_6_wdata            (childBd_7_wdata),
    .boreChildrenBd_bore_6_wmask            (childBd_7_wmask),
    .boreChildrenBd_bore_6_re               (childBd_7_re),
    .boreChildrenBd_bore_6_we               (childBd_7_we),
    .boreChildrenBd_bore_6_rdata            (childBd_7_rdata),
    .boreChildrenBd_bore_6_ack              (childBd_7_ack),
    .boreChildrenBd_bore_6_selectedOH       (childBd_7_selectedOH),
    .boreChildrenBd_bore_6_array            (childBd_7_array),
    .boreChildrenBd_bore_7_addr             (childBd_8_addr),
    .boreChildrenBd_bore_7_addr_rd          (childBd_8_addr_rd),
    .boreChildrenBd_bore_7_wdata            (childBd_8_wdata),
    .boreChildrenBd_bore_7_wmask            (childBd_8_wmask),
    .boreChildrenBd_bore_7_re               (childBd_8_re),
    .boreChildrenBd_bore_7_we               (childBd_8_we),
    .boreChildrenBd_bore_7_rdata            (childBd_8_rdata),
    .boreChildrenBd_bore_7_ack              (childBd_8_ack),
    .boreChildrenBd_bore_7_selectedOH       (childBd_8_selectedOH),
    .boreChildrenBd_bore_7_array            (childBd_8_array),
    .boreChildrenBd_bore_8_addr             (childBd_9_addr),
    .boreChildrenBd_bore_8_addr_rd          (childBd_9_addr_rd),
    .boreChildrenBd_bore_8_wdata            (childBd_9_wdata),
    .boreChildrenBd_bore_8_wmask            (childBd_9_wmask),
    .boreChildrenBd_bore_8_re               (childBd_9_re),
    .boreChildrenBd_bore_8_we               (childBd_9_we),
    .boreChildrenBd_bore_8_rdata            (childBd_9_rdata),
    .boreChildrenBd_bore_8_ack              (childBd_9_ack),
    .boreChildrenBd_bore_8_selectedOH       (childBd_9_selectedOH),
    .boreChildrenBd_bore_8_array            (childBd_9_array),
    .boreChildrenBd_bore_9_addr             (childBd_10_addr),
    .boreChildrenBd_bore_9_addr_rd          (childBd_10_addr_rd),
    .boreChildrenBd_bore_9_wdata            (childBd_10_wdata),
    .boreChildrenBd_bore_9_wmask            (childBd_10_wmask),
    .boreChildrenBd_bore_9_re               (childBd_10_re),
    .boreChildrenBd_bore_9_we               (childBd_10_we),
    .boreChildrenBd_bore_9_rdata            (childBd_10_rdata),
    .boreChildrenBd_bore_9_ack              (childBd_10_ack),
    .boreChildrenBd_bore_9_selectedOH       (childBd_10_selectedOH),
    .boreChildrenBd_bore_9_array            (childBd_10_array),
    .boreChildrenBd_bore_10_addr            (childBd_11_addr),
    .boreChildrenBd_bore_10_addr_rd         (childBd_11_addr_rd),
    .boreChildrenBd_bore_10_wdata           (childBd_11_wdata),
    .boreChildrenBd_bore_10_wmask           (childBd_11_wmask),
    .boreChildrenBd_bore_10_re              (childBd_11_re),
    .boreChildrenBd_bore_10_we              (childBd_11_we),
    .boreChildrenBd_bore_10_rdata           (childBd_11_rdata),
    .boreChildrenBd_bore_10_ack             (childBd_11_ack),
    .boreChildrenBd_bore_10_selectedOH      (childBd_11_selectedOH),
    .boreChildrenBd_bore_10_array           (childBd_11_array),
    .boreChildrenBd_bore_11_addr            (childBd_12_addr),
    .boreChildrenBd_bore_11_addr_rd         (childBd_12_addr_rd),
    .boreChildrenBd_bore_11_wdata           (childBd_12_wdata),
    .boreChildrenBd_bore_11_wmask           (childBd_12_wmask),
    .boreChildrenBd_bore_11_re              (childBd_12_re),
    .boreChildrenBd_bore_11_we              (childBd_12_we),
    .boreChildrenBd_bore_11_rdata           (childBd_12_rdata),
    .boreChildrenBd_bore_11_ack             (childBd_12_ack),
    .boreChildrenBd_bore_11_selectedOH      (childBd_12_selectedOH),
    .boreChildrenBd_bore_11_array           (childBd_12_array),
    .boreChildrenBd_bore_12_addr            (childBd_13_addr),
    .boreChildrenBd_bore_12_addr_rd         (childBd_13_addr_rd),
    .boreChildrenBd_bore_12_wdata           (childBd_13_wdata),
    .boreChildrenBd_bore_12_wmask           (childBd_13_wmask),
    .boreChildrenBd_bore_12_re              (childBd_13_re),
    .boreChildrenBd_bore_12_we              (childBd_13_we),
    .boreChildrenBd_bore_12_rdata           (childBd_13_rdata),
    .boreChildrenBd_bore_12_ack             (childBd_13_ack),
    .boreChildrenBd_bore_12_selectedOH      (childBd_13_selectedOH),
    .boreChildrenBd_bore_12_array           (childBd_13_array),
    .boreChildrenBd_bore_13_addr            (childBd_14_addr),
    .boreChildrenBd_bore_13_addr_rd         (childBd_14_addr_rd),
    .boreChildrenBd_bore_13_wdata           (childBd_14_wdata),
    .boreChildrenBd_bore_13_wmask           (childBd_14_wmask),
    .boreChildrenBd_bore_13_re              (childBd_14_re),
    .boreChildrenBd_bore_13_we              (childBd_14_we),
    .boreChildrenBd_bore_13_rdata           (childBd_14_rdata),
    .boreChildrenBd_bore_13_ack             (childBd_14_ack),
    .boreChildrenBd_bore_13_selectedOH      (childBd_14_selectedOH),
    .boreChildrenBd_bore_13_array           (childBd_14_array),
    .boreChildrenBd_bore_14_addr            (childBd_15_addr),
    .boreChildrenBd_bore_14_addr_rd         (childBd_15_addr_rd),
    .boreChildrenBd_bore_14_wdata           (childBd_15_wdata),
    .boreChildrenBd_bore_14_wmask           (childBd_15_wmask),
    .boreChildrenBd_bore_14_re              (childBd_15_re),
    .boreChildrenBd_bore_14_we              (childBd_15_we),
    .boreChildrenBd_bore_14_rdata           (childBd_15_rdata),
    .boreChildrenBd_bore_14_ack             (childBd_15_ack),
    .boreChildrenBd_bore_14_selectedOH      (childBd_15_selectedOH),
    .boreChildrenBd_bore_14_array           (childBd_15_array),
    .boreChildrenBd_bore_15_addr            (childBd_16_addr),
    .boreChildrenBd_bore_15_addr_rd         (childBd_16_addr_rd),
    .boreChildrenBd_bore_15_wdata           (childBd_16_wdata),
    .boreChildrenBd_bore_15_wmask           (childBd_16_wmask),
    .boreChildrenBd_bore_15_re              (childBd_16_re),
    .boreChildrenBd_bore_15_we              (childBd_16_we),
    .boreChildrenBd_bore_15_rdata           (childBd_16_rdata),
    .boreChildrenBd_bore_15_ack             (childBd_16_ack),
    .boreChildrenBd_bore_15_selectedOH      (childBd_16_selectedOH),
    .boreChildrenBd_bore_15_array           (childBd_16_array),
    .sigFromSrams_bore_ram_hold             (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_ram_bypass           (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken         (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk          (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp         (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold         (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_cgen                 (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_1_ram_hold           (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_1_ram_bypass         (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken       (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk        (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp       (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold       (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen               (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_2_ram_hold           (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_2_ram_bypass         (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken       (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk        (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp       (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold       (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen               (sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_3_ram_hold           (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_3_ram_bypass         (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken       (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk        (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp       (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold       (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen               (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_4_ram_hold           (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_4_ram_bypass         (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken       (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk        (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp       (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold       (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen               (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_5_ram_hold           (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_5_ram_bypass         (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken       (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk        (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp       (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold       (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen               (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_6_ram_hold           (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_6_ram_bypass         (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken       (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk        (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp       (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold       (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen               (sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_7_ram_hold           (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_7_ram_bypass         (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken       (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk        (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp       (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold       (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen               (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_8_ram_hold           (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_8_ram_bypass         (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken       (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk        (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp       (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold       (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen               (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_9_ram_hold           (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_9_ram_bypass         (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken       (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk        (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp       (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold       (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen               (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_10_ram_hold          (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_10_ram_bypass        (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken      (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk       (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp      (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold      (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen              (sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_11_ram_hold          (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_11_ram_bypass        (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken      (sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk       (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp      (sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold      (sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen              (sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_12_ram_hold          (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_12_ram_bypass        (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken      (sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk       (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp      (sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold      (sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen              (sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_13_ram_hold          (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_13_ram_bypass        (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken      (sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk       (sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp      (sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold      (sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen              (sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_14_ram_hold          (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_14_ram_bypass        (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken      (sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk       (sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp      (sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold      (sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen              (sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_15_ram_hold          (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_15_ram_bypass        (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken      (sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk       (sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp      (sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold      (sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen              (sigFromSrams_bore_16_cgen)
  );

  // l0 级 MBIST 分发（可读实现在 rtl/dft/MbistPipePtwL0.sv）
  MbistPipePtwL0 u_mbist_l0 (
    .clock                (clock),
    .reset                (reset),
    .mbist_array          (boreChildrenBd_bore_1_array),
    .mbist_all            (boreChildrenBd_bore_1_all),
    .mbist_req            (boreChildrenBd_bore_1_req),
    .mbist_ack            (boreChildrenBd_bore_1_ack),
    .mbist_writeen        (boreChildrenBd_bore_1_writeen),
    .mbist_be             (boreChildrenBd_bore_1_be),
    .mbist_addr           (boreChildrenBd_bore_1_addr),
    .mbist_indata         (boreChildrenBd_bore_1_indata),
    .mbist_readen         (boreChildrenBd_bore_1_readen),
    .mbist_addr_rd        (boreChildrenBd_bore_1_addr_rd),
    .mbist_outdata        (boreChildrenBd_bore_1_outdata),
    .toSRAM_0_addr        (childBd_1_addr),
    .toSRAM_0_addr_rd     (childBd_1_addr_rd),
    .toSRAM_0_wdata       (childBd_1_wdata),
    .toSRAM_0_wmask       (childBd_1_wmask),
    .toSRAM_0_re          (childBd_1_re),
    .toSRAM_0_we          (childBd_1_we),
    .toSRAM_0_rdata       (childBd_1_rdata),
    .toSRAM_0_ack         (childBd_1_ack),
    .toSRAM_0_selectedOH  (childBd_1_selectedOH),
    .toSRAM_0_array       (childBd_1_array),
    .toSRAM_1_addr        (childBd_2_addr),
    .toSRAM_1_addr_rd     (childBd_2_addr_rd),
    .toSRAM_1_wdata       (childBd_2_wdata),
    .toSRAM_1_wmask       (childBd_2_wmask),
    .toSRAM_1_re          (childBd_2_re),
    .toSRAM_1_we          (childBd_2_we),
    .toSRAM_1_rdata       (childBd_2_rdata),
    .toSRAM_1_ack         (childBd_2_ack),
    .toSRAM_1_selectedOH  (childBd_2_selectedOH),
    .toSRAM_1_array       (childBd_2_array),
    .toSRAM_2_addr        (childBd_3_addr),
    .toSRAM_2_addr_rd     (childBd_3_addr_rd),
    .toSRAM_2_wdata       (childBd_3_wdata),
    .toSRAM_2_wmask       (childBd_3_wmask),
    .toSRAM_2_re          (childBd_3_re),
    .toSRAM_2_we          (childBd_3_we),
    .toSRAM_2_rdata       (childBd_3_rdata),
    .toSRAM_2_ack         (childBd_3_ack),
    .toSRAM_2_selectedOH  (childBd_3_selectedOH),
    .toSRAM_2_array       (childBd_3_array),
    .toSRAM_3_addr        (childBd_4_addr),
    .toSRAM_3_addr_rd     (childBd_4_addr_rd),
    .toSRAM_3_wdata       (childBd_4_wdata),
    .toSRAM_3_wmask       (childBd_4_wmask),
    .toSRAM_3_re          (childBd_4_re),
    .toSRAM_3_we          (childBd_4_we),
    .toSRAM_3_rdata       (childBd_4_rdata),
    .toSRAM_3_ack         (childBd_4_ack),
    .toSRAM_3_selectedOH  (childBd_4_selectedOH),
    .toSRAM_3_array       (childBd_4_array),
    .toSRAM_4_addr        (childBd_5_addr),
    .toSRAM_4_addr_rd     (childBd_5_addr_rd),
    .toSRAM_4_wdata       (childBd_5_wdata),
    .toSRAM_4_wmask       (childBd_5_wmask),
    .toSRAM_4_re          (childBd_5_re),
    .toSRAM_4_we          (childBd_5_we),
    .toSRAM_4_rdata       (childBd_5_rdata),
    .toSRAM_4_ack         (childBd_5_ack),
    .toSRAM_4_selectedOH  (childBd_5_selectedOH),
    .toSRAM_4_array       (childBd_5_array),
    .toSRAM_5_addr        (childBd_6_addr),
    .toSRAM_5_addr_rd     (childBd_6_addr_rd),
    .toSRAM_5_wdata       (childBd_6_wdata),
    .toSRAM_5_wmask       (childBd_6_wmask),
    .toSRAM_5_re          (childBd_6_re),
    .toSRAM_5_we          (childBd_6_we),
    .toSRAM_5_rdata       (childBd_6_rdata),
    .toSRAM_5_ack         (childBd_6_ack),
    .toSRAM_5_selectedOH  (childBd_6_selectedOH),
    .toSRAM_5_array       (childBd_6_array),
    .toSRAM_6_addr        (childBd_7_addr),
    .toSRAM_6_addr_rd     (childBd_7_addr_rd),
    .toSRAM_6_wdata       (childBd_7_wdata),
    .toSRAM_6_wmask       (childBd_7_wmask),
    .toSRAM_6_re          (childBd_7_re),
    .toSRAM_6_we          (childBd_7_we),
    .toSRAM_6_rdata       (childBd_7_rdata),
    .toSRAM_6_ack         (childBd_7_ack),
    .toSRAM_6_selectedOH  (childBd_7_selectedOH),
    .toSRAM_6_array       (childBd_7_array),
    .toSRAM_7_addr        (childBd_8_addr),
    .toSRAM_7_addr_rd     (childBd_8_addr_rd),
    .toSRAM_7_wdata       (childBd_8_wdata),
    .toSRAM_7_wmask       (childBd_8_wmask),
    .toSRAM_7_re          (childBd_8_re),
    .toSRAM_7_we          (childBd_8_we),
    .toSRAM_7_rdata       (childBd_8_rdata),
    .toSRAM_7_ack         (childBd_8_ack),
    .toSRAM_7_selectedOH  (childBd_8_selectedOH),
    .toSRAM_7_array       (childBd_8_array),
    .toSRAM_8_addr        (childBd_9_addr),
    .toSRAM_8_addr_rd     (childBd_9_addr_rd),
    .toSRAM_8_wdata       (childBd_9_wdata),
    .toSRAM_8_wmask       (childBd_9_wmask),
    .toSRAM_8_re          (childBd_9_re),
    .toSRAM_8_we          (childBd_9_we),
    .toSRAM_8_rdata       (childBd_9_rdata),
    .toSRAM_8_ack         (childBd_9_ack),
    .toSRAM_8_selectedOH  (childBd_9_selectedOH),
    .toSRAM_8_array       (childBd_9_array),
    .toSRAM_9_addr        (childBd_10_addr),
    .toSRAM_9_addr_rd     (childBd_10_addr_rd),
    .toSRAM_9_wdata       (childBd_10_wdata),
    .toSRAM_9_wmask       (childBd_10_wmask),
    .toSRAM_9_re          (childBd_10_re),
    .toSRAM_9_we          (childBd_10_we),
    .toSRAM_9_rdata       (childBd_10_rdata),
    .toSRAM_9_ack         (childBd_10_ack),
    .toSRAM_9_selectedOH  (childBd_10_selectedOH),
    .toSRAM_9_array       (childBd_10_array),
    .toSRAM_10_addr       (childBd_11_addr),
    .toSRAM_10_addr_rd    (childBd_11_addr_rd),
    .toSRAM_10_wdata      (childBd_11_wdata),
    .toSRAM_10_wmask      (childBd_11_wmask),
    .toSRAM_10_re         (childBd_11_re),
    .toSRAM_10_we         (childBd_11_we),
    .toSRAM_10_rdata      (childBd_11_rdata),
    .toSRAM_10_ack        (childBd_11_ack),
    .toSRAM_10_selectedOH (childBd_11_selectedOH),
    .toSRAM_10_array      (childBd_11_array),
    .toSRAM_11_addr       (childBd_12_addr),
    .toSRAM_11_addr_rd    (childBd_12_addr_rd),
    .toSRAM_11_wdata      (childBd_12_wdata),
    .toSRAM_11_wmask      (childBd_12_wmask),
    .toSRAM_11_re         (childBd_12_re),
    .toSRAM_11_we         (childBd_12_we),
    .toSRAM_11_rdata      (childBd_12_rdata),
    .toSRAM_11_ack        (childBd_12_ack),
    .toSRAM_11_selectedOH (childBd_12_selectedOH),
    .toSRAM_11_array      (childBd_12_array),
    .toSRAM_12_addr       (childBd_13_addr),
    .toSRAM_12_addr_rd    (childBd_13_addr_rd),
    .toSRAM_12_wdata      (childBd_13_wdata),
    .toSRAM_12_wmask      (childBd_13_wmask),
    .toSRAM_12_re         (childBd_13_re),
    .toSRAM_12_we         (childBd_13_we),
    .toSRAM_12_rdata      (childBd_13_rdata),
    .toSRAM_12_ack        (childBd_13_ack),
    .toSRAM_12_selectedOH (childBd_13_selectedOH),
    .toSRAM_12_array      (childBd_13_array),
    .toSRAM_13_addr       (childBd_14_addr),
    .toSRAM_13_addr_rd    (childBd_14_addr_rd),
    .toSRAM_13_wdata      (childBd_14_wdata),
    .toSRAM_13_wmask      (childBd_14_wmask),
    .toSRAM_13_re         (childBd_14_re),
    .toSRAM_13_we         (childBd_14_we),
    .toSRAM_13_rdata      (childBd_14_rdata),
    .toSRAM_13_ack        (childBd_14_ack),
    .toSRAM_13_selectedOH (childBd_14_selectedOH),
    .toSRAM_13_array      (childBd_14_array),
    .toSRAM_14_addr       (childBd_15_addr),
    .toSRAM_14_addr_rd    (childBd_15_addr_rd),
    .toSRAM_14_wdata      (childBd_15_wdata),
    .toSRAM_14_wmask      (childBd_15_wmask),
    .toSRAM_14_re         (childBd_15_re),
    .toSRAM_14_we         (childBd_15_we),
    .toSRAM_14_rdata      (childBd_15_rdata),
    .toSRAM_14_ack        (childBd_15_ack),
    .toSRAM_14_selectedOH (childBd_15_selectedOH),
    .toSRAM_14_array      (childBd_15_array),
    .toSRAM_15_addr       (childBd_16_addr),
    .toSRAM_15_addr_rd    (childBd_16_addr_rd),
    .toSRAM_15_wdata      (childBd_16_wdata),
    .toSRAM_15_wmask      (childBd_16_wmask),
    .toSRAM_15_re         (childBd_16_re),
    .toSRAM_15_we         (childBd_16_we),
    .toSRAM_15_rdata      (childBd_16_rdata),
    .toSRAM_15_ack        (childBd_16_ack),
    .toSRAM_15_selectedOH (childBd_16_selectedOH),
    .toSRAM_15_array      (childBd_16_array)
  );

endmodule

module PtwCache(
  input  logic         clock,
  input  logic         reset,
  input  logic         io_csr_mPBMTE,
  input  logic         io_csr_hPBMTE,
  output logic         io_req_ready,
  input  logic         io_req_valid,
  input  logic [37:0]  io_req_bits_req_info_vpn,
  input  logic [1:0]   io_req_bits_req_info_s2xlate,
  input  logic [1:0]   io_req_bits_req_info_source,
  input  logic         io_req_bits_isFirst,
  input  logic         io_req_bits_isHptwReq,
  input  logic [2:0]   io_req_bits_hptwId,
  input  logic         io_resp_ready,
  output logic         io_resp_valid,
  output logic [37:0]  io_resp_bits_req_info_vpn,
  output logic [1:0]   io_resp_bits_req_info_s2xlate,
  output logic [1:0]   io_resp_bits_req_info_source,
  output logic         io_resp_bits_isFirst,
  output logic         io_resp_bits_hit,
  output logic         io_resp_bits_prefetch,
  output logic         io_resp_bits_bypassed,
  output logic         io_resp_bits_toFsm_l3Hit,
  output logic         io_resp_bits_toFsm_l2Hit,
  output logic         io_resp_bits_toFsm_l1Hit,
  output logic [37:0]  io_resp_bits_toFsm_ppn,
  output logic         io_resp_bits_toFsm_stage1Hit,
  output logic         io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check,
  output logic         io_resp_bits_toFsm_bitmapCheck_toLLPTW,
  output logic [3:0]   io_resp_bits_toFsm_bitmapCheck_hitway,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_pte,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_ptes_0,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_ptes_1,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_ptes_2,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_ptes_3,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_ptes_4,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_ptes_5,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_ptes_6,
  output logic [63:0]  io_resp_bits_toFsm_bitmapCheck_ptes_7,
  output logic         io_resp_bits_toFsm_bitmapCheck_cfs_0,
  output logic         io_resp_bits_toFsm_bitmapCheck_cfs_1,
  output logic         io_resp_bits_toFsm_bitmapCheck_cfs_2,
  output logic         io_resp_bits_toFsm_bitmapCheck_cfs_3,
  output logic         io_resp_bits_toFsm_bitmapCheck_cfs_4,
  output logic         io_resp_bits_toFsm_bitmapCheck_cfs_5,
  output logic         io_resp_bits_toFsm_bitmapCheck_cfs_6,
  output logic         io_resp_bits_toFsm_bitmapCheck_cfs_7,
  output logic [1:0]   io_resp_bits_toFsm_bitmapCheck_SPlevel,
  output logic [34:0]  io_resp_bits_stage1_entry_0_tag,
  output logic [15:0]  io_resp_bits_stage1_entry_0_asid,
  output logic [13:0]  io_resp_bits_stage1_entry_0_vmid,
  output logic         io_resp_bits_stage1_entry_0_n,
  output logic [1:0]   io_resp_bits_stage1_entry_0_pbmt,
  output logic         io_resp_bits_stage1_entry_0_perm_d,
  output logic         io_resp_bits_stage1_entry_0_perm_a,
  output logic         io_resp_bits_stage1_entry_0_perm_g,
  output logic         io_resp_bits_stage1_entry_0_perm_u,
  output logic         io_resp_bits_stage1_entry_0_perm_x,
  output logic         io_resp_bits_stage1_entry_0_perm_w,
  output logic         io_resp_bits_stage1_entry_0_perm_r,
  output logic [1:0]   io_resp_bits_stage1_entry_0_level,
  output logic         io_resp_bits_stage1_entry_0_v,
  output logic [40:0]  io_resp_bits_stage1_entry_0_ppn,
  output logic [2:0]   io_resp_bits_stage1_entry_0_ppn_low,
  output logic         io_resp_bits_stage1_entry_0_pf,
  output logic         io_resp_bits_stage1_entry_0_cf,
  output logic [34:0]  io_resp_bits_stage1_entry_1_tag,
  output logic [15:0]  io_resp_bits_stage1_entry_1_asid,
  output logic [13:0]  io_resp_bits_stage1_entry_1_vmid,
  output logic         io_resp_bits_stage1_entry_1_n,
  output logic [1:0]   io_resp_bits_stage1_entry_1_pbmt,
  output logic         io_resp_bits_stage1_entry_1_perm_d,
  output logic         io_resp_bits_stage1_entry_1_perm_a,
  output logic         io_resp_bits_stage1_entry_1_perm_g,
  output logic         io_resp_bits_stage1_entry_1_perm_u,
  output logic         io_resp_bits_stage1_entry_1_perm_x,
  output logic         io_resp_bits_stage1_entry_1_perm_w,
  output logic         io_resp_bits_stage1_entry_1_perm_r,
  output logic [1:0]   io_resp_bits_stage1_entry_1_level,
  output logic         io_resp_bits_stage1_entry_1_v,
  output logic [40:0]  io_resp_bits_stage1_entry_1_ppn,
  output logic [2:0]   io_resp_bits_stage1_entry_1_ppn_low,
  output logic         io_resp_bits_stage1_entry_1_pf,
  output logic         io_resp_bits_stage1_entry_1_cf,
  output logic [34:0]  io_resp_bits_stage1_entry_2_tag,
  output logic [15:0]  io_resp_bits_stage1_entry_2_asid,
  output logic [13:0]  io_resp_bits_stage1_entry_2_vmid,
  output logic         io_resp_bits_stage1_entry_2_n,
  output logic [1:0]   io_resp_bits_stage1_entry_2_pbmt,
  output logic         io_resp_bits_stage1_entry_2_perm_d,
  output logic         io_resp_bits_stage1_entry_2_perm_a,
  output logic         io_resp_bits_stage1_entry_2_perm_g,
  output logic         io_resp_bits_stage1_entry_2_perm_u,
  output logic         io_resp_bits_stage1_entry_2_perm_x,
  output logic         io_resp_bits_stage1_entry_2_perm_w,
  output logic         io_resp_bits_stage1_entry_2_perm_r,
  output logic [1:0]   io_resp_bits_stage1_entry_2_level,
  output logic         io_resp_bits_stage1_entry_2_v,
  output logic [40:0]  io_resp_bits_stage1_entry_2_ppn,
  output logic [2:0]   io_resp_bits_stage1_entry_2_ppn_low,
  output logic         io_resp_bits_stage1_entry_2_pf,
  output logic         io_resp_bits_stage1_entry_2_cf,
  output logic [34:0]  io_resp_bits_stage1_entry_3_tag,
  output logic [15:0]  io_resp_bits_stage1_entry_3_asid,
  output logic [13:0]  io_resp_bits_stage1_entry_3_vmid,
  output logic         io_resp_bits_stage1_entry_3_n,
  output logic [1:0]   io_resp_bits_stage1_entry_3_pbmt,
  output logic         io_resp_bits_stage1_entry_3_perm_d,
  output logic         io_resp_bits_stage1_entry_3_perm_a,
  output logic         io_resp_bits_stage1_entry_3_perm_g,
  output logic         io_resp_bits_stage1_entry_3_perm_u,
  output logic         io_resp_bits_stage1_entry_3_perm_x,
  output logic         io_resp_bits_stage1_entry_3_perm_w,
  output logic         io_resp_bits_stage1_entry_3_perm_r,
  output logic [1:0]   io_resp_bits_stage1_entry_3_level,
  output logic         io_resp_bits_stage1_entry_3_v,
  output logic [40:0]  io_resp_bits_stage1_entry_3_ppn,
  output logic [2:0]   io_resp_bits_stage1_entry_3_ppn_low,
  output logic         io_resp_bits_stage1_entry_3_pf,
  output logic         io_resp_bits_stage1_entry_3_cf,
  output logic [34:0]  io_resp_bits_stage1_entry_4_tag,
  output logic [15:0]  io_resp_bits_stage1_entry_4_asid,
  output logic [13:0]  io_resp_bits_stage1_entry_4_vmid,
  output logic         io_resp_bits_stage1_entry_4_n,
  output logic [1:0]   io_resp_bits_stage1_entry_4_pbmt,
  output logic         io_resp_bits_stage1_entry_4_perm_d,
  output logic         io_resp_bits_stage1_entry_4_perm_a,
  output logic         io_resp_bits_stage1_entry_4_perm_g,
  output logic         io_resp_bits_stage1_entry_4_perm_u,
  output logic         io_resp_bits_stage1_entry_4_perm_x,
  output logic         io_resp_bits_stage1_entry_4_perm_w,
  output logic         io_resp_bits_stage1_entry_4_perm_r,
  output logic [1:0]   io_resp_bits_stage1_entry_4_level,
  output logic         io_resp_bits_stage1_entry_4_v,
  output logic [40:0]  io_resp_bits_stage1_entry_4_ppn,
  output logic [2:0]   io_resp_bits_stage1_entry_4_ppn_low,
  output logic         io_resp_bits_stage1_entry_4_pf,
  output logic         io_resp_bits_stage1_entry_4_cf,
  output logic [34:0]  io_resp_bits_stage1_entry_5_tag,
  output logic [15:0]  io_resp_bits_stage1_entry_5_asid,
  output logic [13:0]  io_resp_bits_stage1_entry_5_vmid,
  output logic         io_resp_bits_stage1_entry_5_n,
  output logic [1:0]   io_resp_bits_stage1_entry_5_pbmt,
  output logic         io_resp_bits_stage1_entry_5_perm_d,
  output logic         io_resp_bits_stage1_entry_5_perm_a,
  output logic         io_resp_bits_stage1_entry_5_perm_g,
  output logic         io_resp_bits_stage1_entry_5_perm_u,
  output logic         io_resp_bits_stage1_entry_5_perm_x,
  output logic         io_resp_bits_stage1_entry_5_perm_w,
  output logic         io_resp_bits_stage1_entry_5_perm_r,
  output logic [1:0]   io_resp_bits_stage1_entry_5_level,
  output logic         io_resp_bits_stage1_entry_5_v,
  output logic [40:0]  io_resp_bits_stage1_entry_5_ppn,
  output logic [2:0]   io_resp_bits_stage1_entry_5_ppn_low,
  output logic         io_resp_bits_stage1_entry_5_pf,
  output logic         io_resp_bits_stage1_entry_5_cf,
  output logic [34:0]  io_resp_bits_stage1_entry_6_tag,
  output logic [15:0]  io_resp_bits_stage1_entry_6_asid,
  output logic [13:0]  io_resp_bits_stage1_entry_6_vmid,
  output logic         io_resp_bits_stage1_entry_6_n,
  output logic [1:0]   io_resp_bits_stage1_entry_6_pbmt,
  output logic         io_resp_bits_stage1_entry_6_perm_d,
  output logic         io_resp_bits_stage1_entry_6_perm_a,
  output logic         io_resp_bits_stage1_entry_6_perm_g,
  output logic         io_resp_bits_stage1_entry_6_perm_u,
  output logic         io_resp_bits_stage1_entry_6_perm_x,
  output logic         io_resp_bits_stage1_entry_6_perm_w,
  output logic         io_resp_bits_stage1_entry_6_perm_r,
  output logic [1:0]   io_resp_bits_stage1_entry_6_level,
  output logic         io_resp_bits_stage1_entry_6_v,
  output logic [40:0]  io_resp_bits_stage1_entry_6_ppn,
  output logic [2:0]   io_resp_bits_stage1_entry_6_ppn_low,
  output logic         io_resp_bits_stage1_entry_6_pf,
  output logic         io_resp_bits_stage1_entry_6_cf,
  output logic [34:0]  io_resp_bits_stage1_entry_7_tag,
  output logic [15:0]  io_resp_bits_stage1_entry_7_asid,
  output logic [13:0]  io_resp_bits_stage1_entry_7_vmid,
  output logic         io_resp_bits_stage1_entry_7_n,
  output logic [1:0]   io_resp_bits_stage1_entry_7_pbmt,
  output logic         io_resp_bits_stage1_entry_7_perm_d,
  output logic         io_resp_bits_stage1_entry_7_perm_a,
  output logic         io_resp_bits_stage1_entry_7_perm_g,
  output logic         io_resp_bits_stage1_entry_7_perm_u,
  output logic         io_resp_bits_stage1_entry_7_perm_x,
  output logic         io_resp_bits_stage1_entry_7_perm_w,
  output logic         io_resp_bits_stage1_entry_7_perm_r,
  output logic [1:0]   io_resp_bits_stage1_entry_7_level,
  output logic         io_resp_bits_stage1_entry_7_v,
  output logic [40:0]  io_resp_bits_stage1_entry_7_ppn,
  output logic [2:0]   io_resp_bits_stage1_entry_7_ppn_low,
  output logic         io_resp_bits_stage1_entry_7_pf,
  output logic         io_resp_bits_stage1_entry_7_cf,
  output logic         io_resp_bits_stage1_pteidx_0,
  output logic         io_resp_bits_stage1_pteidx_1,
  output logic         io_resp_bits_stage1_pteidx_2,
  output logic         io_resp_bits_stage1_pteidx_3,
  output logic         io_resp_bits_stage1_pteidx_4,
  output logic         io_resp_bits_stage1_pteidx_5,
  output logic         io_resp_bits_stage1_pteidx_6,
  output logic         io_resp_bits_stage1_pteidx_7,
  output logic         io_resp_bits_stage1_not_super,
  output logic         io_resp_bits_isHptwReq,
  output logic         io_resp_bits_toHptw_l3Hit,
  output logic         io_resp_bits_toHptw_l2Hit,
  output logic         io_resp_bits_toHptw_l1Hit,
  output logic [35:0]  io_resp_bits_toHptw_ppn,
  output logic [2:0]   io_resp_bits_toHptw_id,
  output logic [37:0]  io_resp_bits_toHptw_resp_entry_tag,
  output logic [13:0]  io_resp_bits_toHptw_resp_entry_vmid,
  output logic         io_resp_bits_toHptw_resp_entry_n,
  output logic [1:0]   io_resp_bits_toHptw_resp_entry_pbmt,
  output logic [37:0]  io_resp_bits_toHptw_resp_entry_ppn,
  output logic         io_resp_bits_toHptw_resp_entry_perm_d,
  output logic         io_resp_bits_toHptw_resp_entry_perm_a,
  output logic         io_resp_bits_toHptw_resp_entry_perm_g,
  output logic         io_resp_bits_toHptw_resp_entry_perm_u,
  output logic         io_resp_bits_toHptw_resp_entry_perm_x,
  output logic         io_resp_bits_toHptw_resp_entry_perm_w,
  output logic         io_resp_bits_toHptw_resp_entry_perm_r,
  output logic [1:0]   io_resp_bits_toHptw_resp_entry_level,
  output logic         io_resp_bits_toHptw_resp_gpf,
  output logic         io_resp_bits_toHptw_bypassed,
  output logic         io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check,
  output logic [3:0]   io_resp_bits_toHptw_bitmapCheck_hitway,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_pte,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_ptes_0,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_ptes_1,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_ptes_2,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_ptes_3,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_ptes_4,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_ptes_5,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_ptes_6,
  output logic [63:0]  io_resp_bits_toHptw_bitmapCheck_ptes_7,
  output logic         io_resp_bits_toHptw_bitmapCheck_fromSP,
  output logic [1:0]   io_resp_bits_toHptw_bitmapCheck_SPlevel,
  input  logic         io_refill_valid,
  input  logic [511:0] io_refill_bits_ptes,
  input  logic         io_refill_bits_levelOH_sp,
  input  logic         io_refill_bits_levelOH_l0,
  input  logic         io_refill_bits_levelOH_l1,
  input  logic         io_refill_bits_levelOH_l2,
  input  logic         io_refill_bits_levelOH_l3,
  input  logic [37:0]  io_refill_bits_req_info_dup_0_vpn,
  input  logic [1:0]   io_refill_bits_req_info_dup_0_s2xlate,
  input  logic [1:0]   io_refill_bits_req_info_dup_0_source,
  input  logic [37:0]  io_refill_bits_req_info_dup_1_vpn,
  input  logic [1:0]   io_refill_bits_req_info_dup_1_s2xlate,
  input  logic [1:0]   io_refill_bits_req_info_dup_1_source,
  input  logic [37:0]  io_refill_bits_req_info_dup_2_vpn,
  input  logic [1:0]   io_refill_bits_req_info_dup_2_s2xlate,
  input  logic [1:0]   io_refill_bits_req_info_dup_2_source,
  input  logic [1:0]   io_refill_bits_level_dup_0,
  input  logic [1:0]   io_refill_bits_level_dup_2,
  input  logic [63:0]  io_refill_bits_sel_pte_dup_0,
  input  logic [63:0]  io_refill_bits_sel_pte_dup_2,
  output logic [3:0]   io_l0_way_info,
  input  logic         io_sfence_dup_0_valid,
  input  logic         io_sfence_dup_0_bits_rs1,
  input  logic         io_sfence_dup_0_bits_rs2,
  input  logic [49:0]  io_sfence_dup_0_bits_addr,
  input  logic [15:0]  io_sfence_dup_0_bits_id,
  input  logic         io_sfence_dup_0_bits_hv,
  input  logic         io_sfence_dup_0_bits_hg,
  input  logic         io_sfence_dup_1_valid,
  input  logic [15:0]  io_sfence_dup_1_bits_id,
  input  logic         io_sfence_dup_2_valid,
  input  logic         io_sfence_dup_2_bits_rs1,
  input  logic         io_sfence_dup_2_bits_rs2,
  input  logic [15:0]  io_sfence_dup_2_bits_id,
  input  logic [15:0]  io_csr_dup_0_satp_asid,
  input  logic         io_csr_dup_0_satp_changed,
  input  logic [15:0]  io_csr_dup_0_vsatp_asid,
  input  logic         io_csr_dup_0_vsatp_changed,
  input  logic [3:0]   io_csr_dup_0_hgatp_mode,
  input  logic [15:0]  io_csr_dup_0_hgatp_vmid,
  input  logic         io_csr_dup_0_hgatp_changed,
  input  logic         io_csr_dup_0_mbmc_BME,
  input  logic         io_csr_dup_0_mbmc_CMODE,
  input  logic         io_csr_dup_0_priv_virt,
  input  logic         io_csr_dup_0_priv_virt_changed,
  input  logic [15:0]  io_csr_dup_1_satp_asid,
  input  logic         io_csr_dup_1_satp_changed,
  input  logic [15:0]  io_csr_dup_1_vsatp_asid,
  input  logic         io_csr_dup_1_vsatp_changed,
  input  logic [3:0]   io_csr_dup_1_hgatp_mode,
  input  logic [15:0]  io_csr_dup_1_hgatp_vmid,
  input  logic         io_csr_dup_1_hgatp_changed,
  input  logic         io_csr_dup_1_priv_virt,
  input  logic         io_csr_dup_1_priv_virt_changed,
  input  logic [15:0]  io_csr_dup_2_satp_asid,
  input  logic         io_csr_dup_2_satp_changed,
  input  logic [15:0]  io_csr_dup_2_vsatp_asid,
  input  logic         io_csr_dup_2_vsatp_changed,
  input  logic [3:0]   io_csr_dup_2_hgatp_mode,
  input  logic [15:0]  io_csr_dup_2_hgatp_vmid,
  input  logic         io_csr_dup_2_hgatp_changed,
  input  logic         io_csr_dup_2_priv_virt,
  input  logic         io_csr_dup_2_priv_virt_changed,
  output logic         io_bitmap_wakeup_ready,
  input  logic         io_bitmap_wakeup_valid,
  input  logic [5:0]   io_bitmap_wakeup_bits_setIndex,
  input  logic [37:0]  io_bitmap_wakeup_bits_tag,
  input  logic [3:0]   io_bitmap_wakeup_bits_way_info,
  input  logic [2:0]   io_bitmap_wakeup_bits_pte_index,
  input  logic         io_bitmap_wakeup_bits_check_success,
  input  logic [1:0]   io_bitmap_wakeup_bits_s2xlate,
  output logic [5:0]   io_perf_0_value,
  output logic [5:0]   io_perf_1_value,
  output logic [5:0]   io_perf_2_value,
  output logic [5:0]   io_perf_3_value,
  output logic [5:0]   io_perf_4_value,
  output logic [5:0]   io_perf_5_value,
  output logic [5:0]   io_perf_6_value,
  output logic [5:0]   io_perf_7_value,
  input  logic [5:0]   boreChildrenBd_bore_array,
  input  logic         boreChildrenBd_bore_all,
  input  logic         boreChildrenBd_bore_req,
  output logic         boreChildrenBd_bore_ack,
  input  logic         boreChildrenBd_bore_writeen,
  input  logic         boreChildrenBd_bore_be,
  input  logic [2:0]   boreChildrenBd_bore_addr,
  input  logic [130:0] boreChildrenBd_bore_indata,
  input  logic         boreChildrenBd_bore_readen,
  input  logic [2:0]   boreChildrenBd_bore_addr_rd,
  output logic [130:0] boreChildrenBd_bore_outdata,
  input  logic [6:0]   boreChildrenBd_bore_1_array,
  input  logic         boreChildrenBd_bore_1_all,
  input  logic         boreChildrenBd_bore_1_req,
  output logic         boreChildrenBd_bore_1_ack,
  input  logic         boreChildrenBd_bore_1_writeen,
  input  logic [1:0]   boreChildrenBd_bore_1_be,
  input  logic [6:0]   boreChildrenBd_bore_1_addr,
  input  logic [113:0] boreChildrenBd_bore_1_indata,
  input  logic         boreChildrenBd_bore_1_readen,
  input  logic [6:0]   boreChildrenBd_bore_1_addr_rd,
  output logic [113:0] boreChildrenBd_bore_1_outdata,
  input  logic         sigFromSrams_bore_ram_hold,
  input  logic         sigFromSrams_bore_ram_bypass,
  input  logic         sigFromSrams_bore_ram_bp_clken,
  input  logic         sigFromSrams_bore_ram_aux_clk,
  input  logic         sigFromSrams_bore_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_ram_mcp_hold,
  input  logic         sigFromSrams_bore_cgen,
  input  logic         sigFromSrams_bore_1_ram_hold,
  input  logic         sigFromSrams_bore_1_ram_bypass,
  input  logic         sigFromSrams_bore_1_ram_bp_clken,
  input  logic         sigFromSrams_bore_1_ram_aux_clk,
  input  logic         sigFromSrams_bore_1_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_1_ram_mcp_hold,
  input  logic         sigFromSrams_bore_1_cgen,
  input  logic         sigFromSrams_bore_2_ram_hold,
  input  logic         sigFromSrams_bore_2_ram_bypass,
  input  logic         sigFromSrams_bore_2_ram_bp_clken,
  input  logic         sigFromSrams_bore_2_ram_aux_clk,
  input  logic         sigFromSrams_bore_2_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_2_ram_mcp_hold,
  input  logic         sigFromSrams_bore_2_cgen,
  input  logic         sigFromSrams_bore_3_ram_hold,
  input  logic         sigFromSrams_bore_3_ram_bypass,
  input  logic         sigFromSrams_bore_3_ram_bp_clken,
  input  logic         sigFromSrams_bore_3_ram_aux_clk,
  input  logic         sigFromSrams_bore_3_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_3_ram_mcp_hold,
  input  logic         sigFromSrams_bore_3_cgen,
  input  logic         sigFromSrams_bore_4_ram_hold,
  input  logic         sigFromSrams_bore_4_ram_bypass,
  input  logic         sigFromSrams_bore_4_ram_bp_clken,
  input  logic         sigFromSrams_bore_4_ram_aux_clk,
  input  logic         sigFromSrams_bore_4_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_4_ram_mcp_hold,
  input  logic         sigFromSrams_bore_4_cgen,
  input  logic         sigFromSrams_bore_5_ram_hold,
  input  logic         sigFromSrams_bore_5_ram_bypass,
  input  logic         sigFromSrams_bore_5_ram_bp_clken,
  input  logic         sigFromSrams_bore_5_ram_aux_clk,
  input  logic         sigFromSrams_bore_5_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_5_ram_mcp_hold,
  input  logic         sigFromSrams_bore_5_cgen,
  input  logic         sigFromSrams_bore_6_ram_hold,
  input  logic         sigFromSrams_bore_6_ram_bypass,
  input  logic         sigFromSrams_bore_6_ram_bp_clken,
  input  logic         sigFromSrams_bore_6_ram_aux_clk,
  input  logic         sigFromSrams_bore_6_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_6_ram_mcp_hold,
  input  logic         sigFromSrams_bore_6_cgen,
  input  logic         sigFromSrams_bore_7_ram_hold,
  input  logic         sigFromSrams_bore_7_ram_bypass,
  input  logic         sigFromSrams_bore_7_ram_bp_clken,
  input  logic         sigFromSrams_bore_7_ram_aux_clk,
  input  logic         sigFromSrams_bore_7_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_7_ram_mcp_hold,
  input  logic         sigFromSrams_bore_7_cgen,
  input  logic         sigFromSrams_bore_8_ram_hold,
  input  logic         sigFromSrams_bore_8_ram_bypass,
  input  logic         sigFromSrams_bore_8_ram_bp_clken,
  input  logic         sigFromSrams_bore_8_ram_aux_clk,
  input  logic         sigFromSrams_bore_8_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_8_ram_mcp_hold,
  input  logic         sigFromSrams_bore_8_cgen,
  input  logic         sigFromSrams_bore_9_ram_hold,
  input  logic         sigFromSrams_bore_9_ram_bypass,
  input  logic         sigFromSrams_bore_9_ram_bp_clken,
  input  logic         sigFromSrams_bore_9_ram_aux_clk,
  input  logic         sigFromSrams_bore_9_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_9_ram_mcp_hold,
  input  logic         sigFromSrams_bore_9_cgen,
  input  logic         sigFromSrams_bore_10_ram_hold,
  input  logic         sigFromSrams_bore_10_ram_bypass,
  input  logic         sigFromSrams_bore_10_ram_bp_clken,
  input  logic         sigFromSrams_bore_10_ram_aux_clk,
  input  logic         sigFromSrams_bore_10_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_10_ram_mcp_hold,
  input  logic         sigFromSrams_bore_10_cgen,
  input  logic         sigFromSrams_bore_11_ram_hold,
  input  logic         sigFromSrams_bore_11_ram_bypass,
  input  logic         sigFromSrams_bore_11_ram_bp_clken,
  input  logic         sigFromSrams_bore_11_ram_aux_clk,
  input  logic         sigFromSrams_bore_11_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_11_ram_mcp_hold,
  input  logic         sigFromSrams_bore_11_cgen,
  input  logic         sigFromSrams_bore_12_ram_hold,
  input  logic         sigFromSrams_bore_12_ram_bypass,
  input  logic         sigFromSrams_bore_12_ram_bp_clken,
  input  logic         sigFromSrams_bore_12_ram_aux_clk,
  input  logic         sigFromSrams_bore_12_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_12_ram_mcp_hold,
  input  logic         sigFromSrams_bore_12_cgen,
  input  logic         sigFromSrams_bore_13_ram_hold,
  input  logic         sigFromSrams_bore_13_ram_bypass,
  input  logic         sigFromSrams_bore_13_ram_bp_clken,
  input  logic         sigFromSrams_bore_13_ram_aux_clk,
  input  logic         sigFromSrams_bore_13_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_13_ram_mcp_hold,
  input  logic         sigFromSrams_bore_13_cgen,
  input  logic         sigFromSrams_bore_14_ram_hold,
  input  logic         sigFromSrams_bore_14_ram_bypass,
  input  logic         sigFromSrams_bore_14_ram_bp_clken,
  input  logic         sigFromSrams_bore_14_ram_aux_clk,
  input  logic         sigFromSrams_bore_14_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_14_ram_mcp_hold,
  input  logic         sigFromSrams_bore_14_cgen,
  input  logic         sigFromSrams_bore_15_ram_hold,
  input  logic         sigFromSrams_bore_15_ram_bypass,
  input  logic         sigFromSrams_bore_15_ram_bp_clken,
  input  logic         sigFromSrams_bore_15_ram_aux_clk,
  input  logic         sigFromSrams_bore_15_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_15_ram_mcp_hold,
  input  logic         sigFromSrams_bore_15_cgen,
  input  logic         sigFromSrams_bore_16_ram_hold,
  input  logic         sigFromSrams_bore_16_ram_bypass,
  input  logic         sigFromSrams_bore_16_ram_bp_clken,
  input  logic         sigFromSrams_bore_16_ram_aux_clk,
  input  logic         sigFromSrams_bore_16_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_16_ram_mcp_hold,
  input  logic         sigFromSrams_bore_16_cgen,
  input  logic         cg_bore_cgen
);

  // 薄壳：golden 同名、逐位同序的端口表，整体透传给可读核。
  xs_PtwCache_core u_core (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_csr_mPBMTE                                    (io_csr_mPBMTE),
    .io_csr_hPBMTE                                    (io_csr_hPBMTE),
    .io_req_ready                                     (io_req_ready),
    .io_req_valid                                     (io_req_valid),
    .io_req_bits_req_info_vpn                         (io_req_bits_req_info_vpn),
    .io_req_bits_req_info_s2xlate                     (io_req_bits_req_info_s2xlate),
    .io_req_bits_req_info_source                      (io_req_bits_req_info_source),
    .io_req_bits_isFirst                              (io_req_bits_isFirst),
    .io_req_bits_isHptwReq                            (io_req_bits_isHptwReq),
    .io_req_bits_hptwId                               (io_req_bits_hptwId),
    .io_resp_ready                                    (io_resp_ready),
    .io_resp_valid                                    (io_resp_valid),
    .io_resp_bits_req_info_vpn                        (io_resp_bits_req_info_vpn),
    .io_resp_bits_req_info_s2xlate                    (io_resp_bits_req_info_s2xlate),
    .io_resp_bits_req_info_source                     (io_resp_bits_req_info_source),
    .io_resp_bits_isFirst                             (io_resp_bits_isFirst),
    .io_resp_bits_hit                                 (io_resp_bits_hit),
    .io_resp_bits_prefetch                            (io_resp_bits_prefetch),
    .io_resp_bits_bypassed                            (io_resp_bits_bypassed),
    .io_resp_bits_toFsm_l3Hit                         (io_resp_bits_toFsm_l3Hit),
    .io_resp_bits_toFsm_l2Hit                         (io_resp_bits_toFsm_l2Hit),
    .io_resp_bits_toFsm_l1Hit                         (io_resp_bits_toFsm_l1Hit),
    .io_resp_bits_toFsm_ppn                           (io_resp_bits_toFsm_ppn),
    .io_resp_bits_toFsm_stage1Hit                     (io_resp_bits_toFsm_stage1Hit),
    .io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check  (io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check),
    .io_resp_bits_toFsm_bitmapCheck_toLLPTW           (io_resp_bits_toFsm_bitmapCheck_toLLPTW),
    .io_resp_bits_toFsm_bitmapCheck_hitway            (io_resp_bits_toFsm_bitmapCheck_hitway),
    .io_resp_bits_toFsm_bitmapCheck_pte               (io_resp_bits_toFsm_bitmapCheck_pte),
    .io_resp_bits_toFsm_bitmapCheck_ptes_0            (io_resp_bits_toFsm_bitmapCheck_ptes_0),
    .io_resp_bits_toFsm_bitmapCheck_ptes_1            (io_resp_bits_toFsm_bitmapCheck_ptes_1),
    .io_resp_bits_toFsm_bitmapCheck_ptes_2            (io_resp_bits_toFsm_bitmapCheck_ptes_2),
    .io_resp_bits_toFsm_bitmapCheck_ptes_3            (io_resp_bits_toFsm_bitmapCheck_ptes_3),
    .io_resp_bits_toFsm_bitmapCheck_ptes_4            (io_resp_bits_toFsm_bitmapCheck_ptes_4),
    .io_resp_bits_toFsm_bitmapCheck_ptes_5            (io_resp_bits_toFsm_bitmapCheck_ptes_5),
    .io_resp_bits_toFsm_bitmapCheck_ptes_6            (io_resp_bits_toFsm_bitmapCheck_ptes_6),
    .io_resp_bits_toFsm_bitmapCheck_ptes_7            (io_resp_bits_toFsm_bitmapCheck_ptes_7),
    .io_resp_bits_toFsm_bitmapCheck_cfs_0             (io_resp_bits_toFsm_bitmapCheck_cfs_0),
    .io_resp_bits_toFsm_bitmapCheck_cfs_1             (io_resp_bits_toFsm_bitmapCheck_cfs_1),
    .io_resp_bits_toFsm_bitmapCheck_cfs_2             (io_resp_bits_toFsm_bitmapCheck_cfs_2),
    .io_resp_bits_toFsm_bitmapCheck_cfs_3             (io_resp_bits_toFsm_bitmapCheck_cfs_3),
    .io_resp_bits_toFsm_bitmapCheck_cfs_4             (io_resp_bits_toFsm_bitmapCheck_cfs_4),
    .io_resp_bits_toFsm_bitmapCheck_cfs_5             (io_resp_bits_toFsm_bitmapCheck_cfs_5),
    .io_resp_bits_toFsm_bitmapCheck_cfs_6             (io_resp_bits_toFsm_bitmapCheck_cfs_6),
    .io_resp_bits_toFsm_bitmapCheck_cfs_7             (io_resp_bits_toFsm_bitmapCheck_cfs_7),
    .io_resp_bits_toFsm_bitmapCheck_SPlevel           (io_resp_bits_toFsm_bitmapCheck_SPlevel),
    .io_resp_bits_stage1_entry_0_tag                  (io_resp_bits_stage1_entry_0_tag),
    .io_resp_bits_stage1_entry_0_asid                 (io_resp_bits_stage1_entry_0_asid),
    .io_resp_bits_stage1_entry_0_vmid                 (io_resp_bits_stage1_entry_0_vmid),
    .io_resp_bits_stage1_entry_0_n                    (io_resp_bits_stage1_entry_0_n),
    .io_resp_bits_stage1_entry_0_pbmt                 (io_resp_bits_stage1_entry_0_pbmt),
    .io_resp_bits_stage1_entry_0_perm_d               (io_resp_bits_stage1_entry_0_perm_d),
    .io_resp_bits_stage1_entry_0_perm_a               (io_resp_bits_stage1_entry_0_perm_a),
    .io_resp_bits_stage1_entry_0_perm_g               (io_resp_bits_stage1_entry_0_perm_g),
    .io_resp_bits_stage1_entry_0_perm_u               (io_resp_bits_stage1_entry_0_perm_u),
    .io_resp_bits_stage1_entry_0_perm_x               (io_resp_bits_stage1_entry_0_perm_x),
    .io_resp_bits_stage1_entry_0_perm_w               (io_resp_bits_stage1_entry_0_perm_w),
    .io_resp_bits_stage1_entry_0_perm_r               (io_resp_bits_stage1_entry_0_perm_r),
    .io_resp_bits_stage1_entry_0_level                (io_resp_bits_stage1_entry_0_level),
    .io_resp_bits_stage1_entry_0_v                    (io_resp_bits_stage1_entry_0_v),
    .io_resp_bits_stage1_entry_0_ppn                  (io_resp_bits_stage1_entry_0_ppn),
    .io_resp_bits_stage1_entry_0_ppn_low              (io_resp_bits_stage1_entry_0_ppn_low),
    .io_resp_bits_stage1_entry_0_pf                   (io_resp_bits_stage1_entry_0_pf),
    .io_resp_bits_stage1_entry_0_cf                   (io_resp_bits_stage1_entry_0_cf),
    .io_resp_bits_stage1_entry_1_tag                  (io_resp_bits_stage1_entry_1_tag),
    .io_resp_bits_stage1_entry_1_asid                 (io_resp_bits_stage1_entry_1_asid),
    .io_resp_bits_stage1_entry_1_vmid                 (io_resp_bits_stage1_entry_1_vmid),
    .io_resp_bits_stage1_entry_1_n                    (io_resp_bits_stage1_entry_1_n),
    .io_resp_bits_stage1_entry_1_pbmt                 (io_resp_bits_stage1_entry_1_pbmt),
    .io_resp_bits_stage1_entry_1_perm_d               (io_resp_bits_stage1_entry_1_perm_d),
    .io_resp_bits_stage1_entry_1_perm_a               (io_resp_bits_stage1_entry_1_perm_a),
    .io_resp_bits_stage1_entry_1_perm_g               (io_resp_bits_stage1_entry_1_perm_g),
    .io_resp_bits_stage1_entry_1_perm_u               (io_resp_bits_stage1_entry_1_perm_u),
    .io_resp_bits_stage1_entry_1_perm_x               (io_resp_bits_stage1_entry_1_perm_x),
    .io_resp_bits_stage1_entry_1_perm_w               (io_resp_bits_stage1_entry_1_perm_w),
    .io_resp_bits_stage1_entry_1_perm_r               (io_resp_bits_stage1_entry_1_perm_r),
    .io_resp_bits_stage1_entry_1_level                (io_resp_bits_stage1_entry_1_level),
    .io_resp_bits_stage1_entry_1_v                    (io_resp_bits_stage1_entry_1_v),
    .io_resp_bits_stage1_entry_1_ppn                  (io_resp_bits_stage1_entry_1_ppn),
    .io_resp_bits_stage1_entry_1_ppn_low              (io_resp_bits_stage1_entry_1_ppn_low),
    .io_resp_bits_stage1_entry_1_pf                   (io_resp_bits_stage1_entry_1_pf),
    .io_resp_bits_stage1_entry_1_cf                   (io_resp_bits_stage1_entry_1_cf),
    .io_resp_bits_stage1_entry_2_tag                  (io_resp_bits_stage1_entry_2_tag),
    .io_resp_bits_stage1_entry_2_asid                 (io_resp_bits_stage1_entry_2_asid),
    .io_resp_bits_stage1_entry_2_vmid                 (io_resp_bits_stage1_entry_2_vmid),
    .io_resp_bits_stage1_entry_2_n                    (io_resp_bits_stage1_entry_2_n),
    .io_resp_bits_stage1_entry_2_pbmt                 (io_resp_bits_stage1_entry_2_pbmt),
    .io_resp_bits_stage1_entry_2_perm_d               (io_resp_bits_stage1_entry_2_perm_d),
    .io_resp_bits_stage1_entry_2_perm_a               (io_resp_bits_stage1_entry_2_perm_a),
    .io_resp_bits_stage1_entry_2_perm_g               (io_resp_bits_stage1_entry_2_perm_g),
    .io_resp_bits_stage1_entry_2_perm_u               (io_resp_bits_stage1_entry_2_perm_u),
    .io_resp_bits_stage1_entry_2_perm_x               (io_resp_bits_stage1_entry_2_perm_x),
    .io_resp_bits_stage1_entry_2_perm_w               (io_resp_bits_stage1_entry_2_perm_w),
    .io_resp_bits_stage1_entry_2_perm_r               (io_resp_bits_stage1_entry_2_perm_r),
    .io_resp_bits_stage1_entry_2_level                (io_resp_bits_stage1_entry_2_level),
    .io_resp_bits_stage1_entry_2_v                    (io_resp_bits_stage1_entry_2_v),
    .io_resp_bits_stage1_entry_2_ppn                  (io_resp_bits_stage1_entry_2_ppn),
    .io_resp_bits_stage1_entry_2_ppn_low              (io_resp_bits_stage1_entry_2_ppn_low),
    .io_resp_bits_stage1_entry_2_pf                   (io_resp_bits_stage1_entry_2_pf),
    .io_resp_bits_stage1_entry_2_cf                   (io_resp_bits_stage1_entry_2_cf),
    .io_resp_bits_stage1_entry_3_tag                  (io_resp_bits_stage1_entry_3_tag),
    .io_resp_bits_stage1_entry_3_asid                 (io_resp_bits_stage1_entry_3_asid),
    .io_resp_bits_stage1_entry_3_vmid                 (io_resp_bits_stage1_entry_3_vmid),
    .io_resp_bits_stage1_entry_3_n                    (io_resp_bits_stage1_entry_3_n),
    .io_resp_bits_stage1_entry_3_pbmt                 (io_resp_bits_stage1_entry_3_pbmt),
    .io_resp_bits_stage1_entry_3_perm_d               (io_resp_bits_stage1_entry_3_perm_d),
    .io_resp_bits_stage1_entry_3_perm_a               (io_resp_bits_stage1_entry_3_perm_a),
    .io_resp_bits_stage1_entry_3_perm_g               (io_resp_bits_stage1_entry_3_perm_g),
    .io_resp_bits_stage1_entry_3_perm_u               (io_resp_bits_stage1_entry_3_perm_u),
    .io_resp_bits_stage1_entry_3_perm_x               (io_resp_bits_stage1_entry_3_perm_x),
    .io_resp_bits_stage1_entry_3_perm_w               (io_resp_bits_stage1_entry_3_perm_w),
    .io_resp_bits_stage1_entry_3_perm_r               (io_resp_bits_stage1_entry_3_perm_r),
    .io_resp_bits_stage1_entry_3_level                (io_resp_bits_stage1_entry_3_level),
    .io_resp_bits_stage1_entry_3_v                    (io_resp_bits_stage1_entry_3_v),
    .io_resp_bits_stage1_entry_3_ppn                  (io_resp_bits_stage1_entry_3_ppn),
    .io_resp_bits_stage1_entry_3_ppn_low              (io_resp_bits_stage1_entry_3_ppn_low),
    .io_resp_bits_stage1_entry_3_pf                   (io_resp_bits_stage1_entry_3_pf),
    .io_resp_bits_stage1_entry_3_cf                   (io_resp_bits_stage1_entry_3_cf),
    .io_resp_bits_stage1_entry_4_tag                  (io_resp_bits_stage1_entry_4_tag),
    .io_resp_bits_stage1_entry_4_asid                 (io_resp_bits_stage1_entry_4_asid),
    .io_resp_bits_stage1_entry_4_vmid                 (io_resp_bits_stage1_entry_4_vmid),
    .io_resp_bits_stage1_entry_4_n                    (io_resp_bits_stage1_entry_4_n),
    .io_resp_bits_stage1_entry_4_pbmt                 (io_resp_bits_stage1_entry_4_pbmt),
    .io_resp_bits_stage1_entry_4_perm_d               (io_resp_bits_stage1_entry_4_perm_d),
    .io_resp_bits_stage1_entry_4_perm_a               (io_resp_bits_stage1_entry_4_perm_a),
    .io_resp_bits_stage1_entry_4_perm_g               (io_resp_bits_stage1_entry_4_perm_g),
    .io_resp_bits_stage1_entry_4_perm_u               (io_resp_bits_stage1_entry_4_perm_u),
    .io_resp_bits_stage1_entry_4_perm_x               (io_resp_bits_stage1_entry_4_perm_x),
    .io_resp_bits_stage1_entry_4_perm_w               (io_resp_bits_stage1_entry_4_perm_w),
    .io_resp_bits_stage1_entry_4_perm_r               (io_resp_bits_stage1_entry_4_perm_r),
    .io_resp_bits_stage1_entry_4_level                (io_resp_bits_stage1_entry_4_level),
    .io_resp_bits_stage1_entry_4_v                    (io_resp_bits_stage1_entry_4_v),
    .io_resp_bits_stage1_entry_4_ppn                  (io_resp_bits_stage1_entry_4_ppn),
    .io_resp_bits_stage1_entry_4_ppn_low              (io_resp_bits_stage1_entry_4_ppn_low),
    .io_resp_bits_stage1_entry_4_pf                   (io_resp_bits_stage1_entry_4_pf),
    .io_resp_bits_stage1_entry_4_cf                   (io_resp_bits_stage1_entry_4_cf),
    .io_resp_bits_stage1_entry_5_tag                  (io_resp_bits_stage1_entry_5_tag),
    .io_resp_bits_stage1_entry_5_asid                 (io_resp_bits_stage1_entry_5_asid),
    .io_resp_bits_stage1_entry_5_vmid                 (io_resp_bits_stage1_entry_5_vmid),
    .io_resp_bits_stage1_entry_5_n                    (io_resp_bits_stage1_entry_5_n),
    .io_resp_bits_stage1_entry_5_pbmt                 (io_resp_bits_stage1_entry_5_pbmt),
    .io_resp_bits_stage1_entry_5_perm_d               (io_resp_bits_stage1_entry_5_perm_d),
    .io_resp_bits_stage1_entry_5_perm_a               (io_resp_bits_stage1_entry_5_perm_a),
    .io_resp_bits_stage1_entry_5_perm_g               (io_resp_bits_stage1_entry_5_perm_g),
    .io_resp_bits_stage1_entry_5_perm_u               (io_resp_bits_stage1_entry_5_perm_u),
    .io_resp_bits_stage1_entry_5_perm_x               (io_resp_bits_stage1_entry_5_perm_x),
    .io_resp_bits_stage1_entry_5_perm_w               (io_resp_bits_stage1_entry_5_perm_w),
    .io_resp_bits_stage1_entry_5_perm_r               (io_resp_bits_stage1_entry_5_perm_r),
    .io_resp_bits_stage1_entry_5_level                (io_resp_bits_stage1_entry_5_level),
    .io_resp_bits_stage1_entry_5_v                    (io_resp_bits_stage1_entry_5_v),
    .io_resp_bits_stage1_entry_5_ppn                  (io_resp_bits_stage1_entry_5_ppn),
    .io_resp_bits_stage1_entry_5_ppn_low              (io_resp_bits_stage1_entry_5_ppn_low),
    .io_resp_bits_stage1_entry_5_pf                   (io_resp_bits_stage1_entry_5_pf),
    .io_resp_bits_stage1_entry_5_cf                   (io_resp_bits_stage1_entry_5_cf),
    .io_resp_bits_stage1_entry_6_tag                  (io_resp_bits_stage1_entry_6_tag),
    .io_resp_bits_stage1_entry_6_asid                 (io_resp_bits_stage1_entry_6_asid),
    .io_resp_bits_stage1_entry_6_vmid                 (io_resp_bits_stage1_entry_6_vmid),
    .io_resp_bits_stage1_entry_6_n                    (io_resp_bits_stage1_entry_6_n),
    .io_resp_bits_stage1_entry_6_pbmt                 (io_resp_bits_stage1_entry_6_pbmt),
    .io_resp_bits_stage1_entry_6_perm_d               (io_resp_bits_stage1_entry_6_perm_d),
    .io_resp_bits_stage1_entry_6_perm_a               (io_resp_bits_stage1_entry_6_perm_a),
    .io_resp_bits_stage1_entry_6_perm_g               (io_resp_bits_stage1_entry_6_perm_g),
    .io_resp_bits_stage1_entry_6_perm_u               (io_resp_bits_stage1_entry_6_perm_u),
    .io_resp_bits_stage1_entry_6_perm_x               (io_resp_bits_stage1_entry_6_perm_x),
    .io_resp_bits_stage1_entry_6_perm_w               (io_resp_bits_stage1_entry_6_perm_w),
    .io_resp_bits_stage1_entry_6_perm_r               (io_resp_bits_stage1_entry_6_perm_r),
    .io_resp_bits_stage1_entry_6_level                (io_resp_bits_stage1_entry_6_level),
    .io_resp_bits_stage1_entry_6_v                    (io_resp_bits_stage1_entry_6_v),
    .io_resp_bits_stage1_entry_6_ppn                  (io_resp_bits_stage1_entry_6_ppn),
    .io_resp_bits_stage1_entry_6_ppn_low              (io_resp_bits_stage1_entry_6_ppn_low),
    .io_resp_bits_stage1_entry_6_pf                   (io_resp_bits_stage1_entry_6_pf),
    .io_resp_bits_stage1_entry_6_cf                   (io_resp_bits_stage1_entry_6_cf),
    .io_resp_bits_stage1_entry_7_tag                  (io_resp_bits_stage1_entry_7_tag),
    .io_resp_bits_stage1_entry_7_asid                 (io_resp_bits_stage1_entry_7_asid),
    .io_resp_bits_stage1_entry_7_vmid                 (io_resp_bits_stage1_entry_7_vmid),
    .io_resp_bits_stage1_entry_7_n                    (io_resp_bits_stage1_entry_7_n),
    .io_resp_bits_stage1_entry_7_pbmt                 (io_resp_bits_stage1_entry_7_pbmt),
    .io_resp_bits_stage1_entry_7_perm_d               (io_resp_bits_stage1_entry_7_perm_d),
    .io_resp_bits_stage1_entry_7_perm_a               (io_resp_bits_stage1_entry_7_perm_a),
    .io_resp_bits_stage1_entry_7_perm_g               (io_resp_bits_stage1_entry_7_perm_g),
    .io_resp_bits_stage1_entry_7_perm_u               (io_resp_bits_stage1_entry_7_perm_u),
    .io_resp_bits_stage1_entry_7_perm_x               (io_resp_bits_stage1_entry_7_perm_x),
    .io_resp_bits_stage1_entry_7_perm_w               (io_resp_bits_stage1_entry_7_perm_w),
    .io_resp_bits_stage1_entry_7_perm_r               (io_resp_bits_stage1_entry_7_perm_r),
    .io_resp_bits_stage1_entry_7_level                (io_resp_bits_stage1_entry_7_level),
    .io_resp_bits_stage1_entry_7_v                    (io_resp_bits_stage1_entry_7_v),
    .io_resp_bits_stage1_entry_7_ppn                  (io_resp_bits_stage1_entry_7_ppn),
    .io_resp_bits_stage1_entry_7_ppn_low              (io_resp_bits_stage1_entry_7_ppn_low),
    .io_resp_bits_stage1_entry_7_pf                   (io_resp_bits_stage1_entry_7_pf),
    .io_resp_bits_stage1_entry_7_cf                   (io_resp_bits_stage1_entry_7_cf),
    .io_resp_bits_stage1_pteidx_0                     (io_resp_bits_stage1_pteidx_0),
    .io_resp_bits_stage1_pteidx_1                     (io_resp_bits_stage1_pteidx_1),
    .io_resp_bits_stage1_pteidx_2                     (io_resp_bits_stage1_pteidx_2),
    .io_resp_bits_stage1_pteidx_3                     (io_resp_bits_stage1_pteidx_3),
    .io_resp_bits_stage1_pteidx_4                     (io_resp_bits_stage1_pteidx_4),
    .io_resp_bits_stage1_pteidx_5                     (io_resp_bits_stage1_pteidx_5),
    .io_resp_bits_stage1_pteidx_6                     (io_resp_bits_stage1_pteidx_6),
    .io_resp_bits_stage1_pteidx_7                     (io_resp_bits_stage1_pteidx_7),
    .io_resp_bits_stage1_not_super                    (io_resp_bits_stage1_not_super),
    .io_resp_bits_isHptwReq                           (io_resp_bits_isHptwReq),
    .io_resp_bits_toHptw_l3Hit                        (io_resp_bits_toHptw_l3Hit),
    .io_resp_bits_toHptw_l2Hit                        (io_resp_bits_toHptw_l2Hit),
    .io_resp_bits_toHptw_l1Hit                        (io_resp_bits_toHptw_l1Hit),
    .io_resp_bits_toHptw_ppn                          (io_resp_bits_toHptw_ppn),
    .io_resp_bits_toHptw_id                           (io_resp_bits_toHptw_id),
    .io_resp_bits_toHptw_resp_entry_tag               (io_resp_bits_toHptw_resp_entry_tag),
    .io_resp_bits_toHptw_resp_entry_vmid              (io_resp_bits_toHptw_resp_entry_vmid),
    .io_resp_bits_toHptw_resp_entry_n                 (io_resp_bits_toHptw_resp_entry_n),
    .io_resp_bits_toHptw_resp_entry_pbmt              (io_resp_bits_toHptw_resp_entry_pbmt),
    .io_resp_bits_toHptw_resp_entry_ppn               (io_resp_bits_toHptw_resp_entry_ppn),
    .io_resp_bits_toHptw_resp_entry_perm_d            (io_resp_bits_toHptw_resp_entry_perm_d),
    .io_resp_bits_toHptw_resp_entry_perm_a            (io_resp_bits_toHptw_resp_entry_perm_a),
    .io_resp_bits_toHptw_resp_entry_perm_g            (io_resp_bits_toHptw_resp_entry_perm_g),
    .io_resp_bits_toHptw_resp_entry_perm_u            (io_resp_bits_toHptw_resp_entry_perm_u),
    .io_resp_bits_toHptw_resp_entry_perm_x            (io_resp_bits_toHptw_resp_entry_perm_x),
    .io_resp_bits_toHptw_resp_entry_perm_w            (io_resp_bits_toHptw_resp_entry_perm_w),
    .io_resp_bits_toHptw_resp_entry_perm_r            (io_resp_bits_toHptw_resp_entry_perm_r),
    .io_resp_bits_toHptw_resp_entry_level             (io_resp_bits_toHptw_resp_entry_level),
    .io_resp_bits_toHptw_resp_gpf                     (io_resp_bits_toHptw_resp_gpf),
    .io_resp_bits_toHptw_bypassed                     (io_resp_bits_toHptw_bypassed),
    .io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check (io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check),
    .io_resp_bits_toHptw_bitmapCheck_hitway           (io_resp_bits_toHptw_bitmapCheck_hitway),
    .io_resp_bits_toHptw_bitmapCheck_pte              (io_resp_bits_toHptw_bitmapCheck_pte),
    .io_resp_bits_toHptw_bitmapCheck_ptes_0           (io_resp_bits_toHptw_bitmapCheck_ptes_0),
    .io_resp_bits_toHptw_bitmapCheck_ptes_1           (io_resp_bits_toHptw_bitmapCheck_ptes_1),
    .io_resp_bits_toHptw_bitmapCheck_ptes_2           (io_resp_bits_toHptw_bitmapCheck_ptes_2),
    .io_resp_bits_toHptw_bitmapCheck_ptes_3           (io_resp_bits_toHptw_bitmapCheck_ptes_3),
    .io_resp_bits_toHptw_bitmapCheck_ptes_4           (io_resp_bits_toHptw_bitmapCheck_ptes_4),
    .io_resp_bits_toHptw_bitmapCheck_ptes_5           (io_resp_bits_toHptw_bitmapCheck_ptes_5),
    .io_resp_bits_toHptw_bitmapCheck_ptes_6           (io_resp_bits_toHptw_bitmapCheck_ptes_6),
    .io_resp_bits_toHptw_bitmapCheck_ptes_7           (io_resp_bits_toHptw_bitmapCheck_ptes_7),
    .io_resp_bits_toHptw_bitmapCheck_fromSP           (io_resp_bits_toHptw_bitmapCheck_fromSP),
    .io_resp_bits_toHptw_bitmapCheck_SPlevel          (io_resp_bits_toHptw_bitmapCheck_SPlevel),
    .io_refill_valid                                  (io_refill_valid),
    .io_refill_bits_ptes                              (io_refill_bits_ptes),
    .io_refill_bits_levelOH_sp                        (io_refill_bits_levelOH_sp),
    .io_refill_bits_levelOH_l0                        (io_refill_bits_levelOH_l0),
    .io_refill_bits_levelOH_l1                        (io_refill_bits_levelOH_l1),
    .io_refill_bits_levelOH_l2                        (io_refill_bits_levelOH_l2),
    .io_refill_bits_levelOH_l3                        (io_refill_bits_levelOH_l3),
    .io_refill_bits_req_info_dup_0_vpn                (io_refill_bits_req_info_dup_0_vpn),
    .io_refill_bits_req_info_dup_0_s2xlate            (io_refill_bits_req_info_dup_0_s2xlate),
    .io_refill_bits_req_info_dup_0_source             (io_refill_bits_req_info_dup_0_source),
    .io_refill_bits_req_info_dup_1_vpn                (io_refill_bits_req_info_dup_1_vpn),
    .io_refill_bits_req_info_dup_1_s2xlate            (io_refill_bits_req_info_dup_1_s2xlate),
    .io_refill_bits_req_info_dup_1_source             (io_refill_bits_req_info_dup_1_source),
    .io_refill_bits_req_info_dup_2_vpn                (io_refill_bits_req_info_dup_2_vpn),
    .io_refill_bits_req_info_dup_2_s2xlate            (io_refill_bits_req_info_dup_2_s2xlate),
    .io_refill_bits_req_info_dup_2_source             (io_refill_bits_req_info_dup_2_source),
    .io_refill_bits_level_dup_0                       (io_refill_bits_level_dup_0),
    .io_refill_bits_level_dup_2                       (io_refill_bits_level_dup_2),
    .io_refill_bits_sel_pte_dup_0                     (io_refill_bits_sel_pte_dup_0),
    .io_refill_bits_sel_pte_dup_2                     (io_refill_bits_sel_pte_dup_2),
    .io_l0_way_info                                   (io_l0_way_info),
    .io_sfence_dup_0_valid                            (io_sfence_dup_0_valid),
    .io_sfence_dup_0_bits_rs1                         (io_sfence_dup_0_bits_rs1),
    .io_sfence_dup_0_bits_rs2                         (io_sfence_dup_0_bits_rs2),
    .io_sfence_dup_0_bits_addr                        (io_sfence_dup_0_bits_addr),
    .io_sfence_dup_0_bits_id                          (io_sfence_dup_0_bits_id),
    .io_sfence_dup_0_bits_hv                          (io_sfence_dup_0_bits_hv),
    .io_sfence_dup_0_bits_hg                          (io_sfence_dup_0_bits_hg),
    .io_sfence_dup_1_valid                            (io_sfence_dup_1_valid),
    .io_sfence_dup_1_bits_id                          (io_sfence_dup_1_bits_id),
    .io_sfence_dup_2_valid                            (io_sfence_dup_2_valid),
    .io_sfence_dup_2_bits_rs1                         (io_sfence_dup_2_bits_rs1),
    .io_sfence_dup_2_bits_rs2                         (io_sfence_dup_2_bits_rs2),
    .io_sfence_dup_2_bits_id                          (io_sfence_dup_2_bits_id),
    .io_csr_dup_0_satp_asid                           (io_csr_dup_0_satp_asid),
    .io_csr_dup_0_satp_changed                        (io_csr_dup_0_satp_changed),
    .io_csr_dup_0_vsatp_asid                          (io_csr_dup_0_vsatp_asid),
    .io_csr_dup_0_vsatp_changed                       (io_csr_dup_0_vsatp_changed),
    .io_csr_dup_0_hgatp_mode                          (io_csr_dup_0_hgatp_mode),
    .io_csr_dup_0_hgatp_vmid                          (io_csr_dup_0_hgatp_vmid),
    .io_csr_dup_0_hgatp_changed                       (io_csr_dup_0_hgatp_changed),
    .io_csr_dup_0_mbmc_BME                            (io_csr_dup_0_mbmc_BME),
    .io_csr_dup_0_mbmc_CMODE                          (io_csr_dup_0_mbmc_CMODE),
    .io_csr_dup_0_priv_virt                           (io_csr_dup_0_priv_virt),
    .io_csr_dup_0_priv_virt_changed                   (io_csr_dup_0_priv_virt_changed),
    .io_csr_dup_1_satp_asid                           (io_csr_dup_1_satp_asid),
    .io_csr_dup_1_satp_changed                        (io_csr_dup_1_satp_changed),
    .io_csr_dup_1_vsatp_asid                          (io_csr_dup_1_vsatp_asid),
    .io_csr_dup_1_vsatp_changed                       (io_csr_dup_1_vsatp_changed),
    .io_csr_dup_1_hgatp_mode                          (io_csr_dup_1_hgatp_mode),
    .io_csr_dup_1_hgatp_vmid                          (io_csr_dup_1_hgatp_vmid),
    .io_csr_dup_1_hgatp_changed                       (io_csr_dup_1_hgatp_changed),
    .io_csr_dup_1_priv_virt                           (io_csr_dup_1_priv_virt),
    .io_csr_dup_1_priv_virt_changed                   (io_csr_dup_1_priv_virt_changed),
    .io_csr_dup_2_satp_asid                           (io_csr_dup_2_satp_asid),
    .io_csr_dup_2_satp_changed                        (io_csr_dup_2_satp_changed),
    .io_csr_dup_2_vsatp_asid                          (io_csr_dup_2_vsatp_asid),
    .io_csr_dup_2_vsatp_changed                       (io_csr_dup_2_vsatp_changed),
    .io_csr_dup_2_hgatp_mode                          (io_csr_dup_2_hgatp_mode),
    .io_csr_dup_2_hgatp_vmid                          (io_csr_dup_2_hgatp_vmid),
    .io_csr_dup_2_hgatp_changed                       (io_csr_dup_2_hgatp_changed),
    .io_csr_dup_2_priv_virt                           (io_csr_dup_2_priv_virt),
    .io_csr_dup_2_priv_virt_changed                   (io_csr_dup_2_priv_virt_changed),
    .io_bitmap_wakeup_ready                           (io_bitmap_wakeup_ready),
    .io_bitmap_wakeup_valid                           (io_bitmap_wakeup_valid),
    .io_bitmap_wakeup_bits_setIndex                   (io_bitmap_wakeup_bits_setIndex),
    .io_bitmap_wakeup_bits_tag                        (io_bitmap_wakeup_bits_tag),
    .io_bitmap_wakeup_bits_way_info                   (io_bitmap_wakeup_bits_way_info),
    .io_bitmap_wakeup_bits_pte_index                  (io_bitmap_wakeup_bits_pte_index),
    .io_bitmap_wakeup_bits_check_success              (io_bitmap_wakeup_bits_check_success),
    .io_bitmap_wakeup_bits_s2xlate                    (io_bitmap_wakeup_bits_s2xlate),
    .io_perf_0_value                                  (io_perf_0_value),
    .io_perf_1_value                                  (io_perf_1_value),
    .io_perf_2_value                                  (io_perf_2_value),
    .io_perf_3_value                                  (io_perf_3_value),
    .io_perf_4_value                                  (io_perf_4_value),
    .io_perf_5_value                                  (io_perf_5_value),
    .io_perf_6_value                                  (io_perf_6_value),
    .io_perf_7_value                                  (io_perf_7_value),
    .boreChildrenBd_bore_array                        (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all                          (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req                          (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack                          (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen                      (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be                           (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr                         (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata                       (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen                       (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd                      (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata                      (boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_array                      (boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all                        (boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req                        (boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_ack                        (boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_writeen                    (boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be                         (boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr                       (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata                     (boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen                     (boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd                    (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_outdata                    (boreChildrenBd_bore_1_outdata),
    .sigFromSrams_bore_ram_hold                       (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass                     (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken                   (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk                    (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp                   (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold                   (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen                           (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold                     (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass                   (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken                 (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk                  (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp                 (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold                 (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                         (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold                     (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass                   (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken                 (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk                  (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp                 (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold                 (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                         (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold                     (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass                   (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken                 (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk                  (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp                 (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold                 (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                         (sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold                     (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass                   (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken                 (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk                  (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp                 (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold                 (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                         (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold                     (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass                   (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken                 (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk                  (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp                 (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold                 (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                         (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold                     (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass                   (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken                 (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk                  (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp                 (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold                 (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                         (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold                     (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass                   (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken                 (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk                  (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp                 (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold                 (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                         (sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold                     (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass                   (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken                 (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk                  (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp                 (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold                 (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen                         (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold                     (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass                   (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken                 (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk                  (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp                 (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold                 (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen                         (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold                    (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass                  (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken                (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk                 (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp                (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold                (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen                        (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold                    (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass                  (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken                (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk                 (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp                (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold                (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen                        (sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold                    (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass                  (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken                (sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk                 (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp                (sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold                (sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen                        (sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold                    (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass                  (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken                (sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk                 (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp                (sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold                (sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen                        (sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold                    (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass                  (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken                (sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk                 (sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp                (sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold                (sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen                        (sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold                    (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass                  (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken                (sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk                 (sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp                (sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold                (sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen                        (sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold                    (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass                  (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken                (sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk                 (sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp                (sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold                (sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen                        (sigFromSrams_bore_16_cgen),
    .cg_bore_cgen                                     (cg_bore_cgen)
  );

endmodule

