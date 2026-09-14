#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""full_elab_classify.py —— 把整芯片 elaborate 的 VCS 日志按「问题类别」归纳。

整芯片第一次跑通常是几百条错误，逐条读没有意义；有意义的是**有几类、每类的根因
是什么、涉及哪些文件**——那才是下一轮能排任务的东西。

VCS 的每条诊断都带一个稳定的错误码（`Error-[SV-PPD]` / `Error-[MOI]` / …），
本脚本按错误码分组，给出每组的条数、涉及的模块/文件样本、以及一条人话解释
（解释表只覆盖本工程实际撞到过的码，没见过的码如实打「未归类」，不编）。
"""
import collections
import pathlib
import re
import sys

# ★ Lint- 也要收 ★：`+lint=TFIPC-L` 这类详细诊断以 `Lint-[...]` 开头，
# 只认 Error/Warning 会把 33 条 TFIPC-L 全部漏掉，摘要就在说假话。
CODE_RE = re.compile(r'^(Error|Warning|Lint)-\[([A-Z0-9_\-]+)\]\s*(.*)$')
# 只解释真见过的码；没见过的一律标「未归类」，不猜。
MEANING = {
    'SV-PPD':   'package 重名（package 名是全局的，两个文件定义同名包即冲突）',
    'MOI':      '模块被多次定义（重写件与 golden 件、或两个重写件同名）',
    'MPD':      '模块端口宽度/数量与例化不匹配',
    'IPDW':     '例化端口位宽与模块端口位宽不一致',
    'PCWM':     '例化端口连接宽度不匹配',
    'SV-LCM-PRTMM': '端口模式/类型不匹配',
    'DUPMOD':   '重复模块定义',
    'SE':       '语法错误',
    'UMI':      '例化了不存在的模块（缺件）',
    'IND':      '标识符未声明',
    'SV-UIOP':  '非法操作数',
    'TFIPC':    '例化连接的端口数少于模块定义（本工程形态：xs_*_core 是参数化**超集核**，'
                '某个变体用不到的可选端口没连；要确认没连的是输出还是输入）',
    'TFIPC-L':  '同 TFIPC，+lint=TFIPC-L 打开后的逐端口明细',
    'SIOB':     '数组下标越界选择（本工程形态：generate 里用 ?: 而不是 generate-if，'
                'genvar=0 时把 idx-1 算成 -1；常量折叠让它功能上没事，但是潜在 X 写法）',
    'OPD':      '同一个模块被读进来两次（源清单里同一文件出现两次），后一次覆盖前一次 —— '
                '通常是清单生成的问题，不是设计问题',
    'LCA_FEATURES_ENABLED': '用到需 -lca 的特性',
    'ACC_CLI_ON': '调试访问开启提示（非设计问题）',
}


def main():
    log = pathlib.Path(sys.argv[1])
    if not log.exists():
        print(f'日志不存在: {log}')
        return 2
    text = log.read_text(errors='replace')
    lines = text.splitlines()

    groups = collections.defaultdict(list)   # (sev, code) -> [首行 + 上下文]
    i = 0
    while i < len(lines):
        m = CODE_RE.match(lines[i].strip())
        if m:
            sev, code, rest = m.groups()
            ctx = [lines[i].strip()]
            j = i + 1
            while j < len(lines) and j - i < 8 and lines[j].strip() and not CODE_RE.match(lines[j].strip()):
                ctx.append(lines[j].rstrip())
                j += 1
            groups[(sev, code)].append(ctx)
            i = j
        else:
            i += 1

    n_err = sum(len(v) for (s, _), v in groups.items() if s == 'Error')
    n_warn = sum(len(v) for (s, _), v in groups.items() if s == 'Warning')
    n_lint = sum(len(v) for (s, _), v in groups.items() if s == 'Lint')
    print(f'=== 整芯片 elaborate 诊断归纳：{log} ===')
    print(f'Error 共 {n_err} 条 / Warning 共 {n_warn} 条 / Lint 共 {n_lint} 条，'
          f'分 {len(groups)} 类\n')

    for sev in ('Error', 'Warning', 'Lint'):
        sel = sorted(((c, v) for (s, c), v in groups.items() if s == sev),
                     key=lambda kv: -len(kv[1]))
        if not sel:
            continue
        print(f'--- {sev} ---')
        for code, items in sel:
            why = MEANING.get(code, '★未归类★（本工程此前没撞到过这个码）')
            print(f'[{sev}-{code}] × {len(items)}   —— {why}')
            # 涉及的文件（取上下文里出现的 .sv/.v 路径）
            files = collections.Counter()
            for ctx in items:
                for f in re.findall(r'[\w./+-]+\.s?v\b', '\n'.join(ctx)):
                    files[pathlib.Path(f).name] += 1
            if files:
                top = ', '.join(f'{k}×{v}' for k, v in files.most_common(6))
                print(f'      涉及文件(前6): {top}')
            for ctx in items[:2]:
                for l in ctx[:5]:
                    print(f'      | {l}')
                print('      |')
        print()

    tail = [l for l in lines[-40:] if l.strip()]
    print('--- 日志末尾 ---')
    for l in tail[-12:]:
        print('  ' + l)
    return 0


if __name__ == '__main__':
    sys.exit(main())
