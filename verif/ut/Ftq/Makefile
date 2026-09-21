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

# ★FM_MERGE_DUP 留在 FM 默认 true —— 实测关掉会把本目标打红★
#
# 关掉 merge 本身是加强（不黑盒、不跳点、不约束 ref，比较点只增不减），
# 别的目标（Rob / RenameBuffer / MulUnit）靠它转绿。本目标反过来：
#
#   evidence/2ef304c666ad/Ftq  FM_MERGE_DUP=false  ★FAILED★
#     matched 3494(user)+65240(name)+1676(signature)=70410
#     ★unmatched 1382(ref) / 220(impl)★，failing 20（被 limit 截断）、unverified 9437
#
# 失配的是**扇出复制的结构差，不是功能差**：golden 为切扇出把 ftq_pc_mem 的读数据
# 各复制了 5 份（pc_mem_ifu_ptr_rdata_REG / _REG_1.._REG_4 与
# pc_mem_ifu_plus1_rdata_REG / _REG_1.._REG_4，各 50 位 × startAddr/nextLineAddr
# 两字段），可读核每族只留一份（toIfuPc_cur_* / toIfuPc_p1_*，合计 200 位，
# 正是 impl 侧 220 个失配点里的 200 个）。merge 打开时 FM 把 golden 那 5 份并成一个
# 代表再比，两侧逐点对上；merge 关掉后 golden 多出来的复制找不到对象。
# 这正是 verification_merge_duplicated_registers 存在的理由，不是可读核的缺陷。
#
# ★代价：fm_predict 的模型在 merge=true 时只剩一条宽 regs 的上界带★
# （本目标 regs 74120 / expected 76113，带宽 97.4%，工具自己标"近乎无信息"）。
# 那条带留下的 5322 余额**已被上面这次判别性实验测死**，不是推断：
#   merge=true   比较点 66481（全 matched，unmatched 0）+ unread 4282 + const 28
#   merge=false  比较点 70410+1382=71792          + unread 4293 + const 28
#   两次之差      71792-66481 = 5311   4293-4282 = 11   合计 ★5322★
#   且 merge=false 侧逐列闭合到模型：
#     Port  passing 1305 + unverified 688                        = 1993 = outs
#     DFF   (59648+20+8749) + unmatched_ref 1382 + unread 4293 + const 28
#                                                                = 74120 = regs
#   即 expected 76113 在 merge 关掉时**逐位成立**，5322 就是被合并掉的寄存器位。

include ../../../scripts/ut_common.mk

# golden 里 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2（Scala assert 的落地），
# 编译期就报未定义函数；同 Fence/PreDecode/RASStack 先例，UT 两侧统一定义 SYNTHESIS
# 把断言段与随机初值段一起关掉（寄存器起始为 X，比对侧按 $isunknown 跳过未初始化点）。
VCS += +define+SYNTHESIS
