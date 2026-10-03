MODULE = VIntFixpAlu64b

# VIntFixpAlu64b（向量整数/定点 ALU 64 位半片，两拍流水）。golden 直接 child 三个：
#   VIntAdder64b（纯叶）/ VIntMisc64b（内含 CLZ_6/7/9/11）/ VFixPoint64b（内含 Adder_chain_rnd，本 lane）
#   —— docs/coverage_three_axis.tsv 除 VFixPoint64b 外全部 PROVEN_DIRECT；VFixPoint64b 由本 lane
#   在 verif/ut/VFixPoint64b 先行签核。处置 = 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件，无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/common/CLZ_6.sv \
           $(RTL_DIR)/common/CLZ_7.sv \
           $(RTL_DIR)/common/CLZ_9.sv \
           $(RTL_DIR)/common/CLZ_11.sv \
           $(RTL_DIR)/backend/VIntMisc64b.sv \
           $(RTL_DIR)/backend/VIntAdder64b.sv \
           $(RTL_DIR)/backend/Adder_chain_rnd.sv \
           $(RTL_DIR)/backend/VFixPoint64b.sv \
           $(RTL_DIR)/backend/VIntFixpAlu64b.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/VIntFixpAlu64b.sv \
              $(GOLDEN_RTL)/VIntAdder64b.sv \
              $(GOLDEN_RTL)/VIntMisc64b.sv \
              $(GOLDEN_RTL)/CLZ_6.sv \
              $(GOLDEN_RTL)/CLZ_7.sv \
              $(GOLDEN_RTL)/CLZ_9.sv \
              $(GOLDEN_RTL)/CLZ_11.sv \
              $(GOLDEN_RTL)/VFixPoint64b.sv \
              $(GOLDEN_RTL)/Adder_chain_rnd.sv
FM_VARIANTS = VIntFixpAlu64b
FM_REF_DEPS_VIntFixpAlu64b = VIntAdder64b.sv VIntMisc64b.sv CLZ_6.sv CLZ_7.sv CLZ_9.sv CLZ_11.sv VFixPoint64b.sv Adder_chain_rnd.sv

# 关 merge_dup：golden 流水寄存器里有多份同源打拍，关掉后 fm_predict 的模型严格适用（加强不是放宽）
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 流水寄存器全部不复位：+random 档两侧初值不同，tb 在第一次 fire 之后才开始比对（见 tb.sv 文件头）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
