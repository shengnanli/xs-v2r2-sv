# 自动生成：scripts/gen_zj_ut.py 的配套 Makefile（零判断批 G0->G1 迁移）
MODULE = OpenLLC

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/l2/OpenLLC.sv
TB_SRCS = tb.sv

# golden 双例化：golden 顶 + 其全部子模块传递闭包（两侧共用同一份子模块定义，
# 比对的是本目标自己的逻辑；子模块本身由各自的目标去证）。
GOLDEN_SRCS = $(GOLDEN_RTL)/OpenLLC.sv \
              $(GOLDEN_RTL)/DataStorage_4.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_1.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_2.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_5.sv \
              $(GOLDEN_RTL)/Directory_4.sv \
              $(GOLDEN_RTL)/FastArbiter_26.sv \
              $(GOLDEN_RTL)/FastArbiter_29.sv \
              $(GOLDEN_RTL)/FastArbiter_30.sv \
              $(GOLDEN_RTL)/FastArbiter_35.sv \
              $(GOLDEN_RTL)/FastArbiter_43.sv \
              $(GOLDEN_RTL)/FastArbiter_45.sv \
              $(GOLDEN_RTL)/FastArbiter_46.sv \
              $(GOLDEN_RTL)/FastArbiter_48.sv \
              $(GOLDEN_RTL)/FastArbiter_49.sv \
              $(GOLDEN_RTL)/FastArbiter_51.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_3.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_4.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_5.sv \
              $(GOLDEN_RTL)/MMIODiverger.sv \
              $(GOLDEN_RTL)/MMIOMerger.sv \
              $(GOLDEN_RTL)/MainPipe_5.sv \
              $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR_3.sv \
              $(GOLDEN_RTL)/MemUnit.sv \
              $(GOLDEN_RTL)/Queue15_CHIDAT.sv \
              $(GOLDEN_RTL)/Queue15_CHIREQ.sv \
              $(GOLDEN_RTL)/Queue15_CHIRSP.sv \
              $(GOLDEN_RTL)/Queue1_CHIRSP_1.sv \
              $(GOLDEN_RTL)/RNLinkMonitor.sv \
              $(GOLDEN_RTL)/RNXbar.sv \
              $(GOLDEN_RTL)/RXDAT_4.sv \
              $(GOLDEN_RTL)/RXREQ.sv \
              $(GOLDEN_RTL)/RXRSP_4.sv \
              $(GOLDEN_RTL)/RefillUnit.sv \
              $(GOLDEN_RTL)/RequestArb_4.sv \
              $(GOLDEN_RTL)/RequestBuffer_4.sv \
              $(GOLDEN_RTL)/ResponseUnit.sv \
              $(GOLDEN_RTL)/SNLinkMonitor.sv \
              $(GOLDEN_RTL)/SNXbar.sv \
              $(GOLDEN_RTL)/SRAMTemplate_192.sv \
              $(GOLDEN_RTL)/SRAMTemplate_193.sv \
              $(GOLDEN_RTL)/SRAMTemplate_194.sv \
              $(GOLDEN_RTL)/SRAMTemplate_195.sv \
              $(GOLDEN_RTL)/SRAMTemplate_196.sv \
              $(GOLDEN_RTL)/SRAMTemplate_197.sv \
              $(GOLDEN_RTL)/Slice_4.sv \
              $(GOLDEN_RTL)/SnoopUnit.sv \
              $(GOLDEN_RTL)/SubDirectory.sv \
              $(GOLDEN_RTL)/SubDirectory_1.sv \
              $(GOLDEN_RTL)/TXDAT_4.sv \
              $(GOLDEN_RTL)/TXREQ_4.sv \
              $(GOLDEN_RTL)/TXRSP_4.sv \
              $(GOLDEN_RTL)/TXSNP.sv \
              $(GOLDEN_RTL)/TopDownMonitor_1.sv \
              $(GOLDEN_RTL)/array_0_0.sv \
              $(GOLDEN_RTL)/array_0_0_ext.v \
              $(GOLDEN_RTL)/array_0_1.sv \
              $(GOLDEN_RTL)/array_0_1_ext.v \
              $(GOLDEN_RTL)/array_19.sv \
              $(GOLDEN_RTL)/array_19_ext.v \
              $(GOLDEN_RTL)/array_20.sv \
              $(GOLDEN_RTL)/array_20_ext.v \
              $(GOLDEN_RTL)/array_21.sv \
              $(GOLDEN_RTL)/array_21_ext.v \
              $(GOLDEN_RTL)/array_22.sv \
              $(GOLDEN_RTL)/array_22_ext.v \
              $(GOLDEN_RTL)/ram_15x162.sv \
              $(GOLDEN_RTL)/ram_15x422.sv \
              $(GOLDEN_RTL)/ram_15x73.sv

FM_VARIANTS = OpenLLC

# ---------------------------------------------------------------------------
# closure 对称（codex 0153 D68）—— 本轮**第 5 次**撞见 RTL_GOLDEN_DEPS 缺失
# （前四次：零判断批 8 个目标 / ICacheMissUnit / DuplicatedTagArray / 本条）。
#
# 修前实测（scripts/check_closure_symmetry.py --only OpenLLC）：
#   ref  侧 = $(GOLDEN_RTL)/OpenLLC.sv + FM_REF_DEPS_OpenLLC 的 69 个依赖 -> 黑盒 {}
#   impl 侧 = $(RTL_SRCS) 一个文件 + RTL_GOLDEN_DEPS(空)                  -> 黑盒 8 种 11 个
#   => assembly_bbox_not_symmetric:MMIODiverger(ref=0,impl=1)
#   单侧黑盒清单：MMIODiverger/MMIOMerger/RNXbar/SNXbar/RNLinkMonitor/SNLinkMonitor/
#                 Slice_4×4/TopDownMonitor_1 —— 都是 rtl/l2/OpenLLC.sv 直接例化的子模块。
#   这正是 strict 模式下「impl 侧偷偷黑掉一块逻辑」的洞。
#
# 修法：impl 侧读**同一组**闭包文件。这里直接由 FM_REF_DEPS_OpenLLC 派生而不是再抄一份
# 69 行清单 —— 抄一份就会再漂一次，而本条的病因就是两张清单各写各的。
# （RTL_GOLDEN_DEPS 与 GOLDEN_SRCS 在 VCS 命令行上重复给同一文件，是本仓既有形态：
#   DuplicatedTagArray / FTBBank / ICacheDataArray / SRAMTemplate / TLBuffer_13 五个
#   WORKING_PASS 的 UT 都是这个样子，故不动 GOLDEN_SRCS。）
#
# ★未验证声明★：本条只改 elaboration 闭包配置，**没有跑过 FM**。
#   codex 0153 D68：本机（cgroup-v1、无可信 memory containment）不得跑 OpenLLC XL，
#   状态登记为 UNRUNNABLE_RESOURCE_LIMIT_CURRENT_HOST —— 不算 PASS，也不算 RTL mismatch。
#   后续须在有 cgroup-v2 memory controller 或更大内存且可独占的主机上重跑；
#   ★不得以 watcher 人工抢救替代隔离★。见 docs/fastlane_ledger.tsv 同名条目。
#   静态复核（不跑 FM）：python3 scripts/check_closure_symmetry.py --only OpenLLC
# ---------------------------------------------------------------------------
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_OpenLLC))

FM_REF_DEPS_OpenLLC = DataStorage_4.sv Decoupled2LCredit.sv Decoupled2LCredit_1.sv Decoupled2LCredit_2.sv Decoupled2LCredit_5.sv Directory_4.sv FastArbiter_26.sv FastArbiter_29.sv FastArbiter_30.sv FastArbiter_35.sv FastArbiter_43.sv FastArbiter_45.sv FastArbiter_46.sv FastArbiter_48.sv FastArbiter_49.sv FastArbiter_51.sv LCredit2Decoupled_3.sv LCredit2Decoupled_4.sv LCredit2Decoupled_5.sv MMIODiverger.sv MMIOMerger.sv MainPipe_5.sv MaxPeriodFibonacciLFSR_3.sv MemUnit.sv Queue15_CHIDAT.sv Queue15_CHIREQ.sv Queue15_CHIRSP.sv Queue1_CHIRSP_1.sv RNLinkMonitor.sv RNXbar.sv RXDAT_4.sv RXREQ.sv RXRSP_4.sv RefillUnit.sv RequestArb_4.sv RequestBuffer_4.sv ResponseUnit.sv SNLinkMonitor.sv SNXbar.sv SRAMTemplate_192.sv SRAMTemplate_193.sv SRAMTemplate_194.sv SRAMTemplate_195.sv SRAMTemplate_196.sv SRAMTemplate_197.sv Slice_4.sv SnoopUnit.sv SubDirectory.sv SubDirectory_1.sv TXDAT_4.sv TXREQ_4.sv TXRSP_4.sv TXSNP.sv TopDownMonitor_1.sv array_0_0.sv array_0_0_ext.v array_0_1.sv array_0_1_ext.v array_19.sv array_19_ext.v array_20.sv array_20_ext.v array_21.sv array_21_ext.v array_22.sv array_22_ext.v ram_15x162.sv ram_15x422.sv ram_15x73.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
