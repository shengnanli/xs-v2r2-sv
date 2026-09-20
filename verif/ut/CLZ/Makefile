# CLZ 家族 UT/FM 入口（9 变体共用 xs_CLZ_core）
# 重写件 = 1 个参数化核 + 9 个变体薄文件（rtl/common/），核体不复制。
# golden 侧 9 个模块都是自足叶子（一条纯组合三元链，无寄存器无子模块）。
#
# 家族形状由 gen_facts.py 对 golden 做**整段模块体重建比对**：从 WIDTH 与
# SCAN_LOW 两个参数把 golden 的整条三元链（含 firtool 的尾部公共前缀因子分解）
# 生成出来，与真 golden 逐字比。9/9 一致 —— 每个变体的全部逻辑恰好 = 家族公式
# 在这组参数上的取值。对不上生成器当场停，薄文件生不出来。
#
# 维度矩阵（WIDTH / SCAN_LOW 从 golden 模块体真正引用到的位数出来；OUT_W 来自端口表）：
#   CLZ     WIDTH=64  OUT_W=6 SCAN_LOW=1 NONE=63 
#   CLZ_6   WIDTH=64  OUT_W=7 SCAN_LOW=0 NONE=64 
#   CLZ_7   WIDTH=16  OUT_W=5 SCAN_LOW=0 NONE=16 
#   CLZ_9   WIDTH=32  OUT_W=6 SCAN_LOW=0 NONE=32 
#   CLZ_11  WIDTH=8   OUT_W=4 SCAN_LOW=0 NONE=8  
#   CLZ_28  WIDTH=10  OUT_W=4 SCAN_LOW=0 NONE=10 
#   CLZ_29  WIDTH=23  OUT_W=5 SCAN_LOW=0 NONE=23 
#   CLZ_30  WIDTH=11  OUT_W=4 SCAN_LOW=0 NONE=11 
#   CLZ_31  WIDTH=24  OUT_W=5 SCAN_LOW=0 NONE=24 
#
# ★SCAN_LOW 不是排版差异，是语义差异★
# 8 个变体 SCAN_LOW=0（全零输入 -> WIDTH，教科书 CLZ）；
# **只有 CLZ 本体** SCAN_LOW=1：golden 根本不读 io_in[0]，全零输入输出 63 而不是 64，
# 「全零」与「只有第 0 位是 1」输出相同。来源是 Chisel PriorityEncoder 的无条件兜底
# 分支；io_out 只有 6 位装不下 64，端口宽度本身就是痕迹。照抄，不"修正"。
# tb 的覆盖闸要求**每个可能的输出值都被观察到** + 全零输入至少 1000 次，
# 这条语义才算被真的打到，而不是"按构造应该对"。
MODULE = CLZ

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/common/CLZ.sv \
           $(RTL_DIR)/common/CLZ_6.sv \
           $(RTL_DIR)/common/CLZ_7.sv \
           $(RTL_DIR)/common/CLZ_9.sv \
           $(RTL_DIR)/common/CLZ_11.sv \
           $(RTL_DIR)/common/CLZ_28.sv \
           $(RTL_DIR)/common/CLZ_29.sv \
           $(RTL_DIR)/common/CLZ_30.sv \
           $(RTL_DIR)/common/CLZ_31.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/CLZ.sv \
              $(GOLDEN_RTL)/CLZ_6.sv \
              $(GOLDEN_RTL)/CLZ_7.sv \
              $(GOLDEN_RTL)/CLZ_9.sv \
              $(GOLDEN_RTL)/CLZ_11.sv \
              $(GOLDEN_RTL)/CLZ_28.sv \
              $(GOLDEN_RTL)/CLZ_29.sv \
              $(GOLDEN_RTL)/CLZ_30.sv \
              $(GOLDEN_RTL)/CLZ_31.sv

FM_VARIANTS = CLZ CLZ_6 CLZ_7 CLZ_9 CLZ_11 CLZ_28 CLZ_29 CLZ_30 CLZ_31

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# 纯组合，没有寄存器 —— initreg 对本家族无事可做（没有上电初值可言）。
# 仍然打开机制并跑一轮 random，是为了让"这里确实没有寄存器"这件事有凭据：
# 哪天有人往核里加了个寄存器，两轮初值一不同就会当场暴露。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+random

.PHONY: run-initreg0
run-initreg0: simv
	@rm -f sim_ir0_$(SEED).log
	./simv +vcs+initreg+0 +ntb_random_seed=$(SEED) +ncycles=$(NCYCLES) -l sim_ir0_$(SEED).log
	@grep -q "TEST PASSED" sim_ir0_$(SEED).log && echo "=== UT PASSED ($(MODULE) initreg=0 seed=$(SEED)) ===" || { echo "=== UT FAILED ($(MODULE) initreg=0 seed=$(SEED)) ==="; exit 1; }

# FM_MERGE_DUP=false：理由同 DelayNWithValid —— 合并会让比较点数变成一个算不出来
# 的量，scripts/fm_predict.py 只能给 MODEL_NA，"跑前登记预期 passing、跑后逐条
# 对账"这套账就做不成。本家族没有寄存器，关掉合并不影响结果，只让账能对上。
FM_MERGE_DUP = false

# ---------------------------------------------------------------------------
# 负测：核的两条 elaborate 期不变式各一个用例，都必须真能拦下。
#   NEG_CASE 1  端口位宽抄错（io_in 抄窄）      -> PORT_BITS_IN != WIDTH
#   NEG_CASE 2  SCAN_LOW 抄错（把 CLZ 抄成 0）  -> OUT_W != $clog2(NONE+1)
# 第 2 条正是本家族最容易抄错的地方：SCAN_LOW 看不见摸不着，抄成 0 之后电路
# 变成"全零输出 64"，而 64 装不进 6 位 —— 不变式必须在 elaborate 期就喊出来，
# 不能等 UT 撞运气。
# 判据：编译期报错 或 运行期 time 0 $fatal 都算 PASS；跑通了才是 FAIL。
.PHONY: negtest
negtest: $(UT_SRCS)
	@set -e; for c in 1 2; do \
	  echo "--- NEGTEST case $$c ---"; \
	  rm -rf simv_neg$$c simv_neg$$c.daidir simv_neg$$c\_csrc negtest$$c\_compile.log negtest$$c\_run.log; \
	  if $(VCS) -Mdir=simv_neg$$c\_csrc $(if $(filter 2,$$c),+define+NEG_CASE_2,) \
	        $(UT_GEN_DIR)/xs_CLZ_core.sv negtest.sv \
	        -top neg_tb -o simv_neg$$c > negtest$$c\_compile.log 2>&1; then \
	     ./simv_neg$$c -l negtest$$c\_run.log > /dev/null 2>&1 || true; \
	     if grep -qE 'NEGTEST_UNREACHED' negtest$$c\_run.log; then \
	       echo "=== NEGTEST $$c FAILED：抄错竟然跑通了，不变式形同虚设 ==="; exit 1; \
	     else \
	       echo "=== NEGTEST $$c PASSED（运行期 \$$fatal 拦下）==="; \
	       grep -m2 -E 'Fatal|xs_CLZ_core' negtest$$c\_run.log || true; \
	     fi; \
	   else \
	     echo "=== NEGTEST $$c PASSED（编译期就拦下）==="; \
	     grep -m2 -E 'Error|xs_CLZ_core' negtest$$c\_compile.log || true; \
	   fi; \
	 done
