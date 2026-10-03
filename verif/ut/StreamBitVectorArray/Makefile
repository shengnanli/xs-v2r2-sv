MODULE = StreamBitVectorArray

# StreamBitVectorArray（L1 流式预取的区域位向量表）。golden 0 child。
# 重写核用共享辅助件 rtl/common/xs_PlruReplacer.sv（golden 里内联成 state_reg）。
# 无黑盒。FM「匹配前」钉点 fm_pins_pre.tcl 由 scripts/gen_mmuleaf.py 生成（golden 顶层寄存器逐位）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_PlruReplacer.sv \
           $(RTL_DIR)/memblock/StreamBitVectorArray.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/StreamBitVectorArray.sv

FM_VARIANTS = StreamBitVectorArray
FM_REF_DEPS_StreamBitVectorArray =

# 关掉 merge_duplicated_registers：golden 有值恒等的多份寄存器（s3_pf_l1_valid / s3_pf_l2_valid，
# s2_pf_l2_incr_vaddr / s2_pf_l3_incr_vaddr），让 FM 逐个比；fm_predict 的 passing 模型也只在关掉时严格适用。
FM_MERGE_DUP = false

# ★vmucp：依据见 verif/fm_target_config/StreamBitVectorArray.tcl★ —— 319 位两侧对称死位
# （表项 tag 高 15 位 / 查询 tag 高 15 位 / 性能计数器打拍 / 预取地址低 6 位 / 断言打拍），
# 全部由 fm_pins_pre.tcl 一一钉配。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 断言块两侧统一关掉（与 FM 口径一致）。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
#   INITREG=0 / random / <seed>017（第三个真随机档）
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_mmuleaf.py --check
