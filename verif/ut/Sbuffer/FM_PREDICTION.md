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
