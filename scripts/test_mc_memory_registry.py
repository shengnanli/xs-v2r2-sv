#!/usr/bin/env python3
"""test_mc_memory_registry.py —— MC 存储契约登记表（codex 0222）的正负测。

正例：P0 整表复算一致；P1 证书闭包条目（真实 sha）命中；P2 三层链 sram_array→array_N→ext 递归通过。
负例（每条都必须红，且按原因关键字断言）：
  N1  表外 design（从表副本删掉 ram_16x137）                       mc_not_registered
  N2  名字像 RAM 但未登记（ram_2x117 / sram_array_1p32x148m74s1h0l1b_pftch_pht）  mc_not_registered
  N3  普通功能模块（Queue16_CHIREQ）                               mc_not_registered
  N4  G1 字节变一位（副本里加一个空行）                              mc_field_mismatch:...:g1_sha256
  N5  登记的端口签名改了                                            mc_field_mismatch:...:port_signature
  N6  登记的 depth / mask 粒度 / collision 语义改了                 mc_field_mismatch
  N7  ram 写使能语义被改（副本 W0_en & 1'h1 -> W0_en & R0_en）       mc_template_mismatch
  N8  sram_array 外壳夹带普通逻辑（副本里多一个 assign）             mc_template_mismatch
  N9  sram_array 外壳夹带别的子模块（子实例换成 Queue16_CHIREQ）    mc_template_mismatch / mc_child
  N10 MBIST 端口被接上（副本把 bypass 接进 wmode）                   mc_template_mismatch
  N11 外壳的子模块未登记（表副本删掉 array_14）                      mc_child_not_registered
  N12 子模块类别不对（array_14 登记成 BLACKBOX）                     mc_class / mc_child_class
  N13 厂商叶子登记成 MODEL                                          mc_class_mismatch
  N14 厂商叶子与 vendor_boundary.tsv 不一致（副本 G1 改字节，表也跟着改）  mc_vendor_boundary_mismatch
  N15 证书闭包条目 sha 与登记不符                                   mc_closure_sha_mismatch
用法：python3 scripts/test_mc_memory_registry.py
"""
import os
import pathlib
import shutil
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mc_memory_registry as MC  # noqa: E402

G1 = pathlib.Path(MC.DEFAULT_G1) / 'golden-rtl'
fails = []


def chk(name, got, want):
    """want=True 表示必须通过；want='关键字' 表示必须失败且原因含该关键字。"""
    if want is True:
        ok = got is True
    else:
        ok = isinstance(got, str) and want in got
    print('  %-44s %s  %s' % (name, 'ok' if ok else '★FAIL★', str(got)[:110]))
    if not ok:
        fails.append(name)


def g1_copy(td, designs):
    root = pathlib.Path(td) / 'g1'
    (root / 'golden-rtl').mkdir(parents=True, exist_ok=True)
    for d in designs:
        for ext in ('.sv', '.v'):
            if (G1 / (d + ext)).is_file():
                (root / 'golden-rtl' / (d + ext)).write_bytes((G1 / (d + ext)).read_bytes())
    return root


def edit(root, design, old, new):
    p = root / 'golden-rtl' / (design + '.sv')
    t = p.read_text()
    if old not in t:
        raise SystemExit('负测前提变了：%s 里没有 %r' % (design, old))
    p.write_text(t.replace(old, new, 1))


def main():
    reg = MC.load_registry()
    TAG = 'sram_array_1p512x76m19s1h0l1b_l2_tag'
    # --- 正例
    chk('P0 整表复算', all(MC.check_entry(d, reg=reg) is True for d in reg) or 'red', True)
    sha = reg['ram_16x25']['g1_sha256']
    ok, cls = MC.check_golden_entry({'path': 'golden-rtl/ram_16x25.sv', 'kind': 'golden', 'sha256': sha}, reg=reg)
    chk('P1 闭包条目命中', ok or cls, True)
    chk('P2 三层链递归', MC.check_entry(TAG, reg=reg), True)
    # --- 负例：表外 / 像 RAM / 功能模块
    r2 = dict(reg); r2.pop('ram_16x137')
    chk('N1 表外 design', MC.check_entry('ram_16x137', reg=r2), 'mc_not_registered')
    chk('N2a ram_2x117 名字像 RAM', MC.check_entry('ram_2x117', reg=reg), 'mc_not_registered')
    chk('N2b sram_array pftch_pht 名字像 RAM', MC.check_entry('sram_array_1p32x148m74s1h0l1b_pftch_pht', reg=reg),
        'mc_not_registered')
    chk('N3 普通功能模块 Queue16_CHIREQ', MC.check_entry('Queue16_CHIREQ', reg=reg), 'mc_not_registered')
    # --- 负例：登记字段被改
    def row_mut(design, **kw):
        r = dict(reg)
        r[design] = dict(reg[design], **kw)
        return r
    chk('N5 端口签名改', MC.check_entry('ram_16x25', reg=row_mut(
        'ram_16x25', port_signature=reg['ram_16x25']['port_signature'].replace('[3:0]', '[4:0]', 1))),
        'mc_field_mismatch:ram_16x25:port_signature')
    chk('N6a depth 改', MC.check_entry('ram_16x25', reg=row_mut('ram_16x25', depth='32')),
        'mc_field_mismatch:ram_16x25:depth')
    chk('N6b mask 粒度改', MC.check_entry(TAG, reg=row_mut(TAG, mask_gran='38')),
        'mc_field_mismatch:%s:mask_gran' % TAG)
    chk('N6c collision 语义改', MC.check_entry('ram_16x25', reg=row_mut('ram_16x25', collision='write_first')),
        'mc_field_mismatch:ram_16x25:collision')
    with tempfile.TemporaryDirectory() as td:
        root = g1_copy(td, list(reg) + ['Queue16_CHIREQ'])
        chk('P3 G1 副本原样通过', MC.check_entry(TAG, reg=reg, g1_root=root), True)
        p = root / 'golden-rtl' / 'ram_16x25.sv'
        p.write_bytes(p.read_bytes() + b'\n')
        chk('N4 G1 字节变', MC.check_entry('ram_16x25', reg=reg, g1_root=root),
            'mc_field_mismatch:ram_16x25:g1_sha256')
        edit(root, 'ram_data_16x256', "if (W0_en & 1'h1)", 'if (W0_en & R0_en)')
        chk('N7 ram 写使能语义改', MC.check_entry('ram_data_16x256', reg=reg, g1_root=root), 'mc_template_mismatch')
        edit(root, TAG, '  array_14 array (', '  assign RW0_rdata_dbg = RW0_en;\n  array_14 array (')
        chk('N8 外壳夹带普通逻辑', MC.check_entry(TAG, reg=reg, g1_root=root), 'mc_template_mismatch')
        edit(root, 'sram_array_1p512x104m13s1h0l1b_l2_meta', '  array_15 array (', '  Queue16_CHIREQ array (')
        # 表也跟着改成新字节的推导值（模拟"有人顺手更新登记"）：仍须因子模块不是已登记 MC 层而红
        META = 'sram_array_1p512x104m13s1h0l1b_l2_meta'
        f9, _e9 = MC.derive(META, g1_root=root)
        chk('N9 外壳夹带别的子模块', MC.check_entry(META, reg=row_mut(META, **f9), g1_root=root),
            'mc_child_not_registered')
        edit(root, 'sram_array_1p512x16m16s1h0l1b_l2_repl', '(RW0_wmode & RW0_en)',
             '(RW0_wmode & RW0_en & mbist_dft_ram_bypass)')
        chk('N10 MBIST 端口被接上', MC.check_entry('sram_array_1p512x16m16s1h0l1b_l2_repl', reg=reg, g1_root=root),
            'mc_template_mismatch')
        # N14：厂商叶子字节变、表也跟着改（推导一致），但 vendor_boundary.tsv 不认
        ep = root / 'golden-rtl' / 'array_16_ext.v'
        ep.write_bytes(ep.read_bytes() + b'\n')
        f, _e = MC.derive('array_16_ext', g1_root=root)
        chk('N14 厂商叶子与 vendor_boundary 不一致', MC.check_entry(
            'array_16_ext', reg=row_mut('array_16_ext', g1_sha256=f['g1_sha256']), g1_root=root),
            'mc_vendor_boundary_mismatch')
    r11 = dict(reg); r11.pop('array_14')
    chk('N11 外壳的子模块未登记', MC.check_entry(TAG, reg=r11), 'mc_child_not_registered')
    r12 = row_mut('array_14', **{'class': 'MC_MEMORY_BLACKBOX'})
    chk('N12 子模块类别不对', MC.check_entry(TAG, reg=r12), 'mc_')
    chk('N13 厂商叶子登记成 MODEL', MC.check_entry(
        'array_18_ext', reg=row_mut('array_18_ext', **{'class': 'MC_MEMORY_MODEL'})), 'mc_class_mismatch')
    ok, why = MC.check_golden_entry({'path': 'golden-rtl/ram_16x25.sv', 'kind': 'golden',
                                     'sha256': '0' * 64}, reg=reg)
    chk('N15 闭包条目 sha 不符', ok or why, 'mc_closure_sha_mismatch')
    if fails:
        print('test_mc_memory_registry: ★%d 条不过★ %s' % (len(fails), fails))
        return 1
    print('test_mc_memory_registry: 全过（4 正 + 17 负）')
    return 0


if __name__ == '__main__':
    sys.exit(main())
