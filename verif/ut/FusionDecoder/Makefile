# FusionDecoder —— 宏指令融合译码器（DecodeStage 的 child，看相邻两条指令是否可融合）
#
# 无子模块、无黑盒：impl 只有 rtl/backend/FusionDecoder.sv（package + xs_FusionDecoder_core
# + golden 同名 wrapper），ref 只有 golden FusionDecoder.sv。
MODULE = FusionDecoder

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/FusionDecoder.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FusionDecoder.sv

FM_VARIANTS = FusionDecoder
FM_REF_DEPS_FusionDecoder =

# merge_dup=false 是加强不是放宽：golden 每对里 lastFire/REG 是两个 D 端相同的
# RegNext(fire)，rs2FromRs1_r/rs2FromRs2_r 也是两份相同寄存器；关掉合并让两侧
# 寄存器 1:1 对应（fm_predict 的 passing 模型也只在 merge_dup=false 下成立）。
FM_MERGE_DUP = false

# vmucp = 加强证明（让 FM 真的去比 matched-unread 点），不是放宽。
# 对称死位 = 每对的 lastFire / fireDelayed_perf（golden lastFire_i / REG_i），
# XSPerfAccumulate 的打拍寄存器，本配置下无读者；两侧对称保留，FM 按名（auto match +
# fm_pins.tcl 消名差）1↔1 配上后实比。依据与白名单条目见 verif/fm_target_config/FusionDecoder.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

# 端口顺序也当硬闸（wrapper 与 golden 端口表逐位同序）
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2，两侧统一定义 SYNTHESIS，
# 把断言段与随机初值段一起关掉。
VCS += +define+SYNTHESIS

# 两档 initreg：编译期打开机制，运行期 +vcs+initreg+random（默认）或 +0（run-initreg0）。
# 本模块的流水寄存器（fusionVec/notHint/enabled/lsrc2Mux_q …）全部无复位且直接可见于输出，
# 两例化在 +random 下初值不同；tb 用 WARMUP 拍全 valid/全 ready 让 5 对都 fire 一次把
# 它们写定，之后才开比对窗口，所以两档都必须 errors=0。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+random

.PHONY: run-initreg0 gen
run-initreg0:
	$(MAKE) run SEED=$(SEED) SIM_ARGS="+ncycles=$(NCYCLES) +vcs+initreg+0"

gen:
	python3 gen.py
