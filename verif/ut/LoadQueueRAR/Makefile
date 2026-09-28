MODULE = LoadQueueRAR

# LoadQueueRAR（load→load RAR 违例检测队列）。golden 直接 child 2 个实例 / 2 种：
#   LqPAddrModule（本 lane 重写并签核，rtl/memblock/LqPAddrModule.sv；内含 72 个 0 级延迟件
#                  DelayN_225 / DelayNWithValid_4 / DelayNWithValid_7，均 PROVEN_DIRECT）
#   FreeList_3（rtl/memblock/FreeList.sv 家族共用核 xs_FreeList_core + 薄 wrapper FreeList_3.sv，PROVEN_DIRECT）
# 处置 = **两侧白盒**：ref 读 golden 同名件，impl 读本仓重写件，无黑盒。
# 证明的是"golden 整棵子树 == 重写整棵子树"。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/LoadQueueRAR.sv \
           $(RTL_DIR)/memblock/LqPAddrModule.sv \
           $(RTL_DIR)/memblock/FreeList.sv \
           $(RTL_DIR)/memblock/FreeList_3.sv \
           $(RTL_DIR)/common/xs_DelayN_core.sv \
           $(RTL_DIR)/common/xs_DelayNWithValid_core.sv \
           $(RTL_DIR)/common/DelayN_225.sv \
           $(RTL_DIR)/common/DelayNWithValid_4.sv \
           $(RTL_DIR)/common/DelayNWithValid_7.sv
TB_SRCS  = tb.sv

LQRAR_CHILDREN = LqPAddrModule.sv FreeList_3.sv \
                 DelayN_225.sv DelayNWithValid_4.sv DelayNWithValid_7.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/LoadQueueRAR.sv $(addprefix $(GOLDEN_RTL)/,$(LQRAR_CHILDREN))

FM_VARIANTS = LoadQueueRAR
FM_REF_DEPS_LoadQueueRAR = $(LQRAR_CHILDREN)

# 关掉 merge_duplicated_registers：与 LoadQueueRAW 同口径（只有关掉时 fm_predict 的
# passing 模型才严格适用）。这是加强不是放宽。
FM_MERGE_DUP = false

# vmucp（加强不是放宽）：唯一的 6 个 unread 点是 release2Cycle.paddr 打拍寄存器的 [5:0]，两侧对称死位，
# 依据与六条证据见 verif/fm_target_config/LoadQueueRAR.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 断言块调用未定义的 xs_assert_v2，与 FM 口径一致定义 SYNTHESIS。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
# 不复位寄存器里只有 ldLdViolationMask（RegEnable(req.valid)）会在"写过之前"被输出看到，
# tb 对 rep_frm_fetch 按"该流水首次 req.valid 之后"门控（见 tb.sv 文件头）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_lqrar.py --check
