MODULE = Scheduler_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核(golden 同名顶层 wrapper)+ 类型包。svh 由核 include。
RTL_SRCS = $(RTL_DIR)/backend/scheduler_fp_pkg.sv \
           $(RTL_DIR)/backend/Scheduler_1.sv

# golden 黑盒:IQ 例化所需的全部子模块(两侧 u_g/u_i 共享)。
BB_DEPS = AgeDetector_12.sv AgeDetector_13.sv AgeDetector_8.sv AgeDetector_9.sv EnqEntry_10.sv EnqEntry_12.sv EnqEntry_8.sv EnqPolicy_8.sv EntriesFaluFcvtF2vFmacFdiv.sv EntriesFaluFmac.sv EntriesFaluFmacFdiv.sv FuBusyTableRead_42.sv FuBusyTableRead_43.sv FuBusyTableRead_52.sv FuBusyTableRead_53.sv FuBusyTableWrite_42.sv FuBusyTableWrite_43.sv FuBusyTableWrite_52.sv FuBusyTableWrite_53.sv IssueQueueFaluFcvtF2vFmacFdiv.sv IssueQueueFaluFmac.sv IssueQueueFaluFmacFdiv.sv MultiWakeupQueue_4.sv MultiWakeupQueue_5.sv NewAgeDetector.sv NewAgeDetector_6.sv OthersEntry_104.sv OthersEntry_106.sv OthersEntry_120.sv OthersEntry_122.sv OthersEntry_88.sv OthersEntry_90.sv PipeWithFlush_10.sv PipeWithFlush_11.sv PipeWithFlush_6.sv PipeWithFlush_7.sv PipeWithFlush_8.sv PipeWithFlush_9.sv UIntCompressor_27_000000000000001010100000000.sv

# UT: u_g=golden 顶层, u_i=可读核顶层(重命名 _xs)。
TB_SRCS = scheduler_variant_xs.sv sched_tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Scheduler_1.sv \
              $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))

# FM: ref=golden 顶层+依赖; impl=可读核+同一批 golden 黑盒。
WRAPPER_SRCS = $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))
FM_VARIANTS = Scheduler_1
FM_REF_DEPS_Scheduler_1 = $(BB_DEPS)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# golden 无 reset 的状态寄存器上电为 X,flush 把 X 派生值灌进 don't-care 输出造假阳性。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
