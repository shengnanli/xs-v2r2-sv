# DelayReg 家族 UT/FM 入口（11 变体共用 xs_DelayReg_core）
# 重写件 = 1 个参数化核 + 11 个变体薄文件（rtl/common/），核体不复制。
# golden 侧 11 个模块都是自足叶子（同步复位 reg + 带使能的移位链 + 直连 assign），
# 无子模块依赖，所以没有 FM_REF_DEPS_*。
#
# ★"一个核覆盖全族"是量出来的★ verif/ut/DelayReg/gen_facts.py 的
# verify_reconstruct()：只用 (端口表, 级数) 重建 golden 模块体，11/11 逐行一致
# （去掉 firtool 随机初值段、归一空白）。gen.py 每次生成前都重跑这道核对。
#
# 覆盖的是 GatewayEndpoint（difftest 网关）例化闭包里的 11 个 DelayReg 变体，
# 合计 21 个实例、96345 个 reg 位：
#   DelayReg(322b×3, 8 例) DelayReg_16(256b×2, 2 例) DelayReg_18(576b×2)
#   DelayReg_19(14344b×2)  DelayReg_20(12296b×2)     DelayReg_21(19208b×2)
#   DelayReg_22(173b×3)    DelayReg_23(10b×4)        DelayReg_24(153b×1)
#   DelayReg_25(657b×1)    DelayReg_26(325b×2, 3 例)
# ★级数 1..4 的差异是每个 DifftestBundle 在调用点各自选的 delay= 参数★
#   （出处逐个记在 gen_facts.py 的 USERS 表与各变体文件头），不是谁漏做了什么。
MODULE = DelayReg

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_DelayReg_core.sv \
           $(RTL_DIR)/common/DelayReg.sv \
           $(RTL_DIR)/common/DelayReg_16.sv \
           $(RTL_DIR)/common/DelayReg_18.sv \
           $(RTL_DIR)/common/DelayReg_19.sv \
           $(RTL_DIR)/common/DelayReg_20.sv \
           $(RTL_DIR)/common/DelayReg_21.sv \
           $(RTL_DIR)/common/DelayReg_22.sv \
           $(RTL_DIR)/common/DelayReg_23.sv \
           $(RTL_DIR)/common/DelayReg_24.sv \
           $(RTL_DIR)/common/DelayReg_25.sv \
           $(RTL_DIR)/common/DelayReg_26.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/DelayReg.sv \
              $(GOLDEN_RTL)/DelayReg_16.sv \
              $(GOLDEN_RTL)/DelayReg_18.sv \
              $(GOLDEN_RTL)/DelayReg_19.sv \
              $(GOLDEN_RTL)/DelayReg_20.sv \
              $(GOLDEN_RTL)/DelayReg_21.sv \
              $(GOLDEN_RTL)/DelayReg_22.sv \
              $(GOLDEN_RTL)/DelayReg_23.sv \
              $(GOLDEN_RTL)/DelayReg_24.sv \
              $(GOLDEN_RTL)/DelayReg_25.sv \
              $(GOLDEN_RTL)/DelayReg_26.sv

FM_VARIANTS = DelayReg DelayReg_16 DelayReg_18 DelayReg_19 DelayReg_20 DelayReg_21 \
              DelayReg_22 DelayReg_23 DelayReg_24 DelayReg_25 DelayReg_26

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 两侧都定义 SYNTHESIS（golden 的随机初值 initial 块在 `ifndef SYNTHESIS 里），
# 初值交给 +vcs+initreg。本族**所有寄存器都带同步复位**，tb 开跑前拉 5 拍 reset，
# 所以 initreg 的两轮从同一确定状态出发；initreg 这一轮真正验的是
# "复位臂有没有覆盖每一级"——漏清哪一级，random 那轮当场炸。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

.PHONY: mutants
mutants:
	python3 mutants.py

# ---------------------------------------------------------------------------
# 负测（★双向★）：家族核的 elaborate 期不变式必须"该拦的拦、不该拦的不拦"。
#
# 反向（必须拦下）negtest_bad.sv：复制 DelayReg_26 的薄文件，只把
#   i_mask 从 16 位抄成 15 位（本轮真实事故的形态：端口位宽被改小，逻辑一行没动）。
#   判据：编译期报错 或 运行期 time 0 $fatal 都算 PASS；跑通了才是 FAIL。
# 正向（必须**不**拦）negtest_ok.sv：同一份薄文件原样不动。
#   判据：必须跑到 NEGTEST_OK_REACHED 才算 PASS。
#   —— 没有这一半，"恒 $fatal 的不变式"也会让反向那一半显示 PASS。
.PHONY: negtest
negtest: $(UT_SRCS)
	@rm -rf simv_neg* negtest_*.log
	@ok=1; \
	if $(VCS) -Mdir=simv_negbad_csrc $(UT_GEN_DIR)/xs_DelayReg_core.sv negtest_bad.sv \
	      -top neg_tb -o simv_negbad > negtest_bad_compile.log 2>&1; then \
	   ./simv_negbad -l negtest_bad_run.log > /dev/null 2>&1; \
	   if grep -qE 'NEGTEST_UNREACHED' negtest_bad_run.log; then \
	     echo "=== NEGTEST[bad] FAILED：位宽抄错竟然跑通了，不变式形同虚设 ==="; ok=0; \
	   else \
	     echo "=== NEGTEST[bad] PASSED（运行期 \$$fatal 拦下）==="; \
	   fi; \
	 else \
	   echo "=== NEGTEST[bad] PASSED（编译期就拦下）==="; \
	 fi; \
	if $(VCS) -Mdir=simv_negok_csrc $(UT_GEN_DIR)/xs_DelayReg_core.sv negtest_ok.sv \
	      -top neg_tb -o simv_negok > negtest_ok_compile.log 2>&1; then \
	   ./simv_negok -l negtest_ok_run.log > /dev/null 2>&1; \
	   if grep -qE 'NEGTEST_OK_REACHED' negtest_ok_run.log; then \
	     echo "=== NEGTEST[ok]  PASSED（位宽正确时不变式不报警）==="; \
	   else \
	     echo "=== NEGTEST[ok]  FAILED：位宽正确却也被拦下 —— 这是个恒报警的闸 ==="; ok=0; \
	   fi; \
	 else \
	   echo "=== NEGTEST[ok]  FAILED：位宽正确却编译不过 ==="; ok=0; \
	 fi; \
	test $$ok -eq 1 || exit 1
