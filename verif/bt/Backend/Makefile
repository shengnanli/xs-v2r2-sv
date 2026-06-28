MODULE = Backend_BT

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
UT_DIR     = ../../ut

# ===========================================================================
# BT（块级，Backend 子系统）：golden Backend (u_g) vs 部分重写装配 Backend_bt (u_i)
#
#   Backend_bt：顶层端口 = golden Backend（逐字）；body = golden Backend 互联（权威），
#   只把选定的「可清晰替换」子模块实例的模块名换成 _bt 包装。每个 _bt 包装暴露全套
#   golden 端口，内部例化已验证的 _xs 适配器（端口为 golden 子集 + 真重写 glue，
#   例化 xs_<M>_core 重写核），golden-only input 悬空、golden-only output 接 '0
#   （rewrite 省略的透传/元数据/perf 端口；列入 tb nonfunc，打印不计 PASS）。
#
#   本 BT 覆盖的重写核（真 xs_*_core，grep 可证）：
#       WbFuBusyTable inner_wbFuBusyTable -> WbFuBusyTable_bt -> WbFuBusyTable_xs -> xs_WbFuBusyTable_core
#     （DataPath / BypassNetwork 的 _bt 包装与核已就绪，可经 gen_backend_bt.py 扩入；
#      因其重写核省略较多功能透传端口（preDecode/mem-IQ 元数据/og1resp），会在顶层
#      产生大量 nonfunc 量化分叉，故默认仅纳入 WbFuBusyTable 这一最干净的替换，
#      其余作为可选扩展，详见 status / 报告。）
#
#   其余子模块（CtrlBlock/Scheduler×4/DataPath/ExuBlock×3/WbDataPath/...）保留 golden：
#     这些重写核与 golden 同名（为 ST 直替设计），双例化会命名冲突，需逐模块 _it/_bt
#     重命名机械（IT 仅对 Int Scheduler / Exec / Decode / RenameDispatch / Writeback 完成）。
#   叶子边界（golden 与 rewrite 共用，非算法原语，-y 自动解析）：
#     RegFilePart×N / RFReadArbiter / RFWBCollideChecker / RegCache / ImmExtractor / UIntExtractor。
# ===========================================================================

# ---------------------------------------------------------------------------
# 重写侧（u_i 链路）：pkg + xs_*_core + _xs 适配器 + _bt 包装
# ---------------------------------------------------------------------------
# 注：DataPath 不纳入本 BT —— 其重写核 xs_DataPath_core 例化 difftest 探针
# DummyDPICWrapper_9（ArchIntRegState 变体，端口 io_bits_value_0..7），与 golden
# Backend 全闭包里同名的 DummyDPICWrapper_9（PTW/L2TLB 变体，端口 io_bits_satp…）
# 命名冲突（difftest 探针编号在两上下文不同），VCS 取错定义→端口未定义。
# 且 xs_DataPath_core 省略 346 个功能透传端口（preDecode/mem-IQ 元数据/og1resp），
# 会在顶层产生大量量化分叉。故 DataPath 作可选扩展，需先解决探针重名（局部 stub）。
XS_PKGS = \
    $(RTL_DIR)/backend/bypassnetwork_pkg.sv \
    $(RTL_DIR)/backend/wbfubusytable_pkg.sv \
    $(RTL_DIR)/backend/wbdatapath_pkg.sv \
    $(RTL_DIR)/backend/iq_acfd_pkg.sv \
    $(RTL_DIR)/backend/iq_ambb_pkg.sv \
    $(RTL_DIR)/backend/iq_abjivvi_pkg.sv \
    $(RTL_DIR)/backend/scheduler_int_pkg.sv

XS_CORES = \
    $(RTL_DIR)/backend/BypassNetwork.sv \
    $(RTL_DIR)/backend/WbFuBusyTable.sv \
    $(RTL_DIR)/backend/WbDataPath.sv

# Int Scheduler 子树共享重写核(名字 xs_* / Iq* 唯一, 不撞 golden, 两侧/-y 共享原文件)。
SCHED_XS_CORES = \
    $(RTL_DIR)/backend/EntriesAluCsrFenceDiv.sv \
    $(RTL_DIR)/backend/EntriesAluMulBkuBrhJmp.sv \
    $(RTL_DIR)/backend/EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv \
    $(RTL_DIR)/backend/IqEntryAcfd.sv \
    $(RTL_DIR)/backend/IqEntryAmbb.sv \
    $(RTL_DIR)/backend/IqEntryAbjivvi.sv

XS_ADAPTERS = \
    $(UT_DIR)/BypassNetwork/variants_xs.sv \
    $(UT_DIR)/WbFuBusyTable/variants_xs.sv

# WbDataPath 适配器经 gen_bt.py 改名(difftest 探针 DummyDPICWrapper_24/32/38/44 → _wbdp,
# 避开 golden Backend 全闭包里同号不同端口的真探针), 配套本地空 stub(纯 sink, 不驱动设计)。
XS_LOCAL_ADAPTERS = \
    WbDataPath_xs_bt.sv \
    WbDataPath_dpic_stub_bt.sv

# Int Scheduler 子树 _bt 改名件(gen_bt.py 的 gen_scheduler_int_subtree 生成;
# 6 个 golden 同名算法模块 + Scheduler 顶层加 _bt, 内含 xs_*_core。include 的
# issuequeue_*_ports/connect.svh 复用 rtl/backend(经 +incdir, 只例化 xs core 无撞名)。
SCHED_BT_SUBTREE = \
    IssueQueueAluCsrFenceDiv_bt.sv \
    IssueQueueAluMulBkuBrhJmp_bt.sv \
    IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v_bt.sv \
    EntriesAluCsrFenceDiv_wrapper_bt.sv \
    EntriesAluMulBkuBrhJmp_wrapper_bt.sv \
    EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v_wrapper_bt.sv \
    Scheduler_core_bt.sv

BT_WRAPPERS = \
    BypassNetwork_bt.sv \
    WbFuBusyTable_bt.sv \
    WbDataPath_bt.sv \
    Scheduler_bt.sv

BT_ASSEMBLY = Backend_bt.sv

# ---------------------------------------------------------------------------
# golden 闭包：golden Backend 顶层 + 31 直接子模块类型（u_g 用；更深叶子 -y 自动解析）
#   同时为 u_i 的 xs_*_core 提供共享 golden 叶子（RegFile/ImmExtractor/UIntExtractor…）。
# ---------------------------------------------------------------------------
SUB_DEPS = $(GOLDEN_RTL)/BypassNetwork.sv \
           $(GOLDEN_RTL)/CtrlBlock.sv \
           $(GOLDEN_RTL)/DataPath.sv \
           $(GOLDEN_RTL)/DelayN_1.sv \
           $(GOLDEN_RTL)/ExuBlock.sv \
           $(GOLDEN_RTL)/ExuBlock_1.sv \
           $(GOLDEN_RTL)/ExuBlock_2.sv \
           $(GOLDEN_RTL)/HPerfMonitor_2.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_1.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_10.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_13.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_14.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_16.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_18.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_20.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_23.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_25.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_5.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_7.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_8.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_9.sv \
           $(GOLDEN_RTL)/Og2ForVector.sv \
           $(GOLDEN_RTL)/PFEvent.sv \
           $(GOLDEN_RTL)/Scheduler.sv \
           $(GOLDEN_RTL)/Scheduler_1.sv \
           $(GOLDEN_RTL)/Scheduler_2.sv \
           $(GOLDEN_RTL)/Scheduler_3.sv \
           $(GOLDEN_RTL)/VecExcpDataMergeModule.sv \
           $(GOLDEN_RTL)/WbDataPath.sv \
           $(GOLDEN_RTL)/WbFuBusyTable.sv

# ---------------------------------------------------------------------------
# 汇总给 ut_common.mk
# ---------------------------------------------------------------------------
RTL_SRCS = \
    $(XS_PKGS) $(XS_CORES) $(SCHED_XS_CORES) $(XS_ADAPTERS) $(XS_LOCAL_ADAPTERS) \
    $(SCHED_BT_SUBTREE) $(BT_WRAPPERS) \
    $(BT_ASSEMBLY)

GOLDEN_SRCS = $(GOLDEN_RTL)/Backend.sv $(SUB_DEPS)

TB_SRCS = tb.sv

# BT 不做 FM。
FM_VARIANTS =

include ../../../scripts/ut_common.mk

# golden 含非综合断言/difftest;关 SYNTHESIS 随机初值 + 关随机化,处理 flush-X。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend +incdir+.
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
VCS += -y $(GOLDEN_RTL) +libext+.sv+.v
VCS += -assert disable
