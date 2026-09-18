#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutants.py —— DelayReg 家族 UT 的判别力负测（`make mutants`）。

`errors=0` 只有在「注入真 bug 时 UT 会红」的前提下才有意义。
做法：把 rtl/common 的家族文件与本目录复制进 neg_build/（已在 .gitignore，
**变异不进库**），逐个注入一个真 bug，跑 20k 拍，要求每个都被 UT 抓出来。

★ 变异选型 ★
核层（xs_DelayReg_core.sv，一处变异同时打中 11 个变体）：
  M1  ★复位覆盖★ 只清第一级，其余级保持 —— golden 的复位臂把每一级都列全了；
      这一条是 +vcs+initreg+random 那轮的守卫。
  M2  ★复位/使能优先级翻转★ 写成 if(enable) ... else if(reset)：
      reset=1 且 enable=1 时移位而不是清零。golden 是 reset 在外层。
      （本条第一版是个**空变异**，见下面 M2 处的注释——MISSED 时先查变异本身。）
  M3  ★使能门控丢失★ 无条件移位，enable 形同虚设。
  M4  ★取错级★ 输出取倒数第二级（对 STAGES>1 的 9 个变体可观测）。
  M5  ★链方向反了★ stage[s] <= stage[s+1]。
  M6  ★复位值★ 清成全 1 而不是全 0。
  M7  ★首级来源错★ 第一级收末级（自环）而不是 d_in。
薄文件层（$bits 端口契约不变式**抓不到**的那一类：位宽不变、只是接错）：
  M8  DelayReg_26 打包时把 i_mask 与 i_offset 对调（都是 16 位，总位宽不变）。
  M9  DelayReg 打包时把 i_wpdest 与 i_otherwpdest_0 对调（都是 9 位）。
  M10 DelayReg_19 拆包时把 o_value_0 与 o_value_1 对调（都是 64 位）。
      —— 这三条正是 negtest 的盲区：负测台守的是"位宽抄错"，
         接错但位宽没变的情况只有逐拍比对能抓。两道闸各守一半，缺一不可。

★ 双向 ★ 只证"该报的报"是不够的：一个恒报警的 tb 也能让 M1..M10 全 CAUGHT。
所以另有两条**期望不报**的等价改写：
  N1  DelayReg_26 的打包约定整体翻转（pack 与 unpack 同时反序，电路一模一样）；
  N2  核里 `assign d_out = ...` 改写成 `always_comb d_out = ...`（同一个组合赋值）。
N1/N2 若报出 error，说明 tb 在对实现细节而不是端口行为下断言，同样算负测失败。

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
CORE = 'xs_DelayReg_core.sv'
FAMILY = [CORE, 'DelayReg.sv'] + ['DelayReg_%d.sv' % n
                                  for n in (16, 18, 19, 20, 21, 22, 23, 24, 25, 26)]
V26, V19, V00 = 'DelayReg_26.sv', 'DelayReg_19.sv', 'DelayReg.sv'
NCYCLES = '20000'

MUTANTS = [
    ('M1 ★复位覆盖★ 只清第一级，其余级保持', CORE,
     "      for (int unsigned s = 0; s < STAGES; s++)\n        stage[s] <= '0;",
     "      stage[0] <= '0;"),

    # ★实测踩到的坑（本轮）★：本条最早写成「把 `if (reset)` 换成
    # `if (enable && !reset) ... else if (reset)`」。真值表逐行对一遍就知道，
    # 那个写法与 golden **完全等价**（reset=1&enable=1 时第一个条件为假，
    # 照样落到复位臂）——是个**空变异**。跑出来 errors=0，看起来像"UT 抓不到
    # 优先级翻转"，其实是变异自己没改电路。★MISSED 的第一反应必须是先去看
    # 变异到底改了什么，而不是先去改 tb★（改 tb 就会把一个没问题的闸越描越黑）。
    # 下面是真正的优先级翻转：enable 在外层，reset=1&enable=1 时移位而不是清零。
    ('M2 ★复位/使能优先级翻转★ 使能压过复位', CORE,
     "    if (reset) begin\n"
     "      // ★每一级都清★（golden 的复位臂逐个寄存器列全，一个不落）\n"
     "      for (int unsigned s = 0; s < STAGES; s++)\n"
     "        stage[s] <= '0;\n"
     "    end\n"
     "    else if (enable) begin\n"
     "      stage[0] <= d_in;\n"
     "      for (int unsigned s = 1; s < STAGES; s++)\n"
     "        stage[s] <= stage[s-1];\n"
     "    end",
     "    if (enable) begin\n"
     "      stage[0] <= d_in;\n"
     "      for (int unsigned s = 1; s < STAGES; s++)\n"
     "        stage[s] <= stage[s-1];\n"
     "    end\n"
     "    else if (reset) begin\n"
     "      for (int unsigned s = 0; s < STAGES; s++)\n"
     "        stage[s] <= '0;\n"
     "    end"),

    ('M3 ★使能门控丢失★ 无条件移位', CORE,
     "    else if (enable) begin",
     "    else begin"),

    ('M4 ★取错级★ 输出取倒数第二级', CORE,
     "  assign d_out = stage[STAGES-1];",
     "  assign d_out = stage[STAGES > 1 ? STAGES-2 : 0];"),

    ('M5 ★链方向反了★ stage[s] <= stage[s+1]', CORE,
     "      for (int unsigned s = 1; s < STAGES; s++)\n        stage[s] <= stage[s-1];",
     "      for (int unsigned s = 1; s < STAGES; s++)\n        stage[s-1] <= stage[s];"),

    ('M6 ★复位值★ 清成全 1', CORE,
     "        stage[s] <= '0;",
     "        stage[s] <= '1;"),

    ('M7 ★首级来源错★ 第一级收末级（自环）', CORE,
     "      stage[0] <= d_in;",
     "      stage[0] <= stage[STAGES-1];"),

    # ---- 薄文件层：位宽不变、只是接错（negtest 的盲区）----
    ('M8 _26 打包时 i_mask 与 i_offset 对调（都是 16 位）', V26,
     "  assign payload_in =\n    {i_valid, i_addr, i_data, i_highData, i_mask, i_wLine, i_vecNeedSplit, i_eew,\n     i_offset,",
     "  assign payload_in =\n    {i_valid, i_addr, i_data, i_highData, i_offset, i_wLine, i_vecNeedSplit, i_eew,\n     i_mask,"),

    ('M9 base 打包时 i_wpdest 与 i_otherwpdest_0 对调（都是 9 位）', V00,
     "PLACEHOLDER_M9_OLD", "PLACEHOLDER_M9_NEW"),

    ('M10 _19 拆包时 o_value_0 与 o_value_1 对调（都是 64 位）', V19,
     "PLACEHOLDER_M10_OLD", "PLACEHOLDER_M10_NEW"),
]


def _resolve_placeholders():
    """M9/M10 的锚点依赖生成出来的折行位置，运行时现读现定，避免把折行写死。"""
    out = []
    for name, fname, old, new in MUTANTS:
        if old == 'PLACEHOLDER_M9_OLD':
            txt = (REPO / 'rtl' / 'common' / V00).read_text()
            m = re.search(r'  assign payload_in =\n((?:    .*\n)+?)(?=\n)', txt)
            body = m.group(1)
            if 'i_wpdest,' not in body or 'i_otherwpdest_0,' not in body:
                raise SystemExit('M9 锚点失配：打包块里找不到 i_wpdest / i_otherwpdest_0')
            nb = body.replace('i_wpdest,', '\x00', 1).replace(
                'i_otherwpdest_0,', 'i_wpdest,', 1).replace('\x00', 'i_otherwpdest_0,', 1)
            out.append((name, fname, '  assign payload_in =\n' + body,
                        '  assign payload_in =\n' + nb))
        elif old == 'PLACEHOLDER_M10_OLD':
            txt = (REPO / 'rtl' / 'common' / V19).read_text()
            m = re.search(r'  assign\n((?:    .*\n)+?)(?=\nendmodule)', txt)
            body = m.group(1)
            if 'o_value_0,' not in body or 'o_value_1,' not in body:
                raise SystemExit('M10 锚点失配：拆包块里找不到 o_value_0 / o_value_1')
            nb = body.replace('o_value_0,', '\x00', 1).replace(
                'o_value_1,', 'o_value_0,', 1).replace('\x00', 'o_value_1,', 1)
            out.append((name, fname, '  assign\n' + body, '  assign\n' + nb))
        else:
            out.append((name, fname, old, new))
    return out


def _noops():
    """期望 **不** 报警的等价改写。"""
    n = []
    # N1: _26 打包约定整体翻转（pack 与 unpack 同时反序）
    txt = (REPO / 'rtl' / 'common' / V26).read_text()
    mi = re.search(r'  assign payload_in =\n((?:    .*\n)+?)(?=\n)', txt)
    mo = re.search(r'  assign\n((?:    .*\n)+?)(?=\nendmodule)', txt)
    def rev(block, tail):
        names = re.findall(r'[io]_\w+', block)
        names.reverse()
        line, lines = '    {', []
        for k, nm in enumerate(names):
            piece = nm + ('}' + tail if k == len(names) - 1 else ',')
            if len(line) + len(piece) + 1 > 90 and not line.endswith('{'):
                lines.append(line); line = '     ' + piece
            else:
                line += ('' if line.endswith('{') else ' ') + piece
        lines.append(line)
        return '\n'.join(lines) + '\n'
    n.append(('N1 _26 打包约定整体翻转（pack+unpack 同时反序，电路不变）', V26, [
        ('  assign payload_in =\n' + mi.group(1),
         '  assign payload_in =\n' + rev(mi.group(1), ';')),
        ('  assign\n' + mo.group(1),
         '  assign\n' + rev(mo.group(1), ' = payload_out;')),
    ]))
    n.append(('N2 核里 assign d_out 改写成 always_comb（同一个组合赋值）', CORE, [
        ('  assign d_out = stage[STAGES-1];',
         '  always_comb d_out = stage[STAGES-1];'),
    ]))
    return n


def prepare():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / 'rtl' / 'common').mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / 'DelayReg').mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    restore()
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / 'DelayReg' / f)


def restore():
    for f in FAMILY:
        shutil.copy(REPO / 'rtl' / 'common' / f, BUILD / 'rtl' / 'common' / f)


def run_ut():
    ut = BUILD / 'verif' / 'ut' / 'DelayReg'
    subprocess.run(['make', 'run', 'SEED=1', 'NCYCLES=' + NCYCLES], cwd=str(ut),
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
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
    for name, fname, old, new in _resolve_placeholders():
        restore()
        tgt = BUILD / 'rtl' / 'common' / fname
        t = tgt.read_text()
        if old not in t:
            print('!! %s：锚点没找到，变异未生效（源码改过？请同步本文件）' % name)
            missed.append(name); continue
        tgt.write_text(t.replace(old, new, 1))
        res = run_ut()
        if res is None:
            print('!! %s：编译/运行失败，不算「被抓到」' % name)
            missed.append(name); continue
        ok = res[1] > 0
        print('  %-52s checks=%-8d errors=%-8d %s'
              % (name, res[0], res[1], 'CAUGHT' if ok else '★MISSED★'))
        if not ok:
            missed.append(name)

    false_alarm = []
    for name, fname, edits in _noops():
        restore()
        tgt = BUILD / 'rtl' / 'common' / fname
        t = tgt.read_text()
        ok_anchor = True
        for old, new in edits:
            if old not in t:
                print('!! %s：锚点没找到' % name); ok_anchor = False; break
            t = t.replace(old, new, 1)
        if not ok_anchor:
            false_alarm.append(name + '（锚点失配）'); continue
        tgt.write_text(t)
        res = run_ut()
        if res is None:
            print('!! %s：编译/运行失败' % name)
            false_alarm.append(name + '（编译失败）'); continue
        ok = res[1] == 0
        print('  %-52s checks=%-8d errors=%-8d %s'
              % (name, res[0], res[1], 'CLEAN(预期)' if ok else '★FALSE ALARM★'))
        if not ok:
            false_alarm.append(name)

    restore()
    if false_alarm:
        print('=== 负测失败：等价改写被误报（闸是"恒报警"的，CAUGHT 不算数）===')
        for m in false_alarm:
            print('   ', m)
        return 1
    if missed:
        print('=== MUTANTS FAILED：以下变异没被 UT 抓到 ===')
        for m in missed:
            print('   ', m)
        return 1
    print('=== MUTANTS PASSED：%d/%d 个变异全部被抓到，%d/%d 个等价改写全部未误报 ==='
          % (len(MUTANTS), len(MUTANTS), len(_noops()), len(_noops())))
    return 0


if __name__ == '__main__':
    sys.exit(main())
