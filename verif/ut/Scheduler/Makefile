MODULE = Scheduler

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核(golden 同名顶层 wrapper)+ 类型包。svh 由核 include。
RTL_SRCS = $(RTL_DIR)/backend/scheduler_int_pkg.sv \
           $(RTL_DIR)/backend/Scheduler.sv

# golden 黑盒:4 个 IQ 例化所需的全部子模块(两侧 u_g/u_i 共享)。
BB_DEPS = IssueQueueAluMulBkuBrhJmp.sv IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv IssueQueueAluCsrFenceDiv.sv AgeDetector.sv AgeDetector_1.sv EnqEntry.sv EnqEntry_4.sv EnqEntry_6.sv EnqPolicy.sv EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv EntriesAluCsrFenceDiv.sv EntriesAluMulBkuBrhJmp.sv FuBusyTableRead.sv FuBusyTableRead_2.sv FuBusyTableRead_22.sv FuBusyTableRead_23.sv FuBusyTableRead_26.sv FuBusyTableRead_28.sv FuBusyTableWrite.sv FuBusyTableWrite_22.sv FuBusyTableWrite_26.sv MultiWakeupQueue.sv MultiWakeupQueue_2.sv NewAgeDetector.sv OthersEntry.sv OthersEntry_44.sv OthersEntry_50.sv OthersEntry_6.sv OthersEntry_66.sv OthersEntry_72.sv PipeWithFlush.sv PipeWithFlush_1.sv UIntCompressor_27_000011100000000000001010101.sv

# UT: u_g=golden Scheduler 顶层, u_i=可读核顶层(重命名 _xs)。
TB_SRCS = scheduler_variant_xs.sv sched_tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Scheduler.sv \
              $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))

# FM: ref=golden Scheduler+依赖; impl=可读核+同一批 golden 黑盒。
WRAPPER_SRCS = $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))
FM_VARIANTS = Scheduler
FM_REF_DEPS_Scheduler = $(BB_DEPS)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# golden 无 reset 的状态寄存器上电为 X,flush 把 X 派生值灌进 don't-care 输出造假阳性。
# initreg 让两侧寄存器都从 0 上电,消除 golden 上电 X 假象。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
