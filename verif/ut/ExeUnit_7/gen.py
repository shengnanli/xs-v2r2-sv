#!/usr/bin/env python3
"""生成 ExeUnit_7 的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

golden ExeUnit_7 vs ExeUnit_7_xs（csr / Fence / Div 两侧各用各的：golden 侧 golden 子树，重写侧本仓重写子树），
全部输出逐拍逐位 !==。

ExeUnit_7 = CSR 执行单元外壳：Dispatcher_7 按 fuType 派给 csr(35'h20) / Fence(35'h200) / Div(35'h100)，三者都是
不定延迟 FU，外壳 busy 一次只放一条。激励沿用 verif/ut/CSR/tb.sv 的套路（那份 tb 是 CSR 签核用的），只是 uop 从
ExeUnit 的扁平口进：
  * 合法 CSR 地址表 LEGAL（337 个）、系统指令 funct12 池、CSR 访问 opType 池、写数据 WARL 偏置 —— 从
    verif/ut/CSR/tb.sv 原样取（取不到或个数不对即失败）；
  * 每拍：valid 60%；fuType 72% csr / 10% Fence / 15% Div / 3% 随机（多半不命中任何 FU，Dispatcher 吞掉）；
    csr：75% CSR 访问（80% 合法地址，1/10 打间接寄存器 mireg/sireg/vsireg）、25% 系统指令
    （比 CSR UT 的 15% 高：外壳 busy 让 csr 收指令的拍数少了，xret 覆盖要补回来）；
    Fence：99% 合法 FenceOpType（6 个），1% 随机（非法 op 会把 Fence 状态机卡死在 s_wait，靠偶发复位解开，同
    verif/ut/Fence 的 golden 行为坑）；sbuffer 空 80%；Div：10% 除数为 0；
    robIdx 与冲刷 robIdx 取 0..15 窄范围、冲刷 3%；trap 3%（exceptionVec 单热）；外部中断线慢变，debug/NMI 稀；
    MSI 5%；out.ready 70%；DFT 时钟门控 cg_bore_*_cgen 1/20；NMIE=0 时的救援（同 CSR UT）。
  * 暖机（上电复位后、开始比较之前，不比对）：CSR 的大量状态寄存器不复位，两个独立例化在随机初值档各摇一份，
    必须先写成确定值 —— 照 CSR UT 的暖机程序：M 态 csrrw 写遍 337 个合法地址；4 组触发器 tselect/tdata1/tdata2；
    拉 debug 中断进调试模式（进不去就走单步异常）；写 dpc/dscratch0/1；dret；打一个 trap；mret。
    uop 型步骤以 golden 外壳 busy 的上升沿判「上一条已被收下」再发下一条（暖机期不冲刷，busy 上升沿与 in.fire 一一对应）。
    暖机做完才 arm（之后每拍都比，含偶发复位后的拍）。
覆盖（每项 >= cov_min，否则 TEST FAILED）：三个 FU 各自的 fire / 写回、busy、冲刷命中在途、反压、trap 进 M 态、
mret、合法 CSR 写、EX_II、xret/中断重定向、MSI。恒值输出位见 EXEMPT（逐项给理由），不要求见过 0/1 但照样逐拍比。

用法：python3 gen.py [--check]
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

TOP = "ExeUnit_7"
X = "e7_"
G = X + "u_gold"
M = G + ".csr.csrMod"          # golden NewCSR 实例（内部信号做覆盖 / 暖机判据）

# ---- 从 CSR 签核 tb 取合法地址表 ----
csr_tb = open(os.path.join(HERE, "..", "CSR", "tb.sv")).read()
m = re.search(r"localparam int NLEGAL = (\d+);\n\s*localparam logic \[11:0\] LEGAL \[NLEGAL\] = '\{([^}]*)\};", csr_tb)
if not m:
    raise SystemExit("verif/ut/CSR/tb.sv 里找不到 LEGAL 表")
NLEGAL = int(m.group(1))
LEGAL = [x.strip() for x in m.group(2).split(",")]
if len(LEGAL) != NLEGAL or NLEGAL != 337 or not all(re.fullmatch(r"12'h[0-9A-F]{3}", x) for x in LEGAL):
    raise SystemExit("LEGAL 表形状不对：%d 项" % len(LEGAL))

DECLS = """
localparam int E7_NLEGAL = %d;
localparam logic [11:0] e7_LEGAL [E7_NLEGAL] = '{%s};
localparam logic [11:0] e7_SYSOP [6] = '{12'h000, 12'h001, 12'h702, 12'h302, 12'h102, 12'h7B2};
localparam logic [8:0]  e7_CSROP [6] = '{9'h9, 9'hA, 9'hB, 9'hD, 9'hE, 9'hF};
localparam logic [8:0]  e7_FENCEOP [6] = '{9'h00, 9'h10, 9'h11, 9'h12, 9'h13, 9'h14};
logic [3:0]  e7_irq = '0;          // mtip msip meip seip：慢变
logic [63:0] e7_clint = '0;
logic [7:0]  e7_hart = 8'h5A;
int unsigned e7_wph = 0, e7_widx = 0, e7_wcnt = 0;   // 暖机程序：阶段 / 阶段内序号 / 阶段内拍数
bit e7_wdone = 0, e7_pbusy = 0;
function automatic bit e7_pct(int p);
  return $urandom_range(9999) < p * 100;
endfunction
function automatic logic [63:0] e7_rnd64();
  case ($urandom_range(7))
    0: return 64'h0;
    1: return '1;
    default: return {$urandom, $urandom};
  endcase
endfunction
// 写数据偏置（与 CSR / NewCSR UT 相同的几条 WARL 规律）
function automatic logic [63:0] e7_bias(input logic [11:0] a, input logic [63:0] d);
  if (a == 12'h7B0 && e7_pct(90)) begin d[17:12] = 6'h0; d[2] = 1'b0; end
  if (a == 12'h744 && e7_pct(90)) d[3] = 1'b1;
  if ((a == 12'h350 || a == 12'h150 || a == 12'h250) && e7_pct(80))
    d = e7_pct(50) ? 64'($urandom_range(8'hFF, 8'h70)) : 64'($urandom_range(8'h3F, 8'h30));
  if ((a == 12'h180 || a == 12'h280 || a == 12'h680) && e7_pct(70))
    d[63:60] = e7_pct(30) ? 4'h0 : (e7_pct(50) ? 4'h8 : 4'h9);
  if (a == 12'h7A1 && e7_pct(70)) d[63:60] = 4'h6;
  if (a == 12'h7A0 && e7_pct(80)) d = 64'($urandom_range(3));
  if ((a == 12'h302 || a == 12'h303 || a == 12'h602 || a == 12'h603) && e7_pct(50)) d = '1;
  return d;
endfunction
""" % (NLEGAL, ", ".join(LEGAL))

EXC = ["@io_csrio_exception_bits_exceptionVec_%d" % k for k in range(24)]

STIM = """
logic [11:0] a;
logic [8:0]  op;
int          f;
bit          adv;
// ---- 慢变 / 稀疏的 CSR 环境输入 ----
for (int k = 0; k < 4; k++) if (e7_pct(5)) e7_irq[k] = ~e7_irq[k];
{@io_csrio_externalInterrupt_mtip, @io_csrio_externalInterrupt_msip,
 @io_csrio_externalInterrupt_meip, @io_csrio_externalInterrupt_seip} = e7_irq;
@io_csrio_externalInterrupt_debug      = ($urandom_range(1999) == 0);
@io_csrio_externalInterrupt_nmi_nmi_31 = ($urandom_range(1999) == 0);
@io_csrio_externalInterrupt_nmi_nmi_43 = ($urandom_range(1999) == 0);
@io_csrin_hartId = e7_hart;
e7_clint += $urandom_range(3);
@io_csrin_clintTime_bits = e7_clint;
@io_csrin_criticalErrorState = ($urandom_range(49999) == 0);
@io_csrin_msiInfo_valid = e7_pct(5);
// ---- 发射口 uop ----
@io_in_valid = e7_pct(60);
@io_in_bits_robIdx_value = 8'($urandom_range(0, 15));
@io_flush_bits_robIdx_value = 8'($urandom_range(0, 15));
f = $urandom_range(99);
if (f < 72) begin
  @io_in_bits_fuType = 35'h20;                       // csr
  if (e7_pct(75)) begin
    op = e7_CSROP[$urandom_range(5)];
    a  = e7_pct(80) ? e7_LEGAL[$urandom_range(E7_NLEGAL - 1)] : 12'($urandom);
    if (e7_pct(10)) a = e7_pct(34) ? 12'h351 : (e7_pct(50) ? 12'h151 : 12'h251);
  end else begin
    op = 9'h10;
    a  = e7_pct(75) ? e7_SYSOP[$urandom_range(5)] : 12'($urandom);
  end
  @io_in_bits_fuOpType  = op;
  @io_in_bits_imm[11:0] = a;
  @io_in_bits_imm[16:12] = e7_pct(75) ? 5'($urandom_range(31, 1)) : 5'h0;
  @io_in_bits_imm[21:17] = e7_pct(75) ? 5'($urandom_range(31, 1)) : 5'h0;
  @io_in_bits_src_0 = e7_bias(a, e7_rnd64());
end else if (f < 82) begin
  @io_in_bits_fuType = 35'h200;                      // Fence
  @io_in_bits_fuOpType = e7_pct(99) ? e7_FENCEOP[$urandom_range(5)] : 9'($urandom);
end else if (f < 97) begin
  @io_in_bits_fuType = 35'h100;                      // Div
  if (e7_pct(10)) @io_in_bits_src_1 = '0;
end
@io_flush_valid = e7_pct(3);
@io_csrio_exception_valid = e7_pct(3);
%s
if (e7_pct(80)) case ($urandom_range(23))
%s
endcase
@io_csrio_exception_bits_isInterrupt = e7_pct(30);
@io_csrio_exception_bits_singleStep = e7_pct(1);
@io_csrio_exception_bits_isPcBkpt = e7_pct(5);
@io_csrio_exception_bits_satpFlushFirstFetchFault = e7_pct(5);
@io_csrio_exception_bits_isFetchMalAddr = e7_pct(5);
@io_csrio_exception_bits_trigger = e7_pct(85) ? 4'hF : 4'($urandom);
@io_csrio_fpu_fflags_valid = e7_pct(20);
@io_csrio_vpu_set_vxsat_valid = e7_pct(20);
@io_csrio_vpu_set_vtype_valid = e7_pct(20);
@io_csrio_vpu_set_vstart_valid = e7_pct(20);
@io_csrio_fpu_dirty_fs = e7_pct(10);
@io_csrio_vpu_dirty_vs = e7_pct(10);
@io_csrin_fromVecExcpMod_busy = e7_pct(20);
@io_csrin_trapInstInfo_valid = e7_pct(20);
@io_out_ready = e7_pct(70);
@io_fenceio_sbuffer_sbIsEmpty = e7_pct(80);
@cg_bore_cgen = ($urandom_range(0, 19) == 0);
@cg_bore_1_cgen = ($urandom_range(0, 19) == 0);
@cg_bore_2_cgen = ($urandom_range(0, 19) == 0);
// ---- NMIE=0 时的救援（同 CSR UT）----
if (!%s._mnstatus_regOut_NMIE && %s.PRVM != 2'h3 && !%s.debugMode && e7_pct(2))
  @io_csrio_externalInterrupt_debug = 1'b1;
if (!%s._mnstatus_regOut_NMIE && e7_pct(10)) begin
  @io_in_valid = 1'b1;
  @io_in_bits_fuType = 35'h20;
  @io_in_bits_fuOpType = 9'h9;
  @io_in_bits_imm[21:0] = {5'h1, 5'h1, 12'h744};
  @io_in_bits_src_0 = 64'h8;
end
// ---- 暖机程序（上电复位后一次；不比对）----
if (cyc < RESET_CYC) begin
  e7_wph = 0; e7_widx = 0; e7_wcnt = 0; e7_wdone = 0;
end else if (!e7_wdone) begin
  adv = %s.busy && !e7_pbusy;                       // busy 上升沿：上一条 uop 已被收下
  @io_flush_valid = 1'b0;
  @io_csrio_exception_valid = 1'b0;
  @io_out_ready = 1'b1;
  @io_csrio_externalInterrupt_debug = 1'b0;
  @io_in_valid = 1'b0;
  @io_in_bits_fuType = 35'h20;
  @io_in_bits_imm[21:12] = {5'h1, 5'h1};
  e7_wcnt++;
  if (adv) begin e7_widx++; e7_wcnt = 0; end
  if (e7_wcnt > 200) begin e7_widx++; e7_wcnt = 0; end    // 超时跳过（不该发生；发生了覆盖会显出来）
  case (e7_wph)
    0: if (e7_widx >= E7_NLEGAL) begin e7_wph = 1; e7_widx = 0; e7_wcnt = 0; end
    1: if (e7_widx >= 12) begin e7_wph = 2; e7_widx = 0; e7_wcnt = 0; end
    2: if (e7_wcnt >= 14) begin e7_wph = 3; e7_widx = 0; e7_wcnt = 0; end
    3: if (e7_wcnt >= 6) begin e7_wph = 4; e7_widx = 0; e7_wcnt = 0; end
    4: if (e7_widx >= 3) begin e7_wph = 5; e7_widx = 0; e7_wcnt = 0; end
    5: if (e7_widx >= 1) begin e7_wph = 6; e7_widx = 0; e7_wcnt = 0; end
    6: if (e7_wcnt >= 6) begin e7_wph = 7; e7_widx = 0; e7_wcnt = 0; end
    7: if (e7_widx >= 1) begin e7_wph = 8; e7_widx = 0; e7_wcnt = 0; end
    default: ;
  endcase
  case (e7_wph)
    0: begin                                         // csrrw 写遍合法地址
      a = e7_LEGAL[e7_widx];
      @io_in_valid = 1'b1;
      @io_in_bits_fuOpType = 9'h9;
      @io_in_bits_imm[11:0] = a;
      @io_in_bits_src_0 = (a == 12'h7B0) ? 64'h0 : (a == 12'h744) ? 64'h8 : e7_bias(a, e7_rnd64());
    end
    1: begin                                         // 触发器：tselect=t / tdata1=0 / tdata2=随机
      @io_in_valid = 1'b1;
      @io_in_bits_fuOpType = 9'h9;
      @io_in_bits_imm[11:0] = 12'h7A0 + 12'(e7_widx %% 3);
      @io_in_bits_src_0 = (e7_widx %% 3 == 0) ? 64'(e7_widx / 3) : (e7_widx %% 3 == 1) ? 64'h0 : {$urandom, $urandom};
    end
    2: begin                                         // 拉调试中断进 debug（trap 在第 12 拍）
      @io_csrio_externalInterrupt_debug = 1'b1;
      @io_csrio_exception_valid = (e7_wcnt == 12);
      @io_csrio_exception_bits_isInterrupt = 1'b1;
    end
    3: begin                                         // 没进去：走单步异常
      @io_csrio_exception_valid = (e7_wcnt == 0) && !%s.debugMode;
      @io_csrio_exception_bits_isInterrupt = 1'b0;
      @io_csrio_exception_bits_singleStep = 1'b1;
    end
    4: begin                                         // dpc / dscratch0 / dscratch1
      @io_in_valid = 1'b1;
      @io_in_bits_fuOpType = 9'h9;
      @io_in_bits_imm[11:0] = 12'h7B1 + 12'(e7_widx);
      @io_in_bits_src_0 = e7_rnd64();
    end
    5: begin                                         // dret
      @io_in_valid = 1'b1;
      @io_in_bits_fuOpType = 9'h10;
      @io_in_bits_imm[21:0] = {10'h0, 12'h7B2};
    end
    6: @io_csrio_exception_valid = (e7_wcnt == 0);  // 打一个 trap
    7: begin                                         // mret
      @io_in_valid = 1'b1;
      @io_in_bits_fuOpType = 9'h10;
      @io_in_bits_imm[21:0] = {10'h0, 12'h302};
    end
    default: e7_wdone = 1;
  endcase
end
e7_pbusy = %s.busy;
""" % ("\n".join("%s = 1'b0;" % e for e in EXC),
       "\n".join("  %d: %s = 1'b1;" % (k, e) for k, e in enumerate(EXC)),
       M, M, M, M, G, M, G)

COV = [
    ("csr_fire", "@io_in_valid && @io_in_ready && @io_in_bits_fuType == 35'h20"),
    ("fence_fire", "@io_in_valid && @io_in_ready && @io_in_bits_fuType == 35'h200"),
    ("div_fire", "@io_in_valid && @io_in_ready && @io_in_bits_fuType == 35'h100"),
    ("csr_out", G + "._csr_io_out_valid"),
    ("fence_out", G + "._Fence_io_out_valid"),
    ("div_out", G + "._Div_io_out_valid"),
    ("busy", G + ".busy"),
    ("flush_busy", "@io_flush_valid && " + G + ".busy"),
    ("stall", "@io_out_valid && !@io_out_ready"),
    ("trap_m", M + ".trapEntryMEvent.valid"),
    ("mret", M + "._permitMod_io_out_hasLegalMret"),
    ("csr_wen", M + ".wenLegalReg_last_REG"),
    ("ex_ii", "@io_out_valid && @io_out_bits_exceptionVec_2"),
    ("redirect", "@io_out_bits_redirect_valid"),
    ("msi", "@io_csrin_msiInfo_valid"),
]

# 恒值输出位（不要求见过 0/1，照样逐拍比）：先空，按探针跑的实测与机理逐项补
EXEMPT = []

PAIRS = [Pair(TOP, X, clocked=True, stim=STIM, cov=COV, decls=DECLS, exempt=EXEMPT,
              arm=["e7_wdone"], reset_period=20000, mode_period=2000, cov_min=100)]

HEADER = """自动生成：verif/ut/ExeUnit_7/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
ExeUnit_7 双例化逐拍比对，全部输出逐位 !==；激励 / 暖机 / 覆盖见 gen.py 文件头。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
