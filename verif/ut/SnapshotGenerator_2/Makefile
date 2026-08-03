MODULE = SnapshotGenerator_2

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/backend/SnapshotGenerator_2.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SnapshotGenerator_2.sv

WRAPPER_SRCS = $(RTL_DIR)/backend/SnapshotGenerator_2_wrapper.sv
FM_VARIANTS = SnapshotGenerator_2

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
