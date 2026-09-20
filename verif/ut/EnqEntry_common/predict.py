#!/usr/bin/env python3
"""predict.py —— EnqEntry* 家族 FM passing 比较点的**跑前**预测器。

## 为什么要有它

FM 跑完再解释数字等于没有判据：任何结果都能「解释一下就过」。
规矩是**跑之前**把预测写死进 PREDICTIONS.md（连同本脚本与 golden 的 sha256），
跑完逐条对账；对不上就把差额**逐位指认出来**，不许把模型调成实测值。

## 模型（不另起炉灶，沿用 OthersEntry* / Entries* 家族那一份）

来源：`verif/ut/OthersEntry_common/predict.py`（它又沿用 `Entries_common/predict.py`）。
FM 的比较点 ≈ golden 侧「寄存器位 + 顶层输出端口位」，golden 是扁平层次，逐实例累加：

    model = regs(本模块) + Σ_子实例 regs(子模块) + 本模块 output 端口位数

其中 regs(mod) = 该 .sv 里所有 `reg [h:l] name;` 的位宽之和。

## 带宽：本族**直接用等号**，有样本依据

OthersEntry lane 在**单条目**这一档上连着两批共 18 个目标实测，
`实测 passing == model` 逐个成立（差全为 +0，constant_reg 为 null）；
Entries 的**阵列**那一档才有 -12 / -128 的缺口（阵列层有 Constant 寄存器）。
EnqEntry 与 OthersEntry 同为**单条目**、同一个 `xs_iq_entry` 核、同一批 golden
firtool 产物，所以本族的预登记判据直接写成等号：

    实测 passing == model     （差 != 0 一律按 fail 上报）

★差额不许用来调模型★：对不上就按 receipt 里的 `constant_reg` / `unread` /
`black_box` 逐位指认缺口（OthersEntry 有过一次差 -31，receipt 里 constant_reg
恰好 = 31，缺口被逐位解释掉；那才是允许的处置）。

## 本族与 OthersEntry 的两处结构差别（都已在模型里机械处理，不是估的）

1. 子实例：EnqEntry/_4/_6 例化 8 份 `UIntCompressor_27_0000111…`，
   _8/_10/_12 例化 8 份 `UIntCompressor_27_0000000…`，_14/_16/_18 没有子实例。
   UIntCompressor 是纯组合压缩器（`reg` 数为 0），所以它对 model 的贡献是 0 ——
   但这是**算出来的** 0，不是假设的 0：下面的 sub_regs 一列逐个打印。
2. 入队延迟窗口：golden 多一根 `enqDelayValidReg_last_REG` 以及整组
   `enqDelay*` 寄存器，它们都在 regs() 里被逐个数到，不需要特判。

用法:
    python3 predict.py            # 打印本 lane 范围内 9 个变体的预测
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

# 本 lane 范围 = 父级 Entries 变体已在本仓实现的那 9 个
# （另外 5 个 _20/_24/_30/EnqEntryVecMem* 的父级未实现，见 enqentry_gen.py 文件头）
DONE9 = ['EnqEntry', 'EnqEntry_4', 'EnqEntry_6', 'EnqEntry_8', 'EnqEntry_10',
         'EnqEntry_12', 'EnqEntry_14', 'EnqEntry_16', 'EnqEntry_18']


def reg_bits(mod):
    n = 0
    for hi, lo in REG_RE.findall((GOLDEN / ('%s.sv' % mod)).read_text()):
        n += 1 if not hi else int(hi) - int(lo) + 1
    return n


def out_bits(mod):
    txt = (GOLDEN / ('%s.sv' % mod)).read_text()
    m = re.search(r'^module\s+%s\s*\(\n(.*?)^\);' % re.escape(mod), txt, re.S | re.M)
    n = 0
    for hi, lo in OUT_RE.findall(m.group(1)):
        n += 1 if not hi else int(hi) - int(lo) + 1
    return n


def predict(mod):
    insts = collections.Counter(INST_RE.findall((GOLDEN / ('%s.sv' % mod)).read_text()))
    own_r, own_o = reg_bits(mod), out_bits(mod)
    sub = sum(c * reg_bits(m) for m, c in insts.items())
    model = own_r + sub + own_o
    return dict(mod=mod, regs=own_r, sub_regs=sub, outs=own_o, model=model,
                insts=dict(insts))


def main(argv):
    mods = [a for a in argv if not a.startswith('-')] or DONE9
    print('%-14s%8s%12s%8s%12s   %s'
          % ('变体', 'regs', '子实例regs', 'outs', '模型(=预测)', '子实例'))
    for m in mods:
        p = predict(m)
        inst = ', '.join('%s x%d' % (k, v) for k, v in sorted(p['insts'].items())) or '无'
        print('%-14s%8d%12d%8d%12d   %s'
              % (p['mod'], p['regs'], p['sub_regs'], p['outs'], p['model'], inst))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
