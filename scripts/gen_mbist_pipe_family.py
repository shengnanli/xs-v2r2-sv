#!/usr/bin/env python3
"""gen_mbist_pipe_family.py —— 从 G1 golden 生成 MbistPipe* 家族的 24 个变体薄文件。

本脚本**每次运行都重新证明家族假设**，而不是信任一张写死的参数表：

  1. check_groups()   把 24 个 golden 归一化模块名后取 md5 分组，报告到底有几种
                      模块体。教训：前端小家族里 ICacheMSHR x14 被误判成"同核不同
                      参"，实测是同一份逻辑单态化复制 14 份；反过来按"不同实参"
                      设计参数表就会凭空造出不存在的参数维度。所以每次都重数。
  2. parse_golden()   把每个 golden 的**每一条语句**去套家族模板，套不上的语句
                      是硬错误（证明 golden 里没有模板以外的东西）。
  3. check_invariants() 校验从 golden 反推出的家族不变量：
        ARRAY_W == clog2(max_id+1)；child 的 ARRAY_W 同理按自己的最大 id 算；
        各 child 的 id 区间连续、首尾相接、并集连续；
        selectedOH 宽度 == 该 child 的 id 个数；
        节点的 DATA_W/BE_W/ADDR_W/ARRAY_W == 各 child 对应值的最大值。
  4. verify_reduce() / verify_selected_oh()
                      用一个小的 Verilog 表达式求值器，把 golden 自己写的读数据
                      归约树和 selectedOH 表达式**符号执行**一遍，逐位证明它们
                      等于模板形式（firtool 会把它们折叠成 (&arrayReg)、
                      {6{allReg}}、分段 OR 树等花样，肉眼核对不可靠）。

用法：
    python3 scripts/gen_mbist_pipe_family.py            # 校验 + 生成
    python3 scripts/gen_mbist_pipe_family.py --check    # 只校验，不写文件
"""
import argparse
import glob
import hashlib
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _mbist_vexpr import ev, V   # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
OUT_DIR = os.path.join(REPO, 'rtl', 'dft')

MODS = sorted(os.path.basename(p)[:-3] for p in glob.glob(G + '/MbistPipe*.sv'))

# 家族外、但由 --scan-adjacent 机器判定"可原样套本核"的同总线节点（agent/l2slice 并入）。
# 它们**不进** MODS：gen_mbist_ut.py 的 24 变体 tb 与 docs/mbist_pipe_family.json 都按 MODS
# 生成，混进去会改动已出证 UT 的字节。这里只借用 parse_golden / check_invariants /
# verify_reduce 三道机器校验 + emit_variant，产物另放、UT 另立（verif/ut/L2Slice）。
EXTRA_MODS = ['L2Slice', 'L2Slice_1', 'L2Slice_2', 'L2Slice_3',
              # extraHold 叶子：读/写使能用 2 位展宽寄存器，核是 rtl/dft/xs_mbist_hold_leaf_core.sv
              'L2DataStorage', 'L2DataStorage_1', 'L2DataStorage_2', 'L2DataStorage_3',
              # Directory_1..3 层的普通叶子（slice 0 的 L2Directory 另有已签核的手写件 rtl/uncore/L2Directory.sv，不在此列）
              'L2Directory_1', 'L2Directory_2', 'L2Directory_3']

# 每个变体服务哪个存储阵列：由 golden 的例化关系机械抓出来的（父模块 + 与本
# pipe 的 toSRAM/toNextPipeline 网线相连的实例类型），写进薄文件头供读者定位。
SERVES = {
 'MbistPipeDCacheData':    ('BankedDataArray', 'DCache 数据阵列 8 bank x 4 way 的 SRAM'),
 'MbistPipeDcacheTag':     ('DuplicatedTagArray', 'DCache tag 阵列 TagArray x4（4 份复制）'),
 'MbistPipeFrontend':      ('Frontend', '前端整棵 MBIST 子树（ICache + 分支预测器 Predictor）'),
 'MbistPipeFtb':           ('FTBBank', '分支预测 FTB（Fetch Target Buffer）的 SplittedSRAMTemplate_2'),
 'MbistPipeIcacheDataWay0':('ICacheDataArray', 'ICache 数据阵列 way0 的 8 个 SRAMTemplateWithFixedWidth'),
 'MbistPipeIcacheDataWay1':('ICacheDataArray', 'ICache 数据阵列 way1 的 8 个 SRAMTemplateWithFixedWidth'),
 'MbistPipeIcacheDataWay2':('ICacheDataArray', 'ICache 数据阵列 way2 的 8 个 SRAMTemplateWithFixedWidth'),
 'MbistPipeIcacheDataWay3':('ICacheDataArray', 'ICache 数据阵列 way3 的 8 个 SRAMTemplateWithFixedWidth'),
 'MbistPipeIcacheTag':     ('ICacheMetaArray', 'ICache tag/meta 阵列 SplittedSRAMTemplate x2'),
 'MbistPipeIttage':        ('ITTageTable',   'ITTage 表 0 的 FoldedSRAMTemplate_22（单 bore 口）'),
 'MbistPipeIttage_1':      ('ITTageTable_1', 'ITTage 表 1 的 FoldedSRAMTemplate_22（单 bore 口）'),
 'MbistPipeIttage_2':      ('ITTageTable_2', 'ITTage 表 2 的 FoldedSRAMTemplate_24（双 bore 口）'),
 'MbistPipeIttage_3':      ('ITTageTable_3', 'ITTage 表 3 的 FoldedSRAMTemplate_24（双 bore 口）'),
 'MbistPipeIttage_4':      ('ITTageTable_4', 'ITTage 表 4 的 FoldedSRAMTemplate_24（双 bore 口）'),
 'MbistPipeL2Prefetcher':  ('Prefetcher',    'L2 预取器 BestOffset 的 P/V 两张 score 表'),
 'MbistPipeMemBlk':        ('MemBlock',      '访存块整棵 MBIST 子树（DCache + L2TLB + SMS 预取器）'),
 'MbistPipePtwL0':         ('PtwCache',      'L2TLB 页表缓存 L0 级 SplittedSRAM_2（16 路）'),
 'MbistPipePtwL1':         ('PtwCache',      'L2TLB 页表缓存 L1 级 SplittedSRAM_1（单口 6 way）'),
 'MbistPipeSc':            ('SCTable',       'TAGE-SC 统计校正表 0 的 SRAMTemplate_68 x2'),
 'MbistPipeSc_1':          ('SCTable_1',     'TAGE-SC 统计校正表 1 的 SRAMTemplate_68 x2'),
 'MbistPipeSc_2':          ('SCTable_2',     'TAGE-SC 统计校正表 2 的 SRAMTemplate_68 x2'),
 'MbistPipeSc_3':          ('SCTable_3',     'TAGE-SC 统计校正表 3 的 SRAMTemplate_68 x2'),
 'MbistPipeSms':           ('MemBlock',      'SMS 空间访存流预取器的表'),
 'MbistPipeTage':          ('Tage_SC',       'TAGE 4 张预测表 + TageBTable 基础表 + us 表'),
 'L2Slice':                ('Slice',         'L2 slice 0 的 MBIST 子树：child0=Directory 层(L2Directory)、child1=DataStorage 层(L2DataStorage)'),
 'L2Slice_1':              ('Slice_1',       'L2 slice 1 的 MBIST 子树：child0=Directory 层(L2Directory_1)、child1=DataStorage 层(L2DataStorage_1)'),
 'L2Slice_2':              ('Slice_2',       'L2 slice 2 的 MBIST 子树：child0=Directory 层(L2Directory_2)、child1=DataStorage 层(L2DataStorage_2)'),
 'L2DataStorage':          ('DataStorage',   'L2 slice 0 数据阵列 GatedSplittedSRAM 的 4 个 137 位 bank（extraHold 多周期 SRAM）'),
 'L2DataStorage_1':        ('DataStorage_1', 'L2 slice 1 数据阵列 GatedSplittedSRAM_1 的 4 个 bank（extraHold）'),
 'L2DataStorage_2':        ('DataStorage_2', 'L2 slice 2 数据阵列 GatedSplittedSRAM_2 的 4 个 bank（extraHold）'),
 'L2DataStorage_3':        ('DataStorage_3', 'L2 slice 3 数据阵列 GatedSplittedSRAM_3 的 4 个 bank（extraHold）'),
 'L2Directory_1':          ('Directory_1',   'L2 slice 1 目录层 7 块 SRAM（tag 4 块 + meta + 替换状态 + origin 位）'),
 'L2Directory_2':          ('Directory_2',   'L2 slice 2 目录层 7 块 SRAM（tag 4 块 + meta + 替换状态 + origin 位）'),
 'L2Directory_3':          ('Directory_3',   'L2 slice 3 目录层 7 块 SRAM（tag 4 块 + meta + 替换状态 + origin 位）'),
 'L2Slice_3':              ('Slice_3',       'L2 slice 3 的 MBIST 子树：child0=Directory 层(L2Directory_3)、child1=DataStorage 层(L2DataStorage_3)'),
}


# ------------------------------------------------- elaborate 期消息可读性闸 ---
CORE_SV = os.path.join(REPO, 'rtl', 'dft', 'xs_mbist_pipe_core.sv')


def check_fatal_bytes(path=None):
    """核里 elaborate 期 $fatal 的文本不许含 UTF-8 编码里带 0xAE 字节的汉字。

    实测（本机 VCS W-2024.09-SP1）：elaborate 阶段的 Error-[FEST] 消息会把 0xAE
    这个字节吞掉，日志因此既不是合法 UTF-8、读起来也是乱码——参数写错的人恰恰
    最需要看懂这句话。运行期 $fatal 不受影响，只有 elaborate 期这样。
    中招的常用字（按字节判，不是背黑名单）：认 宽 算 定 实 完 家 容 据 目 宏 段 管 …
    """
    path = path or CORE_SV
    txt = open(path).read()
    bad = []
    for m in re.finditer(r'\$fatal\(\s*\d+\s*,\s*"((?:[^"\\]|\\.)*)"', txt, re.S):
        ch = sorted({c for c in m.group(1) if b'\xae' in c.encode('utf-8')})
        if ch:
            bad.append((txt[:m.start()].count('\n') + 1, ''.join(ch)))
    if bad:
        for ln, ch in bad:
            print('!! %s:%d elaborate 期 $fatal 文本含会被 VCS 吞掉的字: %s' % (path, ln, ch))
        raise SystemExit('elaborate 期消息里有 0xAE 字节，出错时读到的会是乱码')
    print('== elaborate 期 $fatal 文本闸：%d 条消息均无 0xAE 字节（VCS 不会打成乱码）=='
          % len(re.findall(r'\$fatal\(', txt)))


# ---------------------------------------------------------------- 同构分析 ---
def check_groups(verbose=True):
    """归一化模块名后按 md5 分组，报告真正有几种模块体。"""
    groups = {}
    for m in MODS:
        txt = open(os.path.join(G, m + '.sv')).read()
        norm = re.sub(r'\b%s\b' % re.escape(m), 'M', txt)
        groups.setdefault(hashlib.md5(norm.encode()).hexdigest()[:10], []).append(m)
    if verbose:
        print('== 同构分析：%d 个 golden 归一化模块名后有 %d 种不同的模块体 ==' % (len(MODS), len(groups)))
        for h, ms in sorted(groups.items(), key=lambda kv: -len(kv[1])):
            tag = '（%d 份逐字节相同的单态化复制）' % len(ms) if len(ms) > 1 else ''
            print('   %s %s%s' % (h, ' '.join(sorted(ms)), tag))
    return groups


# ------------------------------------------------------------ golden 解析 ---
def load_body(mod):
    t = open(os.path.join(G, mod + '.sv')).read()
    i = t.index('module %s(' % mod)
    b = t[i:t.index('\nendmodule', i)]
    return re.sub(r"  `ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_\n", '', b, flags=re.S)


def split_ports(b):
    out = []
    for line in b[b.index('(') + 1:b.index(');')].split(','):
        line = line.strip()
        if not line:
            continue
        m = re.match(r'^(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?([A-Za-z_]\w*)$', line)
        assert m, 'bad port %r' % line
        assert m.group(3) in (None, '0'), line
        out.append((m.group(4), m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1))
    return out


def statements(b):
    body = b[b.index(');') + 2:]
    blocks = []
    for m in re.finditer(r'  always @\(posedge[^\n]*\n.*?\n  end // always @\([^\n]*\)\n', body, flags=re.S):
        blocks.append(re.sub(r'\s+', ' ', m.group(0)).strip())
        body = body.replace(m.group(0), '')
    txt = re.sub(r'\s+', ' ', body).strip()
    return [s.strip() + ';' for s in txt.split(';') if s.strip()], blocks


TOK = re.compile(r"\d+'[hb][0-9a-fA-F_]+|\b[A-Za-z_]\w*\b")


def inline(expr, named, depth=0):
    assert depth < 60, 'wire inlining too deep'
    return TOK.sub(lambda m: ('(' + inline(named[m.group(0)], named, depth + 1) + ')')
                   if m.group(0) in named else m.group(0), expr)


def sel_set(expr, var, W):
    """expr 为真的 var 取值集合（allReg/mbist_all 钉 0，mbist_req 钉 1）。"""
    env0 = {'allReg': V(0, 1), 'mbist_all': V(0, 1), 'mbist_req': V(1, 1)}
    out = set()
    for v in range(1 << W):
        env = dict(env0)
        env[var] = V(v, W)
        if ev(expr, env).v:
            out.add(v)
    return out


def clog2(n):
    return max(1, (n - 1).bit_length())


def parse_golden(mod):
    """把 golden 的每条语句套模板；套不上就抛异常。返回参数字典。"""
    b = load_body(mod)
    ports = split_ports(b)
    P = {n: (d, w) for n, d, w in ports}
    isnode = any(n.startswith('toNextPipeline_') for n in P)
    pfx = 'toNextPipeline_' if isnode else 'toSRAM_'
    kids = sorted({int(re.match(r'%s(\d+)_' % pfx, n).group(1)) for n in P if n.startswith(pfx)})
    assert kids == list(range(len(kids)))
    AW = P['mbist_array'][1]
    ss, blocks = statements(b)
    left = list(ss)

    def take(pat):
        for i, s in enumerate(left):
            m = re.match(pat + '$', s)
            if m:
                left.pop(i)
                return m
        return None

    R = dict(module=mod, kind='node' if isnode else 'leaf', nchild=len(kids),
             ARRAY_W=AW, BE_W=P['mbist_be'][1], ADDR_W=P['mbist_addr'][1],
             DATA_W=P['mbist_indata'][1], ports=ports)
    assert P['mbist_addr_rd'][1] == R['ADDR_W'] and P['mbist_outdata'][1] == R['DATA_W']

    m = take(r"wire activated = mbist_all \| mbist_req(?: & (.*))?;")
    assert m, '%s: 没有识别出 activated' % mod
    R['all_ids'] = sorted(sel_set(m.group(1), 'mbist_array', AW)) if m.group(1) else list(range(1 << AW))

    regs = {}
    while True:
        m = take(r"reg (?:\[(\d+):0\] )?(\w+);")
        if not m:
            break
        regs[m.group(2)] = 1 if m.group(1) is None else int(m.group(1)) + 1
    R['regs'] = regs
    while take(r"wire \[\d+:0\] (?:sramDataOut_\d+|_sramDataOut_\d+_T);"):
        pass

    named = {}
    while True:
        m = take(r"wire (?:\[\d+:0\] )?(selectedVec_[\w]+|selected(?:_\d+)?|doSpread(?:_\d+)?|_pipelineDataOut_\d+_T) = (.*);")
        if not m:
            break
        named[m.group(1)] = m.group(2)

    child = []
    for k in kids:
        dsn = 'doSpread' if k == 0 else 'doSpread_%d' % k
        assert dsn in named, '%s: 缺 %s' % (mod, dsn)
        child.append(dict(idx=k, ids=sorted(sel_set(inline(named[dsn], named), 'arrayReg', AW))))
    R['child'] = child

    def sl(w, full):
        return '' if w == full else (r'\[%d:0\]' % (w - 1) if w > 1 else r'\[0\]')

    # extraHold 叶子：golden 没有 wenReg/renReg，改为 2 位 wen/renStretched（见 xs_mbist_hold_leaf_core.sv）
    hold = 'wenStretched' in regs
    assert not (hold and isnode), '%s: extraHold 只见于叶子' % mod
    if hold:
        assert regs['wenStretched'] == 2 and regs['renStretched'] == 2 and 'wenReg' not in regs, mod
    R['hold'] = hold
    ren, wen = (r'renStretched\[0\]', r'wenStretched\[0\]') if hold else ('renReg', 'wenReg')
    if not isnode:
        for c in child:
            k, sfx = c['idx'], ('' if c['idx'] == 0 else '_%d' % c['idx'])
            c['ADDR_W'] = P['%s%d_addr' % (pfx, k)][1]
            c['DATA_W'] = P['%s%d_wdata' % (pfx, k)][1]
            c['BE_W'] = P['%s%d_wmask' % (pfx, k)][1]
            c['ARRAY_W'] = P['%s%d_array' % (pfx, k)][1]
            c['OH_W'] = P['%s%d_selectedOH' % (pfx, k)][1]
            assert P['%s%d_addr_rd' % (pfx, k)][1] == c['ADDR_W']
            assert P['%s%d_rdata' % (pfx, k)][1] == c['DATA_W']
            a, d, be, ar = (sl(c['ADDR_W'], R['ADDR_W']), sl(c['DATA_W'], R['DATA_W']),
                            sl(c['BE_W'], R['BE_W']), sl(c['ARRAY_W'], AW))
            for pat in (r"assign %s%d_addr = doSpread%s \? addrReg%s : \d+'h0;" % (pfx, k, sfx, a),
                        r"assign %s%d_addr_rd = doSpread%s \? addrRdReg%s : \d+'h0;" % (pfx, k, sfx, a),
                        r"assign %s%d_wdata = dataInReg%s;" % (pfx, k, d),
                        r"assign %s%d_wmask = beReg%s;" % (pfx, k, be),
                        r"assign %s%d_re = doSpread%s & %s;" % (pfx, k, sfx, ren),
                        r"assign %s%d_we = doSpread%s & %s;" % (pfx, k, sfx, wen),
                        r"assign %s%d_ack = reqReg;" % (pfx, k)):
                assert take(pat), '%s child%d: golden 里没有模板语句 %s' % (mod, k, pat)
            mo = take(r"assign %s%d_selectedOH = (.*);" % (pfx, k))
            assert mo, '%s child%d selectedOH' % (mod, k)
            c['_oh'] = mo.group(1)
            assert take(r"assign %s%d_array = arrayReg%s;" % (pfx, k, ar)), '%s child%d array' % (mod, k)
        while True:
            m = take(r"wire \[\d+:0\] (_GEN(?:_\d+)?) = (.*);")
            if not m:
                break
            named[m.group(1)] = m.group(2)
        while True:
            m = take(r"assign (sramDataOut_\d+|_sramDataOut_\d+_T) = (.*);")
            if not m:
                break
            named[m.group(1)] = m.group(2)
        assert take(r"assign mbist_ack = reqReg;"), mod
        m = take(r"assign mbist_outdata = (.*);")
        assert m, mod
        R['_reduce'] = m.group(1)
    else:
        for c in child:
            k, sfx = c['idx'], ('' if c['idx'] == 0 else '_%d' % c['idx'])
            c['ADDR_W'] = P['%s%d_addr' % (pfx, k)][1]
            c['DATA_W'] = P['%s%d_indata' % (pfx, k)][1]
            c['BE_W'] = P['%s%d_be' % (pfx, k)][1]
            c['ARRAY_W'] = P['%s%d_array' % (pfx, k)][1]
            c['OH_W'] = 0
            assert P['%s%d_outdata' % (pfx, k)][1] == c['DATA_W']
            a, d, be, ar = (sl(c['ADDR_W'], R['ADDR_W']), sl(c['DATA_W'], R['DATA_W']),
                            sl(c['BE_W'], R['BE_W']), sl(c['ARRAY_W'], AW))
            for pat in (r"assign %s%d_array = doSpread%s \? arrayReg%s : \d+'h0;" % (pfx, k, sfx, ar),
                        r"assign %s%d_all = doSpread%s & allReg;" % (pfx, k, sfx),
                        r"assign %s%d_req = reqReg;" % (pfx, k),
                        r"assign %s%d_writeen = doSpread%s & wenReg;" % (pfx, k, sfx),
                        r"assign %s%d_be = beReg%s;" % (pfx, k, be),
                        r"assign %s%d_addr = doSpread%s \? addrReg%s : \d+'h0;" % (pfx, k, sfx, a),
                        r"assign %s%d_indata = dataInReg%s;" % (pfx, k, d),
                        r"assign %s%d_readen = doSpread%s & renReg;" % (pfx, k, sfx),
                        r"assign %s%d_addr_rd = doSpread%s \? addrRdReg%s : \d+'h0;" % (pfx, k, sfx, a)):
                assert take(pat), '%s child%d: golden 里没有模板语句 %s' % (mod, k, pat)
        while True:
            m = take(r"wire \[\d+:0\] (_GEN(?:_\d+)?) = (.*);")
            if not m:
                break
            named[m.group(1)] = m.group(2)
        m = take(r"assign mbist_ack = reqReg & \((.*)\);")
        assert m, mod
        assert sorted(int(x) for x in re.findall(r'toNextPipeline_(\d+)_ack', m.group(1))) == kids
        assert take(r"assign mbist_outdata = pipelineDataOutReg;"), mod
        bm = [x for x in blocks if 'pipelineDataOutReg' in x]
        assert len(bm) == 1
        mm = re.match(r"always @\(posedge clock\) begin if \(activated\) pipelineDataOutReg <= (.*); end // always @\(posedge\)$", bm[0])
        assert mm, '%s: pipelineDataOutReg 的 always 块不是模板形状' % mod
        R['_reduce'] = mm.group(1)

    assert not left, '%s: golden 有 %d 条语句套不进家族模板：%s' % (mod, len(left), left[:3])
    R['_named'] = named
    return R


# ------------------------------------------------------------- 不变量校验 ---
def check_invariants(R):
    m, ch = R['module'], R['child']
    flat = [i for c in ch for i in c['ids']]
    assert flat == sorted(flat), '%s: child 未按 id 升序' % m
    assert flat == list(range(flat[0], flat[0] + len(flat))), '%s: 各 child 的 id 并集不连续' % m
    assert flat == R['all_ids'], '%s: child id 并集 != activated 认领集合' % m
    assert R['ARRAY_W'] == clog2(max(flat) + 1), '%s: ARRAY_W != clog2(max_id+1)' % m
    for c in ch:
        assert c['ids'] == list(range(c['ids'][0], c['ids'][0] + len(c['ids']))), \
            '%s child%d: id 区间不连续' % (m, c['idx'])
        assert c['ARRAY_W'] == clog2(max(c['ids']) + 1), \
            '%s child%d: array 端口 %d 位 != clog2(0x%x+1)=%d' % (m, c['idx'], c['ARRAY_W'], max(c['ids']), clog2(max(c['ids']) + 1))
        if R['kind'] == 'leaf':
            assert c['OH_W'] == len(c['ids']), '%s child%d: selectedOH 宽度 != id 个数' % (m, c['idx'])
    for k in ('DATA_W', 'BE_W', 'ADDR_W', 'ARRAY_W'):
        assert R[k] == max(c[k] for c in ch), '%s: %s != 各 child 最大值' % (m, k)


def verify_reduce(R):
    """逐位符号执行 golden 自己的读数据归约树。"""
    red = inline(R['_reduce'], R['_named'])
    dp = (lambda k: 'toNextPipeline_%d_outdata' % k) if R['kind'] == 'node' else (lambda k: 'toSRAM_%d_rdata' % k)
    n = 0
    for c in R['child']:
        for aid in c['ids']:
            for b in range(c['DATA_W']):
                env = {dp(c2['idx']): (V(1 << b, c2['DATA_W']) if c2['idx'] == c['idx']
                                       else V((1 << c2['DATA_W']) - 1, c2['DATA_W']))
                       for c2 in R['child']}
                env['arrayReg'] = V(aid, R['ARRAY_W'])
                env['allReg'] = V(0, 1)
                got = ev(red, env)
                assert got.v == (1 << b) and got.w == R['DATA_W'], \
                    '%s child%d id0x%x bit%d: 归约结果 %s' % (R['module'], c['idx'], aid, b, got)
                n += 1
    for aid in range(1 << R['ARRAY_W']):          # 未认领的 id 不能泄漏任何数据
        if aid in R['all_ids']:
            continue
        env = {dp(c['idx']): V((1 << c['DATA_W']) - 1, c['DATA_W']) for c in R['child']}
        env['arrayReg'] = V(aid, R['ARRAY_W'])
        env['allReg'] = V(0, 1)
        assert ev(red, env).v == 0, '%s: 未认领 id 0x%x 泄漏读数据' % (R['module'], aid)
        n += 1
    return n


def verify_selected_oh(R):
    """穷举 (arrayReg, allReg, reqReg) 证明 selectedOH == 模板形式。"""
    if R['kind'] == 'node':
        return 0
    n = 0
    for c in R['child']:
        e = inline(c['_oh'], R['_named'])
        W = c['OH_W']
        for aid in range(1 << R['ARRAY_W']):
            for allr in (0, 1):
                for req in (0, 1):
                    got = ev(e, {'arrayReg': V(aid, R['ARRAY_W']), 'allReg': V(allr, 1), 'reqReg': V(req, 1)})
                    oh = sum(1 << i for i, idv in enumerate(c['ids']) if idv == aid)
                    want = (1 << W) - 1 if (allr or not req) else oh
                    assert got.v == want and got.w == W, \
                        '%s child%d aid=0x%x all=%d req=%d: selectedOH=%s want=%x' % (R['module'], c['idx'], aid, allr, req, got, want)
                    n += 1
    return n


# ------------------------------------------------------------------ 生成 ---
def wdecl(w):
    return '' if w == 1 else '[%d:0] ' % (w - 1)


def emit_hold_variant(R):
    """extraHold 叶子（L2DataStorage*）：例化 xs_mbist_hold_leaf_core。"""
    m = R['module']
    ch = R['child']
    parent, serves = SERVES[m]
    lo, hi = min(R['all_ids']), max(R['all_ids'])
    maxids = max(len(c['ids']) for c in ch)
    L = []
    A = L.append
    A('// %s.sv —— MBIST 分发树的 extraHold 叶子节点：%s' % (m, serves))
    A('//')
    A('// 本变体参数（全部从 G1 golden 逐根量出来，见 scripts/gen_mbist_pipe_family.py）：')
    A('//   拓扑      叶子（extraHold）：直接驱动 SRAM 的 bore 口，%d 个 child（toSRAM_0..%d）' % (R['nchild'], R['nchild'] - 1))
    A('//   例化于    %s' % parent)
    A('//   MBIST array id  0x%02X..0x%02X（共 %d 个），故 ARRAY_W = clog2(0x%X+1) = %d 位'
      % (lo, hi, len(R['all_ids']), hi, R['ARRAY_W']))
    A('//   上游总线  addr/addr_rd %d 位  indata/outdata %d 位  be %d 位' % (R['ADDR_W'], R['DATA_W'], R['BE_W']))
    A('//   规模      golden %d 行 / %d 端口；本文件只做参数化例化 + 端口展平，逻辑全在 xs_mbist_hold_leaf_core'
      % (len(open(os.path.join(G, m + '.sv')).read().splitlines()), len(R['ports'])))
    A('//')
    A('// 各 child 认领的 array id 与端口宽度：')
    for c in ch:
        ids = ('0x%02X' % c['ids'][0]) if len(c['ids']) == 1 else ('0x%02X..0x%02X' % (c['ids'][0], c['ids'][-1]))
        A('//   child %-2d  id %-13s array %d 位  addr %-2d  data %-3d  be %-2d  selectedOH %d 位'
          % (c['idx'], ids, c['ARRAY_W'], c['ADDR_W'], c['DATA_W'], c['BE_W'], c['OH_W']))
    A('//')
    A('// extraHold 与普通叶子的区别讲在 rtl/dft/xs_mbist_hold_leaf_core.sv 文件头；')
    A('// 分发树整体讲在 rtl/dft/xs_mbist_pipe_core.sv 文件头。')
    A('')
    A('// BEGIN GENERATED(%s) —— 由 scripts/gen_mbist_pipe_family.py 从 G1 golden 生成' % m)
    A('module %s (' % m)
    A(',\n'.join('  %-6s logic %s%s' % (d, wdecl(w), n) for n, d, w in R['ports']))
    A(');')
    A('')
    A('  localparam int unsigned N_CHILD = %d;' % R['nchild'])
    A('  localparam int unsigned MAX_IDS = %d;' % maxids)
    A('  localparam int unsigned ARRAY_W = %d;' % R['ARRAY_W'])
    A('  localparam int unsigned ADDR_W  = %d;' % R['ADDR_W'])
    A('  localparam int unsigned DATA_W  = %d;' % R['DATA_W'])
    A('  localparam int unsigned BE_W    = %d;' % R['BE_W'])
    A('')
    A('  logic [ARRAY_W-1:0] ch_array      [N_CHILD];')
    A('  logic               ch_ack        [N_CHILD];')
    A('  logic               ch_writeen    [N_CHILD];')
    A('  logic [BE_W-1:0]    ch_wmask      [N_CHILD];')
    A('  logic [ADDR_W-1:0]  ch_addr       [N_CHILD];')
    A('  logic [DATA_W-1:0]  ch_wdata      [N_CHILD];')
    A('  logic               ch_readen     [N_CHILD];')
    A('  logic [ADDR_W-1:0]  ch_addr_rd    [N_CHILD];')
    A('  logic [MAX_IDS-1:0] ch_selectedOH [N_CHILD];')
    A('  logic [DATA_W-1:0]  ch_rdata      [N_CHILD];')
    A('')
    A('  xs_mbist_hold_leaf_core #(')
    A('    .N_CHILD (N_CHILD),')
    A('    .ARRAY_W (ARRAY_W),')
    A('    .BE_W    (BE_W),')
    A('    .ADDR_W  (ADDR_W),')
    A('    .DATA_W  (DATA_W),')
    A("    .ID_LO   ('{%s})," % ', '.join("'h%02X" % c['ids'][0] for c in ch))
    A("    .ID_CNT  ('{%s})," % ', '.join(str(len(c['ids'])) for c in ch))
    A('    .MAX_IDS (MAX_IDS)')
    A('  ) u_core (')
    A('    .clock (clock), .reset (reset),')
    A('    .mbist_array (mbist_array), .mbist_all (mbist_all), .mbist_req (mbist_req),')
    A('    .mbist_ack (mbist_ack), .mbist_writeen (mbist_writeen), .mbist_be (mbist_be),')
    A('    .mbist_addr (mbist_addr), .mbist_indata (mbist_indata), .mbist_readen (mbist_readen),')
    A('    .mbist_addr_rd (mbist_addr_rd), .mbist_outdata (mbist_outdata),')
    A('    .ch_array (ch_array), .ch_ack (ch_ack), .ch_writeen (ch_writeen), .ch_wmask (ch_wmask),')
    A('    .ch_addr (ch_addr), .ch_wdata (ch_wdata), .ch_readen (ch_readen), .ch_addr_rd (ch_addr_rd),')
    A('    .ch_selectedOH (ch_selectedOH), .ch_rdata (ch_rdata)')
    A('  );')
    A('')
    A('  // 端口展平：核按上游最大位宽给，这里截到每个 child 的实宽；读数据反向零扩展。')

    def cut(sig, w, full):
        return sig if w == full else '%s[%d:0]' % (sig, w - 1)
    for c in ch:
        k = c['idx']
        A('  // ---- child %d ----' % k)
        A('  assign toSRAM_%d_addr       = %s;' % (k, cut('ch_addr[%d]' % k, c['ADDR_W'], R['ADDR_W'])))
        A('  assign toSRAM_%d_addr_rd    = %s;' % (k, cut('ch_addr_rd[%d]' % k, c['ADDR_W'], R['ADDR_W'])))
        A('  assign toSRAM_%d_wdata      = %s;' % (k, cut('ch_wdata[%d]' % k, c['DATA_W'], R['DATA_W'])))
        A('  assign toSRAM_%d_wmask      = %s;' % (k, cut('ch_wmask[%d]' % k, c['BE_W'], R['BE_W'])))
        A('  assign toSRAM_%d_re         = ch_readen[%d];' % (k, k))
        A('  assign toSRAM_%d_we         = ch_writeen[%d];' % (k, k))
        A('  assign toSRAM_%d_ack        = ch_ack[%d];' % (k, k))
        A('  assign toSRAM_%d_selectedOH = %s;' % (k, cut('ch_selectedOH[%d]' % k, c['OH_W'], maxids)))
        A('  assign toSRAM_%d_array      = %s;' % (k, cut('ch_array[%d]' % k, c['ARRAY_W'], R['ARRAY_W'])))
        A("  assign ch_rdata[%d]         = DATA_W'(toSRAM_%d_rdata);" % (k, k))
    A('')
    A('endmodule')
    A('// END GENERATED(%s)' % m)
    return '\n'.join(L) + '\n'


def emit_variant(R):
    if R.get('hold'):
        return emit_hold_variant(R)
    m = R['module']
    kind = R['kind']
    ch = R['child']
    pfx = 'toNextPipeline_' if kind == 'node' else 'toSRAM_'
    parent, serves = SERVES[m]
    lo, hi = min(R['all_ids']), max(R['all_ids'])
    L = []
    A = L.append
    A('// %s.sv —— MBIST 分发树的 %s 节点：%s' % (m, '中间(node)' if kind == 'node' else '叶子(leaf)', serves))
    A('//')
    A('// 本变体参数（全部从 G1 golden 逐根量出来，见 scripts/gen_mbist_pipe_family.py）：')
    A('//   拓扑      %s，%d 个 child（%s）' % ('中间节点：往下接 MbistPipe' if kind == 'node' else '叶子：直接驱动 SRAM 的 bore 口',
                                                R['nchild'], 'toNextPipeline_0..%d' % (R['nchild'] - 1) if kind == 'node' else 'toSRAM_0..%d' % (R['nchild'] - 1)))
    A('//   例化于    %s' % parent)
    A('//   MBIST array id  0x%02X..0x%02X（共 %d 个），故 ARRAY_W = clog2(0x%X+1) = %d 位'
      % (lo, hi, len(R['all_ids']), hi, R['ARRAY_W']))
    A('//   上游总线  addr/addr_rd %d 位  indata/outdata %d 位  be %d 位'
      % (R['ADDR_W'], R['DATA_W'], R['BE_W']))
    A('//   规模      golden %d 行 / %d 端口；本文件只做参数化例化 + 端口展平，逻辑全在 xs_mbist_pipe_core'
      % (len(open(os.path.join(G, m + '.sv')).read().splitlines()), len(R['ports'])))
    A('//')
    aws = sorted({c['ARRAY_W'] for c in ch})
    A('// 各 child 认领的 array id 与端口宽度。child 的 array 端口按**它自己**的最大 id 算宽，')
    if len(aws) > 1:
        A('// 本变体因此出现 %s 位并存的参差宽度——这正是本家族最容易写错的地方：'
          % '/'.join(str(x) for x in aws))
    else:
        A('// 本变体各 child 恰好都是 %d 位（不要当成"反正照抄父节点宽度"——换个变体就不是了）：' % aws[0])
    for c in ch:
        ids = ('0x%02X' % c['ids'][0]) if len(c['ids']) == 1 else ('0x%02X..0x%02X' % (c['ids'][0], c['ids'][-1]))
        A('//   child %-2d  id %-13s array %d 位  addr %-2d  data %-3d  be %-2d%s'
          % (c['idx'], ids, c['ARRAY_W'], c['ADDR_W'], c['DATA_W'], c['BE_W'],
             '  selectedOH %d 位' % c['OH_W'] if kind == 'leaf' else ''))
    A('//')
    A('// MBIST 分发树整体是怎么回事、bore 口每根线什么含义、array id 怎么编址，')
    A('// 全部讲在核文件 rtl/dft/xs_mbist_pipe_core.sv 的文件头，不在这里重复。')
    A('')
    A('// BEGIN GENERATED(%s) —— 由 scripts/gen_mbist_pipe_family.py 从 G1 golden 生成' % m)
    A('module %s (' % m)
    plines = []
    for n, d, w in R['ports']:
        plines.append('  %-6s logic %s%s' % (d, wdecl(w), n))
    A(',\n'.join(plines))
    A(');')
    A('')
    # core instance
    A('  localparam int unsigned N_CHILD = %d;' % R['nchild'])
    A('  localparam int unsigned MAX_IDS = %d;' % max(len(c['ids']) for c in ch))
    A('  localparam int unsigned ARRAY_W = %d;' % R['ARRAY_W'])
    A('  localparam int unsigned ADDR_W  = %d;' % R['ADDR_W'])
    A('  localparam int unsigned DATA_W  = %d;' % R['DATA_W'])
    A('  localparam int unsigned BE_W    = %d;' % R['BE_W'])
    A('')
    A('  logic [ARRAY_W-1:0] ch_array      [N_CHILD];')
    A('  logic               ch_all        [N_CHILD];')
    A('  logic               ch_reqpulse   [N_CHILD];')
    A('  logic               ch_writeen    [N_CHILD];')
    A('  logic [BE_W-1:0]    ch_wmask      [N_CHILD];')
    A('  logic [ADDR_W-1:0]  ch_addr       [N_CHILD];')
    A('  logic [DATA_W-1:0]  ch_wdata      [N_CHILD];')
    A('  logic               ch_readen     [N_CHILD];')
    A('  logic [ADDR_W-1:0]  ch_addr_rd    [N_CHILD];')
    A('  logic [MAX_IDS-1:0] ch_selectedOH [N_CHILD];')
    A('  logic [DATA_W-1:0]  ch_rdata      [N_CHILD];')
    A('  logic               ch_ack        [N_CHILD];')
    A('')
    A('  xs_mbist_pipe_core #(')
    A('    .IS_NODE (1\'b%d),' % (1 if kind == 'node' else 0))
    A('    .N_CHILD (N_CHILD),')
    A('    .ARRAY_W (ARRAY_W),')
    A('    .BE_W    (BE_W),')
    A('    .ADDR_W  (ADDR_W),')
    A('    .DATA_W  (DATA_W),')
    A('    .ID_LO   (\'{%s}),' % ', '.join("'h%02X" % c['ids'][0] for c in ch))
    A('    .ID_CNT  (\'{%s}),' % ', '.join(str(len(c['ids'])) for c in ch))
    A('    .MAX_IDS (MAX_IDS)')
    A('  ) u_core (')
    A('    .clock (clock), .reset (reset),')
    A('    .mbist_array (mbist_array), .mbist_all (mbist_all), .mbist_req (mbist_req),')
    A('    .mbist_ack (mbist_ack), .mbist_writeen (mbist_writeen), .mbist_be (mbist_be),')
    A('    .mbist_addr (mbist_addr), .mbist_indata (mbist_indata), .mbist_readen (mbist_readen),')
    A('    .mbist_addr_rd (mbist_addr_rd), .mbist_outdata (mbist_outdata),')
    A('    .ch_array (ch_array), .ch_all (ch_all), .ch_reqpulse (ch_reqpulse),')
    A('    .ch_writeen (ch_writeen), .ch_wmask (ch_wmask), .ch_addr (ch_addr),')
    A('    .ch_wdata (ch_wdata), .ch_readen (ch_readen), .ch_addr_rd (ch_addr_rd),')
    A('    .ch_selectedOH (ch_selectedOH), .ch_rdata (ch_rdata), .ch_ack (ch_ack)')
    A('  );')
    A('')
    A('  // 端口展平：核按上游最大位宽给，这里截到每个 child 的实宽；读数据反向零扩展。')
    for c in ch:
        k = c['idx']
        A('  // ---- child %d：array id %s ----'
          % (k, ('0x%02X' % c['ids'][0]) if len(c['ids']) == 1 else '0x%02X..0x%02X' % (c['ids'][0], c['ids'][-1])))
        def cut(sig, w, full):
            return sig if w == full else '%s[%d:0]' % (sig, w - 1)
        if kind == 'leaf':
            A('  assign %s%d_addr       = %s;' % (pfx, k, cut('ch_addr[%d]' % k, c['ADDR_W'], R['ADDR_W'])))
            A('  assign %s%d_addr_rd    = %s;' % (pfx, k, cut('ch_addr_rd[%d]' % k, c['ADDR_W'], R['ADDR_W'])))
            A('  assign %s%d_wdata      = %s;' % (pfx, k, cut('ch_wdata[%d]' % k, c['DATA_W'], R['DATA_W'])))
            A('  assign %s%d_wmask      = %s;' % (pfx, k, cut('ch_wmask[%d]' % k, c['BE_W'], R['BE_W'])))
            A('  assign %s%d_re         = ch_readen[%d];' % (pfx, k, k))
            A('  assign %s%d_we         = ch_writeen[%d];' % (pfx, k, k))
            A('  assign %s%d_ack        = ch_reqpulse[%d];' % (pfx, k, k))
            A('  assign %s%d_selectedOH = %s;' % (pfx, k, cut('ch_selectedOH[%d]' % k, c['OH_W'], max(len(x['ids']) for x in ch))))
            A('  assign %s%d_array      = %s;' % (pfx, k, cut('ch_array[%d]' % k, c['ARRAY_W'], R['ARRAY_W'])))
            A('  assign ch_rdata[%d]    = DATA_W\'(%s%d_rdata);' % (k, pfx, k))
            A('  assign ch_ack[%d]      = 1\'b0;   // 叶子不看 SRAM 的 ack' % k)
        else:
            A('  assign %s%d_array   = %s;' % (pfx, k, cut('ch_array[%d]' % k, c['ARRAY_W'], R['ARRAY_W'])))
            A('  assign %s%d_all     = ch_all[%d];' % (pfx, k, k))
            A('  assign %s%d_req     = ch_reqpulse[%d];' % (pfx, k, k))
            A('  assign %s%d_writeen = ch_writeen[%d];' % (pfx, k, k))
            A('  assign %s%d_be      = %s;' % (pfx, k, cut('ch_wmask[%d]' % k, c['BE_W'], R['BE_W'])))
            A('  assign %s%d_addr    = %s;' % (pfx, k, cut('ch_addr[%d]' % k, c['ADDR_W'], R['ADDR_W'])))
            A('  assign %s%d_indata  = %s;' % (pfx, k, cut('ch_wdata[%d]' % k, c['DATA_W'], R['DATA_W'])))
            A('  assign %s%d_readen  = ch_readen[%d];' % (pfx, k, k))
            A('  assign %s%d_addr_rd = %s;' % (pfx, k, cut('ch_addr_rd[%d]' % k, c['ADDR_W'], R['ADDR_W'])))
            A('  assign ch_rdata[%d] = DATA_W\'(%s%d_outdata);' % (k, pfx, k))
            A('  assign ch_ack[%d]   = %s%d_ack;' % (k, pfx, k))
    A('')
    A('endmodule')
    A('// END GENERATED(%s)' % m)
    return '\n'.join(L) + '\n'


# G1 里"名字不叫 MbistPipe*、但总线长得一样"的邻居。同一个 Chisel
# utility.mbist.MbistPipeline 单态化出来的其实不止 24 个：本函数把家族模板拿去
# 套这些邻居，机器判定哪些能直接复用本核、哪些还差点什么。给下一个 owner 用。
ADJACENT = ['MbistBitmapCache', 'L2Cache',
            'L2Slice', 'L2Slice_1', 'L2Slice_2', 'L2Slice_3',
            'L2Directory', 'L2Directory_1', 'L2Directory_2', 'L2Directory_3',
            'L2DataStorage', 'L2DataStorage_1', 'L2DataStorage_2', 'L2DataStorage_3',
            'MbistIntfFrontend', 'MbistIntfL2', 'MbistIntfMemBlk']


def scan_adjacent():
    print('== 家族邻居扫描：把本核的模板拿去套 MbistPipe* 之外的同总线模块 ==')
    ok, ng = [], []
    for m in ADJACENT:
        if not os.path.exists(os.path.join(G, m + '.sv')):
            continue
        try:
            R = parse_golden(m)
            check_invariants(R)
            verify_reduce(R)
            verify_selected_oh(R)
            ok.append(m)
            print('   [可直接复用] %-18s %-4s nch=%-2d AW=%-2d BE=%-2d ADDR=%-2d DATA=%-4d'
                  % (m, R['kind'], R['nchild'], R['ARRAY_W'], R['BE_W'], R['ADDR_W'], R['DATA_W']))
        except (AssertionError, KeyError, ValueError) as e:
            ng.append((m, str(e)[:110]))
    for m, why in ng:
        print('   [还差点  ] %-18s %s' % (m, why))
    print('   小结：%d 个可原样套本核，%d 个套不上（需要扩核或另立）' % (len(ok), len(ng)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true', help='只校验，不写文件')
    ap.add_argument('--scan-adjacent', action='store_true',
                    help='扫描 MbistPipe* 之外、总线相同的邻居模块能否复用本核')
    a = ap.parse_args()
    if a.scan_adjacent:
        scan_adjacent()
        return 0

    check_fatal_bytes()
    print()
    check_groups()
    print()
    Rs, nred, noh = [], 0, 0
    for m in MODS:
        R = parse_golden(m)
        check_invariants(R)
        nred += verify_reduce(R)
        noh += verify_selected_oh(R)
        Rs.append(R)
    print('== golden 模板校验：%d 个模块的每条语句都套进了模板（0 条剩余）==' % len(Rs))
    print('   读数据归约   %d 次逐位符号执行全部通过' % nred)
    print('   selectedOH   %d 次穷举全部通过' % noh)
    nleaf = sum(1 for R in Rs if R['kind'] == 'leaf')
    print('   叶子 %d 个 / 中间节点 %d 个；child 总数 %d'
          % (nleaf, len(Rs) - nleaf, sum(R['nchild'] for R in Rs)))
    Xs = []
    for m in EXTRA_MODS:
        R = parse_golden(m)
        check_invariants(R)
        nx = verify_reduce(R) + verify_selected_oh(R)
        Xs.append(R)
        print('   家族外节点 %-10s 同样套进模板（%d 次逐位符号执行/穷举通过）' % (m, nx))
    if a.check:
        # 产物漂移也算失败：磁盘上的薄文件必须逐字节等于本次生成结果。
        drift = [R['module'] for R in Rs + Xs
                 if not os.path.exists(os.path.join(OUT_DIR, R['module'] + '.sv'))
                 or open(os.path.join(OUT_DIR, R['module'] + '.sv')).read() != emit_variant(R)]
        if drift:
            print('DRIFT: %s 与生成结果不一致（重跑本脚本）' % ' '.join(drift))
            return 1
        return 0
    os.makedirs(OUT_DIR, exist_ok=True)
    for R in Rs + Xs:
        path = os.path.join(OUT_DIR, R['module'] + '.sv')
        txt = emit_variant(R)
        if not os.path.exists(path) or open(path).read() != txt:
            open(path, 'w').write(txt)
    json.dump([{k: v for k, v in R.items() if not k.startswith('_') and k != 'hold'} for R in Rs],
              open(os.path.join(REPO, 'docs', 'mbist_pipe_family.json'), 'w'), indent=1)
    print('\n生成 %d 个变体薄文件 -> %s' % (len(Rs) + len(Xs), OUT_DIR))
    return 0


if __name__ == '__main__':
    sys.exit(main())
