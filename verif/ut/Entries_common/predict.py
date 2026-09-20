#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""predict.py —— Entries* 家族 FM passing 比较点的**跑前**预测器。

## 为什么要有它

FM 跑完再解释数字，等于没有判据：任何结果都能"解释一下就过"。所以本家族的规矩是
**跑之前**把预测写进 docs/lanes/entries-rest-predictions.md 并提交，跑完逐条对账。
这个脚本就是那份预测的**可复跑来源**——预测不是拍脑袋，是从 G1 golden 机械算出来的。

★ 本脚本是接手时补写的 ★：前一位 lane 的 predictions.md 里写了"脚本：本 lane 的
predict.py"，但那个文件**没有进仓**（WIP 抢救提交 6dba42f 里没有）。也就是说那 7 行
预测在仓里是**不可复算**的。本文件按 predictions.md 写下的公式重建，并要求它在两个
已签核变体上复现 predictions.md 记的标定值（--check），否则拒绝输出。

## 模型

FM 的比较点 ≈ golden 侧「寄存器位 + 顶层输出端口位」。golden 是扁平层次，逐实例累加：

    total = Σ_实例 regs(该模块) + regs(Entries<V> 顶层) + Entries<V> 的 output 端口位数

其中 regs(mod) = 该 .sv 里所有 `reg [h:l] name;` 的位宽之和。

模型是**上界**：golden 里被 FM 判成 Constant 的寄存器不产生比较点，所以实测应略低。
标定（predictions.md 记的两个已签核变体实测值）：

    EntriesAluCsrFenceDiv  模型 25013  实测 25001  差 -12
    EntriesVfdivVidiv      模型 12264  实测 12136  差 -128 (-1.0%)

⇒ 可接受带 = [round(0.985 × 模型), 模型]。落在带外（高于模型，或低于 98.5%）判 fail。

用法:
    python3 predict.py                 # 打印全部 14 个变体的预测
    python3 predict.py --check         # 只验两个标定点能否复现（非零退出=模型漂了）
    python3 predict.py Entries<V> ...  # 只算指定变体
"""
import re, sys, pathlib, collections

GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')

# predictions.md 记下的标定值（模型值, 实测 passing）。改模型必须先过这两行。
CALIB = {
    'EntriesAluCsrFenceDiv': (25013, 25001),
    'EntriesVfdivVidiv':     (12264, 12136),
}

REG_RE  = re.compile(r'^\s*reg\s+(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*)?[A-Za-z_]\w*\s*(?:\[[^\]]*\]\s*)?;', re.M)
INST_RE = re.compile(r'^  (EnqEntry\w*|OthersEntry\w*|EnqPolicy\w*)\s+\w+\s*\(', re.M)
OUT_RE  = re.compile(r'^\s*output\s+(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s+)?[A-Za-z_]\w*\s*,?\s*$', re.M)


def reg_bits(mod):
    txt = (GOLDEN / f'{mod}.sv').read_text()
    n = 0
    for hi, lo in REG_RE.findall(txt):
        n += 1 if hi is None or hi == '' else int(hi) - int(lo) + 1
    return n


def out_bits(top):
    txt = (GOLDEN / f'{top}.sv').read_text()
    m = re.search(r'^module\s+%s\s*\(\n(.*?)^\);' % re.escape(top), txt, re.S | re.M)
    n = 0
    for hi, lo in OUT_RE.findall(m.group(1)):
        n += 1 if hi is None or hi == '' else int(hi) - int(lo) + 1
    return n


def predict(top):
    txt = (GOLDEN / f'{top}.sv').read_text()
    insts = collections.Counter(INST_RE.findall(txt))
    total = reg_bits(top) + out_bits(top)
    for mod, cnt in sorted(insts.items()):
        total += cnt * reg_bits(mod)
    return total, insts


VARIANTS = sorted(p.stem for p in GOLDEN.glob('Entries*.sv'))


def main(argv):
    check = '--check' in argv
    names = [a for a in argv if not a.startswith('--')] or VARIANTS
    if check:
        rc = 0
        for v, (model, meas) in CALIB.items():
            got, _ = predict(v)
            ok = (got == model)
            print(f'{v:56s} 模型={got:6d} 期望={model:6d} 实测={meas:6d} {"OK" if ok else "★漂了★"}')
            rc |= 0 if ok else 1
        return rc
    print(f'{"变体":56s} {"预测 passing":>12s} {"可接受带":>18s}')
    for v in names:
        got, insts = predict(v)
        lo = round(0.985 * got)
        print(f'{v:56s} {got:12d} {lo:8d}–{got:<8d}  '
              + ' '.join(f'{m}x{c}' for m, c in sorted(insts.items())))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
