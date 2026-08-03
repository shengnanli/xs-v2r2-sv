MODULE = VTypeBuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核(glue)。子模块(SyncDataModule/SnapshotGenerator_1/_2)在核内按名例化,
# UT 侧由 GOLDEN_SRCS 提供真子模块实现, 让 golden 与核共享同一子模块行为。
RTL_SRCS = $(RTL_DIR)/backend/VTypeBuffer.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化闭包: golden VTypeBuffer + 全子模块(供 u_g 与 u_i 共用)。
GOLDEN_SRCS = $(GOLDEN_RTL)/VTypeBuffer.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_3.sv \
              $(GOLDEN_RTL)/DataModule__16entry_12.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_1.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_2.sv

# FM(assembly): impl 侧 = 可读核 + golden 同名 wrapper。ref 侧仅 golden VTypeBuffer.sv。
# FM_REF_DEPS 留空 → 3 子模块两侧 hdlin_unresolved_modules=black_box 对称黑盒
# (SyncDataModuleTemplate__64entry_3 / SnapshotGenerator_1 / SnapshotGenerator_2, 均已
#  独立 AUX 闭合 → assembly_depends 合法), 本目标只证 VTypeBuffer 自身 glue。
# assembly 因 strict 拒任何黑盒; 3 子模块作声明对称 unresolved_blackbox 边界。
WRAPPER_SRCS = $(RTL_DIR)/backend/VTypeBuffer_wrapper.sv
FM_VARIANTS = VTypeBuffer
FM_MODE = assembly
FM_ALLOWLIST = ../../signoff/allow/VTypeBuffer.json
# allow.json 由 official runner 经 manifest allow_ref(verif/signoff/allow/VTypeBuffer.json)
# 绑定 + hash 入证据; FM_ALLOWLIST(整数, 仅 make 侧 legacy fm_verdict 用)保持默认 0
# —— 3 子模块是 matched blackbox pair(非 unmatched 点), 不占 unmatched 配额。

# 可读核逐字复刻 golden → 每寄存器 1:1 同名双射。默认 merge_duplicated_registers=true
# 会把 enqPtrVec_2_value[0]/enqPtrVec_4_value[1] 在一侧并入重复寄存器另侧不并→2 unmatched
# + 6 个 vtypeBuffer.io_waddr[*] 黑盒输入 miscompare。关掉合并(更严, 非放宽)→完美 1:1。
FM_MERGE_DUP = false
# 118 对称 matched-unread DFF(核逐字复刻 golden, 完美双射, 只驱动黑盒子模块输入)→
# vmucp 让 FM 实开逐位比较证 passing(289→407), 非 vacuous。须 main 白名单(见证据清单)。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
