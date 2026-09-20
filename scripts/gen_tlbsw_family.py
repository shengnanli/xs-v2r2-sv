#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_tlbsw_family.py —— 生成 TlbStorageWrapper 家族 _2 / _3 两个变体的薄 wrapper。

家族形态（CONVENTIONS.md「变体家族」）：一个参数化可读核
rtl/memblock/xs_TlbStorageWrapper_core.sv（Tree-PLRU 替换器，PORTS 可配）
+ 每变体一个薄文件。薄文件里**没有替换逻辑**，只做三件事：

  1) 声明与 G1 golden 逐位同名同宽同序的端口（端口表直接从 golden 抄下来）；
  2) 例化同变体号的存储阵列 TLBFA_<n>（重写件，已独立签核），端口全透传；
  3) 例化核 xs_TlbStorageWrapper_core #(.PORTS(n))，把 TLBFA 反馈的 touch_ways
     喂进去，核算出的 victim way 接回 TLBFA 的 io_w_bits_wayIdx。

为什么只生成 _2/_3：变体 0 与 _1 是上一轮手写并已签核的产物
（evidence/f40deba9439d/），本脚本不碰它们的字节 —— 生成器的职责是
"新变体不靠手抄端口表"，不是"把已签核的文件重排一遍"。

★端口不对称是 firtool 消端口的结果，照抄不补齐★
  _2 与 _3 的差别**只有两个端口**：_2 有 io_r_resp_{0,1}_bits_s2xlate_0，_3 没有。
  两者 PORTS/WAYS 完全相同。这不是笔误，是父级（dtlb-store vs dtlb-prefetch）
  读不读这个字段决定的，firtool 把没人读的端口连同驱动一起消掉了。
  本脚本直接从 golden 端口表读，所以不可能"顺手补齐成对称"。

用法:
  python3 scripts/gen_tlbsw_family.py           # 写文件
  python3 scripts/gen_tlbsw_family.py --check   # 只校验产物与本脚本一致（幂等闸）
"""
import argparse
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
OUT_DIR = REPO / 'rtl' / 'memblock'

# 变体参数：全部实测自 golden（端口数 / 查询端口数 / 内层实例名），不是从 Chisel 默认值推的。
VARIANTS = {
    'TlbStorageWrapper_2': dict(
        ports=2, inst='page_sttlb_storage_fa', child='TLBFA_2',
        parent='dtlb-store（store 流水的 L1 TLB）',
        notes=[
            '本变体 = sttlb 的“存储 + 替换”包装层：2 个查询端口。',
            '与 TlbStorageWrapper_3 参数完全相同（PORTS=2 / nWays=48），唯一差别是',
            'firtool 消端口的结果：本变体保留了 io_r_resp_{0,1}_bits_s2xlate_0，',
            '_3 没有 —— 因为 dtlb-prefetch 的父级不读这个字段。',
        ]),
    'TlbStorageWrapper_3': dict(
        ports=2, inst='page_pftlb_storage_fa', child='TLBFA_3',
        parent='dtlb-prefetch（预取流水的 L1 TLB）',
        notes=[
            '本变体 = pftlb 的“存储 + 替换”包装层：2 个查询端口。',
            '与 TlbStorageWrapper_2 参数完全相同；本变体**没有**',
            'io_r_resp_{0,1}_bits_s2xlate_0 两个端口（父级不读 → firtool 消掉）。',
        ]),
}

HEAD_RE = re.compile(r'^module\s+(\w+)\(\s*$', re.MULTILINE)


def read_golden(name):
    return (GOLDEN / f'{name}.sv').read_text()


def port_table(text, name):
    """取 golden 模块头的端口声明行（原样，去掉行尾逗号由调用者重组）。"""
    m = HEAD_RE.search(text)
    if not m or m.group(1) != name:
        raise SystemExit(f'{name}: 找不到模块头')
    lines = text[m.end():].split('\n')
    out = []
    for ln in lines:
        if ln.startswith(');'):
            return out
        s = ln.strip()
        if not s:
            continue
        if not re.match(r'^(input|output)\b', s):
            raise SystemExit(f'{name}: 端口表里出现非端口行: {s!r}')
        out.append(s.rstrip(','))
    raise SystemExit(f'{name}: 端口表没有结束')


def inst_ports(text, inst, child):
    """取 golden 里 TLBFA_<n> 实例的 (形参, 实参) 序列。

    实参只有三种形态，其余一律报错（防止 golden 变了而脚本静默照抄旧假设）：
      - 与形参同名的顶层端口 → 透传
      - _<inst>_io_access_<i>_touch_ways_{valid,bits} → 接核的反馈向量
      - io_w_bits_wayIdx 的那一大坨 PLRU 表达式 → 接核算出的 refill_wayIdx
    """
    m = re.search(r'^  ' + re.escape(child) + r'\s+' + re.escape(inst) + r'\s*\(\s*$',
                  text, re.MULTILINE)
    if not m:
        raise SystemExit(f'{inst}: 找不到 {child} 实例')
    body = text[m.end():]
    end = body.index('\n  );')
    body = body[:end]
    out = []
    # 形参出现在 ".<name>" 处；实参是它后面到下一个 ".<name>" 之前的内容
    hits = list(re.finditer(r'^\s*\.(\w+)', body, re.MULTILINE))
    for i, h in enumerate(hits):
        pname = h.group(1)
        seg = body[h.end(): hits[i + 1].start() if i + 1 < len(hits) else len(body)]
        seg = seg.strip().rstrip(',').strip()
        assert seg.startswith('(') and seg.endswith(')'), (pname, seg[:40])
        arg = seg[1:-1].strip()
        acc = re.fullmatch(r'_' + re.escape(inst) + r'_io_access_(\d+)_touch_ways_(valid|bits)', arg)
        if pname == 'io_w_bits_wayIdx':
            out.append((pname, 'refill_wayIdx'))
        elif acc:
            out.append((pname, f'acc_{acc.group(2)}[{acc.group(1)}]'))
        elif arg == pname:
            out.append((pname, pname))
        else:
            raise SystemExit(f'{inst}.{pname}: 未预期的实参 {arg[:60]!r}')
    return out


def emit(name, cfg):
    g = read_golden(name)
    ports = port_table(g, name)
    conns = inst_ports(g, cfg['inst'], cfg['child'])
    n = cfg['ports']
    glines = len(g.splitlines())
    npi = sum(1 for p in ports if p.startswith('input'))
    npo = len(ports) - npi

    L = []
    A = L.append
    A('// ' + '=' * 76)
    A(f'// {name} —— {cfg["parent"]} 的 TLB 存储 + 替换包装层'
      f'（TlbStorageWrapper 家族薄 wrapper）')
    A('//')
    A(f'// 本变体参数与规模：PORTS={n}（查询端口数）  nWays=48（全相联条数，四变体一致）')
    A(f'//   golden {name}.sv = {glines} 行 / {len(ports)} 端口（{npi} 输入 / {npo} 输出）')
    A('//')
    for t in cfg['notes']:
        A(f'// {t}')
    A('//')
    A('// 本层唯一的有状态逻辑是 Tree-PLRU 替换器，住在参数化核')
    A('//   xs_TlbStorageWrapper_core（同目录 xs_TlbStorageWrapper_core.sv）里；')
    A(f'//   存储与匹配全部在 {cfg["child"]}（同目录，已独立签核）。本文件只做端口展平与')
    A('//   连线：把 golden 的扁平 io_* 端口透传给内层阵列，把阵列反馈的 touch_ways')
    A('//   收成向量喂给核，再把核算出的 victim way 接回阵列的 io_w_bits_wayIdx。')
    A('//')
    A('// 替换策略包 xs_tlbsw_pkg 住在 rtl/memblock/memblock_common_pkg.sv')
    A('//   （编译/FM 时须排在本文件之前）。')
    A('// 端口表逐位抄自 G1 golden 同名模块（scripts/gen_tlbsw_family.py 生成，勿手改）。')
    A('// ' + '=' * 76)
    A('')
    A('// BEGIN GENERATED(tlbsw-wrapper)')
    A(f'module {name} import xs_tlbsw_pkg::*; (')
    for i, p in enumerate(ports):
        A(f'  {p}' + (',' if i + 1 < len(ports) else ''))
    A(');')
    A('')
    A('  // 内层阵列每拍反馈的“本拍命中/刚 refill 的 way”，逐端口收成核要的向量。')
    A(f'  logic              acc_valid [{n}];')
    A(f'  logic [WAY_W-1:0]  acc_bits  [{n}];')
    A(f'  tlb_access_t       access    [{n}];')
    A('  logic [WAY_W-1:0]  refill_wayIdx;   // 核算出的 victim way → 阵列 refill 写哪一路')
    A('')
    A('  always_comb begin')
    A(f'    for (int i = 0; i < {n}; i++) begin')
    A('      access[i].valid = acc_valid[i];')
    A('      access[i].way   = acc_bits[i];')
    A('    end')
    A('  end')
    A('')
    A(f'  {cfg["child"]} {cfg["inst"]} (')
    for i, (p, a) in enumerate(conns):
        A(f'    .{p}({a})' + (',' if i + 1 < len(conns) else ''))
    A('  );')
    A('')
    A(f'  xs_TlbStorageWrapper_core #(.PORTS({n}), .WAYS(NWAYS), .WW(WAY_W)) u_core (')
    A('    .clock(clock), .reset(reset),')
    A('    .io_access(access),')
    A('    .io_w_bits_wayIdx(refill_wayIdx)')
    A('  );')
    A('endmodule')
    A('// END GENERATED')
    A('')
    return '\n'.join(L)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    rc = 0
    for name, cfg in VARIANTS.items():
        text = emit(name, cfg)
        dst = OUT_DIR / f'{name}.sv'
        if args.check:
            cur = dst.read_text() if dst.exists() else None
            if cur != text:
                print(f'DRIFT: {dst} 与生成器不一致')
                rc = 1
            else:
                print(f'OK: {dst}')
        else:
            dst.write_text(text)
            print(f'wrote {dst} ({len(text.splitlines())} lines)')
    return rc


if __name__ == '__main__':
    sys.exit(main())
