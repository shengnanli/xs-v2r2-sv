# ExeUnit_int0 学习用波形生成
#
# 这是**学习用**目录（verif/study/），不是验收目录（verif/ut/）：
#   · 不做 golden↔重写 双例化比对，只例化 golden 的 ExeUnit 并编排场景；
#   · 不参与 receipt / 可读性闸；
#   · 目的是产出可在 Verdi 里逐拍观察的波形。
#
#   make          编译并跑，产出 novas.fsdb
#   make verdi    打开 Verdi
#   make sig      生成建议观察的信号清单（可在 Verdi 里 Restore Signal）

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN       ?= $(G1_CANONICAL)/golden-rtl

# ExeUnit 的完整子模块闭包（29 个，机械算出：从 ExeUnit 出发遍历例化图）
CLOSURE = ExeUnit Dispatcher ClockGate \
          Alu AluDataModule AluResSel AddModule SubModule \
          LeftShiftModule RightShiftModule LeftShiftWordModule RightShiftWordModule \
          ShiftResultSelect MiscResultSelect ConditionalZeroModule WordResultSelect \
          MulUnit ArrayMulDataModule C22 C32 C53 CSA3_2 \
          Bku CountModule ClmulModule MiscModule CryptoModule BlockCipherModule HashModule

SRCS = $(addprefix $(GOLDEN)/,$(addsuffix .sv,$(CLOSURE)))

export VCS_ARCH_OVERRIDE := linux
VCS := vcs -full64 -sverilog -timescale=1ns/1ps -kdb -lca -debug_access+all \
       +define+SYNTHESIS -l compile.log

.PHONY: all run verdi sig clean

all: run

simv: tb.sv $(SRCS)
	$(VCS) $(SRCS) tb.sv -top tb -o simv

run: simv
	./simv -l sim.log
	@echo; echo "波形: $(CURDIR)/novas.fsdb"

verdi:
	verdi -ssf novas.fsdb -nologo &

# 建议观察的信号：分三组——输入/路由、两套 valid、输出
sig:
	@printf '%s\n' \
	  'tb.phase' 'tb.phase_name' \
	  'tb.u_exe.io_in_valid' 'tb.u_exe.io_in_bits_fuType' 'tb.u_exe.io_in_bits_fuOpType' \
	  'tb.u_exe.io_in_bits_robIdx_value' 'tb.u_exe.io_in_ready' \
	  '# --- Dispatcher 路由（谁被选中）---' \
	  'tb.u_exe.in1ToN.io_out_0_valid' 'tb.u_exe.in1ToN.io_out_1_valid' 'tb.u_exe.in1ToN.io_out_2_valid' \
	  '# --- 存活链 validPipe（flush 在这里生效）---' \
	  'tb.u_exe.inPipe_2_1' 'tb.u_exe.inPipe_2_2' \
	  'tb.u_exe.io_flush_valid' 'tb.u_exe.io_flush_bits_robIdx_value' 'tb.u_exe.io_flush_bits_level' \
	  '# --- 占用链 validVecThisFu（不管 flush）---' \
	  'tb.u_exe.Mul.validVecThisFu_1' 'tb.u_exe.Mul.validVecThisFu_2' \
	  'tb.u_exe.Bku.validVecThisFu_1' 'tb.u_exe.Bku.validVecThisFu_2' \
	  '# --- 输出 ---' \
	  'tb.u_exe.io_out_valid' 'tb.u_exe.io_out_bits_data_0' 'tb.u_exe.io_out_bits_robIdx_value' \
	  > signals.txt
	@echo "信号清单 -> signals.txt"

clean:
	rm -rf simv* csrc *.log ucli.key novas.* verdiLog *.fsdb *.daidir vc_hdrs.h signals.txt
