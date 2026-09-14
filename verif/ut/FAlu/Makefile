MODULE = FAlu

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/FAlu.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

# FloatAdder 及其闭包（fudian 浮点加法器，不是本轮重写目标）：
# 已逐字节核对 G0 与 G1 这 19 个文件完全一致，故两侧同源 elaborate，不设黑盒。
FALU_LEAVES = FloatAdder.sv \
              FloatAdderF64Pipeline.sv FloatAdderF32F16MixedPipeline.sv \
              FarPathFloatAdderF64WidenPipeline.sv FarPathAdderF64WidenPipeline.sv \
              FarPathF32WidenF16MixedPipeline.sv FarPathF32WidenF16MixedAdderPipeline.sv \
              FarShiftRightWithMuxInvFirst.sv FarShiftRightWithMuxInvFirst_2.sv \
              ClosePathFloatAdderF64WidenPipeline.sv ClosePathAdder.sv ClosePathAdder_2.sv \
              ClosePathF32WidenF16MixedPipeline.sv \
              ClosePathF32WidenF16MixedPipelineAdder.sv \
              ClosePathF32WidenF16MixedPipelineAdder_2.sv \
              CloseShiftLeftWithMux.sv CloseShiftLeftWithMux_1.sv \
              Adder.sv Adder_2.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FAlu.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(FALU_LEAVES))

FM_VARIANTS = FAlu
FM_REF_DEPS_FAlu = $(FALU_LEAVES)

# matched-unread 加强（vmucp）——★加强证明，不是 waiver★
# 不加强时剩 4 个 matched-unread，卡住 strict 判定(reason=strict_unread!=0)：
#   falu/F32Adder/U_close_path/U_CS4_io_adder_op0_r_reg[23]
#   falu/F32Adder/U_close_path/U_Lshift_io_src_r_reg[24]
#   falu/F32Adder/U_far_path/U_FS1/io_result_r_2_reg[0]
#   falu/F64Adder/U_close_path/U_CS4_io_adder_op0_r_reg[52]
# 这 4 点都在 FALU_LEAVES 里 —— 那些文件 ref 与 impl 读的是**同一份 golden**
# (上面 RTL_GOLDEN_DEPS 与 FM_REF_DEPS_FAlu 是同一个列表)，两侧路径除 u_core 外
# 逐字相同，FM 自己就把它们配成了 matched_nc：ref 4 ↔ impl 4，严格双射，
# 非 matched_nc 的未读项为 0。打开本项是让 FM **多证 4 个点**。
# 白名单在 scripts/fm_eq.tcl（依据写在那一行紧邻的注释里），两处须同时生效。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# golden 里 `ifndef SYNTHESIS 的断言块调用未定义函数 xs_assert_v2，
# 且随机初始化 initial 块也只在非 SYNTHESIS 下出现——定义 SYNTHESIS 与 FM 侧口径一致。
VCS += +define+SYNTHESIS
