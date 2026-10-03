# RegCache Makefile（原为 scripts/gen_zj_ut.py 零判断批的配套；2026-10-03 tb 改由本目录 gen.py 生成）
MODULE = RegCache

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/RegCache.sv
TB_SRCS = tb.sv

# ---------------------------------------------------------------------------
# 结构性修复（agent/diag-structural，2026-09-13）
#
# 症状：native FM FAILED，passing=168 / failing=20(报告上限) / unmatched=2162。
# 根因（与 SNXbar/RNXbar/ITTageTable 同一类）：impl 侧只给了
#       rtl/backend/RegCache.sv，而 golden 同名 wrapper 里例化的 6 个子模块
#         RegCacheDataModule / RegCacheDataModule_1
#         RegCacheAgeTimer   / RegCacheAgeTimer_1
#         RegCacheAgeDetector/ RegCacheAgeDetector_1
#       在 impl 侧无定义 → 被 hdlin_unresolved_modules=black_box 当黑盒；
#       ref 侧却完整 elaborate（这 6 个里一共 2078 个寄存器位：
#         DataModule 16×64+16=1040、DataModule_1 12×64+12=780、
#         AgeTimer 40、AgeTimer_1 32、AgeDetector C(16,2)=120、
#         AgeDetector_1 C(12,2)=66）。**两侧建模不对称**。
#       impl 侧黑盒输入位 1204（393+324+153+144+122+68），ref 侧那 2078 位
#       寄存器全部无对象可配 —— 两项相加即 unmatched 的主体。
# 修法：两侧同源 elaborate（RTL_GOLDEN_DEPS），去黑盒＝加强。
#
# ★ 复跑结论（agent/err3, 2026-09-14, 基线 7acbde8）：上面的结构性修复有效——
#   native FM SUCCEEDED / passing 3830 / failing 0 / unverified 0 / aborted 0 /
#   unmatched compare points 0 / 无黑盒。下面三条待确认项的现状：
#   (1) 顶层 23 个读地址/使能流水寄存器两侧命名完全不同
#       （golden in_addr_* / int_ren_last_REG_* ↔ impl rd_idx_reg / int_ren_reg），
#       fm_eq.tcl 的 auto_match_flattened_arrays 按「叶名词干+下标」配对，词干不同
#       会失配；若签名分析兜不住需在 fm_pins.tcl 里 set_user_match 钉双射。
#     → 已结：实跑 unmatched compare points = 0，签名分析自己兜住了，不需要钉点。
#   (2) golden 的 delayToWakeupQueueRCIdx 三级流水是全宽 5 位，impl 只存低 4 位
#       （rtl/backend/RegCache.sv 注释里写明是刻意丢掉这个 write-never-read 的
#       常数半区位）。这会让 golden 侧多出 **golden-only cone-dead** 未读点。
#     → 已结（agent/err3, 2026-09-14）：走 a) 声明 dead_ref。
#       实测不是当初估的 21 点而是 **6 点**：bit[4] 的驱动是常数（Int 口恒 0 /
#       Mem 口恒 1），verification_merge_duplicated_registers=true 把同驱动同值的
#       寄存器合并——Int 组 4 路合成代表 _0、Mem 组 3 路合成代表 _4，三级流水各
#       一次，2×3=6。逐条依据见 verif/dead_ref/RegCache.json。
#       实跑：native SUCCEEDED / passing 3830 / failing 0 / unverified 0 /
#       unmatched 0 / 无黑盒 ⇒ 判定 PASS_DEAD_REF。
#       没走 b)（改 impl 补回全宽 5 位再 vmucp）：那是为了让 FM 好看而往可读核里
#       塞一个真实设计不需要的死寄存器，与"按真实读取宽度定宽"的可读性口径相反。
#   (3) 6 个子模块里有 4 个的**例化名与 golden 不同**（golden IntRegCacheAgeTimer /
#       MemRegCacheAgeTimer / IntRegCacheRepRCIdx_age / MemRegCacheRepRCIdx_age
#       ↔ impl IntRegCache_age_timer / MemRegCache_age_timer / IntRegCache_rep /
#       MemRegCache_rep；IntRegCache/MemRegCache 两个是一致的）。层次名不同会
#       让 Formality 少一条最直接的配对线索。同批的 RNXbar/SNXbar/ITTageTable
#       实测证明 Formality 能吃下层次差异（impl 多一层 u_core、还用 generate
#       块名，照样 0 unmatched），所以这不一定是问题；**若解冻后 RegCache 仍有
#       unmatched，先试把这 4 个例化名改成与 golden 一致**（纯改名、零功能影响，
#       UT 可立刻回归），再考虑 set_user_match。
#     → 已结：实跑 unmatched = 0，层次/例化名差异确实不构成问题，不用改名。
# ---------------------------------------------------------------------------
# ★ 两侧读重写件（agent/rob-regcache，2026-10-03）★
#   6 个子模块已由本 lane 重写签核（verif/ut/RegCacheLeaves：RegCacheDataModule{,_1} /
#   RegCacheAgeTimer{,_1} / RegCacheAgeDetector{,_1}，三个家族核 + 薄 wrapper）。
#   impl 侧从"与 ref 同源的 golden 子模块"（原 RTL_GOLDEN_DEPS）改为读这 6 个重写件，
#   ref 侧不变（golden RegCache + 6 个 golden 子模块）。子模块仍两侧白盒，无黑盒。
#   UT 双例化：golden 侧照旧编 golden 子模块（GOLDEN_SRCS），重写侧经 derive 改名 _xs。
RC_CHILDREN = RegCacheDataModule RegCacheDataModule_1 RegCacheAgeTimer RegCacheAgeTimer_1 \
              RegCacheAgeDetector RegCacheAgeDetector_1
RTL_SRCS += $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(RC_CHILDREN)))

# golden 双例化：golden 顶 + 6 个 golden 子模块。
GOLDEN_SRCS = $(GOLDEN_RTL)/RegCache.sv $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(RC_CHILDREN)))

FM_VARIANTS = RegCache
FM_REF_DEPS_RegCache = RegCacheAgeDetector.sv RegCacheAgeDetector_1.sv RegCacheAgeTimer.sv RegCacheAgeTimer_1.sv RegCacheDataModule.sv RegCacheDataModule_1.sv

include ../../../scripts/ut_common.mk

# initreg 九档（agent/rob-regcache）：编译期开机制，运行期 INITREG 选 0 / random / <seed>017。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
