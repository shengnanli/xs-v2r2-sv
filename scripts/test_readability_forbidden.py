#!/usr/bin/env python3
"""可读性 A 类禁用命名正则的对照测试（2026-09-20）。

缘起：旧正则 r'\b_(GEN|T)(_\d+)?\b' 的前导 \b 让**加了前缀的展平中间名**从闸底下走过去。
Rob lane 在生成器里实测到核端口名会长成 `n__GEN_3539` / `GEN_3539` / `dispatchNum_T`。

★这道测试存在的理由★：收紧前后在当时全部 rtl/*.sv 上都命中 0。
「跑一遍没红」对这次改动完全没有分辨力——两个正则在真实代码上表现一样。
有分辨力的只有下面这张对照表，所以判据钉在这里，不钉在"仓库扫一遍"。
参见 CONVENTIONS.md ★判据也必须先自证它看得见改变★。
"""
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from readability_audit import FORBIDDEN

MUST_CATCH = [
    ('_GEN_12',        '裸展平名，旧正则也抓得到'),
    ('_T_18',          '同上'),
    ('x._GEN_1',       '层次引用里的，旧正则也抓得到'),
    ('n__GEN_3539',    '★加前缀 n_ —— 旧正则漏★'),
    ('GEN_3539',       '★无前导下划线 —— 旧正则漏★'),
    ('dispatchNum_T',  '★_T 无数字后缀 —— 旧正则漏★'),
    ('wire n__T_7;',   '★加前缀的 _T_<n> —— 旧正则漏★'),
]
MUST_NOT = [
    'GENERIC', 'my_GENERATOR', 'TOKEN', 'xs_TLB',
    'GEN', 'T', 'width_TOTAL', 'io_T0', 'ENTRY_GEN_CFG',
]

def main():
    bad = []
    for s, why in MUST_CATCH:
        if not FORBIDDEN.search(s):
            bad.append('★漏★ 应当抓住但没抓住: %-16s (%s)' % (repr(s), why))
    for s in MUST_NOT:
        if FORBIDDEN.search(s):
            bad.append('★误报★ 正常名字被判禁用: %s' % repr(s))
    if bad:
        print('test_readability_forbidden: %d 条不过' % len(bad))
        for b in bad:
            print('  ' + b)
        return 1
    print('test_readability_forbidden: %d 正例 / %d 反例 全过'
          % (len(MUST_CATCH), len(MUST_NOT)))
    return 0

if __name__ == '__main__':
    sys.exit(main())
