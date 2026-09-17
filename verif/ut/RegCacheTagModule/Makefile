# 生成命令（tb.sv）：
#   python3 scripts/gen_zj_ut.py RegCacheTagModule --out verif/ut/RegCacheTagModule/tb.sv --min-toggled 104 \
#       --narrow '_tag$$=$$urandom % 8' 'io_cancelVec_[0-9]+$$=($$urandom % 8) == 0'
# 两处域收窄的理由（★不收窄就是"跑 20 万拍什么都没测到"★）：
#   tag 是 8 位 pdest，全随机时 12 个读口撞上表里 tag 的概率 ~ 12*16/256 每拍看着不小，
#   但"写进去的 tag"也是全随机，命中主要靠巧合；收到 0..7 后每拍都有多口命中，
#   OHToUInt / 多命中 OR 的路径才真被踩到。
#   cancelVec 默认 50% 会把表打空，条目活不过一拍，loadDependency 的老化分支
#   （未写 & 未取消 & dep 非零 → 左移）一次都走不到；收到 1/8 后该分支每拍都在走。
MODULE = RegCacheTagModule

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/RegCacheTagModule.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/RegCacheTagModule.sv

FM_VARIANTS = RegCacheTagModule

include ../../../scripts/ut_common.mk

# golden 里 tag / loadDependency **不复位**（只有 v 带异步复位），所以上电值两侧
# 各自随机就必然不同；按全工程惯例运行时用 +vcs+initreg+0 让两侧同起点。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
