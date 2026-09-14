#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""hier_map.py —— golden 层次路径 → 重写层次路径 的重绑映射表（可复算）。

## 为什么需要它

重写模块与 golden 逐位等价，但**层次不等价**：

  * 每个重写模块都是「golden 同名 wrapper + 一层 `u_core` 可读核」，于是
    `P/child` 变成 `P/u_core/…/child`；
  * 可读核把 golden 的扁平重复例化收成 generate-for，于是
    `qs_queue_37` 变成 `g_qs[37].qs`；
  * 一部分 golden 子模块被**吸收**进可读核（TLPLIC 直接例化
    `xs_LevelGateway_core`，Alu 把 AluDataModule 整棵内联成组合逻辑），
    于是那个 golden 模块在 XSTop 可达闭包里一个实例都没有。

任何按**实例路径**工作的外部流程（波形探针、force/deposit、bind、
故障注入 scope、memory campaign 的阵列路径）都需要一张
`golden 路径 → 重写路径` 的对照表。本脚本就是那张表的生成器。

## 三层来源（机器优先，人工兜底）

  1. `SAME_PATH`   impl 侧同一层还有同名实例（只是模块类型可能换成了 `xs_*_core`）；
  2. `DEEPER`      同名实例还在，只是被 `u_core` 之类的可读核层包了一层；
  3. `GEN_SITE` / `ONE_SITE`
                   实例名没了，但 impl 侧该父模块下**只有一个** generate 例化点
                   （或只有一个同类型例化点）用的正是这个 golden 子模块类型；
  4. `DECLARED`    以上都判不准（类型也换了 / 彻底内联成信号）——
                   逐条写在 `docs/hier_rebind_decl.tsv`，本脚本校验其真实性。

判不出来且没声明的，一律写 `UNRESOLVED`，**不猜**。

## 产物

  docs/hier_rebind_map.tsv        逐 golden 实例槽位一行
  docs/hier_unreachable.tsv       在 golden XSTop 闭包里、在 impl XSTop 闭包里没了的模块

## 幂等

  python3 scripts/hier_map.py --check    重算并逐字节比对，漂了就非零退出
"""
from __future__ import print_function

import argparse
import collections
import difflib
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
sys.path.insert(0, str(HERE))
import hier_reach as HR                                             # noqa: E402
import g1_slotmap as SM                                             # noqa: E402

GOLDEN_DEFAULT = '/home/eda/xs-env/G1-canonical/golden-rtl'
DECL = REPO / 'docs' / 'hier_rebind_decl.tsv'
MAP_OUT = REPO / 'docs' / 'hier_rebind_map.tsv'
UNREACH_OUT = REPO / 'docs' / 'hier_unreachable.tsv'

MAP_HDR = [
    '# hier_rebind_map.tsv —— golden 实例路径 → 重写实例路径（scripts/hier_map.py 生成；禁止手改）',
    '# 每行 = golden 侧一个例化槽位。路径都相对 owner（= golden 同名的重写模块），',
    '# 消费方用法：把 `<...>/<owner 实例>/<golden_path>` 换成 `<...>/<owner 实例>/<impl_path>`。',
    '# class: SAME_PATH 同层同名 / DEEPER 同名但更深 / GEN_SITE generate 化 /',
    '#        GEN_SITE_UNINDEXED generate 化但下标对应关系未确立（须人工核对）/\n#        ONE_SITE 改名但唯一对应 / INSTANCE 声明的实例对应 /',
    '#        INLINE 内联成信号 / INLINE_REG_ARRAY 内联成寄存器阵列 /\n#        INLINE_DESCENDANT 父层次内联后随之消失的后代 / UNRESOLVED 判不准',
    '# resolve: auto_* = 机器判定；declared = docs/hier_rebind_decl.tsv',
    '# ★ impl_module 与 golden_child 不同 = 模块类型也换了（路径没变也要注意）★',
]
MAP_COLS = ['owner', 'golden_path', 'golden_child', 'class', 'impl_path',
            'impl_module', 'impl_signals', 'resolve', 'evidence']

UNREACH_HDR = [
    '# hier_unreachable.tsv —— 在 golden XSTop 例化闭包里、在「重写件优先」的 XSTop',
    '# 闭包里**一个实例都没有**的模块（scripts/hier_map.py 生成；禁止手改）。',
    '# kind: SIGNED_OFF_TARGET = 它本身就是一个重写签核目标（重写了，却没人例化）',
    '#       GOLDEN_ONLY       = 只是 golden 的子模块，被重写父模块吸收掉',
    '# cause: ABSORBED_DIRECT  = 它的 golden 父模块在 impl 侧还在，是那个父模块吸收了它',
    '#        ABSORBED_COLLATERAL = 它的 golden 父模块自己先没了，它是被连带带走的',
]
UNREACH_COLS = ['module', 'kind', 'cause', 'golden_parents', 'golden_sites', 'impl_owner', 'impl_file']

IDX = re.compile(r'\[[^\]]*\]')


def norm_path(p):
    """把下标内容抹掉：`g_bank[3].dataBank` 与 `g_bank[b].dataBank` 视为同一个例化点。"""
    return IDX.sub('[]', p)


def suffix_index(inst, family):
    """firtool 的 Vec 命名：`base`,`base_1`,`base_2`… 或 `base_0`,`base_1`…

    只有整个族**连号完整**时才给答案（缺号 = 我们对这个族的理解不对，宁可不给）。
    """
    if not family or len(family) < 2:
        return None
    m = re.fullmatch(r'(.*?)(?:_(\d+))?', inst)
    base = m.group(1)
    idx = int(m.group(2)) if m.group(2) is not None else 0
    got = {}
    for x in family:
        mm = re.fullmatch(re.escape(base) + r'(?:_(\d+))?', x)
        if not mm:
            return None
        got[int(mm.group(1)) if mm.group(1) is not None else 0] = x
    if sorted(got) != list(range(len(family))):
        return None
    return idx


def load_decl(path=DECL):
    rows = []
    for ln in pathlib.Path(path).read_text().splitlines():
        if not ln.strip() or ln.startswith('#'):
            continue
        f = ln.split('\t')
        if f[0] == 'owner':
            continue
        if len(f) != 8:
            raise SystemExit('hier_map: decl 行列数应为 8，实为 %d: %s' % (len(f), ln[:80]))
        rows.append(dict(zip(['owner', 'golden_child', 'golden_inst_re', 'impl_path',
                              'impl_module', 'kind', 'signals', 'evidence'], f)))
    return rows


def subst_index(tmpl, *idx):
    """下标代入：`{i}` = 正则第 1 个捕获组，`{j}` = 第 2 个，支持 `{i+2}` 这种偏移。

      subst_index('g_entry[{i+2}].u_e', 3)                -> 'g_entry[5].u_e'
      subst_index('g_wb_bank[{i}].g_wb_br[{j}].wb', 2, 1) -> 'g_wb_bank[2].g_wb_br[1].wb'
    """
    names = {'i': 0, 'j': 1}

    def rep(m):
        expr = m.group(1)
        mm = re.fullmatch(r'([ij])(?:\+(\d+))?', expr)
        if not mm or names[mm.group(1)] >= len(idx):
            raise SystemExit('hier_map: 不认识的下标表达式 {%s}（给了 %d 个捕获组）'
                             % (expr, len(idx)))
        return str(idx[names[mm.group(1)]] + int(mm.group(2) or 0))
    return re.sub(r'\{([^}]*)\}', rep, tmpl)


class Model(object):
    def __init__(self, golden, filelist, top='XSTop'):
        self.g1 = SM.Baseline(golden, 'G1', include_v=True)
        files = HR.load_filelist(filelist)
        self.defs, self.kids = HR.build(files, REPO)
        self.reach = HR.reachable(self.kids, self.defs, top)
        rtl = str((REPO / 'rtl').resolve())
        self.impl_defs = {k for k, v in self.defs.items() if v.startswith(rtl)}
        self.rewritten = sorted(self.impl_defs & set(self.g1.ports))
        # golden XSTop 闭包
        seen, st = set(), [top]
        while st:
            m = st.pop()
            if m in seen:
                continue
            seen.add(m)
            for ty, _i in self.g1.kids.get(m, ()):
                if ty in self.g1.ports and ty not in seen:
                    st.append(ty)
        self.g_reach = seen
        self.lost = sorted(seen - self.reach)
        self._flat = {}

    def flat(self, M, prefix='', depth=0, seen=()):
        """展开 impl 侧 M 内部的 `xs_*` 可读核层，给出 (相对路径, 模块) 列表。"""
        key = (M, prefix, depth)
        if key in self._flat:
            return self._flat[key]
        out = []
        for ty, _inst, hp in self.kids.get(M, ()):
            out.append((prefix + hp, ty))
            if depth < 3 and ty.startswith('xs_') and ty not in seen:
                out += self.flat(ty, prefix + hp + '.', depth + 1, seen + (ty,))
        self._flat[key] = out
        return out

    def auto(self, impl_module, inst, gtype, family=None):
        """机器判定：同层同名 → 更深同名 → 唯一 generate 点 → 唯一同类型点。

        `family` = 该 golden 父模块下同类型实例名的集合。当 impl 侧只有**一个**
        generate 例化点、且只有**一层**下标、且 golden 实例族是 firtool 的
        连号形态（`base`,`base_1`,… 或 `base_0`,`base_1`,…）时，把下标直接填成
        编号后缀（firtool 的 Vec 命名约定）。两层以上下标（如
        `bank_wrbypasses_2_1` 对 `g_wb_bank[gb].g_wb_br[gp]`）**不猜拆分**，
        原样留 genvar 并标 GEN_SITE_UNINDEXED。
        """
        lvl0 = {i: (hp, ty) for ty, i, hp in self.kids.get(impl_module, ())}
        if inst in lvl0:
            hp, ty = lvl0[inst]
            return ('SAME_PATH', hp, ty, 'auto_same')
        f = self.flat(impl_module)
        deep = [(p, t) for p, t in f if p.split('.')[-1] == inst]
        if len(deep) == 1:
            return ('DEEPER', deep[0][0], deep[0][1], 'auto_deeper')
        cands = [(p, t) for p, t in f if t == gtype]
        gen = [c for c in cands if '[' in c[0]]
        if len(gen) == 1:
            path, ty = gen[0]
            idx = suffix_index(inst, family)
            if path.count('[') == 1 and idx is not None:
                return ('GEN_SITE', IDX.sub('[%d]' % idx, path), ty, 'auto_gen_site_suffix')
            return ('GEN_SITE_UNINDEXED', path, ty, 'auto_gen_site')
        if len(cands) == 1:
            return ('ONE_SITE', cands[0][0], cands[0][1], 'auto_one_site')
        return None


def build_rows(M, decl):
    dmap = collections.defaultdict(list)
    for d in decl:
        dmap[(d['owner'], d['golden_child'])].append(d)
    used = set()
    rows = []

    def emit(owner, gpath, gchild, cls, ipath, imod, sig, resolve, ev):
        rows.append(dict(owner=owner, golden_path=gpath, golden_child=gchild,
                         **{'class': cls}, impl_path=ipath, impl_module=imod,
                         impl_signals=sig, resolve=resolve, evidence=ev))

    def walk(owner, gmod, gprefix, imod, iprefix, depth):
        if depth > 4:
            return
        fam = collections.defaultdict(list)
        for ty, i in M.g1.kids.get(gmod, ()):
            fam[ty].append(i)
        for gty, ginst in sorted(M.g1.kids.get(gmod, ()), key=lambda x: (x[1], x[0])):
            gpath = (gprefix + '/' + ginst) if gprefix else ginst
            # ★声明优先★：机器判定给 GEN_SITE_UNINDEXED（找到了 generate 点但
            # 拆不出下标）时，人工声明正是用来补那一步的；若让 auto 先赢，声明会
            # 永远匹配不到，被「陈旧声明」检查误杀。声明本身的真实性由
            # check_decl_at_use + 「必须匹配到真实槽位」两道检查守着。
            hit = None
            for d in dmap.get((gmod, gty), ()):
                m = re.fullmatch(d['golden_inst_re'], ginst)
                if m:
                    hit = (d, tuple(int(g) if g else 0 for g in m.groups()) or (0,))
                    break
            if hit:
                d, idx = hit
                used.add(id(d))
                ipath = subst_index(d['impl_path'], *idx)
                check_decl_at_use(M, d, ipath, imod)
                full = (iprefix + '.' + ipath) if iprefix else ipath
                emit(owner, gpath, gty, d['kind'], full, d['impl_module'],
                     d['signals'], 'declared', d['evidence'])
                if gty in M.lostset and gty in M.g1.kids:
                    if d['kind'] == 'INSTANCE':
                        walk(owner, gty, gpath, d['impl_module'], full, depth + 1)
                    else:
                        # 内联：整棵子树都落在同一个可读核里，逐个如实记下来，
                        # 不留 UNRESOLVED（它们不是「判不准」，是「确定地不存在了」）。
                        inline_subtree(owner, gty, gpath, imod, iprefix, full,
                                       d['signals'], depth + 1)
                continue
            res = M.auto(imod, ginst, gty, fam[gty]) if imod else None
            if res:
                cls, ipath, itype, how = res
                full = (iprefix + '.' + ipath) if iprefix else ipath
                emit(owner, gpath, gty, cls, full, itype, '', how, '')
                if gty in M.lostset and gty in M.g1.kids:
                    walk(owner, gty, gpath, itype, full, depth + 1)
                continue
            emit(owner, gpath, gty, 'UNRESOLVED', '', '', '', 'none', '')

    def inline_subtree(owner, gmod, gprefix, host, hprefix, ipath, signals, depth):
        """父层次被内联后，逐个如实记下它的后代。

        ★不要一律记成「没了」★：内联的常常只是**控制逻辑**，存储叶子往往被原样
        提到核里（L2TlbMissQueue 把 golden Queue40 的控制内联，但 `ram_40x47`
        仍以 `u_core.mem_ext` 存在）。所以每个后代都先在宿主核里做一次机器判定，
        判得出来就按真实新路径记，判不出来才记 INLINE_DESCENDANT。
        """
        if depth > 6:
            return
        fam = collections.defaultdict(list)
        for ty, i in M.g1.kids.get(gmod, ()):
            fam[ty].append(i)
        for gty, ginst in sorted(M.g1.kids.get(gmod, ()), key=lambda x: (x[1], x[0])):
            gpath = gprefix + '/' + ginst
            res = M.auto(host, ginst, gty, fam[gty]) if host else None
            if res:
                cls, rp, itype, how = res
                full = (hprefix + '.' + rp) if hprefix else rp
                emit(owner, gpath, gty, cls, full, itype, '', how,
                     '父层次已内联，但本层在宿主核里仍是独立实例')
                if gty in M.lostset and gty in M.g1.kids:
                    walk(owner, gty, gpath, itype, full, depth + 1)
                continue
            emit(owner, gpath, gty, 'INLINE_DESCENDANT', ipath, '-', signals,
                 'auto_inline_parent', '父层次已内联，本层随之消失')
            inline_subtree(owner, gty, gpath, host, hprefix, ipath, signals, depth + 1)

    M.lostset = set(M.lost)
    for P in M.rewritten:
        if P not in M.reach:
            continue
        if not M.g1.kids.get(P):
            continue
        walk(P, P, '', P, '', 0)

    stale = [d for d in decl if id(d) not in used]
    if stale:
        raise SystemExit('hier_map: 以下声明没有匹配到任何真实 golden 槽位（陈旧声明）:\n  ' +
                         '\n  '.join('%s / %s / %s' % (d['owner'], d['golden_child'],
                                                       d['golden_inst_re']) for d in stale))
    return rows


def check_decl_at_use(M, d, ipath, imod):
    """在**用到它的那个 impl 上下文**里校验声明：路径必须真实存在。

    放在使用点而不是预检，是因为被吸收的 golden 模块（如
    SyncDataModuleTemplate_FtqPC_64entry）在 impl 侧根本没有同名模块，
    它的子例化只能在「谁顶了它」的那个核里查。
    """
    known = {norm_path(p) for p, _t in M.flat(imod)}
    known |= {i for _t, i, _h in M.kids.get(imod, ())}
    if d['kind'] == 'INSTANCE':
        if norm_path(ipath) not in known:
            raise SystemExit('hier_map: 声明 %s/%s 的 impl_path `%s` 在 %s 的例化图里不存在'
                             % (d['owner'], d['golden_child'], ipath, imod))
    else:
        if norm_path(ipath) not in known:
            raise SystemExit('hier_map: 内联声明 %s/%s 的 impl_path `%s` 不是 %s 下真实存在的层次'
                             % (d['owner'], d['golden_child'], ipath, imod))


def validate(decl):
    """只做与上下文无关的语法校验；路径真实性放在 check_decl_at_use。"""
    bad = []
    for d in decl:
        if d['kind'] == 'INSTANCE':
            if not d['impl_module'] or d['impl_module'] == '-':
                bad.append('%s/%s: INSTANCE 行 impl_module 不能是 -' % (d['owner'], d['golden_child']))
        elif d['kind'] in ('INLINE', 'INLINE_REG_ARRAY'):
            if d['impl_module'] != '-':
                bad.append('%s/%s: %s 行 impl_module 必须是 -'
                           % (d['owner'], d['golden_child'], d['kind']))
            if not d['signals'].strip():
                bad.append('%s/%s: %s 行必须写清状态落在哪些信号上'
                           % (d['owner'], d['golden_child'], d['kind']))
        else:
            bad.append('%s/%s: 不认识的 kind=%s' % (d['owner'], d['golden_child'], d['kind']))
        if not d['evidence'].strip():
            bad.append('%s/%s: evidence 不能为空' % (d['owner'], d['golden_child']))
    if bad:
        raise SystemExit('hier_map: 声明表校验失败:\n  ' + '\n  '.join(bad))


def unreach_rows(M):
    out = []
    lost = set(M.lost)
    for m in M.lost:
        parents = sorted({p for p, _i in M.g1.sites.get(m, ())})
        nsites = len(M.g1.sites.get(m, ()))
        live = [p for p in parents if p not in lost]
        cause = 'ABSORBED_DIRECT' if live else 'ABSORBED_COLLATERAL'
        kind = 'SIGNED_OFF_TARGET' if m in M.impl_defs else 'GOLDEN_ONLY'
        f = M.defs.get(m, '')
        # 路径写成与 `--golden` 无关的形式，冻结文件的字节才不随命令行漂。
        if f.startswith(str(REPO)):
            f = str(pathlib.Path(f).relative_to(REPO))
        else:
            f = '$(GOLDEN_RTL)/' + pathlib.Path(f).name
        out.append(dict(module=m, kind=kind, cause=cause,
                        golden_parents=','.join(parents), golden_sites=str(nsites),
                        impl_owner=','.join(live) if live else '-', impl_file=f))
    return out


def render(hdr, cols, rows):
    L = list(hdr)
    L.append('# ' + '\t'.join(cols))
    for r in rows:
        L.append('\t'.join(str(r[c]) for c in cols))
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--golden', default=GOLDEN_DEFAULT)
    ap.add_argument('--filelist', help='默认现场生成（scripts/full_elab_filelist.py）')
    ap.add_argument('--top', default='XSTop')
    ap.add_argument('--check', action='store_true', help='重算并逐字节比对，不写文件')
    a = ap.parse_args()

    fl = a.filelist
    tmpdir = None
    if not fl:
        import tempfile
        tmpdir = tempfile.mkdtemp(prefix='hier_map_')
        fl = HR.gen_filelist(pathlib.Path(tmpdir) / 'files.f', REPO)
    M = Model(a.golden, fl, a.top)
    decl = load_decl()
    validate(decl)
    rows = build_rows(M, decl)
    ur = unreach_rows(M)

    map_txt = render(MAP_HDR, MAP_COLS, rows)
    ur_txt = render(UNREACH_HDR, UNREACH_COLS, ur)

    nun = sum(1 for r in rows if r['class'] == 'UNRESOLVED')
    print('golden XSTop 可达 : %d' % len(M.g_reach))
    print('impl   XSTop 可达 : %d' % len(M.reach))
    print('层次里没了的模块  : %d（其中重写签核目标 %d）'
          % (len(M.lost), sum(1 for r in ur if r['kind'] == 'SIGNED_OFF_TARGET')))
    print('路径映射行        : %d（UNRESOLVED %d）' % (len(rows), nun))
    by = collections.Counter(r['class'] for r in rows)
    print('  ' + '  '.join('%s=%d' % kv for kv in sorted(by.items())))

    rc = 0
    for path, txt in ((MAP_OUT, map_txt), (UNREACH_OUT, ur_txt)):
        if a.check:
            cur = path.read_text() if path.exists() else ''
            if cur != txt:
                rc = 1
                print('★DRIFT: %s 与重算结果不一致' % path.name)
                for l in list(difflib.unified_diff(cur.splitlines(), txt.splitlines(),
                                                   'repo', 'recomputed', lineterm=''))[:40]:
                    print('  ' + l)
        else:
            path.write_text(txt)
            print('写出 %s' % path)
    if tmpdir:
        import shutil
        shutil.rmtree(tmpdir, ignore_errors=True)
    if a.check and rc == 0:
        print('=== hier_map --check 幂等 PASS ===')
    return rc


if __name__ == '__main__':
    sys.exit(main())
