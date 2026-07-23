MODULE = IMSIC

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 + pkg。
# 子块处理 (reviewer 裁定: 逻辑黑盒禁, 只 vendor 宏或绿305子可黑盒):
#   IntFile ×7  : 可读逻辑, 非 vendor 非独立305 target ⇒ 必须两侧 elaborate
#                 (golden IntFile.sv 同时进 FM_REF_DEPS(ref 侧) 与 WRAPPER_SRCS(impl 侧),
#                  两侧同名 golden 模块一起 elaborate 受验; SinkC 对称法)。
#                 impl 侧 IMSIC.sv 例化 g_intfile[N].u_intFile, golden 侧例化 intFile/_1.._6,
#                 两侧例化同一 golden IntFile 体 ⇒ IntFile 逻辑白盒受验, 非黑盒。
#   IMSICGateWay: 已重写 = 绿 305 target(SIGNOFF_PASS), 且内含 vendor 宏
#                 msi_vld_req_cpu_chain ⇒ assembly-depends 绿子, 两侧黑盒
#                 (不提供其体给任一 FM 侧 ⇒ hdlin_unresolved=black_box 同名边界)。
RTL_SRCS = $(RTL_DIR)/uncore/imsic_pkg.sv \
           $(RTL_DIR)/uncore/IMSIC.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化所需 golden RTL: IMSIC + IntFile×7 + IMSICGateWay + 3 级同步链
GOLDEN_SRCS = $(GOLDEN_RTL)/IMSIC.sv \
              $(GOLDEN_RTL)/IntFile.sv \
              $(GOLDEN_RTL)/IMSICGateWay.sv \
              $(GOLDEN_RTL)/AsyncResetSynchronizerShiftReg_w1_d3_i0.sv \
              $(GOLDEN_RTL)/AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv

# impl 侧 FM 输入 = 可读核 wrapper + golden IntFile 体(两侧对称 elaborate)。
# IMSICGateWay 体不进(绿子 assembly 黑盒)。
WRAPPER_SRCS = $(RTL_DIR)/uncore/IMSIC_wrapper.sv \
               $(GOLDEN_RTL)/IntFile.sv
FM_VARIANTS = IMSIC
# FM ref 侧依赖 = golden IntFile.sv(与 impl 侧 WRAPPER_SRCS 对称提供)。
# 两侧同 elaborate ⇒ IntFile 选择/置位/claim/topei 逻辑全部受 FM 验证(白盒), 非黑盒。
# IMSICGateWay 两侧都不提供 RTL ⇒ hdlin_unresolved_modules=black_box(绿305子 assembly 边界),
#   其内 vendor 宏 msi_vld_req_cpu_chain 随之黑盒。它作 unresolved_blackbox 声明(非
#   interface_only): 两侧同名未解析模块由 hdlin_unresolved_modules=black_box 自动对称黑盒,
#   allow/IMSIC.json 精确声明该边界(IMSICGateWay 绿305子)。故不需 FM_INTERFACE_ONLY。
FM_REF_DEPS_IMSIC = IntFile.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
