#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""复位域核对：golden TLBFA 家族 vs 重写核，哪些寄存器复位、复位是同步还是异步。

为什么单独有这道检查（Predictor 的教训，本轮已在别的模块上真实咬过）：
golden 里"有寄存器不复位"是常态，把它照抄成全复位是**真 bug**，而 elaborate 和 lint
都不会报——RTL 语法完全合法，只是行为不同。复位差异在随机 UT 里也未必看得见
（例如给 entries 多加一个复位，模块边界上根本观测不到，见 mutants.sh 的 M9）。
所以这条必须**结构上**核对，不能只靠仿真。

判据：
  A. golden 四个变体里，带复位的寄存器集合必须恰好是 48 个 v 位，且所在 always 块
     是 `posedge clock or posedge reset`（**异步**复位）。
  B. golden 其余 always 块必须只有 `posedge clock`（无复位）。
  C. 重写核 xs_TLBFA_core.sv 里，唯一出现在 `if (reset)` 分支的赋值目标是 v，
     且它所在的 always_ff 是异步复位；其余 always_ff 只敏感于 posedge clock。
  D. 状态清单：golden 每个变体的寄存器必须**恰好**分解成 6 组（entries / hitVecReg /
     v / reqVpn / resp_valid / refill 打拍），每组位数等于按 (PORTS, KEEP_WPERM) 算出的
     值，且没有第 7 组剩余。这一条管的是"golden 其实还有别的状态而我漏了"——
     漏一组状态，UT 未必看得见（它可能只在极少数激励下才影响输出），但 FM 一定会挂。

用法: python3 verif/ut/TLBFA/reset_domain_check.py
      XSSV_TLBFA_CORE=<某个核.sv> python3 ...   # 核对别处的核（变异体测试用）
退出码 0 = 三条判据都成立

★它与 UT 是互补的，不是重复★：给 entries 多加一个复位（mutants.sh 的 M9）在模块
边界上**观测不到**（v 复位后为 0，读不出任何 entry；而被 refill 写过的 way 内容已被
覆盖），200k 拍随机 UT 报 errors=0。只有这道结构闸能把它拦下来。
"""
import os
import re
import sys

G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
HERE = os.path.dirname(os.path.abspath(__file__))
# XSSV_TLBFA_CORE 可指向别处的核（mutants.sh 用它核对变异副本）
CORE = os.environ.get('XSSV_TLBFA_CORE',
                      os.path.join(HERE, '../../../rtl/memblock/xs_TLBFA_core.sv'))
VARIANTS = ['TLBFA', 'TLBFA_1', 'TLBFA_2', 'TLBFA_3']

ALWAYS = re.compile(r'^\s*always(?:_ff)?\s*@\s*\((.*?)\)', re.M)
rc = 0


def blocks(text):
    """切出 always 块：(敏感表, 块正文)。按下一个 always/文件尾切，够用。"""
    pos = [(m.start(), m.group(1)) for m in ALWAYS.finditer(text)]
    out = []
    for i, (s, sens) in enumerate(pos):
        e = pos[i + 1][0] if i + 1 < len(pos) else len(text)
        out.append((' '.join(sens.split()), text[s:e]))
    return out


print('=== golden ===')
for v in VARIANTS:
    text = open(os.path.join(G, f'{v}.sv')).read()
    # 只看**综合可见**的部分：UT 与 FM 两侧都带 +define+SYNTHESIS，于是
    #   · `ifndef SYNTHESIS 的断言块
    #   · `ifdef ENABLE_INITIAL_REG_ 的 initial 随机化块（里面也有一句 if (reset)，
    #     不去掉就会把它误判成"同步块里出现了复位"）
    # 都不存在。这里照同一口径裁掉，判的才是同一份设计。
    text = re.sub(r'`ifndef SYNTHESIS.*?`endif[^\n]*\n', '', text, flags=re.S)
    text = re.sub(r'`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_\n',
                  '', text, flags=re.S)
    text = re.sub(r'//[^\n]*', '', text)
    async_regs, sync_blocks = set(), 0
    for sens, body in blocks(text):
        m = re.search(r'if\s*\(reset\)\s*begin(.*?)\n    end', body, re.S)
        if 'posedge reset' in sens:
            if not m:
                print(f'  ★{v}: 异步复位块里找不到 if (reset) 分支'); rc = 1; continue
            async_regs |= set(re.findall(r'(\w+)\s*<=', m.group(1)))
        else:
            sync_blocks += 1
            if re.search(r'if\s*\(reset\)', body):
                print(f'  ★{v}: 同步块里出现了 if (reset)'); rc = 1
    expect = {f'v_{i}' for i in range(48)}
    ok = (async_regs == expect)
    print(f'  {v:<8} 异步复位寄存器 {len(async_regs)} 个'
          f'{"（恰好是 v_0..v_47）" if ok else " ★与预期不符：" + str(sorted(async_regs)[:6])}'
          f'；无复位 always 块 {sync_blocks} 个')
    if not ok:
        rc = 1

print('=== 重写核 ===')
core = re.sub(r'//[^\n]*', '', open(CORE).read())   # 注释里出现 "posedge reset" 是说明文字，不是代码
async_targets, sync_n, async_n = set(), 0, 0
for sens, body in blocks(core):
    if 'posedge reset' in sens:
        async_n += 1
        m = re.search(r'if\s*\(reset\)\s*begin(.*?)end else', body, re.S)
        if not m:
            print('  ★核的异步块里找不到 if (reset) 分支'); rc = 1; continue
        async_targets |= set(re.findall(r'(\w+)\s*<=', m.group(1)))
    else:
        sync_n += 1
        if re.search(r'\breset\b', body):
            print(f'  ★核的同步 always_ff 里引用了 reset：{body[:60]!r}'); rc = 1
print(f'  异步复位块 {async_n} 个，复位目标 = {sorted(async_targets)}')
print(f'  无复位 always_ff {sync_n} 个')
if async_targets != {'v'} or async_n != 1:
    print('  ★与 golden 的复位域不一致（应当只有 v 一个目标、一个异步块）')
    rc = 1

# --- D 状态清单 ---------------------------------------------------------
# 每变体 (PORTS, KEEP_WPERM)；entry 公共字段 160 位，KEEP_WPERM 再加 4 位/条。
SPEC = {'TLBFA': (3, 0), 'TLBFA_1': (4, 1), 'TLBFA_2': (2, 1), 'TLBFA_3': (2, 1)}
NWAYS, ENTRY_BITS, VPN_W, WAY_W = 48, 160, 38, 6
print('=== 状态清单（golden） ===')
for v, (ports, keep) in SPEC.items():
    text = open(os.path.join(G, f'{v}.sv')).read()
    text = re.sub(r'`ifndef SYNTHESIS.*?`endif[^\n]*\n', '', text, flags=re.S)
    text = re.sub(r'`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_\n',
                  '', text, flags=re.S)
    got = {}
    for m in re.finditer(r'^\s*reg\s+(?:\[(\d+):0\]\s+)?(\w+);', text, re.M):
        w = int(m.group(1)) + 1 if m.group(1) else 1
        n = m.group(2)
        k = ('entries' if n.startswith('entries_') else
             'hitVecReg' if n.startswith('hitVecReg') else
             'v' if re.fullmatch(r'v_\d+', n) else
             'reqVpn' if n.startswith('reqVpn') else
             'resp_valid' if n.endswith('_valid_REG') else
             'refill' if n in ('REG', 'refill_wayIdx_reg') else 'OTHER')
        got[k] = got.get(k, 0) + w
    want = {'entries': NWAYS * (ENTRY_BITS + 4 * keep), 'hitVecReg': NWAYS * ports,
            'v': NWAYS, 'reqVpn': VPN_W * ports, 'resp_valid': ports,
            'refill': WAY_W + 1}
    ok = (got == want)
    print(f'  {v:<8} 状态位合计 {sum(got.values())}'
          f'{"（与 (PORTS=%d, KEEP_WPERM=%d) 的清单逐组相符）" % (ports, keep) if ok else ""}')
    if not ok:
        print(f'    ★不符：golden={got}')
        print(f'          期望={want}')
        rc = 1

print('--- 复位域 + 状态清单核对 ' + ('PASS' if rc == 0 else 'FAIL') + ' ---')
sys.exit(rc)
