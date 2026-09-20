#!/usr/bin/env python3
"""gen_rob_contract.py -- 把 Rob 核必须实现的**寄存器契约**从 golden 机械算出来。

产物 docs/rob_core_contract.tsv：一行一个寄存器（数组按族折叠），列出
  声明名 / 位宽 / 深度 / 复位域 / 复位值 / 名字是否被 pin 契约锁死 / golden 样例名

为什么要这张表（三件事都在这里，缺一件就会出错且不报错）
--------------------------------------------------------
1. **一位不少**。golden 的 169,763 个寄存器 bit 里 79% 是 160 条目的 debug 阵列。
   上一轮省掉它们，直接的后果是 FM 的 match 爬不动。表底有总位数校验。
2. **两个 always 块严格对应**。golden 把 2,280 个寄存器放异步复位块、9,359 个
   放无复位块，两块**不相交**。核里写反或者合并，FM 会撞 FMR_VLOG-144
   （`if (reset)` 必须是块首）；更糟的是复位值写错不会撞任何工具，只会在
   上电那几拍不一样。复位值这里逐个列出，不靠记忆。
3. **名字被 pin 契约锁死的那些**。scripts/gen_rob_pins.py 钉的 9 族 + 2 个一维族，
   核里必须原样叫 `<prefix>_<field>`；其余（r / io_perf / REG / io_error /
   perfEvents_r）没被钉，核里可以起语义名（比如 golden 的 r_0..r_23 其实是
   exceptionVec 的 24 个 RegEnable）。这一列就是"哪些名字不能改"。

用法
  python3 scripts/gen_rob_contract.py --write
  python3 scripts/gen_rob_contract.py --check     # 幂等闸
"""
import argparse, collections, hashlib, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_rob_pins

GOLDEN = os.environ.get(
    'ROB_GOLDEN', '/home/eda/xs-env/G1-canonical/golden-rtl/Rob.sv')
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET = os.path.join(REPO, 'docs', 'rob_core_contract.tsv')


def registers(lines):
    out = {}
    for l in lines:
        m = re.match(r'\s*reg\s*(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*(\w+)\s*;', l)
        if m:
            w = 1 if m.group(1) is None else int(m.group(1)) - int(m.group(2)) + 1
            out[m.group(3)] = w
    return out


def reset_arm(lines):
    """异步复位块的复位臂：-> {reg: reset_value_literal}。

    ★按 begin/end 配对切出复位臂★，不按缩进猜：缩进在 firtool 的长表达式折行里
    不可靠，而多切/少切几条会让"哪些寄存器有复位"整个错位。
    """
    s = next(k for k, l in enumerate(lines)
             if l.startswith('  always @(posedge clock or posedge reset)'))
    e = next(k for k in range(s, len(lines)) if lines[k].startswith('  end // always'))
    k = s + 1
    if lines[k].strip() != 'if (reset) begin':
        raise SystemExit('gen_rob_contract: 异步块首不是 `if (reset) begin`，'
                         '而是 %r —— golden 变了，先看清楚再改这个脚本'
                         % lines[k].strip())
    vals, depth, k = {}, 1, k + 1
    while k < e:
        t = lines[k].strip()
        if t.endswith('begin'):
            depth += 1
        elif t.startswith('end'):
            depth -= 1
            if depth == 0:
                break
        m = re.match(r'(\w+)\s*<=\s*(.*);$', t)
        if m:
            vals[m.group(1)] = m.group(2)
        k += 1
    return vals


def build(golden):
    text = open(golden).read()
    lines = text.split('\n')
    regs = registers(lines)
    rst = reset_arm(lines)
    pinned, _d = gen_rob_pins.golden_arrays(golden)

    # pin 契约锁死的声明名集合
    locked = set()
    for pre, flds in pinned.items():
        for fld in flds:
            locked.add(pre if fld is None else '%s_%s' % (pre, fld))

    # 折叠：<prefix>_<idx>_<field>
    fam = collections.defaultdict(dict)
    rest = {}
    for n, w in regs.items():
        m = re.match(r'^(.*?)_(\d+)_(.+)$', n)
        if m:
            fam[(m.group(1), m.group(3))][int(m.group(2))] = (w, n)
        else:
            rest[n] = w
    # 再折一维族（只折 pin 白名单里的，理由见 gen_rob_pins.ONE_D_ARRAYS）
    one_d = {}
    for pre in gen_rob_pins.ONE_D_ARRAYS:
        idxs = {}
        for n in list(rest):
            m = re.match(r'^%s_(\d+)$' % re.escape(pre), n)
            if m:
                idxs[int(m.group(1))] = (rest.pop(n), n)
        if idxs:
            one_d[pre] = idxs

    rows = []

    def domain(sample_names):
        has = [n in rst for n in sample_names]
        if all(has):
            vs = {rst[n] for n in sample_names}
            return 'async', (vs.pop() if len(vs) == 1 else '|'.join(sorted(vs)))
        if not any(has):
            return 'none', '-'
        return 'SPLIT', '-'

    for (pre, fld), idxs in sorted(fam.items()):
        ws = {w for w, _ in idxs.values()}
        names = [n for _, n in idxs.values()]
        dom, val = domain(names)
        decl = '%s_%s' % (pre, fld)
        # ★稠密性要查★：`r_4_0..r_4_23`（exceptionVec 的 24 个 RegEnable）会折成
        # 前缀 r、字段 '0'..'23'、下标只有 {4} 的一堆"族"。它们不是阵列存储，是
        # firtool 的**命名撞车**。当成 depth=1 的数组写进契约，读表的人会照着
        # 声明一个 `r_0[1]` —— 名字、深度、下标全错。所以非稠密的另标 BUCKET，
        # 并把真实下标集合写出来。
        dense = set(idxs) == set(range(len(idxs)))
        kind = 'ARRAY' if (dense and len(ws) == 1) else 'BUCKET'
        depth = str(len(idxs)) if kind == 'ARRAY' else \
            'idx{%s}' % ','.join(str(x) for x in sorted(idxs))
        rows.append((kind, decl,
                     ('|'.join(str(x) for x in sorted(ws))),
                     depth, dom, val,
                     'locked' if decl in locked else 'free',
                     sorted(names)[0]))
    for pre, idxs in sorted(one_d.items()):
        ws = {w for w, _ in idxs.values()}
        names = [n for _, n in idxs.values()]
        dom, val = domain(names)
        rows.append(('ARRAY1D', pre, '|'.join(str(x) for x in sorted(ws)),
                     str(len(idxs)), dom, val,
                     'locked' if pre in locked else 'free', sorted(names)[0]))
    for n, w in sorted(rest.items()):
        dom, val = domain([n])
        rows.append(('SCALAR', n, str(w), '1', dom, val, 'free', n))

    # 位数按**逐个寄存器**加，不按"族宽 x 深度"推算：族可能是宽度不齐的 BUCKET，
    # 推算会得到一个看着合理的错数（gen_rob.py --regmap 早先取 min 宽度，
    # 少算了 380 bit，总数 169,763 而不是 170,143）。
    bits_total = sum(regs.values())
    n_array = sum(1 for r in rows if r[0] in ('ARRAY', 'ARRAY1D'))
    n_bucket = sum(1 for r in rows if r[0] == 'BUCKET')
    tot_async = len(rst)
    tot_none = len(regs) - len(rst)
    head = [
        '# gen_rob_contract.py 生成，勿手改。重跑：python3 scripts/gen_rob_contract.py --write',
        '# golden %s' % golden,
        '# golden sha256 %s' % hashlib.sha256(text.encode()).hexdigest(),
        '# 寄存器声明 %d 个；异步复位 %d / 无复位 %d（两块不相交）'
        % (len(regs), tot_async, tot_none),
        '# 寄存器总位数 %d（逐个相加，不由族宽 x 深度推算）' % bits_total,
        '# 折叠结果：真数组 %d 条 / firtool 命名撞车桶 BUCKET %d 条 / 散寄存器 %d 条'
        % (n_array, n_bucket, sum(1 for r in rows if r[0] == 'SCALAR')),
        '# BUCKET = 名字折得进 <prefix>_<idx>_<field> 但下标不稠密或宽度不齐，'
        '不是阵列存储，别照着它声明数组。',
        '# name_lock=locked 表示 verif/ut/Rob/fm_pins.tcl 钉了这个名字，核里必须原样叫；',
        '#          free 表示没被钉，核里可以起语义名。',
        '# reset_domain=async 的进 `always_ff @(posedge clock or posedge reset)`，',
        '#              if (reset) 必须写在块首，否则 FM 撞 FMR_VLOG-144；',
        '#              none 的进 `always_ff @(posedge clock)`。',
        '\t'.join(['kind', 'decl_name', 'width', 'depth', 'reset_domain',
                   'reset_value', 'name_lock', 'golden_example']),
    ]
    body = ['\t'.join(r) for r in rows]
    return '\n'.join(head + body) + '\n', {
        'regs': len(regs), 'async': tot_async, 'none': tot_none,
        'bits': bits_total, 'rows': len(rows),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--golden', default=GOLDEN)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--write', action='store_true')
    g.add_argument('--check', action='store_true')
    a = ap.parse_args()
    text, st = build(a.golden)
    if a.write:
        os.makedirs(os.path.dirname(TARGET), exist_ok=True)
        with open(TARGET, 'w') as f:
            f.write(text)
        print('wrote %s: %d rows, %d regs, async %d / none %d, %d bits'
              % (TARGET, st['rows'], st['regs'], st['async'], st['none'],
                 st['bits']))
        return 0
    if not os.path.exists(TARGET):
        sys.stderr.write('gen_rob_contract --check: %s 不存在（已入库）\n' % TARGET)
        return 1
    if open(TARGET).read() != text:
        sys.stderr.write('gen_rob_contract --check: %s 与重新生成的不一致，重跑 --write\n'
                         % TARGET)
        return 1
    print('gen_rob_contract --check: OK（%d 行，%d bit）' % (st['rows'], st['bits']))
    return 0


if __name__ == '__main__':
    sys.exit(main())
