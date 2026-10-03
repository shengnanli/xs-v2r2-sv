MODULE = FAlu

RTL_DIR = ../../../rtl
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

# impl 侧（2026-10-03，fpaddpath-sqrtblock lane）：f32/f16 加宽混合加法器的 far/close 两条路径及其孙子
# 已有本仓重写件并各自签核（verif/ut/FpAddPathF32W16 与各叶子），impl 改读重写件（两侧白盒）；
# 其余 golden 叶子（FloatAdder 本体、F64 两条路径、F64 的加法器/移位器）仍两侧同读 golden。
FALU_REWRITTEN = Adder_2 FarShiftRightWithMuxInvFirst_2 FarPathF32WidenF16MixedAdderPipeline \
                 FarPathF32WidenF16MixedPipeline ClosePathF32WidenF16MixedPipelineAdder \
                 ClosePathF32WidenF16MixedPipelineAdder_2 CloseShiftLeftWithMux_1 \
                 ClosePathF32WidenF16MixedPipeline
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(FALU_REWRITTEN))) $(RTL_DIR)/backend/FAlu.sv
FALU_GOLDEN_IMPL = FloatAdder.sv \
                   FloatAdderF64Pipeline.sv FloatAdderF32F16MixedPipeline.sv \
                   FarPathFloatAdderF64WidenPipeline.sv FarPathAdderF64WidenPipeline.sv \
                   FarShiftRightWithMuxInvFirst.sv \
                   ClosePathFloatAdderF64WidenPipeline.sv ClosePathAdder.sv ClosePathAdder_2.sv \
                   CloseShiftLeftWithMux.sv \
                   Adder.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FAlu.sv $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(FALU_REWRITTEN)))
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(FALU_GOLDEN_IMPL))

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
# 白名单在 verif/fm_target_config/<top>.tcl（依据就写在那份文件里），两处须同时生效。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

# ---------------------------------------------------------------------------
# FM_MERGE_DUP=false —— ★加强，不是放宽★（2026-09-20，agent/provefleet2 实测）
#
# 为什么动它：跑前登记的模型预期 2742（闭包每个实例的寄存器位 + 顶层 output 位），
# 而 merge_duplicated_registers=true（全仓默认）那一跑实测 **2466**：
#
#     差额 276，可指认项（constant_reg + unread）只有 7
#     -> ★剩 269 位指认不了★
#
# scripts/fm_predict.py 因为它落在"merge 带"里不判红，但工具自己标了
# 带宽 73.3%、"这条结论近乎无信息" —— merge 打开时 FM 把多少个重复寄存器
# 合并成一个比较点，**从 golden 静态算不出来**，于是那个 passing 数没有可复核的含义。
#
# 关掉之后（同一份 RTL、同一批 appvar、同一份钉点文件，只差这一个 appvar）：
#
#     passing   2466 -> **2575**（多比 109 个点）
#     failing / unverified / aborted / unread_notcompared   全 0
#     unmatched 六项全 0 / 零黑盒 / dont_verify=false / 无放宽 appvar
#     2742(模型) - 2575(实测) = 167 = constant_reg 167  ★逐位指认，余额 0★
#
# 不黑盒、不跳点、不约束 ref，只是要求 FM 逐个而不是合并后比，比较点只增不减
# （先例：verif/ut/MulUnit/Makefile、verif/ut/TXREQ/Makefile，
#  以及 scripts/fm_eq.tcl 里的经验注记）。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 里 `ifndef SYNTHESIS 的断言块调用未定义函数 xs_assert_v2，
# 且随机初始化 initial 块也只在非 SYNTHESIS 下出现——定义 SYNTHESIS 与 FM 侧口径一致。
VCS += +define+SYNTHESIS
