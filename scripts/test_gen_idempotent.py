#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_gen_idempotent.py —— 每个 verif/ut/*/gen.py 重跑一遍，产物必须逐字不变。

## 为什么要这道闸

本轮已经踩过两次同一个病，形态完全一样：

  - `gen_tlbuffer_ad_family.py`：negtest 段是**手工贴在生成产物后面**的，谁跑一次
    生成器它就被静默删掉 —— 而那正是该家族唯一病因形态（位宽）的防护。
  - `gen_sram_wrappers.py`：33 个薄文件里的 6 个 `G1_*` 锚点、以及 UT Makefile 的
    negtest 段，同样是手工补在生成产物上的，重跑即全没。

两次都是**并回生成器**才修好的。修好之后给那两个挂了 `--check`，但 `verif/ut/*/gen.py`
这一层 9 个生成器里只有 1 个有 `--check`，剩下 8 个照样是敞口。

## 判据

在 HEAD 上开一个 detached worktree（不碰活动工作树），逐个跑 `gen.py`，跑完
`git status --porcelain` 必须为空。非空 = 库里那份产物与生成器**现在**会生成的不一致，
两种可能都必须当成错：

  (a) 有人手工改了生成产物 —— 下次谁跑生成器就静默丢失；
  (b) 有人改了生成器却没并回产物 —— 库里的 RTL 与生成器已经脱节。

## 已知边界（不藏着）

它验的是 **HEAD 的字节**，不是活动工作树。所以"手改产物但还没提交"这一刻它看不见，
要到下一次跑闸才报。这是刻意的取舍：证明与台账在本工程里一律钉 committed 字节
（见 scripts/run_proof.sh 的同一条理由），而且把 1.3 GiB 的 verif/ 整份拷出来跑
代价太大。它的作用是把"静默永久损坏"变成"下一轮必然变红"。

用法: python3 scripts/test_gen_idempotent.py
"""
import pathlib
import shutil
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent


def sh(args, cwd, env=None):
    return subprocess.run(args, cwd=str(cwd), env=env,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT)


def main():
    gens = sorted(REPO.glob('verif/ut/*/gen.py'))
    if not gens:
        print('test_gen_idempotent: 一个 gen.py 都没找到——闸空转，按失败处理')
        return 1

    wt = pathlib.Path(tempfile.mkdtemp(prefix='xsv2-genidem-'))
    shutil.rmtree(str(wt))                       # worktree add 要求目录不存在
    r = sh(['git', 'worktree', 'add', '--detach', str(wt), 'HEAD'], REPO)
    if r.returncode != 0:
        print('test_gen_idempotent: 建 worktree 失败\n' + r.stdout.decode('utf-8', 'replace'))
        return 1

    import os
    env = dict(os.environ, XSSV_HOME=str(wt), XSSV_INDEX_HOME=str(REPO))
    bad = []
    try:
        for g in gens:
            d = wt / g.relative_to(REPO).parent
            r = sh([sys.executable, 'gen.py'], d, env)
            if r.returncode != 0:
                bad.append('%s 跑挂了 (rc=%d)：%s'
                           % (g.relative_to(REPO), r.returncode,
                              r.stdout.decode('utf-8', 'replace').strip()[-300:]))
                continue
            st = sh(['git', 'status', '--porcelain'], wt).stdout.decode('utf-8', 'replace')
            if st.strip():
                bad.append('%s 重跑后产物变了（库里那份不是它生成的）：\n    %s'
                           % (g.relative_to(REPO),
                              '\n    '.join(st.strip().splitlines()[:8])))
                sh(['git', 'checkout', '--', '.'], wt)
                sh(['git', 'clean', '-fdq'], wt)
    finally:
        sh(['git', 'worktree', 'remove', '--force', str(wt)], REPO)

    if bad:
        print('test_gen_idempotent: %d/%d 个生成器不幂等：' % (len(bad), len(gens)))
        for b in bad:
            print('  - ' + b)
        return 1
    print('test_gen_idempotent: %d 个 verif/ut/*/gen.py 重跑后产物逐字不变' % len(gens))
    return 0


if __name__ == '__main__':
    sys.exit(main())
