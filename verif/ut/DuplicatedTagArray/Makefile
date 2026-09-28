# DuplicatedTagArray —— DCache 的 4 份复制 tag 阵列（每个读口一份，写口广播 + 写入时算 SECDED）。
# 子模块处置（两侧白盒，ref 读 golden 同名件、impl 读本仓重写件）：
#   TagArray / TagSRAMBank（本 lane 重写签核，verif/ut/TagArray）、
#   SRAMTemplate_116（PROVEN_DIRECT，rtl/common + xs_SRAMTemplate_core）、
#   MbistPipeDcacheTag（PROVEN_DIRECT，rtl/dft + xs_mbist_pipe_core）；
#   其下 sram_array_1p256x86m43s1h0l1b_dcsh_tag / array_8 / MbistClockGateCell / ClockGate
#   两侧同源 elaborate（RTL_GOLDEN_DEPS）；唯一黑盒 = 厂商 SRAM 叶子 array_8_ext ×8
#   （verif/vendor_boundary.tsv 已审定；声明逐条在 verif/allow/DuplicatedTagArray.json）。
# 与上一版（直接读 golden TagArray/TagSRAMBank/SRAMTemplate_116/MbistPipeDcacheTag 作 impl 依赖）
# 的区别：impl 侧已不再复用任何 golden 逻辑件。
MODULE = DuplicatedTagArray

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_116.sv \
           $(RTL_DIR)/memblock/TagSRAMBank.sv \
           $(RTL_DIR)/memblock/TagArray.sv \
           $(RTL_DIR)/dft/xs_mbist_pipe_core.sv \
           $(RTL_DIR)/dft/MbistPipeDcacheTag.sv \
           $(RTL_DIR)/memblock/DuplicatedTagArray.sv
TB_SRCS = tb.sv

SRAM_DEPS = sram_array_1p256x86m43s1h0l1b_dcsh_tag.sv array_8.sv MbistClockGateCell.sv ClockGate.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(SRAM_DEPS))
GOLDEN_SRCS = $(GOLDEN_RTL)/DuplicatedTagArray.sv \
              $(GOLDEN_RTL)/TagArray.sv \
              $(GOLDEN_RTL)/TagSRAMBank.sv \
              $(GOLDEN_RTL)/SRAMTemplate_116.sv \
              $(GOLDEN_RTL)/MbistPipeDcacheTag.sv \
              $(RTL_GOLDEN_DEPS) \
              $(GOLDEN_RTL)/array_8_ext.v

FM_VARIANTS = DuplicatedTagArray
FM_REF_DEPS_DuplicatedTagArray = TagArray.sv TagSRAMBank.sv SRAMTemplate_116.sv MbistPipeDcacheTag.sv $(SRAM_DEPS)
FM_MODE = assembly
# merge_duplicated_registers 保持工具默认（开）：共享核 xs_SRAMTemplate_core 的 rdata_last_REG 在
# holdRead 关闭时与 respReg 同方程，靠合并消掉（golden 无此寄存器）；关掉合并它就成为 impl 独有的
# unread（本 lane 实测：TagSRAMBank 1 个 / TagArray 2 个 / DuplicatedTagArray 8 个）。
# 这与 SRAMTemplate_* 自身签核的口径相同。代价：fm_predict 模型不适用（MODEL_NA）。
PORTLINT_ORDER = fail

# vmucp（加强不是放宽）：MbistPipeDcacheTag 的地址打拍寄存器两侧对称死位，
# 依据见 verif/fm_target_config/DuplicatedTagArray.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
