# 自动生成:scripts/gen_openllc.py —— 勿手改
MODULE = OpenLLC

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/decls/glue/inst/outassign svh)。
RTL_SRCS = $(RTL_DIR)/l2/openllc_pkg.sv \
           $(RTL_DIR)/l2/OpenLLC.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 双例化:顶 OpenLLC.sv + 8 子模块类型的全部叶子。
# 叶子传递闭包列在 golden_filelist.f(每文件一次),由 -f 显式编译——
# 不用 -y:golden 叶子多为自包含 pkg+module,-y 会重复解析触发 Package previously declared。
GOLDEN_SRCS = $(GOLDEN_RTL)/OpenLLC.sv

# 子模块顶(FM ref 依赖列表用)。
SUB_DEPS = $(GOLDEN_RTL)/MMIODiverger.sv $(GOLDEN_RTL)/MMIOMerger.sv $(GOLDEN_RTL)/RNLinkMonitor.sv $(GOLDEN_RTL)/RNXbar.sv $(GOLDEN_RTL)/SNLinkMonitor.sv $(GOLDEN_RTL)/SNXbar.sv $(GOLDEN_RTL)/Slice_4.sv $(GOLDEN_RTL)/TopDownMonitor_1.sv

# FM-only 孙子叶子(grandchildren, interface_only 黑盒)—— 消除黑盒引脚方向猜测的
# 196 failing BBPin。golden Slice_4 内部把 RXRSP_4(rxrspUp/rxrspDown)与 RXDAT_4
# (rxdatDown)的部分 output 引脚接到 `/* unused */` 悬空网(io_out_bits_dbID/srcID/
# resp), 另有 MemUnit.io_snRxrsp_bits_dbID 输入由 RXRSP_4 输出驱动。不提供这两个
# 模块定义时 FM 黑盒化, 引脚方向未知 → 把这些 output 位当可验证 BBPin 且 fan-in
# undriven → 196 failing(全 BBPin, 无 DFF)。用 interface_only 只读端口方向、不拉
# 内部逻辑: 悬空 output 变干净黑盒输出(unread, 两侧同源)、memUnit 输入得同一自由
# 变量驱动 → 全部消解。与 TL2CHICoupledL2 的 RequestBuffer interface_only 同法。
# (MemUnit 内部含 FastArbiter, 但 interface_only 不例化内部, 无需其叶子。)
FM_GRANDCHILD_DEPS = RXRSP_4.sv RXDAT_4.sv

# ===================================================================
# codex_0044 inline 分类(消黑盒,从最小高扇出 child 起白盒 elaborate 进 OpenLLC):
# 13 个非 305 逻辑子按扇入/规模分三类(去重后同 Slice L2 装配先例 codex_0036):
#   [INLINE ×11] 两侧 elaborate(白盒受验), 只保留真黑盒边界=
#     纯逻辑叶     : MainPipe_5 / RequestArb_4 / Queue1_CHIRSP
#     带绿/宏子的父: Directory_4(黑盒绿 305 SubDirectory/_1)
#                    DataStorage_4 -> SRAMTemplate_202 -> array_0_1 -> [array_0_1_ext vendor 黑盒]
#                    RequestBuffer_4 -> FastArbiter_49(纯逻辑, 一并 inline)
#                    LCredit2Decoupled_3/4/5(credit-flow FSM 白盒; 黑盒 Queue15_* 队列存储子)
#   [AUX ×4]  MemUnit(8071)/SnoopUnit(2663)/RefillUnit(6061)/ResponseUnit(9139): 过大,
#             各含 FastArbiter_50/52, 走独立 AUX real-body proof(须重写 impl 后非 vacuous);
#             当前作 unresolved black_box(assembly depends, 见 report 交 main 注册 aux)。
#   [RTL 缺口 ×0] impl 是有效装配壳(非空 stub), 无真 RTL 缺口。
# 只保留黑盒边界: (a) 绿 305 SubDirectory/_1 → interface_only; (b) vendor SRAM 宏 array_*_ext;
#   (c) CHI 队列 Queue15_*(内 ram_15x* reg Memory[0:14] 4-bit 下标越界 FMR_ELAB-147)→ interface_only;
#   (d) 4 大 AUX 子 → unresolved black_box。
# 逐子增量 inline 已证(每加 re-verify): 9-child SUCCEEDED passing76912; +LCredit SUCCEEDED
# passing76957; failing=0; 548→0 对称死 DFF 经 vmucp(verify_matched_unread=true)全证等价
# (impl 复用 golden 子 → 双射恒等); 唯 262 Constant reg Not-Compared(非 unread, 不阻门)。
# 见 docs/l2/OpenLLC.md + evidence/。
# ===================================================================
FM_INLINE_DEPS = Directory_4.sv \
                 DataStorage_4.sv SRAMTemplate_202.sv array_0_1.sv \
                 MainPipe_5.sv RequestArb_4.sv Queue1_CHIRSP.sv \
                 RequestBuffer_4.sv FastArbiter_49.sv \
                 LCredit2Decoupled_3.sv LCredit2Decoupled_4.sv LCredit2Decoupled_5.sv
# interface_only 叶子(必须提供 .sv 供 FM 读端口方向, hdlin_interface_only 只读接口
# 不拉内部逻辑 → 不 elaborate 其 SRAM/LFSR/ram 子, 避免 FMR_ELAB-147; 悬空 output 变干净对称黑盒)。
#   SubDirectory/_1 已 SIGNOFF_PASS 绿 305 子(assembly depends);
#   Queue15_CHIRSP/CHIDAT/CHIREQ = CHI 队列存储子(inline LCredit 后其黑盒队列子)。
FM_IFACE_DEPS = SubDirectory.sv SubDirectory_1.sv \
                Queue15_CHIRSP.sv Queue15_CHIDAT.sv Queue15_CHIREQ.sv
FM_INTERFACE_ONLY = RXRSP_4 RXDAT_4 SubDirectory SubDirectory_1 Queue15_CHIRSP Queue15_CHIDAT Queue15_CHIREQ

# vmucp: 548→0 对称内部死 DFF(inline 子里读端止于绿子/vendor 黑盒输入的寄存器)双射匹配
# 实证等价(非 waiver, 要求 FM 证更多)。仅精确白名单; OpenLLC 须由 main 加入 fm_eq.tcl +
# run_signoff_target.sh 白名单 + declarations verify_matched_unread=true(见 report 交 main)。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
# merge_duplicated_registers=false(同 Slice 先例): 分 bank 扇出复制寄存器按名对称保留,
# 避免 ref/impl 常数折叠深度不对称造成绿子黑盒输入假失配。
FM_MERGE_DUP = false

# FM:impl 侧(wrapper->可读核)与 ref 侧在相同层次 elaborate 上述 inline 子链 / 黑盒绿子+队列。
WRAPPER_SRCS = $(RTL_DIR)/l2/OpenLLC_wrapper.sv $(SUB_DEPS) \
               $(addprefix $(GOLDEN_RTL)/,$(FM_GRANDCHILD_DEPS)) \
               $(addprefix $(GOLDEN_RTL)/,$(FM_INLINE_DEPS)) \
               $(addprefix $(GOLDEN_RTL)/,$(FM_IFACE_DEPS))
FM_VARIANTS = OpenLLC
FM_REF_DEPS_OpenLLC = MMIODiverger.sv MMIOMerger.sv RNLinkMonitor.sv RNXbar.sv SNLinkMonitor.sv SNXbar.sv Slice_4.sv TopDownMonitor_1.sv $(FM_GRANDCHILD_DEPS) $(FM_INLINE_DEPS) $(FM_IFACE_DEPS)

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉并关随机化,处理 flush-X。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/l2
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
# golden 叶子全集(传递闭包),-f 显式列出,每文件一次。
VCS += -f golden_filelist.f
VCS += +libext+.sv+.v
VCS += -assert disable
