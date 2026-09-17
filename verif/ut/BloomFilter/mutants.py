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

★ 2026-09-17 自查：本文件此前有一个**真的会出假绿的 harness 洞** ★
  run_ut() 跑完直接读 sim_1.log。变异**编译失败**时 `make run` 不产生新日志，
  于是读到的是**上一个变异**留下的那份 —— 上一个是 CAUGHT(errors>0)，
  这一个就被记成 CAUGHT。IBuffer 的 M6 正是这样：它的替换文本少一个 `end`、
  VCS 报 Syntax error，而报告里它和 M5 的 errors 一模一样(77119)——
  数字撞车当时被我注意到了却没追下去，是 CONVENTIONS 那条新规矩点醒的。
  三处一起堵：
    (1) 每次跑之前**先删** sim_1.log；
    (2) `make run` 的返回码进判据，非 0 一律判 FAIL(不是 CAUGHT)；
    (3) 变异文本必须**真的改变了文件**，否则判 FAIL。
  另配 `--compile-only` 自检：只做替换+编译，不跑仿真，专门查"变异编不过"。

用法: python3 mutants.py [--compile-only]   （或 make mutants）
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
MODULE  = 'BloomFilter'
MUTFILE = 'BloomFilter.sv'

# (说明, 改哪个文件, 锚点, 替换)
MUTANTS = [
    ('M1 更新优先级翻转：set 压过 clr（golden 是 clr 赢）',
     "      data_next[i] = ~(clr_valid & (clr_addr == ADDR_W'(i)))\n"
     "                     & (  (set_valid & (set_addr == ADDR_W'(i)))\n"
     "                        | data[i] );",
     "      data_next[i] = (set_valid & (set_addr == ADDR_W'(i)))\n"
     "                     | (~(clr_valid & (clr_addr == ADDR_W'(i))) & data[i]);"),

    ('M2 关掉 bypass：查询读 data 而不是 data_next',
     "  wire  [N-1:0]      read_src = BYPASS ? data_next : data;",
     "  wire  [N-1:0]      read_src = data;"),

    ('M3 给 res 寄存器加复位（golden 这一路**不复位**）—— 同时检验暖机没把判别力抹掉',
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
     "      if (query_valid[q]) begin\n"
     "        resp_res_q[q] <= read_src[query_addr[q]];\n"
     "      end",
     "      resp_res_q[q] <= read_src[query_addr[q]];"),

    ('M5 给 resp_valid 加使能（golden 是无条件打拍，加了就卡在 1）',
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


def _edits(ent):
    """MUTANTS 条目支持两种写法：
         (名字, [(old, new), ...])  —— **多处**替换，用于 M6 这种要同时改块首与块尾的
         (名字, old, new)           —— 单处替换
    多处那种是被 IBuffer M6 逼出来的：把无复位块改成带复位的 if/else，只改块首会少一个
    `end`，语法就坏了；而语法坏掉在旧 harness 下不报错、直接读到上一轮日志变成假 CAUGHT。
    """
    if len(ent) == 2:
        return list(ent[1])
    return [(ent[-2], ent[-1])]


def apply_mutant(tgt, base_text, edits):
    """返回 (是否成功施加, 新文本)。锚点找不到或文本没变都算失败。"""
    t = base_text
    for old, new in edits:
        if old not in t:
            return (False, t)
        t = t.replace(old, new, 1)
    if t == base_text:
        return (False, t)
    tgt.write_text(t)
    return (True, t)


def run_ut():
    """跑一轮 UT。★每次先删日志★，并把 make 的返回码一起带出来 ——
    编译失败时读到上一轮的日志，就是本文件此前的假绿来源。"""
    ut = BUILD / 'verif' / 'ut' / MODULE
    log = ut / 'sim_1.log'
    if log.exists():
        log.unlink()
    r = subprocess.run(['make', 'run', 'SEED=1', 'NCYCLES=' + NCYCLES], cwd=str(ut),
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                       universal_newlines=True)
    if not log.exists():
        return (None, r.returncode, r.stdout[-2000:])
    m = re.search(r'checks=(\d+) errors=(\d+)', log.read_text())
    if not m:
        return (None, r.returncode, log.read_text()[-2000:])
    return ((int(m.group(1)), int(m.group(2))), r.returncode, '')


def main():
    compile_only = '--compile-only' in sys.argv
    prepare()
    base_text = (REPO / RTLREL / MUTFILE).read_text()
    tgt = BUILD / RTLREL / MUTFILE

    if compile_only:
        # 只查"变异编得过吗"，不跑仿真。用于快速自检锚点与语法。
        bad = []
        for ent in MUTANTS:
            restore()
            ok, _ = apply_mutant(tgt, base_text, _edits(ent))
            if not ok:
                print('  %-70s ★锚点失效/文本未变★' % ent[0].splitlines()[0])
                bad.append(ent[0])
                continue
            r = subprocess.run(['make', 'compile'],
                               cwd=str(BUILD / 'verif' / 'ut' / MODULE),
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               universal_newlines=True)
            print('  %-70s %s' % (ent[0].splitlines()[0],
                                  'compiles' if r.returncode == 0 else '★编译失败★'))
            if r.returncode != 0:
                bad.append(ent[0])
        restore()
        print('=== COMPILE-ONLY: %d/%d 可编译 ===' % (len(MUTANTS) - len(bad), len(MUTANTS)))
        return 1 if bad else 0

    print('=== 基线（未变异，%s 拍）===' % NCYCLES)
    base, rc, tail = run_ut()
    if base is None or rc != 0 or base[1] != 0:
        print('基线就不是 errors=0（rc=%s），负测无意义：%s\n%s' % (rc, base, tail))
        return 2
    print('    checks=%d errors=%d' % base)

    missed = []
    for ent in MUTANTS:
        name = ent[0]
        restore()
        ok, _ = apply_mutant(tgt, base_text, _edits(ent))
        if not ok:
            print('!! %s：锚点失效或文本未改变 —— 变异没生效' % name.splitlines()[0])
            missed.append(name)
            continue
        res, rc, tail = run_ut()
        # ★判据是"日志里有没有本轮的 checks=/errors= 行"，不是 make 的返回码★
        # make run 对**被抓到的变异**本来就返回非 0（tb 打 TEST FAILED，Makefile 据此 exit 1），
        # 拿 rc 当判据会把"正确抓到"误判成"harness 坏了"（第一版硬化就这么错了一次）。
        # 真正堵住假绿的是 run_ut() 里**每次先删 sim_1.log**：编译失败就没有新日志，
        # res 为 None，落到下面判 FAIL，不会再读到上一个变异的结果。
        if res is None:
            print('!! %-66s ★没有产生本轮日志（编译/运行失败，rc=%s），判 FAIL★'
                  % (name.splitlines()[0], rc))
            missed.append(name)
            continue
        caught = res[1] > 0
        print('  %-70s errors=%-9d %s'
              % (name.splitlines()[0], res[1], 'CAUGHT' if caught else '★MISSED★'))
        if not caught:
            missed.append(name)
    restore()
    if missed:
        print('=== MUTANTS FAILED：以下变异没被 UT 抓到（或根本没生效）===')
        for x in missed:
            print('   ', x.splitlines()[0])
        return 1
    print('=== MUTANTS PASSED：%d/%d 个变异全部被 UT 抓到 ===' % (len(MUTANTS), len(MUTANTS)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
