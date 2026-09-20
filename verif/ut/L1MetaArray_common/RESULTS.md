# L1 元数据阵列家族：跑完的结果（预登记见同目录 PREDICTIONS.md）

## 1. FM 对账 —— 三个目标差全为 +0

预登记在 commit 872034d8（早于任何一次 FM 运行）。

| 目标 | 预登记 passing | 实测 passing | 差 | verdict |
|---|---|---|---|---|
| L1ErrorMetaArray | 2300 | 2300 | +0 | SUCCEEDED |
| L1FlagMetaArray | 1352 | 1352 | +0 | SUCCEEDED |
| L1PrefetchSourceArray | 3528 | 3528 | +0 | SUCCEEDED |

三份都是 `mode=signoff-strict`、`failing=0`、`unmatched` 六项全 0、
`unread_notcompared=0`、`unread_points.txt` 0 行、`impl_worktree_dirty=false`。

★零放松手段★（`native_facts.json` 逐条可查）：`objects` 下 20 个列表
（matched_blackbox_pairs / unresolved_blackbox_* / empty_blackbox_* / unmatched_* …）
**全部为空**；`qualifications` 的 dont_verify_objects / elab147 / relaxed_appvars
**全部为空**；`verify_matched_unread_compare_points=false`。
三个目标都没有 `verif/allow/*.json`、没有 `verif/dead_ref/*.json`、
没有 `fm_pins.tcl` / `fm_pins_pre.tcl` / `fm_map/`。

证据：`evidence/00765a691d9a/{L1ErrorMetaArray,L1FlagMetaArray,L1PrefetchSourceArray}/`
（`run_proof.sh` 在 detached clean worktree 上跑，MAKE_RC 全 0，跑前跑后 worktree
摘要一致）。

## 2. UT 矩阵 18/18

3 目标 × 3 seed(1/7/42) × 2 轮 initreg(+random/+0)，每轮 200k 拍：
全部 `checks=200000 errors=0`，18 个 TEST PASSED，0 个 FAILED。

## 3. 共享核变异体矩阵 —— 12 个有效格全被抓住

6 个变异体 × 3 个变体，seed=1 / +vcs+initreg+random / 50k 拍。
每个变异体先验「文件确实变了」（diff 非空）再跑；全跑完核已还原并复核
与原文 **IDENTICAL**。

| 变异体（按它**实际改了什么**命名） | Error | Flag | PfSource |
|---|---|---|---|
| M1 `bypass_r` 使能由「旁路命中」改成「读有效」 | 103 | ○空 | 199 |
| M2 **删掉 S1 旁路项**（只留 S0 那条） | 101 | ○空 | 403 |
| M3 非旁路读路径锁存**数据**而非**地址**（= 抄 L1CohMetaArray 的写法） | 2368 | 10497 | 9123 |
| M4 写口优先级反向（号小的赢） | ○空 | 2440 | 4448 |
| M5 无视 `BYPASS_S0` 参数，一律加 S0 旁路 | ○空 | ○空 | 5111 |
| M6 常数折叠写口的常数值写错（1 → 0） | ○空 | 740142 | 740163 |

★M2 的名字订正★：脚本里这一项原先叫 `M2_s0s1_priority`（"S0/S1 优先级对调"），
但它的 patch 实际是**把 S1 那一整个 if 块删掉**。这里按它真正做的事记，
不按我当初起的名字记。

### 「○空」六格都是**结构上不被例化**，不是逃逸

判据是各 wrapper 传进来的参数实参 + 被改代码所在的 generate 分支，机械可复核：

    变体                    HAS_BYPASS  BYPASS_S0  WRITE_PORTS  WDATA_IS_CONST
    L1ErrorMetaArray           1'b1       1'b1          1          32'h0
    L1FlagMetaArray            1'b0       1'b0          4          32'h7
    L1PrefetchSourceArray      1'b1       1'b0          4          32'h7

    核里的位置： g_bypass 分支从第 189 行起（M1 的使能行、M2 的 S1 项 198 行、
                 M5 的 BYPASS_S0 守卫 202 行都在里面）
                 g_const 分支在第 138 行
                 M4 改的是 165 行那个 meta_array 写回循环

  · M1/M2 在 Flag 上空：整个 `g_bypass` 分支在 HAS_BYPASS=1'b0 时不例化。
  · M5 在 Flag 上空：同上。M5 在 Error 上空：BYPASS_S0 本来就是 1'b1，
    `if (BYPASS_S0 && X)` 换成 `if (1'b1 && X)` 是恒等替换。
  · M4 在 Error 上空：WRITE_PORTS=1，把一次迭代的循环反向是恒等变换。
  · M6 在 Error 上空：WDATA_IS_CONST=32'h0，`g_const` 分支一次都不例化。

按本仓变异体计分规则（无效/空变异体分子分母同时剔除）：
**有效格 12 个，抓住 12 个，12/12。**
6 个变异体每一个都至少被一个变体抓住，没有任何一个是全族看不见的。

### 这张表顺带证明了三件事

1. `HAS_BYPASS`、`BYPASS_S0`、`WDATA_IS_CONST` 三个参数都是**承重的**：
   各自有一个变异体专门只有"该参数取那个值的变体"能看见（M1/M2 之于 Flag、
   M5 之于 PfSource、M6 之于 Error）。参数不是装饰。
2. M3 在三个变体上全红，复核了「L1CohMetaArray 不能并进本核」这个判断
   ——它走的正是被 M3 改成的那种写法。
3. M4 在 Error 上空、在另两个上红，正是"写口数"这一维真实存在的证据。
