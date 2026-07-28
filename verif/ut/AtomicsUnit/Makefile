MODULE = AtomicsUnit

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写 SV: 可读核 xs_AtomicsUnit_core（原子访存 FSM state 0..8）
RTL_SRCS = $(RTL_DIR)/memblock/AtomicsUnit.sv
# WRAPPER_SRCS 仅用于 FM impl 侧(不进 UT 编译): 扁平端口包装 AtomicsUnit +
# golden DummyDPICWrapper_50 + DiffExtLrScEvent（difftest LrSc 事件探针, 纯 DPI 副作用
# 无功能输出; 两侧 elaborate 同一 golden 定义, SYNTHESIS 下 DPI 块被裁为空模块——
# impl 与 ref 同读同层次, 无 unmatched BBPin）。
WRAPPER_SRCS = $(RTL_DIR)/memblock/AtomicsUnit_wrapper.sv \
               $(GOLDEN_RTL)/DummyDPICWrapper_50.sv $(GOLDEN_RTL)/DiffExtLrScEvent.v
# golden 顶层 + 子模块（UT 双例化两侧共用同一定义）
GOLDEN_SRCS = $(GOLDEN_RTL)/AtomicsUnit.sv \
              $(GOLDEN_RTL)/DummyDPICWrapper_50.sv $(GOLDEN_RTL)/DiffExtLrScEvent.v
# UT 变体（impl 顶层改名 AtomicsUnit_xs 以与 golden AtomicsUnit 双例化）
TB_SRCS = variants_xs.sv tb.sv

# FM: 只比 AtomicsUnit 顶层；DummyDPICWrapper_50(+DiffExtLrScEvent) 两侧 elaborate 作为
# 共同子模块（无输出→零比较点, 对称）
FM_VARIANTS = AtomicsUnit
FM_REF_DEPS_AtomicsUnit = DummyDPICWrapper_50.sv DiffExtLrScEvent.v

# 关寄存器合并: golden 保留 4 份常数 0 的 tdata_N_timing_reg(逐个自保持 ~_GEN_2N&self,
# 从不写 1), 默认 merge_duplicated_registers=true 会把 impl 侧这 4 份常数寄存器合并成
# 1 份 → 与 golden 4 份错配(3 unmatched ref)。本模块无扇出复制寄存器(不同于 DataPath),
# 关合并让两侧 4 份 timing 各自独立配对并 passing, 是本模块的正确设定。
FM_MERGE_DUP = false

# 对称内部死位加强(class-4 vmucp): 61 个 matched-unread DFF 是 golden 与 impl 两侧
# 逐位同名双射的 cone-dead 寄存器——golden 存整宽但只读窄片:
#   * dcache_resp_id_reg[1:5]  —— golden 只读 dcache_resp_id[0](success<=id[0]), [5:1] 死;
#   * tdata_0/1/2/3_tdata2_reg[50:63] —— golden trigger 仅比较 tdata2[49:0], [63:50] 死。
# 两侧存储完全一致(非 impl 过宽, 无法 narrow, golden 亦保留), 属对称死位。
# 开 verify_matched_unread=true 让 FM 实开比较证明 61 点 passing(非 waiver)。
# 本 top 须由 main 加入 fm_eq.tcl(line77)/run_signoff_target.sh 的 matched-unread 白名单
# 方可运行(standing rule, main-owned)。见 report。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# golden AtomicsUnit 含 `ifndef SYNTHESIS 的随机初值与断言（unrecognized sta uopIdx /
# checkOneHot / unexpected std / atomic re-receive data / 对齐 / 访问异常等）；UT 随机激励
# 会触发, 故定义 SYNTHESIS 关掉（同时关随机初值注入, 两侧寄存器复位到 0 后同构可比）。
VCS += +define+SYNTHESIS
FM_ALLOWLIST = ../../signoff/allow/AtomicsUnit.json
