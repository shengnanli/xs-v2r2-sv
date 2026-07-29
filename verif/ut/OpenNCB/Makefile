MODULE = OpenNCB

RTL_DIR = ../../../rtl
GOLDEN_RTL = /home/eda/xs-env/G0-canonical/golden-rtl

# Readable top assembly core (pure combinational shell: 1 child NCB200 +
# inbound flit-vector slicing + 2 concat repacks + AXI passthrough). OpenNCB has
# NO state/datapath of its own (0 reg / 0 always / 0 _GEN_).
RTL_SRCS = $(RTL_DIR)/uncore/OpenNCB.sv

# FM impl side: golden-name flat-port wrapper (-> u_core) ONLY. NCB200 is the
# single child and is a SYMMETRIC unresolved_blackbox (NOT compiled here); FM
# black-boxes it on both ref and impl -> the assembly proof exercises exactly the
# OpenNCB glue. NCB200 is independently AUX-signed-off (depends_on NCB200 aux PASS).
WRAPPER_SRCS = $(RTL_DIR)/uncore/OpenNCB_wrapper.sv

# UT dual-instantiation: golden OpenNCB + OpenNCB_xs, both driving the SAME real
# NCB200 subtree (child + 9 grandchildren, two-side same-source) so the UT proves
# the OpenNCB glue end-to-end.
GOLDEN_SRCS = $(GOLDEN_RTL)/OpenNCB.sv \
              $(GOLDEN_RTL)/NCB200.sv \
              $(GOLDEN_RTL)/CHILinkActiveManagerRX.sv \
              $(GOLDEN_RTL)/CHILinkActiveManagerTX.sv \
              $(GOLDEN_RTL)/NCBOrderAddressCAM.sv \
              $(GOLDEN_RTL)/NCBTransactionFreeList.sv \
              $(GOLDEN_RTL)/NCBTransactionAgeMatrix.sv \
              $(GOLDEN_RTL)/NCBTransactionQueue.sv \
              $(GOLDEN_RTL)/NCBTransactionPayload.sv \
              $(GOLDEN_RTL)/NCBUpstreamRXREQ.sv \
              $(GOLDEN_RTL)/NCBUpstreamRXDAT.sv \
              $(GOLDEN_RTL)/NCBUpstreamTXRSP.sv \
              $(GOLDEN_RTL)/NCBUpstreamTXDAT.sv \
              $(GOLDEN_RTL)/NCBDownstreamAW.sv \
              $(GOLDEN_RTL)/NCBDownstreamW.sv \
              $(GOLDEN_RTL)/NCBDownstreamB.sv \
              $(GOLDEN_RTL)/NCBDownstreamAR.sv \
              $(GOLDEN_RTL)/NCBDownstreamR.sv \
              $(GOLDEN_RTL)/CHILinkCreditManagerRX.sv \
              $(GOLDEN_RTL)/CHILinkCreditManagerRX_1.sv \
              $(GOLDEN_RTL)/CHILinkCreditManagerTX.sv \
              $(GOLDEN_RTL)/Decoder.sv \
              $(GOLDEN_RTL)/Decoder_1.sv \
              $(GOLDEN_RTL)/NCBTransactionIndexFIFO.sv \
              $(GOLDEN_RTL)/ProvideBuffer.sv \
              $(GOLDEN_RTL)/SpillRegister.sv \
              $(GOLDEN_RTL)/SpillRegister_2.sv

# UT variant: impl top renamed OpenNCB_xs (instantiates xs_OpenNCB_core).
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = OpenNCB
# assembly: NCB200 declared symmetric unresolved_blackbox (compiled into neither
# ref nor impl -> hdlin_unresolved_modules=black_box picks it up symmetrically).
# allow/OpenNCB.json declares the single unresolved_blackbox pair. No FM_REF_DEPS
# for OpenNCB (only the golden top is on the ref side; NCB200.sv intentionally
# omitted so it becomes the symmetric blackbox boundary).
FM_MODE = assembly
FM_ALLOWLIST = ../../signoff/allow/OpenNCB.json

include ../../../scripts/ut_common.mk

# golden has `ifndef SYNTHESIS assertions; define SYNTHESIS so both sides reset
# identically. (OpenNCB itself is stateless; SYNTHESIS keeps the NCB200 subtree's
# reset behaviour identical on both UT sides.)
VCS += +define+SYNTHESIS
VCS += -assert disable
