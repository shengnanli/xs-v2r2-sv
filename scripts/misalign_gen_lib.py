# -*- coding: utf-8 -*-
"""misalign_gen_lib.py —— Load/StoreMisalignBuffer 两个生成器共用的机械派生引擎（本文件不单独运行）。

调用者（scripts/gen_lmisalign.py / scripts/gen_smisalign.py）只给一份 Target 配置：
  golden 模块名、接口组（端口前缀 → struct）、标量口映射、整包寄存器组、导航锚点、tb 模板。
引擎负责（全部 fail-closed）：
  1. 读 golden 端口表 / reg 表；每个端口恰好归属一个接口组或一个标量口，多一个少一个都拒绝；
  2. 生成接口 struct（uop_t = 各组 uop_* 字段并集；exceptionVec_N 等收成向量）；
  3. 生成整包寄存器（逐字段同名声明 + 装载 + 读回成 struct），位宽逐个核对；
  4. 生成 golden 同名 wrapper（端口表逐字照抄，扁平端口 <-> 核的 struct 拆装）；
  5. 核对 golden 寄存器全集 == 生成的整包寄存器 ∪ 核手写区同名声明（逐名、逐位宽）；
  6. 刷新文件导航；调用 UT 目录的 tb_template.gen_tb 产出 tb.sv；--check 模式只比不写。
"""
import collections
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN_DIR = pathlib.Path(os.environ.get('G1_CANONICAL', '/home/eda/xs-env/G1-canonical')) / 'golden-rtl'
PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$')
REG_RE = re.compile(r'^\s*reg\s+(?:\[(\d+):0\]\s+)?(\w+)\s*;')


class Struct:
    def __init__(self, t, name, doc):
        self.t, self.name, self.doc = t, name, doc
        self.members = collections.OrderedDict()   # name -> (width, arr_len or None, nested type or None)

    def split_field(self, f):
        m = re.fullmatch(r'(\w+?)_(\d+)', f)
        if m and m.group(1) in self.t.arrays:
            return m.group(1), int(m.group(2))
        return f, None

    def add(self, field, width):
        name, idx = self.split_field(field)
        if idx is not None:
            if width != 1:
                self.t.die('%s.%s 向量字段元素不是 1 位' % (self.name, field))
            self.members[name] = (1, self.t.arrays[name], None)
            return
        old = self.members.get(name)
        if old and old != (width, None, None):
            self.t.die('%s.%s 位宽不一致 %r vs %d' % (self.name, name, old, width))
        self.members[name] = (width, None, None)

    def add_nested(self, name, typ):
        self.members[name] = (0, None, typ)

    def member(self, field):
        name, idx = self.split_field(field)
        m = self.members.get(name)
        if not m or m[2]:
            return None
        if idx is not None:
            return '%s[%d]' % (name, idx), 1
        return name, m[0]

    def emit(self):
        out = ['  // %s' % self.doc, '  typedef struct packed {']
        for n, (w, arr, typ) in self.members.items():
            if typ:
                out.append('    %-16s %s;' % (typ, n))
            elif arr:
                out.append('    logic %-10s %s;' % ('[%d:0]' % (arr - 1), n))
            elif w == 1:
                out.append('    logic %-10s %s;' % ('', n))
            else:
                out.append('    logic %-10s %s;' % ('[%d:0]' % (w - 1), n))
        out.append('  } %s;' % self.name)
        return out


class Target:
    """cfg 字段：
      module, pkg, core, tag, rtl, tb, arrays
      groups:  [(前缀(可含 %d), struct 类型, 核端名(可含 %d), 方向, 说明, 个数表达式或 None, 个数)]
      scalars: OrderedDict golden 名 -> 核端名（可为 name[i]）
      vec_counts: {核端向量名: 个数表达式}
      uop_order: 组下标顺序（决定 uop_t 字段顺序）
      reg_structs: [(struct 类型, 寄存器前缀, 说明)] —— 字段取自 golden 同前缀寄存器（条目本体）
      pack_regs: [(前缀, struct 类型, 读回变量, 次态表达式, 有复位?, 使能 or None, 说明)]
      pack_exclude: 前缀撞上但核里手写的寄存器名
      nav: [(标签, 锚点正则)]
    """

    def __init__(self, cfg):
        self.__dict__.update(cfg)
        self.golden = GOLDEN_DIR / (self.module + '.sv')
        self.ports = self.golden_ports()
        self.regs = self.golden_regs()
        self.pw = {n: w for _, w, n in self.ports}
        self.cls = self.classify()
        self.build_structs()
        self.pack = self.pack_reg_members()
        self.pack_names = {r for lst in self.pack.values() for r, _, _ in lst}

    def die(self, msg):
        raise SystemExit('%s: ★拒绝生成★ %s' % (os.path.basename(self.tag), msg))

    # ---------------- golden ----------------
    def golden_ports(self):
        text = self.golden.read_text()
        m = re.search(r'^module %s\((.*?)\n\);' % self.module, text, re.S | re.M)
        if not m:
            self.die('golden 里找不到 module %s' % self.module)
        res = []
        for line in m.group(1).splitlines():
            if not line.strip():
                continue
            pm = PORT_RE.match(line)
            if not pm:
                self.die('不认识的端口行: %r' % line)
            w = int(pm.group(2)) + 1 if pm.group(2) else 1
            res.append((pm.group(1), w, pm.group(3)))
        return res

    def golden_regs(self):
        res = collections.OrderedDict()
        for line in self.golden.read_text().splitlines():
            m = REG_RE.match(line)
            if m:
                if m.group(2) in res:
                    self.die('golden 寄存器重名 %s' % m.group(2))
                res[m.group(2)] = int(m.group(1)) + 1 if m.group(1) else 1
        return res

    # ---------------- 端口分类 ----------------
    def classify(self):
        res = collections.OrderedDict()
        for d, w, n in self.ports:
            hits = []
            if n in self.scalars:
                hits.append(('scalar', self.scalars[n]))
            for gi, g in enumerate(self.groups):
                pre, gdir, cnt = g[0], g[3], g[6]
                if '%d' in pre:
                    for i in range(cnt):
                        p = pre % i
                        if n.startswith(p):
                            hits.append(('group', gi, i, n[len(p):]))
                elif n.startswith(pre):
                    hits.append(('group', gi, None, n[len(pre):]))
            if len(hits) != 1:
                self.die('端口 %s 命中 %d 个分类（必须恰好 1）: %r' % (n, len(hits), hits))
            if hits[0][0] == 'group' and self.groups[hits[0][1]][3] != d:
                self.die('端口 %s 方向 %s 与组方向不符' % (n, d))
            res[n] = hits[0]
        used = {h[1] for h in res.values() if h[0] == 'scalar'}
        if set(self.scalars.values()) - used:
            self.die('标量规则没命中任何端口: %r' % (set(self.scalars.values()) - used))
        return res

    # ---------------- struct ----------------
    def build_structs(self):
        uop = Struct(self, 'uop_t', 'DynInst（后端微操作）在本模块出现过的全部字段；'
                     '各接口只用其中一部分，其余在 wrapper 里补 0 / 丢弃')
        for gi in self.uop_order:
            for n, h in self.cls.items():
                if h[0] == 'group' and h[1] == gi and (h[2] in (None, 0)) and h[3].startswith('uop_'):
                    uop.add(h[3][4:], self.pw[n])
        self.uop = uop
        self.structs = [uop]
        self.by_type = {'uop_t': uop}
        self.gstruct = {}
        for gi, g in enumerate(self.groups):
            pre, typ, doc, cnt = g[0], g[1], g[4], g[6]
            s = Struct(self, typ, doc)
            fields = collections.OrderedDict()
            for n, h in self.cls.items():
                if h[0] == 'group' and h[1] == gi:
                    fields.setdefault(h[2], []).append((h[3], self.pw[n]))
            if '%d' in pre:
                ref = fields[0]
                for i in range(1, cnt):
                    if fields.get(i) != ref:
                        self.die('%s 第 %d 份字段表与第 0 份不一致' % (pre, i))
                flist = ref
            else:
                flist = fields[None]
            self.fill(s, flist)
            self.structs.append(s)
            self.gstruct[gi] = s
            self.by_type[typ] = s
        for typ, pre, doc in getattr(self, 'reg_structs', []):
            s = Struct(self, typ, doc)
            flist = [(r[len(pre):], w) for r, w in self.regs.items()
                     if r.startswith(pre) and r not in self.pack_exclude]
            self.fill(s, flist)
            self.structs.append(s)
            self.by_type[typ] = s

    def fill(self, s, flist):
        has_uop = False
        for f, w in flist:
            if f.startswith('uop_'):
                if not self.uop.member(f[4:]):
                    self.uop.add(f[4:], w)
                if not has_uop:
                    s.add_nested('uop', 'uop_t')
                    has_uop = True
            else:
                s.add(f, w)

    def field_expr(self, s, var, field):
        if field.startswith('uop_'):
            m = self.uop.member(field[4:])
            if not m:
                self.die('uop 字段 %s 不在 uop_t' % field)
            return '%s.uop.%s' % (var, m[0]), m[1]
        m = s.member(field)
        if not m:
            self.die('%s 里没有字段 %s' % (s.name, field))
        return '%s.%s' % (var, m[0]), m[1]

    def gen_types(self):
        out = []
        for s in self.structs:
            out += s.emit()
            out.append('')
        return out[:-1]

    # ---------------- 整包寄存器 ----------------
    def pack_reg_members(self):
        res = collections.OrderedDict()
        for pre, typ, _, _, _, _, _ in self.pack_regs:
            s = self.by_type[typ]
            lst = []
            for r, w in self.regs.items():
                if not r.startswith(pre) or r in self.pack_exclude:
                    continue
                e, ew = self.field_expr(s, '', r[len(pre):])
                if ew != w:
                    self.die('寄存器 %s 位宽 %d 与 struct 成员 %s 位宽 %d 不符' % (r, w, e, ew))
                lst.append((r, w, e))
            if not lst:
                self.die('前缀 %s 一个寄存器都没匹配到' % pre)
            res[pre] = lst
        return res

    @staticmethod
    def decl(w, name):
        return '  logic %-9s %s;' % ('' if w == 1 else '[%d:0]' % (w - 1), name)

    def gen_regs(self):
        out = []
        for pre, typ, rd, nxt, rst, en, doc in self.pack_regs:
            lst = self.pack[pre]
            out.append('  // ---- %s：golden 留下的 %d 个字段 ----' % (doc, len(lst)))
            for r, w, _ in lst:
                out.append(self.decl(w, r))
            if rst:
                out.append('  always_ff @(posedge clock or posedge reset) begin')
                out.append('    if (reset) begin')
                for r, w, _ in lst:
                    out.append('      %s <= %s;' % (r, "1'b0" if w == 1 else "'0"))
                out.append('    end else if (%s) begin' % en)
                for r, _, e in lst:
                    out.append('      %s <= %s%s;' % (r, nxt, e))
                out.append('    end')
                out.append('  end')
            elif en:
                out.append('  always_ff @(posedge clock) begin')
                out.append('    if (%s) begin' % en)
                for r, _, e in lst:
                    out.append('      %s <= %s%s;' % (r, nxt, e))
                out.append('    end')
                out.append('  end')
            else:
                out.append('  always_ff @(posedge clock) begin')
                for r, _, e in lst:
                    out.append('    %s <= %s%s;' % (r, nxt, e))
                out.append('  end')
            out.append('  always_comb begin')
            out.append('    %s = \'0;   // golden 没留的字段恒 0' % rd)
            for r, _, e in lst:
                out.append('    %s%s = %s;' % (rd, e, r))
            out.append('  end')
            out.append('')
        return out[:-1]

    # ---------------- wrapper ----------------
    def vec_bases(self):
        """核端向量标量（name[i]）按首次出现顺序 -> 个数表达式。"""
        res = collections.OrderedDict()
        for core in self.scalars.values():
            if '[' in core:
                b = core.split('[')[0]
                res.setdefault(b, self.vec_counts[b])
        return res

    def gen_wrapper(self):
        out = ['module %s' % self.module, '  import %s::*;' % self.pkg, '(']
        for k, (d, w, n) in enumerate(self.ports):
            rng = '' if w == 1 else '[%d:0]' % (w - 1)
            out.append('  %-6s %-8s %s%s' % (d, rng, n, ',' if k + 1 < len(self.ports) else ''))
        out.append(');')
        out.append('')
        out.append('  // 核端的 struct / 向量信号')
        for g in self.groups:
            pre, typ, core, cexpr = g[0], g[1], g[2], g[5]
            if '%d' in pre:
                out.append('  %-12s [%s-1:0] %s;' % (typ, cexpr, core.split('[')[0]))
            else:
                out.append('  %-12s %s;' % (typ, core))
        by_cnt = collections.OrderedDict()
        for b, c in self.vec_bases().items():
            by_cnt.setdefault(c, []).append(b)
        for c, bs in by_cnt.items():
            out.append('  logic [%s-1:0] %s;' % (c, ', '.join(bs)))
        out.append('')
        for gi, g in enumerate(self.groups):
            pre, typ, core, d, cnt = g[0], g[1], g[2], g[3], g[6]
            if d != 'input':
                continue
            idxs = range(cnt) if '%d' in pre else [None]
            for i in idxs:
                var = core % i if i is not None else core
                out.append('  always_comb begin')
                out.append('    %s = \'0;   // golden 没有端口的字段（上层恒 0 / 被 DCE）补 0' % var)
                for dd, w, n in self.ports:
                    h = self.cls[n]
                    if h[0] == 'group' and h[1] == gi and h[2] == i:
                        e, ew = self.field_expr(self.gstruct[gi], var, h[3])
                        if ew != w:
                            self.die('端口 %s 位宽 %d vs 成员 %s %d' % (n, w, e, ew))
                        out.append('    %s = %s;' % (e, n))
                out.append('  end')
        out.append('')
        for d0 in ('input', 'output'):
            for dd, w, n in self.ports:
                h = self.cls[n]
                if dd == d0 and h[0] == 'scalar' and '[' in h[1]:
                    out.append('  assign %s = %s;' % ((h[1], n) if d0 == 'input' else (n, h[1])))
        out.append('')
        for d, w, n in self.ports:
            h = self.cls[n]
            if h[0] == 'group' and self.groups[h[1]][3] == 'output':
                g = self.groups[h[1]]
                var = g[2] % h[2] if h[2] is not None else g[2]
                e, ew = self.field_expr(self.gstruct[h[1]], var, h[3])
                if ew != w:
                    self.die('端口 %s 位宽 %d vs 成员 %s %d' % (n, w, e, ew))
                out.append('  assign %s = %s;' % (n, e))
        out.append('')
        out.append('  %s u_core (' % self.core)
        conns = []
        for n, core in self.scalars.items():
            if '[' in core:
                continue
            conns.append('    .%s (%s)' % (core, n))
        for b in self.vec_bases():
            conns.append('    .%s (%s)' % (b, b))
        for g in self.groups:
            c = g[2].split('[')[0]
            conns.append('    .%s (%s)' % (c, c))
        out.append(',\n'.join(conns))
        out.append('  );')
        out.append('')
        out.append('endmodule')
        return out

    # ---------------- 替换 / 导航 / 全集核对 ----------------
    def replace_region(self, text, tag, lines):
        b = '// BEGIN GENERATED(%s) —— %s 生成，勿手改' % (tag, self.tag)
        e = '// END GENERATED(%s)' % tag
        pat = re.compile(r'([ \t]*)' + re.escape(b) + r'\n.*?' + re.escape(e), re.S)
        m = pat.search(text)
        if not m:
            self.die('找不到 GENERATED(%s) 标记' % tag)
        ind = m.group(1)
        body = '\n'.join(lines)
        return text[:m.start()] + ind + b + '\n' + (body + '\n' if lines else '') + ind + e + text[m.end():]

    def gen_nav(self, text):
        lines = text.split('\n')
        out = []
        for label, pat in self.nav:
            idx = [i for i, ln in enumerate(lines) if re.match(pat, ln)]
            if len(idx) != 1:
                self.die('导航锚点 %r 命中 %d 处（要求恰好 1 处）' % (pat, len(idx)))
            out.append('//   L%-5d %s' % (idx[0] + 1, label))
        return out

    def check_reg_universe(self, text):
        code = re.sub(r'// BEGIN GENERATED\(regs\).*?// END GENERATED\(regs\)', '', text, flags=re.S)
        code = re.sub(r'//[^\n]*', '', code)
        core = re.search(r'module %s(.*?)\nendmodule' % self.core, code, re.S)
        if not core:
            return ['找不到 %s' % self.core]
        hand = {}
        for m in re.finditer(r'^\s*(logic|state_e)\s*(?:\[(\d+):0\]\s*)?([\w,\s]+?);', core.group(1), re.M):
            w = 3 if m.group(1) == 'state_e' else (int(m.group(2)) + 1 if m.group(2) else 1)
            for nm in m.group(3).split(','):
                hand[nm.strip()] = w
        errs = []
        for rn, w in self.regs.items():
            if rn in self.pack_names:
                continue
            if rn not in hand:
                errs.append('golden 寄存器 %s 在核里没有同名声明' % rn)
            elif hand[rn] != w:
                errs.append('golden 寄存器 %s 位宽 %d，核里 %d' % (rn, w, hand[rn]))
        return errs

    def main(self, argv):
        check = '--check' in argv
        text = self.rtl.read_text()
        new = self.replace_region(text, 'types', self.gen_types())
        new = self.replace_region(new, 'regs', self.gen_regs())
        new = self.replace_region(new, 'wrapper', self.gen_wrapper())
        new = self.replace_region(new, 'nav', self.gen_nav(new))
        new = self.replace_region(new, 'nav', self.gen_nav(new))
        errs = self.check_reg_universe(new)
        if errs:
            for e in errs[:40]:
                print('  ' + e)
            self.die('%d 处寄存器全集不符' % len(errs))
        sys.path.insert(0, str(self.tb.parent))
        import importlib.util
        spec = importlib.util.spec_from_file_location('tb_template_' + self.module,
                                                      str(self.tb.parent / 'tb_template.py'))
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        tb = mod.gen_tb(self.ports, self.cls)
        outputs = [(self.rtl, new), (self.tb, tb)]
        name = os.path.basename(self.tag)[:-3]
        if check:
            bad = [p for p, t in outputs if not p.exists() or p.read_text() != t]
            if bad:
                print('%s --check: 以下产物与生成器不一致：' % name)
                for p in bad:
                    print('  ' + str(p.relative_to(REPO)))
                return 1
            print('%s --check: %d 个产物与生成器一致' % (name, len(outputs)))
            return 0
        for p, t in outputs:
            if not p.exists() or p.read_text() != t:
                p.write_text(t)
                print('写入 ' + str(p.relative_to(REPO)))
        return 0
