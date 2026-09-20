# IBuffer FM passing 预登记（★跑前写死，跑后不改★）

## 为什么挑它

`written_unproven.py` 的 WRITTEN_UNPROVEN 桶里，XSTile 闭包内、**没有任何 lane 在动**的
最大一个（23766 行）。三项前置：
1. 不在 coordinator 给的八条在跑 lane 里，`git branch -a` 也没有 `*ibuffer*` 分支；
2. `in_xstile=Y`；
3. **真叶子** —— golden `IBuffer.sv` 里 0 个子模块例化（Makefile 注释也这么写），
   所以没有任何 child 依赖，不存在未闭合闭包。

## 预测（两个数都登记，判据说清各自含义）

| 来源 | 值 | 含义 |
|---|---|---|
| `scripts/fm_passing_model.py --from-ut IBuffer` | **8292**（regs 7079 + outs 1213） | 模型**上界** |
| `scripts/fm_eq.tcl` 里 2026-09-17 那条历史记录 | **7902**（不加强）/ **7908**（vmucp，正好 +6） | 前人实测，我没跑过 |

★这两个数差 384，我不假装它们一致★。判据：

* **必要条件**：`passing <= 8292`。高于模型上界一律按 fail（说明模型或闭包算漏了）。
* 差额必须由 `constant_reg` **逐位解释**（ArrayMulDataModule 那次是 2692-31=2661，
  `constant_reg` 恰好 31）。解释不掉就按 fail 报，不许把模型改成实测值。
* 若实测正好落在 7902 / 7908，则**同时**佐证了前人那条记录；落不到也照实记，
  那条记录是别人的实测，不是我的预测锚。

## ★额外一条：这个目标的钉点文件用的是"空守卫"★

`verif/ut/IBuffer/fm_pins.tcl` 属于 `CATCH_COUNT_LEDGER` 的存量件（用 `catch` 数钉点，
而 `set_user_match` 从不抛 —— 那个计数恒等于总数）。也就是说**它报的"钉点全中"
不构成证据**。这个文件不是我的（台账只许缩，我不代劳改别人的），
但我签这个目标就得自己确认钉点真的落了。

判据：跑完数 `fm.log` 里的 `FM-036` 行数。IBuffer 是真叶子、只有这一个钉点文件，
不存在 `match_packed_payload` 那类投机性试名的干扰源，所以这里可以直接计数：
**`FM-036` 必须为 0**；非 0 则说明有钉点没落上，按 fail 报并逐条列出。

---

## ★跑后补记：我这条"额外判据"写错了，而且错在"必然响"那一侧★

预测数字一个字没改（下面只记判据缺陷与实测）。

我登记的是「数 `fm.log` 里的 `FM-036` 行数，必须为 0」。实测 = **3**，
按登记该判 fail —— 但查下去，那 3 条命中的是**注释文本被回显进日志**：
`fm_shell` 把入口 Tcl 逐行回显（含注释），而 `scripts/fm_eq.tcl:471-475` 里
恰好有一段注释在讲这个坑，里面就写着 `FM-036`。

所以这条判据**永远为假、不可能通过** —— 它不是"没抓住"，是"必然响"。
这和本轮另一侧（`catch` 守卫永远不响）是同一族缺陷：**两者都没有分辨力**。
更难堪的是：我自己的任务简报里就写着「判据用 `grep -cE "^ *Error:"` **行首锚定**」，
我照样写了不锚定的版本；而我自己那个 `scripts/check_pin_errors.py` 里的
`ERR_RE = r"^\\s*Error:"` **是锚定的** —— 工具写对了，登记时的散文写错了。

### 改正后的判据与实测

| 判据 | 实测 | 结论 |
|---|---|---|
| `grep -c "FM-036"`（我登记的，**不锚定**） | 3 | ★判据坏了，全是注释回显★ |
| `grep -cE "^ *Error:"`（行首锚定） | **0** | 没有任何钉点失败 |
| `grep -cE "^ *Error:.*FM-036"` | **0** | 同上 |

⇒ 尽管 `verif/ut/IBuffer/fm_pins.tcl` 用的是空守卫（`catch` 计数），
**这一次钉点确实全落上了**。这个结论来自行首锚定的计数，不来自那个空守卫的自报。

### 首跑实测（commit `4d12094d`，未加强）

`PARTIAL` / passing **7902** / failing 0 / unmatched 0 / unread **6**

* `7902 <= 8292`（模型上界）✔
* 与 `fm_eq.tcl` 里 2026-09-17 那条历史记录**逐位一致**（7902、6 个 unread）——
  佐证了前人那条记录，虽然它本来不是我的预测锚。

### vmucp 前的再登记（本节写完即提交，然后才跑）

6 个 unread **全部** `matched_nc`、ref 6 ↔ impl 6 严格双射：
`deqInBankPtr_<n>_flag_reg` ↔ `u_core/deq_inbank_flag_q_reg[n]`（n=0..5）。
IBuffer 已在 `scripts/fm_eq.tcl` 的 vmucp 白名单里（2026-09-17 加，依据同上）。

★预登记★：打开 vmucp 后 passing 必须**恰好 +6**：7902 → **7908**，
unread 归 0、failing 仍 0、unmatched 全 0。不增而 unread 归 0 = 点被吞掉，不算过。
