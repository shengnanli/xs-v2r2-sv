# 自动生成:scripts/gen_slice.py —— 勿手改
MODULE = Slice

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/decls/glue/inst/outassign svh)。
RTL_SRCS = $(RTL_DIR)/l2/slice_pkg.sv \
           $(RTL_DIR)/l2/Slice.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 双例化:顶 Slice.sv + 18 子模块类型的全部叶子。
# 叶子传递闭包列在 golden_filelist.f(每文件一次),由 -f 显式编译——
# 不用 -y:golden 叶子多为自包含 pkg+module,-y 会重复解析触发 Package previously declared。
GOLDEN_SRCS = $(GOLDEN_RTL)/Slice.sv

# ----------------------------------------------------------------------------
# FM 子模块边界(codex_0036 修正裁定):
#   ELAB_SRCS = 3 非 305 逻辑子(DataStorage/RequestBuffer/RXSNP)+ 同类
#     MSHRBuffer/MSHRBuffer_1 的 golden 递归闭包(18 文件)。两侧
#     (ref + impl WRAPPER_SRCS)同源 elaborate,SRAM 模板/MBIST/仲裁/队列逻辑全受验;
#     唯一黑盒边界 = 厂商 SRAM 宏 array_18_ext.v(两侧都不给源)。
#   13 已证 305 SIGNOFF_PASS 子(SinkA/SinkC/GrantBuffer/TX*/RXDAT/RXRSP/Directory/
#     RequestArb/MainPipe_1/MSHRCtl/L2Slice)**不列**在此 → 两侧 unresolved →
#     hdlin_unresolved_modules=black_box 同名对称黑盒(assembly depends_on;
#     allow/Slice.json 声明; assembly_depends.tsv 记依赖闭包)。
# ----------------------------------------------------------------------------
ELAB_SRCS = $(GOLDEN_RTL)/ClockGate.sv $(GOLDEN_RTL)/ClockMux.sv $(GOLDEN_RTL)/DataStorage.sv $(GOLDEN_RTL)/FastArbiter_3.sv $(GOLDEN_RTL)/GatedSplittedSRAM.sv $(GOLDEN_RTL)/L2DataStorage.sv $(GOLDEN_RTL)/MSHRBuffer.sv $(GOLDEN_RTL)/MSHRBuffer_1.sv $(GOLDEN_RTL)/MbistClockGateCell_101.sv $(GOLDEN_RTL)/Queue1_ChosenQBundle.sv $(GOLDEN_RTL)/Queue2_CHISNP.sv $(GOLDEN_RTL)/RXSNP.sv $(GOLDEN_RTL)/RequestBuffer.sv $(GOLDEN_RTL)/SRAMTemplate_144.sv $(GOLDEN_RTL)/SRAMTemplate_151.sv $(GOLDEN_RTL)/array_18.sv $(GOLDEN_RTL)/ram_2x98.sv $(GOLDEN_RTL)/sram_array_1p4096x69m69s1h1l2b_l2_dat.sv

# FM:impl 侧(wrapper->可读核)与 ref 侧在相同层次 elaborate 上述非 305 逻辑子链。
WRAPPER_SRCS = $(RTL_DIR)/l2/Slice_wrapper.sv $(ELAB_SRCS)
FM_VARIANTS = Slice
FM_REF_DEPS_Slice = ClockGate.sv ClockMux.sv DataStorage.sv FastArbiter_3.sv GatedSplittedSRAM.sv L2DataStorage.sv MSHRBuffer.sv MSHRBuffer_1.sv MbistClockGateCell_101.sv Queue1_ChosenQBundle.sv Queue2_CHISNP.sv RXSNP.sv RequestBuffer.sv SRAMTemplate_144.sv SRAMTemplate_151.sv array_18.sv ram_2x98.sv sram_array_1p4096x69m69s1h1l2b_l2_dat.sv

# merge_duplicated_registers=false(非放宽——比较点增多 45290→45366): elaborate 的
# chosenQ(Queue1_ChosenQBundle)无 reset ram 中 task_channel[2] 恒 0 位, merge=true 下
# ref/impl 常数折叠深度不对称(ref 折掉 ram_reg[4]、impl 留 DFF0X)→ reqArb 黑盒输入
# io_sinkA_bits_channel[2] 假失配。关 merge 令各寄存器按名对称保留→逐位比对→消失配。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉并关随机化,处理 flush-X。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/l2
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
# golden 叶子全集(传递闭包),-f 显式列出,每文件一次。
VCS += -f golden_filelist.f
VCS += +libext+.sv+.v
VCS += -assert disable
