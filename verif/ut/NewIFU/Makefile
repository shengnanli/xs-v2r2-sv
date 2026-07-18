MODULE = NewIFU

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 + 子模块黑盒适配器 + 共享译码包
RTL_SRCS = $(RTL_DIR)/frontend/predecode_pkg.sv \
           $(RTL_DIR)/frontend/NewIFU.sv \
           $(RTL_DIR)/frontend/NewIFU_subs.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/NewIFU_wrapper.sv \
               $(GOLDEN_RTL)/PreDecode.sv $(GOLDEN_RTL)/RVCExpander.sv \
               $(GOLDEN_RTL)/F3Predecoder.sv $(GOLDEN_RTL)/PredChecker.sv \
               $(GOLDEN_RTL)/FrontendTrigger.sv

# golden NewIFU 及其例化的子模块(UT 双例化 / FM 比对 golden 侧需要)
GOLDEN_SRCS = $(GOLDEN_RTL)/NewIFU.sv \
              $(GOLDEN_RTL)/PreDecode.sv \
              $(GOLDEN_RTL)/RVCExpander.sv \
              $(GOLDEN_RTL)/F3Predecoder.sv \
              $(GOLDEN_RTL)/PredChecker.sv \
              $(GOLDEN_RTL)/FrontendTrigger.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = NewIFU
# golden 顶层有多组「同 D 重复寄存器」(REG/wb_enable_REG, perf 1/3·5/6, mmioFlushWb/mmio_redirect),
# impl 已 1:1 建副本并在 fm_pins_pre.tcl 钉死; merge_dup 会把两侧副本各自合并、与显式钉点冲突
# (钉到被合并掉的点 → wb_enable 锥全域失配), 关掉。
FM_MERGE_DUP = false
# FM ref 侧依赖：golden NewIFU 例化的子模块
# 两侧都把子模块当黑盒(impl 的 xs_newifu_* 适配层内例化同名 PreDecode/RVCExpander/...,
# ref 直接例化;均不读其源 → hdlin_unresolved_modules=black_box 统一黑盒,边界对齐)
# 子模块只取接口(方向已知的黑盒): golden 里 F3Predecoder 输出直连 PredChecker 输入,
# 未解析黑盒方向未知 → ref 侧被判多驱动 net 黑盒化(自由变量), 与 impl(经 wrapper 端口,
# 方向已知)不对称, pd/brType/isRet 全 fail。两侧都给 golden 源文件 + interface_only。
FM_REF_DEPS_NewIFU = PreDecode.sv RVCExpander.sv F3Predecoder.sv PredChecker.sv FrontendTrigger.sv
FM_INTERFACE_ONLY = PreDecode RVCExpander F3Predecoder PredChecker FrontendTrigger

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 的随机初始化/断言；UT 随机激励下定义 SYNTHESIS 关掉。
VCS += +define+SYNTHESIS
