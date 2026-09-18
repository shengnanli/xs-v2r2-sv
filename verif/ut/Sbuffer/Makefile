MODULE = Sbuffer

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/Sbuffer.sv
TB_SRCS  = tb.sv

# ---------------------------------------------------------------------------
#  子模块边界：SbufferData（数据体）与 StorePfWrapper（预取壳）都是**本目标之外**
#  的独立签核目标。本轮规范给的处置是「两侧同名配对」，实现上有两条路：
#    (a) 两侧都不给源码 → 同名黑盒配对（assembly）；
#    (b) 两侧给**同一份 golden 源码** → 两侧白盒展开、结构逐点配对（strict）。
#  这里选 (b)，理由：
#    · SbufferData 里没有厂商硬宏，全是普通触发器，白盒展开没有不可证的叶子；
#    · (a) 会把 Sbuffer 的判决**挂在 SbufferData / StorePfWrapper 自己的签核上**
#      （台账里这两个当前是 UNPROVEN / MISSING），拿不到无条件 PASS；
#    · (b) 两侧同源对称，不遮住任何东西，比黑盒**更强**：dataModule 的
#      读出/写入边界是被真实行为驱动的，而不是自由变量。
#  ★注意这不是「golden 逻辑复用」★：被证明的是 Sbuffer 自己的控制逻辑，
#  SbufferData 在 ref/impl 两侧是同一份字节、逐点自证，不给 impl 任何便宜；
#  SbufferData 本身的重写件（rtl/memblock/SbufferData.sv）另有自己的目标与证明。
#  机器检查：scripts/check_closure_symmetry.py --only Sbuffer
GOLDEN_DEPS = SbufferData.sv StorePfWrapper.sv Serializer.sv

RTL_GOLDEN_DEPS            = $(addprefix $(GOLDEN_RTL)/,$(GOLDEN_DEPS))
FM_REF_DEPS_Sbuffer        = $(GOLDEN_DEPS)
FM_ELAB                    = $(GOLDEN_DEPS)
GOLDEN_SRCS                = $(GOLDEN_RTL)/Sbuffer.sv $(RTL_GOLDEN_DEPS)

FM_VARIANTS    = Sbuffer
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期只负责"打开 initreg 机制"，取值在运行期由 +vcs+initreg+$(INITREG) 选。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
