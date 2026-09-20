# TLBuffer_8 UT/FM 入口（xs_TLBuffer_ad_core 家族变体）
# 重写件只有两个：共享参数化核 + 本变体薄文件。
# Queue2_*/ram_2x* 是 golden 叶子，放 RTL_GOLDEN_DEPS：UT 两侧共用同一份定义
# （不改名、不复制），FM 时与 ref 侧同源 elaborate。
# 自动生成：scripts/gen_tlbuffer_ad_family.py —— 勿手改
MODULE = TLBuffer_8

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/xs_TLBuffer_ad_core.sv \
           $(RTL_DIR)/memblock/TLBuffer_8.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/Queue2_TLBundleA_14.sv \
                  $(GOLDEN_RTL)/Queue2_TLBundleD_15.sv \
                  $(GOLDEN_RTL)/ram_2x136.sv \
                  $(GOLDEN_RTL)/ram_2x79.sv

FM_REF_DEPS_TLBuffer_8 = Queue2_TLBundleA_14.sv Queue2_TLBundleD_15.sv ram_2x136.sv ram_2x79.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer_8.sv
FM_VARIANTS = TLBuffer_8

include ../../../scripts/ut_common.mk

# +vcs+initreg+random 只在**编译期**打开机制，取值在运行期由 +vcs+initreg+<0|1|random>
# 选（ut_common.mk 的 SIM_ARGS）。只在运行期给、编译期不给，VCS 报 Warning-[VICIU]
# 然后当没看见 —— 那一轮等于没测。本家族 2026-09-20 实测过这条：
#   编译期不给、只在运行期给 +vcs+initreg+0 -> Warning-[VICIU] VCS initreg not enabled
#
# ★SIM_ARGS 必须显式钉 +0，不能不给★：编译期开了 random、运行期不选值时，VCS 取
# random（实测 TLBuffer_6 default `make run` 命令行里没有任何 initreg plusarg，
# 结果与 +vcs+initreg+random 逐个相同：errors=47），于是"默认那一轮"会悄悄换语义。
#
# ★诚实交代 +random 那轮今天是红的（2026-09-20 实测，3 seed x 5 变体）★
#   +vcs+initreg+0       15/15 绿
#   +vcs+initreg+1       绿（TLBuffer_6 seed 7/42 实跑）
#   +vcs+initreg+random  seed 1 绿；seed 7/42 全红（errors 10~47）
# 判别实验说明这不是重写件对非零上电初值的行为差异：★+1 两侧上电内容**相同**就绿，
# 只有 random 才红★ —— 差别在"两侧初值一不一样"，不在"初值是不是 0"。
# 实测到的两条事实（不是推断）：
#   · 失配全部落在 reset 撤销后头 1~5 个比较拍（t=86000~136000 ps，共跑 20 万拍），
#     此后到底再无一例；失配信号全是被无复位状态喂的那些（Queue2 的载荷）。
#   · impl 侧 256 位 data 逐位等于 golden 侧的低 128 位再接另外 128 位
#     （g=...adb|5f10b681...04de 对 i=5f10b681...04de|baaebd4f...）。
# 读法（这一句是推断，不是测量）：VCS 的 initreg 像是从一条随机流里按序取值填各个
# 寄存器，于是 tb 里 golden 与 _xs 两个实例拿到同一条流的**不同片段**；而 Queue2 的
# ram_2x<N> 是 golden 行为模型、没有复位，tb 又在 reset 一撤就开始比，
# 比到的就是**还没被写过的条目**。
# 这是 tb 缺暖机窗口，不是 DUT 差异；FM 侧不受影响（本轮 5 个变体 failing/unmatched 全 0）。
# ★所以别把"配了 initreg"读成"两轮都绿"★ —— 补暖机是另一件事，没做。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
