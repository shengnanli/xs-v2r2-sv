# RecentRequestTable —— L2 Best-Offset 预取器的 RR 表（两个变体共用 xs_RecentRequestTable_core）。
# 唯一子模块 SRAMTemplate_146（rrTable）两侧白盒：ref 读 golden、impl 读重写件 rtl/common/SRAMTemplate_146.sv
# （+ xs_SRAMTemplate_core，已签核）；再下一层厂商 SRAM 宏链 sram_array_*_l2_pftch_rrt / array_13 两侧同读，
# 宏内叶子 array_13_ext（vendor_macro）FM 不读 ⇒ 两侧对称黑盒，精确集合见 verif/allow/<T>.json
# （由 verif/allow_gen/write_allow.py 独立生成，不读本次运行结果）。
MODULE = RecentRequestTable

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_146.sv \
           $(RTL_DIR)/uncore/RecentRequestTable.sv \
           $(RTL_DIR)/uncore/RecentRequestTable_1.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv \
                  $(XSSV_HOME)/rtl/common/array_13.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/RecentRequestTable.sv \
              $(GOLDEN_RTL)/RecentRequestTable_1.sv \
              $(GOLDEN_RTL)/SRAMTemplate_146.sv \
              $(GOLDEN_RTL)/array_13_ext.v

FM_REF_DEPS_RecentRequestTable = SRAMTemplate_146.sv sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv array_13.sv
FM_REF_DEPS_RecentRequestTable_1 = SRAMTemplate_146.sv sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv array_13.sv

FM_MODE = assembly
FM_ALLOWLIST ?= 0
FM_VARIANTS = RecentRequestTable RecentRequestTable_1
# merge_dup 用工具默认（true）：内层 SRAMTemplate_146 用的是共享核 xs_SRAMTemplate_core，其非 holdRead
# 分支的 rdata_last_REG 在主线上与 respReg 同方程、靠 merge 合并（SRAMTemplate_146 自己签核时同口径）；
# 关掉 merge 它就成了 golden 没有的 impl 独占 unread（codex 0206 D1 正在另一条 lane 把它从核里删掉）。
# 断言寄存器 REG / rw_same_cycle_q 两侧零扇出，由 fm_pins.tcl 钉成一对后按 vmucp 加强。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，运行期 INITREG=0 / random / <seed>017 三档选初值
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
