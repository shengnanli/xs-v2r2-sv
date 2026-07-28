MODULE = NCB200_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读顶层核 xs_NCB200_1_core(纯结构 netlist glue: 互连 16 个直接 child)。
RTL_SRCS = $(RTL_DIR)/uncore/NCB200_1.sv
# FM impl 侧: golden 同名扁平端口包装 + 26 逻辑 child(16 直接 + 10 孙)两侧 elaborate
# (全逻辑 child, 非黑盒, ref==impl 同源; 无厂商 SRAM 宏 → 结构无黑盒)。
WRAPPER_SRCS = $(RTL_DIR)/uncore/NCB200_1_wrapper.sv \
               $(GOLDEN_RTL)/CHILinkActiveManagerRX.sv \
               $(GOLDEN_RTL)/CHILinkActiveManagerTX.sv \
               $(GOLDEN_RTL)/NCBOrderAddressCAM_1.sv \
               $(GOLDEN_RTL)/NCBTransactionFreeList_1.sv \
               $(GOLDEN_RTL)/NCBTransactionAgeMatrix_1.sv \
               $(GOLDEN_RTL)/NCBTransactionQueue_1.sv \
               $(GOLDEN_RTL)/NCBTransactionPayload_1.sv \
               $(GOLDEN_RTL)/NCBUpstreamRXREQ_1.sv \
               $(GOLDEN_RTL)/NCBUpstreamRXDAT_1.sv \
               $(GOLDEN_RTL)/NCBUpstreamTXRSP_1.sv \
               $(GOLDEN_RTL)/NCBUpstreamTXDAT_1.sv \
               $(GOLDEN_RTL)/NCBDownstreamAW_1.sv \
               $(GOLDEN_RTL)/NCBDownstreamW_1.sv \
               $(GOLDEN_RTL)/NCBDownstreamB_1.sv \
               $(GOLDEN_RTL)/NCBDownstreamAR_1.sv \
               $(GOLDEN_RTL)/NCBDownstreamR_1.sv \
               $(GOLDEN_RTL)/CHILinkCreditManagerRX.sv \
               $(GOLDEN_RTL)/CHILinkCreditManagerRX_1.sv \
               $(GOLDEN_RTL)/CHILinkCreditManagerTX.sv \
               $(GOLDEN_RTL)/Decoder.sv \
               $(GOLDEN_RTL)/Decoder_1.sv \
               $(GOLDEN_RTL)/NCBTransactionIndexFIFO_3.sv \
               $(GOLDEN_RTL)/ProvideBuffer.sv \
               $(GOLDEN_RTL)/SpillRegister_2.sv \
               $(GOLDEN_RTL)/SpillRegister_6.sv \
               $(GOLDEN_RTL)/SpillRegister_7.sv

# golden 顶层 + 全部 26 子模块闭包(无厂商宏)。
GOLDEN_SRCS = $(GOLDEN_RTL)/NCB200_1.sv \
              $(GOLDEN_RTL)/CHILinkActiveManagerRX.sv \
              $(GOLDEN_RTL)/CHILinkActiveManagerTX.sv \
              $(GOLDEN_RTL)/NCBOrderAddressCAM_1.sv \
              $(GOLDEN_RTL)/NCBTransactionFreeList_1.sv \
              $(GOLDEN_RTL)/NCBTransactionAgeMatrix_1.sv \
              $(GOLDEN_RTL)/NCBTransactionQueue_1.sv \
              $(GOLDEN_RTL)/NCBTransactionPayload_1.sv \
              $(GOLDEN_RTL)/NCBUpstreamRXREQ_1.sv \
              $(GOLDEN_RTL)/NCBUpstreamRXDAT_1.sv \
              $(GOLDEN_RTL)/NCBUpstreamTXRSP_1.sv \
              $(GOLDEN_RTL)/NCBUpstreamTXDAT_1.sv \
              $(GOLDEN_RTL)/NCBDownstreamAW_1.sv \
              $(GOLDEN_RTL)/NCBDownstreamW_1.sv \
              $(GOLDEN_RTL)/NCBDownstreamB_1.sv \
              $(GOLDEN_RTL)/NCBDownstreamAR_1.sv \
              $(GOLDEN_RTL)/NCBDownstreamR_1.sv \
              $(GOLDEN_RTL)/CHILinkCreditManagerRX.sv \
              $(GOLDEN_RTL)/CHILinkCreditManagerRX_1.sv \
              $(GOLDEN_RTL)/CHILinkCreditManagerTX.sv \
              $(GOLDEN_RTL)/Decoder.sv \
              $(GOLDEN_RTL)/Decoder_1.sv \
              $(GOLDEN_RTL)/NCBTransactionIndexFIFO_3.sv \
              $(GOLDEN_RTL)/ProvideBuffer.sv \
              $(GOLDEN_RTL)/SpillRegister_2.sv \
              $(GOLDEN_RTL)/SpillRegister_6.sv \
              $(GOLDEN_RTL)/SpillRegister_7.sv
# UT 变体: impl 顶层改名 NCB200_1_xs 与 golden 双例化。
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 assembly。26 逻辑 child 两侧 elaborate golden RTL(逻辑 child, 非黑盒,
# ref==impl 同源)。唯一黑盒 = golden 本身把 NCBOrderAddressCAM_1 化简成的空模块(0 输出),
# FM 自动归 empty_blackbox(对称, allow/NCB200_1.json 声明)。不用 FM_INTERFACE_ONLY
# (我方闭包里没有"有 body 却要当 interface"的模块; 空 CAM 由 FM 自动 empty-blackbox)。
# FM_MERGE_DUP=false: 关闭重复寄存器合并。26 child 里有多份同款子模块(SpillRegister/
# LinkCreditManager/Decoder), impl 侧多一层 u_core 层次会让 merge_duplicated_registers
# 在两侧不对称合并 uLinkCredit 的 regInitialCycleCounter/CreditCounter → 18 个 golden-only
# unmatched-ref 伪影。关掉合并让两侧逐寄存器对称匹配(同 SMSPrefetcher assembly 做法)。
FM_VARIANTS = NCB200_1
FM_MODE = assembly
FM_MERGE_DUP = false
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_ALLOWLIST = ../../signoff/allow/NCB200_1.json
FM_REF_DEPS_NCB200_1 = CHILinkActiveManagerRX.sv CHILinkActiveManagerTX.sv NCBOrderAddressCAM_1.sv NCBTransactionFreeList_1.sv NCBTransactionAgeMatrix_1.sv NCBTransactionQueue_1.sv NCBTransactionPayload_1.sv NCBUpstreamRXREQ_1.sv NCBUpstreamRXDAT_1.sv NCBUpstreamTXRSP_1.sv NCBUpstreamTXDAT_1.sv NCBDownstreamAW_1.sv NCBDownstreamW_1.sv NCBDownstreamB_1.sv NCBDownstreamAR_1.sv NCBDownstreamR_1.sv CHILinkCreditManagerRX.sv CHILinkCreditManagerRX_1.sv CHILinkCreditManagerTX.sv Decoder.sv Decoder_1.sv NCBTransactionIndexFIFO_3.sv ProvideBuffer.sv SpillRegister_2.sv SpillRegister_6.sv SpillRegister_7.sv

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 断言; 定义 SYNTHESIS 关掉使两侧复位到 0 同构。
VCS += +define+SYNTHESIS
VCS += -assert disable
