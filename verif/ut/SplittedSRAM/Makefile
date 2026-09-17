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

# 两侧都完整 elaborate 到**同一层**：内层 SRAMTemplate_128/129/143 是本仓重写件
# （不是厂商宏），ref 侧读 golden 版、impl 侧读重写版，都不抽象；再下一层的
# sram_array_*_ptw_l{0,1} 与 array_10/array_11 两侧同源同读。唯一没给任何一侧的是
# 厂商 SRAM 叶子 array_10_ext / array_11_ext（verif/vendor_boundary.tsv 已审定为
# vendor_sram_leaf，标注 body_not_read_by_fm ⇒ 只能对称黑盒，不许白盒化）。
#
# coordinator 0168 裁定：assembly 是退路不是首选，先按 strict + 零配额跑，
# 真出 unmatched 黑盒点先上报，不许把 allowlist 往上调。
FM_MODE = signoff-strict
FM_ALLOWLIST ?= 0
FM_VARIANTS = SplittedSRAM_1 SplittedSRAM_2

include ../../../scripts/ut_common.mk

# CONVENTIONS 要求两轮寄存器初值：random 与 0。
# ★VCS W-2024.09 的用法★：编译期只能给 `+vcs+initreg+random` 打开这项功能
# （给 `+vcs+initreg+0` 会 Error-[OBSL_OPT_E]），具体取 0/1/random 由**运行时**
# 的 `+vcs+initreg+<值>` 决定。所以两轮共用一次编译，只换运行参数。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
