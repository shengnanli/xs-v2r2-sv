MODULE = PrefetchReqBuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写 SV: 可读核 xs_PrefetchReqBuffer_core（含 xs_prefetchreqbuf_pkg）
RTL_SRCS = $(RTL_DIR)/l2/PrefetchReqBuffer.sv
# WRAPPER_SRCS 仅用于 FM impl 侧(不进 UT 编译): 扁平端口包装 + golden 两个
# RRArbiterInit（两侧 elaborate 确定性轮转仲裁逻辑, 非厂商宏, 消除黑盒——impl
# 与 ref 同读同一子模块定义）。
WRAPPER_SRCS = $(RTL_DIR)/l2/PrefetchReqBuffer_wrapper.sv \
               $(GOLDEN_RTL)/RRArbiterInit_12.sv $(GOLDEN_RTL)/RRArbiterInit_13.sv
# golden 顶层 + 其两个仲裁器子模块（UT 双例化两侧共用同一定义）
GOLDEN_SRCS = $(GOLDEN_RTL)/PrefetchReqBuffer.sv \
              $(GOLDEN_RTL)/RRArbiterInit_12.sv $(GOLDEN_RTL)/RRArbiterInit_13.sv
# UT 变体（impl 顶层改名 PrefetchReqBuffer_xs 以与 golden PrefetchReqBuffer 双例化）
TB_SRCS = variants_xs.sv tb.sv

# FM: 只比 PrefetchReqBuffer 顶层；RRArbiterInit_12/_13 两侧 elaborate 作为共同子模块
FM_VARIANTS = PrefetchReqBuffer
FM_REF_DEPS_PrefetchReqBuffer = RRArbiterInit_12.sv RRArbiterInit_13.sv

# 146 个 matched-unread bit(全对称死位, ref↔impl 完美双射):
#   * entries_i.paddrNoOffset[49:42](顶 8 位 × 16 条目 = 128 位): golden 存 50 位
#     paddrNoOffset, 但只写 {8'h0, paddr[47:6]}(42 位)、只读 [41:0](out.tag=
#     [41:9], out.set=[8:0])——顶 8 位在 golden/impl 两侧都恒 0 且不被读, 结构一致;
#   * prev_in_req_full_vaddr[5:0](6 位): 只读 [49:6](s0_conflict_prev 块比较);
#   * s1_in_req_full_vaddr[5:0](6 位): 只读 [49:6](写 vaddrNoOffset);
#   * s3_tlb_resp_paddr_0[5:0](6 位): 只读 [47:6](update_paddr)。
# 三者均为 golden 忠实复刻(存全宽寄存器只读子域), 死位在两侧同构。
# verify_matched_unread_compare_points=true 让 FM **实际比较**这些 matched-unread
# 点(证明双射且逐位相等), 从 Not-Compared 提升为 Passing——是加强证明, 非 waiver。
# PrefetchReqBuffer 须由 main 加入 fm_eq.tcl(line77)/run_signoff_target.sh(line33)
# 的 matched-unread 白名单方可运行本加强(standing rule)。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# golden PrefetchReqBuffer 含 `ifndef SYNTHESIS 的随机初值注入；UT 双例化时定义
# SYNTHESIS 关掉随机初值, 使两侧寄存器复位到 0 后同构可比。
VCS += +define+SYNTHESIS
