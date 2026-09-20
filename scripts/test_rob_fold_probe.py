#!/usr/bin/env python3
"""test_rob_fold_probe.py -- rob_fold_probe 的分词器负测。

★这条负测是因为踩了坑才有的★：firtool 会把长 `if (...)` 条件折行，而条件的
**下一行就是它的单条语句体**（没有 begin）。原来的分词器按"累到分号为止"合并
续行，于是把条件头和语句体粘成一个 token，整棵语句树随之错位——症状是把 160 个
并列的 `if (isFirstEnq_i)` 解析成一条 160 层深的 else 链，而且**不报任何错**，
只是给出一份看着很像那么回事的假结构。

所以这里的判据不是"能跑通"，而是：
  A 折行的 if 头必须与它的单语句体分成两个 token；
  B 并列 if 必须解析成兄弟，不能变成 else 链；
  C 带 begin/end 的 if-else 仍要解析正确（防止修 A 时把 B 改坏）；
  D ★反测★：把修复退回旧行为，A/B 必须变红——否则这条测试什么也没测。
"""
import os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rob_fold_probe as M

WRAPPED_IF = """\
    if (robEntries_1_valid & robEntries_1_itype == 4'h4
        & (io_exuWriteback_1_valid & _taken_T_10
           | io_exuWriteback_3_valid & _taken_T_13))
      robEntries_1_itype <= 4'h5;
    else if (_GEN_4051)
      robEntries_1_itype <= 4'h6;
    if (isFirstEnq_1) begin
      robEntries_1_fflags <= 5'h0;
    end
    else begin
      robEntries_1_fflags <= 5'h1;
    end
    if (isFirstEnq_2) begin
      robEntries_2_fflags <= 5'h0;
    end
""".split('\n')


NESTING_TRAP = """\
    if (isFirstEnq_0
        & robEntries_0_valid)
      robEntries_0_fflags <= 5'h0;
    if (isFirstEnq_1
        & robEntries_1_valid)
      robEntries_1_fflags <= 5'h0;
    if (isFirstEnq_2
        & robEntries_2_valid)
      robEntries_2_fflags <= 5'h0;
""".split('\n')


def tree_of(lines):
    return M.P(M.tokenize(lines, 0, len(lines))).seq()


def kinds(nodes):
    return [n[0] for n in nodes]


def run():
    toks = M.tokenize(WRAPPED_IF, 0, len(WRAPPED_IF))
    tree = tree_of(WRAPPED_IF)
    rows = []

    hdr = [t for _, t in toks if t.startswith('if (robEntries_1_valid')]
    rows.append(('A_split_header', len(hdr) == 1 and '<=' not in hdr[0],
                 'wrapped if-header is its own token, body not glued in'))

    # B 用**全部折行、全部无 begin** 的并列 if：这正是 golden 里 160 个
    # `if (isFirstEnq_i)` 的形状，也是旧分词器把它们串成一条深链的地方。
    trap = tree_of(NESTING_TRAP)
    rows.append(('B_siblings', kinds(trap) == ['if', 'if', 'if'],
                 'three wrapped begin-less ifs stay siblings, not nested'))

    second = tree[1] if len(tree) > 2 else ('if', '', [], [])
    rows.append(('C_begin_end', second[1] == 'isFirstEnq_1'
                 and len(second[2]) == 1 and len(second[3]) == 1,
                 'begin/end if-else still parses with both arms'))

    first = tree[0]
    rows.append(('C_elseif', first[1].startswith('robEntries_1_valid')
                 and len(first[3]) == 1 and first[3][0][0] == 'if',
                 'wrapped if keeps its else-if as the else arm'))
    return rows


def run_mutated():
    """D: 退回旧分词器（累到分号为止），A/B 必须红。"""
    orig = M.tokenize

    def old(lines, start, end):
        toks, buf, ind = [], None, 0
        for ln in lines[start:end]:
            s = ln.rstrip()
            if not s.strip():
                continue
            t = s.strip()
            if buf is None:
                ind = len(s) - len(s.lstrip())
                buf = t
            else:
                buf += ' ' + t
            if buf.endswith(';') or buf.endswith('begin') or buf.startswith('end') \
               or buf == 'else':
                toks.append((ind, buf))
                buf = None
        if buf is not None:
            toks.append((ind, buf))
        return toks

    M.tokenize = old
    try:
        return run()
    finally:
        M.tokenize = orig


def main():
    rows = run()
    ok = all(g for _, g, _ in rows)
    for n, g, w in rows:
        print('%-16s %-5s %s' % (n, 'OK' if g else 'FAIL', w))
    mut = run_mutated()
    mnames = {n: g for n, g, _ in mut}
    must_break = ['A_split_header', 'B_siblings']
    broke = [n for n in must_break if not mnames.get(n, True)]
    print('meta_old_tokenizer %-5s reverting the fix breaks: %s'
          % ('OK' if len(broke) == len(must_break) else 'FAIL', broke))
    ok = ok and len(broke) == len(must_break)
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
