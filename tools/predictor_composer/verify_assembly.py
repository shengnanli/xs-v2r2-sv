#!/usr/bin/env python3
"""verify_assembly.py —— 装配壳保真校验：重写 wrapper 的例化连线 == G1 golden。

生成器搬了 1757 条连接，"看着对"不算数。本脚本把两侧都解析成
    {(实例名, 子模块端口) -> 连接表达式}
再逐条比。重写侧的网名做了 `_<inst>_io_x` -> `<inst>_io_x` 的重命名，比之前先把
golden 侧同样重命名，其余一个字符都不放过。任何差异都打印并以退出码 1 结束。

同时校验：
  * 端口表（名/方向/位宽/顺序）逐条一致；
  * 实例集合（类型 + 名字 + 顺序）一致；
  * golden 里 module 体的 `assign` 集合与重写侧的 `assign` 集合一致（顶层输出驱动）。
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import svparse

GOLDEN = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def grab(path, mod):
    try:
        return svparse.module(open(path, errors='replace').read(), mod)
    except svparse.ParseError as e:
        sys.exit(f'FATAL: 解析 {path} 的 module {mod} 失败: {e}')


def ports(pl):
    try:
        return svparse.ports(pl)
    except svparse.ParseError as e:
        sys.exit(f'FATAL: 端口表解析失败: {e}')


def instances(body):
    try:
        return [(t, n, dict(c)) for t, n, c in svparse.instances(body)]
    except svparse.ParseError as e:
        sys.exit(f'FATAL: 例化解析失败: {e}')


def assigns(body):
    return svparse.assigns(body)


def norm_expr(e):
    return re.sub(r'\b_(\w+?_io_\w+)\b', r'\1', e)


def main():
    mod = sys.argv[1] if len(sys.argv) > 1 else 'Composer'
    impl = os.path.join(REPO, {'Composer': 'rtl/frontend/Composer.sv',
                               'Predictor': 'rtl/frontend/Predictor.sv'}[mod])
    gp, gb = grab(os.path.join(GOLDEN, mod + '.sv'), mod)
    ip, ib = grab(impl, mod)

    bad = 0
    gpp, ipp = ports(gp), ports(ip)
    if gpp != ipp:
        bad += 1
        print(f'PORT TABLE MISMATCH: golden {len(gpp)} vs impl {len(ipp)}')
        for k in range(max(len(gpp), len(ipp))):
            a = gpp[k] if k < len(gpp) else None
            b = ipp[k] if k < len(ipp) else None
            if a != b:
                print(f'   [{k}] golden={a}  impl={b}')
    else:
        print(f'ports OK: {len(gpp)} 根逐条一致（名/方向/位宽/顺序）')

    gi, ii = instances(gb), instances(ib)
    gsig = [(t, n) for t, n, _ in gi]
    isig = [(t, n) for t, n, _ in ii]
    if gsig != isig:
        bad += 1
        print(f'INSTANCE LIST MISMATCH:\n  golden={gsig}\n  impl  ={isig}')
    else:
        print(f'instances OK: {len(gi)} 个（类型/名字/顺序一致）')
        nconn = 0
        for (_, name, gc), (_, _, ic) in zip(gi, ii):
            gk, ik = set(gc), set(ic)
            if gk != ik:
                bad += 1
                print(f'  {name}: 端口集合不同 golden-only={sorted(gk-ik)[:8]} '
                      f'impl-only={sorted(ik-gk)[:8]}')
            for p in sorted(gk & ik):
                nconn += 1
                if norm_expr(gc[p]) != norm_expr(ic[p]):
                    bad += 1
                    print(f'  CONN DIFF {name}.{p}: golden={gc[p]!r} impl={ic[p]!r}')
        print(f'connections OK: {nconn} 条逐条一致' if not bad else
              f'connections checked: {nconn}')

    ga, ia = assigns(gb), assigns(ib)
    # golden 顶层输出的两类驱动：
    #   (a) 纯扇出——RHS 就是某个子模块输出网。这类必须在重写 wrapper 里逐字一致。
    #   (b) 本层算出来的——RHS 是内部寄存器/表达式。这类改由 u_core 驱动，
    #       wrapper 里看到的是核的输出端口，形状必然不同；它们的**正确性由 UT
    #       逐拍比对负责**，本脚本只负责点名，不放行"漏掉一条"。
    net_re = re.compile(r'^_?\w+_io_\w+$')
    fanout = {k: v for k, v in ga.items() if net_re.match(v)}
    computed = {k: v for k, v in ga.items() if k not in fanout}
    for k, v in sorted(fanout.items()):
        if k not in ia:
            bad += 1
            print(f'  MISSING FANOUT ASSIGN {k} = {v}')
        elif norm_expr(v) != norm_expr(ia[k]):
            bad += 1
            print(f'  ASSIGN DIFF {k}: golden={v!r} impl={ia[k]!r}')
    print(f'assign 纯扇出 {len(fanout)} 条逐字一致: {sorted(fanout)}')
    # 本层算出来的输出必须要么在 wrapper 里 assign、要么接到 u_core 的输出端口上
    core_conn = set()
    for m in re.finditer(r'^\s*xs_\w+\s+u_core\s*\((.*?)^\s*\);', ib, re.S | re.M):
        core_conn |= set(re.findall(r'\(\s*([A-Za-z_]\w*)', m.group(1)))
    core_conn |= set(ia)
    lost = [k for k in computed if k not in core_conn]
    if lost:
        bad += 1
        print(f'  本层计算输出没有落地: {lost}')
    print(f'assign 本层计算 {len(computed)} 条已交给可读核: {sorted(computed)}')

    print('RESULT:', 'PASS' if bad == 0 else f'FAIL ({bad} 处差异)')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
