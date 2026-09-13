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
#    2^6 = 64 > 40。白盒化后 Memory[W0_addr]（ram_40x47.sv:15）与
#    Memory[R0_addr]（:31）都是静态越界索引 ⇒ FMR_ELAB-147
#    "Index may take values outside array bound" -> FM-262 -> set_top 失败 FM-156。
#    另一 owner 的控制实验实测到的正是这条链。
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
# 遗留待裁：ram_40x47 不在 verif/vendor_boundary.tsv（该表当前只有 20 条 array_*_ext），
#    故 declare_allow.py 不会自动归 vendor_macro，assembly 声明仍落不了盘。
#    要么 reviewer 批准把 firtool 行为级存储叶子审定进 registry（新 kind），
#    要么本目标另寻证法。**本 owner 未自行扩表**（codex 0151 D60 明令不扩 vendor registry）。
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
