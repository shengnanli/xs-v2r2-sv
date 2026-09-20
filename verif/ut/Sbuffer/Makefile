MODULE = Sbuffer

RTL_DIR  = ../../../rtl
# ---------------------------------------------------------------------------
#  ★2026-09-20：impl 侧 SbufferData 从 golden 原件改指重写件（codex 0168 裁定）★
#
#  改之前这里是：
#      GOLDEN_DEPS     = SbufferData.sv StorePfWrapper.sv Serializer.sv
#      RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(GOLDEN_DEPS))
#      GOLDEN_SRCS     = $(GOLDEN_RTL)/Sbuffer.sv $(RTL_GOLDEN_DEPS)
#  同一组 golden 文件既进 FM 的 impl 侧（ut_common.mk:167 的
#  FM_IMPL_SRCS = RTL_SRCS + RTL_GOLDEN_DEPS）又进 ref 侧 ⇒ SbufferData 这一块
#  **两侧逐字节同一份**，FM 必判等价。那不是"证明了 SbufferData"，是白送。
#  SbufferData 已有重写件（rtl/memblock/SbufferData.sv，4374 行，自带 UT 目标），
#  所以它必须走 RTL_SRCS。
#
#  ★RTL_SRCS 与 RTL_GOLDEN_DEPS 的语义差别（StdFreeList 7cb6123 已写过一遍）★
#    RTL_SRCS         走 derive_ut_impl.py 改名 _xs，**只**进 impl 侧；
#                     UT 里 Sbuffer_xs 于是例化 SbufferData_xs（重写件），
#                     golden 那侧 Sbuffer 仍例化 golden SbufferData —— 真对比。
#    RTL_GOLDEN_DEPS  不 derive 不改名，UT 两侧**共用同一定义**，FM 时并入 impl 侧。
#  改指必须换变量，不是换路径。
# ---------------------------------------------------------------------------
RTL_SRCS = $(RTL_DIR)/memblock/Sbuffer.sv \
           $(RTL_DIR)/memblock/SbufferData.sv
TB_SRCS  = tb.sv

# ---------------------------------------------------------------------------
#  ref 侧闭包：golden 的三个子模块文件（相对 GOLDEN_RTL 的文件名）。
# ---------------------------------------------------------------------------
FM_REF_DEPS_Sbuffer = SbufferData.sv StorePfWrapper.sv Serializer.sv

# ---------------------------------------------------------------------------
#  ★UNCHANGED_GOLDEN_DEP：StorePfWrapper / Serializer 尚无重写件★
#
#  处置（codex 0168 给的两条路里选"两侧白盒展开真实 child 行为"，理由见下）：
#  两侧仍喂**同一份 golden 文件**，白盒展开，不扩黑盒。
#
#  为什么不选黑盒配对：KunminghuV2Config 下 firtool 已经把这两个模块 DCE 成
#  **一个功能端口都不剩**的空壳 —— golden StorePfWrapper 的端口表只有
#  (clock, reset)，它内部的 Serializer 端口表也只有 (clock, reset)，
#  Serializer 里那 2 个寄存器（enqPtrExt_0_flag / _value）没有任何 fanout 到端口。
#  也就是说这棵子树对 Sbuffer 的**任何输出都不可达**。此时：
#    · 黑盒配对买不到任何东西（一个零输出的黑盒不向父级引入任何自由变量），
#      却要付出 unresolved_blackbox + 判决挂在两个未签核 child 上的代价；
#    · 白盒展开能把 glue（prefetcher 实例存在性与 clock/reset 接线）真的比出来，
#      并且 Serializer 的 2 个寄存器两侧配对受验，没有一处被遮住。
#
#  ★但这**不算**证明了 StorePfWrapper / Serializer★：
#  impl 侧用的是 golden 字节，本 target 对它们**零信息量**。
#  它们在台账里保持 MISSING/UNPROVEN，**不许记 PROVEN_DIRECT**。
#  Sbuffer 本轮的结论因此是**条件性的**：只覆盖 Sbuffer 自身的控制/数据通路 glue，
#  完整目标（含 child 闭包）仍 UNPROVEN —— 见 FM_PREDICTION.md 的"结论边界"。
#
#  机器可见：receipt.json 的 impl_closure 里这两条 kind=golden，一眼能查出来。
#  机器检查：scripts/check_closure_symmetry.py --only Sbuffer（两侧黑盒集均为空）
# ---------------------------------------------------------------------------
UNCHANGED_GOLDEN_DEPS = StorePfWrapper.sv Serializer.sv
RTL_GOLDEN_DEPS       = $(addprefix $(GOLDEN_RTL)/,$(UNCHANGED_GOLDEN_DEPS))

# UT 的 golden 侧：golden 顶层 + golden 三个子模块。
# 与 RTL_GOLDEN_DEPS 重叠的两个由 ut_common.mk 的 GOLDEN_SRCS_UNIQ 去重。
GOLDEN_SRCS = $(GOLDEN_RTL)/Sbuffer.sv \
              $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_Sbuffer))

# 原先这里还有一行 `FM_ELAB = $(GOLDEN_DEPS)`。全仓 grep 过：FM_ELAB **没有任何
# 消费者**（ut_common.mk 不读它、不 export 它；fm_eq.tcl 里只有无关的
# FM_ELAB_ERROR 字符串）。它是死变量，留着只会让人以为 elaborate 集合另有出处。
# 一并删掉。（ICacheDataArray / DuplicatedTagArray 的 Makefile 里也各有一行同样
# 的死变量，不在本 lane 范围内，未动。）

FM_VARIANTS    = Sbuffer
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期只负责"打开 initreg 机制"，取值在运行期由 +vcs+initreg+$(INITREG) 选。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
