#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""prove_pin_calls_equal_dyn.py —— 证明「动态」钉点文件的守卫改动**没有动过发射出去的钉点调用**。

## 它和 verif/ut/OthersEntry_common/prove_pin_calls_equal.py 的分工

那一个针对**静态表**形态的钉点文件（`foreach {…N 行数据…}` + 一行模板化调用）：
把 `set_user_match` 换成记参数的桩，tclsh 真跑两版，逐字节比调用序列。

本文件针对**动态**形态的五个：`NCBTransactionQueue` / `RenameBuffer` / `SSIT` /
`TLBFA` / `TLBNonBlock`。它们不写死点名，而是现场调 `report_unmatched_points`
把两侧未匹配的未读点读回来、按结构规则配对。所以它们的调用序列是
**`report_unmatched_points` 输出的函数** —— 证明必须先把那个输入固定住再比。

## ★为什么不是"逐字节比对两版的 set_user_match 行"★

那条判据假定钉点文件把 N 个调用写成 N 行字面量。这五个都不是：调用写在循环里，
**那一行恰恰就是被改的守卫本身**（`catch {set_user_match ...}` -> `[set_user_match ...]`），
照字面比必然不同，比了等于自问自答。★判据的输入必须独立于被判断的对象★。

## 判据

对每个目标的每个变体，喂一组**夹具**（按该文件自己声明的结构造出的 ref/impl 点名，
数量取自 golden 现数或已提交 evidence 的实测值），old/new 各跑一遍 tclsh，
逐字节比对实际发生的 `set_user_match` 调用序列（含顺序与重复）：

  * **相同** => 改动是"守卫专属"，「钉了哪些点」这一维度上证明闭包没变，
    先前 receipt 继续有效（★诚实标注★：receipt 里 `proof_config.pin_scripts`
    的 sha256 与工作树已不同，桥接它的是这张表，不是口头保证）。
  * **不同** => 记 `NEEDS_RERUN`，按规矩必须在一个 commit 上重出 receipt。

再加一道**注入探针**：让第 K 次调用返回 0（模拟一个名字漂了），要求
**新版必须抛异常、旧版必须不抛** —— 否则这次"补 fail-closed"是空的。

## 用法

    python3 scripts/prove_pin_calls_equal_dyn.py [--old-rev <git-rev>] [--tsv <out.tsv>]

`--old-rev` 默认 `a2434c2a`（本 lane 的基线 main），旧版用 `git show` 取，
所以任何人 clone 下来都能复跑，不依赖谁本地留着的临时目录。
"""
from __future__ import print_function
import argparse
import hashlib
import os
import pathlib
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
DEFAULT_OLD_REV = 'a2434c2a'

# --------------------------------------------------------------------------
# 夹具：每个变体一段 Tcl，定义 report_unmatched_points 的返回值。
# 结构照各钉点文件自己声明的规则造；数量的出处写在注释里（golden 现数 / evidence 实测）。
# --------------------------------------------------------------------------

FX_RENAMEBUFFER = r'''
# 51 = 5 flag + 5x8 value + 6 preg bit7（golden RenameBuffer.sv 现数）
proc report_unmatched_points {args} {
    set ref {} ; set impl {}
    for {set i 1} {$i <= 5} {incr i} {
        lappend ref  "r:/WORK/RenameBuffer/deqPtrVec_${i}_flag_reg"
        lappend impl "i:/WORK/RenameBuffer/u_core/deq_ptr_flag_q_reg\[$i\]"
        for {set b 0} {$b < 8} {incr b} {
            lappend ref  "r:/WORK/RenameBuffer/deqPtrVec_${i}_value_reg\[$b\]"
            lappend impl "i:/WORK/RenameBuffer/u_core/deq_ptr_value_q_reg\[$i\]\[$b\]"
        }
    }
    for {set j 0} {$j < 6} {incr j} {
        lappend ref  "r:/WORK/RenameBuffer/io_toVecExcpMod_logicPhyRegMap_${j}_bits_preg_r_reg\[7\]"
        lappend impl "i:/WORK/RenameBuffer/u_core/vec_excp_preg_q_reg\[$j\]\[7\]"
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
'''

FX_TLBFA = r'''
# 11 位死位 x PORTS（PORTS 取自 golden <变体>.sv 里 `reg [37:0] reqVpn[_N];` 的条数）
set DESIGN {design}
set PORTS  {ports}
proc report_unmatched_points {args} {
    global DESIGN PORTS
    set ref {} ; set impl {}
    for {set p 0} {$p < $PORTS} {incr p} {
        set sfx [expr {$p == 0 ? "" : "_$p"}]
        for {set b 27} {$b <= 37} {incr b} {
            lappend ref  "r:/WORK/$DESIGN/reqVpn${sfx}_reg\[$b\]"
            lappend impl "i:/WORK/$DESIGN/u_core/g_port\[$p\].req_vpn_q_reg\[$b\]"
        }
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
'''

FX_TLBNONBLOCK = r'''
# A 族数量取自 golden `reg r[_N];` 的条数；B 族取自已提交 evidence 的实测值
set DESIGN {design}
set NA {na}
set NB {nb}
proc report_unmatched_points {args} {
    global DESIGN NA NB
    set ref {} ; set impl {}
    for {set n 0} {$n < $NA} {incr n} {
        if {$n == 0} { lappend ref "r:/WORK/$DESIGN/r_reg" } \
                else { lappend ref "r:/WORK/$DESIGN/r_${n}_reg" }
        set lane [expr {$n / 2}]
        if {$n % 2 == 0} {
            lappend impl "i:/WORK/$DESIGN/u_core/first_issue_r_reg\[$lane\]"
        } else {
            lappend impl "i:/WORK/$DESIGN/u_core/first_issue_r2_reg\[$lane\]"
        }
    }
    if {$NB > 0} {
        lappend ref  "r:/WORK/$DESIGN/result_ok_last_REG_reg"
        lappend impl "i:/WORK/$DESIGN/u_core/result_ok_last_reg\[0\]"
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
'''

FX_NCBQ = r'''
# 每槽 23 位（ReturnNID 11 + ReturnTxnID 12）x 槽数（golden 现数：无后缀 64、_1 是 32）
set DESIGN {design}
set SLOTS  {slots}
proc report_unmatched_points {args} {
    global DESIGN SLOTS
    set ref {} ; set impl {}
    for {set i 0} {$i < $SLOTS} {incr i} {
        for {set b 0} {$b < 11} {incr b} {
            lappend ref  "r:/WORK/$DESIGN/regQueue_${i}_bits_info_ReturnNID_reg\[$b\]"
            lappend impl "i:/WORK/$DESIGN/u_core/info_q_reg\[$i\]\[return_nid\]\[$b\]"
        }
        for {set b 0} {$b < 12} {incr b} {
            lappend ref  "r:/WORK/$DESIGN/regQueue_${i}_bits_info_ReturnTxnID_reg\[$b\]"
            lappend impl "i:/WORK/$DESIGN/u_core/info_q_reg\[$i\]\[return_txn_id\]\[$b\]"
        }
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
'''

FX_SSIT = r'''
# 14 个改名寄存器的位宽之和 = 91（golden SSIT.sv 现数，width = hi+1）
proc match {} { }
set MAP {resetCounter 20 resetStepCounter 11 REG 5 s1_mempred_update_req_valid 1
         s1_mempred_update_req_ldpc 10 s1_mempred_update_req_stpc 10
         s2_mempred_update_req_valid 1 s2_ldSsidAllocate_value 10 s2_stSsidAllocate_value 10
         s2_loadAssigned 1 s2_storeAssigned 1 s2_loadOldSSID 5 s2_storeOldSSID 5 s2_loadStrict 1}
set NEW  {reset_counter reset_step timeout_q s1_valid s1_ldpc s1_stpc s2_valid s2_ldpc s2_stpc
          s2_load_assigned s2_store_assigned s2_load_old_ssid s2_store_old_ssid s2_load_strict}
proc report_unmatched_points {args} {
    global MAP NEW
    set ref {} ; set impl {} ; set k 0
    foreach {g w} $MAP {
        set n [lindex $NEW $k] ; incr k
        if {$w == 1} {
            lappend ref "r:/WORK/SSIT/${g}_reg" ; lappend impl "i:/WORK/SSIT/u_core/${n}_reg"
        } else {
            for {set b 0} {$b < $w} {incr b} {
                lappend ref  "r:/WORK/SSIT/${g}_reg\[$b\]"
                lappend impl "i:/WORK/SSIT/u_core/${n}_reg\[$b\]"
            }
        }
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
'''

# (标签, 钉点文件相对路径, 夹具 Tcl, 期望调用数)
CASES = [
    ('RenameBuffer',          'verif/ut/RenameBuffer/fm_pins.tcl',        FX_RENAMEBUFFER, 51),
    ('TLBFA',                 'verif/ut/TLBFA/fm_pins.tcl',
     FX_TLBFA.replace('{design}', 'TLBFA').replace('{ports}', '3'), 33),
    ('TLBFA_1',               'verif/ut/TLBFA/fm_pins.tcl',
     FX_TLBFA.replace('{design}', 'TLBFA_1').replace('{ports}', '4'), 44),
    ('TLBFA_2',               'verif/ut/TLBFA/fm_pins.tcl',
     FX_TLBFA.replace('{design}', 'TLBFA_2').replace('{ports}', '2'), 22),
    ('TLBFA_3',               'verif/ut/TLBFA/fm_pins.tcl',
     FX_TLBFA.replace('{design}', 'TLBFA_3').replace('{ports}', '2'), 22),
    ('TLBNonBlock',           'verif/ut/TLBNonBlock/fm_pins.tcl',
     FX_TLBNONBLOCK.replace('{design}', 'TLBNonBlock').replace('{na}', '8').replace('{nb}', '0'), 8),
    ('TLBNonBlock_1',         'verif/ut/TLBNonBlock/fm_pins.tcl',
     FX_TLBNONBLOCK.replace('{design}', 'TLBNonBlock_1').replace('{na}', '4').replace('{nb}', '0'), 4),
    ('TLBNonBlock_2',         'verif/ut/TLBNonBlock/fm_pins.tcl',
     FX_TLBNONBLOCK.replace('{design}', 'TLBNonBlock_2').replace('{na}', '2').replace('{nb}', '1'), 3),
    ('NCBTransactionQueue',   'verif/ut/NCBTransactionQueue/fm_pins.tcl',
     FX_NCBQ.replace('{design}', 'NCBTransactionQueue').replace('{slots}', '64'), 1472),
    ('NCBTransactionQueue_1', 'verif/ut/NCBTransactionQueue/fm_pins.tcl',
     FX_NCBQ.replace('{design}', 'NCBTransactionQueue_1').replace('{slots}', '32'), 736),
    ('SSIT',                  'verif/ut/SSIT/fm_pins.tcl', FX_SSIT, 91),
]

HARNESS = '''
set ::calls 0
set ::INJECT {inject}
proc set_user_match {{a b}} {{
    incr ::calls
    puts "CALL $a $b"
    if {{$::calls == $::INJECT}} {{ return 0 }}
    return 1
}}
set top {top}
set ::rc [catch {{source {pinfile}}} ::m]
puts "RC $::rc"
'''


def run_one(pinfile, fixture, top, inject):
    """跑一遍钉点文件，返回 (调用序列, rc)。"""
    src = fixture + HARNESS.format(inject=inject, top=top, pinfile=str(pinfile))
    fd, path = tempfile.mkstemp(suffix='.tcl')
    os.close(fd)
    try:
        with open(path, 'w') as f:
            f.write(src)
        pr = subprocess.Popen(['tclsh', path], stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, universal_newlines=True)
        out, _ = pr.communicate()
        calls = [l for l in out.split('\n') if l.startswith('CALL ')]
        rcs = [l for l in out.split('\n') if l.startswith('RC ')]
        rc = int(rcs[-1].split()[1]) if rcs else 99
        return calls, rc, out
    finally:
        if os.path.exists(path):
            os.unlink(path)


def git_show(rev, relpath, outdir):
    """把 <rev> 版的文件取出来放到 outdir，返回路径（不存在返回 None）。"""
    pr = subprocess.Popen(['git', '-C', str(REPO), 'show', '%s:%s' % (rev, relpath)],
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = pr.communicate()
    if pr.returncode != 0:
        return None
    dst = outdir / relpath.replace('/', '__')
    dst.write_bytes(out)
    return dst


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('--old-rev', default=DEFAULT_OLD_REV)
    ap.add_argument('--tsv', default=None)
    args = ap.parse_args(argv)

    tmp = pathlib.Path(tempfile.mkdtemp(prefix='pindyn_'))
    rows = []
    rc_all = 0
    print('%-24s %8s %8s  %-18s  %s' % ('变体', '旧调用数', '新调用数', '调用序列 sha256', '结论'))
    for label, rel, fixture, expect in CASES:
        new = REPO / rel
        old = git_show(args.old_rev, rel, tmp)
        if old is None:
            print('%-24s %8s %8s  %-18s  ★旧版取不出来（%s）★' % (label, '-', '-', '-', args.old_rev))
            rc_all = 1
            continue
        a, rca, _ = run_one(old, fixture, label, -1)
        b, rcb, outb = run_one(new, fixture, label, -1)
        ha = hashlib.sha256('\n'.join(a).encode()).hexdigest()[:16]
        hb = hashlib.sha256('\n'.join(b).encode()).hexdigest()[:16]
        same = (a == b)
        # 注入探针：让第 1 次调用返回 0 —— 新版必须抛，旧版必须不抛。
        _, rca_inj, _ = run_one(old, fixture, label, 1)
        _, rcb_inj, outi = run_one(new, fixture, label, 1)
        probe_ok = (rca_inj == 0 and rcb_inj == 1)
        ok = same and rca == 0 and rcb == 0 and probe_ok and len(b) == expect
        verdict = ('守卫专属' if ok else '★NEEDS_RERUN★')
        detail = []
        if not same:
            detail.append('调用序列不同')
        if len(b) != expect:
            detail.append('调用数 %d != 期望 %d' % (len(b), expect))
        if rcb != 0:
            detail.append('新版正常夹具下就抛了：%s' % outb.strip().split('\n')[-2:])
        if not probe_ok:
            detail.append('注入探针 old_rc=%d new_rc=%d（要求 0/1）' % (rca_inj, rcb_inj))
        print('%-24s %8d %8d  %-18s  %s%s'
              % (label, len(a), len(b), hb, verdict,
                 ('  ' + '；'.join(detail)) if detail else
                 '（注入探针：旧 rc=0 没响 / 新 rc=1 抛出）'))
        rows.append((label, rel, len(a), len(b), ha, hb,
                     'SAME' if same else 'DIFF',
                     'OK' if probe_ok else 'BAD',
                     'GUARD_ONLY' if ok else 'NEEDS_RERUN'))
        if not ok:
            rc_all = 1

    if args.tsv:
        out = pathlib.Path(args.tsv)
        with out.open('w') as f:
            f.write('variant\tpin_file\told_calls\tnew_calls\told_sha256_16\tnew_sha256_16'
                    '\tcall_seq\tinject_probe\tverdict\n')
            for r in rows:
                f.write('\t'.join(str(x) for x in r) + '\n')
        print('\n写出 %s' % out)

    print()
    print('结论：' + ('★守卫专属改动：调用序列逐字节相同且注入探针前后对照成立，'
                     '先前 receipt 继续有效★' if rc_all == 0 else
                     '★有目标的调用集合变了或探针不成立，按规矩必须重出 receipt★'))
    return rc_all


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
