#!/usr/bin/env python3
"""生成 DCacheWrapper 的双例化 UT testbench（tb.sv）：由 DCache 的 tb（verif/ut/DCache/tb.sv，
scripts/gen_dcache.py 生成区 + 手写激励/覆盖）机械改写而来，不另写激励 —— DCacheWrapper 除 perf 打两拍外
全是 DCache 端口直通，DCache tb 的 L2 模型 / LSU 激励 / 覆盖闸原样适用。

改写规则（每条都核对命中次数，不符即失败，fail-closed）：
  1. 两个被测实例：`DCache u_gold (` -> `DCacheWrapper u_gold (`，`DCache_xs u_impl (` -> `DCacheWrapper_xs u_impl (`；
  2. 两个实例的连线里，DCache 端口名 .auto_cacheCtrlOpt_in_* -> 外壳端口名 .auto_uncache_in_*（tb 里的线名不变）；
  3. tb 对 DCache 内部的层次引用多一层实例名：`u_gold.` -> `u_gold.dcache.`，`u_impl.` -> `u_impl.dcache.`；
  4. 文件头第一行换成本 tb 的说明。
perf 口在两侧都多晚两拍，逐拍比较不受影响。

用法：python3 gen.py [--check]
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, '..', 'DCache', 'tb.sv')
DST = os.path.join(HERE, 'tb.sv')


def die(msg):
    raise SystemExit('DCacheWrapper/gen.py: ' + msg)


def build():
    t = open(SRC).read()
    lines = t.split('\n')
    if not lines[0].startswith('// DCache 双例化逐拍比对'):
        die('DCache tb 第一行不是预期的说明行')
    lines[0] = ('// DCacheWrapper 双例化逐拍比对：golden DCacheWrapper vs 重写件 DCacheWrapper_xs。'
                '本文件由 verif/ut/DCacheWrapper/gen.py 从 verif/ut/DCache/tb.sv 机械改写（勿手改），以下为原 DCache tb 说明：')
    t = '\n'.join(lines)
    for old, new in (('  DCache u_gold (\n', '  DCacheWrapper u_gold (\n'), ('  DCache_xs u_impl (\n', '  DCacheWrapper_xs u_impl (\n')):
        if t.count(old) != 1:
            die('实例行 %r 出现 %d 次' % (old, t.count(old)))
        t = t.replace(old, new)
    # 规则 2：只在两个实例块里改端口名
    def fix_block(m):
        blk = m.group(0)
        n = len(re.findall(r'^    \.auto_cacheCtrlOpt_in_', blk, re.M))
        if n != 14:
            die('实例块里 auto_cacheCtrlOpt_in_ 端口 %d 个（应 14）' % n)
        return re.sub(r'^    \.auto_cacheCtrlOpt_in_', '    .auto_uncache_in_', blk, flags=re.M)
    t, k = re.subn(r'^  DCacheWrapper(?:_xs)? u_(?:gold|impl) \(.*?^  \);', fix_block, t, flags=re.S | re.M)
    if k != 2:
        die('实例块 %d 个（应 2）' % k)
    # 规则 3：层次引用
    t, ng = re.subn(r'\bu_gold\.(?!dcache\.)', 'u_gold.dcache.', t)
    t, ni = re.subn(r'\bu_impl\.(?!dcache\.)', 'u_impl.dcache.', t)
    if ng == 0 or ni == 0:
        die('没有找到层次引用（u_gold. %d / u_impl. %d）' % (ng, ni))
    return t


if __name__ == '__main__':
    txt = build()
    if '--check' in sys.argv[1:]:
        ok = os.path.exists(DST) and open(DST).read() == txt
        print(('OK: ' if ok else 'DRIFT: ') + DST)
        sys.exit(0 if ok else 1)
    if not os.path.exists(DST) or open(DST).read() != txt:
        open(DST, 'w').write(txt)
    print('wrote ' + DST)
