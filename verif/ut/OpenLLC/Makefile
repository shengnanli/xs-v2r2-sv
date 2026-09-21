# ============================================================================
# ★范围标注（2026-09-21 coordinator 裁定）★
#   OpenLLC 例化在 XSTop（grep -n 'OpenLLC' $(GOLDEN_RTL)/XSTop.sv -> XSTop.sv:2210），
#   不在 XSTile 闭包内 —— 属**核外**，本轮不重写、不签核。
#   下面这些 FM 配置改动只是把旧登记 UNRUNNABLE_RESOURCE_LIMIT_CURRENT_HOST 的
#   **错误病因**纠正过来备查（真因=闭包里混进厂商 SRAM 行为模型，不是目标太大）。
#   ★改后的这套配置没有跑完过，不得据此声称任何 PASS★。见 docs/openllc_scope_note.md。
# ============================================================================
# 自动生成：scripts/gen_zj_ut.py 的配套 Makefile（零判断批 G0->G1 迁移）
MODULE = OpenLLC

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/l2/OpenLLC.sv
TB_SRCS = tb.sv

# golden 双例化：golden 顶 + 其全部子模块传递闭包（两侧共用同一份子模块定义，
# 比对的是本目标自己的逻辑；子模块本身由各自的目标去证）。
GOLDEN_SRCS = $(GOLDEN_RTL)/OpenLLC.sv \
              $(GOLDEN_RTL)/DataStorage_4.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_1.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_2.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_5.sv \
              $(GOLDEN_RTL)/Directory_4.sv \
              $(GOLDEN_RTL)/FastArbiter_26.sv \
              $(GOLDEN_RTL)/FastArbiter_29.sv \
              $(GOLDEN_RTL)/FastArbiter_30.sv \
              $(GOLDEN_RTL)/FastArbiter_35.sv \
              $(GOLDEN_RTL)/FastArbiter_43.sv \
              $(GOLDEN_RTL)/FastArbiter_45.sv \
              $(GOLDEN_RTL)/FastArbiter_46.sv \
              $(GOLDEN_RTL)/FastArbiter_48.sv \
              $(GOLDEN_RTL)/FastArbiter_49.sv \
              $(GOLDEN_RTL)/FastArbiter_51.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_3.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_4.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_5.sv \
              $(GOLDEN_RTL)/MMIODiverger.sv \
              $(GOLDEN_RTL)/MMIOMerger.sv \
              $(GOLDEN_RTL)/MainPipe_5.sv \
              $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR_3.sv \
              $(GOLDEN_RTL)/MemUnit.sv \
              $(GOLDEN_RTL)/Queue15_CHIDAT.sv \
              $(GOLDEN_RTL)/Queue15_CHIREQ.sv \
              $(GOLDEN_RTL)/Queue15_CHIRSP.sv \
              $(GOLDEN_RTL)/Queue1_CHIRSP_1.sv \
              $(GOLDEN_RTL)/RNLinkMonitor.sv \
              $(GOLDEN_RTL)/RNXbar.sv \
              $(GOLDEN_RTL)/RXDAT_4.sv \
              $(GOLDEN_RTL)/RXREQ.sv \
              $(GOLDEN_RTL)/RXRSP_4.sv \
              $(GOLDEN_RTL)/RefillUnit.sv \
              $(GOLDEN_RTL)/RequestArb_4.sv \
              $(GOLDEN_RTL)/RequestBuffer_4.sv \
              $(GOLDEN_RTL)/ResponseUnit.sv \
              $(GOLDEN_RTL)/SNLinkMonitor.sv \
              $(GOLDEN_RTL)/SNXbar.sv \
              $(GOLDEN_RTL)/SRAMTemplate_192.sv \
              $(GOLDEN_RTL)/SRAMTemplate_193.sv \
              $(GOLDEN_RTL)/SRAMTemplate_194.sv \
              $(GOLDEN_RTL)/SRAMTemplate_195.sv \
              $(GOLDEN_RTL)/SRAMTemplate_196.sv \
              $(GOLDEN_RTL)/SRAMTemplate_197.sv \
              $(GOLDEN_RTL)/Slice_4.sv \
              $(GOLDEN_RTL)/SnoopUnit.sv \
              $(GOLDEN_RTL)/SubDirectory.sv \
              $(GOLDEN_RTL)/SubDirectory_1.sv \
              $(GOLDEN_RTL)/TXDAT_4.sv \
              $(GOLDEN_RTL)/TXREQ_4.sv \
              $(GOLDEN_RTL)/TXRSP_4.sv \
              $(GOLDEN_RTL)/TXSNP.sv \
              $(GOLDEN_RTL)/TopDownMonitor_1.sv \
              $(GOLDEN_RTL)/array_0_0.sv \
              $(GOLDEN_RTL)/array_0_0_ext.v \
              $(GOLDEN_RTL)/array_0_1.sv \
              $(GOLDEN_RTL)/array_0_1_ext.v \
              $(GOLDEN_RTL)/array_19.sv \
              $(GOLDEN_RTL)/array_19_ext.v \
              $(GOLDEN_RTL)/array_20.sv \
              $(GOLDEN_RTL)/array_20_ext.v \
              $(GOLDEN_RTL)/array_21.sv \
              $(GOLDEN_RTL)/array_21_ext.v \
              $(GOLDEN_RTL)/array_22.sv \
              $(GOLDEN_RTL)/array_22_ext.v \
              $(GOLDEN_RTL)/ram_15x162.sv \
              $(GOLDEN_RTL)/ram_15x422.sv \
              $(GOLDEN_RTL)/ram_15x73.sv

FM_VARIANTS = OpenLLC

# ★assembly★：唯一的黑盒边界是 9 个存储宏叶子（58 个实例，ref/impl 各 29，见
# verif/allow/OpenLLC.json 逐条声明）。没有一个 green_child —— 本目标不挂条件绿依赖。
FM_MODE = assembly

# ★merge_duplicated_registers = false★（2026-09-21 实测定的，不是抄来的默认值）
#
# 先用默认 true 跑过一遍（evidence 见 fastlane_ledger 同名条目），结果是
#   Verification FAILED: 167323 passing / 20 failing / 7 unverified
#   6(0) Unmatched reference(implementation) compare points
# 失败点全部集中在 io_rn_0_rx_snp_flit[27..46]（RN 侧 snoop flit 输出），
# 而 6 个 ref-only 未配对寄存器是
#   r:/WORK/OpenLLC/rnXbar/snpReqs_{0,1,2,3}_bits_opcode_reg[4]
#   r:/WORK/OpenLLC/rnLinkMonitor/Decoupled2LCredit_txsnp/out_flit_r_reg[27] 与 [54]
# —— 正是"四个 bank 的同值复制寄存器"那一类。
#
# 这不是重写有 bug：把两侧 OpenLLC 顶层逐项机械对比过，
#   11 个实例、每个实例的全部端口绑定（mmioDiverger 293 / rnXbar 349 / slices_N 189 …）
#   全部逐字相同；wire/logic 声明 0 处宽度差、0 处多余/缺失；3 条 assign 逐字相同。
# 复跑这条机械对比（两边都只读，退出码 0 = 同构）：
#   python3 scripts/openllc_topology_diff.py
# 差异只可能来自 FM 自己：impl 侧比 ref 多一层 u_core 层次，
# merge_duplicated_registers 按名合并复制寄存器时两侧合并深度不对称，
# 被合掉的那几个在 ref 侧成了未配对点，下游 snp flit 位就跟着判失配。
# 上一轮 G0 的已签核配置写过同一条结论（"分 bank 扇出复制寄存器按名对称保留,
# 避免 ref/impl 常数折叠深度不对称造成假失配"），本轮是**独立重现**它。
#
# 关掉合并是**加强**不是放松：不合并 = 比较点更多、每个复制副本各自被证。
FM_MERGE_DUP = false


# ---------------------------------------------------------------------------
# FM elaboration 闭包（两侧同一张清单）与黑盒边界
#
# ★本段推翻了此前 UNRUNNABLE_RESOURCE_LIMIT_CURRENT_HOST 的登记★（2026-09-21）
#
# 病史：本 Makefile 由 scripts/gen_zj_ut.py 的"零判断批"生成，闭包清单是把 golden
# OpenLLC 的传递闭包**整棵树**平铺出来，其中包含厂商 SRAM 行为模型 *_ext.v。
# 一次实跑（evidence/3b72cb1a8513/OpenLLC/fm.log）在 elaborate 阶段被人工 SIGTERM
# 掐掉，随后登记为"本机不可运行的 XL 任务"。
#
# 真因不是"OpenLLC 这个目标太大"，是**闭包里混进了厂商存储宏的行为模型**：
#   $ sed -n '/reg \[511:0\] ram/p' $(GOLDEN_RTL)/array_0_1_ext.v
#     reg [511:0] ram [65535:0];
#   65536 × 512 bit = 3355 万个 flop，一个实例。LLC 4 个 slice 各一份、ref/impl
#   两侧再各一份 => 2.6 亿比较点。fm_shell 在这上面吃内存是必然，与本层装配逻辑无关。
#
# 厂商 SRAM 宏本来就属于"无条件绿黑盒"那一类（见 CONVENTIONS 黑盒边界审核判据，
# 与 ICacheDataArray/SRAMTemplate 家族同处置）。把这 9 个存储叶子从**两侧**闭包里
# 拿掉、让它们成为对称的 unresolved 黑盒之后，本目标是 NORMAL 量级而非 XL。
#
# 对照实证（上一轮 G0 同目标，配置更弱——连 Slice 内 4 个大子模块都是黑盒）：
#   $ tail -12 /home/eda/xs-env/xs-v2r2-sv/verif/ut/OpenLLC/fm_work/OpenLLC/fm.log
#     Verification SUCCEEDED / 100949 Passing / 0 Failing
#     Maximum memory usage for this session: 935 MB   Elapsed time: 25 seconds
# 本轮的闭包**比 G0 那次强**：G0 把 MemUnit/SnoopUnit/RefillUnit/ResponseUnit、
# RNXbar/SNXbar 的 FastArbiter、Decoupled2LCredit 全留成黑盒，这里全部两侧 elaborate，
# 只剩存储宏一类边界。
#
# 黑盒边界（两侧对称，逐个写进 verif/allow/OpenLLC.json）：
#   array_0_0_ext / array_0_1_ext / array_19_ext / array_20_ext / array_21_ext /
#   array_22_ext          —— 厂商 SRAM 宏（.v 行为模型）
#   ram_15x162 / ram_15x422 / ram_15x73 —— CHI 队列存储体行为模型；顺带避开 G0 记过的
#                          FMR_ELAB-147（Memory[0:14] 用 4 bit 下标，第 16 个地址越界）
# 其余 60 个依赖两侧同源 elaborate，不黑盒。
#
# 复跑：  make -C verif/ut/OpenLLC fm-OpenLLC
# 静态复核：python3 scripts/check_closure_symmetry.py --only OpenLLC
# ---------------------------------------------------------------------------
# 两侧共用同一张清单 —— 抄第二份就会再漂一次（D68 的病因正是两张清单各写各的）。
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_OpenLLC))

# 厂商/行为存储宏叶子：**不提供给 FM**，两侧同为 unresolved 黑盒。
# （GOLDEN_SRCS 仍然给 VCS 提供它们——UT 要真存储才能跑激励。）
FM_MEM_MACRO_LEAVES = array_0_0_ext.v array_0_1_ext.v array_19_ext.v array_20_ext.v \
                      array_21_ext.v array_22_ext.v \
                      ram_15x162.sv ram_15x422.sv ram_15x73.sv

FM_REF_DEPS_OpenLLC = DataStorage_4.sv Decoupled2LCredit.sv Decoupled2LCredit_1.sv Decoupled2LCredit_2.sv Decoupled2LCredit_5.sv Directory_4.sv FastArbiter_26.sv FastArbiter_29.sv FastArbiter_30.sv FastArbiter_35.sv FastArbiter_43.sv FastArbiter_45.sv FastArbiter_46.sv FastArbiter_48.sv FastArbiter_49.sv FastArbiter_51.sv LCredit2Decoupled_3.sv LCredit2Decoupled_4.sv LCredit2Decoupled_5.sv MMIODiverger.sv MMIOMerger.sv MainPipe_5.sv MaxPeriodFibonacciLFSR_3.sv MemUnit.sv Queue15_CHIDAT.sv Queue15_CHIREQ.sv Queue15_CHIRSP.sv Queue1_CHIRSP_1.sv RNLinkMonitor.sv RNXbar.sv RXDAT_4.sv RXREQ.sv RXRSP_4.sv RefillUnit.sv RequestArb_4.sv RequestBuffer_4.sv ResponseUnit.sv SNLinkMonitor.sv SNXbar.sv SRAMTemplate_192.sv SRAMTemplate_193.sv SRAMTemplate_194.sv SRAMTemplate_195.sv SRAMTemplate_196.sv SRAMTemplate_197.sv Slice_4.sv SnoopUnit.sv SubDirectory.sv SubDirectory_1.sv TXDAT_4.sv TXREQ_4.sv TXRSP_4.sv TXSNP.sv TopDownMonitor_1.sv array_0_0.sv array_0_1.sv array_19.sv array_20.sv array_21.sv array_22.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
