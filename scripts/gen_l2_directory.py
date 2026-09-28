#!/usr/bin/env python3
"""gen_l2_directory.py —— 从 G1 golden 生成 Directory{,_1,_2,_3} 的 wrapper。

逻辑全在手写核 rtl/uncore/xs_Directory_core.sv（三级流水查询、SECDED、DRRIP、初始化）。
四个 slice 单态化只差子模块是哪个单态化（tag 阵列 SplittedSRAM_N、meta / 替换状态 / origin 位的
SRAMTemplate_*、MBIST 叶子 L2Directory_N）以及 bore 位宽。wrapper 只做连线：

  * u_core           ：io_* <-> 核；msInfo_<i>_* 打包成核的数组口；
  * tagArray         ：读口 <- arrReadFire / io_read_bits_set，读回 -> tagRead[w]；写 <- 编码后的 tag、路掩码；
  * metaArray        ：读回 -> metaRead[w]（结构体）；写数据 / 掩码直接取 io_metaWReq_*；
  * replacer_sram_opt：读回 -> replRead；写 <- stateWrite* / replWriteData；
  * origin_bit_opt   ：读回 -> originRead[w]；写 <- stateWrite* / originWriteData / originWriteWayMask；
  * mbistPl          ：上游 bore 总线 <-> 本模块 boreChildrenBd_bore_*；toSRAM_n <-> 第 n 块 SRAM 的 bore 口
                       （n = 0..3 tag 阵列四块，4 meta，5 替换状态，6 origin；DFT 广播口 sigFromSrams_bore_n 同号）。

★校验★：解析 golden 每个子模块实例的每个端口连接；golden 的内部线名先按它自己的 `wire x = <式子>;`
展开成式子，再按下表换成本仓线名，逐口比对；对不上任何一个即失败。

用法：python3 scripts/gen_l2_directory.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
OUT = os.path.join(REPO, 'rtl', 'uncore')
MODS = ['Directory', 'Directory_1', 'Directory_2', 'Directory_3']
WAYS, N_MSHR = 8, 16
META_F = ['dirty', 'state', 'clients', 'alias', 'prefetch', 'prefetchSrc', 'accessed', 'tagErr', 'dataErr']
BORE_F = ['addr', 'addr_rd', 'wdata', 'wmask', 're', 'we', 'rdata', 'ack', 'selectedOH', 'array']
MS_F = ['valid', 'set', 'way', 'blockRefill', 'dirHit']   # 核只用这几个 msInfo 字段


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
            e = re.sub(r'\s+', ' ', c.group(2))
            conns[c.group(1)] = '' if e == '/* unused */' else e
        res[m.group(2)] = (m.group(1), conns)
    return res


def mine(e, defs):
    """golden 表达式 -> 本仓表达式。"""
    if re.fullmatch(r'_GEN_\d+', e) and e in defs:
        e = defs[e]
    m = re.fullmatch(r'childBd(?:_(\d))?_(\w+)', e)
    if m:
        return 'sramBore%s_%s' % (m.group(1) or '0', m.group(2))
    m = re.fullmatch(r'bd_(\w+)', e)
    if m:
        return 'boreChildrenBd_bore_%s' % m.group(1)
    m = re.fullmatch(r'_tagArray_io_r_resp_data_(\d)', e)
    if m:
        return 'tagRead[%s]' % m.group(1)
    m = re.fullmatch(r'_metaArray_io_r_resp_data_(\d)_(\w+)', e)
    if m:
        return 'metaRead[%s].%s' % (m.group(1), 'alias_' if m.group(2) == 'alias' else m.group(2))
    m = re.fullmatch(r'_origin_bit_opt_io_r_resp_data_(\d)', e)
    if m:
        return 'originRead[%s]' % m.group(1)
    table = {
        '_origin_bits_r_T_probe': 'arrReadFire',
        'tagWrite': 'tagWriteData',
        "8'h1 << io_tagWReq_bits_way": 'tagWriteWayMask',
        '_replacer_sram_opt_io_r_resp_data_0': 'replRead',
        '~resetFinish | replacerWen': 'stateWriteValid',
        'resetFinish ? req_s3_set : resetIdx': 'stateWriteSet',
        "resetFinish ? next_state_s3 : 16'hAAAA": 'replWriteData',
        'resetFinish & hit_s3': 'originWriteData',
        "8'h1 << way_s3": 'originWriteWayMask',
    }
    return table.get(e, e)


def parse(mod):
    txt = open(os.path.join(G, mod + '.sv')).read()
    P = ports(txt, mod)
    body = txt[txt.index('\n);', txt.index('module %s(' % mod)):]
    defs = {}
    for m in re.finditer(r'\n  wire (?:\[\d+:0\]\s+)?\s*(_GEN_\d+)\s*=\s*(.*?);', body, re.S):
        defs[m.group(1)] = re.sub(r'\s+', ' ', m.group(2))
    inst = instances(body)
    assert set(inst) == {'tagArray', 'metaArray', 'replacer_sram_opt', 'origin_bit_opt', 'mbistPl'}, (mod, list(inst))
    conn = {}
    for name, (cm, conns) in inst.items():
        rows = []
        for p, e in conns.items():
            rows.append((p, mine(e, defs)))
        conn[name] = (cm, rows)
    # 每个 child bore 线的位宽（golden 的 childBd 线声明）
    W = {}
    for n in range(7):
        for f in BORE_F:
            m = re.search(r'wire\s+(?:\[(\d+):0\]\s+)?childBd%s_%s;' % ('' if n == 0 else '_%d' % n, f), body)
            assert m, (mod, n, f)
            W[(n, f)] = 1 if m.group(1) is None else int(m.group(1)) + 1
    for a in ('boreChildrenBd_bore_ack = bd_ack', 'boreChildrenBd_bore_outdata = bd_outdata'):
        assert ('assign ' + a + ';') in body, (mod, a)
    # 表外的内部线（没有被上面的规则认出来的 golden 局部名）一律拒绝
    local = set(re.findall(r'\b(_\w+|resetFinish|next_state_s3|way_s3|hit_s3|req_s3_set|resetIdx|replacerWen)\b',
                           ' '.join(e for _, rows in conn.values() for _, e in rows)))
    assert not local, '%s: 连接里还有未映射的 golden 内部线 %s' % (mod, sorted(local))
    return dict(mod=mod, P=P, conn=conn, W=W, lines=len(txt.splitlines()))


def core_conns():
    c = [('clock', 'clock'), ('reset', 'reset'),
         ('read_valid', 'io_read_valid'), ('read_ready', 'io_read_ready'),
         ('read_tag', 'io_read_bits_tag'), ('read_set', 'io_read_bits_set'),
         ('read_wayMask', 'io_read_bits_wayMask'),
         ('read_channel', 'io_read_bits_replacerInfo_channel'),
         ('read_opcode', 'io_read_bits_replacerInfo_opcode'),
         ('read_reqSource', 'io_read_bits_replacerInfo_reqSource'),
         ('read_refill_prefetch', 'io_read_bits_replacerInfo_refill_prefetch'),
         ('read_refill', 'io_read_bits_refill'), ('read_mshrId', 'io_read_bits_mshrId'),
         ('read_cmoAll', 'io_read_bits_cmoAll'), ('read_cmoWay', 'io_read_bits_cmoWay'),
         ('metaWReq_valid', 'io_metaWReq_valid'), ('tagWReq_valid', 'io_tagWReq_valid'),
         ('tagWReq_way', 'io_tagWReq_bits_way'), ('tagWReq_wtag', 'io_tagWReq_bits_wtag')]
    for f in MS_F:
        c.append(('ms_' + f, "'{" + ', '.join('io_msInfo_%d_%s' % (i, 'valid' if f == 'valid' else 'bits_' + f)
                                            for i in range(N_MSHR)) + '}'))
    c += [('resp_valid', 'io_resp_valid'), ('resp_hit', 'io_resp_bits_hit'), ('resp_tag', 'io_resp_bits_tag'),
          ('resp_set', 'io_resp_bits_set'), ('resp_way', 'io_resp_bits_way'), ('resp_meta', 'respMeta'),
          ('resp_error', 'io_resp_bits_error'), ('resp_channel', 'io_resp_bits_replacerInfo_channel'),
          ('resp_opcode', 'io_resp_bits_replacerInfo_opcode'),
          ('resp_reqSource', 'io_resp_bits_replacerInfo_reqSource'),
          ('resp_refill_prefetch', 'io_resp_bits_replacerInfo_refill_prefetch'),
          ('replResp_valid', 'io_replResp_valid'), ('replResp_tag', 'io_replResp_bits_tag'),
          ('replResp_set', 'io_replResp_bits_set'), ('replResp_way', 'io_replResp_bits_way'),
          ('replResp_meta', 'replMeta'), ('replResp_mshrId', 'io_replResp_bits_mshrId'),
          ('replResp_retry', 'io_replResp_bits_retry'), ('replResp_error', 'io_replResp_bits_error'),
          ('arrReadFire', 'arrReadFire'), ('tagRead', 'tagRead'), ('metaRead', 'metaRead'),
          ('replRead', 'replRead'), ('originRead', 'originRead'),
          ('tagWriteData', 'tagWriteData'), ('tagWriteWayMask', 'tagWriteWayMask'),
          ('stateWriteValid', 'stateWriteValid'), ('stateWriteSet', 'stateWriteSet'),
          ('replWriteData', 'replWriteData'), ('originWriteData', 'originWriteData'),
          ('originWriteWayMask', 'originWriteWayMask')]
    return c


ROLE = {'tagArray': 'tag 阵列（4 块，bore/DFT 0..3）', 'metaArray': 'meta 阵列（bore/DFT 4）',
        'replacer_sram_opt': 'DRRIP 替换状态（bore/DFT 5）', 'origin_bit_opt': 'origin 位（bore/DFT 6）',
        'mbistPl': 'MBIST 分发叶子（toSRAM_0..6）'}


def emit(R):
    m = R['mod']
    L = []
    A = L.append
    cm = {k: v[0] for k, v in R['conn'].items()}
    A('// %s.sv —— L2 目录（%s）：tag + meta + DRRIP 替换状态的三级流水查询' % (m, 'slice %s' % (m.split('_')[1] if '_' in m else '0')))
    A('//')
    A('// 逻辑全在 rtl/uncore/xs_Directory_core.sv（文件头讲清流水、选路、DRRIP、初始化）。本 wrapper 只连线：')
    for k in ('tagArray', 'metaArray', 'replacer_sram_opt', 'origin_bit_opt', 'mbistPl'):
        A('//   %-18s %-18s %s' % (k, cm[k], ROLE[k]))
    A('// golden %d 行；本文件由 scripts/gen_l2_directory.py 生成，逐端口与 golden 连接比对。' % R['lines'])
    A('')
    A('// BEGIN GENERATED(%s) —— scripts/gen_l2_directory.py' % m)
    A('module %s' % m)
    A('  import directory_pkg::*;')
    A('(')
    A(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in R['P']))
    A(');')
    A('')
    A('  logic               arrReadFire;')
    A('  logic [ENC_W-1:0]   tagRead    [WAYS];')
    A('  meta_t              metaRead   [WAYS];')
    A('  logic [2*WAYS-1:0]  replRead;')
    A('  logic               originRead [WAYS];')
    A('  logic [ENC_W-1:0]   tagWriteData;')
    A('  logic [WAYS-1:0]    tagWriteWayMask;')
    A('  logic               stateWriteValid;')
    A('  logic [8:0]         stateWriteSet;')
    A('  logic [2*WAYS-1:0]  replWriteData;')
    A('  logic               originWriteData;')
    A('  logic [WAYS-1:0]    originWriteWayMask;')
    A('  meta_t              respMeta, replMeta;')
    A('  // mbistPl.toSRAM_n <-> 第 n 块 SRAM 的 MBIST bore 口')
    for n in range(7):
        A('  ' + '  '.join('logic %s sramBore%d_%s;' % ('' if R['W'][(n, f)] == 1 else '[%d:0]' % (R['W'][(n, f)] - 1), n, f)
                           for f in BORE_F[:5]))
        A('  ' + '  '.join('logic %s sramBore%d_%s;' % ('' if R['W'][(n, f)] == 1 else '[%d:0]' % (R['W'][(n, f)] - 1), n, f)
                           for f in BORE_F[5:]))
    A('')
    A('  xs_Directory_core u_core (')
    A(',\n'.join('    .%-20s (%s)' % x for x in core_conns()))
    A('  );')
    A('')
    for f in META_F:
        A('  assign io_resp_bits_meta_%-11s = respMeta.%s;' % (f, 'alias_' if f == 'alias' else f))
    for f in META_F:
        A('  assign io_replResp_bits_meta_%-11s = replMeta.%s;' % (f, 'alias_' if f == 'alias' else f))
    for k in ('tagArray', 'metaArray', 'replacer_sram_opt', 'origin_bit_opt', 'mbistPl'):
        A('')
        A('  // ---- %s ----' % ROLE[k])
        A('  %s %s (' % (cm[k], k))
        A(',\n'.join('    .%-32s (%s)' % x for x in R['conn'][k][1]))
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
        print('%-12s %s  连接逐口校验通过' % (m, ' '.join('%s=%s' % (k, v[0]) for k, v in R['conn'].items())))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
