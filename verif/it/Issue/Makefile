MODULE = Issue_IT

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
UT_DIR     = ../../ut

# ===========================================================================
# IT(集成级)Issue 簇:golden Scheduler(Int)(u_g) vs 全重写 Scheduler_it(u_i)
#
#   Scheduler_it  : 顶层端口 = golden Scheduler;module Scheduler→Scheduler_it,
#                   include scheduler_int_iq_connect_it.svh,把 4 个 IQ 例化模块名
#                   改成 *_it(撞名 golden 的 6 个算法模块统一加 _it 后缀)。
#   IssueQueue*_it: 文件含 xs_IssueQueue*_core(重写算法核)+ 同名 wrapper(改 _it),
#                   核内联例化 Entries*_it。
#   Entries*_it   : golden 同名扁平 wrapper(改 _it),例化重写 xs_Entries*_core。
#   xs_Entries*_core / xs_iq_entry_* : 复用 rtl/backend 原文件(名字唯一,不撞名)。
#
#   ⇒ 重写链路:xs_Scheduler_int_core → xs_IssueQueue*_core → xs_Entries*_core
#                → xs_iq_entry_*  全程直连,首次跑"调度→发射队列→条目阵列"重写边界。
#
#   共享 golden 结构/存储原语(非算法,两侧共用,不重命名):
#     AgeDetector(_1) / NewAgeDetector / FuBusyTableRead* / FuBusyTableWrite* /
#     MultiWakeupQueue(_2) / EnqPolicy / UIntCompressor_27_*
# ===========================================================================

# ---------------------------------------------------------------------------
# 重写侧(u_i 链路):IT 装配 + 重写核 + 共享结构原语
# ---------------------------------------------------------------------------
# 类型包(重写核 import)
XS_PKGS = \
    $(RTL_DIR)/backend/iq_acfd_pkg.sv \
    $(RTL_DIR)/backend/iq_ambb_pkg.sv \
    $(RTL_DIR)/backend/iq_abjivvi_pkg.sv \
    $(RTL_DIR)/backend/scheduler_int_pkg.sv

# IT 装配(本目录;含 *_it 改名的 IQ/Entries wrapper + Scheduler_it 顶层)
IT_ASSEMBLY = \
    EntriesAluCsrFenceDiv_wrapper_it.sv \
    EntriesAluMulBkuBrhJmp_wrapper_it.sv \
    EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v_wrapper_it.sv \
    IssueQueueAluCsrFenceDiv_it.sv \
    IssueQueueAluMulBkuBrhJmp_it.sv \
    IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v_it.sv \
    Scheduler_it.sv

# 重写 Entries 核 + IqEntry 核(rtl 原文件,名字 xs_* 唯一,不撞 golden)
XS_CORES = \
    $(RTL_DIR)/backend/EntriesAluCsrFenceDiv.sv \
    $(RTL_DIR)/backend/EntriesAluMulBkuBrhJmp.sv \
    $(RTL_DIR)/backend/EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv \
    $(RTL_DIR)/backend/IqEntryAcfd.sv \
    $(RTL_DIR)/backend/IqEntryAmbb.sv \
    $(RTL_DIR)/backend/IqEntryAbjivvi.sv

# ---------------------------------------------------------------------------
# golden 顶层 + golden 全链(u_g 用)+ 共享结构原语(两侧共用)
# ---------------------------------------------------------------------------
# 共享结构/存储原语(u_i 重写链也例化这些 golden 叶子)
SHARED_STRUCT = \
    $(GOLDEN_RTL)/AgeDetector.sv $(GOLDEN_RTL)/AgeDetector_1.sv \
    $(GOLDEN_RTL)/NewAgeDetector.sv \
    $(GOLDEN_RTL)/FuBusyTableRead.sv $(GOLDEN_RTL)/FuBusyTableRead_2.sv \
    $(GOLDEN_RTL)/FuBusyTableRead_22.sv $(GOLDEN_RTL)/FuBusyTableRead_23.sv \
    $(GOLDEN_RTL)/FuBusyTableRead_26.sv $(GOLDEN_RTL)/FuBusyTableRead_28.sv \
    $(GOLDEN_RTL)/FuBusyTableWrite.sv $(GOLDEN_RTL)/FuBusyTableWrite_22.sv \
    $(GOLDEN_RTL)/FuBusyTableWrite_26.sv \
    $(GOLDEN_RTL)/MultiWakeupQueue.sv $(GOLDEN_RTL)/MultiWakeupQueue_2.sv \
    $(GOLDEN_RTL)/EnqPolicy.sv \
    $(GOLDEN_RTL)/UIntCompressor_27_000011100000000000001010101.sv

# golden 顶层 + golden 链独有(只给 u_g)
GOLD_TOP = \
    $(GOLDEN_RTL)/Scheduler.sv \
    $(GOLDEN_RTL)/IssueQueueAluMulBkuBrhJmp.sv \
    $(GOLDEN_RTL)/IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv \
    $(GOLDEN_RTL)/IssueQueueAluCsrFenceDiv.sv \
    $(GOLDEN_RTL)/EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv \
    $(GOLDEN_RTL)/EntriesAluCsrFenceDiv.sv \
    $(GOLDEN_RTL)/EntriesAluMulBkuBrhJmp.sv \
    $(GOLDEN_RTL)/EnqEntry.sv $(GOLDEN_RTL)/EnqEntry_4.sv $(GOLDEN_RTL)/EnqEntry_6.sv \
    $(GOLDEN_RTL)/OthersEntry.sv $(GOLDEN_RTL)/OthersEntry_44.sv \
    $(GOLDEN_RTL)/OthersEntry_50.sv $(GOLDEN_RTL)/OthersEntry_6.sv \
    $(GOLDEN_RTL)/OthersEntry_66.sv $(GOLDEN_RTL)/OthersEntry_72.sv \
    $(GOLDEN_RTL)/PipeWithFlush.sv $(GOLDEN_RTL)/PipeWithFlush_1.sv

# ---------------------------------------------------------------------------
# 汇总给 ut_common.mk
# ---------------------------------------------------------------------------
RTL_SRCS = $(XS_PKGS) $(XS_CORES) $(IT_ASSEMBLY)

GOLDEN_SRCS = $(GOLD_TOP) $(SHARED_STRUCT)

TB_SRCS = tb.sv

# IT 不做 FM(等价证明是 per-module 的事);此处置空。
FM_VARIANTS =

include ../../../scripts/ut_common.mk

# +incdir:重写 IQ wrapper/核 include rtl/backend 下的 *_ports.svh / *_connect.svh;
#         Scheduler_it / IQ_it / Entries wrapper_it 的 *_it.svh 在本目录。
VCS += +incdir+$(RTL_DIR)/backend +incdir+.
# golden 子模块含 ifndef SYNTHESIS 随机初值/运行时断言;关掉以免随机激励误触 $fatal。
VCS += +define+SYNTHESIS +vcs+initreg+random
# +vcs+initreg+0(runtime):无 reset 寄存器清 0,保证两侧从同一确定态出发。
SIM_ARGS += +vcs+initreg+0
