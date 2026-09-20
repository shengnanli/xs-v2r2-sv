# DelayNWithValid 家族 UT/FM 入口（16 变体共用 xs_DelayNWithValid_core）
# 重写件 = 1 个参数化核 + 16 个变体薄文件（rtl/common/），核体不复制。
# golden 侧 16 个模块都是自足叶子（只有 reg 与直连 assign），无子模块依赖。
#
# 家族形状由 gen_facts.py 对 golden 做**整段模块体重建比对**（不是抽查断言）：
# 从「字段表 / 级数 STAGES / valid 链长 V」三个参数把 golden 的模块体整段生成
# 出来，与真 golden 逐字比（只做空白归一化）。16/16 一致 —— 也就证明了每个变体
# 的全部逻辑恰好 = 家族公式在这组参数上的取值，不多也不少。任何一条对不上，
# 生成器当场停，薄文件根本生不出来。
#
# 级数 / valid 链矩阵（从 golden 的 reg 声明数出来，不是从名字猜的）：
#  STAGES=0 V=0 : DelayNWithValid_4(9b) DelayNWithValid_7(16b)
#  STAGES=1 V=0 : DelayNWithValid_103(16b) DelayNWithValid_152(9b) DelayNWithValid_155(50b) DelayNWithValid_52(4b) DelayNWithValid_55(24b)
#  STAGES=1 V=1 : DelayNWithValid_202(12b) DelayNWithValid_203(64b)
#  STAGES=2 V=1 : DelayNWithValid(50b) DelayNWithValid_1(60b)
#  STAGES=2 V=2 : DelayNWithValid_2(49b) DelayNWithValid_200(53b) DelayNWithValid_3(48b)
#  STAGES=3 V=2 : DelayNWithValid_148(7b) DelayNWithValid_149(4b)
#
# ★V 不是自由参数★：V = 0(STAGES=0) / STAGES(有 io_out_valid) / STAGES-1(没有)。
# firtool 只保留被读到的寄存器，valid 链最后一级只有 io_out_valid 会读。
# 于是同样 n=1 的 _52 和 _202 形状完全不同：前者 valid 链消光、连 reset 端口都没有，
# 后者 valid 链留 1 级、reset 在。**是同一个公式的两组参数，不是两种电路。**
MODULE = DelayNWithValid

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_DelayNWithValid_core.sv \
           $(RTL_DIR)/common/DelayNWithValid.sv \
           $(RTL_DIR)/common/DelayNWithValid_1.sv \
           $(RTL_DIR)/common/DelayNWithValid_2.sv \
           $(RTL_DIR)/common/DelayNWithValid_3.sv \
           $(RTL_DIR)/common/DelayNWithValid_4.sv \
           $(RTL_DIR)/common/DelayNWithValid_7.sv \
           $(RTL_DIR)/common/DelayNWithValid_52.sv \
           $(RTL_DIR)/common/DelayNWithValid_55.sv \
           $(RTL_DIR)/common/DelayNWithValid_103.sv \
           $(RTL_DIR)/common/DelayNWithValid_148.sv \
           $(RTL_DIR)/common/DelayNWithValid_149.sv \
           $(RTL_DIR)/common/DelayNWithValid_152.sv \
           $(RTL_DIR)/common/DelayNWithValid_155.sv \
           $(RTL_DIR)/common/DelayNWithValid_200.sv \
           $(RTL_DIR)/common/DelayNWithValid_202.sv \
           $(RTL_DIR)/common/DelayNWithValid_203.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/DelayNWithValid.sv \
              $(GOLDEN_RTL)/DelayNWithValid_1.sv \
              $(GOLDEN_RTL)/DelayNWithValid_2.sv \
              $(GOLDEN_RTL)/DelayNWithValid_3.sv \
              $(GOLDEN_RTL)/DelayNWithValid_4.sv \
              $(GOLDEN_RTL)/DelayNWithValid_7.sv \
              $(GOLDEN_RTL)/DelayNWithValid_52.sv \
              $(GOLDEN_RTL)/DelayNWithValid_55.sv \
              $(GOLDEN_RTL)/DelayNWithValid_103.sv \
              $(GOLDEN_RTL)/DelayNWithValid_148.sv \
              $(GOLDEN_RTL)/DelayNWithValid_149.sv \
              $(GOLDEN_RTL)/DelayNWithValid_152.sv \
              $(GOLDEN_RTL)/DelayNWithValid_155.sv \
              $(GOLDEN_RTL)/DelayNWithValid_200.sv \
              $(GOLDEN_RTL)/DelayNWithValid_202.sv \
              $(GOLDEN_RTL)/DelayNWithValid_203.sv

FM_VARIANTS = DelayNWithValid DelayNWithValid_1 DelayNWithValid_2 DelayNWithValid_3 DelayNWithValid_4 DelayNWithValid_7 DelayNWithValid_52 DelayNWithValid_55 DelayNWithValid_103 DelayNWithValid_148 DelayNWithValid_149 DelayNWithValid_152 DelayNWithValid_155 DelayNWithValid_200 DelayNWithValid_202 DelayNWithValid_203

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# ---------------------------------------------------------------------------
# 复位域：本家族只有 valid 链带异步复位，**数据级一个都不复位**（gen_facts 的
# 重建比对钉死了这一点：数据级那个 always 块里没有 reset 分支）。不开 initreg 时
# 两侧数据寄存器上电都是 X，tb 的 $isunknown 一跳过，「数据级无复位」这件事就
# 从来没被验过。故编译期 +vcs+initreg+random 打开机制，运行期用
# +vcs+initreg+<0|random> 选初值，两种初值都要过。
# ★编译期写 +vcs+initreg+0 是错的：VCS 报 OBSL_OPT_E，那是运行期选项。★
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+random

.PHONY: run-initreg0
run-initreg0: simv
	@rm -f sim_ir0_$(SEED).log
	./simv +vcs+initreg+0 +ntb_random_seed=$(SEED) +ncycles=$(NCYCLES) -l sim_ir0_$(SEED).log
	@grep -q "TEST PASSED" sim_ir0_$(SEED).log && echo "=== UT PASSED ($(MODULE) initreg=0 seed=$(SEED)) ===" || { echo "=== UT FAILED ($(MODULE) initreg=0 seed=$(SEED)) ==="; exit 1; }

# ---------------------------------------------------------------------------
# FM_MERGE_DUP=false：关掉「重复寄存器合并」。
# 两个理由，都不是为了好看：
#  1) 合并会把比较点数压到寄存器位数以下，压多少取决于设计里有多少重复结构 ——
#     那是个算不出来的量，于是 scripts/fm_predict.py 只能给 MODEL_NA，
#     「跑前登记预期 passing、跑后逐条对账」这套账就做不成了。
#  2) 本家族恰恰全是**结构重复**的打拍链（n 级同宽寄存器），是最容易被合并掉的形状；
#     关掉合并 = 每一级都独立比对，比合并后更严，不是更松。
FM_MERGE_DUP = false

# ---------------------------------------------------------------------------
# 负测：核的两条 elaborate 期不变式各有一个用例，都必须真能拦下。
#   NEG_CASE 1  端口位宽抄错   -> PORT_BITS_IN != WIDTH
#   NEG_CASE 2  级数抄错       -> VALID_CHAIN + STAGES*WIDTH != GOLDEN_REG_BITS
# 判据：编译期报错 或 运行期 time 0 $fatal 都算 PASS；跑通了（打出
# NEGTEST_UNREACHED）才是 FAIL。
# ★第 2 条以前是测不到的★：negtest.sv 当时还在覆盖已改名的 GOLDEN_DATA_REG_BITS，
# VCS 只给 Warning-[AOUP] 就忽略，守恒等式取默认值恒真 —— 负测每次都绿，
# 而它声称守着的那条不变式根本没进过场。
.PHONY: negtest
negtest: $(UT_SRCS)
	@set -e; for c in 1 2; do \
	  echo "--- NEGTEST case $$c ---"; \
	  rm -rf simv_neg$$c simv_neg$$c.daidir simv_neg$$c\_csrc negtest$$c\_compile.log negtest$$c\_run.log; \
	  if $(VCS) -Mdir=simv_neg$$c\_csrc $(if $(filter 2,$$c),+define+NEG_CASE_2,) \
	        $(UT_GEN_DIR)/xs_DelayNWithValid_core.sv negtest.sv \
	        -top neg_tb -o simv_neg$$c > negtest$$c\_compile.log 2>&1; then \
	     ./simv_neg$$c -l negtest$$c\_run.log > /dev/null 2>&1 || true; \
	     if grep -qE 'NEGTEST_UNREACHED' negtest$$c\_run.log; then \
	       echo "=== NEGTEST $$c FAILED：抄错竟然跑通了，不变式形同虚设 ==="; exit 1; \
	     else \
	       echo "=== NEGTEST $$c PASSED（运行期 \$$fatal 拦下）==="; \
	       grep -m2 -E 'Fatal|xs_DelayNWithValid_core' negtest$$c\_run.log || true; \
	     fi; \
	   else \
	     echo "=== NEGTEST $$c PASSED（编译期就拦下）==="; \
	     grep -m2 -E 'Error|xs_DelayNWithValid_core' negtest$$c\_compile.log || true; \
	   fi; \
	 done
