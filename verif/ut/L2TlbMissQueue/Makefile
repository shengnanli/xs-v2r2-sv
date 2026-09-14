MODULE = L2TlbMissQueue

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/L2TlbMissQueue.sv
TB_SRCS = tb.sv

# ★ram_40x47 不做 inline elaborate —— 单独处理，禁止从 TLBuffer_13 外推（codex 0151 D60）★
#
# 结论：**保持 ram_40x47 为两侧对称黑盒**，不把 golden ram_40x47.sv 加进本表或
# RTL_GOLDEN_DEPS。三条独立理由：
#
# 1) 结构上必炸（静态可判，无需跑 FM）：golden ram_40x47 的地址口是 `input [5:0]
#    R0_addr/W0_addr`（6 位）而存储是 `reg [46:0] Memory[0:39]`（40 深），
#    2^6 = 64 > 40，24 个地址落在数组之外。
#    ★2026-09-14 本 owner 自己重跑了控制实验（ram_40x47.sv 同时进 FM_REF_SRCS 与
#    FM_IMPL_SRCS），实测链条成立，但把前一版注释的两处说法按实测改正：★
#      - 触发点只有 **1 个**，是组合读那行 `assign R0_data = R0_en ? Memory[R0_addr]
#        : 47'bx;`（ram_40x47.sv **:118**）；写那行 `Memory[W0_addr] <= W0_data;`
#        （**:102**）实测**没有**被报。前一版写「两处都是」且行号记成 :15/:31，都不对。
#      - 实测日志原文：`Warning: Index may take values outside array bound ...
#        (Signal: Memory Block: /ram_40x47 ... Line: 118) (FMR_ELAB-147)`
#        -> `Error: Unsuppressed RTL interpretation message(s) ... (FM-262)`
#        -> `Error: Failed to set top design to 'r:/WORK/L2TlbMissQueue' (FM-156)`
#        -> fm_shell rc=3，整个 SEC 中止（不是「跑出来结果差」，是根本 link 不起来）。
#    这就是 verif/vendor_boundary.tsv 里 ram_40x47 一行 body_rule 写
#    `regimeB=FORBIDDEN_oob_static_index` 的实测依据：那六条 array_*_ext 可以选
#    regimeB（两侧同时白盒）来把边界清零，本条不能选，只剩 regimeA（两侧对称黑盒）。
#    对照 TLBuffer_13 的 5 个 ram：depth=2 / addr 1 位 ⇒ 2^1 == 2，地址空间与深度
#    精确相等，越界在结构上不可能 —— 这才是那边 inline 安全的原因，与本目标无关，
#    故**不可外推**。（golden 全量 68 个 ram_* 中 58 个满足 2^addr_w==depth，10 个不满足。）
#
# 2) 没有可用的抑制杠杆：scripts/fm_eq.tcl 只设 `hdlin_unresolved_modules black_box`，
#    全仓没有任何 FMR_ELAB 消息降级/抑制配置，也不应为单个目标引入。
#
# 3) inline 会改变本目标证明的含义：重写核 rtl/memblock/L2TlbMissQueue.sv 是**有意**
#    把存储折叠成与 golden 同名的 ram_40x47 叶子并依赖它两侧都不展开的（见该文件
#    69-84 行自带注释）。拓扑两侧本就不同 —— ref 经 Queue40_L2TlbMQBundle 到
#    io_out_q/ram_ext（L2TlbMissQueue.sv:111 -> Queue40_L2TlbMQBundle.sv:169），
#    impl 自己直接例化 mem_ext（:114）。按设计名计数两侧各 1 个，
#    fm_verdict.py 的对称性判据（比 design 名实例条数、不比实例路径）已经满足。
#
# 当前状态（scripts/check_closure_symmetry.py --only L2TlbMissQueue 实测）：
#    ref_bbox = {'ram_40x47': 1}, impl_bbox = {'ram_40x47': 1} ⇒ SYMMETRIC。
#
# ★遗留待裁已了结（codex 0158 §1）★
#    reviewer 在 8 条路线里选了方案 1：把这批**非 2 的幂**的 golden RAM 模型逐条审定
#    登记为 `APPROVED_MEMORY_MACRO_MODEL`，按**精确 module 名 + golden 源码 hash** 绑定；
#    明确**不**建通用 ELAB-147 政策例外，也**不**让后缀或诊断文本本身授权任何东西。
#    ram_40x47 是第一条，已登记在 verif/vendor_boundary.tsv 表尾
#    （leaf_sha256=68dbc6df0bcb0aafe5bdf199e6241e5a744207d34db15af3dd7aa191413f9766）。
#    三项最小功能审查可复算，不是「我读过了」：
#        python3 scripts/audit_ram_memory_model.py --check
#      M1 memory-only：正文与 firtool 行为级 RAM 模板**逐字相等**（模板等价，不是关键字排除）；
#      M2 端口与读写行为和实现边界一致：两侧各 1 个例化、8 端口逐名相同、常量连接相同；
#      M3 父级不依赖越界地址：两侧 enq/deq 指针**归纳可证** ∈[0,39]（基例 0、归纳步 +1、
#         在 39 处被互斥守卫回卷），所以 2^6=64 与深度 40 之间那 24 个地址任何可达状态都取不到。
#    本 tb 另有逐拍运行期复核（addr_errors）把 M3 这条在 200k 拍 × 3 seed 上再钉一遍。
#
# ★入表不让任何东西转绿★（codex 0158 原文）：
#    "A clean native result, not registry membership, turns the target green."
#    入表只授权把同一个精确边界两侧对称黑盒；本目标的绿灯来自
#    `bash scripts/run_proof.sh L2TlbMissQueue L2TlbMissQueue` 的 clean native 结果本身。
FM_REF_DEPS_L2TlbMissQueue = Queue40_L2TlbMQBundle.sv
FM_MERGE_DUP = false
GOLDEN_SRCS = $(GOLDEN_RTL)/L2TlbMissQueue.sv \
              $(GOLDEN_RTL)/Queue40_L2TlbMQBundle.sv \
              $(GOLDEN_RTL)/ram_40x47.sv
# 老战役审计声明继承: proof_mode=assembly, 对称黑盒边界 = ram_40x47
FM_MODE = assembly
FM_ALLOWLIST ?= 1
FM_VARIANTS = L2TlbMissQueue

include ../../../scripts/ut_common.mk

# 这里**不再**自定义 simv 规则。原先本文件有一条 override:
#     simv: ...; $(VCS) +define+SYNTHESIS $(RTL_SRCS) $(GOLDEN_SRCS) $(TB_SRCS) ...
# 它直接编 $(RTL_SRCS)（原文件，wrapper 与 golden 同名）而不是 ut_gen/ 里派生出的
# _xs 副本，于是 tb 例化的 L2TlbMissQueue_xs 根本不存在：
#     Error-[CFCILFBI] Cannot find cell 'L2TlbMissQueue_xs' in liblist
# ——也就是说这个 UT 从来没有真正编译通过过（make 只打一行
# "warning: overriding recipe for target 'simv'" 就把公共规则顶掉了）。
# 删掉 override，改用 ut_common.mk 的公共规则（编 $(UT_SRCS)）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
