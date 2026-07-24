MODULE = Scheduler_2

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# FM: 关闭重复寄存器合并(与 LLPTW/MainPipe/Bku 同一合法入口变量, 非放宽:
# fm_sidecar_verdict 对该 appvar 仅 domain 校验)。
# 根因: vf 向量 IQ 的 EnqEntry dataSources 存在**结构性恒零位**——src1 enq 值域
# {4'h0,4'h4,4'h5,4'h8} ⇒ bit[1]恒0; src3/src4 值域 {4'h4,4'h8} ⇒ bit[0]恒0
# (唤醒更新也只写 4'h8)。merge_dup=true 时 FM 的重复/常量寄存器合并把 impl 侧
# 这 18 个位扫掉, ref 侧同名位却保留为 "Constrained 0X" 比对点 ⇒ 18 个
# unmatched ref compare points ⇒ strict PARTIAL(siblings int/fp/mem 无此值域
# 收窄, 不受影响)。false 时两侧对称保留、按名配对、verify 通过(常量寄存器
# 转 matched "Constant reg" not-compared, 与 siblings 绿证一致不计数)。

# 手写可读核(golden 同名顶层 wrapper)+ 类型包。svh 由核 include。
RTL_SRCS = $(RTL_DIR)/backend/scheduler_vf_pkg.sv \
           $(RTL_DIR)/backend/Scheduler_2.sv

# golden 黑盒:IQ 例化所需的全部子模块(两侧 u_g/u_i 共享)。
BB_DEPS = AgeDetector_12.sv AgeDetector_15.sv AgeDetector_19.sv AgeDetector_8.sv EnqEntry_14.sv EnqEntry_16.sv EnqEntry_18.sv EnqPolicy_14.sv EnqPolicy_18.sv EntriesVfdivVidiv.sv EntriesVfmaVialuFixVfalu.sv EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv FuBusyTableRead_68.sv FuBusyTableRead_69.sv FuBusyTableRead_71.sv FuBusyTableRead_73.sv FuBusyTableRead_75.sv FuBusyTableRead_79.sv FuBusyTableRead_80.sv FuBusyTableWrite_68.sv FuBusyTableWrite_69.sv FuBusyTableWrite_71.sv FuBusyTableWrite_73.sv FuBusyTableWrite_75.sv FuBusyTableWrite_79.sv FuBusyTableWrite_80.sv IssueQueueVfdivVidiv.sv IssueQueueVfmaVialuFixVfalu.sv IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv NewAgeDetector.sv NewAgeDetector_6.sv OthersEntry_136.sv OthersEntry_138.sv OthersEntry_150.sv OthersEntry_152.sv OthersEntry_164.sv OthersEntry_166.sv

# UT: u_g=golden 顶层, u_i=可读核顶层(重命名 _xs)。
TB_SRCS = scheduler_variant_xs.sv sched_tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Scheduler_2.sv \
              $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))

# FM: ref=golden 顶层+依赖; impl=可读核+同一批 golden 黑盒。
WRAPPER_SRCS = $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))
FM_VARIANTS = Scheduler_2
FM_REF_DEPS_Scheduler_2 = $(BB_DEPS)

FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# golden 无 reset 的状态寄存器上电为 X,flush 把 X 派生值灌进 don't-care 输出造假阳性。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
