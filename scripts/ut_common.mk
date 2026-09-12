# UT 通用 Makefile —— 各模块 verif/ut/<Module>/Makefile include 本文件
#
# 模块 Makefile 需定义：
#   MODULE          模块名（仅用于打印）
#   RTL_SRCS        重写 SV 源文件（单文件规范：核 + golden 同名 wrapper 同文件；
#                   含依赖的 rtl/common 辅助件与兄弟核文件）
#   TB_SRCS         testbench 源文件（顶层模块名须为 tb）
#   GOLDEN_SRCS     UT 双例化比对所需的 golden RTL 文件列表
#   FM_VARIANTS     做 FM 等价的 golden 顶层名列表，如 "WrBypass WrBypass_32"
#   FM_REF_DEPS_<名> 该变体在 golden 侧的依赖文件（相对 GOLDEN_RTL 的文件名）
#
# UT 侧编译的是 ut_gen/ 下由 derive_ut_impl.py 派生的 _xs 副本（重写文件里的
# golden 同名 wrapper 改名 <名>_xs，避免与 golden 撞名）；tb 可例化 xs_*_core
# （参数化核直测）或 <名>_xs（连 wrapper 一起测）。FM 侧用原文件（ref/impl
# 分容器，不撞名），wrapper 的接线正确性由 FM 覆盖。

XSSV_HOME ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

export VCS_ARCH_OVERRIDE := linux

VCS      := vcs -full64 -sverilog -timescale=1ns/1ps -kdb -lca \
            -debug_access+all +lint=TFIPC-L -l compile.log
SEED     ?= 1
# 拍数：CONVENTIONS 要求每 seed >= 100k 拍。各 tb 自带的默认值参差（实测 Alu/
# VSetRiWi/VSetRvfWvf 20k、SRAMTemplate/TageTable 40k、SyncDataModule/WrBypass 50k），
# 全都低于标准，且没有一个 Makefile 覆盖过——意味着这些目标的 UT 验收是在不达标的
# 拍数下过的。这里统一由 ut_common 下发，**按构造**满足标准，不依赖谁记得加 plusarg。
# tb 若不读 +ncycles 则该参数被忽略，无副作用。
NCYCLES  ?= 200000
SIM_ARGS ?= +ncycles=$(NCYCLES)

UT_GEN_DIR := ut_gen
UT_SRCS    := $(addprefix $(UT_GEN_DIR)/,$(notdir $(RTL_SRCS)))
# RTL_GOLDEN_DEPS: golden 行为模型/闭包（不 derive 不改名, UT 两侧共用同一定义;
# FM 时并入 impl 侧与 ref 侧同源 elaborate）。模块 Makefile 可选定义。
RTL_GOLDEN_DEPS ?=

.PHONY: compile run verdi fm clean derive

derive $(UT_SRCS): $(RTL_SRCS) $(XSSV_HOME)/scripts/derive_ut_impl.py
	python3 $(XSSV_HOME)/scripts/derive_ut_impl.py --out $(UT_GEN_DIR) $(RTL_SRCS)

compile: simv

simv: $(UT_SRCS) $(TB_SRCS) $(GOLDEN_SRCS) $(RTL_GOLDEN_DEPS)
	$(VCS) $(UT_SRCS) $(RTL_GOLDEN_DEPS) $(GOLDEN_SRCS) $(TB_SRCS) -top tb -o simv

run: simv
	./simv +ntb_random_seed=$(SEED) $(SIM_ARGS) -l sim_$(SEED).log
	@grep -q "TEST PASSED" sim_$(SEED).log && echo "=== UT PASSED ($(MODULE) seed=$(SEED)) ===" \
		|| { echo "=== UT FAILED ($(MODULE) seed=$(SEED)) ==="; exit 1; }

verdi:
	verdi -ssf novas.fsdb -nologo &

# 每个变体一次 FM 比对：ref = golden 变体及其依赖，impl = 重写原文件（含 wrapper）
fm: $(addprefix fm-,$(FM_VARIANTS))
ifeq ($(strip $(FM_VARIANTS)),)
	@echo "ERROR($(MODULE)): 'make fm' 无 FM_VARIANTS —— 未证明任何东西(禁止空目标绿灯)"; false
else
	@echo "=== FM all variants passed ($(MODULE)) ==="
endif

# FM_MODE 默认 signoff-strict。判定权威 = fm_verdict.py(fail-closed)。
FM_MODE ?= $(if $(FM_INTERFACE_ONLY),assembly,signoff-strict)
FM_ALLOWLIST ?= 0
# sidecar native-facts 采集（codex 0139 §3.2）：每次 proof 绑定 run id；
# 证据目录 fm_work/<top>/sidecar/ 含 native_facts.json + appvar readback + 脚本字节快照。
# 必须用 := 一次求值：递归展开会让 fm_shell 阶段与 receipt 阶段各取一次时间戳，
# 秒数一跳就被 run_id 绑定判为"捡到别次的 facts"。
FM_RUN_ID := $(if $(FM_RUN_ID),$(FM_RUN_ID),$(MODULE)-$(shell date -u +%Y%m%dT%H%M%SZ)-$(shell git -C $(XSSV_HOME) rev-parse --short HEAD 2>/dev/null || echo nogit))

fm-%:
	@mkdir -p fm_work/$*/sidecar
	@rm -rf fm_work/$*/sidecar && mkdir -p fm_work/$*/sidecar
	@echo "=== FM: $* (mode=$(FM_MODE)) ==="
	FM_TOP=$* \
	FM_MODE=$(FM_MODE) \
	FM_REF_SRCS="$(GOLDEN_RTL)/$*.sv $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_$*))" \
	FM_IMPL_SRCS="$(abspath $(RTL_SRCS) $(RTL_GOLDEN_DEPS))" \
	$(if $(FM_MERGE_DUP),FM_MERGE_DUP=$(FM_MERGE_DUP),) \
	$(if $(FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS),FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=$(FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS),) \
	$(if $(FM_INTERFACE_ONLY),FM_INTERFACE_ONLY="$(FM_INTERFACE_ONLY)",) \
	$(if $(wildcard fm_map/$*.txt),FM_FIELD_MAP=$(abspath fm_map/$*.txt),) \
	$(if $(wildcard fm_pins_pre.tcl),FM_PIN_PRE_TCL=$(abspath fm_pins_pre.tcl),) \
	$(if $(wildcard fm_pins.tcl),FM_PIN_TCL=$(abspath fm_pins.tcl),) \
	FM_SIDECAR_OUT=$(abspath fm_work/$*/sidecar) \
	FM_RUN_ID=$(FM_RUN_ID) \
	fm_shell -64 -work_path fm_work/$* -file $(XSSV_HOME)/scripts/fm_eq.tcl \
	    > fm_work/$*/fm.log 2>&1; \
	rc=$$?; \
	v=$$(XSSV_HOME=$(XSSV_HOME) python3 $(XSSV_HOME)/scripts/fm_verdict.py fm_work/$*/fm.log --rc $$rc --mode $(FM_MODE) --top $* --allowlist $(FM_ALLOWLIST) \
	    $(if $(wildcard $(XSSV_HOME)/verif/dead_ref/$*.json),--dead-ref $(XSSV_HOME)/verif/dead_ref/$*.json --unread-points fm_work/$*/unread_points.txt,) \
	    --bbox-report fm_work/$*/black_boxes.rpt \
	    $(if $(wildcard $(XSSV_HOME)/verif/allow/$*.json),--allow $(XSSV_HOME)/verif/allow/$*.json,) \
	    --canonical-id "$$(cat $(G1_CANONICAL)/CANONICAL_ID.txt)" \
	    --impl-commit "$$(git -C $(XSSV_HOME) rev-parse HEAD)"); \
	vrc=$$?; echo "$$v"; \
	XSSV_HOME=$(XSSV_HOME) python3 $(XSSV_HOME)/scripts/make_receipt.py --top $* --workdir fm_work/$* \
	    --ref-srcs "$(GOLDEN_RTL)/$*.sv $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_$*))" \
	    --impl-srcs "$(abspath $(RTL_SRCS) $(RTL_GOLDEN_DEPS))" \
	    --mode $(FM_MODE) --allowlist $(FM_ALLOWLIST) \
	    --vmucp "$(if $(FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS),$(FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS),false)" \
	    --rc $$rc --verdict "$$v" --expect-run-id "$(FM_RUN_ID)" \
	    --parent-commit "$$(git -C $(XSSV_HOME) rev-parse HEAD)" || exit 1; \
	exit $$vrc

clean:
	rm -rf simv* csrc *.log ucli.key novas.* verdiLog fm_work ut_gen *.fsdb *.daidir \
	       vc_hdrs.h formality* fm_shell_command.log* *.fdc default.svf
