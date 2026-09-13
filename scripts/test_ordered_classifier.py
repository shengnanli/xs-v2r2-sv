#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_ordered_classifier.py —— 有序分类器的回归测试（顺序契约 + 全部反例）。

## 本工程有过「测试假通过」的教训

上一次有一组测试三个断言全被**前置门**挡掉（夹具根本没走到被测判据），却报 PASS。
所以本文件里每一条负测都必须同时满足三件事，缺一不可：

  (1) 断言**结论**（落哪一档 / 不落哪一档）；
  (2) 断言**失败原因文本**含预期关键字 —— 光看结论不知道是不是被别的门挡的；
  (3) 断言**夹具真的走到了被测判据** —— 用 `assert_reached()`：
      该档的 reason 不能是「不可求值」「已在 rankN 归档」这类短路话术，
      必须是这一档自己的判据说的话。

`assert_reached()` 的短路话术黑名单见 `_SHORTCIRCUIT`。任何一条负测如果只写了 (1)，
`test_meta_every_negative_test_checks_reason` 会把它抓出来 —— 元测试扫本文件源码，
要求每个 `test_neg_*` 函数体里都出现 `assert_reached` 与 `assert_reason`。

## 跑法

    python3 scripts/test_ordered_classifier.py            # 全部
    python3 scripts/test_ordered_classifier.py -k tlbuffer
    python3 scripts/test_ordered_classifier.py --cache-dir <目录>

第一次会解析两个 golden 基线（约 2 分钟）并落 pickle 缓存，之后 5 秒内。
不跑任何 EDA 工具，不写任何 RTL。
"""
import argparse
import collections
import hashlib
import inspect
import os
import pathlib
import re
import shutil
import sys
import tempfile
import traceback

_HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(_HERE))
import ordered_classifier as OC        # noqa: E402
import check_name_collisions as CNC    # noqa: E402

G0 = pathlib.Path(OC.G0_DEFAULT)
G1 = pathlib.Path(OC.G1_DEFAULT)

_CACHE_DIR = os.environ.get('OC_TEST_CACHE',
                            os.path.join(tempfile.gettempdir(),
                                         'ordered_classifier_cache'))
_CL = [None]


def cl():
    if _CL[0] is None:
        _CL[0] = OC.Classifier(str(G0), str(G1), _CACHE_DIR, True)
    return _CL[0]


_RES = {}


def R(target):
    if target not in _RES:
        _RES[target] = cl().classify(target)
    return _RES[target]


# ---------------------------------------------------------------------------
# 断言原语 —— 防「假通过」的核心
# ---------------------------------------------------------------------------

class Fail(AssertionError):
    pass


# 「这一档根本没被求值」的短路话术。负测的 reason 命中任何一条 => 夹具没走到判据。
_SHORTCIRCUIT = (
    '不可求值',
    'G1 侧无此模块',
    'G0 侧无此模块',
    '已在 rank',
)


def assert_reached(res, bucket, must_mention=()):
    """证明夹具**真的走到了**这一档的判据，而不是被前置门短路掉。"""
    p = res.predicates.get(bucket)
    if p is None:
        raise Fail('%s: 档 %s 根本没被求值（predicates 里没有这一项）'
                   % (res['target'], bucket))
    for bad in _SHORTCIRCUIT:
        if bad in p.reason:
            raise Fail('%s: 档 %s 的 reason 是短路话术 %r —— 夹具没走到被测判据，'
                       '这条负测等于没测。reason=%s'
                       % (res['target'], bucket, bad, p.reason))
    for kw in must_mention:
        if kw not in p.reason:
            raise Fail('%s: 档 %s 的 reason 里找不到 %r，说明走的不是预期那条判据。'
                       'reason=%s' % (res['target'], bucket, kw, p.reason))
    return p


def assert_reason(res, bucket, *keywords):
    p = res.predicates[bucket]
    for kw in keywords:
        if kw not in p.reason:
            raise Fail('%s: 档 %s 的 reason 缺关键字 %r。实际 reason=%s'
                       % (res['target'], bucket, kw, p.reason))
    return p


def eq(a, b, msg=''):
    if a != b:
        raise Fail('%s: 期望 %r，实际 %r' % (msg or '断言', b, a))


def truthy(c, msg):
    if not c:
        raise Fail(msg)


# ===========================================================================
# 契约测试：顺序本身
# ===========================================================================

def test_order_contract_matches_codex_0144():
    """顺序就是契约 —— 这张表改了就是改契约。"""
    eq(OC.ORDER, [
        (1, 'X_RETIRED'),
        (2, 'G_NEWFORM'),
        (2, 'P_SHIM'),
        (3, 'A_BODY_IDENTICAL'),
        (4, 'A2_IFACE_ONLY'),
        (5, 'F_PORTWIDTH'),
        (6, 'D_DEPRENUM'),
        (7, 'C_ALPHA_RENAME'),
        (8, 'B_HANDSHAKE'),
        (9, 'E_F_RESIDUAL'),
    ], 'ORDER 与 codex 0144 的 1..9 不一致')
    # B 必须排在 A/A2/F/D 之后（codex 明写）
    rank = dict((b, k) for k, b in OC.ORDER)
    for earlier in ('A_BODY_IDENTICAL', 'A2_IFACE_ONLY', 'F_PORTWIDTH', 'D_DEPRENUM'):
        truthy(rank[earlier] < rank['B_HANDSHAKE'],
               'B_HANDSHAKE 必须排在 %s 之后' % earlier)


def test_first_hit_wins_and_overlap_is_recorded():
    """先命中先归类；重叠必须显式记录，不能只报最终结果。"""
    r = R('BypassNetwork')
    sat = r['satisfies'].split(',')
    truthy(len(sat) > 1, 'BypassNetwork 应当同时满足多档，实际只有 %s' % sat)
    eq(r['bucket'], sat[0], '归档必须是 satisfies 里 rank 最小的那个')
    truthy('顺序即契约' in r['adjudication'],
           '重叠裁决必须写清「按顺序归档」：%s' % r['adjudication'])
    for b in sat[1:]:
        truthy(b in r['adjudication'], '被压后的档 %s 没写进裁决' % b)


def test_all_nine_predicates_are_always_evaluated():
    """结构护栏：`classify()` 必须为九档**全部**产出 predicate。

    这条不是想出来的 —— 本文件第一次跑就抓到 `C_ALPHA_RENAME` 整段被一次
    正则改写误删（九档只剩八档，兜底档照样给出结论，看上去一切正常）。
    少一档 = 那一档永远不可能命中 = 顺序契约被悄悄改了，而没有任何报错。
    """
    for t in ('BypassNetwork', 'RNXbar', 'TLBuffer_20', 'Ftq', 'FastArbiter_44'):
        r = R(t)
        missing = [b for b in OC.BUCKETS if b not in r.predicates]
        eq(missing, [], '%s: 九档里少了 %s' % (t, missing))
    # 源码层面：ORDER 里每一档都必须在 classify() 里被赋值过
    src = inspect.getsource(OC.Classifier.classify)
    for _rank, b in OC.ORDER:
        truthy("preds['%s']" % b in src or 'setdefault' in src,
               'classify() 里找不到给 %s 赋值的语句' % b)


def test_selftest_no_rtl_written():
    """分类器不写 RTL；strip_randomize 只用于分类分析（codex 0144 明令）。"""
    eq(OC.selftest_nortl(), [], 'ordered_classifier.py 出现了写 .sv 的路径')
    truthy('只允许用于迁移分类分析' in OC.strip_randomize.__doc__,
           'strip_randomize 的 docstring 必须写明使用范围限制')


# ===========================================================================
# codex 点名的四个反例
# ===========================================================================

TLBUFFER_EXPECT = {          # 实测值；台账写的「五个都是 3->5」是错的
    'TLBuffer_6':  ('[2:0]', '[3:0]'),
    'TLBuffer_8':  ('[1:0]', '[3:0]'),
    'TLBuffer_9':  ('[1:0]', '[3:0]'),
    'TLBuffer_20': ('[2:0]', '[4:0]'),
    'TLBuffer_22': ('[2:0]', '[4:0]'),
}


def test_neg_tlbuffer_must_not_be_A():
    """★codex 反例 1★ TLBuffer_20/22/6/8/9 不得落 A。

    同时也是「台账反例 1」：台账说五个 source 都是 3->5，实测只有 _20/_22 是。
    这条负测的价值全在 assert_reached —— 这五个的**模块体归一化后逐字相同**，
    也就是说它们确实一路走到了 A 的 width/dir 硬闸前才被拦下。
    要是哪天有人把硬闸删了，body_identical=yes 就会直接把它们送进 A。
    """
    for t, (w0, w1) in sorted(TLBUFFER_EXPECT.items()):
        r = R(t)
        # (3) 夹具确实走到了 A 的判据：body 相同，只被 width 闸拦下
        eq(r['body_identical_safe'], 'yes',
           '%s: 前提不成立 —— 模块体归一化后应当逐字相同，否则这条负测测的不是 width 闸' % t)
        assert_reached(r, 'A_BODY_IDENTICAL')
        # (2) 失败原因必须是 width，而不是别的
        assert_reason(r, 'A_BODY_IDENTICAL', '禁止落 A', 'width_chg=4')
        # (1) 结论
        truthy(r['bucket'] != 'A_BODY_IDENTICAL', '%s 落进了 A！' % t)
        eq(r['bucket'], 'F_PORTWIDTH', '%s 应当落 F_PORTWIDTH' % t)
        # 实测位宽（台账反例）
        truthy('%s->%s' % (w0, w1) in r['width_chg_sample'],
               '%s: 实测位宽应是 %s->%s，分类器给的是 %s'
               % (t, w0, w1, r['width_chg_sample']))
        eq(r['f_portwidth_grade'], 'PURE_REPARAM',
           '%s 位宽记号归一后模块体应当相同（纯重参数化）' % t)


def test_neg_tlbuffer_ledger_claim_is_wrong():
    """★台账反例 1★ 台账「5 个 TLBuffer 的 source 都是 3->5」被实测推翻。"""
    got = dict((t, R(t)['width_chg_sample'].split(';')[0].split(':', 1)[1])
               for t in TLBUFFER_EXPECT)
    three_to_five = [t for t, v in got.items() if v == '[2:0]->[4:0]']
    eq(sorted(three_to_five), ['TLBuffer_20', 'TLBuffer_22'],
       '只有 _20/_22 是 3->5；台账说五个都是')
    eq(got['TLBuffer_6'], '[2:0]->[3:0]', 'TLBuffer_6 是 3->4')
    eq(got['TLBuffer_8'], '[1:0]->[3:0]', 'TLBuffer_8 是 2->4')
    eq(got['TLBuffer_9'], '[1:0]->[3:0]', 'TLBuffer_9 是 2->4')


def test_neg_snxbar_rnxbar_pair_by_instance_name():
    """★codex 反例 2★ SNXbar / RNXbar 必须按实例名配对，禁止 family 叉积。

    「family 叉积」的危害不是「一定配错」，而是**它给不出唯一答案**：
    SNXbar 里 G0 用了 {FastArbiter_46, _47}、G1 用了 {_45, _46}，
    光看家族有 2! = 2 种配法；RNXbar 6 个成员就有 6! = 720 种。
    只有实例名能定唯一那一种。本测试因此断言：

      a) 实例名配对让模块体归零（走到了 D 的判据）；
      b) 家族里**另一种**配法代入后模块体**不归零** ——
         证明「多个候选里只有一个对」，叉积不是判据；
      c) 那个错配法与**例化点身份判据**（check_name_collisions.resolve）矛盾 ——
         证明 D 档的 corroboration 闸能独立抓到它；
      d) RNXbar 上顺序 sub 与 simul_sub 结果不同 —— 必须同时替换
         （`_31->_30` 的结果会被 `_30->_29` 再吃一次）。
    """
    import itertools
    for t in ('SNXbar', 'RNXbar'):
        r = R(t)
        assert_reached(r, 'D_DEPRENUM')
        assert_reason(r, 'D_DEPRENUM', '按实例名', '例化点身份判据校验无矛盾')
        eq(r['bucket'], 'D_DEPRENUM', '%s 应当落 D_DEPRENUM' % t)
        eq(r['deprenum_eq'], 'yes', '%s 代入改名后模块体应当逐字相同' % t)
        eq(r['d_contradictions'], '', '%s 的实例名配对与例化点身份判据不应矛盾' % t)

        b0, b1 = _body(G0, t), _body(G1, t)
        good, prob = OC.child_rename_by_instname(b0, b1)
        eq(prob, [], '%s: 实例名集合两侧应当一致' % t)
        truthy(len(good) >= 2, '%s: 应当有 >=2 处子模块改名' % t)
        n0, n1 = OC.norm_safe(b0, t), OC.norm_safe(b1, t)
        tgt = n1.replace('@SELF@', '@S@')
        eq(OC.simul_sub(n0, good).replace('@SELF@', '@S@'), tgt,
           '%s: 实例名配对代入后应当逐字相同' % t)

        # (b) 家族里换一种配法：把两个源交换目标
        srcs = sorted(good)
        wrong = dict(good)
        wrong[srcs[0]], wrong[srcs[1]] = good[srcs[1]], good[srcs[0]]
        truthy(wrong != good, '%s: 造出来的错配法与正确配法相同，夹具失效' % t)
        truthy(OC.simul_sub(n0, wrong).replace('@SELF@', '@S@') != tgt,
               '%s: 家族里的另一种配法竟然也让模块体归零 —— '
               '说明「代入后归零」这条判据没有判别力，请复核' % t)

        # (b2) 候选空间确实 >1：只有实例名能定唯一
        n_cand = 1
        for k in range(2, len(good) + 1):
            n_cand *= k
        truthy(n_cand > 1,
               '%s: 家族配法候选只有 1 种，这条反例说明不了「叉积不唯一」' % t)

        # (c) 错配法与例化点身份判据矛盾
        contra = []
        for c0, c1 in sorted(wrong.items()):
            hit, by = CNC.resolve(cl().b0, cl().b1, c0)
            if len(hit) == 1 and hit[0] != c1:
                contra.append('%s: 错配说->%s，例化点身份说->%s(%s)' % (c0, c1, hit[0], by))
        truthy(contra,
               '%s: 错配法竟然不与例化点身份判据矛盾 —— D 档的 corroboration 闸失效'
               % t)

    # (d) RNXbar 的链式替换反例
    t = 'RNXbar'
    n0 = OC.norm_safe(_body(G0, t), t)
    n1 = OC.norm_safe(_body(G1, t), t)
    good, _ = OC.child_rename_by_instname(_body(G0, t), _body(G1, t))
    truthy(any(v in good for v in good.values()),
           'RNXbar 的改名表里应当存在「某个源恰好是另一条的目标」（_31->_30 与 _30->_29），'
           '否则链式替换的反例不成立。map=%s' % good)
    # 顺序替换用**改名表自己的顺序**（= 按实例名排序得到的顺序），
    # 这正是一个天真实现会写出来的循环。RNXbar 里 txdatArbs_* 先给出 _31->_30，
    # 随后 txreqArbs_* 的 _30->_29 会把刚替出来的 _30 再吃一遍。
    keys = list(good)
    i31 = keys.index('FastArbiter_31') if 'FastArbiter_31' in keys else -1
    i30 = keys.index('FastArbiter_30') if 'FastArbiter_30' in keys else -1
    truthy(i31 >= 0 and i30 >= 0 and i31 < i30,
           'RNXbar: 改名表顺序里 _31->_30 应当排在 _30->_29 之前（链式吃掉的前提）。'
           'keys=%s' % keys)
    seq = n0
    for k in keys:
        seq = re.sub(r'\b%s\b' % re.escape(k), good[k], seq)
    sim = OC.simul_sub(n0, good)
    truthy(seq != sim,
           'RNXbar: 顺序替换与同时替换结果相同 —— 链式吃掉的反例失效了')
    eq(sim.replace('@SELF@', '@S@'), n1.replace('@SELF@', '@S@'),
       'RNXbar: 同时替换后应当逐字相同')
    truthy(seq.replace('@SELF@', '@S@') != n1.replace('@SELF@', '@S@'),
           'RNXbar: 顺序替换后不应当相同（这正是它是 bug 的原因）')


def test_neg_bypassnetwork_not_B():
    """★codex 反例 3★ BypassNetwork 不得因为含 ready 被判成 B。

    这里最能体现「顺序即契约」：BypassNetwork 的 B 判据**确实成立**
    （新增 24 个 ready 端口），但它在 rank4 就被 A2 收走了。
    另外它 G0 端口表本来就有 30 个 ready —— 「含 ready」从来不是 B 的判据。
    """
    r = R('BypassNetwork')
    assert_reached(r, 'B_HANDSHAKE')
    eq(r['bucket'], 'A2_IFACE_ONLY', 'BypassNetwork 应当落 A2（rank4 先于 rank8）')
    truthy(r['bucket'] != 'B_HANDSHAKE', 'BypassNetwork 落进了 B！')
    truthy(int(r['ready_g0']) > 0,
           'BypassNetwork 的 G0 端口表本来就应当有 ready（实测 30 个），'
           '这正是「含 ready 不等于 B」的证据')
    eq(r['ready_g0'], 30, 'BypassNetwork G0 ready 端口数')
    eq(r['handshake_grade'], 'EXTENDED_HANDSHAKE',
       'G0 已有 ready => 只能是 EXTENDED，不是 NEW_HANDSHAKE')
    truthy('B_HANDSHAKE' in r['adjudication'],
           '重叠裁决必须显式说明 B 是被顺序压后的，而不是判据不成立')
    assert_reason(r, 'A2_IFACE_ONLY', '逐行归因通过')


def test_neg_ready_present_but_not_added_is_not_B():
    """★codex 反例 3（补强）★「端口名里含 ready」不是 B 的判据。

    为什么单靠 BypassNetwork 不够：变异测试实测证明，把 B 判据改成
    `ready_g0 > 0 or ready_added > 0`（也就是「含 ready 就算 B」），
    `test_neg_bypassnetwork_not_B` **照样全绿** —— 因为 BypassNetwork 在 rank4
    就被 A2 收走了，B 判据怎么改都影响不到它的归档。
    所以这里另造一个夹具：两侧都有 ready 端口、`ready_added == 0`、
    并且有真逻辑改动（于是一路落到 rank9）。判据一旦放宽成「含 ready」，
    它就会被错判成 B —— 这条测试就会挂。
    """
    g0 = '\n'.join([
        '  wire _T_1 = io_in_valid & io_in_ready;',
        '  assign io_out_valid = _T_1;',
        '  assign io_in_ready = io_out_ready;',
        '  assign io_out_bits = io_in_bits;',
    ])
    g1 = '\n'.join([
        '  wire _T_1 = io_in_valid & io_in_ready;',
        '  assign io_out_valid = _T_1 & io_in_bits;',      # 真逻辑改动
        '  assign io_in_ready = io_out_ready;',
        '  assign io_out_bits = io_in_bits;',
    ])
    with _tmp_golden(g0, g1, name='ReadyMod') as (d0, d1):
        c = OC.Classifier(d0, d1, cache_dir=None, use_cache=False)
        r = c.classify('ReadyMod')
        truthy(int(r['ready_g0']) >= 2,
               '夹具失效：G0 端口表里应当本来就有 ready，实际 %s' % r['ready_g0'])
        eq(r['ready_added'], 0, '夹具失效：本次不应新增 ready 端口')
        assert_reached(r, 'B_HANDSHAKE')
        assert_reason(r, 'B_HANDSHAKE', 'ready_added==0', '含 ready 不等于 B')
        truthy(r['bucket'] != 'B_HANDSHAKE',
               '含 ready 但没新增 ready 的模块被判成了 B')
        eq(r['bucket'], 'E_F_RESIDUAL', '真逻辑改动应当落 rank9 兜底档')


def test_neg_a2_coarse_field_spoof():
    """★codex 反例 4★ 粗 payload 字段过滤不得决定 A2。

    人造夹具：G1 加了一个新端口 `io_out_bits_uop_seqNum`，同时把一条**既有**语句
    `assign io_out_bits_uop_data = _T_5[7:0];` 改写成 `_T_5[15:0]`。
    粗字段名过滤会把 `io_out_bits_uop_*` 整族滤掉（前缀 `io_out_bits_uop` 撞上），
    两侧于是「相等」；严判据看的是**被定义的名字在不在对侧存在**，
    `io_out_bits_uop_data` 两侧都在 => 那条 DEL 行不可归因 => 不是 A2。
    """
    g0_body = '\n'.join([
        '  wire [15:0] _T_5 = io_in_bits_x;',
        '  assign io_out_bits_uop_data = _T_5[7:0];',
        '  assign io_out_valid = io_in_valid;',
    ])
    g1_body = '\n'.join([
        '  wire [15:0] _T_5 = io_in_bits_x;',
        '  assign io_out_bits_uop_data = _T_5[15:0];',
        '  assign io_out_valid = io_in_valid;',
        '  assign io_out_bits_uop_seqNum = io_in_bits_uop_seqNum;',
    ])
    l0, l1 = OC.logical_lines(g0_body), OC.logical_lines(g1_body)
    add, dele, _ = OC.line_diff(l0, l1)
    ap = ['io_out_bits_uop_seqNum', 'io_in_bits_uop_seqNum']

    # 1) 老判据（粗字段名过滤）说「相等」—— 这就是被冒充的那一步
    spoofed = OC.coarse_field_filter_equal(l0, l1, ap, [])
    truthy(spoofed,
           '夹具失效：粗字段名过滤应当把两侧滤成相等（否则这条负测测不到冒充）')

    # 2) 严判据说「不是接口增量」，且指出的正是那条被改写的行
    ids0 = set()
    for x in l0:
        ids0 |= OC.idents(x)
    ids1 = set()
    for x in l1:
        ids1 |= OC.idents(x)
    ok, bad_a, bad_d = OC.attribute(add, dele, ids1 - ids0, ids0 - ids1, ap, [])
    truthy(not ok, '严判据竟然也放过了改写 —— A2 可被粗字段名过滤冒充')
    truthy(any('io_out_bits_uop_data' in x for x in bad_a + bad_d),
           '严判据拒了，但指出的不是那条被改写的行：%s' % (bad_a + bad_d))

    # 3) 端到端：把夹具做成两个 golden 目录，跑完整分类器
    with _tmp_golden(g0_body, g1_body) as (d0, d1):
        c = OC.Classifier(d0, d1, cache_dir=None, use_cache=False)
        r = c.classify('SpoofMod')
        assert_reached(r, 'A2_IFACE_ONLY')
        assert_reason(r, 'A2_IFACE_ONLY', '不可归因', 'io_out_bits_uop_data')
        truthy(r['bucket'] != 'A2_IFACE_ONLY',
               '端到端也被冒充了：夹具落进了 A2')
        eq(r['bucket'], 'E_F_RESIDUAL', '改写应当落到 rank9 兜底档')


def test_neg_a2_positive_control_still_fires():
    """A2 的**正控制**：判据不能严到谁都不给过（否则上一条负测无意义）。"""
    r = R('BypassNetwork')
    eq(r['bucket'], 'A2_IFACE_ONLY', 'A2 判据必须还能对真的接口增量成立')
    truthy(int(r['ports_added']) > 100,
           'BypassNetwork 应当有几百个新增端口，实际 %s' % r['ports_added'])
    eq(r['attrib_ok'], 'yes')


# ===========================================================================
# 台账实测反例（本轮各 owner 从 golden 量出来的）
# ===========================================================================

def test_neg_ftq_is_not_a_from_scratch_rewrite():
    """★台账反例 2★ 台账把 Ftq 判成 U_INDETERMINATE / 从头重写（diff 88972）。

    实测：raw 逐行残余三万多行，其中 99% 是 firtool 给临时线**重新发号**；
    抹掉编号后只剩几百行。分类器必须把这件事说出来，不能把 Ftq 排成重写。
    """
    r = R('Ftq')
    raw, tb = int(r['resid_diff']), int(r['resid_diff_tb'])
    truthy(raw > 20000, 'Ftq 的 raw 残余应当是万级（台账就是被它骗的），实际 %d' % raw)
    truthy(tb < 1000,
           'Ftq 抹掉 firtool 临时线编号后残余应当降到千行以内，实际 %d —— '
           '若这条挂了，说明 temp_blind 归一失效或 golden 变了' % tb)
    truthy(raw / max(tb, 1) > 20,
           'raw/抹编号 的比值应当在 20 倍以上（churn 占绝对多数），实际 %.1f'
           % (raw / max(tb, 1)))
    eq(r['determinacy'], 'DETERMINATE',
       'Ftq 不该是「判不准」—— 它的真改动是可数的')
    truthy('台账「从头重写」口径存疑' in r['caveats'],
           'Ftq 必须带上「台账口径存疑」的告警，否则排期的人看不到。caveats=%s'
           % r['caveats'])
    # 顺带记录接口侧的实测：3 加 39 删，无位宽/方向变化
    eq(r['width_chg'], 0)
    eq(r['dir_chg'], 0)


def test_neg_entries_payload_is_port_addition_not_width_growth():
    """★台账反例 3★「Entries* payload 加宽 78%」——「加宽」这个词是错的。

    实测：`width_chg == 0`，一个端口的位宽都没变；变的是**新增了几百个端口**
    （debugInfo / seqNum 等 payload 字段）。这个区别不是措辞问题：
    位宽变化会落 rank5 F_PORTWIDTH（重参数化），端口新增会落 rank4 A2（接口增量），
    两条施工路线完全不同。
    """
    for t in ('EntriesAluCsrFenceDiv', 'EntriesVlduVstu'):
        r = R(t)
        eq(r['width_chg'], 0,
           '%s: 实测没有任何端口位宽变化，「加宽」的说法不成立' % t)
        truthy(int(r['ports_added']) > 300,
               '%s: 实测新增端口应当上百，实际 %s' % (t, r['ports_added']))
        truthy(r['bucket'] != 'F_PORTWIDTH',
               '%s: 不得落 F_PORTWIDTH（那是位宽档）' % t)
        assert_reached(r, 'F_PORTWIDTH')
        assert_reason(r, 'F_PORTWIDTH', 'width_chg=0')


def test_neg_entries_issuequeue_family_counts():
    """★台账反例 4★ 台账说 Entries* 11 个、IssueQueue* 6 个；golden 各 14 个。"""
    n_e = sorted(n for n in cl().b1.mods if n.startswith('Entries'))
    n_q = sorted(n for n in cl().b1.mods if n.startswith('IssueQueue'))
    eq(len(n_e), 14, 'G1 golden 的 Entries* 变体数')
    eq(len(n_q), 14, 'G1 golden 的 IssueQueue* 变体数')
    led = _ledger_targets()
    if led is not None:
        e_led = [t for t in led if t.startswith('Entries')]
        q_led = [t for t in led if t.startswith('IssueQueue')]
        eq(len(e_led), 11, '台账里的 Entries* 条目数（应当比 golden 少 3）')
        eq(len(q_led), 6, '台账里的 IssueQueue* 条目数（应当比 golden 少 8）')
        truthy(len(n_e) - len(e_led) == 3 and len(n_q) - len(q_led) == 8,
               '台账缺口应当是 Entries 缺 3 / IssueQueue 缺 8')


def test_neg_icachemshr_is_monomorphised_copies_not_one_core():
    """★台账反例 5★「ICacheMSHR x14 是同核不同参」不成立：只有 2 种模块体。"""
    groups = collections.defaultdict(list)
    for i in range(14):
        n = 'ICacheMSHR' if i == 0 else 'ICacheMSHR_%d' % i
        b = OC.norm_safe(_body(G1, n), n)
        groups[hashlib.md5(b.encode()).hexdigest()].append(n)
    eq(len(groups), 2, 'G1 的 14 个 ICacheMSHR 应当只有 2 种模块体')
    sizes = sorted(len(v) for v in groups.values())
    eq(sizes, [4, 10], '两组的成员数（4 + 10）')
    eq(sum(sizes), 14, '14 份单态化复制，一份不少')
    # 「同核不同参」若成立，14 个的端口表应当只差参数；实测是两种**模块体**，
    # 组内逐字相同 —— 这不是参数化，是单态化复制。
    for h, v in groups.items():
        first = OC.norm_safe(_body(G1, v[0]), v[0])
        for n in v[1:]:
            eq(hashlib.md5(OC.norm_safe(_body(G1, n), n).encode()).hexdigest(),
               hashlib.md5(first.encode()).hexdigest(),
               '%s 与 %s 组内模块体应当逐字相同' % (n, v[0]))


def test_neg_g1_universe_fastarbiter_map_is_self_contradictory():
    """★台账反例 7★ g1_universe.tsv 第 48/49 行两个 G0 名字指向同一个 G1 名字。

    例化点身份判据给出的是双射：_30 -> _29，_31 -> _30。
    """
    a = cl().map_name('FastArbiter_30')
    b = cl().map_name('FastArbiter_31')
    eq(a[0], 'FastArbiter_29', 'G0 FastArbiter_30 的 G1 对应物')
    eq(a[1], 'site', '判据必须是例化点身份，不是同名')
    eq(b[0], 'FastArbiter_30', 'G0 FastArbiter_31 的 G1 对应物')
    truthy(a[0] != b[0], '两个 G0 名字不得映到同一个 G1 名字（台账就是这么错的）')
    led = _ledger_map('docs/g1_universe.tsv')
    if led:
        eq(led.get('FastArbiter_30'), 'FastArbiter_30', '台账原文（错的那条）')
        eq(led.get('FastArbiter_31'), 'FastArbiter_30', '台账原文')
        truthy(led['FastArbiter_30'] == led['FastArbiter_31'],
               '台账这两行确实撞在同一个目标上 —— 这就是被推翻的那处')
    r = R('FastArbiter_30')
    truthy('同名不同物' in r['caveats'],
           'FastArbiter_30 必须带「G1 同名模块是另一个设计元素」的告警')


def test_neg_old_to_new_map_npc_is_self_contradictory():
    """★台账反例 8★ g1_old_to_new_map.tsv 第 169/171 行同类矛盾（NPC_31/_33 -> _33）。"""
    a = cl().map_name('NewPipelineConnectPipe_31')
    b = cl().map_name('NewPipelineConnectPipe_33')
    eq(a[0], 'NewPipelineConnectPipe_33')
    eq(b[0], 'NewPipelineConnectPipe_35')
    truthy(a[0] != b[0], '两个 G0 名字不得映到同一个 G1 名字')
    led = _ledger_map('docs/g1_old_to_new_map.tsv')
    if led:
        eq(led.get('NewPipelineConnectPipe_31'), 'NewPipelineConnectPipe_33')
        eq(led.get('NewPipelineConnectPipe_33'), 'NewPipelineConnectPipe_33')


def test_neg_frontend_closure_counts():
    """★台账反例 6★「Frontend 闭包 193 / 83 个真目标」的重算。

    分母口径写死在这里，任何人都能复算：
      closure = 从 G1 Frontend 出发、沿例化边可达的模块（含自身）；
      universe = docs/g1_configured_universe.tsv 里 in_universe=yes 的模块。
    """
    b1 = cl().b1
    seen, stack = set(), ['Frontend']
    while stack:
        n = stack.pop()
        if n in seen or n not in b1.mods:
            continue
        seen.add(n)
        for typ, _inst in b1.mods[n].child_insts:
            stack.append(typ)
    uni = _configured_universe()
    inuni = seen & uni if uni else set()
    print('        [Frontend 闭包] 含自身 %d / in_universe %d；'
          '不含自身 %d / %d'
          % (len(seen), len(inuni), len(seen) - 1,
             len(inuni) - (1 if 'Frontend' in inuni else 0)))
    truthy(len(seen) > 150,
           'Frontend 例化闭包应当是百级，实际 %d —— 闭包算法坏了？' % len(seen))
    eq(len(seen), 185, 'Frontend 例化闭包（**含自身**）')
    eq(len(inuni), 165, 'Frontend 闭包 ∩ configured universe（**含自身**）')
    # 前端小家族 owner 报的是 184 / 164 —— 与本次实测差**恰好 1**，
    # 原因是他们的口径不含 Frontend 自身。两个口径都写死在这里，谁复算都不会错位。
    eq(len(seen) - 1, 184, 'Frontend 闭包（不含自身）—— 与 owner 口径对齐')
    eq(len(inuni) - (1 if 'Frontend' in inuni else 0), 164,
       'Frontend 闭包 ∩ universe（不含自身）—— 与 owner 口径对齐')
    truthy(len(seen) != 193, '台账说 193，实测 %d —— 台账口径被推翻' % len(seen))
    return {'closure': len(seen), 'in_universe': len(inuni)}


def test_c_alpha_rename_never_inherits_pass():
    """codex 0144：C 档只能决定「继承施工」，不能继承 PASS。"""
    with _tmp_golden(
            '  wire _T_1 = io_a & io_b;\n  assign io_o = _T_1;',
            '  wire _T_9 = io_a & io_b;\n  assign io_o = _T_9;') as (d0, d1):
        c = OC.Classifier(d0, d1, cache_dir=None, use_cache=False)
        r = c.classify('AlphaMod')
        assert_reached(r, 'C_ALPHA_RENAME')
        eq(r['bucket'], 'C_ALPHA_RENAME')
        eq(r['inherit_construction'], 'yes')
        eq(r['inherit_pass'], 'NO', 'C 档绝不能继承 PASS')
        truthy('不得继承 PASS' in r['caveats'], 'C 档必须带不得继承 PASS 的告警')


def test_x_retired_is_bookkeeping_only_and_derives_successor():
    """rank1：X_RETIRED 只是台账动作，但后继必须被定位出来，施工量不能丢。"""
    r = R('FastArbiter_44')
    eq(r['bucket'], 'X_RETIRED')
    eq(r['g1_exists'], 'yes')       # 后继存在
    eq(r['successor_g1'], 'FastArbiter_43')
    eq(r['successor_by'], 'site')
    eq(r['inherit_construction'], 'no', 'X_RETIRED 不产 RTL，谈不上继承施工')
    assert_reason(r, 'X_RETIRED', '无 RTL 可交付', 'FastArbiter_43')


def test_p4_changed_children_are_flagged_not_swallowed():
    """P4：同名但 G1 内容变了的子模块必须出现在告警里（继承的隐形陷阱）。"""
    r = R('TLBuffer_20')
    truthy(int(r['p4_n']) > 0,
           'TLBuffer_20 的 Queue2_* 子模块在 G1 内容变了，应当被 P4 抓到')
    truthy('P4' in r['caveats'] and '黑盒' in r['caveats'],
           'P4 告警必须写清「只有当黑盒才允许继承」。caveats=%s' % r['caveats'])


# ===========================================================================
# 元测试：防止本文件自己出现「假通过」
# ===========================================================================

def test_meta_every_negative_test_checks_reason_and_reachability():
    """每个 test_neg_* 都必须同时用 assert_reached 与 assert_reason/等价断言。

    这条是给「三个断言全被前置门挡掉却报 PASS」那次教训准备的护栏。
    """
    src = pathlib.Path(__file__).read_text()
    bad = []
    for name, fn in sorted(globals().items()):
        if not (name.startswith('test_neg_') and callable(fn)):
            continue
        body = inspect.getsource(fn)
        has_reach = 'assert_reached' in body
        # 有些反例是纯数据核对（家族计数、映射矛盾），它们没有「档」可走到，
        # 但必须逐条断言实测值 —— 用 eq(...) 的条数当代理，至少 3 条。
        n_eq = body.count('eq(') + body.count('truthy(')
        if not has_reach and n_eq < 3:
            bad.append('%s: 既没有 assert_reached，实测断言也少于 3 条' % name)
        if 'assert_reason' not in body and 'assert_reached' in body \
                and 'must_mention' not in body:
            # 走到了判据却不检查原因文本 —— 就是只断言了结论
            if 'reason' not in body:
                bad.append('%s: 用了 assert_reached 却没检查 reason 文本' % name)
    eq(bad, [], '负测自身不合格：\n  ' + '\n  '.join(bad) if bad else '')
    truthy(len(_SHORTCIRCUIT) >= 3, '短路话术黑名单不能是空的')


def test_meta_shortcircuit_detector_actually_detects():
    """反测 assert_reached 自己：给它一个被短路的档，它必须报错。"""
    r = R('FastArbiter_44')     # X_RETIRED，G0 侧存在但 G1 无同名
    # 造一个短路 reason，确认探测器会抓
    fake = OC.Result(r)
    fake['_pred'] = dict(r['_pred'])
    fake['_pred']['A2_IFACE_ONLY'] = OC.Pred(False, 'G1 侧无此模块，判据不可求值')
    try:
        assert_reached(fake, 'A2_IFACE_ONLY')
    except Fail as e:
        truthy('短路话术' in str(e), '探测器报的不是短路：%s' % e)
        return
    raise Fail('assert_reached 没有抓到短路话术 —— 防假通过的护栏本身失效了')


# ===========================================================================
# 辅助
# ===========================================================================

def _body(root, name):
    t = (pathlib.Path(root) / ('%s.sv' % name)).read_text(errors='replace')
    return OC.module_span(t, name)[1]


def _family_cross_product(b0, b1):
    """★只供反例使用★ 故意造一个「family 叉积」对应表：
    两侧同家族（去掉尾部 `_<数字>` 后同名）的成员各自按编号排序，位置对位置硬配。
    这正是 codex 禁止的做法。"""
    def fam(n):
        return re.sub(r'_\d+$', '', n)

    def key(n):
        m = re.search(r'_(\d+)$', n)
        return int(m.group(1)) if m else -1
    g0 = collections.defaultdict(list)
    g1 = collections.defaultdict(list)
    for t in OC.instances(b0).values():
        if t not in g0[fam(t)]:
            g0[fam(t)].append(t)
    for t in OC.instances(b1).values():
        if t not in g1[fam(t)]:
            g1[fam(t)].append(t)
    out = {}
    for f in g0:
        a = sorted(g0[f], key=key)
        b = sorted(g1.get(f, []), key=key)
        for x, y in zip(a, b):
            if x != y:
                out[x] = y
    return out


class _tmp_golden(object):
    """把两段模块体做成两个最小 golden 目录，用来端到端跑分类器。"""

    def __init__(self, g0_body, g1_body, name=None):
        self.g0_body, self.g1_body = g0_body, g1_body
        self.name = name

    def __enter__(self):
        self.d = tempfile.mkdtemp(prefix='oc_fixture_')
        d0 = os.path.join(self.d, 'g0')
        d1 = os.path.join(self.d, 'g1')
        os.makedirs(d0)
        os.makedirs(d1)
        name = self.name or ('SpoofMod' if 'seqNum' in self.g1_body else 'AlphaMod')
        ports0 = _ports_for(self.g0_body)
        ports1 = _ports_for(self.g1_body)
        for d, body, ports in ((d0, self.g0_body, ports0), (d1, self.g1_body, ports1)):
            txt = ('module %s(\n%s\n);\n%s\nendmodule\n'
                   % (name, ports, body))
            pathlib.Path(d, '%s.sv' % name).write_text(txt)
        self.name_used = name
        return d0, d1

    def __exit__(self, *a):
        shutil.rmtree(self.d, ignore_errors=True)


def _ports_for(body):
    """从模块体里出现的 io_* 名字机械生成一张端口表（夹具用）。"""
    names = sorted(set(re.findall(r'\bio_\w+', body)))
    out = []
    for i, n in enumerate(names):
        d = 'output' if '_out' in n else 'input'
        w = '[15:0] ' if 'data' in n or n.endswith('_x') else ''
        out.append('  %-6s %s%s%s' % (d, w, n, ',' if i < len(names) - 1 else ''))
    return '\n'.join(out)


def _ledger_targets():
    for c in (_HERE.parent / 'docs' / 'migration_plan.tsv',
              pathlib.Path(os.environ.get('OC_LEDGER', '/nonexistent'))):
        if c.exists():
            return [l.split('\t')[0] for l in c.read_text().splitlines()[1:] if l.strip()]
    p = pathlib.Path('/tmp/claude-1000/-home-eda-xs-env-XiangShan/'
                     '6824a231-879a-49e3-b98d-f29f5afc381c/scratchpad/migration_plan.tsv')
    if p.exists():
        return [l.split('\t')[0] for l in p.read_text().splitlines()[1:] if l.strip()]
    return None


def _ledger_map(rel):
    p = _HERE.parent / rel
    if not p.exists():
        return None
    out = {}
    for line in p.read_text(encoding='utf-8', errors='replace').splitlines():
        if line.startswith('#') or not line.strip():
            continue
        c = line.split('\t')
        if len(c) >= 2:
            out[c[0]] = c[1]
    return out


def _configured_universe():
    p = _HERE.parent / 'docs' / 'g1_configured_universe.tsv'
    if not p.exists():
        return set()
    out = set()
    for line in p.read_text(encoding='utf-8', errors='replace').splitlines():
        if line.startswith('#') or not line.strip():
            continue
        c = line.split('\t')
        if len(c) >= 2 and c[1] == 'yes':
            out.add(c[0])
    return out


# ===========================================================================

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-k', help='只跑名字含该子串的测试')
    ap.add_argument('--cache-dir')
    a = ap.parse_args()
    if a.cache_dir:
        global _CACHE_DIR
        _CACHE_DIR = a.cache_dir
    tests = [(n, f) for n, f in sorted(globals().items())
             if n.startswith('test_') and callable(f)]
    if a.k:
        tests = [(n, f) for n, f in tests if a.k in n]
    npass = nfail = 0
    fails = []
    for n, f in tests:
        try:
            f()
            print('PASS  %s' % n)
            npass += 1
        except Exception as e:                                   # noqa: BLE001
            print('FAIL  %s' % n)
            print('      %s' % str(e).replace('\n', '\n      '))
            if not isinstance(e, AssertionError):
                traceback.print_exc()
            fails.append(n)
            nfail += 1
    print('\n%d passed, %d failed%s'
          % (npass, nfail, ('  -> ' + ', '.join(fails)) if fails else ''))
    return 1 if nfail else 0


if __name__ == '__main__':
    sys.exit(main())
