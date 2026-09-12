# ExeUnit_int0 学习台 —— golden 与可读重写双例化对照波形
#
# 这是**学习用**目录（verif/study/），不是验收目录（verif/ut/）：
#   · tb 里同时例化 golden `ExeUnit` 和可读重写 `ExeUnit_xs`，同激励逐拍比对；
#   · 但它**不产生 signoff receipt、不参与 FM 签核台账**（ExeUnit 本身还没被
#     正式重写进 rtl/；本目录的 ExeUnit_study.sv 是学习材料，见其文件头）；
#   · 目的是产出可在 Verdi 里逐拍观察、左右对照的波形。
#
#   make          编译并跑，产出 novas.fsdb + sim.log（末尾有比对结论）
#   make verdi    打开 Verdi
#   make sig      生成分组的建议观察信号清单 signals.txt
#   make clean    清干净（本目录所有 VCS/Verdi 产物都已在 .gitignore 里）
#
# 两侧的构成：
#   golden 侧  : G1-canonical/golden-rtl 的 29 个模块闭包，一个字没动。
#   可读侧     : 本目录 ExeUnit_study.sv / Dispatcher_study.sv （手写）
#              + rtl/backend/{Alu,MulUnit,Bku}.sv 这三份**已签核的可读重写**，
#                经 scripts/derive_ut_impl.py 机械改名为 *_xs 后编进来
#                （改名只为躲开 golden 同名模块，逻辑一字未动）。
#   两侧共用   : ClockGate（工艺库单元）、以及 Bku/MulUnit 内部的运算阵列叶子
#                （ArrayMulDataModule / CountModule / ... 另有 owner，不在本例范围）。

XSSV_HOME    ?= $(abspath ../../..)
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN       ?= $(G1_CANONICAL)/golden-rtl
RTL          ?= $(XSSV_HOME)/rtl

# ---------------------------------------------------------------------------
# golden 侧：ExeUnit 的完整子模块闭包（29 个，从 ExeUnit 出发遍历例化图得到）
# ---------------------------------------------------------------------------
CLOSURE = ExeUnit Dispatcher ClockGate \
          Alu AluDataModule AluResSel AddModule SubModule \
          LeftShiftModule RightShiftModule LeftShiftWordModule RightShiftWordModule \
          ShiftResultSelect MiscResultSelect ConditionalZeroModule WordResultSelect \
          MulUnit ArrayMulDataModule C22 C32 C53 CSA3_2 \
          Bku CountModule ClmulModule MiscModule CryptoModule BlockCipherModule HashModule

GOLDEN_SRCS = $(addprefix $(GOLDEN)/,$(addsuffix .sv,$(CLOSURE)))

# ---------------------------------------------------------------------------
# 可读侧
# ---------------------------------------------------------------------------
# (a) 需要机械改名的：rtl/ 里的正式重写（文件内含 golden 同名 wrapper）
RTL_SRCS   = $(RTL)/backend/alu_pkg.sv \
             $(RTL)/backend/Alu.sv \
             $(RTL)/backend/MulUnit.sv \
             $(RTL)/backend/Bku.sv
UT_GEN_DIR = ut_gen
DERIVED    = $(addprefix $(UT_GEN_DIR)/,$(notdir $(RTL_SRCS)))

# (b) 本目录手写的学习材料：wrapper 直接就叫 *_xs，不需要派生，
#     这样你在 Verdi 里读到的就是我写的原文（注释没被改名脚本动过）。
STUDY_SRCS = Dispatcher_study.sv ExeUnit_study.sv

TB_SRCS = tb.sv

export VCS_ARCH_OVERRIDE := linux

# +define+SYNTHESIS  : 关掉 golden 头部的寄存器随机初始化块与 $fwrite 断言
#                      （与 verif/ut 各目标一致）
# +vcs+initreg+random: 打开寄存器上电初值控制；运行时用 +vcs+initreg+0 统一清 0
#                      —— 两侧同样地清，波形干净、比对无 X 噪声
VCS := vcs -full64 -sverilog -timescale=1ns/1ps -kdb -lca -debug_access+all \
       +define+SYNTHESIS +vcs+initreg+random -l compile.log

.PHONY: all run derive verdi sig clean

all: run

derive $(DERIVED): $(RTL_SRCS) $(XSSV_HOME)/scripts/derive_ut_impl.py
	python3 $(XSSV_HOME)/scripts/derive_ut_impl.py --out $(UT_GEN_DIR) $(RTL_SRCS)

simv: $(DERIVED) $(STUDY_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) $(DERIVED) $(STUDY_SRCS) $(GOLDEN_SRCS) $(TB_SRCS) -top tb -o simv

run: simv
	./simv +vcs+initreg+0 -l sim.log
	@echo
	@grep -q "TEST PASSED" sim.log \
	  && echo "=== 双例化比对通过：golden 与可读重写逐拍一致 ===" \
	  || { echo "=== 双例化比对失败，看 sim.log 里的 MISMATCH 行 ==="; exit 1; }
	@echo "波形: $(CURDIR)/novas.fsdb    （make verdi 打开；信号清单 make sig）"

verdi:
	verdi -ssf novas.fsdb -nologo &

# ---------------------------------------------------------------------------
# 建议观察的信号：按五个教学点分组，golden 侧与可读侧**成对**列出。
# Verdi: File > Restore Signal... 选 signals.txt；或直接照着这个清单在
#        Hierarchy 里点。以 '#' 开头的是分组标题（Verdi 会当注释跳过，
#        它的作用是让你照着这份清单一组一组地看）。
# ---------------------------------------------------------------------------
sig:
	@printf '%s\n' \
	  '# ============ 0. 定位：现在跑到哪个阶段了 ============' \
	  'tb.phase' \
	  'tb.phase_name' \
	  'tb.errors' \
	  '' \
	  '# ============ 1. 输入 / 分发（教学点 1：35 位独热比较） ============' \
	  '# 上游发射口（两侧接的是同一组线，只列一次）' \
	  'tb.in_valid' \
	  'tb.in_fuType' \
	  'tb.in_fuOpType' \
	  'tb.in_robIdx_value' \
	  'tb.out_ready' \
	  '# golden：分发器里三个独热比较的结果 + 三路 valid' \
	  'tb.u_gold.in1ToN.acceptVec_0' \
	  'tb.u_gold.in1ToN.acceptVec_1' \
	  'tb.u_gold.in1ToN.acceptVec_2' \
	  'tb.u_gold.in1ToN.io_out_0_valid' \
	  'tb.u_gold.in1ToN.io_out_1_valid' \
	  'tb.u_gold.in1ToN.io_out_2_valid' \
	  'tb.u_gold.io_in_ready' \
	  '# 可读：同样三根线，名字换成人话' \
	  'tb.u_read.u_core.u_disp.u_core.hit_alu' \
	  'tb.u_read.u_core.u_disp.u_core.hit_mul' \
	  'tb.u_read.u_core.u_disp.u_core.hit_bku' \
	  'tb.u_read.u_core.disp_valid' \
	  'tb.u_read.io_in_ready' \
	  '' \
	  '# ============ 2. 两个 valid 的分工（教学点 2，最容易看混） ============' \
	  '# (a) 存活性 —— ExeUnit 维护，flush 只动它' \
	  'tb.u_gold.inPipe_2_1' \
	  'tb.u_gold.inPipe_2_2' \
	  'tb.u_read.u_core.alive_s1' \
	  'tb.u_read.u_core.alive_s2' \
	  '# (b) 占用性 —— FU 自己维护，每拍无条件移位，不认识 flush' \
	  'tb.u_gold.Mul.validVecThisFu_1' \
	  'tb.u_gold.Mul.validVecThisFu_2' \
	  'tb.u_read.u_core.u_mul.u_core.valid_thisfu_1' \
	  'tb.u_read.u_core.u_mul.u_core.valid_thisfu_2' \
	  'tb.u_gold.Bku.validVecThisFu_1' \
	  'tb.u_gold.Bku.validVecThisFu_2' \
	  'tb.u_read.u_core.u_bku.u_core.valid_thisfu_1' \
	  'tb.u_read.u_core.u_bku.u_core.valid_thisfu_2' \
	  '# (c) FU 的 out_valid = (a) AND (b)' \
	  'tb.u_gold._Mul_io_out_valid' \
	  'tb.u_gold._Bku_io_out_valid' \
	  'tb.u_read.u_core.fu_valid' \
	  '' \
	  '# ============ 3. 三种握手形态（教学点 3） ============' \
	  '# Alu：纯组合，in_ready 直接等于 out_ready，无 clock' \
	  'tb.u_gold._Alu_io_in_ready' \
	  'tb.u_gold._Alu_io_out_valid' \
	  'tb.u_read.u_core.disp_ready' \
	  '# Mul/Bku：定长两级，自己的反压链（阶段 7 把 out_ready 拉低才看得到动静）' \
	  'tb.u_gold.Mul.rdyVec_0' \
	  'tb.u_gold.Mul.rdyVec_1' \
	  'tb.u_read.u_core.u_mul.u_core.rdy_s0' \
	  'tb.u_read.u_core.u_mul.u_core.rdy_s1' \
	  '# 本执行口没有变长迭代的 Div —— Div 在别的 ExeUnit 变体里' \
	  '' \
	  '# ============ 4. flush 窗口只有 2 拍（教学点 4） ============' \
	  'tb.flush_valid' \
	  'tb.flush_robIdx_value' \
	  'tb.flush_level' \
	  '# 可读侧把两个判定点显式命名了；golden 里这两个表达式是内联的，没有名字' \
	  'tb.u_read.u_core.kill_s0' \
	  'tb.u_read.u_core.kill_s1' \
	  '# 判定结果落在存活链上（就是第 2 组的 (a)）' \
	  'tb.u_gold.inPipe_2_1' \
	  'tb.u_gold.inPipe_2_2' \
	  'tb.u_read.u_core.alive_s1' \
	  'tb.u_read.u_core.alive_s2' \
	  '' \
	  '# ============ 5. ctrlPipe：控制位在 FU 外面走（教学点 5） ============' \
	  'tb.u_gold.inPipe_1_1_robIdx_value' \
	  'tb.u_gold.inPipe_1_2_robIdx_value' \
	  'tb.u_gold.inPipe_1_2_pdest' \
	  'tb.u_read.u_core.ctrl_s1' \
	  'tb.u_read.u_core.ctrl_s2' \
	  '' \
	  '# ============ 6. 时钟门控影子链（阶段 8） ============' \
	  'tb.u_gold.fuVldVec_1' \
	  'tb.u_gold.fuVldVec_2' \
	  'tb.u_gold.clk_en_1_probe' \
	  'tb.u_gold._ClockGate_Q' \
	  'tb.u_read.u_core.g_gate[0].occ_s1' \
	  'tb.u_read.u_core.g_gate[0].occ_s2' \
	  'tb.u_read.u_core.clk_en_gated' \
	  'tb.u_read.u_core.fu_clk' \
	  '' \
	  '# ============ 7. 写回口：两侧应当逐拍完全重合 ============' \
	  'tb.g_out_valid' \
	  'tb.r_out_valid' \
	  'tb.g_data0' \
	  'tb.r_data0' \
	  'tb.g_rob_value' \
	  'tb.r_rob_value' \
	  'tb.g_pdest' \
	  'tb.r_pdest' \
	  'tb.g_intWen' \
	  'tb.r_intWen' \
	  > signals.txt
	@echo "信号清单 -> $(CURDIR)/signals.txt"

clean:
	rm -rf simv* csrc *.log ucli.key novas.* verdiLog *.fsdb *.daidir vc_hdrs.h \
	       $(UT_GEN_DIR) signals.txt .inter.vpd.uvm
