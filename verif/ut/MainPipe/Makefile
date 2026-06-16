MODULE = MainPipe

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 其类型包（核内例化 golden 同名 AMOALU / Arbiter4_MainPipeReq 黑盒）
RTL_SRCS = $(RTL_DIR)/memblock/mainpipe_pkg.sv \
           $(RTL_DIR)/memblock/MainPipe.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 + 叶子子模块 AMOALU / Arbiter4_MainPipeReq
# （UT 双例化两侧共用同一份黑盒，比对只检验顶层流水/命中/一致性/写回是否等价）。
GOLDEN_SRCS = $(GOLDEN_RTL)/MainPipe.sv \
              $(GOLDEN_RTL)/AMOALU.sv \
              $(GOLDEN_RTL)/Arbiter4_MainPipeReq.sv

# FM：golden 顶层 MainPipe（含两个黑盒）vs 手写同名 wrapper（→ 可读核 + 黑盒）。
# 黑盒放 WRAPPER_SRCS 让 impl 侧也读入，使子模块在两侧配对。
WRAPPER_SRCS = $(RTL_DIR)/memblock/MainPipe_wrapper.sv \
               $(GOLDEN_RTL)/AMOALU.sv $(GOLDEN_RTL)/Arbiter4_MainPipeReq.sv
FM_VARIANTS = MainPipe
FM_REF_DEPS_MainPipe = AMOALU.sv Arbiter4_MainPipeReq.sv

# 关闭 FM “合并同值重复寄存器”pass：本核刻意保留 golden 的多份扇出复制
# （status_dup×24、data_write_dup×8、perf 打拍副本等），并与 golden 同名，
# 靠按名配对即可干净比对；若开启合并，反而会把跨 wrapper/u_core 层次的同值寄存器
# 误判为不对称而失配（与 LoadUnit/StoreUnit 先例一致）。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf 行为断言（非综合）；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
