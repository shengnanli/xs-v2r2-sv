# UT 通用 Makefile —— 各模块 verif/ut/<Module>/Makefile include 本文件
#
# 模块 Makefile 需定义：
#   MODULE          模块名（仅用于打印）
#   RTL_SRCS        手写 SV 源文件（参数化核心 + 依赖的公共模块）
#   WRAPPER_SRCS    变体包装文件（golden 同名模块，仅 FM 用，不进 UT 编译）
#   TB_SRCS         testbench 源文件（顶层模块名须为 tb）
#   GOLDEN_SRCS     UT 双例化比对所需的 golden RTL 文件列表
#   FM_VARIANTS     做 FM 等价的 golden 顶层名列表，如 "WrBypass WrBypass_32"
#   FM_REF_DEPS_<名> 该变体在 golden 侧的依赖文件（相对 GOLDEN_RTL 的文件名）
#   FM_REF_ABS_<名>  该变体 golden 侧依赖的**绝对路径**（不加 GOLDEN_RTL 前缀）；
#                    用于 repo 内的 canonical 接口桩(如 Composer predictor_stubs.sv,
#                    由 golden 头生成、两侧同读)——signoff 把 GOLDEN_RTL 外部化为 G0
#                    后 repo 文件无法用 GOLDEN_RTL-相对路径寻址，故走绝对路径。默认空。

XSSV_HOME ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
GOLDEN_RTL ?= $(XSSV_HOME)/golden/chisel-rtl

export VCS_ARCH_OVERRIDE := linux

VCS      := vcs -full64 -sverilog -timescale=1ns/1ps -kdb -lca \
            -debug_access+all +lint=TFIPC-L -l compile.log
SEED     ?= 1
SIM_ARGS ?=

.PHONY: compile run verdi fm clean

compile: simv

simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) $(RTL_SRCS) $(GOLDEN_SRCS) $(TB_SRCS) -top tb -o simv

run: simv
	./simv +ntb_random_seed=$(SEED) $(SIM_ARGS) -l sim.log
	@grep -q "TEST PASSED" sim.log && echo "=== UT PASSED ($(MODULE)) ===" \
		|| { echo "=== UT FAILED ($(MODULE)) ==="; exit 1; }

verdi:
	verdi -ssf novas.fsdb -nologo &

# 每个变体一次 FM 比对：ref = golden 变体及其依赖，impl = 手写核心 + 包装层
fm: $(addprefix fm-,$(FM_VARIANTS))
ifneq ($(strip $(FM_BB_TARGET)),)
	@$(MAKE) --no-print-directory $(FM_BB_TARGET)
else ifeq ($(strip $(FM_VARIANTS)),)
	@echo "ERROR($(MODULE)): 'make fm' 既无 FM_VARIANTS 也无 FM_BB_TARGET —— 未证明任何东西(禁止空目标绿灯)"; false
else
	@echo "=== FM all variants passed ($(MODULE)) ==="
endif

# FM_MODE 默认: 有 FM_INTERFACE_ONLY(声明对称黑盒)⇒assembly, 否则 signoff-strict。
# 模块 Makefile 可显式覆盖 FM_MODE / FM_ALLOWLIST。判定权威 = fm_verdict.py(fail-closed),
# 非旧的裸 grep(那会被 Formality 回显的 Tcl 源码骗成假绿)。
FM_MODE ?= $(if $(FM_INTERFACE_ONLY),assembly,signoff-strict)
FM_ALLOWLIST ?= 0

fm-%:
	@mkdir -p fm_work/$*
	@echo "=== FM: $* (mode=$(FM_MODE)) ==="
	FM_TOP=$* \
	FM_MODE=$(FM_MODE) \
	FM_REF_SRCS="$(GOLDEN_RTL)/$*.sv $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_$*)) $(FM_REF_ABS_$*)" \
	FM_IMPL_SRCS="$(abspath $(RTL_SRCS) $(WRAPPER_SRCS))" \
	$(if $(FM_MERGE_DUP),FM_MERGE_DUP=$(FM_MERGE_DUP),) \
	$(if $(FM_INTERFACE_ONLY),FM_INTERFACE_ONLY="$(FM_INTERFACE_ONLY)",) \
	$(if $(wildcard fm_map/$*.txt),FM_FIELD_MAP=$(abspath fm_map/$*.txt),) \
	$(if $(wildcard fm_pins_pre.tcl),FM_PIN_PRE_TCL=$(abspath fm_pins_pre.tcl),) \
	$(if $(wildcard fm_pins.tcl),FM_PIN_TCL=$(abspath fm_pins.tcl),) \
	fm_shell -64 -work_path fm_work/$* -file $(XSSV_HOME)/scripts/fm_eq.tcl \
	    > fm_work/$*/fm.log 2>&1; \
	rc=$$?; \
	if [ -n "$$FM_SIDECAR_OUT" ]; then echo $$rc > "$$FM_SIDECAR_OUT/fm_shell.rc"; fi; \
	python3 $(XSSV_HOME)/scripts/fm_verdict.py fm_work/$*/fm.log --rc $$rc --mode $(FM_MODE) --top $* --allowlist $(FM_ALLOWLIST)

clean:
	rm -rf simv* csrc *.log ucli.key novas.* verdiLog fm_work *.fsdb *.daidir \
	       vc_hdrs.h formality* fm_shell_command.log* *.fdc default.svf
