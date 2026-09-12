# ExeUnit_int0 学习台 —— 对着波形读懂香山的整数执行口

这个目录只有一个目的：**让你在 Verdi 里把 golden 和可读重写并排放着看**，
左边一栏是 firtool 吐出来的 `inPipe_2_1` / `_GEN_0` / `acceptVec_0`，
右边一栏是同一根线的人话名字 `alive_s1` / `hit_alu`，
中间由 testbench 逐拍逐位盯着，谁偏了立刻报出来。

```
tb
 ├── u_gold : ExeUnit      ← /home/eda/xs-env/G1-canonical/golden-rtl/ExeUnit.sv（一个字没动）
 └── u_read : ExeUnit_xs   ← 本目录 ExeUnit_study.sv（手写可读重写）
        同一份激励  →  每拍比对 20 组输出端口  →  末尾打 TEST PASSED / FAILED
```

## 怎么跑

```bash
cd verif/study/ExeUnit_int0
make          # 派生 + 编译 + 仿真，产出 novas.fsdb 和 sim.log
make sig      # 产出分组的信号清单 signals.txt
make verdi    # 打开 Verdi
```

`make` 末尾会打：

```
================ 双例化比对结果 ================
  比对拍数 : 181
  端口组数 : 20（golden ExeUnit 的全部输出端口）
  失配次数 : 0
  ==> TEST PASSED —— golden 与可读重写逐拍逐位一致
================================================
```

想看"时钟门控常开"的样子：`./simv +cg_te=1`（默认 0，功能模式，能看见门在关）。

---

## 一、这个执行口是什么

香山昆明湖 V2 后端有一排**执行口**（issue port / ExeUnit）。每个口从发射队列
（IssueQueue）收 uop，喂给口内几个功能单元（FU）之一，等结果出来仲裁成唯一一路写回。

本口 = **整数 0 号口**，口内三个 FU：

| FU | fuType 独热位 | 延迟 | 握手形态 |
|---|---|---|---|
| `Alu`     | bit 6  (`35'h40`)  | **0 拍** | 纯组合：`in_ready = out_ready`，`out_valid = in_valid` |
| `MulUnit` | bit 7  (`35'h80`)  | **2 拍** | 定长流水：自己的 `rdyVec` 反压链 + 外面喂进来的存活链 |
| `Bku`     | bit 10 (`35'h400`) | **2 拍** | 同 Mul（位操作 / Zb*、Zk* 加密扩展） |

**ExeUnit 自己不做任何运算。** 它全部的工作是 FU 周围的 glue：
分发、控制位打拍对齐、flush、时钟门控、输出仲裁。
想看运算，去 `rtl/backend/Alu.sv` / `MulUnit.sv` / `Bku.sv`。

---

## 二、两侧到底谁是 golden、谁是可读的（诚实边界）

这一节请先读完再打开 Verdi，免得展开层次时被"怎么又是 golden"膈应到。

| 层次 | golden 侧 `u_gold` | 可读侧 `u_read` |
|---|---|---|
| 执行口 glue | `ExeUnit`（firtool，791 行） | `ExeUnit_xs` → `xs_ExeUnit_study_core`（本目录手写） |
| 分发器 | `Dispatcher`（firtool，233 行） | `Dispatcher_xs` → `xs_Dispatcher_study_core`（本目录手写） |
| Alu | `Alu`（firtool） | `Alu_xs` → `xs_Alu_core`（`rtl/backend/Alu.sv`，已签核的正式重写） |
| MulUnit | `MulUnit`（firtool） | `MulUnit_xs` → `xs_MulUnit_core`（`rtl/backend/MulUnit.sv`，同上） |
| Bku | `Bku`（firtool） | `Bku_xs` → `xs_Bku_core`（`rtl/backend/Bku.sv`，同上） |
| ClockGate | golden | **同一份 golden**（工艺库单元，不重写） |
| 运算阵列叶子 | golden | **同一份 golden**（`ArrayMulDataModule` / `CountModule` / `ClmulModule` / `MiscModule` / `CryptoModule` 等，另有 owner） |

所以：**从执行口一路展到 FU 内部的 valid 链、反压链，右边这一栏全是可读代码**；
只有最底下的运算阵列和库单元仍是 golden，那些是"算得对不对"的事，
和本目录要讲的五件事（分发 / 两个 valid / 握手 / flush 窗口 / ctrlPipe）无关。

**`_xs` 后缀是什么**：`rtl/backend/*.sv` 里的正式重写按工程规范带一个与 golden
**同名**的 wrapper（`module Alu`）。要把 golden 和重写编进同一次 elaboration 就会撞名，
所以先用 `scripts/derive_ut_impl.py` 把非 `xs_` 前缀的模块机械改名成 `<名>_xs`
（**只改名字，逻辑一个字符没动**），派生结果在 `ut_gen/`。
本目录手写的两份直接就叫 `ExeUnit_xs` / `Dispatcher_xs`，不走派生 ——
这样你在 Verdi 里读到的就是我写的原文，注释没被改名脚本动过。

### 这份 ExeUnit_study.sv 的地位

- 它是 **verif/study 下的学习材料，不是 rtl/ 里的交付重写**。
- 它**没有过本工程的 FM（Formality）等价签核**，只过了本目录 tb 的逐拍双例化比对。
  "181 拍 0 失配"是仿真证据，不是形式化证明 —— 别把它当 signoff 用。
- 它不进重写台账，不产生 receipt。将来 ExeUnit 被正式重写进 `rtl/backend/` 时，
  应当按 CONVENTIONS 走单文件规范 + UT + FM，本文件可以当草稿参考。

---

## 三、两边"对不上"的地方（你最需要知道的一节）

### 行为上：0 处

181 拍 × 20 组输出端口，逐位 `!==` 比对，**失配 0 次**。
比对器在 `tb.sv` 的 `always @(posedge clk) if (!rst)` 块里，覆盖 golden ExeUnit 的
**全部输出端口**：`io_in_ready`、`io_out_valid`、`data_0/1`、`pdest`、
`robIdx_flag/value`、`intWen`、10 根 `debugInfo_*`、2 根 `debug_seqNum_*`。

这个"0"只对本 tb 跑过的 181 拍成立。它**不是**穷尽证明：
没有随机激励、没有跑 100k 拍、没有 FM。它足够支撑"你在波形上看到的两栏确实是同一回事"，
不足以支撑"这份重写可以进芯片"。

### 结构上：3 处（不影响波形数值，但你在层次树里会看见）

1. **perf / seqNum 绕过了分发器。**
   golden 里那 12 根观测线（`perfDebugInfo_*` + `debug_seqNum_*`）从 `io_in` 进
   `Dispatcher`，再原封不动三路广播出来喂给三个 FU。可读侧为了不让 36 行机械连线
   淹掉核心逻辑，让它们**直接**从 `io_in` 接到各 FU。因为分发器对它们是纯 `assign` 直通，
   两种接法逐拍等价。副作用：`u_read.u_core.u_disp` 的那三组 perf 输出端口没人接
   （模块内部照常有值，波形里看得到）。编译时 VCS 会报一条
   `Warning-[TFIPC] Too few instance port connections`，就是这个，是预期的。

2. **模块名带 `_xs` 后缀**，见上一节。

3. **可读侧多了几个 golden 里没有名字的中间信号**：
   `kill_s0` / `kill_s1`（flush 判定结果）、`g_gate[*].busy` 等。
   golden 里这些表达式是内联在 `always` 块里的，没有可拖的线。
   这不是"不一致"，是"可读侧多给了你观察点"。

### 不属于本目录、但你可能听说过的 G0/G1 差异

上一轮（G0 基线，`xs-v2r2-sv`）也写过一份可读 ExeUnit，**本目录没有用它**，原因见第四节。
G0→G1 这个模块的实质变化，知道一下有好处：

| | G0 | G1（本目录对照的版本） |
|---|---|---|
| 端口数 | 30 | **50** |
| 握手 | 没有 `io_in_ready` / `io_out_ready` —— 执行口完全不参与握手 | **新增这两个**：FU 的握手上翻到父层，父层再往上游报 |
| 时钟门控影子链 | 无条件移位 | 加了 ready 门控（`fuRdyVec`） |
| perf 字段 | 只有 3 根（enqRs/select/issue） | 10 根 + `debug_seqNum` 2 根 |

注意最后一点的实际后果：因为整数写回口的 `io_out_ready` 在 `ExuBlock` 里硬接 `1'b1`，
G1 新加的那套 ready 门控在真实芯片里**恒等于 G0 的无条件移位**。
它是"为将来可能的反压留的接口"，不是当前配置下的行为变化。
本目录**阶段 7** 专门把 `out_ready` 拉低一段，让这条路径动起来给你看。

---

## 四、为什么重写了一份新的，而不是拿 G0 那份来对照

原计划有两条路：(a) 直接用 G0 可读核对照、逐条标注 G0/G1 差异；
(b) 先把可读核按 G1 对齐再对照。**这里走的是 (b)**，理由：

1. **代价被高估了。** 担心 (b) 贵，是因为"ExeUnit 是 FU 的父层，那批 FU 刚改完握手"。
   但本目录**不重写任何 FU** —— 三个 FU 直接用 `rtl/backend/` 里已经签核过的重写。
   真正要写的只有父层 glue：两条 2 级流水 + 两条门控影子链 + 一个或归约仲裁，
   加起来 100 行左右真逻辑。实际耗时远小于"逐条标注差异"的解释成本。
2. **(a) 的产出是有毒的教学材料。** G0 那份连 `io_in_ready`/`io_out_ready` 都没有，
   拖到 Verdi 里两栏在握手、反压、时钟门控三处都对不上。
   学的人得先记住"这三处不算数"再看剩下的 —— 这比没有对照更糟。
3. **(b) 的对照是可证伪的。** 现在两栏应当**逐拍完全重合**，tb 里有比对器盯着。
   任何一处对不上都是真问题，不需要你自己判断"这算差异还是算 bug"。

代价：这份重写没进 `rtl/`、没过 FM。已在第二节末尾写明。

---

## 五、golden ↔ 可读 名字对照表

Verdi 里最实用的一张表。左边直接在 `u_gold` 下按名字找，右边在 `u_read.u_core` 下找。

### 执行口 glue（`u_gold` ↔ `u_read.u_core`）

| golden | 可读 | 是什么 |
|---|---|---|
| `_in1ToN_io_out_0/1/2_valid` | `disp_valid[0/1/2]` | 分发给 Alu/Mul/Bku 的 valid |
| `_Alu_io_in_ready` 等 | `disp_ready[0/1/2]` | 三个 FU 报回来的 ready |
| `inPipe_2_1` | `alive_s1`（= `alive_pipe[0]`） | **存活链**第 1 级 |
| `inPipe_2_2` | `alive_s2`（= `alive_pipe[1]`） | 存活链第 2 级 |
| （内联，无名） | `kill_s0` / `kill_s1` | 两个 flush 判定点的结果 |
| `inPipe_1_1_robIdx_value` 等 | `ctrl_s1`（= `ctrl_pipe[0]`） | **控制位链**第 1 级（struct） |
| `inPipe_1_2_*` | `ctrl_s2`（= `ctrl_pipe[1]`） | 控制位链第 2 级 |
| `fuVldVec_1` / `fuVldVec_2` | `g_gate[0].occ_s1` / `.occ_s2` | Mul 的门控**影子占用链** |
| `fuVldVec_1_1` / `fuVldVec_2_1` | `g_gate[1].occ_s1` / `.occ_s2` | Bku 的同上 |
| `fuRdyVec_1` / `fuRdyVec_1_1` | `g_gate[0/1].rdy_s1` | 影子链的反压 |
| `fuVld_en_1` / `fuVld_en_2` | `g_gate[0/1].busy` | 链上任一级有货 |
| `fuVld_en_reg_1` / `_reg_2` | `g_gate[0/1].busy_q` | 上面那个打一拍（多留一拍时钟） |
| `clk_en_1_probe` / `clk_en_2_probe` | `clk_en_gated[0/1]` | 送进 ClockGate 的使能 |
| `_ClockGate_Q` / `_ClockGate_1_Q` | `fu_clk[0]` / `fu_clk[1]` | 门控后的 FU 时钟 |
| `_Alu_io_out_valid` 等 | `fu_valid[0/1/2]` | 各 FU 的写回 valid |
| `io_out_bits_data_1_0` | `sel_data` | 或归约后的写回数据 |

### 分发器（`u_gold.in1ToN` ↔ `u_read.u_core.u_disp.u_core`）

| golden | 可读 |
|---|---|
| `acceptVec_0` / `_1` / `_2` | `hit_alu` / `hit_mul` / `hit_bku`（也是 `accept[0..2]`） |

### FU 内部（`u_gold.Mul` ↔ `u_read.u_core.u_mul.u_core`，Bku 同理）

| golden | 可读 |
|---|---|
| `validVecThisFu_1` / `_2` | `valid_thisfu_1` / `_2` |
| `rdyVec_0` / `rdyVec_1` | `rdy_s0` / `rdy_s1` |

> `make sig` 会把上面这些按教学点分好组写进 `signals.txt`，
> Verdi 里 **File > Restore Signal…** 选它即可。
> 这些层次路径在 `tb.sv` 的 `dump_paths()` 里各被引用了一次 ——
> 路径写错或将来谁改了名，**编译就会失败**，这份清单不会悄悄腐烂。

---

## 六、五个教学点，逐条

### 1. 分发：35 位独热码的**整字相等比较**

`fuType` 是 35 位独热码（`FuType.scala` 的 `OHEnumeration`：
jmp=0, brh=1, i2f=2, i2v=3, f2v=4, csr=5, **alu=6, mul=7**, div=8, fence=9, **bku=10**, …）。
分发器对每个 FU 做一次 `fuType == (1<<bit)`：

```systemverilog
assign accept[i] = (in_fuType == (FUTYPE_W'(1) << FU_BIT[i]));
```

**为什么不直接取一位？** 因为整字比较等价于"这一位是 1 **且其余全 0**"。
多设一位就谁也不命中，会被断言抓住；取一位则会静默地分到某个 FU。

反压方向是**与归约**，不是 Mux1H：

```systemverilog
assign in_ready = &out_ready;   // 任何一个 FU 满了，整个口就不收
```

哪怕这条 uop 要去的是空着的那个 FU 也一样。这是有意的简化（缩短发射侧关键路径），
代价是口内可能有假阻塞。本口三个 ready 在真实芯片里恒 1，假阻塞不会发生。

**波形**：阶段 1~4，看 `acceptVec_*` ↔ `hit_*`，以及三路 valid 怎么跟 `in_fuType` 走。

---

### 2. 两个 valid 的分工 —— 最容易看混的地方

| | 名字 | 谁维护 | 认不认识 flush |
|---|---|---|---|
| **存活性**"这条 uop 还该不该算数" | golden `inPipe_2_1/_2_2`，可读 `alive_s1/s2` | **ExeUnit** | 认识，flush 只动它 |
| **占用性**"这一级槽里有没有东西" | golden `validVecThisFu_1/_2`，可读 `valid_thisfu_1/_2` | **FU 自己** | 完全不认识 |

FU 的写回 valid 是两者相与。golden `MulUnit.sv` 最后一行就写着：

```verilog
assign io_out_valid = io_in_bits_validPipe_2 & validVecThisFu_2;
```

存活链从 ExeUnit 通过 `io_in_bits_validPipe_0/1/2` 三根端口喂进 FU。
**杀掉一条在飞指令的全部机制，就是把存活链掐成 0** —— 占用链照常走完，
数据照常在 FU 里往前推，只是最后那一与出不来。

**波形**：阶段 51/52。把这四根拖成一排：

```
u_gold.inPipe_2_2                              ┐ 存活：被掐 0
u_read.u_core.alive_s2                         ┘
u_gold.Mul.validVecThisFu_2                    ┐ 占用：照常走完
u_read.u_core.u_mul.u_core.valid_thisfu_2      ┘
```

---

### 3. 三种握手形态 —— ★这一条原来的说法有错，已订正

原始教学清单写的是：
「Alu 单拍纯组合（`in_ready = out_ready`）、Mul/Bku 定长流水（`rdyVec` 链 + `validPipe`）、
Div 变长迭代（纯 ready/valid）」。核对下来：

- **Alu 那句对。** golden `Alu.sv` 只有两行赋值：`io_in_ready = io_out_ready`、
  `io_out_valid = io_in_valid`，模块连 `clock` 端口都没有。
- **「Div 变长迭代」在本执行口里看不到。** 这个 ExeUnit 只有 Alu/Mul/Bku 三个 FU，
  **没有 Div**（`div` 是 fuType bit 8，在别的执行口变体里）。
  拿本目录的波形找 Div 会白找。变长迭代 FU 在 Chisel 里走的是另一条路
  （`ExeUnit.scala` 里的 `uncerLat` / `busy` 分支），本配置下整块被优化掉了 ——
  这也是为什么 golden `ExeUnit.sv` 里看不到 `busy`，而 `ExeUnit.scala` 里有。
- **「Mul/Bku = rdyVec 链 + validPipe」这句不准确**，需要补一句要紧的：
  `rdyVec` 链**只门控 payload 寄存器**（数据 / 控制 / perf / seqNum），
  **不门控占用链**。golden `MulUnit.sv`：

  ```verilog
  else begin
    validVecThisFu_1 <= io_in_valid;        // 无条件移位，没有 rdyVec
    validVecThisFu_2 <= validVecThisFu_1;
  end
  ...
  if (rdyVec_0 & io_in_valid) begin ... end // 只有 payload 在 ready 门控里面
  ```

  这不是 firtool 的产物 —— Chisel `FuncUnit.scala` 的 `pipelineReg()` 就是把
  `validVec(i) := validVec(i-1)` 写在 `when(rdyVec…)` **外面**的。
  后果：下游真拉低 ready 时 **valid 会继续往前走而 payload 停在原地**，
  也就是"valid 与 payload 脱节"，那一拍的写回被直接丢掉。
  为什么现在不出事：整数写回口的 `out_ready` 硬接 1，`rdyVec` 恒 1，这条路径不可达。
  本工程要求与 golden bug-for-bug 一致，所以两侧**一致地**保留这个行为。

**波形**：阶段 7 就是专门演示这一条的 —— 把 `out_ready` 拉低，
你会看到 `rdyVec_0/_1` ↔ `rdy_s0/s1` 塌下来、`io_in_ready` 跟着塌，
但 robIdx=50 那条**照样在 `out_ready=0` 的那一拍写回了**（sim.log 里能看到）。

---

### 4. flush 判定窗口只有 2 拍 —— 说法正确

`pipelineReg()` 只造了两级带 flush 的存活寄存器（`latencyMax = 2`），
所以判定点只有 `alive_pipe[0]`、`alive_pipe[1]` 两个，没有第三个：

```
T    : flush 到 → kill_s0 命中 → alive_pipe[0] 写 0      ✔ 杀掉   （阶段 51）
T+1  : flush 到 → kill_s1 命中 → alive_pipe[1] 写 0      ✔ 杀掉   （阶段 52）
T+2  : flush 到 → 没有判定点了，Mul 这拍已经 out_valid    ✘ 照常写回（阶段 53）
```

T+2 那次**不是漏洞**：写回带着 robIdx，ROB 收到后按 robIdx 自己丢弃。
执行级只做"能省则省"，正确性兜底在 ROB —— 分层过滤。

flush 判据（`need_flush`）也和原说法一致：

```systemverilog
need_flush = fl_valid & ( (fl_level & (rob == fl_rob)) | rob_younger(rob, fl_rob) );
function rob_younger(a, b) = a.flag ^ b.flag ^ (a.value > b.value);
```

- `level=0`（后端重定向 / 分支预测失败）：只杀**严格更年轻**的，flush 点自己活着走完。
- `level=1`（flushItself，异常 / fence）：**连自己一起杀**。
- `rob_younger` 是**环形**比较：ROB 是环形队列，指针每绕一圈 `flag` 翻转一次，
  所以不能只比 `value`。注意 Verilog 里 `>` 优先级高于 `^`，
  golden 那一长串的断句是 `flag ^ flag ^ (value > value)`。

**波形**：阶段 51/52/53 看窗口；阶段 61/62/63 看 level 语义
（61 和 62 用**完全相同**的激励，只改 `level`：61 活、62 死）。

---

### 5. `ctrlPipe`：控制位在 FU 外面走 —— 说法正确，补两点细节

`robIdx` / `pdest` / `rfWen` 这些控制位**不进 FU 的运算流水**，
而是在 ExeUnit 里单独打一条纯移位链（`ctrl_pipe`，无复位），
等 FU 出结果那拍再把对应级交给它。省掉在每个 FU 里各复制一份控制流水的面积。

两点细节：

- **每个 FU 按自己的延迟取不同的一级**：
  Alu（0 拍）吃 `ctrlPipe_0` = 当拍的 `io_in`；
  Mul/Bku（2 拍）吃 `ctrlPipe_2` = `ctrl_pipe[1]`（延后 2 拍那份）。
  golden 的端口名 `io_in_bits_ctrlPipe_0_*` / `io_in_bits_ctrlPipe_2_*` 就是这个意思。
- **这条链没有复位**（golden 是光杆 `always @(posedge clock)`）。
  复位后头两拍它是垃圾值，但那两拍存活链是 0，没人看它。
  本目录用 `+vcs+initreg+0` 让两侧同样地清 0，所以波形干净。

**波形**：阶段 2，看 `inPipe_1_1_robIdx_value → inPipe_1_2_robIdx_value` ↔
`ctrl_s1.robIdx.value → ctrl_s2.robIdx.value` 怎么跟着 uop 走两拍，
然后在写回那拍变成 `io_out_bits_robIdx_value`。

---

### 附：第 6 件事 —— 时钟门控为什么要养一条"影子链"

`ExeUnit` 里的 `fuVldVec_*`（可读侧 `g_gate[*].occ_s*`）和 FU 内部的
`validVecThisFu_*` 长得一模一样，为什么要复制一份？

因为 **FU 的时钟是被门控的**。FU 内部那条链跑在门控后的时钟上，
门一关它就冻住，没法用它判断"还要不要继续给时钟"—— 鸡生蛋。
所以在**未门控**的 `clock` 上再养一条影子链专门算使能。
这是时钟门控的经典写法：**决定要不要给时钟的那点逻辑，自己不能被门控。**
（这一句是我对设计意图的解读，Chisel 源码没写注释。）

`clk_en = (入口有 uop | 影子链任一级有货) | 上一拍的这个值`，
末尾那个"| 上一拍"是**多留一拍** —— 最后一级出结果那拍还要靠时钟把结果打出去。

**波形**：阶段 8（`cg_te` 从 0 变 1）。默认 `cg_te=0`（功能模式），
`_ClockGate_Q` ↔ `fu_clk[0]` 只在有在飞 uop 时才跳；`cg_te=1` 后门常开，时钟自由跑。
两种模式下写回结果完全一样 —— 这本身就是"这个 clk_en 覆盖了所有活动"的证据。

---

## 七、阶段一览（波形里看 `tb.phase` 定位）

| phase | 演示 | 期望 |
|---|---|---|
| 1 | ALU add 单周期 | 发射当拍就写回 `3+4=0x7` |
| 2 | MUL 两级流水 | 存活链 + 占用链逐级推进，2 拍后写回 `6*7=0x2a` |
| 3 | BKU clz 两级流水 | 走另一条 FU，`0xFF` 的前导零 = `56 = 0x38` |
| 4 | 连发 ALU/MUL/BKU | 三条在不同 FU 并行，写回 `0x2a` / `0x51` / `0x0f` 错开 |
| 51 | flush 与发射**同拍** | `kill_s0` 命中 → 不写回 |
| 52 | flush 晚 **1** 拍 | `kill_s1` 命中 → 不写回 |
| 53 | flush 晚 **2** 拍 | ★窗口已过 → 照常写回 `14*14=0xc4` |
| 61 | `level=0`，robIdx **等于** flush 点 | 不杀 → 写回 `6*6=0x24` |
| 62 | `level=1`，同样相等 | 连自己一起杀 → 不写回 |
| 63 | `level=0`，flush 点更年轻 | 在飞的更老指令不受影响 → 写回 `7*7=0x31` |
| 7 | ★`out_ready=0` 反压 | ready 链塌下来，但 valid 照走、写回被丢（见教学点 3） |
| 8 | ★`cg_te` 0→1 | 门控时钟从"按需跳"变成"自由跑"，结果不变 |
| 9 | ★写回口撞车 | 或归约的前提被打破，产生一条**不存在的指令**（见下） |

### 阶段 9 值得单独说

`§4` 的或归约（Chisel 的 `Mux1H`）有一条硬前提：**同一拍至多一个 FU 写回**。
阶段 9 故意打破它 —— cycle N 发 Mul，cycle N+2 发 Alu，两者正好撞在同一拍：

```
data   = 8*8 | (2+3) = 0x40 | 0x05 = 0x45     ← 写回口上出现了一条不存在的指令
robIdx = 70  | 71                  = 71
```

golden 在这里放了 `XSError(PopCount(fuOutValidOH) > 1.U, …)`
（`ExeUnit.scala:323`，firtool 生成到 `` `ifndef SYNTHESIS `` 里，被本目录的
`+define+SYNTHESIS` 关掉了）。**说明设计者知道这是前提而不是保证。**
真正防撞的是发射侧的 `WbFuBusyTable`：发射队列按各 FU 的固定延迟预定写回时隙，
撞车的组合压根不会被发出来。ExeUnit 只负责在前提被违反时炸出来。

> 顺带记一笔：本目录**上一版 tb 的"阶段 6"就是无意中撞了这一下**。
> 它打印 `robIdx=41 pdest=41 data=0x1b`，被读成"41 存活、Mul 的 40 被 flush 掉了"。
> 其实 `0x1b = 27 = 25 | 2` —— Mul 的 `5*5=25` 和 Alu 的 `1+1=2` 或在了一起，
> robIdx 也是 `40|41=41` 或出来的。真正的原因不是 flush 生效，而是撞车 + 或归约。
> （而且那个 flush 到得太晚：Mul 在第 1 拍发射、flush 在第 5 拍才到，
> 早就出了 2 拍的窗口，根本杀不到任何东西。）
> **看波形时务必分清"或归约的产物"和"某一条指令的结果"。**
> 现在这个坑被改造成了阶段 9，专门演示它。

---

## 八、推荐的 Verdi 看法（20 分钟走一遍）

1. `make && make sig && make verdi`，**File > Restore Signal…** 选 `signals.txt`。
2. 先把 `tb.phase` 拖到最上面当刻度尺。
3. **阶段 1**：确认 `g_out_valid` 和 `r_out_valid` 完全重合。
   建立"这两栏就是同一个东西"的信任，后面才看得下去。
4. **阶段 2**：看第 2 组信号。从 `hit_mul` 出发，跟着
   `alive_s1 → alive_s2` 和 `valid_thisfu_1 → valid_thisfu_2` 两条链走两拍，
   在写回那拍看它俩相与。同时看第 5 组的 `ctrl_s1 → ctrl_s2` 怎么把 robIdx 送到终点。
5. **阶段 51 / 52 / 53 连着看**：同样三条 Mul，只有 flush 到达时刻不同。
   重点盯 `alive_s2` 和 `valid_thisfu_2` 的**分叉**。
6. **阶段 61 / 62**：激励一模一样，只改 `flush_level`。这是 level 语义最干净的证据。
7. **阶段 7**：把 `out_ready`、`rdy_s0/s1`、`valid_thisfu_*`、`r_out_valid` 排一起，
   亲眼看 valid 与 payload 脱节。
8. **阶段 8**：把 `fu_clk[0]` 展开看时钟本身的波形。
9. **阶段 9**：看 `fu_valid[0]` 和 `fu_valid[1]` 同时为 1 的那一拍，
   以及 `sel_data` 变成 `0x45`。

## 九、已知局限

- 没有随机激励、没有长跑、**没有 FM 等价证明**。181 拍定向激励而已。
- `Dispatcher_study.sv` / `ExeUnit_study.sv` 未进 `rtl/`，不受
  `scripts/readability_audit.py` 管辖（它只扫 `rtl/`），但写的时候按同样的规矩来了
  （代码区无 `_GEN_*` / `_T_<n>`，文件头说清位置与机制）。
- 可读侧依赖 `rtl/backend/{alu_pkg,Alu,MulUnit,Bku}.sv` 的当前 HEAD 版本。
  这三份有各自的 owner，如果谁改了它们，本目录 `make` 会自动重新派生并重编；
  真出现失配，先看是不是那边动了。
- ClockGate 与运算阵列叶子两侧共用同一份 golden，本目录不覆盖它们的正确性。
