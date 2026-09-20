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

Fail-closed —— ★2026-09-20 实测推翻了原来的写法，这里记下原委★
------------------------------------------------------------------
产出的 Tcl 数"钉上了几个"，不足数就 `exit 3`。**但"怎么数"以前是错的**：

    旧： if {[catch {set_user_match $r $i}] == 0} {incr _pinned}      ← 空的
    新： if {[set_user_match $r $i]} {incr _pinned}                   ← 有分辨力

实测（scripts/rob_pin_failclosed_probe.py，证据 docs/rob_pin_failclosed.tsv，
两次独立跑一致）：`set_user_match` **从不抛 Tcl 异常**。五例里 catch 全是 0 ——
包括两侧名字都不存在那一例。区别只在**返回值**：钉上了 1，钉不上 0；
同时 fm.log 里每个不存在的名字写一行 `Error: Unknown name: ... (FM-036)`。

所以旧写法下 `_pinned` 恒等于 `_want`，那行 `exit 3` 永远走不到 ——
169,168 个 pin 一个都没配上也会打印 "pinned 169168 of 169168"。

这条错误没被 `--selftest` 发现，因为**桩里让 refuse 模式 `error`** ——
桩的行为正是待验的那个假设。用桩去验桩自己的假设是个闭环。
桩已按实测改成"返回 0/1、从不抛"。

第二条独立判据（不依赖返回值）：fm.log 里行首锚定的 `Error:` 行数必须为 0。
两条都该用；只用一条时，任一条的失效方式都是**安静的**。

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


# --------------------------------------------------------------------------
# ★不参与钉点的族：两侧都不驱动 ⇒ FM 两侧都把它优化掉 ⇒ 它根本不是比较点★
# --------------------------------------------------------------------------
# 集成者 0920 裁定：期望值必须是**结构导出的契约**，不许把一次观测钉成常数。
# 所以这里不是"把 169168 改成 168720"，而是：声明哪一族不参与，
# 期望值仍由 `sum(w*d)` 在**剩下的**族上算出来。
#
# 依据（2026-09-20 真跑实测，evidence: verif/ut/Rob/fm_evidence/fm_run_summary.txt）：
#   robDeqGroup_<0..7>_debug_otherPdest_<0..6> 这 56 个寄存器按裁定两侧都不驱动。
#   Formality 两侧都把它们优化掉了，于是 set_user_match 报名字不存在：
#     ROB_PINS pinned 168720 of 169168        <- 差 448
#     行首锚定的 FM-036 共 **896** 行 = 448 x 2（ref/impl 各一份）
#     逐族点名：14 族 x 64 = 896，全部是 debug_otherPdest
#   448 = 7 字段 x 8 条目 x 8 位。
# ★措辞很重要（集成者 0920 亲自更正）★：它们**不在**比较集合里，
# 不是"在比较集合里但没连上"。前者是"根本没比"，后者是"比了但比不出结果"——
# 对"这个证明覆盖了什么"的含义完全不同。留空的裁定本身不变
# （不驱动 / 不 dont_verify / 不黑盒 / 不进白名单）。
EXCLUDED_NOT_COMPARE_POINTS = {'robDeqGroup': r'^debug_otherPdest_\d+$'}

# ★这张表是断言的对象，不是注释★：排除掉的集合必须**精确**等于它。
# 将来若有**别的**东西变得钉不上，它不在这张表里 ⇒ 它仍会被钉 ⇒ 守卫在真跑里变红，
# 而**不会**被"再降一次期望值"这个动作悄悄吸收掉。这正是集成者要的性质。
EXPECT_EXCLUDED = {('robDeqGroup', 'debug_otherPdest_%d' % k): (8, 8)
                   for k in range(7)}


def split_excluded(arrays):
    """-> (kept, excluded)；并断言 excluded 精确等于 EXPECT_EXCLUDED。"""
    kept, excluded = {}, {}
    for pre in sorted(arrays):
        pat = EXCLUDED_NOT_COMPARE_POINTS.get(pre)
        keep_f, drop_f = {}, {}
        for fld, wd in arrays[pre].items():
            if pat is not None and fld is not None and re.match(pat, fld):
                drop_f[fld] = wd
            else:
                keep_f[fld] = wd
        if keep_f:
            kept[pre] = keep_f
        for fld, wd in drop_f.items():
            excluded[(pre, fld)] = wd
    if excluded != EXPECT_EXCLUDED:
        extra = {k: v for k, v in excluded.items() if EXPECT_EXCLUDED.get(k) != v}
        missing = {k: v for k, v in EXPECT_EXCLUDED.items() if excluded.get(k) != v}
        raise SystemExit(
            'gen_rob_pins: ★被排除的集合与声明不符★\n'
            '  多出来/对不上: %r\n  少了: %r\n'
            '  —— 排除表只为 debug_otherPdest 那 56 个寄存器而设。'
            '别的东西钉不上时**不许**加进来把它吸收掉：那会把"哪些点没被证明"'
            '悄悄扩大。先查为什么钉不上。' % (sorted(extra), sorted(missing)))
    return kept, excluded


def emit(arrays, digest, top='Rob', inst='u_core', excluded=None):
    excluded = excluded or {}
    L = []
    L.append('# fm_pins.tcl for %s -- GENERATED by scripts/gen_rob_pins.py.' % top)
    L.append('# Do not hand-edit: regenerate. golden sha256 %s' % digest)
    L.append('# Every puts in this file is ASCII: fm.log is not UTF-8, and a')
    L.append('# self-report that lands as question marks is worse than none.')
    if excluded:
        nb = sum(w * d for w, d in excluded.values())
        L.append('#')
        L.append('# NOT PINNED (deliberately, %d register bits in %d fields):'
                 % (nb, len(excluded)))
        for (pre, fld) in sorted(excluded):
            w, d = excluded[(pre, fld)]
            L.append('#   %s_<0..%d>_%s  (%d bits each)' % (pre, d - 1, fld, w))
        L.append('#   Both sides leave these undriven, so Formality optimises them')
        L.append('#   away on BOTH sides: they are NOT compare points at all, and a')
        L.append('#   pin naming them can only ever fail (FM-036). Measured 2026-09-20:')
        L.append('#   "pinned 168720 of 169168", 896 line-anchored FM-036 = 448 x 2.')
        L.append('#   The count below is DERIVED (total minus this family), never a')
        L.append('#   hand-written constant -- see EXCLUDED_NOT_COMPARE_POINTS.')
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
                    L.append('  if {[set_user_match '
                             'r:/WORK/%s/%s_${i}_reg '
                             'i:/WORK/%s/%s/%s_reg\\[$i\\]]} {incr _pinned}'
                             % (top, pre, top, inst, pre))
                else:
                    L.append('  for {set b 0} {$b < %d} {incr b} {' % w)
                    L.append('    incr _want')
                    L.append('    if {[set_user_match '
                             'r:/WORK/%s/%s_${i}_reg\\[$b\\] '
                             'i:/WORK/%s/%s/%s_reg\\[$i\\]\\[$b\\]]} '
                             '{incr _pinned}'
                             % (top, pre, top, inst, pre))
                    L.append('  }')
                L.append('}')
                continue
            L.append('for {set i 0} {$i < %d} {incr i} {' % depth)
            if w == 1:
                L.append('  incr _want')
                L.append('  if {[set_user_match '
                         'r:/WORK/%s/%s_${i}_%s_reg '
                         'i:/WORK/%s/%s/%s_%s_reg\\[$i\\]]} {incr _pinned}'
                         % (top, pre, fld, top, inst, pre, fld))
            else:
                L.append('  for {set b 0} {$b < %d} {incr b} {' % w)
                L.append('    incr _want')
                L.append('    if {[set_user_match '
                         'r:/WORK/%s/%s_${i}_%s_reg\\[$b\\] '
                         'i:/WORK/%s/%s/%s_%s_reg\\[$i\\]\\[$b\\]]} {incr _pinned}'
                         % (top, pre, fld, top, inst, pre, fld))
                L.append('  }')
            L.append('}')
    L.append('')
    # ★中止一律用 `error`，任何值的 `exit` 都不许用★（集成者 0920 全仓裁定）
    # 机理是实测出来的、并在 2.29 小时那次真跑里兑现了：钉点文件跑在 sidecar 的
    # **safe interp** 里（fm_eq.tcl:766 sidecar_pin_source -> interp eval），
    # 而 Tcl 的 safe interp **隐藏 exit**。于是 `exit 3` 抛的是
    #   Error: invalid command name "exit"
    # 仍然 fail-closed（fm_eq.tcl 没 catch，错误一路抛上去终止脚本），
    # 但操作者看到的理由**不是**"钉点没配全"。`error` 在白名单里，消息如实。
    L.append('puts "ROB_PINS pinned $_pinned of $_want"')
    L.append('if {$_pinned != $_want} {')
    L.append('  error "ROB_PINS_FAIL not every pin was accepted"')
    L.append('}')
    L.append('if {$_want != %d} {' % total)
    L.append('  error "ROB_PINS_FAIL expected %d pins, built $_want"' % total)
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
    r'(?:\[([^\]:]+)\s*:\s*([^\]]+)\]\s*)?'
    r'([A-Za-z_]\w*)\s*'
    r'((?:\[[^\]]*\]\s*)*);', re.M)

# ★可读核里位宽和深度都是具名常量★（ROB_SIZE / COMMITTYPE_W-1:0 ...），
# 不是字面量。判据必须能把它们解开，否则"读不懂"会被报成"名字缺失/深度不符" ——
# 那是判据自己看不见，不是核写错了（2026-09-20 实测：126 条全报 mismatched）。
# 这里只解 `localparam int NAME = <整数或简单算式>;` 这一种形态，解不动就如实
# 报 UNPARSED_*，不猜。
_LOCALPARAM = re.compile(
    r'^\s*localparam\s+(?:int\s+)?(?:unsigned\s+)?([A-Za-z_]\w*)\s*=\s*([^;,]+)[;,]',
    re.M)


def localparams(text):
    """包/模块里的 localparam 常量表；能算出整数的才收。"""
    env = {}
    for _ in range(4):          # 允许互相引用，迭代几轮即可收敛
        changed = False
        for m in _LOCALPARAM.finditer(text):
            name, expr = m.group(1), m.group(2).strip()
            if name in env:
                continue
            v = _eval_int(expr, env)
            if v is not None:
                env[name] = v
                changed = True
        # 同一行多个赋值（`localparam int A = 0, B = 1;`）
        for m in re.finditer(r'(?:^\s*localparam[^;]*?|,)\s*([A-Za-z_]\w*)\s*=\s*([^;,]+)',
                             text, re.M):
            name, expr = m.group(1), m.group(2).strip()
            if name in env:
                continue
            v = _eval_int(expr, env)
            if v is not None:
                env[name] = v
                changed = True
        if not changed:
            break
    return env


def _eval_int(expr, env):
    """只允许 整数 / 已知常量 / + - * / ( )；其它一律返回 None（不猜）。"""
    e = expr.strip()
    if not re.fullmatch(r'[0-9A-Za-z_+\-*/() \t]+', e):
        return None
    for name in sorted(env, key=len, reverse=True):
        e = re.sub(r'(?<![A-Za-z_0-9])%s(?![A-Za-z_0-9])' % re.escape(name),
                   str(env[name]), e)
    if re.search(r'[A-Za-z_]', e):
        return None
    try:
        v = eval(e, {'__builtins__': {}}, {})       # 上面已限死字符集
    except Exception:
        return None
    return int(v) if isinstance(v, (int, float)) else None


def _unpacked_depth(text, env=None):
    """把 `[160]` / `[0:159]` / `[159:0]` / `[ROB_SIZE]` 解析成深度；不是数组返回 None。"""
    env = env or {}
    text = text.strip()
    if not text:
        return None
    dims = re.findall(r'\[([^\]]*)\]', text)
    if len(dims) != 1:
        return ('MULTI', len(dims))
    d = dims[0].strip()
    v = _eval_int(d, env)
    if v is not None and ':' not in d:
        return v
    if ':' in d:
        lo_hi = [x.strip() for x in d.split(':', 1)]
        a, b = _eval_int(lo_hi[0], env), _eval_int(lo_hi[1], env)
        if a is not None and b is not None:
            return abs(a - b) + 1
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
    env = localparams(text)          # 常量表取自整份文件（package + module）
    out = {}
    for m in DECL.finditer(body):
        hi, lo, name, unp = m.group(1), m.group(2), m.group(3), m.group(4)
        if hi is None:
            w = 1
        else:
            a, b = _eval_int(hi, env), _eval_int(lo, env)
            w = None if (a is None or b is None) else abs(a - b) + 1
        out[name] = (w, _unpacked_depth(unp, env))
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
#
# ★这个桩过去是错的，2026-09-20 用真 fm_shell 量过才改对★
# （证据 docs/rob_pin_failclosed.tsv，探针 scripts/rob_pin_failclosed_probe.py）：
#   set_user_match **从不抛 Tcl 异常**。名字不存在时它照样返回，只是
#   返回 0 而不是 1，并往 fm.log 里写一行 `Error: Unknown name: ... (FM-036)`。
#   实测五例 catch 全 0：真名字返回 1，假名字（impl 侧/ref 侧/两侧）返回 0。
# 老桩让 refuse 模式 `error`，于是它验的是"如果 FM 会抛，判据就成立"——
# 而 FM 不抛。**用桩去验桩自己的假设，是一个闭环**。
proc set_user_match {a b} {
    incr ::calls
    switch -- $::MODE {
        ok       { return 1 }
        refuse1  { if {$::calls == 7} { return 0 } ; return 1 }
        refuseall { return 0 }
    }
    return 1
}
set ::MODE $env(PIN_TEST_MODE)
set ::calls 0
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
        # ★中止改成 `error` 之后，退出码从 3 变成 1★：tclsh 对**未捕获的
        # error** 返回 1。判据仍然是"非零 + 打出它自己那条消息"，
        # 而不是"等于某个魔数"——魔数会把"中止方式"和"中止理由"绑死。
        # （真跑里根本走不到退出码：fm_eq.tcl 不 catch，error 一路抛上去终止脚本。）
        ('ok', 0, 'ROB_PINS pinned 36 of 36', 'positive: every pin accepted'),
        ('refuse1', 1, 'ROB_PINS_FAIL not every pin was accepted',
         'one pin refused (FM-036) must be caught, not rounded away'),
        ('refuseall', 1, 'ROB_PINS_FAIL not every pin was accepted',
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
        pr.returncode == 1 and 'expected 999 pins' in out
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
                           'error "ROB_PINS_FAIL not every pin was accepted"')
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
    # 同一个正例，改用具名常量写（可读核就是这么写的）
    GOOD_PARAM = """package p;
  localparam int ROB_N = 4;
  localparam int PREG_W = 8;
  localparam int XLEN = 64;
endpackage
module xs_Rob_core import p::*; (input logic clock);
  logic                ent_valid  [ROB_N];
  logic [PREG_W-1:0]   ent_pdest  [ROB_N];
  logic [XLEN-1:0]     flat       [ROB_N];
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
        # ★可读核里位宽/深度是具名常量★：核对器必须能解 localparam，
        #   否则它读不懂就报"缺失/深度不符"，而那是判据自己瞎，不是核写错了。
        ('cc_localparam', GOOD_PARAM, [],
         'named localparams ([PREG_W-1:0] / [ROB_N]) resolve, not reported as MISSING'),
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

    # meta：把 localparam 解析关掉，具名常量的正例必须转红 ——
    # 证明那段解析是承重的，不是加了个永远返回空表的摆设。
    _real_lp = globals()['localparams']
    globals()['localparams'] = lambda text: {}
    try:
        _w4, b4 = check_core(tiny2, core_arrays(GOOD_PARAM, is_text=True))
        lp_blind_clean = (len(b4) == 0)
    finally:
        globals()['localparams'] = _real_lp
    results['cc_meta_localparam'] = (
        not lp_blind_clean, 0, ['-'],
        'MUTATED localparam resolution to empty -- the named-param positive MUST go red')

    # ---- 排除表自己的正负测（集成者 0920 要求 2）----------------------------
    # ★「我加了一道更严的判据」本身也要先证明它会响★。split_excluded 的全部价值
    # 在于：**别的**东西将来钉不上时不会被同一个"降期望值"的动作吸收掉。
    # 所以这里必须证明它对"排除集合变了"真的会红，而不是只在正例上安静通过。
    _ga, _ = golden_arrays(GOLDEN)
    _orig = dict(EXCLUDED_NOT_COMPARE_POINTS)
    excl_cases = []
    # 正例：当前 golden + 当前排除表，必须不抛，且正好 448 位 / 7 个字段
    try:
        _k, _e = split_excluded(_ga)
        nb = sum(w * d for w, d in _e.values())
        excl_cases.append(('excl_ok', len(_e) == 7 and nb == 448,
                           'excluded 精确是 7 字段 / 448 位（实测 golden）'))
    except SystemExit as e:
        excl_cases.append(('excl_ok', False, '正例竟然抛了: %s' % e))
    # 负例 1：排除表被放宽到**多吸收一族** -> 必须抛
    try:
        EXCLUDED_NOT_COMPARE_POINTS['robDeqGroup'] = r'^debug_.*$'
        split_excluded(_ga)
        excl_cases.append(('excl_grew', False,
                           '★排除表多吸收了一族竟然没抛 —— 断言是空的★'))
    except SystemExit:
        excl_cases.append(('excl_grew', True,
                           '排除表多吸收一族必须抛（这正是"别的东西钉不上被悄悄吸收"的形状）'))
    finally:
        EXCLUDED_NOT_COMPARE_POINTS.clear()
        EXCLUDED_NOT_COMPARE_POINTS.update(_orig)
    # 负例 2：golden 侧该族形状变了（少一个字段）-> 必须抛
    try:
        _mut = {pre: dict(f) for pre, f in _ga.items()}
        del _mut['robDeqGroup']['debug_otherPdest_6']
        split_excluded(_mut)
        excl_cases.append(('excl_shape', False,
                           '★golden 少一个 otherPdest 字段竟然没抛★'))
    except SystemExit:
        excl_cases.append(('excl_shape', True,
                           'golden 侧该族形状变了必须抛（换 golden 必须重新审）'))
    for k, ok, why in excl_cases:
        results[k] = (ok, '-', [''], why)

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
    # ★期望值由结构导出★：先把"根本不是比较点"的那一族分出去（并断言它精确
    # 等于 EXPECT_EXCLUDED），剩下的族照旧 sum(w*d)。不许在任何地方写死总数。
    kept, excluded = split_excluded(arrays)
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
        want, bad = check_core(kept, core)
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
    body, total = emit(kept, digest, excluded=excluded)
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
        for pre in sorted(kept, key=lambda p: -sum(
                w * d for w, d in kept[p].values())):
            flds = kept[pre]
            print('%-30s %7d %7d %10d'
                  % (pre, len(flds), max(d for _, d in flds.values()),
                     sum(w * d for w, d in flds.values())))
        nb = sum(w * d for w, d in excluded.values())
        print('# total pins %d  (= all %d register bits MINUS %d not-compare-point '
              'bits)' % (total, total + nb, nb))
        print('# excluded as not-arrays: %s' % sorted(NOT_ARRAYS))
        print('# excluded as NOT compare points (undriven both sides): %s'
              % sorted('%s_*_%s' % k for k in excluded))
    if a.emit:
        os.makedirs(os.path.dirname(os.path.abspath(a.emit)), exist_ok=True)
        with open(a.emit, 'w') as f:
            f.write(body)
        print('# wrote %s (%d pins)' % (a.emit, total), file=sys.stderr)
    return 0


if __name__ == '__main__':
    sys.exit(main())
