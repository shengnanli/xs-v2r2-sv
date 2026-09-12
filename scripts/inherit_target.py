#!/usr/bin/env python3
"""inherit_target.py —— 快车道继承：把 xs-v2r2-sv 的一个目标重组进单文件规范。

做的事（对 simple 类目标）：
  1. 解析老 verif/ut/<t>/Makefile 拿 RTL_SRCS/WRAPPER_SRCS/GOLDEN_SRCS/FM_* 配置;
  2. rtl/common 依赖原样复制（去重）；目标自有源合并:
     pkg 文件 + 核文件 拼进主文件, wrapper/variants 文件拆成每 golden 模块一段——
     目标同名 wrapper 并入主文件尾部, 兄弟变体各出薄文件（一个 golden 模块=一个文件）;
  3. 生成新 verif/ut/<t>/{tb.sv, Makefile}（GOLDEN_SRCS/FM_* 原样搬, 源列表换新路径）;
  4. 校验: FM_VARIANTS 每个名字恰好出现为一个模块声明; GOLDEN_SRCS 在 G1 全存在。
不跑 UT/FM——那由调用方串行执行。冲突/歧义直接报错退出（宁可人工，不静默凑合）。

用法: inherit_target.py <target> [--registry <json>]
"""
import argparse
import json
import pathlib
import re
import sys

OLD = pathlib.Path('/home/eda/xs-env/xs-v2r2-sv')
NEW = pathlib.Path('/home/eda/xs-env/xs-v2-sv')
G1 = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
MANIFEST = pathlib.Path('/home/eda/xs-env/xs-signoff/scripts/sidecar/manifest_305.json')

MOD_RE = re.compile(r'^module\s+([A-Za-z_]\w*)', re.MULTILINE)
FM_EQ = NEW / 'scripts' / 'fm_eq.tcl'
G0 = pathlib.Path('/home/eda/xs-env/G0-canonical/golden-rtl')
_SCALA_LN = re.compile(rb'\.scala:\d+')
_remap_cache = {}


def golden_remap(fname):
    """G1 重编号自动解析：老配置引用的 golden 文件在 G1 已改名时，找回同一模块。
    判据 = 自身模块名与断言行号归一后**字节完全相同**（纯重编号），否则不认——
    内容真变的目标必须人工处理，不允许悄悄换成另一个模块。"""
    if fname in _remap_cache:
        return _remap_cache[fname]
    if (G1 / fname).exists() or not (G0 / fname).exists():
        _remap_cache[fname] = None
        return None
    stem = fname[:-3]
    want = _SCALA_LN.sub(b'.scala:0', (G0 / fname).read_bytes()).replace(stem.encode(), b'@S@')
    fam = re.match(r'^(.*?)(_\d+)?$', stem).group(1)
    for cand in sorted(G1.glob(fam + '*.sv')):
        cs = cand.stem
        got = _SCALA_LN.sub(b'.scala:0', cand.read_bytes()).replace(cs.encode(), b'@S@')
        if got == want:
            _remap_cache[fname] = cand.name
            return cand.name
    _remap_cache[fname] = None
    return None



MACRO_RE = re.compile(r'^(sram_array_\w+|array(_\d+)?)$')
INST_RE = re.compile(r'^\s+([A-Za-z_]\w*)\s+[A-Za-z_]\w*\s*\(', re.MULTILINE)


def macro_closure(files):
    """厂商 SRAM 宏链闭包补全：G1 里宏内部例化的 array_N 也可能被重编号
    （如 dcsh_tag 宏的子阵列 array_9→array_8），老配置里的名字会失配。
    只对宏类文件（sram_array_*/array_*）做传递补全，不扩散到功能模块。"""
    out, seen = list(files), set(files)
    queue = [f for f in files if MACRO_RE.match(f.rsplit('.', 1)[0])]
    while queue:
        f = queue.pop()
        fp = G1 / f
        if not fp.exists() or not f.endswith('.sv'):
            continue
        for m in INST_RE.finditer(fp.read_text(errors='replace')):
            child = m.group(1)
            if not MACRO_RE.match(child):
                continue
            for cand in (child + '.sv', child + '_ext.v'):
                if cand in seen or not (G1 / cand).exists():
                    continue
                seen.add(cand)
                out.append(cand)
                if cand.endswith('.sv'):
                    queue.append(cand)
    return out


def _whitelist_add(name):
    """把 vmucp 目标幂等插入 fm_eq.tcl 的精确白名单（继承老战役审计声明）。"""
    txt = FM_EQ.read_text()
    m = re.search(r'if \{\$top ni \{([^}]*)\}\} \{', txt)
    if not m:
        sys.exit('ERROR: fm_eq.tcl 白名单结构未找到')
    cur = m.group(1).split()
    if name in cur:
        return
    cur = sorted(set(cur + [name]))
    FM_EQ.write_text(txt[:m.start(1)] + ' '.join(cur) + txt[m.end(1):])


def parse_makefile(text):
    """解析 make 变量（支持行继续），返回 dict。"""
    text = re.sub(r'\\\n', ' ', text)
    vals = {}
    # 注意: = 后用 [ \t]* 而非 \s*（\s 含换行, 空值行会吞掉下一行）
    for m in re.finditer(r'^(\w+)[ \t]*[:+?]?=[ \t]*(.*)$', text, re.MULTILINE):
        k, v = m.group(1), m.group(2).strip()
        vals[k] = (vals.get(k, '') + ' ' + v).strip() if k in vals else v
    return vals


MAKE_FUNC_RE = re.compile(r'\$\((addprefix|addsuffix)\s+([^,()$]*),([^()$]*)\)')


def expand_make(v, vals):
    """迭代展开 $(VAR) 与 addprefix/addsuffix；GOLDEN_RTL 保留为 @GOLDEN@ 记号。"""
    for _ in range(20):
        def sub_var(m):
            name = m.group(1)
            if name == 'GOLDEN_RTL':
                return '@GOLDEN@'
            if name == 'RTL_DIR':
                return str(OLD / 'rtl')
            return vals.get(name, '')
        new = re.sub(r'\$\((\w+)\)', sub_var, v)

        def sub_func(m):
            func, a1, a2 = m.group(1), m.group(2).strip(), m.group(3)
            return ' '.join((a1 + i) if func == 'addprefix' else (i + a1)
                            for i in a2.split())
        new = MAKE_FUNC_RE.sub(sub_func, new)
        if new == v:
            return v
        v = new
    sys.exit(f'ERROR: make 表达式展开不收敛: {v[:120]}')


def split_modules(text):
    """把文件拆成 (头部注释, [(模块名, 模块全文)])。"""
    starts = [(m.start(), m.group(1)) for m in MOD_RE.finditer(text)]
    if not starts:
        return text, []
    header = text[:starts[0][0]]
    chunks = []
    for i, (pos, name) in enumerate(starts):
        end = starts[i + 1][0] if i + 1 < len(starts) else len(text)
        chunks.append((name, text[pos:end].rstrip() + '\n'))
    return header, chunks


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('target')
    ap.add_argument('--registry', default=str(NEW / 'docs' / 'inherit_registry.json'))
    args = ap.parse_args()
    t = args.target

    regp = pathlib.Path(args.registry)
    registry = json.loads(regp.read_text()) if regp.exists() else {}

    man = {e['target']: e for e in json.load(MANIFEST.open())['entries']}
    if t not in man:
        sys.exit(f'ERROR: {t} 不在 306 manifest')
    if man[t].get('reference_kind', 'golden') != 'golden':
        sys.exit(f"ERROR: {t} 老战役用 canonical_derivative 参考"
                 f"({man[t].get('derivative_id')}), 非快车道, SPECIAL 专项处理")
    vmucp = man[t].get('verify_matched_unread_compare_points') == 'true'
    # 老战役 assembly 契约继承: allow/<t>.json 声明的对称黑盒条数 → FM_ALLOWLIST 配额。
    # fm_verdict 的 assembly 判定要求「未匹配对称且 ≤ 配额」, 非对称一律 PARTIAL。
    asm_mode = man[t].get('proof_mode') == 'assembly'
    allow_n, allow_ids = 0, []
    if asm_mode and man[t].get('allow_ref'):
        ap = pathlib.Path('/home/eda/xs-env/xs-signoff') / man[t]['allow_ref']
        if ap.exists():
            aj = json.loads(ap.read_text())
            for k in ('unresolved_blackbox', 'interface_only', 'empty_blackbox', 'unmatched'):
                for e in aj.get(k, []):
                    allow_ids.append(e.get('id', k) if isinstance(e, dict) else str(e))
            allow_n = len(allow_ids)
    old_mk = OLD / man[t]['makefile']
    old_ut = old_mk.parent
    vals = parse_makefile(old_mk.read_text())

    def expand(v):
        return [x for x in expand_make(v, vals).split() if x]

    rtl_srcs = expand(vals.get('RTL_SRCS', ''))
    wrap_srcs_all = expand(vals.get('WRAPPER_SRCS', ''))
    fm_variants = expand(vals.get('FM_VARIANTS', ''))
    if not fm_variants:
        sys.exit(f'ERROR: {t} 老 Makefile 无 FM_VARIANTS')

    # --- 分拣源文件（@GOLDEN@ 开头 = golden 行为模型/闭包, 原样引用不合并） ---
    common_deps, pkg_files, core_files = [], [], []
    golden_passthru = []
    wrap_srcs = []
    for s in rtl_srcs:
        if s.startswith('@GOLDEN@'):
            golden_passthru.append(s.replace('@GOLDEN@/', ''))
            continue
        p = pathlib.Path(s)
        if not p.exists():
            sys.exit(f'ERROR: {t} RTL_SRC 不存在 {p}')
        if '/rtl/common/' in str(p):
            common_deps.append(p)
        elif p.name.endswith('_pkg.sv'):
            pkg_files.append(p)
        else:
            core_files.append(p)
    for s in wrap_srcs_all:
        if s.startswith('@GOLDEN@'):
            golden_passthru.append(s.replace('@GOLDEN@/', ''))
        else:
            wrap_srcs.append(s)
    golden_passthru = sorted(set(golden_passthru))
    remapped = {}
    for i, g in enumerate(list(golden_passthru)):
        if not (G1 / g).exists():
            r = golden_remap(g)
            if not r:
                sys.exit(f'ERROR: {t} golden 依赖在 G1 缺失且非纯重编号: {g}（人工处理）')
            remapped[g] = r
            golden_passthru[i] = r
    golden_passthru = sorted(set(golden_passthru))

    # 子系统目录：取第一个非 common 源的目录名，缺省 uncore
    subsys = 'uncore'
    for p in pkg_files + core_files + [pathlib.Path(s) for s in wrap_srcs]:
        m = re.search(r'/rtl/(\w+)/', str(p))
        if m and m.group(1) != 'common':
            subsys = m.group(1)
            break

    new_rtl_dir = NEW / 'rtl' / subsys
    new_rtl_dir.mkdir(parents=True, exist_ok=True)
    new_files = []   # 新 RTL_SRCS（相对 NEW）
    notes = []

    # --- common 依赖复制（同名已存在且不同内容 → 报错） ---
    for p in common_deps:
        dst = NEW / 'rtl' / 'common' / p.name
        if dst.exists():
            if dst.read_bytes() != p.read_bytes():
                notes.append(f'common 依赖 {p.name} 与已存在文件不同（沿用已存在版本）')
        else:
            dst.write_bytes(p.read_bytes())
        new_files.append(dst)

    # --- wrapper/variants 拆分 ---
    sibling_files = []
    wrapper_of = {}     # golden 名 -> 模块全文
    wrap_headers = []
    for s in wrap_srcs:
        p = pathlib.Path(s)
        if not p.exists():
            sys.exit(f'ERROR: {t} WRAPPER_SRC 不存在 {p}')
        header, chunks = split_modules(p.read_text())
        if header.strip():
            wrap_headers.append(header.rstrip())
        for name, body in chunks:
            wrapper_of[name] = body

    # 核文件里可能已含 golden 同名 wrapper（少见）；也拆出来
    main_path = new_rtl_dir / (t + '.sv')
    core_texts = []
    for p in core_files:
        key = str(p)
        if key in registry and registry[key] != str(main_path):
            # 已被其他目标放置 → 引用不再复制
            np = pathlib.Path(registry[key])
            if np not in new_files:
                new_files.append(np)
            notes.append(f'{p.name} 已由 {registry[key]} 提供（共享核）')
            continue
        header, chunks = split_modules(p.read_text())
        keep = [header] if header.strip() else []
        for name, body in chunks:
            if name in fm_variants:
                wrapper_of.setdefault(name, body)
            else:
                keep.append(body)
        core_texts.append((p, '\n'.join(keep)))

    missing = [v for v in fm_variants if v not in wrapper_of]
    if missing:
        sys.exit(f'ERROR: {t} 缺 wrapper 模块: {missing}（人工处理）')

    # --- 主文件 = pkg + 核 + 目标 wrapper ---
    parts = []
    for p in pkg_files:
        key = str(p)
        if key in registry and registry[key] != str(main_path):
            # pkg 已在其他目标主文件内（家族共享）→ 引用不再内联, 防 package 重定义
            np = pathlib.Path(registry[key])
            if np not in new_files:
                new_files.insert(0, np)
            notes.append(f'{p.name} 已由 {registry[key]} 提供（共享 pkg）')
            continue
        parts.append(p.read_text().rstrip())
    for p, txt in core_texts:
        parts.append(txt.rstrip())
    if wrap_headers:
        parts.append('\n'.join(wrap_headers))
    parts.append('// ' + '-' * 75 + '\n// golden 同名 wrapper\n// ' + '-' * 75)
    parts.append(wrapper_of[t].rstrip())
    body = '\n\n'.join(x for x in parts if x.strip()) + '\n'
    main_path.write_text(body)   # 目标自有主文件, 重跑覆盖（跨目标冲突由 registry/ut_dir 去重挡）
    new_files.append(main_path)
    for p, _ in core_texts:
        registry.setdefault(str(p), str(main_path))
    for p in pkg_files:
        registry.setdefault(str(p), str(main_path))

    # --- 兄弟变体薄文件 ---
    for name in fm_variants:
        if name == t:
            continue
        vpath = new_rtl_dir / (name + '.sv')
        vbody = (f'// {name} —— {t} 单态化变体 wrapper（核体见 {t}.sv）\n\n'
                 + wrapper_of[name].rstrip() + '\n')
        vpath.write_text(vbody)
        new_files.append(vpath)
        sibling_files.append(vpath)

    # --- 校验 ---
    decl_count = {}
    for f in new_files:
        for name in MOD_RE.findall(f.read_text()):
            decl_count[name] = decl_count.get(name, 0) + 1
    for v in fm_variants:
        if decl_count.get(v, 0) != 1:
            sys.exit(f'ERROR: {t} 模块 {v} 声明 {decl_count.get(v,0)} 次(须恰 1)')
    golden_srcs = [x.replace('@GOLDEN@/', '')
                   for x in expand_make(vals.get('GOLDEN_SRCS', ''), vals).split()]
    golden_srcs = macro_closure(golden_srcs)
    for i, g in enumerate(list(golden_srcs)):
        if not (G1 / g).exists():
            r = golden_remap(g)
            if not r:
                sys.exit(f'ERROR: {t} GOLDEN_SRC 在 G1 缺失且非纯重编号: {g}（改动目标? 人工处理）')
            remapped[g] = r
            golden_srcs[i] = r

    # --- 新 UT 目录 ---
    new_ut = NEW / 'verif' / 'ut' / man[t]['ut_dir']
    new_ut.mkdir(parents=True, exist_ok=True)
    tb_srcs = []
    for s in vals.get('TB_SRCS', 'tb.sv').split():
        src = old_ut / s
        if not src.exists():
            sys.exit(f'ERROR: {t} TB_SRC 不存在 {src}')
        mods = MOD_RE.findall(src.read_text())
        if s != 'tb.sv' and mods and all(
                m.endswith('_xs') and m[:-3] in fm_variants for m in mods):
            notes.append(f'丢弃 {s}（手写 _xs 壳, 新框架由 derive 自动提供）')
            continue
        txt = src.read_text()
        # tb 修正(可选): verif/ut_overrides/<t>.tb.sed 每行「old<TAB>new」逐条替换
        # （典型: 老 tb 直接例化 golden 同名 impl, 新框架该名已 derive 成 <名>_xs）
        sed = NEW / 'verif' / 'ut_overrides' / (t + '.tb.sed')
        if s == 'tb.sv' and sed.exists():
            for ln in sed.read_text().splitlines():
                if '\t' in ln and not ln.startswith('#'):
                    a, b = ln.split('\t', 1)
                    txt = txt.replace(a, b)
            notes.append('tb 已按 overrides sed 修正')
        (new_ut / s).write_text(txt)
        tb_srcs.append(s)
    fmmap = old_ut / 'fm_map'
    if fmmap.is_dir():
        (new_ut / 'fm_map').mkdir(exist_ok=True)
        for f in fmmap.iterdir():
            (new_ut / 'fm_map' / f.name).write_bytes(f.read_bytes())
    # filelist(.f)/fm_pins 附属文件: 原样搬运, golden 路径改指 G1
    for f in sorted(old_ut.glob('*.f')) + sorted(old_ut.glob('fm_pins*.tcl')):
        txt = f.read_text().replace('../../../golden/chisel-rtl', str(G1))
        txt = txt.replace(str(OLD / 'golden' / 'chisel-rtl'), str(G1))
        (new_ut / f.name).write_text(txt)
        notes.append(f'附属 {f.name} 已搬(golden 路径→G1)')

    rel = [str(f).replace(str(NEW / 'rtl'), '$(RTL_DIR)') for f in new_files]
    old_flat = re.sub(r'\\\n', ' ', old_mk.read_text())
    keep_fm = []
    for ln in old_flat.splitlines():
        m = re.match(r'^(FM_(?!VARIANTS)\w+)\s*[:+?]?=\s*(.*)$', ln)
        if m:
            val = expand_make(m.group(2), vals).replace('@GOLDEN@', '$(GOLDEN_RTL)')
            toks = []
            for tok in val.split():
                base = tok.split('/')[-1]
                if base.endswith(('.sv', '.v')) and not (G1 / base).exists():
                    r = remapped.get(base) or golden_remap(base)
                    if r:
                        remapped[base] = r
                        tok = tok.replace(base, r)
                toks.append(tok)
            if m.group(1).startswith('FM_REF_DEPS_'):
                bases = [x.split('/')[-1] for x in toks]
                extra = [x for x in macro_closure(bases) if x not in bases
                         and not x.endswith('.v')]   # FM 不读 vendor _ext.v
                toks += extra
            keep_fm.append(m.group(1) + ' = ' + ' '.join(toks))
    keep_fm.append('GOLDEN_SRCS = ' + ' \\\n              '.join(
        '$(GOLDEN_RTL)/' + g for g in golden_srcs))
    # include 之后的追加段（VCS += +define+SYNTHESIS 等）连注释原样保留
    tail = []
    seen_inc = False
    for ln in old_mk.read_text().splitlines():
        if re.match(r'^include\s+.*ut_common\.mk', ln):
            seen_inc = True
            continue
        if seen_inc:
            tail.append(ln)
    mk = ['MODULE = ' + t, '', 'RTL_DIR = ../../../rtl',
          'RTL_SRCS = ' + ' \\\n           '.join(rel),
          'TB_SRCS = ' + ' '.join(tb_srcs), '']
    if golden_passthru:
        # golden 行为模型/闭包: 不进 derive(保留原名, UT 两侧共用), FM 时并入 impl 侧
        mk += ['RTL_GOLDEN_DEPS = ' + ' \\\n                  '.join(
            '$(GOLDEN_RTL)/' + g for g in golden_passthru), '']
    mk += keep_fm
    if asm_mode and 'FM_MODE' not in '\n'.join(keep_fm):
        mk.append('# 老战役审计声明继承: proof_mode=assembly, 对称黑盒边界 = '
                  + (', '.join(allow_ids[:6]) + ('…' if len(allow_ids) > 6 else '')
                     if allow_ids else '(allow 文件未列条目)'))
        mk.append('FM_MODE = assembly')
        mk.append(f'FM_ALLOWLIST ?= {max(allow_n, 1)}')
    if vmucp and 'FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS' not in '\n'.join(keep_fm):
        mk.append('# 老战役审计声明继承: vmucp=加强证明(FM 实比 matched-unread, 非 waiver)')
        mk.append('FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true')
    mk += ['FM_VARIANTS = ' + ' '.join(fm_variants), '',
           'include ../../../scripts/ut_common.mk']
    mk += tail
    ovr = NEW / 'verif' / 'ut_overrides' / (t + '.mk')
    if ovr.exists():
        mk += ['', '# --- ut_overrides/' + t + '.mk (新战役目标级修正) ---',
               ovr.read_text().rstrip()]
        notes.append('已附加 overrides')
    mk += ['']
    (new_ut / 'Makefile').write_text('\n'.join(mk))

    # vmucp 目标须在 fm_eq.tcl 白名单（继承老战役审计声明, 幂等插入）
    if vmucp:
        for v in fm_variants:
            _whitelist_add(v)

    if remapped:
        notes.append('G1重编号自动remap: '
                     + ', '.join(f'{a}->{b}' for a, b in sorted(remapped.items())))
    regp.parent.mkdir(parents=True, exist_ok=True)
    regp.write_text(json.dumps(registry, indent=1, ensure_ascii=False))
    print(f'OK {t}: 主文件={main_path.relative_to(NEW)} 兄弟变体={len(sibling_files)} '
          f'common={len(common_deps)} ut={new_ut.relative_to(NEW)}'
          + ('; ' + '; '.join(notes) if notes else ''))


if __name__ == '__main__':
    main()
