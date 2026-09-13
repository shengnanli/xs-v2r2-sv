# NewPipelineConnectPipe 家族 UT —— 14 个变体共用一个 tb。
#
# 这一族此前**没有任何 UT**：13 个变体的端口表照 G0 生成，缺 G1 新增的透传字段，
# 却因为既无 UT、又不在台账里而长期没人发现。本目录同时补上 UT 与覆盖闸。
#
# 覆盖范围：13 个本轮按 G1 重做的变体 + 已有的 _25（旧式手工位切片文件，本轮未改
# 其 RTL，只是拉进来一起测）。_27/_31/_32/_33 属“同名不同物”改名链，另有属主，
# 本 UT 刻意不碰。G1 新增的 _29/_34/_35 在 rtl/ 里还没有实现，不在本 UT 范围。
MODULE = NewPipelineConnectPipe

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/PipelineConnect.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_1.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_5.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_7.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_8.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_9.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_10.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_13.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_14.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_16.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_18.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_20.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_23.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_25.sv
TB_SRCS  = tb.sv

# golden 变体都是自包含的（0 子模块），不需要任何 FM_REF_DEPS_*。
GOLDEN_SRCS = $(GOLDEN_RTL)/NewPipelineConnectPipe.sv \
              $(GOLDEN_RTL)/NewPipelineConnectPipe_1.sv \
              $(GOLDEN_RTL)/NewPipelineConnectPipe_5.sv \
              $(GOLDEN_RTL)/NewPipelineConnectPipe_7.sv \
              $(GOLDEN_RTL)/NewPipelineConnectPipe_8.sv \
              $(GOLDEN_RTL)/NewPipelineConnectPipe_9.sv \
              $(GOLDEN_RTL)/NewPipelineConnectPipe_10.sv \
              $(GOLDEN_RTL)/NewPipelineConnectPipe_13.sv \
              $(GOLDEN_RTL)/NewPipelineConnectPipe_14.sv \
              $(GOLDEN_RTL)/NewPipelineConnectPipe_16.sv \
              $(GOLDEN_RTL)/NewPipelineConnectPipe_18.sv \
              $(GOLDEN_RTL)/NewPipelineConnectPipe_20.sv \
              $(GOLDEN_RTL)/NewPipelineConnectPipe_23.sv \
              $(GOLDEN_RTL)/NewPipelineConnectPipe_25.sv

FM_VARIANTS = NewPipelineConnectPipe NewPipelineConnectPipe_1 NewPipelineConnectPipe_5 \
              NewPipelineConnectPipe_7 NewPipelineConnectPipe_8 NewPipelineConnectPipe_9 \
              NewPipelineConnectPipe_10 NewPipelineConnectPipe_13 NewPipelineConnectPipe_14 \
              NewPipelineConnectPipe_16 NewPipelineConnectPipe_18 NewPipelineConnectPipe_20 \
              NewPipelineConnectPipe_23 NewPipelineConnectPipe_25

# 端口顺序也照 golden 生成，顺带把 ORDER 从 warn 升成硬闸。
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# ---------------------------------------------------------------------------
# 参数不变式负测（codex 0145）：故意把 PAYLOAD_W_G1 传成与 DATA_WIDTH 不符的值，
# 核里的 initial 自检必须 $fatal。**跑不失败就说明闸是摆设**，所以这里反过来判：
# 仿真没炸 = NEG FAILED。
# ---------------------------------------------------------------------------
.PHONY: neg
neg:
	@rm -rf neg_build && mkdir -p neg_build
	@cd neg_build && $(VCS) ../$(RTL_DIR)/common/PipelineConnect.sv ../neg_invariant.sv \
	    -top neg_tb -o neg_simv > neg_compile.log 2>&1 \
	  || { echo "=== NEG: 编译就失败了（也算拦下，但请看 neg_build/neg_compile.log）==="; }
	@cd neg_build && ./neg_simv -l neg_sim.log > /dev/null 2>&1; true
	@if grep -q "G1 golden 字段位宽之和" neg_build/neg_sim.log 2>/dev/null; then \
	  echo "=== NEG PASSED: 错误参数被 xs_PipelineConnect 的不变式拦下 ==="; \
	  grep -m1 "G1 golden 字段位宽之和" neg_build/neg_sim.log; \
	elif grep -q "NEG_ESCAPED" neg_build/neg_sim.log 2>/dev/null; then \
	  echo "=== NEG FAILED: 错误参数没被拦下，不变式是摆设 ==="; exit 1; \
	else \
	  echo "=== NEG FAILED: 既没触发不变式也没跑到底，看 neg_build/ ==="; exit 1; \
	fi
