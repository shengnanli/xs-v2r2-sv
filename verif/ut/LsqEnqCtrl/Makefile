# 生成命令（tb.sv）：
#   python3 scripts/gen_zj_ut.py LsqEnqCtrl --out verif/ut/LsqEnqCtrl/tb.sv --min-toggled 303 \
#     --narrow 'io_redirect_valid$=($urandom % 32) == 0' \
#              'io_enq_needAlloc_[0-9]+$=($urandom % 2) ? ($urandom % 4) : 0' \
#              'io_enq_iqAccept_[0-9]+$=(($urandom % 4) != 0)' \
#              '_bits_numLsElem$=((($time/10) % 16) == 0) ? (16 + ($urandom % 16)) : ($urandom % 3)' \
#              'io_lcommit$=$urandom % 3'
# 域收窄理由（★每一条都对着一个"否则永远走不到"的分支★）：
#   redirect_valid 默认 50% → 队列永远在冲刷，入队路径几乎不走；收到 1/32。
#   needAlloc 是 t2_update 的判据（redirect 后第二拍且 6 个口全 0 才回卷）。
#     2 位全随机时"6 个口同时为 0"的概率是 1/4096，配上 1/32 的 redirect，
#     20 万拍只碰得到个位数次 —— 等于回卷路径没测。让每个口有 1/2 概率直接给 0，
#     全 0 概率升到 1/64，实测回卷分支每千拍都在走。
#   iqAccept 是**前缀与**（第一个不接受之后全不算）：50% 时 allocNumber 几乎恒为
#     0 或 1 条，6 口全接受的概率 1/64；偏到 75% 后全接受概率 ~18%。
#   numLsElem：15/16 的拍收到 0..2（否则 lqCounter 一拍见底、canAccept 恒 0，入队
#     路径就没了）；剩下 1/16 的拍**六个口一起**给 16..31。为什么要"一起"：golden
#     把送进 lqIdx/sqIdx 的前缀和截到 7 位 / 6 位（送进 allocNumber 的那一路保留
#     8 位），只有前缀和真的超过 64/128 才看得出截位。各口独立随机时前缀和期望
#     只有 5 左右，跨不过去 —— 实测把"前缀和不截位"这个变异注进去，独立随机的
#     激励 2 万拍**一次都抓不到**；改成按 $time 同拍拉高后立刻抓到
#     （io_enq_resp_5_sqIdx_value g=c i=14）。这就是"定向激励"那一课。
#   lcommit 收到 0..2：与入队速率同量级，队列水位才会在"能收/不能收"之间来回。
MODULE = LsqEnqCtrl

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/LsqEnqCtrl.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/LsqEnqCtrl.sv

FM_VARIANTS = LsqEnqCtrl

include ../../../scripts/ut_common.mk

# 342 个寄存器里只有 8 个带异步复位，其余 334 个（t1/t2/t3、canAccept_REG、
# needAlloc 打拍、6×54 个载荷寄存器）**完全不复位** —— 运行时按全工程惯例用
# +vcs+initreg+0 让两侧同起点。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
