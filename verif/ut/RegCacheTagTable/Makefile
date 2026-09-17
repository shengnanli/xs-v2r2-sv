# 生成命令（tb.sv）：
#   python3 scripts/gen_zj_ut.py RegCacheTagTable --out verif/ut/RegCacheTagTable/tb.sv --min-toggled 24 \
#     --narrow 'io_readPorts_[0-9]+_tag$=$urandom % 16' '_bits_pdest$=$urandom % 16' \
#              'io_allocPregs_[0-9]+_bits$=$urandom % 16' \
#              'io_allocPregs_[0-9]+_valid$=($urandom % 8) == 0' \
#              'io_ldCancel_[0-9]+_ld2Cancel$=($urandom % 8) == 0' \
#              'io_og0Cancel_[0-9]+$=($urandom % 4) == 0'
# 域收窄理由：tag/pdest/allocPregs 三者必须落在同一个小值域，表里才会真的出现
# "读口命中""写口撞号""分配撞号"这三种关键相等事件；allocPregs_valid 与 ldCancel
# 若按 50% 驱动，每个条目活不过一拍，cancel 之外的路径全测不到。
MODULE = RegCacheTagTable

RTL_DIR = ../../../rtl
# 三份重写文件一起进：本 UT / FM 把两个半区当**白盒**（两侧都完整 elaborate），
# 不走黑盒装配契约 —— 这两个子模块是本 lane 自己重写的，黑盒掉等于没证。
RTL_SRCS = $(RTL_DIR)/backend/RegCacheTagModule.sv \
           $(RTL_DIR)/backend/RegCacheTagModule_1.sv \
           $(RTL_DIR)/backend/RegCacheTagTable.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/RegCacheTagTable.sv \
              $(GOLDEN_RTL)/RegCacheTagModule.sv \
              $(GOLDEN_RTL)/RegCacheTagModule_1.sv

FM_VARIANTS = RegCacheTagTable
FM_REF_DEPS_RegCacheTagTable = RegCacheTagModule.sv RegCacheTagModule_1.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
