#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_mshrctl.py —— 从 golden 端口表机械生成 rtl/uncore/MSHRCtl.sv 里的 GENERATED 区。

MSHRCtl 的 Scala 只有 ~260 行；golden 的 14,590 行几乎全是 16×MSHR（287 口）+ 4 个 16 路
仲裁器（mshr_task_arb 一个就 80 字段×16）+ SourceB + 选择器的扁平连线。可读核的"真逻辑"
（占用计数、分配、响应分发、写回 ID、性能计数）是手写的；这里只生成连线：

  core_ports    xs_MSHRCtl_core 端口表（= golden MSHRCtl 端口表，逐位同名同序）
  ms_arrays     每个 MSHR 端口一根 16 元素数组 ms_<端口>（输出 + 按表项不同的输入）
  ms_entries    generate 16 份 MSHR，端口按 RULES 表连到数组 / 广播输入
  ms_ports      golden 的逐表项扁平端口（msInfo_N / msStatus_N / msAlloc_N / pCrd_N）<-> 数组
  children      txreq_arb / txrsp_arb / source_b_arb / mshr_task_arb / sourceB / mshrSelector
  wrapper       golden 同名 wrapper MSHRCtl：按名直连 u_core
  nav           本文件导航

★fail-closed★：每个 child 端口都必须恰好命中一条规则、命中的源信号必须真实存在
（在 golden MSHRCtl 端口表或 MSHR 数组里），否则直接报错退出。

用法:
  python3 scripts/gen_mshrctl.py          # 幂等写入
  python3 scripts/gen_mshrctl.py --check  # 只比对不写，有漂移 rc=1（gate 用）
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN',
                                    '/home/eda/xs-env/G1-canonical/golden-rtl'))
TARGET = REPO / 'rtl' / 'uncore' / 'MSHRCtl.sv'
TOP = 'MSHRCtl'
N = 16


def golden_ports(top):
    src = (GOLDEN / (top + '.sv')).read_text()
    m = re.search(r'^module %s\(\n(.*?)\n\);\n' % top, src, re.S | re.M)
    if not m:
        raise SystemExit('golden %s.sv 里找不到 module 端口表' % top)
    ports = []
    for ln in m.group(1).split('\n'):
        mm = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?\s*$', ln)
        if not mm:
            raise SystemExit('%s: 解析不了端口行 %r' % (top, ln))
        ports.append((mm.group(1), int(mm.group(2)) + 1 if mm.group(2) else 1, mm.group(3)))
    return ports


TOP_PORTS = golden_ports(TOP)
TOP_NAMES = {n: (d, w) for d, w, n in TOP_PORTS}
MSHR_PORTS = golden_ports('MSHR')


def arr_name(mshr_port):
    """MSHR 端口 → 数组名：去掉 io_ 前缀加 ms_。"""
    return 'ms_' + (mshr_port[3:] if mshr_port.startswith('io_') else mshr_port)


# ---------------------------------------------------------------------------
# MSHR 端口连线规则：(正则, 目标模板, 是否需要数组)。{i} = 表项下标（genvar i）
#   目标里 "TOP:" 前缀 = golden MSHRCtl 的端口（要求存在）；"ARR" = 本端口对应的数组元素；
#   "HAND:" = 手写区声明的 16 位向量（按表项 gate 过的 valid 等）。
# ---------------------------------------------------------------------------
RULES = [
    (r'clock|reset', 'TOP:{p}'),
    (r'io_id', "EXPR:8'(i)"),
    (r'io_alloc_valid', 'HAND:alloc_valid[i]'),
    (r'io_alloc_bits_(\w+)', 'TOP:io_fromMainPipe_mshr_alloc_s3_bits_{1}'),
    (r'io_resps_(sinkC|rxrsp|rxdat)_valid', 'HAND:{1}_valid[i]'),
    (r'io_resps_(sinkC|rxrsp|rxdat)_bits_(\w+)', 'TOP:io_resps_{1}_respInfo_{2}'),
    (r'io_nestedwb_(\w+)', 'TOP:io_nestedwb_{1}'),
    (r'io_aMergeTask_valid', 'HAND:aMerge_valid[i]'),
    (r'io_aMergeTask_bits_(\w+)', 'TOP:io_aMergeTask_bits_task_{1}'),
    (r'io_replResp_valid', 'HAND:replResp_valid[i]'),
    (r'io_replResp_bits_(\w+)', 'TOP:io_replResp_bits_{1}'),
    (r'io_dsResp_valid', 'HAND:dsResp_valid[i]'),
    (r'io_dsResp_bits_(\w+)', 'TOP:io_dsResp_bits_{1}'),
    (r'io_pCrd_grant', 'ARR'),
    (r'io_tasks_\w+_ready', 'ARR'),
    (r'(io_\w+|acquire_period_\w+|release_period_\w+)', 'ARR'),   # 其余全是输出
]


def mshr_conn(d, w, p):
    hits = [(pat, tgt) for pat, tgt in RULES if re.fullmatch(pat, p)]
    if not hits:
        raise SystemExit('MSHR 端口 %s 没有连线规则' % p)
    pat, tgt = hits[0]
    m = re.fullmatch(pat, p)
    if tgt == 'ARR':
        if d == 'input' and not (p == 'io_pCrd_grant' or p.endswith('_ready')):
            raise SystemExit('MSHR 输入 %s 落到了 ARR 规则（应有专门规则）' % p)
        return '%s[i]' % arr_name(p), True
    kind, body = tgt.split(':', 1)
    body = body.format(m.group(0), *m.groups(), p=p)
    if kind == 'TOP':
        if body not in TOP_NAMES:
            raise SystemExit('MSHR.%s -> %s：golden MSHRCtl 端口表里没有' % (p, body))
        if TOP_NAMES[body][1] != w:
            raise SystemExit('MSHR.%s(%d) -> %s(%d)：位宽不符' % (p, w, body, TOP_NAMES[body][1]))
    return body, False


def decl(w, name, packed_n=None):
    if packed_n:
        return 'logic %s%s;' % ('[%d:0]' % (packed_n - 1) + ('[%d:0]' % (w - 1) if w > 1 else '') + ' ', name)
    return 'logic %s%s;' % ('[%d:0] ' % (w - 1) if w > 1 else '', name)


def region_core_ports():
    return port_lines(TOP_PORTS, 2, 'logic')


def port_lines(ports, indent, kind=''):
    out = []
    for k, (d, w, n) in enumerate(ports):
        wid = '[%d:0]' % (w - 1) if w > 1 else ''
        sep = ',' if k < len(ports) - 1 else ''
        dk = (d + ' ' + kind) if kind else d
        out.append('%s%-12s %-7s %s%s' % (' ' * indent, dk, wid, n, sep))
    return out


def arrays_needed():
    need = []
    for d, w, p in MSHR_PORTS:
        tgt, is_arr = mshr_conn(d, w, p)
        if is_arr:
            need.append((w, arr_name(p), d))
    return need


def region_ms_arrays():
    L = ['  // 每个 MSHR 端口一根 16 元素数组（下标 = MSHR 编号），名字 = ms_<去掉 io_ 的端口名>']
    for w, n, d in arrays_needed():
        L.append('  ' + decl(w, n, N) + ('   // 输入：由仲裁器 / 顶层端口驱动' if d == 'input' else ''))
    return L


def region_ms_entries():
    L = ['  for (genvar i = 0; i < MSHRS; i++) begin : mshrs',
         '    MSHR entry (']
    conns = []
    for d, w, p in MSHR_PORTS:
        tgt, _ = mshr_conn(d, w, p)
        conns.append('      .%s(%s)' % (p, tgt))
    L.append(',\n'.join(conns))
    L.append('    );')
    L.append('  end')
    return L


# golden 的逐表项扁平端口 <-> 数组
PER_ENTRY = [
    (r'io_msInfo_(\d+)_(\w+)', 'io_msInfo_{2}'),
    (r'io_msStatus_(\d+)_(\w+)', 'io_status_{2}'),
    (r'io_msAlloc_(\d+)_(\w+)', 'io_statAlloc_{2}'),
    (r'io_pCrd_(\d+)_(\w+)', 'io_pCrd_{2}'),
]


def region_ms_ports():
    arrs = {n: w for w, n, d in arrays_needed()}
    L = []
    for d, w, p in TOP_PORTS:
        for pat, tmpl in PER_ENTRY:
            m = re.fullmatch(pat, p)
            if m:
                k = int(m.group(1))
                a = arr_name(tmpl.format(m.group(0), m.group(1), m.group(2)))
                if a not in arrs or arrs[a] != w:
                    raise SystemExit('%s -> %s：数组不存在或位宽不符' % (p, a))
                if d == 'output':
                    L.append('  assign %s = %s[%d];' % (p, a, k))
                else:
                    L.append('  assign %s[%d] = %s;' % (a, k, p))
                break
    return L


# 子模块例化：(模块, 实例名, 端口 -> 源 的函数)
def arb_conn(prefix_ms, out_prefix):
    """16 路仲裁器：io_in_k_* <- ms_tasks_<ch>_*[k]；io_out_* <- out_prefix 口。"""
    def f(d, w, p):
        if p in ('clock', 'reset'):
            return p
        m = re.fullmatch(r'io_in_(\d+)_(valid|ready|bits_\w+)', p)
        if m:
            a = '%s_%s' % (prefix_ms, m.group(2))
            if a not in ARRS:
                raise SystemExit('仲裁器端口 %s -> %s：数组不存在' % (p, a))
            return '%s[%s]' % (a, m.group(1))
        m = re.fullmatch(r'io_out_(\w+)', p)
        if m:
            t = '%s_%s' % (out_prefix, m.group(1))
            if out_prefix.startswith('io_') and t not in TOP_NAMES:
                raise SystemExit('仲裁器端口 %s -> %s：golden MSHRCtl 端口表里没有' % (p, t))
            return t
        raise SystemExit('仲裁器端口 %s 没有规则' % p)
    return f


def sourceb_conn(d, w, p):
    if p in ('clock', 'reset'):
        return p
    m = re.fullmatch(r'io_sourceB_(\w+)', p)
    if m:
        return 'io_toSourceB_' + m.group(1)
    m = re.fullmatch(r'io_task_(\w+)', p)
    if m:
        return 'sb_task_' + m.group(1)
    if re.fullmatch(r'io_grantStatus_\d+_\w+', p):
        if p not in TOP_NAMES:
            raise SystemExit('SourceB.%s 不在 golden MSHRCtl 端口表' % p)
        return p
    raise SystemExit('SourceB 端口 %s 没有规则' % p)


def selector_conn(d, w, p):
    m = re.fullmatch(r'io_idle_(\d+)', p)
    if m:
        return '~ms_status_valid[%s]' % m.group(1)
    if p == 'io_out_bits':
        return 'selectedOH'
    raise SystemExit('MSHRSelector 端口 %s 没有规则' % p)


CHILDREN = [
    ('FastArbiter_3', 'txreq_arb', 'ms_tasks_txreq', 'io_toTXREQ'),
    ('FastArbiter_4', 'txrsp_arb', 'ms_tasks_txrsp', 'io_toTXRSP'),
    ('FastArbiter_6', 'source_b_arb', 'ms_tasks_source_b', 'sb_task'),
    ('FastArbiter_7', 'mshr_task_arb', 'ms_tasks_mainpipe', 'io_mshrTask'),
]
ARRS = {}


def inst(mod, name, fn, comment):
    ps = golden_ports(mod)
    L = ['  // %s' % comment, '  %s %s (' % (mod, name)]
    L.append(',\n'.join('    .%s(%s)' % (p, fn(d, w, p)) for d, w, p in ps))
    L.append('  );')
    return L


def region_children():
    L = []
    # source_b_arb -> sourceB 之间的连线
    sb = [(w, p[len('io_task_'):]) for d, w, p in golden_ports('SourceB') if p.startswith('io_task_')]
    L.append('  // source_b_arb 的输出 -> SourceB 的 task 输入')
    for w, f in sb:
        L.append('  ' + decl(w, 'sb_task_' + f))
    L.append('')
    notes = {
        'txreq_arb': 'CHI TXREQ：16 个 MSHR 的 Acquire / 重发写回 轮转仲裁',
        'txrsp_arb': 'CHI TXRSP：16 个 MSHR 的 CompAck 轮转仲裁',
        'source_b_arb': '16 个 MSHR 的 Probe 请求 -> SourceB',
        'mshr_task_arb': '16 个 MSHR 发往 RequestArb 的 MainPipe 任务',
    }
    for mod, name, pre, out in CHILDREN:
        L += inst(mod, name, arb_conn(pre, out), '%s（%s）' % (notes[name], mod))
        L.append('')
    L += inst('SourceB', 'sourceB', sourceb_conn,
              'SourceB：Probe 缓冲，等同地址 Grant 收到 GrantAck 后才向上层发 Probe')
    L.append('')
    L += inst('MSHRSelector', 'mshrSelector', selector_conn,
              '选一个空闲 MSHR（最低编号优先；第 15 个的 idle 被 golden 折掉，见核注释）')
    return L


def region_wrapper():
    L = ['// ---------------------------------------------------------------------------',
         '// golden 同名 wrapper：端口与 G1 golden MSHRCtl.sv 逐位同名同宽同序，按名直连可读核。',
         '// ---------------------------------------------------------------------------',
         'module %s(' % TOP]
    L += port_lines(TOP_PORTS, 2)
    L.append(');')
    L.append('  xs_MSHRCtl_core u_core (')
    L.append(',\n'.join('    .%s(%s)' % (n, n) for _, _, n in TOP_PORTS))
    L.append('  );')
    L.append('endmodule')
    return L


NAV_RE = re.compile(r'^(  // §\d.*|  // BEGIN GENERATED\((ms_entries|children)\).*|// BEGIN GENERATED\(wrapper\).*)$')


def region_nav(text):
    out = ['// 本文件导航：']
    for i, ln in enumerate(text.split('\n')):
        if NAV_RE.match(ln):
            label = re.sub(r'\s*——.*$', '', ln.strip().lstrip('/').strip())
            out.append('//   L%d %s' % (i + 1, label[:70]))
    return out


def replace_region(text, tag, lines):
    pat = re.compile(r'(^[ \t]*// BEGIN GENERATED\(%s\)[^\n]*\n)(.*?)(^[ \t]*// END GENERATED\(%s\)[^\n]*$)'
                     % (re.escape(tag), re.escape(tag)), re.S | re.M)
    m = pat.search(text)
    if not m:
        raise SystemExit('%s 里找不到 GENERATED(%s) 区' % (TARGET, tag))
    return text[:m.start(2)] + '\n'.join(lines) + '\n' + text[m.end(2):]


def render():
    ARRS.clear()
    ARRS.update({n: w for w, n, d in arrays_needed()})
    text = TARGET.read_text()
    text = replace_region(text, 'core_ports', region_core_ports())
    text = replace_region(text, 'ms_arrays', region_ms_arrays())
    text = replace_region(text, 'ms_entries', region_ms_entries())
    text = replace_region(text, 'ms_ports', region_ms_ports())
    text = replace_region(text, 'children', region_children())
    text = replace_region(text, 'wrapper', region_wrapper())
    for _ in range(2):
        text = replace_region(text, 'nav', region_nav(text))
    return text


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--check', action='store_true', help='只比对不写，有漂移 rc=1')
    args = ap.parse_args()
    new = render()
    cur = TARGET.read_text()
    if args.check:
        if new != cur:
            print('gen_mshrctl: DRIFT %s' % TARGET.relative_to(REPO))
            return 1
        print('gen_mshrctl: OK')
        return 0
    if new != cur:
        TARGET.write_text(new)
        print('gen_mshrctl: 更新 %s' % TARGET.relative_to(REPO))
    else:
        print('gen_mshrctl: 已是最新')
    return 0


if __name__ == '__main__':
    sys.exit(main())
