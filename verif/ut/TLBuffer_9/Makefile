# TLBuffer_9 UT/FM 入口（xs_TLBuffer_ad_core 家族变体）
# 重写件只有两个：共享参数化核 + 本变体薄文件。
# Queue2_*/ram_2x* 是 golden 叶子，放 RTL_GOLDEN_DEPS：UT 两侧共用同一份定义
# （不改名、不复制），FM 时与 ref 侧同源 elaborate。
# 自动生成：scripts/gen_tlbuffer_ad_family.py —— 勿手改
MODULE = TLBuffer_9

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/xs_TLBuffer_ad_core.sv \
           $(RTL_DIR)/memblock/TLBuffer_9.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/Queue2_TLBundleA_15.sv \
                  $(GOLDEN_RTL)/Queue2_TLBundleD_15.sv \
                  $(GOLDEN_RTL)/ram_2x116.sv \
                  $(GOLDEN_RTL)/ram_2x79.sv

FM_REF_DEPS_TLBuffer_9 = Queue2_TLBundleA_15.sv Queue2_TLBundleD_15.sv ram_2x116.sv ram_2x79.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer_9.sv
FM_VARIANTS = TLBuffer_9

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
