#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""boundary_ledger.py —— 冻结台账的**两轴**（codex 0151 D59）。

## 为什么必须分两轴

"XSTop 下有多少个模块"这一个数字同时被两件事用着，而它们的口径不同：

  WORK_REACHABLE     XSTop 下**真实 elaborate 的设计定义**。主分母候选。
  FM_BBOX_REACHABLE  被当作黑盒的**边界定义**。它们没有被证明，只是被挡在了
                     证明之外。★不能把未知的 functional blackbox 从义务中消失★
                     —— 每一个都要有个去处：approved vendor / proven child / GAP。

把两轴混成一个数，结果就是"覆盖率"里悄悄含着一批从没被证过的东西。

## 第三轴（本脚本实测发现，D59 没写）

  BEHIND_BOUNDARY    静态例化图里从 XSTop 可达，但**只能经由某个黑盒父模块**到达，
                     于是 FM 的层次报告里根本没有它。

  实测：`sram_array_*`（黑盒）例化 `array_5`，`array_5` 例化 `array_5_ext`。
  FM 在 `sram_array_*` 就停了，`array_0..18` / `array_ext` / 多数 `array_*_ext`
  共 44 个定义因此完全不出现在 FM 报告里。它们**仍然是设计的一部分**，
  只是躲在边界后面。不单列出来，它们就会从两轴里一起消失 —— 正是 D59 要防的。

守恒：静态 XSTop 闭包 = WORK_REACHABLE + FM_BBOX_REACHABLE + BEHIND_BOUNDARY。
不守恒即非零退出。

## 分类判据

  APPROVED_VENDOR  名字在**已冻结 registry** `verif/vendor_boundary.tsv` 里
                   （精确匹配，不做前缀/通配 —— declare_allow.py 也是精确匹配）。
  PROVEN_CHILD     自己就是某份通过 receipt 的 top（docs/receipt_index.tsv，
                   非 provisional、canonical_id 对得上、verdict 通过）。
  GAP              以上都不是。★默认落到这里，沉默不等于批准★

## 退出码
  0 扫描完成（有 GAP 也算完成，GAP 是数据不是错误）
  1 守恒失败
  2 输入缺失 / 解析失败（fail-closed）
  3 `--fail-on-gap` 且存在 GAP
"""
from __future__ import print_function

import argparse
import collections
import hashlib
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import g1_slotmap as SM                                            # noqa: E402
import g1_configured_universe as GCU                               # noqa: E402

# 层次报告行：`<缩进><设计名>[ (N)] <库>`
_HIER = re.compile(r'^\s+([A-Za-z_]\w*)(?:\s+\((\d+)\))?\s+(WORK|FM_BBOX)\s*$')
# 工具内部件，不是设计定义
_TOOL = re.compile(r'^(M_RTL_|fm_internal_)')
# 报告抬头 / 分隔线 / 计数尾行，逐条列出——**不认识的行一律 fail-closed**
_SKIP = re.compile(r'^\s*(\*{5,}|_{5,}|-{5,}|\|)|^\s*(Report|Reference|Implementation|'
                   r'Version|Date|Design|Information|Legend)\b|^\s*\d+\s*$|'
                   r'^\s*Formality Primitives\b|'
                   # 抬头里 `Report : hierarchy` 的续行，形如 `    r:/WORK/XSTop`
                   r'^\s*[a-z]:/\S*\s*$')


def parse_hierarchy(path):
    """返回 (work_designs, bbox_designs)。看不懂的行 -> 抛异常（fail-closed）。"""
    work, bbox, unparsed = set(), set(), []
    for i, ln in enumerate(pathlib.Path(path).read_text(errors='replace').splitlines(), 1):
        if not ln.strip():
            continue
        m = _HIER.match(ln)
        if m:
            name, lib = m.group(1), m.group(3)
            if _TOOL.match(name):
                continue
            (work if lib == 'WORK' else bbox).add(name)
            continue
        # 顶层设计自己那行没有缩进
        m2 = re.match(r'^([A-Za-z_]\w*)\s+(WORK|FM_BBOX)\s*$', ln)
        if m2:
            (work if m2.group(2) == 'WORK' else bbox).add(m2.group(1))
            continue
        if _SKIP.search(ln):
            continue
        unparsed.append((i, ln))
    if unparsed:
        raise SM.InputError('层次报告有 %d 行看不懂（fail-closed，绝不静默跳过），'
                            '首条 %d: %r' % (len(unparsed), unparsed[0][0], unparsed[0][1]))
    if not work:
        raise SM.InputError('%s: 一个 WORK 设计都没解析出来（解析器坏了？）' % path)
    return work, bbox


def load_registry(repo):
    """verif/vendor_boundary.tsv —— 一次性人工审定并提交的厂商边界名单。"""
    p = pathlib.Path(repo) / 'verif' / 'vendor_boundary.tsv'
    if not p.exists():
        return set(), str(p), ''
    out = set()
    for ln in p.read_text().splitlines():
        if ln.startswith('#') or not ln.strip():
            continue
        out.add(ln.split('\t')[0])
    return out, str(p), hashlib.sha256(p.read_bytes()).hexdigest()[:16]


def load_proven(repo, canonical_id):
    p = pathlib.Path(repo) / 'docs' / 'receipt_index.tsv'
    out = set()
    if not p.exists():
        return out, False
    for ln in p.read_text().splitlines():
        if ln.startswith('#') or not ln.strip():
            continue
        c = ln.split('\t')
        if len(c) >= 7 and c[4] == 'false' and c[1] in ('SUCCEEDED', 'PASS_DEAD_REF'):
            if not canonical_id or c[2] == canonical_id:
                out.add(c[0])
    return out, True


def main(argv=None):
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--repo', default=str(os.environ.get('XSSV_HOME') or HERE.parent))
    ap.add_argument('--g1', default=SM.G1_DEFAULT)
    ap.add_argument('--root', default='XSTop')
    ap.add_argument('--hierarchy', default=None,
                    help='Formality `report_hierarchy` 输出。给了就用实测两轴并与静态'
                         '闭包对账；不给就只按静态闭包推导（provenance 列会注明）。')
    ap.add_argument('--canonical-id', default='/home/eda/xs-env/G1-canonical/CANONICAL_ID.txt')
    ap.add_argument('--out', default=None, help='默认 <repo>/docs/g1_boundary_ledger.tsv')
    ap.add_argument('--fail-on-gap', action='store_true')
    args = ap.parse_args(argv)
    repo = pathlib.Path(args.repo)
    out = pathlib.Path(args.out or (repo / 'docs' / 'g1_boundary_ledger.tsv'))

    try:
        g1 = SM.Baseline(args.g1, 'G1', include_v=True)
        closure = GCU.reachable(g1, args.root)
        cid = ''
        cp = pathlib.Path(args.canonical_id)
        if cp.exists():
            cid = cp.read_text().strip()
        registry, regpath, regsha = load_registry(repo)
        proven, have_ri = load_proven(repo, cid)
        if args.hierarchy:
            work, bbox = parse_hierarchy(args.hierarchy)
            hsha = hashlib.sha256(pathlib.Path(args.hierarchy).read_bytes()).hexdigest()[:16]
            prov = 'fm_hierarchy'
        else:
            bbox = set(n for n in closure if GCU.excluded(n))
            work = closure - bbox
            hsha, prov = '-', 'static_only'
    except (SM.InputError, IOError, OSError) as e:
        sys.stderr.write('INPUT/PARSE ERROR (fail-closed): %s\n' % e)
        return 2

    behind = sorted(closure - work - bbox)
    ghost = sorted((work | bbox) - closure)          # FM 见到、静态闭包里没有

    def classify(n):
        if n in registry:
            return 'APPROVED_VENDOR', '在已冻结 registry %s 内' % regpath
        if n in proven:
            return 'PROVEN_CHILD', '自己是通过 receipt 的 top（docs/receipt_index.tsv）'
        return 'GAP', ('未经 %s 批准，也不是任何通过 receipt 的 top —— '
                       '★仍在可读 RTL 义务内★' % regpath)

    lines = [
        '# G1 冻结台账 · 两轴（scripts/boundary_ledger.py 生成；禁止手工编辑）',
        '# root=%s  静态闭包=%d  WORK_REACHABLE=%d  FM_BBOX_REACHABLE=%d  '
        'BEHIND_BOUNDARY=%d' % (args.root, len(closure), len(work & closure),
                                len(bbox & closure), len(behind)),
        '# provenance=%s  hierarchy_sha256=%s  registry=%s  registry_sha256=%s'
        % (prov, hsha, regpath, regsha or '(缺)'),
        '# receipt_index 可用=%s（缺失时 PROVEN_CHILD 恒为空，GAP 会偏多，'
        '不得当作结论）' % ('是' if have_ri else '否'),
        '#',
        '# axis 取值：',
        '#   WORK_REACHABLE     XSTop 下真实 elaborate 的设计定义（主分母候选）',
        '#   FM_BBOX_REACHABLE  黑盒边界定义 —— 逐个定性，GAP 不得消失',
        '#   BEHIND_BOUNDARY    只能经由黑盒父模块到达，FM 层次报告里没有它',
        '# class 取值：DESIGN / APPROVED_VENDOR / PROVEN_CHILD / GAP',
        '# axis\tname\tclass\tdef_file\tnote',
    ]
    counts = collections.Counter()
    for n in sorted(work & closure):
        lines.append('WORK_REACHABLE\t%s\tDESIGN\t%s\t' % (n, g1.deffile.get(n, '-')))
        counts[('WORK_REACHABLE', 'DESIGN')] += 1
    gaps = []
    for axis, names in (('FM_BBOX_REACHABLE', sorted(bbox & closure)),
                        ('BEHIND_BOUNDARY', behind)):
        for n in names:
            cls, why = classify(n)
            lines.append('%s\t%s\t%s\t%s\t%s' % (axis, n, cls, g1.deffile.get(n, '-'), why))
            counts[(axis, cls)] += 1
            if cls == 'GAP':
                gaps.append((axis, n))
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text('\n'.join(lines) + '\n')

    print('# boundary_ledger  root=%s  provenance=%s' % (args.root, prov))
    print('静态 XSTop 闭包 = %d' % len(closure))
    for k in sorted(counts):
        print('  %-20s %-16s %d' % (k[0], k[1], counts[k]))
    total = sum(counts.values())
    ok = total == len(closure) and not ghost
    print('守恒: %d(WORK) + %d(BBOX) + %d(BEHIND) = %d %s 静态闭包 %d'
          % (len(work & closure), len(bbox & closure), len(behind), total,
             '==' if total == len(closure) else '★!=★', len(closure)))
    if ghost:
        print('★FM 报告里有 %d 个设计不在静态闭包内（静态例化图漏解析？）: %s'
              % (len(ghost), ' '.join(ghost[:8])))
    n_gap = len(gaps)
    print('★GAP（未获批准、未被证明的边界定义）= %d' % n_gap)
    for axis, n in gaps[:12]:
        print('    %s  %s' % (axis, n))
    if n_gap > 12:
        print('    …共 %d 个，全表见 %s' % (n_gap, out))
    print('-> %s' % out)
    if not ok:
        return 1
    if args.fail_on_gap and n_gap:
        return 3
    return 0


if __name__ == '__main__':
    sys.exit(main())
