# Sbuffer FM 跑前预登记（第二版 · 2026-09-20）

**登记时间点**：`verif/ut/Sbuffer/Makefile` 已按 codex 0168 裁定改指，
UT 六轮已在**改指后的字节**上重跑（见下），**本配置的 FM 一次都还没跑**。

---

## 0. 为什么作废第一版

第一版（`FM_PREDICTION.md@00f8408`）登记的配置是：

| 项 | 第一版 |
|---|---|
| impl | `rtl/memblock/Sbuffer.sv` + **同一组** golden 子模块文件（`RTL_GOLDEN_DEPS`） |
| ref | golden `Sbuffer.sv` + `SbufferData.sv` + `StorePfWrapper.sv` + `Serializer.sv` |

`SbufferData.sv` / `StorePfWrapper.sv` / `Serializer.sv` **两侧喂同一份字节**。
FM 对这三块必判等价 —— 那不是"证明"，是白送。第一版自己也把这件事写在第 11 行
（「impl = 重写件 + **同一组** golden 子模块文件」），只是把它当成了配置说明，
没当成缺陷。

`SbufferData` 已有重写件（`rtl/memblock/SbufferData.sv`，4374 行，
`verif/ut/SbufferData/` 有自己的 UT 目标），所以它**必须**走 impl 侧。
改指之后 impl 闭包变了、比较点的**配对机制**变了（见 §3），
第一版的每一条预测都不再绑当前配置，整份作废。

---

## 1. 本次证明配置

| 项 | 值 |
|---|---|
| ref | golden `Sbuffer.sv` + `SbufferData.sv` + `StorePfWrapper.sv` + `Serializer.sv` |
| impl | `rtl/memblock/Sbuffer.sv` + **`rtl/memblock/SbufferData.sv`（重写件）** + golden `StorePfWrapper.sv` + golden `Serializer.sv` |
| FM_MODE | `signoff-strict`（Makefile 未设 FM_MODE） |
| FM_ALLOWLIST | 0 |
| FM_MERGE_DUP | 未设 → `fm_eq.tcl` 默认 `true` |
| vmucp | false（未设） |
| 黑盒 | **0 个**（`check_closure_symmetry.py --only Sbuffer` → `SYMMETRIC=1`，rc=0） |
| `verif/allow/Sbuffer.json` | 不存在 |
| `verif/dead_ref/Sbuffer.json` | 不存在 |
| `fm_pins.tcl` / `fm_map/` | 不存在 |

输入字节（`sha256`，全 64 位）：

```
80f492fc32ea12776de9936b8ec1a84c246b1fcb0740541362d85bcdbd2495be  rtl/memblock/Sbuffer.sv
df1ec7f762638157da7a1063d566b67c89b9afd9097b7b4e5aed1c6c8937d98c  rtl/memblock/SbufferData.sv
859d8f9928ccb19ca0be4203378e3b10f2a543b9be7b0c773d3ff0c6a9921e13  verif/ut/Sbuffer/Makefile
bc04b7f72e782b57a1ae96e414a3610fbcac48e5555cf3cc0f6f5a4dfe73d793  verif/ut/Sbuffer/tb.sv
2d645c1ce603f665a0b0b6dca18cdf81b6804b750304ab4db726817698ae0774  G1/golden-rtl/Sbuffer.sv
1656555c4606d4a4a00f90d9b5b95bc66390172ba7cbef68b776eb2242a3cbc2  G1/golden-rtl/SbufferData.sv
6668f5b100d95192239c6ff430d888b037c4e2bf43324afdd50cc01e9b8277fc  G1/golden-rtl/StorePfWrapper.sv
e52772ba1969e9d9735b19a93cf6d39de95b68a5b7f82c00892da0dae8243456  G1/golden-rtl/Serializer.sv
```

G1 canonical：`G1-a4ea14f2ddf612bb4ad023d26a2ca1bf33eddcaebe470b0c620e9fba0e7afcf0`

复跑命令：

```
cd /home/eda/xs-env/wt-sbuffer2 && scripts/run_proof.sh Sbuffer Sbuffer
```

---

## 2. ★结论边界（先写在预测前面，免得被结论盖过去）★

**无论本次 FM 跑成什么样，完整目标 `Sbuffer` 仍是 UNPROVEN。**

| child | impl 侧用的是 | 本 target 对它的信息量 | 台账应记 |
|---|---|---|---|
| `SbufferData` | **重写件** `rtl/memblock/SbufferData.sv` | 真比对 | 仍 `REWRITTEN/UNPROVEN` —— 它**自己的** FM 目标还没跑过（`evidence/` 下无 `SbufferData` receipt） |
| `StorePfWrapper` | **golden 字节** | **零** | `MISSING/UNPROVEN` · `UNCHANGED_GOLDEN_DEP` |
| `Serializer` | **golden 字节** | **零** | `MISSING/UNPROVEN` · `UNCHANGED_GOLDEN_DEP` |

所以本次 FM 若绿，它证明的是：

> 在「`StorePfWrapper` / `Serializer` 取 golden 定义」这个**前提**下，
> 重写的 `Sbuffer` 顶层 glue + 重写的 `SbufferData` 合起来，与 golden 的
> `Sbuffer` + `SbufferData` + `StorePfWrapper` + `Serializer` 等价。

**不许**据此把 `Sbuffer` 记 `PROVEN_DIRECT`，也**不许**把
`StorePfWrapper` / `Serializer` 记成"已证"。

### 为什么 `StorePfWrapper` / `Serializer` 选"两侧白盒"而不是"两侧黑盒"

codex 0168 给了两条路，选**两侧白盒展开真实 child 行为**这条。理由是这两个模块在
KunminghuV2Config 下已被 firtool **DCE 成没有任何功能端口的空壳**：

```
module StorePfWrapper(input clock, input reset);   // 端口表只有这两个
  Serializer serializer (.clock(clock), .reset(reset));
endmodule

module Serializer(input clock, input reset);       // 同样只有这两个
  reg enqPtrExt_0_flag; reg [3:0] enqPtrExt_0_value;   // 5 bit，无任何 fanout 到端口
  ...
endmodule
```

这棵子树对 `Sbuffer` 的**任何输出都不可达**。于是：

- **黑盒配对买不到东西**：一个零输出的黑盒不向父级引入任何自由变量，
  遮住的也只是 5 个到不了外面的 bit；代价却是 `unresolved_blackbox` 非零、
  判决挂在两个未签核 child 上。
- **白盒展开不吃亏**：glue（`prefetcher` 实例存在性 + clock/reset 接线）被真的比出来，
  `Serializer` 那 5 bit 两侧配对受验，一处不遮。且**不扩大黑盒**，符合裁定的偏好。

这条**不是**"两侧同一 golden 文件所以可以记 PROVEN_DIRECT"——恰恰相反，
正因为 impl 侧用的是 golden 字节，本 target 对它们零信息量，
所以它们被显式记成 `UNCHANGED_GOLDEN_DEP / 子依赖未闭合`。

---

## 3. 改指改变了什么（预测的依据）

**ref 侧一个字节都没变。** 变的只有 impl 侧的 `SbufferData` 从 golden 换成重写件。

比较点的**数量**由此**基本不变**，因为两者寄存器集合是 1:1 的：

| | golden `SbufferData` | 重写 `SbufferData` |
|---|---|---|
| 端口 | 2064 个（16 in / 2048 out） | **2064 个，逐个同名同宽同序**（`PORTLINT_ORDER=fail` 已过） |
| 存储 | `data_<e>_<v>_<b>` 8192 bit + `mask_*` 1024 bit + s1/s2 流水 4736 bit | 同容量，写成 packed 多维 `data[16][4][16][8]` / `mask` / `s2_*` |

变的是比较点的**配对机制**：

- 改指前：impl 的寄存器叫 `dataModule/data_0_0_0` —— 与 ref **逐字同名**，
  FM 按名匹配一把过（这正是"白送"的机制）。
- 改指后：impl 的寄存器在 `dataModule/u_core/data_reg[...]` 里，
  **按名匹配必然失败**，FM 只能走签名/拓扑匹配。

★这就是本次最可能出问题的地方，预登记在此，跑完不许改口。★

比较点数量的自下而上估算（golden 侧，`fm_eq.tcl` 未开 vmucp）：

| 来源 | bit |
|---|---|
| `Sbuffer` 自身寄存器（2058 条声明） | 13,509 |
| `SbufferData` 寄存器（2224 条声明） | 13,968 |
| `Serializer` 寄存器（2 条声明） | 5 |
| `Sbuffer` 顶层输出端口（130 个） | 2,849 |
| **朴素合计** | **30,331** |

`FM_MERGE_DUP=true` 会把输入逻辑相同的寄存器合并成一个比较点，`data_*` / `mask_*`
各有独立的写使能、合并空间不大；firtool 也可能已经消掉一部分常量寄存器。
故实测应落在朴素值**之下**、且不会低太多。

---

## 4. 预测（可证伪）

| # | 预测 | 依据 |
|---|---|---|
| P1 | native verdict = `SUCCEEDED` | UT 六轮全绿（§5）；改指前后 UT 都绿 |
| P2 | `failing` = 0 | 同上 |
| P3 | `unverified` = 0 | 无黑盒、无 dont_verify |
| P4 | unmatched 六类**全部** = 0 | **风险最高的一条**：impl 的 `SbufferData` 寄存器改名换层，按名匹配失效，必须靠签名/拓扑匹配兜住约 14k bit |
| P5 | 黑盒对数 = 0、`unresolved_blackbox` = 0 | 闭包对称（`check_closure_symmetry.py` rc=0，SYMMETRIC=1），两侧全白盒 |
| P6 | `unread_notcompared` = 0 | 重写核没有 golden 没有的寄存器 |
| P7 | 无 `dont_verify`、无 relaxed appvar、`allowlist=0` | 未设任何放宽开关，`verif/allow/Sbuffer.json` 不存在 |
| P8 | `passing` ∈ **[27,000, 30,400]** | §3 的 30,331 朴素值减去 merge_dup / DCE；上沿不超过朴素值 |
| P9 | ★`receipt.json` 的 `impl_closure` **恰好 4 条**：`rtl/memblock/Sbuffer.sv`(kind=repo)、`rtl/memblock/SbufferData.sv`(kind=repo)、`StorePfWrapper.sv`(kind=golden)、`Serializer.sv`(kind=golden)；**其中没有 `SbufferData.sv` kind=golden**★ | 这是"假绿已消掉"的**机器可核**判据，比任何数字都要紧 |
| P10 | `dirty` = false、`g1_canonical_id` = `G1-a4ea…7afcf0` | 走 `run_proof.sh`，detached clean worktree |
| P11 | `Maximum memory usage` > 1599 MB | 同基线里 `SbufferData` 单独跑是 1599 MB，本次是它 + Sbuffer 顶层 |

**对账规矩**：P1~P7、P9、P10 是硬判据，任意一条不符按 **fail** 报，不许事后放宽。
P8 落在区间外也按 fail 报 —— 那说明"比较点 = 匹配寄存器 bit + 顶层输出 bit"
这个模型与工具看到的不是一回事，必须查清楚。P11 只是量级参考，不作判据。

**P4 若不成立**（unmatched 非零）：那是**配对问题不是设计问题**，
处置是补 `fm_pins.tcl`（照 Rob 的做法用循环生成 `set_user_match`）或调匹配开关，
**不许**用 allowlist / dont_verify 盖过去，也不许因此把结论说成"已证"。

---

## 5. UT 重跑（改指后的字节）

改了闭包文件集，改指前的六轮证据不再绑当前字节，全部重跑。

编译（`make compile`，rc=0）实测例化链已经变成真对比：

```
derive_ut_impl: Sbuffer -> Sbuffer_xs
derive_ut_impl: SbufferData -> SbufferData_xs
--- portlint: 1 pass, 0 fail, 0 skip ---
9 modules: Sbuffer_xs / xs_SbufferData_core / SbufferData_xs / StorePfWrapper
           / Sbuffer / SbufferData / tb  (+2 package)
```

即 golden 侧 `Sbuffer` → `SbufferData`（golden），impl 侧 `Sbuffer_xs` →
`SbufferData_xs`（重写）。改指前 impl 侧那条边是指向 golden `SbufferData` 的。

六轮结果见 `UT_ROUND2.md`。

### ★`+vcs+initreg` 到底有没有改变待测状态（codex 0168 要求，实测）★

不能只看命令行里有那个词。用 UCLI 在 `1ps` 处直接读两侧的**无复位**存储：

```
cd verif/ut/Sbuffer
./simv +ntb_random_seed=<S> +vcs+initreg+<V> -ucli -do <脚本>
  脚本内容：run 1ps; get tb.u_g.dataModule.data_0_0_0; get tb.u_i.dataModule.u_core.data[0][0][0]
```

| `+ntb_random_seed` | `+vcs+initreg+` | golden `data_0_0_0` | impl `data[0][0][0]` |
|---|---|---|---|
| 1 | `0` | `00` | `00` |
| 1 | `1` | `ff` | `ff` |
| 1 | `random` | `ff` | `ff` |
| 1 | `12345` | `7a` | `ed` |
| 7 | `random` | `5a` | `bd` |
| 42 | `random` | `04` | `8a` |

**结论 1：initreg 确实在改变待测状态**（`00` / `ff` / 逐寄存器伪随机三种都观测到）。

**结论 2（新发现，值得写进 CONVENTIONS）：`+vcs+initreg+random` 的随机数取自
`+ntb_random_seed`** —— 仿真自己印了这一行：

```
Note-[VIUNRD] initreg using ntb_random_seed
  +vcs+initreg using seed from +ntb_random_seed=1 .
```

而 **`+ntb_random_seed=1` 是退化种子**：它让 `random` 那一轮把**所有**无复位位
初始化成全 1，**两侧完全相同**。也就是说 seed=1 的"random 轮"实际测的是
「全 1 上电」，不是随机上电 —— 它与 `+0` 轮仍是两个不同的初值模式，
不是白跑，但**不能叫"随机"**。seed 7 / 42 的 random 轮才是真随机，且两侧取值不同。

**结论 3：initreg 的扰动能传到被比较的输出**。用 tb 自带的 `+diag_cmp_now`
（跳过暖机窗口，从第 2 拍就开比较；该模式永不报 TEST PASSED，只作诊断）：

```
for sd in 1 7 42; do for ir in 0 random; do
  ./simv +ntb_random_seed=$sd +diag_cmp_now +vcs+initreg+$ir +ncycles=300 -l d_${sd}_${ir}.log
done; done
```

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` |
|---|---|---|
| 1 | checks=38610 errors=0 | checks=38610 errors=**0**（退化种子，两侧同为全 1） |
| 7 | checks=38610 errors=0 | checks=38610 errors=**30** |
| 42 | checks=38610 errors=0 | checks=38610 errors=**13** |

同一份 simv、同一组激励，**只改 initreg 取值**就让被比较的输出从 0 error 变成
30 / 13 error ⇒ initreg 不但改了内部寄存器，还改到了**比较边界上**。
（这些 error 是 tb 缺暖机造成的，不是 RTL 缺陷 —— 正式验收走暖机窗口，见 tb.sv:214。）

★顺带纠正 tb.sv:214 注释的一处措辞★：它说「在 `+vcs+initreg+random` 下两侧
各自抽到不同的上电值 ⇒ 必然不等」。**在 seed=1 下不成立**（两侧同为全 1）。
暖机窗口在 seed 7/42 下才是真正必需的。注释本身的结论（要暖机）没错，
理由只对 2/3 的种子成立。

---

# §6 对账：第一次真跑（FAILED，抓到真 bug）

跑法与产物：

```
PROOF_COMMIT=5c55add9ee20b50896595502345f718edaf00a69 \
  scripts/run_proof.sh Sbuffer Sbuffer
证据: evidence/5c55add9ee20/Sbuffer/{receipt.json,fm.log,unmatched.rpt,black_boxes.rpt,sidecar/}
run_id: Sbuffer-20260920T062127Z-5c55add     make rc=2（verdict FAILED）
Maximum memory usage 1777 MB / CPU 593.35 s / Elapsed 640 s
```

★注意 commit：`5c55add`（= 本 lane 自己修 `fm_eq.tcl` 之后）。在那之前用
`4648b23` 跑过一次，44 秒死在 `fm_eq.tcl` setup，**0 个比较点**，
那次不是"失败"是"根本没跑"（见 `evidence/4648b236a440/`，留档作反例）。★

## 逐条对账

| # | 预测 | 实测 | 判 |
|---|---|---|---|
| P1 | native `SUCCEEDED` | **`FAILED`** | **不符** |
| P2 | failing = 0 | **3** | **不符** |
| P3 | unverified = 0 | 0 | 符 |
| P4 | unmatched 六类全 0（**登记为最高风险**） | 六类全 0（`compare_ref/impl`、`unread_ref/impl`、`bbout_ref/impl` 皆 0） | 符 |
| P5 | 黑盒对数 0、`unresolved_blackbox` 0 | `black_boxes.rpt` = FM-249「No black boxes」；`matched_blackbox_pairs` / `unresolved_blackbox_*` 全空 | 符 |
| P6 | `unread_notcompared` = 0 | 0（`unread_points.txt` 空文件） | 符 |
| P7 | 无 dont_verify / 无 relaxed appvar / allowlist 0 | `dont_verify_objects` `elab147` `relaxed_appvars` 全空；`fm_allowlist_numeric_prefilter="0"` | 符 |
| P8 | passing ∈ [27,000, 30,400] | **28,326**（比较点总数 28,329） | 符 |
| P9 | `impl_closure` 恰 4 条、**无 golden `SbufferData.sv`** | 恰 4 条：`rtl/memblock/Sbuffer.sv`(repo) `rtl/memblock/SbufferData.sv`(repo) `golden-rtl/StorePfWrapper.sv`(golden) `golden-rtl/Serializer.sv`(golden) | **符 —— 假绿已消掉，机器可核** |
| P10 | `dirty=false`、canonical 对得上 | `impl_worktree_dirty=false`，`G1-a4ea…7afcf0` | 符 |
| P11 | 峰值内存 > 1599 MB | 1777 MB | 符（仅参考） |

**9 符 2 不符。** 两条不符是同一件事：**重写核里有一个真 bug**。

### P4 值得单独记一笔（预登记的最高风险项没有出事）

预测里写的是「impl 的 `SbufferData` 寄存器改名换层，按名匹配必然失效，
必须靠签名/拓扑匹配兜住约 14k bit」。实测：

```
14283 Compare points matched by name
14046 Compare points matched by signature analysis
    0 Compare points matched by topology
 1444 Matched primary inputs, black-box outputs
```

14,046 正好是签名匹配扛下来的那一半 —— 与「约 14k」的估算吻合。
**一条 `set_user_match` 都不需要**，`fm_pins.tcl` 没建、也不需要建。

## 3 个 failing 点：真 bug，不是配对伪影

```
r:/WORK/Sbuffer/tag_mismatch_REG_reg    <-> i:/WORK/Sbuffer/u_core/g_fwd[0].fwd_valid_q_reg
r:/WORK/Sbuffer/tag_mismatch_REG_1_reg  <-> i:/WORK/Sbuffer/u_core/g_fwd[1].fwd_valid_q_reg
r:/WORK/Sbuffer/tag_mismatch_REG_2_reg  <-> i:/WORK/Sbuffer/u_core/g_fwd[2].fwd_valid_q_reg
```

配对是**对的**（两侧都是 `io_forward_<i>_valid` 打一拍），差的是**复位域**：

| | golden | 改前的重写核 |
|---|---|---|
| `tag_mismatch_REG{,_1,_2}` ↔ `fwd_valid_q` | `always @(posedge clock)` —— **无复位**（golden `Sbuffer.sv:11707`，驱动在 12763/13342/13921） | `always_ff @(posedge clock or posedge reset)`，`if (reset) fwd_valid_q <= 1'b0` |
| `tag_mismatch_last_REG_*`（96 个）↔ `vtag_match_q` / `act_or_infl_q` | `always @(posedge clock or posedge reset)`（golden `Sbuffer.sv:14218`），复位到 0 | 同 —— 这组是**对的** |

golden 整个文件只有 3 个 `always @`：两个 `posedge clock`、一个
`posedge clock or posedge reset`。`tag_mismatch_REG` 那 3 个落在**无复位**那类，
而重写核把它们和 `tag_mismatch_last_REG_*` 一起塞进了带复位的块。
核里原来的注释写的就是错的：「无使能、异步复位 0（↔ golden tag_mismatch_REG /
tag_mismatch_last_REG_*）」—— 把两组不同复位域的寄存器并列成一组。

**修法**：拆成两个 `always_ff`，`fwd_valid_q` 进无复位那个。

### ★这条 bug 说明了什么（以及说明不了什么）★

- **UT 六轮全绿没抓到它**，10 个变异体也没抓到（变异全打在别处）。
  原因直白：`fwd_valid_q` 是**逐拍无条件覆写**的，复位释放后一拍就同步了，
  而 tb 的比较窗口在暖机之后（`fill_cycle` 28~59 拍）才打开。
  **差异只存在于复位期与复位后第一拍，正好在比较窗口之外。**
  这是"两轮 initreg 都绿 ≠ 复位域正确"（CONVENTIONS 正确性验收第 1 条）
  的一个新实例，而且这次是 FM 抓的、不是复位域结构闸抓的。
- **它不能算"假绿配置盖住的东西"**：`tag_mismatch_REG` 在 `Sbuffer` 自己里，
  不在 `SbufferData` 里，改指与否都会被 FM 看到。诚实的说法是：
  **这个目标此前一次真 FM 都没跑过**（第一版预测自己写着"本轮 FM 一次都还没跑"），
  所以它是"第一次真跑"抓到的，不是"拆掉假绿"抓到的。两件事都真，别混着说。

---

# §7 修 bug 后的再登记（第二次真跑，跑之前写）

改动只有一处：`rtl/memblock/Sbuffer.sv` 里把 `fwd_valid_q` 从带复位的
`always_ff` 拆到无复位的 `always_ff`。`SbufferData.sv` / `Makefile` / `tb.sv`
一个字节没动。

| # | 预测 | 依据 |
|---|---|---|
| Q1 | native verdict = `SUCCEEDED` | 3 个 failing 的机理已定位到唯一一处复位域差异，且该差异**只**影响这 3 个点 |
| Q2 | failing = 0 | 同上 |
| Q3 | passing = **28,329**（= 28,326 + 3），unverified/aborted = 0 | 比较点集合不变：拆 always_ff 不增删寄存器，只改复位；总数 28,329 由上一跑实测钉死 |
| Q4 | unmatched 六类仍全 0；`matched by name` 仍 14,283、`by signature` 仍 14,046 | 寄存器名字与层次都没改 |
| Q5 | `unread_notcompared` = 0、黑盒 0、无 dont_verify / relaxed appvar | 同上一跑 |
| Q6 | `impl_closure` 仍恰 4 条、仍无 golden `SbufferData.sv` | Makefile 未动 |
| Q7 | UT 六轮仍全绿（errors=0） | 差异在比较窗口之外；且 `fwd_valid_q` 逐拍无条件覆写 |
| Q8 | 变异体仍 10/10 CAUGHT | 变异点与本次改动不相交 |

★Q3 是这次最硬的一条★：如果 passing ≠ 28,329，说明"拆 always_ff 不改变比较点
集合"这个理解错了，必须查清楚，不许事后放宽。
