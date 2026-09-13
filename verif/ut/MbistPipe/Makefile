# MbistPipe* 家族（24 个变体）双例化 UT
#
# 家族切分：22 个叶子(直驱 SRAM 的 bore 口) + 2 个中间节点(往下接 MbistPipe)，
# 全部由 rtl/dft/xs_mbist_pipe_core.sv 一个参数化核实现，每变体一个薄文件只设
# 参数 + 展平端口。tb 由 scripts/gen_mbist_ut.py 生成，24 对实例同激励逐拍比对。
#
# 重跑生成器（改了 golden 或参数表之后）：
#   python3 ../../../scripts/gen_mbist_pipe_family.py && python3 ../../../scripts/gen_mbist_ut.py

MODULE  := MbistPipe

RTL_DIR = ../../../rtl

VARIANTS := MbistPipeDCacheData MbistPipeDcacheTag MbistPipeFrontend MbistPipeFtb \
            MbistPipeIcacheDataWay0 MbistPipeIcacheDataWay1 MbistPipeIcacheDataWay2 \
            MbistPipeIcacheDataWay3 MbistPipeIcacheTag \
            MbistPipeIttage MbistPipeIttage_1 MbistPipeIttage_2 MbistPipeIttage_3 \
            MbistPipeIttage_4 MbistPipeL2Prefetcher MbistPipeMemBlk \
            MbistPipePtwL0 MbistPipePtwL1 \
            MbistPipeSc MbistPipeSc_1 MbistPipeSc_2 MbistPipeSc_3 \
            MbistPipeSms MbistPipeTage

RTL_SRCS := $(RTL_DIR)/dft/xs_mbist_pipe_core.sv \
            $(addprefix $(RTL_DIR)/dft/,$(addsuffix .sv,$(VARIANTS)))

TB_SRCS  := tb.sv

GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(VARIANTS)))

# 每个变体都是自包含的（0 子模块、0 黑盒），FM 侧依赖为空。
FM_VARIANTS := $(VARIANTS)
$(foreach v,$(VARIANTS),$(eval FM_REF_DEPS_$(v) :=))

# 端口顺序也当硬闸：本家族的薄文件是生成的，顺序没有理由和 golden 不一致。
PORTLINT_ORDER := fail

include ../../../scripts/ut_common.mk

# 必失败负测：故意把参数表写错，证明核里的 elaborate 期不变量真的会拦下来。
.PHONY: negtest
negtest:
	@bash neg/run_negtests.sh
