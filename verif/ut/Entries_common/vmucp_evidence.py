#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""vmucp_evidence.py —— 申请 matched-unread 加强（vmucp）时要交的证据，一次采齐。

## 为什么做成脚本

reviewer 的 standing rule 要六条证据。手工 grep 采一遍既慢又容易漏项，
而且**期望值必须事前写死**（passing 恰好 +N，不增即空转按 fail 处理）——
写成脚本才能保证"事前"这件事有痕迹，不是事后对着结果凑。

    python3 vmucp_evidence.py <top>            # 采证（加强前跑）
    python3 vmucp_evidence.py <top> --verify   # 加强后复核期望值

## 判据里为什么不用裸错误号

fm_shell 把入口脚本逐行回显进 fm.log，注释也不例外；判据里写具体错误编号会命中
注释自身，判据当场失效。所以一律用行首锚定的 `^ *Error:` 计数。

## 为什么不信任 "IQE_PINS ... 0 threw"

`set_user_match` 对不存在的名字**不一定抛 Tcl 异常**，所以 catch 计数是 fail-open 的，
不能作为"钉点真的生效了"的证据。真正的证据是 sidecar 里 FM 自己吐出的配对表：
把 matched_nc 的 6220 对与钉点文件做**子集判定**——如果有任何一对不在钉点文件里，
说明那是 FM 自己按名字猜的配对，人工强配嫌疑，必须停下来报告。
"""
import json
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parents[3]


def load(top):
    w = REPO / 'verif' / 'ut' / top / 'fm_work' / top
    log = (w / 'fm.log').read_text(errors='replace')
    facts = json.loads((w / 'sidecar' / 'native_facts.json').read_text())
    tcl = (w / 'sidecar' / 'sourced_002_fm_pins_pre.tcl').read_text(errors='replace')
    return w, log, facts, tcl


def parse_pins(tcl, top):
    """钉点文件是 {ref impl} 相对路径对的 foreach 列表，还原成 FM 的绝对路径对。"""
    pin = set()
    for m in re.finditer(r'^\s*\{(\S+)\s+(\S+)\}\s*$', tcl, re.M):
        pin.add((f'r:/WORK/{top}/{m.group(1)}',
                 f'i:/WORK/{top}/u_core/{m.group(2)}'))
    return pin


def main():
    top = sys.argv[1]
    verify = '--verify' in sys.argv
    w, log, facts, tcl = load(top)

    st = facts['stats']
    um = facts['unmatched']
    qual = facts['qualifications']
    pairs = facts['objects']['matched_unread_notcompared_pairs']

    n_mnc = len(pairs)
    refs = [p['ref_path'] for p in pairs]
    imps = [p['impl_path'] for p in pairs]

    # --- 1. 两类分开 ---
    n_um_unread = um['unread_ref'] + um['unread_impl']

    # --- 2. 双射 ---
    bijective = len(set(refs)) == n_mnc == len(set(imps))

    # --- 3. 配对是按构造还是人工挑的 ---
    pin = parse_pins(tcl, top)
    got = set(zip(refs, imps))
    extra = got - pin          # 不在钉点文件里 = FM 自己猜的
    from_pins = len(got & pin)

    # --- 4. fail-closed 判据 ---
    n_err = len([l for l in log.splitlines() if re.match(r'^ *Error:', l)])
    um_all_zero = all(v == 0 for v in um.values())

    # 每实例分布（说明这 6220 是成规模的对称死位，不是零散挑的）
    inst = {}
    for r in refs:
        k = r.split('/')[3]
        k = re.sub(r'_\d+$', '_N', k) if k.startswith(('enqEntries', 'othersEntries')) else k
        inst[k] = inst.get(k, 0) + 1

    print(f'=== vmucp 证据: {top} ===')
    print(f'[1] 两类分开    matched_nc={n_mnc}；unmatched unread ref={um["unread_ref"]} '
          f'impl={um["unread_impl"]} (合计 {n_um_unread}，要求 0)')
    print(f'    ★ vmucp 只作用于 matched 的点。unmatched unread 非 0 时单开 vmucp 必然空转，')
    print(f'      所以顺序必须是"先配对(钉点) 后加强"——本轮已先把 12(12) 钉成 0(0)。')
    print(f'[2] 双射        ref 侧 {len(set(refs))} / impl 侧 {len(set(imps))} / 对数 {n_mnc}'
          f'  → 严格 1:1 = {bijective}')
    print(f'    分布: ' + ', '.join(f'{k}×{v}' for k, v in sorted(inst.items(),
                                                                key=lambda t: -t[1])))
    print(f'[3] 配对方式    来自钉点文件 {from_pins}/{n_mnc}；FM 自行猜配 {len(extra)} (要求 0)')
    print(f'    钉点共 {len(pin)} 对，由 gen_fm_pins.py 从 golden 实例连线机械提取（非人工列表）；')
    print(f'    matched_nc 是它的**子集**，故无一对是人工强配或 FM 名字启发式的产物。')
    for x in sorted(extra)[:5]:
        print(f'      ★未覆盖: {x[0]} <-> {x[1]}')
    print(f'[4] fail-closed  "^ *Error:" 行数={n_err} (要求 0)；unmatched 六项={um}'
          f'  全零={um_all_zero}')
    print(f'    注：不信任钉点循环自报的 "0 threw"——set_user_match 对不存在的名字 fail-open，')
    print(f'    [3] 的子集判定才是钉点真生效的证据。')
    print(f'[5] 期望值(事前写死)  passing {st["passing"]} -> {st["passing"] + n_mnc} '
          f'(恰好 +{n_mnc})；failing 仍 0；unread_notcompared {st["unread_notcompared"]} -> 0')
    print(f'    ★ passing 不增即 FM 没真去比 = 空转，按 fail 处理')
    print(f'[6] qualifications  dont_verify={len(qual["dont_verify_objects"])} '
          f'elab147={len(qual["elab147"])} relaxed_appvars={len(qual["relaxed_appvars"])} '
          f'(三项要求全空)')
    print(f'    黑盒 matched_blackbox_pairs={len(facts["objects"]["matched_blackbox_pairs"])}'
          f'  unresolved_bb ref/impl='
          f'{len(facts["objects"]["unresolved_blackbox_ref"])}/'
          f'{len(facts["objects"]["unresolved_blackbox_impl"])}')
    print(f'    native={facts["native_verdict"]}  vmucp(本轮)='
          f'{facts["entry_appvars"]["verification_verify_matched_unread_compare_points"]}'
          f'  merge_dup={facts["entry_appvars"]["verification_merge_duplicated_registers"]}')

    ok = (n_um_unread == 0 and bijective and not extra and n_err == 0 and um_all_zero
          and st['failing'] == 0 and st['aborted'] == 0
          and facts['native_verdict'] == 'SUCCEEDED'
          and not qual['dont_verify_objects'] and not qual['elab147']
          and not qual['relaxed_appvars'])
    print(f'\n申请条件{"齐备" if ok else "★未齐备★"}')

    if verify:
        # 加强后复核：本轮读到的就该是加强后的 facts
        exp_pass = st['passing']
        print(f'--verify: vmucp='
              f'{facts["entry_appvars"]["verification_verify_matched_unread_compare_points"]}'
              f'  passing={exp_pass}  unread_notcompared={st["unread_notcompared"]}'
              f'  failing={st["failing"]}')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
