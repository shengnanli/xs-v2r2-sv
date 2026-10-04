#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_tb.py —— 生成 L2Top UT 的 tb.sv：golden L2Top vs 重写 L2Top_xs 同激励逐拍比对。

tb 骨架（双例化、逐拍全输出比对、CHI 链路 / 信用模型、RXRSP/RXDAT 选目标、未复位寄存器同步收割、arm 分组、覆盖）
直接复用 verif/ut/TL2CHICoupledL2/gen_tb.py 的 tb()，只换三样：
  * 顶层名 L2Top、TL2CHICoupledL2 的实例路径前缀 inner_l2cache.；
  * 输入激励（drive_expr）：L2Top 的口是核那一侧的 TileLink（DCache 的 TL-C 经 inner_logger_in_0、ICache / PTW / MMIO
    的 TL-UL），地址经 inner_xbar 按 [7:6] 分到 4 个 bank；A/C/E 偏置仍用 Slice tb 的规则；核 ↔ Tile 的边带信号随机；
  * 额外的初值同步：L2Top 这一层 TLBuffer 里每个队列的存储体（两侧都是同一份 golden ram 模型，实例名相同；
    TLBuffer_13 重写件把 4 个 bank 包进 u_bank_<b>）、两个 TLXbar 仲裁器状态（从 verif/ut/TLXbar_5 / _6 的 tb 收割）。

用法: python3 gen_tb.py [--check]
"""
import importlib.util
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
UT = HERE.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN', '/home/eda/xs-env/G1-canonical/golden-rtl'))

_spec = importlib.util.spec_from_file_location('tl2_gen_tb', str(UT / 'TL2CHICoupledL2' / 'gen_tb.py'))
tl2 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(tl2)

TOP = 'L2Top'
PFX = 'inner_l2cache.'

# ---------------------------------------------------------------------------
# 激励
# ---------------------------------------------------------------------------
SLICE_LIKE = 'auto_inner_logger_in_0_'      # DCache 的 TL-C


def drive_expr(name, w):
    if name.startswith(SLICE_LIKE):
        f = name[len(SLICE_LIKE):]
        e = tl2.slice_tb.drive_expr('io_in_' + f, w)
        return e.replace('pick_addr()', 'pick_addr($urandom_range(0, 3))')
    m = re.match(r'auto_inner_(logger_in_1|ptw_to_l2_buffer_in)_a_(\w+)$', name)
    if m:                                     # ICache / PTW 的读（TL-UL Get）
        f = m.group(2)
        if f == 'valid':
            return '($urandom_range(0, 7) == 0)'
        if f == 'bits_opcode':
            return "($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'h4"
        if f == 'bits_size':
            return "($urandom_range(0, 7) == 0) ? 3'($urandom) : 3'h6"
        if f == 'bits_address':
            return 'pick_addr($urandom_range(0, 3))'
        if f == 'bits_source':
            return "4'($urandom_range(0, 3))"
    if re.match(r'auto_inner_(buffers|i_mmio_buffer)_in_a_valid$', name):
        return '($urandom_range(0, 7) == 0)'
    if re.match(r'auto_inner_(buffers|i_mmio_buffer)_in_a_bits_address$', name):
        # 核侧 MMIO / 非缓存访问：inner_xbar_1（TLXbar_6）只认 [47:30]==0 的地址，再按区段分 3 个出口
        # （0x3801_0xxx / 0x3802_20xx 两个设备区与其余），三类各给一部分
        return ("($urandom_range(0, 3) == 0) ? 48'h3801_0000 + 48'($urandom_range(0, 'hFFF)) : "
                "($urandom_range(0, 2) == 0) ? 48'h3802_2000 + 48'($urandom_range(0, 'hFF)) : "
                "48'($urandom_range(0, 'h3FFF_FFFF))")
    if name == 'auto_inner_buffers_in_a_bits_opcode':
        return 'pick_mmio_opcode()'
    if name.startswith('auto_inner_buffers_out_d_'):
        if name.endswith('_valid'):
            return '($urandom_range(0, 3) == 0)'
        if name.endswith('_bits_opcode'):
            return "($urandom_range(0, 1) == 0) ? 4'h1 : 4'h0"
    if re.match(r'auto_inner_\w+_int_in_\w+$', name):
        return '($urandom_range(0, 15) == 0)'
    if re.match(r'io_beu_errors_\w+_ecc_error_valid$', name):
        return '($urandom_range(0, 31) == 0)'
    if name in ('io_msiInfo_fromTile_valid', 'io_msiAck_fromCore', 'io_cpu_halt_fromCore',
                'io_cpu_critical_error_fromCore', 'io_l3Miss_fromTile', 'io_clintTime_fromTile_valid'):
        return '($urandom_range(0, 3) == 0)'
    if name == 'io_hartIsInReset_resetInFrontend':
        return '($urandom_range(0, 63) == 0)'
    if re.match(r'io_traceCoreInterface_fromCore_toEncoder_groups_\d_bits_itype$', name):
        return "($urandom_range(0, 1) == 0) ? 4'($urandom_range(1, 2)) : 4'($urandom)"   # 一半是 trap（异常 / 中断）
    if name == 'auto_inner_l2cache_pf_recv_in_addr_valid':
        return '($urandom_range(0, 7) == 0)'
    if name == 'auto_inner_l2cache_pf_recv_in_pf_source':
        return 'pick_pf_source()'
    return tl2.drive_expr(name, w)


VADDR_OVERRIDE = [
    "if ($urandom_range(0, 3) != 0) %sa_bits_user_vaddr = 44'(%sa_bits_address);" % (SLICE_LIKE, SLICE_LIKE),
]

_L2TOP_PORTS = {n for _, _, n in tl2.ports(TOP)}
# TL2CHICoupledL2 的覆盖项里引用 TL2 端口（@名）而 L2Top 没有同名端口的，换成 L2Top 自己的项（见下）
COVER = [(c, e) for c, e in tl2.COVER if all(n in _L2TOP_PORTS for n in re.findall(r'@(\w+)', e))] + [
    ('DCache A 收下', '@auto_inner_logger_in_0_a_valid & @auto_inner_logger_in_0_a_ready'),
    ('DCache D 收下', '@auto_inner_logger_in_0_d_valid & @auto_inner_logger_in_0_d_ready'),
    ('DCache B 发出', '@auto_inner_logger_in_0_b_valid & @auto_inner_logger_in_0_b_ready'),
    ('ICache D 收下', '@auto_inner_logger_in_1_d_valid & @auto_inner_logger_in_1_d_ready'),
    ('PTW D 收下', '@auto_inner_ptw_to_l2_buffer_in_d_valid & @auto_inner_ptw_to_l2_buffer_in_d_ready'),
    ('外部 MMIO A 发出', '@auto_inner_buffers_out_a_valid & @auto_inner_buffers_out_a_ready'),
    ('BEU 收到 L1 错误', '@io_beu_errors_dcache_ecc_error_valid & ~@io_hartIsInReset_toTile'),
    ('trace trap 锁存', '@io_traceCoreInterface_fromCore_toEncoder_groups_0_valid & @io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype == 4\'h1'),
    ('hartIsInReset', '@io_hartIsInReset_toTile'),
]
# tl2.COVER 里的 golden 内部名（hintFire 等）由 tb() 加 u_g.inner_l2cache. 前缀；L2Top 层的 @ 名是 L2Top 端口

ARM_GROUPS = tl2.ARM_GROUPS


# ---------------------------------------------------------------------------
# L2Top 层的额外初值同步
# ---------------------------------------------------------------------------
def golden_insts(mod):
    t = (GOLDEN / (mod + '.sv')).read_text()
    b = t[t.index('\nmodule %s(' % mod):]
    return re.findall(r'^  (\w+) (\w+) \($', b, re.M)


def queue_ram(mod):
    """golden 队列模块里的 ram 实例名（重写件同名，见 rtl/uncore/Queue2_*.sv）"""
    rams = [(m, i) for m, i in golden_insts(mod) if m.startswith('ram_')]
    if len(rams) != 1:
        raise SystemExit('%s 里的 ram 实例不是恰好 1 个: %s' % (mod, rams))
    return rams[0][1]


def extra_syncs():
    out = []
    for mod, inst in golden_insts(TOP):
        if not mod.startswith('TLBuffer_'):
            continue
        for qmod, q in golden_insts(mod):
            if not qmod.startswith('Queue2_'):
                continue
            ram = queue_ram(qmod)
            ipath = q
            if mod == 'TLBuffer_13':   # 重写件：4 个 bank 各一个 xs_TLBuffer_13_bank（u_bank_<b>），队列名去掉 _<b> 后缀
                mm = re.match(r'(\w+_q)(?:_(\d))?$', q)
                ipath = 'u_bank_%s.%s' % (mm.group(2) or '0', mm.group(1))
            out.append(('%s.%s.%s.Memory' % (inst, q, ram), '%s.%s.%s.Memory' % (inst, ipath, ram), False))
    # 两个 TLXbar 的仲裁器状态：从各自 UT 的 tb 收割 force 行（x_u_impl / x_u_gold 换成本层实例）
    for ut, inst in (('TLXbar_5', 'inner_xbar'), ('TLXbar_6', 'inner_xbar_1')):
        n = 0
        for ln in (UT / ut / 'tb.sv').read_text().split('\n'):
            m = re.match(r'^\s*force\s+x_u_impl\.(\S+)\s*=\s*(.+?);\s*$', ln)
            if not m:
                continue
            g = m.group(2).replace('x_u_gold.', 'u_g.%s.' % inst)
            out.append((('RAW', g), '%s.%s' % (inst, m.group(1)), True))
            n += 1
        if n == 0:
            raise SystemExit('从 %s/tb.sv 没收割到 force 行' % ut)
    return out


def main():
    syncs = extra_syncs()
    new = tl2.tb(top=TOP, pfx=PFX, drive=drive_expr, extra_drive=VADDR_OVERRIDE, cover=COVER,
                 arm_groups=ARM_GROUPS, extra_syncs=syncs,
                 title='L2Top UT：golden L2Top 与重写 L2Top_xs 双例化，同激励逐拍比对',
                 genfile='verif/ut/L2Top/gen_tb.py', mmio_one_in=8)
    p = HERE / 'tb.sv'
    cur = p.read_text() if p.exists() else None
    if '--check' in sys.argv[1:]:
        if cur != new:
            print('gen_tb(L2Top): DRIFT tb.sv')
            return 1
        print('gen_tb(L2Top): OK')
        return 0
    if cur != new:
        p.write_text(new)
        print('gen_tb(L2Top): 更新 tb.sv')
    else:
        print('gen_tb(L2Top): 已是最新')
    return 0


if __name__ == '__main__':
    sys.exit(main())
