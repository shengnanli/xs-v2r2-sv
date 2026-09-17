#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_perf_tier_gate.py —— perf 分档闸的负测（秒级，不扫 golden）。

"闸跑了且退出 0"不等于"它会响"。这里把真实台账复制到临时目录，**逐条注入一个病**，
要求 `scripts/check_perf_tier.py --no-recompute --dir <临时目录>` 当场红；再撤掉，
要求它绿。每一条注入都对应一种**会真实发生**的腐烂方式，不是凑数：

  1. 豁免过期（★最要紧的一条★）：Tage_SC 被重写之后，那 6 条 tage provider 差异
     就不再满足 codex 0162 D3 的豁免（"when the owning modules are unchanged"）。
     把 tier 台账里 Tage_SC 的 owner_rewritten 改成 yes，闸必须红。
  2. 档位被改松：把一条实测不等的计数器从 B_CONTROL 改成 C_DIAG 就能"过闸" ——
     所以 verdict 必须**现算**，且记录的 tier 与 tier 台账不一致时要红。
  3. 出现未分类：tier 台账里冒出 X_UNRESOLVED 行，必须红。
  4. 差异行没分档：mismatch 台账里的计数器在 tier 台账里查不到，必须红。
  5. 截断的 hash：`D62` 明确「截断的 hash 不算」。把 sha256 截成 12 位，必须红。
  6. GAP 单边：tier 台账说 GAP，gap 台账里没有这条（= 悄悄少一条排除记录），必须红。
  7. 解除条件留空：gap 台账的 lift_condition 空着 = 只登记不给出路，必须红。
  8. dump 时刻不同：两侧 dump 时刻不一致时整份比对不可信（D_INVARIANT 档的前提
     就是"同 dump 时刻"），必须红。

另外还钉住两条**纯函数**判据（不经文件，直接调 `perf_compare.verdict_of`）：
  9. 豁免只在 C_DIAG + owner_rewritten==no 时成立，其余组合一律 BLOCKING。
 10. 计数器不在分档台账里时（row=None）必须 BLOCKING，不许 fail-open。
"""
from __future__ import print_function

import pathlib
import shutil
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
sys.path.insert(0, str(HERE))
import perf_compare as PC                                           # noqa: E402

FILES = ('perf_tier_ledger.tsv', 'perf_gap_ledger.tsv', 'perf_mismatch_ledger.tsv')
fails = []


def check(name, cond, detail=''):
    if not cond:
        fails.append('%s: %s' % (name, detail))
    print('  %-52s %s' % (name, 'ok' if cond else '★FAIL ' + detail))


def run(d):
    p = subprocess.run([sys.executable, str(HERE / 'check_perf_tier.py'),
                        '--no-recompute', '--dir', str(d)],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return p.returncode, p.stdout.decode(errors='replace')


def fresh():
    d = pathlib.Path(tempfile.mkdtemp())
    for f in FILES:
        shutil.copy(str(REPO / 'docs' / f), str(d / f))
    return d


def edit(d, fname, fn):
    p = d / fname
    p.write_text(fn(p.read_text()))


def expect_red(name, fname, fn, want=''):
    """注入一个病 → 要求闸红，且**红在预期的那条判据上**。

    只看退出码不够：闸可能因为另一个原因红，那就证明不了这条判据在工作。
    所以要求输出里存在一行**同时**含 `★FAIL` 与判据名。
    """
    d = fresh()
    edit(d, fname, fn)
    rc, out = run(d)
    right = [ln for ln in out.splitlines() if '★FAIL' in ln and want in ln]
    check(name, rc != 0 and (bool(right) if want else True),
          'rc=%d，红在 %s 而不是 %r'
          % (rc, [ln.split()[0] for ln in out.splitlines() if '★FAIL' in ln], want))
    shutil.rmtree(str(d))


# ---------------------------------------------------------------- 先证明基线是绿的
d0 = fresh()
rc0, out0 = run(d0)
check('0 未注入时闸是绿的', rc0 == 0, 'rc=%d\n%s' % (rc0, out0[-600:]))
shutil.rmtree(str(d0))


# ---------------------------------------------------------------- 1 豁免过期
def rewrite_tage(t):
    out = []
    for ln in t.splitlines():
        f = ln.split('\t')
        if len(f) > 9 and f[8] == 'Tage_SC':
            f[9] = 'yes'
            ln = '\t'.join(f)
        out.append(ln)
    return '\n'.join(out) + '\n'


expect_red('1 Tage_SC 一旦重写，6 条 provider 豁免必须失效',
           'perf_tier_ledger.tsv', rewrite_tage, 'E ')


# ---------------------------------------------------------------- 2 档位被改松
def loosen(t):
    """把 storeQueue:vaddr_match_failed 在 tier 台账里改成 B_CONTROL，
    而 mismatch 台账里还记着 C_DIAG/WAIVED —— 闸必须发现这两处对不上。"""
    out = []
    for ln in t.splitlines():
        f = ln.split('\t')
        if len(f) > 3 and f[2] == 'vaddr_match_failed' and f[3] == 'C_DIAG':
            f[3] = 'B_CONTROL'
            ln = '\t'.join(f)
        out.append(ln)
    return '\n'.join(out) + '\n'


expect_red('2 记录的档位与 tier 台账不一致 → 红',
           'perf_tier_ledger.tsv', loosen, 'E ')


# ---------------------------------------------------------------- 3 出现未分类
def inject_unresolved(t):
    lines = t.splitlines()
    for i, ln in enumerate(lines):
        f = ln.split('\t')
        if len(f) > 3 and f[0] == 'PERF':
            f[3] = 'X_UNRESOLVED'
            lines[i] = '\t'.join(f)
            break
    return '\n'.join(lines) + '\n'


expect_red('3 台账里冒出 X_UNRESOLVED → 红',
           'perf_tier_ledger.tsv', inject_unresolved, 'B 无 X_UNRESOLVED')


# ---------------------------------------------------------------- 4 差异行没分档
def drop_row(t):
    lines = t.splitlines()
    for i, ln in enumerate(lines):
        f = ln.split('\t')
        if len(f) > 2 and f[2] == 'vaddr_match_failed':
            del lines[i]
            break
    return '\n'.join(lines) + '\n'


expect_red('4 mismatch 行在 tier 台账里查不到 → 红',
           'perf_tier_ledger.tsv', drop_row, 'E mismatch 行都已分档')


# ---------------------------------------------------------------- 5 截断的 hash
expect_red('5 sha256 被截成 12 位 → 红（D62：截断的 hash 不算）',
           'perf_mismatch_ledger.tsv',
           lambda t: '\n'.join(
               (ln[:ln.index('sha256   ') + 9] + ln.split()[-1][:12]
                if ln.startswith('# impl_log_sha256') else ln)
               for ln in t.splitlines()) + '\n',
           'D impl_log_sha256')


# ---------------------------------------------------------------- 6 GAP 单边
def drop_gap(t):
    lines = t.splitlines()
    for i, ln in enumerate(lines):
        if ln and not ln.startswith('#') and not ln.startswith('tier\t'):
            del lines[i]
            break
    return '\n'.join(lines) + '\n'


expect_red('6 tier 台账说 GAP 而 gap 台账少一条 → 红',
           'perf_gap_ledger.tsv', drop_gap, 'C gap 台账 ⊇')


# ---------------------------------------------------------------- 7 解除条件留空
def blank_lift(t):
    lines = t.splitlines()
    for i, ln in enumerate(lines):
        f = ln.split('\t')
        if len(f) >= 9 and not ln.startswith('#') and f[0] != 'tier':
            f[8] = ''
            lines[i] = '\t'.join(f)
            break
    return '\n'.join(lines) + '\n'


expect_red('7 GAP 只登记不给解除条件 → 红',
           'perf_gap_ledger.tsv', blank_lift, 'C 每条 GAP 都有解除条件')

# ---------------------------------------------------------------- 8 dump 时刻不同
expect_red('8 两侧 dump 时刻不同 → 红',
           'perf_mismatch_ledger.tsv',
           lambda t: t.replace('# dump_times_equal  True', '# dump_times_equal  False'),
           'D dump_times_equal')

# ---------------------------------------------------------------- 9/10 纯函数判据
cases = [
    (dict(tier='C_DIAG', rewritten='no'), 'WAIVED'),
    (dict(tier='C_DIAG', rewritten='yes'), 'BLOCKING'),
    (dict(tier='C_DIAG', rewritten='partial'), 'BLOCKING'),
    (dict(tier='B_CONTROL', rewritten='no'), 'BLOCKING'),
    (dict(tier='B_CONTROL', rewritten='yes'), 'BLOCKING'),
    (dict(tier='A_FUNC_ASSERT', rewritten='no'), 'BLOCKING'),
    (dict(tier='D_CONST', rewritten='no'), 'BLOCKING'),
    (dict(tier='D_INVARIANT', rewritten='no'), 'BLOCKING'),
    (dict(tier='X_UNRESOLVED', rewritten='no'), 'BLOCKING'),
]
bad = ['%s/%s→%s(应 %s)' % (c['tier'], c['rewritten'], PC.verdict_of(c)[0], w)
       for c, w in cases if PC.verdict_of(c)[0] != w]
check('9 豁免只在 C_DIAG + owner_rewritten==no 时成立', not bad, ' '.join(bad))
check('10 未分档的计数器必须 BLOCKING（不许 fail-open）',
      PC.verdict_of(None)[0] == 'BLOCKING', PC.verdict_of(None)[0])

# ---------------------------------------------------------------- 11 判据 FC 本身
# 上面 1~10 钉的是"闸会不会响"，这里钉的是"档分得对不对"。用一个玩具 golden 树，
# 每条判据各给一个最小例子 —— 两个 ★ 都是实测踩过的坑。
import perf_tier as PT                                              # noqa: E402

toy = pathlib.Path(tempfile.mkdtemp())
(toy / 'Kid.sv').write_text('''
module Kid(
  input  io_i,
  output io_o
);
  assign io_o = ~io_i;
endmodule
''')
(toy / 'Toy.sv').write_text('''
module Toy(
  input        io_in,
  input        io_b,
  output       io_out
);
  wire io_in_probe = io_in;
  wire _GEN_0 = io_in & io_b;
  wire _GEN_1 = io_in ^ io_b;
  wire drives_kid = io_in | io_b;
  wire from_kid;
  wire only_in_assert = io_in & ~io_b;
  Kid kid (
    .io_i (drives_kid),
    .io_o (from_kid)
  );
  assign io_out = _GEN_1;
  `ifndef SYNTHESIS
    always @(posedge clock) begin
      if (_GEN_0 & only_in_assert)
        $fwrite(32'h80000002, "boom");
    end
  `endif
endmodule
''')
fcv = PT.FeedsControl(str(toy)).analyze(
    'Toy', {'io_in_probe', '_GEN_0', '_GEN_1', 'drives_kid', 'from_kid', 'only_in_assert'})
want = {
    # 探针拷贝要先解析回 io_in（否则"没人读"，而它就是那个输入端口）
    'io_in_probe': ('FEEDS_CONTROL', 'own_port'),
    # 只在 `ifndef SYNTHESIS` 的断言里出现 → 不是控制逻辑
    '_GEN_0': ('OBSERVE_ONLY', 'no_reader'),
    'only_in_assert': ('OBSERVE_ONLY', 'no_reader'),
    # 被 assign 读到输出端口上
    '_GEN_1': ('FEEDS_CONTROL', 'read_by_logic'),
    # 喂给子实例的 input 端口
    'drives_kid': ('FEEDS_CONTROL', 'drives_child_input'),
    # ★被子实例的 output 端口**驱动**，本模块无人读 —— 不是"有人读"
    'from_kid': ('OBSERVE_ONLY', 'child_output_unread'),
}
bad = ['%s→%s/%s(应 %s/%s)' % (k, fcv[k][0], fcv[k][2], w[0], w[1])
       for k, w in want.items() if (fcv[k][0], fcv[k][2]) != w]
check('11 判据 FC 六种形态各判对（含两个踩过的坑）', not bad, ' '.join(bad))

# ---------------------------------------------------------------- 12 endpoint 数据流
# 直方图的桶长这样：bore 只出现在 `if` **条件**里。只看右边表达式的话，
# 整族桶会被算成"不依赖任何 bore"，于是该排除的没排除。
(toy / 'LogPerfEndpoint.sv').write_text('''
module LogPerfEndpoint(
  input        clock,
  input        reset,
  input [63:0] io_timer,
  input        perfCnt_bore,
  input  [7:0] perfCnt_bore_1
);
  reg  [63:0] hitCounter;
  reg  [63:0] bucketCounter;
  reg  [63:0] nSamples;
  wire [63:0] data_0 = 64'(hitCounter + {63'h0, perfCnt_bore});
  always @(posedge clock) begin
    if (reset) begin
      hitCounter <= 64'h0;
      bucketCounter <= 64'h0;
      nSamples <= 64'h0;
    end
    else begin
      hitCounter <= data_0;
      if (perfCnt_bore_1 > 8'h9D)
        bucketCounter <= 64'(bucketCounter + 64'h1);
      nSamples <= 64'(nSamples + 64'h1);
    end
  end
  always @(posedge clock) begin
    $fwrite(32'h80000002,
      "[PERF ][time=%d] scope.a: hit, %d\\n[PERF ][time=%d] scope.a: bucket, %d\\n[PERF ][time=%d] scope.a: sampled, %d\\n[PERF ][time=%d] scope.a: zero, %d\\n",
      io_timer, hitCounter, io_timer, bucketCounter, io_timer, nSamples, io_timer, 64'h0);
  end
endmodule
''')
tep = PT.Endpoint(str(toy))
got = dict(((n, tuple(sorted(
    set().union(*[({x} if PT.BORE.match(x) else tep.bores_of(x))
                  for x in PT.ids(arg)]) if PT.ids(arg) else set())))
    for _s, n, arg in tep.perf_counters()))
wantb = {'hit': ('perfCnt_bore',),
         'bucket': ('perfCnt_bore_1',),   # ★只出现在 if 条件里，必须跟到
         'sampled': (),                   # 每拍加一，与 DUT 无关 → D_INVARIANT
         'zero': ()}                      # 实参是字面量 → D_CONST
bad = ['%s→%s(应 %s)' % (k, got.get(k), v) for k, v in wantb.items() if got.get(k) != v]
check('12 endpoint 反向闭包跟得到 if 条件里的 bore', not bad, ' '.join(bad))
shutil.rmtree(str(toy))

print()
if fails:
    print('★test_perf_tier_gate: %d 条未过★' % len(fails))
    for f in fails:
        print('   ' + f)
    sys.exit(1)
print('test_perf_tier_gate: 全部通过（%d 条注入都让闸红了，撤掉都绿）' % 8)
