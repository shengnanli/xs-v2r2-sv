# SplittedSRAM 家族 UT（PtwCache 的 l1 / l0 两级页表缓存 SRAM 阵列）。
# tb.sv 由 verif/ut/SplittedSRAM/gen.py 生成；RTL 变体薄文件由
# scripts/gen_splittedsram.py 生成，两者共用手写核 rtl/memblock/SplittedSRAM_ptw_core.sv。
MODULE = SplittedSRAM

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_128.sv \
           $(RTL_DIR)/common/SRAMTemplate_129.sv \
           $(RTL_DIR)/common/SRAMTemplate_143.sv \
           $(RTL_DIR)/memblock/SplittedSRAM_ptw_core.sv \
           $(RTL_DIR)/memblock/SplittedSRAM_1.sv \
           $(RTL_DIR)/memblock/SplittedSRAM_2.sv

TB_SRCS = tb.sv

# 厂商 SRAM 宏链：golden 同源文件，两侧同读（宏内 array_*_ext 是 vendor 叶子 .v，
# FM 不读其内部 ⇒ 对称未解析黑盒）。
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/array_10.sv \
                  $(GOLDEN_RTL)/array_11.sv \
                  $(GOLDEN_RTL)/sram_array_1p4x786m131s1h0l1b_ptw_l1.sv \
                  $(GOLDEN_RTL)/sram_array_1p64x114m57s1h0l1b_ptw_l0.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SplittedSRAM_1.sv \
              $(GOLDEN_RTL)/SplittedSRAM_2.sv \
              $(GOLDEN_RTL)/SRAMTemplate_128.sv \
              $(GOLDEN_RTL)/SRAMTemplate_129.sv \
              $(GOLDEN_RTL)/SRAMTemplate_143.sv \
              $(GOLDEN_RTL)/array_10.sv \
              $(GOLDEN_RTL)/array_10_ext.v \
              $(GOLDEN_RTL)/array_11.sv \
              $(GOLDEN_RTL)/array_11_ext.v \
              $(GOLDEN_RTL)/sram_array_1p4x786m131s1h0l1b_ptw_l1.sv \
              $(GOLDEN_RTL)/sram_array_1p64x114m57s1h0l1b_ptw_l0.sv

FM_REF_DEPS_SplittedSRAM_1 = SRAMTemplate_128.sv sram_array_1p4x786m131s1h0l1b_ptw_l1.sv array_10.sv
FM_REF_DEPS_SplittedSRAM_2 = SRAMTemplate_129.sv SRAMTemplate_143.sv sram_array_1p64x114m57s1h0l1b_ptw_l0.sv array_11.sv

# FM_MODE=assembly：唯一抽象边界 = 厂商 SRAM 宏叶子 array_10_ext / array_11_ext
# （.v 行为模型，两侧同一文件，FM 不读 ⇒ 对称未解析黑盒）。内层 SRAMTemplate_128/129/143
# 是**重写件**，两侧同源 elaborate，不黑盒。★本行的 mode/allowlist 取值照 SRAMTemplate
# 家族现状，尚未经 reviewer 确认，跑 FM 前请复核。
FM_MODE = assembly
FM_ALLOWLIST ?= 8
FM_VARIANTS = SplittedSRAM_1 SplittedSRAM_2

include ../../../scripts/ut_common.mk

# CONVENTIONS 要求两轮寄存器初值：random 与 0。
# ★VCS W-2024.09 的用法★：编译期只能给 `+vcs+initreg+random` 打开这项功能
# （给 `+vcs+initreg+0` 会 Error-[OBSL_OPT_E]），具体取 0/1/random 由**运行时**
# 的 `+vcs+initreg+<值>` 决定。所以两轮共用一次编译，只换运行参数。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
