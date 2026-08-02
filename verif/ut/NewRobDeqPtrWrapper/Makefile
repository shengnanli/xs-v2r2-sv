# NewRobDeqPtrWrapper UT + FM Makefile
#   golden NewRobDeqPtrWrapper.sv  (Rob 内实例 deqPtrGenModule, ROB deq 指针生成器)
#   可读核  xs_NewRobDeqPtr_core + 包装层 NewRobDeqPtrWrapper
MODULE = NewRobDeqPtrWrapper

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= /home/eda/xs-env/G0-canonical/golden-rtl

RTL_SRCS     = $(RTL_DIR)/backend/newrobdeqptr_pkg.sv $(RTL_DIR)/backend/NewRobDeqPtr.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/NewRobDeqPtr_wrapper.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/NewRobDeqPtrWrapper.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = NewRobDeqPtrWrapper
# 自包含逻辑叶子 (无子例化 / 无黑盒), signoff-strict。
# FM_MERGE_DUP=false: 8 个 deqPtrVec[i] 指针寄存器彼此值不同(复位 0..7, 运行期各自
#   环形推进), 但某些位的次态签名在 merge=true 启发式下被误合并, 产生 10 个假失配
#   compare point。关闭寄存器合并后 FM 逐个比较全部 153 点 → 0 failing/0 unread 真
#   SUCCEEDED (比 merge=true 多验 10 点)。同 Bku/FAlu/DecodeStage/AtomicsUnit 既有惯例。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 的随机初值注入; 定义 SYNTHESIS 关掉 (两侧从复位起等价)。
VCS += +define+SYNTHESIS
