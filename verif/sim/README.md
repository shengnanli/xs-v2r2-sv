# verif/sim —— 整芯片（SimTop + difftest + NEMU）仿真泳道

## 一句话

`scripts/full_elab.sh` 证明的是「整芯片 **XSTop** 在 `+define+SYNTHESIS` 下能 elaborate」。
**仿真是另一次完全不同的编译**：top 是 `tb_top` → `SimTop` → `XSTop`，
**不定义 SYNTHESIS**、定义 `DIFFTEST`，走 difftest 官方 VCS 流。
前者 0 error 不蕴含后者能编，实测也确实不蕴含（见下）。

## 三个编译维度的差别

| | full_elab.sh | 本泳道（仿真） |
|---|---|---|
| top | `XSTop` | `tb_top`（difftest）→ `SimTop` → `XSTop` |
| `SYNTHESIS` | **定义** | **不定义**（golden 的断言/随机初值/DPI 全部生效） |
| `DIFFTEST` | 无 | 定义（DPI-C 架构状态导出） |
| 寄存器初值 | — | `+vcs+initreg+random` + `RANDOMIZE_*`（golden 默认配置） |
| `SimTop.sv` | 不参与 | 参与，且带 9897 条层次引用（见下） |

## 已知阻塞：SimTop 的 9897 条 perfCnt_bore 层次引用（XMR）

golden `SimTop.sv` 里 `LogPerfEndpoint logEndpoint(...)` 这一个例化，用 **9897 条
绝对层次引用** 把模块**内部**信号直接引上来，例如：

```
.perfCnt_bore_3 (SimTop.cpu.l_soc.core_with_l2.core.frontend.inner_icache.mainPipe._GEN_0),
.perfCnt_bore_11(SimTop.cpu.l_soc.core_with_l2.core.frontend.inner_icache.missUnit._priorityFIFO_io_enq_valid_T_probe),
```

被引的名字是 firtool 产物（`_GEN_n` / `_T_n_probe` / `*_probe`），**重写件里根本不存在
同名内部信号**，于是整芯片仿真编译直接
`Error-[XMRE] Cross-module reference resolution error` 报死。
这是**端口级 bore（`gatewayIn_packed_bore` / `sigFromSrams_bore_*`，docs 里已登记）
之外的另一套机制**，此前未在本仓登记过。

`LogPerfEndpoint` 共 9903 个端口，**全部是 input**（无任何 output），是纯观测 sink；
perfCnt 只喂性能计数器，不参与 difftest 架构状态比对。所以本泳道的处理是：
在**自己的工作区**生成 `SimTop.sv` 的打补丁副本，把这 9897 条 XMR 接成常量 `'0`。
**不改 golden（只读）、不改 `rtl/`**。补丁由 `run_fullchip.sh setup impl` 机械生成，可复算。

> 代价（如实记）：impl 侧的性能计数器全灭。架构行为与 difftest 判定不受影响，
> 但「perf 计数与 golden 一致」这条不在本轮验收范围内了。
> 若要恢复，唯一的正路是让重写件按 golden 的内部信号名保留这些探针（层次重绑泳道）。

## 用法

```bash
verif/sim/run_fullchip.sh build golden     # golden 对照基线（不打补丁）
verif/sim/run_fullchip.sh build impl       # 重写件优先 + SimTop 打补丁
verif/sim/run_fullchip.sh run   golden     # coremark-2-iteration + NEMU difftest
verif/sim/run_fullchip.sh run   impl
```

工作区默认 `/home/eda/xs-env/sim-work/{golden,impl}`（`SIMW=` 可改），
不落在任何 git worktree 里。

## 里程碑怎么读

- **出时钟**：`tb_top` 自己产生，`initial #100 reset=0`。
- **复位释放**：仿真时间 100ns。
- **第一条指令提交（retirement）**：日志出现
  `The first instruction of core 0 has commited. Difftest enabled.`
  判据在 difftest C++ 侧：`commit[0].pc == FIRST_INST_ADDRESS`(0x10000000)。
  超时则是 `The first instruction of core 0 at 0x10000000 does not commit after N cycles.`
  —— **本工程踩过一次坑**：这条超时信息曾经不是 DUT 坏，而是 golden RTL 生成时
  `--enable-difftest` 没生效、commit pc 恒 0（见 memory `golden-coremark-difftest.md`）。
  G1-canonical 已复核：`DiffExtInstrCommit` 的 `io_pc [63:0]` 端口在、
  `GatewayEndpoint.sv` 里接的是真信号 `_validated_module_out_bits_6_bits_pc`，**不是常量**。
- **终点**：`HIT GOOD TRAP` + `DIFFTEST WORKLOAD DONE at cycle N`（golden 上一轮 = 6492）。
- **功能失配**：difftest 打 `Mismatch detected ...` 并 dump ref/dut 寄存器对照。

## 运行必需参数

`+ram_size=8589934592`（8GiB）—— 默认 8TB 会让 NEMU `init_mem` 崩。

## 这 9897 条里到底断了多少（`verif/sim/bore_audit.py` 机械可复算）

```
XMR 总数: 9897
   9126  信号存在-golden模块      <- 指向未重写模块，正常解析
    507  信号缺失-重写模块        <- 重写件里没有同名内部信号
    262  路径中断(实例名对不上)   <- 重写件里没有同名**子实例**
      2  信号存在-重写模块        <- 偶然同名
```

即 **771 条探针指向重写模块，其中 769 条断**（7.8%）。涉及 36 个重写模块，头部：

| 断的条数 | 模块 | 断法 |
|---|---|---|
| 89 | `Ftq` | 内部信号名 |
| 52 | `SinkA` | 内部信号名 |
| 50 | `EntriesVfdivVidiv` | 内部信号名 |
| 49×4 | `TageTable{,_1,_2,_3}` | 内部信号名 |
| 35 | `OpenLLC` | 子实例 `rnLinkMonitor`/`snLinkMonitor` 不存在 |
| 20 | `FTBBank` | 内部信号名 |
| 16+9 | `ICache` | 子实例 `mainPipe`/`prefetcher` 不存在 + 内部信号名 |
| 50 | `WritebackQueue` | 子实例 `entries_0..9` 不存在 |
| 7 | `LinkMonitor` | 子实例 `LCredit2Decoupled_rxsnp` 不存在 |

「子实例不存在」这一类说明重写件不只是内部**信号**改名，**子模块划分本身**也变了
（如 `WritebackQueue` 的 10 个 `entries_N` 单条目子模块被合进了阵列写法）。
所以「按 golden 保留探针名」这条路对这类模块不是改名能解决的，得改结构。

---

# 2026-09-14 第一轮实跑结果

## 结论先行

**重写整芯片能复位、能出时钟、能提交指令，并且在最小体系结构测试上与 golden
逐周期一致。** 目前**没有**发现任何功能失配。

## 途中踩到的两个真阻塞（都不是 DUT 的问题，但不修就一步也跑不了）

### 阻塞 1：SimTop 的 9897 条 perfCnt_bore 层次引用

见上文。处理：本工作区生成打补丁的 SimTop 副本（不改 golden、不改 `rtl/`）。
**只有 impl 侧需要**；golden 侧用原版 SimTop。

### 阻塞 2：★golden 环境自己是坏的★ —— `XiangShan/build/generated-src` 与 `build/rtl` 不是同一次生成

- `build/rtl/*`（= G1-canonical golden-rtl，逐字节相同）生成于 **2026-09-09 21:40**，
  命令带 `--enable-difftest`。
- `build/generated-src/*`（difftest 的 DPI C++ 胶水）却是 **22:01** 写的，
  `difftest_profile.json` 里记的命令是
  `--target-dir build_xstop/rtl --fpga-platform --disable-all --remove-assert`
  —— 那是 20 分钟后另一次 **FPGA/RELEASE** 形态的生成，把 generated-src 覆盖了
  （difftest 的 `FileControl.scala` 把 generated-src 硬编码写到 `$NOOP_HOME/build/generated-src`，
  不跟 `--target-dir` 走）。
- 后果：golden RTL 例化 27 种 `DummyDPICWrapper_*`，而这份 dpic 只提供 21 个函数，
  且其中 3 个（`Phy*RegState` / `*RenameTable`）RTL 根本不用。缺的 12 个里就有
  `ArchIntRegState` / `ArchFpRegState` / `CommitData` / `StoreEvent` …
  **golden 自己一跑就死**：
  `Error-[DPI-DIFNF] ... 'v_difftest_ArchFpRegState' does not exist`，Time 2287 ns。
- 还有第二层坑：`difftest-state.h` 的**结构体布局**也跟着变了。只换 generated-src
  再增量重编，VCS 只重编了 `difftest-dpic.cpp`，`difftest.cpp`/`diffstate.cpp` 等
  **沿用旧头文件编出来的 .o**，于是出现"整数寄存器对得上、pc 和浮点寄存器是随机值"的
  假失配（`pc ... right=0x10000000, wrong=0x002d002c002d002c`）和裸 segfault。
  必须**显式删掉那 48 个 C++ .o 强制重编**（RTL 的 .o 不能删，否则 55 分钟白编）。

**修法（本泳道做的）**：用 `make sim-verilog CONFIG=KunminghuV2Config` 在隔离目录
（`NOOP_HOME=`/`BUILD_DIR=` 都指向 `sim-work/regen`）重新生成一份，取它的 generated-src。
**顺带证明了 G1-canonical 可复现**：重新生成的 2061 个文件里 **2057 个与 G1 逐字节相同**，
4 个差异分别是 `SimTop.fir`（dump 格式）、`metadata/`（本次未生成）、
`CommitIDModule.sv` 与 `NewCSR.sv`（只差内嵌的 git SHA：`133d7dc4b` vs `b36a1a2a5`）。

> **给 golden/基线 owner 的账**：`G1-canonical/` **不含 generated-src**，
> 因此**这份"唯一 golden 对照"目前不足以复现一次仿真**——必须另外重生成 DPI 胶水。
> 建议把 generated-src（6 个文件、约 120KB）纳入 canonical 包并记进 MANIFEST。

## 里程碑（coremark-2-iteration，difftest + NEMU）

| 里程碑 | golden | impl（重写件优先） |
|---|---|---|
| 出时钟（`tb_top` `always #1`） | ✅ | ✅ |
| 复位释放（100 ns = cycle 50） | ✅ | ✅ |
| **第一条指令提交** `The first instruction of core 0 has commited. Difftest enabled.` | ✅ | ✅ |
| 走完 bootrom → 跳 0x80000000 → 跑到负载 UART 输出 `Running CoreMark for 2 iterations` | ✅ | ✅ |
| difftest 逐指令锁步（NEMU）无失配 | ✅ | ✅ |

## 最小既有体系结构测试：`flash_recursion_test.bin`（跑到终点）

| | golden | impl |
|---|---|---|
| 结果 | `HIT GOOD TRAP at pc = 0xe` | `HIT GOOD TRAP at pc = 0xe` |
| instrCnt | 289 | **289** |
| cycleCnt | 4,642 | **4,642** |
| IPC | 0.062258 | **0.062258** |
| `DIFFTEST WORKLOAD DONE at cycle` | 4649 | **4649** |
| difftest 失配 | 0 | **0** |

**逐周期一致**。这是本工程第一次把重写整芯片跑到一个体系结构测试的终点。
（该测试自带一次 `HIT CRITICAL ERROR: please check if software cause a double trap`，
golden 侧同样出现，是负载行为不是 DUT 差异。）

## 为什么 coremark 没跑到终点

实测仿真速度 **≈75 cycle/s**（`+max-cycles=20000` 用了 267 s）。difftest 的 vcs.mk 固定带
`-debug_access+all` + verdi PLI，整芯片下极慢。coremark 2 迭代远不止 memory 里记的
"cycle 6492"（那个数字与本次实测对不上，**存疑**），按 IPC~1 估要千万级周期
= 数十小时。所以本轮只能给"跑了多少周期无失配"，不能给 coremark 的 GOOD TRAP。
要跑完 coremark 得先编一版**去掉 `-debug_access+all` 的快 simv**（需要改 difftest 的
vcs.mk 或用 `EXTRA` 覆盖，未验证）。

## 顺手抓到的一个 rtl/ 问题（**没改，交给对应 owner**）

`rtl/uncore/SubDirectory.sv:60` 与 `rtl/uncore/SubDirectory_1.sv:61` 里有
`` `timescale 1ns/1ps ``。golden 侧没有任何 timescale 指令。后果：impl 整芯片编译的
时间精度被这两个文件改成 1ns/1ps（golden 侧是 1ns/1ns），**而且生效范围取决于文件顺序**。
本轮结果未受影响（周期数完全一致），但这是个与 golden 的编译差异 + 顺序相关的隐患。

`rtl/backend/RegCache.sv:150` 的 7 条 SIOB（`rcidx_delay[(0-1)][*]`）在**仿真**里
不像综合那样只是 lint：越界读返回 X。本例中 `(s==0)?:` 的条件是 genvar 常量，
VCS 会常量折叠，实测无影响；但清理 owner 值得知道仿真语义上的区别。

## nexus-am cputest：33 个小体系结构测试，**33/33 逐周期一致**

coremark 跑不完（~75 cycle/s），所以本轮改用 nexus-am 的 33 个 cputest：每个约
100~10000 条指令、4300~13800 周期，单次 ~33s，并行 12 路约 6 分钟出全表。
负载现编（本机只有 `riscv64-none-linux-gnu-` 工具链，nexus-am 默认找
`riscv64-unknown-linux-gnu-`，必须显式覆盖 `CROSS_COMPILE`）：

```bash
export AM_HOME=/home/eda/xs-env/nexus-am NOOP_HOME=/home/eda/xs-env/XiangShan
export PATH=/home/eda/xs-env/XiangShan/riscstar-toolchain-15.2-r1-x86_64-riscv64-none-linux-gnu/bin:$PATH
cd $AM_HOME/tests/cputest && make ARCH=riscv64-xs CROSS_COMPILE=riscv64-none-linux-gnu-
verif/sim/run_cputest.sh 12
```

**结果：33/33 全部 `HIT GOOD TRAP`，golden 与 impl 的 `instrCnt` 与 `cycleCnt`
逐项完全相同，两侧 difftest 失配数均为 0。** 全表见
`verif/sim/evidence/cputest_golden_vs_impl.tsv`。覆盖 add/sub/mul/div、longlong、
移位/位操作、符号扩展、**非对齐访存**、load-store、分支/switch、递归、
快排/冒泡/选择排序、矩阵乘、字符串与 printf（走 UART MMIO）。

**所以：本轮没有找到任何功能失配。** 不是"没跑到"，是"跑了、比了、一致"。
