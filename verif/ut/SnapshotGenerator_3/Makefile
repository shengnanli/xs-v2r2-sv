MODULE = SnapshotGenerator_3

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/backend/SnapshotGenerator_3.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SnapshotGenerator_3.sv

WRAPPER_SRCS = $(RTL_DIR)/backend/SnapshotGenerator_3_wrapper.sv
FM_VARIANTS = SnapshotGenerator_3

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
