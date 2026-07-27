MODULE = FusionDecoder

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写 SV: 可读核 xs_FusionDecoder
RTL_SRCS = $(RTL_DIR)/backend/FusionDecoder_core.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/FusionDecoder_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/FusionDecoder.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = FusionDecoder

# 加强证明: golden 每 lane 有 lastFire_N/REG_N 两个逐拍 `<= fire_N` 的寄存器, 仅被
# SYNTHESIS 断言的死 wire 读取 → 关 SYNTHESIS 后 cone-dead。merge 后代表 REG_N_reg。
# 可读核保留语义等价的 lastFire[N]; fm_pins_pre.tcl 显式钉双射, vmucp=true 让 FM 实际
# 逐位证等价(非 waiver), 得 0 unread clean strict SUCCEEDED(passing 330→335)。
# ★须 main 把 FusionDecoder 加入 scripts/fm_eq.tcl 的 vmucp 白名单(L77)+
#   scripts/sidecar/run_signoff_target.sh 的 case 白名单(两处 main-owned)。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS ?= true

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 的随机初值与 LogUtils 断言(assert(false))；
# 关 SYNTHESIS 避免随机初值失配与断言触发。
VCS += +define+SYNTHESIS
