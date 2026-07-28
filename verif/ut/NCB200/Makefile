MODULE = NCB200

RTL_DIR = ../../../rtl
GOLDEN_RTL = /home/eda/xs-env/G0-canonical/golden-rtl

# Readable top assembly core (pure structural: 16 children + passthrough wiring
# + 2 trivial reductions). NCB200 has NO state/datapath of its own.
RTL_SRCS = $(RTL_DIR)/uncore/NCB200.sv

# FM impl side: golden-name flat-port wrapper (-> u_core) + whole NCB200 subtree
# (16 children + 9 grandchildren) two-side-elaborated. All are logic modules with
# their own golden .sv; NONE are vendor SRAM, so NONE are blackboxed. The proof is
# a fully clean strict equivalence over the entire subtree (zero blackboxes).
WRAPPER_SRCS = $(RTL_DIR)/uncore/NCB200_wrapper.sv \
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

# UT dual-instantiation: golden NCB200 + whole subtree (16 children + 9 grandchildren).
GOLDEN_SRCS = $(GOLDEN_RTL)/NCB200.sv \
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

# UT variant: impl top renamed NCB200_xs (instantiates xs_NCB200_core).
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = NCB200
# signoff-strict: whole subtree elaborated on both sides, ZERO blackboxes ->
# no interface_only / assembly relaxation needed. FM_MERGE_DUP=false so the
# repeated leaf instances (Decoder/SpillRegister/IndexFIFO) are not merged.
FM_MODE = signoff-strict
FM_MERGE_DUP = false
# vmucp: the golden children hold 5208 cone-dead DFFs (payload/queue storage that
# is written but whose read cone is not observed at NCB200's top ports). They are
# perfectly SYMMETRIC matched-unread (r:/.../child/reg <-> i:/.../u_core/child/reg,
# identical golden source both sides). verify_matched_unread=true makes FM actually
# compare them -> all convert to passing (proved: DFF 54504->59712, 0 failing), so
# the proof is genuine (non-vacuous). Requires main to add NCB200 to the fm_eq.tcl
# + run_signoff_target.sh vmucp whitelist (main-owned).
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_REF_DEPS_NCB200 = CHILinkActiveManagerRX.sv CHILinkActiveManagerTX.sv NCBOrderAddressCAM.sv NCBTransactionFreeList.sv NCBTransactionAgeMatrix.sv NCBTransactionQueue.sv NCBTransactionPayload.sv NCBUpstreamRXREQ.sv NCBUpstreamRXDAT.sv NCBUpstreamTXRSP.sv NCBUpstreamTXDAT.sv NCBDownstreamAW.sv NCBDownstreamW.sv NCBDownstreamB.sv NCBDownstreamAR.sv NCBDownstreamR.sv CHILinkCreditManagerRX.sv CHILinkCreditManagerRX_1.sv CHILinkCreditManagerTX.sv Decoder.sv Decoder_1.sv NCBTransactionIndexFIFO.sv ProvideBuffer.sv SpillRegister.sv SpillRegister_2.sv

include ../../../scripts/ut_common.mk

# golden has `ifndef SYNTHESIS assertions; define SYNTHESIS so both sides reset
# identically.
VCS += +define+SYNTHESIS
VCS += -assert disable
