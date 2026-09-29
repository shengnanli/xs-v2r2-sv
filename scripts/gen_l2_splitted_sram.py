#!/usr/bin/env python3
"""gen_l2_splitted_sram.py —— 从 G1 golden 生成 L2 目录 tag 阵列 SplittedSRAM_3/_4/_5/_6 的薄文件。

它们是 coupledL2 Directory 的 tagArray：`SplittedSRAM(UInt(38.W), sets=512, ways=8, waySplit=2,
dataSplit=2, singlePort)` 的四个 slice 单态化（38 位 = 31 位 tag + 7 位 SECDED，ECC 在 Directory 里算）。
与 GatedSplittedSRAM 一样**没有任何逻辑**，只是把一个逻辑 SRAM 切成 2x2 = 4 块物理 SRAM：

  * way 切 2 组：组 g 管 way 4g..4g+3，拿写掩码 waymask[4g+3:4g]；
  * 数据切 2 段：段 k 管每个 way 数据的 [19k+18:19k]；
  * 块 (g,k) 的实例名 array_0_<g>_<k>，编号 n = 2g+k，DFT 广播口 / MBIST bore 口用第 n 套端口；
  * 读回：way 4g+j 的 38 位 = {块(g,1) 第 j 路, 块(g,0) 第 j 路}；
  * r_req_ready 取块 (0,0) 的（其余块的 ready 悬空，SRAMTemplate_150 类变体干脆没这个口）；
    w_req_ready 恒 1（单口 SRAM 写永远接受，读写冲突由上层 Directory 避免）。

四个变体只差每块用哪个 SRAMTemplate 单态化与 bore_array 位宽。★校验★：逐实例逐端口把 golden 连接与上面
的规则比对（golden 内部线 _array_0_<g>_<k>_io_r_resp_data_<j> 换成本仓线名），读回拼接逐条比对，
golden 里剩下任何不认识的语句都报错。

用法：python3 scripts/gen_l2_splitted_sram.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
OUT = os.path.join(REPO, 'rtl', 'uncore')
MODS = {'SplittedSRAM_3': 'Directory（slice 0）', 'SplittedSRAM_4': 'Directory_1（slice 1）',
        'SplittedSRAM_5': 'Directory_2（slice 2）', 'SplittedSRAM_6': 'Directory_3（slice 3）'}
WAY_SPLIT, DATA_SPLIT, WAYS, SLICE_W = 2, 2, 8, 19
WAY_PER = WAYS // WAY_SPLIT


def ports(txt, mod):
    i = txt.index('module %s(' % mod)
    j = txt.index('\n);', i)
    out = []
    for line in txt[i:j].splitlines()[1:]:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', line)
        if m:
            out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return out


def instances(body):
    res = []
    for m in re.finditer(r'\n  (\w+) (\w+) \((.*?)\n  \);', body, re.S):
        conns = {}
        for c in re.finditer(r'\.(\w+)\s*\(\s*(.*?)\s*\)(?=,\s*\.|\s*$)', m.group(3), re.S):
            e = re.sub(r'\s+', ' ', c.group(2))
            conns[c.group(1)] = '' if e == '/* unused */' else e
        res.append((m.group(1), m.group(2), conns))
    return res


def sfx(n):
    return '' if n == 0 else '_%d' % n


def rule(g, k, p):
    n = g * DATA_SPLIT + k
    if p in ('clock', 'reset', 'io_r_req_valid', 'io_r_req_bits_setIdx', 'io_w_req_valid', 'io_w_req_bits_setIdx'):
        return p
    if p == 'io_r_req_ready':
        return 'io_r_req_ready' if n == 0 else ''
    m = re.fullmatch(r'io_r_resp_data_(\d)', p)
    if m:
        return 'bankReadData[%d][%s]' % (n, m.group(1))
    m = re.fullmatch(r'io_w_req_bits_data_(\d)', p)
    if m:
        return 'io_w_req_bits_data_%d[%d:%d]' % (WAY_PER * g + int(m.group(1)), SLICE_W * (k + 1) - 1, SLICE_W * k)
    if p == 'io_w_req_bits_waymask':
        return 'io_w_req_bits_waymask[%d:%d]' % (WAY_PER * (g + 1) - 1, WAY_PER * g)
    if p == 'io_broadcast_ram_ctl':
        return "64'h0"
    if p.startswith('io_broadcast_'):
        return 'sigFromSrams_bore%s_%s' % (sfx(n), p[len('io_broadcast_'):])
    if p.startswith('boreChildrenBd_bore_'):
        return 'boreChildrenBd_bore%s_%s' % (sfx(n), p[len('boreChildrenBd_bore_'):])
    raise SystemExit('未知端口 %s' % p)


def golden_to_mine(e):
    m = re.fullmatch(r'_array_0_(\d)_(\d)_io_r_resp_data_(\d)', e)
    if m:
        return 'bankReadData[%d][%s]' % (int(m.group(1)) * DATA_SPLIT + int(m.group(2)), m.group(3))
    return e


def parse(mod):
    txt = open(os.path.join(G, mod + '.sv')).read()
    P = ports(txt, mod)
    body = txt[txt.index('\n);', txt.index('module %s(' % mod)):]
    inst = instances(body)
    assert len(inst) == WAY_SPLIT * DATA_SPLIT, mod
    banks = []
    for idx, (m, name, conns) in enumerate(inst):
        g, k = divmod(idx, DATA_SPLIT)
        assert name == 'array_0_%d_%d' % (g, k), (mod, name)
        for p, e in conns.items():
            assert golden_to_mine(e) == rule(g, k, p), '%s %s.%s: golden %r != 规则 %r' % (mod, name, p, e, rule(g, k, p))
        banks.append((m, list(conns)))
    for w in range(WAYS):
        g, j = divmod(w, WAY_PER)
        a = re.search(r'assign io_r_resp_data_%d =\s*\{(.*?)\};' % w, body, re.S)
        parts = [golden_to_mine(x.strip()) for x in a.group(1).split(',')]
        assert parts == ['bankReadData[%d][%d]' % (g * DATA_SPLIT + k, j) for k in reversed(range(DATA_SPLIT))], (mod, w, parts)
    assert "assign io_w_req_ready = 1'h1;" in body, mod
    rest = re.sub(r'\n  (\w+) (\w+) \((.*?)\n  \);', '', body, flags=re.S)
    rest = re.sub(r'assign io_r_resp_data_\d =\s*\{.*?\};', '', rest, flags=re.S)
    rest = rest.replace("assign io_w_req_ready = 1'h1;", '')
    for line in rest.splitlines():
        s = line.strip()
        assert not s or s.startswith(('wire ', ');', 'endmodule', '//')), '%s: 模板外语句 %r' % (mod, s)
    return dict(mod=mod, P=P, banks=banks, lines=len(txt.splitlines()))


def emit(R):
    m = R['mod']
    L = []
    A = L.append
    A('// %s.sv —— L2 目录 tag 阵列（%s）：512 组 x 8 路 x 38 位（31 位 tag + 7 位 SECDED）' % (m, MODS[m]))
    A('//')
    A('// 纯连线模块（golden %d 行，没有寄存器、没有运算）：一个逻辑 SRAM 切成 2（way 组）x 2（数据段）= 4 块' % R['lines'])
    A('// 物理 SRAM。块 (g,k) = array_0_<g>_<k>，编号 n = 2g+k：')
    for idx, (bm, _) in enumerate(R['banks']):
        g, k = divmod(idx, DATA_SPLIT)
        A('//   n=%d  array_0_%d_%d  %s  管 way %d..%d 的数据位 [%d:%d]，写掩码 waymask[%d:%d]'
          % (idx, g, k, bm, WAY_PER * g, WAY_PER * g + WAY_PER - 1, SLICE_W * (k + 1) - 1, SLICE_W * k,
             WAY_PER * (g + 1) - 1, WAY_PER * g))
    A('// 读回 way 4g+j = {块(g,1) 第 j 路, 块(g,0) 第 j 路}；r_req_ready 取块 n=0 的，w_req_ready 恒 1。')
    A('// 第 n 块的 DFT 广播口 / MBIST bore 口接 sigFromSrams_bore_<n>_* / boreChildrenBd_bore_<n>_*（n=0 无后缀）。')
    A('// 由 scripts/gen_l2_splitted_sram.py 生成：逐实例逐端口与 golden 比对连接规则。')
    A('')
    A('// BEGIN GENERATED(%s) —— scripts/gen_l2_splitted_sram.py' % m)
    A('module %s (' % m)
    A(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in R['P']))
    A(');')
    A('')
    A('  // bankReadData[n][j]：第 n 块读出的第 j 路（19 位）')
    A('  logic [%d:0] bankReadData [%d][%d];' % (SLICE_W - 1, WAY_SPLIT * DATA_SPLIT, WAY_PER))
    for idx, (bm, plist) in enumerate(R['banks']):
        g, k = divmod(idx, DATA_SPLIT)
        A('')
        A('  // ---- 块 n=%d：way %d..%d，数据位 [%d:%d] ----' % (idx, WAY_PER * g, WAY_PER * g + WAY_PER - 1,
                                                              SLICE_W * (k + 1) - 1, SLICE_W * k))
        A('  %s array_0_%d_%d (' % (bm, g, k))
        A(',\n'.join('    .%-30s (%s)' % (p, rule(g, k, p)) for p in plist))
        A('  );')
    A('')
    A('  // 读回拼接')
    for w in range(WAYS):
        g, j = divmod(w, WAY_PER)
        A('  assign io_r_resp_data_%d = {%s};' % (w, ', '.join('bankReadData[%d][%d]' % (g * DATA_SPLIT + k, j)
                                                              for k in reversed(range(DATA_SPLIT)))))
    A("  assign io_w_req_ready   = 1'b1;")
    A('')
    A('endmodule')
    A('// END GENERATED(%s)' % m)
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    bad = 0
    for m in MODS:
        R = parse(m)
        txt = emit(R)
        p = os.path.join(OUT, m + '.sv')
        cur = open(p).read() if os.path.exists(p) else None
        if a.check:
            if cur != txt:
                print('DRIFT: %s' % p)
                bad += 1
        elif cur != txt:
            open(p, 'w').write(txt)
        print('%-16s banks=%s  连接逐口校验通过' % (m, ','.join(b for b, _ in R['banks'])))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
