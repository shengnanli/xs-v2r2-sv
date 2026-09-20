#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_gen_gate_complete.py —— scripts/gen_*.py 一个都不许漏出幂等闸。

## 由来

gate_all.sh 里的生成器幂等闸原本是**手工列举**三个文件名的 for 循环。它自己的注释
就写着「新加的生成器自动进闸，不会因为"忘了挂 --check"再敞一个口」——但那句话只对
`verif/ut/*/gen.py` 那一层成立（那层是统一重跑验的），对 `scripts/gen_*.py` 这一层
恰恰不成立：这层是逐个列名字的，忘了加就静默漏。

2026-09-17 实测：11 个 scripts/gen_*.py 里 6 个支持 --check，而闸里只列了 3 个，
**gen_ndaux.py / gen_npc_missing3.py / gen_splittedsram.py 三个一直在闸外**，
三个都能跑通、都是幂等的——也就是说漏的不是坏文件，是"没人记得加"。

## 判据（fail-closed）

把每个 scripts/gen_*.py 分成两类，两类都必须**显式落账**：
  · 支持 --check 的  -> 必须出现在 gate_all.sh 的被闸列表里
  · 不支持 --check 的 -> 必须出现在本文件的 NO_CHECK 豁免表里，且写明理由

任何一个既不在闸里、也不在豁免表里的，直接非零退出。新加一个生成器时，
要么给它挂 --check 并进闸，要么来这里写一行为什么不需要——两条路都留痕，
没有"什么都不做"这条路。

用法: python3 scripts/check_gen_gate_complete.py
"""
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GATE = REPO / 'scripts' / 'gate_all.sh'

# 不支持 --check 的生成器，逐个写明为什么不需要幂等闸。
# 理由必须是"产物不进证明闭包"或"本来就不是幂等生成"，不能是"还没来得及做"。
NO_CHECK = {
    'gen_dm_wrappers.py':  '一次性脚手架：DebugModule 薄 wrapper 已落库并手工改过，生成器不再是产物的真来源',
    'gen_file_nav.py':     '写的是源文件头部导航注释（行号），不产出任何进证明闭包的字节',
    'gen_g1_manifest.py':  '产物是 golden 清单快照，输入是只读的 G1-canonical，幂等性由 G1 的 chmod a-w 保证',
    'gen_mbist_ut.py':     '产出 UT 脚手架，已由 scripts/test_gen_idempotent.py 在 verif/ut/* 那一层统一重跑验过',
    'gen_zj_ut.py':        '同上：产出 UT 脚手架，归 test_gen_idempotent.py 那一层管',
}


def gated_generators():
    """从 gate_all.sh 里解析出被逐个挂闸的 scripts/gen_*.py。"""
    txt = GATE.read_text(encoding='utf-8', errors='replace')
    return set(re.findall(r'scripts/(gen_[A-Za-z0-9_]+\.py)', txt))


def main():
    gated = gated_generators()
    fails = []
    ok_gated, ok_exempt = [], []

    for p in sorted((REPO / 'scripts').glob('gen_*.py')):
        name = p.name
        has_check = '--check' in p.read_text(encoding='utf-8', errors='replace')
        if has_check:
            if name in gated:
                ok_gated.append(name)
            else:
                fails.append('★%s 支持 --check 却不在 gate_all.sh 的闸里★' % name)
        else:
            if name in NO_CHECK:
                ok_exempt.append(name)
            else:
                fails.append('★%s 既没有 --check、也没在 NO_CHECK 里写明理由★' % name)

    # 豁免表不许有幽灵条目：文件没了/后来挂上 --check 了，都要清掉
    for name in sorted(NO_CHECK):
        p = REPO / 'scripts' / name
        if not p.exists():
            fails.append('NO_CHECK 里的 %s 已不存在，清掉这一行' % name)
        elif '--check' in p.read_text(encoding='utf-8', errors='replace'):
            fails.append('NO_CHECK 里的 %s 现在支持 --check 了，应改为进闸' % name)

    if fails:
        print('check_gen_gate_complete: ★%d 条不过★' % len(fails))
        for f in fails:
            print('  - ' + f)
        return 1
    print('check_gen_gate_complete: %d 个进闸 / %d 个显式豁免，无漏网'
          % (len(ok_gated), len(ok_exempt)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
