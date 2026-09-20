# ArrayMulDataModule 家族 FM passing 预登记（★跑前写死，跑后不改★）

本文件在**任何一次 FM 跑之前**写入并提交。跑完逐条对账，对不上按 fail 上报。

## 为什么挑这一族

`scripts/written_unproven.py --source both --bucket WRITTEN_UNPROVEN --xstile-only`
里 golden 行数最大、且**没有任何 lane 在动**的一族（`ArrayMulDataModule` 24372 行）。
三项前置都核过：

1. **不属于在跑的 lane** —— `git branch -a` 里没有任何 `*arraymul*` / `*c22*` / `*csa*` 分支；
   也不在 coordinator 给的在跑清单（lqreplay-fm / l2tlb-fm / entries-rest3 / rob-v2x /
   fubusy-wbarb / delayn-clz / enqentry / l1err）里。
2. **在 XSTile 闭包内** —— 5 个全部 `in_xstile=Y`（闭包由 golden 实例树现算，见
   `written_unproven.xstile_closure()`）。
3. **没有未闭合的 child 依赖** —— golden 闭包只有 C22/C32/C53/CSA3_2 四个，
   而这四个**本身就在同一个 UT 的 FM_VARIANTS 里**，一起签，不留悬挂。

## 模型

`passing = Σ_(golden 闭包里每个**实例**) 寄存器位 + 顶层 output 端口位`
（`scripts/fm_passing_model.py`，同一模型在 OthersEntry 18 个上差全为 +0）。

复算：`python3 scripts/fm_passing_model.py --from-ut ArrayMulDataModule`

| target | regs | outs | **模型 passing** | 实例构成 | 实测 | 对账 |
|---|---|---|---|---|---|---|
| `ArrayMulDataModule` | 2562 | 130 | **2692** | C22x293, C32x84, C53x989, CSA3_2x1978 | _待填_ | _待填_ |
| `C22` | 0 | 2 | **2** | 无子实例 | _待填_ | _待填_ |
| `C32` | 0 | 2 | **2** | 无子实例 | _待填_ | _待填_ |
| `C53` | 0 | 3 | **3** | CSA3_2x2 | _待填_ | _待填_ |
| `CSA3_2` | 0 | 2 | **2** | 无子实例 | _待填_ | _待填_ |

★C22/C32/C53/CSA3_2 是纯组合件（0 个寄存器）★，所以它们的模型就等于
output 端口位数——这几个是最干净的对照：实测不等于它，说明模型或闭包算错了。

判据：`passing == 模型` 且 `failing=0 / unmatched=0 / unread=0`。
低于模型只允许由 Constant 寄存器解释，且必须逐个点名；高于模型一律按 fail。
