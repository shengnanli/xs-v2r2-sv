MODULE = SnapshotGenerator_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/backend/SnapshotGenerator_1.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SnapshotGenerator_1.sv

WRAPPER_SRCS = $(RTL_DIR)/backend/SnapshotGenerator_1_wrapper.sv
FM_VARIANTS = SnapshotGenerator_1

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
