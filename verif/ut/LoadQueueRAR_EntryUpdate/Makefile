MODULE = LoadQueueRAR_EntryUpdate

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 块 2 canary：standalone paddr CAM（golden 里就是独立子模块 LqPAddrModule）。
# 这是 RAR entry 状态更新块里的 CAM 存储 + 相等匹配部分（allocated/robIdx/released
# 门控在顶层块外, 不在本 CAM 内）。可读重写核, 端口逐一对齐 golden。
RTL_SRCS = $(RTL_DIR)/memblock/loadqueuerar_pkg.sv \
           $(RTL_DIR)/memblock/LqPAddrModule.sv

# UT 双例化：golden LqPAddrModule vs 重命名的 impl LqPAddrModule_xs（同 pkg）。
TB_SRCS = LqPAddrModule_xs.sv tb.sv

# golden LqPAddrModule 依赖 3 个 DelayN 子模块（均 delay=0 直通 assign out=in）。
GOLDEN_SRCS = $(GOLDEN_RTL)/LqPAddrModule.sv \
              $(GOLDEN_RTL)/DelayN_226.sv \
              $(GOLDEN_RTL)/DelayNWithValid_4.sv \
              $(GOLDEN_RTL)/DelayNWithValid_7.sv

# FM：golden LqPAddrModule vs 手写同名 LqPAddrModule（可读重写）。
# golden 侧依赖 3 个 DelayN 直通子模块——**两侧都 elaborate**（确定性逻辑非 vendor 宏,
# 不黑盒）。impl 侧把它们展开进核里, FM 按名/签名自动配对 data_N ↔ data[N]。
WRAPPER_SRCS =
FM_VARIANTS = LqPAddrModule
FM_REF_DEPS_LqPAddrModule = DelayN_226.sv DelayNWithValid_4.sv DelayNWithValid_7.sv

# 关闭合并同值重复寄存器 pass（与父目标 LoadQueueRAR 一致；本块 72×16=1152 存储位,
# auto_match_flattened_arrays 处理展平阵列 data_N ↔ data[N]）。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 含 XSError/XSPerf 行为断言（非综合）；UT 关掉随机初始化与 $fatal。
VCS += +define+SYNTHESIS
