#!/usr/bin/env python3
"""mutants.py —— FreeListVariants UT 的判别力负测（`make mutants`）。

为什么要有它：`errors=0` 只有在「注入真 bug 时 UT 会红」的前提下才有意义。
本家族尤其容易"看起来在验、其实没验"——释放侧的 bank 优先级、非 2 幂回绕、
满/空边界都只在特定相位才分得出对错；激励一退化成均匀随机，整轮 errors=0
什么都不说明（tb 头注释里那条"前缀掩码"就是这么栽过的）。

做法：把 rtl/ 与本目录复制进 neg_build/（已 gitignore，**变异不进库**），
逐个注入一处改动，跑 40k 拍，读 tb 末行的合计 `checks=.. errors=..`。

★两类条目，缺一不可（CONVENTIONS：闸的负测必须双向）★
  CATCH —— 真 bug，UT 必须报（errors > 0）。
  EQUIV —— 文本改了、电路在**可达输入**上等价，UT 必须**不报**。
           它防的是"恒红的 harness"：每次都喊 CAUGHT 的负测毫无价值。
           这里选的是「把释放 bank 的写优先级整个反过来」——
           rtl/memblock/FreeList.sv 头注释已经论证过这条优先级按构造不可达
           （活跃 bank 的写地址互不相同），并实测反过来 UT 仍 errors=0。
           ★注意它只是 UT 不可见，不是可以改★：FM 把寄存器当自由变量、
           不做可达性分析，改了照样 failing。所以它在这里的身份是
           "UT 的能力边界样本"，不是"可以顺手优化的地方"。

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
CORE = 'FreeList.sv'
RTL = [CORE, 'FreeList_1.sv', 'FreeList_3.sv', 'FreeList_4.sv', 'FreeList_6.sv']
NCYCLES = '40000'

# (期望, 说明, 文件, 锚点, 替换)
MUTANTS = [
    ('CATCH', 'M1 空闲计数用当前 tailPtr 而不是 tailPtrNext（满/空边界差一拍）', CORE,
     "  wire fl_ptr_t   tailPtrNext  = ptr_add(tailPtr, popcnt(PC_W'(freeReqReg), FREE_WIDTH));",
     "  wire fl_ptr_t   tailPtrNext  = tailPtr;"),
    ('CATCH', 'M2 preAlloc 的读指针不加 numAllocate（提前一拍那层没了）', CORE,
     "      deqPtr[i] = ENABLE_PRE_ALLOC ? ptr_add(ptr_add(headPtr, numAllocate), IDX_W'(i))",
     "      deqPtr[i] = ENABLE_PRE_ALLOC ? ptr_add(headPtr, IDX_W'(i))"),
    ('CATCH', 'M3 isBefore 漏掉 flag 异或（绕圈后满/空判反）', CORE,
     "    return (a.flag ^ b.flag) ^ (a.value < b.value);",
     "    return (a.value < b.value);"),
    ('CATCH', 'M4 freeMask 不扣除已选中的位（同一个槽位被回收两次）', CORE,
     "      freeMask <= (io_free | freeMask) & ~freeSelMask;",
     "      freeMask <= (io_free | freeMask);"),
    ('CATCH', 'M5 释放写回地址少算一个 bank 偏移（两个 bank 写同一格）', CORE,
     "      enqPtr        = ptr_add(tailPtr, popcnt(PC_W'(freeReqReg), b));",
     "      enqPtr        = tailPtr;"),
    ('CATCH', 'M6 非 2 幂回绕判据写成 diff > 0（绕到第 0 格那次不翻 flag）', CORE,
     "        if (diff >= 0) begin",
     "        if (diff > 0) begin"),
    ('CATCH', 'M7 freeList 复位成全 0（golden 是 0..SIZE-1 顺序排开）', CORE,
     "      for (int i = 0; i < SIZE; i++) freeList[i] <= IDX_W'(i);",
     "      for (int i = 0; i < SIZE; i++) freeList[i] <= '0;"),
    ('CATCH', 'M8 GatedRegNext 写成无条件打拍中的"值没变也不写"反向（freeReq 永不更新）', CORE,
     "        if (freeReqNext[b] != freeReqReg[b])",
     "        if (freeReqNext[b] == freeReqReg[b])"),
    ('EQUIV', 'E1 释放 bank 写优先级整个反过来（按构造不可达，UT 必须不报）', CORE,
     "      for (int e = 0; e < SIZE; e++)\n"
     "        for (int b = 0; b < FREE_WIDTH; b++)",
     "      for (int e = 0; e < SIZE; e++)\n"
     "        for (int b = FREE_WIDTH - 1; b >= 0; b--)"),
]


def prepare():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / 'rtl' / 'memblock').mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / 'FreeListVariants').mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    restore()
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / 'FreeListVariants' / f)


def restore():
    for f in RTL:
        shutil.copy(REPO / 'rtl' / 'memblock' / f, BUILD / 'rtl' / 'memblock' / f)


def run_ut():
    """返回 (checks, errors)；编译或运行失败返回 None。
    make run 每次先删日志，所以读不到日志 = 这一轮真的没跑出来，
    不会捡到上一个变异的 errors（IBuffer M6 实测栽过的那个洞）。"""
    ut = BUILD / 'verif' / 'ut' / 'FreeListVariants'
    subprocess.run(['make', 'run', 'SEED=1', 'NCYCLES=' + NCYCLES], cwd=str(ut),
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   universal_newlines=True)
    log = ut / 'sim_1.log'
    if not log.exists():
        return None
    m = re.search(r'^checks=(\d+) errors=(\d+)', log.read_text(), re.M)
    return (int(m.group(1)), int(m.group(2))) if m else None


def main():
    prepare()
    print('=== 基线（未变异，%s 拍）===' % NCYCLES)
    base = run_ut()
    if base is None or base[1] != 0:
        print('基线就不是 errors=0，负测无意义：', base)
        return 2
    print('    checks=%d errors=%d' % base)

    bad = []
    for expect, name, fname, old, new in MUTANTS:
        restore()
        tgt = BUILD / 'rtl' / 'memblock' / fname
        t = tgt.read_text()
        if old not in t:
            print('!! %s：锚点没找到，变异未生效（核改过？请同步本文件）' % name)
            bad.append(name)
            continue
        tgt.write_text(t.replace(old, new, 1))
        res = run_ut()
        if res is None:
            print('!! %s：编译/运行失败，不算结论' % name)
            bad.append(name)
            continue
        ok = (res[1] > 0) if expect == 'CATCH' else (res[1] == 0)
        tag = ('CAUGHT' if ok else '*** MISSED ***') if expect == 'CATCH' \
              else ('EQUIV-ok' if ok else '*** EQUIV 却报错，说明它并不等价 ***')
        print('  %-64s checks=%d errors=%-9d %s' % (name, res[0], res[1], tag))
        if not ok:
            bad.append(name)
    restore()
    if bad:
        print('=== MUTANTS FAILED ===')
        for m in bad:
            print('   ', m)
        return 1
    print('=== MUTANTS PASSED：%d 个变异全部符合预期（8 CATCH + 1 EQUIV）===' % len(MUTANTS))
    return 0


if __name__ == '__main__':
    sys.exit(main())
