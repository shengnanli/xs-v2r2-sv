#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_uncache.py —— Uncache 的机械派生区：wrapper、FM 匹配前钉点、UT tb 的 DUT 区。

核（xs_Uncache_core，rtl/memblock/Uncache.sv 上半部）手写；本脚本只写三块机械件：
  1. rtl/memblock/Uncache.sv 里 `// BEGIN GENERATED(uncache_wrapper)` 区：
     端口与 golden 逐位同名同序的 wrapper `Uncache`，把扁平端口接到核的
     struct / 数组端口（规则表 PORT_RULES，一条 golden 端口对一条核表达式）。
  2. verif/ut/Uncache/fm_pins_pre.tcl：golden 扁平寄存器名 ↔ 核 SoA 数组寄存器名。
     每个 golden 寄存器都必须命中 REG_RULES 恰好一条（fail-closed）；钉点按位展开，
     总数写成字面整数（= golden 顶层寄存器位数），tcl 端逐条数 set_user_match 的返回值。
  3. verif/ut/Uncache/tb.sv 里 `// BEGIN GENERATED(uncache_tb_dut)` 区：
     输入/输出线声明、golden 与 Uncache_xs 双例化、逐端口比较任务。

用法:
  python3 scripts/gen_uncache.py          # 幂等写入（内容不变不碰文件）
  python3 scripts/gen_uncache.py --check  # 只比对不写，有漂移 rc=1（gate 用）
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN',
                                    '/home/eda/xs-env/G1-canonical/golden-rtl'))
TOP = 'Uncache'
RTL = REPO / 'rtl' / 'memblock' / 'Uncache.sv'
UT_DIR = REPO / 'verif' / 'ut' / 'Uncache'
N_ENTRIES = 16
N_PIPES = 3

# ---------------------------------------------------------------------------
# golden 端口 → 核端口表达式。按顺序试，第一条匹配者生效；一条都不中即报错。
# ---------------------------------------------------------------------------
PORT_RULES = [
    (r'clock', 'clock'),
    (r'reset', 'reset'),
    (r'auto_client_out_a_ready', 'a_ready'),
    (r'auto_client_out_a_valid', 'a_valid'),
    (r'auto_client_out_a_bits_(opcode|size|source|address|mask|data)', r'a_\1'),
    (r'auto_client_out_a_bits_user_memPageType_NC', 'a_user_nc'),
    (r'auto_client_out_a_bits_user_memBackType_MM', 'a_user_mm'),
    (r'auto_client_out_d_valid', 'd_valid'),
    (r'auto_client_out_d_bits_(source|denied|data|corrupt)', r'd_\1'),
    (r'io_hartId', 'hart_id'),
    (r'io_enableOutstanding', 'enable_outstanding'),
    (r'io_flush_valid', 'flush_valid'),
    (r'io_flush_empty', 'flush_empty'),
    (r'io_lsq_req_ready', 'req_ready'),
    (r'io_lsq_req_valid', 'req_valid'),
    (r'io_lsq_req_bits_(\w+)', r'req.\1'),
    (r'io_lsq_idResp_valid', 'id_resp_valid'),
    (r'io_lsq_idResp_bits_(\w+)', r'id_resp.\1'),
    (r'io_lsq_resp_ready', 'resp_ready'),
    (r'io_lsq_resp_valid', 'resp_valid'),
    (r'io_lsq_resp_bits_(\w+)', r'resp.\1'),
    (r'io_forward_(\d)_vaddr', r'fwd_vaddr[\1]'),
    (r'io_forward_(\d)_paddr', r'fwd_paddr[\1]'),
    (r'io_forward_(\d)_valid', r'fwd_valid[\1]'),
    (r'io_forward_(\d)_forwardMask_(\d+)', r'fwd_mask[\1][\2]'),
    (r'io_forward_(\d)_forwardData_(\d+)', r'fwd_data[\1][\2]'),
    (r'io_forward_(\d)_matchInvalid', r'fwd_match_invalid[\1]'),
    (r'io_wfi_wfiReq', 'wfi_req'),
    (r'io_wfi_wfiSafe', 'wfi_safe'),
    (r'io_busError_ecc_error_valid', 'bus_error_valid'),
    (r'io_busError_ecc_error_bits', 'bus_error_addr'),
    (r'gatewayIn_packed_42_bore', 'difftest_bore'),
]

# 核里 struct 型端口（wrapper 里声明成对应类型的线）
STRUCT_PORTS = {'req': 'lsq_req_t', 'id_resp': 'id_resp_t', 'resp': 'lsq_resp_t'}
# 核里数组型端口的声明
ARRAY_PORTS = {
    'fwd_vaddr': 'logic [LOAD_PIPES-1:0][VADDR_W-1:0]',
    'fwd_paddr': 'logic [LOAD_PIPES-1:0][PADDR_W-1:0]',
    'fwd_valid': 'logic [LOAD_PIPES-1:0]',
    'fwd_mask': 'logic [LOAD_PIPES-1:0][15:0]',
    'fwd_data': 'logic [LOAD_PIPES-1:0][15:0][7:0]',
    'fwd_match_invalid': 'logic [LOAD_PIPES-1:0]',
}

# ---------------------------------------------------------------------------
# golden 寄存器 → 核寄存器（u_core 下，FM 的 _reg 命名）。fn(match) -> 核寄存器名（不含 _reg 前缀位）
#   返回 (impl_base, is_vector_bits)：impl_base 是 FM 名去掉位下标的部分。
# ---------------------------------------------------------------------------
ENTRY_FIELDS = {'cmd': 'entry_cmd', 'addr': 'entry_addr', 'vaddr': 'entry_vaddr',
                'data': 'entry_data', 'mask': 'entry_mask', 'nc': 'entry_nc',
                'memBackTypeMM': 'entry_mm', 'resp_denied': 'entry_denied',
                'resp_corrupt': 'entry_corrupt'}
STATE_FIELDS = {'valid': 'st_valid', 'inflight': 'st_inflight',
                'waitSame': 'st_wait_same', 'waitReturn': 'st_wait_return'}


def port_suffix(s):
    """f1_fwdValid / f1_fwdValid_1 / f1_fwdValid_2 → 流水号"""
    return 0 if not s else int(s[1:])


def reg_rule(name):
    """golden 寄存器名 → [(impl 名模板, 位下标是否追加)]。返回 impl 名（不含位下标）。"""
    m = re.fullmatch(r'entries_(\d+)_(\w+)', name)
    if m and m.group(2) in ENTRY_FIELDS:
        return '%s_reg[%s]' % (ENTRY_FIELDS[m.group(2)], m.group(1))
    m = re.fullmatch(r'states_(\d+)_(\w+)', name)
    if m and m.group(2) in STATE_FIELDS:
        return '%s_reg[%s]' % (STATE_FIELDS[m.group(2)], m.group(1))
    m = re.fullmatch(r'noPending_(\d+)', name)
    if m:
        return 'no_pending_reg[%s]' % m.group(1)
    fixed = {
        'uState': 'u_state_reg',
        'do_uarch_drain': 'do_uarch_drain_reg',
        'io_lsq_idResp_valid_REG': 'id_resp_valid_q_reg',
        'io_wfi_wfiSafe_last_REG': 'wfi_safe_q_reg',
    }
    if name in fixed:
        return fixed[name]
    m = re.fullmatch(r'io_lsq_idResp_bits_(mid|sid|is2lq|nc)_r', name)
    if m:
        return 'id_resp_q_reg[%s]' % m.group(1)   # struct 成员：特殊处理（见 pin_pairs）
    m = re.fullmatch(r'f1_fwd(Mask|Data)Candidates_r(_\d+)?', name)
    if m:
        return 'f1_cand_%s_reg[%d]' % (m.group(1).lower(), port_suffix(m.group(2)))
    m = re.fullmatch(r'f1_fwdValid(_\d)?', name)
    if m:
        return 'f1_fwd_valid_reg[%d]' % port_suffix(m.group(1))
    m = re.fullmatch(r'f1_fwdPAddr(_\d)?', name)
    if m:
        return 'f1_paddr_reg[%d]' % port_suffix(m.group(1))
    m = re.fullmatch(r'f1_(fly|idle)TagMatches_(?:(\d)_)?(\d+)', name)
    if m:
        p = int(m.group(2)) if m.group(2) else 0
        return 'f1_%s_match_reg[%d][%s]' % (m.group(1), p, m.group(3))
    m = re.fullmatch(r'f1_ptagMatches_r(_\d+)?', name)
    if m:
        k = port_suffix(m.group(1))
        return 'f1_entry_addr_reg[%d][%d]' % (k // N_ENTRIES, k % N_ENTRIES)
    m = re.fullmatch(r'f1_tagMismatchVec_(\d)_r(_\d+)?', name)
    if m:
        p, k = int(m.group(1)), port_suffix(m.group(2))
        field = 'f1_vtag_match' if k % 2 == 0 else 'f1_valid_mask'
        return '%s_reg[%d][%d]' % (field, p, k // 2)
    return None


ID_RESP_LAYOUT = [('mid', 7), ('sid', 4), ('is2lq', 1), ('nc', 1)]   # id_resp_t 高位在前


class Golden:
    def __init__(self):
        self.src = (GOLDEN / (TOP + '.sv')).read_text()
        m = re.search(r'^module %s\(\n(.*?)\n\);\n' % TOP, self.src, re.S | re.M)
        if not m:
            raise SystemExit('golden %s.sv 里找不到 module 端口表' % TOP)
        self.port_text = m.group(1)
        self.ports = []
        for ln in self.port_text.split('\n'):
            mm = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?\s*$', ln)
            if not mm:
                raise SystemExit('解析不了端口行 %r' % ln)
            w = int(mm.group(2)) + 1 if mm.group(2) else 1
            self.ports.append((mm.group(1), w, mm.group(3)))
        self.regs = []
        for mm in re.finditer(r'^\s+reg\s+(?:\[(\d+):0\]\s+)?(\w+);', self.src, re.M):
            w = int(mm.group(1)) + 1 if mm.group(1) else 1
            self.regs.append((mm.group(2), w))
        # 核内字段宽度核对：entries_0_* 的宽度就是 SoA 数组元素宽度
        self.nbits = sum(w for _, w in self.regs)


def core_expr(port):
    for pat, rep in PORT_RULES:
        if re.fullmatch(pat, port):
            return re.sub('^' + pat + '$', rep, port)
    raise SystemExit('端口 %s 没有映射规则' % port)


def wrapper(g):
    L = []
    A = L.append
    A('// BEGIN GENERATED(uncache_wrapper)')
    A('// wrapper：端口与 golden Uncache 逐位同名同序；只做扁平端口 ↔ 核 struct/数组的对位。')
    A('// 由 scripts/gen_uncache.py 生成，勿手改。')
    A('module %s' % TOP)
    A('  import uncache_pkg::*;')
    A('(')
    A(g.port_text)
    A(');')
    A('  // ---- 核侧的 struct / 数组线')
    for n, t in STRUCT_PORTS.items():
        A('  %s %s;' % (t, n))
    for n, t in ARRAY_PORTS.items():
        A('  %s %s;' % (t, n))
    A('')
    A('  // ---- 输入：golden 扁平端口 → 核')
    for d, w, p in g.ports:
        e = core_expr(p)
        if d == 'input' and not re.fullmatch(r'\w+', e):
            A('  assign %s = %s;' % (e, p))
    A('')
    A('  // ---- 核例化')
    A('  xs_Uncache_core u_core (')
    conns = []
    scalar = []
    seen = set()
    for d, w, p in g.ports:
        e = core_expr(p)
        base = re.match(r'\w+', e).group(0)
        if base in seen:
            continue
        seen.add(base)
        if re.fullmatch(r'\w+', e):
            conns.append('    .%-20s (%s)' % (base, p))
        else:
            conns.append('    .%-20s (%s)' % (base, base))
    A(',\n'.join(conns))
    A('  );')
    A('')
    A('  // ---- 输出：核 → golden 扁平端口')
    for d, w, p in g.ports:
        e = core_expr(p)
        if d == 'output' and not re.fullmatch(r'\w+', e):
            A('  assign %s = %s;' % (p, e))
    A('endmodule')
    A('// END GENERATED')
    return '\n'.join(L)


def pin_pairs(g):
    """[(golden 位名, impl 位名)] 全部按位展开。"""
    pairs = []
    missing = []
    for name, w in g.regs:
        impl = reg_rule(name)
        if impl is None:
            missing.append(name)
            continue
        m = re.fullmatch(r'id_resp_q_reg\[(\w+)\]', impl)
        if m:
            # packed struct 寄存器：FM 看到的是一个 13 位向量 id_resp_q_reg[12:0]
            off = 0
            lsb = {}
            for f, fw in reversed(ID_RESP_LAYOUT):
                lsb[f] = off
                off += fw
            f = m.group(1)
            for b in range(w):
                pairs.append(('%s_reg%s' % (name, '[%d]' % b if w > 1 else ''),
                              'id_resp_q_reg[%d]' % (lsb[f] + b)))
            continue
        if w == 1:
            pairs.append(('%s_reg' % name, impl))
        else:
            for b in range(w):
                pairs.append(('%s_reg[%d]' % (name, b), '%s[%d]' % (impl, b)))
    if missing:
        raise SystemExit('golden 寄存器没有钉点规则：%s' % missing[:10])
    imps = [i for _, i in pairs]
    if len(set(imps)) != len(imps):
        raise SystemExit('钉点 impl 侧有重复（不是一一对应）')
    if len(pairs) != g.nbits:
        raise SystemExit('钉点数 %d != golden 寄存器位数 %d' % (len(pairs), g.nbits))
    return pairs


def tcl_esc(s):
    return s.replace('[', '\\[').replace(']', '\\]')


def pins_tcl(g):
    pairs = pin_pairs(g)
    L = []
    A = L.append
    A('# Uncache FM「匹配前」钉点 —— 自动生成：scripts/gen_uncache.py（勿手改）')
    A('#')
    A('# 只消 golden 扁平寄存器名（entries_<i>_<字段> / f1_ptagMatches_r_<k> ...）与重写核')
    A('# SoA 数组寄存器名（u_core/entry_<字段>_reg[i] ...）之间的命名鸿沟。')
    A('# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。')
    A('# fail-closed：逐条数 set_user_match 的返回值；有拒绝或总数不等于字面整数')
    A('# （= golden 顶层寄存器位数）就 error。进 fm.log 的输出一律 ASCII。')
    A('set ::UNCACHE_PIN_EXPECT %d' % len(pairs))
    A('set ::UNCACHE_PIN_OK 0')
    A('set ::UNCACHE_PIN_BAD 0')
    A('proc uncache_pin {r i} {')
    A('  if {[set_user_match "r:/WORK/Uncache/$r" "i:/WORK/Uncache/u_core/$i"]} {')
    A('    incr ::UNCACHE_PIN_OK')
    A('  } else {')
    A('    incr ::UNCACHE_PIN_BAD')
    A('    if {$::UNCACHE_PIN_BAD <= 10} { puts "UNCACHE_PIN_FAIL: $r <-> $i" }')
    A('  }')
    A('}')
    A('puts "UNCACHE_PIN_BEGIN Uncache expect=$::UNCACHE_PIN_EXPECT"')
    for r, i in pairs:
        A('uncache_pin %s %s' % (tcl_esc(r), tcl_esc(i)))
    A('puts "UNCACHE_PIN_END Uncache ok=$::UNCACHE_PIN_OK bad=$::UNCACHE_PIN_BAD"')
    A('if {$::UNCACHE_PIN_BAD != 0} { error "UNCACHE_PIN_MISS=$::UNCACHE_PIN_BAD" }')
    A('if {$::UNCACHE_PIN_OK != %d} { error "UNCACHE_PIN_COUNT=$::UNCACHE_PIN_OK expect=%d" }'
      % (len(pairs), len(pairs)))
    return '\n'.join(L) + '\n'


def tb_dut(g):
    L = []
    A = L.append
    A('  // BEGIN GENERATED(uncache_tb_dut)')
    A('  // 由 scripts/gen_uncache.py 生成，勿手改：端口线声明、双例化、逐端口比较。')
    for d, w, p in g.ports:
        decl = 'logic [%d:0]' % (w - 1) if w > 1 else 'logic'
        if p in ('clock', 'reset'):
            continue
        if d == 'input':
            A('  %-14s %s;' % (decl, p))
        else:
            A('  %-14s g_%s, i_%s;' % (decl, p, p))
    for side, mod in (('g', TOP), ('i', TOP + '_xs')):
        A('  %s u_%s (' % (mod, side))
        c = []
        for d, w, p in g.ports:
            if p == 'clock':
                c.append('    .clock (clk)')
            elif p == 'reset':
                c.append('    .reset (rst)')
            elif d == 'input':
                c.append('    .%s (%s)' % (p, p))
            else:
                c.append('    .%s (%s_%s)' % (p, side, p))
        A(',\n'.join(c))
        A('  );')
    A('  task automatic compare_outputs();')
    for d, w, p in g.ports:
        if d == 'output':
            A('    `CMP(g_%s, i_%s, "%s")' % (p, p, p))
    A('  endtask')
    A('  // END GENERATED')
    return '\n'.join(L)


def splice(text, tag, body):
    pat = re.compile(r'^[ \t]*// BEGIN GENERATED\(%s\)\n.*?^[ \t]*// END GENERATED[^\n]*' % re.escape(tag),
                     re.S | re.M)
    if len(pat.findall(text)) != 1:
        raise SystemExit('找不到（或多于一个）GENERATED(%s) 区' % tag)
    return pat.sub(lambda _: body, text)


def outputs():
    g = Golden()
    out = {}
    out[RTL] = splice(RTL.read_text(), 'uncache_wrapper', wrapper(g))
    out[UT_DIR / 'fm_pins_pre.tcl'] = pins_tcl(g)
    tbp = UT_DIR / 'tb.sv'
    if tbp.exists():
        out[tbp] = splice(tbp.read_text(), 'uncache_tb_dut', tb_dut(g))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--check', action='store_true', help='只比对不写，有漂移 rc=1')
    args = ap.parse_args()
    out = outputs()
    drift = []
    for path, text in out.items():
        cur = path.read_text() if path.exists() else None
        if cur != text:
            drift.append(path)
            if not args.check:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(text)
    rel = [str(p.relative_to(REPO)) for p in drift]
    if args.check:
        if drift:
            print('gen_uncache: DRIFT %s' % rel)
            return 1
        print('gen_uncache: OK（%d 个文件与生成结果一致）' % len(out))
        return 0
    print('gen_uncache: 更新 %s' % rel if drift else 'gen_uncache: 全部已是最新')
    return 0


if __name__ == '__main__':
    sys.exit(main())
