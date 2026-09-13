#!/usr/bin/env python3
"""test_migrate_criteria.py —— port_increment_migrate.py 三条判据的负测。

跑法: python3 scripts/test_migrate_criteria.py
任何一例不符预期即非零退出。

为什么要负测：三条判据都是"少写一句就会静默放行"的类型 ——
放行的后果是生成一个看起来对、UT 也过、只有 FM 才炸的核。
所以每条判据都必须有一例"构造出来的坏样本"证明它会拒。

  P1 位宽假阳性   : 只改端口位宽的样本必须被拒（并且能被人类从输出里看出改了哪几根）
  P2 随机化块     : 只有 `ifdef ENABLE_INITIAL_REG_ 块大小不同的样本必须被放行
  P3 实例名配对   : 兄弟实例互换编号的样本，按家族配会错、按实例名配必须对，
                    且替换必须是同时替换（链式替换的样本要能被抓出来）
  P4 同名子模块    : 子模块没改名、内容变了的样本必须被拒，除非显式声明它是黑盒
另加真 golden 回归（G0/G1 实样本），避免判据在重构中失效。
"""
import pathlib
import sys
import tempfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import port_increment_migrate as M

FAILS = []
RAN = []


def expect(cond, msg):
    RAN.append(msg)
    if not cond:
        FAILS.append(msg)
        print(f'  FAIL: {msg}')
    else:
        print(f'  ok  : {msg}')


# ---------------------------------------------------------------------------
# 合成样本：一对只差端口位宽的模块
# ---------------------------------------------------------------------------
SYN_A = """\
module T(
  input         clock,
  input  [2:0]  io_in_source,
  output [2:0]  io_out_source
);
  Child u_c (
    .a (io_in_source),
    .b (io_out_source)
  );
endmodule
"""
SYN_B_WIDTH = SYN_A.replace('[2:0]', '[4:0]')

# 只差随机化块大小
SYN_C = """\
module T(
  input  clock,
  input  io_in
);
  reg r;
  always @(posedge clock) r <= io_in;
  `ifdef ENABLE_INITIAL_REG_
    initial begin
      automatic logic [31:0] _RANDOM_0 = `RANDOM;
      r = _RANDOM_0[0];
    end
  `endif // ENABLE_INITIAL_REG_
endmodule
"""
SYN_D = """\
module T(
  input  clock,
  input  io_in
);
  reg r;
  always @(posedge clock) r <= io_in;
  `ifdef ENABLE_INITIAL_REG_
    initial begin
      automatic logic [31:0] _RANDOM_0 = `RANDOM;
      automatic logic [31:0] _RANDOM_1 = `RANDOM;
      automatic logic [31:0] _RANDOM_2 = `RANDOM;
      r = _RANDOM_0[0];
    end
  `endif // ENABLE_INITIAL_REG_
endmodule
"""

# 兄弟实例互换编号 + 整体下移一号（P3 的两个核心坑）
#   坑 A（配对键）：按模块家族叉积配会给出 4 个候选（含 2 个错的）；
#   坑 B（替换法）：Arb_31->Arb_30 与 Arb_30->Arb_29 同时存在时，
#                   逐条 re.sub 会把第一条的结果再喂给第二条。
SYN_E = """\
module T(
  input  clock
);
  Arb_31 txdatArb (
    .clock (clock)
  );
  Arb_30 txreqArb (
    .clock (clock)
  );
endmodule
"""
SYN_F = """\
module T(
  input  clock
);
  Arb_30 txdatArb (
    .clock (clock)
  );
  Arb_29 txreqArb (
    .clock (clock)
  );
endmodule
"""


def syn_check(a, b, name='T', allow_child_renumber=False):
    """把两段合成文本塞进临时 G0/G1 目录，跑真判据。"""
    with tempfile.TemporaryDirectory() as d:
        d0 = pathlib.Path(d) / 'g0'; d0.mkdir()
        d1 = pathlib.Path(d) / 'g1'; d1.mkdir()
        (d0 / f'{name}.sv').write_text(a)
        (d1 / f'{name}.sv').write_text(b)
        old0, old1 = M.G0, M.G1
        M.G0, M.G1 = d0, d1
        try:
            return M.check(name, allow_child_renumber=allow_child_renumber)
        finally:
            M.G0, M.G1 = old0, old1


print('P1 —— 只改端口位宽必须被拒（老版本会放行，生成位宽还是旧值的核）')
v = syn_check(SYN_A, SYN_B_WIDTH)
expect(not v.ok, 'width-only change is REJECTED')
expect(any('WIDTH' in r for r in v.reasons), 'rejection names the WIDTH criterion')
expect([n for n, _, _ in v.detail['width_chg']] == ['io_in_source', 'io_out_source'],
       'the two changed ports are listed by name')
expect(v.detail['body_equal_after_normalisation'],
       'body itself IS identical -- i.e. only P1 catches this case')

print('P1 —— 只改端口方向必须被拒')
v = syn_check(SYN_A, SYN_A.replace('output [2:0]  io_out_source',
                                   'input  [2:0]  io_out_source'))
expect(not v.ok and any('DIRECTION' in r for r in v.reasons),
       'direction-only change is REJECTED')

print('P2 —— 只差随机化块大小必须被放行')
expect(M.strip_randomize(SYN_C) == M.strip_randomize(SYN_D),
       'strip_randomize makes the two randomize blocks equal')
v = syn_check(SYN_C, SYN_D)
expect(v.ok, 'randomize-block-only difference is ACCEPTED')
print('P2 —— 不剥随机化块就会误判（证明这一步确实在起作用）')
expect(SYN_C != SYN_D and 'ENABLE_INITIAL_REG_' in SYN_C,
       'the two samples really do differ before stripping')

print('P3 —— 兄弟实例整体下移一号：按实例名配对必须求出正确的映射')
pt0, b0 = M.module_span(SYN_E, 'T')
pt1, b1 = M.module_span(SYN_F, 'T')
mapping, problems = M.child_rename_map(b0, b1)
expect(mapping == {'Arb_31': 'Arb_30', 'Arb_30': 'Arb_29'} and not problems,
       'instance-name pairing gives {Arb_31->Arb_30, Arb_30->Arb_29}')
expect(M.instances(b0) == {'txdatArb': 'Arb_31', 'txreqArb': 'Arb_30'},
       'instance table is parsed by instance name')
# 家族叉积配对（错法）：只知道 {Arb_30,Arb_31} -> {Arb_29,Arb_30}，
# 4 个候选里只有一个是对的，另外三个代入后 diff 不归零。
fam_candidates = [{a: b} for a in ('Arb_30', 'Arb_31') for b in ('Arb_29', 'Arb_30')]
expect(sum(1 for c in fam_candidates
           if M.norm_body(M.simul_sub(b0, c)) == M.norm_body(b1)) == 0,
       'family cross-product pairing never reaches the G1 body on its own')

print('P3 —— 替换必须是同时替换（链式替换会把 _31→_30 的结果再喂给 _30→_29）')
import re as _re
chained = b0
for k, val in mapping.items():          # 故意用错法：逐条 re.sub
    chained = _re.sub(rf'\b{k}\b', val, chained)
expect('Arb_29' in chained and 'Arb_30' not in chained,
       'chained substitution collapses BOTH instances onto Arb_29 (the bug)')
simul = M.simul_sub(b0, mapping)
expect(M.norm_body(simul) == M.norm_body(b1),
       'simultaneous substitution reaches the G1 body exactly')
expect(M.norm_body(chained) != M.norm_body(b1),
       'chained substitution does NOT reach the G1 body (this is the bug it guards)')

print('P3 —— 未声明 --allow-child-renumber 时，子模块改名必须被拒')
v = syn_check(SYN_E, SYN_F)
expect(not v.ok and any('child modules renamed' in r for r in v.reasons),
       'child renumber without the flag is REJECTED')
v = syn_check(SYN_E, SYN_F, allow_child_renumber=True)
expect(v.ok, 'child renumber WITH the flag is ACCEPTED')

print('P3 —— 实例增删必须被拒（那是结构改动，不是重编号）')
v = syn_check(SYN_E, SYN_F.replace('  Arb_29 txreqArb (\n    .clock (clock)\n  );\n', ''),
              allow_child_renumber=True)
expect(not v.ok and any('instances only in G0' in r for r in v.reasons),
       'dropping an instance is REJECTED')

# ---------------------------------------------------------------------------
# 真 golden 回归
# ---------------------------------------------------------------------------
print('真 golden 回归')
if (M.G0 / 'TLBuffer_6.sv').exists() and (M.G1 / 'TLBuffer_6.sv').exists():
    v = M.check('TLBuffer_6')
    expect(not v.ok and v.detail['width_chg'],
           'TLBuffer_6 (TileLink source 3->5 bits) is REJECTED by P1')
if (M.G0 / 'ICacheCtrlUnit.sv').exists():
    v = M.check('ICacheCtrlUnit', allow_child_renumber=True)
    expect(not v.ok and [n for n, _, _ in v.detail['width_chg']] ==
           ['auto_in_a_bits_source', 'auto_in_d_bits_source'],
           'ICacheCtrlUnit is REJECTED by P1 even though its body is clean '
           '(D_DEPRENUM + port width change)')
    expect(v.detail['body_equal_after_normalisation'],
           'ICacheCtrlUnit body IS clean after child rename -- only P1 catches it')
if (M.G0 / 'RNXbar.sv').exists():
    v = M.check('RNXbar', allow_child_renumber=True)
    expect(v.ok and len(v.detail['child_rename']) == 6,
           'RNXbar is ACCEPTED with 6 child renames (15 instances) under P3')
    v = M.check('RNXbar')
    expect(not v.ok, 'RNXbar without --allow-child-renumber is REJECTED')
def _diff_lines(a, b):
    import difflib
    return sum(1 for l in difflib.unified_diff(a.splitlines(), b.splitlines(), n=0)
               if (l[:1] in '+-') and not l.startswith(('---', '+++')))


def _resid(name, strip):
    t0 = (M.G0 / f'{name}.sv').read_text(errors='replace')
    t1 = (M.G1 / f'{name}.sv').read_text(errors='replace')
    _, b0 = M.module_span(t0, name)
    _, b1 = M.module_span(t1, name)
    import re as _r

    def nb(x):
        s = M.strip_randomize(x) if strip else x
        s = M.strip_passthrough(s)
        s = _r.sub(r'\n\s*\n+', '\n', s)
        return M.SCALA.sub('.scala:0', s)
    return _diff_lines(nb(b0), nb(b1))


# P2 在真 golden 上的效果：残余 diff 必须严格变小（不剥掉就会把纯接口增量
# 误判成真逻辑改动）。注意：剥随机化块**不足以**让 NPC 家族归零 —— 归零还需
# 端口归因过滤（A2 判据）；这里只断言 P2 这一步本身确实有效。
for _n, _lo, _hi in (('NewPipelineConnectPipe_9', 20, 40),
                     ('Predictor', 40, 80)):
    if (M.G0 / f'{_n}.sv').exists() and (M.G1 / f'{_n}.sv').exists():
        _a, _b = _resid(_n, False), _resid(_n, True)
        expect(_b < _a and _lo <= _b <= _hi,
               f'{_n}: P2 shrinks residual diff {_a} -> {_b} (expected {_lo}..{_hi})')

# ---------------------------------------------------------------------------
# P4：同名但内容变了的子模块
# ---------------------------------------------------------------------------
print('P4 —— 子模块没改名但 golden 内容变了，必须被拒（这条是 UT 抓出来的真事故）')


def syn_check_with_child(parent_a, parent_b, child_a, child_b,
                         child='Child', **kw):
    """父模块两侧完全一样，只有子模块的 golden 内容变了。"""
    import tempfile as _tf
    with _tf.TemporaryDirectory() as d:
        d0 = pathlib.Path(d) / 'g0'; d0.mkdir()
        d1 = pathlib.Path(d) / 'g1'; d1.mkdir()
        (d0 / 'T.sv').write_text(parent_a)
        (d1 / 'T.sv').write_text(parent_b)
        (d0 / f'{child}.sv').write_text(child_a)
        (d1 / f'{child}.sv').write_text(child_b)
        o0, o1 = M.G0, M.G1
        M.G0, M.G1 = d0, d1
        try:
            return M.check('T', **kw)
        finally:
            M.G0, M.G1 = o0, o1


PARENT = """\
module T(
  input  clock
);
  Child u_c (
    .clock (clock)
  );
endmodule
"""
CHILD_A = "module Child(\n  input clock\n);\n  wire sel = 7'h46;\nendmodule\n"
CHILD_B = "module Child(\n  input clock\n);\n  wire sel = 7'h4C;\nendmodule\n"

v = syn_check_with_child(PARENT, PARENT, CHILD_A, CHILD_B)
expect(not v.ok and any('P4' in r for r in v.reasons),
       'a same-named child whose golden content changed is REJECTED')
expect(v.detail['body_equal_after_normalisation'] and not v.detail['child_rename'],
       'the parent body IS identical and there is NO rename -- P1/P2/P3 are all '
       'blind to this case, only P4 sees it')
expect(v.detail['kept_name_children_changed'] == [('Child', 'golden content changed')],
       'the offending child is named in the verdict')

v = syn_check_with_child(PARENT, PARENT, CHILD_A, CHILD_B,
                         child_blackboxed=['Child'])
expect(v.ok, 'declaring the child black-boxed (shared G1 definition) ACCEPTS it')

v = syn_check_with_child(PARENT, PARENT, CHILD_A, CHILD_A)
expect(v.ok, 'an unchanged same-named child needs no declaration')

print('P4 —— 真 golden 回归')
if (M.G0 / 'ITTageTable.sv').exists():
    v = M.check('ITTageTable', allow_child_renumber=True)
    expect(not v.ok and v.detail['kept_name_children_changed'] ==
           [('MbistPipeIttage', 'golden content changed')],
           'ITTageTable is REJECTED by P4 (MbistPipeIttage MBIST array id 0x46->0x4C); '
           'the readable impl re-implements that child, so the stale parameter '
           'was a real UT failure')
    v = M.check('ITTageTable', allow_child_renumber=True,
                child_blackboxed=['MbistPipeIttage'])
    expect(v.ok, 'ITTageTable passes once MbistPipeIttage is declared handled')
if (M.G0 / 'SubDirectory.sv').exists():
    v = M.check('SubDirectory', allow_child_renumber=True)
    expect(not v.ok and v.detail['kept_name_children_changed'] ==
           [('MaxPeriodFibonacciLFSR_3', 'golden content changed')],
           'SubDirectory is flagged by P4 too (lfsr_prng changed) -- there it IS '
           'black-boxed, so the flag is an acknowledgement, not a bug')

print()
print(f'{len(RAN)} checks, {len(FAILS)} failures')
if FAILS:
    for f in FAILS:
        print('  FAILED:', f)
    sys.exit(1)
print('ALL CRITERIA TESTS PASSED')
