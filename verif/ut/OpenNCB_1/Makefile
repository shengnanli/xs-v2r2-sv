MODULE = OpenNCB_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读顶层核 xs_OpenNCB_1_core(纯结构 netlist: 例化唯一 child NCB200_1 + CHI flit
# 位切片映射 + 2 条输出 flit 打包 assign)。全部功能逻辑在 NCB200_1 内(已 AUX 签核 PASS)。
RTL_SRCS = $(RTL_DIR)/uncore/OpenNCB_1.sv

# NCB200_1 闭包(golden 26 逻辑 child)—— UT 双例化需要 golden NCB200_1 完整实体。
NCB_CLOSURE = NCB200_1.sv \
              CHILinkActiveManagerRX.sv \
              CHILinkActiveManagerTX.sv \
              NCBOrderAddressCAM_1.sv \
              NCBTransactionFreeList_1.sv \
              NCBTransactionAgeMatrix_1.sv \
              NCBTransactionQueue_1.sv \
              NCBTransactionPayload_1.sv \
              NCBUpstreamRXREQ_1.sv \
              NCBUpstreamRXDAT_1.sv \
              NCBUpstreamTXRSP_1.sv \
              NCBUpstreamTXDAT_1.sv \
              NCBDownstreamAW_1.sv \
              NCBDownstreamW_1.sv \
              NCBDownstreamB_1.sv \
              NCBDownstreamAR_1.sv \
              NCBDownstreamR_1.sv \
              CHILinkCreditManagerRX.sv \
              CHILinkCreditManagerRX_1.sv \
              CHILinkCreditManagerTX.sv \
              Decoder.sv \
              Decoder_1.sv \
              NCBTransactionIndexFIFO_3.sv \
              ProvideBuffer.sv \
              SpillRegister_2.sv \
              SpillRegister_6.sv \
              SpillRegister_7.sv

# FM impl 侧: 可读核 wrapper(OpenNCB_1_wrapper 例化 u_core=xs_OpenNCB_1_core)+ NCB200_1
# golden 同名扁平端口(FM 里 NCB200_1 声明为 FM_INTERFACE_ONLY 对称黑盒, 仅证 OpenNCB_1 glue)。
WRAPPER_SRCS = $(RTL_DIR)/uncore/OpenNCB_1_wrapper.sv \
               $(addprefix $(GOLDEN_RTL)/,$(NCB_CLOSURE))

# UT 双例化 golden OpenNCB_1 + 完整 NCB200_1 闭包。
GOLDEN_SRCS = $(GOLDEN_RTL)/OpenNCB_1.sv $(addprefix $(GOLDEN_RTL)/,$(NCB_CLOSURE))
# UT 变体: impl 顶层改名 OpenNCB_1_xs 与 golden 双例化。
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 assembly。★NCB200_1 对称黑盒 depends_on(已 clean AUX signoff PASS)★:
# FM_INTERFACE_ONLY=NCB200_1 令两侧仅读 NCB200_1 接口不例化其 body → 仅证 OpenNCB_1
# 本层 glue(CHI flit 位切片映射到 NCB200_1 field 端口 + 2 条输出 flit 打包)逐位等价。
# OpenNCB_1 顶层 0 register/0 always → 装配壳 glue 无内部死位; allow 声明 NCB200_1 interface_only
# 对称对。ref 侧提供 golden NCB200_1(经 FM_REF_DEPS), impl 侧提供 golden 同名扁平端口
# (经 WRAPPER_SRCS), FM 因 interface_only 两侧都只取接口。
FM_VARIANTS = OpenNCB_1
FM_MODE = assembly
FM_INTERFACE_ONLY = NCB200_1
FM_ALLOWLIST = ../../signoff/allow/OpenNCB_1.json
FM_REF_DEPS_OpenNCB_1 = $(NCB_CLOSURE)

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 断言; 定义 SYNTHESIS 关掉使两侧复位到 0 同构。
VCS += +define+SYNTHESIS
VCS += -assert disable
