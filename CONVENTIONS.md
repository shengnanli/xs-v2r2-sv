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
   编译带 `+define+SYNTHESIS +vcs+initreg+random`（另一轮 `+vcs+initreg+0`），
   VCS 环境：`VCS_ARCH_OVERRIDE=linux` 必配 `-full64`。
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
- FM 严禁并发多实例大模块验证（内存 OOM），串行跑；禁 `pkill -f`。
- chisel Vec 越界读语义是回绕不是 0（上轮 LoadQueue replay 真 bug 根因）。

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
