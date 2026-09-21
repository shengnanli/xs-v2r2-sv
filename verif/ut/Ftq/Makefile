MODULE = Ftq

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/Ftq.sv
TB_SRCS  = tb.sv

# golden 顶层（被比对的 ref）
GOLDEN_SRCS = $(GOLDEN_RTL)/Ftq.sv

# Ftq 的 6 个子模块不是本目标：两侧共用同一份 golden 定义（黑盒配对）。
# 闭包 = 5 个存储 + FTBEntryGen + 它们各自的 DataModule 子件，共 12 个文件。
RTL_GOLDEN_DEPS = \
  $(GOLDEN_RTL)/FtqPcMemWrapper.sv \
  $(GOLDEN_RTL)/SyncDataModuleTemplate_FtqPC_64entry.sv \
  $(GOLDEN_RTL)/DataModule_FtqPC_16entry.sv \
  $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry.sv \
  $(GOLDEN_RTL)/DataModule__16entry.sv \
  $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_1.sv \
  $(GOLDEN_RTL)/DataModule__16entry_4.sv \
  $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_2.sv \
  $(GOLDEN_RTL)/DataModule__16entry_8.sv \
  $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_3.sv \
  $(GOLDEN_RTL)/DataModule__16entry_12.sv \
  $(GOLDEN_RTL)/FTBEntryGen.sv

FM_VARIANTS = Ftq
# FM 侧 ref 依赖（与上面同一批文件，FM 由集成者统一安排，此处只声明）
FM_REF_DEPS_Ftq = FtqPcMemWrapper.sv SyncDataModuleTemplate_FtqPC_64entry.sv DataModule_FtqPC_16entry.sv \
  SyncDataModuleTemplate__64entry.sv DataModule__16entry.sv \
  SyncDataModuleTemplate__64entry_1.sv DataModule__16entry_4.sv \
  SyncDataModuleTemplate__64entry_2.sv DataModule__16entry_8.sv \
  SyncDataModuleTemplate__64entry_3.sv DataModule__16entry_12.sv FTBEntryGen.sv

# matched-unread 加强（非 waiver：要求 FM 证明**更多**点）。
# Ftq 的 3395 个 matched-not-compared unread 点是两侧同名同路径的对称死位
# （update_target 3200 / pred_stage 128 / ftq_pd_mem jalTarget 65 /
#  last_cycle_bpu_in_stage 2），下游只有被 firtool 裁掉的 difftest/XSPerf 消费者。
# 打开后这些点进入实比，matched_nc 归零，剩下的 unread 只有 golden-only 的 4282 位
# （verif/dead_ref/Ftq.json，PASS_DEAD_REF）。依据与实测数据见 scripts/fm_eq.tcl 白名单注释。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

# verification_merge_duplicated_registers 关掉（★加强不是放宽★：不黑盒、不跳点、
# 不约束 ref，只是要求逐个而非合并后比，比较点只增不减）。
# 动机是"差额要能逐位指认"：merge 打开时 FM 把重复寄存器并成一个比较点，
# 比较点数就低于寄存器位数，而低多少无法从 golden 静态算出，于是
# scripts/fm_predict.py 只能给一条宽 regs 的上界带 —— 本目标 regs 74120 /
# expected 76113，带宽 97.4%，那条结论近乎无信息。
# 实测对照（同一份 RTL、同一组 pin、只切这一个 appvar）：
#   true  passing 66481 = Port 1993 + DFF 64488，constant_reg 28，unread 4282；
#         模型 76113 与之差 9632，减去 28+4282 后仍有 5322 指认不了。
#   false 见 evidence/<commit>/Ftq（本 Makefile 现在的取值）。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 里 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2（Scala assert 的落地），
# 编译期就报未定义函数；同 Fence/PreDecode/RASStack 先例，UT 两侧统一定义 SYNTHESIS
# 把断言段与随机初值段一起关掉（寄存器起始为 X，比对侧按 $isunknown 跳过未初始化点）。
VCS += +define+SYNTHESIS
