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

## 二、中止一律用 `error`，不用 `exit`（本轮实测更正）

钉点代码在 sidecar 模式下由 `scripts/sidecar/fm_native_emit.tcl:133` 的
`interp create -safe` 放进**受限子解释器**里执行，而 **Tcl 的 safe interp 隐藏 `exit`**：

```tcl
set i [interp create -safe]
$i eval {info commands exit}    ;# -> ★空（命令不存在）★
$i eval {info commands error}   ;# -> error
$i eval {exit 3}                ;# -> 抛出: invalid command name "exit"
$i eval {error "PIN_MISS"}      ;# -> 抛出: PIN_MISS
```

所以存量里那些 `exit 3` **确实会中止**，但**是靠"这个命令不存在"中止的，
不是靠写的人表达的那个意思** —— 与本轮要修的病是同一族：
*代码看起来表达了意图，实际起作用的是别的机制*。它今天恰好 fail-closed，
但一旦有人把它包进 `catch`、或哪天 sidecar 换成非 safe interp，行为就变，
而没有任何判据会提醒。

⇒ 本轮把 14 个文件里所有中止路径**统一改成 `error "<可读原因>"`**。

（附带一条别读错：负测 `M10「exit 0 装成中止」`判的是**文本形态**，不是运行时行为 ——
在真实 safe interp 里 `exit 0` 也会抛。它作为"别这么写"的静态约定仍然合理。）

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
