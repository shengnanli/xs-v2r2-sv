#!/usr/bin/env python3
"""gen_l2_gated_sram.py —— 从 G1 golden 生成 L2 数据阵列 GatedSplittedSRAM{,_1,_2,_3} 薄文件。

GatedSplittedSRAM 是 coupledL2 DataStorage 的数据阵列：一个 548 位宽（4 x 137：每 128 位数据
+ 9 位 SECDED 校验）的逻辑 SRAM，按 137 位切成 4 个物理 bank（SRAMTemplate_*，已独立签核），
每个 bank 配一个读时钟门控单元 MbistClockGateCell_93。本模块本身**没有任何逻辑**，只是连线：

  * 读/写请求（valid / setIdx）广播给 4 个 bank；写数据按 137 位切片分给各 bank；
  * 读数据按 bank 号从低到高拼回 548 位；
  * 第 k 个 bank 的 DFT 广播口接 sigFromSrams_bore[_k]_*，MBIST bore 口接
    boreChildrenBd_bore[_k]_*（k=0 时无后缀）；
  * bank 的 mbistCgCtl_{en,rckEn,wckEn} 送给同号门控单元，门控单元的 out_clock 回送给
    bank 的 mbistCgCtl_rclk；门控单元的工作使能 E = io_en，DFT 口与同号 bank 共用。

四个变体只差 bore_array 位宽和各 bank 用哪个 SRAMTemplate 单态化（_2 的 bank0 与其余不同）。
★校验★：脚本把 golden 每个实例的每个端口连接解析出来，再按上面的规则生成本仓的连接，
把 golden 的内部线名（_array_0_0_<k>_io_*、_cg[_k]_out_clock）换成本仓的线名后逐口比较，
任何一个端口、任何一个实例对不上都报错；golden 里不属于这两种实例 + 一条读数据拼接的语句也报错。

用法：python3 scripts/gen_l2_gated_sram.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
OUT = os.path.join(REPO, 'rtl', 'uncore')
MODS = {'GatedSplittedSRAM': 'DataStorage（slice 0）', 'GatedSplittedSRAM_1': 'DataStorage_1（slice 1）',
        'GatedSplittedSRAM_2': 'DataStorage_2（slice 2）', 'GatedSplittedSRAM_3': 'DataStorage_3（slice 3）'}
NBANK, BANK_W = 4, 137


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
        for c in re.finditer(r'\.(\w+)\s*\(\s*(.*?)\s*\)(?=,|\s*$)', m.group(3), re.S):
            conns[c.group(1)] = re.sub(r'\s+', ' ', c.group(2))
        res.append((m.group(1), m.group(2), conns))
    return res


def sfx(k):
    return '' if k == 0 else '_%d' % k


def my_sram_conns(k, sram_ports):
    """本仓第 k 个 bank 的 SRAMTemplate 连接规则（端口名 -> 表达式）。"""
    c = {}
    for p in sram_ports:
        if p in ('clock', 'reset'):
            c[p] = p
        elif p in ('io_r_req_valid', 'io_r_req_bits_setIdx', 'io_w_req_valid', 'io_w_req_bits_setIdx'):
            c[p] = p
        elif p == 'io_r_resp_data_0':
            c[p] = 'bankReadData[%d]' % k
        elif p == 'io_w_req_bits_data_0':
            c[p] = 'io_w_req_bits_data_0_data[%d:%d]' % (BANK_W * (k + 1) - 1, BANK_W * k)
        elif p == 'io_broadcast_ram_ctl':
            c[p] = "64'h0"
        elif p.startswith('io_broadcast_'):
            c[p] = 'sigFromSrams_bore%s_%s' % (sfx(k), p[len('io_broadcast_'):])
        elif p in ('io_mbistCgCtl_en', 'io_mbistCgCtl_rckEn', 'io_mbistCgCtl_wckEn'):
            c[p] = {'io_mbistCgCtl_en': 'bankMbistReq', 'io_mbistCgCtl_rckEn': 'bankMbistRead',
                    'io_mbistCgCtl_wckEn': 'bankMbistWrite'}[p] + '[%d]' % k
        elif p == 'io_mbistCgCtl_rclk':
            c[p] = 'bankReadClock[%d]' % k
        elif p.startswith('boreChildrenBd_bore_'):
            c[p] = 'boreChildrenBd_bore%s_%s' % (sfx(k), p[len('boreChildrenBd_bore_'):])
        else:
            raise SystemExit('未知 SRAM 端口 %s' % p)
    return c


def my_cg_conns(k):
    return {'clock': 'clock', 'mbist_writeen': 'bankMbistWrite[%d]' % k,
            'mbist_readen': 'bankMbistRead[%d]' % k, 'mbist_req': 'bankMbistReq[%d]' % k,
            'E': 'io_en',
            'dft_ram_mcp_hold': 'sigFromSrams_bore%s_ram_mcp_hold' % sfx(k),
            'dft_ram_aux_clk': 'sigFromSrams_bore%s_ram_aux_clk' % sfx(k),
            'dft_ram_aux_ckbp': 'sigFromSrams_bore%s_ram_aux_ckbp' % sfx(k),
            'dft_cgen': 'sigFromSrams_bore%s_cgen' % sfx(k),
            'out_clock': 'bankReadClock[%d]' % k}


def golden_to_mine(expr):
    """golden 内部线名 -> 本仓线名。"""
    m = re.fullmatch(r'_array_0_0_(\d)_io_r_resp_data_0', expr)
    if m:
        return 'bankReadData[%s]' % m.group(1)
    m = re.fullmatch(r'_array_0_0_(\d)_io_mbistCgCtl_(en|rckEn|wckEn)', expr)
    if m:
        return {'en': 'bankMbistReq', 'rckEn': 'bankMbistRead', 'wckEn': 'bankMbistWrite'}[m.group(2)] + '[%s]' % m.group(1)
    m = re.fullmatch(r'_cg(?:_(\d))?_out_clock', expr)
    if m:
        return 'bankReadClock[%s]' % (m.group(1) or '0')
    return expr


def parse(mod):
    txt = open(os.path.join(G, mod + '.sv')).read()
    P = ports(txt, mod)
    body = txt[txt.index('\n);', txt.index('module %s(' % mod)):]
    inst = instances(body)
    srams = [x for x in inst if x[0].startswith('SRAMTemplate_')]
    cgs = [x for x in inst if x[0] == 'MbistClockGateCell_93']
    assert len(srams) == NBANK and len(cgs) == NBANK and len(inst) == 2 * NBANK, mod
    bank_mods = []
    for k, (m, name, conns) in enumerate(srams):
        assert name == 'array_0_0_%d' % k, name
        mine = my_sram_conns(k, list(conns))
        for p, e in conns.items():
            assert golden_to_mine(e) == mine[p], '%s %s.%s: golden %s != 规则 %s' % (mod, name, p, e, mine[p])
        bank_mods.append(m)
    for k, (m, name, conns) in enumerate(cgs):
        assert name == 'cg' + sfx(k), name
        mine = my_cg_conns(k)
        assert set(conns) == set(mine), (mod, name)
        for p, e in conns.items():
            assert golden_to_mine(e) == mine[p], '%s %s.%s: golden %s != 规则 %s' % (mod, name, p, e, mine[p])
    a = re.search(r'assign io_r_resp_data_0_data =\s*\{(.*?)\};', body, re.S)
    parts = [golden_to_mine(x.strip()) for x in a.group(1).split(',')]
    assert parts == ['bankReadData[%d]' % k for k in reversed(range(NBANK))], parts
    # 除去实例与这条 assign，golden 里只能剩线声明
    rest = re.sub(r'\n  (\w+) (\w+) \((.*?)\n  \);', '', body, flags=re.S)
    rest = re.sub(r'assign io_r_resp_data_0_data =\s*\{.*?\};', '', rest, flags=re.S)
    for line in rest.splitlines():
        s = line.strip()
        assert not s or s.startswith(('wire ', ');', 'endmodule', '//')), '%s: 模板外语句 %r' % (mod, s)
    sram_ports = list(srams[0][2])
    return dict(mod=mod, P=P, bank_mods=bank_mods, sram_ports=sram_ports,
                lines=len(txt.splitlines()))


def emit(R):
    m = R['mod']
    L = []
    A = L.append
    A('// %s.sv —— L2 数据阵列：548 位宽逻辑 SRAM = 4 个 137 位物理 bank + 4 个读时钟门控（%s）' % (m, MODS[m]))
    A('//')
    A('// 纯连线模块（golden %d 行，没有任何寄存器或运算）。每个 bank 存一个 128 位数据块及其 9 位' % R['lines'])
    A('// SECDED 校验（校验在上层 DataStorage 里算），所以 bank k 管写数据的 [137k+136:137k]。')
    A('// 各 bank：%s；门控单元 MbistClockGateCell_93（rtl/common/）。' % ', '.join('bank%d=%s' % (k, b) for k, b in enumerate(R['bank_mods'])))
    A('//   * 读/写请求广播到 4 个 bank；读数据按 bank 号低到高拼回；')
    A('//   * bank 把自己的 MBIST 读写请求（mbistCgCtl_en/rckEn/wckEn）交给同号门控单元，门控单元')
    A('//     在"真要访问"的拍放出读时钟（mbistCgCtl_rclk）；正常工作时的使能是 io_en；')
    A('//   * 第 k 个 bank 的 DFT 广播口 / MBIST bore 口接 sigFromSrams_bore_<k>_* / boreChildrenBd_bore_<k>_*')
    A('//     （k=0 无后缀）。')
    A('// 由 scripts/gen_l2_gated_sram.py 生成：逐实例逐端口与 golden 比对连接规则，对不上即失败。')
    A('')
    A('// BEGIN GENERATED(%s) —— scripts/gen_l2_gated_sram.py' % m)
    A('module %s (' % m)
    A(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in R['P']))
    A(');')
    A('')
    A('  logic [%d:0] bankReadData   [%d];   // 各 bank 读出的 137 位' % (BANK_W - 1, NBANK))
    A('  logic         bankMbistReq   [%d];   // bank -> 门控：MBIST 正在访问本 bank' % NBANK)
    A('  logic         bankMbistRead  [%d];' % NBANK)
    A('  logic         bankMbistWrite [%d];' % NBANK)
    A('  logic         bankReadClock  [%d];   // 门控 -> bank：门控后的读时钟' % NBANK)
    for k, bm in enumerate(R['bank_mods']):
        A('')
        A('  // ---- bank %d：写数据 [%d:%d] ----' % (k, BANK_W * (k + 1) - 1, BANK_W * k))
        A('  %s array_0_0_%d (' % (bm, k))
        c = my_sram_conns(k, R['sram_ports'])
        A(',\n'.join('    .%-30s (%s)' % (p, c[p]) for p in R['sram_ports']))
        A('  );')
        cg = my_cg_conns(k)
        A('  MbistClockGateCell_93 cg%s (' % sfx(k))
        A(',\n'.join('    .%-16s (%s)' % (p, e) for p, e in cg.items()))
        A('  );')
    A('')
    A('  assign io_r_resp_data_0_data = {%s};' % ', '.join('bankReadData[%d]' % k for k in reversed(range(NBANK))))
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
        print('%-20s banks=%s  连接逐口校验通过' % (m, ','.join(R['bank_mods'])))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
