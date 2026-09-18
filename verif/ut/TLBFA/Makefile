
MODULE = TLBFA

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/xs_TLBFA_core.sv \
           $(RTL_DIR)/memblock/TLBFA.sv \
           $(RTL_DIR)/memblock/TLBFA_1.sv \
           $(RTL_DIR)/memblock/TLBFA_2.sv \
           $(RTL_DIR)/memblock/TLBFA_3.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBFA.sv $(GOLDEN_RTL)/TLBFA_1.sv \
              $(GOLDEN_RTL)/TLBFA_2.sv $(GOLDEN_RTL)/TLBFA_3.sv

# 四个变体都是自足叶子：golden 侧 0 子模块、0 厂商宏，故无 FM_REF_DEPS_*。
FM_VARIANTS = TLBFA TLBFA_1 TLBFA_2 TLBFA_3

# matched-unread 加强（**是加强不是放宽**：让 FM 把未读点当真比较点去证，passing 必须增）。
# 依据（strict 首跑实测，四个变体一致）：native SUCCEEDED / failing 0 / unmatched 0 /
# aborted 0 / unverified 0 / 黑盒输出 0 / 无 dont_verify，唯一卡点是 11×PORTS 个
# **对称** unread 点：ref reqVpn[_N]_reg[27..37] ↔ impl u_core/g_port[N].req_vpn_q_reg[27..37]，
# 四个变体都核过是精确双射（键集合完全相同，位恒为 27..37、端口恒为 0..PORTS-1）。
# 两侧同死的原因：reqVpn(=RegNext(vpn)) 的唯一读出点是 genPPN，而 genPPN 最高只取
# vpn[26:18]，bit37..27 没有任何读者（golden 对 reqVpn 的全部切片实测就是
# [26:18]/[17:9]/[8:0]/[3:0]/[2:0]）。
# 白名单在 scripts/fm_eq.tcl，由集成者维护（main d16efc7 已纳入本家族四个变体）。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# ★必须在 include 之后★：ut_common.mk 用的是 `VCS := vcs ...`（简单赋值），
# 写在前面会被整根覆盖掉（本 UT 第一次就这么踩了一脚：SYNTHESIS 没生效，
# golden 的断言块里未定义的 xs_assert_v2 当场 4 个 Error-[IND]）。
#
# golden 里 `ifndef SYNTHESIS 的两块东西必须关掉，口径才与 FM 一致：
#   1) XSError("refill, duplicate with existing entries") 断言块调用未定义的
#      xs_assert_v2；本 UT 的激励**故意**会写重复项（那是制造多命中的唯一办法），
#      不关掉它会满屏断言。
#   2) initial 随机化块；关掉后两侧无复位寄存器一致地起 X，再由 +vcs+initreg 统一给值。
#
VCS += +define+SYNTHESIS +vcs+initreg+random

# ★上电初值两轮都要跑★：本模块 golden 有 7948~8227 位寄存器**不复位**
# （只有 48 个 v 位带复位，见 reset_domain_check.py），只跑一种初值等于没验复位域。
#   make run SEED=1            # 随机上电值（编译期默认）
#   make INITREG=0 run SEED=1  # 全 0 上电值
# 不需要重新编译：initreg 的**取值**是运行期 plusarg，编译行上那个 +vcs+initreg+random
# 只是打开这套机制。照 CONVENTIONS.md 的字面把 +vcs+initreg+0 写到编译行上会当场拒编：
#   Error-[OBSL_OPT_E] Obsolete option 'vcs+initreg+0' used. Please use
#   +vcs+initreg+random at compile time and choose either 0|1|random|<seed>
#   at runtime using +vcs+initreg.        （VCS W-2024.09-SP1 实测）
# 仓库里其它 UT 用的也是运行期写法（SIM_ARGS += +vcs+initreg+0），这里只是把它参数化，
# 好让两轮都能从同一个 simv 跑出来。
INITREG ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
