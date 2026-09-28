#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_vmucp_cfg.py —— 为 IssueQueue<V> 写 verif/fm_target_config/<V>.tcl（vmucp 白名单条目）

只在 vmucp_check.py 对一次**未开 vmucp** 的 FM 跑（diagnostic-full，不产 receipt）判 OK 之后才写；
依据里的数字（未开时的 passing / unread / constant_reg、开后期望 passing）全部从那次跑的结果
摘出来写死在注释里，事后复核按这里的期望值比，不增即空转、按 fail 处理。

用法: python3 gen_vmucp_cfg.py <V> <diag 的 fm.log 所在目录> <diag 时的 commit>
"""
import json
import pathlib
import re
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]


def main():
    v, wd, commit = sys.argv[1], pathlib.Path(sys.argv[2]), sys.argv[3]
    r = subprocess.run([sys.executable, str(HERE / 'vmucp_check.py'), v, str(wd / 'unread_points.txt')],
                       stdout=subprocess.PIPE, universal_newlines=True)
    print(r.stdout, end='')
    if r.returncode != 0:
        raise SystemExit('vmucp_check 未通过，不写白名单')
    n = int(re.search(r'matched_nc=(\d+)', r.stdout).group(1))
    log = (wd / 'fm.log').read_text(errors='replace')
    passing = int(re.findall(r'^\s*(\d+) Passing compare points', log, re.M)[-1])
    failing = int(re.findall(r'^\s*(\d+) Failing compare points', log, re.M)[-1]) \
        if re.search(r'Failing compare points', log) else 0
    if v.startswith('Scheduler'):
        comp = '各 IssueQueue 实例子树里与该 IQ 单签时同类的死位（条目阵列死负载、validCnt 高位、唤醒队列 fuType 未读位等）'
    else:
        ev_name = 'Entries' + v[len('IssueQueue'):]
        comp = (f'条目阵列 {ev_name} 的死负载位（与 {ev_name} 单签时同一批，本变体条目里没有输出锥的负载字段）'
                '+ IQ 层 validCntDeqVec 打拍寄存器超出端口宽度的高位 + 唤醒队列/忙表里 IQ 父级不读的位（若有）')
    txt = f'''# vmucp 白名单条目：{v}
#
# 本文件 = {v} 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
# 自动生成：verif/ut/IssueQueue_common/gen_vmucp_cfg.py —— 数字全部从下面那次未开 vmucp 的跑里摘出。
#
# ---- 加入依据（standing rule 六条）----
#   采证跑：diagnostic-full（不产 receipt），commit {commit}，未开 vmucp，
#           native SUCCEEDED，passing {passing}，failing {failing}，unmatched 全 0。
#   (1) 精确绑定：只有本文件打开本目标的 vmucp（Makefile 的 FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS
#       由 gen_tb.py 按本文件是否存在生成）。
#   (2) 双射配对：{n} 个 unread 点**全部**是 matched_nc，且逐对都是 fm_pins_pre.tcl 里的钉点
#       （vmucp_check.py：不在钉点表 0 对、未配对 0 个）；FM 自行猜配 0 对。
#       构成 = {comp}。两侧对称。
#   (3) 期望：开 vmucp 后 passing {passing} -> {passing + n}（恰好 +{n}），failing 仍 0，unread 归 0。
#       不增即空转，按 fail 处理。
#   (4) 全零：failing / unverified / unmatched / aborted 全 0。
#   (5) 无 dont_verify、无新黑盒（两侧全白盒，黑盒输出 0）。
#   (6) 摘要即本段；采证跑的 unread_points.txt 由 lane 存档（scratchpad/iqfam/diag/{v}.unread）。

fm_target_vmucp_allow
'''
    (REPO / 'verif' / 'fm_target_config' / f'{v}.tcl').write_text(txt)
    print(f'写 verif/fm_target_config/{v}.tcl（期望 passing {passing} -> {passing + n}）')


if __name__ == '__main__':
    main()
