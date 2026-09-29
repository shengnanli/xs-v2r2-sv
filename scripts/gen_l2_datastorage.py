#!/usr/bin/env python3
"""gen_l2_datastorage.py —— 从 G1 golden 生成 DataStorage{,_1,_2,_3} 的 wrapper。

DataStorage 的逻辑（SECDED 编解码、请求路由、断言影子寄存器）全在手写核
rtl/uncore/xs_DataStorage_core.sv；四个 slice 的单态化只差两件事：数据阵列用哪个
GatedSplittedSRAM_N、MBIST 节点用哪个 L2DataStorage_N（以及随之变化的 bore_array 位宽）。
本脚本生成的 wrapper 只做连线：

  * u_core   ：io_* <-> 核的请求/数据口；核的 arr_* <-> 数据阵列 array 的读写口；
  * array    ：GatedSplittedSRAM_N，DFT 广播口 sigFromSrams_bore[_k]_* 直通；
               MBIST bore 口 boreChildrenBd_bore[_k]_* <-> mbistPl 的 toSRAM_k_*；
  * mbistPl  ：L2DataStorage_N，上游 mbist_* <-> 本模块 boreChildrenBd_bore_*。

★校验★：解析 golden 的 array / mbistPl 两个实例逐端口连接，把 golden 内部线名
（childBd[_k]_<x>、bd_<x>、hi、_array_io_r_resp_data_0_data、写数据编码表达式）换成本仓线名后
逐口比对；写数据口只核"接的是编码结果"，编码本身由 FM 证明。对不上任何一个端口即失败。

用法：python3 scripts/gen_l2_datastorage.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
OUT = os.path.join(REPO, 'rtl', 'uncore')
MODS = ['DataStorage', 'DataStorage_1', 'DataStorage_2', 'DataStorage_3']
NBANK = 4


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
    res = {}
    for m in re.finditer(r'\n  (\w+) (\w+) \((.*?)\n  \);', body, re.S):
        conns = {}
        for c in re.finditer(r'\.(\w+)\s*\(\s*(.*?)\s*\)(?=,\s*\.|\s*$)', m.group(3), re.S):
            conns[c.group(1)] = re.sub(r'\s+', ' ', c.group(2))
        res[m.group(2)] = (m.group(1), conns)
    return res


def sfx(k):
    return '' if k == 0 else '_%d' % k


BORE_FIELDS = ['addr', 'addr_rd', 'wdata', 'wmask', 're', 'we', 'rdata', 'ack', 'selectedOH', 'array']


def array_rule(p):
    """array 实例端口 -> 本仓表达式。"""
    fixed = {'clock': 'clock', 'reset': 'reset', 'io_en': 'io_en',
             'io_r_req_valid': 'arrReadValid', 'io_r_req_bits_setIdx': 'arrSetIdx',
             'io_r_resp_data_0_data': 'arrReadData', 'io_w_req_valid': 'arrWriteValid',
             'io_w_req_bits_setIdx': 'arrSetIdx', 'io_w_req_bits_data_0_data': 'arrWriteData'}
    if p in fixed:
        return fixed[p]
    if p.startswith('sigFromSrams_'):
        return p
    m = re.fullmatch(r'boreChildrenBd_bore(?:_(\d))?_(\w+)', p)
    assert m and m.group(2) in BORE_FIELDS, p
    return 'sramBore_%s[%s]' % (m.group(2), m.group(1) or '0')


def mbist_rule(p):
    m = re.fullmatch(r'mbist_(\w+)', p)
    if m:
        return {'ack': 'boreChildrenBd_bore_ack', 'outdata': 'boreChildrenBd_bore_outdata'}.get(
            m.group(1), 'boreChildrenBd_bore_%s' % m.group(1))
    if p in ('clock', 'reset'):
        return p
    m = re.fullmatch(r'toSRAM_(\d)_(\w+)', p)
    assert m and m.group(2) in BORE_FIELDS, p
    return 'sramBore_%s[%s]' % (m.group(2), m.group(1))


def golden_to_mine(e):
    m = re.fullmatch(r'childBd(?:_(\d))?_(\w+)', e)
    if m:
        return 'sramBore_%s[%s]' % (m.group(2), m.group(1) or '0')
    m = re.fullmatch(r'bd_(\w+)', e)
    if m:
        return {'ack': 'boreChildrenBd_bore_ack', 'outdata': 'boreChildrenBd_bore_outdata'}.get(
            m.group(1), 'boreChildrenBd_bore_%s' % m.group(1))
    return {'hi': 'arrSetIdx', '_array_io_r_resp_data_0_data': 'arrReadData',
            'io_req_valid & ~io_req_bits_wen': 'arrReadValid',
            'io_req_valid & io_req_bits_wen': 'arrWriteValid'}.get(e, e)


def parse(mod):
    txt = open(os.path.join(G, mod + '.sv')).read()
    P = ports(txt, mod)
    body = txt[txt.index('\n);', txt.index('module %s(' % mod)):]
    inst = instances(body)
    assert set(inst) == {'array', 'mbistPl'}, (mod, list(inst))
    amod, aconn = inst['array']
    mmod, mconn = inst['mbistPl']
    for p, e in aconn.items():
        if p == 'io_w_req_bits_data_0_data':
            assert 'io_wdata_data' in e and 'syndromeUInt' in e, '%s: 写数据口不是编码表达式' % mod
            continue
        assert golden_to_mine(e) == array_rule(p), '%s array.%s: golden %s != 规则 %s' % (mod, p, e, array_rule(p))
    for p, e in mconn.items():
        assert golden_to_mine(e) == mbist_rule(p), '%s mbistPl.%s: golden %s != 规则 %s' % (mod, p, e, mbist_rule(p))
    for a in ('boreChildrenBd_bore_ack = bd_ack', 'boreChildrenBd_bore_outdata = bd_outdata'):
        assert ('assign ' + a + ';') in body, (mod, a)
    # array 实例里每个 bore 字段的位宽（从 golden 的 childBd 线声明取）
    W = {}
    for f in BORE_FIELDS:
        m = re.search(r'wire\s+(?:\[(\d+):0\]\s+)?childBd_%s;' % f, body)
        assert m, (mod, f)
        W[f] = 1 if m.group(1) is None else int(m.group(1)) + 1
    return dict(mod=mod, P=P, amod=amod, mmod=mmod, aports=list(aconn), mports=list(mconn), W=W,
                lines=len(txt.splitlines()))


def emit(R):
    m = R['mod']
    L = []
    A = L.append
    A('// %s.sv —— L2 slice 的数据阵列（%s）：SECDED 保护的 4096 块 x 512 位数据存储' % (m, 'slice %s' % (m.split('_')[1] if '_' in m else '0')))
    A('//')
    A('// 逻辑全在 rtl/uncore/xs_DataStorage_core.sv（ECC 编解码、请求路由、MCP2 断言影子寄存器，')
    A('// 文件头讲清了数据怎么切片、怎么编码、error 怎么来）。本 wrapper 只连线三样东西：')
    A('//   u_core   可读核；')
    A('//   array    数据阵列 %s（4 个 137 位 bank + 读时钟门控，纯连线模块）；' % R['amod'])
    A('//   mbistPl  MBIST 分发叶子 %s（extraHold），把上游 bore 总线铺给 4 个 bank。' % R['mmod'])
    A('// sigFromSrams_bore[_k]_* 是 SRAM 的 DFT 广播口，原样直通给 array。')
    A('// golden %d 行；本文件由 scripts/gen_l2_datastorage.py 生成，逐端口与 golden 连接比对。' % R['lines'])
    A('')
    A('// BEGIN GENERATED(%s) —— scripts/gen_l2_datastorage.py' % m)
    A('module %s (' % m)
    A(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in R['P']))
    A(');')
    A('')
    A('  logic         arrReadValid, arrWriteValid;')
    A('  logic [11:0]  arrSetIdx;')
    A('  logic [547:0] arrWriteData, arrReadData;')
    A('  // mbistPl.toSRAM_k <-> array 的第 k 个 bank 的 MBIST bore 口')
    for f in BORE_FIELDS:
        w = R['W'][f]
        A('  logic %-8s sramBore_%-10s [%d];' % ('' if w == 1 else '[%d:0]' % (w - 1), f, NBANK))
    A('')
    A('  xs_DataStorage_core u_core (')
    A('    .clock       (clock),')
    A('    .reset       (reset),')
    A('    .en          (io_en),')
    A('    .req_valid   (io_req_valid),')
    A('    .req_way     (io_req_bits_way),')
    A('    .req_set     (io_req_bits_set),')
    A('    .req_wen     (io_req_bits_wen),')
    A('    .wdata       (io_wdata_data),')
    A('    .rdata       (io_rdata_data),')
    A('    .error       (io_error),')
    A('    .arr_r_valid (arrReadValid),')
    A('    .arr_w_valid (arrWriteValid),')
    A('    .arr_setIdx  (arrSetIdx),')
    A('    .arr_wdata   (arrWriteData),')
    A('    .arr_rdata   (arrReadData)')
    A('  );')
    A('')
    A('  %s array (' % R['amod'])
    A(',\n'.join('    .%-32s (%s)' % (p, array_rule(p)) for p in R['aports']))
    A('  );')
    A('')
    A('  %s mbistPl (' % R['mmod'])
    A(',\n'.join('    .%-20s (%s)' % (p, mbist_rule(p)) for p in R['mports']))
    A('  );')
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
        print('%-14s array=%s mbistPl=%s  连接逐口校验通过' % (m, R['amod'], R['mmod']))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
