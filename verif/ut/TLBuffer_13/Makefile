MODULE = TLBuffer_13

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/TLBuffer_13.sv
TB_SRCS = tb.sv

# ram_* inline elaborate（codex 0151 D60：优先走两侧同一已提交源，不扩 vendor registry）
#
# 这 5 个 ram_* 是 firtool 行为级存储叶子（module 体 = 单个 reg [W-1:0] Memory[0:D-1]
# + 一写口一读口，零设计逻辑）。原先两侧都不读 ⇒ 各黑盒 4 个实例；现在两侧都读
# **同一个绝对路径**（$(GOLDEN_RTL)/ram_*.sv），黑盒清零、边界消失。
#
# 两侧定义必然逐字节相同的依据（已实测，非推断）：
#   impl rtl/memblock/TLBuffer_13.sv 自己**不例化任何 ram_***，它例化的是 golden
#   Queue2_TLBundle{A_19,B_1,C_1,D_20,E_1}——与 ref 侧同一批文件（上面 5 个 .sv）。
#   每个 Queue2_* 内部各例化 1 个 ram_*：A_19->ram_2x119, B_1->ram_2x352,
#   C_1->ram_2x321, D_20->ram_2x283, E_1->ram_sink_2x8。两侧到达路径同源。
#
# 为什么这里 inline 安全、而 L2TlbMissQueue 的 ram_40x47 不安全（禁止外推，codex 明令）：
#   FMR_ELAB-147「Index may take values outside array bound」只在
#   2^width(addr) > depth 时可能触发。这 5 个都是 depth=2 / addr 1 bit ⇒ 2^1 == 2，
#   地址空间与深度精确相等，越界索引在结构上不可能存在。
#   ram_40x47 是 depth=40 / addr 6 bit ⇒ 2^6 = 64 > 40，故必触发，只能另案处理。
#   全量核对见报告（golden 68 个 ram_* 中 58 个满足 2^aw==depth，10 个不满足）。
#
# 机器检查：scripts/check_closure_symmetry.py --only TLBuffer_13
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/Queue2_TLBundleA_19.sv \
                  $(GOLDEN_RTL)/Queue2_TLBundleB_1.sv \
                  $(GOLDEN_RTL)/Queue2_TLBundleC_1.sv \
                  $(GOLDEN_RTL)/Queue2_TLBundleD_20.sv \
                  $(GOLDEN_RTL)/Queue2_TLBundleE_1.sv \
                  $(GOLDEN_RTL)/ram_2x119.sv \
                  $(GOLDEN_RTL)/ram_2x283.sv \
                  $(GOLDEN_RTL)/ram_2x321.sv \
                  $(GOLDEN_RTL)/ram_2x352.sv \
                  $(GOLDEN_RTL)/ram_sink_2x8.sv

FM_REF_DEPS_TLBuffer_13 = Queue2_TLBundleA_19.sv Queue2_TLBundleB_1.sv Queue2_TLBundleC_1.sv Queue2_TLBundleD_20.sv Queue2_TLBundleE_1.sv ram_2x119.sv ram_2x283.sv ram_2x321.sv ram_2x352.sv ram_sink_2x8.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer_13.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_19.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleB_1.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleC_1.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_20.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleE_1.sv \
              $(GOLDEN_RTL)/ram_2x119.sv \
              $(GOLDEN_RTL)/ram_2x352.sv \
              $(GOLDEN_RTL)/ram_2x321.sv \
              $(GOLDEN_RTL)/ram_2x283.sv \
              $(GOLDEN_RTL)/ram_sink_2x8.sv
# inline 之后**边界为空**：两侧黑盒集合都是 {}（静态实测，见 check_closure_symmetry）。
# 零边界的目标没有 assembly 声明可写，按仓内既有惯例回到默认 signoff-strict
# （110+ 个无 FM_MODE 的目标即此），FM_ALLOWLIST 相应归 0。
# 原值为 `FM_MODE = assembly` / `FM_ALLOWLIST ?= 20`（20 = 两侧各 10 个 ram 实例…
# 实为 ref 4x5 + impl 4x5 = 40 的老口径，且本目标从无 verif/allow/TLBuffer_13.json，
# 即 assembly 路径本就走不通）。★未经 FM 重跑验证：strict 另有 unread 等闸，
# integrator 重跑后若 strict 不过，请回看本注释再定。
FM_ALLOWLIST ?= 0
FM_VARIANTS = TLBuffer_13

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
