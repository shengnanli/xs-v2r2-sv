MODULE = RXSNP

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/RXSNP.sv
# Queue2_CHISNP(+ram_2x98) 已在 shard E 独立签绿; 此处两侧 elaborate 做整体白盒等价
# (非黑盒). UT 变体与 golden 比对也需真定义。
WRAPPER_SRCS = $(RTL_DIR)/uncore/RXSNP_wrapper.sv $(GOLDEN_RTL)/Queue2_CHISNP.sv $(GOLDEN_RTL)/ram_2x98.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/RXSNP.sv $(GOLDEN_RTL)/Queue2_CHISNP.sv $(GOLDEN_RTL)/ram_2x98.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = RXSNP
FM_REF_DEPS_RXSNP = Queue2_CHISNP.sv ram_2x98.sv

# class-4 对称死寄存器加强(standing rule): RXSNP 有 68 个 ref==impl 双射的 cone-dead DFF
# (64 stallCnt 死锁计数器[SYNTHESIS 下断言裁剪]+4 Queue RAM addr[4:3] 死位), 全部按名 auto-match。
# 开 verify_matched_unread=true 让 FM **真正比较**它们(证等价, 非 waiver), 68 个 Unread→Passing。
# fm_pins.tcl 显式钉死双射防命名漂移。★须 main 把 RXSNP 加入 scripts/fm_eq.tcl 的
#   matched-unread 白名单(line 77)方可绿; 否则该 flag 触发 FM_MODE_ERROR 门控退出。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
