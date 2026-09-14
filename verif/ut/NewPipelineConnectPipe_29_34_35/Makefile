# NewPipelineConnectPipe_29 / _34 / _35 UT —— G1 新增/重编号的三个变体，一个 tb。
#
# 这三个变体在 G1 golden 里存在、在 rtl/ 里此前**完全没有实现**：家族 owner 的
# verif/ut/NewPipelineConnectPipe/Makefile 头上明写"G1 新增的 _29/_34/_35 在 rtl/ 里
# 还没有实现，不在本 UT 范围"，name-collision owner 只做了 _27/_33 两个改名链目标。
#
# 为什么另开目录而不是并进家族 tb：主树同时有多位 owner 在动，改别人的 tb/Makefile
# 会撞车；三者又恰好是同一批"G1 新增或重编号"的变体，合成一个 tb 一次编译即可。
#
# 三者的 G0 对应（判据是例化坑位集合相等，见 scripts/check_name_collisions.py，
# 不是名字相似度）：
#   G1 _29 (152 端口) <- G0 _27 (82)   VS/VLMergeBufferImp.VMergebufferPipelineConnect0/1
#   G1 _34 ( 99 端口) <- G0 _32 (71)   MemBlock.inner_otherStoutConnect
#   G1 _35 (356 端口) <- G0 _33 (96)   MemBlock.inner_V{s,l}SplitConnect{Stu,Ldu}[_1]
MODULE = NewPipelineConnectPipe_29_34_35

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/PipelineConnect.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_29.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_34.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_35.sv
TB_SRCS  = tb.sv

# golden 三个变体都是自包含的（0 子模块），不需要任何 FM_REF_DEPS_*。
GOLDEN_SRCS = $(GOLDEN_RTL)/NewPipelineConnectPipe_29.sv \
              $(GOLDEN_RTL)/NewPipelineConnectPipe_34.sv \
              $(GOLDEN_RTL)/NewPipelineConnectPipe_35.sv

FM_VARIANTS = NewPipelineConnectPipe_29 NewPipelineConnectPipe_34 NewPipelineConnectPipe_35

# fm_map/<变体>.txt —— FM payload 字段映射（ut_common.mk 的 fm-% 自动识别，传成
# FM_FIELD_MAP；由 scripts/gen_npc_missing3.py 的 gen_field_map 生成，勿手改）。
# 作用：golden 每字段一个寄存器 data_<f>，手写侧是共享核里一个扁平 data_reg；
# 当 payload 里恰好有字段字面叫 data（本族 19 个变体里只有 _29/_34），Formality
# 的名字匹配会把 data_data_reg[b] 按位配到 u_core/data_reg[b]，而 packed struct
# 的 data 后面还有 vdIdx/vdIdxInField(_29, 错 6 位) / debug_isMMIO(_34, 错 1 位)，
# 于是整体错位、每位都判不等价（取消 failing 上限后 _29 262 点 / _34 129 点；
# 首跑报告里的 20 是 verification_failing_point_limit 的默认截断值）。
# 这里把整个 payload 的逐位双射钉死，钉后三个变体均 0 unmatched / 0 failing。
# 详细论证见 scripts/gen_npc_missing3.py 中 gen_field_map 上方注释。

# 端口表逐行照 golden 生成（含顺序），所以把 ORDER 从 warn 升成硬闸。
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# ---------------------------------------------------------------------------
# 必失败负测（codex 0145）：neg_width.sv 是 NewPipelineConnectPipe_35 的逐字副本，
# 只把 io_in_bits_uop_vpu_vmask 从 128 位改窄到 64 位 ——"逻辑全对、位宽停在旧基线"
# 这一类真实故障的最小复现。薄文件里的 elaborate 期不变式必须在 time 0 $fatal。
# **跑不失败就说明闸是摆设**，所以这里反过来判：仿真跑到底 = NEG FAILED。
# ---------------------------------------------------------------------------
.PHONY: neg
neg:
	@rm -rf neg_build && mkdir -p neg_build
	@cd neg_build && $(VCS) ../$(RTL_DIR)/common/PipelineConnect.sv ../neg_width.sv \
	    -top neg_tb -o neg_simv > neg_compile.log 2>&1 \
	  || { echo "=== NEG: 编译阶段就失败了（也算拦下，但请看 neg_build/neg_compile.log）==="; }
	@cd neg_build && ./neg_simv -l neg_sim.log > /dev/null 2>&1; true
	@if grep -q "入口端口位宽之和" neg_build/neg_sim.log 2>/dev/null; then \
	  echo "=== NEG PASSED: 改窄的位宽被薄文件的 elaborate 期不变式拦下 ==="; \
	  grep -m1 "入口端口位宽之和" neg_build/neg_sim.log; \
	elif grep -q "NEG_ESCAPED" neg_build/neg_sim.log 2>/dev/null; then \
	  echo "=== NEG FAILED: 位宽改窄了却没被拦下，不变式是摆设 ==="; exit 1; \
	else \
	  echo "=== NEG FAILED: 既没触发不变式也没跑到底，看 neg_build/ ==="; exit 1; \
	fi
