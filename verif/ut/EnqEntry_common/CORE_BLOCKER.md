# EnqEntry* 家族被一行共享核代码卡住（★本 lane 不许改那个文件，报上去★）

**状态：9 个变体全部卡住，一个都签不了。**
**卡点规模：`rtl/backend/xs_iq_entries_core.sv` 一行，一个标识符。**

本文件的数字**全部是本 lane 自己跑出来的**（上一位 lane 报过同一个现象，
但那是被 403 打断前的数，这里不引用它，逐项重测）。

## 现象

```
cd verif/ut/EnqEntry && make run SEED=1        # 200k 拍，+vcs+initreg+random
TEST FAILED (errors=2682 cov_fail=0 checks=58199418)
```

58,199,418 次逐拍比对里 errors=2682，**全部落在 `io_commonOut_perfWakeupByWB_*`**
这一组上（tb 的 `[ERR]` 打印上限 40 条，40 条全是这两个信号；
「2682 条全在这个锥里」由下面的对照实验反证：把那一行补上之后 errors 归 0）。

两个方向都出现，所以不是单侧的包含关系：

```
[ERR] t=12436000 io_commonOut_perfWakeupByWB_0 golden=0 impl=1
[ERR] t=20936000 io_commonOut_perfWakeupByWB_0 golden=1 impl=0
```

## 根因（逐字对着 golden）

golden `EnqEntry.sv:3258`

```verilog
  assign io_commonOut_perfWakeupByWB_0 =
    (|_GEN) & ~currentStatus_srcStatus_0_srcState & validReg_last_REG;
               ^^^^^^^^^^^^^ currentStatus —— 入队延迟窗口打过补丁的那一份
```

核 `xs_iq_entries_core.sv` §2.8（`g_dbg_out`）

```systemverilog
        assign o_dbg_perf_wakeup_by_wb[s] = wk_hit[s]
                                          & (r_src_state[s] == SRC_BUSY)   // <- 裸寄存器
                                          & valid_reg;
```

`wk_hit[s]` 与 golden 的 `(|_GEN)` 同义（当拍 WB 总线的命中向量）。
差别只在门控读的是 `currentStatus` 还是 `entryReg`。核 §2.3b 里两者的关系是

```systemverilog
      cur_src_state[s] = dly ? ((~ld_self_cancel_d[s] & r_src_state[s])
                                | wkd_hit[s] | wk_iq_hit_d[s])
                             : r_src_state[s];       // dly = IS_ENQ & enqd_valid_reg
```

`dly` 只有 `IS_ENQ` 才可能为 1，所以这条差别**只在本族暴露**：
`OthersEntry` / `Entries` 的条目没有入队延迟窗口，`cur == r` 恒成立。
也正因为 `dly` 支里既有 `| wkd_hit` （r 忙 -> cur 就绪）又有
`~ld_self_cancel_d & r` （r 就绪 -> cur 忙），两个方向的失配都能出现，
与实测的两种 `[ERR]` 方向一致。

## 需要的改动（一行，一个标识符）

```diff
         assign o_dbg_perf_wakeup_by_wb[s] = wk_hit[s]
-                                          & (r_src_state[s] == SRC_BUSY)
+                                          & (cur_src_state[s] == SRC_BUSY)
                                           & valid_reg;
```

`cur_src_state` 就在同一个 `xs_iq_entry` 里（§2.3b，`o_dbg` 那段之前已经算好），
不需要新信号、不需要新端口、不动端口表。

## 对照实验（本 lane 自己跑的，仓库文件未动）

在 `git worktree add --detach` 出来的一次性副本里打上这一行，其余一字不改：

| | 结果 |
|---|---|
| 仓库现状（未改核） | `TEST FAILED (errors=2682 cov_fail=0 checks=58199418)` |
| 打上这一行 | `TEST PASSED (EnqEntry seed=1)`，同一 seed / 同一拍数 / 同一 tb |

**errors 2682 -> 0。** 这同时反证了「2682 条全在 perfWakeupByWB 锥里」。

## 为什么不能在本 lane 的 wrapper 里绕过去

绕过去需要 `wk_hit[s]`（当拍 WB 命中向量）和 `cur_src_state[s]` 两个核内部量，
核**都没有往外露**。只拿得到的是

* 核已经算错的那个输出 `o_dbg_perf_wakeup_by_wb[s]`，和
* `transEntry` 上的 currentStatus 版 srcState。

如果 `cur_busy ⊆ r_busy` 成立，wrapper 还能用一个与门补救；
但上面已经实测到 `golden=1 / impl=0` 的方向（`r` 就绪而 `cur` 忙，
由 `ld_self_cancel_d` 造成），那一侧核的输出已经是 0，与门救不回来。
**所以这个坑只能在核里填，或者核多露一个端口 —— 两者都是改那个文件。**

## 为什么本 lane 不动手

`rtl/backend/xs_iq_entries_core.sv` 同时被 `agent/othersentry`（加变体）与
`agent/entries-rest3`（改公共路径 E1/E4）在动，改它要跨 lane 协调。
本 lane 从头到尾**一个字都没改过它**（可核：本分支对该文件的 diff 为空）。

## 这一行对另外两条 lane 是不是 no-op

结构上是：`dly = IS_ENQ & enqd_valid_reg`，而 `IS_ENQ=0` 时
`g_no_enq_delay` 支里 `assign enqd_valid_reg = 1'b0`，于是
`cur_src_state[s] = dly ? (...) : r_src_state[s]` 常量折叠回 `r_src_state[s]`。

★但「结构上是」不等于「跑过了」★：本 lane **没有**替另外两条 lane 重跑它们的
UT/FM 来证实这一点，上一位报过的那组 no-op 对照数（OthersEntry 3619/3619、
EntriesVfdivVidiv 12136/12136）本 lane 也没有复核，所以这里不引用、不背书。
落地前请让持有那两条 lane 的人自己跑一遍回归。

## FM 侧：缺口被**逐位**指认掉了（比 UT 更干净的证据）

`make fm-EnqEntry`（signoff-strict，仓库现状，未改核）：

```
FAILED  {"passing": 3616, "failing": 2, "unmatched": 0, "unread": null,
         "blackbox_out": 0, "dont_verify": false, "constant_reg": null, ...}
    Compare point io_commonOut_perfWakeupByWB_0 failed (is not equivalent)
    Compare point io_commonOut_perfWakeupByWB_1 failed (is not equivalent)
```

**`passing 3616 + failing 2 = 3618 = PREDICTIONS.md 里跑前写死的模型值。**
也就是说：预登记的 passing 模型在本族**一位不差**，跑出来比模型少的那 2 点
不是模型不准，而是**恰好**是那两个已知错掉的输出 —— 缺口被逐位指认干净，
没有第三个来源。

钉点同时第一次经真 fm_shell 验过：

```
EE_PINS: 1432 accepted / 1432 expected, 0 refused
```

★数 fm.log 里的错误一律**行首锚定**★：

```
grep -cE '^ *Error:' fm_work/EnqEntry/fm.log      ->  0
grep -c  'FM-036'    fm_work/EnqEntry/fm.log      ->  3   <- 全是注释回显，不是错误
```

那 3 条在 L472/475/476，逐条看**全是 `fm_eq.tcl` 里那段注释的回显**（fm_shell 把
入口 Tcl 逐行回显进日志，注释也不例外），而那段注释讲的正好就是这个坑。
所以「FM-036 行数为 0」这条判据**永远为假** —— 它和 catch 空守卫「永远不响」
方向相反，**一样没有分辨力**。真正的判据是上面那条行首锚定的 0。

## 打上那一行之后的 FM（★干跑，不是签核★）

同一次性副本、同一 mode、同一钉点文件：

```
SUCCEEDED  {"passing": 3618, "failing": 0, "unmatched": 0, "unread": null,
            "blackbox_out": 0, "dont_verify": false, ...}
EE_PINS: 1432 accepted / 1432 expected, 0 refused
```

`passing = 3618 = 模型`，差 **+0**，与 OthersEntry 18/18 的形态一致。

★这**不是**签核★：核补丁不在仓库里，`make_receipt.py` 也按规矩拒绝了出 receipt
（"impl 工作树 dirty —— 拒绝出 receipt"，fail-closed 正确动作）。
这一节只回答一个问题：**卡点是不是只有这一行。** 对 EnqEntry 而言，是。
