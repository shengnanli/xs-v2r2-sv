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
