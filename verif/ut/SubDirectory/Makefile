MODULE = SubDirectory

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/SubDirectory.sv
TB_SRCS = tb.sv

# ---------------------------------------------------------------------------
# 黑盒边界下沉到厂商叶子（agent/arb，2026-09-14）
#
# 原状：FM_REF_DEPS 为空、RTL_GOLDEN_DEPS 未设 ⇒ 两侧都把 tagArray/metaArray/
#       lfsr_prng 当未解析黑盒。对称是对称，但这三个 **不是**厂商宏：
#         SRAMTemplate_192 / SRAMTemplate_193  是 firtool 生成的 SRAM 包装逻辑
#         MaxPeriodFibonacciLFSR_3            是 16 位 Fibonacci LFSR（真功能逻辑）
#       它们在本仓库里既没有独立 FM 目标、也没在台账里绿过
#       （docs/child_target_closure.tsv: 三者 UNVERIFIED / NO_FM_TARGET），
#       所以按 declare_allow 的类别只能归 golden_logic_reuse = NO-GO。
#       换句话说：靠 allow 声明把它们放行等于没证。
# 改法：两侧同源 elaborate（golden 同一份文件同时进 impl 侧与 ref 侧），把抽象
#       边界下沉到 SRAM 编译器叶子 array_19_ext / array_20_ext ——
#       它们已逐条审定入 verif/vendor_boundary.tsv（单口 1rw、单时钟 RW0、
#       1024 深；**不是** array_0_1_ext 那个双时钟 1r1w 宏，SubDirectory 与它无关）。
#       这是**去黑盒 = 加强**：比对点变多，抽象面变小。
# 注：这些文件不能再留在 GOLDEN_SRCS——RTL_GOLDEN_DEPS 与 GOLDEN_SRCS 都会进 VCS
#     命令行，列两次就是同一模块重复定义（SNXbar/SourceB 的 Makefile 里记过）。
# ---------------------------------------------------------------------------
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/SRAMTemplate_192.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_193.sv \
                  $(GOLDEN_RTL)/array_19.sv \
                  $(GOLDEN_RTL)/array_20.sv \
                  $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR_3.sv

FM_REF_DEPS_SubDirectory = SRAMTemplate_192.sv SRAMTemplate_193.sv array_19.sv \
                           array_20.sv MaxPeriodFibonacciLFSR_3.sv

# GOLDEN_SRCS 只补 UT 编译需要、而 FM 不读的厂商叶子行为模型（.v）。
GOLDEN_SRCS = $(GOLDEN_RTL)/SubDirectory.sv \
              $(GOLDEN_RTL)/array_19_ext.v \
              $(GOLDEN_RTL)/array_20_ext.v

# FM_MODE=assembly：唯一抽象边界 = 厂商 SRAM 宏叶子 array_19_ext / array_20_ext
# （.v 行为模型，两侧同一文件，FM 不读 ⇒ 对称未解析黑盒）。精确声明见
# verif/allow/SubDirectory.json（逐对象/逐路径/逐类别，非数字配额）。
# FM_ALLOWLIST 是**对称 unmatched 比对点**的上限，与黑盒数量无关；本目标实测
# unmatched=0，所以钉 0（原来的 3 是老战役按"黑盒个数"填的，口径就不对）。
FM_MODE = assembly
FM_ALLOWLIST ?= 0
FM_VARIANTS = SubDirectory

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random +incdir+$(RTL_DIR)/uncore
SIM_ARGS += +vcs+initreg+0
