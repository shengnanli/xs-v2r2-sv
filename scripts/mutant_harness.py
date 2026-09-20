#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutant_harness.py —— 变异体判别力负测的共享跑法（四个小叶子家族共用）。

为什么抽出来：本轮一条 lane 同时做 FuBusyTableRead / FuBusyTableWrite / WBArbiter /
RealWBArbiter 四个家族，四份 mutants.py 的**跑法**逐字相同，只有变异表不同。
把跑法复制四遍，就会出现「改了其中一份的判据、另外三份还是老的」这种分叉 ——
与 rtl 侧「核体绝不复制」是同一条理由。各家族的 mutants.py 只声明配置与变异表。

★口径（本轮任务书明确要求，逐条落在代码里）★
  · 变异必须**先自证改了电路**：锚点不存在、或替换后文本没变 ⇒ 判 INVALID，
    既不计 caught 也不计分母（它根本没产生电路）。
  · **编不过的变异体算「无效变异体」**：不计 caught 也不计分母。唯一例外是
    期望本来就是 COMPILE_FAIL 的条目（故意测工具链拦截）。
  · **逻辑等价的空变异**（EQUIV）从分子分母**同时剔除**，但必须跑、必须
    errors=0，并在表里写明"为什么等价"。它的作用是证明这套 harness 不会把
    "改了字面"误当成"改了电路"。
  · license/磁盘一类的失败单列 infra 桶，且整体 rc 非零（不许静默吞掉）。

期望值：
  CATCH        真 bug，UT 必须报（errors > 0）
  MISS_FM      UT **结构上**看不见、由 FM 兜底的改动：UT 必须 errors == 0，
               且该条目必须在本家族的 FM_MUTANTS 里有对应项实证 FM 抓得到。
  EQUIV        逻辑等价的空变异：errors 必须 == 0，分子分母都不计。
  COMPILE_FAIL 故意写成编不过的，用来验"编译失败不会被读成绿"。

用法（各家族 mutants.py 里 `sys.exit(run(cfg))`）：
    python3 mutants.py              # UT 判别力
    python3 mutants.py --cov        # 覆盖闸自身的负测（短拍数必须判 FAILED）
    python3 mutants.py --fm         # FM 侧负测
    python3 mutants.py --compile-only
"""
import pathlib
import re
import shutil
import subprocess
import sys

INFRA_PAT = re.compile(r'(Licensed?|LICENSE|license).{0,40}(unavailable|expired|denied|fail)'
                       r'|No space left on device|Disk quota exceeded|Cannot allocate memory',
                       re.I)


class Cfg(object):
    def __init__(self, here, module, rtl_subdir, mut_file, rtl_files,
                 mutants, fm_mutants=(), fm_top=None, ncycles=20000,
                 extra_rtl=()):
        self.here = pathlib.Path(here).resolve().parent
        self.repo = self.here.parent.parent.parent
        self.build = self.here / 'neg_build'
        self.module = module
        self.rtl_subdir = pathlib.Path(rtl_subdir)     # 变异目标所在子目录（相对 rtl/）
        self.mut_file = mut_file                       # 被变异的核文件名
        self.rtl_files = list(rtl_files)               # (子目录, 文件名) 全部要拷进沙箱的
        self.extra_rtl = list(extra_rtl)
        self.mutants = mutants
        self.fm_mutants = list(fm_mutants)
        self.fm_top = fm_top
        self.ncycles = str(ncycles)


def _ut(cfg):
    return cfg.build / 'verif' / 'ut' / cfg.module


def prepare(cfg):
    if cfg.build.exists():
        shutil.rmtree(cfg.build)
    for sub, _f in cfg.rtl_files:
        (cfg.build / 'rtl' / sub).mkdir(parents=True, exist_ok=True)
    _ut(cfg).mkdir(parents=True)
    (cfg.build / 'scripts').symlink_to(cfg.repo / 'scripts')
    restore(cfg)
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(cfg.here / f, _ut(cfg) / f)
    # ★沙箱必须复现真实签核的 FM 配置（2026-09-20, agent/fubusy-wbarb 实测）★
    # 此前沙箱只复制 Makefile + tb.sv。Makefile 里的钉点是
    # `$(if $(wildcard fm_pins.tcl),FM_PIN_TCL=...)` —— 文件没跟过来，wildcard 就是空，
    # 于是 --fm 负测在**没有钉点**的配置下跑，而真实签核是带钉点跑的：两者不是同一个
    # 被测对象。本轮实测撞上过：WBArbiter_3 的常量寄存器负控在沙箱里跑成
    # "SUCCEEDED / unread 2 / PARTIAL"（钉点没生效），补上 fm_pins.tcl 之后才复现出
    # 真实配置下的 "FAILED / failing 1"，负控这才有意义。
    # 没有这些文件的家族不受影响（照旧什么都不拷）。
    for f in ('fm_pins.tcl', 'fm_pins_pre.tcl'):
        if (cfg.here / f).exists():
            shutil.copy(cfg.here / f, _ut(cfg) / f)
    if (cfg.here / 'fm_map').is_dir():
        shutil.copytree(str(cfg.here / 'fm_map'), str(_ut(cfg) / 'fm_map'))


def restore(cfg):
    for sub, f in cfg.rtl_files:
        shutil.copy(cfg.repo / 'rtl' / sub / f, cfg.build / 'rtl' / sub / f)


def target(cfg, where=None):
    sub, name = where or (cfg.rtl_subdir, cfg.mut_file)
    return cfg.build / 'rtl' / sub / name


def _split(m):
    """变异表条目：(期望, 说明, 锚点, 替换[, (子目录, 文件名)])。
    第 5 项用于把变异打进**别的**文件 —— WBArbiter 族要考的优先级法则在共享件
    rtl/common/xs_PriorityArbSelect.sv 里，不在自己的核文件里。"""
    return (m[0], m[1], m[2], m[3], m[4] if len(m) > 4 else None)


def apply_mutant(cfg, old, new, where=None):
    """自证：锚点必须存在、替换后文本必须真的变了，否则返回 False（判 INVALID）。"""
    sub, name = where or (cfg.rtl_subdir, cfg.mut_file)
    base_text = (cfg.repo / 'rtl' / sub / name).read_text()
    if old not in base_text:
        return False
    t = base_text.replace(old, new, 1)
    if t == base_text:
        return False
    target(cfg, where).write_text(t)
    return True


def run_ut(cfg, ncycles=None):
    """跑一轮 UT。★每次先删日志★：编译失败时绝不能读到上一轮的 errors。"""
    ut = _ut(cfg)
    for name in ('sim_1.log', 'sim_1_initregrandom.log', 'sim_1_initreg0.log'):
        p = ut / name
        if p.exists():
            p.unlink()
    r = subprocess.run(['make', 'run', 'SEED=1',
                        'NCYCLES=' + str(ncycles or cfg.ncycles)],
                       cwd=str(ut), stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT, universal_newlines=True)
    log = ut / 'sim_1.log'
    if not log.exists():
        return (None, r.returncode, r.stdout[-3000:])
    txt = log.read_text(errors='replace')
    m = re.search(r'checks=(\d+) errors=(\d+) bad_cov=(\d+)', txt)
    if not m:
        return (None, r.returncode, txt[-3000:])
    return ((int(m.group(1)), int(m.group(2)), int(m.group(3)),
             'TEST PASSED' in txt), r.returncode, '')


def run_fm(cfg, fm_top=None):
    """fm_top 可按条目覆盖：同一家族里不同变体的配置可以不同（例如 WBArbiter 只有
    N=1 的四个变体走钉点 + vmucp），负控必须跑在**它要考的那个变体**上。"""
    fm_top = fm_top or cfg.fm_top
    ut = _ut(cfg)
    log = ut / 'fm_work' / fm_top / 'fm.log'
    if log.exists():
        log.unlink()
    r = subprocess.run(['make', 'fm-' + fm_top], cwd=str(ut),
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                       universal_newlines=True)
    if not log.exists():
        return (None, None, '', r.returncode)
    txt = log.read_text(errors='replace')
    # ★判据钉在行首★：fm_shell 把入口 Tcl 逐行回显进 fm.log，里面同时有
    # SUCCEEDED 与 FAILED 两个字面量，裸子串判会两边都"命中"。
    m = re.search(r'^Verification (SUCCEEDED|FAILED|INCONCLUSIVE)', txt, re.M)
    mf = re.search(r'^Failing \(not equivalent\)((?:\s+\d+){8})\s*$', txt, re.M)
    return (m.group(1) if m else None,
            int(mf.group(1).split()[-1]) if mf else None,
            txt, r.returncode)


def baseline(cfg):
    print('=== 基线（未变异，%s 拍）===' % cfg.ncycles)
    base, rc, tail = run_ut(cfg)
    if base is None or rc != 0 or base[1] != 0 or base[2] != 0 or not base[3]:
        print('基线不绿（rc=%s, %s），负测无意义：\n%s' % (rc, base, tail))
        return None
    print('    checks=%d errors=%d bad_cov=%d TEST PASSED' % base[:3])
    return base


def run(cfg):
    args = sys.argv[1:]
    prepare(cfg)

    if '--compile-only' in args:
        bad = []
        for m in cfg.mutants:
            expect, name, old, new, where = _split(m)
            restore(cfg)
            if not apply_mutant(cfg, old, new, where):
                print('  %-76s ★锚点失效/文本未变 ⇒ INVALID★' % name)
                bad.append(name)
                continue
            r = subprocess.run(['make', 'compile'], cwd=str(_ut(cfg)),
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               universal_newlines=True)
            ok = (r.returncode != 0) if expect == 'COMPILE_FAIL' else (r.returncode == 0)
            print('  %-76s %s' % (name, 'ok' if ok else '★与期望不符★'))
            if not ok:
                bad.append(name)
        restore(cfg)
        return 1 if bad else 0

    if '--cov' in args:
        if baseline(cfg) is None:
            return 2
        res, rc, tail = run_ut(cfg, ncycles=20)
        if res is None:
            print('!! 20 拍那轮没有产生日志（rc=%s）：\n%s' % (rc, tail))
            return 1
        print('=== 覆盖闸负测：20 拍 ===')
        print('    checks=%d errors=%d bad_cov=%d TEST %s'
              % (res[0], res[1], res[2], 'PASSED' if res[3] else 'FAILED'))
        restore(cfg)
        if res[1] == 0 and res[2] > 0 and not res[3]:
            print('=== COV-NEG PASSED：errors=0 但覆盖不全，闸照样判 FAILED ===')
            return 0
        print('=== COV-NEG FAILED：覆盖闸没有独立发挥作用 ===')
        return 1

    if '--fm' in args:
        if not cfg.fm_mutants:
            print('本家族未声明 FM 变异表'); return 2
        print('=== FM 基线（未变异，top=%s）===' % cfg.fm_top)
        v, f, _txt, _rc = run_fm(cfg)
        print('    native=%s failing=%s' % (v, f))
        if v != 'SUCCEEDED' or f != 0:
            print('FM 基线就不干净，负测无意义'); return 2
        bad = []
        for fm in cfg.fm_mutants:
            name, old, new, expect_fail = fm[0], fm[1], fm[2], fm[3]
            where = fm[4] if len(fm) > 4 else None
            this_top = fm[5] if len(fm) > 5 else None   # 可选：按条目换 fm_top
            restore(cfg)
            if not apply_mutant(cfg, old, new, where):
                print('!! %-72s ★锚点失效/文本未变 ⇒ INVALID★' % name)
                bad.append(name); continue
            v, f, txt, mrc = run_fm(cfg, this_top)
            # ★expect_fail 允许第三种取值 'GATE:<marker>'（2026-09-20 实测逼出来的）★
            # 有些变异在**真实签核配置**下根本走不到 verify：WBArbiter 的 F2 把
            # has_full_q 变成无人读，于是 impl 侧多出一个 golden 没有的 unread 点，
            # fm_pins.tcl 的双射自检当场拒绝（WBARBITER_PIN_ERROR），fm_shell 停在那里，
            # 日志里没有任何 Verification 行。这**是被抓到了**，只是抓它的是钉点闸
            # 不是 verify。但"没有 Verification 行"同样是 license 挂了、top 名写错的
            # 症状，所以不许笼统地当成抓到 —— 必须点名是哪道闸：
            #   GATE:<marker> 要求同时满足 (a) 日志里出现 <marker> 行，
            #   (b) make rc != 0，(c) 日志里没有 `Verification SUCCEEDED`。
            # 三条缺一即判不符预期。
            if isinstance(expect_fail, str) and expect_fail.startswith('GATE:'):
                marker = expect_fail[5:]
                hit = re.search(r'^\s*' + re.escape(marker), txt, re.M) is not None
                ok = hit and mrc != 0 and v != 'SUCCEEDED'
                print('  %-72s gate=%-5s make_rc=%-3s native=%-10s %s'
                      % (name + (' [top=%s]' % this_top if this_top else ''),
                         'hit' if hit else 'MISS', mrc, v, 'OK' if ok else '★不符预期★'))
                if not ok:
                    bad.append(name)
                continue
            # ★fail-open 修复（2026-09-20 实测抓到）★
            # 原判据是 `expect_fail and v != 'SUCCEEDED'`。run_fm 在**没产生 fm.log**
            # （FM 根本没跑起来、license 拿不到、日志被删、top 名写错……）时返回
            # (None, None)，而 None != 'SUCCEEDED' 为真 ⇒ 这一条被记成 OK。
            # 本轮实测撞上：WBArbiter 的 F2 有一次跑出 native=None failing=None，
            # 照样印 OK、整批照样 PASSED 5/5 —— "FM 没跑"被读成了"FM 抓到了"。
            # 现在：拿不到 verdict 一律判 INVALID（既不算 OK 也不算抓到），当场停下来看。
            if v is None:
                print('!! %-72s ★没有产生 FM 判决（native=None）⇒ INVALID，'
                      'FM 没跑起来不等于抓到了★' % name)
                bad.append(name); continue
            ok = (v != 'SUCCEEDED' or (f or 0) > 0) if expect_fail else \
                 (v == 'SUCCEEDED' and f == 0)
            print('  %-72s native=%-12s failing=%-5s %s'
                  % (name + (' [top=%s]' % this_top if this_top else ''), v, f,
                     'OK' if ok else '★不符预期★'))
            if not ok:
                bad.append(name)
        restore(cfg)
        if bad:
            print('=== FM-NEG FAILED ===')
            for x in bad:
                print('   ', x)
            return 1
        print('=== FM-NEG PASSED：%d/%d 条 ===' % (len(cfg.fm_mutants), len(cfg.fm_mutants)))
        return 0

    if baseline(cfg) is None:
        return 2
    caught = total = 0
    invalid, equiv, infra, bad = [], [], [], []
    for m in cfg.mutants:
        expect, name, old, new, where = _split(m)
        restore(cfg)
        if not apply_mutant(cfg, old, new, where):
            print('!! %-72s ★锚点失效/文本未变 ⇒ 无效变异体（不计分子分母）★' % name)
            invalid.append(name); continue
        res, rc, tail = run_ut(cfg)
        if res is None:
            if INFRA_PAT.search(tail or ''):
                print('!! %-72s ★infra 失败（license/磁盘），单列★' % name)
                infra.append(name); continue
            if expect == 'COMPILE_FAIL':
                print('  %-72s 编译失败，符合 COMPILE_FAIL 期望' % name)
                caught += 1; total += 1; continue
            print('!! %-72s ★编不过 ⇒ 无效变异体（不计分子分母）★' % name)
            invalid.append(name); continue
        if expect == 'COMPILE_FAIL':
            print('!! %-72s ★居然编过了，与 COMPILE_FAIL 期望不符★' % name)
            bad.append(name); continue
        if expect == 'EQUIV':
            ok = res[1] == 0
            print('  %-72s errors=%-8d %s' % (name, res[1],
                  'EQUIV-ok（逻辑等价，分子分母都不计）' if ok
                  else '★居然报了 —— 说明它并不等价，注释在说假话★'))
            (equiv if ok else bad).append(name); continue
        total += 1
        if expect == 'CATCH':
            ok = res[1] > 0
            if ok:
                caught += 1
            print('  %-72s errors=%-8d %s' % (name, res[1], 'CAUGHT' if ok else '★MISSED★'))
        else:   # MISS_FM
            ok = res[1] == 0
            if ok:
                caught += 1     # 「换了一道闸」也算被闸住，但必须在 FM_MUTANTS 里有实证
            print('  %-72s errors=%-8d %s' % (name, res[1],
                  'MISS_FM-ok（UT 看不见，FM 侧有对应条目实证）' if ok
                  else '★居然报了 —— 期望是 UT 看不见，注释是错的★'))
        if not ok:
            bad.append(name)
    restore(cfg)
    print('=== 判别力：%d/%d（无效变异体 %d，逻辑等价空变异 %d，infra %d）==='
          % (caught, total, len(invalid), len(equiv), len(infra)))
    for tag, lst in (('无效变异体（不计分子分母）', invalid),
                     ('逻辑等价空变异（不计分子分母）', equiv),
                     ('infra 失败', infra), ('与预期不符', bad)):
        for x in lst:
            print('    [%s] %s' % (tag, x))
    return 1 if (bad or infra or caught != total) else 0
