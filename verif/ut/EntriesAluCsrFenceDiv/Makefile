# EntriesAluCsrFenceDiv UT/FM 入口（Entries* 家族 canary）
# 重写件只有两个：家族共享参数化核 + 本变体薄文件。
# golden 的 EnqEntry/OthersEntry/EnqPolicy 都不是独立签核目标，故本重写把它们
# 一起扁平化，不放 RTL_GOLDEN_DEPS、不做黑盒；FM 侧 ref 需要它们做依赖闭包。
# 自动生成：verif/ut/EntriesAluCsrFenceDiv/gen.py（共享库 verif/ut/Entries_common/entries_gen.py）
# 勿手改
MODULE = EntriesAluCsrFenceDiv

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/xs_iq_entries_core.sv \
           $(RTL_DIR)/backend/EntriesAluCsrFenceDiv.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/EntriesAluCsrFenceDiv.sv \
              $(GOLDEN_RTL)/EnqEntry_6.sv \
              $(GOLDEN_RTL)/OthersEntry_66.sv \
              $(GOLDEN_RTL)/OthersEntry_72.sv \
              $(GOLDEN_RTL)/EnqPolicy.sv \
              $(GOLDEN_RTL)/UIntCompressor_27_000011100000000000001010101.sv

FM_VARIANTS = EntriesAluCsrFenceDiv
FM_REF_DEPS_EntriesAluCsrFenceDiv = EnqEntry_6.sv OthersEntry_66.sv OthersEntry_72.sv EnqPolicy.sv UIntCompressor_27_000011100000000000001010101.sv

# ---------------------------------------------------------------------------
# FM 证明配置 —— 两项都是**加强**，不是放宽
# ---------------------------------------------------------------------------
# FM_MERGE_DUP=false：与 MulUnit 同型的工具建模不对称。golden 把条目负载展平成
#   上百个逐字段寄存器，其中本变体用不到的字段整组是常数（Entries 顶层根本没有
#   对应端口 → 入口恒 0）；merge_duplicated_registers=true 时 FM 在 golden 侧把
#   这些同值寄存器合并掉，而可读核把同一份负载存在一根向量里、按位不合并，
#   于是两侧点数对不上。置 false 后两侧都逐个保留。
#   这是要求 FM 逐个而不是合并后比 —— 更严，不跳点、不黑盒、不约束 ref。
# FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true：配合 fm_pins_pre.tcl 的逐位钉点，
#   让 FM **真去比**那些「本变体里没有输出锥」的负载位，而不是记 Not-Compared。
#   白名单在 scripts/fm_eq.tcl（依据写在那一行紧邻的注释里），两处须同时生效。
# 本变体的 FM 点数尚未实测。
FM_MERGE_DUP = false
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# golden 带 XSError/XSPerf 等非综合断言，随机激励会踩到 $fatal；两侧统一关掉。
VCS += +define+SYNTHESIS

# 变异靶子：往可读核里注入若干个**真实形态**的 bug，要求本 UT 每一个都抓得住。
# errors=0 只有在 UT 有判别力的前提下才算证据，所以这一步和 make run 同等重要。
.PHONY: mutants
mutants:
	python3 ../Entries_common/mutants.py $(MODULE) $(MUTANT_ARGS)
