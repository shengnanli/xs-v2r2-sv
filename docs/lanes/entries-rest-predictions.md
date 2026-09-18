# Entries* 剩余变体 lane —— FM 预测预登记

**本文件必须在跑 FM 之前提交。** 跑完逐条对账，对不上按 fail 报，不回头改预测。
预登记时间：2026-09-18；基线 commit：见本文件所在提交的 parent。

## 预测模型（不是拍脑袋，是从两个已签核变体标定出来的）

比较点 ≈ **golden 侧寄存器位 + 顶层输出端口位**。golden 是扁平层次，
所以逐实例累加：`n_enq x EnqEntry + n_simp/n_comp x OthersEntry + 2 x EnqPolicy + Entries 顶层`。
脚本：本 lane 的 `predict.py`（逻辑见下方公式，输入只有 G1 golden）。

    regs(mod) = mod.sv 里所有 `reg [h:l] name;` 的位宽之和
    total     = n_enq*regs(enq) + n_simp*regs(simp) + n_comp*regs(comp)
              + 2*regs(enqPolicy) + regs(Entries<V>) + 顶层 output 端口位数

标定（两个已签核变体，实测数来自它们已有的 evidence）：

| 变体 | 模型值 | 实测 passing(vmucp) | 误差 |
|---|---|---|---|
| EntriesAluCsrFenceDiv | 25013 | 25001 | −12（= 该变体的 Constant reg 12，正好对上） |
| EntriesVfdivVidiv | 12264 | 12136 | −128（−1.0%，同样是常数折叠的寄存器） |

所以模型是**上界**，实测应落在 `[0.985 x 模型值, 模型值]`，差额只能由
`Constant reg` 解释。★落在带外（高于模型值，或低于 98.5%）一律判 fail 报上去，
不允许事后调模型。★

未读点（matched_nc，vmucp 关时的 unread）模型：
`(n_enq + n_simp) x (PL_TRANS_W − PL_DEQ_W)` —— 即 enq/simp 条目里
「只为转移包存、本变体发射口看不见」的那段负载。
标定：ACFD 模型 6208 / 实测 6220（+12 是 enqDelay 影子位）。

## 七个变体的预登记值

| 变体 | 预测 passing(vmucp) | 可接受带 | 预测 unread(不开 vmucp) |
|---|---|---|---|
| EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v | 25312 | 24932–25312 | 6104 (+少量) |
| EntriesAluMulBkuBrhJmp | 25022 | 24647–25022 | 6216 (+少量) |
| EntriesFaluFcvtF2vFmacFdiv | 16693 | 16443–16693 | 3128 (+少量) |
| EntriesFaluFmac | 16008 | 15768–16008 | 3136 (+少量) |
| EntriesFaluFmacFdiv | 16623 | 16374–16623 | 3136 (+少量) |
| EntriesVfmaVialuFixVfalu | 18503 | 18225–18503 | 2352 (+少量) |
| EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf | 18889 | 18605–18889 | 2344 (+少量) |

其余四项一律预测 **0**：failing / unmatched（六项）/ aborted / unverified。
任一非零 = fail，不做"解释一下就过"。
