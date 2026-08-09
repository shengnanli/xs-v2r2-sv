#!/usr/bin/env python3
"""
rob_cone_slicer.py — pre-FM cone-DCE derivative generator for the Rob partition
FM proof (codex 0100 Lane 2, "Rob-cone-DCE").

WHAT IT IS
----------
A deterministic, self-written STRUCTURAL cone-slicer that operates on a *flat*
firtool-emitted SystemVerilog module (one top module, scalar nets, `wire NAME =
EXPR;` / `assign NAME = EXPR;` combinational drivers, `reg NAME;` declarations
driven inside `always @(posedge ...)` blocks, plus leaf-module instances).

Given a partition's OUTPUT PORT LIST (taken verbatim from the union-verified
route-B classifier — NOT re-invented here), it computes the exact TRANSITIVE
FANIN CONE of those outputs down to primary inputs / register boundaries and
emits a reduced copy of the module that keeps ONLY the declarations, continuous
assignments, procedural register writes, and instance connections that lie in
that cone. Everything provably off-cone (no path to any kept output) is
PHYSICALLY REMOVED from the source before FM ever reads it.

SOUNDNESS
---------
* The slice is a pure fanin-cone slice: a statement/decl is kept iff its LHS net
  (or, for instances, any of the instance's output pins) is in the closure. By
  construction, removed logic has NO path to any kept output, so every kept
  output's behaviour is bit-identical to the un-sliced module.
* Registers are cone-transparent: a reg in the cone is kept, AND the cone
  continues through the RHS of its <= assignments (so its next-state fanin is
  preserved to the input/reg boundary).
* Over-removal is NEVER silent: if the analysis wrongly drops a needed driver,
  the reduced design either fails to elaborate (undriven net feeding a kept
  output) or FM reports a mismatch. It cannot produce a false PASS.
* No dont_verify, no assumptions, no constant-forcing, no blackbox added. The
  same 7 official-PASS child leaves remain both-side-elaborated leaf instances.

DETERMINISM
-----------
Pure function of (input source file bytes, partition name, output list bytes).
Two clean runs are byte-identical (no dict-order / no timestamps in output).

USAGE
  rob_cone_slicer.py --src <flat.sv> --module Rob \
      --outputs <output_list.txt> --keep-name <NewModuleName> \
      --out <reduced.sv> [--report <report.json>]
"""
import argparse, hashlib, json, os, re, sys
from collections import OrderedDict
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from always_tree import AlwaysBlock

# ----------------------------------------------------------------------------
# Tokenizer helpers
# ----------------------------------------------------------------------------
IDENT_RE = re.compile(r'[A-Za-z_][A-Za-z0-9_$]*')
# SystemVerilog keywords / macro tokens that are NOT signal identifiers.
KEYWORDS = frozenset("""
module endmodule input output inout wire reg logic assign always always_comb
always_ff always_latch begin end if else case casez casex endcase default for
initial posedge negedge or and not xor nand nor xnor buf localparam parameter
generate endgenerate genvar integer int bit byte signed unsigned function
endfunction task endtask return void automatic static typedef struct union enum
packed unique unique0 priority repeat while do forever break continue disable
assert assume cover property endproperty sequence endsequence clocking iff
inside dist with this super null triggered posedge negedge edge
""".split())
# firtool builtins / system calls we must not treat as data signals.
SYSNAMES = frozenset("""
$fwrite $fatal $error $warning $info $display $random $signed $unsigned $clog2
$bits $size $stop $finish $time xs_assert_v2 __FILE__ __LINE__
""".split())


def strip_comments(text):
    """Remove // and /* */ comments while preserving line count/positions is not
    required (we operate statement-wise later), so just blank them."""
    # block comments
    text = re.sub(r'/\*.*?\*/', ' ', text, flags=re.S)
    # line comments
    text = re.sub(r'//[^\n]*', '', text)
    return text


def idents(expr):
    """All identifier tokens in an expression, minus keywords/sysnames/numbers.
    Handles `4'h0`, `32'h80000002`, macro `` `STOP_COND_ `` (backtick), and
    hierarchical is not expected (flat module)."""
    out = []
    # drop sized literals like 8'h0, 32'd10, 1'b1 (the width digits + base)
    e = re.sub(r"\b\d+'[sS]?[bBoOdDhH][0-9a-fA-FxXzZ_]+", ' ', expr)
    # drop backtick macros entirely (they are compile-time constants/guards)
    e = re.sub(r'`[A-Za-z_][A-Za-z0-9_]*', ' ', e)
    for m in IDENT_RE.finditer(e):
        tok = m.group(0)
        if tok in KEYWORDS or tok in SYSNAMES:
            continue
        # pure numbers already excluded by IDENT_RE (starts with letter/_)
        out.append(tok)
    return out


# ----------------------------------------------------------------------------
# Structural parse of the flat module
# ----------------------------------------------------------------------------
class FlatModule:
    def __init__(self, raw_lines, module_name):
        self.raw = raw_lines           # original text lines (with comments) — emitted verbatim
        self.module = module_name
        self.header_end = None         # index of line containing ");" that ends port list
        self.mod_start = None
        self.endmodule_idx = None
        self.ports_in = OrderedDict()  # name -> decl line idx
        self.ports_out = OrderedDict()
        # "units" = atomic keep/drop items. Each unit:
        #   {kind, lhs:set, rhs:set, lines:(start,end inclusive)}
        self.units = []
        self._parse()

    # -- locate module + port header ----------------------------------------
    def _parse(self):
        no_c = [strip_comments(l) for l in self.raw]
        n = len(self.raw)
        for i, l in enumerate(no_c):
            if re.match(r'^\s*module\s+' + re.escape(self.module) + r'\s*\(', l):
                self.mod_start = i
                break
        assert self.mod_start is not None, "module header not found"
        # port list ends at first line that is exactly ");" after mod_start
        i = self.mod_start
        while i < n:
            if re.match(r'^\s*\);\s*$', no_c[i]):
                self.header_end = i
                break
            i += 1
        assert self.header_end is not None, "port list end ');' not found"
        # parse port directions
        for j in range(self.mod_start, self.header_end + 1):
            m = re.match(r'^\s*(input|output|inout)\b(.*?)([A-Za-z_][A-Za-z0-9_$]*)\s*,?\s*$', no_c[j])
            if m:
                d, name = m.group(1), m.group(3)
                if d == 'input' or d == 'inout':
                    self.ports_in[name] = j
                else:
                    self.ports_out[name] = j
        # endmodule
        for i in range(n - 1, -1, -1):
            if re.match(r'^\s*endmodule\b', no_c[i]):
                self.endmodule_idx = i
                break
        assert self.endmodule_idx is not None
        self._parse_body(no_c)

    # -- parse body into keep/drop units ------------------------------------
    def _parse_body(self, no_c):
        i = self.header_end + 1
        end = self.endmodule_idx
        while i < end:
            line = no_c[i]
            s = line.strip()
            if not s:
                i += 1
                continue
            # ---- declarations that are ALSO drivers: `wire [..] N = EXPR;` ----
            m = re.match(r'^\s*(wire|logic)\b(.*)$', line)
            if m and '=' in line and not re.match(r'^\s*(wire|logic)\b.*<=', line):
                # could be multi-line RHS; gather until ';'
                start = i
                buf = line
                while ';' not in strip_comments(buf):
                    i += 1
                    buf += '\n' + self.raw[i]
                lhs, rhs = self._split_assign(strip_comments(buf))
                self.units.append(dict(kind='wire_assign', lhs={lhs}, rhs=idents(rhs),
                                       lines=(start, i)))
                i += 1
                continue
            # ---- plain declaration: `wire N;` / `reg [..] N;` / `logic N;` ----
            m = re.match(r'^\s*(wire|reg|logic)\b([^=;]*);\s*$', line)
            if m:
                decl_names = self._decl_names(m.group(2))
                self.units.append(dict(kind='decl', lhs=set(decl_names), rhs=set(),
                                       lines=(i, i), decl=True))
                i += 1
                continue
            # ---- continuous assign: `assign N = EXPR;` (maybe multi-line) ----
            if re.match(r'^\s*assign\b', line):
                start = i
                buf = line
                while ';' not in strip_comments(buf):
                    i += 1
                    buf += '\n' + self.raw[i]
                body = strip_comments(buf)
                body = re.sub(r'^\s*assign\b', '', body, count=1)
                lhs, rhs = self._split_assign(body)
                self.units.append(dict(kind='assign', lhs={lhs}, rhs=idents(rhs),
                                       lines=(start, i)))
                i += 1
                continue
            # ---- always blocks (register writes / assertions) ----
            if re.match(r'^\s*always(_ff|_comb|_latch)?\b', line) or re.match(r'^\s*always\s*@', line):
                start, blk_end, unit = self._parse_always(no_c, i)
                self.units.append(unit)
                i = blk_end + 1
                continue
            # ---- initial block (randomize; excluded under SYNTHESIS) ----
            if re.match(r'^\s*(`ifdef\s+ENABLE_INITIAL_REG_|`ifdef\s+ENABLE_INITIAL_MEM_)', line):
                start, blk_end = self._match_ifdef(no_c, i)
                self.units.append(dict(kind='initial_guard', lhs=set(), rhs=set(),
                                       lines=(start, blk_end), synth_excluded=True))
                i = blk_end + 1
                continue
            # ---- instance: `ModName instName (` ... `);` ----
            m = re.match(r'^\s*([A-Za-z_][A-Za-z0-9_$]*)\s+([A-Za-z_][A-Za-z0-9_$]*)\s*\(\s*$', line)
            if m and m.group(1) not in KEYWORDS:
                start, blk_end, unit = self._parse_instance(no_c, i, m.group(1), m.group(2))
                self.units.append(unit)
                i = blk_end + 1
                continue
            # ---- preprocessor / misc passthrough (keep verbatim, no cone) ----
            self.units.append(dict(kind='verbatim', lhs=set(), rhs=set(), lines=(i, i)))
            i += 1

    def _split_assign(self, body):
        body = body.strip().rstrip(';').strip()
        # LHS is up to first top-level '='  (RHS may contain '==','<=','>=' etc.,
        # but firtool LHS is a plain net or bit-select, never contains '=').
        eq = body.find('=')
        lhs_txt = body[:eq]
        rhs_txt = body[eq + 1:]
        # LHS net name = the LAST identifier before '=' that is OUTSIDE any
        # bracket (skips leading type keyword `wire`/`logic`/`reg`, any width or
        # bit-select `[..]`). firtool flat-module LHS is a single net (optionally
        # width-declared or const bit-selected); the net name is that identifier.
        lhs_nobrk = re.sub(r'\[[^\]]*\]', ' ', lhs_txt)
        lm = None
        for lm in IDENT_RE.finditer(lhs_nobrk):
            pass  # keep last
        lhs = lm.group(0) if (lm and lm.group(0) not in ('wire', 'logic', 'reg')) else \
              (lm.group(0) if lm else '')
        return lhs, rhs_txt

    def _decl_names(self, txt):
        # txt like " [7:0] a, b, c" or " N"
        # strip leading width
        txt = re.sub(r'^\s*\[[^\]]*\]', '', txt)
        names = []
        for part in txt.split(','):
            m = IDENT_RE.search(part)
            if m:
                names.append(m.group(0))
        return names

    def _match_ifdef(self, no_c, i):
        depth = 0
        j = i
        while j < len(no_c):
            l = no_c[j]
            if re.match(r'^\s*`ifdef\b', l) or re.match(r'^\s*`ifndef\b', l):
                depth += 1
            elif re.match(r'^\s*`endif\b', l):
                depth -= 1
                if depth == 0:
                    return i, j
            j += 1
        return i, j

    def _parse_always(self, no_c, i):
        """Build an AlwaysBlock recursive statement tree for the block. The tree
        supports statement-level (per-register) cone pruning with correct
        if/else-if/else structure preservation and faithful golden-line emission.
        """
        start = i
        # locate block extent by begin/end depth
        j = i
        depth = 0
        seen_begin = False
        while j < len(no_c):
            l = no_c[j]
            depth += len(re.findall(r'\bbegin\b', l))
            if re.search(r'\bbegin\b', l):
                seen_begin = True
            depth -= len(re.findall(r'\bend\b(?!module|case|function|task|generate|property|sequence)', l))
            if seen_begin and depth <= 0:
                blk_end = j
                break
            j += 1
        else:
            blk_end = len(no_c) - 1

        ab = AlwaysBlock(self.raw, no_c, start, blk_end)
        all_lhs = ab.collect_all_lhs()
        return start, blk_end, dict(kind='always', lhs=all_lhs, ab=ab,
                                    lines=(start, blk_end))

    def _parse_instance(self, no_c, i, modname, instname):
        """Parse an instance `Mod inst (` ... `);` where each port connection is
        `.pin ( expr )` and expr MAY SPAN MULTIPLE LINES (firtool emits large
        nested expressions on instance ports). We gather each connection by
        balancing parentheses from the `.pin (` open to its matching `)`."""
        start = i
        conns = []
        j = i + 1                      # first line after the `Mod inst (` line
        blk_end = None
        while j < len(no_c):
            l = no_c[j]
            if re.match(r'^\s*\);\s*$', l):
                blk_end = j
                break
            # pin name; the opening '(' may be on this line OR the next line(s)
            m = re.match(r'^\s*\.([A-Za-z_][A-Za-z0-9_$]*)\s*(\(?)', l)
            if m and l.lstrip().startswith('.'):
                pin = m.group(1)
                # locate the opening '(' — search this line from after pin; if
                # absent, advance to the next line(s) until we find it.
                srch = j
                openpos = l.find('(', m.end(1))
                buf_prefix_lines = []
                while openpos == -1:
                    srch += 1
                    if srch >= len(no_c):
                        break
                    nxt = no_c[srch]
                    op = nxt.find('(')
                    if op != -1:
                        l = nxt
                        openpos = op
                        j = srch     # continue balancing from this line
                        break
                    # blank/continuation before '(' — skip
                    if nxt.strip() and not nxt.strip().startswith('('):
                        # unexpected token; still keep scanning
                        pass
                if openpos == -1:
                    j += 1
                    continue
                buf = l[openpos:]
                depth = 0
                # count on this line
                def bal(s):
                    d = 0
                    for ch in s:
                        if ch == '(':
                            d += 1
                        elif ch == ')':
                            d -= 1
                    return d
                depth = bal(buf)
                k = j
                while depth > 0 and k < len(no_c) - 1:
                    k += 1
                    buf += '\n' + no_c[k]
                    depth += bal(no_c[k])
                # strip the outer parens
                inner = buf.strip()
                if inner.startswith('('):
                    inner = inner[1:]
                # remove trailing after matching close: keep up to last ')'
                rp = inner.rfind(')')
                if rp != -1:
                    inner = inner[:rp]
                conns.append((pin, idents(inner)))
                j = k + 1
                continue
            j += 1
        if blk_end is None:
            blk_end = j if j < len(no_c) else len(no_c) - 1
        return start, blk_end, dict(kind='instance', modname=modname, instname=instname,
                                    conns=conns, lines=(start, blk_end),
                                    lhs=set(), rhs=set())


# ----------------------------------------------------------------------------
# Cone computation
# ----------------------------------------------------------------------------
def load_child_pin_dirs():
    """Which pins of each child leaf are OUTPUTS (drive nets in the parent) vs
    INPUTS (are driven by parent nets). We need this so an instance's output
    net counts as 'produced by the instance' (a cone source when that net is
    needed) and its input nets count as fanin.

    We read the golden leaf module port directions from the golden-rtl dir.
    Falls back to: if unknown, treat the connected net BOTH as producible and as
    fanin (conservative — keeps the instance and its input cone whenever any of
    its nets is needed)."""
    import os
    GDIR = "/home/eda/xs-env/G0-canonical/golden-rtl"
    cache = {}
    def dirs_for(modname):
        if modname in cache:
            return cache[modname]
        path = os.path.join(GDIR, modname + ".sv")
        pin_out = set(); pin_in = set()
        if os.path.exists(path):
            txt = strip_comments(open(path).read())
            lines = txt.split('\n')
            for l in lines:
                m = re.match(r'^\s*(input|output|inout)\b[^;]*?([A-Za-z_][A-Za-z0-9_$]*)\s*[,)]?\s*$', l)
                if m:
                    if m.group(1) == 'output':
                        pin_out.add(m.group(2))
                    else:
                        pin_in.add(m.group(2))
        cache[modname] = (pin_out, pin_in)
        return cache[modname]
    return dirs_for


def compute_cone(fm: FlatModule, wanted_outputs, dirs_for):
    """Return the set of nets in the transitive fanin cone of wanted_outputs,
    and the set of unit indices to KEEP."""
    # driver_map: net -> list of unit idx that DRIVE it (assign/wire/always/inst-out)
    driver_map = {}
    inst_units = []
    def add_driver(net, uidx):
        driver_map.setdefault(net, []).append(uidx)

    # always blocks: each block's set of register LHS. A reg LHS is a cone
    # "boundary" (kept register); its next-state fanin is computed by the block's
    # AlwaysBlock.fanin_for(cone_regs) at fixpoint (see BFS below).
    always_units = []              # uidx of always units
    reg_to_always = {}             # reg net -> list of always uidx that drive it
    for uidx, u in enumerate(fm.units):
        k = u['kind']
        if k in ('wire_assign', 'assign'):
            for lhs in u['lhs']:
                add_driver(lhs, uidx)
        elif k == 'always':
            always_units.append(uidx)
            for reg in u['lhs']:
                reg_to_always.setdefault(reg, []).append(uidx)
        elif k == 'instance':
            po, pi = dirs_for(u['modname'])
            outs = set(); ins = set()
            for pin, nets in u['conns']:
                if pin in po:
                    outs |= set(nets)
                elif pin in pi:
                    ins |= set(nets)
                else:
                    # unknown direction: be conservative — treat as both
                    outs |= set(nets)
                    ins |= set(nets)
            u['_inst_outs'] = outs
            u['_inst_ins'] = ins
            for net in outs:
                add_driver(net, uidx)
            inst_units.append(uidx)

    # ---- BFS + fixpoint ----
    # in_cone_nets grows monotonically. Combinational/instance drivers add their
    # RHS immediately (net-level BFS). Register (always) drivers are cone
    # boundaries: a reg net entering the cone marks its always block "active";
    # the block's kept-leaf fanin depends on the SET of cone regs it drives, so
    # we recompute each active block's fanin whenever its cone-reg set grows,
    # iterating to fixpoint.
    in_cone_nets = set()
    keep_units = set()
    worklist = list(wanted_outputs)
    seen_net = set(worklist)
    # cone regs per always unit (subset of that block's LHS that are in cone)
    block_cone_regs = {u: set() for u in always_units}
    dirty_blocks = set()

    def push(n):
        if n not in seen_net:
            seen_net.add(n)
            worklist.append(n)

    while True:
        # drain net BFS
        while worklist:
            net = worklist.pop()
            in_cone_nets.add(net)
            for uidx in driver_map.get(net, ()):
                u = fm.units[uidx]
                if uidx in keep_units:
                    continue
                keep_units.add(uidx)
                if u['kind'] in ('wire_assign', 'assign'):
                    for r in u['rhs']:
                        push(r)
                elif u['kind'] == 'instance':
                    for r in u.get('_inst_ins', ()):
                        push(r)
            # register driver: mark block dirty with this reg
            for uidx in reg_to_always.get(net, ()):
                if net not in block_cone_regs[uidx]:
                    block_cone_regs[uidx].add(net)
                    dirty_blocks.add(uidx)
        # process dirty always blocks (their fanin may add new nets)
        if not dirty_blocks:
            break
        du = dirty_blocks.pop()
        ab = fm.units[du]['ab']
        for r in ab.fanin_for(block_cone_regs[du]):
            push(r)

    # instances kept if any output net in cone (already handled via driver_map);
    # but an instance may also be needed if its output feeds a kept reg's cond.
    return in_cone_nets, keep_units, block_cone_regs


# ----------------------------------------------------------------------------
# Emit reduced module
# ----------------------------------------------------------------------------
def emit(fm: FlatModule, wanted_outputs, in_cone_nets, keep_units, block_cone_regs, new_name):
    raw = fm.raw
    out_lines = []
    # header prelude (everything before module decl: macros/guards) verbatim
    out_lines.extend(raw[:fm.mod_start])
    # module header with renamed module + pruned OUTPUT ports (keep all inputs,
    # keep only wanted outputs). We rewrite the port list.
    # Build new port list preserving original declaration lines (verbatim) for
    # kept ports; drop output ports not in wanted set.
    hdr = []
    hdr.append(re.sub(r'\bmodule\s+' + re.escape(fm.module) + r'\b',
                      'module ' + new_name, raw[fm.mod_start], count=1))
    port_decl_lines = raw[fm.mod_start + 1:fm.header_end]  # between '(' line and ');'
    no_c = [strip_comments(l) for l in raw]
    kept_port_lines = []
    for j in range(fm.mod_start + 1, fm.header_end):
        l = raw[j]
        c = no_c[j]
        m = re.match(r'^\s*(input|output|inout)\b(.*?)([A-Za-z_][A-Za-z0-9_$]*)\s*,?\s*$', c)
        if m:
            d, name = m.group(1), m.group(3)
            if d == 'output' and name not in wanted_outputs:
                continue  # drop off-family output port
        kept_port_lines.append(l)
    # ensure last kept port line has no trailing comma issues: firtool port list
    # uses trailing commas on all but visually fine; SV allows a dangling comma
    # before ')' ONLY if... actually it does not. Strip trailing comma on last.
    if kept_port_lines:
        # find last line that declares a port; strip its trailing comma
        for k in range(len(kept_port_lines) - 1, -1, -1):
            if re.search(r'[A-Za-z0-9_$]\s*,\s*$', strip_comments(kept_port_lines[k])):
                kept_port_lines[k] = re.sub(r',(\s*)$', r'\1', kept_port_lines[k], count=1)
                break
            if re.search(r'[A-Za-z0-9_$]\s*$', strip_comments(kept_port_lines[k])):
                break
    out_lines.append(hdr[0])
    out_lines.extend(kept_port_lines)
    out_lines.append(raw[fm.header_end])  # ");"

    # body: emit kept units in original order
    for uidx, u in enumerate(fm.units):
        k = u['kind']
        s, e = u['lines']
        if k == 'decl':
            # keep declaration if ANY declared net is in cone
            if u['lhs'] & in_cone_nets:
                out_lines.extend(raw[s:e + 1])
            continue
        if k == 'initial_guard':
            # excluded under SYNTHESIS anyway; drop physically for determinism
            continue
        if k == 'verbatim':
            out_lines.extend(raw[s:e + 1])
            continue
        if k == 'always':
            cregs = block_cone_regs.get(uidx, set())
            if not cregs:
                continue  # no cone reg in this block -> whole block removed
            blk_lines, _fanin, has_body = u['ab'].prune_emit(cregs)
            if has_body:
                out_lines.extend(blk_lines)
            continue
        if uidx in keep_units:
            out_lines.extend(raw[s:e + 1])
        # else: physically removed (off-cone)
    out_lines.append(raw[fm.endmodule_idx])
    # trailing lines after endmodule (usually none / macros)
    out_lines.extend(raw[fm.endmodule_idx + 1:])
    return out_lines


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', required=True)
    ap.add_argument('--module', default='Rob')
    ap.add_argument('--outputs', required=True, help='file: one output port name per line')
    ap.add_argument('--keep-name', required=True, help='reduced module name')
    ap.add_argument('--out', required=True)
    ap.add_argument('--report', default=None)
    args = ap.parse_args()

    raw = open(args.src).read().split('\n')
    fm = FlatModule(raw, args.module)
    wanted = [l.strip() for l in open(args.outputs) if l.strip() and not l.startswith('#')]
    wanted_set = set(wanted)
    # sanity: all wanted must be real output ports
    missing = wanted_set - set(fm.ports_out.keys())
    if missing:
        print("FATAL: outputs not found in module port list:", sorted(missing)[:10], file=sys.stderr)
        sys.exit(2)

    dirs_for = load_child_pin_dirs()
    in_cone_nets, keep_units, block_cone_regs = compute_cone(fm, wanted_set, dirs_for)
    out_lines = emit(fm, wanted_set, in_cone_nets, keep_units, block_cone_regs, args.keep_name)
    text = '\n'.join(out_lines)
    open(args.out, 'w').write(text)

    if args.report:
        # census
        n_decl_kept = sum(1 for u in fm.units
                          if u['kind'] == 'decl' and (u['lhs'] & in_cone_nets))
        n_decl_total = sum(1 for u in fm.units if u['kind'] == 'decl')
        n_always_kept = sum(1 for i, u in enumerate(fm.units)
                            if u['kind'] == 'always' and block_cone_regs.get(i))
        n_always_total = sum(1 for u in fm.units if u['kind'] == 'always')
        n_stmt_kept = sum(len(block_cone_regs.get(i, ()))
                          for i, u in enumerate(fm.units) if u['kind'] == 'always')
        n_stmt_total = sum(len(u['lhs'])
                           for u in fm.units if u['kind'] == 'always')
        n_assign_kept = sum(1 for i, u in enumerate(fm.units)
                            if u['kind'] in ('assign', 'wire_assign') and i in keep_units)
        n_assign_total = sum(1 for u in fm.units if u['kind'] in ('assign', 'wire_assign'))
        n_inst_kept = sum(1 for i, u in enumerate(fm.units)
                          if u['kind'] == 'instance' and i in keep_units)
        n_inst_total = sum(1 for u in fm.units if u['kind'] == 'instance')
        rep = OrderedDict()
        rep['module'] = args.module
        rep['reduced_name'] = args.keep_name
        rep['src_sha256'] = hashlib.sha256('\n'.join(raw).encode()).hexdigest()
        rep['out_sha256'] = hashlib.sha256(text.encode()).hexdigest()
        rep['wanted_outputs'] = len(wanted_set)
        rep['cone_nets'] = len(in_cone_nets)
        rep['decl_kept'] = n_decl_kept
        rep['decl_total'] = n_decl_total
        rep['assign_kept'] = n_assign_kept
        rep['assign_total'] = n_assign_total
        rep['always_kept'] = n_always_kept
        rep['always_total'] = n_always_total
        rep['reg_signals_kept'] = n_stmt_kept
        rep['reg_signals_total'] = n_stmt_total
        rep['inst_kept'] = n_inst_kept
        rep['inst_total'] = n_inst_total
        rep['out_lines'] = len(out_lines)
        rep['src_lines'] = len(raw)
        json.dump(rep, open(args.report, 'w'), indent=2)
    print(f"[cone-slicer] {args.keep_name}: {len(wanted_set)} outputs, "
          f"{len(in_cone_nets)} cone nets, {len(out_lines)}/{len(raw)} lines, "
          f"out={args.out}")


if __name__ == '__main__':
    main()
