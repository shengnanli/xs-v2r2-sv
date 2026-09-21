MODULE = StoreQueue

RTL_DIR = ../../../rtl
# 单文件规范：核 + golden 同名 wrapper 同文件。StoreQueue 的可读核例化 5 个
# 子模块（本仓已有重写件），它们必须一起进 UT 的 _xs 派生与 FM 的 impl 侧，
# 否则 UT 会把 golden 的同名子模块编进重写侧（假绿）。
RTL_SRCS = $(RTL_DIR)/memblock/StoreQueue.sv \
           $(RTL_DIR)/memblock/SQDataModule.sv \
           $(RTL_DIR)/memblock/SQData8Module.sv \
           $(RTL_DIR)/memblock/SQAddrModule.sv \
           $(RTL_DIR)/memblock/SQAddrModule_1.sv \
           $(RTL_DIR)/memblock/DatamoduleResultBuffer.sv \
           $(RTL_DIR)/memblock/StoreExceptionBuffer.sv
TB_SRCS = tb.sv

# golden StoreQueue 例化 5 个子模块（SQDataModule 又例化 SQData8Module），
# UT 双例化时 golden 侧闭包必须齐全。
GOLDEN_SRCS = $(GOLDEN_RTL)/StoreQueue.sv \
              $(GOLDEN_RTL)/SQAddrModule.sv \
              $(GOLDEN_RTL)/SQAddrModule_1.sv \
              $(GOLDEN_RTL)/SQDataModule.sv \
              $(GOLDEN_RTL)/SQData8Module.sv \
              $(GOLDEN_RTL)/DatamoduleResultBuffer.sv \
              $(GOLDEN_RTL)/StoreExceptionBuffer.sv

# ★verify_matched_unread_compare_points★：让 FM 真的去比那 41 个「两侧都没人读」
# 的对称死位，而不是跳过它们。
#   第 7 轮（不开 vmucp）实报：Verification SUCCEEDED / passing 76971 / failing 0 /
#   unverified 0 / unmatched 0(0)，但 unread=41 —— strict 下 unread!=0 判 PARTIAL。
#   这 41 个全是 matched_nc（已配对、未比较），逐条都是**两侧对称**的死位：
#     golden REG / REG_1                 <-> mmioStoutFireRegChain{,_1}
#         只喂 assert(!RegNext(RegNext(sbuffer(0).fire) && mmioStout.fire))
#     golden counter[31:0]               <-> timeoutCounter[31:0]
#         只喂 TimeOutAssert(vecExceptionFlag.valid, 3000, ...)
#     golden uncacheUop_fuOpType[8:2]    <-> uncacheUop_fuOpType[8:2]
#         cmoOpCode 只取 [1:0]，高 7 位两侧都没人读
#   本仓按 SYNTHESIS 编译，断言不生成，所以这些位在两侧同样是死的；★份数照 golden 留★，
#   少留一个就会变成 unmatched。开 vmucp 后它们变成真比较点，passing 应当 +41。
#   前后对照见本轮 receipt（76971 -> 77012），这就是「vmucp 不是空转」的证据。
# ★开 vmucp 不等于放宽判据★：它只把「配上了但没比」改成「配上了并且比了」，
#   比不过一样红。不 dont_verify、不加黑盒、不动别的 appvar。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

FM_VARIANTS = StoreQueue
FM_REF_DEPS_StoreQueue = SQAddrModule.sv SQAddrModule_1.sv SQDataModule.sv SQData8Module.sv DatamoduleResultBuffer.sv StoreExceptionBuffer.sv

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 断言块调用未定义的 xs_assert_v2；与 FM 侧口径一致，
# UT 也定义 SYNTHESIS。
#
# initreg：编译期用 +vcs+initreg+random **打开机制**，运行期由 plusarg 选常量档。
# ★双例化 UT 不许在运行期用 +vcs+initreg+random★ —— 它给 golden 与重写两个实例
# 各摇各的随机初值，无复位寄存器（本模块有 2913 个）两侧初态就不同，比出来的
# 差异与重写无关。两个常量档 +0 / +1 两侧必然同初态、又互不相同，是能用的两轮：
#   make run SEED=1                                        # 默认带 +vcs+initreg+0
#   make run SEED=1 SIM_ARGS="+ncycles=200000 +vcs+initreg+1"
# 两轮的日志分别落到 sim_<seed>_initreg0.log / sim_<seed>_initreg1.log（ut_common.mk
# 的 INITREG_TAG 负责），不会互相覆盖。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
