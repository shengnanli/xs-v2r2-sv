MODULE = F3Predecoder

RTL_DIR = ../../../rtl
# frontend_common_pkg.sv 里的 xs_predecode_pkg 由 PreDecode/F3Predecoder 共用（每个子系统
# 至多一个公共包文件，见 CONVENTIONS.md）。必须排在使用者之前：package 要先于引用它的模块可见。
RTL_SRCS = $(RTL_DIR)/frontend/frontend_common_pkg.sv $(RTL_DIR)/frontend/F3Predecoder.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/F3Predecoder.sv
FM_VARIANTS = F3Predecoder

include ../../../scripts/ut_common.mk
