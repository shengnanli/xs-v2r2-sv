MODULE = Iprio0Module

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读参数化 primitives xs_iprio_ext (reg_ALL&mask) + xs_iprio6 (六 8 位字段) +
# 四个代表薄 wrapper。覆盖 Iprio 家族全部 3 种结构形态。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_iprio.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/Iprio0Module_wrapper.sv \
               $(RTL_DIR)/backend/Iprio2Module_1_wrapper.sv \
               $(RTL_DIR)/backend/Iprio8Module_wrapper.sv \
               $(RTL_DIR)/backend/Iprio8Module_1_wrapper.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/Iprio0Module.sv $(GOLDEN_RTL)/Iprio2Module_1.sv \
               $(GOLDEN_RTL)/Iprio8Module.sv $(GOLDEN_RTL)/Iprio8Module_1.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: 每个代表 golden(ref) vs impl(primitive + wrapper)。逐 compare-point
# 全等价; 无黑盒/无 dont_verify/无 allow。
# 选“全读”代表证 primitive 位精确干净 SUCCEEDED:
#   Iprio0Module   —— xs_iprio6 六字段全读 (112/0)
#   Iprio8Module_1 —— xs_iprio_ext reg_ALL 全 mask-读 (128/0)
# base 机器态 (Iprio4..14, reg_ALL 死寄存器 rdata=0) 与部分死字段变态
# (Iprio0_1/Iprio2/Iprio2_1) 与 golden 逐位一致但含 golden 自身对称死寄存器
# (matched-unread), 干净 strict 需 main 把这些 top 加入 fm_eq.tcl 的 matched-unread
# 白名单(共享文件, 非本 worker 所有权)。UT 已对 4 形态逐拍验证 rdata 全等 (见 tb.sv)。
FM_VARIANTS = Iprio0Module Iprio8Module_1

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 随机初值注入；UT 定义 SYNTHESIS 关掉以对齐 reset 语义。
VCS += +define+SYNTHESIS
