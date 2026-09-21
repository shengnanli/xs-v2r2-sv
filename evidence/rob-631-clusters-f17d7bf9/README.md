# Rob 的 631 个 failing：聚类、处置，以及「0 是够不着的」这件事

本目录回答三个问题，每一个都带可重跑的命令：

1. `FM_FAILING_LIMIT=0` 那次诊断跑的 **631 个 failing 点**分别是什么、各多少个；
2. 其中哪些是**重写的真 bug**（改核对齐 golden），哪些不是；
3. 为什么 `make -C verif/ut/Rob fm-Rob`（signoff-strict）**在当前证明边界上不可能
   SUCCEEDED** —— 并且这个"不可能"是 golden 自己的性质，不是重写没写好。

---

## 0. ★先纠正一条会误导后来人的记账★

`wt-rob-v2x/verif/ut/Rob/fm_work/Rob/receipt.json` 记的是

```
"impl_commit": "f17d7bf9801e2574ca45d35a55cad301fe8f9ada"
"impl_closure": [{"path": "rtl/backend/Rob.sv",
                  "sha256": "b343179b74d2a109742935f510996ea73970d80b17c42d40f31b1fb7498d83ff"}]
"impl_closure_hashed_at": "post_run"
```

**那次跑读到的并不是这份源码。** 时间线（都可查）：

| 时刻(EDT) | 事件 | 出处 |
|---|---|---|
| 22:09:57 | 诊断跑启动，fm_shell 开始读 `rtl/backend/Rob.sv` | `FM_RUN_ID=Rob-diag-20260921T020957Z`（UTC 02:09:57 = EDT 22:09:57） |
| 22:22:43 | 真 bug 1/4 落盘 | `git log 1c5989f0` |
| 22:23:41 | 真 bug 2/4 落盘 | `445c17da` |
| 22:24:47 | 真 bug 3/4 落盘 | `64a78f86` |
| 22:26:20 | 真 bug 4/4 落盘 | `d248c3eb` |
| 次日 01:45 | 跑结束，`make_receipt.py` 此时才去 `git rev-parse HEAD` 并 hash 文件 | `fm.log` mtime |

所以 631 这张画像是**修 bug 之前**的源码的画像，而 receipt 上却盖了修完之后的
commit 和 hash。`impl_closure_hashed_at: post_run` 正是这个坑的名字。

★教训：跑了三个半小时的证明，中途不许动被证明的文件；harness 该在 **run 前**
钉 hash、run 后复核两次是否一致，不一致就作废。★ 本目录只把事实记下，没有改
harness（那是共享文件，不该由一条 lane 单方面动）。

数字上也能自证：该 receipt 的 `unread_impl = 261`，正是真 bug 4/4 要消掉的
256 个 `s_reg3..s_reg10` 加上真 bug 3/4 要消掉的 5 个 —— 两条都"已修"却分毫未动，
只可能是跑的时候它们还在。

---

## 1. 631 的聚类（逐条数出来，和恰好 631）

明细见 `clusters_631.tsv`（从 `failing.rpt` 机械提取，脚本口径：
按 `_<数字>_` / `_<数字>` / `[<数字>]` 归一化成族名）。

| # | 簇 | 点数 | ref 类型 | `*` 标记 | 性质 |
|---|---|---|---|---|---|
| A | `robEntries_<0..159>_isHls_reg` | **160** | DFF | 否 | ★重写真 bug★ |
| B | `io_commits_info_<0..7>_debug_otherPdest_<0..6>[0..7]` | **448** | Port | 是 | golden 自比对地板 |
| C | `deqPtrGenModule/io_next_out_<1..7>_flag` | **7** | BBPin | 是 | golden 自比对地板 |
| D | `enqPtrGenModule/io_out_<1..5>_flag` | **5** | BBPin(Impl None) | 否 | ★重写真 bug★(边界不对称) |
| E | `io_csr_fflags_next_bits_r_reg[0..4]` | **5** | DFF | 否 | ★重写真 bug★ |
| F | `io_lsq_scommit_REG_reg[0..3]` | **4** | DFF | 否 | ★重写真 bug★ |
| G | `io_csr_vxsat_next_bits_r_reg` | **1** | DFF | 否 | ★重写真 bug★ |
| H | `io_csr_vxsat_next_valid_last_REG_reg` | **1** | DFF | 否 | ★重写真 bug★ |
| | **合计** | **631** | | | |

`*` 是 Formality 自己打的标记，原文：*"This failure may be due to an undriven
signal in the reference design"*。631 里带 `*` 的恰好 **455**，不带的 **176**。

### 真 bug 的根因与修法（都已在 f17d7bf9 之前落盘）

* **A（160 点）**：`isHls` 必须在 Mux1H **之后**算。golden 是
  `f(Mux1H(fuType), Mux1H(fuOpType[8:4]))`（`_GEN_3881` / `_GEN_11894`），
  f 含相等比较与取反，非线性，与 Mux1H 不可交换；enqOH 非 one-hot 可达。
  修在 `1c5989f0`。
* **E/F/G/H（11 点，同一个 bug 的两个站点）**：Chisel `Vec(160)` 用 8 位下标读，
  firtool 展成 256 格表，160..255 这 96 格填的**全是条目 0**，所以"没命中"的
  默认值是条目 0 而不是 0。`fflagsDataRead` / `vxsatDataRead` / `entryVls`
  三处漏了。修在 `445c17da`。
* **D（5 点）**：golden 里 `enqPtrVec_<1..5>_flag` **没有任何读者**，于是 FM 把
  `enqPtrGenModule` 的这 5 根 pin 推断成**输入**（BBPin 比较点）；重写把它们接进
  可读核当输出用，方向推断就反了，配不上对。修在 `64a78f86`（照 golden 悬空）。
  同一处还顺带修了 `deqPtrVec_next_<1..7>_flag`（簇 C 的 impl 侧）。

### 465 个 unmatched_ref 的分解（也恰好加和）

| 类 | 点数 | 处置 |
|---|---|---|
| `Und robDeqGroup_<0..7>_debug_otherPdest_<0..6>[0..7]` | 448 | golden-only 悬空寄存器；地板 |
| `Und deqPtrVec_next_<1..7>_flag` | 7 | golden-only 悬空（黑盒边界造成）；地板 |
| `Und enqPtrVec_<1..5>_flag` | 5 | 同上；地板 |
| `BBPin enqPtrGenModule/io_out_<1..5>_flag` | 5 | ★重写漏钉/方向不对称★，已修 `64a78f86` |
| 合计 | **465** | |

另有 56 个 `deqPtrGenModule/io_next_out_<1..7>_value[0..7]`，ref 侧 impl 侧**各 56**，
属 unread 黑盒 pin，不计入上面这 465（FM 汇总表的 unmatched 行是 465(56)）。

**集合级验证**（不是数字相等，是元素相等）：

```
python3 - <<'PY'
import re
def load(p,side='Ref'):
    return {(m.group(1),m.group(2)) for m in
            (re.match(r'\s*\*?'+side+r'\s+(\S+)\s+(\S+)\s*$',l) for l in open(p)) if m}
floor = load('evidence/rob-selfcompare-4aa8838b/run_binaryX/unmatched_460.rpt')
diag  = load('<wt-rob-v2x>/verif/ut/Rob/fm_work/Rob/unmatched.rpt')
diag  = {x for x in diag if 'io_next_out' not in x[1]}      # 去掉 56 个 unread bbpin
print(len(floor), len(diag), floor-diag, sorted(diag-floor))
PY
```

实测输出：`460 465 set() [5 条 enqPtrGenModule/io_out_<1..5>_flag]`
—— 诊断跑的 465 **正好是**已入库的 460 地板 **加上** 真 bug 3/4 的那 5 条。

---

## 2. ★631 = 460 + 171★

`evidence/rob-selfcompare-4aa8838b/` 里已经量过：golden Rob 与**自己逐字节相同的
副本**比，在 Formality 默认 `verification_set_undriven_signals = binary:X` 下

```
passing 108209 / failing 20 / unverified 440 / unmatched ref 460 / FAILED
108209 + 20 + 440 = 108669  （守恒闭合）
```

那 460 = 448 `robDeqGroup_*_debug_otherPdest_*` + 7 `deqPtrVec_next_*_flag`
+ 5 `enqPtrVec_*_flag`，与本目录的簇 B + C + D **同一批信号**。

该 README 留了一个未决问题：*"460 到底怎么分成 20 failing + 440 unverified，
本目录没有确立"*。**本次 limit=0 的诊断跑把它确立了**：20/440 只是
`verification_failing_point_limit=20` 的截断，真实数量是 **460 个 failing
比较点**（448 个 Port + 7 + 5 个 BBPin），不是两类。

于是

```
631 (limit=0 实测) = 460 (golden 自比对地板) + 171 (重写真 bug: A 160 + E/F/G/H 11)
```

（簇 D 的 5 点在地板里以 *matched BBPin* 的形态出现；修 3/4 之前它在重写侧是
*unmatched*，所以它同时是"真 bug"和"地板成员"—— 修好之后它回到地板里。）

---

## 3. ★地板拿不掉：任何 sound 的 undriven 设置都拿不掉★

### 3.1 最小复现（秒级，20 行）

`undriven_floor_min/T.sv` 是 golden 的形状：4 个**声明了但从来没有驱动**的寄存器，
经 mux 送到主输出 —— 与 golden Rob 的
`robDeqGroup_<n>_debug_otherPdest_<m> -> io_commits_info_*` 同构。

```
cd undriven_floor_min
./run_floor.sh binary:X T.sv        # ★把 T.sv 同时当 ref 和 impl★
```

实测：

```
FLOOR_REF_UNMATCHED 32
FLOOR_IMPL_UNMATCHED 0
Verification FAILED
 16 Passing compare points
 8 Failing compare points (8 matched, 0 unmatched)
```

**同一个文件、同一份字节，FM 判 FAILED。** 机制：`binary:X` 的两半是
`<implementation>:<reference>` —— 参考侧的悬空信号变成 X **割点**（必须被配对），
实现侧的悬空信号**不产生割点**。于是参考侧永远多出 N 个配不上对的自由变量，
落在它们扇出锥里的比较点必然失败。重写写成什么样都一样：

```
./run_floor.sh binary:X T_rewrite_style.sv   # 重写风格（core 子模块 + 非打包数组）
→ 同样 32 / 0 / FAILED / 8 failing
```

### 3.2 四种取值的完整矩阵（合法取值只有 `0 1 binary binary:X 0:X synthesis`）

两组被测对象：
* **地板**：`T.sv` vs `T.sv`（逐字节相同）—— 一个正确的证明必须 SUCCEEDED；
* **安全性**：`evidence/rob-selfcompare-4aa8838b/undriven_safety/` 里那两组
  （实现漏驱动一根线；参考分别用真逻辑 / 恒 0 的死驱动）—— 必须 FAILED。

| 设置 | 地板(自比对) | 漏驱动·参考真逻辑 | 漏驱动·参考恒 0 | 交换两根悬空源 |
|---|---|---|---|---|
| `binary:X`（默认） | **FAILED** ✗ | FAILED ✓ | FAILED ✓ | — |
| `synthesis` | **FAILED** ✗（割点跑到 impl 侧） | FAILED ✓ | FAILED ✓ | — |
| `0` | SUCCEEDED ✓ | FAILED ✓ | **SUCCEEDED** ✗掩盖 | — |
| `binary` | SUCCEEDED ✓ | FAILED ✓ | FAILED ✓ | **SUCCEEDED** ✗掩盖 |

最后一列是本轮新加的判据，`undriven_floor_min/run_swap.sh`：
ref 是 `o1=g_0; o2=g_1`，impl 是 `o1=g_1; o2=g_0`（两根悬空源**对调**）。
哪根悬空源走到哪个输出，是**真实的结构差异**，sound 的处理必须判不等价。

```
./run_swap.sh binary
→ Verification SUCCEEDED
   4 Passing compare points
```

`binary` 判等价 ⇒ 它把所有悬空信号折叠成同一个值，**不是**每根一个自由变量。
所以 `binary` 看着"既拆掉地板又抓得住漏驱动"，其实只是那两个反例恰好不撞它的盲区；
`run_swap.sh` 就是撞它盲区的那个反例。

**结论：拆掉地板的三种取值（`0`/`1`/`binary`）都会掩盖真实差异；不掩盖的两种
（`binary:X`/`synthesis`）都留着地板。没有第三条路。**

### 3.3 于是 Rob 在当前边界上不可能 signoff-strict SUCCEEDED

`scripts/fm_verdict.py` 的 signoff-strict 要求
`failing == 0 && unmatched == 0 && unverified == 0 && aborted == 0 && unread == 0
&& blackbox_out == 0`。其中

* `failing == 0`：被 448 挡死（golden 自己都过不了）；
* `unmatched == 0`：被同一批 448 个 ref 侧 Und 割点挡死。

这两条**与重写质量无关**，任何 impl 都过不了。根因是 golden 自身的设计事实
（`evidence/rob-selfcompare-4aa8838b/` 的 Addendum 已从 Chisel 源码坐实）：
`RobCommitEntryBundle.debug_otherPdest` 有声明、有读者（一路读到
`io.commits.info(i).debug_otherPdest` 端口）、**没有写者** ——
`RobEntryBundle` 根本没有这个成员，`connectCommitEntry` 无从拷贝。
**golden 的这 448 个输出位在综合后的设计里是未定义的。**

能做而本 lane 没做的两件事（都要 reviewer 裁定，不该由一条 lane 自己定）：

1. **把 8 个子模块两侧 elaborate**（本仓已有先例：IMSIC / NewCSR / TL2）。
   这会拿掉簇 C+D 那 12 个**边界伪影**（它们悬空只是因为子模块被黑盒），
   以及 56 个 unread 黑盒 pin 和 `blackbox_out=56`。
   地板从 460 降到 **448**，仍然不是 0。
2. **给 `fm_eq.tcl` 加 fail-closed 的 `FM_UNDRIVEN` 旋钮**（Makefile 里已写明
   "NOT YET WIRED"，且上一条 lane 明确不单方面加）。但由 3.2 的矩阵，**没有一个
   取值同时满足"拆地板"和"不掩盖"**，所以这个旋钮解决不了 Rob 的问题，
   只会把问题换个地方。

诚实的结论是：**Rob 这一层的 FM 判据需要一条新的、被裁定过的结论类**
（形如"golden 自比对地板"这样的非 PASS 标签，`ROB_SELF_COMPARE_FLOOR` 已经是
codex 0168 给它起的名字），而不是一个更松的 appvar。本 lane 不自己发明它。

---

## 4. 本目录的文件

| 路径 | 内容 |
|---|---|
| `clusters_631.tsv` | 631 个 failing 的机械聚类，含代表点与两侧路径 |
| `undriven_floor_min/T.sv` | 地板的 20 行最小复现（golden 形状） |
| `undriven_floor_min/T_rewrite_style.sv` | 同一函数的重写风格写法 |
| `undriven_floor_min/run_floor.sh` | 地板复现脚本，取 undriven 设置作参数 |
| `undriven_floor_min/swap_ref.sv` / `swap_impl.sv` / `run_swap.sh` | `binary` 的 soundness 反例 |
