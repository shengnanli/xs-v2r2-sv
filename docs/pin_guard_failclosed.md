# 钉点守卫还债（agent/pindebt）：14 个 fail-open 的 `fm_pins*.tcl` 改成真 fail-closed

`scripts/gate_all.sh` 末尾 `GATE_RC=` 那一行长期恒为 1，唯一的红就是
`scripts/test_fm_pins_wellformed.py` 报的这 14 个钉点文件。
**一道永远红的闸等于没有信号**，所以这笔债要还，不靠放宽判据、也不靠把它们从闸里豁免。

本文件记两件事：**改了什么**，以及**为什么先前那些 receipt 不必重跑**（★证据，不是声明★）。

---

## 一、缺陷：`catch {set_user_match ...}` 是一个空守卫

`set_user_match` **从不抛 Tcl 异常**（V-2023.12-SP3）：

| 调用 | 返回值 | fm.log |
|---|---|---|
| 名字存在 | `1` | 无 |
| 名字不存在 | `0` | 行首 `Error:`（Unknown name） |
| `catch {set_user_match ...}` | `0`（**从不抛**） | 同上 |

于是

```tcl
if {[catch {set_user_match $r $i} _msg]} { incr _miss } else { incr _n }
...
if {$_miss != 0} { error "..." }      ;# 永远走不到
```

里 `_miss` 恒 0、`_n` 恒等于总数 —— **一个 pin 都没配上也会打印 "pinned N of N"**。

★同族的更阴一层★：后来"加强"上去的 `if {$_n != <expect>} {error}` **同样是空的**，
因为 `_n` 正是在那个永不触发的 `catch` 的 else 支里自增的。
**新判据建立在旧判据的中间量上时，会把旧判据的空洞一并继承。**

---

## 二、中止一律用 `error`，不用 `exit`

### 2.1 ★`exit` 在钉点文件里有两种行为，取决于是不是正式签核★

`scripts/fm_eq.tcl:735/:814` 按 `SIDECAR_ON` 分叉，而 `SIDECAR_ON` 由环境变量
`FM_SIDECAR_OUT` 决定（`fm_eq.tcl:16-21`）——
**正式签核的 `run_proof.sh` 会设它，本地 `make fm-X` 不设**：

```tcl
if {$SIDECAR_ON} { sidecar_pin_source $env(FM_PIN_TCL) } else { source $env(FM_PIN_TCL) }
```

本 lane 在 tclsh 上把两条路都跑过（两段探针，各自独立可复跑）：

| 上下文 | `exit 3` | `error "..."` |
|---|---|---|
| 本地调试（顶层 `source`） | **宿主进程真退出，退出码 3**（`HOST STILL ALIVE` 那行不再打印） | 抛异常 |
| 正式签核（`interp create -safe`） | 抛 `invalid command name "exit"`，**宿主还活着** | 抛异常，**作者写的失败原因原样保留** |

safe interp 隐藏 `exit` 的直接证据：

```tcl
set i [interp create -safe]
$i eval {info commands exit}    ;# -> ★空（命令不存在）★
$i eval {info commands error}   ;# -> error
```

### 2.2 为什么这是最坏的一种排列

**同一行代码在调试时和出证时走不同机制。** 而且签核那条路上的 fail-closed
是**副作用不是设计**：它靠"这个命令在 safe interp 里不存在"生效，
日志里留下的是 `invalid command name "exit"` —— 读的人会以为脚本有语法错，
而**作者写的失败原因一个字都没留下**。

这正是本轮反复在修的那一族：*代码看起来表达了意图，实际起作用的是别的机制*。
它今天恰好 fail-closed，但一旦有人把它包进 `catch`、或哪天 sidecar 换成非 safe interp，
行为就变，而没有任何判据会提醒。

⇒ 结论（已进 `CONVENTIONS.md`）：**一律 `error`，任何值的 `exit` 都不许用。**
本轮把这 14 个文件里所有中止路径统一改成 `error "<可读原因>"`。

（附带一条别读错：负测 `M10「exit 0 装成中止」`判的是**文本形态**，不是运行时行为 ——
在 safe interp 里 `exit 0` 也会抛，在顶层 `source` 下它会让宿主以 0 退出。
它作为"别这么写"的静态约定仍然合理。）

---

## 三、修法

两道 fail-closed，**都在最后一次 `set_user_match` 之后**：

```tcl
if {[set_user_match $r $i]} { incr _n } else { incr _miss ; puts "..._PIN_FAIL: ..." }
...
if {$_miss != 0}   { error "..._PIN_MISS=<top> miss=$_miss" }
if {$_n != <字面整数>} { error "..._PIN_COUNT=<top> n=$_n expect=<字面整数>" }
```

`_n`/`_miss` 的输入是 `set_user_match` 的**返回值**，不再是那个永不触发的 `catch`。
再加一对 `<PREFIX>_PIN_BEGIN/END` 标记，让 `scripts/check_pin_errors.py --marker <PREFIX>_PIN`
能把 fm.log 里的行首 `Error:` **按区间归因到本文件**（区间外的多半是别处的投机性试名）。

六个前缀（`IQE_PIN` / `NCBQ_PIN` / `SSIT_PIN` / `TLBFA_PIN` / `TLBNONBLOCK_PIN` /
`RENAMEBUFFER_PIN`）都对着 `check_pin_errors.py` 实测过：干净日志 rc=0，
在区间内种一行行首 `Error:` 就 rc=1 —— **标记不是写上去好看的，它真的被那道判据读**。

---

## 四、★为什么先前的 receipt 不必重跑★

`fm_pins*.tcl` **在证明闭包里**（receipt 的 `proof_config.pin_scripts` 记它的 sha256）。
按 `CONVENTIONS.md`「别把不同前提下产出的结果并列成一张表」，动了它先前的 receipt 就成了旧前提。

判据**不是**"我觉得只动了守卫"，也**不是**"逐字节比对两版的 `set_user_match` 行"——
后者对这些文件根本不成立：它们是 `foreach {…N 行数据…}` + **一行**模板化调用，
照字面比那一行必然不同，**而那一行恰恰就是守卫本身，比了等于自问自答**。
（★判据的输入必须独立于被判断的对象★。）

用的判据是：把 `set_user_match` 换成**记参数的桩**，用 tclsh 真跑两版，
逐字节比对**实际发生的调用序列**（含顺序与重复）。捕获的是行为不是文本。

复算：

```
python3 verif/ut/OthersEntry_common/prove_pin_calls_equal.py <旧文件目录> <变体...>   # Entries* 家族
python3 scripts/prove_pin_calls_equal_dyn.py                                          # 5 个动态钉点文件
```

### 4.1 Entries\* 家族（9 个，静态 foreach 表，改的是生成器）

生成器：`verif/ut/Entries_common/gen_fm_pins.py`（**改生成器，不逐个改产物**）。

| 变体 | 调用数 | 调用序列 sha256（新旧相同） |
|---|---|---|
| `EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v` | 20516 | `38362fe100e278d6` |
| `EntriesAluCsrFenceDiv` | 20308 | `58ee147d7170a35c` |
| `EntriesAluMulBkuBrhJmp` | 20292 | `f3b6057c48a4e885` |
| `EntriesFaluFcvtF2vFmacFdiv` | 13208 | `5d7b2694b2c1040d` |
| `EntriesFaluFmac` | 13166 | `d35c31de7e5543c0` |
| `EntriesFaluFmacFdiv` | 13180 | `aa0479b1bfd61bef` |
| `EntriesVfdivVidiv` | 9898 | `45e97f5fc799bc6c` |
| `EntriesVfmaVialuFixVfalu` | 14374 | `d3e5457776d29428` |
| `EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf` | 14398 | `4add08b4eed05fa9` |

9/9 逐字节相同 ⇒「钉了哪些点」这一维度上闭包没变，**先前 receipt 继续有效**。

★诚实标注★：这些目标 receipt 里记的 `proof_config.pin_scripts` sha256 与当前工作树
**已不同**（守卫文本变了）。桥接它的就是上面这张表，不是口头保证。

### 4.2 注入探针（守卫真的会响 —— 前后对照）

同一个变体、同一个注入（让第 7 次 `set_user_match` 返回 0，模拟一个名字漂了）：

| 版本 | 输出 | tclsh rc |
|---|---|---|
| 旧（catch 计数） | `IQE_PINS: 9898 / 9898 tried, 0 threw` | 0 ★完全没响★ |
| 新（返回值计数） | `IQE_PIN_FAIL: ...` / `IQE_PIN_END ... n=9897 miss=1 expect=9898` | 1（`error` 抛出） |

---

## 五、5 个动态钉点文件（`NCBTransactionQueue` / `RenameBuffer` / `SSIT` / `TLBFA` / `TLBNonBlock`）

这 5 个不是静态表：它们现场调 `report_unmatched_points` 发现点名再按结构配对。
所以调用序列是 **`report_unmatched_points` 输出的函数**，证明必须把那个输入固定住再比。

### 5.1 病灶有两种形态

| 文件 | 形态 | 旧状态 |
|---|---|---|
| `RenameBuffer` / `TLBFA` / `TLBNonBlock` | **空守卫** | `catch {set_user_match}` 的中止路径永远走不到，`_pinned` 无条件自增，连带把 `$_pinned != [llength $_impl]` 一起架空 |
| `NCBTransactionQueue` / `SSIT` | **根本没有中止路径** | 通篇只有 `puts`；一个点都没配上也照样跑完、照样绿 |

### 5.2 期望数量的出处（自己重测，不抄现成数字）

| 目标 | 期望 | 出处 |
|---|---|---|
| `RenameBuffer` | 51 | golden `RenameBuffer.sv` 现数：5 flag + 5×8 value + 6 preg bit7 |
| `TLBFA{,_1,_2,_3}` | 33 / 44 / 22 / 22 | 11 位死位 × PORTS(3/4/2/2)；PORTS = golden `reg [37:0] reqVpn[_N];` 条数；11 = bit37..27 无读者（全部读出切片最高只到 bit26：`[26:18]/[17:9]/[8:0]/[3:0]/[2:0]`） |
| `NCBTransactionQueue{,_1}` | 1472 / 736 | 23 位/槽（ReturnNID 11 + ReturnTxnID 12）× 槽数(64/32)，槽数 = golden `regQueue_*_bits_info_ReturnNID` 条数。★无后缀是 **64** 槽、`_1` 才是 32 槽 —— 与 `fm_eq.tcl` 注释里"736/1472"的行文顺序相反，别照抄顺序★ |
| `SSIT` | 91 | golden `SSIT.sv` 现数，14 个改名寄存器位宽之和（width = hi+1）：20+11+5+1+10+10+1+10+10+1+1+5+5+1 |
| `TLBNonBlock{,_1,_2}` | 8 / 4 / 3 | A 族 = golden `reg r[_N];` 条数 8/4/2（机械）；B 族 = 0/0/1（**数声明看不出来**，取已提交 evidence 实测，`evidence/88d4f00d0fe1/` 与 `evidence/522c3fe3d5dd/` 两个独立目录一致） |

### 5.3 证明结果（`scripts/prove_pin_calls_equal_dyn.py`，可复跑）

它对每个变体喂一组按该文件自己声明的结构造出的夹具，old（`git show a2434c2a:<path>`）
与 new 各跑一遍 tclsh，逐字节比对调用序列；再做一次**注入探针**（让第 1 次调用返回 0），
要求**旧版不抛、新版必抛**。

| 变体 | 调用数 | 调用序列 sha256（新旧相同） | 注入探针 |
|---|---|---|---|
| `RenameBuffer` | 51 | `826824bd925d7861` | 旧 rc=0 没响 / 新 rc=1 抛出 |
| `TLBFA` | 33 | `e4888a0db5d49ff2` | 同上 |
| `TLBFA_1` | 44 | `95d4f948afe49a29` | 同上 |
| `TLBFA_2` | 22 | `d70ea05efb36999a` | 同上 |
| `TLBFA_3` | 22 | `27e8594f37dc41e4` | 同上 |
| `TLBNonBlock` | 8 | `d7e074e2e32b6bee` | 同上 |
| `TLBNonBlock_1` | 4 | `f661478a21871e65` | 同上 |
| `TLBNonBlock_2` | 3 | `25eaa21b2829a196` | 同上 |
| `NCBTransactionQueue` | 1472 | `ee20d210319c9ceb` | 同上 |
| `NCBTransactionQueue_1` | 736 | `359e835e766c77e8` | 同上 |
| `SSIT` | 91 | `80b225deb5231f7a` | 同上 |

11/11 逐字节相同 ⇒ **先前 receipt 继续有效**；机读结果 `docs/pin_guard_dyn_proof.tsv`。
★诚实标注★同 §4.1：`proof_config.pin_scripts` 的 sha256 与工作树已不同，桥接它的是这张表。

### 5.4 顺带

`TLBFA` 的 `puts` 原本是中文，落进 `fm.log` 会变成一串问号（`CONVENTIONS.md:880` 里
存着当年那几行的问号残骸为证）。本轮既然要动这个文件，一并改成 ASCII。
这不改变任何 `set_user_match` 调用，已被 §5.3 的调用序列比对覆盖。

---

## 六、台账

`scripts/test_fm_pins_wellformed.py` 里的 `CATCH_COUNT_LEDGER` 是 ratchet（只许缩不许长）。
本轮缩 12 条：9 个 `Entries_*` + `RenameBuffer` / `TLBFA` / `TLBNonBlock`。
`NCBTransactionQueue` / `SSIT` 本就不在表里（它们不是"用 catch 数"，是**根本没有守卫**），
同一轮一并补成 fail-closed。

缩表后 `python3 scripts/test_fm_pins_wellformed.py` **rc=0**（21 项全过，含 M0b..M14 负测）。

---

## 七、把这件事做成一道**可复跑的闸**：`scripts/pin_call_equiv.py`

§4/§5 那两张表是**一次性产物**。但「动了钉点文件，既有 receipt 还算不算数」这个问题
**还会反复发生** —— 只要有人改名、改期望、加规则就要回答一次。
这个能力如果只留在一次性脚本里，下一个人会重新发明一遍，
或者更糟：**直接声称"只是守卫改动"而不证明**。

所以做成闸：

```
python3 scripts/pin_call_equiv.py               # 闸：对着基线表核对（gate_all 已接）
python3 scripts/pin_call_equiv.py --selftest    # ★双向负测★（gate_all 已接，跑在闸之前）
python3 scripts/pin_call_equiv.py --list        # 覆盖情况
python3 scripts/pin_call_equiv.py --compare-rev <git-rev> [--tsv out.tsv]
                                                # 工作树 vs 某版本，直接回答"要不要重跑"
python3 scripts/pin_call_equiv.py --update      # 重建基线（★只在重出 receipt 之后★）
```

### 7.1 何时**必须**跑

* 改了任何 `verif/ut/*/fm_pins*.tcl` —— 提交前跑 `--compare-rev <改动前的 rev>`，
  把结论写进 commit message。`GUARD_ONLY` 才可以说"receipt 继续有效"。
* 判 `NEEDS_RERUN` 时 **不要**自己去 `--update` 把表改绿 ——
  那等于给旧 receipt 背书。先重出 receipt，再更新表。

### 7.2 覆盖面

| 类型 | 判别 | 怎么跑 | 数量 |
|---|---|---|---|
| 静态 | 钉点表写死，只依赖 `$top` | 把 `$top` 设成文件里声明的变体，**不需要夹具** | 40 文件 / 49 变体 |
| 动态 | 用 `report_unmatched_points` / `find_cells` 现场发现点名 | 需 `verif/ut/<目标>/fm_pins_fixture.tcl` 把查询输出固定住 | 7 文件 / 14 变体 |
| 缺夹具 | 动态但夹具还没写 | 进 `NO_FIXTURE` 棘轮，逐条写明原因 | 1（`Predictor`） |

两条棘轮双向约束：`NO_FIXTURE` **只许缩**（新动态文件没夹具一律判红），
`COVERED_DYNAMIC` **只许涨**（已覆盖的不许悄悄退回无夹具）。
基线表 `docs/pin_call_seq.tsv` 63 条，全跑一遍约 11 秒。

### 7.3 双向负测（`--selftest`）

**只判红的实现和恒等判绿的实现都必须露馅**，所以两侧都种病：

* **A 组：真守卫专属 → 必须判绿**（改错误消息文本 / 加一行 `puts` /
  返回值计数↔catch 计数互换 / 期望值从字面量改成变量）—— 静态动态各 4 条
* **B 组：真改了钉的点 → 必须判红**（改一个 ref 名字 / 少钉一对 / 多钉一对 /
  换两对的顺序 / 改 impl 侧路径模板）—— 静态动态各 5 条
* **C 组**：跑不起来时必须 `rc != 0` 且调用序列为空 ——
  ★"跑不起来"不能读成"没有差异"★

### 7.4 ★端到端实测：这道闸抓的是结构闸看不见的东西★

在真钉点文件 `EntriesVfdivVidiv/fm_pins_pre.tcl` 里把**一对钉点的 ref 名改一个词**
（`entryReg_payload_*` -> `entryRegX_payload_*`），守卫一个字没动：

| 闸 | 结果 |
|---|---|
| `test_fm_pins_wellformed.py`（结构闸） | **rc=0 绿** —— 它管"守卫写对没有"，看不见钉的是哪些点 |
| `pin_call_equiv.py`（本闸） | **红**：`9898 条/45e97f5f… -> 9898 条/94d0646a…` |

★注意调用数**没变**（都是 9898）★ —— 一个只比"钉了多少对"的判据会**放过**这个改动。
必须比序列本身。

另外两条基线篡改也实测过：把一条已有条目的调用数改小 -> 红；
往基线里塞一条测不到的条目 -> 红（"基线表里有、现在测不到"）。

### 7.5 一次独立交叉核对

本工具测出的 18 个 `OthersEntry_*` 调用数，与**另一条 lane 独立写的**
`verif/ut/OthersEntry_common/PIN_GUARD_FIX.md` 那张表 **18/18 逐个相同**。
两个互不知情的量法给出同一组数 —— 这是对量法本身的一次外部验证，
比我自己说"我的桩是对的"强。

---

## 八、`LoadQueueReplay`（`agent/lqreplay-fm`）—— 第一个真客户，以及三条比 `exit` 更重的发现

集成者派这道闸去处理 `agent/lqreplay-fm` 的 `LoadQueueReplay/fm_pins_pre.tcl`
（它用 `exit 3`，并且明确拒绝为了让闸变绿去动已出证的文件 —— **它拒得对**）。
本 lane 只从 `git show agent/lqreplay-fm:<path>` 读了 git object，**没有碰它的 worktree**，
也**没有改它的文件**（等它回话）。读出来的事比双方原先以为的都多：

### 8.1 ★那个 `exit 3` 不可达★

```tcl
proc pin {r i} {
  if {[catch {set_user_match $r $i} m]} { incr ::LQR_PIN_BAD ... } else { incr ::LQR_PIN_OK }
}
...
if {$::LQR_PIN_BAD > 0} { ... exit 3 }
```

`set_user_match` 从不抛 ⇒ `LQR_PIN_BAD` 恒 0 ⇒ **`exit 3` 一次都不会执行**。
日志里 `LQR_PINS: accepted=N rejected=0` 的那个 0 是恒真的，不是测出来的。

⇒「要么闸认 `exit`，要么改文件并重跑」是个**假两难**：认不认都不影响，因为那条路不可达。
真正要改的是发射端（`catch` → 返回值），而那**正好**是调用序列等价能担保的守卫改动。

### 8.2 ★它一合进来，钉点结构闸会因 **P1** 变红，与 P2 无关★

拿 `test_fm_pins_wellformed.py` 的 `check()` 跑它的文件，报 5 项：

```
P1 第 49 行 `set_app_var`
P1 第 50 行 `set_app_var`
P1 第 11 行 `setup`
P4 用 catch 数钉点
P3 期望数量没声明 / 校验没在最后一次 set_user_match 之后
```

★`P1` 对谁都不豁免★：`FAIL_OPEN_LEDGER` 只豁免 P2/P3，`CATCH_COUNT_LEDGER` 只豁免 P4。
所以「合入 → 收紧 P2」这个顺序里藏着一个谁都没算到的红：**它在 P1 上就红了。**

### 8.3 钉点数是**量出来的 6290**，不是算出来的 1990

本 lane 第一次是按它的循环**心算**出 1990，写进给对方的消息时自己标了
"请你独立复核，别信我的算术"。随后用桩真跑了一遍：**6290**（无重复对）。
★算术错了 3 倍★ —— 这就是为什么期望值必须**量**，不能**推**
（`debug_vaddr` 一族单独就是 72×50 = 3600，心算时整族漏掉了）。

复算：把它的 `fm_pins_pre.tcl` 喂给本文件 §7 那个桩（另需 `setup` / `set_app_var` 空桩），
数 `CALL` 行。

### 8.4 待办（不归本 lane 单方面决定）

- 改法提案（`catch` → 返回值 + `error` + `$OK != 6290` 一道 + `LQR_PIN_BEGIN/END` 标记）
  已发给 `agent/lqreplay-fm`，**但 SendMessage 两次都报 "No agent reachable"**，
  需要集成者转达。在它回话之前不动它的文件。
- P1 那三项（`setup` / 两个 `set_app_var`）**不在调用序列等价的担保范围内** ——
  它们改的是**证明输入**不是守卫，改了必须重跑。本 lane 不碰。
- ★P2 收紧到只认 `error` 暂缓★：顺序是「先修 LoadQueueReplay，再收紧」，
  而 LoadQueueReplay 还没对齐。先收紧会把它打红，而那个红会被读成"收紧收坏了"。
