#!/usr/bin/env python3
"""predict.py —— OthersEntry* 家族 FM passing 比较点的**跑前**预测器。

## 为什么要有它

FM 跑完再解释数字等于没有判据：任何结果都能「解释一下就过」。
所以规矩是**跑之前**把预测写死进 PREDICTIONS.md（连同本脚本与 golden 的 sha256），
跑完逐条对账，对不上按 fail 上报，不许事后改预测。

## 模型（沿用 Entries* 家族那一份，不另起炉灶）

来源：`verif/ut/Entries_common/predict.py`（agent/entries-rest3 分支 47c36535）。
FM 的比较点 ≈ golden 侧「寄存器位 + 顶层输出端口位」，golden 是扁平层次，逐实例累加：

    total = regs(本模块) + Σ_子实例 regs(子模块) + 本模块 output 端口位数

其中 regs(mod) = 该 .sv 里所有 `reg [h:l] name;` 的位宽之和。

模型是**上界**：golden 里被 FM 判成 Constant 的寄存器不产生比较点，实测应略低。

## ★这里的带宽为什么与 Entries 那份不同★

Entries 那份的可接受带 [98.5%×模型, 模型] 是在**阵列**变体上标定的
（EntriesAluCsrFenceDiv 模型 25013 / 实测 25001，差 -12；
  EntriesVfdivVidiv 模型 12264 / 实测 12136，差 -128）。
本族是**单条目**，规模小一到两个数量级，同样的绝对偏差占比会大得多，
所以照抄 98.5% 这个**相对**带没有依据。本脚本改用两者之中较宽的一个：

    lo = min(round(0.90 * model), model - 200)

并且★把这条带本身也登记成待验条目★：12 个变体跑完之后，用实测值反标定，
把带收窄到有依据的宽度，写回本文件。在那之前，落在带外一律按 fail 上报，
**不在事后调带**。

用法:
    python3 predict.py            # 打印 12 个 INT/FP 变体的预测
    python3 predict.py --all      # 24 个全打（含尚未落地的 12 个）
    python3 predict.py <mod> ...  # 只算指定变体
"""
import re, sys, pathlib, collections

GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')

REG_RE = re.compile(
    r'^\s*reg\s+(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*)?[A-Za-z_]\w*\s*'
    r'(?:\[[^\]]*\]\s*)?;', re.M)
OUT_RE = re.compile(
    r'^\s*output\s+(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s+)?[A-Za-z_]\w*\s*,?\s*$', re.M)
INST_RE = re.compile(r'^  ([A-Z][A-Za-z0-9_]*)\s+\w+\s*\($', re.M)

# 本轮已落地（不需要 E1）的 12 个：wkWB_wen 是单 rfWen 或单 fpWen
DONE12 = ['OthersEntry_44', 'OthersEntry_50', 'OthersEntry_66', 'OthersEntry_72',
          'OthersEntry', 'OthersEntry_6', 'OthersEntry_88', 'OthersEntry_90',
          'OthersEntry_104', 'OthersEntry_106', 'OthersEntry_120', 'OthersEntry_122']


def reg_bits(mod):
    n = 0
    for hi, lo in REG_RE.findall((GOLDEN / f'{mod}.sv').read_text()):
        n += 1 if not hi else int(hi) - int(lo) + 1
    return n


def out_bits(mod):
    txt = (GOLDEN / f'{mod}.sv').read_text()
    m = re.search(r'^module\s+%s\s*\(\n(.*?)^\);' % re.escape(mod), txt, re.S | re.M)
    n = 0
    for hi, lo in OUT_RE.findall(m.group(1)):
        n += 1 if not hi else int(hi) - int(lo) + 1
    return n


def predict(mod):
    insts = collections.Counter(INST_RE.findall((GOLDEN / f'{mod}.sv').read_text()))
    own_r, own_o = reg_bits(mod), out_bits(mod)
    sub = sum(c * reg_bits(m) for m, c in insts.items())
    model = own_r + sub + own_o
    lo = min(round(0.90 * model), model - 200)
    return dict(mod=mod, regs=own_r, sub_regs=sub, outs=own_o,
                model=model, lo=lo, insts=dict(insts))


def main(argv):
    mods = [a for a in argv if not a.startswith('-')]
    if not mods:
        mods = (sorted(p.stem for p in GOLDEN.glob('OthersEntry*.sv')
                       if 'VecMem' not in p.stem) if '--all' in argv else DONE12)
    print(f'{"变体":<18}{"regs":>7}{"子实例regs":>11}{"outs":>7}'
          f'{"模型(上界)":>12}{"可接受下界":>12}')
    for m in mods:
        p = predict(m)
        print(f'{p["mod"]:<18}{p["regs"]:>7}{p["sub_regs"]:>11}{p["outs"]:>7}'
              f'{p["model"]:>12}{p["lo"]:>12}')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
