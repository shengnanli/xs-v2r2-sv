#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""prev_round_verbatim_scan.py —— 上一轮（xs-v2r2-sv，对 G0 全签的那一轮）
「真逻辑行逐字来自 golden」全仓扫描。

## 为什么这条属于 ordered classifier 的任务范围

codex 0148：classifier「只作调度，不继承 PASS」。可如果上一轮有一批目标其实是
**照抄 golden** 而不是重写，那它们的「已签核」就不能作为本轮任何判断的输入 ——
本轮的 `A_BODY_IDENTICAL` / `D_DEPRENUM` / `C_ALPHA_RENAME` 三档给出的是
「可以继承上一轮的**施工**」，一旦上一轮那份施工本身是照抄，这个继承就是把
照抄搬到本轮来。所以分类结论必须知道哪些目标处在这个名单上。

## 判据（**与 scripts/readability_audit.py 的 G 类完全同一套，一个字没改**）

`_STRUCTURAL` / `_PORTLINE` / `_codelines` / 最小 60 行 / 阈值 0.45 全部取自
`readability_audit.py@c922636`。「真逻辑行」= 去注释、去空行，并排除：
端口表、实例连线 `.io_x (y),`、例化头 `Foo bar (`、收尾 `);`、纯声明、括号/块关键字。
这些与 golden 逐字相同是**规范要求或结构必然**（端口名由 golden 定），不算照抄逻辑。

## 与 G 类的**唯一**差别：golden 对应文件怎么找 —— 这是一处 fail-open 的修补

`readability_audit.py` 的 G 类用 `GOLDEN / p.name` 找 golden 对应文件。
上一轮 `xs-v2r2-sv/rtl/` 是**两文件布局**：`Predictor.sv`（可读核）+
`Predictor_wrapper.sv`（golden 形状的壳）。而 golden 里只有 `Predictor.sv`，
**没有** `Predictor_wrapper.sv` —— 于是 `golden_overlap()` 返回 `None`，
所有 `*_wrapper.sv` 被**静默跳过**。而 `_wrapper.sv` 恰恰就是要查的那一批。

本脚本改成按**文件里声明的模块名**找 golden：
  1. 解析 impl 文件里所有 `module <Name>`；
  2. golden 集合 = 这些名字在 golden 里存在的同名文件；
  3. 都找不到 -> 退回文件名去掉 `_wrapper` / `_core` / `_pkg` 后缀再找；
  4. 仍找不到 -> 记 `NO_GOLDEN_COUNTERPART`，**列出来，不静默跳过**
     （静默跳过正是上面那处 fail-open 的成因）。

两个口径都算，都进 TSV：
  `rate_named` —— 只跟「主模块」（文件名去壳后缀 / 第一个 golden 命中）比，
                  与 readability_audit G 类的口径最接近；
  `rate_union` —— 跟本文件声明的**全部**模块对应的 golden 文件并集比。
     单文件规范下一个 impl 文件常同时含 core + wrapper + pkg，
     只跟单个 golden 文件比会低估。判定用 `rate_union`（更保守地更容易命中），
     `rate_named` 同时列出来供复算。

## 用法

    python3 scripts/prev_round_verbatim_scan.py \
        --impl-root /home/eda/xs-env/xs-v2r2-sv/rtl \
        --golden /home/eda/xs-env/G0-canonical/golden-rtl \
        --threshold 0.45 --tsv docs/prev_round_verbatim.tsv

退出码 0 = 扫完（有命中也算扫完，命中是数据不是错误）；2 = 环境错误。
"""
import argparse
import collections
import hashlib
import json
import os
import pathlib
import re
import sys

# ---- 以下四段与 readability_audit.py@c922636 逐字相同（判据必须同一套）----
FORBIDDEN = re.compile(r'\b_(GEN|T)(_\d+)?\b')
MOD_RE = re.compile(r'^(package|module)\s+(\w+)', re.MULTILINE)
_PORTLINE = re.compile(r'^\s*(input|output|inout)\b')
_STRUCTURAL = re.compile(
    r'^(\.\w+'
    r'|\)\s*\w*\s*;?$'
    r'|(wire|logic|reg|localparam|parameter|genvar|typedef|import|package|endpackage)\b'
    r'|[A-Za-z_]\w*(\s*#\s*\(.*)?\s+\w+\s*\($'
    r'|(begin|end|endmodule|endcase|endgenerate|endfunction|else)\b'
    r'|module\s+\w+'
    r'|\{|\}|,$)')


def strip_comments(text):
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    return re.sub(r'//[^\n]*', '', text)


def codelines(text, drop_ports=True):
    out = []
    for ln in strip_comments(text).splitlines():
        s = ln.rstrip()
        if not s.strip():
            continue
        if drop_ports and (_PORTLINE.match(s) or _STRUCTURAL.match(s.strip())):
            continue
        out.append(s.strip())
    return out
# ---- 判据引用结束 ---------------------------------------------------------


_SHELL_SUFFIX = re.compile(r'_(wrapper|core|pkg|inst|decls|body)$')

# ---- 逐字重合行的**分类**（新增的证据列；**不改判定阈值**）-----------------
# 为什么要分类：45% 阈值本身不动（那是 coordinator 定的），但命中里混着两类东西，
# 施工含义完全相反，混在一起报会误导：
#   concat_elem  —— 整行只是一个标识符（可带尾逗号），是 `assign valids = {`
#                   多行拼接里的一个元素。两侧列的是同一批端口名，**逐字相同是必然**。
#                   实证：uncore/FastArbiter_29.sv 91.2% 里 146 条重合几乎全是这一类。
#   const_tieoff —— `assign io_x = <常量>;`。golden 形状的壳必须把这些输出钉成同一个
#                   常量，**逐字相同也是必然**。实证：backend/BranchUnit_wrapper.sv
#                   76/76 重合全部是这一类。
#   passthrough  —— `assign io_a = io_b;` 纯直通。P_SHIM 形态的模块整个模块体就是这个，
#                   与 golden 逐字相同**同样是必然**（端口名两侧一致，直通没有第二种写法）。
#                   实证：uncore/CHILogger.sv 32/32、TLLogger.sv 53/53 全是这一类。
#   inst_conn_val —— 例化连线被折行后**只剩连接值**的那一行（`(auto_xxx),`）。
#                   `_STRUCTURAL` 只丢以 `.` 开头的连线行，折行后的值行漏了下来。
#                   实证：uncore/DebugModule.sv 94.1% 几乎全是这一类。
#   substantive  —— 其余。这才是「照抄逻辑」。实证：frontend/Predictor_wrapper.sv
#                   36552 条重合里 23921 条属这一类，且代码区有 617 处 `_GEN_/_T_`。
_CONCAT_ELEM = re.compile(r'^[A-Za-z_]\w*(\s*\[[^\]]*\])?\s*,?$')
_CONST_TIEOFF = re.compile(
    r"^assign\s+[A-Za-z_]\w*(\s*\[[^\]]*\])?\s*=\s*"
    r"(\d[\d_]*'[sS]?[bodhBODH][0-9a-fA-FxXzZ_]+|\d+|1'h0|1'h1)\s*;$")


_PASSTHRU = re.compile(r'^assign\s+[A-Za-z_]\w*\s*=\s*[A-Za-z_]\w*\s*;$')
_INST_CONN_VAL = re.compile(r'^\(\s*[A-Za-z_]\w*(\s*\[[^\]]*\])?\s*\)\s*,?$')


def classify_line(l):
    if _CONCAT_ELEM.match(l):
        return 'concat_elem'
    if _CONST_TIEOFF.match(l):
        return 'const_tieoff'
    if _PASSTHRU.match(l):
        return 'passthrough'
    if _INST_CONN_VAL.match(l):
        return 'inst_conn_val'
    return 'substantive'



def golden_candidates(path, text, golden_dir):
    """本文件对应哪些 golden 文件。返回 (主 golden 文件, 全部 golden 文件列表)。"""
    names = [m.group(2) for m in MOD_RE.finditer(strip_comments(text))]
    hits = []
    for n in names:
        f = golden_dir / ('%s.sv' % n)
        if f.exists() and f not in hits:
            hits.append(f)
    stem = path.stem
    primary = None
    for cand in (stem, _SHELL_SUFFIX.sub('', stem)):
        f = golden_dir / ('%s.sv' % cand)
        if f.exists():
            primary = f
            if f not in hits:
                hits.append(f)
            break
    if primary is None and hits:
        primary = hits[0]
    return primary, hits


def scan(impl_root, golden_dir, min_lines=60):
    rows = []
    for p in sorted(pathlib.Path(impl_root).rglob('*.sv')):
        text = p.read_text(errors='replace')
        impl = codelines(text)
        code = strip_comments(text)
        a_hits = len(FORBIDDEN.findall(code))
        primary, allg = golden_candidates(p, text, pathlib.Path(golden_dir))
        row = {
            'file': str(p),
            'rel': str(p.relative_to(impl_root)),
            'total_lines': len(text.splitlines()),
            'code_lines': len(impl),
            'a_class_hits': a_hits,
            'golden_primary': primary.name if primary else '',
            'golden_n': len(allg),
            'golden_all': ';'.join(f.name for f in allg[:6]),
        }
        if len(impl) < min_lines:
            row.update(verdict='SKIP_TOO_SMALL', verbatim_named=0, rate_named='',
                       verbatim_union=0, rate_union='', v_substantive=0,
                       rate_substantive='', v_concat_elem=0, v_const_tieoff=0,
                       v_passthrough=0, v_inst_conn_val=0)
            rows.append(row)
            continue
        if not allg:
            row.update(verdict='NO_GOLDEN_COUNTERPART', verbatim_named=0,
                       rate_named='', verbatim_union=0, rate_union='', v_substantive=0,
                       rate_substantive='', v_concat_elem=0, v_const_tieoff=0,
                       v_passthrough=0, v_inst_conn_val=0)
            rows.append(row)
            continue
        gset_named = _gold(primary) if primary else set()
        gset_union = set()
        for f in allg:
            gset_union |= _gold(f)
        vn = sum(1 for l in impl if l in gset_named)
        hits = [l for l in impl if l in gset_union]
        kinds = collections.Counter(classify_line(l) for l in hits)
        subst = kinds['substantive']
        row.update(verbatim_named=vn, rate_named=round(vn / len(impl), 4),
                   verbatim_union=len(hits), rate_union=round(len(hits) / len(impl), 4),
                   v_substantive=subst,
                   rate_substantive=round(subst / len(impl), 4),
                   v_concat_elem=kinds['concat_elem'],
                   v_const_tieoff=kinds['const_tieoff'],
                   v_passthrough=kinds['passthrough'],
                   v_inst_conn_val=kinds['inst_conn_val'],
                   verdict='SCANNED')
        rows.append(row)
    return rows


_GCACHE = {}


def _gold(f):
    k = str(f)
    if k not in _GCACHE:
        _GCACHE[k] = set(codelines(f.read_text(errors='replace')))
    return _GCACHE[k]


def load_ledger_status(paths):
    """target -> 台账终态。多个台账取先出现的（口径见调用处）。"""
    out = {}
    for p in paths:
        p = pathlib.Path(p)
        if not p.exists():
            continue
        for line in p.read_text(encoding='utf-8', errors='replace').splitlines():
            if line.startswith('#') or not line.strip():
                continue
            c = line.split('\t')
            # g1_universe.tsv: old_target g1_name resolve delta_class status note
            # ledger_normalized.tsv: target bucket status note
            st = c[4] if len(c) >= 6 else (c[2] if len(c) >= 4 else '')
            if c[0] not in out and st:
                out[c[0]] = st
    return out


def annotate_ledger(rows, golden_dir, status):
    """给每行标上它涉及的 target 与台账终态。target = 本文件声明的、
    在 golden 里存在的模块名；再补上按文件名去壳后缀找到的主 golden 模块。"""
    gd = pathlib.Path(golden_dir)
    for r in rows:
        p = pathlib.Path(r['file'])
        names = [m.group(2) for m in MOD_RE.finditer(strip_comments(
            p.read_text(errors='replace')))]
        tg = [n for n in dict.fromkeys(names) if (gd / ('%s.sv' % n)).exists()]
        prim = r.get('golden_primary', '')
        if prim.endswith('.sv') and prim[:-3] not in tg:
            tg.insert(0, prim[:-3])
        r['targets'] = ';'.join(tg[:8])
        r['ledger_status'] = ';'.join('%s=%s' % (n, status.get(n, 'NOT_IN_LEDGER'))
                                      for n in tg[:8])
        r['any_pass'] = 'yes' if any('PASS' in status.get(n, '') for n in tg) else 'no'


COLS = ['rel', 'verdict', 'total_lines', 'code_lines', 'verbatim_union', 'rate_union',
        'v_substantive', 'rate_substantive', 'v_concat_elem', 'v_const_tieoff',
        'v_passthrough', 'v_inst_conn_val',
        'verbatim_named', 'rate_named', 'a_class_hits', 'golden_primary', 'golden_n',
        'golden_all', 'targets', 'ledger_status', 'any_pass', 'file']


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('--impl-root', default='/home/eda/xs-env/xs-v2r2-sv/rtl')
    ap.add_argument('--golden', default='/home/eda/xs-env/G0-canonical/golden-rtl')
    ap.add_argument('--threshold', type=float,
                    default=float(os.environ.get('XSSV_OVERLAP_LIMIT', '0.45')))
    ap.add_argument('--min-lines', type=int, default=60)
    ap.add_argument('--tsv')
    ap.add_argument('--manifest')
    ap.add_argument('--ledger', action='append', default=[],
                    help='台账 TSV（可给多次）；给了就把每个文件对应的 target 终态标出来，'
                         '并单列「命中文件里有多少对应着已标 PASS 的 target」')
    a = ap.parse_args(argv)
    for d in (a.impl_root, a.golden):
        if not os.path.isdir(d):
            print('ERROR: 目录不存在 %s' % d, file=sys.stderr)
            return 2

    rows = scan(a.impl_root, a.golden, a.min_lines)
    status = load_ledger_status(a.ledger) if a.ledger else {}
    annotate_ledger(rows, a.golden, status)
    rows.sort(key=lambda r: (-(r['rate_union'] or 0), r['rel']))
    tsv = '\t'.join(COLS) + '\n' + '\n'.join(
        '\t'.join(str(r.get(c, '')) for c in COLS) for r in rows) + '\n'
    if a.tsv:
        pathlib.Path(a.tsv).parent.mkdir(parents=True, exist_ok=True)
        pathlib.Path(a.tsv).write_text(tsv)
        print('wrote %s' % a.tsv)

    hit = [r for r in rows if r['verdict'] == 'SCANNED' and r['rate_union'] > a.threshold]
    cnt = collections.Counter(r['verdict'] for r in rows)
    print('# 扫描 %d 个 .sv：%s' % (len(rows), dict(cnt)))
    print('# 阈值 %.2f，命中 %d 个' % (a.threshold, len(hit)))
    print('%-50s %6s %6s %7s %7s %7s %6s %5s'
          % ('file', 'lines', 'code', 'union%', '实质%', '实质行', '必然', 'A类'))
    for r in hit:
        print('%-50s %6d %6d %7.1f %7.1f %7d %6d %5d'
              % (r['rel'], r['total_lines'], r['code_lines'], 100 * r['rate_union'],
                 100 * r['rate_substantive'], r['v_substantive'],
                 r['v_concat_elem'] + r['v_const_tieoff'] + r['v_passthrough']
                 + r['v_inst_conn_val'], r['a_class_hits']))
    if a.ledger:
        npass = sum(1 for r in hit if r['any_pass'] == 'yes')
        print('\n# 台账对账（台账: %s）' % ', '.join(a.ledger))
        print('#   命中文件里，对应 target **已标 PASS** 的: %d / %d' % (npass, len(hit)))
        for r in hit:
            if r['any_pass'] == 'yes':
                print('   %-46s %s' % (r['rel'], r['ledger_status'][:120]))
        # 反方向：已标 PASS 的 target，其上一轮实现文件的重合率分布
        bytarget = {}
        for r in rows:
            if r['verdict'] != 'SCANNED':
                continue
            for n in (r['targets'] or '').split(';'):
                if n and 'PASS' in status.get(n, ''):
                    cur = bytarget.get(n)
                    if cur is None or r['rate_union'] > cur['rate_union']:
                        bytarget[n] = r
        npt = sum(1 for n, st in status.items() if 'PASS' in st)
        over = sorted(((n, r) for n, r in bytarget.items()
                       if r['rate_union'] > a.threshold),
                      key=lambda x: -x[1]['rate_union'])
        print('#   反向：台账 PASS 的 target 共 %d 个，其中在本次扫描里可比的 %d 个，'
              '超阈值 %d 个' % (npt, len(bytarget), len(over)))
        for n, r in over:
            print('   %-28s %-44s union=%.1f%% 实质=%.1f%%'
                  % (n, r['rel'], 100 * r['rate_union'], 100 * r['rate_substantive']))

    # ---- codex 0150 D56 名单 -------------------------------------------
    # D56：任何**逻辑正文**从 G0 逐字复制的目标，不得计为「可读重写完成」，
    # 即便 FM 通过；必须重写或显式留 gap。
    # 「逻辑正文」= 本脚本的 substantive 类：已剔除结构上必然重合的四类
    # （拼接元素 / 常量钉死 / 纯 io->io 直通 / 折行后的例化连接值）。
    d56 = [r for r in rows if r['verdict'] == 'SCANNED'
           and r['rate_substantive'] > a.threshold]
    d56.sort(key=lambda r: -r['v_substantive'])
    print('\n# codex 0150 D56 名单：逻辑正文逐字重合 > %.0f%% 的文件（%d 个）'
          % (100 * a.threshold, len(d56)))
    print('#   （union%% 列里那些「必然重合」的已经扣掉；扣完仍超阈值才进本名单）')
    print('%-48s %7s %8s %7s %6s  %s'
          % ('file', '实质行', '实质%', 'union%', 'A类', 'target -> 台账'))
    for r in d56:
        print('%-48s %7d %7.1f%% %6.1f%% %6d  %s'
              % (r['rel'], r['v_substantive'], 100 * r['rate_substantive'],
                 100 * r['rate_union'], r['a_class_hits'],
                 (r.get('ledger_status') or r.get('targets') or '')[:80]))
    borderline = [r for r in rows if r['verdict'] == 'SCANNED'
                  and r['rate_union'] > a.threshold
                  and r['rate_substantive'] <= a.threshold]
    if borderline:
        print('\n# 只在 union 口径超阈值、扣掉「结构上必然重合」后不超的（%d 个，'
              '**不**进 D56 名单）:' % len(borderline))
        for r in borderline:
            print('   %-46s union=%.1f%% 实质=%.1f%%（实质行仅 %d）'
                  % (r['rel'], 100 * r['rate_union'],
                     100 * r['rate_substantive'], r['v_substantive']))

    ng = [r for r in rows if r['verdict'] == 'NO_GOLDEN_COUNTERPART']
    if ng:
        print('\n# 找不到 golden 对应文件（**列出来，不静默跳过**）: %d 个' % len(ng))
        for r in ng[:20]:
            print('   %s' % r['rel'])
    if a.manifest:
        pathlib.Path(a.manifest).write_text(json.dumps({
            'impl_root': a.impl_root, 'golden': a.golden,
            'threshold': a.threshold, 'min_lines': a.min_lines,
            'n_files': len(rows), 'n_hit': len(hit),
            'verdicts': dict(cnt),
            'tsv_sha256': hashlib.sha256(tsv.encode()).hexdigest(),
            'script_sha256': hashlib.sha256(
                pathlib.Path(__file__).read_bytes()).hexdigest(),
            'criteria_from': 'scripts/readability_audit.py@c922636 G 类（逐字复用）',
            'rerun': ('python3 scripts/prev_round_verbatim_scan.py --impl-root %s '
                      '--golden %s --threshold %s --tsv %s'
                      % (a.impl_root, a.golden, a.threshold, a.tsv)),
        }, indent=2, ensure_ascii=False))
        print('wrote %s' % a.manifest)
    return 0


if __name__ == '__main__':
    sys.exit(main())
