#!/usr/bin/env python3
"""test_audit_ram_manual_review.py —— M3 MANUAL_REVIEWED 窄出口的负测（codex 0203 裁定 X）。

正样本：当前仓里 ram_10x89 的真实绑定必须通过。
负测（每条都必须**不通过**）：
  N1 去掉消息号
  N2 消息号不对（换成别的 codex 号）
  N3 绑定文件 sha256 改一位（等价于「改任一绑定字节」）
  N4 绑定里没有 parent_impl 本身
  N5 design 不在硬编码名单里（名单不读 tsv，不推广到其它 ram_*）
  N6 绑定项格式坏（没有 =）
  N7 绑定了不存在的文件
用法: python3 scripts/test_audit_ram_manual_review.py
"""
import hashlib
import os
import pathlib
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import audit_ram_memory_model as A  # noqa: E402

REPO = A.REPO
IMPL = 'rtl/uncore/Queue10_GrantBuffer_Anon.sv'
CORE = 'rtl/common/xs_ChiselQueue_core.sv'


def sha(p):
    return hashlib.sha256((REPO / p).read_bytes()).hexdigest()


def flip(h):
    return ('0' if h[0] != '0' else '1') + h[1:]


def main():
    good = f'codex_0202;{IMPL}={sha(IMPL)};{CORE}={sha(CORE)}'
    impl_path = str(REPO / IMPL)
    cases = [
        ('P0 真实绑定通过', 'ram_10x89', good, True),
        ('N1 去掉消息号', 'ram_10x89', f'{IMPL}={sha(IMPL)};{CORE}={sha(CORE)}', False),
        ('N2 消息号不对', 'ram_10x89', good.replace('codex_0202', 'codex_0199'), False),
        ('N3 绑定字节变了', 'ram_10x89', good.replace(sha(CORE), flip(sha(CORE))), False),
        ('N4 绑定不含 parent_impl', 'ram_10x89', f'codex_0202;{CORE}={sha(CORE)}', False),
        ('N5 design 不在名单', 'ram_16x25', good, False),
        ('N6 绑定项格式坏', 'ram_10x89', f'codex_0202;{IMPL}', False),
        ('N7 绑定不存在的文件', 'ram_10x89', good + ';rtl/nope/none.sv=' + '0' * 64, False),
    ]
    fails = []
    for name, design, review, want in cases:
        ok, msg = A.check_manual_review(design, review, impl_path)
        good_ = (ok is True) == want
        print(f'  {name:28s} {"ok" if good_ else "★FAIL★"}  {msg[:90]}')
        if not good_:
            fails.append(name)
    if fails:
        print(f'test_audit_ram_manual_review: ★{len(fails)} 条不过★ {fails}')
        return 1
    print('test_audit_ram_manual_review: 全过（1 正样本 + 7 负测）')
    return 0


if __name__ == '__main__':
    sys.exit(main())
