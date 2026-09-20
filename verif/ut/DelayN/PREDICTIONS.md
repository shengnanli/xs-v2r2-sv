# DelayN 家族 FM passing 预登记（★跑前写死，跑后不改★）

本表在读到**任何一个实测 passing 之前**写入并提交。
写入时刻本 lane 的 FM 批跑已在后台进行（`scripts/run_proof.sh DelayN …`），
其中前 9 个目标的 fm.log 已经落盘 —— ★但本 lane 到此刻为止只读过前 6 个
（DelayN / _1 / _7 / _8 / _9 / _13，那 6 个是**上一轮就已签核**、
任务书直接给了 657/216 的那批，本轮重跑是为了验证共享核改动没有回归）；
新增 12 个变体的数字一个都没看过★。这一点是本预登记的成立条件，如实写在这里。

跑完逐条对账，对不上按 fail 上报，**不在事后调模型**。

## 复算
```
cd verif/ut/DelayN && python3 predict.py
```

## 模型（等式，不设带宽 —— 理由见 predict.py 的 docstring）

    passing = payload × (1 + STAGES)
            = 顶层输出端口位数 + 闭包触发器位数

payload 与 STAGES 由 `gen_facts.py` 从 G1 golden **现读并逐条结构验证**。

## 输入固定

| 项 | sha256 |
|---|---|
| `predict.py` | `29fdd11effa5e192dda943a6a476f911140eb50f4284899285b707a4b67e5f45` |
| `gen_facts.py` | `0e0f5ede8793f9f69e62af03288821a83d4f5e8b5226589b0837a1529d4544d6` |
| `gen.py` | `a7de60f7e6cfe6fc5e127bee62e6a50c6a3e5c25461e5bcdf913b057a24e3fec` |
| golden 18 文件 cat 后 | `64fca259c6c5c7e1d958c5181b4fc4adb226d841102445b2071945cae1b79f51` |

## 预测

| 变体 | payload | STAGES | port 位 | DFF 位 | 模型 passing | 本轮状态 |
|---|---|---|---|---|---|---|
| `DelayN` | 5 | 1 | 5 | 5 | **10** | 上轮已签核，本轮重跑验隔离（数字已读） |
| `DelayN_1` | 1 | 2 | 1 | 2 | **3** | 上轮已签核，本轮重跑验隔离（数字已读） |
| `DelayN_7` | 219 | 2 | 219 | 438 | **657** | 上轮已签核，本轮重跑验隔离（数字已读） |
| `DelayN_8` | 274 | 2 | 274 | 548 | **822** | 上轮已签核，本轮重跑验隔离（数字已读） |
| `DelayN_9` | 72 | 2 | 72 | 144 | **216** | 上轮已签核，本轮重跑验隔离（数字已读） |
| `DelayN_13` | 1 | 1 | 1 | 1 | **2** | 上轮已签核，本轮重跑验隔离（数字已读） |
| `DelayN_15` | 1 | 4 | 1 | 4 | **5** | ★本轮新增，预测在先★ |
| `DelayN_17` | 1 | 5 | 1 | 5 | **6** | ★本轮新增，预测在先★ |
| `DelayN_208` | 8 | 5 | 8 | 40 | **48** | ★本轮新增，预测在先★ |
| `DelayN_214` | 183 | 2 | 183 | 366 | **549** | ★本轮新增，预测在先★ |
| `DelayN_215` | 9 | 2 | 9 | 18 | **27** | ★本轮新增，预测在先★ |
| `DelayN_220` | 71 | 1 | 71 | 71 | **142** | ★本轮新增，预测在先★ |
| `DelayN_221` | 261 | 1 | 261 | 261 | **522** | ★本轮新增，预测在先★ |
| `DelayN_225` | 1 | 0 | 1 | 0 | **1** | ★本轮新增，预测在先★ |
| `DelayN_297` | 1 | 3 | 1 | 3 | **4** | ★本轮新增，预测在先★ |
| `DelayN_331` | 1 | 10 | 1 | 10 | **11** | ★本轮新增，预测在先★ |
| `DelayN_333` | 14 | 2 | 14 | 28 | **42** | ★本轮新增，预测在先★ |
| `DelayN_334` | 48 | 5 | 48 | 240 | **288** | ★本轮新增，预测在先★ |

判据：实测 passing 必须**恰好等于**模型值，且 failing=0 / unmatched=0 / unread=0 /
verdict=SUCCEEDED。差任何一个（高或低）都按 fail 上报并查清机理，不改模型。

---

## 对账（★上面那张表原样保留，不改；这里只填实测★）

- 证明 commit：`f0bcd42e8a8168e1dbba9f5cfd8530fa1ba15bd2`（evidence/f0bcd42e8a81/）
- 复算：`cd verif/ut/DelayN && python3 reconcile.py f0bcd42e`
  —— 实测各列从 `evidence/f0bcd42e8a81/<top>/receipt.json` 机械读，非手抄；非零退出 = 对不上。
- 跑法：`scripts/run_proof.sh DelayN <18 个 top>`（detached clean worktree，
  `RUN_PROOF_RC=0`，脚本自报「输入前后一致」）。

| 变体 | 模型 passing | 实测 passing | 差 | failing | unmatched | unread | verdict |
|---|---|---|---|---|---|---|---|
| `DelayN` | 10 | **10** | +0 | 0 | 0 | 0 | SUCCEEDED |
| `DelayN_1` | 3 | **3** | +0 | 0 | 0 | 0 | SUCCEEDED |
| `DelayN_7` | 657 | **657** | +0 | 0 | 0 | 0 | SUCCEEDED |
| `DelayN_8` | 822 | **822** | +0 | 0 | 0 | 0 | SUCCEEDED |
| `DelayN_9` | 216 | **216** | +0 | 0 | 0 | 0 | SUCCEEDED |
| `DelayN_13` | 2 | **2** | +0 | 0 | 0 | 0 | SUCCEEDED |
| `DelayN_15` | 5 | **5** | +0 | 0 | 0 | 0 | SUCCEEDED |
| `DelayN_17` | 6 | **6** | +0 | 0 | 0 | 0 | SUCCEEDED |
| `DelayN_208` | 48 | **48** | +0 | 0 | 0 | 0 | SUCCEEDED |
| `DelayN_214` | 549 | **549** | +0 | 0 | 0 | 0 | SUCCEEDED |
| `DelayN_215` | 27 | **27** | +0 | 0 | 0 | 0 | SUCCEEDED |
| `DelayN_220` | 142 | **142** | +0 | 0 | 0 | 0 | SUCCEEDED |
| `DelayN_221` | 522 | **522** | +0 | 0 | 0 | 0 | SUCCEEDED |
| `DelayN_225` | 1 | **1** | +0 | 0 | 0 | 0 | SUCCEEDED |
| `DelayN_297` | 4 | **4** | +0 | 0 | 0 | 0 | SUCCEEDED |
| `DelayN_331` | 11 | **11** | +0 | 0 | 0 | 0 | SUCCEEDED |
| `DelayN_333` | 42 | **42** | +0 | 0 | 0 | 0 | SUCCEEDED |
| `DelayN_334` | 288 | **288** | +0 | 0 | 0 | 0 | SUCCEEDED |

**18/18 verdict=SUCCEEDED，passing 逐个恰好等于模型，差全 +0。**

★其中 `DelayN_7` = 657、`DelayN_9` = 216★ —— 与上一轮已签核的数字逐位相同，
即 3523ac09 对共享核 `xs_DelayN_core.sv` 的改动（把打拍链包进 generate、
新增 0 级旁路支路与 GOLDEN_HAS_CLOCK 不变式）**对已签核变体零影响**。
同批重跑的另外 4 个已签核变体也一个数没动：DelayN 10 / _1 3 / _8 822 / _13 2。

## 重跑（注释改动后重新绑字节）

`eee60602` 只给 `xs_DelayN_core.sv` 加了一段头注释（答"三个核能不能合并"）。
注释也是字节，旧 receipt 绑的是旧字节，所以全 18 个重跑了一遍：

- 证明 commit：`eee60602a12f28b1366e5be5e27bb62427246d7c`（证据目录 `evidence/eee60602a12f/`，取前 12 位）
- 复算：`cd verif/ut/DelayN && python3 reconcile.py eee60602` —— RECONCILE_RC=0
- 结果：18/18 verdict=SUCCEEDED，passing 与模型差全 +0，与 `f0bcd42e` 那批逐个相同。

★不拿「只改了注释，按构造不会变」蒙混过去★ —— 这就是重跑的理由。
