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
- FM 并发：**小模块可高并发**（批跑默认 `--jobs 16`）。上一轮实测 676 次 FM 峰值内存
  中位 867 MB / 90 分位 869 MB / 最大 1455 MB，16 并发约 24 GB，本机 125 GB 宽裕；
  ★2026-09-17 复测更正上沿★：`1455 MB` 这个最大值**已被本轮超过**，按 `fm.log` 的
  `Maximum memory usage` 逐个量（不是 `ps` 的 RSS）：
  `Predictor 34434` / `Composer 4653` / `Ftq 4047` / `ArrayMulDataModule 1948` /
  `DecodeUnitComp 4182`（三轮并行跑都是 4182，不是并发挤出来的）/
  `IBuffer 1660`（三次独立跑 1660/1662/1660，不是抖动）/ `SbufferData 1599` /
  `TLFIFOFixer 1592`。也就是说"最大 1455 MB"只对**叶子**成立，
  上了 Composer/Ftq 这一档就是数 GB，Predictor 这种带整棵预测器子树的是 **34 GB**。
  估并发度前先看目标属于哪一档，别拿叶子的中位数去估大件。
  ★**867 MB 是地板值，不是测量值**★（2026-09-17 全仓统计，SnapshotGenerator lane 提醒后我查的）
  把所有 evidence 日志里的 `Maximum memory usage` 拉出来数：

      867 MB  出现 2675 次      868 MB  4 次
      869 MB     77 次          872 MB  44 次

  也就是说 **`867` 是 Formality 启动期的高水位**，报 867 的目标意思是
  "它自己用的内存低于这条地板"，**不是"它用了 867 MB"**。
  所以：
    · 一个目标报 867，**不能**据此说它比报 869 的那个更省；
    · 本文件和各 lane 报告里凡是引用 867 的地方，都只能读成"小于地板"；
    · 要做规模趋势，只有明显高于地板的那些数（1599 / 1660 / 1948 / 4047 / 4182 / 4653 / 34434）可用。
  Formality license 9999 席不是约束。
  **例外**：整芯片级目标（XSTop 全量 elaborate 实测 9.6 GB/实例）必须单独串行——
  上轮 OOM 事故是 63k 行大模块并发造成的，教训适用于大模块，不适用于小模块。
  禁 `pkill -f`（会误杀其他任务的 simv）。
- ★**共享 scratchpad 里禁止 `rm -rf` 语义名**（2026-09-17 实际发生过一次）★
  `/tmp/claude-1000/<session>/scratchpad/` 是**整个 fleet 共用**的，不是某条 lane 独占。
  一条 lane 建诊断目录时写了 `S=.../scratchpad/fmneg; rm -rf $S; mkdir -p $S/...`，
  把**另一条 lane 正在跑的** `scratchpad/fmneg/verif/ut/RenameBuffer` 整棵树删掉了。
  进程当时还活着，但它持有的每个 fd 都成了 `(deleted)` —— 还在算，
  算完写进的是已 unlink 的 inode，**磁盘上不会留下任何证据**。
  （那一跑的 fm.log 后来从 `/proc/<pid>/fd/1` 捞回来了，但 `receipt.json` /
  `unread_points.txt` / `sidecar/` 这些收尾时才写的文件救不回来 —— 只能重跑。）

  **规矩**：共享 scratchpad 里只许 `mkdir -p` 自己带**唯一后缀**的目录；
  要清理，作用域必须由**你自己创建的唯一标识**界定，不能由语义名界定。
  通用名（`fmneg` / `work` / `tmp` / `out` / `diag`）一律视同他人领地。

  和禁 `pkill -f` 是同一条判据的两面：**破坏性操作的作用域不能由"看起来是我的"来界定。**
  同一条判据当天撞到**三次**，列在一起才看得清：

  | 场景 | 错误判据 | 正确判据 |
  |---|---|---|
  | `pkill -f` | 命令行**看起来**像我的 | PID 确实是我起的 |
  | `rm -rf <语义名>` | 目录名**看起来**像我的 | 路径带我自己造的唯一标识 |
  | `/tmp/xsv2-proof-*` | **看起来**像残留垃圾 | `/proc/<pid>/cwd` 有没有进程在用 |

  第三行是真事：一条 lane 报告里写「看起来是同一个脚本留下的垃圾我也不动」，
  而那两个目录里正跑着 Predictor（已 2 小时 10 分）和 NewDispatch 的证明。
  它结论对、判据错。

  ★它自己点出的那句最要紧★：「不动」如果是**保守习惯**而不是**结论**，
  就会被"这次情况不一样"说服 —— 目录再脏一点、手头再赶一点，
  "看起来像垃圾"随时能翻成"确实是垃圾了"。**判据要能被复核，习惯不能。**
  查活性的现成写法：

      for p in $(pgrep -x fm_shell_exec); do readlink /proc/$p/cwd; done | grep <路径>

  注意用 `pgrep -x`（按可执行名精确匹配）。`pgrep -f 'simv|fm_shell'` 会匹配到
  **执行这条命令的 shell 自己**（它的命令行里就含那两个字符串），于是你数的是自己 ——
  这个自匹配当天也有两处实例。

## ★当 FM 的配对可疑时，换一个独立的观测手段★（RenameBuffer 实测）

FM 报了 20 个 failing、集中在 `buffer_q_reg[255]`，看起来像"最后一项/回绕"的边界 bug。
但当时**配对本身就是可疑的**（3 个未配对寄存器成了自由割点），
这时再拿 FM 的结论去判断 RTL 对不对，是用可疑的中间结果做推断。

lane 的做法：写一个探针 tb，把两侧 `enqPtrVec` 的 6 个 value + flag **每拍 force 成
同一组任意值**，再逐拍比对 256 项缓冲表的**全部内容**；四种压力模式各占 25% 拍
（全随机 / 全挤 0..3 造指针撞车 / 全挤 250..255 打末项与回绕 / 全挤 172..178 打 175）。
3 seed × 3000 拍 `buffer_mismatch=0` ⇒ **缓冲表写逻辑与 golden 等价**，
那 20 个 failing 是配对残缺的下游产物。后来关掉 `FM_MERGE_DUP` 证实了这一点
（`failing 20 -> 0`）。

★适用边界（lane 自己划的，照抄）★：这个探针能成立，是因为 `buffer_q` 的次态
**只依赖 `req` 与 `enqPtrVec`**，才能把被测锥体的全部自由输入都 force 到手里。
换一个次态依赖大半个模块状态的寄存器，force 的代价迅速逼近"重写一遍 golden"，
那就不如再跑一轮 FM。**判据是「被测锥体的自由输入能不能被我完全控制」，
不是「FM 可疑就上探针」。**
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

### ★闸的负测必须是双向的：会报警 **和** 不会误报，缺一不可★（2026-09-17，四次拦住同一个工具）

变异体那条规矩说的是「变异必须自证改变了电路」。**闸有对称的一条，而且更容易漏**：

> 一个**恒报警**的闸能通过「该报警时报了警」这一半负测。
> 只有再加一半 —— **不该报警时不许报警** —— 才能把它逼出来。

实测：一条 lane 写跑前可证性检查（找 impl 侧常量驱动的控制输入、
判断它门控的次态锥），按双向负测做，**v1~v4 四个版本全是恒报警的闸**，
两边都报 10~12 个。每一版的根因都不是想出来的，是被"两边都报"顶出来的：

| 版本 | 根因 |
|---|---|
| v1 | 没跨实例端口传播常量（外面叫 `unresolved_X`、核里叫 `X`）⇒ 切断边检出 0 条，判定压根没用到那个变量 |
| v2 | 图里没有**控制依赖**（信号只出现在 `if` 条件里、不在右值）⇒ 整条链断 |
| v3 | 赋值正则按行首锚定 ⇒ `for (...) cnt += ...;` 一行里捕到的是 `for`，边丢了 |
| v4 | LHS 下标不支持嵌套 ⇒ `a[l][IQ_OF[k]]` 匹配不上，一条边丢了 |

★v1 最危险★：它报出的 12 个里**包含了正确的 10 个** —— **答案对、理由全错**。
lane 的原话：「只看结论我会直接收工。」

**规矩**：新写任何判定/闸/检查，负测必须两个方向都造：
  · 造一个"该报"的样本，确认它报；
  · 造一个"不该报"的对照，确认它**不**报。
只做前者等于只验证了"它会响"，而一个 `return True` 也会响。
配套：★**新写的闸第一次跑就全绿（或全红），本身就该触发怀疑**★
（同日另一条 lane 的 `(cond, cond)` 恒真核对就是这么混过去的）。

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

### ★上面这条只管 tb，别拿去管 RTL —— 在 `always_ff` 里恰恰相反★

★这两条规矩方向相反，作用域不同，必须一起读★：

| 场景 | 规矩 | 违反的后果 |
|---|---|---|
| **tb** 的过程块 | 带初始化式的声明**必须** `automatic` | 静态变量只在 0 时刻初始化一次 ⇒ 激励恒定、覆盖全压一个桶 |
| **RTL** 的 `always_ff` | **不要**在里面放 `automatic` 临时量 | FM 把它们推成**伪寄存器** ⇒ 成批 impl-only 未读比较点 |

RTL 那一侧的量级实测（NewDispatch，2026-09-17）：

    一个 6x17 的双重循环里 4 个 automatic 临时量
        -> 493 个 impl-only 未读比较点
    （lanes_reg 432 / single_reg 37 / idx_reg 18 / multi_reg 6）
    UT 全绿、elaborate 0 warning、只有 FM 看得见；移进 always_comb 之后 493 -> 0

**4 个临时量换 493 个点**这个比例才是重点 —— 它说明这不是"就这一个图方便"的事。
写法：把中间计算移到 `always_comb`（或直接写成 `assign`），`always_ff` 里只留寄存器赋值。

★这条本身就是"教训写在错的作用域"的又一例★：原来只有 tb 那一条，
读的人很自然会把「一律加 `automatic`」带进 RTL。规矩必须自带作用域，
否则它在别处就是反的。

## ★看起来冗余的重复结构，一份都不许少★（2026-09-17，一天里四例、三个方向）

FM 的配对是**按结构**做的。任何一侧比另一侧「少一份」都会产生孤儿点，
而未配对的比较点在 FM 里是**自由割点** —— 它不只是自己不被证，还会让下游跟着失配。
所以"值反正一样、合并掉更好读"这个念头，在本工程里是错的三次里最贵的一次。

同一件事有**三个方向**，今天各撞到了：

**方向一：自己把 golden 的多份合并成一份**（Entries canary，846 failing）
golden 给**每个 enq 条目各打一拍** `og0Cancel` / `ldCancel`
（`Entries.scala` 的 `RegNext` 在 `for (entryIdx <- 0 until EnqEntryNum)` 内），
展平后是两套同源寄存器 `REG_0/2/4/6` ↔ `REG_2_0/2_2/2_4/2_6`，逐位恒等。
可读核合并成共享的一份 ⇒ FM 把这一份配给了 enq0 那套，**enq1 那套 globally unmatched**。
四个现象一次解释完：`enqEntries_0` 干净、`enqEntries_1` 起全错、
846 全错无一对、只在延迟窗口激活时出现。**仿真按构造永远看不见**（值一直相同）。

**方向二：让工具去合并**（RenameBuffer / MulUnit）
`verification_merge_duplicated_registers=true` 会把函数相同的寄存器合并，
而**两侧合并结果可能不一致**：
  · RenameBuffer：`bit1(v+1) == bit1(v+5)`，ref 合了 impl 没合 ⇒ 3 个孤儿 ⇒ 20 failing。
    关掉之后 `passing 651 -> 5825`、`failing 20 -> 0`、`unverified 5147 -> 0`。
  · MulUnit：31 个粘滞常数 impl 合了 ref 没合 ⇒ 29 unmatched。关掉后 `unmatched 29 -> 0`。
  处置都是 `FM_MERGE_DUP = false`（per-UT Makefile 变量）。
  **这是加强不是放宽**：不黑盒、不跳点、不约束 ref，只是要求逐个而不是合并后比。

**方向三：把 golden 的冗余"优化"掉**（TLBFA / RenameBuffer）
  · TLBFA：把 `req_vpn_q` 从 38 位收窄到 27 位（高 11 位确实没读者）——
    那 11×PORTS 位会从**两侧对称死位**变成 **golden-only 死位**，连双射都没有，更难签。
  · RenameBuffer：把 `deqPtrVec` 收窄成只留 head（1..5 号确实没读者）—— 同上，45 位变 golden-only。
  照抄 golden 的宽度/份数才是对的。

**一句话**：`golden` 里凡是"看起来没用、看起来重复"的东西 —— 不可达状态的行为、
不复位的位、没人读的寄存器、值恒等的多份打拍 —— **照抄都比优化掉便宜**。
理由见上一节：你论证"没用"用的是可达性/可观测性，而 **FM 不做可达性分析**。

### ★但这条规则的边界要说清：它管的是"自由变量"，不是每一个内部信号★

（2026-09-17，RRArbiterInit lane 用一对变异把边界两侧都量了出来 ——
**它证伪的是它自己先前写下的注释**，那条注释和本节的说法一致。）

FM 的自由变量只有两类：**寄存器** 和 **输入端口**。
由逻辑内部导出的信号，取值域由逻辑本身决定，FM 推得出来：

| 对象 | 是不是自由变量 | 实测 |
|---|---|---|
| `chosen`（由仲裁逻辑算出，位宽 `$clog2(N)`） | **否** | 变异 F3 改它的补位取值 ⇒ **FM 判等价 SUCCEEDED failing=0** |
| `lastGrant`（寄存器） | **是** | 变异 M7/F1 改它的复位方式 ⇒ **UT errors=0 / FM failing=2** |

所以：
* 在**寄存器**和**输入端口**上"化简不可达/非法取值" ⇒ FM 会抓，照抄是**必须**的；
* 在**内部导出信号**的不可达补位上照抄 ⇒ 是**零成本的忠实**，不是 FM 逼的。

两者都该照抄（忠实本身就是本轮的目的），但**理由不同**，
别把"FM 会抓"当成所有照抄的理由 —— 那会让人以为凡是 FM 不抓的就可以动。

**方向四：在"非法输入编码"上化简**（Entries canary，192 failing）
★这一种最反直觉：输入端口在 FM 里也是自由变量★

    golden 输出侧: dataSources_value[3]        （位测试）
    golden 寄存器更新侧: == 4'h2               （相等比较）
    可读核: 两处都写成相等比较                   ← 把 golden 的不对称"抹平"了

`DataSource` 只定义了 16 种编码里的 7 种，bit3 在合法集合里只由 `reg=4'b1000` 置起，
所以两种写法**在每一个合法值上都等价**，只在 `4'b1001..4'b1111` 上不同。
tb 只会驱动合法值,仿真**按构造**永远分不出来（600k 拍 `errors=0`）；
而 `dataSources_value` 是一个**裸 4 位输入端口**，FM 对全部 16 个取值都要证 ——
于是失配点数正好等于 `io_dataSources` 的全部输出位：**192**。

所以"FM 量化的范围比现实大"有**三种**来源，别只记住第一种：

| 自由变量 | 现实里受什么约束 | 实例 |
|---|---|---|
| 寄存器 | 可达状态 | DecodeUnitComp X1/X2（不可达状态） |
| 寄存器 | 复位/无读者 | walkPtr 复位、reqVpn 高位、deqPtrVec 1..5 |
| **输入端口** | **上游只产生合法编码** | **Entries 的 dataSources_value** |

第三种最容易漏，因为"输入是别的模块驱动的"这个直觉会让人以为它不自由。
**在本层看，输入端口就是自由变量；上游的约束在本层的证明里不存在。**

★而且 golden 在这件事上是**故意不对称**的（输出侧位测试、更新侧相等比较）★
—— 这已经是同一条 lane 第三次把 golden 看起来像噪声的不规则抹平了
（前两次：合并 enq 打拍寄存器、合并 og0/ld2 两套同源寄存器）。
用它自己的话：**"我又一次把一个看起来像噪声的不规则给磨平了"**。

**方向五：给 golden 没有的地方"补上"对称**（Predictor，17 failing / 4h40 一轮）
★这一例最值得记，因为 golden 的不对称是**有理由的**，而理由就写在 Chisel 源码里★

`update pc` 分三段打拍，golden 只给高两段加了"值变了才打拍"的比较器，
**最低段没有比较器、每拍无条件打**：

    golden Predictor.sv:1342-1344   modified_2 = 1'h1        // 恒真
    utility/ClockGatedReg.scala:210 modified.last := true.B  // Assume lower part often changes

低位段本来就几乎每拍都变，比较器省不下翻转、反而白花一个比较器 —— 所以 golden 故意不放。
可读核"顺手"把三段写成一致的 `if (值变了) 打拍`，**功能完全等价**，
但两侧那一位落进了**不同的 FM 类别**（ref 侧 `seg_2_value_reg[0]` 进 unread、
impl 侧 `upc_seg2_reg[0]` 进 compare），**FM 不跨类别配对** ⇒ 该寄存器成为未配对点
⇒ 在下游锥里变成两个互不相干的自由变量 ⇒ 共享的 `Composer` 里
17 个 `..._io_update_pc_..._reg[0]` 全部失配。

**教训**：看到 golden 三处里有两处做了某件事、第三处没做，
**第一反应应该是"去查为什么"，不是"把第三处补齐"**。
这一例的理由甚至写在 Chisel 注释里，查一下就能看到。

★还有一条关于"教训写在哪一层"的教训★
Entries 那条 lane **早就把「值恒等 ≠ 可证等价、别合并看起来冗余的结构」写进了自己核的
§11 注释** —— 写在**条目级**；然后在自己新写的**阵列级**上犯了同一个错。
经验写对了、写在了错的作用域，等于没写。新写一层结构时，
要把已有的教训**逐条对着新这一层重问一遍**，而不是假定它已经被覆盖。

## ★UT 与 FM 的分工：不可达状态与复位域归 FM 管★（2026-09-17，三个实测实例）

**Formality 把寄存器当自由变量，默认不做可达性分析。** 这一条决定了两件事：

1. **重写必须连不可达状态、连复位域都逐字照抄 golden** —— 不是洁癖，是 FM 判据的
   直接推论。在死状态上替 golden 补一层门控、或替它化简掉一层冗余门控，
   **UT 一声不响，FM 当场 failing**。
2. 变异体表里的 `EXPECTED_MISSED` 应当读作
   **「UT 观测不到（可达性所限），由 FM 兜底」**，不是「没人管，只能靠照抄自觉」。
   它标的是**换了一道闸**，不是没有闸。

三个实例都是实测，不是推理：

| 改动 | UT | FM |
|---|---|---|
| DecodeUnitComp X1：给 `out_valid` 加 state 门控 | 40k 拍 `errors=0` | **failing 6**（恰好 `io_out_complexDecodedInsts_0..5_valid`） |
| DecodeUnitComp X2：去掉 `complexNum` 的 state 门控 | 同上 `errors=0` | **failing 3**（恰好 `io_complexNum[0..2]`） |
| RenameBuffer (c)：给不复位的 `walkPtr` 加复位 | 20k 拍 `errors=0` | **9 个点全 failed** |
| SnapshotGenerator 同型对照：给 4 个不复位快照槽加复位 | 能抓（`errors=201`） | 基线 SUCCEEDED → 注入后 20 failing 全落在 `snapshots_*` |

### ★"UT 为什么结构上看不见" —— 一句话说清（Entries canary，1030 -> 0）★

Entries canary 最终定位到**三个**缺陷，全部同一个物种：**golden 的不对称被当成噪声抹平**。

| | 可读核写的 | golden 实际 | 仿真可见？ |
|---|---|---|---|
| 延迟打拍寄存器 | 共享一份 | **每 enq 条目各一份**（同源、逐位恒等） | 否（值一直相同） |
| `ld1Cancel` 项 | 保留（`c1` 走寄存器） | 该变体**不存在**这一项 | 否（`c1` 恒 0） |
| `dataSources` 输出 | `== DS_REG` | **`value[3]`** 位测试 | 否（只在非法编码上分歧） |

三者共同点：**在合法/可达的输入范围内完全等价**。
所以 3 seed × 2 initreg × 200k 拍、23 个覆盖闸全非零，仍然 `errors=0`。

★所以"UT 看不见"的正确说法不是"激励不够密"，而是★

> **这类差异在仿真的输入分布里根本不存在。**

加密激励、加长跑程、加覆盖点，一个都没用 —— 因为要触发它们需要的是
**仿真按构造不会产生的输入**（非法编码、不可达状态、恒 0 的信号取 1）。
而 FM 在全取值域上逐点比，所以看得见。

这条是本节四个方向（不可达状态 / 死位 / 非法输入编码 / 值恒等的多份结构）的共同底。
**判断一个差异 UT 能不能抓到，问的不是"我的激励够不够"，
而是"要触发它需要的输入，仿真产生得出来吗"。**

★两条做法上的要求★

* **对照组是硬前提**：base（未注入）必须 `failing = 0`，否则注入后的 failing
  证明不了是注入造成的。上表两组都做了。
* **比较点守恒可以当交叉验证**：DecodeUnitComp 实测 `3157 = 3151 + 6 = 3154 + 3`，
  失败点是从 passing 里扣出来的、不是凭空多出来的点。
  更进一步，穷举出的**反例状态数**（X1 747 / X2 127）与 FM 的**比较点数**（6 / 3）
  通过"每个输出位是否存在反例"严格对应，逐位闭合 —— 所以不是"大概落在那条通路上"。

一个具体例子说明"照抄不对称"的必要：DecodeUnitComp 的 golden 自己就是不对称的
（`complexNum` 有 state 门控、`out_valid` 没有，**两层都是冗余的**）。
照抄这份不对称是唯一能过 FM 的写法；把两边"统一"成任何一种都会 failing。

## ★进 fm.log 的字必须是 ASCII★（2026-09-17，两条 lane 各自独立发现）

`Formality` 的 `fm.log` **不是 UTF-8**。钉点脚本里的中文 `puts` 落进日志全成问号：

```
TLBFA_PINS: ?? 33 ? reqVpn ???ref 33 / impl 33??????
RENAMEBUFFER_PINS: ?? 51 ??A deqPtr flag 5 / B deqPtr value 40 / ...?
```

**日志是给 reviewer 看的证据**，自报里说了什么、钉了几族、判据是什么，
全都看不见了。注释留中文没问题（读的是源文件），但**凡是会进 `fm.log` 的
`puts` 一律 ASCII**。

一句要说清的：这件事**不影响判定**。判定用的数字（`Unmatched ... 0(0)`、
`Verification SUCCEEDED`、比较点表）都是 Formality 自己打的 ASCII，
乱码的只有 lane 自己的自报。但自报正是"给人看的那一半证据"，
写了等于没写比没写更糟 —— 它让人以为这里有说明。

实测受影响（`git ls-files "verif/ut/*/fm_pins*.tcl"` 里 `puts` 带非 ASCII 的）：
`Ftq` 1 行 / `IBuffer` 6 行 / `ICacheMissUnit` 1 行 / `SSIT` 1 行 / `TLBFA` 9 行。
**改这些文件会改变它们的 sha256，而 receipt 里记着 `pin_scripts` 的哈希** ——
所以不要为了改乱码单独去动已签绿的脚本，**等这些目标下次因为别的原因重跑时一并改**。
（已核：仓库里没有任何闸拿 receipt 的 `pin_scripts` 哈希去比当前文件，
所以现在不改也不会让闸变红；这是"何时改"的问题，不是"改不改"。）

## ★别拿裸错误号当判据★（2026-09-17，我自己写的注释就是祸首）

`fm_shell` 会把 `-file` 载入的入口脚本**逐行回显进 fm.log，注释也不例外**。
所以只要有人在 `scripts/fm_eq.tcl` 的注释里提一句某个错误号，
`grep -c "<错误号>" fm.log` 从此对**所有目标**永远 `>= 1`。

实际发生过：我在 vmucp 白名单注释里写了一条判据「`FM-036 = 0`」，
那行注释自己一进 fm.log，这条判据就永远为假。实测六份 evidence 日志：

    grep -c  "FM-036"      fm.log   ->  1   ← 全是那条注释的回显
    grep -cE "^ *Error:"   fm.log   ->  0   ← 真实情况

**规矩**：判据必须钉在**行首的 `Error:`** 上（`grep -cE "^ *Error:" fm.log` 为 0），
不能钉在裸错误号上。同理适用于任何"日志里出现某字符串就算出事"的判据 ——
**入口脚本的注释会出现在日志里**，所以凡是能被注释命中的模式都不是判据。

这和 `test_tcl_no_poison.py` 防的是同一类事，区别在于那道闸盯的是 `fm_verdict.py`
的正则，而这次中招的是**人手写的判据**——闸没覆盖到的那一半。
我今天还因为同一个机制踩过一次：监控脚本匹配到了 `fm_eq.tcl` 里被回显的注释，
误判成跑完了。**两次同源，一次在工具、一次在判据。**

第三例（2026-09-18，Entries lane 独立撞上，与前两例无沟通）：
想用 `grep FM_MODE_ERROR fm.log` 提前判断 vmucp 白名单有没有生效——

    grep -c   "FM_MODE_ERROR"    fm.log   ->  6   ← 全是脚本自己 puts 的回显
    grep -cE  "^FM_MODE_ERROR:"  fm.log   ->  0   ← 真实情况

同一个机制在一天之内被三个互不相通的人踩到，说明它不是个人疏忽而是**日志形态的固有陷阱**。
连带一条更要紧的结论：那次真正想问的是"要不要提前 44 秒放弃这轮"，
而这个问题**grep 日志根本答不了**——权威读数只有跑完之后 sidecar 里的 appvar 回读。
拿日志里的字符串去猜配置是否生效，方向本身就是错的。

## ★`fm_shell -file` 脚本报错时**不会退出**，它会挂在交互提示符上占着 license★（2026-09-18 实测）

一个 probe 脚本的第 12 行写错了（`report_unmatched_points -point_type unread`，
没有 `-point_type unread` 这个选项），`fm_shell` 报完错就**掉进交互提示符一直等 stdin**。
结果是：报告文件早就写完了，日志停在错误处再也不动，进程却一直活着。
它就这么占了一个 Formality license **48 分钟**，直到被发现。

### 为什么监控看不出来
- 看日志 mtime：日志 47 分钟没变 —— 但"跑大件时长时间不写日志"是正常的，区分不出来。
- 看进程在不在：在。
- **唯一能区分的是 CPU 增量**：`/proc/<pid>/stat` 第 14+15 域，这个挂死的进程
  47 分钟里只涨了 **207 tick ≈ 2 秒**，而同时在跑的 Predictor 是 208706 tick（35 分钟满载）。
  这正是「三层判活」里第三层的用处 —— 别看日志 mtime，看 CPU。

### ★量哪个进程：必须量 `fm_shell_exec` 子进程，不是 `fm_shell` 父进程★
`fm_shell` 是个 `/bin/sh` 壳，它把活全交给 `fm_shell_exec` 子进程，**父进程的 CPU 增量恒为 0**。
拿父进程判活会把正在满载计算的 run 判成挂死。DelayReg lane 实测同一时刻的 Predictor：

    fm_shell      pid 688875   20 秒增量 0          ← 父壳，永远是 0
    fm_shell_exec pid 688916   20 秒增量 1992 tick  ← ≈100%，这才是真状态

所以定式是 `pgrep -x fm_shell_exec`，再对它读 `/proc/<pid>/stat`。
（上面那个挂死的 207 tick 量的正是 exec 子进程，所以那次判断成立。）

### 修法与双向实测
在所有 `fm_shell` 调用上加 `< /dev/null`（`scripts/ut_common.mk` 的正式路径已加）。
同一个必错脚本，两种 stdin 各跑一次：

| stdin | 行为 | rc | 日志结尾 |
|---|---|---|---|
| 保持打开（前台/管道） | **永不退出**，90 s 后被 `timeout -s KILL` 杀掉 | 137 | 停在错误处 |
| `< /dev/null` | 44 秒正常退出 | **1** | `Thank you for using Formality!` |

`< /dev/null` 不只是堵泄漏 —— 它把"无限挂起"变回了**rc 非零的可见失败**。
挂起是最坏的失败形态：它既不报错也不结束，还伪装成"还在跑"。

复现：
```
cat > err.tcl <<'T'
puts "BEFORE_ERROR"
report_unmatched_points -point_type unread > /dev/null
exit
T
( sleep 400 | timeout -s KILL 90 fm_shell -64 -work_path wA -file err.tcl > a.log 2>&1 )  # rc=137
timeout -s KILL 90 fm_shell -64 -work_path wB -file err.tcl < /dev/null > b.log 2>&1      # rc=1, 44s
```

注意 `scripts/fm_eq.tcl` 全文只有末尾一句 `exit`，中间任何一行出错都走这条挂死路径。
正式路径此前没炸，只是因为后台跑时 stdin 恰好是 `/dev/null`——**靠的是巧合，不是设计**。

## ★工具派生态（scratch）不许进版本控制，而 `.gitignore` 单独挡不住★（三例，第三例推翻了前两例的修法）

| # | 产物 | 体量 | 为什么没拦住 |
|---|---|---|---|
| 1 | 仓库根 `FM_INFO/` | 53 KB / 9 文件 | 规则 `/FM_INFO*/` 是它**进库之后**才加的；ignore 对已跟踪文件完全无效 |
| 2 | `verif/ut/EntriesAluCsrFenceDiv/fm_diag{,2..7}/` | **994807 行 / 77.8 MB，占该分支插入行数的 86.4%** | 老规则按**固定深度**写死：`verif/ut/*/fm_shell_command.log*` 只管 UT 目录直下，这些文件深了一层 |
| 3 | `verif/ut/NewPipelineConnectPipe/neg_build/` | 12 文件（含 VCS `.daidir` 二进制库树） | ★**规则早就在了**（`verif/ut/*/neg_build/` 加于 d61c00b，先于提交 5336c49），文件照样进了库★ |

第 1、2 例的教训像是"ignore 规则写得不够全"，于是前两次的修法都是**再加几条规则**。
第 3 例推翻了这个思路：规则在位、文件仍然进库。`.gitignore` 只拦**未跟踪**的新文件，
拦不住 `git add -f`；而 `evidence/` 恰恰必须靠 `-f` 提交（它整个目录在 ignore 里），
所以养成 `-f` 习惯的人会顺手把旁边的 scratch 一起拖进去。

**结论：ignore 是防线，不是闸。必须另有一道对着「已跟踪文件列表」跑的闸。**
- 闸：`scripts/check_no_tool_scratch.py`（按**名字**判，不按路径深度判；`evidence/` 整棵豁免）
- 双向负测：`scripts/test_no_tool_scratch_gate.py`，正向 14 例 + 反向 14 例
- 两者都在 `scripts/gate_all.sh` 里

反向那一半不是凑数：前缀匹配 `fm_diag*` 极易误伤 `fm_diagram/`、`fm_diagnostics_spec.md`。
边界定在"`fm_diag` 之后紧跟的是数字还是字母"——编号工作目录是 `名字+数字[+任意]`
（`fm_diag7`、`fm_diag4_sidecar`），正常单词是 `名字+字母`。
**这道负测第一次跑就抓出闸自己两个漏报**（`fm_diag4_sidecar/` 被后缀剥离规则放过、
`.daidir` 只在 basename 上判而漏了目录段），两个都是真 bug。

写完闸别忘了拿它扫一遍存量 —— 第 3 例就是这么被翻出来的，
而 `.gitignore` 里当时还写着一句注释说它"靠没 git add 侥幸没进库"。**那句话是错的。**

## ★`$time` 打出来的是时间不是拍数 —— 单位错会把诊断引向完全错误的嫌疑犯★（2026-09-18）

RenameTable_2 的失配日志写着 `$time=264000`。我转述成"约 26400 拍"，
于是整个诊断方向被定成"长期累积漂移"。**错了。**

tb 是 `` `timescale 1ns/1ps ``、`%0t` 默认按**精度**（1ps）打印、时钟 `always #5`，
所以 `264000 ps = 264 ns = 第 26 拍`。UCLI 实测印证：`run 264 ns` 之后
`senv time` 返回 `264000 ps`。

**差别不是"数字不准"，是嫌疑犯集合完全不同**：
- "跑了 26400 拍才错" ⇒ 找累积性的东西：计数器回绕、指针漂移、老化状态
- "刚开跑 26 拍就错" ⇒ 找初始化类的东西：未复位寄存器、暖机不足、上电值

真因是后者，而按前者去找永远找不到。

**规矩**：日志里任何 `$time`，第一次引用前先确认三件事 ——
`timescale` 的单位/精度、`%0t` 用的是哪个、时钟周期多少。
要拍数就自己算或者直接在 tb 里打一个拍计数器，别拿时间当拍数用。

## ★"读一个从没写过、而且不复位的寄存器" —— 是 tb 违反契约，不是 RTL bug★（2026-09-18）

golden 里有一整类寄存器是**故意不复位**的，典型是快照 payload：

    SnapshotGenerator.sv:146    always @(posedge clock)              ← 无 reset 臂，写 4×N 个槽
    SnapshotGenerator.sv:180    always @(posedge clock or posedge reset) ← 只复位 ptr/valids
    （SnapshotGenerator_6.sv 是 :551 / :765，同构）

设计契约是**只读有效槽**，由 `snptValids` 保证。重写件照抄"不复位"是**对的**。

而 UT 的 tb 常常把 `snptSelect` 写成全随机、不看有效位。于是开跑最初那几拍里
还没被写过的槽，golden 与重写件两个**独立例化**在 `+vcs+initreg+random` 下
各抽一份互不相同的上电值 ⇒ 读到就必然不等。

**这时候红的是 tb，不是 RTL。** 判断方法很硬：拿 UCLI 在失配那一拍定点探针，
两侧同读——**写过的槽全一致、只有没写过的槽不等**，就是这一类。

修法是给 tb 加**暖机窗口**（复位一撤先纯入队若干拍把槽写满，窗口内把
`useSnpt`/`redirect` 压 0 使恢复路径不启动），不是去改 RTL、更不是加 waiver。
`verif/ut/SnapshotGenerator/tb.sv`（`WARM_CYCLES=24`）与
`verif/ut/RenameBuffer/tb.sv`（`warm_drive` 里 `snptEnq = (c < 8)`）早就是这么做的，
这是**既有定式**，不是临时绕法。

**加了暖机必须证明没削弱判别力**：RenameTable 那次 `make mutants` 仍 11/11
符合预期，其中 M9「快照恢复源恒取 arch_table」——正是被动过的那条路——
仍然 CAUGHT（errors=453480）；覆盖闸也不空（四张快照各被选中上万次）。
**只报"改完还是绿的"不算数，要报"改完仍然抓得住动过的那条路"。**

## ★`INITREG` 这类 Makefile 变量，声明了不等于接上了★（2026-09-18，两个 UT 各一种死法）

两个 UT 的"3 seed × 2 initreg"里，有一轮或两轮**从来没真跑过**：

| UT | 死法 |
|---|---|
| `verif/ut/FreeList` | 编译行**根本没有** `+vcs+initreg+random`，`SIM_ARGS` 里也没有任何 initreg 字样 ⇒ `make run INITREG=...` 的 `INITREG` 从来没被用到，**两轮都没跑过** |
| `verif/ut/FreeList_5` | 运行期**写死** `SIM_ARGS += +vcs+initreg+0`，`INITREG` 改不动它 ⇒ **random 那轮从没跑过** |

★VCS 的初值注入是**编译期**开关★ —— 只在运行期加 `+vcs+initreg+random` 不生效，
这是第一种死法的根源。

**怎么发现**：不要看 Makefile 写了什么，看**磁盘上有没有对应的日志文件**。
`ls sim_*_initreg*.log`，两档后缀都得有、且内容不同（同 seed 两档 md5 必须不等）。
`scripts/ut_common.mk` 的 `INITREG_TAG` 就是为此存在的：它按 `SIM_ARGS` 里真正
出现的字样给日志加后缀，**接没接上一看文件名就知道**。

这和"`errors=0` 单独不算数"是同一类：**声明的验收和实际跑过的验收要分开核**。

## ★让 FM 跑不动的两个结构决定（Rob 上一轮 PARTITIONED 的真实根因）★（2026-09-18 考古）

上一轮 306 个签核目标里唯一一个非 `SIGNOFF_PASS` 的是 `Rob`。查下来**卡点不是"Rob 太大"，
是两个自己做的结构决定**，而且两个都可复现、都有名字。记在这里，因为它们对任何大模块都成立。

### 1. golden 的 debug/difftest 寄存器阵列必须照写，一个不少
上一轮可读核**故意不写**这些阵列（想着"反正是 debug 的"）。后果：
约 **35,000 个 golden-only 寄存器没有 impl 对家**，FM 的 `match` 要在巨大的未配对空间里爬——
**跑 3.3 小时只走到 11%**。

这是「看起来冗余的重复结构，一份都不许少」的又一个实例，但有两点不同：
- **量级大得多**：G1 Rob 里 **79% 的寄存器位**是 debug/difftest 的 160 条目规则阵列
  （`debug_microOp_debugReg*` 就占 52.9%），真 ROB 本体只占 18.9%
- **后果形态不同**：不是 `failing`，是 **`match` 根本跑不完**。省掉它们看似省事，
  实际是把代价从"多写几百行 genvar"换成"FM 永远不收敛"

而这些阵列**写起来很便宜**：规则的 160 条目阵列，genvar/数组几百行就能出全部十几万位。

### 2. 条目数组必须存成 per-field 数组（SoA），不能用 packed struct（AoS）
golden 是扁平 per-field 标量：`robEntries_<idx>_<field>`。
上一轮可读核为了"好看"存成 packed struct 数组，于是：
- FM 只能做**签名匹配**（signature analysis），代价 O(N²) —— 实测 **54 分钟只匹配了 13%**
- 想改成按名匹配（`set_user_match` name-pin）又撞 **FM-036，9263/9440 条全报**
- 最后只能用 **16161 条手工 completion pin** 兜过去才出了 `PARTITIONED_SUCCEEDED`

上一轮自己也认识到了这点并开了 SoA 改造 campaign，但那个 campaign 卡在"owner 未交付"。

**本轮定式：对齐 golden 的扁平命名，从第一行就写 SoA。**
顺带一提，per-field 数组 + genvar 本来就比 packed struct 更像硬件讲法，**可读性不吃亏**——
这里不存在"可读性 vs 可证性"的取舍，是当初选错了。

### 推论：行数是坏的规模代理
同一个 Rob，G0→G1 **行数 +45,354**，但**端口从 3234 降到 2200、实例从 26 降到 8**。
真正变的是：G0 时代 2343 个 output 里 2040 个是 difftest 端口、由**被黑盒的** child 直通出来，
**FM 根本没证、实现也不用写**；G1 把这条路堵死，667 个 output 里 647 个必须由重写件自己产生。
**真实证明面涨了 2.3 倍（276 → 647），而行数给出的信号是反的。**
估工作量时要看 **"有多少输出必须由重写件自己驱动"**，不是看行数。

## ★结论会传下去，限定条件不会 —— 台账必须记住"为什么不算数"★（2026-09-18，三例同源）

同一个病，一天之内在三个地方各咬一次：

| 现场 | 传下来的结论 | 丢掉的限定条件 |
|---|---|---|
| 覆盖台账 | "已直接证明 133 个" | 其中 **99 个的 evidence 没进版本库**，clean clone 只能核实 34 个 |
| `Rob` 上一轮实现 | "上一轮有实现 4638 行" | 那份 wrapper **声明 2343 个 output、`assign io_` 行数 0**，一个都不驱动；文件自己第 3255 行标着 SCAFFOLD、"不是可签核的证明壳" |
| `migration_plan_199` | `delta_class=REWRITE_L`、"must be re-derived, not migrated" | 那是 multiset 文本 diff 推的，**看不出残余量是同一个 payload bundle 复制 72 份** |

三处的作者当时都是诚实的 —— SCAFFOLD 那句注释白纸黑字写在文件里，`mode` 列老老实实标着
`U_INDETERMINATE`。**丢的不是诚实，是那句话没跟着结论一起进台账。**

**规矩**：往台账里写一个正面结论时，如果它有限定条件（证据不在库里 / 只是草稿 /
判据是弱信号 / 依赖别的目标没绿），**限定条件必须和结论写在同一行**，
不能只留在源文件注释、commit message 或某条分支的文档里。
读台账的人不会去读那些地方 —— 我这轮就三次没读到。

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
