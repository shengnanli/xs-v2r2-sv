#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutants.py —— InterruptFilter UT 的判别力负测（`make mutants`）。

为什么要有它：`errors=0` 只有在「注入真 bug 时 UT 会红」的前提下才有意义。
本模块 296 个输入全随机很容易"看着在验、其实哪条路都没走到"——比如
greaterThan255 那一支要 xtopei 的高 3 位非零才进得去，均匀随机只有 7/8 概率
**不**为零，反过来 isZero 那一支要求整整 8 位全零，均匀随机只有 1/256。
tb 的 drive() 专门给这些分界值加了权，这里就得证明那些加权真的把路走到了。

十个变异各对准本模块一处真实容易写错的地方。M9 是"照 Chisel last-connect 语义
写就会写错"的那处，M2/M6 一起钉住"与外部中断槽位比大小"的边界（<= vs <、> vs >=），
M1/M3 钉住两路比较的第三层（>255 谁输）与规约树的配对顺序（并列取左）。

★第一版的 M1 曾经打在「两边 greaterThan255 都为 1 -> Mux1H 无选中项 -> 全零」那一行，
  10 个里就它和当时的 M3 没被抓到。查下来不是 UT 弱：本模块每一族里能把
  greaterThan255 置 1 的**只有外部中断那一个条目**（M/HS 是 xtopei，VS 根本没有来源），
  第 2 级更是只有第 3 组留了这一位 —— "两边都 >255" 结构上不可达，UT 和 FM 都看不见它。
  于是把 M1 换成可达的那条单边分支；RTL 里那行全零照样照抄 golden，不动。
  当时的 M3（改成线性链）也换成了"最底层配对左右互换"，因为只有并列时配对顺序才可观测。★

变异只发生在 neg_build/（已在 .gitignore 里），不进库。
用法: python3 mutants.py   （或 make mutants）
"""
import pathlib
import re
import shutil
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
BUILD = HERE / 'neg_build'
RTL_REL = pathlib.Path('rtl') / 'backend' / 'InterruptFilter.sv'
NCYCLES = '20000'

# (说明, 锚点, 替换)
MUTANTS = [
    ('M1 >255 的一方本该输，改成赢（greaterThan255 那两条单边分支互换）',
     "      if      ( lhs.greaterThan255 && !rhs.greaterThan255) byNum = rhs;",
     "      if      ( lhs.greaterThan255 && !rhs.greaterThan255) byNum = lhs;"),
    ('M2 isZero 一方与外部中断槽位比大小：<= 写成 <（平手时归属翻转）',
     "      else if ( lhs.isZero && !rhs.isZero) byZero = (lhs.idx <= eiSlot) ? lhs : rhs;",
     "      else if ( lhs.isZero && !rhs.isZero) byZero = (lhs.idx <  eiSlot) ? lhs : rhs;"),
    ('M3 规约树最底层配对顺序左右互换（并列时"取左"变成"取右"）',
     "      lo = iprios_min2(iprios_min2(grp[0], grp[1], eiSlot),",
     "      lo = iprios_min2(iprios_min2(grp[1], grp[0], eiSlot),"),
    ('M4 vstopigather 忘了屏蔽 SEI(9)（VS 外部中断会同时走两条通路）',
     "  assign vstopigather = vsip & vsie & ~(64'h1 << IRQ_SEI);",
     "  assign vstopigather = vsip & vsie;"),
    ('M5 HS 级 SEI 的 greaterThan255 漏掉 mvien/mvip 注入那一项',
     "              hsipriosSort[g][j].greaterThan255 = (injectSEI & ~SEIfromEIC) | (|stopei_IPRIO[10:8]);",
     "              hsipriosSort[g][j].greaterThan255 = (|stopei_IPRIO[10:8]);"),
    ('M6 xtopi.IPRIO 的默认优先级比较：> 写成 >=（恰好是外部中断自己那一格翻转）',
     "                 | ({8{ sel.greaterThan255 | (sel.isZero & (sel.idx > eiSlot))}} & 8'hFF);",
     "                 | ({8{ sel.greaterThan255 | (sel.isZero & (sel.idx >= eiSlot))}} & 8'hFF);"),
    ('M7 VS->宿主 的中断号映射方向反了（应是 VSxI 取 SxI）',
     "      if (n == 2 || n == 6 || n == 10)      vsMapHostIRVecTmp[n] = vsIRVec[n-1];  // VSxI ← SxI",
     "      if (n == 2 || n == 6 || n == 10)      vsMapHostIRVecTmp[n] = vsIRVec[n+1];"),
    ('M8 NMI 优先级反了（43 应压住 31）',
     "    nmiVecTmp[31] = ~nmiVec[43] & nmiVec[31];   // 43 更高优先级，压住 31",
     "    nmiVecTmp[31] = nmiVec[31];"),
    ('M9 iidC1C5 的默认连接被当成 else 分支（Chisel last-connect 语义写错）',
     "    iidC1C5 = hvictlReg_DPR ? iidOnlyC1 : iidOnlyC5;   // 默认连接\n    if (C2C5IsZero) begin",
     "    iidC1C5 = iidOnlyC5;\n    if (C2C5IsZero) begin\n      iidC1C5 = hvictlReg_DPR ? iidOnlyC1 : iidOnlyC5;"),
    ('M10 irToVS 漏掉「HS 没中断」这一条（三级优先级塌掉一层）',
     "  assign irToVS = ~mIRNotZero & ~hsIRNotZero & vsIRNotZero;",
     "  assign irToVS = ~mIRNotZero & vsIRNotZero;"),
]


def prepare():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / RTL_REL.parent).mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / 'InterruptFilter').mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    restore()
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / 'InterruptFilter' / f)


def restore():
    shutil.copy(REPO / RTL_REL, BUILD / RTL_REL)


def run_ut():
    ut = BUILD / 'verif' / 'ut' / 'InterruptFilter'
    log = ut / 'sim_1.log'
    if log.exists():
        log.unlink()          # 编译失败时绝不能读到上一轮的日志（假 CAUGHT）
    subprocess.run(['make', 'run', 'SEED=1', 'NCYCLES=' + NCYCLES], cwd=str(ut),
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   universal_newlines=True)
    if not log.exists():
        return None
    m = re.search(r'checks=(\d+) errors=(\d+)', log.read_text())
    return (int(m.group(1)), int(m.group(2))) if m else None


def main():
    prepare()
    print('=== 基线（未变异，%s 拍）===' % NCYCLES)
    base = run_ut()
    if base is None or base[1] != 0:
        print('基线就不是 errors=0，负测无意义：', base)
        return 2
    print('    checks=%d errors=%d' % base)

    missed = []
    for name, old, new in MUTANTS:
        restore()
        tgt = BUILD / RTL_REL
        t = tgt.read_text()
        if old not in t:
            print('!! %s：锚点没找到，变异未生效（源码改过？请同步本文件）' % name)
            missed.append(name)
            continue
        tgt.write_text(t.replace(old, new, 1))
        res = run_ut()
        if res is None:
            print('!! %s：编译/运行失败，不算「被抓到」' % name)
            missed.append(name)
            continue
        ok = res[1] > 0
        print('  %-66s checks=%d errors=%-8d %s'
              % (name, res[0], res[1], 'CAUGHT' if ok else '★MISSED★'))
        if not ok:
            missed.append(name)
    restore()

    if missed:
        print('=== MUTANTS FAILED：以下变异没被 UT 抓到 ===')
        for m in missed:
            print('   ', m)
        return 1
    print('=== MUTANTS PASSED：%d/%d 个变异全部被 UT 抓到 ===' % (len(MUTANTS), len(MUTANTS)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
