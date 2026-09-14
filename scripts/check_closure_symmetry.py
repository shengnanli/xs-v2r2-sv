#!/usr/bin/env python3
"""check_closure_symmetry.py —— 全仓 UT elaboration closure 对称性机器检查。

**为什么要有这道闸**（codex 0151 D60）：本轮已四次撞见 `RTL_GOLDEN_DEPS` 与
`FM_REF_DEPS_<top>` 不同步（零判断批 8 个目标、ICacheMissUnit 依赖选择、
DuplicatedTagArray）。两侧 elaboration 文件集不一致 ⇒ 同一个设计在 ref 侧白盒、
impl 侧黑盒（或反之），assembly 声明必被 `fm_verdict.py` 的
`assembly_bbox_not_symmetric` 拒；strict 模式下则是「impl 侧偷偷黑掉一块逻辑」的洞。
这些都只有跑完 heavy FM 才暴露。本脚本**不跑 FM**，纯静态复现同一判据。

**判据与 fm_verdict.py 逐字对齐**（scripts/fm_verdict.py:288-294）：
    ref_cnt  = Counter(design for side=='r')
    impl_cnt = Counter(design for side=='i')
    对称 ⟺ ref_cnt == impl_cnt
比的是**设计名的实例条数**、不是实例路径——可读核用 generate-for 数组取代 golden
的展平副本，实例名本就应不同。

**输入三样，全部与 FM 运行结果无关**（沿用 codex 0150 阶段 1 的反循环论证约束）：
  1. elaboration 元数据：`verif/ut/<dir>/Makefile` 的
     FM_REF_SRCS  = $(GOLDEN_RTL)/<top>.sv + FM_REF_DEPS_<top>
     FM_IMPL_SRCS = RTL_SRCS + RTL_GOLDEN_DEPS
     由 `make --eval` 自己展开，不手抄；
  2. 设计源层次图：verif/allow_gen/sv_elab.py（轻量 elaborator，已对 52 份已接受
     声明做过 52/52 交叉校验）；
  3. 冻结 registry：verif/vendor_boundary.tsv —— **只用于分类展示**，不参与判定。
**绝不读** black_boxes.rpt / native_facts.json / fm.log。

**fail-closed**：任何 make 展开失败、elaboration 报错、依赖文件不存在，一律计
FAIL（而不是「没看出问题所以通过」）。

退出码（负测须同时断言退出码**与**关键字，本工程有过「断言被前置门挡掉却报 PASS」
与「VCS 对 $fatal 返回 0」的假通过）：
    0  CLEAN      —— 所检目标全部对称且无错误
    1  VIOLATION  —— 至少一个 ASYMMETRIC / ERROR（正常的 fail-closed 结论）
    2  USAGE      —— 命令行/环境用法错误
    3  INTERNAL   —— 脚本自身未预期异常（输出含 INTERNAL_ERROR:，与 1 区分开，
                     避免「反测崩溃」和「反测抓到了」都是 1 的历史坑）
"""
import argparse
import concurrent.futures as _fut
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys
import traceback
from collections import Counter

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
sys.path.insert(0, str(REPO / 'verif' / 'allow_gen'))
import sv_elab  # noqa: E402

# --------------------------------------------------------------------------
# sv_elab.evaluate 的换行归一化（**只在本脚本内生效的 monkeypatch，不改共享文件**）
#
# sv_elab.evaluate 只做 expr.strip()，表达式**内部**的换行原样进 Python eval，
# 于是 golden 里这种跨行写法：
#     localparam W = A_OPCODE_W + A_PARAM_W + A_SIZE_W + SOURCE_W
#                    + ADDR_W + A_USER_W + MASK_W + DATA_W + 1;
# 会炸成 `unexpected indent`，把整个 target 判成 ERROR（实测 30 个 target 因此
# 无法判定，其中就有 TLBuffer_6/8/9/20/22 这 5 个 TLBuffer_13 的同族目标）。
# SystemVerilog 表达式对空白不敏感，折叠成单空格是保义变换。
# 不直接改 verif/allow_gen/sv_elab.py：那是 A 类 owner 做过 52/52 交叉校验的共享件，
# 本轮 freeze 中不动它。
# --------------------------------------------------------------------------
_sv_evaluate_orig = sv_elab.evaluate


def _evaluate_ws_normalized(expr, env):
    return _sv_evaluate_orig(' '.join(str(expr).split()), env)


sv_elab.evaluate = _evaluate_ws_normalized
for _m in ('_cond_true', '_prev_taken', '_parse_overrides', 'enumerate_blackboxes',
           '_mod_env', 'LazyEnv'):
    pass  # 同模块内以全局名引用 evaluate，替换模块属性即可对全部调用点生效

MARK = '@@'
EXIT_CLEAN, EXIT_VIOLATION, EXIT_USAGE, EXIT_INTERNAL = 0, 1, 2, 3


def make_vars(utdir, target):
    """用 make 自己展开 elaboration 变量（不执行任何配方、不跑 FM）。"""
    expr = (f'xsprint: ; @echo "{MARK}REF{MARK}$(GOLDEN_RTL)/{target}.sv '
            f'$(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_{target}))"; '
            f'echo "{MARK}IMPL{MARK}$(abspath $(RTL_SRCS) $(RTL_GOLDEN_DEPS))"; '
            f'echo "{MARK}MODE{MARK}$(FM_MODE)"; '
            f'echo "{MARK}VARIANTS{MARK}$(FM_VARIANTS)"; '
            f'echo "{MARK}IFONLY{MARK}$(FM_INTERFACE_ONLY)"')
    p = subprocess.run(['make', '--eval=' + expr, 'xsprint'], cwd=str(utdir),
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       universal_newlines=True)
    out = {}
    for ln in p.stdout.splitlines():
        if ln.startswith(MARK):
            k, _, v = ln[len(MARK):].partition(MARK)
            out[k] = v.split()
    if 'REF' not in out or 'IMPL' not in out:
        raise RuntimeError(f'make 展开失败 rc={p.returncode}: '
                           f'{(p.stderr or p.stdout).strip()[:200]}')
    return out


def variants_of(utdir):
    """本 UT 声称要证明的 golden 顶层集合。空 = 本 UT 不对任何 golden 顶层。"""
    try:
        v = make_vars(utdir, '__probe__')
    except RuntimeError:
        return None
    return v.get('VARIANTS', [])


def typedef_names(files):
    """收集该侧文件集里所有 typedef 出来的类型名。

    **为什么必须有这一步**：sv_elab 的例化识别是「<标识符> <标识符> (」模式，
    而手写可读核里的 `function automatic maxpair_t find_max(` 与
    `ras_entry_t sel_top(` 长得一模一样，会被误当成「例化了一个叫 find_max 的
    maxpair_t 模块」。golden 是 firtool 产物、从不用 typedef，所以这种误判**只发生在
    impl 侧**，表现为凭空多出的单侧黑盒——正是最容易被误读成「闭包不对称」的假阳性。
    实测 FPDecoder(dec_t)/PLICFanIn(maxpair_t)/RASStack(ras_entry_t) 三例即此。

    typedef 名永远不是模块类型，故从两侧黑盒集里一律剔除，并记进 JSON 备查。
    """
    names = set()
    for f in files:
        try:
            txt = sv_elab._scrub(open(f, errors='replace').read())
        except OSError:
            continue
        for m in re.finditer(r'\btypedef\b', txt):
            i, depth, last = m.end(), 0, None
            while i < len(txt):
                c = txt[i]
                if c in '{([':
                    depth += 1
                elif c in '})]':
                    depth -= 1
                elif c == ';' and depth <= 0:
                    break
                i += 1
            decl = txt[m.end():i]
            ids = re.findall(r'[A-Za-z_]\w*', decl.split('}')[-1] or decl)
            if ids:
                names.add(ids[-1])
    return names


def check_target(utdir, target):
    """返回一行结果 dict。任何异常都转成 status=ERROR（fail-closed）。"""
    row = {'target': target, 'utdir': os.path.relpath(str(utdir), str(REPO)),
           'mode': '?', 'status': 'ERROR', 'detail': '',
           'ref_bbox': {}, 'impl_bbox': {}}
    try:
        v = make_vars(utdir, target)
        row['mode'] = (v.get('MODE') or ['strict'])[0] or 'strict'
        if (v.get('IFONLY') or [''])[0] in ('true', '1', 'yes'):
            row['status'] = 'SKIP'
            row['detail'] = 'FM_INTERFACE_ONLY —— 不做层次闭包比较'
            return row

        missing = [f for f in v['REF'] + v['IMPL'] if not os.path.exists(f)]
        if missing:
            row['detail'] = ('elab_src_missing:' +
                             ','.join(os.path.basename(m) for m in missing[:4]))
            return row

        ru, _ = sv_elab.load_universe(v['REF'])
        rb, _ = sv_elab.enumerate_blackboxes(target, ru, 'r')
        iu, _ = sv_elab.load_universe(v['IMPL'])
        ib, _ = sv_elab.enumerate_blackboxes(target, iu, 'i')
    except sv_elab.ElabError as e:
        row['detail'] = f'elab_error:{e}'
        return row
    except RuntimeError as e:
        row['detail'] = f'make_error:{e}'
        return row
    except Exception as e:  # noqa: BLE001 - fail-closed, 不吞
        row['detail'] = f'unexpected:{type(e).__name__}:{e}'
        return row

    # 剔除 typedef 类型名造成的伪黑盒（见 typedef_names 的说明）
    tdn = typedef_names(v['REF']) | typedef_names(v['IMPL'])
    dropped = sorted({d for _, d, _ in rb if d in tdn} | {d for _, d, _ in ib if d in tdn})
    if dropped:
        row['typedef_filtered'] = dropped
    rb = [x for x in rb if x[1] not in tdn]
    ib = [x for x in ib if x[1] not in tdn]

    ref_cnt, impl_cnt = Counter(d for _, d, _ in rb), Counter(d for _, d, _ in ib)
    row['ref_bbox'], row['impl_bbox'] = dict(ref_cnt), dict(impl_cnt)
    if ref_cnt != impl_cnt:
        # 与 fm_verdict.py:288-294 同一条挑选规则，消息格式也对齐，便于对照
        diff = sorted(set(ref_cnt) ^ set(impl_cnt)) or \
            sorted(d for d in ref_cnt if ref_cnt[d] != impl_cnt.get(d))
        row['status'] = 'ASYMMETRIC'
        row['detail'] = (f'assembly_bbox_not_symmetric:{diff[0]}'
                         f'(ref={ref_cnt.get(diff[0], 0)},impl={impl_cnt.get(diff[0], 0)})')
        return row
    row['status'] = 'SYMMETRIC'
    if ref_cnt:
        row['detail'] = 'bbox=' + ','.join(f'{d}x{n}' for d, n in sorted(ref_cnt.items()))
    return row


# --------------------------------------------------------------------------
# 源清单对账（codex 0153 D69）—— 给 `$bits(...)` 那 95 个 ERROR 的第二条路
# --------------------------------------------------------------------------
# ★D69 的禁令：不要为支持完整 SystemVerilog 而自写第二个 elaborator。★
# 所以这里**不**去教 sv_elab 认 `$bits(type/signal)`。换的是判据本身：
#
#   原判据（enumerate_blackboxes）要先把参数/generate 求值出来，才知道到底例化了谁，
#   于是一遇到 `$bits(io_mem_acquire_bits_address)` 这种表达式就判不下去。
#   但 `$bits` 出现的位置是**位宽**与**参数覆盖**（实测 ICacheMissUnit 的 7 处全是
#   `localparam int unsigned W = $bits(t);` 与 `.PORT_ACQ_ADDR_W ($bits(...))`），
#   它决定不了"例化的是哪个模块"。
#
#   新判据只问两件**不需要求值**的事：
#     provides(side)   这一侧读入的文件里**定义**了哪些 design（纯声明扫描）
#     refs_over(side)  从 target 出发，把所有 generate 分支都当成走到，
#                      语法上可能例化到的 design 集合（**过近似**）
#   黑盒 = 被引用但没被提供（FM 的 hdlin_unresolved_modules=black_box 就是这条）。
#   真实黑盒集 ⊆ refs_over - provides。所以：
#
#       ★两侧的 (refs_over - provides) 都为空 ⇒ 两侧真实黑盒集都为空
#         ⇒ Counter(ref)==Counter(impl)=={} ⇒ 一定对称。★
#
#   这是**充分**条件，不是充要：过近似不空时只能判不准（照旧 CLOSURE_UNKNOWN），
#   绝不反过来当成"不对称"。方向是安全的那一边。
#
# 附带做 D69 要的 **provider hash 对账**：两侧都提供的 design，逐个记下它在各侧
# 的提供文件与 sha256。同名不同字节 = 两侧在拿不同的东西当同一个设计。

INV_CLOSED = 'CLOSED_NO_BLACKBOX'      # 已证明两侧黑盒集皆空 ⇒ 对称
INV_UNKNOWN = 'INVENTORY_UNKNOWN'      # 过近似不为空 —— 判不准，维持 CLOSURE_UNKNOWN
INV_ERROR = 'INVENTORY_ERROR'          # 连声明都扫不出来（fail-closed）

#: `bind` 会在语法可见的例化之外再挂上实例，"语法过近似"这个前提就不成立了。
#: 本仓 golden 是 firtool 产物、可读核也不用 bind；真出现就必须停下来，不许放行。
_BIND = re.compile(r'^\s*bind\s+[A-Za-z_]', re.M)


def _provider_inventory(files):
    """{design: (文件名, sha256)} + {design: [被它例化的 design…]}。

    纯声明扫描：不求值参数、不解 generate、不碰 `$bits`。
    """
    prov, insts = {}, {}
    for f in files:
        try:
            raw = open(f, 'rb').read()
        except OSError as e:
            raise RuntimeError(f'源文件读不出来: {f}: {e}')
        if _BIND.search(raw.decode('utf-8', 'replace')):
            raise RuntimeError(f'{os.path.basename(f)} 里有 `bind` —— '
                               f'"语法例化是过近似"这个前提不成立，拒绝下结论')
        sha = hashlib.sha256(raw).hexdigest()
        mods = sv_elab.parse_file(f)
        for name, m in mods.items():
            # 同名模块被后读的文件覆盖：与 FM 读文件的语义一致，记最后一个
            prov[name] = (os.path.basename(f), sha)
            insts[name] = [typ for (_p, typ, _i, _o) in m.insts]
    return prov, insts


def _refs_overapprox(target, prov, insts, drop):
    """从 target 出发的**语法过近似**引用集（所有 generate 分支都当走到）。"""
    seen, stack, refs = set(), [target], set()
    while stack:
        n = stack.pop()
        if n in seen:
            continue
        seen.add(n)
        for typ in insts.get(n, ()):
            if typ in drop:
                continue
            refs.add(typ)
            if typ in prov:
                stack.append(typ)
    return refs


def inventory_check(utdir, target):
    """源清单对账。返回 row dict（status ∈ INV_*）。任何异常都 fail-closed。"""
    row = {'target': target, 'utdir': os.path.relpath(str(utdir), str(REPO)),
           'inventory': INV_ERROR, 'inventory_detail': ''}
    try:
        v = make_vars(utdir, target)
        ref = [f for f in v['REF'] if os.path.exists(f)]
        impl = [f for f in v['IMPL'] if os.path.exists(f)]
        missing = [f for f in v['REF'] + v['IMPL'] if not os.path.exists(f)]
        if missing:
            row['inventory_detail'] = ('elab_src_missing:' + ','.join(
                os.path.basename(m) for m in missing[:4]))
            return row
        drop = typedef_names(ref) | typedef_names(impl)
        rp, ri = _provider_inventory(ref)
        ip, ii = _provider_inventory(impl)
        if target not in rp:
            row['inventory_detail'] = f'ref 侧没有提供 {target} 的定义'
            return row
        if target not in ip:
            row['inventory_detail'] = f'impl 侧没有提供 {target} 的定义'
            return row
        rbb = sorted(_refs_overapprox(target, rp, ri, drop) - set(rp))
        ibb = sorted(_refs_overapprox(target, ip, ii, drop) - set(ip))
    except (RuntimeError, sv_elab.ElabError) as e:
        row['inventory_detail'] = f'{type(e).__name__}:{e}'
        return row
    except Exception as e:  # noqa: BLE001 - fail-closed，不吞
        row['inventory_detail'] = f'unexpected:{type(e).__name__}:{e}'
        return row

    # provider hash 对账（D69 明确要的那一半）
    both = sorted(set(rp) & set(ip))
    shared = [d for d in both if rp[d][1] == ip[d][1]]
    row['provider_reconcile'] = {
        'ref_provides': len(rp), 'impl_provides': len(ip),
        'provided_both_sides': len(both),
        'identical_bytes_both_sides': len(shared),
        'ref_only': sorted(set(rp) - set(ip))[:20],
        'impl_only': sorted(set(ip) - set(rp))[:20],
    }
    row['overapprox_bbox'] = {'ref': rbb, 'impl': ibb}
    if not rbb and not ibb:
        row['inventory'] = INV_CLOSED
        row['inventory_detail'] = (
            f'两侧语法过近似黑盒集皆空（ref 提供 {len(rp)} / impl 提供 {len(ip)} '
            f'个 design，其中 {len(shared)} 个两侧字节相同）'
            f' ⇒ 真实黑盒集必为空 ⇒ 对称')
        return row
    row['inventory'] = INV_UNKNOWN
    row['inventory_detail'] = (f'过近似黑盒非空，判不准（不等于不对称）: '
                               f'ref={rbb[:6]} impl={ibb[:6]}')
    return row


def dead_deps(utdir, target):
    """报告两侧文件集里读入、但层次闭包里无人例化的**死依赖**（提示，不判 FAIL）。

    死依赖本身不致错，但它是「依赖表没人维护」的强信号——DuplicatedTagArray 的
    array_9.sv 两侧都读、闭包里无人例化，与 array_8.sv 该读没读是同一处失修。
    """
    out = {}
    try:
        v = make_vars(utdir, target)
        for side, files in (('ref', v['REF']), ('impl', v['IMPL'])):
            files = [f for f in files if os.path.exists(f)]
            # 每个文件单独解析，拿「该文件定义了哪些 module」——不能用合并后的
            # universe 反查（同名模块被后读的文件覆盖，会把前一个文件误判成死的）。
            per_file = {f: set(sv_elab.parse_file(f)) for f in files}
            uni, _ = sv_elab.load_universe(files)
            seen, used = set(), set()

            def walk(name):
                if name in seen or name not in uni:
                    return
                seen.add(name)
                for _pos, typ, _i, _o in uni[name].insts:
                    used.add(typ)
                    walk(typ)
            walk(target)
            reach = seen | used
            dead, empty = [], []
            for f, names in per_file.items():
                if not names:
                    empty.append(os.path.basename(f))
                elif not (names & reach):
                    dead.append(os.path.basename(f))
            out[side] = sorted(dead)
            if empty:
                # fail-closed 提示：文件读了却一个 module 都没解析出来 = 解析可疑
                out[side + '_unparsed'] = sorted(empty)
    except Exception as e:  # noqa: BLE001
        return {'error': f'{type(e).__name__}:{e}'}
    return out


# --------------------------------------------------------------------------
# registry schema 校验（codex 0151 D60：registry 必须补端口/参数签名与 body/hash 规则）
# --------------------------------------------------------------------------
REG_COLS = ['design_pattern', 'kind', 'rationale', 'leaf_file', 'leaf_sha256',
            'port_count', 'port_signature', 'port_sig_sha256_16',
            'param_signature', 'body_rule']


def _extract_leaf(golden_rtl, design):
    """从 golden **现读**端口/参数/hash —— 不读表里已有的值，防自证。"""
    f = pathlib.Path(golden_rtl) / f'{design}.v'
    if not f.exists():
        f2 = pathlib.Path(golden_rtl) / f'{design}.sv'
        if not f2.exists():
            raise FileNotFoundError(f'{design}: golden 里找不到 {design}.v/.sv')
        f = f2
    raw = f.read_bytes()
    txt = re.sub(r'//[^\n]*', '', re.sub(r'/\*.*?\*/', '', raw.decode(errors='replace'), flags=re.S))
    m = re.search(r'\bmodule\s+' + re.escape(design) + r'\s*(#\s*\([^;]*?\))?\s*\((.*?)\)\s*;',
                  txt, re.S)
    if not m:
        raise ValueError(f'{design}: 模块头解析失败')
    ports = [' '.join(x.split()) for x in m.group(2).split(',') if x.strip()]
    body = txt[m.end():]
    body = body[:body.find('endmodule')] if 'endmodule' in body else body
    params = re.findall(r'\bparameter\b\s+([^;]+);', (m.group(1) or '') + ' ; ' + body)
    psig = ';'.join(ports)
    return {'leaf_file': f.name,
            'leaf_sha256': hashlib.sha256(raw).hexdigest(),
            'port_count': str(len(ports)),
            'port_signature': psig,
            'port_sig_sha256_16': hashlib.sha256(psig.encode()).hexdigest()[:16],
            'param_signature': ';'.join(' '.join(x.split()) for x in params) if params else 'none'}


def check_registry(path, golden_rtl):
    """逐条把 registry 的签名/hash 与 golden 现文件比对。返回 (ok, [问题])。"""
    probs, n = [], 0
    try:
        lines = pathlib.Path(path).read_text().splitlines()
    except OSError as e:
        return False, [f'registry_unreadable:{e}']
    for i, ln in enumerate(lines, 1):
        if ln.startswith('#') or not ln.strip():
            continue
        n += 1
        f = ln.split('\t')
        if len(f) != len(REG_COLS):
            probs.append(f'L{i} {f[0] if f else "?"}: registry_field_count '
                         f'期望 {len(REG_COLS)} 列得到 {len(f)} 列 '
                         f'(缺 {",".join(REG_COLS[len(f):]) or "?"})')
            continue
        row = dict(zip(REG_COLS, f))
        for c in REG_COLS:
            if not row[c].strip():
                probs.append(f'L{i} {row["design_pattern"]}: registry_field_empty:{c}')
        if 'pin_by=leaf_sha256' not in row['body_rule']:
            probs.append(f'L{i} {row["design_pattern"]}: registry_body_rule_missing_pin '
                         f'(body_rule 必须含 pin_by=leaf_sha256)')
        try:
            cur = _extract_leaf(golden_rtl, row['design_pattern'])
        except Exception as e:  # noqa: BLE001
            probs.append(f'L{i} {row["design_pattern"]}: registry_golden_extract_failed:{e}')
            continue
        for c in ('leaf_file', 'leaf_sha256', 'port_count', 'port_signature',
                  'port_sig_sha256_16', 'param_signature'):
            if row[c] != cur[c]:
                probs.append(f'L{i} {row["design_pattern"]}: registry_mismatch:{c} '
                             f'表={row[c][:40]!r} golden={cur[c][:40]!r}')
    if n == 0:
        probs.append('registry_empty: 一条都没有（fail-closed：空表不算通过）')
    return (not probs), probs


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--ut-root', default=str(REPO / 'verif' / 'ut'))
    ap.add_argument('--only', action='append', default=[],
                    help='只查这些 UT 目录名（可重复）')
    ap.add_argument('--json', help='把完整结果写成 JSON（用于 artifact hash）')
    # ★不要叫 --ledger★：main 上 agent/registry-memory-macro 已经用 --ledger 指
    # docs/g1_boundary_ledger.tsv（配 --reconcile-ledger）。两边都叫 --ledger 时
    # git 能"干净合并"，但 argparse 在运行期直接 conflicting option string 崩掉 ——
    # 实测试merge后 scripts/test_check_closure_symmetry.py 整套挂掉。
    ap.add_argument('--closure-ledger',
                    help='把逐 target 判定写成 TSV 台账'
                         '（CLOSURE_UNKNOWN 必须如实登记，D69）')
    ap.add_argument('--jobs', type=int, default=min(8, (os.cpu_count() or 4)))
    ap.add_argument('--check-registry', action='store_true',
                    help='只校验 verif/vendor_boundary.tsv 的 schema 与签名/hash（不扫 UT）')
    ap.add_argument('--registry', default=str(REPO / 'verif' / 'vendor_boundary.tsv'))
    ap.add_argument('--golden-rtl',
                    default=os.environ.get('GOLDEN_RTL',
                                           '/home/eda/xs-env/G1-canonical/golden-rtl'))
    ap.add_argument('--inventory', action='store_true',
                    help='对 elaboration 判不准（ERROR）的 target 再跑一遍**源清单对账**'
                         '（codex 0153 D69）：两侧语法过近似黑盒集皆空即可判对称。'
                         '不新写 elaborator，只用 make 展开的文件表 + 声明扫描。')
    ap.add_argument('--dead-deps', action='store_true',
                    help='额外报告死依赖（读入但闭包里无人例化的文件）')
    a = ap.parse_args(argv)

    if a.check_registry:
        ok, probs = check_registry(a.registry, a.golden_rtl)
        print(f'=== registry schema check: {a.registry} ===')
        print(f'    golden = {a.golden_rtl}')
        for x in probs:
            print('  ' + x)
        if ok:
            print('OK: registry 每条的端口签名/参数签名/leaf hash 与 golden 现文件一致')
            return EXIT_CLEAN
        print(f'FAIL: registry {len(probs)} 处问题（fail-closed）')
        return EXIT_VIOLATION

    root = pathlib.Path(a.ut_root)
    if not root.is_dir():
        print(f'USAGE_ERROR: --ut-root 不是目录: {root}', file=sys.stderr)
        return EXIT_USAGE
    utdirs = sorted(d for d in root.iterdir() if (d / 'Makefile').is_file())
    if a.only:
        want = set(a.only)
        utdirs = [d for d in utdirs if d.name in want]
        miss = want - {d.name for d in utdirs}
        if miss:
            print(f'USAGE_ERROR: 找不到 UT 目录: {",".join(sorted(miss))}', file=sys.stderr)
            return EXIT_USAGE
    if not utdirs:
        print('USAGE_ERROR: 没有找到任何带 Makefile 的 UT 目录', file=sys.stderr)
        return EXIT_USAGE

    jobs = []
    probe_err = []
    for d in utdirs:
        vs = variants_of(d)
        if vs is None:
            probe_err.append(d)
            continue
        for t in vs:
            jobs.append((d, t))

    rows = []
    with _fut.ThreadPoolExecutor(max_workers=a.jobs) as ex:
        futs = {ex.submit(check_target, d, t): (d, t) for d, t in jobs}
        for f in _fut.as_completed(futs):
            rows.append(f.result())
    for d in probe_err:
        rows.append({'target': '(FM_VARIANTS 展开失败)',
                     'utdir': os.path.relpath(str(d), str(REPO)), 'mode': '?',
                     'status': 'ERROR', 'detail': 'make_error: 无法展开 FM_VARIANTS',
                     'ref_bbox': {}, 'impl_bbox': {}})
    rows.sort(key=lambda r: (r['utdir'], r['target']))

    if a.dead_deps:
        for r in rows:
            if r['status'] in ('SYMMETRIC', 'ASYMMETRIC'):
                r['dead_deps'] = dead_deps(REPO / r['utdir'], r['target'])

    # ---- D69 第二条路：对 ERROR 行做源清单对账，能关掉的关掉 ----
    if a.inventory:
        todo = [r for r in rows if r['status'] == 'ERROR' and r['target'].isidentifier()]
        with _fut.ThreadPoolExecutor(max_workers=a.jobs) as ex:
            futs = {ex.submit(inventory_check, REPO / r['utdir'], r['target']): r
                    for r in todo}
            for f in _fut.as_completed(futs):
                r = futs[f]
                inv = f.result()
                r.update({k: v for k, v in inv.items()
                          if k not in ('target', 'utdir')})
                if inv['inventory'] == INV_CLOSED:
                    # ★只把"判不准"升级成"已证明对称"，绝不反向把 ERROR 变 ASYMMETRIC★
                    r['status'] = 'SYMMETRIC_BY_INVENTORY'
                    r['detail'] = inv['inventory_detail']
                else:
                    r['status'] = 'CLOSURE_UNKNOWN'
                    r['detail'] = f"{r['detail']} || 源清单对账: {inv['inventory_detail']}"
        for r in rows:
            if r['status'] == 'ERROR' and not r['target'].isidentifier():
                r['status'] = 'CLOSURE_UNKNOWN'

    tally = Counter(r['status'] for r in rows)
    bad = [r for r in rows
           if r['status'] in ('ASYMMETRIC', 'ERROR', 'CLOSURE_UNKNOWN')]

    w = max([len(r['target']) for r in rows] + [6])
    print(f'=== closure symmetry: {len(rows)} 个 target / {len(utdirs)} 个 UT 目录 ===')
    for r in rows:
        if r['status'] not in ('SYMMETRIC', 'SYMMETRIC_BY_INVENTORY'):
            print(f'  [{r["status"]:<10}] {r["target"]:<{w}} ({r["mode"]:<8}) '
                  f'{r["utdir"]}  {r["detail"]}')
    print('--- tally: ' + ', '.join(f'{k}={v}' for k, v in sorted(tally.items())) + ' ---')

    if a.closure_ledger:
        led = [
            '# UT elaboration closure 对称性台账'
            '（scripts/check_closure_symmetry.py --inventory --closure-ledger 生成）',
            '# SYMMETRIC              轻量 elaboration 直接判定两侧黑盒 Counter 相等',
            '# SYMMETRIC_BY_INVENTORY 源清单对账（D69）：两侧**语法过近似**黑盒集皆空',
            '#                        ⇒ 真实黑盒集必空 ⇒ 一定对称。充分条件，方向安全。',
            '# CLOSURE_UNKNOWN        ★判不准★ —— 不等价于 clean，也不等价于不对称。',
            '#                        它不阻塞"全集身份冻结"，但**阻塞该目标 PASS**；',
            '#                        bank 前必须由权威编译/elaboration source inventory',
            '#                        或扩展后的 checker 证明对称。',
            '# ASYMMETRIC             两侧 elaboration 集合确实不对称（真缺陷）',
            '# SKIP                   FM_INTERFACE_ONLY，不做层次闭包比较',
            '# target\tutdir\tmode\tstatus\tdetail',
        ]
        for r in rows:
            led.append('%s\t%s\t%s\t%s\t%s'
                       % (r['target'], r['utdir'], r['mode'], r['status'],
                          ' '.join(str(r.get('detail', '')).split())[:400]))
        blob = '\n'.join(led) + '\n'
        pathlib.Path(a.closure_ledger).write_text(blob)
        print(f'ledger: {a.closure_ledger}  sha256='
              f'{hashlib.sha256(blob.encode()).hexdigest()[:16]}')

    if a.json:
        blob = json.dumps({'rows': rows, 'tally': dict(tally)},
                          ensure_ascii=False, indent=1, sort_keys=True)
        pathlib.Path(a.json).write_text(blob)
        print(f'json: {a.json}  sha256={hashlib.sha256(blob.encode()).hexdigest()[:16]}')

    if a.inventory:
        n_closed = tally.get('SYMMETRIC_BY_INVENTORY', 0)
        print(f'--- 源清单对账（D69）关掉了 {n_closed} 个 CLOSURE_UNKNOWN；'
              f'仍判不准 {tally.get("CLOSURE_UNKNOWN", 0)} 个 ---')
    if bad:
        print(f'FAIL: {len(bad)} 个 target closure 不对称或无法判定（fail-closed）')
        print('  ★UNKNOWN 不等价于 clean★：它不阻塞"全集身份冻结"，但阻塞目标 PASS。')
        return EXIT_VIOLATION
    print('OK: 所检 target 两侧 elaboration closure 对称')
    return EXIT_CLEAN


if __name__ == '__main__':
    try:
        sys.exit(main())
    except SystemExit:
        raise
    except Exception:  # noqa: BLE001
        traceback.print_exc()
        print('INTERNAL_ERROR: check_closure_symmetry.py 自身异常（不是检查结论）',
              file=sys.stderr)
        sys.exit(EXIT_INTERNAL)
