# match_packed_payload 改正后 5 目标重证 —— 跑前登记（codex_0207 E1 同类，lane agent/gatefix2）

## 为什么重跑

`scripts/fm_eq.tcl` 的 `match_packed_payload`（FM_FIELD_MAP 驱动的扁平 payload 逐位配对）对
1 位字段先试 `data_<suf>_reg[0]`、`catch` 失败再试 `data_<suf>_reg`。`set_user_match` 对不存在的
名字不抛异常（返回 0 + 行首一行 FM-036），catch 恒 0，回退走不到，计数照增。golden 1 位寄存器
是 `reg data_<suf>;` -> 真名 `data_<suf>_reg`（无下标）。

| 目标 | UT 目录 | 旧 receipt | 旧 passing | 旧日志行首 Unknown name | field map 1 位字段数 | field map 总位数 |
|---|---|---|---|---|---|---|
| PipelineConnectPipe | PipelineConnectPipe | e47e713399e0 | 1071 | 74 | 74 | 617 |
| NewPipelineConnectPipe_29 | NewPipelineConnectPipe_29_34_35 | 6a9e4235497e | 2049 | 41 | 41 | 1023 |
| NewPipelineConnectPipe_34 | NewPipelineConnectPipe_29_34_35 | 6a9e4235497e | 1523 | 30 | 30 | 760 |
| NewPipelineConnectPipe_35 | NewPipelineConnectPipe_29_34_35 | 40ec7fc36bb8 | 2895 | 0（★当时还没有 field map★） | 85 | 1446 |
| FauFTBWay | FauFTBWay | 40ec7fc36bb8 | 139 | 12 | 12 | 60 |

旧日志 "Set a match" 条数 = 总位数 − 1 位字段数（543/982/730/48），逐个对上。
NewPipelineConnectPipe_35：其 field map（3e9c6f419）晚于旧 receipt（40ec7fc36），旧证明根本没走
packed 路径；按现在的输入一跑就会撞同一个坑（85 行），所以一并重证。
新名字按 G1 golden 寄存器声明校验：5 份 field map 每个字段 `data_<suf>` 存在且位宽一致，坏名 0。

修法：直接算真名，用**返回值**判成败，期望数 = field map 位宽之和；miss≠0 或 n≠期望 -> exit 3。
防复发：`scripts/fm_verdict.py` 新增——日志行首 `Error: Unknown name` 计数 > 0 ⇒ 不得
SUCCEEDED/PASS_DEAD_REF；负测 `scripts/test_unknown_name_verdict.py` 进 gate_all。

## 预测（跑前写死）

每个目标：
1. native **SUCCEEDED**，failing 0 / unmatched 0；
2. 日志行首 `Error: Unknown name` **0 行**；`PACKED_MATCH: <n> points pinned (miss=0 expect=<n>)`，
   n = 617 / 1023 / 760 / 1446 / 60；"Set a match" 条数 == n；
3. passing 与旧 receipt 相同（1071 / 2049 / 1523 / 2895 / 139）。_35 是首次走 packed 路径，
   若 passing 有差必须逐点指认，否则判红。
