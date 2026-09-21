#!/usr/bin/env python3
"""gen_ptwcache.py —— 生成 rtl/mmu/PtwCache.sv 里**纯机械**的那几段。

为什么要有这个生成器：PtwCache 的边界是 firtool 展平过的——SplittedSRAM_2 一个子模块
就有 1015 个标量端口，MbistPipePtwL0 有 173 个。这些连线一根都不能错，但里面没有任何
设计判断，靠手敲只会引入抄写错误。所以：

  * 端口表、子模块例化连线、DFT 透传、wrapper  —— 本脚本从 G1 golden 逐根抄出来；
  * 几何/类型/流水/复位域/替换策略等**需要判断**的部分 —— 手写在 parts/ 下的片段里，
    本脚本只负责拼接，不生成。

★本文件不做任何等价性判断★：它抄的是 golden 的连线拓扑，抄对了不等于逻辑对了。

用法:
    python3 scripts/gen_ptwcache.py            # 写出 rtl/mmu/PtwCache.sv
    python3 scripts/gen_ptwcache.py --check    # 只校验产物与重算结果逐字节一致
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('GOLDEN_RTL',
                                     '/home/eda/xs-env/G1-canonical/golden-rtl'))
SRC = GOLDEN / 'PtwCache.sv'
OUT = REPO / 'rtl' / 'mmu' / 'PtwCache.sv'
PARTS = REPO / 'rtl' / 'mmu' / 'parts'   # 手写片段，扩展名 .svpart 故不被任何 *.sv/*.svh 闸扫到

# golden PtwCache.sv 里各段的 1-based 行号。★改 golden 版本必须重新量★
PORT_FIRST, PORT_LAST = 88, 542          # 端口表（不含 `module` 行与 `);`）
INST = {                                  # 实例块 [起, 止]，含 `);`
    'l1':    (43250, 43388),
    'mbL1':  (43388, 43412),
    'l0':    (43557, 44575),
    'mbL0':  (44575, 44749),
}


def golden_lines():
    return SRC.read_text().split('\n')


def parse_ports(L):
    out = []
    for ln in L[PORT_FIRST - 1:PORT_LAST]:
        m = re.match(r'\s+(input|output|inout)\s+(\[[^\]]*\]\s+)?(\w+),?\s*$', ln)
        if not m:
            raise SystemExit('端口行解析不了（fail-closed）: %r' % ln)
        out.append((m.group(1), (m.group(2) or '').strip(), m.group(3)))
    if len(out) != 455:
        raise SystemExit('端口数 %d != 455 —— golden 变了，先重新量行号' % len(out))
    return out


def parse_inst(L, key):
    first, last = INST[key]
    seg = '\n'.join(L[first - 1:last])
    out = []
    for m in re.finditer(r'\.(\w+)\s*\n?\s*\(([^()]*(?:\([^()]*\)[^()]*)*)\)\s*,?', seg):
        out.append((m.group(1), ' '.join(m.group(2).split())))
    return out


def wire_widths(L):
    """golden 里所有 `wire [a:b] name;` 的宽度串，用来给中间信号定宽。"""
    w = {}
    for ln in L:
        m = re.match(r'\s+wire\s+(\[[^\]]*\]\s+)?(\w+)\s*[;=]', ln)
        if m:
            w.setdefault(m.group(2), (m.group(1) or '').strip())
    return w


# ---------------------------------------------------------------------------
# 端口表 / wrapper
# ---------------------------------------------------------------------------
def emit_portlist(ports, indent='  '):
    w = max(len(p[1]) for p in ports)
    out = []
    for i, (d, rng, n) in enumerate(ports):
        kw = 'input  logic' if d == 'input' else 'output logic'
        out.append('%s%s %-*s %s%s' % (indent, kw, w, rng, n,
                                       '' if i == len(ports) - 1 else ','))
    return out


def emit_wrapper(ports):
    out = ['module PtwCache(']
    out += emit_portlist(ports)
    out += [');', '',
            '  // 薄壳：golden 同名、逐位同序的端口表，整体透传给可读核。',
            '  xs_PtwCache_core u_core (']
    w = max(len(n) for _, _, n in ports)
    for i, (_, _, n) in enumerate(ports):
        out.append('    .%-*s (%s)%s' % (w, n, n, '' if i == len(ports) - 1 else ','))
    out += ['  );', '', 'endmodule']
    return out


# ---------------------------------------------------------------------------
# 子模块例化：golden 驱动表达式 -> 可读核信号名
# ---------------------------------------------------------------------------
UNTRACED = {}          # name -> (width, 说明)
RDATA = {}             # name -> width


def xlate_sram(level, port, expr, widths):
    P = level
    if port == 'clock':
        return '%s_clk' % P
    if port == 'reset':
        return 'reset'
    if port == 'io_r_req_valid':
        return '%s_r_valid' % P
    if port == 'io_r_req_bits_setIdx':
        return '%s_r_set' % P
    m = re.match(r'io_r_resp_data_(\d+)_entries_(.+)$', port)
    if m:
        name = '%s_rdata_%s_%s' % (P, m.group(1), m.group(2))
        RDATA[name] = widths.get(expr, widths.get(expr.lstrip('_'), ''))
        return name
    if port == 'io_w_req_valid':
        return '%s_refill' % P
    if port == 'io_w_req_bits_setIdx':
        return '%s_w_set' % P
    if port == 'io_w_req_bits_waymask':
        return '%s_w_waymask' % P
    m = re.match(r'io_w_req_bits_data_(\d+)_entries_(.+)$', port)
    if m:
        f = m.group(2)
        # 一行 512 位里第 i 个 PTE 的定长字段：直接写成 refill_pte[i] 的切片，
        # 比 golden 的 io_refill_bits_ptes[64i+47:64i+10] 好读，且是同一根线。
        mm = re.fullmatch(r'ppns_(\d)', f)
        if mm:
            return 'refill_pte[%s][47:10]' % mm.group(1)
        mm = re.fullmatch(r'pbmts_(\d)', f)
        if mm:
            return 'refill_pte[%s][62:61]' % mm.group(1)
        mm = re.fullmatch(r'vs_(\d)', f)
        if mm:
            return '%s_w_vs[%s]' % (P, mm.group(1))
        mm = re.fullmatch(r'onlypf_(\d)', f)
        if mm:
            return '%s_w_onlypf[%s]' % (P, mm.group(1))
        mm = re.fullmatch(r'perms_(\d)_(\w)', f)
        if mm:
            return '%s_w_perms[%s].%s' % (P, mm.group(1), mm.group(2))
        if f in ('tag', 'asid', 'vmid', 'prefetch'):
            return '%s_w_%s' % (P, f)
        UNTRACED.setdefault('%s_w_%s' % (P, f), '')
        return '%s_w_%s' % (P, f)
    if port.startswith('boreChildrenBd_bore') or port.startswith('sigFromSrams_bore'):
        return expr                         # MBIST/DFT：照抄 golden 的透传
    raise SystemExit('未分类 SRAM 端口 %s' % port)


def xlate_mbist(port, expr):
    """golden 在 MBIST 上游插了一层 `bd_*`/`bd_1_*` 的纯改名 wire；可读核里省掉这层，
    直接连到 boreChildrenBd_bore(_1)_* 端口本身。"""
    if port in ('clock', 'reset'):
        return port
    m = re.fullmatch(r'bd_1_(\w+)', expr)
    if m:
        return 'boreChildrenBd_bore_1_' + m.group(1)
    m = re.fullmatch(r'bd_(\w+)', expr)
    if m:
        return 'boreChildrenBd_bore_' + m.group(1)
    if expr.startswith('childBd_'):
        return expr                         # 下游 childBd_* 线束
    raise SystemExit('未分类 MBIST 端口 %s -> %s' % (port, expr))


def emit_inst(mod, inst, conns, xl):
    body = [(p, xl(p, e)) for p, e in conns]
    w = max(len(p) for p, _ in body)
    out = ['  %s %s (' % (mod, inst)]
    for i, (p, e) in enumerate(body):
        out.append('    .%-*s (%s)%s' % (w, p, e, '' if i == len(body) - 1 else ','))
    out.append('  );')
    return out



# ---------------------------------------------------------------------------
# §19 stage1 的 8 条表项：逐条同形，只有行内序号 i 变。手敲 8 遍只会抄错，
# 所以这一段由本脚本展开 —— 形状（优先级树、各字段的取法）写在 30_resp.svpart 的注释里，
# 本函数不含任何设计判断。
# ---------------------------------------------------------------------------
PERM_BITS = ('d', 'a', 'g', 'u', 'x', 'w', 'r')


def emit_stage1_fanout():
    out = ['  logic [34:0]     stage1_tag;',
           '  logic [15:0]     stage1_asid;',
           '  logic [13:0]     stage1_vmid;',
           '  assign stage1_tag  = resp_vpn[37:3];',
           '  assign stage1_asid = (|resp_s2x) ? io_csr_dup_0_vsatp_asid'
           ' : io_csr_dup_0_satp_asid;',
           '  assign stage1_vmid = io_csr_dup_0_hgatp_vmid[13:0];',
           '']
    for i in range(8):
        e = '  assign io_resp_bits_stage1_entry_%d_' % i
        out += [
            '%stag   = stage1_tag;' % e,
            '%sasid  = stage1_asid;' % e,
            '%svmid  = stage1_vmid;' % e,
            '%sn     = stage1_n;' % e,
            '%slevel = stage1_level;' % e,
            '%sv     = stage1_v[%d];' % (e, i),
            '%spf    = ~stage1_v[%d];' % (e, i),
            '%scf    = resp_res_l0.hit & l0_cfs[%d];' % (e, i),
            '%spbmt  = resp_res_l0.hit ? resp_res_l0.pbmt[%d]' % (e, i),
            '                              : resp_res_sp.hit ? resp_res_sp.pbmt'
            ' : nonleaf_pbmt;',
        ]
        for b in PERM_BITS:
            out += ['%sperm_%s = resp_res_l0.hit ? resp_res_l0.perm[%d].%s'
                    % (e, b, i, b),
                    '                                : resp_res_sp.hit'
                    ' & resp_res_sp.perm.%s;' % b]
        for name, sl in (('ppn', '[37:3]'), ('ppn_low', '[2:0]')):
            pre = "{6'h0, " if name == 'ppn' else ''
            suf = '}' if name == 'ppn' else ''
            out += ['%s%s = %sresp_res_l0.hit ? resp_res_l0.ppn[%d]%s'
                    % (e, name, pre, i, sl),
                    '                          : resp_res_sp.hit ? resp_res_sp.ppn%s'
                    % sl,
                    '                          : resp_res_l1.hit ? resp_res_l1.ppn%s'
                    % sl,
                    '                          : resp_res_l2.hit ? resp_res_l2.ppn%s'
                    % sl,
                    '                                            : resp_res_l3.ppn%s%s;'
                    % (sl, suf)]
        out.append('')
    for i in range(8):
        out.append("  assign io_resp_bits_stage1_pteidx_%d = (resp_pte_idx == 3'd%d);"
                   % (i, i))
    out.append('')
    # bitmapCheck 的 8 条 ptes / cfs 扇出（形状见 30_resp.svpart 的 §19 注释）。
    # ★toHptw 一侧没有 cfs 端口★：golden 里下游没人读，firtool 已经把它裁掉了。
    for i in range(8):
        out += ['  assign io_resp_bits_toFsm_bitmapCheck_ptes_%d =' % i,
                '    resp_res_sp.jmp_bitmap_check ? resp_res_sp.pte'
                ' : resp_res_l0.ptes[%d];' % i]
    for i in range(8):
        out.append('  assign io_resp_bits_toFsm_bitmapCheck_cfs_%d'
                   '  = resp_res_l0.cfs[%d];' % (i, i))
    for i in range(8):
        out.append('  assign io_resp_bits_toHptw_bitmapCheck_ptes_%d'
                   ' = resp_res_l0.ptes[%d];' % (i, i))
    return out


def build():
    L = golden_lines()
    ports = parse_ports(L)
    widths = wire_widths(L)

    l1 = parse_inst(L, 'l1')
    l0 = parse_inst(L, 'l0')
    mb1 = parse_inst(L, 'mbL1')
    mb0 = parse_inst(L, 'mbL0')

    inst_l1 = emit_inst('SplittedSRAM_1', 'u_l1_sram', l1,
                        lambda p, e: xlate_sram('l1', p, e, widths))
    inst_l0 = emit_inst('SplittedSRAM_2', 'u_l0_sram', l0,
                        lambda p, e: xlate_sram('l0', p, e, widths))
    inst_mb1 = emit_inst('MbistPipePtwL1', 'u_mbist_l1', mb1, xlate_mbist)
    inst_mb0 = emit_inst('MbistPipePtwL0', 'u_mbist_l0', mb0, xlate_mbist)

    # childBd_* 线束：MbistPipe 下游到 SRAM 的连线，宽度从 golden 抄
    childbd = sorted({e for _, e in l1 + l0 + mb1 + mb0 if e.startswith('childBd_')},
                     key=lambda s: (len(s), s))
    decl_childbd = ['  // MBIST 分发级到 SRAM 的线束（宽度逐根抄自 golden）']
    for n in childbd:
        decl_childbd.append('  logic %-10s %s;' % (widths.get(n, ''), n))

    decl_rdata = ['  // SRAM 读回的扁平线（golden 的端口名，逐根抄）——',
                  '  // 命中判定读的是下面 §16 打包出来的 l1_line_t / l0_line_t。']
    for n in sorted(RDATA):
        decl_rdata.append('  logic %-10s %s;' % (RDATA[n], n))

    decl_pack = ['', '  // BEGIN GENERATED(sram_rdata_pack)',
                 '  // 把 SRAM 回读的扁平线打包成 §16 用的 struct（纯改名，无逻辑）。']
    for n in sorted(RDATA):
        m = re.match(r'(l[01])_rdata_(\d+)_(.+)$', n)
        if not m:
            raise SystemExit('rdata 名字解析不了（fail-closed）: %s' % n)
        lvl, way, f = m.group(1), m.group(2), m.group(3)
        dst = '%s_sram_rdata[%s]' % (lvl, way)
        mm = re.fullmatch(r'(pbmts|ppns|vs|onlypf)_(\d+)', f)
        if mm:
            tgt = '%s.%s[%s]' % (dst, mm.group(1), mm.group(2))
        else:
            mm = re.fullmatch(r'perms_(\d+)_(\w)', f)
            if mm:
                tgt = '%s.perms[%s].%s' % (dst, mm.group(1), mm.group(2))
            elif f in ('tag', 'asid', 'vmid', 'prefetch'):
                tgt = '%s.%s' % (dst, f)
            else:
                raise SystemExit('rdata 字段没分类（fail-closed）: %s' % n)
        decl_pack.append('  assign %-40s = %s;' % (tgt, n))
    decl_pack.append('  // END GENERATED(sram_rdata_pack)')

    # 未追清的写载荷：统一声明并**显式钉 0**。钉 0 不是"默认值"，是"还没做"的标记；
    # 任何一根被真正追清后，就从这张表里消失。
    decl_untraced = []
    for n in sorted(UNTRACED):
        decl_untraced.append('  logic %s;' % n)
    decl_untraced.append('')
    for n in sorted(UNTRACED):
        decl_untraced.append("  assign %s = '0;" % n)

    def part(name):
        return (PARTS / name).read_text().rstrip('\n').split('\n')

    out = []
    out += part('00_header.svpart')
    out += part('10_pkg.svpart')
    out += ['', 'module xs_PtwCache_core(']
    out += emit_portlist(ports)
    out += [');']
    out += part('20_core_body.svpart')
    out += part('25_refill_wdata.svpart')
    out += part('26_replace.svpart')
    out += part('27_refill_comb.svpart')
    out += ['']
    out += decl_rdata
    out += ['']
    out += decl_childbd
    out += part('28_hit.svpart')
    out += decl_pack
    # ★30_resp 必须排在 29_state_ff 前面★：时序块里要写 resp_res / bypass /
    # perf 这些寄存器，而它们声明在 30 里。SV 里变量必须先声明后用。
    resp = part('30_resp.svpart')
    at = [i for i, l in enumerate(resp)
          if l.startswith('  // BEGIN GENERATED(stage1_entry_fanout)')]
    if len(at) != 1:
        raise SystemExit('30_resp.svpart 里的 stage1 展开标记不唯一（fail-closed）')
    out += resp[:at[0] + 1] + emit_stage1_fanout() + resp[at[0] + 1:]
    out += part('31_sfence.svpart')
    out += part('32_wakeup.svpart')
    out += part('29_state_ff.svpart')
    out += ['', '  // ' + '-' * 75,
            '  // §8 未追清清单 —— ★占位信号，当前值无意义★',
            '  //',
            '  // 下面每一根都还没有从 golden 逐条追出方程。它们现在被恒定值顶着，',
            '  // 只为让本骨架能 elaborate；任何人引用它们都会拿到错值。',
            '  // 回填写数据（§6）、替换与受害者选择（§7）、回填侧状态（§9/§11）、',
            '  // 流水载荷（§12）与五级命中（§14-§16）已从本表毕业，都有',
            '  // verif/study/PtwCache_refill 的定向差分对照钉住。剩下的追清顺序：',
            '  // sfence/hfence 失效 -> ecc flush -> l0_bitmap 写侧与 wakeup ->',
            '  // 响应装配（io.resp 的 220 根）-> perf。',
            '']
    out += decl_untraced
    # ★这里曾经再发一遍 decl_rdata / decl_childbd★——它们早已挪到 §16 之前（见上），
    # 这一份是搬家时忘了删的旧拷贝，产物里因此有 594 组重复声明（VCS 只给 IPDW 警告，
    # 幂等闸因为生成器与产物一起陈旧而照样绿）。留一份，不许再发。
    # 哪些输出已经有真驱动 —— ★从产物本身量，不维护名单★。
    # 手维护的名单会和 parts 脱节：追清了忘了加，那根就被下面的钉 0 覆盖掉，
    # elaborate 报重复驱动还好，若名单多写一个就是"以为驱动了其实悬空"。
    body = '\n'.join(out)
    driven = set(re.findall(r'^\s*assign\s+(\w+)\s*=', body, re.M))
    # 子模块的输出经例化端口回连到本层端口，也算有驱动（不归本层管）。
    for _line in inst_l1 + inst_l0 + inst_mb1 + inst_mb0:
        _m = re.match(r'\s*\.\w+\s*\((\w+)\)', _line)
        if _m:
            driven.add(_m.group(1))
    undriven = [n for d, _, n in ports if d == 'output' and n not in driven]
    if undriven:
        out += ['',
                '  // ★以下 %d 个输出还没有真实驱动★——钉 0 只为让骨架能 elaborate，'
                % len(undriven),
                '  // 不是它们的正确值。名单由本脚本从产物实测，不手维护。']
        for n in undriven:
            out += ["  assign %s = '0;" % n]
    else:
        out += ['',
                '  // ★455 个端口里的全部 236 个输出都已有真实驱动★'
                '（本行由生成器实测，不是声明）。',
                '  // 早先那张"钉 0 占位"表已清空 —— 但**有驱动不等于驱动得对**，'
                '对不对是 UT 与 FM 的事。']
    out += ['', '  // ' + '-' * 75,
            '  // §9 子模块例化（连线拓扑逐根抄自 golden，见 gen_ptwcache.py）',
            '  //',
            '  // l1 级 SRAM：4 组 2 路，每条表项 8 个 PDE。本仓尚无 SplittedSRAM_1 可读实现。']
    out += inst_l1
    out += ['', '  // l1 级 MBIST 分发（可读实现在 rtl/dft/MbistPipePtwL1.sv）']
    out += inst_mb1
    out += ['', '  // l0 级 SRAM：64 组 4 路，每条表项 8 个 PTE。本仓尚无 SplittedSRAM_2 可读实现。']
    out += inst_l0
    out += ['', '  // l0 级 MBIST 分发（可读实现在 rtl/dft/MbistPipePtwL0.sv）']
    out += inst_mb0
    out += ['', 'endmodule', '']
    out += emit_wrapper(ports)
    out += ['']
    return '\n'.join(out) + '\n'


def materialize(path):
    """写出文件并补「本文件导航」。导航用的是 scripts/gen_file_nav.py 的同一份实现，
    不另写一套——readability_audit 的 E 项按行号校验导航，两套算法迟早对不上。"""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(build())
    sys.path.insert(0, str(REPO / 'scripts'))
    import gen_file_nav
    gen_file_nav.apply(path)
    return path.read_text()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    if a.check:
        tmp = OUT.with_suffix('.sv.regen')
        try:
            txt = materialize(tmp)
        finally:
            if tmp.exists():
                tmp.unlink()
        cur = OUT.read_text() if OUT.exists() else ''
        if cur != txt:
            print('gen_ptwcache --check: DRIFT —— rtl/mmu/PtwCache.sv 与重算结果不一致')
            return 1
        print('gen_ptwcache --check: 逐字节一致')
        return 0
    txt = materialize(OUT)
    print('written %s (%d 行)' % (OUT, txt.count('\n')))
    return 0


if __name__ == '__main__':
    sys.exit(main())
