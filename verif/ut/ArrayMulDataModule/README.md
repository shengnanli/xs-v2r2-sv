# ArrayMulDataModule 家族 UT —— 覆盖证据与变异测试记录

对位的 golden 顶层（5 个，都在同一个 tb 里双例化）：
`ArrayMulDataModule` / `C22` / `C32` / `C53` / `CSA3_2`。

重写件：`rtl/backend/{ArrayMulDataModule,C22,C32,C53,CSA3_2}.sv`。

文件间依赖（编译顺序按 Makefile `RTL_SRCS` 的顺序）：
`C32.sv` 与 `C53.sv` 都复用 `CSA3_2.sv` 里的 `xs_CSA3_2_core`（家族规矩：
核体只写一份）。所以 `C32.sv` **单独**编译会失败（实测 VCS rc=255，
`Error-[CFCILFBI]` 找不到 `xs_CSA3_2_core`），这是预期的，不是缺陷。

## 复跑

```bash
cd verif/ut/ArrayMulDataModule
for ir in 0 random; do for s in 1 7 42; do make run SEED=$s INITREG=$ir; done; done
```

`ut_common.mk` 下发 `NCYCLES=200000`；`INITREG` 在运行期选 `+vcs+initreg+{0,random}`，
编译期固定带 `+vcs+initreg+random` 打开机制（两处缺一不可）。

## golden 行数构成（先量清膨胀机制，再动手）

`ArrayMulDataModule.sv` 24372 行按行段分类（复跑见本节末尾的命令）：

| 行段 | 行数 | 占比 | 是什么 |
|---|---|---|---|
| L1-86 | 86 | 0.4% | firtool 宏样板头（每个 golden 文件都一样） |
| L87-94 | 8 | 0.0% | 端口表（**只有 6 个端口**） |
| L95-6728 | 6634 | 27.2% | 声明 + Booth 前端 + 组合 wire（2562 个 `reg r_*` + 3849 个 `wire`） |
| L6729-9296 | 2568 | 10.5% | **唯一**一个 `always @(posedge clock)`（2562 条 `<=`） |
| L9297-11877 | 2581 | 10.6% | `initial` randomize —— 仿真专用，不是逻辑 |
| L11878-24113 | 12236 | 50.2% | **1366 个压缩器实例的连线**（C22×293 / C32×84 / C53×989） |
| L24114-24370 | 257 | 1.1% | 末级 `assign io_result = {…} + {…}` |

整体归一化后（数字全换成 `#`）**唯一行模板只有 187 条**。

也就是说：**一半的行是压缩器实例连线，四分之一是 wire 声明，一成是仿真专用的
randomize**。真正的"设计"是三件事——Booth 编码表、压缩树的形状递推、末级加法。
重写件 486 行，分节行号如下（`rtl/backend/ArrayMulDataModule.sv`）：
L1-55 文件头 / L59-187 `arraymul_pkg`（形状递推，129 行）/ L192-207 核端口 /
L208-217 Booth 倍数 / L218-282 33 行部分积（65 行）/ L283-303 堆列 + 第 1 级流水 /
L304-435 Wallace 压缩层 generate（132 行）/ L436-464 末级加法 / L466-486 wrapper。

膨胀机制不是"一个单元 + generate"那么简单：压缩树的形状是 Chisel 展开期一段
**递归 Scala 程序**算出来的，每一列的高度都不同（层 0 是 2,2,3,3,…,33,33,…,2,2），
所以 generate 必须由一张 elaborate 期算出来的高度/偏移表驱动，而不是规则铺排。

```bash
G=/home/eda/xs-env/G1-canonical/golden-rtl/ArrayMulDataModule.sv
grep -nE '^\s*(always|initial|endmodule)' $G     # 唯一时序块在 L6729
grep -nE '^  assign ' $G                         # 唯一一条 assign 在 L24114
grep -cE '^  (C22|C32|C53) ' $G                  # 1366
```

## 结构对账（跑 UT 之前先把"形状"对上）

`ArrayMulDataModule` 的压缩树形状是 Chisel 展开期一段**递归 Scala 程序**算出来的，
不是规则阵列。重写件把那段递归翻成闭式的 `arraymul_pkg::calc_heights()` 递推。
两者产出的算子用量逐项相等，这是重写之前第一件被验证的事：

| 量 | golden 实测 | 重写件闭式规则 |
|---|---|---|
| C22 实例 | 293 | 293 |
| C32 实例 | 84 | 84 |
| C53 实例 | 989 | 989 |
| 流水寄存器 | 2562（`reg r_*` 计数） | 2307(层0) + 255(层5) = 2562 |
| 进位向量右移位数 | 5（golden 末尾 `5'h0`） | 5（`carry_start()`） |
| always 块 | 1 个 `always @(posedge clock)`，**无 reset 端口** | 同（两处 `always_ff @(posedge clock)`） |

golden 侧复跑：
```bash
G=/home/eda/xs-env/G1-canonical/golden-rtl/ArrayMulDataModule.sv
grep -cE '^  C22 '  $G   # 293
grep -cE '^  C32 '  $G   # 84
grep -cE '^  C53 '  $G   # 989
grep -cE '^  reg ' $G    # 2562
```

## elaborate 期的形状闸（负测过）

重写件在 `§2.5` 放了一条 elaborate 期断言：末层高度剖面必须单调
（前 `CARRY_START` 列各 1 位、其后全 2 位）——这正是 golden 末尾那个字面量 `5'h0`
成立的前提。负测：把 `carry_start()` 故意改成 `return 7;`，VCS 当场
`rc=255` 并打出 2 条"剖面不单调"错误。也就是说这条断言会响，不是装饰。

（负测在 scratchpad 的副本上做，仓库文件未改。）

## 覆盖证据（seed=1 / INITREG=random / 200k 拍的 tb 自报）

```
compressor 5-bit input patterns : 32/32 seen, min hits = 1140     <- C22/C32/C53/CSA3_2 输入空间穷举
booth windows 0..7              : 8/8 seen,  min hits = 290778    <- Booth 选择表 7 个分支全覆盖
operand classes 0..7            : 8/8 seen,  min hits = 24821     <- 全0/全1/单点/交替/合法带符号/合法无符号/随机
regEnables {en1,en0} combos     : 4/4 seen,  min hits = 1997      <- 两级流水使能四种组合（含"保持"）
cycles with non-zero product    : 154019
checks=1999992 errors=0
```

`TEST PASSED` 的判据里已经把这四项的**最低水位 > 0** 与"非零乘积拍数 > 1000"写死，
覆盖不到位不会给绿灯。

六轮（seed 1/7/42 × INITREG 0/random）全部 `checks=1999992 errors=0`，
逐轮实测值见各 `run_<seed>_<initreg>.log`。

## 变异测试（注入真 bug，不进库；脚本在 scratchpad，见下）

| 变异 | 注入内容 | 结果 |
|---|---|---|
| `amdm_en`    | 丢掉第 1 级流水使能（`if (reg_en_pp)` → 无条件加载） | **CAUGHT**（errors=375） |
| `amdm_corr`  | Booth 修正量取本行窗口而不是上一行（`window[k]` 代 `window[k-1]`） | **CAUGHT**（errors=2818） |
| `amdm_tail`  | 尾块 C32 的第 3 个输入接 0（丢一位） | **CAUGHT**（errors=2619） |
| `amdm_order` | 把低一列的 cout2 并进本列时**次序反转** | ★**NOT CAUGHT**★ |

### ★`amdm_order` 抓不到，这不是 UT 写得差，是这一类差异在模块边界上不可见★

Wallace 树的每个压缩器都**保权重和**，最后一步又是把最后一层的
`sum + carry` 一次加完；所以**同一列内的位怎么排列、怎么分块，io_result 的值完全不变**。
纯仿真（无论多少拍、多少 seed）都区分不了列内换序。

能钉住次序的只有**两级流水寄存器**：`pp_reg`(2307) 与 `mid_reg`(255) 是模块里仅有的
状态，列内换序会让它们逐位对不上 golden 的 `r_0..r_2561`。所以：

1. FM 的寄存器比较点会盖住**层 0 与层 5** 这两个边界（这正是 FM 相对 UT 的增量）；
2. 本轮**没有等 FM**，先用一次性的层次探针把这两个边界自己钉死了（见下）。

★说清楚边界在哪：中间三层（1→2 / 2→3 / 3→4）是纯组合、没有比较点，
在那里换序 UT 与 FM **都**不会响 —— 但那种情况下两个电路是真的等价，
不响是对的，不是漏。本重写件中间层也与 golden 同构（算子用量逐项相等），
这是"照抄结构不合并"的结果，不是被谁验出来的。这一点如实说。

### 结构探针：2562 个流水寄存器逐个对 golden

一次性脚本（不进库，放在 scratchpad）生成一个 2572 行的 tb，逐拍比
`u_g.r_<N>` 与 `u_i.u_core.pp_reg[N]` / `mid_reg[N-2307]`：

```
PROBE pp_reg mismatches=0  mid_reg mismatches=0  io_result mismatches=0 (cycles=4000)
PROBE PASSED
```

即：重写件的层 0 (`pp_reg[0..2306]`) 与层 5 (`mid_reg[0..254]`) 寄存器，
与 golden 的 `r_0..r_2306` / `r_2307..r_2561` **逐个同位同值**（4000 拍随机激励、
两级使能随机拉低）。列内次序与 golden 一致，不是"碰巧值相等"。

这条探针也把上面那个 `amdm_order` 变异补上了 —— 同一份探针跑变异件：

```
PROBE pp_reg mismatches=0  mid_reg mismatches=103767  io_result mismatches=0 (cycles=4000)
PROBE FAILED
```

`io_result` **一位不差**（所以 UT 无论跑多少拍都绿），而 `mid_reg` 4000 拍里
错了 103767 个寄存器位。这就是 CONVENTIONS 里"值恒等 ≠ 可证等价"最干净的一个实例：
能拦住它的只有寄存器级的比较点（本探针 / FM），端口级的仿真拦不住。

### 这两件东西**没有进库**，说清楚为什么

变异件与探针 tb 都是一次性产物，放在本次会话的 scratchpad：
`…/scratchpad/mut/run_mutant.sh` + `p_amdm_*.py`（变异），
`…/scratchpad/gen_probe_tb.py`（探针生成器，`python3 gen_probe_tb.py > probe_tb.sv`
可逐字节复现用过的那份 tb，sha256 `0c8afb2a4f6dd78c6100df6c367221857c150094951e1c0320bddd616e57bbb1`）。

不进库的理由：探针 tb 是按 **golden 的扁平寄存器名 `r_0..r_2561`** 和
**重写件的层次路径 `u_i.u_core.pp_reg[...]`** 写死的，两边任何一处改名它就静默失效；
而本仓 `scripts/test_gen_idempotent.py` 只覆盖 `verif/ut/*/gen.py`，
放进来也没有闸看着它，正是本仓反复吃亏的"生成物无闸腐烂"形态。
它该覆盖的事 FM 的寄存器比较点会长期覆盖；在 FM 之前它是我手上唯一的证据，
所以数字如实记在这里，脚本留作可复跑的一次性工具。
