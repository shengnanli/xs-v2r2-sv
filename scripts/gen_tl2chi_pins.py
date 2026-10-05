#!/usr/bin/env python3
"""gen_tl2chi_pins.py —— TL2CHICoupledL2 / L2Top 的 FM 钉点（verif/ut/<T>/fm_pins_pre.tcl 与 fm_pins.tcl）。

依据 codex 0215 Q2：不改共享 scripts/fm_eq.tcl，也不把 child matched.rpt 收割成几万条静态钉点；
改为「语义改名钉点（静态，复用已签 child generator 的产物）」+「目标局部的 nested-u_core 结构匹配器（动态）」。

一、fm_pins_pre.tcl（匹配前，静态，fail-closed 字面计数）——codex 0217 起 TL2CHICoupledL2 走**已证 child 的
层次化组合**：slices_0..3 / prefetcher / pCrdQueue_s2 两侧都是 green_child 黑盒（verif/allow/TL2CHICoupledL2.json
逐实例绑定证书 sha），FM 看不到 child 内部，所以这里**只剩本层**（xs_TL2CHICoupledL2_core）与 golden 异名的
寄存器：OWN_RULES，841 位。不再复用 Slice / Prefetcher 的钉点（那些点在黑盒里面）。
L2Top 把 inner_l2cache 整个当作 TL2CHICoupledL2 的 green_child，本层无异名寄存器 ⇒ 不生成钉点文件。

二、（codex 0217：已从 TL2/L2Top 正式 pin closure 移除——生产 canary matched=0。MATCHER_TCL 与
build_post/build_fixture 只作辅助保留，由 scripts/test_tl2chi_ucore_matcher.py 测；本脚本不再写出
verif/ut/<T>/fm_pins.tcl / fm_pins_fixture.tcl。）原设计：fm_pins.tcl（匹配后，动态；scripts/fm_eq.tcl 在首次 match 与 auto_match 之后 source、随后再 match）——
  nested-u_core prefix-aware matcher（codex 0215 Q2 规则 1~5）：
  1. 取当前 unmatched DFF 集合（compare 与 unread 两种状态，两侧分别查询，`-point_type dff`）；
  2. key = 相对 top 的完整路径；impl 侧**只删除名字恰为 `u_core` 的层次段**（整段相等才删，不做子串替换），
     其余祖先段原样保留（slices_2 与 slices_3 不会混）；叶名做与 fm_eq.tcl auto_match_flattened_arrays 相同的
     数组展平正规化（`name_reg[i][j]` → `name_i_j_reg`，ref 的 `name_i_reg[j]` → `name_i_j_reg`），
     叶名不是 `<名>_reg<下标…>` 形状的原样作 key；
  3. 两侧各自 key 必须唯一：同侧有重复 key（多对一 / 一对多）→ 打印明细、整份 error（不静默覆盖）；
  4. 两侧都恰有一项的 key 才 set_user_match，返回值必须为 1，否则 error；
  5. 打印 matched / ambiguous / missing_ref / missing_impl 计数（UCM_SUMMARY 行）。不做字段改名猜测、不做签名近似。
  matcher 的 Tcl 源在本文件的 MATCHER_TCL 里，两个目标生成的内容只差 top 名；它的合成用例测试在
  scripts/test_tl2chi_ucore_matcher.py（多 slice 正例 / 重复 key / 跨 slice / 非 u_core 子串 / set_user_match 失败）。
  pin_call_equiv 的夹具：verif/ut/<T>/fm_pins_fixture.tcl（由本脚本一并生成）。

用法：python3 scripts/gen_tl2chi_pins.py          # 生成 verif/ut/TL2CHICoupledL2/fm_pins_pre.tcl
      python3 scripts/gen_tl2chi_pins.py --check  # 与仓库里的文件逐字节比较，不一致 rc=1
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
OWN_EXPECT = 5 + 20 + 68 * 2 * 6       # 841
TARGETS = {'TL2CHICoupledL2': ''}
EXPECT = OWN_EXPECT                                        # 841（codex 0217 green_child 组合）


def die(msg):
    raise SystemExit('gen_tl2chi_pins: ' + msg)


# ---------------------------------------------------------------------------
# 一、语义改名（静态）
# ---------------------------------------------------------------------------
def own_rules():
    r = [('allCanFire_REG', 'u_core/noHint2_d1_reg', 1), ('allCanFire_REG_1', 'u_core/noHint2_d2_reg', 1),
         ('allCanFire_REG_2', 'u_core/noHint3_d1_reg', 1), ('allCanFire_REG_3', 'u_core/noHint3_d2_reg', 1),
         ('allCanFire_REG_4', 'u_core/noHint3_d3_reg', 1)]
    stages = ['pick2_d1', 'pick2_d2', 'pick3_d1', 'pick3_d2', 'pick3_d3']
    for i in range(4):
        for j, st in enumerate(stages):
            n = 5 * i + j
            r.append(('sliceCanFire_REG' + ('' if n == 0 else '_%d' % n), 'u_core/%s_reg[%d]' % (st, i), 1))
    for k in range(1, 69):
        r.append(('io_perf_%d_value_REG' % k, 'u_core/perf_d1_reg[%d]' % (k - 1), 6))
        r.append(('io_perf_%d_value_REG_1' % k, 'u_core/perf_d2_reg[%d]' % (k - 1), 6))
    return r


def golden_regs(mod):
    t = open(os.path.join(G, mod + '.sv')).read()
    i = t.index('\nmodule %s(' % mod)
    return {m.group(2): 1 if m.group(1) is None else int(m.group(1)) + 1
            for m in re.finditer(r'^  reg\s+(?:\[(\d+):0\]\s+)?(\w+);', t[i:], re.M)}


def static_pairs(top, pfx):
    """[(ref 相对 top, impl 相对 top, 宽度 0=单点)] —— 只有本层异名寄存器（child 是 green_child 黑盒）。"""
    pairs = []
    regs = golden_regs('TL2CHICoupledL2')
    n = 0
    for g, i, w in own_rules():
        if regs.get(g) != w:
            die('golden TL2CHICoupledL2 的寄存器 %s 宽 %s，规则写 %d' % (g, regs.get(g), w))
        pairs.append(('%s%s_reg' % (pfx, g), pfx + i, 0 if w == 1 else w))
        n += w
    if n != OWN_EXPECT:
        die('本层钉点 %d 位，字面期望 %d' % (n, OWN_EXPECT))
    if len({p[0] for p in pairs}) != len(pairs) or len({p[1] for p in pairs}) != len(pairs):
        die('%s：语义钉点映射不单射' % top)
    total = sum(w or 1 for _, _, w in pairs)
    if total != EXPECT:
        die('%s：本层钉点 %d 位，字面期望 %d' % (top, total, EXPECT))
    return pairs


def build_pre(top, pfx):
    pairs = static_pairs(top, pfx)
    o = ['# %s FM「匹配前」钉点（本层异名寄存器，静态）—— 自动生成：scripts/gen_tl2chi_pins.py（勿手改）' % top,
         '#',
         '# 内容 = TL2CHICoupledL2 本层（xs_TL2CHICoupledL2_core）与 golden 异名的寄存器 %d 位；child（slices_0..3 /'
         ' prefetcher / pCrdQueue_s2）是 green_child 黑盒（codex 0217），内部不配对。' % OWN_EXPECT,
         '# set_user_match 只声明两点对应，比较照比。fail-closed：逐条数返回值；拒一条或总数 != %d 即 error。' % EXPECT,
         'set ::TL2_PIN_OK 0',
         'set ::TL2_PIN_BAD 0',
         'proc tl2_pin {r i} {',
         '  if {[set_user_match "r:/WORK/%s/$r" "i:/WORK/%s/$i"]} { incr ::TL2_PIN_OK } else {' % (top, top),
         '    incr ::TL2_PIN_BAD',
         '    if {$::TL2_PIN_BAD <= 10} { puts "TL2_PIN_FAIL: $r <-> $i" }',
         '  }',
         '}',
         'proc tl2_pinw {r i w} {',
         '  for {set b 0} {$b < $w} {incr b} { tl2_pin "${r}\\[$b\\]" "${i}\\[$b\\]" }',
         '}',
         'puts "TL2_PIN_BEGIN %s expect=%d"' % (top, EXPECT)]
    for r, i, w in pairs:
        o.append(('tl2_pin {%s} {%s}' % (r, i)) if w == 0 else ('tl2_pinw {%s} {%s} %d' % (r, i, w)))
    o += ['puts "TL2_PIN_END %s ok=$::TL2_PIN_OK bad=$::TL2_PIN_BAD"' % top,
          'if {$::TL2_PIN_BAD != 0 || $::TL2_PIN_OK != %d} {' % EXPECT,
          '  error "TL2_PIN_MISMATCH ok=$::TL2_PIN_OK bad=$::TL2_PIN_BAD expect=%d"' % EXPECT,
          '}']
    return '\n'.join(o) + '\n'


# ---------------------------------------------------------------------------
# 二、nested-u_core 结构匹配器（动态，匹配后）
# ---------------------------------------------------------------------------
MATCHER_TCL = r'''# ---- nested-u_core prefix-aware matcher（codex 0215 Q2）----
# key：相对 top 的完整路径；impl 侧只删除**整段等于** u_core 的层次段；叶名数组展平
# （name_reg[i][j] -> name_i_j_reg；ref name_i_reg[j] -> name_i_j_reg）。只 DFF；两侧 key 必须唯一。
proc ucm_leaf {leaf} {
    if {[regexp {^(\w+)_reg((?:\[\d+\])*)$} $leaf -> nm bits]} {
        set idx ""
        foreach b [regexp -all -inline {\d+} $bits] { append idx "_$b" }
        return "${nm}${idx}_reg"
    }
    return $leaf
}
proc ucm_key {side path} {
    global top
    set pre "${side}:/WORK/${top}/"
    if {[string first $pre $path] != 0} { return "" }
    set segs [split [string range $path [string length $pre] end] /]
    set keep {}
    foreach s [lrange $segs 0 end-1] {
        if {$side eq "i" && $s eq "u_core"} continue
        lappend keep $s
    }
    lappend keep [ucm_leaf [lindex $segs end]]
    return [join $keep /]
}
proc ucm_collect {side} {
    set opt [expr {$side eq "r" ? "-reference" : "-implementation"}]
    set pts {}
    foreach st {{} unread} {
        if {$st eq ""} {
            set l [report_unmatched_points $opt -point_type dff -list]
        } else {
            set l [report_unmatched_points $opt -point_type dff -status unread -list]
        }
        foreach p $l { lappend pts $p }
    }
    return [lsort -unique $pts]
}
proc ucm_run {} {
    global top
    array set rk {}; array set ik {}
    set bad 0
    foreach side {r i} {
        foreach p [ucm_collect $side] {
            set k [ucm_key $side $p]
            if {$k eq ""} { puts "UCM_BADPATH: $side $p"; incr bad; continue }
            if {$side eq "r"} { lappend rk($k) $p } else { lappend ik($k) $p }
        }
    }
    set matched 0; set amb 0; set miss_r 0; set miss_i 0; set fail 0
    foreach side {r i} {
        upvar 0 [expr {$side eq "r" ? "rk" : "ik"}] m
        foreach k [lsort [array names m]] {
            if {[llength $m($k)] != 1} {
                incr amb
                if {$amb <= 20} { puts "UCM_AMBIGUOUS: side=$side key=$k pts=$m($k)" }
            }
        }
    }
    foreach k [lsort [array names rk]] {
        if {![info exists ik($k)]} { incr miss_r; continue }
        if {[llength $rk($k)] != 1 || [llength $ik($k)] != 1} continue
        set r [lindex $rk($k) 0]; set i [lindex $ik($k) 0]
        if {[set_user_match $r $i]} { incr matched } else {
            incr fail
            if {$fail <= 10} { puts "UCM_SET_FAIL: $r <-> $i" }
        }
    }
    foreach k [array names ik] { if {![info exists rk($k)]} { incr miss_i } }
    puts "UCM_SUMMARY $top matched=$matched ambiguous=$amb missing_ref=$miss_r missing_impl=$miss_i set_fail=$fail bad_path=$bad"
    if {$amb != 0 || $fail != 0 || $bad != 0} {
        error "UCM_FAIL ambiguous=$amb set_fail=$fail bad_path=$bad"
    }
}
ucm_run
'''


def build_post(top):
    return ('# %s FM「匹配后」钉点（动态）—— 自动生成：scripts/gen_tl2chi_pins.py（勿手改）\n'
            '# scripts/fm_eq.tcl 在首次 match、auto_match 之后 source 本文件，随后再 match。\n' % top) + MATCHER_TCL


def build_fixture(top, pfx):
    """pin_call_equiv.py 的夹具：按匹配器声明的结构造两侧 unmatched 点（不参与 FM 跑）。"""
    return ('# VARIANTS: %s\n' % top +
            '# fm_pins.tcl 的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）—— 自动生成：scripts/gen_tl2chi_pins.py\n'
            '# 造 2 个 slice × 2 个 MSHR 槽的展平寄存器：ref <pfx>slices_<k>/mshrCtl/q_<j>_reg[<b>]，\n'
            '# impl <pfx>slices_<k>/u_core/mshrCtl/u_core/q_reg[<j>][<b>]；匹配器应恰好配上 8 对、按 key 排序发射。\n'
            'proc report_unmatched_points {args} {\n'
            '    global top\n'
            '    if {[lsearch $args unread] >= 0} { return {} }\n'
            '    set ref {} ; set impl {}\n'
            '    foreach k {0 1} { foreach j {0 1} { foreach b {0 1} {\n'
            '        lappend ref  "r:/WORK/$top/%sslices_${k}/mshrCtl/q_${j}_reg\\[$b\\]"\n'
            '        lappend impl "i:/WORK/$top/%sslices_${k}/u_core/mshrCtl/u_core/q_reg\\[$j\\]\\[$b\\]"\n'
            '    } } }\n'
            '    if {[lindex $args 0] eq "-reference"} { return $ref }\n'
            '    return $impl\n'
            '}\n') % (pfx, pfx)


def outputs():
    out = {}
    for top, pfx in TARGETS.items():
        d = os.path.join(REPO, 'verif', 'ut', top)
        out[os.path.join(d, 'fm_pins_pre.tcl')] = build_pre(top, pfx)
    return out


def main():
    check = '--check' in sys.argv[1:]
    rc = 0
    for path, txt in outputs().items():
        if check:
            ok = os.path.exists(path) and open(path).read() == txt
            print(('OK: ' if ok else 'DRIFT: ') + path)
            rc |= 0 if ok else 1
        else:
            if not os.path.exists(path) or open(path).read() != txt:
                open(path, 'w').write(txt)
            print('wrote ' + path)
    return rc


if __name__ == '__main__':
    sys.exit(main())
