#!/usr/bin/env python3
"""mc_memory_registry.py —— Memory Compiler（MC）存储契约登记表的读取与逐条复算（codex 0222）。

# 这是什么

用户决定：RAM 存储层（firtool `ram_*` 行为模型、`sram_array_*` 外壳、`array_N` 外壳、`array_*_ext`
厂商叶子）**不重写**，将来由存储编译器生成的 Memory 替换。codex 0222 把这一层放进证明链的办法是
**精确外部存储契约**：父证明在「同一份已登记的存储模型」下证明周边可读 RTL 与 golden 等价。

两种合法形态（registry 第 2 列）：

  MC_MEMORY_MODEL      ref / impl 两侧读取**同一份** G1 行为模型（白盒，FM 照常比较周边）。
  MC_MEMORY_BLACKBOX   两侧对称黑盒的宏边界（厂商叶子 array_*_ext；FM 不读其内部）。
                       与 verif/vendor_boundary.tsv 同名行的 sha256 / 端口签名逐字核对。

# 不许做的事（0222 §1/§2）

* **不按名字放行**：不按 `ram_` / `sram_array_` / `array_` 前后缀或任何正则推断"这是存储"。
  只认 verif/mc_memory_registry.tsv 里逐 design 列名的行；表外一律 `mc_not_registered`。
* **不按 MANIFEST 相等放行**：G1 字节对上只是必要条件。每一行的 depth / width / mask 粒度 /
  端口形态 / 读延迟 / 写沿 / enable-wmode-mask 语义 / 读写冲突语义 / MBIST 连接 / 子模块，
  都由本模块从 G1 源**重新推导**并与登记值逐字段比较；推导不出（模块体不是本表认得的
  存储模板，例如夹带了任何别的逻辑或别的子模块）就是 `mc_template_mismatch`，fail-closed。
* **外壳的子模块只能是已登记 MC 层**：`sram_array_*` 的唯一子实例必须是已登记的 `array_N`，
  `array_N` 的唯一子实例必须是已登记的 MC_MEMORY_BLACKBOX；否则 `mc_child_not_registered`。

# 推导的模板（任何偏离 = 不认）

  firtool ram（1R1W）:   reg [W-1:0] Memory[0:D-1];
                         always @(posedge W0_clk) if (W0_en & 1'h1) Memory[W0_addr] <= W0_data;
                         assign R0_data = R0_en ? Memory[R0_addr] : W'bx;
                         （外加 firtool 固定的 `ifdef ENABLE_INITIAL_MEM_ 仿真初值块，综合不可见）
  sram_array（1RW 外壳）: 唯一子实例 array_K；wmode 送 `RW0_wmode & RW0_en`（无掩码）或
                         `RW0_en & RW0_wmode & (|RW0_wmask)` 且逐位 mask_i = RW0_wmode & RW0_wmask[i]；
                         mbist_dft_ram_bypass / mbist_dft_ram_bp_clken 只声明、不连接。
  array_N（直连外壳）:   唯一子实例 array_N_ext，每个端口同名直连。
  array_*_ext（叶子）:   reg [W-1:0] ram [D-1:0]；读地址寄存一拍（读延迟 1）；
                         写 = posedge 且 en && wmode（有掩码时按粒度 G 逐段写）；读使能 = en && !wmode。

用法:
    python3 scripts/mc_memory_registry.py --check          # 逐行复算整张表（gate）
    python3 scripts/mc_memory_registry.py --derive <design> # 打印某 design 的推导结果（登记时用）
    import mc_memory_registry as MC; MC.check_entry('ram_16x25')
"""
import hashlib
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
REGISTRY = REPO / 'verif' / 'mc_memory_registry.tsv'
VENDOR_BOUNDARY = REPO / 'verif' / 'vendor_boundary.tsv'
DEFAULT_G1 = os.environ.get('G1_CANONICAL') or '/home/eda/xs-env/G1-canonical'

CLASSES = ('MC_MEMORY_MODEL', 'MC_MEMORY_BLACKBOX')
EXTERNAL_DEPENDENCY = 'MC_MEMORY_CONTRACT'
COLUMNS = ['design', 'class', 'g1_file', 'g1_sha256', 'port_signature', 'depth', 'width',
           'mask_gran', 'ports', 'read', 'read_latency', 'write_edge', 'enable_semantics',
           'collision', 'mbist', 'children', 'audit']


# ---------------------------------------------------------------------------
# 读表
# ---------------------------------------------------------------------------
def load_registry(path=None):
    """{design: row-dict}。格式错 / 重复行 / 未知类别直接抛 ValueError（表本身坏了不能 fail-open）。"""
    p = pathlib.Path(path or REGISTRY)
    return parse_registry_text(p.read_text(), p.name)


def parse_registry_text(text, name='mc_memory_registry.tsv'):
    """同 load_registry，但输入是文本（证书校验从**父 commit** 的 git show 读表，不读工作树）。"""
    class _P:                                              # 只为报错信息里的文件名
        pass
    p = _P()
    p.name = name
    rows = {}
    for n, ln in enumerate(text.splitlines(), 1):
        if not ln.strip() or ln.startswith('#'):
            continue
        c = ln.split('\t')
        if len(c) != len(COLUMNS):
            raise ValueError('%s:%d 列数 %d != %d' % (p.name, n, len(c), len(COLUMNS)))
        r = dict(zip(COLUMNS, c))
        if r['class'] not in CLASSES:
            raise ValueError('%s:%d 未知类别 %r' % (p.name, n, r['class']))
        if r['design'] in rows:
            raise ValueError('%s:%d 重复登记 %s' % (p.name, n, r['design']))
        rows[r['design']] = r
    return rows


# ---------------------------------------------------------------------------
# 从 G1 源推导（模板匹配；不认就返回 None + 原因）
# ---------------------------------------------------------------------------
def _strip(text):
    """去注释、去 firtool 宏头（module 之前的全部内容）、去 ENABLE_INITIAL_MEM_ / RANDOMIZE 仿真块。"""
    i = text.find('\nmodule ')
    body = text[i + 1:] if i >= 0 else text
    body = re.sub(r'`ifdef ENABLE_INITIAL_MEM_.*?`endif // ENABLE_INITIAL_MEM_', '', body, flags=re.S)
    body = re.sub(r'//[^\n]*', '', body)
    return body


def _norm(s):
    return re.sub(r'\s+', ' ', s).strip()


def _ports(body):
    m = re.match(r'\s*module\s+(\w+)\s*\((.*?)\);', body, re.S)
    if not m:
        return None, None, None
    ports = []
    for d in m.group(2).split(','):
        d = _norm(d)
        if not d:
            continue
        pm = re.fullmatch(r'(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)', d)
        if not pm:
            return m.group(1), None, None
        ports.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return m.group(1), ports, body[m.end():]


def port_signature(ports):
    return ';'.join('%s %s%s' % (d, ('[%d:0] ' % (w - 1)) if w > 1 else '', n) for d, w, n in ports)


def _ext_ports(text):
    """厂商 .v：端口每行 `input [8:0] RW0_addr,` 形式。"""
    m = re.search(r'module\s+(\w+)\s*\((.*?)\);', text, re.S)
    if not m:
        return None, None
    ports = []
    for d in m.group(2).split(','):
        d = _norm(d)
        if not d:
            continue
        pm = re.fullmatch(r'(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)', d)
        if not pm:
            return m.group(1), None
        ports.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return m.group(1), ports


def _inst(rest):
    """唯一子实例（模块名, 实例名, [(port, expr)]）；不是恰好一个实例 / 有别的语句就返回 None。"""
    rest = _norm(rest)
    m = re.fullmatch(r'(?P<pre>.*?)(?P<mod>\w+) (?P<inst>\w+) \( (?P<conns>\..*?) \); endmodule', rest)
    if not m:
        return None
    conns = []
    for c in re.split(r', (?=\.)', m.group('conns')):
        cm = re.fullmatch(r'\.(\w+) ?\((.*)\)', c.strip())
        if not cm:
            return None
        conns.append((cm.group(1), _norm(cm.group(2))))
    return m.group('pre').strip(), m.group('mod'), m.group('inst'), conns


def derive(design, g1_root=None):
    """返回 (facts-dict, None) 或 (None, 原因串)。facts 的键与 COLUMNS 的语义列同名。"""
    g = pathlib.Path(g1_root or DEFAULT_G1) / 'golden-rtl'
    sv, v = g / (design + '.sv'), g / (design + '.v')
    f = sv if sv.is_file() else (v if v.is_file() else None)
    if f is None:
        return None, 'mc_g1_file_missing:%s' % design
    raw = f.read_bytes()
    text = raw.decode('utf-8', 'replace')
    facts = {'g1_file': f.name, 'g1_sha256': hashlib.sha256(raw).hexdigest()}

    if f.suffix == '.v':                                   # 厂商叶子
        name, ports = _ext_ports(text)
        if name != design or not ports:
            return None, 'mc_template_mismatch:%s:ext_ports' % design
        facts['port_signature'] = port_signature(ports)
        mr = re.search(r'reg \[(\d+):0\] ram \[(\d+):0\];', text)
        if not mr or 'reg_RW0_addr <= RW0_addr' not in text \
                or 'reg_RW0_ren <= RW0_en && !RW0_wmode' not in text \
                or 'assign RW0_rdata = ram[reg_RW0_addr];' not in text \
                or 'if (RW0_en && RW0_wmode)' not in text:
            return None, 'mc_template_mismatch:%s:ext_body' % design
        w, d = int(mr.group(1)) + 1, int(mr.group(2)) + 1
        lm = re.search(r'if \(RW0_en && RW0_wmode\) begin for \(i=0;i<(\d+);i=i\+1\) begin '
                       r'(if \(RW0_wmask\[i\]\) begin )?ram\[RW0_addr\]\[i\*(\d+) \+: (\d+)\] <= '
                       r'RW0_wdata\[i\*(\d+) \+: (\d+)\];', _norm(text))
        has_mask = any(n == 'RW0_wmask' for _, _, n in ports)
        bm = re.search(r'if \(RW0_en && RW0_wmode\) begin ram\[RW0_addr\] <= \(RW0_wmask & RW0_wdata\) '
                       r'\| \(~RW0_wmask & ram\[RW0_addr\]\); end', _norm(text))
        pwd = {n: wd for _, wd, n in ports}
        if bm and has_mask and pwd.get('RW0_wmask') == pwd.get('RW0_wdata') == int(mr.group(1)) + 1:
            lm = None                                    # 逐位掩码形态：粒度 1
            n_seg, g_w, gm = int(mr.group(1)) + 1, 1, True
        elif not lm or len({lm.group(k) for k in (3, 4, 5, 6)}) != 1 or bool(lm.group(2)) != has_mask:
            return None, 'mc_template_mismatch:%s:ext_write' % design
        else:
            n_seg, g_w = int(lm.group(1)), int(lm.group(3))
            gm = lm if has_mask else None
        if n_seg * g_w != int(mr.group(1)) + 1:
            return None, 'mc_template_mismatch:%s:ext_write_width' % design
        facts.update(depth=str(d), width=str(w), mask_gran=str(g_w) if gm else '-',
                     ports='1RW', read='sync', read_latency='1', write_edge='posedge RW0_clk',
                     enable_semantics='write=en&&wmode' + ('&&wmask[i]' if gm else '')
                                      + ';ren=en&&!wmode',
                     collision='write_cycle_no_read;rdata=ram[last_read_addr]',
                     mbist='-', children='-')
        return facts, None

    body = _strip(text)
    name, ports, rest = _ports(body)
    if name != design or ports is None:
        return None, 'mc_template_mismatch:%s:ports' % design
    facts['port_signature'] = port_signature(ports)
    pn = [p[2] for p in ports]
    pw = {p[2]: p[1] for p in ports}

    # --- firtool 1R1W 行为模型 ---------------------------------------------
    if pn == ['R0_addr', 'R0_en', 'R0_clk', 'R0_data', 'W0_addr', 'W0_en', 'W0_clk', 'W0_data']:
        w, a = pw['R0_data'], pw['R0_addr']
        mm = re.fullmatch(r'reg \[(\d+):0\] Memory\[0:(\d+)\]; '
                          r'always @\(posedge W0_clk\) begin if \(W0_en & 1\'h1\) '
                          r'Memory\[W0_addr\] <= W0_data; end '
                          r'assign R0_data = R0_en \? Memory\[R0_addr\] : (\d+)\'bx; endmodule',
                          _norm(rest))
        if not mm or int(mm.group(1)) + 1 != w or int(mm.group(3)) != w \
                or pw['W0_data'] != w or pw['W0_addr'] != a:
            return None, 'mc_template_mismatch:%s:ram_body' % design
        d = int(mm.group(2)) + 1
        if (1 << a) < d:
            return None, 'mc_template_mismatch:%s:addr_width' % design
        facts.update(depth=str(d), width=str(w), mask_gran='-', ports='1R1W',
                     read='async', read_latency='0', write_edge='posedge W0_clk',
                     enable_semantics='write=W0_en;R0_en=0->rdata=X',
                     collision='same_cycle_read_returns_old_data',
                     mbist='-', children='-')
        return facts, None

    ins = _inst(rest)
    if ins is None:
        return None, 'mc_template_mismatch:%s:not_single_instance' % design
    pre, mod, inst, conns = ins
    cd = dict(conns)

    # --- array_N 直连外壳 ----------------------------------------------------
    if inst == mod and mod == design + '_ext':
        if pre or sorted(cd) != sorted(pn) or any(cd[p] != p for p in pn):
            return None, 'mc_template_mismatch:%s:passthrough' % design
        facts.update(depth='-', width=str(pw['RW0_rdata']),
                     mask_gran='-', ports='1RW', read='child', read_latency='child',
                     write_edge='child', enable_semantics='passthrough',
                     collision='child', mbist='-', children=mod)
        return facts, None

    # --- sram_array 1RW 外壳 -------------------------------------------------
    if inst == 'array' and pn[:2] == ['mbist_dft_ram_bypass', 'mbist_dft_ram_bp_clken']:
        if re.search(r'\bmbist_dft_ram_(bypass|bp_clken)\b', rest):
            return None, 'mc_template_mismatch:%s:mbist_connected' % design
        m_bits = pw.get('RW0_wmask', 0)
        if m_bits:
            want_pre = ' '.join('wire array_RW0_rdata_MPORT_wmask_%d;' % i for i in reversed(range(m_bits)))
            want_pre += ' ' + ' '.join('assign array_RW0_rdata_MPORT_wmask_%d = RW0_wmode & RW0_wmask[%d];'
                                       % (i, i) for i in range(m_bits))
            want_wmode = 'RW0_en & RW0_wmode & (|RW0_wmask)'
            want_mask = '{' + ', '.join('array_RW0_rdata_MPORT_wmask_%d' % i
                                        for i in reversed(range(m_bits))) + '}'
            ok = (_norm(pre) == _norm(want_pre) and cd.get('RW0_wmode') == want_wmode
                  and cd.get('RW0_wmask', '').replace(' ', '') == want_mask.replace(' ', ''))
            sem = 'wmode=en&wmode&|wmask;mask_i=wmode&wmask[i]'
        else:
            ok = (pre == '' and cd.get('RW0_wmode') == 'RW0_wmode & RW0_en' and 'RW0_wmask' not in cd)
            sem = 'wmode=wmode&en'
        same = [p for p in ('RW0_addr', 'RW0_en', 'RW0_clk', 'RW0_wdata', 'RW0_rdata')]
        if not ok or any(cd.get(p) != p for p in same) or \
                set(cd) != set(same + ['RW0_wmode'] + (['RW0_wmask'] if m_bits else [])):
            return None, 'mc_template_mismatch:%s:sram_array_body' % design
        w = pw['RW0_rdata']
        facts.update(depth=str(1 << pw['RW0_addr']), width=str(w),
                     mask_gran=str(w // m_bits) if m_bits else '-', ports='1RW',
                     read='child', read_latency='child', write_edge='child',
                     enable_semantics=sem, collision='child',
                     mbist='bypass,bp_clken:unconnected', children=mod)
        return facts, None

    return None, 'mc_template_mismatch:%s:unknown_shape' % design


# ---------------------------------------------------------------------------
# 逐条复算
# ---------------------------------------------------------------------------
def _vendor_row(design, vendor_text=None):
    if vendor_text is None:
        if not VENDOR_BOUNDARY.is_file():
            return None
        vendor_text = VENDOR_BOUNDARY.read_text()
    for ln in vendor_text.splitlines():
        c = ln.split('\t')
        if c and c[0] == design and not ln.startswith('#'):
            return c
    return None


def check_entry(design, reg=None, g1_root=None, _depth=0, vendor_text=None):
    """True 或失败原因串。design 必须在表里，且表里每一列都等于从 G1 重推的值；子模块递归同验。"""
    if _depth > 4:
        return 'mc_chain_too_deep:%s' % design
    reg = reg if reg is not None else load_registry()
    row = reg.get(design)
    if row is None:
        return 'mc_not_registered:%s' % design
    facts, err = derive(design, g1_root=g1_root)
    if err:
        return err
    for k, v in facts.items():
        if row.get(k) != v:
            return 'mc_field_mismatch:%s:%s:registry=%r,derived=%r' % (design, k, row.get(k), v)
    if row['class'] == 'MC_MEMORY_BLACKBOX':
        if not facts['g1_file'].endswith('.v'):
            return 'mc_class_mismatch:%s:blackbox_must_be_vendor_leaf' % design
        vb = _vendor_row(design, vendor_text)
        if not vb or len(vb) < 7 or vb[4] != facts['g1_sha256'] or vb[6] != facts['port_signature']:
            return 'mc_vendor_boundary_mismatch:%s' % design
    else:
        if facts['g1_file'].endswith('.v'):
            return 'mc_class_mismatch:%s:vendor_leaf_must_be_blackbox' % design
    if row['children'] != '-':
        for ch in row['children'].split(','):
            r = check_entry(ch, reg=reg, g1_root=g1_root, _depth=_depth + 1, vendor_text=vendor_text)
            if r is not True:
                return 'mc_child_not_registered:%s->%s' % (design, r)
        # 外壳的子：sram_array → MODEL（array_N）；array_N → BLACKBOX（ext）
        kinds = {reg[ch]['class'] for ch in row['children'].split(',')}
        want = 'MC_MEMORY_BLACKBOX' if facts['enable_semantics'] == 'passthrough' else 'MC_MEMORY_MODEL'
        if kinds != {want}:
            return 'mc_child_class_mismatch:%s:%s' % (design, sorted(kinds))
    return True


def check_golden_entry(entry, reg=None, g1_root=None, vendor_text=None):
    """证书 impl 闭包里的一条 golden 条目（{path, kind, sha256}）是否精确命中 MC registry。
    返回 (True, class) / (False, 原因)。这里的 sha 必须与登记、与 G1 当前字节三者相等。"""
    base = os.path.basename(entry.get('path') or '')
    design = re.sub(r'\.(sv|v)$', '', base)
    reg = reg if reg is not None else load_registry()
    r = check_entry(design, reg=reg, g1_root=g1_root, vendor_text=vendor_text)
    if r is not True:
        return False, r
    if entry.get('sha256') != reg[design]['g1_sha256']:
        return False, 'mc_closure_sha_mismatch:%s' % design
    return True, reg[design]['class']


def mc_objects_in_closure(entries, reg=None):
    """闭包条目里 kind=='golden' 且**名字在登记表里**的 design 列表（只做成员关系；字节/语义由
    check_golden_entry 复算）。receipt / certificate 用它填 external_dependency。"""
    reg = reg if reg is not None else load_registry()
    out = []
    for e in entries or []:
        if e.get('kind') != 'golden':
            continue
        d = re.sub(r'\.(sv|v)$', '', os.path.basename(e.get('path') or ''))
        if d in reg and d not in out:
            out.append(d)
    return out


def main(argv):
    if '--derive' in argv:
        d = argv[argv.index('--derive') + 1]
        facts, err = derive(d)
        if err:
            print(err)
            return 1
        print('\t'.join([d, '?'] + [facts.get(k, '?') for k in COLUMNS[2:-1]] + ['?']))
        return 0
    reg = load_registry()
    bad = 0
    for d in sorted(reg):
        r = check_entry(d, reg=reg)
        print('%-48s %-20s %s' % (d, reg[d]['class'], 'OK' if r is True else r))
        bad += r is not True
    print('mc_memory_registry: %d 行，%s' % (len(reg), '全部复算一致' if not bad else '%d 行不符' % bad))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
