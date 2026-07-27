MODULE = SnapshotGenerator_14

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/backend/SnapshotGenerator_14.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SnapshotGenerator_14.sv

WRAPPER_SRCS = $(RTL_DIR)/backend/SnapshotGenerator_14_wrapper.sv
FM_VARIANTS = SnapshotGenerator_14

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
