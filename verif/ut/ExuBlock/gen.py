#!/usr/bin/env python3
"""生成 ExuBlock 的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

golden ExuBlock vs ExuBlock_xs（8 个 ExeUnit 两侧各用各的：golden 侧 golden 子树，重写侧本仓重写子树），
全部输出逐拍逐位 !==。ExuBlock = 整数执行块：exus/exus_2 = ExeUnit（Alu/Mul/Bku）、exus_1/exus_3 = ExeUnit_1（brh/jmp）、
exus_4/exus_6 = ExeUnit_4（Alu）、exus_5 = ExeUnit_5（brh/jmp/i2f/vset/i2v）、exus_7 = ExeUnit_7（csr/Fence/Div）。

激励：
  * exus_7 的发射口 io_in_3_1 与全部 CSR 环境口（csrio / csrin / fenceio）：照搬 verif/ut/ExeUnit_7/gen.py 的
    csr_exu_parts（同一套 CSR 激励、暖机程序、arm 条件与覆盖项，只把端口前缀换成 io_in_3_1 / io_out_3_1、golden 层次换成
    exus_7）；暖机做完才 arm。
  * 其余 7 个发射口：与 verif/ut/ExuBlock_1/gen.py 同一套路（按所接 ExeUnit 的结构自动推出）：fuType 85% 取该
    ExeUnit 某个 FU 的编码（Dispatcher acceptVec 常量，从 golden 解析）、valid 60%、robIdx 3/4 取 0..15；
    复位撤销后 48 拍轮流灌每个 FU；frm 每拍随机；DFT 时钟门控 cg_bore_*_cgen 1/20 强开。
  * 冲刷：CSR 片段里 3%（暖机期不冲刷）。
覆盖（每项 >= cov_min，否则 TEST FAILED）：每个发射口 fire、每个 FU 写回、CSR 片段的各项。
恒值输出位见 EXEMPT（逐项给理由），不要求见过 0/1 但照样逐拍比。

用法：python3 gen.py [--check]
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
sys.path.insert(0, os.path.join(HERE, "..", "ExeUnit_7"))
from dual_tb_lib import Pair, render, write_or_check, G as GOLDEN  # noqa: E402
import gen_exeunit  # noqa: E402
import importlib.util  # noqa: E402

_spec = importlib.util.spec_from_file_location("e7gen", os.path.join(HERE, "..", "ExeUnit_7", "gen.py"))
e7gen = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(e7gen)

TOP = "ExuBlock"
X = "eb_"
G = X + "u_gold"
WARM_END = 8 + 48      # RESET_CYC 之后 48 拍暖机（非 CSR 口）


def golden_insts():
    txt = open(os.path.join(GOLDEN, TOP + ".sv")).read()
    out = []
    for m in re.finditer(r"^  (ExeUnit(?:_\d+)?) (\w+) \(\n(.*?)^  \);", txt, re.S | re.M):
        cm = dict((c.group(1), " ".join(c.group(2).split()))
                  for c in re.finditer(r"\.(\w+)\s*\((.*?)\)\s*(?:,|$)", m.group(3), re.S))
        out.append((m.group(1), m.group(2), cm["io_in_valid"][:-len("_valid")], cm["io_out_valid"][:-len("_valid")]))
    if len(out) != 8:
        raise SystemExit("ExuBlock: 解析到 %d 个 ExeUnit 实例（应为 8）" % len(out))
    return out


def fu_codes(typ):
    v = gen_exeunit.Variant(typ)
    disp = open(os.path.join(GOLDEN, v.disp[0] + ".sv")).read()
    codes = []
    for k in range(len(v.fus)):
        m = re.search(r"wire\s+(?:acceptVec_%d|data_0_probe) = io_in_bits_fuType == 35'h([0-9A-F]+);" % k, disp)
        if not m:
            raise SystemExit("%s: 找不到 Dispatcher 出口 %d 的 fuType 编码" % (typ, k))
        codes.append(m.group(1))
    return v, codes


INSTS = golden_insts()
ports = {n for _, _, n in Pair(TOP, X).ports}
DECLS, STIM, COV, EXEMPT = [], [], [], []
for n in sorted(ports):
    if re.fullmatch(r"cg_bore(_\d+)?_cgen", n):
        STIM.append("@%s = ($urandom_range(0, 19) == 0);" % n)
csr = None
for typ, iname, pin, pout in INSTS:
    if typ == "ExeUnit_7":
        csr = (iname, pin, pout)
        continue
    v, codes = fu_codes(typ)
    tbl = "%s%s_code" % (X, iname)
    DECLS.append("logic [34:0] %s [%d] = '{%s};" % (tbl, len(codes), ", ".join("35'h" + c for c in codes)))
    STIM += [
        "if ($urandom_range(0, 99) < 85) @%s_bits_fuType = %s[$urandom_range(0, %d)];" % (pin, tbl, len(codes) - 1),
        "@%s_valid = ($urandom_range(0, 9) < 6);" % pin,
        "if ($urandom_range(0, 3) != 0) @%s_bits_robIdx_value = 8'($urandom_range(0, 15));" % pin,
        "if (cyc >= 8 && cyc < %d) begin" % WARM_END,
        "  @%s_valid = 1'b1;" % pin,
        "  @%s_bits_fuType = %s[cyc %% %d];" % (pin, tbl, len(codes)),
        "end",
    ]
    COV.append(("%s_fire" % iname, "@%s_valid && @%s_ready" % (pin, pin)))
    for _, fu, _ in v.fus:
        COV.append(("%s_%s_out" % (iname, fu), "%s.%s._%s_io_out_valid" % (G, iname, fu)))
if csr is None:
    raise SystemExit("ExuBlock: 没有 ExeUnit_7 实例")
cdecl, cstim, ccov, carm = e7gen.csr_exu_parts(G + "." + csr[0], pin=csr[1], pout=csr[2], keep_cg=False)
COV += [(csr[0] + "_" + n, e) for n, e in ccov]


# ---- 不要求见过 0/1 的输出位（照样逐拍比），全部按机理圈定 ----
_gtxt = open(os.path.join(GOLDEN, TOP + ".sv")).read()
_e7c = dict((c.group(1), " ".join(c.group(2).split())) for c in re.finditer(
    r"\.(\w+)\s*\((.*?)\)\s*(?:,|$)",
    re.search(r"^  ExeUnit_7 %s \(\n(.*?)^  \);" % csr[0], _gtxt, re.S | re.M).group(1), re.S))
_assigns = dict(re.findall(r"^  assign (\w+) = (\w+);", _gtxt, re.M))
# (1) exus_7（ExeUnit_7）上 ExeUnit_7 自己 tb 豁免的口（子 FU 直连口、VS 态 ecall 位），经本层直连 / assign 到顶层口的那些
for _p in e7gen.exempt_ports("ExeUnit_7"):
    _e = _e7c.get(_p, "")
    if _e in ports:
        EXEMPT.append(_e)
    for _o, _src in _assigns.items():
        if _e and _src == _e:
            EXEMPT.append(_o)
for typ, iname, pin, pout in INSTS:
    if typ == "ExeUnit_7":
        continue
    v = gen_exeunit.Variant(typ)
    etxt = open(os.path.join(GOLDEN, typ + ".sv")).read()
    # (2) 无 busy 的 ExeUnit 的 in.ready 恒 1（同 ExuBlock_1）
    if not v.has_busy:
        EXEMPT.append(pin + "_ready")
    # (3) golden ExeUnit 里写成 {64'h0, ...} 的数据口高 64 位恒 0（同 ExuBlock_1）
    for m in re.finditer(r"assign io_out_bits_(data_\d+) = \{64'h0,", etxt):
        EXEMPT += ["%s_bits_%s[%d]" % (pout, m.group(1), b) for b in range(64, 128)]
    # (2b) 写回 Mux1H 的成员 FU 在各自 golden 里把该字段赋成常量（如 BranchUnit / JumpUnit 的 redirect.cfiUpdate 历史字段
    #      全 0）⇒ 外壳输出口按构造恒 0（逐个成员核 golden 的 `assign <口> = <N>'h0;`，有一个不是常量就不豁免）
    for _o, _k in v.out_kind.items():
        if _k[0] != "mux":
            continue
        _const = True
        for _f in _k[1]:
            _ft = [t for t, n, _ in v.fus if n == _f][0]
            _fx = open(os.path.join(GOLDEN, _ft + ".sv")).read()
            if not re.search(r"^  assign io_out_bits_%s = \d+'h0;$" % re.escape(_k[2][_f]), _fx, re.M):
                _const = False
        if _const:
            EXEMPT.append(pout + _o[len("io_out"):])
    # (2c) redirect.cfiUpdate.backendIGPF（brh / jmp）：只在取指地址翻译处于 sv39x4 / sv48x4（两级翻译）且目标越界时才置 1，
    #      要 CSR 先进 V 态并写好 hgatp/vsatp —— 本激励不专门进虚拟化模式（同 ExeUnit_7 tb 豁免 VS 态 ecall 位）；
    #      seed 1 碰巧翻到过，seed 7 没有，不能当按构造的闸
    if any(t in ("BranchUnit", "JumpUnit") for t, _, _ in v.fus):
        EXEMPT.append(pout + "_bits_redirect_bits_cfiUpdate_backendIGPF")
    if typ == "ExeUnit_5":
        # (4) data_5 = {64'h0, VSetRiWvf.res_data}，而 VSetRiWvf 的 res_data = {56'h0, vl}（golden VSetRiWvf.sv）⇒ [63:8] 也恒 0
        if not re.search(r"assign io_out_bits_data_5 = \{64'h0, _VSetRiWvf_io_out_bits_res_data\};", etxt) or \
                "assign io_out_bits_res_data = {56'h0, _vsetModule_io_out_vconfig_vl};" not in \
                open(os.path.join(GOLDEN, "VSetRiWvf.sv")).read():
            raise SystemExit("ExeUnit_5 data_5 / VSetRiWvf res_data 形状变了，恒值位豁免要重核")
        EXEMPT += ["%s_bits_data_5[%d]" % (pout, b) for b in range(8, 64)]
        # (5) fflags 只来自 i2f（整数转浮点）：只可能报 NX / OF，UF[1]、DZ[3]、NV[4] 按 IEEE 语义恒 0
        EXEMPT += ["%s_bits_fflags[%d]" % (pout, b) for b in (1, 3, 4)]
EXEMPT = sorted(set(EXEMPT))

PAIRS = [Pair(TOP, X, clocked=True, stim="\n".join(STIM) + "\nbegin : csr_exu\n" + cstim + "\nend", cov=COV,
              decls="\n".join(DECLS) + "\n" + cdecl, exempt=EXEMPT,
              arm=carm, reset_period=20000, mode_period=2000, cov_min=100)]

HEADER = """自动生成：verif/ut/ExuBlock/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
ExuBlock 双例化逐拍比对，全部输出逐位 !==；激励 / 暖机 / 覆盖见 gen.py 文件头。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
