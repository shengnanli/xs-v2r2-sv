MODULE = VSetRiWi

RTL_DIR = ../../../rtl
# backend_common_pkg.sv 里的 vset_pkg 由 VSetRiWi/VSetRvfWvf 共用（每个子系统至多一个
# 公共包文件，见 CONVENTIONS.md）。必须排在使用者之前：package 要先于引用它的模块可见。
RTL_SRCS = $(RTL_DIR)/backend/backend_common_pkg.sv $(RTL_DIR)/backend/VSetRiWi.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
# VsetModule 是 golden 侧的 vset 运算叶子，随 golden 顶层一起 elaborate（无黑盒）。
GOLDEN_SRCS = $(GOLDEN_RTL)/VSetRiWi.sv $(GOLDEN_RTL)/VsetModule.sv
# 同 Alu：不设 RTL_GOLDEN_DEPS。该变量会进 FM_IMPL_SRCS（ut_common.mk:137），只在
# impl 真的例化 golden 叶子时才该用；可读核把 VsetModule 的组合逻辑重写进了
# vset_pkg 的纯函数，没有任何例化，放进 impl 侧只会污染 receipt 的 impl_closure。

FM_VARIANTS = VSetRiWi
FM_REF_DEPS_VSetRiWi = VsetModule.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
