"""Tiny Verilog-expression evaluator (concat / slice / | / & / ~ / ?: / literals).

Values are (int_value, width) pairs so slices and concats are exact.
Used to *prove* golden's read-data OR-reduction equals the family template's
zero-extended OR, instead of eyeballing firtool's staged reduction tree.
"""
import re

class V(object):
    __slots__ = ('v', 'w')
    def __init__(self, v, w): self.v = v & ((1 << w) - 1); self.w = w
    def __repr__(self): return 'V(%x,%d)' % (self.v, self.w)

def tokenize(s):
    return re.findall(r"\d+'[hb][0-9a-fA-F_]+|[A-Za-z_]\w*|\d+|==|[\{\}\[\]\(\)\?:,\|&~]", s)

class P(object):
    def __init__(self, toks, env):
        self.t = toks; self.i = 0; self.env = env
    def peek(self): return self.t[self.i] if self.i < len(self.t) else None
    def eat(self, x=None):
        tk = self.t[self.i]; self.i += 1
        assert x is None or tk == x, (x, tk, self.t[self.i-5:self.i+5])
        return tk
    # ternary (lowest)
    def expr(self):
        c = self.orx()
        if self.peek() == '?':
            self.eat('?'); a = self.expr(); self.eat(':'); b = self.expr()
            w = max(a.w, b.w)
            return V(a.v if c.v else b.v, w)
        return c
    def orx(self):
        a = self.andx()
        while self.peek() == '|':
            self.eat('|'); b = self.andx(); a = V(a.v | b.v, max(a.w, b.w))
        return a
    def andx(self):
        a = self.eqx()
        while self.peek() == '&':
            self.eat('&'); b = self.eqx(); a = V(a.v & b.v, max(a.w, b.w))
        return a
    def eqx(self):
        a = self.unary()
        while self.peek() == '==':
            self.eat('=='); b = self.unary(); a = V(1 if a.v == b.v else 0, 1)
        return a
    def unary(self):
        tk = self.peek()
        if tk == '~':
            self.eat('~'); a = self.unary(); return V(~a.v, a.w)
        if tk == '&':          # reduction AND
            self.eat('&'); a = self.unary()
            return V(1 if a.v == (1 << a.w) - 1 else 0, 1)
        if tk == '|':          # reduction OR
            self.eat('|'); a = self.unary()
            return V(1 if a.v else 0, 1)
        return self.postfix()
    def postfix(self):
        a = self.primary()
        while self.peek() == '[':
            self.eat('[')
            hi = int(self.eat())
            if self.peek() == ':':
                self.eat(':'); lo = int(self.eat())
            else:
                lo = hi
            self.eat(']')
            a = V(a.v >> lo, hi - lo + 1)
        return a
    def primary(self):
        tk = self.peek()
        if tk == '(':
            self.eat('('); e = self.expr(); self.eat(')'); return e
        if tk == '{':
            self.eat('{')
            # replication {N{expr}}
            if re.match(r'^\d+$', self.peek() or '') and self.t[self.i+1] == '{':
                n = int(self.eat()); self.eat('{'); e = self.expr(); self.eat('}'); self.eat('}')
                v = 0
                for _ in range(n):
                    v = (v << e.w) | e.v
                return V(v, e.w * n)
            parts = [self.expr()]
            while self.peek() == ',':
                self.eat(','); parts.append(self.expr())
            self.eat('}')
            v = 0; w = 0
            for p in reversed(parts):
                v |= p.v << w; w += p.w
            return V(v, w)
        m = re.match(r"^(\d+)'([hb])([0-9a-fA-F_]+)$", tk)
        if m:
            self.eat()
            return V(int(m.group(3).replace('_',''), 16 if m.group(2)=='h' else 2), int(m.group(1)))
        if re.match(r'^\d+$', tk):
            self.eat(); return V(int(tk), 32)
        self.eat()
        assert tk in self.env, 'unbound %r' % tk
        return self.env[tk]

def ev(s, env):
    p = P(tokenize(s), env)
    r = p.expr()
    assert p.i == len(p.t), 'trailing tokens %s' % p.t[p.i:]
    return r
