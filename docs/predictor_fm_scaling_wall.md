# Predictor FM 的真实状态（★本文件的上一版结论是错的，已整篇重写★）

**2026-09-15。** 上一版标题是「名字匹配在 10 万点以上失效 / 匹配不终止 / 外推 302 天」。
**那是错的**，成因是把 Formality 的匹配进度条读成了线性进度。本文件先讲错在哪，
再讲实测到的真实状态。

## 一、错在哪：一个按构造到不了 100% 的进度条

Formality 匹配阶段会打这样的进度行：

```
.............................. 522488M/1057545 (49% Matched) 09/15/26 07:34 34433MB/9340.46sec
```

我们（我与 worker 各自独立地）把它读成「才走了 49%，还剩一半」，于是拿**尾部速率**
去外推剩下的「53.5 万点」，得出 302 天 / 146 天，据此判定「匹配不终止」并**提前把
进程杀了**。

实际上这次跑**完成了匹配**，紧接着就打出了 Matching Results：

```
 256 Compare points matched by user
 517783 Compare points matched by name
 2461 Compare points matched by signature analysis
 0 Compare points matched by topology
 1856 Matched primary inputs, black-box outputs
 134(6) Unmatched reference(implementation) compare points
 1113(1826) Unmatched reference(implementation) unread points
```

配上的比较点 = 256 + 517,783 + 2,461 = **520,500**，而 520,500 / 1,057,545 = **49.2%**。
分母约是配对数的两倍（看起来是 ref+impl 两侧对象合计），**所以配完时进度条正好停在
49% 附近，它按构造就到不了 100%**。

★教训★：**不要把一个不知道分母含义的进度条当成进度。** 判断匹配有没有走完，唯一
可靠的标志是 `**** Matching Results ****` 这个段头有没有出现，以及其后是否出现
`Status:  Verifying...`。同一个教训在本轮已经是第二次（第一次是把
`Building verification models` 当成「已过合并阶段」，见 `scripts/fm_verdict.py` 文档）。
两次都是**对工具输出的含义想当然，没有先确认判据**。

## 二、真实状态

带 GHV 钉点那次跑（`PROOF_COMMIT=da93a13`，`FM_MERGE_DUP=false`，官方 runner）：

| | |
|---|---|
| 已配上的比较点 | **520,500**（其中 256 由钉点、517,783 靠名字、2,461 靠签名分析） |
| 未配上的比较点 | **134 (ref) / 6 (impl)**，全部是 DFF |
| 未配上的 unread 点 | **1113 (ref) / 1826 (impl)** |
| 匹配耗时 | FM 累计 > 9,340 秒后完成（约 2.6 小时） |
| 之后 | 进入 `Status: Verifying...`，被我们按 PID 停掉 |

**这是个完全正常、可收拾的局面**，与本工程其它目标同一量级
（例如 Composer 当初也要处理 6,323 个 unread 点才转绿）。

未钉点那次（`82503e5`）被停在 FM 累计 7,718 秒、仍在 Matching —— 也就是说
**它很可能再跑半小时就出结果了，是被那个错误外推提前杀掉的**。

## 三、因此 GHV canary 的结论也要改

上一版写「路线 1（补名字对齐）不通，转路线 2（拆证明边界）」。**撤回。**

- 钉点**有效**且有两条独立证据：`PREDICTOR_PINS: 256 / 256 pinned, 0 missed`；
  以及 Matching Results 里的 `256 Compare points matched by user`。
- 需要靠钉点解决的不是「53.5 万点」，是 **134 + 6 个未配比较点**和
  **1113 / 1826 个未配 unread 点**。这正是 `fm_pins_pre.tcl` 该干的活，
  也正是 `verif/ut/Composer/fm_pins_pre.tcl` 当年干过的活。
- 所以 codex 0162 D2 的**路线 1 仍然在轨**，没有理由现在跳到路线 3（拆分区）。

## 四、仍然成立的那条（别一起丢掉）

`FM_MERGE_DUP=false` 的依据不受本次更正影响：那条比的是**到达 `Status: Matching...`
的耗时**（off 18 分 54 秒 vs on 2 小时 16 分，约 7 倍），两侧取的是同一个日志标志，
不涉及进度条。见 `verif/ut/Predictor/Makefile` 的注释。

## 五、复跑

```
scripts/run_proof.sh Predictor Predictor        # 需要 clean tree
```
判据（**不要看进度条**）：
```
grep -n "Matching Results" <fm.log>             # 出现 = 匹配已完成
grep -nE "Unmatched reference|matched by user" <fm.log>
grep -n "Status:  Verifying" <fm.log>
```

证据样本（跟踪进库）见 `verif/testdata/fm_samples/`，README 里已更正对这些 log 的描述。
