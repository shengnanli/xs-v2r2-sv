# PipeWithFlush 家族 UT/FM 入口（8 变体共用 xs_PipeWithFlush_core）
# 重写件 = 1 个参数化核 + 8 个变体薄文件（rtl/common/），核体不复制。
# golden 侧 8 个模块都是自足叶子（reg + 两个 always + 直连 assign），无子模块依赖。
#
# 家族形状由 gen_facts.py 对 golden 做**整段模块体重建比对**：从「字段表 + 级数」
# 两个参数把 golden 的模块体整段生成出来，与真 golden 逐字比。8/8 一致 ——
# 连 firtool 在 N>=3 时提出来的 CSE 临时 wire、loadDependency 的级间左移、
# ogFail 的下标都在比对范围内。对不上生成器当场停，薄文件生不出来。
#
# 维度矩阵（级数从 valids_* reg 声明数出来，不是从名字猜的）：
#   PipeWithFlush     STAGES=0 字段6  载荷50 b reg0   b 无冲刷端口
#   PipeWithFlush_1   STAGES=2 字段8  载荷59 b reg120 b 冲刷: redirect + og0Fail + ldCancel×3(带 loadDependency 老化)
#   PipeWithFlush_6   STAGES=1 字段7  载荷55 b reg56  b 无冲刷端口
#   PipeWithFlush_7   STAGES=2 字段7  载荷55 b reg112 b 冲刷: redirect + og0Fail
#   PipeWithFlush_8   STAGES=0 字段5  载荷46 b reg0   b 无冲刷端口
#   PipeWithFlush_9   STAGES=3 字段7  载荷55 b reg168 b 冲刷: redirect + og0Fail/og1Fail
#   PipeWithFlush_10  STAGES=1 字段4  载荷18 b reg19  b 无冲刷端口
#   PipeWithFlush_11  STAGES=3 字段4  载荷18 b reg57  b 冲刷: redirect + og0Fail/og1Fail
#
# ★第 1 级不冲刷★：冲刷判据要读「正待前移的那个条目的 robIdx」，而第 1 级的
# 来源还在组合输入上，没落进寄存器。所以 N=1 的 _6/_10 **一个 flush 端口都没有**
# —— 不是被裁剪了，是公式里本来就用不到；N=0 的更是连 clock/reset 都没有。
#
# ★只有 PipeWithFlush_1 有 loadDependency 老化与 ldCancel 冲刷★
# 它是全家族唯一同时满足「带 loadDependency 字段」且「STAGES>=2」的变体。
# 老化 = 级间左移一位（`{bits_{k-1}_loadDependency_j[0], 1'h0}`），第 1 级不移。
MODULE = PipeWithFlush

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_PipeWithFlush_core.sv \
           $(RTL_DIR)/common/PipeWithFlush.sv \
           $(RTL_DIR)/common/PipeWithFlush_1.sv \
           $(RTL_DIR)/common/PipeWithFlush_6.sv \
           $(RTL_DIR)/common/PipeWithFlush_7.sv \
           $(RTL_DIR)/common/PipeWithFlush_8.sv \
           $(RTL_DIR)/common/PipeWithFlush_9.sv \
           $(RTL_DIR)/common/PipeWithFlush_10.sv \
           $(RTL_DIR)/common/PipeWithFlush_11.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/PipeWithFlush.sv \
              $(GOLDEN_RTL)/PipeWithFlush_1.sv \
              $(GOLDEN_RTL)/PipeWithFlush_6.sv \
              $(GOLDEN_RTL)/PipeWithFlush_7.sv \
              $(GOLDEN_RTL)/PipeWithFlush_8.sv \
              $(GOLDEN_RTL)/PipeWithFlush_9.sv \
              $(GOLDEN_RTL)/PipeWithFlush_10.sv \
              $(GOLDEN_RTL)/PipeWithFlush_11.sv

FM_VARIANTS = PipeWithFlush PipeWithFlush_1 PipeWithFlush_6 PipeWithFlush_7 PipeWithFlush_8 PipeWithFlush_9 PipeWithFlush_10 PipeWithFlush_11

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# ---------------------------------------------------------------------------
# 复位域：只有 valid 链带异步复位，**数据级一个都不复位**（重建比对钉死了这一点：
# 数据那个 always 块里没有 reset 分支）。不开 initreg 时两侧数据寄存器上电都是 X，
# tb 的 $isunknown 一跳过，「数据级无复位」就从来没被验过。故编译期
# +vcs+initreg+random 打开机制，运行期用 +vcs+initreg+<0|random> 选初值，两种都要过。
# ★编译期写 +vcs+initreg+0 是错的：VCS 报 OBSL_OPT_E，那是运行期选项。★
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+random

.PHONY: run-initreg0
run-initreg0: simv
	@rm -f sim_ir0_$(SEED).log
	./simv +vcs+initreg+0 +ntb_random_seed=$(SEED) +ncycles=$(NCYCLES) -l sim_ir0_$(SEED).log
	@grep -q "TEST PASSED" sim_ir0_$(SEED).log && echo "=== UT PASSED ($(MODULE) initreg=0 seed=$(SEED)) ===" || { echo "=== UT FAILED ($(MODULE) initreg=0 seed=$(SEED)) ==="; exit 1; }

# FM_MERGE_DUP=false：理由同 DelayNWithValid —— 合并会把比较点数压到寄存器位数
# 以下，压多少取决于设计里有多少重复结构，是个算不出来的量，于是
# scripts/fm_predict.py 只能给 MODEL_NA，"跑前登记预期 passing、跑后逐条对账"
# 这套账就做不成。本家族恰恰是同宽寄存器逐级重复的形状，最容易被合并掉；
# 关掉合并 = 每一级独立比对，比合并后更严，不是更松。
FM_MERGE_DUP = false

# ---------------------------------------------------------------------------
# 负测：核的两条 elaborate 期不变式各一个用例，都必须真能拦下。
#   NEG_CASE 1  端口位宽抄错（io_enq_bits_fuType 抄窄） -> PORT_BITS_IN != WIDTH
#   NEG_CASE 2  级数抄错（PipeWithFlush_9 的 3 级抄成 2）
#               -> STAGES*(1+WIDTH) != GOLDEN_REG_BITS
# 判据：编译期报错 或 运行期 time 0 $fatal 都算 PASS；跑通了才是 FAIL。
.PHONY: negtest
negtest: $(UT_SRCS)
	@set -e; for c in 1 2; do \
	  echo "--- NEGTEST case $$c ---"; \
	  rm -rf simv_neg$$c simv_neg$$c.daidir simv_neg$$c\_csrc negtest$$c\_compile.log negtest$$c\_run.log; \
	  if $(VCS) -Mdir=simv_neg$$c\_csrc $(if $(filter 2,$$c),+define+NEG_CASE_2,) \
	        $(UT_GEN_DIR)/xs_PipeWithFlush_core.sv negtest.sv \
	        -top neg_tb -o simv_neg$$c > negtest$$c\_compile.log 2>&1; then \
	     ./simv_neg$$c -l negtest$$c\_run.log > /dev/null 2>&1 || true; \
	     if grep -qE 'NEGTEST_UNREACHED' negtest$$c\_run.log; then \
	       echo "=== NEGTEST $$c FAILED：抄错竟然跑通了，不变式形同虚设 ==="; exit 1; \
	     else \
	       echo "=== NEGTEST $$c PASSED（运行期 \$$fatal 拦下）==="; \
	       grep -m2 -E 'Fatal|xs_PipeWithFlush_core' negtest$$c\_run.log || true; \
	     fi; \
	   else \
	     echo "=== NEGTEST $$c PASSED（编译期就拦下）==="; \
	     grep -m2 -E 'Error|xs_PipeWithFlush_core' negtest$$c\_compile.log || true; \
	   fi; \
	 done
