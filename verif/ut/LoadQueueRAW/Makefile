MODULE = LoadQueueRAW

# LoadQueueRAW（store→load RAW 违例检测队列）。golden 直接 child 7 个实例 / 6 种：
#   LqPAddrModule_1 / LqMaskModule（本 lane 重写并签核，共用核 xs_LqRawDataCam_core）
#   FreeList_4（rtl/memblock/FreeList.sv 家族共用核 xs_FreeList_core + 薄 wrapper FreeList_4.sv）
#   DelayN_297 ×2 / DelayNWithValid_148 ×2 / DelayNWithValid_149 ×2
# 以及两块 CAM 阵列里的 DelayN_13 / DelayNWithValid_52 / _55 / _103。
# docs/coverage_three_axis.tsv 里这些件全部 PROVEN_DIRECT（CAM 两件由本 lane 签核，
# receipt evidence/341d7e6f14cf/）。处置 = **两侧白盒**：ref 读 golden 同名件，
# impl 读本仓重写件，无黑盒。证明的是"golden 整棵子树 == 重写整棵子树"。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/LoadQueueRAW.sv \
           $(RTL_DIR)/memblock/xs_LqRawDataCam_core.sv \
           $(RTL_DIR)/memblock/LqMaskModule.sv \
           $(RTL_DIR)/memblock/LqPAddrModule_1.sv \
           $(RTL_DIR)/memblock/FreeList.sv \
           $(RTL_DIR)/memblock/FreeList_4.sv \
           $(RTL_DIR)/common/xs_DelayN_core.sv \
           $(RTL_DIR)/common/xs_DelayNWithValid_core.sv \
           $(RTL_DIR)/common/DelayN_13.sv \
           $(RTL_DIR)/common/DelayN_297.sv \
           $(RTL_DIR)/common/DelayNWithValid_52.sv \
           $(RTL_DIR)/common/DelayNWithValid_55.sv \
           $(RTL_DIR)/common/DelayNWithValid_103.sv \
           $(RTL_DIR)/common/DelayNWithValid_148.sv \
           $(RTL_DIR)/common/DelayNWithValid_149.sv
TB_SRCS  = tb.sv

LQRAW_CHILDREN = LqPAddrModule_1.sv LqMaskModule.sv FreeList_4.sv \
                 DelayN_13.sv DelayN_297.sv \
                 DelayNWithValid_52.sv DelayNWithValid_55.sv DelayNWithValid_103.sv \
                 DelayNWithValid_148.sv DelayNWithValid_149.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/LoadQueueRAW.sv $(addprefix $(GOLDEN_RTL)/,$(LQRAW_CHILDREN))

FM_VARIANTS = LoadQueueRAW
FM_REF_DEPS_LoadQueueRAW = $(LQRAW_CHILDREN)

# 关掉 merge_duplicated_registers：golden 有大量值恒等的多份结构（每个选择组一份
# RegNext(io.redirect)、CAM 阵列里每 bank 一份写数据），合并后两侧幸存者可能不同；
# 且只有关掉时 fm_predict 的 passing 模型才严格适用。这是加强不是放宽。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 断言块调用未定义的 xs_assert_v2，与 FM 口径一致定义 SYNTHESIS。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
# 不复位寄存器（uop 阵列、选择树 bits、store 打拍、CAM 阵列）在 +random 档两侧初值不同，
# tb 只在"该寄存器至少被写过一次"之后才比对依赖它的输出（见 tb.sv 文件头）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_lqraw.py --check
