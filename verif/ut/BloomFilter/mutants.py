#!/usr/bin/env python3
"""mutants.py —— BloomFilter UT 的判别力负测（`make mutants`）。

为什么要有它：`errors=0` 只有在「注入真 bug 时 UT 会红」的前提下才有意义。
本模块还多一层理由 —— tb 为了处理**不复位**的 res 寄存器做了暖机（前 24 拍
强制三个 query 口全 valid，之后才比 res）。暖机是必要的（否则 random initreg
下两侧上电值不同，会报一片假失配），但暖机也最容易把判别力一起暖没：M3/M4 就是
专门用来证明「暖机之后 res 那条路还在被真验」的。

做法：把 rtl/ 与本目录复制进 neg_build/（已在 .gitignore 里，**变异不进库**），
逐个注入一个真 bug，跑 20k 拍，要求每个都被 UT 抓出来（errors > 0）。

★ 一个**故意不放进来**的变异 ★
  把 data 的写回加上 `if (set_valid | clr_valid)` 门控 —— 两者都无效时
  data_next 恒等于 data，所以这个改动**值恒等**，UT 永远抓不到，FM 也会判等价。
  它不是 bug，也不构成判别力缺口；列在这里是为了说明本文件挑变异的口径：
  只注入**可观测**的真 bug，不拿值恒等的改写凑数。

用法: python3 mutants.py      （或 make mutants）
"""
import pathlib
import re
import shutil
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
BUILD = HERE / 'neg_build'
RTLREL = pathlib.Path('rtl') / 'memblock'
RTL = ['BloomFilter.sv']
NCYCLES = '20000'

# (说明, 改哪个文件, 锚点, 替换)
MUTANTS = [
    ('M1 更新优先级翻转：set 压过 clr（golden 是 clr 赢）',
     'BloomFilter.sv',
     "      data_next[i] = ~(clr_valid & (clr_addr == ADDR_W'(i)))\n"
     "                     & (  (set_valid & (set_addr == ADDR_W'(i)))\n"
     "                        | data[i] );",
     "      data_next[i] = (set_valid & (set_addr == ADDR_W'(i)))\n"
     "                     | (~(clr_valid & (clr_addr == ADDR_W'(i))) & data[i]);"),

    ('M2 关掉 bypass：查询读 data 而不是 data_next',
     'BloomFilter.sv',
     "  wire  [N-1:0]      read_src = BYPASS ? data_next : data;",
     "  wire  [N-1:0]      read_src = data;"),

    ('M3 给 res 寄存器加复位（golden 这一路**不复位**）—— 同时检验暖机没把判别力抹掉',
     'BloomFilter.sv',
     "  always_ff @(posedge clock) begin\n"
     "    for (int unsigned q = 0; q < NQUERY; q++) begin\n"
     "      if (query_valid[q]) begin\n"
     "        resp_res_q[q] <= read_src[query_addr[q]];\n"
     "      end\n"
     "    end\n"
     "  end",
     "  always_ff @(posedge clock or posedge reset) begin\n"
     "    if (reset) resp_res_q <= '0;\n"
     "    else for (int unsigned q = 0; q < NQUERY; q++) begin\n"
     "      if (query_valid[q]) begin\n"
     "        resp_res_q[q] <= read_src[query_addr[q]];\n"
     "      end\n"
     "    end\n"
     "  end"),

    ('M4 去掉 res 寄存器的使能（无效拍也更新，golden 是 RegEnable）',
     'BloomFilter.sv',
     "      if (query_valid[q]) begin\n"
     "        resp_res_q[q] <= read_src[query_addr[q]];\n"
     "      end",
     "      resp_res_q[q] <= read_src[query_addr[q]];"),

    ('M5 给 resp_valid 加使能（golden 是无条件打拍，加了就卡在 1）',
     'BloomFilter.sv',
     "      resp_valid_q <= query_valid;",
     "      resp_valid_q <= resp_valid_q | query_valid;"),
]


def prepare():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / RTLREL).mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / 'BloomFilter').mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    restore()
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / 'BloomFilter' / f)


def restore():
    for f in RTL:
        shutil.copy(REPO / RTLREL / f, BUILD / RTLREL / f)


def run_ut():
    ut = BUILD / 'verif' / 'ut' / 'BloomFilter'
    subprocess.run(['make', 'run', 'SEED=1', 'NCYCLES=' + NCYCLES], cwd=str(ut),
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   universal_newlines=True)
    log = ut / 'sim_1.log'
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
    for name, fname, old, new in MUTANTS:
        restore()
        tgt = BUILD / RTLREL / fname
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
        print('  %-70s checks=%d errors=%-7d %s'
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
