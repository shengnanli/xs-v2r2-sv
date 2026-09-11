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


def parse_makefile(text):
    """解析 make 变量（支持行继续），返回 dict。"""
    text = re.sub(r'\\\n', ' ', text)
    vals = {}
    for m in re.finditer(r'^(\w+)\s*[:+?]?=\s*(.*)$', text, re.MULTILINE):
        k, v = m.group(1), m.group(2).strip()
        vals[k] = (vals.get(k, '') + ' ' + v).strip() if k in vals else v
    return vals


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
    old_mk = OLD / man[t]['makefile']
    old_ut = old_mk.parent
    vals = parse_makefile(old_mk.read_text())

    def expand(v):
        v = v.replace('$(RTL_DIR)', str(OLD / 'rtl'))
        return [x for x in v.split() if x]

    rtl_srcs = expand(vals.get('RTL_SRCS', ''))
    wrap_srcs = expand(vals.get('WRAPPER_SRCS', ''))
    fm_variants = vals.get('FM_VARIANTS', '').split()
    if not fm_variants:
        sys.exit(f'ERROR: {t} 老 Makefile 无 FM_VARIANTS')

    # --- 分拣源文件 ---
    common_deps, pkg_files, core_files = [], [], []
    for s in rtl_srcs:
        p = pathlib.Path(s)
        if not p.exists():
            sys.exit(f'ERROR: {t} RTL_SRC 不存在 {p}')
        if '/rtl/common/' in str(p):
            common_deps.append(p)
        elif p.name.endswith('_pkg.sv'):
            pkg_files.append(p)
        else:
            core_files.append(p)

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
        parts.append(p.read_text().rstrip())
    for p, txt in core_texts:
        parts.append(txt.rstrip())
    if wrap_headers:
        parts.append('\n'.join(wrap_headers))
    parts.append('// ' + '-' * 75 + '\n// golden 同名 wrapper\n// ' + '-' * 75)
    parts.append(wrapper_of[t].rstrip())
    body = '\n\n'.join(x for x in parts if x.strip()) + '\n'
    if main_path.exists() and main_path.read_text() != body:
        sys.exit(f'ERROR: {main_path} 已存在且内容不同（人工处理）')
    main_path.write_text(body)
    new_files.append(main_path)
    for p, _ in core_texts:
        registry[str(p)] = str(main_path)
    for p in pkg_files:
        registry[str(p)] = str(main_path)

    # --- 兄弟变体薄文件 ---
    for name in fm_variants:
        if name == t:
            continue
        vpath = new_rtl_dir / (name + '.sv')
        vbody = (f'// {name} —— {t} 单态化变体 wrapper（核体见 {t}.sv）\n\n'
                 + wrapper_of[name].rstrip() + '\n')
        if vpath.exists() and vpath.read_text() != vbody:
            sys.exit(f'ERROR: {vpath} 已存在且内容不同')
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
    golden_srcs = vals.get('GOLDEN_SRCS', '')
    for g in golden_srcs.replace('$(GOLDEN_RTL)/', '').split():
        if not (G1 / g).exists():
            sys.exit(f'ERROR: {t} GOLDEN_SRC 在 G1 缺失: {g}（改动目标? 人工处理）')

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
        (new_ut / s).write_bytes(src.read_bytes())
        tb_srcs.append(s)
    fmmap = old_ut / 'fm_map'
    if fmmap.is_dir():
        (new_ut / 'fm_map').mkdir(exist_ok=True)
        for f in fmmap.iterdir():
            (new_ut / 'fm_map' / f.name).write_bytes(f.read_bytes())

    rel = [str(f).replace(str(NEW / 'rtl'), '$(RTL_DIR)') for f in new_files]
    old_flat = re.sub(r'\\\n', ' ', old_mk.read_text())
    keep_fm = []
    for ln in old_flat.splitlines():
        if re.match(r'^(FM_(?!VARIANTS)\w+|GOLDEN_SRCS)\s*[:+?]?=', ln):
            keep_fm.append(ln)
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
    mk += keep_fm
    mk += ['FM_VARIANTS = ' + ' '.join(fm_variants), '',
           'include ../../../scripts/ut_common.mk']
    mk += tail + ['']
    (new_ut / 'Makefile').write_text('\n'.join(mk))

    regp.parent.mkdir(parents=True, exist_ok=True)
    regp.write_text(json.dumps(registry, indent=1, ensure_ascii=False))
    print(f'OK {t}: 主文件={main_path.relative_to(NEW)} 兄弟变体={len(sibling_files)} '
          f'common={len(common_deps)} ut={new_ut.relative_to(NEW)}'
          + ('; ' + '; '.join(notes) if notes else ''))


if __name__ == '__main__':
    main()
