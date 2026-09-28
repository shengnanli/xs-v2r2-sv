#!/usr/bin/env python3
"""mutants.py —— IntRegFilePart 家族 UT 的判别力负测（`make mutants`）。

`errors=0` 只有在「注入真 bug 时 UT 会红」的前提下才有意义。做法：把 rtl 与本目录复制到
scratchpad 下的构建目录（**变异不进库**、也不落在仓库树里），逐个注入一个真 bug，跑 5k 拍，
要求每个都被 UT 抓出来（errors > 0）。每个变异对准寄存器堆一条容易写错的语义：
写口合并方式（按位或 vs 优先级）、读延迟、同拍旁路、x0/越界常零、写口数、wrapper 接线。

构建目录：环境变量 INTRF_MUT_BUILD，默认 /tmp/claude-1000/<session>/scratchpad/intrf/mut_build。
用法: python3 mutants.py      （或 make mutants）
"""
import os
import pathlib
import re
import shutil
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
BUILD = pathlib.Path(os.environ.get(
    'INTRF_MUT_BUILD',
    '/tmp/claude-1000/-home-eda-xs-env-XiangShan/6824a231-879a-49e3-b98d-f29f5afc381c/scratchpad/intrf/mut_build'))
UTNAME = 'IntRegFilePart'

CORE = 'xs_IntRegFilePart_core.sv'
# (说明, 改哪个文件, 锚点, 替换)
MUTANTS = [
    ('M1 同址多写改成"后口覆盖"（golden 是按位或）', CORE,
     "        if (hit[w]) wdata |= write_data[w];",
     "        if (hit[w]) wdata = write_data[w];"),
    ('M2 读口不打拍（组合读，延迟 0）', CORE,
     "      read_data[r] = mem_for_read[raddr_q[r]];",
     "      read_data[r] = mem_for_read[read_addr[r]];"),
    ('M3 加一条 golden 没有的写->读同拍旁路', CORE,
     "      read_data[r] = mem_for_read[raddr_q[r]];",
     "      read_data[r] = mem_for_read[raddr_q[r]];\n"
     "      for (int w = 0; w < NUM_WRITE; w++)\n"
     "        if (write_wen[w] && write_addr[w] == raddr_q[r] && raddr_q[r] != 0) read_data[r] = write_data[w];"),
    ('M4 越界读回绕到 mem[1]（golden 是 0）', CORE,
     "      assign mem_for_read[i] = '0;   // i==0：x0；i>=NUM_PREGS：越界",
     "      assign mem_for_read[i] = (i == 0) ? '0 : mem[1];"),
    ('M5 x0 读出 mem[1]（golden 是 0）', CORE,
     "      assign mem_for_read[i] = '0;   // i==0：x0；i>=NUM_PREGS：越界",
     "      assign mem_for_read[i] = (i == 0) ? mem[1] : '0;"),
    ('M6 最后一个写口被漏掉', CORE,
     "      for (int w = 0; w < NUM_WRITE; w++) begin\n        hit[w]",
     "      hit[NUM_WRITE-1] = 1'b0;\n      for (int w = 0; w < NUM_WRITE - 1; w++) begin\n        hit[w]"),
    ('M7 wrapper 接线错：Part2 的 debug_all_rdata_5 接成第 6 路', 'IntRegFilePart2.sv',
     "  assign io_debug_all_rdata_5 = debug_all_rdata[5];",
     "  assign io_debug_all_rdata_5 = debug_all_rdata[6];"),
    ('M8 wrapper 接线错：Part3 读口 9/10 地址对调', 'IntRegFilePart3.sv',
     "  assign read_addr[9] = io_readPorts_9_addr;\n  assign read_addr[10] = io_readPorts_10_addr;",
     "  assign read_addr[9] = io_readPorts_10_addr;\n  assign read_addr[10] = io_readPorts_9_addr;"),
    ('M9 写使能改成"只看地址不看 wen"的最高行（行 223）', CORE,
     "        hit[w] = write_wen[w] && (write_addr[w] == ADDR_W'(row));",
     "        hit[w] = (write_wen[w] || row == NUM_PREGS - 1) && (write_addr[w] == ADDR_W'(row));"),
]

RTL = [CORE, 'IntRegFilePart0.sv', 'IntRegFilePart1.sv', 'IntRegFilePart2.sv', 'IntRegFilePart3.sv']
NCYCLES = '5000'


def prepare():
    # 只清自己的构建目录（路径由本脚本唯一确定，带 lane 名），不碰别的东西
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / 'rtl' / 'backend').mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / UTNAME).mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / UTNAME / f)
    restore()


def restore():
    for f in RTL:
        shutil.copy(REPO / 'rtl' / 'backend' / f, BUILD / 'rtl' / 'backend' / f)


def run_ut(initreg):
    ut = BUILD / 'verif' / 'ut' / UTNAME
    subprocess.run(['make', 'run', 'SEED=1', 'INITREG=' + initreg, 'NCYCLES=' + NCYCLES], cwd=str(ut),
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
    log = ut / 'sim_1.log'   # ut_common 在跑前删掉它：编译失败时读不到陈旧日志
    if not log.exists():
        return None
    m = re.search(r'checks=(\d+) errors=(\d+)', log.read_text())
    return (int(m.group(1)), int(m.group(2))) if m else None


def main():
    prepare()
    print('=== 基线（未变异，%s 拍，INITREG=0 与 7017 两档）===' % NCYCLES)
    for ir in ('0', '7017'):
        base = run_ut(ir)
        if base is None or base[1] != 0:
            print('基线就不是 errors=0，负测无意义：', ir, base)
            return 2
        print('    INITREG=%s checks=%d errors=%d' % ((ir,) + base))
    missed = []
    for name, fname, old, new in MUTANTS:
        restore()
        tgt = BUILD / 'rtl' / 'backend' / fname
        t = tgt.read_text()
        if t.count(old) != 1:
            print('!! %s：锚点命中 %d 次（应为 1），变异未生效' % (name, t.count(old)))
            missed.append(name)
            continue
        tgt.write_text(t.replace(old, new, 1))
        # 用真随机档（+vcs+initreg+7017）：比的是"写过的行"，变异要在门控下仍被看见
        res = run_ut('7017')
        if res is None:
            print('!! %s：编译/运行失败，不算「被抓到」' % name)
            missed.append(name)
            continue
        ok = res[1] > 0
        print('  %-58s checks=%d errors=%-8d %s' % (name, res[0], res[1], 'CAUGHT' if ok else '*MISSED*'))
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
