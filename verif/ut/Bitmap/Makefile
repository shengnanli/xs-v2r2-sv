MODULE = Bitmap

RTL_DIR = ../../../rtl
# 重写侧：Bitmap 本体 + 它例化的轮转仲裁器（rtl/common 的重写件，与 golden RRArbiterInit
# 同一变体：8 入 / ppn 36 位 / 有 out_ready / 有 chosen，端口逐名核对过）。
RTL_SRCS = $(RTL_DIR)/mmu/mmu_common_pkg.sv \
           $(RTL_DIR)/common/RRArbiterInit.sv \
           $(RTL_DIR)/mmu/Bitmap.sv
TB_SRCS = tb.sv

# 边界：Arbiter8_bitmapCacheReqBundle（固定优先级 8 入仲裁，golden 独有、无寄存器）
# **两侧同源用 golden**，不黑盒——同 verif/ut/PtwCache/Makefile 的取法，黑盒边界为空，
# proof_mode 走 signoff-strict。Bitmap 本身没有 SRAM（golden 全文只有这两个例化）。
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/Arbiter8_bitmapCacheReqBundle.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Bitmap.sv \
              $(GOLDEN_RTL)/RRArbiterInit.sv \
              $(RTL_GOLDEN_DEPS)

FM_VARIANTS = Bitmap
# ref 侧闭包：golden 的 RRArbiterInit（impl 侧用 rtl/common 重写版，两侧白盒对称）+ 同源 Arbiter8。
FM_REF_DEPS_Bitmap = RRArbiterInit.sv Arbiter8_bitmapCacheReqBundle.sv
# 关掉重复寄存器合并：让 passing 与 fm_predict.py 的模型可逐位对账。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 的 XSError/assert 段（`ifndef SYNTHESIS）随机激励下会触发 $fatal，统一关掉。
# ★双例化 UT 的两档 initreg 是 +0 与 +1，不用 +random★（random 按实例各摇各的初值；
# 本模块 enq_ptr_reg / need_addr_check / pmp 地址 / wakeup 保持寄存器都不复位）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
