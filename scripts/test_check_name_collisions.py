#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_name_collisions.py 的自测。

为什么需要：全量扫真实基线时 SILENT_COLLISION 命中数是 0。**"扫出来 0" 和
"检测器根本不会响" 在报告里长得一模一样**，所以必须有一组人造基线证明它会响。
同样地，fail-closed 也得证明：喂一行看不懂的端口声明进去，必须报错退出，
不能悄悄跳过那个模块（跳过 = 该模块永远不会被判为冲突 = 假阴性）。

跑法: python3 scripts/test_check_name_collisions.py     （退出码 0 = 全过）
"""
import os
import pathlib
import shutil
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import check_name_collisions as C  # noqa: E402


def mod(name, ports, body):
    """拼一个 firtool 风格的模块。ports = [(dir, '[N:0]' 或 '', 名字)]"""
    lines = ['module %s(' % name]
    lines += ['  %s %s %s,' % p for p in ports[:-1]]
    lines += ['  %s %s %s' % ports[-1]]
    lines += [');', body, 'endmodule', '']
    return '\n'.join(lines)


def write(root, name, text):
    (pathlib.Path(root) / (name + '.sv')).write_text(text)


IO1 = [('input', '', 'clock'), ('input', '', 'a'), ('output', '', 'z')]
IO2 = [('input', '', 'clock'), ('input', '[7:0]', 'a'), ('output', '', 'z')]

failures = []


def check(cond, what):
    print(('  ok   ' if cond else '  FAIL ') + what)
    if not cond:
        failures.append(what)


def _shifted_baselines(g0, g1, io_a_g0, io_a_g1):
    """复刻真实的"编号整体平移"形状。

    坑位 S1=(Top,u0)、S2=(Top,u1)：
      G0:  S1 -> A(体 X)      S2 -> B(体 Y)
      G1:  S1 -> Z(体 X)      S2 -> A(体 Y)
    于是名字 `A` 在两版下是**不同的设计元素**：G0 的 A 在 G1 里叫 Z。
    """
    os.makedirs(g0); os.makedirs(g1)
    body_x = "  assign z = a ^ 1'b0;"
    body_y = "  assign z = a ^ 1'b1;"
    write(g0, 'Top', mod('Top', IO1, '  A u0 (\n  );\n  B u1 (\n  );'))
    write(g0, 'A', mod('A', io_a_g0, body_x))
    write(g0, 'B', mod('B', IO1, body_y))
    write(g1, 'Top', mod('Top', IO1, '  Z u0 (\n  );\n  A u1 (\n  );'))
    write(g1, 'Z', mod('Z', io_a_g0, body_x))
    write(g1, 'A', mod('A', io_a_g1, body_y))
    return C.analyse(C.Baseline(g0), C.Baseline(g1))


def case_silent_collision(tmp):
    """同名、端口表逐位相同、但坑位上换了人 —— 只有例化点判据能看见。"""
    rows = _shifted_baselines(tmp + '/s0', tmp + '/s1', IO1, IO1)
    by = dict((r['name'], r) for r in rows)
    check('A' in by and by['A']['verdict'] == 'SILENT_COLLISION',
          'SILENT_COLLISION 会响（同名 + 端口表逐位相同 + 坑位换人）')
    check('A' in by and by['A']['fwd'] == 'Z' and by['A']['fwd_by'] == 'site',
          'SILENT_COLLISION 给出正确对应 A(G0) -> Z(G1)，判据 site')
    check('A' in by and by['A']['rev'] == 'B',
          'SILENT_COLLISION 反向也对：A(G1) 在 G0 里是 B')


def case_renumber_collision(tmp):
    """同名、坑位换人、且端口表也不同 —— 比端口也能看见的那一类。"""
    rows = _shifted_baselines(tmp + '/r0', tmp + '/r1', IO1, IO2)
    by = dict((r['name'], r) for r in rows)
    check('A' in by and by['A']['verdict'] == 'RENUMBER_COLLISION',
          'RENUMBER_COLLISION 会响')


def case_evolved_not_collision(tmp):
    """同名、同坑位、只是内容与端口变了 —— 必须判 EVOLVED，不能误报成冲突。"""
    g0, g1 = tmp + '/e0', tmp + '/e1'
    os.makedirs(g0); os.makedirs(g1)
    for root, io in ((g0, IO1), (g1, IO2)):
        write(root, 'Top', mod('Top', IO1, '  A u0 (\n  );'))
        write(root, 'A', mod('A', io, "  assign z = |a;"))
    rows = C.analyse(C.Baseline(g0), C.Baseline(g1))
    by = dict((r['name'], r) for r in rows)
    check('A' in by and by['A']['verdict'] == 'EVOLVED',
          'EVOLVED 不被误报成冲突（同名同坑位，只是端口变宽）')


def case_site_common(tmp):
    """坑位集合不完全相同，但有共有坑位 —— site_common 应认出来。"""
    g0, g1 = tmp + '/c0', tmp + '/c1'
    os.makedirs(g0); os.makedirs(g1)
    write(g0, 'Top', mod('Top', IO1, '  A u0 (\n  );\n  A u1 (\n  );'))
    write(g1, 'Top', mod('Top', IO1, '  A u0 (\n  );'))
    write(g0, 'A', mod('A', IO1, "  assign z = a;"))
    write(g1, 'A', mod('A', IO2, "  assign z = |a;"))
    b0, b1 = C.Baseline(g0), C.Baseline(g1)
    hit, by = C.resolve(b0, b1, 'A')
    check(hit == ['A'] and by in ('site', 'site_common'),
          'site_common：坑位少了一处仍能定位（判据=%s）' % by)


def case_fail_closed(tmp):
    """看不懂的端口声明必须抛 ParseError，绝不静默跳过。"""
    bad = tmp + '/bad'
    os.makedirs(bad)
    (pathlib.Path(bad) / 'X.sv').write_text(
        'module X(\n  input a,\n  wat [3:0] b\n);\nendmodule\n')
    try:
        C.Baseline(bad)
        check(False, 'fail-closed：坏端口行必须抛 ParseError')
    except C.ParseError:
        check(True, 'fail-closed：坏端口行抛了 ParseError')
    rc = C.main(['--g0', bad, '--g1', bad])
    check(rc == 2, 'fail-closed：main() 在解析失败时返回退出码 2（实得 %s）' % rc)


def case_real_baselines_parse():
    """真实 G0/G1 必须能整体解析通过——解析器一旦看不懂什么就等于漏检。"""
    for root in (C.G0_DEFAULT, C.G1_DEFAULT):
        if not os.path.isdir(root):
            print('  skip  %s 不存在' % root)
            continue
        try:
            b = C.Baseline(root)
            check(len(b.mods) > 1000, '%s 解析出 %d 个模块' % (root, len(b.mods)))
        except C.ParseError as e:
            check(False, '%s 解析失败: %s' % (root, e))


def main():
    tmp = tempfile.mkdtemp(prefix='cnc_test_')
    try:
        print('人造基线用例:')
        case_silent_collision(tmp)
        case_renumber_collision(tmp)
        case_evolved_not_collision(tmp)
        case_site_common(tmp)
        case_fail_closed(tmp)
        print('真实基线用例（慢，约 2 分钟）:')
        case_real_baselines_parse()
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    if failures:
        print('\n%d 个用例失败' % len(failures))
        return 1
    print('\n全部通过')
    return 0


if __name__ == '__main__':
    sys.exit(main())
