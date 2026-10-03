#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_fastarbiter_l2c.py —— 生成 L2 顶层（TL2CHICoupledL2）里 3 个 FastArbiter 变体的薄 wrapper。

家族规矩（CONVENTIONS「变体家族」）：一个参数化核 + 每变体一个薄文件，核体绝不复制。
  核   = rtl/common/xs_FastArbiter_core.sv（已签核，本脚本不碰）
  薄壳 = rtl/uncore/FastArbiter.sv / FastArbiter_1.sv / FastArbiter_26.sv（本脚本生成）

三个变体的例化者（golden 实测 `grep -n '^  FastArbiter\\(_1\\|_26\\)\\? ' *.sv`）：
  FastArbiter     TL2CHICoupledL2.prefetch_train_arb  4 个 slice 的预取训练请求 → Prefetcher.io.train
  FastArbiter_1   TL2CHICoupledL2.prefetch_resp_arb   4 个 slice 的预取响应     → Prefetcher.io.resp
  FastArbiter_26  TL2CHICoupledL2.txrsp_arb           4 个 slice 的 CHI TXRSP    → 下游 TXRSP
                  （同一单态化也被 OpenLLC 的 RNXbar.rxrspArbs_0 例化）
  Scala：coupledL2/CoupledL2.scala:218 `fastArb(...)` = utility.FastArbiter(gen, n)。

与 gen_fastarbiter_l2.py（FastArbiter_3..7）的差别：这三个变体没有"常量字段"（每个输出字段都有
对应的 4 路输入端口）；FastArbiter_26 多一个 io_chosen 输出（OHToUInt(chosenOH)）—— 核不导出
chosenOH，照 FastArbiter_2 的做法在载荷低 N 位捎带每路的独热标识取回它，不动已签核的核。

★维度全部从 golden 端口表实测，并对 golden 正文做 fail-closed 核对★：
  (a) 端口面只许 clock/reset/io_in_k_{ready,valid,bits_*}/io_out_{ready,valid,bits_*}[/io_chosen]；
  (b) 每个输入字段 4 路齐全、宽度等于同名输出；输出字段集合 == 输入字段集合（无常量字段）；
  (c) 每个 `assign io_out_bits_<f>` 都是 golden 的 Mux1H 形状（chosenOH[k] 选第 k 路，按位或）；
  (d) io_chosen 的 golden 表达式就是 2 位 OHToUInt；
  (e) 两张掩码寄存器 pendingMask / rrGrantMask 宽 N。

用法:
  python3 scripts/gen_fastarbiter_l2c.py          # 幂等写入（内容不变不碰文件）
  python3 scripts/gen_fastarbiter_l2c.py --check  # 只比对不写，有漂移 rc=1（gate 用）
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN', '/home/eda/xs-env/G1-canonical/golden-rtl'))
OUT = REPO / 'rtl' / 'uncore'

FAMILY = ['FastArbiter', 'FastArbiter_1', 'FastArbiter_26']
USERS = {
    'FastArbiter': 'TL2CHICoupledL2.sv（实例 prefetch_train_arb）',
    'FastArbiter_1': 'TL2CHICoupledL2.sv（实例 prefetch_resp_arb）',
    'FastArbiter_26': 'TL2CHICoupledL2.sv（实例 txrsp_arb）、RNXbar.sv（实例 rxrspArbs_0）',
}
ROLE = {
    'FastArbiter': 'L2 4 个 slice 的预取训练请求（PrefetchTrain）汇入 Prefetcher 的仲裁',
    'FastArbiter_1': 'L2 4 个 slice 的预取响应（PrefetchResp，只剩 pfSource 字段）汇入 Prefetcher 的仲裁',
    'FastArbiter_26': 'L2 4 个 slice 的 CHI TXRSP 汇成一路下游的仲裁（带赢家下标 io_chosen）',
}

SV_KEYWORDS = {'alias', 'bit', 'byte', 'int', 'logic', 'reg', 'wire', 'type', 'time', 'string',
               'input', 'output', 'module', 'package', 'struct', 'union', 'enum', 'const'}


class Variant:
    def __init__(self, name):
        self.name = name
        src = (GOLDEN / (name + '.sv')).read_text()
        m = re.search(r'^module %s\(\n(.*?)\n\);\n' % name, src, re.S | re.M)
        if not m:
            raise SystemExit('golden %s.sv 里找不到 module 端口表' % name)
        body = src[m.end():]
        self.ports = []
        for ln in m.group(1).split('\n'):
            mm = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?\s*$', ln)
            if not mm:
                raise SystemExit('%s: 解析不了端口行 %r' % (name, ln))
            self.ports.append((mm.group(1), int(mm.group(2)) + 1 if mm.group(2) else 1, mm.group(3)))
        pn = [p for _, _, p in self.ports]
        # (a) 端口面
        bad = [p for p in pn if not re.match(r'(clock|reset|io_in_\d+_(ready|valid|bits_\w+)|'
                                             r'io_out_(ready|valid|bits_\w+)|io_chosen)$', p)]
        if bad:
            raise SystemExit('%s: 端口面外的端口 %s' % (name, bad))
        self.n = 1 + max(int(re.match(r'io_in_(\d+)_valid$', p).group(1))
                         for p in pn if re.match(r'io_in_(\d+)_valid$', p))
        for i in range(self.n):
            for s in ('valid', 'ready'):
                if 'io_in_%d_%s' % (i, s) not in pn:
                    raise SystemExit('%s: 缺 io_in_%d_%s' % (name, i, s))
        for s in ('clock', 'reset', 'io_out_ready', 'io_out_valid'):
            if s not in pn:
                raise SystemExit('%s: 缺 %s' % (name, s))
        self.chosen = 'io_chosen' in pn
        # (b) 字段表：顺序 = golden 输出端口顺序
        self.fields = [(p[len('io_out_bits_'):], w) for d, w, p in self.ports if p.startswith('io_out_bits_')]
        width = dict(self.fields)
        ins = {}
        for d, w, p in self.ports:
            mm = re.match(r'io_in_(\d+)_bits_(\w+)$', p)
            if mm:
                ins.setdefault(mm.group(2), {})[int(mm.group(1))] = w
        if set(ins) != set(width):
            raise SystemExit('%s: 输入字段 %s != 输出字段 %s（本族不应有常量字段）'
                             % (name, sorted(ins), sorted(width)))
        for f, per in ins.items():
            if set(per) != set(range(self.n)) or set(per.values()) != {width[f]}:
                raise SystemExit('%s: 字段 %s 路数/宽度不齐 %s' % (name, f, per))
        # (c) Mux1H 形状
        flat = re.sub(r'\s+', ' ', body)
        for f, w in self.fields:
            ma = re.search(r'assign io_out_bits_%s = (.*?);' % f, flat)
            if not ma:
                raise SystemExit('%s: golden 无 io_out_bits_%s 的 assign' % (name, f))
            e = ma.group(1)
            if w == 1:
                terms = re.split(r' \| ', e)
                want = ['chosenOH[%d] & io_in_%d_bits_%s' % (k, k, f) for k in range(self.n)]
            else:
                terms = [t.strip('() ') for t in re.split(r'\) \| \(', e)]
                want = ['chosenOH[%d] ? io_in_%d_bits_%s : %d\'h0' % (k, k, f, w) for k in range(self.n)]
            if terms != want:
                raise SystemExit('%s: io_out_bits_%s 不是 Mux1H 形状: %r' % (name, f, e))
        # (d) io_chosen = OHToUInt(chosenOH)（N=4 时 2 位）
        if self.chosen:
            if self.n != 4:
                raise SystemExit('%s: io_chosen 只核对过 N=4' % name)
            mc = re.search(r'assign io_chosen = (.*?);', flat)
            if not mc or mc.group(1) != '{|(chosenOH[3:2]), chosenOH[3] | chosenOH[1]}':
                raise SystemExit('%s: io_chosen 不是 OHToUInt 形状: %r' % (name, mc and mc.group(1)))
        # (e) 掩码寄存器宽度
        for r in ('pendingMask', 'rrGrantMask'):
            if not re.search(r'reg \[%d:0\] %s;' % (self.n - 1, r), flat):
                raise SystemExit('%s: 找不到 reg [%d:0] %s' % (name, self.n - 1, r))
        self.w = sum(w for _, w in self.fields)

    def fid(self, f):
        return f + '_f' if f in SV_KEYWORDS else f


def rng(w):
    return '[%d:0] ' % (w - 1) if w > 1 else ''


def wrapper(v):
    pk = v.name.lower() + '_pkg'
    L = []
    L.append('// ' + '=' * 77)
    L.append('// %s.sv —— FastArbiter 家族薄 wrapper：%s' % (v.name, ROLE[v.name]))
    L.append('//')
    L.append('// 本变体规模：N=%d 路，载荷打平 W=%d 位（%d 个字段，无常量字段）。' % (v.n, v.w, len(v.fields)))
    L.append('//   例化者：%s。' % USERS[v.name])
    if v.chosen:
        L.append('//   多一个 io_chosen 输出 = 赢家下标（OHToUInt(chosenOH)）。核不导出 chosenOH，这里在')
        L.append('//   载荷低 N 位捎带第 k 路的独热标识 1<<k：核按 Mux1H（按位或）选载荷，输出低 N 位')
        L.append('//   恰好就是 chosenOH（无人 valid 时全 0）—— 与 FastArbiter_2 同一做法，不改已签核的核。')
    L.append('//')
    L.append('// 本文件只做"字段打包 → 核 → 拆包"的端口对位；仲裁逻辑（轮转 + 挂起记忆）')
    L.append('// 在 rtl/common/xs_FastArbiter_core.sv，全家族共一份。')
    L.append('// 本文件由 scripts/gen_fastarbiter_l2c.py 生成，勿手改。')
    L.append('// golden 对照：G1-canonical/golden-rtl/%s.sv' % v.name)
    L.append('// ' + '=' * 77)
    L.append('package %s;' % pk)
    L.append('  // 载荷字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。')
    L.append('  typedef struct packed {')
    fw = max(len(rng(w)) for _, w in v.fields)
    for f, w in v.fields:
        L.append('    logic %s%s;' % (rng(w).ljust(fw), v.fid(f)))
    L.append('  } payload_t;')
    L.append('endpackage')
    L.append('')
    L.append('module %s import %s::*; (' % (v.name, pk))
    pw = max(len(rng(w)) for _, w, _ in v.ports)
    for i, (d, w, p) in enumerate(v.ports):
        sep = ',' if i < len(v.ports) - 1 else ''
        L.append('  %-6s %s%s%s' % (d, rng(w).ljust(pw), p, sep))
    L.append(');')
    L.append('  localparam int N = %d;' % v.n)
    L.append('  localparam int W = $bits(payload_t);')
    L.append('')
    if v.chosen:
        L.append('  // 每路送进核的字 = {载荷, 独热标识}')
        L.append('  typedef struct packed {')
        L.append('    payload_t     payload;')
        L.append('    logic [N-1:0] tag_oh;   // 第 k 路恒为 1<<k')
        L.append('  } word_t;')
        L.append('')
        L.append('  // ---- 打包：第 i 路的全部字段按字段表拼成一个 payload_t，低位捎带独热标识')
        L.append('  word_t [N-1:0] in_word;')
        for i in range(v.n):
            L.append('  assign in_word[%d] = \'{' % i)
            L.append('    payload: \'{')
            for j, (f, _) in enumerate(v.fields):
                L.append('      %s: io_in_%d_bits_%s%s' % (v.fid(f), i, f, ',' if j < len(v.fields) - 1 else ''))
            L.append('    },')
            L.append("    tag_oh: N'(1 << %d)" % i)
            L.append('  };')
        L.append('')
        L.append('  // ---- 核例化：仲裁逻辑全在 xs_FastArbiter_core')
        L.append('  word_t out_word;')
        core_w, core_in, core_out = '$bits(word_t)', 'in_word', 'out_word'
    else:
        L.append('  // ---- 打包：第 i 路的全部字段按字段表拼成一个 payload_t')
        L.append('  payload_t [N-1:0] in_payload;')
        for i in range(v.n):
            L.append('  assign in_payload[%d] = \'{' % i)
            for j, (f, _) in enumerate(v.fields):
                L.append('    %s: io_in_%d_bits_%s%s' % (v.fid(f), i, f, ',' if j < len(v.fields) - 1 else ''))
            L.append('  };')
        L.append('')
        L.append('  // ---- 核例化：仲裁逻辑全在 xs_FastArbiter_core')
        L.append('  payload_t out_payload;')
        core_w, core_in, core_out = 'W', 'in_payload', 'out_payload'
    valids = ', '.join('io_in_%d_valid' % i for i in reversed(range(v.n)))
    readys = ', '.join('io_in_%d_ready' % i for i in reversed(range(v.n)))
    L.append('  xs_FastArbiter_core #(.N(N), .W(%s)) u_core (' % core_w)
    L.append('    .clock     (clock),')
    L.append('    .reset     (reset),')
    L.append('    .in_valid  ({%s}),' % valids)
    L.append('    .in_bits   (%s),' % core_in)
    L.append('    .in_ready  ({%s}),' % readys)
    L.append('    .out_ready (io_out_ready),')
    L.append('    .out_valid (io_out_valid),')
    L.append('    .out_bits  (%s)' % core_out)
    L.append('  );')
    L.append('')
    L.append('  // ---- 拆包：与打包共用同一张字段表')
    src = 'out_word.payload' if v.chosen else 'out_payload'
    for f, _ in v.fields:
        L.append('  assign io_out_bits_%s = %s.%s;' % (f, src, v.fid(f)))
    if v.chosen:
        L.append('')
        L.append('  // ---- 赢家下标：OHToUInt(chosenOH)，chosenOH = 载荷捎带回来的独热标识')
        L.append('  logic [N-1:0] chosen_oh;')
        L.append('  assign chosen_oh = out_word.tag_oh;')
        L.append('  assign io_chosen = {chosen_oh[3] | chosen_oh[2], chosen_oh[3] | chosen_oh[1]};')
    L.append('endmodule')
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    rc = 0
    for name in FAMILY:
        v = Variant(name)
        txt = wrapper(v)
        path = OUT / (name + '.sv')
        old = path.read_text() if path.exists() else None
        if a.check:
            if old != txt:
                print('DRIFT: %s 与生成结果不一致' % path.relative_to(REPO))
                rc = 1
            else:
                print('ok  %s  N=%d W=%d fields=%d chosen=%s' % (name, v.n, v.w, len(v.fields), v.chosen))
        elif old != txt:
            path.write_text(txt)
            print('wrote %s' % path.relative_to(REPO))
        else:
            print('unchanged %s' % path.relative_to(REPO))
    return rc


if __name__ == '__main__':
    sys.exit(main())
