MODULE = FTBEntryGen

RTL_DIR = ../../../rtl
# frontend_common_pkg.sv 里的 xs_ftb_pkg 由 FTBEntryGen/FTBBank 共用（每个子系统至多一个公共包文件，见
# CONVENTIONS.md）。必须排在使用者之前：package 要先于引用它的模块可见。
RTL_SRCS = $(RTL_DIR)/frontend/frontend_common_pkg.sv \
           $(RTL_DIR)/frontend/FTBEntryGen.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FTBEntryGen.sv
FM_VARIANTS = FTBEntryGen

include ../../../scripts/ut_common.mk
