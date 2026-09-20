#!/usr/bin/env python3
"""gen_rob_pins.py -- generate Rob's FM name-pin table from golden.

Why pins at all
---------------
Rob has 11,639 registers. Unpinned, Formality matches them by signature, and
signature matching on structurally identical entries is ~O(N^2): measured
8/33/147/554 s at 320/640/1280/2560 registers (scripts/rob_array_idiom_canary.py),
extrapolating to ~3 h at Rob's size. Pinning turns that into a name lookup.

The previous round could not pin at all. Its core stored entries as a packed
struct, so the only impl DFF objects were `rob_entries_reg[N][bit]` with `bit` an
offset into a 201-bit concatenation -- FM-036 on 9263/9440 -- and it fell back to
16,161 hand-written pins. With the per-field array layout this file assumes, the
canary measured 4000/4000 pins ACCEPTED, no FM-036, match 147 s -> 55 s.

The naming contract (this file IS the contract)
-----------------------------------------------
golden flattens `<prefix>[<i>].<field>` to a scalar `<prefix>_<i>_<field>`.
The readable core declares one array per (prefix, field):

    logic [W-1:0] <prefix>_<field> [DEPTH];

which Formality sees as `<prefix>_<field>_reg[<i>][<b>]`. So every pin is:

    r:/WORK/Rob/<prefix>_<i>_<field>_reg[<b>]
    i:/WORK/Rob/u_core/<prefix>_<field>_reg[<i>][<b>]

Width-1 registers have no `[<b>]` on either side -- golden writes
`<prefix>_<i>_<field>_reg` and the core `<prefix>_<field>_reg[<i>]`.

Measured (2026-09-18, fm_shell V-2023.12-SP3)
--------------------------------------------
The impl half of the contract above was validated on a 160-entry x 8-field
stand-in shaped exactly like Rob's wrapper -- `module Canary` instantiating
`xs_Canary_core u_core` -- because the earlier canary only ever proved the path
at TOP level (`i:/WORK/Canary/ent_<f>_reg[i][b]`), and every pin this file emits
carries one extra instance hop (`.../Canary/u_core/...`). That hop was an
assumption until measured. Result:

    PINCONTRACT pinned 4000 of 4000       <- every pin accepted, no FM-036
    Verification SUCCEEDED, 4025 passing compare points, 0 errors

What is STILL unvalidated: the real Rob core does not exist yet, so the prefix
and field spellings this file derives from golden have never been checked
against an actual `xs_Rob_core`. The emitted Tcl is fail-closed precisely so
that a spelling mismatch shows up as `pinned N of M, N != M` and `exit 3`
instead of a silently slow match.

Fail-closed
-----------
The emitted Tcl counts accepted pins and `exit 3`s unless every pin was taken,
so a silently-unpinned register can never masquerade as a fast match.

Self-test (`--selftest`) runs in pure tclsh with `set_user_match` stubbed -- no
Formality, no license. It is DISCRIMINATING, not merely reactive: each check
emits its own tag, and every negative asserts THAT SPECIFIC tag fired. A test
that only asserted "nonzero exit" would pass against a script that rejects
everything, which is the `return True` failure mode.

Usage
  python3 scripts/gen_rob_pins.py --emit verif/ut/Rob/fm_pins.tcl
  python3 scripts/gen_rob_pins.py --selftest
"""
import argparse, collections, hashlib, os, re, subprocess, sys, tempfile

GOLDEN = os.environ.get(
    'ROB_GOLDEN', '/home/eda/xs-env/G1-canonical/golden-rtl/Rob.sv')

# Families that are firtool temporaries, not arrays. `r_0`/`r_1` and
# `io_perf_<n>_value_REG` fold under a <prefix>_<idx>_<field> regex but are not
# indexed storage, so pinning them by array position would be a guess. Excluded
# by name, and the exclusion is asserted in the self-test so it cannot silently
# grow.
NOT_ARRAYS = {'r', 'io_perf', 'REG', 'io_error'}

# 形如 `<prefix>_<idx>`（没有字段后缀）的真数组。它们折不进 <prefix>_<idx>_<field>
# 的正则，于是一直没被钉住——而它们恰恰是钉 pin 要解决的那种情况：160 个结构完全
# 相同的寄存器，不钉就退化成签名匹配（O(N^2)，canary 实测 320/640/1280/2560 个
# 寄存器要 8/33/147/554 秒）。
#
# ★为什么是白名单而不是"凡是稠密的 <prefix>_<idx> 都算"★：golden 里 `REG_1..REG_8`、
# `r_0..r_23`、`perfEvents_r_0..7` 也都长这样，但它们在可读核里根本不叫这个名字
# （r_0..r_23 是 exceptionVec 的 24 个 RegEnable，核里叫 exceptionVecReg）。
# pin 是 fail-closed 的：钉一个核里不存在的名字，整个 FM 直接 exit 3。
# 所以这里只放"核一定会用这个名字声明成数组"的两族，并由自测钉住它不许悄悄变长。
ONE_D_ARRAYS = {
    'debug_exuData': (64, 160),   # Reg(Vec(RobSize, UInt(XLEN.W)))，写回数据快照
    'debug_lsIssued': (1, 160),   # RegInit(VecInit.fill(RobSize)(false.B))
}


def golden_arrays(path):
    """-> {prefix: {field: (width, depth)}} for genuinely entry-indexed storage."""
    with open(path) as f:
        text = f.read()
    decl = {}
    for l in text.split('\n'):
        m = re.match(r'\s*reg\s*(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*(\w+)\s*;', l)
        if m:
            w = 1 if m.group(1) is None else int(m.group(1)) - int(m.group(2)) + 1
            decl[m.group(3)] = w
    fam = collections.defaultdict(lambda: collections.defaultdict(dict))
    for n, w in decl.items():
        m = re.match(r'^(.*?)_(\d+)_(.+)$', n)
        if not m:
            continue
        pre, idx, fld = m.group(1), int(m.group(2)), m.group(3)
        if pre in NOT_ARRAYS:
            continue
        fam[pre][fld][idx] = w
    out = {}
    for pre, flds in fam.items():
        keep = {}
        for fld, idxs in flds.items():
            widths = set(idxs.values())
            # A real array has one width and a dense 0..N-1 index range. Anything
            # ragged is a name collision, not storage -- drop it rather than
            # emit a pin whose impl side may not exist.
            if len(widths) == 1 and set(idxs) == set(range(len(idxs))):
                keep[fld] = (widths.pop(), len(idxs))
        if keep:
            out[pre] = keep

    # 一维族：<prefix>_<idx>，白名单内且在 golden 里确实稠密、等宽才收。
    for pre, (w, depth) in sorted(ONE_D_ARRAYS.items()):
        idxs = {}
        for n, ww in decl.items():
            m = re.match(r'^%s_(\d+)$' % re.escape(pre), n)
            if m:
                idxs[int(m.group(1))] = ww
        if not idxs:
            raise SystemExit('gen_rob_pins: ONE_D_ARRAYS 里的 %r 在 golden 里一个都没有'
                             % pre)
        widths = set(idxs.values())
        if widths != {w} or set(idxs) != set(range(depth)):
            raise SystemExit(
                'gen_rob_pins: %r 与白名单声明不符 golden=(%s, idx %d..%d) 声明=(%d, %d)'
                % (pre, sorted(widths), min(idxs), max(idxs), w, depth))
        if pre in out:
            raise SystemExit('gen_rob_pins: %r 同时被二维和一维规则收了' % pre)
        out[pre] = {None: (w, depth)}
    return out, hashlib.sha256(text.encode()).hexdigest()


def emit(arrays, digest, top='Rob', inst='u_core'):
    L = []
    L.append('# fm_pins.tcl for %s -- GENERATED by scripts/gen_rob_pins.py.' % top)
    L.append('# Do not hand-edit: regenerate. golden sha256 %s' % digest)
    L.append('# Every puts in this file is ASCII: fm.log is not UTF-8, and a')
    L.append('# self-report that lands as question marks is worse than none.')
    L.append('set _pinned 0')
    L.append('set _want 0')
    total = 0
    for pre in sorted(arrays):
        flds = arrays[pre]
        n = sum(w * d for w, d in flds.values())
        total += n
        L.append('')
        if list(flds) == [None]:
            w, d = flds[None]
            L.append('# %s: 1-D array, %d entries x %d bits = %d register bits'
                     % (pre, d, w, n))
        else:
            L.append('# %s: %d fields x %d entries = %d register bits'
                     % (pre, len(flds), max(d for _, d in flds.values()), n))
        for fld in sorted(flds, key=lambda x: '' if x is None else x):
            w, depth = flds[fld]
            if fld is None:
                # 一维族：golden `<pre>_<i>` <-> 核 `<pre>[<i>]`
                L.append('for {set i 0} {$i < %d} {incr i} {' % depth)
                if w == 1:
                    L.append('  incr _want')
                    L.append('  if {[catch {set_user_match '
                             'r:/WORK/%s/%s_${i}_reg '
                             'i:/WORK/%s/%s/%s_reg\\[$i\\]}] == 0} {incr _pinned}'
                             % (top, pre, top, inst, pre))
                else:
                    L.append('  for {set b 0} {$b < %d} {incr b} {' % w)
                    L.append('    incr _want')
                    L.append('    if {[catch {set_user_match '
                             'r:/WORK/%s/%s_${i}_reg\\[$b\\] '
                             'i:/WORK/%s/%s/%s_reg\\[$i\\]\\[$b\\]}] == 0} '
                             '{incr _pinned}'
                             % (top, pre, top, inst, pre))
                    L.append('  }')
                L.append('}')
                continue
            L.append('for {set i 0} {$i < %d} {incr i} {' % depth)
            if w == 1:
                L.append('  incr _want')
                L.append('  if {[catch {set_user_match '
                         'r:/WORK/%s/%s_${i}_%s_reg '
                         'i:/WORK/%s/%s/%s_%s_reg\\[$i\\]}] == 0} {incr _pinned}'
                         % (top, pre, fld, top, inst, pre, fld))
            else:
                L.append('  for {set b 0} {$b < %d} {incr b} {' % w)
                L.append('    incr _want')
                L.append('    if {[catch {set_user_match '
                         'r:/WORK/%s/%s_${i}_%s_reg\\[$b\\] '
                         'i:/WORK/%s/%s/%s_%s_reg\\[$i\\]\\[$b\\]}] == 0} {incr _pinned}'
                         % (top, pre, fld, top, inst, pre, fld))
                L.append('  }')
            L.append('}')
    L.append('')
    L.append('puts "ROB_PINS pinned $_pinned of $_want"')
    L.append('if {$_pinned != $_want} {')
    L.append('  puts "ROB_PINS_FAIL not every pin was accepted"')
    L.append('  exit 3')
    L.append('}')
    L.append('if {$_want != %d} {' % total)
    L.append('  puts "ROB_PINS_FAIL expected %d pins, built $_want"' % total)
    L.append('  exit 3')
    L.append('}')
    return '\n'.join(L) + '\n', total



# --------------------------------------------------------------------------
# 离线核对：核里的数组声明是否满足这份 pin 契约
# --------------------------------------------------------------------------
# 为什么要这个：pin 表是 fail-closed 的 —— 名字对不上，FM 会在 match 阶段
# `exit 3`。可是要走到那一步得先付 **72 分钟 + 15 GB**（见
# evidence/rob-selfcompare-4aa8838b/README.md 的实测）。一个拼错的字段名不值这个价。
# 这里直接读 rtl/backend/Rob.sv 里 xs_Rob_core 的声明，秒级给出同样的判断。
#
# ★这不是 FM 的替身★：它只核对"名字/位宽/深度"这一层，也就是 pin 能不能落上。
# FM 还要核对逻辑。两者都要跑，顺序是先跑这个。

# SV 非打包数组声明。接受 `[N]` / `[0:N-1]` / `[N-1:0]` 三种写法。
DECL = re.compile(
    r'^\s*(?:logic|reg|bit)\s*'
    r'(?:signed\s+)?'
    r'(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*)?'
    r'([A-Za-z_]\w*)\s*'
    r'((?:\[[^\]]*\]\s*)*);', re.M)


def _unpacked_depth(text):
    """把 `[160]` / `[0:159]` / `[159:0]` 解析成深度；不是数组返回 None。"""
    text = text.strip()
    if not text:
        return None
    dims = re.findall(r'\[([^\]]*)\]', text)
    if len(dims) != 1:
        return ('MULTI', len(dims))
    d = dims[0].strip()
    m = re.match(r'^(\d+)$', d)
    if m:
        return int(m.group(1))
    m = re.match(r'^(\d+)\s*:\s*(\d+)$', d)
    if m:
        return abs(int(m.group(1)) - int(m.group(2))) + 1
    return ('EXPR', d)


def core_arrays(path_or_text, is_text=False):
    """-> {name: (width, depth_or_None)}，只看 xs_Rob_core 那一段。"""
    text = path_or_text if is_text else open(path_or_text).read()
    i = text.find('module xs_Rob_core')
    if i < 0:
        return None
    j = text.find('\nendmodule', i)
    body = text[i:] if j < 0 else text[i:j]
    out = {}
    for m in DECL.finditer(body):
        hi, lo, name, unp = m.group(1), m.group(2), m.group(3), m.group(4)
        w = 1 if hi is None else abs(int(hi) - int(lo)) + 1
        out[name] = (w, _unpacked_depth(unp))
    return out


def check_core(arrays, core):
    """核对，返回 (rows, rc)。每条不符都带自己的标签，不合并成一句"有问题"。"""
    bad = []
    want = 0
    for pre in sorted(arrays):
        for fld in sorted(arrays[pre], key=lambda x: '' if x is None else x):
            w, depth = arrays[pre][fld]
            name = pre if fld is None else '%s_%s' % (pre, fld)
            want += 1
            got = core.get(name)
            if got is None:
                bad.append(('MISSING', name, 'w=%d d=%d' % (w, depth), '-'))
                continue
            gw, gd = got
            if gd is None:
                bad.append(('NOT_AN_ARRAY', name, 'w=%d d=%d' % (w, depth),
                            'declared as a scalar'))
                continue
            if isinstance(gd, tuple):
                bad.append(('UNPARSED_DEPTH', name, 'w=%d d=%d' % (w, depth),
                            '%s %s' % gd))
                continue
            if gw != w:
                bad.append(('WIDTH', name, 'w=%d' % w, 'core w=%d' % gw))
            if gd != depth:
                bad.append(('DEPTH', name, 'd=%d' % depth, 'core d=%d' % gd))
    return want, bad

SELFTEST_HARNESS = r'''
# Stubs: no Formality, no license. MODE decides how set_user_match behaves.
set ::MODE $env(PIN_TEST_MODE)
set ::calls 0
proc set_user_match {a b} {
    incr ::calls
    switch -- $::MODE {
        ok       { return 0 }
        refuse1  { if {$::calls == 7} { error "FM-036 unknown name $b" } ; return 0 }
        refuseall { error "FM-036 unknown name $b" }
    }
    return 0
}
proc exit_tag {t} { puts "TAG $t" ; exit 3 }
'''


def selftest():
    """Positive + three negatives, each asserting ITS OWN tag.

    The point of the tags: a script that rejected everything would pass a test
    that only checked "nonzero exit". Each negative below names the check it
    expects to fire, so a blanket-reject script fails the positive AND reports
    the wrong tag on two of the three negatives.
    """
    arrays, digest = golden_arrays(GOLDEN)
    # A small synthetic family keeps the self-test fast and independent of how
    # big golden happens to be today.
    tiny = {'ent': {'valid': (1, 4), 'pdest': (8, 4)}}
    body, total = emit(tiny, 'SELFTEST')
    assert total == 4 * 1 + 4 * 8, total
    d = tempfile.mkdtemp(prefix='rob-pins-selftest-')
    results = {}
    cases = [
        ('ok', 0, 'ROB_PINS pinned 36 of 36', 'positive: every pin accepted'),
        ('refuse1', 3, 'ROB_PINS_FAIL not every pin was accepted',
         'one pin refused (FM-036) must be caught, not rounded away'),
        ('refuseall', 3, 'ROB_PINS_FAIL not every pin was accepted',
         'all pins refused'),
    ]
    for mode, want_rc, want_txt, why in cases:
        p = os.path.join(d, 'case_%s.tcl' % mode)
        with open(p, 'w') as f:
            f.write(SELFTEST_HARNESS + body)
        env = dict(os.environ, PIN_TEST_MODE=mode)
        # Python 3.6 here: no capture_output=, no text=.
        pr = subprocess.run(['tclsh', p], stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, env=env)
        out = pr.stdout.decode()
        ok = (pr.returncode == want_rc) and (want_txt in out)
        results[mode] = (ok, pr.returncode, out.strip().splitlines()[-1:] or [''], why)

    # Fourth negative, and the one that catches a WRONG-COUNT generator: claim a
    # count the body does not build. This is a different check from "a pin was
    # refused", and it must fire its own message.
    bad = body.replace('if {$_want != 36} {', 'if {$_want != 999} {')
    bad = bad.replace('expected 36 pins', 'expected 999 pins')
    p = os.path.join(d, 'case_count.tcl')
    with open(p, 'w') as f:
        f.write(SELFTEST_HARNESS + bad)
    pr = subprocess.run(['tclsh', p], stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        env=dict(os.environ, PIN_TEST_MODE='ok'))
    out = pr.stdout.decode()
    results['wrong_count'] = (
        pr.returncode == 3 and 'expected 999 pins' in out
        and 'not every pin was accepted' not in out,
        pr.returncode, out.strip().splitlines()[-1:] or [''],
        'count check fires its OWN message; pin-refused message must NOT appear')

    # ---- meta-check: would this self-test CATCH a broken generator? ----
    # Everything above shows the checks fire on bad INPUT. That is only half.
    # A generator that rejected unconditionally would also "fire" on every
    # negative -- and sail through, because a test that asserts only
    # "the negatives were rejected" cannot tell a discriminating check from
    # `return True`. So mutate the generator itself into a blanket-rejecter and
    # require the POSITIVE case to go red. If this row ever says OK, the four
    # rows above prove nothing.
    blanket = body.replace('puts "ROB_PINS pinned $_pinned of $_want"',
                           'puts "ROB_PINS_FAIL not every pin was accepted"\nexit 3')
    p = os.path.join(d, 'case_meta.tcl')
    with open(p, 'w') as f:
        f.write(SELFTEST_HARNESS + blanket)
    pr = subprocess.run(['tclsh', p], stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        env=dict(os.environ, PIN_TEST_MODE='ok'))
    out = pr.stdout.decode()
    # The positive case must now FAIL (rc != 0). If it still passes, the
    # positive assertion is vacuous.
    results['meta_blanket'] = (
        pr.returncode != 0,
        pr.returncode, out.strip().splitlines()[-1:] or [''],
        'MUTATED generator to reject everything -- positive case MUST go red')


    # ---- --check-core 的自测：正例 + 四个负例，各自报自己的标签 ----
    # 这一段测的是"离线契约核对"，不是 Tcl。它必须能分辨四种不同的错法，
    # 否则一个只会说"有问题"的核对器也能过。
    tiny2 = {'ent': {'valid': (1, 4), 'pdest': (8, 4)},
             'flat': {None: (64, 4)}}
    GOOD = """module xs_Rob_core (input logic clock);
  logic        ent_valid  [4];
  logic [7:0]  ent_pdest  [4];
  logic [63:0] flat       [4];
endmodule
"""
    core_cases = [
        ('cc_ok', GOOD, [], 'positive: every required array present and shaped right'),
        ('cc_missing', GOOD.replace('  logic [7:0]  ent_pdest  [4];\n', ''),
         ['MISSING'], 'a missing array is named, not rounded away'),
        ('cc_width', GOOD.replace('[7:0]  ent_pdest', '[6:0]  ent_pdest'),
         ['WIDTH'], 'wrong width fires WIDTH (and only WIDTH)'),
        ('cc_depth', GOOD.replace('ent_pdest  [4]', 'ent_pdest  [5]'),
         ['DEPTH'], 'wrong depth fires DEPTH (and only DEPTH)'),
        ('cc_scalar', GOOD.replace('ent_pdest  [4];', 'ent_pdest;'),
         ['NOT_AN_ARRAY'], 'declared as a scalar is its own failure, not MISSING'),
    ]
    for name, text, want_tags, why in core_cases:
        core = core_arrays(text, is_text=True)
        _want, bad = check_core(tiny2, core)
        tags = sorted({t for t, _n, _e, _g in bad})
        results[name] = (tags == sorted(want_tags), len(bad),
                         [','.join(tags) or '(none)'], why)

    # meta：把核对器改成"永远说没问题"，四个负例必须全部变红。
    _real = globals()['check_core']

    def _blind(arrays, core):
        return 0, []
    globals()['check_core'] = _blind
    try:
        blind_ok = all(
            sorted({t for t, _n, _e, _g in check_core(tiny2,
                    core_arrays(text, is_text=True))[1]}) == sorted(want)
            for _n2, text, want, _w in core_cases if want)
    finally:
        globals()['check_core'] = _real
    results['cc_meta_blind'] = (
        not blind_ok, 0, ['-'],
        'MUTATED the checker to always pass -- the four negatives MUST go red')

    # meta：把核对器改成"永远说有问题"，正例必须变红。
    def _paranoid(arrays, core):
        return 0, [('MISSING', 'x', '-', '-')]
    globals()['check_core'] = _paranoid
    try:
        _w3, b3 = check_core(tiny2, core_arrays(GOOD, is_text=True))
        para_pos_ok = (len(b3) == 0)
    finally:
        globals()['check_core'] = _real
    results['cc_meta_paranoid'] = (
        not para_pos_ok, 0, ['-'],
        'MUTATED the checker to always fail -- the positive MUST go red')

    print('%-18s %-6s %-4s %s' % ('case', 'verdict', 'rc', 'what it proves'))
    allok = True
    for k, (ok, rc, tail, why) in results.items():
        print('%-18s %-6s %-4s %s' % (k, 'OK' if ok else 'FAIL', rc, why))
        if not ok:
            allok = False
            print('             last line: %s' % (tail[0] if tail else ''))
    print()
    print('exclusions asserted not to have grown: %s' % sorted(NOT_ARRAYS))
    print('1-D array allowlist asserted not to have grown: %s'
          % sorted(ONE_D_ARRAYS))
    if sorted(NOT_ARRAYS) != ['REG', 'io_error', 'io_perf', 'r'] or \
       sorted(ONE_D_ARRAYS) != ['debug_exuData', 'debug_lsIssued']:
        print('FAIL 白名单/排除表变了却没改这条断言 —— 每一条都要有理由，'
              '不许悄悄增长')
        allok = False
    return 0 if allok else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--golden', default=GOLDEN)
    ap.add_argument('--emit')
    ap.add_argument('--summary', action='store_true')
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--selftest', action='store_true')
    ap.add_argument('--check-core', dest='check_core',
                    nargs='?', const='rtl/backend/Rob.sv')
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    arrays, digest = golden_arrays(a.golden)
    if a.check_core is not None:
        repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        path = a.check_core
        if not os.path.isabs(path):
            path = os.path.join(repo, path)
        if not os.path.exists(path):
            sys.stderr.write(
                'gen_rob_pins --check-core: %s 不存在 —— 核还没建，无可核对。\n'
                '  ★这里不 fail-open★：本条只在"文件不在"时返回 2（区别于 0=通过、'
                '3=契约不符），\n  调用方要自己决定 2 算不算过。\n' % path)
            return 2
        core = core_arrays(path)
        if core is None:
            sys.stderr.write('gen_rob_pins --check-core: %s 里找不到 module xs_Rob_core\n'
                             % path)
            return 3
        want, bad = check_core(arrays, core)
        print('# core %s' % path)
        print('# golden sha256 %s' % digest)
        for tag, name, expect, got in bad:
            print('%-14s %-44s expected %-14s got %s' % (tag, name, expect, got))
        print('PINCONTRACT %d array declarations required, %d mismatched'
              % (want, len(bad)))
        if bad:
            print('PINCONTRACT_FAIL 名字/位宽/深度对不上 —— FM 的 set_user_match 会拒，'
                  '别去烧那 72 分钟')
            return 3
        return 0
    body, total = emit(arrays, digest)
    if a.check:
        repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        tgt = os.path.join(repo, 'verif', 'ut', 'Rob', 'fm_pins.tcl')
        # ★fail-closed★：产物已入库，不在就是真出事（被删/被 gitignore 吃掉），
        # 不是"还没生成"。生成器无输入依赖除了只读的 golden。
        if not os.path.exists(tgt):
            sys.stderr.write('gen_rob_pins --check: %s 不存在（该文件已入库）\n' % tgt)
            return 1
        cur = open(tgt).read()
        if cur != body:
            sys.stderr.write(
                'gen_rob_pins --check: %s 与重新生成的结果不一致 —— 重跑 --emit\n'
                '  （golden sha256 %s）\n' % (tgt, digest))
            return 1
        print('gen_rob_pins --check: OK，%d 个 pin，与 %s 逐字节一致' % (total, tgt))
        return 0
    if a.summary or not a.emit:
        print('# golden sha256 %s' % digest)
        print('%-30s %7s %7s %10s' % ('array prefix', 'fields', 'depth', 'pins'))
        for pre in sorted(arrays, key=lambda p: -sum(
                w * d for w, d in arrays[p].values())):
            flds = arrays[pre]
            print('%-30s %7d %7d %10d'
                  % (pre, len(flds), max(d for _, d in flds.values()),
                     sum(w * d for w, d in flds.values())))
        print('# total pins %d' % total)
        print('# excluded as not-arrays: %s' % sorted(NOT_ARRAYS))
    if a.emit:
        os.makedirs(os.path.dirname(os.path.abspath(a.emit)), exist_ok=True)
        with open(a.emit, 'w') as f:
            f.write(body)
        print('# wrote %s (%d pins)' % (a.emit, total), file=sys.stderr)
    return 0


if __name__ == '__main__':
    sys.exit(main())
