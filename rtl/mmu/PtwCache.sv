// PtwCache.sv —— L2 TLB 页表缓存（Page Table Cache）：把已走过的页表项缓存下来，
// 让下一次同前缀的地址翻译少走几级 memory walk。
//
// 本文件含：xs_ptwcache_pkg（几何与类型）+ xs_PtwCache_core（可读重写核）+
// PtwCache（golden 同名 wrapper，455 端口透传）。
// 对应 Chisel: xiangshan.cache.mmu.PtwCache（PageTableCache.scala）；
// 对照 golden = G1-canonical/golden-rtl/PtwCache.sv（45,308 行，单变体）。
//
// ★状态（2026-09-21）：455 个端口里的全部 236 个输出都已从 golden 逐条追出方程，
//  「未追清清单」已清空，钉 0 占位一根不剩（生成器实测，不是声明）。
//  ★但"有驱动"不等于"驱动得对"★：对不对由 verif/ut/PtwCache 的双例化逐拍对照
//  （两档 initreg × 3 seed × 200k 拍，每拍 3347 次比较，errors=0）和 FM 来判。
//  ★FM 本轮没跑完★（match 阶段不收敛，详见 docs/fm_predictions/PtwCache.md），
//  所以本文件目前**没有**形式等价证明背书 —— 只有仿真侧的证据。
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
// 【差分 UT —— 已实现，在 verif/ut/PtwCache/】
//   tb 里同时例化 golden PtwCache 与本核的派生副本 PtwCache_xs，同拍同激励，
//   逐拍比 455 根端口里的全部 236 个输出 **加上** 约 5000 根核内状态。
//   seed 1/7/42，每 seed 200k 拍，两档 initreg 都跑，errors=0。
//   ★本模块有三处必须专门设计激励，否则 errors=0 没有意义★：
//     1. 不复位寄存器占 2749/4892，两档 initreg 都要跑。
//        ★档位取 +0 与 +1，**不许用 +random**★：双例化时 random 给两个实例
//        各摇各的初值，比出来的差异跟重写无关（L2TLB lane 实测）。
//        又：编译期只能给 +vcs+initreg+random（那只是打开机制），
//        档位在运行期用 +vcs+initreg+0/+1 选 —— 编译期给 +0 会被 VCS 判废弃选项。
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
//   （M4 已在 tb 头注释里以 H4 的名字实测过：errors=74774，抓到。）
//
// 【追清到哪了 —— 全部追清，逐节列出】
//   已追清并写成 RTL：
//     · 四级流水握手与入口节流、三份 dup 的 flush 与归属、复位域划分、
//       两个 ClockGate 的开门条件、l1/l0 的 SRAM 读地址与读使能、全部 MBIST/DFT 拓扑；
//     · l1/l0 的**全部写数据**（§6.1 的 10 个 PTE 谓词 + §6.2 的逐项字段）；
//     · 五级替换策略与受害者选择（§7：PseudoLRU 取路/更新 + replaceWrapper，
//       含 golden 那个"l3 回填污染 l2 PLRU"的真 bug）；
//     · 各级回填使能与回填侧状态更新（§9/§11：l3/l2/sp 表项载荷、l3v..spv 置位、
//       l3g..spg、五级 h、l1/l0 的 XORFold 影子哈希）；
//     · 流水载荷三级打拍与两个 1 拍脉冲（§12）；
//     · ★五级命中判定（§14/§15/§16）★——l3/l2 的 hitVec + DataHoldBypass，
//       sp 的 allType 比较（level_match + napot）与 bitmap 门，
//       l1/l0 的 SRAM 两拍命中（v/h/g 向量在发读那一拍锁存、数据 DataHoldBypass），
//       以及命中侧的 PLRU access。
//   验证：verif/ut/PtwCache 双例化逐拍比 golden 端口表逐根量出的**全部 236 个输出**
//     加上约 3100 根核内状态（回填 / 命中 / 栅栏 / bitmap / wakeup），
//     ★两档 initreg（运行期 +0 与 +1）× 3 seed × 200k 拍，errors 全为 0★。
//     tb 自己判"五级回填、五级命中、三种栅栏、bitmap wakeup 的写、l1 两路同时命中
//     都必须至少触发一次"，任何一项为 0 就判 FAIL（"那一段等于什么都没比"）；
//     注入过的 mutant 与各自的 errors 数记在 tb 头注释里。
//     · ★响应装配（§17-§19）★——refill bypass 的三级"当拍匹配 + 跨拍记忆"、
//       stageResp 的命中结果快照 resp_res、io.resp 的 220 根载荷（含 stage1 的
//       8 条相邻 PTE、toFsm/toHptw 两个出口、bitmapCheck 的 ptes/cfs）；
//     · ★perf（§20）★——8 个事件各打两拍再零扩展到 6 位；
//     · ★sfence / hfence.vvma / hfence.gvma 的失效掩码（§21）★——
//       三种栅栏 × rs1/rs2 四档 × 五级，含 sp 的 allType hit 展开；
//     · ★l0_bitmap 的写侧与 bitmap wakeup 的三拍流水（§22）★。
//   ★golden 里没有 ecc flush★：KunminghuV2Config 下 l2tlbParams.enablePTWECC=false，
//   eccError 恒 0，整段被 firtool 消光（golden 45308 行里 grep 不到一个 "ecc"）。
//   所以"不写"就是照抄，不是缺口 —— 这条以前被误记在未追清清单里。
//
// 【两条 X 语义的坑（都是实测逼出来的，别改回去）】
//   重写与 golden 在 0/1 上同值、在 X 上不同，就等于把一批拍上的比对**静默关掉**。
//   本模块的 l0/l1 载荷来自 SRAM，未写过的行在 +define+SYNTHESIS 下就是 X，
//   所以这两处不是理论问题：
//     1. 选择：`always_comb` 里的 `if (hitvec[w]) sel = ...` 是 X-乐观的
//        （过程式 `if (X)` 按假走），而 golden 的三目树会吐 X。全部写成三目形。
//        实测：改之前 20k 拍里这一处贡献 275 个 golden=X / impl=定值 的失配。
//     2. 写使能：`if (写) reg <= 值` 同样 X-乐观，而 firtool 展开的是
//        `next = ~清零 & (写? 值 : 旧值)` 这个每拍都算的表达式。l0_bitmap 照这个形状写。
// 本文件导航（共 6494 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L59    它在 MMU 里的位置
//   L66    五级存储
//   L79    四级流水
//   L89    三份 dup 各归谁 —— 照抄，绝不合并
//   L98    复位域 —— golden 实测，别照直觉全复位
//   L108   子模块
//   L115   golden 45,308 行里有多少是真逻辑
//   L122   差分 UT —— 已实现，在 verif/ut/PtwCache/
//   L145   追清到哪了 —— 全部追清，逐节列出
//   L176   两条 X 语义的坑
//   L187   xs_ptwcache_pkg —— 几何、类型与编码
//   L841   §1 四级流水与反压
//   L886   §2 三份 dup 的归属与 flush
//   L917   §3 存储声明
//   L958   §4 复位域
//   L969   §5 时钟门控与 SRAM 端口仲裁
//   L1002  §6 各级 refill 使能
//   L1012  §7 替换策略状态
//   L1031  §6.1 PTE 谓词
//   L1145  §6.2 回填写数据
//   L1239  §7.1 PseudoLRU —— 位布局与两个方程
//   L1296  §7.2 replaceWrapper —— 「有空位先填空位，满了才问 PLRU」
//   L1325  §7.3 受害者选择
//   L1368  §9 各级回填使能与回填载荷
//   L1439  §9.1 XORFold —— 影子元数据存的是折叠哈希，不是原值
//   L2052  §12 流水载荷与两个 1 拍脉冲
//   L2099  §13 命中判定的两个公共写法
//   L2138  §14 l3 / l2 命中
//   L2251  §15 sp 命中的取数
//   L2306  §16 l1 / l0 命中
//   L2464  §16.1 命中选数 —— stageCheck 级把"命中那一路"的字段挑出来
//   L2953  §17 refill bypass —— "你要的那条，这一拍正好在回填路上"
//   L3028  §18 stageResp 的命中结果快照 resp_res
//   L3040  §19 io.resp 装配
//   L3514  §20 perf 事件
//   L3543  §21 sfence / hfence 失效
//   L3725  §21.1 五级的失效掩码 —— "这一拍要把哪些位从 v 向量里打掉"
//   L3804  §22 bitmap wakeup —— 上层查完 bitmap 回来"补票"
//   L3875  §11 时序：两个 always_ff，复位域划分照抄 golden
//   L4192  §8 追清进度台账
//   L4209  §9 子模块例化
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

  // l1 / l0 的一条表项（SRAM 里的一行）：整行 8 个 PTE 共享 tag/asid/vmid/prefetch，
  // 每个 PTE 自己带 pbmt/ppn/vs（有效）。l0 还多一份 onlypf 与完整 perm（它存叶子）。
  // ★vs 是"本条 PTE 有效"，与 l1v/l0v 的"本路表项有效"是两回事，命中要同时满足★
  typedef struct packed {
    logic [L1_TAG_W-1:0]            tag;
    logic [ASID_W-1:0]              asid;
    logic [VMID_W-1:0]              vmid;
    logic [SECTOR_N-1:0][1:0]       pbmts;
    logic [SECTOR_N-1:0][PPN_W-1:0] ppns;
    logic [SECTOR_N-1:0]            vs;
    logic                           prefetch;
  } l1_line_t;

  // l1/l0 在 stageCheck 级留下的那一份（ramDatas）：★只留下游真用得到的字段★。
  // golden 里 l1 的 ramDatas 没有 tag/asid/vmid/vs —— 命中判定在上一级就做完了，
  // 这一级只需要选数用的 ppn/pbmt/prefetch（l0 还多 onlypf 与 perm）。
  // 把整行都留下来会凭空多出一批永远没人读的寄存器，FM 上就是 unread 点。
  typedef struct packed {
    logic [SECTOR_N-1:0][1:0]       pbmts;
    logic [SECTOR_N-1:0][PPN_W-1:0] ppns;
    logic                           prefetch;
  } l1_ram_t;

  typedef struct packed {
    logic [SECTOR_N-1:0][1:0]       pbmts;
    logic [SECTOR_N-1:0][PPN_W-1:0] ppns;
    logic [SECTOR_N-1:0]            onlypf;
    pte_perm_t [SECTOR_N-1:0]       perms;
    logic                           prefetch;
  } l0_ram_t;

  // sp 命中后真正被下游用到的字段（★没有 tag/asid/vmid★：它们在 golden 里
  // 从来到不了输出，firtool 把那三个寄存器消掉了，这里照抄"不存"）。
  typedef struct packed {
    logic            n;
    logic [1:0]      pbmt;
    logic [PPN_W-1:0] ppn;
    pte_perm_t       perm;
    logic [1:0]      level;
    logic            v;
    logic            prefetch;
  } sp_hit_t;

  typedef struct packed {
    logic [L0_TAG_W-1:0]            tag;
    logic [ASID_W-1:0]              asid;
    logic [VMID_W-1:0]              vmid;
    logic [SECTOR_N-1:0][1:0]       pbmts;
    logic [SECTOR_N-1:0][PPN_W-1:0] ppns;
    logic [SECTOR_N-1:0]            vs;
    logic [SECTOR_N-1:0]            onlypf;
    pte_perm_t [SECTOR_N-1:0]       perms;
    logic                           prefetch;
  } l0_line_t;


  // ---- §17 用：stageCheck -> stageResp 之间那一拍的命中结果快照（golden resp_res）----
  //  ★只留 golden 真的存了的字段★：l3 没有 pbmt，l0 没有 level，sp 没有 tag/asid/vmid，
  //  都是 firtool 顺着"到不了输出"消掉的。多存一个字段在 FM 上就是一个 unread 点。
  typedef struct packed {
    logic             hit;
    logic             pre;
    logic [PPN_W-1:0] ppn;
  } res_l3_t;

  typedef struct packed {
    logic             hit;
    logic             pre;
    logic [PPN_W-1:0] ppn;
    logic [1:0]       pbmt;
  } res_l12_t;

  // l0 一次命中带回整行 8 个 PTE（tlbcontiguous），下游 TLB 一次填 8 条。
  typedef struct packed {
    logic                           hit;
    logic                           pre;
    logic [SECTOR_N-1:0][PPN_W-1:0] ppn;
    logic [SECTOR_N-1:0][1:0]       pbmt;
    pte_perm_t [SECTOR_N-1:0]       perm;
    logic [SECTOR_N-1:0]            v;        // = ~onlypf，"这条不是注定 pf"
    logic                           jmp_bitmap_check;
    logic [L0_WAYS-1:0]             hitway;   // one-hot，给 bitmap wakeup 回来时定位
    logic [SECTOR_N-1:0][63:0]      ptes;     // 重新拼回 RISC-V PTE 格式，给 bitmap 检查用
    logic [SECTOR_N-1:0]            cfs;      // Bitmap Check Failed：该条 bitmap 还没过
  } res_l0_t;

  typedef struct packed {
    logic             hit;
    logic             pre;
    logic [PPN_W-1:0] ppn;
    logic [1:0]       pbmt;
    pte_perm_t        perm;
    logic             n;
    logic [1:0]       level;
    logic             v;
    logic             jmp_bitmap_check;
    logic [63:0]      pte;
  } res_sp_t;

  // bitmap wakeup 回读 l0 时只需要比对用的那几根（golden 实测只留了这些寄存器：
  // tag/asid/vmid/vs/perms.g —— ppn、pbmt、onlypf、其余 perm 位一个都没留）。
  typedef struct packed {
    logic [L0_TAG_W-1:0] tag;
    logic [ASID_W-1:0]   asid;
    logic [VMID_W-1:0]   vmid;
    logic [SECTOR_N-1:0] vs;
    logic [SECTOR_N-1:0] g;
  } l0_wake_t;

  // 查找/回填两侧共用的 h 折叠：allStage(3) 折成 onlyStage1(1)，其余原样。
  // （golden 把这同一个折法在 h_search / delay_h / refill_h / refill_bypass 四处各展开一次。）
  function automatic logic [1:0] fold_h(input logic [1:0] s2x);
    return (s2x == H_ONLY_STAGE2) ? H_ONLY_STAGE2
                                  : {1'b0, (s2x == H_ONLY_STAGE1) | (&s2x)};
  endfunction

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
  // §3 存储声明（更新方程见 §11 的两个 always_ff）
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
  // §7 替换策略状态（PLRU 方程见 §7.1）
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
    // verif/ut/PtwCache）。**仍然照抄不删** —— 值恒等不等于可证等价，
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

  // SRAM 读回的扁平线（golden 的端口名，逐根抄）——
  // 命中判定读的是下面 §16 打包出来的 l1_line_t / l0_line_t。
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

  // ---------------------------------------------------------------------------
  // §12 流水载荷与两个 1 拍脉冲（已追清：golden:3087-3129 / 30764-30771 / 31216 / 31240）
  //
  //  §1 只搬了三级 valid；载荷（vpn / s2xlate / source / isFirst / isHptwReq / hptwId）
  //  另有三套寄存器，各在自己那一级的 fire 上打拍：
  //     stageDelay 级载荷 delay_*  <= io.req.bits   @ left_fire_req
  //     stageCheck 级载荷 check_*  <= delay_*       @ left_fire_delay
  //     stageResp  级载荷 resp_*   <= check_*       @ left_fire_check
  //  ★两个 1 拍脉冲不是 valid★：它们是"这一拍有新数据进到该级"的选通，
  //  给 DataHoldBypass / RegEnable 当使能，且各自都被 flush_dup_0 清掉。
  logic [VPN_W-1:0]    delay_vpn,  check_vpn,  resp_vpn;
  logic [1:0]          delay_s2x,  check_s2x,  resp_s2x;
  logic [1:0]          delay_src,  check_src,  resp_src;
  logic                delay_isfirst, check_isfirst, resp_isfirst;
  logic                delay_ishptw,  check_ishptw,  resp_ishptw;
  logic [HPTWID_W-1:0] delay_hptwid,  check_hptwid,  resp_hptwid;

  logic stage_delay_valid_1cycle;   // golden stageDelay_valid_1cycle
  logic stage_check_valid_1cycle;   // golden stageCheck_valid_1cycle

  always_ff @(posedge clock) begin
    if (left_fire_req) begin
      delay_vpn     <= io_req_bits_req_info_vpn;
      delay_s2x     <= io_req_bits_req_info_s2xlate;
      delay_src     <= io_req_bits_req_info_source;
      delay_isfirst <= io_req_bits_isFirst;
      delay_ishptw  <= io_req_bits_isHptwReq;
      delay_hptwid  <= io_req_bits_hptwId;
    end
    if (left_fire_delay) begin
      check_vpn     <= delay_vpn;
      check_s2x     <= delay_s2x;
      check_src     <= delay_src;
      check_isfirst <= delay_isfirst;
      check_ishptw  <= delay_ishptw;
      check_hptwid  <= delay_hptwid;
    end
    if (left_fire_check) begin
      resp_vpn     <= check_vpn;
      resp_s2x     <= check_s2x;
      resp_src     <= check_src;
      resp_isfirst <= check_isfirst;
      resp_ishptw  <= check_ishptw;
      resp_hptwid  <= check_hptwid;
    end
  end

  // ---------------------------------------------------------------------------
  // §13 命中判定的两个公共写法（已追清：golden:13205-13218 / _hitPPN_T_29）
  //
  //  ParallelOR / ParallelPriorityMux / OHToUInt 在 golden 里被展成平衡树，
  //  这里写成循环。★两条 tie-break 必须照抄★：
  //    · ParallelPriorityMux 一个都不命中时返回**最后一项**（不是 0）；
  //    · l3/l2/sp 的 PLRU access 用 OHToUInt（按位或），
  //      l1/l0 用 ParallelPriorityMux（最低命中位优先）—— 两者只在非 one-hot 时不同。
  function automatic logic [3:0] oh_to_uint16(input logic [15:0] oh);
    logic [3:0] r;
    for (int b = 0; b < 4; b++) begin
      r[b] = 1'b0;
      for (int i = 0; i < 16; i++)
        if (i[b]) r[b] |= oh[i];
    end
    return r;
  endfunction

  // sp 的 allType tag 比较（PtwEntry.hit 的 allType 分支）：按 level 决定比到第几段。
  //   level 3(512G) 只比最高段；2(1G) 比两段；1(2M) 比三段；0(4K/napot) 四段全比。
  //   ★napot 条目的最低段只比 vpn[8:4]★——Svnapot 一条覆盖 16 个 4K 页。
  //   ★查找侧与 sfence 侧共用同一个函数★：两处写两遍是 sfence 失效集合出错的经典来源。
  //  ★表项整条当参数传进来，不在函数体里直接读 sp_entry★：函数体引用模块级信号
  //  会让 Formality 报 FMR_VLOG-091（"non-local variable ... may cause a simulation
  //  and synthesis mismatch"），进而汇总成 FM-089。那不是噪声——它说的是综合与仿真
  //  对函数里的非局部引用理解可能不同。修法是把依赖写进参数表，不是去关警告。
  function automatic logic sp_level_match(input sp_entry_t e,
                                          input logic [VPN_W-1:0] vpn);
    logic tm0, tm1, tm2, tm3;
    tm0 = e.n ? (e.tag[8:4]  == vpn[8:4])
              : (e.tag[8:0]  == vpn[8:0]);
    tm1 =        e.tag[17:9]  == vpn[17:9];
    tm2 =        e.tag[26:18] == vpn[26:18];
    tm3 =        e.tag[37:27] == vpn[37:27];
    return (e.level == 2'd0) ? (tm3 & tm2 & tm1 & tm0)
         : (e.level == 2'd1) ? (tm3 & tm2 & tm1)
         : (((e.level != 2'd2) | tm2) & tm3);
  endfunction

  // ---------------------------------------------------------------------------
  // §14 l3 / l2 命中（寄存器阵列，stageReq 发起、stageDelay 定型）
  //
  //  PtwEntry.hit 展开（golden:33485 / 33565）：
  //    asid_hit = ~(~g[i] & ~onlyS2) | (asid[i] == asid_value)   // g 位 ⇒ 忽略 asid
  //    vmid_hit = ~(|h_search)      | ({2'h0, vmid[i]} == hgatp_vmid)
  //    ★vmid 比较是 16 位零扩展★：存的是 14 位，但要求 hgatp_vmid[15:14]==0 才算命中。
  //    再与 tag 相等、v[i]、h[i]==h_search 相与。
  //  三个"取数"信号走 DataHoldBypass（stage_delay_valid_1cycle 时取新值，否则保持），
  //  再在 stageDelay 出口 RegEnable 一次，与 l1/l0 对齐到 stageCheck。
  //
  //  ★l3 没有 pbmt★：golden 里 l3 表项根本没有 pbmt 寄存器 —— 响应侧的 pbmt
  //  在 l1 不命中时直接取 l2 的，l3 那一路的 pbmt 从来到不了输出，被 firtool 消掉了。
  //  这里照抄"不存"，不要补一个出来。
  logic [ASID_W-1:0] search_asid_dup2, search_asid_dup0;
  assign search_asid_dup2 = (|h_search) ? io_csr_dup_2_vsatp_asid : io_csr_dup_2_satp_asid;
  assign search_asid_dup0 = (|h_search) ? io_csr_dup_0_vsatp_asid : io_csr_dup_0_satp_asid;

  logic onlyS2;
  assign onlyS2 = (h_search == H_ONLY_STAGE2);

  logic [L3_N-1:0] l3_hitvec;      // 在 stageReq fire 那一拍锁存
  logic [L2_N-1:0] l2_hitvec;
  logic [SP_N-1:0] sp_hitvec;

  always_ff @(posedge clock) begin
    if (sram_read_fire) begin
      for (int i = 0; i < L3_N; i++)
        l3_hitvec[i] <=
            (~(~l3g[i] & ~onlyS2) | (l3_entry[i].asid == search_asid_dup2))
          & (~(|h_search) | ({2'h0, l3_entry[i].vmid} == io_csr_dup_2_hgatp_vmid))
          & (l3_entry[i].tag == io_req_bits_req_info_vpn[37:27])
          & l3v[i] & (h_search == l3h[i]);
      for (int i = 0; i < L2_N; i++)
        l2_hitvec[i] <=
            (~(~l2g[i] & ~onlyS2) | (l2_entry[i].asid == search_asid_dup2))
          & (~(|h_search) | ({2'h0, l2_entry[i].vmid} == io_csr_dup_2_hgatp_vmid))
          & (l2_entry[i].tag == io_req_bits_req_info_vpn[37:18])
          & l2v[i] & (h_search == l2h[i]);
      // sp 是 allType 比较：先按 level 决定要比到第几段 tag，napot 再改写最低那段。
      for (int i = 0; i < SP_N; i++)
        sp_hitvec[i] <=
            (onlyS2 | (sp_entry[i].asid == search_asid_dup0) | sp_entry[i].perm.g)
          & (~(|h_search) | ({2'h0, sp_entry[i].vmid} == io_csr_dup_0_hgatp_vmid))
          & sp_level_match(sp_entry[i], io_req_bits_req_info_vpn)
          & spv[i] & (sph[i] == h_search);
    end
  end

  // 三级的取数（组合）+ DataHoldBypass 的保持寄存器
  logic             l3_hit_c,  l2_hit_c,  sp_hit_c;
  logic [PPN_W-1:0] l3_ppn_c,  l2_ppn_c;
  logic [1:0]       l2_pbmt_c;
  logic             l3_pre_c,  l2_pre_c,  sp_pre_c;

  always_comb begin
    l3_hit_c = |l3_hitvec;
    l2_hit_c = |l2_hitvec;
    // ★一个都不命中时取最后一项★（ParallelPriorityMux 的 tie-break，照抄）。
    // ★用三目而不是 `if`★：同 §16 的理由，`if (X)` 按假走会把 X 吃掉。
    l3_ppn_c = l3_entry[L3_N-1].ppn;
    l3_pre_c = l3_entry[L3_N-1].prefetch;
    for (int i = L3_N-2; i >= 0; i--) begin
      l3_ppn_c = l3_hitvec[i] ? l3_entry[i].ppn      : l3_ppn_c;
      l3_pre_c = l3_hitvec[i] ? l3_entry[i].prefetch : l3_pre_c;
    end
    l2_ppn_c  = l2_entry[L2_N-1].ppn;
    l2_pbmt_c = l2_entry[L2_N-1].pbmt;
    l2_pre_c  = l2_entry[L2_N-1].prefetch;
    for (int i = L2_N-2; i >= 0; i--) begin
      l2_ppn_c  = l2_hitvec[i] ? l2_entry[i].ppn      : l2_ppn_c;
      l2_pbmt_c = l2_hitvec[i] ? l2_entry[i].pbmt     : l2_pbmt_c;
      l2_pre_c  = l2_hitvec[i] ? l2_entry[i].prefetch : l2_pre_c;
    end
  end

  logic             l3_hit_r,  l2_hit_r;
  logic [PPN_W-1:0] l3_ppn_r,  l2_ppn_r;
  logic [1:0]       l2_pbmt_r;
  logic             l3_pre_r,  l2_pre_r;

  logic             l3_hit_h,  l2_hit_h;
  logic [PPN_W-1:0] l3_ppn_h,  l2_ppn_h;
  logic [1:0]       l2_pbmt_h;
  logic             l3_pre_h,  l2_pre_h;

  assign l3_hit_h  = stage_delay_valid_1cycle ? l3_hit_c  : l3_hit_r;
  assign l3_ppn_h  = stage_delay_valid_1cycle ? l3_ppn_c  : l3_ppn_r;
  assign l3_pre_h  = stage_delay_valid_1cycle ? l3_pre_c  : l3_pre_r;
  assign l2_hit_h  = stage_delay_valid_1cycle ? l2_hit_c  : l2_hit_r;
  assign l2_ppn_h  = stage_delay_valid_1cycle ? l2_ppn_c  : l2_ppn_r;
  assign l2_pbmt_h = stage_delay_valid_1cycle ? l2_pbmt_c : l2_pbmt_r;
  assign l2_pre_h  = stage_delay_valid_1cycle ? l2_pre_c  : l2_pre_r;

  // 与 l1/l0 对齐到 stageCheck 的一拍（golden l3Hit_r / l2Hit / …）
  logic             l3_hit_ck, l2_hit_ck;
  logic [PPN_W-1:0] l3_ppn_ck, l2_ppn_ck;
  logic [1:0]       l2_pbmt_ck;
  logic             l3_pre_ck, l2_pre_ck;

  always_ff @(posedge clock) begin
    if (stage_delay_valid_1cycle) begin
      l3_hit_r <= l3_hit_c;  l3_ppn_r <= l3_ppn_c;  l3_pre_r <= l3_pre_c;
      l2_hit_r <= l2_hit_c;  l2_ppn_r <= l2_ppn_c;  l2_pre_r <= l2_pre_c;
      l2_pbmt_r <= l2_pbmt_c;
    end
    if (left_fire_delay) begin
      l3_hit_ck <= l3_hit_h;  l3_ppn_ck <= l3_ppn_h;  l3_pre_ck <= l3_pre_h;
      l2_hit_ck <= l2_hit_h;  l2_ppn_ck <= l2_ppn_h;  l2_pre_ck <= l2_pre_h;
      l2_pbmt_ck <= l2_pbmt_h;
    end
  end

  // ---------------------------------------------------------------------------
  // §15 sp 命中的取数（golden:6141-6155）
  //
  //  ★sp 与 l3/l2 的形状不同：它**没有** DataHoldBypass★——hitVec 锁存之后，
  //  取数与 hit 都是纯组合，直接在 stageDelay 出口 RegEnable 一次。
  //  照抄这个差别：多补一级保持寄存器在仿真里大多数拍同值，但 FM 上是两棵不同的锥。
  //
  //  sp 的 hit 还带 bitmap 门：BME 打开、不是 allStage 的非 hptw 请求、且命中项 v=1 时，
  //  hit 直接判 0，改走 jmp_bitmap_check 让上层去查 bitmap。
  sp_hit_t sp_hitdata_c, sp_hitdata_ck;
  logic    sp_hit_or, sp_jmp_bitmap_c, sp_bitmap_gate;
  logic    sp_hit_ck, sp_pre_ck, sp_valid_ck, sp_jmp_bitmap_ck;
  logic    sp_ishptw_delay;
  logic [1:0] sp_s2x_delay;

  // 同上：整条当参数传，函数体只碰局部量。
  function automatic sp_hit_t sp_pick(input sp_entry_t e);
    sp_pick.n        = e.n;
    sp_pick.pbmt     = e.pbmt;
    sp_pick.ppn      = e.ppn;
    sp_pick.perm     = e.perm;
    sp_pick.level    = e.level;
    sp_pick.v        = e.v;
    sp_pick.prefetch = e.prefetch;
  endfunction

  always_comb begin
    // ★一个都不命中时取最后一项★（ParallelPriorityMux 的 tie-break）。
    // ★三目而不是 `if`★：同 §16，别把 X 吃掉。
    sp_hitdata_c = sp_pick(sp_entry[SP_N-1]);
    for (int i = SP_N-2; i >= 0; i--)
      sp_hitdata_c = sp_hitvec[i] ? sp_pick(sp_entry[i]) : sp_hitdata_c;
  end

  assign sp_hit_or       = |sp_hitvec;
  assign sp_bitmap_gate  = bitmap_enable & ((sp_s2x_delay != H_ALL_STAGE) | sp_ishptw_delay)
                         & sp_hitdata_c.v;
  assign sp_hit_c        = sp_bitmap_gate ? 1'b0 : sp_hit_or;
  assign sp_jmp_bitmap_c = sp_bitmap_gate & sp_hit_or;
  assign sp_pre_c        = sp_hitdata_c.prefetch;

  always_ff @(posedge clock) begin
    if (sram_read_fire) begin
      sp_ishptw_delay <= io_req_bits_isHptwReq;
      sp_s2x_delay    <= io_req_bits_req_info_s2xlate;
    end
    if (left_fire_delay) begin
      sp_hit_ck        <= sp_hit_c;
      sp_hitdata_ck    <= sp_hitdata_c;
      sp_pre_ck        <= sp_hitdata_c.prefetch;
      sp_valid_ck      <= sp_hitdata_c.v;
      sp_jmp_bitmap_ck <= sp_jmp_bitmap_c;
    end
  end

  // ---------------------------------------------------------------------------
  // §16 l1 / l0 命中（SRAM 两拍：stageDelay 组合判、stageCheck 锁存）
  //
  //  与 l3/l2 的关键差别：载荷在 SRAM 里，一拍才回来，所以
  //    · 比较用的 v/h/g 向量在**发读请求**那一拍就得锁下来（vVec_delay 等）；
  //    · SRAM 回读数据走 DataHoldBypass（stage_delay_valid_1cycle 取新值，否则保持）；
  //    · hitVec 在 stageDelay 出口锁存，命中选数在 stageCheck 用。
  //  PtwEntries.hit 与 PtwEntry.hit 不是同一个函数（golden:34041 / 35369）：
  //    asid_hit = ignoreID | (delay_h == onlyStage2) | (asid == asid_value) | is_global
  //      ★l1 的 ignoreID 是本路的 g 位，l0 没有 ignoreID，改用**本条 PTE 的 perm.g**★
  //    vmid_hit = ~(|delay_h) | ({2'h0, vmid} == hgatp_vmid)
  //    再与 tag 相等、以及**本条 PTE 的 vs 位**（不是整条表项的 v）相与。
  l1_line_t l1_sram_rdata [L1_WAYS];
  l0_line_t l0_sram_rdata [L0_WAYS];

  logic [L1_WAYS-1:0] l1_vvec_delay, l1_gvec_delay;
  logic [L0_WAYS-1:0] l0_vvec_delay;
  logic [1:0]         l1_hvec_delay [L1_WAYS];
  logic [1:0]         l0_hvec_delay [L0_WAYS];

  // bitmap 读路径的两级寄存器（与 SRAM 数据同步）
  logic [SECTOR_N-1:0] l0_bitmap_delay [L0_WAYS];
  logic [SECTOR_N-1:0] l0_bitmap_ck    [L0_WAYS];

  // ★l0 的 bitmap 门自己另存了一份 isHptwReq / s2xlate / vpn[2:0]★
  //  （golden 的 ishptw / s2x_info / pte_index）。它们与流水载荷 check_* 同值、
  //  同一个使能，看起来是三个多余的寄存器 —— 但 golden 里确实是**另外三个寄存器**，
  //  合并掉会让那三个 golden 比较点在 FM 上变成 unmatched。照抄这份冗余。
  logic       l0_ishptw;
  logic [1:0] l0_s2x;
  logic [2:0] l0_pte_idx;

  l1_line_t l1_resp_r [L1_WAYS];
  l0_line_t l0_resp_r [L0_WAYS];
  l1_line_t l1_resp_h [L1_WAYS];
  l0_line_t l0_resp_h [L0_WAYS];
  l1_ram_t  l1_ramdata [L1_WAYS];
  l0_ram_t  l0_ramdata [L0_WAYS];

  logic [1:0] delay_h;    // 查找 h，用 stageDelay 级的 s2xlate 折叠
  assign delay_h = (delay_s2x == H_ONLY_STAGE2)
                 ? H_ONLY_STAGE2
                 : {1'b0, (delay_s2x == H_ONLY_STAGE1) | (&delay_s2x)};

  for (genvar w = 0; w < L1_WAYS; w++) begin : g_l1_hold
    assign l1_resp_h[w] = stage_delay_valid_1cycle ? l1_sram_rdata[w] : l1_resp_r[w];
  end
  for (genvar w = 0; w < L0_WAYS; w++) begin : g_l0_hold
    assign l0_resp_h[w] = stage_delay_valid_1cycle ? l0_sram_rdata[w] : l0_resp_r[w];
  end

  logic [L1_WAYS-1:0] l1_hitvec_delay, l1_hitvec;
  logic [L0_WAYS-1:0] l0_hitvec_delay, l0_hitvec;

  always_comb begin
    for (int w = 0; w < L1_WAYS; w++) begin
      l1_hitvec_delay[w] =
          (l1_gvec_delay[w] | (delay_h == H_ONLY_STAGE2)
           | (l1_resp_h[w].asid == ((|delay_h) ? io_csr_dup_1_vsatp_asid
                                               : io_csr_dup_1_satp_asid)))
        & (~(|delay_h) | ({2'h0, l1_resp_h[w].vmid} == io_csr_dup_1_hgatp_vmid))
        & (l1_resp_h[w].tag == delay_vpn[37:14])
        & l1_resp_h[w].vs[delay_vpn[11:9]]
        & l1_vvec_delay[w] & (delay_h == l1_hvec_delay[w]);
    end
    for (int w = 0; w < L0_WAYS; w++) begin
      l0_hitvec_delay[w] =
          ((delay_h == H_ONLY_STAGE2)
           | (l0_resp_h[w].asid == ((|delay_h) ? io_csr_dup_0_vsatp_asid
                                               : io_csr_dup_0_satp_asid))
           | l0_resp_h[w].perms[delay_vpn[2:0]].g)
        & (~(|delay_h) | ({2'h0, l0_resp_h[w].vmid} == io_csr_dup_0_hgatp_vmid))
        & (l0_resp_h[w].tag == delay_vpn[37:9])
        & l0_resp_h[w].vs[delay_vpn[2:0]]
        & l0_vvec_delay[w] & (delay_h == l0_hvec_delay[w]);
    end
  end

  always_ff @(posedge clock) begin
    if (sram_read_fire) begin
      for (int w = 0; w < L1_WAYS; w++) begin
        l1_vvec_delay[w] <= l1v[2*io_req_bits_req_info_vpn[13:12] + w];
        l1_gvec_delay[w] <= l1g[2*io_req_bits_req_info_vpn[13:12] + w];
        l1_hvec_delay[w] <= l1h[io_req_bits_req_info_vpn[13:12]][w];
      end
      for (int w = 0; w < L0_WAYS; w++) begin
        l0_vvec_delay[w] <= l0v[4*io_req_bits_req_info_vpn[8:3] + w];
        l0_hvec_delay[w] <= l0h[io_req_bits_req_info_vpn[8:3]][w];
      end
      for (int w = 0; w < L0_WAYS; w++)
        l0_bitmap_delay[w] <= l0_bitmap[io_req_bits_req_info_vpn[8:3]][w];
    end
    if (stage_delay_valid_1cycle) begin
      for (int w = 0; w < L1_WAYS; w++) l1_resp_r[w] <= l1_sram_rdata[w];
      for (int w = 0; w < L0_WAYS; w++) l0_resp_r[w] <= l0_sram_rdata[w];
    end
    if (left_fire_delay) begin
      l0_ishptw  <= delay_ishptw;
      l0_s2x     <= delay_s2x;
      l0_pte_idx <= delay_vpn[2:0];
      for (int w = 0; w < L1_WAYS; w++) begin
        l1_ramdata[w].pbmts    <= l1_resp_h[w].pbmts;
        l1_ramdata[w].ppns     <= l1_resp_h[w].ppns;
        l1_ramdata[w].prefetch <= l1_resp_h[w].prefetch;
      end
      for (int w = 0; w < L0_WAYS; w++) begin
        l0_ramdata[w].pbmts    <= l0_resp_h[w].pbmts;
        l0_ramdata[w].ppns     <= l0_resp_h[w].ppns;
        l0_ramdata[w].onlypf   <= l0_resp_h[w].onlypf;
        l0_ramdata[w].perms    <= l0_resp_h[w].perms;
        l0_ramdata[w].prefetch <= l0_resp_h[w].prefetch;
      end
      l1_hitvec <= l1_hitvec_delay;
      l0_hitvec <= l0_hitvec_delay;
      for (int w = 0; w < L0_WAYS; w++) l0_bitmap_ck[w] <= l0_bitmap_delay[w];
    end
  end

  // 命中路号：★l1/l0 用 ParallelPriorityMux（最低命中位优先），一个不中时取最后一路★
  logic       l1_hit, l0_hit_raw, l0_hit;
  logic [1:0] l0_hitway;
  assign l1_hit     = |l1_hitvec;
  assign l0_hit_raw = |l0_hitvec;
  assign l0_hitway  = (l0_hitvec[0] | l0_hitvec[1]) ? {1'b0, ~l0_hitvec[0]}
                                                    : {1'b1, ~l0_hitvec[2]};

  // l0 命中还要过 bitmap：BME 打开、且不是 allStage 的非 hptw 请求、且这条不是 onlypf 时，
  // 必须本条 PTE 的 bitmap 已检查通过才算命中。
  // ★l0_bitmap 的写侧还没追清（§8）★——所以 l0_hit 只在 BME=0 时可信。
  l0_ram_t  l0_hitdata;
  logic     l0_hit_onlypf, l0_bitmap_ok;
  // ★写成 golden 的平衡三目树，不写成 `always_comb` 里的 `if (hitvec[w])`★。
  //  两者在 0/1 上同值，在 X 上**不同**：过程式 `if (X)` 按假走，于是 hitVec 带 X 时
  //  这里会稳稳地选出最后一路的**确定值**，而 golden 那棵三目树会老老实实吐 X。
  //  l0 的载荷来自 SRAM，未写过的行在 `+define+SYNTHESIS` 下就是 X —— 也就是说
  //  X-乐观的写法会让"命中向量算错"这类 bug 在这些拍上**按构造测不出来**。
  //  实测：改成本形状之前，20k 拍里这一处贡献 275 个 golden=X / impl=定值 的失配。
  assign l0_hitdata = (l0_hitvec[0] | l0_hitvec[1])
                    ? (l0_hitvec[0] ? l0_ramdata[0] : l0_ramdata[1])
                    : (l0_hitvec[2] ? l0_ramdata[2] : l0_ramdata[3]);
  assign l0_hit_onlypf = l0_hitdata.onlypf[l0_pte_idx];

  // ★选路与选位的顺序照抄 golden：先把同一条 PTE 的 4 路 bitmap 位聚成一个 4 宽向量，
  //  再用 hitWay 去索引★。反过来写（先按路取整条 8 位、再取位）在 0/1 上同值，
  //  但 hitWay 带 X 时两者不同 —— 实测这一处贡献了 cfs_6 的 5 个 golden=X/impl=1 失配。
  logic [L0_WAYS-1:0] l0_bitmap_by_pte [SECTOR_N];   // [第几条 PTE][第几路]
  logic [SECTOR_N-1:0] l0_bitmap_sel;                // 命中那一路的 8 位
  always_comb
    for (int k = 0; k < SECTOR_N; k++) begin
      for (int w = 0; w < L0_WAYS; w++) l0_bitmap_by_pte[k][w] = l0_bitmap_ck[w][k];
      l0_bitmap_sel[k] = l0_bitmap_by_pte[k][l0_hitway];
    end
  assign l0_bitmap_ok  = l0_bitmap_sel[l0_pte_idx];
  assign l0_hit = (bitmap_enable & ((l0_s2x != H_ALL_STAGE) | l0_ishptw)
                   & ~l0_hit_onlypf)
                ? (l0_hit_raw & l0_bitmap_ok)
                : l0_hit_raw;

  // ---------------------------------------------------------------------------
  // §16.1 命中选数 —— stageCheck 级把"命中那一路"的字段挑出来
  //       （已追清：golden:5790-5820 / 35851-35856 / 35940-36066）
  //
  //  五级的选法是同一条：ParallelPriorityMux(hitVec zip ways)，
  //  ★一路都不命中时取最后一路★（不是 0），与 §13 的 tie-break 同一条约定。
  //  l1 选完还要再按 vpn[11:9] 从 8 个 PDE 里挑一条；l0 则是整行 8 条全带走。
  l1_ram_t          l1_hitdata;
  logic [PPN_W-1:0] l1_hit_ppn;
  logic [1:0]       l1_hit_pbmt;
  logic             l1_pre;

  // 同 §16 的理由：三目形，不用过程式 if（l1 的载荷同样来自 SRAM，会有 X）。
  assign l1_hitdata = l1_hitvec[0] ? l1_ramdata[0] : l1_ramdata[1];
  assign l1_hit_ppn  = l1_hitdata.ppns [check_vpn[11:9]];
  assign l1_hit_pbmt = l1_hitdata.pbmts[check_vpn[11:9]];
  assign l1_pre      = l1_hitdata.prefetch;

  logic                l0_pre;
  logic [SECTOR_N-1:0] l0_valid;      // 逐条 PTE 的"不是 onlypf"
  logic [SECTOR_N-1:0] l0_cfs;        // 逐条 PTE 的"bitmap 还没过"
  logic [SECTOR_N-1:0][63:0] l0_ptes; // 逐条 PTE 重新拼回 RISC-V 格式
  logic [L0_WAYS-1:0]  l0_hitway_oh;
  logic                l0_jmp_bitmap;

  assign l0_pre       = l0_hitdata.prefetch;
  assign l0_hitway_oh = L0_WAYS'(1) << l0_hitway;

  // ★bitmap 门的三个出口共用同一组条件★（golden:36053-36055）：
  //   命中 -> 要 bitmap 通过才算 hit（§16 的 l0_hit）；
  //   命中但 bitmap 没过 -> jmp_bitmap_check，让上层去查 bitmap 再回来 wakeup；
  //   onlypf 的条目不查 bitmap（它注定 pf，没有物理页可查）。
  assign l0_jmp_bitmap = bitmap_enable
                       & ((l0_s2x != H_ALL_STAGE) | l0_ishptw)
                       & ~l0_hit_onlypf & l0_hit_raw & ~l0_bitmap_ok;

  // RISC-V PTE 位布局：[63]=N [62:61]=PBMT [60:54]=Reserved [53:10]=PPN
  //                    [9:8]=RSW [7:1]=D A G U X W R [0]=V
  //  这里 ppn 只有 38 位（gvpnLen），高 6 位补 0 —— 与 Reserved 的 7 位合成 13'h0。
  //  ★l0 的 N 位恒 0★：napot 的条目在回填时就被踢去 sp 了（§9），l0 里不会有。
  always_comb begin
    for (int i = 0; i < SECTOR_N; i++) begin
      l0_valid[i] = ~l0_hitdata.onlypf[i];
      l0_cfs[i]   = ~l0_bitmap_sel[i];
      l0_ptes[i]  = {1'b0, l0_hitdata.pbmts[i], 13'h0, l0_hitdata.ppns[i], 2'h0,
                     l0_hitdata.perms[i].d, l0_hitdata.perms[i].a,
                     l0_hitdata.perms[i].g, l0_hitdata.perms[i].u,
                     l0_hitdata.perms[i].x, l0_hitdata.perms[i].w,
                     l0_hitdata.perms[i].r, l0_valid[i]};
    end
  end

  // sp 命中的那一条也拼成 PTE 格式（sp 的 N 位是真的，可能是 Svnapot 大页）。
  logic [63:0] sp_pte;
  assign sp_pte = {sp_hitdata_ck.n, sp_hitdata_ck.pbmt, 13'h0, sp_hitdata_ck.ppn, 2'h0,
                   sp_hitdata_ck.perm.d, sp_hitdata_ck.perm.a, sp_hitdata_ck.perm.g,
                   sp_hitdata_ck.perm.u, sp_hitdata_ck.perm.x, sp_hitdata_ck.perm.w,
                   sp_hitdata_ck.perm.r, sp_hitdata_ck.v};
  // ★V 位取的是 sp_hitdata_ck.v（表项里那份），不是并排那个 sp_valid_ck 寄存器★——
  //  两者同值，但 golden 里是两个不同的寄存器，拼 PTE 用的是前者。照抄出处。

  // BEGIN GENERATED(sram_rdata_pack)
  // 把 SRAM 回读的扁平线打包成 §16 用的 struct（纯改名，无逻辑）。
  assign l0_sram_rdata[0].asid                    = l0_rdata_0_asid;
  assign l0_sram_rdata[0].onlypf[0]               = l0_rdata_0_onlypf_0;
  assign l0_sram_rdata[0].onlypf[1]               = l0_rdata_0_onlypf_1;
  assign l0_sram_rdata[0].onlypf[2]               = l0_rdata_0_onlypf_2;
  assign l0_sram_rdata[0].onlypf[3]               = l0_rdata_0_onlypf_3;
  assign l0_sram_rdata[0].onlypf[4]               = l0_rdata_0_onlypf_4;
  assign l0_sram_rdata[0].onlypf[5]               = l0_rdata_0_onlypf_5;
  assign l0_sram_rdata[0].onlypf[6]               = l0_rdata_0_onlypf_6;
  assign l0_sram_rdata[0].onlypf[7]               = l0_rdata_0_onlypf_7;
  assign l0_sram_rdata[0].pbmts[0]                = l0_rdata_0_pbmts_0;
  assign l0_sram_rdata[0].pbmts[1]                = l0_rdata_0_pbmts_1;
  assign l0_sram_rdata[0].pbmts[2]                = l0_rdata_0_pbmts_2;
  assign l0_sram_rdata[0].pbmts[3]                = l0_rdata_0_pbmts_3;
  assign l0_sram_rdata[0].pbmts[4]                = l0_rdata_0_pbmts_4;
  assign l0_sram_rdata[0].pbmts[5]                = l0_rdata_0_pbmts_5;
  assign l0_sram_rdata[0].pbmts[6]                = l0_rdata_0_pbmts_6;
  assign l0_sram_rdata[0].pbmts[7]                = l0_rdata_0_pbmts_7;
  assign l0_sram_rdata[0].perms[0].a              = l0_rdata_0_perms_0_a;
  assign l0_sram_rdata[0].perms[0].d              = l0_rdata_0_perms_0_d;
  assign l0_sram_rdata[0].perms[0].g              = l0_rdata_0_perms_0_g;
  assign l0_sram_rdata[0].perms[0].r              = l0_rdata_0_perms_0_r;
  assign l0_sram_rdata[0].perms[0].u              = l0_rdata_0_perms_0_u;
  assign l0_sram_rdata[0].perms[0].w              = l0_rdata_0_perms_0_w;
  assign l0_sram_rdata[0].perms[0].x              = l0_rdata_0_perms_0_x;
  assign l0_sram_rdata[0].perms[1].a              = l0_rdata_0_perms_1_a;
  assign l0_sram_rdata[0].perms[1].d              = l0_rdata_0_perms_1_d;
  assign l0_sram_rdata[0].perms[1].g              = l0_rdata_0_perms_1_g;
  assign l0_sram_rdata[0].perms[1].r              = l0_rdata_0_perms_1_r;
  assign l0_sram_rdata[0].perms[1].u              = l0_rdata_0_perms_1_u;
  assign l0_sram_rdata[0].perms[1].w              = l0_rdata_0_perms_1_w;
  assign l0_sram_rdata[0].perms[1].x              = l0_rdata_0_perms_1_x;
  assign l0_sram_rdata[0].perms[2].a              = l0_rdata_0_perms_2_a;
  assign l0_sram_rdata[0].perms[2].d              = l0_rdata_0_perms_2_d;
  assign l0_sram_rdata[0].perms[2].g              = l0_rdata_0_perms_2_g;
  assign l0_sram_rdata[0].perms[2].r              = l0_rdata_0_perms_2_r;
  assign l0_sram_rdata[0].perms[2].u              = l0_rdata_0_perms_2_u;
  assign l0_sram_rdata[0].perms[2].w              = l0_rdata_0_perms_2_w;
  assign l0_sram_rdata[0].perms[2].x              = l0_rdata_0_perms_2_x;
  assign l0_sram_rdata[0].perms[3].a              = l0_rdata_0_perms_3_a;
  assign l0_sram_rdata[0].perms[3].d              = l0_rdata_0_perms_3_d;
  assign l0_sram_rdata[0].perms[3].g              = l0_rdata_0_perms_3_g;
  assign l0_sram_rdata[0].perms[3].r              = l0_rdata_0_perms_3_r;
  assign l0_sram_rdata[0].perms[3].u              = l0_rdata_0_perms_3_u;
  assign l0_sram_rdata[0].perms[3].w              = l0_rdata_0_perms_3_w;
  assign l0_sram_rdata[0].perms[3].x              = l0_rdata_0_perms_3_x;
  assign l0_sram_rdata[0].perms[4].a              = l0_rdata_0_perms_4_a;
  assign l0_sram_rdata[0].perms[4].d              = l0_rdata_0_perms_4_d;
  assign l0_sram_rdata[0].perms[4].g              = l0_rdata_0_perms_4_g;
  assign l0_sram_rdata[0].perms[4].r              = l0_rdata_0_perms_4_r;
  assign l0_sram_rdata[0].perms[4].u              = l0_rdata_0_perms_4_u;
  assign l0_sram_rdata[0].perms[4].w              = l0_rdata_0_perms_4_w;
  assign l0_sram_rdata[0].perms[4].x              = l0_rdata_0_perms_4_x;
  assign l0_sram_rdata[0].perms[5].a              = l0_rdata_0_perms_5_a;
  assign l0_sram_rdata[0].perms[5].d              = l0_rdata_0_perms_5_d;
  assign l0_sram_rdata[0].perms[5].g              = l0_rdata_0_perms_5_g;
  assign l0_sram_rdata[0].perms[5].r              = l0_rdata_0_perms_5_r;
  assign l0_sram_rdata[0].perms[5].u              = l0_rdata_0_perms_5_u;
  assign l0_sram_rdata[0].perms[5].w              = l0_rdata_0_perms_5_w;
  assign l0_sram_rdata[0].perms[5].x              = l0_rdata_0_perms_5_x;
  assign l0_sram_rdata[0].perms[6].a              = l0_rdata_0_perms_6_a;
  assign l0_sram_rdata[0].perms[6].d              = l0_rdata_0_perms_6_d;
  assign l0_sram_rdata[0].perms[6].g              = l0_rdata_0_perms_6_g;
  assign l0_sram_rdata[0].perms[6].r              = l0_rdata_0_perms_6_r;
  assign l0_sram_rdata[0].perms[6].u              = l0_rdata_0_perms_6_u;
  assign l0_sram_rdata[0].perms[6].w              = l0_rdata_0_perms_6_w;
  assign l0_sram_rdata[0].perms[6].x              = l0_rdata_0_perms_6_x;
  assign l0_sram_rdata[0].perms[7].a              = l0_rdata_0_perms_7_a;
  assign l0_sram_rdata[0].perms[7].d              = l0_rdata_0_perms_7_d;
  assign l0_sram_rdata[0].perms[7].g              = l0_rdata_0_perms_7_g;
  assign l0_sram_rdata[0].perms[7].r              = l0_rdata_0_perms_7_r;
  assign l0_sram_rdata[0].perms[7].u              = l0_rdata_0_perms_7_u;
  assign l0_sram_rdata[0].perms[7].w              = l0_rdata_0_perms_7_w;
  assign l0_sram_rdata[0].perms[7].x              = l0_rdata_0_perms_7_x;
  assign l0_sram_rdata[0].ppns[0]                 = l0_rdata_0_ppns_0;
  assign l0_sram_rdata[0].ppns[1]                 = l0_rdata_0_ppns_1;
  assign l0_sram_rdata[0].ppns[2]                 = l0_rdata_0_ppns_2;
  assign l0_sram_rdata[0].ppns[3]                 = l0_rdata_0_ppns_3;
  assign l0_sram_rdata[0].ppns[4]                 = l0_rdata_0_ppns_4;
  assign l0_sram_rdata[0].ppns[5]                 = l0_rdata_0_ppns_5;
  assign l0_sram_rdata[0].ppns[6]                 = l0_rdata_0_ppns_6;
  assign l0_sram_rdata[0].ppns[7]                 = l0_rdata_0_ppns_7;
  assign l0_sram_rdata[0].prefetch                = l0_rdata_0_prefetch;
  assign l0_sram_rdata[0].tag                     = l0_rdata_0_tag;
  assign l0_sram_rdata[0].vmid                    = l0_rdata_0_vmid;
  assign l0_sram_rdata[0].vs[0]                   = l0_rdata_0_vs_0;
  assign l0_sram_rdata[0].vs[1]                   = l0_rdata_0_vs_1;
  assign l0_sram_rdata[0].vs[2]                   = l0_rdata_0_vs_2;
  assign l0_sram_rdata[0].vs[3]                   = l0_rdata_0_vs_3;
  assign l0_sram_rdata[0].vs[4]                   = l0_rdata_0_vs_4;
  assign l0_sram_rdata[0].vs[5]                   = l0_rdata_0_vs_5;
  assign l0_sram_rdata[0].vs[6]                   = l0_rdata_0_vs_6;
  assign l0_sram_rdata[0].vs[7]                   = l0_rdata_0_vs_7;
  assign l0_sram_rdata[1].asid                    = l0_rdata_1_asid;
  assign l0_sram_rdata[1].onlypf[0]               = l0_rdata_1_onlypf_0;
  assign l0_sram_rdata[1].onlypf[1]               = l0_rdata_1_onlypf_1;
  assign l0_sram_rdata[1].onlypf[2]               = l0_rdata_1_onlypf_2;
  assign l0_sram_rdata[1].onlypf[3]               = l0_rdata_1_onlypf_3;
  assign l0_sram_rdata[1].onlypf[4]               = l0_rdata_1_onlypf_4;
  assign l0_sram_rdata[1].onlypf[5]               = l0_rdata_1_onlypf_5;
  assign l0_sram_rdata[1].onlypf[6]               = l0_rdata_1_onlypf_6;
  assign l0_sram_rdata[1].onlypf[7]               = l0_rdata_1_onlypf_7;
  assign l0_sram_rdata[1].pbmts[0]                = l0_rdata_1_pbmts_0;
  assign l0_sram_rdata[1].pbmts[1]                = l0_rdata_1_pbmts_1;
  assign l0_sram_rdata[1].pbmts[2]                = l0_rdata_1_pbmts_2;
  assign l0_sram_rdata[1].pbmts[3]                = l0_rdata_1_pbmts_3;
  assign l0_sram_rdata[1].pbmts[4]                = l0_rdata_1_pbmts_4;
  assign l0_sram_rdata[1].pbmts[5]                = l0_rdata_1_pbmts_5;
  assign l0_sram_rdata[1].pbmts[6]                = l0_rdata_1_pbmts_6;
  assign l0_sram_rdata[1].pbmts[7]                = l0_rdata_1_pbmts_7;
  assign l0_sram_rdata[1].perms[0].a              = l0_rdata_1_perms_0_a;
  assign l0_sram_rdata[1].perms[0].d              = l0_rdata_1_perms_0_d;
  assign l0_sram_rdata[1].perms[0].g              = l0_rdata_1_perms_0_g;
  assign l0_sram_rdata[1].perms[0].r              = l0_rdata_1_perms_0_r;
  assign l0_sram_rdata[1].perms[0].u              = l0_rdata_1_perms_0_u;
  assign l0_sram_rdata[1].perms[0].w              = l0_rdata_1_perms_0_w;
  assign l0_sram_rdata[1].perms[0].x              = l0_rdata_1_perms_0_x;
  assign l0_sram_rdata[1].perms[1].a              = l0_rdata_1_perms_1_a;
  assign l0_sram_rdata[1].perms[1].d              = l0_rdata_1_perms_1_d;
  assign l0_sram_rdata[1].perms[1].g              = l0_rdata_1_perms_1_g;
  assign l0_sram_rdata[1].perms[1].r              = l0_rdata_1_perms_1_r;
  assign l0_sram_rdata[1].perms[1].u              = l0_rdata_1_perms_1_u;
  assign l0_sram_rdata[1].perms[1].w              = l0_rdata_1_perms_1_w;
  assign l0_sram_rdata[1].perms[1].x              = l0_rdata_1_perms_1_x;
  assign l0_sram_rdata[1].perms[2].a              = l0_rdata_1_perms_2_a;
  assign l0_sram_rdata[1].perms[2].d              = l0_rdata_1_perms_2_d;
  assign l0_sram_rdata[1].perms[2].g              = l0_rdata_1_perms_2_g;
  assign l0_sram_rdata[1].perms[2].r              = l0_rdata_1_perms_2_r;
  assign l0_sram_rdata[1].perms[2].u              = l0_rdata_1_perms_2_u;
  assign l0_sram_rdata[1].perms[2].w              = l0_rdata_1_perms_2_w;
  assign l0_sram_rdata[1].perms[2].x              = l0_rdata_1_perms_2_x;
  assign l0_sram_rdata[1].perms[3].a              = l0_rdata_1_perms_3_a;
  assign l0_sram_rdata[1].perms[3].d              = l0_rdata_1_perms_3_d;
  assign l0_sram_rdata[1].perms[3].g              = l0_rdata_1_perms_3_g;
  assign l0_sram_rdata[1].perms[3].r              = l0_rdata_1_perms_3_r;
  assign l0_sram_rdata[1].perms[3].u              = l0_rdata_1_perms_3_u;
  assign l0_sram_rdata[1].perms[3].w              = l0_rdata_1_perms_3_w;
  assign l0_sram_rdata[1].perms[3].x              = l0_rdata_1_perms_3_x;
  assign l0_sram_rdata[1].perms[4].a              = l0_rdata_1_perms_4_a;
  assign l0_sram_rdata[1].perms[4].d              = l0_rdata_1_perms_4_d;
  assign l0_sram_rdata[1].perms[4].g              = l0_rdata_1_perms_4_g;
  assign l0_sram_rdata[1].perms[4].r              = l0_rdata_1_perms_4_r;
  assign l0_sram_rdata[1].perms[4].u              = l0_rdata_1_perms_4_u;
  assign l0_sram_rdata[1].perms[4].w              = l0_rdata_1_perms_4_w;
  assign l0_sram_rdata[1].perms[4].x              = l0_rdata_1_perms_4_x;
  assign l0_sram_rdata[1].perms[5].a              = l0_rdata_1_perms_5_a;
  assign l0_sram_rdata[1].perms[5].d              = l0_rdata_1_perms_5_d;
  assign l0_sram_rdata[1].perms[5].g              = l0_rdata_1_perms_5_g;
  assign l0_sram_rdata[1].perms[5].r              = l0_rdata_1_perms_5_r;
  assign l0_sram_rdata[1].perms[5].u              = l0_rdata_1_perms_5_u;
  assign l0_sram_rdata[1].perms[5].w              = l0_rdata_1_perms_5_w;
  assign l0_sram_rdata[1].perms[5].x              = l0_rdata_1_perms_5_x;
  assign l0_sram_rdata[1].perms[6].a              = l0_rdata_1_perms_6_a;
  assign l0_sram_rdata[1].perms[6].d              = l0_rdata_1_perms_6_d;
  assign l0_sram_rdata[1].perms[6].g              = l0_rdata_1_perms_6_g;
  assign l0_sram_rdata[1].perms[6].r              = l0_rdata_1_perms_6_r;
  assign l0_sram_rdata[1].perms[6].u              = l0_rdata_1_perms_6_u;
  assign l0_sram_rdata[1].perms[6].w              = l0_rdata_1_perms_6_w;
  assign l0_sram_rdata[1].perms[6].x              = l0_rdata_1_perms_6_x;
  assign l0_sram_rdata[1].perms[7].a              = l0_rdata_1_perms_7_a;
  assign l0_sram_rdata[1].perms[7].d              = l0_rdata_1_perms_7_d;
  assign l0_sram_rdata[1].perms[7].g              = l0_rdata_1_perms_7_g;
  assign l0_sram_rdata[1].perms[7].r              = l0_rdata_1_perms_7_r;
  assign l0_sram_rdata[1].perms[7].u              = l0_rdata_1_perms_7_u;
  assign l0_sram_rdata[1].perms[7].w              = l0_rdata_1_perms_7_w;
  assign l0_sram_rdata[1].perms[7].x              = l0_rdata_1_perms_7_x;
  assign l0_sram_rdata[1].ppns[0]                 = l0_rdata_1_ppns_0;
  assign l0_sram_rdata[1].ppns[1]                 = l0_rdata_1_ppns_1;
  assign l0_sram_rdata[1].ppns[2]                 = l0_rdata_1_ppns_2;
  assign l0_sram_rdata[1].ppns[3]                 = l0_rdata_1_ppns_3;
  assign l0_sram_rdata[1].ppns[4]                 = l0_rdata_1_ppns_4;
  assign l0_sram_rdata[1].ppns[5]                 = l0_rdata_1_ppns_5;
  assign l0_sram_rdata[1].ppns[6]                 = l0_rdata_1_ppns_6;
  assign l0_sram_rdata[1].ppns[7]                 = l0_rdata_1_ppns_7;
  assign l0_sram_rdata[1].prefetch                = l0_rdata_1_prefetch;
  assign l0_sram_rdata[1].tag                     = l0_rdata_1_tag;
  assign l0_sram_rdata[1].vmid                    = l0_rdata_1_vmid;
  assign l0_sram_rdata[1].vs[0]                   = l0_rdata_1_vs_0;
  assign l0_sram_rdata[1].vs[1]                   = l0_rdata_1_vs_1;
  assign l0_sram_rdata[1].vs[2]                   = l0_rdata_1_vs_2;
  assign l0_sram_rdata[1].vs[3]                   = l0_rdata_1_vs_3;
  assign l0_sram_rdata[1].vs[4]                   = l0_rdata_1_vs_4;
  assign l0_sram_rdata[1].vs[5]                   = l0_rdata_1_vs_5;
  assign l0_sram_rdata[1].vs[6]                   = l0_rdata_1_vs_6;
  assign l0_sram_rdata[1].vs[7]                   = l0_rdata_1_vs_7;
  assign l0_sram_rdata[2].asid                    = l0_rdata_2_asid;
  assign l0_sram_rdata[2].onlypf[0]               = l0_rdata_2_onlypf_0;
  assign l0_sram_rdata[2].onlypf[1]               = l0_rdata_2_onlypf_1;
  assign l0_sram_rdata[2].onlypf[2]               = l0_rdata_2_onlypf_2;
  assign l0_sram_rdata[2].onlypf[3]               = l0_rdata_2_onlypf_3;
  assign l0_sram_rdata[2].onlypf[4]               = l0_rdata_2_onlypf_4;
  assign l0_sram_rdata[2].onlypf[5]               = l0_rdata_2_onlypf_5;
  assign l0_sram_rdata[2].onlypf[6]               = l0_rdata_2_onlypf_6;
  assign l0_sram_rdata[2].onlypf[7]               = l0_rdata_2_onlypf_7;
  assign l0_sram_rdata[2].pbmts[0]                = l0_rdata_2_pbmts_0;
  assign l0_sram_rdata[2].pbmts[1]                = l0_rdata_2_pbmts_1;
  assign l0_sram_rdata[2].pbmts[2]                = l0_rdata_2_pbmts_2;
  assign l0_sram_rdata[2].pbmts[3]                = l0_rdata_2_pbmts_3;
  assign l0_sram_rdata[2].pbmts[4]                = l0_rdata_2_pbmts_4;
  assign l0_sram_rdata[2].pbmts[5]                = l0_rdata_2_pbmts_5;
  assign l0_sram_rdata[2].pbmts[6]                = l0_rdata_2_pbmts_6;
  assign l0_sram_rdata[2].pbmts[7]                = l0_rdata_2_pbmts_7;
  assign l0_sram_rdata[2].perms[0].a              = l0_rdata_2_perms_0_a;
  assign l0_sram_rdata[2].perms[0].d              = l0_rdata_2_perms_0_d;
  assign l0_sram_rdata[2].perms[0].g              = l0_rdata_2_perms_0_g;
  assign l0_sram_rdata[2].perms[0].r              = l0_rdata_2_perms_0_r;
  assign l0_sram_rdata[2].perms[0].u              = l0_rdata_2_perms_0_u;
  assign l0_sram_rdata[2].perms[0].w              = l0_rdata_2_perms_0_w;
  assign l0_sram_rdata[2].perms[0].x              = l0_rdata_2_perms_0_x;
  assign l0_sram_rdata[2].perms[1].a              = l0_rdata_2_perms_1_a;
  assign l0_sram_rdata[2].perms[1].d              = l0_rdata_2_perms_1_d;
  assign l0_sram_rdata[2].perms[1].g              = l0_rdata_2_perms_1_g;
  assign l0_sram_rdata[2].perms[1].r              = l0_rdata_2_perms_1_r;
  assign l0_sram_rdata[2].perms[1].u              = l0_rdata_2_perms_1_u;
  assign l0_sram_rdata[2].perms[1].w              = l0_rdata_2_perms_1_w;
  assign l0_sram_rdata[2].perms[1].x              = l0_rdata_2_perms_1_x;
  assign l0_sram_rdata[2].perms[2].a              = l0_rdata_2_perms_2_a;
  assign l0_sram_rdata[2].perms[2].d              = l0_rdata_2_perms_2_d;
  assign l0_sram_rdata[2].perms[2].g              = l0_rdata_2_perms_2_g;
  assign l0_sram_rdata[2].perms[2].r              = l0_rdata_2_perms_2_r;
  assign l0_sram_rdata[2].perms[2].u              = l0_rdata_2_perms_2_u;
  assign l0_sram_rdata[2].perms[2].w              = l0_rdata_2_perms_2_w;
  assign l0_sram_rdata[2].perms[2].x              = l0_rdata_2_perms_2_x;
  assign l0_sram_rdata[2].perms[3].a              = l0_rdata_2_perms_3_a;
  assign l0_sram_rdata[2].perms[3].d              = l0_rdata_2_perms_3_d;
  assign l0_sram_rdata[2].perms[3].g              = l0_rdata_2_perms_3_g;
  assign l0_sram_rdata[2].perms[3].r              = l0_rdata_2_perms_3_r;
  assign l0_sram_rdata[2].perms[3].u              = l0_rdata_2_perms_3_u;
  assign l0_sram_rdata[2].perms[3].w              = l0_rdata_2_perms_3_w;
  assign l0_sram_rdata[2].perms[3].x              = l0_rdata_2_perms_3_x;
  assign l0_sram_rdata[2].perms[4].a              = l0_rdata_2_perms_4_a;
  assign l0_sram_rdata[2].perms[4].d              = l0_rdata_2_perms_4_d;
  assign l0_sram_rdata[2].perms[4].g              = l0_rdata_2_perms_4_g;
  assign l0_sram_rdata[2].perms[4].r              = l0_rdata_2_perms_4_r;
  assign l0_sram_rdata[2].perms[4].u              = l0_rdata_2_perms_4_u;
  assign l0_sram_rdata[2].perms[4].w              = l0_rdata_2_perms_4_w;
  assign l0_sram_rdata[2].perms[4].x              = l0_rdata_2_perms_4_x;
  assign l0_sram_rdata[2].perms[5].a              = l0_rdata_2_perms_5_a;
  assign l0_sram_rdata[2].perms[5].d              = l0_rdata_2_perms_5_d;
  assign l0_sram_rdata[2].perms[5].g              = l0_rdata_2_perms_5_g;
  assign l0_sram_rdata[2].perms[5].r              = l0_rdata_2_perms_5_r;
  assign l0_sram_rdata[2].perms[5].u              = l0_rdata_2_perms_5_u;
  assign l0_sram_rdata[2].perms[5].w              = l0_rdata_2_perms_5_w;
  assign l0_sram_rdata[2].perms[5].x              = l0_rdata_2_perms_5_x;
  assign l0_sram_rdata[2].perms[6].a              = l0_rdata_2_perms_6_a;
  assign l0_sram_rdata[2].perms[6].d              = l0_rdata_2_perms_6_d;
  assign l0_sram_rdata[2].perms[6].g              = l0_rdata_2_perms_6_g;
  assign l0_sram_rdata[2].perms[6].r              = l0_rdata_2_perms_6_r;
  assign l0_sram_rdata[2].perms[6].u              = l0_rdata_2_perms_6_u;
  assign l0_sram_rdata[2].perms[6].w              = l0_rdata_2_perms_6_w;
  assign l0_sram_rdata[2].perms[6].x              = l0_rdata_2_perms_6_x;
  assign l0_sram_rdata[2].perms[7].a              = l0_rdata_2_perms_7_a;
  assign l0_sram_rdata[2].perms[7].d              = l0_rdata_2_perms_7_d;
  assign l0_sram_rdata[2].perms[7].g              = l0_rdata_2_perms_7_g;
  assign l0_sram_rdata[2].perms[7].r              = l0_rdata_2_perms_7_r;
  assign l0_sram_rdata[2].perms[7].u              = l0_rdata_2_perms_7_u;
  assign l0_sram_rdata[2].perms[7].w              = l0_rdata_2_perms_7_w;
  assign l0_sram_rdata[2].perms[7].x              = l0_rdata_2_perms_7_x;
  assign l0_sram_rdata[2].ppns[0]                 = l0_rdata_2_ppns_0;
  assign l0_sram_rdata[2].ppns[1]                 = l0_rdata_2_ppns_1;
  assign l0_sram_rdata[2].ppns[2]                 = l0_rdata_2_ppns_2;
  assign l0_sram_rdata[2].ppns[3]                 = l0_rdata_2_ppns_3;
  assign l0_sram_rdata[2].ppns[4]                 = l0_rdata_2_ppns_4;
  assign l0_sram_rdata[2].ppns[5]                 = l0_rdata_2_ppns_5;
  assign l0_sram_rdata[2].ppns[6]                 = l0_rdata_2_ppns_6;
  assign l0_sram_rdata[2].ppns[7]                 = l0_rdata_2_ppns_7;
  assign l0_sram_rdata[2].prefetch                = l0_rdata_2_prefetch;
  assign l0_sram_rdata[2].tag                     = l0_rdata_2_tag;
  assign l0_sram_rdata[2].vmid                    = l0_rdata_2_vmid;
  assign l0_sram_rdata[2].vs[0]                   = l0_rdata_2_vs_0;
  assign l0_sram_rdata[2].vs[1]                   = l0_rdata_2_vs_1;
  assign l0_sram_rdata[2].vs[2]                   = l0_rdata_2_vs_2;
  assign l0_sram_rdata[2].vs[3]                   = l0_rdata_2_vs_3;
  assign l0_sram_rdata[2].vs[4]                   = l0_rdata_2_vs_4;
  assign l0_sram_rdata[2].vs[5]                   = l0_rdata_2_vs_5;
  assign l0_sram_rdata[2].vs[6]                   = l0_rdata_2_vs_6;
  assign l0_sram_rdata[2].vs[7]                   = l0_rdata_2_vs_7;
  assign l0_sram_rdata[3].asid                    = l0_rdata_3_asid;
  assign l0_sram_rdata[3].onlypf[0]               = l0_rdata_3_onlypf_0;
  assign l0_sram_rdata[3].onlypf[1]               = l0_rdata_3_onlypf_1;
  assign l0_sram_rdata[3].onlypf[2]               = l0_rdata_3_onlypf_2;
  assign l0_sram_rdata[3].onlypf[3]               = l0_rdata_3_onlypf_3;
  assign l0_sram_rdata[3].onlypf[4]               = l0_rdata_3_onlypf_4;
  assign l0_sram_rdata[3].onlypf[5]               = l0_rdata_3_onlypf_5;
  assign l0_sram_rdata[3].onlypf[6]               = l0_rdata_3_onlypf_6;
  assign l0_sram_rdata[3].onlypf[7]               = l0_rdata_3_onlypf_7;
  assign l0_sram_rdata[3].pbmts[0]                = l0_rdata_3_pbmts_0;
  assign l0_sram_rdata[3].pbmts[1]                = l0_rdata_3_pbmts_1;
  assign l0_sram_rdata[3].pbmts[2]                = l0_rdata_3_pbmts_2;
  assign l0_sram_rdata[3].pbmts[3]                = l0_rdata_3_pbmts_3;
  assign l0_sram_rdata[3].pbmts[4]                = l0_rdata_3_pbmts_4;
  assign l0_sram_rdata[3].pbmts[5]                = l0_rdata_3_pbmts_5;
  assign l0_sram_rdata[3].pbmts[6]                = l0_rdata_3_pbmts_6;
  assign l0_sram_rdata[3].pbmts[7]                = l0_rdata_3_pbmts_7;
  assign l0_sram_rdata[3].perms[0].a              = l0_rdata_3_perms_0_a;
  assign l0_sram_rdata[3].perms[0].d              = l0_rdata_3_perms_0_d;
  assign l0_sram_rdata[3].perms[0].g              = l0_rdata_3_perms_0_g;
  assign l0_sram_rdata[3].perms[0].r              = l0_rdata_3_perms_0_r;
  assign l0_sram_rdata[3].perms[0].u              = l0_rdata_3_perms_0_u;
  assign l0_sram_rdata[3].perms[0].w              = l0_rdata_3_perms_0_w;
  assign l0_sram_rdata[3].perms[0].x              = l0_rdata_3_perms_0_x;
  assign l0_sram_rdata[3].perms[1].a              = l0_rdata_3_perms_1_a;
  assign l0_sram_rdata[3].perms[1].d              = l0_rdata_3_perms_1_d;
  assign l0_sram_rdata[3].perms[1].g              = l0_rdata_3_perms_1_g;
  assign l0_sram_rdata[3].perms[1].r              = l0_rdata_3_perms_1_r;
  assign l0_sram_rdata[3].perms[1].u              = l0_rdata_3_perms_1_u;
  assign l0_sram_rdata[3].perms[1].w              = l0_rdata_3_perms_1_w;
  assign l0_sram_rdata[3].perms[1].x              = l0_rdata_3_perms_1_x;
  assign l0_sram_rdata[3].perms[2].a              = l0_rdata_3_perms_2_a;
  assign l0_sram_rdata[3].perms[2].d              = l0_rdata_3_perms_2_d;
  assign l0_sram_rdata[3].perms[2].g              = l0_rdata_3_perms_2_g;
  assign l0_sram_rdata[3].perms[2].r              = l0_rdata_3_perms_2_r;
  assign l0_sram_rdata[3].perms[2].u              = l0_rdata_3_perms_2_u;
  assign l0_sram_rdata[3].perms[2].w              = l0_rdata_3_perms_2_w;
  assign l0_sram_rdata[3].perms[2].x              = l0_rdata_3_perms_2_x;
  assign l0_sram_rdata[3].perms[3].a              = l0_rdata_3_perms_3_a;
  assign l0_sram_rdata[3].perms[3].d              = l0_rdata_3_perms_3_d;
  assign l0_sram_rdata[3].perms[3].g              = l0_rdata_3_perms_3_g;
  assign l0_sram_rdata[3].perms[3].r              = l0_rdata_3_perms_3_r;
  assign l0_sram_rdata[3].perms[3].u              = l0_rdata_3_perms_3_u;
  assign l0_sram_rdata[3].perms[3].w              = l0_rdata_3_perms_3_w;
  assign l0_sram_rdata[3].perms[3].x              = l0_rdata_3_perms_3_x;
  assign l0_sram_rdata[3].perms[4].a              = l0_rdata_3_perms_4_a;
  assign l0_sram_rdata[3].perms[4].d              = l0_rdata_3_perms_4_d;
  assign l0_sram_rdata[3].perms[4].g              = l0_rdata_3_perms_4_g;
  assign l0_sram_rdata[3].perms[4].r              = l0_rdata_3_perms_4_r;
  assign l0_sram_rdata[3].perms[4].u              = l0_rdata_3_perms_4_u;
  assign l0_sram_rdata[3].perms[4].w              = l0_rdata_3_perms_4_w;
  assign l0_sram_rdata[3].perms[4].x              = l0_rdata_3_perms_4_x;
  assign l0_sram_rdata[3].perms[5].a              = l0_rdata_3_perms_5_a;
  assign l0_sram_rdata[3].perms[5].d              = l0_rdata_3_perms_5_d;
  assign l0_sram_rdata[3].perms[5].g              = l0_rdata_3_perms_5_g;
  assign l0_sram_rdata[3].perms[5].r              = l0_rdata_3_perms_5_r;
  assign l0_sram_rdata[3].perms[5].u              = l0_rdata_3_perms_5_u;
  assign l0_sram_rdata[3].perms[5].w              = l0_rdata_3_perms_5_w;
  assign l0_sram_rdata[3].perms[5].x              = l0_rdata_3_perms_5_x;
  assign l0_sram_rdata[3].perms[6].a              = l0_rdata_3_perms_6_a;
  assign l0_sram_rdata[3].perms[6].d              = l0_rdata_3_perms_6_d;
  assign l0_sram_rdata[3].perms[6].g              = l0_rdata_3_perms_6_g;
  assign l0_sram_rdata[3].perms[6].r              = l0_rdata_3_perms_6_r;
  assign l0_sram_rdata[3].perms[6].u              = l0_rdata_3_perms_6_u;
  assign l0_sram_rdata[3].perms[6].w              = l0_rdata_3_perms_6_w;
  assign l0_sram_rdata[3].perms[6].x              = l0_rdata_3_perms_6_x;
  assign l0_sram_rdata[3].perms[7].a              = l0_rdata_3_perms_7_a;
  assign l0_sram_rdata[3].perms[7].d              = l0_rdata_3_perms_7_d;
  assign l0_sram_rdata[3].perms[7].g              = l0_rdata_3_perms_7_g;
  assign l0_sram_rdata[3].perms[7].r              = l0_rdata_3_perms_7_r;
  assign l0_sram_rdata[3].perms[7].u              = l0_rdata_3_perms_7_u;
  assign l0_sram_rdata[3].perms[7].w              = l0_rdata_3_perms_7_w;
  assign l0_sram_rdata[3].perms[7].x              = l0_rdata_3_perms_7_x;
  assign l0_sram_rdata[3].ppns[0]                 = l0_rdata_3_ppns_0;
  assign l0_sram_rdata[3].ppns[1]                 = l0_rdata_3_ppns_1;
  assign l0_sram_rdata[3].ppns[2]                 = l0_rdata_3_ppns_2;
  assign l0_sram_rdata[3].ppns[3]                 = l0_rdata_3_ppns_3;
  assign l0_sram_rdata[3].ppns[4]                 = l0_rdata_3_ppns_4;
  assign l0_sram_rdata[3].ppns[5]                 = l0_rdata_3_ppns_5;
  assign l0_sram_rdata[3].ppns[6]                 = l0_rdata_3_ppns_6;
  assign l0_sram_rdata[3].ppns[7]                 = l0_rdata_3_ppns_7;
  assign l0_sram_rdata[3].prefetch                = l0_rdata_3_prefetch;
  assign l0_sram_rdata[3].tag                     = l0_rdata_3_tag;
  assign l0_sram_rdata[3].vmid                    = l0_rdata_3_vmid;
  assign l0_sram_rdata[3].vs[0]                   = l0_rdata_3_vs_0;
  assign l0_sram_rdata[3].vs[1]                   = l0_rdata_3_vs_1;
  assign l0_sram_rdata[3].vs[2]                   = l0_rdata_3_vs_2;
  assign l0_sram_rdata[3].vs[3]                   = l0_rdata_3_vs_3;
  assign l0_sram_rdata[3].vs[4]                   = l0_rdata_3_vs_4;
  assign l0_sram_rdata[3].vs[5]                   = l0_rdata_3_vs_5;
  assign l0_sram_rdata[3].vs[6]                   = l0_rdata_3_vs_6;
  assign l0_sram_rdata[3].vs[7]                   = l0_rdata_3_vs_7;
  assign l1_sram_rdata[0].asid                    = l1_rdata_0_asid;
  assign l1_sram_rdata[0].pbmts[0]                = l1_rdata_0_pbmts_0;
  assign l1_sram_rdata[0].pbmts[1]                = l1_rdata_0_pbmts_1;
  assign l1_sram_rdata[0].pbmts[2]                = l1_rdata_0_pbmts_2;
  assign l1_sram_rdata[0].pbmts[3]                = l1_rdata_0_pbmts_3;
  assign l1_sram_rdata[0].pbmts[4]                = l1_rdata_0_pbmts_4;
  assign l1_sram_rdata[0].pbmts[5]                = l1_rdata_0_pbmts_5;
  assign l1_sram_rdata[0].pbmts[6]                = l1_rdata_0_pbmts_6;
  assign l1_sram_rdata[0].pbmts[7]                = l1_rdata_0_pbmts_7;
  assign l1_sram_rdata[0].ppns[0]                 = l1_rdata_0_ppns_0;
  assign l1_sram_rdata[0].ppns[1]                 = l1_rdata_0_ppns_1;
  assign l1_sram_rdata[0].ppns[2]                 = l1_rdata_0_ppns_2;
  assign l1_sram_rdata[0].ppns[3]                 = l1_rdata_0_ppns_3;
  assign l1_sram_rdata[0].ppns[4]                 = l1_rdata_0_ppns_4;
  assign l1_sram_rdata[0].ppns[5]                 = l1_rdata_0_ppns_5;
  assign l1_sram_rdata[0].ppns[6]                 = l1_rdata_0_ppns_6;
  assign l1_sram_rdata[0].ppns[7]                 = l1_rdata_0_ppns_7;
  assign l1_sram_rdata[0].prefetch                = l1_rdata_0_prefetch;
  assign l1_sram_rdata[0].tag                     = l1_rdata_0_tag;
  assign l1_sram_rdata[0].vmid                    = l1_rdata_0_vmid;
  assign l1_sram_rdata[0].vs[0]                   = l1_rdata_0_vs_0;
  assign l1_sram_rdata[0].vs[1]                   = l1_rdata_0_vs_1;
  assign l1_sram_rdata[0].vs[2]                   = l1_rdata_0_vs_2;
  assign l1_sram_rdata[0].vs[3]                   = l1_rdata_0_vs_3;
  assign l1_sram_rdata[0].vs[4]                   = l1_rdata_0_vs_4;
  assign l1_sram_rdata[0].vs[5]                   = l1_rdata_0_vs_5;
  assign l1_sram_rdata[0].vs[6]                   = l1_rdata_0_vs_6;
  assign l1_sram_rdata[0].vs[7]                   = l1_rdata_0_vs_7;
  assign l1_sram_rdata[1].asid                    = l1_rdata_1_asid;
  assign l1_sram_rdata[1].pbmts[0]                = l1_rdata_1_pbmts_0;
  assign l1_sram_rdata[1].pbmts[1]                = l1_rdata_1_pbmts_1;
  assign l1_sram_rdata[1].pbmts[2]                = l1_rdata_1_pbmts_2;
  assign l1_sram_rdata[1].pbmts[3]                = l1_rdata_1_pbmts_3;
  assign l1_sram_rdata[1].pbmts[4]                = l1_rdata_1_pbmts_4;
  assign l1_sram_rdata[1].pbmts[5]                = l1_rdata_1_pbmts_5;
  assign l1_sram_rdata[1].pbmts[6]                = l1_rdata_1_pbmts_6;
  assign l1_sram_rdata[1].pbmts[7]                = l1_rdata_1_pbmts_7;
  assign l1_sram_rdata[1].ppns[0]                 = l1_rdata_1_ppns_0;
  assign l1_sram_rdata[1].ppns[1]                 = l1_rdata_1_ppns_1;
  assign l1_sram_rdata[1].ppns[2]                 = l1_rdata_1_ppns_2;
  assign l1_sram_rdata[1].ppns[3]                 = l1_rdata_1_ppns_3;
  assign l1_sram_rdata[1].ppns[4]                 = l1_rdata_1_ppns_4;
  assign l1_sram_rdata[1].ppns[5]                 = l1_rdata_1_ppns_5;
  assign l1_sram_rdata[1].ppns[6]                 = l1_rdata_1_ppns_6;
  assign l1_sram_rdata[1].ppns[7]                 = l1_rdata_1_ppns_7;
  assign l1_sram_rdata[1].prefetch                = l1_rdata_1_prefetch;
  assign l1_sram_rdata[1].tag                     = l1_rdata_1_tag;
  assign l1_sram_rdata[1].vmid                    = l1_rdata_1_vmid;
  assign l1_sram_rdata[1].vs[0]                   = l1_rdata_1_vs_0;
  assign l1_sram_rdata[1].vs[1]                   = l1_rdata_1_vs_1;
  assign l1_sram_rdata[1].vs[2]                   = l1_rdata_1_vs_2;
  assign l1_sram_rdata[1].vs[3]                   = l1_rdata_1_vs_3;
  assign l1_sram_rdata[1].vs[4]                   = l1_rdata_1_vs_4;
  assign l1_sram_rdata[1].vs[5]                   = l1_rdata_1_vs_5;
  assign l1_sram_rdata[1].vs[6]                   = l1_rdata_1_vs_6;
  assign l1_sram_rdata[1].vs[7]                   = l1_rdata_1_vs_7;
  // END GENERATED(sram_rdata_pack)

  // ---------------------------------------------------------------------------
  // §17 refill bypass —— "你要的那条，这一拍正好在回填路上"
  //      （已追清：golden:30003-30070 / 30773 / 31210-31252 / 6286-6355 / 27226-27241）
  //
  //  为什么要它：请求已经进了流水、SRAM 也读过了，这时 io.refill 把同一条 vpn 写进来。
  //  流水里那份读数是**旧的**，不能当"未命中"直接报出去，否则上层会再走一次内存。
  //  所以只要 refill 覆盖了流水里这条请求的地址，就给它打上 bypassed 标记，
  //  让上层知道"这次的 miss 结论作废，重来一次就命中了"。
  //
  //  ★形状：每一级各有一份，且每一级都是「本拍匹配 wire + 跨拍记忆 reg」两件套★
  //    stageDelay 级：bypass_hit_delay / bypass_seen_delay
  //    stageCheck 级：bypass_hit_check / bypass_seen_check
  //    stageResp  级：bypass_hit_resp  + 两组 hold（普通口一组、hptw 口一组，清除条件不同）
  //  四级 index 0..3 = l0/l1/l2/l3，比较的 tag 位数不同（级数越高比得越少）。

  // 一级一级地比 vpn：l0 比 [37:3]（8 条一行，低 3 位是行内序号），
  // l1 再去掉 9 位 [37:12]，l2 去掉 18 位 [37:21]，l3 去掉 27 位 [37:30]。
  function automatic logic bypass_vpn_match(input int              level,
                                            input logic [VPN_W-1:0] a,
                                            input logic [VPN_W-1:0] b);
    case (level)
      0:       return a[37:3]  == b[37:3];
      1:       return a[37:12] == b[37:12];
      2:       return a[37:21] == b[37:21];
      default: return a[37:30] == b[37:30];
    endcase
  endfunction

  // 这一拍的 refill 是否正好覆盖了 (vpn, s2xlate) 这条请求的第 level 级。
  // ★两边都要先过 fold_h★：allStage 的请求查的是它的 stage-1 条目。
  // ★refill 那三根当参数传，不在函数体里直接读模块级信号★（理由同 §13 的
  //  sp_level_match：函数体引用非局部量会被 Formality 判 FMR_VLOG-091 / FM-089）。
  function automatic logic refill_bypass(input int              level,
                                         input logic [VPN_W-1:0] vpn,
                                         input logic [1:0]       s2x,
                                         input logic             rf_valid,
                                         input logic [1:0]       rf_level,
                                         input logic [VPN_W-1:0] rf_vpn,
                                         input logic [1:0]       rf_s2x);
    return rf_valid
         & (rf_level == 2'(level))
         & bypass_vpn_match(level, rf_vpn, vpn)
         & (fold_h(s2x) == fold_h(rf_s2x));
  endfunction

  logic [3:0] bypass_hit_delay, bypass_hit_check, bypass_hit_resp;
  logic [3:0] bypass_seen_delay, bypass_seen_check;
  logic [3:0] check_bypassed, resp_bypassed;

  // 四份"释放"脉冲，golden 里是四个**独立而同值**的寄存器（OneCycleValid(stageCheck.fire)）。
  // ★照抄四份，不合并★：合成一份会让 golden 那三个寄存器在 FM 上变成 unmatched。
  logic [3:0] bypass_release;
  logic [3:0] bypass_hold;        // 普通口：refill 或新一拍进来就清
  logic [3:0] hptw_bypass_hold;   // hptw 口：io.resp 握手成功才清

  always_comb begin
    for (int i = 0; i < 4; i++) begin
      bypass_hit_delay[i] = refill_bypass(i, delay_vpn, delay_s2x,
                                          io_refill_valid, io_refill_bits_level_dup_0,
                                          io_refill_bits_req_info_dup_0_vpn,
                                          io_refill_bits_req_info_dup_0_s2xlate);
      bypass_hit_check[i] = refill_bypass(i, check_vpn, check_s2x,
                                          io_refill_valid, io_refill_bits_level_dup_0,
                                          io_refill_bits_req_info_dup_0_vpn,
                                          io_refill_bits_req_info_dup_0_s2xlate);
      bypass_hit_resp [i] = refill_bypass(i, resp_vpn,  resp_s2x,
                                          io_refill_valid, io_refill_bits_level_dup_0,
                                          io_refill_bits_req_info_dup_0_vpn,
                                          io_refill_bits_req_info_dup_0_s2xlate);
    end
  end

  logic resp_fire;
  assign resp_fire = valid_resp & io_resp_ready;

  // ---------------------------------------------------------------------------
  // §18 stageResp 的命中结果快照 resp_res（已追清：golden:35843-36085）
  //
  //  ★为什么要再存一拍★：stageCheck 的命中结果是组合的，而 io.resp 要在下一拍输出，
  //  且 stageResp 可能被下游反压住好几拍。所以整份命中结果在 stageCheck 出口
  //  锁存成 resp_res，之后 io.resp 的两百多根全部只读 resp_res，不再回看流水。
  //  ★存的字段就是 golden 存的那些★，见 pkg 里四个 res_*_t 的注释。
  res_l3_t  resp_res_l3;
  res_l12_t resp_res_l2, resp_res_l1;
  res_l0_t  resp_res_l0;
  res_sp_t  resp_res_sp;

  // ---------------------------------------------------------------------------
  // §19 io.resp 装配（已追清：golden:6396-6536 / 44766-45302）
  //
  //  五级的优先级在这里定死：l0 > sp > l1 > l2 > l3（越靠近叶子越优先）。
  //  两阶段翻译（allStage）时还要拐一道：查到的是 stage-1 的结果，
  //  上层拿去再查 stage-2，所以 toFsm 的三个 Hit 全都要被 stage1Hit 压住。
  logic       resp_any_leaf_hit;   // l0 或 sp 命中（"叶子已经拿到了"）
  logic       stage1_hit;
  logic       resp_is_all_stage, resp_not_only_s2;
  logic [2:0] resp_pte_idx;

  assign resp_any_leaf_hit = resp_res_l0.hit | resp_res_sp.hit;
  assign resp_is_all_stage = &resp_s2x;
  assign stage1_hit        = resp_any_leaf_hit & resp_is_all_stage;
  assign resp_not_only_s2  = (resp_s2x != H_ONLY_STAGE2);
  assign resp_pte_idx      = resp_vpn[2:0];

  // 命中那一条 PTE 的 v 位：l0 命中取行内第 idx 条，否则取 sp 的。
  logic resp_leaf_v;
  assign resp_leaf_v = resp_res_l0.hit ? resp_res_l0.v[resp_pte_idx] : resp_res_sp.v;

  // ★io.resp.hit 的第二项是 golden 的"stage1 页错误"判据★：
  //  allStage 时，只有查到的 stage-1 条目**无效**（注定 pf）才算"命中并可以直接回话"，
  //  有效的话得让上层继续走 stage-2，所以反而不算 hit。非 allStage 时这一项恒真。
  assign io_resp_bits_hit = resp_any_leaf_hit
                          & (~resp_is_all_stage | resp_is_all_stage & ~resp_leaf_v);

  assign io_resp_bits_req_info_vpn     = resp_vpn;
  assign io_resp_bits_req_info_s2xlate = resp_s2x;
  assign io_resp_bits_req_info_source  = resp_src;
  assign io_resp_bits_isFirst          = resp_isfirst;
  assign io_resp_bits_isHptwReq        = resp_ishptw;
  assign io_resp_bits_prefetch = resp_res_l0.pre & resp_res_l0.hit
                               | resp_res_sp.pre & resp_res_sp.hit;

  // bypassed：某一级"这次的结论作废"且那一级确实没命中，才报给上层。
  // allStage 的请求不报（它本来就要再走一轮）。
  assign io_resp_bits_bypassed =
      ((resp_bypassed[0] | bypass_hold[0] | bypass_hit_resp[0]) & ~resp_res_l0.hit
     | (resp_bypassed[1] | bypass_hold[1] | bypass_hit_resp[1]) & ~resp_res_l1.hit
     | (resp_bypassed[2] | bypass_hold[2] | bypass_hit_resp[2]) & ~resp_res_l2.hit
     | (resp_bypassed[3] | bypass_hold[3] | bypass_hit_resp[3]) & ~resp_res_l3.hit)
    & ~resp_is_all_stage;

  assign io_resp_bits_toHptw_bypassed =
      ((resp_bypassed[0] | hptw_bypass_hold[0] | bypass_hit_resp[0]) & ~resp_res_l0.hit
     | (resp_bypassed[1] | hptw_bypass_hold[1] | bypass_hit_resp[1]) & ~resp_res_l1.hit
     | (resp_bypassed[2] | hptw_bypass_hold[2] | bypass_hit_resp[2]) & ~resp_res_l2.hit
     | (resp_bypassed[3] | hptw_bypass_hold[3] | bypass_hit_resp[3]) & ~resp_res_l3.hit)
    & resp_ishptw;

  // ---- toFsm：没查到叶子时，告诉 PTW 状态机"你可以从第几级接着往下走" ----
  assign io_resp_bits_toFsm_l3Hit =
    resp_res_l3.hit & ~stage1_hit & resp_not_only_s2 & ~resp_ishptw;
  assign io_resp_bits_toFsm_l2Hit =
    resp_res_l2.hit & ~stage1_hit & resp_not_only_s2 & ~resp_ishptw;
  assign io_resp_bits_toFsm_l1Hit =
    resp_res_l1.hit & ~stage1_hit & resp_not_only_s2 & ~resp_ishptw;
  assign io_resp_bits_toFsm_stage1Hit = stage1_hit;

  // 非叶子那三级的 ppn 共用一棵优先级树（l1 > l2 > l3），toFsm 与 toHptw 都取它。
  logic [PPN_W-1:0] nonleaf_ppn;
  assign nonleaf_ppn = resp_res_l1.hit ? resp_res_l1.ppn
                     : resp_res_l2.hit ? resp_res_l2.ppn : resp_res_l3.ppn;
  assign io_resp_bits_toFsm_ppn  = nonleaf_ppn;
  assign io_resp_bits_toHptw_ppn = nonleaf_ppn[35:0];

  // ---- toFsm / toHptw 的 bitmapCheck 出口 ----
  logic       jmp_bitmap_check;
  logic [1:0] sp_bitmap_level;
  assign jmp_bitmap_check = resp_res_l0.jmp_bitmap_check | resp_res_sp.jmp_bitmap_check;
  assign sp_bitmap_level  = resp_res_sp.jmp_bitmap_check ? resp_res_sp.level : 2'h0;

  assign io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check  = jmp_bitmap_check;
  assign io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check = jmp_bitmap_check;
  // toLLPTW：l0 那一侧要查 bitmap，且这是一阶段请求 —— 转给 LLPTW 去查。
  assign io_resp_bits_toFsm_bitmapCheck_toLLPTW =
    resp_res_l0.jmp_bitmap_check
    & ((resp_s2x == H_NO_S2XLATE) | (resp_s2x == H_ONLY_STAGE1));
  assign io_resp_bits_toFsm_bitmapCheck_hitway  = resp_res_l0.hitway;
  assign io_resp_bits_toHptw_bitmapCheck_hitway = resp_res_l0.hitway;
  assign io_resp_bits_toFsm_bitmapCheck_SPlevel  = sp_bitmap_level;
  assign io_resp_bits_toHptw_bitmapCheck_SPlevel = sp_bitmap_level;
  assign io_resp_bits_toHptw_bitmapCheck_fromSP  = resp_res_sp.jmp_bitmap_check;
  // ★两个口的 pte / ptes 取法不一样，别合并★：
  //   toFsm  —— sp 要查时整组 8 条全填 sp 那一条；否则给 l0 的 8 条（pte 再按 idx 挑）。
  //   toHptw —— pte 恒取 sp 的、ptes 恒取 l0 的，不做选择。
  assign io_resp_bits_toFsm_bitmapCheck_pte =
    resp_res_sp.jmp_bitmap_check ? resp_res_sp.pte : resp_res_l0.ptes[resp_pte_idx];
  assign io_resp_bits_toHptw_bitmapCheck_pte = resp_res_sp.pte;

  // ---- stage1：一次回 8 条相邻 PTE（tlbcontiguous），给 TLB 整组回填 ----
  //  每条的 ppn/pbmt/perm/v 各走各的优先级树；tag/asid/vmid/level/n 八条共用。
  logic [1:0] stage1_level;
  logic       stage1_n;
  logic [1:0] nonleaf_pbmt;
  assign stage1_level = resp_res_l0.hit ? 2'h0
                      : resp_res_sp.hit ? resp_res_sp.level
                      : resp_res_l1.hit ? 2'h1
                      : {1'b1, ~resp_res_l2.hit};   // l2 命中 -> 2，否则 3（l3）
  assign stage1_n     = resp_res_sp.hit & resp_res_sp.n;
  assign nonleaf_pbmt = resp_res_l1.hit ? resp_res_l1.pbmt : resp_res_l2.pbmt;

  logic [SECTOR_N-1:0] stage1_v;
  always_comb
    for (int i = 0; i < SECTOR_N; i++)
      // ★l0 不命中时 v 取 `~sp命中 | sp的v`★：谁都没命中时 v=1（于是 pf=0），
      //  只有"sp 命中了但那条是 onlyPf"才报 v=0。照抄这个不对称的写法。
      stage1_v[i] = resp_res_l0.hit ? resp_res_l0.v[i]
                                    : (~resp_res_sp.hit | resp_res_sp.v);

  // BEGIN GENERATED(stage1_entry_fanout) —— 8 条的展开，逐条同形，见上面注释
  logic [34:0]     stage1_tag;
  logic [15:0]     stage1_asid;
  logic [13:0]     stage1_vmid;
  assign stage1_tag  = resp_vpn[37:3];
  assign stage1_asid = (|resp_s2x) ? io_csr_dup_0_vsatp_asid : io_csr_dup_0_satp_asid;
  assign stage1_vmid = io_csr_dup_0_hgatp_vmid[13:0];

  assign io_resp_bits_stage1_entry_0_tag   = stage1_tag;
  assign io_resp_bits_stage1_entry_0_asid  = stage1_asid;
  assign io_resp_bits_stage1_entry_0_vmid  = stage1_vmid;
  assign io_resp_bits_stage1_entry_0_n     = stage1_n;
  assign io_resp_bits_stage1_entry_0_level = stage1_level;
  assign io_resp_bits_stage1_entry_0_v     = stage1_v[0];
  assign io_resp_bits_stage1_entry_0_pf    = ~stage1_v[0];
  assign io_resp_bits_stage1_entry_0_cf    = resp_res_l0.hit & l0_cfs[0];
  assign io_resp_bits_stage1_entry_0_pbmt  = resp_res_l0.hit ? resp_res_l0.pbmt[0]
                              : resp_res_sp.hit ? resp_res_sp.pbmt : nonleaf_pbmt;
  assign io_resp_bits_stage1_entry_0_perm_d = resp_res_l0.hit ? resp_res_l0.perm[0].d
                                : resp_res_sp.hit & resp_res_sp.perm.d;
  assign io_resp_bits_stage1_entry_0_perm_a = resp_res_l0.hit ? resp_res_l0.perm[0].a
                                : resp_res_sp.hit & resp_res_sp.perm.a;
  assign io_resp_bits_stage1_entry_0_perm_g = resp_res_l0.hit ? resp_res_l0.perm[0].g
                                : resp_res_sp.hit & resp_res_sp.perm.g;
  assign io_resp_bits_stage1_entry_0_perm_u = resp_res_l0.hit ? resp_res_l0.perm[0].u
                                : resp_res_sp.hit & resp_res_sp.perm.u;
  assign io_resp_bits_stage1_entry_0_perm_x = resp_res_l0.hit ? resp_res_l0.perm[0].x
                                : resp_res_sp.hit & resp_res_sp.perm.x;
  assign io_resp_bits_stage1_entry_0_perm_w = resp_res_l0.hit ? resp_res_l0.perm[0].w
                                : resp_res_sp.hit & resp_res_sp.perm.w;
  assign io_resp_bits_stage1_entry_0_perm_r = resp_res_l0.hit ? resp_res_l0.perm[0].r
                                : resp_res_sp.hit & resp_res_sp.perm.r;
  assign io_resp_bits_stage1_entry_0_ppn = {6'h0, resp_res_l0.hit ? resp_res_l0.ppn[0][37:3]
                          : resp_res_sp.hit ? resp_res_sp.ppn[37:3]
                          : resp_res_l1.hit ? resp_res_l1.ppn[37:3]
                          : resp_res_l2.hit ? resp_res_l2.ppn[37:3]
                                            : resp_res_l3.ppn[37:3]};
  assign io_resp_bits_stage1_entry_0_ppn_low = resp_res_l0.hit ? resp_res_l0.ppn[0][2:0]
                          : resp_res_sp.hit ? resp_res_sp.ppn[2:0]
                          : resp_res_l1.hit ? resp_res_l1.ppn[2:0]
                          : resp_res_l2.hit ? resp_res_l2.ppn[2:0]
                                            : resp_res_l3.ppn[2:0];

  assign io_resp_bits_stage1_entry_1_tag   = stage1_tag;
  assign io_resp_bits_stage1_entry_1_asid  = stage1_asid;
  assign io_resp_bits_stage1_entry_1_vmid  = stage1_vmid;
  assign io_resp_bits_stage1_entry_1_n     = stage1_n;
  assign io_resp_bits_stage1_entry_1_level = stage1_level;
  assign io_resp_bits_stage1_entry_1_v     = stage1_v[1];
  assign io_resp_bits_stage1_entry_1_pf    = ~stage1_v[1];
  assign io_resp_bits_stage1_entry_1_cf    = resp_res_l0.hit & l0_cfs[1];
  assign io_resp_bits_stage1_entry_1_pbmt  = resp_res_l0.hit ? resp_res_l0.pbmt[1]
                              : resp_res_sp.hit ? resp_res_sp.pbmt : nonleaf_pbmt;
  assign io_resp_bits_stage1_entry_1_perm_d = resp_res_l0.hit ? resp_res_l0.perm[1].d
                                : resp_res_sp.hit & resp_res_sp.perm.d;
  assign io_resp_bits_stage1_entry_1_perm_a = resp_res_l0.hit ? resp_res_l0.perm[1].a
                                : resp_res_sp.hit & resp_res_sp.perm.a;
  assign io_resp_bits_stage1_entry_1_perm_g = resp_res_l0.hit ? resp_res_l0.perm[1].g
                                : resp_res_sp.hit & resp_res_sp.perm.g;
  assign io_resp_bits_stage1_entry_1_perm_u = resp_res_l0.hit ? resp_res_l0.perm[1].u
                                : resp_res_sp.hit & resp_res_sp.perm.u;
  assign io_resp_bits_stage1_entry_1_perm_x = resp_res_l0.hit ? resp_res_l0.perm[1].x
                                : resp_res_sp.hit & resp_res_sp.perm.x;
  assign io_resp_bits_stage1_entry_1_perm_w = resp_res_l0.hit ? resp_res_l0.perm[1].w
                                : resp_res_sp.hit & resp_res_sp.perm.w;
  assign io_resp_bits_stage1_entry_1_perm_r = resp_res_l0.hit ? resp_res_l0.perm[1].r
                                : resp_res_sp.hit & resp_res_sp.perm.r;
  assign io_resp_bits_stage1_entry_1_ppn = {6'h0, resp_res_l0.hit ? resp_res_l0.ppn[1][37:3]
                          : resp_res_sp.hit ? resp_res_sp.ppn[37:3]
                          : resp_res_l1.hit ? resp_res_l1.ppn[37:3]
                          : resp_res_l2.hit ? resp_res_l2.ppn[37:3]
                                            : resp_res_l3.ppn[37:3]};
  assign io_resp_bits_stage1_entry_1_ppn_low = resp_res_l0.hit ? resp_res_l0.ppn[1][2:0]
                          : resp_res_sp.hit ? resp_res_sp.ppn[2:0]
                          : resp_res_l1.hit ? resp_res_l1.ppn[2:0]
                          : resp_res_l2.hit ? resp_res_l2.ppn[2:0]
                                            : resp_res_l3.ppn[2:0];

  assign io_resp_bits_stage1_entry_2_tag   = stage1_tag;
  assign io_resp_bits_stage1_entry_2_asid  = stage1_asid;
  assign io_resp_bits_stage1_entry_2_vmid  = stage1_vmid;
  assign io_resp_bits_stage1_entry_2_n     = stage1_n;
  assign io_resp_bits_stage1_entry_2_level = stage1_level;
  assign io_resp_bits_stage1_entry_2_v     = stage1_v[2];
  assign io_resp_bits_stage1_entry_2_pf    = ~stage1_v[2];
  assign io_resp_bits_stage1_entry_2_cf    = resp_res_l0.hit & l0_cfs[2];
  assign io_resp_bits_stage1_entry_2_pbmt  = resp_res_l0.hit ? resp_res_l0.pbmt[2]
                              : resp_res_sp.hit ? resp_res_sp.pbmt : nonleaf_pbmt;
  assign io_resp_bits_stage1_entry_2_perm_d = resp_res_l0.hit ? resp_res_l0.perm[2].d
                                : resp_res_sp.hit & resp_res_sp.perm.d;
  assign io_resp_bits_stage1_entry_2_perm_a = resp_res_l0.hit ? resp_res_l0.perm[2].a
                                : resp_res_sp.hit & resp_res_sp.perm.a;
  assign io_resp_bits_stage1_entry_2_perm_g = resp_res_l0.hit ? resp_res_l0.perm[2].g
                                : resp_res_sp.hit & resp_res_sp.perm.g;
  assign io_resp_bits_stage1_entry_2_perm_u = resp_res_l0.hit ? resp_res_l0.perm[2].u
                                : resp_res_sp.hit & resp_res_sp.perm.u;
  assign io_resp_bits_stage1_entry_2_perm_x = resp_res_l0.hit ? resp_res_l0.perm[2].x
                                : resp_res_sp.hit & resp_res_sp.perm.x;
  assign io_resp_bits_stage1_entry_2_perm_w = resp_res_l0.hit ? resp_res_l0.perm[2].w
                                : resp_res_sp.hit & resp_res_sp.perm.w;
  assign io_resp_bits_stage1_entry_2_perm_r = resp_res_l0.hit ? resp_res_l0.perm[2].r
                                : resp_res_sp.hit & resp_res_sp.perm.r;
  assign io_resp_bits_stage1_entry_2_ppn = {6'h0, resp_res_l0.hit ? resp_res_l0.ppn[2][37:3]
                          : resp_res_sp.hit ? resp_res_sp.ppn[37:3]
                          : resp_res_l1.hit ? resp_res_l1.ppn[37:3]
                          : resp_res_l2.hit ? resp_res_l2.ppn[37:3]
                                            : resp_res_l3.ppn[37:3]};
  assign io_resp_bits_stage1_entry_2_ppn_low = resp_res_l0.hit ? resp_res_l0.ppn[2][2:0]
                          : resp_res_sp.hit ? resp_res_sp.ppn[2:0]
                          : resp_res_l1.hit ? resp_res_l1.ppn[2:0]
                          : resp_res_l2.hit ? resp_res_l2.ppn[2:0]
                                            : resp_res_l3.ppn[2:0];

  assign io_resp_bits_stage1_entry_3_tag   = stage1_tag;
  assign io_resp_bits_stage1_entry_3_asid  = stage1_asid;
  assign io_resp_bits_stage1_entry_3_vmid  = stage1_vmid;
  assign io_resp_bits_stage1_entry_3_n     = stage1_n;
  assign io_resp_bits_stage1_entry_3_level = stage1_level;
  assign io_resp_bits_stage1_entry_3_v     = stage1_v[3];
  assign io_resp_bits_stage1_entry_3_pf    = ~stage1_v[3];
  assign io_resp_bits_stage1_entry_3_cf    = resp_res_l0.hit & l0_cfs[3];
  assign io_resp_bits_stage1_entry_3_pbmt  = resp_res_l0.hit ? resp_res_l0.pbmt[3]
                              : resp_res_sp.hit ? resp_res_sp.pbmt : nonleaf_pbmt;
  assign io_resp_bits_stage1_entry_3_perm_d = resp_res_l0.hit ? resp_res_l0.perm[3].d
                                : resp_res_sp.hit & resp_res_sp.perm.d;
  assign io_resp_bits_stage1_entry_3_perm_a = resp_res_l0.hit ? resp_res_l0.perm[3].a
                                : resp_res_sp.hit & resp_res_sp.perm.a;
  assign io_resp_bits_stage1_entry_3_perm_g = resp_res_l0.hit ? resp_res_l0.perm[3].g
                                : resp_res_sp.hit & resp_res_sp.perm.g;
  assign io_resp_bits_stage1_entry_3_perm_u = resp_res_l0.hit ? resp_res_l0.perm[3].u
                                : resp_res_sp.hit & resp_res_sp.perm.u;
  assign io_resp_bits_stage1_entry_3_perm_x = resp_res_l0.hit ? resp_res_l0.perm[3].x
                                : resp_res_sp.hit & resp_res_sp.perm.x;
  assign io_resp_bits_stage1_entry_3_perm_w = resp_res_l0.hit ? resp_res_l0.perm[3].w
                                : resp_res_sp.hit & resp_res_sp.perm.w;
  assign io_resp_bits_stage1_entry_3_perm_r = resp_res_l0.hit ? resp_res_l0.perm[3].r
                                : resp_res_sp.hit & resp_res_sp.perm.r;
  assign io_resp_bits_stage1_entry_3_ppn = {6'h0, resp_res_l0.hit ? resp_res_l0.ppn[3][37:3]
                          : resp_res_sp.hit ? resp_res_sp.ppn[37:3]
                          : resp_res_l1.hit ? resp_res_l1.ppn[37:3]
                          : resp_res_l2.hit ? resp_res_l2.ppn[37:3]
                                            : resp_res_l3.ppn[37:3]};
  assign io_resp_bits_stage1_entry_3_ppn_low = resp_res_l0.hit ? resp_res_l0.ppn[3][2:0]
                          : resp_res_sp.hit ? resp_res_sp.ppn[2:0]
                          : resp_res_l1.hit ? resp_res_l1.ppn[2:0]
                          : resp_res_l2.hit ? resp_res_l2.ppn[2:0]
                                            : resp_res_l3.ppn[2:0];

  assign io_resp_bits_stage1_entry_4_tag   = stage1_tag;
  assign io_resp_bits_stage1_entry_4_asid  = stage1_asid;
  assign io_resp_bits_stage1_entry_4_vmid  = stage1_vmid;
  assign io_resp_bits_stage1_entry_4_n     = stage1_n;
  assign io_resp_bits_stage1_entry_4_level = stage1_level;
  assign io_resp_bits_stage1_entry_4_v     = stage1_v[4];
  assign io_resp_bits_stage1_entry_4_pf    = ~stage1_v[4];
  assign io_resp_bits_stage1_entry_4_cf    = resp_res_l0.hit & l0_cfs[4];
  assign io_resp_bits_stage1_entry_4_pbmt  = resp_res_l0.hit ? resp_res_l0.pbmt[4]
                              : resp_res_sp.hit ? resp_res_sp.pbmt : nonleaf_pbmt;
  assign io_resp_bits_stage1_entry_4_perm_d = resp_res_l0.hit ? resp_res_l0.perm[4].d
                                : resp_res_sp.hit & resp_res_sp.perm.d;
  assign io_resp_bits_stage1_entry_4_perm_a = resp_res_l0.hit ? resp_res_l0.perm[4].a
                                : resp_res_sp.hit & resp_res_sp.perm.a;
  assign io_resp_bits_stage1_entry_4_perm_g = resp_res_l0.hit ? resp_res_l0.perm[4].g
                                : resp_res_sp.hit & resp_res_sp.perm.g;
  assign io_resp_bits_stage1_entry_4_perm_u = resp_res_l0.hit ? resp_res_l0.perm[4].u
                                : resp_res_sp.hit & resp_res_sp.perm.u;
  assign io_resp_bits_stage1_entry_4_perm_x = resp_res_l0.hit ? resp_res_l0.perm[4].x
                                : resp_res_sp.hit & resp_res_sp.perm.x;
  assign io_resp_bits_stage1_entry_4_perm_w = resp_res_l0.hit ? resp_res_l0.perm[4].w
                                : resp_res_sp.hit & resp_res_sp.perm.w;
  assign io_resp_bits_stage1_entry_4_perm_r = resp_res_l0.hit ? resp_res_l0.perm[4].r
                                : resp_res_sp.hit & resp_res_sp.perm.r;
  assign io_resp_bits_stage1_entry_4_ppn = {6'h0, resp_res_l0.hit ? resp_res_l0.ppn[4][37:3]
                          : resp_res_sp.hit ? resp_res_sp.ppn[37:3]
                          : resp_res_l1.hit ? resp_res_l1.ppn[37:3]
                          : resp_res_l2.hit ? resp_res_l2.ppn[37:3]
                                            : resp_res_l3.ppn[37:3]};
  assign io_resp_bits_stage1_entry_4_ppn_low = resp_res_l0.hit ? resp_res_l0.ppn[4][2:0]
                          : resp_res_sp.hit ? resp_res_sp.ppn[2:0]
                          : resp_res_l1.hit ? resp_res_l1.ppn[2:0]
                          : resp_res_l2.hit ? resp_res_l2.ppn[2:0]
                                            : resp_res_l3.ppn[2:0];

  assign io_resp_bits_stage1_entry_5_tag   = stage1_tag;
  assign io_resp_bits_stage1_entry_5_asid  = stage1_asid;
  assign io_resp_bits_stage1_entry_5_vmid  = stage1_vmid;
  assign io_resp_bits_stage1_entry_5_n     = stage1_n;
  assign io_resp_bits_stage1_entry_5_level = stage1_level;
  assign io_resp_bits_stage1_entry_5_v     = stage1_v[5];
  assign io_resp_bits_stage1_entry_5_pf    = ~stage1_v[5];
  assign io_resp_bits_stage1_entry_5_cf    = resp_res_l0.hit & l0_cfs[5];
  assign io_resp_bits_stage1_entry_5_pbmt  = resp_res_l0.hit ? resp_res_l0.pbmt[5]
                              : resp_res_sp.hit ? resp_res_sp.pbmt : nonleaf_pbmt;
  assign io_resp_bits_stage1_entry_5_perm_d = resp_res_l0.hit ? resp_res_l0.perm[5].d
                                : resp_res_sp.hit & resp_res_sp.perm.d;
  assign io_resp_bits_stage1_entry_5_perm_a = resp_res_l0.hit ? resp_res_l0.perm[5].a
                                : resp_res_sp.hit & resp_res_sp.perm.a;
  assign io_resp_bits_stage1_entry_5_perm_g = resp_res_l0.hit ? resp_res_l0.perm[5].g
                                : resp_res_sp.hit & resp_res_sp.perm.g;
  assign io_resp_bits_stage1_entry_5_perm_u = resp_res_l0.hit ? resp_res_l0.perm[5].u
                                : resp_res_sp.hit & resp_res_sp.perm.u;
  assign io_resp_bits_stage1_entry_5_perm_x = resp_res_l0.hit ? resp_res_l0.perm[5].x
                                : resp_res_sp.hit & resp_res_sp.perm.x;
  assign io_resp_bits_stage1_entry_5_perm_w = resp_res_l0.hit ? resp_res_l0.perm[5].w
                                : resp_res_sp.hit & resp_res_sp.perm.w;
  assign io_resp_bits_stage1_entry_5_perm_r = resp_res_l0.hit ? resp_res_l0.perm[5].r
                                : resp_res_sp.hit & resp_res_sp.perm.r;
  assign io_resp_bits_stage1_entry_5_ppn = {6'h0, resp_res_l0.hit ? resp_res_l0.ppn[5][37:3]
                          : resp_res_sp.hit ? resp_res_sp.ppn[37:3]
                          : resp_res_l1.hit ? resp_res_l1.ppn[37:3]
                          : resp_res_l2.hit ? resp_res_l2.ppn[37:3]
                                            : resp_res_l3.ppn[37:3]};
  assign io_resp_bits_stage1_entry_5_ppn_low = resp_res_l0.hit ? resp_res_l0.ppn[5][2:0]
                          : resp_res_sp.hit ? resp_res_sp.ppn[2:0]
                          : resp_res_l1.hit ? resp_res_l1.ppn[2:0]
                          : resp_res_l2.hit ? resp_res_l2.ppn[2:0]
                                            : resp_res_l3.ppn[2:0];

  assign io_resp_bits_stage1_entry_6_tag   = stage1_tag;
  assign io_resp_bits_stage1_entry_6_asid  = stage1_asid;
  assign io_resp_bits_stage1_entry_6_vmid  = stage1_vmid;
  assign io_resp_bits_stage1_entry_6_n     = stage1_n;
  assign io_resp_bits_stage1_entry_6_level = stage1_level;
  assign io_resp_bits_stage1_entry_6_v     = stage1_v[6];
  assign io_resp_bits_stage1_entry_6_pf    = ~stage1_v[6];
  assign io_resp_bits_stage1_entry_6_cf    = resp_res_l0.hit & l0_cfs[6];
  assign io_resp_bits_stage1_entry_6_pbmt  = resp_res_l0.hit ? resp_res_l0.pbmt[6]
                              : resp_res_sp.hit ? resp_res_sp.pbmt : nonleaf_pbmt;
  assign io_resp_bits_stage1_entry_6_perm_d = resp_res_l0.hit ? resp_res_l0.perm[6].d
                                : resp_res_sp.hit & resp_res_sp.perm.d;
  assign io_resp_bits_stage1_entry_6_perm_a = resp_res_l0.hit ? resp_res_l0.perm[6].a
                                : resp_res_sp.hit & resp_res_sp.perm.a;
  assign io_resp_bits_stage1_entry_6_perm_g = resp_res_l0.hit ? resp_res_l0.perm[6].g
                                : resp_res_sp.hit & resp_res_sp.perm.g;
  assign io_resp_bits_stage1_entry_6_perm_u = resp_res_l0.hit ? resp_res_l0.perm[6].u
                                : resp_res_sp.hit & resp_res_sp.perm.u;
  assign io_resp_bits_stage1_entry_6_perm_x = resp_res_l0.hit ? resp_res_l0.perm[6].x
                                : resp_res_sp.hit & resp_res_sp.perm.x;
  assign io_resp_bits_stage1_entry_6_perm_w = resp_res_l0.hit ? resp_res_l0.perm[6].w
                                : resp_res_sp.hit & resp_res_sp.perm.w;
  assign io_resp_bits_stage1_entry_6_perm_r = resp_res_l0.hit ? resp_res_l0.perm[6].r
                                : resp_res_sp.hit & resp_res_sp.perm.r;
  assign io_resp_bits_stage1_entry_6_ppn = {6'h0, resp_res_l0.hit ? resp_res_l0.ppn[6][37:3]
                          : resp_res_sp.hit ? resp_res_sp.ppn[37:3]
                          : resp_res_l1.hit ? resp_res_l1.ppn[37:3]
                          : resp_res_l2.hit ? resp_res_l2.ppn[37:3]
                                            : resp_res_l3.ppn[37:3]};
  assign io_resp_bits_stage1_entry_6_ppn_low = resp_res_l0.hit ? resp_res_l0.ppn[6][2:0]
                          : resp_res_sp.hit ? resp_res_sp.ppn[2:0]
                          : resp_res_l1.hit ? resp_res_l1.ppn[2:0]
                          : resp_res_l2.hit ? resp_res_l2.ppn[2:0]
                                            : resp_res_l3.ppn[2:0];

  assign io_resp_bits_stage1_entry_7_tag   = stage1_tag;
  assign io_resp_bits_stage1_entry_7_asid  = stage1_asid;
  assign io_resp_bits_stage1_entry_7_vmid  = stage1_vmid;
  assign io_resp_bits_stage1_entry_7_n     = stage1_n;
  assign io_resp_bits_stage1_entry_7_level = stage1_level;
  assign io_resp_bits_stage1_entry_7_v     = stage1_v[7];
  assign io_resp_bits_stage1_entry_7_pf    = ~stage1_v[7];
  assign io_resp_bits_stage1_entry_7_cf    = resp_res_l0.hit & l0_cfs[7];
  assign io_resp_bits_stage1_entry_7_pbmt  = resp_res_l0.hit ? resp_res_l0.pbmt[7]
                              : resp_res_sp.hit ? resp_res_sp.pbmt : nonleaf_pbmt;
  assign io_resp_bits_stage1_entry_7_perm_d = resp_res_l0.hit ? resp_res_l0.perm[7].d
                                : resp_res_sp.hit & resp_res_sp.perm.d;
  assign io_resp_bits_stage1_entry_7_perm_a = resp_res_l0.hit ? resp_res_l0.perm[7].a
                                : resp_res_sp.hit & resp_res_sp.perm.a;
  assign io_resp_bits_stage1_entry_7_perm_g = resp_res_l0.hit ? resp_res_l0.perm[7].g
                                : resp_res_sp.hit & resp_res_sp.perm.g;
  assign io_resp_bits_stage1_entry_7_perm_u = resp_res_l0.hit ? resp_res_l0.perm[7].u
                                : resp_res_sp.hit & resp_res_sp.perm.u;
  assign io_resp_bits_stage1_entry_7_perm_x = resp_res_l0.hit ? resp_res_l0.perm[7].x
                                : resp_res_sp.hit & resp_res_sp.perm.x;
  assign io_resp_bits_stage1_entry_7_perm_w = resp_res_l0.hit ? resp_res_l0.perm[7].w
                                : resp_res_sp.hit & resp_res_sp.perm.w;
  assign io_resp_bits_stage1_entry_7_perm_r = resp_res_l0.hit ? resp_res_l0.perm[7].r
                                : resp_res_sp.hit & resp_res_sp.perm.r;
  assign io_resp_bits_stage1_entry_7_ppn = {6'h0, resp_res_l0.hit ? resp_res_l0.ppn[7][37:3]
                          : resp_res_sp.hit ? resp_res_sp.ppn[37:3]
                          : resp_res_l1.hit ? resp_res_l1.ppn[37:3]
                          : resp_res_l2.hit ? resp_res_l2.ppn[37:3]
                                            : resp_res_l3.ppn[37:3]};
  assign io_resp_bits_stage1_entry_7_ppn_low = resp_res_l0.hit ? resp_res_l0.ppn[7][2:0]
                          : resp_res_sp.hit ? resp_res_sp.ppn[2:0]
                          : resp_res_l1.hit ? resp_res_l1.ppn[2:0]
                          : resp_res_l2.hit ? resp_res_l2.ppn[2:0]
                                            : resp_res_l3.ppn[2:0];

  assign io_resp_bits_stage1_pteidx_0 = (resp_pte_idx == 3'd0);
  assign io_resp_bits_stage1_pteidx_1 = (resp_pte_idx == 3'd1);
  assign io_resp_bits_stage1_pteidx_2 = (resp_pte_idx == 3'd2);
  assign io_resp_bits_stage1_pteidx_3 = (resp_pte_idx == 3'd3);
  assign io_resp_bits_stage1_pteidx_4 = (resp_pte_idx == 3'd4);
  assign io_resp_bits_stage1_pteidx_5 = (resp_pte_idx == 3'd5);
  assign io_resp_bits_stage1_pteidx_6 = (resp_pte_idx == 3'd6);
  assign io_resp_bits_stage1_pteidx_7 = (resp_pte_idx == 3'd7);

  assign io_resp_bits_toFsm_bitmapCheck_ptes_0 =
    resp_res_sp.jmp_bitmap_check ? resp_res_sp.pte : resp_res_l0.ptes[0];
  assign io_resp_bits_toFsm_bitmapCheck_ptes_1 =
    resp_res_sp.jmp_bitmap_check ? resp_res_sp.pte : resp_res_l0.ptes[1];
  assign io_resp_bits_toFsm_bitmapCheck_ptes_2 =
    resp_res_sp.jmp_bitmap_check ? resp_res_sp.pte : resp_res_l0.ptes[2];
  assign io_resp_bits_toFsm_bitmapCheck_ptes_3 =
    resp_res_sp.jmp_bitmap_check ? resp_res_sp.pte : resp_res_l0.ptes[3];
  assign io_resp_bits_toFsm_bitmapCheck_ptes_4 =
    resp_res_sp.jmp_bitmap_check ? resp_res_sp.pte : resp_res_l0.ptes[4];
  assign io_resp_bits_toFsm_bitmapCheck_ptes_5 =
    resp_res_sp.jmp_bitmap_check ? resp_res_sp.pte : resp_res_l0.ptes[5];
  assign io_resp_bits_toFsm_bitmapCheck_ptes_6 =
    resp_res_sp.jmp_bitmap_check ? resp_res_sp.pte : resp_res_l0.ptes[6];
  assign io_resp_bits_toFsm_bitmapCheck_ptes_7 =
    resp_res_sp.jmp_bitmap_check ? resp_res_sp.pte : resp_res_l0.ptes[7];
  assign io_resp_bits_toFsm_bitmapCheck_cfs_0  = resp_res_l0.cfs[0];
  assign io_resp_bits_toFsm_bitmapCheck_cfs_1  = resp_res_l0.cfs[1];
  assign io_resp_bits_toFsm_bitmapCheck_cfs_2  = resp_res_l0.cfs[2];
  assign io_resp_bits_toFsm_bitmapCheck_cfs_3  = resp_res_l0.cfs[3];
  assign io_resp_bits_toFsm_bitmapCheck_cfs_4  = resp_res_l0.cfs[4];
  assign io_resp_bits_toFsm_bitmapCheck_cfs_5  = resp_res_l0.cfs[5];
  assign io_resp_bits_toFsm_bitmapCheck_cfs_6  = resp_res_l0.cfs[6];
  assign io_resp_bits_toFsm_bitmapCheck_cfs_7  = resp_res_l0.cfs[7];
  assign io_resp_bits_toHptw_bitmapCheck_ptes_0 = resp_res_l0.ptes[0];
  assign io_resp_bits_toHptw_bitmapCheck_ptes_1 = resp_res_l0.ptes[1];
  assign io_resp_bits_toHptw_bitmapCheck_ptes_2 = resp_res_l0.ptes[2];
  assign io_resp_bits_toHptw_bitmapCheck_ptes_3 = resp_res_l0.ptes[3];
  assign io_resp_bits_toHptw_bitmapCheck_ptes_4 = resp_res_l0.ptes[4];
  assign io_resp_bits_toHptw_bitmapCheck_ptes_5 = resp_res_l0.ptes[5];
  assign io_resp_bits_toHptw_bitmapCheck_ptes_6 = resp_res_l0.ptes[6];
  assign io_resp_bits_toHptw_bitmapCheck_ptes_7 = resp_res_l0.ptes[7];
  // END GENERATED(stage1_entry_fanout)

  assign io_resp_bits_stage1_not_super = resp_res_l0.hit;
  assign io_resp_bits_toHptw_id        = resp_hptwid;
  assign io_resp_bits_toHptw_resp_entry_tag   = resp_vpn;
  assign io_resp_bits_toHptw_resp_entry_vmid  = io_csr_dup_0_hgatp_vmid[13:0];
  assign io_resp_bits_toHptw_resp_entry_n     = stage1_n;
  assign io_resp_bits_toHptw_resp_entry_level = resp_res_l0.hit ? 2'h0 : resp_res_sp.level;
  assign io_resp_bits_toHptw_resp_entry_pbmt  =
    resp_res_l0.hit ? resp_res_l0.pbmt[resp_pte_idx] : resp_res_sp.pbmt;
  assign io_resp_bits_toHptw_resp_entry_ppn   =
    {2'h0, resp_res_l0.hit ? resp_res_l0.ppn[resp_pte_idx][35:0]
                           : resp_res_sp.ppn[35:0]};
  assign io_resp_bits_toHptw_resp_entry_perm_d =
    resp_res_l0.hit ? resp_res_l0.perm[resp_pte_idx].d : resp_res_sp.perm.d;
  assign io_resp_bits_toHptw_resp_entry_perm_a =
    resp_res_l0.hit ? resp_res_l0.perm[resp_pte_idx].a : resp_res_sp.perm.a;
  assign io_resp_bits_toHptw_resp_entry_perm_g =
    resp_res_l0.hit ? resp_res_l0.perm[resp_pte_idx].g : resp_res_sp.perm.g;
  assign io_resp_bits_toHptw_resp_entry_perm_u =
    resp_res_l0.hit ? resp_res_l0.perm[resp_pte_idx].u : resp_res_sp.perm.u;
  assign io_resp_bits_toHptw_resp_entry_perm_x =
    resp_res_l0.hit ? resp_res_l0.perm[resp_pte_idx].x : resp_res_sp.perm.x;
  assign io_resp_bits_toHptw_resp_entry_perm_w =
    resp_res_l0.hit ? resp_res_l0.perm[resp_pte_idx].w : resp_res_sp.perm.w;
  assign io_resp_bits_toHptw_resp_entry_perm_r =
    resp_res_l0.hit ? resp_res_l0.perm[resp_pte_idx].r : resp_res_sp.perm.r;
  // gpf = "G 阶段页错误" = 查到的那条无效
  assign io_resp_bits_toHptw_resp_gpf = ~resp_leaf_v;

  assign io_resp_bits_toHptw_l3Hit = resp_res_l3.hit & resp_ishptw;
  assign io_resp_bits_toHptw_l2Hit = resp_res_l2.hit & resp_ishptw;
  assign io_resp_bits_toHptw_l1Hit = resp_res_l1.hit & resp_ishptw;

  // ---------------------------------------------------------------------------
  // §20 perf 事件（已追清：golden:8347-8361 / 36097-36113 / 45295-45302）
  //
  //  八个计数口都是 1 位事件打**两拍**再零扩展到 6 位输出（HasPerfEvents 的定式）。
  //  ★access 只统计非预取请求★：prefetch(source==2) 发起的查询不算一次访问。
  logic perf_access;
  assign perf_access = (resp_src != 2'd2) & resp_fire;

  logic [7:0] perf_event;
  assign perf_event[0] = perf_access;
  assign perf_event[1] = perf_access & io_resp_bits_toFsm_l2Hit
                       & ~io_resp_bits_toFsm_l1Hit & ~io_resp_bits_hit;
  assign perf_event[2] = perf_access & io_resp_bits_toFsm_l1Hit & ~io_resp_bits_hit;
  assign perf_event[3] = perf_access & resp_res_l0.hit;
  assign perf_event[4] = perf_access & resp_res_sp.hit;
  assign perf_event[5] = perf_access & io_resp_bits_hit;
  assign perf_event[6] = io_req_valid & ~stage_req_ready;   // 入口被堵
  assign perf_event[7] = valid_resp   & ~io_resp_ready;     // 出口被堵

  logic [7:0] perf_event_d1, perf_event_d2;
  assign io_perf_0_value = {5'h0, perf_event_d2[0]};
  assign io_perf_1_value = {5'h0, perf_event_d2[1]};
  assign io_perf_2_value = {5'h0, perf_event_d2[2]};
  assign io_perf_3_value = {5'h0, perf_event_d2[3]};
  assign io_perf_4_value = {5'h0, perf_event_d2[4]};
  assign io_perf_5_value = {5'h0, perf_event_d2[5]};
  assign io_perf_6_value = {5'h0, perf_event_d2[6]};
  assign io_perf_7_value = {5'h0, perf_event_d2[7]};

  // ---------------------------------------------------------------------------
  // §21 sfence / hfence 失效（已追清：golden 的 l0v/l1v/l2v/spv/l3v 清零支路；
  //     Chisel PageTableCache.scala:1097-1300）
  //
  //  三种栅栏，**同一拍最多来一种**，但 golden 是三段 `when` 顺序覆盖，
  //  所以优先级是 hfence.gvma > hfence.vvma > sfence.vma。照抄这个顺序。
  //    sfence.vma    —— hg=0 且 hv=0。刷"当前虚拟化上下文"的一阶段条目。
  //    hfence.vvma   —— hv=1。刷本 VM 的一阶段条目（VS 级页表）。
  //    hfence.gvma   —— hg=1。刷二阶段条目（G 级页表）。
  //  每种再按 rs1（给了地址吗）/ rs2（给了 asid/vmid 吗）分四档：
  //    rs1=1,rs2=1  全刷      rs1=1,rs2=0  按 asid 刷（global 条目豁免）
  //    rs1=0,rs2=1  按地址刷  rs1=0,rs2=0  按地址 + asid 刷
  //  ★rs1=0（指定地址）那两档只碰 l0 与 sp★：l1/l2/l3 存的是非叶子 PDE，
  //   一个地址落在哪条 PDE 上不唯一，golden 干脆不刷它们。照抄，别"补全"。
  //
  //  ★比对用的是 XORFold 哈希副本，不是 SRAM 里的原值★（见 §9.1）：
  //   哈希撞了就多刷几条，是 golden 有意的保守设计。

  logic sfence_plain, hfence_vvma, hfence_gvma;
  assign sfence_plain = io_sfence_dup_0_valid
                      & ~io_sfence_dup_0_bits_hg & ~io_sfence_dup_0_bits_hv;
  assign hfence_vvma  = io_sfence_dup_0_valid & io_sfence_dup_0_bits_hv;
  assign hfence_gvma  = io_sfence_dup_0_valid & io_sfence_dup_0_bits_hg;

  // ---- 与栅栏种类无关的 asid 比对（golden 把它们放在三段 when 之外）----
  //  ★l0/l1 比折叠哈希，l2/sp 比 16 位原值★：l2/sp 是寄存器阵列，原值就在手边。
  logic [L0_SETS*L0_WAYS-1:0] l0_asid_hit;
  logic [L1_SETS*L1_WAYS-1:0] l1_asid_hit;
  logic [L2_N-1:0]            l2_asid_hit;
  logic [SP_N-1:0]            sp_asid_hit;
  logic [L3_N-1:0]            l3_asid_hit;

  always_comb begin
    for (int s = 0; s < L0_SETS; s++)
      for (int w = 0; w < L0_WAYS; w++)
        l0_asid_hit[L0_WAYS*s + w] =
          (l0asids[s][w] == xorfold3(io_sfence_dup_0_bits_id));
    for (int s = 0; s < L1_SETS; s++)
      for (int w = 0; w < L1_WAYS; w++)
        l1_asid_hit[L1_WAYS*s + w] =
          (l1asids[s][w] == xorfold3(io_sfence_dup_1_bits_id));
    for (int i = 0; i < L2_N; i++)
      l2_asid_hit[i] = (l2_entry[i].asid == io_sfence_dup_2_bits_id);
    for (int i = 0; i < SP_N; i++)
      sp_asid_hit[i] = (sp_entry[i].asid == io_sfence_dup_0_bits_id);
    for (int i = 0; i < L3_N; i++)
      l3_asid_hit[i] = (l3_entry[i].asid == io_sfence_dup_2_bits_id);
  end

  // ---- vmid 比对：sfence/hfence.vvma 比 hgatp.vmid，hfence.gvma 比 rs2 给的 id ----
  //  ★各级用各自 dup 的 csr★（l0/sp 用 dup_0、l1 用 dup_1、l2/l3 用 dup_2）。
  logic [L0_SETS*L0_WAYS-1:0] l0_vmid_csr, l0_vmid_id;
  logic [L1_SETS*L1_WAYS-1:0] l1_vmid_csr, l1_vmid_id;
  logic [L2_N-1:0]            l2_vmid_csr, l2_vmid_id;
  logic [SP_N-1:0]            sp_vmid_csr, sp_vmid_id;
  logic [L3_N-1:0]            l3_vmid_csr, l3_vmid_id;

  always_comb begin
    for (int s = 0; s < L0_SETS; s++)
      for (int w = 0; w < L0_WAYS; w++) begin
        l0_vmid_csr[L0_WAYS*s + w] =
          (l0vmids[s][w] == xorfold3(io_csr_dup_0_hgatp_vmid));
        l0_vmid_id [L0_WAYS*s + w] =
          (l0vmids[s][w] == xorfold3(io_sfence_dup_0_bits_id));
      end
    for (int s = 0; s < L1_SETS; s++)
      for (int w = 0; w < L1_WAYS; w++) begin
        l1_vmid_csr[L1_WAYS*s + w] =
          (l1vmids[s][w] == xorfold3(io_csr_dup_1_hgatp_vmid));
        l1_vmid_id [L1_WAYS*s + w] =
          (l1vmids[s][w] == xorfold3(io_sfence_dup_1_bits_id));
      end
    // ★14 位存值与 16 位比较值之间是零扩展★：vmid 高两位非零就一条都刷不到。
    for (int i = 0; i < L2_N; i++) begin
      l2_vmid_csr[i] = ({2'h0, l2_entry[i].vmid} == io_csr_dup_2_hgatp_vmid);
      l2_vmid_id [i] = ({2'h0, l2_entry[i].vmid} == io_sfence_dup_2_bits_id);
    end
    for (int i = 0; i < SP_N; i++) begin
      sp_vmid_csr[i] = ({2'h0, sp_entry[i].vmid} == io_csr_dup_0_hgatp_vmid);
      sp_vmid_id [i] = ({2'h0, sp_entry[i].vmid} == io_sfence_dup_0_bits_id);
    end
    for (int i = 0; i < L3_N; i++) begin
      l3_vmid_csr[i] = ({2'h0, l3_entry[i].vmid} == io_csr_dup_2_hgatp_vmid);
      l3_vmid_id [i] = ({2'h0, l3_entry[i].vmid} == io_sfence_dup_2_bits_id);
    end
  end

  // ---- h 比对：这条表项属不属于本次栅栏要刷的翻译模式 ----
  //  sfence.vma 在 V=1 时刷 onlyStage1、在 V=0 时刷 noS2xlate（各用各的 dup 的 priv.virt）；
  //  hfence.vvma 恒刷 onlyStage1；hfence.gvma 刷 onlyStage1 与 onlyStage2 两种。
  logic [L0_SETS*L0_WAYS-1:0] l0_h_sf, l0_h_s1, l0_h_s2, l0_h_g;
  logic [L1_SETS*L1_WAYS-1:0] l1_h_sf, l1_h_s1, l1_h_g;
  logic [L2_N-1:0]            l2_h_sf, l2_h_s1, l2_h_g;
  logic [SP_N-1:0]            sp_h_sf, sp_h_s1, sp_h_s2, sp_h_g;
  logic [L3_N-1:0]            l3_h_sf, l3_h_s1, l3_h_g;

  always_comb begin
    for (int s = 0; s < L0_SETS; s++)
      for (int w = 0; w < L0_WAYS; w++) begin
        automatic int k = L0_WAYS*s + w;
        l0_h_sf[k] = io_csr_dup_0_priv_virt ? (l0h[s][w] == H_ONLY_STAGE1)
                                            : (l0h[s][w] == H_NO_S2XLATE);
        l0_h_s1[k] = (l0h[s][w] == H_ONLY_STAGE1);
        l0_h_s2[k] = (l0h[s][w] == H_ONLY_STAGE2);
        l0_h_g [k] = l0_h_s1[k] | l0_h_s2[k];
      end
    for (int s = 0; s < L1_SETS; s++)
      for (int w = 0; w < L1_WAYS; w++) begin
        automatic int k = L1_WAYS*s + w;
        l1_h_sf[k] = io_csr_dup_1_priv_virt ? (l1h[s][w] == H_ONLY_STAGE1)
                                            : (l1h[s][w] == H_NO_S2XLATE);
        l1_h_s1[k] = (l1h[s][w] == H_ONLY_STAGE1);
        l1_h_g [k] = l1_h_s1[k] | (l1h[s][w] == H_ONLY_STAGE2);
      end
    for (int i = 0; i < L2_N; i++) begin
      l2_h_sf[i] = io_csr_dup_2_priv_virt ? (l2h[i] == H_ONLY_STAGE1)
                                          : (l2h[i] == H_NO_S2XLATE);
      l2_h_s1[i] = (l2h[i] == H_ONLY_STAGE1);
      l2_h_g [i] = l2_h_s1[i] | (l2h[i] == H_ONLY_STAGE2);
    end
    for (int i = 0; i < SP_N; i++) begin
      sp_h_sf[i] = io_csr_dup_0_priv_virt ? (sph[i] == H_ONLY_STAGE1)
                                          : (sph[i] == H_NO_S2XLATE);
      sp_h_s1[i] = (sph[i] == H_ONLY_STAGE1);
      sp_h_s2[i] = (sph[i] == H_ONLY_STAGE2);
      sp_h_g [i] = sp_h_s1[i] | sp_h_s2[i];
    end
    for (int i = 0; i < L3_N; i++) begin
      l3_h_sf[i] = io_csr_dup_2_priv_virt ? (l3h[i] == H_ONLY_STAGE1)
                                          : (l3h[i] == H_NO_S2XLATE);
      l3_h_s1[i] = (l3h[i] == H_ONLY_STAGE1);
      l3_h_g [i] = l3_h_s1[i] | (l3h[i] == H_ONLY_STAGE2);
    end
  end

  // sfence.vma 的"虚拟化上下文命中"：V=1 时还要 vmid 也对上，V=0 时只看 h。
  logic [L0_SETS*L0_WAYS-1:0] l0_virt_hit;
  logic [L1_SETS*L1_WAYS-1:0] l1_virt_hit;
  logic [L2_N-1:0]            l2_virt_hit;
  logic [SP_N-1:0]            sp_virt_hit;
  logic [L3_N-1:0]            l3_virt_hit;
  assign l0_virt_hit = l0_h_sf & (io_csr_dup_0_priv_virt ? l0_vmid_csr : '1);
  assign l1_virt_hit = l1_h_sf & (io_csr_dup_1_priv_virt ? l1_vmid_csr : '1);
  assign l2_virt_hit = l2_h_sf & (io_csr_dup_2_priv_virt ? l2_vmid_csr : '1);
  assign sp_virt_hit = sp_h_sf & (io_csr_dup_0_priv_virt ? sp_vmid_csr : '1);
  assign l3_virt_hit = l3_h_sf & (io_csr_dup_2_priv_virt ? l3_vmid_csr : '1);

  // ---- 按地址刷时用的 vpn ----
  //  sfence.vma / hfence.vvma 取 addr[49:12]（addr 是字节地址，去掉 12 位页内偏移）；
  //  ★hfence.gvma 取的是 (addr << 2)[49:12] = addr[47:10]★——G 阶段的 gpa 在
  //  sfence 指令里按 4 字节粒度编码（Sv39x4 的根页表大 4 倍），照抄这个移位。
  logic [VPN_W-1:0] sfence_vpn, hfenceg_gvpn;
  assign sfence_vpn   = io_sfence_dup_0_bits_addr[49:12];
  assign hfenceg_gvpn = io_sfence_dup_0_bits_addr[47:10];

  logic [L0_SETS*L0_WAYS-1:0] l0_vpn_hit_sf, l0_vpn_hit_g;
  logic [L0_SETS*L0_WAYS-1:0] l0_flush_set_sf, l0_flush_set_g;
  always_comb begin
    for (int s = 0; s < L0_SETS; s++)
      for (int w = 0; w < L0_WAYS; w++) begin
        automatic int k = L0_WAYS*s + w;
        l0_vpn_hit_sf[k]   = (l0vpns[s][w] == xorfold6_tag(sfence_vpn[37:9]));
        l0_vpn_hit_g [k]   = (l0vpns[s][w] == xorfold6_tag(hfenceg_gvpn[37:9]));
        // 只刷地址落到的那一组（组内 4 路都刷，因为 vpn 哈希只能缩到组这一级）
        l0_flush_set_sf[k] = (6'(s) == sfence_vpn[8:3]);
        l0_flush_set_g [k] = (6'(s) == hfenceg_gvpn[8:3]);
      end
  end

  // ---- sp 在"按地址刷"时用的是完整的 PtwEntry.hit（allType）----
  //  PtwEntry.hit 的 sfence 分支展开后只剩三项，按栅栏种类取舍：
  //    asid_hit  —— 只有 rs2=0（指定了 asid）且不是 hfence.gvma 时才查；global 条目豁免
  //    vmid_hit  —— sfence.vma 仅在 V=1 时查、hfence.vvma 恒查、hfence.gvma 在 rs2=0 时查
  //    level_match —— 恒查（与查找侧共用 sp_level_match）
  logic [SP_N-1:0] sp_tag_sf, sp_tag_g, sp_asid_or_g;
  always_comb
    for (int i = 0; i < SP_N; i++) begin
      sp_tag_sf[i]    = sp_level_match(sp_entry[i], sfence_vpn);
      sp_tag_g [i]    = sp_level_match(sp_entry[i], hfenceg_gvpn);
      sp_asid_or_g[i] = sp_asid_hit[i] | sp_entry[i].perm.g;
    end

  // ---------------------------------------------------------------------------
  // §21.1 五级的失效掩码 —— "这一拍要把哪些位从 v 向量里打掉"
  //
  //  写成掩码而不是直接写 v：三种栅栏要按 golden 的顺序覆盖，掩码形让覆盖关系
  //  在 §11 的 always_ff 里一眼可读（谁在后面谁赢）。
  logic [L0_SETS*L0_WAYS-1:0] l0_sf_mask, l0_hv_mask, l0_hg_mask;
  logic [L1_SETS*L1_WAYS-1:0] l1_sf_mask, l1_hv_mask, l1_hg_mask;
  logic [L2_N-1:0]            l2_sf_mask, l2_hv_mask, l2_hg_mask;
  logic [SP_N-1:0]            sp_sf_mask, sp_hv_mask, sp_hg_mask;
  logic [L3_N-1:0]            l3_sf_mask, l3_hv_mask, l3_hg_mask;
  logic sf_rs1, sf_rs2, l3_rs1, l3_rs2;
  assign sf_rs1 = io_sfence_dup_0_bits_rs1;
  assign sf_rs2 = io_sfence_dup_0_bits_rs2;
  // ★l3 那一段用的是 dup_2 的 rs1/rs2★（golden 里 l3 的 sfence 独立成段）。
  assign l3_rs1 = io_sfence_dup_2_bits_rs1;
  assign l3_rs2 = io_sfence_dup_2_bits_rs2;

  always_comb begin
    // ---- sfence.vma ----
    if (sf_rs1) begin
      l0_sf_mask = sf_rs2 ? l0_virt_hit : (l0_virt_hit & ~l0g & l0_asid_hit);
      l1_sf_mask = sf_rs2 ? l1_virt_hit : (l1_virt_hit & ~l1g & l1_asid_hit);
      l2_sf_mask = sf_rs2 ? l2_virt_hit : (l2_virt_hit & ~l2g & l2_asid_hit);
      sp_sf_mask = sf_rs2 ? sp_virt_hit : (sp_virt_hit & ~spg & sp_asid_hit);
    end
    else begin
      l0_sf_mask = l0_virt_hit & l0_vpn_hit_sf & l0_flush_set_sf
                 & (sf_rs2 ? '1 : (~l0g & l0_asid_hit));
      // ★rs1=0 时 golden 根本不给 l1v/l2v 赋值★（非叶子 PDE 与地址不是一一对应）。
      //  这里给掩码填 0 只是让 always_comb 完备；真正的"不刷"靠 §11 里的 sf_rs1 门，
      //  掩码为 0 的赋值会覆盖掉同一拍的回填结果，不是无害的。
      l1_sf_mask = '0;
      l2_sf_mask = '0;
      sp_sf_mask = sp_h_sf & sp_tag_sf
                 & (io_csr_dup_0_priv_virt ? sp_vmid_csr : '1)
                 & (sf_rs2 ? '1 : (~spg & sp_asid_or_g));
    end

    // ---- hfence.vvma ----
    if (sf_rs1) begin
      l0_hv_mask = (l0_h_s1 & l0_vmid_csr) & (sf_rs2 ? '1 : (~l0g & l0_asid_hit));
      l1_hv_mask = (l1_h_s1 & l1_vmid_csr) & (sf_rs2 ? '1 : (~l1g & l1_asid_hit));
      l2_hv_mask = (l2_h_s1 & l2_vmid_csr) & (sf_rs2 ? '1 : (~l2g & l2_asid_hit));
      sp_hv_mask = (sp_h_s1 & sp_vmid_csr) & (sf_rs2 ? '1 : (~spg & sp_asid_hit));
    end
    else begin
      l0_hv_mask = l0_h_s1 & l0_vmid_csr & l0_vpn_hit_sf & l0_flush_set_sf
                 & (sf_rs2 ? '1 : (~l0g & l0_asid_hit));
      l1_hv_mask = '0;
      l2_hv_mask = '0;
      sp_hv_mask = sp_h_s1 & sp_tag_sf & sp_vmid_csr
                 & (sf_rs2 ? '1 : (~spg & sp_asid_or_g));
    end

    // ---- hfence.gvma（★vmid 来自 rs2 寄存器的 id，不是 hgatp★）----
    if (sf_rs1) begin
      l0_hg_mask = sf_rs2 ? l0_h_g : (l0_h_g & l0_vmid_id);
      l1_hg_mask = sf_rs2 ? l1_h_g : (l1_h_g & l1_vmid_id);
      l2_hg_mask = sf_rs2 ? l2_h_g : (l2_h_g & l2_vmid_id);
      sp_hg_mask = sf_rs2 ? sp_h_g : (sp_h_g & sp_vmid_id);
    end
    else begin
      // ★按地址刷 G 阶段时只认 onlyStage2 的条目★（不含 onlyStage1）。
      l0_hg_mask = l0_h_s2 & l0_vpn_hit_g & l0_flush_set_g
                 & (sf_rs2 ? '1 : l0_vmid_id);
      l1_hg_mask = '0;
      l2_hg_mask = '0;
      sp_hg_mask = sp_h_s2 & sp_tag_g & (sf_rs2 ? '1 : sp_vmid_id);
    end

    // ---- l3：独立一段，用 dup_2 的 rs1/rs2，且★只有 rs1=1 的两档★ ----
    //  rs1=0 时 golden 那一段整个不赋值 —— 所以 §11 里那三条都用 l3_rs1 当门，
    //  ★不能写成"掩码为 0 的无害赋值"★：那会把同一拍 l3 回填刚置上的位又抹回去。
    l3_sf_mask = l3_rs2 ? l3_virt_hit : (~l3g & l3_h_sf & l3_asid_hit & l3_virt_hit);
    l3_hv_mask = l3_rs2 ? (l3_h_s1 & l3_vmid_csr)
                        : (~l3g & l3_h_s1 & l3_asid_hit & l3_vmid_csr);
    l3_hg_mask = l3_rs2 ? l3_h_g : (l3_h_g & l3_vmid_id);
  end

  // ---------------------------------------------------------------------------
  // §22 bitmap wakeup —— 上层查完 bitmap 回来"补票"
  //     （已追清：Chisel PageTableCache.scala:613-645；golden wakeup_* 一族寄存器）
  //
  //  剧情：l0 命中了但这条 PTE 的 bitmap 还没查过（§16 的 jmp_bitmap_check），
  //  于是这次不算命中，上层拿着 {setIndex, way_info, pte_index} 去查 bitmap，
  //  查完从 io.bitmap_wakeup 回来把那一位置上。下次再查同一条就直接命中。
  //
  //  ★为什么要重新读一遍 SRAM★：从发出去到回来隔了很多拍，那一路可能已经被
  //  别的回填顶掉了。所以 wakeup 也占用 l0 的读端口（§5 的入口节流就是为它让路），
  //  回读之后**重算一次命中**，确认还是同一条，才允许写 bitmap 位。
  //
  //  三拍流水，与主流水**完全独立**（各有各的保持寄存器）：
  //    拍0 fire        发 SRAM 读，锁存请求与该组的 v/h 向量
  //    拍1 delay_valid SRAM 数据回来，算 hitVec
  //    拍2 req_valid   按 way_info 取出对应那一路的 hit，命中才写 l0_bitmap

  logic       wakeup_delay_valid, wakeup_valid;
  l0_wake_t   wakeup_rdata   [L0_WAYS];   // DataHoldBypass 的输出
  l0_wake_t   wakeup_rdata_r [L0_WAYS];   // 保持寄存器
  logic [L0_WAYS-1:0] wakeup_vvec_delay;
  logic [1:0]         wakeup_hvec_delay [L0_WAYS];
  logic [L0_WAYS-1:0] wakeup_hitvec_delay, wakeup_hitvec;

  // 请求载荷打两拍（拍0->拍1->拍2）。
  // ★第二拍只留 set/way/idx/ok 四根★：tag 与 s2xlate 到拍2 已经没人读了
  //  （命中重算在拍1 就做完了），golden 里那两个寄存器被 firtool 消掉，照抄"不存"。
  //  多存一个就是 FM 上的一个 unread 点。
  logic [VPN_W-1:0] wk_d_tag;
  logic [5:0]       wk_d_set,  wk_set;
  logic [3:0]       wk_d_way,  wk_way;
  logic [2:0]       wk_d_idx,  wk_idx;
  logic             wk_d_ok,   wk_ok;
  logic [1:0]       wk_d_s2x;

  for (genvar w = 0; w < L0_WAYS; w++) begin : g_wakeup_hold
    always_comb begin
      wakeup_rdata[w] = wakeup_rdata_r[w];
      if (wakeup_delay_valid) begin
        wakeup_rdata[w].tag  = l0_sram_rdata[w].tag;
        wakeup_rdata[w].asid = l0_sram_rdata[w].asid;
        wakeup_rdata[w].vmid = l0_sram_rdata[w].vmid;
        wakeup_rdata[w].vs   = l0_sram_rdata[w].vs;
        for (int k = 0; k < SECTOR_N; k++)
          wakeup_rdata[w].g[k] = l0_sram_rdata[w].perms[k].g;
      end
    end
  end

  // 重算命中：与 §16 的 l0 命中同一个 PtwEntries.hit，只是 vpn/h 换成 wakeup 自己的。
  logic [1:0] wakeup_h;
  assign wakeup_h = fold_h(wk_d_s2x);

  always_comb
    for (int w = 0; w < L0_WAYS; w++)
      wakeup_hitvec_delay[w] =
          ((wakeup_h == H_ONLY_STAGE2)
           | (wakeup_rdata[w].asid == ((|wakeup_h) ? io_csr_dup_0_vsatp_asid
                                                   : io_csr_dup_0_satp_asid))
           | wakeup_rdata[w].g[wk_d_tag[2:0]])
        & (~(|wakeup_h) | ({2'h0, wakeup_rdata[w].vmid} == io_csr_dup_0_hgatp_vmid))
        & (wakeup_rdata[w].tag == wk_d_tag[37:9])
        & wakeup_rdata[w].vs[wk_d_tag[2:0]]
        & wakeup_vvec_delay[w] & (wakeup_h == wakeup_hvec_delay[w]);

  // way_info 是 one-hot，转成路号（4 路的 OHToUInt）
  logic [1:0] wakeup_way_idx;
  assign wakeup_way_idx = {wk_way[3] | wk_way[2], wk_way[3] | wk_way[1]};

  logic wakeup_write;
  assign wakeup_write = wakeup_valid & wakeup_hitvec[wakeup_way_idx];
  // ---------------------------------------------------------------------------
  // §11 时序：两个 always_ff，复位域划分照抄 golden（见 §4 的说明）
  //
  //  回填侧、命中侧、响应侧、栅栏失效侧的状态更新都在这里。
  //  ★golden 里没有 ecc flush★：KunminghuV2Config 下 l2tlbParams.enablePTWECC=false，
  //  eccError 恒 0，整段 l1eccFlush/l0eccFlush 被 firtool 消光了（golden 全文
  //  grep 不到一个 "ecc"）。所以这里"不写"就是照抄，不是缺口。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      l3v <= '0;  l2v <= '0;  l1v <= '0;  l0v <= '0;  spv <= '0;
      valid_delay <= 1'b0;  valid_check <= 1'b0;  valid_resp <= 1'b0;
      stage_delay_valid_1cycle <= 1'b0;  stage_check_valid_1cycle <= 1'b0;
      plru_l3 <= '0;  plru_l2 <= '0;  plru_sp <= '0;
      for (int s = 0; s < L1_SETS; s++) plru_l1[s] <= 1'b0;
      for (int s = 0; s < L0_SETS; s++) plru_l0[s] <= '0;
      for (int s = 0; s < L0_SETS; s++)
        for (int w = 0; w < L0_WAYS; w++)
          l0_bitmap[s][w] <= '0;
      bypass_release <= '0;  bypass_hold <= '0;  hptw_bypass_hold <= '0;
      wakeup_delay_valid <= 1'b0;  wakeup_valid <= 1'b0;
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
      // 两个 1 拍脉冲：本级这一拍收到了新数据（用作 DataHoldBypass / RegEnable 的使能）
      stage_delay_valid_1cycle <= ~flush_dup_0 & sram_read_fire;
      stage_check_valid_1cycle <= ~flush_dup_0 & left_fire_delay;

      // 有效位：回填把被选中的那一位置 1。
      if (l3_refill) l3v <= l3v | l3_rf_oh;
      if (l2_refill) l2v <= l2v | l2_rf_oh;
      if (l1_refill) l1v <= l1v | l1_rfv_oh;
      if (l0_refill) l0v <= l0v | l0_rfv_oh;
      if (sp_refill) spv <= spv | sp_rf_oh;

      // ★栅栏失效写在回填之后，顺序就是覆盖优先级★（Chisel 的 last-connect）：
      //   sfence.vma < hfence.vvma < hfence.gvma，三者又都压过同一拍的回填。
      //   l1/l2 只在 rs1=1 时被赋值、l3 只在 dup_2 的 rs1=1 时被赋值 ——
      //   ★这几个门不能省★，见 §21.1 的注释。掩码本身在 §21 算好。
      if (sfence_plain) begin
        l0v <= l0v & ~l0_sf_mask;
        spv <= spv & ~sp_sf_mask;
        if (sf_rs1) begin
          l1v <= l1v & ~l1_sf_mask;
          l2v <= l2v & ~l2_sf_mask;
        end
      end
      if (hfence_vvma) begin
        l0v <= l0v & ~l0_hv_mask;
        spv <= spv & ~sp_hv_mask;
        if (sf_rs1) begin
          l1v <= l1v & ~l1_hv_mask;
          l2v <= l2v & ~l2_hv_mask;
        end
      end
      if (hfence_gvma) begin
        l0v <= l0v & ~l0_hg_mask;
        spv <= spv & ~sp_hg_mask;
        if (sf_rs1) begin
          l1v <= l1v & ~l1_hg_mask;
          l2v <= l2v & ~l2_hg_mask;
        end
      end
      // l3 那一段在 golden 里独立成块（在三种栅栏之后），且只认 dup_2 的 rs1。
      if (l3_rs1) begin
        if (sfence_plain) l3v <= l3v & ~l3_sf_mask;
        if (hfence_vvma)  l3v <= l3v & ~l3_hv_mask;
        if (hfence_gvma)  l3v <= l3v & ~l3_hg_mask;
      end

      // §22 wakeup 的两拍 valid（与主流水一样被 flush_dup_0 清掉）
      wakeup_delay_valid <= ~flush_dup_0 & wakeup_harzad;
      wakeup_valid       <= ~flush_dup_0 & wakeup_delay_valid;

      // l0_bitmap 的两个写者。★顺序就是优先级★：golden 里 wakeup 那条写在前面
      // （l0 命中块内），l0 回填的清零写在后面（回填块内），所以**回填赢** ——
      // 于是 next = ~清零 & (wakeup 写 ? 新值 : 旧值)。
      //
      // ★必须写成"每拍都算一遍的表达式"，不能写成 `if (写使能) 才更新`★：
      //  wakeup 的写使能里含 wakeup_hitvec，而它来自 l0 SRAM —— 没写过的行在
      //  `+define+SYNTHESIS` 下回读是 X。golden（firtool 展开的正是上面那个表达式）
      //  会把 X 写进寄存器，而 `if (X)` 按假走会保住旧值。两者在 0/1 上同值。
      //  实测：改成本形状之前，20k 拍里这一处贡献 l0_bitmap[4] 的 golden=X/impl=0 失配。
      for (int s = 0; s < L0_SETS; s++)
        for (int w = 0; w < L0_WAYS; w++)
          for (int k = 0; k < SECTOR_N; k++)
            l0_bitmap[s][w][k] <=
              ~(l0_refill & l0_rfv_oh[L0_WAYS*s + w])
              & ((wakeup_write & (wk_set == 6'(s)) & (wakeup_way_idx == 2'(w))
                  & (wk_idx == 3'(k))) ? wk_ok : l0_bitmap[s][w][k]);

      // 替换状态。★这里就是 §7 记的那个 golden 真 bug 的落点★：
      //   plru_l3 只有"l3 命中"**一个**写者（l3 回填根本不碰它）；
      //   plru_l2 有三个写者，优先级 l2 回填 > **l3 回填** > l2 命中，
      //   而 l3 回填那一支喂进去的是 l3_refill_idx —— 照抄，不许"修好"。
      if (l3_hit_h & stage_delay_valid_1cycle)
        plru_l3 <= plru16_access(plru_l3, oh_to_uint16(l3_hitvec));

      if (l2_refill)      plru_l2 <= plru16_access(plru_l2, l2_refill_idx);
      else if (l3_refill) plru_l2 <= plru16_access(plru_l2, l3_refill_idx);
      else if (l2_hit_h & stage_delay_valid_1cycle)
        plru_l2 <= plru16_access(plru_l2, oh_to_uint16(l2_hitvec));

      if (sp_refill) plru_sp <= plru16_access(plru_sp, sp_refill_idx);
      else if (sp_hit_c & stage_delay_valid_1cycle)
        plru_sp <= plru16_access(plru_sp, oh_to_uint16(sp_hitvec));

      // l1/l0 是每组一份状态：回填与命中可能落在**不同的组**，两边都要更新；
      // 落在同一组时回填优先。所以按组写，不能写成两条互不相干的 if。
      for (int s = 0; s < L1_SETS; s++) begin
        if (l1_refill & (l1_w_set == s[$clog2(L1_SETS)-1:0]))
          plru_l1[s] <= ~l1_victim_way;
        else if (l1_hit & stage_check_valid_1cycle
                 & (check_vpn[13:12] == s[$clog2(L1_SETS)-1:0]))
          // 2 路的 access(way) = ~way，而 hitWay 是 ParallelPriorityMux ⇒ ~hitVec[0]，
          // 两个取反抵消，golden 直接写的就是 hitVec[0]。照抄这个形状。
          plru_l1[s] <= l1_hitvec[0];
      end
      for (int s = 0; s < L0_SETS; s++) begin
        if (l0_refill & (l0_w_set == s[$clog2(L0_SETS)-1:0]))
          plru_l0[s] <= plru4_access(plru_l0[s], l0_victim_way);
        else if (l0_hit & stage_check_valid_1cycle
                 & (check_vpn[8:3] == s[$clog2(L0_SETS)-1:0]))
          plru_l0[s] <= plru4_access(plru_l0[s], l0_hitway);
      end

      // §17 bypass 的三个带复位寄存器组（各 4 位，对应 l0/l1/l2/l3 四级）。
      // ★两个 hold 的清除条件不一样，别合并★：
      //   普通口 bypass_hold —— 新一拍进 stageResp 或又来一次 refill 就清；
      //   hptw 口 hptw_bypass_hold —— 只有 io.resp 真的握手走了才清。
      // bypass_release 是"新一拍进了 stageResp"的 1 拍脉冲，golden 存了**四份同值**的
      // 寄存器（每级一份），这里照抄成 4 位向量而不是 1 位，保住与 golden 的点对点对应。
      bypass_release <= {4{left_fire_check}};
      for (int i = 0; i < 4; i++) begin
        bypass_hold[i] <= ~(bypass_release[i] | io_refill_valid)
                        & (bypass_hit_resp[i] | bypass_hold[i]);
        hptw_bypass_hold[i] <= ~resp_fire & (bypass_hit_resp[i] | hptw_bypass_hold[i]);
      end
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

    // ---- §17 bypass 的跨拍记忆（不复位）----
    //  每一级记住"在本级停留期间有没有被 refill 覆盖过"：本级进新数据那一拍直接取
    //  当拍匹配值（把上一条请求的记忆冲掉），否则把新来的 refill 命中或进去。
    if (stage_delay_valid_1cycle) bypass_seen_delay <= bypass_hit_delay;
    else bypass_seen_delay <= ({4{io_refill_valid}} & bypass_hit_delay) | bypass_seen_delay;
    if (stage_check_valid_1cycle) bypass_seen_check <= bypass_hit_check;
    else bypass_seen_check <= ({4{io_refill_valid}} & bypass_hit_check) | bypass_seen_check;

    //  往下一级交班时把"当拍匹配 + 本级记忆"并进载荷。
    //  ★`& ~valid_1cycle` 这一项不是多余的★：本级这一拍刚进新数据时，记忆寄存器里
    //  还是上一条请求的值（它要到下一拍才更新），必须屏蔽掉。
    if (left_fire_delay)
      check_bypassed <= bypass_hit_delay
                      | (bypass_seen_delay & {4{~stage_delay_valid_1cycle}});
    if (left_fire_check)
      resp_bypassed <= check_bypassed | bypass_hit_check
                     | (bypass_seen_check & {4{~stage_check_valid_1cycle}});

    // ---- §18 命中结果快照（不复位）----
    if (left_fire_check) begin
      resp_res_l3.hit  <= l3_hit_ck;
      resp_res_l3.pre  <= l3_pre_ck;
      resp_res_l3.ppn  <= l3_ppn_ck;

      resp_res_l2.hit  <= l2_hit_ck;
      resp_res_l2.pre  <= l2_pre_ck;
      resp_res_l2.ppn  <= l2_ppn_ck;
      resp_res_l2.pbmt <= l2_pbmt_ck;

      resp_res_l1.hit  <= l1_hit;
      resp_res_l1.pre  <= l1_pre;
      resp_res_l1.ppn  <= l1_hit_ppn;
      resp_res_l1.pbmt <= l1_hit_pbmt;

      resp_res_l0.hit              <= l0_hit;
      resp_res_l0.pre              <= l0_pre;
      resp_res_l0.ppn              <= l0_hitdata.ppns;
      resp_res_l0.pbmt             <= l0_hitdata.pbmts;
      resp_res_l0.perm             <= l0_hitdata.perms;
      resp_res_l0.v                <= l0_valid;
      resp_res_l0.jmp_bitmap_check <= l0_jmp_bitmap;
      resp_res_l0.hitway           <= l0_hitway_oh;
      resp_res_l0.ptes             <= l0_ptes;
      resp_res_l0.cfs              <= l0_cfs;

      resp_res_sp.hit              <= sp_hit_ck;
      resp_res_sp.pre              <= sp_pre_ck;
      resp_res_sp.ppn              <= sp_hitdata_ck.ppn;
      resp_res_sp.pbmt             <= sp_hitdata_ck.pbmt;
      resp_res_sp.perm             <= sp_hitdata_ck.perm;
      resp_res_sp.n                <= sp_hitdata_ck.n;
      resp_res_sp.level            <= sp_hitdata_ck.level;
      resp_res_sp.v                <= sp_valid_ck;
      resp_res_sp.jmp_bitmap_check <= sp_jmp_bitmap_ck;
      resp_res_sp.pte              <= sp_pte;
    end

    // ---- §22 wakeup 的载荷与保持寄存器（不复位）----
    if (wakeup_harzad) begin
      wk_d_tag <= io_bitmap_wakeup_bits_tag;
      wk_d_set <= io_bitmap_wakeup_bits_setIndex;
      wk_d_way <= io_bitmap_wakeup_bits_way_info;
      wk_d_idx <= io_bitmap_wakeup_bits_pte_index;
      wk_d_ok  <= io_bitmap_wakeup_bits_check_success;
      wk_d_s2x <= io_bitmap_wakeup_bits_s2xlate;
      for (int w = 0; w < L0_WAYS; w++) begin
        wakeup_vvec_delay[w] <= l0v[L0_WAYS*io_bitmap_wakeup_bits_tag[8:3] + w];
        wakeup_hvec_delay[w] <= l0h[io_bitmap_wakeup_bits_tag[8:3]][w];
      end
    end
    if (wakeup_delay_valid) begin
      for (int w = 0; w < L0_WAYS; w++) begin
        wakeup_rdata_r[w].tag  <= l0_sram_rdata[w].tag;
        wakeup_rdata_r[w].asid <= l0_sram_rdata[w].asid;
        wakeup_rdata_r[w].vmid <= l0_sram_rdata[w].vmid;
        wakeup_rdata_r[w].vs   <= l0_sram_rdata[w].vs;
        for (int k = 0; k < SECTOR_N; k++)
          wakeup_rdata_r[w].g[k] <= l0_sram_rdata[w].perms[k].g;
      end
      wk_set <= wk_d_set;  wk_way <= wk_d_way;
      wk_idx <= wk_d_idx;  wk_ok  <= wk_d_ok;
      wakeup_hitvec <= wakeup_hitvec_delay;
    end

    // ---- §20 perf 事件打两拍（不复位）----
    perf_event_d1 <= perf_event;
    perf_event_d2 <= perf_event_d1;
  end

  // ---------------------------------------------------------------------------
  // §8 追清进度台账
  //
  // 这一节曾经是「未追清清单」：一张显式钉 0 的占位输出表，
  // 外加一句"任何人引用它们都会拿到错值"。★现在它是空的★ ——
  // 回填写数据(§6) / 替换与受害者选择(§7) / 回填侧状态(§9/§11) /
  // 流水载荷(§12) / 五级命中(§14-§16) / 响应装配(§17-§19) /
  // perf(§20) / 栅栏失效(§21) / bitmap wakeup(§22) 全部毕业。
  // ★下面这行"还剩几根"的数由生成器实测，不是手写的★，
  // 它是这份重写唯一一个随追清单调下降的进度量
  // （scripts/rewritten_floor.py 把钉 0 也算"被驱动"，在本模块上从一开始就饱和）。



  // ★455 个端口里的全部 236 个输出都已有真实驱动★（本行由生成器实测，不是声明）。
  // 早先那张"钉 0 占位"表已清空 —— 但**有驱动不等于驱动得对**，对不对是 UT 与 FM 的事。

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

