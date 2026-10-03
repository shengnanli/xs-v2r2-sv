# IPrefetchPipe —— ICache 预取流水（iTLB/meta 预查 + 写 WayLookup + 向 MissUnit 发预取）
#
# 子模块只有一个：Arbiter2_ICacheMissReq（两口 miss 请求的固定优先级仲裁）。
# 它是本工程已签核的可读重写件（xs_FixedPriorityArbiter_core 家族），放在
# RTL_GOLDEN_DEPS：不 derive、不改名，golden IPrefetchPipe 与派生出的
# IPrefetchPipe_xs 例化的是**同一份**定义，UT 两侧对称；FM 侧 ref 走 golden 的
# Arbiter2_ICacheMissReq.sv（FM_REF_DEPS），impl 走这份可读件，两侧都完整
# elaborate、无黑盒（同 ICacheMissUnit 的做法）。
MODULE = IPrefetchPipe

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/IPrefetchPipe.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/IPrefetchPipe.sv

RTL_GOLDEN_DEPS = \
  $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
  $(RTL_DIR)/frontend/Arbiter2_ICacheMissReq.sv

FM_VARIANTS = IPrefetchPipe
FM_REF_DEPS_IPrefetchPipe = Arbiter2_ICacheMissReq.sv

# vmucp = 加强证明（让 FM 真的去比 matched-unread 点），不是放宽。
# 第一次 strict 跑（commit 4be234a9，FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS 未开）：
# native SUCCEEDED、passing 910（Port 435 + DFF 475）、failing 0、unmatched 0(0)，
# 但 matched-unread 96 → strict 判 PARTIAL。这 96 个点 FM 已经按名字/签名 1↔1 配上
# （fm_work/IPrefetchPipe/unread_points.txt 每行都是 matched_nc r:… i:…），全是
# **两侧对称**的"存了全宽、只读一截"的 cone-dead 位：
#   s2_req_vaddr_0/1 [49:14] 与 [5:0]（只读 [13:6] 组索引）      42×2 = 84
#   s2_req_paddr_0/1 [5:0]  （只读 [47:6] 块地址 / [47:12] ptag） 6×2 = 12
#   s2_isSoftPrefetch（golden 只在 XSPerfAccumulate 里读，perf 段被编译掉）   1
#   （其中 1 个点被 FM 合并进别的点，实际列出 96）
# 可读核照 golden 存同样的寄存器，所以 impl 侧对称存在同一批死位。开 vmucp 后 FM 把
# 这 96 对当比对点真的去证，passing 应从 910 涨到 1006；不 dont_verify、不黑盒、不约束 ref。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

# 端口顺序也当硬闸（wrapper 与 golden 端口表逐位同序）
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2（Scala assert 的落地），
# 两侧统一定义 SYNTHESIS，把断言段与随机初值段一起关掉。
VCS += +define+SYNTHESIS

# 两档 initreg：编译期打开机制，运行期 +vcs+initreg+random（默认）或 +0（run-initreg0）。
# 本模块无复位寄存器有 4 类（RegNext(s0_fire) / RegNext(s1_need_meta&&ready) /
# RegNext(s1_real_fire) / PMP 结果保持寄存器），golden 与重写各自随机初值不同，
# 但它们全部在进入比对窗口前被写定或被 valid 门控，两档都必须 errors=0。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+random

.PHONY: run-initreg0
run-initreg0:
	$(MAKE) run SEED=$(SEED) SIM_ARGS="+ncycles=$(NCYCLES) +vcs+initreg+0"
