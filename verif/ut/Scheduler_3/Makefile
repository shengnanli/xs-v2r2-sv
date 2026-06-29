MODULE = Scheduler_3

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核(golden 同名顶层 wrapper)+ 类型包。svh 由核 include。
RTL_SRCS = $(RTL_DIR)/backend/scheduler_mem_pkg.sv \
           $(RTL_DIR)/backend/Scheduler_3.sv

# golden 黑盒:IQ 例化所需的全部子模块(两侧 u_g/u_i 共享)。
BB_DEPS = AgeDetector_12.sv AgeDetector_21.sv EnqEntryVecMem.sv EnqEntryVecMem_2.sv EnqEntry_20.sv EnqEntry_24.sv EnqEntry_30.sv EnqPolicy_14.sv EntriesLdu.sv EntriesStaMou.sv EntriesStdMoud.sv EntriesVlduVstu.sv EntriesVlduVstuVseglduVsegstu.sv FuBusyTableRead_105.sv FuBusyTableWrite_105.sv IssueQueueLdu.sv IssueQueueStaMou.sv IssueQueueStdMoud.sv IssueQueueVlduVstu.sv IssueQueueVlduVstuVseglduVsegstu.sv NewAgeDetector_6.sv OthersEntryVecMem.sv OthersEntryVecMem_14.sv OthersEntryVecMem_16.sv OthersEntryVecMem_2.sv OthersEntry_172.sv OthersEntry_174.sv OthersEntry_200.sv OthersEntry_202.sv OthersEntry_242.sv OthersEntry_244.sv UIntCompressor_27_000011100000000000001010101.sv

# UT: u_g=golden 顶层, u_i=可读核顶层(重命名 _xs)。
TB_SRCS = scheduler_variant_xs.sv sched_tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Scheduler_3.sv \
              $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))

# FM: ref=golden 顶层+依赖; impl=可读核+同一批 golden 黑盒。
WRAPPER_SRCS = $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))
FM_VARIANTS = Scheduler_3
FM_REF_DEPS_Scheduler_3 = $(BB_DEPS)

FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# golden 无 reset 的状态寄存器上电为 X,flush 把 X 派生值灌进 don't-care 输出造假阳性。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
