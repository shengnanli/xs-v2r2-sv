#!/usr/bin/env python3
"""test_no_location_dependency.py —— 禁止按「仓库父目录」解析 golden。

**为什么**（2026-09-14 实测）：`scripts/declare_allow.py` 曾按仓库父目录拼 canonical ID 路径，
于是把仓库克隆到别处（哪怕只为在 clean clone 里跑一遍测试）就 FileNotFoundError，
而 `XSSV_HOME` 绕不开 —— 它设的是仓库根，代码取的是它的父目录。**克隆位置成了承重结构**。
修法是绝对默认 + 可覆盖 flag（`--canonical-id`），与 boundary_ledger.py 一致。本测试防它退化。

★为什么用 AST 而不是 grep★：第一版用行级文本扫描，当场抓到了**它自己**——docstring 里
的举例、检测逻辑里的模式串、探针里的字符串，四处全中。纯文本分不清「代码在这么做」与
「文档在说这件事」。AST 分得清：违规形态是**属性访问** `.parent` 与**字符串常量**
'G1-canonical' 同处一个表达式；而检测逻辑里的 `'.parent'` 是字符串常量、不是属性访问。
"""
import ast
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
CANON_DIRS = ('G1-canonical', 'G0-canonical')
PASS, FAIL = [], []


def violations(path):
    """[(行号, 源码片段)] —— 真代码里按父目录拼 canonical 路径的表达式。"""
    try:
        tree = ast.parse(path.read_text(errors='replace'), str(path))
    except SyntaxError as e:
        return None, 'SyntaxError: %s' % e
    src = path.read_text(errors='replace').splitlines()
    out = []
    for node in ast.walk(tree):
        # 只看表达式子树：其中同时含 Attribute(attr='parent') 与 canonical 目录名常量
        if not isinstance(node, (ast.BinOp, ast.Call, ast.Attribute, ast.Subscript)):
            continue
        has_parent = any(isinstance(n, ast.Attribute) and n.attr == 'parent'
                         for n in ast.walk(node))
        if not has_parent:
            continue
        has_canon = any(isinstance(n, ast.Str) and n.s in CANON_DIRS
                        for n in ast.walk(node))
        if has_canon:
            ln = getattr(node, 'lineno', 0)
            out.append((ln, src[ln - 1].strip()[:90] if 0 < ln <= len(src) else ''))
    # 同一表达式会被外层节点重复命中，按行去重
    return sorted({ln: t for ln, t in out}.items()), None


print('=== 扫描 scripts/ 下全部 .py ===')
files = sorted(HERE.glob('*.py'))
bad = []
for f in files:
    v, err = violations(f)
    if err:
        FAIL.append('%s: %s' % (f.name, err))
        print('  FAIL  %s: %s' % (f.name, err))
    elif v:
        bad.append((f.name, v))
if bad:
    FAIL.append('按父目录解析 canonical: ' + ', '.join(n for n, _ in bad))
    for n, v in bad:
        print('  FAIL  %s' % n)
        for ln, txt in v:
            print('          :%d  %s' % (ln, txt))
else:
    PASS.append('N1')
    print('  ok    N1  %d 个脚本，无一按父目录解析 canonical' % len(files))


def probe(name, body, want_hit, label):
    p = HERE / name
    try:
        p.write_text(body)
        v, err = violations(p)
        ok = (bool(v) == want_hit) and not err
        (PASS if ok else FAIL).append(label.split()[0])
        print('  %s  %s  (命中 %d 处)' % ('ok  ' if ok else 'FAIL', label,
                                          len(v) if v else 0))
    finally:
        if p.exists():
            p.unlink()


# ★对照★：种真违规必须抓到 —— 否则 N1 可能是空转。
probe('_loc_probe_a.py',
      "import pathlib\nNEW = pathlib.Path('.')\n"
      "x = (NEW.parent / 'G1-canonical' / 'CANONICAL_ID.txt').read_text()\n",
      True, 'N2 对照：种入真违规必须被抓')

# ★对照★：只在注释/文档里提及不算违规（第一版正是死在这里）。
probe('_loc_probe_b.py',
      '"""说明：曾用 NEW.parent / \'G1-canonical\' / \'CANONICAL_ID.txt\'。"""\n'
      "# 同样的话再写一遍：NEW.parent / 'G1-canonical'\n"
      "x = 1\n",
      False, 'N3 对照：仅注释/文档提及不算违规')

# ★对照★：绝对路径默认值不算违规（正是我们要的写法）。
probe('_loc_probe_c.py',
      "DEFAULT = '/home/eda/xs-env/G1-canonical/CANONICAL_ID.txt'\n"
      "import argparse\nap = argparse.ArgumentParser()\n"
      "ap.add_argument('--canonical-id', default=DEFAULT)\n",
      False, 'N4 对照：绝对默认+flag 的正确写法不报')

print()
print('PASS %d / FAIL %d' % (len(PASS), len(FAIL)))
sys.exit(1 if FAIL else 0)
