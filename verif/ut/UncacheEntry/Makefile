
MODULE = UncacheEntry

VARIANT_NAMES = UncacheEntry UncacheEntry_1 UncacheEntry_2 UncacheEntry_3 \
                UncacheEntry_4 UncacheEntry_5 UncacheEntry_6 UncacheEntry_7 \
                UncacheEntry_8 UncacheEntry_9 UncacheEntry_10 UncacheEntry_11 \
                UncacheEntry_12 UncacheEntry_13 UncacheEntry_14 UncacheEntry_15

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/xs_UncacheEntry_core.sv \
           $(addprefix $(RTL_DIR)/memblock/,$(addsuffix .sv,$(VARIANT_NAMES)))
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(VARIANT_NAMES)))

# 16 个变体都是自足叶子：golden 侧 0 子模块、0 厂商宏，故无 FM_REF_DEPS_*。
FM_VARIANTS = $(VARIANT_NAMES)

# ★FM_MERGE_DUP=false —— 依据是实测，不是预防性设置★
#
# 本模块有**两个函数完全相同**的寄存器：req_uop_flushPipe 与 req_uop_replayInst。
# 它们在 golden 里都没有输入端口（父级恒 0），firtool 把锁存写成
#   q <= _GEN & q          （_GEN = flush | ~io_req_valid）
# 两条一字不差，只是名字不同；重写核照抄了这两份。
#
# 开着 verification_merge_duplicated_registers（默认 true）时实测（首跑 fm.log）：
#   4938 matched by name / 82 by signature / **1(0) Unmatched reference**
#   Unmatched Objects: Registers ref 1 / impl 0，Constrained 0X ref 1 / impl 0
#   AUTO_MATCH_FAIL: r:/WORK/UncacheEntry/req_uop_replayInst_reg
#   -> 判定 PARTIAL（reason=strict_unmatched!=0），虽然 native 已经 SUCCEEDED。
# 即 impl 侧把这两个同函数寄存器合并成了一个、ref 侧没有（或合并结果不同），
# 于是 ref 的 replayInst 成了孤儿。这正是 CONVENTIONS「方向二：让工具去合并」
# 里 RenameBuffer / MulUnit 那一类。
#
# 关掉之后实测：unmatched 0(0)、passing 5020（未变）、failing 0、unread 0。
# ★这是加强不是放宽★：不黑盒、不跳点、不约束 ref，只是要求逐个而不是合并后比。
#
# 关掉后两侧对称地各留 2 个 `Not Compared / Constant reg`（就是上面这两个位）——
# FM 认定它们在 init-toggle 假设下恒定。两侧同为 2，没有单边吞点。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# ★必须在 include 之后★：ut_common.mk 用的是 `VCS := vcs ...`（简单赋值），
# 写在前面会被整根覆盖掉。
#
# golden 里 `ifndef SYNTHESIS 的两块东西必须关掉，口径才与 FM 一致
# （FM 两侧也都是 read_sverilog -define {SYNTHESIS}）：
#   1) XSError("LoadQueueUncache: You can not write an valid entry")
#      —— 调用未定义的 xs_assert_v2；而本 UT 的激励**故意**会在条目占用时再压一条
#      请求（那是 golden 这条断言所描述的场景，也是 req_valid/slaveAccept 优先级
#      唯一能被观测到的地方），不关掉它会满屏断言。
#   2) initial 随机化块；关掉后两侧无复位寄存器一致地起 X，再由 +vcs+initreg 统一给值。
VCS += +define+SYNTHESIS +vcs+initreg+random

# ★上电初值两轮都要跑★：本模块 golden 一条 entry 共 **203 个寄存器 / 1670 位**，
# 其中只有 **9 个寄存器 / 17 位在复位域**（req_valid 1 / slaveAccept 1 /
# uncacheState 2 / denied 1 / corrupt 1 / needFlushReg 1 / pendingld_last_REG 1 /
# pendingPtr_next_r_flag 1 + pendingPtr_next_r_value 8）；另外 **1653 位一个都不复位**
# （payload 190 个字段、slaveId、uncacheData、flushPipe、replayInst）。
# 这三个数由 reset_domain_check.py 从 golden 现场数出来并打印（不是抄来的）：
#     python3 reset_domain_check.py
# 只跑一种上电初值等于没验复位域。
#   make run SEED=1            # 随机上电值
#   make INITREG=0 run SEED=1  # 全 0 上电值
# initreg 的**取值**是运行期 plusarg，编译行上那个 +vcs+initreg+random 只是打开机制。
INITREG ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

# 生成器（核 + 16 个薄 wrapper + tb 全部由它产出）
.PHONY: gen gencheck
gen:
	python3 gen.py

gencheck:
	python3 gen.py --check
