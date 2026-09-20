#!/usr/bin/env python3
"""EnqEntry* 家族 FM 钉点生成器（共享库）。
产物 = verif/ut/<变体>/fm_pins_pre.tcl（勿手改）。

★为什么需要钉点★（沿用 OthersEntry lane 实测出来的那个名字串台）

golden（firtool 产物）把条目负载展平成上百个逐字段寄存器 `entryReg_payload_<f>_reg[b]`，
可读核把同一份负载存成一根向量 `r_payload_reg[off+b]`，两侧词干完全不同。
OthersEntry lane 的未钉点首跑实测：FM 把 golden 的 **payload.psrc** 配到了可读核的
**status.psrc** 上（两者是不同的寄存器），于是一比就失配 —— 而且只在「存整包负载」
的那一类条目上炸（payload.psrc 只有整包里才有）。

★EnqEntry 全族都属于「存整包负载」那一类★：KEEP_WIDE = IS_ENQ | IS_TRANS，
enq 条目要把整包交给下一级，所以 14/14 都有 transEntry.payload。也就是说
OthersEntry 那边只有 simp 会踩的坑，本族**每个变体都会踩**，钉点不是可选项。

★钉点只做名字对应★ 不 dont_verify、不黑盒、不约束 ref、不跳过任何比较点。
偏移表若算错，FM 会把钉错的对拿去比而**失败**，不会被掩盖。

★事实来源全部机械提取★
  1. 字段偏移表 <- entries_gen.Variant.pl_off（就是生成 <变体>.sv 用的同一张表）
  2. 哪些字段真有寄存器 <- 逐模块解析 golden 的 `reg ... entryReg_*;` 声明

用法（各变体目录下的 gen_fm_pins.py 是薄壳）：
  python3 gen_fm_pins.py            # 生成
  python3 gen_fm_pins.py --check    # 只校验没漂移（非零退出=漂移）
"""
import pathlib, re, sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
sys.path.insert(0, str(HERE))
from enqentry_gen import EnqVariant                              # noqa: E402

REG_RE = re.compile(r'^\s*reg\s+(?:\[\s*(\d+)\s*:\s*0\s*\]\s+)?([A-Za-z_]\w*)\s*;', re.M)


def golden_regs(mod):
    out = {}
    for hi, nm in REG_RE.findall((GOLDEN / f'{mod}.sv').read_text()):
        out[nm] = 1 if hi == '' else int(hi) + 1
    return out


def ref_bits(name, width):
    """golden 寄存器在 FM 里的对象名：1 位标量无下标，多位逐位带下标。"""
    return [(name + '_reg', 0)] if width == 1 else \
           [(f'{name}_reg[{b}]', b) for b in range(width)]


def build_pins(ov):
    v = ov.v
    regs = golden_regs(ov.mod)
    pins, skipped = [], []
    # --- 负载：golden 每字段一个寄存器 <-> 核的一根扁平向量 ---
    # enq 条目存整包（KEEP_WIDE），所以是 pl_all 不是 pl_deq。
    for f, w in v.pl_all:
        gname = 'entryReg_imm' if f == '#imm' else f'entryReg_payload_{f}'
        if gname not in regs:
            skipped.append(gname)           # 本变体里被 firtool DCE 掉了
            continue
        if regs[gname] != w:
            sys.exit(f'ERROR: {ov.mod}.{gname} 位宽 {regs[gname]} != 端口表 {w}')
        off = v.pl_off[f][0]
        for leaf, b in ref_bits(gname, w):
            pins.append((leaf, f'r_payload_reg[{off + b}]'))
    # --- 状态里词干不同 / 核用数组的那几组 ---
    for gname, iname in (('entryReg_status_deqPortIdx', 'r_deq_port_idx_reg'),
                         ('entryReg_status_blocked', 'r_blocked_reg'),
                         ('entryReg_status_issued', 'r_issued_reg'),
                         ('entryReg_status_firstIssue', 'r_first_issue_reg')):
        if gname in regs:
            if regs[gname] != 1:
                sys.exit(f'ERROR: {ov.mod}.{gname} 不是 1 位')
            pins.append((gname + '_reg', iname))
        else:
            skipped.append(gname)
    if 'entryReg_status_issueTimer' in regs:
        for leaf, b in ref_bits('entryReg_status_issueTimer',
                                regs['entryReg_status_issueTimer']):
            pins.append((leaf, f'r_issue_timer_reg[{b}]'))
    else:
        skipped.append('entryReg_status_issueTimer')
    for s in range(v.n_regsrc):
        for gsuf, isig in (('psrc', 'r_psrc_reg'), ('srcType', 'r_src_type_reg'),
                           ('srcState', 'r_src_state_reg'),
                           ('dataSources_value', 'r_data_src_reg'),
                           ('exuSources_value', 'r_exu_src_reg'),
                           ('useRegCache', 'r_use_rc_reg'),
                           ('regCacheIdx', 'r_rc_idx_reg')):
            gname = f'entryReg_status_srcStatus_{s}_{gsuf}'
            if gname not in regs:
                skipped.append(gname)
                continue
            w = regs[gname]
            if w == 1:
                pins.append((gname + '_reg', f'{isig}[{s}]'))
            else:
                for leaf, b in ref_bits(gname, w):
                    pins.append((leaf, f'{isig}[{s}][{b}]'))
        for q in range(v.ld_pipes):
            gname = f'entryReg_status_srcStatus_{s}_srcLoadDependency_{q}'
            if gname not in regs:
                skipped.append(gname)
                continue
            for leaf, b in ref_bits(gname, regs[gname]):
                pins.append((leaf, f'r_ld_dep_reg[{s}][{q}][{b}]'))
    # --- 本族专属：入队延迟窗口寄存器（golden 与核词干不同）---
    if 'enqDelayValidReg_last_REG' in regs:
        pins.append(('enqDelayValidReg_last_REG_reg', 'enqd_valid_reg_reg'))
    else:
        skipped.append('enqDelayValidReg_last_REG')
    return pins, skipped


HDR = """# {mod} FM 匹配前钉点 —— golden 逐字段寄存器 <-> 可读核的扁平负载向量与数组寄存器
# ============================================================================
# ★自动生成：verif/ut/{mod}/gen_fm_pins.py
#   （共享库 verif/ut/EnqEntry_common/gen_fm_pins.py）—— 勿手改★
#
# 为什么要钉：golden 把负载展平成逐字段寄存器，可读核存成一根向量，词干完全不同；
# OthersEntry lane 的未钉点首跑实测 FM 会把 golden 的 payload.psrc 配到可读核的
# status.psrc 上（Ref entryReg_payload_psrc_0_reg[b] <-> Impl u_entry/r_psrc_reg[0][b]）。
# EnqEntry 全族都存整包负载（KEEP_WIDE = IS_ENQ|IS_TRANS），所以每个变体都会踩。
#
# 钉的对应（只消名差，不 dont_verify、不黑盒、不约束 ref、不跳过任何比较点）：
#   entryReg_payload_<field>_reg[b] / entryReg_imm_reg[b]  <-> r_payload_reg[off+b]
#   entryReg_status_<f>                                    <-> r_<f>_reg
#   entryReg_status_srcStatus_<s>_<f>                      <-> r_<f>_reg[s][..]
#   enqDelayValidReg_last_REG                              <-> enqd_valid_reg
#
# ★ 钉点数不是证据 ★ set_user_match 对不存在的名字不抛异常，所以下面那个计数
#   只说明"没抛"。判钉点真的生效看 fm.log 三条：行首 Error 计数为 0 /
#   match 后 Unmatched 0(0) / 终判 SUCCEEDED 且 failing=0。
#
# 本文件钉 {npin} 对；golden 侧不存在（被 firtool DCE）因而跳过的 {nskip} 个列在文件尾。
# ============================================================================

if {{$top eq "{mod}"}} {{
  set _n 0
  set _miss 0
  foreach _pair {{
"""

FTR = """  }} {{
    lassign $_pair _r _i
    if {{[catch {{set_user_match "r:/WORK/$top/$_r" "i:/WORK/$top/u_entry/$_i"}} _msg]}} {{
      incr _miss
      if {{$_miss <= 10}} {{ puts "EE_PIN_FAIL: $_r <-> $_i ($_msg)" }}
    }} else {{
      incr _n
    }}
  }}
  puts "EE_PINS: $_n / {npin} tried, $_miss threw"
  # fail-closed 两道，都在最后一次 set_user_match **之后**：
  #   (1) 一次都不许抛；
  #   (2) 成功条数必须**恰好**等于生成时算出来的期望数量 —— set_user_match 对不存在的
  #       名字不抛异常（实测），所以只看"没抛"证明不了钉点真的都下去了；
  #       把期望数量写成字面整数钉死，少一条就 error。
  if {{$_miss != 0}} {{ error "EE_PIN_THREW=$_miss" }}
  if {{$_n != {npin}}} {{ error "EE_PIN_COUNT=$_n expected {npin}" }}
}}
"""


def gen(mod):
    ov = EnqVariant(mod)
    pins, skipped = build_pins(ov)
    out = [HDR.format(mod=mod, npin=len(pins), nskip=len(skipped))]
    for r, i in pins:
        out.append('    {%s %s}\n' % (r, i))
    out.append(FTR.format(npin=len(pins)))
    if skipped:
        out.append('\n# golden 侧不存在、因而未钉点的寄存器：\n')
        for s in skipped:
            out.append(f'#   {s}\n')
    return ''.join(out), len(pins), len(skipped)


def main(mod):
    txt, npin, nskip = gen(mod)
    p = REPO / 'verif' / 'ut' / mod / 'fm_pins_pre.tcl'
    if '--check' in sys.argv:
        if not p.exists() or p.read_text() != txt:
            print(f'DRIFT: {p}')
            return 1
        print(f'{p.name} 与 golden 一致（{npin} 对）')
        return 0
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(txt)
    print(f'wrote {p}  钉 {npin} 对，跳过 {nskip} 个')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
