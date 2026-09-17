# xs-v2-sv 重写规范（v1）

## 工程定位
把香山 kunminghu-v2（G1-canonical golden，commit b36a1a2a5 + KunminghuV2Config）的
firtool 生成 RTL 重写成**人可以读懂、用于学习**的 SystemVerilog。

两个硬指标，按优先级：
1. **正确性**：与 golden bug-for-bug 一致。每个模块必须过双重验收（见下）。
2. **可读性**：读代码的人不需要 golden 对照就能理解这个模块在做什么。

## 单文件规范（本轮与上轮 xs-v2r2-sv 的核心差别）
一个 golden 模块 = 一个 `.sv` 文件，文件内从上到下：

```systemverilog
// <Module>.sv — <一句话说明这个模块是什么>
package <module>_pkg;   // 本模块私有类型/参数；仅本文件使用
  ...
endpackage

module xs_<Module>_core // 可读核：真正的重写逻辑，struct/数组/genvar 风格
  import <module>_pkg::*; (...);
  ...
endmodule

module <Module> (...);  // wrapper：端口与 golden 逐位同名，例化 u_core 做展平/改名
  ...
endmodule
```

- **禁止 `.svh` include**（上轮教训：svh 套壳把 golden 原文藏进 include 蒙混）。
- **`import` 必须写在模块头里**（`module M import m_pkg::*; (...);`，或把 import 单独占一行
  放在模块名与端口表之间），
  **禁止写在任何 module 之外**。模块外的 import 属于**编译单元(`$unit`)作用域**，
  而 VCS 默认整个编译是单一编译单元 —— 它会**跨文件泄漏**到所有别的文件。
  2026-09-14 实测（VCS W-2024.09-SP1）：两个文件各在模块外 import 一个包、两个包都
  定义 `IDX_BITS`（probequeue_pkg=3 / writebackqueue_pkg=5）时，VCS **退出码 0、
  0 Error、0 Warning**，两个模块一起拿到排在前面那个文件的值；换文件顺序，值一起翻。
  **UT 和 FM 永远看不见这种错**（它们各编各的文件，第二个包不在场），只有整芯片
  一起编才会有第二个包。由 `scripts/check_pkg_scope.py` 判据 C 把守（含负测
  `scripts/test_pkg_scope_gate.py`，两者都在 `scripts/gate_all.sh` 里）；
  上面那组数字可复跑：`bash scripts/demo_unit_scope_leak.sh`（要 VCS，故不进 gate_all）。
- package 段仅在确有类型/参数共享需求时出现；无 struct/enum 的小模块直接省略
  （空包是噪音）。
- 跨模块共享类型放子系统级公共包：`rtl/<subsys>/<subsys>_common_pkg.sv`，
  数量克制（每个子系统至多一个）。
- **共享辅助件**：不对应任何 golden 模块、被多个核复用的经典结构
  （如树形 PLRU——Chisel 把它内联进各使用者），抽成 `rtl/common/xs_<Name>.sv`
  独立文件（无 wrapper，命名无 `_core` 后缀），一处实现 + 讲透，胜过处处内联。
- 变体家族（如 WrBypass_32/_33、Slice_1/2/3）：一个参数化核文件 +
  每变体一个薄文件（仅 wrapper 设参数），核体绝不复制。
- 机械派生区（大模块端口表/实例连线）由 `scripts/gen_*.py` 生成，
  在单文件内用 `// BEGIN GENERATED(<tag>)` / `// END GENERATED` 标记原地替换，
  手写区脚本不得触碰。

## 可读性规则
- 中间信号一律有语义名，禁止 `_GEN_*`/`_T_*` 残留。
  验收 grep：代码区 `_GEN_|_T_\d` 命中数必须为 0。
- 每个文件头 3~10 行注释说清：这个模块在流水线/子系统里的位置、输入输出的含义、
  核心机制（如"CAM 写旁路，w 命中即改写，否则轮转分配"）。
- 关键状态机/仲裁/指针给一段注释讲清语义；寄存器复位值和 golden 逐一对齐
  （异步/同步 reset、无 reset 三类都照搬 golden，上轮 hpm_timers 异步 reset 踩过坑）。
- 结构上贴近硬件讲法：用 struct 打包总线、数组+genvar 表达对称阵列、
  enum 表达状态，不为省行数牺牲直白。

## 正确性验收（每模块必过，缺一不可）
1. **UT（VCS 双例化）**：golden `<Module>` 与重写 `<Module>_xs`（脚本从主文件派生改名）
   同激励并跑，逐拍比全部输出。seed 1/7/42 各 ≥100k 拍，errors=0。
   ★`+vcs+initreg` 的正确用法（2026-09-17 实测更正）★：
   - **编译期**只写一次 `+vcs+initreg+random`，它的作用是**打开这套机制**；
   - **取值在运行期**由 plusarg 选：`./simv +vcs+initreg+0` 或 `+vcs+initreg+random`
     （本仓即 `make run SIM_ARGS=...`，见 `scripts/ut_common.mk` 的 `SIM_ARGS`）。

   本条原先写成「编译带 …（另一轮 `+vcs+initreg+0`）」，**照字面做会当场拒编**
   （VCS W-2024.09-SP1 实测）：
   ```
   Error-[OBSL_OPT_E] Obsolete option 'vcs+initreg+0' used. Please use
   +vcs+initreg+random at compile time and choose either 0|1|random|<seed>
   at runtime using +vcs+initreg.
   ```
   仓库里其它 UT 用的一直是运行期写法，只有这行文档是错的。

   ★反过来也有坑：**只在运行期给、编译期不给，VCS 会静默忽略**★
   （报 `Warning-[VICIU]` 然后当没看见），**那一轮等于没测**。
   所以两处都要给：`VCS += +vcs+initreg+random`（打开机制）
   与 `SIM_ARGS += +vcs+initreg+$(INITREG)`（选取值）。

   所以「两轮」= **同一个 simv 跑两次**，不是编两次。
   编译带 `+define+SYNTHESIS +vcs+initreg+random`；
   VCS 环境：`VCS_ARCH_OVERRIDE=linux` 必配 `-full64`。

   ★两轮都绿≠复位域正确★：若被测件的可观测行为对上电初值不敏感
   （不复位寄存器都在比较窗口打开前被写成确定值），两轮必然都绿，
   **这时它证明不了任何事**。复位域要靠「结构比对 golden 的 always 块分类」
   + 针对性 mutant（给 golden 没有的寄存器加复位 / 去掉 golden 有的复位）来把关。
   TLBFA 家族实测就是这种情形：两轮全绿，真正拦住 M9/M10 的是复位域结构闸。
2. **FM（Formality 等价）**：golden 为 ref，`<Module>`（wrapper）为 impl，
   要求 native `SUCCEEDED`，failing=0、unmatched=0；unread 点须诊断归零或
   给出对称双射证明（vmucp），禁止 dont_verify / relaxed appvar / 假白名单。
3. 子模块处理：非本目标的子模块两侧同名黑盒配对（同一份不给任一侧）；
   厂商 SRAM 宏（array_*_ext）无条件黑盒。

## golden 引用
- 唯一对照：`/home/eda/xs-env/G1-canonical/golden-rtl/`（只读，禁止写入）。
- G0-canonical 与 xs-v2r2-sv 是上一轮成果，可参考其可读核的写法，
  但**逐字复制前必须对照 G1 golden 确认该模块在 422 个 commit 里没变**。

## 已知环境坑（从上轮继承）
- generate-for 内禁止用 function 捕获模块级信号（仿真返 X），
  路由/选择用显式 assign 或 always_comb-for。
- FM read_sverilog 不支持函数返回值域选 `f(x).value`，拆成独立函数。
- FM 并发：**小模块可高并发**（批跑默认 `--jobs 16`）。实测 676 次 FM 峰值内存
  中位 867 MB / 90 分位 869 MB / 最大 1455 MB，16 并发约 24 GB，本机 125 GB 宽裕；
  Formality license 9999 席不是约束。
  **例外**：整芯片级目标（XSTop 全量 elaborate 实测 9.6 GB/实例）必须单独串行——
  上轮 OOM 事故是 63k 行大模块并发造成的，教训适用于大模块，不适用于小模块。
  禁 `pkill -f`（会误杀其他任务的 simv）。
- chisel Vec 越界读语义是回绕不是 0（上轮 LoadQueue replay 真 bug 根因）。
  ★本轮实测更正：G1 的 firtool 把越界项展开成**填第 0 项**，不是回绕。★
  而且**同一模块里不同信号的越界语义可能各不相同**（BusyTable 实测三种：忙位
  `table>>req` 得 0、loadDependency 走 256 项表高位填第 0 项、分配旁路全宽比较不看越界）。
  **按「没查到就是 0」写就是真 bug**，逐个从 golden 读。

## ★Formality elaborate 的四条硬约束（只能改 RTL，不能压消息）★

这四条都会让 `set_top` 直接失败，跑都跑不起来。它们是**工具的解析/展开能力边界**，
不是 RTL 有 bug，但修法只有一条：**改 RTL 去迁就它**。用
`set_mismatch_message_filter` 之类把消息压掉，等于把证明做空了。

| 消息 | 触发形状 | 修法 |
|---|---|---|
| `FMR_ELAB-147` | `arr[cond ? idx : 0]` —— FM 不传播范围保护，认为下标可能越界 | 把守卫提出来，先算下标再索引 |
| `FMR_VLOG-091` | function 读模块级信号 | 改成纯函数，需要的信号走形参 |
| `FMR_VLOG-144` | 异步复位块里第一条语句不是 `if`（FM 认不出这是复位） | 把 `if (reset)` 提到块首 |
| `FMR_ELAB-268` | **循环超过最大展开次数**，后续报 `FM-156` | 见下 |

`FMR_ELAB-268` 是 2026-09-17 TLFIFOFixer 实测新加的一条：

```systemverilog
// ✗ 12,288 个标量，复位要逐位写 → 循环展开超限，set_top 失败
logic flight [END_SOURCE_ID];
for (int i = 0; i < END_SOURCE_ID; i++) flight[i] <= 1'b0;

// ✓ 压缩向量，复位一句话，没有循环
logic [END_SOURCE_ID-1:0] flight;
flight <= '0;
```

顺带一提这个改法**同时更好读**：分组忙判断也从 128 次 `|=` 循环变成
`|flight[g*GROUP_SIZE +: GROUP_SIZE]`，"这组有任意一位在飞"一眼可见。
所以遇到 ELAB-268 先想「是不是本来就该用压缩向量」，而不是想怎么绕开工具。

## ★验证件自身的两个坑（2026-09-17，两条 lane 各自独立踩到）★

### 1. 变异体必须先自证「改变了电路」

本轮有 **3 条 lane** 发现自己的负测是空的，跟了整轮 `errors=0` 差点报成「UT 漏检」：

- **同一变量被两个 `always_ff` 驱动**：把 `x <= '0` 加进另一个复位块，VCS **不报错不警告**，
  排在后面的块赢，**变异根本没生效**（SSIT / RenameBuffer 各踩一次）。
  真变异要写在**原块之内**。
- **把 `N'(…)` 套在同宽度的目标线外面**，等于没改电路（DecodeUnitComp）。改成真正加宽后
  同一变异抓到 721 个 error。
- **变异后编译失败而 harness 读到上一轮的 `sim_*.log`**，把上次的 `errors=0` 当本次结果
  ⇒ 报出假的「逃逸」（SSIT）。harness 每次必须先删日志。

**规矩**：注入后要么确认 RTL 文本真的变了且能编过，要么让 harness 在编译失败时**判 FAIL 而不是继续**。
另：`CAUGHT` 不是二值——**报出每个变异的 errors 数**。本轮实测 `485` 与 `1,387,450` 都算 CAUGHT，
但前者换个 seed 就可能漏。余量薄的要点名，不许报成「判别力均匀」。

### 2. 过程块里声明的变量是 **static**，初始化式只在 0 时刻执行一次

```systemverilog
always @(posedge clk) begin
  int kind = $urandom_range(0,3);   // ★整场仿真恒定★，不是每拍重掷
  logic [4:0] hv = 5'd31 - $urandom_range(0,6);
end
```

**两条 lane 独立踩到同一个陷阱**：

- TLBFA：`kind` 恒定 ⇒ seed 1/42 抽到「hv&hg 同置」，5906/6049 次 fence 事件 **100% 是同一种**，
  整轮**只测了 hfence.gvma**，sfence.vma 与 hfence.vvma 一次没发 —— 而三轮都照样 `errors=0`。
- DecodeUnitComp：`hv` 恒定 ⇒ 整场 vd 是同一个常数。

**规矩**：过程块里凡是带初始化式的声明一律加 `automatic`；tb 里的 function/task 也一律 `automatic`。
检查手段是**报覆盖计数**——上面两例都是覆盖分桶全压在一个值上才暴露的。

## ★继承来的数字与断言，第一次引用时必须重新测量★（2026-09-17，一天里四例）

本仓有大量从上一轮 `xs-v2r2-sv` 整段抄过来、或从别处转述而来的注释、判据与说明。
它们在被抄的那一刻是对的，此后**没人对着这棵树验证过**。今天一天就撞到四个，
形态完全相同，值得单列成一条规矩。

| 陈述 | 实际 | 后果 |
|---|---|---|
| SSIT 判据「passing 必须 +3073」 | 实测 `0 -> 14525`，差 4.7 倍 | 复核的人看到对不上，要么惊慌、要么学会无视判据 |
| 「diagnostic-full 由 `fm_eq_full.tcl` 承担」 | 本仓**没有**这个文件，且该 mode 不在 switch 里 | 按文档写的调用方式 `exit 3`，端到端跑不通 |
| 「新加的生成器自动进闸」 | 那段是**手工列举文件名**的 for 循环 | 3 个支持 `--check` 的生成器一直在闸外 |
| Entries 判据里的 `12196` | 是**预测值**不是测量值 | 差点被当成回归基线 |

**规矩**：
1. 任何被抄进来的数字，在本仓第一次用它做判据之前，先跑一次把它量出来；
   量出来的值与抄来的不一致，**先查清楚为什么，再改写判据** ——
   不许因为"实测比预期好、方向没错"就放过去（SSIT 那条差 4.7 倍，
   查清是两个数在数不同的东西，不是加强空转）。
2. 任何指向某个文件/工具/开关的注释，写的时候 `ls` 一下它在不在。
3. 任何说"自动/一律/全部"的注释，看一眼它描述的那段代码是不是真的做到了。
   手工列举的清单永远会漏，要么改成自动发现，要么加一道**完备性闸**
   （`scripts/check_gen_gate_complete.py` 就是为此写的）。

判据的价值在于**事前承诺、事后对账**。一条对不上的判据比没有判据更糟：
没有判据时人会去查，判据对不上却被放过时，人学到的是判据可以无视。

## 可读性验收（与 FM 同等地位，须常态化跑）

`python3 scripts/readability_audit.py`，非零退出即不合格。检查项：

- **A 代码区禁用命名**：`_GEN_*` / `_T_<n>` 等 golden 展平中间名不得出现在代码区。
  注释里作为"对应 golden 哪根线"的交叉引用是允许的（那对读者有用），故按去注释后判。
- **B 文件头**：首行须是注释，头部注释块 ≥3 行，说清这个模块是什么、在哪一层、核心机制。
  变体薄文件也要说清**本变体的参数与规模**，不能只写一句"是某家族的变体"。
- **C 头注释与内容自洽**：头里列的模块必须真在本文件里；不得引用已不存在的文件
  （单文件规范下 `<X>_wrapper.sv` 已并入，再提就是误导读者）。
- **D 单文件结构**：模块顺序 package → `xs_*_core` → golden 同名 wrapper。
- **E 大文件导航**：>1500 行的文件**不拆**（用户裁定：保持"一个 golden 模块一个文件"），
  但必须带「本文件导航」——列出各分节的行号与标题，让读者不必滚两千行才知道里面有什么。
  导航由 `scripts/gen_file_nav.py` 从**真实分节**生成（改动后重跑即可刷新），
  审计会校验每条导航的行号确实落在一条分节注释上；导航一旦腐烂就成了误导，判失败。

**教训（2026-09-12）**：可读性是本工程两个硬指标之一，但前若干轮全部精力在证明基础设施上，
上百个机械继承/生成进来的文件从未复查。一次性补审发现两类系统性缺陷：
48 个文件头只有一行（生成器只发"自动生成"字样，等于没说）、6 个变体文件整段复制了家族头
（读者打开 `_1` 会看到一串本文件根本没有的模块清单）。两类都已修，且生成器本身已改，
不会再产出这种文件。**结论：可读性必须和 FM 一样有可机器复跑的闸，否则一定会被工程压力挤掉。**
