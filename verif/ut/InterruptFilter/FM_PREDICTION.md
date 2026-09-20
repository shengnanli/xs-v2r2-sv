# InterruptFilter FM 跑前预登记

**登记时间点**：RTL 与 UT harness 已落库（`c6fd8743`），UT 六轮正在跑，
**本配置的 FM 一次都还没跑过**。本文件先于 FM 提交；跑完只在下面 §5 追加实测，
不改 §1~§4 一个字。

---

## 1. 本次证明配置

| 项 | 值 |
|---|---|
| ref | golden `InterruptFilter.sv` + `DelayN_17.sv` + `DelayN_208.sv` |
| impl | `rtl/backend/InterruptFilter.sv`（重写件） + **golden** `DelayN_17.sv` + **golden** `DelayN_208.sv` |
| FM_MODE | `signoff-strict`（Makefile 未设 FM_MODE） |
| FM_ALLOWLIST | 0 |
| FM_MERGE_DUP | 未设 → `fm_eq.tcl` 默认 `true` |
| vmucp | false（未设） |
| 黑盒 | **0 个**（`check_closure_symmetry.py --only InterruptFilter` → `SYMMETRIC=1`，rc=0） |
| `verif/allow/InterruptFilter.json` | 不存在 |
| `verif/dead_ref/InterruptFilter.json` | 不存在 |
| `fm_pins.tcl` / `fm_pins_pre.tcl` / `fm_map/` | 不存在（若跑后需要钉点，另立一次、另写一版预登记） |

输入字节（`sha256`）：

```
3db694810bd971444af02cb6d0cff87d19577fe1989e6d2ab663e1cb0281d27a  rtl/backend/InterruptFilter.sv
df21dd1c865fba187068a3c8f59ee7b76f0a2e20f834e31b5d0720fe7b3f0924  verif/ut/InterruptFilter/Makefile
0f05d326f7046571d1b1e8a536ada0dbb757200658f6c00d5dacff04c03e515b  verif/ut/InterruptFilter/tb.sv
617b54539fc08deed87815df84c74bf8712def9f1aee7d36e13f72a19f7d7321  verif/ut/InterruptFilter/gen.py
6fa2a02f02439140887b6a9741ccd9667c7cb3efdcf57a2a5b5282a77a6d5d34  G1/golden-rtl/InterruptFilter.sv
c255f4aa1501a94103c31a6f9ebc8cf92d7bee7fedb40f230bbb90811dcc39e5  G1/golden-rtl/DelayN_17.sv
40e0d6caa4a4ff9c5b61ce6caca0b2034824160803ca4f1ce6f295de45de027d  G1/golden-rtl/DelayN_208.sv
```

G1 canonical：`G1-a4ea14f2ddf612bb4ad023d26a2ca1bf33eddcaebe470b0c620e9fba0e7afcf0`

复跑命令：`cd /home/eda/xs-env/wt-intfilter && scripts/run_proof.sh InterruptFilter InterruptFilter`

---

## 2. ★结论边界（写在预测前面）★

**无论本次 FM 跑成什么样，`InterruptFilter` 都不许记 `PROVEN_DIRECT`。**

`InterruptFilter` 例化 6 个子模块，全部来自 `DelayN` 家族：

| child | 实例数 | 规模 | impl 侧用的是 | 本 target 对它的信息量 | 台账应记 |
|---|---|---|---|---|---|
| `DelayN_17`  | 5（debugIntr / nmi / viIsHvictlInject / irToHS / irToVS） | 5 级 × 1 位移位链，无复位无使能，golden 43 行 | **golden 字节** | **零** | `MISSING/UNPROVEN` · `UNCHANGED_GOLDEN_DEP` |
| `DelayN_208` | 1（intrVec） | 5 级 × 8 位移位链，同上 | **golden 字节** | **零** | `MISSING/UNPROVEN` · `UNCHANGED_GOLDEN_DEP` |

这两个 child 正由另一条 lane（`agent/delayn-clz`）重写，尚未合入 main。
所以本次 FM 若绿，它证明的是：

> 在「`DelayN_17` / `DelayN_208` 取 golden 定义」这个**前提**下，重写的
> `InterruptFilter`（wrapper + 可读核 + 6 个实例的接线）与 golden 的
> `InterruptFilter` + `DelayN_17` + `DelayN_208` 等价。

即 **条件性证明 + 子依赖未闭合（`UNCHANGED_GOLDEN_DEP`）**，对应交办给的三条路里的第 2 条。
另按 codex 0168 §1：child 没有重写实现时只能报条件性证明，
"两侧同一个 golden 文件"与"对称黑盒"都**不算** `PROVEN_DIRECT`。

### 为什么选"两侧白盒同源"而不是"两侧对称黑盒"

两条都合规，选白盒的理由与 Sbuffer 那次一致（codex 0168 的偏好：不扩大黑盒）：

- 白盒时 6 个实例的**接线**（哪个寄存器接哪条延迟链、5 级深度、位宽 1 vs 8）
  是真的被比出来的；黑盒则只比黑盒边界的引脚，接错到另一条链上照样能过；
- 白盒时 `unresolved_blackbox = 0`，判决不挂在两个未签核 child 上，
  `signoff-strict` 直接可用（strict 模式遇到未声明黑盒会判 `strict_has_blackbox`）；
- 代价是这 65 位延迟链寄存器两侧逐字同名、必然配上 —— 那是"白送"，
  所以它们被显式记成 `UNCHANGED_GOLDEN_DEP`，见上表。

### child 其实很小 —— 但"小"不是转绿的理由

两个 child 合起来 65 位无复位移位寄存器、0 子模块、0 分支。`rtl/common/` 下
已有 `xs_DelayN_core.sv` 这个参数化核与 `DelayN_1/7/8/9/13.sv` 五个薄变体，
`DelayN_17`（STAGES=5, WIDTH=1）与 `DelayN_208`（STAGES=5, WIDTH=8）照着写各约 30 行。
本 lane **不碰 `rtl/common/`**（那是 `agent/delayn-clz` 的地盘）。
等它合入后把 `RTL_GOLDEN_DEPS` 改指到重写件、重跑一次 FM，闭包才闭合。

---

## 3. passing 预测

模型（`scripts/tlbsw_passing_model.py`，`gate_all.sh` 里有 6 点自校准）：

```
passing = 证明闭包的触发器位数 + 顶层 output 端口位数
```

逐项（全部由 `tlbsw_passing_model.py` 的函数在 golden 上现算，不手抄）：

| 项 | 位数 | 来源 |
|---|---|---|
| `InterruptFilter` 自身触发器 | **439** | 123 个 `reg` 声明（见下面的字段明细） |
| `DelayN_17` × 5 实例 | **25** | 每实例 5 个 1 位 `reg` |
| `DelayN_208` × 1 实例 | **40** | 5 个 8 位 `reg` |
| 闭包触发器合计 | **504** | |
| 顶层 output 位 | **74** | 13 个 output 端口（2×12 位 IID + 1×12 + 3×8 + 8 位 bits + 6 个 1 位） |
| **预测 passing** | **578** | |

failing = 0，unmatched = 0，unread = 0，`dont_verify` = 0，黑盒 = 0。

### 439 位是怎么来的（这一条决定了我的寄存器字段集合必须照搬 golden）

golden 的 `Reg(Vec(8, new IpriosSort))` 三族，字段**不全**：

| 族 | idx(6) | enable(1) | isZero(1) | greaterThan255(1) | prioNum(8) |
|---|---|---|---|---|---|
| `mipriosReg[0..7]`  | 8 个 | 8 个 | 8 个 | **只有第 3 组** | 8 个 |
| `hsipriosReg[0..7]` | 8 个 | 8 个 | 8 个 | **只有第 3 组** | 8 个 |
| `hvipriosReg[0..7]` | 8 个 | 8 个 | 8 个 | **一个都没有** | **只有 0..6 组** |

机理：这些字段在 **Chisel 源里就是字面常量**（`greaterThan255 := false.B`
除 EI 那一条之外；VS 第 7 组的槽位 56..60 = 中断 51/25/50/49/24/48 没有任何
hviprio 字节，`prioNum` 恒 0），firtool 的寄存器常量折叠在这些位上生效。
而 `mipriosReg_0_enable` 虽然最终也恒 0（`mip` 根本没有 ≥14 的端口），
却**保留着**（`mipriosReg_0_enable <= 1'h0`）—— 因为那个 0 要等 64 位向量的
位提取折叠之后才看得见，晚于寄存器折叠那一趟。

所以 golden 的寄存器集合是 firtool 的 pass 顺序留下的形状，不是"逻辑上该有的形状"。
重写件按同一份形状声明（`rtl/backend/InterruptFilter.sv` §5），多一位常零寄存器
就会在 FM 里变成一个配不上的比较点。

余下：`hvictlReg` 4 个字段（IID 12 / DPR 1 / IPRIOM 1 / IPRIO 8 —— **没有 VTI**，
它的寄存器没有读者）、`vstopeiReg_IPRIO` 11 位（**没有 IID**），
以及异步复位域的 21 个（2 个 xtopiIsNotZero + 13 个 Candidate 组合标志 +
intrVec 8 + debugIntr/nmi/viIsHvictlInject/irToHS/irToVS 各 1）。

---

## 4. 已知风险（跑之前就写下来，不留事后解释的余地）

1. **配对风险（最大的一个）**：三族 97 个数组寄存器在 impl 侧是 SoA 数组
   （`mipriosReg_idx[8]` …），在 ref 侧是 firtool 展平的
   `mipriosReg_0_idx`。`fm_eq.tcl` 的 `auto_match_flattened_arrays` 处理的是
   `name_reg[i][j]` ↔ `name_i_j_reg` 这种形状，而 golden 这里是
   `name_<i>_<field>`（下标在字段名**中间**），规则对不上。
   若 Formality 自己的签名/拓扑匹配补不上，会出现 unmatched DFF。
   **那时的处置是**：另立一次带 `fm_pins.tcl` 的证明并另写一版预登记，
   钉点按 `mipriosReg_<g>_<field>` ↔ `u_core/mipriosReg_<field>_reg[<g>]` 逐条机械对位，
   计数用 `set_user_match` 的**返回值**（不用 `catch`，判据 P4），
   数目对不上就 `error` 中止。**不会**因为"钉了就绿"而略过这一步的记录。
   标量寄存器（21 + 5 个）已经沿用 golden 叶名，预期靠名字直接配上，不需要钉点。
2. **规约树形状**：重写用的是 `min2(min2(a,b),min2(c,d))` 的平衡树，与 Chisel
   `minSelect` 的递归形状一致。若形状记错，因为"两边 greaterThan255 都为 1 → 全零"
   这条路径的存在，结果会真的不同 —— 那会表现为 failing，不是 unmatched。
3. **规模**：闭包约 504 个触发器 + 578 个比较点，属"叶子"档，
   预计内存接近 `fm.log` 的 867 MB 地板值，不需要独占串行。

---

## 5. 实测（FM 跑完后追加，不改上面任何一行）

（待填）

### 5.1 第一跑（`FM_MERGE_DUP` 未设 → `fm_eq.tcl` 默认 `true`）—— **FAILED**

`run_proof.sh` rc=2，证据 `evidence/08a85f26dc67/InterruptFilter/`：

```
FAILED  {"passing": 145, "failing": 20, "unverified": 258, "unmatched": 10,
         "failing_matched": 20, "blackbox_out": 0, "constant_reg": 2,
         "native": "FAILED", "unmatched_ref": 10, "unmatched_impl": 7}
```

**预测 578 vs 实测 423 个已配对比较点（145+20+258），差 -155。对不上，先报差再解释。**

| 预测 | 实测（第一跑） |
|---|---|
| passing 578 | passing 145 / failing 20 / unverified 258 |
| unmatched 0 | unmatched 10(ref) / 7(impl) |

`failing: 20` 是截断值（`verification_failing_point_limit` 默认 20，撞到就停，
剩下的全计 unverified）。加 `FM_FAILING_LIMIT=0` 重跑一次**诊断跑**，
拿到完整数字：**383 passing / 40 failing / 0 unverified**，
40 个失败点 = `failing.rpt`（本目录 `fm_work/InterruptFilter/failing.rpt`）：

| 失败点 | 个数 |
|---|---|
| `io_out_stopi_IID[0..5]` / `io_out_stopi_IPRIO[0..7]` | 14 |
| `io_out_vstopi_IID[0..5]` / `io_out_vstopi_IPRIO[0..7]` | 14 |
| `intrVecReg_reg[0..5]` / `irToHSReg` / `irToVSReg` | 8 |
| `io_out_interruptVec_bits[6]` `[7]` / `io_out_interruptVec_valid` | 3 |
| `delayedIntrVec_delay/REG_1_reg[6]`（ref DFF0X vs impl DFFX） | 1 |

**`io_out_mtopi_*` 一个都没失败。**

### 5.2 为什么：合并导致的不对称孤儿点，不是逻辑差异

`unmatched.rpt` 里 17 个孤儿点**全部**落在 hs/hv 两族的第 6/7 组：
ref 侧 `hsipriosReg_6_enable` / `hsipriosReg_7_enable` / `hvipriosReg_6_enable` /
`hvipriosReg_7_enable` / `hvipriosReg_7_idx[3]` / `hvipriosReg_7_isZero`；
impl 侧 `hsipriosReg_enable[6]` / `[7]` / `hsipriosReg_idx[6][5]` / `[7][5]` /
`hvipriosReg_enable[6]` / `[7]` / `hvipriosReg_idx[6][5]`。miprios 一个都没有。

机理：第 6 组是槽位 48..55，六位 idx 的 bit5/bit4 在这 8 个值上恒为 1；
第 7 组是槽位 56..60，idx 的 bit5/bit4/bit3 恒为 1。而"整组一个都没使能"时
条目归零（idx 也归零）。于是 **idx 高位 ≡ enable**，是货真价实的重复寄存器。
`verification_merge_duplicated_registers=true` 把它们合并，两侧各自留下
**不同的幸存者名字**（`matched.rpt` 里 ref 的 `hsipriosReg_6_idx_reg[3]`/`[5]`
根本不在配对表里，impl 的 `hsipriosReg_idx_reg[6][5]` 却还在），
配对表一乱，依赖这些状态的输出锥就整片判不等。
miprios 族没这个问题，因为 mip 没有 ≥14 的端口，第 6/7 组整组恒不使能。

### 5.3 独立观测手段：把两侧寄存器每拍强制成同一组随机值

按 CONVENTIONS「当 FM 的配对可疑时，换一个独立的观测手段」，做了一个
**寄存器扰动 tb**（在 scratchpad，不进库）：每拍 `force` 两侧全部 **123 个 / 439 位**
流水寄存器为同一组随机值（数目与位数正好等于 golden 的寄存器普查结果），
再逐拍比 13 个输出 —— 这正是 FM「寄存器是自由变量」的语义。

结果：`checks=260000 errors=0`。

也就是说：**在任意寄存器状态下两侧输出函数都相同**，第一跑那 40 个失败点
来自配对，不是逻辑。

---

## 6. 第二跑预登记（`FM_MERGE_DUP=false`）

改动**只有一处**：`verif/ut/InterruptFilter/Makefile` 增加 `FM_MERGE_DUP = false`，
RTL 一个字节没动。这正是 `scripts/fm_eq.tcl` 里那条经验注记描述的症状与处置，
且它是**加强不是放宽**（不黑盒、不跳点、不约束 ref，比较点只增不减）。

预测（跑之前写死）：

| 项 | 预测值 |
|---|---|
| passing | **578** = 闭包触发器 504 位 + 顶层 output 74 位 |
| failing | 0 |
| unverified | 0 |
| unmatched | 0（ref）/ 0（impl） |
| 黑盒 | 0 |
| unread | 0 |
| verdict | `SIGNOFF_PASS`，但按 §2 仍记 **条件性证明 / UNCHANGED_GOLDEN_DEP** |

第一跑的 423 个点之所以少于 578，就是被合并吃掉的那些重复寄存器；关掉合并后
应当回到模型值。**若实测不是 578，照样先报差，不事后改模型。**

### 6.1 第二跑实测（`FM_MERGE_DUP=false`，commit `55468572`）—— native SUCCEEDED / failing 0，但 PARTIAL

证据 `evidence/55468572146b/InterruptFilter/`：

```
PARTIAL {"passing": 440, "failing": 0, "unverified": null, "unmatched": 85,
         "aborted": null, "blackbox_out": 0, "constant_reg": 53,
         "native": "SUCCEEDED", "dont_verify": false,
         "reason": "strict_unmatched!=0", "unmatched_ref": 85, "unmatched_impl": 85}
```

Formality 结果表：

```
Passing (equivalent)   Port 74   DFF 366   TOTAL 440
Failing                Port  0   DFF   0   TOTAL   0
Not Compared  Constant reg      DFF  53
85(85) Unmatched reference(implementation) compare points
```

**预测 578 vs 实测 passing 440，差 -138。先报差。**

### 6.2 差在哪：模型算的是「比较点总数」，不是「passing」

把三项加起来：

```
DFF:  366 passing + 85 unmatched + 53 constant(Not Compared) = 504
Port: 74 passing                                             =  74
合计                                                          = 578
```

**578 一位不差**，等于闭包触发器 504 位 + 顶层 output 74 位 —— 模型算对了
**比较点的全集**。§3/§6 把它直接写成 `passing` 是我的错：
Formality 把两侧都恒为常量的寄存器归进 `Not Compared / Constant reg`，
它们永远不会变成 passing；未配对的点也不在 passing 里。
所以模型的正确读法是

> passing ≤ 闭包触发器位 + 顶层 output 位，缺口 = 常量寄存器 + 未配对点。

第一跑（merge_dup=true）的 423 也能对上同一本账：合并把重复寄存器吃掉了一批。

### 6.3 那 85(85) 是什么：M 级恒零组的常零寄存器，两侧一一对得上

85 个孤儿点**全部**落在 `mipriosReg` 的第 0/1/2/4/5/6/7 组：
mip 只有 11 个端口（中断号 1..13），没有任何 ≥14 的位，于是这些组里每个条目的
`enable` 恒 0、整条目归零 —— 两侧都是常零寄存器（ref 报 `DFF0X`，impl 报 `DFF0`）。
常零寄存器的次态是常量，**签名分析没有区分度**；名字又对不上：

```
ref   r:/WORK/InterruptFilter/mipriosReg_0_idx_reg[3]          (firtool 展平 Vec)
impl  i:/WORK/InterruptFilter/u_core/mipriosReg_idx_reg[0][3]  (可读核按 SoA 数组存)
```

`fm_eq.tcl` 自带的 `auto_match_flattened_arrays` 处理的是
`name_i_j_reg` ↔ `name_reg[i][j]`（下标在**末尾**），这里下标在**字段名中间**，
规则对不上 —— 这正是 §4 风险 1 写下的那条，按当时写好的处置办。

离线核对双射（不是"数目一样就认"）：把两侧 85 个路径各自规约成
`(族, 组号, 字段, 位号)` 的 key，两个 key 集合**完全相等**，差集两边都为空。

---

## 7. 第三跑预登记（加 `verif/ut/InterruptFilter/fm_pins.tcl`）

改动只有两处，RTL 逻辑一个字节没动（只加了一段注释，记录 §1 里那条
「两边 >255 」路径结构上不可达的实测发现）：

1. 新增 `verif/ut/InterruptFilter/fm_pins.tcl` —— 只 `set_user_match` 消名字差，
   现场用 `report_unmatched_points` discover、按 `(族,组,字段,位)` 规约核对双射、
   用 `set_user_match` 的**返回值**计数（不是 `catch`，判据 P4）、任何一步不符合就
   `error` 中止。已过 `test_fm_pins_wellformed.py`（该文件行 `ok`）。
2. UT 激励与变异负测的改进（不进证明闭包）。

预测（跑之前写死）：

| 项 | 预测值 |
|---|---|
| passing | **525** = 440 + 85（钉上的孤儿点全部转成 passing） |
| failing | 0 |
| unverified | 0 |
| unmatched | 0（ref）/ 0（impl） |
| Not Compared / Constant reg | 53（不变 —— 钉点不改变常量寄存器的归类） |
| 比较点全集 | 525 + 53 = **578**，仍等于模型值 |
| 黑盒 | 0 |
| verdict | `SIGNOFF_PASS`，但按 §2 仍记 **条件性证明 / UNCHANGED_GOLDEN_DEP** |

★判据是 passing 必须 440 → 525（恰好 +85）★：passing 不增而 unmatched 归 0
就是点被吞掉，不算过。

---

## 8. 登记方式更正：改用 `scripts/fm_predict.py`（集成者 0920 更正）

集成者更正了一条我一直当成无条件的前提：

> 模型 `passing = 闭包触发器位 + 顶层输出端口位` **只在
> `verification_merge_duplicated_registers = false` 时成立**。merge 打开时
> FM 把重复寄存器合并成一个比较点，低多少**不是能从 golden 静态算出来的量**。

**本目标的两跑正好是这条更正的一个独立实测**：

| 跑 | merge_dup | 模型 | 实测比较点全集 | 能不能静态指认 |
|---|---|---|---|---|
| 第一跑 | **true** | 578 | 423（+17 孤儿） | ★指认不了★ —— 合并吃掉多少取决于重复结构 |
| 第二跑 | **false** | 578 | **578**（440 passing + 85 孤儿 + 53 constant） | 逐位对得上 |

工具（`scripts/fm_predict.py` + `scripts/fm_passing_model.py`）独立算出
`expected=578 (regs 504 + outs 74)`，与本文件 §3 手算逐位一致，
并因 Makefile 写了 `FM_MERGE_DUP = false` 判为「模型适用」。

登记已落 `docs/fm_predictions/InterruptFilter.json` 并**在签核跑之前提交**
（工具的 `check` 只认 git HEAD 里的登记，且要求登记 commit 是 receipt 里
`impl_commit` 的祖先 —— 跑完再改登记不起作用）。

对账口径（工具定义，不是我手填）：

```
差额   = expected - passing
可指认 = constant_reg + unread      （两者都从 receipt 读）
绿 ⟺ 差额 == 可指认
```

本目标的预期对账：`578 - 525 = 53`，可指认 `constant_reg 53 + unread 0 = 53` → 相等。

★另一条更正一并照办★：数 `fm.log` 里的错误一律行首锚定 `grep -cE "^ *Error:"` ——
`fm_shell` 会把入口 Tcl **逐行回显（含注释）**，而 `fm_eq.tcl` 的注释里就写着
`FM-036`，按裸关键字数必然误报。本目录所有"错误行数"口径都用行首锚定版。

## 9. 第四跑（签核跑）预登记

第三跑（commit `71476fde`）是**验钉点文件能不能用**的一跑，它早于本次登记，
按工具的"登记必须早于证明"判据**不可用于对账**，只当诊断。
签核跑是加上本次登记之后的第四跑，预测与 §7 完全相同：

| 项 | 预测值 |
|---|---|
| passing | **525** |
| failing / unverified / unmatched / 黑盒 / unread | 全 0 |
| Not Compared / Constant reg | 53 |
| `fm_predict.py check` | 差 53 = 可指认 53 → 绿 |
| verdict | `SIGNOFF_PASS`，但按 §2 仍记 **条件性证明 / UNCHANGED_GOLDEN_DEP** |

---

## 10. 第三跑实测（加 `fm_pins.tcl`，commit `71476fde`）—— native SUCCEEDED，但 **§7 的判据没达成**

`run_proof.sh` rc=0，证据 `evidence/71476fde0e6c/InterruptFilter/`：

```
verdict: SUCCEEDED
{"passing": 440, "failing": 0, "unverified": null, "unmatched": 0,
 "unread": null, "blackbox_out": 0, "dont_verify": false, "elab147": false,
 "constant_reg": 138, "native": "SUCCEEDED", "unmatched_ref": 0, "unmatched_impl": 0}
Passing (equivalent)   Port 74   DFF 366   TOTAL 440
Failing                                     TOTAL   0
Not Compared  Constant reg      DFF 138
fm.log 行首锚定错误行数 grep -cE "^ *Error:" = 0
IF_PIN: pinned 85 pair(s); orphans 85; structural inventory upper bound 378
```

**★§7 写死的判据是「passing 必须 440 → 525（恰好 +85）」，没达成：passing 还是 440。★**
先报没达成，再解释。

### 10.1 那 85 点去哪了：被 Formality 归进 `Constant reg / Not Compared`

`Constant reg` 从 **53 变成 138**，正好 `53 + 85 = 138`。也就是说钉点把这 85 点
从「未配对」变成了「已配对、但两侧都是常量 -> 不比较」，**没有变成 passing**。

我在 §7 写"钉上之后 FM 真去证它们"是**错的**：这 85 点不是 IBuffer 那种
"matched-but-unread"（开 vmucp 就会去证），而是**两侧都恒为常量**的寄存器，
Formality 对常量寄存器一律不产生比较内容。

### 10.2 为什么我仍然认为这次证明是成立的（判断依据，交给复核者裁）

不是"差不多"，是三条可核对的事实：

1. **两侧的常量值是各自独立测出来的，不是假设的**：第二跑（未钉点）的
   `unmatched.rpt` 把两侧分别定了型 —— ref 侧 85 个全是 `DFF0X`（常 0/X），
   impl 侧 85 个全是 `DFF0`（常 0）。**同一个常量 0**，两份证据互不依赖。
2. **常量若不同会在下游炸**：这 85 个寄存器都喂进第二级规约树，最终落到
   `io_out_*topi_*` 与 `intrVecReg`。若两侧常量不同，那 440 个已比较点里必有失败。
   实测 failing = 0。
3. **和 FM 自己配上的那 53 个是同一种待遇**：那 53 个是 Formality **自己**按名字
   配上的常量寄存器对，同样归 `Not Compared`。钉点只消掉名字差，让剩下 85 个
   与那 53 个站到同一条线上 —— 是**一致**，不是**例外**。

反过来也说清楚**这次证明没覆盖什么**：这 85 位没有逐点的等价判决，
它们的等价性是**由下游 440 个已比较点传递覆盖**的。

### 10.3 对账（工具口径）

```
expected 578 - passing 440 = 138
可指认 = constant_reg 138 + unread 0 = 138
差额 == 可指认 -> 绿（"差额被指认"）
```

★但第三跑**不能用来对账**★：登记 commit `38b51ce2` 晚于本跑的 `impl_commit`
`71476fde`，`fm_predict.py check` 会判「登记不早于该次证明」。第三跑只当诊断跑。

---

## 11. 第四跑（签核跑）预登记 —— 修正 §7/§9 的错误预测

改动只有一处：`fm_pins.tcl` 的**运行期 `puts`/`error` 文案改成纯 ASCII**
（CONVENTIONS「进 fm.log 的字必须是 ASCII」；第三跑里那行 `IF_PIN` 在 fm.log 里
是一串 `?`，读不出数字）。判据逻辑、钉点集合、RTL 一个字节没动。

修正后的预测（跑之前写死）：

| 项 | 预测值 | 与 §7/§9 的差别 |
|---|---|---|
| passing | **440** | §7 写的 525 是错的，见 §10.1 |
| Not Compared / Constant reg | **138** | §7 写的 53 是错的 |
| failing / unverified / unmatched / 黑盒 / unread / dont_verify | 全 0 | 不变 |
| 比较点全集 | 440 + 138 = **578** | 不变，仍等于模型值 |
| `fm_predict.py check` | 差 138 = 可指认 138 → 绿 | — |
| verdict | `SUCCEEDED`，但按 §2 仍记 **条件性证明 / UNCHANGED_GOLDEN_DEP** | — |

★登记文件 `docs/fm_predictions/InterruptFilter.json` 里的 `expected=578` 自始至终
没有动过，也不会动 —— 工具对账的是它，不是我这段叙述。★

---

## 12. 第四跑（签核跑）实测 —— 与 §11 逐项相符

证据 `evidence/3e3ea3700d11/InterruptFilter/`，`run_proof.sh` rc=0：

```
verdict: SUCCEEDED          impl_commit 3e3ea3700d11
{"passing": 440, "failing": 0, "unverified": null, "unmatched": 0,
 "unread": null, "blackbox_out": 0, "dont_verify": false, "elab147": false,
 "constant_reg": 138, "native": "SUCCEEDED", "unmatched_ref": 0, "unmatched_impl": 0}
Passing (equivalent)   Port 74   DFF 366   TOTAL 440
Failing                                     TOTAL   0
Not Compared  Constant reg      DFF 138
IF_PIN: pinned 85 pair(s); orphans 85; structural inventory upper bound 378
fm.log 行首锚定错误行数  grep -cE "^ *Error:"  = 0
```

| 项 | §11 预测 | 实测 | 差 |
|---|---|---|---|
| passing | 440 | **440** | 0 |
| Constant reg | 138 | **138** | 0 |
| failing / unverified / unmatched / 黑盒 / unread / dont_verify | 0 | **0** | 0 |
| 比较点全集 | 578 | **578** | 0 |

工具对账（`python3 scripts/fm_predict.py check InterruptFilter`，rc=0）：

```
target                        预期      实测      差     可指认  判决
InterruptFilter              578     440    138     138  差额被指认（constant_reg 138 + unread 0）
结论：全部对上
```

登记 commit `38b51ce2` 是 `impl_commit 3e3ea370` 的祖先（工具已校验），
即预期是在这次证明**之前**进的库。

### 12.1 四跑一览（把"预测对不上"的两次也留在表里）

| 跑 | commit | 配置 | 结果 | 预测 vs 实测 |
|---|---|---|---|---|
| 1 | `08a85f26` | merge_dup=true（默认） | **FAILED** 20F/258U/10(7)unmatched | 预测 578 passing，实测已配对点 423 —— ★差 -155，静态指认不了★ |
| 2 | `55468572` | merge_dup=false | native SUCCEEDED / failing 0，但 PARTIAL（85(85) unmatched） | 预测 578 passing，实测 440 —— ★模型算的是比较点全集，不是 passing★ |
| 3 | `71476fde` | + fm_pins.tcl | SUCCEEDED（unmatched 归 0） | 预测 passing 440→525，★没达成★：85 点变成 matched-constant，passing 不变 |
| 4 | `3e3ea370` | + 钉点文案改 ASCII | **SUCCEEDED** | §11 修正后的预测逐项相符，差全为 0 |

第 1、3 两跑的预测都没对上，原因分别写在 §5.2/§6.2 与 §10.1。
第 2 跑正好是集成者那条更正（模型只在 merge_dup=false 时成立）的一个独立实测。

---

## 13. 子依赖闭合升级：impl 侧换成 main 上的 DelayN 重写件（第五跑预登记）

集成者裁定 3：DelayN lane 已合入 main（`80617800`），18 个变体里**包含
`DelayN_17` 与 `DelayN_208`**。于是 impl 闭包升级：

| 侧 | 升级前（第 1~4 跑） | 升级后（第 5 跑） |
|---|---|---|
| ref | golden `InterruptFilter.sv` + golden `DelayN_17.sv` + golden `DelayN_208.sv` | **不变** |
| impl | 重写 `InterruptFilter.sv` + **golden** `DelayN_17.sv` + **golden** `DelayN_208.sv` | 重写 `InterruptFilter.sv` + **重写** `rtl/common/DelayN_17.sv` + **重写** `rtl/common/DelayN_208.sv` + `xs_DelayN_core.sv` |

两侧从此是**两套不同的字节**，这两个 child 对本 target 不再零信息量，
`UNCHANGED_GOLDEN_DEP` / 条件性证明随之摘掉 —— **但只有第 5 跑真过了才摘**，
不许只改台账不重跑。

### 13.1 预测（跑之前写死）

ref 侧一个字节没动，所以**比较点全集不变**：模型仍是
`504（闭包触发器位）+ 74（顶层 output 位）= 578`，
`docs/fm_predictions/InterruptFilter.json` 里的 `expected=578` **不需要改**
（它是从 golden 闭包算的），登记 commit `38b51ce2` 仍是新 `impl_commit` 的祖先。

| 项 | 预测值 |
|---|---|
| passing | **440** |
| Not Compared / Constant reg | **138** |
| failing / unverified / unmatched / 黑盒 / unread / dont_verify | 全 0 |
| 比较点全集 | 440 + 138 = **578** |
| `fm_predict.py check` | 差 138 = 可指认 138 → 绿 |
| verdict | `SUCCEEDED`，且这次是**子依赖闭合的完整签核**，不再是条件性证明 |

### 13.2 ★这一跑新增的风险：DelayN 链的寄存器叶名变了★

升级前两侧的延迟链是同一份 golden 字节，逐字同名必然配上。升级后：

```
ref   r:/WORK/InterruptFilter/delayedDebugIntr_delay/REG_reg      (golden 的 REG / REG_1..REG_4)
impl  i:/WORK/InterruptFilter/u_core/delayedDebugIntr_delay/u_core/stage_reg[0]   (重写核的 stage[0..4])
```

这 5 实例 × 5 位 + 1 实例 × 5×8 位 = **65 位**名字对不上。
和 §6.3 那 85 点不同的是：**这些是非常量寄存器**（真载荷在流动），
签名分析对移位链有区分度，**预期 FM 自己能配上**。
若配不上会表现为 `unmatched != 0`（不是 failing），那时的处置与 §7 同：
按 `REG_<k>` ↔ `u_core/stage_reg[<k>]` 的结构规则扩 `fm_pins.tcl`，另立一次预登记。

### 13.3 一条如实记录：`check_closure_symmetry.py` 对本 target 报 ERROR，且**不是**本 target 的问题

升级后 `python3 scripts/check_closure_symmetry.py --only InterruptFilter` 报

```
[ERROR] InterruptFilter (signoff-strict)  elab_error:未知标识符 io_in in '$bits( {io_in})'
```

原因是那个轻量静态 elaborator（`verif/allow_gen/sv_elab.py`）**算不了
localparam 里的 `$bits(端口拼接)`**，而 DelayN 家族的薄 wrapper 正是用它做位宽自检的。
现查：`--only DelayN` 下 **18 个 DelayN 目标全部报同一个 elab_error**，
包括 DelayN lane 已签核的那些。也就是说这是**检查器的既有局限**，不是闭包不对称，
也不是我引入的新缺陷 —— 我只是把 DelayN 拉进了自己的闭包才碰到它。

两点补充：
1. `scripts/check_closure_symmetry.py` **不在 `gate_all.sh` 里**（grep 计数 0），不会把闸判红；
2. 对称性的**权威判据**是 FM 实跑导出的 `black_boxes.rpt`（`fm_verdict.py` 用它判
   `assembly_bbox_not_symmetric`）。第 5 跑跑完会把 `blackbox_out` 与该文件一并核对。

---

## 14. 第五跑（子依赖闭合后的签核跑）实测 —— `UNCHANGED_GOLDEN_DEP` 摘除

★口径说明★：本 lane 被 HTTP 403 打断过一次。打断前曾有一跑落在
`evidence/e8d0f728dda2/`，但「那一跑有没有出结果、结果是什么」在版本库里没有依据，
**按集成者要求全部重跑，下面的数字一律来自打断后的重跑，不引用打断前的任何数字**。

证据 `evidence/5254ac5bde44/InterruptFilter/`，`run_proof.sh` rc=0：

```
verdict: SUCCEEDED          impl_commit 5254ac5bde44
{"passing": 440, "failing": 0, "unverified": null, "unmatched": 0,
 "unread": null, "blackbox_out": 0, "dont_verify": false, "elab147": false,
 "constant_reg": 138, "native": "SUCCEEDED", "unmatched_ref": 0, "unmatched_impl": 0}
Passing (equivalent)   Port 74   DFF 366   TOTAL 440
Failing                                     TOTAL   0
Not Compared  Constant reg      DFF 138
IF_PIN: pinned 85 pair(s); orphans 85; structural inventory upper bound 378
grep -cE "^ *Error:" fm.log = 0
```

impl 闭包（从 fm.log 现读，确认 golden 的 DelayN **不在 impl 侧**）：

```
.../rtl/backend/InterruptFilter.sv
.../rtl/common/xs_DelayN_core.sv
.../rtl/common/DelayN_17.sv
.../rtl/common/DelayN_208.sv
```

| 项 | §13.1 预测 | 实测 | 差 |
|---|---|---|---|
| passing | 440 | **440** | 0 |
| Constant reg | 138 | **138** | 0 |
| failing / unverified / unmatched / 黑盒 / unread / dont_verify | 0 | **0** | 0 |
| 比较点全集 | 578 | **578** | 0 |

`python3 scripts/fm_predict.py check InterruptFilter` → rc=0：
`预期 578 / 实测 440 / 差 138 / 可指认 138（constant_reg 138 + unread 0）→ 差额被指认`。

§13.2 担心的风险**没有发生**：DelayN 链那 65 位寄存器叶名虽然从 golden 的
`REG_<k>` 变成重写核的 `u_core/stage_reg[<k>]`，FM 自己就把它们配上了，
`unmatched` 仍是 0(0)，不需要为它们扩钉点。

### 14.1 ★自证「没有任何东西被黑盒掉」★

`black_boxes.rpt` 里有一条 `e *  xs_DelayN_core  Instances : 0`。
这条**不是**真黑盒，两条独立证据：

1. **闭包触发器位逐位对上**：`scripts/fm_predict.py model InterruptFilter` 算出
   `regs 504`（= InterruptFilter 439 + DelayN_17×5 的 25 + DelayN_208 的 40）。
   实测 `366 passing DFF + 138 Constant reg DFF = 504`。
   ★若 `xs_DelayN_core` 真被黑盒，它那 65 位就会从比较点里消失，只剩 439。★
2. **同形态出现在别人已签核的证据里**（这条我按要求**自己复核了一遍**，不是引用）：
   `/home/eda/xs-env/xs-v2-sv/evidence/eee60602a12f/DelayN_17/` 是 DelayN lane
   自己的 `signoff-strict` receipt，`verdict SUCCEEDED / blackbox_out 0`，
   而它的 `black_boxes.rpt` 里有 **18 条 entry、每一条都是 `Instances : 0`**
   （逐条解析过，没有一条 `Instances > 0`）。
   这些是被读进库但在该顶层没有实例的设计条目，Formality 照例列出来。

### 14.2 结论：条件性证明升级为完整签核

| | 升级前（跑 1~4） | 升级后（本跑） |
|---|---|---|
| `DelayN_17` / `DelayN_208` 在 impl 侧 | golden 字节 | **重写件** |
| 本 target 对这两个 child 的信息量 | 零 | **真比对** |
| 台账 | 条件性证明 · `UNCHANGED_GOLDEN_DEP` / 子依赖未闭合 | ★`UNCHANGED_GOLDEN_DEP` **摘除**★ |

§2 那一节的结论边界**到此失效**，保留在文件里是为了留下当时的前提，
**不要再引用它来描述当前状态**。

### 14.3 同一 commit 上的另外两项验收（也都是打断后重跑的）

- **UT**：3 seed × {`+vcs+initreg+0`,`+random`} 共 **6/6 轮全过**，
  每轮 200k 拍 / 2.6M 次比较 / `errors=0`（升级后的闭包，golden 的 DelayN 只在对照侧）。
- **变异负测**：`mutants.py` **10/10 全被抓到**，基线 `checks=260000 errors=0`。

### 14.4 ★一次自己造成的事故：两跑 mutants 共用固定名目录，互相拆台★

升级后第一次跑变异负测时，基线就报失配（`io_out_irToVS`），一度像是真缺陷。
查下来是**我自己**在上一跑还活着的时候又起了一跑，两者共用固定名的
`neg_build/`：一边 `prepare()` 的 `rmtree` 把另一边跑到一半的树删掉
（那边因此报「M6 编译/运行失败」），另一边 `restore()` 还没跑完，
这边就把**对方注入的 M10 变异**当成自己的基线量了 —— 失配签名正是 M10 的。

★那两次跑的结论都不作数★，已重跑（见 §14.3）。
`mutants.py` 已改成 `BUILD = neg_build/run-<pid>`，只删自己那一跑的目录、
绝不碰 `neg_build` 本身 —— 与 CONVENTIONS ★共享 scratchpad 里禁止 `rm -rf` 语义名★
是同一条判据：破坏性操作的作用域必须由**自己造的唯一标识**界定。
（仍放在 `neg_build/` 之下，`.gitignore` 的 `verif/ut/*/neg_build/` 继续覆盖，已实测。）
