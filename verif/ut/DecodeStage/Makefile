# DecodeStage —— 译码级（6 个 DecodeUnit + DecodeUnitComp + VTypeGen 的父层，粘合逻辑）
#
# 子模块闭包全部**两侧共用 golden 定义**（RTL_GOLDEN_DEPS）：DecodeUnit / VTypeGen 本轮尚未
# 重写（三轴表 MISSING），DecodeUnitComp 虽已重写并单独签核（verif/ut/DecodeUnitComp），
# 但本目标只证 DecodeStage 这一层的粘合逻辑，子模块在 UT 里两侧同一份定义、在 FM 里
# ref 侧走 FM_REF_DEPS、impl 侧走同一批 golden 文件，两侧完整 elaborate、无黑盒。
# 于是本目标的"绿"是**条件绿**：DecodeStage 粘合逻辑与 golden 等价，子模块的正确性
# 由它们各自的签核负责（DecodeUnit / VTypeGen 待做）。
MODULE = DecodeStage

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/DecodeStage.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/DecodeStage.sv

# 子模块闭包（golden 文件，两侧共用）：
#   DecodeUnit -> FPDecoder, UopInfoGen -> strdiedLSNumOfUopTable, indexedLSNumOfUopTable
#   DecodeUnitComp -> VecExceptionGen, indexedLSUopTable_1..7
#   VTypeGen -> VsetModule
CHILD_CLOSURE = DecodeUnit.sv FPDecoder.sv UopInfoGen.sv strdiedLSNumOfUopTable.sv \
  indexedLSNumOfUopTable.sv DecodeUnitComp.sv VecExceptionGen.sv \
  indexedLSUopTable_1.sv indexedLSUopTable_2.sv indexedLSUopTable_3.sv indexedLSUopTable_4.sv \
  indexedLSUopTable_5.sv indexedLSUopTable_6.sv indexedLSUopTable_7.sv \
  VTypeGen.sv VsetModule.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(CHILD_CLOSURE))

FM_VARIANTS = DecodeStage
FM_REF_DEPS_DecodeStage = $(CHILD_CLOSURE)

# merge_dup=false 是加强不是放宽：golden 的 last_REG/last_REG_1 与 frontendStall/backendStall
# 打拍寄存器 D 端相同；关掉合并让两侧寄存器 1:1 对应（fm_predict 的 passing 模型也只在
# merge_dup=false 下成立）。
FM_MERGE_DUP = false

# vmucp = 加强证明（让 FM 真的去比 matched-unread 点），不是放宽。
# 对称死位 = golden last_REG / last_REG_1（XSPerfAccumulate 的 GatedValidRegNext 多出的一份，
# 只喂 _probe 观测线，cone-dead），可读核对称保留为 frontendStall_probe_q / backendStall_probe_q，
# 由 fm_pins.tcl 消名差后实比。依据与白名单条目见 verif/fm_target_config/DecodeStage.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2，两侧统一定义 SYNTHESIS，
# 把断言段与随机初值段一起关掉。
VCS += +define+SYNTHESIS

# 两档 initreg：编译期打开机制，运行期 +vcs+initreg+random（默认）或 +0（run-initreg0）。
# 本模块无复位寄存器（trapInstInfo 的 RegNext、perf 两级打拍）每拍都写，两拍后必然一致；
# 子模块 DecodeUnitComp 的锁存寄存器无复位、只在 in.fire 时写，两例化各自一份 golden 副本
# 在 +random 下初值不同，tb 用 WARMUP 拍定向喂复杂指令让它锁存一次再开比对，所以两档都必须 errors=0。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+random

.PHONY: run-initreg0 gen
run-initreg0:
	$(MAKE) run SEED=$(SEED) SIM_ARGS="+ncycles=$(NCYCLES) +vcs+initreg+0"

gen:
	python3 gen.py
