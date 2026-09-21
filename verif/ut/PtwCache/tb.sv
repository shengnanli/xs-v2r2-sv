// tb.sv —— PtwCache 的双例化逐拍差分 UT（verif/ut/PtwCache）。
//
// ★这份 tb 原来在 verif/study/PtwCache_refill/，头注释写着"不是验收 UT"，理由是
//  它只比 l1/l0 SRAM 的 430 根写端口、覆盖面窄得多。★那条理由已经不成立★：
//  现在它比的是 golden 端口表逐根量出的**全部 236 个输出** + 约 5000 根核内状态，
//  激励也覆盖了 sfence/hfence 三种栅栏与 bitmap wakeup。所以本轮把它移进 verif/ut/。
//
// 双例化 golden PtwCache 与派生的 PtwCache_xs，同拍同激励，用层次引用逐拍比两侧：
//   A  l1/l0 SRAM 的**全部写端口**（430 根，含 waymask）；
//   B  核内**回填侧状态**：l3v/l2v/l1v/l0v/spv、l3g..spg、五级 h、
//      l1asids/l1vmids/l0asids/l0vmids/l0vpns 影子哈希、三个 15 位 PLRU state_reg
//      + 4 个 l1 组状态 + 64 个 l0 组状态、l3/l2/sp 的全部表项字段；
//   C  核内**命中侧**：三级流水载荷与两个 1 拍脉冲、五级 hitVec、
//      l3/l2 的 DataHoldBypass 保持寄存器与 stageCheck 对齐寄存器、
//      sp 的 spHit/spHitData/spPre/spValid/spJmpBitmapCheck、
//      l1/l0 的 v/h/g 延迟向量与 data_resp_r / ramDatas 两级寄存器。
//   B+C 的两侧层次路径表由 gen_state_cmp.py 生成（支持 --check，已进 gate_all）。
//
//   D  ★全部 236 个输出★（由 gen_state_cmp.py 从 golden 端口表逐根量出，不手抄）；
//   E  §21 栅栏失效与 §22 bitmap wakeup 的状态：l0BitmapReg（64 组打包）、
//      bitmap 的两级流水副本、wakeup 三拍流水。
//
// ★它仍然不覆盖的★（如实列出，不是"应该没问题"）：
//   · ecc flush —— golden 里根本没有这段（enablePTWECC=false，golden 全文
//     grep 不到一个 "ecc"），所以不是缺口；
//   · MBIST/DFT 通路只被钉 0 驱动，boreChildrenBd_* 那一族输出比的是"两侧都不动"；
//   · 激励是随机的，不是定向的协议序列 —— 覆盖率由下面几个 fire 计数自证，
//     没有覆盖率工具的数据。
//
// 【激励为什么长这样（两条都是实测逼出来的，别"简化"回去）】
//   1. vpn 从一个 4 项的池子里取（四分之一仍全随机），csr 每 512 拍才换一次。
//      全随机时回填进去的条目下一拍就再也匹配不上，五级命中 fire 全是 0。
//   2. rand_pte 三分之一造一条**干净的** next 型 PTE（r/w/x=0,v=1，且 d/a/u/n/pbmt/
//      reserved/ppn_high 全清）。只清 r/w/x 不够：非叶子的 isPf 还查 u/a/d/n/pbmt，
//      随机值下九成判 pf，canRefill 过不去，l1 的 vs 位几乎恒 0 ——
//      实测 3000 拍里 l1 命中只有 2 次，补了这条之后是 51 次。
//   三份 dup 仍各取各的（各自独立但各自稳定），"dup 归属写错"的判别力保住了。
//
// 【判别力自证】
//   常态自证：五级回填的 fire 次数与五级命中的 fire 次数**都必须 > 0**，
//   否则那一段等于什么都没比，tb 自己判 FAIL。
//   注入过的 mutant（都不进库；下表是**一次跑完的一轮**：同一份激励、每个 mutant
//   都 make clean 全量重建、并先在产物里 grep 确认变异真的进去了，5000 拍 seed=1）：
//     H1 l1 命中的 asid 用 dup_0 的 csr（dup 归属写错）
//        -> errors=159138，首个失配 l1_hitvec[1]。抓到。
//     H2 sp 的 level==1 少比一段 tag（tm1）
//        -> errors=503184，首个失配 sp_hitvec[4]。抓到。
//        ★这条一开始是漏的★：只有"整条相同 / 整条随机"两种 vpn 时 errors=0。
//        补了近失 vpn（池子里的一条翻一位）才抓到 —— 见上面 pick_vpn。
//     H3 l3 的 vmid 比较去掉 16 位零扩展（只比低 14 位）
//        -> errors=381252，首个失配 l3_hitvec[0]。抓到。
//        ★这条一开始也是漏的★：hgatp_vmid 只喂 0..3 时两种写法值恒等。
//        补了 rand_vmid（四分之一带高位）才抓到。
//     H4 plru_l2 的三写者优先级：把 l2 命中提到 l3 回填前面（即"修好"那个 golden 真 bug）
//        -> errors=74774，首个失配 plru_l2。抓到。
//        ★这条是唯一能证明我们照抄了 golden 的 bug、而不是照抄了直觉的实验★
//     H5 ParallelPriorityMux 的 tie-break：全不中时取第 0 项而不是最后一项
//        -> errors=7343，首个失配 l3_ppn_r。抓到。
//     H6 l1 的 PLRU 命中更新写成 ~l1_hitvec[1] 而不是 l1_hitvec[0]
//        -> errors=0，**没抓到**。★这条是本对照的已知盲点，不是通过★：
//        两种写法只在 l1 两路**同时命中**时不同（hitVec=2'b11），那要求同一组里
//        两路的 tag/asid/vmid/h 全一样；本激励产生不出这种状态。
//        要覆盖它得专门构造"同组两路同 tag"的回填序列，记在这儿等后续补。
//   历史（更早只比写端口那一版记的，保留备查）：
//     A  pte_is_pf 的 napot 分支去掉 `| (level != 0)`  -> errors=0，**没抓到**。
//        查清了原因：level>0 时 ppn[3:0]==8 蕴含 ppn[8:0]!=0，紧接着的
//        unaligned(level) 对同一批输入也给 1，两者**值恒等**。所以这不是本对照的
//        漏洞，是这个 mutant 本身无效。（RTL 里那一项照抄保留。）
//     B  pbmte 改用 dup_1                             -> errors=6164 / 20000 拍，抓到。
//     C  pte_only_pf 去掉 `& ~pte_is_af(p)`           -> errors=28536 / 20000 拍，抓到。
//
// 【实测】基线 commit cd59b7cc2389122a7d35bfc7298d208a45103e54
//   （rtl/mmu/PtwCache.sv sha256 cf3579a77b0349647dfae49282952fa5ad9a8abe780728f9226e65ade68b623c）
//   golden = G1-a4ea14f2ddf612bb4ad023d26a2ca1bf33eddcaebe470b0c620e9fba0e7afcf0
//
//   两档 initreg × 3 seed × 200000 拍，每拍 3347 次比较，全部 errors=0：
//     make run          SEED=1|7|42 NCYCLES=200000   （运行期 +vcs+initreg+0）
//     make run-initreg1 SEED=1|7|42 NCYCLES=200000   （运行期 +vcs+initreg+1）
//
//   档  seed  checks      errors  sfence/hfv/hfg   wakeup/写   l1双命中/l0多命中  判定
//   ---------------------------------------------------------------------------------
//   ir0   1   669400000   0       1058/955/1016    8766/75     12318/425          TEST PASSED
//   ir0   7   669400000   0        994/1009/1062   8962/64     12548/277          TEST PASSED
//   ir0  42   669400000   0       1038/1029/1010   8924/44     13052/180          TEST PASSED
//   ir1   1   669400000   0       1058/955/1016    8766/75     12321/428          TEST PASSED
//   ir1   7   669400000   0        994/1009/1062   8962/64     12555/284          TEST PASSED
//   ir1  42   669400000   0       1038/1029/1010   8924/44     13054/182          TEST PASSED
//
//   ★两档的"双命中"计数**不同**（12318 vs 12321 等）是对的★：那些拍上有不复位
//   寄存器参与，两档初值不同会让边界拍的命中数差几次。差异**只**出现在计数上、
//   errors 两档都是 0 —— 也就是说没有 X 依赖的失配。
`timescale 1ns/1ps
module tb;
  int errors = 0;          // 已追清信号的失配 —— 一个都不许有
  int checks = 0;
  int ncycles;

  logic            io_csr_mPBMTE;
  logic            io_csr_hPBMTE;
  logic            g_io_req_ready, i_io_req_ready;
  logic            io_req_valid;
  logic [37:0]     io_req_bits_req_info_vpn;
  logic [1:0]      io_req_bits_req_info_s2xlate;
  logic [1:0]      io_req_bits_req_info_source;
  logic            io_req_bits_isFirst;
  logic            io_req_bits_isHptwReq;
  logic [2:0]      io_req_bits_hptwId;
  logic            io_resp_ready;
  logic            g_io_resp_valid, i_io_resp_valid;
  logic [37:0]     g_io_resp_bits_req_info_vpn, i_io_resp_bits_req_info_vpn;
  logic [1:0]      g_io_resp_bits_req_info_s2xlate, i_io_resp_bits_req_info_s2xlate;
  logic [1:0]      g_io_resp_bits_req_info_source, i_io_resp_bits_req_info_source;
  logic            g_io_resp_bits_isFirst, i_io_resp_bits_isFirst;
  logic            g_io_resp_bits_hit, i_io_resp_bits_hit;
  logic            g_io_resp_bits_prefetch, i_io_resp_bits_prefetch;
  logic            g_io_resp_bits_bypassed, i_io_resp_bits_bypassed;
  logic            g_io_resp_bits_toFsm_l3Hit, i_io_resp_bits_toFsm_l3Hit;
  logic            g_io_resp_bits_toFsm_l2Hit, i_io_resp_bits_toFsm_l2Hit;
  logic            g_io_resp_bits_toFsm_l1Hit, i_io_resp_bits_toFsm_l1Hit;
  logic [37:0]     g_io_resp_bits_toFsm_ppn, i_io_resp_bits_toFsm_ppn;
  logic            g_io_resp_bits_toFsm_stage1Hit, i_io_resp_bits_toFsm_stage1Hit;
  logic            g_io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check, i_io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check;
  logic            g_io_resp_bits_toFsm_bitmapCheck_toLLPTW, i_io_resp_bits_toFsm_bitmapCheck_toLLPTW;
  logic [3:0]      g_io_resp_bits_toFsm_bitmapCheck_hitway, i_io_resp_bits_toFsm_bitmapCheck_hitway;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_pte, i_io_resp_bits_toFsm_bitmapCheck_pte;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_ptes_0, i_io_resp_bits_toFsm_bitmapCheck_ptes_0;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_ptes_1, i_io_resp_bits_toFsm_bitmapCheck_ptes_1;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_ptes_2, i_io_resp_bits_toFsm_bitmapCheck_ptes_2;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_ptes_3, i_io_resp_bits_toFsm_bitmapCheck_ptes_3;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_ptes_4, i_io_resp_bits_toFsm_bitmapCheck_ptes_4;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_ptes_5, i_io_resp_bits_toFsm_bitmapCheck_ptes_5;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_ptes_6, i_io_resp_bits_toFsm_bitmapCheck_ptes_6;
  logic [63:0]     g_io_resp_bits_toFsm_bitmapCheck_ptes_7, i_io_resp_bits_toFsm_bitmapCheck_ptes_7;
  logic            g_io_resp_bits_toFsm_bitmapCheck_cfs_0, i_io_resp_bits_toFsm_bitmapCheck_cfs_0;
  logic            g_io_resp_bits_toFsm_bitmapCheck_cfs_1, i_io_resp_bits_toFsm_bitmapCheck_cfs_1;
  logic            g_io_resp_bits_toFsm_bitmapCheck_cfs_2, i_io_resp_bits_toFsm_bitmapCheck_cfs_2;
  logic            g_io_resp_bits_toFsm_bitmapCheck_cfs_3, i_io_resp_bits_toFsm_bitmapCheck_cfs_3;
  logic            g_io_resp_bits_toFsm_bitmapCheck_cfs_4, i_io_resp_bits_toFsm_bitmapCheck_cfs_4;
  logic            g_io_resp_bits_toFsm_bitmapCheck_cfs_5, i_io_resp_bits_toFsm_bitmapCheck_cfs_5;
  logic            g_io_resp_bits_toFsm_bitmapCheck_cfs_6, i_io_resp_bits_toFsm_bitmapCheck_cfs_6;
  logic            g_io_resp_bits_toFsm_bitmapCheck_cfs_7, i_io_resp_bits_toFsm_bitmapCheck_cfs_7;
  logic [1:0]      g_io_resp_bits_toFsm_bitmapCheck_SPlevel, i_io_resp_bits_toFsm_bitmapCheck_SPlevel;
  logic [34:0]     g_io_resp_bits_stage1_entry_0_tag, i_io_resp_bits_stage1_entry_0_tag;
  logic [15:0]     g_io_resp_bits_stage1_entry_0_asid, i_io_resp_bits_stage1_entry_0_asid;
  logic [13:0]     g_io_resp_bits_stage1_entry_0_vmid, i_io_resp_bits_stage1_entry_0_vmid;
  logic            g_io_resp_bits_stage1_entry_0_n, i_io_resp_bits_stage1_entry_0_n;
  logic [1:0]      g_io_resp_bits_stage1_entry_0_pbmt, i_io_resp_bits_stage1_entry_0_pbmt;
  logic            g_io_resp_bits_stage1_entry_0_perm_d, i_io_resp_bits_stage1_entry_0_perm_d;
  logic            g_io_resp_bits_stage1_entry_0_perm_a, i_io_resp_bits_stage1_entry_0_perm_a;
  logic            g_io_resp_bits_stage1_entry_0_perm_g, i_io_resp_bits_stage1_entry_0_perm_g;
  logic            g_io_resp_bits_stage1_entry_0_perm_u, i_io_resp_bits_stage1_entry_0_perm_u;
  logic            g_io_resp_bits_stage1_entry_0_perm_x, i_io_resp_bits_stage1_entry_0_perm_x;
  logic            g_io_resp_bits_stage1_entry_0_perm_w, i_io_resp_bits_stage1_entry_0_perm_w;
  logic            g_io_resp_bits_stage1_entry_0_perm_r, i_io_resp_bits_stage1_entry_0_perm_r;
  logic [1:0]      g_io_resp_bits_stage1_entry_0_level, i_io_resp_bits_stage1_entry_0_level;
  logic            g_io_resp_bits_stage1_entry_0_v, i_io_resp_bits_stage1_entry_0_v;
  logic [40:0]     g_io_resp_bits_stage1_entry_0_ppn, i_io_resp_bits_stage1_entry_0_ppn;
  logic [2:0]      g_io_resp_bits_stage1_entry_0_ppn_low, i_io_resp_bits_stage1_entry_0_ppn_low;
  logic            g_io_resp_bits_stage1_entry_0_pf, i_io_resp_bits_stage1_entry_0_pf;
  logic            g_io_resp_bits_stage1_entry_0_cf, i_io_resp_bits_stage1_entry_0_cf;
  logic [34:0]     g_io_resp_bits_stage1_entry_1_tag, i_io_resp_bits_stage1_entry_1_tag;
  logic [15:0]     g_io_resp_bits_stage1_entry_1_asid, i_io_resp_bits_stage1_entry_1_asid;
  logic [13:0]     g_io_resp_bits_stage1_entry_1_vmid, i_io_resp_bits_stage1_entry_1_vmid;
  logic            g_io_resp_bits_stage1_entry_1_n, i_io_resp_bits_stage1_entry_1_n;
  logic [1:0]      g_io_resp_bits_stage1_entry_1_pbmt, i_io_resp_bits_stage1_entry_1_pbmt;
  logic            g_io_resp_bits_stage1_entry_1_perm_d, i_io_resp_bits_stage1_entry_1_perm_d;
  logic            g_io_resp_bits_stage1_entry_1_perm_a, i_io_resp_bits_stage1_entry_1_perm_a;
  logic            g_io_resp_bits_stage1_entry_1_perm_g, i_io_resp_bits_stage1_entry_1_perm_g;
  logic            g_io_resp_bits_stage1_entry_1_perm_u, i_io_resp_bits_stage1_entry_1_perm_u;
  logic            g_io_resp_bits_stage1_entry_1_perm_x, i_io_resp_bits_stage1_entry_1_perm_x;
  logic            g_io_resp_bits_stage1_entry_1_perm_w, i_io_resp_bits_stage1_entry_1_perm_w;
  logic            g_io_resp_bits_stage1_entry_1_perm_r, i_io_resp_bits_stage1_entry_1_perm_r;
  logic [1:0]      g_io_resp_bits_stage1_entry_1_level, i_io_resp_bits_stage1_entry_1_level;
  logic            g_io_resp_bits_stage1_entry_1_v, i_io_resp_bits_stage1_entry_1_v;
  logic [40:0]     g_io_resp_bits_stage1_entry_1_ppn, i_io_resp_bits_stage1_entry_1_ppn;
  logic [2:0]      g_io_resp_bits_stage1_entry_1_ppn_low, i_io_resp_bits_stage1_entry_1_ppn_low;
  logic            g_io_resp_bits_stage1_entry_1_pf, i_io_resp_bits_stage1_entry_1_pf;
  logic            g_io_resp_bits_stage1_entry_1_cf, i_io_resp_bits_stage1_entry_1_cf;
  logic [34:0]     g_io_resp_bits_stage1_entry_2_tag, i_io_resp_bits_stage1_entry_2_tag;
  logic [15:0]     g_io_resp_bits_stage1_entry_2_asid, i_io_resp_bits_stage1_entry_2_asid;
  logic [13:0]     g_io_resp_bits_stage1_entry_2_vmid, i_io_resp_bits_stage1_entry_2_vmid;
  logic            g_io_resp_bits_stage1_entry_2_n, i_io_resp_bits_stage1_entry_2_n;
  logic [1:0]      g_io_resp_bits_stage1_entry_2_pbmt, i_io_resp_bits_stage1_entry_2_pbmt;
  logic            g_io_resp_bits_stage1_entry_2_perm_d, i_io_resp_bits_stage1_entry_2_perm_d;
  logic            g_io_resp_bits_stage1_entry_2_perm_a, i_io_resp_bits_stage1_entry_2_perm_a;
  logic            g_io_resp_bits_stage1_entry_2_perm_g, i_io_resp_bits_stage1_entry_2_perm_g;
  logic            g_io_resp_bits_stage1_entry_2_perm_u, i_io_resp_bits_stage1_entry_2_perm_u;
  logic            g_io_resp_bits_stage1_entry_2_perm_x, i_io_resp_bits_stage1_entry_2_perm_x;
  logic            g_io_resp_bits_stage1_entry_2_perm_w, i_io_resp_bits_stage1_entry_2_perm_w;
  logic            g_io_resp_bits_stage1_entry_2_perm_r, i_io_resp_bits_stage1_entry_2_perm_r;
  logic [1:0]      g_io_resp_bits_stage1_entry_2_level, i_io_resp_bits_stage1_entry_2_level;
  logic            g_io_resp_bits_stage1_entry_2_v, i_io_resp_bits_stage1_entry_2_v;
  logic [40:0]     g_io_resp_bits_stage1_entry_2_ppn, i_io_resp_bits_stage1_entry_2_ppn;
  logic [2:0]      g_io_resp_bits_stage1_entry_2_ppn_low, i_io_resp_bits_stage1_entry_2_ppn_low;
  logic            g_io_resp_bits_stage1_entry_2_pf, i_io_resp_bits_stage1_entry_2_pf;
  logic            g_io_resp_bits_stage1_entry_2_cf, i_io_resp_bits_stage1_entry_2_cf;
  logic [34:0]     g_io_resp_bits_stage1_entry_3_tag, i_io_resp_bits_stage1_entry_3_tag;
  logic [15:0]     g_io_resp_bits_stage1_entry_3_asid, i_io_resp_bits_stage1_entry_3_asid;
  logic [13:0]     g_io_resp_bits_stage1_entry_3_vmid, i_io_resp_bits_stage1_entry_3_vmid;
  logic            g_io_resp_bits_stage1_entry_3_n, i_io_resp_bits_stage1_entry_3_n;
  logic [1:0]      g_io_resp_bits_stage1_entry_3_pbmt, i_io_resp_bits_stage1_entry_3_pbmt;
  logic            g_io_resp_bits_stage1_entry_3_perm_d, i_io_resp_bits_stage1_entry_3_perm_d;
  logic            g_io_resp_bits_stage1_entry_3_perm_a, i_io_resp_bits_stage1_entry_3_perm_a;
  logic            g_io_resp_bits_stage1_entry_3_perm_g, i_io_resp_bits_stage1_entry_3_perm_g;
  logic            g_io_resp_bits_stage1_entry_3_perm_u, i_io_resp_bits_stage1_entry_3_perm_u;
  logic            g_io_resp_bits_stage1_entry_3_perm_x, i_io_resp_bits_stage1_entry_3_perm_x;
  logic            g_io_resp_bits_stage1_entry_3_perm_w, i_io_resp_bits_stage1_entry_3_perm_w;
  logic            g_io_resp_bits_stage1_entry_3_perm_r, i_io_resp_bits_stage1_entry_3_perm_r;
  logic [1:0]      g_io_resp_bits_stage1_entry_3_level, i_io_resp_bits_stage1_entry_3_level;
  logic            g_io_resp_bits_stage1_entry_3_v, i_io_resp_bits_stage1_entry_3_v;
  logic [40:0]     g_io_resp_bits_stage1_entry_3_ppn, i_io_resp_bits_stage1_entry_3_ppn;
  logic [2:0]      g_io_resp_bits_stage1_entry_3_ppn_low, i_io_resp_bits_stage1_entry_3_ppn_low;
  logic            g_io_resp_bits_stage1_entry_3_pf, i_io_resp_bits_stage1_entry_3_pf;
  logic            g_io_resp_bits_stage1_entry_3_cf, i_io_resp_bits_stage1_entry_3_cf;
  logic [34:0]     g_io_resp_bits_stage1_entry_4_tag, i_io_resp_bits_stage1_entry_4_tag;
  logic [15:0]     g_io_resp_bits_stage1_entry_4_asid, i_io_resp_bits_stage1_entry_4_asid;
  logic [13:0]     g_io_resp_bits_stage1_entry_4_vmid, i_io_resp_bits_stage1_entry_4_vmid;
  logic            g_io_resp_bits_stage1_entry_4_n, i_io_resp_bits_stage1_entry_4_n;
  logic [1:0]      g_io_resp_bits_stage1_entry_4_pbmt, i_io_resp_bits_stage1_entry_4_pbmt;
  logic            g_io_resp_bits_stage1_entry_4_perm_d, i_io_resp_bits_stage1_entry_4_perm_d;
  logic            g_io_resp_bits_stage1_entry_4_perm_a, i_io_resp_bits_stage1_entry_4_perm_a;
  logic            g_io_resp_bits_stage1_entry_4_perm_g, i_io_resp_bits_stage1_entry_4_perm_g;
  logic            g_io_resp_bits_stage1_entry_4_perm_u, i_io_resp_bits_stage1_entry_4_perm_u;
  logic            g_io_resp_bits_stage1_entry_4_perm_x, i_io_resp_bits_stage1_entry_4_perm_x;
  logic            g_io_resp_bits_stage1_entry_4_perm_w, i_io_resp_bits_stage1_entry_4_perm_w;
  logic            g_io_resp_bits_stage1_entry_4_perm_r, i_io_resp_bits_stage1_entry_4_perm_r;
  logic [1:0]      g_io_resp_bits_stage1_entry_4_level, i_io_resp_bits_stage1_entry_4_level;
  logic            g_io_resp_bits_stage1_entry_4_v, i_io_resp_bits_stage1_entry_4_v;
  logic [40:0]     g_io_resp_bits_stage1_entry_4_ppn, i_io_resp_bits_stage1_entry_4_ppn;
  logic [2:0]      g_io_resp_bits_stage1_entry_4_ppn_low, i_io_resp_bits_stage1_entry_4_ppn_low;
  logic            g_io_resp_bits_stage1_entry_4_pf, i_io_resp_bits_stage1_entry_4_pf;
  logic            g_io_resp_bits_stage1_entry_4_cf, i_io_resp_bits_stage1_entry_4_cf;
  logic [34:0]     g_io_resp_bits_stage1_entry_5_tag, i_io_resp_bits_stage1_entry_5_tag;
  logic [15:0]     g_io_resp_bits_stage1_entry_5_asid, i_io_resp_bits_stage1_entry_5_asid;
  logic [13:0]     g_io_resp_bits_stage1_entry_5_vmid, i_io_resp_bits_stage1_entry_5_vmid;
  logic            g_io_resp_bits_stage1_entry_5_n, i_io_resp_bits_stage1_entry_5_n;
  logic [1:0]      g_io_resp_bits_stage1_entry_5_pbmt, i_io_resp_bits_stage1_entry_5_pbmt;
  logic            g_io_resp_bits_stage1_entry_5_perm_d, i_io_resp_bits_stage1_entry_5_perm_d;
  logic            g_io_resp_bits_stage1_entry_5_perm_a, i_io_resp_bits_stage1_entry_5_perm_a;
  logic            g_io_resp_bits_stage1_entry_5_perm_g, i_io_resp_bits_stage1_entry_5_perm_g;
  logic            g_io_resp_bits_stage1_entry_5_perm_u, i_io_resp_bits_stage1_entry_5_perm_u;
  logic            g_io_resp_bits_stage1_entry_5_perm_x, i_io_resp_bits_stage1_entry_5_perm_x;
  logic            g_io_resp_bits_stage1_entry_5_perm_w, i_io_resp_bits_stage1_entry_5_perm_w;
  logic            g_io_resp_bits_stage1_entry_5_perm_r, i_io_resp_bits_stage1_entry_5_perm_r;
  logic [1:0]      g_io_resp_bits_stage1_entry_5_level, i_io_resp_bits_stage1_entry_5_level;
  logic            g_io_resp_bits_stage1_entry_5_v, i_io_resp_bits_stage1_entry_5_v;
  logic [40:0]     g_io_resp_bits_stage1_entry_5_ppn, i_io_resp_bits_stage1_entry_5_ppn;
  logic [2:0]      g_io_resp_bits_stage1_entry_5_ppn_low, i_io_resp_bits_stage1_entry_5_ppn_low;
  logic            g_io_resp_bits_stage1_entry_5_pf, i_io_resp_bits_stage1_entry_5_pf;
  logic            g_io_resp_bits_stage1_entry_5_cf, i_io_resp_bits_stage1_entry_5_cf;
  logic [34:0]     g_io_resp_bits_stage1_entry_6_tag, i_io_resp_bits_stage1_entry_6_tag;
  logic [15:0]     g_io_resp_bits_stage1_entry_6_asid, i_io_resp_bits_stage1_entry_6_asid;
  logic [13:0]     g_io_resp_bits_stage1_entry_6_vmid, i_io_resp_bits_stage1_entry_6_vmid;
  logic            g_io_resp_bits_stage1_entry_6_n, i_io_resp_bits_stage1_entry_6_n;
  logic [1:0]      g_io_resp_bits_stage1_entry_6_pbmt, i_io_resp_bits_stage1_entry_6_pbmt;
  logic            g_io_resp_bits_stage1_entry_6_perm_d, i_io_resp_bits_stage1_entry_6_perm_d;
  logic            g_io_resp_bits_stage1_entry_6_perm_a, i_io_resp_bits_stage1_entry_6_perm_a;
  logic            g_io_resp_bits_stage1_entry_6_perm_g, i_io_resp_bits_stage1_entry_6_perm_g;
  logic            g_io_resp_bits_stage1_entry_6_perm_u, i_io_resp_bits_stage1_entry_6_perm_u;
  logic            g_io_resp_bits_stage1_entry_6_perm_x, i_io_resp_bits_stage1_entry_6_perm_x;
  logic            g_io_resp_bits_stage1_entry_6_perm_w, i_io_resp_bits_stage1_entry_6_perm_w;
  logic            g_io_resp_bits_stage1_entry_6_perm_r, i_io_resp_bits_stage1_entry_6_perm_r;
  logic [1:0]      g_io_resp_bits_stage1_entry_6_level, i_io_resp_bits_stage1_entry_6_level;
  logic            g_io_resp_bits_stage1_entry_6_v, i_io_resp_bits_stage1_entry_6_v;
  logic [40:0]     g_io_resp_bits_stage1_entry_6_ppn, i_io_resp_bits_stage1_entry_6_ppn;
  logic [2:0]      g_io_resp_bits_stage1_entry_6_ppn_low, i_io_resp_bits_stage1_entry_6_ppn_low;
  logic            g_io_resp_bits_stage1_entry_6_pf, i_io_resp_bits_stage1_entry_6_pf;
  logic            g_io_resp_bits_stage1_entry_6_cf, i_io_resp_bits_stage1_entry_6_cf;
  logic [34:0]     g_io_resp_bits_stage1_entry_7_tag, i_io_resp_bits_stage1_entry_7_tag;
  logic [15:0]     g_io_resp_bits_stage1_entry_7_asid, i_io_resp_bits_stage1_entry_7_asid;
  logic [13:0]     g_io_resp_bits_stage1_entry_7_vmid, i_io_resp_bits_stage1_entry_7_vmid;
  logic            g_io_resp_bits_stage1_entry_7_n, i_io_resp_bits_stage1_entry_7_n;
  logic [1:0]      g_io_resp_bits_stage1_entry_7_pbmt, i_io_resp_bits_stage1_entry_7_pbmt;
  logic            g_io_resp_bits_stage1_entry_7_perm_d, i_io_resp_bits_stage1_entry_7_perm_d;
  logic            g_io_resp_bits_stage1_entry_7_perm_a, i_io_resp_bits_stage1_entry_7_perm_a;
  logic            g_io_resp_bits_stage1_entry_7_perm_g, i_io_resp_bits_stage1_entry_7_perm_g;
  logic            g_io_resp_bits_stage1_entry_7_perm_u, i_io_resp_bits_stage1_entry_7_perm_u;
  logic            g_io_resp_bits_stage1_entry_7_perm_x, i_io_resp_bits_stage1_entry_7_perm_x;
  logic            g_io_resp_bits_stage1_entry_7_perm_w, i_io_resp_bits_stage1_entry_7_perm_w;
  logic            g_io_resp_bits_stage1_entry_7_perm_r, i_io_resp_bits_stage1_entry_7_perm_r;
  logic [1:0]      g_io_resp_bits_stage1_entry_7_level, i_io_resp_bits_stage1_entry_7_level;
  logic            g_io_resp_bits_stage1_entry_7_v, i_io_resp_bits_stage1_entry_7_v;
  logic [40:0]     g_io_resp_bits_stage1_entry_7_ppn, i_io_resp_bits_stage1_entry_7_ppn;
  logic [2:0]      g_io_resp_bits_stage1_entry_7_ppn_low, i_io_resp_bits_stage1_entry_7_ppn_low;
  logic            g_io_resp_bits_stage1_entry_7_pf, i_io_resp_bits_stage1_entry_7_pf;
  logic            g_io_resp_bits_stage1_entry_7_cf, i_io_resp_bits_stage1_entry_7_cf;
  logic            g_io_resp_bits_stage1_pteidx_0, i_io_resp_bits_stage1_pteidx_0;
  logic            g_io_resp_bits_stage1_pteidx_1, i_io_resp_bits_stage1_pteidx_1;
  logic            g_io_resp_bits_stage1_pteidx_2, i_io_resp_bits_stage1_pteidx_2;
  logic            g_io_resp_bits_stage1_pteidx_3, i_io_resp_bits_stage1_pteidx_3;
  logic            g_io_resp_bits_stage1_pteidx_4, i_io_resp_bits_stage1_pteidx_4;
  logic            g_io_resp_bits_stage1_pteidx_5, i_io_resp_bits_stage1_pteidx_5;
  logic            g_io_resp_bits_stage1_pteidx_6, i_io_resp_bits_stage1_pteidx_6;
  logic            g_io_resp_bits_stage1_pteidx_7, i_io_resp_bits_stage1_pteidx_7;
  logic            g_io_resp_bits_stage1_not_super, i_io_resp_bits_stage1_not_super;
  logic            g_io_resp_bits_isHptwReq, i_io_resp_bits_isHptwReq;
  logic            g_io_resp_bits_toHptw_l3Hit, i_io_resp_bits_toHptw_l3Hit;
  logic            g_io_resp_bits_toHptw_l2Hit, i_io_resp_bits_toHptw_l2Hit;
  logic            g_io_resp_bits_toHptw_l1Hit, i_io_resp_bits_toHptw_l1Hit;
  logic [35:0]     g_io_resp_bits_toHptw_ppn, i_io_resp_bits_toHptw_ppn;
  logic [2:0]      g_io_resp_bits_toHptw_id, i_io_resp_bits_toHptw_id;
  logic [37:0]     g_io_resp_bits_toHptw_resp_entry_tag, i_io_resp_bits_toHptw_resp_entry_tag;
  logic [13:0]     g_io_resp_bits_toHptw_resp_entry_vmid, i_io_resp_bits_toHptw_resp_entry_vmid;
  logic            g_io_resp_bits_toHptw_resp_entry_n, i_io_resp_bits_toHptw_resp_entry_n;
  logic [1:0]      g_io_resp_bits_toHptw_resp_entry_pbmt, i_io_resp_bits_toHptw_resp_entry_pbmt;
  logic [37:0]     g_io_resp_bits_toHptw_resp_entry_ppn, i_io_resp_bits_toHptw_resp_entry_ppn;
  logic            g_io_resp_bits_toHptw_resp_entry_perm_d, i_io_resp_bits_toHptw_resp_entry_perm_d;
  logic            g_io_resp_bits_toHptw_resp_entry_perm_a, i_io_resp_bits_toHptw_resp_entry_perm_a;
  logic            g_io_resp_bits_toHptw_resp_entry_perm_g, i_io_resp_bits_toHptw_resp_entry_perm_g;
  logic            g_io_resp_bits_toHptw_resp_entry_perm_u, i_io_resp_bits_toHptw_resp_entry_perm_u;
  logic            g_io_resp_bits_toHptw_resp_entry_perm_x, i_io_resp_bits_toHptw_resp_entry_perm_x;
  logic            g_io_resp_bits_toHptw_resp_entry_perm_w, i_io_resp_bits_toHptw_resp_entry_perm_w;
  logic            g_io_resp_bits_toHptw_resp_entry_perm_r, i_io_resp_bits_toHptw_resp_entry_perm_r;
  logic [1:0]      g_io_resp_bits_toHptw_resp_entry_level, i_io_resp_bits_toHptw_resp_entry_level;
  logic            g_io_resp_bits_toHptw_resp_gpf, i_io_resp_bits_toHptw_resp_gpf;
  logic            g_io_resp_bits_toHptw_bypassed, i_io_resp_bits_toHptw_bypassed;
  logic            g_io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check, i_io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check;
  logic [3:0]      g_io_resp_bits_toHptw_bitmapCheck_hitway, i_io_resp_bits_toHptw_bitmapCheck_hitway;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_pte, i_io_resp_bits_toHptw_bitmapCheck_pte;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_ptes_0, i_io_resp_bits_toHptw_bitmapCheck_ptes_0;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_ptes_1, i_io_resp_bits_toHptw_bitmapCheck_ptes_1;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_ptes_2, i_io_resp_bits_toHptw_bitmapCheck_ptes_2;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_ptes_3, i_io_resp_bits_toHptw_bitmapCheck_ptes_3;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_ptes_4, i_io_resp_bits_toHptw_bitmapCheck_ptes_4;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_ptes_5, i_io_resp_bits_toHptw_bitmapCheck_ptes_5;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_ptes_6, i_io_resp_bits_toHptw_bitmapCheck_ptes_6;
  logic [63:0]     g_io_resp_bits_toHptw_bitmapCheck_ptes_7, i_io_resp_bits_toHptw_bitmapCheck_ptes_7;
  logic            g_io_resp_bits_toHptw_bitmapCheck_fromSP, i_io_resp_bits_toHptw_bitmapCheck_fromSP;
  logic [1:0]      g_io_resp_bits_toHptw_bitmapCheck_SPlevel, i_io_resp_bits_toHptw_bitmapCheck_SPlevel;
  logic            io_refill_valid;
  logic [511:0]    io_refill_bits_ptes;
  logic            io_refill_bits_levelOH_sp;
  logic            io_refill_bits_levelOH_l0;
  logic            io_refill_bits_levelOH_l1;
  logic            io_refill_bits_levelOH_l2;
  logic            io_refill_bits_levelOH_l3;
  logic [37:0]     io_refill_bits_req_info_dup_0_vpn;
  logic [1:0]      io_refill_bits_req_info_dup_0_s2xlate;
  logic [1:0]      io_refill_bits_req_info_dup_0_source;
  logic [37:0]     io_refill_bits_req_info_dup_1_vpn;
  logic [1:0]      io_refill_bits_req_info_dup_1_s2xlate;
  logic [1:0]      io_refill_bits_req_info_dup_1_source;
  logic [37:0]     io_refill_bits_req_info_dup_2_vpn;
  logic [1:0]      io_refill_bits_req_info_dup_2_s2xlate;
  logic [1:0]      io_refill_bits_req_info_dup_2_source;
  logic [1:0]      io_refill_bits_level_dup_0;
  logic [1:0]      io_refill_bits_level_dup_2;
  logic [63:0]     io_refill_bits_sel_pte_dup_0;
  logic [63:0]     io_refill_bits_sel_pte_dup_2;
  logic [3:0]      g_io_l0_way_info, i_io_l0_way_info;
  logic            io_sfence_dup_0_valid;
  logic            io_sfence_dup_0_bits_rs1;
  logic            io_sfence_dup_0_bits_rs2;
  logic [49:0]     io_sfence_dup_0_bits_addr;
  logic [15:0]     io_sfence_dup_0_bits_id;
  logic            io_sfence_dup_0_bits_hv;
  logic            io_sfence_dup_0_bits_hg;
  logic            io_sfence_dup_1_valid;
  logic [15:0]     io_sfence_dup_1_bits_id;
  logic            io_sfence_dup_2_valid;
  logic            io_sfence_dup_2_bits_rs1;
  logic            io_sfence_dup_2_bits_rs2;
  logic [15:0]     io_sfence_dup_2_bits_id;
  logic [15:0]     io_csr_dup_0_satp_asid;
  logic            io_csr_dup_0_satp_changed;
  logic [15:0]     io_csr_dup_0_vsatp_asid;
  logic            io_csr_dup_0_vsatp_changed;
  logic [3:0]      io_csr_dup_0_hgatp_mode;
  logic [15:0]     io_csr_dup_0_hgatp_vmid;
  logic            io_csr_dup_0_hgatp_changed;
  logic            io_csr_dup_0_mbmc_BME;
  logic            io_csr_dup_0_mbmc_CMODE;
  logic            io_csr_dup_0_priv_virt;
  logic            io_csr_dup_0_priv_virt_changed;
  logic [15:0]     io_csr_dup_1_satp_asid;
  logic            io_csr_dup_1_satp_changed;
  logic [15:0]     io_csr_dup_1_vsatp_asid;
  logic            io_csr_dup_1_vsatp_changed;
  logic [3:0]      io_csr_dup_1_hgatp_mode;
  logic [15:0]     io_csr_dup_1_hgatp_vmid;
  logic            io_csr_dup_1_hgatp_changed;
  logic            io_csr_dup_1_priv_virt;
  logic            io_csr_dup_1_priv_virt_changed;
  logic [15:0]     io_csr_dup_2_satp_asid;
  logic            io_csr_dup_2_satp_changed;
  logic [15:0]     io_csr_dup_2_vsatp_asid;
  logic            io_csr_dup_2_vsatp_changed;
  logic [3:0]      io_csr_dup_2_hgatp_mode;
  logic [15:0]     io_csr_dup_2_hgatp_vmid;
  logic            io_csr_dup_2_hgatp_changed;
  logic            io_csr_dup_2_priv_virt;
  logic            io_csr_dup_2_priv_virt_changed;
  logic            g_io_bitmap_wakeup_ready, i_io_bitmap_wakeup_ready;
  logic            io_bitmap_wakeup_valid;
  logic [5:0]      io_bitmap_wakeup_bits_setIndex;
  logic [37:0]     io_bitmap_wakeup_bits_tag;
  logic [3:0]      io_bitmap_wakeup_bits_way_info;
  logic [2:0]      io_bitmap_wakeup_bits_pte_index;
  logic            io_bitmap_wakeup_bits_check_success;
  logic [1:0]      io_bitmap_wakeup_bits_s2xlate;
  logic [5:0]      g_io_perf_0_value, i_io_perf_0_value;
  logic [5:0]      g_io_perf_1_value, i_io_perf_1_value;
  logic [5:0]      g_io_perf_2_value, i_io_perf_2_value;
  logic [5:0]      g_io_perf_3_value, i_io_perf_3_value;
  logic [5:0]      g_io_perf_4_value, i_io_perf_4_value;
  logic [5:0]      g_io_perf_5_value, i_io_perf_5_value;
  logic [5:0]      g_io_perf_6_value, i_io_perf_6_value;
  logic [5:0]      g_io_perf_7_value, i_io_perf_7_value;
  logic [5:0]      boreChildrenBd_bore_array;
  logic            boreChildrenBd_bore_all;
  logic            boreChildrenBd_bore_req;
  logic            g_boreChildrenBd_bore_ack, i_boreChildrenBd_bore_ack;
  logic            boreChildrenBd_bore_writeen;
  logic            boreChildrenBd_bore_be;
  logic [2:0]      boreChildrenBd_bore_addr;
  logic [130:0]    boreChildrenBd_bore_indata;
  logic            boreChildrenBd_bore_readen;
  logic [2:0]      boreChildrenBd_bore_addr_rd;
  logic [130:0]    g_boreChildrenBd_bore_outdata, i_boreChildrenBd_bore_outdata;
  logic [6:0]      boreChildrenBd_bore_1_array;
  logic            boreChildrenBd_bore_1_all;
  logic            boreChildrenBd_bore_1_req;
  logic            g_boreChildrenBd_bore_1_ack, i_boreChildrenBd_bore_1_ack;
  logic            boreChildrenBd_bore_1_writeen;
  logic [1:0]      boreChildrenBd_bore_1_be;
  logic [6:0]      boreChildrenBd_bore_1_addr;
  logic [113:0]    boreChildrenBd_bore_1_indata;
  logic            boreChildrenBd_bore_1_readen;
  logic [6:0]      boreChildrenBd_bore_1_addr_rd;
  logic [113:0]    g_boreChildrenBd_bore_1_outdata, i_boreChildrenBd_bore_1_outdata;
  logic            sigFromSrams_bore_ram_hold;
  logic            sigFromSrams_bore_ram_bypass;
  logic            sigFromSrams_bore_ram_bp_clken;
  logic            sigFromSrams_bore_ram_aux_clk;
  logic            sigFromSrams_bore_ram_aux_ckbp;
  logic            sigFromSrams_bore_ram_mcp_hold;
  logic            sigFromSrams_bore_cgen;
  logic            sigFromSrams_bore_1_ram_hold;
  logic            sigFromSrams_bore_1_ram_bypass;
  logic            sigFromSrams_bore_1_ram_bp_clken;
  logic            sigFromSrams_bore_1_ram_aux_clk;
  logic            sigFromSrams_bore_1_ram_aux_ckbp;
  logic            sigFromSrams_bore_1_ram_mcp_hold;
  logic            sigFromSrams_bore_1_cgen;
  logic            sigFromSrams_bore_2_ram_hold;
  logic            sigFromSrams_bore_2_ram_bypass;
  logic            sigFromSrams_bore_2_ram_bp_clken;
  logic            sigFromSrams_bore_2_ram_aux_clk;
  logic            sigFromSrams_bore_2_ram_aux_ckbp;
  logic            sigFromSrams_bore_2_ram_mcp_hold;
  logic            sigFromSrams_bore_2_cgen;
  logic            sigFromSrams_bore_3_ram_hold;
  logic            sigFromSrams_bore_3_ram_bypass;
  logic            sigFromSrams_bore_3_ram_bp_clken;
  logic            sigFromSrams_bore_3_ram_aux_clk;
  logic            sigFromSrams_bore_3_ram_aux_ckbp;
  logic            sigFromSrams_bore_3_ram_mcp_hold;
  logic            sigFromSrams_bore_3_cgen;
  logic            sigFromSrams_bore_4_ram_hold;
  logic            sigFromSrams_bore_4_ram_bypass;
  logic            sigFromSrams_bore_4_ram_bp_clken;
  logic            sigFromSrams_bore_4_ram_aux_clk;
  logic            sigFromSrams_bore_4_ram_aux_ckbp;
  logic            sigFromSrams_bore_4_ram_mcp_hold;
  logic            sigFromSrams_bore_4_cgen;
  logic            sigFromSrams_bore_5_ram_hold;
  logic            sigFromSrams_bore_5_ram_bypass;
  logic            sigFromSrams_bore_5_ram_bp_clken;
  logic            sigFromSrams_bore_5_ram_aux_clk;
  logic            sigFromSrams_bore_5_ram_aux_ckbp;
  logic            sigFromSrams_bore_5_ram_mcp_hold;
  logic            sigFromSrams_bore_5_cgen;
  logic            sigFromSrams_bore_6_ram_hold;
  logic            sigFromSrams_bore_6_ram_bypass;
  logic            sigFromSrams_bore_6_ram_bp_clken;
  logic            sigFromSrams_bore_6_ram_aux_clk;
  logic            sigFromSrams_bore_6_ram_aux_ckbp;
  logic            sigFromSrams_bore_6_ram_mcp_hold;
  logic            sigFromSrams_bore_6_cgen;
  logic            sigFromSrams_bore_7_ram_hold;
  logic            sigFromSrams_bore_7_ram_bypass;
  logic            sigFromSrams_bore_7_ram_bp_clken;
  logic            sigFromSrams_bore_7_ram_aux_clk;
  logic            sigFromSrams_bore_7_ram_aux_ckbp;
  logic            sigFromSrams_bore_7_ram_mcp_hold;
  logic            sigFromSrams_bore_7_cgen;
  logic            sigFromSrams_bore_8_ram_hold;
  logic            sigFromSrams_bore_8_ram_bypass;
  logic            sigFromSrams_bore_8_ram_bp_clken;
  logic            sigFromSrams_bore_8_ram_aux_clk;
  logic            sigFromSrams_bore_8_ram_aux_ckbp;
  logic            sigFromSrams_bore_8_ram_mcp_hold;
  logic            sigFromSrams_bore_8_cgen;
  logic            sigFromSrams_bore_9_ram_hold;
  logic            sigFromSrams_bore_9_ram_bypass;
  logic            sigFromSrams_bore_9_ram_bp_clken;
  logic            sigFromSrams_bore_9_ram_aux_clk;
  logic            sigFromSrams_bore_9_ram_aux_ckbp;
  logic            sigFromSrams_bore_9_ram_mcp_hold;
  logic            sigFromSrams_bore_9_cgen;
  logic            sigFromSrams_bore_10_ram_hold;
  logic            sigFromSrams_bore_10_ram_bypass;
  logic            sigFromSrams_bore_10_ram_bp_clken;
  logic            sigFromSrams_bore_10_ram_aux_clk;
  logic            sigFromSrams_bore_10_ram_aux_ckbp;
  logic            sigFromSrams_bore_10_ram_mcp_hold;
  logic            sigFromSrams_bore_10_cgen;
  logic            sigFromSrams_bore_11_ram_hold;
  logic            sigFromSrams_bore_11_ram_bypass;
  logic            sigFromSrams_bore_11_ram_bp_clken;
  logic            sigFromSrams_bore_11_ram_aux_clk;
  logic            sigFromSrams_bore_11_ram_aux_ckbp;
  logic            sigFromSrams_bore_11_ram_mcp_hold;
  logic            sigFromSrams_bore_11_cgen;
  logic            sigFromSrams_bore_12_ram_hold;
  logic            sigFromSrams_bore_12_ram_bypass;
  logic            sigFromSrams_bore_12_ram_bp_clken;
  logic            sigFromSrams_bore_12_ram_aux_clk;
  logic            sigFromSrams_bore_12_ram_aux_ckbp;
  logic            sigFromSrams_bore_12_ram_mcp_hold;
  logic            sigFromSrams_bore_12_cgen;
  logic            sigFromSrams_bore_13_ram_hold;
  logic            sigFromSrams_bore_13_ram_bypass;
  logic            sigFromSrams_bore_13_ram_bp_clken;
  logic            sigFromSrams_bore_13_ram_aux_clk;
  logic            sigFromSrams_bore_13_ram_aux_ckbp;
  logic            sigFromSrams_bore_13_ram_mcp_hold;
  logic            sigFromSrams_bore_13_cgen;
  logic            sigFromSrams_bore_14_ram_hold;
  logic            sigFromSrams_bore_14_ram_bypass;
  logic            sigFromSrams_bore_14_ram_bp_clken;
  logic            sigFromSrams_bore_14_ram_aux_clk;
  logic            sigFromSrams_bore_14_ram_aux_ckbp;
  logic            sigFromSrams_bore_14_ram_mcp_hold;
  logic            sigFromSrams_bore_14_cgen;
  logic            sigFromSrams_bore_15_ram_hold;
  logic            sigFromSrams_bore_15_ram_bypass;
  logic            sigFromSrams_bore_15_ram_bp_clken;
  logic            sigFromSrams_bore_15_ram_aux_clk;
  logic            sigFromSrams_bore_15_ram_aux_ckbp;
  logic            sigFromSrams_bore_15_ram_mcp_hold;
  logic            sigFromSrams_bore_15_cgen;
  logic            sigFromSrams_bore_16_ram_hold;
  logic            sigFromSrams_bore_16_ram_bypass;
  logic            sigFromSrams_bore_16_ram_bp_clken;
  logic            sigFromSrams_bore_16_ram_aux_clk;
  logic            sigFromSrams_bore_16_ram_aux_ckbp;
  logic            sigFromSrams_bore_16_ram_mcp_hold;
  logic            sigFromSrams_bore_16_cgen;
  logic            cg_bore_cgen;
  logic clock = 1'b0;
  logic reset = 1'b1;
  always #5 clock = ~clock;

  PtwCache dut_g (
    .clock                                      (clock),
    .reset                                      (reset),
    .io_csr_mPBMTE                              (io_csr_mPBMTE),
    .io_csr_hPBMTE                              (io_csr_hPBMTE),
    .io_req_ready                               (g_io_req_ready),
    .io_req_valid                               (io_req_valid),
    .io_req_bits_req_info_vpn                   (io_req_bits_req_info_vpn),
    .io_req_bits_req_info_s2xlate               (io_req_bits_req_info_s2xlate),
    .io_req_bits_req_info_source                (io_req_bits_req_info_source),
    .io_req_bits_isFirst                        (io_req_bits_isFirst),
    .io_req_bits_isHptwReq                      (io_req_bits_isHptwReq),
    .io_req_bits_hptwId                         (io_req_bits_hptwId),
    .io_resp_ready                              (io_resp_ready),
    .io_resp_valid                              (g_io_resp_valid),
    .io_resp_bits_req_info_vpn                  (g_io_resp_bits_req_info_vpn),
    .io_resp_bits_req_info_s2xlate              (g_io_resp_bits_req_info_s2xlate),
    .io_resp_bits_req_info_source               (g_io_resp_bits_req_info_source),
    .io_resp_bits_isFirst                       (g_io_resp_bits_isFirst),
    .io_resp_bits_hit                           (g_io_resp_bits_hit),
    .io_resp_bits_prefetch                      (g_io_resp_bits_prefetch),
    .io_resp_bits_bypassed                      (g_io_resp_bits_bypassed),
    .io_resp_bits_toFsm_l3Hit                   (g_io_resp_bits_toFsm_l3Hit),
    .io_resp_bits_toFsm_l2Hit                   (g_io_resp_bits_toFsm_l2Hit),
    .io_resp_bits_toFsm_l1Hit                   (g_io_resp_bits_toFsm_l1Hit),
    .io_resp_bits_toFsm_ppn                     (g_io_resp_bits_toFsm_ppn),
    .io_resp_bits_toFsm_stage1Hit               (g_io_resp_bits_toFsm_stage1Hit),
    .io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check (g_io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check),
    .io_resp_bits_toFsm_bitmapCheck_toLLPTW     (g_io_resp_bits_toFsm_bitmapCheck_toLLPTW),
    .io_resp_bits_toFsm_bitmapCheck_hitway      (g_io_resp_bits_toFsm_bitmapCheck_hitway),
    .io_resp_bits_toFsm_bitmapCheck_pte         (g_io_resp_bits_toFsm_bitmapCheck_pte),
    .io_resp_bits_toFsm_bitmapCheck_ptes_0      (g_io_resp_bits_toFsm_bitmapCheck_ptes_0),
    .io_resp_bits_toFsm_bitmapCheck_ptes_1      (g_io_resp_bits_toFsm_bitmapCheck_ptes_1),
    .io_resp_bits_toFsm_bitmapCheck_ptes_2      (g_io_resp_bits_toFsm_bitmapCheck_ptes_2),
    .io_resp_bits_toFsm_bitmapCheck_ptes_3      (g_io_resp_bits_toFsm_bitmapCheck_ptes_3),
    .io_resp_bits_toFsm_bitmapCheck_ptes_4      (g_io_resp_bits_toFsm_bitmapCheck_ptes_4),
    .io_resp_bits_toFsm_bitmapCheck_ptes_5      (g_io_resp_bits_toFsm_bitmapCheck_ptes_5),
    .io_resp_bits_toFsm_bitmapCheck_ptes_6      (g_io_resp_bits_toFsm_bitmapCheck_ptes_6),
    .io_resp_bits_toFsm_bitmapCheck_ptes_7      (g_io_resp_bits_toFsm_bitmapCheck_ptes_7),
    .io_resp_bits_toFsm_bitmapCheck_cfs_0       (g_io_resp_bits_toFsm_bitmapCheck_cfs_0),
    .io_resp_bits_toFsm_bitmapCheck_cfs_1       (g_io_resp_bits_toFsm_bitmapCheck_cfs_1),
    .io_resp_bits_toFsm_bitmapCheck_cfs_2       (g_io_resp_bits_toFsm_bitmapCheck_cfs_2),
    .io_resp_bits_toFsm_bitmapCheck_cfs_3       (g_io_resp_bits_toFsm_bitmapCheck_cfs_3),
    .io_resp_bits_toFsm_bitmapCheck_cfs_4       (g_io_resp_bits_toFsm_bitmapCheck_cfs_4),
    .io_resp_bits_toFsm_bitmapCheck_cfs_5       (g_io_resp_bits_toFsm_bitmapCheck_cfs_5),
    .io_resp_bits_toFsm_bitmapCheck_cfs_6       (g_io_resp_bits_toFsm_bitmapCheck_cfs_6),
    .io_resp_bits_toFsm_bitmapCheck_cfs_7       (g_io_resp_bits_toFsm_bitmapCheck_cfs_7),
    .io_resp_bits_toFsm_bitmapCheck_SPlevel     (g_io_resp_bits_toFsm_bitmapCheck_SPlevel),
    .io_resp_bits_stage1_entry_0_tag            (g_io_resp_bits_stage1_entry_0_tag),
    .io_resp_bits_stage1_entry_0_asid           (g_io_resp_bits_stage1_entry_0_asid),
    .io_resp_bits_stage1_entry_0_vmid           (g_io_resp_bits_stage1_entry_0_vmid),
    .io_resp_bits_stage1_entry_0_n              (g_io_resp_bits_stage1_entry_0_n),
    .io_resp_bits_stage1_entry_0_pbmt           (g_io_resp_bits_stage1_entry_0_pbmt),
    .io_resp_bits_stage1_entry_0_perm_d         (g_io_resp_bits_stage1_entry_0_perm_d),
    .io_resp_bits_stage1_entry_0_perm_a         (g_io_resp_bits_stage1_entry_0_perm_a),
    .io_resp_bits_stage1_entry_0_perm_g         (g_io_resp_bits_stage1_entry_0_perm_g),
    .io_resp_bits_stage1_entry_0_perm_u         (g_io_resp_bits_stage1_entry_0_perm_u),
    .io_resp_bits_stage1_entry_0_perm_x         (g_io_resp_bits_stage1_entry_0_perm_x),
    .io_resp_bits_stage1_entry_0_perm_w         (g_io_resp_bits_stage1_entry_0_perm_w),
    .io_resp_bits_stage1_entry_0_perm_r         (g_io_resp_bits_stage1_entry_0_perm_r),
    .io_resp_bits_stage1_entry_0_level          (g_io_resp_bits_stage1_entry_0_level),
    .io_resp_bits_stage1_entry_0_v              (g_io_resp_bits_stage1_entry_0_v),
    .io_resp_bits_stage1_entry_0_ppn            (g_io_resp_bits_stage1_entry_0_ppn),
    .io_resp_bits_stage1_entry_0_ppn_low        (g_io_resp_bits_stage1_entry_0_ppn_low),
    .io_resp_bits_stage1_entry_0_pf             (g_io_resp_bits_stage1_entry_0_pf),
    .io_resp_bits_stage1_entry_0_cf             (g_io_resp_bits_stage1_entry_0_cf),
    .io_resp_bits_stage1_entry_1_tag            (g_io_resp_bits_stage1_entry_1_tag),
    .io_resp_bits_stage1_entry_1_asid           (g_io_resp_bits_stage1_entry_1_asid),
    .io_resp_bits_stage1_entry_1_vmid           (g_io_resp_bits_stage1_entry_1_vmid),
    .io_resp_bits_stage1_entry_1_n              (g_io_resp_bits_stage1_entry_1_n),
    .io_resp_bits_stage1_entry_1_pbmt           (g_io_resp_bits_stage1_entry_1_pbmt),
    .io_resp_bits_stage1_entry_1_perm_d         (g_io_resp_bits_stage1_entry_1_perm_d),
    .io_resp_bits_stage1_entry_1_perm_a         (g_io_resp_bits_stage1_entry_1_perm_a),
    .io_resp_bits_stage1_entry_1_perm_g         (g_io_resp_bits_stage1_entry_1_perm_g),
    .io_resp_bits_stage1_entry_1_perm_u         (g_io_resp_bits_stage1_entry_1_perm_u),
    .io_resp_bits_stage1_entry_1_perm_x         (g_io_resp_bits_stage1_entry_1_perm_x),
    .io_resp_bits_stage1_entry_1_perm_w         (g_io_resp_bits_stage1_entry_1_perm_w),
    .io_resp_bits_stage1_entry_1_perm_r         (g_io_resp_bits_stage1_entry_1_perm_r),
    .io_resp_bits_stage1_entry_1_level          (g_io_resp_bits_stage1_entry_1_level),
    .io_resp_bits_stage1_entry_1_v              (g_io_resp_bits_stage1_entry_1_v),
    .io_resp_bits_stage1_entry_1_ppn            (g_io_resp_bits_stage1_entry_1_ppn),
    .io_resp_bits_stage1_entry_1_ppn_low        (g_io_resp_bits_stage1_entry_1_ppn_low),
    .io_resp_bits_stage1_entry_1_pf             (g_io_resp_bits_stage1_entry_1_pf),
    .io_resp_bits_stage1_entry_1_cf             (g_io_resp_bits_stage1_entry_1_cf),
    .io_resp_bits_stage1_entry_2_tag            (g_io_resp_bits_stage1_entry_2_tag),
    .io_resp_bits_stage1_entry_2_asid           (g_io_resp_bits_stage1_entry_2_asid),
    .io_resp_bits_stage1_entry_2_vmid           (g_io_resp_bits_stage1_entry_2_vmid),
    .io_resp_bits_stage1_entry_2_n              (g_io_resp_bits_stage1_entry_2_n),
    .io_resp_bits_stage1_entry_2_pbmt           (g_io_resp_bits_stage1_entry_2_pbmt),
    .io_resp_bits_stage1_entry_2_perm_d         (g_io_resp_bits_stage1_entry_2_perm_d),
    .io_resp_bits_stage1_entry_2_perm_a         (g_io_resp_bits_stage1_entry_2_perm_a),
    .io_resp_bits_stage1_entry_2_perm_g         (g_io_resp_bits_stage1_entry_2_perm_g),
    .io_resp_bits_stage1_entry_2_perm_u         (g_io_resp_bits_stage1_entry_2_perm_u),
    .io_resp_bits_stage1_entry_2_perm_x         (g_io_resp_bits_stage1_entry_2_perm_x),
    .io_resp_bits_stage1_entry_2_perm_w         (g_io_resp_bits_stage1_entry_2_perm_w),
    .io_resp_bits_stage1_entry_2_perm_r         (g_io_resp_bits_stage1_entry_2_perm_r),
    .io_resp_bits_stage1_entry_2_level          (g_io_resp_bits_stage1_entry_2_level),
    .io_resp_bits_stage1_entry_2_v              (g_io_resp_bits_stage1_entry_2_v),
    .io_resp_bits_stage1_entry_2_ppn            (g_io_resp_bits_stage1_entry_2_ppn),
    .io_resp_bits_stage1_entry_2_ppn_low        (g_io_resp_bits_stage1_entry_2_ppn_low),
    .io_resp_bits_stage1_entry_2_pf             (g_io_resp_bits_stage1_entry_2_pf),
    .io_resp_bits_stage1_entry_2_cf             (g_io_resp_bits_stage1_entry_2_cf),
    .io_resp_bits_stage1_entry_3_tag            (g_io_resp_bits_stage1_entry_3_tag),
    .io_resp_bits_stage1_entry_3_asid           (g_io_resp_bits_stage1_entry_3_asid),
    .io_resp_bits_stage1_entry_3_vmid           (g_io_resp_bits_stage1_entry_3_vmid),
    .io_resp_bits_stage1_entry_3_n              (g_io_resp_bits_stage1_entry_3_n),
    .io_resp_bits_stage1_entry_3_pbmt           (g_io_resp_bits_stage1_entry_3_pbmt),
    .io_resp_bits_stage1_entry_3_perm_d         (g_io_resp_bits_stage1_entry_3_perm_d),
    .io_resp_bits_stage1_entry_3_perm_a         (g_io_resp_bits_stage1_entry_3_perm_a),
    .io_resp_bits_stage1_entry_3_perm_g         (g_io_resp_bits_stage1_entry_3_perm_g),
    .io_resp_bits_stage1_entry_3_perm_u         (g_io_resp_bits_stage1_entry_3_perm_u),
    .io_resp_bits_stage1_entry_3_perm_x         (g_io_resp_bits_stage1_entry_3_perm_x),
    .io_resp_bits_stage1_entry_3_perm_w         (g_io_resp_bits_stage1_entry_3_perm_w),
    .io_resp_bits_stage1_entry_3_perm_r         (g_io_resp_bits_stage1_entry_3_perm_r),
    .io_resp_bits_stage1_entry_3_level          (g_io_resp_bits_stage1_entry_3_level),
    .io_resp_bits_stage1_entry_3_v              (g_io_resp_bits_stage1_entry_3_v),
    .io_resp_bits_stage1_entry_3_ppn            (g_io_resp_bits_stage1_entry_3_ppn),
    .io_resp_bits_stage1_entry_3_ppn_low        (g_io_resp_bits_stage1_entry_3_ppn_low),
    .io_resp_bits_stage1_entry_3_pf             (g_io_resp_bits_stage1_entry_3_pf),
    .io_resp_bits_stage1_entry_3_cf             (g_io_resp_bits_stage1_entry_3_cf),
    .io_resp_bits_stage1_entry_4_tag            (g_io_resp_bits_stage1_entry_4_tag),
    .io_resp_bits_stage1_entry_4_asid           (g_io_resp_bits_stage1_entry_4_asid),
    .io_resp_bits_stage1_entry_4_vmid           (g_io_resp_bits_stage1_entry_4_vmid),
    .io_resp_bits_stage1_entry_4_n              (g_io_resp_bits_stage1_entry_4_n),
    .io_resp_bits_stage1_entry_4_pbmt           (g_io_resp_bits_stage1_entry_4_pbmt),
    .io_resp_bits_stage1_entry_4_perm_d         (g_io_resp_bits_stage1_entry_4_perm_d),
    .io_resp_bits_stage1_entry_4_perm_a         (g_io_resp_bits_stage1_entry_4_perm_a),
    .io_resp_bits_stage1_entry_4_perm_g         (g_io_resp_bits_stage1_entry_4_perm_g),
    .io_resp_bits_stage1_entry_4_perm_u         (g_io_resp_bits_stage1_entry_4_perm_u),
    .io_resp_bits_stage1_entry_4_perm_x         (g_io_resp_bits_stage1_entry_4_perm_x),
    .io_resp_bits_stage1_entry_4_perm_w         (g_io_resp_bits_stage1_entry_4_perm_w),
    .io_resp_bits_stage1_entry_4_perm_r         (g_io_resp_bits_stage1_entry_4_perm_r),
    .io_resp_bits_stage1_entry_4_level          (g_io_resp_bits_stage1_entry_4_level),
    .io_resp_bits_stage1_entry_4_v              (g_io_resp_bits_stage1_entry_4_v),
    .io_resp_bits_stage1_entry_4_ppn            (g_io_resp_bits_stage1_entry_4_ppn),
    .io_resp_bits_stage1_entry_4_ppn_low        (g_io_resp_bits_stage1_entry_4_ppn_low),
    .io_resp_bits_stage1_entry_4_pf             (g_io_resp_bits_stage1_entry_4_pf),
    .io_resp_bits_stage1_entry_4_cf             (g_io_resp_bits_stage1_entry_4_cf),
    .io_resp_bits_stage1_entry_5_tag            (g_io_resp_bits_stage1_entry_5_tag),
    .io_resp_bits_stage1_entry_5_asid           (g_io_resp_bits_stage1_entry_5_asid),
    .io_resp_bits_stage1_entry_5_vmid           (g_io_resp_bits_stage1_entry_5_vmid),
    .io_resp_bits_stage1_entry_5_n              (g_io_resp_bits_stage1_entry_5_n),
    .io_resp_bits_stage1_entry_5_pbmt           (g_io_resp_bits_stage1_entry_5_pbmt),
    .io_resp_bits_stage1_entry_5_perm_d         (g_io_resp_bits_stage1_entry_5_perm_d),
    .io_resp_bits_stage1_entry_5_perm_a         (g_io_resp_bits_stage1_entry_5_perm_a),
    .io_resp_bits_stage1_entry_5_perm_g         (g_io_resp_bits_stage1_entry_5_perm_g),
    .io_resp_bits_stage1_entry_5_perm_u         (g_io_resp_bits_stage1_entry_5_perm_u),
    .io_resp_bits_stage1_entry_5_perm_x         (g_io_resp_bits_stage1_entry_5_perm_x),
    .io_resp_bits_stage1_entry_5_perm_w         (g_io_resp_bits_stage1_entry_5_perm_w),
    .io_resp_bits_stage1_entry_5_perm_r         (g_io_resp_bits_stage1_entry_5_perm_r),
    .io_resp_bits_stage1_entry_5_level          (g_io_resp_bits_stage1_entry_5_level),
    .io_resp_bits_stage1_entry_5_v              (g_io_resp_bits_stage1_entry_5_v),
    .io_resp_bits_stage1_entry_5_ppn            (g_io_resp_bits_stage1_entry_5_ppn),
    .io_resp_bits_stage1_entry_5_ppn_low        (g_io_resp_bits_stage1_entry_5_ppn_low),
    .io_resp_bits_stage1_entry_5_pf             (g_io_resp_bits_stage1_entry_5_pf),
    .io_resp_bits_stage1_entry_5_cf             (g_io_resp_bits_stage1_entry_5_cf),
    .io_resp_bits_stage1_entry_6_tag            (g_io_resp_bits_stage1_entry_6_tag),
    .io_resp_bits_stage1_entry_6_asid           (g_io_resp_bits_stage1_entry_6_asid),
    .io_resp_bits_stage1_entry_6_vmid           (g_io_resp_bits_stage1_entry_6_vmid),
    .io_resp_bits_stage1_entry_6_n              (g_io_resp_bits_stage1_entry_6_n),
    .io_resp_bits_stage1_entry_6_pbmt           (g_io_resp_bits_stage1_entry_6_pbmt),
    .io_resp_bits_stage1_entry_6_perm_d         (g_io_resp_bits_stage1_entry_6_perm_d),
    .io_resp_bits_stage1_entry_6_perm_a         (g_io_resp_bits_stage1_entry_6_perm_a),
    .io_resp_bits_stage1_entry_6_perm_g         (g_io_resp_bits_stage1_entry_6_perm_g),
    .io_resp_bits_stage1_entry_6_perm_u         (g_io_resp_bits_stage1_entry_6_perm_u),
    .io_resp_bits_stage1_entry_6_perm_x         (g_io_resp_bits_stage1_entry_6_perm_x),
    .io_resp_bits_stage1_entry_6_perm_w         (g_io_resp_bits_stage1_entry_6_perm_w),
    .io_resp_bits_stage1_entry_6_perm_r         (g_io_resp_bits_stage1_entry_6_perm_r),
    .io_resp_bits_stage1_entry_6_level          (g_io_resp_bits_stage1_entry_6_level),
    .io_resp_bits_stage1_entry_6_v              (g_io_resp_bits_stage1_entry_6_v),
    .io_resp_bits_stage1_entry_6_ppn            (g_io_resp_bits_stage1_entry_6_ppn),
    .io_resp_bits_stage1_entry_6_ppn_low        (g_io_resp_bits_stage1_entry_6_ppn_low),
    .io_resp_bits_stage1_entry_6_pf             (g_io_resp_bits_stage1_entry_6_pf),
    .io_resp_bits_stage1_entry_6_cf             (g_io_resp_bits_stage1_entry_6_cf),
    .io_resp_bits_stage1_entry_7_tag            (g_io_resp_bits_stage1_entry_7_tag),
    .io_resp_bits_stage1_entry_7_asid           (g_io_resp_bits_stage1_entry_7_asid),
    .io_resp_bits_stage1_entry_7_vmid           (g_io_resp_bits_stage1_entry_7_vmid),
    .io_resp_bits_stage1_entry_7_n              (g_io_resp_bits_stage1_entry_7_n),
    .io_resp_bits_stage1_entry_7_pbmt           (g_io_resp_bits_stage1_entry_7_pbmt),
    .io_resp_bits_stage1_entry_7_perm_d         (g_io_resp_bits_stage1_entry_7_perm_d),
    .io_resp_bits_stage1_entry_7_perm_a         (g_io_resp_bits_stage1_entry_7_perm_a),
    .io_resp_bits_stage1_entry_7_perm_g         (g_io_resp_bits_stage1_entry_7_perm_g),
    .io_resp_bits_stage1_entry_7_perm_u         (g_io_resp_bits_stage1_entry_7_perm_u),
    .io_resp_bits_stage1_entry_7_perm_x         (g_io_resp_bits_stage1_entry_7_perm_x),
    .io_resp_bits_stage1_entry_7_perm_w         (g_io_resp_bits_stage1_entry_7_perm_w),
    .io_resp_bits_stage1_entry_7_perm_r         (g_io_resp_bits_stage1_entry_7_perm_r),
    .io_resp_bits_stage1_entry_7_level          (g_io_resp_bits_stage1_entry_7_level),
    .io_resp_bits_stage1_entry_7_v              (g_io_resp_bits_stage1_entry_7_v),
    .io_resp_bits_stage1_entry_7_ppn            (g_io_resp_bits_stage1_entry_7_ppn),
    .io_resp_bits_stage1_entry_7_ppn_low        (g_io_resp_bits_stage1_entry_7_ppn_low),
    .io_resp_bits_stage1_entry_7_pf             (g_io_resp_bits_stage1_entry_7_pf),
    .io_resp_bits_stage1_entry_7_cf             (g_io_resp_bits_stage1_entry_7_cf),
    .io_resp_bits_stage1_pteidx_0               (g_io_resp_bits_stage1_pteidx_0),
    .io_resp_bits_stage1_pteidx_1               (g_io_resp_bits_stage1_pteidx_1),
    .io_resp_bits_stage1_pteidx_2               (g_io_resp_bits_stage1_pteidx_2),
    .io_resp_bits_stage1_pteidx_3               (g_io_resp_bits_stage1_pteidx_3),
    .io_resp_bits_stage1_pteidx_4               (g_io_resp_bits_stage1_pteidx_4),
    .io_resp_bits_stage1_pteidx_5               (g_io_resp_bits_stage1_pteidx_5),
    .io_resp_bits_stage1_pteidx_6               (g_io_resp_bits_stage1_pteidx_6),
    .io_resp_bits_stage1_pteidx_7               (g_io_resp_bits_stage1_pteidx_7),
    .io_resp_bits_stage1_not_super              (g_io_resp_bits_stage1_not_super),
    .io_resp_bits_isHptwReq                     (g_io_resp_bits_isHptwReq),
    .io_resp_bits_toHptw_l3Hit                  (g_io_resp_bits_toHptw_l3Hit),
    .io_resp_bits_toHptw_l2Hit                  (g_io_resp_bits_toHptw_l2Hit),
    .io_resp_bits_toHptw_l1Hit                  (g_io_resp_bits_toHptw_l1Hit),
    .io_resp_bits_toHptw_ppn                    (g_io_resp_bits_toHptw_ppn),
    .io_resp_bits_toHptw_id                     (g_io_resp_bits_toHptw_id),
    .io_resp_bits_toHptw_resp_entry_tag         (g_io_resp_bits_toHptw_resp_entry_tag),
    .io_resp_bits_toHptw_resp_entry_vmid        (g_io_resp_bits_toHptw_resp_entry_vmid),
    .io_resp_bits_toHptw_resp_entry_n           (g_io_resp_bits_toHptw_resp_entry_n),
    .io_resp_bits_toHptw_resp_entry_pbmt        (g_io_resp_bits_toHptw_resp_entry_pbmt),
    .io_resp_bits_toHptw_resp_entry_ppn         (g_io_resp_bits_toHptw_resp_entry_ppn),
    .io_resp_bits_toHptw_resp_entry_perm_d      (g_io_resp_bits_toHptw_resp_entry_perm_d),
    .io_resp_bits_toHptw_resp_entry_perm_a      (g_io_resp_bits_toHptw_resp_entry_perm_a),
    .io_resp_bits_toHptw_resp_entry_perm_g      (g_io_resp_bits_toHptw_resp_entry_perm_g),
    .io_resp_bits_toHptw_resp_entry_perm_u      (g_io_resp_bits_toHptw_resp_entry_perm_u),
    .io_resp_bits_toHptw_resp_entry_perm_x      (g_io_resp_bits_toHptw_resp_entry_perm_x),
    .io_resp_bits_toHptw_resp_entry_perm_w      (g_io_resp_bits_toHptw_resp_entry_perm_w),
    .io_resp_bits_toHptw_resp_entry_perm_r      (g_io_resp_bits_toHptw_resp_entry_perm_r),
    .io_resp_bits_toHptw_resp_entry_level       (g_io_resp_bits_toHptw_resp_entry_level),
    .io_resp_bits_toHptw_resp_gpf               (g_io_resp_bits_toHptw_resp_gpf),
    .io_resp_bits_toHptw_bypassed               (g_io_resp_bits_toHptw_bypassed),
    .io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check (g_io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check),
    .io_resp_bits_toHptw_bitmapCheck_hitway     (g_io_resp_bits_toHptw_bitmapCheck_hitway),
    .io_resp_bits_toHptw_bitmapCheck_pte        (g_io_resp_bits_toHptw_bitmapCheck_pte),
    .io_resp_bits_toHptw_bitmapCheck_ptes_0     (g_io_resp_bits_toHptw_bitmapCheck_ptes_0),
    .io_resp_bits_toHptw_bitmapCheck_ptes_1     (g_io_resp_bits_toHptw_bitmapCheck_ptes_1),
    .io_resp_bits_toHptw_bitmapCheck_ptes_2     (g_io_resp_bits_toHptw_bitmapCheck_ptes_2),
    .io_resp_bits_toHptw_bitmapCheck_ptes_3     (g_io_resp_bits_toHptw_bitmapCheck_ptes_3),
    .io_resp_bits_toHptw_bitmapCheck_ptes_4     (g_io_resp_bits_toHptw_bitmapCheck_ptes_4),
    .io_resp_bits_toHptw_bitmapCheck_ptes_5     (g_io_resp_bits_toHptw_bitmapCheck_ptes_5),
    .io_resp_bits_toHptw_bitmapCheck_ptes_6     (g_io_resp_bits_toHptw_bitmapCheck_ptes_6),
    .io_resp_bits_toHptw_bitmapCheck_ptes_7     (g_io_resp_bits_toHptw_bitmapCheck_ptes_7),
    .io_resp_bits_toHptw_bitmapCheck_fromSP     (g_io_resp_bits_toHptw_bitmapCheck_fromSP),
    .io_resp_bits_toHptw_bitmapCheck_SPlevel    (g_io_resp_bits_toHptw_bitmapCheck_SPlevel),
    .io_refill_valid                            (io_refill_valid),
    .io_refill_bits_ptes                        (io_refill_bits_ptes),
    .io_refill_bits_levelOH_sp                  (io_refill_bits_levelOH_sp),
    .io_refill_bits_levelOH_l0                  (io_refill_bits_levelOH_l0),
    .io_refill_bits_levelOH_l1                  (io_refill_bits_levelOH_l1),
    .io_refill_bits_levelOH_l2                  (io_refill_bits_levelOH_l2),
    .io_refill_bits_levelOH_l3                  (io_refill_bits_levelOH_l3),
    .io_refill_bits_req_info_dup_0_vpn          (io_refill_bits_req_info_dup_0_vpn),
    .io_refill_bits_req_info_dup_0_s2xlate      (io_refill_bits_req_info_dup_0_s2xlate),
    .io_refill_bits_req_info_dup_0_source       (io_refill_bits_req_info_dup_0_source),
    .io_refill_bits_req_info_dup_1_vpn          (io_refill_bits_req_info_dup_1_vpn),
    .io_refill_bits_req_info_dup_1_s2xlate      (io_refill_bits_req_info_dup_1_s2xlate),
    .io_refill_bits_req_info_dup_1_source       (io_refill_bits_req_info_dup_1_source),
    .io_refill_bits_req_info_dup_2_vpn          (io_refill_bits_req_info_dup_2_vpn),
    .io_refill_bits_req_info_dup_2_s2xlate      (io_refill_bits_req_info_dup_2_s2xlate),
    .io_refill_bits_req_info_dup_2_source       (io_refill_bits_req_info_dup_2_source),
    .io_refill_bits_level_dup_0                 (io_refill_bits_level_dup_0),
    .io_refill_bits_level_dup_2                 (io_refill_bits_level_dup_2),
    .io_refill_bits_sel_pte_dup_0               (io_refill_bits_sel_pte_dup_0),
    .io_refill_bits_sel_pte_dup_2               (io_refill_bits_sel_pte_dup_2),
    .io_l0_way_info                             (g_io_l0_way_info),
    .io_sfence_dup_0_valid                      (io_sfence_dup_0_valid),
    .io_sfence_dup_0_bits_rs1                   (io_sfence_dup_0_bits_rs1),
    .io_sfence_dup_0_bits_rs2                   (io_sfence_dup_0_bits_rs2),
    .io_sfence_dup_0_bits_addr                  (io_sfence_dup_0_bits_addr),
    .io_sfence_dup_0_bits_id                    (io_sfence_dup_0_bits_id),
    .io_sfence_dup_0_bits_hv                    (io_sfence_dup_0_bits_hv),
    .io_sfence_dup_0_bits_hg                    (io_sfence_dup_0_bits_hg),
    .io_sfence_dup_1_valid                      (io_sfence_dup_1_valid),
    .io_sfence_dup_1_bits_id                    (io_sfence_dup_1_bits_id),
    .io_sfence_dup_2_valid                      (io_sfence_dup_2_valid),
    .io_sfence_dup_2_bits_rs1                   (io_sfence_dup_2_bits_rs1),
    .io_sfence_dup_2_bits_rs2                   (io_sfence_dup_2_bits_rs2),
    .io_sfence_dup_2_bits_id                    (io_sfence_dup_2_bits_id),
    .io_csr_dup_0_satp_asid                     (io_csr_dup_0_satp_asid),
    .io_csr_dup_0_satp_changed                  (io_csr_dup_0_satp_changed),
    .io_csr_dup_0_vsatp_asid                    (io_csr_dup_0_vsatp_asid),
    .io_csr_dup_0_vsatp_changed                 (io_csr_dup_0_vsatp_changed),
    .io_csr_dup_0_hgatp_mode                    (io_csr_dup_0_hgatp_mode),
    .io_csr_dup_0_hgatp_vmid                    (io_csr_dup_0_hgatp_vmid),
    .io_csr_dup_0_hgatp_changed                 (io_csr_dup_0_hgatp_changed),
    .io_csr_dup_0_mbmc_BME                      (io_csr_dup_0_mbmc_BME),
    .io_csr_dup_0_mbmc_CMODE                    (io_csr_dup_0_mbmc_CMODE),
    .io_csr_dup_0_priv_virt                     (io_csr_dup_0_priv_virt),
    .io_csr_dup_0_priv_virt_changed             (io_csr_dup_0_priv_virt_changed),
    .io_csr_dup_1_satp_asid                     (io_csr_dup_1_satp_asid),
    .io_csr_dup_1_satp_changed                  (io_csr_dup_1_satp_changed),
    .io_csr_dup_1_vsatp_asid                    (io_csr_dup_1_vsatp_asid),
    .io_csr_dup_1_vsatp_changed                 (io_csr_dup_1_vsatp_changed),
    .io_csr_dup_1_hgatp_mode                    (io_csr_dup_1_hgatp_mode),
    .io_csr_dup_1_hgatp_vmid                    (io_csr_dup_1_hgatp_vmid),
    .io_csr_dup_1_hgatp_changed                 (io_csr_dup_1_hgatp_changed),
    .io_csr_dup_1_priv_virt                     (io_csr_dup_1_priv_virt),
    .io_csr_dup_1_priv_virt_changed             (io_csr_dup_1_priv_virt_changed),
    .io_csr_dup_2_satp_asid                     (io_csr_dup_2_satp_asid),
    .io_csr_dup_2_satp_changed                  (io_csr_dup_2_satp_changed),
    .io_csr_dup_2_vsatp_asid                    (io_csr_dup_2_vsatp_asid),
    .io_csr_dup_2_vsatp_changed                 (io_csr_dup_2_vsatp_changed),
    .io_csr_dup_2_hgatp_mode                    (io_csr_dup_2_hgatp_mode),
    .io_csr_dup_2_hgatp_vmid                    (io_csr_dup_2_hgatp_vmid),
    .io_csr_dup_2_hgatp_changed                 (io_csr_dup_2_hgatp_changed),
    .io_csr_dup_2_priv_virt                     (io_csr_dup_2_priv_virt),
    .io_csr_dup_2_priv_virt_changed             (io_csr_dup_2_priv_virt_changed),
    .io_bitmap_wakeup_ready                     (g_io_bitmap_wakeup_ready),
    .io_bitmap_wakeup_valid                     (io_bitmap_wakeup_valid),
    .io_bitmap_wakeup_bits_setIndex             (io_bitmap_wakeup_bits_setIndex),
    .io_bitmap_wakeup_bits_tag                  (io_bitmap_wakeup_bits_tag),
    .io_bitmap_wakeup_bits_way_info             (io_bitmap_wakeup_bits_way_info),
    .io_bitmap_wakeup_bits_pte_index            (io_bitmap_wakeup_bits_pte_index),
    .io_bitmap_wakeup_bits_check_success        (io_bitmap_wakeup_bits_check_success),
    .io_bitmap_wakeup_bits_s2xlate              (io_bitmap_wakeup_bits_s2xlate),
    .io_perf_0_value                            (g_io_perf_0_value),
    .io_perf_1_value                            (g_io_perf_1_value),
    .io_perf_2_value                            (g_io_perf_2_value),
    .io_perf_3_value                            (g_io_perf_3_value),
    .io_perf_4_value                            (g_io_perf_4_value),
    .io_perf_5_value                            (g_io_perf_5_value),
    .io_perf_6_value                            (g_io_perf_6_value),
    .io_perf_7_value                            (g_io_perf_7_value),
    .boreChildrenBd_bore_array                  (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all                    (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req                    (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack                    (g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen                (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be                     (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr                   (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata                 (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen                 (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd                (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata                (g_boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_array                (boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all                  (boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req                  (boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_ack                  (g_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_writeen              (boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be                   (boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr                 (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata               (boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen               (boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd              (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_outdata              (g_boreChildrenBd_bore_1_outdata),
    .sigFromSrams_bore_ram_hold                 (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass               (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken             (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk              (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp             (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold             (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen                     (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold               (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass             (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken           (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk            (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp           (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold           (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                   (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold               (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass             (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken           (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk            (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp           (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold           (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                   (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold               (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass             (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken           (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk            (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp           (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold           (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                   (sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold               (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass             (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken           (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk            (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp           (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold           (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                   (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold               (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass             (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken           (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk            (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp           (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold           (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                   (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold               (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass             (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken           (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk            (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp           (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold           (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                   (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold               (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass             (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken           (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk            (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp           (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold           (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                   (sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold               (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass             (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken           (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk            (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp           (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold           (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen                   (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold               (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass             (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken           (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk            (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp           (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold           (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen                   (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold              (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass            (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken          (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk           (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp          (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold          (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen                  (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold              (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass            (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken          (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk           (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp          (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold          (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen                  (sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold              (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass            (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken          (sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk           (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp          (sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold          (sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen                  (sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold              (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass            (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken          (sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk           (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp          (sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold          (sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen                  (sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold              (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass            (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken          (sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk           (sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp          (sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold          (sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen                  (sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold              (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass            (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken          (sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk           (sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp          (sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold          (sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen                  (sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold              (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass            (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken          (sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk           (sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp          (sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold          (sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen                  (sigFromSrams_bore_16_cgen),
    .cg_bore_cgen                               (cg_bore_cgen)
  );
  PtwCache_xs dut_i (
    .clock                                      (clock),
    .reset                                      (reset),
    .io_csr_mPBMTE                              (io_csr_mPBMTE),
    .io_csr_hPBMTE                              (io_csr_hPBMTE),
    .io_req_ready                               (i_io_req_ready),
    .io_req_valid                               (io_req_valid),
    .io_req_bits_req_info_vpn                   (io_req_bits_req_info_vpn),
    .io_req_bits_req_info_s2xlate               (io_req_bits_req_info_s2xlate),
    .io_req_bits_req_info_source                (io_req_bits_req_info_source),
    .io_req_bits_isFirst                        (io_req_bits_isFirst),
    .io_req_bits_isHptwReq                      (io_req_bits_isHptwReq),
    .io_req_bits_hptwId                         (io_req_bits_hptwId),
    .io_resp_ready                              (io_resp_ready),
    .io_resp_valid                              (i_io_resp_valid),
    .io_resp_bits_req_info_vpn                  (i_io_resp_bits_req_info_vpn),
    .io_resp_bits_req_info_s2xlate              (i_io_resp_bits_req_info_s2xlate),
    .io_resp_bits_req_info_source               (i_io_resp_bits_req_info_source),
    .io_resp_bits_isFirst                       (i_io_resp_bits_isFirst),
    .io_resp_bits_hit                           (i_io_resp_bits_hit),
    .io_resp_bits_prefetch                      (i_io_resp_bits_prefetch),
    .io_resp_bits_bypassed                      (i_io_resp_bits_bypassed),
    .io_resp_bits_toFsm_l3Hit                   (i_io_resp_bits_toFsm_l3Hit),
    .io_resp_bits_toFsm_l2Hit                   (i_io_resp_bits_toFsm_l2Hit),
    .io_resp_bits_toFsm_l1Hit                   (i_io_resp_bits_toFsm_l1Hit),
    .io_resp_bits_toFsm_ppn                     (i_io_resp_bits_toFsm_ppn),
    .io_resp_bits_toFsm_stage1Hit               (i_io_resp_bits_toFsm_stage1Hit),
    .io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check (i_io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check),
    .io_resp_bits_toFsm_bitmapCheck_toLLPTW     (i_io_resp_bits_toFsm_bitmapCheck_toLLPTW),
    .io_resp_bits_toFsm_bitmapCheck_hitway      (i_io_resp_bits_toFsm_bitmapCheck_hitway),
    .io_resp_bits_toFsm_bitmapCheck_pte         (i_io_resp_bits_toFsm_bitmapCheck_pte),
    .io_resp_bits_toFsm_bitmapCheck_ptes_0      (i_io_resp_bits_toFsm_bitmapCheck_ptes_0),
    .io_resp_bits_toFsm_bitmapCheck_ptes_1      (i_io_resp_bits_toFsm_bitmapCheck_ptes_1),
    .io_resp_bits_toFsm_bitmapCheck_ptes_2      (i_io_resp_bits_toFsm_bitmapCheck_ptes_2),
    .io_resp_bits_toFsm_bitmapCheck_ptes_3      (i_io_resp_bits_toFsm_bitmapCheck_ptes_3),
    .io_resp_bits_toFsm_bitmapCheck_ptes_4      (i_io_resp_bits_toFsm_bitmapCheck_ptes_4),
    .io_resp_bits_toFsm_bitmapCheck_ptes_5      (i_io_resp_bits_toFsm_bitmapCheck_ptes_5),
    .io_resp_bits_toFsm_bitmapCheck_ptes_6      (i_io_resp_bits_toFsm_bitmapCheck_ptes_6),
    .io_resp_bits_toFsm_bitmapCheck_ptes_7      (i_io_resp_bits_toFsm_bitmapCheck_ptes_7),
    .io_resp_bits_toFsm_bitmapCheck_cfs_0       (i_io_resp_bits_toFsm_bitmapCheck_cfs_0),
    .io_resp_bits_toFsm_bitmapCheck_cfs_1       (i_io_resp_bits_toFsm_bitmapCheck_cfs_1),
    .io_resp_bits_toFsm_bitmapCheck_cfs_2       (i_io_resp_bits_toFsm_bitmapCheck_cfs_2),
    .io_resp_bits_toFsm_bitmapCheck_cfs_3       (i_io_resp_bits_toFsm_bitmapCheck_cfs_3),
    .io_resp_bits_toFsm_bitmapCheck_cfs_4       (i_io_resp_bits_toFsm_bitmapCheck_cfs_4),
    .io_resp_bits_toFsm_bitmapCheck_cfs_5       (i_io_resp_bits_toFsm_bitmapCheck_cfs_5),
    .io_resp_bits_toFsm_bitmapCheck_cfs_6       (i_io_resp_bits_toFsm_bitmapCheck_cfs_6),
    .io_resp_bits_toFsm_bitmapCheck_cfs_7       (i_io_resp_bits_toFsm_bitmapCheck_cfs_7),
    .io_resp_bits_toFsm_bitmapCheck_SPlevel     (i_io_resp_bits_toFsm_bitmapCheck_SPlevel),
    .io_resp_bits_stage1_entry_0_tag            (i_io_resp_bits_stage1_entry_0_tag),
    .io_resp_bits_stage1_entry_0_asid           (i_io_resp_bits_stage1_entry_0_asid),
    .io_resp_bits_stage1_entry_0_vmid           (i_io_resp_bits_stage1_entry_0_vmid),
    .io_resp_bits_stage1_entry_0_n              (i_io_resp_bits_stage1_entry_0_n),
    .io_resp_bits_stage1_entry_0_pbmt           (i_io_resp_bits_stage1_entry_0_pbmt),
    .io_resp_bits_stage1_entry_0_perm_d         (i_io_resp_bits_stage1_entry_0_perm_d),
    .io_resp_bits_stage1_entry_0_perm_a         (i_io_resp_bits_stage1_entry_0_perm_a),
    .io_resp_bits_stage1_entry_0_perm_g         (i_io_resp_bits_stage1_entry_0_perm_g),
    .io_resp_bits_stage1_entry_0_perm_u         (i_io_resp_bits_stage1_entry_0_perm_u),
    .io_resp_bits_stage1_entry_0_perm_x         (i_io_resp_bits_stage1_entry_0_perm_x),
    .io_resp_bits_stage1_entry_0_perm_w         (i_io_resp_bits_stage1_entry_0_perm_w),
    .io_resp_bits_stage1_entry_0_perm_r         (i_io_resp_bits_stage1_entry_0_perm_r),
    .io_resp_bits_stage1_entry_0_level          (i_io_resp_bits_stage1_entry_0_level),
    .io_resp_bits_stage1_entry_0_v              (i_io_resp_bits_stage1_entry_0_v),
    .io_resp_bits_stage1_entry_0_ppn            (i_io_resp_bits_stage1_entry_0_ppn),
    .io_resp_bits_stage1_entry_0_ppn_low        (i_io_resp_bits_stage1_entry_0_ppn_low),
    .io_resp_bits_stage1_entry_0_pf             (i_io_resp_bits_stage1_entry_0_pf),
    .io_resp_bits_stage1_entry_0_cf             (i_io_resp_bits_stage1_entry_0_cf),
    .io_resp_bits_stage1_entry_1_tag            (i_io_resp_bits_stage1_entry_1_tag),
    .io_resp_bits_stage1_entry_1_asid           (i_io_resp_bits_stage1_entry_1_asid),
    .io_resp_bits_stage1_entry_1_vmid           (i_io_resp_bits_stage1_entry_1_vmid),
    .io_resp_bits_stage1_entry_1_n              (i_io_resp_bits_stage1_entry_1_n),
    .io_resp_bits_stage1_entry_1_pbmt           (i_io_resp_bits_stage1_entry_1_pbmt),
    .io_resp_bits_stage1_entry_1_perm_d         (i_io_resp_bits_stage1_entry_1_perm_d),
    .io_resp_bits_stage1_entry_1_perm_a         (i_io_resp_bits_stage1_entry_1_perm_a),
    .io_resp_bits_stage1_entry_1_perm_g         (i_io_resp_bits_stage1_entry_1_perm_g),
    .io_resp_bits_stage1_entry_1_perm_u         (i_io_resp_bits_stage1_entry_1_perm_u),
    .io_resp_bits_stage1_entry_1_perm_x         (i_io_resp_bits_stage1_entry_1_perm_x),
    .io_resp_bits_stage1_entry_1_perm_w         (i_io_resp_bits_stage1_entry_1_perm_w),
    .io_resp_bits_stage1_entry_1_perm_r         (i_io_resp_bits_stage1_entry_1_perm_r),
    .io_resp_bits_stage1_entry_1_level          (i_io_resp_bits_stage1_entry_1_level),
    .io_resp_bits_stage1_entry_1_v              (i_io_resp_bits_stage1_entry_1_v),
    .io_resp_bits_stage1_entry_1_ppn            (i_io_resp_bits_stage1_entry_1_ppn),
    .io_resp_bits_stage1_entry_1_ppn_low        (i_io_resp_bits_stage1_entry_1_ppn_low),
    .io_resp_bits_stage1_entry_1_pf             (i_io_resp_bits_stage1_entry_1_pf),
    .io_resp_bits_stage1_entry_1_cf             (i_io_resp_bits_stage1_entry_1_cf),
    .io_resp_bits_stage1_entry_2_tag            (i_io_resp_bits_stage1_entry_2_tag),
    .io_resp_bits_stage1_entry_2_asid           (i_io_resp_bits_stage1_entry_2_asid),
    .io_resp_bits_stage1_entry_2_vmid           (i_io_resp_bits_stage1_entry_2_vmid),
    .io_resp_bits_stage1_entry_2_n              (i_io_resp_bits_stage1_entry_2_n),
    .io_resp_bits_stage1_entry_2_pbmt           (i_io_resp_bits_stage1_entry_2_pbmt),
    .io_resp_bits_stage1_entry_2_perm_d         (i_io_resp_bits_stage1_entry_2_perm_d),
    .io_resp_bits_stage1_entry_2_perm_a         (i_io_resp_bits_stage1_entry_2_perm_a),
    .io_resp_bits_stage1_entry_2_perm_g         (i_io_resp_bits_stage1_entry_2_perm_g),
    .io_resp_bits_stage1_entry_2_perm_u         (i_io_resp_bits_stage1_entry_2_perm_u),
    .io_resp_bits_stage1_entry_2_perm_x         (i_io_resp_bits_stage1_entry_2_perm_x),
    .io_resp_bits_stage1_entry_2_perm_w         (i_io_resp_bits_stage1_entry_2_perm_w),
    .io_resp_bits_stage1_entry_2_perm_r         (i_io_resp_bits_stage1_entry_2_perm_r),
    .io_resp_bits_stage1_entry_2_level          (i_io_resp_bits_stage1_entry_2_level),
    .io_resp_bits_stage1_entry_2_v              (i_io_resp_bits_stage1_entry_2_v),
    .io_resp_bits_stage1_entry_2_ppn            (i_io_resp_bits_stage1_entry_2_ppn),
    .io_resp_bits_stage1_entry_2_ppn_low        (i_io_resp_bits_stage1_entry_2_ppn_low),
    .io_resp_bits_stage1_entry_2_pf             (i_io_resp_bits_stage1_entry_2_pf),
    .io_resp_bits_stage1_entry_2_cf             (i_io_resp_bits_stage1_entry_2_cf),
    .io_resp_bits_stage1_entry_3_tag            (i_io_resp_bits_stage1_entry_3_tag),
    .io_resp_bits_stage1_entry_3_asid           (i_io_resp_bits_stage1_entry_3_asid),
    .io_resp_bits_stage1_entry_3_vmid           (i_io_resp_bits_stage1_entry_3_vmid),
    .io_resp_bits_stage1_entry_3_n              (i_io_resp_bits_stage1_entry_3_n),
    .io_resp_bits_stage1_entry_3_pbmt           (i_io_resp_bits_stage1_entry_3_pbmt),
    .io_resp_bits_stage1_entry_3_perm_d         (i_io_resp_bits_stage1_entry_3_perm_d),
    .io_resp_bits_stage1_entry_3_perm_a         (i_io_resp_bits_stage1_entry_3_perm_a),
    .io_resp_bits_stage1_entry_3_perm_g         (i_io_resp_bits_stage1_entry_3_perm_g),
    .io_resp_bits_stage1_entry_3_perm_u         (i_io_resp_bits_stage1_entry_3_perm_u),
    .io_resp_bits_stage1_entry_3_perm_x         (i_io_resp_bits_stage1_entry_3_perm_x),
    .io_resp_bits_stage1_entry_3_perm_w         (i_io_resp_bits_stage1_entry_3_perm_w),
    .io_resp_bits_stage1_entry_3_perm_r         (i_io_resp_bits_stage1_entry_3_perm_r),
    .io_resp_bits_stage1_entry_3_level          (i_io_resp_bits_stage1_entry_3_level),
    .io_resp_bits_stage1_entry_3_v              (i_io_resp_bits_stage1_entry_3_v),
    .io_resp_bits_stage1_entry_3_ppn            (i_io_resp_bits_stage1_entry_3_ppn),
    .io_resp_bits_stage1_entry_3_ppn_low        (i_io_resp_bits_stage1_entry_3_ppn_low),
    .io_resp_bits_stage1_entry_3_pf             (i_io_resp_bits_stage1_entry_3_pf),
    .io_resp_bits_stage1_entry_3_cf             (i_io_resp_bits_stage1_entry_3_cf),
    .io_resp_bits_stage1_entry_4_tag            (i_io_resp_bits_stage1_entry_4_tag),
    .io_resp_bits_stage1_entry_4_asid           (i_io_resp_bits_stage1_entry_4_asid),
    .io_resp_bits_stage1_entry_4_vmid           (i_io_resp_bits_stage1_entry_4_vmid),
    .io_resp_bits_stage1_entry_4_n              (i_io_resp_bits_stage1_entry_4_n),
    .io_resp_bits_stage1_entry_4_pbmt           (i_io_resp_bits_stage1_entry_4_pbmt),
    .io_resp_bits_stage1_entry_4_perm_d         (i_io_resp_bits_stage1_entry_4_perm_d),
    .io_resp_bits_stage1_entry_4_perm_a         (i_io_resp_bits_stage1_entry_4_perm_a),
    .io_resp_bits_stage1_entry_4_perm_g         (i_io_resp_bits_stage1_entry_4_perm_g),
    .io_resp_bits_stage1_entry_4_perm_u         (i_io_resp_bits_stage1_entry_4_perm_u),
    .io_resp_bits_stage1_entry_4_perm_x         (i_io_resp_bits_stage1_entry_4_perm_x),
    .io_resp_bits_stage1_entry_4_perm_w         (i_io_resp_bits_stage1_entry_4_perm_w),
    .io_resp_bits_stage1_entry_4_perm_r         (i_io_resp_bits_stage1_entry_4_perm_r),
    .io_resp_bits_stage1_entry_4_level          (i_io_resp_bits_stage1_entry_4_level),
    .io_resp_bits_stage1_entry_4_v              (i_io_resp_bits_stage1_entry_4_v),
    .io_resp_bits_stage1_entry_4_ppn            (i_io_resp_bits_stage1_entry_4_ppn),
    .io_resp_bits_stage1_entry_4_ppn_low        (i_io_resp_bits_stage1_entry_4_ppn_low),
    .io_resp_bits_stage1_entry_4_pf             (i_io_resp_bits_stage1_entry_4_pf),
    .io_resp_bits_stage1_entry_4_cf             (i_io_resp_bits_stage1_entry_4_cf),
    .io_resp_bits_stage1_entry_5_tag            (i_io_resp_bits_stage1_entry_5_tag),
    .io_resp_bits_stage1_entry_5_asid           (i_io_resp_bits_stage1_entry_5_asid),
    .io_resp_bits_stage1_entry_5_vmid           (i_io_resp_bits_stage1_entry_5_vmid),
    .io_resp_bits_stage1_entry_5_n              (i_io_resp_bits_stage1_entry_5_n),
    .io_resp_bits_stage1_entry_5_pbmt           (i_io_resp_bits_stage1_entry_5_pbmt),
    .io_resp_bits_stage1_entry_5_perm_d         (i_io_resp_bits_stage1_entry_5_perm_d),
    .io_resp_bits_stage1_entry_5_perm_a         (i_io_resp_bits_stage1_entry_5_perm_a),
    .io_resp_bits_stage1_entry_5_perm_g         (i_io_resp_bits_stage1_entry_5_perm_g),
    .io_resp_bits_stage1_entry_5_perm_u         (i_io_resp_bits_stage1_entry_5_perm_u),
    .io_resp_bits_stage1_entry_5_perm_x         (i_io_resp_bits_stage1_entry_5_perm_x),
    .io_resp_bits_stage1_entry_5_perm_w         (i_io_resp_bits_stage1_entry_5_perm_w),
    .io_resp_bits_stage1_entry_5_perm_r         (i_io_resp_bits_stage1_entry_5_perm_r),
    .io_resp_bits_stage1_entry_5_level          (i_io_resp_bits_stage1_entry_5_level),
    .io_resp_bits_stage1_entry_5_v              (i_io_resp_bits_stage1_entry_5_v),
    .io_resp_bits_stage1_entry_5_ppn            (i_io_resp_bits_stage1_entry_5_ppn),
    .io_resp_bits_stage1_entry_5_ppn_low        (i_io_resp_bits_stage1_entry_5_ppn_low),
    .io_resp_bits_stage1_entry_5_pf             (i_io_resp_bits_stage1_entry_5_pf),
    .io_resp_bits_stage1_entry_5_cf             (i_io_resp_bits_stage1_entry_5_cf),
    .io_resp_bits_stage1_entry_6_tag            (i_io_resp_bits_stage1_entry_6_tag),
    .io_resp_bits_stage1_entry_6_asid           (i_io_resp_bits_stage1_entry_6_asid),
    .io_resp_bits_stage1_entry_6_vmid           (i_io_resp_bits_stage1_entry_6_vmid),
    .io_resp_bits_stage1_entry_6_n              (i_io_resp_bits_stage1_entry_6_n),
    .io_resp_bits_stage1_entry_6_pbmt           (i_io_resp_bits_stage1_entry_6_pbmt),
    .io_resp_bits_stage1_entry_6_perm_d         (i_io_resp_bits_stage1_entry_6_perm_d),
    .io_resp_bits_stage1_entry_6_perm_a         (i_io_resp_bits_stage1_entry_6_perm_a),
    .io_resp_bits_stage1_entry_6_perm_g         (i_io_resp_bits_stage1_entry_6_perm_g),
    .io_resp_bits_stage1_entry_6_perm_u         (i_io_resp_bits_stage1_entry_6_perm_u),
    .io_resp_bits_stage1_entry_6_perm_x         (i_io_resp_bits_stage1_entry_6_perm_x),
    .io_resp_bits_stage1_entry_6_perm_w         (i_io_resp_bits_stage1_entry_6_perm_w),
    .io_resp_bits_stage1_entry_6_perm_r         (i_io_resp_bits_stage1_entry_6_perm_r),
    .io_resp_bits_stage1_entry_6_level          (i_io_resp_bits_stage1_entry_6_level),
    .io_resp_bits_stage1_entry_6_v              (i_io_resp_bits_stage1_entry_6_v),
    .io_resp_bits_stage1_entry_6_ppn            (i_io_resp_bits_stage1_entry_6_ppn),
    .io_resp_bits_stage1_entry_6_ppn_low        (i_io_resp_bits_stage1_entry_6_ppn_low),
    .io_resp_bits_stage1_entry_6_pf             (i_io_resp_bits_stage1_entry_6_pf),
    .io_resp_bits_stage1_entry_6_cf             (i_io_resp_bits_stage1_entry_6_cf),
    .io_resp_bits_stage1_entry_7_tag            (i_io_resp_bits_stage1_entry_7_tag),
    .io_resp_bits_stage1_entry_7_asid           (i_io_resp_bits_stage1_entry_7_asid),
    .io_resp_bits_stage1_entry_7_vmid           (i_io_resp_bits_stage1_entry_7_vmid),
    .io_resp_bits_stage1_entry_7_n              (i_io_resp_bits_stage1_entry_7_n),
    .io_resp_bits_stage1_entry_7_pbmt           (i_io_resp_bits_stage1_entry_7_pbmt),
    .io_resp_bits_stage1_entry_7_perm_d         (i_io_resp_bits_stage1_entry_7_perm_d),
    .io_resp_bits_stage1_entry_7_perm_a         (i_io_resp_bits_stage1_entry_7_perm_a),
    .io_resp_bits_stage1_entry_7_perm_g         (i_io_resp_bits_stage1_entry_7_perm_g),
    .io_resp_bits_stage1_entry_7_perm_u         (i_io_resp_bits_stage1_entry_7_perm_u),
    .io_resp_bits_stage1_entry_7_perm_x         (i_io_resp_bits_stage1_entry_7_perm_x),
    .io_resp_bits_stage1_entry_7_perm_w         (i_io_resp_bits_stage1_entry_7_perm_w),
    .io_resp_bits_stage1_entry_7_perm_r         (i_io_resp_bits_stage1_entry_7_perm_r),
    .io_resp_bits_stage1_entry_7_level          (i_io_resp_bits_stage1_entry_7_level),
    .io_resp_bits_stage1_entry_7_v              (i_io_resp_bits_stage1_entry_7_v),
    .io_resp_bits_stage1_entry_7_ppn            (i_io_resp_bits_stage1_entry_7_ppn),
    .io_resp_bits_stage1_entry_7_ppn_low        (i_io_resp_bits_stage1_entry_7_ppn_low),
    .io_resp_bits_stage1_entry_7_pf             (i_io_resp_bits_stage1_entry_7_pf),
    .io_resp_bits_stage1_entry_7_cf             (i_io_resp_bits_stage1_entry_7_cf),
    .io_resp_bits_stage1_pteidx_0               (i_io_resp_bits_stage1_pteidx_0),
    .io_resp_bits_stage1_pteidx_1               (i_io_resp_bits_stage1_pteidx_1),
    .io_resp_bits_stage1_pteidx_2               (i_io_resp_bits_stage1_pteidx_2),
    .io_resp_bits_stage1_pteidx_3               (i_io_resp_bits_stage1_pteidx_3),
    .io_resp_bits_stage1_pteidx_4               (i_io_resp_bits_stage1_pteidx_4),
    .io_resp_bits_stage1_pteidx_5               (i_io_resp_bits_stage1_pteidx_5),
    .io_resp_bits_stage1_pteidx_6               (i_io_resp_bits_stage1_pteidx_6),
    .io_resp_bits_stage1_pteidx_7               (i_io_resp_bits_stage1_pteidx_7),
    .io_resp_bits_stage1_not_super              (i_io_resp_bits_stage1_not_super),
    .io_resp_bits_isHptwReq                     (i_io_resp_bits_isHptwReq),
    .io_resp_bits_toHptw_l3Hit                  (i_io_resp_bits_toHptw_l3Hit),
    .io_resp_bits_toHptw_l2Hit                  (i_io_resp_bits_toHptw_l2Hit),
    .io_resp_bits_toHptw_l1Hit                  (i_io_resp_bits_toHptw_l1Hit),
    .io_resp_bits_toHptw_ppn                    (i_io_resp_bits_toHptw_ppn),
    .io_resp_bits_toHptw_id                     (i_io_resp_bits_toHptw_id),
    .io_resp_bits_toHptw_resp_entry_tag         (i_io_resp_bits_toHptw_resp_entry_tag),
    .io_resp_bits_toHptw_resp_entry_vmid        (i_io_resp_bits_toHptw_resp_entry_vmid),
    .io_resp_bits_toHptw_resp_entry_n           (i_io_resp_bits_toHptw_resp_entry_n),
    .io_resp_bits_toHptw_resp_entry_pbmt        (i_io_resp_bits_toHptw_resp_entry_pbmt),
    .io_resp_bits_toHptw_resp_entry_ppn         (i_io_resp_bits_toHptw_resp_entry_ppn),
    .io_resp_bits_toHptw_resp_entry_perm_d      (i_io_resp_bits_toHptw_resp_entry_perm_d),
    .io_resp_bits_toHptw_resp_entry_perm_a      (i_io_resp_bits_toHptw_resp_entry_perm_a),
    .io_resp_bits_toHptw_resp_entry_perm_g      (i_io_resp_bits_toHptw_resp_entry_perm_g),
    .io_resp_bits_toHptw_resp_entry_perm_u      (i_io_resp_bits_toHptw_resp_entry_perm_u),
    .io_resp_bits_toHptw_resp_entry_perm_x      (i_io_resp_bits_toHptw_resp_entry_perm_x),
    .io_resp_bits_toHptw_resp_entry_perm_w      (i_io_resp_bits_toHptw_resp_entry_perm_w),
    .io_resp_bits_toHptw_resp_entry_perm_r      (i_io_resp_bits_toHptw_resp_entry_perm_r),
    .io_resp_bits_toHptw_resp_entry_level       (i_io_resp_bits_toHptw_resp_entry_level),
    .io_resp_bits_toHptw_resp_gpf               (i_io_resp_bits_toHptw_resp_gpf),
    .io_resp_bits_toHptw_bypassed               (i_io_resp_bits_toHptw_bypassed),
    .io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check (i_io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check),
    .io_resp_bits_toHptw_bitmapCheck_hitway     (i_io_resp_bits_toHptw_bitmapCheck_hitway),
    .io_resp_bits_toHptw_bitmapCheck_pte        (i_io_resp_bits_toHptw_bitmapCheck_pte),
    .io_resp_bits_toHptw_bitmapCheck_ptes_0     (i_io_resp_bits_toHptw_bitmapCheck_ptes_0),
    .io_resp_bits_toHptw_bitmapCheck_ptes_1     (i_io_resp_bits_toHptw_bitmapCheck_ptes_1),
    .io_resp_bits_toHptw_bitmapCheck_ptes_2     (i_io_resp_bits_toHptw_bitmapCheck_ptes_2),
    .io_resp_bits_toHptw_bitmapCheck_ptes_3     (i_io_resp_bits_toHptw_bitmapCheck_ptes_3),
    .io_resp_bits_toHptw_bitmapCheck_ptes_4     (i_io_resp_bits_toHptw_bitmapCheck_ptes_4),
    .io_resp_bits_toHptw_bitmapCheck_ptes_5     (i_io_resp_bits_toHptw_bitmapCheck_ptes_5),
    .io_resp_bits_toHptw_bitmapCheck_ptes_6     (i_io_resp_bits_toHptw_bitmapCheck_ptes_6),
    .io_resp_bits_toHptw_bitmapCheck_ptes_7     (i_io_resp_bits_toHptw_bitmapCheck_ptes_7),
    .io_resp_bits_toHptw_bitmapCheck_fromSP     (i_io_resp_bits_toHptw_bitmapCheck_fromSP),
    .io_resp_bits_toHptw_bitmapCheck_SPlevel    (i_io_resp_bits_toHptw_bitmapCheck_SPlevel),
    .io_refill_valid                            (io_refill_valid),
    .io_refill_bits_ptes                        (io_refill_bits_ptes),
    .io_refill_bits_levelOH_sp                  (io_refill_bits_levelOH_sp),
    .io_refill_bits_levelOH_l0                  (io_refill_bits_levelOH_l0),
    .io_refill_bits_levelOH_l1                  (io_refill_bits_levelOH_l1),
    .io_refill_bits_levelOH_l2                  (io_refill_bits_levelOH_l2),
    .io_refill_bits_levelOH_l3                  (io_refill_bits_levelOH_l3),
    .io_refill_bits_req_info_dup_0_vpn          (io_refill_bits_req_info_dup_0_vpn),
    .io_refill_bits_req_info_dup_0_s2xlate      (io_refill_bits_req_info_dup_0_s2xlate),
    .io_refill_bits_req_info_dup_0_source       (io_refill_bits_req_info_dup_0_source),
    .io_refill_bits_req_info_dup_1_vpn          (io_refill_bits_req_info_dup_1_vpn),
    .io_refill_bits_req_info_dup_1_s2xlate      (io_refill_bits_req_info_dup_1_s2xlate),
    .io_refill_bits_req_info_dup_1_source       (io_refill_bits_req_info_dup_1_source),
    .io_refill_bits_req_info_dup_2_vpn          (io_refill_bits_req_info_dup_2_vpn),
    .io_refill_bits_req_info_dup_2_s2xlate      (io_refill_bits_req_info_dup_2_s2xlate),
    .io_refill_bits_req_info_dup_2_source       (io_refill_bits_req_info_dup_2_source),
    .io_refill_bits_level_dup_0                 (io_refill_bits_level_dup_0),
    .io_refill_bits_level_dup_2                 (io_refill_bits_level_dup_2),
    .io_refill_bits_sel_pte_dup_0               (io_refill_bits_sel_pte_dup_0),
    .io_refill_bits_sel_pte_dup_2               (io_refill_bits_sel_pte_dup_2),
    .io_l0_way_info                             (i_io_l0_way_info),
    .io_sfence_dup_0_valid                      (io_sfence_dup_0_valid),
    .io_sfence_dup_0_bits_rs1                   (io_sfence_dup_0_bits_rs1),
    .io_sfence_dup_0_bits_rs2                   (io_sfence_dup_0_bits_rs2),
    .io_sfence_dup_0_bits_addr                  (io_sfence_dup_0_bits_addr),
    .io_sfence_dup_0_bits_id                    (io_sfence_dup_0_bits_id),
    .io_sfence_dup_0_bits_hv                    (io_sfence_dup_0_bits_hv),
    .io_sfence_dup_0_bits_hg                    (io_sfence_dup_0_bits_hg),
    .io_sfence_dup_1_valid                      (io_sfence_dup_1_valid),
    .io_sfence_dup_1_bits_id                    (io_sfence_dup_1_bits_id),
    .io_sfence_dup_2_valid                      (io_sfence_dup_2_valid),
    .io_sfence_dup_2_bits_rs1                   (io_sfence_dup_2_bits_rs1),
    .io_sfence_dup_2_bits_rs2                   (io_sfence_dup_2_bits_rs2),
    .io_sfence_dup_2_bits_id                    (io_sfence_dup_2_bits_id),
    .io_csr_dup_0_satp_asid                     (io_csr_dup_0_satp_asid),
    .io_csr_dup_0_satp_changed                  (io_csr_dup_0_satp_changed),
    .io_csr_dup_0_vsatp_asid                    (io_csr_dup_0_vsatp_asid),
    .io_csr_dup_0_vsatp_changed                 (io_csr_dup_0_vsatp_changed),
    .io_csr_dup_0_hgatp_mode                    (io_csr_dup_0_hgatp_mode),
    .io_csr_dup_0_hgatp_vmid                    (io_csr_dup_0_hgatp_vmid),
    .io_csr_dup_0_hgatp_changed                 (io_csr_dup_0_hgatp_changed),
    .io_csr_dup_0_mbmc_BME                      (io_csr_dup_0_mbmc_BME),
    .io_csr_dup_0_mbmc_CMODE                    (io_csr_dup_0_mbmc_CMODE),
    .io_csr_dup_0_priv_virt                     (io_csr_dup_0_priv_virt),
    .io_csr_dup_0_priv_virt_changed             (io_csr_dup_0_priv_virt_changed),
    .io_csr_dup_1_satp_asid                     (io_csr_dup_1_satp_asid),
    .io_csr_dup_1_satp_changed                  (io_csr_dup_1_satp_changed),
    .io_csr_dup_1_vsatp_asid                    (io_csr_dup_1_vsatp_asid),
    .io_csr_dup_1_vsatp_changed                 (io_csr_dup_1_vsatp_changed),
    .io_csr_dup_1_hgatp_mode                    (io_csr_dup_1_hgatp_mode),
    .io_csr_dup_1_hgatp_vmid                    (io_csr_dup_1_hgatp_vmid),
    .io_csr_dup_1_hgatp_changed                 (io_csr_dup_1_hgatp_changed),
    .io_csr_dup_1_priv_virt                     (io_csr_dup_1_priv_virt),
    .io_csr_dup_1_priv_virt_changed             (io_csr_dup_1_priv_virt_changed),
    .io_csr_dup_2_satp_asid                     (io_csr_dup_2_satp_asid),
    .io_csr_dup_2_satp_changed                  (io_csr_dup_2_satp_changed),
    .io_csr_dup_2_vsatp_asid                    (io_csr_dup_2_vsatp_asid),
    .io_csr_dup_2_vsatp_changed                 (io_csr_dup_2_vsatp_changed),
    .io_csr_dup_2_hgatp_mode                    (io_csr_dup_2_hgatp_mode),
    .io_csr_dup_2_hgatp_vmid                    (io_csr_dup_2_hgatp_vmid),
    .io_csr_dup_2_hgatp_changed                 (io_csr_dup_2_hgatp_changed),
    .io_csr_dup_2_priv_virt                     (io_csr_dup_2_priv_virt),
    .io_csr_dup_2_priv_virt_changed             (io_csr_dup_2_priv_virt_changed),
    .io_bitmap_wakeup_ready                     (i_io_bitmap_wakeup_ready),
    .io_bitmap_wakeup_valid                     (io_bitmap_wakeup_valid),
    .io_bitmap_wakeup_bits_setIndex             (io_bitmap_wakeup_bits_setIndex),
    .io_bitmap_wakeup_bits_tag                  (io_bitmap_wakeup_bits_tag),
    .io_bitmap_wakeup_bits_way_info             (io_bitmap_wakeup_bits_way_info),
    .io_bitmap_wakeup_bits_pte_index            (io_bitmap_wakeup_bits_pte_index),
    .io_bitmap_wakeup_bits_check_success        (io_bitmap_wakeup_bits_check_success),
    .io_bitmap_wakeup_bits_s2xlate              (io_bitmap_wakeup_bits_s2xlate),
    .io_perf_0_value                            (i_io_perf_0_value),
    .io_perf_1_value                            (i_io_perf_1_value),
    .io_perf_2_value                            (i_io_perf_2_value),
    .io_perf_3_value                            (i_io_perf_3_value),
    .io_perf_4_value                            (i_io_perf_4_value),
    .io_perf_5_value                            (i_io_perf_5_value),
    .io_perf_6_value                            (i_io_perf_6_value),
    .io_perf_7_value                            (i_io_perf_7_value),
    .boreChildrenBd_bore_array                  (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all                    (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req                    (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack                    (i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen                (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be                     (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr                   (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata                 (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen                 (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd                (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata                (i_boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_array                (boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all                  (boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req                  (boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_ack                  (i_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_writeen              (boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be                   (boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr                 (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata               (boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen               (boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd              (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_outdata              (i_boreChildrenBd_bore_1_outdata),
    .sigFromSrams_bore_ram_hold                 (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass               (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken             (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk              (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp             (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold             (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen                     (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold               (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass             (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken           (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk            (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp           (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold           (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                   (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold               (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass             (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken           (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk            (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp           (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold           (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                   (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold               (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass             (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken           (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk            (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp           (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold           (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                   (sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold               (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass             (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken           (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk            (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp           (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold           (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                   (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold               (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass             (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken           (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk            (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp           (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold           (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                   (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold               (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass             (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken           (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk            (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp           (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold           (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                   (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold               (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass             (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken           (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk            (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp           (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold           (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                   (sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold               (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass             (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken           (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk            (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp           (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold           (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen                   (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold               (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass             (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken           (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk            (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp           (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold           (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen                   (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold              (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass            (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken          (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk           (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp          (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold          (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen                  (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold              (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass            (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken          (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk           (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp          (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold          (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen                  (sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold              (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass            (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken          (sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk           (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp          (sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold          (sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen                  (sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold              (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass            (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken          (sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk           (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp          (sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold          (sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen                  (sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold              (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass            (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken          (sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk           (sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp          (sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold          (sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen                  (sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold              (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass            (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken          (sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk           (sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp          (sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold          (sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen                  (sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold              (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass            (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken          (sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk           (sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp          (sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold          (sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen                  (sigFromSrams_bore_16_cgen),
    .cg_bore_cgen                               (cg_bore_cgen)
  );

  // 判别力自证（替代上一版的 untraced_diff）：
  //   waymask 从 §8 占位毕业成真逻辑之后，比较集合里已经没有"按构造必失配"的信号，
  //   原来那条 `untraced_diff > 0` 的自证随之失效。改成直接量**激励有没有走到**：
  //   五级回填各自的 fire 次数必须都 > 0，否则这一轮里某一级根本没被触发，
  //   它那一段 errors=0 就是"什么都没比"。
  int fire_l3 = 0, fire_l2 = 0, fire_l1 = 0, fire_l0 = 0, fire_sp = 0;
  int fire_hit_l3 = 0, fire_hit_l2 = 0, fire_hit_l1 = 0, fire_hit_l0 = 0, fire_hit_sp = 0;

  task automatic chk(input string nm, input logic [63:0] a, input logic [63:0] b);
    checks++;
    if (a !== b) begin
      errors++;
      if (errors <= 20)
        $display("MISMATCH t=%0t %s golden=%0h impl=%0h", $time, nm, a, b);
    end
  endtask

  // 随机 PTE：整 64 位随机会让 reserved/ppn_high 几乎恒非零，isPf 早早短路，
  // 后面几级判据一条都走不到。所以按字段加权，让每条 when 分支都有机会被走到。
  function automatic logic [63:0] rand_pte();
    logic [63:0] p;
    p = {$urandom(), $urandom()};
    if ($urandom_range(0,3) != 0) p[60:54] = 7'h0;   // reserved 多数清零
    if ($urandom_range(0,3) != 0) p[53:46] = 8'h0;   // ppn_high 多数清零
    if ($urandom_range(0,2) != 0) p[63]    = 1'b0;   // napot 少见
    if ($urandom_range(0,1) == 0) p[13:10] = 4'h8;   // 但一旦有就多给合法 napot
    if ($urandom_range(0,2) != 0) p[62:61] = $urandom_range(0,1) ? 2'b00 : p[62:61];
    if ($urandom_range(0,2) != 0) p[18:10] = 9'h0;   // 让 unaligned 两侧都能取到
    // ★2026-09-20 补★：l3/l2 只收**非叶子**且 canRefill 的 PTE，纯随机下 5000 拍
    // 只触发 5/6 次（实测），那两级的状态等于没比。这里三分之一强制成
    // "v=1 且 r=w=x=0" 的 next 型 PTE，把 l3Refill/l2Refill 的触发率抬上来。
    // ★2026-09-20 再补★：光把 r/w/x 清零还不够 —— 非叶子 PTE 的 isPf 还会查
    // u/a/d/n/pbmt，随机值下九成会被判 pf，canRefill 一样过不去，于是 l1 的 vs 位
    // 几乎恒 0，l1 命中在 3000 拍里只触发 2 次（实测）。这里三分之一造一条**干净的**
    // next 型 PTE，把 l1 命中率抬上来。
    if ($urandom_range(0,2) == 0) begin
      p[3:1]   = 3'b000;   // r/w/x = 0 ⇒ 非叶子
      p[0]     = 1'b1;     // v = 1
      p[7:6]   = 2'b00;    // d/a = 0
      p[4]     = 1'b0;     // u   = 0
      p[63]    = 1'b0;     // n   = 0
      p[62:61] = 2'b00;    // pbmt
      p[60:54] = 7'h0;     // reserved
      p[53:46] = 8'h0;     // ppn_high
    end
    return p;
  endfunction

  // 命中锥体要走得到，激励就不能"每拍全随机"：vpn 必须从一个小池子里取，
  // csr 必须在一段时间里保持不变，否则回填进去的条目下一拍就再也匹配不上了。
  // ★三份 dup 仍然各取各的★（各自独立但各自稳定）—— 命中靠的是"同一份 dup
  // 在回填与查找时一致"，不是三份相等，所以这样既能命中又保留 dup 判别力。
  logic [37:0] vpn_pool [0:7];

  // hgatp_vmid ★不能只给低位★：表项里存的是 14 位，而命中比较是
  // `{2'h0, vmid} == hgatp_vmid`（16 位零扩展），也就是说 hgatp_vmid[15:14] 非零时
  // 一律不命中。只喂 0..3 的话，"零扩展"和"只比低 14 位"两种写法值恒等——
  // 实测 mutant「l3 的 vmid 比较去掉零扩展」在那种激励下 errors=0。
  function automatic logic [15:0] rand_vmid();
    if ($urandom_range(0,3) == 0) return {$urandom_range(0,3), 14'($urandom_range(0,3))};
    return 16'($urandom_range(0,3));
  endfunction

  task automatic refresh_csr();
    io_csr_mPBMTE = $urandom_range(0,1);
    io_csr_hPBMTE = $urandom_range(0,1);
    io_csr_dup_0_satp_asid  = $urandom_range(0,3);
    io_csr_dup_0_vsatp_asid = $urandom_range(0,3);
    io_csr_dup_0_hgatp_vmid = rand_vmid();
    io_csr_dup_0_hgatp_mode = $urandom_range(0,1) ? 4'h8 : 4'h9;
    io_csr_dup_1_satp_asid  = $urandom_range(0,3);
    io_csr_dup_1_vsatp_asid = $urandom_range(0,3);
    io_csr_dup_1_hgatp_vmid = rand_vmid();
    io_csr_dup_1_hgatp_mode = $urandom_range(0,1) ? 4'h8 : 4'h9;
    io_csr_dup_2_satp_asid  = $urandom_range(0,3);
    io_csr_dup_2_vsatp_asid = $urandom_range(0,3);
    io_csr_dup_2_hgatp_vmid = rand_vmid();
    io_csr_dup_2_hgatp_mode = $urandom_range(0,1) ? 4'h8 : 4'h9;
    // ★priv.virt 三份各给各的★：sfence 的 h 比对每一级用的是自己那份 dup 的 virt
    //   （l0/sp 用 dup_0、l1 用 dup_1、l2/l3 用 dup_2）。绑成一根线的话
    //   "virt 取错 dup" 这类错误在本对照里按构造测不出来。
    io_csr_dup_0_priv_virt = $urandom_range(0,1);
    io_csr_dup_1_priv_virt = $urandom_range(0,1);
    io_csr_dup_2_priv_virt = $urandom_range(0,1);
    // BME=1 才会走 bitmap 门（§16 的 jmp_bitmap_check 与 §22 的 wakeup 写）。
    // CMODE 多数给 0：CMODE=1 时 bitmap 检查整体关掉，那一段等于没比。
    io_csr_dup_0_mbmc_BME   = $urandom_range(0,1);
    io_csr_dup_0_mbmc_CMODE = ($urandom_range(0,7) == 0);
  endtask

  // ---- 栅栏与 bitmap wakeup 的激励（本轮新增，配合 §21/§22）----
  //
  //  ★频率必须低★：sfence_dup_0.valid 直接进 flush_dup_0，整条流水一拍清空。
  //  发得太勤的话五级命中一次都走不到 —— 那就是"把命中那一段的比对偷偷关掉"。
  //  实测 1/64 时三种栅栏各触发一千次以上，而五级命中计数与不发栅栏时同量级。
  //
  //  ★三份 dup 的 valid / id / rs1 / rs2 各自独立★：golden 里
  //    l0/sp 的掩码用 dup_0 的 id 与 rs1/rs2，l1 用 dup_1 的 id，
  //    l2/l3 用 dup_2 的 id，而 l3 那一段的 rs1/rs2 也是 dup_2 的。
  //  绑成一份的话"取错 dup"在这里按构造测不出来（Predictor 那 504 个失配的形态）。
  int fire_sfence, fire_hfv, fire_hfg, fire_wakeup, fire_wk_write;

  task automatic drive_fence();
    int kind;
    io_sfence_dup_0_valid = 1'b0;
    io_sfence_dup_1_valid = 1'b0;
    io_sfence_dup_2_valid = 1'b0;
    io_csr_dup_0_satp_changed = 1'b0;  io_csr_dup_0_vsatp_changed = 1'b0;
    io_csr_dup_0_hgatp_changed = 1'b0; io_csr_dup_0_priv_virt_changed = 1'b0;
    io_csr_dup_1_satp_changed = 1'b0;  io_csr_dup_1_vsatp_changed = 1'b0;
    io_csr_dup_1_hgatp_changed = 1'b0; io_csr_dup_1_priv_virt_changed = 1'b0;
    io_csr_dup_2_satp_changed = 1'b0;  io_csr_dup_2_vsatp_changed = 1'b0;
    io_csr_dup_2_hgatp_changed = 1'b0; io_csr_dup_2_priv_virt_changed = 1'b0;

    if ($urandom_range(0,63) == 0) begin
      kind = $urandom_range(0,2);        // 0=sfence.vma 1=hfence.vvma 2=hfence.gvma
      io_sfence_dup_0_valid    = 1'b1;
      io_sfence_dup_0_bits_hv  = (kind == 1);
      io_sfence_dup_0_bits_hg  = (kind == 2);
      io_sfence_dup_0_bits_rs1 = $urandom_range(0,1);
      io_sfence_dup_0_bits_rs2 = $urandom_range(0,1);
      // ★两种地址编码都要给★：sfence/hfence.vvma 取 addr[49:12]，
      //   hfence.gvma 取 (addr<<2)[49:12] = addr[47:10]。只给一种的话
      //   "gvma 少移那两位"这个错误在本对照里测不出来。
      io_sfence_dup_0_bits_addr = (kind == 2) ? {2'h0, pick_vpn(), 10'h0}
                                              : {pick_vpn(), 12'h0};
      io_sfence_dup_0_bits_id   = rand_vmid();
      if (kind == 0) fire_sfence++;
      else if (kind == 1) fire_hfv++;
      else fire_hfg++;
    end
    if ($urandom_range(0,63) == 0) begin
      io_sfence_dup_1_valid   = 1'b1;
      io_sfence_dup_1_bits_id = rand_vmid();
    end
    if ($urandom_range(0,63) == 0) begin
      io_sfence_dup_2_valid    = 1'b1;
      io_sfence_dup_2_bits_rs1 = $urandom_range(0,1);
      io_sfence_dup_2_bits_rs2 = $urandom_range(0,1);
      io_sfence_dup_2_bits_id  = rand_vmid();
    end
    // csr 变更脉冲：也是 flush 的来源，且三份各自独立。
    if ($urandom_range(0,255) == 0) io_csr_dup_0_satp_changed      = 1'b1;
    if ($urandom_range(0,255) == 0) io_csr_dup_1_vsatp_changed     = 1'b1;
    if ($urandom_range(0,255) == 0) io_csr_dup_2_hgatp_changed     = 1'b1;
    if ($urandom_range(0,255) == 0) io_csr_dup_0_priv_virt_changed = 1'b1;
  endtask

  // ---- twin-fill：专门造"同一组两路装同一条 tag"的状态（本轮补的判别力缺口）----
  //
  //  ★为什么要有它★：l1 的 PLRU 命中更新，golden 写的是 `hitVec[0]`
  //  （2 路的 access(way)=~way，而 hitWay=~hitVec[0]，两个取反抵消）。
  //  把它写成 `~hitVec[1]` 在**只有一路命中**时值恒等 —— 两种写法只有在
  //  l1 两路**同时命中**（hitVec=2'b11）时才不同。
  //  原来的激励每拍 vpn/s2xlate/ptes 全新随机，产生不出"同组两路同 tag"的状态，
  //  于是 tb 头注释里的 mutant H6 errors=0 —— 那是**已知盲点，不是通过**。
  //
  //  ★造法★：固定一组 (vpn, s2xlate, 干净的 next 型 ptes) 用 128 拍，
  //  让 l1 回填反复用同一组。第一次落在某一路上；第二次时另一路还无效，
  //  而 replaceWrapper 优先挑无效路，于是落到另一路 —— 两路同 tag。
  //  之后拿同一条 vpn 去查，两路就会同时命中。
  //  同一组激励对 l0（4 路）同样有效，顺带把 l0 的多路同时命中也造出来。
  logic [37:0]  twin_vpn;
  logic [1:0]   twin_s2x;
  logic [511:0] twin_ptes;
  logic [63:0]  twin_sel;
  int           twin_cnt;
  int           fire_l1_double, fire_l0_double;

  //  非叶子、且各项 pf 判据都干净的 PTE：v=1，r/w/x=0，d/a/u/n/pbmt/reserved/
  //  ppn_high 全清。这样 canRefill 必过、vs 位必为 1，两次回填才真的都写进去。
  function automatic logic [63:0] clean_next_pte();
    logic [63:0] p;
    p        = '0;
    p[0]     = 1'b1;                                  // v
    p[45:10] = {4'($urandom()), $urandom()};          // ppn（高 8 位留 0）
    return p;
  endfunction

  task automatic drive_twin();
    if (twin_cnt <= 0) begin
      twin_cnt = 128;
      twin_vpn = pick_vpn();
      twin_s2x = $urandom_range(0,3);
      for (int k = 0; k < 8; k++) twin_ptes[64*k +: 64] = clean_next_pte();
      twin_sel = clean_next_pte();
    end
    twin_cnt--;
    // 四分之一的拍用同一组参数回填（dup_1 管 l1、dup_0 管 l0，两份都给同一组，
    // 这样 l1 与 l0 都能造出多路同 tag；三份 dup 的**独立性**由其余四分之三的拍保住）。
    if ($urandom_range(0,3) == 0) begin
      io_refill_valid                       = 1'b1;
      io_refill_bits_levelOH_l1             = 1'b1;
      io_refill_bits_levelOH_l0             = 1'b1;
      io_refill_bits_ptes                   = twin_ptes;
      io_refill_bits_sel_pte_dup_0          = twin_sel;
      io_refill_bits_req_info_dup_1_vpn     = twin_vpn;
      io_refill_bits_req_info_dup_1_s2xlate = twin_s2x;
      io_refill_bits_req_info_dup_0_vpn     = twin_vpn;
      io_refill_bits_req_info_dup_0_s2xlate = twin_s2x;
    end
    // 四分之一的拍查这条 vpn（s2xlate 必须同源，否则 h/asid 对不上，白填）
    if ($urandom_range(0,3) == 0) begin
      io_req_valid                 = 1'b1;
      io_req_bits_req_info_vpn     = twin_vpn;
      io_req_bits_req_info_s2xlate = twin_s2x;
    end
  endtask

  //  wakeup：上层查完 bitmap 回来补票。way_info 是 one-hot。
  //  ★一半用"刚回填那一路"（io_l0_way_info），一半随机★：
  //   只给随机的话命中率太低，§22 的写路径几乎走不到；只给回填那一路的话
  //   "way_info 的 OHToUInt 写错" 这类错误又测不出来。
  logic [3:0] last_way_info;
  task automatic drive_wakeup();
    logic [37:0] v;
    io_bitmap_wakeup_valid = 1'b0;
    if ($urandom_range(0,7) == 0) begin
      v = pick_vpn();
      io_bitmap_wakeup_valid             = 1'b1;
      io_bitmap_wakeup_bits_tag          = v;
      io_bitmap_wakeup_bits_setIndex     = ($urandom_range(0,3) == 0)
                                             ? 6'($urandom()) : v[8:3];
      io_bitmap_wakeup_bits_way_info     = ($urandom_range(0,1) && last_way_info != 0)
                                             ? last_way_info
                                             : (4'h1 << $urandom_range(0,3));
      io_bitmap_wakeup_bits_pte_index    = ($urandom_range(0,3) == 0)
                                             ? 3'($urandom()) : v[2:0];
      io_bitmap_wakeup_bits_check_success = $urandom_range(0,1);
      io_bitmap_wakeup_bits_s2xlate      = $urandom_range(0,3);
    end
  endtask

  function automatic logic [37:0] pick_vpn();
    logic [37:0] v;
    int b;
    // 四分之一全随机，保住"vpn 写错位"这类错误的判别力；
    // 再四分之一取**近失**：池子里的一条翻掉一位。
    // ★近失这一路是补上去的，理由是实测的一个漏检★：
    //   mutant「sp 的 level==1 少比一段 tag（tm1）」在只有"整条相同 / 整条随机"
    //   两种 vpn 的激励下 errors=0 —— 因为 tm3&tm2 相同就意味着是同一条池子项，
    //   tm1 必然也相同；而全随机的 vpn 又几乎不可能撞中 tm3&tm2。
    //   翻一位之后，"高段相同、某一段不同"这种组合才真的会出现。
    if ($urandom_range(0,3) == 0) return {$urandom(), $urandom()};
    v = vpn_pool[$urandom_range(0,3)];
    if ($urandom_range(0,2) == 0) begin
      b    = $urandom_range(0,37);   // ★同一个下标，别写成两次 $urandom_range★
      v[b] = ~v[b];
    end
    return v;
  endfunction

  task automatic drive_random();
    io_req_valid                     = $urandom_range(0,1);
    io_resp_ready                    = $urandom_range(0,1);
    io_req_bits_req_info_vpn         = pick_vpn();
    io_req_bits_req_info_s2xlate     = $urandom_range(0,3);
    io_req_bits_req_info_source      = $urandom_range(0,3);
    io_req_bits_isFirst              = $urandom_range(0,1);
    io_req_bits_isHptwReq            = $urandom_range(0,1);
    io_req_bits_hptwId               = $urandom_range(0,7);

    for (int k = 0; k < 8; k++) io_refill_bits_ptes[64*k +: 64] = rand_pte();
    io_refill_bits_sel_pte_dup_0 = rand_pte();
    io_refill_bits_sel_pte_dup_2 = rand_pte();
    io_refill_valid               = $urandom_range(0,1);
    io_refill_bits_levelOH_sp     = $urandom_range(0,1);
    io_refill_bits_levelOH_l0     = $urandom_range(0,1);
    io_refill_bits_levelOH_l1     = $urandom_range(0,1);
    io_refill_bits_levelOH_l2     = $urandom_range(0,1);
    io_refill_bits_levelOH_l3     = $urandom_range(0,1);
    io_refill_bits_level_dup_0    = $urandom_range(0,3);
    io_refill_bits_level_dup_2    = $urandom_range(0,3);
    // ★三份 dup 的 vpn/s2xlate/source 各自独立随机★：绑成一根线的话，
    // "dup 归属写错"这类错误在本对照里按构造测不出来。
    io_refill_bits_req_info_dup_0_vpn     = pick_vpn();
    io_refill_bits_req_info_dup_0_s2xlate = $urandom_range(0,3);
    io_refill_bits_req_info_dup_0_source  = $urandom_range(0,3);
    io_refill_bits_req_info_dup_1_vpn     = pick_vpn();
    io_refill_bits_req_info_dup_1_s2xlate = $urandom_range(0,3);
    io_refill_bits_req_info_dup_1_source  = $urandom_range(0,3);
    io_refill_bits_req_info_dup_2_vpn     = pick_vpn();
    io_refill_bits_req_info_dup_2_s2xlate = $urandom_range(0,3);
    io_refill_bits_req_info_dup_2_source  = $urandom_range(0,3);
  endtask

  // BEGIN GENERATED(state_cmp)
  // 由 gen_state_cmp.py 生成（golden 展平标量 <-> 重写核 struct 数组的路径对照）。
  // 手改这段会被下次生成覆盖；要改请改生成器。
  task automatic compare_state();
    chk("l3v", dut_g.l3v, dut_i.u_core.l3v);
    chk("l2v", dut_g.l2v, dut_i.u_core.l2v);
    chk("l1v", dut_g.l1v, dut_i.u_core.l1v);
    chk("spv", dut_g.spv, dut_i.u_core.spv);
    chk("l3g", dut_g.l3g, dut_i.u_core.l3g);
    chk("l2g", dut_g.l2g, dut_i.u_core.l2g);
    chk("l1g", dut_g.l1g, dut_i.u_core.l1g);
    chk("spg", dut_g.spg, dut_i.u_core.spg);
    chk("l0v[0]", dut_g.l0v[63:0], dut_i.u_core.l0v[63:0]);
    chk("l0v[1]", dut_g.l0v[127:64], dut_i.u_core.l0v[127:64]);
    chk("l0v[2]", dut_g.l0v[191:128], dut_i.u_core.l0v[191:128]);
    chk("l0v[3]", dut_g.l0v[255:192], dut_i.u_core.l0v[255:192]);
    chk("l0g[0]", dut_g.l0g[63:0], dut_i.u_core.l0g[63:0]);
    chk("l0g[1]", dut_g.l0g[127:64], dut_i.u_core.l0g[127:64]);
    chk("l0g[2]", dut_g.l0g[191:128], dut_i.u_core.l0g[191:128]);
    chk("l0g[3]", dut_g.l0g[255:192], dut_i.u_core.l0g[255:192]);
    chk("plru_l3", dut_g.state_reg, dut_i.u_core.plru_l3);
    chk("plru_l2", dut_g.state_reg_1, dut_i.u_core.plru_l2);
    chk("plru_sp", dut_g.state_reg_4, dut_i.u_core.plru_sp);
    chk("plru_l1[0]", dut_g.state_vec_0, dut_i.u_core.plru_l1[0]);
    chk("plru_l1[1]", dut_g.state_vec_1, dut_i.u_core.plru_l1[1]);
    chk("plru_l1[2]", dut_g.state_vec_2, dut_i.u_core.plru_l1[2]);
    chk("plru_l1[3]", dut_g.state_vec_3, dut_i.u_core.plru_l1[3]);
    chk("plru_l0[0]", dut_g.state_vec_1_0, dut_i.u_core.plru_l0[0]);
    chk("plru_l0[1]", dut_g.state_vec_1_1, dut_i.u_core.plru_l0[1]);
    chk("plru_l0[2]", dut_g.state_vec_1_2, dut_i.u_core.plru_l0[2]);
    chk("plru_l0[3]", dut_g.state_vec_1_3, dut_i.u_core.plru_l0[3]);
    chk("plru_l0[4]", dut_g.state_vec_1_4, dut_i.u_core.plru_l0[4]);
    chk("plru_l0[5]", dut_g.state_vec_1_5, dut_i.u_core.plru_l0[5]);
    chk("plru_l0[6]", dut_g.state_vec_1_6, dut_i.u_core.plru_l0[6]);
    chk("plru_l0[7]", dut_g.state_vec_1_7, dut_i.u_core.plru_l0[7]);
    chk("plru_l0[8]", dut_g.state_vec_1_8, dut_i.u_core.plru_l0[8]);
    chk("plru_l0[9]", dut_g.state_vec_1_9, dut_i.u_core.plru_l0[9]);
    chk("plru_l0[10]", dut_g.state_vec_1_10, dut_i.u_core.plru_l0[10]);
    chk("plru_l0[11]", dut_g.state_vec_1_11, dut_i.u_core.plru_l0[11]);
    chk("plru_l0[12]", dut_g.state_vec_1_12, dut_i.u_core.plru_l0[12]);
    chk("plru_l0[13]", dut_g.state_vec_1_13, dut_i.u_core.plru_l0[13]);
    chk("plru_l0[14]", dut_g.state_vec_1_14, dut_i.u_core.plru_l0[14]);
    chk("plru_l0[15]", dut_g.state_vec_1_15, dut_i.u_core.plru_l0[15]);
    chk("plru_l0[16]", dut_g.state_vec_1_16, dut_i.u_core.plru_l0[16]);
    chk("plru_l0[17]", dut_g.state_vec_1_17, dut_i.u_core.plru_l0[17]);
    chk("plru_l0[18]", dut_g.state_vec_1_18, dut_i.u_core.plru_l0[18]);
    chk("plru_l0[19]", dut_g.state_vec_1_19, dut_i.u_core.plru_l0[19]);
    chk("plru_l0[20]", dut_g.state_vec_1_20, dut_i.u_core.plru_l0[20]);
    chk("plru_l0[21]", dut_g.state_vec_1_21, dut_i.u_core.plru_l0[21]);
    chk("plru_l0[22]", dut_g.state_vec_1_22, dut_i.u_core.plru_l0[22]);
    chk("plru_l0[23]", dut_g.state_vec_1_23, dut_i.u_core.plru_l0[23]);
    chk("plru_l0[24]", dut_g.state_vec_1_24, dut_i.u_core.plru_l0[24]);
    chk("plru_l0[25]", dut_g.state_vec_1_25, dut_i.u_core.plru_l0[25]);
    chk("plru_l0[26]", dut_g.state_vec_1_26, dut_i.u_core.plru_l0[26]);
    chk("plru_l0[27]", dut_g.state_vec_1_27, dut_i.u_core.plru_l0[27]);
    chk("plru_l0[28]", dut_g.state_vec_1_28, dut_i.u_core.plru_l0[28]);
    chk("plru_l0[29]", dut_g.state_vec_1_29, dut_i.u_core.plru_l0[29]);
    chk("plru_l0[30]", dut_g.state_vec_1_30, dut_i.u_core.plru_l0[30]);
    chk("plru_l0[31]", dut_g.state_vec_1_31, dut_i.u_core.plru_l0[31]);
    chk("plru_l0[32]", dut_g.state_vec_1_32, dut_i.u_core.plru_l0[32]);
    chk("plru_l0[33]", dut_g.state_vec_1_33, dut_i.u_core.plru_l0[33]);
    chk("plru_l0[34]", dut_g.state_vec_1_34, dut_i.u_core.plru_l0[34]);
    chk("plru_l0[35]", dut_g.state_vec_1_35, dut_i.u_core.plru_l0[35]);
    chk("plru_l0[36]", dut_g.state_vec_1_36, dut_i.u_core.plru_l0[36]);
    chk("plru_l0[37]", dut_g.state_vec_1_37, dut_i.u_core.plru_l0[37]);
    chk("plru_l0[38]", dut_g.state_vec_1_38, dut_i.u_core.plru_l0[38]);
    chk("plru_l0[39]", dut_g.state_vec_1_39, dut_i.u_core.plru_l0[39]);
    chk("plru_l0[40]", dut_g.state_vec_1_40, dut_i.u_core.plru_l0[40]);
    chk("plru_l0[41]", dut_g.state_vec_1_41, dut_i.u_core.plru_l0[41]);
    chk("plru_l0[42]", dut_g.state_vec_1_42, dut_i.u_core.plru_l0[42]);
    chk("plru_l0[43]", dut_g.state_vec_1_43, dut_i.u_core.plru_l0[43]);
    chk("plru_l0[44]", dut_g.state_vec_1_44, dut_i.u_core.plru_l0[44]);
    chk("plru_l0[45]", dut_g.state_vec_1_45, dut_i.u_core.plru_l0[45]);
    chk("plru_l0[46]", dut_g.state_vec_1_46, dut_i.u_core.plru_l0[46]);
    chk("plru_l0[47]", dut_g.state_vec_1_47, dut_i.u_core.plru_l0[47]);
    chk("plru_l0[48]", dut_g.state_vec_1_48, dut_i.u_core.plru_l0[48]);
    chk("plru_l0[49]", dut_g.state_vec_1_49, dut_i.u_core.plru_l0[49]);
    chk("plru_l0[50]", dut_g.state_vec_1_50, dut_i.u_core.plru_l0[50]);
    chk("plru_l0[51]", dut_g.state_vec_1_51, dut_i.u_core.plru_l0[51]);
    chk("plru_l0[52]", dut_g.state_vec_1_52, dut_i.u_core.plru_l0[52]);
    chk("plru_l0[53]", dut_g.state_vec_1_53, dut_i.u_core.plru_l0[53]);
    chk("plru_l0[54]", dut_g.state_vec_1_54, dut_i.u_core.plru_l0[54]);
    chk("plru_l0[55]", dut_g.state_vec_1_55, dut_i.u_core.plru_l0[55]);
    chk("plru_l0[56]", dut_g.state_vec_1_56, dut_i.u_core.plru_l0[56]);
    chk("plru_l0[57]", dut_g.state_vec_1_57, dut_i.u_core.plru_l0[57]);
    chk("plru_l0[58]", dut_g.state_vec_1_58, dut_i.u_core.plru_l0[58]);
    chk("plru_l0[59]", dut_g.state_vec_1_59, dut_i.u_core.plru_l0[59]);
    chk("plru_l0[60]", dut_g.state_vec_1_60, dut_i.u_core.plru_l0[60]);
    chk("plru_l0[61]", dut_g.state_vec_1_61, dut_i.u_core.plru_l0[61]);
    chk("plru_l0[62]", dut_g.state_vec_1_62, dut_i.u_core.plru_l0[62]);
    chk("plru_l0[63]", dut_g.state_vec_1_63, dut_i.u_core.plru_l0[63]);
    chk("l3[0].tag", dut_g.l3_0_tag, dut_i.u_core.l3_entry[0].tag);
    chk("l3[0].asid", dut_g.l3_0_asid, dut_i.u_core.l3_entry[0].asid);
    chk("l3[0].vmid", dut_g.l3_0_vmid, dut_i.u_core.l3_entry[0].vmid);
    chk("l3[0].ppn", dut_g.l3_0_ppn, dut_i.u_core.l3_entry[0].ppn);
    chk("l3[0].prefetch", dut_g.l3_0_prefetch, dut_i.u_core.l3_entry[0].prefetch);
    chk("l3h[0]", dut_g.l3h_0, dut_i.u_core.l3h[0]);
    chk("l3[1].tag", dut_g.l3_1_tag, dut_i.u_core.l3_entry[1].tag);
    chk("l3[1].asid", dut_g.l3_1_asid, dut_i.u_core.l3_entry[1].asid);
    chk("l3[1].vmid", dut_g.l3_1_vmid, dut_i.u_core.l3_entry[1].vmid);
    chk("l3[1].ppn", dut_g.l3_1_ppn, dut_i.u_core.l3_entry[1].ppn);
    chk("l3[1].prefetch", dut_g.l3_1_prefetch, dut_i.u_core.l3_entry[1].prefetch);
    chk("l3h[1]", dut_g.l3h_1, dut_i.u_core.l3h[1]);
    chk("l3[2].tag", dut_g.l3_2_tag, dut_i.u_core.l3_entry[2].tag);
    chk("l3[2].asid", dut_g.l3_2_asid, dut_i.u_core.l3_entry[2].asid);
    chk("l3[2].vmid", dut_g.l3_2_vmid, dut_i.u_core.l3_entry[2].vmid);
    chk("l3[2].ppn", dut_g.l3_2_ppn, dut_i.u_core.l3_entry[2].ppn);
    chk("l3[2].prefetch", dut_g.l3_2_prefetch, dut_i.u_core.l3_entry[2].prefetch);
    chk("l3h[2]", dut_g.l3h_2, dut_i.u_core.l3h[2]);
    chk("l3[3].tag", dut_g.l3_3_tag, dut_i.u_core.l3_entry[3].tag);
    chk("l3[3].asid", dut_g.l3_3_asid, dut_i.u_core.l3_entry[3].asid);
    chk("l3[3].vmid", dut_g.l3_3_vmid, dut_i.u_core.l3_entry[3].vmid);
    chk("l3[3].ppn", dut_g.l3_3_ppn, dut_i.u_core.l3_entry[3].ppn);
    chk("l3[3].prefetch", dut_g.l3_3_prefetch, dut_i.u_core.l3_entry[3].prefetch);
    chk("l3h[3]", dut_g.l3h_3, dut_i.u_core.l3h[3]);
    chk("l3[4].tag", dut_g.l3_4_tag, dut_i.u_core.l3_entry[4].tag);
    chk("l3[4].asid", dut_g.l3_4_asid, dut_i.u_core.l3_entry[4].asid);
    chk("l3[4].vmid", dut_g.l3_4_vmid, dut_i.u_core.l3_entry[4].vmid);
    chk("l3[4].ppn", dut_g.l3_4_ppn, dut_i.u_core.l3_entry[4].ppn);
    chk("l3[4].prefetch", dut_g.l3_4_prefetch, dut_i.u_core.l3_entry[4].prefetch);
    chk("l3h[4]", dut_g.l3h_4, dut_i.u_core.l3h[4]);
    chk("l3[5].tag", dut_g.l3_5_tag, dut_i.u_core.l3_entry[5].tag);
    chk("l3[5].asid", dut_g.l3_5_asid, dut_i.u_core.l3_entry[5].asid);
    chk("l3[5].vmid", dut_g.l3_5_vmid, dut_i.u_core.l3_entry[5].vmid);
    chk("l3[5].ppn", dut_g.l3_5_ppn, dut_i.u_core.l3_entry[5].ppn);
    chk("l3[5].prefetch", dut_g.l3_5_prefetch, dut_i.u_core.l3_entry[5].prefetch);
    chk("l3h[5]", dut_g.l3h_5, dut_i.u_core.l3h[5]);
    chk("l3[6].tag", dut_g.l3_6_tag, dut_i.u_core.l3_entry[6].tag);
    chk("l3[6].asid", dut_g.l3_6_asid, dut_i.u_core.l3_entry[6].asid);
    chk("l3[6].vmid", dut_g.l3_6_vmid, dut_i.u_core.l3_entry[6].vmid);
    chk("l3[6].ppn", dut_g.l3_6_ppn, dut_i.u_core.l3_entry[6].ppn);
    chk("l3[6].prefetch", dut_g.l3_6_prefetch, dut_i.u_core.l3_entry[6].prefetch);
    chk("l3h[6]", dut_g.l3h_6, dut_i.u_core.l3h[6]);
    chk("l3[7].tag", dut_g.l3_7_tag, dut_i.u_core.l3_entry[7].tag);
    chk("l3[7].asid", dut_g.l3_7_asid, dut_i.u_core.l3_entry[7].asid);
    chk("l3[7].vmid", dut_g.l3_7_vmid, dut_i.u_core.l3_entry[7].vmid);
    chk("l3[7].ppn", dut_g.l3_7_ppn, dut_i.u_core.l3_entry[7].ppn);
    chk("l3[7].prefetch", dut_g.l3_7_prefetch, dut_i.u_core.l3_entry[7].prefetch);
    chk("l3h[7]", dut_g.l3h_7, dut_i.u_core.l3h[7]);
    chk("l3[8].tag", dut_g.l3_8_tag, dut_i.u_core.l3_entry[8].tag);
    chk("l3[8].asid", dut_g.l3_8_asid, dut_i.u_core.l3_entry[8].asid);
    chk("l3[8].vmid", dut_g.l3_8_vmid, dut_i.u_core.l3_entry[8].vmid);
    chk("l3[8].ppn", dut_g.l3_8_ppn, dut_i.u_core.l3_entry[8].ppn);
    chk("l3[8].prefetch", dut_g.l3_8_prefetch, dut_i.u_core.l3_entry[8].prefetch);
    chk("l3h[8]", dut_g.l3h_8, dut_i.u_core.l3h[8]);
    chk("l3[9].tag", dut_g.l3_9_tag, dut_i.u_core.l3_entry[9].tag);
    chk("l3[9].asid", dut_g.l3_9_asid, dut_i.u_core.l3_entry[9].asid);
    chk("l3[9].vmid", dut_g.l3_9_vmid, dut_i.u_core.l3_entry[9].vmid);
    chk("l3[9].ppn", dut_g.l3_9_ppn, dut_i.u_core.l3_entry[9].ppn);
    chk("l3[9].prefetch", dut_g.l3_9_prefetch, dut_i.u_core.l3_entry[9].prefetch);
    chk("l3h[9]", dut_g.l3h_9, dut_i.u_core.l3h[9]);
    chk("l3[10].tag", dut_g.l3_10_tag, dut_i.u_core.l3_entry[10].tag);
    chk("l3[10].asid", dut_g.l3_10_asid, dut_i.u_core.l3_entry[10].asid);
    chk("l3[10].vmid", dut_g.l3_10_vmid, dut_i.u_core.l3_entry[10].vmid);
    chk("l3[10].ppn", dut_g.l3_10_ppn, dut_i.u_core.l3_entry[10].ppn);
    chk("l3[10].prefetch", dut_g.l3_10_prefetch, dut_i.u_core.l3_entry[10].prefetch);
    chk("l3h[10]", dut_g.l3h_10, dut_i.u_core.l3h[10]);
    chk("l3[11].tag", dut_g.l3_11_tag, dut_i.u_core.l3_entry[11].tag);
    chk("l3[11].asid", dut_g.l3_11_asid, dut_i.u_core.l3_entry[11].asid);
    chk("l3[11].vmid", dut_g.l3_11_vmid, dut_i.u_core.l3_entry[11].vmid);
    chk("l3[11].ppn", dut_g.l3_11_ppn, dut_i.u_core.l3_entry[11].ppn);
    chk("l3[11].prefetch", dut_g.l3_11_prefetch, dut_i.u_core.l3_entry[11].prefetch);
    chk("l3h[11]", dut_g.l3h_11, dut_i.u_core.l3h[11]);
    chk("l3[12].tag", dut_g.l3_12_tag, dut_i.u_core.l3_entry[12].tag);
    chk("l3[12].asid", dut_g.l3_12_asid, dut_i.u_core.l3_entry[12].asid);
    chk("l3[12].vmid", dut_g.l3_12_vmid, dut_i.u_core.l3_entry[12].vmid);
    chk("l3[12].ppn", dut_g.l3_12_ppn, dut_i.u_core.l3_entry[12].ppn);
    chk("l3[12].prefetch", dut_g.l3_12_prefetch, dut_i.u_core.l3_entry[12].prefetch);
    chk("l3h[12]", dut_g.l3h_12, dut_i.u_core.l3h[12]);
    chk("l3[13].tag", dut_g.l3_13_tag, dut_i.u_core.l3_entry[13].tag);
    chk("l3[13].asid", dut_g.l3_13_asid, dut_i.u_core.l3_entry[13].asid);
    chk("l3[13].vmid", dut_g.l3_13_vmid, dut_i.u_core.l3_entry[13].vmid);
    chk("l3[13].ppn", dut_g.l3_13_ppn, dut_i.u_core.l3_entry[13].ppn);
    chk("l3[13].prefetch", dut_g.l3_13_prefetch, dut_i.u_core.l3_entry[13].prefetch);
    chk("l3h[13]", dut_g.l3h_13, dut_i.u_core.l3h[13]);
    chk("l3[14].tag", dut_g.l3_14_tag, dut_i.u_core.l3_entry[14].tag);
    chk("l3[14].asid", dut_g.l3_14_asid, dut_i.u_core.l3_entry[14].asid);
    chk("l3[14].vmid", dut_g.l3_14_vmid, dut_i.u_core.l3_entry[14].vmid);
    chk("l3[14].ppn", dut_g.l3_14_ppn, dut_i.u_core.l3_entry[14].ppn);
    chk("l3[14].prefetch", dut_g.l3_14_prefetch, dut_i.u_core.l3_entry[14].prefetch);
    chk("l3h[14]", dut_g.l3h_14, dut_i.u_core.l3h[14]);
    chk("l3[15].tag", dut_g.l3_15_tag, dut_i.u_core.l3_entry[15].tag);
    chk("l3[15].asid", dut_g.l3_15_asid, dut_i.u_core.l3_entry[15].asid);
    chk("l3[15].vmid", dut_g.l3_15_vmid, dut_i.u_core.l3_entry[15].vmid);
    chk("l3[15].ppn", dut_g.l3_15_ppn, dut_i.u_core.l3_entry[15].ppn);
    chk("l3[15].prefetch", dut_g.l3_15_prefetch, dut_i.u_core.l3_entry[15].prefetch);
    chk("l3h[15]", dut_g.l3h_15, dut_i.u_core.l3h[15]);
    chk("l2[0].tag", dut_g.l2_0_tag, dut_i.u_core.l2_entry[0].tag);
    chk("l2[0].asid", dut_g.l2_0_asid, dut_i.u_core.l2_entry[0].asid);
    chk("l2[0].vmid", dut_g.l2_0_vmid, dut_i.u_core.l2_entry[0].vmid);
    chk("l2[0].pbmt", dut_g.l2_0_pbmt, dut_i.u_core.l2_entry[0].pbmt);
    chk("l2[0].ppn", dut_g.l2_0_ppn, dut_i.u_core.l2_entry[0].ppn);
    chk("l2[0].prefetch", dut_g.l2_0_prefetch, dut_i.u_core.l2_entry[0].prefetch);
    chk("l2h[0]", dut_g.l2h_0, dut_i.u_core.l2h[0]);
    chk("l2[1].tag", dut_g.l2_1_tag, dut_i.u_core.l2_entry[1].tag);
    chk("l2[1].asid", dut_g.l2_1_asid, dut_i.u_core.l2_entry[1].asid);
    chk("l2[1].vmid", dut_g.l2_1_vmid, dut_i.u_core.l2_entry[1].vmid);
    chk("l2[1].pbmt", dut_g.l2_1_pbmt, dut_i.u_core.l2_entry[1].pbmt);
    chk("l2[1].ppn", dut_g.l2_1_ppn, dut_i.u_core.l2_entry[1].ppn);
    chk("l2[1].prefetch", dut_g.l2_1_prefetch, dut_i.u_core.l2_entry[1].prefetch);
    chk("l2h[1]", dut_g.l2h_1, dut_i.u_core.l2h[1]);
    chk("l2[2].tag", dut_g.l2_2_tag, dut_i.u_core.l2_entry[2].tag);
    chk("l2[2].asid", dut_g.l2_2_asid, dut_i.u_core.l2_entry[2].asid);
    chk("l2[2].vmid", dut_g.l2_2_vmid, dut_i.u_core.l2_entry[2].vmid);
    chk("l2[2].pbmt", dut_g.l2_2_pbmt, dut_i.u_core.l2_entry[2].pbmt);
    chk("l2[2].ppn", dut_g.l2_2_ppn, dut_i.u_core.l2_entry[2].ppn);
    chk("l2[2].prefetch", dut_g.l2_2_prefetch, dut_i.u_core.l2_entry[2].prefetch);
    chk("l2h[2]", dut_g.l2h_2, dut_i.u_core.l2h[2]);
    chk("l2[3].tag", dut_g.l2_3_tag, dut_i.u_core.l2_entry[3].tag);
    chk("l2[3].asid", dut_g.l2_3_asid, dut_i.u_core.l2_entry[3].asid);
    chk("l2[3].vmid", dut_g.l2_3_vmid, dut_i.u_core.l2_entry[3].vmid);
    chk("l2[3].pbmt", dut_g.l2_3_pbmt, dut_i.u_core.l2_entry[3].pbmt);
    chk("l2[3].ppn", dut_g.l2_3_ppn, dut_i.u_core.l2_entry[3].ppn);
    chk("l2[3].prefetch", dut_g.l2_3_prefetch, dut_i.u_core.l2_entry[3].prefetch);
    chk("l2h[3]", dut_g.l2h_3, dut_i.u_core.l2h[3]);
    chk("l2[4].tag", dut_g.l2_4_tag, dut_i.u_core.l2_entry[4].tag);
    chk("l2[4].asid", dut_g.l2_4_asid, dut_i.u_core.l2_entry[4].asid);
    chk("l2[4].vmid", dut_g.l2_4_vmid, dut_i.u_core.l2_entry[4].vmid);
    chk("l2[4].pbmt", dut_g.l2_4_pbmt, dut_i.u_core.l2_entry[4].pbmt);
    chk("l2[4].ppn", dut_g.l2_4_ppn, dut_i.u_core.l2_entry[4].ppn);
    chk("l2[4].prefetch", dut_g.l2_4_prefetch, dut_i.u_core.l2_entry[4].prefetch);
    chk("l2h[4]", dut_g.l2h_4, dut_i.u_core.l2h[4]);
    chk("l2[5].tag", dut_g.l2_5_tag, dut_i.u_core.l2_entry[5].tag);
    chk("l2[5].asid", dut_g.l2_5_asid, dut_i.u_core.l2_entry[5].asid);
    chk("l2[5].vmid", dut_g.l2_5_vmid, dut_i.u_core.l2_entry[5].vmid);
    chk("l2[5].pbmt", dut_g.l2_5_pbmt, dut_i.u_core.l2_entry[5].pbmt);
    chk("l2[5].ppn", dut_g.l2_5_ppn, dut_i.u_core.l2_entry[5].ppn);
    chk("l2[5].prefetch", dut_g.l2_5_prefetch, dut_i.u_core.l2_entry[5].prefetch);
    chk("l2h[5]", dut_g.l2h_5, dut_i.u_core.l2h[5]);
    chk("l2[6].tag", dut_g.l2_6_tag, dut_i.u_core.l2_entry[6].tag);
    chk("l2[6].asid", dut_g.l2_6_asid, dut_i.u_core.l2_entry[6].asid);
    chk("l2[6].vmid", dut_g.l2_6_vmid, dut_i.u_core.l2_entry[6].vmid);
    chk("l2[6].pbmt", dut_g.l2_6_pbmt, dut_i.u_core.l2_entry[6].pbmt);
    chk("l2[6].ppn", dut_g.l2_6_ppn, dut_i.u_core.l2_entry[6].ppn);
    chk("l2[6].prefetch", dut_g.l2_6_prefetch, dut_i.u_core.l2_entry[6].prefetch);
    chk("l2h[6]", dut_g.l2h_6, dut_i.u_core.l2h[6]);
    chk("l2[7].tag", dut_g.l2_7_tag, dut_i.u_core.l2_entry[7].tag);
    chk("l2[7].asid", dut_g.l2_7_asid, dut_i.u_core.l2_entry[7].asid);
    chk("l2[7].vmid", dut_g.l2_7_vmid, dut_i.u_core.l2_entry[7].vmid);
    chk("l2[7].pbmt", dut_g.l2_7_pbmt, dut_i.u_core.l2_entry[7].pbmt);
    chk("l2[7].ppn", dut_g.l2_7_ppn, dut_i.u_core.l2_entry[7].ppn);
    chk("l2[7].prefetch", dut_g.l2_7_prefetch, dut_i.u_core.l2_entry[7].prefetch);
    chk("l2h[7]", dut_g.l2h_7, dut_i.u_core.l2h[7]);
    chk("l2[8].tag", dut_g.l2_8_tag, dut_i.u_core.l2_entry[8].tag);
    chk("l2[8].asid", dut_g.l2_8_asid, dut_i.u_core.l2_entry[8].asid);
    chk("l2[8].vmid", dut_g.l2_8_vmid, dut_i.u_core.l2_entry[8].vmid);
    chk("l2[8].pbmt", dut_g.l2_8_pbmt, dut_i.u_core.l2_entry[8].pbmt);
    chk("l2[8].ppn", dut_g.l2_8_ppn, dut_i.u_core.l2_entry[8].ppn);
    chk("l2[8].prefetch", dut_g.l2_8_prefetch, dut_i.u_core.l2_entry[8].prefetch);
    chk("l2h[8]", dut_g.l2h_8, dut_i.u_core.l2h[8]);
    chk("l2[9].tag", dut_g.l2_9_tag, dut_i.u_core.l2_entry[9].tag);
    chk("l2[9].asid", dut_g.l2_9_asid, dut_i.u_core.l2_entry[9].asid);
    chk("l2[9].vmid", dut_g.l2_9_vmid, dut_i.u_core.l2_entry[9].vmid);
    chk("l2[9].pbmt", dut_g.l2_9_pbmt, dut_i.u_core.l2_entry[9].pbmt);
    chk("l2[9].ppn", dut_g.l2_9_ppn, dut_i.u_core.l2_entry[9].ppn);
    chk("l2[9].prefetch", dut_g.l2_9_prefetch, dut_i.u_core.l2_entry[9].prefetch);
    chk("l2h[9]", dut_g.l2h_9, dut_i.u_core.l2h[9]);
    chk("l2[10].tag", dut_g.l2_10_tag, dut_i.u_core.l2_entry[10].tag);
    chk("l2[10].asid", dut_g.l2_10_asid, dut_i.u_core.l2_entry[10].asid);
    chk("l2[10].vmid", dut_g.l2_10_vmid, dut_i.u_core.l2_entry[10].vmid);
    chk("l2[10].pbmt", dut_g.l2_10_pbmt, dut_i.u_core.l2_entry[10].pbmt);
    chk("l2[10].ppn", dut_g.l2_10_ppn, dut_i.u_core.l2_entry[10].ppn);
    chk("l2[10].prefetch", dut_g.l2_10_prefetch, dut_i.u_core.l2_entry[10].prefetch);
    chk("l2h[10]", dut_g.l2h_10, dut_i.u_core.l2h[10]);
    chk("l2[11].tag", dut_g.l2_11_tag, dut_i.u_core.l2_entry[11].tag);
    chk("l2[11].asid", dut_g.l2_11_asid, dut_i.u_core.l2_entry[11].asid);
    chk("l2[11].vmid", dut_g.l2_11_vmid, dut_i.u_core.l2_entry[11].vmid);
    chk("l2[11].pbmt", dut_g.l2_11_pbmt, dut_i.u_core.l2_entry[11].pbmt);
    chk("l2[11].ppn", dut_g.l2_11_ppn, dut_i.u_core.l2_entry[11].ppn);
    chk("l2[11].prefetch", dut_g.l2_11_prefetch, dut_i.u_core.l2_entry[11].prefetch);
    chk("l2h[11]", dut_g.l2h_11, dut_i.u_core.l2h[11]);
    chk("l2[12].tag", dut_g.l2_12_tag, dut_i.u_core.l2_entry[12].tag);
    chk("l2[12].asid", dut_g.l2_12_asid, dut_i.u_core.l2_entry[12].asid);
    chk("l2[12].vmid", dut_g.l2_12_vmid, dut_i.u_core.l2_entry[12].vmid);
    chk("l2[12].pbmt", dut_g.l2_12_pbmt, dut_i.u_core.l2_entry[12].pbmt);
    chk("l2[12].ppn", dut_g.l2_12_ppn, dut_i.u_core.l2_entry[12].ppn);
    chk("l2[12].prefetch", dut_g.l2_12_prefetch, dut_i.u_core.l2_entry[12].prefetch);
    chk("l2h[12]", dut_g.l2h_12, dut_i.u_core.l2h[12]);
    chk("l2[13].tag", dut_g.l2_13_tag, dut_i.u_core.l2_entry[13].tag);
    chk("l2[13].asid", dut_g.l2_13_asid, dut_i.u_core.l2_entry[13].asid);
    chk("l2[13].vmid", dut_g.l2_13_vmid, dut_i.u_core.l2_entry[13].vmid);
    chk("l2[13].pbmt", dut_g.l2_13_pbmt, dut_i.u_core.l2_entry[13].pbmt);
    chk("l2[13].ppn", dut_g.l2_13_ppn, dut_i.u_core.l2_entry[13].ppn);
    chk("l2[13].prefetch", dut_g.l2_13_prefetch, dut_i.u_core.l2_entry[13].prefetch);
    chk("l2h[13]", dut_g.l2h_13, dut_i.u_core.l2h[13]);
    chk("l2[14].tag", dut_g.l2_14_tag, dut_i.u_core.l2_entry[14].tag);
    chk("l2[14].asid", dut_g.l2_14_asid, dut_i.u_core.l2_entry[14].asid);
    chk("l2[14].vmid", dut_g.l2_14_vmid, dut_i.u_core.l2_entry[14].vmid);
    chk("l2[14].pbmt", dut_g.l2_14_pbmt, dut_i.u_core.l2_entry[14].pbmt);
    chk("l2[14].ppn", dut_g.l2_14_ppn, dut_i.u_core.l2_entry[14].ppn);
    chk("l2[14].prefetch", dut_g.l2_14_prefetch, dut_i.u_core.l2_entry[14].prefetch);
    chk("l2h[14]", dut_g.l2h_14, dut_i.u_core.l2h[14]);
    chk("l2[15].tag", dut_g.l2_15_tag, dut_i.u_core.l2_entry[15].tag);
    chk("l2[15].asid", dut_g.l2_15_asid, dut_i.u_core.l2_entry[15].asid);
    chk("l2[15].vmid", dut_g.l2_15_vmid, dut_i.u_core.l2_entry[15].vmid);
    chk("l2[15].pbmt", dut_g.l2_15_pbmt, dut_i.u_core.l2_entry[15].pbmt);
    chk("l2[15].ppn", dut_g.l2_15_ppn, dut_i.u_core.l2_entry[15].ppn);
    chk("l2[15].prefetch", dut_g.l2_15_prefetch, dut_i.u_core.l2_entry[15].prefetch);
    chk("l2h[15]", dut_g.l2h_15, dut_i.u_core.l2h[15]);
    chk("sp[0].tag", dut_g.sp_0_tag, dut_i.u_core.sp_entry[0].tag);
    chk("sp[0].asid", dut_g.sp_0_asid, dut_i.u_core.sp_entry[0].asid);
    chk("sp[0].vmid", dut_g.sp_0_vmid, dut_i.u_core.sp_entry[0].vmid);
    chk("sp[0].n", dut_g.sp_0_n, dut_i.u_core.sp_entry[0].n);
    chk("sp[0].pbmt", dut_g.sp_0_pbmt, dut_i.u_core.sp_entry[0].pbmt);
    chk("sp[0].ppn", dut_g.sp_0_ppn, dut_i.u_core.sp_entry[0].ppn);
    chk("sp[0].level", dut_g.sp_0_level, dut_i.u_core.sp_entry[0].level);
    chk("sp[0].prefetch", dut_g.sp_0_prefetch, dut_i.u_core.sp_entry[0].prefetch);
    chk("sp[0].v", dut_g.sp_0_v, dut_i.u_core.sp_entry[0].v);
    chk("sp[0].perm.d", dut_g.sp_0_perm_d, dut_i.u_core.sp_entry[0].perm.d);
    chk("sp[0].perm.a", dut_g.sp_0_perm_a, dut_i.u_core.sp_entry[0].perm.a);
    chk("sp[0].perm.g", dut_g.sp_0_perm_g, dut_i.u_core.sp_entry[0].perm.g);
    chk("sp[0].perm.u", dut_g.sp_0_perm_u, dut_i.u_core.sp_entry[0].perm.u);
    chk("sp[0].perm.x", dut_g.sp_0_perm_x, dut_i.u_core.sp_entry[0].perm.x);
    chk("sp[0].perm.w", dut_g.sp_0_perm_w, dut_i.u_core.sp_entry[0].perm.w);
    chk("sp[0].perm.r", dut_g.sp_0_perm_r, dut_i.u_core.sp_entry[0].perm.r);
    chk("sph[0]", dut_g.sph_0, dut_i.u_core.sph[0]);
    chk("sp[1].tag", dut_g.sp_1_tag, dut_i.u_core.sp_entry[1].tag);
    chk("sp[1].asid", dut_g.sp_1_asid, dut_i.u_core.sp_entry[1].asid);
    chk("sp[1].vmid", dut_g.sp_1_vmid, dut_i.u_core.sp_entry[1].vmid);
    chk("sp[1].n", dut_g.sp_1_n, dut_i.u_core.sp_entry[1].n);
    chk("sp[1].pbmt", dut_g.sp_1_pbmt, dut_i.u_core.sp_entry[1].pbmt);
    chk("sp[1].ppn", dut_g.sp_1_ppn, dut_i.u_core.sp_entry[1].ppn);
    chk("sp[1].level", dut_g.sp_1_level, dut_i.u_core.sp_entry[1].level);
    chk("sp[1].prefetch", dut_g.sp_1_prefetch, dut_i.u_core.sp_entry[1].prefetch);
    chk("sp[1].v", dut_g.sp_1_v, dut_i.u_core.sp_entry[1].v);
    chk("sp[1].perm.d", dut_g.sp_1_perm_d, dut_i.u_core.sp_entry[1].perm.d);
    chk("sp[1].perm.a", dut_g.sp_1_perm_a, dut_i.u_core.sp_entry[1].perm.a);
    chk("sp[1].perm.g", dut_g.sp_1_perm_g, dut_i.u_core.sp_entry[1].perm.g);
    chk("sp[1].perm.u", dut_g.sp_1_perm_u, dut_i.u_core.sp_entry[1].perm.u);
    chk("sp[1].perm.x", dut_g.sp_1_perm_x, dut_i.u_core.sp_entry[1].perm.x);
    chk("sp[1].perm.w", dut_g.sp_1_perm_w, dut_i.u_core.sp_entry[1].perm.w);
    chk("sp[1].perm.r", dut_g.sp_1_perm_r, dut_i.u_core.sp_entry[1].perm.r);
    chk("sph[1]", dut_g.sph_1, dut_i.u_core.sph[1]);
    chk("sp[2].tag", dut_g.sp_2_tag, dut_i.u_core.sp_entry[2].tag);
    chk("sp[2].asid", dut_g.sp_2_asid, dut_i.u_core.sp_entry[2].asid);
    chk("sp[2].vmid", dut_g.sp_2_vmid, dut_i.u_core.sp_entry[2].vmid);
    chk("sp[2].n", dut_g.sp_2_n, dut_i.u_core.sp_entry[2].n);
    chk("sp[2].pbmt", dut_g.sp_2_pbmt, dut_i.u_core.sp_entry[2].pbmt);
    chk("sp[2].ppn", dut_g.sp_2_ppn, dut_i.u_core.sp_entry[2].ppn);
    chk("sp[2].level", dut_g.sp_2_level, dut_i.u_core.sp_entry[2].level);
    chk("sp[2].prefetch", dut_g.sp_2_prefetch, dut_i.u_core.sp_entry[2].prefetch);
    chk("sp[2].v", dut_g.sp_2_v, dut_i.u_core.sp_entry[2].v);
    chk("sp[2].perm.d", dut_g.sp_2_perm_d, dut_i.u_core.sp_entry[2].perm.d);
    chk("sp[2].perm.a", dut_g.sp_2_perm_a, dut_i.u_core.sp_entry[2].perm.a);
    chk("sp[2].perm.g", dut_g.sp_2_perm_g, dut_i.u_core.sp_entry[2].perm.g);
    chk("sp[2].perm.u", dut_g.sp_2_perm_u, dut_i.u_core.sp_entry[2].perm.u);
    chk("sp[2].perm.x", dut_g.sp_2_perm_x, dut_i.u_core.sp_entry[2].perm.x);
    chk("sp[2].perm.w", dut_g.sp_2_perm_w, dut_i.u_core.sp_entry[2].perm.w);
    chk("sp[2].perm.r", dut_g.sp_2_perm_r, dut_i.u_core.sp_entry[2].perm.r);
    chk("sph[2]", dut_g.sph_2, dut_i.u_core.sph[2]);
    chk("sp[3].tag", dut_g.sp_3_tag, dut_i.u_core.sp_entry[3].tag);
    chk("sp[3].asid", dut_g.sp_3_asid, dut_i.u_core.sp_entry[3].asid);
    chk("sp[3].vmid", dut_g.sp_3_vmid, dut_i.u_core.sp_entry[3].vmid);
    chk("sp[3].n", dut_g.sp_3_n, dut_i.u_core.sp_entry[3].n);
    chk("sp[3].pbmt", dut_g.sp_3_pbmt, dut_i.u_core.sp_entry[3].pbmt);
    chk("sp[3].ppn", dut_g.sp_3_ppn, dut_i.u_core.sp_entry[3].ppn);
    chk("sp[3].level", dut_g.sp_3_level, dut_i.u_core.sp_entry[3].level);
    chk("sp[3].prefetch", dut_g.sp_3_prefetch, dut_i.u_core.sp_entry[3].prefetch);
    chk("sp[3].v", dut_g.sp_3_v, dut_i.u_core.sp_entry[3].v);
    chk("sp[3].perm.d", dut_g.sp_3_perm_d, dut_i.u_core.sp_entry[3].perm.d);
    chk("sp[3].perm.a", dut_g.sp_3_perm_a, dut_i.u_core.sp_entry[3].perm.a);
    chk("sp[3].perm.g", dut_g.sp_3_perm_g, dut_i.u_core.sp_entry[3].perm.g);
    chk("sp[3].perm.u", dut_g.sp_3_perm_u, dut_i.u_core.sp_entry[3].perm.u);
    chk("sp[3].perm.x", dut_g.sp_3_perm_x, dut_i.u_core.sp_entry[3].perm.x);
    chk("sp[3].perm.w", dut_g.sp_3_perm_w, dut_i.u_core.sp_entry[3].perm.w);
    chk("sp[3].perm.r", dut_g.sp_3_perm_r, dut_i.u_core.sp_entry[3].perm.r);
    chk("sph[3]", dut_g.sph_3, dut_i.u_core.sph[3]);
    chk("sp[4].tag", dut_g.sp_4_tag, dut_i.u_core.sp_entry[4].tag);
    chk("sp[4].asid", dut_g.sp_4_asid, dut_i.u_core.sp_entry[4].asid);
    chk("sp[4].vmid", dut_g.sp_4_vmid, dut_i.u_core.sp_entry[4].vmid);
    chk("sp[4].n", dut_g.sp_4_n, dut_i.u_core.sp_entry[4].n);
    chk("sp[4].pbmt", dut_g.sp_4_pbmt, dut_i.u_core.sp_entry[4].pbmt);
    chk("sp[4].ppn", dut_g.sp_4_ppn, dut_i.u_core.sp_entry[4].ppn);
    chk("sp[4].level", dut_g.sp_4_level, dut_i.u_core.sp_entry[4].level);
    chk("sp[4].prefetch", dut_g.sp_4_prefetch, dut_i.u_core.sp_entry[4].prefetch);
    chk("sp[4].v", dut_g.sp_4_v, dut_i.u_core.sp_entry[4].v);
    chk("sp[4].perm.d", dut_g.sp_4_perm_d, dut_i.u_core.sp_entry[4].perm.d);
    chk("sp[4].perm.a", dut_g.sp_4_perm_a, dut_i.u_core.sp_entry[4].perm.a);
    chk("sp[4].perm.g", dut_g.sp_4_perm_g, dut_i.u_core.sp_entry[4].perm.g);
    chk("sp[4].perm.u", dut_g.sp_4_perm_u, dut_i.u_core.sp_entry[4].perm.u);
    chk("sp[4].perm.x", dut_g.sp_4_perm_x, dut_i.u_core.sp_entry[4].perm.x);
    chk("sp[4].perm.w", dut_g.sp_4_perm_w, dut_i.u_core.sp_entry[4].perm.w);
    chk("sp[4].perm.r", dut_g.sp_4_perm_r, dut_i.u_core.sp_entry[4].perm.r);
    chk("sph[4]", dut_g.sph_4, dut_i.u_core.sph[4]);
    chk("sp[5].tag", dut_g.sp_5_tag, dut_i.u_core.sp_entry[5].tag);
    chk("sp[5].asid", dut_g.sp_5_asid, dut_i.u_core.sp_entry[5].asid);
    chk("sp[5].vmid", dut_g.sp_5_vmid, dut_i.u_core.sp_entry[5].vmid);
    chk("sp[5].n", dut_g.sp_5_n, dut_i.u_core.sp_entry[5].n);
    chk("sp[5].pbmt", dut_g.sp_5_pbmt, dut_i.u_core.sp_entry[5].pbmt);
    chk("sp[5].ppn", dut_g.sp_5_ppn, dut_i.u_core.sp_entry[5].ppn);
    chk("sp[5].level", dut_g.sp_5_level, dut_i.u_core.sp_entry[5].level);
    chk("sp[5].prefetch", dut_g.sp_5_prefetch, dut_i.u_core.sp_entry[5].prefetch);
    chk("sp[5].v", dut_g.sp_5_v, dut_i.u_core.sp_entry[5].v);
    chk("sp[5].perm.d", dut_g.sp_5_perm_d, dut_i.u_core.sp_entry[5].perm.d);
    chk("sp[5].perm.a", dut_g.sp_5_perm_a, dut_i.u_core.sp_entry[5].perm.a);
    chk("sp[5].perm.g", dut_g.sp_5_perm_g, dut_i.u_core.sp_entry[5].perm.g);
    chk("sp[5].perm.u", dut_g.sp_5_perm_u, dut_i.u_core.sp_entry[5].perm.u);
    chk("sp[5].perm.x", dut_g.sp_5_perm_x, dut_i.u_core.sp_entry[5].perm.x);
    chk("sp[5].perm.w", dut_g.sp_5_perm_w, dut_i.u_core.sp_entry[5].perm.w);
    chk("sp[5].perm.r", dut_g.sp_5_perm_r, dut_i.u_core.sp_entry[5].perm.r);
    chk("sph[5]", dut_g.sph_5, dut_i.u_core.sph[5]);
    chk("sp[6].tag", dut_g.sp_6_tag, dut_i.u_core.sp_entry[6].tag);
    chk("sp[6].asid", dut_g.sp_6_asid, dut_i.u_core.sp_entry[6].asid);
    chk("sp[6].vmid", dut_g.sp_6_vmid, dut_i.u_core.sp_entry[6].vmid);
    chk("sp[6].n", dut_g.sp_6_n, dut_i.u_core.sp_entry[6].n);
    chk("sp[6].pbmt", dut_g.sp_6_pbmt, dut_i.u_core.sp_entry[6].pbmt);
    chk("sp[6].ppn", dut_g.sp_6_ppn, dut_i.u_core.sp_entry[6].ppn);
    chk("sp[6].level", dut_g.sp_6_level, dut_i.u_core.sp_entry[6].level);
    chk("sp[6].prefetch", dut_g.sp_6_prefetch, dut_i.u_core.sp_entry[6].prefetch);
    chk("sp[6].v", dut_g.sp_6_v, dut_i.u_core.sp_entry[6].v);
    chk("sp[6].perm.d", dut_g.sp_6_perm_d, dut_i.u_core.sp_entry[6].perm.d);
    chk("sp[6].perm.a", dut_g.sp_6_perm_a, dut_i.u_core.sp_entry[6].perm.a);
    chk("sp[6].perm.g", dut_g.sp_6_perm_g, dut_i.u_core.sp_entry[6].perm.g);
    chk("sp[6].perm.u", dut_g.sp_6_perm_u, dut_i.u_core.sp_entry[6].perm.u);
    chk("sp[6].perm.x", dut_g.sp_6_perm_x, dut_i.u_core.sp_entry[6].perm.x);
    chk("sp[6].perm.w", dut_g.sp_6_perm_w, dut_i.u_core.sp_entry[6].perm.w);
    chk("sp[6].perm.r", dut_g.sp_6_perm_r, dut_i.u_core.sp_entry[6].perm.r);
    chk("sph[6]", dut_g.sph_6, dut_i.u_core.sph[6]);
    chk("sp[7].tag", dut_g.sp_7_tag, dut_i.u_core.sp_entry[7].tag);
    chk("sp[7].asid", dut_g.sp_7_asid, dut_i.u_core.sp_entry[7].asid);
    chk("sp[7].vmid", dut_g.sp_7_vmid, dut_i.u_core.sp_entry[7].vmid);
    chk("sp[7].n", dut_g.sp_7_n, dut_i.u_core.sp_entry[7].n);
    chk("sp[7].pbmt", dut_g.sp_7_pbmt, dut_i.u_core.sp_entry[7].pbmt);
    chk("sp[7].ppn", dut_g.sp_7_ppn, dut_i.u_core.sp_entry[7].ppn);
    chk("sp[7].level", dut_g.sp_7_level, dut_i.u_core.sp_entry[7].level);
    chk("sp[7].prefetch", dut_g.sp_7_prefetch, dut_i.u_core.sp_entry[7].prefetch);
    chk("sp[7].v", dut_g.sp_7_v, dut_i.u_core.sp_entry[7].v);
    chk("sp[7].perm.d", dut_g.sp_7_perm_d, dut_i.u_core.sp_entry[7].perm.d);
    chk("sp[7].perm.a", dut_g.sp_7_perm_a, dut_i.u_core.sp_entry[7].perm.a);
    chk("sp[7].perm.g", dut_g.sp_7_perm_g, dut_i.u_core.sp_entry[7].perm.g);
    chk("sp[7].perm.u", dut_g.sp_7_perm_u, dut_i.u_core.sp_entry[7].perm.u);
    chk("sp[7].perm.x", dut_g.sp_7_perm_x, dut_i.u_core.sp_entry[7].perm.x);
    chk("sp[7].perm.w", dut_g.sp_7_perm_w, dut_i.u_core.sp_entry[7].perm.w);
    chk("sp[7].perm.r", dut_g.sp_7_perm_r, dut_i.u_core.sp_entry[7].perm.r);
    chk("sph[7]", dut_g.sph_7, dut_i.u_core.sph[7]);
    chk("sp[8].tag", dut_g.sp_8_tag, dut_i.u_core.sp_entry[8].tag);
    chk("sp[8].asid", dut_g.sp_8_asid, dut_i.u_core.sp_entry[8].asid);
    chk("sp[8].vmid", dut_g.sp_8_vmid, dut_i.u_core.sp_entry[8].vmid);
    chk("sp[8].n", dut_g.sp_8_n, dut_i.u_core.sp_entry[8].n);
    chk("sp[8].pbmt", dut_g.sp_8_pbmt, dut_i.u_core.sp_entry[8].pbmt);
    chk("sp[8].ppn", dut_g.sp_8_ppn, dut_i.u_core.sp_entry[8].ppn);
    chk("sp[8].level", dut_g.sp_8_level, dut_i.u_core.sp_entry[8].level);
    chk("sp[8].prefetch", dut_g.sp_8_prefetch, dut_i.u_core.sp_entry[8].prefetch);
    chk("sp[8].v", dut_g.sp_8_v, dut_i.u_core.sp_entry[8].v);
    chk("sp[8].perm.d", dut_g.sp_8_perm_d, dut_i.u_core.sp_entry[8].perm.d);
    chk("sp[8].perm.a", dut_g.sp_8_perm_a, dut_i.u_core.sp_entry[8].perm.a);
    chk("sp[8].perm.g", dut_g.sp_8_perm_g, dut_i.u_core.sp_entry[8].perm.g);
    chk("sp[8].perm.u", dut_g.sp_8_perm_u, dut_i.u_core.sp_entry[8].perm.u);
    chk("sp[8].perm.x", dut_g.sp_8_perm_x, dut_i.u_core.sp_entry[8].perm.x);
    chk("sp[8].perm.w", dut_g.sp_8_perm_w, dut_i.u_core.sp_entry[8].perm.w);
    chk("sp[8].perm.r", dut_g.sp_8_perm_r, dut_i.u_core.sp_entry[8].perm.r);
    chk("sph[8]", dut_g.sph_8, dut_i.u_core.sph[8]);
    chk("sp[9].tag", dut_g.sp_9_tag, dut_i.u_core.sp_entry[9].tag);
    chk("sp[9].asid", dut_g.sp_9_asid, dut_i.u_core.sp_entry[9].asid);
    chk("sp[9].vmid", dut_g.sp_9_vmid, dut_i.u_core.sp_entry[9].vmid);
    chk("sp[9].n", dut_g.sp_9_n, dut_i.u_core.sp_entry[9].n);
    chk("sp[9].pbmt", dut_g.sp_9_pbmt, dut_i.u_core.sp_entry[9].pbmt);
    chk("sp[9].ppn", dut_g.sp_9_ppn, dut_i.u_core.sp_entry[9].ppn);
    chk("sp[9].level", dut_g.sp_9_level, dut_i.u_core.sp_entry[9].level);
    chk("sp[9].prefetch", dut_g.sp_9_prefetch, dut_i.u_core.sp_entry[9].prefetch);
    chk("sp[9].v", dut_g.sp_9_v, dut_i.u_core.sp_entry[9].v);
    chk("sp[9].perm.d", dut_g.sp_9_perm_d, dut_i.u_core.sp_entry[9].perm.d);
    chk("sp[9].perm.a", dut_g.sp_9_perm_a, dut_i.u_core.sp_entry[9].perm.a);
    chk("sp[9].perm.g", dut_g.sp_9_perm_g, dut_i.u_core.sp_entry[9].perm.g);
    chk("sp[9].perm.u", dut_g.sp_9_perm_u, dut_i.u_core.sp_entry[9].perm.u);
    chk("sp[9].perm.x", dut_g.sp_9_perm_x, dut_i.u_core.sp_entry[9].perm.x);
    chk("sp[9].perm.w", dut_g.sp_9_perm_w, dut_i.u_core.sp_entry[9].perm.w);
    chk("sp[9].perm.r", dut_g.sp_9_perm_r, dut_i.u_core.sp_entry[9].perm.r);
    chk("sph[9]", dut_g.sph_9, dut_i.u_core.sph[9]);
    chk("sp[10].tag", dut_g.sp_10_tag, dut_i.u_core.sp_entry[10].tag);
    chk("sp[10].asid", dut_g.sp_10_asid, dut_i.u_core.sp_entry[10].asid);
    chk("sp[10].vmid", dut_g.sp_10_vmid, dut_i.u_core.sp_entry[10].vmid);
    chk("sp[10].n", dut_g.sp_10_n, dut_i.u_core.sp_entry[10].n);
    chk("sp[10].pbmt", dut_g.sp_10_pbmt, dut_i.u_core.sp_entry[10].pbmt);
    chk("sp[10].ppn", dut_g.sp_10_ppn, dut_i.u_core.sp_entry[10].ppn);
    chk("sp[10].level", dut_g.sp_10_level, dut_i.u_core.sp_entry[10].level);
    chk("sp[10].prefetch", dut_g.sp_10_prefetch, dut_i.u_core.sp_entry[10].prefetch);
    chk("sp[10].v", dut_g.sp_10_v, dut_i.u_core.sp_entry[10].v);
    chk("sp[10].perm.d", dut_g.sp_10_perm_d, dut_i.u_core.sp_entry[10].perm.d);
    chk("sp[10].perm.a", dut_g.sp_10_perm_a, dut_i.u_core.sp_entry[10].perm.a);
    chk("sp[10].perm.g", dut_g.sp_10_perm_g, dut_i.u_core.sp_entry[10].perm.g);
    chk("sp[10].perm.u", dut_g.sp_10_perm_u, dut_i.u_core.sp_entry[10].perm.u);
    chk("sp[10].perm.x", dut_g.sp_10_perm_x, dut_i.u_core.sp_entry[10].perm.x);
    chk("sp[10].perm.w", dut_g.sp_10_perm_w, dut_i.u_core.sp_entry[10].perm.w);
    chk("sp[10].perm.r", dut_g.sp_10_perm_r, dut_i.u_core.sp_entry[10].perm.r);
    chk("sph[10]", dut_g.sph_10, dut_i.u_core.sph[10]);
    chk("sp[11].tag", dut_g.sp_11_tag, dut_i.u_core.sp_entry[11].tag);
    chk("sp[11].asid", dut_g.sp_11_asid, dut_i.u_core.sp_entry[11].asid);
    chk("sp[11].vmid", dut_g.sp_11_vmid, dut_i.u_core.sp_entry[11].vmid);
    chk("sp[11].n", dut_g.sp_11_n, dut_i.u_core.sp_entry[11].n);
    chk("sp[11].pbmt", dut_g.sp_11_pbmt, dut_i.u_core.sp_entry[11].pbmt);
    chk("sp[11].ppn", dut_g.sp_11_ppn, dut_i.u_core.sp_entry[11].ppn);
    chk("sp[11].level", dut_g.sp_11_level, dut_i.u_core.sp_entry[11].level);
    chk("sp[11].prefetch", dut_g.sp_11_prefetch, dut_i.u_core.sp_entry[11].prefetch);
    chk("sp[11].v", dut_g.sp_11_v, dut_i.u_core.sp_entry[11].v);
    chk("sp[11].perm.d", dut_g.sp_11_perm_d, dut_i.u_core.sp_entry[11].perm.d);
    chk("sp[11].perm.a", dut_g.sp_11_perm_a, dut_i.u_core.sp_entry[11].perm.a);
    chk("sp[11].perm.g", dut_g.sp_11_perm_g, dut_i.u_core.sp_entry[11].perm.g);
    chk("sp[11].perm.u", dut_g.sp_11_perm_u, dut_i.u_core.sp_entry[11].perm.u);
    chk("sp[11].perm.x", dut_g.sp_11_perm_x, dut_i.u_core.sp_entry[11].perm.x);
    chk("sp[11].perm.w", dut_g.sp_11_perm_w, dut_i.u_core.sp_entry[11].perm.w);
    chk("sp[11].perm.r", dut_g.sp_11_perm_r, dut_i.u_core.sp_entry[11].perm.r);
    chk("sph[11]", dut_g.sph_11, dut_i.u_core.sph[11]);
    chk("sp[12].tag", dut_g.sp_12_tag, dut_i.u_core.sp_entry[12].tag);
    chk("sp[12].asid", dut_g.sp_12_asid, dut_i.u_core.sp_entry[12].asid);
    chk("sp[12].vmid", dut_g.sp_12_vmid, dut_i.u_core.sp_entry[12].vmid);
    chk("sp[12].n", dut_g.sp_12_n, dut_i.u_core.sp_entry[12].n);
    chk("sp[12].pbmt", dut_g.sp_12_pbmt, dut_i.u_core.sp_entry[12].pbmt);
    chk("sp[12].ppn", dut_g.sp_12_ppn, dut_i.u_core.sp_entry[12].ppn);
    chk("sp[12].level", dut_g.sp_12_level, dut_i.u_core.sp_entry[12].level);
    chk("sp[12].prefetch", dut_g.sp_12_prefetch, dut_i.u_core.sp_entry[12].prefetch);
    chk("sp[12].v", dut_g.sp_12_v, dut_i.u_core.sp_entry[12].v);
    chk("sp[12].perm.d", dut_g.sp_12_perm_d, dut_i.u_core.sp_entry[12].perm.d);
    chk("sp[12].perm.a", dut_g.sp_12_perm_a, dut_i.u_core.sp_entry[12].perm.a);
    chk("sp[12].perm.g", dut_g.sp_12_perm_g, dut_i.u_core.sp_entry[12].perm.g);
    chk("sp[12].perm.u", dut_g.sp_12_perm_u, dut_i.u_core.sp_entry[12].perm.u);
    chk("sp[12].perm.x", dut_g.sp_12_perm_x, dut_i.u_core.sp_entry[12].perm.x);
    chk("sp[12].perm.w", dut_g.sp_12_perm_w, dut_i.u_core.sp_entry[12].perm.w);
    chk("sp[12].perm.r", dut_g.sp_12_perm_r, dut_i.u_core.sp_entry[12].perm.r);
    chk("sph[12]", dut_g.sph_12, dut_i.u_core.sph[12]);
    chk("sp[13].tag", dut_g.sp_13_tag, dut_i.u_core.sp_entry[13].tag);
    chk("sp[13].asid", dut_g.sp_13_asid, dut_i.u_core.sp_entry[13].asid);
    chk("sp[13].vmid", dut_g.sp_13_vmid, dut_i.u_core.sp_entry[13].vmid);
    chk("sp[13].n", dut_g.sp_13_n, dut_i.u_core.sp_entry[13].n);
    chk("sp[13].pbmt", dut_g.sp_13_pbmt, dut_i.u_core.sp_entry[13].pbmt);
    chk("sp[13].ppn", dut_g.sp_13_ppn, dut_i.u_core.sp_entry[13].ppn);
    chk("sp[13].level", dut_g.sp_13_level, dut_i.u_core.sp_entry[13].level);
    chk("sp[13].prefetch", dut_g.sp_13_prefetch, dut_i.u_core.sp_entry[13].prefetch);
    chk("sp[13].v", dut_g.sp_13_v, dut_i.u_core.sp_entry[13].v);
    chk("sp[13].perm.d", dut_g.sp_13_perm_d, dut_i.u_core.sp_entry[13].perm.d);
    chk("sp[13].perm.a", dut_g.sp_13_perm_a, dut_i.u_core.sp_entry[13].perm.a);
    chk("sp[13].perm.g", dut_g.sp_13_perm_g, dut_i.u_core.sp_entry[13].perm.g);
    chk("sp[13].perm.u", dut_g.sp_13_perm_u, dut_i.u_core.sp_entry[13].perm.u);
    chk("sp[13].perm.x", dut_g.sp_13_perm_x, dut_i.u_core.sp_entry[13].perm.x);
    chk("sp[13].perm.w", dut_g.sp_13_perm_w, dut_i.u_core.sp_entry[13].perm.w);
    chk("sp[13].perm.r", dut_g.sp_13_perm_r, dut_i.u_core.sp_entry[13].perm.r);
    chk("sph[13]", dut_g.sph_13, dut_i.u_core.sph[13]);
    chk("sp[14].tag", dut_g.sp_14_tag, dut_i.u_core.sp_entry[14].tag);
    chk("sp[14].asid", dut_g.sp_14_asid, dut_i.u_core.sp_entry[14].asid);
    chk("sp[14].vmid", dut_g.sp_14_vmid, dut_i.u_core.sp_entry[14].vmid);
    chk("sp[14].n", dut_g.sp_14_n, dut_i.u_core.sp_entry[14].n);
    chk("sp[14].pbmt", dut_g.sp_14_pbmt, dut_i.u_core.sp_entry[14].pbmt);
    chk("sp[14].ppn", dut_g.sp_14_ppn, dut_i.u_core.sp_entry[14].ppn);
    chk("sp[14].level", dut_g.sp_14_level, dut_i.u_core.sp_entry[14].level);
    chk("sp[14].prefetch", dut_g.sp_14_prefetch, dut_i.u_core.sp_entry[14].prefetch);
    chk("sp[14].v", dut_g.sp_14_v, dut_i.u_core.sp_entry[14].v);
    chk("sp[14].perm.d", dut_g.sp_14_perm_d, dut_i.u_core.sp_entry[14].perm.d);
    chk("sp[14].perm.a", dut_g.sp_14_perm_a, dut_i.u_core.sp_entry[14].perm.a);
    chk("sp[14].perm.g", dut_g.sp_14_perm_g, dut_i.u_core.sp_entry[14].perm.g);
    chk("sp[14].perm.u", dut_g.sp_14_perm_u, dut_i.u_core.sp_entry[14].perm.u);
    chk("sp[14].perm.x", dut_g.sp_14_perm_x, dut_i.u_core.sp_entry[14].perm.x);
    chk("sp[14].perm.w", dut_g.sp_14_perm_w, dut_i.u_core.sp_entry[14].perm.w);
    chk("sp[14].perm.r", dut_g.sp_14_perm_r, dut_i.u_core.sp_entry[14].perm.r);
    chk("sph[14]", dut_g.sph_14, dut_i.u_core.sph[14]);
    chk("sp[15].tag", dut_g.sp_15_tag, dut_i.u_core.sp_entry[15].tag);
    chk("sp[15].asid", dut_g.sp_15_asid, dut_i.u_core.sp_entry[15].asid);
    chk("sp[15].vmid", dut_g.sp_15_vmid, dut_i.u_core.sp_entry[15].vmid);
    chk("sp[15].n", dut_g.sp_15_n, dut_i.u_core.sp_entry[15].n);
    chk("sp[15].pbmt", dut_g.sp_15_pbmt, dut_i.u_core.sp_entry[15].pbmt);
    chk("sp[15].ppn", dut_g.sp_15_ppn, dut_i.u_core.sp_entry[15].ppn);
    chk("sp[15].level", dut_g.sp_15_level, dut_i.u_core.sp_entry[15].level);
    chk("sp[15].prefetch", dut_g.sp_15_prefetch, dut_i.u_core.sp_entry[15].prefetch);
    chk("sp[15].v", dut_g.sp_15_v, dut_i.u_core.sp_entry[15].v);
    chk("sp[15].perm.d", dut_g.sp_15_perm_d, dut_i.u_core.sp_entry[15].perm.d);
    chk("sp[15].perm.a", dut_g.sp_15_perm_a, dut_i.u_core.sp_entry[15].perm.a);
    chk("sp[15].perm.g", dut_g.sp_15_perm_g, dut_i.u_core.sp_entry[15].perm.g);
    chk("sp[15].perm.u", dut_g.sp_15_perm_u, dut_i.u_core.sp_entry[15].perm.u);
    chk("sp[15].perm.x", dut_g.sp_15_perm_x, dut_i.u_core.sp_entry[15].perm.x);
    chk("sp[15].perm.w", dut_g.sp_15_perm_w, dut_i.u_core.sp_entry[15].perm.w);
    chk("sp[15].perm.r", dut_g.sp_15_perm_r, dut_i.u_core.sp_entry[15].perm.r);
    chk("sph[15]", dut_g.sph_15, dut_i.u_core.sph[15]);
    chk("l1h[0][0]", dut_g.l1h_0_0, dut_i.u_core.l1h[0][0]);
    chk("l1asids[0][0]", dut_g.l1asids_0_0, dut_i.u_core.l1asids[0][0]);
    chk("l1vmids[0][0]", dut_g.l1vmids_0_0, dut_i.u_core.l1vmids[0][0]);
    chk("l1h[0][1]", dut_g.l1h_0_1, dut_i.u_core.l1h[0][1]);
    chk("l1asids[0][1]", dut_g.l1asids_0_1, dut_i.u_core.l1asids[0][1]);
    chk("l1vmids[0][1]", dut_g.l1vmids_0_1, dut_i.u_core.l1vmids[0][1]);
    chk("l1h[1][0]", dut_g.l1h_1_0, dut_i.u_core.l1h[1][0]);
    chk("l1asids[1][0]", dut_g.l1asids_1_0, dut_i.u_core.l1asids[1][0]);
    chk("l1vmids[1][0]", dut_g.l1vmids_1_0, dut_i.u_core.l1vmids[1][0]);
    chk("l1h[1][1]", dut_g.l1h_1_1, dut_i.u_core.l1h[1][1]);
    chk("l1asids[1][1]", dut_g.l1asids_1_1, dut_i.u_core.l1asids[1][1]);
    chk("l1vmids[1][1]", dut_g.l1vmids_1_1, dut_i.u_core.l1vmids[1][1]);
    chk("l1h[2][0]", dut_g.l1h_2_0, dut_i.u_core.l1h[2][0]);
    chk("l1asids[2][0]", dut_g.l1asids_2_0, dut_i.u_core.l1asids[2][0]);
    chk("l1vmids[2][0]", dut_g.l1vmids_2_0, dut_i.u_core.l1vmids[2][0]);
    chk("l1h[2][1]", dut_g.l1h_2_1, dut_i.u_core.l1h[2][1]);
    chk("l1asids[2][1]", dut_g.l1asids_2_1, dut_i.u_core.l1asids[2][1]);
    chk("l1vmids[2][1]", dut_g.l1vmids_2_1, dut_i.u_core.l1vmids[2][1]);
    chk("l1h[3][0]", dut_g.l1h_3_0, dut_i.u_core.l1h[3][0]);
    chk("l1asids[3][0]", dut_g.l1asids_3_0, dut_i.u_core.l1asids[3][0]);
    chk("l1vmids[3][0]", dut_g.l1vmids_3_0, dut_i.u_core.l1vmids[3][0]);
    chk("l1h[3][1]", dut_g.l1h_3_1, dut_i.u_core.l1h[3][1]);
    chk("l1asids[3][1]", dut_g.l1asids_3_1, dut_i.u_core.l1asids[3][1]);
    chk("l1vmids[3][1]", dut_g.l1vmids_3_1, dut_i.u_core.l1vmids[3][1]);
    chk("l0h[0][0]", dut_g.l0h_0_0, dut_i.u_core.l0h[0][0]);
    chk("l0asids[0][0]", dut_g.l0asids_0_0, dut_i.u_core.l0asids[0][0]);
    chk("l0vmids[0][0]", dut_g.l0vmids_0_0, dut_i.u_core.l0vmids[0][0]);
    chk("l0vpns[0][0]", dut_g.l0vpns_0_0, dut_i.u_core.l0vpns[0][0]);
    chk("l0h[0][1]", dut_g.l0h_0_1, dut_i.u_core.l0h[0][1]);
    chk("l0asids[0][1]", dut_g.l0asids_0_1, dut_i.u_core.l0asids[0][1]);
    chk("l0vmids[0][1]", dut_g.l0vmids_0_1, dut_i.u_core.l0vmids[0][1]);
    chk("l0vpns[0][1]", dut_g.l0vpns_0_1, dut_i.u_core.l0vpns[0][1]);
    chk("l0h[0][2]", dut_g.l0h_0_2, dut_i.u_core.l0h[0][2]);
    chk("l0asids[0][2]", dut_g.l0asids_0_2, dut_i.u_core.l0asids[0][2]);
    chk("l0vmids[0][2]", dut_g.l0vmids_0_2, dut_i.u_core.l0vmids[0][2]);
    chk("l0vpns[0][2]", dut_g.l0vpns_0_2, dut_i.u_core.l0vpns[0][2]);
    chk("l0h[0][3]", dut_g.l0h_0_3, dut_i.u_core.l0h[0][3]);
    chk("l0asids[0][3]", dut_g.l0asids_0_3, dut_i.u_core.l0asids[0][3]);
    chk("l0vmids[0][3]", dut_g.l0vmids_0_3, dut_i.u_core.l0vmids[0][3]);
    chk("l0vpns[0][3]", dut_g.l0vpns_0_3, dut_i.u_core.l0vpns[0][3]);
    chk("l0h[1][0]", dut_g.l0h_1_0, dut_i.u_core.l0h[1][0]);
    chk("l0asids[1][0]", dut_g.l0asids_1_0, dut_i.u_core.l0asids[1][0]);
    chk("l0vmids[1][0]", dut_g.l0vmids_1_0, dut_i.u_core.l0vmids[1][0]);
    chk("l0vpns[1][0]", dut_g.l0vpns_1_0, dut_i.u_core.l0vpns[1][0]);
    chk("l0h[1][1]", dut_g.l0h_1_1, dut_i.u_core.l0h[1][1]);
    chk("l0asids[1][1]", dut_g.l0asids_1_1, dut_i.u_core.l0asids[1][1]);
    chk("l0vmids[1][1]", dut_g.l0vmids_1_1, dut_i.u_core.l0vmids[1][1]);
    chk("l0vpns[1][1]", dut_g.l0vpns_1_1, dut_i.u_core.l0vpns[1][1]);
    chk("l0h[1][2]", dut_g.l0h_1_2, dut_i.u_core.l0h[1][2]);
    chk("l0asids[1][2]", dut_g.l0asids_1_2, dut_i.u_core.l0asids[1][2]);
    chk("l0vmids[1][2]", dut_g.l0vmids_1_2, dut_i.u_core.l0vmids[1][2]);
    chk("l0vpns[1][2]", dut_g.l0vpns_1_2, dut_i.u_core.l0vpns[1][2]);
    chk("l0h[1][3]", dut_g.l0h_1_3, dut_i.u_core.l0h[1][3]);
    chk("l0asids[1][3]", dut_g.l0asids_1_3, dut_i.u_core.l0asids[1][3]);
    chk("l0vmids[1][3]", dut_g.l0vmids_1_3, dut_i.u_core.l0vmids[1][3]);
    chk("l0vpns[1][3]", dut_g.l0vpns_1_3, dut_i.u_core.l0vpns[1][3]);
    chk("l0h[2][0]", dut_g.l0h_2_0, dut_i.u_core.l0h[2][0]);
    chk("l0asids[2][0]", dut_g.l0asids_2_0, dut_i.u_core.l0asids[2][0]);
    chk("l0vmids[2][0]", dut_g.l0vmids_2_0, dut_i.u_core.l0vmids[2][0]);
    chk("l0vpns[2][0]", dut_g.l0vpns_2_0, dut_i.u_core.l0vpns[2][0]);
    chk("l0h[2][1]", dut_g.l0h_2_1, dut_i.u_core.l0h[2][1]);
    chk("l0asids[2][1]", dut_g.l0asids_2_1, dut_i.u_core.l0asids[2][1]);
    chk("l0vmids[2][1]", dut_g.l0vmids_2_1, dut_i.u_core.l0vmids[2][1]);
    chk("l0vpns[2][1]", dut_g.l0vpns_2_1, dut_i.u_core.l0vpns[2][1]);
    chk("l0h[2][2]", dut_g.l0h_2_2, dut_i.u_core.l0h[2][2]);
    chk("l0asids[2][2]", dut_g.l0asids_2_2, dut_i.u_core.l0asids[2][2]);
    chk("l0vmids[2][2]", dut_g.l0vmids_2_2, dut_i.u_core.l0vmids[2][2]);
    chk("l0vpns[2][2]", dut_g.l0vpns_2_2, dut_i.u_core.l0vpns[2][2]);
    chk("l0h[2][3]", dut_g.l0h_2_3, dut_i.u_core.l0h[2][3]);
    chk("l0asids[2][3]", dut_g.l0asids_2_3, dut_i.u_core.l0asids[2][3]);
    chk("l0vmids[2][3]", dut_g.l0vmids_2_3, dut_i.u_core.l0vmids[2][3]);
    chk("l0vpns[2][3]", dut_g.l0vpns_2_3, dut_i.u_core.l0vpns[2][3]);
    chk("l0h[3][0]", dut_g.l0h_3_0, dut_i.u_core.l0h[3][0]);
    chk("l0asids[3][0]", dut_g.l0asids_3_0, dut_i.u_core.l0asids[3][0]);
    chk("l0vmids[3][0]", dut_g.l0vmids_3_0, dut_i.u_core.l0vmids[3][0]);
    chk("l0vpns[3][0]", dut_g.l0vpns_3_0, dut_i.u_core.l0vpns[3][0]);
    chk("l0h[3][1]", dut_g.l0h_3_1, dut_i.u_core.l0h[3][1]);
    chk("l0asids[3][1]", dut_g.l0asids_3_1, dut_i.u_core.l0asids[3][1]);
    chk("l0vmids[3][1]", dut_g.l0vmids_3_1, dut_i.u_core.l0vmids[3][1]);
    chk("l0vpns[3][1]", dut_g.l0vpns_3_1, dut_i.u_core.l0vpns[3][1]);
    chk("l0h[3][2]", dut_g.l0h_3_2, dut_i.u_core.l0h[3][2]);
    chk("l0asids[3][2]", dut_g.l0asids_3_2, dut_i.u_core.l0asids[3][2]);
    chk("l0vmids[3][2]", dut_g.l0vmids_3_2, dut_i.u_core.l0vmids[3][2]);
    chk("l0vpns[3][2]", dut_g.l0vpns_3_2, dut_i.u_core.l0vpns[3][2]);
    chk("l0h[3][3]", dut_g.l0h_3_3, dut_i.u_core.l0h[3][3]);
    chk("l0asids[3][3]", dut_g.l0asids_3_3, dut_i.u_core.l0asids[3][3]);
    chk("l0vmids[3][3]", dut_g.l0vmids_3_3, dut_i.u_core.l0vmids[3][3]);
    chk("l0vpns[3][3]", dut_g.l0vpns_3_3, dut_i.u_core.l0vpns[3][3]);
    chk("l0h[4][0]", dut_g.l0h_4_0, dut_i.u_core.l0h[4][0]);
    chk("l0asids[4][0]", dut_g.l0asids_4_0, dut_i.u_core.l0asids[4][0]);
    chk("l0vmids[4][0]", dut_g.l0vmids_4_0, dut_i.u_core.l0vmids[4][0]);
    chk("l0vpns[4][0]", dut_g.l0vpns_4_0, dut_i.u_core.l0vpns[4][0]);
    chk("l0h[4][1]", dut_g.l0h_4_1, dut_i.u_core.l0h[4][1]);
    chk("l0asids[4][1]", dut_g.l0asids_4_1, dut_i.u_core.l0asids[4][1]);
    chk("l0vmids[4][1]", dut_g.l0vmids_4_1, dut_i.u_core.l0vmids[4][1]);
    chk("l0vpns[4][1]", dut_g.l0vpns_4_1, dut_i.u_core.l0vpns[4][1]);
    chk("l0h[4][2]", dut_g.l0h_4_2, dut_i.u_core.l0h[4][2]);
    chk("l0asids[4][2]", dut_g.l0asids_4_2, dut_i.u_core.l0asids[4][2]);
    chk("l0vmids[4][2]", dut_g.l0vmids_4_2, dut_i.u_core.l0vmids[4][2]);
    chk("l0vpns[4][2]", dut_g.l0vpns_4_2, dut_i.u_core.l0vpns[4][2]);
    chk("l0h[4][3]", dut_g.l0h_4_3, dut_i.u_core.l0h[4][3]);
    chk("l0asids[4][3]", dut_g.l0asids_4_3, dut_i.u_core.l0asids[4][3]);
    chk("l0vmids[4][3]", dut_g.l0vmids_4_3, dut_i.u_core.l0vmids[4][3]);
    chk("l0vpns[4][3]", dut_g.l0vpns_4_3, dut_i.u_core.l0vpns[4][3]);
    chk("l0h[5][0]", dut_g.l0h_5_0, dut_i.u_core.l0h[5][0]);
    chk("l0asids[5][0]", dut_g.l0asids_5_0, dut_i.u_core.l0asids[5][0]);
    chk("l0vmids[5][0]", dut_g.l0vmids_5_0, dut_i.u_core.l0vmids[5][0]);
    chk("l0vpns[5][0]", dut_g.l0vpns_5_0, dut_i.u_core.l0vpns[5][0]);
    chk("l0h[5][1]", dut_g.l0h_5_1, dut_i.u_core.l0h[5][1]);
    chk("l0asids[5][1]", dut_g.l0asids_5_1, dut_i.u_core.l0asids[5][1]);
    chk("l0vmids[5][1]", dut_g.l0vmids_5_1, dut_i.u_core.l0vmids[5][1]);
    chk("l0vpns[5][1]", dut_g.l0vpns_5_1, dut_i.u_core.l0vpns[5][1]);
    chk("l0h[5][2]", dut_g.l0h_5_2, dut_i.u_core.l0h[5][2]);
    chk("l0asids[5][2]", dut_g.l0asids_5_2, dut_i.u_core.l0asids[5][2]);
    chk("l0vmids[5][2]", dut_g.l0vmids_5_2, dut_i.u_core.l0vmids[5][2]);
    chk("l0vpns[5][2]", dut_g.l0vpns_5_2, dut_i.u_core.l0vpns[5][2]);
    chk("l0h[5][3]", dut_g.l0h_5_3, dut_i.u_core.l0h[5][3]);
    chk("l0asids[5][3]", dut_g.l0asids_5_3, dut_i.u_core.l0asids[5][3]);
    chk("l0vmids[5][3]", dut_g.l0vmids_5_3, dut_i.u_core.l0vmids[5][3]);
    chk("l0vpns[5][3]", dut_g.l0vpns_5_3, dut_i.u_core.l0vpns[5][3]);
    chk("l0h[6][0]", dut_g.l0h_6_0, dut_i.u_core.l0h[6][0]);
    chk("l0asids[6][0]", dut_g.l0asids_6_0, dut_i.u_core.l0asids[6][0]);
    chk("l0vmids[6][0]", dut_g.l0vmids_6_0, dut_i.u_core.l0vmids[6][0]);
    chk("l0vpns[6][0]", dut_g.l0vpns_6_0, dut_i.u_core.l0vpns[6][0]);
    chk("l0h[6][1]", dut_g.l0h_6_1, dut_i.u_core.l0h[6][1]);
    chk("l0asids[6][1]", dut_g.l0asids_6_1, dut_i.u_core.l0asids[6][1]);
    chk("l0vmids[6][1]", dut_g.l0vmids_6_1, dut_i.u_core.l0vmids[6][1]);
    chk("l0vpns[6][1]", dut_g.l0vpns_6_1, dut_i.u_core.l0vpns[6][1]);
    chk("l0h[6][2]", dut_g.l0h_6_2, dut_i.u_core.l0h[6][2]);
    chk("l0asids[6][2]", dut_g.l0asids_6_2, dut_i.u_core.l0asids[6][2]);
    chk("l0vmids[6][2]", dut_g.l0vmids_6_2, dut_i.u_core.l0vmids[6][2]);
    chk("l0vpns[6][2]", dut_g.l0vpns_6_2, dut_i.u_core.l0vpns[6][2]);
    chk("l0h[6][3]", dut_g.l0h_6_3, dut_i.u_core.l0h[6][3]);
    chk("l0asids[6][3]", dut_g.l0asids_6_3, dut_i.u_core.l0asids[6][3]);
    chk("l0vmids[6][3]", dut_g.l0vmids_6_3, dut_i.u_core.l0vmids[6][3]);
    chk("l0vpns[6][3]", dut_g.l0vpns_6_3, dut_i.u_core.l0vpns[6][3]);
    chk("l0h[7][0]", dut_g.l0h_7_0, dut_i.u_core.l0h[7][0]);
    chk("l0asids[7][0]", dut_g.l0asids_7_0, dut_i.u_core.l0asids[7][0]);
    chk("l0vmids[7][0]", dut_g.l0vmids_7_0, dut_i.u_core.l0vmids[7][0]);
    chk("l0vpns[7][0]", dut_g.l0vpns_7_0, dut_i.u_core.l0vpns[7][0]);
    chk("l0h[7][1]", dut_g.l0h_7_1, dut_i.u_core.l0h[7][1]);
    chk("l0asids[7][1]", dut_g.l0asids_7_1, dut_i.u_core.l0asids[7][1]);
    chk("l0vmids[7][1]", dut_g.l0vmids_7_1, dut_i.u_core.l0vmids[7][1]);
    chk("l0vpns[7][1]", dut_g.l0vpns_7_1, dut_i.u_core.l0vpns[7][1]);
    chk("l0h[7][2]", dut_g.l0h_7_2, dut_i.u_core.l0h[7][2]);
    chk("l0asids[7][2]", dut_g.l0asids_7_2, dut_i.u_core.l0asids[7][2]);
    chk("l0vmids[7][2]", dut_g.l0vmids_7_2, dut_i.u_core.l0vmids[7][2]);
    chk("l0vpns[7][2]", dut_g.l0vpns_7_2, dut_i.u_core.l0vpns[7][2]);
    chk("l0h[7][3]", dut_g.l0h_7_3, dut_i.u_core.l0h[7][3]);
    chk("l0asids[7][3]", dut_g.l0asids_7_3, dut_i.u_core.l0asids[7][3]);
    chk("l0vmids[7][3]", dut_g.l0vmids_7_3, dut_i.u_core.l0vmids[7][3]);
    chk("l0vpns[7][3]", dut_g.l0vpns_7_3, dut_i.u_core.l0vpns[7][3]);
    chk("l0h[8][0]", dut_g.l0h_8_0, dut_i.u_core.l0h[8][0]);
    chk("l0asids[8][0]", dut_g.l0asids_8_0, dut_i.u_core.l0asids[8][0]);
    chk("l0vmids[8][0]", dut_g.l0vmids_8_0, dut_i.u_core.l0vmids[8][0]);
    chk("l0vpns[8][0]", dut_g.l0vpns_8_0, dut_i.u_core.l0vpns[8][0]);
    chk("l0h[8][1]", dut_g.l0h_8_1, dut_i.u_core.l0h[8][1]);
    chk("l0asids[8][1]", dut_g.l0asids_8_1, dut_i.u_core.l0asids[8][1]);
    chk("l0vmids[8][1]", dut_g.l0vmids_8_1, dut_i.u_core.l0vmids[8][1]);
    chk("l0vpns[8][1]", dut_g.l0vpns_8_1, dut_i.u_core.l0vpns[8][1]);
    chk("l0h[8][2]", dut_g.l0h_8_2, dut_i.u_core.l0h[8][2]);
    chk("l0asids[8][2]", dut_g.l0asids_8_2, dut_i.u_core.l0asids[8][2]);
    chk("l0vmids[8][2]", dut_g.l0vmids_8_2, dut_i.u_core.l0vmids[8][2]);
    chk("l0vpns[8][2]", dut_g.l0vpns_8_2, dut_i.u_core.l0vpns[8][2]);
    chk("l0h[8][3]", dut_g.l0h_8_3, dut_i.u_core.l0h[8][3]);
    chk("l0asids[8][3]", dut_g.l0asids_8_3, dut_i.u_core.l0asids[8][3]);
    chk("l0vmids[8][3]", dut_g.l0vmids_8_3, dut_i.u_core.l0vmids[8][3]);
    chk("l0vpns[8][3]", dut_g.l0vpns_8_3, dut_i.u_core.l0vpns[8][3]);
    chk("l0h[9][0]", dut_g.l0h_9_0, dut_i.u_core.l0h[9][0]);
    chk("l0asids[9][0]", dut_g.l0asids_9_0, dut_i.u_core.l0asids[9][0]);
    chk("l0vmids[9][0]", dut_g.l0vmids_9_0, dut_i.u_core.l0vmids[9][0]);
    chk("l0vpns[9][0]", dut_g.l0vpns_9_0, dut_i.u_core.l0vpns[9][0]);
    chk("l0h[9][1]", dut_g.l0h_9_1, dut_i.u_core.l0h[9][1]);
    chk("l0asids[9][1]", dut_g.l0asids_9_1, dut_i.u_core.l0asids[9][1]);
    chk("l0vmids[9][1]", dut_g.l0vmids_9_1, dut_i.u_core.l0vmids[9][1]);
    chk("l0vpns[9][1]", dut_g.l0vpns_9_1, dut_i.u_core.l0vpns[9][1]);
    chk("l0h[9][2]", dut_g.l0h_9_2, dut_i.u_core.l0h[9][2]);
    chk("l0asids[9][2]", dut_g.l0asids_9_2, dut_i.u_core.l0asids[9][2]);
    chk("l0vmids[9][2]", dut_g.l0vmids_9_2, dut_i.u_core.l0vmids[9][2]);
    chk("l0vpns[9][2]", dut_g.l0vpns_9_2, dut_i.u_core.l0vpns[9][2]);
    chk("l0h[9][3]", dut_g.l0h_9_3, dut_i.u_core.l0h[9][3]);
    chk("l0asids[9][3]", dut_g.l0asids_9_3, dut_i.u_core.l0asids[9][3]);
    chk("l0vmids[9][3]", dut_g.l0vmids_9_3, dut_i.u_core.l0vmids[9][3]);
    chk("l0vpns[9][3]", dut_g.l0vpns_9_3, dut_i.u_core.l0vpns[9][3]);
    chk("l0h[10][0]", dut_g.l0h_10_0, dut_i.u_core.l0h[10][0]);
    chk("l0asids[10][0]", dut_g.l0asids_10_0, dut_i.u_core.l0asids[10][0]);
    chk("l0vmids[10][0]", dut_g.l0vmids_10_0, dut_i.u_core.l0vmids[10][0]);
    chk("l0vpns[10][0]", dut_g.l0vpns_10_0, dut_i.u_core.l0vpns[10][0]);
    chk("l0h[10][1]", dut_g.l0h_10_1, dut_i.u_core.l0h[10][1]);
    chk("l0asids[10][1]", dut_g.l0asids_10_1, dut_i.u_core.l0asids[10][1]);
    chk("l0vmids[10][1]", dut_g.l0vmids_10_1, dut_i.u_core.l0vmids[10][1]);
    chk("l0vpns[10][1]", dut_g.l0vpns_10_1, dut_i.u_core.l0vpns[10][1]);
    chk("l0h[10][2]", dut_g.l0h_10_2, dut_i.u_core.l0h[10][2]);
    chk("l0asids[10][2]", dut_g.l0asids_10_2, dut_i.u_core.l0asids[10][2]);
    chk("l0vmids[10][2]", dut_g.l0vmids_10_2, dut_i.u_core.l0vmids[10][2]);
    chk("l0vpns[10][2]", dut_g.l0vpns_10_2, dut_i.u_core.l0vpns[10][2]);
    chk("l0h[10][3]", dut_g.l0h_10_3, dut_i.u_core.l0h[10][3]);
    chk("l0asids[10][3]", dut_g.l0asids_10_3, dut_i.u_core.l0asids[10][3]);
    chk("l0vmids[10][3]", dut_g.l0vmids_10_3, dut_i.u_core.l0vmids[10][3]);
    chk("l0vpns[10][3]", dut_g.l0vpns_10_3, dut_i.u_core.l0vpns[10][3]);
    chk("l0h[11][0]", dut_g.l0h_11_0, dut_i.u_core.l0h[11][0]);
    chk("l0asids[11][0]", dut_g.l0asids_11_0, dut_i.u_core.l0asids[11][0]);
    chk("l0vmids[11][0]", dut_g.l0vmids_11_0, dut_i.u_core.l0vmids[11][0]);
    chk("l0vpns[11][0]", dut_g.l0vpns_11_0, dut_i.u_core.l0vpns[11][0]);
    chk("l0h[11][1]", dut_g.l0h_11_1, dut_i.u_core.l0h[11][1]);
    chk("l0asids[11][1]", dut_g.l0asids_11_1, dut_i.u_core.l0asids[11][1]);
    chk("l0vmids[11][1]", dut_g.l0vmids_11_1, dut_i.u_core.l0vmids[11][1]);
    chk("l0vpns[11][1]", dut_g.l0vpns_11_1, dut_i.u_core.l0vpns[11][1]);
    chk("l0h[11][2]", dut_g.l0h_11_2, dut_i.u_core.l0h[11][2]);
    chk("l0asids[11][2]", dut_g.l0asids_11_2, dut_i.u_core.l0asids[11][2]);
    chk("l0vmids[11][2]", dut_g.l0vmids_11_2, dut_i.u_core.l0vmids[11][2]);
    chk("l0vpns[11][2]", dut_g.l0vpns_11_2, dut_i.u_core.l0vpns[11][2]);
    chk("l0h[11][3]", dut_g.l0h_11_3, dut_i.u_core.l0h[11][3]);
    chk("l0asids[11][3]", dut_g.l0asids_11_3, dut_i.u_core.l0asids[11][3]);
    chk("l0vmids[11][3]", dut_g.l0vmids_11_3, dut_i.u_core.l0vmids[11][3]);
    chk("l0vpns[11][3]", dut_g.l0vpns_11_3, dut_i.u_core.l0vpns[11][3]);
    chk("l0h[12][0]", dut_g.l0h_12_0, dut_i.u_core.l0h[12][0]);
    chk("l0asids[12][0]", dut_g.l0asids_12_0, dut_i.u_core.l0asids[12][0]);
    chk("l0vmids[12][0]", dut_g.l0vmids_12_0, dut_i.u_core.l0vmids[12][0]);
    chk("l0vpns[12][0]", dut_g.l0vpns_12_0, dut_i.u_core.l0vpns[12][0]);
    chk("l0h[12][1]", dut_g.l0h_12_1, dut_i.u_core.l0h[12][1]);
    chk("l0asids[12][1]", dut_g.l0asids_12_1, dut_i.u_core.l0asids[12][1]);
    chk("l0vmids[12][1]", dut_g.l0vmids_12_1, dut_i.u_core.l0vmids[12][1]);
    chk("l0vpns[12][1]", dut_g.l0vpns_12_1, dut_i.u_core.l0vpns[12][1]);
    chk("l0h[12][2]", dut_g.l0h_12_2, dut_i.u_core.l0h[12][2]);
    chk("l0asids[12][2]", dut_g.l0asids_12_2, dut_i.u_core.l0asids[12][2]);
    chk("l0vmids[12][2]", dut_g.l0vmids_12_2, dut_i.u_core.l0vmids[12][2]);
    chk("l0vpns[12][2]", dut_g.l0vpns_12_2, dut_i.u_core.l0vpns[12][2]);
    chk("l0h[12][3]", dut_g.l0h_12_3, dut_i.u_core.l0h[12][3]);
    chk("l0asids[12][3]", dut_g.l0asids_12_3, dut_i.u_core.l0asids[12][3]);
    chk("l0vmids[12][3]", dut_g.l0vmids_12_3, dut_i.u_core.l0vmids[12][3]);
    chk("l0vpns[12][3]", dut_g.l0vpns_12_3, dut_i.u_core.l0vpns[12][3]);
    chk("l0h[13][0]", dut_g.l0h_13_0, dut_i.u_core.l0h[13][0]);
    chk("l0asids[13][0]", dut_g.l0asids_13_0, dut_i.u_core.l0asids[13][0]);
    chk("l0vmids[13][0]", dut_g.l0vmids_13_0, dut_i.u_core.l0vmids[13][0]);
    chk("l0vpns[13][0]", dut_g.l0vpns_13_0, dut_i.u_core.l0vpns[13][0]);
    chk("l0h[13][1]", dut_g.l0h_13_1, dut_i.u_core.l0h[13][1]);
    chk("l0asids[13][1]", dut_g.l0asids_13_1, dut_i.u_core.l0asids[13][1]);
    chk("l0vmids[13][1]", dut_g.l0vmids_13_1, dut_i.u_core.l0vmids[13][1]);
    chk("l0vpns[13][1]", dut_g.l0vpns_13_1, dut_i.u_core.l0vpns[13][1]);
    chk("l0h[13][2]", dut_g.l0h_13_2, dut_i.u_core.l0h[13][2]);
    chk("l0asids[13][2]", dut_g.l0asids_13_2, dut_i.u_core.l0asids[13][2]);
    chk("l0vmids[13][2]", dut_g.l0vmids_13_2, dut_i.u_core.l0vmids[13][2]);
    chk("l0vpns[13][2]", dut_g.l0vpns_13_2, dut_i.u_core.l0vpns[13][2]);
    chk("l0h[13][3]", dut_g.l0h_13_3, dut_i.u_core.l0h[13][3]);
    chk("l0asids[13][3]", dut_g.l0asids_13_3, dut_i.u_core.l0asids[13][3]);
    chk("l0vmids[13][3]", dut_g.l0vmids_13_3, dut_i.u_core.l0vmids[13][3]);
    chk("l0vpns[13][3]", dut_g.l0vpns_13_3, dut_i.u_core.l0vpns[13][3]);
    chk("l0h[14][0]", dut_g.l0h_14_0, dut_i.u_core.l0h[14][0]);
    chk("l0asids[14][0]", dut_g.l0asids_14_0, dut_i.u_core.l0asids[14][0]);
    chk("l0vmids[14][0]", dut_g.l0vmids_14_0, dut_i.u_core.l0vmids[14][0]);
    chk("l0vpns[14][0]", dut_g.l0vpns_14_0, dut_i.u_core.l0vpns[14][0]);
    chk("l0h[14][1]", dut_g.l0h_14_1, dut_i.u_core.l0h[14][1]);
    chk("l0asids[14][1]", dut_g.l0asids_14_1, dut_i.u_core.l0asids[14][1]);
    chk("l0vmids[14][1]", dut_g.l0vmids_14_1, dut_i.u_core.l0vmids[14][1]);
    chk("l0vpns[14][1]", dut_g.l0vpns_14_1, dut_i.u_core.l0vpns[14][1]);
    chk("l0h[14][2]", dut_g.l0h_14_2, dut_i.u_core.l0h[14][2]);
    chk("l0asids[14][2]", dut_g.l0asids_14_2, dut_i.u_core.l0asids[14][2]);
    chk("l0vmids[14][2]", dut_g.l0vmids_14_2, dut_i.u_core.l0vmids[14][2]);
    chk("l0vpns[14][2]", dut_g.l0vpns_14_2, dut_i.u_core.l0vpns[14][2]);
    chk("l0h[14][3]", dut_g.l0h_14_3, dut_i.u_core.l0h[14][3]);
    chk("l0asids[14][3]", dut_g.l0asids_14_3, dut_i.u_core.l0asids[14][3]);
    chk("l0vmids[14][3]", dut_g.l0vmids_14_3, dut_i.u_core.l0vmids[14][3]);
    chk("l0vpns[14][3]", dut_g.l0vpns_14_3, dut_i.u_core.l0vpns[14][3]);
    chk("l0h[15][0]", dut_g.l0h_15_0, dut_i.u_core.l0h[15][0]);
    chk("l0asids[15][0]", dut_g.l0asids_15_0, dut_i.u_core.l0asids[15][0]);
    chk("l0vmids[15][0]", dut_g.l0vmids_15_0, dut_i.u_core.l0vmids[15][0]);
    chk("l0vpns[15][0]", dut_g.l0vpns_15_0, dut_i.u_core.l0vpns[15][0]);
    chk("l0h[15][1]", dut_g.l0h_15_1, dut_i.u_core.l0h[15][1]);
    chk("l0asids[15][1]", dut_g.l0asids_15_1, dut_i.u_core.l0asids[15][1]);
    chk("l0vmids[15][1]", dut_g.l0vmids_15_1, dut_i.u_core.l0vmids[15][1]);
    chk("l0vpns[15][1]", dut_g.l0vpns_15_1, dut_i.u_core.l0vpns[15][1]);
    chk("l0h[15][2]", dut_g.l0h_15_2, dut_i.u_core.l0h[15][2]);
    chk("l0asids[15][2]", dut_g.l0asids_15_2, dut_i.u_core.l0asids[15][2]);
    chk("l0vmids[15][2]", dut_g.l0vmids_15_2, dut_i.u_core.l0vmids[15][2]);
    chk("l0vpns[15][2]", dut_g.l0vpns_15_2, dut_i.u_core.l0vpns[15][2]);
    chk("l0h[15][3]", dut_g.l0h_15_3, dut_i.u_core.l0h[15][3]);
    chk("l0asids[15][3]", dut_g.l0asids_15_3, dut_i.u_core.l0asids[15][3]);
    chk("l0vmids[15][3]", dut_g.l0vmids_15_3, dut_i.u_core.l0vmids[15][3]);
    chk("l0vpns[15][3]", dut_g.l0vpns_15_3, dut_i.u_core.l0vpns[15][3]);
    chk("l0h[16][0]", dut_g.l0h_16_0, dut_i.u_core.l0h[16][0]);
    chk("l0asids[16][0]", dut_g.l0asids_16_0, dut_i.u_core.l0asids[16][0]);
    chk("l0vmids[16][0]", dut_g.l0vmids_16_0, dut_i.u_core.l0vmids[16][0]);
    chk("l0vpns[16][0]", dut_g.l0vpns_16_0, dut_i.u_core.l0vpns[16][0]);
    chk("l0h[16][1]", dut_g.l0h_16_1, dut_i.u_core.l0h[16][1]);
    chk("l0asids[16][1]", dut_g.l0asids_16_1, dut_i.u_core.l0asids[16][1]);
    chk("l0vmids[16][1]", dut_g.l0vmids_16_1, dut_i.u_core.l0vmids[16][1]);
    chk("l0vpns[16][1]", dut_g.l0vpns_16_1, dut_i.u_core.l0vpns[16][1]);
    chk("l0h[16][2]", dut_g.l0h_16_2, dut_i.u_core.l0h[16][2]);
    chk("l0asids[16][2]", dut_g.l0asids_16_2, dut_i.u_core.l0asids[16][2]);
    chk("l0vmids[16][2]", dut_g.l0vmids_16_2, dut_i.u_core.l0vmids[16][2]);
    chk("l0vpns[16][2]", dut_g.l0vpns_16_2, dut_i.u_core.l0vpns[16][2]);
    chk("l0h[16][3]", dut_g.l0h_16_3, dut_i.u_core.l0h[16][3]);
    chk("l0asids[16][3]", dut_g.l0asids_16_3, dut_i.u_core.l0asids[16][3]);
    chk("l0vmids[16][3]", dut_g.l0vmids_16_3, dut_i.u_core.l0vmids[16][3]);
    chk("l0vpns[16][3]", dut_g.l0vpns_16_3, dut_i.u_core.l0vpns[16][3]);
    chk("l0h[17][0]", dut_g.l0h_17_0, dut_i.u_core.l0h[17][0]);
    chk("l0asids[17][0]", dut_g.l0asids_17_0, dut_i.u_core.l0asids[17][0]);
    chk("l0vmids[17][0]", dut_g.l0vmids_17_0, dut_i.u_core.l0vmids[17][0]);
    chk("l0vpns[17][0]", dut_g.l0vpns_17_0, dut_i.u_core.l0vpns[17][0]);
    chk("l0h[17][1]", dut_g.l0h_17_1, dut_i.u_core.l0h[17][1]);
    chk("l0asids[17][1]", dut_g.l0asids_17_1, dut_i.u_core.l0asids[17][1]);
    chk("l0vmids[17][1]", dut_g.l0vmids_17_1, dut_i.u_core.l0vmids[17][1]);
    chk("l0vpns[17][1]", dut_g.l0vpns_17_1, dut_i.u_core.l0vpns[17][1]);
    chk("l0h[17][2]", dut_g.l0h_17_2, dut_i.u_core.l0h[17][2]);
    chk("l0asids[17][2]", dut_g.l0asids_17_2, dut_i.u_core.l0asids[17][2]);
    chk("l0vmids[17][2]", dut_g.l0vmids_17_2, dut_i.u_core.l0vmids[17][2]);
    chk("l0vpns[17][2]", dut_g.l0vpns_17_2, dut_i.u_core.l0vpns[17][2]);
    chk("l0h[17][3]", dut_g.l0h_17_3, dut_i.u_core.l0h[17][3]);
    chk("l0asids[17][3]", dut_g.l0asids_17_3, dut_i.u_core.l0asids[17][3]);
    chk("l0vmids[17][3]", dut_g.l0vmids_17_3, dut_i.u_core.l0vmids[17][3]);
    chk("l0vpns[17][3]", dut_g.l0vpns_17_3, dut_i.u_core.l0vpns[17][3]);
    chk("l0h[18][0]", dut_g.l0h_18_0, dut_i.u_core.l0h[18][0]);
    chk("l0asids[18][0]", dut_g.l0asids_18_0, dut_i.u_core.l0asids[18][0]);
    chk("l0vmids[18][0]", dut_g.l0vmids_18_0, dut_i.u_core.l0vmids[18][0]);
    chk("l0vpns[18][0]", dut_g.l0vpns_18_0, dut_i.u_core.l0vpns[18][0]);
    chk("l0h[18][1]", dut_g.l0h_18_1, dut_i.u_core.l0h[18][1]);
    chk("l0asids[18][1]", dut_g.l0asids_18_1, dut_i.u_core.l0asids[18][1]);
    chk("l0vmids[18][1]", dut_g.l0vmids_18_1, dut_i.u_core.l0vmids[18][1]);
    chk("l0vpns[18][1]", dut_g.l0vpns_18_1, dut_i.u_core.l0vpns[18][1]);
    chk("l0h[18][2]", dut_g.l0h_18_2, dut_i.u_core.l0h[18][2]);
    chk("l0asids[18][2]", dut_g.l0asids_18_2, dut_i.u_core.l0asids[18][2]);
    chk("l0vmids[18][2]", dut_g.l0vmids_18_2, dut_i.u_core.l0vmids[18][2]);
    chk("l0vpns[18][2]", dut_g.l0vpns_18_2, dut_i.u_core.l0vpns[18][2]);
    chk("l0h[18][3]", dut_g.l0h_18_3, dut_i.u_core.l0h[18][3]);
    chk("l0asids[18][3]", dut_g.l0asids_18_3, dut_i.u_core.l0asids[18][3]);
    chk("l0vmids[18][3]", dut_g.l0vmids_18_3, dut_i.u_core.l0vmids[18][3]);
    chk("l0vpns[18][3]", dut_g.l0vpns_18_3, dut_i.u_core.l0vpns[18][3]);
    chk("l0h[19][0]", dut_g.l0h_19_0, dut_i.u_core.l0h[19][0]);
    chk("l0asids[19][0]", dut_g.l0asids_19_0, dut_i.u_core.l0asids[19][0]);
    chk("l0vmids[19][0]", dut_g.l0vmids_19_0, dut_i.u_core.l0vmids[19][0]);
    chk("l0vpns[19][0]", dut_g.l0vpns_19_0, dut_i.u_core.l0vpns[19][0]);
    chk("l0h[19][1]", dut_g.l0h_19_1, dut_i.u_core.l0h[19][1]);
    chk("l0asids[19][1]", dut_g.l0asids_19_1, dut_i.u_core.l0asids[19][1]);
    chk("l0vmids[19][1]", dut_g.l0vmids_19_1, dut_i.u_core.l0vmids[19][1]);
    chk("l0vpns[19][1]", dut_g.l0vpns_19_1, dut_i.u_core.l0vpns[19][1]);
    chk("l0h[19][2]", dut_g.l0h_19_2, dut_i.u_core.l0h[19][2]);
    chk("l0asids[19][2]", dut_g.l0asids_19_2, dut_i.u_core.l0asids[19][2]);
    chk("l0vmids[19][2]", dut_g.l0vmids_19_2, dut_i.u_core.l0vmids[19][2]);
    chk("l0vpns[19][2]", dut_g.l0vpns_19_2, dut_i.u_core.l0vpns[19][2]);
    chk("l0h[19][3]", dut_g.l0h_19_3, dut_i.u_core.l0h[19][3]);
    chk("l0asids[19][3]", dut_g.l0asids_19_3, dut_i.u_core.l0asids[19][3]);
    chk("l0vmids[19][3]", dut_g.l0vmids_19_3, dut_i.u_core.l0vmids[19][3]);
    chk("l0vpns[19][3]", dut_g.l0vpns_19_3, dut_i.u_core.l0vpns[19][3]);
    chk("l0h[20][0]", dut_g.l0h_20_0, dut_i.u_core.l0h[20][0]);
    chk("l0asids[20][0]", dut_g.l0asids_20_0, dut_i.u_core.l0asids[20][0]);
    chk("l0vmids[20][0]", dut_g.l0vmids_20_0, dut_i.u_core.l0vmids[20][0]);
    chk("l0vpns[20][0]", dut_g.l0vpns_20_0, dut_i.u_core.l0vpns[20][0]);
    chk("l0h[20][1]", dut_g.l0h_20_1, dut_i.u_core.l0h[20][1]);
    chk("l0asids[20][1]", dut_g.l0asids_20_1, dut_i.u_core.l0asids[20][1]);
    chk("l0vmids[20][1]", dut_g.l0vmids_20_1, dut_i.u_core.l0vmids[20][1]);
    chk("l0vpns[20][1]", dut_g.l0vpns_20_1, dut_i.u_core.l0vpns[20][1]);
    chk("l0h[20][2]", dut_g.l0h_20_2, dut_i.u_core.l0h[20][2]);
    chk("l0asids[20][2]", dut_g.l0asids_20_2, dut_i.u_core.l0asids[20][2]);
    chk("l0vmids[20][2]", dut_g.l0vmids_20_2, dut_i.u_core.l0vmids[20][2]);
    chk("l0vpns[20][2]", dut_g.l0vpns_20_2, dut_i.u_core.l0vpns[20][2]);
    chk("l0h[20][3]", dut_g.l0h_20_3, dut_i.u_core.l0h[20][3]);
    chk("l0asids[20][3]", dut_g.l0asids_20_3, dut_i.u_core.l0asids[20][3]);
    chk("l0vmids[20][3]", dut_g.l0vmids_20_3, dut_i.u_core.l0vmids[20][3]);
    chk("l0vpns[20][3]", dut_g.l0vpns_20_3, dut_i.u_core.l0vpns[20][3]);
    chk("l0h[21][0]", dut_g.l0h_21_0, dut_i.u_core.l0h[21][0]);
    chk("l0asids[21][0]", dut_g.l0asids_21_0, dut_i.u_core.l0asids[21][0]);
    chk("l0vmids[21][0]", dut_g.l0vmids_21_0, dut_i.u_core.l0vmids[21][0]);
    chk("l0vpns[21][0]", dut_g.l0vpns_21_0, dut_i.u_core.l0vpns[21][0]);
    chk("l0h[21][1]", dut_g.l0h_21_1, dut_i.u_core.l0h[21][1]);
    chk("l0asids[21][1]", dut_g.l0asids_21_1, dut_i.u_core.l0asids[21][1]);
    chk("l0vmids[21][1]", dut_g.l0vmids_21_1, dut_i.u_core.l0vmids[21][1]);
    chk("l0vpns[21][1]", dut_g.l0vpns_21_1, dut_i.u_core.l0vpns[21][1]);
    chk("l0h[21][2]", dut_g.l0h_21_2, dut_i.u_core.l0h[21][2]);
    chk("l0asids[21][2]", dut_g.l0asids_21_2, dut_i.u_core.l0asids[21][2]);
    chk("l0vmids[21][2]", dut_g.l0vmids_21_2, dut_i.u_core.l0vmids[21][2]);
    chk("l0vpns[21][2]", dut_g.l0vpns_21_2, dut_i.u_core.l0vpns[21][2]);
    chk("l0h[21][3]", dut_g.l0h_21_3, dut_i.u_core.l0h[21][3]);
    chk("l0asids[21][3]", dut_g.l0asids_21_3, dut_i.u_core.l0asids[21][3]);
    chk("l0vmids[21][3]", dut_g.l0vmids_21_3, dut_i.u_core.l0vmids[21][3]);
    chk("l0vpns[21][3]", dut_g.l0vpns_21_3, dut_i.u_core.l0vpns[21][3]);
    chk("l0h[22][0]", dut_g.l0h_22_0, dut_i.u_core.l0h[22][0]);
    chk("l0asids[22][0]", dut_g.l0asids_22_0, dut_i.u_core.l0asids[22][0]);
    chk("l0vmids[22][0]", dut_g.l0vmids_22_0, dut_i.u_core.l0vmids[22][0]);
    chk("l0vpns[22][0]", dut_g.l0vpns_22_0, dut_i.u_core.l0vpns[22][0]);
    chk("l0h[22][1]", dut_g.l0h_22_1, dut_i.u_core.l0h[22][1]);
    chk("l0asids[22][1]", dut_g.l0asids_22_1, dut_i.u_core.l0asids[22][1]);
    chk("l0vmids[22][1]", dut_g.l0vmids_22_1, dut_i.u_core.l0vmids[22][1]);
    chk("l0vpns[22][1]", dut_g.l0vpns_22_1, dut_i.u_core.l0vpns[22][1]);
    chk("l0h[22][2]", dut_g.l0h_22_2, dut_i.u_core.l0h[22][2]);
    chk("l0asids[22][2]", dut_g.l0asids_22_2, dut_i.u_core.l0asids[22][2]);
    chk("l0vmids[22][2]", dut_g.l0vmids_22_2, dut_i.u_core.l0vmids[22][2]);
    chk("l0vpns[22][2]", dut_g.l0vpns_22_2, dut_i.u_core.l0vpns[22][2]);
    chk("l0h[22][3]", dut_g.l0h_22_3, dut_i.u_core.l0h[22][3]);
    chk("l0asids[22][3]", dut_g.l0asids_22_3, dut_i.u_core.l0asids[22][3]);
    chk("l0vmids[22][3]", dut_g.l0vmids_22_3, dut_i.u_core.l0vmids[22][3]);
    chk("l0vpns[22][3]", dut_g.l0vpns_22_3, dut_i.u_core.l0vpns[22][3]);
    chk("l0h[23][0]", dut_g.l0h_23_0, dut_i.u_core.l0h[23][0]);
    chk("l0asids[23][0]", dut_g.l0asids_23_0, dut_i.u_core.l0asids[23][0]);
    chk("l0vmids[23][0]", dut_g.l0vmids_23_0, dut_i.u_core.l0vmids[23][0]);
    chk("l0vpns[23][0]", dut_g.l0vpns_23_0, dut_i.u_core.l0vpns[23][0]);
    chk("l0h[23][1]", dut_g.l0h_23_1, dut_i.u_core.l0h[23][1]);
    chk("l0asids[23][1]", dut_g.l0asids_23_1, dut_i.u_core.l0asids[23][1]);
    chk("l0vmids[23][1]", dut_g.l0vmids_23_1, dut_i.u_core.l0vmids[23][1]);
    chk("l0vpns[23][1]", dut_g.l0vpns_23_1, dut_i.u_core.l0vpns[23][1]);
    chk("l0h[23][2]", dut_g.l0h_23_2, dut_i.u_core.l0h[23][2]);
    chk("l0asids[23][2]", dut_g.l0asids_23_2, dut_i.u_core.l0asids[23][2]);
    chk("l0vmids[23][2]", dut_g.l0vmids_23_2, dut_i.u_core.l0vmids[23][2]);
    chk("l0vpns[23][2]", dut_g.l0vpns_23_2, dut_i.u_core.l0vpns[23][2]);
    chk("l0h[23][3]", dut_g.l0h_23_3, dut_i.u_core.l0h[23][3]);
    chk("l0asids[23][3]", dut_g.l0asids_23_3, dut_i.u_core.l0asids[23][3]);
    chk("l0vmids[23][3]", dut_g.l0vmids_23_3, dut_i.u_core.l0vmids[23][3]);
    chk("l0vpns[23][3]", dut_g.l0vpns_23_3, dut_i.u_core.l0vpns[23][3]);
    chk("l0h[24][0]", dut_g.l0h_24_0, dut_i.u_core.l0h[24][0]);
    chk("l0asids[24][0]", dut_g.l0asids_24_0, dut_i.u_core.l0asids[24][0]);
    chk("l0vmids[24][0]", dut_g.l0vmids_24_0, dut_i.u_core.l0vmids[24][0]);
    chk("l0vpns[24][0]", dut_g.l0vpns_24_0, dut_i.u_core.l0vpns[24][0]);
    chk("l0h[24][1]", dut_g.l0h_24_1, dut_i.u_core.l0h[24][1]);
    chk("l0asids[24][1]", dut_g.l0asids_24_1, dut_i.u_core.l0asids[24][1]);
    chk("l0vmids[24][1]", dut_g.l0vmids_24_1, dut_i.u_core.l0vmids[24][1]);
    chk("l0vpns[24][1]", dut_g.l0vpns_24_1, dut_i.u_core.l0vpns[24][1]);
    chk("l0h[24][2]", dut_g.l0h_24_2, dut_i.u_core.l0h[24][2]);
    chk("l0asids[24][2]", dut_g.l0asids_24_2, dut_i.u_core.l0asids[24][2]);
    chk("l0vmids[24][2]", dut_g.l0vmids_24_2, dut_i.u_core.l0vmids[24][2]);
    chk("l0vpns[24][2]", dut_g.l0vpns_24_2, dut_i.u_core.l0vpns[24][2]);
    chk("l0h[24][3]", dut_g.l0h_24_3, dut_i.u_core.l0h[24][3]);
    chk("l0asids[24][3]", dut_g.l0asids_24_3, dut_i.u_core.l0asids[24][3]);
    chk("l0vmids[24][3]", dut_g.l0vmids_24_3, dut_i.u_core.l0vmids[24][3]);
    chk("l0vpns[24][3]", dut_g.l0vpns_24_3, dut_i.u_core.l0vpns[24][3]);
    chk("l0h[25][0]", dut_g.l0h_25_0, dut_i.u_core.l0h[25][0]);
    chk("l0asids[25][0]", dut_g.l0asids_25_0, dut_i.u_core.l0asids[25][0]);
    chk("l0vmids[25][0]", dut_g.l0vmids_25_0, dut_i.u_core.l0vmids[25][0]);
    chk("l0vpns[25][0]", dut_g.l0vpns_25_0, dut_i.u_core.l0vpns[25][0]);
    chk("l0h[25][1]", dut_g.l0h_25_1, dut_i.u_core.l0h[25][1]);
    chk("l0asids[25][1]", dut_g.l0asids_25_1, dut_i.u_core.l0asids[25][1]);
    chk("l0vmids[25][1]", dut_g.l0vmids_25_1, dut_i.u_core.l0vmids[25][1]);
    chk("l0vpns[25][1]", dut_g.l0vpns_25_1, dut_i.u_core.l0vpns[25][1]);
    chk("l0h[25][2]", dut_g.l0h_25_2, dut_i.u_core.l0h[25][2]);
    chk("l0asids[25][2]", dut_g.l0asids_25_2, dut_i.u_core.l0asids[25][2]);
    chk("l0vmids[25][2]", dut_g.l0vmids_25_2, dut_i.u_core.l0vmids[25][2]);
    chk("l0vpns[25][2]", dut_g.l0vpns_25_2, dut_i.u_core.l0vpns[25][2]);
    chk("l0h[25][3]", dut_g.l0h_25_3, dut_i.u_core.l0h[25][3]);
    chk("l0asids[25][3]", dut_g.l0asids_25_3, dut_i.u_core.l0asids[25][3]);
    chk("l0vmids[25][3]", dut_g.l0vmids_25_3, dut_i.u_core.l0vmids[25][3]);
    chk("l0vpns[25][3]", dut_g.l0vpns_25_3, dut_i.u_core.l0vpns[25][3]);
    chk("l0h[26][0]", dut_g.l0h_26_0, dut_i.u_core.l0h[26][0]);
    chk("l0asids[26][0]", dut_g.l0asids_26_0, dut_i.u_core.l0asids[26][0]);
    chk("l0vmids[26][0]", dut_g.l0vmids_26_0, dut_i.u_core.l0vmids[26][0]);
    chk("l0vpns[26][0]", dut_g.l0vpns_26_0, dut_i.u_core.l0vpns[26][0]);
    chk("l0h[26][1]", dut_g.l0h_26_1, dut_i.u_core.l0h[26][1]);
    chk("l0asids[26][1]", dut_g.l0asids_26_1, dut_i.u_core.l0asids[26][1]);
    chk("l0vmids[26][1]", dut_g.l0vmids_26_1, dut_i.u_core.l0vmids[26][1]);
    chk("l0vpns[26][1]", dut_g.l0vpns_26_1, dut_i.u_core.l0vpns[26][1]);
    chk("l0h[26][2]", dut_g.l0h_26_2, dut_i.u_core.l0h[26][2]);
    chk("l0asids[26][2]", dut_g.l0asids_26_2, dut_i.u_core.l0asids[26][2]);
    chk("l0vmids[26][2]", dut_g.l0vmids_26_2, dut_i.u_core.l0vmids[26][2]);
    chk("l0vpns[26][2]", dut_g.l0vpns_26_2, dut_i.u_core.l0vpns[26][2]);
    chk("l0h[26][3]", dut_g.l0h_26_3, dut_i.u_core.l0h[26][3]);
    chk("l0asids[26][3]", dut_g.l0asids_26_3, dut_i.u_core.l0asids[26][3]);
    chk("l0vmids[26][3]", dut_g.l0vmids_26_3, dut_i.u_core.l0vmids[26][3]);
    chk("l0vpns[26][3]", dut_g.l0vpns_26_3, dut_i.u_core.l0vpns[26][3]);
    chk("l0h[27][0]", dut_g.l0h_27_0, dut_i.u_core.l0h[27][0]);
    chk("l0asids[27][0]", dut_g.l0asids_27_0, dut_i.u_core.l0asids[27][0]);
    chk("l0vmids[27][0]", dut_g.l0vmids_27_0, dut_i.u_core.l0vmids[27][0]);
    chk("l0vpns[27][0]", dut_g.l0vpns_27_0, dut_i.u_core.l0vpns[27][0]);
    chk("l0h[27][1]", dut_g.l0h_27_1, dut_i.u_core.l0h[27][1]);
    chk("l0asids[27][1]", dut_g.l0asids_27_1, dut_i.u_core.l0asids[27][1]);
    chk("l0vmids[27][1]", dut_g.l0vmids_27_1, dut_i.u_core.l0vmids[27][1]);
    chk("l0vpns[27][1]", dut_g.l0vpns_27_1, dut_i.u_core.l0vpns[27][1]);
    chk("l0h[27][2]", dut_g.l0h_27_2, dut_i.u_core.l0h[27][2]);
    chk("l0asids[27][2]", dut_g.l0asids_27_2, dut_i.u_core.l0asids[27][2]);
    chk("l0vmids[27][2]", dut_g.l0vmids_27_2, dut_i.u_core.l0vmids[27][2]);
    chk("l0vpns[27][2]", dut_g.l0vpns_27_2, dut_i.u_core.l0vpns[27][2]);
    chk("l0h[27][3]", dut_g.l0h_27_3, dut_i.u_core.l0h[27][3]);
    chk("l0asids[27][3]", dut_g.l0asids_27_3, dut_i.u_core.l0asids[27][3]);
    chk("l0vmids[27][3]", dut_g.l0vmids_27_3, dut_i.u_core.l0vmids[27][3]);
    chk("l0vpns[27][3]", dut_g.l0vpns_27_3, dut_i.u_core.l0vpns[27][3]);
    chk("l0h[28][0]", dut_g.l0h_28_0, dut_i.u_core.l0h[28][0]);
    chk("l0asids[28][0]", dut_g.l0asids_28_0, dut_i.u_core.l0asids[28][0]);
    chk("l0vmids[28][0]", dut_g.l0vmids_28_0, dut_i.u_core.l0vmids[28][0]);
    chk("l0vpns[28][0]", dut_g.l0vpns_28_0, dut_i.u_core.l0vpns[28][0]);
    chk("l0h[28][1]", dut_g.l0h_28_1, dut_i.u_core.l0h[28][1]);
    chk("l0asids[28][1]", dut_g.l0asids_28_1, dut_i.u_core.l0asids[28][1]);
    chk("l0vmids[28][1]", dut_g.l0vmids_28_1, dut_i.u_core.l0vmids[28][1]);
    chk("l0vpns[28][1]", dut_g.l0vpns_28_1, dut_i.u_core.l0vpns[28][1]);
    chk("l0h[28][2]", dut_g.l0h_28_2, dut_i.u_core.l0h[28][2]);
    chk("l0asids[28][2]", dut_g.l0asids_28_2, dut_i.u_core.l0asids[28][2]);
    chk("l0vmids[28][2]", dut_g.l0vmids_28_2, dut_i.u_core.l0vmids[28][2]);
    chk("l0vpns[28][2]", dut_g.l0vpns_28_2, dut_i.u_core.l0vpns[28][2]);
    chk("l0h[28][3]", dut_g.l0h_28_3, dut_i.u_core.l0h[28][3]);
    chk("l0asids[28][3]", dut_g.l0asids_28_3, dut_i.u_core.l0asids[28][3]);
    chk("l0vmids[28][3]", dut_g.l0vmids_28_3, dut_i.u_core.l0vmids[28][3]);
    chk("l0vpns[28][3]", dut_g.l0vpns_28_3, dut_i.u_core.l0vpns[28][3]);
    chk("l0h[29][0]", dut_g.l0h_29_0, dut_i.u_core.l0h[29][0]);
    chk("l0asids[29][0]", dut_g.l0asids_29_0, dut_i.u_core.l0asids[29][0]);
    chk("l0vmids[29][0]", dut_g.l0vmids_29_0, dut_i.u_core.l0vmids[29][0]);
    chk("l0vpns[29][0]", dut_g.l0vpns_29_0, dut_i.u_core.l0vpns[29][0]);
    chk("l0h[29][1]", dut_g.l0h_29_1, dut_i.u_core.l0h[29][1]);
    chk("l0asids[29][1]", dut_g.l0asids_29_1, dut_i.u_core.l0asids[29][1]);
    chk("l0vmids[29][1]", dut_g.l0vmids_29_1, dut_i.u_core.l0vmids[29][1]);
    chk("l0vpns[29][1]", dut_g.l0vpns_29_1, dut_i.u_core.l0vpns[29][1]);
    chk("l0h[29][2]", dut_g.l0h_29_2, dut_i.u_core.l0h[29][2]);
    chk("l0asids[29][2]", dut_g.l0asids_29_2, dut_i.u_core.l0asids[29][2]);
    chk("l0vmids[29][2]", dut_g.l0vmids_29_2, dut_i.u_core.l0vmids[29][2]);
    chk("l0vpns[29][2]", dut_g.l0vpns_29_2, dut_i.u_core.l0vpns[29][2]);
    chk("l0h[29][3]", dut_g.l0h_29_3, dut_i.u_core.l0h[29][3]);
    chk("l0asids[29][3]", dut_g.l0asids_29_3, dut_i.u_core.l0asids[29][3]);
    chk("l0vmids[29][3]", dut_g.l0vmids_29_3, dut_i.u_core.l0vmids[29][3]);
    chk("l0vpns[29][3]", dut_g.l0vpns_29_3, dut_i.u_core.l0vpns[29][3]);
    chk("l0h[30][0]", dut_g.l0h_30_0, dut_i.u_core.l0h[30][0]);
    chk("l0asids[30][0]", dut_g.l0asids_30_0, dut_i.u_core.l0asids[30][0]);
    chk("l0vmids[30][0]", dut_g.l0vmids_30_0, dut_i.u_core.l0vmids[30][0]);
    chk("l0vpns[30][0]", dut_g.l0vpns_30_0, dut_i.u_core.l0vpns[30][0]);
    chk("l0h[30][1]", dut_g.l0h_30_1, dut_i.u_core.l0h[30][1]);
    chk("l0asids[30][1]", dut_g.l0asids_30_1, dut_i.u_core.l0asids[30][1]);
    chk("l0vmids[30][1]", dut_g.l0vmids_30_1, dut_i.u_core.l0vmids[30][1]);
    chk("l0vpns[30][1]", dut_g.l0vpns_30_1, dut_i.u_core.l0vpns[30][1]);
    chk("l0h[30][2]", dut_g.l0h_30_2, dut_i.u_core.l0h[30][2]);
    chk("l0asids[30][2]", dut_g.l0asids_30_2, dut_i.u_core.l0asids[30][2]);
    chk("l0vmids[30][2]", dut_g.l0vmids_30_2, dut_i.u_core.l0vmids[30][2]);
    chk("l0vpns[30][2]", dut_g.l0vpns_30_2, dut_i.u_core.l0vpns[30][2]);
    chk("l0h[30][3]", dut_g.l0h_30_3, dut_i.u_core.l0h[30][3]);
    chk("l0asids[30][3]", dut_g.l0asids_30_3, dut_i.u_core.l0asids[30][3]);
    chk("l0vmids[30][3]", dut_g.l0vmids_30_3, dut_i.u_core.l0vmids[30][3]);
    chk("l0vpns[30][3]", dut_g.l0vpns_30_3, dut_i.u_core.l0vpns[30][3]);
    chk("l0h[31][0]", dut_g.l0h_31_0, dut_i.u_core.l0h[31][0]);
    chk("l0asids[31][0]", dut_g.l0asids_31_0, dut_i.u_core.l0asids[31][0]);
    chk("l0vmids[31][0]", dut_g.l0vmids_31_0, dut_i.u_core.l0vmids[31][0]);
    chk("l0vpns[31][0]", dut_g.l0vpns_31_0, dut_i.u_core.l0vpns[31][0]);
    chk("l0h[31][1]", dut_g.l0h_31_1, dut_i.u_core.l0h[31][1]);
    chk("l0asids[31][1]", dut_g.l0asids_31_1, dut_i.u_core.l0asids[31][1]);
    chk("l0vmids[31][1]", dut_g.l0vmids_31_1, dut_i.u_core.l0vmids[31][1]);
    chk("l0vpns[31][1]", dut_g.l0vpns_31_1, dut_i.u_core.l0vpns[31][1]);
    chk("l0h[31][2]", dut_g.l0h_31_2, dut_i.u_core.l0h[31][2]);
    chk("l0asids[31][2]", dut_g.l0asids_31_2, dut_i.u_core.l0asids[31][2]);
    chk("l0vmids[31][2]", dut_g.l0vmids_31_2, dut_i.u_core.l0vmids[31][2]);
    chk("l0vpns[31][2]", dut_g.l0vpns_31_2, dut_i.u_core.l0vpns[31][2]);
    chk("l0h[31][3]", dut_g.l0h_31_3, dut_i.u_core.l0h[31][3]);
    chk("l0asids[31][3]", dut_g.l0asids_31_3, dut_i.u_core.l0asids[31][3]);
    chk("l0vmids[31][3]", dut_g.l0vmids_31_3, dut_i.u_core.l0vmids[31][3]);
    chk("l0vpns[31][3]", dut_g.l0vpns_31_3, dut_i.u_core.l0vpns[31][3]);
    chk("l0h[32][0]", dut_g.l0h_32_0, dut_i.u_core.l0h[32][0]);
    chk("l0asids[32][0]", dut_g.l0asids_32_0, dut_i.u_core.l0asids[32][0]);
    chk("l0vmids[32][0]", dut_g.l0vmids_32_0, dut_i.u_core.l0vmids[32][0]);
    chk("l0vpns[32][0]", dut_g.l0vpns_32_0, dut_i.u_core.l0vpns[32][0]);
    chk("l0h[32][1]", dut_g.l0h_32_1, dut_i.u_core.l0h[32][1]);
    chk("l0asids[32][1]", dut_g.l0asids_32_1, dut_i.u_core.l0asids[32][1]);
    chk("l0vmids[32][1]", dut_g.l0vmids_32_1, dut_i.u_core.l0vmids[32][1]);
    chk("l0vpns[32][1]", dut_g.l0vpns_32_1, dut_i.u_core.l0vpns[32][1]);
    chk("l0h[32][2]", dut_g.l0h_32_2, dut_i.u_core.l0h[32][2]);
    chk("l0asids[32][2]", dut_g.l0asids_32_2, dut_i.u_core.l0asids[32][2]);
    chk("l0vmids[32][2]", dut_g.l0vmids_32_2, dut_i.u_core.l0vmids[32][2]);
    chk("l0vpns[32][2]", dut_g.l0vpns_32_2, dut_i.u_core.l0vpns[32][2]);
    chk("l0h[32][3]", dut_g.l0h_32_3, dut_i.u_core.l0h[32][3]);
    chk("l0asids[32][3]", dut_g.l0asids_32_3, dut_i.u_core.l0asids[32][3]);
    chk("l0vmids[32][3]", dut_g.l0vmids_32_3, dut_i.u_core.l0vmids[32][3]);
    chk("l0vpns[32][3]", dut_g.l0vpns_32_3, dut_i.u_core.l0vpns[32][3]);
    chk("l0h[33][0]", dut_g.l0h_33_0, dut_i.u_core.l0h[33][0]);
    chk("l0asids[33][0]", dut_g.l0asids_33_0, dut_i.u_core.l0asids[33][0]);
    chk("l0vmids[33][0]", dut_g.l0vmids_33_0, dut_i.u_core.l0vmids[33][0]);
    chk("l0vpns[33][0]", dut_g.l0vpns_33_0, dut_i.u_core.l0vpns[33][0]);
    chk("l0h[33][1]", dut_g.l0h_33_1, dut_i.u_core.l0h[33][1]);
    chk("l0asids[33][1]", dut_g.l0asids_33_1, dut_i.u_core.l0asids[33][1]);
    chk("l0vmids[33][1]", dut_g.l0vmids_33_1, dut_i.u_core.l0vmids[33][1]);
    chk("l0vpns[33][1]", dut_g.l0vpns_33_1, dut_i.u_core.l0vpns[33][1]);
    chk("l0h[33][2]", dut_g.l0h_33_2, dut_i.u_core.l0h[33][2]);
    chk("l0asids[33][2]", dut_g.l0asids_33_2, dut_i.u_core.l0asids[33][2]);
    chk("l0vmids[33][2]", dut_g.l0vmids_33_2, dut_i.u_core.l0vmids[33][2]);
    chk("l0vpns[33][2]", dut_g.l0vpns_33_2, dut_i.u_core.l0vpns[33][2]);
    chk("l0h[33][3]", dut_g.l0h_33_3, dut_i.u_core.l0h[33][3]);
    chk("l0asids[33][3]", dut_g.l0asids_33_3, dut_i.u_core.l0asids[33][3]);
    chk("l0vmids[33][3]", dut_g.l0vmids_33_3, dut_i.u_core.l0vmids[33][3]);
    chk("l0vpns[33][3]", dut_g.l0vpns_33_3, dut_i.u_core.l0vpns[33][3]);
    chk("l0h[34][0]", dut_g.l0h_34_0, dut_i.u_core.l0h[34][0]);
    chk("l0asids[34][0]", dut_g.l0asids_34_0, dut_i.u_core.l0asids[34][0]);
    chk("l0vmids[34][0]", dut_g.l0vmids_34_0, dut_i.u_core.l0vmids[34][0]);
    chk("l0vpns[34][0]", dut_g.l0vpns_34_0, dut_i.u_core.l0vpns[34][0]);
    chk("l0h[34][1]", dut_g.l0h_34_1, dut_i.u_core.l0h[34][1]);
    chk("l0asids[34][1]", dut_g.l0asids_34_1, dut_i.u_core.l0asids[34][1]);
    chk("l0vmids[34][1]", dut_g.l0vmids_34_1, dut_i.u_core.l0vmids[34][1]);
    chk("l0vpns[34][1]", dut_g.l0vpns_34_1, dut_i.u_core.l0vpns[34][1]);
    chk("l0h[34][2]", dut_g.l0h_34_2, dut_i.u_core.l0h[34][2]);
    chk("l0asids[34][2]", dut_g.l0asids_34_2, dut_i.u_core.l0asids[34][2]);
    chk("l0vmids[34][2]", dut_g.l0vmids_34_2, dut_i.u_core.l0vmids[34][2]);
    chk("l0vpns[34][2]", dut_g.l0vpns_34_2, dut_i.u_core.l0vpns[34][2]);
    chk("l0h[34][3]", dut_g.l0h_34_3, dut_i.u_core.l0h[34][3]);
    chk("l0asids[34][3]", dut_g.l0asids_34_3, dut_i.u_core.l0asids[34][3]);
    chk("l0vmids[34][3]", dut_g.l0vmids_34_3, dut_i.u_core.l0vmids[34][3]);
    chk("l0vpns[34][3]", dut_g.l0vpns_34_3, dut_i.u_core.l0vpns[34][3]);
    chk("l0h[35][0]", dut_g.l0h_35_0, dut_i.u_core.l0h[35][0]);
    chk("l0asids[35][0]", dut_g.l0asids_35_0, dut_i.u_core.l0asids[35][0]);
    chk("l0vmids[35][0]", dut_g.l0vmids_35_0, dut_i.u_core.l0vmids[35][0]);
    chk("l0vpns[35][0]", dut_g.l0vpns_35_0, dut_i.u_core.l0vpns[35][0]);
    chk("l0h[35][1]", dut_g.l0h_35_1, dut_i.u_core.l0h[35][1]);
    chk("l0asids[35][1]", dut_g.l0asids_35_1, dut_i.u_core.l0asids[35][1]);
    chk("l0vmids[35][1]", dut_g.l0vmids_35_1, dut_i.u_core.l0vmids[35][1]);
    chk("l0vpns[35][1]", dut_g.l0vpns_35_1, dut_i.u_core.l0vpns[35][1]);
    chk("l0h[35][2]", dut_g.l0h_35_2, dut_i.u_core.l0h[35][2]);
    chk("l0asids[35][2]", dut_g.l0asids_35_2, dut_i.u_core.l0asids[35][2]);
    chk("l0vmids[35][2]", dut_g.l0vmids_35_2, dut_i.u_core.l0vmids[35][2]);
    chk("l0vpns[35][2]", dut_g.l0vpns_35_2, dut_i.u_core.l0vpns[35][2]);
    chk("l0h[35][3]", dut_g.l0h_35_3, dut_i.u_core.l0h[35][3]);
    chk("l0asids[35][3]", dut_g.l0asids_35_3, dut_i.u_core.l0asids[35][3]);
    chk("l0vmids[35][3]", dut_g.l0vmids_35_3, dut_i.u_core.l0vmids[35][3]);
    chk("l0vpns[35][3]", dut_g.l0vpns_35_3, dut_i.u_core.l0vpns[35][3]);
    chk("l0h[36][0]", dut_g.l0h_36_0, dut_i.u_core.l0h[36][0]);
    chk("l0asids[36][0]", dut_g.l0asids_36_0, dut_i.u_core.l0asids[36][0]);
    chk("l0vmids[36][0]", dut_g.l0vmids_36_0, dut_i.u_core.l0vmids[36][0]);
    chk("l0vpns[36][0]", dut_g.l0vpns_36_0, dut_i.u_core.l0vpns[36][0]);
    chk("l0h[36][1]", dut_g.l0h_36_1, dut_i.u_core.l0h[36][1]);
    chk("l0asids[36][1]", dut_g.l0asids_36_1, dut_i.u_core.l0asids[36][1]);
    chk("l0vmids[36][1]", dut_g.l0vmids_36_1, dut_i.u_core.l0vmids[36][1]);
    chk("l0vpns[36][1]", dut_g.l0vpns_36_1, dut_i.u_core.l0vpns[36][1]);
    chk("l0h[36][2]", dut_g.l0h_36_2, dut_i.u_core.l0h[36][2]);
    chk("l0asids[36][2]", dut_g.l0asids_36_2, dut_i.u_core.l0asids[36][2]);
    chk("l0vmids[36][2]", dut_g.l0vmids_36_2, dut_i.u_core.l0vmids[36][2]);
    chk("l0vpns[36][2]", dut_g.l0vpns_36_2, dut_i.u_core.l0vpns[36][2]);
    chk("l0h[36][3]", dut_g.l0h_36_3, dut_i.u_core.l0h[36][3]);
    chk("l0asids[36][3]", dut_g.l0asids_36_3, dut_i.u_core.l0asids[36][3]);
    chk("l0vmids[36][3]", dut_g.l0vmids_36_3, dut_i.u_core.l0vmids[36][3]);
    chk("l0vpns[36][3]", dut_g.l0vpns_36_3, dut_i.u_core.l0vpns[36][3]);
    chk("l0h[37][0]", dut_g.l0h_37_0, dut_i.u_core.l0h[37][0]);
    chk("l0asids[37][0]", dut_g.l0asids_37_0, dut_i.u_core.l0asids[37][0]);
    chk("l0vmids[37][0]", dut_g.l0vmids_37_0, dut_i.u_core.l0vmids[37][0]);
    chk("l0vpns[37][0]", dut_g.l0vpns_37_0, dut_i.u_core.l0vpns[37][0]);
    chk("l0h[37][1]", dut_g.l0h_37_1, dut_i.u_core.l0h[37][1]);
    chk("l0asids[37][1]", dut_g.l0asids_37_1, dut_i.u_core.l0asids[37][1]);
    chk("l0vmids[37][1]", dut_g.l0vmids_37_1, dut_i.u_core.l0vmids[37][1]);
    chk("l0vpns[37][1]", dut_g.l0vpns_37_1, dut_i.u_core.l0vpns[37][1]);
    chk("l0h[37][2]", dut_g.l0h_37_2, dut_i.u_core.l0h[37][2]);
    chk("l0asids[37][2]", dut_g.l0asids_37_2, dut_i.u_core.l0asids[37][2]);
    chk("l0vmids[37][2]", dut_g.l0vmids_37_2, dut_i.u_core.l0vmids[37][2]);
    chk("l0vpns[37][2]", dut_g.l0vpns_37_2, dut_i.u_core.l0vpns[37][2]);
    chk("l0h[37][3]", dut_g.l0h_37_3, dut_i.u_core.l0h[37][3]);
    chk("l0asids[37][3]", dut_g.l0asids_37_3, dut_i.u_core.l0asids[37][3]);
    chk("l0vmids[37][3]", dut_g.l0vmids_37_3, dut_i.u_core.l0vmids[37][3]);
    chk("l0vpns[37][3]", dut_g.l0vpns_37_3, dut_i.u_core.l0vpns[37][3]);
    chk("l0h[38][0]", dut_g.l0h_38_0, dut_i.u_core.l0h[38][0]);
    chk("l0asids[38][0]", dut_g.l0asids_38_0, dut_i.u_core.l0asids[38][0]);
    chk("l0vmids[38][0]", dut_g.l0vmids_38_0, dut_i.u_core.l0vmids[38][0]);
    chk("l0vpns[38][0]", dut_g.l0vpns_38_0, dut_i.u_core.l0vpns[38][0]);
    chk("l0h[38][1]", dut_g.l0h_38_1, dut_i.u_core.l0h[38][1]);
    chk("l0asids[38][1]", dut_g.l0asids_38_1, dut_i.u_core.l0asids[38][1]);
    chk("l0vmids[38][1]", dut_g.l0vmids_38_1, dut_i.u_core.l0vmids[38][1]);
    chk("l0vpns[38][1]", dut_g.l0vpns_38_1, dut_i.u_core.l0vpns[38][1]);
    chk("l0h[38][2]", dut_g.l0h_38_2, dut_i.u_core.l0h[38][2]);
    chk("l0asids[38][2]", dut_g.l0asids_38_2, dut_i.u_core.l0asids[38][2]);
    chk("l0vmids[38][2]", dut_g.l0vmids_38_2, dut_i.u_core.l0vmids[38][2]);
    chk("l0vpns[38][2]", dut_g.l0vpns_38_2, dut_i.u_core.l0vpns[38][2]);
    chk("l0h[38][3]", dut_g.l0h_38_3, dut_i.u_core.l0h[38][3]);
    chk("l0asids[38][3]", dut_g.l0asids_38_3, dut_i.u_core.l0asids[38][3]);
    chk("l0vmids[38][3]", dut_g.l0vmids_38_3, dut_i.u_core.l0vmids[38][3]);
    chk("l0vpns[38][3]", dut_g.l0vpns_38_3, dut_i.u_core.l0vpns[38][3]);
    chk("l0h[39][0]", dut_g.l0h_39_0, dut_i.u_core.l0h[39][0]);
    chk("l0asids[39][0]", dut_g.l0asids_39_0, dut_i.u_core.l0asids[39][0]);
    chk("l0vmids[39][0]", dut_g.l0vmids_39_0, dut_i.u_core.l0vmids[39][0]);
    chk("l0vpns[39][0]", dut_g.l0vpns_39_0, dut_i.u_core.l0vpns[39][0]);
    chk("l0h[39][1]", dut_g.l0h_39_1, dut_i.u_core.l0h[39][1]);
    chk("l0asids[39][1]", dut_g.l0asids_39_1, dut_i.u_core.l0asids[39][1]);
    chk("l0vmids[39][1]", dut_g.l0vmids_39_1, dut_i.u_core.l0vmids[39][1]);
    chk("l0vpns[39][1]", dut_g.l0vpns_39_1, dut_i.u_core.l0vpns[39][1]);
    chk("l0h[39][2]", dut_g.l0h_39_2, dut_i.u_core.l0h[39][2]);
    chk("l0asids[39][2]", dut_g.l0asids_39_2, dut_i.u_core.l0asids[39][2]);
    chk("l0vmids[39][2]", dut_g.l0vmids_39_2, dut_i.u_core.l0vmids[39][2]);
    chk("l0vpns[39][2]", dut_g.l0vpns_39_2, dut_i.u_core.l0vpns[39][2]);
    chk("l0h[39][3]", dut_g.l0h_39_3, dut_i.u_core.l0h[39][3]);
    chk("l0asids[39][3]", dut_g.l0asids_39_3, dut_i.u_core.l0asids[39][3]);
    chk("l0vmids[39][3]", dut_g.l0vmids_39_3, dut_i.u_core.l0vmids[39][3]);
    chk("l0vpns[39][3]", dut_g.l0vpns_39_3, dut_i.u_core.l0vpns[39][3]);
    chk("l0h[40][0]", dut_g.l0h_40_0, dut_i.u_core.l0h[40][0]);
    chk("l0asids[40][0]", dut_g.l0asids_40_0, dut_i.u_core.l0asids[40][0]);
    chk("l0vmids[40][0]", dut_g.l0vmids_40_0, dut_i.u_core.l0vmids[40][0]);
    chk("l0vpns[40][0]", dut_g.l0vpns_40_0, dut_i.u_core.l0vpns[40][0]);
    chk("l0h[40][1]", dut_g.l0h_40_1, dut_i.u_core.l0h[40][1]);
    chk("l0asids[40][1]", dut_g.l0asids_40_1, dut_i.u_core.l0asids[40][1]);
    chk("l0vmids[40][1]", dut_g.l0vmids_40_1, dut_i.u_core.l0vmids[40][1]);
    chk("l0vpns[40][1]", dut_g.l0vpns_40_1, dut_i.u_core.l0vpns[40][1]);
    chk("l0h[40][2]", dut_g.l0h_40_2, dut_i.u_core.l0h[40][2]);
    chk("l0asids[40][2]", dut_g.l0asids_40_2, dut_i.u_core.l0asids[40][2]);
    chk("l0vmids[40][2]", dut_g.l0vmids_40_2, dut_i.u_core.l0vmids[40][2]);
    chk("l0vpns[40][2]", dut_g.l0vpns_40_2, dut_i.u_core.l0vpns[40][2]);
    chk("l0h[40][3]", dut_g.l0h_40_3, dut_i.u_core.l0h[40][3]);
    chk("l0asids[40][3]", dut_g.l0asids_40_3, dut_i.u_core.l0asids[40][3]);
    chk("l0vmids[40][3]", dut_g.l0vmids_40_3, dut_i.u_core.l0vmids[40][3]);
    chk("l0vpns[40][3]", dut_g.l0vpns_40_3, dut_i.u_core.l0vpns[40][3]);
    chk("l0h[41][0]", dut_g.l0h_41_0, dut_i.u_core.l0h[41][0]);
    chk("l0asids[41][0]", dut_g.l0asids_41_0, dut_i.u_core.l0asids[41][0]);
    chk("l0vmids[41][0]", dut_g.l0vmids_41_0, dut_i.u_core.l0vmids[41][0]);
    chk("l0vpns[41][0]", dut_g.l0vpns_41_0, dut_i.u_core.l0vpns[41][0]);
    chk("l0h[41][1]", dut_g.l0h_41_1, dut_i.u_core.l0h[41][1]);
    chk("l0asids[41][1]", dut_g.l0asids_41_1, dut_i.u_core.l0asids[41][1]);
    chk("l0vmids[41][1]", dut_g.l0vmids_41_1, dut_i.u_core.l0vmids[41][1]);
    chk("l0vpns[41][1]", dut_g.l0vpns_41_1, dut_i.u_core.l0vpns[41][1]);
    chk("l0h[41][2]", dut_g.l0h_41_2, dut_i.u_core.l0h[41][2]);
    chk("l0asids[41][2]", dut_g.l0asids_41_2, dut_i.u_core.l0asids[41][2]);
    chk("l0vmids[41][2]", dut_g.l0vmids_41_2, dut_i.u_core.l0vmids[41][2]);
    chk("l0vpns[41][2]", dut_g.l0vpns_41_2, dut_i.u_core.l0vpns[41][2]);
    chk("l0h[41][3]", dut_g.l0h_41_3, dut_i.u_core.l0h[41][3]);
    chk("l0asids[41][3]", dut_g.l0asids_41_3, dut_i.u_core.l0asids[41][3]);
    chk("l0vmids[41][3]", dut_g.l0vmids_41_3, dut_i.u_core.l0vmids[41][3]);
    chk("l0vpns[41][3]", dut_g.l0vpns_41_3, dut_i.u_core.l0vpns[41][3]);
    chk("l0h[42][0]", dut_g.l0h_42_0, dut_i.u_core.l0h[42][0]);
    chk("l0asids[42][0]", dut_g.l0asids_42_0, dut_i.u_core.l0asids[42][0]);
    chk("l0vmids[42][0]", dut_g.l0vmids_42_0, dut_i.u_core.l0vmids[42][0]);
    chk("l0vpns[42][0]", dut_g.l0vpns_42_0, dut_i.u_core.l0vpns[42][0]);
    chk("l0h[42][1]", dut_g.l0h_42_1, dut_i.u_core.l0h[42][1]);
    chk("l0asids[42][1]", dut_g.l0asids_42_1, dut_i.u_core.l0asids[42][1]);
    chk("l0vmids[42][1]", dut_g.l0vmids_42_1, dut_i.u_core.l0vmids[42][1]);
    chk("l0vpns[42][1]", dut_g.l0vpns_42_1, dut_i.u_core.l0vpns[42][1]);
    chk("l0h[42][2]", dut_g.l0h_42_2, dut_i.u_core.l0h[42][2]);
    chk("l0asids[42][2]", dut_g.l0asids_42_2, dut_i.u_core.l0asids[42][2]);
    chk("l0vmids[42][2]", dut_g.l0vmids_42_2, dut_i.u_core.l0vmids[42][2]);
    chk("l0vpns[42][2]", dut_g.l0vpns_42_2, dut_i.u_core.l0vpns[42][2]);
    chk("l0h[42][3]", dut_g.l0h_42_3, dut_i.u_core.l0h[42][3]);
    chk("l0asids[42][3]", dut_g.l0asids_42_3, dut_i.u_core.l0asids[42][3]);
    chk("l0vmids[42][3]", dut_g.l0vmids_42_3, dut_i.u_core.l0vmids[42][3]);
    chk("l0vpns[42][3]", dut_g.l0vpns_42_3, dut_i.u_core.l0vpns[42][3]);
    chk("l0h[43][0]", dut_g.l0h_43_0, dut_i.u_core.l0h[43][0]);
    chk("l0asids[43][0]", dut_g.l0asids_43_0, dut_i.u_core.l0asids[43][0]);
    chk("l0vmids[43][0]", dut_g.l0vmids_43_0, dut_i.u_core.l0vmids[43][0]);
    chk("l0vpns[43][0]", dut_g.l0vpns_43_0, dut_i.u_core.l0vpns[43][0]);
    chk("l0h[43][1]", dut_g.l0h_43_1, dut_i.u_core.l0h[43][1]);
    chk("l0asids[43][1]", dut_g.l0asids_43_1, dut_i.u_core.l0asids[43][1]);
    chk("l0vmids[43][1]", dut_g.l0vmids_43_1, dut_i.u_core.l0vmids[43][1]);
    chk("l0vpns[43][1]", dut_g.l0vpns_43_1, dut_i.u_core.l0vpns[43][1]);
    chk("l0h[43][2]", dut_g.l0h_43_2, dut_i.u_core.l0h[43][2]);
    chk("l0asids[43][2]", dut_g.l0asids_43_2, dut_i.u_core.l0asids[43][2]);
    chk("l0vmids[43][2]", dut_g.l0vmids_43_2, dut_i.u_core.l0vmids[43][2]);
    chk("l0vpns[43][2]", dut_g.l0vpns_43_2, dut_i.u_core.l0vpns[43][2]);
    chk("l0h[43][3]", dut_g.l0h_43_3, dut_i.u_core.l0h[43][3]);
    chk("l0asids[43][3]", dut_g.l0asids_43_3, dut_i.u_core.l0asids[43][3]);
    chk("l0vmids[43][3]", dut_g.l0vmids_43_3, dut_i.u_core.l0vmids[43][3]);
    chk("l0vpns[43][3]", dut_g.l0vpns_43_3, dut_i.u_core.l0vpns[43][3]);
    chk("l0h[44][0]", dut_g.l0h_44_0, dut_i.u_core.l0h[44][0]);
    chk("l0asids[44][0]", dut_g.l0asids_44_0, dut_i.u_core.l0asids[44][0]);
    chk("l0vmids[44][0]", dut_g.l0vmids_44_0, dut_i.u_core.l0vmids[44][0]);
    chk("l0vpns[44][0]", dut_g.l0vpns_44_0, dut_i.u_core.l0vpns[44][0]);
    chk("l0h[44][1]", dut_g.l0h_44_1, dut_i.u_core.l0h[44][1]);
    chk("l0asids[44][1]", dut_g.l0asids_44_1, dut_i.u_core.l0asids[44][1]);
    chk("l0vmids[44][1]", dut_g.l0vmids_44_1, dut_i.u_core.l0vmids[44][1]);
    chk("l0vpns[44][1]", dut_g.l0vpns_44_1, dut_i.u_core.l0vpns[44][1]);
    chk("l0h[44][2]", dut_g.l0h_44_2, dut_i.u_core.l0h[44][2]);
    chk("l0asids[44][2]", dut_g.l0asids_44_2, dut_i.u_core.l0asids[44][2]);
    chk("l0vmids[44][2]", dut_g.l0vmids_44_2, dut_i.u_core.l0vmids[44][2]);
    chk("l0vpns[44][2]", dut_g.l0vpns_44_2, dut_i.u_core.l0vpns[44][2]);
    chk("l0h[44][3]", dut_g.l0h_44_3, dut_i.u_core.l0h[44][3]);
    chk("l0asids[44][3]", dut_g.l0asids_44_3, dut_i.u_core.l0asids[44][3]);
    chk("l0vmids[44][3]", dut_g.l0vmids_44_3, dut_i.u_core.l0vmids[44][3]);
    chk("l0vpns[44][3]", dut_g.l0vpns_44_3, dut_i.u_core.l0vpns[44][3]);
    chk("l0h[45][0]", dut_g.l0h_45_0, dut_i.u_core.l0h[45][0]);
    chk("l0asids[45][0]", dut_g.l0asids_45_0, dut_i.u_core.l0asids[45][0]);
    chk("l0vmids[45][0]", dut_g.l0vmids_45_0, dut_i.u_core.l0vmids[45][0]);
    chk("l0vpns[45][0]", dut_g.l0vpns_45_0, dut_i.u_core.l0vpns[45][0]);
    chk("l0h[45][1]", dut_g.l0h_45_1, dut_i.u_core.l0h[45][1]);
    chk("l0asids[45][1]", dut_g.l0asids_45_1, dut_i.u_core.l0asids[45][1]);
    chk("l0vmids[45][1]", dut_g.l0vmids_45_1, dut_i.u_core.l0vmids[45][1]);
    chk("l0vpns[45][1]", dut_g.l0vpns_45_1, dut_i.u_core.l0vpns[45][1]);
    chk("l0h[45][2]", dut_g.l0h_45_2, dut_i.u_core.l0h[45][2]);
    chk("l0asids[45][2]", dut_g.l0asids_45_2, dut_i.u_core.l0asids[45][2]);
    chk("l0vmids[45][2]", dut_g.l0vmids_45_2, dut_i.u_core.l0vmids[45][2]);
    chk("l0vpns[45][2]", dut_g.l0vpns_45_2, dut_i.u_core.l0vpns[45][2]);
    chk("l0h[45][3]", dut_g.l0h_45_3, dut_i.u_core.l0h[45][3]);
    chk("l0asids[45][3]", dut_g.l0asids_45_3, dut_i.u_core.l0asids[45][3]);
    chk("l0vmids[45][3]", dut_g.l0vmids_45_3, dut_i.u_core.l0vmids[45][3]);
    chk("l0vpns[45][3]", dut_g.l0vpns_45_3, dut_i.u_core.l0vpns[45][3]);
    chk("l0h[46][0]", dut_g.l0h_46_0, dut_i.u_core.l0h[46][0]);
    chk("l0asids[46][0]", dut_g.l0asids_46_0, dut_i.u_core.l0asids[46][0]);
    chk("l0vmids[46][0]", dut_g.l0vmids_46_0, dut_i.u_core.l0vmids[46][0]);
    chk("l0vpns[46][0]", dut_g.l0vpns_46_0, dut_i.u_core.l0vpns[46][0]);
    chk("l0h[46][1]", dut_g.l0h_46_1, dut_i.u_core.l0h[46][1]);
    chk("l0asids[46][1]", dut_g.l0asids_46_1, dut_i.u_core.l0asids[46][1]);
    chk("l0vmids[46][1]", dut_g.l0vmids_46_1, dut_i.u_core.l0vmids[46][1]);
    chk("l0vpns[46][1]", dut_g.l0vpns_46_1, dut_i.u_core.l0vpns[46][1]);
    chk("l0h[46][2]", dut_g.l0h_46_2, dut_i.u_core.l0h[46][2]);
    chk("l0asids[46][2]", dut_g.l0asids_46_2, dut_i.u_core.l0asids[46][2]);
    chk("l0vmids[46][2]", dut_g.l0vmids_46_2, dut_i.u_core.l0vmids[46][2]);
    chk("l0vpns[46][2]", dut_g.l0vpns_46_2, dut_i.u_core.l0vpns[46][2]);
    chk("l0h[46][3]", dut_g.l0h_46_3, dut_i.u_core.l0h[46][3]);
    chk("l0asids[46][3]", dut_g.l0asids_46_3, dut_i.u_core.l0asids[46][3]);
    chk("l0vmids[46][3]", dut_g.l0vmids_46_3, dut_i.u_core.l0vmids[46][3]);
    chk("l0vpns[46][3]", dut_g.l0vpns_46_3, dut_i.u_core.l0vpns[46][3]);
    chk("l0h[47][0]", dut_g.l0h_47_0, dut_i.u_core.l0h[47][0]);
    chk("l0asids[47][0]", dut_g.l0asids_47_0, dut_i.u_core.l0asids[47][0]);
    chk("l0vmids[47][0]", dut_g.l0vmids_47_0, dut_i.u_core.l0vmids[47][0]);
    chk("l0vpns[47][0]", dut_g.l0vpns_47_0, dut_i.u_core.l0vpns[47][0]);
    chk("l0h[47][1]", dut_g.l0h_47_1, dut_i.u_core.l0h[47][1]);
    chk("l0asids[47][1]", dut_g.l0asids_47_1, dut_i.u_core.l0asids[47][1]);
    chk("l0vmids[47][1]", dut_g.l0vmids_47_1, dut_i.u_core.l0vmids[47][1]);
    chk("l0vpns[47][1]", dut_g.l0vpns_47_1, dut_i.u_core.l0vpns[47][1]);
    chk("l0h[47][2]", dut_g.l0h_47_2, dut_i.u_core.l0h[47][2]);
    chk("l0asids[47][2]", dut_g.l0asids_47_2, dut_i.u_core.l0asids[47][2]);
    chk("l0vmids[47][2]", dut_g.l0vmids_47_2, dut_i.u_core.l0vmids[47][2]);
    chk("l0vpns[47][2]", dut_g.l0vpns_47_2, dut_i.u_core.l0vpns[47][2]);
    chk("l0h[47][3]", dut_g.l0h_47_3, dut_i.u_core.l0h[47][3]);
    chk("l0asids[47][3]", dut_g.l0asids_47_3, dut_i.u_core.l0asids[47][3]);
    chk("l0vmids[47][3]", dut_g.l0vmids_47_3, dut_i.u_core.l0vmids[47][3]);
    chk("l0vpns[47][3]", dut_g.l0vpns_47_3, dut_i.u_core.l0vpns[47][3]);
    chk("l0h[48][0]", dut_g.l0h_48_0, dut_i.u_core.l0h[48][0]);
    chk("l0asids[48][0]", dut_g.l0asids_48_0, dut_i.u_core.l0asids[48][0]);
    chk("l0vmids[48][0]", dut_g.l0vmids_48_0, dut_i.u_core.l0vmids[48][0]);
    chk("l0vpns[48][0]", dut_g.l0vpns_48_0, dut_i.u_core.l0vpns[48][0]);
    chk("l0h[48][1]", dut_g.l0h_48_1, dut_i.u_core.l0h[48][1]);
    chk("l0asids[48][1]", dut_g.l0asids_48_1, dut_i.u_core.l0asids[48][1]);
    chk("l0vmids[48][1]", dut_g.l0vmids_48_1, dut_i.u_core.l0vmids[48][1]);
    chk("l0vpns[48][1]", dut_g.l0vpns_48_1, dut_i.u_core.l0vpns[48][1]);
    chk("l0h[48][2]", dut_g.l0h_48_2, dut_i.u_core.l0h[48][2]);
    chk("l0asids[48][2]", dut_g.l0asids_48_2, dut_i.u_core.l0asids[48][2]);
    chk("l0vmids[48][2]", dut_g.l0vmids_48_2, dut_i.u_core.l0vmids[48][2]);
    chk("l0vpns[48][2]", dut_g.l0vpns_48_2, dut_i.u_core.l0vpns[48][2]);
    chk("l0h[48][3]", dut_g.l0h_48_3, dut_i.u_core.l0h[48][3]);
    chk("l0asids[48][3]", dut_g.l0asids_48_3, dut_i.u_core.l0asids[48][3]);
    chk("l0vmids[48][3]", dut_g.l0vmids_48_3, dut_i.u_core.l0vmids[48][3]);
    chk("l0vpns[48][3]", dut_g.l0vpns_48_3, dut_i.u_core.l0vpns[48][3]);
    chk("l0h[49][0]", dut_g.l0h_49_0, dut_i.u_core.l0h[49][0]);
    chk("l0asids[49][0]", dut_g.l0asids_49_0, dut_i.u_core.l0asids[49][0]);
    chk("l0vmids[49][0]", dut_g.l0vmids_49_0, dut_i.u_core.l0vmids[49][0]);
    chk("l0vpns[49][0]", dut_g.l0vpns_49_0, dut_i.u_core.l0vpns[49][0]);
    chk("l0h[49][1]", dut_g.l0h_49_1, dut_i.u_core.l0h[49][1]);
    chk("l0asids[49][1]", dut_g.l0asids_49_1, dut_i.u_core.l0asids[49][1]);
    chk("l0vmids[49][1]", dut_g.l0vmids_49_1, dut_i.u_core.l0vmids[49][1]);
    chk("l0vpns[49][1]", dut_g.l0vpns_49_1, dut_i.u_core.l0vpns[49][1]);
    chk("l0h[49][2]", dut_g.l0h_49_2, dut_i.u_core.l0h[49][2]);
    chk("l0asids[49][2]", dut_g.l0asids_49_2, dut_i.u_core.l0asids[49][2]);
    chk("l0vmids[49][2]", dut_g.l0vmids_49_2, dut_i.u_core.l0vmids[49][2]);
    chk("l0vpns[49][2]", dut_g.l0vpns_49_2, dut_i.u_core.l0vpns[49][2]);
    chk("l0h[49][3]", dut_g.l0h_49_3, dut_i.u_core.l0h[49][3]);
    chk("l0asids[49][3]", dut_g.l0asids_49_3, dut_i.u_core.l0asids[49][3]);
    chk("l0vmids[49][3]", dut_g.l0vmids_49_3, dut_i.u_core.l0vmids[49][3]);
    chk("l0vpns[49][3]", dut_g.l0vpns_49_3, dut_i.u_core.l0vpns[49][3]);
    chk("l0h[50][0]", dut_g.l0h_50_0, dut_i.u_core.l0h[50][0]);
    chk("l0asids[50][0]", dut_g.l0asids_50_0, dut_i.u_core.l0asids[50][0]);
    chk("l0vmids[50][0]", dut_g.l0vmids_50_0, dut_i.u_core.l0vmids[50][0]);
    chk("l0vpns[50][0]", dut_g.l0vpns_50_0, dut_i.u_core.l0vpns[50][0]);
    chk("l0h[50][1]", dut_g.l0h_50_1, dut_i.u_core.l0h[50][1]);
    chk("l0asids[50][1]", dut_g.l0asids_50_1, dut_i.u_core.l0asids[50][1]);
    chk("l0vmids[50][1]", dut_g.l0vmids_50_1, dut_i.u_core.l0vmids[50][1]);
    chk("l0vpns[50][1]", dut_g.l0vpns_50_1, dut_i.u_core.l0vpns[50][1]);
    chk("l0h[50][2]", dut_g.l0h_50_2, dut_i.u_core.l0h[50][2]);
    chk("l0asids[50][2]", dut_g.l0asids_50_2, dut_i.u_core.l0asids[50][2]);
    chk("l0vmids[50][2]", dut_g.l0vmids_50_2, dut_i.u_core.l0vmids[50][2]);
    chk("l0vpns[50][2]", dut_g.l0vpns_50_2, dut_i.u_core.l0vpns[50][2]);
    chk("l0h[50][3]", dut_g.l0h_50_3, dut_i.u_core.l0h[50][3]);
    chk("l0asids[50][3]", dut_g.l0asids_50_3, dut_i.u_core.l0asids[50][3]);
    chk("l0vmids[50][3]", dut_g.l0vmids_50_3, dut_i.u_core.l0vmids[50][3]);
    chk("l0vpns[50][3]", dut_g.l0vpns_50_3, dut_i.u_core.l0vpns[50][3]);
    chk("l0h[51][0]", dut_g.l0h_51_0, dut_i.u_core.l0h[51][0]);
    chk("l0asids[51][0]", dut_g.l0asids_51_0, dut_i.u_core.l0asids[51][0]);
    chk("l0vmids[51][0]", dut_g.l0vmids_51_0, dut_i.u_core.l0vmids[51][0]);
    chk("l0vpns[51][0]", dut_g.l0vpns_51_0, dut_i.u_core.l0vpns[51][0]);
    chk("l0h[51][1]", dut_g.l0h_51_1, dut_i.u_core.l0h[51][1]);
    chk("l0asids[51][1]", dut_g.l0asids_51_1, dut_i.u_core.l0asids[51][1]);
    chk("l0vmids[51][1]", dut_g.l0vmids_51_1, dut_i.u_core.l0vmids[51][1]);
    chk("l0vpns[51][1]", dut_g.l0vpns_51_1, dut_i.u_core.l0vpns[51][1]);
    chk("l0h[51][2]", dut_g.l0h_51_2, dut_i.u_core.l0h[51][2]);
    chk("l0asids[51][2]", dut_g.l0asids_51_2, dut_i.u_core.l0asids[51][2]);
    chk("l0vmids[51][2]", dut_g.l0vmids_51_2, dut_i.u_core.l0vmids[51][2]);
    chk("l0vpns[51][2]", dut_g.l0vpns_51_2, dut_i.u_core.l0vpns[51][2]);
    chk("l0h[51][3]", dut_g.l0h_51_3, dut_i.u_core.l0h[51][3]);
    chk("l0asids[51][3]", dut_g.l0asids_51_3, dut_i.u_core.l0asids[51][3]);
    chk("l0vmids[51][3]", dut_g.l0vmids_51_3, dut_i.u_core.l0vmids[51][3]);
    chk("l0vpns[51][3]", dut_g.l0vpns_51_3, dut_i.u_core.l0vpns[51][3]);
    chk("l0h[52][0]", dut_g.l0h_52_0, dut_i.u_core.l0h[52][0]);
    chk("l0asids[52][0]", dut_g.l0asids_52_0, dut_i.u_core.l0asids[52][0]);
    chk("l0vmids[52][0]", dut_g.l0vmids_52_0, dut_i.u_core.l0vmids[52][0]);
    chk("l0vpns[52][0]", dut_g.l0vpns_52_0, dut_i.u_core.l0vpns[52][0]);
    chk("l0h[52][1]", dut_g.l0h_52_1, dut_i.u_core.l0h[52][1]);
    chk("l0asids[52][1]", dut_g.l0asids_52_1, dut_i.u_core.l0asids[52][1]);
    chk("l0vmids[52][1]", dut_g.l0vmids_52_1, dut_i.u_core.l0vmids[52][1]);
    chk("l0vpns[52][1]", dut_g.l0vpns_52_1, dut_i.u_core.l0vpns[52][1]);
    chk("l0h[52][2]", dut_g.l0h_52_2, dut_i.u_core.l0h[52][2]);
    chk("l0asids[52][2]", dut_g.l0asids_52_2, dut_i.u_core.l0asids[52][2]);
    chk("l0vmids[52][2]", dut_g.l0vmids_52_2, dut_i.u_core.l0vmids[52][2]);
    chk("l0vpns[52][2]", dut_g.l0vpns_52_2, dut_i.u_core.l0vpns[52][2]);
    chk("l0h[52][3]", dut_g.l0h_52_3, dut_i.u_core.l0h[52][3]);
    chk("l0asids[52][3]", dut_g.l0asids_52_3, dut_i.u_core.l0asids[52][3]);
    chk("l0vmids[52][3]", dut_g.l0vmids_52_3, dut_i.u_core.l0vmids[52][3]);
    chk("l0vpns[52][3]", dut_g.l0vpns_52_3, dut_i.u_core.l0vpns[52][3]);
    chk("l0h[53][0]", dut_g.l0h_53_0, dut_i.u_core.l0h[53][0]);
    chk("l0asids[53][0]", dut_g.l0asids_53_0, dut_i.u_core.l0asids[53][0]);
    chk("l0vmids[53][0]", dut_g.l0vmids_53_0, dut_i.u_core.l0vmids[53][0]);
    chk("l0vpns[53][0]", dut_g.l0vpns_53_0, dut_i.u_core.l0vpns[53][0]);
    chk("l0h[53][1]", dut_g.l0h_53_1, dut_i.u_core.l0h[53][1]);
    chk("l0asids[53][1]", dut_g.l0asids_53_1, dut_i.u_core.l0asids[53][1]);
    chk("l0vmids[53][1]", dut_g.l0vmids_53_1, dut_i.u_core.l0vmids[53][1]);
    chk("l0vpns[53][1]", dut_g.l0vpns_53_1, dut_i.u_core.l0vpns[53][1]);
    chk("l0h[53][2]", dut_g.l0h_53_2, dut_i.u_core.l0h[53][2]);
    chk("l0asids[53][2]", dut_g.l0asids_53_2, dut_i.u_core.l0asids[53][2]);
    chk("l0vmids[53][2]", dut_g.l0vmids_53_2, dut_i.u_core.l0vmids[53][2]);
    chk("l0vpns[53][2]", dut_g.l0vpns_53_2, dut_i.u_core.l0vpns[53][2]);
    chk("l0h[53][3]", dut_g.l0h_53_3, dut_i.u_core.l0h[53][3]);
    chk("l0asids[53][3]", dut_g.l0asids_53_3, dut_i.u_core.l0asids[53][3]);
    chk("l0vmids[53][3]", dut_g.l0vmids_53_3, dut_i.u_core.l0vmids[53][3]);
    chk("l0vpns[53][3]", dut_g.l0vpns_53_3, dut_i.u_core.l0vpns[53][3]);
    chk("l0h[54][0]", dut_g.l0h_54_0, dut_i.u_core.l0h[54][0]);
    chk("l0asids[54][0]", dut_g.l0asids_54_0, dut_i.u_core.l0asids[54][0]);
    chk("l0vmids[54][0]", dut_g.l0vmids_54_0, dut_i.u_core.l0vmids[54][0]);
    chk("l0vpns[54][0]", dut_g.l0vpns_54_0, dut_i.u_core.l0vpns[54][0]);
    chk("l0h[54][1]", dut_g.l0h_54_1, dut_i.u_core.l0h[54][1]);
    chk("l0asids[54][1]", dut_g.l0asids_54_1, dut_i.u_core.l0asids[54][1]);
    chk("l0vmids[54][1]", dut_g.l0vmids_54_1, dut_i.u_core.l0vmids[54][1]);
    chk("l0vpns[54][1]", dut_g.l0vpns_54_1, dut_i.u_core.l0vpns[54][1]);
    chk("l0h[54][2]", dut_g.l0h_54_2, dut_i.u_core.l0h[54][2]);
    chk("l0asids[54][2]", dut_g.l0asids_54_2, dut_i.u_core.l0asids[54][2]);
    chk("l0vmids[54][2]", dut_g.l0vmids_54_2, dut_i.u_core.l0vmids[54][2]);
    chk("l0vpns[54][2]", dut_g.l0vpns_54_2, dut_i.u_core.l0vpns[54][2]);
    chk("l0h[54][3]", dut_g.l0h_54_3, dut_i.u_core.l0h[54][3]);
    chk("l0asids[54][3]", dut_g.l0asids_54_3, dut_i.u_core.l0asids[54][3]);
    chk("l0vmids[54][3]", dut_g.l0vmids_54_3, dut_i.u_core.l0vmids[54][3]);
    chk("l0vpns[54][3]", dut_g.l0vpns_54_3, dut_i.u_core.l0vpns[54][3]);
    chk("l0h[55][0]", dut_g.l0h_55_0, dut_i.u_core.l0h[55][0]);
    chk("l0asids[55][0]", dut_g.l0asids_55_0, dut_i.u_core.l0asids[55][0]);
    chk("l0vmids[55][0]", dut_g.l0vmids_55_0, dut_i.u_core.l0vmids[55][0]);
    chk("l0vpns[55][0]", dut_g.l0vpns_55_0, dut_i.u_core.l0vpns[55][0]);
    chk("l0h[55][1]", dut_g.l0h_55_1, dut_i.u_core.l0h[55][1]);
    chk("l0asids[55][1]", dut_g.l0asids_55_1, dut_i.u_core.l0asids[55][1]);
    chk("l0vmids[55][1]", dut_g.l0vmids_55_1, dut_i.u_core.l0vmids[55][1]);
    chk("l0vpns[55][1]", dut_g.l0vpns_55_1, dut_i.u_core.l0vpns[55][1]);
    chk("l0h[55][2]", dut_g.l0h_55_2, dut_i.u_core.l0h[55][2]);
    chk("l0asids[55][2]", dut_g.l0asids_55_2, dut_i.u_core.l0asids[55][2]);
    chk("l0vmids[55][2]", dut_g.l0vmids_55_2, dut_i.u_core.l0vmids[55][2]);
    chk("l0vpns[55][2]", dut_g.l0vpns_55_2, dut_i.u_core.l0vpns[55][2]);
    chk("l0h[55][3]", dut_g.l0h_55_3, dut_i.u_core.l0h[55][3]);
    chk("l0asids[55][3]", dut_g.l0asids_55_3, dut_i.u_core.l0asids[55][3]);
    chk("l0vmids[55][3]", dut_g.l0vmids_55_3, dut_i.u_core.l0vmids[55][3]);
    chk("l0vpns[55][3]", dut_g.l0vpns_55_3, dut_i.u_core.l0vpns[55][3]);
    chk("l0h[56][0]", dut_g.l0h_56_0, dut_i.u_core.l0h[56][0]);
    chk("l0asids[56][0]", dut_g.l0asids_56_0, dut_i.u_core.l0asids[56][0]);
    chk("l0vmids[56][0]", dut_g.l0vmids_56_0, dut_i.u_core.l0vmids[56][0]);
    chk("l0vpns[56][0]", dut_g.l0vpns_56_0, dut_i.u_core.l0vpns[56][0]);
    chk("l0h[56][1]", dut_g.l0h_56_1, dut_i.u_core.l0h[56][1]);
    chk("l0asids[56][1]", dut_g.l0asids_56_1, dut_i.u_core.l0asids[56][1]);
    chk("l0vmids[56][1]", dut_g.l0vmids_56_1, dut_i.u_core.l0vmids[56][1]);
    chk("l0vpns[56][1]", dut_g.l0vpns_56_1, dut_i.u_core.l0vpns[56][1]);
    chk("l0h[56][2]", dut_g.l0h_56_2, dut_i.u_core.l0h[56][2]);
    chk("l0asids[56][2]", dut_g.l0asids_56_2, dut_i.u_core.l0asids[56][2]);
    chk("l0vmids[56][2]", dut_g.l0vmids_56_2, dut_i.u_core.l0vmids[56][2]);
    chk("l0vpns[56][2]", dut_g.l0vpns_56_2, dut_i.u_core.l0vpns[56][2]);
    chk("l0h[56][3]", dut_g.l0h_56_3, dut_i.u_core.l0h[56][3]);
    chk("l0asids[56][3]", dut_g.l0asids_56_3, dut_i.u_core.l0asids[56][3]);
    chk("l0vmids[56][3]", dut_g.l0vmids_56_3, dut_i.u_core.l0vmids[56][3]);
    chk("l0vpns[56][3]", dut_g.l0vpns_56_3, dut_i.u_core.l0vpns[56][3]);
    chk("l0h[57][0]", dut_g.l0h_57_0, dut_i.u_core.l0h[57][0]);
    chk("l0asids[57][0]", dut_g.l0asids_57_0, dut_i.u_core.l0asids[57][0]);
    chk("l0vmids[57][0]", dut_g.l0vmids_57_0, dut_i.u_core.l0vmids[57][0]);
    chk("l0vpns[57][0]", dut_g.l0vpns_57_0, dut_i.u_core.l0vpns[57][0]);
    chk("l0h[57][1]", dut_g.l0h_57_1, dut_i.u_core.l0h[57][1]);
    chk("l0asids[57][1]", dut_g.l0asids_57_1, dut_i.u_core.l0asids[57][1]);
    chk("l0vmids[57][1]", dut_g.l0vmids_57_1, dut_i.u_core.l0vmids[57][1]);
    chk("l0vpns[57][1]", dut_g.l0vpns_57_1, dut_i.u_core.l0vpns[57][1]);
    chk("l0h[57][2]", dut_g.l0h_57_2, dut_i.u_core.l0h[57][2]);
    chk("l0asids[57][2]", dut_g.l0asids_57_2, dut_i.u_core.l0asids[57][2]);
    chk("l0vmids[57][2]", dut_g.l0vmids_57_2, dut_i.u_core.l0vmids[57][2]);
    chk("l0vpns[57][2]", dut_g.l0vpns_57_2, dut_i.u_core.l0vpns[57][2]);
    chk("l0h[57][3]", dut_g.l0h_57_3, dut_i.u_core.l0h[57][3]);
    chk("l0asids[57][3]", dut_g.l0asids_57_3, dut_i.u_core.l0asids[57][3]);
    chk("l0vmids[57][3]", dut_g.l0vmids_57_3, dut_i.u_core.l0vmids[57][3]);
    chk("l0vpns[57][3]", dut_g.l0vpns_57_3, dut_i.u_core.l0vpns[57][3]);
    chk("l0h[58][0]", dut_g.l0h_58_0, dut_i.u_core.l0h[58][0]);
    chk("l0asids[58][0]", dut_g.l0asids_58_0, dut_i.u_core.l0asids[58][0]);
    chk("l0vmids[58][0]", dut_g.l0vmids_58_0, dut_i.u_core.l0vmids[58][0]);
    chk("l0vpns[58][0]", dut_g.l0vpns_58_0, dut_i.u_core.l0vpns[58][0]);
    chk("l0h[58][1]", dut_g.l0h_58_1, dut_i.u_core.l0h[58][1]);
    chk("l0asids[58][1]", dut_g.l0asids_58_1, dut_i.u_core.l0asids[58][1]);
    chk("l0vmids[58][1]", dut_g.l0vmids_58_1, dut_i.u_core.l0vmids[58][1]);
    chk("l0vpns[58][1]", dut_g.l0vpns_58_1, dut_i.u_core.l0vpns[58][1]);
    chk("l0h[58][2]", dut_g.l0h_58_2, dut_i.u_core.l0h[58][2]);
    chk("l0asids[58][2]", dut_g.l0asids_58_2, dut_i.u_core.l0asids[58][2]);
    chk("l0vmids[58][2]", dut_g.l0vmids_58_2, dut_i.u_core.l0vmids[58][2]);
    chk("l0vpns[58][2]", dut_g.l0vpns_58_2, dut_i.u_core.l0vpns[58][2]);
    chk("l0h[58][3]", dut_g.l0h_58_3, dut_i.u_core.l0h[58][3]);
    chk("l0asids[58][3]", dut_g.l0asids_58_3, dut_i.u_core.l0asids[58][3]);
    chk("l0vmids[58][3]", dut_g.l0vmids_58_3, dut_i.u_core.l0vmids[58][3]);
    chk("l0vpns[58][3]", dut_g.l0vpns_58_3, dut_i.u_core.l0vpns[58][3]);
    chk("l0h[59][0]", dut_g.l0h_59_0, dut_i.u_core.l0h[59][0]);
    chk("l0asids[59][0]", dut_g.l0asids_59_0, dut_i.u_core.l0asids[59][0]);
    chk("l0vmids[59][0]", dut_g.l0vmids_59_0, dut_i.u_core.l0vmids[59][0]);
    chk("l0vpns[59][0]", dut_g.l0vpns_59_0, dut_i.u_core.l0vpns[59][0]);
    chk("l0h[59][1]", dut_g.l0h_59_1, dut_i.u_core.l0h[59][1]);
    chk("l0asids[59][1]", dut_g.l0asids_59_1, dut_i.u_core.l0asids[59][1]);
    chk("l0vmids[59][1]", dut_g.l0vmids_59_1, dut_i.u_core.l0vmids[59][1]);
    chk("l0vpns[59][1]", dut_g.l0vpns_59_1, dut_i.u_core.l0vpns[59][1]);
    chk("l0h[59][2]", dut_g.l0h_59_2, dut_i.u_core.l0h[59][2]);
    chk("l0asids[59][2]", dut_g.l0asids_59_2, dut_i.u_core.l0asids[59][2]);
    chk("l0vmids[59][2]", dut_g.l0vmids_59_2, dut_i.u_core.l0vmids[59][2]);
    chk("l0vpns[59][2]", dut_g.l0vpns_59_2, dut_i.u_core.l0vpns[59][2]);
    chk("l0h[59][3]", dut_g.l0h_59_3, dut_i.u_core.l0h[59][3]);
    chk("l0asids[59][3]", dut_g.l0asids_59_3, dut_i.u_core.l0asids[59][3]);
    chk("l0vmids[59][3]", dut_g.l0vmids_59_3, dut_i.u_core.l0vmids[59][3]);
    chk("l0vpns[59][3]", dut_g.l0vpns_59_3, dut_i.u_core.l0vpns[59][3]);
    chk("l0h[60][0]", dut_g.l0h_60_0, dut_i.u_core.l0h[60][0]);
    chk("l0asids[60][0]", dut_g.l0asids_60_0, dut_i.u_core.l0asids[60][0]);
    chk("l0vmids[60][0]", dut_g.l0vmids_60_0, dut_i.u_core.l0vmids[60][0]);
    chk("l0vpns[60][0]", dut_g.l0vpns_60_0, dut_i.u_core.l0vpns[60][0]);
    chk("l0h[60][1]", dut_g.l0h_60_1, dut_i.u_core.l0h[60][1]);
    chk("l0asids[60][1]", dut_g.l0asids_60_1, dut_i.u_core.l0asids[60][1]);
    chk("l0vmids[60][1]", dut_g.l0vmids_60_1, dut_i.u_core.l0vmids[60][1]);
    chk("l0vpns[60][1]", dut_g.l0vpns_60_1, dut_i.u_core.l0vpns[60][1]);
    chk("l0h[60][2]", dut_g.l0h_60_2, dut_i.u_core.l0h[60][2]);
    chk("l0asids[60][2]", dut_g.l0asids_60_2, dut_i.u_core.l0asids[60][2]);
    chk("l0vmids[60][2]", dut_g.l0vmids_60_2, dut_i.u_core.l0vmids[60][2]);
    chk("l0vpns[60][2]", dut_g.l0vpns_60_2, dut_i.u_core.l0vpns[60][2]);
    chk("l0h[60][3]", dut_g.l0h_60_3, dut_i.u_core.l0h[60][3]);
    chk("l0asids[60][3]", dut_g.l0asids_60_3, dut_i.u_core.l0asids[60][3]);
    chk("l0vmids[60][3]", dut_g.l0vmids_60_3, dut_i.u_core.l0vmids[60][3]);
    chk("l0vpns[60][3]", dut_g.l0vpns_60_3, dut_i.u_core.l0vpns[60][3]);
    chk("l0h[61][0]", dut_g.l0h_61_0, dut_i.u_core.l0h[61][0]);
    chk("l0asids[61][0]", dut_g.l0asids_61_0, dut_i.u_core.l0asids[61][0]);
    chk("l0vmids[61][0]", dut_g.l0vmids_61_0, dut_i.u_core.l0vmids[61][0]);
    chk("l0vpns[61][0]", dut_g.l0vpns_61_0, dut_i.u_core.l0vpns[61][0]);
    chk("l0h[61][1]", dut_g.l0h_61_1, dut_i.u_core.l0h[61][1]);
    chk("l0asids[61][1]", dut_g.l0asids_61_1, dut_i.u_core.l0asids[61][1]);
    chk("l0vmids[61][1]", dut_g.l0vmids_61_1, dut_i.u_core.l0vmids[61][1]);
    chk("l0vpns[61][1]", dut_g.l0vpns_61_1, dut_i.u_core.l0vpns[61][1]);
    chk("l0h[61][2]", dut_g.l0h_61_2, dut_i.u_core.l0h[61][2]);
    chk("l0asids[61][2]", dut_g.l0asids_61_2, dut_i.u_core.l0asids[61][2]);
    chk("l0vmids[61][2]", dut_g.l0vmids_61_2, dut_i.u_core.l0vmids[61][2]);
    chk("l0vpns[61][2]", dut_g.l0vpns_61_2, dut_i.u_core.l0vpns[61][2]);
    chk("l0h[61][3]", dut_g.l0h_61_3, dut_i.u_core.l0h[61][3]);
    chk("l0asids[61][3]", dut_g.l0asids_61_3, dut_i.u_core.l0asids[61][3]);
    chk("l0vmids[61][3]", dut_g.l0vmids_61_3, dut_i.u_core.l0vmids[61][3]);
    chk("l0vpns[61][3]", dut_g.l0vpns_61_3, dut_i.u_core.l0vpns[61][3]);
    chk("l0h[62][0]", dut_g.l0h_62_0, dut_i.u_core.l0h[62][0]);
    chk("l0asids[62][0]", dut_g.l0asids_62_0, dut_i.u_core.l0asids[62][0]);
    chk("l0vmids[62][0]", dut_g.l0vmids_62_0, dut_i.u_core.l0vmids[62][0]);
    chk("l0vpns[62][0]", dut_g.l0vpns_62_0, dut_i.u_core.l0vpns[62][0]);
    chk("l0h[62][1]", dut_g.l0h_62_1, dut_i.u_core.l0h[62][1]);
    chk("l0asids[62][1]", dut_g.l0asids_62_1, dut_i.u_core.l0asids[62][1]);
    chk("l0vmids[62][1]", dut_g.l0vmids_62_1, dut_i.u_core.l0vmids[62][1]);
    chk("l0vpns[62][1]", dut_g.l0vpns_62_1, dut_i.u_core.l0vpns[62][1]);
    chk("l0h[62][2]", dut_g.l0h_62_2, dut_i.u_core.l0h[62][2]);
    chk("l0asids[62][2]", dut_g.l0asids_62_2, dut_i.u_core.l0asids[62][2]);
    chk("l0vmids[62][2]", dut_g.l0vmids_62_2, dut_i.u_core.l0vmids[62][2]);
    chk("l0vpns[62][2]", dut_g.l0vpns_62_2, dut_i.u_core.l0vpns[62][2]);
    chk("l0h[62][3]", dut_g.l0h_62_3, dut_i.u_core.l0h[62][3]);
    chk("l0asids[62][3]", dut_g.l0asids_62_3, dut_i.u_core.l0asids[62][3]);
    chk("l0vmids[62][3]", dut_g.l0vmids_62_3, dut_i.u_core.l0vmids[62][3]);
    chk("l0vpns[62][3]", dut_g.l0vpns_62_3, dut_i.u_core.l0vpns[62][3]);
    chk("l0h[63][0]", dut_g.l0h_63_0, dut_i.u_core.l0h[63][0]);
    chk("l0asids[63][0]", dut_g.l0asids_63_0, dut_i.u_core.l0asids[63][0]);
    chk("l0vmids[63][0]", dut_g.l0vmids_63_0, dut_i.u_core.l0vmids[63][0]);
    chk("l0vpns[63][0]", dut_g.l0vpns_63_0, dut_i.u_core.l0vpns[63][0]);
    chk("l0h[63][1]", dut_g.l0h_63_1, dut_i.u_core.l0h[63][1]);
    chk("l0asids[63][1]", dut_g.l0asids_63_1, dut_i.u_core.l0asids[63][1]);
    chk("l0vmids[63][1]", dut_g.l0vmids_63_1, dut_i.u_core.l0vmids[63][1]);
    chk("l0vpns[63][1]", dut_g.l0vpns_63_1, dut_i.u_core.l0vpns[63][1]);
    chk("l0h[63][2]", dut_g.l0h_63_2, dut_i.u_core.l0h[63][2]);
    chk("l0asids[63][2]", dut_g.l0asids_63_2, dut_i.u_core.l0asids[63][2]);
    chk("l0vmids[63][2]", dut_g.l0vmids_63_2, dut_i.u_core.l0vmids[63][2]);
    chk("l0vpns[63][2]", dut_g.l0vpns_63_2, dut_i.u_core.l0vpns[63][2]);
    chk("l0h[63][3]", dut_g.l0h_63_3, dut_i.u_core.l0h[63][3]);
    chk("l0asids[63][3]", dut_g.l0asids_63_3, dut_i.u_core.l0asids[63][3]);
    chk("l0vmids[63][3]", dut_g.l0vmids_63_3, dut_i.u_core.l0vmids[63][3]);
    chk("l0vpns[63][3]", dut_g.l0vpns_63_3, dut_i.u_core.l0vpns[63][3]);
  endtask

  // 命中侧（stageReq -> stageDelay -> stageCheck 三级）
  task automatic compare_hit();
    chk("delay_req_info_vpn", dut_g.data_req_info_vpn, dut_i.u_core.delay_vpn);
    chk("delay_req_info_s2xlate", dut_g.data_req_info_s2xlate, dut_i.u_core.delay_s2x);
    chk("delay_req_info_source", dut_g.data_req_info_source, dut_i.u_core.delay_src);
    chk("delay_isFirst", dut_g.data_isFirst, dut_i.u_core.delay_isfirst);
    chk("delay_isHptwReq", dut_g.data_isHptwReq, dut_i.u_core.delay_ishptw);
    chk("delay_hptwId", dut_g.data_hptwId, dut_i.u_core.delay_hptwid);
    chk("check_req_info_vpn", dut_g.data_1_req_info_vpn, dut_i.u_core.check_vpn);
    chk("check_req_info_s2xlate", dut_g.data_1_req_info_s2xlate, dut_i.u_core.check_s2x);
    chk("check_req_info_source", dut_g.data_1_req_info_source, dut_i.u_core.check_src);
    chk("check_isFirst", dut_g.data_1_isFirst, dut_i.u_core.check_isfirst);
    chk("check_isHptwReq", dut_g.data_1_isHptwReq, dut_i.u_core.check_ishptw);
    chk("check_hptwId", dut_g.data_1_hptwId, dut_i.u_core.check_hptwid);
    chk("resp_req_info_vpn", dut_g.data_2_req_info_vpn, dut_i.u_core.resp_vpn);
    chk("resp_req_info_s2xlate", dut_g.data_2_req_info_s2xlate, dut_i.u_core.resp_s2x);
    chk("resp_req_info_source", dut_g.data_2_req_info_source, dut_i.u_core.resp_src);
    chk("resp_isFirst", dut_g.data_2_isFirst, dut_i.u_core.resp_isfirst);
    chk("resp_isHptwReq", dut_g.data_2_isHptwReq, dut_i.u_core.resp_ishptw);
    chk("resp_hptwId", dut_g.data_2_hptwId, dut_i.u_core.resp_hptwid);
    chk("stageDelay_valid_1cycle", dut_g.stageDelay_valid_1cycle, dut_i.u_core.stage_delay_valid_1cycle);
    chk("stageCheck_valid_1cycle", dut_g.stageCheck_valid_1cycle, dut_i.u_core.stage_check_valid_1cycle);
    chk("valid_delay", dut_g.valid, dut_i.u_core.valid_delay);
    chk("valid_check", dut_g.valid_1, dut_i.u_core.valid_check);
    chk("valid_resp", dut_g.valid_2, dut_i.u_core.valid_resp);
    chk("l3_hitvec[0]", dut_g.hitVec_0, dut_i.u_core.l3_hitvec[0]);
    chk("l3_hitvec[1]", dut_g.hitVec_1, dut_i.u_core.l3_hitvec[1]);
    chk("l3_hitvec[2]", dut_g.hitVec_2, dut_i.u_core.l3_hitvec[2]);
    chk("l3_hitvec[3]", dut_g.hitVec_3, dut_i.u_core.l3_hitvec[3]);
    chk("l3_hitvec[4]", dut_g.hitVec_4, dut_i.u_core.l3_hitvec[4]);
    chk("l3_hitvec[5]", dut_g.hitVec_5, dut_i.u_core.l3_hitvec[5]);
    chk("l3_hitvec[6]", dut_g.hitVec_6, dut_i.u_core.l3_hitvec[6]);
    chk("l3_hitvec[7]", dut_g.hitVec_7, dut_i.u_core.l3_hitvec[7]);
    chk("l3_hitvec[8]", dut_g.hitVec_8, dut_i.u_core.l3_hitvec[8]);
    chk("l3_hitvec[9]", dut_g.hitVec_9, dut_i.u_core.l3_hitvec[9]);
    chk("l3_hitvec[10]", dut_g.hitVec_10, dut_i.u_core.l3_hitvec[10]);
    chk("l3_hitvec[11]", dut_g.hitVec_11, dut_i.u_core.l3_hitvec[11]);
    chk("l3_hitvec[12]", dut_g.hitVec_12, dut_i.u_core.l3_hitvec[12]);
    chk("l3_hitvec[13]", dut_g.hitVec_13, dut_i.u_core.l3_hitvec[13]);
    chk("l3_hitvec[14]", dut_g.hitVec_14, dut_i.u_core.l3_hitvec[14]);
    chk("l3_hitvec[15]", dut_g.hitVec_15, dut_i.u_core.l3_hitvec[15]);
    chk("l2_hitvec[0]", dut_g.hitVec_0_1, dut_i.u_core.l2_hitvec[0]);
    chk("l2_hitvec[1]", dut_g.hitVec_1_1, dut_i.u_core.l2_hitvec[1]);
    chk("l2_hitvec[2]", dut_g.hitVec_2_1, dut_i.u_core.l2_hitvec[2]);
    chk("l2_hitvec[3]", dut_g.hitVec_3_1, dut_i.u_core.l2_hitvec[3]);
    chk("l2_hitvec[4]", dut_g.hitVec_4_1, dut_i.u_core.l2_hitvec[4]);
    chk("l2_hitvec[5]", dut_g.hitVec_5_1, dut_i.u_core.l2_hitvec[5]);
    chk("l2_hitvec[6]", dut_g.hitVec_6_1, dut_i.u_core.l2_hitvec[6]);
    chk("l2_hitvec[7]", dut_g.hitVec_7_1, dut_i.u_core.l2_hitvec[7]);
    chk("l2_hitvec[8]", dut_g.hitVec_8_1, dut_i.u_core.l2_hitvec[8]);
    chk("l2_hitvec[9]", dut_g.hitVec_9_1, dut_i.u_core.l2_hitvec[9]);
    chk("l2_hitvec[10]", dut_g.hitVec_10_1, dut_i.u_core.l2_hitvec[10]);
    chk("l2_hitvec[11]", dut_g.hitVec_11_1, dut_i.u_core.l2_hitvec[11]);
    chk("l2_hitvec[12]", dut_g.hitVec_12_1, dut_i.u_core.l2_hitvec[12]);
    chk("l2_hitvec[13]", dut_g.hitVec_13_1, dut_i.u_core.l2_hitvec[13]);
    chk("l2_hitvec[14]", dut_g.hitVec_14_1, dut_i.u_core.l2_hitvec[14]);
    chk("l2_hitvec[15]", dut_g.hitVec_15_1, dut_i.u_core.l2_hitvec[15]);
    chk("sp_hitvec[0]", dut_g.hitVec_0_2, dut_i.u_core.sp_hitvec[0]);
    chk("sp_hitvec[1]", dut_g.hitVec_1_2, dut_i.u_core.sp_hitvec[1]);
    chk("sp_hitvec[2]", dut_g.hitVec_2_2, dut_i.u_core.sp_hitvec[2]);
    chk("sp_hitvec[3]", dut_g.hitVec_3_2, dut_i.u_core.sp_hitvec[3]);
    chk("sp_hitvec[4]", dut_g.hitVec_4_2, dut_i.u_core.sp_hitvec[4]);
    chk("sp_hitvec[5]", dut_g.hitVec_5_2, dut_i.u_core.sp_hitvec[5]);
    chk("sp_hitvec[6]", dut_g.hitVec_6_2, dut_i.u_core.sp_hitvec[6]);
    chk("sp_hitvec[7]", dut_g.hitVec_7_2, dut_i.u_core.sp_hitvec[7]);
    chk("sp_hitvec[8]", dut_g.hitVec_8_2, dut_i.u_core.sp_hitvec[8]);
    chk("sp_hitvec[9]", dut_g.hitVec_9_2, dut_i.u_core.sp_hitvec[9]);
    chk("sp_hitvec[10]", dut_g.hitVec_10_2, dut_i.u_core.sp_hitvec[10]);
    chk("sp_hitvec[11]", dut_g.hitVec_11_2, dut_i.u_core.sp_hitvec[11]);
    chk("sp_hitvec[12]", dut_g.hitVec_12_2, dut_i.u_core.sp_hitvec[12]);
    chk("sp_hitvec[13]", dut_g.hitVec_13_2, dut_i.u_core.sp_hitvec[13]);
    chk("sp_hitvec[14]", dut_g.hitVec_14_2, dut_i.u_core.sp_hitvec[14]);
    chk("sp_hitvec[15]", dut_g.hitVec_15_2, dut_i.u_core.sp_hitvec[15]);
    chk("l3_hit_r", dut_g.hit_r, dut_i.u_core.l3_hit_r);
    chk("l3_ppn_r", dut_g.hitPPN_r, dut_i.u_core.l3_ppn_r);
    chk("l3_pre_r", dut_g.hitPre_r, dut_i.u_core.l3_pre_r);
    chk("l2_hit_r", dut_g.hit_r_1, dut_i.u_core.l2_hit_r);
    chk("l2_ppn_r", dut_g.hitPPN_r_1, dut_i.u_core.l2_ppn_r);
    chk("l2_pbmt_r", dut_g.hitPbmt_r_1, dut_i.u_core.l2_pbmt_r);
    chk("l2_pre_r", dut_g.hitPre_r_1, dut_i.u_core.l2_pre_r);
    chk("l3_hit_ck", dut_g.l3Hit_r, dut_i.u_core.l3_hit_ck);
    chk("l3_ppn_ck", dut_g.l3HitPPN_r, dut_i.u_core.l3_ppn_ck);
    chk("l3_pre_ck", dut_g.l3Pre_r, dut_i.u_core.l3_pre_ck);
    chk("l2_hit_ck", dut_g.l2Hit, dut_i.u_core.l2_hit_ck);
    chk("l2_ppn_ck", dut_g.l2HitPPN, dut_i.u_core.l2_ppn_ck);
    chk("l2_pbmt_ck", dut_g.l2HitPbmt, dut_i.u_core.l2_pbmt_ck);
    chk("l2_pre_ck", dut_g.l2Pre, dut_i.u_core.l2_pre_ck);
    chk("sp_ishptw_delay", dut_g.ishptw_1, dut_i.u_core.sp_ishptw_delay);
    chk("sp_s2x_delay", dut_g.s2x_info_1, dut_i.u_core.sp_s2x_delay);
    chk("sp_hit_ck", dut_g.spHit, dut_i.u_core.sp_hit_ck);
    chk("sp_pre_ck", dut_g.spPre, dut_i.u_core.sp_pre_ck);
    chk("sp_valid_ck", dut_g.spValid, dut_i.u_core.sp_valid_ck);
    chk("sp_jmp_bitmap_ck", dut_g.spJmpBitmapCheck, dut_i.u_core.sp_jmp_bitmap_ck);
    chk("sp_hitdata_ck.n", dut_g.spHitData_n, dut_i.u_core.sp_hitdata_ck.n);
    chk("sp_hitdata_ck.pbmt", dut_g.spHitData_pbmt, dut_i.u_core.sp_hitdata_ck.pbmt);
    chk("sp_hitdata_ck.ppn", dut_g.spHitData_ppn, dut_i.u_core.sp_hitdata_ck.ppn);
    chk("sp_hitdata_ck.level", dut_g.spHitData_level, dut_i.u_core.sp_hitdata_ck.level);
    chk("sp_hitdata_ck.v", dut_g.spHitData_v, dut_i.u_core.sp_hitdata_ck.v);
    chk("sp_hitdata_ck.perm.d", dut_g.spHitData_perm_d, dut_i.u_core.sp_hitdata_ck.perm.d);
    chk("sp_hitdata_ck.perm.a", dut_g.spHitData_perm_a, dut_i.u_core.sp_hitdata_ck.perm.a);
    chk("sp_hitdata_ck.perm.g", dut_g.spHitData_perm_g, dut_i.u_core.sp_hitdata_ck.perm.g);
    chk("sp_hitdata_ck.perm.u", dut_g.spHitData_perm_u, dut_i.u_core.sp_hitdata_ck.perm.u);
    chk("sp_hitdata_ck.perm.x", dut_g.spHitData_perm_x, dut_i.u_core.sp_hitdata_ck.perm.x);
    chk("sp_hitdata_ck.perm.w", dut_g.spHitData_perm_w, dut_i.u_core.sp_hitdata_ck.perm.w);
    chk("sp_hitdata_ck.perm.r", dut_g.spHitData_perm_r, dut_i.u_core.sp_hitdata_ck.perm.r);
    chk("l1_vvec_delay", dut_g.vVec_delay, dut_i.u_core.l1_vvec_delay);
    chk("l1_gvec_delay", dut_g.gVec_delay, dut_i.u_core.l1_gvec_delay);
    chk("l1_hvec_delay[0]", dut_g.hVec_delay_0, dut_i.u_core.l1_hvec_delay[0]);
    chk("l1_hitvec[0]", dut_g.l1_hitVec_0, dut_i.u_core.l1_hitvec[0]);
    chk("l1_hvec_delay[1]", dut_g.hVec_delay_1, dut_i.u_core.l1_hvec_delay[1]);
    chk("l1_hitvec[1]", dut_g.l1_hitVec_1, dut_i.u_core.l1_hitvec[1]);
    chk("l0_vvec_delay", dut_g.vVec_delay_1, dut_i.u_core.l0_vvec_delay);
    chk("l0_hvec_delay[0]", dut_g.hVec_delay_1_0, dut_i.u_core.l0_hvec_delay[0]);
    chk("l0_hitvec[0]", dut_g.l0_hitVec_0, dut_i.u_core.l0_hitvec[0]);
    chk("l0_hvec_delay[1]", dut_g.hVec_delay_1_1, dut_i.u_core.l0_hvec_delay[1]);
    chk("l0_hitvec[1]", dut_g.l0_hitVec_1, dut_i.u_core.l0_hitvec[1]);
    chk("l0_hvec_delay[2]", dut_g.hVec_delay_1_2, dut_i.u_core.l0_hvec_delay[2]);
    chk("l0_hitvec[2]", dut_g.l0_hitVec_2, dut_i.u_core.l0_hitvec[2]);
    chk("l0_hvec_delay[3]", dut_g.hVec_delay_1_3, dut_i.u_core.l0_hvec_delay[3]);
    chk("l0_hitvec[3]", dut_g.l0_hitVec_3, dut_i.u_core.l0_hitvec[3]);
    chk("l1_resp_r[0].tag", dut_g.data_resp_r_0_entries_tag, dut_i.u_core.l1_resp_r[0].tag);
    chk("l1_resp_r[0].asid", dut_g.data_resp_r_0_entries_asid, dut_i.u_core.l1_resp_r[0].asid);
    chk("l1_resp_r[0].vmid", dut_g.data_resp_r_0_entries_vmid, dut_i.u_core.l1_resp_r[0].vmid);
    chk("l1_resp_r[0].prefetch", dut_g.data_resp_r_0_entries_prefetch, dut_i.u_core.l1_resp_r[0].prefetch);
    chk("l1_resp_r[0].pbmts[0]", dut_g.data_resp_r_0_entries_pbmts_0, dut_i.u_core.l1_resp_r[0].pbmts[0]);
    chk("l1_resp_r[0].ppns[0]", dut_g.data_resp_r_0_entries_ppns_0, dut_i.u_core.l1_resp_r[0].ppns[0]);
    chk("l1_resp_r[0].vs[0]", dut_g.data_resp_r_0_entries_vs_0, dut_i.u_core.l1_resp_r[0].vs[0]);
    chk("l1_resp_r[0].pbmts[1]", dut_g.data_resp_r_0_entries_pbmts_1, dut_i.u_core.l1_resp_r[0].pbmts[1]);
    chk("l1_resp_r[0].ppns[1]", dut_g.data_resp_r_0_entries_ppns_1, dut_i.u_core.l1_resp_r[0].ppns[1]);
    chk("l1_resp_r[0].vs[1]", dut_g.data_resp_r_0_entries_vs_1, dut_i.u_core.l1_resp_r[0].vs[1]);
    chk("l1_resp_r[0].pbmts[2]", dut_g.data_resp_r_0_entries_pbmts_2, dut_i.u_core.l1_resp_r[0].pbmts[2]);
    chk("l1_resp_r[0].ppns[2]", dut_g.data_resp_r_0_entries_ppns_2, dut_i.u_core.l1_resp_r[0].ppns[2]);
    chk("l1_resp_r[0].vs[2]", dut_g.data_resp_r_0_entries_vs_2, dut_i.u_core.l1_resp_r[0].vs[2]);
    chk("l1_resp_r[0].pbmts[3]", dut_g.data_resp_r_0_entries_pbmts_3, dut_i.u_core.l1_resp_r[0].pbmts[3]);
    chk("l1_resp_r[0].ppns[3]", dut_g.data_resp_r_0_entries_ppns_3, dut_i.u_core.l1_resp_r[0].ppns[3]);
    chk("l1_resp_r[0].vs[3]", dut_g.data_resp_r_0_entries_vs_3, dut_i.u_core.l1_resp_r[0].vs[3]);
    chk("l1_resp_r[0].pbmts[4]", dut_g.data_resp_r_0_entries_pbmts_4, dut_i.u_core.l1_resp_r[0].pbmts[4]);
    chk("l1_resp_r[0].ppns[4]", dut_g.data_resp_r_0_entries_ppns_4, dut_i.u_core.l1_resp_r[0].ppns[4]);
    chk("l1_resp_r[0].vs[4]", dut_g.data_resp_r_0_entries_vs_4, dut_i.u_core.l1_resp_r[0].vs[4]);
    chk("l1_resp_r[0].pbmts[5]", dut_g.data_resp_r_0_entries_pbmts_5, dut_i.u_core.l1_resp_r[0].pbmts[5]);
    chk("l1_resp_r[0].ppns[5]", dut_g.data_resp_r_0_entries_ppns_5, dut_i.u_core.l1_resp_r[0].ppns[5]);
    chk("l1_resp_r[0].vs[5]", dut_g.data_resp_r_0_entries_vs_5, dut_i.u_core.l1_resp_r[0].vs[5]);
    chk("l1_resp_r[0].pbmts[6]", dut_g.data_resp_r_0_entries_pbmts_6, dut_i.u_core.l1_resp_r[0].pbmts[6]);
    chk("l1_resp_r[0].ppns[6]", dut_g.data_resp_r_0_entries_ppns_6, dut_i.u_core.l1_resp_r[0].ppns[6]);
    chk("l1_resp_r[0].vs[6]", dut_g.data_resp_r_0_entries_vs_6, dut_i.u_core.l1_resp_r[0].vs[6]);
    chk("l1_resp_r[0].pbmts[7]", dut_g.data_resp_r_0_entries_pbmts_7, dut_i.u_core.l1_resp_r[0].pbmts[7]);
    chk("l1_resp_r[0].ppns[7]", dut_g.data_resp_r_0_entries_ppns_7, dut_i.u_core.l1_resp_r[0].ppns[7]);
    chk("l1_resp_r[0].vs[7]", dut_g.data_resp_r_0_entries_vs_7, dut_i.u_core.l1_resp_r[0].vs[7]);
    chk("l1_ramdata[0].prefetch", dut_g.l1_ramDatas_0_entries_prefetch, dut_i.u_core.l1_ramdata[0].prefetch);
    chk("l1_ramdata[0].pbmts[0]", dut_g.l1_ramDatas_0_entries_pbmts_0, dut_i.u_core.l1_ramdata[0].pbmts[0]);
    chk("l1_ramdata[0].ppns[0]", dut_g.l1_ramDatas_0_entries_ppns_0, dut_i.u_core.l1_ramdata[0].ppns[0]);
    chk("l1_ramdata[0].pbmts[1]", dut_g.l1_ramDatas_0_entries_pbmts_1, dut_i.u_core.l1_ramdata[0].pbmts[1]);
    chk("l1_ramdata[0].ppns[1]", dut_g.l1_ramDatas_0_entries_ppns_1, dut_i.u_core.l1_ramdata[0].ppns[1]);
    chk("l1_ramdata[0].pbmts[2]", dut_g.l1_ramDatas_0_entries_pbmts_2, dut_i.u_core.l1_ramdata[0].pbmts[2]);
    chk("l1_ramdata[0].ppns[2]", dut_g.l1_ramDatas_0_entries_ppns_2, dut_i.u_core.l1_ramdata[0].ppns[2]);
    chk("l1_ramdata[0].pbmts[3]", dut_g.l1_ramDatas_0_entries_pbmts_3, dut_i.u_core.l1_ramdata[0].pbmts[3]);
    chk("l1_ramdata[0].ppns[3]", dut_g.l1_ramDatas_0_entries_ppns_3, dut_i.u_core.l1_ramdata[0].ppns[3]);
    chk("l1_ramdata[0].pbmts[4]", dut_g.l1_ramDatas_0_entries_pbmts_4, dut_i.u_core.l1_ramdata[0].pbmts[4]);
    chk("l1_ramdata[0].ppns[4]", dut_g.l1_ramDatas_0_entries_ppns_4, dut_i.u_core.l1_ramdata[0].ppns[4]);
    chk("l1_ramdata[0].pbmts[5]", dut_g.l1_ramDatas_0_entries_pbmts_5, dut_i.u_core.l1_ramdata[0].pbmts[5]);
    chk("l1_ramdata[0].ppns[5]", dut_g.l1_ramDatas_0_entries_ppns_5, dut_i.u_core.l1_ramdata[0].ppns[5]);
    chk("l1_ramdata[0].pbmts[6]", dut_g.l1_ramDatas_0_entries_pbmts_6, dut_i.u_core.l1_ramdata[0].pbmts[6]);
    chk("l1_ramdata[0].ppns[6]", dut_g.l1_ramDatas_0_entries_ppns_6, dut_i.u_core.l1_ramdata[0].ppns[6]);
    chk("l1_ramdata[0].pbmts[7]", dut_g.l1_ramDatas_0_entries_pbmts_7, dut_i.u_core.l1_ramdata[0].pbmts[7]);
    chk("l1_ramdata[0].ppns[7]", dut_g.l1_ramDatas_0_entries_ppns_7, dut_i.u_core.l1_ramdata[0].ppns[7]);
    chk("l1_resp_r[1].tag", dut_g.data_resp_r_1_entries_tag, dut_i.u_core.l1_resp_r[1].tag);
    chk("l1_resp_r[1].asid", dut_g.data_resp_r_1_entries_asid, dut_i.u_core.l1_resp_r[1].asid);
    chk("l1_resp_r[1].vmid", dut_g.data_resp_r_1_entries_vmid, dut_i.u_core.l1_resp_r[1].vmid);
    chk("l1_resp_r[1].prefetch", dut_g.data_resp_r_1_entries_prefetch, dut_i.u_core.l1_resp_r[1].prefetch);
    chk("l1_resp_r[1].pbmts[0]", dut_g.data_resp_r_1_entries_pbmts_0, dut_i.u_core.l1_resp_r[1].pbmts[0]);
    chk("l1_resp_r[1].ppns[0]", dut_g.data_resp_r_1_entries_ppns_0, dut_i.u_core.l1_resp_r[1].ppns[0]);
    chk("l1_resp_r[1].vs[0]", dut_g.data_resp_r_1_entries_vs_0, dut_i.u_core.l1_resp_r[1].vs[0]);
    chk("l1_resp_r[1].pbmts[1]", dut_g.data_resp_r_1_entries_pbmts_1, dut_i.u_core.l1_resp_r[1].pbmts[1]);
    chk("l1_resp_r[1].ppns[1]", dut_g.data_resp_r_1_entries_ppns_1, dut_i.u_core.l1_resp_r[1].ppns[1]);
    chk("l1_resp_r[1].vs[1]", dut_g.data_resp_r_1_entries_vs_1, dut_i.u_core.l1_resp_r[1].vs[1]);
    chk("l1_resp_r[1].pbmts[2]", dut_g.data_resp_r_1_entries_pbmts_2, dut_i.u_core.l1_resp_r[1].pbmts[2]);
    chk("l1_resp_r[1].ppns[2]", dut_g.data_resp_r_1_entries_ppns_2, dut_i.u_core.l1_resp_r[1].ppns[2]);
    chk("l1_resp_r[1].vs[2]", dut_g.data_resp_r_1_entries_vs_2, dut_i.u_core.l1_resp_r[1].vs[2]);
    chk("l1_resp_r[1].pbmts[3]", dut_g.data_resp_r_1_entries_pbmts_3, dut_i.u_core.l1_resp_r[1].pbmts[3]);
    chk("l1_resp_r[1].ppns[3]", dut_g.data_resp_r_1_entries_ppns_3, dut_i.u_core.l1_resp_r[1].ppns[3]);
    chk("l1_resp_r[1].vs[3]", dut_g.data_resp_r_1_entries_vs_3, dut_i.u_core.l1_resp_r[1].vs[3]);
    chk("l1_resp_r[1].pbmts[4]", dut_g.data_resp_r_1_entries_pbmts_4, dut_i.u_core.l1_resp_r[1].pbmts[4]);
    chk("l1_resp_r[1].ppns[4]", dut_g.data_resp_r_1_entries_ppns_4, dut_i.u_core.l1_resp_r[1].ppns[4]);
    chk("l1_resp_r[1].vs[4]", dut_g.data_resp_r_1_entries_vs_4, dut_i.u_core.l1_resp_r[1].vs[4]);
    chk("l1_resp_r[1].pbmts[5]", dut_g.data_resp_r_1_entries_pbmts_5, dut_i.u_core.l1_resp_r[1].pbmts[5]);
    chk("l1_resp_r[1].ppns[5]", dut_g.data_resp_r_1_entries_ppns_5, dut_i.u_core.l1_resp_r[1].ppns[5]);
    chk("l1_resp_r[1].vs[5]", dut_g.data_resp_r_1_entries_vs_5, dut_i.u_core.l1_resp_r[1].vs[5]);
    chk("l1_resp_r[1].pbmts[6]", dut_g.data_resp_r_1_entries_pbmts_6, dut_i.u_core.l1_resp_r[1].pbmts[6]);
    chk("l1_resp_r[1].ppns[6]", dut_g.data_resp_r_1_entries_ppns_6, dut_i.u_core.l1_resp_r[1].ppns[6]);
    chk("l1_resp_r[1].vs[6]", dut_g.data_resp_r_1_entries_vs_6, dut_i.u_core.l1_resp_r[1].vs[6]);
    chk("l1_resp_r[1].pbmts[7]", dut_g.data_resp_r_1_entries_pbmts_7, dut_i.u_core.l1_resp_r[1].pbmts[7]);
    chk("l1_resp_r[1].ppns[7]", dut_g.data_resp_r_1_entries_ppns_7, dut_i.u_core.l1_resp_r[1].ppns[7]);
    chk("l1_resp_r[1].vs[7]", dut_g.data_resp_r_1_entries_vs_7, dut_i.u_core.l1_resp_r[1].vs[7]);
    chk("l1_ramdata[1].prefetch", dut_g.l1_ramDatas_1_entries_prefetch, dut_i.u_core.l1_ramdata[1].prefetch);
    chk("l1_ramdata[1].pbmts[0]", dut_g.l1_ramDatas_1_entries_pbmts_0, dut_i.u_core.l1_ramdata[1].pbmts[0]);
    chk("l1_ramdata[1].ppns[0]", dut_g.l1_ramDatas_1_entries_ppns_0, dut_i.u_core.l1_ramdata[1].ppns[0]);
    chk("l1_ramdata[1].pbmts[1]", dut_g.l1_ramDatas_1_entries_pbmts_1, dut_i.u_core.l1_ramdata[1].pbmts[1]);
    chk("l1_ramdata[1].ppns[1]", dut_g.l1_ramDatas_1_entries_ppns_1, dut_i.u_core.l1_ramdata[1].ppns[1]);
    chk("l1_ramdata[1].pbmts[2]", dut_g.l1_ramDatas_1_entries_pbmts_2, dut_i.u_core.l1_ramdata[1].pbmts[2]);
    chk("l1_ramdata[1].ppns[2]", dut_g.l1_ramDatas_1_entries_ppns_2, dut_i.u_core.l1_ramdata[1].ppns[2]);
    chk("l1_ramdata[1].pbmts[3]", dut_g.l1_ramDatas_1_entries_pbmts_3, dut_i.u_core.l1_ramdata[1].pbmts[3]);
    chk("l1_ramdata[1].ppns[3]", dut_g.l1_ramDatas_1_entries_ppns_3, dut_i.u_core.l1_ramdata[1].ppns[3]);
    chk("l1_ramdata[1].pbmts[4]", dut_g.l1_ramDatas_1_entries_pbmts_4, dut_i.u_core.l1_ramdata[1].pbmts[4]);
    chk("l1_ramdata[1].ppns[4]", dut_g.l1_ramDatas_1_entries_ppns_4, dut_i.u_core.l1_ramdata[1].ppns[4]);
    chk("l1_ramdata[1].pbmts[5]", dut_g.l1_ramDatas_1_entries_pbmts_5, dut_i.u_core.l1_ramdata[1].pbmts[5]);
    chk("l1_ramdata[1].ppns[5]", dut_g.l1_ramDatas_1_entries_ppns_5, dut_i.u_core.l1_ramdata[1].ppns[5]);
    chk("l1_ramdata[1].pbmts[6]", dut_g.l1_ramDatas_1_entries_pbmts_6, dut_i.u_core.l1_ramdata[1].pbmts[6]);
    chk("l1_ramdata[1].ppns[6]", dut_g.l1_ramDatas_1_entries_ppns_6, dut_i.u_core.l1_ramdata[1].ppns[6]);
    chk("l1_ramdata[1].pbmts[7]", dut_g.l1_ramDatas_1_entries_pbmts_7, dut_i.u_core.l1_ramdata[1].pbmts[7]);
    chk("l1_ramdata[1].ppns[7]", dut_g.l1_ramDatas_1_entries_ppns_7, dut_i.u_core.l1_ramdata[1].ppns[7]);
    chk("l0_resp_r[0].tag", dut_g.data_resp_r_1_0_entries_tag, dut_i.u_core.l0_resp_r[0].tag);
    chk("l0_resp_r[0].asid", dut_g.data_resp_r_1_0_entries_asid, dut_i.u_core.l0_resp_r[0].asid);
    chk("l0_resp_r[0].vmid", dut_g.data_resp_r_1_0_entries_vmid, dut_i.u_core.l0_resp_r[0].vmid);
    chk("l0_resp_r[0].prefetch", dut_g.data_resp_r_1_0_entries_prefetch, dut_i.u_core.l0_resp_r[0].prefetch);
    chk("l0_resp_r[0].pbmts[0]", dut_g.data_resp_r_1_0_entries_pbmts_0, dut_i.u_core.l0_resp_r[0].pbmts[0]);
    chk("l0_resp_r[0].ppns[0]", dut_g.data_resp_r_1_0_entries_ppns_0, dut_i.u_core.l0_resp_r[0].ppns[0]);
    chk("l0_resp_r[0].vs[0]", dut_g.data_resp_r_1_0_entries_vs_0, dut_i.u_core.l0_resp_r[0].vs[0]);
    chk("l0_resp_r[0].onlypf[0]", dut_g.data_resp_r_1_0_entries_onlypf_0, dut_i.u_core.l0_resp_r[0].onlypf[0]);
    chk("l0_resp_r[0].perms[0].d", dut_g.data_resp_r_1_0_entries_perms_0_d, dut_i.u_core.l0_resp_r[0].perms[0].d);
    chk("l0_resp_r[0].perms[0].a", dut_g.data_resp_r_1_0_entries_perms_0_a, dut_i.u_core.l0_resp_r[0].perms[0].a);
    chk("l0_resp_r[0].perms[0].g", dut_g.data_resp_r_1_0_entries_perms_0_g, dut_i.u_core.l0_resp_r[0].perms[0].g);
    chk("l0_resp_r[0].perms[0].u", dut_g.data_resp_r_1_0_entries_perms_0_u, dut_i.u_core.l0_resp_r[0].perms[0].u);
    chk("l0_resp_r[0].perms[0].x", dut_g.data_resp_r_1_0_entries_perms_0_x, dut_i.u_core.l0_resp_r[0].perms[0].x);
    chk("l0_resp_r[0].perms[0].w", dut_g.data_resp_r_1_0_entries_perms_0_w, dut_i.u_core.l0_resp_r[0].perms[0].w);
    chk("l0_resp_r[0].perms[0].r", dut_g.data_resp_r_1_0_entries_perms_0_r, dut_i.u_core.l0_resp_r[0].perms[0].r);
    chk("l0_resp_r[0].pbmts[1]", dut_g.data_resp_r_1_0_entries_pbmts_1, dut_i.u_core.l0_resp_r[0].pbmts[1]);
    chk("l0_resp_r[0].ppns[1]", dut_g.data_resp_r_1_0_entries_ppns_1, dut_i.u_core.l0_resp_r[0].ppns[1]);
    chk("l0_resp_r[0].vs[1]", dut_g.data_resp_r_1_0_entries_vs_1, dut_i.u_core.l0_resp_r[0].vs[1]);
    chk("l0_resp_r[0].onlypf[1]", dut_g.data_resp_r_1_0_entries_onlypf_1, dut_i.u_core.l0_resp_r[0].onlypf[1]);
    chk("l0_resp_r[0].perms[1].d", dut_g.data_resp_r_1_0_entries_perms_1_d, dut_i.u_core.l0_resp_r[0].perms[1].d);
    chk("l0_resp_r[0].perms[1].a", dut_g.data_resp_r_1_0_entries_perms_1_a, dut_i.u_core.l0_resp_r[0].perms[1].a);
    chk("l0_resp_r[0].perms[1].g", dut_g.data_resp_r_1_0_entries_perms_1_g, dut_i.u_core.l0_resp_r[0].perms[1].g);
    chk("l0_resp_r[0].perms[1].u", dut_g.data_resp_r_1_0_entries_perms_1_u, dut_i.u_core.l0_resp_r[0].perms[1].u);
    chk("l0_resp_r[0].perms[1].x", dut_g.data_resp_r_1_0_entries_perms_1_x, dut_i.u_core.l0_resp_r[0].perms[1].x);
    chk("l0_resp_r[0].perms[1].w", dut_g.data_resp_r_1_0_entries_perms_1_w, dut_i.u_core.l0_resp_r[0].perms[1].w);
    chk("l0_resp_r[0].perms[1].r", dut_g.data_resp_r_1_0_entries_perms_1_r, dut_i.u_core.l0_resp_r[0].perms[1].r);
    chk("l0_resp_r[0].pbmts[2]", dut_g.data_resp_r_1_0_entries_pbmts_2, dut_i.u_core.l0_resp_r[0].pbmts[2]);
    chk("l0_resp_r[0].ppns[2]", dut_g.data_resp_r_1_0_entries_ppns_2, dut_i.u_core.l0_resp_r[0].ppns[2]);
    chk("l0_resp_r[0].vs[2]", dut_g.data_resp_r_1_0_entries_vs_2, dut_i.u_core.l0_resp_r[0].vs[2]);
    chk("l0_resp_r[0].onlypf[2]", dut_g.data_resp_r_1_0_entries_onlypf_2, dut_i.u_core.l0_resp_r[0].onlypf[2]);
    chk("l0_resp_r[0].perms[2].d", dut_g.data_resp_r_1_0_entries_perms_2_d, dut_i.u_core.l0_resp_r[0].perms[2].d);
    chk("l0_resp_r[0].perms[2].a", dut_g.data_resp_r_1_0_entries_perms_2_a, dut_i.u_core.l0_resp_r[0].perms[2].a);
    chk("l0_resp_r[0].perms[2].g", dut_g.data_resp_r_1_0_entries_perms_2_g, dut_i.u_core.l0_resp_r[0].perms[2].g);
    chk("l0_resp_r[0].perms[2].u", dut_g.data_resp_r_1_0_entries_perms_2_u, dut_i.u_core.l0_resp_r[0].perms[2].u);
    chk("l0_resp_r[0].perms[2].x", dut_g.data_resp_r_1_0_entries_perms_2_x, dut_i.u_core.l0_resp_r[0].perms[2].x);
    chk("l0_resp_r[0].perms[2].w", dut_g.data_resp_r_1_0_entries_perms_2_w, dut_i.u_core.l0_resp_r[0].perms[2].w);
    chk("l0_resp_r[0].perms[2].r", dut_g.data_resp_r_1_0_entries_perms_2_r, dut_i.u_core.l0_resp_r[0].perms[2].r);
    chk("l0_resp_r[0].pbmts[3]", dut_g.data_resp_r_1_0_entries_pbmts_3, dut_i.u_core.l0_resp_r[0].pbmts[3]);
    chk("l0_resp_r[0].ppns[3]", dut_g.data_resp_r_1_0_entries_ppns_3, dut_i.u_core.l0_resp_r[0].ppns[3]);
    chk("l0_resp_r[0].vs[3]", dut_g.data_resp_r_1_0_entries_vs_3, dut_i.u_core.l0_resp_r[0].vs[3]);
    chk("l0_resp_r[0].onlypf[3]", dut_g.data_resp_r_1_0_entries_onlypf_3, dut_i.u_core.l0_resp_r[0].onlypf[3]);
    chk("l0_resp_r[0].perms[3].d", dut_g.data_resp_r_1_0_entries_perms_3_d, dut_i.u_core.l0_resp_r[0].perms[3].d);
    chk("l0_resp_r[0].perms[3].a", dut_g.data_resp_r_1_0_entries_perms_3_a, dut_i.u_core.l0_resp_r[0].perms[3].a);
    chk("l0_resp_r[0].perms[3].g", dut_g.data_resp_r_1_0_entries_perms_3_g, dut_i.u_core.l0_resp_r[0].perms[3].g);
    chk("l0_resp_r[0].perms[3].u", dut_g.data_resp_r_1_0_entries_perms_3_u, dut_i.u_core.l0_resp_r[0].perms[3].u);
    chk("l0_resp_r[0].perms[3].x", dut_g.data_resp_r_1_0_entries_perms_3_x, dut_i.u_core.l0_resp_r[0].perms[3].x);
    chk("l0_resp_r[0].perms[3].w", dut_g.data_resp_r_1_0_entries_perms_3_w, dut_i.u_core.l0_resp_r[0].perms[3].w);
    chk("l0_resp_r[0].perms[3].r", dut_g.data_resp_r_1_0_entries_perms_3_r, dut_i.u_core.l0_resp_r[0].perms[3].r);
    chk("l0_resp_r[0].pbmts[4]", dut_g.data_resp_r_1_0_entries_pbmts_4, dut_i.u_core.l0_resp_r[0].pbmts[4]);
    chk("l0_resp_r[0].ppns[4]", dut_g.data_resp_r_1_0_entries_ppns_4, dut_i.u_core.l0_resp_r[0].ppns[4]);
    chk("l0_resp_r[0].vs[4]", dut_g.data_resp_r_1_0_entries_vs_4, dut_i.u_core.l0_resp_r[0].vs[4]);
    chk("l0_resp_r[0].onlypf[4]", dut_g.data_resp_r_1_0_entries_onlypf_4, dut_i.u_core.l0_resp_r[0].onlypf[4]);
    chk("l0_resp_r[0].perms[4].d", dut_g.data_resp_r_1_0_entries_perms_4_d, dut_i.u_core.l0_resp_r[0].perms[4].d);
    chk("l0_resp_r[0].perms[4].a", dut_g.data_resp_r_1_0_entries_perms_4_a, dut_i.u_core.l0_resp_r[0].perms[4].a);
    chk("l0_resp_r[0].perms[4].g", dut_g.data_resp_r_1_0_entries_perms_4_g, dut_i.u_core.l0_resp_r[0].perms[4].g);
    chk("l0_resp_r[0].perms[4].u", dut_g.data_resp_r_1_0_entries_perms_4_u, dut_i.u_core.l0_resp_r[0].perms[4].u);
    chk("l0_resp_r[0].perms[4].x", dut_g.data_resp_r_1_0_entries_perms_4_x, dut_i.u_core.l0_resp_r[0].perms[4].x);
    chk("l0_resp_r[0].perms[4].w", dut_g.data_resp_r_1_0_entries_perms_4_w, dut_i.u_core.l0_resp_r[0].perms[4].w);
    chk("l0_resp_r[0].perms[4].r", dut_g.data_resp_r_1_0_entries_perms_4_r, dut_i.u_core.l0_resp_r[0].perms[4].r);
    chk("l0_resp_r[0].pbmts[5]", dut_g.data_resp_r_1_0_entries_pbmts_5, dut_i.u_core.l0_resp_r[0].pbmts[5]);
    chk("l0_resp_r[0].ppns[5]", dut_g.data_resp_r_1_0_entries_ppns_5, dut_i.u_core.l0_resp_r[0].ppns[5]);
    chk("l0_resp_r[0].vs[5]", dut_g.data_resp_r_1_0_entries_vs_5, dut_i.u_core.l0_resp_r[0].vs[5]);
    chk("l0_resp_r[0].onlypf[5]", dut_g.data_resp_r_1_0_entries_onlypf_5, dut_i.u_core.l0_resp_r[0].onlypf[5]);
    chk("l0_resp_r[0].perms[5].d", dut_g.data_resp_r_1_0_entries_perms_5_d, dut_i.u_core.l0_resp_r[0].perms[5].d);
    chk("l0_resp_r[0].perms[5].a", dut_g.data_resp_r_1_0_entries_perms_5_a, dut_i.u_core.l0_resp_r[0].perms[5].a);
    chk("l0_resp_r[0].perms[5].g", dut_g.data_resp_r_1_0_entries_perms_5_g, dut_i.u_core.l0_resp_r[0].perms[5].g);
    chk("l0_resp_r[0].perms[5].u", dut_g.data_resp_r_1_0_entries_perms_5_u, dut_i.u_core.l0_resp_r[0].perms[5].u);
    chk("l0_resp_r[0].perms[5].x", dut_g.data_resp_r_1_0_entries_perms_5_x, dut_i.u_core.l0_resp_r[0].perms[5].x);
    chk("l0_resp_r[0].perms[5].w", dut_g.data_resp_r_1_0_entries_perms_5_w, dut_i.u_core.l0_resp_r[0].perms[5].w);
    chk("l0_resp_r[0].perms[5].r", dut_g.data_resp_r_1_0_entries_perms_5_r, dut_i.u_core.l0_resp_r[0].perms[5].r);
    chk("l0_resp_r[0].pbmts[6]", dut_g.data_resp_r_1_0_entries_pbmts_6, dut_i.u_core.l0_resp_r[0].pbmts[6]);
    chk("l0_resp_r[0].ppns[6]", dut_g.data_resp_r_1_0_entries_ppns_6, dut_i.u_core.l0_resp_r[0].ppns[6]);
    chk("l0_resp_r[0].vs[6]", dut_g.data_resp_r_1_0_entries_vs_6, dut_i.u_core.l0_resp_r[0].vs[6]);
    chk("l0_resp_r[0].onlypf[6]", dut_g.data_resp_r_1_0_entries_onlypf_6, dut_i.u_core.l0_resp_r[0].onlypf[6]);
    chk("l0_resp_r[0].perms[6].d", dut_g.data_resp_r_1_0_entries_perms_6_d, dut_i.u_core.l0_resp_r[0].perms[6].d);
    chk("l0_resp_r[0].perms[6].a", dut_g.data_resp_r_1_0_entries_perms_6_a, dut_i.u_core.l0_resp_r[0].perms[6].a);
    chk("l0_resp_r[0].perms[6].g", dut_g.data_resp_r_1_0_entries_perms_6_g, dut_i.u_core.l0_resp_r[0].perms[6].g);
    chk("l0_resp_r[0].perms[6].u", dut_g.data_resp_r_1_0_entries_perms_6_u, dut_i.u_core.l0_resp_r[0].perms[6].u);
    chk("l0_resp_r[0].perms[6].x", dut_g.data_resp_r_1_0_entries_perms_6_x, dut_i.u_core.l0_resp_r[0].perms[6].x);
    chk("l0_resp_r[0].perms[6].w", dut_g.data_resp_r_1_0_entries_perms_6_w, dut_i.u_core.l0_resp_r[0].perms[6].w);
    chk("l0_resp_r[0].perms[6].r", dut_g.data_resp_r_1_0_entries_perms_6_r, dut_i.u_core.l0_resp_r[0].perms[6].r);
    chk("l0_resp_r[0].pbmts[7]", dut_g.data_resp_r_1_0_entries_pbmts_7, dut_i.u_core.l0_resp_r[0].pbmts[7]);
    chk("l0_resp_r[0].ppns[7]", dut_g.data_resp_r_1_0_entries_ppns_7, dut_i.u_core.l0_resp_r[0].ppns[7]);
    chk("l0_resp_r[0].vs[7]", dut_g.data_resp_r_1_0_entries_vs_7, dut_i.u_core.l0_resp_r[0].vs[7]);
    chk("l0_resp_r[0].onlypf[7]", dut_g.data_resp_r_1_0_entries_onlypf_7, dut_i.u_core.l0_resp_r[0].onlypf[7]);
    chk("l0_resp_r[0].perms[7].d", dut_g.data_resp_r_1_0_entries_perms_7_d, dut_i.u_core.l0_resp_r[0].perms[7].d);
    chk("l0_resp_r[0].perms[7].a", dut_g.data_resp_r_1_0_entries_perms_7_a, dut_i.u_core.l0_resp_r[0].perms[7].a);
    chk("l0_resp_r[0].perms[7].g", dut_g.data_resp_r_1_0_entries_perms_7_g, dut_i.u_core.l0_resp_r[0].perms[7].g);
    chk("l0_resp_r[0].perms[7].u", dut_g.data_resp_r_1_0_entries_perms_7_u, dut_i.u_core.l0_resp_r[0].perms[7].u);
    chk("l0_resp_r[0].perms[7].x", dut_g.data_resp_r_1_0_entries_perms_7_x, dut_i.u_core.l0_resp_r[0].perms[7].x);
    chk("l0_resp_r[0].perms[7].w", dut_g.data_resp_r_1_0_entries_perms_7_w, dut_i.u_core.l0_resp_r[0].perms[7].w);
    chk("l0_resp_r[0].perms[7].r", dut_g.data_resp_r_1_0_entries_perms_7_r, dut_i.u_core.l0_resp_r[0].perms[7].r);
    chk("l0_ramdata[0].prefetch", dut_g.l0_ramDatas_0_entries_prefetch, dut_i.u_core.l0_ramdata[0].prefetch);
    chk("l0_ramdata[0].pbmts[0]", dut_g.l0_ramDatas_0_entries_pbmts_0, dut_i.u_core.l0_ramdata[0].pbmts[0]);
    chk("l0_ramdata[0].ppns[0]", dut_g.l0_ramDatas_0_entries_ppns_0, dut_i.u_core.l0_ramdata[0].ppns[0]);
    chk("l0_ramdata[0].onlypf[0]", dut_g.l0_ramDatas_0_entries_onlypf_0, dut_i.u_core.l0_ramdata[0].onlypf[0]);
    chk("l0_ramdata[0].perms[0].d", dut_g.l0_ramDatas_0_entries_perms_0_d, dut_i.u_core.l0_ramdata[0].perms[0].d);
    chk("l0_ramdata[0].perms[0].a", dut_g.l0_ramDatas_0_entries_perms_0_a, dut_i.u_core.l0_ramdata[0].perms[0].a);
    chk("l0_ramdata[0].perms[0].g", dut_g.l0_ramDatas_0_entries_perms_0_g, dut_i.u_core.l0_ramdata[0].perms[0].g);
    chk("l0_ramdata[0].perms[0].u", dut_g.l0_ramDatas_0_entries_perms_0_u, dut_i.u_core.l0_ramdata[0].perms[0].u);
    chk("l0_ramdata[0].perms[0].x", dut_g.l0_ramDatas_0_entries_perms_0_x, dut_i.u_core.l0_ramdata[0].perms[0].x);
    chk("l0_ramdata[0].perms[0].w", dut_g.l0_ramDatas_0_entries_perms_0_w, dut_i.u_core.l0_ramdata[0].perms[0].w);
    chk("l0_ramdata[0].perms[0].r", dut_g.l0_ramDatas_0_entries_perms_0_r, dut_i.u_core.l0_ramdata[0].perms[0].r);
    chk("l0_ramdata[0].pbmts[1]", dut_g.l0_ramDatas_0_entries_pbmts_1, dut_i.u_core.l0_ramdata[0].pbmts[1]);
    chk("l0_ramdata[0].ppns[1]", dut_g.l0_ramDatas_0_entries_ppns_1, dut_i.u_core.l0_ramdata[0].ppns[1]);
    chk("l0_ramdata[0].onlypf[1]", dut_g.l0_ramDatas_0_entries_onlypf_1, dut_i.u_core.l0_ramdata[0].onlypf[1]);
    chk("l0_ramdata[0].perms[1].d", dut_g.l0_ramDatas_0_entries_perms_1_d, dut_i.u_core.l0_ramdata[0].perms[1].d);
    chk("l0_ramdata[0].perms[1].a", dut_g.l0_ramDatas_0_entries_perms_1_a, dut_i.u_core.l0_ramdata[0].perms[1].a);
    chk("l0_ramdata[0].perms[1].g", dut_g.l0_ramDatas_0_entries_perms_1_g, dut_i.u_core.l0_ramdata[0].perms[1].g);
    chk("l0_ramdata[0].perms[1].u", dut_g.l0_ramDatas_0_entries_perms_1_u, dut_i.u_core.l0_ramdata[0].perms[1].u);
    chk("l0_ramdata[0].perms[1].x", dut_g.l0_ramDatas_0_entries_perms_1_x, dut_i.u_core.l0_ramdata[0].perms[1].x);
    chk("l0_ramdata[0].perms[1].w", dut_g.l0_ramDatas_0_entries_perms_1_w, dut_i.u_core.l0_ramdata[0].perms[1].w);
    chk("l0_ramdata[0].perms[1].r", dut_g.l0_ramDatas_0_entries_perms_1_r, dut_i.u_core.l0_ramdata[0].perms[1].r);
    chk("l0_ramdata[0].pbmts[2]", dut_g.l0_ramDatas_0_entries_pbmts_2, dut_i.u_core.l0_ramdata[0].pbmts[2]);
    chk("l0_ramdata[0].ppns[2]", dut_g.l0_ramDatas_0_entries_ppns_2, dut_i.u_core.l0_ramdata[0].ppns[2]);
    chk("l0_ramdata[0].onlypf[2]", dut_g.l0_ramDatas_0_entries_onlypf_2, dut_i.u_core.l0_ramdata[0].onlypf[2]);
    chk("l0_ramdata[0].perms[2].d", dut_g.l0_ramDatas_0_entries_perms_2_d, dut_i.u_core.l0_ramdata[0].perms[2].d);
    chk("l0_ramdata[0].perms[2].a", dut_g.l0_ramDatas_0_entries_perms_2_a, dut_i.u_core.l0_ramdata[0].perms[2].a);
    chk("l0_ramdata[0].perms[2].g", dut_g.l0_ramDatas_0_entries_perms_2_g, dut_i.u_core.l0_ramdata[0].perms[2].g);
    chk("l0_ramdata[0].perms[2].u", dut_g.l0_ramDatas_0_entries_perms_2_u, dut_i.u_core.l0_ramdata[0].perms[2].u);
    chk("l0_ramdata[0].perms[2].x", dut_g.l0_ramDatas_0_entries_perms_2_x, dut_i.u_core.l0_ramdata[0].perms[2].x);
    chk("l0_ramdata[0].perms[2].w", dut_g.l0_ramDatas_0_entries_perms_2_w, dut_i.u_core.l0_ramdata[0].perms[2].w);
    chk("l0_ramdata[0].perms[2].r", dut_g.l0_ramDatas_0_entries_perms_2_r, dut_i.u_core.l0_ramdata[0].perms[2].r);
    chk("l0_ramdata[0].pbmts[3]", dut_g.l0_ramDatas_0_entries_pbmts_3, dut_i.u_core.l0_ramdata[0].pbmts[3]);
    chk("l0_ramdata[0].ppns[3]", dut_g.l0_ramDatas_0_entries_ppns_3, dut_i.u_core.l0_ramdata[0].ppns[3]);
    chk("l0_ramdata[0].onlypf[3]", dut_g.l0_ramDatas_0_entries_onlypf_3, dut_i.u_core.l0_ramdata[0].onlypf[3]);
    chk("l0_ramdata[0].perms[3].d", dut_g.l0_ramDatas_0_entries_perms_3_d, dut_i.u_core.l0_ramdata[0].perms[3].d);
    chk("l0_ramdata[0].perms[3].a", dut_g.l0_ramDatas_0_entries_perms_3_a, dut_i.u_core.l0_ramdata[0].perms[3].a);
    chk("l0_ramdata[0].perms[3].g", dut_g.l0_ramDatas_0_entries_perms_3_g, dut_i.u_core.l0_ramdata[0].perms[3].g);
    chk("l0_ramdata[0].perms[3].u", dut_g.l0_ramDatas_0_entries_perms_3_u, dut_i.u_core.l0_ramdata[0].perms[3].u);
    chk("l0_ramdata[0].perms[3].x", dut_g.l0_ramDatas_0_entries_perms_3_x, dut_i.u_core.l0_ramdata[0].perms[3].x);
    chk("l0_ramdata[0].perms[3].w", dut_g.l0_ramDatas_0_entries_perms_3_w, dut_i.u_core.l0_ramdata[0].perms[3].w);
    chk("l0_ramdata[0].perms[3].r", dut_g.l0_ramDatas_0_entries_perms_3_r, dut_i.u_core.l0_ramdata[0].perms[3].r);
    chk("l0_ramdata[0].pbmts[4]", dut_g.l0_ramDatas_0_entries_pbmts_4, dut_i.u_core.l0_ramdata[0].pbmts[4]);
    chk("l0_ramdata[0].ppns[4]", dut_g.l0_ramDatas_0_entries_ppns_4, dut_i.u_core.l0_ramdata[0].ppns[4]);
    chk("l0_ramdata[0].onlypf[4]", dut_g.l0_ramDatas_0_entries_onlypf_4, dut_i.u_core.l0_ramdata[0].onlypf[4]);
    chk("l0_ramdata[0].perms[4].d", dut_g.l0_ramDatas_0_entries_perms_4_d, dut_i.u_core.l0_ramdata[0].perms[4].d);
    chk("l0_ramdata[0].perms[4].a", dut_g.l0_ramDatas_0_entries_perms_4_a, dut_i.u_core.l0_ramdata[0].perms[4].a);
    chk("l0_ramdata[0].perms[4].g", dut_g.l0_ramDatas_0_entries_perms_4_g, dut_i.u_core.l0_ramdata[0].perms[4].g);
    chk("l0_ramdata[0].perms[4].u", dut_g.l0_ramDatas_0_entries_perms_4_u, dut_i.u_core.l0_ramdata[0].perms[4].u);
    chk("l0_ramdata[0].perms[4].x", dut_g.l0_ramDatas_0_entries_perms_4_x, dut_i.u_core.l0_ramdata[0].perms[4].x);
    chk("l0_ramdata[0].perms[4].w", dut_g.l0_ramDatas_0_entries_perms_4_w, dut_i.u_core.l0_ramdata[0].perms[4].w);
    chk("l0_ramdata[0].perms[4].r", dut_g.l0_ramDatas_0_entries_perms_4_r, dut_i.u_core.l0_ramdata[0].perms[4].r);
    chk("l0_ramdata[0].pbmts[5]", dut_g.l0_ramDatas_0_entries_pbmts_5, dut_i.u_core.l0_ramdata[0].pbmts[5]);
    chk("l0_ramdata[0].ppns[5]", dut_g.l0_ramDatas_0_entries_ppns_5, dut_i.u_core.l0_ramdata[0].ppns[5]);
    chk("l0_ramdata[0].onlypf[5]", dut_g.l0_ramDatas_0_entries_onlypf_5, dut_i.u_core.l0_ramdata[0].onlypf[5]);
    chk("l0_ramdata[0].perms[5].d", dut_g.l0_ramDatas_0_entries_perms_5_d, dut_i.u_core.l0_ramdata[0].perms[5].d);
    chk("l0_ramdata[0].perms[5].a", dut_g.l0_ramDatas_0_entries_perms_5_a, dut_i.u_core.l0_ramdata[0].perms[5].a);
    chk("l0_ramdata[0].perms[5].g", dut_g.l0_ramDatas_0_entries_perms_5_g, dut_i.u_core.l0_ramdata[0].perms[5].g);
    chk("l0_ramdata[0].perms[5].u", dut_g.l0_ramDatas_0_entries_perms_5_u, dut_i.u_core.l0_ramdata[0].perms[5].u);
    chk("l0_ramdata[0].perms[5].x", dut_g.l0_ramDatas_0_entries_perms_5_x, dut_i.u_core.l0_ramdata[0].perms[5].x);
    chk("l0_ramdata[0].perms[5].w", dut_g.l0_ramDatas_0_entries_perms_5_w, dut_i.u_core.l0_ramdata[0].perms[5].w);
    chk("l0_ramdata[0].perms[5].r", dut_g.l0_ramDatas_0_entries_perms_5_r, dut_i.u_core.l0_ramdata[0].perms[5].r);
    chk("l0_ramdata[0].pbmts[6]", dut_g.l0_ramDatas_0_entries_pbmts_6, dut_i.u_core.l0_ramdata[0].pbmts[6]);
    chk("l0_ramdata[0].ppns[6]", dut_g.l0_ramDatas_0_entries_ppns_6, dut_i.u_core.l0_ramdata[0].ppns[6]);
    chk("l0_ramdata[0].onlypf[6]", dut_g.l0_ramDatas_0_entries_onlypf_6, dut_i.u_core.l0_ramdata[0].onlypf[6]);
    chk("l0_ramdata[0].perms[6].d", dut_g.l0_ramDatas_0_entries_perms_6_d, dut_i.u_core.l0_ramdata[0].perms[6].d);
    chk("l0_ramdata[0].perms[6].a", dut_g.l0_ramDatas_0_entries_perms_6_a, dut_i.u_core.l0_ramdata[0].perms[6].a);
    chk("l0_ramdata[0].perms[6].g", dut_g.l0_ramDatas_0_entries_perms_6_g, dut_i.u_core.l0_ramdata[0].perms[6].g);
    chk("l0_ramdata[0].perms[6].u", dut_g.l0_ramDatas_0_entries_perms_6_u, dut_i.u_core.l0_ramdata[0].perms[6].u);
    chk("l0_ramdata[0].perms[6].x", dut_g.l0_ramDatas_0_entries_perms_6_x, dut_i.u_core.l0_ramdata[0].perms[6].x);
    chk("l0_ramdata[0].perms[6].w", dut_g.l0_ramDatas_0_entries_perms_6_w, dut_i.u_core.l0_ramdata[0].perms[6].w);
    chk("l0_ramdata[0].perms[6].r", dut_g.l0_ramDatas_0_entries_perms_6_r, dut_i.u_core.l0_ramdata[0].perms[6].r);
    chk("l0_ramdata[0].pbmts[7]", dut_g.l0_ramDatas_0_entries_pbmts_7, dut_i.u_core.l0_ramdata[0].pbmts[7]);
    chk("l0_ramdata[0].ppns[7]", dut_g.l0_ramDatas_0_entries_ppns_7, dut_i.u_core.l0_ramdata[0].ppns[7]);
    chk("l0_ramdata[0].onlypf[7]", dut_g.l0_ramDatas_0_entries_onlypf_7, dut_i.u_core.l0_ramdata[0].onlypf[7]);
    chk("l0_ramdata[0].perms[7].d", dut_g.l0_ramDatas_0_entries_perms_7_d, dut_i.u_core.l0_ramdata[0].perms[7].d);
    chk("l0_ramdata[0].perms[7].a", dut_g.l0_ramDatas_0_entries_perms_7_a, dut_i.u_core.l0_ramdata[0].perms[7].a);
    chk("l0_ramdata[0].perms[7].g", dut_g.l0_ramDatas_0_entries_perms_7_g, dut_i.u_core.l0_ramdata[0].perms[7].g);
    chk("l0_ramdata[0].perms[7].u", dut_g.l0_ramDatas_0_entries_perms_7_u, dut_i.u_core.l0_ramdata[0].perms[7].u);
    chk("l0_ramdata[0].perms[7].x", dut_g.l0_ramDatas_0_entries_perms_7_x, dut_i.u_core.l0_ramdata[0].perms[7].x);
    chk("l0_ramdata[0].perms[7].w", dut_g.l0_ramDatas_0_entries_perms_7_w, dut_i.u_core.l0_ramdata[0].perms[7].w);
    chk("l0_ramdata[0].perms[7].r", dut_g.l0_ramDatas_0_entries_perms_7_r, dut_i.u_core.l0_ramdata[0].perms[7].r);
    chk("l0_resp_r[1].tag", dut_g.data_resp_r_1_1_entries_tag, dut_i.u_core.l0_resp_r[1].tag);
    chk("l0_resp_r[1].asid", dut_g.data_resp_r_1_1_entries_asid, dut_i.u_core.l0_resp_r[1].asid);
    chk("l0_resp_r[1].vmid", dut_g.data_resp_r_1_1_entries_vmid, dut_i.u_core.l0_resp_r[1].vmid);
    chk("l0_resp_r[1].prefetch", dut_g.data_resp_r_1_1_entries_prefetch, dut_i.u_core.l0_resp_r[1].prefetch);
    chk("l0_resp_r[1].pbmts[0]", dut_g.data_resp_r_1_1_entries_pbmts_0, dut_i.u_core.l0_resp_r[1].pbmts[0]);
    chk("l0_resp_r[1].ppns[0]", dut_g.data_resp_r_1_1_entries_ppns_0, dut_i.u_core.l0_resp_r[1].ppns[0]);
    chk("l0_resp_r[1].vs[0]", dut_g.data_resp_r_1_1_entries_vs_0, dut_i.u_core.l0_resp_r[1].vs[0]);
    chk("l0_resp_r[1].onlypf[0]", dut_g.data_resp_r_1_1_entries_onlypf_0, dut_i.u_core.l0_resp_r[1].onlypf[0]);
    chk("l0_resp_r[1].perms[0].d", dut_g.data_resp_r_1_1_entries_perms_0_d, dut_i.u_core.l0_resp_r[1].perms[0].d);
    chk("l0_resp_r[1].perms[0].a", dut_g.data_resp_r_1_1_entries_perms_0_a, dut_i.u_core.l0_resp_r[1].perms[0].a);
    chk("l0_resp_r[1].perms[0].g", dut_g.data_resp_r_1_1_entries_perms_0_g, dut_i.u_core.l0_resp_r[1].perms[0].g);
    chk("l0_resp_r[1].perms[0].u", dut_g.data_resp_r_1_1_entries_perms_0_u, dut_i.u_core.l0_resp_r[1].perms[0].u);
    chk("l0_resp_r[1].perms[0].x", dut_g.data_resp_r_1_1_entries_perms_0_x, dut_i.u_core.l0_resp_r[1].perms[0].x);
    chk("l0_resp_r[1].perms[0].w", dut_g.data_resp_r_1_1_entries_perms_0_w, dut_i.u_core.l0_resp_r[1].perms[0].w);
    chk("l0_resp_r[1].perms[0].r", dut_g.data_resp_r_1_1_entries_perms_0_r, dut_i.u_core.l0_resp_r[1].perms[0].r);
    chk("l0_resp_r[1].pbmts[1]", dut_g.data_resp_r_1_1_entries_pbmts_1, dut_i.u_core.l0_resp_r[1].pbmts[1]);
    chk("l0_resp_r[1].ppns[1]", dut_g.data_resp_r_1_1_entries_ppns_1, dut_i.u_core.l0_resp_r[1].ppns[1]);
    chk("l0_resp_r[1].vs[1]", dut_g.data_resp_r_1_1_entries_vs_1, dut_i.u_core.l0_resp_r[1].vs[1]);
    chk("l0_resp_r[1].onlypf[1]", dut_g.data_resp_r_1_1_entries_onlypf_1, dut_i.u_core.l0_resp_r[1].onlypf[1]);
    chk("l0_resp_r[1].perms[1].d", dut_g.data_resp_r_1_1_entries_perms_1_d, dut_i.u_core.l0_resp_r[1].perms[1].d);
    chk("l0_resp_r[1].perms[1].a", dut_g.data_resp_r_1_1_entries_perms_1_a, dut_i.u_core.l0_resp_r[1].perms[1].a);
    chk("l0_resp_r[1].perms[1].g", dut_g.data_resp_r_1_1_entries_perms_1_g, dut_i.u_core.l0_resp_r[1].perms[1].g);
    chk("l0_resp_r[1].perms[1].u", dut_g.data_resp_r_1_1_entries_perms_1_u, dut_i.u_core.l0_resp_r[1].perms[1].u);
    chk("l0_resp_r[1].perms[1].x", dut_g.data_resp_r_1_1_entries_perms_1_x, dut_i.u_core.l0_resp_r[1].perms[1].x);
    chk("l0_resp_r[1].perms[1].w", dut_g.data_resp_r_1_1_entries_perms_1_w, dut_i.u_core.l0_resp_r[1].perms[1].w);
    chk("l0_resp_r[1].perms[1].r", dut_g.data_resp_r_1_1_entries_perms_1_r, dut_i.u_core.l0_resp_r[1].perms[1].r);
    chk("l0_resp_r[1].pbmts[2]", dut_g.data_resp_r_1_1_entries_pbmts_2, dut_i.u_core.l0_resp_r[1].pbmts[2]);
    chk("l0_resp_r[1].ppns[2]", dut_g.data_resp_r_1_1_entries_ppns_2, dut_i.u_core.l0_resp_r[1].ppns[2]);
    chk("l0_resp_r[1].vs[2]", dut_g.data_resp_r_1_1_entries_vs_2, dut_i.u_core.l0_resp_r[1].vs[2]);
    chk("l0_resp_r[1].onlypf[2]", dut_g.data_resp_r_1_1_entries_onlypf_2, dut_i.u_core.l0_resp_r[1].onlypf[2]);
    chk("l0_resp_r[1].perms[2].d", dut_g.data_resp_r_1_1_entries_perms_2_d, dut_i.u_core.l0_resp_r[1].perms[2].d);
    chk("l0_resp_r[1].perms[2].a", dut_g.data_resp_r_1_1_entries_perms_2_a, dut_i.u_core.l0_resp_r[1].perms[2].a);
    chk("l0_resp_r[1].perms[2].g", dut_g.data_resp_r_1_1_entries_perms_2_g, dut_i.u_core.l0_resp_r[1].perms[2].g);
    chk("l0_resp_r[1].perms[2].u", dut_g.data_resp_r_1_1_entries_perms_2_u, dut_i.u_core.l0_resp_r[1].perms[2].u);
    chk("l0_resp_r[1].perms[2].x", dut_g.data_resp_r_1_1_entries_perms_2_x, dut_i.u_core.l0_resp_r[1].perms[2].x);
    chk("l0_resp_r[1].perms[2].w", dut_g.data_resp_r_1_1_entries_perms_2_w, dut_i.u_core.l0_resp_r[1].perms[2].w);
    chk("l0_resp_r[1].perms[2].r", dut_g.data_resp_r_1_1_entries_perms_2_r, dut_i.u_core.l0_resp_r[1].perms[2].r);
    chk("l0_resp_r[1].pbmts[3]", dut_g.data_resp_r_1_1_entries_pbmts_3, dut_i.u_core.l0_resp_r[1].pbmts[3]);
    chk("l0_resp_r[1].ppns[3]", dut_g.data_resp_r_1_1_entries_ppns_3, dut_i.u_core.l0_resp_r[1].ppns[3]);
    chk("l0_resp_r[1].vs[3]", dut_g.data_resp_r_1_1_entries_vs_3, dut_i.u_core.l0_resp_r[1].vs[3]);
    chk("l0_resp_r[1].onlypf[3]", dut_g.data_resp_r_1_1_entries_onlypf_3, dut_i.u_core.l0_resp_r[1].onlypf[3]);
    chk("l0_resp_r[1].perms[3].d", dut_g.data_resp_r_1_1_entries_perms_3_d, dut_i.u_core.l0_resp_r[1].perms[3].d);
    chk("l0_resp_r[1].perms[3].a", dut_g.data_resp_r_1_1_entries_perms_3_a, dut_i.u_core.l0_resp_r[1].perms[3].a);
    chk("l0_resp_r[1].perms[3].g", dut_g.data_resp_r_1_1_entries_perms_3_g, dut_i.u_core.l0_resp_r[1].perms[3].g);
    chk("l0_resp_r[1].perms[3].u", dut_g.data_resp_r_1_1_entries_perms_3_u, dut_i.u_core.l0_resp_r[1].perms[3].u);
    chk("l0_resp_r[1].perms[3].x", dut_g.data_resp_r_1_1_entries_perms_3_x, dut_i.u_core.l0_resp_r[1].perms[3].x);
    chk("l0_resp_r[1].perms[3].w", dut_g.data_resp_r_1_1_entries_perms_3_w, dut_i.u_core.l0_resp_r[1].perms[3].w);
    chk("l0_resp_r[1].perms[3].r", dut_g.data_resp_r_1_1_entries_perms_3_r, dut_i.u_core.l0_resp_r[1].perms[3].r);
    chk("l0_resp_r[1].pbmts[4]", dut_g.data_resp_r_1_1_entries_pbmts_4, dut_i.u_core.l0_resp_r[1].pbmts[4]);
    chk("l0_resp_r[1].ppns[4]", dut_g.data_resp_r_1_1_entries_ppns_4, dut_i.u_core.l0_resp_r[1].ppns[4]);
    chk("l0_resp_r[1].vs[4]", dut_g.data_resp_r_1_1_entries_vs_4, dut_i.u_core.l0_resp_r[1].vs[4]);
    chk("l0_resp_r[1].onlypf[4]", dut_g.data_resp_r_1_1_entries_onlypf_4, dut_i.u_core.l0_resp_r[1].onlypf[4]);
    chk("l0_resp_r[1].perms[4].d", dut_g.data_resp_r_1_1_entries_perms_4_d, dut_i.u_core.l0_resp_r[1].perms[4].d);
    chk("l0_resp_r[1].perms[4].a", dut_g.data_resp_r_1_1_entries_perms_4_a, dut_i.u_core.l0_resp_r[1].perms[4].a);
    chk("l0_resp_r[1].perms[4].g", dut_g.data_resp_r_1_1_entries_perms_4_g, dut_i.u_core.l0_resp_r[1].perms[4].g);
    chk("l0_resp_r[1].perms[4].u", dut_g.data_resp_r_1_1_entries_perms_4_u, dut_i.u_core.l0_resp_r[1].perms[4].u);
    chk("l0_resp_r[1].perms[4].x", dut_g.data_resp_r_1_1_entries_perms_4_x, dut_i.u_core.l0_resp_r[1].perms[4].x);
    chk("l0_resp_r[1].perms[4].w", dut_g.data_resp_r_1_1_entries_perms_4_w, dut_i.u_core.l0_resp_r[1].perms[4].w);
    chk("l0_resp_r[1].perms[4].r", dut_g.data_resp_r_1_1_entries_perms_4_r, dut_i.u_core.l0_resp_r[1].perms[4].r);
    chk("l0_resp_r[1].pbmts[5]", dut_g.data_resp_r_1_1_entries_pbmts_5, dut_i.u_core.l0_resp_r[1].pbmts[5]);
    chk("l0_resp_r[1].ppns[5]", dut_g.data_resp_r_1_1_entries_ppns_5, dut_i.u_core.l0_resp_r[1].ppns[5]);
    chk("l0_resp_r[1].vs[5]", dut_g.data_resp_r_1_1_entries_vs_5, dut_i.u_core.l0_resp_r[1].vs[5]);
    chk("l0_resp_r[1].onlypf[5]", dut_g.data_resp_r_1_1_entries_onlypf_5, dut_i.u_core.l0_resp_r[1].onlypf[5]);
    chk("l0_resp_r[1].perms[5].d", dut_g.data_resp_r_1_1_entries_perms_5_d, dut_i.u_core.l0_resp_r[1].perms[5].d);
    chk("l0_resp_r[1].perms[5].a", dut_g.data_resp_r_1_1_entries_perms_5_a, dut_i.u_core.l0_resp_r[1].perms[5].a);
    chk("l0_resp_r[1].perms[5].g", dut_g.data_resp_r_1_1_entries_perms_5_g, dut_i.u_core.l0_resp_r[1].perms[5].g);
    chk("l0_resp_r[1].perms[5].u", dut_g.data_resp_r_1_1_entries_perms_5_u, dut_i.u_core.l0_resp_r[1].perms[5].u);
    chk("l0_resp_r[1].perms[5].x", dut_g.data_resp_r_1_1_entries_perms_5_x, dut_i.u_core.l0_resp_r[1].perms[5].x);
    chk("l0_resp_r[1].perms[5].w", dut_g.data_resp_r_1_1_entries_perms_5_w, dut_i.u_core.l0_resp_r[1].perms[5].w);
    chk("l0_resp_r[1].perms[5].r", dut_g.data_resp_r_1_1_entries_perms_5_r, dut_i.u_core.l0_resp_r[1].perms[5].r);
    chk("l0_resp_r[1].pbmts[6]", dut_g.data_resp_r_1_1_entries_pbmts_6, dut_i.u_core.l0_resp_r[1].pbmts[6]);
    chk("l0_resp_r[1].ppns[6]", dut_g.data_resp_r_1_1_entries_ppns_6, dut_i.u_core.l0_resp_r[1].ppns[6]);
    chk("l0_resp_r[1].vs[6]", dut_g.data_resp_r_1_1_entries_vs_6, dut_i.u_core.l0_resp_r[1].vs[6]);
    chk("l0_resp_r[1].onlypf[6]", dut_g.data_resp_r_1_1_entries_onlypf_6, dut_i.u_core.l0_resp_r[1].onlypf[6]);
    chk("l0_resp_r[1].perms[6].d", dut_g.data_resp_r_1_1_entries_perms_6_d, dut_i.u_core.l0_resp_r[1].perms[6].d);
    chk("l0_resp_r[1].perms[6].a", dut_g.data_resp_r_1_1_entries_perms_6_a, dut_i.u_core.l0_resp_r[1].perms[6].a);
    chk("l0_resp_r[1].perms[6].g", dut_g.data_resp_r_1_1_entries_perms_6_g, dut_i.u_core.l0_resp_r[1].perms[6].g);
    chk("l0_resp_r[1].perms[6].u", dut_g.data_resp_r_1_1_entries_perms_6_u, dut_i.u_core.l0_resp_r[1].perms[6].u);
    chk("l0_resp_r[1].perms[6].x", dut_g.data_resp_r_1_1_entries_perms_6_x, dut_i.u_core.l0_resp_r[1].perms[6].x);
    chk("l0_resp_r[1].perms[6].w", dut_g.data_resp_r_1_1_entries_perms_6_w, dut_i.u_core.l0_resp_r[1].perms[6].w);
    chk("l0_resp_r[1].perms[6].r", dut_g.data_resp_r_1_1_entries_perms_6_r, dut_i.u_core.l0_resp_r[1].perms[6].r);
    chk("l0_resp_r[1].pbmts[7]", dut_g.data_resp_r_1_1_entries_pbmts_7, dut_i.u_core.l0_resp_r[1].pbmts[7]);
    chk("l0_resp_r[1].ppns[7]", dut_g.data_resp_r_1_1_entries_ppns_7, dut_i.u_core.l0_resp_r[1].ppns[7]);
    chk("l0_resp_r[1].vs[7]", dut_g.data_resp_r_1_1_entries_vs_7, dut_i.u_core.l0_resp_r[1].vs[7]);
    chk("l0_resp_r[1].onlypf[7]", dut_g.data_resp_r_1_1_entries_onlypf_7, dut_i.u_core.l0_resp_r[1].onlypf[7]);
    chk("l0_resp_r[1].perms[7].d", dut_g.data_resp_r_1_1_entries_perms_7_d, dut_i.u_core.l0_resp_r[1].perms[7].d);
    chk("l0_resp_r[1].perms[7].a", dut_g.data_resp_r_1_1_entries_perms_7_a, dut_i.u_core.l0_resp_r[1].perms[7].a);
    chk("l0_resp_r[1].perms[7].g", dut_g.data_resp_r_1_1_entries_perms_7_g, dut_i.u_core.l0_resp_r[1].perms[7].g);
    chk("l0_resp_r[1].perms[7].u", dut_g.data_resp_r_1_1_entries_perms_7_u, dut_i.u_core.l0_resp_r[1].perms[7].u);
    chk("l0_resp_r[1].perms[7].x", dut_g.data_resp_r_1_1_entries_perms_7_x, dut_i.u_core.l0_resp_r[1].perms[7].x);
    chk("l0_resp_r[1].perms[7].w", dut_g.data_resp_r_1_1_entries_perms_7_w, dut_i.u_core.l0_resp_r[1].perms[7].w);
    chk("l0_resp_r[1].perms[7].r", dut_g.data_resp_r_1_1_entries_perms_7_r, dut_i.u_core.l0_resp_r[1].perms[7].r);
    chk("l0_ramdata[1].prefetch", dut_g.l0_ramDatas_1_entries_prefetch, dut_i.u_core.l0_ramdata[1].prefetch);
    chk("l0_ramdata[1].pbmts[0]", dut_g.l0_ramDatas_1_entries_pbmts_0, dut_i.u_core.l0_ramdata[1].pbmts[0]);
    chk("l0_ramdata[1].ppns[0]", dut_g.l0_ramDatas_1_entries_ppns_0, dut_i.u_core.l0_ramdata[1].ppns[0]);
    chk("l0_ramdata[1].onlypf[0]", dut_g.l0_ramDatas_1_entries_onlypf_0, dut_i.u_core.l0_ramdata[1].onlypf[0]);
    chk("l0_ramdata[1].perms[0].d", dut_g.l0_ramDatas_1_entries_perms_0_d, dut_i.u_core.l0_ramdata[1].perms[0].d);
    chk("l0_ramdata[1].perms[0].a", dut_g.l0_ramDatas_1_entries_perms_0_a, dut_i.u_core.l0_ramdata[1].perms[0].a);
    chk("l0_ramdata[1].perms[0].g", dut_g.l0_ramDatas_1_entries_perms_0_g, dut_i.u_core.l0_ramdata[1].perms[0].g);
    chk("l0_ramdata[1].perms[0].u", dut_g.l0_ramDatas_1_entries_perms_0_u, dut_i.u_core.l0_ramdata[1].perms[0].u);
    chk("l0_ramdata[1].perms[0].x", dut_g.l0_ramDatas_1_entries_perms_0_x, dut_i.u_core.l0_ramdata[1].perms[0].x);
    chk("l0_ramdata[1].perms[0].w", dut_g.l0_ramDatas_1_entries_perms_0_w, dut_i.u_core.l0_ramdata[1].perms[0].w);
    chk("l0_ramdata[1].perms[0].r", dut_g.l0_ramDatas_1_entries_perms_0_r, dut_i.u_core.l0_ramdata[1].perms[0].r);
    chk("l0_ramdata[1].pbmts[1]", dut_g.l0_ramDatas_1_entries_pbmts_1, dut_i.u_core.l0_ramdata[1].pbmts[1]);
    chk("l0_ramdata[1].ppns[1]", dut_g.l0_ramDatas_1_entries_ppns_1, dut_i.u_core.l0_ramdata[1].ppns[1]);
    chk("l0_ramdata[1].onlypf[1]", dut_g.l0_ramDatas_1_entries_onlypf_1, dut_i.u_core.l0_ramdata[1].onlypf[1]);
    chk("l0_ramdata[1].perms[1].d", dut_g.l0_ramDatas_1_entries_perms_1_d, dut_i.u_core.l0_ramdata[1].perms[1].d);
    chk("l0_ramdata[1].perms[1].a", dut_g.l0_ramDatas_1_entries_perms_1_a, dut_i.u_core.l0_ramdata[1].perms[1].a);
    chk("l0_ramdata[1].perms[1].g", dut_g.l0_ramDatas_1_entries_perms_1_g, dut_i.u_core.l0_ramdata[1].perms[1].g);
    chk("l0_ramdata[1].perms[1].u", dut_g.l0_ramDatas_1_entries_perms_1_u, dut_i.u_core.l0_ramdata[1].perms[1].u);
    chk("l0_ramdata[1].perms[1].x", dut_g.l0_ramDatas_1_entries_perms_1_x, dut_i.u_core.l0_ramdata[1].perms[1].x);
    chk("l0_ramdata[1].perms[1].w", dut_g.l0_ramDatas_1_entries_perms_1_w, dut_i.u_core.l0_ramdata[1].perms[1].w);
    chk("l0_ramdata[1].perms[1].r", dut_g.l0_ramDatas_1_entries_perms_1_r, dut_i.u_core.l0_ramdata[1].perms[1].r);
    chk("l0_ramdata[1].pbmts[2]", dut_g.l0_ramDatas_1_entries_pbmts_2, dut_i.u_core.l0_ramdata[1].pbmts[2]);
    chk("l0_ramdata[1].ppns[2]", dut_g.l0_ramDatas_1_entries_ppns_2, dut_i.u_core.l0_ramdata[1].ppns[2]);
    chk("l0_ramdata[1].onlypf[2]", dut_g.l0_ramDatas_1_entries_onlypf_2, dut_i.u_core.l0_ramdata[1].onlypf[2]);
    chk("l0_ramdata[1].perms[2].d", dut_g.l0_ramDatas_1_entries_perms_2_d, dut_i.u_core.l0_ramdata[1].perms[2].d);
    chk("l0_ramdata[1].perms[2].a", dut_g.l0_ramDatas_1_entries_perms_2_a, dut_i.u_core.l0_ramdata[1].perms[2].a);
    chk("l0_ramdata[1].perms[2].g", dut_g.l0_ramDatas_1_entries_perms_2_g, dut_i.u_core.l0_ramdata[1].perms[2].g);
    chk("l0_ramdata[1].perms[2].u", dut_g.l0_ramDatas_1_entries_perms_2_u, dut_i.u_core.l0_ramdata[1].perms[2].u);
    chk("l0_ramdata[1].perms[2].x", dut_g.l0_ramDatas_1_entries_perms_2_x, dut_i.u_core.l0_ramdata[1].perms[2].x);
    chk("l0_ramdata[1].perms[2].w", dut_g.l0_ramDatas_1_entries_perms_2_w, dut_i.u_core.l0_ramdata[1].perms[2].w);
    chk("l0_ramdata[1].perms[2].r", dut_g.l0_ramDatas_1_entries_perms_2_r, dut_i.u_core.l0_ramdata[1].perms[2].r);
    chk("l0_ramdata[1].pbmts[3]", dut_g.l0_ramDatas_1_entries_pbmts_3, dut_i.u_core.l0_ramdata[1].pbmts[3]);
    chk("l0_ramdata[1].ppns[3]", dut_g.l0_ramDatas_1_entries_ppns_3, dut_i.u_core.l0_ramdata[1].ppns[3]);
    chk("l0_ramdata[1].onlypf[3]", dut_g.l0_ramDatas_1_entries_onlypf_3, dut_i.u_core.l0_ramdata[1].onlypf[3]);
    chk("l0_ramdata[1].perms[3].d", dut_g.l0_ramDatas_1_entries_perms_3_d, dut_i.u_core.l0_ramdata[1].perms[3].d);
    chk("l0_ramdata[1].perms[3].a", dut_g.l0_ramDatas_1_entries_perms_3_a, dut_i.u_core.l0_ramdata[1].perms[3].a);
    chk("l0_ramdata[1].perms[3].g", dut_g.l0_ramDatas_1_entries_perms_3_g, dut_i.u_core.l0_ramdata[1].perms[3].g);
    chk("l0_ramdata[1].perms[3].u", dut_g.l0_ramDatas_1_entries_perms_3_u, dut_i.u_core.l0_ramdata[1].perms[3].u);
    chk("l0_ramdata[1].perms[3].x", dut_g.l0_ramDatas_1_entries_perms_3_x, dut_i.u_core.l0_ramdata[1].perms[3].x);
    chk("l0_ramdata[1].perms[3].w", dut_g.l0_ramDatas_1_entries_perms_3_w, dut_i.u_core.l0_ramdata[1].perms[3].w);
    chk("l0_ramdata[1].perms[3].r", dut_g.l0_ramDatas_1_entries_perms_3_r, dut_i.u_core.l0_ramdata[1].perms[3].r);
    chk("l0_ramdata[1].pbmts[4]", dut_g.l0_ramDatas_1_entries_pbmts_4, dut_i.u_core.l0_ramdata[1].pbmts[4]);
    chk("l0_ramdata[1].ppns[4]", dut_g.l0_ramDatas_1_entries_ppns_4, dut_i.u_core.l0_ramdata[1].ppns[4]);
    chk("l0_ramdata[1].onlypf[4]", dut_g.l0_ramDatas_1_entries_onlypf_4, dut_i.u_core.l0_ramdata[1].onlypf[4]);
    chk("l0_ramdata[1].perms[4].d", dut_g.l0_ramDatas_1_entries_perms_4_d, dut_i.u_core.l0_ramdata[1].perms[4].d);
    chk("l0_ramdata[1].perms[4].a", dut_g.l0_ramDatas_1_entries_perms_4_a, dut_i.u_core.l0_ramdata[1].perms[4].a);
    chk("l0_ramdata[1].perms[4].g", dut_g.l0_ramDatas_1_entries_perms_4_g, dut_i.u_core.l0_ramdata[1].perms[4].g);
    chk("l0_ramdata[1].perms[4].u", dut_g.l0_ramDatas_1_entries_perms_4_u, dut_i.u_core.l0_ramdata[1].perms[4].u);
    chk("l0_ramdata[1].perms[4].x", dut_g.l0_ramDatas_1_entries_perms_4_x, dut_i.u_core.l0_ramdata[1].perms[4].x);
    chk("l0_ramdata[1].perms[4].w", dut_g.l0_ramDatas_1_entries_perms_4_w, dut_i.u_core.l0_ramdata[1].perms[4].w);
    chk("l0_ramdata[1].perms[4].r", dut_g.l0_ramDatas_1_entries_perms_4_r, dut_i.u_core.l0_ramdata[1].perms[4].r);
    chk("l0_ramdata[1].pbmts[5]", dut_g.l0_ramDatas_1_entries_pbmts_5, dut_i.u_core.l0_ramdata[1].pbmts[5]);
    chk("l0_ramdata[1].ppns[5]", dut_g.l0_ramDatas_1_entries_ppns_5, dut_i.u_core.l0_ramdata[1].ppns[5]);
    chk("l0_ramdata[1].onlypf[5]", dut_g.l0_ramDatas_1_entries_onlypf_5, dut_i.u_core.l0_ramdata[1].onlypf[5]);
    chk("l0_ramdata[1].perms[5].d", dut_g.l0_ramDatas_1_entries_perms_5_d, dut_i.u_core.l0_ramdata[1].perms[5].d);
    chk("l0_ramdata[1].perms[5].a", dut_g.l0_ramDatas_1_entries_perms_5_a, dut_i.u_core.l0_ramdata[1].perms[5].a);
    chk("l0_ramdata[1].perms[5].g", dut_g.l0_ramDatas_1_entries_perms_5_g, dut_i.u_core.l0_ramdata[1].perms[5].g);
    chk("l0_ramdata[1].perms[5].u", dut_g.l0_ramDatas_1_entries_perms_5_u, dut_i.u_core.l0_ramdata[1].perms[5].u);
    chk("l0_ramdata[1].perms[5].x", dut_g.l0_ramDatas_1_entries_perms_5_x, dut_i.u_core.l0_ramdata[1].perms[5].x);
    chk("l0_ramdata[1].perms[5].w", dut_g.l0_ramDatas_1_entries_perms_5_w, dut_i.u_core.l0_ramdata[1].perms[5].w);
    chk("l0_ramdata[1].perms[5].r", dut_g.l0_ramDatas_1_entries_perms_5_r, dut_i.u_core.l0_ramdata[1].perms[5].r);
    chk("l0_ramdata[1].pbmts[6]", dut_g.l0_ramDatas_1_entries_pbmts_6, dut_i.u_core.l0_ramdata[1].pbmts[6]);
    chk("l0_ramdata[1].ppns[6]", dut_g.l0_ramDatas_1_entries_ppns_6, dut_i.u_core.l0_ramdata[1].ppns[6]);
    chk("l0_ramdata[1].onlypf[6]", dut_g.l0_ramDatas_1_entries_onlypf_6, dut_i.u_core.l0_ramdata[1].onlypf[6]);
    chk("l0_ramdata[1].perms[6].d", dut_g.l0_ramDatas_1_entries_perms_6_d, dut_i.u_core.l0_ramdata[1].perms[6].d);
    chk("l0_ramdata[1].perms[6].a", dut_g.l0_ramDatas_1_entries_perms_6_a, dut_i.u_core.l0_ramdata[1].perms[6].a);
    chk("l0_ramdata[1].perms[6].g", dut_g.l0_ramDatas_1_entries_perms_6_g, dut_i.u_core.l0_ramdata[1].perms[6].g);
    chk("l0_ramdata[1].perms[6].u", dut_g.l0_ramDatas_1_entries_perms_6_u, dut_i.u_core.l0_ramdata[1].perms[6].u);
    chk("l0_ramdata[1].perms[6].x", dut_g.l0_ramDatas_1_entries_perms_6_x, dut_i.u_core.l0_ramdata[1].perms[6].x);
    chk("l0_ramdata[1].perms[6].w", dut_g.l0_ramDatas_1_entries_perms_6_w, dut_i.u_core.l0_ramdata[1].perms[6].w);
    chk("l0_ramdata[1].perms[6].r", dut_g.l0_ramDatas_1_entries_perms_6_r, dut_i.u_core.l0_ramdata[1].perms[6].r);
    chk("l0_ramdata[1].pbmts[7]", dut_g.l0_ramDatas_1_entries_pbmts_7, dut_i.u_core.l0_ramdata[1].pbmts[7]);
    chk("l0_ramdata[1].ppns[7]", dut_g.l0_ramDatas_1_entries_ppns_7, dut_i.u_core.l0_ramdata[1].ppns[7]);
    chk("l0_ramdata[1].onlypf[7]", dut_g.l0_ramDatas_1_entries_onlypf_7, dut_i.u_core.l0_ramdata[1].onlypf[7]);
    chk("l0_ramdata[1].perms[7].d", dut_g.l0_ramDatas_1_entries_perms_7_d, dut_i.u_core.l0_ramdata[1].perms[7].d);
    chk("l0_ramdata[1].perms[7].a", dut_g.l0_ramDatas_1_entries_perms_7_a, dut_i.u_core.l0_ramdata[1].perms[7].a);
    chk("l0_ramdata[1].perms[7].g", dut_g.l0_ramDatas_1_entries_perms_7_g, dut_i.u_core.l0_ramdata[1].perms[7].g);
    chk("l0_ramdata[1].perms[7].u", dut_g.l0_ramDatas_1_entries_perms_7_u, dut_i.u_core.l0_ramdata[1].perms[7].u);
    chk("l0_ramdata[1].perms[7].x", dut_g.l0_ramDatas_1_entries_perms_7_x, dut_i.u_core.l0_ramdata[1].perms[7].x);
    chk("l0_ramdata[1].perms[7].w", dut_g.l0_ramDatas_1_entries_perms_7_w, dut_i.u_core.l0_ramdata[1].perms[7].w);
    chk("l0_ramdata[1].perms[7].r", dut_g.l0_ramDatas_1_entries_perms_7_r, dut_i.u_core.l0_ramdata[1].perms[7].r);
    chk("l0_resp_r[2].tag", dut_g.data_resp_r_1_2_entries_tag, dut_i.u_core.l0_resp_r[2].tag);
    chk("l0_resp_r[2].asid", dut_g.data_resp_r_1_2_entries_asid, dut_i.u_core.l0_resp_r[2].asid);
    chk("l0_resp_r[2].vmid", dut_g.data_resp_r_1_2_entries_vmid, dut_i.u_core.l0_resp_r[2].vmid);
    chk("l0_resp_r[2].prefetch", dut_g.data_resp_r_1_2_entries_prefetch, dut_i.u_core.l0_resp_r[2].prefetch);
    chk("l0_resp_r[2].pbmts[0]", dut_g.data_resp_r_1_2_entries_pbmts_0, dut_i.u_core.l0_resp_r[2].pbmts[0]);
    chk("l0_resp_r[2].ppns[0]", dut_g.data_resp_r_1_2_entries_ppns_0, dut_i.u_core.l0_resp_r[2].ppns[0]);
    chk("l0_resp_r[2].vs[0]", dut_g.data_resp_r_1_2_entries_vs_0, dut_i.u_core.l0_resp_r[2].vs[0]);
    chk("l0_resp_r[2].onlypf[0]", dut_g.data_resp_r_1_2_entries_onlypf_0, dut_i.u_core.l0_resp_r[2].onlypf[0]);
    chk("l0_resp_r[2].perms[0].d", dut_g.data_resp_r_1_2_entries_perms_0_d, dut_i.u_core.l0_resp_r[2].perms[0].d);
    chk("l0_resp_r[2].perms[0].a", dut_g.data_resp_r_1_2_entries_perms_0_a, dut_i.u_core.l0_resp_r[2].perms[0].a);
    chk("l0_resp_r[2].perms[0].g", dut_g.data_resp_r_1_2_entries_perms_0_g, dut_i.u_core.l0_resp_r[2].perms[0].g);
    chk("l0_resp_r[2].perms[0].u", dut_g.data_resp_r_1_2_entries_perms_0_u, dut_i.u_core.l0_resp_r[2].perms[0].u);
    chk("l0_resp_r[2].perms[0].x", dut_g.data_resp_r_1_2_entries_perms_0_x, dut_i.u_core.l0_resp_r[2].perms[0].x);
    chk("l0_resp_r[2].perms[0].w", dut_g.data_resp_r_1_2_entries_perms_0_w, dut_i.u_core.l0_resp_r[2].perms[0].w);
    chk("l0_resp_r[2].perms[0].r", dut_g.data_resp_r_1_2_entries_perms_0_r, dut_i.u_core.l0_resp_r[2].perms[0].r);
    chk("l0_resp_r[2].pbmts[1]", dut_g.data_resp_r_1_2_entries_pbmts_1, dut_i.u_core.l0_resp_r[2].pbmts[1]);
    chk("l0_resp_r[2].ppns[1]", dut_g.data_resp_r_1_2_entries_ppns_1, dut_i.u_core.l0_resp_r[2].ppns[1]);
    chk("l0_resp_r[2].vs[1]", dut_g.data_resp_r_1_2_entries_vs_1, dut_i.u_core.l0_resp_r[2].vs[1]);
    chk("l0_resp_r[2].onlypf[1]", dut_g.data_resp_r_1_2_entries_onlypf_1, dut_i.u_core.l0_resp_r[2].onlypf[1]);
    chk("l0_resp_r[2].perms[1].d", dut_g.data_resp_r_1_2_entries_perms_1_d, dut_i.u_core.l0_resp_r[2].perms[1].d);
    chk("l0_resp_r[2].perms[1].a", dut_g.data_resp_r_1_2_entries_perms_1_a, dut_i.u_core.l0_resp_r[2].perms[1].a);
    chk("l0_resp_r[2].perms[1].g", dut_g.data_resp_r_1_2_entries_perms_1_g, dut_i.u_core.l0_resp_r[2].perms[1].g);
    chk("l0_resp_r[2].perms[1].u", dut_g.data_resp_r_1_2_entries_perms_1_u, dut_i.u_core.l0_resp_r[2].perms[1].u);
    chk("l0_resp_r[2].perms[1].x", dut_g.data_resp_r_1_2_entries_perms_1_x, dut_i.u_core.l0_resp_r[2].perms[1].x);
    chk("l0_resp_r[2].perms[1].w", dut_g.data_resp_r_1_2_entries_perms_1_w, dut_i.u_core.l0_resp_r[2].perms[1].w);
    chk("l0_resp_r[2].perms[1].r", dut_g.data_resp_r_1_2_entries_perms_1_r, dut_i.u_core.l0_resp_r[2].perms[1].r);
    chk("l0_resp_r[2].pbmts[2]", dut_g.data_resp_r_1_2_entries_pbmts_2, dut_i.u_core.l0_resp_r[2].pbmts[2]);
    chk("l0_resp_r[2].ppns[2]", dut_g.data_resp_r_1_2_entries_ppns_2, dut_i.u_core.l0_resp_r[2].ppns[2]);
    chk("l0_resp_r[2].vs[2]", dut_g.data_resp_r_1_2_entries_vs_2, dut_i.u_core.l0_resp_r[2].vs[2]);
    chk("l0_resp_r[2].onlypf[2]", dut_g.data_resp_r_1_2_entries_onlypf_2, dut_i.u_core.l0_resp_r[2].onlypf[2]);
    chk("l0_resp_r[2].perms[2].d", dut_g.data_resp_r_1_2_entries_perms_2_d, dut_i.u_core.l0_resp_r[2].perms[2].d);
    chk("l0_resp_r[2].perms[2].a", dut_g.data_resp_r_1_2_entries_perms_2_a, dut_i.u_core.l0_resp_r[2].perms[2].a);
    chk("l0_resp_r[2].perms[2].g", dut_g.data_resp_r_1_2_entries_perms_2_g, dut_i.u_core.l0_resp_r[2].perms[2].g);
    chk("l0_resp_r[2].perms[2].u", dut_g.data_resp_r_1_2_entries_perms_2_u, dut_i.u_core.l0_resp_r[2].perms[2].u);
    chk("l0_resp_r[2].perms[2].x", dut_g.data_resp_r_1_2_entries_perms_2_x, dut_i.u_core.l0_resp_r[2].perms[2].x);
    chk("l0_resp_r[2].perms[2].w", dut_g.data_resp_r_1_2_entries_perms_2_w, dut_i.u_core.l0_resp_r[2].perms[2].w);
    chk("l0_resp_r[2].perms[2].r", dut_g.data_resp_r_1_2_entries_perms_2_r, dut_i.u_core.l0_resp_r[2].perms[2].r);
    chk("l0_resp_r[2].pbmts[3]", dut_g.data_resp_r_1_2_entries_pbmts_3, dut_i.u_core.l0_resp_r[2].pbmts[3]);
    chk("l0_resp_r[2].ppns[3]", dut_g.data_resp_r_1_2_entries_ppns_3, dut_i.u_core.l0_resp_r[2].ppns[3]);
    chk("l0_resp_r[2].vs[3]", dut_g.data_resp_r_1_2_entries_vs_3, dut_i.u_core.l0_resp_r[2].vs[3]);
    chk("l0_resp_r[2].onlypf[3]", dut_g.data_resp_r_1_2_entries_onlypf_3, dut_i.u_core.l0_resp_r[2].onlypf[3]);
    chk("l0_resp_r[2].perms[3].d", dut_g.data_resp_r_1_2_entries_perms_3_d, dut_i.u_core.l0_resp_r[2].perms[3].d);
    chk("l0_resp_r[2].perms[3].a", dut_g.data_resp_r_1_2_entries_perms_3_a, dut_i.u_core.l0_resp_r[2].perms[3].a);
    chk("l0_resp_r[2].perms[3].g", dut_g.data_resp_r_1_2_entries_perms_3_g, dut_i.u_core.l0_resp_r[2].perms[3].g);
    chk("l0_resp_r[2].perms[3].u", dut_g.data_resp_r_1_2_entries_perms_3_u, dut_i.u_core.l0_resp_r[2].perms[3].u);
    chk("l0_resp_r[2].perms[3].x", dut_g.data_resp_r_1_2_entries_perms_3_x, dut_i.u_core.l0_resp_r[2].perms[3].x);
    chk("l0_resp_r[2].perms[3].w", dut_g.data_resp_r_1_2_entries_perms_3_w, dut_i.u_core.l0_resp_r[2].perms[3].w);
    chk("l0_resp_r[2].perms[3].r", dut_g.data_resp_r_1_2_entries_perms_3_r, dut_i.u_core.l0_resp_r[2].perms[3].r);
    chk("l0_resp_r[2].pbmts[4]", dut_g.data_resp_r_1_2_entries_pbmts_4, dut_i.u_core.l0_resp_r[2].pbmts[4]);
    chk("l0_resp_r[2].ppns[4]", dut_g.data_resp_r_1_2_entries_ppns_4, dut_i.u_core.l0_resp_r[2].ppns[4]);
    chk("l0_resp_r[2].vs[4]", dut_g.data_resp_r_1_2_entries_vs_4, dut_i.u_core.l0_resp_r[2].vs[4]);
    chk("l0_resp_r[2].onlypf[4]", dut_g.data_resp_r_1_2_entries_onlypf_4, dut_i.u_core.l0_resp_r[2].onlypf[4]);
    chk("l0_resp_r[2].perms[4].d", dut_g.data_resp_r_1_2_entries_perms_4_d, dut_i.u_core.l0_resp_r[2].perms[4].d);
    chk("l0_resp_r[2].perms[4].a", dut_g.data_resp_r_1_2_entries_perms_4_a, dut_i.u_core.l0_resp_r[2].perms[4].a);
    chk("l0_resp_r[2].perms[4].g", dut_g.data_resp_r_1_2_entries_perms_4_g, dut_i.u_core.l0_resp_r[2].perms[4].g);
    chk("l0_resp_r[2].perms[4].u", dut_g.data_resp_r_1_2_entries_perms_4_u, dut_i.u_core.l0_resp_r[2].perms[4].u);
    chk("l0_resp_r[2].perms[4].x", dut_g.data_resp_r_1_2_entries_perms_4_x, dut_i.u_core.l0_resp_r[2].perms[4].x);
    chk("l0_resp_r[2].perms[4].w", dut_g.data_resp_r_1_2_entries_perms_4_w, dut_i.u_core.l0_resp_r[2].perms[4].w);
    chk("l0_resp_r[2].perms[4].r", dut_g.data_resp_r_1_2_entries_perms_4_r, dut_i.u_core.l0_resp_r[2].perms[4].r);
    chk("l0_resp_r[2].pbmts[5]", dut_g.data_resp_r_1_2_entries_pbmts_5, dut_i.u_core.l0_resp_r[2].pbmts[5]);
    chk("l0_resp_r[2].ppns[5]", dut_g.data_resp_r_1_2_entries_ppns_5, dut_i.u_core.l0_resp_r[2].ppns[5]);
    chk("l0_resp_r[2].vs[5]", dut_g.data_resp_r_1_2_entries_vs_5, dut_i.u_core.l0_resp_r[2].vs[5]);
    chk("l0_resp_r[2].onlypf[5]", dut_g.data_resp_r_1_2_entries_onlypf_5, dut_i.u_core.l0_resp_r[2].onlypf[5]);
    chk("l0_resp_r[2].perms[5].d", dut_g.data_resp_r_1_2_entries_perms_5_d, dut_i.u_core.l0_resp_r[2].perms[5].d);
    chk("l0_resp_r[2].perms[5].a", dut_g.data_resp_r_1_2_entries_perms_5_a, dut_i.u_core.l0_resp_r[2].perms[5].a);
    chk("l0_resp_r[2].perms[5].g", dut_g.data_resp_r_1_2_entries_perms_5_g, dut_i.u_core.l0_resp_r[2].perms[5].g);
    chk("l0_resp_r[2].perms[5].u", dut_g.data_resp_r_1_2_entries_perms_5_u, dut_i.u_core.l0_resp_r[2].perms[5].u);
    chk("l0_resp_r[2].perms[5].x", dut_g.data_resp_r_1_2_entries_perms_5_x, dut_i.u_core.l0_resp_r[2].perms[5].x);
    chk("l0_resp_r[2].perms[5].w", dut_g.data_resp_r_1_2_entries_perms_5_w, dut_i.u_core.l0_resp_r[2].perms[5].w);
    chk("l0_resp_r[2].perms[5].r", dut_g.data_resp_r_1_2_entries_perms_5_r, dut_i.u_core.l0_resp_r[2].perms[5].r);
    chk("l0_resp_r[2].pbmts[6]", dut_g.data_resp_r_1_2_entries_pbmts_6, dut_i.u_core.l0_resp_r[2].pbmts[6]);
    chk("l0_resp_r[2].ppns[6]", dut_g.data_resp_r_1_2_entries_ppns_6, dut_i.u_core.l0_resp_r[2].ppns[6]);
    chk("l0_resp_r[2].vs[6]", dut_g.data_resp_r_1_2_entries_vs_6, dut_i.u_core.l0_resp_r[2].vs[6]);
    chk("l0_resp_r[2].onlypf[6]", dut_g.data_resp_r_1_2_entries_onlypf_6, dut_i.u_core.l0_resp_r[2].onlypf[6]);
    chk("l0_resp_r[2].perms[6].d", dut_g.data_resp_r_1_2_entries_perms_6_d, dut_i.u_core.l0_resp_r[2].perms[6].d);
    chk("l0_resp_r[2].perms[6].a", dut_g.data_resp_r_1_2_entries_perms_6_a, dut_i.u_core.l0_resp_r[2].perms[6].a);
    chk("l0_resp_r[2].perms[6].g", dut_g.data_resp_r_1_2_entries_perms_6_g, dut_i.u_core.l0_resp_r[2].perms[6].g);
    chk("l0_resp_r[2].perms[6].u", dut_g.data_resp_r_1_2_entries_perms_6_u, dut_i.u_core.l0_resp_r[2].perms[6].u);
    chk("l0_resp_r[2].perms[6].x", dut_g.data_resp_r_1_2_entries_perms_6_x, dut_i.u_core.l0_resp_r[2].perms[6].x);
    chk("l0_resp_r[2].perms[6].w", dut_g.data_resp_r_1_2_entries_perms_6_w, dut_i.u_core.l0_resp_r[2].perms[6].w);
    chk("l0_resp_r[2].perms[6].r", dut_g.data_resp_r_1_2_entries_perms_6_r, dut_i.u_core.l0_resp_r[2].perms[6].r);
    chk("l0_resp_r[2].pbmts[7]", dut_g.data_resp_r_1_2_entries_pbmts_7, dut_i.u_core.l0_resp_r[2].pbmts[7]);
    chk("l0_resp_r[2].ppns[7]", dut_g.data_resp_r_1_2_entries_ppns_7, dut_i.u_core.l0_resp_r[2].ppns[7]);
    chk("l0_resp_r[2].vs[7]", dut_g.data_resp_r_1_2_entries_vs_7, dut_i.u_core.l0_resp_r[2].vs[7]);
    chk("l0_resp_r[2].onlypf[7]", dut_g.data_resp_r_1_2_entries_onlypf_7, dut_i.u_core.l0_resp_r[2].onlypf[7]);
    chk("l0_resp_r[2].perms[7].d", dut_g.data_resp_r_1_2_entries_perms_7_d, dut_i.u_core.l0_resp_r[2].perms[7].d);
    chk("l0_resp_r[2].perms[7].a", dut_g.data_resp_r_1_2_entries_perms_7_a, dut_i.u_core.l0_resp_r[2].perms[7].a);
    chk("l0_resp_r[2].perms[7].g", dut_g.data_resp_r_1_2_entries_perms_7_g, dut_i.u_core.l0_resp_r[2].perms[7].g);
    chk("l0_resp_r[2].perms[7].u", dut_g.data_resp_r_1_2_entries_perms_7_u, dut_i.u_core.l0_resp_r[2].perms[7].u);
    chk("l0_resp_r[2].perms[7].x", dut_g.data_resp_r_1_2_entries_perms_7_x, dut_i.u_core.l0_resp_r[2].perms[7].x);
    chk("l0_resp_r[2].perms[7].w", dut_g.data_resp_r_1_2_entries_perms_7_w, dut_i.u_core.l0_resp_r[2].perms[7].w);
    chk("l0_resp_r[2].perms[7].r", dut_g.data_resp_r_1_2_entries_perms_7_r, dut_i.u_core.l0_resp_r[2].perms[7].r);
    chk("l0_ramdata[2].prefetch", dut_g.l0_ramDatas_2_entries_prefetch, dut_i.u_core.l0_ramdata[2].prefetch);
    chk("l0_ramdata[2].pbmts[0]", dut_g.l0_ramDatas_2_entries_pbmts_0, dut_i.u_core.l0_ramdata[2].pbmts[0]);
    chk("l0_ramdata[2].ppns[0]", dut_g.l0_ramDatas_2_entries_ppns_0, dut_i.u_core.l0_ramdata[2].ppns[0]);
    chk("l0_ramdata[2].onlypf[0]", dut_g.l0_ramDatas_2_entries_onlypf_0, dut_i.u_core.l0_ramdata[2].onlypf[0]);
    chk("l0_ramdata[2].perms[0].d", dut_g.l0_ramDatas_2_entries_perms_0_d, dut_i.u_core.l0_ramdata[2].perms[0].d);
    chk("l0_ramdata[2].perms[0].a", dut_g.l0_ramDatas_2_entries_perms_0_a, dut_i.u_core.l0_ramdata[2].perms[0].a);
    chk("l0_ramdata[2].perms[0].g", dut_g.l0_ramDatas_2_entries_perms_0_g, dut_i.u_core.l0_ramdata[2].perms[0].g);
    chk("l0_ramdata[2].perms[0].u", dut_g.l0_ramDatas_2_entries_perms_0_u, dut_i.u_core.l0_ramdata[2].perms[0].u);
    chk("l0_ramdata[2].perms[0].x", dut_g.l0_ramDatas_2_entries_perms_0_x, dut_i.u_core.l0_ramdata[2].perms[0].x);
    chk("l0_ramdata[2].perms[0].w", dut_g.l0_ramDatas_2_entries_perms_0_w, dut_i.u_core.l0_ramdata[2].perms[0].w);
    chk("l0_ramdata[2].perms[0].r", dut_g.l0_ramDatas_2_entries_perms_0_r, dut_i.u_core.l0_ramdata[2].perms[0].r);
    chk("l0_ramdata[2].pbmts[1]", dut_g.l0_ramDatas_2_entries_pbmts_1, dut_i.u_core.l0_ramdata[2].pbmts[1]);
    chk("l0_ramdata[2].ppns[1]", dut_g.l0_ramDatas_2_entries_ppns_1, dut_i.u_core.l0_ramdata[2].ppns[1]);
    chk("l0_ramdata[2].onlypf[1]", dut_g.l0_ramDatas_2_entries_onlypf_1, dut_i.u_core.l0_ramdata[2].onlypf[1]);
    chk("l0_ramdata[2].perms[1].d", dut_g.l0_ramDatas_2_entries_perms_1_d, dut_i.u_core.l0_ramdata[2].perms[1].d);
    chk("l0_ramdata[2].perms[1].a", dut_g.l0_ramDatas_2_entries_perms_1_a, dut_i.u_core.l0_ramdata[2].perms[1].a);
    chk("l0_ramdata[2].perms[1].g", dut_g.l0_ramDatas_2_entries_perms_1_g, dut_i.u_core.l0_ramdata[2].perms[1].g);
    chk("l0_ramdata[2].perms[1].u", dut_g.l0_ramDatas_2_entries_perms_1_u, dut_i.u_core.l0_ramdata[2].perms[1].u);
    chk("l0_ramdata[2].perms[1].x", dut_g.l0_ramDatas_2_entries_perms_1_x, dut_i.u_core.l0_ramdata[2].perms[1].x);
    chk("l0_ramdata[2].perms[1].w", dut_g.l0_ramDatas_2_entries_perms_1_w, dut_i.u_core.l0_ramdata[2].perms[1].w);
    chk("l0_ramdata[2].perms[1].r", dut_g.l0_ramDatas_2_entries_perms_1_r, dut_i.u_core.l0_ramdata[2].perms[1].r);
    chk("l0_ramdata[2].pbmts[2]", dut_g.l0_ramDatas_2_entries_pbmts_2, dut_i.u_core.l0_ramdata[2].pbmts[2]);
    chk("l0_ramdata[2].ppns[2]", dut_g.l0_ramDatas_2_entries_ppns_2, dut_i.u_core.l0_ramdata[2].ppns[2]);
    chk("l0_ramdata[2].onlypf[2]", dut_g.l0_ramDatas_2_entries_onlypf_2, dut_i.u_core.l0_ramdata[2].onlypf[2]);
    chk("l0_ramdata[2].perms[2].d", dut_g.l0_ramDatas_2_entries_perms_2_d, dut_i.u_core.l0_ramdata[2].perms[2].d);
    chk("l0_ramdata[2].perms[2].a", dut_g.l0_ramDatas_2_entries_perms_2_a, dut_i.u_core.l0_ramdata[2].perms[2].a);
    chk("l0_ramdata[2].perms[2].g", dut_g.l0_ramDatas_2_entries_perms_2_g, dut_i.u_core.l0_ramdata[2].perms[2].g);
    chk("l0_ramdata[2].perms[2].u", dut_g.l0_ramDatas_2_entries_perms_2_u, dut_i.u_core.l0_ramdata[2].perms[2].u);
    chk("l0_ramdata[2].perms[2].x", dut_g.l0_ramDatas_2_entries_perms_2_x, dut_i.u_core.l0_ramdata[2].perms[2].x);
    chk("l0_ramdata[2].perms[2].w", dut_g.l0_ramDatas_2_entries_perms_2_w, dut_i.u_core.l0_ramdata[2].perms[2].w);
    chk("l0_ramdata[2].perms[2].r", dut_g.l0_ramDatas_2_entries_perms_2_r, dut_i.u_core.l0_ramdata[2].perms[2].r);
    chk("l0_ramdata[2].pbmts[3]", dut_g.l0_ramDatas_2_entries_pbmts_3, dut_i.u_core.l0_ramdata[2].pbmts[3]);
    chk("l0_ramdata[2].ppns[3]", dut_g.l0_ramDatas_2_entries_ppns_3, dut_i.u_core.l0_ramdata[2].ppns[3]);
    chk("l0_ramdata[2].onlypf[3]", dut_g.l0_ramDatas_2_entries_onlypf_3, dut_i.u_core.l0_ramdata[2].onlypf[3]);
    chk("l0_ramdata[2].perms[3].d", dut_g.l0_ramDatas_2_entries_perms_3_d, dut_i.u_core.l0_ramdata[2].perms[3].d);
    chk("l0_ramdata[2].perms[3].a", dut_g.l0_ramDatas_2_entries_perms_3_a, dut_i.u_core.l0_ramdata[2].perms[3].a);
    chk("l0_ramdata[2].perms[3].g", dut_g.l0_ramDatas_2_entries_perms_3_g, dut_i.u_core.l0_ramdata[2].perms[3].g);
    chk("l0_ramdata[2].perms[3].u", dut_g.l0_ramDatas_2_entries_perms_3_u, dut_i.u_core.l0_ramdata[2].perms[3].u);
    chk("l0_ramdata[2].perms[3].x", dut_g.l0_ramDatas_2_entries_perms_3_x, dut_i.u_core.l0_ramdata[2].perms[3].x);
    chk("l0_ramdata[2].perms[3].w", dut_g.l0_ramDatas_2_entries_perms_3_w, dut_i.u_core.l0_ramdata[2].perms[3].w);
    chk("l0_ramdata[2].perms[3].r", dut_g.l0_ramDatas_2_entries_perms_3_r, dut_i.u_core.l0_ramdata[2].perms[3].r);
    chk("l0_ramdata[2].pbmts[4]", dut_g.l0_ramDatas_2_entries_pbmts_4, dut_i.u_core.l0_ramdata[2].pbmts[4]);
    chk("l0_ramdata[2].ppns[4]", dut_g.l0_ramDatas_2_entries_ppns_4, dut_i.u_core.l0_ramdata[2].ppns[4]);
    chk("l0_ramdata[2].onlypf[4]", dut_g.l0_ramDatas_2_entries_onlypf_4, dut_i.u_core.l0_ramdata[2].onlypf[4]);
    chk("l0_ramdata[2].perms[4].d", dut_g.l0_ramDatas_2_entries_perms_4_d, dut_i.u_core.l0_ramdata[2].perms[4].d);
    chk("l0_ramdata[2].perms[4].a", dut_g.l0_ramDatas_2_entries_perms_4_a, dut_i.u_core.l0_ramdata[2].perms[4].a);
    chk("l0_ramdata[2].perms[4].g", dut_g.l0_ramDatas_2_entries_perms_4_g, dut_i.u_core.l0_ramdata[2].perms[4].g);
    chk("l0_ramdata[2].perms[4].u", dut_g.l0_ramDatas_2_entries_perms_4_u, dut_i.u_core.l0_ramdata[2].perms[4].u);
    chk("l0_ramdata[2].perms[4].x", dut_g.l0_ramDatas_2_entries_perms_4_x, dut_i.u_core.l0_ramdata[2].perms[4].x);
    chk("l0_ramdata[2].perms[4].w", dut_g.l0_ramDatas_2_entries_perms_4_w, dut_i.u_core.l0_ramdata[2].perms[4].w);
    chk("l0_ramdata[2].perms[4].r", dut_g.l0_ramDatas_2_entries_perms_4_r, dut_i.u_core.l0_ramdata[2].perms[4].r);
    chk("l0_ramdata[2].pbmts[5]", dut_g.l0_ramDatas_2_entries_pbmts_5, dut_i.u_core.l0_ramdata[2].pbmts[5]);
    chk("l0_ramdata[2].ppns[5]", dut_g.l0_ramDatas_2_entries_ppns_5, dut_i.u_core.l0_ramdata[2].ppns[5]);
    chk("l0_ramdata[2].onlypf[5]", dut_g.l0_ramDatas_2_entries_onlypf_5, dut_i.u_core.l0_ramdata[2].onlypf[5]);
    chk("l0_ramdata[2].perms[5].d", dut_g.l0_ramDatas_2_entries_perms_5_d, dut_i.u_core.l0_ramdata[2].perms[5].d);
    chk("l0_ramdata[2].perms[5].a", dut_g.l0_ramDatas_2_entries_perms_5_a, dut_i.u_core.l0_ramdata[2].perms[5].a);
    chk("l0_ramdata[2].perms[5].g", dut_g.l0_ramDatas_2_entries_perms_5_g, dut_i.u_core.l0_ramdata[2].perms[5].g);
    chk("l0_ramdata[2].perms[5].u", dut_g.l0_ramDatas_2_entries_perms_5_u, dut_i.u_core.l0_ramdata[2].perms[5].u);
    chk("l0_ramdata[2].perms[5].x", dut_g.l0_ramDatas_2_entries_perms_5_x, dut_i.u_core.l0_ramdata[2].perms[5].x);
    chk("l0_ramdata[2].perms[5].w", dut_g.l0_ramDatas_2_entries_perms_5_w, dut_i.u_core.l0_ramdata[2].perms[5].w);
    chk("l0_ramdata[2].perms[5].r", dut_g.l0_ramDatas_2_entries_perms_5_r, dut_i.u_core.l0_ramdata[2].perms[5].r);
    chk("l0_ramdata[2].pbmts[6]", dut_g.l0_ramDatas_2_entries_pbmts_6, dut_i.u_core.l0_ramdata[2].pbmts[6]);
    chk("l0_ramdata[2].ppns[6]", dut_g.l0_ramDatas_2_entries_ppns_6, dut_i.u_core.l0_ramdata[2].ppns[6]);
    chk("l0_ramdata[2].onlypf[6]", dut_g.l0_ramDatas_2_entries_onlypf_6, dut_i.u_core.l0_ramdata[2].onlypf[6]);
    chk("l0_ramdata[2].perms[6].d", dut_g.l0_ramDatas_2_entries_perms_6_d, dut_i.u_core.l0_ramdata[2].perms[6].d);
    chk("l0_ramdata[2].perms[6].a", dut_g.l0_ramDatas_2_entries_perms_6_a, dut_i.u_core.l0_ramdata[2].perms[6].a);
    chk("l0_ramdata[2].perms[6].g", dut_g.l0_ramDatas_2_entries_perms_6_g, dut_i.u_core.l0_ramdata[2].perms[6].g);
    chk("l0_ramdata[2].perms[6].u", dut_g.l0_ramDatas_2_entries_perms_6_u, dut_i.u_core.l0_ramdata[2].perms[6].u);
    chk("l0_ramdata[2].perms[6].x", dut_g.l0_ramDatas_2_entries_perms_6_x, dut_i.u_core.l0_ramdata[2].perms[6].x);
    chk("l0_ramdata[2].perms[6].w", dut_g.l0_ramDatas_2_entries_perms_6_w, dut_i.u_core.l0_ramdata[2].perms[6].w);
    chk("l0_ramdata[2].perms[6].r", dut_g.l0_ramDatas_2_entries_perms_6_r, dut_i.u_core.l0_ramdata[2].perms[6].r);
    chk("l0_ramdata[2].pbmts[7]", dut_g.l0_ramDatas_2_entries_pbmts_7, dut_i.u_core.l0_ramdata[2].pbmts[7]);
    chk("l0_ramdata[2].ppns[7]", dut_g.l0_ramDatas_2_entries_ppns_7, dut_i.u_core.l0_ramdata[2].ppns[7]);
    chk("l0_ramdata[2].onlypf[7]", dut_g.l0_ramDatas_2_entries_onlypf_7, dut_i.u_core.l0_ramdata[2].onlypf[7]);
    chk("l0_ramdata[2].perms[7].d", dut_g.l0_ramDatas_2_entries_perms_7_d, dut_i.u_core.l0_ramdata[2].perms[7].d);
    chk("l0_ramdata[2].perms[7].a", dut_g.l0_ramDatas_2_entries_perms_7_a, dut_i.u_core.l0_ramdata[2].perms[7].a);
    chk("l0_ramdata[2].perms[7].g", dut_g.l0_ramDatas_2_entries_perms_7_g, dut_i.u_core.l0_ramdata[2].perms[7].g);
    chk("l0_ramdata[2].perms[7].u", dut_g.l0_ramDatas_2_entries_perms_7_u, dut_i.u_core.l0_ramdata[2].perms[7].u);
    chk("l0_ramdata[2].perms[7].x", dut_g.l0_ramDatas_2_entries_perms_7_x, dut_i.u_core.l0_ramdata[2].perms[7].x);
    chk("l0_ramdata[2].perms[7].w", dut_g.l0_ramDatas_2_entries_perms_7_w, dut_i.u_core.l0_ramdata[2].perms[7].w);
    chk("l0_ramdata[2].perms[7].r", dut_g.l0_ramDatas_2_entries_perms_7_r, dut_i.u_core.l0_ramdata[2].perms[7].r);
    chk("l0_resp_r[3].tag", dut_g.data_resp_r_1_3_entries_tag, dut_i.u_core.l0_resp_r[3].tag);
    chk("l0_resp_r[3].asid", dut_g.data_resp_r_1_3_entries_asid, dut_i.u_core.l0_resp_r[3].asid);
    chk("l0_resp_r[3].vmid", dut_g.data_resp_r_1_3_entries_vmid, dut_i.u_core.l0_resp_r[3].vmid);
    chk("l0_resp_r[3].prefetch", dut_g.data_resp_r_1_3_entries_prefetch, dut_i.u_core.l0_resp_r[3].prefetch);
    chk("l0_resp_r[3].pbmts[0]", dut_g.data_resp_r_1_3_entries_pbmts_0, dut_i.u_core.l0_resp_r[3].pbmts[0]);
    chk("l0_resp_r[3].ppns[0]", dut_g.data_resp_r_1_3_entries_ppns_0, dut_i.u_core.l0_resp_r[3].ppns[0]);
    chk("l0_resp_r[3].vs[0]", dut_g.data_resp_r_1_3_entries_vs_0, dut_i.u_core.l0_resp_r[3].vs[0]);
    chk("l0_resp_r[3].onlypf[0]", dut_g.data_resp_r_1_3_entries_onlypf_0, dut_i.u_core.l0_resp_r[3].onlypf[0]);
    chk("l0_resp_r[3].perms[0].d", dut_g.data_resp_r_1_3_entries_perms_0_d, dut_i.u_core.l0_resp_r[3].perms[0].d);
    chk("l0_resp_r[3].perms[0].a", dut_g.data_resp_r_1_3_entries_perms_0_a, dut_i.u_core.l0_resp_r[3].perms[0].a);
    chk("l0_resp_r[3].perms[0].g", dut_g.data_resp_r_1_3_entries_perms_0_g, dut_i.u_core.l0_resp_r[3].perms[0].g);
    chk("l0_resp_r[3].perms[0].u", dut_g.data_resp_r_1_3_entries_perms_0_u, dut_i.u_core.l0_resp_r[3].perms[0].u);
    chk("l0_resp_r[3].perms[0].x", dut_g.data_resp_r_1_3_entries_perms_0_x, dut_i.u_core.l0_resp_r[3].perms[0].x);
    chk("l0_resp_r[3].perms[0].w", dut_g.data_resp_r_1_3_entries_perms_0_w, dut_i.u_core.l0_resp_r[3].perms[0].w);
    chk("l0_resp_r[3].perms[0].r", dut_g.data_resp_r_1_3_entries_perms_0_r, dut_i.u_core.l0_resp_r[3].perms[0].r);
    chk("l0_resp_r[3].pbmts[1]", dut_g.data_resp_r_1_3_entries_pbmts_1, dut_i.u_core.l0_resp_r[3].pbmts[1]);
    chk("l0_resp_r[3].ppns[1]", dut_g.data_resp_r_1_3_entries_ppns_1, dut_i.u_core.l0_resp_r[3].ppns[1]);
    chk("l0_resp_r[3].vs[1]", dut_g.data_resp_r_1_3_entries_vs_1, dut_i.u_core.l0_resp_r[3].vs[1]);
    chk("l0_resp_r[3].onlypf[1]", dut_g.data_resp_r_1_3_entries_onlypf_1, dut_i.u_core.l0_resp_r[3].onlypf[1]);
    chk("l0_resp_r[3].perms[1].d", dut_g.data_resp_r_1_3_entries_perms_1_d, dut_i.u_core.l0_resp_r[3].perms[1].d);
    chk("l0_resp_r[3].perms[1].a", dut_g.data_resp_r_1_3_entries_perms_1_a, dut_i.u_core.l0_resp_r[3].perms[1].a);
    chk("l0_resp_r[3].perms[1].g", dut_g.data_resp_r_1_3_entries_perms_1_g, dut_i.u_core.l0_resp_r[3].perms[1].g);
    chk("l0_resp_r[3].perms[1].u", dut_g.data_resp_r_1_3_entries_perms_1_u, dut_i.u_core.l0_resp_r[3].perms[1].u);
    chk("l0_resp_r[3].perms[1].x", dut_g.data_resp_r_1_3_entries_perms_1_x, dut_i.u_core.l0_resp_r[3].perms[1].x);
    chk("l0_resp_r[3].perms[1].w", dut_g.data_resp_r_1_3_entries_perms_1_w, dut_i.u_core.l0_resp_r[3].perms[1].w);
    chk("l0_resp_r[3].perms[1].r", dut_g.data_resp_r_1_3_entries_perms_1_r, dut_i.u_core.l0_resp_r[3].perms[1].r);
    chk("l0_resp_r[3].pbmts[2]", dut_g.data_resp_r_1_3_entries_pbmts_2, dut_i.u_core.l0_resp_r[3].pbmts[2]);
    chk("l0_resp_r[3].ppns[2]", dut_g.data_resp_r_1_3_entries_ppns_2, dut_i.u_core.l0_resp_r[3].ppns[2]);
    chk("l0_resp_r[3].vs[2]", dut_g.data_resp_r_1_3_entries_vs_2, dut_i.u_core.l0_resp_r[3].vs[2]);
    chk("l0_resp_r[3].onlypf[2]", dut_g.data_resp_r_1_3_entries_onlypf_2, dut_i.u_core.l0_resp_r[3].onlypf[2]);
    chk("l0_resp_r[3].perms[2].d", dut_g.data_resp_r_1_3_entries_perms_2_d, dut_i.u_core.l0_resp_r[3].perms[2].d);
    chk("l0_resp_r[3].perms[2].a", dut_g.data_resp_r_1_3_entries_perms_2_a, dut_i.u_core.l0_resp_r[3].perms[2].a);
    chk("l0_resp_r[3].perms[2].g", dut_g.data_resp_r_1_3_entries_perms_2_g, dut_i.u_core.l0_resp_r[3].perms[2].g);
    chk("l0_resp_r[3].perms[2].u", dut_g.data_resp_r_1_3_entries_perms_2_u, dut_i.u_core.l0_resp_r[3].perms[2].u);
    chk("l0_resp_r[3].perms[2].x", dut_g.data_resp_r_1_3_entries_perms_2_x, dut_i.u_core.l0_resp_r[3].perms[2].x);
    chk("l0_resp_r[3].perms[2].w", dut_g.data_resp_r_1_3_entries_perms_2_w, dut_i.u_core.l0_resp_r[3].perms[2].w);
    chk("l0_resp_r[3].perms[2].r", dut_g.data_resp_r_1_3_entries_perms_2_r, dut_i.u_core.l0_resp_r[3].perms[2].r);
    chk("l0_resp_r[3].pbmts[3]", dut_g.data_resp_r_1_3_entries_pbmts_3, dut_i.u_core.l0_resp_r[3].pbmts[3]);
    chk("l0_resp_r[3].ppns[3]", dut_g.data_resp_r_1_3_entries_ppns_3, dut_i.u_core.l0_resp_r[3].ppns[3]);
    chk("l0_resp_r[3].vs[3]", dut_g.data_resp_r_1_3_entries_vs_3, dut_i.u_core.l0_resp_r[3].vs[3]);
    chk("l0_resp_r[3].onlypf[3]", dut_g.data_resp_r_1_3_entries_onlypf_3, dut_i.u_core.l0_resp_r[3].onlypf[3]);
    chk("l0_resp_r[3].perms[3].d", dut_g.data_resp_r_1_3_entries_perms_3_d, dut_i.u_core.l0_resp_r[3].perms[3].d);
    chk("l0_resp_r[3].perms[3].a", dut_g.data_resp_r_1_3_entries_perms_3_a, dut_i.u_core.l0_resp_r[3].perms[3].a);
    chk("l0_resp_r[3].perms[3].g", dut_g.data_resp_r_1_3_entries_perms_3_g, dut_i.u_core.l0_resp_r[3].perms[3].g);
    chk("l0_resp_r[3].perms[3].u", dut_g.data_resp_r_1_3_entries_perms_3_u, dut_i.u_core.l0_resp_r[3].perms[3].u);
    chk("l0_resp_r[3].perms[3].x", dut_g.data_resp_r_1_3_entries_perms_3_x, dut_i.u_core.l0_resp_r[3].perms[3].x);
    chk("l0_resp_r[3].perms[3].w", dut_g.data_resp_r_1_3_entries_perms_3_w, dut_i.u_core.l0_resp_r[3].perms[3].w);
    chk("l0_resp_r[3].perms[3].r", dut_g.data_resp_r_1_3_entries_perms_3_r, dut_i.u_core.l0_resp_r[3].perms[3].r);
    chk("l0_resp_r[3].pbmts[4]", dut_g.data_resp_r_1_3_entries_pbmts_4, dut_i.u_core.l0_resp_r[3].pbmts[4]);
    chk("l0_resp_r[3].ppns[4]", dut_g.data_resp_r_1_3_entries_ppns_4, dut_i.u_core.l0_resp_r[3].ppns[4]);
    chk("l0_resp_r[3].vs[4]", dut_g.data_resp_r_1_3_entries_vs_4, dut_i.u_core.l0_resp_r[3].vs[4]);
    chk("l0_resp_r[3].onlypf[4]", dut_g.data_resp_r_1_3_entries_onlypf_4, dut_i.u_core.l0_resp_r[3].onlypf[4]);
    chk("l0_resp_r[3].perms[4].d", dut_g.data_resp_r_1_3_entries_perms_4_d, dut_i.u_core.l0_resp_r[3].perms[4].d);
    chk("l0_resp_r[3].perms[4].a", dut_g.data_resp_r_1_3_entries_perms_4_a, dut_i.u_core.l0_resp_r[3].perms[4].a);
    chk("l0_resp_r[3].perms[4].g", dut_g.data_resp_r_1_3_entries_perms_4_g, dut_i.u_core.l0_resp_r[3].perms[4].g);
    chk("l0_resp_r[3].perms[4].u", dut_g.data_resp_r_1_3_entries_perms_4_u, dut_i.u_core.l0_resp_r[3].perms[4].u);
    chk("l0_resp_r[3].perms[4].x", dut_g.data_resp_r_1_3_entries_perms_4_x, dut_i.u_core.l0_resp_r[3].perms[4].x);
    chk("l0_resp_r[3].perms[4].w", dut_g.data_resp_r_1_3_entries_perms_4_w, dut_i.u_core.l0_resp_r[3].perms[4].w);
    chk("l0_resp_r[3].perms[4].r", dut_g.data_resp_r_1_3_entries_perms_4_r, dut_i.u_core.l0_resp_r[3].perms[4].r);
    chk("l0_resp_r[3].pbmts[5]", dut_g.data_resp_r_1_3_entries_pbmts_5, dut_i.u_core.l0_resp_r[3].pbmts[5]);
    chk("l0_resp_r[3].ppns[5]", dut_g.data_resp_r_1_3_entries_ppns_5, dut_i.u_core.l0_resp_r[3].ppns[5]);
    chk("l0_resp_r[3].vs[5]", dut_g.data_resp_r_1_3_entries_vs_5, dut_i.u_core.l0_resp_r[3].vs[5]);
    chk("l0_resp_r[3].onlypf[5]", dut_g.data_resp_r_1_3_entries_onlypf_5, dut_i.u_core.l0_resp_r[3].onlypf[5]);
    chk("l0_resp_r[3].perms[5].d", dut_g.data_resp_r_1_3_entries_perms_5_d, dut_i.u_core.l0_resp_r[3].perms[5].d);
    chk("l0_resp_r[3].perms[5].a", dut_g.data_resp_r_1_3_entries_perms_5_a, dut_i.u_core.l0_resp_r[3].perms[5].a);
    chk("l0_resp_r[3].perms[5].g", dut_g.data_resp_r_1_3_entries_perms_5_g, dut_i.u_core.l0_resp_r[3].perms[5].g);
    chk("l0_resp_r[3].perms[5].u", dut_g.data_resp_r_1_3_entries_perms_5_u, dut_i.u_core.l0_resp_r[3].perms[5].u);
    chk("l0_resp_r[3].perms[5].x", dut_g.data_resp_r_1_3_entries_perms_5_x, dut_i.u_core.l0_resp_r[3].perms[5].x);
    chk("l0_resp_r[3].perms[5].w", dut_g.data_resp_r_1_3_entries_perms_5_w, dut_i.u_core.l0_resp_r[3].perms[5].w);
    chk("l0_resp_r[3].perms[5].r", dut_g.data_resp_r_1_3_entries_perms_5_r, dut_i.u_core.l0_resp_r[3].perms[5].r);
    chk("l0_resp_r[3].pbmts[6]", dut_g.data_resp_r_1_3_entries_pbmts_6, dut_i.u_core.l0_resp_r[3].pbmts[6]);
    chk("l0_resp_r[3].ppns[6]", dut_g.data_resp_r_1_3_entries_ppns_6, dut_i.u_core.l0_resp_r[3].ppns[6]);
    chk("l0_resp_r[3].vs[6]", dut_g.data_resp_r_1_3_entries_vs_6, dut_i.u_core.l0_resp_r[3].vs[6]);
    chk("l0_resp_r[3].onlypf[6]", dut_g.data_resp_r_1_3_entries_onlypf_6, dut_i.u_core.l0_resp_r[3].onlypf[6]);
    chk("l0_resp_r[3].perms[6].d", dut_g.data_resp_r_1_3_entries_perms_6_d, dut_i.u_core.l0_resp_r[3].perms[6].d);
    chk("l0_resp_r[3].perms[6].a", dut_g.data_resp_r_1_3_entries_perms_6_a, dut_i.u_core.l0_resp_r[3].perms[6].a);
    chk("l0_resp_r[3].perms[6].g", dut_g.data_resp_r_1_3_entries_perms_6_g, dut_i.u_core.l0_resp_r[3].perms[6].g);
    chk("l0_resp_r[3].perms[6].u", dut_g.data_resp_r_1_3_entries_perms_6_u, dut_i.u_core.l0_resp_r[3].perms[6].u);
    chk("l0_resp_r[3].perms[6].x", dut_g.data_resp_r_1_3_entries_perms_6_x, dut_i.u_core.l0_resp_r[3].perms[6].x);
    chk("l0_resp_r[3].perms[6].w", dut_g.data_resp_r_1_3_entries_perms_6_w, dut_i.u_core.l0_resp_r[3].perms[6].w);
    chk("l0_resp_r[3].perms[6].r", dut_g.data_resp_r_1_3_entries_perms_6_r, dut_i.u_core.l0_resp_r[3].perms[6].r);
    chk("l0_resp_r[3].pbmts[7]", dut_g.data_resp_r_1_3_entries_pbmts_7, dut_i.u_core.l0_resp_r[3].pbmts[7]);
    chk("l0_resp_r[3].ppns[7]", dut_g.data_resp_r_1_3_entries_ppns_7, dut_i.u_core.l0_resp_r[3].ppns[7]);
    chk("l0_resp_r[3].vs[7]", dut_g.data_resp_r_1_3_entries_vs_7, dut_i.u_core.l0_resp_r[3].vs[7]);
    chk("l0_resp_r[3].onlypf[7]", dut_g.data_resp_r_1_3_entries_onlypf_7, dut_i.u_core.l0_resp_r[3].onlypf[7]);
    chk("l0_resp_r[3].perms[7].d", dut_g.data_resp_r_1_3_entries_perms_7_d, dut_i.u_core.l0_resp_r[3].perms[7].d);
    chk("l0_resp_r[3].perms[7].a", dut_g.data_resp_r_1_3_entries_perms_7_a, dut_i.u_core.l0_resp_r[3].perms[7].a);
    chk("l0_resp_r[3].perms[7].g", dut_g.data_resp_r_1_3_entries_perms_7_g, dut_i.u_core.l0_resp_r[3].perms[7].g);
    chk("l0_resp_r[3].perms[7].u", dut_g.data_resp_r_1_3_entries_perms_7_u, dut_i.u_core.l0_resp_r[3].perms[7].u);
    chk("l0_resp_r[3].perms[7].x", dut_g.data_resp_r_1_3_entries_perms_7_x, dut_i.u_core.l0_resp_r[3].perms[7].x);
    chk("l0_resp_r[3].perms[7].w", dut_g.data_resp_r_1_3_entries_perms_7_w, dut_i.u_core.l0_resp_r[3].perms[7].w);
    chk("l0_resp_r[3].perms[7].r", dut_g.data_resp_r_1_3_entries_perms_7_r, dut_i.u_core.l0_resp_r[3].perms[7].r);
    chk("l0_ramdata[3].prefetch", dut_g.l0_ramDatas_3_entries_prefetch, dut_i.u_core.l0_ramdata[3].prefetch);
    chk("l0_ramdata[3].pbmts[0]", dut_g.l0_ramDatas_3_entries_pbmts_0, dut_i.u_core.l0_ramdata[3].pbmts[0]);
    chk("l0_ramdata[3].ppns[0]", dut_g.l0_ramDatas_3_entries_ppns_0, dut_i.u_core.l0_ramdata[3].ppns[0]);
    chk("l0_ramdata[3].onlypf[0]", dut_g.l0_ramDatas_3_entries_onlypf_0, dut_i.u_core.l0_ramdata[3].onlypf[0]);
    chk("l0_ramdata[3].perms[0].d", dut_g.l0_ramDatas_3_entries_perms_0_d, dut_i.u_core.l0_ramdata[3].perms[0].d);
    chk("l0_ramdata[3].perms[0].a", dut_g.l0_ramDatas_3_entries_perms_0_a, dut_i.u_core.l0_ramdata[3].perms[0].a);
    chk("l0_ramdata[3].perms[0].g", dut_g.l0_ramDatas_3_entries_perms_0_g, dut_i.u_core.l0_ramdata[3].perms[0].g);
    chk("l0_ramdata[3].perms[0].u", dut_g.l0_ramDatas_3_entries_perms_0_u, dut_i.u_core.l0_ramdata[3].perms[0].u);
    chk("l0_ramdata[3].perms[0].x", dut_g.l0_ramDatas_3_entries_perms_0_x, dut_i.u_core.l0_ramdata[3].perms[0].x);
    chk("l0_ramdata[3].perms[0].w", dut_g.l0_ramDatas_3_entries_perms_0_w, dut_i.u_core.l0_ramdata[3].perms[0].w);
    chk("l0_ramdata[3].perms[0].r", dut_g.l0_ramDatas_3_entries_perms_0_r, dut_i.u_core.l0_ramdata[3].perms[0].r);
    chk("l0_ramdata[3].pbmts[1]", dut_g.l0_ramDatas_3_entries_pbmts_1, dut_i.u_core.l0_ramdata[3].pbmts[1]);
    chk("l0_ramdata[3].ppns[1]", dut_g.l0_ramDatas_3_entries_ppns_1, dut_i.u_core.l0_ramdata[3].ppns[1]);
    chk("l0_ramdata[3].onlypf[1]", dut_g.l0_ramDatas_3_entries_onlypf_1, dut_i.u_core.l0_ramdata[3].onlypf[1]);
    chk("l0_ramdata[3].perms[1].d", dut_g.l0_ramDatas_3_entries_perms_1_d, dut_i.u_core.l0_ramdata[3].perms[1].d);
    chk("l0_ramdata[3].perms[1].a", dut_g.l0_ramDatas_3_entries_perms_1_a, dut_i.u_core.l0_ramdata[3].perms[1].a);
    chk("l0_ramdata[3].perms[1].g", dut_g.l0_ramDatas_3_entries_perms_1_g, dut_i.u_core.l0_ramdata[3].perms[1].g);
    chk("l0_ramdata[3].perms[1].u", dut_g.l0_ramDatas_3_entries_perms_1_u, dut_i.u_core.l0_ramdata[3].perms[1].u);
    chk("l0_ramdata[3].perms[1].x", dut_g.l0_ramDatas_3_entries_perms_1_x, dut_i.u_core.l0_ramdata[3].perms[1].x);
    chk("l0_ramdata[3].perms[1].w", dut_g.l0_ramDatas_3_entries_perms_1_w, dut_i.u_core.l0_ramdata[3].perms[1].w);
    chk("l0_ramdata[3].perms[1].r", dut_g.l0_ramDatas_3_entries_perms_1_r, dut_i.u_core.l0_ramdata[3].perms[1].r);
    chk("l0_ramdata[3].pbmts[2]", dut_g.l0_ramDatas_3_entries_pbmts_2, dut_i.u_core.l0_ramdata[3].pbmts[2]);
    chk("l0_ramdata[3].ppns[2]", dut_g.l0_ramDatas_3_entries_ppns_2, dut_i.u_core.l0_ramdata[3].ppns[2]);
    chk("l0_ramdata[3].onlypf[2]", dut_g.l0_ramDatas_3_entries_onlypf_2, dut_i.u_core.l0_ramdata[3].onlypf[2]);
    chk("l0_ramdata[3].perms[2].d", dut_g.l0_ramDatas_3_entries_perms_2_d, dut_i.u_core.l0_ramdata[3].perms[2].d);
    chk("l0_ramdata[3].perms[2].a", dut_g.l0_ramDatas_3_entries_perms_2_a, dut_i.u_core.l0_ramdata[3].perms[2].a);
    chk("l0_ramdata[3].perms[2].g", dut_g.l0_ramDatas_3_entries_perms_2_g, dut_i.u_core.l0_ramdata[3].perms[2].g);
    chk("l0_ramdata[3].perms[2].u", dut_g.l0_ramDatas_3_entries_perms_2_u, dut_i.u_core.l0_ramdata[3].perms[2].u);
    chk("l0_ramdata[3].perms[2].x", dut_g.l0_ramDatas_3_entries_perms_2_x, dut_i.u_core.l0_ramdata[3].perms[2].x);
    chk("l0_ramdata[3].perms[2].w", dut_g.l0_ramDatas_3_entries_perms_2_w, dut_i.u_core.l0_ramdata[3].perms[2].w);
    chk("l0_ramdata[3].perms[2].r", dut_g.l0_ramDatas_3_entries_perms_2_r, dut_i.u_core.l0_ramdata[3].perms[2].r);
    chk("l0_ramdata[3].pbmts[3]", dut_g.l0_ramDatas_3_entries_pbmts_3, dut_i.u_core.l0_ramdata[3].pbmts[3]);
    chk("l0_ramdata[3].ppns[3]", dut_g.l0_ramDatas_3_entries_ppns_3, dut_i.u_core.l0_ramdata[3].ppns[3]);
    chk("l0_ramdata[3].onlypf[3]", dut_g.l0_ramDatas_3_entries_onlypf_3, dut_i.u_core.l0_ramdata[3].onlypf[3]);
    chk("l0_ramdata[3].perms[3].d", dut_g.l0_ramDatas_3_entries_perms_3_d, dut_i.u_core.l0_ramdata[3].perms[3].d);
    chk("l0_ramdata[3].perms[3].a", dut_g.l0_ramDatas_3_entries_perms_3_a, dut_i.u_core.l0_ramdata[3].perms[3].a);
    chk("l0_ramdata[3].perms[3].g", dut_g.l0_ramDatas_3_entries_perms_3_g, dut_i.u_core.l0_ramdata[3].perms[3].g);
    chk("l0_ramdata[3].perms[3].u", dut_g.l0_ramDatas_3_entries_perms_3_u, dut_i.u_core.l0_ramdata[3].perms[3].u);
    chk("l0_ramdata[3].perms[3].x", dut_g.l0_ramDatas_3_entries_perms_3_x, dut_i.u_core.l0_ramdata[3].perms[3].x);
    chk("l0_ramdata[3].perms[3].w", dut_g.l0_ramDatas_3_entries_perms_3_w, dut_i.u_core.l0_ramdata[3].perms[3].w);
    chk("l0_ramdata[3].perms[3].r", dut_g.l0_ramDatas_3_entries_perms_3_r, dut_i.u_core.l0_ramdata[3].perms[3].r);
    chk("l0_ramdata[3].pbmts[4]", dut_g.l0_ramDatas_3_entries_pbmts_4, dut_i.u_core.l0_ramdata[3].pbmts[4]);
    chk("l0_ramdata[3].ppns[4]", dut_g.l0_ramDatas_3_entries_ppns_4, dut_i.u_core.l0_ramdata[3].ppns[4]);
    chk("l0_ramdata[3].onlypf[4]", dut_g.l0_ramDatas_3_entries_onlypf_4, dut_i.u_core.l0_ramdata[3].onlypf[4]);
    chk("l0_ramdata[3].perms[4].d", dut_g.l0_ramDatas_3_entries_perms_4_d, dut_i.u_core.l0_ramdata[3].perms[4].d);
    chk("l0_ramdata[3].perms[4].a", dut_g.l0_ramDatas_3_entries_perms_4_a, dut_i.u_core.l0_ramdata[3].perms[4].a);
    chk("l0_ramdata[3].perms[4].g", dut_g.l0_ramDatas_3_entries_perms_4_g, dut_i.u_core.l0_ramdata[3].perms[4].g);
    chk("l0_ramdata[3].perms[4].u", dut_g.l0_ramDatas_3_entries_perms_4_u, dut_i.u_core.l0_ramdata[3].perms[4].u);
    chk("l0_ramdata[3].perms[4].x", dut_g.l0_ramDatas_3_entries_perms_4_x, dut_i.u_core.l0_ramdata[3].perms[4].x);
    chk("l0_ramdata[3].perms[4].w", dut_g.l0_ramDatas_3_entries_perms_4_w, dut_i.u_core.l0_ramdata[3].perms[4].w);
    chk("l0_ramdata[3].perms[4].r", dut_g.l0_ramDatas_3_entries_perms_4_r, dut_i.u_core.l0_ramdata[3].perms[4].r);
    chk("l0_ramdata[3].pbmts[5]", dut_g.l0_ramDatas_3_entries_pbmts_5, dut_i.u_core.l0_ramdata[3].pbmts[5]);
    chk("l0_ramdata[3].ppns[5]", dut_g.l0_ramDatas_3_entries_ppns_5, dut_i.u_core.l0_ramdata[3].ppns[5]);
    chk("l0_ramdata[3].onlypf[5]", dut_g.l0_ramDatas_3_entries_onlypf_5, dut_i.u_core.l0_ramdata[3].onlypf[5]);
    chk("l0_ramdata[3].perms[5].d", dut_g.l0_ramDatas_3_entries_perms_5_d, dut_i.u_core.l0_ramdata[3].perms[5].d);
    chk("l0_ramdata[3].perms[5].a", dut_g.l0_ramDatas_3_entries_perms_5_a, dut_i.u_core.l0_ramdata[3].perms[5].a);
    chk("l0_ramdata[3].perms[5].g", dut_g.l0_ramDatas_3_entries_perms_5_g, dut_i.u_core.l0_ramdata[3].perms[5].g);
    chk("l0_ramdata[3].perms[5].u", dut_g.l0_ramDatas_3_entries_perms_5_u, dut_i.u_core.l0_ramdata[3].perms[5].u);
    chk("l0_ramdata[3].perms[5].x", dut_g.l0_ramDatas_3_entries_perms_5_x, dut_i.u_core.l0_ramdata[3].perms[5].x);
    chk("l0_ramdata[3].perms[5].w", dut_g.l0_ramDatas_3_entries_perms_5_w, dut_i.u_core.l0_ramdata[3].perms[5].w);
    chk("l0_ramdata[3].perms[5].r", dut_g.l0_ramDatas_3_entries_perms_5_r, dut_i.u_core.l0_ramdata[3].perms[5].r);
    chk("l0_ramdata[3].pbmts[6]", dut_g.l0_ramDatas_3_entries_pbmts_6, dut_i.u_core.l0_ramdata[3].pbmts[6]);
    chk("l0_ramdata[3].ppns[6]", dut_g.l0_ramDatas_3_entries_ppns_6, dut_i.u_core.l0_ramdata[3].ppns[6]);
    chk("l0_ramdata[3].onlypf[6]", dut_g.l0_ramDatas_3_entries_onlypf_6, dut_i.u_core.l0_ramdata[3].onlypf[6]);
    chk("l0_ramdata[3].perms[6].d", dut_g.l0_ramDatas_3_entries_perms_6_d, dut_i.u_core.l0_ramdata[3].perms[6].d);
    chk("l0_ramdata[3].perms[6].a", dut_g.l0_ramDatas_3_entries_perms_6_a, dut_i.u_core.l0_ramdata[3].perms[6].a);
    chk("l0_ramdata[3].perms[6].g", dut_g.l0_ramDatas_3_entries_perms_6_g, dut_i.u_core.l0_ramdata[3].perms[6].g);
    chk("l0_ramdata[3].perms[6].u", dut_g.l0_ramDatas_3_entries_perms_6_u, dut_i.u_core.l0_ramdata[3].perms[6].u);
    chk("l0_ramdata[3].perms[6].x", dut_g.l0_ramDatas_3_entries_perms_6_x, dut_i.u_core.l0_ramdata[3].perms[6].x);
    chk("l0_ramdata[3].perms[6].w", dut_g.l0_ramDatas_3_entries_perms_6_w, dut_i.u_core.l0_ramdata[3].perms[6].w);
    chk("l0_ramdata[3].perms[6].r", dut_g.l0_ramDatas_3_entries_perms_6_r, dut_i.u_core.l0_ramdata[3].perms[6].r);
    chk("l0_ramdata[3].pbmts[7]", dut_g.l0_ramDatas_3_entries_pbmts_7, dut_i.u_core.l0_ramdata[3].pbmts[7]);
    chk("l0_ramdata[3].ppns[7]", dut_g.l0_ramDatas_3_entries_ppns_7, dut_i.u_core.l0_ramdata[3].ppns[7]);
    chk("l0_ramdata[3].onlypf[7]", dut_g.l0_ramDatas_3_entries_onlypf_7, dut_i.u_core.l0_ramdata[3].onlypf[7]);
    chk("l0_ramdata[3].perms[7].d", dut_g.l0_ramDatas_3_entries_perms_7_d, dut_i.u_core.l0_ramdata[3].perms[7].d);
    chk("l0_ramdata[3].perms[7].a", dut_g.l0_ramDatas_3_entries_perms_7_a, dut_i.u_core.l0_ramdata[3].perms[7].a);
    chk("l0_ramdata[3].perms[7].g", dut_g.l0_ramDatas_3_entries_perms_7_g, dut_i.u_core.l0_ramdata[3].perms[7].g);
    chk("l0_ramdata[3].perms[7].u", dut_g.l0_ramDatas_3_entries_perms_7_u, dut_i.u_core.l0_ramdata[3].perms[7].u);
    chk("l0_ramdata[3].perms[7].x", dut_g.l0_ramDatas_3_entries_perms_7_x, dut_i.u_core.l0_ramdata[3].perms[7].x);
    chk("l0_ramdata[3].perms[7].w", dut_g.l0_ramDatas_3_entries_perms_7_w, dut_i.u_core.l0_ramdata[3].perms[7].w);
    chk("l0_ramdata[3].perms[7].r", dut_g.l0_ramDatas_3_entries_perms_7_r, dut_i.u_core.l0_ramdata[3].perms[7].r);
    // §22 l0BitmapReg（每组 4 路 x 8 位打成 32 位比一次）
    chk("l0_bitmap[0]", {dut_g.l0BitmapReg_0_3_7, dut_g.l0BitmapReg_0_3_6, dut_g.l0BitmapReg_0_3_5, dut_g.l0BitmapReg_0_3_4, dut_g.l0BitmapReg_0_3_3, dut_g.l0BitmapReg_0_3_2, dut_g.l0BitmapReg_0_3_1, dut_g.l0BitmapReg_0_3_0, dut_g.l0BitmapReg_0_2_7, dut_g.l0BitmapReg_0_2_6, dut_g.l0BitmapReg_0_2_5, dut_g.l0BitmapReg_0_2_4, dut_g.l0BitmapReg_0_2_3, dut_g.l0BitmapReg_0_2_2, dut_g.l0BitmapReg_0_2_1, dut_g.l0BitmapReg_0_2_0, dut_g.l0BitmapReg_0_1_7, dut_g.l0BitmapReg_0_1_6, dut_g.l0BitmapReg_0_1_5, dut_g.l0BitmapReg_0_1_4, dut_g.l0BitmapReg_0_1_3, dut_g.l0BitmapReg_0_1_2, dut_g.l0BitmapReg_0_1_1, dut_g.l0BitmapReg_0_1_0, dut_g.l0BitmapReg_0_0_7, dut_g.l0BitmapReg_0_0_6, dut_g.l0BitmapReg_0_0_5, dut_g.l0BitmapReg_0_0_4, dut_g.l0BitmapReg_0_0_3, dut_g.l0BitmapReg_0_0_2, dut_g.l0BitmapReg_0_0_1, dut_g.l0BitmapReg_0_0_0}, {dut_i.u_core.l0_bitmap[0][3], dut_i.u_core.l0_bitmap[0][2], dut_i.u_core.l0_bitmap[0][1], dut_i.u_core.l0_bitmap[0][0]});
    chk("l0_bitmap[1]", {dut_g.l0BitmapReg_1_3_7, dut_g.l0BitmapReg_1_3_6, dut_g.l0BitmapReg_1_3_5, dut_g.l0BitmapReg_1_3_4, dut_g.l0BitmapReg_1_3_3, dut_g.l0BitmapReg_1_3_2, dut_g.l0BitmapReg_1_3_1, dut_g.l0BitmapReg_1_3_0, dut_g.l0BitmapReg_1_2_7, dut_g.l0BitmapReg_1_2_6, dut_g.l0BitmapReg_1_2_5, dut_g.l0BitmapReg_1_2_4, dut_g.l0BitmapReg_1_2_3, dut_g.l0BitmapReg_1_2_2, dut_g.l0BitmapReg_1_2_1, dut_g.l0BitmapReg_1_2_0, dut_g.l0BitmapReg_1_1_7, dut_g.l0BitmapReg_1_1_6, dut_g.l0BitmapReg_1_1_5, dut_g.l0BitmapReg_1_1_4, dut_g.l0BitmapReg_1_1_3, dut_g.l0BitmapReg_1_1_2, dut_g.l0BitmapReg_1_1_1, dut_g.l0BitmapReg_1_1_0, dut_g.l0BitmapReg_1_0_7, dut_g.l0BitmapReg_1_0_6, dut_g.l0BitmapReg_1_0_5, dut_g.l0BitmapReg_1_0_4, dut_g.l0BitmapReg_1_0_3, dut_g.l0BitmapReg_1_0_2, dut_g.l0BitmapReg_1_0_1, dut_g.l0BitmapReg_1_0_0}, {dut_i.u_core.l0_bitmap[1][3], dut_i.u_core.l0_bitmap[1][2], dut_i.u_core.l0_bitmap[1][1], dut_i.u_core.l0_bitmap[1][0]});
    chk("l0_bitmap[2]", {dut_g.l0BitmapReg_2_3_7, dut_g.l0BitmapReg_2_3_6, dut_g.l0BitmapReg_2_3_5, dut_g.l0BitmapReg_2_3_4, dut_g.l0BitmapReg_2_3_3, dut_g.l0BitmapReg_2_3_2, dut_g.l0BitmapReg_2_3_1, dut_g.l0BitmapReg_2_3_0, dut_g.l0BitmapReg_2_2_7, dut_g.l0BitmapReg_2_2_6, dut_g.l0BitmapReg_2_2_5, dut_g.l0BitmapReg_2_2_4, dut_g.l0BitmapReg_2_2_3, dut_g.l0BitmapReg_2_2_2, dut_g.l0BitmapReg_2_2_1, dut_g.l0BitmapReg_2_2_0, dut_g.l0BitmapReg_2_1_7, dut_g.l0BitmapReg_2_1_6, dut_g.l0BitmapReg_2_1_5, dut_g.l0BitmapReg_2_1_4, dut_g.l0BitmapReg_2_1_3, dut_g.l0BitmapReg_2_1_2, dut_g.l0BitmapReg_2_1_1, dut_g.l0BitmapReg_2_1_0, dut_g.l0BitmapReg_2_0_7, dut_g.l0BitmapReg_2_0_6, dut_g.l0BitmapReg_2_0_5, dut_g.l0BitmapReg_2_0_4, dut_g.l0BitmapReg_2_0_3, dut_g.l0BitmapReg_2_0_2, dut_g.l0BitmapReg_2_0_1, dut_g.l0BitmapReg_2_0_0}, {dut_i.u_core.l0_bitmap[2][3], dut_i.u_core.l0_bitmap[2][2], dut_i.u_core.l0_bitmap[2][1], dut_i.u_core.l0_bitmap[2][0]});
    chk("l0_bitmap[3]", {dut_g.l0BitmapReg_3_3_7, dut_g.l0BitmapReg_3_3_6, dut_g.l0BitmapReg_3_3_5, dut_g.l0BitmapReg_3_3_4, dut_g.l0BitmapReg_3_3_3, dut_g.l0BitmapReg_3_3_2, dut_g.l0BitmapReg_3_3_1, dut_g.l0BitmapReg_3_3_0, dut_g.l0BitmapReg_3_2_7, dut_g.l0BitmapReg_3_2_6, dut_g.l0BitmapReg_3_2_5, dut_g.l0BitmapReg_3_2_4, dut_g.l0BitmapReg_3_2_3, dut_g.l0BitmapReg_3_2_2, dut_g.l0BitmapReg_3_2_1, dut_g.l0BitmapReg_3_2_0, dut_g.l0BitmapReg_3_1_7, dut_g.l0BitmapReg_3_1_6, dut_g.l0BitmapReg_3_1_5, dut_g.l0BitmapReg_3_1_4, dut_g.l0BitmapReg_3_1_3, dut_g.l0BitmapReg_3_1_2, dut_g.l0BitmapReg_3_1_1, dut_g.l0BitmapReg_3_1_0, dut_g.l0BitmapReg_3_0_7, dut_g.l0BitmapReg_3_0_6, dut_g.l0BitmapReg_3_0_5, dut_g.l0BitmapReg_3_0_4, dut_g.l0BitmapReg_3_0_3, dut_g.l0BitmapReg_3_0_2, dut_g.l0BitmapReg_3_0_1, dut_g.l0BitmapReg_3_0_0}, {dut_i.u_core.l0_bitmap[3][3], dut_i.u_core.l0_bitmap[3][2], dut_i.u_core.l0_bitmap[3][1], dut_i.u_core.l0_bitmap[3][0]});
    chk("l0_bitmap[4]", {dut_g.l0BitmapReg_4_3_7, dut_g.l0BitmapReg_4_3_6, dut_g.l0BitmapReg_4_3_5, dut_g.l0BitmapReg_4_3_4, dut_g.l0BitmapReg_4_3_3, dut_g.l0BitmapReg_4_3_2, dut_g.l0BitmapReg_4_3_1, dut_g.l0BitmapReg_4_3_0, dut_g.l0BitmapReg_4_2_7, dut_g.l0BitmapReg_4_2_6, dut_g.l0BitmapReg_4_2_5, dut_g.l0BitmapReg_4_2_4, dut_g.l0BitmapReg_4_2_3, dut_g.l0BitmapReg_4_2_2, dut_g.l0BitmapReg_4_2_1, dut_g.l0BitmapReg_4_2_0, dut_g.l0BitmapReg_4_1_7, dut_g.l0BitmapReg_4_1_6, dut_g.l0BitmapReg_4_1_5, dut_g.l0BitmapReg_4_1_4, dut_g.l0BitmapReg_4_1_3, dut_g.l0BitmapReg_4_1_2, dut_g.l0BitmapReg_4_1_1, dut_g.l0BitmapReg_4_1_0, dut_g.l0BitmapReg_4_0_7, dut_g.l0BitmapReg_4_0_6, dut_g.l0BitmapReg_4_0_5, dut_g.l0BitmapReg_4_0_4, dut_g.l0BitmapReg_4_0_3, dut_g.l0BitmapReg_4_0_2, dut_g.l0BitmapReg_4_0_1, dut_g.l0BitmapReg_4_0_0}, {dut_i.u_core.l0_bitmap[4][3], dut_i.u_core.l0_bitmap[4][2], dut_i.u_core.l0_bitmap[4][1], dut_i.u_core.l0_bitmap[4][0]});
    chk("l0_bitmap[5]", {dut_g.l0BitmapReg_5_3_7, dut_g.l0BitmapReg_5_3_6, dut_g.l0BitmapReg_5_3_5, dut_g.l0BitmapReg_5_3_4, dut_g.l0BitmapReg_5_3_3, dut_g.l0BitmapReg_5_3_2, dut_g.l0BitmapReg_5_3_1, dut_g.l0BitmapReg_5_3_0, dut_g.l0BitmapReg_5_2_7, dut_g.l0BitmapReg_5_2_6, dut_g.l0BitmapReg_5_2_5, dut_g.l0BitmapReg_5_2_4, dut_g.l0BitmapReg_5_2_3, dut_g.l0BitmapReg_5_2_2, dut_g.l0BitmapReg_5_2_1, dut_g.l0BitmapReg_5_2_0, dut_g.l0BitmapReg_5_1_7, dut_g.l0BitmapReg_5_1_6, dut_g.l0BitmapReg_5_1_5, dut_g.l0BitmapReg_5_1_4, dut_g.l0BitmapReg_5_1_3, dut_g.l0BitmapReg_5_1_2, dut_g.l0BitmapReg_5_1_1, dut_g.l0BitmapReg_5_1_0, dut_g.l0BitmapReg_5_0_7, dut_g.l0BitmapReg_5_0_6, dut_g.l0BitmapReg_5_0_5, dut_g.l0BitmapReg_5_0_4, dut_g.l0BitmapReg_5_0_3, dut_g.l0BitmapReg_5_0_2, dut_g.l0BitmapReg_5_0_1, dut_g.l0BitmapReg_5_0_0}, {dut_i.u_core.l0_bitmap[5][3], dut_i.u_core.l0_bitmap[5][2], dut_i.u_core.l0_bitmap[5][1], dut_i.u_core.l0_bitmap[5][0]});
    chk("l0_bitmap[6]", {dut_g.l0BitmapReg_6_3_7, dut_g.l0BitmapReg_6_3_6, dut_g.l0BitmapReg_6_3_5, dut_g.l0BitmapReg_6_3_4, dut_g.l0BitmapReg_6_3_3, dut_g.l0BitmapReg_6_3_2, dut_g.l0BitmapReg_6_3_1, dut_g.l0BitmapReg_6_3_0, dut_g.l0BitmapReg_6_2_7, dut_g.l0BitmapReg_6_2_6, dut_g.l0BitmapReg_6_2_5, dut_g.l0BitmapReg_6_2_4, dut_g.l0BitmapReg_6_2_3, dut_g.l0BitmapReg_6_2_2, dut_g.l0BitmapReg_6_2_1, dut_g.l0BitmapReg_6_2_0, dut_g.l0BitmapReg_6_1_7, dut_g.l0BitmapReg_6_1_6, dut_g.l0BitmapReg_6_1_5, dut_g.l0BitmapReg_6_1_4, dut_g.l0BitmapReg_6_1_3, dut_g.l0BitmapReg_6_1_2, dut_g.l0BitmapReg_6_1_1, dut_g.l0BitmapReg_6_1_0, dut_g.l0BitmapReg_6_0_7, dut_g.l0BitmapReg_6_0_6, dut_g.l0BitmapReg_6_0_5, dut_g.l0BitmapReg_6_0_4, dut_g.l0BitmapReg_6_0_3, dut_g.l0BitmapReg_6_0_2, dut_g.l0BitmapReg_6_0_1, dut_g.l0BitmapReg_6_0_0}, {dut_i.u_core.l0_bitmap[6][3], dut_i.u_core.l0_bitmap[6][2], dut_i.u_core.l0_bitmap[6][1], dut_i.u_core.l0_bitmap[6][0]});
    chk("l0_bitmap[7]", {dut_g.l0BitmapReg_7_3_7, dut_g.l0BitmapReg_7_3_6, dut_g.l0BitmapReg_7_3_5, dut_g.l0BitmapReg_7_3_4, dut_g.l0BitmapReg_7_3_3, dut_g.l0BitmapReg_7_3_2, dut_g.l0BitmapReg_7_3_1, dut_g.l0BitmapReg_7_3_0, dut_g.l0BitmapReg_7_2_7, dut_g.l0BitmapReg_7_2_6, dut_g.l0BitmapReg_7_2_5, dut_g.l0BitmapReg_7_2_4, dut_g.l0BitmapReg_7_2_3, dut_g.l0BitmapReg_7_2_2, dut_g.l0BitmapReg_7_2_1, dut_g.l0BitmapReg_7_2_0, dut_g.l0BitmapReg_7_1_7, dut_g.l0BitmapReg_7_1_6, dut_g.l0BitmapReg_7_1_5, dut_g.l0BitmapReg_7_1_4, dut_g.l0BitmapReg_7_1_3, dut_g.l0BitmapReg_7_1_2, dut_g.l0BitmapReg_7_1_1, dut_g.l0BitmapReg_7_1_0, dut_g.l0BitmapReg_7_0_7, dut_g.l0BitmapReg_7_0_6, dut_g.l0BitmapReg_7_0_5, dut_g.l0BitmapReg_7_0_4, dut_g.l0BitmapReg_7_0_3, dut_g.l0BitmapReg_7_0_2, dut_g.l0BitmapReg_7_0_1, dut_g.l0BitmapReg_7_0_0}, {dut_i.u_core.l0_bitmap[7][3], dut_i.u_core.l0_bitmap[7][2], dut_i.u_core.l0_bitmap[7][1], dut_i.u_core.l0_bitmap[7][0]});
    chk("l0_bitmap[8]", {dut_g.l0BitmapReg_8_3_7, dut_g.l0BitmapReg_8_3_6, dut_g.l0BitmapReg_8_3_5, dut_g.l0BitmapReg_8_3_4, dut_g.l0BitmapReg_8_3_3, dut_g.l0BitmapReg_8_3_2, dut_g.l0BitmapReg_8_3_1, dut_g.l0BitmapReg_8_3_0, dut_g.l0BitmapReg_8_2_7, dut_g.l0BitmapReg_8_2_6, dut_g.l0BitmapReg_8_2_5, dut_g.l0BitmapReg_8_2_4, dut_g.l0BitmapReg_8_2_3, dut_g.l0BitmapReg_8_2_2, dut_g.l0BitmapReg_8_2_1, dut_g.l0BitmapReg_8_2_0, dut_g.l0BitmapReg_8_1_7, dut_g.l0BitmapReg_8_1_6, dut_g.l0BitmapReg_8_1_5, dut_g.l0BitmapReg_8_1_4, dut_g.l0BitmapReg_8_1_3, dut_g.l0BitmapReg_8_1_2, dut_g.l0BitmapReg_8_1_1, dut_g.l0BitmapReg_8_1_0, dut_g.l0BitmapReg_8_0_7, dut_g.l0BitmapReg_8_0_6, dut_g.l0BitmapReg_8_0_5, dut_g.l0BitmapReg_8_0_4, dut_g.l0BitmapReg_8_0_3, dut_g.l0BitmapReg_8_0_2, dut_g.l0BitmapReg_8_0_1, dut_g.l0BitmapReg_8_0_0}, {dut_i.u_core.l0_bitmap[8][3], dut_i.u_core.l0_bitmap[8][2], dut_i.u_core.l0_bitmap[8][1], dut_i.u_core.l0_bitmap[8][0]});
    chk("l0_bitmap[9]", {dut_g.l0BitmapReg_9_3_7, dut_g.l0BitmapReg_9_3_6, dut_g.l0BitmapReg_9_3_5, dut_g.l0BitmapReg_9_3_4, dut_g.l0BitmapReg_9_3_3, dut_g.l0BitmapReg_9_3_2, dut_g.l0BitmapReg_9_3_1, dut_g.l0BitmapReg_9_3_0, dut_g.l0BitmapReg_9_2_7, dut_g.l0BitmapReg_9_2_6, dut_g.l0BitmapReg_9_2_5, dut_g.l0BitmapReg_9_2_4, dut_g.l0BitmapReg_9_2_3, dut_g.l0BitmapReg_9_2_2, dut_g.l0BitmapReg_9_2_1, dut_g.l0BitmapReg_9_2_0, dut_g.l0BitmapReg_9_1_7, dut_g.l0BitmapReg_9_1_6, dut_g.l0BitmapReg_9_1_5, dut_g.l0BitmapReg_9_1_4, dut_g.l0BitmapReg_9_1_3, dut_g.l0BitmapReg_9_1_2, dut_g.l0BitmapReg_9_1_1, dut_g.l0BitmapReg_9_1_0, dut_g.l0BitmapReg_9_0_7, dut_g.l0BitmapReg_9_0_6, dut_g.l0BitmapReg_9_0_5, dut_g.l0BitmapReg_9_0_4, dut_g.l0BitmapReg_9_0_3, dut_g.l0BitmapReg_9_0_2, dut_g.l0BitmapReg_9_0_1, dut_g.l0BitmapReg_9_0_0}, {dut_i.u_core.l0_bitmap[9][3], dut_i.u_core.l0_bitmap[9][2], dut_i.u_core.l0_bitmap[9][1], dut_i.u_core.l0_bitmap[9][0]});
    chk("l0_bitmap[10]", {dut_g.l0BitmapReg_10_3_7, dut_g.l0BitmapReg_10_3_6, dut_g.l0BitmapReg_10_3_5, dut_g.l0BitmapReg_10_3_4, dut_g.l0BitmapReg_10_3_3, dut_g.l0BitmapReg_10_3_2, dut_g.l0BitmapReg_10_3_1, dut_g.l0BitmapReg_10_3_0, dut_g.l0BitmapReg_10_2_7, dut_g.l0BitmapReg_10_2_6, dut_g.l0BitmapReg_10_2_5, dut_g.l0BitmapReg_10_2_4, dut_g.l0BitmapReg_10_2_3, dut_g.l0BitmapReg_10_2_2, dut_g.l0BitmapReg_10_2_1, dut_g.l0BitmapReg_10_2_0, dut_g.l0BitmapReg_10_1_7, dut_g.l0BitmapReg_10_1_6, dut_g.l0BitmapReg_10_1_5, dut_g.l0BitmapReg_10_1_4, dut_g.l0BitmapReg_10_1_3, dut_g.l0BitmapReg_10_1_2, dut_g.l0BitmapReg_10_1_1, dut_g.l0BitmapReg_10_1_0, dut_g.l0BitmapReg_10_0_7, dut_g.l0BitmapReg_10_0_6, dut_g.l0BitmapReg_10_0_5, dut_g.l0BitmapReg_10_0_4, dut_g.l0BitmapReg_10_0_3, dut_g.l0BitmapReg_10_0_2, dut_g.l0BitmapReg_10_0_1, dut_g.l0BitmapReg_10_0_0}, {dut_i.u_core.l0_bitmap[10][3], dut_i.u_core.l0_bitmap[10][2], dut_i.u_core.l0_bitmap[10][1], dut_i.u_core.l0_bitmap[10][0]});
    chk("l0_bitmap[11]", {dut_g.l0BitmapReg_11_3_7, dut_g.l0BitmapReg_11_3_6, dut_g.l0BitmapReg_11_3_5, dut_g.l0BitmapReg_11_3_4, dut_g.l0BitmapReg_11_3_3, dut_g.l0BitmapReg_11_3_2, dut_g.l0BitmapReg_11_3_1, dut_g.l0BitmapReg_11_3_0, dut_g.l0BitmapReg_11_2_7, dut_g.l0BitmapReg_11_2_6, dut_g.l0BitmapReg_11_2_5, dut_g.l0BitmapReg_11_2_4, dut_g.l0BitmapReg_11_2_3, dut_g.l0BitmapReg_11_2_2, dut_g.l0BitmapReg_11_2_1, dut_g.l0BitmapReg_11_2_0, dut_g.l0BitmapReg_11_1_7, dut_g.l0BitmapReg_11_1_6, dut_g.l0BitmapReg_11_1_5, dut_g.l0BitmapReg_11_1_4, dut_g.l0BitmapReg_11_1_3, dut_g.l0BitmapReg_11_1_2, dut_g.l0BitmapReg_11_1_1, dut_g.l0BitmapReg_11_1_0, dut_g.l0BitmapReg_11_0_7, dut_g.l0BitmapReg_11_0_6, dut_g.l0BitmapReg_11_0_5, dut_g.l0BitmapReg_11_0_4, dut_g.l0BitmapReg_11_0_3, dut_g.l0BitmapReg_11_0_2, dut_g.l0BitmapReg_11_0_1, dut_g.l0BitmapReg_11_0_0}, {dut_i.u_core.l0_bitmap[11][3], dut_i.u_core.l0_bitmap[11][2], dut_i.u_core.l0_bitmap[11][1], dut_i.u_core.l0_bitmap[11][0]});
    chk("l0_bitmap[12]", {dut_g.l0BitmapReg_12_3_7, dut_g.l0BitmapReg_12_3_6, dut_g.l0BitmapReg_12_3_5, dut_g.l0BitmapReg_12_3_4, dut_g.l0BitmapReg_12_3_3, dut_g.l0BitmapReg_12_3_2, dut_g.l0BitmapReg_12_3_1, dut_g.l0BitmapReg_12_3_0, dut_g.l0BitmapReg_12_2_7, dut_g.l0BitmapReg_12_2_6, dut_g.l0BitmapReg_12_2_5, dut_g.l0BitmapReg_12_2_4, dut_g.l0BitmapReg_12_2_3, dut_g.l0BitmapReg_12_2_2, dut_g.l0BitmapReg_12_2_1, dut_g.l0BitmapReg_12_2_0, dut_g.l0BitmapReg_12_1_7, dut_g.l0BitmapReg_12_1_6, dut_g.l0BitmapReg_12_1_5, dut_g.l0BitmapReg_12_1_4, dut_g.l0BitmapReg_12_1_3, dut_g.l0BitmapReg_12_1_2, dut_g.l0BitmapReg_12_1_1, dut_g.l0BitmapReg_12_1_0, dut_g.l0BitmapReg_12_0_7, dut_g.l0BitmapReg_12_0_6, dut_g.l0BitmapReg_12_0_5, dut_g.l0BitmapReg_12_0_4, dut_g.l0BitmapReg_12_0_3, dut_g.l0BitmapReg_12_0_2, dut_g.l0BitmapReg_12_0_1, dut_g.l0BitmapReg_12_0_0}, {dut_i.u_core.l0_bitmap[12][3], dut_i.u_core.l0_bitmap[12][2], dut_i.u_core.l0_bitmap[12][1], dut_i.u_core.l0_bitmap[12][0]});
    chk("l0_bitmap[13]", {dut_g.l0BitmapReg_13_3_7, dut_g.l0BitmapReg_13_3_6, dut_g.l0BitmapReg_13_3_5, dut_g.l0BitmapReg_13_3_4, dut_g.l0BitmapReg_13_3_3, dut_g.l0BitmapReg_13_3_2, dut_g.l0BitmapReg_13_3_1, dut_g.l0BitmapReg_13_3_0, dut_g.l0BitmapReg_13_2_7, dut_g.l0BitmapReg_13_2_6, dut_g.l0BitmapReg_13_2_5, dut_g.l0BitmapReg_13_2_4, dut_g.l0BitmapReg_13_2_3, dut_g.l0BitmapReg_13_2_2, dut_g.l0BitmapReg_13_2_1, dut_g.l0BitmapReg_13_2_0, dut_g.l0BitmapReg_13_1_7, dut_g.l0BitmapReg_13_1_6, dut_g.l0BitmapReg_13_1_5, dut_g.l0BitmapReg_13_1_4, dut_g.l0BitmapReg_13_1_3, dut_g.l0BitmapReg_13_1_2, dut_g.l0BitmapReg_13_1_1, dut_g.l0BitmapReg_13_1_0, dut_g.l0BitmapReg_13_0_7, dut_g.l0BitmapReg_13_0_6, dut_g.l0BitmapReg_13_0_5, dut_g.l0BitmapReg_13_0_4, dut_g.l0BitmapReg_13_0_3, dut_g.l0BitmapReg_13_0_2, dut_g.l0BitmapReg_13_0_1, dut_g.l0BitmapReg_13_0_0}, {dut_i.u_core.l0_bitmap[13][3], dut_i.u_core.l0_bitmap[13][2], dut_i.u_core.l0_bitmap[13][1], dut_i.u_core.l0_bitmap[13][0]});
    chk("l0_bitmap[14]", {dut_g.l0BitmapReg_14_3_7, dut_g.l0BitmapReg_14_3_6, dut_g.l0BitmapReg_14_3_5, dut_g.l0BitmapReg_14_3_4, dut_g.l0BitmapReg_14_3_3, dut_g.l0BitmapReg_14_3_2, dut_g.l0BitmapReg_14_3_1, dut_g.l0BitmapReg_14_3_0, dut_g.l0BitmapReg_14_2_7, dut_g.l0BitmapReg_14_2_6, dut_g.l0BitmapReg_14_2_5, dut_g.l0BitmapReg_14_2_4, dut_g.l0BitmapReg_14_2_3, dut_g.l0BitmapReg_14_2_2, dut_g.l0BitmapReg_14_2_1, dut_g.l0BitmapReg_14_2_0, dut_g.l0BitmapReg_14_1_7, dut_g.l0BitmapReg_14_1_6, dut_g.l0BitmapReg_14_1_5, dut_g.l0BitmapReg_14_1_4, dut_g.l0BitmapReg_14_1_3, dut_g.l0BitmapReg_14_1_2, dut_g.l0BitmapReg_14_1_1, dut_g.l0BitmapReg_14_1_0, dut_g.l0BitmapReg_14_0_7, dut_g.l0BitmapReg_14_0_6, dut_g.l0BitmapReg_14_0_5, dut_g.l0BitmapReg_14_0_4, dut_g.l0BitmapReg_14_0_3, dut_g.l0BitmapReg_14_0_2, dut_g.l0BitmapReg_14_0_1, dut_g.l0BitmapReg_14_0_0}, {dut_i.u_core.l0_bitmap[14][3], dut_i.u_core.l0_bitmap[14][2], dut_i.u_core.l0_bitmap[14][1], dut_i.u_core.l0_bitmap[14][0]});
    chk("l0_bitmap[15]", {dut_g.l0BitmapReg_15_3_7, dut_g.l0BitmapReg_15_3_6, dut_g.l0BitmapReg_15_3_5, dut_g.l0BitmapReg_15_3_4, dut_g.l0BitmapReg_15_3_3, dut_g.l0BitmapReg_15_3_2, dut_g.l0BitmapReg_15_3_1, dut_g.l0BitmapReg_15_3_0, dut_g.l0BitmapReg_15_2_7, dut_g.l0BitmapReg_15_2_6, dut_g.l0BitmapReg_15_2_5, dut_g.l0BitmapReg_15_2_4, dut_g.l0BitmapReg_15_2_3, dut_g.l0BitmapReg_15_2_2, dut_g.l0BitmapReg_15_2_1, dut_g.l0BitmapReg_15_2_0, dut_g.l0BitmapReg_15_1_7, dut_g.l0BitmapReg_15_1_6, dut_g.l0BitmapReg_15_1_5, dut_g.l0BitmapReg_15_1_4, dut_g.l0BitmapReg_15_1_3, dut_g.l0BitmapReg_15_1_2, dut_g.l0BitmapReg_15_1_1, dut_g.l0BitmapReg_15_1_0, dut_g.l0BitmapReg_15_0_7, dut_g.l0BitmapReg_15_0_6, dut_g.l0BitmapReg_15_0_5, dut_g.l0BitmapReg_15_0_4, dut_g.l0BitmapReg_15_0_3, dut_g.l0BitmapReg_15_0_2, dut_g.l0BitmapReg_15_0_1, dut_g.l0BitmapReg_15_0_0}, {dut_i.u_core.l0_bitmap[15][3], dut_i.u_core.l0_bitmap[15][2], dut_i.u_core.l0_bitmap[15][1], dut_i.u_core.l0_bitmap[15][0]});
    chk("l0_bitmap[16]", {dut_g.l0BitmapReg_16_3_7, dut_g.l0BitmapReg_16_3_6, dut_g.l0BitmapReg_16_3_5, dut_g.l0BitmapReg_16_3_4, dut_g.l0BitmapReg_16_3_3, dut_g.l0BitmapReg_16_3_2, dut_g.l0BitmapReg_16_3_1, dut_g.l0BitmapReg_16_3_0, dut_g.l0BitmapReg_16_2_7, dut_g.l0BitmapReg_16_2_6, dut_g.l0BitmapReg_16_2_5, dut_g.l0BitmapReg_16_2_4, dut_g.l0BitmapReg_16_2_3, dut_g.l0BitmapReg_16_2_2, dut_g.l0BitmapReg_16_2_1, dut_g.l0BitmapReg_16_2_0, dut_g.l0BitmapReg_16_1_7, dut_g.l0BitmapReg_16_1_6, dut_g.l0BitmapReg_16_1_5, dut_g.l0BitmapReg_16_1_4, dut_g.l0BitmapReg_16_1_3, dut_g.l0BitmapReg_16_1_2, dut_g.l0BitmapReg_16_1_1, dut_g.l0BitmapReg_16_1_0, dut_g.l0BitmapReg_16_0_7, dut_g.l0BitmapReg_16_0_6, dut_g.l0BitmapReg_16_0_5, dut_g.l0BitmapReg_16_0_4, dut_g.l0BitmapReg_16_0_3, dut_g.l0BitmapReg_16_0_2, dut_g.l0BitmapReg_16_0_1, dut_g.l0BitmapReg_16_0_0}, {dut_i.u_core.l0_bitmap[16][3], dut_i.u_core.l0_bitmap[16][2], dut_i.u_core.l0_bitmap[16][1], dut_i.u_core.l0_bitmap[16][0]});
    chk("l0_bitmap[17]", {dut_g.l0BitmapReg_17_3_7, dut_g.l0BitmapReg_17_3_6, dut_g.l0BitmapReg_17_3_5, dut_g.l0BitmapReg_17_3_4, dut_g.l0BitmapReg_17_3_3, dut_g.l0BitmapReg_17_3_2, dut_g.l0BitmapReg_17_3_1, dut_g.l0BitmapReg_17_3_0, dut_g.l0BitmapReg_17_2_7, dut_g.l0BitmapReg_17_2_6, dut_g.l0BitmapReg_17_2_5, dut_g.l0BitmapReg_17_2_4, dut_g.l0BitmapReg_17_2_3, dut_g.l0BitmapReg_17_2_2, dut_g.l0BitmapReg_17_2_1, dut_g.l0BitmapReg_17_2_0, dut_g.l0BitmapReg_17_1_7, dut_g.l0BitmapReg_17_1_6, dut_g.l0BitmapReg_17_1_5, dut_g.l0BitmapReg_17_1_4, dut_g.l0BitmapReg_17_1_3, dut_g.l0BitmapReg_17_1_2, dut_g.l0BitmapReg_17_1_1, dut_g.l0BitmapReg_17_1_0, dut_g.l0BitmapReg_17_0_7, dut_g.l0BitmapReg_17_0_6, dut_g.l0BitmapReg_17_0_5, dut_g.l0BitmapReg_17_0_4, dut_g.l0BitmapReg_17_0_3, dut_g.l0BitmapReg_17_0_2, dut_g.l0BitmapReg_17_0_1, dut_g.l0BitmapReg_17_0_0}, {dut_i.u_core.l0_bitmap[17][3], dut_i.u_core.l0_bitmap[17][2], dut_i.u_core.l0_bitmap[17][1], dut_i.u_core.l0_bitmap[17][0]});
    chk("l0_bitmap[18]", {dut_g.l0BitmapReg_18_3_7, dut_g.l0BitmapReg_18_3_6, dut_g.l0BitmapReg_18_3_5, dut_g.l0BitmapReg_18_3_4, dut_g.l0BitmapReg_18_3_3, dut_g.l0BitmapReg_18_3_2, dut_g.l0BitmapReg_18_3_1, dut_g.l0BitmapReg_18_3_0, dut_g.l0BitmapReg_18_2_7, dut_g.l0BitmapReg_18_2_6, dut_g.l0BitmapReg_18_2_5, dut_g.l0BitmapReg_18_2_4, dut_g.l0BitmapReg_18_2_3, dut_g.l0BitmapReg_18_2_2, dut_g.l0BitmapReg_18_2_1, dut_g.l0BitmapReg_18_2_0, dut_g.l0BitmapReg_18_1_7, dut_g.l0BitmapReg_18_1_6, dut_g.l0BitmapReg_18_1_5, dut_g.l0BitmapReg_18_1_4, dut_g.l0BitmapReg_18_1_3, dut_g.l0BitmapReg_18_1_2, dut_g.l0BitmapReg_18_1_1, dut_g.l0BitmapReg_18_1_0, dut_g.l0BitmapReg_18_0_7, dut_g.l0BitmapReg_18_0_6, dut_g.l0BitmapReg_18_0_5, dut_g.l0BitmapReg_18_0_4, dut_g.l0BitmapReg_18_0_3, dut_g.l0BitmapReg_18_0_2, dut_g.l0BitmapReg_18_0_1, dut_g.l0BitmapReg_18_0_0}, {dut_i.u_core.l0_bitmap[18][3], dut_i.u_core.l0_bitmap[18][2], dut_i.u_core.l0_bitmap[18][1], dut_i.u_core.l0_bitmap[18][0]});
    chk("l0_bitmap[19]", {dut_g.l0BitmapReg_19_3_7, dut_g.l0BitmapReg_19_3_6, dut_g.l0BitmapReg_19_3_5, dut_g.l0BitmapReg_19_3_4, dut_g.l0BitmapReg_19_3_3, dut_g.l0BitmapReg_19_3_2, dut_g.l0BitmapReg_19_3_1, dut_g.l0BitmapReg_19_3_0, dut_g.l0BitmapReg_19_2_7, dut_g.l0BitmapReg_19_2_6, dut_g.l0BitmapReg_19_2_5, dut_g.l0BitmapReg_19_2_4, dut_g.l0BitmapReg_19_2_3, dut_g.l0BitmapReg_19_2_2, dut_g.l0BitmapReg_19_2_1, dut_g.l0BitmapReg_19_2_0, dut_g.l0BitmapReg_19_1_7, dut_g.l0BitmapReg_19_1_6, dut_g.l0BitmapReg_19_1_5, dut_g.l0BitmapReg_19_1_4, dut_g.l0BitmapReg_19_1_3, dut_g.l0BitmapReg_19_1_2, dut_g.l0BitmapReg_19_1_1, dut_g.l0BitmapReg_19_1_0, dut_g.l0BitmapReg_19_0_7, dut_g.l0BitmapReg_19_0_6, dut_g.l0BitmapReg_19_0_5, dut_g.l0BitmapReg_19_0_4, dut_g.l0BitmapReg_19_0_3, dut_g.l0BitmapReg_19_0_2, dut_g.l0BitmapReg_19_0_1, dut_g.l0BitmapReg_19_0_0}, {dut_i.u_core.l0_bitmap[19][3], dut_i.u_core.l0_bitmap[19][2], dut_i.u_core.l0_bitmap[19][1], dut_i.u_core.l0_bitmap[19][0]});
    chk("l0_bitmap[20]", {dut_g.l0BitmapReg_20_3_7, dut_g.l0BitmapReg_20_3_6, dut_g.l0BitmapReg_20_3_5, dut_g.l0BitmapReg_20_3_4, dut_g.l0BitmapReg_20_3_3, dut_g.l0BitmapReg_20_3_2, dut_g.l0BitmapReg_20_3_1, dut_g.l0BitmapReg_20_3_0, dut_g.l0BitmapReg_20_2_7, dut_g.l0BitmapReg_20_2_6, dut_g.l0BitmapReg_20_2_5, dut_g.l0BitmapReg_20_2_4, dut_g.l0BitmapReg_20_2_3, dut_g.l0BitmapReg_20_2_2, dut_g.l0BitmapReg_20_2_1, dut_g.l0BitmapReg_20_2_0, dut_g.l0BitmapReg_20_1_7, dut_g.l0BitmapReg_20_1_6, dut_g.l0BitmapReg_20_1_5, dut_g.l0BitmapReg_20_1_4, dut_g.l0BitmapReg_20_1_3, dut_g.l0BitmapReg_20_1_2, dut_g.l0BitmapReg_20_1_1, dut_g.l0BitmapReg_20_1_0, dut_g.l0BitmapReg_20_0_7, dut_g.l0BitmapReg_20_0_6, dut_g.l0BitmapReg_20_0_5, dut_g.l0BitmapReg_20_0_4, dut_g.l0BitmapReg_20_0_3, dut_g.l0BitmapReg_20_0_2, dut_g.l0BitmapReg_20_0_1, dut_g.l0BitmapReg_20_0_0}, {dut_i.u_core.l0_bitmap[20][3], dut_i.u_core.l0_bitmap[20][2], dut_i.u_core.l0_bitmap[20][1], dut_i.u_core.l0_bitmap[20][0]});
    chk("l0_bitmap[21]", {dut_g.l0BitmapReg_21_3_7, dut_g.l0BitmapReg_21_3_6, dut_g.l0BitmapReg_21_3_5, dut_g.l0BitmapReg_21_3_4, dut_g.l0BitmapReg_21_3_3, dut_g.l0BitmapReg_21_3_2, dut_g.l0BitmapReg_21_3_1, dut_g.l0BitmapReg_21_3_0, dut_g.l0BitmapReg_21_2_7, dut_g.l0BitmapReg_21_2_6, dut_g.l0BitmapReg_21_2_5, dut_g.l0BitmapReg_21_2_4, dut_g.l0BitmapReg_21_2_3, dut_g.l0BitmapReg_21_2_2, dut_g.l0BitmapReg_21_2_1, dut_g.l0BitmapReg_21_2_0, dut_g.l0BitmapReg_21_1_7, dut_g.l0BitmapReg_21_1_6, dut_g.l0BitmapReg_21_1_5, dut_g.l0BitmapReg_21_1_4, dut_g.l0BitmapReg_21_1_3, dut_g.l0BitmapReg_21_1_2, dut_g.l0BitmapReg_21_1_1, dut_g.l0BitmapReg_21_1_0, dut_g.l0BitmapReg_21_0_7, dut_g.l0BitmapReg_21_0_6, dut_g.l0BitmapReg_21_0_5, dut_g.l0BitmapReg_21_0_4, dut_g.l0BitmapReg_21_0_3, dut_g.l0BitmapReg_21_0_2, dut_g.l0BitmapReg_21_0_1, dut_g.l0BitmapReg_21_0_0}, {dut_i.u_core.l0_bitmap[21][3], dut_i.u_core.l0_bitmap[21][2], dut_i.u_core.l0_bitmap[21][1], dut_i.u_core.l0_bitmap[21][0]});
    chk("l0_bitmap[22]", {dut_g.l0BitmapReg_22_3_7, dut_g.l0BitmapReg_22_3_6, dut_g.l0BitmapReg_22_3_5, dut_g.l0BitmapReg_22_3_4, dut_g.l0BitmapReg_22_3_3, dut_g.l0BitmapReg_22_3_2, dut_g.l0BitmapReg_22_3_1, dut_g.l0BitmapReg_22_3_0, dut_g.l0BitmapReg_22_2_7, dut_g.l0BitmapReg_22_2_6, dut_g.l0BitmapReg_22_2_5, dut_g.l0BitmapReg_22_2_4, dut_g.l0BitmapReg_22_2_3, dut_g.l0BitmapReg_22_2_2, dut_g.l0BitmapReg_22_2_1, dut_g.l0BitmapReg_22_2_0, dut_g.l0BitmapReg_22_1_7, dut_g.l0BitmapReg_22_1_6, dut_g.l0BitmapReg_22_1_5, dut_g.l0BitmapReg_22_1_4, dut_g.l0BitmapReg_22_1_3, dut_g.l0BitmapReg_22_1_2, dut_g.l0BitmapReg_22_1_1, dut_g.l0BitmapReg_22_1_0, dut_g.l0BitmapReg_22_0_7, dut_g.l0BitmapReg_22_0_6, dut_g.l0BitmapReg_22_0_5, dut_g.l0BitmapReg_22_0_4, dut_g.l0BitmapReg_22_0_3, dut_g.l0BitmapReg_22_0_2, dut_g.l0BitmapReg_22_0_1, dut_g.l0BitmapReg_22_0_0}, {dut_i.u_core.l0_bitmap[22][3], dut_i.u_core.l0_bitmap[22][2], dut_i.u_core.l0_bitmap[22][1], dut_i.u_core.l0_bitmap[22][0]});
    chk("l0_bitmap[23]", {dut_g.l0BitmapReg_23_3_7, dut_g.l0BitmapReg_23_3_6, dut_g.l0BitmapReg_23_3_5, dut_g.l0BitmapReg_23_3_4, dut_g.l0BitmapReg_23_3_3, dut_g.l0BitmapReg_23_3_2, dut_g.l0BitmapReg_23_3_1, dut_g.l0BitmapReg_23_3_0, dut_g.l0BitmapReg_23_2_7, dut_g.l0BitmapReg_23_2_6, dut_g.l0BitmapReg_23_2_5, dut_g.l0BitmapReg_23_2_4, dut_g.l0BitmapReg_23_2_3, dut_g.l0BitmapReg_23_2_2, dut_g.l0BitmapReg_23_2_1, dut_g.l0BitmapReg_23_2_0, dut_g.l0BitmapReg_23_1_7, dut_g.l0BitmapReg_23_1_6, dut_g.l0BitmapReg_23_1_5, dut_g.l0BitmapReg_23_1_4, dut_g.l0BitmapReg_23_1_3, dut_g.l0BitmapReg_23_1_2, dut_g.l0BitmapReg_23_1_1, dut_g.l0BitmapReg_23_1_0, dut_g.l0BitmapReg_23_0_7, dut_g.l0BitmapReg_23_0_6, dut_g.l0BitmapReg_23_0_5, dut_g.l0BitmapReg_23_0_4, dut_g.l0BitmapReg_23_0_3, dut_g.l0BitmapReg_23_0_2, dut_g.l0BitmapReg_23_0_1, dut_g.l0BitmapReg_23_0_0}, {dut_i.u_core.l0_bitmap[23][3], dut_i.u_core.l0_bitmap[23][2], dut_i.u_core.l0_bitmap[23][1], dut_i.u_core.l0_bitmap[23][0]});
    chk("l0_bitmap[24]", {dut_g.l0BitmapReg_24_3_7, dut_g.l0BitmapReg_24_3_6, dut_g.l0BitmapReg_24_3_5, dut_g.l0BitmapReg_24_3_4, dut_g.l0BitmapReg_24_3_3, dut_g.l0BitmapReg_24_3_2, dut_g.l0BitmapReg_24_3_1, dut_g.l0BitmapReg_24_3_0, dut_g.l0BitmapReg_24_2_7, dut_g.l0BitmapReg_24_2_6, dut_g.l0BitmapReg_24_2_5, dut_g.l0BitmapReg_24_2_4, dut_g.l0BitmapReg_24_2_3, dut_g.l0BitmapReg_24_2_2, dut_g.l0BitmapReg_24_2_1, dut_g.l0BitmapReg_24_2_0, dut_g.l0BitmapReg_24_1_7, dut_g.l0BitmapReg_24_1_6, dut_g.l0BitmapReg_24_1_5, dut_g.l0BitmapReg_24_1_4, dut_g.l0BitmapReg_24_1_3, dut_g.l0BitmapReg_24_1_2, dut_g.l0BitmapReg_24_1_1, dut_g.l0BitmapReg_24_1_0, dut_g.l0BitmapReg_24_0_7, dut_g.l0BitmapReg_24_0_6, dut_g.l0BitmapReg_24_0_5, dut_g.l0BitmapReg_24_0_4, dut_g.l0BitmapReg_24_0_3, dut_g.l0BitmapReg_24_0_2, dut_g.l0BitmapReg_24_0_1, dut_g.l0BitmapReg_24_0_0}, {dut_i.u_core.l0_bitmap[24][3], dut_i.u_core.l0_bitmap[24][2], dut_i.u_core.l0_bitmap[24][1], dut_i.u_core.l0_bitmap[24][0]});
    chk("l0_bitmap[25]", {dut_g.l0BitmapReg_25_3_7, dut_g.l0BitmapReg_25_3_6, dut_g.l0BitmapReg_25_3_5, dut_g.l0BitmapReg_25_3_4, dut_g.l0BitmapReg_25_3_3, dut_g.l0BitmapReg_25_3_2, dut_g.l0BitmapReg_25_3_1, dut_g.l0BitmapReg_25_3_0, dut_g.l0BitmapReg_25_2_7, dut_g.l0BitmapReg_25_2_6, dut_g.l0BitmapReg_25_2_5, dut_g.l0BitmapReg_25_2_4, dut_g.l0BitmapReg_25_2_3, dut_g.l0BitmapReg_25_2_2, dut_g.l0BitmapReg_25_2_1, dut_g.l0BitmapReg_25_2_0, dut_g.l0BitmapReg_25_1_7, dut_g.l0BitmapReg_25_1_6, dut_g.l0BitmapReg_25_1_5, dut_g.l0BitmapReg_25_1_4, dut_g.l0BitmapReg_25_1_3, dut_g.l0BitmapReg_25_1_2, dut_g.l0BitmapReg_25_1_1, dut_g.l0BitmapReg_25_1_0, dut_g.l0BitmapReg_25_0_7, dut_g.l0BitmapReg_25_0_6, dut_g.l0BitmapReg_25_0_5, dut_g.l0BitmapReg_25_0_4, dut_g.l0BitmapReg_25_0_3, dut_g.l0BitmapReg_25_0_2, dut_g.l0BitmapReg_25_0_1, dut_g.l0BitmapReg_25_0_0}, {dut_i.u_core.l0_bitmap[25][3], dut_i.u_core.l0_bitmap[25][2], dut_i.u_core.l0_bitmap[25][1], dut_i.u_core.l0_bitmap[25][0]});
    chk("l0_bitmap[26]", {dut_g.l0BitmapReg_26_3_7, dut_g.l0BitmapReg_26_3_6, dut_g.l0BitmapReg_26_3_5, dut_g.l0BitmapReg_26_3_4, dut_g.l0BitmapReg_26_3_3, dut_g.l0BitmapReg_26_3_2, dut_g.l0BitmapReg_26_3_1, dut_g.l0BitmapReg_26_3_0, dut_g.l0BitmapReg_26_2_7, dut_g.l0BitmapReg_26_2_6, dut_g.l0BitmapReg_26_2_5, dut_g.l0BitmapReg_26_2_4, dut_g.l0BitmapReg_26_2_3, dut_g.l0BitmapReg_26_2_2, dut_g.l0BitmapReg_26_2_1, dut_g.l0BitmapReg_26_2_0, dut_g.l0BitmapReg_26_1_7, dut_g.l0BitmapReg_26_1_6, dut_g.l0BitmapReg_26_1_5, dut_g.l0BitmapReg_26_1_4, dut_g.l0BitmapReg_26_1_3, dut_g.l0BitmapReg_26_1_2, dut_g.l0BitmapReg_26_1_1, dut_g.l0BitmapReg_26_1_0, dut_g.l0BitmapReg_26_0_7, dut_g.l0BitmapReg_26_0_6, dut_g.l0BitmapReg_26_0_5, dut_g.l0BitmapReg_26_0_4, dut_g.l0BitmapReg_26_0_3, dut_g.l0BitmapReg_26_0_2, dut_g.l0BitmapReg_26_0_1, dut_g.l0BitmapReg_26_0_0}, {dut_i.u_core.l0_bitmap[26][3], dut_i.u_core.l0_bitmap[26][2], dut_i.u_core.l0_bitmap[26][1], dut_i.u_core.l0_bitmap[26][0]});
    chk("l0_bitmap[27]", {dut_g.l0BitmapReg_27_3_7, dut_g.l0BitmapReg_27_3_6, dut_g.l0BitmapReg_27_3_5, dut_g.l0BitmapReg_27_3_4, dut_g.l0BitmapReg_27_3_3, dut_g.l0BitmapReg_27_3_2, dut_g.l0BitmapReg_27_3_1, dut_g.l0BitmapReg_27_3_0, dut_g.l0BitmapReg_27_2_7, dut_g.l0BitmapReg_27_2_6, dut_g.l0BitmapReg_27_2_5, dut_g.l0BitmapReg_27_2_4, dut_g.l0BitmapReg_27_2_3, dut_g.l0BitmapReg_27_2_2, dut_g.l0BitmapReg_27_2_1, dut_g.l0BitmapReg_27_2_0, dut_g.l0BitmapReg_27_1_7, dut_g.l0BitmapReg_27_1_6, dut_g.l0BitmapReg_27_1_5, dut_g.l0BitmapReg_27_1_4, dut_g.l0BitmapReg_27_1_3, dut_g.l0BitmapReg_27_1_2, dut_g.l0BitmapReg_27_1_1, dut_g.l0BitmapReg_27_1_0, dut_g.l0BitmapReg_27_0_7, dut_g.l0BitmapReg_27_0_6, dut_g.l0BitmapReg_27_0_5, dut_g.l0BitmapReg_27_0_4, dut_g.l0BitmapReg_27_0_3, dut_g.l0BitmapReg_27_0_2, dut_g.l0BitmapReg_27_0_1, dut_g.l0BitmapReg_27_0_0}, {dut_i.u_core.l0_bitmap[27][3], dut_i.u_core.l0_bitmap[27][2], dut_i.u_core.l0_bitmap[27][1], dut_i.u_core.l0_bitmap[27][0]});
    chk("l0_bitmap[28]", {dut_g.l0BitmapReg_28_3_7, dut_g.l0BitmapReg_28_3_6, dut_g.l0BitmapReg_28_3_5, dut_g.l0BitmapReg_28_3_4, dut_g.l0BitmapReg_28_3_3, dut_g.l0BitmapReg_28_3_2, dut_g.l0BitmapReg_28_3_1, dut_g.l0BitmapReg_28_3_0, dut_g.l0BitmapReg_28_2_7, dut_g.l0BitmapReg_28_2_6, dut_g.l0BitmapReg_28_2_5, dut_g.l0BitmapReg_28_2_4, dut_g.l0BitmapReg_28_2_3, dut_g.l0BitmapReg_28_2_2, dut_g.l0BitmapReg_28_2_1, dut_g.l0BitmapReg_28_2_0, dut_g.l0BitmapReg_28_1_7, dut_g.l0BitmapReg_28_1_6, dut_g.l0BitmapReg_28_1_5, dut_g.l0BitmapReg_28_1_4, dut_g.l0BitmapReg_28_1_3, dut_g.l0BitmapReg_28_1_2, dut_g.l0BitmapReg_28_1_1, dut_g.l0BitmapReg_28_1_0, dut_g.l0BitmapReg_28_0_7, dut_g.l0BitmapReg_28_0_6, dut_g.l0BitmapReg_28_0_5, dut_g.l0BitmapReg_28_0_4, dut_g.l0BitmapReg_28_0_3, dut_g.l0BitmapReg_28_0_2, dut_g.l0BitmapReg_28_0_1, dut_g.l0BitmapReg_28_0_0}, {dut_i.u_core.l0_bitmap[28][3], dut_i.u_core.l0_bitmap[28][2], dut_i.u_core.l0_bitmap[28][1], dut_i.u_core.l0_bitmap[28][0]});
    chk("l0_bitmap[29]", {dut_g.l0BitmapReg_29_3_7, dut_g.l0BitmapReg_29_3_6, dut_g.l0BitmapReg_29_3_5, dut_g.l0BitmapReg_29_3_4, dut_g.l0BitmapReg_29_3_3, dut_g.l0BitmapReg_29_3_2, dut_g.l0BitmapReg_29_3_1, dut_g.l0BitmapReg_29_3_0, dut_g.l0BitmapReg_29_2_7, dut_g.l0BitmapReg_29_2_6, dut_g.l0BitmapReg_29_2_5, dut_g.l0BitmapReg_29_2_4, dut_g.l0BitmapReg_29_2_3, dut_g.l0BitmapReg_29_2_2, dut_g.l0BitmapReg_29_2_1, dut_g.l0BitmapReg_29_2_0, dut_g.l0BitmapReg_29_1_7, dut_g.l0BitmapReg_29_1_6, dut_g.l0BitmapReg_29_1_5, dut_g.l0BitmapReg_29_1_4, dut_g.l0BitmapReg_29_1_3, dut_g.l0BitmapReg_29_1_2, dut_g.l0BitmapReg_29_1_1, dut_g.l0BitmapReg_29_1_0, dut_g.l0BitmapReg_29_0_7, dut_g.l0BitmapReg_29_0_6, dut_g.l0BitmapReg_29_0_5, dut_g.l0BitmapReg_29_0_4, dut_g.l0BitmapReg_29_0_3, dut_g.l0BitmapReg_29_0_2, dut_g.l0BitmapReg_29_0_1, dut_g.l0BitmapReg_29_0_0}, {dut_i.u_core.l0_bitmap[29][3], dut_i.u_core.l0_bitmap[29][2], dut_i.u_core.l0_bitmap[29][1], dut_i.u_core.l0_bitmap[29][0]});
    chk("l0_bitmap[30]", {dut_g.l0BitmapReg_30_3_7, dut_g.l0BitmapReg_30_3_6, dut_g.l0BitmapReg_30_3_5, dut_g.l0BitmapReg_30_3_4, dut_g.l0BitmapReg_30_3_3, dut_g.l0BitmapReg_30_3_2, dut_g.l0BitmapReg_30_3_1, dut_g.l0BitmapReg_30_3_0, dut_g.l0BitmapReg_30_2_7, dut_g.l0BitmapReg_30_2_6, dut_g.l0BitmapReg_30_2_5, dut_g.l0BitmapReg_30_2_4, dut_g.l0BitmapReg_30_2_3, dut_g.l0BitmapReg_30_2_2, dut_g.l0BitmapReg_30_2_1, dut_g.l0BitmapReg_30_2_0, dut_g.l0BitmapReg_30_1_7, dut_g.l0BitmapReg_30_1_6, dut_g.l0BitmapReg_30_1_5, dut_g.l0BitmapReg_30_1_4, dut_g.l0BitmapReg_30_1_3, dut_g.l0BitmapReg_30_1_2, dut_g.l0BitmapReg_30_1_1, dut_g.l0BitmapReg_30_1_0, dut_g.l0BitmapReg_30_0_7, dut_g.l0BitmapReg_30_0_6, dut_g.l0BitmapReg_30_0_5, dut_g.l0BitmapReg_30_0_4, dut_g.l0BitmapReg_30_0_3, dut_g.l0BitmapReg_30_0_2, dut_g.l0BitmapReg_30_0_1, dut_g.l0BitmapReg_30_0_0}, {dut_i.u_core.l0_bitmap[30][3], dut_i.u_core.l0_bitmap[30][2], dut_i.u_core.l0_bitmap[30][1], dut_i.u_core.l0_bitmap[30][0]});
    chk("l0_bitmap[31]", {dut_g.l0BitmapReg_31_3_7, dut_g.l0BitmapReg_31_3_6, dut_g.l0BitmapReg_31_3_5, dut_g.l0BitmapReg_31_3_4, dut_g.l0BitmapReg_31_3_3, dut_g.l0BitmapReg_31_3_2, dut_g.l0BitmapReg_31_3_1, dut_g.l0BitmapReg_31_3_0, dut_g.l0BitmapReg_31_2_7, dut_g.l0BitmapReg_31_2_6, dut_g.l0BitmapReg_31_2_5, dut_g.l0BitmapReg_31_2_4, dut_g.l0BitmapReg_31_2_3, dut_g.l0BitmapReg_31_2_2, dut_g.l0BitmapReg_31_2_1, dut_g.l0BitmapReg_31_2_0, dut_g.l0BitmapReg_31_1_7, dut_g.l0BitmapReg_31_1_6, dut_g.l0BitmapReg_31_1_5, dut_g.l0BitmapReg_31_1_4, dut_g.l0BitmapReg_31_1_3, dut_g.l0BitmapReg_31_1_2, dut_g.l0BitmapReg_31_1_1, dut_g.l0BitmapReg_31_1_0, dut_g.l0BitmapReg_31_0_7, dut_g.l0BitmapReg_31_0_6, dut_g.l0BitmapReg_31_0_5, dut_g.l0BitmapReg_31_0_4, dut_g.l0BitmapReg_31_0_3, dut_g.l0BitmapReg_31_0_2, dut_g.l0BitmapReg_31_0_1, dut_g.l0BitmapReg_31_0_0}, {dut_i.u_core.l0_bitmap[31][3], dut_i.u_core.l0_bitmap[31][2], dut_i.u_core.l0_bitmap[31][1], dut_i.u_core.l0_bitmap[31][0]});
    chk("l0_bitmap[32]", {dut_g.l0BitmapReg_32_3_7, dut_g.l0BitmapReg_32_3_6, dut_g.l0BitmapReg_32_3_5, dut_g.l0BitmapReg_32_3_4, dut_g.l0BitmapReg_32_3_3, dut_g.l0BitmapReg_32_3_2, dut_g.l0BitmapReg_32_3_1, dut_g.l0BitmapReg_32_3_0, dut_g.l0BitmapReg_32_2_7, dut_g.l0BitmapReg_32_2_6, dut_g.l0BitmapReg_32_2_5, dut_g.l0BitmapReg_32_2_4, dut_g.l0BitmapReg_32_2_3, dut_g.l0BitmapReg_32_2_2, dut_g.l0BitmapReg_32_2_1, dut_g.l0BitmapReg_32_2_0, dut_g.l0BitmapReg_32_1_7, dut_g.l0BitmapReg_32_1_6, dut_g.l0BitmapReg_32_1_5, dut_g.l0BitmapReg_32_1_4, dut_g.l0BitmapReg_32_1_3, dut_g.l0BitmapReg_32_1_2, dut_g.l0BitmapReg_32_1_1, dut_g.l0BitmapReg_32_1_0, dut_g.l0BitmapReg_32_0_7, dut_g.l0BitmapReg_32_0_6, dut_g.l0BitmapReg_32_0_5, dut_g.l0BitmapReg_32_0_4, dut_g.l0BitmapReg_32_0_3, dut_g.l0BitmapReg_32_0_2, dut_g.l0BitmapReg_32_0_1, dut_g.l0BitmapReg_32_0_0}, {dut_i.u_core.l0_bitmap[32][3], dut_i.u_core.l0_bitmap[32][2], dut_i.u_core.l0_bitmap[32][1], dut_i.u_core.l0_bitmap[32][0]});
    chk("l0_bitmap[33]", {dut_g.l0BitmapReg_33_3_7, dut_g.l0BitmapReg_33_3_6, dut_g.l0BitmapReg_33_3_5, dut_g.l0BitmapReg_33_3_4, dut_g.l0BitmapReg_33_3_3, dut_g.l0BitmapReg_33_3_2, dut_g.l0BitmapReg_33_3_1, dut_g.l0BitmapReg_33_3_0, dut_g.l0BitmapReg_33_2_7, dut_g.l0BitmapReg_33_2_6, dut_g.l0BitmapReg_33_2_5, dut_g.l0BitmapReg_33_2_4, dut_g.l0BitmapReg_33_2_3, dut_g.l0BitmapReg_33_2_2, dut_g.l0BitmapReg_33_2_1, dut_g.l0BitmapReg_33_2_0, dut_g.l0BitmapReg_33_1_7, dut_g.l0BitmapReg_33_1_6, dut_g.l0BitmapReg_33_1_5, dut_g.l0BitmapReg_33_1_4, dut_g.l0BitmapReg_33_1_3, dut_g.l0BitmapReg_33_1_2, dut_g.l0BitmapReg_33_1_1, dut_g.l0BitmapReg_33_1_0, dut_g.l0BitmapReg_33_0_7, dut_g.l0BitmapReg_33_0_6, dut_g.l0BitmapReg_33_0_5, dut_g.l0BitmapReg_33_0_4, dut_g.l0BitmapReg_33_0_3, dut_g.l0BitmapReg_33_0_2, dut_g.l0BitmapReg_33_0_1, dut_g.l0BitmapReg_33_0_0}, {dut_i.u_core.l0_bitmap[33][3], dut_i.u_core.l0_bitmap[33][2], dut_i.u_core.l0_bitmap[33][1], dut_i.u_core.l0_bitmap[33][0]});
    chk("l0_bitmap[34]", {dut_g.l0BitmapReg_34_3_7, dut_g.l0BitmapReg_34_3_6, dut_g.l0BitmapReg_34_3_5, dut_g.l0BitmapReg_34_3_4, dut_g.l0BitmapReg_34_3_3, dut_g.l0BitmapReg_34_3_2, dut_g.l0BitmapReg_34_3_1, dut_g.l0BitmapReg_34_3_0, dut_g.l0BitmapReg_34_2_7, dut_g.l0BitmapReg_34_2_6, dut_g.l0BitmapReg_34_2_5, dut_g.l0BitmapReg_34_2_4, dut_g.l0BitmapReg_34_2_3, dut_g.l0BitmapReg_34_2_2, dut_g.l0BitmapReg_34_2_1, dut_g.l0BitmapReg_34_2_0, dut_g.l0BitmapReg_34_1_7, dut_g.l0BitmapReg_34_1_6, dut_g.l0BitmapReg_34_1_5, dut_g.l0BitmapReg_34_1_4, dut_g.l0BitmapReg_34_1_3, dut_g.l0BitmapReg_34_1_2, dut_g.l0BitmapReg_34_1_1, dut_g.l0BitmapReg_34_1_0, dut_g.l0BitmapReg_34_0_7, dut_g.l0BitmapReg_34_0_6, dut_g.l0BitmapReg_34_0_5, dut_g.l0BitmapReg_34_0_4, dut_g.l0BitmapReg_34_0_3, dut_g.l0BitmapReg_34_0_2, dut_g.l0BitmapReg_34_0_1, dut_g.l0BitmapReg_34_0_0}, {dut_i.u_core.l0_bitmap[34][3], dut_i.u_core.l0_bitmap[34][2], dut_i.u_core.l0_bitmap[34][1], dut_i.u_core.l0_bitmap[34][0]});
    chk("l0_bitmap[35]", {dut_g.l0BitmapReg_35_3_7, dut_g.l0BitmapReg_35_3_6, dut_g.l0BitmapReg_35_3_5, dut_g.l0BitmapReg_35_3_4, dut_g.l0BitmapReg_35_3_3, dut_g.l0BitmapReg_35_3_2, dut_g.l0BitmapReg_35_3_1, dut_g.l0BitmapReg_35_3_0, dut_g.l0BitmapReg_35_2_7, dut_g.l0BitmapReg_35_2_6, dut_g.l0BitmapReg_35_2_5, dut_g.l0BitmapReg_35_2_4, dut_g.l0BitmapReg_35_2_3, dut_g.l0BitmapReg_35_2_2, dut_g.l0BitmapReg_35_2_1, dut_g.l0BitmapReg_35_2_0, dut_g.l0BitmapReg_35_1_7, dut_g.l0BitmapReg_35_1_6, dut_g.l0BitmapReg_35_1_5, dut_g.l0BitmapReg_35_1_4, dut_g.l0BitmapReg_35_1_3, dut_g.l0BitmapReg_35_1_2, dut_g.l0BitmapReg_35_1_1, dut_g.l0BitmapReg_35_1_0, dut_g.l0BitmapReg_35_0_7, dut_g.l0BitmapReg_35_0_6, dut_g.l0BitmapReg_35_0_5, dut_g.l0BitmapReg_35_0_4, dut_g.l0BitmapReg_35_0_3, dut_g.l0BitmapReg_35_0_2, dut_g.l0BitmapReg_35_0_1, dut_g.l0BitmapReg_35_0_0}, {dut_i.u_core.l0_bitmap[35][3], dut_i.u_core.l0_bitmap[35][2], dut_i.u_core.l0_bitmap[35][1], dut_i.u_core.l0_bitmap[35][0]});
    chk("l0_bitmap[36]", {dut_g.l0BitmapReg_36_3_7, dut_g.l0BitmapReg_36_3_6, dut_g.l0BitmapReg_36_3_5, dut_g.l0BitmapReg_36_3_4, dut_g.l0BitmapReg_36_3_3, dut_g.l0BitmapReg_36_3_2, dut_g.l0BitmapReg_36_3_1, dut_g.l0BitmapReg_36_3_0, dut_g.l0BitmapReg_36_2_7, dut_g.l0BitmapReg_36_2_6, dut_g.l0BitmapReg_36_2_5, dut_g.l0BitmapReg_36_2_4, dut_g.l0BitmapReg_36_2_3, dut_g.l0BitmapReg_36_2_2, dut_g.l0BitmapReg_36_2_1, dut_g.l0BitmapReg_36_2_0, dut_g.l0BitmapReg_36_1_7, dut_g.l0BitmapReg_36_1_6, dut_g.l0BitmapReg_36_1_5, dut_g.l0BitmapReg_36_1_4, dut_g.l0BitmapReg_36_1_3, dut_g.l0BitmapReg_36_1_2, dut_g.l0BitmapReg_36_1_1, dut_g.l0BitmapReg_36_1_0, dut_g.l0BitmapReg_36_0_7, dut_g.l0BitmapReg_36_0_6, dut_g.l0BitmapReg_36_0_5, dut_g.l0BitmapReg_36_0_4, dut_g.l0BitmapReg_36_0_3, dut_g.l0BitmapReg_36_0_2, dut_g.l0BitmapReg_36_0_1, dut_g.l0BitmapReg_36_0_0}, {dut_i.u_core.l0_bitmap[36][3], dut_i.u_core.l0_bitmap[36][2], dut_i.u_core.l0_bitmap[36][1], dut_i.u_core.l0_bitmap[36][0]});
    chk("l0_bitmap[37]", {dut_g.l0BitmapReg_37_3_7, dut_g.l0BitmapReg_37_3_6, dut_g.l0BitmapReg_37_3_5, dut_g.l0BitmapReg_37_3_4, dut_g.l0BitmapReg_37_3_3, dut_g.l0BitmapReg_37_3_2, dut_g.l0BitmapReg_37_3_1, dut_g.l0BitmapReg_37_3_0, dut_g.l0BitmapReg_37_2_7, dut_g.l0BitmapReg_37_2_6, dut_g.l0BitmapReg_37_2_5, dut_g.l0BitmapReg_37_2_4, dut_g.l0BitmapReg_37_2_3, dut_g.l0BitmapReg_37_2_2, dut_g.l0BitmapReg_37_2_1, dut_g.l0BitmapReg_37_2_0, dut_g.l0BitmapReg_37_1_7, dut_g.l0BitmapReg_37_1_6, dut_g.l0BitmapReg_37_1_5, dut_g.l0BitmapReg_37_1_4, dut_g.l0BitmapReg_37_1_3, dut_g.l0BitmapReg_37_1_2, dut_g.l0BitmapReg_37_1_1, dut_g.l0BitmapReg_37_1_0, dut_g.l0BitmapReg_37_0_7, dut_g.l0BitmapReg_37_0_6, dut_g.l0BitmapReg_37_0_5, dut_g.l0BitmapReg_37_0_4, dut_g.l0BitmapReg_37_0_3, dut_g.l0BitmapReg_37_0_2, dut_g.l0BitmapReg_37_0_1, dut_g.l0BitmapReg_37_0_0}, {dut_i.u_core.l0_bitmap[37][3], dut_i.u_core.l0_bitmap[37][2], dut_i.u_core.l0_bitmap[37][1], dut_i.u_core.l0_bitmap[37][0]});
    chk("l0_bitmap[38]", {dut_g.l0BitmapReg_38_3_7, dut_g.l0BitmapReg_38_3_6, dut_g.l0BitmapReg_38_3_5, dut_g.l0BitmapReg_38_3_4, dut_g.l0BitmapReg_38_3_3, dut_g.l0BitmapReg_38_3_2, dut_g.l0BitmapReg_38_3_1, dut_g.l0BitmapReg_38_3_0, dut_g.l0BitmapReg_38_2_7, dut_g.l0BitmapReg_38_2_6, dut_g.l0BitmapReg_38_2_5, dut_g.l0BitmapReg_38_2_4, dut_g.l0BitmapReg_38_2_3, dut_g.l0BitmapReg_38_2_2, dut_g.l0BitmapReg_38_2_1, dut_g.l0BitmapReg_38_2_0, dut_g.l0BitmapReg_38_1_7, dut_g.l0BitmapReg_38_1_6, dut_g.l0BitmapReg_38_1_5, dut_g.l0BitmapReg_38_1_4, dut_g.l0BitmapReg_38_1_3, dut_g.l0BitmapReg_38_1_2, dut_g.l0BitmapReg_38_1_1, dut_g.l0BitmapReg_38_1_0, dut_g.l0BitmapReg_38_0_7, dut_g.l0BitmapReg_38_0_6, dut_g.l0BitmapReg_38_0_5, dut_g.l0BitmapReg_38_0_4, dut_g.l0BitmapReg_38_0_3, dut_g.l0BitmapReg_38_0_2, dut_g.l0BitmapReg_38_0_1, dut_g.l0BitmapReg_38_0_0}, {dut_i.u_core.l0_bitmap[38][3], dut_i.u_core.l0_bitmap[38][2], dut_i.u_core.l0_bitmap[38][1], dut_i.u_core.l0_bitmap[38][0]});
    chk("l0_bitmap[39]", {dut_g.l0BitmapReg_39_3_7, dut_g.l0BitmapReg_39_3_6, dut_g.l0BitmapReg_39_3_5, dut_g.l0BitmapReg_39_3_4, dut_g.l0BitmapReg_39_3_3, dut_g.l0BitmapReg_39_3_2, dut_g.l0BitmapReg_39_3_1, dut_g.l0BitmapReg_39_3_0, dut_g.l0BitmapReg_39_2_7, dut_g.l0BitmapReg_39_2_6, dut_g.l0BitmapReg_39_2_5, dut_g.l0BitmapReg_39_2_4, dut_g.l0BitmapReg_39_2_3, dut_g.l0BitmapReg_39_2_2, dut_g.l0BitmapReg_39_2_1, dut_g.l0BitmapReg_39_2_0, dut_g.l0BitmapReg_39_1_7, dut_g.l0BitmapReg_39_1_6, dut_g.l0BitmapReg_39_1_5, dut_g.l0BitmapReg_39_1_4, dut_g.l0BitmapReg_39_1_3, dut_g.l0BitmapReg_39_1_2, dut_g.l0BitmapReg_39_1_1, dut_g.l0BitmapReg_39_1_0, dut_g.l0BitmapReg_39_0_7, dut_g.l0BitmapReg_39_0_6, dut_g.l0BitmapReg_39_0_5, dut_g.l0BitmapReg_39_0_4, dut_g.l0BitmapReg_39_0_3, dut_g.l0BitmapReg_39_0_2, dut_g.l0BitmapReg_39_0_1, dut_g.l0BitmapReg_39_0_0}, {dut_i.u_core.l0_bitmap[39][3], dut_i.u_core.l0_bitmap[39][2], dut_i.u_core.l0_bitmap[39][1], dut_i.u_core.l0_bitmap[39][0]});
    chk("l0_bitmap[40]", {dut_g.l0BitmapReg_40_3_7, dut_g.l0BitmapReg_40_3_6, dut_g.l0BitmapReg_40_3_5, dut_g.l0BitmapReg_40_3_4, dut_g.l0BitmapReg_40_3_3, dut_g.l0BitmapReg_40_3_2, dut_g.l0BitmapReg_40_3_1, dut_g.l0BitmapReg_40_3_0, dut_g.l0BitmapReg_40_2_7, dut_g.l0BitmapReg_40_2_6, dut_g.l0BitmapReg_40_2_5, dut_g.l0BitmapReg_40_2_4, dut_g.l0BitmapReg_40_2_3, dut_g.l0BitmapReg_40_2_2, dut_g.l0BitmapReg_40_2_1, dut_g.l0BitmapReg_40_2_0, dut_g.l0BitmapReg_40_1_7, dut_g.l0BitmapReg_40_1_6, dut_g.l0BitmapReg_40_1_5, dut_g.l0BitmapReg_40_1_4, dut_g.l0BitmapReg_40_1_3, dut_g.l0BitmapReg_40_1_2, dut_g.l0BitmapReg_40_1_1, dut_g.l0BitmapReg_40_1_0, dut_g.l0BitmapReg_40_0_7, dut_g.l0BitmapReg_40_0_6, dut_g.l0BitmapReg_40_0_5, dut_g.l0BitmapReg_40_0_4, dut_g.l0BitmapReg_40_0_3, dut_g.l0BitmapReg_40_0_2, dut_g.l0BitmapReg_40_0_1, dut_g.l0BitmapReg_40_0_0}, {dut_i.u_core.l0_bitmap[40][3], dut_i.u_core.l0_bitmap[40][2], dut_i.u_core.l0_bitmap[40][1], dut_i.u_core.l0_bitmap[40][0]});
    chk("l0_bitmap[41]", {dut_g.l0BitmapReg_41_3_7, dut_g.l0BitmapReg_41_3_6, dut_g.l0BitmapReg_41_3_5, dut_g.l0BitmapReg_41_3_4, dut_g.l0BitmapReg_41_3_3, dut_g.l0BitmapReg_41_3_2, dut_g.l0BitmapReg_41_3_1, dut_g.l0BitmapReg_41_3_0, dut_g.l0BitmapReg_41_2_7, dut_g.l0BitmapReg_41_2_6, dut_g.l0BitmapReg_41_2_5, dut_g.l0BitmapReg_41_2_4, dut_g.l0BitmapReg_41_2_3, dut_g.l0BitmapReg_41_2_2, dut_g.l0BitmapReg_41_2_1, dut_g.l0BitmapReg_41_2_0, dut_g.l0BitmapReg_41_1_7, dut_g.l0BitmapReg_41_1_6, dut_g.l0BitmapReg_41_1_5, dut_g.l0BitmapReg_41_1_4, dut_g.l0BitmapReg_41_1_3, dut_g.l0BitmapReg_41_1_2, dut_g.l0BitmapReg_41_1_1, dut_g.l0BitmapReg_41_1_0, dut_g.l0BitmapReg_41_0_7, dut_g.l0BitmapReg_41_0_6, dut_g.l0BitmapReg_41_0_5, dut_g.l0BitmapReg_41_0_4, dut_g.l0BitmapReg_41_0_3, dut_g.l0BitmapReg_41_0_2, dut_g.l0BitmapReg_41_0_1, dut_g.l0BitmapReg_41_0_0}, {dut_i.u_core.l0_bitmap[41][3], dut_i.u_core.l0_bitmap[41][2], dut_i.u_core.l0_bitmap[41][1], dut_i.u_core.l0_bitmap[41][0]});
    chk("l0_bitmap[42]", {dut_g.l0BitmapReg_42_3_7, dut_g.l0BitmapReg_42_3_6, dut_g.l0BitmapReg_42_3_5, dut_g.l0BitmapReg_42_3_4, dut_g.l0BitmapReg_42_3_3, dut_g.l0BitmapReg_42_3_2, dut_g.l0BitmapReg_42_3_1, dut_g.l0BitmapReg_42_3_0, dut_g.l0BitmapReg_42_2_7, dut_g.l0BitmapReg_42_2_6, dut_g.l0BitmapReg_42_2_5, dut_g.l0BitmapReg_42_2_4, dut_g.l0BitmapReg_42_2_3, dut_g.l0BitmapReg_42_2_2, dut_g.l0BitmapReg_42_2_1, dut_g.l0BitmapReg_42_2_0, dut_g.l0BitmapReg_42_1_7, dut_g.l0BitmapReg_42_1_6, dut_g.l0BitmapReg_42_1_5, dut_g.l0BitmapReg_42_1_4, dut_g.l0BitmapReg_42_1_3, dut_g.l0BitmapReg_42_1_2, dut_g.l0BitmapReg_42_1_1, dut_g.l0BitmapReg_42_1_0, dut_g.l0BitmapReg_42_0_7, dut_g.l0BitmapReg_42_0_6, dut_g.l0BitmapReg_42_0_5, dut_g.l0BitmapReg_42_0_4, dut_g.l0BitmapReg_42_0_3, dut_g.l0BitmapReg_42_0_2, dut_g.l0BitmapReg_42_0_1, dut_g.l0BitmapReg_42_0_0}, {dut_i.u_core.l0_bitmap[42][3], dut_i.u_core.l0_bitmap[42][2], dut_i.u_core.l0_bitmap[42][1], dut_i.u_core.l0_bitmap[42][0]});
    chk("l0_bitmap[43]", {dut_g.l0BitmapReg_43_3_7, dut_g.l0BitmapReg_43_3_6, dut_g.l0BitmapReg_43_3_5, dut_g.l0BitmapReg_43_3_4, dut_g.l0BitmapReg_43_3_3, dut_g.l0BitmapReg_43_3_2, dut_g.l0BitmapReg_43_3_1, dut_g.l0BitmapReg_43_3_0, dut_g.l0BitmapReg_43_2_7, dut_g.l0BitmapReg_43_2_6, dut_g.l0BitmapReg_43_2_5, dut_g.l0BitmapReg_43_2_4, dut_g.l0BitmapReg_43_2_3, dut_g.l0BitmapReg_43_2_2, dut_g.l0BitmapReg_43_2_1, dut_g.l0BitmapReg_43_2_0, dut_g.l0BitmapReg_43_1_7, dut_g.l0BitmapReg_43_1_6, dut_g.l0BitmapReg_43_1_5, dut_g.l0BitmapReg_43_1_4, dut_g.l0BitmapReg_43_1_3, dut_g.l0BitmapReg_43_1_2, dut_g.l0BitmapReg_43_1_1, dut_g.l0BitmapReg_43_1_0, dut_g.l0BitmapReg_43_0_7, dut_g.l0BitmapReg_43_0_6, dut_g.l0BitmapReg_43_0_5, dut_g.l0BitmapReg_43_0_4, dut_g.l0BitmapReg_43_0_3, dut_g.l0BitmapReg_43_0_2, dut_g.l0BitmapReg_43_0_1, dut_g.l0BitmapReg_43_0_0}, {dut_i.u_core.l0_bitmap[43][3], dut_i.u_core.l0_bitmap[43][2], dut_i.u_core.l0_bitmap[43][1], dut_i.u_core.l0_bitmap[43][0]});
    chk("l0_bitmap[44]", {dut_g.l0BitmapReg_44_3_7, dut_g.l0BitmapReg_44_3_6, dut_g.l0BitmapReg_44_3_5, dut_g.l0BitmapReg_44_3_4, dut_g.l0BitmapReg_44_3_3, dut_g.l0BitmapReg_44_3_2, dut_g.l0BitmapReg_44_3_1, dut_g.l0BitmapReg_44_3_0, dut_g.l0BitmapReg_44_2_7, dut_g.l0BitmapReg_44_2_6, dut_g.l0BitmapReg_44_2_5, dut_g.l0BitmapReg_44_2_4, dut_g.l0BitmapReg_44_2_3, dut_g.l0BitmapReg_44_2_2, dut_g.l0BitmapReg_44_2_1, dut_g.l0BitmapReg_44_2_0, dut_g.l0BitmapReg_44_1_7, dut_g.l0BitmapReg_44_1_6, dut_g.l0BitmapReg_44_1_5, dut_g.l0BitmapReg_44_1_4, dut_g.l0BitmapReg_44_1_3, dut_g.l0BitmapReg_44_1_2, dut_g.l0BitmapReg_44_1_1, dut_g.l0BitmapReg_44_1_0, dut_g.l0BitmapReg_44_0_7, dut_g.l0BitmapReg_44_0_6, dut_g.l0BitmapReg_44_0_5, dut_g.l0BitmapReg_44_0_4, dut_g.l0BitmapReg_44_0_3, dut_g.l0BitmapReg_44_0_2, dut_g.l0BitmapReg_44_0_1, dut_g.l0BitmapReg_44_0_0}, {dut_i.u_core.l0_bitmap[44][3], dut_i.u_core.l0_bitmap[44][2], dut_i.u_core.l0_bitmap[44][1], dut_i.u_core.l0_bitmap[44][0]});
    chk("l0_bitmap[45]", {dut_g.l0BitmapReg_45_3_7, dut_g.l0BitmapReg_45_3_6, dut_g.l0BitmapReg_45_3_5, dut_g.l0BitmapReg_45_3_4, dut_g.l0BitmapReg_45_3_3, dut_g.l0BitmapReg_45_3_2, dut_g.l0BitmapReg_45_3_1, dut_g.l0BitmapReg_45_3_0, dut_g.l0BitmapReg_45_2_7, dut_g.l0BitmapReg_45_2_6, dut_g.l0BitmapReg_45_2_5, dut_g.l0BitmapReg_45_2_4, dut_g.l0BitmapReg_45_2_3, dut_g.l0BitmapReg_45_2_2, dut_g.l0BitmapReg_45_2_1, dut_g.l0BitmapReg_45_2_0, dut_g.l0BitmapReg_45_1_7, dut_g.l0BitmapReg_45_1_6, dut_g.l0BitmapReg_45_1_5, dut_g.l0BitmapReg_45_1_4, dut_g.l0BitmapReg_45_1_3, dut_g.l0BitmapReg_45_1_2, dut_g.l0BitmapReg_45_1_1, dut_g.l0BitmapReg_45_1_0, dut_g.l0BitmapReg_45_0_7, dut_g.l0BitmapReg_45_0_6, dut_g.l0BitmapReg_45_0_5, dut_g.l0BitmapReg_45_0_4, dut_g.l0BitmapReg_45_0_3, dut_g.l0BitmapReg_45_0_2, dut_g.l0BitmapReg_45_0_1, dut_g.l0BitmapReg_45_0_0}, {dut_i.u_core.l0_bitmap[45][3], dut_i.u_core.l0_bitmap[45][2], dut_i.u_core.l0_bitmap[45][1], dut_i.u_core.l0_bitmap[45][0]});
    chk("l0_bitmap[46]", {dut_g.l0BitmapReg_46_3_7, dut_g.l0BitmapReg_46_3_6, dut_g.l0BitmapReg_46_3_5, dut_g.l0BitmapReg_46_3_4, dut_g.l0BitmapReg_46_3_3, dut_g.l0BitmapReg_46_3_2, dut_g.l0BitmapReg_46_3_1, dut_g.l0BitmapReg_46_3_0, dut_g.l0BitmapReg_46_2_7, dut_g.l0BitmapReg_46_2_6, dut_g.l0BitmapReg_46_2_5, dut_g.l0BitmapReg_46_2_4, dut_g.l0BitmapReg_46_2_3, dut_g.l0BitmapReg_46_2_2, dut_g.l0BitmapReg_46_2_1, dut_g.l0BitmapReg_46_2_0, dut_g.l0BitmapReg_46_1_7, dut_g.l0BitmapReg_46_1_6, dut_g.l0BitmapReg_46_1_5, dut_g.l0BitmapReg_46_1_4, dut_g.l0BitmapReg_46_1_3, dut_g.l0BitmapReg_46_1_2, dut_g.l0BitmapReg_46_1_1, dut_g.l0BitmapReg_46_1_0, dut_g.l0BitmapReg_46_0_7, dut_g.l0BitmapReg_46_0_6, dut_g.l0BitmapReg_46_0_5, dut_g.l0BitmapReg_46_0_4, dut_g.l0BitmapReg_46_0_3, dut_g.l0BitmapReg_46_0_2, dut_g.l0BitmapReg_46_0_1, dut_g.l0BitmapReg_46_0_0}, {dut_i.u_core.l0_bitmap[46][3], dut_i.u_core.l0_bitmap[46][2], dut_i.u_core.l0_bitmap[46][1], dut_i.u_core.l0_bitmap[46][0]});
    chk("l0_bitmap[47]", {dut_g.l0BitmapReg_47_3_7, dut_g.l0BitmapReg_47_3_6, dut_g.l0BitmapReg_47_3_5, dut_g.l0BitmapReg_47_3_4, dut_g.l0BitmapReg_47_3_3, dut_g.l0BitmapReg_47_3_2, dut_g.l0BitmapReg_47_3_1, dut_g.l0BitmapReg_47_3_0, dut_g.l0BitmapReg_47_2_7, dut_g.l0BitmapReg_47_2_6, dut_g.l0BitmapReg_47_2_5, dut_g.l0BitmapReg_47_2_4, dut_g.l0BitmapReg_47_2_3, dut_g.l0BitmapReg_47_2_2, dut_g.l0BitmapReg_47_2_1, dut_g.l0BitmapReg_47_2_0, dut_g.l0BitmapReg_47_1_7, dut_g.l0BitmapReg_47_1_6, dut_g.l0BitmapReg_47_1_5, dut_g.l0BitmapReg_47_1_4, dut_g.l0BitmapReg_47_1_3, dut_g.l0BitmapReg_47_1_2, dut_g.l0BitmapReg_47_1_1, dut_g.l0BitmapReg_47_1_0, dut_g.l0BitmapReg_47_0_7, dut_g.l0BitmapReg_47_0_6, dut_g.l0BitmapReg_47_0_5, dut_g.l0BitmapReg_47_0_4, dut_g.l0BitmapReg_47_0_3, dut_g.l0BitmapReg_47_0_2, dut_g.l0BitmapReg_47_0_1, dut_g.l0BitmapReg_47_0_0}, {dut_i.u_core.l0_bitmap[47][3], dut_i.u_core.l0_bitmap[47][2], dut_i.u_core.l0_bitmap[47][1], dut_i.u_core.l0_bitmap[47][0]});
    chk("l0_bitmap[48]", {dut_g.l0BitmapReg_48_3_7, dut_g.l0BitmapReg_48_3_6, dut_g.l0BitmapReg_48_3_5, dut_g.l0BitmapReg_48_3_4, dut_g.l0BitmapReg_48_3_3, dut_g.l0BitmapReg_48_3_2, dut_g.l0BitmapReg_48_3_1, dut_g.l0BitmapReg_48_3_0, dut_g.l0BitmapReg_48_2_7, dut_g.l0BitmapReg_48_2_6, dut_g.l0BitmapReg_48_2_5, dut_g.l0BitmapReg_48_2_4, dut_g.l0BitmapReg_48_2_3, dut_g.l0BitmapReg_48_2_2, dut_g.l0BitmapReg_48_2_1, dut_g.l0BitmapReg_48_2_0, dut_g.l0BitmapReg_48_1_7, dut_g.l0BitmapReg_48_1_6, dut_g.l0BitmapReg_48_1_5, dut_g.l0BitmapReg_48_1_4, dut_g.l0BitmapReg_48_1_3, dut_g.l0BitmapReg_48_1_2, dut_g.l0BitmapReg_48_1_1, dut_g.l0BitmapReg_48_1_0, dut_g.l0BitmapReg_48_0_7, dut_g.l0BitmapReg_48_0_6, dut_g.l0BitmapReg_48_0_5, dut_g.l0BitmapReg_48_0_4, dut_g.l0BitmapReg_48_0_3, dut_g.l0BitmapReg_48_0_2, dut_g.l0BitmapReg_48_0_1, dut_g.l0BitmapReg_48_0_0}, {dut_i.u_core.l0_bitmap[48][3], dut_i.u_core.l0_bitmap[48][2], dut_i.u_core.l0_bitmap[48][1], dut_i.u_core.l0_bitmap[48][0]});
    chk("l0_bitmap[49]", {dut_g.l0BitmapReg_49_3_7, dut_g.l0BitmapReg_49_3_6, dut_g.l0BitmapReg_49_3_5, dut_g.l0BitmapReg_49_3_4, dut_g.l0BitmapReg_49_3_3, dut_g.l0BitmapReg_49_3_2, dut_g.l0BitmapReg_49_3_1, dut_g.l0BitmapReg_49_3_0, dut_g.l0BitmapReg_49_2_7, dut_g.l0BitmapReg_49_2_6, dut_g.l0BitmapReg_49_2_5, dut_g.l0BitmapReg_49_2_4, dut_g.l0BitmapReg_49_2_3, dut_g.l0BitmapReg_49_2_2, dut_g.l0BitmapReg_49_2_1, dut_g.l0BitmapReg_49_2_0, dut_g.l0BitmapReg_49_1_7, dut_g.l0BitmapReg_49_1_6, dut_g.l0BitmapReg_49_1_5, dut_g.l0BitmapReg_49_1_4, dut_g.l0BitmapReg_49_1_3, dut_g.l0BitmapReg_49_1_2, dut_g.l0BitmapReg_49_1_1, dut_g.l0BitmapReg_49_1_0, dut_g.l0BitmapReg_49_0_7, dut_g.l0BitmapReg_49_0_6, dut_g.l0BitmapReg_49_0_5, dut_g.l0BitmapReg_49_0_4, dut_g.l0BitmapReg_49_0_3, dut_g.l0BitmapReg_49_0_2, dut_g.l0BitmapReg_49_0_1, dut_g.l0BitmapReg_49_0_0}, {dut_i.u_core.l0_bitmap[49][3], dut_i.u_core.l0_bitmap[49][2], dut_i.u_core.l0_bitmap[49][1], dut_i.u_core.l0_bitmap[49][0]});
    chk("l0_bitmap[50]", {dut_g.l0BitmapReg_50_3_7, dut_g.l0BitmapReg_50_3_6, dut_g.l0BitmapReg_50_3_5, dut_g.l0BitmapReg_50_3_4, dut_g.l0BitmapReg_50_3_3, dut_g.l0BitmapReg_50_3_2, dut_g.l0BitmapReg_50_3_1, dut_g.l0BitmapReg_50_3_0, dut_g.l0BitmapReg_50_2_7, dut_g.l0BitmapReg_50_2_6, dut_g.l0BitmapReg_50_2_5, dut_g.l0BitmapReg_50_2_4, dut_g.l0BitmapReg_50_2_3, dut_g.l0BitmapReg_50_2_2, dut_g.l0BitmapReg_50_2_1, dut_g.l0BitmapReg_50_2_0, dut_g.l0BitmapReg_50_1_7, dut_g.l0BitmapReg_50_1_6, dut_g.l0BitmapReg_50_1_5, dut_g.l0BitmapReg_50_1_4, dut_g.l0BitmapReg_50_1_3, dut_g.l0BitmapReg_50_1_2, dut_g.l0BitmapReg_50_1_1, dut_g.l0BitmapReg_50_1_0, dut_g.l0BitmapReg_50_0_7, dut_g.l0BitmapReg_50_0_6, dut_g.l0BitmapReg_50_0_5, dut_g.l0BitmapReg_50_0_4, dut_g.l0BitmapReg_50_0_3, dut_g.l0BitmapReg_50_0_2, dut_g.l0BitmapReg_50_0_1, dut_g.l0BitmapReg_50_0_0}, {dut_i.u_core.l0_bitmap[50][3], dut_i.u_core.l0_bitmap[50][2], dut_i.u_core.l0_bitmap[50][1], dut_i.u_core.l0_bitmap[50][0]});
    chk("l0_bitmap[51]", {dut_g.l0BitmapReg_51_3_7, dut_g.l0BitmapReg_51_3_6, dut_g.l0BitmapReg_51_3_5, dut_g.l0BitmapReg_51_3_4, dut_g.l0BitmapReg_51_3_3, dut_g.l0BitmapReg_51_3_2, dut_g.l0BitmapReg_51_3_1, dut_g.l0BitmapReg_51_3_0, dut_g.l0BitmapReg_51_2_7, dut_g.l0BitmapReg_51_2_6, dut_g.l0BitmapReg_51_2_5, dut_g.l0BitmapReg_51_2_4, dut_g.l0BitmapReg_51_2_3, dut_g.l0BitmapReg_51_2_2, dut_g.l0BitmapReg_51_2_1, dut_g.l0BitmapReg_51_2_0, dut_g.l0BitmapReg_51_1_7, dut_g.l0BitmapReg_51_1_6, dut_g.l0BitmapReg_51_1_5, dut_g.l0BitmapReg_51_1_4, dut_g.l0BitmapReg_51_1_3, dut_g.l0BitmapReg_51_1_2, dut_g.l0BitmapReg_51_1_1, dut_g.l0BitmapReg_51_1_0, dut_g.l0BitmapReg_51_0_7, dut_g.l0BitmapReg_51_0_6, dut_g.l0BitmapReg_51_0_5, dut_g.l0BitmapReg_51_0_4, dut_g.l0BitmapReg_51_0_3, dut_g.l0BitmapReg_51_0_2, dut_g.l0BitmapReg_51_0_1, dut_g.l0BitmapReg_51_0_0}, {dut_i.u_core.l0_bitmap[51][3], dut_i.u_core.l0_bitmap[51][2], dut_i.u_core.l0_bitmap[51][1], dut_i.u_core.l0_bitmap[51][0]});
    chk("l0_bitmap[52]", {dut_g.l0BitmapReg_52_3_7, dut_g.l0BitmapReg_52_3_6, dut_g.l0BitmapReg_52_3_5, dut_g.l0BitmapReg_52_3_4, dut_g.l0BitmapReg_52_3_3, dut_g.l0BitmapReg_52_3_2, dut_g.l0BitmapReg_52_3_1, dut_g.l0BitmapReg_52_3_0, dut_g.l0BitmapReg_52_2_7, dut_g.l0BitmapReg_52_2_6, dut_g.l0BitmapReg_52_2_5, dut_g.l0BitmapReg_52_2_4, dut_g.l0BitmapReg_52_2_3, dut_g.l0BitmapReg_52_2_2, dut_g.l0BitmapReg_52_2_1, dut_g.l0BitmapReg_52_2_0, dut_g.l0BitmapReg_52_1_7, dut_g.l0BitmapReg_52_1_6, dut_g.l0BitmapReg_52_1_5, dut_g.l0BitmapReg_52_1_4, dut_g.l0BitmapReg_52_1_3, dut_g.l0BitmapReg_52_1_2, dut_g.l0BitmapReg_52_1_1, dut_g.l0BitmapReg_52_1_0, dut_g.l0BitmapReg_52_0_7, dut_g.l0BitmapReg_52_0_6, dut_g.l0BitmapReg_52_0_5, dut_g.l0BitmapReg_52_0_4, dut_g.l0BitmapReg_52_0_3, dut_g.l0BitmapReg_52_0_2, dut_g.l0BitmapReg_52_0_1, dut_g.l0BitmapReg_52_0_0}, {dut_i.u_core.l0_bitmap[52][3], dut_i.u_core.l0_bitmap[52][2], dut_i.u_core.l0_bitmap[52][1], dut_i.u_core.l0_bitmap[52][0]});
    chk("l0_bitmap[53]", {dut_g.l0BitmapReg_53_3_7, dut_g.l0BitmapReg_53_3_6, dut_g.l0BitmapReg_53_3_5, dut_g.l0BitmapReg_53_3_4, dut_g.l0BitmapReg_53_3_3, dut_g.l0BitmapReg_53_3_2, dut_g.l0BitmapReg_53_3_1, dut_g.l0BitmapReg_53_3_0, dut_g.l0BitmapReg_53_2_7, dut_g.l0BitmapReg_53_2_6, dut_g.l0BitmapReg_53_2_5, dut_g.l0BitmapReg_53_2_4, dut_g.l0BitmapReg_53_2_3, dut_g.l0BitmapReg_53_2_2, dut_g.l0BitmapReg_53_2_1, dut_g.l0BitmapReg_53_2_0, dut_g.l0BitmapReg_53_1_7, dut_g.l0BitmapReg_53_1_6, dut_g.l0BitmapReg_53_1_5, dut_g.l0BitmapReg_53_1_4, dut_g.l0BitmapReg_53_1_3, dut_g.l0BitmapReg_53_1_2, dut_g.l0BitmapReg_53_1_1, dut_g.l0BitmapReg_53_1_0, dut_g.l0BitmapReg_53_0_7, dut_g.l0BitmapReg_53_0_6, dut_g.l0BitmapReg_53_0_5, dut_g.l0BitmapReg_53_0_4, dut_g.l0BitmapReg_53_0_3, dut_g.l0BitmapReg_53_0_2, dut_g.l0BitmapReg_53_0_1, dut_g.l0BitmapReg_53_0_0}, {dut_i.u_core.l0_bitmap[53][3], dut_i.u_core.l0_bitmap[53][2], dut_i.u_core.l0_bitmap[53][1], dut_i.u_core.l0_bitmap[53][0]});
    chk("l0_bitmap[54]", {dut_g.l0BitmapReg_54_3_7, dut_g.l0BitmapReg_54_3_6, dut_g.l0BitmapReg_54_3_5, dut_g.l0BitmapReg_54_3_4, dut_g.l0BitmapReg_54_3_3, dut_g.l0BitmapReg_54_3_2, dut_g.l0BitmapReg_54_3_1, dut_g.l0BitmapReg_54_3_0, dut_g.l0BitmapReg_54_2_7, dut_g.l0BitmapReg_54_2_6, dut_g.l0BitmapReg_54_2_5, dut_g.l0BitmapReg_54_2_4, dut_g.l0BitmapReg_54_2_3, dut_g.l0BitmapReg_54_2_2, dut_g.l0BitmapReg_54_2_1, dut_g.l0BitmapReg_54_2_0, dut_g.l0BitmapReg_54_1_7, dut_g.l0BitmapReg_54_1_6, dut_g.l0BitmapReg_54_1_5, dut_g.l0BitmapReg_54_1_4, dut_g.l0BitmapReg_54_1_3, dut_g.l0BitmapReg_54_1_2, dut_g.l0BitmapReg_54_1_1, dut_g.l0BitmapReg_54_1_0, dut_g.l0BitmapReg_54_0_7, dut_g.l0BitmapReg_54_0_6, dut_g.l0BitmapReg_54_0_5, dut_g.l0BitmapReg_54_0_4, dut_g.l0BitmapReg_54_0_3, dut_g.l0BitmapReg_54_0_2, dut_g.l0BitmapReg_54_0_1, dut_g.l0BitmapReg_54_0_0}, {dut_i.u_core.l0_bitmap[54][3], dut_i.u_core.l0_bitmap[54][2], dut_i.u_core.l0_bitmap[54][1], dut_i.u_core.l0_bitmap[54][0]});
    chk("l0_bitmap[55]", {dut_g.l0BitmapReg_55_3_7, dut_g.l0BitmapReg_55_3_6, dut_g.l0BitmapReg_55_3_5, dut_g.l0BitmapReg_55_3_4, dut_g.l0BitmapReg_55_3_3, dut_g.l0BitmapReg_55_3_2, dut_g.l0BitmapReg_55_3_1, dut_g.l0BitmapReg_55_3_0, dut_g.l0BitmapReg_55_2_7, dut_g.l0BitmapReg_55_2_6, dut_g.l0BitmapReg_55_2_5, dut_g.l0BitmapReg_55_2_4, dut_g.l0BitmapReg_55_2_3, dut_g.l0BitmapReg_55_2_2, dut_g.l0BitmapReg_55_2_1, dut_g.l0BitmapReg_55_2_0, dut_g.l0BitmapReg_55_1_7, dut_g.l0BitmapReg_55_1_6, dut_g.l0BitmapReg_55_1_5, dut_g.l0BitmapReg_55_1_4, dut_g.l0BitmapReg_55_1_3, dut_g.l0BitmapReg_55_1_2, dut_g.l0BitmapReg_55_1_1, dut_g.l0BitmapReg_55_1_0, dut_g.l0BitmapReg_55_0_7, dut_g.l0BitmapReg_55_0_6, dut_g.l0BitmapReg_55_0_5, dut_g.l0BitmapReg_55_0_4, dut_g.l0BitmapReg_55_0_3, dut_g.l0BitmapReg_55_0_2, dut_g.l0BitmapReg_55_0_1, dut_g.l0BitmapReg_55_0_0}, {dut_i.u_core.l0_bitmap[55][3], dut_i.u_core.l0_bitmap[55][2], dut_i.u_core.l0_bitmap[55][1], dut_i.u_core.l0_bitmap[55][0]});
    chk("l0_bitmap[56]", {dut_g.l0BitmapReg_56_3_7, dut_g.l0BitmapReg_56_3_6, dut_g.l0BitmapReg_56_3_5, dut_g.l0BitmapReg_56_3_4, dut_g.l0BitmapReg_56_3_3, dut_g.l0BitmapReg_56_3_2, dut_g.l0BitmapReg_56_3_1, dut_g.l0BitmapReg_56_3_0, dut_g.l0BitmapReg_56_2_7, dut_g.l0BitmapReg_56_2_6, dut_g.l0BitmapReg_56_2_5, dut_g.l0BitmapReg_56_2_4, dut_g.l0BitmapReg_56_2_3, dut_g.l0BitmapReg_56_2_2, dut_g.l0BitmapReg_56_2_1, dut_g.l0BitmapReg_56_2_0, dut_g.l0BitmapReg_56_1_7, dut_g.l0BitmapReg_56_1_6, dut_g.l0BitmapReg_56_1_5, dut_g.l0BitmapReg_56_1_4, dut_g.l0BitmapReg_56_1_3, dut_g.l0BitmapReg_56_1_2, dut_g.l0BitmapReg_56_1_1, dut_g.l0BitmapReg_56_1_0, dut_g.l0BitmapReg_56_0_7, dut_g.l0BitmapReg_56_0_6, dut_g.l0BitmapReg_56_0_5, dut_g.l0BitmapReg_56_0_4, dut_g.l0BitmapReg_56_0_3, dut_g.l0BitmapReg_56_0_2, dut_g.l0BitmapReg_56_0_1, dut_g.l0BitmapReg_56_0_0}, {dut_i.u_core.l0_bitmap[56][3], dut_i.u_core.l0_bitmap[56][2], dut_i.u_core.l0_bitmap[56][1], dut_i.u_core.l0_bitmap[56][0]});
    chk("l0_bitmap[57]", {dut_g.l0BitmapReg_57_3_7, dut_g.l0BitmapReg_57_3_6, dut_g.l0BitmapReg_57_3_5, dut_g.l0BitmapReg_57_3_4, dut_g.l0BitmapReg_57_3_3, dut_g.l0BitmapReg_57_3_2, dut_g.l0BitmapReg_57_3_1, dut_g.l0BitmapReg_57_3_0, dut_g.l0BitmapReg_57_2_7, dut_g.l0BitmapReg_57_2_6, dut_g.l0BitmapReg_57_2_5, dut_g.l0BitmapReg_57_2_4, dut_g.l0BitmapReg_57_2_3, dut_g.l0BitmapReg_57_2_2, dut_g.l0BitmapReg_57_2_1, dut_g.l0BitmapReg_57_2_0, dut_g.l0BitmapReg_57_1_7, dut_g.l0BitmapReg_57_1_6, dut_g.l0BitmapReg_57_1_5, dut_g.l0BitmapReg_57_1_4, dut_g.l0BitmapReg_57_1_3, dut_g.l0BitmapReg_57_1_2, dut_g.l0BitmapReg_57_1_1, dut_g.l0BitmapReg_57_1_0, dut_g.l0BitmapReg_57_0_7, dut_g.l0BitmapReg_57_0_6, dut_g.l0BitmapReg_57_0_5, dut_g.l0BitmapReg_57_0_4, dut_g.l0BitmapReg_57_0_3, dut_g.l0BitmapReg_57_0_2, dut_g.l0BitmapReg_57_0_1, dut_g.l0BitmapReg_57_0_0}, {dut_i.u_core.l0_bitmap[57][3], dut_i.u_core.l0_bitmap[57][2], dut_i.u_core.l0_bitmap[57][1], dut_i.u_core.l0_bitmap[57][0]});
    chk("l0_bitmap[58]", {dut_g.l0BitmapReg_58_3_7, dut_g.l0BitmapReg_58_3_6, dut_g.l0BitmapReg_58_3_5, dut_g.l0BitmapReg_58_3_4, dut_g.l0BitmapReg_58_3_3, dut_g.l0BitmapReg_58_3_2, dut_g.l0BitmapReg_58_3_1, dut_g.l0BitmapReg_58_3_0, dut_g.l0BitmapReg_58_2_7, dut_g.l0BitmapReg_58_2_6, dut_g.l0BitmapReg_58_2_5, dut_g.l0BitmapReg_58_2_4, dut_g.l0BitmapReg_58_2_3, dut_g.l0BitmapReg_58_2_2, dut_g.l0BitmapReg_58_2_1, dut_g.l0BitmapReg_58_2_0, dut_g.l0BitmapReg_58_1_7, dut_g.l0BitmapReg_58_1_6, dut_g.l0BitmapReg_58_1_5, dut_g.l0BitmapReg_58_1_4, dut_g.l0BitmapReg_58_1_3, dut_g.l0BitmapReg_58_1_2, dut_g.l0BitmapReg_58_1_1, dut_g.l0BitmapReg_58_1_0, dut_g.l0BitmapReg_58_0_7, dut_g.l0BitmapReg_58_0_6, dut_g.l0BitmapReg_58_0_5, dut_g.l0BitmapReg_58_0_4, dut_g.l0BitmapReg_58_0_3, dut_g.l0BitmapReg_58_0_2, dut_g.l0BitmapReg_58_0_1, dut_g.l0BitmapReg_58_0_0}, {dut_i.u_core.l0_bitmap[58][3], dut_i.u_core.l0_bitmap[58][2], dut_i.u_core.l0_bitmap[58][1], dut_i.u_core.l0_bitmap[58][0]});
    chk("l0_bitmap[59]", {dut_g.l0BitmapReg_59_3_7, dut_g.l0BitmapReg_59_3_6, dut_g.l0BitmapReg_59_3_5, dut_g.l0BitmapReg_59_3_4, dut_g.l0BitmapReg_59_3_3, dut_g.l0BitmapReg_59_3_2, dut_g.l0BitmapReg_59_3_1, dut_g.l0BitmapReg_59_3_0, dut_g.l0BitmapReg_59_2_7, dut_g.l0BitmapReg_59_2_6, dut_g.l0BitmapReg_59_2_5, dut_g.l0BitmapReg_59_2_4, dut_g.l0BitmapReg_59_2_3, dut_g.l0BitmapReg_59_2_2, dut_g.l0BitmapReg_59_2_1, dut_g.l0BitmapReg_59_2_0, dut_g.l0BitmapReg_59_1_7, dut_g.l0BitmapReg_59_1_6, dut_g.l0BitmapReg_59_1_5, dut_g.l0BitmapReg_59_1_4, dut_g.l0BitmapReg_59_1_3, dut_g.l0BitmapReg_59_1_2, dut_g.l0BitmapReg_59_1_1, dut_g.l0BitmapReg_59_1_0, dut_g.l0BitmapReg_59_0_7, dut_g.l0BitmapReg_59_0_6, dut_g.l0BitmapReg_59_0_5, dut_g.l0BitmapReg_59_0_4, dut_g.l0BitmapReg_59_0_3, dut_g.l0BitmapReg_59_0_2, dut_g.l0BitmapReg_59_0_1, dut_g.l0BitmapReg_59_0_0}, {dut_i.u_core.l0_bitmap[59][3], dut_i.u_core.l0_bitmap[59][2], dut_i.u_core.l0_bitmap[59][1], dut_i.u_core.l0_bitmap[59][0]});
    chk("l0_bitmap[60]", {dut_g.l0BitmapReg_60_3_7, dut_g.l0BitmapReg_60_3_6, dut_g.l0BitmapReg_60_3_5, dut_g.l0BitmapReg_60_3_4, dut_g.l0BitmapReg_60_3_3, dut_g.l0BitmapReg_60_3_2, dut_g.l0BitmapReg_60_3_1, dut_g.l0BitmapReg_60_3_0, dut_g.l0BitmapReg_60_2_7, dut_g.l0BitmapReg_60_2_6, dut_g.l0BitmapReg_60_2_5, dut_g.l0BitmapReg_60_2_4, dut_g.l0BitmapReg_60_2_3, dut_g.l0BitmapReg_60_2_2, dut_g.l0BitmapReg_60_2_1, dut_g.l0BitmapReg_60_2_0, dut_g.l0BitmapReg_60_1_7, dut_g.l0BitmapReg_60_1_6, dut_g.l0BitmapReg_60_1_5, dut_g.l0BitmapReg_60_1_4, dut_g.l0BitmapReg_60_1_3, dut_g.l0BitmapReg_60_1_2, dut_g.l0BitmapReg_60_1_1, dut_g.l0BitmapReg_60_1_0, dut_g.l0BitmapReg_60_0_7, dut_g.l0BitmapReg_60_0_6, dut_g.l0BitmapReg_60_0_5, dut_g.l0BitmapReg_60_0_4, dut_g.l0BitmapReg_60_0_3, dut_g.l0BitmapReg_60_0_2, dut_g.l0BitmapReg_60_0_1, dut_g.l0BitmapReg_60_0_0}, {dut_i.u_core.l0_bitmap[60][3], dut_i.u_core.l0_bitmap[60][2], dut_i.u_core.l0_bitmap[60][1], dut_i.u_core.l0_bitmap[60][0]});
    chk("l0_bitmap[61]", {dut_g.l0BitmapReg_61_3_7, dut_g.l0BitmapReg_61_3_6, dut_g.l0BitmapReg_61_3_5, dut_g.l0BitmapReg_61_3_4, dut_g.l0BitmapReg_61_3_3, dut_g.l0BitmapReg_61_3_2, dut_g.l0BitmapReg_61_3_1, dut_g.l0BitmapReg_61_3_0, dut_g.l0BitmapReg_61_2_7, dut_g.l0BitmapReg_61_2_6, dut_g.l0BitmapReg_61_2_5, dut_g.l0BitmapReg_61_2_4, dut_g.l0BitmapReg_61_2_3, dut_g.l0BitmapReg_61_2_2, dut_g.l0BitmapReg_61_2_1, dut_g.l0BitmapReg_61_2_0, dut_g.l0BitmapReg_61_1_7, dut_g.l0BitmapReg_61_1_6, dut_g.l0BitmapReg_61_1_5, dut_g.l0BitmapReg_61_1_4, dut_g.l0BitmapReg_61_1_3, dut_g.l0BitmapReg_61_1_2, dut_g.l0BitmapReg_61_1_1, dut_g.l0BitmapReg_61_1_0, dut_g.l0BitmapReg_61_0_7, dut_g.l0BitmapReg_61_0_6, dut_g.l0BitmapReg_61_0_5, dut_g.l0BitmapReg_61_0_4, dut_g.l0BitmapReg_61_0_3, dut_g.l0BitmapReg_61_0_2, dut_g.l0BitmapReg_61_0_1, dut_g.l0BitmapReg_61_0_0}, {dut_i.u_core.l0_bitmap[61][3], dut_i.u_core.l0_bitmap[61][2], dut_i.u_core.l0_bitmap[61][1], dut_i.u_core.l0_bitmap[61][0]});
    chk("l0_bitmap[62]", {dut_g.l0BitmapReg_62_3_7, dut_g.l0BitmapReg_62_3_6, dut_g.l0BitmapReg_62_3_5, dut_g.l0BitmapReg_62_3_4, dut_g.l0BitmapReg_62_3_3, dut_g.l0BitmapReg_62_3_2, dut_g.l0BitmapReg_62_3_1, dut_g.l0BitmapReg_62_3_0, dut_g.l0BitmapReg_62_2_7, dut_g.l0BitmapReg_62_2_6, dut_g.l0BitmapReg_62_2_5, dut_g.l0BitmapReg_62_2_4, dut_g.l0BitmapReg_62_2_3, dut_g.l0BitmapReg_62_2_2, dut_g.l0BitmapReg_62_2_1, dut_g.l0BitmapReg_62_2_0, dut_g.l0BitmapReg_62_1_7, dut_g.l0BitmapReg_62_1_6, dut_g.l0BitmapReg_62_1_5, dut_g.l0BitmapReg_62_1_4, dut_g.l0BitmapReg_62_1_3, dut_g.l0BitmapReg_62_1_2, dut_g.l0BitmapReg_62_1_1, dut_g.l0BitmapReg_62_1_0, dut_g.l0BitmapReg_62_0_7, dut_g.l0BitmapReg_62_0_6, dut_g.l0BitmapReg_62_0_5, dut_g.l0BitmapReg_62_0_4, dut_g.l0BitmapReg_62_0_3, dut_g.l0BitmapReg_62_0_2, dut_g.l0BitmapReg_62_0_1, dut_g.l0BitmapReg_62_0_0}, {dut_i.u_core.l0_bitmap[62][3], dut_i.u_core.l0_bitmap[62][2], dut_i.u_core.l0_bitmap[62][1], dut_i.u_core.l0_bitmap[62][0]});
    chk("l0_bitmap[63]", {dut_g.l0BitmapReg_63_3_7, dut_g.l0BitmapReg_63_3_6, dut_g.l0BitmapReg_63_3_5, dut_g.l0BitmapReg_63_3_4, dut_g.l0BitmapReg_63_3_3, dut_g.l0BitmapReg_63_3_2, dut_g.l0BitmapReg_63_3_1, dut_g.l0BitmapReg_63_3_0, dut_g.l0BitmapReg_63_2_7, dut_g.l0BitmapReg_63_2_6, dut_g.l0BitmapReg_63_2_5, dut_g.l0BitmapReg_63_2_4, dut_g.l0BitmapReg_63_2_3, dut_g.l0BitmapReg_63_2_2, dut_g.l0BitmapReg_63_2_1, dut_g.l0BitmapReg_63_2_0, dut_g.l0BitmapReg_63_1_7, dut_g.l0BitmapReg_63_1_6, dut_g.l0BitmapReg_63_1_5, dut_g.l0BitmapReg_63_1_4, dut_g.l0BitmapReg_63_1_3, dut_g.l0BitmapReg_63_1_2, dut_g.l0BitmapReg_63_1_1, dut_g.l0BitmapReg_63_1_0, dut_g.l0BitmapReg_63_0_7, dut_g.l0BitmapReg_63_0_6, dut_g.l0BitmapReg_63_0_5, dut_g.l0BitmapReg_63_0_4, dut_g.l0BitmapReg_63_0_3, dut_g.l0BitmapReg_63_0_2, dut_g.l0BitmapReg_63_0_1, dut_g.l0BitmapReg_63_0_0}, {dut_i.u_core.l0_bitmap[63][3], dut_i.u_core.l0_bitmap[63][2], dut_i.u_core.l0_bitmap[63][1], dut_i.u_core.l0_bitmap[63][0]});
    // §22 bitmap 的两级流水副本（golden r_W_K / r_1_W_K）
    chk("l0_bitmap_delay", {dut_g.r_3_7, dut_g.r_3_6, dut_g.r_3_5, dut_g.r_3_4, dut_g.r_3_3, dut_g.r_3_2, dut_g.r_3_1, dut_g.r_3_0, dut_g.r_2_7, dut_g.r_2_6, dut_g.r_2_5, dut_g.r_2_4, dut_g.r_2_3, dut_g.r_2_2, dut_g.r_2_1, dut_g.r_2_0, dut_g.r_1_7, dut_g.r_1_6, dut_g.r_1_5, dut_g.r_1_4, dut_g.r_1_3, dut_g.r_1_2, dut_g.r_1_1, dut_g.r_1_0, dut_g.r_0_7, dut_g.r_0_6, dut_g.r_0_5, dut_g.r_0_4, dut_g.r_0_3, dut_g.r_0_2, dut_g.r_0_1, dut_g.r_0_0}, {dut_i.u_core.l0_bitmap_delay[3], dut_i.u_core.l0_bitmap_delay[2], dut_i.u_core.l0_bitmap_delay[1], dut_i.u_core.l0_bitmap_delay[0]});
    chk("l0_bitmap_ck", {dut_g.r_1_3_7, dut_g.r_1_3_6, dut_g.r_1_3_5, dut_g.r_1_3_4, dut_g.r_1_3_3, dut_g.r_1_3_2, dut_g.r_1_3_1, dut_g.r_1_3_0, dut_g.r_1_2_7, dut_g.r_1_2_6, dut_g.r_1_2_5, dut_g.r_1_2_4, dut_g.r_1_2_3, dut_g.r_1_2_2, dut_g.r_1_2_1, dut_g.r_1_2_0, dut_g.r_1_1_7, dut_g.r_1_1_6, dut_g.r_1_1_5, dut_g.r_1_1_4, dut_g.r_1_1_3, dut_g.r_1_1_2, dut_g.r_1_1_1, dut_g.r_1_1_0, dut_g.r_1_0_7, dut_g.r_1_0_6, dut_g.r_1_0_5, dut_g.r_1_0_4, dut_g.r_1_0_3, dut_g.r_1_0_2, dut_g.r_1_0_1, dut_g.r_1_0_0}, {dut_i.u_core.l0_bitmap_ck[3], dut_i.u_core.l0_bitmap_ck[2], dut_i.u_core.l0_bitmap_ck[1], dut_i.u_core.l0_bitmap_ck[0]});
    // §22 wakeup 三拍流水
    chk("wakeup_delay_valid", dut_g.wakeup_req_delay_valid, dut_i.u_core.wakeup_delay_valid);
    chk("wakeup_valid", dut_g.wakeup_req_valid, dut_i.u_core.wakeup_valid);
    chk("wk_d_set", dut_g.wakeup_req_delay_setIndex, dut_i.u_core.wk_d_set);
    chk("wk_d_tag", dut_g.wakeup_req_delay_tag, dut_i.u_core.wk_d_tag);
    chk("wk_d_way", dut_g.wakeup_req_delay_way_info, dut_i.u_core.wk_d_way);
    chk("wk_d_idx", dut_g.wakeup_req_delay_pte_index, dut_i.u_core.wk_d_idx);
    chk("wk_d_ok", dut_g.wakeup_req_delay_check_success, dut_i.u_core.wk_d_ok);
    chk("wk_d_s2x", dut_g.wakeup_req_delay_s2xlate, dut_i.u_core.wk_d_s2x);
    chk("wk_set", dut_g.wakeup_req_setIndex, dut_i.u_core.wk_set);
    chk("wk_way", dut_g.wakeup_req_way_info, dut_i.u_core.wk_way);
    chk("wk_idx", dut_g.wakeup_req_pte_index, dut_i.u_core.wk_idx);
    chk("wk_ok", dut_g.wakeup_req_check_success, dut_i.u_core.wk_ok);
    chk("wakeup_hitvec[0]", dut_g.wakeup_hitVec_0, dut_i.u_core.wakeup_hitvec[0]);
    chk("wakeup_vvec_delay[0]", dut_g.wakeup_vVec_delay[0], dut_i.u_core.wakeup_vvec_delay[0]);
    chk("wakeup_hvec_delay[0]", dut_g.wakeup_hVec_delay_0, dut_i.u_core.wakeup_hvec_delay[0]);
    chk("wakeup_rdata_r[0].tag", dut_g.wakeup_data_resp_r_0_entries_tag, dut_i.u_core.wakeup_rdata_r[0].tag);
    chk("wakeup_rdata_r[0].asid", dut_g.wakeup_data_resp_r_0_entries_asid, dut_i.u_core.wakeup_rdata_r[0].asid);
    chk("wakeup_rdata_r[0].vmid", dut_g.wakeup_data_resp_r_0_entries_vmid, dut_i.u_core.wakeup_rdata_r[0].vmid);
    chk("wakeup_rdata_r[0].vs[0]", dut_g.wakeup_data_resp_r_0_entries_vs_0, dut_i.u_core.wakeup_rdata_r[0].vs[0]);
    chk("wakeup_rdata_r[0].g[0]", dut_g.wakeup_data_resp_r_0_entries_perms_0_g, dut_i.u_core.wakeup_rdata_r[0].g[0]);
    chk("wakeup_rdata_r[0].vs[1]", dut_g.wakeup_data_resp_r_0_entries_vs_1, dut_i.u_core.wakeup_rdata_r[0].vs[1]);
    chk("wakeup_rdata_r[0].g[1]", dut_g.wakeup_data_resp_r_0_entries_perms_1_g, dut_i.u_core.wakeup_rdata_r[0].g[1]);
    chk("wakeup_rdata_r[0].vs[2]", dut_g.wakeup_data_resp_r_0_entries_vs_2, dut_i.u_core.wakeup_rdata_r[0].vs[2]);
    chk("wakeup_rdata_r[0].g[2]", dut_g.wakeup_data_resp_r_0_entries_perms_2_g, dut_i.u_core.wakeup_rdata_r[0].g[2]);
    chk("wakeup_rdata_r[0].vs[3]", dut_g.wakeup_data_resp_r_0_entries_vs_3, dut_i.u_core.wakeup_rdata_r[0].vs[3]);
    chk("wakeup_rdata_r[0].g[3]", dut_g.wakeup_data_resp_r_0_entries_perms_3_g, dut_i.u_core.wakeup_rdata_r[0].g[3]);
    chk("wakeup_rdata_r[0].vs[4]", dut_g.wakeup_data_resp_r_0_entries_vs_4, dut_i.u_core.wakeup_rdata_r[0].vs[4]);
    chk("wakeup_rdata_r[0].g[4]", dut_g.wakeup_data_resp_r_0_entries_perms_4_g, dut_i.u_core.wakeup_rdata_r[0].g[4]);
    chk("wakeup_rdata_r[0].vs[5]", dut_g.wakeup_data_resp_r_0_entries_vs_5, dut_i.u_core.wakeup_rdata_r[0].vs[5]);
    chk("wakeup_rdata_r[0].g[5]", dut_g.wakeup_data_resp_r_0_entries_perms_5_g, dut_i.u_core.wakeup_rdata_r[0].g[5]);
    chk("wakeup_rdata_r[0].vs[6]", dut_g.wakeup_data_resp_r_0_entries_vs_6, dut_i.u_core.wakeup_rdata_r[0].vs[6]);
    chk("wakeup_rdata_r[0].g[6]", dut_g.wakeup_data_resp_r_0_entries_perms_6_g, dut_i.u_core.wakeup_rdata_r[0].g[6]);
    chk("wakeup_rdata_r[0].vs[7]", dut_g.wakeup_data_resp_r_0_entries_vs_7, dut_i.u_core.wakeup_rdata_r[0].vs[7]);
    chk("wakeup_rdata_r[0].g[7]", dut_g.wakeup_data_resp_r_0_entries_perms_7_g, dut_i.u_core.wakeup_rdata_r[0].g[7]);
    chk("wakeup_hitvec[1]", dut_g.wakeup_hitVec_1, dut_i.u_core.wakeup_hitvec[1]);
    chk("wakeup_vvec_delay[1]", dut_g.wakeup_vVec_delay[1], dut_i.u_core.wakeup_vvec_delay[1]);
    chk("wakeup_hvec_delay[1]", dut_g.wakeup_hVec_delay_1, dut_i.u_core.wakeup_hvec_delay[1]);
    chk("wakeup_rdata_r[1].tag", dut_g.wakeup_data_resp_r_1_entries_tag, dut_i.u_core.wakeup_rdata_r[1].tag);
    chk("wakeup_rdata_r[1].asid", dut_g.wakeup_data_resp_r_1_entries_asid, dut_i.u_core.wakeup_rdata_r[1].asid);
    chk("wakeup_rdata_r[1].vmid", dut_g.wakeup_data_resp_r_1_entries_vmid, dut_i.u_core.wakeup_rdata_r[1].vmid);
    chk("wakeup_rdata_r[1].vs[0]", dut_g.wakeup_data_resp_r_1_entries_vs_0, dut_i.u_core.wakeup_rdata_r[1].vs[0]);
    chk("wakeup_rdata_r[1].g[0]", dut_g.wakeup_data_resp_r_1_entries_perms_0_g, dut_i.u_core.wakeup_rdata_r[1].g[0]);
    chk("wakeup_rdata_r[1].vs[1]", dut_g.wakeup_data_resp_r_1_entries_vs_1, dut_i.u_core.wakeup_rdata_r[1].vs[1]);
    chk("wakeup_rdata_r[1].g[1]", dut_g.wakeup_data_resp_r_1_entries_perms_1_g, dut_i.u_core.wakeup_rdata_r[1].g[1]);
    chk("wakeup_rdata_r[1].vs[2]", dut_g.wakeup_data_resp_r_1_entries_vs_2, dut_i.u_core.wakeup_rdata_r[1].vs[2]);
    chk("wakeup_rdata_r[1].g[2]", dut_g.wakeup_data_resp_r_1_entries_perms_2_g, dut_i.u_core.wakeup_rdata_r[1].g[2]);
    chk("wakeup_rdata_r[1].vs[3]", dut_g.wakeup_data_resp_r_1_entries_vs_3, dut_i.u_core.wakeup_rdata_r[1].vs[3]);
    chk("wakeup_rdata_r[1].g[3]", dut_g.wakeup_data_resp_r_1_entries_perms_3_g, dut_i.u_core.wakeup_rdata_r[1].g[3]);
    chk("wakeup_rdata_r[1].vs[4]", dut_g.wakeup_data_resp_r_1_entries_vs_4, dut_i.u_core.wakeup_rdata_r[1].vs[4]);
    chk("wakeup_rdata_r[1].g[4]", dut_g.wakeup_data_resp_r_1_entries_perms_4_g, dut_i.u_core.wakeup_rdata_r[1].g[4]);
    chk("wakeup_rdata_r[1].vs[5]", dut_g.wakeup_data_resp_r_1_entries_vs_5, dut_i.u_core.wakeup_rdata_r[1].vs[5]);
    chk("wakeup_rdata_r[1].g[5]", dut_g.wakeup_data_resp_r_1_entries_perms_5_g, dut_i.u_core.wakeup_rdata_r[1].g[5]);
    chk("wakeup_rdata_r[1].vs[6]", dut_g.wakeup_data_resp_r_1_entries_vs_6, dut_i.u_core.wakeup_rdata_r[1].vs[6]);
    chk("wakeup_rdata_r[1].g[6]", dut_g.wakeup_data_resp_r_1_entries_perms_6_g, dut_i.u_core.wakeup_rdata_r[1].g[6]);
    chk("wakeup_rdata_r[1].vs[7]", dut_g.wakeup_data_resp_r_1_entries_vs_7, dut_i.u_core.wakeup_rdata_r[1].vs[7]);
    chk("wakeup_rdata_r[1].g[7]", dut_g.wakeup_data_resp_r_1_entries_perms_7_g, dut_i.u_core.wakeup_rdata_r[1].g[7]);
    chk("wakeup_hitvec[2]", dut_g.wakeup_hitVec_2, dut_i.u_core.wakeup_hitvec[2]);
    chk("wakeup_vvec_delay[2]", dut_g.wakeup_vVec_delay[2], dut_i.u_core.wakeup_vvec_delay[2]);
    chk("wakeup_hvec_delay[2]", dut_g.wakeup_hVec_delay_2, dut_i.u_core.wakeup_hvec_delay[2]);
    chk("wakeup_rdata_r[2].tag", dut_g.wakeup_data_resp_r_2_entries_tag, dut_i.u_core.wakeup_rdata_r[2].tag);
    chk("wakeup_rdata_r[2].asid", dut_g.wakeup_data_resp_r_2_entries_asid, dut_i.u_core.wakeup_rdata_r[2].asid);
    chk("wakeup_rdata_r[2].vmid", dut_g.wakeup_data_resp_r_2_entries_vmid, dut_i.u_core.wakeup_rdata_r[2].vmid);
    chk("wakeup_rdata_r[2].vs[0]", dut_g.wakeup_data_resp_r_2_entries_vs_0, dut_i.u_core.wakeup_rdata_r[2].vs[0]);
    chk("wakeup_rdata_r[2].g[0]", dut_g.wakeup_data_resp_r_2_entries_perms_0_g, dut_i.u_core.wakeup_rdata_r[2].g[0]);
    chk("wakeup_rdata_r[2].vs[1]", dut_g.wakeup_data_resp_r_2_entries_vs_1, dut_i.u_core.wakeup_rdata_r[2].vs[1]);
    chk("wakeup_rdata_r[2].g[1]", dut_g.wakeup_data_resp_r_2_entries_perms_1_g, dut_i.u_core.wakeup_rdata_r[2].g[1]);
    chk("wakeup_rdata_r[2].vs[2]", dut_g.wakeup_data_resp_r_2_entries_vs_2, dut_i.u_core.wakeup_rdata_r[2].vs[2]);
    chk("wakeup_rdata_r[2].g[2]", dut_g.wakeup_data_resp_r_2_entries_perms_2_g, dut_i.u_core.wakeup_rdata_r[2].g[2]);
    chk("wakeup_rdata_r[2].vs[3]", dut_g.wakeup_data_resp_r_2_entries_vs_3, dut_i.u_core.wakeup_rdata_r[2].vs[3]);
    chk("wakeup_rdata_r[2].g[3]", dut_g.wakeup_data_resp_r_2_entries_perms_3_g, dut_i.u_core.wakeup_rdata_r[2].g[3]);
    chk("wakeup_rdata_r[2].vs[4]", dut_g.wakeup_data_resp_r_2_entries_vs_4, dut_i.u_core.wakeup_rdata_r[2].vs[4]);
    chk("wakeup_rdata_r[2].g[4]", dut_g.wakeup_data_resp_r_2_entries_perms_4_g, dut_i.u_core.wakeup_rdata_r[2].g[4]);
    chk("wakeup_rdata_r[2].vs[5]", dut_g.wakeup_data_resp_r_2_entries_vs_5, dut_i.u_core.wakeup_rdata_r[2].vs[5]);
    chk("wakeup_rdata_r[2].g[5]", dut_g.wakeup_data_resp_r_2_entries_perms_5_g, dut_i.u_core.wakeup_rdata_r[2].g[5]);
    chk("wakeup_rdata_r[2].vs[6]", dut_g.wakeup_data_resp_r_2_entries_vs_6, dut_i.u_core.wakeup_rdata_r[2].vs[6]);
    chk("wakeup_rdata_r[2].g[6]", dut_g.wakeup_data_resp_r_2_entries_perms_6_g, dut_i.u_core.wakeup_rdata_r[2].g[6]);
    chk("wakeup_rdata_r[2].vs[7]", dut_g.wakeup_data_resp_r_2_entries_vs_7, dut_i.u_core.wakeup_rdata_r[2].vs[7]);
    chk("wakeup_rdata_r[2].g[7]", dut_g.wakeup_data_resp_r_2_entries_perms_7_g, dut_i.u_core.wakeup_rdata_r[2].g[7]);
    chk("wakeup_hitvec[3]", dut_g.wakeup_hitVec_3, dut_i.u_core.wakeup_hitvec[3]);
    chk("wakeup_vvec_delay[3]", dut_g.wakeup_vVec_delay[3], dut_i.u_core.wakeup_vvec_delay[3]);
    chk("wakeup_hvec_delay[3]", dut_g.wakeup_hVec_delay_3, dut_i.u_core.wakeup_hvec_delay[3]);
    chk("wakeup_rdata_r[3].tag", dut_g.wakeup_data_resp_r_3_entries_tag, dut_i.u_core.wakeup_rdata_r[3].tag);
    chk("wakeup_rdata_r[3].asid", dut_g.wakeup_data_resp_r_3_entries_asid, dut_i.u_core.wakeup_rdata_r[3].asid);
    chk("wakeup_rdata_r[3].vmid", dut_g.wakeup_data_resp_r_3_entries_vmid, dut_i.u_core.wakeup_rdata_r[3].vmid);
    chk("wakeup_rdata_r[3].vs[0]", dut_g.wakeup_data_resp_r_3_entries_vs_0, dut_i.u_core.wakeup_rdata_r[3].vs[0]);
    chk("wakeup_rdata_r[3].g[0]", dut_g.wakeup_data_resp_r_3_entries_perms_0_g, dut_i.u_core.wakeup_rdata_r[3].g[0]);
    chk("wakeup_rdata_r[3].vs[1]", dut_g.wakeup_data_resp_r_3_entries_vs_1, dut_i.u_core.wakeup_rdata_r[3].vs[1]);
    chk("wakeup_rdata_r[3].g[1]", dut_g.wakeup_data_resp_r_3_entries_perms_1_g, dut_i.u_core.wakeup_rdata_r[3].g[1]);
    chk("wakeup_rdata_r[3].vs[2]", dut_g.wakeup_data_resp_r_3_entries_vs_2, dut_i.u_core.wakeup_rdata_r[3].vs[2]);
    chk("wakeup_rdata_r[3].g[2]", dut_g.wakeup_data_resp_r_3_entries_perms_2_g, dut_i.u_core.wakeup_rdata_r[3].g[2]);
    chk("wakeup_rdata_r[3].vs[3]", dut_g.wakeup_data_resp_r_3_entries_vs_3, dut_i.u_core.wakeup_rdata_r[3].vs[3]);
    chk("wakeup_rdata_r[3].g[3]", dut_g.wakeup_data_resp_r_3_entries_perms_3_g, dut_i.u_core.wakeup_rdata_r[3].g[3]);
    chk("wakeup_rdata_r[3].vs[4]", dut_g.wakeup_data_resp_r_3_entries_vs_4, dut_i.u_core.wakeup_rdata_r[3].vs[4]);
    chk("wakeup_rdata_r[3].g[4]", dut_g.wakeup_data_resp_r_3_entries_perms_4_g, dut_i.u_core.wakeup_rdata_r[3].g[4]);
    chk("wakeup_rdata_r[3].vs[5]", dut_g.wakeup_data_resp_r_3_entries_vs_5, dut_i.u_core.wakeup_rdata_r[3].vs[5]);
    chk("wakeup_rdata_r[3].g[5]", dut_g.wakeup_data_resp_r_3_entries_perms_5_g, dut_i.u_core.wakeup_rdata_r[3].g[5]);
    chk("wakeup_rdata_r[3].vs[6]", dut_g.wakeup_data_resp_r_3_entries_vs_6, dut_i.u_core.wakeup_rdata_r[3].vs[6]);
    chk("wakeup_rdata_r[3].g[6]", dut_g.wakeup_data_resp_r_3_entries_perms_6_g, dut_i.u_core.wakeup_rdata_r[3].g[6]);
    chk("wakeup_rdata_r[3].vs[7]", dut_g.wakeup_data_resp_r_3_entries_vs_7, dut_i.u_core.wakeup_rdata_r[3].vs[7]);
    chk("wakeup_rdata_r[3].g[7]", dut_g.wakeup_data_resp_r_3_entries_perms_7_g, dut_i.u_core.wakeup_rdata_r[3].g[7]);
  endtask
  // END GENERATED(state_cmp)

  // BEGIN GENERATED(port_cmp)
  // 由 gen_state_cmp.py 生成（golden 端口表逐根量出）。改这段请改生成器。
  task automatic compare_outputs();
    chk("io_req_ready", g_io_req_ready, i_io_req_ready);
    chk("io_resp_valid", g_io_resp_valid, i_io_resp_valid);
    chk("io_resp_bits_req_info_vpn", g_io_resp_bits_req_info_vpn, i_io_resp_bits_req_info_vpn);
    chk("io_resp_bits_req_info_s2xlate", g_io_resp_bits_req_info_s2xlate, i_io_resp_bits_req_info_s2xlate);
    chk("io_resp_bits_req_info_source", g_io_resp_bits_req_info_source, i_io_resp_bits_req_info_source);
    chk("io_resp_bits_isFirst", g_io_resp_bits_isFirst, i_io_resp_bits_isFirst);
    chk("io_resp_bits_hit", g_io_resp_bits_hit, i_io_resp_bits_hit);
    chk("io_resp_bits_prefetch", g_io_resp_bits_prefetch, i_io_resp_bits_prefetch);
    chk("io_resp_bits_bypassed", g_io_resp_bits_bypassed, i_io_resp_bits_bypassed);
    chk("io_resp_bits_toFsm_l3Hit", g_io_resp_bits_toFsm_l3Hit, i_io_resp_bits_toFsm_l3Hit);
    chk("io_resp_bits_toFsm_l2Hit", g_io_resp_bits_toFsm_l2Hit, i_io_resp_bits_toFsm_l2Hit);
    chk("io_resp_bits_toFsm_l1Hit", g_io_resp_bits_toFsm_l1Hit, i_io_resp_bits_toFsm_l1Hit);
    chk("io_resp_bits_toFsm_ppn", g_io_resp_bits_toFsm_ppn, i_io_resp_bits_toFsm_ppn);
    chk("io_resp_bits_toFsm_stage1Hit", g_io_resp_bits_toFsm_stage1Hit, i_io_resp_bits_toFsm_stage1Hit);
    chk("io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check", g_io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check, i_io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check);
    chk("io_resp_bits_toFsm_bitmapCheck_toLLPTW", g_io_resp_bits_toFsm_bitmapCheck_toLLPTW, i_io_resp_bits_toFsm_bitmapCheck_toLLPTW);
    chk("io_resp_bits_toFsm_bitmapCheck_hitway", g_io_resp_bits_toFsm_bitmapCheck_hitway, i_io_resp_bits_toFsm_bitmapCheck_hitway);
    chk("io_resp_bits_toFsm_bitmapCheck_pte", g_io_resp_bits_toFsm_bitmapCheck_pte, i_io_resp_bits_toFsm_bitmapCheck_pte);
    chk("io_resp_bits_toFsm_bitmapCheck_ptes_0", g_io_resp_bits_toFsm_bitmapCheck_ptes_0, i_io_resp_bits_toFsm_bitmapCheck_ptes_0);
    chk("io_resp_bits_toFsm_bitmapCheck_ptes_1", g_io_resp_bits_toFsm_bitmapCheck_ptes_1, i_io_resp_bits_toFsm_bitmapCheck_ptes_1);
    chk("io_resp_bits_toFsm_bitmapCheck_ptes_2", g_io_resp_bits_toFsm_bitmapCheck_ptes_2, i_io_resp_bits_toFsm_bitmapCheck_ptes_2);
    chk("io_resp_bits_toFsm_bitmapCheck_ptes_3", g_io_resp_bits_toFsm_bitmapCheck_ptes_3, i_io_resp_bits_toFsm_bitmapCheck_ptes_3);
    chk("io_resp_bits_toFsm_bitmapCheck_ptes_4", g_io_resp_bits_toFsm_bitmapCheck_ptes_4, i_io_resp_bits_toFsm_bitmapCheck_ptes_4);
    chk("io_resp_bits_toFsm_bitmapCheck_ptes_5", g_io_resp_bits_toFsm_bitmapCheck_ptes_5, i_io_resp_bits_toFsm_bitmapCheck_ptes_5);
    chk("io_resp_bits_toFsm_bitmapCheck_ptes_6", g_io_resp_bits_toFsm_bitmapCheck_ptes_6, i_io_resp_bits_toFsm_bitmapCheck_ptes_6);
    chk("io_resp_bits_toFsm_bitmapCheck_ptes_7", g_io_resp_bits_toFsm_bitmapCheck_ptes_7, i_io_resp_bits_toFsm_bitmapCheck_ptes_7);
    chk("io_resp_bits_toFsm_bitmapCheck_cfs_0", g_io_resp_bits_toFsm_bitmapCheck_cfs_0, i_io_resp_bits_toFsm_bitmapCheck_cfs_0);
    chk("io_resp_bits_toFsm_bitmapCheck_cfs_1", g_io_resp_bits_toFsm_bitmapCheck_cfs_1, i_io_resp_bits_toFsm_bitmapCheck_cfs_1);
    chk("io_resp_bits_toFsm_bitmapCheck_cfs_2", g_io_resp_bits_toFsm_bitmapCheck_cfs_2, i_io_resp_bits_toFsm_bitmapCheck_cfs_2);
    chk("io_resp_bits_toFsm_bitmapCheck_cfs_3", g_io_resp_bits_toFsm_bitmapCheck_cfs_3, i_io_resp_bits_toFsm_bitmapCheck_cfs_3);
    chk("io_resp_bits_toFsm_bitmapCheck_cfs_4", g_io_resp_bits_toFsm_bitmapCheck_cfs_4, i_io_resp_bits_toFsm_bitmapCheck_cfs_4);
    chk("io_resp_bits_toFsm_bitmapCheck_cfs_5", g_io_resp_bits_toFsm_bitmapCheck_cfs_5, i_io_resp_bits_toFsm_bitmapCheck_cfs_5);
    chk("io_resp_bits_toFsm_bitmapCheck_cfs_6", g_io_resp_bits_toFsm_bitmapCheck_cfs_6, i_io_resp_bits_toFsm_bitmapCheck_cfs_6);
    chk("io_resp_bits_toFsm_bitmapCheck_cfs_7", g_io_resp_bits_toFsm_bitmapCheck_cfs_7, i_io_resp_bits_toFsm_bitmapCheck_cfs_7);
    chk("io_resp_bits_toFsm_bitmapCheck_SPlevel", g_io_resp_bits_toFsm_bitmapCheck_SPlevel, i_io_resp_bits_toFsm_bitmapCheck_SPlevel);
    chk("io_resp_bits_stage1_entry_0_tag", g_io_resp_bits_stage1_entry_0_tag, i_io_resp_bits_stage1_entry_0_tag);
    chk("io_resp_bits_stage1_entry_0_asid", g_io_resp_bits_stage1_entry_0_asid, i_io_resp_bits_stage1_entry_0_asid);
    chk("io_resp_bits_stage1_entry_0_vmid", g_io_resp_bits_stage1_entry_0_vmid, i_io_resp_bits_stage1_entry_0_vmid);
    chk("io_resp_bits_stage1_entry_0_n", g_io_resp_bits_stage1_entry_0_n, i_io_resp_bits_stage1_entry_0_n);
    chk("io_resp_bits_stage1_entry_0_pbmt", g_io_resp_bits_stage1_entry_0_pbmt, i_io_resp_bits_stage1_entry_0_pbmt);
    chk("io_resp_bits_stage1_entry_0_perm_d", g_io_resp_bits_stage1_entry_0_perm_d, i_io_resp_bits_stage1_entry_0_perm_d);
    chk("io_resp_bits_stage1_entry_0_perm_a", g_io_resp_bits_stage1_entry_0_perm_a, i_io_resp_bits_stage1_entry_0_perm_a);
    chk("io_resp_bits_stage1_entry_0_perm_g", g_io_resp_bits_stage1_entry_0_perm_g, i_io_resp_bits_stage1_entry_0_perm_g);
    chk("io_resp_bits_stage1_entry_0_perm_u", g_io_resp_bits_stage1_entry_0_perm_u, i_io_resp_bits_stage1_entry_0_perm_u);
    chk("io_resp_bits_stage1_entry_0_perm_x", g_io_resp_bits_stage1_entry_0_perm_x, i_io_resp_bits_stage1_entry_0_perm_x);
    chk("io_resp_bits_stage1_entry_0_perm_w", g_io_resp_bits_stage1_entry_0_perm_w, i_io_resp_bits_stage1_entry_0_perm_w);
    chk("io_resp_bits_stage1_entry_0_perm_r", g_io_resp_bits_stage1_entry_0_perm_r, i_io_resp_bits_stage1_entry_0_perm_r);
    chk("io_resp_bits_stage1_entry_0_level", g_io_resp_bits_stage1_entry_0_level, i_io_resp_bits_stage1_entry_0_level);
    chk("io_resp_bits_stage1_entry_0_v", g_io_resp_bits_stage1_entry_0_v, i_io_resp_bits_stage1_entry_0_v);
    chk("io_resp_bits_stage1_entry_0_ppn", g_io_resp_bits_stage1_entry_0_ppn, i_io_resp_bits_stage1_entry_0_ppn);
    chk("io_resp_bits_stage1_entry_0_ppn_low", g_io_resp_bits_stage1_entry_0_ppn_low, i_io_resp_bits_stage1_entry_0_ppn_low);
    chk("io_resp_bits_stage1_entry_0_pf", g_io_resp_bits_stage1_entry_0_pf, i_io_resp_bits_stage1_entry_0_pf);
    chk("io_resp_bits_stage1_entry_0_cf", g_io_resp_bits_stage1_entry_0_cf, i_io_resp_bits_stage1_entry_0_cf);
    chk("io_resp_bits_stage1_entry_1_tag", g_io_resp_bits_stage1_entry_1_tag, i_io_resp_bits_stage1_entry_1_tag);
    chk("io_resp_bits_stage1_entry_1_asid", g_io_resp_bits_stage1_entry_1_asid, i_io_resp_bits_stage1_entry_1_asid);
    chk("io_resp_bits_stage1_entry_1_vmid", g_io_resp_bits_stage1_entry_1_vmid, i_io_resp_bits_stage1_entry_1_vmid);
    chk("io_resp_bits_stage1_entry_1_n", g_io_resp_bits_stage1_entry_1_n, i_io_resp_bits_stage1_entry_1_n);
    chk("io_resp_bits_stage1_entry_1_pbmt", g_io_resp_bits_stage1_entry_1_pbmt, i_io_resp_bits_stage1_entry_1_pbmt);
    chk("io_resp_bits_stage1_entry_1_perm_d", g_io_resp_bits_stage1_entry_1_perm_d, i_io_resp_bits_stage1_entry_1_perm_d);
    chk("io_resp_bits_stage1_entry_1_perm_a", g_io_resp_bits_stage1_entry_1_perm_a, i_io_resp_bits_stage1_entry_1_perm_a);
    chk("io_resp_bits_stage1_entry_1_perm_g", g_io_resp_bits_stage1_entry_1_perm_g, i_io_resp_bits_stage1_entry_1_perm_g);
    chk("io_resp_bits_stage1_entry_1_perm_u", g_io_resp_bits_stage1_entry_1_perm_u, i_io_resp_bits_stage1_entry_1_perm_u);
    chk("io_resp_bits_stage1_entry_1_perm_x", g_io_resp_bits_stage1_entry_1_perm_x, i_io_resp_bits_stage1_entry_1_perm_x);
    chk("io_resp_bits_stage1_entry_1_perm_w", g_io_resp_bits_stage1_entry_1_perm_w, i_io_resp_bits_stage1_entry_1_perm_w);
    chk("io_resp_bits_stage1_entry_1_perm_r", g_io_resp_bits_stage1_entry_1_perm_r, i_io_resp_bits_stage1_entry_1_perm_r);
    chk("io_resp_bits_stage1_entry_1_level", g_io_resp_bits_stage1_entry_1_level, i_io_resp_bits_stage1_entry_1_level);
    chk("io_resp_bits_stage1_entry_1_v", g_io_resp_bits_stage1_entry_1_v, i_io_resp_bits_stage1_entry_1_v);
    chk("io_resp_bits_stage1_entry_1_ppn", g_io_resp_bits_stage1_entry_1_ppn, i_io_resp_bits_stage1_entry_1_ppn);
    chk("io_resp_bits_stage1_entry_1_ppn_low", g_io_resp_bits_stage1_entry_1_ppn_low, i_io_resp_bits_stage1_entry_1_ppn_low);
    chk("io_resp_bits_stage1_entry_1_pf", g_io_resp_bits_stage1_entry_1_pf, i_io_resp_bits_stage1_entry_1_pf);
    chk("io_resp_bits_stage1_entry_1_cf", g_io_resp_bits_stage1_entry_1_cf, i_io_resp_bits_stage1_entry_1_cf);
    chk("io_resp_bits_stage1_entry_2_tag", g_io_resp_bits_stage1_entry_2_tag, i_io_resp_bits_stage1_entry_2_tag);
    chk("io_resp_bits_stage1_entry_2_asid", g_io_resp_bits_stage1_entry_2_asid, i_io_resp_bits_stage1_entry_2_asid);
    chk("io_resp_bits_stage1_entry_2_vmid", g_io_resp_bits_stage1_entry_2_vmid, i_io_resp_bits_stage1_entry_2_vmid);
    chk("io_resp_bits_stage1_entry_2_n", g_io_resp_bits_stage1_entry_2_n, i_io_resp_bits_stage1_entry_2_n);
    chk("io_resp_bits_stage1_entry_2_pbmt", g_io_resp_bits_stage1_entry_2_pbmt, i_io_resp_bits_stage1_entry_2_pbmt);
    chk("io_resp_bits_stage1_entry_2_perm_d", g_io_resp_bits_stage1_entry_2_perm_d, i_io_resp_bits_stage1_entry_2_perm_d);
    chk("io_resp_bits_stage1_entry_2_perm_a", g_io_resp_bits_stage1_entry_2_perm_a, i_io_resp_bits_stage1_entry_2_perm_a);
    chk("io_resp_bits_stage1_entry_2_perm_g", g_io_resp_bits_stage1_entry_2_perm_g, i_io_resp_bits_stage1_entry_2_perm_g);
    chk("io_resp_bits_stage1_entry_2_perm_u", g_io_resp_bits_stage1_entry_2_perm_u, i_io_resp_bits_stage1_entry_2_perm_u);
    chk("io_resp_bits_stage1_entry_2_perm_x", g_io_resp_bits_stage1_entry_2_perm_x, i_io_resp_bits_stage1_entry_2_perm_x);
    chk("io_resp_bits_stage1_entry_2_perm_w", g_io_resp_bits_stage1_entry_2_perm_w, i_io_resp_bits_stage1_entry_2_perm_w);
    chk("io_resp_bits_stage1_entry_2_perm_r", g_io_resp_bits_stage1_entry_2_perm_r, i_io_resp_bits_stage1_entry_2_perm_r);
    chk("io_resp_bits_stage1_entry_2_level", g_io_resp_bits_stage1_entry_2_level, i_io_resp_bits_stage1_entry_2_level);
    chk("io_resp_bits_stage1_entry_2_v", g_io_resp_bits_stage1_entry_2_v, i_io_resp_bits_stage1_entry_2_v);
    chk("io_resp_bits_stage1_entry_2_ppn", g_io_resp_bits_stage1_entry_2_ppn, i_io_resp_bits_stage1_entry_2_ppn);
    chk("io_resp_bits_stage1_entry_2_ppn_low", g_io_resp_bits_stage1_entry_2_ppn_low, i_io_resp_bits_stage1_entry_2_ppn_low);
    chk("io_resp_bits_stage1_entry_2_pf", g_io_resp_bits_stage1_entry_2_pf, i_io_resp_bits_stage1_entry_2_pf);
    chk("io_resp_bits_stage1_entry_2_cf", g_io_resp_bits_stage1_entry_2_cf, i_io_resp_bits_stage1_entry_2_cf);
    chk("io_resp_bits_stage1_entry_3_tag", g_io_resp_bits_stage1_entry_3_tag, i_io_resp_bits_stage1_entry_3_tag);
    chk("io_resp_bits_stage1_entry_3_asid", g_io_resp_bits_stage1_entry_3_asid, i_io_resp_bits_stage1_entry_3_asid);
    chk("io_resp_bits_stage1_entry_3_vmid", g_io_resp_bits_stage1_entry_3_vmid, i_io_resp_bits_stage1_entry_3_vmid);
    chk("io_resp_bits_stage1_entry_3_n", g_io_resp_bits_stage1_entry_3_n, i_io_resp_bits_stage1_entry_3_n);
    chk("io_resp_bits_stage1_entry_3_pbmt", g_io_resp_bits_stage1_entry_3_pbmt, i_io_resp_bits_stage1_entry_3_pbmt);
    chk("io_resp_bits_stage1_entry_3_perm_d", g_io_resp_bits_stage1_entry_3_perm_d, i_io_resp_bits_stage1_entry_3_perm_d);
    chk("io_resp_bits_stage1_entry_3_perm_a", g_io_resp_bits_stage1_entry_3_perm_a, i_io_resp_bits_stage1_entry_3_perm_a);
    chk("io_resp_bits_stage1_entry_3_perm_g", g_io_resp_bits_stage1_entry_3_perm_g, i_io_resp_bits_stage1_entry_3_perm_g);
    chk("io_resp_bits_stage1_entry_3_perm_u", g_io_resp_bits_stage1_entry_3_perm_u, i_io_resp_bits_stage1_entry_3_perm_u);
    chk("io_resp_bits_stage1_entry_3_perm_x", g_io_resp_bits_stage1_entry_3_perm_x, i_io_resp_bits_stage1_entry_3_perm_x);
    chk("io_resp_bits_stage1_entry_3_perm_w", g_io_resp_bits_stage1_entry_3_perm_w, i_io_resp_bits_stage1_entry_3_perm_w);
    chk("io_resp_bits_stage1_entry_3_perm_r", g_io_resp_bits_stage1_entry_3_perm_r, i_io_resp_bits_stage1_entry_3_perm_r);
    chk("io_resp_bits_stage1_entry_3_level", g_io_resp_bits_stage1_entry_3_level, i_io_resp_bits_stage1_entry_3_level);
    chk("io_resp_bits_stage1_entry_3_v", g_io_resp_bits_stage1_entry_3_v, i_io_resp_bits_stage1_entry_3_v);
    chk("io_resp_bits_stage1_entry_3_ppn", g_io_resp_bits_stage1_entry_3_ppn, i_io_resp_bits_stage1_entry_3_ppn);
    chk("io_resp_bits_stage1_entry_3_ppn_low", g_io_resp_bits_stage1_entry_3_ppn_low, i_io_resp_bits_stage1_entry_3_ppn_low);
    chk("io_resp_bits_stage1_entry_3_pf", g_io_resp_bits_stage1_entry_3_pf, i_io_resp_bits_stage1_entry_3_pf);
    chk("io_resp_bits_stage1_entry_3_cf", g_io_resp_bits_stage1_entry_3_cf, i_io_resp_bits_stage1_entry_3_cf);
    chk("io_resp_bits_stage1_entry_4_tag", g_io_resp_bits_stage1_entry_4_tag, i_io_resp_bits_stage1_entry_4_tag);
    chk("io_resp_bits_stage1_entry_4_asid", g_io_resp_bits_stage1_entry_4_asid, i_io_resp_bits_stage1_entry_4_asid);
    chk("io_resp_bits_stage1_entry_4_vmid", g_io_resp_bits_stage1_entry_4_vmid, i_io_resp_bits_stage1_entry_4_vmid);
    chk("io_resp_bits_stage1_entry_4_n", g_io_resp_bits_stage1_entry_4_n, i_io_resp_bits_stage1_entry_4_n);
    chk("io_resp_bits_stage1_entry_4_pbmt", g_io_resp_bits_stage1_entry_4_pbmt, i_io_resp_bits_stage1_entry_4_pbmt);
    chk("io_resp_bits_stage1_entry_4_perm_d", g_io_resp_bits_stage1_entry_4_perm_d, i_io_resp_bits_stage1_entry_4_perm_d);
    chk("io_resp_bits_stage1_entry_4_perm_a", g_io_resp_bits_stage1_entry_4_perm_a, i_io_resp_bits_stage1_entry_4_perm_a);
    chk("io_resp_bits_stage1_entry_4_perm_g", g_io_resp_bits_stage1_entry_4_perm_g, i_io_resp_bits_stage1_entry_4_perm_g);
    chk("io_resp_bits_stage1_entry_4_perm_u", g_io_resp_bits_stage1_entry_4_perm_u, i_io_resp_bits_stage1_entry_4_perm_u);
    chk("io_resp_bits_stage1_entry_4_perm_x", g_io_resp_bits_stage1_entry_4_perm_x, i_io_resp_bits_stage1_entry_4_perm_x);
    chk("io_resp_bits_stage1_entry_4_perm_w", g_io_resp_bits_stage1_entry_4_perm_w, i_io_resp_bits_stage1_entry_4_perm_w);
    chk("io_resp_bits_stage1_entry_4_perm_r", g_io_resp_bits_stage1_entry_4_perm_r, i_io_resp_bits_stage1_entry_4_perm_r);
    chk("io_resp_bits_stage1_entry_4_level", g_io_resp_bits_stage1_entry_4_level, i_io_resp_bits_stage1_entry_4_level);
    chk("io_resp_bits_stage1_entry_4_v", g_io_resp_bits_stage1_entry_4_v, i_io_resp_bits_stage1_entry_4_v);
    chk("io_resp_bits_stage1_entry_4_ppn", g_io_resp_bits_stage1_entry_4_ppn, i_io_resp_bits_stage1_entry_4_ppn);
    chk("io_resp_bits_stage1_entry_4_ppn_low", g_io_resp_bits_stage1_entry_4_ppn_low, i_io_resp_bits_stage1_entry_4_ppn_low);
    chk("io_resp_bits_stage1_entry_4_pf", g_io_resp_bits_stage1_entry_4_pf, i_io_resp_bits_stage1_entry_4_pf);
    chk("io_resp_bits_stage1_entry_4_cf", g_io_resp_bits_stage1_entry_4_cf, i_io_resp_bits_stage1_entry_4_cf);
    chk("io_resp_bits_stage1_entry_5_tag", g_io_resp_bits_stage1_entry_5_tag, i_io_resp_bits_stage1_entry_5_tag);
    chk("io_resp_bits_stage1_entry_5_asid", g_io_resp_bits_stage1_entry_5_asid, i_io_resp_bits_stage1_entry_5_asid);
    chk("io_resp_bits_stage1_entry_5_vmid", g_io_resp_bits_stage1_entry_5_vmid, i_io_resp_bits_stage1_entry_5_vmid);
    chk("io_resp_bits_stage1_entry_5_n", g_io_resp_bits_stage1_entry_5_n, i_io_resp_bits_stage1_entry_5_n);
    chk("io_resp_bits_stage1_entry_5_pbmt", g_io_resp_bits_stage1_entry_5_pbmt, i_io_resp_bits_stage1_entry_5_pbmt);
    chk("io_resp_bits_stage1_entry_5_perm_d", g_io_resp_bits_stage1_entry_5_perm_d, i_io_resp_bits_stage1_entry_5_perm_d);
    chk("io_resp_bits_stage1_entry_5_perm_a", g_io_resp_bits_stage1_entry_5_perm_a, i_io_resp_bits_stage1_entry_5_perm_a);
    chk("io_resp_bits_stage1_entry_5_perm_g", g_io_resp_bits_stage1_entry_5_perm_g, i_io_resp_bits_stage1_entry_5_perm_g);
    chk("io_resp_bits_stage1_entry_5_perm_u", g_io_resp_bits_stage1_entry_5_perm_u, i_io_resp_bits_stage1_entry_5_perm_u);
    chk("io_resp_bits_stage1_entry_5_perm_x", g_io_resp_bits_stage1_entry_5_perm_x, i_io_resp_bits_stage1_entry_5_perm_x);
    chk("io_resp_bits_stage1_entry_5_perm_w", g_io_resp_bits_stage1_entry_5_perm_w, i_io_resp_bits_stage1_entry_5_perm_w);
    chk("io_resp_bits_stage1_entry_5_perm_r", g_io_resp_bits_stage1_entry_5_perm_r, i_io_resp_bits_stage1_entry_5_perm_r);
    chk("io_resp_bits_stage1_entry_5_level", g_io_resp_bits_stage1_entry_5_level, i_io_resp_bits_stage1_entry_5_level);
    chk("io_resp_bits_stage1_entry_5_v", g_io_resp_bits_stage1_entry_5_v, i_io_resp_bits_stage1_entry_5_v);
    chk("io_resp_bits_stage1_entry_5_ppn", g_io_resp_bits_stage1_entry_5_ppn, i_io_resp_bits_stage1_entry_5_ppn);
    chk("io_resp_bits_stage1_entry_5_ppn_low", g_io_resp_bits_stage1_entry_5_ppn_low, i_io_resp_bits_stage1_entry_5_ppn_low);
    chk("io_resp_bits_stage1_entry_5_pf", g_io_resp_bits_stage1_entry_5_pf, i_io_resp_bits_stage1_entry_5_pf);
    chk("io_resp_bits_stage1_entry_5_cf", g_io_resp_bits_stage1_entry_5_cf, i_io_resp_bits_stage1_entry_5_cf);
    chk("io_resp_bits_stage1_entry_6_tag", g_io_resp_bits_stage1_entry_6_tag, i_io_resp_bits_stage1_entry_6_tag);
    chk("io_resp_bits_stage1_entry_6_asid", g_io_resp_bits_stage1_entry_6_asid, i_io_resp_bits_stage1_entry_6_asid);
    chk("io_resp_bits_stage1_entry_6_vmid", g_io_resp_bits_stage1_entry_6_vmid, i_io_resp_bits_stage1_entry_6_vmid);
    chk("io_resp_bits_stage1_entry_6_n", g_io_resp_bits_stage1_entry_6_n, i_io_resp_bits_stage1_entry_6_n);
    chk("io_resp_bits_stage1_entry_6_pbmt", g_io_resp_bits_stage1_entry_6_pbmt, i_io_resp_bits_stage1_entry_6_pbmt);
    chk("io_resp_bits_stage1_entry_6_perm_d", g_io_resp_bits_stage1_entry_6_perm_d, i_io_resp_bits_stage1_entry_6_perm_d);
    chk("io_resp_bits_stage1_entry_6_perm_a", g_io_resp_bits_stage1_entry_6_perm_a, i_io_resp_bits_stage1_entry_6_perm_a);
    chk("io_resp_bits_stage1_entry_6_perm_g", g_io_resp_bits_stage1_entry_6_perm_g, i_io_resp_bits_stage1_entry_6_perm_g);
    chk("io_resp_bits_stage1_entry_6_perm_u", g_io_resp_bits_stage1_entry_6_perm_u, i_io_resp_bits_stage1_entry_6_perm_u);
    chk("io_resp_bits_stage1_entry_6_perm_x", g_io_resp_bits_stage1_entry_6_perm_x, i_io_resp_bits_stage1_entry_6_perm_x);
    chk("io_resp_bits_stage1_entry_6_perm_w", g_io_resp_bits_stage1_entry_6_perm_w, i_io_resp_bits_stage1_entry_6_perm_w);
    chk("io_resp_bits_stage1_entry_6_perm_r", g_io_resp_bits_stage1_entry_6_perm_r, i_io_resp_bits_stage1_entry_6_perm_r);
    chk("io_resp_bits_stage1_entry_6_level", g_io_resp_bits_stage1_entry_6_level, i_io_resp_bits_stage1_entry_6_level);
    chk("io_resp_bits_stage1_entry_6_v", g_io_resp_bits_stage1_entry_6_v, i_io_resp_bits_stage1_entry_6_v);
    chk("io_resp_bits_stage1_entry_6_ppn", g_io_resp_bits_stage1_entry_6_ppn, i_io_resp_bits_stage1_entry_6_ppn);
    chk("io_resp_bits_stage1_entry_6_ppn_low", g_io_resp_bits_stage1_entry_6_ppn_low, i_io_resp_bits_stage1_entry_6_ppn_low);
    chk("io_resp_bits_stage1_entry_6_pf", g_io_resp_bits_stage1_entry_6_pf, i_io_resp_bits_stage1_entry_6_pf);
    chk("io_resp_bits_stage1_entry_6_cf", g_io_resp_bits_stage1_entry_6_cf, i_io_resp_bits_stage1_entry_6_cf);
    chk("io_resp_bits_stage1_entry_7_tag", g_io_resp_bits_stage1_entry_7_tag, i_io_resp_bits_stage1_entry_7_tag);
    chk("io_resp_bits_stage1_entry_7_asid", g_io_resp_bits_stage1_entry_7_asid, i_io_resp_bits_stage1_entry_7_asid);
    chk("io_resp_bits_stage1_entry_7_vmid", g_io_resp_bits_stage1_entry_7_vmid, i_io_resp_bits_stage1_entry_7_vmid);
    chk("io_resp_bits_stage1_entry_7_n", g_io_resp_bits_stage1_entry_7_n, i_io_resp_bits_stage1_entry_7_n);
    chk("io_resp_bits_stage1_entry_7_pbmt", g_io_resp_bits_stage1_entry_7_pbmt, i_io_resp_bits_stage1_entry_7_pbmt);
    chk("io_resp_bits_stage1_entry_7_perm_d", g_io_resp_bits_stage1_entry_7_perm_d, i_io_resp_bits_stage1_entry_7_perm_d);
    chk("io_resp_bits_stage1_entry_7_perm_a", g_io_resp_bits_stage1_entry_7_perm_a, i_io_resp_bits_stage1_entry_7_perm_a);
    chk("io_resp_bits_stage1_entry_7_perm_g", g_io_resp_bits_stage1_entry_7_perm_g, i_io_resp_bits_stage1_entry_7_perm_g);
    chk("io_resp_bits_stage1_entry_7_perm_u", g_io_resp_bits_stage1_entry_7_perm_u, i_io_resp_bits_stage1_entry_7_perm_u);
    chk("io_resp_bits_stage1_entry_7_perm_x", g_io_resp_bits_stage1_entry_7_perm_x, i_io_resp_bits_stage1_entry_7_perm_x);
    chk("io_resp_bits_stage1_entry_7_perm_w", g_io_resp_bits_stage1_entry_7_perm_w, i_io_resp_bits_stage1_entry_7_perm_w);
    chk("io_resp_bits_stage1_entry_7_perm_r", g_io_resp_bits_stage1_entry_7_perm_r, i_io_resp_bits_stage1_entry_7_perm_r);
    chk("io_resp_bits_stage1_entry_7_level", g_io_resp_bits_stage1_entry_7_level, i_io_resp_bits_stage1_entry_7_level);
    chk("io_resp_bits_stage1_entry_7_v", g_io_resp_bits_stage1_entry_7_v, i_io_resp_bits_stage1_entry_7_v);
    chk("io_resp_bits_stage1_entry_7_ppn", g_io_resp_bits_stage1_entry_7_ppn, i_io_resp_bits_stage1_entry_7_ppn);
    chk("io_resp_bits_stage1_entry_7_ppn_low", g_io_resp_bits_stage1_entry_7_ppn_low, i_io_resp_bits_stage1_entry_7_ppn_low);
    chk("io_resp_bits_stage1_entry_7_pf", g_io_resp_bits_stage1_entry_7_pf, i_io_resp_bits_stage1_entry_7_pf);
    chk("io_resp_bits_stage1_entry_7_cf", g_io_resp_bits_stage1_entry_7_cf, i_io_resp_bits_stage1_entry_7_cf);
    chk("io_resp_bits_stage1_pteidx_0", g_io_resp_bits_stage1_pteidx_0, i_io_resp_bits_stage1_pteidx_0);
    chk("io_resp_bits_stage1_pteidx_1", g_io_resp_bits_stage1_pteidx_1, i_io_resp_bits_stage1_pteidx_1);
    chk("io_resp_bits_stage1_pteidx_2", g_io_resp_bits_stage1_pteidx_2, i_io_resp_bits_stage1_pteidx_2);
    chk("io_resp_bits_stage1_pteidx_3", g_io_resp_bits_stage1_pteidx_3, i_io_resp_bits_stage1_pteidx_3);
    chk("io_resp_bits_stage1_pteidx_4", g_io_resp_bits_stage1_pteidx_4, i_io_resp_bits_stage1_pteidx_4);
    chk("io_resp_bits_stage1_pteidx_5", g_io_resp_bits_stage1_pteidx_5, i_io_resp_bits_stage1_pteidx_5);
    chk("io_resp_bits_stage1_pteidx_6", g_io_resp_bits_stage1_pteidx_6, i_io_resp_bits_stage1_pteidx_6);
    chk("io_resp_bits_stage1_pteidx_7", g_io_resp_bits_stage1_pteidx_7, i_io_resp_bits_stage1_pteidx_7);
    chk("io_resp_bits_stage1_not_super", g_io_resp_bits_stage1_not_super, i_io_resp_bits_stage1_not_super);
    chk("io_resp_bits_isHptwReq", g_io_resp_bits_isHptwReq, i_io_resp_bits_isHptwReq);
    chk("io_resp_bits_toHptw_l3Hit", g_io_resp_bits_toHptw_l3Hit, i_io_resp_bits_toHptw_l3Hit);
    chk("io_resp_bits_toHptw_l2Hit", g_io_resp_bits_toHptw_l2Hit, i_io_resp_bits_toHptw_l2Hit);
    chk("io_resp_bits_toHptw_l1Hit", g_io_resp_bits_toHptw_l1Hit, i_io_resp_bits_toHptw_l1Hit);
    chk("io_resp_bits_toHptw_ppn", g_io_resp_bits_toHptw_ppn, i_io_resp_bits_toHptw_ppn);
    chk("io_resp_bits_toHptw_id", g_io_resp_bits_toHptw_id, i_io_resp_bits_toHptw_id);
    chk("io_resp_bits_toHptw_resp_entry_tag", g_io_resp_bits_toHptw_resp_entry_tag, i_io_resp_bits_toHptw_resp_entry_tag);
    chk("io_resp_bits_toHptw_resp_entry_vmid", g_io_resp_bits_toHptw_resp_entry_vmid, i_io_resp_bits_toHptw_resp_entry_vmid);
    chk("io_resp_bits_toHptw_resp_entry_n", g_io_resp_bits_toHptw_resp_entry_n, i_io_resp_bits_toHptw_resp_entry_n);
    chk("io_resp_bits_toHptw_resp_entry_pbmt", g_io_resp_bits_toHptw_resp_entry_pbmt, i_io_resp_bits_toHptw_resp_entry_pbmt);
    chk("io_resp_bits_toHptw_resp_entry_ppn", g_io_resp_bits_toHptw_resp_entry_ppn, i_io_resp_bits_toHptw_resp_entry_ppn);
    chk("io_resp_bits_toHptw_resp_entry_perm_d", g_io_resp_bits_toHptw_resp_entry_perm_d, i_io_resp_bits_toHptw_resp_entry_perm_d);
    chk("io_resp_bits_toHptw_resp_entry_perm_a", g_io_resp_bits_toHptw_resp_entry_perm_a, i_io_resp_bits_toHptw_resp_entry_perm_a);
    chk("io_resp_bits_toHptw_resp_entry_perm_g", g_io_resp_bits_toHptw_resp_entry_perm_g, i_io_resp_bits_toHptw_resp_entry_perm_g);
    chk("io_resp_bits_toHptw_resp_entry_perm_u", g_io_resp_bits_toHptw_resp_entry_perm_u, i_io_resp_bits_toHptw_resp_entry_perm_u);
    chk("io_resp_bits_toHptw_resp_entry_perm_x", g_io_resp_bits_toHptw_resp_entry_perm_x, i_io_resp_bits_toHptw_resp_entry_perm_x);
    chk("io_resp_bits_toHptw_resp_entry_perm_w", g_io_resp_bits_toHptw_resp_entry_perm_w, i_io_resp_bits_toHptw_resp_entry_perm_w);
    chk("io_resp_bits_toHptw_resp_entry_perm_r", g_io_resp_bits_toHptw_resp_entry_perm_r, i_io_resp_bits_toHptw_resp_entry_perm_r);
    chk("io_resp_bits_toHptw_resp_entry_level", g_io_resp_bits_toHptw_resp_entry_level, i_io_resp_bits_toHptw_resp_entry_level);
    chk("io_resp_bits_toHptw_resp_gpf", g_io_resp_bits_toHptw_resp_gpf, i_io_resp_bits_toHptw_resp_gpf);
    chk("io_resp_bits_toHptw_bypassed", g_io_resp_bits_toHptw_bypassed, i_io_resp_bits_toHptw_bypassed);
    chk("io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check", g_io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check, i_io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check);
    chk("io_resp_bits_toHptw_bitmapCheck_hitway", g_io_resp_bits_toHptw_bitmapCheck_hitway, i_io_resp_bits_toHptw_bitmapCheck_hitway);
    chk("io_resp_bits_toHptw_bitmapCheck_pte", g_io_resp_bits_toHptw_bitmapCheck_pte, i_io_resp_bits_toHptw_bitmapCheck_pte);
    chk("io_resp_bits_toHptw_bitmapCheck_ptes_0", g_io_resp_bits_toHptw_bitmapCheck_ptes_0, i_io_resp_bits_toHptw_bitmapCheck_ptes_0);
    chk("io_resp_bits_toHptw_bitmapCheck_ptes_1", g_io_resp_bits_toHptw_bitmapCheck_ptes_1, i_io_resp_bits_toHptw_bitmapCheck_ptes_1);
    chk("io_resp_bits_toHptw_bitmapCheck_ptes_2", g_io_resp_bits_toHptw_bitmapCheck_ptes_2, i_io_resp_bits_toHptw_bitmapCheck_ptes_2);
    chk("io_resp_bits_toHptw_bitmapCheck_ptes_3", g_io_resp_bits_toHptw_bitmapCheck_ptes_3, i_io_resp_bits_toHptw_bitmapCheck_ptes_3);
    chk("io_resp_bits_toHptw_bitmapCheck_ptes_4", g_io_resp_bits_toHptw_bitmapCheck_ptes_4, i_io_resp_bits_toHptw_bitmapCheck_ptes_4);
    chk("io_resp_bits_toHptw_bitmapCheck_ptes_5", g_io_resp_bits_toHptw_bitmapCheck_ptes_5, i_io_resp_bits_toHptw_bitmapCheck_ptes_5);
    chk("io_resp_bits_toHptw_bitmapCheck_ptes_6", g_io_resp_bits_toHptw_bitmapCheck_ptes_6, i_io_resp_bits_toHptw_bitmapCheck_ptes_6);
    chk("io_resp_bits_toHptw_bitmapCheck_ptes_7", g_io_resp_bits_toHptw_bitmapCheck_ptes_7, i_io_resp_bits_toHptw_bitmapCheck_ptes_7);
    chk("io_resp_bits_toHptw_bitmapCheck_fromSP", g_io_resp_bits_toHptw_bitmapCheck_fromSP, i_io_resp_bits_toHptw_bitmapCheck_fromSP);
    chk("io_resp_bits_toHptw_bitmapCheck_SPlevel", g_io_resp_bits_toHptw_bitmapCheck_SPlevel, i_io_resp_bits_toHptw_bitmapCheck_SPlevel);
    chk("io_l0_way_info", g_io_l0_way_info, i_io_l0_way_info);
    chk("io_bitmap_wakeup_ready", g_io_bitmap_wakeup_ready, i_io_bitmap_wakeup_ready);
    chk("io_perf_0_value", g_io_perf_0_value, i_io_perf_0_value);
    chk("io_perf_1_value", g_io_perf_1_value, i_io_perf_1_value);
    chk("io_perf_2_value", g_io_perf_2_value, i_io_perf_2_value);
    chk("io_perf_3_value", g_io_perf_3_value, i_io_perf_3_value);
    chk("io_perf_4_value", g_io_perf_4_value, i_io_perf_4_value);
    chk("io_perf_5_value", g_io_perf_5_value, i_io_perf_5_value);
    chk("io_perf_6_value", g_io_perf_6_value, i_io_perf_6_value);
    chk("io_perf_7_value", g_io_perf_7_value, i_io_perf_7_value);
    chk("boreChildrenBd_bore_ack", g_boreChildrenBd_bore_ack, i_boreChildrenBd_bore_ack);
    chk("boreChildrenBd_bore_outdata", g_boreChildrenBd_bore_outdata, i_boreChildrenBd_bore_outdata);
    chk("boreChildrenBd_bore_1_ack", g_boreChildrenBd_bore_1_ack, i_boreChildrenBd_bore_1_ack);
    chk("boreChildrenBd_bore_1_outdata", g_boreChildrenBd_bore_1_outdata, i_boreChildrenBd_bore_1_outdata);
  endtask
  // END GENERATED(port_cmp)

  task automatic compare_write_ports();
    chk("l1.io_w_req_valid", dut_g.l1.io_w_req_valid, dut_i.u_core.u_l1_sram.io_w_req_valid);
    chk("l1.io_w_req_bits_setIdx", dut_g.l1.io_w_req_bits_setIdx, dut_i.u_core.u_l1_sram.io_w_req_bits_setIdx);
    chk("l1.io_w_req_bits_data_0_entries_tag", dut_g.l1.io_w_req_bits_data_0_entries_tag, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_tag);
    chk("l1.io_w_req_bits_data_0_entries_asid", dut_g.l1.io_w_req_bits_data_0_entries_asid, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_asid);
    chk("l1.io_w_req_bits_data_0_entries_vmid", dut_g.l1.io_w_req_bits_data_0_entries_vmid, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vmid);
    chk("l1.io_w_req_bits_data_0_entries_pbmts_0", dut_g.l1.io_w_req_bits_data_0_entries_pbmts_0, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_pbmts_0);
    chk("l1.io_w_req_bits_data_0_entries_pbmts_1", dut_g.l1.io_w_req_bits_data_0_entries_pbmts_1, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_pbmts_1);
    chk("l1.io_w_req_bits_data_0_entries_pbmts_2", dut_g.l1.io_w_req_bits_data_0_entries_pbmts_2, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_pbmts_2);
    chk("l1.io_w_req_bits_data_0_entries_pbmts_3", dut_g.l1.io_w_req_bits_data_0_entries_pbmts_3, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_pbmts_3);
    chk("l1.io_w_req_bits_data_0_entries_pbmts_4", dut_g.l1.io_w_req_bits_data_0_entries_pbmts_4, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_pbmts_4);
    chk("l1.io_w_req_bits_data_0_entries_pbmts_5", dut_g.l1.io_w_req_bits_data_0_entries_pbmts_5, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_pbmts_5);
    chk("l1.io_w_req_bits_data_0_entries_pbmts_6", dut_g.l1.io_w_req_bits_data_0_entries_pbmts_6, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_pbmts_6);
    chk("l1.io_w_req_bits_data_0_entries_pbmts_7", dut_g.l1.io_w_req_bits_data_0_entries_pbmts_7, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_pbmts_7);
    chk("l1.io_w_req_bits_data_0_entries_ppns_0", dut_g.l1.io_w_req_bits_data_0_entries_ppns_0, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_ppns_0);
    chk("l1.io_w_req_bits_data_0_entries_ppns_1", dut_g.l1.io_w_req_bits_data_0_entries_ppns_1, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_ppns_1);
    chk("l1.io_w_req_bits_data_0_entries_ppns_2", dut_g.l1.io_w_req_bits_data_0_entries_ppns_2, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_ppns_2);
    chk("l1.io_w_req_bits_data_0_entries_ppns_3", dut_g.l1.io_w_req_bits_data_0_entries_ppns_3, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_ppns_3);
    chk("l1.io_w_req_bits_data_0_entries_ppns_4", dut_g.l1.io_w_req_bits_data_0_entries_ppns_4, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_ppns_4);
    chk("l1.io_w_req_bits_data_0_entries_ppns_5", dut_g.l1.io_w_req_bits_data_0_entries_ppns_5, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_ppns_5);
    chk("l1.io_w_req_bits_data_0_entries_ppns_6", dut_g.l1.io_w_req_bits_data_0_entries_ppns_6, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_ppns_6);
    chk("l1.io_w_req_bits_data_0_entries_ppns_7", dut_g.l1.io_w_req_bits_data_0_entries_ppns_7, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_ppns_7);
    chk("l1.io_w_req_bits_data_0_entries_vs_0", dut_g.l1.io_w_req_bits_data_0_entries_vs_0, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vs_0);
    chk("l1.io_w_req_bits_data_0_entries_vs_1", dut_g.l1.io_w_req_bits_data_0_entries_vs_1, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vs_1);
    chk("l1.io_w_req_bits_data_0_entries_vs_2", dut_g.l1.io_w_req_bits_data_0_entries_vs_2, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vs_2);
    chk("l1.io_w_req_bits_data_0_entries_vs_3", dut_g.l1.io_w_req_bits_data_0_entries_vs_3, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vs_3);
    chk("l1.io_w_req_bits_data_0_entries_vs_4", dut_g.l1.io_w_req_bits_data_0_entries_vs_4, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vs_4);
    chk("l1.io_w_req_bits_data_0_entries_vs_5", dut_g.l1.io_w_req_bits_data_0_entries_vs_5, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vs_5);
    chk("l1.io_w_req_bits_data_0_entries_vs_6", dut_g.l1.io_w_req_bits_data_0_entries_vs_6, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vs_6);
    chk("l1.io_w_req_bits_data_0_entries_vs_7", dut_g.l1.io_w_req_bits_data_0_entries_vs_7, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_vs_7);
    chk("l1.io_w_req_bits_data_0_entries_prefetch", dut_g.l1.io_w_req_bits_data_0_entries_prefetch, dut_i.u_core.u_l1_sram.io_w_req_bits_data_0_entries_prefetch);
    chk("l1.io_w_req_bits_data_1_entries_tag", dut_g.l1.io_w_req_bits_data_1_entries_tag, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_tag);
    chk("l1.io_w_req_bits_data_1_entries_asid", dut_g.l1.io_w_req_bits_data_1_entries_asid, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_asid);
    chk("l1.io_w_req_bits_data_1_entries_vmid", dut_g.l1.io_w_req_bits_data_1_entries_vmid, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vmid);
    chk("l1.io_w_req_bits_data_1_entries_pbmts_0", dut_g.l1.io_w_req_bits_data_1_entries_pbmts_0, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_pbmts_0);
    chk("l1.io_w_req_bits_data_1_entries_pbmts_1", dut_g.l1.io_w_req_bits_data_1_entries_pbmts_1, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_pbmts_1);
    chk("l1.io_w_req_bits_data_1_entries_pbmts_2", dut_g.l1.io_w_req_bits_data_1_entries_pbmts_2, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_pbmts_2);
    chk("l1.io_w_req_bits_data_1_entries_pbmts_3", dut_g.l1.io_w_req_bits_data_1_entries_pbmts_3, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_pbmts_3);
    chk("l1.io_w_req_bits_data_1_entries_pbmts_4", dut_g.l1.io_w_req_bits_data_1_entries_pbmts_4, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_pbmts_4);
    chk("l1.io_w_req_bits_data_1_entries_pbmts_5", dut_g.l1.io_w_req_bits_data_1_entries_pbmts_5, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_pbmts_5);
    chk("l1.io_w_req_bits_data_1_entries_pbmts_6", dut_g.l1.io_w_req_bits_data_1_entries_pbmts_6, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_pbmts_6);
    chk("l1.io_w_req_bits_data_1_entries_pbmts_7", dut_g.l1.io_w_req_bits_data_1_entries_pbmts_7, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_pbmts_7);
    chk("l1.io_w_req_bits_data_1_entries_ppns_0", dut_g.l1.io_w_req_bits_data_1_entries_ppns_0, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_ppns_0);
    chk("l1.io_w_req_bits_data_1_entries_ppns_1", dut_g.l1.io_w_req_bits_data_1_entries_ppns_1, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_ppns_1);
    chk("l1.io_w_req_bits_data_1_entries_ppns_2", dut_g.l1.io_w_req_bits_data_1_entries_ppns_2, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_ppns_2);
    chk("l1.io_w_req_bits_data_1_entries_ppns_3", dut_g.l1.io_w_req_bits_data_1_entries_ppns_3, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_ppns_3);
    chk("l1.io_w_req_bits_data_1_entries_ppns_4", dut_g.l1.io_w_req_bits_data_1_entries_ppns_4, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_ppns_4);
    chk("l1.io_w_req_bits_data_1_entries_ppns_5", dut_g.l1.io_w_req_bits_data_1_entries_ppns_5, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_ppns_5);
    chk("l1.io_w_req_bits_data_1_entries_ppns_6", dut_g.l1.io_w_req_bits_data_1_entries_ppns_6, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_ppns_6);
    chk("l1.io_w_req_bits_data_1_entries_ppns_7", dut_g.l1.io_w_req_bits_data_1_entries_ppns_7, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_ppns_7);
    chk("l1.io_w_req_bits_data_1_entries_vs_0", dut_g.l1.io_w_req_bits_data_1_entries_vs_0, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vs_0);
    chk("l1.io_w_req_bits_data_1_entries_vs_1", dut_g.l1.io_w_req_bits_data_1_entries_vs_1, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vs_1);
    chk("l1.io_w_req_bits_data_1_entries_vs_2", dut_g.l1.io_w_req_bits_data_1_entries_vs_2, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vs_2);
    chk("l1.io_w_req_bits_data_1_entries_vs_3", dut_g.l1.io_w_req_bits_data_1_entries_vs_3, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vs_3);
    chk("l1.io_w_req_bits_data_1_entries_vs_4", dut_g.l1.io_w_req_bits_data_1_entries_vs_4, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vs_4);
    chk("l1.io_w_req_bits_data_1_entries_vs_5", dut_g.l1.io_w_req_bits_data_1_entries_vs_5, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vs_5);
    chk("l1.io_w_req_bits_data_1_entries_vs_6", dut_g.l1.io_w_req_bits_data_1_entries_vs_6, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vs_6);
    chk("l1.io_w_req_bits_data_1_entries_vs_7", dut_g.l1.io_w_req_bits_data_1_entries_vs_7, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_vs_7);
    chk("l1.io_w_req_bits_data_1_entries_prefetch", dut_g.l1.io_w_req_bits_data_1_entries_prefetch, dut_i.u_core.u_l1_sram.io_w_req_bits_data_1_entries_prefetch);
    chk("l1.io_w_req_bits_waymask", dut_g.l1.io_w_req_bits_waymask, dut_i.u_core.u_l1_sram.io_w_req_bits_waymask);
    chk("l0.io_w_req_valid", dut_g.l0.io_w_req_valid, dut_i.u_core.u_l0_sram.io_w_req_valid);
    chk("l0.io_w_req_bits_setIdx", dut_g.l0.io_w_req_bits_setIdx, dut_i.u_core.u_l0_sram.io_w_req_bits_setIdx);
    chk("l0.io_w_req_bits_data_0_entries_tag", dut_g.l0.io_w_req_bits_data_0_entries_tag, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_tag);
    chk("l0.io_w_req_bits_data_0_entries_asid", dut_g.l0.io_w_req_bits_data_0_entries_asid, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_asid);
    chk("l0.io_w_req_bits_data_0_entries_vmid", dut_g.l0.io_w_req_bits_data_0_entries_vmid, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vmid);
    chk("l0.io_w_req_bits_data_0_entries_pbmts_0", dut_g.l0.io_w_req_bits_data_0_entries_pbmts_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_pbmts_0);
    chk("l0.io_w_req_bits_data_0_entries_pbmts_1", dut_g.l0.io_w_req_bits_data_0_entries_pbmts_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_pbmts_1);
    chk("l0.io_w_req_bits_data_0_entries_pbmts_2", dut_g.l0.io_w_req_bits_data_0_entries_pbmts_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_pbmts_2);
    chk("l0.io_w_req_bits_data_0_entries_pbmts_3", dut_g.l0.io_w_req_bits_data_0_entries_pbmts_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_pbmts_3);
    chk("l0.io_w_req_bits_data_0_entries_pbmts_4", dut_g.l0.io_w_req_bits_data_0_entries_pbmts_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_pbmts_4);
    chk("l0.io_w_req_bits_data_0_entries_pbmts_5", dut_g.l0.io_w_req_bits_data_0_entries_pbmts_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_pbmts_5);
    chk("l0.io_w_req_bits_data_0_entries_pbmts_6", dut_g.l0.io_w_req_bits_data_0_entries_pbmts_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_pbmts_6);
    chk("l0.io_w_req_bits_data_0_entries_pbmts_7", dut_g.l0.io_w_req_bits_data_0_entries_pbmts_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_pbmts_7);
    chk("l0.io_w_req_bits_data_0_entries_ppns_0", dut_g.l0.io_w_req_bits_data_0_entries_ppns_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_ppns_0);
    chk("l0.io_w_req_bits_data_0_entries_ppns_1", dut_g.l0.io_w_req_bits_data_0_entries_ppns_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_ppns_1);
    chk("l0.io_w_req_bits_data_0_entries_ppns_2", dut_g.l0.io_w_req_bits_data_0_entries_ppns_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_ppns_2);
    chk("l0.io_w_req_bits_data_0_entries_ppns_3", dut_g.l0.io_w_req_bits_data_0_entries_ppns_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_ppns_3);
    chk("l0.io_w_req_bits_data_0_entries_ppns_4", dut_g.l0.io_w_req_bits_data_0_entries_ppns_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_ppns_4);
    chk("l0.io_w_req_bits_data_0_entries_ppns_5", dut_g.l0.io_w_req_bits_data_0_entries_ppns_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_ppns_5);
    chk("l0.io_w_req_bits_data_0_entries_ppns_6", dut_g.l0.io_w_req_bits_data_0_entries_ppns_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_ppns_6);
    chk("l0.io_w_req_bits_data_0_entries_ppns_7", dut_g.l0.io_w_req_bits_data_0_entries_ppns_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_ppns_7);
    chk("l0.io_w_req_bits_data_0_entries_vs_0", dut_g.l0.io_w_req_bits_data_0_entries_vs_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vs_0);
    chk("l0.io_w_req_bits_data_0_entries_vs_1", dut_g.l0.io_w_req_bits_data_0_entries_vs_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vs_1);
    chk("l0.io_w_req_bits_data_0_entries_vs_2", dut_g.l0.io_w_req_bits_data_0_entries_vs_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vs_2);
    chk("l0.io_w_req_bits_data_0_entries_vs_3", dut_g.l0.io_w_req_bits_data_0_entries_vs_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vs_3);
    chk("l0.io_w_req_bits_data_0_entries_vs_4", dut_g.l0.io_w_req_bits_data_0_entries_vs_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vs_4);
    chk("l0.io_w_req_bits_data_0_entries_vs_5", dut_g.l0.io_w_req_bits_data_0_entries_vs_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vs_5);
    chk("l0.io_w_req_bits_data_0_entries_vs_6", dut_g.l0.io_w_req_bits_data_0_entries_vs_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vs_6);
    chk("l0.io_w_req_bits_data_0_entries_vs_7", dut_g.l0.io_w_req_bits_data_0_entries_vs_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_vs_7);
    chk("l0.io_w_req_bits_data_0_entries_onlypf_0", dut_g.l0.io_w_req_bits_data_0_entries_onlypf_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_onlypf_0);
    chk("l0.io_w_req_bits_data_0_entries_onlypf_1", dut_g.l0.io_w_req_bits_data_0_entries_onlypf_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_onlypf_1);
    chk("l0.io_w_req_bits_data_0_entries_onlypf_2", dut_g.l0.io_w_req_bits_data_0_entries_onlypf_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_onlypf_2);
    chk("l0.io_w_req_bits_data_0_entries_onlypf_3", dut_g.l0.io_w_req_bits_data_0_entries_onlypf_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_onlypf_3);
    chk("l0.io_w_req_bits_data_0_entries_onlypf_4", dut_g.l0.io_w_req_bits_data_0_entries_onlypf_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_onlypf_4);
    chk("l0.io_w_req_bits_data_0_entries_onlypf_5", dut_g.l0.io_w_req_bits_data_0_entries_onlypf_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_onlypf_5);
    chk("l0.io_w_req_bits_data_0_entries_onlypf_6", dut_g.l0.io_w_req_bits_data_0_entries_onlypf_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_onlypf_6);
    chk("l0.io_w_req_bits_data_0_entries_onlypf_7", dut_g.l0.io_w_req_bits_data_0_entries_onlypf_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_onlypf_7);
    chk("l0.io_w_req_bits_data_0_entries_perms_0_d", dut_g.l0.io_w_req_bits_data_0_entries_perms_0_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_0_d);
    chk("l0.io_w_req_bits_data_0_entries_perms_0_a", dut_g.l0.io_w_req_bits_data_0_entries_perms_0_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_0_a);
    chk("l0.io_w_req_bits_data_0_entries_perms_0_g", dut_g.l0.io_w_req_bits_data_0_entries_perms_0_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_0_g);
    chk("l0.io_w_req_bits_data_0_entries_perms_0_u", dut_g.l0.io_w_req_bits_data_0_entries_perms_0_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_0_u);
    chk("l0.io_w_req_bits_data_0_entries_perms_0_x", dut_g.l0.io_w_req_bits_data_0_entries_perms_0_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_0_x);
    chk("l0.io_w_req_bits_data_0_entries_perms_0_w", dut_g.l0.io_w_req_bits_data_0_entries_perms_0_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_0_w);
    chk("l0.io_w_req_bits_data_0_entries_perms_0_r", dut_g.l0.io_w_req_bits_data_0_entries_perms_0_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_0_r);
    chk("l0.io_w_req_bits_data_0_entries_perms_1_d", dut_g.l0.io_w_req_bits_data_0_entries_perms_1_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_1_d);
    chk("l0.io_w_req_bits_data_0_entries_perms_1_a", dut_g.l0.io_w_req_bits_data_0_entries_perms_1_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_1_a);
    chk("l0.io_w_req_bits_data_0_entries_perms_1_g", dut_g.l0.io_w_req_bits_data_0_entries_perms_1_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_1_g);
    chk("l0.io_w_req_bits_data_0_entries_perms_1_u", dut_g.l0.io_w_req_bits_data_0_entries_perms_1_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_1_u);
    chk("l0.io_w_req_bits_data_0_entries_perms_1_x", dut_g.l0.io_w_req_bits_data_0_entries_perms_1_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_1_x);
    chk("l0.io_w_req_bits_data_0_entries_perms_1_w", dut_g.l0.io_w_req_bits_data_0_entries_perms_1_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_1_w);
    chk("l0.io_w_req_bits_data_0_entries_perms_1_r", dut_g.l0.io_w_req_bits_data_0_entries_perms_1_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_1_r);
    chk("l0.io_w_req_bits_data_0_entries_perms_2_d", dut_g.l0.io_w_req_bits_data_0_entries_perms_2_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_2_d);
    chk("l0.io_w_req_bits_data_0_entries_perms_2_a", dut_g.l0.io_w_req_bits_data_0_entries_perms_2_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_2_a);
    chk("l0.io_w_req_bits_data_0_entries_perms_2_g", dut_g.l0.io_w_req_bits_data_0_entries_perms_2_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_2_g);
    chk("l0.io_w_req_bits_data_0_entries_perms_2_u", dut_g.l0.io_w_req_bits_data_0_entries_perms_2_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_2_u);
    chk("l0.io_w_req_bits_data_0_entries_perms_2_x", dut_g.l0.io_w_req_bits_data_0_entries_perms_2_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_2_x);
    chk("l0.io_w_req_bits_data_0_entries_perms_2_w", dut_g.l0.io_w_req_bits_data_0_entries_perms_2_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_2_w);
    chk("l0.io_w_req_bits_data_0_entries_perms_2_r", dut_g.l0.io_w_req_bits_data_0_entries_perms_2_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_2_r);
    chk("l0.io_w_req_bits_data_0_entries_perms_3_d", dut_g.l0.io_w_req_bits_data_0_entries_perms_3_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_3_d);
    chk("l0.io_w_req_bits_data_0_entries_perms_3_a", dut_g.l0.io_w_req_bits_data_0_entries_perms_3_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_3_a);
    chk("l0.io_w_req_bits_data_0_entries_perms_3_g", dut_g.l0.io_w_req_bits_data_0_entries_perms_3_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_3_g);
    chk("l0.io_w_req_bits_data_0_entries_perms_3_u", dut_g.l0.io_w_req_bits_data_0_entries_perms_3_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_3_u);
    chk("l0.io_w_req_bits_data_0_entries_perms_3_x", dut_g.l0.io_w_req_bits_data_0_entries_perms_3_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_3_x);
    chk("l0.io_w_req_bits_data_0_entries_perms_3_w", dut_g.l0.io_w_req_bits_data_0_entries_perms_3_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_3_w);
    chk("l0.io_w_req_bits_data_0_entries_perms_3_r", dut_g.l0.io_w_req_bits_data_0_entries_perms_3_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_3_r);
    chk("l0.io_w_req_bits_data_0_entries_perms_4_d", dut_g.l0.io_w_req_bits_data_0_entries_perms_4_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_4_d);
    chk("l0.io_w_req_bits_data_0_entries_perms_4_a", dut_g.l0.io_w_req_bits_data_0_entries_perms_4_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_4_a);
    chk("l0.io_w_req_bits_data_0_entries_perms_4_g", dut_g.l0.io_w_req_bits_data_0_entries_perms_4_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_4_g);
    chk("l0.io_w_req_bits_data_0_entries_perms_4_u", dut_g.l0.io_w_req_bits_data_0_entries_perms_4_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_4_u);
    chk("l0.io_w_req_bits_data_0_entries_perms_4_x", dut_g.l0.io_w_req_bits_data_0_entries_perms_4_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_4_x);
    chk("l0.io_w_req_bits_data_0_entries_perms_4_w", dut_g.l0.io_w_req_bits_data_0_entries_perms_4_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_4_w);
    chk("l0.io_w_req_bits_data_0_entries_perms_4_r", dut_g.l0.io_w_req_bits_data_0_entries_perms_4_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_4_r);
    chk("l0.io_w_req_bits_data_0_entries_perms_5_d", dut_g.l0.io_w_req_bits_data_0_entries_perms_5_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_5_d);
    chk("l0.io_w_req_bits_data_0_entries_perms_5_a", dut_g.l0.io_w_req_bits_data_0_entries_perms_5_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_5_a);
    chk("l0.io_w_req_bits_data_0_entries_perms_5_g", dut_g.l0.io_w_req_bits_data_0_entries_perms_5_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_5_g);
    chk("l0.io_w_req_bits_data_0_entries_perms_5_u", dut_g.l0.io_w_req_bits_data_0_entries_perms_5_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_5_u);
    chk("l0.io_w_req_bits_data_0_entries_perms_5_x", dut_g.l0.io_w_req_bits_data_0_entries_perms_5_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_5_x);
    chk("l0.io_w_req_bits_data_0_entries_perms_5_w", dut_g.l0.io_w_req_bits_data_0_entries_perms_5_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_5_w);
    chk("l0.io_w_req_bits_data_0_entries_perms_5_r", dut_g.l0.io_w_req_bits_data_0_entries_perms_5_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_5_r);
    chk("l0.io_w_req_bits_data_0_entries_perms_6_d", dut_g.l0.io_w_req_bits_data_0_entries_perms_6_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_6_d);
    chk("l0.io_w_req_bits_data_0_entries_perms_6_a", dut_g.l0.io_w_req_bits_data_0_entries_perms_6_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_6_a);
    chk("l0.io_w_req_bits_data_0_entries_perms_6_g", dut_g.l0.io_w_req_bits_data_0_entries_perms_6_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_6_g);
    chk("l0.io_w_req_bits_data_0_entries_perms_6_u", dut_g.l0.io_w_req_bits_data_0_entries_perms_6_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_6_u);
    chk("l0.io_w_req_bits_data_0_entries_perms_6_x", dut_g.l0.io_w_req_bits_data_0_entries_perms_6_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_6_x);
    chk("l0.io_w_req_bits_data_0_entries_perms_6_w", dut_g.l0.io_w_req_bits_data_0_entries_perms_6_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_6_w);
    chk("l0.io_w_req_bits_data_0_entries_perms_6_r", dut_g.l0.io_w_req_bits_data_0_entries_perms_6_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_6_r);
    chk("l0.io_w_req_bits_data_0_entries_perms_7_d", dut_g.l0.io_w_req_bits_data_0_entries_perms_7_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_7_d);
    chk("l0.io_w_req_bits_data_0_entries_perms_7_a", dut_g.l0.io_w_req_bits_data_0_entries_perms_7_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_7_a);
    chk("l0.io_w_req_bits_data_0_entries_perms_7_g", dut_g.l0.io_w_req_bits_data_0_entries_perms_7_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_7_g);
    chk("l0.io_w_req_bits_data_0_entries_perms_7_u", dut_g.l0.io_w_req_bits_data_0_entries_perms_7_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_7_u);
    chk("l0.io_w_req_bits_data_0_entries_perms_7_x", dut_g.l0.io_w_req_bits_data_0_entries_perms_7_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_7_x);
    chk("l0.io_w_req_bits_data_0_entries_perms_7_w", dut_g.l0.io_w_req_bits_data_0_entries_perms_7_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_7_w);
    chk("l0.io_w_req_bits_data_0_entries_perms_7_r", dut_g.l0.io_w_req_bits_data_0_entries_perms_7_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_perms_7_r);
    chk("l0.io_w_req_bits_data_0_entries_prefetch", dut_g.l0.io_w_req_bits_data_0_entries_prefetch, dut_i.u_core.u_l0_sram.io_w_req_bits_data_0_entries_prefetch);
    chk("l0.io_w_req_bits_data_1_entries_tag", dut_g.l0.io_w_req_bits_data_1_entries_tag, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_tag);
    chk("l0.io_w_req_bits_data_1_entries_asid", dut_g.l0.io_w_req_bits_data_1_entries_asid, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_asid);
    chk("l0.io_w_req_bits_data_1_entries_vmid", dut_g.l0.io_w_req_bits_data_1_entries_vmid, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vmid);
    chk("l0.io_w_req_bits_data_1_entries_pbmts_0", dut_g.l0.io_w_req_bits_data_1_entries_pbmts_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_pbmts_0);
    chk("l0.io_w_req_bits_data_1_entries_pbmts_1", dut_g.l0.io_w_req_bits_data_1_entries_pbmts_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_pbmts_1);
    chk("l0.io_w_req_bits_data_1_entries_pbmts_2", dut_g.l0.io_w_req_bits_data_1_entries_pbmts_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_pbmts_2);
    chk("l0.io_w_req_bits_data_1_entries_pbmts_3", dut_g.l0.io_w_req_bits_data_1_entries_pbmts_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_pbmts_3);
    chk("l0.io_w_req_bits_data_1_entries_pbmts_4", dut_g.l0.io_w_req_bits_data_1_entries_pbmts_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_pbmts_4);
    chk("l0.io_w_req_bits_data_1_entries_pbmts_5", dut_g.l0.io_w_req_bits_data_1_entries_pbmts_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_pbmts_5);
    chk("l0.io_w_req_bits_data_1_entries_pbmts_6", dut_g.l0.io_w_req_bits_data_1_entries_pbmts_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_pbmts_6);
    chk("l0.io_w_req_bits_data_1_entries_pbmts_7", dut_g.l0.io_w_req_bits_data_1_entries_pbmts_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_pbmts_7);
    chk("l0.io_w_req_bits_data_1_entries_ppns_0", dut_g.l0.io_w_req_bits_data_1_entries_ppns_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_ppns_0);
    chk("l0.io_w_req_bits_data_1_entries_ppns_1", dut_g.l0.io_w_req_bits_data_1_entries_ppns_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_ppns_1);
    chk("l0.io_w_req_bits_data_1_entries_ppns_2", dut_g.l0.io_w_req_bits_data_1_entries_ppns_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_ppns_2);
    chk("l0.io_w_req_bits_data_1_entries_ppns_3", dut_g.l0.io_w_req_bits_data_1_entries_ppns_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_ppns_3);
    chk("l0.io_w_req_bits_data_1_entries_ppns_4", dut_g.l0.io_w_req_bits_data_1_entries_ppns_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_ppns_4);
    chk("l0.io_w_req_bits_data_1_entries_ppns_5", dut_g.l0.io_w_req_bits_data_1_entries_ppns_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_ppns_5);
    chk("l0.io_w_req_bits_data_1_entries_ppns_6", dut_g.l0.io_w_req_bits_data_1_entries_ppns_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_ppns_6);
    chk("l0.io_w_req_bits_data_1_entries_ppns_7", dut_g.l0.io_w_req_bits_data_1_entries_ppns_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_ppns_7);
    chk("l0.io_w_req_bits_data_1_entries_vs_0", dut_g.l0.io_w_req_bits_data_1_entries_vs_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vs_0);
    chk("l0.io_w_req_bits_data_1_entries_vs_1", dut_g.l0.io_w_req_bits_data_1_entries_vs_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vs_1);
    chk("l0.io_w_req_bits_data_1_entries_vs_2", dut_g.l0.io_w_req_bits_data_1_entries_vs_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vs_2);
    chk("l0.io_w_req_bits_data_1_entries_vs_3", dut_g.l0.io_w_req_bits_data_1_entries_vs_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vs_3);
    chk("l0.io_w_req_bits_data_1_entries_vs_4", dut_g.l0.io_w_req_bits_data_1_entries_vs_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vs_4);
    chk("l0.io_w_req_bits_data_1_entries_vs_5", dut_g.l0.io_w_req_bits_data_1_entries_vs_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vs_5);
    chk("l0.io_w_req_bits_data_1_entries_vs_6", dut_g.l0.io_w_req_bits_data_1_entries_vs_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vs_6);
    chk("l0.io_w_req_bits_data_1_entries_vs_7", dut_g.l0.io_w_req_bits_data_1_entries_vs_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_vs_7);
    chk("l0.io_w_req_bits_data_1_entries_onlypf_0", dut_g.l0.io_w_req_bits_data_1_entries_onlypf_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_onlypf_0);
    chk("l0.io_w_req_bits_data_1_entries_onlypf_1", dut_g.l0.io_w_req_bits_data_1_entries_onlypf_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_onlypf_1);
    chk("l0.io_w_req_bits_data_1_entries_onlypf_2", dut_g.l0.io_w_req_bits_data_1_entries_onlypf_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_onlypf_2);
    chk("l0.io_w_req_bits_data_1_entries_onlypf_3", dut_g.l0.io_w_req_bits_data_1_entries_onlypf_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_onlypf_3);
    chk("l0.io_w_req_bits_data_1_entries_onlypf_4", dut_g.l0.io_w_req_bits_data_1_entries_onlypf_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_onlypf_4);
    chk("l0.io_w_req_bits_data_1_entries_onlypf_5", dut_g.l0.io_w_req_bits_data_1_entries_onlypf_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_onlypf_5);
    chk("l0.io_w_req_bits_data_1_entries_onlypf_6", dut_g.l0.io_w_req_bits_data_1_entries_onlypf_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_onlypf_6);
    chk("l0.io_w_req_bits_data_1_entries_onlypf_7", dut_g.l0.io_w_req_bits_data_1_entries_onlypf_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_onlypf_7);
    chk("l0.io_w_req_bits_data_1_entries_perms_0_d", dut_g.l0.io_w_req_bits_data_1_entries_perms_0_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_0_d);
    chk("l0.io_w_req_bits_data_1_entries_perms_0_a", dut_g.l0.io_w_req_bits_data_1_entries_perms_0_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_0_a);
    chk("l0.io_w_req_bits_data_1_entries_perms_0_g", dut_g.l0.io_w_req_bits_data_1_entries_perms_0_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_0_g);
    chk("l0.io_w_req_bits_data_1_entries_perms_0_u", dut_g.l0.io_w_req_bits_data_1_entries_perms_0_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_0_u);
    chk("l0.io_w_req_bits_data_1_entries_perms_0_x", dut_g.l0.io_w_req_bits_data_1_entries_perms_0_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_0_x);
    chk("l0.io_w_req_bits_data_1_entries_perms_0_w", dut_g.l0.io_w_req_bits_data_1_entries_perms_0_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_0_w);
    chk("l0.io_w_req_bits_data_1_entries_perms_0_r", dut_g.l0.io_w_req_bits_data_1_entries_perms_0_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_0_r);
    chk("l0.io_w_req_bits_data_1_entries_perms_1_d", dut_g.l0.io_w_req_bits_data_1_entries_perms_1_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_1_d);
    chk("l0.io_w_req_bits_data_1_entries_perms_1_a", dut_g.l0.io_w_req_bits_data_1_entries_perms_1_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_1_a);
    chk("l0.io_w_req_bits_data_1_entries_perms_1_g", dut_g.l0.io_w_req_bits_data_1_entries_perms_1_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_1_g);
    chk("l0.io_w_req_bits_data_1_entries_perms_1_u", dut_g.l0.io_w_req_bits_data_1_entries_perms_1_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_1_u);
    chk("l0.io_w_req_bits_data_1_entries_perms_1_x", dut_g.l0.io_w_req_bits_data_1_entries_perms_1_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_1_x);
    chk("l0.io_w_req_bits_data_1_entries_perms_1_w", dut_g.l0.io_w_req_bits_data_1_entries_perms_1_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_1_w);
    chk("l0.io_w_req_bits_data_1_entries_perms_1_r", dut_g.l0.io_w_req_bits_data_1_entries_perms_1_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_1_r);
    chk("l0.io_w_req_bits_data_1_entries_perms_2_d", dut_g.l0.io_w_req_bits_data_1_entries_perms_2_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_2_d);
    chk("l0.io_w_req_bits_data_1_entries_perms_2_a", dut_g.l0.io_w_req_bits_data_1_entries_perms_2_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_2_a);
    chk("l0.io_w_req_bits_data_1_entries_perms_2_g", dut_g.l0.io_w_req_bits_data_1_entries_perms_2_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_2_g);
    chk("l0.io_w_req_bits_data_1_entries_perms_2_u", dut_g.l0.io_w_req_bits_data_1_entries_perms_2_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_2_u);
    chk("l0.io_w_req_bits_data_1_entries_perms_2_x", dut_g.l0.io_w_req_bits_data_1_entries_perms_2_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_2_x);
    chk("l0.io_w_req_bits_data_1_entries_perms_2_w", dut_g.l0.io_w_req_bits_data_1_entries_perms_2_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_2_w);
    chk("l0.io_w_req_bits_data_1_entries_perms_2_r", dut_g.l0.io_w_req_bits_data_1_entries_perms_2_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_2_r);
    chk("l0.io_w_req_bits_data_1_entries_perms_3_d", dut_g.l0.io_w_req_bits_data_1_entries_perms_3_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_3_d);
    chk("l0.io_w_req_bits_data_1_entries_perms_3_a", dut_g.l0.io_w_req_bits_data_1_entries_perms_3_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_3_a);
    chk("l0.io_w_req_bits_data_1_entries_perms_3_g", dut_g.l0.io_w_req_bits_data_1_entries_perms_3_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_3_g);
    chk("l0.io_w_req_bits_data_1_entries_perms_3_u", dut_g.l0.io_w_req_bits_data_1_entries_perms_3_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_3_u);
    chk("l0.io_w_req_bits_data_1_entries_perms_3_x", dut_g.l0.io_w_req_bits_data_1_entries_perms_3_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_3_x);
    chk("l0.io_w_req_bits_data_1_entries_perms_3_w", dut_g.l0.io_w_req_bits_data_1_entries_perms_3_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_3_w);
    chk("l0.io_w_req_bits_data_1_entries_perms_3_r", dut_g.l0.io_w_req_bits_data_1_entries_perms_3_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_3_r);
    chk("l0.io_w_req_bits_data_1_entries_perms_4_d", dut_g.l0.io_w_req_bits_data_1_entries_perms_4_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_4_d);
    chk("l0.io_w_req_bits_data_1_entries_perms_4_a", dut_g.l0.io_w_req_bits_data_1_entries_perms_4_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_4_a);
    chk("l0.io_w_req_bits_data_1_entries_perms_4_g", dut_g.l0.io_w_req_bits_data_1_entries_perms_4_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_4_g);
    chk("l0.io_w_req_bits_data_1_entries_perms_4_u", dut_g.l0.io_w_req_bits_data_1_entries_perms_4_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_4_u);
    chk("l0.io_w_req_bits_data_1_entries_perms_4_x", dut_g.l0.io_w_req_bits_data_1_entries_perms_4_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_4_x);
    chk("l0.io_w_req_bits_data_1_entries_perms_4_w", dut_g.l0.io_w_req_bits_data_1_entries_perms_4_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_4_w);
    chk("l0.io_w_req_bits_data_1_entries_perms_4_r", dut_g.l0.io_w_req_bits_data_1_entries_perms_4_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_4_r);
    chk("l0.io_w_req_bits_data_1_entries_perms_5_d", dut_g.l0.io_w_req_bits_data_1_entries_perms_5_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_5_d);
    chk("l0.io_w_req_bits_data_1_entries_perms_5_a", dut_g.l0.io_w_req_bits_data_1_entries_perms_5_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_5_a);
    chk("l0.io_w_req_bits_data_1_entries_perms_5_g", dut_g.l0.io_w_req_bits_data_1_entries_perms_5_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_5_g);
    chk("l0.io_w_req_bits_data_1_entries_perms_5_u", dut_g.l0.io_w_req_bits_data_1_entries_perms_5_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_5_u);
    chk("l0.io_w_req_bits_data_1_entries_perms_5_x", dut_g.l0.io_w_req_bits_data_1_entries_perms_5_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_5_x);
    chk("l0.io_w_req_bits_data_1_entries_perms_5_w", dut_g.l0.io_w_req_bits_data_1_entries_perms_5_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_5_w);
    chk("l0.io_w_req_bits_data_1_entries_perms_5_r", dut_g.l0.io_w_req_bits_data_1_entries_perms_5_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_5_r);
    chk("l0.io_w_req_bits_data_1_entries_perms_6_d", dut_g.l0.io_w_req_bits_data_1_entries_perms_6_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_6_d);
    chk("l0.io_w_req_bits_data_1_entries_perms_6_a", dut_g.l0.io_w_req_bits_data_1_entries_perms_6_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_6_a);
    chk("l0.io_w_req_bits_data_1_entries_perms_6_g", dut_g.l0.io_w_req_bits_data_1_entries_perms_6_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_6_g);
    chk("l0.io_w_req_bits_data_1_entries_perms_6_u", dut_g.l0.io_w_req_bits_data_1_entries_perms_6_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_6_u);
    chk("l0.io_w_req_bits_data_1_entries_perms_6_x", dut_g.l0.io_w_req_bits_data_1_entries_perms_6_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_6_x);
    chk("l0.io_w_req_bits_data_1_entries_perms_6_w", dut_g.l0.io_w_req_bits_data_1_entries_perms_6_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_6_w);
    chk("l0.io_w_req_bits_data_1_entries_perms_6_r", dut_g.l0.io_w_req_bits_data_1_entries_perms_6_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_6_r);
    chk("l0.io_w_req_bits_data_1_entries_perms_7_d", dut_g.l0.io_w_req_bits_data_1_entries_perms_7_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_7_d);
    chk("l0.io_w_req_bits_data_1_entries_perms_7_a", dut_g.l0.io_w_req_bits_data_1_entries_perms_7_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_7_a);
    chk("l0.io_w_req_bits_data_1_entries_perms_7_g", dut_g.l0.io_w_req_bits_data_1_entries_perms_7_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_7_g);
    chk("l0.io_w_req_bits_data_1_entries_perms_7_u", dut_g.l0.io_w_req_bits_data_1_entries_perms_7_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_7_u);
    chk("l0.io_w_req_bits_data_1_entries_perms_7_x", dut_g.l0.io_w_req_bits_data_1_entries_perms_7_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_7_x);
    chk("l0.io_w_req_bits_data_1_entries_perms_7_w", dut_g.l0.io_w_req_bits_data_1_entries_perms_7_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_7_w);
    chk("l0.io_w_req_bits_data_1_entries_perms_7_r", dut_g.l0.io_w_req_bits_data_1_entries_perms_7_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_perms_7_r);
    chk("l0.io_w_req_bits_data_1_entries_prefetch", dut_g.l0.io_w_req_bits_data_1_entries_prefetch, dut_i.u_core.u_l0_sram.io_w_req_bits_data_1_entries_prefetch);
    chk("l0.io_w_req_bits_data_2_entries_tag", dut_g.l0.io_w_req_bits_data_2_entries_tag, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_tag);
    chk("l0.io_w_req_bits_data_2_entries_asid", dut_g.l0.io_w_req_bits_data_2_entries_asid, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_asid);
    chk("l0.io_w_req_bits_data_2_entries_vmid", dut_g.l0.io_w_req_bits_data_2_entries_vmid, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vmid);
    chk("l0.io_w_req_bits_data_2_entries_pbmts_0", dut_g.l0.io_w_req_bits_data_2_entries_pbmts_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_pbmts_0);
    chk("l0.io_w_req_bits_data_2_entries_pbmts_1", dut_g.l0.io_w_req_bits_data_2_entries_pbmts_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_pbmts_1);
    chk("l0.io_w_req_bits_data_2_entries_pbmts_2", dut_g.l0.io_w_req_bits_data_2_entries_pbmts_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_pbmts_2);
    chk("l0.io_w_req_bits_data_2_entries_pbmts_3", dut_g.l0.io_w_req_bits_data_2_entries_pbmts_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_pbmts_3);
    chk("l0.io_w_req_bits_data_2_entries_pbmts_4", dut_g.l0.io_w_req_bits_data_2_entries_pbmts_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_pbmts_4);
    chk("l0.io_w_req_bits_data_2_entries_pbmts_5", dut_g.l0.io_w_req_bits_data_2_entries_pbmts_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_pbmts_5);
    chk("l0.io_w_req_bits_data_2_entries_pbmts_6", dut_g.l0.io_w_req_bits_data_2_entries_pbmts_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_pbmts_6);
    chk("l0.io_w_req_bits_data_2_entries_pbmts_7", dut_g.l0.io_w_req_bits_data_2_entries_pbmts_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_pbmts_7);
    chk("l0.io_w_req_bits_data_2_entries_ppns_0", dut_g.l0.io_w_req_bits_data_2_entries_ppns_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_ppns_0);
    chk("l0.io_w_req_bits_data_2_entries_ppns_1", dut_g.l0.io_w_req_bits_data_2_entries_ppns_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_ppns_1);
    chk("l0.io_w_req_bits_data_2_entries_ppns_2", dut_g.l0.io_w_req_bits_data_2_entries_ppns_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_ppns_2);
    chk("l0.io_w_req_bits_data_2_entries_ppns_3", dut_g.l0.io_w_req_bits_data_2_entries_ppns_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_ppns_3);
    chk("l0.io_w_req_bits_data_2_entries_ppns_4", dut_g.l0.io_w_req_bits_data_2_entries_ppns_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_ppns_4);
    chk("l0.io_w_req_bits_data_2_entries_ppns_5", dut_g.l0.io_w_req_bits_data_2_entries_ppns_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_ppns_5);
    chk("l0.io_w_req_bits_data_2_entries_ppns_6", dut_g.l0.io_w_req_bits_data_2_entries_ppns_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_ppns_6);
    chk("l0.io_w_req_bits_data_2_entries_ppns_7", dut_g.l0.io_w_req_bits_data_2_entries_ppns_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_ppns_7);
    chk("l0.io_w_req_bits_data_2_entries_vs_0", dut_g.l0.io_w_req_bits_data_2_entries_vs_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vs_0);
    chk("l0.io_w_req_bits_data_2_entries_vs_1", dut_g.l0.io_w_req_bits_data_2_entries_vs_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vs_1);
    chk("l0.io_w_req_bits_data_2_entries_vs_2", dut_g.l0.io_w_req_bits_data_2_entries_vs_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vs_2);
    chk("l0.io_w_req_bits_data_2_entries_vs_3", dut_g.l0.io_w_req_bits_data_2_entries_vs_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vs_3);
    chk("l0.io_w_req_bits_data_2_entries_vs_4", dut_g.l0.io_w_req_bits_data_2_entries_vs_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vs_4);
    chk("l0.io_w_req_bits_data_2_entries_vs_5", dut_g.l0.io_w_req_bits_data_2_entries_vs_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vs_5);
    chk("l0.io_w_req_bits_data_2_entries_vs_6", dut_g.l0.io_w_req_bits_data_2_entries_vs_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vs_6);
    chk("l0.io_w_req_bits_data_2_entries_vs_7", dut_g.l0.io_w_req_bits_data_2_entries_vs_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_vs_7);
    chk("l0.io_w_req_bits_data_2_entries_onlypf_0", dut_g.l0.io_w_req_bits_data_2_entries_onlypf_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_onlypf_0);
    chk("l0.io_w_req_bits_data_2_entries_onlypf_1", dut_g.l0.io_w_req_bits_data_2_entries_onlypf_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_onlypf_1);
    chk("l0.io_w_req_bits_data_2_entries_onlypf_2", dut_g.l0.io_w_req_bits_data_2_entries_onlypf_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_onlypf_2);
    chk("l0.io_w_req_bits_data_2_entries_onlypf_3", dut_g.l0.io_w_req_bits_data_2_entries_onlypf_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_onlypf_3);
    chk("l0.io_w_req_bits_data_2_entries_onlypf_4", dut_g.l0.io_w_req_bits_data_2_entries_onlypf_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_onlypf_4);
    chk("l0.io_w_req_bits_data_2_entries_onlypf_5", dut_g.l0.io_w_req_bits_data_2_entries_onlypf_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_onlypf_5);
    chk("l0.io_w_req_bits_data_2_entries_onlypf_6", dut_g.l0.io_w_req_bits_data_2_entries_onlypf_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_onlypf_6);
    chk("l0.io_w_req_bits_data_2_entries_onlypf_7", dut_g.l0.io_w_req_bits_data_2_entries_onlypf_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_onlypf_7);
    chk("l0.io_w_req_bits_data_2_entries_perms_0_d", dut_g.l0.io_w_req_bits_data_2_entries_perms_0_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_0_d);
    chk("l0.io_w_req_bits_data_2_entries_perms_0_a", dut_g.l0.io_w_req_bits_data_2_entries_perms_0_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_0_a);
    chk("l0.io_w_req_bits_data_2_entries_perms_0_g", dut_g.l0.io_w_req_bits_data_2_entries_perms_0_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_0_g);
    chk("l0.io_w_req_bits_data_2_entries_perms_0_u", dut_g.l0.io_w_req_bits_data_2_entries_perms_0_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_0_u);
    chk("l0.io_w_req_bits_data_2_entries_perms_0_x", dut_g.l0.io_w_req_bits_data_2_entries_perms_0_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_0_x);
    chk("l0.io_w_req_bits_data_2_entries_perms_0_w", dut_g.l0.io_w_req_bits_data_2_entries_perms_0_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_0_w);
    chk("l0.io_w_req_bits_data_2_entries_perms_0_r", dut_g.l0.io_w_req_bits_data_2_entries_perms_0_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_0_r);
    chk("l0.io_w_req_bits_data_2_entries_perms_1_d", dut_g.l0.io_w_req_bits_data_2_entries_perms_1_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_1_d);
    chk("l0.io_w_req_bits_data_2_entries_perms_1_a", dut_g.l0.io_w_req_bits_data_2_entries_perms_1_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_1_a);
    chk("l0.io_w_req_bits_data_2_entries_perms_1_g", dut_g.l0.io_w_req_bits_data_2_entries_perms_1_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_1_g);
    chk("l0.io_w_req_bits_data_2_entries_perms_1_u", dut_g.l0.io_w_req_bits_data_2_entries_perms_1_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_1_u);
    chk("l0.io_w_req_bits_data_2_entries_perms_1_x", dut_g.l0.io_w_req_bits_data_2_entries_perms_1_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_1_x);
    chk("l0.io_w_req_bits_data_2_entries_perms_1_w", dut_g.l0.io_w_req_bits_data_2_entries_perms_1_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_1_w);
    chk("l0.io_w_req_bits_data_2_entries_perms_1_r", dut_g.l0.io_w_req_bits_data_2_entries_perms_1_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_1_r);
    chk("l0.io_w_req_bits_data_2_entries_perms_2_d", dut_g.l0.io_w_req_bits_data_2_entries_perms_2_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_2_d);
    chk("l0.io_w_req_bits_data_2_entries_perms_2_a", dut_g.l0.io_w_req_bits_data_2_entries_perms_2_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_2_a);
    chk("l0.io_w_req_bits_data_2_entries_perms_2_g", dut_g.l0.io_w_req_bits_data_2_entries_perms_2_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_2_g);
    chk("l0.io_w_req_bits_data_2_entries_perms_2_u", dut_g.l0.io_w_req_bits_data_2_entries_perms_2_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_2_u);
    chk("l0.io_w_req_bits_data_2_entries_perms_2_x", dut_g.l0.io_w_req_bits_data_2_entries_perms_2_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_2_x);
    chk("l0.io_w_req_bits_data_2_entries_perms_2_w", dut_g.l0.io_w_req_bits_data_2_entries_perms_2_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_2_w);
    chk("l0.io_w_req_bits_data_2_entries_perms_2_r", dut_g.l0.io_w_req_bits_data_2_entries_perms_2_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_2_r);
    chk("l0.io_w_req_bits_data_2_entries_perms_3_d", dut_g.l0.io_w_req_bits_data_2_entries_perms_3_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_3_d);
    chk("l0.io_w_req_bits_data_2_entries_perms_3_a", dut_g.l0.io_w_req_bits_data_2_entries_perms_3_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_3_a);
    chk("l0.io_w_req_bits_data_2_entries_perms_3_g", dut_g.l0.io_w_req_bits_data_2_entries_perms_3_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_3_g);
    chk("l0.io_w_req_bits_data_2_entries_perms_3_u", dut_g.l0.io_w_req_bits_data_2_entries_perms_3_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_3_u);
    chk("l0.io_w_req_bits_data_2_entries_perms_3_x", dut_g.l0.io_w_req_bits_data_2_entries_perms_3_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_3_x);
    chk("l0.io_w_req_bits_data_2_entries_perms_3_w", dut_g.l0.io_w_req_bits_data_2_entries_perms_3_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_3_w);
    chk("l0.io_w_req_bits_data_2_entries_perms_3_r", dut_g.l0.io_w_req_bits_data_2_entries_perms_3_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_3_r);
    chk("l0.io_w_req_bits_data_2_entries_perms_4_d", dut_g.l0.io_w_req_bits_data_2_entries_perms_4_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_4_d);
    chk("l0.io_w_req_bits_data_2_entries_perms_4_a", dut_g.l0.io_w_req_bits_data_2_entries_perms_4_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_4_a);
    chk("l0.io_w_req_bits_data_2_entries_perms_4_g", dut_g.l0.io_w_req_bits_data_2_entries_perms_4_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_4_g);
    chk("l0.io_w_req_bits_data_2_entries_perms_4_u", dut_g.l0.io_w_req_bits_data_2_entries_perms_4_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_4_u);
    chk("l0.io_w_req_bits_data_2_entries_perms_4_x", dut_g.l0.io_w_req_bits_data_2_entries_perms_4_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_4_x);
    chk("l0.io_w_req_bits_data_2_entries_perms_4_w", dut_g.l0.io_w_req_bits_data_2_entries_perms_4_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_4_w);
    chk("l0.io_w_req_bits_data_2_entries_perms_4_r", dut_g.l0.io_w_req_bits_data_2_entries_perms_4_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_4_r);
    chk("l0.io_w_req_bits_data_2_entries_perms_5_d", dut_g.l0.io_w_req_bits_data_2_entries_perms_5_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_5_d);
    chk("l0.io_w_req_bits_data_2_entries_perms_5_a", dut_g.l0.io_w_req_bits_data_2_entries_perms_5_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_5_a);
    chk("l0.io_w_req_bits_data_2_entries_perms_5_g", dut_g.l0.io_w_req_bits_data_2_entries_perms_5_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_5_g);
    chk("l0.io_w_req_bits_data_2_entries_perms_5_u", dut_g.l0.io_w_req_bits_data_2_entries_perms_5_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_5_u);
    chk("l0.io_w_req_bits_data_2_entries_perms_5_x", dut_g.l0.io_w_req_bits_data_2_entries_perms_5_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_5_x);
    chk("l0.io_w_req_bits_data_2_entries_perms_5_w", dut_g.l0.io_w_req_bits_data_2_entries_perms_5_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_5_w);
    chk("l0.io_w_req_bits_data_2_entries_perms_5_r", dut_g.l0.io_w_req_bits_data_2_entries_perms_5_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_5_r);
    chk("l0.io_w_req_bits_data_2_entries_perms_6_d", dut_g.l0.io_w_req_bits_data_2_entries_perms_6_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_6_d);
    chk("l0.io_w_req_bits_data_2_entries_perms_6_a", dut_g.l0.io_w_req_bits_data_2_entries_perms_6_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_6_a);
    chk("l0.io_w_req_bits_data_2_entries_perms_6_g", dut_g.l0.io_w_req_bits_data_2_entries_perms_6_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_6_g);
    chk("l0.io_w_req_bits_data_2_entries_perms_6_u", dut_g.l0.io_w_req_bits_data_2_entries_perms_6_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_6_u);
    chk("l0.io_w_req_bits_data_2_entries_perms_6_x", dut_g.l0.io_w_req_bits_data_2_entries_perms_6_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_6_x);
    chk("l0.io_w_req_bits_data_2_entries_perms_6_w", dut_g.l0.io_w_req_bits_data_2_entries_perms_6_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_6_w);
    chk("l0.io_w_req_bits_data_2_entries_perms_6_r", dut_g.l0.io_w_req_bits_data_2_entries_perms_6_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_6_r);
    chk("l0.io_w_req_bits_data_2_entries_perms_7_d", dut_g.l0.io_w_req_bits_data_2_entries_perms_7_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_7_d);
    chk("l0.io_w_req_bits_data_2_entries_perms_7_a", dut_g.l0.io_w_req_bits_data_2_entries_perms_7_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_7_a);
    chk("l0.io_w_req_bits_data_2_entries_perms_7_g", dut_g.l0.io_w_req_bits_data_2_entries_perms_7_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_7_g);
    chk("l0.io_w_req_bits_data_2_entries_perms_7_u", dut_g.l0.io_w_req_bits_data_2_entries_perms_7_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_7_u);
    chk("l0.io_w_req_bits_data_2_entries_perms_7_x", dut_g.l0.io_w_req_bits_data_2_entries_perms_7_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_7_x);
    chk("l0.io_w_req_bits_data_2_entries_perms_7_w", dut_g.l0.io_w_req_bits_data_2_entries_perms_7_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_7_w);
    chk("l0.io_w_req_bits_data_2_entries_perms_7_r", dut_g.l0.io_w_req_bits_data_2_entries_perms_7_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_perms_7_r);
    chk("l0.io_w_req_bits_data_2_entries_prefetch", dut_g.l0.io_w_req_bits_data_2_entries_prefetch, dut_i.u_core.u_l0_sram.io_w_req_bits_data_2_entries_prefetch);
    chk("l0.io_w_req_bits_data_3_entries_tag", dut_g.l0.io_w_req_bits_data_3_entries_tag, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_tag);
    chk("l0.io_w_req_bits_data_3_entries_asid", dut_g.l0.io_w_req_bits_data_3_entries_asid, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_asid);
    chk("l0.io_w_req_bits_data_3_entries_vmid", dut_g.l0.io_w_req_bits_data_3_entries_vmid, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vmid);
    chk("l0.io_w_req_bits_data_3_entries_pbmts_0", dut_g.l0.io_w_req_bits_data_3_entries_pbmts_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_pbmts_0);
    chk("l0.io_w_req_bits_data_3_entries_pbmts_1", dut_g.l0.io_w_req_bits_data_3_entries_pbmts_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_pbmts_1);
    chk("l0.io_w_req_bits_data_3_entries_pbmts_2", dut_g.l0.io_w_req_bits_data_3_entries_pbmts_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_pbmts_2);
    chk("l0.io_w_req_bits_data_3_entries_pbmts_3", dut_g.l0.io_w_req_bits_data_3_entries_pbmts_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_pbmts_3);
    chk("l0.io_w_req_bits_data_3_entries_pbmts_4", dut_g.l0.io_w_req_bits_data_3_entries_pbmts_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_pbmts_4);
    chk("l0.io_w_req_bits_data_3_entries_pbmts_5", dut_g.l0.io_w_req_bits_data_3_entries_pbmts_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_pbmts_5);
    chk("l0.io_w_req_bits_data_3_entries_pbmts_6", dut_g.l0.io_w_req_bits_data_3_entries_pbmts_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_pbmts_6);
    chk("l0.io_w_req_bits_data_3_entries_pbmts_7", dut_g.l0.io_w_req_bits_data_3_entries_pbmts_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_pbmts_7);
    chk("l0.io_w_req_bits_data_3_entries_ppns_0", dut_g.l0.io_w_req_bits_data_3_entries_ppns_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_ppns_0);
    chk("l0.io_w_req_bits_data_3_entries_ppns_1", dut_g.l0.io_w_req_bits_data_3_entries_ppns_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_ppns_1);
    chk("l0.io_w_req_bits_data_3_entries_ppns_2", dut_g.l0.io_w_req_bits_data_3_entries_ppns_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_ppns_2);
    chk("l0.io_w_req_bits_data_3_entries_ppns_3", dut_g.l0.io_w_req_bits_data_3_entries_ppns_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_ppns_3);
    chk("l0.io_w_req_bits_data_3_entries_ppns_4", dut_g.l0.io_w_req_bits_data_3_entries_ppns_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_ppns_4);
    chk("l0.io_w_req_bits_data_3_entries_ppns_5", dut_g.l0.io_w_req_bits_data_3_entries_ppns_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_ppns_5);
    chk("l0.io_w_req_bits_data_3_entries_ppns_6", dut_g.l0.io_w_req_bits_data_3_entries_ppns_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_ppns_6);
    chk("l0.io_w_req_bits_data_3_entries_ppns_7", dut_g.l0.io_w_req_bits_data_3_entries_ppns_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_ppns_7);
    chk("l0.io_w_req_bits_data_3_entries_vs_0", dut_g.l0.io_w_req_bits_data_3_entries_vs_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vs_0);
    chk("l0.io_w_req_bits_data_3_entries_vs_1", dut_g.l0.io_w_req_bits_data_3_entries_vs_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vs_1);
    chk("l0.io_w_req_bits_data_3_entries_vs_2", dut_g.l0.io_w_req_bits_data_3_entries_vs_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vs_2);
    chk("l0.io_w_req_bits_data_3_entries_vs_3", dut_g.l0.io_w_req_bits_data_3_entries_vs_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vs_3);
    chk("l0.io_w_req_bits_data_3_entries_vs_4", dut_g.l0.io_w_req_bits_data_3_entries_vs_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vs_4);
    chk("l0.io_w_req_bits_data_3_entries_vs_5", dut_g.l0.io_w_req_bits_data_3_entries_vs_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vs_5);
    chk("l0.io_w_req_bits_data_3_entries_vs_6", dut_g.l0.io_w_req_bits_data_3_entries_vs_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vs_6);
    chk("l0.io_w_req_bits_data_3_entries_vs_7", dut_g.l0.io_w_req_bits_data_3_entries_vs_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_vs_7);
    chk("l0.io_w_req_bits_data_3_entries_onlypf_0", dut_g.l0.io_w_req_bits_data_3_entries_onlypf_0, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_onlypf_0);
    chk("l0.io_w_req_bits_data_3_entries_onlypf_1", dut_g.l0.io_w_req_bits_data_3_entries_onlypf_1, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_onlypf_1);
    chk("l0.io_w_req_bits_data_3_entries_onlypf_2", dut_g.l0.io_w_req_bits_data_3_entries_onlypf_2, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_onlypf_2);
    chk("l0.io_w_req_bits_data_3_entries_onlypf_3", dut_g.l0.io_w_req_bits_data_3_entries_onlypf_3, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_onlypf_3);
    chk("l0.io_w_req_bits_data_3_entries_onlypf_4", dut_g.l0.io_w_req_bits_data_3_entries_onlypf_4, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_onlypf_4);
    chk("l0.io_w_req_bits_data_3_entries_onlypf_5", dut_g.l0.io_w_req_bits_data_3_entries_onlypf_5, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_onlypf_5);
    chk("l0.io_w_req_bits_data_3_entries_onlypf_6", dut_g.l0.io_w_req_bits_data_3_entries_onlypf_6, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_onlypf_6);
    chk("l0.io_w_req_bits_data_3_entries_onlypf_7", dut_g.l0.io_w_req_bits_data_3_entries_onlypf_7, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_onlypf_7);
    chk("l0.io_w_req_bits_data_3_entries_perms_0_d", dut_g.l0.io_w_req_bits_data_3_entries_perms_0_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_0_d);
    chk("l0.io_w_req_bits_data_3_entries_perms_0_a", dut_g.l0.io_w_req_bits_data_3_entries_perms_0_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_0_a);
    chk("l0.io_w_req_bits_data_3_entries_perms_0_g", dut_g.l0.io_w_req_bits_data_3_entries_perms_0_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_0_g);
    chk("l0.io_w_req_bits_data_3_entries_perms_0_u", dut_g.l0.io_w_req_bits_data_3_entries_perms_0_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_0_u);
    chk("l0.io_w_req_bits_data_3_entries_perms_0_x", dut_g.l0.io_w_req_bits_data_3_entries_perms_0_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_0_x);
    chk("l0.io_w_req_bits_data_3_entries_perms_0_w", dut_g.l0.io_w_req_bits_data_3_entries_perms_0_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_0_w);
    chk("l0.io_w_req_bits_data_3_entries_perms_0_r", dut_g.l0.io_w_req_bits_data_3_entries_perms_0_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_0_r);
    chk("l0.io_w_req_bits_data_3_entries_perms_1_d", dut_g.l0.io_w_req_bits_data_3_entries_perms_1_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_1_d);
    chk("l0.io_w_req_bits_data_3_entries_perms_1_a", dut_g.l0.io_w_req_bits_data_3_entries_perms_1_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_1_a);
    chk("l0.io_w_req_bits_data_3_entries_perms_1_g", dut_g.l0.io_w_req_bits_data_3_entries_perms_1_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_1_g);
    chk("l0.io_w_req_bits_data_3_entries_perms_1_u", dut_g.l0.io_w_req_bits_data_3_entries_perms_1_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_1_u);
    chk("l0.io_w_req_bits_data_3_entries_perms_1_x", dut_g.l0.io_w_req_bits_data_3_entries_perms_1_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_1_x);
    chk("l0.io_w_req_bits_data_3_entries_perms_1_w", dut_g.l0.io_w_req_bits_data_3_entries_perms_1_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_1_w);
    chk("l0.io_w_req_bits_data_3_entries_perms_1_r", dut_g.l0.io_w_req_bits_data_3_entries_perms_1_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_1_r);
    chk("l0.io_w_req_bits_data_3_entries_perms_2_d", dut_g.l0.io_w_req_bits_data_3_entries_perms_2_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_2_d);
    chk("l0.io_w_req_bits_data_3_entries_perms_2_a", dut_g.l0.io_w_req_bits_data_3_entries_perms_2_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_2_a);
    chk("l0.io_w_req_bits_data_3_entries_perms_2_g", dut_g.l0.io_w_req_bits_data_3_entries_perms_2_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_2_g);
    chk("l0.io_w_req_bits_data_3_entries_perms_2_u", dut_g.l0.io_w_req_bits_data_3_entries_perms_2_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_2_u);
    chk("l0.io_w_req_bits_data_3_entries_perms_2_x", dut_g.l0.io_w_req_bits_data_3_entries_perms_2_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_2_x);
    chk("l0.io_w_req_bits_data_3_entries_perms_2_w", dut_g.l0.io_w_req_bits_data_3_entries_perms_2_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_2_w);
    chk("l0.io_w_req_bits_data_3_entries_perms_2_r", dut_g.l0.io_w_req_bits_data_3_entries_perms_2_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_2_r);
    chk("l0.io_w_req_bits_data_3_entries_perms_3_d", dut_g.l0.io_w_req_bits_data_3_entries_perms_3_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_3_d);
    chk("l0.io_w_req_bits_data_3_entries_perms_3_a", dut_g.l0.io_w_req_bits_data_3_entries_perms_3_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_3_a);
    chk("l0.io_w_req_bits_data_3_entries_perms_3_g", dut_g.l0.io_w_req_bits_data_3_entries_perms_3_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_3_g);
    chk("l0.io_w_req_bits_data_3_entries_perms_3_u", dut_g.l0.io_w_req_bits_data_3_entries_perms_3_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_3_u);
    chk("l0.io_w_req_bits_data_3_entries_perms_3_x", dut_g.l0.io_w_req_bits_data_3_entries_perms_3_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_3_x);
    chk("l0.io_w_req_bits_data_3_entries_perms_3_w", dut_g.l0.io_w_req_bits_data_3_entries_perms_3_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_3_w);
    chk("l0.io_w_req_bits_data_3_entries_perms_3_r", dut_g.l0.io_w_req_bits_data_3_entries_perms_3_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_3_r);
    chk("l0.io_w_req_bits_data_3_entries_perms_4_d", dut_g.l0.io_w_req_bits_data_3_entries_perms_4_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_4_d);
    chk("l0.io_w_req_bits_data_3_entries_perms_4_a", dut_g.l0.io_w_req_bits_data_3_entries_perms_4_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_4_a);
    chk("l0.io_w_req_bits_data_3_entries_perms_4_g", dut_g.l0.io_w_req_bits_data_3_entries_perms_4_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_4_g);
    chk("l0.io_w_req_bits_data_3_entries_perms_4_u", dut_g.l0.io_w_req_bits_data_3_entries_perms_4_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_4_u);
    chk("l0.io_w_req_bits_data_3_entries_perms_4_x", dut_g.l0.io_w_req_bits_data_3_entries_perms_4_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_4_x);
    chk("l0.io_w_req_bits_data_3_entries_perms_4_w", dut_g.l0.io_w_req_bits_data_3_entries_perms_4_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_4_w);
    chk("l0.io_w_req_bits_data_3_entries_perms_4_r", dut_g.l0.io_w_req_bits_data_3_entries_perms_4_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_4_r);
    chk("l0.io_w_req_bits_data_3_entries_perms_5_d", dut_g.l0.io_w_req_bits_data_3_entries_perms_5_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_5_d);
    chk("l0.io_w_req_bits_data_3_entries_perms_5_a", dut_g.l0.io_w_req_bits_data_3_entries_perms_5_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_5_a);
    chk("l0.io_w_req_bits_data_3_entries_perms_5_g", dut_g.l0.io_w_req_bits_data_3_entries_perms_5_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_5_g);
    chk("l0.io_w_req_bits_data_3_entries_perms_5_u", dut_g.l0.io_w_req_bits_data_3_entries_perms_5_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_5_u);
    chk("l0.io_w_req_bits_data_3_entries_perms_5_x", dut_g.l0.io_w_req_bits_data_3_entries_perms_5_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_5_x);
    chk("l0.io_w_req_bits_data_3_entries_perms_5_w", dut_g.l0.io_w_req_bits_data_3_entries_perms_5_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_5_w);
    chk("l0.io_w_req_bits_data_3_entries_perms_5_r", dut_g.l0.io_w_req_bits_data_3_entries_perms_5_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_5_r);
    chk("l0.io_w_req_bits_data_3_entries_perms_6_d", dut_g.l0.io_w_req_bits_data_3_entries_perms_6_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_6_d);
    chk("l0.io_w_req_bits_data_3_entries_perms_6_a", dut_g.l0.io_w_req_bits_data_3_entries_perms_6_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_6_a);
    chk("l0.io_w_req_bits_data_3_entries_perms_6_g", dut_g.l0.io_w_req_bits_data_3_entries_perms_6_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_6_g);
    chk("l0.io_w_req_bits_data_3_entries_perms_6_u", dut_g.l0.io_w_req_bits_data_3_entries_perms_6_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_6_u);
    chk("l0.io_w_req_bits_data_3_entries_perms_6_x", dut_g.l0.io_w_req_bits_data_3_entries_perms_6_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_6_x);
    chk("l0.io_w_req_bits_data_3_entries_perms_6_w", dut_g.l0.io_w_req_bits_data_3_entries_perms_6_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_6_w);
    chk("l0.io_w_req_bits_data_3_entries_perms_6_r", dut_g.l0.io_w_req_bits_data_3_entries_perms_6_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_6_r);
    chk("l0.io_w_req_bits_data_3_entries_perms_7_d", dut_g.l0.io_w_req_bits_data_3_entries_perms_7_d, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_7_d);
    chk("l0.io_w_req_bits_data_3_entries_perms_7_a", dut_g.l0.io_w_req_bits_data_3_entries_perms_7_a, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_7_a);
    chk("l0.io_w_req_bits_data_3_entries_perms_7_g", dut_g.l0.io_w_req_bits_data_3_entries_perms_7_g, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_7_g);
    chk("l0.io_w_req_bits_data_3_entries_perms_7_u", dut_g.l0.io_w_req_bits_data_3_entries_perms_7_u, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_7_u);
    chk("l0.io_w_req_bits_data_3_entries_perms_7_x", dut_g.l0.io_w_req_bits_data_3_entries_perms_7_x, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_7_x);
    chk("l0.io_w_req_bits_data_3_entries_perms_7_w", dut_g.l0.io_w_req_bits_data_3_entries_perms_7_w, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_7_w);
    chk("l0.io_w_req_bits_data_3_entries_perms_7_r", dut_g.l0.io_w_req_bits_data_3_entries_perms_7_r, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_perms_7_r);
    chk("l0.io_w_req_bits_data_3_entries_prefetch", dut_g.l0.io_w_req_bits_data_3_entries_prefetch, dut_i.u_core.u_l0_sram.io_w_req_bits_data_3_entries_prefetch);
    chk("l0.io_w_req_bits_waymask", dut_g.l0.io_w_req_bits_waymask, dut_i.u_core.u_l0_sram.io_w_req_bits_waymask);
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", ncycles)) ncycles = 20000;
    // 未驱动的输入全部清零（本对照只关心回填锥体）
    io_csr_mPBMTE = '0;
    io_csr_hPBMTE = '0;
    io_req_valid = '0;
    io_req_bits_req_info_vpn = '0;
    io_req_bits_req_info_s2xlate = '0;
    io_req_bits_req_info_source = '0;
    io_req_bits_isFirst = '0;
    io_req_bits_isHptwReq = '0;
    io_req_bits_hptwId = '0;
    io_resp_ready = '0;
    io_refill_valid = '0;
    io_refill_bits_ptes = '0;
    io_refill_bits_levelOH_sp = '0;
    io_refill_bits_levelOH_l0 = '0;
    io_refill_bits_levelOH_l1 = '0;
    io_refill_bits_levelOH_l2 = '0;
    io_refill_bits_levelOH_l3 = '0;
    io_refill_bits_req_info_dup_0_vpn = '0;
    io_refill_bits_req_info_dup_0_s2xlate = '0;
    io_refill_bits_req_info_dup_0_source = '0;
    io_refill_bits_req_info_dup_1_vpn = '0;
    io_refill_bits_req_info_dup_1_s2xlate = '0;
    io_refill_bits_req_info_dup_1_source = '0;
    io_refill_bits_req_info_dup_2_vpn = '0;
    io_refill_bits_req_info_dup_2_s2xlate = '0;
    io_refill_bits_req_info_dup_2_source = '0;
    io_refill_bits_level_dup_0 = '0;
    io_refill_bits_level_dup_2 = '0;
    io_refill_bits_sel_pte_dup_0 = '0;
    io_refill_bits_sel_pte_dup_2 = '0;
    io_sfence_dup_0_valid = '0;
    io_sfence_dup_0_bits_rs1 = '0;
    io_sfence_dup_0_bits_rs2 = '0;
    io_sfence_dup_0_bits_addr = '0;
    io_sfence_dup_0_bits_id = '0;
    io_sfence_dup_0_bits_hv = '0;
    io_sfence_dup_0_bits_hg = '0;
    io_sfence_dup_1_valid = '0;
    io_sfence_dup_1_bits_id = '0;
    io_sfence_dup_2_valid = '0;
    io_sfence_dup_2_bits_rs1 = '0;
    io_sfence_dup_2_bits_rs2 = '0;
    io_sfence_dup_2_bits_id = '0;
    io_csr_dup_0_satp_asid = '0;
    io_csr_dup_0_satp_changed = '0;
    io_csr_dup_0_vsatp_asid = '0;
    io_csr_dup_0_vsatp_changed = '0;
    io_csr_dup_0_hgatp_mode = '0;
    io_csr_dup_0_hgatp_vmid = '0;
    io_csr_dup_0_hgatp_changed = '0;
    io_csr_dup_0_mbmc_BME = '0;
    io_csr_dup_0_mbmc_CMODE = '0;
    io_csr_dup_0_priv_virt = '0;
    io_csr_dup_0_priv_virt_changed = '0;
    io_csr_dup_1_satp_asid = '0;
    io_csr_dup_1_satp_changed = '0;
    io_csr_dup_1_vsatp_asid = '0;
    io_csr_dup_1_vsatp_changed = '0;
    io_csr_dup_1_hgatp_mode = '0;
    io_csr_dup_1_hgatp_vmid = '0;
    io_csr_dup_1_hgatp_changed = '0;
    io_csr_dup_1_priv_virt = '0;
    io_csr_dup_1_priv_virt_changed = '0;
    io_csr_dup_2_satp_asid = '0;
    io_csr_dup_2_satp_changed = '0;
    io_csr_dup_2_vsatp_asid = '0;
    io_csr_dup_2_vsatp_changed = '0;
    io_csr_dup_2_hgatp_mode = '0;
    io_csr_dup_2_hgatp_vmid = '0;
    io_csr_dup_2_hgatp_changed = '0;
    io_csr_dup_2_priv_virt = '0;
    io_csr_dup_2_priv_virt_changed = '0;
    io_bitmap_wakeup_valid = '0;
    io_bitmap_wakeup_bits_setIndex = '0;
    io_bitmap_wakeup_bits_tag = '0;
    io_bitmap_wakeup_bits_way_info = '0;
    io_bitmap_wakeup_bits_pte_index = '0;
    io_bitmap_wakeup_bits_check_success = '0;
    io_bitmap_wakeup_bits_s2xlate = '0;
    boreChildrenBd_bore_array = '0;
    boreChildrenBd_bore_all = '0;
    boreChildrenBd_bore_req = '0;
    boreChildrenBd_bore_writeen = '0;
    boreChildrenBd_bore_be = '0;
    boreChildrenBd_bore_addr = '0;
    boreChildrenBd_bore_indata = '0;
    boreChildrenBd_bore_readen = '0;
    boreChildrenBd_bore_addr_rd = '0;
    boreChildrenBd_bore_1_array = '0;
    boreChildrenBd_bore_1_all = '0;
    boreChildrenBd_bore_1_req = '0;
    boreChildrenBd_bore_1_writeen = '0;
    boreChildrenBd_bore_1_be = '0;
    boreChildrenBd_bore_1_addr = '0;
    boreChildrenBd_bore_1_indata = '0;
    boreChildrenBd_bore_1_readen = '0;
    boreChildrenBd_bore_1_addr_rd = '0;
    sigFromSrams_bore_ram_hold = '0;
    sigFromSrams_bore_ram_bypass = '0;
    sigFromSrams_bore_ram_bp_clken = '0;
    sigFromSrams_bore_ram_aux_clk = '0;
    sigFromSrams_bore_ram_aux_ckbp = '0;
    sigFromSrams_bore_ram_mcp_hold = '0;
    sigFromSrams_bore_cgen = '0;
    sigFromSrams_bore_1_ram_hold = '0;
    sigFromSrams_bore_1_ram_bypass = '0;
    sigFromSrams_bore_1_ram_bp_clken = '0;
    sigFromSrams_bore_1_ram_aux_clk = '0;
    sigFromSrams_bore_1_ram_aux_ckbp = '0;
    sigFromSrams_bore_1_ram_mcp_hold = '0;
    sigFromSrams_bore_1_cgen = '0;
    sigFromSrams_bore_2_ram_hold = '0;
    sigFromSrams_bore_2_ram_bypass = '0;
    sigFromSrams_bore_2_ram_bp_clken = '0;
    sigFromSrams_bore_2_ram_aux_clk = '0;
    sigFromSrams_bore_2_ram_aux_ckbp = '0;
    sigFromSrams_bore_2_ram_mcp_hold = '0;
    sigFromSrams_bore_2_cgen = '0;
    sigFromSrams_bore_3_ram_hold = '0;
    sigFromSrams_bore_3_ram_bypass = '0;
    sigFromSrams_bore_3_ram_bp_clken = '0;
    sigFromSrams_bore_3_ram_aux_clk = '0;
    sigFromSrams_bore_3_ram_aux_ckbp = '0;
    sigFromSrams_bore_3_ram_mcp_hold = '0;
    sigFromSrams_bore_3_cgen = '0;
    sigFromSrams_bore_4_ram_hold = '0;
    sigFromSrams_bore_4_ram_bypass = '0;
    sigFromSrams_bore_4_ram_bp_clken = '0;
    sigFromSrams_bore_4_ram_aux_clk = '0;
    sigFromSrams_bore_4_ram_aux_ckbp = '0;
    sigFromSrams_bore_4_ram_mcp_hold = '0;
    sigFromSrams_bore_4_cgen = '0;
    sigFromSrams_bore_5_ram_hold = '0;
    sigFromSrams_bore_5_ram_bypass = '0;
    sigFromSrams_bore_5_ram_bp_clken = '0;
    sigFromSrams_bore_5_ram_aux_clk = '0;
    sigFromSrams_bore_5_ram_aux_ckbp = '0;
    sigFromSrams_bore_5_ram_mcp_hold = '0;
    sigFromSrams_bore_5_cgen = '0;
    sigFromSrams_bore_6_ram_hold = '0;
    sigFromSrams_bore_6_ram_bypass = '0;
    sigFromSrams_bore_6_ram_bp_clken = '0;
    sigFromSrams_bore_6_ram_aux_clk = '0;
    sigFromSrams_bore_6_ram_aux_ckbp = '0;
    sigFromSrams_bore_6_ram_mcp_hold = '0;
    sigFromSrams_bore_6_cgen = '0;
    sigFromSrams_bore_7_ram_hold = '0;
    sigFromSrams_bore_7_ram_bypass = '0;
    sigFromSrams_bore_7_ram_bp_clken = '0;
    sigFromSrams_bore_7_ram_aux_clk = '0;
    sigFromSrams_bore_7_ram_aux_ckbp = '0;
    sigFromSrams_bore_7_ram_mcp_hold = '0;
    sigFromSrams_bore_7_cgen = '0;
    sigFromSrams_bore_8_ram_hold = '0;
    sigFromSrams_bore_8_ram_bypass = '0;
    sigFromSrams_bore_8_ram_bp_clken = '0;
    sigFromSrams_bore_8_ram_aux_clk = '0;
    sigFromSrams_bore_8_ram_aux_ckbp = '0;
    sigFromSrams_bore_8_ram_mcp_hold = '0;
    sigFromSrams_bore_8_cgen = '0;
    sigFromSrams_bore_9_ram_hold = '0;
    sigFromSrams_bore_9_ram_bypass = '0;
    sigFromSrams_bore_9_ram_bp_clken = '0;
    sigFromSrams_bore_9_ram_aux_clk = '0;
    sigFromSrams_bore_9_ram_aux_ckbp = '0;
    sigFromSrams_bore_9_ram_mcp_hold = '0;
    sigFromSrams_bore_9_cgen = '0;
    sigFromSrams_bore_10_ram_hold = '0;
    sigFromSrams_bore_10_ram_bypass = '0;
    sigFromSrams_bore_10_ram_bp_clken = '0;
    sigFromSrams_bore_10_ram_aux_clk = '0;
    sigFromSrams_bore_10_ram_aux_ckbp = '0;
    sigFromSrams_bore_10_ram_mcp_hold = '0;
    sigFromSrams_bore_10_cgen = '0;
    sigFromSrams_bore_11_ram_hold = '0;
    sigFromSrams_bore_11_ram_bypass = '0;
    sigFromSrams_bore_11_ram_bp_clken = '0;
    sigFromSrams_bore_11_ram_aux_clk = '0;
    sigFromSrams_bore_11_ram_aux_ckbp = '0;
    sigFromSrams_bore_11_ram_mcp_hold = '0;
    sigFromSrams_bore_11_cgen = '0;
    sigFromSrams_bore_12_ram_hold = '0;
    sigFromSrams_bore_12_ram_bypass = '0;
    sigFromSrams_bore_12_ram_bp_clken = '0;
    sigFromSrams_bore_12_ram_aux_clk = '0;
    sigFromSrams_bore_12_ram_aux_ckbp = '0;
    sigFromSrams_bore_12_ram_mcp_hold = '0;
    sigFromSrams_bore_12_cgen = '0;
    sigFromSrams_bore_13_ram_hold = '0;
    sigFromSrams_bore_13_ram_bypass = '0;
    sigFromSrams_bore_13_ram_bp_clken = '0;
    sigFromSrams_bore_13_ram_aux_clk = '0;
    sigFromSrams_bore_13_ram_aux_ckbp = '0;
    sigFromSrams_bore_13_ram_mcp_hold = '0;
    sigFromSrams_bore_13_cgen = '0;
    sigFromSrams_bore_14_ram_hold = '0;
    sigFromSrams_bore_14_ram_bypass = '0;
    sigFromSrams_bore_14_ram_bp_clken = '0;
    sigFromSrams_bore_14_ram_aux_clk = '0;
    sigFromSrams_bore_14_ram_aux_ckbp = '0;
    sigFromSrams_bore_14_ram_mcp_hold = '0;
    sigFromSrams_bore_14_cgen = '0;
    sigFromSrams_bore_15_ram_hold = '0;
    sigFromSrams_bore_15_ram_bypass = '0;
    sigFromSrams_bore_15_ram_bp_clken = '0;
    sigFromSrams_bore_15_ram_aux_clk = '0;
    sigFromSrams_bore_15_ram_aux_ckbp = '0;
    sigFromSrams_bore_15_ram_mcp_hold = '0;
    sigFromSrams_bore_15_cgen = '0;
    sigFromSrams_bore_16_ram_hold = '0;
    sigFromSrams_bore_16_ram_bypass = '0;
    sigFromSrams_bore_16_ram_bp_clken = '0;
    sigFromSrams_bore_16_ram_aux_clk = '0;
    sigFromSrams_bore_16_ram_aux_ckbp = '0;
    sigFromSrams_bore_16_ram_mcp_hold = '0;
    sigFromSrams_bore_16_cgen = '0;
    cg_bore_cgen = '0;
    last_way_info = 4'h0;
    twin_cnt = 0;
    repeat (4) @(posedge clock);
    reset = 1'b0;
    for (int i = 0; i < 8; i++)
      vpn_pool[i] = {$urandom_range(0,3), $urandom_range(0,15),
                     $urandom_range(0,255), $urandom_range(0,255),
                     $urandom_range(0,63)};
    refresh_csr();
    for (int c = 0; c < ncycles; c++) begin
      @(negedge clock);
      // csr 每 512 拍才换一次；换得太勤，回填进去的条目根本等不到被查一次。
      if (c % 512 == 0) refresh_csr();
      drive_random();
      drive_fence();
      drive_wakeup();
      drive_twin();
      #1;
      compare_write_ports();
      compare_state();
      compare_hit();
      compare_outputs();     // ★全部 236 个输出，逐拍逐位★
      if (dut_g.hit)   fire_hit_l3++;
      if (dut_g.hit_1) fire_hit_l2++;
      if (dut_g.hit_2) fire_hit_sp++;
      if (dut_g.l1Hit) fire_hit_l1++;
      if (dut_g.l0Hit) fire_hit_l0++;
      if (dut_g.l3Refill) fire_l3++;
      if (dut_g.l2Refill) fire_l2++;
      if (dut_g.l1Refill) fire_l1++;
      if (dut_g.l0Refill) fire_l0++;
      if (dut_g.spRefill) fire_sp++;
      if (dut_g.wakeup_req_valid) fire_wakeup++;
      // golden 里 `_GEN_254 = wakeup_req_valid & wakeup_hitVec[OHToUInt(way_info)]`
      // 就是 l0BitmapReg 的写使能（PtwCache.sv:13282）。
      if (dut_g._GEN_254) fire_wk_write++;
      if (io_refill_bits_levelOH_l0) last_way_info = g_io_l0_way_info;
      // ★多路同时命中的计数★：H6 那个 mutant 只在这种拍上才与 golden 不同。
      if (dut_g.l1_hitVec_0 & dut_g.l1_hitVec_1) fire_l1_double++;
      if (dut_g.l0_hitVec_0 + dut_g.l0_hitVec_1
          + dut_g.l0_hitVec_2 + dut_g.l0_hitVec_3 >= 2) fire_l0_double++;
    end
    $display("PtwCache_refill study: cycles=%0d checks=%0d errors=%0d",
             ncycles, checks, errors);
    $display("PtwCache_refill fire: l3=%0d l2=%0d l1=%0d l0=%0d sp=%0d",
             fire_l3, fire_l2, fire_l1, fire_l0, fire_sp);
    $display("PtwCache_refill hit:  l3=%0d l2=%0d l1=%0d l0=%0d sp=%0d",
             fire_hit_l3, fire_hit_l2, fire_hit_l1, fire_hit_l0, fire_hit_sp);
    $display("PtwCache_refill fence: sfence=%0d hfence.vvma=%0d hfence.gvma=%0d wakeup=%0d wakeup_write=%0d",
             fire_sfence, fire_hfv, fire_hfg, fire_wakeup, fire_wk_write);
    $display("PtwCache_refill double-hit: l1=%0d l0=%0d",
             fire_l1_double, fire_l0_double);
    if (errors != 0)
      $display("STUDY FAIL (已追清信号失配)");
    else if (fire_l3 == 0 || fire_l2 == 0 || fire_l1 == 0 || fire_l0 == 0 || fire_sp == 0)
      $display("STUDY FAIL (有一级回填一次都没触发 —— 那一段等于什么都没比)");
    else if (fire_hit_l3 == 0 || fire_hit_l2 == 0 || fire_hit_l1 == 0
             || fire_hit_l0 == 0 || fire_hit_sp == 0)
      $display("STUDY FAIL (有一级命中一次都没触发 —— 那一段等于什么都没比)");
    else if (fire_sfence == 0 || fire_hfv == 0 || fire_hfg == 0)
      $display("STUDY FAIL (有一种栅栏一次都没发 —— §21 那一段等于什么都没比)");
    else if (fire_wakeup == 0 || fire_wk_write == 0)
      $display("STUDY FAIL (bitmap wakeup 没走到写 —— §22 那一段等于什么都没比)");
    else if (fire_l1_double == 0)
      $display("STUDY FAIL (l1 两路从没同时命中 —— H6 那类 PLRU 写法错按构造测不出来)");
    else
      $display("STUDY PASS");
    // ut_common.mk 的 run 目标按 "TEST PASSED" 判绿；上面那几行 STUDY 判据
    // 一条不过就不打这行。★两处判据必须同源★，所以这里重算一遍同一个布尔式，
    // 不许在上面打完 STUDY PASS 之后无条件补一行 TEST PASSED。
    if (errors == 0
        && fire_l3 != 0 && fire_l2 != 0 && fire_l1 != 0 && fire_l0 != 0 && fire_sp != 0
        && fire_hit_l3 != 0 && fire_hit_l2 != 0 && fire_hit_l1 != 0
        && fire_hit_l0 != 0 && fire_hit_sp != 0
        && fire_sfence != 0 && fire_hfv != 0 && fire_hfg != 0
        && fire_wakeup != 0 && fire_wk_write != 0
        && fire_l1_double != 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
