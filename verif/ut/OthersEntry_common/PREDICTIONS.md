# OthersEntry* FM passing 预登记（★跑前写死，跑后不改★）

本文件在**任何一次 FM 跑之前**写入并提交。跑完逐条对账，对不上按 fail 上报。
模型与带宽的依据写在 `predict.py` 的 docstring 里（沿用 Entries* 家族那份模型，
带宽因为本族是单条目、规模小一到两个数量级而放宽，并把带宽本身登记为待反标定项）。

## 复算
```
cd verif/ut/OthersEntry_common && python3 predict.py
```

## 输入固定

| 项 | sha256 |
|---|---|
| `predict.py` | `c6e681648d7f29a8720af7a9a62d14af0822f1931cbab9f7f2d3a05ee19334dd` |
| `othersentry_gen.py` | `6bf97782d0ed5f86ef2b36acdcc6353e738a71016bf7e9dc76d361911f011d53` |
| golden 24 文件 cat 后 | `a4b5cf5023947216d3959f67783c561b007dc302d731717850d8cfa6713a04d3` |

## 预测（12 个 INT/FP 变体，本轮落地的那批）

| 变体 | 角色 | regs | outs | 模型(上界) | 可接受下界 | 实测 passing | 对账 |
|---|---|---|---|---|---|---|---|
| `OthersEntry_44` | simp | 1449 | 2190 | **3639** | 3275 | _待填_ | _待填_ |
| `OthersEntry_50` | comp | 686 | 740 | **1426** | 1226 | _待填_ | _待填_ |
| `OthersEntry_66` | simp | 1446 | 2171 | **3617** | 3255 | _待填_ | _待填_ |
| `OthersEntry_72` | comp | 670 | 724 | **1394** | 1194 | _待填_ | _待填_ |
| `OthersEntry` | simp | 1447 | 2172 | **3619** | 3257 | _待填_ | _待填_ |
| `OthersEntry_6` | comp | 670 | 724 | **1394** | 1194 | _待填_ | _待填_ |
| `OthersEntry_88` | simp | 1426 | 2102 | **3528** | 3175 | _待填_ | _待填_ |
| `OthersEntry_90` | comp | 626 | 675 | **1301** | 1101 | _待填_ | _待填_ |
| `OthersEntry_104` | simp | 1424 | 2096 | **3520** | 3168 | _待填_ | _待填_ |
| `OthersEntry_106` | comp | 622 | 671 | **1293** | 1093 | _待填_ | _待填_ |
| `OthersEntry_120` | simp | 1423 | 2093 | **3516** | 3164 | _待填_ | _待填_ |
| `OthersEntry_122` | comp | 620 | 669 | **1289** | 1089 | _待填_ | _待填_ |

判据：实测 passing ∈ [可接受下界, 模型]，且 failing=0 / unmatched=0 / unread 可解释。
落在带外（高于模型上界，或低于下界）一律按 fail 上报，不在事后调带。
