# TLBuffer_6 UT/FM 入口（xs_TLBuffer_ad_core 家族变体）
# 重写件只有两个：共享参数化核 + 本变体薄文件。
# Queue2_*/ram_2x* 是 golden 叶子，放 RTL_GOLDEN_DEPS：UT 两侧共用同一份定义
# （不改名、不复制），FM 时与 ref 侧同源 elaborate。
# 自动生成：scripts/gen_tlbuffer_ad_family.py —— 勿手改
MODULE = TLBuffer_6

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/xs_TLBuffer_ad_core.sv \
           $(RTL_DIR)/memblock/TLBuffer_6.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/Queue2_TLBundleA_6.sv \
                  $(GOLDEN_RTL)/Queue2_TLBundleD_7.sv \
                  $(GOLDEN_RTL)/ram_2x281.sv \
                  $(GOLDEN_RTL)/ram_2x356.sv

FM_REF_DEPS_TLBuffer_6 = Queue2_TLBundleA_6.sv Queue2_TLBundleD_7.sv ram_2x281.sv ram_2x356.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer_6.sv
FM_VARIANTS = TLBuffer_6

include ../../../scripts/ut_common.mk

# +vcs+initreg+random 只在**编译期**打开机制，取值在运行期由 +vcs+initreg+<0|1|random>
# 选（ut_common.mk 的 SIM_ARGS）。只在运行期给、编译期不给，VCS 报 Warning-[VICIU]
# 然后当没看见 —— 那一轮等于没测。本家族 2026-09-20 实测过这条：
#   编译期不给、只在运行期给 +vcs+initreg+0 -> Warning-[VICIU] VCS initreg not enabled
#
# ★SIM_ARGS 必须显式钉 +0，不能不给★：编译期开了 random、运行期不选值时，VCS 取
# random（实测 TLBuffer_6 default `make run` 命令行里没有任何 initreg plusarg，
# 结果与 +vcs+initreg+random 逐个相同：errors=47），于是"默认那一轮"会悄悄换语义。
#
# ★诚实交代 +random 那轮今天是红的（2026-09-20 实测，3 seed x 5 变体）★
#   +vcs+initreg+0       15/15 绿
#   +vcs+initreg+1       绿（TLBuffer_6 seed 7/42 实跑）
#   +vcs+initreg+random  seed 1 绿；seed 7/42 全红（errors 10~47）
# 判别实验说明这不是重写件对非零上电初值的行为差异：★+1 两侧上电内容**相同**就绿，
# 只有 random 才红★ —— 差别在"两侧初值一不一样"，不在"初值是不是 0"。
# 实测到的两条事实（不是推断）：
#   · 失配全部落在 reset 撤销后头 1~5 个比较拍（t=86000~136000 ps，共跑 20 万拍），
#     此后到底再无一例；失配信号全是被无复位状态喂的那些（Queue2 的载荷）。
#   · impl 侧 256 位 data 逐位等于 golden 侧的低 128 位再接另外 128 位
#     （g=...adb|5f10b681...04de 对 i=5f10b681...04de|baaebd4f...）。
# 读法（这一句是推断，不是测量）：VCS 的 initreg 像是从一条随机流里按序取值填各个
# 寄存器，于是 tb 里 golden 与 _xs 两个实例拿到同一条流的**不同片段**；而 Queue2 的
# ram_2x<N> 是 golden 行为模型、没有复位，tb 又在 reset 一撤就开始比，
# 比到的就是**还没被写过的条目**。
# 这是 tb 缺暖机窗口，不是 DUT 差异；FM 侧不受影响（本轮 5 个变体 failing/unmatched 全 0）。
# ★所以别把"配了 initreg"读成"两轮都绿"★ —— 补暖机是另一件事，没做。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

# ---------------------------------------------------------------------------
# negtest：xs_TLBuffer_ad_core 载荷位数等式不变式的必失败负测（codex 0145 决策三）。
#   NEG_TLB_SOURCE     SOURCE_W 抄成旧值（G0->G1 真实事故形态）
#   NEG_TLB_NO_ANCHOR  不传 ram_2x<N> 锚点（改造前会拿 TLBuffer_6 的默认值蒙混）
# 判据：两个都必须在 elaborate 期非零退出。
NEG_CASES = NEG_TLB_SOURCE NEG_TLB_NO_ANCHOR
.PHONY: negtest
negtest:
	@rc=0; for c in $(NEG_CASES); do \
	  rm -rf neg_csrc simv_neg simv_neg.daidir; \
	  if vcs -full64 -sverilog -Mdir=neg_csrc +define+SYNTHESIS +define+$$c \
	         $(RTL_DIR)/memblock/xs_TLBuffer_ad_core.sv negtest.sv \
	         -top neg_tlb_probe -o simv_neg > neg_$$c.log 2>&1; then \
	    echo "=== NEGTEST FAILED ($$c)：抄错的参数竟然 elaborate 过了 ==="; rc=1; \
	  elif grep -q 'Error-\[FEST\]' neg_$$c.log; then \
	    echo "=== NEGTEST PASSED ($$c)：elaborate 期被不变式拦下 ==="; \
	    sed -n '/FEST/,/^$$/p' neg_$$c.log | grep -m2 'msg:' || true; \
	  else \
	    echo "=== NEGTEST FAILED ($$c)：编译是失败了, 但不是 \$$fatal 不变式拦的(看 neg_$$c.log) ==="; \
	    grep -m3 -E '^Error' neg_$$c.log || true; rc=1; \
	  fi; \
	done; rm -rf neg_csrc simv_neg simv_neg.daidir; exit $$rc
