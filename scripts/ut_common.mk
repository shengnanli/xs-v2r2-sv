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

.PHONY: compile run verdi fm clean derive portlint

# ---------------------------------------------------------------------------
# 端口契约闸（codex 0145 决策三）：**UT 之前**必须过 G1 端口契约 lint。
#
# 核对对象 = FM_VARIANTS 里每个 golden 顶层名 vs RTL_SRCS 里的同名 wrapper，
# 逐项比端口集合/方向/packed 维/unpacked 维/总位宽（判据见 port_contract_lint.py）。
#
# 为什么用 FM_VARIANTS 判定"本 UT 是否适用"：FM_VARIANTS 就是本 UT 声称要证明的
# golden 顶层集合——有它才有"golden 同名模块"这个对位对象。FM_VARIANTS 为空的 UT
# （纯学习用例 / 家族聚合 tb）本来就不对任何 golden 模块下断言，没有契约可核；而且
# 下面的 `fm` 目标本身就拒绝空 FM_VARIANTS，所以"清空 FM_VARIANTS 绕闸"是自断签核
# 路，不构成后门。这里仍然打一行显式 SKIP，别让它悄悄溜过去。
#
# PORTLINT_EXTRA_SRCS：极少数 wrapper 不在 RTL_SRCS 里（例如被别处 include）时，
# 由模块 Makefile 补充搜索范围。它只能**扩大**搜索范围，不能放宽任何判据。
# PORTLINT_ORDER：warn（默认）/ fail —— 端口顺序不一致的处置。
PORTLINT_EXTRA_SRCS ?=
PORTLINT_ORDER      ?= warn
PORTLINT_CMD = python3 $(XSSV_HOME)/scripts/port_contract_lint.py \
               --order $(PORTLINT_ORDER) \
               $(addprefix --impl-src ,$(abspath $(RTL_SRCS) $(PORTLINT_EXTRA_SRCS))) \
               $(FM_VARIANTS)

portlint:
ifeq ($(strip $(FM_VARIANTS)),)
	@echo "[SKIP] portlint($(MODULE)): FM_VARIANTS 为空 —— 本 UT 不对任何 golden 顶层"
	@echo "       下断言，没有端口契约可核。显式 SKIP，**不产生任何 signoff receipt**"
	@echo "       （codex 0146）；fm / fm-% 目标也一并拒绝空 or 未声明的顶层。"
else
	@echo "=== portlint: $(MODULE) [$(FM_VARIANTS)] ==="
	@$(PORTLINT_CMD) || { \
	  echo "=== PORTLINT FAILED ($(MODULE)) —— 端口契约与 G1 golden 不一致，UT 前置闸拦下 ==="; \
	  exit 1; }
endif

# ★ derive 必须每次都跑，不能靠 mtime 判新旧 ★
# 教训（2026-09-12，两位 owner 各自独立踩到）：原规则是 `derive $(UT_SRCS): $(RTL_SRCS)`，
# 而 simv 依赖真实文件 $(UT_SRCS)。git checkout / git stash pop / 从备份还原都会让
# RTL 源文件 mtime **倒退**，make 于是认为 ut_gen/ 更新、跳过派生 ——
# **UT 就在一份不再对应源码的副本上报 errors=0**。
# 实测：全仓 213 份派生文件里 28 份与源码不一致，其中 4 份有实质（非注释）差异，
# 包括被 41 个变体共用的 xs_SRAMTemplate_core.sv（138 行）。
# 修法：derive 改为 simv 的 order-only 前置（每次必跑），配合 derive_ut_impl.py
# 的幂等写入（内容不变不碰文件），既杜绝陈旧又不会每次重链。
derive $(UT_SRCS): $(RTL_SRCS) $(XSSV_HOME)/scripts/derive_ut_impl.py
	python3 $(XSSV_HOME)/scripts/derive_ut_impl.py --out $(UT_GEN_DIR) $(RTL_SRCS)

compile: simv

# order-only 依赖：portlint 在 simv 的配方之前**总是**跑（含 -j 并行），但不会因为
# 它是 .PHONY 就把 simv 判成过期而反复重新链接。`make compile` / `make run` 都会
# 经过这道闸。
#
# GOLDEN_SRCS 与 RTL_GOLDEN_DEPS 会重叠（厂商 SRAM 宏、ClockGate 这类两侧共读的
# 文件经常两边都列了一遍）。同一个文件在 VCS 命令行上出现两次 = 同一个 module
# 被声明两次，VCS 报 `Warning-[OPD] Override previous declaration`。
# 实测 12 个 UT 中招，共 116 处（SRAMTemplate 32、ICacheDataArray 14、
# SRAMTemplateNewForm/SplittedSRAMTemplate 各 12 …）。这类噪声的害处不是它本身，
# 而是它把编译日志的信噪比压低到"警告一律略过"，真警告就藏在里面了。
# ★在这里去重，不去改各 UT 的 Makefile★：其中好几个（SRAMTemplate 家族、
# TLBuffer 家族）是生成产物，手改会被下一次跑生成器静默删掉——本轮已经踩过两次。
# 用 filter-out 而不是 $(sort)：sort 会重排，而源文件顺序在 SV 里不是无关紧要的。
GOLDEN_SRCS_UNIQ = $(filter-out $(RTL_GOLDEN_DEPS),$(GOLDEN_SRCS))

simv: $(UT_SRCS) $(TB_SRCS) $(GOLDEN_SRCS) $(RTL_GOLDEN_DEPS) | portlint derive
	$(VCS) $(UT_SRCS) $(RTL_GOLDEN_DEPS) $(GOLDEN_SRCS_UNIQ) $(TB_SRCS) -top tb -o simv

# 两轮 initreg 的日志原先同名 sim_$(SEED).log —— 后跑的那轮把前一轮**静默覆盖**，
# 于是"两轮都绿"这件事在磁盘上永远只剩一轮的证据，事后没法复核。
# 2026-09-17 实测：NCBTransactionQueue 目录里三个 sim_<seed>.log 全是 +vcs+initreg+0
# 那轮的，+random 那轮的日志已经不在了。
# ★做法是"多留一份"而不是"改名"★：原名保持不变（各 lane 的脚本还在 grep 它，
# 而且现在有 5 条 lane 正在跑，改名会凭空制造失败），额外按轮次存一份副本，
# 两轮的证据从此并存。没带 initreg 参数时不产生副本，行为完全不变。
INITREG_TAG = $(if $(findstring +vcs+initreg+random,$(SIM_ARGS)),_initregrandom,$(if $(findstring +vcs+initreg+0,$(SIM_ARGS)),_initreg0,))

# ★跑之前先删掉两个名字★（2026-09-17，BloomFilter lane 指出的交互）
# 「多留一份副本」和「每次先删日志」这两条规矩天然打架：留副本是为了让两轮证据并存，
# 先删是为了让**编译失败时读不到上一轮的日志**（变异 harness 的命门 —— 编不过却读到
# 上一个变异的 errors，就会记成假 CAUGHT，IBuffer M6 实测栽过）。
# 只删 sim_$(SEED).log 的话，带 tag 的那份会留着；哪天谁把 harness 改成读带 tag 的名字
# （"名字更清楚"是很自然的想法），那个洞就原样回来了。所以两个名字一起删，
# 让"读到陈旧日志"这件事在**任何**读法下都不可能发生。
run: simv
	@rm -f sim_$(SEED).log $(if $(INITREG_TAG),sim_$(SEED)$(INITREG_TAG).log,)
	./simv +ntb_random_seed=$(SEED) $(SIM_ARGS) -l sim_$(SEED).log
	@$(if $(INITREG_TAG),cp -f sim_$(SEED).log sim_$(SEED)$(INITREG_TAG).log,:)
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

# codex 0146：FM_VARIANTS 为空只能显式 SKIP，**不能产生 signoff receipt**。
# 上面的 `fm` 目标已经拒绝空 FM_VARIANTS；这里把同一条规矩钉到 fm-% 上，堵住
# 直接 `make fm-<某个没声明的顶层>` 绕过去、却照样生成 receipt 的路。
# 合法用法（`fm` 展开出来的、或手工重跑某个已声明变体）不受影响。
fm-%:
	@case " $(strip $(FM_VARIANTS)) " in \
	  *" $* "*) ;; \
	  *) echo "ERROR($(MODULE)): '$*' 不在 FM_VARIANTS='$(FM_VARIANTS)' 里 ——" \
	          "未声明的顶层不许出 receipt（codex 0146）"; exit 1;; \
	esac
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
	    < /dev/null > fm_work/$*/fm.log 2>&1; \
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
