#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_tlbfa_family.py —— 生成 TLBFA 家族四个变体的薄 wrapper。

家族形态：一个参数化可读核 rtl/memblock/xs_TLBFA_core.sv + 每变体一个薄文件
（rtl/memblock/TLBFA{,_1,_2,_3}.sv）。薄文件里**没有逻辑**，只做两件事：
  1) 声明与 G1 golden 逐位同名同宽同序的端口（端口表直接从 golden 抄下来，
     所以不可能漏/多/错宽——这正是本脚本存在的理由）；
  2) 把这些扁平端口接到核的向量端口上，并处理 firtool 在各变体上剪掉的字段。

为什么不手写：四个变体合计 588 个端口，手写端口表是纯抄写劳动，抄错一位
（比如 ppn 写成 [34:0]）在 UT 里表现为大面积失配，在 FM 里表现为端口不匹配，
排查成本远高于写这个脚本。端口契约闸（scripts/port_contract_lint.py）会校验
结果，但闸只在"已经写错"之后才响。

用法:
  python3 scripts/gen_tlbfa_family.py            # 写文件
  python3 scripts/gen_tlbfa_family.py --check     # 只校验产物与本脚本一致（幂等闸）
"""
import argparse
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
OUT_DIR = REPO / 'rtl' / 'memblock'

# 变体参数：全部实测自 golden（端口数 / entry 寄存器组数 / 字段存在与否），
# 不是从 Chisel 默认值推的。
VARIANTS = {
    'TLBFA': dict(
        ports=3, keep_wperm=0, ndups=1, parent='itlb（取指 TLB）',
        golden_lines=21303,
        notes=[
            '本变体 = itlb 的存储阵列：3 个查询端口（ICache 三路 vpn 查询），nDups=1。',
            'KEEP_WPERM=0：取指不关心"能不能写"，父级从不读 perm.d / g_perm.{d,w,r}，',
            'firtool 把这 4×48 个寄存器连同端口一起消掉了——本变体的端口表里确实',
            '找不到 io_r_resp_*_bits_perm_*_d，也找不到 g_perm 的 d/w/r。',
            '同理 g_perm 只剩 pf/af/a/x 四位（其余在四个变体里都被消掉）。',
        ]),
    'TLBFA_1': dict(
        ports=4, keep_wperm=1, ndups=2, parent='ldtlb（load TLB）',
        golden_lines=27196,
        notes=[
            '本变体 = dtlb-load 的存储阵列：4 个查询端口，nDups=2。',
            'nDups 是 Chisel 里为后端布线**复制驱动**用的：resp.ppn(0) 与 resp.ppn(1)',
            '是逐字相同的两组方程，firtool 也照抄了两份（golden 里 _GEN 编号不同、',
            '表达式一字不差）。重写里只算一份再扇出到两个端口——功能等价、可读性好得多。',
            '端口表里 dup1 只在 0/1/2 号端口、且只有 ppn 与 perm 的一部分存在：',
            '那是父级 TLB 只用到这几根线，firtool 把没人读的 dup 端口消了。',
        ]),
    'TLBFA_2': dict(
        ports=2, keep_wperm=1, ndups=1, parent='sttlb（store TLB）',
        golden_lines=20067,
        notes=[
            '本变体 = dtlb-store 的存储阵列：2 个查询端口，nDups=1。',
            '与 TLBFA_3 参数完全相同，唯一差别是父级消端口的结果：',
            '本变体保留了 io_r_resp_*_bits_s2xlate_0，TLBFA_3 没有。',
        ]),
    'TLBFA_3': dict(
        ports=2, keep_wperm=1, ndups=1, parent='pftlb（prefetch TLB）',
        golden_lines=19972,
        notes=[
            '本变体 = dtlb-prefetch 的存储阵列：2 个查询端口，nDups=1。',
            '与 TLBFA_2 逻辑完全一致；差别只在端口：预取通路不看 s2xlate，',
            '所以 io_r_resp_*_bits_s2xlate_0 被 firtool 消掉了（核照算不误，只是没人接）。',
        ]),
}

PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[([0-9]+):([0-9]+)\]\s+)?(\w+)\s*,?\s*$')


def golden_ports(name):
    """从 golden 模块头抄端口表：返回 [(dir, width_str, msb, name)]，顺序即 golden 顺序。"""
    text = (GOLDEN / f'{name}.sv').read_text()
    m = re.search(rf'^module {name}\(\n(.*?)^\);', text, re.S | re.M)
    if not m:
        sys.exit(f'{name}: 找不到模块头')
    out = []
    for ln in m.group(1).splitlines():
        pm = PORT_RE.match(ln)
        if not pm:
            sys.exit(f'{name}: 端口行解析失败: {ln!r}')
        d, msb, lsb, pname = pm.groups()
        if msb is None:
            out.append((d, '', 1, pname))
        else:
            assert lsb == '0', ln
            out.append((d, f'[{msb}:{lsb}]', int(msb) + 1, pname))
    return out


# --- 扁平 golden 端口 -> 核端口的映射 -------------------------------------
# 返回 (核信号表达式, 是否输入)。核信号一律 core_<名>；索引用 [端口号]。
SIMPLE_IN = {
    'clock': 'clock', 'reset': 'reset',
    'io_sfence_valid': 'core_sfence_valid',
    'io_sfence_bits_rs1': 'core_sfence_rs1',
    'io_sfence_bits_rs2': 'core_sfence_rs2',
    'io_sfence_bits_addr': 'core_sfence_addr',
    'io_sfence_bits_id': 'core_sfence_id',
    'io_sfence_bits_hv': 'core_sfence_hv',
    'io_sfence_bits_hg': 'core_sfence_hg',
    'io_csr_satp_asid': 'core_csr_satp_asid',
    'io_csr_vsatp_asid': 'core_csr_vsatp_asid',
    'io_csr_hgatp_vmid': 'core_csr_hgatp_vmid',
    'io_csr_mbmc_BME': 'core_csr_mbmc_bme',
    'io_csr_mbmc_CMODE': 'core_csr_mbmc_cmode',
    'io_csr_priv_virt': 'core_csr_priv_virt',
    'io_w_valid': 'core_w_valid',
    'io_w_bits_wayIdx': 'core_w_way',
    'io_w_bits_data_s2xlate': 'core_w_s2xlate',
    'io_w_bits_data_s1_pf': 'core_w_s1_pf',
    'io_w_bits_data_s1_af': 'core_w_s1_af',
    'io_w_bits_data_s2_gpf': 'core_w_s2_gpf',
    'io_w_bits_data_s2_gaf': 'core_w_s2_gaf',
}


def map_port(p):
    """golden 端口名 -> 核侧表达式；None 表示"本端口在核里没有对应物"（不应出现）。"""
    if p in SIMPLE_IN:
        return SIMPLE_IN[p]
    m = re.fullmatch(r'io_r_req_(\d+)_valid', p)
    if m:
        return f'core_req_valid[{m.group(1)}]'
    m = re.fullmatch(r'io_r_req_(\d+)_bits_(vpn|s2xlate)', p)
    if m:
        return f'core_req_{m.group(2)}[{m.group(1)}]'
    m = re.fullmatch(r'io_r_resp_(\d+)_bits_hit', p)
    if m:
        return f'core_resp_hit[{m.group(1)}]'
    m = re.fullmatch(r'io_r_resp_(\d+)_bits_(ppn|pbmt|g_pbmt|s2xlate)_(\d+)', p)
    if m:
        return f'core_resp_{m.group(2)}[{m.group(1)}]'
    m = re.fullmatch(r'io_r_resp_(\d+)_bits_(g_perm|perm)_(\d+)_(\w+)', p)
    if m:
        return f'core_resp_{m.group(2)}_{m.group(4)}[{m.group(1)}]'
    m = re.fullmatch(r'io_access_(\d+)_touch_ways_valid', p)
    if m:
        return f'core_access_touch_valid[{m.group(1)}]'
    m = re.fullmatch(r'io_access_(\d+)_touch_ways_bits', p)
    if m:
        return f'core_access_touch_way[{m.group(1)}]'
    m = re.fullmatch(r'io_w_bits_data_s1_entry_(\w+)', p)
    if m:
        return f'core_w_s1_entry_{m.group(1)}'
    m = re.fullmatch(r'io_w_bits_data_s2_entry_(\w+)', p)
    if m:
        return f'core_w_s2_entry_{m.group(1)}'
    m = re.fullmatch(r'io_w_bits_data_s1_(ppn_low|valididx|pteidx)_(\d+)', p)
    if m:
        return f'core_w_s1_{m.group(1)}[{m.group(2)}]'
    sys.exit(f'未知端口形状: {p}')


# 核侧信号声明（名字, 位宽表达式, 是否按端口号成数组）
def core_decls(ports):
    P = ports
    perm_f = ['pf', 'af', 'v', 'd', 'a', 'g', 'u', 'x', 'w', 'r']
    gperm_f = ['pf', 'af', 'd', 'a', 'x', 'w', 'r']
    d = [
        ('core_sfence_valid', '', ''), ('core_sfence_rs1', '', ''), ('core_sfence_rs2', '', ''),
        ('core_sfence_addr', '[49:0]', ''), ('core_sfence_id', '[15:0]', ''),
        ('core_sfence_hv', '', ''), ('core_sfence_hg', '', ''),
        ('core_csr_satp_asid', '[15:0]', ''), ('core_csr_vsatp_asid', '[15:0]', ''),
        ('core_csr_hgatp_vmid', '[15:0]', ''), ('core_csr_mbmc_bme', '', ''),
        ('core_csr_mbmc_cmode', '', ''), ('core_csr_priv_virt', '', ''),
        ('core_req_valid', '', f'[{P-1}:0]'),
        ('core_req_vpn', '[37:0]', f'[{P-1}:0]'),
        ('core_req_s2xlate', '[1:0]', f'[{P-1}:0]'),
        ('core_resp_hit', '', f'[{P-1}:0]'),
        ('core_resp_ppn', '[35:0]', f'[{P-1}:0]'),
        ('core_resp_pbmt', '[1:0]', f'[{P-1}:0]'),
        ('core_resp_g_pbmt', '[1:0]', f'[{P-1}:0]'),
    ]
    d += [(f'core_resp_perm_{f}', '', f'[{P-1}:0]') for f in perm_f]
    d += [(f'core_resp_g_perm_{f}', '', f'[{P-1}:0]') for f in gperm_f]
    d += [
        ('core_resp_s2xlate', '[1:0]', f'[{P-1}:0]'),
        ('core_w_valid', '', ''), ('core_w_way', '[5:0]', ''), ('core_w_s2xlate', '[1:0]', ''),
        ('core_w_s1_entry_tag', '[34:0]', ''), ('core_w_s1_entry_asid', '[15:0]', ''),
        ('core_w_s1_entry_vmid', '[13:0]', ''), ('core_w_s1_entry_n', '', ''),
        ('core_w_s1_entry_pbmt', '[1:0]', ''),
        ('core_w_s1_entry_perm_d', '', ''), ('core_w_s1_entry_perm_a', '', ''),
        ('core_w_s1_entry_perm_g', '', ''), ('core_w_s1_entry_perm_u', '', ''),
        ('core_w_s1_entry_perm_x', '', ''), ('core_w_s1_entry_perm_w', '', ''),
        ('core_w_s1_entry_perm_r', '', ''),
        ('core_w_s1_entry_level', '[1:0]', ''), ('core_w_s1_entry_v', '', ''),
        ('core_w_s1_entry_ppn', '[40:0]', ''),
        ('core_w_s1_ppn_low', '[2:0]', '[7:0]'),
        ('core_w_s1_valididx', '', '[7:0]'),
        ('core_w_s1_pteidx', '', '[7:0]'),
        ('core_w_s1_pf', '', ''), ('core_w_s1_af', '', ''),
        ('core_w_s2_entry_tag', '[37:0]', ''), ('core_w_s2_entry_vmid', '[13:0]', ''),
        ('core_w_s2_entry_n', '', ''), ('core_w_s2_entry_pbmt', '[1:0]', ''),
        ('core_w_s2_entry_ppn', '[37:0]', ''),
        ('core_w_s2_entry_perm_d', '', ''), ('core_w_s2_entry_perm_a', '', ''),
        ('core_w_s2_entry_perm_g', '', ''), ('core_w_s2_entry_perm_u', '', ''),
        ('core_w_s2_entry_perm_x', '', ''), ('core_w_s2_entry_perm_w', '', ''),
        ('core_w_s2_entry_perm_r', '', ''),
        ('core_w_s2_entry_level', '[1:0]', ''),
        ('core_w_s2_gpf', '', ''), ('core_w_s2_gaf', '', ''),
        ('core_access_touch_valid', '', f'[{P-1}:0]'),
        ('core_access_touch_way', '[5:0]', f'[{P-1}:0]'),
    ]
    return d


CORE_PORT_ORDER = None   # 见 core_port_map()


def core_port_map(ports):
    """核端口名 -> 连接的核侧信号（名字相同，去掉 core_ 前缀的映射关系写在这）。"""
    pairs = [('clock', 'clock'), ('reset', 'reset')]
    for nm, _, _ in core_decls(ports):
        pairs.append((nm[len('core_'):], nm))
    return pairs


def render(name):
    spec = VARIANTS[name]
    P = spec['ports']
    ports = golden_ports(name)
    mapped = {p[3]: map_port(p[3]) for p in ports}

    L = []
    A = L.append
    A('// ' + '=' * 76)
    A(f'// {name} —— {spec["parent"]} 的 L1 TLB 全相联存储阵列（TLBFA 家族薄 wrapper）')
    A('//')
    A(f'// 本变体参数与规模：PORTS={P}（查询端口数）  nWays=48（全相联条数，四变体一致）')
    A(f'//   nDups={spec["ndups"]}   KEEP_WPERM={spec["keep_wperm"]}   '
      f'golden {name}.sv = {spec["golden_lines"]} 行 / {len(ports)} 端口')
    A('//')
    for n in spec['notes']:
        A(f'// {n}')
    A('//')
    A('// 逻辑全部在参数化核 xs_TLBFA_core（同目录 xs_TLBFA_core.sv）里；本文件只做')
    A('// 端口展平与改名：把 golden 的扁平 io_* 名接到核的按端口号成组的向量端口上。')
    A('// 端口表逐位抄自 G1 golden 同名模块（scripts/gen_tlbfa_family.py 生成，勿手改）。')
    A('// ' + '=' * 76)
    A('')
    A('// BEGIN GENERATED(tlbfa-wrapper)')
    A(f'module {name}(')
    for i, (d, w, _, pname) in enumerate(ports):
        comma = ',' if i + 1 < len(ports) else ''
        wid = f'{w:<8}' if w else ' ' * 8
        A(f'  {d:<6} {wid}{pname}{comma}')
    A(');')
    A('')
    A('  // ---- 核侧信号（按端口号成组的 packed 数组，与核端口同型）----')
    for nm, w, dim in core_decls(P):
        dims = f'{dim}{w}'
        A(f'  logic {dims:<14}{nm};')
    A('')
    A('  // ---- 输入：golden 扁平端口 -> 核 ----')
    for d, w, _, pname in ports:
        if d != 'input' or pname in ('clock', 'reset'):
            continue
        A(f'  assign {mapped[pname]} = {pname};')
    A('')
    A('  xs_TLBFA_core #(')
    A(f'    .PORTS      ({P}),')
    A(f'    .KEEP_WPERM ({spec["keep_wperm"]})')
    A('  ) u_core (')
    pm = core_port_map(P)
    for i, (pn, sn) in enumerate(pm):
        comma = ',' if i + 1 < len(pm) else ''
        A(f'    .{pn:<20}({sn}){comma}')
    A('  );')
    A('')
    A('  // ---- 输出：核 -> golden 扁平端口 ----')
    A('  // 同一个核信号可能接到多个 golden 端口（nDups 复制），也可能一个都不接')
    A('  //（该字段在本变体里被 firtool 消掉了）——两种情况都在上面的变体说明里交代过。')
    for d, w, _, pname in ports:
        if d != 'output':
            continue
        A(f'  assign {pname} = {mapped[pname]};')
    A('')
    A('endmodule')
    A('// END GENERATED(tlbfa-wrapper)')
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    rc = 0
    for name in VARIANTS:
        txt = render(name)
        dst = OUT_DIR / f'{name}.sv'
        if a.check:
            cur = dst.read_text() if dst.exists() else None
            if cur != txt:
                print(f'DRIFT {dst.relative_to(REPO)}')
                rc = 1
        else:
            dst.write_text(txt)
            print(f'wrote {dst.relative_to(REPO)}')
    if a.check and rc == 0:
        print('gen_tlbfa_family: 产物与生成器一致')
    return rc


if __name__ == '__main__':
    sys.exit(main())
