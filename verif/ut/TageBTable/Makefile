MODULE = TageBTable

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/TageBTable.sv
TB_SRCS = tb.sv

# ---------------------------------------------------------------------------
# 子模块边界：**两侧同源白盒**，不是黑盒（2026-09-14 改）
#
# 原先这里把 FoldedSRAMTemplate_20 / WrBypass_32 做成 assembly 对称黑盒。实测那条路
# 走不通：两者都不是厂商宏（不在 verif/vendor_boundary.tsv），declare_allow.py 只能把
# 它们归 green_child，而 green_child 自 codex 0157 D57 起必须持有 tracked 证书，且
# verif/proof_certificates/POLICY.json 的 freeze_commit 目前是 null ——
# validator 一律 fail-closed（green_child_policy_no_freeze_commit）。整仓当前没有任何
# 一份证书，TageTable 家族是唯一用 green_child 的目标，也就是唯一被这堵墙挡住的。
#
# 改法不是等证书，而是**把抽象去掉**：golden 的子模块闭包同时进 ref 与 impl 两侧
# elaborate（IMSIC 消黑盒的同一套做法）。于是
#   - 子模块不再是黑盒，本层 glue + 子模块内部一起受验（证明只会更强，不会更弱）；
#   - 剩下的唯一黑盒是 array_4_ext（SRAM 编译器行为级叶子，已在 vendor_boundary.tsv
#     逐条审定，两侧读同一份 .v），类别 vendor_macro，不需要任何证书；
#   - impl 侧例化子模块的端口连线也被真的检查了（黑盒时端口错配是看不出来的）。
# 重写版子模块（rtl/common/FoldedSRAMTemplate_20.sv、rtl/frontend/WrBypass_32.sv）
# 各有独立 target 与独立签核，**不**进本目标的闭包——本目标不重复证明它们。
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/FoldedSRAMTemplate_20.sv \
                  $(GOLDEN_RTL)/SplittedSRAMTemplate_23.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_64.sv \
                  $(GOLDEN_RTL)/sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv \
                  $(GOLDEN_RTL)/array_4.sv \
                  $(GOLDEN_RTL)/MbistClockGateCell.sv \
                  $(GOLDEN_RTL)/ClockGate.sv \
                  $(GOLDEN_RTL)/WrBypass_32.sv \
                  $(GOLDEN_RTL)/IndexableCAMTemplate_32.sv \
                  $(GOLDEN_RTL)/data_mem_8x4.sv

# UT 双例化只替换 TageBTable 本体；子模块闭包由 RTL_GOLDEN_DEPS 提供（两侧共用），
# 这里只剩 golden 本体与厂商叶子行为模型（array_4_ext 只给 VCS，不进 FM 任一侧）。
GOLDEN_SRCS = $(GOLDEN_RTL)/TageBTable.sv \
              $(GOLDEN_RTL)/array_4_ext.v

# FM ref 侧闭包 = 与 RTL_GOLDEN_DEPS 同一组文件（同名同字节），impl 侧经 RTL_GOLDEN_DEPS
# 并入。两侧同源 ⇒ 子模块白盒且天然对称。
FM_REF_DEPS_TageBTable = FoldedSRAMTemplate_20.sv SplittedSRAMTemplate_23.sv SRAMTemplate_64.sv \
                         sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv array_4.sv \
                         MbistClockGateCell.sv ClockGate.sv \
                         WrBypass_32.sv IndexableCAMTemplate_32.sv data_mem_8x4.sv
FM_MODE = assembly
FM_ALLOWLIST ?= 0
FM_VARIANTS = TageBTable

# matched-unread 加强（vmucp）：本目标残余的 10 个 unread 点全是 matched_nc 且严格双射
# （ref 10 ↔ impl 10，末段名同为 s1_idx_reg[1..10]）。这不是 waiver —— true 是要求 FM
# **多证**这 10 点而不是把它们记成 Not-Compared。依据与"这些位是什么"写在
# scripts/fm_eq.tcl 的白名单注释里（加强后 passing 381→391，failing 仍 0）。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
