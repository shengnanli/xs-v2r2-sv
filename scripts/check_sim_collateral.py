#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_sim_collateral.py —— 仿真 collateral 防腐闸：清单完整性 + DPI 接口与 golden 一致。

## 这道闸守的是什么（2026-09-14，codex 0160 §Canonical simulation collateral）

`verif/sim/collateral/` 是**一次干净 checkout 能跑起整芯片仿真**所缺的那一小块：
difftest 的 DPI C++ 胶水（`generated-src/` 6 个文件）与 `build/` 下 7 个 Chisel 派生件。
G1-canonical 只冻结了 `golden-rtl/`（2061 个 .sv/.v/.conf/.fir），**不含 generated-src**，
所以「唯一 golden 对照」本身不足以复现一次仿真 —— 缺的就是这 13 个文件。

这些文件是**生成物**，进版本库就有腐烂风险：RTL 换了一版、DPI 接口跟着变，而库里这份
不会自己跟着走。于是必须有一道闸，把「库里这份」与「golden RTL 要求的那份」逐次对齐。

## 三条判据

**A. 清单完整性（双向）**：`MANIFEST.sha256` 里的每个文件都要存在且 sha256 相符；
   `generated-src/` 与 `build/` 下也不许有清单外的文件。双向是必须的 —— 只查一个方向的话，
   「悄悄多塞一个文件进去」和「悄悄删掉一个」各能从一边溜过去。
   清单**只覆盖这两个生成物目录**；同级的 `README.md` / `seed.sh` 是手写源码，走 review
   而不是走 sha —— 否则改一行注释就要重出清单，清单也就贬值成随手重出的东西了。

**B. DPI 接口集合 == golden 例化集合（fail-closed）**：
   collateral 的 `difftest-dpic.cpp` 提供的 `v_difftest_*` 函数名集合，必须**恰好等于**
   golden `GatewayEndpoint.sv` 例化的 `DummyDPICWrapper_*` 名字集合。

   这条判据不是凭空定的，它复刻 `verif/sim/run_fullchip.sh` 里已经在跑的 `check_dpic`
   门禁，把同一条判据从「跑仿真时才发现」提前到「跑闸时就发现」。

   ★ 它抓的是一个真出过事的形态 ★：`XiangShan/build/generated-src` 那份是
   `--fpga-platform --disable-all --remove-assert` 那次 make 的产物，而 `build/rtl`
   是 `--enable-difftest` 那次的 —— 两次 make 不是同一次配置。golden RTL 例化 27 种
   `DummyDPICWrapper_*`，那份 dpic 只给 21 个函数，少 12 个：
     ArchFpRegState ArchIntRegState ArchVecRegState AtomicEvent CMOInvalEvent
     CommitData L1TLBEvent L2TLBEvent RefillEvent SbufferEvent StoreEvent
     UncacheMMStoreEvent
   症状是 **golden 自己一跑就死**：`Error-[DPI-DIFNF] 'v_difftest_ArchFpRegState'
   does not exist`。这不是「impl 有 bug」，是 collateral 配错了 —— 而错得很像 bug。

**C. canonical 绑定**：`MANIFEST.sha256` 头部记录的 G1 CANONICAL_ID 必须等于
   `$G1_CANONICAL/CANONICAL_ID.txt` 当前内容。golden 换基线 = collateral 必须重出，
   这条让「换了基线却忘了换 collateral」当场红，而不是留到仿真跑出假失配。

   假失配长什么样（本工程实测，值得记住）：`difftest-state.h` 的结构体布局跟着接口变，
   只增量重编会留下按旧布局编出来的 C++ `.o`，于是整数寄存器对得上、pc 是
   `0x002d002c002d002c` 这种随机值，甚至裸 segfault。看上去像 RTL 错，其实是 ABI 错。

## 用法
  python3 scripts/check_sim_collateral.py            # 跑闸
  python3 scripts/check_sim_collateral.py --selftest # 负测：种病必须被抓
  python3 scripts/check_sim_collateral.py --write-manifest  # 重出清单（换基线后）

## 环境变量
  G1_CANONICAL  golden 基线包根目录（默认 /home/eda/xs-env/G1-canonical）

## 退出码
  0 = 干净 / 1 = 有 finding
"""
import argparse
import hashlib
import os
import pathlib
import re
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
COLLATERAL = REPO / 'verif' / 'sim' / 'collateral'
MANIFEST = COLLATERAL / 'MANIFEST.sha256'
G1 = pathlib.Path(os.environ.get('G1_CANONICAL', '/home/eda/xs-env/G1-canonical'))

ID_KEY = '# g1-canonical-id: '
DPIC_FUNC = re.compile(r'void\s+v_difftest_(\w+)')
GOLDEN_WRAP = re.compile(r'^\s*DummyDPICWrapper_(\w+)\s+\w+\s*\(', re.M)


def sha256(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


# 清单只管**生成物**这两个子目录。README.md / seed.sh 是手写源码，跟仓库里任何别的
# 源文件一样走 review，不该被 sha 钉住 —— 钉住的话，改一行注释就要重出清单，
# 而清单一旦变成「随手重出」的东西，它对生成物的约束力也就没了。
PAYLOAD_DIRS = ('generated-src', 'build')


def tracked_files(root):
    """collateral 的生成物文件（generated-src/ 与 build/ 下的全部文件）。"""
    out = []
    for d in PAYLOAD_DIRS:
        sub = root / d
        if sub.is_dir():
            out += [p for p in sub.rglob('*') if p.is_file()]
    return sorted(out)


def build_manifest(root, canonical_id):
    lines = [
        '# verif/sim/collateral 内容清单（scripts/check_sim_collateral.py --write-manifest 生成）',
        '# 格式: <sha256>  <相对 collateral 根的路径>',
        ID_KEY + canonical_id,
    ]
    lines += [f'{sha256(p)}  {p.relative_to(root).as_posix()}' for p in tracked_files(root)]
    return '\n'.join(lines) + '\n'


def parse_manifest(text):
    cid, entries = None, {}
    for ln in text.splitlines():
        if ln.startswith(ID_KEY):
            cid = ln[len(ID_KEY):].strip()
            continue
        if not ln.strip() or ln.lstrip().startswith('#'):
            continue
        digest, _, rel = ln.partition('  ')
        entries[rel.strip()] = digest.strip()
    return cid, entries


def check(root=COLLATERAL, g1=G1):
    findings = []
    manifest = root / 'MANIFEST.sha256'
    if not manifest.is_file():
        return [f'NO_MANIFEST  {manifest} 不存在 —— collateral 必须自带清单，'
                f'否则「库里这份是不是当初那份」无从复算']
    cid, entries = parse_manifest(manifest.read_text())

    # --- A 清单完整性（双向）---
    on_disk = {p.relative_to(root).as_posix(): p for p in tracked_files(root)}
    for rel, want in sorted(entries.items()):
        p = on_disk.get(rel)
        if p is None:
            findings.append(f'MISSING_FILE  {rel}  清单里有、树里没有')
            continue
        got = sha256(p)
        if got != want:
            findings.append(f'HASH_MISMATCH  {rel}  清单 {want[:12]}… 实际 {got[:12]}… —— '
                            f'生成物被改过；要么是手工编辑（不允许），要么是换了基线'
                            f'却没跑 --write-manifest')
    for rel in sorted(set(on_disk) - set(entries)):
        findings.append(f'UNLISTED_FILE  {rel}  树里有、清单里没有 —— '
                        f'{"/".join(PAYLOAD_DIRS)} 下不允许有来路不明的生成物')

    # --- B DPI 接口集合 == golden 例化集合 ---
    dpic = root / 'generated-src' / 'difftest-dpic.cpp'
    gw = g1 / 'golden-rtl' / 'GatewayEndpoint.sv'
    if not dpic.is_file():
        findings.append(f'NO_DPIC  {dpic} 不存在 —— 这是 collateral 的核心件')
    elif not gw.is_file():
        findings.append(f'NO_GOLDEN_GATEWAY  {gw} 不存在 —— 无法与 golden 对齐，'
                        f'本闸 fail-closed（找不到对照物不算通过）')
    else:
        have = set(DPIC_FUNC.findall(dpic.read_text(errors='replace')))
        want = set(GOLDEN_WRAP.findall(gw.read_text(errors='replace')))
        if not have:
            findings.append(f'EMPTY_DPIC  {dpic} 里一个 v_difftest_* 都没有')
        elif have != want:
            miss, extra = sorted(want - have), sorted(have - want)
            findings.append(
                f'DPI_SET_MISMATCH  collateral 提供 {len(have)} 个 v_difftest_*，'
                f'golden GatewayEndpoint.sv 例化 {len(want)} 种 DummyDPICWrapper_* —— '
                f'缺 {len(miss)} 个: {miss if miss else "无"}；多 {len(extra)} 个: '
                f'{extra if extra else "无"}。缺失会在仿真时变成 '
                f'Error-[DPI-DIFNF] \'v_difftest_<name>\' does not exist（golden 自己也跑不起来）。'
                f'典型病因：这份 dpic 来自 --fpga-platform --disable-all 那次 make，'
                f'而 RTL 来自 --enable-difftest 那次，两次配置不是同一次')
        else:
            print(f'check_sim_collateral: DPI 接口集合一致（{len(have)} 个 v_difftest_* '
                  f'== golden 例化的 {len(want)} 种 DummyDPICWrapper_*）')

    # --- C canonical 绑定 ---
    idf = g1 / 'CANONICAL_ID.txt'
    if cid is None:
        findings.append(f'NO_CANONICAL_ID  清单头缺 "{ID_KEY.strip()}" 行 —— '
                        f'collateral 必须钉死它是从哪个 golden 基线出的')
    elif not idf.is_file():
        findings.append(f'NO_G1_ID_FILE  {idf} 不存在，无法核对 canonical 绑定（fail-closed）')
    else:
        cur = idf.read_text().strip()
        if cur != cid:
            findings.append(f'CANONICAL_ID_DRIFT  清单记 {cid[:24]}…，当前 G1 是 {cur[:24]}… —— '
                            f'golden 换了基线，collateral 必须重新生成并重出清单')

    return findings


# --------------------------------------------------------------------------
# 负测：种病必须被抓。闸「跑了且退出 0」不等于「它会响」，本工程已踩过同形态的坑。
# --------------------------------------------------------------------------
# --fpga-platform --disable-all 那份 dpic 相对 golden 少的 12 个函数（实测抄录）。
FPGA_PROFILE_MISSING = [
    'ArchFpRegState', 'ArchIntRegState', 'ArchVecRegState', 'AtomicEvent',
    'CMOInvalEvent', 'CommitData', 'L1TLBEvent', 'L2TLBEvent', 'RefillEvent',
    'SbufferEvent', 'StoreEvent', 'UncacheMMStoreEvent',
]


def _fake_g1(root, names, canonical_id):
    (root / 'golden-rtl').mkdir(parents=True, exist_ok=True)
    body = 'module GatewayEndpoint(input clock);\n' + ''.join(
        f'  DummyDPICWrapper_{n} inst_{n} (\n    .clock(clock)\n  );\n' for n in names) + 'endmodule\n'
    (root / 'golden-rtl' / 'GatewayEndpoint.sv').write_text(body)
    (root / 'CANONICAL_ID.txt').write_text(canonical_id + '\n')


def _fake_collateral(root, names):
    (root / 'generated-src').mkdir(parents=True, exist_ok=True)
    (root / 'generated-src' / 'difftest-dpic.cpp').write_text(
        ''.join(f'extern "C" void v_difftest_{n}(long long a) {{}}\n' for n in names))
    (root / 'build').mkdir(parents=True, exist_ok=True)
    (root / 'build' / 'constantin.cpp').write_text('// stub\n')


def selftest():
    CID = 'G1-' + 'a' * 64
    ALL = FPGA_PROFILE_MISSING + ['TrapEvent', 'CSRState', 'ArchEvent']
    fails = []

    def run_case(name, mutate, marker):
        with tempfile.TemporaryDirectory() as td:
            td = pathlib.Path(td)
            col, g1 = td / 'collateral', td / 'g1'
            _fake_collateral(col, ALL)
            _fake_g1(g1, ALL, CID)
            (col / 'MANIFEST.sha256').write_text(build_manifest(col, CID))
            mutate(col, g1)
            findings = check(col, g1)
            if marker is None:
                if findings:
                    fails.append(f'干净样本被判红 —— 闸在误报：\n    ' + '\n    '.join(findings))
                else:
                    print('  PASS  干净样本 rc=0（未误报）')
                return
            if not findings:
                fails.append(f'负测「{name}」：种了病闸却干净 —— 这条判据抓不住')
            elif not any(marker in f for f in findings):
                fails.append(f'负测「{name}」：闸红了但没报 {marker}：\n    '
                             + '\n    '.join(findings))
            else:
                print(f'  PASS  负测「{name}」被抓（{marker}）')

    run_case('干净样本', lambda c, g: None, None)

    def m_fpga(c, g):
        keep = [n for n in ALL if n not in FPGA_PROFILE_MISSING]
        _fake_collateral(c, keep)
        (c / 'MANIFEST.sha256').write_text(build_manifest(c, CID))
    run_case('B 换成 --fpga-platform 那份 dpic（少 12 个函数，真实形态）',
             m_fpga, 'DPI_SET_MISMATCH')

    def m_tamper(c, g):
        p = c / 'build' / 'constantin.cpp'
        p.write_text(p.read_text() + '// 手工改了一行\n')
    run_case('A 文件被手工改过（sha 对不上）', m_tamper, 'HASH_MISMATCH')

    def m_extra(c, g):
        (c / 'build' / 'stowaway.cpp').write_text('// 来路不明\n')
    run_case('A 塞进一个清单外的文件', m_extra, 'UNLISTED_FILE')

    def m_del(c, g):
        (c / 'build' / 'constantin.cpp').unlink()
    run_case('A 删掉一个清单内的文件', m_del, 'MISSING_FILE')

    def m_drift(c, g):
        (g / 'CANONICAL_ID.txt').write_text('G1-' + 'b' * 64 + '\n')
    run_case('C golden 换了基线、collateral 没跟着重出', m_drift, 'CANONICAL_ID_DRIFT')

    def m_nogolden(c, g):
        (g / 'golden-rtl' / 'GatewayEndpoint.sv').unlink()
    run_case('B 对照物缺失时必须 fail-closed（不得视为通过）',
             m_nogolden, 'NO_GOLDEN_GATEWAY')

    if fails:
        print('\n=== check_sim_collateral 负测 FAILED ===')
        for f in fails:
            print('  ★ ' + f)
        return 1
    print('=== check_sim_collateral 负测 PASSED ===')
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--selftest', action='store_true', help='负测：种病必须被抓')
    ap.add_argument('--write-manifest', action='store_true', help='重出 MANIFEST.sha256')
    a = ap.parse_args()

    if a.selftest:
        return selftest()

    if a.write_manifest:
        cid = (G1 / 'CANONICAL_ID.txt').read_text().strip()
        MANIFEST.write_text(build_manifest(COLLATERAL, cid))
        print(f'check_sim_collateral: 已重出 {MANIFEST.relative_to(REPO)}'
              f'（{len(tracked_files(COLLATERAL))} 个文件，绑定 {cid[:24]}…）')
        return 0

    findings = check()
    n = len(tracked_files(COLLATERAL)) if COLLATERAL.is_dir() else 0
    total = sum(p.stat().st_size for p in tracked_files(COLLATERAL)) if COLLATERAL.is_dir() else 0
    print(f'check_sim_collateral: {COLLATERAL.relative_to(REPO)} 下 {n} 个文件，'
          f'{total} 字节（{total // 1024} KiB）')
    if findings:
        for f in findings:
            print('  ★ ' + f)
        return 1
    print('check_sim_collateral: 干净')
    return 0


if __name__ == '__main__':
    sys.exit(main())
