#!/usr/bin/env python3
"""生成 PMPChecker 家族的双例化 UT testbench（tb.sv）。

三对同测（scripts/dual_tb_lib.py，端口表读 G1 golden）：
  PMPChecker    vs PMPChecker_xs      纯组合（sameCycle）
  PMPChecker_2  vs PMPChecker_2_xs    结果打一拍，无 reset 口
  PMPChecker_12 vs PMPChecker_12_xs   leaveHitMux：命中位/权限/cmd 打一拍

激励（纯随机的 48 位地址几乎不可能命中任何表项，所以全部偏置）：
  * 表项基址落在 20 个 4KB "区" 里（外加调试模块地址段附近的三个区），请求地址同样落在这些区，
    另有 1/6 的请求打在调试段边界 [0x3801FFF0, 0x38021010]，1/32 全随机；
  * mask 取 NAPOT 形（低 12..17 位全 1），1/8 全随机；
  * cfg.a 按 mode 分四档：全随机 / 稀疏 / 只有高下标项启用（逼出"靠后的项胜出"）/ 几乎全关（走缺省项）；
  * env_mode、debug、cmd、req_valid 全随机（cmd 八个编码全打，含未定义的 3'b011 / 3'b110）。
不复位寄存器（_2 的结果寄存器；_12 的权限与 cmd 寄存器）在 +random 档两侧初值不同，
所以这两对在"至少见过一次 req_valid"之后才开始比（arm）。

PMPChecker_2 没有 reset 口：dual_tb_lib 的 clocked 模式要求 clock/reset 都在，这里先按非时钟对
构造（端口检查不拦），再把 clocked 置真并用 decls 补一个不接任何东西的 reset 变量 —— 目的只是
让库把 clock 接到 tb 的 clk 而不是每拍灌随机数。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

NUM = 32


def decls(x):
    return """
function automatic logic [45:0] {x}rnd_addr();
  logic [47:0] p;
  case ($urandom_range(0, 15))
    0:       p = {{$urandom, $urandom}};
    1, 2:    p = 48'(48'h3801F + $urandom_range(0, 2)) << 12;
    default: p = 48'($urandom_range(0, 19)) << 12;
  endcase
  return {{p[47:12], 10'($urandom)}};
endfunction
function automatic logic [47:0] {x}rnd_mask();
  if ($urandom_range(0, 7) == 0) return {{$urandom, $urandom}};
  return (48'h1 << $urandom_range(12, 17)) - 48'h1;
endfunction
function automatic logic [47:0] {x}rnd_req();
  int unsigned k;
  k = $urandom_range(0, 31);
  if (k == 0) return {{$urandom, $urandom}};
  if (k < 6)  return 48'h3801FFF0 + 48'($urandom_range(0, 32'h1020));
  return {{36'($urandom_range(0, 21)), 12'($urandom)}};
endfunction
function automatic logic [1:0] {x}rnd_a(input int unsigned mode, input int unsigned idx);
  case (mode % 4)
    0:       return 2'($urandom);
    1:       return ($urandom_range(0, 7) == 0) ? 2'($urandom) : 2'b00;
    2:       return (idx >= 2 * mode) ? 2'($urandom) : 2'b00;
    default: return ($urandom_range(0, 63) == 0) ? 2'($urandom) : 2'b00;
  endcase
endfunction
""".format(x=x)


def stim(x):
    s = []
    for kind in ("pmp", "pma"):
        for i in range(NUM):
            s.append("@io_check_env_%s_%d_cfg_a = %srnd_a(@mode, %d);" % (kind, i, x, i))
            s.append("@io_check_env_%s_%d_addr = %srnd_addr();" % (kind, i, x))
            s.append("@io_check_env_%s_%d_mask = %srnd_mask();" % (kind, i, x))
    s.append("@io_req_bits_addr = %srnd_req();" % x)
    return "\n".join(s)


def in_debug():
    return "(@io_req_bits_addr >= 48'h38020000 && @io_req_bits_addr <= 48'h38020fff)"


COMMON_COV = [
    ("dbg_range_blocked", in_debug() + " && !@io_check_env_debug"),
    ("dbg_range_allowed", in_debug() + " && @io_check_env_debug"),
    ("mmode", "@io_check_env_mode[1]"),
    ("mmio0", "!@io_resp_mmio"),
    ("mmio1", "@io_resp_mmio"),
]

# ---- PMPChecker（组合）：命中位直接看 golden 内部线 ----
G0 = "p0_u_gold."
COV0 = COMMON_COV + [
    ("ld1", "@io_resp_ld"), ("ld0", "!@io_resp_ld"),
    ("atomic1", "@io_resp_atomic"),
    ("pmp_hit_e0", G0 + "res_pmp_is_match"),
    ("pma_hit_e0", G0 + "res_pma_is_match"),
    ("pma_hit_e31", G0 + "res_pma_is_match_31"),
]

# ---- PMPChecker_2（结果打一拍）----
G2 = "p2_u_gold."
COV2 = COMMON_COV + [
    ("instr1", "@io_resp_instr"), ("instr0", "!@io_resp_instr"),
    ("req_valid", "@io_req_valid"),
    ("pmp_hit_e0", G2 + "res_pmp_is_match"),
    ("pma_hit_e31", G2 + "res_pma_is_match_31"),
]

# ---- PMPChecker_12（leaveHitMux）：命中位寄存器 res_{pmp,pma}_r[_i]，cmd 是打过拍的 ----
G12 = "p12_u_gold."
any_pmp = "(" + " || ".join([G12 + "res_pmp_r"] + [G12 + "res_pmp_r_%d" % i for i in range(1, NUM)]) + ")"
any_pma = "(" + " || ".join([G12 + "res_pma_r"] + [G12 + "res_pma_r_%d" % i for i in range(1, NUM)]) + ")"
only_last_pmp = "(%sres_pmp_r_31 && !(%s))" % (
    G12, " || ".join([G12 + "res_pmp_r"] + [G12 + "res_pmp_r_%d" % i for i in range(1, NUM - 1)]))
only_last_pma = "(%sres_pma_r_31 && !(%s))" % (
    G12, " || ".join([G12 + "res_pma_r"] + [G12 + "res_pma_r_%d" % i for i in range(1, NUM - 1)]))
COV12 = COMMON_COV + [
    ("req_valid", "@io_req_valid"),
    ("pmp_hit_e0", G12 + "res_pmp_r"),
    ("pmp_hit_last_only", only_last_pmp),
    ("pmp_default", "!" + any_pmp),
    ("pmp_default_mmode", "!%s && %sres_pmp_r_33_32_cfg_r" % (any_pmp, G12)),
    ("pma_hit_e0", G12 + "res_pma_r"),
    ("pma_hit_last_only", only_last_pma),
    ("pma_default", "!" + any_pma),
    ("atomic1", "@io_resp_atomic"),
]
# 访问类型 × 结果：cmd 八个编码各自见过；每个违例输出在其相关 cmd 下拉高/不拉高
for c in range(8):
    COV12.append(("cmd%d" % c, "%scmd == 3'd%d" % (G12, c)))
for c in (0, 4, 7):
    COV12.append(("cmd%d_ld1" % c, "%scmd == 3'd%d && @io_resp_ld" % (G12, c)))
    COV12.append(("cmd%d_ld0" % c, "%scmd == 3'd%d && !@io_resp_ld" % (G12, c)))
for c in (1, 5):
    COV12.append(("cmd%d_st1" % c, "%scmd == 3'd%d && @io_resp_st" % (G12, c)))
    COV12.append(("cmd%d_st0" % c, "%scmd == 3'd%d && !@io_resp_st" % (G12, c)))
for c in (2, 7):
    COV12.append(("cmd%d_instr1" % c, "%scmd == 3'd%d && @io_resp_instr" % (G12, c)))
    COV12.append(("cmd%d_instr0" % c, "%scmd == 3'd%d && !@io_resp_instr" % (G12, c)))

p0 = Pair("PMPChecker", "p0_", clocked=False, stim=stim("p0_"), decls=decls("p0_"),
          cov=COV0, mode_period=2000, cov_min=200)
p2 = Pair("PMPChecker_2", "p2_", clocked=False, stim=stim("p2_"),
          decls=decls("p2_") + "logic p2_reset;  // golden 无 reset 口，仅为满足 dual_tb_lib 的 clocked 路径\n",
          cov=COV2, mode_period=2000, cov_min=200, arm=["@io_req_valid"])
p2.clocked = True
p12 = Pair("PMPChecker_12", "p12_", clocked=True, stim=stim("p12_"), decls=decls("p12_"),
           cov=COV12, mode_period=2000, reset_period=20000, cov_min=200, arm=["@io_req_valid"])

HEADER = """自动生成：verif/ut/PMPChecker/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
PMPChecker 家族三对双例化逐拍比对：golden PMPChecker / _2 / _12 vs 重写 *_xs，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render([p0, p2, p12], HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
