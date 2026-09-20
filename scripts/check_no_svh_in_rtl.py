#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""闸：`rtl/` 下不许有 `.svh`，也不许有 `` `include ``。

为什么要有这道闸
----------------
CONVENTIONS「单文件规范」明文禁止 `.svh` include，理由是上一轮的教训：
用 svh 套壳把 golden 原文藏进 include 蒙混验收。

**但禁令一直没有闸，靠的是"没人加过"。** 2026-09-18 实测本轮 `rtl/` 下确实
0 个 `.svh` —— 规范在事实上成立，但那是运气不是机制。

真正的危险由上一轮的审计量出来了，而且**和当初设想的不是同一回事**：

  上一轮 202 个 .svh / 199,801 非注释行，逐字抄 golden 的**实质逻辑行只有 1.83%**，
  而 .sv 同口径是 8.19% —— ★.svh 的照抄密度只有 .sv 的一半★。
  所以"svh 是 golden 原文的藏身处"这个假设**是错的**。

  .svh 真正的问题更隐蔽：那 204,373 行（占上一轮 rtl 的 29%）**整体绕过了可读性闸** ——
  `readability_audit.py` 与 `prev_round_verbatim_scan.py` 都只 `rglob('*.sv')`
  （后者 manifest 的 n_files: 909 就是证据，正好是 .sv 的个数）。
  ★是审计盲点，不是藏赃点。★

本轮 `scripts/readability_audit.py` 至今仍只 `rglob('*.sv')`（第 81、313 行），
也就是说**同一个盲点机制在本轮原样存在**：只要有人在 rtl/ 下放一个 .svh，
可读性审计就会静默跳过它。与其去改那个大脚本（风险高），不如在源头堵死：
rtl/ 下根本不许出现 .svh，那么"只扫 .sv"就等于扫全了。

判据
----
A  `rtl/` 下不存在 `.svh` 文件（tracked 或未跟踪都算）
B  `rtl/` 下的 `.sv` 里不出现 `` `include ``
   （即使 include 的是 .sv，也会把内容从"一个模块一个文件"里拆走，同样绕过按文件的审计）

用法:
    python3 scripts/check_no_svh_in_rtl.py
退出码 0 = 通过。
"""
import os
import re
import sys

INCLUDE = re.compile(r'^\s*`include\b')


def main():
    root = 'rtl'
    if not os.path.isdir(root):
        print('check_no_svh_in_rtl: 跳过 —— 没有 rtl/ 目录')
        return 0

    svh = []
    inc = []
    for dp, _dn, fns in os.walk(root):
        for fn in fns:
            p = os.path.join(dp, fn)
            if fn.endswith('.svh'):
                svh.append(p)
            elif fn.endswith('.sv'):
                try:
                    with open(p, encoding='utf-8', errors='replace') as f:
                        for n, line in enumerate(f, 1):
                            if INCLUDE.match(line):
                                inc.append((p, n, line.rstrip()))
                except OSError:
                    pass

    bad = False
    if svh:
        bad = True
        print('check_no_svh_in_rtl: 判据 A 失败 —— rtl/ 下有 %d 个 .svh' % len(svh),
              file=sys.stderr)
        for p in sorted(svh)[:10]:
            print('    %s' % p, file=sys.stderr)
        if len(svh) > 10:
            print('    ...还有 %d 个' % (len(svh) - 10), file=sys.stderr)
    if inc:
        bad = True
        print('check_no_svh_in_rtl: 判据 B 失败 —— rtl/ 的 .sv 里有 %d 处 `include'
              % len(inc), file=sys.stderr)
        for p, n, l in inc[:10]:
            print('    %s:%d  %s' % (p, n, l.strip()), file=sys.stderr)
        if len(inc) > 10:
            print('    ...还有 %d 处' % (len(inc) - 10), file=sys.stderr)

    if bad:
        print('', file=sys.stderr)
        print('修法：按 CONVENTIONS「单文件规范」把内容收进那个模块自己的 .sv；',
              file=sys.stderr)
        print('      机械派生区用 scripts/gen_*.py 生成并用',
              file=sys.stderr)
        print('      // BEGIN GENERATED(<tag>) / // END GENERATED 原地标记，而不是拆成 include。',
              file=sys.stderr)
        return 1

    print('check_no_svh_in_rtl: OK —— rtl/ 下无 .svh、无 `include')
    return 0


if __name__ == '__main__':
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    sys.exit(main())
