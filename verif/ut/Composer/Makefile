# Composer UT/FM 入口 —— BPU 五预测器组合层（装配壳）
#
# 重写件只有一个单文件：rtl/frontend/Composer.sv（package + xs_Composer_core +
# golden 同名 wrapper）。wrapper 里的端口表/子模块输出网/9 个例化块是机械派生区，
# 由 tools/predictor_composer/gen_assembly.py 从 G1 golden 生成，
# tools/predictor_composer/verify_assembly.py 逐条校验 1757 根连接与 golden 一致。
#
# 子模块处置（2026-10-03 agent/bpu-tables 改；之前 5 个预测器全部两侧同源用 golden）：
#   · FauFTB / Tage_SC / ITTage 三个预测器及其子树（SCTable*、TageTable*、TageBTable、ITTageTable*、RegionWays、
#     MaxPeriodFibonacciLFSR、FauFTBWay、SRAMTemplate_68、WrBypass / WrBypass_33、MbistPipeTage / MbistPipeSc* 等）
#     已有签核重写件 ⇒ **两侧白盒**：ref = golden（FM_REF_DEPS_Composer，未改），impl = 重写件（RTL_SRCS）；
#     UT 里 golden 侧读 COMPOSER_GOLDEN_ONLY，重写侧读改名后的重写件。
#   · FTB / RAS 两个预测器、4 个 DelayN、以及 TageTable / ITTageTable / TageBTable 的下一层（Folded/Splitted SRAM、
#     WrBypass_32/41/43 等）照旧两侧同源用 golden（RTL_GOLDEN_DEPS）。
#   · 厂商 SRAM 叶子 array_*_ext.v：改回审定的厂商边界（verif/vendor_boundary.tsv：FM 两侧黑盒，.v 只给 VCS）。
#     之前两侧读成白盒（两侧同一份子树时无妨）；子树换成重写件后，叶子里的存储阵列在父级规模下 FM 配不上
#     （诊断跑 8192 个 tage/bt 存储位 unmatched），而各预测器自己的签核本来就是叶子黑盒。
MODULE = Composer

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/Composer.sv \
           $(RTL_DIR)/frontend/frontend_common_pkg.sv \
           $(RTL_DIR)/common/xs_BpuStagePc.sv \
           $(RTL_DIR)/common/MaxPeriodFibonacciLFSR.sv \
           $(RTL_DIR)/common/xs_PlruReplacer.sv \
           $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_68.sv \
           $(RTL_DIR)/common/IndexableCAMTemplate.sv \
           $(RTL_DIR)/frontend/WrBypass.sv \
           $(RTL_DIR)/frontend/WrBypass_33.sv \
           $(RTL_DIR)/dft/xs_mbist_pipe_core.sv \
           $(RTL_DIR)/dft/MbistPipeTage.sv \
           $(RTL_DIR)/dft/MbistPipeSc.sv \
           $(RTL_DIR)/dft/MbistPipeSc_1.sv \
           $(RTL_DIR)/dft/MbistPipeSc_2.sv \
           $(RTL_DIR)/dft/MbistPipeSc_3.sv \
           $(RTL_DIR)/frontend/FauFTBWay.sv \
           $(RTL_DIR)/frontend/FauFTB.sv \
           $(RTL_DIR)/frontend/RegionWays.sv \
           $(RTL_DIR)/frontend/ITTageTable.sv \
           $(RTL_DIR)/frontend/ITTageTable_1.sv \
           $(RTL_DIR)/frontend/ITTageTable_2.sv \
           $(RTL_DIR)/frontend/ITTageTable_3.sv \
           $(RTL_DIR)/frontend/ITTageTable_4.sv \
           $(RTL_DIR)/frontend/ITTage.sv \
           $(RTL_DIR)/frontend/sctable_pkg.sv \
           $(RTL_DIR)/frontend/SCTable.sv \
           $(RTL_DIR)/frontend/SCTable_1.sv \
           $(RTL_DIR)/frontend/SCTable_2.sv \
           $(RTL_DIR)/frontend/SCTable_3.sv \
           $(RTL_DIR)/frontend/TageTable.sv \
           $(RTL_DIR)/frontend/TageTable_1.sv \
           $(RTL_DIR)/frontend/TageTable_2.sv \
           $(RTL_DIR)/frontend/TageTable_3.sv \
           $(RTL_DIR)/frontend/TageBTable.sv \
           $(RTL_DIR)/frontend/Tage_SC.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/ClockGate.sv \
                  $(GOLDEN_RTL)/DelayN.sv \
                  $(GOLDEN_RTL)/DelayNWithValid.sv \
                  $(GOLDEN_RTL)/DelayNWithValid_1.sv \
                  $(GOLDEN_RTL)/DelayN_1.sv \
                  $(GOLDEN_RTL)/FTB.sv \
                  $(GOLDEN_RTL)/FTBBank.sv \
                  $(GOLDEN_RTL)/FoldedSRAMTemplate.sv \
                  $(GOLDEN_RTL)/FoldedSRAMTemplate_1.sv \
                  $(GOLDEN_RTL)/FoldedSRAMTemplate_20.sv \
                  $(GOLDEN_RTL)/FoldedSRAMTemplate_22.sv \
                  $(GOLDEN_RTL)/FoldedSRAMTemplate_24.sv \
                  $(GOLDEN_RTL)/IndexableCAMTemplate_32.sv \
                  $(GOLDEN_RTL)/IndexableCAMTemplate_41.sv \
                  $(GOLDEN_RTL)/IndexableCAMTemplate_43.sv \
                  $(GOLDEN_RTL)/MbistClockGateCell.sv \
                  $(GOLDEN_RTL)/MbistPipeFtb.sv \
                  $(GOLDEN_RTL)/RAS.sv \
                  $(GOLDEN_RTL)/RASStack.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_36.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_44.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_45.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_64.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_76.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_78.sv \
                  $(GOLDEN_RTL)/SplittedSRAMTemplate_2.sv \
                  $(GOLDEN_RTL)/SplittedSRAMTemplate_23.sv \
                  $(GOLDEN_RTL)/SplittedSRAMTemplate_25.sv \
                  $(GOLDEN_RTL)/SplittedSRAMTemplate_27.sv \
                  $(GOLDEN_RTL)/SplittedSRAMTemplate_3.sv \
                  $(GOLDEN_RTL)/SplittedSRAMTemplate_4.sv \
                  $(GOLDEN_RTL)/WrBypass_32.sv \
                  $(GOLDEN_RTL)/WrBypass_41.sv \
                  $(GOLDEN_RTL)/WrBypass_43.sv \
                  $(GOLDEN_RTL)/array_1.sv \
                  $(GOLDEN_RTL)/array_2.sv \
                  $(GOLDEN_RTL)/array_3.sv \
                  $(GOLDEN_RTL)/array_4.sv \
                  $(GOLDEN_RTL)/array_5.sv \
                  $(GOLDEN_RTL)/array_6.sv \
                  $(GOLDEN_RTL)/data_mem_0_4x2.sv \
                  $(GOLDEN_RTL)/data_mem_8x4.sv \
                  $(GOLDEN_RTL)/sram_array_1p128x24m6s1h0l1b_bp_sc.sv \
                  $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv \
                  $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
                  $(GOLDEN_RTL)/sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv \
                  $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
                  $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv

# golden 侧独有：三个预测器（FauFTB / Tage_SC / ITTage）及其重写过的整棵子树，impl 侧用 RTL_SRCS 里的重写件。
COMPOSER_GOLDEN_ONLY = FauFTB.sv FauFTBWay.sv ITTage.sv ITTageTable.sv ITTageTable_1.sv ITTageTable_2.sv ITTageTable_3.sv ITTageTable_4.sv IndexableCAMTemplate.sv IndexableCAMTemplate_33.sv MaxPeriodFibonacciLFSR.sv MbistPipeIttage.sv MbistPipeIttage_1.sv MbistPipeIttage_2.sv MbistPipeIttage_3.sv MbistPipeIttage_4.sv MbistPipeSc.sv MbistPipeSc_1.sv MbistPipeSc_2.sv MbistPipeSc_3.sv MbistPipeTage.sv RegionWays.sv SCTable.sv SCTable_1.sv SCTable_2.sv SCTable_3.sv SRAMTemplate_68.sv TageBTable.sv TageTable.sv TageTable_1.sv TageTable_2.sv TageTable_3.sv Tage_SC.sv WrBypass.sv WrBypass_33.sv data_mem_0_8x3.sv data_mem_16x12.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Composer.sv $(addprefix $(GOLDEN_RTL)/,$(COMPOSER_GOLDEN_ONLY)) \
              $(addprefix $(GOLDEN_RTL)/,array_1_ext.v array_2_ext.v array_3_ext.v array_4_ext.v array_5_ext.v array_6_ext.v)
FM_VARIANTS = Composer
# 关 merge_duplicated_registers（2026-10-03 agent/bpu-tables）：逐个比，fm_predict 的 passing 模型严格适用。
FM_MERGE_DUP = false
FM_REF_DEPS_Composer = ClockGate.sv DelayN.sv DelayNWithValid.sv DelayNWithValid_1.sv DelayN_1.sv FTB.sv FTBBank.sv FauFTB.sv FauFTBWay.sv FoldedSRAMTemplate.sv FoldedSRAMTemplate_1.sv FoldedSRAMTemplate_20.sv FoldedSRAMTemplate_22.sv FoldedSRAMTemplate_24.sv ITTage.sv ITTageTable.sv ITTageTable_1.sv ITTageTable_2.sv ITTageTable_3.sv ITTageTable_4.sv IndexableCAMTemplate.sv IndexableCAMTemplate_32.sv IndexableCAMTemplate_33.sv IndexableCAMTemplate_41.sv IndexableCAMTemplate_43.sv MaxPeriodFibonacciLFSR.sv MbistClockGateCell.sv MbistPipeFtb.sv MbistPipeIttage.sv MbistPipeIttage_1.sv MbistPipeIttage_2.sv MbistPipeIttage_3.sv MbistPipeIttage_4.sv MbistPipeSc.sv MbistPipeSc_1.sv MbistPipeSc_2.sv MbistPipeSc_3.sv MbistPipeTage.sv RAS.sv RASStack.sv RegionWays.sv SCTable.sv SCTable_1.sv SCTable_2.sv SCTable_3.sv SRAMTemplate_36.sv SRAMTemplate_44.sv SRAMTemplate_45.sv SRAMTemplate_64.sv SRAMTemplate_68.sv SRAMTemplate_76.sv SRAMTemplate_78.sv SplittedSRAMTemplate_2.sv SplittedSRAMTemplate_23.sv SplittedSRAMTemplate_25.sv SplittedSRAMTemplate_27.sv SplittedSRAMTemplate_3.sv SplittedSRAMTemplate_4.sv TageBTable.sv TageTable.sv TageTable_1.sv TageTable_2.sv TageTable_3.sv Tage_SC.sv WrBypass.sv WrBypass_32.sv WrBypass_33.sv WrBypass_41.sv WrBypass_43.sv array_1.sv array_2.sv array_3.sv array_4.sv array_5.sv array_6.sv data_mem_0_4x2.sv data_mem_0_8x3.sv data_mem_16x12.sv data_mem_8x4.sv sram_array_1p128x24m6s1h0l1b_bp_sc.sv sram_array_1p128x76m1s1h0l1b_bp_ittage.sv sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv sram_array_1p512x24m12s1h0l1b_bp_tage.sv sram_array_1p512x40m10s1h0l1b_bp_ftb.sv

# ---------------------------------------------------------------------------
# matched-unread 加强（FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true）
#
# 这是**加强不是放宽**：默认 FM 把"没有输出锥"的未读点记成 Not-Compared 放过；
# 打开后它真的去证这些点等价。本目标的证明因此覆盖全部 526285 个点。
#
# 未读点的构成与逐类死因写在 scripts/fm_eq.tcl 的白名单依据里（Composer 条），
# 这里只记验收：
#
#   不加强的基线（evidence/6a791d008f45/Composer_prepin，跑在本分支的父 commit
#   6a791d0 上，Composer 的证明输入与本 commit 同字节）：
#     native SUCCEEDED / passing 519962 / failing 0 / unverified 0 / aborted 0
#     / unmatched compare points 0 / 无黑盒 / 无 qualification
#     unread = 5923 matched_nc + 400(400) unmatched unread（合计 6323 点）
#     判定 PARTIAL，reason=strict_unread!=0
#
#   fm_pins_pre.tcl 在首次 match 之前把 Composer **本层**那条 cone-dead 的影子
#   PC 流水整条钉成 601 对（modified_reset 1 + s1_pc 200 + s2_pc 200 + s3_pc 200）。
#   钉点集合与实测未读点集合**精确相等**这件事由脚本核对，不是眼看的：
#       python3 ../../../tools/predictor_composer/check_pin_bijection.py \
#               ../../../evidence/6a791d008f45/Composer_prepin/unread_points.txt
#   钉不上任何一条即 error 退出（fail-closed）。
#
#   ★为什么钉 601 而不是基线里报出来的那 400★（实测，别踩第二次）
#   基线里 s1_pc 的 200 点与 modified_reset 是 FM 自己配上的 matched unread，
#   只有 s2/s3 的 400 点是 unmatched。但打开本加强后未读点升级成比对点，
#   s1_pc 那 200 点的配对**掉了**，变成新的 200(200) unmatched unread ——
#   只钉 400 的那一版实测 compare points 526085、判定仍 PARTIAL。
#
#   打开本项后应得：passing 519962 -> 526285（恰好 +6323）、failing 仍 0、
#   unread 归 0。passing 不增 = FM 没真去比，那是空转，不算过。
#
#   另有一条独立于 FM 的旁证：tb.sv 对这 601 位里的 s1/s2/s3 分段寄存器逐拍做
#   层次比对（24 个 `CHECKH`，见 tb.sv:3726-3752），三 seed × 200k 拍
#   hier_errors=0 —— 仿真侧与形式侧指向同一个结论。
# ---------------------------------------------------------------------------
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
# ★initreg（2026-10-03 加，agent/bpu-tables）★：之前本 UT 不给 initreg，全部不复位寄存器 / SRAM 从 X 起步，
# 两侧接的是同一份 golden 子模块，X 传播天然一致。换成重写子模块后，两侧逻辑同功能但表达式形状不同，
# X 的乐观/悲观传播不再一致（实测：seed 1 第 5217 拍 io_out_s3_full_pred_*_br_taken_mask_1 golden=0、重写=X，
# 源头是未初始化 SRAM 读出的 X 经 SC 和/阈值比较）。X 不是硬件取值，按 CONVENTIONS 改用 initreg 三档：
#   INITREG=0 / random / <seed>017；后两档用 initreg 配置文件，其余状态随机、厂商 SRAM 行为模型存储钉 0
#   （两个实例各读"从没写过"的条目时随机值不同 —— tb 先写后读契约，同 verif/ut/ITTage、verif/ut/Tage_SC），
#   并把两侧同源 golden SRAM 包装链的读出保持寄存器也钉 0；另给 +warmup=4000：前 4000 拍（第一次运行中复位之前）不比，
#   等两侧各自同源的 golden 子模块（FTB / RAS）里不复位的流水寄存器被随机激励写过一遍。
INITREG ?= 0
SRAM_LEAVES = array_1_ext array_2_ext array_3_ext array_4_ext array_5_ext array_6_ext FoldedSRAMTemplate FoldedSRAMTemplate_1 FoldedSRAMTemplate_20 FoldedSRAMTemplate_22 FoldedSRAMTemplate_24 SRAMTemplate_36 SRAMTemplate_44 SRAMTemplate_45 SRAMTemplate_64 SRAMTemplate_76 SRAMTemplate_78 SplittedSRAMTemplate_2 SplittedSRAMTemplate_23 SplittedSRAMTemplate_25 SplittedSRAMTemplate_27 SplittedSRAMTemplate_3 SplittedSRAMTemplate_4
ifeq ($(INITREG),0)
SIM_ARGS += +vcs+initreg+0
else
SIM_ARGS += +vcs+initreg+config+$(UT_GEN_DIR)/initreg_$(INITREG).cfg +warmup=4000
endif
$(UT_GEN_DIR)/initreg_%.cfg: Makefile
	@mkdir -p $(UT_GEN_DIR)
	@{ if [ "$*" = random ]; then echo "defaultvalue random"; else echo "defaultvalue random $*"; fi; \
	   for m in $(SRAM_LEAVES); do echo "module $$m 0"; done; } > $@
run: $(if $(filter-out 0,$(INITREG)),$(UT_GEN_DIR)/initreg_$(INITREG).cfg)

# 装配壳保真闸：生成区必须与 G1 golden 同步，且 1757 条例化连接逐条一致。
# 挂成 simv 的 order-only 前置，跟 portlint 一样"每次编译都过一遍"——
# 只放一份不会有人跑的校验脚本，等于没有闸。
TOOLS = ../../../tools/predictor_composer
.PHONY: assemblycheck pincheck
assemblycheck:
	@python3 $(TOOLS)/gen_assembly.py Composer --check
	@python3 $(TOOLS)/verify_assembly.py Composer

# 钉点双射闸：fm_pins_pre.tcl 自带的 fail-closed 只管"每条都钉上了"，管不住
# 多钉/漏钉。这里拿**不加强那次跑**的实测未读点做集合相等核对。同样挂成 simv 的
# order-only 前置——只放一份不会有人跑的校验脚本，等于没有闸。
pincheck:
	@python3 $(TOOLS)/check_pin_bijection.py \
	    ../../../evidence/6a791d008f45/Composer_prepin/unread_points.txt

simv: | assemblycheck pincheck
