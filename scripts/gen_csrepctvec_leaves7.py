#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_csrepctvec_leaves7.py —— 族 F（7 个 CSR trap epc/tvec 叶）wrapper 的 GENERATED 区生成器。

对象（全部是 NewCSR 的直接 child、0 子模块叶）：
  epc 亚族（trap 返回地址，63 位寄存器，trap 装载 + 软件写按位或合并）：
    MepcModule / SepcModule / VSepcModule / MnepcModule（仅 trap 口前缀不同）
  tvec 亚族（trap 向量，base[63:2] + WARL mode[1:0]，无 trap 口，逐字节同构）：
    MtvecModule / StvecModule / VStvecModule

手写部分：rtl/backend/xs_CsrEpcTvec_core.sv（参数化共享核，IS_TVEC 区分亚族）
与每个 rtl/backend/<Module>.sv 的文件头注释。本脚本只重写每个 <Module>.sv 里
    // BEGIN GENERATED(csrepctvec-leaves7)
    ...
    // END GENERATED
之间的 golden 同名 wrapper（端口表 + 共享核例化连线/绑线）。

★所有维度都从 golden 实测、fail-closed★：端口表逐行解析 G1 golden 并断言与本族
两亚族的期望形状逐字一致（名字/方向/位宽/顺序、trap 口前缀）；golden 的更新/
复位结构也做去空白模板核对；共享核的端口表同样解析出来与期望逐字比对。任何
一项不符即报错退出，绝不猜。

用法: python3 scripts/gen_csrepctvec_leaves7.py [--check]
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
CORE_FILE = OUT_DIR / 'xs_CsrEpcTvec_core.sv'
BEGIN = '// BEGIN GENERATED(csrepctvec-leaves7)'
END = '// END GENERATED'

# 变体表：名字 -> (亚族, trap 口前缀)。trap 口前缀取自 golden 端口名实测，
# 本表是断言基准，不是生成依据（生成依据是 golden 解析结果，两者不符即报错）。
VARIANTS = {
    'MepcModule':   ('epc',  'trapToM_mepc'),
    'SepcModule':   ('epc',  'trapToHS_sepc'),
    'VSepcModule':  ('epc',  'trapToVS_vsepc'),
    'MnepcModule':  ('epc',  'trapToMN_mnepc'),
    'MtvecModule':  ('tvec', None),
    'StvecModule':  ('tvec', None),
    'VStvecModule': ('tvec', None),
}

# 期望 golden 端口表（golden 顺序）：(方向, 位宽区间, 名字)；{p} = trap 口前缀占位。
EXPECTED_PORTS = {
    'epc': [
        ('input',  '',       'clock'),
        ('input',  '',       'reset'),
        ('input',  '',       'w_wen'),
        ('input',  '[63:0]', 'w_wdata'),
        ('output', '[63:0]', 'rdata'),
        ('output', '[62:0]', 'regOut_epc'),
        ('input',  '',       '{p}_valid'),
        ('input',  '[62:0]', '{p}_bits_epc'),
    ],
    'tvec': [
        ('input',  '',       'clock'),
        ('input',  '',       'reset'),
        ('input',  '',       'w_wen'),
        ('input',  '[63:0]', 'w_wdata'),
        ('output', '[63:0]', 'rdata'),
        ('output', '[1:0]',  'regOut_mode'),
        ('output', '[61:0]', 'regOut_addr'),
    ],
}

# 期望 golden 更新/复位结构（去空白后做子串核对，{p} = trap 口前缀占位）。
# 防 golden 静默漂移：复位极性/复位值、写使能形状、OR 合并、WARL 条件变了即报错。
EXPECTED_BODY = {
    'epc': [
        'reg [62:0] reg_epc;',
        'always @(posedge clock or posedge reset)',
        "if (reset) reg_epc <= 63'h0;",
        "else if (w_wen | {p}_valid)",
        "reg_epc <= ({p}_valid ? {p}_bits_epc : 63'h0) | (w_wen ? w_wdata[63:1] : 63'h0);",
        "assign rdata = {reg_epc, 1'h0};",
        'assign regOut_epc = reg_epc;',
    ],
    'tvec': [
        'reg [1:0] reg_mode;',
        'reg [61:0] reg_addr;',
        'always @(posedge clock or posedge reset)',
        "if (reset) begin reg_mode <= 2'h0; reg_addr <= 62'h0; end",
        "if (w_wen & (w_wdata[1:0] == 2'h0 | w_wdata[1:0] == 2'h1)) reg_mode <= w_wdata[1:0];",
        'if (w_wen) reg_addr <= w_wdata[63:2];',
        'assign rdata = {reg_addr, reg_mode};',
        'assign regOut_mode = reg_mode;',
        'assign regOut_addr = reg_addr;',
    ],
}

# 期望共享核端口表（顺序）：(方向, 位宽区间, 名字)。核是手写的，这条把
# 「核改了忘改生成器映射」变成显式失败。
EXPECTED_CORE_PORTS = [
    ('input',  '',       'clock'),
    ('input',  '',       'reset'),
    ('input',  '',       'wen'),
    ('input',  '[63:0]', 'wdata'),
    ('input',  '',       'trap_valid'),
    ('input',  '[62:0]', 'trap_epc'),
    ('output', '[63:0]', 'rdata'),
    ('output', '[62:0]', 'epc'),
    ('output', '[1:0]',  'mode'),
    ('output', '[61:0]', 'addr'),
]

# 连线表（核端口 -> golden 端口 / 常量绑线 / ''=输出不连）；{p} = trap 口前缀占位。
CONN = {
    'epc': [
        ('clock',      'clock'),
        ('reset',      'reset'),
        ('wen',        'w_wen'),
        ('wdata',      'w_wdata'),
        ('trap_valid', '{p}_valid'),
        ('trap_epc',   '{p}_bits_epc'),
        ('rdata',      'rdata'),
        ('epc',        'regOut_epc'),
        ('mode',       ''),           # 本亚族无此字段，输出不连
        ('addr',       ''),           # 本亚族无此字段，输出不连
    ],
    'tvec': [
        ('clock',      'clock'),
        ('reset',      'reset'),
        ('wen',        'w_wen'),
        ('wdata',      'w_wdata'),
        ('trap_valid', "1'b0"),       # tvec 无 trap 装载口，绑常量
        ('trap_epc',   "63'h0"),      # tvec 无 trap 装载口，绑常量
        ('rdata',      'rdata'),
        ('epc',        ''),           # 本亚族无此字段，输出不连
        ('mode',       'regOut_mode'),
        ('addr',       'regOut_addr'),
    ],
}


def die(msg):
    sys.exit('gen_csrepctvec_leaves7: ' + msg)


def squash(s):
    """去空白（含换行），用于 golden 结构模板核对。"""
    return re.sub(r'\s+', '', s)


def parse_ports(txt, modname, where):
    """解析 module modname 的端口表：返回 [(dir, range, name)]，顺序与声明一致。"""
    m = re.search(r'^module\s+' + modname + r'\s*(#\s*\(.*?\)\s*)?\(\n(.*?)\n\);',
                  txt, re.S | re.M)
    if not m:
        die('%s: 找不到 module %s 的端口表' % (where, modname))
    ports = []
    for ln in m.group(2).split('\n'):
        ln = re.sub(r'//[^\n]*', '', ln).rstrip()
        if not ln.strip():
            continue
        pm = re.match(r'^\s+(input|output)\s+(?:logic\s+)?(?:\[(\d+):(\d+)\]\s+)?(\w+),?$',
                      ln)
        if not pm:
            die('%s: 端口行形状不认识: %r' % (where, ln))
        rng = '[%s:%s]' % (pm.group(2), pm.group(3)) if pm.group(2) is not None else ''
        ports.append((pm.group(1), rng, pm.group(4)))
    if not ports:
        die('%s: %s 端口表为空' % (where, modname))
    return ports


def check_variant(top):
    """ golden 端口表 + 结构模板核对；返回解析出的端口表。"""
    kind, prefix = VARIANTS[top]
    gfile = GOLDEN / (top + '.sv')
    if not gfile.exists():
        die('%s: golden 文件不存在: %s' % (top, gfile))
    txt = gfile.read_text()

    # golden 自包含断言：本族全部 0 子模块，golden 里不得出现其它例化。
    body = txt[txt.index('module ' + top):]
    extra_mods = re.findall(r'^\s*(\w+)\s+u_\w+\s*\(', body, re.M)
    if extra_mods:
        die('%s: golden 里出现子模块例化 %s，与"0 子模块叶"登记不符' % (top, extra_mods))

    ports = parse_ports(txt, top, top)
    want = [(d, r, n.replace('{p}', prefix or '')) for d, r, n in EXPECTED_PORTS[kind]]
    if ports != want:
        die('%s: golden 端口表与期望 %s 亚族形状不一致:\n  got  %r\n  want %r'
            % (top, kind, ports, want))

    sq = squash(body)
    for pat in EXPECTED_BODY[kind]:
        p = squash(pat.replace('{p}', prefix or ''))
        if p not in sq:
            die('%s: golden 结构模板缺项: %s' % (top, pat))
    return ports


def check_core():
    """共享核端口表解析 + 与期望逐字比对；返回端口表。"""
    if not CORE_FILE.exists():
        die('共享核不存在: %s（手写件，先写好再跑本脚本）' % CORE_FILE)
    txt = CORE_FILE.read_text()
    mods = re.findall(r'^module\s+(\w+)', txt, re.M)
    if mods != ['xs_CsrEpcTvec_core']:
        die('共享核文件应且只应声明 xs_CsrEpcTvec_core 一个模块，实际: %r' % mods)
    ports = parse_ports(txt, 'xs_CsrEpcTvec_core', str(CORE_FILE))
    if ports != EXPECTED_CORE_PORTS:
        die('共享核端口表与期望不一致:\n  got  %r\n  want %r' % (ports, EXPECTED_CORE_PORTS))
    return ports


def gen_block(top, gports):
    kind, prefix = VARIANTS[top]
    conn = [(c, t.replace('{p}', prefix or '')) for c, t in CONN[kind]]

    # 连线表与核端口表双向全覆盖（防"核改了忘改映射"）
    core_names = [n for _, _, n in EXPECTED_CORE_PORTS]
    conn_names = [c for c, _ in conn]
    if sorted(core_names) != sorted(conn_names):
        die('%s: 连线表与核端口集合不一致: conn-only=%s core-only=%s'
            % (top, sorted(set(conn_names) - set(core_names)),
               sorted(set(core_names) - set(conn_names))))
    # 连到 golden 端口的目标必须在 golden 端口表里（防映射打错名安静地连空）
    gset = {n for _, _, n in gports}
    gdir = {n: d for d, _, n in gports}
    cdir = {n: d for d, _, n in EXPECTED_CORE_PORTS}
    for c, t in conn:
        if t == '' or "'" in t:
            continue               # 输出不连 / 输入绑常量
        if t not in gset:
            die('%s: 连线目标 %s 不在 golden 端口表里' % (top, t))
        if cdir[c] != gdir[t]:
            die('%s: 端口方向不一致: core.%s=%s golden.%s=%s' % (top, c, cdir[c], t, gdir[t]))
    # 反向：golden 端口必须全部被连线表消费（防漏连）
    used = {t for _, t in conn if t and "'" not in t}
    if used != gset:
        die('%s: golden 端口未被连线表全覆盖: %s' % (top, sorted(gset - used)))

    out = [BEGIN, 'module %s(' % top]
    w_dir = max(len(d) for d, _, _ in gports)
    w_rng = max(len(r) for _, r, _ in gports)
    for i, (d, r, n) in enumerate(gports):
        sep = ',' if i < len(gports) - 1 else ''
        out.append('  %s %s %s%s' % (d.ljust(w_dir), r.ljust(w_rng), n, sep))
    out.append(');')
    out.append('')
    out.append('  xs_CsrEpcTvec_core #(')
    out.append("    .IS_TVEC (1'b%d)" % (1 if kind == 'tvec' else 0))
    out.append('  ) u_core (')
    wp = max(len(c) for c, _ in conn)
    for i, (c, t) in enumerate(conn):
        sep = ',' if i < len(conn) - 1 else ''
        out.append('    .%s (%s)%s' % (c.ljust(wp), t, sep))
    out.append('  );')
    out.append('endmodule')
    out.append(END)
    return '\n'.join(out) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()

    check_core()
    drift = 0
    for top in VARIANTS:
        gports = check_variant(top)
        path = OUT_DIR / (top + '.sv')
        if not path.exists():
            die('%s 不存在：文件头注释要先写好（本脚本只替换 GENERATED 区）' % path)
        txt = path.read_text()
        if txt.count(BEGIN) != 1 or txt.count(END) != 1:
            die('%s: GENERATED 标记必须各恰好一个' % path)
        head, rest = txt.split(BEGIN, 1)
        _, tail = rest.split(END + '\n', 1)
        new = head + gen_block(top, gports) + tail
        if new != txt:
            drift += 1
            if args.check:
                print('DRIFT %s' % path.relative_to(REPO))
            else:
                path.write_text(new)
                print('wrote %s' % path.relative_to(REPO))
        else:
            print('  %s: 无漂移（%d 端口）' % (top, len(gports)))
    if args.check and drift:
        print('gen_csrepctvec_leaves7 --check: DRIFT (%d files)' % drift)
        return 1
    if args.check:
        print('gen_csrepctvec_leaves7 --check: OK (%d files)' % len(VARIANTS))
    return 0


if __name__ == '__main__':
    sys.exit(main())
