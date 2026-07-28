MODULE = ExuBlock_2

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口表 / 逻辑 / 连线 svh)。
RTL_SRCS = $(RTL_DIR)/backend/exublock_2_pkg.sv \
           $(RTL_DIR)/backend/ExuBlock_2.sv

TB_SRCS = variants_xs.sv tb.sv

# ============================================================================
# CHILD 闭包(codex_0079 自审合规重做):
#   原配置在 ExeUnit_13-17 边界黑盒 => 无闭包违规(ExeUnit 非 305 非 aux 未证).
#   合规重做 = ExeUnit_13-17 及其**全部**向量 FU 子模块两侧真实 elaborate
#   (golden RTL 同时进 UT/FM 两侧), 直到叶子. 该闭包内**无** vendor SRAM 宏、
#   **无**需黑盒模块 => FM 全白盒(0 black box)strict 证明.
#   pdest[7] "未驱动"问题消失: VFMA/Vppu 等深层 FU 的 io_out_bits_ctrl_pdest[7]
#   在两侧均由同一份 golden RTL 驱动(内部 {1'h0, pdest} 常 0 高位), ExeUnit
#   输出 [6:0] 切片两侧一致 => 无 undriven 失配.
# 闭包 = ExeUnit_13/14/15/16/17 + 向量 FU 及其子模块(含小写模块名 compare_*/
#   fpdiv_*/fpsqrt_*/lzc/r4_qds*/Adder_xb*/slide*Table 等)= 167 golden 模块.
# ============================================================================
CLOSURE_MODS = \
    Adder \
    Adder_18 \
    Adder_2 \
    Adder_chain_rnd \
    Adder_xb \
    Adder_xb_20 \
    Adder_xb_3 \
    Adder_xb_8 \
    BoothEncoderF64F32F16_3 \
    ByteMaskTailGen \
    CLZ_11 \
    CLZ_28 \
    CLZ_29 \
    CLZ_30 \
    CLZ_31 \
    CLZ_6 \
    CLZ_7 \
    CLZ_9 \
    CSA3_2_3987 \
    CSA3_2_3988 \
    CSA3_2_3992 \
    CSA3_2_4017 \
    CSA3_2_4111 \
    CSA3_2_4173 \
    CSA3to2 \
    CSA3to2_124 \
    CSA3to2_125 \
    CSA3to2_127 \
    CSA3to2_132 \
    CSA3to2_20 \
    CSA3to2_24 \
    CSA4to2 \
    CSA4to2_15 \
    CSA4to2_16 \
    CSA_Nto2With3to2MainPipeline \
    CVT16 \
    CVT32 \
    CVT64_1 \
    ClockGate \
    ClosePathAdder \
    ClosePathAdderF16Pipeline \
    ClosePathAdderF16Pipeline_2 \
    ClosePathAdder_2 \
    ClosePathF16Pipeline \
    ClosePathF32WidenF16MixedPipeline \
    ClosePathF32WidenF16MixedPipelineAdder \
    ClosePathF32WidenF16MixedPipelineAdder_2 \
    ClosePathFloatAdderF64WidenPipeline \
    CloseShiftLeftWithMux \
    CloseShiftLeftWithMux_1 \
    CloseShiftLeftWithMux_9 \
    Conversion \
    Conversion_12 \
    Conversion_8 \
    Dispatcher_13 \
    Dispatcher_14 \
    Dispatcher_15 \
    Dispatcher_16 \
    Dispatcher_17 \
    Estimate7 \
    ExeUnit_13 \
    ExeUnit_14 \
    ExeUnit_15 \
    ExeUnit_16 \
    ExeUnit_17 \
    FP_INCVT \
    FarPathAdderF16Pipeline \
    FarPathAdderF64WidenPipeline \
    FarPathF16Pipeline \
    FarPathF32WidenF16MixedAdderPipeline \
    FarPathF32WidenF16MixedPipeline \
    FarPathFloatAdderF64WidenPipeline \
    FarShiftRightWithMuxInvFirst \
    FarShiftRightWithMuxInvFirst_18 \
    FarShiftRightWithMuxInvFirst_2 \
    FloatAdderF16Pipeline \
    FloatAdderF32WidenF16MixedPipeline \
    FloatAdderF64WidenPipeline \
    FloatAdderWidenFormat \
    I8DivNr4 \
    INT2FP \
    IterBlockI8Nr4 \
    IterBlock_v4 \
    IterBlock_v4_4 \
    IterBlock_v4_6 \
    MaskExtractor \
    Mgtu \
    Mgu \
    Permutation \
    Rec7Table \
    Reduction \
    RoundingUnit_11 \
    RoundingUnit_3 \
    RoundingUnit_4 \
    RoundingUnit_8 \
    RoundingUnit_9 \
    Rsqrt7Table \
    SRT16Divint \
    SRT16Divint_4 \
    SRT16Divint_6 \
    SRT4qdsCons \
    SelBlock_v4 \
    ShiftLeftPriorityWithF32EXPResult \
    ShiftLeftPriorityWithF64EXPResult \
    ShiftLeftPriorityWithLZDResult \
    ShiftLeftPriorityWithLZDResult_6 \
    ShiftLeftPriorityWithLZDResult_8 \
    ShiftRightJam \
    ShiftRightJam_2 \
    ShiftRightJam_3 \
    ShiftRightJam_4 \
    SignDec \
    SpecBlock_v4 \
    UIntToContLow0s \
    UIntToContLow1s \
    VCVT \
    VCVT_1 \
    VCVT_2 \
    VCVT_8 \
    VFAlu \
    VFDivSqrt \
    VFMA \
    VFixPoint64b \
    VIAlu \
    VIAluDecoder \
    VIAluFix \
    VIAluSrcTypeModule \
    VIDiv \
    VIMac64b \
    VIMacSrcTypeModule \
    VIMacU \
    VIPU \
    VIntAdder64b \
    VIntFixpAlu64b \
    VIntMisc64b \
    VMask \
    VPPU \
    VPermSrcTypeModule \
    VSetRvfWvf \
    VecDataSplitModule \
    VectorCvt \
    VectorCvtTop \
    VectorFloatAdder \
    VectorFloatDivider \
    VectorFloatDividerR64 \
    VectorFloatFMA \
    VectorIdiv \
    VsetModule \
    compare_2to1 \
    compare_2to1_2 \
    compare_3to1 \
    compare_3to1_1 \
    compare_3to1_2 \
    compare_3to1_6 \
    fpdiv_r64_block_vector \
    fpsqrt_r16_block \
    fpsqrt_vector_r16 \
    lzc \
    lzc_3 \
    lzc_4 \
    r4_qds \
    r4_qds_cg \
    r4_qds_spec \
    r4_qds_v2 \
    r4_qds_v2_spec \
    slidednVs2VdTable \
    slideupVs2VdTable

# golden 闭包文件列表(相对 GOLDEN_RTL)
CLOSURE_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CLOSURE_MODS)))

# UT 双例化: golden ExuBlock_2 + 全闭包(两侧共用同一份 golden 子模块定义)。
GOLDEN_SRCS = $(GOLDEN_RTL)/ExuBlock_2.sv $(CLOSURE_SRCS)

# FM: 全白盒。ref 侧 = golden ExuBlock_2 + 闭包; impl 侧 = 可读核 + wrapper
# + 闭包(u_core 例化 ExeUnit_13-17, 须解析其 golden 内部)。无黑盒 => strict.
FM_REF_DEPS_ExuBlock_2 = $(addsuffix .sv,$(CLOSURE_MODS))
WRAPPER_SRCS = $(RTL_DIR)/backend/ExuBlock_2_wrapper.sv $(CLOSURE_SRCS)
FM_VARIANTS = ExuBlock_2

# 两侧 ExeUnit_13-17 及其向量 FU 闭包为**同一份 golden RTL**(impl 核 u_core 例化
# 与 ref 相同的 golden 子模块层次)⇒ 内部寄存器按层次名逐一对应, 无展平-vs-generate
# 命名差, 无需 merge_duplicated_registers 调和(该优化在 VIMac64b/VectorFloatFMA
# 宽乘法器阵列上近病态耗时且此处零收益)。关闭以加速; 容器自身 5 个 frm 流水寄存器
# 名字清晰按名匹配。同 Bku/Slice_2/DCacheWrapper 等既有 target 用法。
FM_MERGE_DUP = false

# ★2101 对称 matched-unread DFF = golden 向量 FU(VectorFloatFMA/VMask/VIntMisc64b
# 等)内部 cone-dead 寄存器(驱动但输出不喂任何 ExuBlock_2 可观测口), 两侧同款 golden
# RTL ⇒ 完美双射(baseline strict native SUCCEEDED 49279passing/0fail/0unmatched(0(0))
# 但 unread=2101 → strict PARTIAL, unmatched.rpt="No unmatched points" 证全配对)。
# vmucp=true 让 FM 逐位实开比较这 2101 点 ⇒ 全 passing(46368→48469 DFF, +2101),
# unread 0, native SUCCEEDED 51380passing/0fail/0unread。非 vacuous(要 FM 证更多)。
# ★须 main 把 ExuBlock_2 加入 fm_eq.tcl vmucp 白名单(L78)+run_signoff_target.sh
# case + manifest_declarations 列5 true(同 Composer/Slice/StoreQueue 等既有 vmucp
# 目标)。白名单不含时本行触发 FM_MODE_ERROR 退3; 故 CI 门控前须 main 先加白名单。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉以免触发,并关随机化。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
VCS += -assert disable
