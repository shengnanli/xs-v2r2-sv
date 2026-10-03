MODULE = ArithVecLeaves5

# 族 A：算术/向量运算叶 ×5。
#   Adder_chain_rnd / VIAluDecoder / VIntAdder64b：纯组合叶，无子模块。
#   DivUnit：golden 闭包 = SRT16DividerDataModule + CSA3_2_3956/3960/3962 + RightShifter。
#   FDivSqrt：golden 闭包 = FloatDivider + FloatDividerR64 + fpsqrt_r16(+_block) +
#     fpdiv_r64_block + CSA3to2_20/24 + ShiftLeftPriorityWithLZDResult + lzc +
#     r4_qds{,_cg,_spec,_v2,_v2_spec}。
# 闭包用 grep 递归实例化关系核实（scripts 侧无吸收、不改写）：
# UT 两侧共用同一份 golden 孩子（RTL_GOLDEN_DEPS），FM 侧 ref/impl 同源同闭包
# （FM_REF_DEPS_*，相对 golden-rtl 的文件名列表）。
RTL_DIR  = ../../../rtl
LEAVES = Adder_chain_rnd DivUnit FDivSqrt VIAluDecoder VIntAdder64b
# FDivSqrt 闭包里已有本仓重写件并签核的开方通路（2026-10-03，fpaddpath-sqrtblock lane）：
#   fpsqrt_r16（verif/ut/fpsqrt_r16）、fpsqrt_r16_block（verif/ut/fpsqrt_r16_block）及其 child
#   r4_qds / r4_qds_spec / r4_qds_cg / lzc（SRTDivSqrtLeaves10，PROVEN_DIRECT）——impl 改读重写件（两侧白盒）。
#   ★UT 侧的限度★：impl 的 FloatDivider 仍是 golden 文件，它例化的是 golden 名 fpsqrt_r16，UT 单一 elaboration
#   里绑到 golden 件（derive 只给 RTL_SRCS 里的模块改名）——所以本 UT 回归不到这条开方通路的重写件；
#   这条通路的 UT 在 verif/ut/fpsqrt_r16 / fpsqrt_r16_block。FM 两侧分容器，impl 容器里只有重写件，证明覆盖到。
FDIVSQRT_REWRITTEN = lzc r4_qds_cg r4_qds r4_qds_spec fpsqrt_r16_block fpsqrt_r16
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES) $(FDIVSQRT_REWRITTEN)))
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES) $(FDIVSQRT_REWRITTEN)))

DIVUNIT_DEPS = SRT16DividerDataModule.sv CSA3_2_3956.sv CSA3_2_3960.sv CSA3_2_3962.sv \
               RightShifter.sv
FDIVSQRT_DEPS = FloatDivider.sv FloatDividerR64.sv fpsqrt_r16.sv fpdiv_r64_block.sv \
                fpsqrt_r16_block.sv CSA3to2_20.sv CSA3to2_24.sv \
                ShiftLeftPriorityWithLZDResult.sv lzc.sv r4_qds.sv r4_qds_cg.sv \
                r4_qds_spec.sv r4_qds_v2.sv r4_qds_v2_spec.sv
# impl 侧仍读 golden 的 FDivSqrt 闭包文件（= FDIVSQRT_DEPS 去掉上面 6 个重写件）
FDIVSQRT_GOLDEN_IMPL = FloatDivider.sv FloatDividerR64.sv fpdiv_r64_block.sv \
                       CSA3to2_20.sv CSA3to2_24.sv ShiftLeftPriorityWithLZDResult.sv \
                       r4_qds_v2.sv r4_qds_v2_spec.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(DIVUNIT_DEPS) $(FDIVSQRT_GOLDEN_IMPL))

# FM_VARIANTS / FM_REF_DEPS 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = Adder_chain_rnd DivUnit FDivSqrt VIAluDecoder VIntAdder64b
FM_REF_DEPS_DivUnit  = $(DIVUNIT_DEPS)
FM_REF_DEPS_FDivSqrt = FloatDivider.sv FloatDividerR64.sv fpsqrt_r16.sv fpdiv_r64_block.sv \
                fpsqrt_r16_block.sv CSA3to2_20.sv CSA3to2_24.sv \
                ShiftLeftPriorityWithLZDResult.sv lzc.sv r4_qds.sv r4_qds_cg.sv \
                r4_qds_spec.sv r4_qds_v2.sv r4_qds_v2_spec.sv

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 块（FDivSqrt 的断言调用未定义的 xs_assert_v2 + 随机初值）；
# 两侧同口径带 SYNTHESIS。
# initreg：编译期开机制、运行期选取值（ut_common 的 INITREG_TAG 会给日志留档）。
# 默认 INITREG=0（常量初值）：DivUnit/FDivSqrt 的输出 payload 寄存器无复位，
# 常量档保证两侧同初态；tb 另有 armed 闸，随机初值档也不会误判。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

# FDivSqrt 唯一 unread 点是 golden 闭包（VectorFloatDividerR64）内两侧同死的
# matched_nc 死位 fp_format_onehot_q_reg[2]，依据与白名单见
# verif/fm_target_config/FDivSqrt.tcl。
# DivUnit 有 6 对 unread 死位，全在两侧共用 golden 孩子 SRT16DividerDataModule
# 内部（aLZCReg/dLZCReg[6] 恒 0 且读者只取 [5:0]；udNegReg_{0,1,3,4}[67] 无
# 读者）——golden 自带死位，与重写无关。它们属 unmatched unread（层次名
# divDataModule vs u_core/u_div、无扇出签名），由本目录 fm_pins.tcl 逐对
# 钉死后交 vmucp 实比。依据与白名单见 verif/fm_target_config/DivUnit.tcl。
# 只作用在这两个目标：vmucp=true 无白名单会被 fm_eq.tcl fail-closed 拒掉，
# 其余 3 个 unread=0 的目标不能开。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = $(if $(filter FDivSqrt DivUnit,$*),true,)

# DivUnit：verification_merge_duplicated_registers 在本目标上两侧合并不对称 ——
# 两侧读的是同一份 golden 孩子 SRT16DividerDataModule（闭包 sha256 相同），但
# merge=on 时 ref 侧比 impl 侧多合并掉 10 个寄存器位（rudPmNegReg_3_*[9]、
# r2udPmNegReg_3_*[12]、r2udPmNegReg_2_2[4]、r2udPmNegReg_2_3[3]，全部成为
# impl-only 孤儿点），余数/商迭代环上 262 个 matched DFF 随后被判
# not equivalent（merge=on 诊断跑：failing=262、unmatched_impl=10；
# merge=off 诊断跑：native SUCCEEDED、passing=3126、failing=0、unverified=0、
# unmatched=0，全部寄存器逐位 1:1 证等价）。UT 双例化 6 seeds x 200k 拍零误。
# 关掉它是加强不是放宽（不黑盒/不跳点/不约束 ref，比较点只增不减），先例见
# scripts/fm_eq.tcl 的 merge 经验注记（RenameBuffer/MulUnit）。只作用在 DivUnit，
# 命令行显式传 FM_MERGE_DUP=... 仍可覆盖（诊断用）。
# FDivSqrt（2026-10-03，fpaddpath-sqrtblock lane）：开方通路 impl 改读重写件后，merge=on 首跑
# evidence/194f78e14165/FDivSqrt 出现同一类不对称合并——ref 侧 fpsqrt_r16 的 f_r_s_q[7:0]/f_r_c_q[9:4,1] 等
# 被合并/判常量，impl 侧对应位不合并（15 个 unmatched），迭代环上 f_r_s_q/f_r_c_q 随之 failing（至少 20，截断）、
# unverified 291。fpsqrt_r16 单独签核（merge=off，evidence/44292961f2c0）两侧逐位 1:1 证等价。
# 与 DivUnit 同理关 merge（加强：比较点只增不减，不黑盒不跳点）。
FM_MERGE_DUP = $(if $(filter DivUnit FDivSqrt,$*),false,)
