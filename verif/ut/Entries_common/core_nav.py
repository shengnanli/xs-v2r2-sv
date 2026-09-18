#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""core_nav.py —— 重算/校验 xs_iq_entries_core.sv 的文件头导航行号。

## 为什么单独做个工具

核是手写的（不是生成产物），1700 多行，按裁定不拆，所以必须配文件头导航。
`scripts/readability_audit.py` 的判据 E 会**按行号**核对导航条目是否真的落在
分节注释上 —— 往核里插一行就红，而那道闸接在 run_proof.sh 上：导航烂了会直接
拒绝出证明。手工维护这张表必然腐烂（本轮已经因此被拦过）。

所以：分节标题在核里是唯一的事实来源，这个脚本只负责把行号重算回去。

    python3 core_nav.py            # 重写导航
    python3 core_nav.py --check    # 只校验（非零退出 = 已腐烂）

新增分节时，在核里写好 `// §X …` 注释后跑一次本脚本即可，不要手改导航。
"""
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parents[3]
CORE = REPO / 'rtl' / 'backend' / 'xs_iq_entries_core.sv'

# 分节注释的形态：行首若干空格 + "// §<编号> <标题>"。
# 标题里可能带补充说明（"—— …"），导航只取到行尾。
SEC_RE = re.compile(r'^(\s*)//\s+(§[0-9]+[a-z]?(?:\.[0-9]+[a-z]?)?)\s+(.*)$')


def sections(lines):
    """按出现顺序抠出所有分节标题 -> [(行号(1-based), 标题全文)]。"""
    out = []
    for i, line in enumerate(lines):
        m = SEC_RE.match(line)
        if not m:
            continue
        # 只认「注释框里的分节标题」：上一行是分隔线，或它是 module/package 的大标题
        prev = lines[i - 1] if i else ''
        # 只认「注释框里的分节标题」：上一行必须是分隔线（---- 或 ==== 都算）
        if not (set(prev.strip()) <= set('/-= ') and len(prev.strip()) > 8):
            continue
        # 标题后面常跟一大段说明（往往跨行）。导航是一行一条，所以截到第一个
        # 破折号/句号之前；都没有就按长度截 —— 宁可短，也不要把半句话搬进导航。
        title = m.group(3).rstrip()
        for sep in ('\u2014\u2014', '\u3002'):
            title = title.split(sep)[0].rstrip()
        if len(title) > 46:
            title = title[:46].rstrip() + '\u2026'
        title = (m.group(2) + ' ' + title).rstrip()
        out.append((i + 1, title))
    return out


def build(text):
    lines = text.split('\n')
    secs = sections(lines)
    assert secs, 'xs_iq_entries_core.sv: 一个分节注释都没找到'
    nav = ['// 本文件导航（共 %d 行；按"一个 golden 模块一个文件"的规范不拆分，'
           '用下面的分节定位）：' % len(lines)]
    nav += ['//   L%-5d %s' % (ln, title) for ln, title in secs]
    nav.append('// 导航由 verif/ut/Entries_common/core_nav.py 重算 —— 改完核跑一次，勿手改')
    start = text.index('// 本文件导航（共')
    end = text.index('//\n\n// ---', start)
    return text[:start] + '\n'.join(nav) + '\n' + text[end:]


def build_fixpoint(text):
    """导航本身占若干行，重写它会挪动后面所有分节的行号 —— 所以要迭代到不动点。

    不动点一定存在且很快收敛：条目数固定，只有"共 N 行"和各行号在变。
    收敛不了就报错，不要悄悄写一份自相矛盾的导航出去。
    """
    for _ in range(8):
        new = build(text)
        if new == text:
            return text
        text = new
    raise SystemExit('core_nav: 导航行号迭代 8 轮仍未收敛（分节注释形态异常？）')


def main():
    text = CORE.read_text()
    new = build_fixpoint(text)
    if '--check' in sys.argv:
        if new != text:
            sys.stderr.write('core_nav: 导航已腐烂，重跑 core_nav.py\n')
            return 1
        print('core_nav --check: PASS')
        return 0
    CORE.write_text(new)
    print(f'core_nav: 重写 {CORE}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
