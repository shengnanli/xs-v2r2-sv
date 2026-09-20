# DelayN 家族 UT/FM 入口（18 变体共用 xs_DelayN_core）
# 重写件 = 1 个参数化核 + 18 个变体薄文件（rtl/common/），核体不复制。
# golden 侧 18 个模块都是自足叶子（只有无复位 reg 与直连 assign），无子模块依赖。
# 家族形状由 gen_facts.py 对 golden **逐条结构验证**（不是只数位宽）：端口三类、
# 字段表输入输出同构、reg 表 = 级数 × 字段、唯一一个无复位无使能的 always、
# 输出取最后一级。任何一条不成立，生成器当场停。
#
# 级数矩阵（从 golden 数出来，不是从名字猜的）：
#   0 级  DelayN_225(1b)                     ← 退化成一根直连线，golden 连 clock 都没有
#   1 级  DelayN(5b) DelayN_13(1b) DelayN_220(71b) DelayN_221(261b)
#   2 级  DelayN_1(1b) DelayN_7(219b) DelayN_8(274b) DelayN_9(72b)
#         DelayN_214(183b) DelayN_215(9b) DelayN_333(14b)
#   3 级  DelayN_297(1b)
#   4 级  DelayN_15(1b)
#   5 级  DelayN_17(1b) DelayN_208(8b) DelayN_334(48b)
#  10 级  DelayN_331(1b)
MODULE = DelayN

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_DelayN_core.sv \
           $(RTL_DIR)/common/DelayN.sv \
           $(RTL_DIR)/common/DelayN_1.sv \
           $(RTL_DIR)/common/DelayN_7.sv \
           $(RTL_DIR)/common/DelayN_8.sv \
           $(RTL_DIR)/common/DelayN_9.sv \
           $(RTL_DIR)/common/DelayN_13.sv \
           $(RTL_DIR)/common/DelayN_15.sv \
           $(RTL_DIR)/common/DelayN_17.sv \
           $(RTL_DIR)/common/DelayN_208.sv \
           $(RTL_DIR)/common/DelayN_214.sv \
           $(RTL_DIR)/common/DelayN_215.sv \
           $(RTL_DIR)/common/DelayN_220.sv \
           $(RTL_DIR)/common/DelayN_221.sv \
           $(RTL_DIR)/common/DelayN_225.sv \
           $(RTL_DIR)/common/DelayN_297.sv \
           $(RTL_DIR)/common/DelayN_331.sv \
           $(RTL_DIR)/common/DelayN_333.sv \
           $(RTL_DIR)/common/DelayN_334.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/DelayN.sv \
              $(GOLDEN_RTL)/DelayN_1.sv \
              $(GOLDEN_RTL)/DelayN_7.sv \
              $(GOLDEN_RTL)/DelayN_8.sv \
              $(GOLDEN_RTL)/DelayN_9.sv \
              $(GOLDEN_RTL)/DelayN_13.sv \
              $(GOLDEN_RTL)/DelayN_15.sv \
              $(GOLDEN_RTL)/DelayN_17.sv \
              $(GOLDEN_RTL)/DelayN_208.sv \
              $(GOLDEN_RTL)/DelayN_214.sv \
              $(GOLDEN_RTL)/DelayN_215.sv \
              $(GOLDEN_RTL)/DelayN_220.sv \
              $(GOLDEN_RTL)/DelayN_221.sv \
              $(GOLDEN_RTL)/DelayN_225.sv \
              $(GOLDEN_RTL)/DelayN_297.sv \
              $(GOLDEN_RTL)/DelayN_331.sv \
              $(GOLDEN_RTL)/DelayN_333.sv \
              $(GOLDEN_RTL)/DelayN_334.sv

FM_VARIANTS = DelayN DelayN_1 DelayN_7 DelayN_8 DelayN_9 DelayN_13 DelayN_15 DelayN_17 DelayN_208 DelayN_214 DelayN_215 DelayN_220 DelayN_221 DelayN_225 DelayN_297 DelayN_331 DelayN_333 DelayN_334

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# ---------------------------------------------------------------------------
# 复位域：DelayN 家族的打拍链在 golden 里**一个 reg 都不复位**（gen_facts.py 的
# 结构判据第 4 条就钉死了「只有一个 always @(posedge clock)、无复位无使能」）。
# 不开 initreg 时两侧寄存器上电都是 X，tb 的 $isunknown 一跳过，「无复位」这件事
# 就从来没被验过。故编译期 +vcs+initreg+random 打开机制，运行期用
# +vcs+initreg+<0|random> 选初值，两种初值都要过。
# ★ 编译期写 +vcs+initreg+0 是错的：VCS 报 OBSL_OPT_E，那是运行期选项。★
#
# ★热身窗口（WARMUP）不是为了绕过失配，是「无复位链」的定义域★：
# golden 的 REG 与重写侧的 u_core.g_chain.stage[] 是**不同的寄存器**，
# +vcs+initreg+random 给它们各自独立的随机初值，前 STAGES 拍输出的是这些初值，
# 本来就不该相等；从第 STAGES+1 拍起链上每一级都已被 tb 驱动的数据覆盖，
# 此后必须逐拍相等。tb 用 WARMUP = 家族最大级数(10) + 1 = 11 拍，
# 对任何一个变体都足够；窗口内不比对也不计 checks（20 万拍里扣 11 拍，覆盖闸不受影响）。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+random

.PHONY: run-initreg0
run-initreg0: simv
	@rm -f sim_ir0_$(SEED).log
	./simv +vcs+initreg+0 +ntb_random_seed=$(SEED) +ncycles=$(NCYCLES) -l sim_ir0_$(SEED).log
	@grep -q "TEST PASSED" sim_ir0_$(SEED).log && echo "=== UT PASSED ($(MODULE) initreg=0 seed=$(SEED)) ===" || { echo "=== UT FAILED ($(MODULE) initreg=0 seed=$(SEED)) ==="; exit 1; }

# ---------------------------------------------------------------------------
# 负测：家族核的 elaborate 期不变式必须真能拦下"位宽静默写错"。
# negtest.sv 复制 DelayN_9 的薄文件，只把 io_in_bits_addr 从 50 位抄成 49 位
# （本轮真实事故的形态：端口位宽被改小，逻辑一行没动，UT 按旧位宽驱动照过）。
# 判据：编译期报错 或 运行期 time 0 $fatal 都算 PASS；跑通了才是 FAIL。
.PHONY: negtest
negtest: $(UT_SRCS)
	@rm -rf simv_neg simv_neg.daidir simv_neg_csrc negtest_compile.log negtest_run.log
	@if $(VCS) -Mdir=simv_neg_csrc $(UT_GEN_DIR)/xs_DelayN_core.sv negtest.sv \
	      -top neg_tb -o simv_neg > negtest_compile.log 2>&1; then \
	   ./simv_neg -l negtest_run.log > /dev/null 2>&1; \
	   if grep -qE 'NEGTEST_UNREACHED' negtest_run.log; then \
	     echo "=== NEGTEST FAILED：位宽抄错竟然跑通了，不变式形同虚设 ==="; exit 1; \
	   else \
	     echo "=== NEGTEST PASSED（运行期 \$$fatal 拦下）==="; \
	     grep -m2 -E 'Fatal|xs_DelayN_core' negtest_run.log || true; \
	   fi; \
	 else \
	   echo "=== NEGTEST PASSED（编译期就拦下）==="; \
	   grep -m2 -E 'Error|xs_DelayN_core' negtest_compile.log || true; \
	 fi

# 变异靶子：往家族核 / 薄文件里注入若干个**真实形态**的 bug，要求本 UT 每一个都
# 抓得住；另有两条逻辑等价空变异要求**不**误报。本轮 tb 新加了 WARMUP 热身窗口
# （判据的放宽），这道负测就是它的凭据 —— 变异表与口径见 mutants.py 顶部。
.PHONY: mutants
mutants:
	python3 mutants.py $(MUTANT_ARGS)
