#!/usr/bin/env python3
"""快版：SimTop 的 9897 条 perfCnt_bore XMR 分别落在哪个模块、该模块是否被重写、
被引的内部信号名在该模块源码里是否存在。用 token 集合代替逐条 regex。"""
import re, pathlib, collections
FLIST = pathlib.Path('/home/eda/xs-env/sim-work/impl/files_simtop.f')
SIMTOP = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl/SimTop.sv')
IMPL = '/home/eda/xs-env/wt-sim/rtl/'
MOD_RE = re.compile(r'^\s*module\s+(\w+)', re.M)
END_RE = re.compile(r'^\s*endmodule', re.M)
INST_RE = re.compile(r'^\s*([A-Za-z_]\w*)\s+([A-Za-z_]\w*)\s*\(\s*$', re.M)
WORD_RE = re.compile(r'[A-Za-z_]\w*')
KW = {'module','endmodule','if','else','case','always','always_ff','always_comb','initial',
      'assign','wire','reg','logic','input','output','inout','for','while','begin','end','function','task'}
mod2file, mod2insts, mod2words = {}, {}, {}
for line in FLIST.read_text().splitlines():
    p = pathlib.Path(line.strip())
    if not line.strip(): continue
    try: t = p.read_text(errors='replace')
    except Exception: continue
    starts = [(m.start(), m.group(1)) for m in MOD_RE.finditer(t)]
    ends = [m.start() for m in END_RE.finditer(t)]
    for s, n in starts:
        e = next((x for x in ends if x > s), len(t))
        body = t[s:e]
        mod2file[n] = p
        mod2words[n] = set(WORD_RE.findall(body))
        mod2insts[n] = {m.group(2): m.group(1) for m in INST_RE.finditer(body)
                        if m.group(1) not in KW}
st = SIMTOP.read_text(errors='replace')
mod2insts['SimTop'] = {m.group(2): m.group(1) for m in INST_RE.finditer(st) if m.group(1) not in KW}
mod2file['SimTop'] = SIMTOP
xmrs = re.findall(r'\(\s*(SimTop\.[A-Za-z0-9_.]+)\s*\)', st)
stat, broken, brk_path = collections.Counter(), collections.Counter(), collections.Counter()
for x in xmrs:
    parts = x.split('.'); cur = 'SimTop'; okp = True
    for seg in parts[1:-1]:
        nxt = mod2insts.get(cur, {}).get(seg)
        if nxt is None:
            okp = False; brk_path[f'{cur}::{seg}'] += 1; break
        cur = nxt
    if not okp:
        stat['路径中断(实例名对不上)'] += 1; continue
    rew = str(mod2file.get(cur, '')).startswith(IMPL)
    has = parts[-1] in mod2words.get(cur, ())
    tag = ('重写模块' if rew else 'golden模块')
    stat[('信号存在-' if has else '信号缺失-') + tag] += 1
    if not has: broken[(cur, tag)] += 1
print('XMR 总数:', len(xmrs))
for k, v in stat.most_common(): print(f'  {v:6d}  {k}')
print('--- 信号缺失的模块 TOP25 ---')
for (m, t), v in broken.most_common(25): print(f'  {v:6d}  {m} [{t}]')
print('缺失涉及模块数:', len(broken))
print('--- 路径中断 TOP15 ---')
for k, v in brk_path.most_common(15): print(f'  {v:6d}  {k}')
