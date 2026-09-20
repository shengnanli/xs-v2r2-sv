# InstrUncache / InstrMMIOEntry / Arbiter1_InsUncacheResp —— MMIO 取指通路三件套
# tb 里两对双例化：entry 级（状态机）+ 顶层级（含 D 通道 source 分发）。
MODULE = InstrUncache

RTL_DIR = ../../../rtl
# InstrMMIOEntry.sv 必须排在最前：里面的 instr_mmio_entry_pkg 要先编译。
RTL_SRCS = $(RTL_DIR)/frontend/InstrMMIOEntry.sv \
           $(RTL_DIR)/frontend/Arbiter1_InsUncacheResp.sv \
           $(RTL_DIR)/frontend/InstrUncache.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/InstrMMIOEntry.sv \
              $(GOLDEN_RTL)/Arbiter1_InsUncacheResp.sv \
              $(GOLDEN_RTL)/InstrUncache.sv

FM_REF_DEPS_InstrUncache = InstrMMIOEntry.sv Arbiter1_InsUncacheResp.sv
FM_VARIANTS = InstrMMIOEntry Arbiter1_InsUncacheResp InstrUncache

# matched-unread 加强（vmucp）——★加强证明，不是 waiver★
# 与 fm_pins.tcl 配套：钉点把 entries_0 锁存地址的死最低位配成一对（两侧同为死位，
# 1↔1 严格双射），本项让 FM **真去比这一对**，而不是记作 Not-Compared。
# 白名单在 verif/fm_target_config/<top>.tcl（依据就写在那份文件里），两处须同时生效。
# 注意本项对同目录三个变体一起生效：InstrMMIOEntry / Arbiter1_InsUncacheResp
# 若出现未配对的 unread 不受影响（vmucp 只作用于**已配对**的未读点）。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk
