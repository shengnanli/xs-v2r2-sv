#!/usr/bin/env python3
"""
always_tree.py — recursive-descent parser + cone-pruner for firtool-emitted
`always @(...)` blocks in a FLAT module.

Handles the firtool subset actually present in Rob.sv:
  - nested if / else-if / else
  - `begin ... end` blocks (begin appears inline on the `if(cond) begin` /
    `else begin` line, or a bare single statement follows an `if(cond)` /
    `else` with no begin)
  - `<=` leaf register assignments (RHS may span multiple lines)
  - assertion payload (`$fwrite`/`xs_assert_v2`) leaves — dropped when off-cone
  NO case / for / while / fork (verified absent).

Approach: build a flat TOKEN STREAM of (word, line_idx) where `word` ∈ the
comment-stripped source words, tracking the original source line of each token.
A recursive-descent parser over the token stream produces a statement tree whose
nodes carry their exact source LINE SPAN. Pruning selects a subset of leaves
(by LHS ∈ cone_regs) and re-emits the ORIGINAL golden source lines that make up
the kept subtree (byte-faithful), inserting synthetic `begin end` only where a
structurally-required branch became empty.

Soundness: a pure fanin-cone slice — a leaf is kept iff its target reg reaches a
kept output; conditions gating a kept leaf are preserved (their idents feed the
fanin). Removing off-cone leaves cannot change any kept output's behaviour.
"""
import re

IDENT_RE = re.compile(r'[A-Za-z_][A-Za-z0-9_$]*')
KEYWORDS = frozenset("""begin end if else case casez casex endcase default for
posedge negedge or and always always_ff always_comb always_latch clock reset
""".split())
SYS = frozenset("$fwrite $fatal $error $display $random $signed $unsigned".split())


def _idents(txt):
    e = re.sub(r"\b\d+'[sS]?[bBoOdDhH][0-9a-fA-FxXzZ_]+", ' ', txt)
    e = re.sub(r'`[A-Za-z_][A-Za-z0-9_]*', ' ', e)
    out = []
    for m in IDENT_RE.finditer(e):
        t = m.group(0)
        if t in KEYWORDS or t in SYS:
            continue
        out.append(t)
    return out


# Token = (kind, text, line)  where kind in {'begin','end','if','else','semi','('
#         ,')','word'}  — we only need begin/end/if/else/semicolon structurally.
class Lexer:
    def __init__(self, no_c, start, end):
        self.toks = []
        # We tokenise coarsely: split each line into words but keep begin/end/if/
        # else/';' as structural markers; everything else is opaque 'chunk'.
        for li in range(start, end + 1):
            line = no_c[li]
            # tokenise preserving structure: find begin|end|else|if keywords,
            # semicolons, and the remaining text.
            pos = 0
            for m in re.finditer(r'\bbegin\b|\bend\b|\belse\b|\bif\b|;', line):
                pre = line[pos:m.start()]
                if pre.strip():
                    self.toks.append(('chunk', pre, li))
                tk = m.group(0)
                if tk == ';':
                    self.toks.append(('semi', ';', li))
                else:
                    self.toks.append((tk, tk, li))
                pos = m.end()
            tail = line[pos:]
            if tail.strip():
                self.toks.append(('chunk', tail, li))
        self.i = 0

    def peek(self):
        return self.toks[self.i] if self.i < len(self.toks) else (None, None, None)

    def next(self):
        t = self.toks[self.i]
        self.i += 1
        return t

    def eof(self):
        return self.i >= len(self.toks)


class AlwaysBlock:
    def __init__(self, raw, no_c, start, end):
        self.raw = raw
        self.start = start
        self.end = end
        # header lines: from `always` up to and incl. the line with the first
        # `begin` (the block open).
        self.header_lines = []
        i = start
        while i <= end:
            self.header_lines.append(i)
            if re.search(r'\bbegin\b', no_c[i]):
                break
            i += 1
        self.header_last = i          # line with opening begin
        # tokenise from AFTER the opening begin to the final end (self.end)
        self.lex = Lexer(no_c, start, end)
        # advance lexer past header: consume tokens until the FIRST 'begin'
        while not self.lex.eof():
            k = self.lex.peek()[0]
            self.lex.next()
            if k == 'begin':
                break
        # parse statement list until the matching final 'end' (block close)
        self.tree = self._parse_stmt_list(close='end')

    # node kinds:
    #  ('assign', lhs, rhs_idents, (s,e))
    #  ('pass', None, set(), (s,e))
    #  ('block', [nodes], None, (begin_line, end_line))
    #  ('if', [(cond_idents,(cs,ce),then_node)...], else_node|None, (s,e))
    def _parse_stmt_list(self, close):
        nodes = []
        while not self.lex.eof():
            k, txt, li = self.lex.peek()
            if k == close:
                self.lex.next()   # consume closing end
                return nodes
            if k == 'begin':
                nodes.append(self._parse_block())
                continue
            if k == 'if':
                nodes.append(self._parse_if())
                continue
            if k == 'semi':
                self.lex.next()
                continue
            if k == 'chunk':
                nodes.append(self._parse_leaf())
                continue
            # stray else/end -> stop
            if k in ('else', 'end'):
                return nodes
            self.lex.next()
        return nodes

    def _parse_block(self):
        _, _, begin_li = self.lex.next()   # consume 'begin'
        nodes = []
        end_li = begin_li
        while not self.lex.eof():
            k, txt, li = self.lex.peek()
            if k == 'end':
                _, _, end_li = self.lex.next()
                break
            if k == 'begin':
                nodes.append(self._parse_block())
            elif k == 'if':
                nodes.append(self._parse_if())
            elif k == 'semi':
                self.lex.next()
            elif k == 'chunk':
                nodes.append(self._parse_leaf())
            else:
                self.lex.next()
        return ('block', nodes, None, (begin_li, end_li))

    def _parse_leaf(self):
        """A leaf statement: gather chunk tokens up to the next ';'. Determine if
        it's an `LHS <= RHS` assignment or a passthrough (assertion)."""
        parts = []
        s_li = self.lex.peek()[2]
        e_li = s_li
        while not self.lex.eof():
            k, txt, li = self.lex.peek()
            if k == 'semi':
                _, _, e_li = self.lex.next()
                break
            if k in ('begin', 'end', 'if', 'else'):
                break
            self.lex.next()
            parts.append(txt)
            e_li = li
        body = ' '.join(parts)
        m = re.match(r'\s*([A-Za-z_][A-Za-z0-9_$]*)\s*(\[[^\]]*\])?\s*<=', body)
        if m:
            lhs = m.group(1)
            rhs_txt = body.split('<=', 1)[1]
            return ('assign', lhs, set(_idents(rhs_txt)), (s_li, e_li))
        return ('pass', None, set(), (s_li, e_li))

    def _parse_if(self):
        first_li = self.lex.peek()[2]
        arms = []
        else_node = None
        while True:
            # consume 'if'
            _, _, if_li = self.lex.next()
            cs, ce, cond_idents = self._gather_cond()
            then_node = self._parse_branch_body()
            arms.append((cond_idents, (cs, ce), then_node))
            # look for else / else-if
            k, txt, li = self.lex.peek()
            if k == 'else':
                self.lex.next()  # consume 'else'
                k2 = self.lex.peek()[0]
                if k2 == 'if':
                    continue  # else-if arm
                # trailing else
                else_node = self._parse_branch_body()
                break
            break
        last_li = else_node[3][1] if else_node else arms[-1][2][3][1]
        return ('if', arms, else_node, (first_li, last_li))

    def _gather_cond(self):
        """After 'if', gather '(' ... balanced ')'. Returns (start_line, end_line,
        idents)."""
        # collect chunk tokens spanning the parenthesised condition
        depth = 0
        started = False
        parts = []
        s_li = None
        e_li = None
        while not self.lex.eof():
            k, txt, li = self.lex.peek()
            if k != 'chunk':
                # begin/if/else/end/semi cannot appear inside a condition except
                # 'begin' AFTER the ')'. Stop when balanced.
                if started and depth == 0:
                    break
            self.lex.next()
            if s_li is None:
                s_li = li
            e_li = li
            parts.append(txt)
            for ch in txt:
                if ch == '(':
                    depth += 1; started = True
                elif ch == ')':
                    depth -= 1
            if started and depth == 0:
                break
        return s_li, e_li, set(_idents(' '.join(parts)))

    def _parse_branch_body(self):
        """Parse the statement that forms a branch body: either a `begin..end`
        block or a single statement (assign/if/pass)."""
        k, txt, li = self.lex.peek()
        if k == 'begin':
            return self._parse_block()
        if k == 'if':
            return self._parse_if()
        if k == 'chunk':
            return self._parse_leaf()
        if k == 'semi':
            self.lex.next()
            return ('block', [], None, (li, li))
        return ('block', [], None, (li, li))

    # ---- analysis helpers ----
    def collect_all_lhs(self):
        lhs = set()
        def rec(n):
            if n is None:
                return
            t = n[0]
            if t == 'assign':
                lhs.add(n[1])
            elif t == 'block':
                for c in n[1]:
                    rec(c)
            elif t == 'if':
                for (_ci, _cl, tn) in n[1]:
                    rec(tn)
                rec(n[2])
        for n in self.tree:
            rec(n)
        return lhs

    def _node_has_kept(self, node, cone):
        if node is None:
            return False
        t = node[0]
        if t == 'assign':
            return node[1] in cone
        if t == 'pass':
            return False
        if t == 'block':
            return any(self._node_has_kept(c, cone) for c in node[1])
        if t == 'if':
            for (_ci, _cl, tn) in node[1]:
                if self._node_has_kept(tn, cone):
                    return True
            return self._node_has_kept(node[2], cone)
        return False

    def fanin_for(self, cone):
        fanin = set()
        def rec(node):
            t = node[0]
            if t == 'assign':
                if node[1] in cone:
                    fanin.update(node[2])
                return
            if t == 'pass':
                return
            if t == 'block':
                for c in node[1]:
                    if self._node_has_kept(c, cone):
                        rec(c)
                return
            if t == 'if':
                arms = node[1]; else_n = node[2]
                arm_kept = [self._node_has_kept(a[2], cone) for a in arms]
                else_kept = self._node_has_kept(else_n, cone) if else_n else False
                last = -1
                for idx, ak in enumerate(arm_kept):
                    if ak:
                        last = idx
                stop = len(arms) - 1 if else_kept else last
                for idx in range(len(arms)):
                    if idx > stop:
                        break
                    fanin.update(arms[idx][0])
                    if arm_kept[idx]:
                        rec(arms[idx][2])
                if else_kept:
                    rec(else_n)
        for n in self.tree:
            if self._node_has_kept(n, cone):
                rec(n)
        return fanin


    def prune_emit(self, cone):
        """Byte-faithful line-set emission of the pruned block.

        Strategy: walk the tree and decide, for the kept subtree, exactly which
        ORIGINAL golden source lines to emit, plus any synthetic `begin end`
        fillers required when a structurally-necessary branch has no kept leaf.
        Returns (out_lines, fanin, has_body).

        Rules (all sound — pure fanin cone):
          * a leaf assign kept  -> emit its source line span; add RHS to fanin
          * an if-chain: emit arms 0..last_needed (last kept arm, or all arms if
            the trailing else is kept). For each such arm emit the condition line
            span (verbatim, carrying any inline `begin`) + add its idents to
            fanin. Then:
              - if the arm body has kept content -> emit that body (recursively),
                and for a block body the golden inner lines + the block's `end`.
              - if the arm body is empty (dropped) but structurally required ->
                if the cond carried an inline `begin`, emit the block's golden
                `end` line (=> `if(cond) begin end`); else inject a lone `;`.
          * a trailing kept else -> emit its golden `else` line + body.
        """
        raw = self.raw
        fanin = set()
        keep = set()          # source line indices to emit
        inject = {}           # source line idx -> list of synthetic lines to
                              # append AFTER that source line

        def add_inject(after_li, text):
            inject.setdefault(after_li, []).append(text)

        def emit_body(node):
            """Emit a branch/statement body. Return True if it produced ≥1 kept
            leaf line (non-empty)."""
            t = node[0]
            if t == 'assign':
                if node[1] in cone:
                    s, e = node[3]
                    for li in range(s, e + 1):
                        keep.add(li)
                    fanin.update(node[2])
                    return True
                return False
            if t == 'pass':
                return False
            if t == 'block':
                s, e = node[3]     # begin_line, end_line
                any_kept = False
                for c in node[1]:
                    if self._node_has_kept(c, cone):
                        if emit_body(c):
                            any_kept = True
                if any_kept:
                    keep.add(s)    # begin (may coincide with cond line -> set dedups)
                    keep.add(e)    # end
                    return True
                return False
            if t == 'if':
                return emit_if(node)
            return False

        def emit_if(node):
            arms = node[1]; else_n = node[2]
            arm_kept = [self._node_has_kept(a[2], cone) for a in arms]
            else_kept = self._node_has_kept(else_n, cone) if else_n else False
            last = -1
            for idx, ak in enumerate(arm_kept):
                if ak:
                    last = idx
            stop = len(arms) - 1 if else_kept else last
            if last < 0 and not else_kept:
                return False
            for idx in range(len(arms)):
                if idx > stop:
                    break
                ci, cl, tn = arms[idx]
                for li in range(cl[0], cl[1] + 1):
                    keep.add(li)
                fanin.update(ci)
                inline_begin = bool(re.search(r'\bbegin\s*$', raw[cl[1]]))
                produced = emit_body(tn) if arm_kept[idx] else False
                if not produced:
                    # required-but-empty arm
                    if inline_begin:
                        # cond already opened a block; close it
                        if tn[0] == 'block':
                            keep.add(tn[3][1])         # golden 'end'
                        else:
                            add_inject(cl[1], '    end')
                    else:
                        add_inject(cl[1], '    ;')      # empty single stmt
            if else_kept:
                # emit the golden 'else' line: it's the source line immediately
                # preceding else_n's first line, OR shares a line. Find it.
                els_li = self._else_source_line(else_n, arms)
                if els_li is not None:
                    keep.add(els_li)
                    inline_begin = bool(re.search(r'\bbegin\s*$', raw[els_li]))
                else:
                    inline_begin = False
                produced = emit_body(else_n)
                if not produced:
                    if inline_begin and else_n[0] == 'block':
                        keep.add(else_n[3][1])
                    elif inline_begin:
                        if els_li is not None:
                            add_inject(els_li, '    end')
                    else:
                        if els_li is not None:
                            add_inject(els_li, '    ;')
            return True

        for n in self.tree:
            if self._node_has_kept(n, cone):
                emit_body(n)

        if not keep:
            return [], fanin, False
        # assemble: header + kept body lines in order + final end
        out = [raw[li] for li in self.header_lines]
        lo = self.header_last + 1
        hi = self.end - 1
        for li in range(lo, hi + 1):
            if li in keep:
                out.append(raw[li])
            for extra in inject.get(li, ()):
                out.append(extra)
        out.append(raw[self.end])
        return out, fanin, True

    def _else_source_line(self, else_n, arms):
        """The golden source line index carrying the `else` keyword for the
        trailing else. firtool emits `else` on its own line, or `else begin` /
        `else if`. We locate it as the line right after the last arm's body,
        scanning raw for the `else` token. Robust heuristic: the else line is the
        first line at-or-before else_n's start that contains a standalone
        `else`."""
        start = else_n[3][0]
        raw = self.raw
        for li in range(start, max(self.header_last, start - 4) - 1, -1):
            if re.search(r'(^|\s)else(\s|$)', raw[li]):
                return li
        return None
