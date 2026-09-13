# ICacheMSHR 家族 UT/FM 入口（14 变体共用 xs_ICacheMSHR_core）
# 家族识别结论：这 14 个**不是**同核不同参，而是**两种模块体各复制若干份**——
#   取指 MSHR ICacheMSHR/_1/_2/_3（ICacheMissUnit.fetchMSHRs_0..3）：无 io_flush；
#   预取 MSHR ICacheMSHR_4.._13（prefetchMSHRs_0..9）：多一条 io_flush。
# 组内把自身模块名归一化后逐字节相同（md5 一致），所有位宽 14 个变体完全一样。
# 因此重写件 = 1 个核（flush 输入常在，取指变体接 1'b0）+ 14 个薄文件。
MODULE = ICacheMSHR

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/xs_ICacheMSHR_core.sv \
           $(RTL_DIR)/frontend/ICacheMSHR.sv \
           $(RTL_DIR)/frontend/ICacheMSHR_1.sv \
           $(RTL_DIR)/frontend/ICacheMSHR_2.sv \
           $(RTL_DIR)/frontend/ICacheMSHR_3.sv \
           $(RTL_DIR)/frontend/ICacheMSHR_4.sv \
           $(RTL_DIR)/frontend/ICacheMSHR_5.sv \
           $(RTL_DIR)/frontend/ICacheMSHR_6.sv \
           $(RTL_DIR)/frontend/ICacheMSHR_7.sv \
           $(RTL_DIR)/frontend/ICacheMSHR_8.sv \
           $(RTL_DIR)/frontend/ICacheMSHR_9.sv \
           $(RTL_DIR)/frontend/ICacheMSHR_10.sv \
           $(RTL_DIR)/frontend/ICacheMSHR_11.sv \
           $(RTL_DIR)/frontend/ICacheMSHR_12.sv \
           $(RTL_DIR)/frontend/ICacheMSHR_13.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/ICacheMSHR.sv \
              $(GOLDEN_RTL)/ICacheMSHR_1.sv \
              $(GOLDEN_RTL)/ICacheMSHR_2.sv \
              $(GOLDEN_RTL)/ICacheMSHR_3.sv \
              $(GOLDEN_RTL)/ICacheMSHR_4.sv \
              $(GOLDEN_RTL)/ICacheMSHR_5.sv \
              $(GOLDEN_RTL)/ICacheMSHR_6.sv \
              $(GOLDEN_RTL)/ICacheMSHR_7.sv \
              $(GOLDEN_RTL)/ICacheMSHR_8.sv \
              $(GOLDEN_RTL)/ICacheMSHR_9.sv \
              $(GOLDEN_RTL)/ICacheMSHR_10.sv \
              $(GOLDEN_RTL)/ICacheMSHR_11.sv \
              $(GOLDEN_RTL)/ICacheMSHR_12.sv \
              $(GOLDEN_RTL)/ICacheMSHR_13.sv

FM_VARIANTS = ICacheMSHR ICacheMSHR_1 ICacheMSHR_2 ICacheMSHR_3 ICacheMSHR_4 \
              ICacheMSHR_5 ICacheMSHR_6 ICacheMSHR_7 ICacheMSHR_8 ICacheMSHR_9 \
              ICacheMSHR_10 ICacheMSHR_11 ICacheMSHR_12 ICacheMSHR_13

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# ---------------------------------------------------------------------------
# 负测：核的块地址拼接等式必须真能拦下"块大小抄错"。
# negtest.sv 复制 ICacheMSHR_4 的薄文件，只把 OFFSET_W 从 6（64B 块）抄成 5
# （32B 块）。端口表照旧、逻辑一行不改，acquire 地址只是低位少填一个 0——
# 随机激励不比 golden 就发现不了。判据：编译期报错或 time 0 $fatal 才算 PASS。
.PHONY: negtest
negtest: $(UT_SRCS)
	@rm -rf simv_neg simv_neg.daidir simv_neg_csrc negtest_compile.log negtest_run.log
	@if $(VCS) -Mdir=simv_neg_csrc $(UT_GEN_DIR)/xs_ICacheMSHR_core.sv negtest.sv \
	      -top neg_tb -o simv_neg > negtest_compile.log 2>&1; then \
	   ./simv_neg -l negtest_run.log > /dev/null 2>&1; \
	   if grep -qE 'NEGTEST_UNREACHED' negtest_run.log; then \
	     echo "=== NEGTEST FAILED：块大小抄错竟然跑通了，不变式形同虚设 ==="; exit 1; \
	   else \
	     echo "=== NEGTEST PASSED（运行期 \$$fatal 拦下）==="; \
	     grep -m2 -E 'Fatal|xs_ICacheMSHR_core' negtest_run.log || true; \
	   fi; \
	 else \
	   echo "=== NEGTEST PASSED（编译期就拦下）==="; \
	   grep -m2 -E 'Error|xs_ICacheMSHR_core' negtest_compile.log || true; \
	 fi
