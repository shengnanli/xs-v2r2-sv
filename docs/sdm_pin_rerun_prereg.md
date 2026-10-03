# SyncDataModule 8 变体重证 —— 跑前登记（codex_0207 E1，lane agent/gatefix2）

## 为什么重跑

`verif/ut/SyncDataModule/fm_pins_pre.tcl`（生成器 `scripts/gen_dm_wrappers.py`）对 **1 位字段**
先试 `data_<e>_<f>_reg[0]`、`catch` 失败再试 `data_<e>_<f>_reg`，对**无后缀整宽载荷**用
`data_<e>__flat_reg[k]`。golden 里这两类真名是 `data_<e>_<f>_reg`（1 位无下标）与
`data_<e>_reg[k]`。`set_user_match` 对不存在的名字**不抛异常**（返回 0 + fm.log 一行
`Error: Unknown name ... (FM-036)`），所以 catch 恒 0、回退永远走不到、`_n` 照样自增：
真实 FM 里这些点**一个都没钉上**，而脚本自报 `pinned=N miss=0`。

逐变体实测（旧 receipt 的 fm.log `Error: Unknown name` 行数）与"按 G1 golden 寄存器声明
校验旧钉点文件发出的 ref 名"得到的**坏名数逐个相等**：

| 变体 | 旧 receipt | 旧 passing | FM Unknown name | golden 校验坏名 | 本次调用序列 |
|---|---|---|---|---|---|
| SyncDataModuleTemplate_FtqPC_64entry | 25cdce831a66 | 7166 | 64 | 64 | 变 |
| SyncDataModuleTemplate__1024entry | 25cdce831a66 | 1070 | 1024 | 1024 | 变（旧版实钉 0） |
| SyncDataModuleTemplate__64entry | 25cdce831a66 | 5743 | 384 | 384 | 变 |
| SyncDataModuleTemplate__64entry_1 | 25cdce831a66 | 38029 | 768 | 768 | 变 |
| SyncDataModuleTemplate__64entry_2 | 25cdce831a66 | 955 | 384 | 384 | 变 |
| SyncDataModuleTemplate__64entry_3 | 25cdce831a66 | 5999 | 2304 | 2304 | 变 |
| SyncDataModuleTemplate__64entry_4 | 25cdce831a66 | 792 | 256 | 256 | 变 |
| SyncDataModuleTemplate__64entry_5 | 9154088d8da0 | 3775 | 64 | 64 | 变 |
| SyncDataModuleTemplate_BackendPC_64entry | 25cdce831a66 | 4097 | 0 | 0 | 逐字节相同（不重跑） |

旧 receipt 结论本身没有被推翻：那些点 FM 自己按签名配上了（unmatched 全 0、failing 0）。
坏的是"钉点脚本声称钉了、其实没钉"——证明闭包里有一句假话。

修法：生成器直接算出 golden 真名（不再"先试 A 再试 B"），用 `set_user_match` **返回值**
判成败，末尾 `miss != 0 || pinned != 字面期望数` 即 `error`（fail-closed）。
新钉点文件发出的全部 ref 名按 G1 golden 寄存器声明校验：9 个变体坏名 0。
`pin_call_equiv.py --compare-rev` 判定：上表 8 个 NEEDS_RERUN，BackendPC 逐字节相同。

## 预测（跑前写死）

每个重跑变体：
1. native **SUCCEEDED**，failing 0 / unverified 0 / aborted 0，unmatched 六项全 0；
2. fm.log 里 `Error: Unknown name` **0 行**；`SDM_PIN(<top>): pinned=<expect> miss=0 expect=<expect>`，
   且 "Set a match" 回显条数 == expect（FtqPC 6464 / 1024entry 1024 / 64entry 5504 /
   64entry_1 36864 / 64entry_2 896 / 64entry_3 5760 / 64entry_4 576 / 64entry_5 3648）；
3. **passing 与旧 receipt 相同**（上表"旧 passing"列）——钉点只是把 FM 原本按签名配上的点
   改成显式配对，不增减比较点。若 passing 有差，必须逐点指认，否则判红。
（`docs/fm_predictions/*.json` 的 passing 模型对这 8 个是 MODEL_NA：merge_dup=true。）
