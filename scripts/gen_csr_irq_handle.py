#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_csr_irq_handle.py —— csr-irq-handle lane 的 wrapper GENERATED 区生成器。

对象（NewCSR 的直接 child，全部 0 子模块叶）：
  按中断号逐位的视图/寄存器族（8 个）：
    SieModule / SipModule / VSieModule / VSipModule /
    MvipModule / HvipModule / MvienModule / HvienModule
  PMP/PMA 跨条目规则（2 个，共享核 xs_PmEntryHandle_core）：
    PMPEntryHandleModule / PMAEntryHandleModule

手写部分：各 rtl/backend/<Module>.sv 的文件头与 xs_*_core（含共享核
xs_CsrVien_core.sv / xs_PmEntryHandle_core.sv 与 csr_irq_pkg.sv）。本脚本只重写
    // BEGIN GENERATED(csr-irq-handle)
    ...
    // END GENERATED
之间的 golden 同名 wrapper：端口表逐行照抄 golden；golden 的"每个中断号一个标量
端口"（regOut_LC14IE / mvien_LC14IE / fromVSie_LC14IE_valid ...）按**中断号**收拢成
64 位向量接到核上。golden 里没有端口的位是 firtool 折叠掉的常数，由本表的 tie 值
显式给出（例如 mideleg 的 VS/SGEI 位恒 1）——tie 值写错 UT/FM 会直接红。

fail-closed：golden 的每个端口都必须被某条规则认领，否则报错退出；中断名到中断号
的映射表之外的名字同样报错，绝不猜。

用法: python3 scripts/gen_csr_irq_handle.py [--check]
      --check 只比对、不写盘，有漂移即非零退出（幂等闸）。
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN',
                                     '/home/eda/xs-env/G1-canonical/golden-rtl'))
OUT_DIR = REPO / 'rtl' / 'backend'
BEGIN = '// BEGIN GENERATED(csr-irq-handle)'
END = '// END GENERATED'

PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')

# 中断名（去掉 I / IE / IP 后缀）-> 中断号。Scala: InterruptNO。
IRQ_NO = {'SS': 1, 'VSS': 2, 'MS': 3, 'ST': 5, 'VST': 6, 'MT': 7,
          'SE': 9, 'VSE': 10, 'ME': 11, 'SGE': 12, 'LCOF': 13,
          'LPRASE': 35, 'HPRASE': 43}
IRQ_NAME_RE = re.compile(r'^(LC(\d+)|[A-Z]+?)I[EP]?$')

# mideleg 在 golden 里只有 SSI/STI/SEI/LCOFI 四个端口：VS 三位与 SGEI 恒 1
# （MidelegBundle：getVS / SGEI setRO().withReset(1)），其余恒 0。
MIDELEG_TIE = 0x1444


def irq_no(name, top):
    m = IRQ_NAME_RE.match(name)
    if not m:
        raise SystemExit(f'{top}: 认不出的中断名 {name!r}')
    if m.group(2):
        n = int(m.group(2))
        if not 14 <= n <= 63:
            raise SystemExit(f'{top}: 本地中断号越界 {name!r}')
        return n
    base = m.group(1)
    if base not in IRQ_NO:
        raise SystemExit(f'{top}: 认不出的中断名 {name!r}')
    return IRQ_NO[base]


def golden_ports(top):
    txt = (GOLDEN / f'{top}.sv').read_text()
    key = f'\nmodule {top}('
    if key not in txt:
        raise SystemExit(f'golden {top}.sv 里找不到 module {top}(')
    body = txt[txt.index(key) + 1:]
    head = body[:body.index('\n);')]
    out = []
    for ln in head.splitlines()[1:]:
        m = PORT_RE.match(ln)
        if not m:
            raise SystemExit(f'{top}: 端口行解析失败: {ln!r}')
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        out.append((m.group(1), w, m.group(4), ln.rstrip().rstrip(',')))
    return out


# ---------------------------------------------------------------------------
# 中断向量族
# ---------------------------------------------------------------------------
# 每个模块：
#   core      核模块名
#   params    例化参数（文本）
#   scalars   golden 标量端口 -> 核端口（直连）
#   value     regOut_* / rdata 共用的核输出向量名
#   in_vec    golden 输入前缀 -> (核端口, tie 值)        前缀_<中断名>
#   in_vld    golden 输入前缀 -> (valid 核端口, bits 核端口)   前缀_<中断名>_valid/_bits
#   out_vld   golden 输出前缀 -> (valid 核端口, bits 核端口)
#   order     核端口例化顺序
CLK = {'clock': 'clk', 'reset': 'rst'}
CSR_W = {'w_wen': 'wen', 'w_wdata': 'wdata'}

IRQ_MODS = {
    'SieModule': dict(
        core='xs_SieModule_core', params='',
        scalars={**CLK, **CSR_W},
        value='value',
        in_vec={'mideleg': ('mideleg', MIDELEG_TIE), 'mie': ('mie', 0), 'mvien': ('mvien', 0)},
        in_vld={'fromVSie': ('vsie_wr_valid', 'vsie_wr_bits')},
        out_vld={'toMie': ('to_mie_valid', 'to_mie_bits')},
        order=['clk', 'rst', 'wen', 'wdata', 'mideleg', 'mie', 'mvien',
               'vsie_wr_valid', 'vsie_wr_bits', 'value', 'to_mie_valid', 'to_mie_bits'],
    ),
    'SipModule': dict(
        core='xs_SipModule_core', params='',
        scalars={**CSR_W},
        value='value',
        in_vec={'mideleg': ('mideleg', MIDELEG_TIE), 'mip': ('mip', 0),
                'mvip': ('mvip', 0), 'mvien': ('mvien', 0)},
        in_vld={},
        out_vld={'toMip': ('to_mip_valid', 'to_mip_bits'),
                 'toMvip': ('to_mvip_valid', 'to_mvip_bits')},
        order=['wen', 'wdata', 'mideleg', 'mip', 'mvip', 'mvien', 'value',
               'to_mip_valid', 'to_mip_bits', 'to_mvip_valid', 'to_mvip_bits'],
    ),
    'VSieModule': dict(
        core='xs_VSieModule_core', params='',
        scalars={**CLK, **CSR_W},
        value='value',
        in_vec={'mideleg': ('mideleg', MIDELEG_TIE), 'hideleg': ('hideleg', 0),
                'mie': ('mie', 0), 'sie': ('sie', 0),
                'mvien': ('mvien', 0), 'hvien': ('hvien', 0)},
        in_vld={},
        out_vld={'toMie': ('to_mie_valid', 'to_mie_bits'),
                 'toSie': ('to_sie_valid', 'to_sie_bits')},
        order=['clk', 'rst', 'wen', 'wdata', 'mideleg', 'hideleg', 'mie', 'sie',
               'mvien', 'hvien', 'value',
               'to_mie_valid', 'to_mie_bits', 'to_sie_valid', 'to_sie_bits'],
    ),
    'VSipModule': dict(
        core='xs_VSipModule_core', params='',
        scalars={**CSR_W},
        value='value',
        in_vec={'mideleg': ('mideleg', MIDELEG_TIE), 'hideleg': ('hideleg', 0),
                'mip': ('mip', 0), 'mvip': ('mvip', 0), 'hvip': ('hvip', 0),
                'mvien': ('mvien', 0), 'hvien': ('hvien', 0)},
        in_vld={},
        out_vld={'toMip': ('to_mip_valid', 'to_mip_bits'),
                 'toHvip': ('to_hvip_valid', 'to_hvip_bits')},
        order=['wen', 'wdata', 'mideleg', 'hideleg', 'mip', 'mvip', 'hvip',
               'mvien', 'hvien', 'value',
               'to_mip_valid', 'to_mip_bits', 'to_hvip_valid', 'to_hvip_bits'],
    ),
    'MvipModule': dict(
        core='xs_MvipModule_core', params='',
        scalars={**CLK, **CSR_W, 'menvcfg_STCE': 'menvcfg_stce'},
        value='value',
        in_vec={'mip': ('mip', 0), 'mvien': ('mvien', 0)},
        in_vld={'fromMip': ('mip_wr_valid', 'mip_wr_bits'),
                'fromSip': ('sip_wr_valid', 'sip_wr_bits')},
        out_vld={'toMip': ('to_mip_valid', 'to_mip_bits')},
        order=['clk', 'rst', 'wen', 'wdata', 'mip', 'mvien', 'menvcfg_stce',
               'mip_wr_valid', 'mip_wr_bits', 'sip_wr_valid', 'sip_wr_bits',
               'value', 'to_mip_valid', 'to_mip_bits'],
    ),
    'HvipModule': dict(
        core='xs_HvipModule_core', params='',
        scalars={**CLK, **CSR_W},
        value='value',
        in_vec={},
        in_vld={'fromMip': ('mip_wr_valid', 'mip_wr_bits'),
                'fromHip': ('hip_wr_valid', 'hip_wr_bits'),
                'fromVSip': ('vsip_wr_valid', 'vsip_wr_bits')},
        out_vld={},
        order=['clk', 'rst', 'wen', 'wdata', 'mip_wr_valid', 'mip_wr_bits',
               'hip_wr_valid', 'hip_wr_bits', 'vsip_wr_valid', 'vsip_wr_bits', 'value'],
    ),
    # mvien：SSIE(1)/SEIE(9)/本地 14..63 可写；hvien：仅本地 14..63。
    'MvienModule': dict(
        core='xs_CsrVien_core', params="#(.WRITABLE(64'hFFFF_FFFF_FFFF_C202)) ",
        scalars={**CLK, **CSR_W},
        value='value', in_vec={}, in_vld={}, out_vld={},
        order=['clk', 'rst', 'wen', 'wdata', 'value'],
    ),
    'HvienModule': dict(
        core='xs_CsrVien_core', params="#(.WRITABLE(64'hFFFF_FFFF_FFFF_C000)) ",
        scalars={**CLK, **CSR_W},
        value='value', in_vec={}, in_vld={}, out_vld={},
        order=['clk', 'rst', 'wen', 'wdata', 'value'],
    ),
}


def hex64(v):
    s = f'{v:016X}'
    return "64'h" + '_'.join(s[i:i + 4] for i in range(0, 16, 4))


def gen_irq(top, cfg):
    ports = golden_ports(top)
    in_bits = {}    # 核输入向量 -> {中断号: golden 端口}
    out_bits = {}   # 核输出向量 -> [(golden 端口, 中断号)]
    conn = {}       # 核端口 -> 连接表达式
    tie = {}
    for pfx, (cp, tv) in cfg['in_vec'].items():
        in_bits[cp] = {}
        tie[cp] = tv
    for pfx, (cv, cb) in cfg['in_vld'].items():
        in_bits[cv] = {}
        in_bits[cb] = {}
        tie[cv] = 0
        tie[cb] = 0
    for pfx, (cv, cb) in cfg['out_vld'].items():
        out_bits[cv] = []
        out_bits[cb] = []
    value = cfg['value']
    out_bits[value] = []
    saw_rdata = False

    for d, w, name, _ in ports:
        if name in cfg['scalars']:
            conn[cfg['scalars'][name]] = name
            continue
        if name == 'rdata':
            if d != 'output' or w != 64:
                raise SystemExit(f'{top}: rdata 形状不符')
            saw_rdata = True
            continue
        if w != 1:
            raise SystemExit(f'{top}: 未认领的多位端口 {name}')
        if name.startswith('regOut_'):
            out_bits[value].append((name, irq_no(name[len('regOut_'):], top)))
            continue
        pfx, _, rest = name.partition('_')
        if d == 'input' and pfx in cfg['in_vec']:
            cp = cfg['in_vec'][pfx][0]
            n = irq_no(rest, top)
            if n in in_bits[cp]:
                raise SystemExit(f'{top}: {cp}[{n}] 重复')
            in_bits[cp][n] = name
            continue
        m = re.match(r'^(\w+?)_(valid|bits)$', rest)
        if m and d == 'input' and pfx in cfg['in_vld']:
            cp = cfg['in_vld'][pfx][0 if m.group(2) == 'valid' else 1]
            n = irq_no(m.group(1), top)
            if n in in_bits[cp]:
                raise SystemExit(f'{top}: {cp}[{n}] 重复')
            in_bits[cp][n] = name
            continue
        if m and d == 'output' and pfx in cfg['out_vld']:
            cp = cfg['out_vld'][pfx][0 if m.group(2) == 'valid' else 1]
            out_bits[cp].append((name, irq_no(m.group(1), top)))
            continue
        raise SystemExit(f'{top}: 端口 {name} 没有规则认领')
    if not saw_rdata:
        raise SystemExit(f'{top}: golden 没有 rdata')

    L = [f'module {top} (']
    L.append(',\n'.join(ln for _, _, _, ln in ports))
    L.append(');')
    if in_bits:
        L.append('  // Inputs gathered by interrupt number.  A bit without a golden port is a')
        L.append('  // constant that firtool folded away; the default below restates it.')
    for cp in cfg['order']:
        if cp not in in_bits:
            continue
        L.append(f'  logic [63:0] {cp};')
        L.append('  always_comb begin')
        L.append(f'    {cp} = {hex64(tie[cp])};')
        for n in sorted(in_bits[cp]):
            L.append(f'    {cp}[{n}] = {in_bits[cp][n]};')
        L.append('  end')
        conn[cp] = cp
    for cp in cfg['order']:
        if cp in out_bits:
            L.append(f'  logic [63:0] {cp};')
            conn[cp] = cp
    L.append('')
    L.append(f"  {cfg['core']} {cfg['params']}u_core (")
    missing = [cp for cp in cfg['order'] if cp not in conn]
    if missing:
        raise SystemExit(f'{top}: 核端口未接: {missing}')
    extra = set(conn) - set(cfg['order'])
    if extra:
        raise SystemExit(f'{top}: 多出的连接: {sorted(extra)}')
    wid = max(len(c) for c in cfg['order'])
    L.append(',\n'.join(f'    .{cp.ljust(wid)} ({conn[cp]})' for cp in cfg['order']))
    L.append('  );')
    L.append('')
    L.append('  // Outputs spread back to one port per interrupt number.')
    L.append(f'  assign rdata = {value};')
    for cp in cfg['order']:
        if cp not in out_bits:
            continue
        for name, n in out_bits[cp]:
            L.append(f'  assign {name} = {cp}[{n}];')
    L.append('endmodule')
    return '\n'.join(L) + '\n'


# ---------------------------------------------------------------------------
# PMP / PMA EntryHandle
# ---------------------------------------------------------------------------
PM_MODS = {
    # top: (cfg 端口前缀, cfg 写值输出名, addr 读值输出前缀, golden 寄存器名模板,
    #       cfg CSR 基址, addr CSR 基址, cfg bit6 / bit5 的字段名或 None)
    'PMPEntryHandleModule': ('io_in_pmpCfg', 'io_out_pmpCfgWData', 'io_out_pmpAddrRData',
                             'pmpAddr_{}_ADDRESS', 0x3A0, 0x3B0, None, None),
    'PMAEntryHandleModule': ('io_in_pmaCfg', 'io_out_pmaCfgWdata', 'io_out_pmaAddrRData',
                             'pmaAddr_{}', 0x7C0, 0x7C8, 'C', 'ATOMIC'),
}
PM_N = 32


def gen_pm(top, cfg):
    cpfx, cfg_out, rd_pfx, reg_tmpl, cfg_base, addr_base, f6, f5 = cfg
    ports = golden_ports(top)
    names = {n: (d, w) for d, w, n, _ in ports}
    fixed = [('input', 1, 'clock'), ('input', 1, 'reset'), ('input', 1, 'io_in_wen'),
             ('input', 1, 'io_in_ren'), ('input', 12, 'io_in_addr'),
             ('input', 64, 'io_in_wdata'), ('output', 64, cfg_out)]
    expect = list(fixed)
    fields = [('R', 1), ('W', 1), ('X', 1), ('A', 2), ('L', 1)]
    if f5:
        fields += [(f5, 1)]
    if f6:
        fields += [(f6, 1)]
    for i in range(PM_N):
        for f, w in fields:
            expect.append(('input', w, f'{cpfx}_{i}_{f}'))
    for i in range(PM_N):
        expect.append(('output', 64, f'{rd_pfx}_{i}'))
    got = sorted((d, w, n) for d, w, n, _ in ports)
    if got != sorted(expect):
        diff = set(got) ^ set(expect)
        raise SystemExit(f'{top}: golden 端口表与期望形状不符: {sorted(diff)[:8]}')

    # 地址寄存器复位值：读 golden 的异步复位支路，逐条必须恰好出现一次。
    txt = (GOLDEN / f'{top}.sv').read_text()
    always = txt[txt.index('always @(posedge clock or posedge reset)'):]
    always = always[:always.index('else begin')]
    resets = []
    for i in range(PM_N):
        m = re.findall(r'^\s*' + re.escape(reg_tmpl.format(i)) + r" <= 46'h([0-9A-Fa-f]+);$",
                       always, re.M)
        if len(m) != 1:
            raise SystemExit(f'{top}: 条目 {i} 的复位值解析失败')
        resets.append(int(m[0], 16))

    L = [f'module {top} (']
    L.append(',\n'.join(ln for _, _, _, ln in ports))
    L.append(');')
    L.append('  // Current cfg byte of every entry: {L, bit6, bit5, A[1:0], X, W, R}.')
    L.append('  logic [31:0][7:0] old_cfg;')
    for i in range(PM_N):
        p = f'{cpfx}_{i}_'
        b6 = p + f6 if f6 else "1'b0"
        b5 = p + f5 if f5 else "1'b0"
        L.append(f'  assign old_cfg[{i}] = {{{p}L, {b6}, {b5}, {p}A, {p}X, {p}W, {p}R}};')
    L.append('  logic [31:0][63:0] addr_rdata;')
    L.append('')
    L.append('  // Address reset values, one per entry (entry 31 first).')
    L.append('  localparam logic [31:0][45:0] ADDR_RESET = {')
    for i in reversed(range(PM_N)):
        s = f'{resets[i]:012X}'
        sep = ',' if i else ' '
        L.append(f"    46'h{s[0:4]}_{s[4:8]}_{s[8:12]}{sep}  // {i}")
    L.append('  };')
    L.append('')
    L.append('  xs_PmEntryHandle_core #(')
    L.append(f"    .CFG_CSR_BASE (12'h{cfg_base:03X}),")
    L.append(f"    .ADDR_CSR_BASE(12'h{addr_base:03X}),")
    L.append('    .ADDR_RESET   (ADDR_RESET)')
    L.append('  ) u_core (')
    L.append('    .clk       (clock),')
    L.append('    .rst       (reset),')
    L.append('    .wen       (io_in_wen),')
    L.append('    .ren       (io_in_ren),')
    L.append('    .csr_addr  (io_in_addr),')
    L.append('    .wdata     (io_in_wdata),')
    L.append('    .old_cfg   (old_cfg),')
    L.append(f'    .cfg_wdata ({cfg_out}),')
    L.append('    .addr_rdata(addr_rdata)')
    L.append('  );')
    L.append('')
    for i in range(PM_N):
        L.append(f'  assign {rd_pfx}_{i} = addr_rdata[{i}];')
    L.append('endmodule')
    return '\n'.join(L) + '\n'


def splice(path, gen_txt):
    txt = path.read_text()
    if txt.count(BEGIN) != 1 or txt.count(END) != 1:
        raise SystemExit(f'{path}: 需要恰好一对 GENERATED 标记')
    a = txt.index(BEGIN) + len(BEGIN) + 1
    b = txt.index(END)
    return txt[:a] + gen_txt + txt[b:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    rc = 0
    jobs = [(t, gen_irq(t, c)) for t, c in IRQ_MODS.items()]
    jobs += [(t, gen_pm(t, c)) for t, c in PM_MODS.items()]
    for top, gen_txt in jobs:
        path = OUT_DIR / f'{top}.sv'
        new = splice(path, gen_txt)
        old = path.read_text()
        if new == old:
            print(f'[gen_csr_irq_handle] {path.name} OK')
        elif args.check:
            print(f'[gen_csr_irq_handle] DRIFT {path.name}（请重跑生成器）')
            rc = 1
        else:
            path.write_text(new)
            print(f'[gen_csr_irq_handle] wrote {path.name}')
    return rc


if __name__ == '__main__':
    sys.exit(main())
