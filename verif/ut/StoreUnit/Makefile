# StoreUnit —— store 地址流水（s0 选源 → s1 TLB → s2 PMP → s3/sx 写回；MemBlock 里 2 条同一模块）
#
# 子模块只有 MemTrigger_3（storeTrigger，本 lane 先行重写签核；核与 LOAD 变体共用 rtl/memblock/MemTrigger.sv）：
# UT 里 impl 侧用重写件（派生成 MemTrigger_3_xs），golden 侧用 golden 文件；FM 两侧都白盒 elaborate
# （ref 走 FM_REF_DEPS 的 golden MemTrigger_3.sv，impl 走 RTL_SRCS 里的重写件）。
# rtl/memblock/StoreUnit.sv 的 GENERATED 段与本目录 tb.sv 由 scripts/gen_storeunit.py 生成（`make gencheck`）。
MODULE = StoreUnit

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/MemTrigger.sv \
           $(RTL_DIR)/memblock/MemTrigger_3.sv \
           $(RTL_DIR)/memblock/StoreUnit.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/StoreUnit.sv $(GOLDEN_RTL)/MemTrigger_3.sv

FM_VARIANTS = StoreUnit
FM_REF_DEPS_StoreUnit = MemTrigger_3.sv

# 关掉 merge_duplicated_registers：golden 有三份同源的 RegNext(~s1_tlb_miss) 等重复寄存器，
# 逐个比而不是合并后比；也让 fm_predict 的 passing 模型严格适用。
FM_MERGE_DUP = false

# ★vmucp：依据与复核判据见 verif/fm_target_config/StoreUnit.tcl★ —— 84 个两侧对称的死位
# （vecBaseVaddr / vecVaddrOffset 高 39 位、fuOpType 4 位、perf / 断言专用寄存器 2 位），FM 按名 matched_nc。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段（随机初值 / 断言）两侧统一关掉。
# 各级流水寄存器（s1_in / s2_in / s3_in / sx_in_1 等）不复位：非常量 initreg 档两个实例各摇各的初值，
# 先跑 WARMUP 拍（全部被写过）再比；常量档（+0 / +1）两侧同初态，从第 0 拍比。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= +vcs+initreg+random
WARMUP  ?= $(if $(filter +vcs+initreg+0 +vcs+initreg+1,$(INITREG)),0,3000)
SIM_ARGS += $(INITREG) +warmup=$(WARMUP)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_storeunit.py --check
