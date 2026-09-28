MODULE = LoadMisalignBuffer

# LoadMisalignBuffer —— 跨 16B 非对齐 load 的拆分 / 重发 / 拼接缓冲（单条目，叶子模块，无子模块）。
# rtl/memblock/LoadMisalignBuffer.sv 的 GENERATED 段与本目录 tb.sv 由 scripts/gen_lmisalign.py
# 生成（`make gencheck`）；激励 / 比对口径 / 覆盖判据见 tb_template.py 文件头。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/LoadMisalignBuffer.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/LoadMisalignBuffer.sv

FM_VARIANTS = LoadMisalignBuffer
FM_REF_DEPS_LoadMisalignBuffer =

# 关掉 merge_duplicated_registers：让 fm_predict 的 passing 模型严格适用（加强不是放宽）。
FM_MERGE_DUP = false

# vmucp（加强不是放宽）：145 个两侧对称的死位（REG / splitLoadReqs_*_uop_fuOpType[8:2] /
# splitLoadResp_*_data[128:64]），依据与六条证据见 verif/fm_target_config/LoadMisalignBuffer.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段（随机初值 / 断言）两侧统一关掉，与 FM 口径一致。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。三档：
#   INITREG=0 / 1       常量档，两侧初态相同，从复位后第一拍就比（+gate_req=0）；
#   INITREG=random      种子取自 +ntb_random_seed（seed 1 退化成全 1，见 CONVENTIONS）；
#   INITREG=<n>         显式数值种子（本 lane 用 <seed>017），与 ntb 种子无关的真随机档。
#   后两档 req 整包寄存器（不复位）两侧初值不同，从第一次入队的下一拍才开始比（+gate_req=1）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
GATE_REQ ?= $(if $(filter 0 1,$(INITREG)),0,1)
SIM_ARGS += +vcs+initreg+$(INITREG) +gate_req=$(GATE_REQ)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_lmisalign.py --check
