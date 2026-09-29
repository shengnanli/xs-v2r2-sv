#!/usr/bin/env python3
"""test_assembly_bbox_scope.py —— assembly 黑盒对称性的作用域（codex 0199 裁定 B'）自证。

规则：只比较当前 target 顶层可达的实例（路径以 `<side>:/WORK/<top>/` 开头）；FM 容器里
其它 design root 下的黑盒（merge_dup 唯一化生成的辅助设计）只作诊断，不参与判决。

四类用例（前三类是负测，必须仍判不过）：
  N1 顶层内 impl 多一个实例            -> 失败
  N2 顶层内 impl 少一个实例            -> 失败
  N3 顶层内路径错配（同设计、换路径）  -> 失败
  P1 BankedDataArray 形：顶层内两侧逐路径相同，impl 另有 aux root 的 16 个副本 -> 通过
另加：
  N4 没有 top                          -> 失败（不许无作用域放行）
  N5 aux 前缀伪装（/WORK/<top>_x/）    -> 不算顶层，也不能让顶层缺的实例被补上
用法: python3 scripts/test_assembly_bbox_scope.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fm_verdict as V  # noqa: E402

TOP = 'BankedDataArray'
DES = 'array_7_ext'


def top_objs(n=4):
    out = set()
    for b in range(n):
        for side in ('r', 'i'):
            out.add((side, DES, f'{side}:/WORK/{TOP}/data_banks_0_{b}/data_bank_0/array/array/{DES}'))
    return out


def aux_objs():
    return {('i', DES, f'i:/WORK/DataSRAMBank_4_{k}/data_bank_3/array/array/{DES}') for k in range(4)}


def decl_of(objs):
    return {'objects': [{'side': s, 'design': d, 'path': p, 'class': 'vendor_macro'}
                        for s, d, p in sorted(objs)]}


def check(observed, declared, top=TOP):
    diag = {}
    r = V._assembly_bbox_check(set(observed), {}, decl_of(declared), top=top, diag=diag)
    return r, diag


def main():
    fails = []

    def expect(name, cond, detail):
        print(f'  {name:48s} {"ok" if cond else "★FAIL★"}  {detail}')
        if not cond:
            fails.append(name)

    base = top_objs()
    # P1：顶层逐路径相同 + impl 侧 aux root 副本（声明里也列了，和现有 allow 形状一致）
    r, d = check(base | aux_objs(), base | aux_objs())
    expect('P1 aux root 副本不影响判决', r is True and d.get('bbox_aux_observed') == 4, (r, d))
    # P1b：aux 只在观测里、声明里没有 —— 同样不影响（辅助 root 增减不得改变 verdict）
    r, d = check(base | aux_objs(), base)
    expect('P1b aux 只观测不声明也不影响', r is True, (r, d))

    extra = ('i', DES, f'i:/WORK/{TOP}/data_banks_0_9/data_bank_0/array/array/{DES}')
    r, _ = check(base | {extra}, base)
    expect('N1 顶层内多一个实例 -> 失败', r is not True, r)

    missing = sorted(k for k in base if k[0] == 'i')[0]
    r, _ = check(base - {missing}, base)
    expect('N2 顶层内缺一个实例 -> 失败', r is not True, r)

    moved = ('i', DES, missing[2].replace('data_bank_0', 'data_bank_7'))
    r, _ = check((base - {missing}) | {moved}, base)
    expect('N3 顶层内路径错配 -> 失败', r is not True, r)

    r, _ = check(base, base, top=None)
    expect('N4 没有 top -> 失败', r is not True, r)

    # N5：拿 /WORK/<top>_x/ 下的对象冒充顶层实例，去补顶层缺的那一个
    fake = ('i', DES, missing[2].replace(f'/WORK/{TOP}/', f'/WORK/{TOP}_x/'))
    r, _ = check((base - {missing}) | {fake}, base)
    expect('N5 前缀伪装不能补缺 -> 失败', r is not True, r)

    # N6：两侧计数对称但顶层内 ref 多出一个 impl 没有的设计实例 -> 失败（对称性仍在顶层内判）
    ref_only = ('r', 'array_8_ext', f'r:/WORK/{TOP}/tag/array/array/array_8_ext')
    r, _ = check(base | {ref_only}, base | {ref_only})
    expect('N6 顶层内两侧不对称 -> 失败', r is not True, r)

    if fails:
        print(f'test_assembly_bbox_scope: ★{len(fails)} 条不过★ {fails}')
        return 1
    print('test_assembly_bbox_scope: 全过（3 类负测 + aux root 正样本 + 无 top/前缀伪装/不对称）')
    return 0


if __name__ == '__main__':
    sys.exit(main())
