#!/usr/bin/env python3
"""gen_assembly.py —— Predictor / Composer 装配壳的机械派生区生成器。

这两个 target 的 golden（Composer 4787 行 / Predictor 44908 行）里 **81% / 96% 是
子模块例化连线**：真逻辑只有寥寥几十行，其余全是把顶层端口一根根接到 5~272 个子模块
上。这种东西手抄一定抄错（G0→G1 这一轮就有 8 处 MBIST 地址 9→8 位宽改动藏在里面），
所以**从 G1 golden 现取现生成**，只做三件保真变换：

  1. 端口表：原样搬（名字/方向/位宽/顺序逐字来自 golden），按功能簇插分节注释。
  2. 子模块输出网：golden 用 `_<inst>_io_*` 命名（前导下划线是 firtool 防撞名的），
     去掉前导下划线成 `<inst>_io_*`，可读且仍一一对应。
  3. 例化块：连接对逐条搬运，只重排对齐 + 按端口名前缀插分节注释；被重命名的网名
     同步替换。**连接的配对关系一个字都不动。**

生成区在目标文件里用 `// BEGIN GENERATED(<tag>)` / `// END GENERATED` 圈起来，
本脚本只替换圈内内容，手写区（文件头、可读核、u_core 例化）绝不触碰。

用法:
    gen_assembly.py Composer            # 就地刷新 rtl/frontend/Composer.sv 的生成区
    gen_assembly.py Composer --check    # 只校验生成区是否与 golden 同步（CI 用）
"""
import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import svparse

GOLDEN = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

TARGETS = {
    'Composer':  'rtl/frontend/Composer.sv',
    'Predictor': 'rtl/frontend/Predictor.sv',
}

# 端口/连接分节：按名字前缀正则归类，顺序即匹配优先级。
PORT_SECTIONS = [
    (r'^(clock|reset)$',                    '时钟与复位'),
    (r'^io_reset_vector$',                  '复位向量（复位后第一个取指 PC）'),
    (r'^io_(s[0-3]_fire|in_valid|in_ready)', 'S0~S3 流水握手（fire = valid & ready，4 份 dup）'),
    (r'^io_in_bits_(s0_pc|ghist|folded_hist|s1_folded_hist)', 'S0 预测请求：PC + 全局/折叠历史'),
    (r'^io_in_bits_',                       'S0 预测请求：其余字段'),
    (r'^io_out_s1_',                        'S1 预测输出（uFTB 零气泡首版）'),
    (r'^io_out_s2_',                        'S2 预测输出（FTB / TAGE 覆盖）'),
    (r'^io_out_s3_',                        'S3 预测输出（SC / ITTAGE / RAS 覆盖）'),
    (r'^io_out_last_stage',                 '末级 meta / FTB entry（写回 FTQ，update 时原样送回）'),
    (r'^io_out_',                           '其余预测输出'),
    (r'^io_ctrl_',                          '各预测器使能开关（CSR 可关）'),
    (r'^io_update',                         'FTQ commit 回来的训练更新'),
    (r'^io_redirect',                       '重定向（错预测纠正 / 恢复历史）'),
    (r'^io_perf_',                          '性能计数（对齐 2 拍后输出）'),
    (r'^io_s1_ready$',                      'S1 就绪（三大表相与）'),
    (r'^boreChildrenBd_',                   'MBIST 子链地址/数据（bore）—— G1 把 addr/addr_rd 由 9 位收窄到 8 位'),
    (r'^sigFromSrams_',                     'MBIST SRAM 侧带外控制（每 bore 7 根：hold/bypass/bp_clken/aux_clk/aux_ckbp/mcp_hold/cgen）'),
    (r'^io_',                               '其余 io'),
    (r'',                                   '其余'),
]


def section_of(name):
    for pat, title in PORT_SECTIONS:
        if re.search(pat, name):
            return title
    return '其余'


def load_golden(mod):
    """从 G1 golden 取端口表 / 子模块输出网 / 例化。解析失败一律抛错（fail-closed）。"""
    path = os.path.join(GOLDEN, mod + '.sv')
    try:
        portlist, body = svparse.module(open(path, errors='replace').read(), mod)
        return (svparse.ports(portlist), svparse.child_nets(body),
                svparse.instances(body))
    except svparse.ParseError as e:
        raise SystemExit(f'FATAL: 解析 {path} 的 module {mod} 失败: {e}')


def rename_net(n):
    """firtool 的 `_<inst>_io_x` 前导下划线只为防撞名，去掉即可读。"""
    return n[1:] if n.startswith('_') and re.match(r'^_\w+_io_', n) else n


def emit_ports(ports):
    w = max((len(r) for _, _, r, _ in ports), default=0)
    out, cur = [], None
    for k, (name, d, rng, _) in enumerate(ports):
        sec = section_of(name)
        if sec != cur:
            out.append(f'  // ---- {sec} ----')
            cur = sec
        comma = '' if k == len(ports) - 1 else ','
        out.append(f'  {d:<6s} {rng:<{w}s} {name}{comma}')
    return out


def emit_nets(nets):
    w = max((len(r) for r, _ in nets), default=0)
    out, cur = [], None
    for rng, name in nets:
        inst = re.match(r'^_(\w+?)_io_', name).group(1)
        if inst != cur:
            out.append(f'  // ---- {inst} 的输出 ----')
            cur = inst
        out.append(f'  wire {rng:<{w}s} {rename_net(name)};')
    return out


INST_DOC = {
    'uftb':               '链头 uFTB(FauFTB)：32 路全相联微 FTB，S1 零气泡出第一版预测；'
                          '74 个顶层 S1 输出由它直驱，另把 s1 br_taken_mask 送给 tage',
    'tage':               '链 2/5 TAGE-SC：主方向预测器（几何历史标签表 + 统计校正），'
                          '改写方向后传给 ftb',
    'ftb':                '链 3/5 大容量组相联 FTB：给取指块的 CFI 槽/目标/fall-through',
    'ittage':             '链 4/5 ITTAGE：间接跳转目标预测，改写 jalr_target',
    'ras':                '链尾 RAS：返回地址栈，补 ret 目标；186 个顶层输出由它直驱'
                          '（S2 76 + S3 80 + last_stage 30）',
    'uftb_io_ctrl_delay': 'ctrl 打拍：CSR 开关信号延迟对齐到各预测器的使用级',
    'tage_io_ctrl_delay': 'ctrl 打拍（同上）',
    'ftb_io_ctrl_delay':  'ctrl 打拍（同上）',
    'ras_io_ctrl_delay':  'ctrl 打拍（同上）',
    'composer':           'Composer：5 个预测器的组合层（本层唯一的功能子模块）',
}


def emit_insts(insts, netmap):
    out = []
    for typ, name, conns in insts:
        doc = INST_DOC.get(name)
        out.append('')
        out.append('  // ' + '-' * 75)
        out.append(f'  // {typ} {name} —— {doc}' if doc else f'  // {typ} {name}')
        out.append('  // ' + '-' * 75)
        w = max(len(p) for p, _ in conns)
        out.append(f'  {typ} {name} (')
        cur = None
        for k, (port, expr) in enumerate(conns):
            sec = section_of(port)
            if sec != cur:
                out.append(f'    // -- {sec} --')
                cur = sec
            e = ' '.join(expr.split())
            for old, new in netmap:
                e = re.sub(r'\b' + re.escape(old) + r'\b', new, e)
            # golden 用 `(/* unused */)` 表示"这个子模块输出故意不接"，保留这个标记，
            # 免得读者以为是生成器漏掉了一根线。
            if not e:
                e = '/* unused */'
            comma = '' if k == len(conns) - 1 else ','
            out.append(f'    .{port:<{w}s} ({e}){comma}')
        out.append('  );')
    return out


def splice(text, tag, lines):
    b = f'  // BEGIN GENERATED({tag})'
    e = '  // END GENERATED'
    pat = re.compile(re.escape(b) + r'.*?' + re.escape(e), re.S)
    if not pat.search(text):
        raise SystemExit(f'FATAL: 目标文件里找不到 BEGIN GENERATED({tag}) 区')
    return pat.sub(lambda _: '\n'.join([b] + lines + [e]), text, count=1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('target', choices=sorted(TARGETS))
    ap.add_argument('--check', action='store_true',
                    help='只比对，不写回；不同步则退出码 1')
    ap.add_argument('--dry-run', action='store_true',
                    help='只解析 golden 并报规模，不需要目标文件存在（给还没起稿的 target 用）')
    a = ap.parse_args()

    ports, nets, insts = load_golden(a.target)
    netmap = [(n, rename_net(n)) for _, n in nets if rename_net(n) != n]

    if a.dry_run:
        print(f'{a.target}: 端口 {len(ports)} / 子模块输出网 {len(nets)} / '
              f'例化 {len(insts)} / 连接 {sum(len(c) for _, _, c in insts)}')
        for typ, name, conns in insts[:12]:
            print(f'    {typ:22s} {name:22s} {len(conns)} 根')
        if len(insts) > 12:
            print(f'    ... 其余 {len(insts) - 12} 个例化')
        return 0

    path = os.path.join(REPO, TARGETS[a.target])
    text = open(path).read()
    new = splice(text, 'ports', emit_ports(ports))
    new = splice(new, 'child-nets', emit_nets(nets))
    new = splice(new, 'instances', emit_insts(insts, netmap))

    if a.check:
        if new != text:
            print(f'OUT OF SYNC: {path} 的生成区与 G1 golden 不一致，请重跑生成器')
            return 1
        print(f'IN SYNC: {path}（端口 {len(ports)} / 子模块输出网 {len(nets)} / 例化 {len(insts)}）')
        return 0
    open(path, 'w').write(new)
    print(f'generated: {path}  端口 {len(ports)} / 子模块输出网 {len(nets)} / '
          f'例化 {len(insts)} / 连接 {sum(len(c) for _, _, c in insts)}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
