# MainPipe —— DCache 主流水（store / AMO / probe / refill 的 s0-s3 读改写流水）
#
# 单文件规范：package mainpipe_pkg + xs_MainPipe_core + golden 同名 wrapper 都在
# rtl/memblock/MainPipe.sv 里（io 类型 / 核端口表 / wrapper 由本目录 gen_mainpipe.py 生成）。
# 子模块两个，都是本工程已签核的可读重写件，放 RTL_GOLDEN_DEPS：不 derive、不改名，
# golden MainPipe 与派生出的 MainPipe_xs 例化同一份定义（UT 两侧对称，只比 MainPipe 本体）；
# FM 侧 ref 走 golden 的 Arbiter4_MainPipeReq.sv / AMOALU.sv（FM_REF_DEPS），impl 走可读件，
# 两侧都完整 elaborate、无黑盒。
# 注意：golden 里的 MainPipe_1 / MainPipe_5 是 L2（CoupledL2）的主流水，与本目标无关。
MODULE = MainPipe

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/MainPipe.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/MainPipe.sv

RTL_GOLDEN_DEPS = \
  $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
  $(RTL_DIR)/memblock/Arbiter4_MainPipeReq.sv \
  $(RTL_DIR)/memblock/AMOALU.sv

FM_VARIANTS = MainPipe
FM_REF_DEPS_MainPipe = Arbiter4_MainPipeReq.sv AMOALU.sv

# 关掉 merge_duplicated_registers：golden 有大量值恒等的多份打拍（24 份 status_dup、
# 5 份 RegNext(s0_fire)…），两侧照抄同样份数，逐个比；也让 fm_predict 模型严格适用。
FM_MERGE_DUP = false

# ★vmucp：依据见 verif/fm_target_config/MainPipe.tcl★ —— 81 个两侧对称死寄存器位
# （debug SC 计数、仿真断言打拍寄存器、只喂性能计数的字段…）加强为实比；其中名字不同的
# 16 个由 fm_pins_pre.tcl 在首次 match 前逐项配对。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2，两侧统一定义 SYNTHESIS。
# 两档 initreg：编译期打开机制，运行期 INITREG 选 +vcs+initreg+0 / +vcs+initreg+random。
# 不复位且常态可见的寄存器（lrsc_addr、AMO 结果寄存器、s3 各字段）由 tb 的确定性暖机写定。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

.PHONY: gencheck
gencheck:
	python3 gen_mainpipe.py --check
