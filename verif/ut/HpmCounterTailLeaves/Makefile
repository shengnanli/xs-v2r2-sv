MODULE = HpmCounterTailLeaves
RTL_DIR = ../../../rtl
HPM_LEAVES = Hpmcounter11Module Hpmcounter12Module Hpmcounter13Module \
 Hpmcounter14Module Hpmcounter15Module Hpmcounter16Module Hpmcounter17Module \
 Hpmcounter18Module Hpmcounter19Module Hpmcounter20Module Hpmcounter21Module \
 Hpmcounter22Module Hpmcounter23Module Hpmcounter24Module Hpmcounter25Module \
 Hpmcounter26Module Hpmcounter27Module Hpmcounter28Module Hpmcounter29Module \
 Hpmcounter30Module Hpmcounter31Module
MHPM_LEAVES = Mhpmcounter3Module Mhpmcounter4Module Mhpmcounter5Module \
 Mhpmcounter6Module Mhpmcounter7Module Mhpmcounter8Module Mhpmcounter9Module \
 Mhpmcounter10Module Mhpmcounter11Module Mhpmcounter12Module Mhpmcounter13Module \
 Mhpmcounter14Module Mhpmcounter15Module Mhpmcounter16Module Mhpmcounter17Module \
 Mhpmcounter18Module Mhpmcounter19Module Mhpmcounter20Module Mhpmcounter21Module \
 Mhpmcounter22Module Mhpmcounter23Module Mhpmcounter24Module Mhpmcounter25Module \
 Mhpmcounter26Module Mhpmcounter27Module Mhpmcounter28Module Mhpmcounter29Module \
 Mhpmcounter30Module Mhpmcounter31Module
LEAVES = $(HPM_LEAVES) $(MHPM_LEAVES)
RTL_SRCS = $(RTL_DIR)/backend/xs_Hpmcounter_core.sv \
           $(RTL_DIR)/backend/newcsr_mhpmcounter.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
include ../../../scripts/ut_common.mk

# Enable VCS register initialization support at compile time.  Runtime default
# is deterministic zero; the six-seed lane matrix also runs INITREG=random.
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS = +ncycles=$(NCYCLES) +vcs+initreg+$(INITREG)
PORTLINT_ORDER = fail
